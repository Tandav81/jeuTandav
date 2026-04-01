extends CharacterBody2D

@export var npc_name: String = "PNJ"
@export var quest_id: String = ""
@onready var anim = $AnimatedSprite2D
@onready var quest_icon = $QuestIcon
@onready var interaction_zone: Area2D = $InteractionZone

var dialogue_data: Dictionary = {

	"default": [
		"Bonjour, aventurier !",
		"Belle journée pour explorer, non ?",
	],
	"quest_available": [
		"Ah, tu tombes bien !",
		"J'aurais une mission pour quelqu'un de courageux...",
		{
			"text": "Acceptes-tu de relever ce défi ?",
			"choices": [
				{"label": "Oui, je suis partant !",   "goto": "accept"},
				{"label": "Peut-être plus tard...",    "goto": "refuse"},
			]
		},
	],
	"accept": [
		{"action": "start_quest"},
		"Excellent ! J'ai confiance en toi. Bonne chance !",
	],
	"refuse": [
		"Je comprends... Reviens me voir si tu changes d'avis.",
	],
	"quest_active": [
		"Tu n'as pas encore terminé ta mission.",
		"Je compte sur toi, courage !",
	],
	"quest_completable": [
		"Tu as réussi ! Je suis vraiment impressionné.",
		"Laisse-moi te remettre ta récompense...",
		{"action": "give_reward"},
		"Prends ça, tu l'as bien mérité. Merci !",
	],
	"quest_done": [
		"Merci encore pour tout ce que tu as fait !",
		"Le village te doit beaucoup.",
	],
}

var player_in_range = false
var can_interact = true
var _player_in_range:  bool  = false
var _dialogue_active:  bool  = false
var _waiting_for_choice: bool = false
var _current_sequence: Array = []
var _current_index:    int   = 0

func _ready():
	anim.play("idle")
	# Connexion manuelle uniquement — supprimer les connexions dans l'éditeur
	$InteractionZone.body_entered.connect(_on_body_entered)
	$InteractionZone.body_exited.connect(_on_body_exited)

	if quest_id != "":
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
		if _dialogue_active:
			force_end_dialogue()

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
	if quest_icon == null:
		return
	if quest_id == "":
		quest_icon.visible = false
		return

	var state: String = QuestManager.get_quest_state(quest_id)
	match state:
		"available":
			quest_icon.visible  = true
			quest_icon.modulate = Color.YELLOW
		"active":
			quest_icon.visible  = true
			quest_icon.modulate = Color.WHITE
		"completable":
			quest_icon.visible  = true
			quest_icon.modulate = Color.GREEN
		_:
			quest_icon.visible  = false
			
func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("interact") and not _dialogue_active:
		_begin_dialogue()
		# Marque l'événement comme traité pour que le HUD ne l'attrape pas
		# sur le même frame (il vient de mettre _active_npc à jour via
		# start_npc_dialogue, et pourrait appeler advance() par erreur).
		get_viewport().set_input_as_handled()
		
func _begin_dialogue() -> void:
	_dialogue_active    = true
	_waiting_for_choice = false
	_load_sequence(_resolve_start_key())

	var hud = _get_hud()
	if hud:
		hud.start_npc_dialogue(self, npc_name)

	_emit_current()
	
func _resolve_start_key() -> String:
	if quest_id == "":
		return "default"
	var state: String = QuestManager.get_quest_state(quest_id)
	match state:
		"available":   return "quest_available"
		"active":      return "quest_active"
		"completable": return "quest_completable"
		"done":        return "quest_done"
		_:             return "default"

func _load_sequence(key: String) -> void:
	_current_sequence = dialogue_data.get(key, ["..."])
	_current_index    = 0

func _emit_current() -> bool:
	# Exécuter automatiquement les actions silencieuses
	while _current_index < _current_sequence.size():
		var node = _current_sequence[_current_index]
		if node is Dictionary and node.has("action") and not node.has("text"):
			_execute_action(node["action"])
			_current_index += 1
		else:
			break

	# Fin de séquence
	if _current_index >= _current_sequence.size():
		_end_dialogue()
		return false

	var node = _current_sequence[_current_index]
	var hud  = _get_hud()
	if hud == null:
		return false

	if node is String:
		hud.show_dialogue_line(node)

	elif node is Dictionary:
		var text: String = node.get("text", "")
		if node.has("choices"):
			_waiting_for_choice = true
			hud.show_dialogue_line_with_choices(text, node["choices"])
		else:
			hud.show_dialogue_line(text)

	return true

func _execute_action(action: String) -> void:
	match action:
		"start_quest":
			if quest_id != "":
				QuestManager.start_quest(quest_id)
		"give_reward":
			if quest_id != "":
				QuestManager.claim_reward(quest_id)
		# ← Ajouter d'autres actions ici si besoin

func _end_dialogue() -> void:
	_dialogue_active    = false
	_waiting_for_choice = false
	update_quest_icon()
	var hud = _get_hud()
	if hud:
		hud.end_npc_dialogue()
		
## Avance d'un cran dans la séquence (touche E).
## Ignoré si on attend un choix.
func advance() -> void:
	if not _dialogue_active or _waiting_for_choice:
		return
	_current_index += 1
	_emit_current()

## Appelée quand le joueur clique sur un bouton de choix.
## index = position du choix dans le tableau "choices".
func select_choice(index: int) -> void:
	if not _waiting_for_choice:
		return

	var node = _current_sequence[_current_index]
	if not (node is Dictionary and node.has("choices")):
		return

	var choices: Array = node["choices"]
	if index < 0 or index >= choices.size():
		return

	_waiting_for_choice = false
	var goto_key: String = choices[index].get("goto", "")

	if goto_key == "" or not dialogue_data.has(goto_key):
		_end_dialogue()
		return

	_load_sequence(goto_key)
	_emit_current()

## Ferme le dialogue de force (ex : joueur qui s'éloigne).
func force_end_dialogue() -> void:
	_dialogue_active    = false
	_waiting_for_choice = false
	var hud = _get_hud()
	if hud:
		hud.end_npc_dialogue()
	update_quest_icon()

func _get_hud() -> Node:
	return get_tree().get_first_node_in_group("hud")
