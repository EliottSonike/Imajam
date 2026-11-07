class_name TurnManager
extends Node
## Machine à états : intro → tour 1 → tour 2 → tour 3 → panne → fin.

enum Phase { INTRO, TURN_1, TURN_2, TURN_3, BLACKOUT, ENDING }

@export var prisoner_1: PrisonerHider
@export var prisoner_2: PrisonerTracker
@export var prisoner_3: PrisonerStalker

var phase := Phase.INTRO


func _ready() -> void:
	pass


func _enter(p: Phase) -> void:
	pass


func _on_camera_viewed(camera_id: StringName) -> void:
	pass


func _on_encounter_resolved(prisoner_id: int, killed: bool) -> void:
	pass


func _on_player_caught() -> void:
	pass
