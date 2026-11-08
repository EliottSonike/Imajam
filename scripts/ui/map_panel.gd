class_name MapPanel
extends Control
## Carte de la prison. Le bouton « Retenir » la garde en mémoire : elle s'affiche alors en bas à droite.

var _remember: Button

func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.dim(0.6))

	var panel := PanelContainer.new()
	UiTheme.centered(panel, Vector2(960, 700))
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(UiTheme.label("PLAN DE LA PRISON SAINT-ROCH", 24, UiTheme.ACCENT))
	vb.add_child(HSeparator.new())
	var map := TextureRect.new()
	map.texture = load(MapBoard.MAP_TEXTURE)
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(map)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_remember = UiTheme.button("Retenir la carte", 240)
	_remember.pressed.connect(_on_remember)
	row.add_child(_remember)
	var close_btn := UiTheme.button("Fermer   [Échap]", 240)
	close_btn.pressed.connect(close)
	row.add_child(close_btn)


func open() -> void:
	_update_remember()
	show()
	UiTheme.pop_in(self)
	_lock(true)
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	_lock(false)
	Events.ui_modal_changed.emit(false)


func _on_remember() -> void:
	if not GameState.has_map:
		Sfx.play("pickup", -8.0)
		GameState.take_map()
	_update_remember()


func _update_remember() -> void:
	_remember.disabled = GameState.has_map
	_remember.text = "Carte retenue" if GameState.has_map else "Retenir la carte"


func _lock(on: bool) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"map", on)
