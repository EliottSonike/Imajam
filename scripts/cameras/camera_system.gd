class_name CameraSystem
extends Node
## Mode caméras : passer d'une SecurityCamera à l'autre depuis le bureau.

var active := false
var current_id: StringName = &""


func _ready() -> void:
	pass


func enter() -> void:
	pass


func exit() -> void:
	pass


func is_watching(camera_id: StringName) -> bool:
	return false


func _unhandled_input(event: InputEvent) -> void:
	pass
