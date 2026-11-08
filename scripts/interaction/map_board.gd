class_name MapBoard
extends Interactable
## Carte à l'entrée du bureau (bouton « Retenir » dans le panneau).

const MAP_TEXTURE := "res://assets/ui/plan_prison.png"

@export var size := Vector2(1.3, 0.82)


func _ready() -> void:
	if prompt == "":
		prompt = "Consulter la carte"
	_setup_box(Vector3(size.x + 0.1, size.y + 0.1, 0.1))
	# le plan affiché sur le panneau
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	quad.position.z = 0.006
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(MAP_TEXTURE)
	mat.roughness = 0.9
	quad.material_override = mat
	add_child(quad)


func can_interact(_player: Player) -> bool:
	return enabled


func interact(_player: Player) -> void:
	Events.open_map_panel.emit()
