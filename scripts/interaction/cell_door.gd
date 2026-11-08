class_name CellDoor
extends Interactable
## Porte de cellule à barreaux. Elle coulisse dans le mur quand elle s'ouvre.

@export var locked := true
@export var width := 1.2
@export var height := 2.3
## Déplacement des barreaux à l'ouverture (repère local de la porte).
@export var slide := Vector3(1.25, 0.0, 0.0)

var is_open := false
var _bars: Node3D
var _shape: CollisionShape3D


func _ready() -> void:
	if prompt == "":
		prompt = "Ouvrir la cellule"
	_bars = Node3D.new()
	_bars.name = "Barreaux"
	add_child(_bars)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.27)
	mat.metallic = 0.7
	mat.roughness = 0.35
	var n := 7
	for i in n:
		var x := -width / 2.0 + 0.07 + i * (width - 0.14) / (n - 1)
		_bar(Vector3(0.035, height, 0.035), Vector3(x, height / 2.0, 0.0), mat)
	for y in [0.06, height * 0.5, height - 0.06]:
		_bar(Vector3(width, 0.06, 0.05), Vector3(0.0, y, 0.0), mat)
	# fermée : elle bloque le joueur et elle se vise
	_shape = _setup_box(Vector3(width, height, 0.14), Vector3(0.0, height / 2.0, 0.0))
	collision_layer = 1 | INTERACT_LAYER


func can_interact(_player: Player) -> bool:
	return enabled and not is_open and not locked


func get_hint() -> String:
	return "Cellule verrouillée" if locked and not is_open else ""


func interact(_player: Player) -> void:
	open()


func unlock() -> void:
	locked = false


func open() -> void:
	if is_open:
		return
	is_open = true
	locked = false
	Sfx.play_at("door", global_position + Vector3.UP, 0.0, 5.0)
	var tw := create_tween()
	tw.tween_property(_bars, "position", slide, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_shape.set_deferred("disabled", true)


func _bar(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	_bars.add_child(mi)
