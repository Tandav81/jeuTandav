extends CharacterBody2D

@export var animal_name = "Mouton"
@export var resource_name = "Viande"
@export var quantity = 1
@export var flee_speed = 80.0
@export var flee_range = 80.0
@export var health = 2

@onready var anim = $AnimatedSprite2D

var player = null
var is_dead = false
var current_health = 0

signal resource_collected(type, name, qty)

func _ready():
	current_health = health
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if is_dead or player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist < flee_range:
		_fuir()
	else:
		_idle()

	move_and_slide()
	_jouer_animation()

func _fuir():
	var dir = (global_position - player.global_position).normalized()
	velocity = dir * flee_speed

func _idle():
	velocity = Vector2.ZERO

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

func take_damage(amount):
	if is_dead:
		return
	current_health -= amount
	# Effet visuel de hit
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.RED, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	if current_health <= 0:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	#Inventory.add_item(resource_name, quantity)
	Inventory.add_item(resource_name, quantity)
	print("Ressource obtenue : ", resource_name, " x", quantity)

	# Animation de mort si elle existe, sinon fondu simple
	if anim.sprite_frames.has_animation("die"):
		anim.play("die")
		await anim.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished

	queue_free()
