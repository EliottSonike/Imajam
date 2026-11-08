class_name SecurityDesk
extends Interactable
## Bureau des écrans : entrée en mode caméras.

## Zone d'interaction : tout le bureau plus l'espace de la chaise devant,
## pour que la chaise ne bloque pas le regard du joueur.
@export var size := Vector3(4.3, 1.5, 1.75)
@export var box_offset := Vector3(0.0, 0.03, -0.33)


func _ready() -> void:
	if prompt == "":
		prompt = "Regarder les caméras"
	_setup_box(size, box_offset)


func can_interact(_player: Player) -> bool:
	return enabled and GameState.power_on


func get_hint() -> String:
	return "Les écrans sont éteints…" if not GameState.power_on else ""


func interact(_player: Player) -> void:
	Events.camera_mode_requested.emit()
