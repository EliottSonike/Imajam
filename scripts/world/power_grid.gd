class_name PowerGrid
extends Node
## Allume / éteint les lumières pendant la panne.

@export var world_environment: WorldEnvironment


func _ready() -> void:
	pass


func _on_power_changed(on: bool) -> void:
	pass
