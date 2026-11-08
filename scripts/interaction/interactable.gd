class_name Interactable
extends StaticBody3D
## Base de tout ce qu'on vise + [E].

const INTERACT_LAYER := 4  # valeur du calque physique 3

@export var prompt := ""
@export var enabled := true


func can_interact(_player: Player) -> bool:
	return enabled


func get_prompt() -> String:
	return "[E] " + prompt


func get_hint() -> String:
	return ""


func interact(_player: Player) -> void:
	pass


## Crée la boîte de collision visée par le joueur.
func _setup_box(size: Vector3, offset := Vector3.ZERO) -> CollisionShape3D:
	collision_layer = INTERACT_LAYER
	collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	add_child(cs)
	return cs


## Petite boîte décorative (pour les objets provisoires).
func _add_box_mesh(size: Vector3, pos: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	mi.material_override = mat
	add_child(mi)
	return mi
