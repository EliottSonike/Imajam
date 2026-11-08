class_name Telephone
extends Interactable
## Téléphone du bureau : sonne (son 3D, de plus en plus faible quand on s'éloigne)
## jusqu'à ce que le joueur décroche avec [E].

signal answered

## Silence entre deux sonneries.
@export var ring_gap := 1.1

var ringing := false
var _ring: AudioStreamPlayer3D


func _ready() -> void:
	if prompt == "":
		prompt = "Décrocher le téléphone"
	enabled = false
	add_to_group(&"telephone")
	_setup_box(Vector3(0.45, 0.3, 0.45), Vector3(0, 0.1, 0))
	_ring = Sfx.player_3d(self, "phone_ring", 2.5, 3.0, false)
	_ring.max_distance = 30.0
	_ring.finished.connect(_on_ring_finished)


func ring() -> void:
	ringing = true
	enabled = true
	_desk_targetable(false)  # le bureau des écrans englobe le téléphone : on le rend visable
	_ring.play()


func can_interact(_player: Player) -> bool:
	return ringing


func interact(_player: Player) -> void:
	if not ringing:
		return
	ringing = false
	enabled = false
	_ring.stop()
	_desk_targetable(true)
	Sfx.play("pickup", -8.0)
	answered.emit()


func _desk_targetable(on: bool) -> void:
	for desk in get_tree().get_nodes_in_group(&"security_desk"):
		(desk as CollisionObject3D).collision_layer = INTERACT_LAYER if on else 0


func _on_ring_finished() -> void:
	if not ringing:
		return
	await get_tree().create_timer(ring_gap, false).timeout
	if ringing:
		_ring.play()
