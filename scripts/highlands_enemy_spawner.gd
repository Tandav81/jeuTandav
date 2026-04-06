extends Node2D
# ============================================================
#  HIGHLANDSEnemySpawner
#  Spawne des ennemis dans la grotte — pas de cycle jour/nuit.
#  Les ennemis sont présents en permanence et réapparaissent
#  après leur mort.
#
#  Tiles valides : source_id = 13, atlas_coords = (2, 2)
#
#  🔧 AJOUTER UN ENNEMI DE GROTTE :
#  Dans HIGHLANDS_ENEMY_DEFS, ajoute un dictionnaire :
#  {
#      "scene":  "res://scenes/MON_ENNEMI.tscn",
#      "max":    4,
#      "overrides": { "speed": 60.0, "max_health": 40 }  ← optionnel
#  }
# ============================================================

const HIGHLANDS_SOURCE_ID    = 1
const HIGHLANDS_ATLAS_COORDS = Vector2i(3, 3)

# ── ✏️  CONFIGURATION DES ENNEMIS DE GROTTE ─────────────────
const HIGHLANDS_ENEMY_DEFS: Array = [
	{
		"scene": "res://scenes/bat.tscn",
		"max":   30,
		"overrides": {}
	},
	{
		"scene": "res://scenes/skeleton.tscn",
		"max":   20,
		"overrides": {
			"speed":             65.0,
			"damage_per_second": 12.0,
		}
	},
	{
		"scene": "res://scenes/slime.tscn",
		"max":   20,
		"overrides": {}
	},
	{
		"scene": "res://scenes/flyingMushroom.tscn",
		"max":   5,
		"overrides": {}
	},
]

# ── ✏️  PARAMÈTRES GÉNÉRAUX ──────────────────────────────────
## Distance minimale entre deux ennemis spawnés (pixels)
const MIN_DIST: float = 80.0
## Distance minimale entre un spawn et le joueur (pixels)
const PLAYER_SAFE_DIST: float = 200.0
## Délai avant réapparition d'un ennemi mort (secondes)
const RESPAWN_DELAY: float = 30.0
## Durée du fondu d'apparition (secondes)
const FADE_DURATION: float = 1.0

# ────────────────────────────────────────────────────────────
var _spawn_positions: Array = []
var _terrain_layer:   TileMapLayer = null
var _player:          Node = null

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	_player = get_tree().get_first_node_in_group("player")

	if not _terrain_layer:
		push_error("CaveEnemySpawner : TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	if _spawn_positions.is_empty():
		push_error("CaveEnemySpawner : aucune tile source_id=13 atlas=(2,2) trouvée !")
		return
	_spawn_all()

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
	_spawn_positions.clear()
	var tm_scale  = _terrain_layer.scale.x
	var tm_offset = _terrain_layer.position

	for cell in _terrain_layer.get_used_cells():
		var src    = _terrain_layer.get_cell_source_id(cell)
		var coords = _terrain_layer.get_cell_atlas_coords(cell)
		if src == HIGHLANDS_SOURCE_ID and coords == HIGHLANDS_ATLAS_COORDS:
			var local_px = _terrain_layer.map_to_local(cell)
			_spawn_positions.append(local_px * tm_scale + tm_offset)

	_spawn_positions.shuffle()

# ============================================================
#  SPAWN INITIAL
# ============================================================

func _spawn_all() -> void:
	for def in HIGHLANDS_ENEMY_DEFS:
		for _i in range(def["max"]):
			_try_spawn(def)

# ============================================================
#  SPAWN D'UN ENNEMI
# ============================================================

func _try_spawn(def: Dictionary) -> void:
	var pos = _pick_free_position()
	if pos == Vector2.INF:
		return
	var scene_res = load(def["scene"])
	if not scene_res:
		push_error("CaveEnemySpawner : scène introuvable — " + def["scene"])
		return
	var node = scene_res.instantiate()
	node.position = pos
	for key in def.get("overrides", {}).keys():
		node.set(key, def["overrides"][key])
	# Apparition en fondu
	node.modulate.a = 0.0
	add_child(node)
	var tw = create_tween()
	tw.tween_property(node, "modulate:a", 1.0, FADE_DURATION)
	# Réapparition automatique à la mort
	if node.has_signal("died"):
		node.died.connect(_on_enemy_died.bind(def))

func _pick_free_position() -> Vector2:
	if _spawn_positions.is_empty():
		return Vector2.INF
	for _attempt in range(60):
		var candidate: Vector2 = _spawn_positions[randi() % _spawn_positions.size()]
		if is_instance_valid(_player) and \
			_player.global_position.distance_to(candidate) < PLAYER_SAFE_DIST:
			continue
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

func _on_enemy_died(def: Dictionary) -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	# Compter les ennemis vivants de ce type
	var current_count = 0
	for child in get_children():
		if is_instance_valid(child) and child.scene_file_path == def["scene"]:
			current_count += 1
	if current_count < def["max"]:
		_try_spawn(def)
