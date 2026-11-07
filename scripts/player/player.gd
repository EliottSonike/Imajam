class_name Player
extends CharacterBody3D
## Contrôleur FPS du garde.

@export var walk_speed := 3.0
@export var sprint_speed := 5.0
@export var mouse_sensitivity := 0.0025

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func set_lock(reason: StringName, locked: bool) -> void:
	pass


func is_locked() -> bool:
	return false


func make_view_current() -> void:
	pass
