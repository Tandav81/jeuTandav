extends Area2D

@export var item_type = "potion"
@export var heal_amount = 30

func _on_body_entered(body):
	print("Item détecté : ", body.name)
	if body.is_in_group("player"):
		print("C'est le joueur !")
		match item_type:
			"potion":
				body.heal(heal_amount)
		_ramasser()

func _ramasser():
	$CollisionShape2D.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
