extends Node2D
# ============================================================
#  ResourceSpawner
#  Spawne automatiquement plantes et minerais sur la carte.
#
#  Plantes  → tiles herbe (source_id 2 = Grass_Middle,
#                           source_id 3 = FarmLand_Tile)
#  Minerais → tiles sable  (source_id 5 = Path_Middle)
#
#  Quand une ressource est ramassée, elle réapparaît au bout
#  de RESPAWN_DELAY secondes à un NOUVEL emplacement aléatoire.
# ============================================================

const GRASS_SOURCE_IDS = [2, 3]
const SAND_SOURCE_ID   = 5

const MAX_PLANTS     = 5      # maximum simultané par type de plante
const RESPAWN_DELAY  = 90.0   # secondes avant réapparition ailleurs
const MIN_DIST       = 28.0   # distance minimale entre deux ressources

# Sprites "carte" des minerais dans spr_tileset_sunnysideworld_16px.png
# 3 tailles de rocher par minerai, à gauche du gem (gem à x=880).
#   Grande taille : x=784, 32×32 px
#   Taille moyenne: x=816, 32×32 px
#   Petite taille : x=848, 32×32 px
# y_start = y_gem - 16  (le rocher dépasse d'une tile au-dessus de la ligne gem)
const _TILESET_PATH = "res://assets/Tileset/spr_tileset_sunnysideworld_16px.png"
const MINERAL_MAP_SPRITES = {
	"Minerai de fer": [Rect2(784, 336, 32, 32), Rect2(816, 336, 32, 32), Rect2(848, 336, 32, 32)],
	"Charbon":        [Rect2(784, 368, 32, 32), Rect2(816, 368, 32, 32), Rect2(848, 368, 32, 32)],
	"Cristal":        [Rect2(784, 400, 32, 32), Rect2(816, 400, 32, 32), Rect2(848, 400, 32, 32)],
	"Minerai d'or":   [Rect2(784, 432, 32, 32), Rect2(816, 432, 32, 32), Rect2(848, 432, 32, 32)],
	"Pierre brute":   [Rect2(784, 464, 32, 32), Rect2(816, 464, 32, 32), Rect2(848, 464, 32, 32)],
}

# ── Définitions des ressources ──────────────────────────────
const PLANT_DEFS = [
	{"name": "Plante",     "qty": 1, "health": 1, "tool": ""},
	{"name": "Tournesol",  "qty": 1, "health": 1, "tool": ""},
	{"name": "Champignon", "qty": 1, "health": 1, "tool": ""},
	{"name": "Baie",       "qty": 1, "health": 1, "tool": ""},
]
const MINERAL_DEFS = [
	{"name": "Pierre brute",   "qty": 2, "health": 3,  "tool": "pioche", "max": 6},  # commun    — 3 coups,  6 simultanés
	{"name": "Minerai de fer", "qty": 1, "health": 5,  "tool": "pioche", "max": 4},  # peu rare  — 5 coups,  4 simultanés
	{"name": "Charbon",        "qty": 2, "health": 5,  "tool": "pioche", "max": 4},  # peu rare  — 5 coups,  4 simultanés
	{"name": "Cristal",        "qty": 1, "health": 8,  "tool": "pioche", "max": 2},  # rare      — 8 coups,  2 simultanés
	{"name": "Minerai d'or",   "qty": 1, "health": 10, "tool": "pioche", "max": 2},  # très rare — 10 coups, 2 simultanés
]

var _grass_positions: Array = []
var _sand_positions:  Array = []
var _terrain_layer:   TileMapLayer = null
var _resource_script  = preload("res://scripts/resource.gd")

# ============================================================
func _ready() -> void:
	# Attend que la scène soit complètement chargée
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	if not _terrain_layer:
		push_error("ResourceSpawner: TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	_initial_spawn()

# ============================================================
#  SCAN DE LA TILEMAP
# ============================================================

func _find_terrain_layer() -> TileMapLayer:
	# Cherche "Terrains" dans le parent (World)
	var parent = get_parent()
	if parent:
		var found = parent.find_child("Terrains", false, false)
		if found is TileMapLayer:
			return found
	return null

func _scan_tiles() -> void:
	_grass_positions.clear()
	_sand_positions.clear()

	var tm_scale  = _terrain_layer.scale.x
	var tm_offset = _terrain_layer.position

	for cell in _terrain_layer.get_used_cells():
		var src      = _terrain_layer.get_cell_source_id(cell)
		var local_px = _terrain_layer.map_to_local(cell)
		var world_px = local_px * tm_scale + tm_offset

		if src in GRASS_SOURCE_IDS:
			_grass_positions.append(world_px)
		elif src == SAND_SOURCE_ID:
			_sand_positions.append(world_px)

	_grass_positions.shuffle()
	_sand_positions.shuffle()

# ============================================================
#  SPAWN INITIAL
# ============================================================

func _initial_spawn() -> void:
	for def in PLANT_DEFS:
		for i in range(MAX_PLANTS):
			_try_spawn(def, true)
	for def in MINERAL_DEFS:
		for i in range(def.get("max", 4)):
			_try_spawn(def, false)

# ============================================================
#  SPAWN D'UNE RESSOURCE
# ============================================================

func _try_spawn(def: Dictionary, is_plant: bool) -> void:
	var pool = _grass_positions if is_plant else _sand_positions
	if pool.is_empty():
		return
	var pos = _pick_free_position(pool)
	if pos == Vector2.INF:
		return
	var node = _build_resource_node(def, pos)
	add_child(node)
	# Connexion au signal depleted pour gérer la réapparition ailleurs
	node.depleted.connect(_on_resource_depleted.bind(def, is_plant))

func _pick_free_position(pool: Array) -> Vector2:
	# Tente jusqu'à 40 fois de trouver un emplacement libre
	for _i in range(40):
		var candidate: Vector2 = pool[randi() % pool.size()]
		var ok = true
		for child in get_children():
			if is_instance_valid(child) and child.position.distance_to(candidate) < MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF

# ============================================================
#  CONSTRUCTION DU NŒUD RESSOURCE
# ============================================================

func _build_resource_node(def: Dictionary, pos: Vector2) -> Node2D:
	var node = Node2D.new()
	node.position = pos
	node.set_script(_resource_script)

	# Propriétés exportées du script resource.gd
	node.set("resource_type", "collectible")
	node.set("resource_name", def["name"])
	node.set("quantity",      def["qty"])
	node.set("respawn_time",  0.0)   # Spawner gère le respawn, pas resource.gd
	node.set("required_tool", def.get("tool", ""))
	node.set("health",        def["health"])

	# ── Sprite2D ────────────────────────────────────────────
	var sprite = Sprite2D.new()
	sprite.name           = "Sprite2D"
	sprite.position       = Vector2(0, -4)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture        = _get_map_texture(def["name"])
	node.add_child(sprite)

	# ── CollisionShape2D (attendu par resource.gd) ──────────
	var col       = CollisionShape2D.new()
	col.name      = "CollisionShape2D"
	var col_shape = CircleShape2D.new()
	col_shape.radius = 6.0
	col.shape     = col_shape
	node.add_child(col)

	# ── Zone d'interaction (Area2D) ─────────────────────────
	var zone              = Area2D.new()
	zone.name             = "InteractionZone"
	zone.collision_layer  = 0
	zone.collision_mask   = 1   # Layer 1 = joueur
	var zone_col          = CollisionShape2D.new()
	var zone_shape        = CircleShape2D.new()
	zone_shape.radius     = 20.0
	zone_col.shape        = zone_shape
	zone.add_child(zone_col)
	node.add_child(zone)

	return node

# ============================================================
#  RÉAPPARITION APRÈS RÉCOLTE
# ============================================================

func _on_resource_depleted(res_name: String, def: Dictionary, is_plant: bool) -> void:
	# Attend RESPAWN_DELAY secondes puis respawne ailleurs si sous le max
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	var max_count = MAX_PLANTS if is_plant else def.get("max", 4)
	var current_count = 0
	for child in get_children():
		if is_instance_valid(child) and child.get("resource_name") == def["name"]:
			current_count += 1
	if current_count < max_count:
		_try_spawn(def, is_plant)

# ============================================================
#  TEXTURE CARTE (sprite affiché dans le monde)
# ============================================================

func _get_map_texture(item_name: String) -> Texture2D:
	# Minerais → forme de rocher aléatoire parmi les 3 variantes
	if MINERAL_MAP_SPRITES.has(item_name):
		var variants: Array = MINERAL_MAP_SPRITES[item_name]
		var region: Rect2   = variants[randi() % variants.size()]
		if ResourceLoader.exists(_TILESET_PATH):
			var atlas        = AtlasTexture.new()
			atlas.atlas      = load(_TILESET_PATH)
			atlas.region     = region
			return atlas

	# Plantes → icône inventaire (déjà dans le tileset via ItemData)
	return ItemData.get_texture(item_name)
