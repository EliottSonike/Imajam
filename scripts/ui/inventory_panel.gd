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
	left.custom_minimum_size = Vector2(340, 0)
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

	_items.add_child(_item_card("objet_pistolet.png", "Pistolet", "Arme de service. Chargé."))
	if GameState.has_item(GameState.ITEM_TASER):
		_items.add_child(_item_card("objet_taser.png", "Taser", "Neutralise sans tuer."))
	var meds: int = GameState.items.get(GameState.ITEM_MEDS, 0)
	if meds > 0:
		var card := _item_card("objet_medicaments.png", "Médicaments  ×%d" % meds, "Soignent la vision trouble.")
		var use := UiTheme.button("Prendre [R]", 0.0)
		use.custom_minimum_size = Vector2(130, 40)
		use.add_theme_font_size_override("font_size", 16)
		use.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		use.disabled = not GameState.vision_impaired
		use.pressed.connect(_on_use_meds)
		card.get_child(0).add_child(use)
		_items.add_child(card)
	if GameState.vision_impaired:
		_items.add_child(UiTheme.mono("● VISION TROUBLE", 13, UiTheme.DANGER))

	for i in GameState.JOURNAL_COUNT:
		var found: bool = GameState.journals[i]
		var page := JournalThumb.new()
		page.index = i
		page.found = found
		page.custom_minimum_size = Vector2(300, 196)
		if found:
			var data: Dictionary = Texts.JOURNALS[i]
			page.title = data["title"]
			page.excerpt = data["body"]
			page.pressed.connect(func() -> void: Events.show_document.emit(data["title"], data["body"]))
		_page.add_child(page)


## Fiche d'un objet : vignette, nom, description (et éventuellement un bouton d'action).
func _item_card(icon: String, title: String, desc: String) -> PanelContainer:
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.03, 0.05, 0.09, 0.45)
	box.border_color = Color(0.55, 0.6, 0.72, 0.3)
	box.set_border_width_all(1)
	box.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var pic := TextureRect.new()
	pic.texture = load("res://assets/ui/theme/" + icon)
	pic.custom_minimum_size = Vector2(76, 76)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 2)
	text.add_child(UiTheme.label(title, 19, UiTheme.ACCENT))
	var d := UiTheme.mono(desc, 12)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(d)
	row.add_child(text)
	return card


func _on_use_meds() -> void:
	if GameState.use_meds():
		Sfx.play("pickup")
	_refresh()


func _lock(on: bool) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"inventory", on)



## Miniature d'une page de carnet (trouvée : papier ligné, titre et début du texte ; sinon emplacement vide).
class JournalThumb:
	extends Control
	signal pressed

	const PAPER := Color(0.95, 0.93, 0.86)
	const INK := Color(0.12, 0.14, 0.32)
	const RULE := Color(0.45, 0.6, 0.85, 0.45)
	const MARGIN := Color(0.85, 0.25, 0.25, 0.55)

	var index := 0
	var found := false
	var title := ""
	var excerpt := ""
	var _hover := false
	var _font: Font = load("res://assets/fonts/Caveat.ttf")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP if found else Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if found else Control.CURSOR_ARROW
		mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
		mouse_exited.connect(func() -> void: _hover = false; queue_redraw())
		var re := RegEx.create_from_string("\\[[^\\]]*\\]")
		excerpt = re.sub(excerpt, "", true).replace("\n", " ").strip_edges()

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if found and mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			Sfx.play("ui_click", -6.0)
			pressed.emit()

	func _draw() -> void:
		var r := Rect2(Vector2(10, 8), size - Vector2(20, 16))
		if not found:
			_dashed(r, Color(0.6, 0.65, 0.78, 0.35))
			var t := "page %d — manquante" % (index + 1)
			var f := UiTheme.font()
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(f, r.get_center() + Vector2(-w / 2.0, 4), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.65, 0.78, 0.6))
			return
		var angle := deg_to_rad([-2.2, 1.6, -1.1, 2.4][index % 4]) * (0.4 if _hover else 1.0)
		var lift := -4.0 if _hover else 0.0
		draw_set_transform(size / 2.0 + Vector2(0, lift), angle)
		var p := Rect2(r.position - size / 2.0, r.size)
		draw_rect(Rect2(p.position + Vector2(4, 6), p.size), Color(0, 0, 0, 0.45))  # ombre
		draw_rect(p, PAPER)
		for y in range(int(p.position.y) + 42, int(p.end.y) - 6, 21):
			draw_line(Vector2(p.position.x + 6, y), Vector2(p.end.x - 6, y), RULE, 1.0)
		draw_line(Vector2(p.position.x + 30, p.position.y + 4), Vector2(p.position.x + 30, p.end.y - 4), MARGIN, 1.5)
		draw_string(_font, p.position + Vector2(38, 34), title, HORIZONTAL_ALIGNMENT_LEFT, p.size.x - 46, 24, INK)
		draw_multiline_string(_font, p.position + Vector2(38, 59), excerpt, HORIZONTAL_ALIGNMENT_LEFT,
			p.size.x - 48, 19, 5, Color(INK, 0.85))
		var n := "%d / 4" % (index + 1)
		draw_string(_font, p.end + Vector2(-34, -6), n, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(INK, 0.6))
		draw_set_transform(Vector2.ZERO, 0.0)

	func _dashed(r: Rect2, c: Color) -> void:
		var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
		for i in 4:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var l := a.distance_to(b)
			var d := 0.0
			while d < l:
				draw_line(a.lerp(b, d / l), a.lerp(b, minf(d + 7.0, l) / l), c, 1.0)
				d += 12.0
