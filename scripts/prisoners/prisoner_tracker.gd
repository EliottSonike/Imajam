class_name PrisonerTracker
extends Prisoner
## Détenu 2 : épisode psychotique, à suivre de caméra en caméra.

signal located

@export var cell_door: CellDoor
@export var waypoints: Array[NodePath] = []
@export var arrival_trigger: Area3D


func start_escape() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _on_arrival_trigger_body_entered(body: Node3D) -> void:
	pass
