class_name MainMenu
extends Control
## Menu principal : Jouer, Options, Quitter, sur un fond uni.

const GAME_SCENE := "res://scenes/main.tscn"

var _box: VBoxContainer
var _options: OptionsPanel
var _fade: ColorRect


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_all_loops()
	Sfx.loop("ambient", -18.0)
	UiTheme.full_rect(self)
	theme = UiTheme.get_theme()

	add_child(UiTheme.menu_bg())

	_box = VBoxContainer.new()
	UiTheme.centered(_box, Vector2(360, 320))
	_box.add_theme_constant_override("separation", 12)
	add_child(_box)
	var title := UiTheme.label("SURVEILLANCE", 48, UiTheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	_box.add_child(gap)
	for entry in [["Jouer", _on_play], ["Options", _on_options], ["Quitter", _on_quit]]:
		var b := UiTheme.button(entry[0], 280)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(entry[1])
		_box.add_child(b)
	(_box.get_child(2) as Button).grab_focus()

	_options = OptionsPanel.new()
	_options.closed.connect(func() -> void: _box.show())
	add_child(_options)

	# fondu au noir seulement au lancement de la partie
	_fade = ColorRect.new()
	UiTheme.full_rect(_fade)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") and _options.visible:
		_options.close()
		get_viewport().set_input_as_handled()


func _on_play() -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.8)
	await tw.finished
	Sfx.stop_all_loops()
	GameState.reset()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_options() -> void:
	_box.hide()
	_options.open()


func _on_quit() -> void:
	get_tree().quit()
