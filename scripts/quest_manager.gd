extends Node

# ======================
# DONNÉES
# ======================

var active_quests = []
var completed_quests = []

signal quest_updated
signal quest_completed(quest_id)

# ======================
# BASE DE QUÊTES
# ======================

var QUESTS = {
	"villageois_slime": {
		"id": "villageois_slime",
		"name": "Chasseur de slimes",
		"description": "Tuer 5 slimes",
		"type": "kill",
		"target": "slime",
		"required": 5,
		"progress": 0,
		"reward_xp": 50,
		"reward_gold": 20,
		"reward_items": {
			"Potion": 2
		},
		"completed": false,
		"reward_claimed": false
	},
	"bucherondeb": {
		"id": "bucherondeb",
		"name": "Vieux bûcheron",
		"description": "Récolter 10 bois",
		"type": "collect",
		"target": "Bois",
		"required": 10,
		"progress": 0,
		"reward_xp": 40,
		"reward_gold": 50,
		 "reward_items": {
			"Potion": 2
		},
		"completed": false,
		"reward_claimed": false
	}
}

# ======================
# GESTION DES QUÊTES
# ======================

func start_quest(quest_id):
	if not QUESTS.has(quest_id):
		return
	# Ne pas relancer si déjà active
	for q in active_quests:
		if q.id == quest_id:
			return
	# Ne pas relancer si déjà complétée/réclamée
	for q in completed_quests:
		if q.id == quest_id:
			return
	var quest = QUESTS[quest_id].duplicate(true)
	active_quests.append(quest)
	emit_signal("quest_updated")

func complete_quest(quest):
	quest.completed = true
	emit_signal("quest_updated")

func give_reward(quest):
	if quest.reward_xp > 0:
		Stats.add_xp(quest.reward_xp)

	if quest.reward_gold > 0:
		Inventory.add_gold(quest.reward_gold)

	if quest.has("reward_items"):
		for item in quest.reward_items:
			Inventory.add_item(item, quest.reward_items[item])

# ======================
# PROGRESSION
# ======================

func update_kill(enemy_type):
	for quest in active_quests:
		if quest.type == "kill" and quest.target == enemy_type:
			quest.progress += 1

			if quest.progress >= quest.required:
				complete_quest(quest)

	emit_signal("quest_updated")

func update_collect(item_name):
	for quest in active_quests:
		if quest.type == "collect" and quest.target == item_name:
			quest.progress += 1

			if quest.progress >= quest.required:
				complete_quest(quest)

	emit_signal("quest_updated")

func claim_reward(quest_id):
	for quest in active_quests:
		if quest.id == quest_id and quest.completed and not quest.reward_claimed:
			give_reward(quest)
			quest.reward_claimed = true
			completed_quests.append(quest)
			active_quests.erase(quest)

			emit_signal("quest_completed", quest_id)
			emit_signal("quest_updated")

func get_quest_state(quest_id: String) -> String:
	# Vérifier si la quête est en cours
	for quest in active_quests:
		if quest.id == quest_id:
			if quest.completed:
				return "completable"   # terminée, récompense à récupérer
			else:
				return "active"        # en cours
	# Vérifier si la récompense a déjà été réclamée
	for quest in completed_quests:
		if quest.id == quest_id:
			return "done"
	# Sinon, la quête est disponible (pas encore démarrée)
	return "available"
