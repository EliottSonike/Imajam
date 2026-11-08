extends Node
## État global de la partie (items, journaux, kills, courant, carte).

enum Ending { NONE, BON, BRUTE, TRUAND }

const ITEM_GUN := &"gun"
const ITEM_TASER := &"taser"
const ITEM_MEDS := &"meds"
const JOURNAL_COUNT := 4
const OUTCOME_TASER := "maîtrisé (taser)"
const OUTCOME_KILLED := "abattu"
const OUTCOME_CALMED := "calmé, sans arme"
const PROGRESS_PATH := "user://progression.cfg"

var items: Dictionary = {}
var journals: Array[bool] = []
var has_killed := false
var has_map := false
var power_on := true
var vision_impaired := false
## Sort de chaque détenu (id -> OUTCOME_*), pour le rapport de fin.
var outcomes: Dictionary = {}
var _start_ms := 0


func _ready() -> void:
	reset()
	
# Remettre l'état de départ.
func reset() -> void:
	items = {ITEM_GUN: 1}
	journals.resize(JOURNAL_COUNT)
	journals.fill(false)
	has_killed = false
	has_map = false
	power_on = true
	vision_impaired = false
	outcomes = {}
	_start_ms = Time.get_ticks_msec()

# Ajouter l'item, puis émettre item_picked
func add_item(id: StringName, count := 1) -> void:
	items[id] =  items.get(id,0) + count
	Events.item_picked.emit(id)

# Renvoyer vrai si l'item est détenu
func has_item(id: StringName) -> bool:
	return items.get(id,0) > 0

func set_vision_impaired(value: bool) -> void:
	vision_impaired = value
	Events.vision_changed.emit(value)

func use_meds() -> bool:
	if not(has_item(ITEM_MEDS)) or not(vision_impaired):
		return false
	items[ITEM_MEDS] -= 1
	set_vision_impaired(false)
	return true 

# ramasse le journal
func pick_journal(index: int) -> void:
	if index < 0 or index >= JOURNAL_COUNT : 
		return
	journals[index] = true
	Events.journal_picked.emit(index)

func journal_count() -> int:
	return journals.count(true)


func take_map() -> void:
	has_map = true
	Events.map_taken.emit()


func set_power(on: bool) -> void:
	if power_on == on : 
		return
	else :
		power_on = on
		Events.power_changed.emit(on)
	


func resolve_prisoner(prisoner_id: int, killed: bool, calmed := false) -> void:
	outcomes[prisoner_id] = OUTCOME_KILLED if killed else (OUTCOME_CALMED if calmed else OUTCOME_TASER)
	if killed :
		has_killed = true
			


func compute_ending() -> Ending:
	if journal_count() == JOURNAL_COUNT:
		return Ending.TRUAND
	if has_killed :
		return Ending.BRUTE
	else : 
		return Ending.BON


func elapsed_seconds() -> int:
	return int((Time.get_ticks_msec() - _start_ms) / 1000.0)


## Fins déjà vues (gardées d'une partie à l'autre).
func ending_seen(ending: int) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	return cfg.get_value("fins", str(ending), false)


func mark_ending_seen(ending: int) -> void:
	if ending <= Ending.NONE:
		return
	var cfg := ConfigFile.new()
	cfg.load(PROGRESS_PATH)
	cfg.set_value("fins", str(ending), true)
	cfg.save(PROGRESS_PATH)
