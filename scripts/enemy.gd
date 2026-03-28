extends CharacterBody2D

@export var speed = 60.0
@export var detection_range = 100.0
@export var patrol_range = 50.0
@export var damage_per_second = 10.0
@export var max_health = 50
@export var xp_reward = 20
@export var respawn_time = 5.0  # secondes avant respawn
@export var enemy_type = "slime"

@onready var anim = $AnimatedSprite2D

var player = null
var start_position = Vector2.ZERO
var patrol_direction = Vector2.RIGHT
var patrol_timer = 0.0
var damage_timer = 0.0
var player_in_range = false
var health = 50
var is_dying = false

func _ready():
	start_position = global_position
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	add_collision_exception_with(player)

func take_damage(amount):
	health -= amount
	print("Ennemi touché ! vie restante=", health)
	if health <= 0:
		die()

#func die():
	## Empêche l'ennemi de bouger et d'infliger des dégâts
	#is_dying = true
	#velocity = Vector2.ZERO
	#$CollisionShape2D.set_deferred("disabled", true)
	#$Area2D/CollisionShape2D.set_deferred("disabled", true)
	#
	#Stats.add_xp(xp_reward)
	#
	## Joue l'animation de mort
	#anim.play("die")
	#await anim.animation_finished
	#queue_free()

func die():
	if is_dying:
		return
		
	is_dying = true

	Stats.add_xp(xp_reward)
	QuestManager.update_kill(enemy_type)
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

	$CollisionShape2D.disabled = false
	set_physics_process(true)

	# effet de réapparition
	modulate = Color(1, 1, 1, 0)
	visible = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
func _physics_process(delta):
	if is_dying:
		return
	if player == null:
		return

	# Dégâts continus si le joueur est dans la zone
	if player_in_range:
		damage_timer += delta
		if damage_timer >= 1.0:
			damage_timer = 0.0
			player.take_damage(damage_per_second)

	var dist = global_position.distance_to(player.global_position)
	if dist < detection_range:
		_poursuit_joueur()
	else:
		_patrouille(delta)

	move_and_slide()
	_jouer_animation()

func _poursuit_joueur():
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

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		print("C'est le joueur !")
		player_in_range = true
		damage_timer = 1.0  # dégâts immédiats au contact

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		damage_timer = 0.0
