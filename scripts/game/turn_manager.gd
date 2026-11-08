class_name TurnManager
extends Node
## Machine à états : intro → tour 1 → tour 2 → tour 3 → panne → fin.
## Entre deux tours, le joueur doit revenir au poste de surveillance :
## le tour suivant démarre quand il rallume les caméras.
##
## Le téléphone ne sonne qu'au début. Ensuite, c'est le garde qui pense à voix haute, et ses
## répliques se déclenchent au moment où il VOIT ce qui se passe à l'écran.
##  - Tour 1 : la cellule 1 paraît vide à l'écran (le détenu est dans l'angle mort).
##  - Tour 2 : le détenu 2 sort quand on le regarde, prend un couteau aux cuisines et attend au
##             réfectoire. Négociation sur place : réussie = aucun mort, ratée = il faut tirer.
##  - Tour 3 : le détenu 3 sort en courant quand on le regarde et coupe le générateur.
##
## Raccourcis de test (uniquement en debug) : F2 = tour 2, F3 = tour 3, F4 = panne, J = fin,
## K = détenu 3 tout près (panne), F7 = téléporter le joueur au prochain lieu clé.

enum Phase { INTRO, TURN_1, TURN_2, TURN_3, BLACKOUT, ENDING }

@export var prisoner_1: PrisonerHider
@export var prisoner_2: PrisonerCrisis
@export var prisoner_3: PrisonerStalker

var phase := Phase.INTRO
var _turn_1_cell_seen := false
var _next_turn_on_cameras := -1  ## tour à lancer au prochain passage au poste
var _final_return := false
var _checkpoint_pos := Vector3.ZERO
var _checkpoint_yaw := 0.0
var _debug_tp := 0
var _p2_exit_said := false
var _p3_exit_said := false

## Lieux de téléportation de test (position, orientation).
const DEBUG_SPOTS := [
	[Vector3(3.5, 0.05, -21.4), 0.0],         # devant la cellule 1
	[Vector3(4.9, 0.05, -16.1), PI],          # entrée de la réserve (taser)
	[Vector3(21.7, 0.05, -13.3), -PI / 2.0],  # entrée de l'infirmerie (médicaments)
	[Vector3(39.9, 0.05, -3.5), 0.0],         # bloc B, devant la cellule 2
	[Vector3(18.9, 0.05, -17.5), 0.0],        # devant le réfectoire (porte sud)
	[Vector3(14.7, 0.05, -7.7), 0.0],         # devant la cellule 3
	[Vector3(43.0, 0.05, -24.8), -PI / 2.0],  # salle du générateur
	[Vector3(0.0, 0.05, 0.0), PI],            # bureau
]


func _ready() -> void:
	add_to_group(&"turn_manager")
	Events.encounter_resolved.connect(_on_encounter_resolved)
	Events.camera_viewed.connect(_on_camera_viewed)
	Events.camera_mode_changed.connect(_on_camera_mode_changed)
	Events.power_changed.connect(_on_power_changed)
	Events.player_caught.connect(_on_player_caught)
	if prisoner_2:
		prisoner_2.escaped.connect(_on_prisoner_2_escaped)
		prisoner_2.spotted.connect(_on_prisoner_2_spotted)
		prisoner_2.arrived.connect(_on_prisoner_2_arrived)
		prisoner_2.calmed.connect(_on_prisoner_2_calmed)
	if prisoner_3:
		prisoner_3.escaped.connect(_on_prisoner_3_escaped)
		prisoner_3.spotted.connect(_say_p3_exit)
		prisoner_3.reached_generator.connect(_on_prisoner_3_reached_generator)
	GameState.reset()
	Sfx.loop("ambient", -16.0)
	_enter.call_deferred(Phase.INTRO)


func _process(_delta: float) -> void:
	# fin de partie : le joueur revient au bureau après le 3e détenu
	if _final_return and phase == Phase.BLACKOUT:
		var p := _player()
		if p and PrisonNav.room_at(p.global_position) == "B":
			_final_return = false
			_enter(Phase.ENDING)


func _enter(p: Phase) -> void:
	phase = p
	Events.phase_changed.emit(p)
	match p:
		Phase.INTRO:
			Events.fade_requested.emit(false, 2.0)
			await get_tree().create_timer(1.2).timeout
			Events.show_document.emit(Texts.INTRO_TITLE, Texts.INTRO_BODY)
			await Events.document_closed
			Sfx.play("phone_ring", -4.0)
			await get_tree().create_timer(2.2).timeout
			await Dialogue.say(&"intro")  # le seul appel du jeu
			if phase != Phase.INTRO:
				return  # un raccourci de test a déjà fait avancer la partie
			_objective(&"intro")
			_enter(Phase.TURN_1)
		Phase.TURN_1:
			if prisoner_1:
				prisoner_1.start_escape()
			_next_turn_on_cameras = -1
			# le joueur est peut-être déjà devant les écrans
			var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
			if sys and sys.active:
				_on_camera_mode_changed(true)
				_on_camera_viewed(sys.current_id)
		Phase.TURN_2:
			Dialogue.say(&"turn_2")
			_objective(&"turn_2")
			if prisoner_2:
				prisoner_2.start_escape()
		Phase.TURN_3:
			Dialogue.say(&"turn_3")
			_objective(&"turn_3")
			if prisoner_3:
				prisoner_3.start_escape()
		Phase.BLACKOUT:
			var player := _player()
			if player:
				_checkpoint_pos = player.global_position
				_checkpoint_yaw = player.rotation.y
			Sfx.play("power_down")
			GameState.set_power(false)
			await get_tree().create_timer(1.2).timeout
			Dialogue.say(&"blackout")
			_objective(&"blackout")
			await get_tree().create_timer(3.0).timeout
			if prisoner_3 and not prisoner_3.resolved and not GameState.power_on:
				prisoner_3.start_stalking()
		Phase.ENDING:
			Events.fade_requested.emit(true, 2.5)
			await get_tree().create_timer(2.8).timeout
			Events.ending_reached.emit(GameState.compute_ending())


# --- Tour 1 ---

func _on_camera_mode_changed(on: bool) -> void:
	if not on:
		return
	if phase == Phase.TURN_1 and not _turn_1_cell_seen and _next_turn_on_cameras == -1:
		Dialogue.say(&"turn_1")
		_objective(&"turn_1")
		_next_turn_on_cameras = 0
	elif _next_turn_on_cameras == 2:
		_next_turn_on_cameras = -1
		_enter(Phase.TURN_2)
	elif _next_turn_on_cameras == 3:
		_next_turn_on_cameras = -1
		_enter(Phase.TURN_3)


## Le joueur regarde la caméra de la cellule 1 : elle paraît vide.
func _on_camera_viewed(camera_id: StringName) -> void:
	if phase != Phase.TURN_1 or camera_id != &"cell_1" or _turn_1_cell_seen:
		return
	_turn_1_cell_seen = true
	if prisoner_1 and prisoner_1.cell_door:
		prisoner_1.cell_door.unlock()
	Dialogue.say(&"turn_1_empty")
	_objective(&"turn_1_empty")


func _on_encounter_resolved(prisoner_id: int, killed: bool) -> void:
	await get_tree().create_timer(2.0).timeout
	match prisoner_id:
		1:
			Dialogue.say(&"turn_1_done")
			_objective(&"turn_1_done")
			_next_turn_on_cameras = 2
		2:
			Dialogue.say(&"turn_2_tue" if killed else &"turn_2_calme")
			_objective(&"turn_2_done")
			_next_turn_on_cameras = 3
		3:
			Dialogue.say(&"turn_3_done")
			_objective(&"turn_3_done")
			_final_return = true


# --- Tour 2 : le détenu 2 ---

func _on_prisoner_2_escaped(seen: bool) -> void:
	if phase != Phase.TURN_2:
		return
	_objective(&"turn_2_sortie")
	if seen:
		_say_p2_exit()


func _on_prisoner_2_spotted(where: StringName) -> void:
	if phase != Phase.TURN_2:
		return
	if where == &"route":
		_say_p2_exit()
	else:
		Dialogue.say(&"turn_2_refectoire")
		_objective(&"turn_2_refectoire")


func _say_p2_exit() -> void:
	if not _p2_exit_said:
		_p2_exit_said = true
		Dialogue.say(&"turn_2_sortie")


func _on_prisoner_2_arrived() -> void:
	if phase == Phase.TURN_2:
		_objective(&"turn_2_refectoire")


## Négociation réussie : aucun mort.
func _on_prisoner_2_calmed() -> void:
	if phase != Phase.TURN_2:
		return
	GameState.resolve_prisoner(2, false)
	await get_tree().create_timer(1.5).timeout
	Dialogue.say(&"turn_2_calme")
	_objective(&"turn_2_done")
	_next_turn_on_cameras = 3


# --- Tour 3 : le détenu 3 ---

func _on_prisoner_3_escaped(seen: bool) -> void:
	if phase != Phase.TURN_3:
		return
	_objective(&"turn_3_sortie")
	if seen:
		_say_p3_exit()


func _say_p3_exit() -> void:
	if phase == Phase.TURN_3 and not _p3_exit_said:
		_p3_exit_said = true
		Dialogue.say(&"turn_3_sortie")


func _on_prisoner_3_reached_generator() -> void:
	if phase == Phase.TURN_3:
		_enter(Phase.BLACKOUT)


func _on_power_changed(on: bool) -> void:
	# le joueur a rallumé le générateur : screamer du détenu 3
	if on and phase == Phase.BLACKOUT and prisoner_3 and not prisoner_3.resolved:
		var player := _player()
		if player:
			prisoner_3.screamer_at(player)


func _on_player_caught() -> void:
	var player := _player()
	if player == null:
		return
	player.set_lock(&"caught", true)
	Sfx.play("screamer", 0.0, 0.8)
	Events.shake.emit(1.5)
	Events.fade_requested.emit(true, 0.4)
	await get_tree().create_timer(1.6).timeout
	player.teleport(_checkpoint_pos, _checkpoint_yaw)
	GameState.set_vision_impaired(true)
	if prisoner_3:
		prisoner_3.respawn_far_from(_checkpoint_pos)
	Events.fade_requested.emit(false, 1.2)
	Dialogue.say(&"caught")
	player.set_lock(&"caught", false)


# --- Raccourcis de test ---

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F2:
			_debug_skip(2)
		KEY_F3:
			_debug_skip(3)
		KEY_F4:
			_debug_skip(4)
		KEY_J:  # fin (F6, F8, F9 sont pris par l'éditeur quand le jeu tourne)
			if phase != Phase.ENDING:
				_enter(Phase.ENDING)
		KEY_K:  # pendant la panne : le détenu 3 à quelques mètres
			var p := _player()
			if p and prisoner_3 and phase == Phase.BLACKOUT and not prisoner_3.resolved:
				prisoner_3.debug_place_near(p.global_position)
				Events.subtitle.emit("[debug] détenu 3 à quelques mètres", 2.0)
		KEY_F7:
			var player := _player()
			if player:
				var spot: Array = DEBUG_SPOTS[_debug_tp % DEBUG_SPOTS.size()]
				_debug_tp += 1
				player.teleport(spot[0], spot[1])


func _debug_skip(to: int) -> void:
	var prisoners := [prisoner_1, prisoner_2]
	for i in mini(to - 1, 2):
		var pr: Prisoner = prisoners[i]
		if pr and not pr.resolved:
			GameState.resolve_prisoner(pr.prisoner_id, false)
			pr.on_resolved(false)
	_turn_1_cell_seen = true
	_next_turn_on_cameras = -1
	if to == 2:
		_enter(Phase.TURN_2)
	elif to == 3:
		_enter(Phase.TURN_3)
	elif to == 4:
		phase = Phase.TURN_3
		if prisoner_3 and prisoner_3.cell_door:
			prisoner_3.cell_door.open()
		_on_prisoner_3_reached_generator()


# --- Utilitaires ---

func _objective(key: StringName) -> void:
	Events.objective_changed.emit(Texts.OBJECTIVES.get(key, ""))


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player
