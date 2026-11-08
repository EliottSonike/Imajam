class_name TracesEau
extends Node3D
## Traces d'eau de la buanderie jusqu'au chariot de ménage abandonné au bout du couloir sud-est,
## où est cachée la dernière page du carnet : empreintes mouillées, traces de roues, gouttes, flaques.
## Les textures viennent de tools/generate_traces.py.

const DIR := "res://assets/textures/traces/"
## Départ (devant les machines de la buanderie) et arrivée (devant le chariot), en cases de PrisonNav.
const DEPART := Vector2i(27, 9)
const ARRIVEE := Vector2i(33, 21)
const PAS := 0.62  # longueur d'une foulée
const ECART := 0.11  # écart pied gauche / pied droit
const ROUES := 0.27  # demi-écartement des roues du chariot

var _rng := RandomNumberGenerator.new()
var _tex := {}


func _ready() -> void:
	_rng.seed = 41
	var path := PrisonNav.find_path(PrisonNav.tile_to_world(DEPART), PrisonNav.tile_to_world(ARRIVEE))
	if path.size() < 2:
		return
	path = _lisser(path)
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])

	# flaques : sous les machines, et là où le chariot s'est arrêté
	_decal("flaque", PrisonNav.tile_to_world(DEPART) + Vector3(0.9, 0, 0.3), 0.0, Vector2(1.5, 1.1), 0.9)
	_decal("flaque", PrisonNav.tile_to_world(DEPART) + Vector3(0.5, 0, -0.9), 1.2, Vector2(0.8, 0.6), 0.8)
	_decal("flaque", path[path.size() - 1] + Vector3(0.55, 0, 0.0), 0.7, Vector2(1.0, 0.8), 0.85)

	var d := 0.3
	var gauche := true
	while d < total - 0.2:
		var p := _point(path, d)
		var dir := _direction(path, d)
		var side := Vector3(-dir.z, 0, dir.x)
		var t := d / total
		# l'eau sèche en chemin : les traces pâlissent un peu vers la fin
		var force := lerpf(0.95, 0.55, t)
		var yaw := atan2(-dir.x, -dir.z) + _rng.randf_range(-0.12, 0.12)
		_decal("trace_pas", p + side * (ECART if gauche else -ECART), yaw, Vector2(0.11, 0.28), force)
		gauche = not gauche
		# traces de roues (un tronçon par foulée) et gouttes du chariot
		for s in [-1.0, 1.0]:
			_decal("trace_roue", p + side * ROUES * s + dir * 0.31, yaw, Vector2(0.035, PAS + 0.04), force * 0.8)
		if _rng.randf() < 0.35:
			var off := side * _rng.randf_range(-0.2, 0.2) + dir * _rng.randf_range(0.0, PAS)
			var size := _rng.randf_range(0.05, 0.11)
			_decal("goutte", p + off, _rng.randf() * TAU, Vector2(size, size), force)
		d += PAS


func _decal(nom: String, pos: Vector3, yaw: float, size: Vector2, force: float) -> void:
	var dec := Decal.new()
	dec.texture_albedo = _texture(nom)
	dec.texture_orm = _texture(nom + "_orm")
	dec.size = Vector3(size.x, 0.4, size.y)
	dec.modulate = Color(1, 1, 1, force)
	dec.albedo_mix = 1.0
	dec.cull_mask = 1  # pas sur les détenus ni sur le joueur
	add_child(dec)
	dec.global_position = Vector3(pos.x, 0.12, pos.z)
	dec.global_rotation = Vector3(0, yaw, 0)


func _texture(nom: String) -> Texture2D:
	if not _tex.has(nom):
		_tex[nom] = load(DIR + nom + ".png")
	return _tex[nom]


## Coupe les virages à angle droit du chemin (centres des cases) pour une trajectoire naturelle.
func _lisser(path: PackedVector3Array) -> PackedVector3Array:
	var out := PackedVector3Array([path[0]])
	for i in range(1, path.size() - 1):
		var a := path[i - 1]
		var b := path[i]
		var c := path[i + 1]
		if (b - a).normalized().dot((c - b).normalized()) < 0.9:
			out.append(b.lerp(a, 0.35))
			out.append(b.lerp(c, 0.35))
		else:
			out.append(b)
	out.append(path[path.size() - 1])
	return out


func _point(path: PackedVector3Array, d: float) -> Vector3:
	for i in path.size() - 1:
		var l := path[i].distance_to(path[i + 1])
		if d <= l:
			return path[i].lerp(path[i + 1], d / l)
		d -= l
	return path[path.size() - 1]


func _direction(path: PackedVector3Array, d: float) -> Vector3:
	for i in path.size() - 1:
		var l := path[i].distance_to(path[i + 1])
		if d <= l:
			return (path[i + 1] - path[i]).normalized()
		d -= l
	return (path[path.size() - 1] - path[path.size() - 2]).normalized()
