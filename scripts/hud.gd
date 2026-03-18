extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var panneau = $PanneauInventaire
@onready var grid = $PanneauInventaire/VBoxContainer/GridContainer
@onready var label_or = $PanneauInventaire/VBoxContainer/LabelOr
@onready var label_outil = $PanneauInventaire/VBoxContainer/LabelOutil

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

func _ready():
	
	var player = get_tree().get_first_node_in_group("player")
	player.health_changed.connect(_on_health_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	panneau.visible = false
	# Empêche les boutons de capturer le focus clavier
	$BtnInventaire.focus_mode = Control.FOCUS_NONE

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel") and panneau.visible:
		panneau.visible = false

func _on_health_changed(new_health):
	health_bar.value = new_health

func _on_inventory_changed():
	_refresh_inventaire()

func _on_btn_inventaire_pressed():
	panneau.visible = !panneau.visible
	inventaire_ouvert = panneau.visible	
	if panneau.visible:
		_refresh_inventaire()
		$BtnInventaire.release_focus()

func _on_btn_fermer_pressed():
	panneau.visible = false
	$BtnFermer.release_focus()

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
	if item_name == "Potion":
		var player = get_tree().get_first_node_in_group("player")
		if Inventory.remove_item(item_name, 1):
			player.heal(30)
	elif item_name == "Hache":
		Inventory.equip_tool("hache")
		_refresh_inventaire()
	elif item_name == "Pioche":
		Inventory.equip_tool("pioche")
		_refresh_inventaire()

func get_item_texture(item_name: String) -> Texture2D:
	if item_images.has(item_name):
		return load(item_images[item_name])
	if item_regions.has(item_name):
		var atlas = AtlasTexture.new()
		atlas.atlas = load(item_spritesheets[item_name])
		atlas.region = item_regions[item_name]
		return atlas
	return null
