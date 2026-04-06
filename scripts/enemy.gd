extends CharacterBody2D

@export var speed = 60.0
@export var detection_range = 100.0
@export var attack_range = 38.0   # distance à laquelle l'ennemi s'arrête et attaque
@export var patrol_range = 50.0
@export var damage_per_second = 10.0
@export var max_health = 50
@export var xp_reward = 20
@export var respawn_time = 5.0  # secondes avant respawn
@export var enemy_type = "slime"

# ── Boss ─────────────────────────────────────────────────────
@export var is_boss: bool = false
@export var boss_name: String = "Boss"
## Items droppés à la mort : chaque entrée = Dictionary { "name": "...", "qty": N }
@export var unique_drops: Array[Dictionary] = []
## Si true, déclenche la cinématique de révélation dans world.tscn à la mort du boss
@export var triggers_world_cinematic: bool = false

signal boss_health_changed(current_hp: int, max_hp: int)
signal boss_died

@onready var anim = $AnimatedSprite2D

# Barre de vie flottante (sprites redbar_00 à redbar_06)
# 00 = vide, 06 = pleine
const HEALTH_BAR_TEXTURES = [
	"res://assets/sprites/redbar_00/dc17217d-04fa-45f7-9395-c8dd174d20a7.png",
	"res://assets/sprites/redbar_01/b279e444-e9c0-405a-90c1-4223cd72ce85.png",
	"res://assets/sprites/redbar_02/a13ba0c9-db87-4485-8fef-9dd9dcce8c47.png",
	"res://assets/sprites/redbar_03/1e7aeec7-0e39-4199-b221-af151c260612.png",
	"res://assets/sprites/redbar_04/a5ebdca8-6945-40be-ba98-b1fee6e06f46.png",
	"res://assets/sprites/redbar_05/5fbdad32-2c70-4812-a88a-ffc845af46d2.png",
	"res://assets/sprites/redbar_06/ee1a1d70-68e1-4d3b-9855-b9fb146881f5.png",
]
@export var health_bar_offset_y: float = -24.0  # ajustable par scène

var player = null
var start_position = Vector2.ZERO
var patrol_direction = Vector2.RIGHT
var patrol_timer = 0.0
var damage_timer = 0.0
var player_in_range = false
var health = 0        # initialisé dans _ready() depuis max_health
var is_dying = false
var is_hurt     = false
var is_attacking = false   # true pendant l'animation d'attaque
var _health_bar: Sprite2D = null
var _health_bar_textures_cache: Array[Texture2D] = []

func _ready():
	health = max_health   # Fix : applique la valeur exportée (ex. golem 500)
	start_position = global_position
	for path in HEALTH_BAR_TEXTURES:
		_health_bar_textures_cache.append(load(path))
	_build_health_bar()
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		add_collision_exception_with(player)
	# Notifier le HUD si c'est un boss
	if is_boss:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.on_boss_spawned(self)

func _build_health_bar() -> void:
	_health_bar = Sprite2D.new()
	_health_bar.name = "HealthBar"
	_health_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_health_bar.scale = Vector2(2, 2)
	_health_bar.position = Vector2(0, health_bar_offset_y)
	_health_bar.visible = false
	add_child(_health_bar)
	_update_health_bar()

func _update_health_bar() -> void:
	if not is_instance_valid(_health_bar):
		return
	var pct = float(health) / float(max_health)
	var idx = clamp(int(round(pct * 6)), 0, 6)
	_health_bar.texture = _health_bar_textures_cache[idx]
	_health_bar.visible = health < max_health and not is_dying

func take_damage(amount):
	# Talent crit_chance : 20% de chances de coup critique
	var final_amount = amount
	if Stats.has_talent("crit_chance") and randf() < 0.20:
		final_amount = int(amount * 1.5)
	health -= final_amount
	_update_health_bar()
	if is_boss:
		boss_health_changed.emit(health, max_health)
	if health <= 0:
		die()
	else:
		_play_hurt()

func _do_attack():
	if is_dying:
		return
	is_attacking = true
	$AnimatedSprite2D.play("attack")
	# Dégâts au milieu de l'animation (effet visuel de frappe)
	await get_tree().create_timer(0.3).timeout
	if player_in_range and not is_dying and is_instance_valid(player):
		player.take_damage(damage_per_second)
	await $AnimatedSprite2D.animation_finished
	is_attacking = false

func _play_hurt():
	if is_hurt or is_dying:
		return
	is_hurt = true
	$AnimatedSprite2D.play("hurt")
	await $AnimatedSprite2D.animation_finished
	is_hurt = false

func die():
	if is_dying:
		return
		
	is_dying = true
	if is_instance_valid(_health_bar):
		_health_bar.visible = false

	Stats.add_xp(xp_reward)
	QuestManager.update_kill(enemy_type)
	# Talent : régénération au kill
	if Stats.has_talent("regen_on_kill"):
		var p = get_tree().get_first_node_in_group("player")
		if p:
			p.heal(5)
	# Boss : drops uniques + signal HUD
	if is_boss:
		for drop in unique_drops:
			if drop is Dictionary and drop.has("name"):
				Inventory.add_item(drop["name"], drop.get("qty", 1))
			else:
				push_warning("unique_drops: élément invalide ignoré — doit être {name, qty}")
		if triggers_world_cinematic:
			GameManager.dungeon_key_pending = true
		boss_died.emit()
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.on_boss_died()
	# jouer animation de mort
	$AnimatedSprite2D.play("die")
	
	# attendre la fin de l'animation
	await $AnimatedSprite2D.animation_finished
	
	# désactive l'ennemi
	visible = false
	$CollisionShape2D.disabled = true
	set_physics_process(false)

	# attendre avant respawn
	await get_tree().create_timer(respawn_time).timeout

	respawn()
	
func respawn():
	health = max_health
	is_dying = false
	is_hurt = false       # réinitialise les flags d'animation au cas où
	is_attacking = false
	player_in_range = false
	damage_timer = 0.0

	$CollisionShape2D.disabled = false
	set_physics_process(true)

	# effet de réapparition
	modulate = Color(1, 1, 1, 0)
	visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	_update_health_bar()
	if is_boss:
		boss_health_changed.emit(health, max_health)
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.on_boss_spawned(self)
	
func _physics_process(delta):
	if is_dying:
		return
	if player == null:
		return

	# Attaque animée si le joueur est dans la zone
	if player_in_range and not is_attacking:
		damage_timer += delta
		if damage_timer >= 1.0:
			damage_timer = 0.0
			_do_attack()

	var dist = global_position.distance_to(player.global_position)
	if dist < detection_range:
		_poursuit_joueur(dist)
	else:
		player_in_range = false
		_patrouille(delta)

	move_and_slide()
	_jouer_animation()

func _poursuit_joueur(dist: float):
	if dist <= attack_range:
		# À portée d'attaque : s'arrêter et activer le combat
		velocity = Vector2.ZERO
		player_in_range = true
	else:
		# Encore trop loin : s'approcher — réinitialiser le timer si on vient de quitter la portée
		if player_in_range:
			damage_timer = 0.0   # Bug fix : évite une attaque instantanée au retour
		player_in_range = false
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed

func _patrouille(delta):
	patrol_timer += delta
	if patrol_timer > 2.0:
		patrol_timer = 0.0
		patrol_direction = -patrol_direction
	var dist_from_start = global_position.distance_to(start_position)
	if dist_from_start > patrol_range:
		patrol_direction = (start_position - global_position).normalized()
	velocity = patrol_direction * (speed * 0.5)

func _jouer_animation():
	if is_hurt or is_dying or is_attacking:
		return   # laisser l'animation hurt/die/attack se terminer sans l'écraser
	if velocity.length() < 1:
		anim.play("idle_down")
	elif abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			anim.flip_h = false
			anim.play("walk_right")
		else:
			anim.flip_h = true
			anim.play("walk_right")
	else:
		if velocity.y > 0:
			anim.play("walk_down")
		else:
			anim.play("walk_up")

func _on_area_2d_body_entered(_body):
	# Géré directement via la distance dans _poursuit_joueur()
	pass

func _on_area_2d_body_exited(_body):
	# Géré directement via la distance dans _poursuit_joueur()
	pass
