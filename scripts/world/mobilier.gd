class_name Mobilier
extends Node3D
## Remplace les meubles « boîtes » du modèle de la prison par des modèles détaillés (Sketchfab, CC-BY 4.0,
## crédits dans CREDITS.md). Les anciens meubles sont seulement cachés : leurs collisions restent.
##
## Toutes les positions sont dans le repère du modèle de la prison (prison.glb), relevées sur les meubles
## d'origine. Si la map change, il faut les mettre à jour ici.

const LIT := preload("res://models/lit_hopital.glb")
const TABLE := preload("res://models/table_prison.glb")
const CASIER := preload("res://models/casier.glb")
const TABOURET := preload("res://models/tabouret.glb")
const CHAISE := preload("res://models/chaise_bureau.glb")
const CARTON := preload("res://models/carton.glb")
const TOILETTES := preload("res://models/toilettes.glb")
const LAVABO := preload("res://models/lavabo.glb")
const TABLEAU := preload("res://models/tableau_electrique.glb")
const GROUPE := preload("res://models/groupe_electrogene.glb")
const ETAGERE := preload("res://models/etagere.glb")
const CAMERA := preload("res://models/camera_surveillance.glb")
const ELECTROMENAGER := preload("res://models/electromenager.glb")  # frigo, gazinière, machine à laver
const TABLE_BOIS := preload("res://models/table_ancienne.glb")
const JERRICAN := preload("res://models/jerrican.glb")
const CUISINE := preload("res://models/cuisine_meubles.glb")  # meubles en L, nord + est, comme la cuisine
const POMMEAU := preload("res://models/pommeau_douche.glb")
const CHARIOT := preload("res://models/chariot_menage.glb")  # « Cleaning Cart », Kerridge1, CC-BY-NC 4.0
const CHARIOT_SOINS := preload("res://models/chariot_infirmerie.glb")
const CHARIOT_LINGE := preload("res://models/chariot_linge.glb")
const BUREAU := preload("res://models/bureau.glb")
const TABLE_INOX := preload("res://models/table_inox.glb")
const PANNEAU_MOUILLE := preload("res://models/panneau_sol_mouille.glb")

const CACHES: Array[String] = ["Lit_Cellule", "Matelas_Cellule", "Lits_Infirmerie", "Matelas_Infirmerie",
	"Tables_Refectoire", "Bancs_Refectoire", "Casiers_Vestiaire", "Armoire_Bureau", "Armoire_Medicaments_Infirmerie",
	"Tabouret_Cellule", "Tabourets_Parloir", "Chaise_Bureau", "Cartons_Archives", "Caisses_Reserve",
	"Toilettes_Cellule", "Lavabo_Cellule", "Tableau_Electrique_Generateur", "Groupe_Electrogene_Generateur",
	"Etageres_Archives", "Etageres_Reserve", "Frigo_Cuisine", "Machines_a_Laver_Buanderie",
	"Table_Cellule", "Table_Archives", "Table_Pliage_Buanderie",
	"Bidons_Generateur", "Plan_de_Travail_Cuisine", "Fourneau_Cuisine", "Pommeaux_Douches",
	"Chariot_Infirmerie", "Chariot_Linge_Buanderie", "Poste_Securite_Bureau", "Ilot_Cuisine"]

# Réglage d'un modèle (« fit ») :
#   len / height / width : taille voulue en X (longueur) / Y / Z, à l'échelle uniforme sauf si plusieurs sont donnés
#   foot : Vector2(x, z) — (repère du modèle) plus grande taille qui tient dans cette empreinte (échelle uniforme)
#   box  : Vector3 — étire exactement à cette taille
#   pre  : rotation (degrés) appliquée au modèle avant tout, pour le remettre debout / face à +Z
#   y    : hauteur du bas du modèle (0 = posé au sol)

## [centre, rotation Y] — lits : tête du côté de l'oreiller d'origine (le modèle a la tête en -X).
const LITS := [
	[Vector3(9.24, 0, 2.51), -90.0], [Vector3(47.89, 0, 24.64), 180.0], [Vector3(20.44, 0, 15.11), -90.0],
	[Vector3(31.62, 0, 14.0), -90.0], [Vector3(31.62, 0, 16.7), -90.0],
]
const TABLES := [
	[Vector3(20.75, 0, 3.5), 0.0], [Vector3(20.75, 0, 6.3), 0.0],
	[Vector3(25.45, 0, 3.5), 0.0], [Vector3(25.45, 0, 6.3), 0.0],
]
## Rangées de casiers : [centre, rotation (portes vers la pièce), longueur du mur à couvrir].
const CASIERS := [
	[Vector3(10.15, 0, 26.59), 90.0, 1.78],  # vestiaire, mur ouest
	[Vector3(11.89, 0, 29.04), 180.0, 3.58],  # vestiaire, mur sud
	[Vector3(1.8, 0, 26.2), 90.0, 1.2],  # bureau
	[Vector3(27.6, 0, 12.93), 0.0, 1.2],  # infirmerie
]
const TABOURETS := [
	Vector3(6.54, 0, 3.48), Vector3(46.92, 0, 21.94), Vector3(17.73, 0, 16.08),  # cellules
	Vector3(20.55, 0, 29.32), Vector3(20.55, 0, 30.87), Vector3(22.25, 0, 29.32), Vector3(22.25, 0, 30.87),  # parloir
	Vector3(23.95, 0, 29.32), Vector3(23.95, 0, 30.87), Vector3(25.65, 0, 29.32), Vector3(25.65, 0, 30.87),
]
## [centre, rotation, taille de la boîte d'origine]
const CARTONS := [
	[Vector3(8.05, 0, 21.52), 8.0, Vector3(0.5, 0.4, 0.45)],
	[Vector3(8.2, 0, 15.0), -5.0, Vector3(0.6, 1.0, 0.6)],  # deux cartons empilés
	[Vector3(10.05, 0, 13.95), 14.0, Vector3(0.5, 0.5, 0.5)],
]
## [centre, rotation] — toilettes : le modèle est couché, « pre » le relève (−90° en X), il regarde alors vers +X.
const TOILETTES_POS := [[Vector3(6.06, 0, 1.84), -90.0], [Vector3(48.57, 0, 21.46), 180.0], [Vector3(17.26, 0, 14.43), -90.0]]
const LAVABOS := [[Vector3(6.76, 0, 1.72), 0.0], [Vector3(48.68, 0, 22.16), -90.0], [Vector3(17.96, 0, 14.32), 0.0]]
## Étagères : [centre, rotation (face ouverte vers la pièce), longueur du mur]
const ETAGERES := [
	[Vector3(7.35, 0, 14.85), 90.0, 3.3], [Vector3(10.84, 0, 14.85), -90.0, 3.3], [Vector3(9.1, 0, 16.44), 180.0, 2.6],  # réserve
	[Vector3(9.39, 0, 18.55), 0.0, 3.39], [Vector3(9.39, 0, 22.05), 180.0, 3.39], [Vector3(10.85, 0, 20.3), -90.0, 3.0],  # archives (porte à l'ouest)
]
## Petites tables en bois : [centre, rotation, longueur, largeur, hauteur] (hauteur d'origine : les journaux sont posés dessus).
const TABLES_BOIS := [
	[Vector3(5.96, 0, 3.51), 90.0, 1.0, 0.5, 0.77],  # cellule 1
	[Vector3(46.9, 0, 21.36), 0.0, 1.0, 0.5, 0.77],  # cellule 2
	[Vector3(17.16, 0, 16.1), 90.0, 1.0, 0.5, 0.77],  # cellule 3
	[Vector3(9.1, 0, 20.3), 0.0, 1.2, 0.8, 0.75],  # archives
	[Vector3(38.0, 0, 11.65), 0.0, 2.2, 0.69, 0.85],  # buanderie (table de pliage)
]
const CHARIOT_ROT := 0.0
const CASIER_HAUTEUR := 1.9
const CASIER_COUPE := 57.0  # casier.glb : bloc de trois à gauche de cette abscisse, casier seul à droite
const ETAGERE_LARGEUR := 2.18
const CAMERA_LONGUEUR := 0.38

@export var prison: Node3D


func _ready() -> void:
	if prison == null:
		return
	for node in prison.find_children("*", "MeshInstance3D", true, false):
		if CACHES.any(func(n: String) -> bool: return node.name.begins_with(n)):
			(node as MeshInstance3D).visible = false

	for l in LITS:
		_poser(LIT.instantiate(), l[0], l[1], {"len": 2.0, "width": 1.0, "height_follow": true})
	for t in TABLES:
		_poser(TABLE.instantiate(), t[0], t[1], {"len": 2.9})
	_casiers()
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 7
	for p in TABOURETS:
		_poser(TABOURET.instantiate(), p, rnd.randf_range(-25.0, 25.0), {"height": 0.46})
	_poser(CHAISE.instantiate(), Vector3(4.15, 0, 29.37), -90.0, {"height": 1.05})
	for c in CARTONS:
		var size: Vector3 = c[2]
		if size.y > size.x * 1.4:  # haute pile : deux cartons
			var half := Vector3(size.x, size.y / 2.0, size.z)
			_poser(CARTON.instantiate(), c[0], c[1], {"box": half})
			_poser(CARTON.instantiate(), c[0], c[1] + 9.0, {"box": half * Vector3(0.9, 1.0, 0.9), "y": half.y})
		else:
			_poser(CARTON.instantiate(), c[0], c[1], {"box": size})
	for t in TOILETTES_POS:
		_poser(TOILETTES.instantiate(), t[0], t[1], {"pre": Vector3(-90, 0, 0), "height": 0.78})
	for l in LAVABOS:
		_poser(LAVABO.instantiate(), l[0], l[1], {"height": 0.9})
	_poser(TABLEAU.instantiate(), Vector3(48.75, 0, 3.2), -90.0, {"len": 0.6, "y": 0.92})  # 60 cm de large, centré à 1,4 m
	_poser(GROUPE.instantiate(), Vector3(46.2, 0, 1.4), -90.0, {"foot": Vector2(1.6, 3.4)})  # empreinte dans le repère du modèle (long en Z)
	for e in ETAGERES:
		var n := maxi(1, roundi(float(e[2]) / ETAGERE_LARGEUR))
		var w: float = float(e[2]) / n
		var rangee := Node3D.new()
		for i in n:
			var shelf := _caler(ETAGERE.instantiate(), {"pre": Vector3(0, 180, 0), "len": w, "height": 2.0, "width": 0.49})
			shelf.position.x = -float(e[2]) / 2.0 + w * (i + 0.5)
			rangee.add_child(shelf)
		_placer(rangee, e[0], e[1])
	for t in TABLES_BOIS:
		_poser(TABLE_BOIS.instantiate(), t[0], t[1], {"len": t[2], "width": t[3], "height": t[4]})
	_poser(JERRICAN.instantiate(), Vector3(43.85, 0, 5.05), 12.0, {"height": 0.47})
	_poser(JERRICAN.instantiate(), Vector3(44.45, 0, 5.1), -20.0, {"height": 0.47})
	# meubles de cuisine : étirés sur l'emprise des plans de travail d'origine (5,38 × 4,54 m)
	_poser(CUISINE.instantiate(), Vector3(32.2, 0, 3.78), 0.0, {"len": 5.38, "width": 4.54, "height": 2.46})
	for z in [21.75, 23.1, 24.45]:  # pommeaux de douche, bras vers +X (mur ouest)
		_poser(POMMEAU.instantiate(), Vector3(18.44, 0, z), 90.0, {"height": 0.16, "y": 1.94})
	# chariot de ménage abandonné au bout du couloir sud-est (la dernière page du carnet y est cachée,
	# des traces d'eau y mènent depuis la buanderie : voir TracesEau)
	_poser(CHARIOT.instantiate(), Vector3(48.2, 0, 30.1), CHARIOT_ROT, {"height": 1.25})
	# buanderie : cartons de linge et tabouret
	_poser(CARTON.instantiate(), Vector3(40.2, 0, 14.95), 6.0, {"box": Vector3(0.55, 0.42, 0.45)})
	_poser(CARTON.instantiate(), Vector3(40.2, 0, 14.95), -4.0, {"box": Vector3(0.5, 0.38, 0.42), "y": 0.42})
	_poser(CARTON.instantiate(), Vector3(39.55, 0, 15.0), 20.0, {"box": Vector3(0.45, 0.35, 0.4)})
	_poser(TABOURET.instantiate(), Vector3(38.7, 0, 12.7), 17.0, {"height": 0.46})
	# infirmerie : chariot de soins (les médicaments sont posés dessus, à 0,90 m)
	_poser(CHARIOT_SOINS.instantiate(), Vector3(29.0, 0, 13.15), 0.0, {"len": 0.6, "height": 0.95, "width": 0.5})
	# buanderie : bac à linge sale
	_poser(CHARIOT_LINGE.instantiate(), Vector3(37.4, 0, 14.8), 0.0, {"len": 0.9})
	# poste de garde : deux bureaux côte à côte sous les écrans (plateau à 0,76 m comme l'ancien)
	for x in [3.15, 5.25]:
		_poser(BUREAU.instantiate(), Vector3(x, 0, 30.24), 0.0, {"len": 2.1, "height": 0.76, "width": 0.89})
	# cuisine : table de préparation en inox à la place de l'îlot
	_poser(TABLE_INOX.instantiate(), Vector3(32.3, 0, 4.4), 0.0, {"len": 1.6, "height": 0.9, "width": 1.0})
	# panneaux « sol mouillé » : à la sortie de la buanderie, et un renversé près du chariot abandonné
	_poser(PANNEAU_MOUILLE.instantiate(), Vector3(36.75, 0, 12.6), -70.0, {"height": 0.62})
	var tombe := _caler(PANNEAU_MOUILLE.instantiate(), {"pre": Vector3(-90, 0, 0), "height": 0.12})
	_placer(tombe, Vector3(46.9, 0, 29.75), 35.0)
	# électroménager années 50 (façade en +Z)
	_poser(_sous_arbre(ELECTROMENAGER, "frigo"), Vector3(34.52, 0, 6.5), -90.0, {"height": 1.9})
	var lave := _sous_arbre(ELECTROMENAGER, "machine_laver")
	for z in [11.84, 12.52, 13.2]:
		_poser(lave.duplicate(), Vector3(40.17, 0, z), -90.0, {"height": 0.85})
	_cameras.call_deferred()


# --- Placement -----------------------------------------------------------------

func _poser(model: Node3D, centre: Vector3, rot_y: float, fit: Dictionary) -> void:
	_placer(_caler(model, fit), centre, rot_y)


func _placer(n: Node3D, centre: Vector3, rot_y: float) -> void:
	var holder := Node3D.new()
	holder.position = centre
	holder.rotation_degrees.y = rot_y
	holder.add_child(n)
	prison.add_child(holder)


## Met un modèle à la taille voulue, centré sur l'origine, le bas à la hauteur « y ».
func _caler(model: Node3D, fit: Dictionary) -> Node3D:
	var wrap := Node3D.new()
	var scaler := Node3D.new()
	var orient := Node3D.new()
	orient.rotation_degrees = fit.get("pre", Vector3.ZERO)
	orient.add_child(model)
	scaler.add_child(orient)
	wrap.add_child(scaler)
	var a := _boite(scaler)
	var s := Vector3.ONE
	if fit.has("box"):
		s = (fit["box"] as Vector3) / a.size
	elif fit.has("foot"):
		var f: Vector2 = fit["foot"]
		var k := minf(f.x / a.size.x, f.y / a.size.z)
		s = Vector3(k, k, k)
	else:
		var k := 1.0
		if fit.has("len"):
			k = float(fit["len"]) / a.size.x
		elif fit.has("height"):
			k = float(fit["height"]) / a.size.y
		s = Vector3(k, k, k)
		if fit.has("len") and fit.has("height") and not fit.get("height_follow", false):
			s.y = float(fit["height"]) / a.size.y
		if fit.has("width"):
			s.z = float(fit["width"]) / a.size.z
	scaler.scale = s
	var c := a.get_center()
	scaler.position = Vector3(-c.x * s.x, -a.position.y * s.y + float(fit.get("y", 0.0)), -c.z * s.z)
	return wrap


## Boîte englobante des maillages d'un nœud, dans le repère de ce nœud.
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


## Copie d'une partie nommée d'un modèle (avec sa position dans le modèle).
func _sous_arbre(scene: PackedScene, nom: String) -> Node3D:
	var src := scene.instantiate() as Node3D
	var part := src.find_child(nom, true, false) as Node3D
	var out := Node3D.new()
	if part:
		var t := Transform3D.IDENTITY
		var p: Node = part
		while p != src and p != null:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var copy := part.duplicate() as Node3D
		copy.transform = t
		out.add_child(copy)
	src.free()
	return out


# --- Casiers -------------------------------------------------------------------

## Remplit chaque mur avec des blocs de trois, complétés par des casiers seuls.
func _casiers() -> void:
	var trois := _morceau(CASIER, func(c: Vector3) -> bool: return c.x < CASIER_COUPE)
	var seul := _morceau(CASIER, func(c: Vector3) -> bool: return c.x >= CASIER_COUPE)
	var w3 := _boite(_caler(trois.duplicate(), {"height": CASIER_HAUTEUR})).size.x
	var w1 := _boite(_caler(seul.duplicate(), {"height": CASIER_HAUTEUR})).size.x
	for r in CASIERS:
		var longueur: float = r[2]
		var blocs: Array[Node3D] = []
		var reste := longueur
		while reste >= w3 - 0.02:
			blocs.append(trois)
			reste -= w3
		while reste >= w1 - 0.02:
			blocs.append(seul)
			reste -= w1
		if blocs.is_empty():
			blocs.append(seul)
		var total := 0.0
		var pieces: Array[Node3D] = []
		for b in blocs:
			var piece := _caler(b.duplicate(), {"height": CASIER_HAUTEUR})
			pieces.append(piece)
			total += _boite(piece).size.x
		var rangee := Node3D.new()
		var x := -total / 2.0
		for piece in pieces:
			var w := _boite(piece).size.x
			piece.position.x = x + w / 2.0
			x += w
			rangee.add_child(piece)
		_placer(rangee, r[0], r[1])


## Extrait d'un modèle les triangles dont le centre (repère du modèle) vérifie « garde ».
func _morceau(scene: PackedScene, garde: Callable) -> Node3D:
	var src := scene.instantiate() as Node3D
	var out := Node3D.new()
	for m in src.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != src and p != null:
			t = (p as Node3D).transform * t
			p = p.get_parent()
		var mesh := ArrayMesh.new()
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				idx = PackedInt32Array(range(v.size()))
			var remap := {}
			var used := PackedInt32Array()
			var new_idx := PackedInt32Array()
			for i in range(0, idx.size(), 3):
				var c := t * ((v[idx[i]] + v[idx[i + 1]] + v[idx[i + 2]]) / 3.0)
				if not garde.call(c):
					continue
				for k in 3:
					var o := idx[i + k]
					if not remap.has(o):
						remap[o] = used.size()
						used.append(o)
					new_idx.append(remap[o])
			if new_idx.is_empty():
				continue
			# on ne garde que les sommets utilisés (sinon la boîte englobante reste celle du modèle entier)
			var compact := []
			compact.resize(Mesh.ARRAY_MAX)
			for k in Mesh.ARRAY_MAX:
				var a = arr[k]
				if a == null or k == Mesh.ARRAY_INDEX or a.size() == 0:
					continue
				var per: int = a.size() / v.size()
				var b = a.duplicate()
				b.resize(used.size() * per)
				for j in used.size():
					for q in per:
						b[j * per + q] = a[used[j] * per + q]
				compact[k] = b
			compact[Mesh.ARRAY_INDEX] = new_idx
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, compact)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mi.mesh.surface_get_material(si))
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.transform = t
		out.add_child(piece)
	src.free()
	return out


# --- Caméras -------------------------------------------------------------------

## Pose un modèle de caméra à la place de chaque boîte « Modele_CAM_n », objectif dans l'axe de la caméra n.
func _cameras() -> void:
	var cams := get_tree().get_nodes_in_group(&"security_cameras")
	if cams.is_empty():
		return  # pas de caméras (menu) : on garde les boîtes d'origine
	var modele := _morceau(CAMERA, func(c: Vector3) -> bool: return c.x > 0.0)  # le modèle contient deux caméras
	var boxes := {}
	for node in prison.find_children("Modele_CAM_*", "MeshInstance3D", true, false):
		var parts := String(node.name).split("_")
		if parts.size() > 2 and parts[2].is_valid_int():
			boxes[parts[2].to_int()] = node
	var inv := prison.global_transform.affine_inverse()
	for c in cams:
		var cam := c as SecurityCamera
		var parts := String(cam.name).split("_")
		if parts.size() < 2 or not parts[1].is_valid_int():
			continue
		var fwd := (inv.basis * -cam.global_basis.z).normalized()
		var centre: Vector3
		if boxes.has(parts[1].to_int()):
			var box := boxes[parts[1].to_int()] as MeshInstance3D
			box.visible = false
			centre = inv * (box.global_transform * box.get_aabb().get_center())
		else:
			# caméra ajoutée après le modèle de la prison (cuisines) : boîtier juste derrière l'objectif
			centre = inv * cam.global_position - fwd * 0.32
		var holder := Node3D.new()
		holder.position = centre
		holder.rotation = Vector3(0.0, atan2(-fwd.z, fwd.x), asin(clampf(fwd.y, -1.0, 1.0)))
		holder.add_child(_caler(modele.duplicate(), {"len": CAMERA_LONGUEUR, "y": -0.12}))
		prison.add_child(holder)
