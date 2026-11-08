class_name OptionsPanel
extends Control
## Options : volume, sensibilité de la souris, plein écran. Utilisé par le menu et la pause.

signal closed

var _volume: HSlider
var _sensi: HSlider
var _fullscreen: CheckButton


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.menu_bg())
	var vb := VBoxContainer.new()
	UiTheme.centered(vb, Vector2(560, 400))
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	vb.add_child(UiTheme.label("OPTIONS", 26, UiTheme.ACCENT))
	vb.add_child(HSeparator.new())

	vb.add_child(UiTheme.label("Volume", 18))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.01
	_volume.value_changed.connect(_on_volume)
	vb.add_child(_volume)

	vb.add_child(UiTheme.label("Sensibilité de la souris", 18))
	_sensi = HSlider.new()
	_sensi.min_value = 0.0005
	_sensi.max_value = 0.006
	_sensi.step = 0.0001
	_sensi.value_changed.connect(_on_sensitivity)
	vb.add_child(_sensi)

	_fullscreen = CheckButton.new()
	_fullscreen.text = "Plein écran"
	_fullscreen.toggled.connect(_on_fullscreen)
	vb.add_child(_fullscreen)

	var back := UiTheme.button("Retour", 200)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(close)
	vb.add_child(back)


func open() -> void:
	_volume.set_value_no_signal(Settings.volume)
	_sensi.set_value_no_signal(Settings.mouse_sensitivity)
	_fullscreen.set_pressed_no_signal(Settings.fullscreen)
	show()


func close() -> void:
	if not visible:
		return
	Settings.save()
	hide()
	closed.emit()


func _on_volume(v: float) -> void:
	Settings.volume = v
	Settings.apply()


func _on_sensitivity(v: float) -> void:
	Settings.mouse_sensitivity = v


func _on_fullscreen(on: bool) -> void:
	Settings.fullscreen = on
	Settings.apply()
