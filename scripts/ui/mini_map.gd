class_name MiniMap
extends Control
## Carte en bas à droite pendant la panne, avec la position du joueur.

const MAP_SIZE := Vector2(456, 288)  # le plan à 12 px par case
const MARGIN := 12.0
const MAP_TILE_PX := 24.0  # taille d'une case dans plan_prison.png

var _map: Texture2D


func _ready() -> void:
	var box := MAP_SIZE + Vector2(MARGIN, MARGIN) * 2.0
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -box.x - 24
	offset_right = -24
	offset_top = -box.y - 24
	offset_bottom = -24
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_map = load(MapBoard.MAP_TEXTURE)
	Events.map_taken.connect(_refresh)
	Events.power_changed.connect(func(_on: bool) -> void: _refresh())


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _refresh() -> void:
	var want := GameState.has_map and not GameState.power_on
	if want == visible:
		return
	if want:
		show()
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(hide)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.06, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), false, 1.0)
	if _map == null:
		return
	var origin := Vector2(MARGIN, MARGIN)
	draw_texture_rect(_map, Rect2(origin, MAP_SIZE), false, Color(1, 1, 1, 0.9))
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	var s := MAP_SIZE.x / _map.get_size().x
	var p := origin + PrisonNav.world_to_plan(player.global_position) * MAP_TILE_PX * s
	var fwd3 := -player.global_basis.z
	var fwd := Vector2(fwd3.x, fwd3.z).normalized()
	var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
	draw_line(p, p + fwd * 14.0, Color(0.85, 0.05, 0.05), 2.5)
	draw_circle(p, 5.0, Color(0.9, 0.05, 0.05, blink))
