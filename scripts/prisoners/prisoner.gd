class_name Prisoner
extends Node3D
## Base des trois psychopathes.

const HIDDEN_FROM_CAMERAS_LAYER := 2
const MODELE := preload("res://models/prisonnier.glb")
## Tenue par détenu (le 1 garde la combinaison orange d'origine).
const TENUES := {
	2: preload("res://models/prisonnier_tenue_blanc.png"),
	3: preload("res://models/prisonnier_tenue_rouge.png"),
}
const ANIM_BOUCLES: Array[StringName] = [&"idle", &"marche", &"course", &"accroupi", &"assis_boucle", &"agite"]
## Regardé trop longtemps à l'écran, il tourne lentement la tête vers la caméra (puis le corps s'il est debout).
const STARE_DELAY := 4.0  # s à l'écran avant qu'il réagisse
const STARE_TURN := 1.6  # s pour tourner la tête
const STARE_BODY_SPEED := 0.5  # rad/s quand il pivote en entier

@export var prisoner_id := 0
@export var display_name := ""
@export var walk_speed := 1.4
@export var attack_line: StringName = &""

var taser_allowed := true

var resolved := false
var _shot_by_gun := false  # abattu au pistolet par le garde : le coup de feu a déjà été entendu

var _model: Node3D
var _anim: AnimationPlayer
var _skeleton: Skeleton3D
var _pose := &""  # anim imposée par le comportement (accroupi, agite...)
var _last_pos := Vector3.ZERO
var _speed := 0.0
var _body: AnimatableBody3D
var _body_shape: CollisionShape3D
var _path := PackedVector3Array()
var _path_i := 0
var _moving := false
var _busy := false
var _seen_cache := false
var _seen_check := 0.0
var _stare_t := 0.0
var _stare_w := 0.0
var _stare_locked := false
var _look_target: Node3D
var _look_head: LookAtModifier3D
var _look_torso: LookAtModifier3D


func _ready() -> void:
	add_to_group(&"prisoners")
	if display_name == "":
		display_name = Texts.PRISONER_NAMES.get(prisoner_id, "")
	_build_model()
	_last_pos = global_position
	Events.encounter_resolved.connect(_on_encounter_resolved)


func _process(delta: float) -> void:
	if delta > 0.0:
		var flat := global_position - _last_pos
		flat.y = 0.0
		_speed = lerpf(_speed, flat.length() / delta, minf(1.0, 10.0 * delta))
	_last_pos = global_position
	_update_stare(delta)
	if resolved or _busy or _anim == null:
		return
	if _pose != &"":
		_play(_pose)
	elif _moving and _speed > 2.2:
		_play(&"course", _speed / 3.2)
	elif _moving and _speed > 0.2:
		_play(&"marche", _speed / 1.4)
	else:
		_play(&"idle")


func _play(anim_name: StringName, speed := 1.0, blend := 0.25) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if _anim.current_animation != anim_name:
		_anim.play(anim_name, blend)
	_anim.speed_scale = clampf(speed, 0.5, 1.6)


func start_escape() -> void:
	pass


func attack_player() -> void:
	var player := _player()
	if player == null or resolved:
		return
	_busy = true
	_moving = false
	player.set_lock(&"encounter", true)
	set_hidden_from_cameras(false)
	face_instant(player.global_position)
	player.face_point(global_position + Vector3.UP * 1.5, 0.35)
	# la réplique (« Coucou, j'étais bien caché ? ») d'abord, puis le screamer : ils ne se chevauchent plus
	if attack_line != &"":
		_play(&"idle")
		await Dialogue.say(attack_line)
		await get_tree().create_timer(0.25, false).timeout
		if resolved:
			return
	var to_me := global_position - player.global_position
	to_me.y = 0.0
	var target := player.global_position + to_me.normalized() * 0.95
	target.y = global_position.y
	face_instant(player.global_position)
	player.face_point(global_position + Vector3.UP * 1.5, 0.2)
	_play(&"attaque", 1.0, 0.1)
	Sfx.play("screamer", -1.0)
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Events.shake.emit(1.0)
	Events.flash.emit(Color(0.6, 0.0, 0.0, 0.55))
	player.face_point(global_position + Vector3.UP * 1.5, 0.15)
	await get_tree().create_timer(0.45, false).timeout
	Events.encounter_requested.emit(self)


func on_resolved(killed: bool) -> void:
	resolved = true
	_busy = true
	_moving = false
	set_hidden_from_cameras(false)
	if _anim:
		_anim.speed_scale = 1.0
		_anim.play(&"idle", 0.15)
	if killed:
		if not _shot_by_gun:  # abattu au pistolet par le garde : le coup de feu a déjà retenti
			Sfx.play("gunshot")
			Events.flash.emit(Color(1.0, 0.85, 0.55, 0.8))
			Events.shake.emit(0.8)
	else:
		Sfx.play("taser")
		Sfx.play_at("cri_taser" if Sfx.has_sound("cri_taser") else "scream", global_position + Vector3.UP * 1.5, 2.0, 6.0)
		Events.flash.emit(Color(0.4, 0.6, 1.0, 0.6))
		var shiver := create_tween()
		for i in 10:
			shiver.tween_property(_model, "rotation:z", 0.09 if i % 2 == 0 else -0.09, 0.05)
		await shiver.finished
	var fall := create_tween().set_parallel()
	fall.tween_property(_model, "rotation", Vector3(deg_to_rad(-88.0), 0.0, 0.0), 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.tween_property(_model, "position:y", 0.14, 0.7)
	_body_shape.set_deferred("disabled", true)
	await fall.finished
	if _anim:
		_anim.pause()


## Touché par une balle du garde. Renvoie vrai si ça compte (sinon la balle s'écrase sur lui sans effet).
func on_shot(_by: Node) -> bool:
	return false


func set_hidden_from_cameras(hidden: bool) -> void:
	for vi in _model.find_children("*", "VisualInstance3D", true, false):
		(vi as VisualInstance3D).layers = (1 << (HIDDEN_FROM_CAMERAS_LAYER - 1)) if hidden else 1


func seen_on_screen() -> bool:
	var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
	return sys != null and sys.active and camera_sees(sys.current_camera())


func _update_seen(delta: float) -> bool:
	_seen_check -= delta
	if _seen_check <= 0.0:
		_seen_check = 0.2
		_seen_cache = seen_on_screen()
	return _seen_cache


func camera_sees(cam: SecurityCamera) -> bool:
	if cam == null:
		return false
	var point := global_position + Vector3.UP * 1.0
	if not cam.is_position_in_frustum(point):
		return false
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, point)
	query.collision_mask = 1  # seulement les murs et le décor
	query.exclude = [_body.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Peut-il fixer la caméra ? Seulement à l'arrêt, hors action.
func _can_stare() -> bool:
	return not resolved and not _busy and not _moving


## Peut-il pivoter tout le corps vers la caméra (debout) ? Sinon seulement la tête.
func _can_turn_body() -> bool:
	return true


func _update_stare(delta: float) -> void:
	if _look_head == null:
		return
	var cam: SecurityCamera = null
	if _can_stare() and _update_seen(delta):
		var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
		cam = sys.current_camera() if sys else null
	if cam:
		_stare_t += delta
		_look_target.global_position = cam.global_position
	else:
		_stare_t = 0.0
	var staring := _stare_t >= STARE_DELAY
	_stare_w = move_toward(_stare_w, 1.0 if staring else 0.0, delta / STARE_TURN)
	var w := smoothstep(0.0, 1.0, _stare_w)
	var body := _can_turn_body()
	_look_head.influence = w
	_look_head.active = w > 0.0
	_look_torso.influence = w * (0.4 if body else 0.0)
	_look_torso.active = _look_torso.influence > 0.0
	# il a croisé ton regard : petit grésillement sur l'écran
	if staring and _stare_w >= 1.0 and not _stare_locked:
		_stare_locked = true
		Sfx.play("static", -16.0, 0.55)
	elif not staring:
		_stare_locked = false
	# puis il se tourne lentement face à la caméra
	if body and staring and _stare_t > STARE_DELAY + STARE_TURN:
		var d := _look_target.global_position - global_position
		if Vector2(d.x, d.z).length() > 0.1:
			rotation.y = rotate_toward(rotation.y, atan2(-d.x, -d.z), STARE_BODY_SPEED * delta)


func face_instant(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


func _set_path(path: PackedVector3Array, start_index := 0) -> void:
	_path = path
	_path_i = mini(start_index, maxi(path.size() - 1, 0))


## Avance vers la fin du chemin.
func _follow_path(delta: float, speed: float) -> bool:
	if _path_i >= _path.size():
		_moving = false
		return true
	_moving = true
	var target := _path[_path_i]
	target.y = global_position.y
	var to := target - global_position
	var step := speed * delta
	if to.length() <= step:
		global_position = target
		_path_i += 1
		if _path_i >= _path.size():
			_moving = false
			return true
		return false
	global_position += to.normalized() * step
	var yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(1.0, 10.0 * delta))
	return false


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _on_encounter_resolved(id: int, killed: bool) -> void:
	if id == prisoner_id and not resolved:
		on_resolved(killed)


func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Modele"
	add_child(_model)

	var perso := MODELE.instantiate() as Node3D
	perso.name = "Perso"
	perso.rotation.y = PI  # le modèle regarde vers +Z, les détenus avancent vers -Z
	_model.add_child(perso)
	var skeletons := perso.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		_skeleton = skeletons[0] as Skeleton3D
	var players := perso.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		for n in ANIM_BOUCLES:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_anim.play(&"idle")
		_anim.seek(randf() * 1.5, true)  # pour qu'ils ne respirent pas tous en même temps

	var tenue: Texture2D = TENUES.get(prisoner_id)
	var corps := perso.find_child("Corps", true, false) as MeshInstance3D
	if tenue and corps:
		var mat := corps.get_active_material(0).duplicate() as BaseMaterial3D
		if mat:
			mat.albedo_texture = tenue
			corps.set_surface_override_material(0, mat)

	var knife := perso.find_child("Couteau", true, false) as Node3D
	if knife:
		knife.visible = false

	# numéro dans le dos, accroché à l'os du torse
	if _skeleton and _skeleton.find_bone("torse") >= 0:
		var bone := _skeleton.find_bone("torse")
		var attach := BoneAttachment3D.new()
		attach.bone_name = "torse"
		_skeleton.add_child(attach)
		var number := Label3D.new()
		number.name = "Numero"
		number.text = str(prisoner_id)
		number.font_size = 110
		number.pixel_size = 0.0025
		number.modulate = Color(0.08, 0.08, 0.08)
		number.outline_size = 0
		number.shaded = true
		number.double_sided = false
		# dans le repère du squelette le dos est vers -Z
		var wanted := Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 1.2, -0.165))
		number.transform = _skeleton.get_bone_global_rest(bone).affine_inverse() * wanted
		attach.add_child(number)

	_build_stare()

	_body = AnimatableBody3D.new()
	_body.sync_to_physics = false
	_body_shape = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.75
	_body_shape.shape = shape
	_body_shape.position.y = 0.875
	_body.add_child(_body_shape)
	add_child(_body)


## Deux modificateurs « regarder vers » : le torse aide un peu, la tête finit le mouvement.
func _build_stare() -> void:
	if _skeleton == null or _skeleton.find_bone("tete") < 0 or _skeleton.find_bone("torse") < 0:
		return
	_look_target = Node3D.new()
	_look_target.name = "CibleRegard"
	_look_target.top_level = true
	add_child(_look_target)
	_look_torso = _look_at_modifier("torse", 90.0, 40.0)
	_look_head = _look_at_modifier("tete", 150.0, 100.0)


func _look_at_modifier(bone: String, yaw_range: float, pitch_range: float) -> LookAtModifier3D:
	var m := LookAtModifier3D.new()
	m.name = "Regard_" + bone
	m.bone_name = bone
	m.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Z  # le visage regarde vers +Z dans le squelette
	m.primary_rotation_axis = Vector3.AXIS_Y
	m.use_angle_limitation = true
	m.symmetry_limitation = true
	m.primary_limit_angle = deg_to_rad(yaw_range)
	m.primary_damp_threshold = 0.6
	m.secondary_limit_angle = deg_to_rad(pitch_range)
	m.secondary_damp_threshold = 0.6
	m.duration = 0.6  # changement de caméra : il suit en douceur
	m.transition_type = Tween.TRANS_SINE
	m.ease_type = Tween.EASE_IN_OUT
	m.influence = 0.0
	m.active = false
	_skeleton.add_child(m)
	m.target_node = m.get_path_to(_look_target)
	return m
