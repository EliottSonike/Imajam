class_name EndingPanel
extends Control
## Écran de fin, en deux temps :
## 1. noir, « 06:00 — fin du service » ;
## 2. le rapport de nuit sur le porte-bloc (bilan des détenus, pages, durée), le tampon de la fin,
##    le texte qui s'écrit, les fins découvertes, puis Rejouer / Menu.

const MENU_SCENE := "res://scenes/menu.tscn"
const INK := Color(0.12, 0.11, 0.1)
const INK_SOFT := Color(0.36, 0.33, 0.29)
const STAMP := Color(0.72, 0.12, 0.1)
const ENDING_NAMES := {1: "Le Bon", 2: "La Brute", 3: "Le Truand"}
const HINTS := {
	1: "Une fin sans une goutte de sang existe.",
	2: "Il existe une fin plus… expéditive.",
	3: "Le carnet du gardien comptait quatre pages.",
}

var _intro: Control
var _clock: Label
var _report: Control
var _title: Label
var _subtitle: Label
var _body: Label
var _stamp: Label
var _rows: VBoxContainer
var _found: HBoxContainer
var _hint: Label
var _buttons: HBoxContainer


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.022, 0.02)
	UiTheme.full_rect(bg)
	add_child(bg)
	_build_intro()
	_build_report()


func _build_intro() -> void:
	_intro = VBoxContainer.new()
	UiTheme.centered(_intro, Vector2(700, 200))
	(_intro as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_intro)
	_clock = UiTheme.mono("06:00", 84, UiTheme.AMBER)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.add_child(_clock)
	var l := UiTheme.mono("FIN DU SERVICE  —  PRISON SAINT-ROCH", 20, UiTheme.DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.add_child(l)


func _build_report() -> void:
	_report = Control.new()
	UiTheme.full_rect(_report)
	_report.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_report)

	var row := HBoxContainer.new()
	UiTheme.centered(row, Vector2(1120, 640))
	row.add_theme_constant_override("separation", 48)
	_report.add_child(row)

	# à gauche : la fin
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(520, 0)
	left.add_theme_constant_override("separation", 16)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	_title = UiTheme.title("", 66)
	left.add_child(_title)
	_subtitle = UiTheme.mono("", 18, UiTheme.AMBER)
	left.add_child(_subtitle)
	var sep := ColorRect.new()
	sep.color = Color(UiTheme.DIM, 0.4)
	sep.custom_minimum_size = Vector2(0, 2)
	left.add_child(sep)
	_body = UiTheme.label("", 21)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(520, 260)
	left.add_child(_body)
	_buttons = HBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 18)
	left.add_child(_buttons)
	var again := UiTheme.button("Rejouer", 230)
	again.pressed.connect(_on_replay)
	_buttons.add_child(again)
	var menu := UiTheme.button("Menu principal", 230)
	menu.pressed.connect(_on_menu)
	_buttons.add_child(menu)

	# à droite : le rapport de nuit sur le porte-bloc
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(552, 640)
	row.add_child(holder)
	var board := PanelContainer.new()
	UiTheme.full_rect(board)
	board.add_theme_stylebox_override("panel", UiTheme.clipboard())
	holder.add_child(board)
	var sheet := PanelContainer.new()
	var paper := StyleBoxFlat.new()
	paper.bg_color = UiTheme.PAPER
	paper.set_content_margin_all(26)
	paper.shadow_color = Color(0, 0, 0, 0.35)
	paper.shadow_size = 6
	sheet.add_theme_stylebox_override("panel", paper)
	board.add_child(sheet)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	sheet.add_child(vb)
	vb.add_child(_ink("RAPPORT DE NUIT", 30, INK, true))
	vb.add_child(_ink("Pénitencier Saint-Roch  —  formulaire 12-B", 13, INK_SOFT))
	vb.add_child(_rule())
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 8)
	vb.add_child(_rows)
	vb.add_child(_rule())
	vb.add_child(_ink("FINS DÉCOUVERTES", 15, INK_SOFT))
	_found = HBoxContainer.new()
	_found.add_theme_constant_override("separation", 10)
	vb.add_child(_found)
	_hint = _ink("", 15, INK_SOFT)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_hint)
	var clip := UiTheme.clipboard_clip()
	clip.size = Vector2(220, 70)
	clip.position = Vector2(166, -34)
	holder.add_child(clip)
	# le tampon, posé de travers sur la feuille
	_stamp = UiTheme.title("", 40, STAMP)
	_stamp.rotation_degrees = -12.0
	_stamp.position = Vector2(270, 520)
	holder.add_child(_stamp)


func open(ending: int = 0) -> void:
	var data: Dictionary = Texts.ENDINGS.get(ending, {"title": "FIN", "subtitle": "", "body": ""})
	GameState.mark_ending_seen(ending)
	_title.text = String(data["title"]).to_upper()
	_subtitle.text = String(data["subtitle"]).to_upper()
	_body.text = data["body"]
	_body.visible_ratio = 0.0
	_stamp.text = String(data["title"]).to_upper()
	_fill_report(ending)
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_all_loops()
	Events.ui_modal_changed.emit(true)

	_intro.modulate.a = 0.0
	_report.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	_stamp.modulate.a = 0.0
	_stamp.scale = Vector2(1.8, 1.8)
	var tw := create_tween()
	tw.tween_property(_intro, "modulate:a", 1.0, 1.2)
	tw.tween_interval(1.8)
	tw.tween_property(_intro, "modulate:a", 0.0, 0.8)
	tw.tween_property(_report, "modulate:a", 1.0, 1.0)
	tw.tween_property(_body, "visible_ratio", 1.0, maxf(3.0, _body.text.length() * 0.03))
	tw.tween_callback(func() -> void: Sfx.play("door", -10.0, 1.6))  # coup de tampon
	tw.parallel().tween_property(_stamp, "modulate:a", 0.85, 0.12)
	tw.parallel().tween_property(_stamp, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_buttons, "modulate:a", 1.0, 0.6)


func _fill_report(ending: int) -> void:
	for c in _rows.get_children():
		c.queue_free()
	for id in [1, 2, 3]:
		var outcome := String(GameState.outcomes.get(id, "—"))
		var line := _report_line("Détenu %d  —  %s" % [id, Texts.PRISONER_NAMES.get(id, "")], outcome.to_upper(),
			STAMP if outcome == GameState.OUTCOME_KILLED else INK)
		_rows.add_child(line)
	_rows.add_child(_report_line("Carnet du gardien disparu", "%d / %d PAGES" % [GameState.journal_count(), GameState.JOURNAL_COUNT], INK))
	var secs := GameState.elapsed_seconds()
	_rows.add_child(_report_line("Durée du service", "%d MIN %02d S" % [secs / 60, secs % 60], INK))

	for c in _found.get_children():
		c.queue_free()
	var missing: Array = []
	for e in [1, 2, 3]:
		var seen := GameState.ending_seen(e)
		var tag := _ink(String(ENDING_NAMES[e]).to_upper() if seen else "? ? ?", 16, INK if seen else INK_SOFT, true)
		var box := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = STAMP if e == ending else INK_SOFT
		sb.set_border_width_all(2)
		sb.set_content_margin_all(8)
		box.add_theme_stylebox_override("panel", sb)
		box.add_child(tag)
		_found.add_child(box)
		if not seen:
			missing.append(e)
	_hint.text = HINTS[missing[0]] if not missing.is_empty() else "Toutes les fins sont découvertes. La prison n'a plus de secrets pour toi."


func _report_line(left: String, right: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := _ink(left, 17, INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(_ink(right, 17, color, true))
	return row


func _ink(text: String, size: int, color: Color, bold := false) -> Label:
	var l := UiTheme.mono(text, size, color) if not bold else UiTheme.title(text, size, color)
	return l


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(INK_SOFT, 0.6)
	r.custom_minimum_size = Vector2(0, 1)
	return r


func close() -> void:
	hide()


func _on_replay() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
