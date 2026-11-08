class_name PauseMenu
extends Control
## Menu pause (Échap) : Reprendre, Options, Menu principal, Quitter.

const MENU_SCENE := "res://scenes/menu.tscn"

var _box: Control
var _options: OptionsPanel


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiTheme.menu_bg())

	_box = PanelContainer.new()
	UiTheme.centered(_box, Vector2(420, 420))
	add_child(_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_box.add_child(vb)
	vb.add_child(UiTheme.header("Pause", "PS-00", 34, UiTheme.DANGER))
	vb.add_child(UiTheme.mono("RONDE INTERROMPUE", 12))
	vb.add_child(HSeparator.new())
	var resume := UiTheme.button("Reprendre")
	resume.pressed.connect(close)
	vb.add_child(resume)
	var options := UiTheme.button("Options")
	options.pressed.connect(_open_options)
	vb.add_child(options)
	var menu := UiTheme.button("Menu principal")
	menu.pressed.connect(_on_menu)
	vb.add_child(menu)
	var quit := UiTheme.button("Quitter le jeu")
	quit.pressed.connect(func() -> void: get_tree().quit())
	vb.add_child(quit)

	_options = OptionsPanel.new()
	_options.closed.connect(func() -> void: _box.show())
	add_child(_options)


func open() -> void:
	show()
	_box.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p and not p.is_locked():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Events.ui_modal_changed.emit(false)


func handle_back() -> void:
	if _options.visible:
		_options.close()
	else:
		close()


func _open_options() -> void:
	_box.hide()
	_options.open()


func _on_menu() -> void:
	get_tree().paused = false
	Sfx.stop_all_loops()
	get_tree().change_scene_to_file(MENU_SCENE)
