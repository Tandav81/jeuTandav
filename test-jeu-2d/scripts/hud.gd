extends CanvasLayer

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)

func _on_health_changed(new_health):
	print("HUD reçoit health_changed ! valeur=", new_health)
	$HealthBar.value = new_health
