extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var panneau = $PanneauInventaire
@onready var panneau_perso = $PanneauPersonnage
@onready var grid = $PanneauInventaire/VBoxContainer/GridContainer
@onready var label_or = $PanneauInventaire/VBoxContainer/LabelOr
@onready var label_niveau = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/LabelNiveau
@onready var barre_xp = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/BarreXP
@onready var label_points = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/LabelPoints
@onready var grid_stats = $PanneauPersonnage/HBoxContainer/PanneauStats/VBoxContainer/GridStats
@onready var grid_equip = $PanneauPersonnage/HBoxContainer/PanneauEquipement/VBoxContainer/GridEquipement
@onready var dialogue_box:       Panel        = $DialogueBox
@onready var choices_container:  VBoxContainer = $DialogueBox/VBoxContainer/ChoicesContainer
@onready var label_nom_pnj:      Label        = $DialogueBox/VBoxContainer/LabelNomPNJ
@onready var label_dialogue:     Label        = $DialogueBox/VBoxContainer/LabelDialogue
@onready var label_continuer:    Label        = $DialogueBox/VBoxContainer/LabelContinuer
@onready var quest_journal = $QuestJournal
@onready var quest_liste = $QuestJournal/QuestList

var journal_open = false

# Les icônes d'items sont gérées centralement par l'autoload ItemData.

var inventaire_ouvert = false
var perso_ouvert = false
var crafting_panel_node = null   # instancié dans _ready()
var mana_bar: TextureProgressBar = null
var xp_bar: TextureProgressBar = null
var _help_panel: Control = null   # panneau d'aide (F1)

# ── Système de notifications ────────────────────────────────────────────────
var _notif_panel: PanelContainer = null
var _notif_label: Label = null
var _notif_tween: Tween = null

# ── Outil équipé (affiché sous les barres) ──────────────────────────────────
var _tool_slot: PanelContainer = null
var _tool_icon: TextureRect   = null

var _active_npc: Node = null

const TOOL_ICONS = {
	"hache":  {"sheet": "res://assets/rpgItems.png", "region": Rect2(64, 80, 16, 16)},
	"pioche": {"sheet": "res://assets/rpgItems.png", "region": Rect2(80, 48, 16, 16)},
}

func _ready():
	add_to_group("hud")
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	Stats.stats_changed.connect(_on_stats_changed)
	Stats.level_up.connect(_on_level_up)
	panneau.visible = false
	panneau_perso.visible = false
	quest_journal.visible = false
	dialogue_box.visible = false
	$BtnInventaire.focus_mode = Control.FOCUS_NONE
	$BtnPersonnage.focus_mode = Control.FOCUS_NONE
	$BtnQuetes.focus_mode = Control.FOCUS_NONE
	QuestManager.quest_updated.connect(update_quest_journal)

	# ── Panneau Crafting (construit par code) ──────────────────
	crafting_panel_node = load("res://scripts/crafting_panel.gd").new()
	add_child(crafting_panel_node)

	# ── Barre de mana (construite après le layout) ──────────────
	call_deferred("_build_mana_bar")
	# ── Outil équipé (affiché sous les barres) ───────────────────
	call_deferred("_build_tool_display")
	# ── Panneau d'aide (F1) ──────────────────────────────────────
	_build_help_panel()
	# ── Bouton ❓ et raccourcis claviers sur boutons HUD ─────────
	call_deferred("_build_hud_shortcuts")

func _input(event: InputEvent) -> void:
	# Touche B (Bricoler) : ouvre/ferme le panneau de crafting
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			if crafting_panel_node:
				crafting_panel_node.toggle()
		# Touche I : inventaire
		elif event.keycode == KEY_I:
			_on_btn_inventaire_pressed()
			get_viewport().set_input_as_handled()
		# Touche P : fiche personnage
		elif event.keycode == KEY_P:
			_on_btn_personnage_pressed()
			get_viewport().set_input_as_handled()
		# Touche F1 : ouvre/ferme le panneau d'aide
		elif event.keycode == KEY_F1:
			if _help_panel:
				_help_panel.visible = not _help_panel.visible
				get_viewport().set_input_as_handled()
	
	# ── Avancer dans le dialogue avec E (si dialogue actif) ──────────
	if event.is_action_pressed("interact") and _active_npc != null:
		_active_npc.advance()
		get_viewport().set_input_as_handled()
		return

	# ── Fermer la DialogueBox avec Échap ──────────────────────────────
	if event.is_action_pressed("ui_cancel"):
		if _active_npc != null:
			_active_npc.force_end_dialogue()
			get_viewport().set_input_as_handled()
			return

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if _help_panel and _help_panel.visible:
			_help_panel.visible = false
			return
		if panneau.visible:
			panneau.visible = false
			inventaire_ouvert = false
		if panneau_perso.visible:
			panneau_perso.visible = false
			perso_ouvert = false
		if crafting_panel_node and crafting_panel_node.panel_visible:
			crafting_panel_node.hide_panel()
			
	if dialogue_box.visible and Input.is_action_just_pressed("ui_accept"):
		hide_dialogue()
	
	if Input.is_action_just_pressed("personnage"): # ou une nouvelle touche
		toggle_journal()

func _build_tool_display():
	# Petit slot pixel-art positionné juste sous les barres de vie/mana/xp
	_tool_slot = PanelContainer.new()
	var style = StyleBoxTexture.new()
	style.texture = load("res://assets/menus/Inventory.png")
	style.region_rect = Rect2(272, 16, 16, 16)
	style.texture_margin_left   = 2
	style.texture_margin_right  = 2
	style.texture_margin_top    = 2
	style.texture_margin_bottom = 2
	_tool_slot.add_theme_stylebox_override("panel", style)
	_tool_slot.set_anchor(SIDE_LEFT,   0.0)
	_tool_slot.set_anchor(SIDE_RIGHT,  0.0)
	_tool_slot.set_anchor(SIDE_TOP,    0.0)
	_tool_slot.set_anchor(SIDE_BOTTOM, 0.0)
	# Positionné sous les barres (barres : top=10, hauteur 72px*scale=2 → ~82px + marge)
	_tool_slot.offset_left   = 10
	_tool_slot.offset_top    = 88
	_tool_slot.offset_right  = 58   # 48px de large
	_tool_slot.offset_bottom = 136  # 48px de haut

	_tool_icon = TextureRect.new()
	_tool_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	_tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tool_icon.custom_minimum_size = Vector2(32, 32)
	_tool_slot.add_child(_tool_icon)

	add_child(_tool_slot)
	# Placer juste après xp_bar pour rester sous les panneaux
	if xp_bar:
		move_child(_tool_slot, xp_bar.get_index() + 1)

	_refresh_tool_display()

func _refresh_tool_display():
	if _tool_slot == null:
		return
	var tool = Inventory.equipped_tool
	if tool == "" or not TOOL_ICONS.has(tool):
		_tool_slot.visible = false
		return
	_tool_slot.visible = true
	var info = TOOL_ICONS[tool]
	var atlas = AtlasTexture.new()
	atlas.atlas = load(info["sheet"])
	atlas.region = info["region"]
	_tool_icon.texture = atlas

func _build_notification_panel():
	_notif_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	style.corner_radius_top_left    = 8
	style.corner_radius_top_right   = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 18
	style.content_margin_right  = 18
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	_notif_panel.add_theme_stylebox_override("panel", style)
	_notif_panel.modulate.a = 0.0

	_notif_label = Label.new()
	_notif_label.add_theme_font_size_override("font_size", 17)
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_panel.add_child(_notif_label)
	add_child(_notif_panel)

	# Centré horizontalement, position initiale hors écran en haut
	_notif_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_notif_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_notif_panel.set_anchor(SIDE_LEFT,   0.5)
	_notif_panel.set_anchor(SIDE_RIGHT,  0.5)
	_notif_panel.set_anchor(SIDE_TOP,    0.0)
	_notif_panel.set_anchor(SIDE_BOTTOM, 0.0)
	_notif_panel.offset_left   = -180
	_notif_panel.offset_right  =  180
	_notif_panel.offset_top    = -60
	_notif_panel.offset_bottom =  0

func show_notification(text: String, color: Color = Color.WHITE):
	if _notif_panel == null:
		_build_notification_panel()
	# Annule le tween en cours si une notif est déjà affichée
	if _notif_tween and _notif_tween.is_valid():
		_notif_tween.kill()

	_notif_label.text = text
	_notif_label.add_theme_color_override("font_color", color)
	_notif_panel.modulate.a = 0.0
	# Position de départ : légèrement au-dessus de la cible
	_notif_panel.offset_top    = -70
	_notif_panel.offset_bottom = -10

	_notif_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Glisse vers le bas + fade in
	_notif_tween.parallel().tween_property(_notif_panel, "offset_top",    20.0, 0.25)
	_notif_tween.parallel().tween_property(_notif_panel, "offset_bottom", 60.0, 0.25)
	_notif_tween.parallel().tween_property(_notif_panel, "modulate:a",     1.0, 0.2)
	# Pause
	_notif_tween.tween_interval(2.2)
	# Fade out
	_notif_tween.tween_property(_notif_panel, "modulate:a", 0.0, 0.4)

func _on_health_changed(new_health):
	health_bar.value = new_health

# Construit une ImageTexture (85×36) qui ne contient que les rangées
# tex_row_start..tex_row_end de la zone progress de character_panel.png.
# Coordonnée texture : tex_y = image_y + 2  (le Rect2 démarre à y=-2).
#   Rouge  : image y=7..12  → tex_y=9..14
#   Bleu   : image y=13..17 → tex_y=15..19
#   Vert   : image y=18..22 → tex_y=20..24
func _make_bar_texture(tex_row_start: int, tex_row_end: int) -> ImageTexture:
	var src_img: Image = load("res://assets/menus/character_panel.png").get_image()
	var bar_img = Image.create(85, 36, false, Image.FORMAT_RGBA8)
	bar_img.fill(Color.TRANSPARENT)
	for tex_y in range(tex_row_start, tex_row_end + 1):
		var img_y: int = tex_y - 2  # texture → image coordinate
		if img_y < 0 or img_y >= src_img.get_height():
			continue
		for x in range(85):
			bar_img.set_pixel(x, tex_y, src_img.get_pixel(97 + x, img_y))
	return ImageTexture.create_from_image(bar_img)

func _build_mana_bar():
	# Barre de vie : n'afficher que la rangée ROUGE
	health_bar.texture_progress = _make_bar_texture(9, 14)

	# Barre de mana : rangée BLEUE, même position/taille que health_bar
	mana_bar = TextureProgressBar.new()
	mana_bar.offset_left   = health_bar.offset_left
	mana_bar.offset_top    = health_bar.offset_top
	mana_bar.offset_right  = health_bar.offset_right
	mana_bar.offset_bottom = health_bar.offset_bottom
	mana_bar.scale         = health_bar.scale
	mana_bar.min_value     = 0.0
	mana_bar.max_value     = float(Stats.get_max_mana())
	mana_bar.value         = Stats.current_mana
	mana_bar.texture_under    = null  # fond déjà dessiné par health_bar
	mana_bar.texture_progress = _make_bar_texture(15, 19)
	Stats.mana_changed.connect(_on_mana_changed)
	add_child(mana_bar)
	# Placer la barre de mana juste après health_bar dans l'arbre
	# pour qu'elle s'affiche SOUS les panneaux (inventaire, quêtes, etc.)
	move_child(mana_bar, health_bar.get_index() + 1)

	# Barre d'XP : rangée VERTE, même position/taille
	xp_bar = TextureProgressBar.new()
	xp_bar.offset_left   = health_bar.offset_left
	xp_bar.offset_top    = health_bar.offset_top
	xp_bar.offset_right  = health_bar.offset_right
	xp_bar.offset_bottom = health_bar.offset_bottom
	xp_bar.scale         = health_bar.scale
	xp_bar.min_value     = 0.0
	xp_bar.max_value     = float(Stats.xp_next_level)
	xp_bar.value         = float(Stats.xp)
	xp_bar.texture_under    = null
	xp_bar.texture_progress = _make_bar_texture(20, 24)
	add_child(xp_bar)
	move_child(xp_bar, mana_bar.get_index() + 1)

func _on_mana_changed(current: float, max_val: float):
	if mana_bar:
		mana_bar.max_value = max_val
		mana_bar.value = current

# ===== INVENTAIRE =====

func _on_inventory_changed():
	if panneau.visible:
		_refresh_inventaire()
	if panneau_perso.visible:
		_refresh_equipement()
	_refresh_tool_display()

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
	for child in grid.get_children():
		child.queue_free()
	for item_name in Inventory.items:
		var qty = Inventory.items[item_name]
		var container = PanelContainer.new()
		container.custom_minimum_size = Vector2(64, 64)
		var style = StyleBoxTexture.new()
		style.texture = load("res://assets/menus/Inventory.png")
		style.region_rect = Rect2(272, 16, 16, 16)  # un slot individuel de la grille
		style.texture_margin_left = 2
		style.texture_margin_right = 2
		style.texture_margin_top = 2
		style.texture_margin_bottom = 2
		container.add_theme_stylebox_override("panel", style)
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		container.add_child(vbox)
		var texture = get_item_texture(item_name)
		if texture != null:
			var texture_rect = TextureRect.new()
			texture_rect.custom_minimum_size = Vector2(40, 40)
			texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture_rect.texture = texture
			vbox.add_child(texture_rect)
		else:
			# Aucune icône connue → afficher le nom en texte
			var label_nom = Label.new()
			label_nom.text = item_name
			label_nom.add_theme_color_override("font_color", Color("#3d1f00"))
			label_nom.add_theme_font_size_override("font_size", 10)
			label_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label_nom.custom_minimum_size = Vector2(56, 0)
			label_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(label_nom)
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
		"Grande potion":
			if Inventory.remove_item(item_name, 1):
				player.heal(60)
				_refresh_inventaire()
		"Potion de mana":
			if Inventory.remove_item(item_name, 1):
				Stats.restore_mana(40)
				_refresh_inventaire()
		"Potion de force":
			if Inventory.remove_item(item_name, 1):
				player.heal(20)
				Stats.restore_mana(20)
				_refresh_inventaire()
		"Viande":
			if Inventory.remove_item(item_name, 1):
				player.heal(15)
				_refresh_inventaire()
		"Livre du forgeron":
			if Inventory.remove_item(item_name, 1):
				GameManager.use_book("Livre du forgeron")
				show_notification("📖 Livre du forgeron lu !\nNouvelles recettes débloquées.", Color("#88ccff"))
				_refresh_inventaire()
		"Livre du mage":
			if Inventory.remove_item(item_name, 1):
				GameManager.use_book("Livre du mage")
				show_notification("📖 Livre du mage lu !\nNouvelles recettes débloquées.", Color("#bb88ff"))
				_refresh_inventaire()
		"Hache":
			Inventory.equip_tool("hache")
			show_notification("🪓  Hache équipée", Color("#aaffaa"))
			_refresh_inventaire()
		"Pioche":
			Inventory.equip_tool("pioche")
			show_notification("⛏️  Pioche équipée", Color("#aaffaa"))
			_refresh_inventaire()
		_:
			if Stats.equipment_data.has(item_name):
				var slot = Stats.equipment_data[item_name]["slot"]
				Inventory.equip_item(slot, item_name)
				Stats.emit_signal("stats_changed")
				show_notification("✅  " + item_name + " équipé(e)", Color("#aaffaa"))
				_refresh_inventaire()
				if panneau_perso.visible:
					_refresh_equipement()

# ===== PERSONNAGE =====

func _on_stats_changed():
	if panneau_perso.visible:
		_refresh_stats()
	# La magie affecte le mana max : mettre à jour la barre
	if mana_bar:
		mana_bar.max_value = float(Stats.get_max_mana())
	# XP : mise à jour de la barre verte
	if xp_bar:
		xp_bar.max_value = float(Stats.xp_next_level)
		xp_bar.value     = float(Stats.xp)

func _on_level_up(new_level):
	show_notification("🎉 Niveau " + str(new_level) + " !\n+3 points à distribuer", Color("#FFD700"))

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
		["arme",     "⚔️ Arme"],
		["casque",   "🪖 Casque"],
		["plastron", "🛡️ Plastron"],
		["bouclier", "🛡 Bouclier"],
		["bottes",   "👢 Bottes"],
		["anneau",   "💍 Anneau"],
		["amulette", "📿 Amulette"],
	]
	for slot_info in slots:
		var slot = slot_info[0]
		var slot_nom = slot_info[1]
		var item_equipe = Inventory.equipped.get(slot, null)
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
	return ItemData.get_texture(item_name)

func show_dialogue(text):
	dialogue_box.visible = true
	label_dialogue.text = text
	
func hide_dialogue():
	dialogue_box.visible = false

func toggle_journal():
	journal_open = !journal_open
	quest_journal.visible = journal_open

	if journal_open:
		update_quest_journal()

func update_quest_journal():
	for child in quest_liste.get_children():
		child.queue_free()

	for quest in QuestManager.active_quests:
		var label = Label.new()

		var text = quest.name + "\n"
		text += quest.description + "\n"
		text += "Progression : %d / %d" % [quest.progress, quest.required]

		if quest.completed:
			text += "\n✅ Terminé - Retourner voir le PNJ"

		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_color_override("font_color", Color("#3d1f00"))

		quest_liste.add_child(label)

func _on_btn_quetes_pressed() -> void:
	toggle_journal()
	$BtnQuetes.release_focus()

## Appelé par npc.gd pour ouvrir la boîte de dialogue.
func start_npc_dialogue(npc: Node, npc_name: String) -> void:
	_active_npc              = npc
	label_nom_pnj.text       = npc_name
	label_dialogue.text      = ""
	label_continuer.visible  = true
	_clear_choices()
	dialogue_box.visible     = true

## Affiche une ligne simple (le joueur appuie sur E pour continuer).
func show_dialogue_line(text: String) -> void:
	label_dialogue.text     = text
	label_continuer.visible = true
	_clear_choices()

## Affiche une ligne puis des boutons de choix.
## choices = [{"label": "...", "goto": "..."}, ...]
func show_dialogue_line_with_choices(text: String, choices: Array) -> void:
	label_dialogue.text     = text
	label_continuer.visible = false   # on attend un clic, pas E
	_clear_choices()

	for i in choices.size():
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text              = choice.get("label", "...")
		btn.focus_mode        = Control.FOCUS_NONE   # évite les conflits avec Espace
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Style facultatif — adapte ou supprime selon ton thème
		var sb := StyleBoxFlat.new()
		sb.bg_color          = Color(0.15, 0.10, 0.05, 0.85)
		sb.border_color      = Color(0.7, 0.55, 0.2)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left   = 8.0
		sb.content_margin_right  = 8.0
		sb.content_margin_top    = 4.0
		sb.content_margin_bottom = 4.0
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))

		var idx := i   # capture de la variable pour la lambda
		btn.pressed.connect(func() -> void: _on_dialogue_choice_pressed(idx))
		choices_container.add_child(btn)

## Ferme la boîte de dialogue.
func end_npc_dialogue() -> void:
	dialogue_box.visible = false
	_clear_choices()
	_active_npc = null

## Supprime tous les boutons de choix existants.
func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()

## Transmet le choix sélectionné au NPC.
func _on_dialogue_choice_pressed(index: int) -> void:
	if _active_npc != null:
		_active_npc.select_choice(index)

# ============================================================
#  PANNEAU D'AIDE (F1)
# ============================================================

func _build_help_panel() -> void:
	# Fond semi-transparent plein écran
	var bg = ColorRect.new()
	bg.name = "HelpPanel"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.visible = false
	add_child(bg)
	_help_panel = bg

	# Panneau centré
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(480, 0)
	bg.add_child(panel)

	# Forcer le centrage après layout
	panel.set_deferred("position", Vector2(40, 20))

	# Style du panneau
	var style = StyleBoxFlat.new()
	style.bg_color          = Color(0.12, 0.10, 0.18, 0.97)
	style.border_color      = Color(0.6, 0.5, 0.8, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Titre
	var title = Label.new()
	title.text = "⚔  GUIDE DES TOUCHES  ⚔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.6, 0.5, 0.8, 0.6))
	vbox.add_child(sep)

	# Sections de touches
	const SECTIONS = [
		["Déplacement", [
			["↑ ↓ ← →",       "Se déplacer"],
		]],
		["Combat & Actions", [
			["Espace",         "Attaquer"],
			["E",              "Interagir / Ramasser"],
			["T",              "Changer d'outil équipé"],
		]],
		["Interface", [
			["I",              "Inventaire"],
			["P",              "Fiche personnage"],
			["C",              "Journal de quêtes"],
			["B",              "Atelier de craft"],
			["S",              "Sauvegarder"],
			["F1 / ❓",        "Guide d'aide"],
			["Échap",          "Fermer les panneaux"],
		]],
		["Conseils", [
			["⛏",              "Équipe une pioche pour miner"],
			["🪓",             "Équipe une hache pour couper le bois"],
			["💊",             "Utilise les potions depuis l'inventaire"],
			["🌙",             "La nuit est dangereuse, reste prudent !"],
		]],
	]

	for section in SECTIONS:
		var section_label = Label.new()
		section_label.text = section[0]
		section_label.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
		section_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(section_label)

		for entry in section[1]:
			var row = HBoxContainer.new()
			vbox.add_child(row)

			var key_label = Label.new()
			key_label.text = entry[0]
			key_label.custom_minimum_size = Vector2(110, 0)
			key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			key_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
			key_label.add_theme_font_size_override("font_size", 13)
			row.add_child(key_label)

			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(12, 0)
			row.add_child(spacer)

			var desc_label = Label.new()
			desc_label.text = entry[1]
			desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			desc_label.add_theme_font_size_override("font_size", 13)
			row.add_child(desc_label)

		var gap = Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		vbox.add_child(gap)

	# Pied de page
	var footer = Label.new()
	footer.text = "F1 ou Échap pour fermer"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	footer.add_theme_font_size_override("font_size", 11)
	vbox.add_child(footer)

#============================================================
#  BOUTON AIDE + LABELS RACCOURCIS SUR LES BOUTONS HUD
# ============================================================

func _build_hud_shortcuts() -> void:
	# ── Raccourcis sur les 3 boutons existants ──────────────────
	var shortcut_map = {
		"BtnInventaire": "I",
		"BtnPersonnage":  "P",
		"BtnQuetes":      "C",
	}
	for btn_name in shortcut_map:
		var btn = get_node_or_null(btn_name)
		if not btn:
			continue
		var lbl = Label.new()
		lbl.text = shortcut_map[btn_name]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(1, 1, 0.6, 0.9))
		# Positionner en bas-droite du bouton
		lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		lbl.set_anchor(SIDE_LEFT,   1.0)
		lbl.set_anchor(SIDE_RIGHT,  1.0)
		lbl.set_anchor(SIDE_TOP,    1.0)
		lbl.set_anchor(SIDE_BOTTOM, 1.0)
		lbl.offset_left   = -14
		lbl.offset_top    = -14
		lbl.offset_right  = -2
		lbl.offset_bottom = -2
		lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)

	# ── Bouton ❓ (aide F1) à gauche de BtnQuetes ───────────────
	var btn_quetes = get_node_or_null("BtnQuetes")
	if not btn_quetes:
		return

	var btn_help = Button.new()
	btn_help.name = "BtnAide"
	btn_help.text = "❓"
	btn_help.focus_mode = Control.FOCUS_NONE
	btn_help.tooltip_text = "Aide (F1)"
	btn_help.add_theme_font_size_override("font_size", 18)

	# Même style que BtnQuetes
	var style = StyleBoxFlat.new()
	style.bg_color          = Color(0.18, 0.14, 0.08, 0.88)
	style.border_color      = Color(0.7, 0.6, 0.3, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn_help.add_theme_stylebox_override("normal", style)

	# Position : à gauche de BtnQuetes (décalé de 70px)
	btn_help.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_help.set_anchor(SIDE_LEFT,   btn_quetes.anchor_left)
	btn_help.set_anchor(SIDE_RIGHT,  btn_quetes.anchor_right)
	btn_help.set_anchor(SIDE_TOP,    btn_quetes.anchor_top)
	btn_help.set_anchor(SIDE_BOTTOM, btn_quetes.anchor_bottom)
	btn_help.offset_left   = btn_quetes.offset_left - 70
	btn_help.offset_right  = btn_quetes.offset_right - 70
	btn_help.offset_top    = btn_quetes.offset_top
	btn_help.offset_bottom = btn_quetes.offset_bottom
	add_child(btn_help)
	btn_help.pressed.connect(func():
		if _help_panel:
			_help_panel.visible = not _help_panel.visible
	)

	# Label "F1" en bas-droite du bouton aide
	var lbl_f1 = Label.new()
	lbl_f1.text = "F1"
	lbl_f1.add_theme_font_size_override("font_size", 9)
	lbl_f1.add_theme_color_override("font_color", Color(1, 1, 0.6, 0.9))
	lbl_f1.set_anchor(SIDE_LEFT,   1.0)
	lbl_f1.set_anchor(SIDE_RIGHT,  1.0)
	lbl_f1.set_anchor(SIDE_TOP,    1.0)
	lbl_f1.set_anchor(SIDE_BOTTOM, 1.0)
	lbl_f1.offset_left   = -16
	lbl_f1.offset_top    = -14
	lbl_f1.offset_right  = -2
	lbl_f1.offset_bottom = -2
	lbl_f1.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	btn_help.add_child(lbl_f1)
