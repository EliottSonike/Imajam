class_name Pickup
extends Interactable
## Item ramassable (taser, médicaments).

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


## Pose un modèle 3D à la bonne taille, centré sur l'objet et posé sur le meuble.
## « pre » : rotation pour le coucher / le tourner ; « cible » : longueur voulue en X (ou hauteur si y_ref).
func _add_model(path: String, pre: Vector3, cible: float, y_ref := false, offset := Vector3.ZERO) -> void:
	var model := (load(path) as PackedScene).instantiate() as Node3D
	var lie := Node3D.new()
	lie.rotation_degrees = pre
	lie.add_child(model)
	var wrap := Node3D.new()
	wrap.add_child(lie)
	add_child(wrap)
	var box := AABB()
	var first := true
	for m in lie.find_children("*", "MeshInstance3D", true, false):
		var b := (m as MeshInstance3D)
		var t := wrap.global_transform.affine_inverse() * b.global_transform
		box = t * b.get_aabb() if first else box.merge(t * b.get_aabb())
		first = false
	var k := cible / maxf(box.size.y if y_ref else box.size.x, 0.001)
	wrap.scale = Vector3.ONE * k
	wrap.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * k + offset


func _build_visual() -> void:
	if item_id == &"taser":
		# « Evega Tazer », lumoize (CC-BY 4.0) : debout de profil dans le modèle, on le couche
		_add_model("res://models/taser.glb", Vector3(-90, 0, 0), 0.2)
	elif item_id == &"meds":
		# « Pills », Dawndragon (CC-BY 4.0) : un flacon, plus un deuxième couché à côté
		_add_model("res://models/medicaments.glb", Vector3.ZERO, 0.11, true, Vector3(-0.04, 0, 0))
		_add_model("res://models/medicaments.glb", Vector3(0, 30, 90), 0.06, true, Vector3(0.07, 0, 0.02))
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
