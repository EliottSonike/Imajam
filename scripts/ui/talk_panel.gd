class_name TalkPanel
extends Control
## Négociation avec le détenu 2, face à face au réfectoire.

var _prisoner: Prisoner
var _speaker: Label
var _you: Label
var _line: Label
var _answers: VBoxContainer
var _step := 0
var _score := 0
var _waiting := false


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # on voit le détenu au-dessus du panneau

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -460
	panel.offset_right = 460
	panel.offset_top = -270
	panel.offset_bottom = -12
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var box := UiTheme.plate()
	box.content_margin_top = 22
	box.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	_speaker = UiTheme.mono("", 13, UiTheme.AMBER)
	vb.add_child(_speaker)
	_you = UiTheme.label("", 16, UiTheme.DIM)
	_you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_you)
	_line = UiTheme.label("", 18)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_line)
	_answers = VBoxContainer.new()
	_answers.add_theme_constant_override("separation", 5)
	vb.add_child(_answers)


func open(prisoner: Node) -> void:
	_prisoner = prisoner as Prisoner
	if _prisoner == null:
		return
	_step = 0
	_score = 0
	_speaker.text = "● ENTRETIEN  ·  DÉTENU %d — %s" % [_prisoner.prisoner_id, _prisoner.display_name.to_upper()]
	show()
	_show_step()


func _show_step() -> void:
	var ex: Dictionary = Texts.TALK_2[_step]
	_you.text = ""
	_line.text = "« %s »" % ex["line"]
	Sfx.play_voice(&"detenu_2", "negociation_%d" % (_step + 1))
	_clear_answers()
	var order := [0, 1, 2]
	order.shuffle()
	for i in order.size():
		var k: int = order[i]
		var a: Array = ex["answers"][k]
		var b := UiTheme.button("%d.  %s" % [i + 1, a[0]], 0.0, false)
		b.custom_minimum_size.y = 38
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_font_override("font", load("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_on_answer.bind(a, k + 1))
		_answers.add_child(b)
	(_answers.get_child(0) as Button).grab_focus()
	_waiting = false


func _on_answer(a: Array, k: int) -> void:
	if _waiting or _prisoner == null:
		return
	_waiting = true
	var effect: int = a[1]
	_score += effect
	_prisoner.call(&"on_talk_answer", effect)
	_clear_answers()
	var n := _step + 1
	_you.text = "Toi : %s" % a[0]
	_line.text = ""
	var t_you := Sfx.play_voice(&"joueur", "negociation_%d_reponse_%d" % [n, k])
	if t_you > 0.0:
		await get_tree().create_timer(t_you + 0.2).timeout
	if not visible:
		return
	_line.text = "« %s »" % a[2]
	var t_react := Sfx.play_voice(&"detenu_2", "negociation_%d_reaction_%d" % [n, k])
	await get_tree().create_timer(maxf(2.6, t_react + 0.4)).timeout
	if not visible:
		return
	_step += 1
	if _step < Texts.TALK_2.size():
		_show_step()
	else:
		_finish()


func _finish() -> void:
	var success := _score >= Texts.TALK_2_NEEDED
	_you.text = ""
	_line.text = "« %s »" % Texts.TALK_2_END["success" if success else "fail"]
	var t_end := Sfx.play_voice(&"detenu_2", "negociation_reussie" if success else "negociation_ratee")
	if not success and t_end == 0.0:
		Sfx.play("scream", -12.0, 0.9)
	await get_tree().create_timer(maxf(3.0, t_end + 0.4)).timeout
	hide()
	var id := _prisoner.prisoner_id
	_prisoner = null
	Events.talk_finished.emit(id, success)


func _clear_answers() -> void:
	for c in _answers.get_children():
		_answers.remove_child(c)
		c.queue_free()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"cancel") or event.is_action_pressed(&"cam_next") \
			or event.is_action_pressed(&"cam_prev") or event.is_action_pressed(&"inventory"):
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or _waiting:
		return
	for n in range(1, 4):
		if _is_digit(key, n) and n - 1 < _answers.get_child_count():
			(_answers.get_child(n - 1) as Button).pressed.emit()
			get_viewport().set_input_as_handled()
			return


func _is_digit(key: InputEventKey, n: int) -> bool:
	var row: Key = [KEY_1, KEY_2, KEY_3][n - 1]
	var pad: Key = [KEY_KP_1, KEY_KP_2, KEY_KP_3][n - 1]
	return key.physical_keycode == row or key.keycode == row or key.keycode == pad \
		or key.unicode == str(n).unicode_at(0)
