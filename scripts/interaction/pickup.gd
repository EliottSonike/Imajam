class_name Pickup
extends Interactable
## Item ramassable (taser, médicaments). Modèle provisoire en boîtes.

@export var item_id: StringName = &""
@export var count := 1


func _ready() -> void:
	if prompt == "":
		if item_id == &"taser":
			prompt = "Prendre le taser"
		elif item_id == &"meds":
			prompt = "Prendre les médicaments"
		else:
			prompt = "Ramasser"
	_setup_box(Vector3(0.45, 0.3, 0.45), Vector3(0.0, 0.12, 0.0))
	_build_visual()


func can_interact(_player: Player) -> bool:
	return enabled


func interact(_player: Player) -> void:
	GameState.add_item(item_id, count)
	Sfx.play("pickup")
	queue_free()


func _build_visual() -> void:
	if item_id == &"taser":
		_add_box_mesh(Vector3(0.2, 0.06, 0.05), Vector3(0.0, 0.03, 0.0), Color(0.95, 0.78, 0.08))
		_add_box_mesh(Vector3(0.05, 0.065, 0.055), Vector3(0.12, 0.03, 0.0), Color(0.06, 0.06, 0.06))
		_add_box_mesh(Vector3(0.012, 0.02, 0.03), Vector3(0.152, 0.03, 0.0), Color(0.3, 0.6, 1.0), 3.0)
	elif item_id == &"meds":
		_add_box_mesh(Vector3(0.14, 0.09, 0.07), Vector3(0.0, 0.045, 0.0), Color(0.94, 0.94, 0.92))
		_add_box_mesh(Vector3(0.08, 0.004, 0.022), Vector3(0.0, 0.092, 0.0), Color(0.85, 0.1, 0.1))
		_add_box_mesh(Vector3(0.022, 0.004, 0.06), Vector3(0.0, 0.092, 0.0), Color(0.85, 0.1, 0.1))
	else:
		_add_box_mesh(Vector3(0.15, 0.1, 0.1), Vector3(0.0, 0.05, 0.0), Color(0.7, 0.7, 0.7))
	# petit halo pour qu'on le repère (s'éteint pendant la panne)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 0.5
	light.omni_range = 1.2
	light.position = Vector3(0.0, 0.35, 0.0)
	light.add_to_group(&"power_lights")
	add_child(light)
