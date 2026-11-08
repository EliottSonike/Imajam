class_name PrisonerCrisis
extends Prisoner
## Détenu 2 : épisode psychotique.
## Au tour 2, il s'agite dans sa cellule. Dès que le joueur le voit à la caméra (ou au bout de
## max_wait secondes), il force sa porte, passe par les cuisines (il y prend un couteau) et
## s'arrête au réfectoire. Quand le joueur entre dans le réfectoire, la négociation commence :
##  - réussie : il lâche le couteau et s'assoit par terre (aucune violence) ;
##  - ratée : il charge, couteau en avant → confrontation, sans taser possible : il faut tirer.

signal escaped(seen: bool)          ## sorti de sa cellule ; seen = le joueur le regardait
signal spotted(where: StringName)   ## premier passage à l'écran : &"route" ou &"refectoire"
signal arrived                      ## arrivé au réfectoire
signal calmed                       ## négociation réussie

enum State { IDLE, WAITING, ESCAPING, REFECTOIRE, TALKING, CALM }

@export var cell_door: CellDoor
## Case du plan où il prend le couteau (cuisines), puis celle où il s'arrête (réfectoire).
@export var kitchen_tile := Vector2i(22, 3)
@export var refectoire_tile := Vector2i(16, 3)
@export var run_speed := 3.0
## Distance à laquelle la négociation commence (ou dès que le joueur entre dans le réfectoire).
@export var talk_distance := 5.0
## Secondes passées dans sa cellule si le joueur ne le regarde jamais.
@export var max_wait := 40.0

var state := State.IDLE
var _wait_left := 0.0
var _leg := 0  # 0 = vers les cuisines, 1 = vers le réfectoire
var _spotted_route := false
var _spotted_refectoire := false
var _agitation := 1.0
var _knife: MeshInstance3D
var _twitch_t := 0.0
var _twitch_target := 0.0


func _ready() -> void:
	body_color = Color(0.9, 0.9, 0.86)  # camisole blanche : on ne le confond pas avec le 1
	super._ready()
	_build_knife()
	Events.talk_finished.connect(_on_talk_finished)


## Début du tour 2 : il s'agite dans sa cellule en attendant qu'on le regarde.
func start_escape() -> void:
	if resolved:
		return
	state = State.WAITING
	_wait_left = max_wait


## Chaque réponse le calme (+1) ou l'énerve (-1) : ça se voit à ses tremblements.
func on_talk_answer(effect: int) -> void:
	_agitation = clampf(_agitation - 0.3 * effect, 0.15, 1.4)


func _physics_process(delta: float) -> void:
	if resolved or _busy:
		return
	match state:
		State.WAITING:
			_wait_left -= delta
			if _update_seen(delta):
				_break_out(true)
			elif _wait_left <= 0.0:
				_break_out(false)
		State.ESCAPING:
			if _follow_path(delta, run_speed):
				if _leg == 0:
					_leg = 1
					_knife.visible = true  # il a pris un couteau aux cuisines
					_set_path(PrisonNav.find_path(global_position, PrisonNav.tile_to_world(refectoire_tile)), 1)
				else:
					state = State.REFECTOIRE
					_moving = false
					arrived.emit()
			elif not _spotted_route and _update_seen(delta):
				_spotted_route = true
				spotted.emit(&"route")
			if _leg == 1:
				_check_player_close()
		State.REFECTOIRE:
			if not _spotted_refectoire and _update_seen(delta):
				_spotted_refectoire = true
				spotted.emit(&"refectoire")
			_check_player_close()


func _break_out(seen: bool) -> void:
	state = State.ESCAPING
	_leg = 0
	_spotted_route = seen
	if cell_door:
		cell_door.open()
	_set_path(PrisonNav.find_path(global_position, PrisonNav.tile_to_world(kitchen_tile)), 1)
	escaped.emit(seen)


## Le joueur arrive (dans le réfectoire, ou tout près) : la négociation commence.
func _check_player_close() -> void:
	var p := _player()
	if p == null or p.is_locked():
		return
	var in_room := state == State.REFECTOIRE and PrisonNav.room_at(p.global_position) == "F"
	if in_room or p.global_position.distance_to(global_position) < talk_distance:
		_start_talk(p)


func _start_talk(p: Player) -> void:
	state = State.TALKING
	_moving = false
	p.set_lock(&"talk", true)
	face_instant(p.global_position)
	p.face_point(global_position + Vector3.UP * 1.5, 0.4)
	await Dialogue.say(&"detenu_2_couteau")
	if state == State.TALKING:
		Events.talk_requested.emit(self)


func _on_talk_finished(id: int, success: bool) -> void:
	if id != prisoner_id or state != State.TALKING:
		return
	var p := _player()
	if success:
		state = State.CALM
		resolved = true
		_drop_knife()
		_sit_down()
		if p:
			p.set_lock(&"talk", false)
		calmed.emit()
	else:
		state = State.IDLE
		taser_allowed = false  # il a un couteau : pas le temps de sortir le taser
		attack_player()
		if p:
			p.set_lock(&"talk", false)


## Tremblements de la crise : d'autant plus forts qu'il est agité.
func _process(delta: float) -> void:
	super._process(delta)
	if resolved or _busy or _model == null or state == State.IDLE:
		return
	_twitch_t -= delta
	if _twitch_t <= 0.0:
		_twitch_t = randf_range(0.08, 0.35)
		_twitch_target = randf_range(-0.35, 0.35) * _agitation
	_model.rotation.y = lerpf(_model.rotation.y, _twitch_target, minf(1.0, 20.0 * delta))
	_model.rotation.x = randf_range(-0.04, 0.04) * _agitation


# --- Couteau et fin calme ---

func _build_knife() -> void:
	_knife = MeshInstance3D.new()
	_knife.name = "Couteau"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, 0.02, 0.46)
	_knife.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.84, 0.87)
	mat.metallic = 0.9
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(0.45, 0.45, 0.48)  # reste visible sur les caméras
	_knife.material_override = mat
	_knife.position = Vector3(0.44, 0.9, -0.25)  # tenu à droite, pointé vers l'avant
	_knife.rotation.x = deg_to_rad(-30.0)
	_knife.visible = false
	_model.add_child(_knife)


func _drop_knife() -> void:
	if not _knife.visible:
		return
	_knife.reparent(self)
	var tw := create_tween().set_parallel()
	tw.tween_property(_knife, "position", Vector3(0.35, 0.02, -0.45), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_knife, "rotation", Vector3(0.0, 0.6, 0.0), 0.45)
	Sfx.play("pickup", -10.0, 0.6)


## Il s'assoit par terre (la capsule s'enfonce un peu).
func _sit_down() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(_model, "rotation", Vector3.ZERO, 0.6)
	tw.tween_property(_model, "position:y", -0.55, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
