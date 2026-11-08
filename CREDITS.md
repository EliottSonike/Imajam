# Crédits

## Équipe

- **Eliott** (EliottSonike) : structure du jeu, déroulé, textes, voix du téléphone et des détenus
- **Wallis** (Wallis-code) : joueur, interface, interactions
- **Axel** : modèle de la prison (`models/prison.glb`), détenus, écrans, téléphone, matériaux
- **froshe** : sons, voix du garde

## Modèles 3D tiers

Tous viennent de Sketchfab. Licence **CC-BY 4.0** (https://creativecommons.org/licenses/by/4.0/),
sauf mention contraire.

| Modèle | Auteur | Fichier |
|---|---|---|
| Hospital Bed | loxfear | `models/lit_hopital.glb` |
| Prison Table | chuZz | `models/table_prison.glb` |
| Locker | neverfollow81 | `models/casier.glb` |
| tabur | kesha62 | `models/tabouret.glb` |
| Chaise de bureau | GwendolineR | `models/chaise_bureau.glb` |
| Carton Box_05_Closed | Pixeled Bun | `models/carton.glb` |
| Toilette | GNI-APALH | `models/toilettes.glb` |
| Lavabo | Antonio Rossini (Rox3d) | `models/lavabo.glb` |
| Industrial Switches Apollo Command Module | ntilted | `models/tableau_electrique.glb` |
| Simple Generator (Fixed) | Blender3D | `models/groupe_electrogene.glb` |
| Etagère | oooFFFFEDDMODELS | `models/etagere.glb` |
| Evega Tazer | lumoize | `models/taser.glb` |
| Electromenager fifty's | Configcars / maxipub | `models/electromenager.glb` |
| Old table | EricKos | `models/table_ancienne.glb` |
| Jerrycan | DJMaesen | `models/jerrican.glb` |
| Kitchen Cabinets | jimbogies | `models/cuisine_meubles.glb` |
| jailShower_head | dronelord | `models/pommeau_douche.glb` |
| Rusty medical cart | CarlosTorresVFX | `models/chariot_infirmerie.glb` |
| Laundry Bin | cnseto | `models/chariot_linge.glb` |
| Office Desk | Mehdi Shahsavan | `models/bureau.glb` |
| Pills | Dawndragon | `models/medicaments.glb` |
| Steel table | yoyo83710 | `models/table_inox.glb` |
| caution wet floor / cleaning sign v2 | Sousinho | `models/panneau_sol_mouille.glb` |
| Cleaning Cart | Kerridge1 | `models/chariot_menage.glb` — **CC-BY-NC 4.0 : pas d'usage commercial** |
| Security camera | Veebroush | `models/camera_surveillance.glb` — **licence Sketchfab Standard** : utilisable dans le jeu, pas de redistribution du modèle seul |
| Pistol | Quaternius (Poly Pizza) | `models/pistolet.fbx` — **CC0** (domaine public) |

Modifications : textures réduites (`tools/optimize_glb.py`) ; le casier, la caméra et l'électroménager
sont découpés en morceaux ; tous sont mis à l'échelle et placés par `scripts/world/mobilier.gd`.

## Sons

- Halètement (`assets/sounds/halete.wav`) : « Male Breathing Slow », freesound_community (Pixabay),
  accéléré.
- Cri du taser (`assets/sounds/cri_taser.wav`) : fait à partir de la voix d'Eliott.
- Autres sons de `assets/sounds/` : ajoutés par l'équipe — **sources à compléter** (ambiance,
  porte, coup de feu, sonnerie, screamer, taser, pas).

## Voix

Enregistrées par l'équipe. Nettoyage, effet « téléphone » et « voix intérieure » appliqués avec ffmpeg.

## Polices

Toutes sous **SIL Open Font License 1.1** (licences dans `assets/fonts/`) :
Caveat, Old Standard TT, UnifrakturMaguntia, Saira Stencil One, Barlow Condensed, IBM Plex Mono.

## Textures générées

Plan de la prison, post-it, interface, dalles de sol et traces d'eau : générés par les scripts de
`tools/` (pas de source extérieure). Le béton des murs et le carrelage du réfectoire ont été ajoutés
par Axel.

## Moteur

[Godot Engine](https://godotengine.org) 4.7 (licence MIT) et le plugin godot-git-plugin (licence MIT).
