class_name PrisonerCrisis
extends Prisoner
## Détenu 2 : épisode psychotique.

signal escaped(seen: bool)
signal spotted(where: StringName)
signal arrived  # arrivé au réfectoire
signal calmed  # négociation réussie

enum State { IDLE, WAITING, ESCAPING, REFECTOIRE, TALKING, CALM }

@export var cell_door: CellDoor
@export var kitchen_tile := Vector2i(22, 3)
@export var refectoire_tile := Vector2i(16, 3)
@export var run_speed := 2.4
## Arrêts du trajet vers les cuisines, chacun bien visible sur une caméra (Bloc B, Couloir central).
@export var route_stops: Array[Vector3] = [Vector3(39.9, 0.0, -8.5), Vector3(28.6, 0.0, -17.5)]
@export var route_pauses: Array[float] = [2.2, 1.4]
## Temps passé à fouiller les cuisines (CAM 15) avant de ressortir avec le couteau.
@export var kitchen_search := 3.6
@export var talk_distance := 5.0
@export var max_wait := 40.0
## Temps pendant lequel le joueur doit l'avoir vu sur CAM 09 avant qu'il force sa porte
## (sinon il s'évade à l'instant même où l'écran s'allume, en plein milieu de la réplique).
@export var watch_before_escape := 3.0
## Actes 0 et 1 : recroquevillé dans un coin de sa cellule, bien visible sur CAM 09.
@export var curl_position := Vector3(44.2, 0.0, -4.5)
@export var curl_yaw := PI / 2.0

var state := State.IDLE
var _wait_left := 0.0
var _watched := 0.0
var _curled := true
var _leg := 0  # 0 : vers les cuisines, 1 : couteau en main, vers le réfectoire
var _stops: Array[Vector3] = []
var _stop_i := 0
var _pause := 0.0
var _searching := false
var _spotted_kitchen := false
var _spotted_route := false
var _spotted_refectoire := false
var _agitation := 1.0
var _knife: Node3D
var _twitch_t := 0.0
var _twitch_target := 0.0


func _ready() -> void:
	super._ready()
	global_position = curl_position
	rotation.y = curl_yaw
	_build_knife()
	Events.talk_finished.connect(_on_talk_finished)


func start_escape() -> void:
	if resolved:
		return
	state = State.WAITING
	_wait_left = max_wait
	_watched = 0.0
	_curled = false


func on_talk_answer(effect: int) -> void:
	_agitation = clampf(_agitation - 0.3 * effect, 0.15, 1.4)


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
			_escape_step(delta)
			if _leg == 1:
				_check_player_close()
		State.REFECTOIRE:
			if not _spotted_refectoire and _update_seen(delta):
				_spotted_refectoire = true
				spotted.emit(&"refectoire")
			_check_player_close()


func _break_out(seen: bool) -> void:
	state = State.ESCAPING
	_leg = 0
	_spotted_route = seen
	if cell_door:
		cell_door.open()
	# trajet : arrêts devant les caméras, puis les cuisines, puis le réfectoire
	_stops = route_stops.duplicate()
	_stops.append(PrisonNav.tile_to_world(kitchen_tile))
	_stops.append(PrisonNav.tile_to_world(refectoire_tile))
	_stop_i = 0
	_pause = 0.0
	_go_to_stop()
	escaped.emit(seen)


## Le détecteur de mouvement le signale pendant toute sa fuite, arrêts compris.
func shows_motion() -> bool:
	return not resolved and not _busy and state in [State.ESCAPING, State.REFECTOIRE]


func _go_to_stop() -> void:
	_set_path(PrisonNav.find_path(global_position, _stops[_stop_i]), 1)


func _escape_step(delta: float) -> void:
	var seen := _update_seen(delta)
	if seen and not _spotted_route:
		_spotted_route = true
		spotted.emit(&"route")
	if _searching and seen and not _spotted_kitchen:
		_spotted_kitchen = true
		spotted.emit(&"cuisine")
	if _pause > 0.0:
		_pause -= delta
		_moving = false
		if _searching and _pause <= kitchen_search * 0.4 and not _knife.visible:
			_knife.visible = true  # il a trouvé un couteau
			Sfx.play_at("pickup", global_position + Vector3.UP, -4.0, 2.0)
		if _pause <= 0.0:
			_searching = false
			_stop_i += 1
			_go_to_stop()
		return
	if not _follow_path(delta, run_speed):
		return
	var last := _stops.size() - 1
	if _stop_i == last:
		state = State.REFECTOIRE
		_moving = false
		arrived.emit()
	elif _stop_i == last - 1:
		# cuisines : il fouille, dos à la porte, puis repart couteau en main
		_leg = 1
		_searching = true
		_pause = kitchen_search
		rotation.y += PI * 0.6
	else:
		_pause = route_pauses[_stop_i] if _stop_i < route_pauses.size() else 1.0
		# il lève la tête vers la caméra la plus proche (il parle aux caméras)
		var cam := _nearest_camera()
		if cam:
			face_instant(cam.global_position)


func _nearest_camera() -> SecurityCamera:
	var best: SecurityCamera = null
	for c in get_tree().get_nodes_in_group(&"security_cameras"):
		if camera_sees(c) and (best == null or c.global_position.distance_to(global_position) < best.global_position.distance_to(global_position)):
			best = c
	return best


func _check_player_close() -> void:
	var p := _player()
	if p == null or p.is_locked():
		return
	var in_room := state == State.REFECTOIRE and PrisonNav.room_at(p.global_position) == "F"
	if in_room or p.global_position.distance_to(global_position) < talk_distance:
		_start_talk(p)


func _start_talk(p: Player) -> void:
	state = State.TALKING
	_moving = false
	p.set_lock(&"talk", true)
	face_instant(p.global_position)
	p.face_point(global_position + Vector3.UP * 1.5, 0.4)
	await Dialogue.say(&"detenu_2_couteau")
	if state == State.TALKING:
		Events.talk_requested.emit(self)


func _on_talk_finished(id: int, success: bool) -> void:
	if id != prisoner_id or state != State.TALKING:
		return
	var p := _player()
	if success:
		state = State.CALM
		resolved = true
		_drop_knife()
		_sit_down()
		if p:
			p.set_lock(&"talk", false)
		calmed.emit()
	else:
		state = State.IDLE
		taser_allowed = false
		attack_player()
		if p:
			p.set_lock(&"talk", false)


func _process(delta: float) -> void:
	_pose = &"agite" if state in [State.WAITING, State.REFECTOIRE, State.TALKING] or (state == State.ESCAPING and _pause > 0.0) else &""
	if _curled and state == State.IDLE:
		_pose = &"assis_boucle"
	super._process(delta)
	if resolved or _busy or _model == null or state == State.IDLE:
		return
	_twitch_t -= delta
	if _twitch_t <= 0.0:
		_twitch_t = randf_range(0.08, 0.35)
		_twitch_target = randf_range(-0.35, 0.35) * _agitation
	_model.rotation.y = lerpf(_model.rotation.y, _twitch_target, minf(1.0, 20.0 * delta))
	_model.rotation.x = randf_range(-0.04, 0.04) * _agitation


## Recroquevillé dans sa cellule avant son tour : il ne tourne que la tête.
func _can_stare() -> bool:
	return state == State.IDLE and super._can_stare()


func _can_turn_body() -> bool:
	return false


## Le couteau fait partie du modèle, accroché à la main droite.
func _build_knife() -> void:
	_knife = _model.find_child("Couteau", true, false) as Node3D
	if _knife == null:
		_knife = Node3D.new()
		_model.add_child(_knife)
	_knife.visible = false


func _drop_knife() -> void:
	if _knife == null or not _knife.visible:
		return
	_knife.reparent(self)
	var tw := create_tween().set_parallel()
	tw.tween_property(_knife, "position", Vector3(0.35, 0.02, -0.45), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_knife, "rotation", Vector3(0.0, 0.6, PI / 2.0), 0.45)  # lame à plat
	Sfx.play("pickup", -10.0, 0.6)


## Il s'assoit par terre et se recroqueville.
func _sit_down() -> void:
	var tw := create_tween()
	tw.tween_property(_model, "rotation", Vector3.ZERO, 0.4)
	_play(&"assis", 1.0, 0.3)
	if _anim:
		_anim.queue(&"assis_boucle")
