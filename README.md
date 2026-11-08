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
scripts/ui/          UiRoot, Hud, MiniMap, DocumentPanel, MapPanel, InventoryPanel, EncounterPanel, EndingPanel
```


## Version jouable (branche version-complete)

Le jeu marche de bout en bout, avec des capsules à la place des persos.

Déroulé : intro -> tour 1 (le 1 se cache dans l'angle mort de sa caméra) -> tour 2 (le 2 sort de sa
cellule, prend un couteau aux cuisines et attend au réfectoire, il faut le calmer en lui parlant) ->
tour 3 (le 3 coupe le générateur, passage dans le noir) -> retour au bureau -> une des 3 fins.

Touches : ZQSD/WASD, souris ou flèches, Maj pour courir, E interagir, Tab inventaire, R médocs,
Echap pause. Au poste : Q/D ou flèches pour changer de caméra.

Debug : F2 tour 2, F3 tour 3, F4 panne, F7 téléport, K détenu 3 à côté (pendant la panne), J fin.
Attention, F6/F8/F9 sont pris par l'éditeur quand le jeu tourne.

Négo avec le 2 : il faut au moins 2 points à la fin (réponse qui le rassure +1, agressive -1).
Les textes sont dans autoload/texts.gd.

Voix : mettre les fichiers dans assets/voix/<perso>/ avec le nom donné dans A_ENREGISTRER.md,
le jeu les lance tout seul.

Encore provisoire : les textes, les sons (assets/sounds), les capsules et les objets.
Plus utilisés : scenes/panel.gd et scripts/prisoners/prisoner_tracker.gd.
