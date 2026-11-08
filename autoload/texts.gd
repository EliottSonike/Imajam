extends Node
## Tous les textes du jeu.

const INTRO_TITLE := "LE COURRIER DU SOIR — Édition de nuit"
const INTRO_BODY := """[b]ÉVASION À LA PRISON SAINT-ROCH[/b]

Trois jours après l'évasion d'un détenu de l'aile psychiatrique, la direction assure que la situation est « sous contrôle ». L'établissement, qui enfermait quatre des criminels les plus dangereux du pays, n'en compte désormais plus que trois.

Le fugitif n'a toujours pas été retrouvé. Les enquêteurs n'excluent aucune piste.

Cette nuit, la surveillance est assurée par un seul garde, depuis le poste de contrôle.

[i](Appuie sur E ou clique sur Fermer)[/i]"""

const CONTROLS := "ZQSD / WASD : se déplacer   Maj : courir   E : interagir   Tab : inventaire   R : médicaments   Échap : pause"

const SPEAKER_NAMES: Dictionary = {
	&"telephone": "Téléphone",
	&"joueur": "",
	&"detenu_1": "Détenu 1",
	&"detenu_2": "Détenu 2",
	&"detenu_3": "Détenu 3",
}

const LINES: Dictionary = {
	&"intro": [
		[&"telephone", "Allô ? C'est moi. Tu as pris ton poste, parfait."],
		[&"telephone", "Il ne reste que trois détenus. Ils ne doivent pas quitter leur cellule."],
		[&"telephone", "Installe-toi aux écrans, au fond du bureau. Commence par la cellule 1 : le 1 ne répond plus."],
		[&"telephone", "Je ne pourrai pas te rappeler cette nuit. Tu es seul. Bon courage."],
	],
	&"turn_1": [  # Premier passage aux écrans
		[&"joueur", "Bon. La cellule 1 d'abord… caméra 2."],
	],
	&"turn_1_empty": [  # Il voit la cellule 1 vide à l'écran
		[&"joueur", "Quoi ?! La porte n'a pas bougé… Il est forcément encore là-dedans."],
		[&"joueur", "J'y vais. Il me faut de quoi me défendre."],
	],
	&"detenu_1_attaque": [  # Le détenu 1 sort de l'angle mort
		[&"detenu_1", "COUCOU, j'étais bien caché ?"],
	],
	&"turn_1_done": [  # Après le détenu 1
		[&"joueur", "Un de moins… Retour aux écrans."],
	],
	&"turn_2": [  # Retour aux écrans après le détenu 1
		[&"joueur", "Le bloc B est agité ce soir… Voyons la cellule 2. Caméra 9."],
	],
	&"turn_2_sortie": [  # Il voit le détenu 2 sortir de sa cellule
		[&"joueur", "Le 2 ! Il a forcé sa porte… Il part vers les cuisines…"],
	],
	&"turn_2_refectoire": [  # Il voit le détenu 2 arrêté au réfectoire
		[&"joueur", "Il s'est arrêté au réfectoire… Il tient quelque chose. Un couteau ? Je dois y aller."],
	],
	&"detenu_2_couteau": [  # Le joueur entre dans le réfectoire
		[&"detenu_2", "N'approche pas ! J'ai un couteau… Je n'hésiterai pas à l'utiliser"],
	],
	&"turn_2_calme": [  # Négociation réussie
		[&"joueur", "Il a lâché le couteau… C'est fini. Il faut que je retourne au bureau."],
	],
	&"turn_2_tue": [  # Négociation ratée : le joueur a dû tirer
		[&"joueur", "Je n'avais pas le choix… Je n'avais pas le choix. Il m'a attaqué, il faut que je retourne au bureau."],
	],
	&"turn_3": [  # Retour aux écrans après le détenu 2
		[&"joueur", "Plus que le 3. Cellule 3… caméra 6."],
	],
	&"turn_3_sortie": [  # Il voit le détenu 3 courir
		[&"joueur", "Le 3 sort ! Il court… vers le générateur ?! S'il coupe le courant, je suis mal !"],
	],
	&"blackout": [  # Coupure de courant
		[&"joueur", "Le courant ! Il a coupé le générateur…"],
		[&"joueur", "Il faut que j'aille le redémarrer."],
	],
	&"caught": [  # Le détenu 3 l'a attrapé dans le noir
		[&"joueur", "…Ma tête… Il m'a laissé là. Le générateur. Vite."],
	],
	&"detenu_3_screamer": [
		[&"detenu_3", "A MON TOUR"],
	],
	&"turn_3_done": [  # Après le détenu 3
		[&"joueur", "C'est fini… Les trois sont maîtrisés. Retour au bureau."],
	],
}

const TALK_2_NEEDED := 2
const TALK_2: Array = [
	{
		"line": "Reste où tu es ! Elles me regardent… Toutes ces caméras… Elles me regardent tout le temps.",
		"answers": [
			["Doucement. Je suis le gardien, je suis seul. Personne ne te veut de mal.", 1, "Le gardien… Le vrai ? Pas l'autre ?"],
			["Pose ce couteau. Tout de suite.", 0, "Le poser ? Pour qu'il me trouve sans défense ?"],
			["Lâche ça ou je tire.", -1, "Tu vois ! Tu es comme lui !"],
		],
	},
	{
		"line": "Le Quatrième est passé devant ma porte. Il ne regarde jamais les caméras. Il va revenir me chercher.",
		"answers": [
			["J'ai regardé tous les écrans de la nuit. Personne n'est passé.", 1, "Personne… Tu en es sûr ? Tu as tout regardé ?"],
			["Le Quatrième s'est évadé il y a trois jours.", 0, "Évadé ? Non. Il est encore ici. Je le sens."],
			["Arrête avec tes histoires de Quatrième.", -1, "Tu ne me crois pas. Personne ne me croit."],
		],
	},
	{
		"line": "Si je retourne dans ma cellule, il va venir. Qui va me protéger ?",
		"answers": [
			["Moi. Je reste aux écrans, je ne te lâche pas des yeux. Promis.", 1, "…Tu me regarderas ? Tout le temps ?"],
			["Les caméras tournent toute la nuit, de toute façon.", 0, "De toute façon…"],
			["Ce n'est pas mon problème.", -1, "Alors je me protège tout seul."],
		],
	},
]
const TALK_2_END := {
	"success": "D'accord… D'accord. Je pose le couteau.",
	"fail": "Menteur ! Tu es avec LUI !",
}

const OBJECTIVES: Dictionary = {
	&"intro": "Rejoindre le poste de surveillance (au fond du bureau)",
	&"turn_1": "Regarder la caméra de la cellule 1 (CAM 02)",
	&"turn_1_empty": "Aller à la cellule 1 (bloc A, au nord-ouest)",
	&"turn_1_done": "Retourner au poste de surveillance",
	&"turn_2": "Regarder la cellule 2 (CAM 09)",
	&"turn_2_sortie": "Suivre le détenu 2 sur les caméras (cuisines, réfectoire)",
	&"turn_2_refectoire": "Aller au réfectoire (au nord)",
	&"turn_2_done": "Retourner au poste de surveillance",
	&"turn_3": "Regarder la cellule 3 (CAM 06)",
	&"turn_3_sortie": "Suivre le détenu 3 sur les caméras",
	&"blackout": "Prendre la carte du bureau (voyant rouge)",
	&"blackout_carte": "Rallumer le générateur (suis la carte et le bruit du moteur)",
	&"turn_3_done": "Retourner au bureau",
}

## Bouts de journal : le carnet du gardien disparu.
const JOURNALS: Array = [
	{
		"title": "Carnet du gardien — page 1",
		"body": "Le 1 connaît tous les angles morts. Hier soir, sur l'écran, sa cellule était vide. Je suis descendu : il était là, plaqué contre le mur, juste sous la caméra. Il m'a souri.\n\nIl parle d'un maître qui lui aurait appris à disparaître.",
	},
	{
		"title": "Carnet du gardien — page 2",
		"body": "Le 2 parle aux caméras. Il répète que tant qu'une caméra le filme, il existe. Pendant ses crises, il ne se calme que si on lui parle doucement et qu'on lui promet de le regarder.\n\nSes crises reviennent chaque fois que le Quatrième passe devant sa porte. Le Quatrième, lui, ne regarde jamais les caméras. Il sait toujours où elles sont.",
	},
	{
		"title": "Carnet du gardien — page 3",
		"body": "Le 3 a déjà coupé le courant deux fois. Dans le noir, il entend tout.\n\nIl est maladivement jaloux du Quatrième : il veut être comme lui.",
	},
	{
		"title": "Carnet du gardien — dernière page",
		"body": "Le Quatrième est très curieux, trop curieux, il me met mal à l'aise.\n\nJ'ai l'impression qu'il m'observe constamment. Je l'ai même surpris en train de s'entraîner à m'imiter.\n\nJe sens que je ne rentrerai pas chez moi ce soir.",
	},
]

## Noms affichés des détenus et phrase de la confrontation.
const PRISONER_NAMES: Dictionary = {1: "Le Caméléon", 2: "Le Fragmenté", 3: "L'Électricien"}
const ENCOUNTERS: Dictionary = {
	1: "Il jaillit de l'angle mort et se jette sur toi !",
	2: "Il se jette sur toi, le couteau levé !",
	3: "La lumière revient… il est juste devant toi !",
}

## Fins (clés = GameState.Ending).
const ENDINGS: Dictionary = {
	1: {
		"title": "LE BON",
		"subtitle": "« Bonne » fin",
		"body": "Les trois détenus ont été maîtrisés sans une goutte de sang.\n\nAu matin, la direction te félicite et te propose le poste de nuit, pour de bon. Tu acceptes sans hésiter.\n\nTu as toujours aimé cet endroit.",
	},
	2: {
		"title": "LA BRUTE",
		"subtitle": "Mauvaise fin",
		"body": "Au petit matin, la relève te trouve assis devant les écrans, l'arme encore chaude.\n\nLes détenus ne s'évaderont plus. Personne ne posera de questions sur le sang dans les couloirs.\n\nPersonne, sauf toi. Chaque nuit.",
	},
	3: {
		"title": "LE TRUAND",
		"subtitle": "Fin secrète",
		"body": "Les quatre pages réunies ne laissent aucun doute : tu n'es pas à ta place.\n\nTu plies soigneusement les pages, tu les glisses dans la poche de ton uniforme, et tu reprends ta place devant les écrans.\n\nCette prison n'a jamais été aussi bien gardée. Et maintenant, elle est à toi.",
	},
}
