extends "res://scripts/npc.gd"

func _ready() -> void:
	npc_name = "Villageois"
	quest_id = "villageois_slime"   # ← ton quest_id existant dans quest_manager.gd

	dialogue_data["default"] = [
		"Bonjour, étranger.",
	]

	dialogue_data["quest_available"] = [
		"Les slimes envahissent notre village!",
		"Si tu pouvais en tuer 5, je te récompenserais bien.",
		{
			"text": "Ça te dit d'aider le village ?",
			"choices": [
				{"label": "Bien sûr, je m'en occupe !", "goto": "accept"},
				{"label": "Pas maintenant.",             "goto": "refuse"},
			]
		}
	]

	dialogue_data["accept"] = [
		{"action": "start_quest"},
        "Merci ! Les slimes sont plus à l'est. Bonne chance !"
	]

	dialogue_data["refuse"] = [
		"Je comprends... Un vieux comme moi ne peut pas exiger grand chose.",
        "Reviens si tu changes d'avis."
	]

	dialogue_data["quest_active"] = [
		"Tu les as tué ?",
        "Il faut tuer 5 slimes, n'oublie pas !"
	]

	dialogue_data["quest_completable"] = [
		"Tu es revenu ! Et tu as tués les 5 slimes, parfait !",
		{"action": "give_reward"},   # ← déclenche QuestManager.claim_reward()
		"Voilà ta récompense : quelques potions et un peu d'or.",
        "Tu m'as sauvé la mise, merci !"
	]

	dialogue_data["quest_done"] = [
		"Grâce à toi le village sera plus tranquille.",
        "Tu es un brave, vraiment."
	]

	super._ready()
	
