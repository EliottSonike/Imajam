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
