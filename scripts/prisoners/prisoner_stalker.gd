class_name PrisonerStalker
extends Prisoner
## Détenu 3 : coupe le générateur, rôde dans le noir, screamer au retour du courant.

signal reached_generator

@export var cell_door: CellDoor
@export var escape_path: Array[NodePath] = []
@export var patrol_points: Array[NodePath] = []


func start_escape() -> void:
	pass


func start_stalking() -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func _on_power_changed(on: bool) -> void:
	pass
