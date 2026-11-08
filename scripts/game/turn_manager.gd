class_name TurnManager
extends Node
## Machine à états : intro -> trois tours (un détenu par tour, ordre tiré au hasard) -> fin.
## L'appel ne désigne aucune cellule : c'est le garde qui choisit par où commencer (première réplique du tour).
## Entre deux tours : retour aux écrans puis un moment de calme avant l'évasion suivante.
## Le tour du détenu 3 passe par la panne de courant (BLACKOUT).

enum Phase { INTRO, TURN_1, TURN_2, TURN_3, BLACKOUT, ENDING }

## Caméra de la cellule de chaque détenu.
const CELL_CAMERAS := {1: &"cell_1", 2: &"cell_2", 3: &"cell_3"}

@export var prisoner_1: PrisonerHider
@export var prisoner_2: PrisonerCrisis
@export var prisoner_3: PrisonerStalker
## Ordre imposé des détenus (ex. [3, 1, 2]) pour tester. Vide : tiré au hasard à chaque partie.
@export var forced_order: Array[int] = []
## Calme entre deux évasions (s), compté à partir du retour aux écrans.
@export var calm_min := 15.0
@export var calm_max := 25.0

var phase := Phase.INTRO
## Ordre de passage des détenus pour cette partie.
var order: Array[int] = [1, 2, 3]
var _turn := -1  # tour en cours (0, 1 ou 2)
var _current := 0  # détenu du tour en cours
var _turn_started := false  # réplique dite et évasion lancée
var _awaiting_return := false  # tour fini : on attend le retour aux écrans
var _calm_left := -1.0
var _cell_1_seen := false
var _done: Array[int] = []
var _final_return := false
var _checkpoint_pos := Vector3.ZERO
var _checkpoint_yaw := 0.0
var _debug_tp := 0
var _p2_exit_said := false
var _p3_exit_said := false

## Lieux de téléportation de test (position, orientation).
const DEBUG_SPOTS := [
	[Vector3(3.5, 0.05, -21.4), 0.0],  # devant la cellule 1
	[Vector3(4.9, 0.05, -16.1), PI],  # entrée de la réserve (taser)
	[Vector3(21.7, 0.05, -13.3), -PI / 2.0],  # entrée de l'infirmerie (médicaments)
	[Vector3(39.9, 0.05, -3.5), 0.0],  # bloc B, devant la cellule 2
	[Vector3(18.9, 0.05, -17.5), 0.0],  # devant le réfectoire (porte sud)
	[Vector3(14.7, 0.05, -7.7), 0.0],  # devant la cellule 3
	[Vector3(43.0, 0.05, -24.8), -PI / 2.0],  # salle du générateur
	[Vector3(0.0, 0.05, 0.0), PI],  # bureau
]


func _ready() -> void:
	add_to_group(&"turn_manager")
	Events.encounter_resolved.connect(_on_encounter_resolved)
	Events.camera_viewed.connect(_on_camera_viewed)
	Events.camera_mode_changed.connect(_on_camera_mode_changed)
	Events.power_changed.connect(_on_power_changed)
	Events.player_caught.connect(_on_player_caught)
	Events.map_taken.connect(_on_map_taken)
	Events.player_died.connect(_on_player_died)
	if prisoner_1:
		prisoner_1.fled.connect(_on_prisoner_1_fled)
	if prisoner_2:
		prisoner_2.escaped.connect(_on_prisoner_2_escaped)
		prisoner_2.spotted.connect(_on_prisoner_2_spotted)
		prisoner_2.arrived.connect(_on_prisoner_2_arrived)
		prisoner_2.calmed.connect(_on_prisoner_2_calmed)
	if prisoner_3:
		prisoner_3.escaped.connect(_on_prisoner_3_escaped)
		prisoner_3.spotted.connect(_say_p3_exit)
		prisoner_3.reached_generator.connect(_on_prisoner_3_reached_generator)
	_pick_order()
	GameState.reset()
	Sfx.loop("ambient", -16.0)
	_enter.call_deferred(Phase.INTRO)


func _pick_order() -> void:
	if forced_order.size() == 3 and 1 in forced_order and 2 in forced_order and 3 in forced_order:
		order = forced_order.duplicate()
	else:
		order = [1, 2, 3]
		order.shuffle()
	if OS.is_debug_build():
		print("Ordre des détenus : ", order)


func _process(delta: float) -> void:
	if _final_return and phase != Phase.ENDING:
		var p := _player()
		if p and PrisonNav.room_at(p.global_position) == "B":
			_final_return = false
			_enter(Phase.ENDING)
	if _calm_left > 0.0:
		_calm_left -= delta
		if _calm_left <= 0.0:
			_calm_left = -1.0
			_begin_turn(_turn + 1)
			_start_turn()


func _enter(p: Phase) -> void:
	phase = p
	Events.phase_changed.emit(p)
	match p:
		Phase.INTRO:
			# si le 1 passe en premier, il est déjà caché dans son angle mort :
			# quand le téléphone parle de lui, sa cellule paraît vide
			if order[0] == 1 and prisoner_1:
				prisoner_1.start_escape()
			Events.fade_requested.emit(false, 2.0)
			await get_tree().create_timer(1.2, false).timeout
			Events.show_document.emit(Texts.INTRO_TITLE, Texts.INTRO_BODY)
			await Events.document_closed
			Sfx.play("phone_ring", -4.0)
			await get_tree().create_timer(2.2, false).timeout
			# le seul appel du jeu (il ne dit plus par quelle cellule commencer)
			await Dialogue.say(&"intro")
			if phase != Phase.INTRO:
				return
			_objective(&"intro")
			_begin_turn(0)
		Phase.BLACKOUT:
			var player := _player()
			if player:
				_checkpoint_pos = player.global_position
				_checkpoint_yaw = player.rotation.y
			Sfx.play("power_down")
			GameState.set_power(false)
			await get_tree().create_timer(1.2, false).timeout
			Dialogue.say(&"blackout")
			# carte déjà retenue (post-it) : pas besoin d'aller la chercher
			_objective(&"blackout_carte" if GameState.has_map else &"blackout")
			await get_tree().create_timer(3.0, false).timeout
			if prisoner_3 and not prisoner_3.resolved and not GameState.power_on:
				prisoner_3.start_stalking()
		Phase.ENDING:
			Events.fade_requested.emit(true, 2.5)
			await get_tree().create_timer(2.8, false).timeout
			Events.ending_reached.emit(GameState.compute_ending())


## Passe au tour i (le détenu order[i]). L'évasion démarre avec _start_turn().
func _begin_turn(i: int) -> void:
	_turn = i
	_current = order[i]
	_turn_started = false
	_enter(_turn_phase())
	# premier tour : il démarre quand le joueur s'installe aux écrans (il y est peut-être déjà)
	if i == 0:
		var sys := _camera_system()
		if sys and sys.active:
			_start_turn()


## Réplique du garde, objectif, et le détenu passe à l'action.
func _start_turn() -> void:
	if _turn_started or _turn < 0:
		return
	_turn_started = true
	if _turn > 0:
		Sfx.play("static", -10.0, 0.8)  # grésillement sur les écrans : quelque chose bouge
	Dialogue.say(_turn_line())
	_objective(StringName("turn_%d" % _current))
	match _current:
		1:
			_start_prisoner_1()
		2:
			if prisoner_2:
				prisoner_2.start_escape()
		3:
			if prisoner_3:
				prisoner_3.start_escape()


func _turn_line() -> StringName:
	match _current:
		1:
			return &"turn_1" if _turn == 0 else &"turn_1_suite"  # « la cellule 1 d'abord »
		2:
			return &"turn_2"
		_:
			return &"turn_3" if _is_last_turn() else &"turn_3_suite"  # « plus que le 3 »


func _start_prisoner_1() -> void:
	if prisoner_1 == null:
		return
	var sys := _camera_system()
	var watching := sys != null and sys.is_watching(CELL_CAMERAS[1])
	if not prisoner_1.is_hiding():
		if watching:
			Sfx.play("static", -4.0)  # il disparaît sous les parasites, en direct
		prisoner_1.start_escape()
	if watching:
		_cell_1_viewed(true)


func _cell_1_viewed(after_line: bool) -> void:
	if _cell_1_seen:
		return
	_cell_1_seen = true
	if prisoner_1 and prisoner_1.cell_door:
		prisoner_1.cell_door.unlock()
	if after_line:
		Dialogue.say_after(&"turn_1_empty")
	else:
		Dialogue.say(&"turn_1_empty")
	_objective(&"turn_1_empty")


## Le détenu du tour est maîtrisé : retour aux écrans, ou fin de la nuit après le dernier.
func _turn_finished(id: int) -> void:
	if id in _done:
		return
	_done.append(id)
	if phase == Phase.BLACKOUT:
		_enter(_turn_phase())
	if _is_last_turn():
		_objective(&"turn_3_done")  # retourner au bureau
		_final_return = true
		return
	_objective(&"turn_1_done")  # retourner au poste de surveillance
	_awaiting_return = true
	var sys := _camera_system()
	if sys and sys.active:
		_on_camera_mode_changed(true)


func _on_camera_mode_changed(on: bool) -> void:
	if not on:
		return
	if _turn == 0 and not _turn_started and phase == Phase.TURN_1:
		_start_turn()
	elif _awaiting_return:
		_awaiting_return = false
		_calm_left = randf_range(calm_min, calm_max)
		_objective(&"calme")


func _on_camera_viewed(camera_id: StringName) -> void:
	if _current == 1 and _turn_started and camera_id == CELL_CAMERAS[1]:
		_cell_1_viewed(false)


## Le 1 a bousculé le garde et s'enfuit : traque au pistolet.
func _on_prisoner_1_fled() -> void:
	Dialogue.say(&"turn_1_fuite")
	_objective(&"turn_1_traque")


func _on_encounter_resolved(prisoner_id: int, killed: bool) -> void:
	await get_tree().create_timer(2.0, false).timeout
	if prisoner_id in _done or phase == Phase.ENDING:
		return
	if prisoner_id == 2:
		Dialogue.say(&"turn_2_tue" if killed else &"turn_2_calme")
	else:
		# « Un de moins… Retour aux écrans. » / « C'est fini… Les trois sont maîtrisés. »
		Dialogue.say(&"turn_3_done" if _is_last_turn() else &"turn_1_done")
	_turn_finished(prisoner_id)


func _on_prisoner_2_escaped(seen: bool) -> void:
	if _current != 2:
		return
	_objective(&"turn_2_sortie")
	if seen:
		_say_p2_exit()


func _on_prisoner_2_spotted(where: StringName) -> void:
	if _current != 2:
		return
	if where == &"route":
		_say_p2_exit()
	else:
		Dialogue.say_after(&"turn_2_refectoire")  # sans couper « il a forcé sa porte »
		_objective(&"turn_2_refectoire")


func _say_p2_exit() -> void:
	if not _p2_exit_said:
		_p2_exit_said = true
		Dialogue.say_after(&"turn_2_sortie")  # sans couper « voyons la cellule 2 »


func _on_prisoner_2_arrived() -> void:
	if _current == 2:
		_objective(&"turn_2_refectoire")


## Négociation réussie : aucun mort.
func _on_prisoner_2_calmed() -> void:
	if _current != 2:
		return
	GameState.resolve_prisoner(2, false)
	await get_tree().create_timer(1.5, false).timeout
	Dialogue.say(&"turn_2_calme")
	_turn_finished(2)


func _on_prisoner_3_escaped(seen: bool) -> void:
	if _current != 3:
		return
	_objective(&"turn_3_sortie")
	if seen:
		_say_p3_exit()


func _say_p3_exit() -> void:
	if _current == 3 and not _p3_exit_said:
		_p3_exit_said = true
		Dialogue.say_after(&"turn_3_sortie")


func _on_prisoner_3_reached_generator() -> void:
	if _current == 3 and phase != Phase.BLACKOUT:
		_enter(Phase.BLACKOUT)


func _on_power_changed(on: bool) -> void:
	# le joueur a rallumé le générateur : screamer du détenu 3
	if on and phase == Phase.BLACKOUT and prisoner_3 and not prisoner_3.resolved:
		var player := _player()
		if player:
			prisoner_3.screamer_at(player)


func _on_map_taken() -> void:
	if phase == Phase.BLACKOUT and not GameState.power_on:
		_objective(&"blackout_carte")


func _on_player_caught() -> void:
	var player := _player()
	if player == null or GameState.is_dead():
		return
	player.set_lock(&"caught", true)
	Sfx.play("screamer", 0.0, 0.8)
	Events.shake.emit(1.5)
	GameState.hurt()  # deuxième coup sans médicaments : il y reste
	if GameState.is_dead():
		return
	Events.fade_requested.emit(true, 0.4)
	await get_tree().create_timer(1.6, false).timeout
	player.teleport(_checkpoint_pos, _checkpoint_yaw)
	if prisoner_3:
		prisoner_3.respawn_far_from(_checkpoint_pos)
	Events.fade_requested.emit(false, 1.2)
	Dialogue.say(&"caught")
	player.set_lock(&"caught", false)


## Le garde est mort : quatrième fin.
func _on_player_died() -> void:
	if phase == Phase.ENDING:
		return
	_final_return = false
	_calm_left = -1.0
	Dialogue.stop()
	var player := _player()
	if player:
		player.collapse()
	Events.flash.emit(Color(0.6, 0.0, 0.0, 0.85))
	Events.shake.emit(2.0)
	phase = Phase.ENDING
	Events.phase_changed.emit(phase)
	await get_tree().create_timer(1.0, false).timeout
	Events.fade_requested.emit(true, 1.6)
	await get_tree().create_timer(2.0, false).timeout
	Events.ending_reached.emit(GameState.Ending.MORT)


## Touches de test : F2 / F3 = passer au 2e / 3e tour, F4 = panne du détenu 3,
## J = fin, K = détenu 3 tout près (panne), F7 = téléportation.
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F2:
			_debug_skip_to(1)
		KEY_F3:
			_debug_skip_to(2)
		KEY_F4:
			_debug_blackout()
		KEY_J:
			if phase != Phase.ENDING:
				_enter(Phase.ENDING)
		KEY_K:
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


## Maîtrise d'office les détenus des tours avant i.
func _debug_resolve_before(i: int) -> void:
	for j in i:
		var pr := _prisoner(order[j])
		if pr and not pr.resolved:
			GameState.resolve_prisoner(pr.prisoner_id, false)
			pr.on_resolved(false)
		if not order[j] in _done:
			_done.append(order[j])
	_calm_left = -1.0
	_awaiting_return = false


func _debug_skip_to(i: int) -> void:
	_debug_resolve_before(i)
	_begin_turn(i)
	_start_turn()
	Events.subtitle.emit("[debug] tour %d : détenu %d" % [i + 1, _current], 2.0)


func _debug_blackout() -> void:
	var i := order.find(3)
	_debug_resolve_before(i)
	_begin_turn(i)
	_turn_started = true
	if prisoner_3:
		if prisoner_3.cell_door:
			prisoner_3.cell_door.open()
		if prisoner_3._in_bed:
			prisoner_3._get_up()
	_on_prisoner_3_reached_generator()


func _turn_phase() -> Phase:
	match _turn:
		0:
			return Phase.TURN_1
		1:
			return Phase.TURN_2
	return Phase.TURN_3


func _is_last_turn() -> bool:
	return _turn >= order.size() - 1


func _prisoner(id: int) -> Prisoner:
	match id:
		1:
			return prisoner_1
		2:
			return prisoner_2
		3:
			return prisoner_3
	return null


func _objective(key: StringName) -> void:
	Events.objective_changed.emit(Texts.OBJECTIVES.get(key, ""))


func _camera_system() -> CameraSystem:
	return get_tree().get_first_node_in_group(&"camera_system") as CameraSystem


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player
