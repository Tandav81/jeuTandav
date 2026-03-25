extends Node

# Niveau et XP
var level = 1
var xp = 0
var xp_next_level = 100  # XP nécessaire pour le prochain niveau
var stat_points = 0      # Points à distribuer

# Stats de base
var base_force = 5
var base_endurance = 5
var base_agilite = 5
var base_magie = 5
var base_defense = 5

# Données des équipements
# Format : nom -> {slot, force, endurance, agilite, magie, defense, description}
var equipment_data = {
	# Armes
	"Epee en bois": {
		"slot": "arme", "force": 3, "endurance": 0,
		"agilite": 0, "magie": 0, "defense": 0,
		"description": "Une épée basique en bois"
	},
	"Epee en fer": {
		"slot": "arme", "force": 8, "endurance": 0,
		"agilite": 0, "magie": 0, "defense": 0,
		"description": "Une épée solide en fer"
	},
	"Baton magique": {
		"slot": "arme", "force": 0, "endurance": 0,
		"agilite": 0, "magie": 10, "defense": 0,
		"description": "Amplifie les sorts magiques"
	},
	# Armures
	"Casque en cuir": {
		"slot": "casque", "force": 0, "endurance": 2,
		"agilite": 0, "magie": 0, "defense": 3,
		"description": "Protection légère pour la tête"
	},
	"Plastron en fer": {
		"slot": "plastron", "force": 0, "endurance": 5,
		"agilite": -1, "magie": 0, "defense": 8,
		"description": "Armure lourde mais solide"
	},
	"Bottes légères": {
		"slot": "bottes", "force": 0, "endurance": 0,
		"agilite": 4, "magie": 0, "defense": 1,
		"description": "Augmente la vitesse de déplacement"
	},
	# Accessoires
	"Anneau de force": {
		"slot": "anneau", "force": 5, "endurance": 0,
		"agilite": 0, "magie": 0, "defense": 0,
		"description": "Augmente la force au combat"
	},
	"Amulette de magie": {
		"slot": "amulette", "force": 0, "endurance": 0,
		"agilite": 0, "magie": 8, "defense": 0,
		"description": "Amplifie la puissance magique"
	},
}

signal stats_changed
signal level_up(new_level)

# Stats totales (base + équipements)
func get_force() -> int:
	return base_force + _get_equipment_bonus("force")

func get_endurance() -> int:
	return base_endurance + _get_equipment_bonus("endurance")

func get_agilite() -> int:
	return base_agilite + _get_equipment_bonus("agilite")

func get_magie() -> int:
	return base_magie + _get_equipment_bonus("magie")

func get_defense() -> int:
	return base_defense + _get_equipment_bonus("defense")

func get_max_health() -> int:
	return 100 + (get_endurance() * 10)

func get_damage() -> int:
	return 10 + (get_force() * 2)

func get_speed() -> float:
	return 150.0 + (get_agilite() * 5.0)

func _get_equipment_bonus(stat: String) -> int:
	var total = 0
	for slot in Inventory.equipped:
		var item_name = Inventory.equipped[slot]
		if item_name != null and equipment_data.has(item_name):
			total += equipment_data[item_name][stat]
	return total

func add_xp(amount: int):
	xp += amount
	print("XP : ", xp, "/", xp_next_level)
	while xp >= xp_next_level:
		_level_up()
	emit_signal("stats_changed")

func _level_up():
	xp -= xp_next_level
	level += 1
	stat_points += 3  # 3 points à distribuer par niveau
	xp_next_level = int(xp_next_level * 1.5)  # XP nécessaire augmente
	emit_signal("level_up", level)
	print("NIVEAU ", level, " ! Tu as ", stat_points, " points à distribuer !")

func spend_point(stat: String) -> bool:
	if stat_points <= 0:
		return false
	match stat:
		"force":
			base_force += 1
		"endurance":
			base_endurance += 1
		"agilite":
			base_agilite += 1
		"magie":
			base_magie += 1
		"defense":
			base_defense += 1
	stat_points -= 1
	emit_signal("stats_changed")
	return true
