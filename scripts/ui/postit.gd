class_name PostIt
extends Control
## Post-it en bas à droite : carte + position du joueur pendant la panne.
## N'apparaît que si le joueur a appuyé sur « Retenir » devant la carte du bureau.

const SIZE := Vector2(300, 220)
const MAP_TILE_PX := 24.0  ## taille d'une case dans plan_prison.png

var _map: Texture2D


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -SIZE.x - 30
	offset_right = -30
	offset_top = -SIZE.y - 30
	offset_bottom = -30
	pivot_offset = SIZE / 2.0
	rotation = deg_to_rad(-3.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_map = load(MapBoard.MAP_TEXTURE)
	Events.power_changed.connect(_on_power_changed)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _on_power_changed(on: bool) -> void:
	if on or not GameState.has_map_memory:
		if visible:
			var tw := create_tween()
			tw.tween_property(self, "modulate:a", 0.0, 0.4)
			tw.tween_callback(hide)
		return
	show()
	modulate.a = 1.0
	position.y += 260.0
	create_tween().tween_property(self, "position:y", position.y - 260.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	# le papier jaune
	draw_rect(Rect2(Vector2(4, 6), SIZE), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.98, 0.9, 0.42))
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, 22)), Color(0.93, 0.83, 0.33))
	var font := get_theme_default_font()
	draw_string(font, Vector2(10, 16), "plan (de mémoire)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.3, 0.25, 0.1))
	if _map == null:
		return
	# la carte, réduite
	var area := Rect2(Vector2(10, 28), SIZE - Vector2(20, 38))
	var tex_size := _map.get_size()
	var s := minf(area.size.x / tex_size.x, area.size.y / tex_size.y)
	var draw_size := tex_size * s
	var origin := area.position + (area.size - draw_size) / 2.0
	draw_texture_rect(_map, Rect2(origin, draw_size), false, Color(1, 1, 1, 0.85))
	# le joueur : un point rouge et sa direction
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var p := origin + PrisonNav.world_to_plan(player.global_position) * MAP_TILE_PX * s
	var fwd3 := -player.global_basis.z
	var fwd := Vector2(fwd3.x, fwd3.z).normalized()
	var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
	draw_line(p, p + fwd * 10.0, Color(0.8, 0.05, 0.05), 2.0)
	draw_circle(p, 4.0, Color(0.85, 0.05, 0.05, blink))
