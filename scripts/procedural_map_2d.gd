extends Node2D

@export var width: int = 100
@export var height: int = 100
@export var noise_scale: float = 0.05
@export var seed: int = 12389

var noise := FastNoiseLite.new()
var tilemap : TileMapLayer

const WATER = 0
const BEACH = 1
const GRASS = 2
const CLIFF = 3
const FARM = 4
const PATH = 5

func _ready():
	print("generation du monde")
	tilemap = $TileMap

	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = noise_scale

	generate_map()


func generate_map():

	for x in range(width):
		for y in range(height):

			var n = noise.get_noise_2d(x, y)

			var tile = GRASS

			if n < -0.35:
				tile = WATER

			elif n < -0.25:
				tile = BEACH

			elif n < 0.4:
				tile = GRASS

			elif n < 0.65:
				tile = FARM

			else:
				tile = CLIFF

			tilemap.set_cell(Vector2i(x,y), tile, Vector2i(0,0))
