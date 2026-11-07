extends Panel

@onready var label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	hide() 
	$fermerBoutton.pressed.connect(close) 

func open(text: String) -> void:
	label.text = text
	show()
	_player().set_lock("document", true)

func close() -> void:
	hide()
	_player().set_lock("document", false)

func _player():
	return get_tree().get_first_node_in_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		open("Texte de test du journal.")  # debug, à enlever
