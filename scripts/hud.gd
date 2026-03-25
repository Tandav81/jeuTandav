extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var panneau = $PanneauInventaire
@onready var panneau_perso = $PanneauPersonnage
@onready var grid = $PanneauInventaire/VBoxContainer/GridContainer
@onready var label_or = $PanneauInventaire/VBoxContainer/LabelOr
@onready var label_outil = $PanneauInventaire/VBoxContainer/LabelOutil
@onready var label_niveau = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/LabelNiveau
@onready var barre_xp = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/BarreXP
@onready var label_points = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/LabelPoints
@onready var grid_stats = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/GridStats
@onready var grid_equip = $PanneauPersonnage/HBoxContainer/PanneauEquipement/VBoxContainer/GridEquipement
@onready var quest_list = $QuestPanel/QuestList
@onready var dialogue_box = $DialogueBox
@onready var dialogue_text = $DialogueBox/DialogueText

var item_images = {
	"Bois": "res://assets/sprites/wood/wood.png",
	"Minerai": "res://assets/sprites/rock/rock.png",
}
var item_regions = {
	"Viande": Rect2(16, 64, 16, 16),
	"Potion": Rect2(0, 0, 16, 16),
}
var item_spritesheets = {
	"Viande": "res://assets/rpgItems.png",
	"Potion": "res://assets/rpgItems.png",
}

var inventaire_ouvert = false
var perso_ouvert = false

func _ready():
	add_to_group("hud")
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Stats.stats_changed.connect(_on_stats_changed)
	Stats.level_up.connect(_on_level_up)
	panneau.visible = false
	panneau_perso.visible = false
	$BtnInventaire.focus_mode = Control.FOCUS_NONE
	$BtnPersonnage.focus_mode = Control.FOCUS_NONE
	QuestManager.quest_updated.connect(update_quests_display)
	update_quests_display()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if panneau.visible:
			panneau.visible = false
			inventaire_ouvert = false
		if panneau_perso.visible:
			panneau_perso.visible = false
			perso_ouvert = false
			
	if dialogue_box.visible and Input.is_action_just_pressed("ui_accept"):
		hide_dialogue()
# ===== SANTÉ =====

func _on_health_changed(new_health):
	health_bar.value = new_health

# ===== INVENTAIRE =====

func _on_inventory_changed():
	if panneau.visible:
		_refresh_inventaire()
	if panneau_perso.visible:
		_refresh_equipement()

func _on_btn_inventaire_pressed():
	panneau.visible = !panneau.visible
	inventaire_ouvert = panneau.visible
	if panneau.visible:
		_refresh_inventaire()
	$BtnInventaire.release_focus()

func _on_btn_fermer_pressed():
	panneau.visible = false
	inventaire_ouvert = false

func _refresh_inventaire():
	label_or.text = "Or : " + str(Inventory.gold)
	label_outil.text = "Outil : " + (Inventory.equipped_tool if Inventory.equipped_tool != "" else "Aucun")
	for child in grid.get_children():
		child.queue_free()
	for item_name in Inventory.items:
		var qty = Inventory.items[item_name]
		var container = PanelContainer.new()
		container.custom_minimum_size = Vector2(64, 64)
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#a07850")
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color("#5c3a1e")
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		container.add_theme_stylebox_override("panel", style)
		var vbox = VBoxContainer.new()
		container.add_child(vbox)
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(40, 40)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var texture = get_item_texture(item_name)
		if texture != null:
			texture_rect.texture = texture
		else:
			var label_nom = Label.new()
			label_nom.text = item_name
			label_nom.add_theme_color_override("font_color", Color("#3d1f00"))
			vbox.add_child(label_nom)
		vbox.add_child(texture_rect)
		var label = Label.new()
		label.text = "x" + str(qty)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#3d1f00"))
		label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(label)
		var btn = Button.new()
		btn.flat = true
		btn.size = container.size
		container.add_child(btn)
		btn.pressed.connect(_on_item_pressed.bind(item_name))
		grid.add_child(container)

func _on_item_pressed(item_name: String):
	var player = get_tree().get_first_node_in_group("player")
	match item_name:
		"Potion":
			if Inventory.remove_item(item_name, 1):
				player.heal(30)
				_refresh_inventaire()
		"Viande":
			if Inventory.remove_item(item_name, 1):
				player.heal(15)
				_refresh_inventaire()
		"Hache":
			Inventory.equip_tool("hache")
			_refresh_inventaire()
		"Pioche":
			Inventory.equip_tool("pioche")
			_refresh_inventaire()
		_:
			if Stats.equipment_data.has(item_name):
				var slot = Stats.equipment_data[item_name]["slot"]
				Inventory.equip_item(slot, item_name)
				Stats.emit_signal("stats_changed")
				_refresh_inventaire()
				if panneau_perso.visible:
					_refresh_equipement()

# ===== PERSONNAGE =====

func _on_stats_changed():
	if panneau_perso.visible:
		_refresh_stats()

func _on_level_up(new_level):
	print("🎉 Niveau ", new_level, " !")

func _on_btn_personnage_pressed():
	panneau_perso.visible = !panneau_perso.visible
	perso_ouvert = panneau_perso.visible
	if panneau_perso.visible:
		_refresh_stats()
		_refresh_equipement()
	$BtnPersonnage.release_focus()

func _refresh_stats():
	# Niveau
	label_niveau.text = "⚔️ Niveau " + str(Stats.level)
	label_niveau.add_theme_font_size_override("font_size", 20)
	label_niveau.add_theme_color_override("font_color", Color("#FFD700"))

	# Barre XP
	barre_xp.max_value = Stats.xp_next_level
	barre_xp.value = Stats.xp
	barre_xp.custom_minimum_size = Vector2(0, 16)
	var style_xp_fond = StyleBoxFlat.new()
	style_xp_fond.bg_color = Color("#2a2a2a")
	style_xp_fond.corner_radius_top_left = 4
	style_xp_fond.corner_radius_top_right = 4
	style_xp_fond.corner_radius_bottom_left = 4
	style_xp_fond.corner_radius_bottom_right = 4
	var style_xp_rempli = StyleBoxFlat.new()
	style_xp_rempli.bg_color = Color("#2a6aff")
	style_xp_rempli.corner_radius_top_left = 4
	style_xp_rempli.corner_radius_top_right = 4
	style_xp_rempli.corner_radius_bottom_left = 4
	style_xp_rempli.corner_radius_bottom_right = 4
	barre_xp.add_theme_stylebox_override("background", style_xp_fond)
	barre_xp.add_theme_stylebox_override("fill", style_xp_rempli)

	# Points disponibles
	if Stats.stat_points > 0:
		label_points.text = "✨ " + str(Stats.stat_points) + " points à distribuer !"
		label_points.add_theme_color_override("font_color", Color("#FFD700"))
		label_points.add_theme_font_size_override("font_size", 15)
	else:
		label_points.text = "Aucun point disponible"
		label_points.add_theme_color_override("font_color", Color("#888888"))
		label_points.add_theme_font_size_override("font_size", 14)

	# Vide la grille
	for child in grid_stats.get_children():
		child.queue_free()

	# Stats avec couleurs
	var liste_stats = [
		["⚔️ Force", Stats.get_force(), "force", Color("#ff8866")],
		["❤️ Endurance", Stats.get_endurance(), "endurance", Color("#ff66aa")],
		["💨 Agilité", Stats.get_agilite(), "agilite", Color("#66ffaa")],
		["✨ Magie", Stats.get_magie(), "magie", Color("#88aaff")],
		["🛡️ Défense", Stats.get_defense(), "defense", Color("#ffcc44")],
	]

	for stat in liste_stats:
		var lbl_nom = Label.new()
		grid_stats.add_child(lbl_nom)
		lbl_nom.text = stat[0]
		lbl_nom.set("theme_override_colors/font_color", stat[3])
		lbl_nom.add_theme_font_size_override("font_size", 18)
		lbl_nom.custom_minimum_size = Vector2(130, 25)

		var lbl_val = Label.new()
		grid_stats.add_child(lbl_val)
		lbl_val.text = str(stat[1])
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_val.add_theme_color_override("font_color", Color("#ffffff"))
		lbl_val.add_theme_font_size_override("font_size", 16)
		lbl_val.custom_minimum_size = Vector2(40, 0)

		var btn_plus = Button.new()
		grid_stats.add_child(btn_plus)
		btn_plus.text = "+"
		btn_plus.custom_minimum_size = Vector2(28, 28)
		btn_plus.focus_mode = Control.FOCUS_NONE
		if Stats.stat_points > 0:
			btn_plus.disabled = false
			var style_actif = StyleBoxFlat.new()
			style_actif.bg_color = Color("#4a8c2a")
			style_actif.border_width_left = 2
			style_actif.border_width_right = 2
			style_actif.border_width_top = 2
			style_actif.border_width_bottom = 2
			style_actif.border_color = Color("#FFD700")
			style_actif.corner_radius_top_left = 4
			style_actif.corner_radius_top_right = 4
			style_actif.corner_radius_bottom_left = 4
			style_actif.corner_radius_bottom_right = 4
			btn_plus.add_theme_stylebox_override("normal", style_actif)
			btn_plus.add_theme_color_override("font_color", Color("#FFD700"))
			btn_plus.add_theme_font_size_override("font_size", 16)
		else:
			btn_plus.disabled = true
			var style_inactif = StyleBoxFlat.new()
			style_inactif.bg_color = Color("#444444")
			style_inactif.corner_radius_top_left = 4
			style_inactif.corner_radius_top_right = 4
			style_inactif.corner_radius_bottom_left = 4
			style_inactif.corner_radius_bottom_right = 4
			btn_plus.add_theme_stylebox_override("normal", style_inactif)
			btn_plus.add_theme_color_override("font_color", Color("#666666"))
		btn_plus.pressed.connect(_on_stat_plus.bind(stat[2]))

func _on_stat_plus(stat_name: String):
	if Stats.spend_point(stat_name):
		_refresh_stats()
		if stat_name == "endurance":
			var player = get_tree().get_first_node_in_group("player")
			player.max_health = Stats.get_max_health()

func _refresh_equipement():
	for child in grid_equip.get_children():
		child.queue_free()
	var slots = [
		["arme", "⚔️ Arme"],
		["casque", "🪖 Casque"],
		["plastron", "🛡️ Plastron"],
		["bottes", "👢 Bottes"],
		["anneau", "💍 Anneau"],
		["amulette", "📿 Amulette"],
	]
	for slot_info in slots:
		var slot = slot_info[0]
		var slot_nom = slot_info[1]
		var item_equipe = Inventory.equipped[slot]
		var lbl_slot = Label.new()
		lbl_slot.text = slot_nom
		lbl_slot.add_theme_color_override("font_color", Color("#ddccaa"))
		lbl_slot.add_theme_font_size_override("font_size", 14)
		lbl_slot.custom_minimum_size = Vector2(90, 0)
		grid_equip.add_child(lbl_slot)
		var btn = Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		if item_equipe != null:
			btn.text = item_equipe
			btn.add_theme_color_override("font_color", Color("#44ff44"))
			btn.pressed.connect(_on_desequiper.bind(slot))
		else:
			btn.text = "[ vide ]"
			btn.add_theme_color_override("font_color", Color("#888888"))
		btn.custom_minimum_size = Vector2(140, 32)
		btn.add_theme_font_size_override("font_size", 13)
		grid_equip.add_child(btn)

func _on_desequiper(slot: String):
	Inventory.unequip_item(slot)
	Stats.emit_signal("stats_changed")
	_refresh_equipement()
	_refresh_stats()

# ===== UTILITAIRES =====

func get_item_texture(item_name: String) -> Texture2D:
	if item_images.has(item_name):
		var path = item_images[item_name]
		if ResourceLoader.exists(path):
			return load(path)
		else:
			print("Image non trouvée : ", path)
			return null
	if item_regions.has(item_name):
		var path = item_spritesheets[item_name]
		if ResourceLoader.exists(path):
			var atlas = AtlasTexture.new()
			atlas.atlas = load(path)
			atlas.region = item_regions[item_name]
			return atlas
		else:
			print("Spritesheet non trouvé : ", path)
			return null
	return null

func update_quests_display():
	# Nettoyer
	for child in quest_list.get_children():
		child.queue_free()

	# Ajouter chaque quête
	for quest in QuestManager.active_quests:
		var label = Label.new()
		label.text = "%s : %d / %d" % [
			quest.name,
			quest.progress,
			quest.required
		]
		if quest.completed:
			label.text += " (Terminé !)"
		quest_list.add_child(label)

func show_dialogue(text):
	dialogue_box.visible = true
	dialogue_text.text = text
	
func hide_dialogue():
	dialogue_box.visible = false
