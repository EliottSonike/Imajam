class_name OptionsPanel
extends Control
## Options : volume, sensibilité de la souris, plein écran.

signal closed

var _volume: HSlider
var _sensi: HSlider
var _fullscreen: CheckButton


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.menu_bg())
	var panel := PanelContainer.new()
	UiTheme.centered(panel, Vector2(620, 480))
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)
	vb.add_child(UiTheme.header("Réglages", "FORM. RG-01"))
	vb.add_child(HSeparator.new())

	vb.add_child(UiTheme.mono("VOLUME", 14, UiTheme.AMBER))
	_volume = HSlider.new()
	_volume.min_value = 0.0
	_volume.max_value = 1.0
	_volume.step = 0.01
	_volume.value_changed.connect(_on_volume)
	vb.add_child(_volume)

	vb.add_child(UiTheme.mono("SENSIBILITÉ DE LA SOURIS", 14, UiTheme.AMBER))
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
