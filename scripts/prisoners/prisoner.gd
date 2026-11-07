class_name Prisoner
extends Node3D
## Base des trois psychopathes.

@export var prisoner_id := 0
@export var display_name := ""

var resolved := false


func start_escape() -> void:
	pass


func attack_player() -> void:
	pass


func on_resolved(killed: bool) -> void:
	pass
