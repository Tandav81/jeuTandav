extends "res://scripts/npc.gd"

func _ready() -> void:
	npc_name = "Vieux Bûcheron"
	quest_id = "bucherondeb"   # ← ton quest_id existant dans quest_manager.gd

	dialogue_data["default"] = [
		"Bonjour, étranger.",
	]

	dialogue_data["quest_available"] = [
		"Mon dos me fait trop souffrir pour couper du bois...",
		"Si tu pouvais m'en ramener 10 morceaux, je te récompenserais bien.",
		{
			"text": "Ça te dit d'aider un vieux ?",
			"choices": [
				{"label": "Bien sûr, je m'en occupe !", "goto": "accept"},
				{"label": "Pas maintenant.",             "goto": "refuse"},
			]
		}
	]

	dialogue_data["accept"] = [
		{"action": "start_quest"},
        "Merci ! La forêt est au nord. Bonne chance !"
	]

	dialogue_data["refuse"] = [
		"Je comprends... Un vieux comme moi ne peut pas exiger grand chose.",
        "Reviens si tu changes d'avis."
	]

	dialogue_data["quest_active"] = [
		"Tu as le bois ?",
        "Il m'en faut 10 morceaux, n'oublie pas !"
	]

	dialogue_data["quest_completable"] = [
		"Tu es revenu ! Et avec du bois en plus, parfait !",
		{"action": "give_reward"},   # ← déclenche QuestManager.claim_reward()
		"Voilà ta récompense : quelques potions et un peu d'or.",
        "Tu m'as sauvé la mise, merci !"
	]

	dialogue_data["quest_done"] = [
		"Grâce à toi j'ai de quoi chauffer la maison cet hiver.",
        "Tu es un brave, vraiment."
	]

	super._ready()
	
