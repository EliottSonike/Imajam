class_name PrisonerHider
extends Prisoner
## Détenu 1 : caché dans sa cellule (invisible aux caméras), attaque à l'arrivée.

@export var cell_trigger: Area3D
@export var cell_door: CellDoor


func start_escape() -> void:
	pass


func _on_cell_trigger_body_entered(body: Node3D) -> void:
	pass
