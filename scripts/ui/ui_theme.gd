class_name UiTheme
extends RefCounted

const ACCENT := Color(0.96, 0.96, 0.96)  # titres
const TEXT := Color(0.88, 0.88, 0.88)
const DIM := Color(0.6, 0.6, 0.6)
const BG := Color(0.11, 0.11, 0.12, 0.96)
const DANGER := Color(1.0, 0.36, 0.3)
const PAPER := Color(0.93, 0.89, 0.76)
const MENU_COLOR := Color(0.13, 0.13, 0.14)

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Police à chasse fixe (horloge et textes des caméras).
static func font() -> Font:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "DejaVu Sans Mono", "Courier New", "monospace"])
	return f


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	var panel := _box(BG, Color(0, 0, 0, 0), 0, 24)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("normal", "Button", _box(Color(0.22, 0.22, 0.23), Color(0, 0, 0, 0), 0, 12))
	t.set_stylebox("hover", "Button", _box(Color(0.3, 0.3, 0.32), Color(0, 0, 0, 0), 0, 12))
	t.set_stylebox("pressed", "Button", _box(Color(0.38, 0.38, 0.4), Color(0, 0, 0, 0), 0, 12))
	t.set_stylebox("disabled", "Button", _box(Color(0.16, 0.16, 0.17), Color(0, 0, 0, 0), 0, 12))
	var focus := _box(Color(0, 0, 0, 0), Color(1, 1, 1, 0.45), 1, 12)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.42, 0.42, 0.42))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 21)
	var line := StyleBoxLine.new()
	line.color = Color(1, 1, 1, 0.15)
	line.thickness = 1
	t.set_stylebox("separator", "HSeparator", line)
	var slider := _box(Color(0.3, 0.3, 0.32), Color(0, 0, 0, 0), 0, 0)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", _box(Color(0.7, 0.7, 0.72), Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(Color(0.85, 0.85, 0.87), Color(0, 0, 0, 0), 0, 0))
	return t


static func _box(bg: Color, border: Color, border_width: int, margin: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(4)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s


static func label(text: String, size := 18, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_width := 280.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 46)
	b.pressed.connect(func() -> void: Sfx.play("ui_click", -6.0))
	return b


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func centered(c: Control, size: Vector2) -> Control:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.5
	c.anchor_bottom = 0.5
	c.offset_left = -size.x / 2.0
	c.offset_right = size.x / 2.0
	c.offset_top = -size.y / 2.0
	c.offset_bottom = size.y / 2.0
	c.custom_minimum_size = size
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH
	return c


## Fond uni plein écran pour les menus.
static func menu_bg() -> ColorRect:
	var r := ColorRect.new()
	r.color = MENU_COLOR
	full_rect(r)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func dim(alpha := 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	full_rect(r)
	return r


## Apparition douce d'un panneau.
static func pop_in(c: Control, duration := 0.22) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 1.0, duration)


static func shader_rect(code: String) -> ColorRect:
	var r := ColorRect.new()
	full_rect(r)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	r.material = mat
	return r


const CAMERA_FX := """
shader_type canvas_item;
uniform float noise = 0.12;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float scan = sin(uv.y * 900.0) * 0.5 + 0.5;
	float n = rand(floor(uv * vec2(640.0, 360.0)) + floor(TIME * 24.0));
	float vig = smoothstep(0.95, 0.35, distance(uv, vec2(0.5)));
	float a = (1.0 - scan) * 0.10 + n * noise + (1.0 - vig) * 0.65;
	COLOR = vec4(vec3(n * 0.25), clamp(a, 0.0, 1.0));
}
"""

## Neige plein écran (changement de caméra).
const STATIC_FX := """
shader_type canvas_item;
uniform float amount = 0.0;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = rand(floor(UV * vec2(320.0, 180.0)) + floor(TIME * 60.0));
	float band = step(0.92, fract(UV.y * 3.0 + TIME * 2.0)) * 0.4;
	COLOR = vec4(vec3(n + band), amount);
}
"""

const VISION_FX := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
void fragment() {
	vec2 off = vec2(sin(TIME * 1.7), cos(TIME * 1.3)) * 0.008 * amount;
	vec3 a = textureLod(screen_tex, SCREEN_UV, 2.0 * amount).rgb;
	vec3 b = texture(screen_tex, SCREEN_UV + off).rgb;
	vec3 c = mix(a, b, 0.5);
	float vig = smoothstep(0.9, 0.25, distance(UV, vec2(0.5)));
	c *= mix(1.0, vig, 0.7 * amount);
	c = mix(c, c * vec3(1.1, 0.85, 0.85), 0.4 * amount);
	COLOR = vec4(c, step(0.01, amount));
}
"""


