class_name PrisonerHider
extends Prisoner
## Détenu 1 : caché dans l'angle mort de sa cellule (invisible aux caméras).
## Quand le garde entre, il le bouscule et file dans la prison. Avec le taser, le jeu se fige et on peut
## le neutraliser sur le coup. Sinon le garde sort son pistolet et le traque : une balle suffit,
## mais lui aussi chasse le garde (il fuit quand on le voit, guette, et frappe dans le dos).

signal fled  # il a bousculé le garde : la traque commence

enum Chase { NONE, FLEE, LURK, STALK, STRIKE }

@export var cell_trigger: Area3D
@export var cell_door: CellDoor
@export var hide_spot: Marker3D
@export var flee_speed := 4.2  # le garde court à 5 m/s
@export var stalk_speed := 2.6
@export var strike_speed := 4.8
@export var strike_cooldown := 7.0
@export var hit_distance := 1.25
## Distance à laquelle il détale s'il se sait regardé.
@export var spook_distance := 16.0

var chase := Chase.NONE
var _waiting := false
var _state_t := 0.0
var _repath := 0.0
var _cooldown := 0.0
var _think := 0.0
var _seen := false
var _step_t := 0.0
var _steps: AudioStreamPlayer3D


func _ready() -> void:
	if attack_line == &"":
		attack_line = &"detenu_1_attaque"
	super._ready()
	_steps = Sfx.player_3d(self, "step", 4.0, 4.0, false)
	if cell_trigger:
		cell_trigger.body_entered.connect(_on_cell_trigger_body_entered)


func start_escape() -> void:
	set_hidden_from_cameras(true)
	if hide_spot:
		global_position = hide_spot.global_position
		rotation.y = hide_spot.global_rotation.y
	_waiting = true
	_pose = &"accroupi"


func is_hiding() -> bool:
	return _waiting


## Avant son tour il attend debout dans sa cellule et peut fixer la caméra.
func _can_stare() -> bool:
	return not _waiting and super._can_stare()


func _on_cell_trigger_body_entered(body: Node3D) -> void:
	if _waiting and not resolved and body is Player:
		_ambush(body as Player)


## Il jaillit, bouscule le garde, puis : taser (si on l'a et qu'on le choisit) ou traque.
func _ambush(p: Player) -> void:
	_waiting = false
	_pose = &""
	_busy = true
	set_hidden_from_cameras(false)
	p.set_lock(&"encounter", true)
	face_instant(p.global_position)
	p.face_point(global_position + Vector3.UP * 1.5, 0.35)
	_play(&"idle")
	await Dialogue.say(attack_line)  # « Coucou, j'étais bien caché ? »
	await get_tree().create_timer(0.15, false).timeout
	if resolved:
		return
	# il fonce et le bouscule
	var to_me := global_position - p.global_position
	to_me.y = 0.0
	var target := p.global_position + to_me.normalized() * 0.75
	target.y = global_position.y
	_play(&"attaque", 1.3, 0.1)
	Sfx.play("screamer", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Events.shake.emit(1.2)
	Events.flash.emit(Color(0.5, 0.0, 0.0, 0.35))
	p.push(p.global_position - global_position, 6.0)
	await get_tree().create_timer(0.25, false).timeout

	var tase := false
	var panel := ActionPanel.find(get_tree())
	if panel and GameState.has_item(GameState.ITEM_TASER):
		var pick := await panel.choose("Détenu %d — %s" % [prisoner_id, display_name],
			Texts.ENCOUNTERS.get(prisoner_id, ""), ["Taser", "Le poursuivre (pistolet)"])
		tase = pick == 0
	if tase:
		GameState.resolve_prisoner(prisoner_id, false)
		Events.encounter_resolved.emit(prisoner_id, false)
		await get_tree().create_timer(1.0, false).timeout
		p.set_lock(&"encounter", false)
		return
	# il file dans la prison : traque
	_busy = false
	p.set_lock(&"encounter", false)
	p.draw_gun(true)
	_cooldown = 4.0  # il ne revient pas frapper tout de suite
	_start_flee()
	fled.emit()
	Events.prisoner_fled.emit(prisoner_id)


## Une balle et c'est fini.
func on_shot(_by: Node) -> bool:
	if chase == Chase.NONE or resolved:
		return false
	chase = Chase.NONE
	_shot_by_gun = true
	_moving = false
	GameState.resolve_prisoner(prisoner_id, true)
	Events.encounter_resolved.emit(prisoner_id, true)
	_holster_later()
	return true


func _holster_later() -> void:
	await get_tree().create_timer(1.4, false).timeout
	var p := _player()
	if p:
		p.draw_gun(false)


func _physics_process(delta: float) -> void:
	if chase == Chase.NONE or resolved or _busy or GameState.is_dead():
		return
	var p := _player()
	if p == null:
		return
	_cooldown -= delta
	_state_t -= delta
	_think -= delta
	if _think <= 0.0:
		_think = 0.15
		_seen = _player_sees_me(p)
	var d := global_position.distance_to(p.global_position)
	match chase:
		Chase.FLEE:
			if _follow_path(delta, flee_speed):
				_start_lurk()
		Chase.LURK:
			if _seen and d < spook_distance:
				_start_flee()
			elif d < 9.0 and _cooldown <= 0.0 and not _player_faces(p, 0.2) and _clear_line(p):
				_start_strike()  # le garde lui tourne le dos : il fonce
			elif _state_t <= 0.0:
				_start_stalk()
		Chase.STALK:
			if _seen and d < spook_distance:
				_start_flee()
			elif d < 5.0 and _cooldown <= 0.0:
				_start_strike()
			else:
				_repath -= delta
				if _repath <= 0.0:
					_repath = 0.7
					_set_path(PrisonNav.find_path(global_position, p.global_position), 1)
				_follow_path(delta, stalk_speed)
		Chase.STRIKE:
			# lancé, il ne recule plus : c'est le moment de tirer
			_repath -= delta
			if _repath <= 0.0:
				_repath = 0.25
				_set_path(PrisonNav.find_path(global_position, p.global_position), 1)
				if _path.size() <= 1:
					_path.append(Vector3(p.global_position.x, global_position.y, p.global_position.z))
			_follow_path(delta, strike_speed)
			if d < hit_distance:
				_hit(p)
			elif _state_t <= 0.0:
				_start_flee()  # il abandonne
	_footsteps(delta)


func _process(delta: float) -> void:
	if chase == Chase.LURK:
		_pose = &"accroupi"
	elif chase != Chase.NONE:
		_pose = &""
	super._process(delta)


func _hit(p: Player) -> void:
	_busy = true
	_moving = false
	face_instant(p.global_position)
	_play(&"attaque", 1.4, 0.05)
	p.take_hit(global_position)
	_cooldown = strike_cooldown
	await get_tree().create_timer(0.45, false).timeout
	_busy = false
	if not resolved and chase != Chase.NONE:
		_start_flee()


## Fuite vers un couloir loin du garde, par un chemin qui ne repasse pas devant lui.
func _start_flee() -> void:
	chase = Chase.FLEE
	var p := _player()
	var best := PackedVector3Array()
	var best_score := -INF
	for i in 10:
		var tile := PrisonNav.random_tile_near(global_position, 8.0, 22.0)
		var path := PrisonNav.find_path(global_position, PrisonNav.tile_to_world(tile))
		if path.size() < 2:
			continue
		var score := 0.0
		if p:
			score = path[path.size() - 1].distance_to(p.global_position)
			for q in path:
				if q.distance_to(p.global_position) < 2.5:
					score -= 30.0
					break
		if score > best_score:
			best_score = score
			best = path
	_set_path(best, 1)


func _start_lurk() -> void:
	chase = Chase.LURK
	_moving = false
	_state_t = randf_range(3.0, 6.0)


func _start_stalk() -> void:
	chase = Chase.STALK
	_repath = 0.0


func _start_strike() -> void:
	chase = Chase.STRIKE
	_repath = 0.0
	_state_t = 6.0


## Le garde le regarde (au centre de l'écran, pas de mur entre eux) ?
func _player_sees_me(p: Player) -> bool:
	if global_position.distance_to(p.global_position) > 25.0:
		return false
	var cam := p.camera
	var to_me := (global_position + Vector3.UP * 1.2 - cam.global_position).normalized()
	return -cam.global_basis.z.dot(to_me) > 0.82 and _clear_line(p)


## Le garde est-il tourné vers lui (plan horizontal) ?
func _player_faces(p: Player, threshold: float) -> bool:
	var fwd := -p.camera.global_basis.z
	fwd.y = 0.0
	var to_me := global_position - p.global_position
	to_me.y = 0.0
	if fwd.length() < 0.01 or to_me.length() < 0.01:
		return true
	return fwd.normalized().dot(to_me.normalized()) > threshold


func _clear_line(p: Player) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, p.camera.global_position)
	query.collision_mask = 1
	query.exclude = [_body.get_rid(), p.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Ses pas : on l'entend courir (et arriver).
func _footsteps(delta: float) -> void:
	if not _moving:
		return
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.3 if chase in [Chase.FLEE, Chase.STRIKE] else 0.5
		_steps.pitch_scale = randf_range(0.85, 1.05)
		_steps.play()
