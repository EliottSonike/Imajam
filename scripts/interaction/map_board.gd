class_name MapBoard
extends Interactable
## Carte murale du bureau. Pendant la panne, un voyant rouge clignote au-dessus (on le voit de loin dans le noir)
## et on peut prendre la carte.

const MAP_TEXTURE := "res://assets/ui/plan_prison.png"

@export var size := Vector2(1.3, 0.82)

var _quad: MeshInstance3D
var _light: OmniLight3D
var _bulb_mat: StandardMaterial3D
var _blink := 0.0


func _ready() -> void:
	_setup_box(Vector3(size.x + 0.1, size.y + 0.1, 0.1))
	_quad = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	_quad.mesh = mesh
	_quad.position.z = 0.006
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(MAP_TEXTURE)
	mat.roughness = 0.9
	_quad.material_override = mat
	add_child(_quad)
	_build_emergency_light()
	Events.power_changed.connect(_on_power_changed)
	_on_power_changed(GameState.power_on)


func can_interact(_player: Player) -> bool:
	# lumière allumée : on peut toujours la consulter ; dans le noir : on la décroche si on ne l'a pas
	return enabled and (GameState.power_on or not GameState.has_map)


func get_prompt() -> String:
	return "[E] Prendre la carte" if not GameState.power_on else "[E] Consulter la carte"


func interact(_player: Player) -> void:
	if GameState.power_on:
		Events.open_map_panel.emit()
		return
	# dans le noir : on décroche la carte, elle s'affiche en bas à droite
	_quad.hide()
	Sfx.play("pickup", -4.0)
	GameState.take_map()


# voyant de secours au-dessus de la carte (même style que les veilleuses du générateur, en rouge) et sa lueur
func _build_emergency_light() -> void:
	var lamp := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.16, 0.07, 0.06)
	lamp.mesh = box
	lamp.position = Vector3(0, size.y / 2.0 + 0.12, 0.03)
	_bulb_mat = StandardMaterial3D.new()
	_bulb_mat.albedo_color = Color(0.3, 0.05, 0.04)
	_bulb_mat.emission_enabled = true
	_bulb_mat.emission = Color(1.0, 0.12, 0.08)
	_bulb_mat.emission_energy_multiplier = 0.0
	lamp.material_override = _bulb_mat
	add_child(lamp)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.18, 0.12)
	_light.omni_range = 2.4
	_light.light_energy = 0.0
	_light.position = Vector3(0, size.y / 2.0 + 0.1, 0.4)
	add_child(_light)


func _on_power_changed(on: bool) -> void:
	_light.visible = not on
	set_process(not on)
	if on:
		_bulb_mat.emission_energy_multiplier = 0.0


func _process(delta: float) -> void:
	_blink += delta
	var lit := fmod(_blink, 1.0) < 0.4
	_light.light_energy = 0.7 if lit else 0.0
	_bulb_mat.emission_energy_multiplier = 2.2 if lit else 0.15
