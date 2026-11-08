class_name DocumentPanel
extends Control
## Affiche un texte (intro, bout de journal).

var _panel: PanelContainer
var _title: Label
var _body: RichTextLabel


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.dim(0.55))

	_panel = PanelContainer.new()
	UiTheme.centered(_panel, Vector2(800, 560))
	var paper := StyleBoxFlat.new()
	paper.bg_color = UiTheme.PAPER
	paper.border_color = Color(0.45, 0.38, 0.28)
	paper.set_border_width_all(2)
	paper.content_margin_left = 40
	paper.content_margin_right = 40
	paper.content_margin_top = 30
	paper.content_margin_bottom = 26
	_panel.add_theme_stylebox_override("panel", paper)
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	_panel.add_child(vb)
	_title = UiTheme.label("", 26, Color(0.18, 0.14, 0.1))
	_title.clip_text = true
	vb.add_child(_title)
	var sep := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(0.3, 0.24, 0.16, 0.5)
	sep.add_theme_stylebox_override("separator", line)
	vb.add_child(sep)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size = Vector2(0, 340)
	_body.fit_content = false
	_body.scroll_active = true
	_body.add_theme_color_override("default_color", Color(0.16, 0.13, 0.1))
	_body.add_theme_font_size_override("normal_font_size", 19)
	vb.add_child(_body)
	var close_btn := UiTheme.button("Fermer   [E]", 220)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(close)
	vb.add_child(close_btn)


func open(title := "", body := "") -> void:
	_title.text = title
	_body.text = body
	_body.scroll_to_line(0)
	show()
	UiTheme.pop_in(self)
	_panel.position.y += 20.0
	create_tween().tween_property(_panel, "position:y", _panel.position.y - 20.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_lock(true)
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	_lock(false)
	Events.ui_modal_changed.emit(false)
	Events.document_closed.emit()


func _lock(on: bool) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"document", on)
