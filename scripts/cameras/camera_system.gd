class_name CameraSystem
extends Node
## Mode caméras : passer d'une SecurityCamera à l'autre depuis le bureau.

var active := false
var current_id: StringName = &""
var _cams: Array[SecurityCamera] = []
var _index := 0
## Détecteur de mouvement : index de la caméra (autre que celle affichée) qui filme un détenu en déplacement, -1 sinon.
var motion_index := -1
var _motion_check := 0.0

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


## Caméra affichée (null hors du mode caméras).
func current_camera() -> SecurityCamera:
	if not active or _cams.is_empty():
		return null
	return _cams[_index]


func camera_number() -> int:
	return _index + 1


func _process(delta: float) -> void:
	if not active:
		motion_index = -1
		return
	_motion_check -= delta
	if _motion_check > 0.0:
		return
	_motion_check = 0.25
	var movers: Array = get_tree().get_nodes_in_group(&"prisoners").filter(func(p: Node) -> bool: return p.shows_motion())
	# on garde la même caméra tant qu'elle filme encore le mouvement
	if motion_index >= 0 and motion_index != _index and _sees_any(_cams[motion_index], movers):
		return
	motion_index = -1
	for i in _cams.size():
		if i != _index and _sees_any(_cams[i], movers):
			motion_index = i
			return


func _sees_any(cam: SecurityCamera, movers: Array) -> bool:
	for p in movers:
		if p.camera_sees(cam):
			return true
	return false


## Aller à la caméra qui détecte du mouvement.
func jump_to_motion() -> void:
	if motion_index >= 0 and motion_index != _index:
		var i := motion_index
		motion_index = -1
		_show(i)


func motion_camera() -> SecurityCamera:
	return _cams[motion_index] if motion_index >= 0 and motion_index < _cams.size() else null


func _unhandled_input(event: InputEvent) -> void:
	if not active :
		return
	if event.is_action_pressed(&"interact") or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_SPACE):
		jump_to_motion()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"cam_next") :
		_show(wrapi(_index + 1, 0, _cams.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cam_prev") :
		_show(wrapi(_index - 1, 0, _cams.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"cancel"):
		exit()
		get_viewport().set_input_as_handled()

func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player

func _show(i: int) -> void:
	_index = i
	var cam := _cams[i]
	cam.current = true
	current_id = cam.camera_id
	Sfx.play("static", -14.0)
	Events.camera_viewed.emit(cam.camera_id)
