extends Node2D
# ============================================================
#  DayEnemySpawner
#  Spawne des ennemis diurnes uniquement pendant la journée.
#  Ils disparaissent (fade out + queue_free) à la nuit tombée.
#
#  🔧 AJOUTER UN ENNEMI DIURNE :
#  Dans DAY_ENEMY_DEFS, ajoute un dictionnaire :
#  {
#      "scene":  "res://scenes/MON_ENNEMI.tscn",   ← scène Godot
#      "max":    4,                                 ← nb max simultané
#      "overrides": {                               ← propriétés à écraser (optionnel)
#          "speed": 60.0,
#          "damage_per_second": 10.0,
#          "max_health": 40,
#          "xp_reward": 15,
#      }
#  }
# ============================================================

# ── ✏️  CONFIGURATION DES ENNEMIS DIURNES ───────────────────
const DAY_ENEMY_DEFS: Array = [
	{
		"scene":     "res://scenes/slime.tscn",
		"max":       6,
		"overrides": {}   # valeurs par défaut de slime.tscn
	},
	{
		"scene":     "res://scenes/skeleton.tscn",
		"max":       4,
		"overrides": {
			"speed":             55.0,
			"damage_per_second": 10.0,
		}
	},
	{
		"scene":     "res://scenes/flyingMushroom.tscn",
		"max":       3,
		"overrides": {}
	},
	# ── Exemple : ajouter un gobelin (à décommenter quand la scène existe)
	# {
	#     "scene":     "res://scenes/goblin.tscn",
	#     "max":       5,
	#     "overrides": { "speed": 70.0, "max_health": 30 }
	# },
]

# ── ✏️  PARAMÈTRES GÉNÉRAUX ──────────────────────────────────
## Distance minimale entre deux ennemis spawnés (pixels)
const MIN_DIST: float = 80.0
## Distance minimale entre un spawn et le joueur (pixels)
const PLAYER_SAFE_DIST: float = 220.0
## Durée du fondu d'apparition / disparition (secondes)
const FADE_DURATION: float = 1.2

# ── Terrain valide pour spawner : herbe + chemin/sable ───────
const VALID_SOURCE_IDS: Array = [2, 3, 5]

# ────────────────────────────────────────────────────────────
var _spawn_positions: Array = []
var _terrain_layer:   TileMapLayer = null
var _player:          Node = null
var _is_day:          bool = false

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	_player = get_tree().get_first_node_in_group("player")

	if not _terrain_layer:
		push_error("DayEnemySpawner : TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()

	# Se connecter au signal du cycle jour/nuit
	var day_night = get_tree().get_first_node_in_group("day_night")
	if not day_night:
		push_error("DayEnemySpawner : nœud 'day_night' introuvable (groupe manquant) !")
		return
	day_night.time_of_day_changed.connect(_on_time_of_day_changed)

	# État initial : si on démarre le jour, spawner immédiatement
	if not day_night.is_night():
		_on_time_of_day_changed("day")

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
		var src = _terrain_layer.get_cell_source_id(cell)
		if src in VALID_SOURCE_IDS:
			var local_px = _terrain_layer.map_to_local(cell)
			_spawn_positions.append(local_px * tm_scale + tm_offset)
	_spawn_positions.shuffle()

# ============================================================
#  RÉACTION AU CYCLE JOUR/NUIT
# ============================================================

func _on_time_of_day_changed(period: String) -> void:
	match period:
		"day", "dawn":
			if not _is_day:
				_is_day = true
				_spawn_all_day_enemies()
		"night", "dusk":
			if _is_day:
				_is_day = false
				_despawn_all()

# ============================================================
#  SPAWN INITIAL DU JOUR
# ============================================================

func _spawn_all_day_enemies() -> void:
	for def in DAY_ENEMY_DEFS:
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
		push_error("DayEnemySpawner : scène introuvable — " + def["scene"])
		return
	var node = scene_res.instantiate()
	node.position = pos
	# Appliquer les surcharges de propriétés
	for key in def.get("overrides", {}).keys():
		node.set(key, def["overrides"][key])
	# Apparition en fondu
	node.modulate.a = 0.0
	add_child(node)
	var tw = create_tween()
	tw.tween_property(node, "modulate:a", 1.0, FADE_DURATION)

func _pick_free_position() -> Vector2:
	if _spawn_positions.is_empty():
		return Vector2.INF
	for _attempt in range(60):
		var candidate: Vector2 = _spawn_positions[randi() % _spawn_positions.size()]
		# Distance sécurité joueur
		if is_instance_valid(_player) and \
			_player.global_position.distance_to(candidate) < PLAYER_SAFE_DIST:
			continue
		# Distance entre spawns déjà placés
		var ok = true
		for child in get_children():
			if is_instance_valid(child) and child.global_position.distance_to(candidate) < MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF

# ============================================================
#  DÉPOP À LA NUIT
# ============================================================

func _despawn_all() -> void:
	for child in get_children():
		if is_instance_valid(child):
			_fade_and_free(child)

func _fade_and_free(node: Node) -> void:
	var col = node.find_child("CollisionShape2D", false, false)
	if col:
		col.set_deferred("disabled", true)
	node.set_physics_process(false)
	var tw = create_tween()
	tw.tween_property(node, "modulate:a", 0.0, FADE_DURATION)
	tw.tween_callback(node.queue_free)
