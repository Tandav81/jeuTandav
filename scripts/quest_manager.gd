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
	"slime_hunter": {
		"id": "slime_hunter",
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
	"wood_collector": {
		"id": "wood_collector",
		"name": "Bûcheron débutant",
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
	if QUESTS.has(quest_id):
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
