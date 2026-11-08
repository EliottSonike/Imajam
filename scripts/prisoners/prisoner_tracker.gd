class_name PrisonerTracker
extends Prisoner
## Détenu 2 : épisode psychotique, à suivre de caméra en caméra.

signal located

@export var cell_door: CellDoor
@export var waypoints: Array[NodePath] = []
@export var arrival_trigger: Area3D
@export var destination: Marker3D
@export var attack_distance := 2.2

var _active := false
var _arrived := false


func _ready() -> void:
	super._ready()
	if arrival_trigger:
		arrival_trigger.body_entered.connect(_on_arrival_trigger_body_entered)


func start_escape() -> void:
	if cell_door:
		cell_door.open()
	var path := PackedVector3Array()
	if not waypoints.is_empty():
		for np in waypoints:
			var n := get_node_or_null(np) as Node3D
			if n:
				path.append(n.global_position)
	elif destination:
		path = PrisonNav.find_path(global_position, destination.global_position)
	_set_path(path, 1)
	_active = true


func _physics_process(delta: float) -> void:
	if not _active or resolved or _busy:
		return
	var player := _player()
	if player and not player.is_locked() and player.global_position.distance_to(global_position) < attack_distance:
		_active = false
		attack_player()
		return
	if _arrived:
		return
	if _can_move():
		if _follow_path(delta, walk_speed):
			_arrived = true
			located.emit()
	else:
		_moving = false


func _can_move() -> bool:
	var cams := cameras_seeing(global_position + Vector3.UP * 1.0)
	if cams.is_empty():
		return true
	var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
	return sys != null and sys.active and cams.has(sys.current_id)


func cameras_seeing(point: Vector3) -> Array[StringName]:
	var out: Array[StringName] = []
	var space := get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group(&"security_cameras"):
		var cam := node as SecurityCamera
		if cam == null or not cam.is_position_in_frustum(point):
			continue
		var query := PhysicsRayQueryParameters3D.create(cam.global_position, point)
		query.collision_mask = 1  # seulement les murs et le décor
		query.exclude = [_body.get_rid()]
		if space.intersect_ray(query).is_empty():
			out.append(cam.camera_id)
	return out


func _on_arrival_trigger_body_entered(body: Node3D) -> void:
	if _active and _arrived and not resolved and not _busy and body is Player:
		_active = false
		attack_player()
