class_name UiTheme
extends RefCounted
## Thème « poste de garde » : plaques d'acier vissées, boutons en ruban Dymo,
## titres au pochoir, données en police à chasse fixe.
## Les textures sont générées par tools/generate_ui.py (assets/ui/theme/).

const ACCENT := Color(0.95, 0.92, 0.82)  # titres (crème)
const TEXT := Color(0.87, 0.85, 0.78)
const DIM := Color(0.56, 0.59, 0.53)
const BG := Color(0.07, 0.08, 0.07, 0.96)
const DANGER := Color(0.95, 0.34, 0.26)
const AMBER := Color(0.95, 0.66, 0.2)  # voyants, focus, valeurs
const PAPER := Color(0.93, 0.89, 0.76)
const MENU_COLOR := Color(0.06, 0.07, 0.06)
const DYMO_TEXT := Color(0.94, 0.93, 0.88)

const _DIR := "res://assets/ui/theme/"
const _FONT_TEXT := "res://assets/fonts/BarlowCondensed-Medium.ttf"
const _FONT_BOLD := "res://assets/fonts/BarlowCondensed-SemiBold.ttf"
const _FONT_STENCIL := "res://assets/fonts/SairaStencilOne-Regular.ttf"
const _FONT_MONO := "res://assets/fonts/IBMPlexMono-Medium.ttf"

static var _theme: Theme
static var _mono: Font
static var _stencil: Font
static var _bold: Font


static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


## Police à chasse fixe (horloges, caméras, références).
static func font() -> Font:
	if _mono == null:
		_mono = load(_FONT_MONO)
	return _mono


## Police des titres, au pochoir.
static func stencil_font() -> Font:
	if _stencil == null:
		_stencil = load(_FONT_STENCIL)
	return _stencil


## Police des boutons : lettres serrées et espacées comme une étiqueteuse.
static func dymo_font() -> Font:
	if _bold == null:
		var v := FontVariation.new()
		v.base_font = load(_FONT_BOLD)
		v.spacing_glyph = 2
		_bold = v
	return _bold


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = load(_FONT_TEXT)
	t.default_font_size = 21

	t.set_stylebox("panel", "PanelContainer", plate())
	t.set_stylebox("panel", "Panel", plate())

	t.set_stylebox("normal", "Button", _tape("dymo.png"))
	t.set_stylebox("hover", "Button", _tape("dymo_survol.png"))
	t.set_stylebox("pressed", "Button", _tape("dymo_appui.png", 2))
	t.set_stylebox("hover_pressed", "Button", _tape("dymo_appui.png", 2))
	t.set_stylebox("disabled", "Button", _tape("dymo_inactif.png"))
	t.set_stylebox("focus", "Button", _tape("dymo_survol.png"))
	t.set_font("font", "Button", dymo_font())
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", DYMO_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color(1, 0.9, 0.85))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 0.9, 0.85))
	t.set_color("font_disabled_color", "Button", Color(0.68, 0.69, 0.64))

	# Interrupteur à levier (plein écran…), sans ruban derrière.
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.set_stylebox(st, "CheckButton", StyleBoxEmpty.new())
	t.set_icon("checked", "CheckButton", load(_DIR + "interrupteur_on.png"))
	t.set_icon("unchecked", "CheckButton", load(_DIR + "interrupteur_off.png"))
	t.set_icon("checked_disabled", "CheckButton", load(_DIR + "interrupteur_on.png"))
	t.set_icon("unchecked_disabled", "CheckButton", load(_DIR + "interrupteur_off.png"))
	t.set_font("font", "CheckButton", load(_FONT_TEXT))
	t.set_font_size("font_size", "CheckButton", 22)
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", AMBER)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 21)
	t.set_font_size("bold_font_size", "RichTextLabel", 23)

	var line := StyleBoxTexture.new()
	line.texture = load(_DIR + "separateur.png")
	line.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	line.content_margin_top = 1
	line.content_margin_bottom = 1
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", 6)

	var slot := StyleBoxTexture.new()
	slot.texture = load(_DIR + "rainure.png")
	slot.set_texture_margin_all(3)
	slot.content_margin_top = 5
	slot.content_margin_bottom = 5
	t.set_stylebox("slider", "HSlider", slot)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(AMBER, 0.75)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	fill.expand_margin_top = -2
	fill.expand_margin_bottom = -2
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", load(_DIR + "curseur.png"))
	t.set_icon("grabber_highlight", "HSlider", load(_DIR + "curseur_survol.png"))
	t.set_icon("grabber_disabled", "HSlider", load(_DIR + "curseur.png"))

	var tip := StyleBoxFlat.new()
	tip.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	tip.set_border_width_all(1)
	tip.border_color = Color(AMBER, 0.6)
	tip.set_content_margin_all(8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_font("font", "TooltipLabel", font())
	t.set_font_size("font_size", "TooltipLabel", 14)
	return t


## Plaque d'acier peinte et vissée (danger : cerclée de bandes jaunes et noires).
static func plate(danger := false) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(_DIR + ("plaque_danger.png" if danger else "plaque.png"))
	s.set_texture_margin_all(24.0 if danger else 32.0)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.content_margin_left = 40
	s.content_margin_right = 40
	s.content_margin_top = 30
	s.content_margin_bottom = 30
	return s


static func _tape(file: String, push := 0) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(_DIR + file)
	s.texture_margin_left = 12
	s.texture_margin_right = 12
	s.texture_margin_top = 8
	s.texture_margin_bottom = 8
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 8 + push
	s.content_margin_bottom = 8 - push
	return s


static func label(text: String, size := 18, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	# La police est étroite : on compense pour garder la même lisibilité.
	l.add_theme_font_size_override("font_size", roundi(size * 1.15))
	l.add_theme_color_override("font_color", color)
	return l


## Titre au pochoir.
static func title(text: String, size := 30, color := ACCENT) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", stencil_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Petite étiquette en chasse fixe (références, légendes).
static func mono(text: String, size := 13, color := DIM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## En-tête de plaque : voyant, titre au pochoir, référence du formulaire à droite.
static func header(text: String, ref := "", size := 30, lamp := AMBER) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_font_size_override("font_size", 14)
	dot.add_theme_color_override("font_color", lamp)
	dot.add_theme_color_override("font_shadow_color", Color(lamp, 0.45))
	dot.add_theme_constant_override("shadow_outline_size", 6)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	row.add_child(title(text, size))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	if ref != "":
		var r := mono(ref, 13)
		r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(r)
	return row


static func button(text: String, min_width := 280.0, upper := true) -> Button:
	var b := Button.new()
	b.text = text.to_upper() if upper else text
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


## Fond plein écran des menus : pénombre granuleuse, bord assombri.
static func menu_bg() -> ColorRect:
	var r := shader_rect(BACKDROP_FX)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
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


const BACKDROP_FX := """
shader_type canvas_item;
float rand(vec2 co) { return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = rand(floor(FRAGCOORD.xy * 0.5) + floor(TIME * 12.0));
	float vig = smoothstep(1.05, 0.2, distance(UV, vec2(0.5, 0.45)));
	vec3 c = vec3(0.045, 0.052, 0.046) + vec3(0.03, 0.034, 0.028) * vig + (n - 0.5) * 0.018;
	COLOR = vec4(c, 1.0);
}
"""

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


