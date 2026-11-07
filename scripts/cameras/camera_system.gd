class_name CameraSystem
extends Node
## Mode caméras : passer d'une SecurityCamera à l'autre depuis le bureau.

var active := false
var current_id: StringName = &""
var _cams: Array[SecurityCamera] = []
var _index := 0

func _ready() -> void:
	add_to_group(&"camera_system")
	Events.camera_mode_requested.connect(enter)
	_collect_cameras.call_deferred()
	Events.power_changed.connect(_on_power_changed)

func _on_power_changed(on: bool) -> void:
	if not on:
		exit()

func _collect_cameras() -> void:
	_cams.clear()
	for n in get_tree().get_nodes_in_group(&"security_cameras"):
		_cams.append(n)

func enter() -> void:
	if active or _cams.is_empty() or not GameState.power_on:
		return
	active = true
	var p := _player()
	if p:
		p.set_lock(&"cameras", true)
	Events.camera_mode_changed.emit(true)
	_show(_index)

func exit() -> void:
	if not active :
		return
	active = false 
	current_id = &""
	var p := _player()
	if p :
		p.make_view_current()
		p.set_lock(&"cameras", false)
	Events.camera_mode_changed.emit(false)


func is_watching(camera_id: StringName) -> bool:
	return active and current_id == camera_id


func _unhandled_input(event: InputEvent) -> void:
	if not active :
		return
	if event.is_action_pressed(&"cam_next") :
		_show(wrapi(_index + 1, 0, _cams.size()))
	elif event.is_action_pressed(&"cam_prev") :
		_show(wrapi(_index - 1, 0, _cams.size()))
	elif event.is_action_pressed(&"cancel"):
		exit()
	
func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player
	
func _show(i: int) -> void:
	_index = i
	var cam := _cams[i]
	cam.current = true
	current_id = cam.camera_id
	Events.camera_viewed.emit(cam.camera_id)
