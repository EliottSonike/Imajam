extends Node
## Sons : effets 2D (interface, téléphone, coups), boucles d'ambiance et sons 3D.

const DIR := "res://assets/sounds/"
const VOICE_DIR := "res://assets/voix/"

var _cache := {}
var _loops := {}
var _voice: AudioStreamPlayer


func stream(sound: String) -> AudioStream:
	if not _cache.has(sound):
		_cache[sound] = load(DIR + sound + ".wav")
	return _cache[sound]


## Joue un son 2D une fois.
func play(sound: String, volume_db := 0.0, pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream(sound)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p


## Joue un son 3D une fois à une position du monde.
func play_at(sound: String, position: Vector3, volume_db := 0.0, unit_size := 4.0) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(sound)
	p.volume_db = volume_db
	p.unit_size = unit_size
	scene.add_child(p)
	p.global_position = position
	p.finished.connect(p.queue_free)
	p.play()


## Lance une boucle 2D (ambiance, battements de coeur...).
func loop(sound: String, volume_db := 0.0) -> void:
	if _loops.has(sound):
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream(sound)
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.play)
	p.play()
	_loops[sound] = p


func stop_loop(sound: String) -> void:
	if _loops.has(sound):
		(_loops[sound] as Node).queue_free()
		_loops.erase(sound)


func stop_all_loops() -> void:
	for sound in _loops.keys():
		stop_loop(sound)


func player_3d(parent: Node3D, sound: String, unit_size := 3.0, volume_db := 0.0, looping := true) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(sound)
	p.unit_size = unit_size
	p.volume_db = volume_db
	p.max_distance = 45.0
	parent.add_child(p)
	if looping:
		p.finished.connect(p.play)
	return p


## Fichier de voix d'une réplique s'il existe, sinon null.
func voice_stream(speaker: StringName, id: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s/%s.%s" % [VOICE_DIR, speaker, id, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Joue la voix d'une réplique (coupe la précédente).
func play_voice(speaker: StringName, id: String) -> float:
	stop_voice()
	var s := voice_stream(speaker, id)
	if s == null:
		return 0.0
	if _voice == null:
		_voice = AudioStreamPlayer.new()
		_voice.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_voice)
	_voice.stream = s
	_voice.play()
	return s.get_length()


func stop_voice() -> void:
	if _voice:
		_voice.stop()
