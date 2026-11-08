class_name Generator
extends Interactable
## Générateur à rallumer pendant la panne (le tableau électrique de la salle).

@export var size := Vector3(0.3, 1.1, 1.1)
@export var hum_offset := Vector3(-2.6, -0.6, -1.8)
## Veilleuses de sécurité : très faibles, sur batterie (restent allumées pendant la panne).
@export var safety_lights: Array[Vector3] = [Vector3(0.1, 1.0, 0.0), Vector3(0.1, 1.2, -2.6)]
@export var safety_energy := 0.18

var _hum: AudioStreamPlayer3D


func _ready() -> void:
	if prompt == "":
		prompt = "Rallumer le générateur"
	_setup_box(size)
	_hum = Sfx.player_3d(self, "generator_hum", 3.0, -2.0, true)
	_hum.position = hum_offset
	_hum.max_distance = 70.0
	_hum.play()
	for p in safety_lights:
		_add_safety_light(p)
	Events.power_changed.connect(_on_power_changed)


func can_interact(_player: Player) -> bool:
	return enabled and not GameState.power_on


func get_hint() -> String:
	return "Le générateur tourne normalement." if GameState.power_on else ""


func interact(_player: Player) -> void:
	Sfx.play("power_up")
	GameState.set_power(true)


func _on_power_changed(on: bool) -> void:
	_hum.volume_db = -2.0 if on else 6.0
	_hum.unit_size = 3.0 if on else 6.0


## Petit boîtier de veilleuse (verre orangé) et sa lumière, hors du réseau électrique.
func _add_safety_light(pos: Vector3) -> void:
	var lamp := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.16)
	lamp.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.15, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.15)
	mat.emission_energy_multiplier = 1.6
	lamp.material_override = mat
	lamp.position = pos
	add_child(lamp)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.22)
	light.light_energy = safety_energy
	light.omni_range = 3.5
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	light.position = pos + Vector3(-0.15, -0.05, 0.0)
	add_child(light)
