class_name Pickup
extends Interactable
## Item ramassable (taser, médicaments).

@export var item_id: StringName = &""


func can_interact(player: Player) -> bool:
	return false


func interact(player: Player) -> void:
	pass
