extends Node2D

@export var map_width = 80      # largeur en tuiles
@export var map_height = 80     # hauteur en tuiles
@export var zone_size = 10      # taille d'une zone en tuiles
@export var seed_value = 0      # graine de génération

@onready var tilemap = $TileMap

# Biomes possibles
enum Biome { EAU, SABLE, FORET, ROCHE }

const TUILES = {
	# Tuiles de base
	"herbe": {"source": 0, "atlas": Vector2i(0, 0)},
	"eau": {"source": 1, "atlas": Vector2i(0, 0)},
	"sable": {"source": 2, "atlas": Vector2i(0, 0)},
	"roche": {"source": 3, "atlas": Vector2i(0, 0)},
	
	# Transitions eau->sable
	"eau_sable_haut": {"source": 2, "atlas": Vector2i(1, 0)},
	"eau_sable_bas": {"source": 2, "atlas": Vector2i(1, 2)},
	"eau_sable_gauche": {"source": 2, "atlas": Vector2i(0, 1)},
	"eau_sable_droite": {"source": 2, "atlas": Vector2i(2, 1)},
	
	# Transitions herbe->sable
	"herbe_sable_haut": {"source": 2, "atlas": Vector2i(1, 3)},
	"herbe_sable_bas": {"source": 2, "atlas": Vector2i(1, 5)},
	# etc...
}

var biome_grid = []
# Grille de tuiles finale
var tile_grid = []

func _ready():
	if seed_value == 0:
		seed_value = randi()
	seed(seed_value)
	generate()

func generate():
	_generate_biomes()
	_apply_tiles()
	_place_villages()
	print("Map générée avec seed : ", seed_value)
	
func _generate_biomes():
	var zones_x = map_width / zone_size
	var zones_y = map_height / zone_size
	
	# Crée la grille de zones
	var zone_grid = []
	for x in range(zones_x):
		zone_grid.append([])
		for y in range(zones_y):
			# Distribution des biomes
			var roll = randi() % 100
			var biome
			if roll < 20:
				biome = Biome.EAU
			elif roll < 35:
				biome = Biome.SABLE
			elif roll < 75:
				biome = Biome.FORET
			else:
				biome = Biome.ROCHE
			zone_grid[x].append(biome)
	
	# Convertit les zones en tuiles individuelles
	biome_grid = []
	for x in range(map_width):
		biome_grid.append([])
		for y in range(map_height):
			var zone_x = x / zone_size
			var zone_y = y / zone_size
			biome_grid[x].append(zone_grid[zone_x][zone_y])
			
#func _apply_tiles():
	#for x in range(map_width):
		#for y in range(map_height):
			#var biome = biome_grid[x][y]
			#var coords = Vector2i(x, y)
			#
			## Vérifie les voisins pour les transitions
			#var voisin_haut = _get_biome(x, y - 1)
			#var voisin_bas = _get_biome(x, y + 1)
			#var voisin_gauche = _get_biome(x - 1, y)
			#var voisin_droite = _get_biome(x + 1, y)
			#
			#var tuile = _choisir_tuile(biome, voisin_haut, voisin_bas, voisin_gauche, voisin_droite)
			#tilemap.set_cell(coords, tuile.source, tuile.atlas)
			
func _apply_tiles():
	var herbe_cells = []
	var eau_cells = []
	var sable_cells = []
	var roche_cells = []
	
	for x in range(map_width):
		for y in range(map_height):
			var coords = Vector2i(x, y)
			match biome_grid[x][y]:
				Biome.FORET:
					herbe_cells.append(coords)
				Biome.EAU:
					eau_cells.append(coords)
				Biome.SABLE:
					sable_cells.append(coords)
				Biome.ROCHE:
					roche_cells.append(coords)
	
	# Godot place les bonnes tuiles de transition automatiquement !
	tilemap.set_cells_terrain_connect(herbe_cells, 0, 0)
	tilemap.set_cells_terrain_connect(eau_cells, 0, 1)
	tilemap.set_cells_terrain_connect(sable_cells, 0, 2)
	tilemap.set_cells_terrain_connect(roche_cells, 0, 3)
	
func _get_biome(x, y) -> int:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return Biome.EAU  # bord de map = eau
	return biome_grid[x][y]
	
func _choisir_tuile(biome, haut, bas, gauche, droite) -> Dictionary:
	# Tuile de base selon le biome
	match biome:
		Biome.EAU:
			return TUILES["eau"]
		Biome.SABLE:
			# Transition sable->eau
			if haut == Biome.EAU:
				return TUILES["eau_sable_haut"]
			if bas == Biome.EAU:
				return TUILES["eau_sable_bas"]
			if gauche == Biome.EAU:
				return TUILES["eau_sable_gauche"]
			if droite == Biome.EAU:
				return TUILES["eau_sable_droite"]
			return TUILES["sable"]
		Biome.FORET:
			# Transition forêt->sable
			if haut == Biome.SABLE:
				return TUILES["herbe_sable_haut"]
			if bas == Biome.SABLE:
				return TUILES["herbe_sable_bas"]
			return TUILES["herbe"]
		Biome.ROCHE:
			return TUILES["roche"]
	return TUILES["herbe"]
	
func _place_villages():
	var zones_x = map_width / zone_size
	var zones_y = map_height / zone_size
	
	for zx in range(zones_x):
		for zy in range(zones_y):
			var biome = biome_grid[zx * zone_size][zy * zone_size]
			
			# Place un village sur les zones forêt (30% de chance)
			if biome == Biome.FORET and randi() % 100 < 30:
				_generate_village(zx * zone_size, zy * zone_size)

func _generate_village(start_x, start_y):
	var nb_maisons = randi_range(3, 8)
	var positions_utilisees = []
	
	for i in range(nb_maisons):
		# Position aléatoire dans la zone
		var tentatives = 0
		while tentatives < 20:
			var mx = start_x + randi() % (zone_size - 2) + 1
			var my = start_y + randi() % (zone_size - 2) + 1
			var pos = Vector2i(mx, my)
			
			# Vérifie qu'il n'y a pas déjà une maison trop proche
			var trop_proche = false
			for p in positions_utilisees:
				if pos.distance_to(p) < 3:
					trop_proche = true
					break
			
			if not trop_proche:
				positions_utilisees.append(pos)
				#_placer_maison(mx, my)
				break
			tentatives += 1

#func _placer_maison(x, y):
	## Instancie une maison à cette position
	## Adapte le chemin selon ta scène de maison
	#var maison_scene = preload("res://scenes/house.tscn")
	#var maison = maison_scene.instantiate()
	#maison.position = Vector2(x * 16, y * 16)  # 16 = taille tuile
	#add_child(maison)
