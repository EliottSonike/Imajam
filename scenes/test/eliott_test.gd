extends Node3D

func _ready() -> void:
	Events.phase_changed.connect(func(p): print("Phase : ", TurnManager.Phase.keys()[p]))
	Events.ending_reached.connect(func(e): print("Fin : ", GameState.Ending.keys()[e]))
	await get_tree().process_frame
	await get_tree().process_frame

	Events.document_closed.emit()             # le joueur ferme l'intro
	Events.camera_viewed.emit(&"cell_1")      # il regarde la cellule 1
	Events.encounter_resolved.emit(1, false)  # détenu 1 tasé
	GameState.resolve_prisoner(2, true)       # détenu 2 tué...
	Events.encounter_resolved.emit(2, true)
	Events.encounter_resolved.emit(3, false)  # détenu 3 tasé
