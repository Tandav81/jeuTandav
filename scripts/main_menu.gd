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
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_btn_continuer_pressed():
	if GameManager.load_game():
		get_tree().change_scene_to_file(GameManager.current_scene)

func _on_btn_quitter_pressed():
	get_tree().quit()
