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
var _shop_panel: Control = null   # panneau boutique
var _shop_merchant: Node  = null  # marchand actif
var _talent_panel: Control = null   # panneau de choix de talent
var _boss_bar_container: Control = null   # barre boss (bas écran)
var _boss_bar_fill: ColorRect    = null
var _boss_bar_label: Label       = null
var _boss_max_hp: int = 1
var _minimap_rect: TextureRect   = null
var _minimap_image: Image        = null
var _minimap_texture: ImageTexture = null
var _minimap_timer: float        = 0.0
var _minimap_visible: bool       = true
const MINIMAP_UPDATE_INTERVAL: float = 0.5
const MINIMAP_DISPLAY_SIZE: int = 120

# ── Icônes de talents actifs (rangée sous les barres) ───────────────────────
var _talent_icons_row: HBoxContainer = null

# Couleur et abréviation par talent_id
const TALENT_ICON_DEFS: Dictionary = {
	"regen_on_kill":   { "abbr": "VA", "color": Color("#c0392b"), "full": "Vampire — +5 PV par kill" },
	"speed_boost":     { "abbr": "LE", "color": Color("#1abc9c"), "full": "Leste — Vitesse +15%" },
	"piercing_arrows": { "abbr": "FP", "color": Color("#e67e22"), "full": "Flèches perçantes — traversent les ennemis" },
	"max_health_up":   { "abbr": "RO", "color": Color("#27ae60"), "full": "Robuste — PV max +30" },
	"crit_chance":     { "abbr": "PR", "color": Color("#f1c40f"), "full": "Précision — 20% de coups critiques ×1.5" },
	"mana_regen_up":   { "abbr": "MY", "color": Color("#3498db"), "full": "Mystique — Régén mana ×2" },
	"double_loot":     { "abbr": "CH", "color": Color("#f39c12"), "full": "Chanceux — Ressources ×2" },
	"dash_heal":       { "abbr": "ES", "color": Color("#9b59b6"), "full": "Esquiveur — +3 PV par esquive" },
}
var _shop_buy_list:  VBoxContainer = null
var _shop_sell_list: VBoxContainer = null
var _shop_gold_label: Label = null

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
	# ── Panneau boutique (construit à la demande) ───────────────
	call_deferred("_build_shop_panel")
	# ── Talents passifs ──────────────────────────────────────────
	Stats.talent_available.connect(_show_talent_choices)
	call_deferred("_build_talent_panel")
	# ── Barre de vie boss ────────────────────────────────────────
	call_deferred("_build_boss_bar")
	# ── Minimap ──────────────────────────────────────────────────
	call_deferred("_build_minimap")
	# ── Icônes talents actifs (sous les barres) ──────────────────
	call_deferred("_build_talent_icons")

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
		# Touche M : afficher/masquer la minimap
		elif event.keycode == KEY_M:
			_minimap_visible = not _minimap_visible
			if _minimap_rect:
				_minimap_rect.get_parent().visible = _minimap_visible
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

func _process(delta: float):
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
		if _shop_panel and _shop_panel.visible:
			_shop_panel.visible = false
		if _talent_panel and _talent_panel.visible:
			pass  # talent panel non fermable — choix obligatoire
			
	if dialogue_box.visible and Input.is_action_just_pressed("ui_accept"):
		hide_dialogue()
	
	if Input.is_action_just_pressed("personnage"): # ou une nouvelle touche
		toggle_journal()
	# Minimap — mise à jour périodique
	_minimap_timer += delta
	if _minimap_timer >= MINIMAP_UPDATE_INTERVAL:
		_minimap_timer = 0.0
		_update_minimap()

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
	# Icônes de talents actifs
	_refresh_talent_icons()

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


# ============================================================
#  BOUTIQUE MARCHAND
# ============================================================

func _build_shop_panel() -> void:
	# Overlay sombre plein écran
	var overlay = ColorRect.new()
	overlay.name = "ShopOverlay"
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	add_child(overlay)
	_shop_panel = overlay

	# Panneau centré
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 420)
	panel.offset_left   = -260
	panel.offset_top    = -210
	panel.offset_right  = 260
	panel.offset_bottom = 210
	var style = StyleBoxFlat.new()
	style.bg_color          = Color(0.12, 0.10, 0.07, 0.97)
	style.border_color      = Color(0.8, 0.65, 0.25, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# ── Titre ──────────────────────────────────────────────────
	var title_row = HBoxContainer.new()
	vbox.add_child(title_row)

	var lbl_title = Label.new()
	lbl_title.name = "ShopTitle"
	lbl_title.text = "Boutique"
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(lbl_title)

	# Or du joueur
	_shop_gold_label = Label.new()
	_shop_gold_label.add_theme_font_size_override("font_size", 14)
	_shop_gold_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	_shop_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(_shop_gold_label)

	# Bouton fermer
	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.add_theme_font_size_override("font_size", 16)
	btn_close.pressed.connect(func(): _shop_panel.visible = false)
	title_row.add_child(btn_close)

	# Séparateur
	vbox.add_child(HSeparator.new())

	# ── Corps : Acheter | Vendre côte à côte ───────────────────
	var hbox = HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	# Colonne Acheter
	var col_buy = VBoxContainer.new()
	col_buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_buy)
	var lbl_buy = Label.new()
	lbl_buy.text = "🛒 Acheter"
	lbl_buy.add_theme_font_size_override("font_size", 14)
	lbl_buy.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	col_buy.add_child(lbl_buy)
	col_buy.add_child(HSeparator.new())
	var scroll_buy = ScrollContainer.new()
	scroll_buy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_buy.add_child(scroll_buy)
	_shop_buy_list = VBoxContainer.new()
	_shop_buy_list.add_theme_constant_override("separation", 4)
	scroll_buy.add_child(_shop_buy_list)

	# Séparateur vertical
	hbox.add_child(VSeparator.new())

	# Colonne Vendre
	var col_sell = VBoxContainer.new()
	col_sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_sell)
	var lbl_sell = Label.new()
	lbl_sell.text = "💰 Vendre"
	lbl_sell.add_theme_font_size_override("font_size", 14)
	lbl_sell.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	col_sell.add_child(lbl_sell)
	col_sell.add_child(HSeparator.new())
	var scroll_sell = ScrollContainer.new()
	scroll_sell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col_sell.add_child(scroll_sell)
	_shop_sell_list = VBoxContainer.new()
	_shop_sell_list.add_theme_constant_override("separation", 4)
	scroll_sell.add_child(_shop_sell_list)

func open_shop(merchant: Node) -> void:
	if not _shop_panel:
		return
	_shop_merchant = merchant
	_refresh_shop()
	_shop_panel.visible = true

func _refresh_shop() -> void:
	if not _shop_merchant or not _shop_buy_list or not _shop_sell_list:
		return

	# Titre
	var title = _shop_panel.find_child("ShopTitle", true, false)
	if title:
		title.text = _shop_merchant.get("shop_title") if _shop_merchant.get("shop_title") else "Boutique"

	# Or du joueur
	_shop_gold_label.text = "💰 %d or" % Inventory.gold

	# ── Liste Acheter ───────────────────────────────────────────
	for child in _shop_buy_list.get_children():
		child.queue_free()
	var items_to_sell: Array = _shop_merchant.get("sell_items") if _shop_merchant.get("sell_items") else []
	for item in items_to_sell:
		_shop_buy_list.add_child(_make_shop_row_buy(item["name"], item["price"]))

	# ── Liste Vendre (inventaire du joueur) ─────────────────────
	for child in _shop_sell_list.get_children():
		child.queue_free()
	var buy_prices: Dictionary = _shop_merchant.get("buy_prices") if _shop_merchant.get("buy_prices") else {}
	var can_buy: bool = _shop_merchant.get("can_buy_from_player") if _shop_merchant.get("can_buy_from_player") else false
	if can_buy:
		for item_name in Inventory.items:
			var qty: int = Inventory.items[item_name]
			if qty <= 0:
				continue
			# Prix de rachat : buy_prices ou price/2
			var price: int = buy_prices.get(item_name, 0)
			if price <= 0:
				continue
			_shop_sell_list.add_child(_make_shop_row_sell(item_name, qty, price))
	if _shop_sell_list.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "Rien à vendre."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_shop_sell_list.add_child(lbl)

func _make_shop_row_buy(item_name: String, price: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Icône
	var icon = TextureRect.new()
	icon.texture = get_item_texture(item_name)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	# Nom
	var lbl = Label.new()
	lbl.text = item_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)

	# Prix
	var lbl_price = Label.new()
	var can_afford: bool = Inventory.gold >= price
	lbl_price.text = "%d 💰" % price
	lbl_price.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.3) if can_afford else Color(1.0, 0.3, 0.3))
	lbl_price.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl_price)

	# Bouton acheter
	var btn = Button.new()
	btn.text = "Acheter"
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not can_afford
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(_on_buy_pressed.bind(item_name, price))
	row.add_child(btn)
	return row

func _make_shop_row_sell(item_name: String, qty: int, price: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Icône
	var icon = TextureRect.new()
	icon.texture = get_item_texture(item_name)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	# Nom + quantité
	var lbl = Label.new()
	lbl.text = "%s ×%d" % [item_name, qty]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)

	# Prix de vente
	var lbl_price = Label.new()
	lbl_price.text = "%d 💰" % price
	lbl_price.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl_price.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl_price)

	# Bouton vendre
	var btn = Button.new()
	btn.text = "Vendre"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(_on_sell_pressed.bind(item_name, price))
	row.add_child(btn)
	return row

func _on_buy_pressed(item_name: String, price: int) -> void:
	if Inventory.gold < price:
		show_notification("Pas assez d'or !", Color(1.0, 0.4, 0.2))
		return
	Inventory.add_gold(-price)
	Inventory.add_item(item_name, 1)
	show_notification("Acheté : %s" % item_name, Color(0.6, 1.0, 0.6))
	_refresh_shop()

func _on_sell_pressed(item_name: String, price: int) -> void:
	if not Inventory.items.has(item_name) or Inventory.items[item_name] <= 0:
		return
	Inventory.remove_item(item_name, 1)
	Inventory.add_gold(price)
	show_notification("Vendu : %s (+%d or)" % [item_name, price], Color(1.0, 0.9, 0.3))
	_refresh_shop()

# ============================================================
#  TALENTS PASSIFS
# ============================================================

func _build_talent_panel() -> void:
	var overlay = ColorRect.new()
	overlay.name = "TalentOverlay"
	overlay.color = Color(0, 0, 0, 0.80)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	_talent_panel = overlay

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 20)
	vbox.custom_minimum_size = Vector2(600, 0)
	vbox.offset_left = -300
	vbox.offset_right = 300
	overlay.add_child(vbox)

	var title = Label.new()
	title.name = "TalentTitle"
	title.text = "🌟 Choisis un talent !"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(title)

	var cards_row = HBoxContainer.new()
	cards_row.name = "CardsRow"
	cards_row.add_theme_constant_override("separation", 16)
	vbox.add_child(cards_row)

func _show_talent_choices(choices: Array) -> void:
	if not _talent_panel:
		return
	_talent_panel.visible = true
	get_tree().paused = true

	var vbox = _talent_panel.get_child(0)
	var cards_row: HBoxContainer = vbox.get_node("CardsRow")
	# Nettoyer les cartes précédentes
	for c in cards_row.get_children():
		c.queue_free()

	for talent in choices:
		var card = _make_talent_card(talent)
		cards_row.add_child(card)

func _make_talent_card(talent: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(170, 180)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.07, 0.97)
	style.border_color = Color(0.8, 0.65, 0.25, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", style)

	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var lbl_name = Label.new()
	lbl_name.text = talent["label"]
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vb.add_child(lbl_name)

	vb.add_child(HSeparator.new())

	var lbl_desc = Label.new()
	lbl_desc.text = talent["desc"]
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 12)
	lbl_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vb.add_child(lbl_desc)

	var btn = Button.new()
	btn.text = "Choisir"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 13)
	btn.pressed.connect(_on_talent_chosen.bind(talent["id"], talent["label"]))
	vb.add_child(btn)

	return card

func _on_talent_chosen(talent_id: String, talent_label: String) -> void:
	Stats.apply_talent(talent_id)
	get_tree().paused = false
	_talent_panel.visible = false
	show_notification("🌟 Talent acquis : " + talent_label, Color(1.0, 0.9, 0.2))
	_refresh_talent_icons()

# ============================================================
#  BARRE DE VIE BOSS
# ============================================================

func _build_boss_bar() -> void:
	var container = PanelContainer.new()
	container.name = "BossBarContainer"
	container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	container.custom_minimum_size = Vector2(0, 52)
	container.offset_left  = 160
	container.offset_right = -160
	container.offset_top   = -70
	container.offset_bottom = -18

	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.05, 0.03, 0.03, 0.95)
	style.border_color = Color(0.75, 0.15, 0.10, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	container.add_theme_stylebox_override("panel", style)
	container.visible = false
	add_child(container)
	_boss_bar_container = container

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	container.add_child(vb)

	_boss_bar_label = Label.new()
	_boss_bar_label.text = "Boss"
	_boss_bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_bar_label.add_theme_font_size_override("font_size", 13)
	_boss_bar_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	vb.add_child(_boss_bar_label)

	# Fond de la barre
	var bar_bg = PanelContainer.new()
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.15, 0.05, 0.05)
	bar_style.set_corner_radius_all(4)
	bar_bg.add_theme_stylebox_override("panel", bar_style)
	bar_bg.custom_minimum_size = Vector2(0, 14)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(bar_bg)

	# Remplissage rouge
	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.color = Color(0.85, 0.15, 0.10)
	_boss_bar_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_bar_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.add_child(_boss_bar_fill)

func on_boss_spawned(boss: Node) -> void:
	if not _boss_bar_container:
		return
	_boss_max_hp = boss.max_health
	_boss_bar_label.text = "☠ " + boss.get("boss_name") + " ☠"
	_boss_bar_fill.anchor_right = 1.0
	_boss_bar_container.visible = true
	# Connecter le signal de santé
	if not boss.boss_health_changed.is_connected(_on_boss_health_changed):
		boss.boss_health_changed.connect(_on_boss_health_changed)

func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	if not _boss_bar_fill:
		return
	_boss_max_hp = max_hp
	var pct = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
	_boss_bar_fill.anchor_right = pct

func on_boss_died() -> void:
	if not _boss_bar_container:
		return
	# Animer la barre à zéro puis cacher
	var tw = create_tween()
	tw.tween_property(_boss_bar_fill, "anchor_right", 0.0, 0.6)
	tw.tween_interval(0.4)
	tw.tween_property(_boss_bar_container, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		_boss_bar_container.visible = false
		_boss_bar_container.modulate.a = 1.0
	)

# ============================================================
#  ICÔNES DE TALENTS ACTIFS
# ============================================================

func _build_talent_icons() -> void:
	_talent_icons_row = HBoxContainer.new()
	_talent_icons_row.name = "TalentIconsRow"
	# Positionnée en haut-gauche, sous les barres de vie/mana/xp
	# Les barres occupent environ y=10 à y=82 (72px × scale 2 + marge)
	_talent_icons_row.set_anchor(SIDE_LEFT,   0.0)
	_talent_icons_row.set_anchor(SIDE_RIGHT,  0.0)
	_talent_icons_row.set_anchor(SIDE_TOP,    0.0)
	_talent_icons_row.set_anchor(SIDE_BOTTOM, 0.0)
	_talent_icons_row.offset_left   = 10
	_talent_icons_row.offset_top    = 92
	_talent_icons_row.offset_right  = 300
	_talent_icons_row.offset_bottom = 118   # hauteur 26px
	_talent_icons_row.add_theme_constant_override("separation", 3)
	add_child(_talent_icons_row)
	# Pas d'icônes au démarrage — peuplé dès le premier talent acquis
	_refresh_talent_icons()

func _refresh_talent_icons() -> void:
	if not _talent_icons_row:
		return
	# Vider les icônes existantes
	for child in _talent_icons_row.get_children():
		child.queue_free()
	# Reconstruire une icône par talent actif
	for tid in Stats.active_talents:
		var def = TALENT_ICON_DEFS.get(tid, null)
		if def == null:
			continue
		# Conteneur de l'icône
		var icon = PanelContainer.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.tooltip_text = def["full"]
		var style = StyleBoxFlat.new()
		style.bg_color = def["color"]
		style.corner_radius_top_left     = 4
		style.corner_radius_top_right    = 4
		style.corner_radius_bottom_left  = 4
		style.corner_radius_bottom_right = 4
		style.border_color = Color(1, 1, 1, 0.3)
		style.set_border_width_all(1)
		icon.add_theme_stylebox_override("panel", style)
		# Abréviation centrée
		var lbl = Label.new()
		lbl.text = def["abbr"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.add_child(lbl)
		_talent_icons_row.add_child(icon)

# ============================================================
#  MINIMAP
# ============================================================

func _build_minimap() -> void:
	# Conteneur avec bordure pixel-art
	var frame = PanelContainer.new()
	frame.name = "MinimapFrame"
	frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	frame.custom_minimum_size = Vector2(MINIMAP_DISPLAY_SIZE + 8, MINIMAP_DISPLAY_SIZE + 8)
	frame.offset_left   = -(MINIMAP_DISPLAY_SIZE + 16)
	frame.offset_top    = 8
	frame.offset_right  = -8
	frame.offset_bottom = MINIMAP_DISPLAY_SIZE + 16

	var style = StyleBoxFlat.new()
	style.bg_color     = Color(0.05, 0.05, 0.05, 0.85)
	style.border_color = Color(0.5, 0.5, 0.5, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)

	_minimap_rect = TextureRect.new()
	_minimap_rect.name = "MinimapTexture"
	_minimap_rect.custom_minimum_size = Vector2(MINIMAP_DISPLAY_SIZE, MINIMAP_DISPLAY_SIZE)
	_minimap_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_minimap_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_minimap_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_minimap_rect)

	# Créer l'image initiale (toute noire)
	_minimap_image = Image.create(120, 120, false, Image.FORMAT_RGBA8)
	_minimap_image.fill(Color(0.05, 0.05, 0.05))
	_minimap_texture = ImageTexture.create_from_image(_minimap_image)
	_minimap_rect.texture = _minimap_texture

func _update_minimap() -> void:
	if not _minimap_rect or not _minimap_image or not _minimap_texture:
		return

	var fog = get_tree().get_first_node_in_group("fog")
	if not fog:
		return

	var map_w: int = fog.map_width_tiles
	var map_h: int = fog.map_height_tiles
	var img_w: int = _minimap_image.get_width()
	var img_h: int = _minimap_image.get_height()

	var color_fog      = Color(0.05, 0.05, 0.05)
	var color_revealed = Color(0.25, 0.45, 0.20)
	var color_player   = Color(1.0, 1.0, 1.0)
	var color_enemy    = Color(1.0, 0.2, 0.2)

	# Remplir pixel par pixel en mappant sur les tuiles du fog
	for py in range(img_h):
		for px in range(img_w):
			var tx = int(px * map_w / img_w)
			var ty = int(py * map_h / img_h)
			var cell = Vector2i(tx, ty)
			var alpha = fog.revealed_cells.get(cell, fog.fog_alpha)
			if alpha < 0.5:
				_minimap_image.set_pixel(px, py, color_revealed)
			else:
				_minimap_image.set_pixel(px, py, color_fog)

	# Point joueur
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var map_origin: Vector2 = fog.map_origin
		var tile_size: int = fog.tile_size
		var local = player.global_position - map_origin
		var px = int(local.x / tile_size * img_w / map_w)
		var py = int(local.y / tile_size * img_h / map_h)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var cx = clamp(px + dx, 0, img_w - 1)
				var cy = clamp(py + dy, 0, img_h - 1)
				_minimap_image.set_pixel(cx, cy, color_player)

	# Points ennemis proches (dans le rayon révélé)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var local = enemy.global_position - fog.map_origin
		var px = int(local.x / fog.tile_size * img_w / map_w)
		var py = int(local.y / fog.tile_size * img_h / map_h)
		var cell = Vector2i(int(local.x / fog.tile_size), int(local.y / fog.tile_size))
		var alpha = fog.revealed_cells.get(cell, fog.fog_alpha)
		if alpha < 0.5 and px >= 0 and px < img_w and py >= 0 and py < img_h:
			_minimap_image.set_pixel(px, py, color_enemy)

	_minimap_texture.update(_minimap_image)
