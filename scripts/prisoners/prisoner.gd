class_name Prisoner
extends Node3D
## Base des trois psychopathes. Modèle provisoire : une capsule orange avec un numéro
## et des yeux rouges (visibles dans le noir). Le nœud « Modele » est à remplacer
## par le vrai modèle quand il sera prêt.

## Calque de rendu que les caméras de surveillance n'affichent pas.
const HIDDEN_FROM_CAMERAS_LAYER := 2

@export var prisoner_id := 0
@export var display_name := ""
@export var walk_speed := 1.4
## Couleur de la capsule (orange = tenue de détenu).
@export var body_color := Color(0.85, 0.36, 0.07)
## Réplique dite au moment de l'attaque (clé de Texts.LINES, vide = rien).
@export var attack_line: StringName = &""

## Faux quand le joueur n'a pas le temps de sortir le taser (il doit tirer).
var taser_allowed := true

var resolved := false

var _model: Node3D
var _body: AnimatableBody3D
var _body_shape: CollisionShape3D
var _path := PackedVector3Array()
var _path_i := 0
var _moving := false
var _busy := false
var _t := 0.0
var _seen_cache := false
var _seen_check := 0.0


func _ready() -> void:
	add_to_group(&"prisoners")
	if display_name == "":
		display_name = Texts.PRISONER_NAMES.get(prisoner_id, "")
	_build_model()
	Events.encounter_resolved.connect(_on_encounter_resolved)


func _process(delta: float) -> void:
	_t += delta
	if resolved or _model == null:
		return
	if _moving:
		_model.position.y = absf(sin(_t * 9.0)) * 0.05
		_model.rotation.z = sin(_t * 4.5) * 0.04
	else:
		_model.position.y = lerpf(_model.position.y, 0.0, 8.0 * delta)
		_model.rotation.z = lerpf(_model.rotation.z, 0.0, 8.0 * delta)
		_model.scale = Vector3(1.0, 1.0 + sin(_t * 2.0) * 0.012, 1.0)


func start_escape() -> void:
	pass


## Attaque scriptée : le détenu fonce sur le joueur, puis la confrontation s'ouvre.
func attack_player() -> void:
	var player := _player()
	if player == null or resolved:
		return
	_busy = true
	_moving = false
	player.set_lock(&"encounter", true)
	set_hidden_from_cameras(false)
	if attack_line != &"":
		Dialogue.say(attack_line)
	var to_me := global_position - player.global_position
	to_me.y = 0.0
	var target := player.global_position + to_me.normalized() * 0.95
	target.y = global_position.y
	face_instant(player.global_position)
	player.face_point(global_position + Vector3.UP * 1.5, 0.2)
	Sfx.play("scream", -4.0, 1.25)
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Events.shake.emit(1.0)
	Events.flash.emit(Color(0.6, 0.0, 0.0, 0.55))
	player.face_point(global_position + Vector3.UP * 1.5, 0.15)
	await get_tree().create_timer(0.45).timeout
	Events.encounter_requested.emit(self)


## Fin de la confrontation : tasé (tremble puis tombe) ou abattu (tombe).
func on_resolved(killed: bool) -> void:
	resolved = true
	_busy = true
	_moving = false
	set_hidden_from_cameras(false)
	if killed:
		Sfx.play("gunshot")
		Events.flash.emit(Color(1.0, 0.85, 0.55, 0.8))
		Events.shake.emit(0.8)
	else:
		Sfx.play("taser")
		Events.flash.emit(Color(0.4, 0.6, 1.0, 0.6))
		var shiver := create_tween()
		for i in 10:
			shiver.tween_property(_model, "rotation:z", 0.09 if i % 2 == 0 else -0.09, 0.05)
		await shiver.finished
	var fall := create_tween().set_parallel()
	fall.tween_property(_model, "rotation", Vector3(deg_to_rad(-88.0), 0.0, 0.0), 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	fall.tween_property(_model, "position:y", 0.3, 0.7)
	_body_shape.set_deferred("disabled", true)
	if killed:
		for eye in _model.find_children("Oeil*", "MeshInstance3D", false, false):
			(eye as Node3D).visible = false


## Invisible sur les caméras de surveillance (mais visible à l'œil nu).
func set_hidden_from_cameras(hidden: bool) -> void:
	for vi in _model.find_children("*", "VisualInstance3D", true, false):
		(vi as VisualInstance3D).layers = (1 << (HIDDEN_FROM_CAMERAS_LAYER - 1)) if hidden else 1


## Vrai si le joueur est aux écrans et que la caméra affichée montre le détenu.
func seen_on_screen() -> bool:
	var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
	return sys != null and sys.active and camera_sees(sys.current_camera())


## Même chose, vérifié 5 fois par seconde seulement (à appeler à chaque image).
func _update_seen(delta: float) -> bool:
	_seen_check -= delta
	if _seen_check <= 0.0:
		_seen_check = 0.2
		_seen_cache = seen_on_screen()
	return _seen_cache


## Vrai si cette caméra voit le détenu (dans le champ et sans mur devant).
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


func face_instant(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


# --- Déplacement le long d'un chemin (centres des cases de PrisonNav) ---

func _set_path(path: PackedVector3Array, start_index := 0) -> void:
	_path = path
	_path_i = mini(start_index, maxi(path.size() - 1, 0))


## Avance vers la fin du chemin. Renvoie true une fois arrivé.
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

	var body := MeshInstance3D.new()
	body.name = "Corps"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	body.mesh = capsule
	body.position.y = 0.875
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.85
	body.material_override = mat
	_model.add_child(body)

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.1, 0.05)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.05, 0.02)
	eye_mat.emission_energy_multiplier = 6.0
	for i in 2:
		var eye := MeshInstance3D.new()
		eye.name = "Oeil%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		eye.mesh = sphere
		eye.material_override = eye_mat
		eye.position = Vector3(-0.09 if i == 0 else 0.09, 1.57, -0.27)
		_model.add_child(eye)

	var number := Label3D.new()
	number.name = "Numero"
	number.text = str(prisoner_id)
	number.font_size = 120
	number.pixel_size = 0.003
	number.modulate = Color(0.05, 0.05, 0.05)
	number.outline_size = 0
	number.shaded = true  # reçoit la lumière : invisible dans le noir, comme le corps
	number.position = Vector3(0.0, 1.15, -0.305)
	number.rotation.y = PI
	_model.add_child(number)

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
