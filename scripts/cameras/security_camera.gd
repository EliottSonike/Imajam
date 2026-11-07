class_name SecurityCamera
extends Camera3D
## Une caméra de surveillance.

const HIDDEN_FROM_CAMERAS_LAYER := 2
@export var camera_id: StringName = &""
@export var label := ""


func _ready() -> void:
	add_to_group(&"security_cameras")
	set_cull_mask_value(HIDDEN_FROM_CAMERAS_LAYER, false)
