extends Node
## État global de la partie (items, journaux, kills, courant, carte).

enum Ending { NONE, BON, BRUTE, TRUAND }

const ITEM_GUN := &"gun"
const ITEM_TASER := &"taser"
const ITEM_MEDS := &"meds"
const JOURNAL_COUNT := 4

var items: Dictionary = {}
var journals: Array[bool] = []
var has_killed := false
var has_map_memory := false
var power_on := true
var vision_impaired := false

# Remettre l’état de départ. Le joueur a le gun dès le début
func reset() -> void:
	items = {ITEM_GUN: 1}
	journals.resize(JOURNAL_COUNT)
	journals.fill(false)
	has_killed = false
	has_map_memory = false
	power_on = true
	vision_impaired = false

# Ajouter l’item, puis émettre item_picked
func add_item(id: StringName, count := 1) -> void:
	items[id] =  items.get(id,0) + count
	Events.item_picked.emit(id)


func has_item(id: StringName) -> bool:
	return false


func use_meds() -> bool:
	return false


func pick_journal(index: int) -> void:
	pass


func journal_count() -> int:
	return 0


func memorize_map() -> void:
	pass


func set_power(on: bool) -> void:
	pass


func resolve_prisoner(prisoner_id: int, killed: bool) -> void:
	pass


func compute_ending() -> Ending:
	return Ending.NONE
