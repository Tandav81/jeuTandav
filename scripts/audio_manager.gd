extends Node

# ─────────────────────────────────────────────────────────────────────────────
#  AudioManager — Autoload
#
#  Gère la musique d'ambiance avec fondus enchaînés entre les scènes.
#
#  Usage :
#    AudioManager.play_ambient(preload("res://assets/music/donjon.ogg"))
#    AudioManager.stop_ambient()
#
#  Enregistrer dans Project → Project Settings → Autoload :
#    Nom : AudioManager
#    Chemin : res://scripts/audio_manager.gd
# ─────────────────────────────────────────────────────────────────────────────

## Durée par défaut des fondus (secondes)
const FADE_DURATION: float = 1.2
## Volume de la musique d'ambiance (dB)
const AMBIENT_VOLUME_DB: float = -10.0

var _player_a: AudioStreamPlayer = null
var _player_b: AudioStreamPlayer = null
var _active: AudioStreamPlayer   = null   # le player actuellement en train de jouer

func _ready() -> void:
	_player_a = _make_player("AmbientA")
	_player_b = _make_player("AmbientB")
	_active   = _player_a

func _make_player(node_name: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.name        = node_name
	p.bus         = "Music"   # Bus "Music" recommandé ; fonctionne aussi sur "Master"
	p.volume_db   = AMBIENT_VOLUME_DB
	p.autoplay    = false
	add_child(p)
	return p

# ─── API publique ─────────────────────────────────────────────────────────────

## Joue un nouveau stream en fondu enchaîné.
## Si le même stream est déjà en cours, ne fait rien.
func play_ambient(stream: AudioStream, fade_duration: float = FADE_DURATION) -> void:
	if not stream:
		return
	# Éviter de relancer le même morceau si déjà en cours
	if is_instance_valid(_active) and _active.stream == stream and _active.playing:
		return

	var incoming = _player_b if _active == _player_a else _player_a
	var outgoing = _active

	incoming.stream   = stream
	incoming.volume_db = AMBIENT_VOLUME_DB - 80.0   # commence silencieux
	incoming.play()

	# Fondu croisé
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", AMBIENT_VOLUME_DB,   fade_duration)
	tween.tween_property(outgoing, "volume_db", AMBIENT_VOLUME_DB - 80.0, fade_duration)
	await tween.finished

	outgoing.stop()
	outgoing.volume_db = AMBIENT_VOLUME_DB   # réinitialiser pour la prochaine utilisation
	_active = incoming

## Arrête la musique en fondu.
func stop_ambient(fade_duration: float = FADE_DURATION) -> void:
	if not is_instance_valid(_active) or not _active.playing:
		return
	var tween = create_tween()
	tween.tween_property(_active, "volume_db", AMBIENT_VOLUME_DB - 80.0, fade_duration)
	await tween.finished
	_active.stop()
	_active.volume_db = AMBIENT_VOLUME_DB

## Vérifie si de la musique est en cours
func is_playing() -> bool:
	return is_instance_valid(_active) and _active.playing
