class_name EncounterPanel
extends Control
## Confrontation : pistolet ou taser.

var _prisoner: Prisoner
var _title: Label
var _text: Label
var _gun: Button
var _taser: Button
var _hint: Label


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -420
	panel.offset_right = 420
	panel.offset_top = -230
	panel.offset_bottom = -40
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	_title = UiTheme.label("", 22, UiTheme.ACCENT)
	vb.add_child(_title)
	_text = UiTheme.label("", 19)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	_gun = UiTheme.button("1. Tirer (pistolet)", 300)
	_gun.pressed.connect(_on_choice.bind(true))
	row.add_child(_gun)
	_taser = UiTheme.button("2. Neutraliser (taser)", 300)
	_taser.pressed.connect(_on_choice.bind(false))
	row.add_child(_taser)
	_hint = UiTheme.label("", 15, UiTheme.DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_hint)


func open(prisoner: Node = null) -> void:
	_prisoner = prisoner as Prisoner
	if _prisoner == null:
		return
	var id := _prisoner.prisoner_id
	_title.text = "Détenu %d : %s" % [id, _prisoner.display_name]
	_text.text = Texts.ENCOUNTERS.get(id, "Il se jette sur toi !")
	var has_taser := GameState.has_item(GameState.ITEM_TASER)
	_taser.disabled = not has_taser or not _prisoner.taser_allowed
	if not _prisoner.taser_allowed:
		_hint.text = "Il a un couteau : pas le temps de sortir le taser !"
	elif not has_taser:
		_hint.text = "Tu n'as pas de taser… (il est quelque part dans la prison)"
	else:
		_hint.text = ""
	show()
	_gun.grab_focus()
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	Events.ui_modal_changed.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if _is_digit(key, 1):
		_on_choice(true)
		get_viewport().set_input_as_handled()
	elif _is_digit(key, 2) and not _taser.disabled:
		_on_choice(false)
		get_viewport().set_input_as_handled()


func _is_digit(key: InputEventKey, n: int) -> bool:
	var row := KEY_1 if n == 1 else KEY_2
	var pad := KEY_KP_1 if n == 1 else KEY_KP_2
	return key.physical_keycode == row or key.keycode == row or key.keycode == pad \
		or key.unicode == str(n).unicode_at(0)


func _on_choice(killed: bool) -> void:
	if _prisoner == null or not visible:
		return
	var id := _prisoner.prisoner_id
	close()
	GameState.resolve_prisoner(id, killed)
	Events.encounter_resolved.emit(id, killed)
	await get_tree().create_timer(1.5).timeout
	GameState.set_vision_impaired(true)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"encounter", false)
		p.make_view_current()
	_prisoner = null
