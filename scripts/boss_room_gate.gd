extends StaticBody2D

# ─────────────────────────────────────────────────────────────────────────────
#  BossRoomGate — barrière qui bloque l'entrée d'une salle de boss
#
#  Comportement :
#    • Bloque le passage tant que le boss est vivant.
#    • Dès que le signal boss_died est émis, la barrière disparaît en fondu.
#
#  Structure dans la scène (identique à un mur TileMap ennemi) :
#    StaticBody2D  (script: boss_room_gate.gd)
#      CollisionShape2D
#      Sprite2D ou AnimatedSprite2D  (optionnel — visuel de la barrière)
#
#  Exports à configurer dans l'inspecteur :
#    • boss_node_path : NodePath vers le nœud du boss (Enemy avec is_boss = true)
#    • fade_duration  : durée du fondu de disparition (secondes)
# ─────────────────────────────────────────────────────────────────────────────

## Chemin vers le nœud boss dans la scène. Le script se connecte au signal boss_died.
@export var boss_node_path: NodePath = NodePath("")
## Durée du fondu de sortie quand la barrière disparaît (secondes).
@export var fade_duration: float = 0.8
## Activer pour afficher les logs de debug dans la console.
@export var debug_mode: bool = false

var _collision: CollisionShape2D = null

func _ready() -> void:
	# Récupérer la forme de collision (premier enfant du type CollisionShape2D)
	for child in get_children():
		if child is CollisionShape2D:
			_collision = child
			break

	# Connexion au signal boss_died
	if boss_node_path == NodePath(""):
		push_warning("BossRoomGate : boss_node_path non défini, la barrière ne s'ouvrira jamais.")
		return

	var boss = get_node_or_null(boss_node_path)
	if not boss:
		push_warning("BossRoomGate : impossible de trouver le boss au chemin '%s'." % str(boss_node_path))
		return

	if boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)
		if debug_mode:
			print("[BossRoomGate] Connecté au signal boss_died de ", boss.name)
	else:
		push_warning("BossRoomGate : le nœud boss n'a pas de signal 'boss_died'.")

# ─── Ouverture de la barrière ─────────────────────────────────────────────────
func _on_boss_died() -> void:
	if debug_mode:
		print("[BossRoomGate] Boss mort — ouverture de la barrière...")

	# Désactiver la collision immédiatement (le joueur peut passer)
	if _collision:
		_collision.set_deferred("disabled", true)

	# Fondu vers transparent puis suppression du nœud
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()
