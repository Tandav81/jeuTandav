extends Node2D
# ============================================================
#  ChestSpawner
#  Place des coffres aléatoirement sur la carte au démarrage.
#  Les coffres sont PERMANENTS : une fois ouverts, ils restent
#  ouverts entre les sessions (géré par GameManager.coffres_ouverts).
#
#  Les positions sont déterministes (graine fixe) : un coffre
#  "SpawnedChest_0" sera toujours au même endroit, ce qui permet
#  à GameManager de retrouver son état après rechargement.
#
#  🔧 AJOUTER UN COFFRE :
#  Dans CHEST_DEFS, ajoute un dictionnaire :
#  {
#      "contenu":   "Potion",   ← nom de l'item (ou "or")
#      "quantite":  2,          ← quantité d'items
#      "gold_amount": 0,        ← or donné (utilisé si contenu = "or")
#  }
#  Les coffres sont placés dans l'ordre du tableau — le premier
#  sera SpawnedChest_0, le deuxième SpawnedChest_1, etc.
# ============================================================

# ── ✏️  CONTENU DES COFFRES ──────────────────────────────────
const CHEST_DEFS: Array = [
	{ "contenu": "Potion",        "quantite": 2,  "gold_amount": 0  },
	{ "contenu": "or",            "quantite": 0,  "gold_amount": 30 },
	{ "contenu": "Epee en bois",  "quantite": 1,  "gold_amount": 0  },
	{ "contenu": "or",            "quantite": 0,  "gold_amount": 50 },
	{ "contenu": "Grande potion", "quantite": 1,  "gold_amount": 0  },
	{ "contenu": "Minerai de fer","quantite": 3,  "gold_amount": 0  },
	# ── Exemples supplémentaires ──────────────────────────────
	# { "contenu": "Cle de donjon", "quantite": 1,  "gold_amount": 0  },
	# { "contenu": "Cristal",       "quantite": 2,  "gold_amount": 0  },
]

# ── ✏️  PARAMÈTRES GÉNÉRAUX ──────────────────────────────────
## Distance minimale entre deux coffres (pixels)
const MIN_DIST: float = 96.0
## Distance minimale entre un coffre et le bord de la carte (tiles)
## (évite les coffres coincés dans un coin inaccessible)
const BORDER_MARGIN: int = 3
## Graine fixe — garantit les mêmes emplacements à chaque lancement
## Changer pour générer une nouvelle disposition
const PLACEMENT_SEED: int = 7331

# ── Terrain valide : herbe uniquement (pas sur les chemins) ──
const VALID_SOURCE_IDS: Array = [2, 3]

# ────────────────────────────────────────────────────────────
var _grass_positions: Array = []
var _terrain_layer:   TileMapLayer = null

# ============================================================
func _ready() -> void:
	await get_tree().process_frame
	_terrain_layer = _find_terrain_layer()
	if not _terrain_layer:
		push_error("ChestSpawner : TileMapLayer 'Terrains' introuvable !")
		return
	_scan_tiles()
	_place_chests()

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
	var used      = _terrain_layer.get_used_cells()

	# Calculer les bornes de la carte pour le margin
	var min_cell = Vector2i(INF, INF)
	var max_cell = Vector2i(-INF, -INF)
	for cell in used:
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
		max_cell.x = max(max_cell.x, cell.x)
		max_cell.y = max(max_cell.y, cell.y)

	for cell in used:
		# Exclure les bords
		if cell.x < min_cell.x + BORDER_MARGIN or cell.x > max_cell.x - BORDER_MARGIN:
			continue
		if cell.y < min_cell.y + BORDER_MARGIN or cell.y > max_cell.y - BORDER_MARGIN:
			continue
		var src      = _terrain_layer.get_cell_source_id(cell)
		var local_px = _terrain_layer.map_to_local(cell)
		if src in VALID_SOURCE_IDS:
			_grass_positions.append(local_px * tm_scale + tm_offset)

	# Mélange déterministe
	var rng = RandomNumberGenerator.new()
	rng.seed = PLACEMENT_SEED
	for i in range(_grass_positions.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = _grass_positions[i]
		_grass_positions[i] = _grass_positions[j]
		_grass_positions[j] = tmp

# ============================================================
#  PLACEMENT DES COFFRES
# ============================================================

func _place_chests() -> void:
	if _grass_positions.is_empty():
		return

	var chest_scene = load("res://scenes/chest.tscn")
	if not chest_scene:
		push_error("ChestSpawner : scène 'res://scenes/chest.tscn' introuvable !")
		return

	var placed_positions: Array = []
	var chest_index: int = 0

	for def in CHEST_DEFS:
		var pos = _pick_free_position(placed_positions)
		if pos == Vector2.INF:
			push_warning("ChestSpawner : impossible de placer le coffre #" + str(chest_index))
			chest_index += 1
			continue

		var node = chest_scene.instantiate()
		# Nom déterministe pour que GameManager retrouve l'état ouvert/fermé
		node.name = "SpawnedChest_" + str(chest_index)
		node.position = pos
		node.set("contenu",      def["contenu"])
		node.set("quantite",     def["quantite"])
		node.set("gold_amount",  def["gold_amount"])
		add_child(node)

		placed_positions.append(pos)
		chest_index += 1

func _pick_free_position(already_placed: Array) -> Vector2:
	for candidate in _grass_positions:
		var ok = true
		for p in already_placed:
			if candidate.distance_to(p) < MIN_DIST:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF
