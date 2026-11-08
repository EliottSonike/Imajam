class_name PrisonerStalker
extends Prisoner

signal reached_generator
signal escaped(seen: bool)
signal spotted

enum State { IDLE, WAITING, ESCAPING, STALKING, CHASING }

@export var cell_door: CellDoor
@export var escape_path: Array[NodePath] = []  # optionnel : sinon chemin calculé
@export var patrol_points: Array[NodePath] = []  # optionnel : sinon couloirs au hasard
@export var generator_spot: Marker3D
@export var run_speed := 3.2
@export var patrol_speed := 1.5
@export var retarget_time := 8.0
@export var chase_speed := 3.4
@export var catch_distance := 1.0
@export var max_wait := 40.0

var state := State.IDLE
var _repath := 0.0
var _retarget := 0.0
var _step_t := 0.0
var _steps: AudioStreamPlayer3D
var _breath: AudioStreamPlayer3D
var _wait_left := 0.0
var _spotted := false


func _ready() -> void:
	super._ready()
	_steps = Sfx.player_3d(self, "step", 3.0, 2.0, false)
	_breath = Sfx.player_3d(self, "breath", 2.0, -3.0, true)
	_breath.position.y = 1.5


func start_escape() -> void:
	if resolved:
		return
	state = State.WAITING
	_wait_left = max_wait


func _break_out(seen: bool) -> void:
	_spotted = seen
	if cell_door:
		cell_door.open()
	var path := PackedVector3Array()
	if not escape_path.is_empty():
		for np in escape_path:
			var n := get_node_or_null(np) as Node3D
			if n:
				path.append(n.global_position)
	elif generator_spot:
		path = PrisonNav.find_path(global_position, generator_spot.global_position)
	_set_path(path, 1)
	state = State.ESCAPING
	escaped.emit(seen)


func start_stalking() -> void:
	if resolved:
		return
	state = State.STALKING
	_breath.play()
	_pick_patrol()


func stop_stalking() -> void:
	state = State.IDLE
	_moving = false
	_breath.stop()


func respawn_far_from(point: Vector3) -> void:
	var t := PrisonNav.random_tile_near(point, 18.0, 30.0)
	global_position = PrisonNav.tile_to_world(t)
	start_stalking()


func debug_place_near(point: Vector3) -> void:
	var t := PrisonNav.random_tile_near(point, 5.0, 8.0)
	global_position = PrisonNav.tile_to_world(t)
	start_stalking()


## Au retour du courant : il est juste devant le joueur.
func screamer_at(player: Player) -> void:
	stop_stalking()
	_busy = true
	var forward := -player.camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	global_position = player.global_position + forward * 1.1
	face_instant(player.global_position)
	set_hidden_from_cameras(false)
	_play(&"attaque", 1.3, 0.05)
	player.set_lock(&"encounter", true)
	Sfx.play("scream", 2.0)
	Dialogue.say(&"detenu_3_screamer")
	Events.screamer.emit()
	Events.flash.emit(Color(1.0, 1.0, 1.0, 0.9))
	Events.shake.emit(1.4)
	await get_tree().create_timer(0.8).timeout
	Events.encounter_requested.emit(self)


func _physics_process(delta: float) -> void:
	if resolved or _busy:
		return
	match state:
		State.WAITING:
			_wait_left -= delta
			if _update_seen(delta):
				_break_out(true)
			elif _wait_left <= 0.0:
				_break_out(false)
		State.ESCAPING:
			if not _spotted and _update_seen(delta):
				_spotted = true
				spotted.emit()
			var player := _player()
			var close := player != null and player.global_position.distance_to(global_position) < 3.0
			if _follow_path(delta, run_speed) or close:
				if generator_spot:
					global_position = generator_spot.global_position
				state = State.IDLE
				_moving = false
				reached_generator.emit()
		State.STALKING, State.CHASING:
			_stalk(delta)


func _stalk(delta: float) -> void:
	var player := _player()
	if player == null:
		return
	var d := player.global_position.distance_to(global_position)
	if d < catch_distance and not player.is_locked():
		stop_stalking()
		Events.player_caught.emit()
		return
	if d < player.noise_radius():
		if state != State.CHASING:
			state = State.CHASING
			_repath = 0.0
	elif state == State.CHASING and d > 12.0:
		state = State.STALKING
		_pick_patrol()

	var speed := patrol_speed
	if state == State.STALKING:
		_retarget -= delta
		if _retarget <= 0.0:
			_pick_patrol()
	if state == State.CHASING:
		speed = chase_speed
		_repath -= delta
		if _repath <= 0.0:
			_repath = 0.4
			_set_path(PrisonNav.find_path(global_position, player.global_position), 1)
			if _path.size() <= 1:
				_path.append(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	if _follow_path(delta, speed) and state == State.STALKING:
		_pick_patrol()

	_step_t -= delta
	if _moving and _step_t <= 0.0:
		_step_t = 0.38 if state == State.CHASING else 0.7
		_steps.pitch_scale = randf_range(0.8, 1.0)
		_steps.play()


func _pick_patrol() -> void:
	_retarget = retarget_time
	var target: Vector3
	if not patrol_points.is_empty():
		var n := get_node_or_null(patrol_points.pick_random()) as Node3D
		target = n.global_position if n else global_position
	else:
		var player := _player()
		var around := player.global_position if player else global_position
		target = PrisonNav.tile_to_world(PrisonNav.random_tile_near(around, 4.0, 14.0))
	_set_path(PrisonNav.find_path(global_position, target), 1)
