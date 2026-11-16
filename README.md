# FRAMER — Générateur procédural de façades (3ds Max 2026)

Script MAXScript pour Autodesk 3ds Max 2026 : génère des façades procédurales
(piliers, travées, rez-de-chaussée vitré, arcades type Perret, portique à colonnes,
étages identiques ou indépendants, balcons, variation aléatoire par graine,
guides d'étages et moulures balayées).

## Installation

1. Télécharger `FRAMER_0.6.ms`.
2. Dans 3ds Max : menu *Scripting > Run Script…* et choisir le fichier.
3. La fenêtre FRAMER s'ouvre (mode création / mode édition).

## Presets d'exemple

- `presets/Facade_photo.framer` — maison de ville d'après photo (7 travées, 5 étages,
  volets battants, garde-corps barreaudés).
- `presets/Facade_photo2.framer` — façade moderne d'après photo (balcons profonds 1,20 m).
- `presets/Facade_photo3.framer` — résidence d'après photo (balcons filants vitrés,
  brise-soleil à lames, 6 étages, toit-terrasse).
- `presets/Facade_photo4.framer` — immeuble commercial d'après photo (4 travées,
  rdc vitrines, 4 étages de porte-fenêtres, balcons individuels à garde-corps vitré,
  casquettes, toit-terrasse avec acrotère).
- `presets/Facade_photo5.framer` — résidence blanche d'après modèle 3D (6 travées,
  6 étages, balcons individuels pleine travée à garde-corps vitré 1,20 m,
  porte-fenêtres PLEINE HAUTEUR (allège 0, vitrage 2,90 m, 85 % de la travée), balcons en MIX par travée (50 % saillants, 30 % loggias),
  menuiseries gris foncé, toit-terrasse).

Copier dans `plugcfg\FRAMER\presets` puis Charger.

## Version 0.6.10

- **Arêtes biseautées** sur les casquettes et les dalles (balcons, bow-windows) :
  chanfrein sous l'arête côté rue au lieu de la dalle rectangulaire brute.
- **Bow-window simple** (nouveau choix *Bow simple (rectangulaire)* du menu
  Balcons de l'étage) : oriel vitré en saillie parallélépipédique sans joues
  inclinées, poteaux d'angle droits, dalle et capot biseautés.
- **Rythme par travée** (nouveau choix *Mix (par travée)* du menu Balcons de
  l'étage) : sur un même étage, chaque travée tire au hasard balcon saillant,
  loggia ou rien, selon deux pourcentages réglables dans l'onglet Étages
  (« Mix : balcons (% travées) », « Mix : loggias (% travées) ») — le tirage
  dépend de la graine.
- **Profondeur et variation par étage** : en mode *Indépendants*, la profondeur
  des balcons/loggias et leur variation aléatoire (± %) se règlent étage par
  étage (comme la hauteur et le type) ; en mode *Identiques*, un réglage commun.
- **Épaisseur des dalles réglable** (onglet Étages, « Épaisseur des dalles (m) ») :
  la dalle de 30 cm (« grande casquette » de la 0.6.7) est conservée par défaut,
  0,15 m pour une dalle fine.
- **Variation de profondeur des balcons/loggias corrigée** : le plancher minimal
  était un 0,3 m fixe qui écrasait le tirage aléatoire sur les faibles profondeurs ;
  il est désormais relatif (35 % de la profondeur réglée) et le tirage réel
  s'affiche dans la ligne de résumé (« prof. dalles : X à Y m »).
- **Corrigé : crash « L'appel nécessite une fonction ou une classe : undefined »**
  dès qu'on activait la moulure d'assemblage (fonction référencée avant sa
  définition dans le fichier = locale implicite indéfinie en MAXScript).
  Déclarations globales anticipées : moulure, fenêtres cintrées et
  dalles/casquettes biseautées fonctionnent.
- **Plafond de galerie PLAT au niveau de la clé de l'arc** : la voûte en berceau
  qui se prolongeait en profondeur « remplissait » l'arc (arcades pleines).
  Le plafond est désormais une dalle plate à la hauteur de la clé : l'arc reste
  lisible côté rue, la galerie garde toute la hauteur, et les retombées près
  des piliers descendent sous le plafond (comme sur une construction réelle).
- **Parseur de presets tolérant aux commentaires inline** : une ligne de preset
  du type `width=23.0000  -- commentaire` se charge désormais sans erreur
  (tout ce qui suit `--` est ignoré).

## Version 0.6.8

- **Trou noir dans la dalle de terrasse** (toit en mode contour, plans non convexes) :
  la triangulation de la dalle et du fond se bloquait en cours de découpe d'oreilles
  (le mauvais sommet était supprimé — le premier du triangle au lieu du sommet de
  l'oreille), laissant ~10 % de la surface sans triangle. Découpe corrigée + filet de
  sécurité (dernier triangle forcé, clipping forcé du sommet le plus convexe).
  Couverture validée à 100 % sur le contour en L (brut et décalé), un U, un rectangle,
  un hexagone.
- **Couleurs par défaut réalistes** : les 8 sélecteurs démarrent sur des teintes
  réalistes (murs beige, verre bleu-gris désaturé sombre, piliers gris béton,
  menuiseries gris foncé, portes bois, volets crème, toit brun, panneaux beige clair)
  au lieu du bleu pur de MAXScript.

## Version 0.6.7

- **Couleurs des matériaux** (onglet Général, groupe *Couleurs des matériaux*) :
  8 sélecteurs — Murs, Menuiseries, Piliers, Verre, Portes, Volets, Toit,
  Panneaux. Appliqués à chaque génération / mise à jour : les matériaux de
  scène `FRAMER_xxx` déjà présents sont recolorés. Mémorisés par façade et
  dans les presets.
- **Grande casquette à chaque niveau** : la dalle des balcons (saillants,
  loggias, filants) passe de 15 à **30 cm** d'épaisseur — avec une saillie de
  1,20 m, elle se lit comme une casquette proéminente au-dessus de chaque
  niveau (dessus de dalle inchangé).
- **Corrigé — toit en mode contour** : le toit rectangulaire « façade simple »
  était généré pour chaque segment du contour, en plus du toit suivant le
  contour (mélange incohérent). Le toit part bien du contour (décalé du
  débord), généré une seule fois.
- **Corrigé — bow-windows** : erreur de signe sur la profondeur des joues —
  joues à 45° et dalle/capot invisibles, vitrage avant décalé et trop large.

## Version 0.6.6

- **Bow-windows** (nouveau choix *Bow-windows* du menu *Balcons de l'étage*) :
  oriel vitré en 3 facettes (joues à 45° + face avant) sur toute la travée,
  dalle et capot compris. Profondeur = réglage balcon (varie avec
  *Variation de profondeur*) ; la face avant garde au moins 0,8 m de large.
- **Baies cintrées** (onglet Hasard, *Baies cintrées (% des fenêtres)*) :
  part des fenêtres des étages à tête en plein cintre, vitrage et cadre
  suivant l'arc (tirage par travée). Pas de volets roulants, ni volets
  battants, ni moulure d'encadrement sur une baie cintrée.
- **Onglets lisibles** : libellés raccourcis (Gén., Rdc, Étag., Fen., Toit,
  Hasard, Moul.) — l'onglet Moulures était tronqué à droite.

## Version 0.6.5

- **Encadrement des baies (moulure d'assemblage)** (onglet Fenêtres, groupe
  *Encadrement des baies*) : une moulure est balayée autour de chaque ouverture
  (fenêtres des étages et du rdc maison de ville). Profil par défaut : bande de
  **7 cm**, saillie 8 cm, chanfreinée. Profil personnalisé : créez-le avec
  *Créer un profil carré* (onglet Moulures), éditez ses sommets (x = largeur
  depuis la baie, y = saillie vers la rue), puis choisissez-le avec le bouton
  *Profil* ; échelle réglable. Matériau de scène : `FRAMER_Moulding`.
- **Garde-corps « Lisse seule »** (nouveau choix du menu Garde-corps) : juste
  la main courante, sans remplissage. Le menu Garde-corps commande désormais
  aussi le type de garde-corps des **balcons** (Vitré / Barreaudé / Plein /
  Lisse seule / Aucun = dalle nue).
- **Largeur des cadres par défaut : 7 cm** (avant 12 cm).
- **Presets** : plantage « No "map" function » corrigé (les chaînes MAXScript
  ne sont pas itérables) ; bouton « … » pour charger un preset depuis
  n'importe quel dossier ; bouton « ↻ » et chemin du dossier affiché.
- **Correction majeure** : `copy <array>` renvoie `OK` en MAXScript (pas une
  copie !) — toutes les copies de tableaux (presets, segments de contour,
  étages indépendants) se partagent la même référence, ce qui provoquait des
  réglages qui « fuyaient » d'un étage/segment à l'autre. Remplacées par une
  copie élément par élément (`FR_CopyArr`).
- Plus de **garde-corps en double** derrière les balcons.

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
