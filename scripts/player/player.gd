class_name Player
extends CharacterBody3D
## Contrôleur FPS du garde.

const BODY_LAYER := 3
## Pistolet (traque du détenu 1) : coup par coup, munitions infinies.
const GUN_REST := Vector3(0.16, -0.15, -0.34)
const GUN_MODEL := preload("res://models/pistolet.fbx")
const GUN_LENGTH := 0.2  # m, du chien au bout du canon
const GUN_SHADER := """
shader_type spatial;
uniform vec4 albedo : source_color = vec4(0.2, 0.2, 0.2, 1.0);

void vertex() {
	// profondeur ramenée vers le plan proche (Z inversé : 1 = proche), en gardant l'ordre de ses propres faces
	POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	POSITION.z = mix(POSITION.z, POSITION.w, 0.9);
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.55;
	METALLIC = 0.2;
}
"""
const GUN_COOLDOWN := 0.35
const GUN_RANGE := 60.0

@export var walk_speed := 3.0
@export var sprint_speed := 5.0
@export var mouse_sensitivity := 0.0025  # remplacée par le réglage des options
@export var eye_height := 1.6
@export var keyboard_turn_speed := 2.4  # rad/s, flèches du clavier

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay

var is_sprinting := false
var gun_drawn := false

var _locks := {}
var _target: Interactable = null
var _prompt_text := ""
var _bob_t := 0.0
var _shake := 0.0
var _vision_t := 0.0
var _step_timer := 0.0
var _step_player: AudioStreamPlayer
var _gun: Node3D
var _gun_flash: OmniLight3D
var _gun_cooldown := 0.0
var _knock := Vector3.ZERO


func _ready() -> void:
	add_to_group(&"player")
	camera.set_cull_mask_value(BODY_LAYER, false)
	_build_body()
	_build_gun()
	_step_player = AudioStreamPlayer.new()
	_step_player.stream = Sfx.stream("step")
	_step_player.volume_db = -12.0
	add_child(_step_player)
	Events.shake.connect(func(s: float) -> void: _shake = maxf(_shake, s))
	Events.vision_changed.connect(_on_vision_changed)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	make_view_current()


## Vision trouble : il halète (boucle « halete ») jusqu'à ce qu'il prenne ses médicaments.
func _on_vision_changed(impaired: bool) -> void:
	if impaired:
		Sfx.loop("halete", -10.0)
	else:
		Sfx.stop_loop("halete")


func _exit_tree() -> void:
	Sfx.stop_loop("halete")  # retour au menu, rechargement : la boucle ne doit pas continuer


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
	var click := event as InputEventMouseButton
	if gun_drawn and click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		shoot()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact"):
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
	# vision trouble : plus de course (il halète, voir _on_vision_changed)
	is_sprinting = Input.is_action_pressed(&"sprint") and input_dir != Vector2.ZERO and not GameState.vision_impaired
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
	# bousculé : poussée qui retombe vite (et qui s'arrête contre les murs)
	velocity.x += _knock.x
	velocity.z += _knock.z
	_knock = _knock.move_toward(Vector3.ZERO, 14.0 * delta)
	_gun_cooldown -= delta
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


## Poussée (bousculade, coup reçu), dans le plan horizontal.
func push(direction: Vector3, strength: float) -> void:
	direction.y = 0.0
	if direction.length() > 0.01:
		_knock = direction.normalized() * strength


## Coup reçu d'un détenu : il recule, l'écran rougit, et une vie part.
func take_hit(from: Vector3, strength := 4.0) -> void:
	Events.flash.emit(Color(0.7, 0.0, 0.0, 0.6))
	Events.shake.emit(1.3)
	Sfx.play("screamer", -8.0, 1.3)
	push(global_position - from, strength)
	GameState.hurt()


## Il s'effondre (mort du garde).
func collapse() -> void:
	set_lock(&"dead", true)
	draw_gun(false)
	var tw := create_tween().set_parallel()
	tw.tween_property(head, "position:y", 0.35, 1.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "rotation:z", 1.2, 0.9).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(head, "rotation:x", -0.3, 0.9)


## Sort ou range le pistolet.
func draw_gun(on: bool) -> void:
	if on == gun_drawn or _gun == null:
		return
	gun_drawn = on
	var hidden := GUN_REST + Vector3(0.0, -0.25, 0.1)
	var tw := create_tween()
	if on:
		_gun.visible = true
		_gun.position = hidden
		tw.tween_property(_gun, "position", GUN_REST, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("pickup", -6.0, 0.6)
	else:
		tw.tween_property(_gun, "position", hidden, 0.25)
		tw.tween_callback(func() -> void: _gun.visible = false)
	Events.gun_drawn.emit(on)


## Un coup de pistolet, au centre de l'écran.
func shoot() -> void:
	if _gun_cooldown > 0.0:
		return
	_gun_cooldown = GUN_COOLDOWN
	Sfx.play("gunshot", -3.0, randf_range(0.95, 1.05))
	Events.shake.emit(0.25)
	_gun.position = GUN_REST + Vector3(0.0, 0.012, 0.06)
	_gun.rotation.x = 0.28
	var tw := create_tween().set_parallel()
	tw.tween_property(_gun, "position", GUN_REST, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_gun, "rotation:x", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	head.rotation.x = clampf(head.rotation.x + 0.015, deg_to_rad(-85.0), deg_to_rad(85.0))
	_gun_flash.visible = true
	get_tree().create_timer(0.06, false).timeout.connect(func() -> void: _gun_flash.visible = false)

	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * GUN_RANGE)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var n := hit.collider as Node
	while n != null and not (n is Prisoner):
		n = n.get_parent()
	if n and (n as Prisoner).on_shot(self):
		return
	_impact(hit.position, hit.normal)


## Petit trou noir là où la balle a frappé.
func _impact(point: Vector3, normal: Vector3) -> void:
	var dot := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.022
	mesh.height = 0.044
	mesh.radial_segments = 8
	mesh.rings = 4
	dot.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.03)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot.material_override = mat
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(dot)
	dot.global_position = point + normal * 0.004
	get_tree().create_timer(12.0, false).timeout.connect(dot.queue_free)


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


## Pistolet « Pistol » de Quaternius (CC0), accroché à la caméra, sur le calque caché aux caméras de surveillance.
## Sa profondeur est écrasée vers le plan proche (GUN_SHADER) : il passe devant les murs sans s'y enfoncer.
func _build_gun() -> void:
	_gun = Node3D.new()
	_gun.name = "Pistolet"
	_gun.position = GUN_REST
	_gun.rotation.y = 0.06  # légèrement tourné vers le centre de l'écran
	_gun.visible = false
	camera.add_child(_gun)
	var holder := Node3D.new()
	holder.rotation.y = PI / 2.0  # le canon du modèle pointe vers +X : on le tourne vers -Z
	_gun.add_child(holder)
	var model := GUN_MODEL.instantiate() as Node3D
	holder.add_child(model)

	var shader := Shader.new()
	shader.code = GUN_SHADER
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var box := AABB()
	for i in meshes.size():
		var mi := meshes[i] as MeshInstance3D
		var t := _gun.global_transform.affine_inverse() * mi.global_transform
		box = t * mi.get_aabb() if i == 0 else box.merge(t * mi.get_aabb())
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = 1 << (SecurityCamera.HIDDEN_FROM_CAMERAS_LAYER - 1)
		for surface in mi.mesh.get_surface_count():
			var src := mi.get_active_material(surface) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = shader
			mat.set_shader_parameter("albedo", src.albedo_color if src else Color(0.2, 0.2, 0.2))
			mi.set_surface_override_material(surface, mat)
	# taille et centrage d'après la boîte englobante (longueur = axe Z une fois tourné)
	var k := GUN_LENGTH / maxf(box.size.z, 0.001)
	holder.scale = Vector3.ONE * k
	holder.position = -box.get_center() * k

	_gun_flash = OmniLight3D.new()
	_gun_flash.light_color = Color(1.0, 0.78, 0.45)
	_gun_flash.light_energy = 5.0
	_gun_flash.omni_range = 5.0
	_gun_flash.position = Vector3(0.0, GUN_LENGTH * 0.15, -GUN_LENGTH * 0.6)
	_gun_flash.visible = false
	_gun.add_child(_gun_flash)
