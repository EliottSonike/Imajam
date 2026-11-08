extends Node
## État global de la partie (items, journaux, kills, courant, carte).

enum Ending { NONE, BON, BRUTE, TRUAND, MORT }

const ITEM_GUN := &"gun"
const ITEM_TASER := &"taser"
const ITEM_MEDS := &"meds"
const JOURNAL_COUNT := 4
## Deux vies : au premier coup la vision se trouble, au deuxième (sans médicaments entre-temps) il meurt.
const MAX_HEALTH := 2

var items: Dictionary = {}
var journals: Array[bool] = []
var has_killed := false
var has_map := false
var power_on := true
var vision_impaired := false
var health := MAX_HEALTH


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
	health = MAX_HEALTH

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
	health = MAX_HEALTH
	set_vision_impaired(false)
	return true 


## Le garde prend un coup : vision trouble, puis la mort s'il n'a pas pris de médicaments.
func hurt(amount := 1) -> void:
	if health <= 0:
		return
	health = maxi(health - amount, 0)
	Events.player_hurt.emit(health)
	if health <= 0:
		Events.player_died.emit()
	else:
		set_vision_impaired(true)


func is_dead() -> bool:
	return health <= 0

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
	


func resolve_prisoner(_prisoner_id: int, killed: bool) -> void:
	if killed :
		has_killed = true
			


func compute_ending() -> Ending:
	if journal_count() == JOURNAL_COUNT:
		return Ending.TRUAND
	if has_killed :
		return Ending.BRUTE
	else : 
		return Ending.BON
