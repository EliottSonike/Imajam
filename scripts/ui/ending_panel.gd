class_name EndingPanel
extends Control
## Écran de fin : titre, texte qui s'écrit lettre par lettre, puis Rejouer / Menu.

const MENU_SCENE := "res://scenes/menu.tscn"

var _title: Label
var _subtitle: Label
var _body: Label
var _buttons: HBoxContainer


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.menu_bg())

	var vb := VBoxContainer.new()
	UiTheme.centered(vb, Vector2(900, 560))
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)
	_title = UiTheme.label("", 56, UiTheme.ACCENT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_subtitle = UiTheme.label("", 20, UiTheme.DIM)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_subtitle)
	vb.add_child(HSeparator.new())
	_body = UiTheme.label("", 21)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_body)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 20)
	vb.add_child(_buttons)
	var again := UiTheme.button("Rejouer", 240)
	again.pressed.connect(_on_replay)
	_buttons.add_child(again)
	var menu := UiTheme.button("Menu principal", 240)
	menu.pressed.connect(_on_menu)
	_buttons.add_child(menu)


func open(ending: int = 0) -> void:
	var data: Dictionary = Texts.ENDINGS.get(ending, {"title": "FIN", "subtitle": "", "body": ""})
	_title.text = data["title"]
	_subtitle.text = data["subtitle"]
	_body.text = data["body"]
	_body.visible_ratio = 0.0
	_buttons.modulate.a = 0.0
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_all_loops()
	_title.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 1.5)
	tw.tween_property(_body, "visible_ratio", 1.0, maxf(3.0, _body.text.length() * 0.035))
	tw.tween_property(_buttons, "modulate:a", 1.0, 0.6)
	Events.ui_modal_changed.emit(true)


func close() -> void:
	hide()


func _on_replay() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
