extends Node
## Bus de signaux global : les systèmes émettent / écoutent ici.

# Items / journaux / carte
signal item_picked(item_id: StringName)
signal journal_picked(index: int)
signal map_memorized

# Monde
signal power_changed(on: bool)
signal phase_changed(phase: int)

# UI / narration
signal objective_changed(text: String)
signal subtitle(text: String, duration: float)
signal say(speaker: StringName, text: String, duration: float)  ## réplique d'un personnage (sous-titre)
signal interact_prompt(text: String)
signal show_document(title: String, body: String)
signal document_closed
signal open_map_panel
signal ui_modal_changed(open: bool)
signal vision_changed(impaired: bool)

# Caméras
signal camera_mode_requested
signal camera_mode_changed(active: bool)
signal camera_viewed(camera_id: StringName)

# Prisonniers
signal encounter_requested(prisoner: Node)
signal encounter_resolved(prisoner_id: int, killed: bool)
signal screamer
signal player_caught
signal talk_requested(prisoner: Node)              ## ouvrir la négociation (détenu 2)
signal talk_finished(prisoner_id: int, success: bool)

# Fin
signal ending_reached(ending: int)

# Effets d'écran
signal fade_requested(to_black: bool, duration: float)
signal flash(color: Color)
signal shake(strength: float)
