extends CharacterBody2D

const SPEED = 150.0
@onready var anim = $AnimatedSprite2D
@onready var attack_zone = $AttackZone
var max_health = 100
var health = 100
var is_attacking = false
var attack_direction = Vector2.DOWN
var equipped_tool = ""  # "", "hache", "pioche"
var _fog_timer: float = 0.0
const FOG_UPDATE_INTERVAL: float = 0.15  # secondes entre chaque mise à jour
var _fog_node: Node = null

# Ordre de cycle pour le changement d'arme (touche Q)
const WEAPON_LIST = ["Epee en bois", "Epee en fer", "Arc", "Baton magique"]

# ── Esquive / Roulade ────────────────────────────────────────
const DOUBLE_TAP_WINDOW: float = 0.28   # fenêtre double-tap (secondes)
const DODGE_COOLDOWN:    float = 1.0    # délai entre deux esquives
const DODGE_SPEED:       float = 420.0  # vitesse du dash
const DODGE_DURATION:    float = 0.18   # durée d'invincibilité

var _last_dir_pressed:   Vector2 = Vector2.ZERO
var _last_dir_time_ms:   int     = 0
var _is_dodging:         bool    = false
var _dodge_cooldown_cur: float   = 0.0

signal health_changed(new_health)

func _ready():
	add_to_group("player")
	max_health = Stats.get_max_health()
	if GameManager.spawn_position != Vector2.ZERO:
		global_position = GameManager.spawn_position
	if GameManager.player_health > 0:
		health = GameManager.player_health
		emit_signal("health_changed", health)
	Inventory.emit_signal("inventory_changed")
	_add_bow_animations()
	_fog_node = get_tree().get_first_node_in_group("fog")
	# Révéler immédiatement au spawn
	if _fog_node:
		_fog_node.reveal_around(global_position)

# Ajoute l'animation "bow_right" (6 frames) depuis Player_bow_attack.png
func _add_bow_animations():
	var bow_tex = load("res://assets/Player/Player_bow_attack.png")
	if bow_tex == null:
		push_warning("Player_bow_attack.png introuvable — animation arc ignorée")
		return
	var frames: SpriteFrames = anim.sprite_frames
	if frames.has_animation("bow_right"):
		return  # déjà ajouté (re-entrée après reload)
	frames.add_animation("bow_right")
	frames.set_animation_speed("bow_right", 8.0)
	frames.set_animation_loop("bow_right", false)
	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = bow_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("bow_right", atlas)

func take_damage(amount):
	if is_attacking or _is_dodging:
		return  # invincible pendant l'attaque ou l'esquive
	var damage_reduit = max(1, amount - Stats.get_defense())
	health -= damage_reduit
	emit_signal("health_changed", health)
	if health <= 0:
		die()

func die():
	get_tree().reload_current_scene()

func _physics_process(delta):
	# Cooldown esquive
	if _dodge_cooldown_cur > 0.0:
		_dodge_cooldown_cur -= delta

	var current_speed = Stats.get_speed()

	if _is_dodging:
		move_and_slide()
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		anim.flip_h = false
		attack_direction = Vector2.RIGHT
		anim.play("walk_right")
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
		anim.flip_h = true
		attack_direction = Vector2.LEFT
		anim.play("walk_left")
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
		attack_direction = Vector2.DOWN
		anim.play("walk_down")
	elif Input.is_action_pressed("ui_up"):
		direction.y -= 1
		attack_direction = Vector2.UP
		anim.play("walk_up")
	else:
		anim.play("idle_down")

	# Attaque avec espace
	if Input.is_action_just_pressed("attack"):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud == null or not hud.inventaire_ouvert:
			_attaquer()

	# Interaction avec outil
	if Input.is_action_just_pressed("interact"):
		_utiliser_outil()

	velocity = direction.normalized() * current_speed
	move_and_slide()
	
	_fog_timer += delta
	if _fog_timer >= FOG_UPDATE_INTERVAL:
		_fog_timer = 0.0
		if _fog_node:
			_fog_node.reveal_around(global_position)

func _utiliser_outil():
	if Inventory.equipped_tool == "":
		return
	is_attacking = true
	var anim_name = Inventory.equipped_tool + "_"
	if attack_direction == Vector2.DOWN:
		anim.play(anim_name + "down")
	elif attack_direction == Vector2.UP:
		anim.play(anim_name + "up")
	elif attack_direction == Vector2.RIGHT:
		anim.flip_h = false
		anim.play(anim_name + "right")
	elif attack_direction == Vector2.LEFT:
		anim.flip_h = true
		anim.play(anim_name + "right")

	await get_tree().create_timer(0.2).timeout
	is_attacking = false
	anim.play("idle_down")

# ---- Type et portée de l'arme équipée --------------------------------

func get_weapon_type() -> String:
	var arme = Inventory.equipped["arme"]
	if arme == "Arc":
		return "arc"
	elif arme == "Baton magique":
		return "magie"
	return "melee"

func get_attack_range() -> float:
	var type = get_weapon_type()
	if type == "arc":
		# Portée : Force + Agilité
		return max(80.0, 60.0 + (Stats.get_force() + Stats.get_agilite()) * 8.0)
	elif type == "magie":
		# Portée : niveau de Magie
		return max(80.0, 40.0 + Stats.get_magie() * 15.0)
	return 30.0  # mêlée : portée de la zone d'attaque

# ---- Attaque principale : dispatche selon le type d'arme -------------

func _attaquer():
	var type = get_weapon_type()
	if type == "arc":
		_lancer_projectile("arc")
	elif type == "magie":
		var cout = Stats.get_mana_cost_sort()
		if not Stats.use_mana(cout):
			print("Pas assez de mana ! (", int(Stats.current_mana), "/", cout, ")")
			return
		_lancer_projectile("magie")
	else:
		_attaque_melee()

func _attaque_melee():
	is_attacking = true
	attack_zone.monitoring = true
	attack_zone.position = attack_direction * 20

	if attack_direction == Vector2.DOWN:
		anim.play("attack_down")
	elif attack_direction == Vector2.UP:
		anim.play("attack_up")
	elif attack_direction == Vector2.RIGHT:
		anim.flip_h = false
		anim.play("attack_right")
	elif attack_direction == Vector2.LEFT:
		anim.flip_h = true
		anim.play("attack_right")

	await get_tree().create_timer(0.3).timeout
	attack_zone.monitoring = false
	is_attacking = false
	anim.play("idle_down")

func _lancer_projectile(type: String):
	is_attacking = true

	if type == "arc":
		# Animation de tir à l'arc : "bow_right" mirrorée pour la gauche
		anim.flip_h = (attack_direction == Vector2.LEFT)
		anim.play("bow_right")
		# Attendre la phase "armé" (≈ 4 frames sur 6 → 0.5 s à 8 fps)
		await get_tree().create_timer(0.5).timeout

	# Lancer le projectile au moment du relâchement
	var ProjectileScript = load("res://scripts/projectile.gd")
	var proj = ProjectileScript.new()
	proj.proj_type = type
	proj.direction = attack_direction
	proj.max_range = get_attack_range()
	proj.damage    = Stats.get_damage()
	# Décalage selon l'arme : l'arc est tenu en hauteur dans le sprite
	var spawn_offset := Vector2.ZERO
	spawn_offset = Vector2(0, -14)   # remonter pour aligner avec l'arc dessiné
	proj.global_position = global_position + attack_direction * 12.0 + spawn_offset
	get_tree().current_scene.add_child(proj)

	if type == "arc":
		# Laisser les 2 frames de suivi se terminer
		await anim.animation_finished
	else:
		# Magie : courte pause le temps de l'effet visuel
		await get_tree().create_timer(0.25).timeout

	is_attacking = false
	anim.play("idle_down")

# ---- Changement d'arme (cycle Q sur les armes possédées) -------------

func _changer_arme():
	var dispo: Array = []
	for w in WEAPON_LIST:
		if Inventory.has_item(w):
			dispo.append(w)
	if dispo.is_empty():
		return
	var actuelle = Inventory.equipped["arme"]
	var idx = dispo.find(actuelle)
	var prochaine = dispo[(idx + 1) % dispo.size()]
	Inventory.equip_item("arme", prochaine)
	print("Arme équipée : ", prochaine)

# ---- Callbacks -------------------------------------------------------

func _on_attack_zone_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(Stats.get_damage())

func heal(amount):
	health = min(health + amount, max_health)
	emit_signal("health_changed", health)
	print("❤️ +", amount, " PV ! Vie actuelle : ", health)

func _dodge(dir: Vector2) -> void:
	if _is_dodging or _dodge_cooldown_cur > 0.0 or is_attacking:
		return
	_is_dodging = true
	_dodge_cooldown_cur = DODGE_COOLDOWN
	velocity = dir * DODGE_SPEED
	# Flash semi-transparent pendant le dash
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.4, 0.05)
	tw.tween_property(self, "modulate:a", 1.0, DODGE_DURATION - 0.05)
	await get_tree().create_timer(DODGE_DURATION).timeout
	_is_dodging = false
	velocity = Vector2.ZERO
	# Talent dash_heal : +3 PV à chaque esquive réussie
	if Stats.has_talent("dash_heal"):
		heal(3)

func _input(event):
	# ── Double-tap directionnel = esquive ───────────────────────
	if event is InputEventKey and event.pressed and not event.echo:
		var dir = Vector2.ZERO
		match event.keycode:
			KEY_RIGHT: dir = Vector2.RIGHT
			KEY_LEFT:  dir = Vector2.LEFT
			KEY_DOWN:  dir = Vector2.DOWN
			KEY_UP:    dir = Vector2.UP
		if dir != Vector2.ZERO:
			var now_ms = Time.get_ticks_msec()
			if dir == _last_dir_pressed and (now_ms - _last_dir_time_ms) < int(DOUBLE_TAP_WINDOW * 1000):
				_dodge(dir)
				_last_dir_pressed = Vector2.ZERO  # reset pour éviter triple-tap
			else:
				_last_dir_pressed = dir
				_last_dir_time_ms = now_ms

	# Changer d'arme avec Q
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_changer_arme()

	if Input.is_action_just_pressed("tool_next"):
		match Inventory.equipped_tool:
			"":
				Inventory.equip_tool("hache")
			"hache":
				Inventory.equip_tool("pioche")
			"pioche":
				Inventory.equip_tool("")

	if Input.is_action_just_pressed("save"):
		GameManager.save_game()
		print("Sauvegarde effectuée !")
