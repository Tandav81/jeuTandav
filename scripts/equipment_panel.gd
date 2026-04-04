extends Control
# ============================================================
#  EquipmentPanel — design pixel-perfect sur Equipment.png
#  Touche G pour ouvrir/fermer.
#
#  Layout analysé pixel-par-pixel (×4 scale, 160×88 → 640×352) :
#
#  Section gauche (personnage dessiné dans l'image) :
#   Rangée 1 :        [CASQUE]          x=132,y=68  56×56
#   Rangée 2 : [BOU] [PLASTRON] [ARME]  y=132  52×56 / 84×56 / 48×56
#   Rangée 3 :        [BOTTES]          x=132,y=196 56×56
#   Rangée 4 : [ANN]          [AMU]     y=260  48×56 / 48×56
#
#  Section droite (grille items, cellules native 14×17px → 56×68px à ×4) :
#   4 colonnes séparées à x=95,111,127 (natif) = x=380,444,508 (×4)
# ============================================================

# ── Chemins ──────────────────────────────────────────────────
const EQUIP_TEX_PATH  = "res://assets/menus/Equipment.png"

# ── Région du PNG à utiliser (panneau 1 : y=0..87) ───────────
const IMG_REGION  = Rect2(0, 0, 160, 88)

# ── Dimensions du panneau à ×4 ───────────────────────────────
const PANEL_W     = 640        # 160 × 4
const PANEL_IMG_H = 352        # 88 × 4
const DETAIL_H    = 36
const PANEL_H     = 388

# ── Positions et tailles EXACTES des slots (px ×4) ───────────
# Déterminées par analyse pixel du PNG (run Python)
const SLOT_POSITIONS = {
	# Croix parfaite : gaps V=8px, gaps H=12px, tous 56×56
	# Centre x=160 (milieu section personnage), colonnes à ±68px
	"casque":   Vector2(132, 68),    # centre (160, 96)
	"bouclier": Vector2(64,  132),   # centre (92,  160)
	"plastron": Vector2(132, 132),   # centre (160, 160)
	"arme":     Vector2(200, 132),   # centre (228, 160)
	"bottes":   Vector2(132, 196),   # centre (160, 224)
	"anneau":   Vector2(64,  260),   # centre (92,  288)
	"amulette": Vector2(200, 260),   # centre (228, 288)
}
const SLOT_SIZES = {
	"casque":   Vector2(56, 56),
	"bouclier": Vector2(56, 56),
	"plastron": Vector2(56, 56),
	"arme":     Vector2(56, 56),
	"bottes":   Vector2(56, 56),
	"anneau":   Vector2(56, 56),
	"amulette": Vector2(56, 56),
}
const SLOT_LABELS = {
	"casque": "Casque", "amulette": "Amulette", "anneau": "Anneau",
	"bouclier": "Bouclier", "arme": "Arme",
	"plastron": "Plastron", "bottes": "Bottes",
}

# ── Zone items — grille droite ────────────────────────────────
# Cellules natives : x=81..94, 97..110, 113..126, 129..142 (14px chaque)
# → ×4 : colonnes démarrant à x=324, 388, 452, 516 (largeur 56px)
# On utilise la section complète avec marges pour centrer joliment
const ITEMS_X    = 324        # aligné sur la 1ère colonne native (x=81×4=324)
const ITEMS_Y    = 68         # sous le header teal + décalage d'alignement
const ITEMS_W    = 288        # largeur utile de la grille
const ITEMS_H    = 280        # hauteur utile
const ITEM_COLS  = 4
const ITEM_BTN_W = 56         # cellule native 14px × 4 = 56px
const ITEM_BTN_H = 56         # cellule native 14px × 4 = 56px

# ── Couleurs palette Equipment.png ────────────────────────────
const COL_TAN        = Color(0.804, 0.651, 0.467)   # (205,166,119)
const COL_BEIGE      = Color(0.898, 0.839, 0.631)   # (229,214,161)
const COL_BROWN      = Color(0.510, 0.361, 0.184)   # (130,92,47)
const COL_TEAL       = Color(0.314, 0.663, 0.471)   # (80,169,120)
const COL_DARK       = Color(0.243, 0.122, 0.114)   # (62,31,29)
# Slots : fond totalement transparent pour laisser l'image transparaître
const COL_SLOT_EMPTY    = Color(0.0, 0.0, 0.0, 0.0)       # invisible
const COL_SLOT_EQUIPPED = Color(0.12, 0.55, 0.20, 0.60)   # vert semi-transparent
const COL_BORDER_EMPTY  = Color(0.0, 0.0, 0.0, 0.0)       # invisible
const COL_BORDER_EQ     = Color(0.53, 0.87, 0.42, 1.0)    # vert vif
const COL_GOLD          = Color("#FFD700")

# ── Données internes ─────────────────────────────────────────
var _slot_data: Dictionary = {}
var _item_grid: GridContainer = null
var _detail_label: Label = null

# ============================================================
func _ready() -> void:
	_build_panel()
	Inventory.inventory_changed.connect(_refresh)
	visible = false

# ============================================================
#  CONSTRUCTION
# ============================================================

func _build_panel() -> void:
	# Centrage plein écran
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	set_anchor(SIDE_LEFT,   0.5)
	set_anchor(SIDE_TOP,    0.5)
	set_anchor(SIDE_RIGHT,  0.5)
	set_anchor(SIDE_BOTTOM, 0.5)
	offset_left   = -PANEL_W * 0.5
	offset_top    = -PANEL_H * 0.5
	offset_right  =  PANEL_W * 0.5
	offset_bottom =  PANEL_H * 0.5

	# Supprimer le fond blanc du Panel Godot
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	# ── Texture Equipment.png ×4 ─────────────────────────────
	var bg = TextureRect.new()
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas = AtlasTexture.new()
	atlas.atlas  = load(EQUIP_TEX_PATH)
	atlas.region = IMG_REGION
	bg.texture      = atlas
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.position     = Vector2.ZERO
	bg.size         = Vector2(PANEL_W, PANEL_IMG_H)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Barre de détails sous l'image ────────────────────────
	var detail_bg = ColorRect.new()
	detail_bg.color    = COL_DARK
	detail_bg.position = Vector2(0, PANEL_IMG_H)
	detail_bg.size     = Vector2(PANEL_W, DETAIL_H)
	detail_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(detail_bg)

	var sep = ColorRect.new()
	sep.color    = COL_TAN
	sep.position = Vector2(0, PANEL_IMG_H)
	sep.size     = Vector2(PANEL_W, 2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# ── Bouton fermer — zone invisible sur le X dessiné dans l'image ─
	# Position native : x=144..150, y=3..9 → ×4 : x=576, y=12, 28×28
	var btn_close = Button.new()
	btn_close.text = ""          # invisible : le X du dessin suffit
	btn_close.flat = true
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.add_theme_stylebox_override("normal",   StyleBoxEmpty.new())
	btn_close.add_theme_stylebox_override("hover",    StyleBoxEmpty.new())
	btn_close.add_theme_stylebox_override("pressed",  StyleBoxEmpty.new())
	btn_close.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	btn_close.position = Vector2(576, 12)
	btn_close.size     = Vector2(28, 28)
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_close.pressed.connect(func(): visible = false)
	add_child(btn_close)

	# ── Slots d'équipement (superposés aux cadres de l'image) ─
	for slot_id in SLOT_POSITIONS.keys():
		var sz  = SLOT_SIZES[slot_id]
		var slot_node = _make_slot_button(slot_id, sz)
		slot_node.position = SLOT_POSITIONS[slot_id]
		add_child(slot_node)
		_slot_data[slot_id] = slot_node.get_meta("slot_refs")

	# ── Grille d'items (section droite) ──────────────────────
	_build_item_list()

	# ── Label de détails ─────────────────────────────────────
	_detail_label = Label.new()
	_detail_label.text = "Survolez un emplacement ou un item pour voir ses détails"
	_detail_label.add_theme_color_override("font_color", Color("#a09070"))
	_detail_label.add_theme_font_size_override("font_size", 11)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.position = Vector2(8, PANEL_IMG_H + 4)
	_detail_label.size     = Vector2(PANEL_W - 16, DETAIL_H - 6)
	_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_detail_label)

# ── Slot bouton superposé au cadre dessiné dans l'image ─────

func _make_slot_button(slot_id: String, sz: Vector2) -> Control:
	var container = Control.new()
	container.custom_minimum_size = sz
	container.size = sz

	# Fond — transparent par défaut, coloré si équipé
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Icône item — remplit le cadre dessiné (1px de marge seulement)
	var icon = TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.set_offset(SIDE_LEFT,   1)
	icon.set_offset(SIDE_TOP,    1)
	icon.set_offset(SIDE_RIGHT, -1)
	icon.set_offset(SIDE_BOTTOM,-1)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Zone de clic
	var click = Button.new()
	click.flat = true
	click.focus_mode = Control.FOCUS_NONE
	click.set_anchors_preset(Control.PRESET_FULL_RECT)
	click.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	click.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	click.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click.mouse_entered.connect(_on_slot_hover.bind(slot_id))
	click.mouse_exited.connect(_on_hover_exit)
	click.pressed.connect(_on_slot_clicked.bind(slot_id))
	container.add_child(click)

	container.set_meta("slot_refs", {"bg": bg, "icon": icon})
	return container

# ── Grille d'items ──────────────────────────────────────────

func _build_item_list() -> void:
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(ITEMS_X, ITEMS_Y)
	scroll.size     = Vector2(ITEMS_W, ITEMS_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)

	_item_grid = GridContainer.new()
	_item_grid.columns = ITEM_COLS
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_grid.add_theme_constant_override("h_separation", 8)
	_item_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_item_grid)

# ============================================================
#  RAFRAÎCHISSEMENT
# ============================================================

func _refresh() -> void:
	if not visible:
		return
	_refresh_slots()
	_refresh_items()

func _refresh_slots() -> void:
	for slot_id in _slot_data.keys():
		var refs = _slot_data[slot_id]
		var bg   = refs["bg"]   as Panel
		var icon = refs["icon"] as TextureRect
		var eq   = Inventory.equipped.get(slot_id, null)

		var style = StyleBoxFlat.new()
		style.corner_radius_top_left     = 3
		style.corner_radius_top_right    = 3
		style.corner_radius_bottom_left  = 3
		style.corner_radius_bottom_right = 3

		if eq != null:
			# Slot équipé : fond vert semi-transparent + bordure verte
			style.bg_color     = COL_SLOT_EQUIPPED
			style.border_color = COL_BORDER_EQ
			style.set_border_width_all(2)
			icon.texture = ItemData.get_texture(str(eq))
		else:
			# Slot vide : totalement transparent (cadre de l'image visible)
			style.bg_color     = COL_SLOT_EMPTY
			style.border_color = COL_BORDER_EMPTY
			style.set_border_width_all(0)
			icon.texture = null

		bg.add_theme_stylebox_override("panel", style)

func _refresh_items() -> void:
	# Vider proprement la grille (remove_child = immédiat, pas de race condition)
	var old_children = _item_grid.get_children()
	for child in old_children:
		_item_grid.remove_child(child)
		child.queue_free()

	var shown: Array = []

	# 1. Items dans Inventory.items filtrés par equipment_data
	for item_name in Inventory.items.keys():
		if not Stats.equipment_data.has(item_name):
			continue
		var slot_id = Stats.equipment_data[item_name]["slot"]
		var is_eq   = (Inventory.equipped.get(slot_id) == item_name)
		var qty     = Inventory.items[item_name]
		_item_grid.add_child(_make_item_button(item_name, slot_id, is_eq, qty))
		shown.append(item_name)

	# 2. Fallback : items équipés mais absents de Inventory.items
	for slot_id in Inventory.equipped.keys():
		var eq = Inventory.equipped.get(slot_id, null)
		if eq == null or shown.has(eq):
			continue
		if Stats.equipment_data.has(eq):
			_item_grid.add_child(_make_item_button(eq, slot_id, true, 1))
			shown.append(eq)

	if _item_grid.get_child_count() == 0:
		var lbl = Label.new()
		lbl.text = "Aucun équipement\ndans l'inventaire"
		lbl.add_theme_color_override("font_color", COL_BROWN)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_item_grid.add_child(lbl)

func _make_item_button(item_name: String, slot_id: String, is_eq: bool, qty: int) -> Control:
	var container = Control.new()
	container.set_meta("item_name", item_name)   # pour le fallback du refresh
	container.custom_minimum_size = Vector2(ITEM_BTN_W, ITEM_BTN_H)

	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left    = 3
	style.corner_radius_top_right   = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.set_border_width_all(2)
	if is_eq:
		style.bg_color     = Color(0.16, 0.38, 0.14, 0.85)
		style.border_color = COL_BORDER_EQ
	else:
		style.bg_color     = Color(0.18, 0.12, 0.06, 0.75)
		style.border_color = COL_TAN
	bg.add_theme_stylebox_override("panel", style)
	container.add_child(bg)

	# Icône — grande, occupe la majorité du bouton
	var icon = TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture        = ItemData.get_texture(item_name)
	icon.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(2, 2)
	icon.size     = Vector2(ITEM_BTN_W - 4, ITEM_BTN_H - 4)    # 52×52 — remplit la cellule
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Pas de label visible — le nom s'affiche dans la barre de détails au survol

	# Badge équipé (petit ✓ en haut à droite)
	if is_eq:
		var badge = Label.new()
		badge.text = "✓"
		badge.add_theme_color_override("font_color", Color("#6dff6d"))
		badge.add_theme_font_size_override("font_size", 9)
		badge.position = Vector2(ITEM_BTN_W - 12, 2)           # x=44
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(badge)

	# Quantité (bas-gauche, petit)
	if qty > 1:
		var qty_lbl = Label.new()
		qty_lbl.text = "×%d" % qty
		qty_lbl.add_theme_color_override("font_color", COL_BEIGE)
		qty_lbl.add_theme_font_size_override("font_size", 7)
		qty_lbl.position = Vector2(2, ITEM_BTN_H - 10)
		qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(qty_lbl)

	# Zone de clic
	var click = Button.new()
	click.flat = true
	click.focus_mode = Control.FOCUS_NONE
	click.set_anchors_preset(Control.PRESET_FULL_RECT)
	click.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	click.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	click.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click.mouse_entered.connect(_on_item_hover.bind(item_name, slot_id, is_eq))
	click.mouse_exited.connect(_on_hover_exit)
	if is_eq:
		click.pressed.connect(_on_desequip.bind(slot_id))
	else:
		click.pressed.connect(_on_equip.bind(item_name, slot_id))
	container.add_child(click)

	return container

# ============================================================
#  INTERACTIONS
# ============================================================

func _on_slot_clicked(slot_id: String) -> void:
	if Inventory.equipped.get(slot_id) != null:
		_on_desequip(slot_id)

func _on_equip(item_name: String, slot_id: String) -> void:
	Inventory.equip_item(slot_id, item_name)
	Stats.emit_signal("stats_changed")
	_refresh()

func _on_desequip(slot_id: String) -> void:
	Inventory.unequip_item(slot_id)
	Stats.emit_signal("stats_changed")
	_refresh()

# ============================================================
#  SURVOL
# ============================================================

func _on_slot_hover(slot_id: String) -> void:
	var eq = Inventory.equipped.get(slot_id, null)
	if eq != null:
		var data    = Stats.equipment_data.get(eq, {})
		var bonuses = _format_bonuses(data)
		_detail_label.text = "[%s]  %s%s" % [SLOT_LABELS[slot_id], eq, bonuses]
		_detail_label.add_theme_color_override("font_color", Color("#88ff88"))
	else:
		_detail_label.text = "[%s] — vide  (cliquer un item ci-contre pour équiper)" % SLOT_LABELS[slot_id]
		_detail_label.add_theme_color_override("font_color", COL_TAN)

func _on_item_hover(item_name: String, slot_id: String, is_eq: bool) -> void:
	var data    = Stats.equipment_data.get(item_name, {})
	var bonuses = _format_bonuses(data)
	var state   = "  ✅ Équipé — cliquer pour retirer" if is_eq else \
				  "  → cliquer pour équiper (%s)" % SLOT_LABELS.get(slot_id, slot_id)
	_detail_label.text = item_name + bonuses + state
	_detail_label.add_theme_color_override("font_color",
		Color("#88ff88") if is_eq else COL_GOLD)

func _on_hover_exit() -> void:
	_detail_label.text = "Survolez un emplacement ou un item pour voir ses détails"
	_detail_label.add_theme_color_override("font_color", Color("#a09070"))

func _format_bonuses(data: Dictionary) -> String:
	if data.is_empty():
		return ""
	var parts = []
	var stat_map = {"force": "FOR", "endurance": "END",
					"agilite": "AGI", "magie": "MAG", "defense": "DEF"}
	for stat in stat_map.keys():
		var val = data.get(stat, 0)
		if val > 0:
			parts.append("+%d %s" % [val, stat_map[stat]])
		elif val < 0:
			parts.append("%d %s" % [val, stat_map[stat]])
	return "" if parts.is_empty() else "  [" + ", ".join(parts) + "]"

# ============================================================
#  TOGGLE
# ============================================================

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()
