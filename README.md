# FRAMER — Générateur procédural de façades (3ds Max 2026)

Script MAXScript pour Autodesk 3ds Max 2026 : génère des façades procédurales
(piliers, travées, rez-de-chaussée vitré, arcades type Perret, portique à colonnes,
étages identiques ou indépendants, balcons, variation aléatoire par graine,
guides d'étages et moulures balayées).

## Installation

1. Télécharger `FRAMER_0.6.ms`.
2. Dans 3ds Max : menu *Scripting > Run Script…* et choisir le fichier.
3. La fenêtre FRAMER s'ouvre (mode création / mode édition).

## Version 0.6.2

- **Toit sur contour retravaillé** : le toit part désormais du contour **décalé vers
  l'extérieur** (valeur du débord, 0,4 m par défaut) au lieu du rectangle englobant,
  et un **fond fermé** (face vers le bas) bouche la vue d'en dessous, débord compris.
  - *Terrasse* : dalle + acrotère suivant le contour décalé.
  - *Deux pentes* : versants suivant le contour décalé, faîtage exact sur le plus long
    segment (pas de pignons maçonnés en mode contour).
  - *Quatre pans* : même principe, pans de bout coupés par les diagonales à 45° des
    extrémités du faîtage (footprints convexes recommandés).
- **Corrections** :
  - plantage « Mauvais index de membre local thunk libre » sur les vitrines en arc ;
  - plantage « Tentative d'accès supprimée Objet scène » si la spline du contour a été
    supprimée après le choix (message clair + sélecteur réinitialisé) ;
  - plantage « Impossible de convertir matrix3 vers Point3 » du toit en mode contour.

## Version 0.6.1

- **Toits** (onglet Toit) : toit-terrasse avec acrotère (suit exactement le contour,
  polygone triangulé), toit à deux pentes (pignons) ou à quatre pans (croupes).
  Pente, débord et hauteur d'acrotère réglables. Un toit remplace la corniche.
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
