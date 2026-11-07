class_name Interactable
extends StaticBody3D
## Base de tout ce qu'on vise + [E].

@export var prompt := ""
@export var enabled := true


func can_interact(_player: Player) -> bool:
	return enabled


func get_prompt() -> String:
	return "[E] " + prompt


func interact(_player: Player) -> void:
	pass
