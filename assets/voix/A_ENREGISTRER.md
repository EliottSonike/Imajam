# Voix à enregistrer

48 répliques (nouvelles : G25 pour l'ordre aléatoire, G27 pour la traque du détenu 1 ; G26 est déjà couverte). Chaque mp3 est nommé avec son code (ex. `G7.mp3`), puis rangé dans
`assets/voix/<perso>/<fichier>.mp3` avec le nom de la colonne Fichier (.ogg, .wav ou .mp3).
Le jeu lance la voix tout seul ; sans fichier, il affiche juste le sous-titre.

Si une réplique change dans autoload/texts.gd, la réenregistrer avec le même code.

## Téléphone (assets/voix/telephone/)

| Code | Fichier | Réplique |
|---|---|---|
| T1 | `intro_1` | Allô ? C'est moi. Tu as pris ton poste, parfait. |
| T2 | `intro_2` | Il ne reste que trois détenus. Ils ne doivent pas quitter leur cellule. |
| T3 | `intro_3` | Installe-toi aux écrans, au fond du bureau. *(déjà enregistrée : la fin « Commence par la cellule 1… » a été coupée)* |
| T4 | `intro_4` | Je ne pourrai pas te rappeler cette nuit. Tu es seul. Bon courage. |


## Le garde (assets/voix/joueur/)

| Code | Fichier | Réplique |
|---|---|---|
| G1 | `turn_1_1` | Bon. La cellule 1 d'abord… caméra 2. |
| G2 | `turn_1_empty_1` | Quoi ?! La porte n'a pas bougé… Il est forcément encore là-dedans. |
| G3 | `turn_1_empty_2` | J'y vais. Il me faut de quoi me défendre. |
| G4 | `turn_1_done_1` | Un de moins… Retour aux écrans. |
| G5 | `turn_2_1` | Le bloc B est agité ce soir… Voyons la cellule 2. Caméra 9. |
| G6 | `turn_2_sortie_1` | Le 2 ! Il a forcé sa porte… Il part vers les cuisines… |
| G7 | `turn_2_refectoire_1` | Il s'est arrêté au réfectoire… Il tient quelque chose. Un couteau ? Je dois y aller. |
| G8 | `turn_2_calme_1` | Il a lâché le couteau… C'est fini. Il faut que je retourne au bureau. |
| G9 | `turn_2_tue_1` | Je n'avais pas le choix… Je n'avais pas le choix. Il m'a attaqué, il faut que je retourne au bureau. |
| G10 | `turn_3_1` | Plus que le 3. Cellule 3… caméra 6. |
| G11 | `turn_3_sortie_1` | Le 3 sort ! Il court… vers le générateur ?! S'il coupe le courant, je suis mal ! |
| G12 | `blackout_1` | Le courant ! Il a coupé le générateur… |
| G13 | `blackout_2` | Il faut que j'aille le redémarrer. |
| G14 | `caught_1` | …Ma tête… Il m'a laissé là. Le générateur. Vite. |
| G15 | `turn_3_done_1` | C'est fini… Les trois sont maîtrisés. Retour au bureau. |
| G16 | `negociation_1_reponse_1` | Doucement. Je suis le gardien, je suis seul. Personne ne te veut de mal. |
| G17 | `negociation_1_reponse_2` | Pose ce couteau. Tout de suite. |
| G18 | `negociation_1_reponse_3` | Lâche ça ou je tire. |
| G19 | `negociation_2_reponse_1` | J'ai regardé tous les écrans de la nuit. Personne n'est passé. |
| G20 | `negociation_2_reponse_2` | Le Quatrième s'est évadé il y a trois jours. |
| G21 | `negociation_2_reponse_3` | Arrête avec tes histoires de Quatrième. |
| G22 | `negociation_3_reponse_1` | Moi. Je reste aux écrans, je ne te lâche pas des yeux. Promis. |
| G23 | `negociation_3_reponse_2` | Les caméras tournent toute la nuit, de toute façon. |
| G24 | `negociation_3_reponse_3` | Ce n'est pas mon problème. |
| G25 | `turn_1_suite_1` | La cellule 1, maintenant… caméra 2. |
| G26 | `turn_3_suite_1` | Cellule 3… caméra 6. *(déjà faite : fin de G10 recoupée)* |
| G27 | `turn_1_fuite_1` | Il file ! Pas le choix… je sors mon arme. |

Le premier tour, c'est le garde qui choisit sa cellule : G1, G5 ou G26 selon le détenu tiré. G1 sert quand le 1 passe en premier, G25 sinon. G10 sert quand le 3 passe en dernier, G26 sinon.
G4 sert après le 1 ou le 3 s'il en reste, G15 après le dernier.

## Détenu 1 (assets/voix/detenu_1/)

| Code | Fichier | Réplique |
|---|---|---|
| D1-1 | `detenu_1_attaque_1` | COUCOU, j'étais bien caché ? |

## Détenu 2 (assets/voix/detenu_2/)

| Code | Fichier | Réplique |
|---|---|---|
| D2-1 | `detenu_2_couteau_1` | N'approche pas ! J'ai un couteau… Je n'hésiterai pas à l'utiliser |
| D2-2 | `negociation_1` | Reste où tu es ! Elles me regardent… Toutes ces caméras… Elles me regardent tout le temps. |
| D2-3 | `negociation_1_reaction_1` | Le gardien… Le vrai ? Pas l'autre ? |
| D2-4 | `negociation_1_reaction_2` | Le poser ? Pour qu'il me trouve sans défense ? |
| D2-5 | `negociation_1_reaction_3` | Tu vois ! Tu es comme lui ! |
| D2-6 | `negociation_2` | Le Quatrième est passé devant ma porte. Il ne regarde jamais les caméras. Il va revenir me chercher. |
| D2-7 | `negociation_2_reaction_1` | Personne… Tu en es sûr ? Tu as tout regardé ? |
| D2-8 | `negociation_2_reaction_2` | Évadé ? Non. Il est encore ici. Je le sens. |
| D2-9 | `negociation_2_reaction_3` | Tu ne me crois pas. Personne ne me croit. |
| D2-10 | `negociation_3` | Si je retourne dans ma cellule, il va venir. Qui va me protéger ? |
| D2-11 | `negociation_3_reaction_1` | …Tu me regarderas ? Tout le temps ? |
| D2-12 | `negociation_3_reaction_2` | De toute façon… |
| D2-13 | `negociation_3_reaction_3` | Alors je me protège tout seul. |
| D2-14 | `negociation_reussie` | D'accord… D'accord. Je pose le couteau. |
| D2-15 | `negociation_ratee` | Menteur ! Tu es avec LUI ! |

## Détenu 3 (assets/voix/detenu_3/)

| Code | Fichier | Réplique |
|---|---|---|
| D3-1 | `detenu_3_screamer_1` | A MON TOUR |

## Murmures du détenu 3 (déjà enregistrés)

Pendant la traque dans le noir, il lâche ces phrases au hasard, chacune une seule fois, et se tait s'il est
maîtrisé avant : `detenu_3/detenu_3_murmure_1.ogg` à `detenu_3_murmure_4.ogg` (découpées dans « Chez Tonton
Lazhar 2 »). Pas de sous-titre pour l'instant.
