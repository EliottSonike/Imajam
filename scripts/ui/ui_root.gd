class_name UiRoot
extends CanvasLayer
## Racine de l'UI : HUD + panneaux (construits par code, avec le thème commun).
## Gère aussi Échap / Tab, les fondus, les flashs et l'effet de vision trouble.

var hud: Hud
var postit: PostIt
var document_panel: DocumentPanel
var map_panel: MapPanel
var inventory_panel: InventoryPanel
var encounter_panel: EncounterPanel
var talk_panel: TalkPanel
var ending_panel: EndingPanel
var pause_menu: PauseMenu

var _root: Control
var _vision_fx: ColorRect
var _fade: ColorRect
var _flash: ColorRect
var _flash_tween: Tween
var _fade_tween: Tween


func _ready() -> void:
	add_to_group(&"ui_root")
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5

	_root = Control.new()
	UiTheme.full_rect(_root)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.get_theme()
	add_child(_root)

	_vision_fx = UiTheme.shader_rect(UiTheme.VISION_FX)
	(_vision_fx.material as ShaderMaterial).set_shader_parameter("amount", 0.0)
	_root.add_child(_vision_fx)
	hud = Hud.new()
	_root.add_child(hud)
	postit = PostIt.new()
	_root.add_child(postit)
	inventory_panel = InventoryPanel.new()
	_root.add_child(inventory_panel)
	map_panel = MapPanel.new()
	_root.add_child(map_panel)
	encounter_panel = EncounterPanel.new()
	_root.add_child(encounter_panel)
	talk_panel = TalkPanel.new()
	_root.add_child(talk_panel)
	document_panel = DocumentPanel.new()
	_root.add_child(document_panel)
	ending_panel = EndingPanel.new()
	_root.add_child(ending_panel)
	pause_menu = PauseMenu.new()
	_root.add_child(pause_menu)

	_flash = ColorRect.new()
	UiTheme.full_rect(_flash)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_root.add_child(_flash)
	_fade = ColorRect.new()
	UiTheme.full_rect(_fade)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0, 0, 0, 1)  # la partie commence dans le noir
	_root.add_child(_fade)

	Events.show_document.connect(func(t: String, b: String) -> void: document_panel.open(t, b))
	Events.open_map_panel.connect(map_panel.open)
	Events.encounter_requested.connect(encounter_panel.open)
	Events.talk_requested.connect(talk_panel.open)
	Events.ending_reached.connect(_on_ending)
	Events.fade_requested.connect(_on_fade)
	Events.flash.connect(_on_flash)
	Events.vision_changed.connect(_on_vision_changed)


func _unhandled_input(event: InputEvent) -> void:
	if ending_panel.visible:
		return
	if event.is_action_pressed(&"cancel"):
		if pause_menu.visible:
			pause_menu.handle_back()
		elif document_panel.visible:
			document_panel.close()
		elif map_panel.visible:
			map_panel.close()
		elif inventory_panel.visible:
			inventory_panel.close()
		elif encounter_panel.visible or _camera_active():
			return  # laissé au panneau de confrontation / au système de caméras
		else:
			pause_menu.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"inventory"):
		if inventory_panel.visible:
			inventory_panel.close()
		elif not _modal_open() and not _camera_active() and not get_tree().paused:
			inventory_panel.open()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"interact") and document_panel.visible:
		document_panel.close()
		get_viewport().set_input_as_handled()


func _modal_open() -> bool:
	return document_panel.visible or map_panel.visible or inventory_panel.visible \
		or encounter_panel.visible or ending_panel.visible or pause_menu.visible \
		or talk_panel.visible


func _camera_active() -> bool:
	var sys := get_tree().get_first_node_in_group(&"camera_system") as CameraSystem
	return sys != null and sys.active


func _on_fade(to_black: bool, duration: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "color:a", 1.0 if to_black else 0.0, duration)


## L'écran de fin a son propre fond noir : on retire le fondu qui le recouvrait.
func _on_ending(ending: int) -> void:
	ending_panel.open(ending)
	_on_fade(false, 0.8)


func _on_flash(color: Color) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_vision_changed(impaired: bool) -> void:
	var mat := _vision_fx.material as ShaderMaterial
	var from: float = mat.get_shader_parameter("amount")
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), from, 1.0 if impaired else 0.0, 1.2)
	if impaired:
		Sfx.loop("heartbeat", -8.0)
	else:
		Sfx.stop_loop("heartbeat")
