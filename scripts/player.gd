extends CharacterBody2D

const SPEED = 150.0

@onready var anim = $AnimatedSprite2D

var max_health = 100
var health = 100

signal health_changed(new_health)

func take_damage(amount):
	health -= amount
	emit_signal("health_changed", health)
	if health <= 0:
		die()

func die():
	get_tree().reload_current_scene()

func _physics_process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		anim.flip_h = false
		anim.play("walk_right")
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
		anim.flip_h = true
		anim.play("walk_left")
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
		anim.play("walk_down")
	elif Input.is_action_pressed("ui_up"):
		direction.y -= 1
		anim.play("walk_up")
	else:
		anim.play("idle_down")

	velocity = direction.normalized() * SPEED
	move_and_slide()
