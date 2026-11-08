class_name PrisonerHider
extends Prisoner
## Détenu 1 : caché dans sa cellule (invisible aux caméras), attaque à l'arrivée.

@export var cell_trigger: Area3D
@export var cell_door: CellDoor
@export var hide_spot: Marker3D

var _waiting := false


func _ready() -> void:
	if attack_line == &"":
		attack_line = &"detenu_1_attaque"
	super._ready()
	if cell_trigger:
		cell_trigger.body_entered.connect(_on_cell_trigger_body_entered)


func start_escape() -> void:
	set_hidden_from_cameras(true)
	if hide_spot:
		global_position = hide_spot.global_position
		rotation.y = hide_spot.global_rotation.y
	_waiting = true
	_pose = &"accroupi"


func _on_cell_trigger_body_entered(body: Node3D) -> void:
	if _waiting and not resolved and body is Player:
		_waiting = false
		_pose = &""
		attack_player()
