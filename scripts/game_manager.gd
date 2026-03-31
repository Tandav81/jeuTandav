extends Node

var spawn_position = Vector2.ZERO
var player_health = 100
var current_scene = "res://scenes/world.tscn"
var coffres_ouverts = []

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	var fog = get_tree().get_first_node_in_group("fog")
	
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
		"coffres_ouverts": coffres_ouverts,
		"level": Stats.level,
		"xp": Stats.xp,
		"xp_next_level": Stats.xp_next_level,
		"stat_points": Stats.stat_points,
		"base_force": Stats.base_force,
		"base_endurance": Stats.base_endurance,
		"base_agilite": Stats.base_agilite,
		"base_magie": Stats.base_magie,
		"base_defense": Stats.base_defense,
		"equipped": Inventory.equipped,
		"fog_revealed": fog.get_save_data() if fog else []
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
	Inventory.gold = int(data["gold"])
	Inventory.equipped_tool = data["equipped_tool"]
	
	if data.has("coffres_ouverts"):
		coffres_ouverts = data["coffres_ouverts"]
	
	Inventory.items = {}
	for item_name in data["items"]:
		Inventory.items[item_name] = int(data["items"][item_name])
	
	# Stats — vérifie que les données existent (compatibilité anciennes sauvegardes)
	if data.has("level"):
		Stats.level = int(data["level"])
		Stats.xp = int(data["xp"])
		Stats.xp_next_level = int(data["xp_next_level"])
		Stats.stat_points = int(data["stat_points"])
		Stats.base_force = int(data["base_force"])
		Stats.base_endurance = int(data["base_endurance"])
		Stats.base_agilite = int(data["base_agilite"])
		Stats.base_magie = int(data["base_magie"])
		Stats.base_defense = int(data["base_defense"])
	
	if data.has("equipped"):
		Inventory.equipped = data["equipped"]
	
	var fog = get_tree().get_first_node_in_group("fog")
	if fog and data.has("fog_revealed"):
		fog.load_save_data(data["fog_revealed"])
	
	return true

func save_exists() -> bool:
	return FileAccess.file_exists("user://save.json")
