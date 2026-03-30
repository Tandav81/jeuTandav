extends CanvasLayer

# Autoload "SceneTransition" — gère le fondu noir entre les scènes.
# Persiste à travers tous les changements de scène grâce au process_mode ALWAYS.

var _rect: ColorRect

func _ready():
	layer = 100  # au-dessus de tout, y compris le HUD
	process_mode = Node.PROCESS_MODE_ALWAYS

	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)

# Appelé par un portal. Fondu → changement de scène → fondu retour.
func fade_out_to(target_scene: String, spawn_pos: Vector2):
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	# 1. Fondu au noir (0.5 s)
	tween.tween_property(_rect, "modulate:a", 1.0, 0.5)
	# 2. Changement de scène
	tween.tween_callback(_do_scene_change.bind(target_scene, spawn_pos))
	# 3. Courte pause pour laisser la scène se charger (0.15 s)
	tween.tween_interval(0.15)
	# 4. Fondu retour (0.6 s)
	tween.tween_property(_rect, "modulate:a", 0.0, 0.6)

func _do_scene_change(target_scene: String, spawn_pos: Vector2):
	GameManager.spawn_position = spawn_pos
	GameManager.current_scene = target_scene
	get_tree().change_scene_to_file(target_scene)
