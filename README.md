# Imajam — Surveillance (squelette)

Squelette vide pour Godot 4.3 : arborescence, classes, signaux, variables et signatures de fonctions. Aucune logique.

```
autoload/        Events (bus de signaux), GameState, Texts, InputSetup
scenes/          main.tscn (nœuds d'organisation + systèmes), player.tscn
scripts/game/        TurnManager
scripts/player/      Player
scripts/cameras/     SecurityCamera, CameraSystem
scripts/interaction/ Interactable + Pickup, JournalPiece, MapBoard, SecurityDesk, Generator, CellDoor
scripts/prisoners/   Prisoner + PrisonerHider (1), PrisonerTracker (2), PrisonerStalker (3), TrackWaypoint
scripts/world/       PowerGrid
scripts/ui/          UiRoot, Hud, PostIt, DocumentPanel, MapPanel, InventoryPanel, EncounterPanel, EndingPanel
```


## Version jouable (branche `version-complete`)

Toute la boucle du GDD est branchée, avec des capsules à la place des personnages :
menu → intro (journal + le seul appel téléphonique) → tour 1 → tour 2 → tour 3 → panne → retour au
bureau → une des 3 fins.

- **Tour 1** : la cellule 1 paraît vide à l'écran (CAM 02) : le détenu est dans l'angle mort.
- **Tour 2** : le détenu 2 (camisole blanche) s'agite dans sa cellule. Quand on le voit à la CAM 09,
  il force sa porte, passe par les cuisines (il y prend un couteau) et s'arrête au réfectoire.
  En entrant dans le réfectoire, on le raisonne : 3 échanges, 3 réponses chacun (+1 rassure,
  0 neutre, -1 énerve). Avec au moins 2 points (`TALK_2_NEEDED`) il lâche le couteau ; sinon il
  charge, et pas de taser possible : il faut tirer. Textes : `TALK_2` dans `autoload/texts.gd`.
- **Tour 3** : le détenu 3 sort en courant quand on le voit à la CAM 06 et coupe le générateur.
- **Répliques** : après l'appel du début, c'est le garde qui pense à voix haute (sous-titres en
  italique). Les répliques se déclenchent au moment où on voit l'événement à l'écran. Si on ne
  regarde pas, chaque détenu finit par sortir tout seul au bout de 40 s.
- **Doublage** : chaque réplique joue automatiquement `assets/voix/<personnage>/<nom>.ogg` s'il
  existe (sinon seul le sous-titre s'affiche). La liste des 45 répliques avec leurs noms de
  fichier est dans `assets/voix/A_ENREGISTRER.md`. Code : `scripts/game/dialogue.gd` et
  `Sfx.play_voice()`.

- **Commandes** : ZQSD/WASD, souris (ou flèches), Maj courir, E interagir, Tab inventaire, R médicaments,
  Échap pause. Au poste : ◄ ► (ou Q/D) pour changer de caméra.
- **Tests rapides (debug)** : F2 tour 2, F3 tour 3, F4 panne, F7 téléportation (cellule 1, réserve, infirmerie, cellule 2, réfectoire, cellule 3, générateur, bureau), K pendant la panne : le détenu 3 apparaît à quelques mètres, J fin. (F6, F8 et F9 sont des raccourcis de l'éditeur quand le jeu tourne.)
- **Nouveaux autoloads** : `Settings` (options), `Sfx` (sons), `PrisonNav` (grille de la prison
  pour les déplacements des détenus, la carte et le post-it).
- **À remplacer** : textes (`autoload/texts.gd`), sons (`assets/sounds/`, générés), capsules
  (nœud `Modele` de chaque détenu), objets (boîtes dans `scripts/interaction/`).
- `scenes/panel.gd` (panneau de Wallis) n'est plus utilisé : `DocumentPanel` le remplace.
- `scripts/prisoners/prisoner_tracker.gd` (ancien tour 2 « suivre de caméra en caméra ») n'est plus utilisé :
  le détenu 2 utilise `prisoner_crisis.gd`.
