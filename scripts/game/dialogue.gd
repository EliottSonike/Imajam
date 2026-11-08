class_name Dialogue
extends RefCounted
## Répliques du jeu : sous-titre + voix enregistrée si le fichier existe (doublage).
##
##   await Dialogue.say(&"turn_2_sortie")   # joue la suite Texts.LINES[&"turn_2_sortie"]
##   Dialogue.line(&"detenu_2", "texte", "negociation_1")   # une seule réplique, renvoie sa durée
##
## Fichier de voix : assets/voix/<personnage>/<id>.ogg (.wav / .mp3 aussi).
## Pour une suite de Texts.LINES, l'id est <clé>_<n> (n = 1, 2…). Liste complète : A_ENREGISTRER.md.
## Une nouvelle suite coupe celle en cours.

static var _sequence := 0


## Nom du fichier de voix de la n-ième réplique d'une clé (n commence à 0).
static func voice_id(key: StringName, index: int) -> String:
	return "%s_%d" % [key, index + 1]


## Joue toute la suite de répliques d'une clé, l'une après l'autre.
static func say(key: StringName) -> void:
	var lines: Array = Texts.LINES.get(key, [])
	_sequence += 1
	var mine := _sequence
	var tree := Engine.get_main_loop() as SceneTree
	for i in lines.size():
		if mine != _sequence:
			return
		var entry: Array = lines[i]
		var duration := line(entry[0], entry[1], voice_id(key, i))
		await tree.create_timer(duration).timeout


## Affiche une réplique et joue sa voix. Renvoie le temps d'affichage (durée de la voix si elle existe).
static func line(speaker: StringName, text: String, id: String) -> float:
	var audio := Sfx.play_voice(speaker, id)
	var duration := audio + 0.35 if audio > 0.0 else clampf(1.6 + text.length() * 0.05, 2.4, 7.0)
	Events.say.emit(speaker, text, duration)
	return duration


## Coupe la suite et la voix en cours.
static func stop() -> void:
	_sequence += 1
	Sfx.stop_voice()
