class_name Decor
extends Node3D
## Habille le niveau : béton sur les murs, carrelage au réfectoire, écrans et téléphone du bureau.
## Les meubles détaillés sont posés par Mobilier (scripts/world/mobilier.gd).

const MAT_MUR := preload("res://assets/materials/beton_mur.tres")
const MAT_REFECTOIRE := preload("res://assets/materials/carrelage_refectoire.tres")
const MAT_SOL_LINO := preload("res://assets/materials/sol_lino.tres")  # dalles vinyles (tools/generate_sol.py)
const MAT_SOL_BETON := preload("res://assets/materials/sol_beton.tres")
## Sols en béton brut ; les autres pièces ont des dalles vinyles, la douche du carrelage.
const SOLS_BETON: Array[String] = ["Sol_Couloir", "Sol_Generateur", "Sol_Reserve", "Sol_Archives", "Sol_Buanderie"]
const SHADER_ECRAN := preload("res://assets/materials/ecran_cctv.gdshader")
const ECRAN := preload("res://models/ecran.glb")
const TELEPHONE := preload("res://models/telephone.glb")
## Les quatre écrans posés sur le bureau, légèrement tournés vers la chaise.
const ECRANS_X: Array[float] = [-1.475, -0.475, 0.525, 1.525]
const ECRANS_Z := 2.25
const BUREAU_Y := 0.76
const CHAISE := Vector3(-0.05, 0.0, 1.37)
const TELEPHONE_POS := Vector3(1.9, 0.76, 1.93)

## Flux en direct : chaque écran filme une caméra de surveillance via une SubViewport.
const FLUX_RES := Vector2i(384, 234)  # même rapport que la dalle de l'écran
const FLUX_DUREE := Vector2(7.0, 12.0)  # temps passé sur une caméra avant de changer
const FLUX_DISTANCE_MAX := 9.0  # au-delà, le joueur ne voit plus les écrans : on coupe le rendu
const HEURE_DEPART := 2 * 3600 + 47 * 60 + 13  # 02:47:13

@export var prison: Node3D

var _ecrans: Array[ShaderMaterial] = []
var _sols := {}
var _flux: Array[Dictionary] = []
var _cams: Array[SecurityCamera] = []
var _temps := 0.0
var _mode_cameras := false


func _ready() -> void:
	if prison == null:
		prison = get_parent().get_node_or_null("Prison") as Node3D
	if prison:
		_habiller(prison)
		var mobilier := Mobilier.new()
		mobilier.name = "Mobilier"
		mobilier.prison = prison
		add_child(mobilier)
		var traces := TracesEau.new()
		traces.name = "TracesEau"
		add_child(traces)
	_poser_bureau()
	Events.power_changed.connect(_on_power_changed)
	Events.camera_mode_changed.connect(_on_camera_mode_changed)
	_brancher_flux.call_deferred()


func _habiller(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.name.begins_with("Ecrans_Bureau"):
			mi.visible = false  # remplacés par les vrais écrans (la collision reste)
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat == null:
				continue
			match mat.resource_name:
				"Mur":
					mi.set_surface_override_material(i, MAT_MUR)
				"Sol_Refectoire":
					mi.set_surface_override_material(i, MAT_REFECTOIRE)
				var n when n.begins_with("Sol_"):
					mi.set_surface_override_material(i, _sol(mat))


## Matériau texturé d'un sol, teinté avec la couleur d'origine de la pièce (un peu adoucie).
func _sol(original: Material) -> Material:
	var nom := original.resource_name
	if not _sols.has(nom):
		var base: StandardMaterial3D = MAT_SOL_BETON if nom in SOLS_BETON else MAT_SOL_LINO
		if nom == "Sol_Douches":
			base = MAT_REFECTOIRE
		var m := base.duplicate() as StandardMaterial3D
		var c := Color(0.75, 0.75, 0.75)
		if original is BaseMaterial3D:
			c = (original as BaseMaterial3D).albedo_color
		var gris := (c.r + c.g + c.b) / 3.0
		c = c.lerp(Color(gris, gris, gris), 0.35 if base == MAT_SOL_LINO else 0.7)
		m.albedo_color = c * (1.15 if base == MAT_SOL_LINO else 1.0)
		_sols[nom] = m
	return _sols[nom]


func _poser_bureau() -> void:
	for i in ECRANS_X.size():
		var ecran := ECRAN.instantiate() as Node3D
		ecran.name = "Ecran%d" % (i + 1)
		ecran.position = Vector3(ECRANS_X[i], BUREAU_Y, ECRANS_Z)
		ecran.rotation.y = _vers_chaise(ecran.position) * 0.4
		add_child(ecran)
		var dalle := ecran.find_child("Affichage", true, false) as MeshInstance3D
		if dalle:
			var mat := ShaderMaterial.new()
			mat.shader = SHADER_ECRAN
			mat.set_shader_parameter(&"graine", float(i) * 1.37)
			mat.set_shader_parameter(&"allume", 1.0 if GameState.power_on else 0.0)
			dalle.material_override = mat
			_ecrans.append(mat)

	var tel := TELEPHONE.instantiate() as Node3D
	tel.name = "Telephone"
	tel.position = TELEPHONE_POS
	tel.rotation.y = _vers_chaise(TELEPHONE_POS) * 0.7
	add_child(tel)


func _vers_chaise(from: Vector3) -> float:
	var d := CHAISE - from
	return atan2(-d.x, -d.z)


func _on_power_changed(on: bool) -> void:
	for mat in _ecrans:
		mat.set_shader_parameter(&"allume", 1.0 if on else 0.0)
	_maj_rendu()


func _on_camera_mode_changed(active: bool) -> void:
	_mode_cameras = active
	_maj_rendu()


# --- Flux en direct ---------------------------------------------------------

func _brancher_flux() -> void:
	for n in get_tree().get_nodes_in_group(&"security_cameras"):
		_cams.append(n as SecurityCamera)
	if _cams.is_empty():
		return  # pas de caméras (menu) : les écrans gardent leur neige
	for i in _ecrans.size():
		var vp := SubViewport.new()
		vp.name = "Flux%d" % (i + 1)
		vp.size = FLUX_RES
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(vp)
		var cam := Camera3D.new()
		cam.current = true
		vp.add_child(cam)

		var nom := _texte(14, Color(0.9, 0.95, 0.9))
		nom.position = Vector2(12, 8)
		vp.add_child(nom)
		var heure := _texte(12, Color(0.75, 0.8, 0.75))
		heure.position = Vector2(12, FLUX_RES.y - 24)
		vp.add_child(heure)

		var mat := _ecrans[i]
		mat.set_shader_parameter(&"flux", vp.get_texture())
		mat.set_shader_parameter(&"a_flux", 1.0)
		var flux := {"vp": vp, "cam": cam, "nom": nom, "heure": heure, "mat": mat,
			"source": null, "reste": randf_range(FLUX_DUREE.x, FLUX_DUREE.y) + i * 1.5,
			"parasites": 0.0}
		_flux.append(flux)
		_regler(flux, _cams[(_ecrans.size() - 1 - i) % _cams.size()])  # de gauche à droite : CAM 01, 02, 03…
	_maj_rendu()


func _texte(taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", UiTheme.font())
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


func _regler(flux: Dictionary, source: SecurityCamera) -> void:
	flux.source = source
	var cam := flux.cam as Camera3D
	cam.global_transform = source.global_transform
	cam.fov = source.fov
	cam.near = source.near
	cam.far = source.far
	cam.cull_mask = source.cull_mask
	cam.environment = source.environment
	(flux.nom as Label).text = "CAM %02d · %s" % [_numero(source), source.label.to_upper()]


func _numero(source: SecurityCamera) -> int:
	var morceaux := String(source.name).split("_")
	if morceaux.size() > 1 and morceaux[1].is_valid_int():
		return morceaux[1].to_int()
	return _cams.find(source) + 1


## Caméra suivante qui n'est pas déjà sur un autre écran.
func _suivante(flux: Dictionary) -> SecurityCamera:
	var prises: Array = []
	for f in _flux:
		prises.append(f.source)
	var i := _cams.find(flux.source)
	for k in _cams.size():
		var c := _cams[(i + 1 + k) % _cams.size()]
		if not prises.has(c):
			return c
	return flux.source


func _rendu_utile() -> bool:
	if not GameState.power_on or _mode_cameras:
		return false
	var joueur := get_tree().get_first_node_in_group(&"player") as Node3D
	if joueur == null:
		return true
	return joueur.global_position.distance_to(to_global(Vector3(0.0, BUREAU_Y, ECRANS_Z))) < FLUX_DISTANCE_MAX


func _maj_rendu() -> void:
	var mode := SubViewport.UPDATE_ALWAYS if _rendu_utile() else SubViewport.UPDATE_DISABLED
	for f in _flux:
		(f.vp as SubViewport).render_target_update_mode = mode


func _process(delta: float) -> void:
	if _flux.is_empty():
		return
	_temps += delta
	if Engine.get_process_frames() % 15 == 0:
		_maj_rendu()
	var s := HEURE_DEPART + int(_temps)
	var heure := "%02d:%02d:%02d" % [s / 3600 % 24, s / 60 % 60, s % 60]
	for f in _flux:
		(f.heure as Label).text = heure
		var source := f.source as SecurityCamera
		if is_instance_valid(source):
			(f.cam as Camera3D).global_transform = source.global_transform
		f.reste -= delta
		if f.reste <= 0.0:
			f.reste = randf_range(FLUX_DUREE.x, FLUX_DUREE.y)
			f.parasites = 1.0
			_regler(f, _suivante(f))
		if f.parasites > 0.0:
			f.parasites = maxf(f.parasites - delta * 2.5, 0.0)
			(f.mat as ShaderMaterial).set_shader_parameter(&"parasites", f.parasites)
