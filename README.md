# The Guard : Surveillance

Jeu d'horreur à la première personne réalisé en 2 jours pour l'Imajam (thème : **surveillance**),
avec Godot 4.7 (rendu Forward+).

Vous êtes le gardien de nuit de l'aile psychiatrique du pénitencier Saint-Roch. Il ne reste que trois
détenus, et ils ne doivent pas quitter leur cellule. Depuis le poste de garde, vous les surveillez sur
les écrans… jusqu'à ce qu'il faille descendre.

## Déroulé

1. **Intro** : une coupure de journal sur l'évasion d'un détenu, puis l'appel de votre responsable.
2. **Détenu 1** : il a disparu de sa cellule à l'écran. Il se cache dans l'angle mort de sa caméra.
3. **Détenu 2** : en pleine crise, il force sa porte, prend un couteau aux cuisines et s'arrête au
   réfectoire. Il faut le calmer en lui parlant (ou en arriver aux mains).
4. **Détenu 3** : il coupe le générateur. Dans le noir, avec le plan recopié sur un post-it, il faut
   rallumer le courant pendant qu'il vous traque.
5. **Retour au bureau**, puis l'une des trois fins.

**Les fins**
- **Le Bon** : personne n'est tué.
- **La Brute** : au moins un détenu est tué.
- **Le Truand** : les 4 pages du carnet du gardien sont retrouvées (cette fin remplace les autres).
  La dernière page est bien cachée : suivez l'eau.

## Commandes

| Action | Touche |
|---|---|
| Se déplacer | ZQSD / WASD |
| Regarder | souris ou flèches |
| Courir | Maj (impossible quand la vision est trouble) |
| Interagir | E |
| Inventaire et carnet | Tab |
| Prendre un médicament | R |
| Pause | Échap |
| Changer de caméra (au poste) | Q / D ou ◄ ► |

**Debug** (dans l'éditeur uniquement) : F2 détenu 2, F3 détenu 3, F4 panne, F7 téléportation entre
des points clés, K détenu 3 à côté (pendant la panne), J fin. Attention : F6, F8 et F9 sont pris par
l'éditeur quand le jeu tourne.

## Organisation du projet

```
autoload/            Events (signaux), GameState, Texts (tous les textes), Settings, Sfx, PrisonNav (plan + chemins)
scenes/              menu.tscn (mur d'écrans), main.tscn (jeu), level.tscn, props.tscn, cameras.tscn
scripts/game/        TurnManager (déroulé des tours), Dialogue (répliques + voix)
scripts/player/      Player
scripts/cameras/     SecurityCamera, CameraSystem
scripts/interaction/ Interactable, Pickup, JournalPiece, MapBoard, SecurityDesk, Generator, CellDoor
scripts/prisoners/   Prisoner + PrisonerHider (1), PrisonerCrisis (2), PrisonerStalker (3)
scripts/world/       Decor (matériaux, écrans en direct), Mobilier (meubles), TracesEau, PowerGrid
scripts/ui/          UiTheme + tous les panneaux (carte, inventaire, journal, négociation, pause, fin…)
assets/voix/         doublage, un dossier par personnage (liste dans A_ENREGISTRER.md)
tools/               scripts Python qui génèrent des assets (voir plus bas)
```

- **Textes** : tout est dans `autoload/texts.gd`.
- **Voix** : mettre le fichier dans `assets/voix/<perso>/<nom>.ogg` avec le nom donné dans
  `assets/voix/A_ENREGISTRER.md`. Le jeu le lance tout seul ; sans fichier, il affiche juste le sous-titre.
- **Sons** : `assets/sounds/<nom>.ogg` (ou `.wav`) ; un `.ogg` remplace le `.wav` du même nom.
- **Affichage** : le jeu est conçu en 1280×720 et s'étire à toutes les résolutions (`canvas_items` / `expand`),
  y compris en écran large.
- **Meubles** : les meubles du modèle de la prison sont cachés et remplacés par des modèles détaillés
  dans `scripts/world/mobilier.gd`. Les positions y sont écrites en dur : si la map change, il faut
  les mettre à jour.
- **Négociation avec le 2** : il faut au moins 2 points à la fin (réponse qui rassure +1, agressive −1).

## Outils (`tools/`)

| Script | Rôle |
|---|---|
| `generate_plan.py` | plan de la prison (style plan d'architecte), depuis la grille de `PrisonNav` |
| `generate_postit.py` | plan recopié à la main sur le post-it (mini-carte) |
| `generate_ui.py` | textures de l'interface (toile d'uniforme, poche, porte-bloc, rubans Dymo, icônes) |
| `generate_sol.py` | texture des dalles de sol |
| `generate_traces.py` | traces d'eau (empreintes, flaques, gouttes) |
| `optimize_glb.py` | réduit les textures d'un modèle `.glb` téléchargé : `python tools/optimize_glb.py entree.glb sortie.glb 1024` |

## Équipe

- **Eliott** (EliottSonike) : structure du jeu, déroulé, textes, voix
- **Wallis** (Wallis-code) : joueur, interface, interactions
- **Axel** : modèle 3D de la prison, des détenus, des écrans et du téléphone
- **froshe** : sons, voix du garde

## Licences

Le code, les textes, les voix et les modèles faits par l'équipe appartiennent à l'équipe.

Les modèles 3D, polices et sons tiers ont leur propre licence : la liste complète, avec les auteurs,
est dans **[CREDITS.md](CREDITS.md)**. La plupart sont en CC-BY 4.0 (crédit obligatoire), sauf :

- **Cleaning Cart** : CC-BY-NC 4.0 → **pas d'usage commercial** ;
- **Security camera** : licence Sketchfab Standard → utilisable dans le jeu, mais pas de
  redistribution du modèle seul.

**Le jeu ne peut donc pas être vendu tel quel.** Pour une version payante, il faudrait remplacer ces
deux modèles.
