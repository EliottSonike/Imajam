extends Node

const PATH := "user://settings.cfg"

var volume := 0.8
var mouse_sensitivity := 0.0025
var fullscreen := true  # le jeu s'ouvre en plein écran (désactivable dans Options)


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		volume = cfg.get_value("audio", "volume", volume)
		mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
		# nouvelle clé : les anciennes sauvegardes (fenêtré par défaut) ne bloquent plus le plein écran
		fullscreen = cfg.get_value("video", "plein_ecran", fullscreen)
	apply()


func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "plein_ecran", fullscreen)
	cfg.save(PATH)
