class_name MapBoard
extends Interactable
## Carte à l'entrée du bureau (bouton « Retenir »).


func can_interact(player: Player) -> bool:
	return false


func interact(player: Player) -> void:
	pass
