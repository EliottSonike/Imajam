extends Node
## Déclaration des actions d'entrée.


func _ready() -> void:
	_add_key(&"cam_next", KEY_RIGHT)
	_add_key(&"cam_prev", KEY_LEFT)
	_add_key(&"cancel", KEY_ESCAPE)
	_add_key(&"move_forward", KEY_W)
	_add_key(&"move_back", KEY_S)
	_add_key(&"move_left", KEY_A)
	_add_key(&"move_right", KEY_D)
	_add_key(&"sprint", KEY_SHIFT)
	_add_key(&"interact", KEY_E)
	_add_key(&"inventory", KEY_TAB)


func _add_key(action: StringName, physical_key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = physical_key
	InputMap.action_add_event(action, ev)
