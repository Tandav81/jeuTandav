extends Node

var spawn_position = Vector2.ZERO
var player_health = 100
var current_scene = "res://scenes/world.tscn"
var coffres_ouverts = []

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var save_data = {
		"health": player.health,
		"position_x": player.global_position.x,
		"position_y": player.global_position.y,
		"scene": get_tree().current_scene.scene_file_path,
		"items": Inventory.items,
		"gold": Inventory.gold,
		"equipped_tool": Inventory.equipped_tool,
		"coffres_ouverts": coffres_ouverts
	}
	
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Jeu sauvegardé !")

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		print("Aucune sauvegarde trouvée")
		return false
	
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	spawn_position = Vector2(data["position_x"], data["position_y"])
	player_health = data["health"]
	current_scene = data["scene"]
	Inventory.gold = data["gold"]
	Inventory.equipped_tool = data["equipped_tool"]
	if data.has("coffres_ouverts"):
		coffres_ouverts = data["coffres_ouverts"]
		
	Inventory.items = {}
	for item_name in data["items"]:
		Inventory.items[item_name] = int(data["items"][item_name])
		
	return true

func save_exists() -> bool:
	return FileAccess.file_exists("user://save.json")
