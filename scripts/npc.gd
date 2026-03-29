extends CharacterBody2D

@export var quest_id = "slime_hunter"
@onready var anim = $AnimatedSprite2D
@onready var quest_icon = $QuestIcon

var player_in_range = false
var can_interact = true

func _ready():
	anim.play("idle")
	# Connexion manuelle uniquement — supprimer les connexions dans l'éditeur
	$InteractionZone.body_entered.connect(_on_body_entered)
	$InteractionZone.body_exited.connect(_on_body_exited)
	QuestManager.quest_updated.connect(update_quest_icon)
	update_quest_icon()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		interact()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func interact() -> void:
	if not can_interact:
		return

	can_interact = false
	
	var quest = get_quest()
	var hud = get_tree().get_first_node_in_group("hud")
	if quest == null:
		QuestManager.start_quest(quest_id)
		hud.show_dialogue("Peux tu compléter ma quête ?")
	elif quest.completed and not quest.reward_claimed:
		QuestManager.claim_reward(quest_id)
		hud.show_dialogue("Merci ! Voici ta récompense.")
	elif not quest.completed:
		hud.show_dialogue("Tu n'as pas encore fini la quête...")
	else:
		hud.show_dialogue("Merci encore pour ton aide !")
		
	await get_tree().create_timer(0.5).timeout
	can_interact = true

func get_quest():
	for quest in QuestManager.active_quests:
		if quest.id == quest_id:
			return quest
	for quest in QuestManager.completed_quests:
		if quest.id == quest_id:
			return quest
	return null

func update_quest_icon():
	var quest = get_quest()
	if quest == null:
		# Quête disponible
		quest_icon.visible = true
		quest_icon.modulate = Color.YELLOW   # ❗

	elif quest.completed and not quest.reward_claimed:
		# Récompense dispo
		quest_icon.visible = true
		quest_icon.modulate = Color.GREEN    # ✅

	elif not quest.completed:
		# En cours
		quest_icon.visible = true
		quest_icon.modulate = Color.WHITE    # ❓

	else:
		# Tout fini
		quest_icon.visible = false
