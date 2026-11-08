class_name MiniMap
extends Control
## Post-it collé en bas à droite de l'écran : le plan recopié à la main par le garde,
## avec sa position (point rouge) et son champ de vision.
## Affiché dès que la carte est retenue (au bureau, ou décrochée pendant la panne).
## Le plan recopié (plan_postit.png) est généré sur la même grille que plan_prison.png
## (24 px par case) par tools/generate_postit.py.

const POSTIT_TEXTURE := "res://assets/ui/plan_postit.png"
const MAP_TILE_PX := 24.0  # taille d'une case dans plan_postit.png
const NOTE_SIZE := Vector2(290, 196)
const MAP_RECT := Rect2(14, 20, 262, 166)  # zone du plan sur le post-it
const PAPER := Color(0.99, 0.87, 0.36)
const PAPER_DARK := Color(0.93, 0.79, 0.29)
const INK := Color(0.11, 0.17, 0.47)

var _map: Texture2D


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -NOTE_SIZE.x - 30
	offset_right = -30
	offset_top = -NOTE_SIZE.y - 30
	offset_bottom = -30
	pivot_offset = NOTE_SIZE * 0.5
	rotation_degrees = -2.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_map = load(POSTIT_TEXTURE)
	Events.map_taken.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _refresh() -> void:
	var want := GameState.has_map
	if want == visible:
		return
	if want:
		show()
		modulate.a = 0.0
		var y0 := position.y
		position.y = y0 + 40.0
		var tw := create_tween().set_parallel()
		tw.tween_property(self, "modulate:a", 1.0, 0.35)
		tw.tween_property(self, "position:y", y0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(hide)


func _draw() -> void:
	var s := NOTE_SIZE
	# ombre, plus marquée en bas à droite (le coin se décolle un peu)
	draw_colored_polygon(PackedVector2Array([Vector2(6, 9), Vector2(s.x + 5, 7), Vector2(s.x + 9, s.y + 12), Vector2(8, s.y + 8)]), Color(0, 0, 0, 0.35))
	# papier, un peu plus foncé vers le bas
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), Vector2(s.x, s.y), Vector2(0, s.y)]),
		PackedColorArray([PAPER, PAPER, PAPER_DARK, PAPER_DARK]))
	# bande adhésive en haut
	draw_rect(Rect2(0, 0, s.x, 14), Color(0.0, 0.0, 0.0, 0.04))
	# coin bas droit légèrement relevé
	draw_colored_polygon(PackedVector2Array([Vector2(s.x - 22, s.y), Vector2(s.x, s.y - 18), Vector2(s.x, s.y)]), Color(0.86, 0.72, 0.24))
	if _map == null:
		return
	draw_texture_rect(_map, MAP_RECT, false)
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var sc := MAP_RECT.size.x / _map.get_size().x
	var p := MAP_RECT.position + PrisonNav.world_to_plan(player.global_position) * MAP_TILE_PX * sc
	_draw_view_cone(p, player, sc)
	var blink := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 150.0)
	draw_circle(p, 4.0, Color(0.55, 0.0, 0.0, 0.9))
	draw_circle(p, 3.2, Color(0.9, 0.06, 0.05, blink))


## Champ de vision : un cône rouge qui s'estompe, de l'angle réel de la caméra du joueur.
func _draw_view_cone(p: Vector2, player: Player, scale_px: float) -> void:
	var fwd3 := -player.global_basis.z
	var yaw := atan2(fwd3.z, fwd3.x)  # sur le plan : x vers la droite, z vers le bas
	var half := deg_to_rad(37.5)
	if player.camera:
		var aspect := get_viewport_rect().size.aspect()
		half = atan(tan(deg_to_rad(player.camera.fov) * 0.5) * aspect)
	var reach := 6.0 / PrisonNav.TILE * MAP_TILE_PX * scale_px  # environ 6 m
	var steps := 14
	var pts := PackedVector2Array([p])
	var cols := PackedColorArray([Color(0.9, 0.08, 0.05, 0.5)])
	for i in steps + 1:
		pts.append(p + Vector2.from_angle(yaw - half + 2.0 * half * i / steps) * reach)
		cols.append(Color(0.9, 0.08, 0.05, 0.0))
	draw_polygon(pts, cols)
