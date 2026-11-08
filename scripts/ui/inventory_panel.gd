class_name InventoryPanel
extends Control

var _items: VBoxContainer
var _page: GridContainer


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.menu_bg())

	var pocket := PanelContainer.new()
	UiTheme.centered(pocket, Vector2(1080, 660))
	pocket.add_theme_stylebox_override("panel", UiTheme.pocket())
	add_child(pocket)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	pocket.add_child(root)
	# bouton au milieu du bas du rabat (frère de la poche : un conteneur l'aurait étiré)
	var bouton := UiTheme.pocket_button()
	UiTheme.centered(bouton, Vector2(44, 44))
	bouton.position.y -= 330 - 52
	add_child(bouton)
	var head := UiTheme.header("Effets personnels", "CASIER N° 07")
	var close_btn := UiTheme.button("Fermer   [Tab]", 200)
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	root.add_child(head)
	var under_flap := Control.new()
	under_flap.custom_minimum_size.y = 34  # le contenu commence sous le rabat
	root.add_child(under_flap)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.add_theme_constant_override("separation", 10)
	left.add_child(UiTheme.mono("OBJETS", 14, UiTheme.AMBER))
	_items = VBoxContainer.new()
	_items.add_theme_constant_override("separation", 8)
	left.add_child(_items)
	cols.add_child(left)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	right.add_child(UiTheme.mono("JOURNAL — PAGES RETROUVÉES", 14, UiTheme.AMBER))
	_page = GridContainer.new()
	_page.columns = 2
	_page.add_theme_constant_override("h_separation", 6)
	_page.add_theme_constant_override("v_separation", 6)
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_page)
	cols.add_child(right)


## Tab ferme l'inventaire même si un bouton a le focus.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"inventory"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_refresh()
	show()
	_lock(true)
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	_lock(false)
	Events.ui_modal_changed.emit(false)


func _refresh() -> void:
	for c in _items.get_children():
		c.queue_free()
	for c in _page.get_children():
		c.queue_free()

	_items.add_child(UiTheme.label("▪ Pistolet", 19))
	if GameState.has_item(GameState.ITEM_TASER):
		_items.add_child(UiTheme.label("▪ Taser", 19))
	var meds: int = GameState.items.get(GameState.ITEM_MEDS, 0)
	if meds > 0:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(UiTheme.label("▪ Médicaments ×%d" % meds, 19))
		var use := UiTheme.button("Prendre  [R]", 150)
		use.disabled = not GameState.vision_impaired
		use.tooltip_text = "Soigne la vision trouble"
		use.pressed.connect(_on_use_meds)
		row.add_child(use)
		_items.add_child(row)
	if GameState.vision_impaired:
		_items.add_child(UiTheme.label("Vision trouble", 16, UiTheme.DANGER))

	for i in GameState.JOURNAL_COUNT:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(300, 190)
		var box := StyleBoxFlat.new()
		if GameState.journals[i]:
			box.bg_color = UiTheme.PAPER
			box.border_color = Color(0.45, 0.38, 0.28)
		else:
			box.bg_color = Color(0.03, 0.05, 0.09, 0.45)
			box.border_color = Color(0.55, 0.6, 0.72, 0.3)
		box.set_border_width_all(1)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		cell.add_theme_stylebox_override("panel", box)
		if GameState.journals[i]:
			var page: Dictionary = Texts.JOURNALS[i]
			var b := Button.new()
			b.flat = true
			b.text = page["title"] + "\n\n(cliquer pour relire)"
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.add_theme_color_override("font_color", Color(0.18, 0.14, 0.1))
			b.add_theme_color_override("font_hover_color", Color(0.45, 0.2, 0.1))
			b.add_theme_font_override("font", load("res://assets/fonts/Caveat.ttf"))
			b.add_theme_font_size_override("font_size", 26)
			b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			b.pressed.connect(func() -> void: Events.show_document.emit(page["title"], page["body"]))
			cell.add_child(b)
		else:
			var l := UiTheme.label("— morceau manquant —", 16, UiTheme.DIM)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell.add_child(l)
		_page.add_child(cell)


func _on_use_meds() -> void:
	if GameState.use_meds():
		Sfx.play("pickup")
	_refresh()


func _lock(on: bool) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"inventory", on)
