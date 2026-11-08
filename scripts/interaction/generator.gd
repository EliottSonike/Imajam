class_name Generator
extends Interactable
## Générateur à rallumer pendant la panne (le tableau électrique de la salle).
## Son moteur s'entend de loin : c'est lui qui guide le joueur dans le noir.

@export var size := Vector3(0.3, 1.1, 1.1)
## Position du moteur par rapport au tableau électrique (d'où vient le bruit).
@export var hum_offset := Vector3(-2.6, -0.6, -1.8)

var _hum: AudioStreamPlayer3D


func _ready() -> void:
	if prompt == "":
		prompt = "Rallumer le générateur"
	_setup_box(size)
	_hum = Sfx.player_3d(self, "generator_hum", 3.0, -2.0, true)
	_hum.position = hum_offset
	_hum.max_distance = 70.0
	_hum.play()
	Events.power_changed.connect(_on_power_changed)


func can_interact(_player: Player) -> bool:
	return enabled and not GameState.power_on


func get_hint() -> String:
	return "Le générateur tourne normalement." if GameState.power_on else ""


func interact(_player: Player) -> void:
	Sfx.play("power_up")
	GameState.set_power(true)


func _on_power_changed(on: bool) -> void:
	# dans le noir, le moteur est le seul repère : on le rend plus présent
	_hum.volume_db = -2.0 if on else 6.0
	_hum.unit_size = 3.0 if on else 6.0
