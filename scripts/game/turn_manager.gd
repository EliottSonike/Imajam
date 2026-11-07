class_name TurnManager
extends Node
## Machine à états : intro → tour 1 → tour 2 → tour 3 → panne → fin.

enum Phase { INTRO, TURN_1, TURN_2, TURN_3, BLACKOUT, ENDING }

@export var prisoner_1: PrisonerHider
@export var prisoner_2: PrisonerTracker
@export var prisoner_3: PrisonerStalker

var phase := Phase.INTRO
var _turn_1_cell_seen := false

func _ready() -> void:
	Events.encounter_resolved.connect(_on_encounter_resolved)
	_enter.call_deferred(Phase.INTRO)
	Events.camera_viewed.connect(_on_camera_viewed)


func _enter(p: Phase) -> void:
	phase = p
	Events.phase_changed.emit(p)
	match p:
		Phase.INTRO:
			Events.show_document.emit(Texts.INTRO_TITLE, Texts.INTRO_BODY)
			await Events.document_closed
			_enter(Phase.TURN_1)
		Phase.TURN_1:
			_phone(&"turn_1")
			_objective(&"turn_1")
			if prisoner_1 :
				prisoner_1.start_escape()
		Phase.TURN_2:
			_phone(&"turn_2")
			_objective(&"turn_2")
			if prisoner_2 :
				prisoner_2.start_escape()
		Phase.TURN_3:
			_phone(&"turn_3")
			_objective(&"turn_3")
			if prisoner_3 :
				prisoner_3.start_escape()
		Phase.BLACKOUT:
			pass
		Phase.ENDING:
			Events.ending_reached.emit(GameState.compute_ending()) 

func _on_camera_viewed(camera_id: StringName) -> void:
	if phase != Phase.TURN_1 or camera_id != &"cell_1" or _turn_1_cell_seen:
		return
	_turn_1_cell_seen = true
	_phone(&"turn_1_empty")
	_objective(&"turn_1_empty")

func _on_encounter_resolved(prisoner_id: int, _killed: bool) -> void:
	match prisoner_id :
		1 : _enter(Phase.TURN_2)
		2 : _enter(Phase.TURN_3)
		3 : _enter(Phase.ENDING)


func _on_player_caught() -> void:
	pass

func _phone(key: StringName) -> void:
	Events.subtitle.emit(Texts.PHONE.get(key, ""), 5.0)


func _objective(key: StringName) -> void:
	Events.objective_changed.emit(Texts.OBJECTIVES.get(key, ""))
