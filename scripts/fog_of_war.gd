# fog_of_war.gd
extends Node2D

@export var map_width_tiles: int = 120       # largeur de ta map en tuiles
@export var map_height_tiles: int = 120      # hauteur de ta map en tuiles
@export var map_origin: Vector2 = Vector2(-960, -960)  # coin haut-gauche en pixels monde
@export var tile_size: int = 16
@export var reveal_radius: int = 7          # rayon de révélation en tuiles
@export var fog_alpha: float = 0.92         # opacité du brouillard (0.0 = invisible, 1.0 = noir total)

var fog_image: Image
var fog_texture: ImageTexture
var _sprite: Sprite2D

# Cellules révélées : Vector2i -> alpha residuel (0.0 = totalement révélé)
var revealed_cells: Dictionary = {}

func _ready():
	_build_fog_sprite()
	
	var scene_key = GameManager.current_scene
	if GameManager.fog_data.has(scene_key) and GameManager.fog_data[scene_key].size() > 0:
		load_save_data(GameManager.fog_data[scene_key])

func _build_fog_sprite():
	fog_image = Image.create(map_width_tiles, map_height_tiles, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color(0, 0, 0, fog_alpha))
	fog_texture = ImageTexture.create_from_image(fog_image)

	_sprite = Sprite2D.new()
	_sprite.texture = fog_texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # pixels nets, style pixel-art
	_sprite.scale = Vector2(tile_size, tile_size)
	# Le Sprite2D est centré → décaler de la moitié de la map
	_sprite.position = map_origin + Vector2(map_width_tiles, map_height_tiles) * tile_size * 0.5
	_sprite.z_index = 10  # au-dessus du monde, sous le HUD (CanvasLayer)
	add_child(_sprite)

# Appelé depuis player.gd à intervalle régulier
func reveal_around(world_pos: Vector2) -> void:
	var local = world_pos - map_origin
	var cx = int(local.x / tile_size)
	var cy = int(local.y / tile_size)
	var changed = false
	var fade_start = reveal_radius - 2.5  # début du fondu sur les bords

	for dx in range(-reveal_radius, reveal_radius + 1):
		for dy in range(-reveal_radius, reveal_radius + 1):
			var dist = Vector2(dx, dy).length()
			if dist > reveal_radius:
				continue

			var px = cx + dx
			var py = cy + dy
			if px < 0 or px >= map_width_tiles or py < 0 or py >= map_height_tiles:
				continue

			# Alpha résiduel : 0 au centre, fog_alpha au bord extérieur
			var target_alpha: float
			if dist <= fade_start:
				target_alpha = 0.0
			else:
				target_alpha = lerp(0.0, fog_alpha, (dist - fade_start) / 2.5)

			var cell = Vector2i(px, py)
			var current_alpha = revealed_cells.get(cell, fog_alpha)
			# On n'écrit que si on améliore (révèle plus)
			if target_alpha < current_alpha:
				revealed_cells[cell] = target_alpha
				fog_image.set_pixel(px, py, Color(0, 0, 0, target_alpha))
				changed = true

	if changed:
		fog_texture.update(fog_image)

# --- Sauvegarde / Chargement ---

func get_save_data() -> Array:
	var data := []
	for cell in revealed_cells:
		data.append([cell.x, cell.y, revealed_cells[cell]])
	return data

func load_save_data(data: Array) -> void:
	fog_image.fill(Color(0, 0, 0, fog_alpha))
	revealed_cells.clear()
	for entry in data:
		var cell = Vector2i(int(entry[0]), int(entry[1]))
		var alpha = float(entry[2])
		revealed_cells[cell] = alpha
		fog_image.set_pixel(cell.x, cell.y, Color(0, 0, 0, alpha))
	fog_texture.update(fog_image)
	
