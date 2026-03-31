extends Area2D

# Place ce nœud (portal.tscn) à l'entrée/sortie d'une zone.
# Configure les exports dans l'inspecteur Godot :
#   - target_scene : chemin vers la scène de destination (ex: "res://scenes/cave.tscn")
#   - target_spawn : coordonnées où le joueur apparaît dans la scène de destination

@export var target_scene: String = ""
@export var target_spawn: Vector2 = Vector2.ZERO
@export var portal_label: String = ""  # texte affiché au-dessus (ex: "Entrée de la grotte")

var _used: bool = false

@onready var _label: Label = $Label

func _ready():
	body_entered.connect(_on_body_entered)
	_label.text = portal_label
	_label.visible = portal_label != ""

func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return
	if target_scene == "":
		push_warning("Portal : target_scene non défini !")
		return
	_used = true
	
	var fog = get_tree().get_first_node_in_group("fog")
	if fog:
		GameManager.fog_data[GameManager.current_scene] = fog.get_save_data()
		
	GameManager.current_scene = target_scene
	SceneTransition.fade_out_to(target_scene, target_spawn)
