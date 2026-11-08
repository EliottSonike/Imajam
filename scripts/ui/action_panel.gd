class_name ActionPanel
extends Control
## Choix express (le jeu se fige le temps de choisir) et QTE.
## Le QTE est toujours le même (on peut l'apprendre) et ne pardonne aucune erreur.

signal chosen(index: int)
signal qte_done(success: bool)

const QTE_KEYS: Array[Key] = [KEY_E, KEY_F, KEY_SPACE, KEY_R]
const QTE_FIRST_WINDOW := 1.3  # première touche : le temps de comprendre ce qui arrive
const QTE_WINDOW := 0.9
const KEY_NAMES := {KEY_E: "E", KEY_F: "F", KEY_SPACE: "ESPACE", KEY_R: "R"}
## Touches qui ne comptent pas comme une erreur (on peut les tenir par réflexe).
const IGNORED := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK, KEY_ESCAPE]

var _mode := ""  # "", "choice" ou "qte"
var _choice_box: PanelContainer
var _choice_title: Label
var _choice_text: Label
var _choice_row: HBoxContainer
var _buttons: Array[Button] = []
var _qte_box: VBoxContainer
var _qte_title: Label
var _qte_key: Label
var _qte_bar: ColorRect
var _qte_steps: HBoxContainer
var _qte_i := 0
var _qte_left := 0.0
var _qte_window := 1.0


static func find(tree: SceneTree) -> ActionPanel:
	return tree.get_first_node_in_group(&"action_panel") as ActionPanel


func _ready() -> void:
	add_to_group(&"action_panel")
	UiTheme.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS  # le choix fige le jeu
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_choice()
	_build_qte()


## Fige le jeu et propose des options ; renvoie l'indice choisi (touches 1, 2… ou clic).
func choose(title: String, text: String, options: Array) -> int:
	_mode = "choice"
	_choice_title.text = title.to_upper()
	_choice_text.text = text
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for i in options.size():
		var b := UiTheme.button("%d. %s" % [i + 1, options[i]], 300)
		b.pressed.connect(func() -> void: _pick(i))
		_choice_row.add_child(b)
		_buttons.append(b)
	_choice_box.show()
	_qte_box.hide()
	show()
	UiTheme.pop_in(_choice_box, 0.12)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_buttons[0].grab_focus()
	Events.ui_modal_changed.emit(true)
	var index: int = await chosen
	_mode = ""
	hide()
	get_tree().paused = false
	Events.ui_modal_changed.emit(false)
	return index


## Lance le QTE ; renvoie vrai s'il est réussi sans la moindre erreur.
func run_qte(title := "Il t'attrape !") -> bool:
	_mode = "qte"
	_qte_title.text = title.to_upper()
	_qte_i = 0
	_qte_window = QTE_FIRST_WINDOW
	_qte_left = _qte_window
	_show_step()
	_choice_box.hide()
	_qte_box.show()
	show()
	Events.ui_modal_changed.emit(true)
	var ok: bool = await qte_done
	_qte_key.text = "OK" if ok else "RATÉ"
	_qte_key.add_theme_color_override("font_color", Color(0.55, 0.9, 0.5) if ok else UiTheme.DANGER)
	_qte_bar.scale.x = 0.0
	await get_tree().create_timer(0.55, true, false, true).timeout
	_qte_key.remove_theme_color_override("font_color")
	hide()
	Events.ui_modal_changed.emit(false)
	return ok


func is_busy() -> bool:
	return _mode != ""


func _process(delta: float) -> void:
	if _mode != "qte":
		return
	_qte_left -= delta
	_qte_bar.scale.x = clampf(_qte_left / _qte_window, 0.0, 1.0)
	if _qte_left <= 0.0:
		_end_qte(false)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _mode == "" or key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if _mode == "choice":
		for i in _buttons.size():
			if key.keycode == KEY_1 + i or key.physical_keycode == KEY_1 + i or key.keycode == KEY_KP_1 + i \
					or key.unicode == str(i + 1).unicode_at(0):
				_pick(i)
				return
		return
	if key.keycode in IGNORED:
		return
	var want: Key = QTE_KEYS[_qte_i]
	if key.keycode == want or key.physical_keycode == want:
		Sfx.play("ui_click", -4.0, 1.0 + 0.1 * _qte_i)
		_qte_i += 1
		if _qte_i >= QTE_KEYS.size():
			_end_qte(true)
		else:
			_qte_window = QTE_WINDOW
			_qte_left = _qte_window
			_show_step()
	else:
		_end_qte(false)


func _pick(i: int) -> void:
	if _mode == "choice":
		chosen.emit(i)


func _end_qte(ok: bool) -> void:
	if _mode != "qte":
		return
	_mode = ""
	qte_done.emit(ok)


func _show_step() -> void:
	_qte_key.text = KEY_NAMES.get(QTE_KEYS[_qte_i], "?")
	_qte_bar.scale.x = 1.0
	for i in _qte_steps.get_child_count():
		var dot := _qte_steps.get_child(i) as ColorRect
		dot.color = UiTheme.AMBER if i < _qte_i else (UiTheme.TEXT if i == _qte_i else Color(UiTheme.DIM, 0.4))
	UiTheme.pop_in(_qte_key, 0.08)


func _build_choice() -> void:
	_choice_box = PanelContainer.new()
	_choice_box.anchor_left = 0.5
	_choice_box.anchor_right = 0.5
	_choice_box.anchor_top = 0.5
	_choice_box.anchor_bottom = 0.5
	_choice_box.offset_left = -420
	_choice_box.offset_right = 420
	_choice_box.offset_top = -30
	_choice_box.offset_bottom = 160
	_choice_box.add_theme_stylebox_override("panel", UiTheme.fabric(true))
	add_child(_choice_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_choice_box.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	_choice_title = UiTheme.title("", 26)
	head.add_child(_choice_title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	var alert := UiTheme.mono("● ALERTE", 14, UiTheme.DANGER)
	alert.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(alert)
	_choice_text = UiTheme.label("", 19)
	_choice_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_choice_text)
	_choice_row = HBoxContainer.new()
	_choice_row.add_theme_constant_override("separation", 16)
	_choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_choice_row)


func _build_qte() -> void:
	_qte_box = VBoxContainer.new()
	UiTheme.centered(_qte_box, Vector2(420, 260))
	_qte_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_qte_box.add_theme_constant_override("separation", 14)
	_qte_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_qte_box)
	_qte_title = UiTheme.title("", 30, UiTheme.DANGER)
	_qte_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qte_box.add_child(_qte_title)
	var cap := PanelContainer.new()
	cap.custom_minimum_size = Vector2(220, 110)
	cap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.03, 0.85)
	style.border_color = UiTheme.ACCENT
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	cap.add_theme_stylebox_override("panel", style)
	_qte_box.add_child(cap)
	_qte_key = UiTheme.title("", 56)
	_qte_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qte_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_child(_qte_key)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0, 0, 0, 0.6)
	bar_bg.custom_minimum_size = Vector2(220, 8)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_qte_box.add_child(bar_bg)
	_qte_bar = ColorRect.new()
	_qte_bar.color = UiTheme.AMBER
	UiTheme.full_rect(_qte_bar)
	bar_bg.add_child(_qte_bar)
	_qte_steps = HBoxContainer.new()
	_qte_steps.alignment = BoxContainer.ALIGNMENT_CENTER
	_qte_steps.add_theme_constant_override("separation", 10)
	_qte_box.add_child(_qte_steps)
	for i in QTE_KEYS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(26, 6)
		_qte_steps.add_child(dot)
