class_name JournalPiece
extends Interactable
## Bout de journal (3 = le bout caché).

@export_range(0, 3) var index := 0


func can_interact(player: Player) -> bool:
	return false


func interact(player: Player) -> void:
	pass
