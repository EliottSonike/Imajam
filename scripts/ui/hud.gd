class_name Hud
extends Control
## Viseur, prompt d'interaction, sous-titres, objectif, overlay caméras.

var _crosshair: ColorRect
var _prompt: Label
var _sub_panel: PanelContainer
var _subtitle: Label
var _objective: Label
var _toast: Label
var _status: Label
var _controls: Label
var _cam: Control
var _cam_title: Label
var _cam_rec: Label
var _cam_time: Label
var _static: ColorRect
var _sub_timer := 0.0
var _sub_fade: Tween
var _toast_tween: Tween
var _clock := 2.0 * 3600.0 + 13.0 * 60.0  # l'action commence à 02:13


func _ready() -> void:
	UiTheme.full_rect(self)
	process_mode = Node.PROCESS_MODE_PAUSABLE  # figé pendant la pause (l'UI racine tourne toujours)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.75)
	UiTheme.centered(_crosshair, Vector2(4, 4))
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE  # sinon il bloque le regard souris
	add_child(_crosshair)

	_prompt = UiTheme.label("", 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(_prompt, 0.5, 0.58, -400, 400, 0, 30)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	add_child(_prompt)

	_objective = UiTheme.mono("", 15, UiTheme.AMBER)
	_anchor(_objective, 0.0, 0.0, 24, 760, 18, 44)
	_objective.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective.add_theme_constant_override("outline_size", 5)
	add_child(_objective)

	_toast = UiTheme.label("", 20, UiTheme.PAPER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(_toast, 0.5, 0.0, -400, 400, 70, 100)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.modulate.a = 0.0
	add_child(_toast)

	_status = UiTheme.label("", 17, UiTheme.DANGER)
	_anchor(_status, 0.0, 1.0, 24, 760, -96, -72)
	_status.add_theme_color_override("font_outline_color", Color.BLACK)
	_status.add_theme_constant_override("outline_size", 5)
	add_child(_status)

	_controls = UiTheme.label(Texts.CONTROLS, 14, UiTheme.DIM)
	_anchor(_controls, 0.0, 1.0, 24, 1200, -40, -18)
	_controls.modulate.a = 0.0
	add_child(_controls)

	_sub_panel = PanelContainer.new()
	_anchor(_sub_panel, 0.5, 1.0, -460, 460, -170, -100)
	_sub_panel.modulate.a = 0.0
	_sub_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sub_box := StyleBoxFlat.new()
	sub_box.bg_color = Color(0.02, 0.025, 0.02, 0.8)
	sub_box.border_color = Color(UiTheme.AMBER, 0.5)
	sub_box.border_width_left = 3
	sub_box.content_margin_left = 22
	sub_box.content_margin_right = 22
	sub_box.content_margin_top = 10
	sub_box.content_margin_bottom = 10
	_sub_panel.add_theme_stylebox_override("panel", sub_box)
	_subtitle = UiTheme.label("", 19)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_panel.add_child(_subtitle)
	add_child(_sub_panel)

	_build_camera_overlay()

	Events.interact_prompt.connect(func(t: String) -> void: _prompt.text = t)
	Events.subtitle.connect(_on_subtitle)
	Events.say.connect(_on_say)
	Events.encounter_requested.connect(func(_p: Node) -> void: _raise_subtitles(true))
	Events.encounter_resolved.connect(func(_id: int, _k: bool) -> void: _raise_subtitles(false))
	Events.objective_changed.connect(_on_objective)
	Events.camera_mode_changed.connect(_on_camera_mode)
	Events.camera_viewed.connect(_on_camera_viewed)
	Events.item_picked.connect(_on_item_picked)
	Events.journal_picked.connect(_on_journal_picked)
	Events.map_taken.connect(func() -> void: _show_toast("Carte récupérée"))
	Events.vision_changed.connect(func(_v: bool) -> void: _update_status())
	Events.power_changed.connect(_on_power_changed)
	_update_status()


func _process(delta: float) -> void:
	_clock += delta
	if _sub_timer > 0.0:
		_sub_timer -= delta
		if _sub_timer <= 0.0:
			_sub_fade = create_tween()
			_sub_fade.tween_property(_sub_panel, "modulate:a", 0.0, 0.4)
	if _cam.visible:
		var c := int(_clock)
		_cam_time.text = "08/11/2026   %02d:%02d:%02d" % [floori(c / 3600.0) % 24, floori(c / 60.0) % 60, c % 60]
		_cam_rec.visible = fmod(_clock, 1.0) < 0.6


func show_controls(duration := 14.0) -> void:
	var tw := create_tween()
	tw.tween_property(_controls, "modulate:a", 1.0, 0.6)
	tw.tween_interval(duration)
	tw.tween_property(_controls, "modulate:a", 0.0, 1.0)


func _on_subtitle(text: String, duration: float) -> void:
	if text == "":
		return
	_subtitle.text = text
	_sub_timer = duration
	# la réplique précédente finissait de s'effacer : sans ça elle emportait la nouvelle avec elle
	if _sub_fade:
		_sub_fade.kill()
		_sub_fade = null
	_sub_panel.modulate.a = 1.0


func _raise_subtitles(up: bool) -> void:
	_sub_panel.offset_top = -330.0 if up else -170.0
	_sub_panel.offset_bottom = -260.0 if up else -100.0


func _on_say(speaker: StringName, text: String, duration: float) -> void:
	var who: String = Texts.SPEAKER_NAMES.get(speaker, "")
	if who == "":
		_subtitle.add_theme_font_override("font", _italic_font())
		_subtitle.add_theme_color_override("font_color", Color(0.82, 0.82, 0.84))
		_on_subtitle(text, duration)
	else:
		_subtitle.remove_theme_font_override("font")
		_subtitle.add_theme_color_override("font_color", UiTheme.TEXT)
		_on_subtitle("%s : %s" % [who, text], duration)


var _italic: FontVariation

## Italique obtenue en penchant la police par défaut.
func _italic_font() -> Font:
	if _italic == null:
		_italic = FontVariation.new()
		_italic.base_font = get_theme_default_font()
		_italic.variation_transform = Transform2D(Vector2(1.0, 0.22), Vector2(0.0, 1.0), Vector2.ZERO)
	return _italic


func _on_objective(text: String) -> void:
	if text == "":
		_objective.text = ""
		return
	_objective.text = "OBJECTIF  ›  " + text
	_objective.modulate.a = 0.0
	create_tween().tween_property(_objective, "modulate:a", 1.0, 0.6)
	if _controls.modulate.a == 0.0 and _objective.text != "" and not has_meta("controls_shown"):
		set_meta("controls_shown", true)
		show_controls()


func _on_item_picked(id: StringName) -> void:
	if id == GameState.ITEM_TASER:
		_show_toast("+ Taser")
	elif id == GameState.ITEM_MEDS:
		_show_toast("+ Médicaments  (R pour les prendre)")
	_update_status()


func _on_journal_picked(_index: int) -> void:
	_show_toast("Morceau de journal  %d / %d   (Tab pour relire)" % [GameState.journal_count(), GameState.JOURNAL_COUNT])


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)


func _update_status() -> void:
	if not GameState.vision_impaired:
		_status.text = ""
	elif GameState.has_item(GameState.ITEM_MEDS):
		_status.text = "VISION TROUBLE  —  [R] prendre un médicament"
	else:
		_status.text = "VISION TROUBLE  —  il te faut des médicaments (infirmerie)"


func _on_power_changed(_on: bool) -> void:
	_update_status()


func _build_camera_overlay() -> void:
	_cam = Control.new()
	UiTheme.full_rect(_cam)
	_cam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cam.visible = false
	add_child(_cam)
	_cam.add_child(UiTheme.shader_rect(UiTheme.CAMERA_FX))

	_cam_rec = UiTheme.mono("● REC", 22, UiTheme.DANGER)
	_anchor(_cam_rec, 0.0, 0.0, 36, 200, 28, 58)
	_cam.add_child(_cam_rec)
	_cam_title = UiTheme.mono("", 24, UiTheme.TEXT)
	_anchor(_cam_title, 0.0, 0.0, 36, 700, 62, 94)
	_cam.add_child(_cam_title)
	_cam_time = UiTheme.mono("", 20, UiTheme.TEXT)
	_cam_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_anchor(_cam_time, 1.0, 0.0, -460, -36, 28, 58)
	_cam.add_child(_cam_time)
	var hint := UiTheme.mono("◄ ►  /  Q D : changer de caméra        ÉCHAP : quitter les écrans", 15, UiTheme.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor(hint, 0.5, 1.0, -500, 500, -50, -24)
	_cam.add_child(hint)
	# coins du cadre
	for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		for horizontal in [true, false]:
			var bar := ColorRect.new()
			bar.color = Color(UiTheme.TEXT, 0.8)
			var bar_size := Vector2(60, 3) if horizontal else Vector2(3, 60)
			var x := 20.0 if corner.x == 0 else -20.0 - bar_size.x
			var y := 20.0 if corner.y == 0 else -20.0 - bar_size.y
			_anchor(bar, corner.x, corner.y, x, x + bar_size.x, y, y + bar_size.y)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_cam.add_child(bar)

	_static = UiTheme.shader_rect(UiTheme.STATIC_FX)
	(_static.material as ShaderMaterial).set_shader_parameter("amount", 0.0)
	add_child(_static)


func _on_camera_mode(active: bool) -> void:
	_cam.visible = active
	_crosshair.visible = not active
	_prompt.visible = not active
	_objective.visible = not active
	_controls.visible = not active
	_burst_static(0.35)


func _on_camera_viewed(camera_id: StringName) -> void:
	var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
	var cam: SecurityCamera = sys.current_camera() if sys else null
	var label: String = String(camera_id)
	if cam and cam.label != "":
		label = cam.label
	var number: int = sys.camera_number() if sys else 0
	_cam_title.text = "CAM %02d  —  %s" % [number, label.to_upper()]
	_burst_static(0.18)


func _burst_static(duration: float) -> void:
	var mat := _static.material as ShaderMaterial
	mat.set_shader_parameter("amount", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), 1.0, 0.0, duration)


func _anchor(c: Control, ax: float, ay: float, left: float, right: float, top: float, bottom: float) -> void:
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	c.offset_left = left
	c.offset_right = right
	c.offset_top = top
	c.offset_bottom = bottom
