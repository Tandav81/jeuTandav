extends Control

func _ready():
	# Désactive Continuer si pas de sauvegarde
	$Panel/VBoxContainer/BtnContinuer.disabled = not GameManager.save_exists()
	$Panel/VBoxContainer/BtnContinuer.focus_mode = Control.FOCUS_NONE
	$Panel/VBoxContainer/BtnNouvellePartie.focus_mode = Control.FOCUS_NONE
	$Panel/VBoxContainer/BtnQuitter.focus_mode = Control.FOCUS_NONE

func _on_btn_nouvelle_partie_pressed():
	GameManager.spawn_position = Vector2.ZERO
	GameManager.player_health = 100
	GameManager.coffres_ouverts = []
	Inventory.items = {}
	Inventory.gold = 0
	Inventory.equipped_tool = ""
	QuestManager.active_quests = []
	QuestManager.completed_quests = []
	Inventory.equipped = {
		"arme": null,
		"casque": null,
		"plastron": null,
		"bottes": null,
		"anneau": null,
		"amulette": null}
	Stats.level = 1
	Stats.xp = 0
	Stats.xp_next_level = 100
	Stats.stat_points = 0
	Stats.base_force = 5
	Stats.base_endurance = 5
	Stats.base_agilite = 5
	Stats.base_magie = 5
	Stats.base_defense = 5
	Stats.current_mana = float(Stats.get_max_mana())
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_btn_continuer_pressed():
	GameManager.load_game()
	get_tree().change_scene_to_file(GameManager.current_scene)

func _on_btn_quitter_pressed():
	get_tree().quit()
