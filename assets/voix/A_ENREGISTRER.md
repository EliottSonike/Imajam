# Répliques à enregistrer

45 répliques au total.

Chaque réplique a son fichier. Mettez l'enregistrement dans `assets/voix/<personnage>/` avec
**exactement** ce nom (en `.ogg`, `.wav` ou `.mp3`) : le jeu le joue tout seul, et le sous-titre
reste affiché le temps de l'enregistrement. S'il n'y a pas de fichier, seul le sous-titre s'affiche.

Exemple : `assets/voix/joueur/turn_2_sortie_1.ogg`.

Les textes viennent de `autoload/texts.gd` : si vous modifiez une réplique là-bas, réenregistrez-la
avec le même nom de fichier.

## Téléphone — dossier `assets/voix/telephone/`

| Fichier | Réplique | Moment |
|---|---|---|
| `intro_1` | Allô ? C'est moi. Tu as pris ton poste, parfait. | Appel au début de la nuit (le seul coup de téléphone du jeu) |
| `intro_2` | Il ne reste que trois détenus. Ils ne doivent pas quitter leur cellule. | Appel au début de la nuit (le seul coup de téléphone du jeu) |
| `intro_3` | Installe-toi aux écrans, au fond du bureau. Commence par la cellule 1 : le 1 ne répond plus. | Appel au début de la nuit (le seul coup de téléphone du jeu) |
| `intro_4` | Je ne pourrai pas te rappeler cette nuit. Tu es seul. Bon courage. | Appel au début de la nuit (le seul coup de téléphone du jeu) |

## Le garde (pensées) — dossier `assets/voix/joueur/`

| Fichier | Réplique | Moment |
|---|---|---|
| `turn_1_1` | Bon. La cellule 1 d'abord… caméra 2. | Premier passage aux écrans |
| `turn_1_empty_1` | Vide ?! La porte n'a pas bougé… Il est forcément encore là-dedans. | Il voit la cellule 1 vide à l'écran |
| `turn_1_empty_2` | Je déverrouille la cellule à distance. J'y vais. Il me faut de quoi me défendre. | Il voit la cellule 1 vide à l'écran |
| `turn_1_done_1` | Un de moins… Retour aux écrans. | Après le détenu 1 |
| `turn_2_1` | Le bloc B est agité ce soir… Voyons la cellule 2. Caméra 9. | Retour aux écrans après le détenu 1 |
| `turn_2_sortie_1` | Le 2 ! Il a forcé sa porte… Il part vers les cuisines ! | Il voit le détenu 2 sortir de sa cellule |
| `turn_2_refectoire_1` | Il s'est arrêté au réfectoire… Il tient quelque chose. Un couteau ? Je dois y aller. | Il voit le détenu 2 arrêté au réfectoire |
| `turn_2_calme_1` | Il a lâché le couteau… C'est fini. Retour aux écrans. | Négociation réussie |
| `turn_2_tue_1` | Je n'avais pas le choix… Je n'avais pas le choix. Retour aux écrans. | Négociation ratée : le joueur a dû tirer |
| `turn_3_1` | Plus que le 3. Cellule 3… caméra 6. | Retour aux écrans après le détenu 2 |
| `turn_3_sortie_1` | Le 3 sort ! Il court… vers le générateur ?! S'il coupe le courant, je suis aveugle. | Il voit le détenu 3 courir |
| `blackout_1` | Le courant ! Il a coupé le générateur… | Coupure de courant |
| `blackout_2` | J'entends le moteur d'ici. Il faut que je suive le bruit. | Coupure de courant |
| `caught_1` | …Ma tête… Il m'a laissé là. Le générateur. Vite. | Le détenu 3 l'a attrapé dans le noir |
| `turn_3_done_1` | C'est fini… Les trois sont maîtrisés. Retour au bureau. | Après le détenu 3 |
| `negociation_1_reponse_1` | Doucement. Je suis le gardien, je suis seul. Personne ne te veut de mal. | Réfectoire, échange 1 (réponse au choix) |
| `negociation_1_reponse_2` | Pose ce couteau. Tout de suite. | Réfectoire, échange 1 (réponse au choix) |
| `negociation_1_reponse_3` | Lâche ça ou je tire. | Réfectoire, échange 1 (réponse au choix) |
| `negociation_2_reponse_1` | J'ai regardé tous les écrans de la nuit. Personne n'est passé. | Réfectoire, échange 2 (réponse au choix) |
| `negociation_2_reponse_2` | Le Quatrième s'est évadé il y a trois jours. | Réfectoire, échange 2 (réponse au choix) |
| `negociation_2_reponse_3` | Arrête avec tes histoires de Quatrième. | Réfectoire, échange 2 (réponse au choix) |
| `negociation_3_reponse_1` | Moi. Je reste aux écrans, je ne te lâche pas des yeux. Promis. | Réfectoire, échange 3 (réponse au choix) |
| `negociation_3_reponse_2` | Les caméras tournent toute la nuit, de toute façon. | Réfectoire, échange 3 (réponse au choix) |
| `negociation_3_reponse_3` | Ce n'est pas mon problème. | Réfectoire, échange 3 (réponse au choix) |

## Détenu 1 — dossier `assets/voix/detenu_1/`

| Fichier | Réplique | Moment |
|---|---|---|
| `detenu_1_attaque_1` | Tu ne m'avais pas vu, hein ? | Le détenu 1 sort de l'angle mort |

## Détenu 2 — dossier `assets/voix/detenu_2/`

| Fichier | Réplique | Moment |
|---|---|---|
| `detenu_2_couteau_1` | N'approche pas ! J'ai un couteau… Je l'ai pris aux cuisines ! | Le joueur entre dans le réfectoire |
| `negociation_1` | Reste où tu es ! Elles me regardent… Toutes ces caméras… Elles me regardent tout le temps. | Réfectoire, échange 1 |
| `negociation_1_reaction_1` | Le gardien… Le vrai ? Pas l'autre ? | Réfectoire, réaction à la réponse 1 de l'échange 1 |
| `negociation_1_reaction_2` | Le poser ? Pour qu'il me trouve sans défense ? | Réfectoire, réaction à la réponse 2 de l'échange 1 |
| `negociation_1_reaction_3` | Tu vois ! Tu es comme lui ! | Réfectoire, réaction à la réponse 3 de l'échange 1 |
| `negociation_2` | Le Quatrième est passé devant ma porte. Il ne regarde jamais les caméras. Il va revenir me chercher. | Réfectoire, échange 2 |
| `negociation_2_reaction_1` | Personne… Tu en es sûr ? Tu as tout regardé ? | Réfectoire, réaction à la réponse 1 de l'échange 2 |
| `negociation_2_reaction_2` | Évadé ? Non. Il est encore ici. Je le sens. | Réfectoire, réaction à la réponse 2 de l'échange 2 |
| `negociation_2_reaction_3` | Tu ne me crois pas. Personne ne me croit. | Réfectoire, réaction à la réponse 3 de l'échange 2 |
| `negociation_3` | Si je retourne dans ma cellule, il va venir. Qui va me protéger ? | Réfectoire, échange 3 |
| `negociation_3_reaction_1` | …Tu me regarderas ? Tout le temps ? | Réfectoire, réaction à la réponse 1 de l'échange 3 |
| `negociation_3_reaction_2` | De toute façon… | Réfectoire, réaction à la réponse 2 de l'échange 3 |
| `negociation_3_reaction_3` | Alors je me protège tout seul. | Réfectoire, réaction à la réponse 3 de l'échange 3 |
| `negociation_reussie` | D'accord… D'accord. Je pose le couteau. | Réfectoire, négociation réussie |
| `negociation_ratee` | Menteur ! Tu es avec LUI ! | Réfectoire, négociation ratée (il charge) |

## Détenu 3 — dossier `assets/voix/detenu_3/`

| Fichier | Réplique | Moment |
|---|---|---|
| `detenu_3_screamer_1` | Tu m'as cherché dans le noir ? | Le courant revient, le détenu 3 est devant lui |
