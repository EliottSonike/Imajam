class_name Interactable
extends StaticBody3D
## Base de tout ce qu'on vise + [E].

@export var prompt := ""
@export var enabled := true


func can_interact(player: Player) -> bool:
	return false


func get_prompt() -> String:
	return ""


func interact(player: Player) -> void:
	pass
