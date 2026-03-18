extends StaticBody2D

@export var contenu = "potion"
@export var quantite = 1
@export var gold_amount = 0

@onready var anim = $AnimatedSprite2D
@onready var interaction_zone = $InteractionZone

var ouvert = false
var player_nearby = false

func _ready():
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)
	# Vérifie si ce coffre a déjà été ouvert
	if GameManager.coffres_ouverts.has(name):
		ouvert = true
		anim.play("ouvert")  # ta frame d'état ouvert permanent
		interaction_zone.monitoring = false
	else:
		anim.play("ferme")

func _process(_delta):
	if player_nearby and not ouvert:
		if Input.is_action_just_pressed("interact"):
			_ouvrir()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _ouvrir():
	ouvert = true
	# Enregistre dans GameManager
	GameManager.coffres_ouverts.append(name)
	# Joue l'animation d'ouverture
	anim.play("ouverture")
	await anim.animation_finished
	
	# Donne le contenu au joueur
	match contenu:
		"potion":
			Inventory.add_item("Potion", quantite)
			print("Tu as trouvé une potion !")
		"or":
			Inventory.add_gold(gold_amount)
			print("Tu as trouvé ", gold_amount, " pièces d'or !")
		_:
			Inventory.add_item(contenu, quantite)
			print("Tu as trouvé ", quantite, " ", contenu)
	
	interaction_zone.monitoring = false
