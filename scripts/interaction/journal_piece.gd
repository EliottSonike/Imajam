class_name JournalPiece
extends Interactable
## Bout de journal (3 = le bout caché qui révèle le twist).

@export_range(0, 3) var index := 0


func _ready() -> void:
	if prompt == "":
		prompt = "Lire le bout de papier"
	_setup_box(Vector3(0.36, 0.1, 0.4), Vector3(0.0, 0.04, 0.0))
	var sheet := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(0.21, 0.27)
	sheet.mesh = mesh
	sheet.position.y = 0.004
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.86, 0.72)
	mat.roughness = 1.0
	sheet.material_override = mat
	add_child(sheet)
	# quelques lignes d'écriture
	for i in 5:
		var line := MeshInstance3D.new()
		var lm := PlaneMesh.new()
		lm.size = Vector2(0.15 if i < 4 else 0.08, 0.006)
		line.mesh = lm
		line.position = Vector3(-0.01 if i < 4 else -0.045, 0.005, -0.08 + i * 0.035)
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(0.2, 0.18, 0.25)
		line.material_override = lmat
		add_child(line)


func can_interact(_player: Player) -> bool:
	return enabled


func interact(_player: Player) -> void:
	GameState.pick_journal(index)
	var page: Dictionary = Texts.JOURNALS[index]
	Sfx.play("pickup")
	Events.show_document.emit(page["title"], page["body"])
	queue_free()
