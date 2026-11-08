class_name DocumentPanel
extends Control
## Affiche un document : l'intro comme la une d'un vrai journal, les bouts de journal comme
## des pages arrachées au carnet du gardien. Se ferme avec E, Échap ou le bouton.
## Le style est choisi selon le titre : Texts.INTRO_TITLE = journal, le reste = page de carnet.

const F_MAST := "res://assets/fonts/UnifrakturMaguntia-Book.ttf"
const F_SERIF := "res://assets/fonts/OldStandard-Regular.ttf"
const F_SERIF_B := "res://assets/fonts/OldStandard-Bold.ttf"
const F_SERIF_I := "res://assets/fonts/OldStandard-Italic.ttf"
const F_HAND := "res://assets/fonts/Caveat.ttf"

const NEWS_SIZE := Vector2(880, 540)
const PAGE_SIZE := Vector2(520, 600)

var _news: NewsPaper
var _page: NotebookPage
var _current: Control
var _close_btn: Button


func _ready() -> void:
	UiTheme.full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(UiTheme.dim(0.7))

	_news = NewsPaper.new()
	UiTheme.centered(_news, NEWS_SIZE)
	_news.offset_top -= 26
	_news.offset_bottom -= 26
	add_child(_news)

	_page = NotebookPage.new()
	UiTheme.centered(_page, PAGE_SIZE)
	_page.offset_top -= 26
	_page.offset_bottom -= 26
	add_child(_page)

	_close_btn = UiTheme.button("Fermer   [E]", 220)
	_close_btn.anchor_left = 0.5
	_close_btn.anchor_right = 0.5
	_close_btn.anchor_top = 1.0
	_close_btn.anchor_bottom = 1.0
	_close_btn.offset_left = -110
	_close_btn.offset_right = 110
	_close_btn.offset_top = -58
	_close_btn.offset_bottom = -12
	_close_btn.pressed.connect(close)
	add_child(_close_btn)


func open(title := "", body := "") -> void:
	var is_news := title == Texts.INTRO_TITLE
	_news.visible = is_news
	_page.visible = not is_news
	_current = _news if is_news else _page
	if is_news:
		_news.set_content(title, body)
	else:
		_page.set_content(title, body)
	show()
	UiTheme.pop_in(self)
	var y0 := _current.position.y
	_current.position.y = y0 + 24.0
	create_tween().tween_property(_current, "position:y", y0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_lock(true)
	Events.ui_modal_changed.emit(true)


func close() -> void:
	if not visible:
		return
	hide()
	_lock(false)
	Events.ui_modal_changed.emit(false)
	Events.document_closed.emit()


func _lock(on: bool) -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p:
		p.set_lock(&"document", on)


static func _font(path: String) -> Font:
	return load(path) as Font


static func _rich(normal: String, size: int, color: Color) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", _font(normal))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", color)
	return r


static func _plain_label(text: String, font_path: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", _font(font_path))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# =====================================================================================
# La une du journal (intro)
# =====================================================================================

class NewsPaper extends Control:
	const PAPER := Color(0.91, 0.88, 0.8)
	const INK := Color(0.1, 0.09, 0.08)
	const INK_SOFT := Color(0.28, 0.26, 0.23)
	const M := 34.0  # marge

	var _mast: Label
	var _date_c: Label
	var _headline: Label
	var _cols: Array[RichTextLabel] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		rotation_degrees = -0.6
		var w := 880.0 - 2.0 * M
		_mast = DocumentPanel._plain_label("", DocumentPanel.F_MAST, 62, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_place(_mast, M, 8, w, 76)
		_place(DocumentPanel._plain_label("N° 12 847", DocumentPanel.F_SERIF, 13, INK_SOFT), M, 92, 260, 18)
		_date_c = DocumentPanel._plain_label("", DocumentPanel.F_SERIF_B, 13, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_place(_date_c, 300, 92, 280, 18)
		_place(DocumentPanel._plain_label("1,20 €", DocumentPanel.F_SERIF, 13, INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT), 880 - M - 260, 92, 260, 18)
		_headline = DocumentPanel._plain_label("", DocumentPanel.F_SERIF_B, 38, INK, HORIZONTAL_ALIGNMENT_CENTER)
		_place(_headline, M, 128, w, 50)
		_place(HalftonePhoto.new(), M, 196, 250, 214)
		var caption := DocumentPanel._plain_label("Le pénitencier Saint-Roch, vu depuis la route nationale.", DocumentPanel.F_SERIF_I, 13, INK_SOFT)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_place(caption, M, 416, 250, 44)
		for x in [302.0, 583.0]:
			var col := DocumentPanel._rich(DocumentPanel.F_SERIF, 19, INK)
			col.add_theme_font_override("bold_font", DocumentPanel._font(DocumentPanel.F_SERIF_B))
			col.add_theme_font_override("italics_font", DocumentPanel._font(DocumentPanel.F_SERIF_I))
			col.add_theme_constant_override("line_separation", 3)
			_place(col, x, 196, 263, 296)
			_cols.append(col)
		_place(DocumentPanel._plain_label("Faits divers — page 1", DocumentPanel.F_SERIF_I, 12, INK_SOFT), M, 510, 300, 16)
		_place(DocumentPanel._plain_label("Suite en page 4", DocumentPanel.F_SERIF_I, 12, INK_SOFT, HORIZONTAL_ALIGNMENT_RIGHT), 880 - M - 300, 510, 300, 16)

	func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
		c.position = Vector2(x, y)
		c.size = Vector2(w, h)
		add_child(c)

	func set_content(title: String, body: String) -> void:
		var parts := title.split(" — ", false, 1)
		_mast.text = _masthead(parts[0])
		_date_c.text = parts[1].to_upper() if parts.size() > 1 else ""
		# Gros titre = premier [b]…[/b] du texte ; l'indication « (Appuie sur E…) » est retirée,
		# le bouton Fermer [E] l'affiche déjà.
		var m := RegEx.create_from_string("\\[b\\](.*?)\\[/b\\]").search(body)
		_headline.text = m.get_string(1) if m else ""
		var rest := body.replace(m.get_string(0), "") if m else body
		rest = RegEx.create_from_string("\\[i\\]\\(.*?\\)\\[/i\\]").sub(rest, "", true)
		var paragraphs: Array[String] = []
		for p in rest.split("\n\n"):
			if p.strip_edges() != "":
				paragraphs.append(p.strip_edges())
		# Deux colonnes équilibrées : le texte passe de l'une à l'autre au milieu d'un paragraphe,
		# comme dans un vrai journal.
		var text := "\n\n".join(paragraphs).replace("« ", "«\u00A0").replace(" »", "\u00A0»")
		# On coupe de préférence entre deux paragraphes s'il y en a un près du milieu,
		# sinon au milieu d'un paragraphe (au mot près).
		var half := text.length() / 2
		var cut := -1
		var skip := 1
		var i := text.find("\n\n")
		while i >= 0:
			if absi(i - half) < text.length() * 0.15 and (cut < 0 or absi(i - half) < absi(cut - half)):
				cut = i
				skip = 2
			i = text.find("\n\n", i + 2)
		if cut < 0:
			cut = text.find(" ", half)
			skip = 1
		if cut < 0:
			cut = text.length()
		_cols[0].text = "[fill]" + text.substr(0, cut) + "[/fill]"
		_cols[1].text = "[fill]" + text.substr(cut + skip) + "[/fill]"
		queue_redraw()

	## « LE COURRIER DU SOIR » -> « Le Courrier du Soir » (la gothique ne s'écrit pas en capitales).
	func _masthead(s: String) -> String:
		var small := ["du", "de", "la", "le", "des", "et", "à"]
		var words := s.to_lower().split(" ", false)
		for i in words.size():
			if i == 0 or not small.has(words[i]):
				words[i] = words[i].capitalize()
		return " ".join(words)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(Rect2(r.position + Vector2(8, 10), r.size), Color(0, 0, 0, 0.45))
		draw_rect(r, PAPER)
		# jaunissement léger des bords
		for i in 6:
			draw_rect(Rect2(Vector2(i * 3, i * 3), size - Vector2(i * 6, i * 6)), Color(0.55, 0.45, 0.25, 0.035), false, 3.0)
		# pli horizontal du journal
		var fy := size.y * 0.5
		draw_line(Vector2(0, fy), Vector2(size.x, fy), Color(0, 0, 0, 0.05), 2.0, true)
		draw_line(Vector2(0, fy + 2), Vector2(size.x, fy + 2), Color(1, 1, 1, 0.18), 1.0, true)
		# filets sous le titre du journal
		var w := size.x - 2 * M
		draw_line(Vector2(M, 88), Vector2(M + w, 88), INK, 1.0, true)
		draw_line(Vector2(M, 115), Vector2(M + w, 115), INK, 3.0, true)
		draw_line(Vector2(M, 120), Vector2(M + w, 120), INK, 1.0, true)
		draw_line(Vector2(M, 185), Vector2(M + w, 185), INK, 1.0, true)
		# filets verticaux entre les colonnes, filet de pied de page
		draw_line(Vector2(293, 198), Vector2(293, 496), INK_SOFT, 1.0, true)
		draw_line(Vector2(574, 198), Vector2(574, 496), INK_SOFT, 1.0, true)
		draw_line(Vector2(M, 503), Vector2(M + w, 503), INK, 1.0, true)


## Photo de presse en trame de points : le pénitencier de nuit, un projecteur balaie le ciel.
class HalftonePhoto extends Control:
	func _draw() -> void:
		var ink := Color(0.12, 0.11, 0.1)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.88, 0.8))
		var step := 4.0
		var y := step * 0.5
		var row := 0
		while y < size.y:
			var x := step * 0.5 + (step * 0.5 if row % 2 == 1 else 0.0)
			while x < size.x:
				var tone := _tone(Vector2(x, y) / size)
				if tone > 0.04:
					draw_circle(Vector2(x, y), step * 0.64 * sqrt(tone), ink)
				x += step
			y += step
			row += 1
		draw_rect(Rect2(Vector2.ZERO, size), ink, false, 1.0)

	## Valeur sombre (0 = papier, 1 = noir) de l'image au point uv.
	func _tone(uv: Vector2) -> float:
		var v := lerpf(0.62, 0.3, uv.y / 0.6)  # ciel de nuit, plus clair vers l'horizon
		# faisceau du projecteur, du mirador vers le haut à droite
		var lamp := Vector2(0.16, 0.16)
		var d := uv - lamp
		var ang := atan2(-d.y, d.x)
		if d.x > 0.0 and absf(ang - 0.42) < 0.07 + d.length() * 0.05:
			v *= 0.45
		var horizon := 0.62
		if uv.y > horizon:
			v = 0.72  # mur d'enceinte
			if uv.y < horizon + 0.02:
				v = 0.9  # chaperon du mur
		var in_building := uv.x > 0.34 and uv.x < 0.78 and uv.y > 0.34 and uv.y <= horizon + 0.12
		if in_building:
			v = 0.9
			var wx := fmod((uv.x - 0.37) / 0.065, 1.0)
			var wy := fmod((uv.y - 0.39) / 0.085, 1.0)
			if uv.x > 0.37 and uv.x < 0.76 and uv.y > 0.39 and uv.y < horizon + 0.06 and wx < 0.45 and wy < 0.45:
				v = 0.2  # fenêtres faiblement éclairées
		if uv.y > 0.34 - 0.06 and uv.y <= 0.34 and uv.x > 0.34 and uv.x < 0.78:
			v = 0.95  # toit
		if absf(uv.x - 0.16) < 0.045 and uv.y > 0.2 and uv.y <= horizon + 0.12:
			v = 0.95  # mirador
		if absf(uv.x - 0.16) < 0.075 and uv.y > 0.13 and uv.y <= 0.2:
			v = 0.97  # cabine du mirador
		if d.length() < 0.03:
			v = 0.02  # projecteur allumé
		if uv.y > horizon + 0.12:
			v = lerpf(0.8, 0.95, (uv.y - horizon - 0.12) / 0.26)  # route au premier plan
		return clampf(v, 0.0, 1.0)


# =====================================================================================
# Page arrachée du carnet du gardien (bouts de journal)
# =====================================================================================

class NotebookPage extends Control:
	const PAPER := Color(0.96, 0.94, 0.87)
	const RULE := Color(0.45, 0.6, 0.82, 0.55)
	const MARGIN_LINE := Color(0.82, 0.3, 0.3, 0.6)
	const INK := Color(0.12, 0.18, 0.44)
	const FIRST_RULE := 74.0
	const SPACING := 32.0
	const TEXT_X := 74.0
	const BODY_SIZE := 25
	const TITLE_SIZE := 32

	var _title: Label
	var _body: RichTextLabel
	var _torn: PackedVector2Array = []
	var _stain := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hand := DocumentPanel._font(DocumentPanel.F_HAND)
		var hand_b := FontVariation.new()
		hand_b.base_font = hand
		hand_b.variation_opentype = {"wght": 700}
		_title = Label.new()
		_title.add_theme_font_override("font", hand_b)
		_title.add_theme_font_size_override("font_size", TITLE_SIZE)
		_title.add_theme_color_override("font_color", INK)
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_title)
		_body = DocumentPanel._rich(DocumentPanel.F_HAND, BODY_SIZE, INK)
		_body.add_theme_font_override("bold_font", hand_b)
		_body.add_theme_font_override("italics_font", hand)
		# hauteur de ligne = espacement des lignes du carnet
		_body.add_theme_constant_override("line_separation", int(SPACING - hand.get_height(BODY_SIZE)))
		add_child(_body)

	func set_content(title: String, body: String) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(hash(title))  # même page = même déchirure, même inclinaison
		_stain = title.to_lower().contains("dernière")
		pivot_offset = size * 0.5
		rotation_degrees = -3.2 if _stain else rng.randf_range(0.8, 2.2) * (1.0 if rng.randf() < 0.5 else -1.0)
		_torn = PackedVector2Array()
		var x := 0.0
		while x < size.x:
			_torn.append(Vector2(x, rng.randf_range(0.0, 9.0)))
			x += rng.randf_range(6.0, 16.0)
		_torn.append(Vector2(size.x, rng.randf_range(0.0, 9.0)))

		var hand := DocumentPanel._font(DocumentPanel.F_HAND)
		var title_font := _title.get_theme_font("font")
		_title.text = title
		# le titre est posé sur la première ligne du carnet
		_title.position = Vector2(TEXT_X, FIRST_RULE - title_font.get_ascent(TITLE_SIZE) + 4)
		_title.size = Vector2(size.x - TEXT_X - 24, title_font.get_height(TITLE_SIZE))
		# le texte commence deux lignes plus bas, chaque ligne posée sur une ligne du carnet
		var first_body_rule := FIRST_RULE + SPACING * 2.0
		_body.position = Vector2(TEXT_X, first_body_rule - hand.get_ascent(BODY_SIZE) + 4)
		_body.size = Vector2(size.x - TEXT_X - 30, size.y - _body.position.y - 16)
		_body.text = body.replace("\n\n", "\n")
		queue_redraw()

	func _draw() -> void:
		if _torn.is_empty():
			return
		# ombre portée
		var shadow := PackedVector2Array()
		for p in _torn:
			shadow.append(p + Vector2(7, 9))
		shadow.append(Vector2(size.x + 7, size.y + 9))
		shadow.append(Vector2(7, size.y + 9))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.45))
		# papier avec le bord haut déchiré
		var paper := _torn.duplicate()
		paper.append(Vector2(size.x, size.y))
		paper.append(Vector2(0, size.y))
		draw_colored_polygon(paper, PAPER)
		# lignes du carnet + marge rouge
		var y := FIRST_RULE
		while y < size.y - 10:
			draw_line(Vector2(0, y), Vector2(size.x, y), RULE, 1.0, true)
			y += SPACING
		draw_line(Vector2(TEXT_X - 12, 14), Vector2(TEXT_X - 12, size.y), MARGIN_LINE, 1.5, true)
		# trous de reliure
		for hy in [size.y * 0.22, size.y * 0.5, size.y * 0.78]:
			draw_circle(Vector2(26, hy), 9.0, Color(0.05, 0.05, 0.06))
			draw_arc(Vector2(26, hy), 9.0, 0, TAU, 24, Color(0.6, 0.57, 0.5, 0.6), 1.0, true)
		# dernière page : trace de tasse de café (anneau irrégulier, plus marqué d'un côté)
		if _stain:
			var c := Vector2(size.x - 125, size.y - 135)
			var rng := RandomNumberGenerator.new()
			rng.seed = 77
			draw_circle(c, 44.0, Color(0.55, 0.38, 0.18, 0.045))
			var pts := 64
			for i in pts:
				var a0 := TAU * i / pts
				var a1 := TAU * (i + 1) / pts
				var r := 44.0 + rng.randf_range(-1.2, 1.2)
				var strength := 0.08 + 0.22 * pow(maxf(0.0, cos(a0 - 2.4)), 2.0)
				var w := 1.0 + 2.5 * strength / 0.3
				draw_line(c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r, Color(0.45, 0.29, 0.12, strength), w)
			draw_arc(c + Vector2(6, -3), 39.0, 3.6, 5.1, 20, Color(0.45, 0.29, 0.12, 0.12), 1.2, true)
