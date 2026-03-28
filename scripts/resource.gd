extends Node2D

@export var resource_type = "bois"    # "bois", "minerai", "plante", "animal"
@export var resource_name = "Bois"    # nom affiché
@export var quantity = 1              # quantité donnée
@export var respawn_time = 10.0       # secondes avant repousse (0 = pas de repousse)
@export var required_tool = ""        # "" = aucun outil requis, "hache", "pioche"...
@export var health = 3                # coups nécessaires pour récolter

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var interaction_zone = $InteractionZone

var player_nearby = false
var is_depleted = false
var current_health = 0

signal resource_collected(type, name, qty)

func _ready():
	current_health = health
	interaction_zone.body_entered.connect(_on_player_enter)
	interaction_zone.body_exited.connect(_on_player_exit)

func _process(_delta):
	if player_nearby and not is_depleted:
		if Input.is_action_just_pressed("interact"):
			print("E appuyé sur : ", resource_name)
			_interact()

func _on_player_enter(body):
	if body.is_in_group("player"):
		player_nearby = true
		print("Joueur détecté près de : ", resource_name)

func _on_player_exit(body):
	if body.is_in_group("player"):
		player_nearby = false

func _interact():
	 # Vérifie l'outil requis
	if required_tool != "" and Inventory.equipped_tool != required_tool:
		print("Il vous faut une ", required_tool, " !")
		return
		
	current_health -= 1

	# Petite animation de "hit"
	var original_pos = global_position
	var tween = create_tween()
	tween.tween_property(self, "global_position", global_position + Vector2(2, 0), 0.05)
	tween.tween_property(self, "global_position", original_pos, 0.05)

	if current_health <= 0:
		_harvest()

func _harvest():
	is_depleted = true
	collision.set_deferred("disabled", true)

	# Émet le signal pour donner l'item à l'inventaire
	emit_signal("resource_collected", resource_type, resource_name, quantity)
	Inventory.add_item(resource_name, quantity)
	print("Ressource obtenue : ", resource_name, " x", quantity)
	QuestManager.update_collect(resource_name)
	if respawn_time > 0:
		# Cache la ressource et la fait repousser
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
		await get_tree().create_timer(respawn_time).timeout
		_respawn()
	else:
		# Disparaît définitivement
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()

func _respawn():
	current_health = health
	is_depleted = false
	collision.set_deferred("disabled", false)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
