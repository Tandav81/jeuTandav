extends Node

# ─────────────────────────────────────────────────────────────────────────────
#  DungeonCinematic — nœud à placer dans world.tscn
#
#  Déclenche automatiquement une cinématique (pan + zoom de la caméra)
#  vers le portail verrouillé associé, quand le joueur revient dans world.tscn
#  après avoir tué le boss dont le cinematic_key correspond à watched_key.
#
#  Supporte plusieurs boss / donjons : placer autant de DungeonCinematic que
#  de boss, chacun avec son propre watched_key pointant vers son LockedPortal.
#
#  Le LockedPortal cible est trouvé parmi les nœuds du groupe "locked_portal"
#  dont le required_key correspond à watched_key.
#
#  Exports (inspecteur) :
#    • watched_key     → nom de la clé boss qui déclenche CETTE cinématique
#    • cinematic_zoom  → niveau de zoom à l'arrivée (défaut 2.0)
#    • pan_duration    → durée du déplacement vers la cible (défaut 1.5s)
#    • hold_duration   → temps de pause sur la cible (défaut 2.0s)
#    • return_duration → durée du retour au joueur (défaut 1.2s)
#    • debug_mode      → logs console (défaut false)
# ─────────────────────────────────────────────────────────────────────────────

## Nom de la clé boss que cette cinématique surveille (ex: "Clé du donjon").
## Doit correspondre au cinematic_key du boss ET au required_key du LockedPortal.
@export var watched_key:       String = ""
@export var cinematic_zoom:    float  = 2.0
@export var pan_duration:      float  = 1.5
@export var hold_duration:     float  = 2.0
@export var return_duration:   float  = 1.2
## Activer pour afficher les logs de debug dans la console Godot
@export var debug_mode:        bool   = false

var _locked_portal: Node = null

func _ready() -> void:
	add_to_group("dungeon_cinematic")
	# Laisser la scène se charger entièrement avant d'agir
	await get_tree().process_frame

	# ── Chercher le LockedPortal dont le required_key correspond à watched_key ──
	if watched_key != "":
		for p in get_tree().get_nodes_in_group("locked_portal"):
			if p.get("required_key") == watched_key:
				_locked_portal = p
				break
	if is_instance_valid(_locked_portal):
		if debug_mode: print("[DungeonCinematic] LockedPortal trouvé : ", _locked_portal.name)
	else:
		if debug_mode: print("[DungeonCinematic] ⚠ Aucun LockedPortal avec required_key='", watched_key, "' — cinématique sans flash.")

	# ── Vérifier si notre clé est en attente ─────────────────────────────────
	if debug_mode: print("[DungeonCinematic] pending_cinematics = ", GameManager.pending_cinematics)

	if watched_key != "" and GameManager.pending_cinematics.has(watched_key):
		GameManager.pending_cinematics.erase(watched_key)
		# Attendre la fin du fondu de SceneTransition (environ 0.75s)
		await get_tree().create_timer(0.9).timeout
		play_cinematic()
	else:
		if debug_mode: print("[DungeonCinematic] Pas de cinématique à déclencher pour '", watched_key, "'.")

# ─── Cinématique publique ─────────────────────────────────────────────────────
## Peut être appelée manuellement depuis la console Godot pour tester :
##   get_tree().get_first_node_in_group("dungeon_cinematic").play_cinematic()
func play_cinematic() -> void:
	if debug_mode: print("[DungeonCinematic] ▶ Démarrage de la cinématique...")

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("[DungeonCinematic] Joueur introuvable (groupe 'player' manquant ?).")
		return

	var cam: Camera2D = _find_camera(player)
	if not cam:
		push_error("[DungeonCinematic] Camera2D introuvable sous le joueur.")
		return

	# ── Sauvegarder l'état caméra ─────────────────────────────────────────────
	var original_zoom:   Vector2 = cam.zoom
	var original_offset: Vector2 = cam.offset
	var smooth_was_on:   bool    = cam.position_smoothing_enabled

	cam.position_smoothing_enabled = false
	player.in_dialogue = true   # bloquer le mouvement (même mécanisme que PNJ)

	# ── Notification HUD ──────────────────────────────────────────────────────
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("✨  Une entrée secrète vient de s'ouvrir !", Color.GOLD)

	# ── Calculer la cible du pan ──────────────────────────────────────────────
	# Si le portail est connu : on y va. Sinon : zoom sur place (effet "révélation")
	var target_offset: Vector2
	if is_instance_valid(_locked_portal):
		target_offset = _locked_portal.global_position - player.global_position
		if debug_mode: print("[DungeonCinematic] Pan vers ", _locked_portal.global_position, " | offset = ", target_offset)
	else:
		target_offset = Vector2.ZERO   # zoom sur le joueur si pas de portail
		if debug_mode: print("[DungeonCinematic] Pas de portail — zoom sur place.")

	# ── Tween principal ───────────────────────────────────────────────────────
	var tween = create_tween()

	# Phase 1 — Pan + zoom vers la cible
	tween.tween_property(cam, "offset", target_offset, pan_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cam, "zoom",
		Vector2(cinematic_zoom, cinematic_zoom), pan_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Phase 2 — Flash + ouverture du portail (si disponible)
	tween.tween_callback(_flash_and_open_portal)
	tween.tween_interval(hold_duration)

	# Phase 3 — Retour au joueur
	tween.tween_property(cam, "offset", original_offset, return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cam, "zoom", original_zoom, return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# ── Restaurer ─────────────────────────────────────────────────────────────
	cam.position_smoothing_enabled = smooth_was_on
	player.in_dialogue = false
	if debug_mode: print("[DungeonCinematic] ✓ Cinématique terminée.")

# ─── Flash + ouverture du portail ────────────────────────────────────────────
func _flash_and_open_portal() -> void:
	if not is_instance_valid(_locked_portal):
		return
	if _locked_portal.has_method("open_portal"):
		_locked_portal.open_portal()
	# Flash doré → retour normal
	_locked_portal.modulate = Color(2.0, 2.0, 0.5, 1.0)
	var flash = create_tween()
	flash.tween_property(_locked_portal, "modulate", Color.WHITE, 0.7) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

# ─── Cherche la Camera2D dans les enfants du joueur (récursif) ───────────────
func _find_camera(player: Node) -> Camera2D:
	return player.find_child("Camera2D", true, false) as Camera2D
