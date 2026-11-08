class_name Decor
extends Node3D
## Habille le niveau : béton sur les murs, carrelage au réfectoire, écrans et téléphone du bureau.

const MAT_MUR := preload("res://assets/materials/beton_mur.tres")
const MAT_REFECTOIRE := preload("res://assets/materials/carrelage_refectoire.tres")
const SHADER_ECRAN := preload("res://assets/materials/ecran_cctv.gdshader")
const ECRAN := preload("res://models/ecran.glb")
const TELEPHONE := preload("res://models/telephone.glb")
const LIT := preload("res://models/lit_hopital.glb")  # « Hospital Bed », loxfear, CC-BY 4.0
const TABLE := preload("res://models/table_prison.glb")  # « Prison Table », chuZz, CC-BY 4.0
const CASIER := preload("res://models/casier.glb")  # « Locker », neverfollow81, CC-BY 4.0

## Meubles d'origine du modèle de la prison, remplacés par les modèles ci-dessus
## (on ne cache que l'image : les collisions restent).
const REMPLACES: Array[String] = ["Lit_Cellule", "Matelas_Cellule", "Lits_Infirmerie", "Matelas_Infirmerie",
	"Tables_Refectoire", "Bancs_Refectoire", "Casiers_Vestiaire", "Armoire_Bureau", "Armoire_Medicaments_Infirmerie"]

## Emplacements des meubles, dans le repère du modèle de la prison : [centre au sol, rotation Y en degrés].
## Lits : tête du côté de l'oreiller d'origine.
const LITS := [
	[Vector3(9.24, 0, 2.51), -90.0],  # cellule 1
	[Vector3(47.89, 0, 24.64), 180.0],  # cellule 2
	[Vector3(20.44, 0, 15.11), -90.0],  # cellule 3
	[Vector3(31.62, 0, 14.0), -90.0],  # infirmerie
	[Vector3(31.62, 0, 16.7), -90.0],
]
const TABLES := [
	[Vector3(20.75, 0, 3.5), 0.0], [Vector3(20.75, 0, 6.3), 0.0],
	[Vector3(25.45, 0, 3.5), 0.0], [Vector3(25.45, 0, 6.3), 0.0],
]
## Rangées de casiers : [centre, rotation (porte vers la pièce), blocs] ; "3" = bloc de trois, "1" = casier seul.
const CASIERS := [
	[Vector3(10.16, 0, 26.59), 90.0, ["3", "1"]],  # vestiaire, mur ouest
	[Vector3(11.89, 0, 29.05), 180.0, ["3", "3", "3"]],  # vestiaire, mur sud
	[Vector3(1.81, 0, 26.2), 90.0, ["3"]],  # bureau
	[Vector3(27.6, 0, 12.93), 0.0, ["3"]],  # infirmerie
]
const LIT_TAILLE := Vector2(2.0, 1.0)  # longueur, largeur
const TABLE_LONGUEUR := 2.9
const CASIER_HAUTEUR := 1.9
const CASIER_COUPE := 57.0  # dans casier.glb, le bloc de trois est à gauche de cette abscisse, le casier seul à droite

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
var _flux: Array[Dictionary] = []
var _cams: Array[SecurityCamera] = []
var _temps := 0.0
var _mode_cameras := false


func _ready() -> void:
	if prison == null:
		prison = get_parent().get_node_or_null("Prison") as Node3D
	if prison:
		_habiller(prison)
		_meubler(prison)
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
		if REMPLACES.any(func(n: String) -> bool: return mi.name.begins_with(n)):
			mi.visible = false
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


# --- Mobilier ----------------------------------------------------------------

func _meubler(root: Node3D) -> void:
	for l in LITS:
		var lit := _caler(LIT.instantiate(), Vector3(LIT_TAILLE.x, 0.0, LIT_TAILLE.y), true)
		_poser(root, lit, l[0], l[1])
	for t in TABLES:
		_poser(root, _caler(TABLE.instantiate(), Vector3(TABLE_LONGUEUR, 0.0, 0.0)), t[0], t[1])
	var blocs := _blocs_casiers()
	for r in CASIERS:
		var rangee := Node3D.new()
		var largeurs: Array[float] = []
		var pieces: Array[Node3D] = []
		for b in r[2]:
			var piece := _caler((blocs[b] as Node3D).duplicate(), Vector3(0.0, CASIER_HAUTEUR, 0.0))
			pieces.append(piece)
			largeurs.append(_boite(piece).size.x)
		var total := 0.0
		for w in largeurs:
			total += w
		var x := -total / 2.0
		for i in pieces.size():
			pieces[i].position.x = x + largeurs[i] / 2.0
			x += largeurs[i]
			rangee.add_child(pieces[i])
		_poser(root, rangee, r[0], r[1])


func _poser(root: Node3D, n: Node3D, centre: Vector3, rot_y: float) -> void:
	var holder := Node3D.new()
	holder.position = centre
	holder.rotation_degrees.y = rot_y
	holder.add_child(n)
	root.add_child(holder)


## Met un modèle à la bonne taille (axe X = longueur), centré, posé au sol.
## Une taille à 0 suit les autres (échelle uniforme) ; « libre » laisse la largeur (Z) suivre sa propre cible.
func _caler(model: Node3D, cible: Vector3, libre := false) -> Node3D:
	var wrap := Node3D.new()
	wrap.add_child(model)
	var a := _boite(model)
	var k := 1.0
	if cible.x > 0.0:
		k = cible.x / a.size.x
	elif cible.y > 0.0:
		k = cible.y / a.size.y
	var s := Vector3(k, k, k)
	if libre and cible.z > 0.0:
		s.z = cible.z / a.size.z
	model.scale = s
	model.position = -Vector3(a.get_center().x * s.x, a.position.y * s.y, a.get_center().z * s.z)
	return wrap


## Boîte englobante d'un modèle, dans son propre repère.
func _boite(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != n and p != null:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var b := t * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## casier.glb contient un bloc de trois casiers et un casier seul dans le même maillage : on les sépare.
func _blocs_casiers() -> Dictionary:
	var src := CASIER.instantiate() as Node3D
	var mi := src.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var t := Transform3D.IDENTITY
	var p: Node = mi
	while p != src and p != null:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	var out := {}
	for cle in ["3", "1"]:
		var mesh := ArrayMesh.new()
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var garde := PackedInt32Array()
			for i in range(0, idx.size(), 3):
				var c := t * ((v[idx[i]] + v[idx[i + 1]] + v[idx[i + 2]]) / 3.0)
				if (c.x < CASIER_COUPE) == (cle == "3"):
					garde.append_array([idx[i], idx[i + 1], idx[i + 2]])
			arr[Mesh.ARRAY_INDEX] = garde
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			mesh.surface_set_material(si, mi.mesh.surface_get_material(si))
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.transform = t
		var n := Node3D.new()
		n.add_child(piece)
		out[cle] = n
	src.free()
	return out


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
