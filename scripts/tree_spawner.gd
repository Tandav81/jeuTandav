extends Node2D
# ============================================================
#  TreeSpawner
#  Spawne des arbres aléatoirement sur les tiles herbe.
#  Les arbres utilisent resource.gd : ils gèrent eux-mêmes
#  leur respawn en place après avoir été coupés à la hache.
#
#  🔧 AJOUTER UN TYPE D'ARBRE :
#  Dans TREE_DEFS, ajoute un dictionnaire :
#  {
#      "scene":    "res://scenes/MON_ARBRE.tscn",
#      "weight":   3,      ← fréquence relative (plus grand = plus fréquent)
#      "overrides": {      ← propriétés resource.gd à écraser (optionnel)
#          "quantity":      3,
#          "health":        5,
#          "respawn_time":  60.0,
#      }
#  }
# ============================================================

# ── ✏️  TYPES D'ARBRES ───────────────────────────────────────
const TREE_DEFS: Array = [
	{
		"scene":     "res://scenes/tree.tscn",
		"weight":    1,        # seul type pour l'instant
		"overrides": {}        # valeurs de tree.tscn : qty=2, health=3, respawn=30s, tool=hache
	},
	# ── Exemple : arbre fruitier (à décommenter quand la scène existe)
	# {
	#     "scene":     "res://scenes/fruit_tree.tscn",
	#     "weight":    1,
	#     "overrides": { "quantity": 1, "resource_name": "Pomme", "respawn_time": 120.0 }
	# },
]

# ── ✏️  PARAMÈTRES GÉNÉRAUX ──────────────────────────────────
## Nombre total d'arbres à placer sur la carte
const TREE_COUNT: int = 20
## Distance minimale entre deux arbres (pixels)
const MIN_DIST: float = 48.0
## Graine aléatoire fixe — garantit les mêmes positions à chaque lancement
## Changer cette valeur génère une nouvelle disposition d'arbres
const PLACEMENT_SEED: int = 42

# ── Terrain valide : herbe uniquement ────────────────────────
const VALID_SOURCE_IDS: Array = [2, 3]

# ────────────────────────────────────────────────────────────
var _grass_positions: Array = []
var _terrain_layer:   TileMapLayer = null

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	if not _terrain_layer:
		push_error("TreeSpawner : TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	_spawn_trees()

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
		if src in VALID_SOURCE_IDS:
			_grass_positions.append(local_px * tm_scale + tm_offset)
	# Mélange avec graine fixe pour des positions déterministes
	var rng = RandomNumberGenerator.new()
	rng.seed = PLACEMENT_SEED
	for i in range(_grass_positions.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = _grass_positions[i]
		_grass_positions[i] = _grass_positions[j]
		_grass_positions[j] = tmp

# ============================================================
#  PLACEMENT DES ARBRES
# ============================================================

func _spawn_trees() -> void:
	if _grass_positions.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = PLACEMENT_SEED
	var placed: int = 0
	var attempts: int = 0

	while placed < TREE_COUNT and attempts < _grass_positions.size():
		var candidate: Vector2 = _grass_positions[attempts]
		attempts += 1

		# Vérifier la distance minimale avec les arbres déjà placés
		var too_close = false
		for child in get_children():
			if is_instance_valid(child) and child.position.distance_to(candidate) < MIN_DIST:
				too_close = true
				break
		if too_close:
			continue

		# Choisir un type d'arbre selon les poids
		var def = _pick_weighted(rng)
		_place_tree(def, candidate)
		placed += 1

func _pick_weighted(rng: RandomNumberGenerator) -> Dictionary:
	var total_weight: int = 0
	for d in TREE_DEFS:
		total_weight += d.get("weight", 1)
	var roll = rng.randi_range(0, total_weight - 1)
	var acc = 0
	for d in TREE_DEFS:
		acc += d.get("weight", 1)
		if roll < acc:
			return d
	return TREE_DEFS[0]

func _place_tree(def: Dictionary, pos: Vector2) -> void:
	var scene_res = load(def["scene"])
	if not scene_res:
		push_error("TreeSpawner : scène introuvable — " + def["scene"])
		return
	var node = scene_res.instantiate()
	node.position = pos
	# Appliquer les surcharges (quantité, health, respawn_time…)
	for key in def.get("overrides", {}).keys():
		node.set(key, def["overrides"][key])
	add_child(node)
