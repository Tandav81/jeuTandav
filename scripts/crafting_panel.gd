extends Node

# ============================================================
#  CRAFTING PANEL v2
#  Positionnement absolu calé sur le fond spritesheet.
#  Ajouté dynamiquement par hud.gd dans _ready().
#
#  Mesures pixel Craft.png col 2 (208×128) :
#   - Zone GAUCHE  (recettes) : x= 8–71
#   - Zone MILIEU  (sombre)   : x=72–135   ← bouton CREATE
#   - Zone DROITE  (claire)   : x=136–199  ← détails recette
#   - Onglet armes (vert T)   : x=18–27, y=12–22
#   - Onglet potions (mortier): x=35–44, y=13–22
#   - Bouton CREATE (vert)    : x=83–123,  y=70–79
# ============================================================

const PANEL_SCALE = 3
const PANEL_W     = 208
const PANEL_H     = 128

# Alias court pour les calculs de position
const S = PANEL_SCALE

# ---- Chemins assets ----------------------------------------
const CRAFT_TEX  = "res://assets/menus/Craft.png"
const ITEMS_TEX  = "res://assets/rpgItems.png"

# ---- Icônes items (fichiers PNG dédiés) --------------------
const ITEM_IMAGES = {
	"Bois":    "res://assets/sprites/wood/wood.png",
	"Minerai": "res://assets/sprites/rock/rock.png",
}

# Regions dans rpgItems.png (cellules 16×16, grille 8×8)
const ITEM_REGIONS = {
	"Potion":        Rect2(0,   0,  16, 16),
	"Viande":        Rect2(16,  64, 16, 16),
	"Epee en bois":  Rect2(80,  64, 16, 16),  # ligne 4 col 5 ← CORRIGÉ (v1 avait ligne 3 = pioche)
	"Epee en fer":   Rect2(96,  64, 16, 16),  # ligne 4 col 6
	"Baton magique": Rect2(64,  48, 16, 16),  # ligne 3 col 4
}

# ---- Recettes ----------------------------------------------
# Ajouter de nouvelles recettes ici sans toucher au reste du code.
const RECIPES = {
	"armes": [
		{
			"name":        "Epee en bois",
			"ingredients": {"Bois": 2},
			"result":      "Epee en bois",
			"result_qty":  1,
		},
	],
	"potions": [
		# Exemple : {"name": "Potion", "ingredients": {"Plante": 1}, "result": "Potion", "result_qty": 1}
	],
}

# ---- Couleurs ----------------------------------------------
const C_TEXT_WHITE  = Color("#ffffff")
const C_TEXT_GREY   = Color("#888888")
const C_TEXT_GREEN  = Color("#44ff44")
const C_TEXT_RED    = Color("#ff4444")
const C_TEXT_GOLD   = Color("#FFD700")
const C_TEXT_NORMAL = Color("#ddccaa")

# ---- État --------------------------------------------------
var current_tab           = "armes"
var selected_recipe_index = -1
var panel_visible         = false

# ---- Références nœuds UI -----------------------------------
var root_control:          Control
var bg_texture:            TextureRect
var recipe_list_container: GridContainer
var recipe_slots:          Array = []   # Control nodes des cases recettes
var ingredient_area:       VBoxContainer
var result_display:        HBoxContainer
var create_btn:            Button
var feedback_label:        Label
var tab_btns:              Dictionary = {}   # "armes" / "potions" → Button

# ============================================================
func _ready() -> void:
	_build_panel()
	root_control.visible = false

# ============================================================
#  CONSTRUCTION DE L'UI
# ============================================================

func _build_panel() -> void:
	# ── Conteneur racine centré à l'écran ──────────────────
	root_control = Control.new()
	root_control.anchor_left   = 0.5
	root_control.anchor_right  = 0.5
	root_control.anchor_top    = 0.5
	root_control.anchor_bottom = 0.5
	var pw = PANEL_W * S
	var ph = PANEL_H * S
	root_control.offset_left   = -pw / 2.0
	root_control.offset_right  =  pw / 2.0
	root_control.offset_top    = -ph / 2.0
	root_control.offset_bottom =  ph / 2.0
	add_child(root_control)

	# ── Fond spritesheet ────────────────────────────────────
	bg_texture = TextureRect.new()
	bg_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_texture.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode   = TextureRect.STRETCH_SCALE
	bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(bg_texture)
	_update_bg_texture()

	# ── Boutons d'onglets invisibles ────────────────────────
	# Positionnés sur les icônes d'onglets du spritesheet.
	# Le changement de fond gère le rendu actif/inactif — pas besoin de texte.
	# Armes (icône T verte) : x=18–27, y=12–22 à 1×
	var btn_armes = _make_invisible_btn(
		Vector2(14, 8) * S, Vector2(20, 20) * S,
		_on_tab_pressed.bind("armes")
	)
	root_control.add_child(btn_armes)
	tab_btns["armes"] = btn_armes

	# Potions (icône mortier verte) : x=35–44, y=13–22 à 1×
	var btn_potions = _make_invisible_btn(
		Vector2(32, 8) * S, Vector2(20, 20) * S,
		_on_tab_pressed.bind("potions")
	)
	root_control.add_child(btn_potions)
	tab_btns["potions"] = btn_potions

	# ── Bouton FERMER (coin haut-droit du panneau) ──────────
	var close_btn = _make_invisible_btn(
		Vector2(192, 2) * S, Vector2(12, 10) * S,
		hide_panel
	)
	root_control.add_child(close_btn)

	# ── Liste de recettes — zone GAUCHE (x=10–68 à 1×) ─────
	recipe_list_container = GridContainer.new()
	recipe_list_container.columns = 3
	recipe_list_container.position = Vector2(10, 28) * S
	recipe_list_container.add_theme_constant_override("h_separation", 3)
	recipe_list_container.add_theme_constant_override("v_separation", 3)
	root_control.add_child(recipe_list_container)

	# ── Zone détail — zone DROITE (x=138–196, y=10–65 à 1×) ─
	var detail_ctrl = Control.new()
	detail_ctrl.position = Vector2(138, 10) * S
	detail_ctrl.size     = Vector2(58, 56) * S
	root_control.add_child(detail_ctrl)

	var detail_vbox = VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 3)
	detail_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_ctrl.add_child(detail_vbox)

	var lbl_ingr = Label.new()
	lbl_ingr.text = "Ingrédients"
	lbl_ingr.add_theme_color_override("font_color", C_TEXT_NORMAL)
	lbl_ingr.add_theme_font_size_override("font_size", 9)
	detail_vbox.add_child(lbl_ingr)

	ingredient_area = VBoxContainer.new()
	ingredient_area.add_theme_constant_override("separation", 2)
	detail_vbox.add_child(ingredient_area)

	var lbl_result = Label.new()
	lbl_result.text = "Résultat"
	lbl_result.add_theme_color_override("font_color", C_TEXT_NORMAL)
	lbl_result.add_theme_font_size_override("font_size", 9)
	detail_vbox.add_child(lbl_result)

	result_display = HBoxContainer.new()
	result_display.add_theme_constant_override("separation", 4)
	detail_vbox.add_child(result_display)

	# ── Bouton CRÉER (transparent, sur le bouton CREATE du spritesheet) ─
	# CREATE (pixels verts) : x=83–123, y=70–79 à 1×
	# Zone cliquable élargie : y=66–84 pour faciliter le clic
	create_btn = Button.new()
	create_btn.flat       = true
	create_btn.position   = Vector2(83, 66) * S
	create_btn.size       = Vector2(41, 18) * S
	create_btn.focus_mode = Control.FOCUS_NONE
	create_btn.disabled   = true
	create_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_create_btn(create_btn, false)
	create_btn.pressed.connect(_on_create_pressed)
	root_control.add_child(create_btn)

	# ── Label feedback (zone MILIEU bas : x=72–135, y=84–115) ─
	feedback_label = Label.new()
	feedback_label.position           = Vector2(72, 84) * S
	feedback_label.size               = Vector2(63, 32) * S
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 8)
	feedback_label.autowrap_mode      = TextServer.AUTOWRAP_WORD
	root_control.add_child(feedback_label)

	_refresh_recipe_list()


# ============================================================
#  MISE À JOUR DE L'UI
# ============================================================

func _update_bg_texture() -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas  = load(CRAFT_TEX)
	# Col 2 (x=416) : panneau avec bouton CREATE visible
	# Row 0 (y=  0) : armes (enclume)
	# Row 1 (y=128) : potions (mortier)
	var row_y = 0 if current_tab == "armes" else 128
	atlas.region = Rect2(416, row_y, PANEL_W, PANEL_H)
	bg_texture.texture = atlas

func _refresh_recipe_list() -> void:
	for child in recipe_list_container.get_children():
		child.queue_free()
	recipe_slots.clear()
	selected_recipe_index = -1
	_clear_detail_panel()

	var recipes: Array = RECIPES.get(current_tab, [])
	if recipes.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "—"
		empty_lbl.add_theme_color_override("font_color", C_TEXT_GREY)
		empty_lbl.add_theme_font_size_override("font_size", 10)
		recipe_list_container.add_child(empty_lbl)
		return

	for i in range(recipes.size()):
		var slot = _make_recipe_slot(i)
		recipe_list_container.add_child(slot)
		recipe_slots.append(slot)

func _on_recipe_selected(index: int) -> void:
	selected_recipe_index = index
	# Met à jour l'apparence des cases (sélectionnée = fond plus clair)
	for i in range(recipe_slots.size()):
		_set_slot_selected(recipe_slots[i], i == index)
	_update_right_panel()

func _update_right_panel() -> void:
	_clear_detail_panel()
	if selected_recipe_index < 0:
		return

	var recipe: Dictionary = RECIPES[current_tab][selected_recipe_index]

	# -- Ingrédients --
	for item_name in recipe["ingredients"]:
		var qty_needed: int = recipe["ingredients"][item_name]
		var qty_have:   int = Inventory.items.get(item_name, 0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		ingredient_area.add_child(row)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode         = TextureRect.EXPAND_FIT_WIDTH
		icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter      = CanvasItem.TEXTURE_FILTER_NEAREST
		var tex = _get_item_texture(item_name)
		if tex:
			icon.texture = tex
		row.add_child(icon)

		var lbl = Label.new()
		lbl.text = "%d/%d" % [qty_have, qty_needed]
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color",
			C_TEXT_GREEN if qty_have >= qty_needed else C_TEXT_RED)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(lbl)

	# -- Résultat --
	var res_icon = TextureRect.new()
	res_icon.custom_minimum_size = Vector2(22, 22)
	res_icon.expand_mode         = TextureRect.EXPAND_FIT_WIDTH
	res_icon.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	res_icon.texture_filter      = CanvasItem.TEXTURE_FILTER_NEAREST
	var res_tex = _get_item_texture(recipe["result"])
	if res_tex:
		res_icon.texture = res_tex
	result_display.add_child(res_icon)

	var res_lbl = Label.new()
	res_lbl.text = "×%d" % recipe.get("result_qty", 1)
	res_lbl.add_theme_font_size_override("font_size", 10)
	res_lbl.add_theme_color_override("font_color", C_TEXT_GOLD)
	res_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result_display.add_child(res_lbl)

	# -- Bouton CRÉER --
	var can = _can_craft(recipe)
	create_btn.disabled = not can
	_style_create_btn(create_btn, can)

func _clear_detail_panel() -> void:
	for child in ingredient_area.get_children():
		child.queue_free()
	for child in result_display.get_children():
		child.queue_free()
	create_btn.disabled = true
	_style_create_btn(create_btn, false)
	feedback_label.text = ""


# ============================================================
#  LOGIQUE DE CRAFT
# ============================================================

func _can_craft(recipe: Dictionary) -> bool:
	for item_name in recipe["ingredients"]:
		if not Inventory.has_item(item_name, recipe["ingredients"][item_name]):
			return false
	return true

func _on_create_pressed() -> void:
	if selected_recipe_index < 0:
		return
	var recipe: Dictionary = RECIPES[current_tab][selected_recipe_index]
	if not _can_craft(recipe):
		_show_feedback("Ressources\ninsuffisantes !", C_TEXT_RED)
		return

	# Consomme les ingrédients
	for item_name in recipe["ingredients"]:
		Inventory.remove_item(item_name, recipe["ingredients"][item_name])

	# Ajoute le résultat
	Inventory.add_item(recipe["result"], recipe.get("result_qty", 1))

	_show_feedback("%s\nfabriqué !" % recipe["result"], C_TEXT_GREEN)

	# Rafraîchit la liste (une recette peut devenir grisée)
	_refresh_recipe_list()
	if selected_recipe_index >= 0 and selected_recipe_index < RECIPES[current_tab].size():
		_update_right_panel()


# ============================================================
#  ONGLETS
# ============================================================

func _on_tab_pressed(tab_id: String) -> void:
	if current_tab == tab_id:
		return
	current_tab = tab_id
	_update_bg_texture()
	_refresh_recipe_list()


# ============================================================
#  AFFICHER / CACHER
# ============================================================

func show_panel() -> void:
	root_control.visible = true
	panel_visible = true
	_refresh_recipe_list()   # recharge (les quantités peuvent avoir changé)

func hide_panel() -> void:
	root_control.visible = false
	panel_visible = false

func toggle() -> void:
	if panel_visible:
		hide_panel()
	else:
		show_panel()


# ============================================================
#  UTILITAIRES
# ============================================================

func _show_feedback(msg: String, color: Color) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override("font_color", color)
	get_tree().create_timer(2.5).timeout.connect(
		func(): if is_instance_valid(feedback_label): feedback_label.text = ""
	)

# ── Styles des boutons ──────────────────────────────────────

func _transparent_stylebox() -> StyleBoxFlat:
	var st = StyleBoxFlat.new()
	st.bg_color    = Color(0, 0, 0, 0)
	st.draw_center = false
	return st

func _hover_stylebox() -> StyleBoxFlat:
	var st = StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.18)
	return st

func _make_invisible_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Button:
	var btn = Button.new()
	btn.flat       = true
	btn.position   = pos
	btn.size       = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal",   _transparent_stylebox())
	btn.add_theme_stylebox_override("hover",    _hover_stylebox())
	btn.add_theme_stylebox_override("pressed",  _transparent_stylebox())
	btn.add_theme_stylebox_override("focus",    _transparent_stylebox())
	btn.add_theme_stylebox_override("disabled", _transparent_stylebox())
	btn.pressed.connect(callback)
	return btn

func _style_create_btn(btn: Button, active: bool) -> void:
	# Le bouton CRÉER est transparent : le sprite montre déjà "CREATE".
	# Hover = léger voile vert pour indiquer l'interactivité.
	var normal_st = StyleBoxFlat.new()
	normal_st.bg_color    = Color(0, 0, 0, 0)
	normal_st.draw_center = false

	var hover_st = StyleBoxFlat.new()
	hover_st.bg_color = Color(0.2, 1.0, 0.2, 0.25) if active else Color(0, 0, 0, 0)

	var disabled_st = StyleBoxFlat.new()
	disabled_st.bg_color = Color(0, 0, 0, 0.35)   # assombrit le bouton quand inactif

	btn.add_theme_stylebox_override("normal",   normal_st)
	btn.add_theme_stylebox_override("hover",    hover_st)
	btn.add_theme_stylebox_override("pressed",  hover_st)
	btn.add_theme_stylebox_override("disabled", disabled_st)
	btn.add_theme_stylebox_override("focus",    normal_st)

# ── Cases de recettes ───────────────────────────────────────

func _make_recipe_slot(recipe_index: int) -> Control:
	var recipe: Dictionary = RECIPES[current_tab][recipe_index]
	var can_craft = _can_craft(recipe)

	# Conteneur principal 48×48 px
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(16, 16) * S   # 48×48 à l'écran

	# Fond coloré (fond normal = sombre, sélectionné = légèrement plus clair)
	var bg = ColorRect.new()
	bg.color = Color("#1a1a2e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(bg)

	# Bordure via Panel + StyleBoxFlat
	var border = Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var border_st = StyleBoxFlat.new()
	border_st.bg_color    = Color(0, 0, 0, 0)
	border_st.draw_center = false
	border_st.border_color = Color("#5a5a7a") if not can_craft else Color("#8888aa")
	border_st.set_border_width_all(1)
	border.add_theme_stylebox_override("panel", border_st)
	slot.add_child(border)

	# Icône de l'objet résultant
	var icon = TextureRect.new()
	icon.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.modulate       = Color(1, 1, 1, 1) if can_craft else Color(0.5, 0.5, 0.5, 1)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tex = _get_item_texture(recipe["result"])
	if tex:
		icon.texture = tex
	slot.add_child(icon)

	# Bouton invisible de détection de clic (au-dessus de tout)
	var btn = Button.new()
	btn.flat       = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal",   _transparent_stylebox())
	btn.add_theme_stylebox_override("hover",    _hover_stylebox())
	btn.add_theme_stylebox_override("pressed",  _transparent_stylebox())
	btn.add_theme_stylebox_override("focus",    _transparent_stylebox())
	btn.pressed.connect(_on_recipe_selected.bind(recipe_index))
	slot.add_child(btn)

	return slot

func _set_slot_selected(slot: Control, selected: bool) -> void:
	# Premier enfant = ColorRect de fond
	if slot.get_child_count() > 0:
		var bg = slot.get_child(0)
		if bg is ColorRect:
			bg.color = Color("#3a3a5e") if selected else Color("#1a1a2e")
	# Deuxième enfant = Panel bordure
	if slot.get_child_count() > 1:
		var border = slot.get_child(1)
		if border is Panel:
			var st = StyleBoxFlat.new()
			st.bg_color    = Color(0, 0, 0, 0)
			st.draw_center = false
			st.border_color = Color("#FFD700") if selected else Color("#8888aa")
			st.set_border_width_all(2 if selected else 1)
			border.add_theme_stylebox_override("panel", st)

# ── Texture d'un item ───────────────────────────────────────

func _get_item_texture(item_name: String) -> Texture2D:
	# 1. Image PNG dédiée (bois, minerai…)
	if ITEM_IMAGES.has(item_name):
		var path = ITEM_IMAGES[item_name]
		if ResourceLoader.exists(path):
			return load(path)
	# 2. Région dans rpgItems.png
	if ITEM_REGIONS.has(item_name):
		if ResourceLoader.exists(ITEMS_TEX):
			var atlas = AtlasTexture.new()
			atlas.atlas  = load(ITEMS_TEX)
			atlas.region = ITEM_REGIONS[item_name]
			return atlas
	return null
