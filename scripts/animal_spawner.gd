extends Node2D
# ============================================================
#  AnimalSpawner
#  Spawne automatiquement les animaux sur les tiles herbe.
#  Quand un animal est tué, il réapparaît à un nouvel emplacement
#  après RESPAWN_DELAY secondes.
# ============================================================

const GRASS_SOURCE_IDS = [2, 3]

const RESPAWN_DELAY = 120.0  # secondes avant réapparition
const MIN_DIST      = 60.0   # distance minimale entre deux animaux au spawn

# Définition de chaque type d'animal
# "name"      : identifiant (= animal_name exporté dans animal.gd)
# "scene"     : chemin vers la scène à instancier
# "max"       : nombre maximum simultané
# "overrides" : propriétés à écraser après instanciation
const ANIMAL_DEFS = [
	{
		"name":      "Mouton",
		"scene":     "res://scenes/mouton.tscn",
		"max":       6,
		"overrides": {}   # valeurs par défaut de animal.gd : Viande×1 + Peau×1, health=2
	},
	{
		"name":      "Poulet",
		"scene":     "res://scenes/poulet.tscn",
		"max":       12,
		"overrides": {}   # valeurs par défaut de animal.gd : Viande×1 + Peau×1, health=2
	},
	{
		"name":      "Vache",
		"scene":     "res://scenes/vache.tscn",
		"max":       3,
		"overrides": {}
	},
]

var _grass_positions: Array = []
var _terrain_layer: TileMapLayer = null

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	if not _terrain_layer:
		push_error("AnimalSpawner: TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	_initial_spawn()

# ============================================================
#  SCAN DE LA TILEMAP
# ============================================================

func _find_terrain_layer() -> TileMapLayer:
	var parent = get_parent()
	if parent:
		var found = parent.find_child("Terrains", false, false)
		if found is TileMapLayer:
			return found
	return null

func _scan_tiles() -> void:
	_grass_positions.clear()
	var tm_scale  = _terrain_layer.scale.x
	var tm_offset = _terrain_layer.position
	for cell in _terrain_layer.get_used_cells():
		var src      = _terrain_layer.get_cell_source_id(cell)
		var local_px = _terrain_layer.map_to_local(cell)
		var world_px = local_px * tm_scale + tm_offset
		if src in GRASS_SOURCE_IDS:
			_grass_positions.append(world_px)
	_grass_positions.shuffle()

# ============================================================
#  SPAWN INITIAL
# ============================================================

func _initial_spawn() -> void:
	for def in ANIMAL_DEFS:
		for i in range(def["max"]):
			_try_spawn(def)

# ============================================================
#  SPAWN D'UN ANIMAL
# ============================================================

func _try_spawn(def: Dictionary) -> void:
	if _grass_positions.is_empty():
		return
	var pos = _pick_free_position()
	if pos == Vector2.INF:
		return
	var scene = load(def["scene"])
	if not scene:
		push_error("AnimalSpawner: scène introuvable — " + def["scene"])
		return
	var node = scene.instantiate()
	node.position = pos
	# Appliquer les surcharges de propriétés
	for key in def["overrides"].keys():
		node.set(key, def["overrides"][key])
	add_child(node)
	# Connexion au signal died pour gérer la réapparition
	node.died.connect(_on_animal_died.bind(def))

func _pick_free_position() -> Vector2:
	for _i in range(50):
		var candidate: Vector2 = _grass_positions[randi() % _grass_positions.size()]
		var ok = true
		for child in get_children():
			if is_instance_valid(child) and child.global_position.distance_to(candidate) < MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF

# ============================================================
#  RÉAPPARITION APRÈS MORT
# ============================================================

func _on_animal_died(_name: String, def: Dictionary) -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	# Vérifier si on est encore en dessous du maximum
	var current_count = 0
	for child in get_children():
		if is_instance_valid(child) and child.get("animal_name") == def["name"]:
			current_count += 1
	if current_count < def["max"]:
		_try_spawn(def)
