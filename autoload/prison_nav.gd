extends Node

const TILE := 1.4
const OFFSET := Vector3(-4.2, 0.0, -28.0)
const ROOMS := "B123RIGFKDLVAPx"
const PLAN := """
...............................GGGG...
....111......FFFFFFF.KKKK......GGGG...
....111......FFFFFFF+KKKK......GGGG...
....111.....+FFFFFFF.KKKK......GGGG...
.CCCC+CCCCC.CFFFFFFF.KKKK.......+.....
.C........C.CFFFFFFF..+.........C.....
.C........C.C...+.....C......CCCC.....
.C........CCCCCCCCCCCCCCCC...C........
.C.CCC+CCC........C......CLLLCCCCCCCC.
.C.C.RRR.C........CIIII..+LLL.......C.
.C.C.RRR.C..333...+IIII..CLLL.......C.
.C.C.RRR.C..333...CIIII..CCCCCCC....C.
.CCC.....C..333...CIIII........C....C.
...C.AAA.C...+....C.+CCCC......CCCCCC.
...C+AAA.CCCCC+CCCC.....C......C......
...C.AAA....CDDDD.......C......C222...
...C........CDDDD.......CCCC...+222...
.CC+CCCC+CCCCDDDD.......C......C222...
.BBBB..VVV..CCCC+CCC....C......C......
.BBBB..VVV....PPPPPC....C......C......
.BBBB..VVV....PPPPP+....C......C......
.BBBB.........PPPPPCCCCCCCCCCCCCCCC...
..............PPPPP...................
......................................
"""

var rows := 0
var cols := 0
var _plan: PackedStringArray = []
var _astar := AStar2D.new()


func _ready() -> void:
	for line in PLAN.split("\n"):
		if line.strip_edges() != "":
			_plan.append(line)
	rows = _plan.size()
	for line in _plan:
		cols = maxi(cols, line.length())
	_build()


func region(t: Vector2i) -> String:
	if t.x < 0 or t.y < 0 or t.y >= rows:
		return ""
	var line: String = _plan[t.y]
	if t.x >= line.length():
		return ""
	var ch := line[t.x]
	if ch == "+":
		return "C"
	if ch == "C" or ROOMS.contains(ch):
		return ch
	return ""


func is_door(t: Vector2i) -> bool:
	return region(t) == "C" and _plan[t.y][t.x] == "+"


func is_walkable(t: Vector2i) -> bool:
	return region(t) != ""


func passable(a: Vector2i, b: Vector2i) -> bool:
	var ra := region(a)
	var rb := region(b)
	if ra == "" or rb == "":
		return false
	return ra == rb or is_door(a) or is_door(b)


func tile_to_world(t: Vector2i, y := 0.0) -> Vector3:
	return Vector3((t.x + 0.5) * TILE, y, (t.y + 0.5) * TILE) + OFFSET


func world_to_tile(p: Vector3) -> Vector2i:
	var q := p - OFFSET
	return Vector2i(floori(q.x / TILE), floori(q.z / TILE))


func world_to_plan(p: Vector3) -> Vector2:
	var q := p - OFFSET
	return Vector2(q.x / TILE, q.z / TILE)


func room_at(p: Vector3) -> String:
	return region(world_to_tile(p))


func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var a := _nearest_walkable(world_to_tile(from))
	var b := _nearest_walkable(world_to_tile(to))
	if a.x < 0 or b.x < 0:
		return out
	for v in _astar.get_point_path(_id(a), _id(b)):
		out.append(tile_to_world(Vector2i(int(v.x), int(v.y))))
	return out


func random_tile_near(p: Vector3, rmin: float, rmax: float, corridors_only := true) -> Vector2i:
	var center := world_to_tile(p)
	var r := int(ceil(rmax / TILE))
	var candidates: Array[Vector2i] = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var t := center + Vector2i(dx, dy)
			var reg := region(t)
			if reg == "" or (corridors_only and reg != "C"):
				continue
			var d := Vector2(dx, dy).length() * TILE
			if d >= rmin and d <= rmax:
				candidates.append(t)
	if candidates.is_empty():
		return _nearest_walkable(center)
	return candidates.pick_random()


func _id(t: Vector2i) -> int:
	return t.y * cols + t.x


func _nearest_walkable(t: Vector2i) -> Vector2i:
	if is_walkable(t):
		return t
	var id := _astar.get_closest_point(Vector2(t))
	if id < 0:
		return Vector2i(-1, -1)
	var p := _astar.get_point_position(id)
	return Vector2i(int(p.x), int(p.y))


func _build() -> void:
	for r in rows:
		for c in cols:
			var t := Vector2i(c, r)
			if is_walkable(t):
				_astar.add_point(_id(t), Vector2(c, r))
	for r in rows:
		for c in cols:
			var t := Vector2i(c, r)
			if not is_walkable(t):
				continue
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var n: Vector2i = t + d
				if passable(t, n):
					_astar.connect_points(_id(t), _id(n))
