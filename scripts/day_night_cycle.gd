# day_night_cycle.gd
extends CanvasLayer

# Durée d'un cycle complet en secondes (1200 = 20 min réelles)
@export var day_duration: float = 1200.0
# Heure de départ (0.0 = minuit, 0.25 = 6h, 0.5 = midi, 0.75 = 18h)
@export var start_time: float = 0.25

var overlay: ColorRect
var sun_label: Label
# Temps actuel normalisé entre 0.0 et 1.0
var current_time: float = start_time

# Palette de couleurs selon l'heure
# Chaque entrée : [heure normalisée, Color de l'overlay]
const TIME_COLORS = [
	[0.00, Color(0.0, 0.02, 0.1, 0.55)], # Minuit — nuit (encore jouable)
	[0.20, Color(0.0, 0.02, 0.1, 0.55)], # 4h30  — encore nuit
	[0.25, Color(0.05, 0.05, 0.2, 0.35)],# 6h    — aube
	[0.30, Color(0.1,  0.05, 0.0, 0.15)],# 7h12  — lever de soleil
	[0.38, Color(0.0,  0.0,  0.0, 0.0)], # 9h    — plein jour
	[0.62, Color(0.0,  0.0,  0.0, 0.0)], # 15h   — plein jour
	[0.70, Color(0.15, 0.05, 0.0, 0.15)],# 16h48 — coucher de soleil
	[0.75, Color(0.1,  0.02, 0.05, 0.35)],# 18h  — crépuscule
	[0.80, Color(0.0,  0.02, 0.1, 0.55)],# 19h12 — nuit tombée
	[1.00, Color(0.0,  0.02, 0.1, 0.55)],# boucle
]

signal time_of_day_changed(period: String)# "day", "night", "dawn", "dusk"
var _last_period: String = ""

func _ready():
	# Créer l'overlay
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color.TRANSPARENT
	add_child(overlay)

# Créer le label d'heure (optionnel)
	sun_label = Label.new()
	sun_label.name = "SunLabel"
	sun_label.position = Vector2(180, 10)
	add_child(sun_label)

# Restaurer l'heure sauvegardée
	if GameManager.time_of_day > 0.0:
		current_time = GameManager.time_of_day
	else:
		current_time = start_time
	_apply_color()

func _process(delta: float):
	current_time = fmod(current_time + delta / day_duration, 1.0)
	_apply_color()
	_update_label()
	_check_period()

func _apply_color():
	# Interpolation entre les deux couleurs clés encadrant l'heure actuelle
	for i in range(TIME_COLORS.size() - 1):
		var t0 = TIME_COLORS[i][0]
		var t1 = TIME_COLORS[i + 1][0]
		if current_time >= t0 and current_time < t1:
			var progress = (current_time - t0) / (t1 - t0)
			overlay.color = TIME_COLORS[i][1].lerp(TIME_COLORS[i + 1][1], progress)
			return

func _update_label():
	if not is_instance_valid(sun_label):
		return
# Convertit le temps normalisé en heure lisible
	var total_minutes = int(current_time * 24 * 60)
	@warning_ignore("integer_division")
	var hours = total_minutes / 60
	var minutes = total_minutes % 60
	sun_label.text = "%02d:%02d" % [hours, minutes]

func _check_period():
	var period = get_period()
	if period != _last_period:
		_last_period = period
		time_of_day_changed.emit(period)

func get_period() -> String:
	if current_time >= 0.38 and current_time < 0.70:
		return "day"
	elif current_time >= 0.25 and current_time < 0.38:
		return "dawn"
	elif current_time >= 0.70 and current_time < 0.80:
		return "dusk"
	else:
		return "night"

func is_night() -> bool:
	return get_period() == "night"

# --- Sauvegarde ---
func get_time() -> float:
	return current_time

func set_time(t: float) -> void:
	current_time = t
	_apply_color()
	
