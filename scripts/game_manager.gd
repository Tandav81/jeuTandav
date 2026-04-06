extends Node

var spawn_position = Vector2.ZERO
var player_health = 100
var current_scene = "res://scenes/world.tscn"
var coffres_ouverts = []
var fog_data: Dictionary = {}
var time_of_day: float = 0.25
var used_books: Array = []   # livres de recettes déjà lus

## true = cinématique à déclencher au prochain chargement de world.tscn
## (posé à true quand un boss avec triggers_world_cinematic=true est tué)
var dungeon_key_pending: bool = false

## Retourne true si ce livre a déjà été utilisé (recettes débloquées).
func is_book_used(book_name: String) -> bool:
	return used_books.has(book_name)

## Utilise un livre : ajoute à la liste si pas déjà présent.
func use_book(book_name: String) -> void:
	if not used_books.has(book_name):
		used_books.append(book_name)

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	var fog = get_tree().get_first_node_in_group("fog")
	
	if fog:
		fog_data[current_scene] = fog.get_save_data()
		
	var dnc = get_tree().get_first_node_in_group("day_night")
	if dnc:
		time_of_day = dnc.get_time()

	
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
		"fog_revealed": fog_data,
		"time_of_day": time_of_day,
		"used_books": used_books,
		"active_talents": Stats.active_talents,
	}
	
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game():
	if not FileAccess.file_exists("user://save.json"):
		print("Aucune sauvegarde trouvée")
		return false
	
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data is Dictionary:
		push_error("Sauvegarde corrompue ou invalide — impossible de charger")
		return false

	spawn_position = Vector2(data["position_x"], data["position_y"])
	player_health = data["health"]
	current_scene = data["scene"]
	Inventory.gold = int(data["gold"])
	Inventory.equipped_tool = data["equipped_tool"]
	
	if data.has("time_of_day"):
		time_of_day = float(data["time_of_day"])
	
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
		# Migration : ajoute les slots ajoutés après la création de la sauvegarde
		for slot in ["arme", "casque", "plastron", "bouclier", "bottes", "anneau", "amulette"]:
			if not Inventory.equipped.has(slot):
				Inventory.equipped[slot] = null
	
	if data.has("fog_revealed"):
		var raw = data["fog_revealed"]
		if raw is Dictionary:
			fog_data = raw
		else:
			fog_data = {}

	if data.has("used_books"):
		used_books = data["used_books"]
	else:
		used_books = []   # compatibilité anciennes sauvegardes

	if data.has("active_talents"):
		Stats.active_talents = data["active_talents"]
	else:
		Stats.active_talents = []   # compatibilité anciennes sauvegardes

	return true

func save_exists() -> bool:
	return FileAccess.file_exists("user://save.json")
