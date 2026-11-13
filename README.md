# FRAMER — Générateur procédural de façades (3ds Max 2026)

Script MAXScript pour Autodesk 3ds Max 2026 : génère des façades procédurales
(piliers, travées, rez-de-chaussée vitré, arcades type Perret, portique à colonnes,
étages identiques ou indépendants, balcons, variation aléatoire par graine,
guides d'étages et moulures balayées).

## Installation

1. Télécharger `FRAMER_0.6.ms`.
2. Dans 3ds Max : menu *Scripting > Run Script…* et choisir le fichier.
3. La fenêtre FRAMER s'ouvre (mode création / mode édition).

## Version 0.6.0

- **Contour fermé** : dessiner une spline fermée (vue de dessus), la sélectionner,
  et générer une façade qui suit tout le contour. Chaque segment peut recevoir un
  style différent (côté rue, côté jardin, pignon…) via le sélecteur de segment ;
  les coins reçoivent une colonne d'angle.
- **Nouvelles options de fenêtres** (onglet Fenêtres) : garde-corps optionnels
  (vitré / barreaudé / plein), volets roulants simulés (pourcentage + ouverture),
  casquettes / brise-soleil (pourcentage + profondeur).
- **Correctifs** : vitrines au plan reculé des arcades en arc, balcons saillants /
  rentrants (loggias) et balcons par étage en mode « indépendants ».

*Test requis dans 3ds Max 2026 : le script n'a pas pu être exécuté hors de Max.*
