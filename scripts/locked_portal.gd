extends Area2D

# Portail verrouillé — nécessite un item précis dans l'inventaire pour passer.
# Structure dans l'éditeur (identique à portal.tscn) :
#   Area2D (script: locked_portal.gd)
#     CollisionShape2D
#     Label (nom: Label)
#     AnimatedSprite2D ou Sprite2D (optionnel — pour l'effet visuel ouvert/fermé)

@export var target_scene: String = ""
@export var target_spawn: Vector2 = Vector2.ZERO
@export var portal_label: String = "Entrée verrouillée"
## Nom exact de l'item-clé requis (ex: "Clé du donjon"). Laisser vide = toujours ouvert.
@export var required_key: String = ""

var _used: bool = false
var _is_open: bool = false

@onready var _label: Label = $Label

func _ready():
	body_entered.connect(_on_body_entered)
	_label.text = portal_label
	_label.visible = portal_label != ""
	# S'ajouter au groupe pour être trouvé par DungeonCinematic sans NodePath
	add_to_group("locked_portal")
	# Vérifier l'état initial (cas où le joueur a déjà la clé, ex: chargement d'une sauvegarde)
	await get_tree().process_frame
	_check_open_state()

func _check_open_state() -> void:
	if required_key == "" or Inventory.has_item(required_key):
		_set_open(true)
	else:
		_set_open(false)

## Appelé par DungeonCinematic quand la cinématique se termine
func open_portal() -> void:
	_set_open(true)

func _set_open(open: bool) -> void:
	_is_open = open
	if open:
		modulate = Color(1.0, 1.0, 1.0, 1.0)   # normal
		_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		modulate = Color(0.45, 0.45, 0.75, 1.0) # teinte bleue = verrouillé
		_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	if not _is_open:
		var hud = get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_notification"):
			hud.show_notification("🔒  Il vous faut : " + required_key, Color.CORNFLOWER_BLUE)
		return
	if target_scene == "":
		push_warning("LockedPortal : target_scene non défini !")
		return
	_used = true
	var fog = get_tree().get_first_node_in_group("fog")
	if fog:
		GameManager.fog_data[GameManager.current_scene] = fog.get_save_data()
	GameManager.current_scene = target_scene
	SceneTransition.fade_out_to(target_scene, target_spawn)
