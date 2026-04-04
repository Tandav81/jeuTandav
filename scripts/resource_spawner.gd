extends Node2D
# ============================================================
#  ResourceSpawner
#  Spawne automatiquement plantes, minerais, ARBRES et COFFRES.
#
#  Plantes  → tiles herbe (source_id 2 = Grass_Middle,
#                           source_id 3 = FarmLand_Tile)
#  Minerais → tiles sable  (source_id 5 = Path_Middle)
#  Arbres   → tiles herbe, placement aléatoire
#  Coffres  → tiles herbe, placement aléatoire, respawn long
#
#  Quand une ressource est ramassée, elle réapparaît au bout
#  de RESPAWN_DELAY secondes à un NOUVEL emplacement aléatoire.
# ============================================================

const GRASS_SOURCE_IDS = [2, 3]
const SAND_SOURCE_ID   = 5

# ── Plantes ────────────────────────────────────────────────
const MAX_PLANTS     = 5      # maximum simultané par type de plante
const RESPAWN_DELAY  = 90.0   # secondes avant réapparition ailleurs
const MIN_DIST       = 28.0   # distance minimale entre deux ressources

# Sprites "carte" des minerais dans spr_tileset_sunnysideworld_16px.png
const _TILESET_PATH = "res://assets/Tileset/spr_tileset_sunnysideworld_16px.png"
const MINERAL_MAP_SPRITES = {
	"Minerai de fer": [Rect2(784, 336, 32, 32), Rect2(816, 336, 32, 32), Rect2(848, 336, 32, 32)],
	"Charbon":        [Rect2(784, 368, 32, 32), Rect2(816, 368, 32, 32), Rect2(848, 368, 32, 32)],
	"Cristal":        [Rect2(784, 400, 32, 32), Rect2(816, 400, 32, 32), Rect2(848, 400, 32, 32)],
	"Minerai d'or":   [Rect2(784, 432, 32, 32), Rect2(816, 432, 32, 32), Rect2(848, 432, 32, 32)],
	"Pierre brute":   [Rect2(784, 464, 32, 32), Rect2(816, 464, 32, 32), Rect2(848, 464, 32, 32)],
}

const PLANT_DEFS = [
	{"name": "Plante",     "qty": 1, "health": 1, "tool": ""},
	{"name": "Tournesol",  "qty": 1, "health": 1, "tool": ""},
	{"name": "Champignon", "qty": 1, "health": 1, "tool": ""},
	{"name": "Baie",       "qty": 1, "health": 1, "tool": ""},
]
const MINERAL_DEFS = [
	{"name": "Pierre brute",   "qty": 2, "health": 3,  "tool": "pioche", "max": 6},
	{"name": "Minerai de fer", "qty": 1, "health": 5,  "tool": "pioche", "max": 4},
	{"name": "Charbon",        "qty": 2, "health": 5,  "tool": "pioche", "max": 4},
	{"name": "Cristal",        "qty": 1, "health": 8,  "tool": "pioche", "max": 2},
	{"name": "Minerai d'or",   "qty": 1, "health": 10, "tool": "pioche", "max": 2},
]

# ── ✏️  ARBRES ──────────────────────────────────────────────
## Nombre total d'arbres à placer aléatoirement sur l'herbe
const TREE_COUNT: int = 30
## Distance minimale entre deux arbres (pixels)
const TREE_MIN_DIST: float = 48.0
## Types d'arbres (weight = fréquence relative, overrides = props resource.gd)
const TREE_DEFS: Array = [
	{
		"scene":     "res://scenes/tree.tscn",
		"weight":    1,
		"overrides": {}    # valeurs de tree.tscn : qty=2, health=3, respawn=30s, tool=hache
	},
	# ── Exemple : arbre fruitier (à décommenter quand la scène existe)
	# {
	#     "scene":     "res://scenes/fruit_tree.tscn",
	#     "weight":    1,
	#     "overrides": { "quantity": 1, "resource_name": "Pomme", "respawn_time": 120.0 }
	# },
]

# ── ✏️  COFFRES ─────────────────────────────────────────────
## Nombre maximum de coffres simultanément sur la carte
const MAX_CHESTS: int = 5
## Délai de réapparition d'un coffre après ouverture (secondes)
const CHEST_RESPAWN_DELAY: float = 600.0   # 10 minutes
## Distance minimale entre deux coffres (pixels)
const CHEST_MIN_DIST: float = 96.0
## Table de récompenses aléatoires (weight = poids relatif)
const CHEST_REWARDS: Array = [
	{"contenu": "Potion",          "quantite": 1, "gold_amount": 0,  "weight": 35},
	{"contenu": "or",              "quantite": 0, "gold_amount": 15, "weight": 25},
	{"contenu": "Minerai de fer",  "quantite": 2, "gold_amount": 0,  "weight": 20},
	{"contenu": "or",              "quantite": 0, "gold_amount": 30, "weight": 12},
	{"contenu": "Grande potion",   "quantite": 1, "gold_amount": 0,  "weight": 5},
	{"contenu": "Cristal",         "quantite": 1, "gold_amount": 0,  "weight": 3},
]

# ────────────────────────────────────────────────────────────
var _grass_positions: Array = []
var _sand_positions:  Array = []
var _terrain_layer:   TileMapLayer = null
var _resource_script  = preload("res://scripts/resource.gd")

# ============================================================
func _ready() -> void:
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
	# Plantes
	for def in PLANT_DEFS:
		for i in range(MAX_PLANTS):
			_try_spawn(def, true)
	# Minerais
	for def in MINERAL_DEFS:
		for i in range(def.get("max", 4)):
			_try_spawn(def, false)
	# Arbres (aléatoires)
	_spawn_trees()
	# Coffres
	for _i in range(MAX_CHESTS):
		_try_spawn_chest()

# ============================================================
#  SPAWN PLANTES / MINERAIS
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
	node.depleted.connect(_on_resource_depleted.bind(def, is_plant))

func _pick_free_position(pool: Array) -> Vector2:
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
#  SPAWN ARBRES
# ============================================================

func _spawn_trees() -> void:
	if _grass_positions.is_empty():
		return
	var placed: int = 0
	var attempts: int = 0
	# Limite les tentatives pour éviter boucle infinie
	while placed < TREE_COUNT and attempts < _grass_positions.size() * 3:
		var candidate: Vector2 = _grass_positions[randi() % _grass_positions.size()]
		attempts += 1
		# Vérifier la distance minimale avec tous les enfants déjà placés
		var too_close = false
		for child in get_children():
			if is_instance_valid(child) and child.position.distance_to(candidate) < TREE_MIN_DIST:
				too_close = true
				break
		if too_close:
			continue
		var def = _pick_tree_weighted()
		var scene_res = load(def["scene"])
		if not scene_res:
			push_error("ResourceSpawner : scène arbre introuvable — " + def["scene"])
			continue
		var node = scene_res.instantiate()
		node.position = candidate
		for key in def.get("overrides", {}).keys():
			node.set(key, def["overrides"][key])
		add_child(node)
		placed += 1

func _pick_tree_weighted() -> Dictionary:
	var total: int = 0
	for d in TREE_DEFS:
		total += d.get("weight", 1)
	var roll = randi() % max(total, 1)
	var acc = 0
	for d in TREE_DEFS:
		acc += d.get("weight", 1)
		if roll < acc:
			return d
	return TREE_DEFS[0]

# ============================================================
#  SPAWN COFFRES
# ============================================================

func _try_spawn_chest() -> void:
	if _grass_positions.is_empty():
		return
	var pos = _pick_free_chest_position()
	if pos == Vector2.INF:
		return
	var chest_scene = load("res://scenes/chest.tscn")
	if not chest_scene:
		push_error("ResourceSpawner : scène 'res://scenes/chest.tscn' introuvable !")
		return
	var node = chest_scene.instantiate()
	node.position = pos
	# Récompense aléatoire
	var reward = _pick_chest_reward()
	node.set("contenu",        reward["contenu"])
	node.set("quantite",       reward["quantite"])
	node.set("gold_amount",    reward["gold_amount"])
	node.set("is_respawnable", true)
	# Ajouter au groupe pour le comptage
	node.add_to_group("spawned_chest")
	add_child(node)
	# Écouter l'ouverture pour déclencher le respawn
	if node.has_signal("chest_opened"):
		node.chest_opened.connect(_on_chest_opened)

func _pick_chest_reward() -> Dictionary:
	var total: int = 0
	for r in CHEST_REWARDS:
		total += r.get("weight", 1)
	var roll = randi() % max(total, 1)
	var acc = 0
	for r in CHEST_REWARDS:
		acc += r.get("weight", 1)
		if roll < acc:
			return r
	return CHEST_REWARDS[0]

func _pick_free_chest_position() -> Vector2:
	for _attempt in range(60):
		var candidate: Vector2 = _grass_positions[randi() % _grass_positions.size()]
		var ok = true
		for child in get_children():
			if is_instance_valid(child) and child.position.distance_to(candidate) < CHEST_MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF

func _on_chest_opened() -> void:
	# Attendre le délai de respawn puis en créer un nouveau si sous le max
	await get_tree().create_timer(CHEST_RESPAWN_DELAY).timeout
	if not is_inside_tree():
		return
	var current_count = get_tree().get_nodes_in_group("spawned_chest").size()
	if current_count < MAX_CHESTS:
		_try_spawn_chest()

# ============================================================
#  RÉAPPARITION PLANTES / MINERAIS APRÈS RÉCOLTE
# ============================================================

func _on_resource_depleted(_res_name: String, def: Dictionary, is_plant: bool) -> void:
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
#  CONSTRUCTION DU NŒUD RESSOURCE (plantes / minerais)
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
#  TEXTURE CARTE (sprite affiché dans le monde)
# ============================================================

func _get_map_texture(item_name: String) -> Texture2D:
	if MINERAL_MAP_SPRITES.has(item_name):
		var variants: Array = MINERAL_MAP_SPRITES[item_name]
		var region: Rect2   = variants[randi() % variants.size()]
		if ResourceLoader.exists(_TILESET_PATH):
			var atlas        = AtlasTexture.new()
			atlas.atlas      = load(_TILESET_PATH)
			atlas.region     = region
			return atlas
	return ItemData.get_texture(item_name)
