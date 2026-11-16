# FRAMER — Générateur procédural de façades (3ds Max 2026)

Script MAXScript pour Autodesk 3ds Max 2026 : génère des façades procédurales
(piliers, travées, rez-de-chaussée vitré, arcades type Perret, portique à colonnes,
étages identiques ou indépendants, balcons, variation aléatoire par graine,
guides d'étages et moulures balayées).

## Installation

1. Télécharger `FRAMER_0.6.ms`.
2. Dans 3ds Max : menu *Scripting > Run Script…* et choisir le fichier.
3. La fenêtre FRAMER s'ouvre (mode création / mode édition).

## Version 0.6.4

- **Onglets réordonnés** : Général, **Rdc**, Étages, Fenêtres, Toit, **Hasard**
  (ex-Variation), Moulures — libellés raccourcis pour tenir dans la barre
  d'onglets.
- **Preset d'exemple** : `presets/Facade_photo.framer` — façade reconstruite
  d'après photo (porte 2,50 m, 7 travées, 5 étages, garde-corps barreaudés,
  balcons saillants sauf au 1er étage). À copier dans
  `plugcfg\FRAMER\presets` puis Charger.
- **Panneaux pleins / vitrés alternés** (onglet Étages) : pour le type
  *Panneaux pleins*, le réglage *Panneaux pleins (% des travées)* tire au
  hasard, par travée, un panneau plein ou un panneau vitré (100 % = tous
  pleins, 0 % = tous vitrés).
- **Profondeur de balcons aléatoire** (onglet Étages) : *Variation de
  profondeur (± %)* — la profondeur des balcons saillants, loggias et du
  balcon filant varie au hasard par travée autour de la profondeur réglée
  (0 = profondeur fixe).
- **Lissage supprimé** : tous les groupes de lissage sont retirés (arêtes
  vives, rendu facetté) sur les objets fusionnés comme sur les arches et toits.
- **Haut des arches / plafond de galerie** : l'arc se prolonge maintenant en
  profondeur (**voûte en berceau**) jusqu'au fond de la galerie — c'est le
  plafond, à la hauteur de la clé de l'arc (avant : dalle plate traversant le
  haut des arcs, puis plafond trop bas, arcs tronqués côté galerie). Le
  portique (linteau droit) garde son plafond plat.
- **Arcades / portique** : un pilier est reporté au plan des vitrines
  reculées, dans l'alignement des colonnes de devant (plus de trous entre deux
  travées, le vitrage et le fond s'arrêtant aux limites de travée). La barre
  horizontale au pied des vitrines est supprimée : le vitrage et ses montants
  descendent jusqu'au sol.
- **Rdc maison de ville** : plus de piliers saillants — un mur continu avec
  les fenêtres de 1,40 × 1,20 m à allège 0,90 m centrées par travée.
- **Échelle des fenêtres du rdc maison de ville** : fenêtres à **1,40 m de large
  × 1,20 m de haut**, allège à **0,90 m** (avant, elles étaient trop grandes).
- **Hauteur des portes unifiée et réglable** : toutes les portes ont la même
  hauteur (seule la largeur varie), via le nouveau réglage *Hauteur des portes*
  de l'onglet Rez-de-chaussée — **2,05 m minimum pour une maison de ville**,
  **3,00 m pour un magasin ou un grand immeuble** ; le réglage suit
  automatiquement le choix du type de rez-de-chaussée. Avant, les portes
  « Porte + vitrage » montaient jusqu'au bandeau (pleine hauteur du rdc) et la
  travée d'entrée était bridée à 2,40 m. Une **imposte vitrée** ferme désormais
  le reste de la hauteur au-dessus des portes « Porte + vitrage ».
- **Volets battants corrigés** : ils débordaient au-dessus des fenêtres (aux
  étages comme au rdc).
- **Fond de galerie** : mur opaque ajouté derrière le vitrage reculé des
  arcades en arc et du portique (on ne voit plus à travers la galerie).
- **Placement corrigé** : la façade apparaissait au mauvais endroit en mode
  « Sur une face sélectionnée » ou « Le long d'un contour fermé » dès que la
  face ou la spline avait été déplacée/rotée après création (double
  transformation de coordonnées).
- **Volets battants à deux vantaux** : vrais volets pivotés — fermés devant la
  fenêtre (ouverture 0 %) ou ouverts à plat contre le mur (100 %), avec
  rotation réelle intermédiaire. L'angle suit le réglage « Ouverture du volet
  (%) » de l'onglet Fenêtres.
- **Style d'étage « Maison de ville (volets battants) »** (nouveau choix dans
  *Type de l'étage*) : comme « Fenêtres », mais toutes les fenêtres reçoivent
  des volets battants.
- **Rez-de-chaussée « Maison de ville »** (nouveau choix dans *Type du
  rez-de-chaussée*) : mur plein avec une fenêtre standard encadrée par travée
  (volets battants), et la porte d'entrée sur la travée d'entrée. Les
  casquettes/brise-soleil s'appliquent aussi au rdc. Recette type : rez 3–4 m,
  2 étages « Maison de ville », volets fermés ou ouverts, toit à deux pentes
  ou quatre pans.

## Version 0.6.3

- **Presets** : sauvegarde et rechargement des réglages de la fenêtre (travées,
  rez-de-chaussée, étages, fenêtres, toit, variation…). Tapez un nom, cliquez
  *Sauver* ; le preset apparaît dans la liste, *Charger* le rappelle, *Suppr.*
  l'efface. Les presets sont des fichiers `.framer` dans le dossier de
  configuration de 3ds Max (`plugcfg\FRAMER\presets`) : copiables, renommables,
  partageables. En mode contour, un preset s'applique au segment affiché
  (utilisez ensuite « Appliquer ce segment à tous » si besoin).

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
