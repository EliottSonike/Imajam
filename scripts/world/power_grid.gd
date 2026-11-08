class_name PowerGrid
extends Node
## Allume / éteint les lumières pendant la panne.

@export var world_environment: WorldEnvironment

var _ambient_energy := 0.12
var _lamp_on: Material
var _lamp_off: StandardMaterial3D


func _ready() -> void:
	add_to_group(&"power_grid")
	Events.power_changed.connect(_on_power_changed)
	_setup.call_deferred()


func _setup() -> void:
	if world_environment == null:
		world_environment = get_tree().get_first_node_in_group(&"world_env") as WorldEnvironment
	if world_environment and world_environment.environment:
		_ambient_energy = world_environment.environment.ambient_light_energy
	_lamp_off = StandardMaterial3D.new()
	_lamp_off.albedo_color = Color(0.15, 0.15, 0.14)
	for lamp in get_tree().get_nodes_in_group(&"power_lamps"):
		if _lamp_on == null and lamp is MeshInstance3D:
			_lamp_on = (lamp as MeshInstance3D).material_override


func _on_power_changed(on: bool) -> void:
	# grésillement avant de s'éteindre / de se rallumer
	var pattern := [true, false, true, false, false, true, false] if not on else [false, true, false, true, false, true]
	for state in pattern:
		_set_lights(state)
		await get_tree().create_timer(randf_range(0.05, 0.14)).timeout
	_set_lights(on)
	if world_environment and world_environment.environment:
		world_environment.environment.ambient_light_energy = _ambient_energy if on else 0.0


func _set_lights(on: bool) -> void:
	for light in get_tree().get_nodes_in_group(&"power_lights"):
		(light as Node3D).visible = on
	for lamp in get_tree().get_nodes_in_group(&"power_lamps"):
		if lamp is MeshInstance3D:
			(lamp as MeshInstance3D).material_override = _lamp_on if on else _lamp_off
