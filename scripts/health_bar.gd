extends TextureProgressBar

var player = get_tree().get_first_node_in_group("player")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.healthChanged.connect(update)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update():
	value = player.currentHealth * 100 / player.maxHealth
