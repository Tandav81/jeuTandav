extends StaticBody2D

@export var contenu = "Potion"
@export var quantite = 1
@export var gold_amount = 0
## Si true : le coffre disparaît après ouverture et réapparaît ailleurs (géré par ResourceSpawner).
## Si false : comportement permanent (état sauvegardé dans GameManager).
@export var is_respawnable: bool = false

@onready var anim = $AnimatedSprite2D
@onready var interaction_zone = $InteractionZone

## Émis dès que le coffre a été ouvert (utilisé par ResourceSpawner pour déclencher le respawn).
signal chest_opened

var ouvert = false
var player_nearby = false

func _ready():
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

	if is_respawnable:
		# Coffre respawnable : toujours frais au démarrage
		anim.play("ferme")
	else:
		# Coffre permanent : vérifie si déjà ouvert lors d'une session précédente
		if GameManager.coffres_ouverts.has(name):
			ouvert = true
			anim.play("ouvert")
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
	interaction_zone.monitoring = false

	# Joue l'animation d'ouverture
	anim.play("ouverture")
	await anim.animation_finished

	# Donne le contenu au joueur
	match contenu:
		"or":
			Inventory.add_gold(gold_amount)
			print("Tu as trouvé ", gold_amount, " pièces d'or !")
		_:
			Inventory.add_item(contenu, quantite)
			print("Tu as trouvé ", quantite, " x ", contenu)

	if is_respawnable:
		# Signale au ResourceSpawner qu'un coffre s'est ouvert
		chest_opened.emit()
		# Reste brièvement visible en état "ouvert" puis disparaît
		anim.play("ouvert")
		await get_tree().create_timer(2.0).timeout
		queue_free()
	else:
		# Coffre permanent : enregistre dans GameManager et reste visible
		GameManager.coffres_ouverts.append(name)
		anim.play("ouvert")
