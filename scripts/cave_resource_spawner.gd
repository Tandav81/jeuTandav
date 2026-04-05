extends Node2D
# ============================================================
#  CaveResourceSpawner
#  Spawne minerais et champignons dans la grotte.
#
#  Pas de plantes, pas d'arbres (pas de soleil).
#  Tiles valides : source_id = 13, atlas_coords = (2, 2)
#
#  Quand une ressource est récoltée, elle réapparaît après
#  RESPAWN_DELAY secondes à un nouvel emplacement aléatoire.
# ============================================================

const CAVE_SOURCE_ID    = 13
const CAVE_ATLAS_COORDS = Vector2i(2, 2)

# ── Sprites minerais dans le tileset ──────────────────────
const _TILESET_PATH = "res://assets/Tileset/spr_tileset_sunnysideworld_16px.png"
const MINERAL_MAP_SPRITES = {
	"Minerai de fer": [Rect2(784, 336, 32, 32), Rect2(816, 336, 32, 32), Rect2(848, 336, 32, 32)],
	"Charbon":        [Rect2(784, 368, 32, 32), Rect2(816, 368, 32, 32), Rect2(848, 368, 32, 32)],
	"Cristal":        [Rect2(784, 400, 32, 32), Rect2(816, 400, 32, 32), Rect2(848, 400, 32, 32)],
	"Minerai d'or":   [Rect2(784, 432, 32, 32), Rect2(816, 432, 32, 32), Rect2(848, 432, 32, 32)],
	"Pierre brute":   [Rect2(784, 464, 32, 32), Rect2(816, 464, 32, 32), Rect2(848, 464, 32, 32)],
}

# ── ✏️  RESSOURCES DE LA GROTTE ──────────────────────────
## Champignons de grotte (poussent sans soleil)
## "Baie" = le sprite bleu du tileset (Rect2 992,160) — appelé "champignon bleu" visuellement
const MUSHROOM_DEFS = [
	{"name": "Champignon", "qty": 1, "health": 1, "tool": "", "max": 6},
	{"name": "Baie",       "qty": 1, "health": 1, "tool": "", "max": 6},
]

## Minerais (plus abondants dans la grotte qu'en surface)
const MINERAL_DEFS = [
	{"name": "Pierre brute",   "qty": 3, "health": 3,  "tool": "pioche", "max": 10},
	{"name": "Minerai de fer", "qty": 1, "health": 5,  "tool": "pioche", "max": 6},
	{"name": "Charbon",        "qty": 2, "health": 5,  "tool": "pioche", "max": 6},
	{"name": "Cristal",        "qty": 1, "health": 8,  "tool": "pioche", "max": 4},
	{"name": "Minerai d'or",   "qty": 1, "health": 10, "tool": "pioche", "max": 3},
]

# ── ✏️  PARAMÈTRES GÉNÉRAUX ───────────────────────────────
## Distance minimale entre deux ressources (pixels)
const MIN_DIST: float = 28.0
## Délai avant réapparition d'une ressource récoltée (secondes)
const RESPAWN_DELAY: float = 90.0

# ────────────────────────────────────────────────────────────
var _cave_positions:  Array = []
var _terrain_layer:   TileMapLayer = null
var _resource_script  = preload("res://scripts/resource.gd")

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	if not _terrain_layer:
		push_error("CaveResourceSpawner: TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	if _cave_positions.is_empty():
		push_error("CaveResourceSpawner: aucune tile source_id=13 atlas=(2,2) trouvée !")
		return
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
	_cave_positions.clear()
	var tm_scale  = _terrain_layer.scale.x
	var tm_offset = _terrain_layer.position

	for cell in _terrain_layer.get_used_cells():
		var src    = _terrain_layer.get_cell_source_id(cell)
		var coords = _terrain_layer.get_cell_atlas_coords(cell)
		if src == CAVE_SOURCE_ID and coords == CAVE_ATLAS_COORDS:
			var local_px = _terrain_layer.map_to_local(cell)
			_cave_positions.append(local_px * tm_scale + tm_offset)

	_cave_positions.shuffle()

# ============================================================
#  SPAWN INITIAL
# ============================================================

func _initial_spawn() -> void:
	# Champignons (rouge + bleu)
	for def in MUSHROOM_DEFS:
		for i in range(def["max"]):
			_try_spawn(def)
	# Minerais
	for def in MINERAL_DEFS:
		for i in range(def["max"]):
			_try_spawn(def)

# ============================================================
#  SPAWN D'UNE RESSOURCE
# ============================================================

func _try_spawn(def: Dictionary) -> void:
	if _cave_positions.is_empty():
		return
	var pos = _pick_free_position()
	if pos == Vector2.INF:
		return
	var node = _build_resource_node(def, pos)
	add_child(node)
	node.depleted.connect(_on_resource_depleted.bind(def))

func _pick_free_position() -> Vector2:
	for _i in range(60):
		var candidate: Vector2 = _cave_positions[randi() % _cave_positions.size()]
		var ok = true
		for child in get_children():
			if is_instance_valid(child) and child.position.distance_to(candidate) < MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF

# ============================================================
#  RÉAPPARITION APRÈS RÉCOLTE
# ============================================================

func _on_resource_depleted(_res_name: String, def: Dictionary) -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	var current_count = 0
	for child in get_children():
		if is_instance_valid(child) and child.get("resource_name") == def["name"]:
			current_count += 1
	if current_count < def.get("max", 4):
		_try_spawn(def)

# ============================================================
#  CONSTRUCTION DU NŒUD RESSOURCE
# ============================================================

func _build_resource_node(def: Dictionary, pos: Vector2) -> Node2D:
	var node = Node2D.new()
	node.position = pos
	node.set_script(_resource_script)

	node.set("resource_type", "collectible")
	node.set("resource_name", def["name"])
	node.set("quantity",      def["qty"])
	node.set("respawn_time",  0.0)
	node.set("required_tool", def.get("tool", ""))
	node.set("health",        def["health"])

	var sprite = Sprite2D.new()
	sprite.name           = "Sprite2D"
	sprite.position       = Vector2(0, -4)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture        = _get_map_texture(def["name"])
	node.add_child(sprite)

	var col       = CollisionShape2D.new()
	col.name      = "CollisionShape2D"
	var col_shape = CircleShape2D.new()
	col_shape.radius = 6.0
	col.shape     = col_shape
	node.add_child(col)

	var zone              = Area2D.new()
	zone.name             = "InteractionZone"
	zone.collision_layer  = 0
	zone.collision_mask   = 1
	var zone_col          = CollisionShape2D.new()
	var zone_shape        = CircleShape2D.new()
	zone_shape.radius     = 20.0
	zone_col.shape        = zone_shape
	zone.add_child(zone_col)
	node.add_child(zone)

	return node

# ============================================================
#  TEXTURE SPRITE
# ============================================================

func _get_map_texture(item_name: String) -> Texture2D:
	if MINERAL_MAP_SPRITES.has(item_name):
		var variants: Array = MINERAL_MAP_SPRITES[item_name]
		var region: Rect2   = variants[randi() % variants.size()]
		if ResourceLoader.exists(_TILESET_PATH):
			var atlas   = AtlasTexture.new()
			atlas.atlas  = load(_TILESET_PATH)
			atlas.region = region
			return atlas
	return ItemData.get_texture(item_name)
