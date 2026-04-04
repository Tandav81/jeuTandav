extends Node2D

# ============================================================
#  PROJECTILE — Arc ou Magie
#
#  Créé dynamiquement par player.gd via _lancer_projectile().
#  Se déplace en ligne droite, détruit à max_range ou au contact
#  d'un ennemi.
#  Talent "piercing_arrows" : les flèches traversent les ennemis.
# ============================================================

## "arc" ou "magie"
var proj_type:        String  = "arc"
var direction:        Vector2 = Vector2.DOWN
var speed:            float   = 320.0
var max_range:        float   = 150.0
var damage:           int     = 10

var distance_traveled: float  = 0.0
var _visual:          ColorRect
var _hit_bodies:      Array   = []   # ennemis déjà touchés (flèches perçantes)

func _ready() -> void:
	_build_visual()

func _build_visual() -> void:
	_visual = ColorRect.new()
	if proj_type == "arc":
		# Flèche : rectangle allongé orange-brun
		_visual.color = Color("#c87820")
		_visual.size  = Vector2(10, 3)
	else:
		# Sort magique : carré bleu lumineux
		_visual.color = Color("#4a80ff")
		_visual.size  = Vector2(7, 7)
	_visual.position = -_visual.size / 2.0
	add_child(_visual)
	# Oriente le visuel dans la direction de tir
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var step = direction * speed * delta
	position  += step
	distance_traveled += step.length()

	if distance_traveled >= max_range:
		queue_free()
		return

	_check_hit()

func _check_hit() -> void:
	# Requête de forme circulaire pour détecter les ennemis
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 5.0
	query.shape     = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFFFFFF   # tous les layers

	# Talent flèches perçantes : uniquement pour les flèches (pas la magie)
	var piercing: bool = proj_type == "arc" and Stats.has_talent("piercing_arrows")

	for result in space.intersect_shape(query, 8):
		var body = result["collider"]
		if body.is_in_group("enemy") and not _hit_bodies.has(body):
			body.take_damage(damage)
			_spawn_impact()
			if piercing:
				# Mémoriser pour ne pas toucher deux fois le même ennemi
				_hit_bodies.append(body)
				# Continuer — ne pas détruire le projectile
			else:
				queue_free()
				return

func _spawn_impact() -> void:
	# Petit flash visuel à l'impact
	var flash = ColorRect.new()
	flash.color = Color("#ffff80", 0.85) if proj_type == "arc" else Color("#aaaaff", 0.85)
	flash.size  = Vector2(10, 10)
	flash.position = global_position - flash.size / 2.0
	get_tree().current_scene.add_child(flash)
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)
