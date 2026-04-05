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
	"Epee en or": {
		"slot": "arme", "force": 14, "endurance": 0,
		"agilite": 1, "magie": 0, "defense": 0,
		"description": "Lame tranchante forgée dans l'or pur"
	},
	"Baton magique": {
		"slot": "arme", "force": 0, "endurance": 0,
		"agilite": 0, "magie": 10, "defense": 0,
		"description": "Amplifie les sorts magiques"
	},
	"Arc": {
		"slot": "arme", "force": 2, "endurance": 0,
		"agilite": 4, "magie": 0, "defense": 0,
		"description": "Attaque à distance — portée : Force + Agilité"
	},
	"Arc en fer": {
		"slot": "arme", "force": 4, "endurance": 0,
		"agilite": 6, "magie": 0, "defense": 0,
		"description": "Attaque à distance — flèches puissantes"
	},
	# Armures
	"Casque en cuir": {
		"slot": "casque", "force": 0, "endurance": 2,
		"agilite": 0, "magie": 0, "defense": 3,
		"description": "Protection légère pour la tête"
	},
	"Casque en fer": {
		"slot": "casque", "force": 0, "endurance": 3,
		"agilite": -1, "magie": 0, "defense": 6,
		"description": "Heaume forgé dans le fer"
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
	"Bottes en fer": {
		"slot": "bottes", "force": 0, "endurance": 1,
		"agilite": -1, "magie": 0, "defense": 4,
		"description": "Protection robuste pour les pieds"
	},
	# Boucliers
	"Bouclier en bois": {
		"slot": "bouclier", "force": 0, "endurance": 0,
		"agilite": -1, "magie": 0, "defense": 4,
		"description": "Protection basique, mais ralentit un peu"
	},
	"Bouclier en fer": {
		"slot": "bouclier", "force": 0, "endurance": 1,
		"agilite": -2, "magie": 0, "defense": 9,
		"description": "Bouclier solide forgé dans le fer"
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
signal mana_changed(current_mana, max_mana)
signal talent_available(choices: Array)

# ── Talents passifs ──────────────────────────────────────────
const TALENT_EVERY_N_LEVELS = 5

const TALENT_POOL = [
	{ "id": "regen_on_kill",   "label": "Vampire",           "desc": "+5 PV à chaque kill ennemi" },
	{ "id": "speed_boost",     "label": "Leste",             "desc": "Vitesse de déplacement +15%" },
	{ "id": "piercing_arrows", "label": "Flèches perçantes", "desc": "Les flèches traversent les ennemis" },
	{ "id": "max_health_up",   "label": "Robuste",           "desc": "PV maximum +30" },
	{ "id": "crit_chance",     "label": "Précision",         "desc": "20% de chances de coup critique (×1.5)" },
	{ "id": "mana_regen_up",   "label": "Mystique",          "desc": "Régénération de mana ×2" },
	{ "id": "double_loot",     "label": "Chanceux",          "desc": "Les ressources récoltées donnent ×2 objets" },
	{ "id": "dash_heal",       "label": "Esquiveur",         "desc": "+3 PV à chaque esquive réussie" },
]

var active_talents: Array = []

# ---- Mana -------------------------------------------------------
# La mana alimente les attaques magiques. Elle se régénère au fil du temps.
# max_mana et regen dépendent de la stat Magie.
var current_mana: float = 0.0   # initialisé dans _ready après calcul des stats

func _ready() -> void:
	current_mana = float(get_max_mana())

func _process(delta: float) -> void:
	_regen_mana(delta)

func get_max_mana() -> int:
	return 20 + get_magie() * 8             # ex. magie=5 → 60 mana


func get_mana_cost_sort() -> int:
	# Coût par attaque magique ; diminue quand la magie augmente
	return max(5, 20 - get_magie())         # ex. magie=5 → 15, magie=15 → 5

func restore_mana(amount: float) -> void:
	current_mana = min(float(get_max_mana()), current_mana + amount)
	mana_changed.emit(current_mana, float(get_max_mana()))

func use_mana(amount: float) -> bool:
	if current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, float(get_max_mana()))
	return true

func _regen_mana(delta: float) -> void:
	if current_mana >= float(get_max_mana()):
		return
	var new_mana = min(float(get_max_mana()), current_mana + get_mana_regen() * delta)
	if new_mana != current_mana:
		current_mana = new_mana
		mana_changed.emit(current_mana, float(get_max_mana()))

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
	var bonus = 30 if has_talent("max_health_up") else 0
	return 100 + (get_endurance() * 10) + bonus

func get_damage() -> int:
	return 10 + (get_force() * 2)

func get_speed() -> float:
	var mult = 1.15 if has_talent("speed_boost") else 1.0
	return (150.0 + (get_agilite() * 5.0)) * mult

func get_mana_regen() -> float:
	var mult = 2.0 if has_talent("mana_regen_up") else 1.0
	return (1.0 + get_magie() * 0.4) * mult

func _get_equipment_bonus(stat: String) -> int:
	var total = 0
	for slot in Inventory.equipped:
		var item_name = Inventory.equipped[slot]
		if item_name != null and equipment_data.has(item_name):
			total += equipment_data[item_name][stat]
	return total

func add_xp(amount: int):
	xp += amount
	while xp >= xp_next_level:
		_level_up()
	stats_changed.emit()

func _level_up():
	xp -= xp_next_level
	level += 1
	stat_points += 3  # 3 points à distribuer par niveau
	xp_next_level = int(xp_next_level * 1.5)  # XP nécessaire augmente
	level_up.emit(level)
	# Proposition de talent tous les N niveaux
	if level % TALENT_EVERY_N_LEVELS == 0:
		_propose_talents()

func _propose_talents() -> void:
	# Piocher 3 talents distincts non encore acquis dans le pool
	var pool = TALENT_POOL.filter(func(t): return not has_talent(t["id"]))
	pool.shuffle()
	var choices = pool.slice(0, min(3, pool.size()))
	if choices.is_empty():
		return
	talent_available.emit(choices)

func apply_talent(talent_id: String) -> void:
	if has_talent(talent_id):
		return
	active_talents.append(talent_id)
	stats_changed.emit()

func has_talent(talent_id: String) -> bool:
	return active_talents.has(talent_id)

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
	stats_changed.emit()
	return true
