class_name CellDoor
extends Interactable
## Porte de cellule.

@export var locked := true

var is_open := false


func can_interact(player: Player) -> bool:
	return false


func interact(player: Player) -> void:
	pass


func open() -> void:
	pass
