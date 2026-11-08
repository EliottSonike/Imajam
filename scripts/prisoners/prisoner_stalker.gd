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
## Temps passé à l'observer sur CAM 06 avant qu'il se lève et force sa porte.
@export var watch_before_escape := 3.0
## Couché dans son lit jusqu'à son tour (actes 0, 1 et 2) : position des pieds sur le matelas.
@export var bed_feet := Vector3(16.24, 0.82, -12.05)  # matelas à ~0,66 m + épaisseur du dos
@export var start_in_bed := true

var state := State.IDLE
var _repath := 0.0
var _retarget := 0.0
var _step_t := 0.0
var _steps: AudioStreamPlayer3D
var _breath: AudioStreamPlayer3D
var _wait_left := 0.0
var _spotted := false
var _yeux: Array[Node3D] = []
var _watched := 0.0
var _in_bed := false
var _stand := Transform3D()


func _ready() -> void:
	super._ready()
	_steps = Sfx.player_3d(self, "step", 3.0, 2.0, false)
	_breath = Sfx.player_3d(self, "breath", 2.0, -3.0, true)
	_breath.position.y = 1.5
	_build_eyes()
	_set_eyes(not GameState.power_on)
	Events.power_changed.connect(_on_power_changed)
	if start_in_bed:
		_lie_down()


## Allongé sur le dos dans son lit, il respire (anim idle).
func _lie_down() -> void:
	_in_bed = true
	_stand = global_transform
	global_position = bed_feet
	rotation = Vector3(0.0, PI, 0.0)  # tête vers l'oreiller (-Z)
	_model.rotation.x = PI / 2.0


## Il se redresse et descend du lit.
func _get_up() -> void:
	if not _in_bed:
		return
	_in_bed = false
	var tw := create_tween().set_parallel()
	tw.tween_property(_model, "rotation:x", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", _stand.origin, 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "rotation:y", _stand.basis.get_euler().y, 0.9)
	await tw.finished


func on_resolved(killed: bool) -> void:
	resolved = true
	_set_eyes(false)
	super.on_resolved(killed)


func start_escape() -> void:
	if resolved:
		return
	state = State.WAITING
	_wait_left = max_wait
	_watched = 0.0


func _break_out(seen: bool) -> void:
	state = State.IDLE  # le temps de sortir du lit
	await _get_up()
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


## Au retour du courant : il arrive dans le dos du joueur (juste son souffle), puis le joueur se retourne
## d'un coup sur le screamer. Pas de réplique : le screamer marche mieux en silence.
func screamer_at(player: Player) -> void:
	stop_stalking()
	_busy = true
	_in_bed = false
	_model.rotation = Vector3.ZERO
	var forward := -player.camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.01 else Vector3.FORWARD
	# derrière lui, sans traverser un mur
	var dist := 1.0
	var from := player.global_position + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, from - forward * 1.3)
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		dist = clampf(from.distance_to(hit.position) - 0.35, 0.45, 1.0)
	global_position = player.global_position - forward * dist
	face_instant(player.global_position)
	set_hidden_from_cameras(false)
	_set_eyes(not GameState.power_on)  # lumière revenue : pas d'yeux rouges
	_play(&"idle")
	player.set_lock(&"encounter", true)
	Sfx.play_at("breath", global_position + Vector3.UP * 1.6, -2.0, 2.0)  # un souffle dans le dos
	await get_tree().create_timer(1.1, false).timeout
	_play(&"attaque", 1.3, 0.05)
	player.face_point(global_position + Vector3.UP * 1.5, 0.14)  # il se retourne d'un coup
	Sfx.play("screamer", 2.0)
	Events.screamer.emit()
	Events.flash.emit(Color(1.0, 1.0, 1.0, 0.9))
	Events.shake.emit(1.4)
	await get_tree().create_timer(0.8, false).timeout
	Events.encounter_requested.emit(self)


func _physics_process(delta: float) -> void:
	if resolved or _busy:
		return
	match state:
		State.WAITING:
			_wait_left -= delta
			if _update_seen(delta):
				_watched += delta
			if _watched >= watch_before_escape:
				_break_out(true)
			elif _wait_left <= 0.0:
				_break_out(_watched > 0.0)
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


## Yeux rouges qui s'allument quand le courant est coupé, pour le repérer dans le noir.
func _build_eyes() -> void:
	if _skeleton == null or _skeleton.find_bone("tete") < 0:
		return
	var attach := BoneAttachment3D.new()
	attach.bone_name = "tete"
	_skeleton.add_child(attach)
	var to_bone := _skeleton.get_bone_global_rest(_skeleton.find_bone("tete")).affine_inverse()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.06, 0.03)
	mat.emission_energy_multiplier = 10.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.016
	mesh.height = 0.032
	mesh.radial_segments = 8
	mesh.rings = 4
	for x in [-0.032, 0.032]:
		var eye := MeshInstance3D.new()
		eye.mesh = mesh
		eye.material_override = mat
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.transform = to_bone * Transform3D(Basis(), Vector3(x, 1.665, 0.094))
		attach.add_child(eye)
		_yeux.append(eye)
	# petite lueur rouge sur le visage
	var lueur := OmniLight3D.new()
	lueur.light_color = Color(1.0, 0.1, 0.05)
	lueur.light_energy = 0.8
	lueur.omni_range = 1.2
	lueur.transform = to_bone * Transform3D(Basis(), Vector3(0.0, 1.66, 0.25))
	attach.add_child(lueur)
	_yeux.append(lueur)


func _set_eyes(on: bool) -> void:
	for n in _yeux:
		n.visible = on and not resolved


func _on_power_changed(on: bool) -> void:
	_set_eyes(not on)
