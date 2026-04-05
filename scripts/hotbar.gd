extends Control
# ============================================================
#  Hotbar — barre de raccourcis consommables
#
#  4 slots affichés en COLONNE VERTICALE sur le bord gauche
#  de l'écran, au-dessus des boutons HUD — hors de la zone
#  couverte par la boîte de dialogue PNJ.
#
#  • Clic gauche / Touches 1–4 : utiliser l'item du slot
#  • Clic droit sur un slot : assigner un consommable au slot
#    (cycle à travers les consommables disponibles en inventaire)
#
#  Consommables supportés : Potion, Grande potion, Potion de mana,
#  Potion de force, Viande, Champignon, Baie
# ============================================================

const SLOT_COUNT = 4
const SLOT_SIZE  = 52
const SLOT_GAP   = 6

const CONSUMABLES = [
	"Potion", "Grande potion", "Potion de mana",
	"Potion de force", "Viande", "Champignon", "Baie",
]

const HEAL_VALUES = {
	"Potion":          {"hp": 30, "mana": 0},
	"Grande potion":   {"hp": 60, "mana": 0},
	"Potion de mana":  {"hp": 0,  "mana": 40},
	"Potion de force": {"hp": 20, "mana": 20},
	"Viande":          {"hp": 15, "mana": 0},
	"Champignon":      {"hp": 8,  "mana": 0},
	"Baie":            {"hp": 5,  "mana": 0},
}

# ─── Données des slots ─────────────────────────────────────
# Chaque entrée : { "item": String, "icon": TextureRect, "qty_lbl": Label, "style": StyleBoxFlat }
var _slots: Array = []

# ============================================================
func _ready() -> void:
	_build_ui()
	_refresh()
	Inventory.inventory_changed.connect(_refresh)

# ============================================================
#  CONSTRUCTION UI
# ============================================================

func _build_ui() -> void:
	# Colonne verticale : largeur = 1 slot, hauteur = 4 slots + gaps
	var total_h = SLOT_COUNT * (SLOT_SIZE + SLOT_GAP) - SLOT_GAP
	var total_w = SLOT_SIZE

	# Coordonnées absolues alignées sur BtnInventaire (offset_left=1090, offset_top=585)
	# Même système que les boutons HUD — indépendant de la résolution d'écran
	set_anchor(SIDE_LEFT,   0.0)
	set_anchor(SIDE_RIGHT,  0.0)
	set_anchor(SIDE_TOP,    0.0)
	set_anchor(SIDE_BOTTOM, 0.0)
	offset_left   = 1093                  # centré sur BtnInventaire (1090 + (59-52)/2)
	offset_right  = 1093 + total_w        # = 1145
	offset_bottom = 575                   # 10 px au-dessus du bouton (top=585)
	offset_top    = 575 - total_h         # = 349 pour 4 slots

	for i in range(SLOT_COUNT):
		var y = i * (SLOT_SIZE + SLOT_GAP)
		_build_slot(i, y)

func _build_slot(idx: int, y: float) -> void:
	# ── Fond du slot ──────────────────────────────────────
	var slot_panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.88)
	style.border_color = Color(0.45, 0.38, 0.18, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	slot_panel.add_theme_stylebox_override("panel", style)
	slot_panel.position = Vector2(0, y)
	slot_panel.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	add_child(slot_panel)

	# ── Numéro de touche (coin haut-gauche du slot) ───────
	var key_lbl = Label.new()
	key_lbl.text = str(idx + 1)
	key_lbl.position = Vector2(2, 1)
	key_lbl.size = Vector2(12, 14)
	key_lbl.add_theme_font_size_override("font_size", 9)
	key_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55, 0.9))
	key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(key_lbl)

	# ── Icône item ────────────────────────────────────────
	var icon = TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(4, 4)
	icon.size     = Vector2(SLOT_SIZE - 8, SLOT_SIZE - 8)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(icon)

	# ── Quantité (bas-droite) ─────────────────────────────
	var qty_lbl = Label.new()
	qty_lbl.text = ""
	qty_lbl.add_theme_font_size_override("font_size", 9)
	qty_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_lbl.position = Vector2(2, SLOT_SIZE - 13)
	qty_lbl.size     = Vector2(SLOT_SIZE - 4, 12)
	qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_panel.add_child(qty_lbl)

	# ── Zone de clic ──────────────────────────────────────
	var btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.position = Vector2.ZERO
	btn.size     = Vector2(SLOT_SIZE, SLOT_SIZE)
	btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(func(): _on_slot_used(idx))
	btn.gui_input.connect(func(ev): _on_slot_gui_input(ev, idx))
	slot_panel.add_child(btn)

	_slots.append({"item": "", "icon": icon, "qty_lbl": qty_lbl, "style": style})

# ============================================================
#  RAFRAÎCHISSEMENT
# ============================================================

func _refresh() -> void:
	for i in range(_slots.size()):
		var s = _slots[i]
		var item_name: String = s["item"]
		var qty: int = Inventory.items.get(item_name, 0) if item_name != "" else 0

		# Si le slot était assigné mais l'item est épuisé, on le vide
		if item_name != "" and qty == 0:
			s["item"] = ""
			item_name = ""

		if item_name == "":
			s["icon"].texture = null
			s["qty_lbl"].text = ""
			_set_slot_border(i, false)
		else:
			s["icon"].texture = ItemData.get_texture(item_name)
			s["qty_lbl"].text = "×%d" % qty if qty > 1 else ""
			_set_slot_border(i, true)

func _set_slot_border(idx: int, filled: bool) -> void:
	var style: StyleBoxFlat = _slots[idx]["style"]
	style.border_color = Color(0.75, 0.62, 0.28, 1.0) if filled else Color(0.45, 0.38, 0.18, 0.75)

# ============================================================
#  INTERACTIONS
# ============================================================

## Appelé par clic gauche sur le slot, ou depuis _input de HUD (touche 1–4).
func use_slot(idx: int) -> void:
	_on_slot_used(idx)

func _on_slot_used(idx: int) -> void:
	if idx < 0 or idx >= _slots.size():
		return
	var item_name: String = _slots[idx]["item"]
	if item_name == "":
		return
	_use_item(item_name)

func _on_slot_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		_cycle_assign(idx)
		get_viewport().set_input_as_handled()

## Clic droit : assigner l'item suivant disponible dans l'inventaire.
func _cycle_assign(idx: int) -> void:
	# Construire la liste des consommables disponibles en inventaire
	var available: Array = []
	for name in CONSUMABLES:
		if Inventory.items.get(name, 0) > 0:
			available.append(name)
	if available.is_empty():
		return

	var current: String = _slots[idx]["item"]
	var pos = available.find(current)

	if pos == -1 or pos >= available.size() - 1:
		# Slot vide ou dernier → premier disponible ; si déjà le premier et seul → vider
		_slots[idx]["item"] = available[0] if pos == -1 else ""
	else:
		_slots[idx]["item"] = available[pos + 1]

	_refresh()

# ============================================================
#  UTILISATION D'UN ITEM CONSOMMABLE
# ============================================================

func _use_item(item_name: String) -> void:
	if not HEAL_VALUES.has(item_name):
		return
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	if not Inventory.remove_item(item_name, 1):
		return

	var vals: Dictionary = HEAL_VALUES[item_name]
	if vals["hp"] > 0:
		player.heal(vals["hp"])
	if vals["mana"] > 0:
		Stats.restore_mana(vals["mana"])
	_refresh()
