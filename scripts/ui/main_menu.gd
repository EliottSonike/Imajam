class_name MainMenu
extends Control
## Menu principal : le mur d'écrans du poste de garde.
## Les 8 écrans affichent en direct les vraies caméras de la prison (level.tscn + cameras.tscn),
## l'écran du milieu affiche le titre et le menu. De temps en temps un écran grésille ou passe
## à une autre caméra, comme sur un vrai poste de surveillance.

const GAME_SCENE := "res://scenes/main.tscn"
const LEVEL_SCENE := "res://scenes/level.tscn"
const CAMERAS_SCENE := "res://scenes/cameras.tscn"

const SCREEN := Vector2(384, 216)
const GAP := 14.0
const FEED_RES := Vector2i(384, 216)
## Caméras affichées au départ (noms des nœuds de cameras.tscn), dans l'ordre des écrans.
const START_FEEDS := [
	"CAM_2_Cellule_1", "CAM_11_Refectoire", "CAM_9_Cellule_2",
	"CAM_5_Couloir_Sud", "CAM_8_Generateur",
	"CAM_6_Cellule_3", "CAM_4_Couloir_Central", "CAM_7_Acces_Generateur",
]
## Caméras qui filment une zone trop sombre pour le menu : jamais affichées.
const SKIP_FEEDS := ["CAM_3_Bloc_B", "CAM_13_Couloir_Ouest", "CAM_14_Couloir_Sud_Est"]
const TEXT := Color(0.82, 0.9, 0.86)
const TEXT_DIM := Color(0.5, 0.58, 0.55)
const REC := Color(0.95, 0.15, 0.12)

## Image de vidéosurveillance : désaturée, un peu verte.
const FEED_SHADER := """
shader_type canvas_item;
void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(c, vec3(g), 0.75) * vec3(1.05, 1.25, 1.12), 1.0);
}
"""

var _cams: Array[Dictionary] = []  ## toutes les caméras : {name, number, label, transform, fov}
var _feeds: Array[Dictionary] = []  ## un écran : {cam, label, static, base, sway, name}
var _rec_labels: Array[Label] = []
var _clock_labels: Array[Label] = []
var _buttons: Array[Button] = []
var _menu_box: VBoxContainer
var _options: OptionsPanel
var _fade: ColorRect
var _t := 0.0
var _next_glitch := 3.0
var _start_time := 2 * 3600 + 47 * 60 + 13  ## 02:47:13, l'heure affichée sur les écrans


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_all_loops()
	Sfx.loop("ambient", -18.0)
	UiTheme.full_rect(self)
	theme = UiTheme.get_theme()

	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.045)
	UiTheme.full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_load_world()
	_build_wall()

	_options = OptionsPanel.new()
	_options.closed.connect(_on_options_closed)
	add_child(_options)

	_fade = ColorRect.new()
	UiTheme.full_rect(_fade)
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 1.2)
	_buttons[0].grab_focus()


# --- La prison, chargée une fois et filmée par les écrans ---

func _load_world() -> void:
	# Le niveau vit dans le monde 3D du menu ; chaque écran a une SubViewport qui filme ce monde.
	var world := Node3D.new()
	world.name = "Prison"
	add_child(world)
	world.add_child(load(LEVEL_SCENE).instantiate())
	# On lit seulement la position des caméras : cameras.tscn n'est pas ajouté à l'arbre.
	var cams := load(CAMERAS_SCENE).instantiate() as Node3D
	for c in cams.get_children():
		if c is Camera3D:
			var n := String(c.name)
			var parts := n.split("_")
			_cams.append({
				"name": n,
				"number": parts[1] if parts.size() > 1 else "?",
				"label": String(c.get("label")),
				"transform": (c as Camera3D).transform,
				"fov": (c as Camera3D).fov,
			})
	cams.free()


func _cam_by_name(n: String) -> Dictionary:
	for c in _cams:
		if c.name == n:
			return c
	return _cams[0] if not _cams.is_empty() else {}


# --- Le mur d'écrans ---

func _build_wall() -> void:
	var total := Vector2(SCREEN.x * 3 + GAP * 2, SCREEN.y * 3 + GAP * 2)
	var wall := Control.new()
	UiTheme.centered(wall, total)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)
	var feed_i := 0
	for row in 3:
		for col in 3:
			var pos := Vector2(col * (SCREEN.x + GAP), row * (SCREEN.y + GAP))
			if row == 1 and col == 1:
				_build_menu_screen(wall, pos)
			elif feed_i < START_FEEDS.size():
				_build_feed(wall, pos, _cam_by_name(START_FEEDS[feed_i]))
				feed_i += 1


func _bezel(parent: Control, pos: Vector2) -> Panel:
	var bezel := Panel.new()
	bezel.position = pos - Vector2(5, 5)
	bezel.size = SCREEN + Vector2(10, 10)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0)
	sb.border_color = Color(0.13, 0.14, 0.15)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(6)
	bezel.add_theme_stylebox_override("panel", sb)
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bezel)
	return bezel


func _overlay(parent: Control, code: String) -> ColorRect:
	var r := UiTheme.shader_rect(code)
	r.set_anchors_preset(Control.PRESET_TOP_LEFT)
	r.position = Vector2(5, 5)
	r.size = SCREEN
	parent.add_child(r)
	return r


func _mono(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_feed(parent: Control, pos: Vector2, cam: Dictionary) -> void:
	var bezel := _bezel(parent, pos)
	var vp := SubViewport.new()
	vp.size = FEED_RES
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var camera := Camera3D.new()
	camera.current = true
	vp.add_child(camera)

	var screen := TextureRect.new()
	screen.texture = vp.get_texture()
	screen.position = Vector2(5, 5)
	screen.size = SCREEN
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = FEED_SHADER
	screen.material = mat
	bezel.add_child(screen)

	_overlay(bezel, UiTheme.CAMERA_FX)
	var stat := _overlay(bezel, UiTheme.STATIC_FX)

	var label := _mono("", 13, TEXT)
	label.position = Vector2(14, 10)
	bezel.add_child(label)
	var rec := _mono("● REC", 13, REC)
	rec.position = Vector2(SCREEN.x - 58, 10)
	bezel.add_child(rec)
	_rec_labels.append(rec)
	var clock := _mono("", 12, TEXT_DIM)
	clock.position = Vector2(14, SCREEN.y - 16)
	bezel.add_child(clock)
	_clock_labels.append(clock)

	var feed := {"cam": camera, "label": label, "static": stat, "base": Transform3D(),
		"sway": randf() * TAU, "name": ""}
	_feeds.append(feed)
	_set_feed(feed, cam)


func _set_feed(feed: Dictionary, cam: Dictionary) -> void:
	if cam.is_empty():
		return
	feed.base = cam.transform
	feed.name = cam.name
	var camera := feed.cam as Camera3D
	camera.transform = cam.transform
	camera.fov = cam.fov
	camera.set_cull_mask_value(SecurityCamera.HIDDEN_FROM_CAMERAS_LAYER, false)
	(feed.label as Label).text = "CAM %s · %s" % [String(cam.number).pad_zeros(2), String(cam.label).to_upper()]


func _build_menu_screen(parent: Control, pos: Vector2) -> void:
	var bezel := _bezel(parent, pos)
	var screen := ColorRect.new()
	screen.color = Color(0.02, 0.035, 0.03)
	screen.position = Vector2(5, 5)
	screen.size = SCREEN
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bezel.add_child(screen)

	_menu_box = VBoxContainer.new()
	_menu_box.position = Vector2(31, 21)
	_menu_box.size = SCREEN - Vector2(52, 32)
	_menu_box.add_theme_constant_override("separation", 0)
	bezel.add_child(_menu_box)
	_menu_box.add_child(_mono("THE GUARD :", 15, TEXT_DIM))
	var title := _mono("SURVEILLANCE", 40, TEXT)
	title.add_theme_color_override("font_shadow_color", Color(0.3, 1.0, 0.6, 0.2))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	_menu_box.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	_menu_box.add_child(gap)
	for entry in [["JOUER", _on_play], ["OPTIONS", _on_options], ["QUITTER", _on_quit]]:
		var b := _menu_button(entry[0])
		b.pressed.connect(entry[1])
		_menu_box.add_child(b)
		_buttons.append(b)

	var fx := _overlay(bezel, UiTheme.CAMERA_FX)
	(fx.material as ShaderMaterial).set_shader_parameter("noise", 0.05)


func _menu_button(text: String) -> Button:
	var b := Button.new()
	b.text = "  " + text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_override("font", UiTheme.font())
	b.add_theme_font_size_override("font_size", 20)
	for state in ["font_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(state, TEXT_DIM)
	for state in ["font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, TEXT)
	for style in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	b.mouse_entered.connect(b.grab_focus)
	b.focus_entered.connect(_on_button_focus.bind(b))
	b.pressed.connect(Sfx.play.bind("ui_click", -6.0))
	return b


## Le curseur « > » suit la souris et le clavier.
func _on_button_focus(b: Button) -> void:
	Sfx.play("ui_click", -18.0)
	for o in _buttons:
		o.text = ("> " if o == b else "  ") + o.text.substr(2)


# --- Animation : horloge, REC qui clignote, caméras qui oscillent, parasites ---

func _process(delta: float) -> void:
	_t += delta
	var rec_on := fmod(_t, 1.2) < 0.75
	for r in _rec_labels:
		r.visible = rec_on
	var secs := _start_time + int(_t)
	var clock := "08/11/2026  %02d:%02d:%02d" % [(secs / 3600) % 24, (secs / 60) % 60, secs % 60]
	for c in _clock_labels:
		c.text = clock
	for f in _feeds:
		var base: Transform3D = f.base
		(f.cam as Camera3D).transform = base.rotated_local(Vector3.UP, sin(_t * 0.25 + f.sway) * 0.06)
	_next_glitch -= delta
	if _next_glitch <= 0.0 and not _feeds.is_empty():
		_next_glitch = randf_range(2.5, 6.0)
		_glitch(_feeds.pick_random(), randf() < 0.4)


## Un écran grésille ; parfois il passe à une autre caméra pendant le grésillement.
func _glitch(feed: Dictionary, switch_cam: bool) -> void:
	var mat := (feed.static as ColorRect).material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(_set_static.bind(mat), 0.0, 0.9, 0.08)
	if switch_cam:
		tw.tween_callback(_switch_feed.bind(feed))
	tw.tween_interval(0.25 if switch_cam else 0.12)
	tw.tween_method(_set_static.bind(mat), 0.9, 0.0, 0.25)


func _set_static(v: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("amount", v)


func _switch_feed(feed: Dictionary) -> void:
	var used: Array = []
	for f in _feeds:
		used.append(f.name)
	var others := _cams.filter(func(c: Dictionary) -> bool: return not used.has(c.name) and not SKIP_FEEDS.has(c.name))
	if not others.is_empty():
		_set_feed(feed, others.pick_random())


# --- Actions ---

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
	_menu_box.hide()
	_options.open()


func _on_options_closed() -> void:
	_menu_box.show()
	_buttons[0].grab_focus()


func _on_quit() -> void:
	get_tree().quit()
