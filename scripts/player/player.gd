class_name Player
extends CharacterBody3D
## Contrôleur FPS du garde.

const BODY_LAYER := 3

@export var walk_speed := 3.0
@export var sprint_speed := 5.0
@export var mouse_sensitivity := 0.0025  # remplacée par le réglage des options
@export var eye_height := 1.6
@export var keyboard_turn_speed := 2.4  # rad/s, flèches du clavier

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay

var is_sprinting := false

var _locks := {}
var _target: Interactable = null
var _prompt_text := ""
var _bob_t := 0.0
var _shake := 0.0
var _vision_t := 0.0
var _step_timer := 0.0
var _step_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group(&"player")
	camera.set_cull_mask_value(BODY_LAYER, false)
	_build_body()
	_step_player = AudioStreamPlayer.new()
	_step_player.stream = Sfx.stream("step")
	_step_player.volume_db = -12.0
	add_child(_step_player)
	Events.shake.connect(func(s: float) -> void: _shake = maxf(_shake, s))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	make_view_current()


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion == null or is_locked() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var s := Settings.mouse_sensitivity
	rotate_y(-motion.relative.x * s)
	head.rotate_x(-motion.relative.y * s)
	head.rotation.x = clampf(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))


func _unhandled_input(event: InputEvent) -> void:
	if is_locked():
		return
	if event.is_action_pressed(&"interact"):
		if _target and _target.can_interact(self):
			_target.interact(self)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"use_meds"):
		if GameState.use_meds():
			Sfx.play("pickup")
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Vector2.ZERO
	if not is_locked():
		input_dir = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
		# regard au clavier (flèches)
		rotate_y(Input.get_axis(&"turn_right", &"turn_left") * keyboard_turn_speed * delta)
		head.rotation.x = clampf(head.rotation.x + Input.get_axis(&"look_down", &"look_up") * keyboard_turn_speed * 0.6 * delta, deg_to_rad(-85.0), deg_to_rad(85.0))
	is_sprinting = Input.is_action_pressed(&"sprint") and input_dir != Vector2.ZERO
	var speed := sprint_speed if is_sprinting else walk_speed
	if GameState.vision_impaired:
		speed *= 0.8
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
	move_and_slide()

	_update_head(delta, direction != Vector3.ZERO and is_on_floor(), speed)
	_update_target()


func set_lock(reason: StringName, locked: bool) -> void:
	if locked:
		_locks[reason] = true
	else:
		_locks.erase(reason)
	if is_locked():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_locked() -> bool:
	return not _locks.is_empty()


func make_view_current() -> void:
	camera.make_current()


func noise_radius() -> float:
	if is_sprinting:
		return 9.0
	if Vector2(velocity.x, velocity.z).length() > 0.5:
		return 4.0
	return 2.0


func face_point(point: Vector3, duration := 0.25) -> void:
	var d := point - head.global_position
	var yaw := atan2(-d.x, -d.z)
	var pitch := atan2(d.y, Vector2(d.x, d.z).length())
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "rotation:y", rotation.y + wrapf(yaw - rotation.y, -PI, PI), duration)
	tw.tween_property(head, "rotation:x", clampf(pitch, -1.2, 1.2), duration)


func teleport(pos: Vector3, yaw: float) -> void:
	global_position = pos
	rotation.y = yaw
	head.rotation.x = 0.0
	velocity = Vector3.ZERO


func _update_head(delta: float, moving: bool, speed: float) -> void:
	if moving:
		_bob_t += delta * speed * 2.4
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.34 if is_sprinting else 0.52
			_step_player.pitch_scale = randf_range(0.85, 1.1)
			_step_player.play()
	var bob := sin(_bob_t) * 0.035 if moving else 0.0
	head.position.y = lerpf(head.position.y, eye_height + bob, 10.0 * delta)

	_shake = move_toward(_shake, 0.0, delta * 2.5)
	var offset := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake * 0.06
	if GameState.vision_impaired:
		_vision_t += delta
		offset += Vector3(sin(_vision_t * 1.3) * 0.03, sin(_vision_t * 0.9) * 0.02, 0.0)
		camera.rotation.z = sin(_vision_t * 0.7) * 0.035
	else:
		camera.rotation.z = lerpf(camera.rotation.z, 0.0, 5.0 * delta)
	camera.position = offset


func _update_target() -> void:
	var target: Interactable = null
	var text := ""
	if not is_locked() and ray.is_colliding():
		var hit := ray.get_collider() as Interactable
		if hit and hit.enabled:
			if hit.can_interact(self):
				target = hit
				text = hit.get_prompt()
			else:
				text = hit.get_hint()
	_target = target
	if text != _prompt_text:
		_prompt_text = text
		Events.interact_prompt.emit(text)


func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "Corps"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	body.mesh = capsule
	body.position.y = 0.875
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.17, 0.28)
	body.material_override = mat
	body.layers = 1 << (BODY_LAYER - 1)
	add_child(body)
