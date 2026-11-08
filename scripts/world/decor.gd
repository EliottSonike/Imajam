class_name Decor
extends Node3D
## Habille le niveau : béton sur les murs, carrelage au réfectoire, écrans et téléphone du bureau.

const MAT_MUR := preload("res://assets/materials/beton_mur.tres")
const MAT_REFECTOIRE := preload("res://assets/materials/carrelage_refectoire.tres")
const SHADER_ECRAN := preload("res://assets/materials/ecran_cctv.gdshader")
const ECRAN := preload("res://models/ecran.glb")
const TELEPHONE := preload("res://models/telephone.glb")

## Les quatre écrans posés sur le bureau, légèrement tournés vers la chaise.
const ECRANS_X: Array[float] = [-1.475, -0.475, 0.525, 1.525]
const ECRANS_Z := 2.25
const BUREAU_Y := 0.76
const CHAISE := Vector3(-0.05, 0.0, 1.37)
const TELEPHONE_POS := Vector3(1.9, 0.76, 1.93)

@export var prison: Node3D

var _ecrans: Array[ShaderMaterial] = []


func _ready() -> void:
	if prison == null:
		prison = get_parent().get_node_or_null("Prison") as Node3D
	if prison:
		_habiller(prison)
	_poser_bureau()
	Events.power_changed.connect(_on_power_changed)


func _habiller(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.name.begins_with("Ecrans_Bureau"):
			mi.visible = false  # remplacés par les vrais écrans (la collision reste)
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat == null:
				continue
			match mat.resource_name:
				"Mur":
					mi.set_surface_override_material(i, MAT_MUR)
				"Sol_Refectoire":
					mi.set_surface_override_material(i, MAT_REFECTOIRE)


func _poser_bureau() -> void:
	for i in ECRANS_X.size():
		var ecran := ECRAN.instantiate() as Node3D
		ecran.name = "Ecran%d" % (i + 1)
		ecran.position = Vector3(ECRANS_X[i], BUREAU_Y, ECRANS_Z)
		ecran.rotation.y = _vers_chaise(ecran.position) * 0.4
		add_child(ecran)
		var dalle := ecran.find_child("Affichage", true, false) as MeshInstance3D
		if dalle:
			var mat := ShaderMaterial.new()
			mat.shader = SHADER_ECRAN
			mat.set_shader_parameter(&"graine", float(i) * 1.37)
			mat.set_shader_parameter(&"allume", 1.0 if GameState.power_on else 0.0)
			dalle.material_override = mat
			_ecrans.append(mat)

	var tel := TELEPHONE.instantiate() as Node3D
	tel.name = "Telephone"
	tel.position = TELEPHONE_POS
	tel.rotation.y = _vers_chaise(TELEPHONE_POS) * 0.7
	add_child(tel)


func _vers_chaise(from: Vector3) -> float:
	var d := CHAISE - from
	return atan2(-d.x, -d.z)


func _on_power_changed(on: bool) -> void:
	for mat in _ecrans:
		mat.set_shader_parameter(&"allume", 1.0 if on else 0.0)
