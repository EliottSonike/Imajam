extends CharacterBody3D

@export var mouse_sensitivity = 0.002

@onready var head = $Head
@onready var camera = $Head/Camera3D

const SPEED = 5.0

var _locks := {}

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event):
	if is_locked():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))


func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Déplacement (bloqué si un panneau est ouvert)
	var input_dir := Vector2.ZERO
	if not is_locked():
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


# --- Contrat Player (utilisé par les panneaux et par Eliott) ---

func set_lock(reason: String, locked: bool) -> void:
	if locked:
		_locks[reason] = true
	else:
		_locks.erase(reason)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_locked() else Input.MOUSE_MODE_CAPTURED


func is_locked() -> bool:
	return not _locks.is_empty()


func make_view_current() -> void:
	camera.make_current()
