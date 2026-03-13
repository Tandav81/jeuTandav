extends CharacterBody2D

@export var speed = 60.0
@export var detection_range = 100.0

var player = null
var patrol_points = []
var current_point = 0

func _ready():
	# Cherche le joueur dans le groupe "player"
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(10)

func _physics_process(delta):
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist < detection_range:
		# Poursuit le joueur
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
