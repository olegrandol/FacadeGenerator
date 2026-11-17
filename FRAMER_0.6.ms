/*
    FRAMER 0.6.18
    Générateur procédural de façades
    Autodesk 3ds Max 2026

    CORRIGÉ EN 0.6.18 :
    - TOIT DU MODE CONTOUR (formes en L et contours concaves) : le décalage
      du contour (débord vers l'extérieur, puis épaisseur d'acrotère vers
      l'intérieur) peut s'AUTO-INTERSECTER sur les angles rentrants ou les
      formes étroites — c'est ce qui produisait les triangles en vrille et
      les dalles détachées. Le résultat du décalage est désormais VÉRIFIÉ
      (polygone simple + aire cohérente) : en cas d'échec le décalage est
      réduit de moitié, plusieurs fois si nécessaire, et un message précise
      la valeur effectivement appliquée. Les sommets confondus introduits
      par le décalage sont supprimés (ils faisaient échouer la triangulation
      = trous dans le toit plat).
    - DIAGNOSTICS : quand aucun versant ne peut être construit (pente trop
      faible pour la profondeur, découpe impossible) ou quand la terrasse
      ne peut pas être créée, un message explique pourquoi au lieu de
      laisser un toit absent sans explication.
    - INTERFACE : la ligne « Espacement » des lucarnes se superposait au
      bouton GÉNÉRER (chevauchement y=700) — les contrôles lucarnes sont
      remontés au-dessus.

    NOUVEAU EN 0.6.17 :
    - LUCARNES DU TOIT MANSARDÉ (onglet Toit, « Lucarnes (mansard) ») :
      les 3 styles classiques, construits dans les règles de l'art (sans
      booléens) — chevet vertical posé sur le brisis avec baie vitrée en
      retrait, joues latérales noyées dans la pente, toiture qui MEURT dans
      le brisis :
        • Fronton   : pignon triangulaire coiffé d'une cornice en bandeau ;
        • Rectangulaire : bâtière simple à deux versants ;
        • Capucine  : toit courbe en demi-cylindre (arc balayé) ;
        • Alterné   : une lucarne à toit EN PENTE, puis une à toit ARRONDI,
          la répartition traditionnelle.
      Réglages : largeur, hauteur, espacement (rangée centrée sur la
      façade). Posées sur le brisis avant (côté rue). Enregistré dans les
      presets (lucMode/lucW/lucH/lucStep, FRAMER_PARAMS=25).

    NOUVEAU EN 0.6.16 :
    - TERRASSE « EN BAC » (toit-terrasse, façade simple ET mode contour) :
      l'acrotère n'est plus un simple bandeau posé sur une dalle fine. Il est
      construit comme la manipulation modélisée à la main : couronne PLEINE
      (ÉPAISSEUR réglable, défaut 0,55) dépassant de la hauteur d'acrotère,
      et plateau intérieur ENFONCÉ (GORGE INTÉRIEURE réglable, défaut 0,40)
      — comme un vrai acrotère avec sa gorge. Solide unique (dessous fermé),
      construit à partir du contour de base copié, translaté à la hauteur du
      bâtiment et décalé vers l'extérieur du débord — le même socle que tous
      les autres types de toits. Nouveaux réglages onglet Toit (actifs pour
      la terrasse) : « Épaisseur de l'acrotère », « Gorge intérieure ».
      Débord par défaut porté à 0,50. Enregistré dans les presets
      (acrTh/acrGorge, FRAMER_PARAMS=21).

    CORRIGÉ EN 0.6.15 :
    - TOIT TERRASSE EN MODE CONTOUR : « mauvaise triangulation » — dalle
      géante inclinée, détachée du bâtiment, avec des arêtes partant en
      biais dans le vide. Deux causes traitées :
      1) CONTOUR PARCOURU EN SENS HORAIRE : la triangulation (ear clipping)
         suppose des sommets anti-horaires ; en sens horaire aucun sommet
         convexe n'est détecté, le repli « clipping forcé » produisait des
         triangles en vrille, et le décalage du débord partait vers
         l'INTÉRIEUR au lieu de l'extérieur. L'orientation des polygones est
         désormais normalisée partout (FR_PolyArea / FR_PolyCCW : aire
         signée, inversion si nécessaire) — la triangulation, le décalage
         du débord, la dalle, le fond et les versants ne dépendent plus du
         sens dans lequel le contour a été dessiné.
      2) TRIANGLES IMPOSSIBLES : sur un contour décalé auto-intersecté
         (formes très concaves), le repli pouvait encore produire un
         triangle plus grand que le polygone lui-même — il est désormais
         détecté (aire du triangle vs aire du polygone) et sauté (trou
         local préférable à une dalle hors du bâtiment). Avant le repli
         aveugle, une oreille « assouplie » (sommets presque plats) est
         tentée avec la contenance vérifiée.
      3) L'appel toit du mode contour est passé dans le try/catch avec
         nettoyage du pool : une erreur pendant le toit ne laisse plus de
         dalle orpheline non parentée dans la scène.

    CORRIGÉ EN 0.6.14 :
    - CRASH AU CHARGEMENT DES ANCIENS PRESETS (FRAMER_PARAMS=6/9, d'avant
      la 0.6.10) : « Impossible de convertir. undefined vers type: Float » —
      ces presets n'ont pas les clés flBalcD/flBalcVar (profondeur et
      variation de balcon PAR ÉTAGE, ajoutées en 0.6.10) ; les tableaux
      restaient vides et le chargement de l'étage 1 lisait undefined.
      Les tableaux par étage sont désormais complétés avec les valeurs
      globales du preset, et le chargement d'étage est protégé.

    NOUVEAU EN 0.6.13 :
    - COUVRE-JOINT DES TOITS EN PENTE (onglet Toit, « Couvre-joint
      (faîtage) ») : un petit profil — TRIANGULAIRE (sec, moderne) ou
      ARRONDI (tuile faîtière traditionnelle), largeur et hauteur
      réglables — est posé le long des jonctions entre versants, là où les
      dalles fines ne se rejoignent que par une arête vive avec un coin
      creux en dessous : faîtage (deux pentes), faîtage + 4 arêtiers
      (quatre pans), arêtes du plateau (mansard). Posé en géométrie
      solide (pas de spline renderable) : fusionné dans le toit, supprimé
      avec lui, cohérent avec le nettoyage mémoire. Enfoncé de la moitié
      de sa course pour rester en contact avec les versants.

    NOUVEAU EN 0.6.12 :
    - NOMBRE DE PORTES RÉGLABLE dans le rdc « Alternance vitrine / porte » :
      nouveau réglage « Nombre de portes (alternance) » de l'onglet
      Rez-de-chaussée — 0 = automatique (une porte sur deux, comme avant) ;
      1 à 20 = nombre EXACT de portes, réparties régulièrement le long de la
      façade avec des vitrines entre elles (ex. 6 travées et 2 portes :
      vitrine vitrine PORTE vitrine vitrine PORTE). La travée d'entrée reste
      prioritaire (elle garde sa position et sa largeur). Enregistré dans les
      presets (nDoors, FRAMER_PARAMS=16).

    NOUVEAU EN 0.6.11 :
    - TOIT MANSARDÉ (nouveau choix « Mansard (brisis + terrasson) » du menu
      Type de toit) : le toit à la française en deux pentes par versant —
      le BRISIS, raide et bas (utilise la pente principale, à monter à
      60-75° dans le menu), puis le TERRASSON, doux (nouvelle réglage
      « Pente du terrasson », ~30°), réuni par un PLATEAU PLAT au sommet
      (réglage « Largeur du toit plat »), le tout ceinturé par l'acrotère
      (réglage « Hauteur de l'acrotère » réutilisé). Structure : 4 prismes
      de brisis + 4 prismes de terrasson + dalle sommitale + acrotères.
      En mode contour, le mansard retombe pour l'instant en quatre pans
      (faîtage sur le plus long segment) — limitation documentée.
    - PENTE DU TOIT étendue à 80° (le brisis d'un vrai mansard est raide).

    CORRIGÉ EN 0.6.11 :
    - CRASH AU LANCEMENT « Propriété inconnue: "color" dans
      LabelControl:lbEdit » : les labels MAXScript n'ont PAS de propriété
      couleur (contrairement aux barres de progression). Le liseret de mode
      repose sur la barre colorée + les libellés + les titres de groupe.

    NOUVEAU EN 0.6.10 :
    - MARQUEUR VISUEL DE MODE : liseret coloré dans le bandeau « Mode de
      travail » — BLEU en création, ORANGE VIF en édition — avec le libellé,
      le titre du groupe et le titre de la fenêtre qui affichent « ● ÉDITION ● »
      pour ne plus générer par erreur dans le mauvais mode.
    - MÉMOIRE : plus de débris orphelins après un plantage. Avant : si la
      génération crashait à mi-chemin, la géométrie déjà créée restait dans la
      scène SANS parent — invisible dans le nettoyage (qui ne cherche que parmi
      les enfants de la racine) et accumulée à chaque crash. Désormais :
      1) try/catch autour de la génération -> géométrie partielle supprimée
      avant de relancer l'erreur (façade simple ET mode contour) ;
      2) FR_CleanOrphans supprime à chaque génération les débris FRAMER_*
      orphelins laissés par les crashs précédents ;
      3) gc light après chaque mise à jour (même manuelle, pas qu'en direct).
    - RYTHME PAR TRAVÉE (nouveau choix « Mix (par travée) » du menu Balcons de
      l'étage) : sur un même étage, chaque travée tire au hasard balcon saillant,
      loggia ou rien, selon deux pourcentages réglables (balcons %, loggias %) —
      comme sur un vrai immeuble où loggias et balcons se répartissent travée par
      travée. Le tirage dépend de la graine.
    - ARÊTES BISEAUTÉES sur les casquettes et les dalles (balcons, bow-windows) :
      chanfrein sous l'arête côté rue (profil trapézoïdal balayé) au lieu de la
      dalle rectangulaire brute — ombre plus douce, lecture plus fine.
    - BOW-WINDOW SIMPLE (nouveau choix « Bow simple (rectangulaire) » du menu
      Balcons de l'étage) : oriel vitré en saillie parallélépipédique SANS joues
      inclinées — une seule face avant vitrée pleine largeur, poteaux d'angle
      droits, dalle et capot biseautés.
    - PLAFOND DE GALERIE PLAT (arcades) : la voûte en berceau qui se prolongeait
      en profondeur « remplissait » l'arc ; remplacée par une dalle plate au
      niveau de la clé de l'arc — l'arc reste lisible côté rue, la galerie garde
      toute la hauteur, les retombées près des piliers descendent sous le
      plafond (comme une construction réelle).
    - PARSEUR DE PRESETS TOLÉRANT AUX COMMENTAIRES INLINE : une ligne du type
      « width=23.0000  -- commentaire » se charge désormais sans erreur
      (tout ce qui suit « -- » dans la valeur est ignoré).

    CORRIGÉ EN 0.6.9 :
    - CRASH « L'appel nécessite une fonction ou une classe : undefined » dès
      qu'on coche la moulure d'assemblage : en MAXScript, une fonction
      référencée avant sa définition dans le fichier devient une locale
      implicite indéfinie (FR_Surround appelait FR_SweepMesh défini plus de
      2000 lignes plus bas). Déclarations globales anticipées pour toutes
      les fonctions concernées (FR_SweepMesh, FR_ReadProfile, FR_ArchWall,
      FR_ArchGlazing, FR_Pt, FR_Prisma) : la moulure, les fenêtres cintrées
      et les dalles/casquettes biseautées fonctionnent à nouveau.
    - ÉPAISSEUR DES DALLES RÉGLABLE (au lieu de supprimée) : la dalle de
      balcon de 30 cm (« grande casquette » de 0.6.7) est conservée par
      défaut ; nouveau réglage « Épaisseur des dalles (m) » de l'onglet
      Étages (0,08 à 0,60 ; 0,15 pour une dalle fine).
    - VARIATION DE PROFONDEUR des balcons/loggias à nouveau visible : le
      plancher minimal était un 0,3 m FIXE qui écrasait le tirage aléatoire
      sur les faibles profondeurs (ex. 0,4 m ± 50 % était presque tout
      clampé) ; il est désormais RELATIF (35 % de la profondeur réglée).
      Le tirage réel s'affiche dans la ligne de résumé (« prof. dalles :
      X à Y m ») pour vérifier d'un coup d'œil que la variation joue.

    CORRIGÉ EN 0.6.8 :
    - TROU NOIR DANS LA DALLE DE TERRASSE (toit en mode contour, plans non
      convexes) : la triangulation de la dalle et du fond se bloquait en
      cours de découpe d'oreilles — le sommet supprimé était le mauvais
      (le premier du triangle au lieu du sommet de l'oreille, au milieu),
      d'où des chevauchements puis un résidu horaire jamais découpable :
      ~10 % de la surface restait sans triangle (la zone noire). La découpe
      supprime désormais le bon sommet ; en sécurité, si aucun oreille n'est
      trouvée : dernier triangle ajouté tel quel à 3 sommets restants, sinon
      clipping forcé du sommet le plus convexe. Couverture validée à 100 %
      sur le contour en L (brut et décalé), un U, un rectangle, un hexagone.
    - COULEURS PAR DÉFAUT RÉALISTES : les 8 sélecteurs de couleurs démarrent
      sur des teintes réalistes (murs beige, verre bleu-gris désaturé sombre,
      piliers gris béton, menuiseries gris foncé, portes bois, volets crème,
      toit brun, panneaux beige clair) au lieu du bleu pur de MAXScript.

    NOUVEAU EN 0.6.7 :
    - COULEURS DES MATÉRIAUX (onglet Général, groupe « Couleurs des matériaux ») :
      8 sélecteurs — Murs, Menuiseries, Piliers, Verre, Portes, Volets, Toit,
      Panneaux. Appliqués à chaque génération / mise à jour : les matériaux de
      scène FRAMER_xxx déjà présents sont recolorés (pas besoin de les effacer).
      Mémorisés par façade et dans les presets.
    - GRANDE CASQUETTE À CHAQUE NIVEAU : la dalle des balcons (saillants,
      loggias, filants) passe de 15 à 30 cm d'épaisseur — avec une saillie
      réglée à 1,20 m, elle se lit comme une casquette proéminente au-dessus
      de chaque niveau (le dessus de la dalle est inchangé, le surplomb pend
      en dessous).

    CORRIGÉ EN 0.6.7 :
    - TOIT EN MODE CONTOUR « étrange » : le toit de façade simple (rectangle
      qui s'étend derrière la façade) était généré pour CHAQUE segment du
      contour, en plus du toit suivant le contour — d'où un mélange
      incohérent de toits. Le toit rectangulaire par segment est supprimé :
      en mode contour, le toit part bien du CONTOUR (décalé du débord),
      généré une seule fois.
    - BOW-WINDOWS cassés (erreur de signe sur la profondeur des joues) :
      joues à 45° et dalle/capot invisibles, vitrage avant décalé et trop
      large. Les 3 facettes, la dalle et le capot sont maintenant corrects.

    NOUVEAU EN 0.6.6 :
    - BOW-WINDOWS (nouveau choix « Bow-windows » du menu Balcons de l'étage) :
      oriel vitré en 3 facettes (joues à 45° + face avant) sur toute la travée,
      avec dalle et capot. La profondeur est celle du réglage balcon (et varie
      avec « Variation de profondeur »). La face avant garde au moins 0,8 m.
    - BAIES CINTRÉES (onglet Hasard, « Baies cintrées (% des fenêtres) ») :
      part des fenêtres des étages à tête en plein cintre (tirage par travée).
      Le vitrage et son cadre suivent l'arc ; pas de volets roulants ni de
      moulure d'encadrement sur une baie cintrée (ni volets battants en style
      maison de ville).
    - ONGLETS : libellés raccourcis (Gén., Rdc, Étag., Fen., Toit, Hasard,
      Moul.) — l'onglet Moulures était tronqué/masqué à droite.

    NOUVEAU EN 0.6.5 :
    - ENCADREMENT DES BAIES (onglet Fenêtres, groupe « Encadrement des baies ») :
      une moulure d'assemblage est balayée autour de chaque ouverture (fenêtres
      des étages et du rdc). Profil PAR DÉFAUT : bande de 7 cm, saillie 8 cm,
      chanfreinée. Pour un profil personnalisé : créez-le avec « Créer un profil
      carré » (onglet Moulures), modifiez ses sommets (x = largeur depuis la
      baie, y = saillie vers la rue), puis choisissez-le avec le bouton « Profil »
      de l'onglet Fenêtres. Échelle du profil réglable. Matériau de scène :
      FRAMER_Moulding.
    - GARDE-CORPS « LISSE SEULE » (nouveau choix du menu Garde-corps) : juste la
      main courante, sans remplissage ni barreaux. S'applique aux fenêtres ET
      aux balcons (le menu Garde-corps commande désormais aussi le type de
      garde-corps des balcons : Vitré = panneaux de verre, Barreaudé = fer
      forgé, Plein = panneaux opaques, Lisse seule, Aucun = dalle nue).
    - LARGEUR DES CADRES PAR DÉFAUT : 7 cm (avant 12 cm) — cadre plus fin.

    CORRIGÉ EN 0.6.5 :
    - PRESETS : plantage « No "map" function » au chargement — les chaînes MAXScript
      ne sont PAS itérables (for c in "texte") : nettoyage du nom par index
      (substring). Fonctionnait aussi mal pour un nom vide que pour un nom valide.
    - Presets : bouton « … » pour charger un .framer depuis n'importe quel dossier
      (parcourir), bouton « ↻ » pour réactualiser la liste, chemin du dossier affiché
      dans les messages.

    CORRIGÉ EN 0.6.4 :
    - LISSAGE SUPPRIMÉ : tous les groupes de lissage sont retirés (arêtes
      vives, rendu facetté), sur les objets fusionnés comme sur les arches,
      bandeaux et toits.
    - HAUT DES ARCHES / PLAFOND DE GALERIE : l'arc se prolonge maintenant en
      PROFONDEUR (voûte en berceau) jusqu'au fond de la galerie — c'est le
      plafond, à la hauteur de la clé de l'arc. Avant, une dalle plate
      traversait le haut des arcs, puis (correctif intermédiaire) plafonnait
      trop bas sous la retombée, et les arcs paraissaient tronqués côté
      galerie. Le portique (linteau droit) garde son plafond plat.
    - TROUS ENTRE TRAVÉES (arcades / portique) : les vitrines reculées et leur
      fond s'arrêtent aux limites de chaque travée — un pilier est maintenant
      reporté au plan des vitrines, dans l'alignement des colonnes de devant.
    - BARRE BASSE DES VITRINES D'ARCades : supprimée — le vitrage et ses
      montants descendent maintenant jusqu'au sol (plus de barre horizontale
      au pied des montants, côté rue comme côté galerie).
    - RDC MAISON DE VILLE : plus de piliers saillants — un mur continu, avec
      les fenêtres de 1,40 × 1,20 m à allège 0,90 m centrées par travée.
    - ÉCHELLE DES FENÊTRES DU RDC MAISON DE VILLE : fenêtres à 1,40 m de large
      × 1,20 m de haut, allège à 0,90 m (taille d'une fenêtre de maison de
      ville classique ; avant, elles étaient trop grandes).
    - HAUTEUR DES PORTES : toutes les portes ont maintenant LA MÊME HAUTEUR
      (seule la largeur varie), réglée par « Hauteur des portes » de l'onglet
      Rez-de-chaussée (2,05 m minimum pour une maison de ville, 3,00 m pour un
      magasin ou un grand immeuble ; l'auto-réglage suit le choix du type de
      rez-de-chaussée). Avant, les portes « Porte + vitrage » montaient jusqu'au
      bandeau (pleine hauteur du rdc) et la travée d'entrée était bridée à 2,40 m.
      Au-dessus des portes « Porte + vitrage », une imposte vitrée ferme le reste
      de la hauteur.
    - VOLETS BATTANTS : ils débordaient au-dessus des fenêtres (la hauteur
      absolue du haut de fenêtre était passée comme hauteur de volet) — aux
      étages comme au rez-de-chaussée.
    - FOND DE GALERIE : les arcades en arc et le portique n'avaient pas de fond
      — on voyait à travers le vitrage reculé jusqu'au fond du viewport. Un mur
      opaque ferme maintenant la galerie juste derrière le vitrage.
    - PLACEMENT : la façade générée en mode « Sur une face sélectionnée » ou
      « Le long d'un contour fermé » n'apparaissait pas à l'endroit de la face
      ou du contour dès que celui-ci avait été déplacé/roté après création
      (double transformation : polyop.getVert et getKnotPoint renvoient déjà
      des coordonnées monde). Le profil de moulure est maintenant lu en
      coordonnées locales, comme prévu.

    NOUVEAU EN 0.6.4 :
    - ONGLETS RÉORDONNÉS : Général, Rdc (rez-de-chaussée), Étages, Fenêtres,
      Toit, Hasard (ex-Variation), Moulures — les libellés sont raccourcis pour
      tenir dans la barre d'onglets.
    - PANNEAUX PLEINS / VITRÉS ALTERNÉS (onglet Étages) : pour le type
      « Panneaux pleins », un réglage « Panneaux pleins (% des travées) » tire
      au hasard, par travée, un panneau PLEIN ou un panneau VITRÉ. 100 % :
      tous pleins (comme avant). 0 % : tous vitrés.
    - PROFONDEUR DE BALCONS ALÉATOIRE (onglet Étages) : « Variation de
      profondeur (± %) » — la profondeur des balcons saillants, loggias et
      balcon filant varie au hasard, par travée, autour de la profondeur
      réglée (0 = profondeur fixe, comme avant).
    - VOLETS BATTANTS À DEUX VANTAUX : vrais volets à pivoter, fermés devant la
      fenêtre (ouverture 0 %) ou ouverts à plat contre le mur (100 %), rotation
      réelle intermédiaire. Le réglage « Ouverture du volet (%) » de l'onglet
      Fenêtres commande l'angle.
    - STYLE D'ÉTAGE « MAISON DE VILLE (VOLETS BATTANTS) » (nouveau choix du menu
      Type de l'étage) : comme « Fenêtres », mais chaque fenêtre reçoit des
      volets battants (pas de tirage au hasard : toutes les fenêtres en ont).
    - RDC « MAISON DE VILLE » (nouveau choix du menu Type du rez-de-chaussée) :
      mur plein avec une fenêtre standard encadrée par travée — avec volets
      battants — et la porte d'entrée sur la travée d'entrée (réglage Entrée de
      l'onglet Général). Les casquettes/brise-soleil s'appliquent aussi au rdc.
      Idéal avec : rez-de-chaussée 3–4 m, 2 étages « Maison de ville », volets
      fermés (0 %) ou ouverts (100 %), toit à deux pentes ou quatre pans.

    NOUVEAU EN 0.6.3 :
    - PRESETS : sauvegardez vos réglages et rechargez-les à tout moment (groupe
      "Presets" en bas de la fenêtre). Tapez un nom, cliquez Sauver ; le preset
      apparaît dans la liste, cliquez Charger pour rappeler tous les réglages
      (travées, rez-de-chaussée, étages, fenêtres, toit, variation...).
      Suppr. efface le preset sélectionné. Les presets sont des fichiers .framer
      stockés dans le dossier de configuration de 3ds Max
      (plugcfg\FRAMER\presets) : on peut les copier, renommer ou partager.
      En mode contour, un preset s'applique au segment affiché (utilisez ensuite
      "Appliquer ce segment à tous" si besoin).

    NOUVEAU EN 0.6.2 :
    - TOIT SUR CONTOUR : le toit part du contour DÉCALÉ vers l'extérieur (valeur du débord,
      0,4 m par défaut) au lieu du rectangle englobant, et un FOND FERMÉ (face vers le bas)
      bouche la vue d'en dessous, débord compris.
      * Terrasse : dalle + acrotère suivant le contour décalé.
      * Deux pentes : les versants suivent le contour décalé, faîtage exact sur le plus long
        segment (pas de pignons maçonnés en mode contour ; le fond ferme le bâtiment).
      * Quatre pans : même principe, pans de bout coupés par les diagonales à 45° des
        extrémités du faîtage (footprints convexes recommandés).

    CORRIGÉ EN 0.6.2 :
    - Vitrines en arc : plantage "Mauvais index de membre local thunk libre" (zsp) au
      moment de créer le verre en arc (collecteur inline passé en argument).
    - Génération en mode contour après suppression de la spline choisie : message clair
      au lieu du plantage "Tentative d'accès supprimée Objet scène".
    - Toit du contour (0.6.1) : plantage "Impossible de convertir matrix3 vers Point3"
      (axes du faîtage mal lus dans le repère du segment).

    NOUVEAU EN 0.6.1 :
    - MÉMOIRE : la mise à jour EN DIRECT ne crée plus d'entrée d'annulation (undo) :
      avant, chaque réglage empilait une façade complète en RAM jusqu'au plantage
      "Out of memory". Les mises à jour manuelles restent annulables (Ctrl+Z).
    - TOITS (nouvel onglet Toit) : toit-terrasse avec acrotère, toit à deux pentes (pignons)
      ou à quatre pans (croupes). Pente, débord et hauteur d'acrotère réglables.
      Un toit remplace la corniche. (Depuis 0.6.2, en mode contour, le toit suit le
      contour décalé vers l'extérieur — voir NOUVEAU EN 0.6.2.)

    NOUVEAU EN 0.6.0 :
    - CONTOUR FERMÉ : générez tout un bâtiment le long d'une spline fermée (nouveau mode
      "Le long d'un contour" de l'onglet Général). Chaque segment du contour devient une
      façade avec ses propres réglages (travées, rez-de-chaussée, graine, entrée...) ;
      la verticale (rez + étages) est commune pour que tout s'aligne.
    - COINS : une colonne d'angle est posée sur chaque sommet du contour ; les bandeaux,
      la corniche et la galerie sont prolongés jusqu'au coin. En édition, un sélecteur
      "Segment n°" permet de régler chaque côté séparément (côté rue, côté jardin...).
    - Garde-corps de fenêtres : vitré, barreaudé ou plein (nouvel onglet Fenêtres).
    - Volets roulants simulés : coffre + panneau, probabilité par travée, ouverture réglable.
    - Casquettes ou brise-soleil au-dessus des fenêtres, probabilité réglable.
    - NB : les tirages aléatoires des volets et casquettes décalent la séquence du hasard :
      une même graine ne redonne pas exactement la même façade qu'en 0.5.x.

    CORRIGÉ DEPUIS 0.5.7 :
    - Vitrines d'arcade reconstruites exactement comme les vitrines du premier plan
      (partie basse rectangulaire + verre et cadre en arc sans faces dégénérées).
    - Balcons saillants / rentrants : le réglage d'étage s'applique à TOUTES les travées
      (avant, il ne faisait rien sans "Autoriser les travées à balcon" + tirage aléatoire).
    - Plafond de la galerie couverte placé sous la clef des arches (visible depuis la galerie).
    - Garde-fou : bande pleine trop haute -> linteau droit au lieu d'une arche aberrante.

    RAPPEL 0.5.7 :
    - Arcades en arc : le passage reste ouvert comme avec le portique. Les gros piliers qui se
      prolongeaient jusqu'à la vitrine sont remplacés par les mêmes colonnes carrées libres
      que le portique ; les arches sont taillées dans le mur au-dessus.

    RAPPEL 0.5.5 / 0.5.6 :
    - Portique à colonnes (type Perret) et arcades : colonnes libres au rez-de-chaussée,
      galerie couverte, vitrines reculées, option "Vitrines en arc".

    RAPPEL 0.5.4 :
    - Interface en ONGLETS, bulles d'aide, MODE CRÉATION / MODE ÉDITION avec chargement
      automatique de la façade sélectionnée et mise à jour en direct.

    RAPPEL 0.5.3 :
    - Étages séparables (identiques ou indépendants), balcons saillants / rentrants / filants,
      guides d'étages, moulures balayées le long d'une ligne avec angles en onglet.

    RAPPEL 0.5.2 :
    - Chaque façade vit sous un helper racine (FRAMER_Facade_xx) qui mémorise ses paramètres.
    - METTRE À JOUR reconstruit la façade sélectionnée sur place ; "en direct" l'applique
      à chaque réglage.

    NOTE : MAXScript ne distingue pas majuscules et minuscules (P et p = même variable),
    la structure de paramètres s'appelle donc PR et le préfixe de nom p.

    AXES LOCAUX :
    X = horizontal (le long de la façade), Y = profondeur (positif = vers l'intérieur
    du bâtiment), Z = vertical. Pour un contour fermé, chaque segment a son propre repère :
    X le long du segment, Y vers l'intérieur (l'extérieur est à DROITE du sens de parcours,
    vu de dessus : même convention que le balayage des moulures).
*/

try(destroyDialog FRAMER_UI)catch()
callbacks.removeScripts id:#FRAMER_SEL

global FR_Pool = #()       -- boîtes créées par la génération en cours
global FR_VC = 0.0         -- profondeur (Y local) du plan médian du mur
global FR_Silent = false   -- pas de messageBox (mise à jour en direct)
global FR_Summary = ""     -- résumé d'une ligne de la dernière génération
global FR_Ctx = ""         -- préfixe des messages ("Segment 2 : ...")

-- codes internes <-> libellés des listes déroulantes (même ordre)
global FR_GroundCodes = #("Storefront","Door + sidelight","Alternating storefront / door","Opaque infill","Empty bay","Arcade","Portico","TownHouse")
global FR_ArcCodes = #("Round","Segment","Flat")
global FR_LastRoot = undefined   -- façade actuellement en édition
global FR_UpperCodes = #("Window","Glazed panel","Opaque panel","Plain wall","TownWin")
global FR_BalcCodes = #("None","Out","In","Cont","Bow","BowS","Mix")
global FR_EntCodes = #("None","Center","Left","Right","Random")
global FR_RailCodes = #("None","Glass","Bars","Solid","Lisse")
global FR_CapCodes = #("None","Slab","Lam")
global FR_RoofCodes = #("None","Flat","Gable","Hip","Mansard")
global FR_LucCodes = #("None","Fronton","Rectangulaire","Capucine","Alterné")
global FR_RidgeCodes = #("None","Tri","Round")

-- valeurs par étage du mode "indépendants" (globales : un local de rollout valait OK)
global FR_gH = #(3.0)
global FR_gMode = #("Window")
global FR_gWin = #(70.0)
global FR_gHt = #(1.5)
global FR_gSill = #(0.9)
global FR_gBalc = #("Out")
global FR_gBalcD = #(0.8)
global FR_gBalcVar = #(0.0)

-- mode contour : réglages de chaque segment + sommets du contour
global FR_CSegs = #()
global FR_CPts = #()
global FR_CurSeg = 1

struct FRParams
(
    width = 24.0,
    groundH = 4.2,
    upperH = 3.0,
    floors = 3,
    bays = 6,
    pier = 0.35,
    depth = 0.25,
    fw = 0.07,
    groundMode = "Storefront",
    upperMode = "Window",
    winPct = 70.0,
    winHt = 1.5,
    winSill = 0.9,
    balcD = 0.8,
    balcVar = 0.0,
    slabTh = 0.30,
    panOpaque = 100.0,
    seedVal = 1,
    variation = 30.0,
    widthVar = 10.0,
    allowWide = true,
    allowBalcony = false,
    allowWall = false,
    entrance = "Center",
    entranceFactor = 1.6,
    doorH = 3.0,
    nDoors = 0,               -- mode « Alternance vitrine / porte » : 0 = une porte sur deux (auto) ; >= 1 = nombre exact de portes
    cornice = true,
    arcType = "Round",
    arcRecess = 2.0,
    arcLintel = 0.6,
    arcGlArch = true,
    -- options de fenêtres (communes à tout le bâtiment)
    railMode = "None",
    railH = 1.0,
    railD = 0.15,
    shutPct = 0.0,
    shutOpen = 50.0,
    capMode = "None",
    capD = 0.4,
    capPct = 100.0,
    -- encadrement des baies (moulure d'assemblage, commun à tout le bâtiment)
    surr = false,
    surrS = 1.0,
    surrProf = "",
    arcPct = 0.0,
    -- couleurs des matériaux (communes à tout le bâtiment)
    colWall = color 214 204 188,
    colFrame = color 55 62 70,
    colPier = color 135 138 142,
    colGlass = color 95 170 205,
    colDoor = color 95 72 52,
    colShut = color 172 166 152,
    colRoof = color 122 84 66,
    colPanel = color 190 188 178,
    -- toit (commun à tout le bâtiment)
    roofMode = "None",
    roofPitch = 30.0,
    roofOver = 0.5,
    roofPar = 0.5,
    roofDepth = 8.0,
    -- terrasse « en bac » (0.6.16) : épaisseur de la couronne d'acrotère et
    -- creux intérieur (le plateau descend de cette valeur sous le sommet)
    acrTh = 0.55,
    acrGorge = 0.4,
    -- lucarnes du mansard (0.6.17) : style, largeur, hauteur, espacement (m)
    lucMode = "None",
    lucW = 1.0,
    lucH = 1.2,
    lucStep = 3.0,
    -- toit mansardé : largeur du plateau plat sommital (m) et pente du
    -- terrasson (degrés) ; le brisis utilise la pente principale (roofPitch)
    mansTop = 2.0,
    mansP2 = 30.0,
    -- couvre-joint des toits en pente (faîtage, arêtiers) : "None"/"Tri"/"Round"
    ridgeMode = "None",
    ridgeW = 0.18,
    ridgeH = 0.10,
    -- un élément par étage d'élévation
    flH = #(),
    flMode = #(),
    flWin = #(),
    flHt = #(),
    flSill = #(),
    flBalc = #(),
    -- profondeur et variation de profondeur des balcons/loggias, PAR ÉTAGE
    -- (mode indépendants) ; les globales balcD/balcVar servent au mode identiques
    -- et de défaut pour les façades plus anciennes
    flBalcD = #(),
    flBalcVar = #(),
    -- rythme PAR TRAVÉE : quand un étage est en "Mix", chaque travée tire au
    -- hasard balcon saillant (mixOut %), loggia (mixIn %) ou rien (le reste)
    mixOut = 40.0,
    mixIn = 30.0
)

/* ---------------------------------------------------------------------
   DÉCLARATIONS ANTICIPÉES (forward declarations).
   En MAXScript, une fonction référencée AVANT sa définition dans le
   fichier devient une « locale implicite » valant undefined au moment
   de l'appel (ex. FR_Surround -> FR_SweepMesh plantait dès que la
   moulure d'assemblage était cochée). On déclare donc ces noms comme
   globals ici ; les définitions `fn ...` plus bas réaffectent bien
   ces globals.
--------------------------------------------------------------------- */
global FR_Pt, FR_Prisma, FR_SweepMesh, FR_ArchWall, FR_ArchGlazing, FR_ReadProfile, FR_RidgeCap, FR_RoofBac
-- 0.6.16 : FR_RoofFlatRect (défini avant) appelle FR_OffsetContour/FR_RoofBac (définis après)
global FR_OffsetContour
-- 0.6.15 : FR_PolyArea / FR_PolyCCW (orientation des contours de toit)
global FR_PolyArea, FR_PolyCCW

fn FR_Msg txt =
(
    if not FR_Silent do messageBox (FR_Ctx + txt)
)

-- arêtes vives : aucun groupe de lissage sur les faces (rendu facetté)
fn FR_NoSmooth obj =
(
    if obj != undefined and isValidNode obj do
    (
        -- seuls les Editable Poly exposent les groupes de lissage via polyop :
        -- les mailles sont converties (FR_Merge les convertit de toute façon)
        if (classof obj) == Editable_mesh do convertToPoly obj

        if (classof obj) == Editable_Poly do
            polyop.setFaceSmoothGroup obj #{1..(polyop.getNumFaces obj)} 0
    )
)

-- complète ou tronque un tableau à n éléments (on répète le dernier, ou dflt si vide)
fn FR_FitArr arr n dflt =
(
    -- protection : si on ne reçoit pas un vrai tableau, on repart d'un tableau vide
    if classof arr != Array do arr = #()

    while arr.count < n do
    (
        if arr.count > 0 then
            append arr arr[arr.count]
        else
            append arr dflt
    )

    while arr.count > n do deleteItem arr arr.count

    arr
)

-- copie de tableau : `copy <array>` ne renvoie PAS une copie (il renvoie OK !),
-- ce qui détruisait silencieusement les tableaux par étage (balcon du 1er étage
-- du preset, réglages par segment du contour...). On copie élément par élément.
fn FR_CopyArr a =
(
    if classof a != Array then #()
    else for i in a collect i
)

/* =========================================================
   PARAMÈTRES <-> TEXTE (mémorisés dans le helper racine)
========================================================= */

fn FR_F v =
(
    formattedPrint v format:".4f"
)

-- lit une couleur sérialisée "r,g,b" (les chaînes MAXScript ne sont pas itérables :
-- filterString rend un tableau, on accède par index)
fn FR_ParseColor v =
(
    local cc = filterString v ","

    if cc != undefined and cc.count >= 3 then
        color (cc[1] as integer) (cc[2] as integer) (cc[3] as integer)
    else
        color 214 204 188
)

fn FR_JoinF arr =
(
    local s = ""

    for k = 1 to arr.count do
    (
        if k > 1 do s = s + ","
        s = s + (FR_F arr[k])
    )

    s
)

fn FR_JoinS arr =
(
    local s = ""

    for k = 1 to arr.count do
    (
        if k > 1 do s = s + ","
        s = s + (arr[k] as string)
    )

    s
)

fn FR_ParamsToString PR =
(
    local ss = stringStream ""

    format "FRAMER_PARAMS=25\n" to:ss
    format "width=%\n" (FR_F PR.width) to:ss
    format "groundH=%\n" (FR_F PR.groundH) to:ss
    format "upperH=%\n" (FR_F PR.upperH) to:ss
    format "floors=%\n" PR.floors to:ss
    format "bays=%\n" PR.bays to:ss
    format "pier=%\n" (FR_F PR.pier) to:ss
    format "depth=%\n" (FR_F PR.depth) to:ss
    format "fw=%\n" (FR_F PR.fw) to:ss
    format "groundMode=%\n" PR.groundMode to:ss
    format "upperMode=%\n" PR.upperMode to:ss
    format "winPct=%\n" (FR_F PR.winPct) to:ss
    format "winHt=%\n" (FR_F PR.winHt) to:ss
    format "winSill=%\n" (FR_F PR.winSill) to:ss
    format "balcD=%\n" (FR_F PR.balcD) to:ss
    format "balcVar=%\n" (FR_F PR.balcVar) to:ss
    format "slabTh=%\n" (FR_F PR.slabTh) to:ss
    format "panOpaque=%\n" (FR_F PR.panOpaque) to:ss
    format "seedVal=%\n" PR.seedVal to:ss
    format "variation=%\n" (FR_F PR.variation) to:ss
    format "widthVar=%\n" (FR_F PR.widthVar) to:ss
    format "allowWide=%\n" PR.allowWide to:ss
    format "allowBalcony=%\n" PR.allowBalcony to:ss
    format "allowWall=%\n" PR.allowWall to:ss
    format "entrance=%\n" PR.entrance to:ss
    format "entranceFactor=%\n" (FR_F PR.entranceFactor) to:ss
    format "doorH=%\n" (FR_F PR.doorH) to:ss
    format "nDoors=%\n" PR.nDoors to:ss
    format "cornice=%\n" PR.cornice to:ss
    format "arcType=%\n" PR.arcType to:ss
    format "arcRecess=%\n" (FR_F PR.arcRecess) to:ss
    format "arcLintel=%\n" (FR_F PR.arcLintel) to:ss
    format "arcGlArch=%\n" PR.arcGlArch to:ss
    format "railMode=%\n" PR.railMode to:ss
    format "railH=%\n" (FR_F PR.railH) to:ss
    format "railD=%\n" (FR_F PR.railD) to:ss
    format "shutPct=%\n" (FR_F PR.shutPct) to:ss
    format "shutOpen=%\n" (FR_F PR.shutOpen) to:ss
    format "capMode=%\n" PR.capMode to:ss
    format "capD=%\n" (FR_F PR.capD) to:ss
    format "capPct=%\n" (FR_F PR.capPct) to:ss
    format "surr=%\n" PR.surr to:ss
    format "surrS=%\n" (FR_F PR.surrS) to:ss
    format "surrProf=%\n" PR.surrProf to:ss
    format "arcPct=%\n" (FR_F PR.arcPct) to:ss
    format "colWall=%,%,%\n" PR.colWall.r PR.colWall.g PR.colWall.b to:ss
    format "colFrame=%,%,%\n" PR.colFrame.r PR.colFrame.g PR.colFrame.b to:ss
    format "colPier=%,%,%\n" PR.colPier.r PR.colPier.g PR.colPier.b to:ss
    format "colGlass=%,%,%\n" PR.colGlass.r PR.colGlass.g PR.colGlass.b to:ss
    format "colDoor=%,%,%\n" PR.colDoor.r PR.colDoor.g PR.colDoor.b to:ss
    format "colShut=%,%,%\n" PR.colShut.r PR.colShut.g PR.colShut.b to:ss
    format "colRoof=%,%,%\n" PR.colRoof.r PR.colRoof.g PR.colRoof.b to:ss
    format "colPanel=%,%,%\n" PR.colPanel.r PR.colPanel.g PR.colPanel.b to:ss
    format "roofMode=%\n" PR.roofMode to:ss
    format "roofPitch=%\n" (FR_F PR.roofPitch) to:ss
    format "roofOver=%\n" (FR_F PR.roofOver) to:ss
    format "roofPar=%\n" (FR_F PR.roofPar) to:ss
    format "roofDepth=%\n" (FR_F PR.roofDepth) to:ss
    format "acrTh=%\n" (FR_F PR.acrTh) to:ss
    format "acrGorge=%\n" (FR_F PR.acrGorge) to:ss
    format "lucMode=%\n" PR.lucMode to:ss
    format "lucW=%\n" (FR_F PR.lucW) to:ss
    format "lucH=%\n" (FR_F PR.lucH) to:ss
    format "lucStep=%\n" (FR_F PR.lucStep) to:ss
    format "mansTop=%\n" (FR_F PR.mansTop) to:ss
    format "mansP2=%\n" (FR_F PR.mansP2) to:ss
    format "ridgeMode=%\n" PR.ridgeMode to:ss
    format "ridgeW=%\n" (FR_F PR.ridgeW) to:ss
    format "ridgeH=%\n" (FR_F PR.ridgeH) to:ss
    format "flH=%\n" (FR_JoinF PR.flH) to:ss
    format "flMode=%\n" (FR_JoinS PR.flMode) to:ss
    format "flWin=%\n" (FR_JoinF PR.flWin) to:ss
    format "flHt=%\n" (FR_JoinF PR.flHt) to:ss
    format "flSill=%\n" (FR_JoinF PR.flSill) to:ss
    format "flBalc=%\n" (FR_JoinS PR.flBalc) to:ss
    format "flBalcD=%\n" (FR_JoinF PR.flBalcD) to:ss
    format "flBalcVar=%\n" (FR_JoinF PR.flBalcVar) to:ss
    format "mixOut=%\n" (FR_F PR.mixOut) to:ss
    format "mixIn=%\n" (FR_F PR.mixIn) to:ss

    ss as string
)

fn FR_ParamsFromString txt =
(
    local PR = FRParams()

    PR.flH = #()
    PR.flMode = #()
    PR.flWin = #()
    PR.flHt = #()
    PR.flSill = #()
    PR.flBalc = #()
    PR.flBalcD = #()
    PR.flBalcVar = #()

    local lines = filterString txt "\r\n"

    for ln in lines do
    (
        local pos = findString ln "="

        if pos != undefined and pos > 1 do
        (
            local k = substring ln 1 (pos-1)
            local v = substring ln (pos+1) ln.count

            -- tolère les commentaires inline : "width=23.0 -- commentaire"
            local cpos = findString v "--"
            if cpos != undefined do v = substring v 1 (cpos-1)
            -- supprime les espaces résiduels (les codes texte comme
            -- "Storefront " avec espace final ne correspondraient plus)
            v = trimLeft (trimRight v)
            k = trimRight k

            case k of
            (
                "width": PR.width = v as float
                "groundH": PR.groundH = v as float
                "upperH": PR.upperH = v as float
                "floors": PR.floors = v as integer
                "bays": PR.bays = v as integer
                "pier": PR.pier = v as float
                "depth": PR.depth = v as float
                "fw": PR.fw = v as float
                "groundMode": PR.groundMode = v
                "upperMode": PR.upperMode = v
                "winPct": PR.winPct = v as float
                "winHt": PR.winHt = v as float
                "winSill": PR.winSill = v as float
                "balcD": PR.balcD = v as float
                "balcVar": PR.balcVar = v as float
                "slabTh": PR.slabTh = v as float
                "panOpaque": PR.panOpaque = v as float
                "seedVal": PR.seedVal = v as integer
                "variation": PR.variation = v as float
                "widthVar": PR.widthVar = v as float
                "allowWide": PR.allowWide = (v == "true")
                "allowBalcony": PR.allowBalcony = (v == "true")
                "allowWall": PR.allowWall = (v == "true")
                "entrance": PR.entrance = v
                "entranceFactor": PR.entranceFactor = v as float
                "doorH": PR.doorH = v as float
                "nDoors": PR.nDoors = v as integer
                "cornice": PR.cornice = (v == "true")
                "arcType": PR.arcType = v
                "arcRecess": PR.arcRecess = v as float
                "arcLintel": PR.arcLintel = v as float
                "arcGlArch": PR.arcGlArch = (v == "true")
                "railMode": PR.railMode = v
                "railH": PR.railH = v as float
                "railD": PR.railD = v as float
                "shutPct": PR.shutPct = v as float
                "shutOpen": PR.shutOpen = v as float
                "capMode": PR.capMode = v
                "capD": PR.capD = v as float
                "capPct": PR.capPct = v as float
                "surr": PR.surr = (v == "true")
                "surrS": PR.surrS = v as float
                "surrProf": PR.surrProf = v
                "arcPct": PR.arcPct = v as float
                "colWall": PR.colWall = FR_ParseColor v
                "colFrame": PR.colFrame = FR_ParseColor v
                "colPier": PR.colPier = FR_ParseColor v
                "colGlass": PR.colGlass = FR_ParseColor v
                "colDoor": PR.colDoor = FR_ParseColor v
                "colShut": PR.colShut = FR_ParseColor v
                "colRoof": PR.colRoof = FR_ParseColor v
                "colPanel": PR.colPanel = FR_ParseColor v
                "roofMode": PR.roofMode = v
                "roofPitch": PR.roofPitch = v as float
                "roofOver": PR.roofOver = v as float
                "roofPar": PR.roofPar = v as float
                "roofDepth": PR.roofDepth = v as float
                "acrTh": PR.acrTh = v as float
                "acrGorge": PR.acrGorge = v as float
                "lucMode": PR.lucMode = v
                "lucW": PR.lucW = v as float
                "lucH": PR.lucH = v as float
                "lucStep": PR.lucStep = v as float
                "mansTop": PR.mansTop = v as float
                "mansP2": PR.mansP2 = v as float
                "ridgeMode": PR.ridgeMode = v
                "ridgeW": PR.ridgeW = v as float
                "ridgeH": PR.ridgeH = v as float
                "flH": PR.flH = for s in (filterString v ",") collect (s as float)
                "flMode": PR.flMode = for s in (filterString v ",") collect s
                "flWin": PR.flWin = for s in (filterString v ",") collect (s as float)
                "flHt": PR.flHt = for s in (filterString v ",") collect (s as float)
                "flSill": PR.flSill = for s in (filterString v ",") collect (s as float)
                "flBalc": PR.flBalc = for s in (filterString v ",") collect s
                "flBalcD": PR.flBalcD = for s in (filterString v ",") collect (s as float)
                "flBalcVar": PR.flBalcVar = for s in (filterString v ",") collect (s as float)
                "mixOut": PR.mixOut = v as float
                "mixIn": PR.mixIn = v as float
            )
        )
    )

    PR
)

/* =========================================================
   HELPER RACINE
========================================================= */

-- remonte la hiérarchie depuis n'importe quelle partie d'une façade jusqu'à sa racine
fn FR_FindRoot n =
(
    local r = n
    local found = undefined

    while r != undefined and found == undefined do
    (
        if (findString (getUserPropBuffer r) "FRAMER_PARAMS") != undefined then
            found = r
        else
            r = r.parent
    )

    found
)

fn FR_NewRoot basis =
(
    local rname = uniqueName "FRAMER_Facade_"
    local r = point name:rname cross:true box:false axistripod:true size:1.0 wirecolor:(color 255 140 0)

    r.transform = basis

    r
)

/* =========================================================
   MATÉRIAUX (réutilisés s'ils existent déjà dans la scène)
========================================================= */

-- apply:true -> met aussi à jour la couleur/l'opacité du matériau existant
fn FR_Material n c opacityVal apply:false =
(
    local res = undefined

    for m in sceneMaterials do
    (
        if m.name == n do res = m
    )

    if res == undefined then
        res = standardMaterial name:n diffuse:c opacity:opacityVal
    else if apply and (classof res) == StandardMaterial do
    (
        res.diffuse = c
        res.opacity = opacityVal
    )

    res
)

/* =========================================================
   GÉOMÉTRIE LOCALE
========================================================= */

fn FR_Box n center basis sx sy sz mat =
(
    if sx > 0.001 and sy > 0.001 and sz > 0.001 then
    (
        local b = box name:n width:sx length:sy height:sz mapCoords:true

        -- le pivot d'une box est au centre de sa base
        b.transform = matrix3 basis[1] basis[2] basis[3] (center - basis[3]*sz/2)
        b.material = mat

        append FR_Pool b

        b
    )
    else
    (
        undefined
    )
)

fn FR_LocalBox n u v w sx sy sz basis mat =
(
    local center = basis[4] + basis[1]*u + basis[2]*v + basis[3]*w

    FR_Box n center basis sx sy sz mat
)

-- dalle à arête avant BISEAUTÉE : chanfrein ch sur l'arête inférieure côté rue
-- (u1..u2 le long de la façade, vOut = côté rue, vIn = côté intérieur, z = dessous)
fn FR_ChamferSlab p u1 u2 vOut vIn z th basis mat ch =
(
    if ch > th*0.45 do ch = th*0.45
    if ch > (vIn - vOut)*0.45 do ch = (vIn - vOut)*0.45

    if ch < 0.004 then
        FR_LocalBox p ((u1+u2)/2) ((vOut+vIn)/2) (z+th/2) (u2-u1) (vIn-vOut) th basis mat
    else
    (
        -- profil trapézoïdal dans le plan (v,z) à u = u1, extrudé vers +u par FR_Prisma
        local pts = #(
            (FR_Pt basis u1 (vOut+ch) z),
            (FR_Pt basis u1 vIn z),
            (FR_Pt basis u1 vIn (z+th)),
            (FR_Pt basis u1 vOut (z+th)),
            (FR_Pt basis u1 vOut (z+ch))
        )

        FR_Prisma p pts mat (u2-u1)
    )
)

-- rectangle de mur entre u1..u2 et z1..z2, épaisseur t, sur le plan du mur
fn FR_WallRect n u1 u2 z1 z2 t basis mat =
(
    FR_LocalBox n ((u1+u2)/2) FR_VC ((z1+z2)/2) (u2-u1) t (z2-z1) basis mat
)

/* =========================================================
   CADRE  (depth = épaisseur du mur)
========================================================= */

fn FR_Frame prefix u1 u2 z1 z2 depth fw basis mat noBottom:false =
(
    local midU = (u1+u2)/2
    local midZ = (z1+z2)/2

    FR_LocalBox (prefix+"_Left") (u1+fw/2) FR_VC midZ fw depth (z2-z1) basis mat
    FR_LocalBox (prefix+"_Right") (u2-fw/2) FR_VC midZ fw depth (z2-z1) basis mat
    FR_LocalBox (prefix+"_Top") midU FR_VC (z2-fw/2) (u2-u1) depth fw basis mat

    -- barre basse optionnelle : supprimée au pied des vitrines d'arcades
    -- (le vitrage descend jusqu'au sol)
    if not noBottom do
        FR_LocalBox (prefix+"_Bottom") midU FR_VC (z1+fw/2) (u2-u1) depth fw basis mat
)

/* =========================================================
   ÉLÉMENT VITRÉ
========================================================= */

fn FR_Glass prefix u1 u2 z1 z2 depth fw basis frameMat glassMat mullions noBottom:false =
(
    local a = u1+fw
    local b = u2-fw
    local c = z1+fw
    local d = z2-fw

    -- sans barre basse : le vitrage et les montants descendent jusqu'en bas
    if noBottom do c = z1

    if b > a and d > c then
    (
        FR_LocalBox (prefix+"_Glass") ((a+b)/2) (FR_VC+depth*0.1) ((c+d)/2) (b-a) (depth*0.28) (d-c) basis glassMat

        FR_Frame prefix u1 u2 z1 z2 depth fw basis frameMat noBottom:noBottom

        if mullions > 0 then
        (
            for k = 1 to mullions do
            (
                local x = a+(b-a)*k/(mullions+1)

                FR_LocalBox (prefix+"_Mullion_"+(k as string)) x FR_VC ((c+d)/2) (fw*0.65) depth (d-c) basis frameMat
            )
        )
    )
)

/* =========================================================
   PANNEAU PLEIN
========================================================= */

fn FR_Panel prefix u1 u2 z1 z2 depth fw basis frameMat panelMat =
(
    FR_LocalBox (prefix+"_Panel") ((u1+u2)/2) (FR_VC+depth*0.1) ((z1+z2)/2) (u2-u1-fw*2) (depth*0.28) (z2-z1-fw*2) basis panelMat

    FR_Frame prefix u1 u2 z1 z2 depth fw basis frameMat
)

/* =========================================================
   OPTIONS DE FENÊTRE : garde-corps, volet roulant, casquette
   (appelées depuis FR_WallWindow, qui connaît la fenêtre)
========================================================= */

-- garde-corps devant l'allège : vitré, barreaudé ou plein, avec main courante
fn FR_WinRail p a b c T fw basis frameMat glassMat railK railH railD =
(
    local vF = FR_VC - T/2
    local rv = vF - railD/2
    local w = b - a

    if railK == "Glass" then
        FR_LocalBox (p+"_RailG") ((a+b)/2) rv (c+railH/2) w 0.03 railH basis glassMat
    else if railK == "Solid" then
        FR_LocalBox (p+"_RailP") ((a+b)/2) rv (c+railH/2) w 0.04 railH basis frameMat
    else if railK == "Bars" then
    (
        local nb = 1 + ((w/0.18) as integer)

        for k = 1 to nb do
            FR_LocalBox (p+"_Bar_"+(k as string)) (a + w*(k-0.5)/nb) rv (c+railH/2) 0.025 0.025 railH basis frameMat
    )

    -- lisse (main courante) toujours présente ; « Lisse » = garde-corps réduit à la seule lisse
    FR_LocalBox (p+"_RailHand") ((a+b)/2) rv (c+railH+0.025) w (railD+0.04) 0.05 basis frameMat

    if railK != "Lisse" do
        FR_LocalBox (p+"_RailFoot") ((a+b)/2) rv (c+0.015) w (railD+0.04) 0.03 basis frameMat
)

-- volet roulant simulé : coffre au-dessus de la fenêtre + panneau descendant du coffre
-- shutH = hauteur recouverte (0 = volet ouvert, winH = fermé)
fn FR_WinShutter p a b c winH T fw basis shutMat shutH =
(
    FR_LocalBox (p+"_ShutBox") ((a+b)/2) (FR_VC - T/2 + 0.02) (c+winH+0.07) (b-a+fw*0.6) (T*0.55) 0.14 basis shutMat

    if shutH > 0.02 do
        FR_LocalBox (p+"_Shut") ((a+b)/2) (FR_VC - T/2 - 0.025) (c+winH-shutH/2) (b-a+fw*0.6) 0.035 shutH basis shutMat
)

-- casquette (dalle en porte-à-faux) ou brise-soleil (lames horizontales) au-dessus de la fenêtre
fn FR_WinCanopy p a b zbase T fw basis frameMat capK capD =
(
    if capK == "Slab" then
        FR_ChamferSlab (p+"_Cap") (a-0.075) (b+0.075) (FR_VC - T/2 - capD) (FR_VC - T/2) zbase 0.08 basis frameMat 0.02
    else if capK == "Lam" then
    (
        for k = 0 to 4 do
            FR_LocalBox (p+"_Blade_"+(k as string)) ((a+b)/2) (FR_VC - T/2 - capD*0.4) (zbase+0.05+k*0.13) (b-a+0.1) (capD*0.8) 0.035 basis frameMat
    )
)

-- volet battant : un vantail pivoté autour de ses gonds verticales
-- deg = 0 (fermé, devant la fenêtre) à 180 (ouvert à plat contre le mur)
fn FR_ShutterLeaf p hx vF zbot lw th winH basis mat deg =
(
    local a = deg * 0.0174532925199433
    local du = cos a
    local dv = -(sin a)   -- la rotation passe par l'extérieur (v négatif = rue)

    local b = box name:p width:lw length:th height:winH mapCoords:true

    b.transform = matrix3 (basis[1]*du + basis[2]*dv) (basis[1]*(-dv) + basis[2]*du) basis[3] \
        (basis[4] + basis[1]*(hx + du*lw/2) + basis[2]*(vF + dv*lw/2) + basis[3]*zbot)
    b.material = mat

    append FR_Pool b

    b
)

-- paire de volets battants sur une fenêtre a..b, du sol c à c+winH
-- openPct : 0 = fermé (les deux vantaux couvrent la fenêtre), 100 = ouvert à plat contre le mur
fn FR_ShutterBattant p a b c winH T fw basis mat openPct =
(
    local vF = FR_VC - T/2 - 0.035   -- plan des gonds, devant le vitrage
    local lw = (b - a)/2 + 0.015
    local deg = amin #(amax #(openPct, 0.0), 100.0) * 1.8

    -- vantail gauche : gonds au bord gauche, fermé = s'étend vers la droite
    FR_ShutterLeaf (p+"_ShutL") a vF c lw 0.04 winH basis mat deg
    -- vantail droit : gonds au bord droit, fermé = s'étend vers la gauche
    FR_ShutterLeaf (p+"_ShutR") b vF c lw 0.04 winH basis mat (180.0 - deg)
)

/* =========================================================
   ENCADREMENT DE BAIE (moulure d'assemblage) : le profil est balayé autour
   de l'ouverture (a..b, c..d). prof = points 2D (x = largeur depuis la baie,
   y = saillie vers la rue), déjà mis à l'échelle. Réutilise FR_SweepMesh
   (onglets d'angle) en remappant les sommets vers le repère de la façade.
========================================================= */

fn FR_Surround nm a b c d basis mat prof =
(
    if prof != undefined and prof.count >= 2 then
    (
        -- chemin fermé autour de la baie, dans l'espace du sweep (x=u, y=z, z=rue)
        local pts = #([a, c, 0], [b, c, 0], [b, d, 0], [a, d, 0])
        local m = FR_SweepMesh pts prof true

        -- remappage : u = x, z = y, v (rue) = -z — rotation directe, winding conservé
        for i = 1 to (numverts m) do
        (
            local q = getVert m i
            setVert m i (basis[4] + basis[1]*q.x + basis[2]*(-q.z) + basis[3]*q.y)
        )

        update m

        m.name = nm
        m.material = mat

        append FR_Pool m

        m
    )
    else
        undefined
)

/* =========================================================
   MUR AVEC OUVERTURE CENTRÉE (trumeaux, allège, linteau + fenêtre)
   Options facultatives (mots-clés) : garde-corps, volet, casquette,
   encadrement de baie (surrProf + surrMat)
   Renvoie #(a, a+winW, c, c+winH) : rectangle de la fenêtre, ou undefined
========================================================= */

fn FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat winW winH sill railK:"None" railH:1.0 railD:0.15 shutOpen:-1.0 capK:"None" capD:0.4 surrProf:undefined surrMat:undefined arced:false =
(
    local bw = bu2-bu1
    local h = z2-z1

    -- on garde un linteau minimum au-dessus de la fenêtre
    if sill + winH > h - 0.1 do winH = h - sill - 0.1

    if winH < 0.3 or winW < 0.3 then
    (
        FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat

        undefined
    )
    else
    (
        local a = bu1 + (bw-winW)/2
        local c = z1 + sill

        -- baie cintrée : plein cintre (rise = demi-largeur), réduit en arc surbaissé
        -- si la fenêtre n'est pas assez haute
        local rise = 0.0
        local zsp = c

        if arced do
        (
            rise = amin #(winW*0.5, winH*0.5)

            if rise < 0.1 do rise = 0.1

            zsp = c + winH - rise
        )

        FR_WallRect (p+"_WallL") bu1 a z1 z2 T basis wallMat
        FR_WallRect (p+"_WallR") (a+winW) bu2 z1 z2 T basis wallMat
        FR_WallRect (p+"_Sill") a (a+winW) z1 c T basis wallMat

        if arced then
        (
            -- mur au-dessus de l'extrados + linteau droit au-dessus de la clé
            FR_ArchWall p a (a+winW) zsp rise (c+winH) T basis wallMat
            FR_WallRect (p+"_Lintel") a (a+winW) (c+winH) z2 T basis wallMat

            -- vitrage : partie rectangulaire (avec barre basse) + bande en arc
            -- (FR_ArchGlazing dessine les deux, de l'allège à la clé)
            FR_ArchGlazing (p+"_Arc") a (a+winW) zsp rise T fw basis frameMat glassMat zBase:c botBar:true
        )
        else
        (
            FR_WallRect (p+"_Lintel") a (a+winW) (c+winH) z2 T basis wallMat

            FR_Glass p a (a+winW) c (c+winH) T fw basis frameMat glassMat 1

            -- encadrement de baie (moulure d'assemblage balayée autour de l'ouverture)
            -- (pas d'encadrement rectangulaire autour d'une baie cintrée)
            if surrProf != undefined and surrMat != undefined do
                FR_Surround (p+"_Surr") a (a+winW) c (c+winH) basis surrMat surrProf
        )

        if railK != "None" and sill > 0.05 do
            FR_WinRail p a (a+winW) c T fw basis frameMat glassMat railK (amin #(railH, winH)) railD

        -- pas de volets roulants sur une baie cintrée (le coffre écraserait l'arc)
        if shutOpen >= 0.0 and not arced do
        (
            local shutH = winH * (1.0 - shutOpen/100.0)

            if shutH > winH do shutH = winH

            FR_WinShutter p a (a+winW) c winH T fw basis (FR_Material "FRAMER_Shutters" (color 172 166 152) 100) shutH
        )

        if capK != "None" do
        (
            local zb = c + winH

            -- la casquette passe au-dessus du coffre du volet
            if shutOpen >= 0.0 do zb = zb + 0.14

            FR_WinCanopy p a (a+winW) zb T fw basis frameMat capK capD
        )

        #(a, a+winW, c, c+winH)
    )
)

/* =========================================================
   BALCON SAILLANT (dalle + garde-corps vitré), sort devant les piliers
   proj = saillie au-delà des piliers
========================================================= */

fn FR_Balcony p bu1 bu2 z depth proj basis slabMat railMat glassMat railK:"Glass" slTh:0.30 =
(
    local outer = -depth - proj
    local inner = -depth*0.5
    local sy = inner - outer
    local cv = (inner+outer)/2
    local uc = (bu1+bu2)/2
    local bw = bu2-bu1

    -- dalle à arête avant biseautée, épaisseur réglable (0.6.9 : 30 cm par
    -- défaut comme en 0.6.7, 15 cm pour une dalle fine — réglage « Épaisseur
    -- des dalles » de l'onglet Étages)
    FR_ChamferSlab (p+"_Slab") bu1 bu2 outer inner (z - slTh/2) slTh basis slabMat 0.03

    -- garde-corps du balcon : suit le type choisi pour les garde-corps de fenêtres
    -- (« Aucun » garde le vitré par sécurité ; « Lisse » : seulement la main courante)
    local rk = if railK == "None" then "Glass" else railK

    if rk == "Glass" then
    (
        FR_LocalBox (p+"_Rail") uc (outer+0.02) (z+0.65) bw 0.03 1.0 basis glassMat
        FR_LocalBox (p+"_RailL") (bu1+0.015) cv (z+0.65) 0.03 sy 1.0 basis glassMat
        FR_LocalBox (p+"_RailR") (bu2-0.015) cv (z+0.65) 0.03 sy 1.0 basis glassMat
    )
    else if rk == "Solid" then
    (
        FR_LocalBox (p+"_RailP") uc (outer+0.02) (z+0.65) bw 0.04 1.0 basis railMat
        FR_LocalBox (p+"_RailL") (bu1+0.015) cv (z+0.65) 0.04 sy 1.0 basis railMat
        FR_LocalBox (p+"_RailR") (bu2-0.015) cv (z+0.65) 0.04 sy 1.0 basis railMat
    )
    else if rk == "Bars" then
    (
        local nb = 1 + ((bw/0.18) as integer)

        for k = 1 to nb do
            FR_LocalBox (p+"_Bar_"+(k as string)) (bu1 + bw*(k-0.5)/nb) (outer+0.02) (z+0.65) 0.025 0.025 1.0 basis railMat

        local ns = 1 + ((sy/0.18) as integer)

        for k = 1 to ns do
        (
            FR_LocalBox (p+"_BarL_"+(k as string)) (bu1+0.015) (outer + sy*(k-0.5)/ns) (z+0.65) 0.025 0.025 1.0 basis railMat
            FR_LocalBox (p+"_BarR_"+(k as string)) (bu2-0.015) (outer + sy*(k-0.5)/ns) (z+0.65) 0.025 0.025 1.0 basis railMat
        )
    )

    -- lisse haute (toujours)
    FR_LocalBox (p+"_RailTop") uc (outer+0.02) (z+1.17) bw 0.06 0.04 basis railMat
)

/* =========================================================
   BOW-WINDOW (oriel vitré en 3 facettes) sur toute la travée :
   dalle + capot + joues à 45° + face avant, tout vitré.
   bd = saillie au-delà des piliers (comme les balcons).
========================================================= */

fn FR_BowWindow p bu1 bu2 z1 z2 T depth bd fw basis wallMat frameMat glassMat simple:false =
(
    local bw = bu2 - bu1
    local inner = -depth*0.5      -- face avant du mur
    local outer = -depth - bd     -- saillie au-delà des piliers (comme les balcons)
    local run = inner - outer     -- profondeur horizontale des joues (POSITIVE :
                                  -- outer est plus négatif que inner, côté rue)

    -- joues à 45° : la face avant garde au moins 0,8 m de large
    if bw - 2.0*run < 0.8 do
    (
        run = (bw - 0.8)/2.0
        outer = inner - run
    )

    local uc = (bu1+bu2)/2
    local cv = (inner+outer)/2
    local cz1 = z1 + 0.12
    local cz2 = z2 - 0.12

    -- dalle et capot (capot légèrement débordant), arête avant biseautée
    FR_ChamferSlab (p+"_Slab") bu1 bu2 outer inner (z1+0.0) 0.15 basis wallMat 0.02
    FR_ChamferSlab (p+"_Cap") (bu1-0.04) (bu2+0.04) (outer-0.04) inner (cz2+0.0) 0.12 basis wallMat 0.02

    if simple then
    (
        -- 0.6.9 : bow-window SIMPLE (rectangulaire, sans joues à 45°) —
        -- une seule face avant vitrée pleine largeur, poteaux d'angle droits
        local bF = (matrix3 [1,0,0] [0,1,0] [0,0,1] [bu1, outer, 0]) * basis

        FR_Glass (p+"_BowF") 0.0 bw cz1 cz2 (T*0.8) fw bF frameMat glassMat 1

        FR_LocalBox (p+"_PostL") 0.0 FR_VC ((cz1+cz2)/2) (fw*1.6) (T*0.8) (cz2-cz1) bF frameMat
        FR_LocalBox (p+"_PostR") bw FR_VC ((cz1+cz2)/2) (fw*1.6) (T*0.8) (cz2-cz1) bF frameMat
    )
    else
    (
        local flen = run*1.41421      -- longueur d'une joue à 45°
        local fwid = bw - 2.0*run     -- largeur de la face avant
        local c45 = 0.70711

        -- bases locales des facettes (tournées, composées avec le repère de la façade)
        local bL = (matrix3 [c45,-c45,0] [c45,c45,0] [0,0,1] [bu1, inner, 0]) * basis
        local bF = (matrix3 [1,0,0] [0,1,0] [0,0,1] [bu1+run, outer, 0]) * basis
        local bR = (matrix3 [c45,c45,0] [-c45,c45,0] [0,0,1] [bu2-run, outer, 0]) * basis

        FR_Glass (p+"_BowL") 0.0 flen cz1 cz2 (T*0.8) fw bL frameMat glassMat 1
        FR_Glass (p+"_BowF") 0.0 fwid cz1 cz2 (T*0.8) fw bF frameMat glassMat 1
        FR_Glass (p+"_BowR") 0.0 flen cz1 cz2 (T*0.8) fw bR frameMat glassMat 1

        -- poteaux d'angle aux deux plis
        FR_LocalBox (p+"_PostL") flen FR_VC ((cz1+cz2)/2) (fw*1.6) (T*0.8) (cz2-cz1) bL frameMat
        FR_LocalBox (p+"_PostR") 0.0 FR_VC ((cz1+cz2)/2) (fw*1.6) (T*0.8) (cz2-cz1) bR frameMat
    )
)

/* =========================================================
   LOGGIA (balcon rentrant) : le mur de fond recule de R,
   avec joues latérales, sous-face, dalle et garde-corps dans le plan de façade
========================================================= */

fn FR_Loggia p bu1 bu2 z1 z2 T depth R fw basis wallMat frameMat glassMat slabMat =
(
    local vf = -depth*0.5       -- face avant du mur
    local cvv = vf + R/2
    local old = FR_VC
    local uc = (bu1+bu2)/2
    local bw = bu2-bu1
    local wW = bw*0.80
    local wH = amin #(2.3, (z2-z1-0.25))

    -- mur de fond reculé, avec porte-fenêtre
    FR_VC = vf + R + T/2
    FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat wW wH 0.0
    FR_VC = old

    -- joues latérales, sous-face et dalle
    FR_LocalBox (p+"_SideL") (bu1+0.06) cvv ((z1+z2)/2) 0.12 R (z2-z1) basis wallMat
    FR_LocalBox (p+"_SideR") (bu2-0.06) cvv ((z1+z2)/2) 0.12 R (z2-z1) basis wallMat
    FR_LocalBox (p+"_Soffit") uc cvv (z2-0.08) bw R 0.16 basis wallMat
    FR_LocalBox (p+"_Floor") uc cvv (z1+0.075) bw R 0.15 basis slabMat

    -- garde-corps dans le plan de la façade
    FR_LocalBox (p+"_Rail") uc (vf+0.02) (z1+0.65) bw 0.03 1.0 basis glassMat
    FR_LocalBox (p+"_RailTop") uc (vf+0.02) (z1+1.17) bw 0.06 0.04 basis frameMat
)

/* =========================================================
   TRAVÉE D'ENTRÉE (porte, vitrages latéraux, imposte, auvent)
========================================================= */

fn FR_Entrance p bu1 bu2 groundH T depth fw basis frameMat glassMat doorMat canopy doorH =
(
    local bw = bu2-bu1
    local dW = amin #(1.2, bw*0.4)
    -- toutes les portes ont la même hauteur (seule la largeur varie) :
    -- 2,05 m maison de ville, 3,00 m magasin / grand immeuble
    local dH = amin #(doorH, groundH-0.3)

    if dH < 1.9 do dH = 1.9
    local dl = (bu1+bu2)/2 - dW/2
    local dr = dl + dW

    FR_LocalBox (p+"_Door") ((dl+dr)/2) FR_VC (dH/2) dW (T*0.7) dH basis doorMat

    FR_Glass (p+"_SideL") bu1 dl 0 groundH T fw basis frameMat glassMat 0
    FR_Glass (p+"_SideR") dr bu2 0 groundH T fw basis frameMat glassMat 0
    FR_Glass (p+"_Transom") dl dr dH groundH T fw basis frameMat glassMat 0

    if canopy and (groundH - dH > 0.5) do
    (
        local outer = -depth - 0.8
        local inner = -depth*0.5

        FR_LocalBox (p+"_Canopy") ((dl+dr)/2) ((inner+outer)/2) (dH+0.08) (dW+0.8) (inner-outer) 0.1 basis frameMat
    )
)

/* =========================================================
   ARCADES (type Perret) : mur plein au-dessus d'une arche, vitrine reculée
========================================================= */

-- mur au-dessus d'une arche : une bande verticale par segment de l'arc, extrudée sur l'épaisseur du mur
fn FR_ArchWall p u1 u2 zsp rise ztop T basis mat =
(
    local w = u2 - u1
    local uc = (u1 + u2)/2
    local rad = (rise*rise + (w/2)*(w/2)) / (2.0*rise)
    local cy = zsp + rise - rad
    local segs = 16
    local vFr = FR_VC - T/2
    local vBk = FR_VC + T/2
    local vArr = #()
    local fArr = #()

    for i = 0 to segs do
    (
        local x = u1 + w*i/segs
        local dx = x - uc
        local q = rad*rad - dx*dx

        if q < 0.0 do q = 0.0

        local yy = cy + sqrt q

        -- 4 sommets par position : avant-bas, avant-haut, arrière-bas, arrière-haut
        append vArr (basis[4] + basis[1]*x + basis[2]*vFr + basis[3]*yy)
        append vArr (basis[4] + basis[1]*x + basis[2]*vFr + basis[3]*ztop)
        append vArr (basis[4] + basis[1]*x + basis[2]*vBk + basis[3]*yy)
        append vArr (basis[4] + basis[1]*x + basis[2]*vBk + basis[3]*ztop)
    )

    for i = 0 to segs-1 do
    (
        local a = 4*i
        local b = 4*(i+1)

        -- façade avant
        append fArr [a+1, b+1, b+2]
        append fArr [a+1, b+2, a+2]

        -- face arrière
        append fArr [a+3, b+4, b+3]
        append fArr [a+3, a+4, b+4]

        -- intrados (dessous de l'arche)
        append fArr [a+1, a+3, b+3]
        append fArr [a+1, b+3, b+1]

        -- dessus
        append fArr [a+2, b+4, a+4]
        append fArr [a+2, b+2, b+4]
    )

    local m = mesh vertices:vArr faces:fArr

    update m
    FR_NoSmooth m

    m.name = p + "_Arch"
    m.material = mat

    append FR_Pool m

    m
)

-- bande extrudée : entre deux courbes (ylo, yhi) le long de xs, sur l'épaisseur vF..vB
fn FR_StripMesh nm xs ylo yhi vF vB basis mat =
(
    local segs = xs.count - 1
    local vArr = #()
    local fArr = #()

    for i = 1 to xs.count do
    (
        -- 4 sommets par position : avant-bas, avant-haut, arrière-bas, arrière-haut
        append vArr (basis[4] + basis[1]*xs[i] + basis[2]*vF + basis[3]*ylo[i])
        append vArr (basis[4] + basis[1]*xs[i] + basis[2]*vF + basis[3]*yhi[i])
        append vArr (basis[4] + basis[1]*xs[i] + basis[2]*vB + basis[3]*ylo[i])
        append vArr (basis[4] + basis[1]*xs[i] + basis[2]*vB + basis[3]*yhi[i])
    )

    for i = 0 to segs-1 do
    (
        local a = 4*i
        local b = 4*(i+1)

        -- façade avant
        append fArr [a+1, b+1, b+2]
        append fArr [a+1, b+2, a+2]

        -- face arrière
        append fArr [a+3, b+4, b+3]
        append fArr [a+3, a+4, b+4]

        -- dessous
        append fArr [a+1, a+3, b+3]
        append fArr [a+1, b+3, b+1]

        -- dessus
        append fArr [a+2, b+4, a+4]
        append fArr [a+2, b+2, b+4]
    )

    local m = mesh vertices:vArr faces:fArr

    update m
    FR_NoSmooth m

    m.name = nm
    m.material = mat

    append FR_Pool m

    m
)

-- vitrage qui suit l'arche : partie basse rectangulaire construite EXACTEMENT comme une
-- vitrine du premier plan (FR_Glass), puis verre et cadre en arc au-dessus.
-- Les bandes en arc ne gardent que les positions où la courbe s'élève : plus aucune
-- station dégénérée aux naissances de l'arc.
fn FR_ArchGlazing p u1 u2 zsp rise T fw basis frameMat glassMat zBase:0.0 botBar:false =
(
    local w = u2 - u1
    local uc = (u1 + u2)/2
    local rad = (rise*rise + (w/2)*(w/2)) / (2.0*rise)
    local radIn = rad - fw
    local cy = zsp + rise - rad
    local segs = 16
    local xsG = #()
    local yGlass = #()
    local xsF = #()
    local yLoF = #()
    local yHiF = #()

    for i = 0 to segs do
    (
        local x = u1 + w*i/segs
        local dx = x - uc
        local q = rad*rad - dx*dx

        if q < 0.0 do q = 0.0

        local yo = cy + sqrt q
        local yi = zsp

        -- courbe intérieure du cadre : sur les côtés le cadre occupe toute la hauteur
        if radIn > 0.0 and (abs dx) < radIn do
        (
            yi = cy + sqrt (radIn*radIn - dx*dx)

            if yi < zsp do yi = zsp
        )

        -- verre en arc : seulement où la courbe intérieure s'élève au-dessus de la naissance
        if yi > zsp + 0.001 do
        (
            append xsG x
            append yGlass yi
        )

        -- cadre en arc : seulement où l'arc dépasse la naissance
        if yo > zsp + 0.001 do
        (
            append xsF x
            append yLoF yi
            append yHiF yo
        )
    )

    -- partie basse rectangulaire (arcades : sans barre basse, vitrage jusqu'au sol ;
    -- fenêtres cintrées : zBase = allège, avec barre basse)
    FR_Glass p u1 u2 zBase zsp T fw basis frameMat glassMat 1 noBottom:(not botBar)

    -- la bande du verre part d'une droite horizontale à la naissance de l'arc
    -- (tableau construit à part : un collecteur inline en argument déclenche un bug MAXScript)
    if xsG.count >= 2 do
    (
        local yBaseG = #()

        for k = 1 to xsG.count do append yBaseG zsp

        FR_StripMesh (p+"_ArchGlass") xsG yBaseG yGlass (FR_VC + T*0.1 - T*0.14) (FR_VC + T*0.1 + T*0.14) basis glassMat
    )

    if xsF.count >= 2 do
        FR_StripMesh (p+"_ArchFrame") xsF yLoF yHiF (FR_VC - T/2) (FR_VC + T/2) basis frameMat
)

-- une travée en arcade : mur au-dessus de l'ouverture + vitrine (ou entrée) reculée de "recess"
-- arcType : "Round" plein cintre, "Segment" arc surbaissé, "Flat" linteau droit (portique)
fn FR_Arcade p bu1 bu2 groundH T depth recess lintelH arcType fw basis frameMat glassMat doorMat wallMat isEnt glArch doorH =
(
    local bw = bu2 - bu1
    local vfa = -depth*0.5
    local crown = groundH - lintelH
    local zsp = crown
    local rise = 0.0

    if arcType == "Round" then
        rise = bw/2
    else if arcType == "Segment" then
        rise = bw*0.18

    if rise > 0.0 do
    (
        zsp = crown - rise

        -- pas assez de hauteur sous l'arc : on l'aplatit, sans jamais descendre sous 0
        if zsp < 2.2 do
        (
            zsp = 2.2
            rise = crown - zsp

            if rise < 0.0 do rise = 0.0
        )
    )

    if rise < 0.05 then
        FR_WallRect (p+"_Lintel") bu1 bu2 crown groundH T basis wallMat
    else
        FR_ArchWall p bu1 bu2 zsp rise groundH T basis wallMat

    -- vitrine reculée derrière l'arcade
    local oldVC = FR_VC

    FR_VC = vfa + recess + T/2

    if isEnt then
        FR_Entrance p bu1 bu2 crown T depth fw basis frameMat glassMat doorMat false doorH
    else if glArch and rise >= 0.05 then
        FR_ArchGlazing p bu1 bu2 zsp rise T fw basis frameMat glassMat
    else
        FR_Glass p bu1 bu2 0.0 crown T fw basis frameMat glassMat 1 noBottom:true

    -- fond de galerie : mur opaque juste derrière le vitrage reculé
    -- (bouche la vue à travers la galerie, arcades en arc comme portique)
    FR_VC = vfa + recess + T + 0.06

    FR_WallRect (p+"_Back") bu1 bu2 0.0 crown 0.1 basis wallMat

    -- plafond PLAT de la galerie, au niveau de la clé de l'arc (haut de
    -- l'ouverture) : l'arc reste lisible côté rue, la galerie garde toute
    -- la hauteur ; les retombées près des piliers descendent sous le
    -- plafond, comme sur une construction réelle
    if rise >= 0.05 do
        FR_LocalBox (p+"_Soffit") ((bu1+bu2)/2) ((vfa + recess + T + 0.06)/2) (crown + 0.05) (bu2-bu1) (vfa + recess + T + 0.06) 0.1 basis wallMat

    FR_VC = oldVC
)

/* =========================================================
   TOIT
========================================================= */

-- point local (u le long, v profondeur, z vertical) -> monde
fn FR_Pt basis u v z =
(
    basis[4] + basis[1]*u + basis[2]*v + basis[3]*z
)

-- prisme épais posé sur des points (3 ou 4) ordonnés anti-horaire vus depuis l'extérieur :
-- extrudé de "th" le long de sa normale
fn FR_Prisma p pts mat th =
(
    local n = pts.count
    local nrm = undefined

    if n >= 3 do
    (
        local cn = cross (pts[2]-pts[1]) (pts[n]-pts[1])

        if (length cn) > 0.000001 do nrm = normalize cn
    )

    if nrm != undefined and th > 0.001 then
    (
        local vArr = #()
        local fArr = #()

        for k = 1 to n do append vArr pts[k]

        for k = 1 to n do append vArr (pts[k] + nrm*th)

        -- dessous (normale inverse)
        for k = 1 to n-2 do append fArr [1, k+2, k+1]

        -- dessus
        for k = 1 to n-2 do append fArr [n+1, n+k+2, n+k+1]

        -- côtés
        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            append fArr [k, n+k2, n+k]
            append fArr [k, k2, n+k2]
        )

        local m = mesh vertices:vArr faces:fArr

        update m
        FR_NoSmooth m

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
    else
        undefined
)

-- toit-terrasse sur un rectangle (u 0..W, v 0..D dans le repère) : dalle + acrotère
-- toit-terrasse sur un rectangle — 0.6.16 : acrotère EN BAC, d'après la manip
-- utilisateur (extrude hauteur + inset épaisseur + extrude négative = gorge) :
-- une couronne PLEINE (épaisseur acrTh) dépasse de parH, le plateau intérieur
-- descend de acrGorge sous le sommet de l'acrotère. Plus de bandeau posé sur
-- une dalle fine : le bac est un solide unique.
fn FR_RoofFlatRect p basis W D z0 over parH mat acrTh:0.55 acrGorge:0.4 =
(
    local oW = W + over*2
    local oD = D + over*2

    if parH < 0.05 then
        FR_LocalBox (p+"_Slab") (W/2) (D/2) (z0 + 0.1) oW oD 0.2 basis mat
    else
    (
        -- épaisseur bornée pour que le polygone intérieur ne s'inverse pas
        local th = acrTh
        local maxTh = (amin #(oW, oD)) / 2.0 - 0.05
        if th > maxTh do th = maxTh

        -- contour extérieur du toit (le rectangle décalé du débord), anti-horaire
        local O = #(
            FR_Pt basis (-over) (-over) 0,
            FR_Pt basis (W + over) (-over) 0,
            FR_Pt basis (W + over) (D + over) 0,
            FR_Pt basis (-over) (D + over) 0
        )

        -- contour intérieur = décalage vers l'INTÉRIEUR de l'épaisseur d'acrotère
        local I = FR_OffsetContour O (-th)

        FR_RoofBac p O I z0 parH acrGorge mat
    )
)

-- toit à deux pentes sur un rectangle : faîtage au milieu de v, pignons aux extrémités u
-- couvre-joint (faîtage / arêtier) : petit profil balayé le long d'une
-- jonction entre deux versants — triangulaire (faîtage sec) ou arrondi
-- (tuile faîtière, demi-ellipse). A/B : extrémités MONDE de la ligne de
-- jonction ; w/h : largeur/hauteur du profil ; s : enfoncement (la base
-- descend sous la ligne pour rester en contact avec les versants, dont la
-- surface s'écarte de la jonction) ; rnd : profil arrondi sinon triangle.
-- NOTE : sin/cos MAXScript travaillent en DEGRÉS.
fn FR_RidgeCap p A B w h s rnd mat =
(
    local ex = B - A
    local len = length ex

    if len > 0.01 and w > 0.01 and h > 0.005 do
    (
        ex = normalize ex

        -- repère local : ey horizontal perpendiculaire au faîtage, ez « haut »
        local ey = normalize (cross [0,0,1] ex)
        local ez = normalize (cross ex ey)

        -- profil (largeur, hauteur), anti-horaire vu depuis +ex
        local prof = #()

        if rnd then
        (
            for k = 0 to 6 do
            (
                local a = k * 30.0
                append prof [(w/2) * cos a, (-s + h * sin a), 0]
            )
        )
        else
        (
            append prof [-(w/2), -s, 0]
            append prof [(w/2), -s, 0]
            append prof [0.0, h - s, 0]
        )

        local n = prof.count
        local vArr = #()
        local fArr = #()

        for k = 1 to n do append vArr (A + ey*prof[k].x + ez*prof[k].y)
        for k = 1 to n do append vArr (B + ey*prof[k].x + ez*prof[k].y)

        -- extrémités (éventails)
        for k = 1 to n-2 do append fArr [1, k+2, k+1]
        for k = 1 to n-2 do append fArr [n+1, n+k+2, n+k+1]

        -- côtés
        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            append fArr [k, n+k2, n+k]
            append fArr [k, k2, n+k2]
        )

        local m = mesh vertices:vArr faces:fArr

        update m
        FR_NoSmooth m

        m.name = p
        m.material = mat
        append FR_Pool m

        m
    )
)

fn FR_RoofGableRect p basis W D z0 pitch over matRoof matWall rk:"None" rw:0.18 rh:0.10 =
(
    local th = 0.12
    local u1 = -over
    local u2 = W + over
    local v1 = -over
    local v2 = D + over
    local vm = (v1 + v2)/2
    local h = ((v2 - v1)/2) * tan pitch

    if h > 0.05 do
    (
        -- versants (débordent sur les 4 côtés)
        FR_Prisma (p+"_Front") #((FR_Pt basis u1 v1 z0), (FR_Pt basis u2 v1 z0), (FR_Pt basis u2 vm (z0+h)), (FR_Pt basis u1 vm (z0+h))) matRoof th
        FR_Prisma (p+"_Back") #((FR_Pt basis u2 v2 z0), (FR_Pt basis u1 v2 z0), (FR_Pt basis u1 vm (z0+h)), (FR_Pt basis u2 vm (z0+h))) matRoof th

        -- pignons (murs triangulaires aux extrémités du bâtiment)
        FR_Prisma (p+"_GableL") #((FR_Pt basis 0.0 v1 z0), (FR_Pt basis 0.0 v2 z0), (FR_Pt basis 0.0 vm (z0+h))) matWall th
        FR_Prisma (p+"_GableR") #((FR_Pt basis W v1 z0), (FR_Pt basis W v2 z0), (FR_Pt basis W vm (z0+h))) matWall th

        -- couvre-joint : faîtage
        if rk != "None" do
            FR_RidgeCap (p+"_Ridge") (FR_Pt basis u1 vm (z0+h)) (FR_Pt basis u2 vm (z0+h)) rw rh ((rw/2)*tan pitch) (rk == "Round") matRoof
    )
)

-- toit à quatre pans sur un rectangle : faîtage raccourci (pentes égales des 4 côtés)
fn FR_RoofHipRect p basis W D z0 pitch over matRoof rk:"None" rw:0.18 rh:0.10 =
(
    local th = 0.12
    local u1 = -over
    local u2 = W + over
    local v1 = -over
    local v2 = D + over
    local vm = (v1 + v2)/2
    local h = ((v2 - v1)/2) * tan pitch
    local r1 = u1 + (v2 - v1)/2
    local r2 = u2 - (v2 - v1)/2

    if h > 0.05 and r2 > r1 do
    (
        FR_Prisma (p+"_Front") #((FR_Pt basis u1 v1 z0), (FR_Pt basis u2 v1 z0), (FR_Pt basis r2 vm (z0+h)), (FR_Pt basis r1 vm (z0+h))) matRoof th
        FR_Prisma (p+"_Back") #((FR_Pt basis u2 v2 z0), (FR_Pt basis u1 v2 z0), (FR_Pt basis r1 vm (z0+h)), (FR_Pt basis r2 vm (z0+h))) matRoof th
        FR_Prisma (p+"_HipL") #((FR_Pt basis u1 v2 z0), (FR_Pt basis u1 v1 z0), (FR_Pt basis r1 vm (z0+h))) matRoof th
        FR_Prisma (p+"_HipR") #((FR_Pt basis u2 v1 z0), (FR_Pt basis u2 v2 z0), (FR_Pt basis r2 vm (z0+h))) matRoof th

        -- couvre-joint : faîtage + 4 arêtiers (diagonales)
        if rk != "None" do
        (
            local s = (rw/2) * tan pitch

            FR_RidgeCap (p+"_Ridge") (FR_Pt basis r1 vm (z0+h)) (FR_Pt basis r2 vm (z0+h)) rw rh s (rk == "Round") matRoof
            FR_RidgeCap (p+"_HipFL") (FR_Pt basis u1 v1 z0) (FR_Pt basis r1 vm (z0+h)) rw rh s (rk == "Round") matRoof
            FR_RidgeCap (p+"_HipFR") (FR_Pt basis u2 v1 z0) (FR_Pt basis r2 vm (z0+h)) rw rh s (rk == "Round") matRoof
            FR_RidgeCap (p+"_HipBL") (FR_Pt basis u1 v2 z0) (FR_Pt basis r1 vm (z0+h)) rw rh s (rk == "Round") matRoof
            FR_RidgeCap (p+"_HipBR") (FR_Pt basis u2 v2 z0) (FR_Pt basis r2 vm (z0+h)) rw rh s (rk == "Round") matRoof
        )
    )
)

-- toit MANSARDE sur un rectangle : brisis raide (pente réglée = roofPitch),
-- terrasson doux (mansP2), plate-forme PLANE au sommet (mansTop de large)
-- + acrotère (roofPar) — les 4 côtés ont la même course horizontale, la
-- plate-forme reste un rectangle (comme un toit à quatre pans à double
-- rupture de pente)
-- LUCARNES DU MANSARD (0.6.17) — géométrie solide, sans booléens, dans les
-- règles de l'art : chevet vertical (mur + baie vitrée), joues noyées dans le
-- brisis, toiture de la lucarne mourant dans la pente (le faîtage horizontal
-- disparaît dans le brisis là où la pente atteint sa hauteur).
-- Coordonnées en repère basis (u = façade, v = vers l'arrière, z = haut) ;
-- le brisis avant monte selon z(u,v) = zF + (v - vF) * tanP.
fn FR_Lucarne p basis uC vF zF tanP lucW lucH style matWall matRoof matGlass =
(
    local hw = lucW / 2.0
    local emb = 0.15
    local ovh = 0.06

    local uL = uC - hw
    local uR = uC + hw

    local zB = zF - emb
    local zT = zF + lucH
    local rh = amax #(0.2, lucW * 0.35)
    local zR = zT + rh

    -- le toit de la lucarne s'enfonce dans le brisis : v où la pente atteint le faîtage
    local dvE = (lucH + rh) / tanP + 0.15
    local vE = vF + dvE

    -- trois mailles : chevet (mur), joues + toiture (zinc), vitrage
    local vW = #() ; local fW = #()
    local vR = #() ; local fR = #()
    local vG = #() ; local fG = #()

    /* --- chevet (façade de la lucarne, normale vers la rue) --- */
    local cp = #()

    append cp [uL, zB, 0]
    append cp [uR, zB, 0]
    append cp [uR, zT, 0]

    if style == "Capucine" then
    (
        -- arc au-dessus du chevet (demi-ellipse, comme le couvre-joint arrondi)
        for k = 5 to 1 by -1 do
        (
            local a = 180.0 - k * 30.0
            append cp [uC + hw * (cos a), zT + rh * (sin a), 0]
        )
    )
    else
        append cp [uC, zR, 0]

    append cp [uL, zT, 0]

    local nc = cp.count

    for q in cp do append vW (basis[4] + basis[1]*q.x + basis[2]*vF + basis[3]*q.y)

    for k = 2 to nc - 1 do
        append fW #(1, k, k + 1)

    /* --- joues (murs latéraux, noyées dans le brisis) + toiture --- */
    local zBvE = zF + dvE * tanP - emb

    for su in #(uL, uR) do
    (
        local sBase = vR.count

        append vR (basis[4] + basis[1]*su + basis[2]*vF + basis[3]*zB)
        append vR (basis[4] + basis[1]*su + basis[2]*vE + basis[3]*zBvE)
        append vR (basis[4] + basis[1]*su + basis[2]*vE + basis[3]*zT)
        append vR (basis[4] + basis[1]*su + basis[2]*vF + basis[3]*zT)

        -- la joue gauche sort vers -u, la droite vers +u : winding opposé
        if su == uL then
        (
            append fR #(sBase + 1, sBase + 2, sBase + 3)
            append fR #(sBase + 1, sBase + 3, sBase + 4)
        )
        else
        (
            append fR #(sBase + 1, sBase + 3, sBase + 2)
            append fR #(sBase + 1, sBase + 4, sBase + 3)
        )
    )

    if style == "Capucine" then
    (
        -- profil en arc balayé de vF-ovh à vE
        local nA = 7
        local rArc = amax #(0.2, (lucW + ovh*2) * 0.35)
        local hwA = (lucW + ovh*2) / 2.0
        local s0 = vR.count

        for k = 0 to nA - 1 do
        (
            local a = 180.0 - k * (180.0 / (nA - 1))
            append vR (basis[4] + basis[1]*(uC + hwA * (cos a)) + basis[2]*(vF - ovh) + basis[3]*(zT + rArc * (sin a)))
        )

        for k = 0 to nA - 1 do
        (
            local a = 180.0 - k * (180.0 / (nA - 1))
            append vR (basis[4] + basis[1]*(uC + hwA * (cos a)) + basis[2]*vE + basis[3]*(zT + rArc * (sin a)))
        )

        for k = 1 to nA - 1 do
        (
            append fR #(s0 + k, s0 + k + 1, s0 + nA + k + 1)
            append fR #(s0 + k, s0 + nA + k + 1, s0 + nA + k)
        )
    )
    else
    (
        -- deux versants rectilignes (fronton / rectangulaire)
        local uL2 = uL - ovh
        local uR2 = uR + ovh
        local vF2 = vF - ovh

        local r1s = vR.count

        append vR (basis[4] + basis[1]*uL2 + basis[2]*vF2 + basis[3]*zT)
        append vR (basis[4] + basis[1]*uC + basis[2]*vF2 + basis[3]*zR)
        append vR (basis[4] + basis[1]*uC + basis[2]*vE + basis[3]*zR)
        append vR (basis[4] + basis[1]*uL2 + basis[2]*vE + basis[3]*zT)

        append fR #(r1s + 1, r1s + 2, r1s + 3)
        append fR #(r1s + 1, r1s + 3, r1s + 4)

        local r2s = vR.count

        append vR (basis[4] + basis[1]*uC + basis[2]*vF2 + basis[3]*zR)
        append vR (basis[4] + basis[1]*uR2 + basis[2]*vF2 + basis[3]*zT)
        append vR (basis[4] + basis[1]*uR2 + basis[2]*vE + basis[3]*zT)
        append vR (basis[4] + basis[1]*uC + basis[2]*vE + basis[3]*zR)

        append fR #(r2s + 1, r2s + 2, r2s + 3)
        append fR #(r2s + 1, r2s + 3, r2s + 4)
    )

    /* --- baie vitrée (en retrait derrière le chevet) --- */
    if matGlass != undefined and lucW > 0.6 do
    (
        local gu1 = uL + 0.15
        local gu2 = uR - 0.15
        local gz1 = zB + 0.35
        local gz2 = zT - 0.12
        local gv = vF + 0.03

        append vG (basis[4] + basis[1]*gu1 + basis[2]*gv + basis[3]*gz1)
        append vG (basis[4] + basis[1]*gu2 + basis[2]*gv + basis[3]*gz1)
        append vG (basis[4] + basis[1]*gu2 + basis[2]*gv + basis[3]*gz2)
        append vG (basis[4] + basis[1]*gu1 + basis[2]*gv + basis[3]*gz2)

        append fG #(1, 2, 3)
        append fG #(1, 3, 4)
    )

    -- création des mailles
    if fW.count > 0 do
    (
        local m = mesh vertices:vW faces:fW
        update m
        FR_NoSmooth m
        m.name = p
        m.material = matWall
        append FR_Pool m
    )

    if fR.count > 0 do
    (
        local m = mesh vertices:vR faces:fR
        update m
        FR_NoSmooth m
        m.name = p + "_R"
        m.material = matRoof
        append FR_Pool m
    )

    if fG.count > 0 do
    (
        local m = mesh vertices:vG faces:fG
        update m
        FR_NoSmooth m
        m.name = p + "_V"
        m.material = matGlass
        append FR_Pool m
    )

    -- fronton : cornice en bandeau sous le pignon
    if style == "Fronton" do
        FR_LocalBox (p+"_Fr") uC (vF - 0.01) zT (lucW + 0.12) 0.07 0.09 basis matRoof
)

-- rangée de lucarnes régulièrement espacées sur un brisis (avant, côté rue)
fn FR_LucarneRow p basis u1 u2 v1 z0 tanP lucW lucH lucStep mode matWall matRoof matGlass =
(
    if lucW > 0.4 and lucH > 0.4 and lucStep > 0.5 and tanP > 0.05 do
    (
        local uStart = u1 + lucW/2 + 0.3
        local uEnd = u2 - lucW/2 - 0.3

        if uEnd > uStart do
        (
            local n = 1 + (((uEnd - uStart) / lucStep) as integer)
            local mid = (u1 + u2) / 2.0
            local first = mid - (n - 1) * lucStep / 2.0

            -- plan avant : un peu au-dessus de l'égout du brisis
            local vF = v1 + 0.30
            local zF = z0 + 0.30 * tanP

            for i = 1 to n do
            (
                local uC = first + (i - 1) * lucStep
                local style = mode

                -- alterné : une à toit en pente (fronton), une à toit arrondi (capucine)
                if mode == "Alterné" do style = (if mod i 2 == 1 then "Fronton" else "Capucine")

                FR_Lucarne (p + "_Luc" + (i as string)) basis uC vF zF tanP lucW lucH style matWall matRoof matGlass
            )
        )
    )
)

fn FR_RoofMansardRect p basis W D z0 pitch p2 over topW parH matRoof rk:"None" rw:0.18 rh:0.10 luc:"None" lw:1.0 lh:1.2 lst:3.0 lucWall:undefined lucGlass:undefined =
(
    local th = 0.12
    local u1 = -over
    local u2 = W + over
    local v1 = -over
    local v2 = D + over

    -- course horizontale totale des deux pentes (brisis + terrasson)
    local runT = amax #(0.2, (((amin #(u2-u1, v2-v1)) - topW)/2.0))

    -- répartition brisis / terrasson : le brisis raide couvre moins de course
    local r1 = runT*0.45
    local r2 = runT - r1

    local h1 = r1 * tan pitch
    local h2 = h1 + r2 * tan p2

    if h1 > 0.05 do
    (
        -- brisis (pente basse raide) : bande en tronc de pyramide, 4 côtés
        FR_Prisma (p+"_BrF") #((FR_Pt basis u1 v1 z0), (FR_Pt basis u2 v1 z0), (FR_Pt basis (u2-r1) (v1+r1) (z0+h1)), (FR_Pt basis (u1+r1) (v1+r1) (z0+h1))) matRoof th
        FR_Prisma (p+"_BrB") #((FR_Pt basis u2 v2 z0), (FR_Pt basis u1 v2 z0), (FR_Pt basis (u1+r1) (v2-r1) (z0+h1)), (FR_Pt basis (u2-r1) (v2-r1) (z0+h1))) matRoof th
        FR_Prisma (p+"_BrL") #((FR_Pt basis u1 v2 z0), (FR_Pt basis u1 v1 z0), (FR_Pt basis (u1+r1) (v1+r1) (z0+h1)), (FR_Pt basis (u1+r1) (v2-r1) (z0+h1))) matRoof th
        FR_Prisma (p+"_BrR") #((FR_Pt basis u2 v1 z0), (FR_Pt basis u2 v2 z0), (FR_Pt basis (u2-r1) (v2-r1) (z0+h1)), (FR_Pt basis (u2-r1) (v1+r1) (z0+h1))) matRoof th

        -- terrasson (pente haute douce) : du brisis au bord de la plate-forme
        local t1 = r1 + r2

        FR_Prisma (p+"_TeF") #((FR_Pt basis (u1+r1) (v1+r1) (z0+h1)), (FR_Pt basis (u2-r1) (v1+r1) (z0+h1)), (FR_Pt basis (u2-t1) (v1+t1) (z0+h2)), (FR_Pt basis (u1+t1) (v1+t1) (z0+h2))) matRoof th
        FR_Prisma (p+"_TeB") #((FR_Pt basis (u2-r1) (v2-r1) (z0+h1)), (FR_Pt basis (u1+r1) (v2-r1) (z0+h1)), (FR_Pt basis (u1+t1) (v2-t1) (z0+h2)), (FR_Pt basis (u2-t1) (v2-t1) (z0+h2))) matRoof th
        FR_Prisma (p+"_TeL") #((FR_Pt basis (u1+r1) (v2-r1) (z0+h1)), (FR_Pt basis (u1+r1) (v1+r1) (z0+h1)), (FR_Pt basis (u1+t1) (v1+t1) (z0+h2)), (FR_Pt basis (u1+t1) (v2-t1) (z0+h2))) matRoof th
        FR_Prisma (p+"_TeR") #((FR_Pt basis (u2-r1) (v1+r1) (z0+h1)), (FR_Pt basis (u2-r1) (v2-r1) (z0+h1)), (FR_Pt basis (u2-t1) (v2-t1) (z0+h2)), (FR_Pt basis (u2-t1) (v1+t1) (z0+h2))) matRoof th

        -- lucarnes du brisis (côté rue uniquement) : 0.6.17
        if luc != "None" and lucWall != undefined do
            FR_LucarneRow (p+"_Luc") basis (u1+r1) (u2-r1) v1 z0 (tan pitch) lw lh lst luc lucWall matRoof lucGlass

        -- plate-forme plane au sommet + acrotère (comme le toit-terrasse)
        local fz0 = z0 + h2
        local fu1 = u1 + t1
        local fu2 = u2 - t1
        local fv1 = v1 + t1
        local fv2 = v2 - t1

        if fu2 > fu1 and fv2 > fv1 do
        (
            FR_LocalBox (p+"_Top") ((fu1+fu2)/2) ((fv1+fv2)/2) (fz0+0.1) (fu2-fu1) (fv2-fv1) 0.2 basis matRoof

            if parH > 0.05 do
            (
                FR_LocalBox (p+"_ParF") ((fu1+fu2)/2) (fv1+0.075) (fz0+parH/2) (fu2-fu1) 0.15 parH basis matRoof
                FR_LocalBox (p+"_ParB") ((fu1+fu2)/2) (fv2-0.075) (fz0+parH/2) (fu2-fu1) 0.15 parH basis matRoof
                FR_LocalBox (p+"_ParL") (fu1+0.075) ((fv1+fv2)/2) (fz0+parH/2) 0.15 (fv2-fv1) parH basis matRoof
                FR_LocalBox (p+"_ParR") (fu2-0.075) ((fv1+fv2)/2) (fz0+parH/2) 0.15 (fv2-fv1) parH basis matRoof
            )

            -- couvre-joint : les 4 arêtes du plateau (jonction terrasson/plateau)
            if rk != "None" do
            (
                local s = (rw/2) * tan p2

                FR_RidgeCap (p+"_CvF") (FR_Pt basis fu1 fv1 (fz0+0.2)) (FR_Pt basis fu2 fv1 (fz0+0.2)) rw rh s (rk == "Round") matRoof
                FR_RidgeCap (p+"_CvB") (FR_Pt basis fu1 fv2 (fz0+0.2)) (FR_Pt basis fu2 fv2 (fz0+0.2)) rw rh s (rk == "Round") matRoof
                FR_RidgeCap (p+"_CvL") (FR_Pt basis fu1 fv1 (fz0+0.2)) (FR_Pt basis fu1 fv2 (fz0+0.2)) rw rh s (rk == "Round") matRoof
                FR_RidgeCap (p+"_CvR") (FR_Pt basis fu2 fv1 (fz0+0.2)) (FR_Pt basis fu2 fv2 (fz0+0.2)) rw rh s (rk == "Round") matRoof
            )
        )
    )
)

-- point strictement dans le triangle abc (test par les signes, plan XY)
fn FR_InTri p a b c =
(
    local d1 = cross (b-a) (p-a)
    local d2 = cross (c-b) (p-b)
    local d3 = cross (a-c) (p-c)

    ((d1.z >= 0.0) and (d2.z >= 0.0) and (d3.z >= 0.0)) or ((d1.z <= 0.0) and (d2.z <= 0.0) and (d3.z <= 0.0))
)

-- aire signée d'un polygone planaire XY (formule du lacet).
-- > 0 : sommets anti-horaires ; < 0 : horaires. 0 : plat ou dégénéré.
fn FR_PolyArea pts =
(
    local a = 0.0
    local n = pts.count

    if n >= 3 do
    (
        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            a += pts[k].x * pts[k2].y - pts[k2].x * pts[k].y
        )

        a /= 2.0
    )

    a
)

-- renvoie une COPIE du polygone en ordre ANTI-HORAIRE (inversée si nécessaire).
-- 0.6.15 : un contour dessiné (ou stocké) dans le sens HORAIRE faisait échouer
-- la détection d'oreilles (cross z > 0 jamais vrai) et basculait dans le repli
-- « clipping forcé » -> triangles en vrille = dalle géante inclinée hors du bâtiment.
fn FR_PolyCCW pts =
(
    local out = #()

    if (FR_PolyArea pts) < 0.0 then
        for k = pts.count to 1 by -1 do append out pts[k]
    else
        for k = 1 to pts.count do append out pts[k]

    out
)

-- triangulation d'un polygone planaire (découpe d'oreilles, contour anti-horaire)
-- 0.6.8 : l'oreille est le sommet DU MILIEU b -> on supprime b (avant : supprimait a,
-- d'où chevauchements puis blocage sur un résidu horaire = TROU au milieu de la dalle)
-- 0.6.15 : l'orientation est normalisée ici (FR_PolyCCW), le sens de parcours du
-- contour n'a plus d'influence sur le résultat.
fn FR_Triangulate pts =
(
    local tris = #()

    pts = FR_PolyCCW pts

    if pts.count >= 3 do
    (
        local rest = for k = 1 to pts.count collect k
        local stuck = false
        local guard = 0

        while rest.count > 2 and guard < 2000 and not stuck do
        (
            guard = guard + 1
            local clipped = false

            for k = 1 to rest.count while not clipped do
            (
                local k2 = k + 1
                if k2 > rest.count do k2 = 1

                local k3 = k2 + 1
                if k3 > rest.count do k3 = 1

                local a = rest[k]
                local b = rest[k2]
                local c = rest[k3]

                -- une oreille est un sommet convexe (cross z > 0 en anti-horaire)
                if (cross (pts[b]-pts[a]) (pts[c]-pts[b])).z > 0.000001 do
                (
                    local empty = true

                    for m in rest while empty do
                    (
                        if m != a and m != b and m != c and (FR_InTri pts[m] pts[a] pts[b] pts[c]) do empty = false
                    )

                    if empty do
                    (
                        append tris #(a, b, c)
                        deleteItem rest k2
                        clipped = true
                    )
                )
            )

            if not clipped do
            (
                -- 0.6.8 : ne plus abandonner (trou dans la dalle) —
                -- résidu à 3 sommets : dernier triangle quelle que soit son orientation
                if rest.count == 3 then
                (
                    append tris #(rest[1], rest[2], rest[3])
                    stuck = true
                )
                else
                (
                    -- 0.6.15 : avant le clipping forcé, on retente une oreille avec un
                    -- test ASSOULI (sommets presque plats acceptés, cross z >= -1e-6)
                    -- et la contenance vérifiée — sur un polygone décalé auto-intersecté,
                    -- le clipping aveugle produisait des triangles en vrille.
                    local relaxed = false

                    for k = 1 to rest.count while not relaxed do
                    (
                        local k2 = k + 1
                        if k2 > rest.count do k2 = 1

                        local k3 = k2 + 1
                        if k3 > rest.count do k3 = 1

                        local a = rest[k]
                        local b = rest[k2]
                        local c = rest[k3]

                        if (cross (pts[b]-pts[a]) (pts[c]-pts[b])).z >= -0.000001 do
                        (
                            local empty = true

                            for m in rest while empty do
                            (
                                if m != a and m != b and m != c and (FR_InTri pts[m] pts[a] pts[b] pts[c]) do empty = false
                            )

                            if empty do
                            (
                                append tris #(a, b, c)
                                deleteItem rest k2
                                relaxed = true
                            )
                        )
                    )

                    -- sinon : clipping forcé du sommet au cross le plus convexe,
                    -- pour garantir la terminaison et la couverture complète
                    if not relaxed do
                    (
                    local bestC = -1.0
                    local bestK = 1

                    for k = 1 to rest.count do
                    (
                        local k2 = k + 1
                        if k2 > rest.count do k2 = 1
                        local k3 = k2 + 1
                        if k3 > rest.count do k3 = 1
                        local cz = (cross (pts[rest[k2]]-pts[rest[k]]) (pts[rest[k3]]-pts[rest[k2]])).z
                        if cz > bestC do
                        (
                            bestC = cz
                            bestK = k2
                        )
                    )

                    local a2 = rest[bestK-1]
                    if bestK-1 < 1 do a2 = rest[rest.count]
                    local b2 = rest[bestK]
                    local c2 = rest[bestK+1]
                    if bestK+1 > rest.count do c2 = rest[1]

                    append tris #(a2, b2, c2)
                    deleteItem rest bestK
                    )
                )
            )
        )
    )

    tris
)

-- dalle de la terrasse sur le contour : polygone triangulé (dessus, dessous, tranche)
-- 0.6.15 : orientation normalisée (FR_PolyCCW) + garde-fou : un triangle plus grand
-- que le polygone lui-même est impossible dans une triangulation valide -> il vient
-- d'un repli sur polygone décalé auto-intersecté, on le SAUTE (trou local préférable
-- à la dalle géante inclinée hors du bâtiment).
fn FR_RoofSlabContour p pts z0 th mat =
(
    pts = FR_PolyCCW pts

    local tris = FR_Triangulate pts

    local totA = abs (FR_PolyArea pts)

    if tris.count > 0 do
    (
        local n = pts.count
        local vArr = #()
        local fArr = #()

        for k = 1 to n do
        (
            append vArr [pts[k].x, pts[k].y, z0]
            append vArr [pts[k].x, pts[k].y, z0 + th]
        )

        for t in tris do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            -- garde-fou triangulation : aire du triangle vs aire du polygone
            local tA = abs ((pts[b].x - pts[a].x) * (pts[c].y - pts[a].y) - (pts[c].x - pts[a].x) * (pts[b].y - pts[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 do
            (
                append fArr [a, c, b]
                append fArr [a+n, b+n, c+n]
            )
        )

        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            append fArr [k, k2, k2+n]
            append fArr [k, k2+n, k+n]
        )

        local m = mesh vertices:vArr faces:fArr

        update m
        FR_NoSmooth m

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
)

-- les deux segments 2D p1p2 et p3p4 se croisent-ils PROPREMENT (intersection
-- stricte, tangements ignorés) ? Test par les orientations relatives.
fn FR_Cross2 a b = (a.x * b.y - a.y * b.x)

fn FR_SegX p1 p2 p3 p4 =
(
    local d1 = FR_Cross2 (p2 - p1) (p3 - p1)
    local d2 = FR_Cross2 (p2 - p1) (p4 - p1)
    local d3 = FR_Cross2 (p4 - p3) (p1 - p3)
    local d4 = FR_Cross2 (p4 - p3) (p2 - p3)

    ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))
)

-- un polygone fermé est-il SIMPLE (aucune auto-intersection d'arêtes non adjacentes) ?
fn FR_PolySimple pts =
(
    local n = pts.count
    local ok = true

    if n >= 4 do
    (
        for i = 1 to n while ok do
        (
            local i2 = i + 1
            if i2 > n do i2 = 1

            for j = i + 1 to n while ok do
            (
                local j2 = j + 1
                if j2 > n do j2 = 1

                -- les arêtes adjacentes (qui partagent un sommet) sont ignorées
                local adj = (j == i2) or (i == 1 and j == n)

                if not adj and (FR_SegX pts[i] pts[i2] pts[j] pts[j2]) do ok = false
            )
        )
    )

    ok
)

-- décalage brut d'un contour fermé (mitre aux sommets, bridée pour les angles
-- très aigus à ~3x le décalage). SANS validation — voir FR_OffsetContour.
fn FR_OffsetMitre pts d =
(
    pts = FR_PolyCCW pts

    local n = pts.count
    local out = #()

    for k = 1 to n do
    (
        local kp = k - 1
        if kp < 1 do kp = n

        local kn = k + 1
        if kn > n do kn = 1

        local dP = pts[k] - pts[kp]
        dP.z = 0.0

        local dN = pts[kn] - pts[k]
        dN.z = 0.0

        -- normale extérieure d'un segment : rotation de 90° vers la droite
        local nP = [0,0,0]
        local nN = [0,0,0]

        if (length dP) > 0.000001 do nP = normalize [dP.y, -dP.x, 0]
        if (length dN) > 0.000001 do nN = normalize [dN.y, -dN.x, 0]

        local bis = nP + nN
        local oPts

        if (length bis) < 0.001 then
            oPts = nN * d
        else
        (
            bis = normalize bis

            local c = dot bis nN

            if c < 0.3 do c = 0.3

            oPts = bis * (d / c)
        )

        append out (pts[k] + oPts)
    )

    out
)

-- supprime les sommets confondus (arêtes de longueur < 1 mm) introduits par
-- le décalage sur un contour étroit — ils font échouer la triangulation
fn FR_DedupPts pts =
(
    local out = #()

    for q in pts do
    (
        if out.count == 0 or (length (q - out[out.count])) > 0.001 do append out q
    )

    if out.count > 1 and (length (out[1] - out[out.count])) <= 0.001 do deleteItem out out.count

    out
)

-- décalage VALIDÉ d'un contour fermé (0.6.18) : d positif = vers l'EXTÉRIEUR
-- (contour anti-horaire : l'extérieur est à droite), d négatif = vers l'intérieur.
-- Sur un contour concave (forme en L) ou étroit, la mitre peut s'AUTO-INTERSECTER
-- (spikes qui se replient) — c'est ce qui produisait les triangles en vrille du
-- toit. Le résultat est donc vérifié (polygone simple + aire cohérente) et en
-- cas d'échec le décalage est réduit de moitié, plusieurs fois si nécessaire.
fn FR_OffsetContour pts d =
(
    pts = FR_PolyCCW pts

    local out = FR_OffsetMitre pts d
    local dd = d
    local nTry = 0

    -- valide = simple, et pour un décalage intérieur l'aire reste positive
    -- (un décalage trop fort inverse le polygone)
    -- NOTE : compteur nommé nTry — « try » est un mot réservé MAXScript
    while nTry < 4 and not ((FR_PolySimple out) and (dd >= 0.0 or (FR_PolyArea out) > 0.0)) do
    (
        nTry = nTry + 1
        dd /= 2.0
        out = FR_OffsetMitre pts dd
    )

    -- dernier recours : ne pas décaler du tout (mieux vaut un toit sans débord
    -- ou sans gorge qu'un toit en vrille)
    -- NOTE : branches en `then` — un `if ... do` ne peut PAS être suivi d'un
    -- `else` en MAXScript (erreur « à else, attendu <facteur> »)
    if not (FR_PolySimple out) then
    (
        FR_Msg ("Décalage du toit impossible (contour trop étroit) : débord réduit à 0.")
        out = pts
    )
    else if nTry > 0 do
        FR_Msg ("Décalage du toit réduit à " + ((abs dd) as string) + " m (contour trop étroit pour la valeur demandée).")

    FR_DedupPts out
)

-- terrasse « EN BAC » (0.6.16, d'après la manip utilisateur extrude + inset +
-- extrude négative) : O = polygone extérieur (contour décalé du débord),
-- I = polygone intérieur (O décalé vers l'INTÉRIEUR de l'épaisseur d'acrotère,
-- même nombre de sommets). Solide unique : couronne pleine de z0 à z0+pT
-- (l'acrotère), plateau intérieur enfoncé — fond de la gorge à z0+pT-gorge —,
-- dessous fermé vu de dessous. O et I doivent être anti-horaires.
fn FR_RoofBac p O I z0 pT gorge mat =
(
    local n = O.count

    if n >= 3 and I.count == n and pT > 0.05 do
    (
        -- la gorge ne peut pas descendre sous le dessous du bac
        if gorge > pT - 0.05 do gorge = pT - 0.05

        local zTop = z0 + pT
        local zFlr = z0 + (pT - gorge)

        local vArr = #()
        local fArr = #()

        -- 1..n : dessous extérieur ; n+1..2n : couronne extérieure (sommet) ;
        -- 2n+1..3n : couronne intérieure (sommet) ; 3n+1..4n : fond de la gorge
        for k = 1 to n do
        (
            append vArr [O[k].x, O[k].y, z0]
            append vArr [O[k].x, O[k].y, zTop]
            append vArr [I[k].x, I[k].y, zTop]
            append vArr [I[k].x, I[k].y, zFlr]
        )

        local totA = abs (FR_PolyArea O)

        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            -- paroi extérieure (normales vers l'extérieur)
            append fArr [k, k2, k2+n]
            append fArr [k, k2+n, k+n]

            -- couronne supérieure (normales vers le haut)
            append fArr [k+n, k2+n, k2+2*n]
            append fArr [k+n, k2+2*n, k+2*n]

            -- paroi intérieure de la gorge (normales vers le centre du bac)
            append fArr [k+2*n, k2+3*n, k+3*n]
            append fArr [k+2*n, k2+2*n, k2+3*n]
        )

        -- fond de la gorge (normales vers le haut) + garde-fou triangles impossibles
        local tris = FR_Triangulate I

        for t in tris do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            local tA = abs ((I[b].x-I[a].x)*(I[c].y-I[a].y) - (I[c].x-I[a].x)*(I[b].y-I[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 do
                append fArr [3*n+a, 3*n+b, 3*n+c]
        )

        -- dessous fermé (normales vers le bas) + même garde-fou
        local tris2 = FR_Triangulate O

        for t in tris2 do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            local tA = abs ((O[b].x-O[a].x)*(O[c].y-O[a].y) - (O[c].x-O[a].x)*(O[b].y-O[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 do
                append fArr [a, c, b]
        )

        local m = mesh vertices:vArr faces:fArr

        update m
        FR_NoSmooth m

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
)

-- fond horizontal fermé (vu d'en dessous) : polygone triangulé posé à la hauteur z, normales vers le bas
-- 0.6.15 : orientation normalisée + garde-fou triangles géants (cf. FR_RoofSlabContour)
fn FR_RoofCapContour p pts z mat =
(
    pts = FR_PolyCCW pts

    local tris = FR_Triangulate pts

    local totA = abs (FR_PolyArea pts)

    if tris.count > 0 do
    (
        local n = pts.count
        local vArr = #()
        local fArr = #()

        for k = 1 to n do append vArr [pts[k].x, pts[k].y, z]

        -- triangulation anti-horaire (normale vers le haut) -> inversée pour regarder vers le bas
        for t in tris do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            local tA = abs ((pts[b].x - pts[a].x) * (pts[c].y - pts[a].y) - (pts[c].x - pts[a].x) * (pts[b].y - pts[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 do append fArr [a, c, b]
        )

        local m = mesh vertices:vArr faces:fArr

        update m
        FR_NoSmooth m

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
)

-- coupe un polygone (tableau de point3, anti-horaire) par la demi-plane nx*x + ny*y + c >= 0
fn FR_SplitGE pts nx ny c =
(
    local res = #()
    local n = pts.count

    for k = 1 to n do
    (
        local a = pts[k]

        local k2 = k + 1
        if k2 > n do k2 = 1

        local b = pts[k2]

        local fa = nx*a.x + ny*a.y + c
        local fb = nx*b.x + ny*b.y + c

        if fa >= 0.0 then
        (
            append res a

            if fb < 0.0 do append res (a + (b - a) * (fa / (fa - fb)))
        )
        else if fb >= 0.0 do
            append res (a + (b - a) * (fa / (fa - fb)))
    )

    -- supprime les sommets confondus introduits par la coupe
    local clean = #()

    for q in res do
    (
        if clean.count == 0 or (length (q - clean[clean.count])) > 0.0001 do append clean q
    )

    if clean.count > 1 and (length (clean[1] - clean[clean.count])) <= 0.0001 do deleteItem clean clean.count

    clean
)

-- versants d'un toit suivant le contour décalé : faîtage sur le plus long segment (direction ex),
-- la surface est découpée en cellules PLANAIRES (une pente par cellule) par la ligne de faîtage
-- et, pour les croupes, par les diagonales à 45° partant des extrémités du faîtage.
-- Chaque cellule devient un prisme (FR_Prisma) ; les arêtes de coupe sont donc exactes.
-- Footprints convexes recommandés (les formes très concaves peuvent mal se découper).
fn FR_RoofSlopesContour p pts ex inw p1 uMin uMax wMin wMax pitch hip mat =
(
    local th = 0.12
    local tanP = tan pitch
    local wm = (wMin + wMax)/2.0
    local h = ((wMax - wMin)/2.0) * tanP

    -- branches en `then` (un `if ... do` ne peut pas être suivi d'un `else`)
    if h > 0.05 then
    (
        -- coordonnées (u, w) du contour décalé dans le repère du faîtage
        local uv = for q in pts collect [dot (q - p1) ex, dot (q - p1) inw, 0.0]

        -- cellules : #(polygone (u,w), axe (1=u, 2=w), référence, signe) -> z = signe*(coord-ref)*tanP
        local cells = #()

        local lo = FR_SplitGE uv 0.0 -1.0 wm
        local hi = FR_SplitGE uv 0.0 1.0 -wm

        if hip then
        (
            -- côté w <= wm : découpé par les diagonales issues des extrémités du faîtage
            local a1 = FR_SplitGE lo -1.0 1.0 (uMin - wMin)
            local rest1 = FR_SplitGE lo 1.0 -1.0 (wMin - uMin)
            local a2 = FR_SplitGE rest1 1.0 1.0 -(uMax + wMin)
            local mid1 = FR_SplitGE rest1 -1.0 -1.0 (uMax + wMin)

            -- côté w >= wm
            local b1 = FR_SplitGE hi -1.0 -1.0 (uMin + wMax)
            local rest2 = FR_SplitGE hi 1.0 1.0 -(uMin + wMax)
            local b2 = FR_SplitGE rest2 1.0 -1.0 (wMax - uMax)
            local mid2 = FR_SplitGE rest2 -1.0 1.0 (uMax - wMax)

            cells = #(#(a1, 1, uMin, 1), #(a2, 1, uMax, -1), #(mid1, 2, wMin, 1), #(b1, 1, uMin, 1), #(b2, 1, uMax, -1), #(mid2, 2, wMax, -1))
        )
        else
            cells = #(#(lo, 2, wMin, 1), #(hi, 2, wMax, -1))

        local built = 0

        for c in cells do
        (
            local poly = c[1]

            if poly.count >= 3 do
            (
                local wpts = #()

                for q in poly do
                (
                    local coord = if c[2] == 1 then q.x else q.y
                    local z = (c[4] * (coord - c[3])) * tanP

                    append wpts (p1 + ex*q.x + inw*q.y + [0,0,z])
                )

                FR_Prisma (p + "_Pente") wpts mat th
                built = built + 1
            )
        )

        -- diagnostic 0.6.18 : prévenir quand aucun versant n'a pu être construit
        if built == 0 do
            FR_Msg ("Versants du toit annulés : découpe impossible (contour " + (pts.count as string) + " sommets, pente " + (pitch as string) + "°).")

        built
    )
    else
    (
        FR_Msg ("Versants du toit annulés : hauteur de pente nulle (pente " + (pitch as string) + "° trop faible pour la profondeur).")
        0
    )
)

-- toit du contour : il part du contour DÉCALÉ vers l'extérieur (débord), avec un fond fermé
-- (terrasse : dalle + acrotère suivant le contour ; pentes : faîtage sur le plus long segment)
fn FR_RoofContour pts segPRs bases totalH =
(
    local PR0 = segPRs[1]
    local roofMat = FR_Material "FRAMER_Roof" PR0.colRoof 100 apply:true

    -- le toit part du contour décalé vers l'extérieur (débord), avec un fond fermé vu de dessous
    local oPts = FR_OffsetContour pts PR0.roofOver

    if PR0.roofMode == "Flat" then
    (
        -- 0.6.16 : terrasse EN BAC — couronne d'acrotère pleine (épaisseur
        -- acrTh) et plateau intérieur enfoncé (gorge acrGorge), le tout partant
        -- du contour décalé du débord (oPts). Plus de dalle + bandeaux séparés.
        if PR0.roofPar > 0.05 then
        (
            local iPts = FR_OffsetContour oPts (-PR0.acrTh)

            local bac = FR_RoofBac "FRAMER_Roof_Terrasse" oPts iPts totalH PR0.roofPar PR0.acrGorge roofMat

            -- diagnostic 0.6.18 : prévenir si le bac n'a pas pu être construit
            if bac == undefined do
                FR_Msg ("Terrasse annulée : contour " + (oPts.count as string) + " sommets (intérieur " + (iPts.count as string) + "), acrotère " + (PR0.roofPar as string) + " m.")
        )
        else
            -- pas d'acrotère : simple dalle sur le contour décalé
            FR_RoofSlabContour "FRAMER_Roof_Slab" oPts totalH 0.2 roofMat
    )
    -- Mansard en mode contour : repli quatre pans (faîtage sur le plus long
    -- segment) ; le vrai brisis/terrasson n'existe qu'en façade simple.
    else if PR0.roofMode == "Gable" or PR0.roofMode == "Hip" or PR0.roofMode == "Mansard" then
    (
        -- le plus long segment donne la direction du faîtage
        local kLong = 1

        for k = 2 to pts.count do
        (
            if bases[k][2] > bases[kLong][2] do kLong = k
        )

        -- bases[k] = #(repère, largeur) : les axes ex et inw sont les LIGNES de la matrix3
        local ex = bases[kLong][1][1]
        local inw = bases[kLong][1][2]
        local p1 = pts[kLong]

        local uMin = 0.0
        local uMax = 0.0
        local wMin = 0.0
        local wMax = 0.0

        for q in oPts do
        (
            local du = dot (q - p1) ex
            local dw = dot (q - p1) inw

            if du < uMin do uMin = du
            if du > uMax do uMax = du
            if dw < wMin do wMin = dw
            if dw > wMax do wMax = dw
        )

        -- fond fermé à la hauteur des murs (visible d'en dessous, ferme aussi le débord)
        FR_RoofCapContour "FRAMER_Roof_Cap" oPts totalH roofMat

        -- versants suivant le contour décalé (pignons maçonnés non générés en mode contour)
        FR_RoofSlopesContour "FRAMER_Roof" oPts ex inw p1 uMin uMax wMin wMax PR0.roofPitch (PR0.roofMode == "Hip") roofMat
    )
)

/* =========================================================
   FUSION : un editable poly par matériau. Renvoie les objets finaux.
========================================================= */

fn FR_Merge basis tag =
(
    local names = #()
    local result = #()

    for b in FR_Pool do
    (
        if isValidNode b then
        (
            local mn = b.material.name

            if (findItem names mn) == 0 do append names mn
        )
    )

    for mn in names do
    (
        local grp = for b in FR_Pool where (isValidNode b) and b.material.name == mn collect b

        if grp.count > 0 then
        (
            local main = grp[1]

            convertToPoly main

            for k = 2 to grp.count do
            (
                -- les mailles (arches) sont converties avant d'être fusionnées
                if (classof grp[k]) == Editable_mesh do convertToPoly grp[k]

                polyop.attach main grp[k]
            )

            -- arêtes vives : suppression de tous les groupes de lissage
            FR_NoSmooth main

            -- "FRAMER_Glass" -> "<nom de la racine>_Glass"
            main.name = tag + "_" + (substring mn 8 mn.count)
            main.pivot = basis[4]

            append result main
        )
    )

    result
)

/* =========================================================
   GÉNÉRATEUR DE FAÇADE  (un segment)
   Disposition suivant U : pilier, travée, pilier, travée, ... , pilier
   Mode contour (noEndPiers) : pas de piliers aux extrémités (les colonnes
   d'angle du contour s'en chargent) et travées décalées de endExt.
========================================================= */

fn FR_Generate PR basis noEndPiers:false endExt:0.0 noRoof:false =
(
    local width = PR.width
    local groundH = PR.groundH
    local floors = PR.floors
    local bays = PR.bays
    local pier = PR.pier
    local depth = PR.depth
    local fw = PR.fw
    local balcD = PR.balcD
    local balcDepths = #()   -- profondeurs réellement tirées (pour le résumé)

    -- complète les tableaux par étage (façades créées avec une version plus ancienne)
    PR.flH = FR_FitArr PR.flH floors PR.upperH
    PR.flMode = FR_FitArr PR.flMode floors PR.upperMode
    PR.flWin = FR_FitArr PR.flWin floors PR.winPct
    PR.flHt = FR_FitArr PR.flHt floors PR.winHt
    PR.flSill = FR_FitArr PR.flSill floors PR.winSill
    PR.flBalc = FR_FitArr PR.flBalc floors "None"
    PR.flBalcD = FR_FitArr PR.flBalcD floors PR.balcD
    PR.flBalcVar = FR_FitArr PR.flBalcVar floors PR.balcVar

    local sumH = 0.0

    for k = 1 to floors do sumH = sumH + PR.flH[k]

    local totalH = groundH + sumH

    local endM = 0.0

    if noEndPiers do endM = endExt

    local nPiers = bays + 1

    if noEndPiers do nPiers = bays - 1

    local clearW = width - nPiers*pier - endM*2

    if clearW <= 0 then
    (
        FR_Msg "Longueur de façade invalide."
        return false
    )

    /* ---------- largeurs de travées (graine) ---------- */

    seed PR.seedVal

    local entIdx = 0

    if PR.entrance == "Center" then
        entIdx = (bays+1)/2
    else if PR.entrance == "Left" then
        entIdx = 1
    else if PR.entrance == "Right" then
        entIdx = bays
    else if PR.entrance == "Random" then
        entIdx = random 1 bays

    local wts = #()
    local sumW = 0.0

    for i = 1 to bays do
    (
        local wt = 1.0 + ((random 0.0 2.0) - 1.0) * PR.widthVar/100.0

        if i == entIdx do wt = wt * PR.entranceFactor

        append wts wt
        sumW = sumW + wt
    )

    local bayW = #()
    local bayU = #()
    local cursor = endM

    if not noEndPiers do cursor = cursor + pier

    for i = 1 to bays do
    (
        local bw = clearW * wts[i] / sumW

        append bayW bw
        append bayU cursor

        cursor = cursor + bw + pier
    )

    if (amin bayW) < (fw*2 + 0.3) then
    (
        FR_Msg "Les travées sont trop étroites pour cette largeur de cadre."
        return false
    )

    /* ---------- variante de chaque colonne de travées (graine) ---------- */

    local variants = #("Window")

    if PR.allowWide do append variants "Wide"
    if PR.allowBalcony do append variants "Balcony"
    if PR.allowWall do append variants "Wall"

    local anyWin = ((findItem PR.flMode "Window") > 0)
    local colVar = #()

    for i = 1 to bays do
    (
        local v = "Window"

        if anyWin and (random 0.0 1.0) < PR.variation/100.0 then
            v = variants[random 1 (variants.count)]

        append colVar v
    )

    -- résumé : F fenêtre, P porte-fenêtre, B balcon, M mur plein
    local sc = ""

    for i = 1 to bays do
    (
        local code = "F"

        if colVar[i] == "Wide" do code = "P"
        if colVar[i] == "Balcony" do code = "B"
        if colVar[i] == "Wall" do code = "M"

        sc = sc + code + " "
    )

    FR_Summary = "Travées : " + sc + "| entrée : " + (entIdx as string) + " | graine " + (PR.seedVal as string)

    /* ---------- matériaux et préparation ---------- */

    -- épaisseur du mur et plan médian (le mur est en retrait des piliers)
    local T = depth*0.5
    FR_VC = -depth*0.25

    local frameMat = FR_Material "FRAMER_Frame" PR.colFrame 100 apply:true
    local pierMat = FR_Material "FRAMER_Piers" PR.colPier 100 apply:true
    local glassMat = FR_Material "FRAMER_Glass" PR.colGlass 42 apply:true
    local panelMat = FR_Material "FRAMER_Panels" PR.colPanel 100 apply:true
    local doorMat = FR_Material "FRAMER_Door" PR.colDoor 100 apply:true
    local wallMat = FR_Material "FRAMER_Walls" PR.colWall 100 apply:true

    -- pré-créer les matériaux utilisés en ligne ailleurs (volets, moulure) :
    -- les appels inline réutilisent le cache sans avoir besoin des couleurs
    FR_Material "FRAMER_Shutters" PR.colShut 100 apply:true
    FR_Material "FRAMER_Moulding" PR.colWall 100 apply:true

    -- encadrement des baies : profil (spline choisie ou carré par défaut) + matériau
    local surrP = undefined
    local surrM = undefined

    if PR.surr do
    (
        surrM = FR_Material "FRAMER_Moulding" PR.colWall 100

        local sn = if PR.surrProf != "" then (try(getNodeByName PR.surrProf)catch(undefined)) else undefined

        if sn != undefined and (isValidNode sn) and (superclassof sn) == shape then
            surrP = FR_ReadProfile sn PR.surrS
        else
        (
            -- profil par défaut : bande de 7 cm, saillie 8 cm, chanfreinée
            local defP = #([0.0,0.0], [0.07,0.0], [0.07,0.05], [0.035,0.08], [0.0,0.05])
            surrP = for q in defP collect [q.x*PR.surrS, q.y*PR.surrS]
        )
    )

    local bu1 = 0.0
    local bu2 = 0.0
    local z1 = 0.0
    local z2 = 0.0
    local p = ""
    local mode = ""

    -- arcades en arc ou portique à colonnes : galerie couverte, vitrines reculées
    local isPort = (PR.groundMode == "Portico")
    local isArc = (PR.groundMode == "Arcade") or isPort
    local arcT = PR.arcType

    if isPort do arcT = "Flat"

    -- zs[1] = haut du rez-de-chaussée, zs[k+1] = haut de l'étage k
    local zs = #(groundH)

    for k = 1 to floors do append zs (zs[k] + PR.flH[k])

    /* ---------- piliers ---------- */

    for k = 0 to bays do
    (
        -- en contour, pas de piliers de bout : les colonnes d'angle les remplacent
        if not noEndPiers or (k > 0 and k < bays) do
        (
            local u = pier/2

            if k > 0 do u = bayU[k] + bayW[k] + pier/2

            if isArc then
            (
                -- portique ET arcades en arc : colonne carrée libre au rez-de-chaussée (le passage reste ouvert),
                -- le mur des étages passe au-dessus
                FR_LocalBox ("FRAMER_Column_"+(k as string)) u (-depth + pier/2) (groundH/2) pier pier groundH basis pierMat
                FR_WallRect ("FRAMER_WallPier_"+(k as string)) (u - pier/2) (u + pier/2) groundH totalH T basis wallMat

                -- pilier reporté au plan des vitrines reculées : bouche les trous
                -- entre deux travées (le vitrage et le fond s'arrêtent aux limites
                -- de chaque travée)
                local oldVC = FR_VC

                FR_VC = -depth*0.5 + PR.arcRecess + T/2

                FR_WallRect ("FRAMER_BackPier_"+(k as string)) (u - pier/2) (u + pier/2) 0.0 (groundH - PR.arcLintel) T basis pierMat

                FR_VC = oldVC
            )
            else if PR.groundMode == "TownHouse" then
            (
                -- maison de ville : pas de piliers saillants — un simple mur continu
                -- (la bande couvre l'intervalle entre deux travées, sur toute la hauteur)
                FR_WallRect ("FRAMER_WallStrip_"+(k as string)) (u - pier/2) (u + pier/2) 0.0 totalH T basis wallMat
            )
            else
            (
                FR_LocalBox ("FRAMER_Pier_"+(k as string)) u (-depth/2) (totalH/2) pier depth totalH basis pierMat
            )
        )
    )

    /* ---------- rez-de-chaussée ---------- */

    -- répartition des portes du mode « Alternance vitrine / porte » :
    -- nDoors = 0 -> une travée sur deux (comportement d'origine) ;
    -- nDoors >= 1 -> nombre exact de portes, réparties régulièrement
    local doorSet = #()
    if PR.groundMode == "Alternating storefront / door" do
    (
        if PR.nDoors >= 1 then
        (
            local nD = (amin #((PR.nDoors as integer), bays))
            for k = 1 to nD do
            (
                local fbi = floor (((k - 0.5) * bays) / (nD as float))
                local bi = 1 + (fbi as integer)
                if findItem doorSet bi == 0 do append doorSet bi
            )
        )
        else
        (
            for k = 2 to bays by 2 do append doorSet k
        )
    )

    for i = 1 to bays do
    (
        bu1 = bayU[i]
        bu2 = bu1 + bayW[i]

        z1 = 0.0
        z2 = groundH

        p = "FRAMER_GF_"+(i as string)

        mode = PR.groundMode

        if mode == "Portico" do mode = "Arcade"

        if mode == "Alternating storefront / door" then
            mode = (if findItem doorSet i > 0 then "Door + sidelight" else "Storefront")

        if i == entIdx and mode != "Arcade" do mode = "Entrance"

        if mode == "Entrance" then
        (
            FR_Entrance p bu1 bu2 groundH T depth fw basis frameMat glassMat doorMat true PR.doorH
        )
        else if mode == "Arcade" then
        (
            FR_Arcade p bu1 bu2 groundH T depth PR.arcRecess PR.arcLintel arcT fw basis frameMat glassMat doorMat wallMat (i == entIdx) (PR.arcGlArch and not isPort) PR.doorH
        )
        else if mode == "Storefront" then
        (
            FR_Glass p bu1 bu2 z1 z2 T fw basis frameMat glassMat 1
        )
        else if mode == "Opaque infill" then
        (
            FR_Panel p bu1 bu2 z1 z2 T fw basis frameMat panelMat
        )
        else if mode == "Door + sidelight" then
        (
            local doorW = (bu2-bu1)*0.42
            local splitU = bu1+doorW

            -- porte à la hauteur commune (réglable), PAS pleine hauteur du rdc
            local dH = amin #(PR.doorH, z2-z1-0.3)

            if dH < 1.9 do dH = 1.9

            FR_LocalBox (p+"_Door") ((bu1+splitU)/2) FR_VC (dH/2) doorW (T*0.7) dH basis doorMat

            -- imposte vitrée au-dessus de la porte, jusqu'au bandeau
            FR_Glass (p+"_Transom") bu1 splitU dH (z2-fw/2) T fw basis frameMat glassMat 0
            FR_Glass (p+"_Side") splitU bu2 z1 z2 T fw basis frameMat glassMat 0
            FR_LocalBox (p+"_DoorHead") ((bu1+bu2)/2) FR_VC (z2-fw/2) (bu2-bu1) T fw basis frameMat
        )
        else if mode == "TownHouse" then
        (
            -- maison de ville : mur plein, fenêtre standard encadrée par travée
            -- (la travée d'entrée reçoit la porte d'entrée, voir plus haut)
            local bw = bu2 - bu1
            -- fenêtre de maison de ville : 1,40 m de large × 1,20 m de haut, allège à 0,90 m
            local wW = amin #(amax #(bw*0.55, 0.8), 1.4)
            local wH = amin #(1.2, groundH - 1.1)

            -- tirage casquettes (mêmes réglages que les étages)
            local capK = "None"

            if PR.capMode != "None" do
            (
                if PR.capPct >= 100.0 then
                    capK = PR.capMode
                else if (random 0.0 100.0) < PR.capPct do
                    capK = PR.capMode
            )

            -- volets battants à deux vantaux sur toutes les fenêtres du rdc
            local wr = FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat wW wH 0.9 capK:capK capD:PR.capD surrProf:surrP surrMat:surrM

            if wr != undefined do
                FR_ShutterBattant p (wr[1]) (wr[2]) (wr[3]) (wr[4]-wr[3]) T fw basis (FR_Material "FRAMER_Shutters" (color 172 166 152) 100) PR.shutOpen
        )
        -- "Empty bay" : passage ouvert, rien n'est généré
    )

    -- portique : plafond plat de la galerie (au-dessus de l'ouverture en linteau)
    -- pour les ARCADES EN ARC, le plafond est PLAT au niveau de la clé de
    -- l'arc (voir FR_Arcade : bloc _Soffit)
    if isArc and PR.arcRecess > 0.3 and arcT == "Flat" do
    (
        local vfA = -depth*0.5

        -- portique : le plafond part de la face avant des colonnes
        if isPort do vfA = -depth

        local gz = groundH - PR.arcLintel - 0.15

        if gz < 1.0 do gz = 1.0

        FR_LocalBox "FRAMER_Gallery" (width/2) ((vfA + PR.arcRecess)/2) gz (width+endM*2) (PR.arcRecess - vfA) 0.3 basis pierMat
    )

    /* ---------- étages (chacun avec sa hauteur, son type, ses fenêtres, son balcon) ---------- */

    for f = 1 to floors do
    (
        local uH = PR.flH[f]
        local fm = PR.flMode[f]
        local kind = PR.flBalc[f]
        local fWin = PR.flWin[f]
        local fHt = PR.flHt[f]
        local fSill = PR.flSill[f]
        -- profondeur et variation de profondeur propres à cet étage (mode indépendants)
        local fBalcD = PR.flBalcD[f]
        local fBalcVar = PR.flBalcVar[f]
        local pf = "FRAMER_F"+(f as string)

        z1 = zs[f]
        z2 = zs[f+1]

        for i = 1 to bays do
        (
            bu1 = bayU[i]
            bu2 = bu1 + bayW[i]

            local bw = bayW[i]

            p = pf + "_B" + (i as string)

            if fm == "Window" or fm == "TownWin" then
            (
                local variant = colVar[i]

                -- rythme PAR TRAVÉE : étage en "Mix" -> chaque travée tire son
                -- propre type (balcon saillant / loggia / rien) selon les %
                local knd = kind

                if kind == "Mix" do
                (
                    local r = random 0.0 100.0
                    knd = if r < PR.mixOut then "Out" else if r < (PR.mixOut + PR.mixIn) then "In" else "None"
                )

                -- balcon filant : toutes les travées deviennent des porte-fenêtres
                if knd == "Cont" do variant = "Wide"

                -- tirages volets roulants et casquettes (après les variantes, pour garder la séquence du hasard)
                -- pas de garde-corps de fenêtre s'il y a un balcon ou une loggia :
                -- c'est le balcon qui porte le garde-corps (sinon deux garde-corps superposés)
                local railK = if knd == "None" then PR.railMode else "None"
                local shutOpen = -1.0

                if PR.shutPct > 0.0 and (random 0.0 100.0) < PR.shutPct do shutOpen = PR.shutOpen

                -- style maison de ville : pas de volet roulant, les battants sont dessinés à part
                if fm == "TownWin" do shutOpen = -1.0

                local capK = "None"

                if PR.capMode != "None" do
                (
                    if PR.capPct >= 100.0 then
                        capK = PR.capMode
                    else if (random 0.0 100.0) < PR.capPct do
                        capK = PR.capMode
                )

                -- baies cintrées : tirage par travée (0 % = toutes rectangulaires)
                local awin = PR.arcPct >= 100.0 or (random 0.0 100.0) < PR.arcPct

                -- profondeur de balcon / loggia de CET étage, éventuellement variable au hasard
                local bd = fBalcD

                if fBalcVar > 0.0 do
                    bd = amax #(fBalcD*0.35, fBalcD * (1.0 + ((random -1.0 1.0) * fBalcVar/100.0)))

                if knd == "Bow" or knd == "BowS" then
                (
                    -- bow-window : oriel vitré sur toute la travée
                    -- (3 facettes à joues 45°, ou simple rectangulaire sans biseaux)
                    FR_BowWindow p bu1 bu2 z1 z2 T depth bd fw basis wallMat frameMat glassMat simple:(knd == "BowS")
                    append balcDepths bd
                )
                else if variant == "Wall" then
                (
                    FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat
                )
                else if knd == "In" then
                (
                    -- loggia (réglage d'étage OU tirage du mix par travée)
                    FR_Loggia p bu1 bu2 z1 z2 T depth bd fw basis wallMat frameMat glassMat pierMat
                    append balcDepths bd
                )
                else
                (
                    local wr = undefined

                    if variant == "Window" then
                    (
                        wr = FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat (bw*fWin/100.0) fHt fSill railK:railK railH:PR.railH railD:PR.railD shutOpen:shutOpen capK:capK capD:PR.capD surrProf:surrP surrMat:surrM arced:awin
                    )
                    else
                    (
                        local wideW = amin #((bw*(fWin+15.0)/100.0), (bw*0.92))
                        local wideH = amin #(2.3, (uH-0.25))

                        wr = FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat wideW wideH 0.0 railK:railK railH:PR.railH railD:PR.railD shutOpen:shutOpen capK:capK capD:PR.capD surrProf:surrP surrMat:surrM arced:awin
                    )

                    -- volets battants à deux vantaux (style maison de ville)
                    -- (pas sur une baie cintrée : les battants rectangulaires écraseraient l'arc)
                    if fm == "TownWin" and wr != undefined and not awin do
                        FR_ShutterBattant p (wr[1]) (wr[2]) (wr[3]) (wr[4]-wr[3]) T fw basis (FR_Material "FRAMER_Shutters" (color 172 166 152) 100) PR.shutOpen

                    -- balcon saillant : réglage d'étage (knd) OU variante tirée au hasard
                    if knd == "Out" or variant == "Balcony" do
                    (
                        FR_Balcony p bu1 bu2 z1 depth bd basis pierMat frameMat glassMat railK:PR.railMode slTh:PR.slabTh
                        append balcDepths bd
                    )
                )
            )
            else if fm == "Glazed panel" then
            (
                FR_Glass p bu1 bu2 z1 z2 T fw basis frameMat glassMat 1
            )
            else if fm == "Opaque panel" then
            (
                -- alternance aléatoire panneaux pleins / vitrés (% de pleins,
                -- 100 % = tous pleins comme avant)
                if PR.panOpaque >= 100.0 or (random 0.0 100.0) < PR.panOpaque then
                    FR_Panel p bu1 bu2 z1 z2 T fw basis frameMat panelMat
                else
                    FR_Glass p bu1 bu2 z1 z2 T fw basis frameMat glassMat 1
            )
            else if fm == "Plain wall" then
            (
                FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat
            )
        )

        -- balcon filant : une seule dalle sur toute la longueur de la façade
        if kind == "Cont" do
        (
            local bdC = fBalcD

            if fBalcVar > 0.0 do
                bdC = amax #(fBalcD*0.35, fBalcD * (1.0 + ((random -1.0 1.0) * fBalcVar/100.0)))

            FR_Balcony (pf+"_Cont") (-endM) (width+endM) z1 depth bdC basis pierMat frameMat glassMat railK:PR.railMode slTh:PR.slabTh
            append balcDepths bdC
        )
    )

    -- 0.6.9 : affiche le tirage réel des profondeurs de dalles (diagnostic variation)
    if balcDepths.count > 0 do
        FR_Summary = FR_Summary + " | prof. dalles : " + ((amin balcDepths) as string) + " à " + ((amax balcDepths) as string) + " m"

    /* ---------- bandeaux horizontaux ---------- */

    local bandH = fw*1.5

    -- en bas, puis au-dessus du rez-de-chaussée et de chaque étage (sauf le dernier), puis en haut
    FR_LocalBox "FRAMER_Band_0" (width/2) (-depth/2) (bandH/2) (width+endM*2) depth bandH basis frameMat

    for k = 1 to floors do
    (
        FR_LocalBox ("FRAMER_Band_"+(k as string)) (width/2) (-depth/2) zs[k] (width+endM*2) depth bandH basis frameMat
    )

    FR_LocalBox ("FRAMER_Band_"+((floors+1) as string)) (width/2) (-depth/2) (totalH-bandH/2) (width+endM*2) depth bandH basis frameMat

    /* ---------- corniche (sans objet si un toit la remplace) ---------- */

    if PR.cornice and PR.roofMode == "None" do
    (
        local ch = 0.25
        local outer = -depth - 0.2
        local inner = 0.0

        FR_LocalBox "FRAMER_Cornice" (width/2) ((outer+inner)/2) (totalH+ch/2) (width+0.3+endM*2) (inner-outer) ch basis pierMat
    )

    /* ---------- toit (façade simple : couvre la façade et s'étend derrière) ---------- */

    -- en mode contour, le toit est généré UNE SEULE FOIS par FR_RoofContour
    -- (il suit le contour décalé) : pas de toit rectangulaire par segment
    if PR.roofMode != "None" and not noRoof do
    (
        local roofMat = FR_Material "FRAMER_Roof" PR.colRoof 100 apply:true

        -- rectangle couvert : du plan des piliers (v = -depth) vers l'arrière (roofDepth)
        local bR = matrix3 basis[1] basis[2] basis[3] (basis[4] + basis[2]*(-depth))
        local W = width + endM*2
        local D = depth + PR.roofDepth

        if PR.roofMode == "Flat" then
            FR_RoofFlatRect "FRAMER_Roof" bR W D totalH PR.roofOver PR.roofPar roofMat acrTh:PR.acrTh acrGorge:PR.acrGorge
        else if PR.roofMode == "Gable" then
            FR_RoofGableRect "FRAMER_Roof" bR W D totalH PR.roofPitch PR.roofOver roofMat pierMat rk:PR.ridgeMode rw:PR.ridgeW rh:PR.ridgeH
        -- NOTE : tout `else if` de cette chaîne doit utiliser `then` (jamais
        -- `do`) : en MAXScript, une branche `if ... do` ne peut PAS être
        -- suivie d'un `else` (sinon erreur « à else, attendu <facteur> »).
        else if PR.roofMode == "Hip" then
            FR_RoofHipRect "FRAMER_Roof" bR W D totalH PR.roofPitch PR.roofOver roofMat rk:PR.ridgeMode rw:PR.ridgeW rh:PR.ridgeH
        else if PR.roofMode == "Mansard" then
            FR_RoofMansardRect "FRAMER_Roof" bR W D totalH PR.roofPitch PR.mansP2 PR.roofOver PR.mansTop PR.roofPar roofMat rk:PR.ridgeMode rw:PR.ridgeW rh:PR.ridgeH luc:PR.lucMode lw:PR.lucW lh:PR.lucH lst:PR.lucStep lucWall:wallMat lucGlass:glassMat
    )

    true
)

/* =========================================================
   VALIDATION
========================================================= */

fn FR_Validate PR =
(
    local ok = true

    if PR.width <= (PR.bays+1)*PR.pier then
    (
        FR_Msg "La longueur de façade est trop petite pour ce nombre de piliers."
        ok = false
    )

    ok
)

/* =========================================================
   CONSTRUIRE / RECONSTRUIRE UNE FAÇADE SOUS UN HELPER RACINE
   La nouvelle géométrie est créée d'abord ; l'ancienne n'est supprimée qu'en cas de succès.
========================================================= */

-- supprime les débris FRAMER orphelins : géométrie créée par une génération
-- interrompue par une erreur (jamais parentée à la racine, elle restait dans
-- la scène et s'accumulait à chaque crash — montée de mémoire invisible)
fn FR_CleanOrphans =
(
    local dead = #()

    for o in objects where o.parent == undefined and \
        (matchPattern o.name pattern:"FRAMER_*") and \
        not (matchPattern o.name pattern:"FRAMER_Facade_*") do
        append dead o

    if dead.count > 0 do
    (
        delete dead
        FR_Msg ((dead.count as string) + " débris FRAMER orphelins supprimés.")
    )

    dead.count
)

fn FR_Build PR root doMerge =
(
    FR_CleanOrphans()

    FR_Pool = #()

    local basis = root.transform

    local oldKids = for c in root.children where (matchPattern c.name pattern:"FRAMER_*") collect c

    local ok = false

    -- si la génération plante à mi-chemin (exception), la géométrie partielle
    -- déjà créée est supprimée avant de relancer l'erreur
    try
    (
        ok = FR_Generate PR basis
    )
    catch
    (
        for n in FR_Pool do ( if isValidNode n do delete n )
        FR_Pool = #()
        throw()
    )

    if ok == true then
    (
        local nodes = FR_Pool

        if doMerge do nodes = FR_Merge basis root.name

        if oldKids.count > 0 do delete oldKids

        for n in nodes do
        (
            if isValidNode n do n.parent = root
        )

        setUserPropBuffer root (FR_ParamsToString PR)
    )
    else
    (
        -- échec propre : supprime ce qui vient d'être créé, l'ancienne façade reste intacte
        for n in FR_Pool do ( if isValidNode n do delete n )
        FR_Pool = #()
    )

    ok
)

/* =========================================================
   CONTOUR FERMÉ : un bâtiment entier, un style de façade par segment
   Convention : l'EXTÉRIEUR est à DROITE du sens de parcours, vu de dessus
   (contour anti-horaire), comme pour le balayage des moulures.
========================================================= */

fn FR_ReverseArr arr =
(
    local res = #()

    for k = arr.count to 1 by -1 do append res arr[k]

    res
)

-- nombre de segments mémorisés dans le buffer du racine (0 si façade simple)
fn FR_ContourCount root =
(
    local n = 0

    if root != undefined do
    (
        for ln in (filterString (getUserPropBuffer root) "\r\n") do
        (
            if (findString ln "FRAMER_CONTOUR=") == 1 do
            (
                try(n = (substring ln 16 ln.count) as integer)catch(n = 0)
            )
        )
    )

    n
)

fn FR_ContourToString pts segs =
(
    local ss = stringStream ""

    format "FRAMER_CONTOUR=%\n" segs.count to:ss

    local ps = ""

    for k = 1 to pts.count do
    (
        if k > 1 do ps = ps + ";"
        ps = ps + (FR_F pts[k].x) + "," + (FR_F pts[k].y) + "," + (FR_F pts[k].z)
    )

    format "PTS=%\n" ps to:ss

    for k = 1 to segs.count do
    (
        format "===FRAMER_SEG===\n" to:ss
        format "%" (FR_ParamsToString segs[k]) to:ss
    )

    ss as string
)

fn FR_ContourFromString txt =
(
    local pts = #()
    local segs = #()
    local chunks = #()

    -- découpe manuelle sur le séparateur (filterString ne garderait pas les bons blocs)
    local sep = "===FRAMER_SEG==="
    local rest = txt
    local done = false

    while not done do
    (
        local p = findString rest sep

        if p == undefined then
        (
            append chunks rest
            done = true
        )
        else
        (
            append chunks (substring rest 1 (p-1))

            if p + sep.count > rest.count then
            (
                append chunks ""
                done = true
            )
            else
                rest = substring rest (p+sep.count) (rest.count - p - sep.count + 1)
        )
    )

    if chunks.count >= 1 do
    (
        for ln in (filterString chunks[1] "\r\n") do
        (
            if (findString ln "PTS=") == 1 do
            (
                for tok in (filterString (substring ln 5 ln.count) ";") do
                (
                    local c = filterString tok ","

                    if c.count >= 3 do append pts [c[1] as float, c[2] as float, c[3] as float]
                )
            )
        )

        for k = 2 to chunks.count do
        (
            append segs (FR_ParamsFromString chunks[k])
        )
    )

    #(pts, segs)
)

-- lit une spline fermée : sommets monde, orientation corrigée (anti-horaire), Z à 0
fn FR_ReadContour shapeNode =
(
    local ok = true

    -- isValidNode d'abord : un objet supprimé de la scène fait planter superclassof
    if shapeNode == undefined or not (isValidNode shapeNode) or (superclassof shapeNode) != shape then
    (
        FR_Msg "Le contour doit être une spline (et exister encore dans la scène)."
        ok = false
    )
    else if (numSplines shapeNode) < 1 or (numKnots shapeNode 1) < 3 then
    (
        FR_Msg "Le contour doit avoir au moins 3 sommets."
        ok = false
    )
    else if not (try(isClosed shapeNode 1)catch(false)) then
    (
        FR_Msg "La spline du contour doit être FERMÉE (Éditable spline : fermer)."
        ok = false
    )

    if not ok then
        undefined
    else
    (
        -- getKnotPoint renvoie déjà des coordonnées MONDE : ne pas re-transformer
        local pts = for k = 1 to (numKnots shapeNode 1) collect (in coordsys world (getKnotPoint shapeNode 1 k))

        -- supprime les sommets confondus (segments de moins de 0,5 m)
        local clean = #(pts[1])

        for k = 2 to pts.count do
        (
            if (length (pts[k] - clean[clean.count])) > 0.5 do append clean pts[k]
        )

        if clean.count > 1 and (length (clean[1] - clean[clean.count])) <= 0.5 do deleteItem clean clean.count

        if clean.count < 3 then
        (
            FR_Msg "Contour invalide : sommets confondus ou segments trop courts."
            undefined
        )
        else
        (
            -- orientation anti-horaire (extérieur à droite du parcours, vu de dessus)
            local ar = 0.0

            for k = 1 to clean.count do
            (
                local k2 = k + 1

                if k2 > clean.count do k2 = 1

                ar = ar + (clean[k].x*clean[k2].y - clean[k2].x*clean[k].y)
            )

            if ar < 0.0 do clean = FR_ReverseArr clean

            -- le contour est posé dans le plan horizontal Z = 0
            for k = 1 to clean.count do clean[k].z = 0.0

            clean
        )
    )
)

-- repère de chaque segment : X le long, Y vers l'intérieur (extérieur à droite)
fn FR_ContourSegs pts =
(
    local segs = #()
    local n = pts.count

    for k = 1 to n do
    (
        local k2 = k + 1

        if k2 > n do k2 = 1

        local p1 = pts[k]
        local p2 = pts[k2]
        local ex = normalize (p2 - p1)
        local inw = normalize (cross [0,0,1] ex)

        append segs #((matrix3 ex inw [0,0,1] p1), (length (p2 - p1)))
    )

    segs
)

-- génère tout le contour : une façade par segment (sans piliers de bout),
-- une colonne d'angle sur chaque sommet, bandeaux/corniche/galerie prolongés jusqu'aux coins
fn FR_BuildContour pts segPRs root doMerge =
(
    local ok = true

    if pts.count < 3 or segPRs.count != pts.count then
    (
        FR_Msg "Contour incomplet : régénérez depuis le mode création."
        ok = false
    )

    if ok do
    (
        FR_CleanOrphans()

        FR_Pool = #()

        local bases = FR_ContourSegs pts

        -- hauteur totale commune (la verticale est la même pour tous les segments)
        local PR0 = segPRs[1]
        PR0.flH = FR_FitArr PR0.flH PR0.floors PR0.upperH

        local totalH = PR0.groundH

        for k = 1 to PR0.floors do totalH = totalH + PR0.flH[k]

        -- un segment de façade par côté du contour
        -- (si un segment plante, la géométrie partielle est supprimée avant de
        -- relancer l'erreur — sinon elle restait orpheline dans la scène)
        try
        (
            for k = 1 to pts.count do
            (
                FR_Ctx = "Segment " + (k as string) + " : "

                local kL = k - 1
                if kL < 1 do kL = pts.count

                local kR = k + 1
                if kR > pts.count do kR = 1

                -- marge d'angle : demi-colonne la plus large des deux coins
                local cL = amax #(segPRs[kL].pier, segPRs[k].pier, PR0.depth*2.0)
                local cR = amax #(segPRs[k].pier, segPRs[kR].pier, PR0.depth*2.0)
                local ext = amax #(cL, cR) / 2.0

                if (FR_Generate segPRs[k] bases[k][1] noEndPiers:true endExt:ext noRoof:true) != true do ok = false
            )
        )
        catch
        (
            for n in FR_Pool do ( if isValidNode n do delete n )
            FR_Pool = #()
            FR_Ctx = ""
            throw()
        )

        FR_Ctx = ""

        -- colonnes d'angle, centrées sur chaque sommet du contour
        if ok do
        (
            local pierMat = FR_Material "FRAMER_Piers" PR0.colPier 100 apply:true

            for k = 1 to pts.count do
            (
                local kL = k - 1
                if kL < 1 do kL = pts.count

                local kR = k + 1
                if kR > pts.count do kR = 1

                local cS = amax #(segPRs[kL].pier, segPRs[kR].pier, PR0.depth*2.0)

                FR_Box ("FRAMER_Corner_"+(k as string)) [pts[k].x, pts[k].y, totalH/2] (matrix3 1) cS cS totalH pierMat
            )
        )

        -- toit du contour (terrasse : polygone exact ; pentes : rectangle englobant)
        -- 0.6.15 : l'appel toit est DANS un try/catch avec nettoyage du pool — avant,
        -- une erreur pendant le toit laissait la dalle fraîchement créée non parentée
        -- (dalle orpheline flottant dans la scène jusqu'au nettoyage suivant).
        if ok and PR0.roofMode != "None" do
        (
            try
            (
                FR_RoofContour pts segPRs bases totalH
            )
            catch
            (
                for n in FR_Pool do ( if isValidNode n do delete n )
                FR_Pool = #()
                FR_Ctx = ""
                throw()
            )
        )

        if ok do
        (
            local nodes = FR_Pool

            if doMerge do nodes = FR_Merge (root.transform) root.name

            local oldKids = for c in root.children where (matchPattern c.name pattern:"FRAMER_*") collect c

            if oldKids.count > 0 do delete oldKids

            for n in nodes do
            (
                if isValidNode n do n.parent = root
            )

            setUserPropBuffer root (FR_ContourToString pts segPRs)

            FR_Summary = "Contour : " + (pts.count as string) + " segments | " + FR_Summary
        )

        if not ok do
        (
            -- échec : on supprime ce qui vient d'être créé, l'ancienne façade reste intacte
            for n in FR_Pool do
            (
                if isValidNode n do delete n
            )

            FR_Pool = #()
        )
    )

    ok
)

/* =========================================================
   FACE QUADRANGULAIRE SÉLECTIONNÉE
   Renvoie #(basis, largeur, hauteur) ou undefined
========================================================= */

fn FR_GetSelectedFace obj =
(
    local result = undefined

    if classof obj != Editable_Poly then
    (
        messageBox "L'objet sélectionné doit être un Editable Poly."
    )
    else
    (
        local fs = polyop.getFaceSelection obj

        if fs.numberSet != 1 then
        (
            messageBox "Sélectionnez exactement un polygone."
        )
        else
        (
            local faceIndex = (fs as array)[1]
            local ids = polyop.getFaceVerts obj faceIndex

            if ids.count != 4 then
            (
                messageBox "Le polygone sélectionné doit être un quadrilatère."
            )
            else
            (
                -- polyop.getVert sur un node renvoie déjà des coordonnées MONDE : ne pas re-transformer
                local pts = for id in ids collect (in coordsys world (polyop.getVert obj id))

                local edgeX = normalize (pts[2]-pts[1])
                local edgeZRaw = pts[4]-pts[1]

                -- repère direct (X = bas de la face, Y = vers l'intérieur, Z = haut)
                local normal = normalize (cross (pts[2]-pts[1]) (pts[4]-pts[1]))
                local inw = -normal
                local up = normalize (cross edgeX inw)

                -- la face a pu être parcourue dans l'autre sens : on redresse
                if up.z < 0.0 do
                (
                    inw = -inw
                    up = normalize (cross edgeX inw)
                )

                result = #(matrix3 edgeX inw up pts[1], (length (pts[2]-pts[1])), (length edgeZRaw))
            )
        )
    )

    result
)

/* =========================================================
   GUIDES D'ÉTAGES : lignes éditables à chaque niveau, sur le plan des piliers
   (version contour : une ligne par segment et par niveau)
========================================================= */

fn FR_MakeGuides root =
(
    local nSeg = FR_ContourCount root

    if nSeg > 1 then
    (
        local cd = FR_ContourFromString (getUserPropBuffer root)
        local pts = cd[1]
        local segs = cd[2]

        if pts.count >= 3 and segs.count == pts.count then
        (
            local PR0 = segs[1]
            PR0.flH = FR_FitArr PR0.flH PR0.floors PR0.upperH

            local zs = #(0.0, PR0.groundH)

            for k = 1 to PR0.floors do append zs (zs[k+1] + PR0.flH[k])

            local bases = FR_ContourSegs pts

            for s = 1 to pts.count do
            (
                local b = bases[s][1]
                local w = bases[s][2]
                local pf = b[4] + b[2]*(-segs[s].depth)

                for k = 1 to zs.count do
                (
                    local sname = "Guide_" + root.name + "_S" + (s as string) + "_" + (k as string)
                    local old = for o in objects where o.name == sname collect o

                    if old.count > 0 do delete old

                    local ln = splineShape name:sname
                    addNewSpline ln
                    addKnot ln 1 #corner #line (pf + b[3]*zs[k])
                    addKnot ln 1 #corner #line (pf + b[1]*w + b[3]*zs[k])
                    updateShape ln
                    ln.wirecolor = color 255 230 0
                    ln.parent = root
                )
            )

            FR_Summary = "Guides : " + (pts.count as string) + " segments x " + (zs.count as string) + " niveaux"
        )
    )
    else
    (
        local PR = FR_ParamsFromString (getUserPropBuffer root)

        PR.flH = FR_FitArr PR.flH PR.floors PR.upperH

        local zs = #(0.0, PR.groundH)

        for k = 1 to PR.floors do append zs (zs[k+1] + PR.flH[k])

        local b = root.transform

        for k = 1 to zs.count do
        (
            local sname = "Guide_" + root.name + "_" + (k as string)
            local old = for o in objects where o.name == sname collect o

            if old.count > 0 do delete old

            local ln = splineShape name:sname
            addNewSpline ln
            addKnot ln 1 #corner #line (b[4] + b[2]*(-PR.depth) + b[3]*zs[k])
            addKnot ln 1 #corner #line (b[4] + b[1]*PR.width + b[2]*(-PR.depth) + b[3]*zs[k])
            updateShape ln
            ln.wirecolor = color 255 230 0
            ln.parent = root
        )

        FR_Summary = "Guides : " + (zs.count as string) + " niveaux"
    )
)

-- profil de moulure : petit carré de 10 cm, sommets à éditer en vue de dessus
fn FR_MakeProfile =
(
    local ed = 0.1
    local s = splineShape name:(uniqueName "FRAMER_Profil_")

    addNewSpline s
    addKnot s 1 #corner #line [0,0,0]
    addKnot s 1 #corner #line [ed,0,0]
    addKnot s 1 #corner #line [ed,ed,0]
    addKnot s 1 #corner #line [0,ed,0]
    close s 1
    updateShape s

    s.wirecolor = color 255 230 0

    s
)

-- lit les sommets du profil (coordonnées locales), mis à l'échelle sc, en sens anti-horaire
fn FR_ReadProfile node sc =
(
    local pts = #()

    if (numSplines node) >= 1 do
    (
        for k = 1 to (numKnots node 1) do
        (
            local kp = in coordsys local (getKnotPoint node 1 k)

            append pts [kp.x*sc, kp.y*sc]
        )
    )

    local ar = 0.0

    for k = 1 to pts.count do
    (
        local k2 = k + 1

        if k2 > pts.count do k2 = 1

        ar = ar + (pts[k].x*pts[k2].y - pts[k2].x*pts[k].y)
    )

    if ar < 0.0 do pts = FR_ReverseArr pts

    pts
)

-- lit les sommets de la ligne en coordonnées monde ; renvoie #(points, fermée?)
fn FR_ReadPath node =
(
    local pts = #()

    if (numSplines node) >= 1 do
    (
        -- getKnotPoint renvoie déjà des coordonnées MONDE : ne pas re-transformer
        for k = 1 to (numKnots node 1) do append pts (in coordsys world (getKnotPoint node 1 k))
    )

    local cl = false

    try (cl = isClosed node 1) catch (cl = false)

    #(pts, cl)
)

-- balaie le profil (a = saillie, b = hauteur) le long de la ligne, angles en onglet.
-- Sens : l'extérieur est à DROITE du sens de parcours, vu de dessus.
fn FR_SweepMesh pts prof isCl =
(
    local n = pts.count
    local m = prof.count
    local vArr = #()
    local fArr = #()
    local segN = n - 1

    if isCl do segN = n

    -- normale extérieure de chaque segment
    local outs = #()

    for k = 1 to segN do
    (
        local k2 = k + 1

        if k2 > n do k2 = 1

        local d = pts[k2] - pts[k]

        d.z = 0.0
        d = normalize d

        append outs (cross d [0,0,1])
    )

    -- anneaux de sommets (une copie du profil à chaque sommet de la ligne)
    for i = 1 to n do
    (
        local oPrev = outs[1]
        local oNext = outs[1]

        if isCl then
        (
            local ip = i - 1

            if ip < 1 do ip = n

            oPrev = outs[ip]
            oNext = outs[i]
        )
        else
        (
            if i == n then
            (
                oPrev = outs[segN]
                oNext = outs[segN]
            )
            else if i > 1 then
            (
                oPrev = outs[i-1]
                oNext = outs[i]
            )
        )

        local nv = oPrev + oNext

        if (length nv) < 0.0001 then
            nv = oNext
        else
            nv = normalize nv

        -- onglet : on allonge le décalage pour garder l'épaisseur constante dans les angles
        local dp = dot nv oNext

        if dp < 0.25 do dp = 0.25

        local kf = 1.0 / dp

        for j = 1 to m do append vArr (pts[i] + nv*(prof[j].x*kf) + [0,0,prof[j].y])
    )

    -- faces latérales
    for k = 1 to segN do
    (
        local k2 = k + 1

        if k2 > n do k2 = 1

        for j = 1 to m do
        (
            local j2 = j + 1

            if j2 > m do j2 = 1

            local a1 = (k-1)*m + j
            local a2 = (k2-1)*m + j
            local a3 = (k2-1)*m + j2
            local a4 = (k-1)*m + j2

            append fArr [a1,a2,a3]
            append fArr [a1,a3,a4]
        )
    )

    -- bouchons aux extrémités (en éventail : corrects pour un profil convexe)
    if not isCl do
    (
        local b0 = (n-1)*m

        for j = 2 to (m-1) do
        (
            append fArr [1, j, j+1]
            append fArr [b0+1, b0+j+1, b0+j]
        )
    )

    local msh = mesh vertices:vArr faces:fArr

    update msh
    FR_NoSmooth msh

    msh
)

fn FR_DoMoulding profNode sc dz flip =
(
    local pathObj = undefined

    if selection.count == 1 do pathObj = selection[1]

    if pathObj == undefined or (superclassof pathObj) != shape then
    (
        messageBox "Sélectionnez une seule ligne (spline), par exemple un guide d'étage."
    )
    else if profNode == undefined or not (isValidNode profNode) or (superclassof profNode) != shape then
    (
        messageBox "Choisissez d'abord le profil (spline)."
    )
    else
    (
        local prof = FR_ReadProfile profNode sc
        local pd = FR_ReadPath pathObj
        local pts = pd[1]
        local isCl = pd[2]

        if prof.count < 3 or pts.count < 2 then
        (
            messageBox "Il faut au moins 3 sommets pour le profil et 2 pour la ligne."
        )
        else
        (
            for k = 1 to pts.count do pts[k] = pts[k] + [0,0,dz]

            -- une boucle fermée est orientée vers l'extérieur, quel que soit son sens de dessin
            local rev = flip

            if isCl do
            (
                local ar = 0.0

                for k = 1 to pts.count do
                (
                    local k2 = k + 1

                    if k2 > pts.count do k2 = 1

                    ar = ar + (pts[k].x*pts[k2].y - pts[k2].x*pts[k].y)
                )

                if ar < 0.0 do rev = not rev
            )

            if rev do pts = FR_ReverseArr pts

            local mname = "Moulure_" + pathObj.name
            local oldM = for o in objects where o.name == mname collect o

            if oldM.count > 0 do delete oldM

            undo "Moulure FRAMER" on
            (
                local msh = FR_SweepMesh pts prof isCl

                msh.name = mname
                msh.material = FR_Material "FRAMER_Moulding" (color 200 196 188) 100
                msh.wirecolor = color 200 196 188

                if pathObj.parent != undefined do msh.parent = pathObj.parent
            )
        )
    )
)

/* ----- presets : fichiers de réglages dans plugcfg\FRAMER\presets ----- */

fn FR_PresetDir =
(
    local d = (getDir #plugcfg) + "\\FRAMER\\presets"

    if not doesFileExist d do makeDir d all:true

    d
)

fn FR_PresetCleanName nm =
(
    local bad = "\\\\/*:?\"<>|"
    local out = ""

    if nm == undefined do nm = ""
    nm = trimLeft (trimRight nm)

    -- une chaîne (vide ou pas) n'est PAS itérable en MAXScript ("No "map" function") :
    -- on parcourt par index
    for i = 1 to nm.count do
    (
        local c = substring nm i 1
        out += if (findString bad c) == undefined then c else "_"
    )

    out
)

fn FR_PresetFile nm = (FR_PresetDir()) + "\\" + nm + ".framer"

fn FR_PresetNames =
(
    sort (for f in getFiles ((FR_PresetDir()) + "\\*.framer") collect (getFilenameFile f))
)

-- filtre des pickbuttons de splines
fn FR_ShapeFilter o = (superclassof o == shape)

/* =========================================================
   INTERFACE (6 onglets)
========================================================= */

rollout FRAMER_UI "FRAMER | Générateur de façades 0.6.18" width:430
(
    -- valeurs par étage du mode "indépendants" : variables globales FR_gH, FR_gMode, ... (voir plus haut)
    local curFloor = 1
    local flCustom = false   -- true si des valeurs par étage ont été saisies (mode indépendant)

    /* ----- bandeau du haut : mode de travail ----- */

    groupBox gbWork "Mode de travail" pos:[10,6] width:410 height:118
    radioButtons rbWork labels:#("CRÉATION : générer une nouvelle façade","ÉDITION : modifier la façade sélectionnée") columns:1 default:1 pos:[25,26] tooltip:"Création : génère une nouvelle façade. Édition : sélectionnez une façade, elle se charge et les réglages s'appliquent à elle."
    label lbEdit "Nouvelle façade : réglez puis cliquez sur Générer." pos:[25,70] width:390 height:18
    checkbox cbLive "Mise à jour en direct (mode édition)" pos:[25,92] checked:false tooltip:"Applique chaque réglage tout de suite à la façade sélectionnée."
    -- LISERET de mode : barre bleue en CRÉATION, orange vif en ÉDITION
    -- (progressBar détournée en bandeau coloré, toujours pleine)
    progressBar pbModeBar pos:[25,112] width:380 height:8 value:100 color:(color 120 150 190)

    -- libellés courts : 7 onglets tiennent dans la largeur (Moulures était tronqué)
    radioButtons rbTab labels:#("Gén.","Rdc","Étag.","Fen.","Toit","Hasard","Moul.") columns:7 default:1 pos:[18,132] tooltip:"Pages de réglages : Général, Rez-de-chaussée, Étages, Fenêtres, Toit, Hasard (variation aléatoire), Moulures."

    /* ----- onglet 1 : Général ----- */

    groupBox gb1 "Génération (création uniquement)" pos:[10,160] width:410 height:112
    radioButtons rbMode labels:#("À partir de dimensions","Sur une face sélectionnée","Le long d'un contour fermé") columns:1 default:1 pos:[22,180] tooltip:"Dimensions : façade libre. Face : la façade épouse un quadrilatère sélectionné. Contour : tout un bâtiment le long d'une spline fermée, un style par segment."
    pickbutton pbCont "Choisir le contour (spline fermée)" pos:[25,244] width:380 height:24 filter:FR_ShapeFilter autoDisplay:true message:"Cliquez sur la spline fermée du contour" tooltip:"Spline FERMÉE posée au sol (vue de dessus) : chaque segment devient une façade avec ses propres réglages."
    groupBox gb2 "Dimensions" pos:[10,280] width:410 height:84
    label l_spLength "Longueur :" pos:[25,306] width:185 height:16
    spinner spLength "" pos:[215,304] width:190 range:[2,500,24] type:#float scale:0.1 tooltip:"Longueur totale de la façade (mode dimensions ; en mode contour, longueur visée du premier segment, qui sert à calculer le pas des travées)."
    label l_spGround "Hauteur du rez-de-chaussée :" pos:[25,334] width:185 height:16
    spinner spGround "" pos:[215,332] width:190 range:[2,30,4.2] type:#float scale:0.1 tooltip:"Hauteur du rez-de-chaussée. En mode face, sert de proportion."
    groupBox gb4 "Structure et options" pos:[10,372] width:410 height:180
    label l_spBays "Nombre de travées :" pos:[25,398] width:185 height:16
    spinner spBays "" pos:[215,396] width:190 range:[1,80,6] type:#integer tooltip:"Nombre de travées (colonnes de fenêtres) entre les piliers."
    label l_spPier "Largeur des piliers :" pos:[25,426] width:185 height:16
    spinner spPier "" pos:[215,424] width:190 range:[0.05,5,0.35] type:#float scale:0.05 tooltip:"Largeur des piliers entre les travées."
    label l_spDepth "Profondeur de façade :" pos:[25,454] width:185 height:16
    spinner spDepth "" pos:[215,452] width:190 range:[0.02,3,0.25] type:#float scale:0.05 tooltip:"Saillie des piliers et des bandeaux. Le mur est en retrait de la moitié de cette valeur."
    label l_spFrame "Largeur des cadres :" pos:[25,482] width:185 height:16
    spinner spFrame "" pos:[215,480] width:190 range:[0.01,1,0.07] type:#float scale:0.01 tooltip:"Épaisseur des cadres de fenêtres et des bandeaux."
    checkbox cbCornice "Corniche en haut" pos:[25,508] checked:true tooltip:"Ajoute une corniche en haut de la façade."
    checkbox cbMerge "Fusionner en un objet par matériau" pos:[25,528] checked:true tooltip:"Regroupe la façade en un objet par matériau (plus léger). Décoché : chaque élément reste séparé."
    groupBox gbCol "Couleurs des matériaux" pos:[10,560] width:410 height:120
    label l_cpWall "Murs :" pos:[25,584] width:80 height:16
    colorPicker cpWall "" color:(color 214 204 188) pos:[110,582] width:90 height:18 tooltip:"Couleur des murs et bandeaux (matériau FRAMER_Walls)."
    label l_cpFrame "Menuiseries :" pos:[210,584] width:100 height:16
    colorPicker cpFrame "" color:(color 55 62 70) pos:[315,582] width:90 height:18 tooltip:"Couleur des cadres et casquettes (matériau FRAMER_Frame)."
    label l_cpPier "Piliers :" pos:[25,610] width:80 height:16
    colorPicker cpPier "" color:(color 135 138 142) pos:[110,608] width:90 height:18 tooltip:"Couleur des piliers, colonnes et corniche (matériau FRAMER_Piers)."
    label l_cpGlass "Verre :" pos:[210,610] width:100 height:16
    colorPicker cpGlass "" color:(color 95 170 205) pos:[315,608] width:90 height:18 tooltip:"Couleur du verre (matériau FRAMER_Glass, translucide)."
    label l_cpDoor "Portes :" pos:[25,636] width:80 height:16
    colorPicker cpDoor "" color:(color 95 72 52) pos:[110,634] width:90 height:18 tooltip:"Couleur des portes (matériau FRAMER_Door)."
    label l_cpShut "Volets :" pos:[210,636] width:100 height:16
    colorPicker cpShut "" color:(color 172 166 152) pos:[315,634] width:90 height:18 tooltip:"Couleur des volets (matériau FRAMER_Shutters)."
    label l_cpRoof "Toit :" pos:[25,662] width:80 height:16
    colorPicker cpRoof "" color:(color 122 84 66) pos:[110,660] width:90 height:18 tooltip:"Couleur du toit (matériau FRAMER_Roof)."
    label l_cpPanel "Panneaux :" pos:[210,662] width:100 height:16
    colorPicker cpPanel "" color:(color 190 188 178) pos:[315,660] width:90 height:18 tooltip:"Couleur des panneaux pleins/vitrés (matériau FRAMER_Panels)."

    /* ----- onglet 2 : Étages ----- */

    groupBox gb3 "Étages" pos:[10,160] width:410 height:150
    label l_spFloors "Nombre d'étages :" pos:[25,186] width:185 height:16
    spinner spFloors "" pos:[215,184] width:190 range:[1,60,3] type:#integer tooltip:"Nombre d'étages au-dessus du rez-de-chaussée."
    -- un seul des deux modes à la fois
    radioButtons rbFloors labels:#("Identiques (une même hauteur et composition)","Indépendants (réglage étage par étage)") columns:1 default:1 pos:[22,212] tooltip:"Identiques : un seul réglage pour tous les étages. Indépendants : chaque étage a sa hauteur, son type, ses fenêtres et son balcon."
    label l_spFloorSel "Étage n° :" pos:[25,254] width:185 height:16
    spinner spFloorSel "" pos:[215,252] width:190 range:[1,3,1] type:#integer tooltip:"Étage dont vous modifiez les réglages (mode indépendants)." enabled:false
    button btCopyAll "Appliquer cet étage à tous" pos:[25,278] width:380 height:22 tooltip:"Copie les réglages de l'étage affiché sur tous les autres étages." enabled:false
    groupBox gb5 "Réglages de l'étage affiché" pos:[10,318] width:410 height:344
    label l_spUpper "Hauteur de l'étage :" pos:[25,344] width:185 height:16
    spinner spUpper "" pos:[215,342] width:190 range:[2,15,3] type:#float scale:0.1 tooltip:"Hauteur de l'étage affiché (de tous les étages en mode identiques)."
    dropdownList ddUpper "Type de l'étage :" pos:[25,370] width:380 items:#("Fenêtres","Panneaux vitrés","Panneaux pleins","Mur plein","Maison de ville (volets battants)") selection:1 tooltip:"Fenêtres dans un mur, panneaux vitrés, panneaux pleins, mur plein, ou maison de ville : fenêtres avec volets battants à deux vantaux (ouverture réglée par « Ouverture du volet »)."
    label l_spPanOp "Panneaux pleins (% des travées) :" pos:[25,422] width:185 height:16
    spinner spPanOp "" pos:[215,420] width:190 range:[0,100,100] type:#float scale:1 tooltip:"Pour le type « Panneaux pleins » : part des travées à panneau plein, les autres reçoivent un panneau VITRÉ (tirage au hasard par travée). 100 % : tous pleins. 0 % : tous vitrés."
    label l_spWinW "Largeur fenêtre (% travée) :" pos:[25,450] width:185 height:16
    spinner spWinW "" pos:[215,448] width:190 range:[20,100,70] type:#float scale:1 tooltip:"Largeur de la fenêtre en pourcentage de la largeur de la travée."
    label l_spWinH "Hauteur fenêtre :" pos:[25,478] width:185 height:16
    spinner spWinH "" pos:[215,476] width:190 range:[0.3,4,1.5] type:#float scale:0.05 tooltip:"Hauteur de la fenêtre."
    label l_spSill "Hauteur d'allège :" pos:[25,506] width:185 height:16
    spinner spSill "" pos:[215,504] width:190 range:[0,3,0.9] type:#float scale:0.05 tooltip:"Hauteur entre le sol de l'étage et le bas de la fenêtre."
    dropdownList ddBalc "Balcons de l'étage :" pos:[25,532] width:380 items:#("Aucun","Saillants","Rentrants (loggias)","Filant (continu)","Bow-windows","Bow simple (rectangulaire)","Mix (par travée)") selection:2 tooltip:"Aucun, saillants, rentrants (loggias), filants (dalle continue), bow-windows (oriels vitrés en 3 facettes), bow simple (saillie rectangulaire sans joues inclinées), ou MIX : chaque travée de l'étage tire au hasard balcon saillant, loggia ou rien (rythme par travée, comme un vrai immeuble)."
    label l_spBalcVar "Variation de profondeur (± %) :" pos:[25,576] width:185 height:16
    spinner spBalcVar "" pos:[215,574] width:190 range:[0,80,0] type:#float scale:1 tooltip:"Variation ALÉATOIRE de la profondeur des balcons et loggias, en ± % autour de la profondeur réglée (0 = profondeur fixe). Tirage par travée. En mode indépendants, ce réglage est PROPRE À L'ÉTAGE affiché (étage n° ci-dessus)."
    label l_spBalcD "Profondeur balcon / loggia :" pos:[25,602] width:185 height:16
    spinner spBalcD "" pos:[215,600] width:190 range:[0.3,2.5,0.8] type:#float scale:0.05 tooltip:"Profondeur des balcons saillants et des loggias. En mode indépendants, ce réglage est PROPRE À L'ÉTAGE affiché (étage n° ci-dessus)."
    label l_spSlabTh "Épaisseur des dalles (m) :" pos:[25,628] width:185 height:16
    spinner spSlabTh "" pos:[215,626] width:190 range:[0.08,0.6,0.30] type:#float scale:0.01 tooltip:"Épaisseur des dalles de balcons. 0,30 : dalle épaisse qui se lit comme une casquette à chaque niveau (0.6.7). 0,15 : dalle fine."
    label l_spMixOut "Mix : balcons (% travées) :" pos:[25,654] width:185 height:16
    spinner spMixOut "" pos:[215,652] width:190 range:[0,100,40] type:#float scale:1 tooltip:"Utilisé quand un étage est en Mix (par travée) : pourcentage de travées avec balcon SAILLANT. Le reste se répartit entre loggias et travées sans balcon. Le tirage dépend de la graine (onglet Gén.)."
    label l_spMixIn "Mix : loggias (% travées) :" pos:[25,680] width:185 height:16
    spinner spMixIn "" pos:[215,678] width:190 range:[0,100,30] type:#float scale:1 tooltip:"Utilisé quand un étage est en Mix (par travée) : pourcentage de travées avec LOGGIA (balcon rentrant). Le reste des travées reste plein (fenêtres sans balcon)."

    /* ----- onglet 3 : Rez-de-chaussée ----- */

    groupBox gb7 "Rez-de-chaussée" pos:[10,160] width:410 height:252
    dropdownList ddGround "Type du rez-de-chaussée :" pos:[25,182] width:380 items:#("Vitrine","Porte + vitrage","Alternance vitrine / porte","Panneaux pleins","Travée vide (passage)","Arcades en arc","Portique à colonnes (type Perret)","Maison de ville (porte + fenêtres)") selection:1 tooltip:"Composition du rez-de-chaussée."
    dropdownList ddArc "Forme des arcades :" pos:[25,232] width:380 items:#("Plein cintre","Arc surbaissé","Linteau droit (portique)") selection:1 tooltip:"Forme des ouvertures des arcades (type Perret, Le Havre)."
    label l_spArcR "Retrait de la vitrine :" pos:[25,286] width:185 height:16
    spinner spArcR "" pos:[215,284] width:190 range:[0.5,6,2] type:#float scale:0.1 tooltip:"Retrait de la vitrine derrière les arcades (galerie couverte)."
    label l_spArcL "Bande pleine au-dessus :" pos:[25,314] width:185 height:16
    spinner spArcL "" pos:[215,312] width:190 range:[0.2,3,0.6] type:#float scale:0.05 tooltip:"Hauteur de mur plein entre le haut des arcades et le bandeau."
    checkbox cbArcGl "Vitrines en arc (suivent l'arche)" pos:[25,342] checked:true tooltip:"Coché : le vitrage de la galerie suit la forme de l'arche. Décoché : vitrines rectangulaires."
    label l_spDoorH "Hauteur des portes :" pos:[25,368] width:185 height:16
    spinner spDoorH "" pos:[215,366] width:190 range:[2,6,3] type:#float scale:0.05 tooltip:"Hauteur commune de toutes les portes du rez-de-chaussée (seule la largeur varie). 2,05 m minimum pour une maison de ville, 3,00 m pour un magasin ou un grand immeuble."
    label l_spDoorN "Nombre de portes (alternance) :" pos:[25,394] width:185 height:16
    spinner spDoorN "" pos:[215,392] width:190 range:[0,20,0] type:#integer scale:1 tooltip:"Pour le type « Alternance vitrine / porte » : nombre de PORTES parmi les travées, réparties régulièrement (vitrines entre les portes). 0 = automatique : une porte sur deux. Exemple : 6 travées, 2 portes = V V P V V P."
    groupBox gb9 "Travée d'entrée" pos:[10,436] width:410 height:106
    dropdownList ddEntrance "Position de l'entrée :" pos:[25,424] width:380 items:#("Aucune","Centre","Gauche","Droite","Aléatoire") selection:2 tooltip:"Position de la travée d'entrée : plus large, avec porte, vitrages, imposte et auvent."
    label l_spEntW "Largeur de l'entrée (facteur) :" pos:[25,478] width:185 height:16
    spinner spEntW "" pos:[215,476] width:190 range:[1,3,1.6] type:#float scale:0.1 tooltip:"Largeur de la travée d'entrée par rapport aux autres."

    /* ----- onglet 4 : Fenêtres (garde-corps, volets, casquettes) ----- */

    groupBox gb10 "Garde-corps de fenêtres" pos:[10,160] width:410 height:120
    dropdownList ddRail "Type :" pos:[25,182] width:380 items:#("Aucun","Vitré","Barreaudé","Plein","Lisse seule") selection:1 tooltip:"Garde-corps devant l'allège des fenêtres à allège. Lisse seule : juste la main courante, sans remplissage."
    label l_spRailH "Hauteur du garde-corps :" pos:[25,232] width:185 height:16
    spinner spRailH "" pos:[215,230] width:190 range:[0.3,2,1.0] type:#float scale:0.05 tooltip:"Hauteur du garde-corps, limitée à la hauteur de la fenêtre."
    label l_spRailD "Saillie du garde-corps :" pos:[25,260] width:185 height:16
    spinner spRailD "" pos:[215,258] width:190 range:[0.05,0.5,0.15] type:#float scale:0.05 tooltip:"Saillie du garde-corps devant la façade."
    groupBox gb11 "Volets roulants (simulés)" pos:[10,288] width:410 height:110
    label l_spShutPct "Probabilité (% des fenêtres) :" pos:[25,314] width:185 height:16
    spinner spShutPct "" pos:[215,312] width:190 range:[0,100,0] type:#float scale:1 tooltip:"Part des fenêtres qui reçoivent un volet roulant (coffre + panneau)."
    label l_spShutOpen "Ouverture du volet (%) :" pos:[25,342] width:185 height:16
    spinner spShutOpen "" pos:[215,340] width:190 range:[0,100,50] type:#float scale:1 tooltip:"0 % : volet fermé. 100 % : volet remisé dans le coffre."
    label lbShutHelp "Le coffre reste visible même volet ouvert." pos:[25,368] width:380 height:16
    groupBox gb12 "Casquettes / brise-soleil" pos:[10,406] width:410 height:140
    dropdownList ddCap "Type :" pos:[25,428] width:380 items:#("Aucune","Casquette (dalle)","Brise-soleil (lames)") selection:1 tooltip:"Dalle en porte-à-faux ou lames horizontales au-dessus des fenêtres."
    label l_spCapD "Profondeur :" pos:[25,478] width:185 height:16
    spinner spCapD "" pos:[215,476] width:190 range:[0.1,1.5,0.4] type:#float scale:0.05 tooltip:"Saillie de la casquette ou des lames."
    label l_spCapPct "Probabilité (% des fenêtres) :" pos:[25,506] width:185 height:16
    spinner spCapPct "" pos:[215,504] width:190 range:[0,100,100] type:#float scale:1 tooltip:"100 % : toutes les fenêtres. Sinon, tirage au hasard par travée."
    groupBox gb13 "Encadrement des baies (moulure)" pos:[10,554] width:410 height:130
    checkbox cbSurr "Encadrer les baies (étages et rdc)" pos:[25,578] tooltip:"Balaie une moulure d'assemblage autour de chaque ouverture."
    pickbutton pbSurrProf "Profil : (carré par défaut)" pos:[25,604] width:380 height:24 filter:FR_ShapeFilter autoDisplay:true message:"Cliquez sur la spline du profil" tooltip:"Spline du profil de la moulure (créable avec « Créer un profil carré », onglet Moulures). Sans spline : profil carré par défaut."
    label l_spSurrS "Échelle du profil :" pos:[25,642] width:185 height:16
    spinner spSurrS "" pos:[215,640] width:190 range:[0.05,20,1] type:#float scale:0.05 tooltip:"Échelle appliquée au profil de la moulure."
    label lbSurrHelp "Profil : x = largeur depuis la baie, y = saillie vers la rue. Sans spline : bande 7 cm, saillie 8 cm." pos:[25,668] width:380 height:16

    /* ----- onglet 5 : Toit ----- */

    groupBox gbRoof "Toit" pos:[10,160] width:410 height:250
    dropdownList ddRoof "Type de toit :" pos:[25,182] width:380 items:#("Aucun","Terrasse + acrotère","Deux pentes (pignons)","Quatre pans (croupes)","Mansard (brisis + terrasson)") selection:1 tooltip:"Aucun : façade nue. Terrasse : dalle + acrotère (remplace la corniche). Deux ou quatre pans : toiture en pente. Mansard : brisis raide (pente principale) + terrasson doux + plateau plat au sommet."
    label l_spRoofPitch "Pente (degrés) :" pos:[25,232] width:185 height:16
    spinner spRoofPitch "" pos:[215,230] width:190 range:[10,80,30] type:#float scale:1 tooltip:"Pente des versants (toits à deux ou quatre pans). Pour un mansard, monter à 60-75° : c'est la pente raide du brisis."
    label l_spRoofOver "Débord du toit :" pos:[25,260] width:185 height:16
    spinner spRoofOver "" pos:[215,258] width:190 range:[0,2,0.5] type:#float scale:0.05 tooltip:"Saillie du toit au-delà des murs. En mode contour : le contour est décalé vers l'EXTÉRIEUR de cette valeur pour dessiner le toit (fond fermé vu de dessous)."
    label l_spRoofPar "Hauteur de l'acrotère :" pos:[25,288] width:185 height:16
    spinner spRoofPar "" pos:[215,286] width:190 range:[0,2,0.5] type:#float scale:0.05 tooltip:"Garde-corps plein autour de la terrasse (toit-terrasse uniquement)."
    label l_spRoofDepth "Profondeur du bâtiment :" pos:[25,316] width:185 height:16
    spinner spRoofDepth "" pos:[215,314] width:190 range:[2,60,8] type:#float scale:0.5 tooltip:"Profondeur couverte derrière la façade (façade simple ; en mode contour, le toit couvre tout le polygone)."
    label l_spAcrTh "Épaisseur de l'acrotère :" pos:[25,342] width:185 height:16
    spinner spAcrTh "" pos:[215,340] width:190 range:[0.1,2,0.55] type:#float scale:0.05 tooltip:"Épaisseur de la couronne de l'acrotère (toit-terrasse « en bac »)."
    label l_spAcrGorge "Gorge intérieure :" pos:[25,368] width:185 height:16
    spinner spAcrGorge "" pos:[215,366] width:190 range:[0,2,0.4] type:#float scale:0.05 tooltip:"Creux intérieur : le plateau de la terrasse descend de cette valeur sous le sommet de l'acrotère (acrotère en bac, avec sa gorge)."
    label l_spMansP2 "Pente du terrasson (°) :" pos:[25,448] width:185 height:16
    spinner spMansP2 "" pos:[215,446] width:190 range:[5,60,30] type:#float scale:1 tooltip:"Pente douce du terrasson (haut du toit mansardé). Le brisis utilise la pente principale ci-dessus (à monter à 60-75° pour un vrai mansard)."
    label l_spMansTop "Largeur du toit plat (m) :" pos:[25,474] width:185 height:16
    spinner spMansTop "" pos:[215,472] width:190 range:[0.5,20,2] type:#float scale:0.1 tooltip:"Largeur du plateau plat au sommet du toit mansardé (entre les deux terrassons)."
    dropdownList ddRidge "Couvre-joint (faîtage) :" pos:[25,500] width:380 items:#("Aucun","Triangulaire","Arrondi (tuile faîtière)") selection:1 tooltip:"Couvre la jonction entre les versants : faîtage (deux pentes), faîtage + 4 arêtiers (quatre pans), arêtes du plateau (mansard). Triangulaire : sec et moderne. Arrondi : tuile faîtière traditionnelle."
    label l_spRidgeW "Largeur du couvre-joint :" pos:[25,550] width:185 height:16
    spinner spRidgeW "" pos:[215,548] width:190 range:[0.05,1,0.18] type:#float scale:0.01 tooltip:"Largeur du couvre-joint posé sur les jonctions de versants."
    label l_spRidgeH "Hauteur du couvre-joint :" pos:[25,576] width:185 height:16
    spinner spRidgeH "" pos:[215,574] width:190 range:[0.02,0.5,0.10] type:#float scale:0.01 tooltip:"Hauteur du couvre-joint au-dessus de la jonction."
    label lbRoofHelp "Le toit part du contour décalé vers l'extérieur (débord), fond fermé vu de dessous. Terrasse : dalle + acrotère suivant le contour. Deux/quatre pans : faîtage sur le plus long segment, versants suivant le contour (footprints convexes recommandés ; pas de pignons maçonnés en mode contour). Un toit remplace la corniche." pos:[25,394] width:380 height:48

    -- lucarnes du toit mansardé (0.6.17) — 0.6.18 : remontées au-dessus du bouton
    -- GÉNÉRER (y=700) avec lequel la ligne « Espacement » se superposait
    dropdownList ddLuc "Lucarnes (mansard) :" pos:[25,596] width:380 items:FR_LucCodes selection:1 tooltip:"Lucarnes posées sur le brisis du mansard (côté rue). Fronton : pignon triangulaire à cornice. Rectangulaire : toit en bâtière simple. Capucine : toit courbe (demi-cylindre). Alterné : une lucarne à toit en pente, puis une à toit arrondi — la répartition traditionnelle."
    label l_spLucW "Largeur des lucarnes :" pos:[25,620] width:185 height:16
    spinner spLucW "" pos:[215,618] width:190 range:[0.4,4,1.0] type:#float scale:0.05 tooltip:"Largeur du chevet de la lucarne."
    label l_spLucH "Hauteur des lucarnes :" pos:[25,644] width:185 height:16
    spinner spLucH "" pos:[215,642] width:190 range:[0.4,4,1.2] type:#float scale:0.05 tooltip:"Hauteur du chevet de la lucarne (du bas de la baie au départ du toit)."
    label l_spLucStep "Espacement :" pos:[25,668] width:185 height:16
    spinner spLucStep "" pos:[215,666] width:190 range:[0.5,10,3.0] type:#float scale:0.1 tooltip:"Distance entre deux lucarnes consécutives (centrage automatique sur la façade)."

    /* ----- onglet 6 : Variation ----- */

    groupBox gb6 "Variation aléatoire" pos:[10,160] width:410 height:250
    label l_spSeed "Graine :" pos:[25,187] width:185 height:16
    spinner spSeed "" pos:[215,185] width:100 range:[1,99999,1] type:#integer tooltip:"Graine du hasard : la même graine redonne la même façade."
    button btRoll "Tirer" pos:[325,184] width:80 height:20 tooltip:"Tire une graine au hasard."
    label l_spVar "Variation (% des travées) :" pos:[25,214] width:185 height:16
    spinner spVar "" pos:[215,212] width:190 range:[0,100,30] type:#float scale:1 tooltip:"Part des travées qui s'écartent de la fenêtre standard."
    label l_spWidthVar "Variation des largeurs (%) :" pos:[25,242] width:185 height:16
    spinner spWidthVar "" pos:[215,240] width:190 range:[0,60,10] type:#float scale:1 tooltip:"Variation aléatoire de la largeur des travées."
    checkbox cbWide "Autoriser les porte-fenêtres" pos:[25,272] checked:true tooltip:"Certaines travées deviennent des porte-fenêtres."
    checkbox cbBalcony "Autoriser les travées à balcon" pos:[25,292] checked:false tooltip:"Certaines travées reçoivent un balcon en plus du réglage d'étage."
    checkbox cbWall "Autoriser les travées en mur plein" pos:[25,312] checked:false tooltip:"Certaines travées deviennent des murs pleins."
    label lbVarHelp "Même graine = même façade. Les variantes ne touchent que les étages de type Fenêtres. NB : les tirages de volets et casquettes décalent le hasard par rapport aux versions 0.5.x." pos:[25,340] width:380 height:30
    label l_spArcPct "Baies cintrées (% des fenêtres) :" pos:[25,376] width:185 height:16
    spinner spArcPct "" pos:[215,374] width:190 range:[0,100,0] type:#float scale:1 tooltip:"Part des fenêtres des étages à tête cintrée (plein cintre). Tirage au hasard par travée. 0 % : toutes rectangulaires. Pas de volets roulants ni de moulure d'encadrement sur les baies cintrées."

    /* ----- onglet 7 : Guides et moulures ----- */

    groupBox gb8 "Guides d'étages et moulures / lisses" pos:[10,160] width:410 height:300
    button btGuides "Créer les guides d'étages (façade sélectionnée)" pos:[25,184] width:380 height:24 tooltip:"Crée une ligne éditable à chaque niveau de la façade sélectionnée (pour un contour : une ligne par segment et par niveau)."
    button btProfile "Créer un profil carré (sommets à éditer)" pos:[25,214] width:380 height:24 tooltip:"Crée un profil carré : déplacez ses sommets pour modeler la moulure."
    pickbutton pbProf "Choisir le profil (spline)" pos:[25,244] width:380 height:24 filter:FR_ShapeFilter autoDisplay:true message:"Cliquez sur la spline du profil" tooltip:"Choisit la spline qui sert de profil de moulure."
    label l_spMoldScale "Échelle du profil :" pos:[25,282] width:185 height:16
    spinner spMoldScale "" pos:[215,280] width:190 range:[0.05,20,1] type:#float scale:0.05 tooltip:"Échelle du profil."
    label l_spMoldZ "Décalage vertical :" pos:[25,310] width:185 height:16
    spinner spMoldZ "" pos:[215,308] width:190 range:[-20,20,0] type:#float scale:0.05 tooltip:"Décalage vertical de la moulure par rapport à la ligne."
    checkbox cbMoldFlip "Inverser le sens (intérieur / extérieur)" pos:[25,338] checked:false tooltip:"Inverse le côté de la moulure."
    button btMold "GÉNÉRER LA MOULURE SUR LA LIGNE SÉLECTIONNÉE" pos:[25,364] width:380 height:30 tooltip:"Balaie le profil le long de la ligne sélectionnée."
    label lbMoldHelp "1) Créez les guides, ou dessinez une spline autour du bâtiment.  2) Créez et modelez le profil.  3) Sélectionnez la ligne, puis générez." pos:[25,402] width:380 height:48

    /* ----- bas de fenêtre ----- */

    button btGenerate "GÉNÉRER" pos:[10,700] width:205 height:32 tooltip:"Crée une nouvelle façade (ou tout le contour) avec les réglages affichés (mode création)."
    button btUpdate "METTRE À JOUR" pos:[215,700] width:205 height:32 tooltip:"Reconstruit la façade sélectionnée avec les réglages affichés (mode édition)."
    button btLoad "Charger la sélection" pos:[10,738] width:205 height:24 tooltip:"Charge dans la fenêtre les réglages de la façade sélectionnée."
    button btDelete "Supprimer la sélection" pos:[215,738] width:205 height:24 tooltip:"Supprime la façade sélectionnée."

    -- mode contour : réglages du segment affiché
    label l_spSeg "Segment n° :" pos:[15,772] width:110 height:16
    spinner spSeg "" pos:[130,770] width:80 range:[1,1,1] type:#integer tooltip:"Segment du contour dont vous modifiez les réglages (côté rue, côté jardin...)." enabled:false
    button btCopySeg "Appliquer ce segment à tous" pos:[230,768] width:190 height:22 tooltip:"Copie les réglages horizontaux du segment affiché sur tous les autres segments." enabled:false

    /* ----- presets ----- */

    groupBox gbPreset "Presets (réglages sauvegardés)" pos:[10,806] width:410 height:92
    dropdownList ddPreset "" pos:[25,826] width:320 items:#() tooltip:"Presets enregistrés. Sélectionnez-en un puis cliquez Charger."
    button btPresetRefresh "↻" pos:[350,824] width:28 height:22 tooltip:"Réactualise la liste des presets et affiche le dossier utilisé dans la barre d'infos."
    button btPresetBrowse "…" pos:[382,824] width:28 height:22 tooltip:"Charger un preset depuis n'importe quel dossier (parcourir…)."
    edittext etPresetName "Nom :" pos:[25,856] width:170 height:20 tooltip:"Nom du preset à sauvegarder (ou à charger s'il existe déjà)."
    button btPresetSave "Sauver" pos:[205,854] width:62 height:22 tooltip:"Sauvegarde tous les réglages affichés sous le nom saisi."
    button btPresetLoad "Charger" pos:[271,854] width:62 height:22 tooltip:"Charge le preset sélectionné dans la liste (ou celui dont le nom est saisi)."
    button btPresetDel "Suppr." pos:[337,854] width:62 height:22 tooltip:"Supprime le preset sélectionné dans la liste (ou celui dont le nom est saisi)."

    label lbInfo "Mode création." pos:[15,856] width:400 height:30
    label lbLegend "F fenêtre | P porte-fenêtre | B balcon | M mur plein" pos:[15,890] width:400 height:16

    -- affiche les contrôles de l'onglet n et cache les autres
    fn SetTab n =
    (
        -- ordre des onglets : 1 Général, 2 Rdc, 3 Étages, 4 Fenêtres, 5 Toit, 6 Hasard, 7 Moulures
        local t1 = (n == 1)
        local t2 = (n == 3)   -- Étages
        local t3 = (n == 2)   -- Rez-de-chaussée
        local t4 = (n == 4)
        local t5 = (n == 5)
        local t6 = (n == 6)
        local t7 = (n == 7)

        gb1.visible = t1
        rbMode.visible = t1
        pbCont.visible = t1
        gb2.visible = t1
        l_spLength.visible = t1
        spLength.visible = t1
        l_spGround.visible = t1
        spGround.visible = t1
        gb4.visible = t1
        l_spBays.visible = t1
        spBays.visible = t1
        l_spPier.visible = t1
        spPier.visible = t1
        l_spDepth.visible = t1
        spDepth.visible = t1
        l_spFrame.visible = t1
        spFrame.visible = t1
        cbCornice.visible = t1
        cbMerge.visible = t1
        gbCol.visible = t1
        l_cpWall.visible = t1
        cpWall.visible = t1
        l_cpFrame.visible = t1
        cpFrame.visible = t1
        l_cpPier.visible = t1
        cpPier.visible = t1
        l_cpGlass.visible = t1
        cpGlass.visible = t1
        l_cpDoor.visible = t1
        cpDoor.visible = t1
        l_cpShut.visible = t1
        cpShut.visible = t1
        l_cpRoof.visible = t1
        cpRoof.visible = t1
        l_cpPanel.visible = t1
        cpPanel.visible = t1

        gb3.visible = t2
        l_spFloors.visible = t2
        spFloors.visible = t2
        rbFloors.visible = t2
        l_spFloorSel.visible = t2
        spFloorSel.visible = t2
        btCopyAll.visible = t2
        gb5.visible = t2
        l_spUpper.visible = t2
        spUpper.visible = t2
        ddUpper.visible = t2
        l_spWinW.visible = t2
        spWinW.visible = t2
        l_spWinH.visible = t2
        spWinH.visible = t2
        l_spSill.visible = t2
        spSill.visible = t2
        ddBalc.visible = t2
        l_spBalcD.visible = t2
        spBalcD.visible = t2
        l_spPanOp.visible = t2
        spPanOp.visible = t2
        l_spBalcVar.visible = t2
        spBalcVar.visible = t2
        l_spSlabTh.visible = t2
        spSlabTh.visible = t2
        l_spMixOut.visible = t2
        spMixOut.visible = t2
        l_spMixIn.visible = t2
        spMixIn.visible = t2

        gb7.visible = t3
        ddGround.visible = t3
        ddArc.visible = t3
        cbArcGl.visible = t3
        l_spArcR.visible = t3
        spArcR.visible = t3
        l_spArcL.visible = t3
        spArcL.visible = t3
        gb9.visible = t3
        ddEntrance.visible = t3
        l_spEntW.visible = t3
        spEntW.visible = t3
        l_spDoorH.visible = t3
        spDoorH.visible = t3
        l_spDoorN.visible = t3
        spDoorN.visible = t3

        gb10.visible = t4
        ddRail.visible = t4
        l_spRailH.visible = t4
        spRailH.visible = t4
        l_spRailD.visible = t4
        spRailD.visible = t4
        gb11.visible = t4
        l_spShutPct.visible = t4
        spShutPct.visible = t4
        l_spShutOpen.visible = t4
        spShutOpen.visible = t4
        lbShutHelp.visible = t4
        gb12.visible = t4
        ddCap.visible = t4
        l_spCapD.visible = t4
        spCapD.visible = t4
        l_spCapPct.visible = t4
        spCapPct.visible = t4
        gb13.visible = t4
        cbSurr.visible = t4
        pbSurrProf.visible = t4
        l_spSurrS.visible = t4
        spSurrS.visible = t4
        lbSurrHelp.visible = t4

        gbRoof.visible = t5
        ddRoof.visible = t5
        l_spRoofPitch.visible = t5
        spRoofPitch.visible = t5
        l_spRoofOver.visible = t5
        spRoofOver.visible = t5
        l_spRoofPar.visible = t5
        spRoofPar.visible = t5
        l_spRoofDepth.visible = t5
        spRoofDepth.visible = t5
        l_spAcrTh.visible = t5
        spAcrTh.visible = t5
        l_spAcrGorge.visible = t5
        spAcrGorge.visible = t5
        l_spMansP2.visible = t5
        spMansP2.visible = t5
        l_spMansTop.visible = t5
        spMansTop.visible = t5
        ddRidge.visible = t5
        l_spRidgeW.visible = t5
        spRidgeW.visible = t5
        l_spRidgeH.visible = t5
        spRidgeH.visible = t5
        l_spLucW.visible = t5
        spLucW.visible = t5
        l_spLucH.visible = t5
        spLucH.visible = t5
        l_spLucStep.visible = t5
        spLucStep.visible = t5
        ddLuc.visible = t5
        lbRoofHelp.visible = t5

        gb6.visible = t6
        l_spArcPct.visible = t6
        spArcPct.visible = t6
        l_spSeed.visible = t6
        spSeed.visible = t6
        btRoll.visible = t6
        l_spVar.visible = t6
        spVar.visible = t6
        l_spWidthVar.visible = t6
        spWidthVar.visible = t6
        cbWide.visible = t6
        cbBalcony.visible = t6
        cbWall.visible = t6
        lbVarHelp.visible = t6

        gb8.visible = t7
        btGuides.visible = t7
        btProfile.visible = t7
        pbProf.visible = t7
        l_spMoldScale.visible = t7
        spMoldScale.visible = t7
        l_spMoldZ.visible = t7
        spMoldZ.visible = t7
        cbMoldFlip.visible = t7
        btMold.visible = t7
        lbMoldHelp.visible = t7

    )

    /* ----- gestion des étages ----- */

    fn FitFloorArrays =
    (
        local n = spFloors.value

        FR_gH = FR_FitArr FR_gH n spUpper.value
        FR_gMode = FR_FitArr FR_gMode n (FR_UpperCodes[ddUpper.selection])
        FR_gWin = FR_FitArr FR_gWin n spWinW.value
        FR_gHt = FR_FitArr FR_gHt n spWinH.value
        FR_gSill = FR_FitArr FR_gSill n spSill.value
        FR_gBalc = FR_FitArr FR_gBalc n (FR_BalcCodes[ddBalc.selection])
        FR_gBalcD = FR_FitArr FR_gBalcD n spBalcD.value
        FR_gBalcVar = FR_FitArr FR_gBalcVar n spBalcVar.value
    )

    -- contrôles -> étage idx
    fn StoreFloor idx =
    (
        FitFloorArrays()

        if idx >= 1 and idx <= FR_gH.count do
        (
            FR_gH[idx] = spUpper.value
            FR_gMode[idx] = FR_UpperCodes[ddUpper.selection]
            FR_gWin[idx] = spWinW.value
            FR_gHt[idx] = spWinH.value
            FR_gSill[idx] = spSill.value
            FR_gBalc[idx] = FR_BalcCodes[ddBalc.selection]
            FR_gBalcD[idx] = spBalcD.value
            FR_gBalcVar[idx] = spBalcVar.value
        )
    )

    -- contrôles -> tous les étages
    fn StoreAll =
    (
        FitFloorArrays()

        for k = 1 to FR_gH.count do StoreFloor k
    )

    -- étage idx -> contrôles
    fn LoadFloor idx =
    (
        if idx >= 1 and idx <= FR_gH.count do
        (
            spUpper.value = FR_gH[idx]

            local mi = findItem FR_UpperCodes FR_gMode[idx]
            if mi == 0 do mi = 1
            ddUpper.selection = mi

            spWinW.value = FR_gWin[idx]
            spWinH.value = FR_gHt[idx]
            spSill.value = FR_gSill[idx]

            local bi = findItem FR_BalcCodes FR_gBalc[idx]
            if bi == 0 do bi = 1
            ddBalc.selection = bi

            -- garde-fou : anciens presets sans flBalcD/flBalcVar -> garder la valeur affichée
            spBalcD.value = (if idx <= FR_gBalcD.count and FR_gBalcD[idx] != undefined then FR_gBalcD[idx] else spBalcD.value)
            spBalcVar.value = (if idx <= FR_gBalcVar.count and FR_gBalcVar[idx] != undefined then FR_gBalcVar[idx] else spBalcVar.value)
        )
    )

    fn SyncFloorCount =
    (
        local n = spFloors.value

        FitFloorArrays()

        if curFloor > n do
        (
            curFloor = n
            LoadFloor curFloor
        )

        spFloorSel.range = [1, n, curFloor]
    )

    -- les réglages d'arcades ne servent que si le rez-de-chaussée est en arcades
    fn UpdateArcUI =
    (
        local g = FR_GroundCodes[ddGround.selection]
        local arc = (g == "Arcade")
        local gal = (g == "Arcade" or g == "Portico")

        -- la forme de l'arc ne sert que pour les arcades ; retrait et bande pleine servent aussi au portique
        ddArc.enabled = arc
        cbArcGl.enabled = arc
        spArcR.enabled = gal
        spArcL.enabled = gal
        l_spArcR.enabled = gal
        l_spArcL.enabled = gal

        -- le nombre de portes ne sert qu'au mode « Alternance vitrine / porte »
        local alt = (g == "Alternating storefront / door")
        spDoorN.enabled = alt
        l_spDoorN.enabled = alt
    )

    -- la pente ne sert qu'aux toits à pentes, l'acrotère qu'à la terrasse
    fn UpdateRoofUI =
    (
        local r = FR_RoofCodes[ddRoof.selection]
        local flat = (r == "Flat")
        local sloped = (r == "Gable" or r == "Hip")
        local mans = (r == "Mansard")

        spRoofPitch.enabled = sloped or mans
        l_spRoofPitch.enabled = sloped or mans
        spRoofPar.enabled = flat or mans
        l_spRoofPar.enabled = flat or mans
        spAcrTh.enabled = flat
        l_spAcrTh.enabled = flat
        spAcrGorge.enabled = flat
        l_spAcrGorge.enabled = flat
        spMansP2.enabled = mans
        l_spMansP2.enabled = mans
        spMansTop.enabled = mans
        l_spMansTop.enabled = mans

        -- les lucarnes ne servent qu'au mansard
        ddLuc.enabled = mans
        spLucW.enabled = mans
        l_spLucW.enabled = mans
        spLucH.enabled = mans
        l_spLucH.enabled = mans
        spLucStep.enabled = mans
        l_spLucStep.enabled = mans

        -- le couvre-joint ne sert qu'aux toits avec versants
        local ridged = (sloped or mans)
        ddRidge.enabled = ridged
        spRidgeW.enabled = ridged
        l_spRidgeW.enabled = ridged
        spRidgeH.enabled = ridged
        l_spRidgeH.enabled = ridged
    )

    /* ----- interface <-> paramètres ----- */

    fn FR_ReadUI =
    (
        local PR = FRParams()

        PR.width = spLength.value
        PR.groundH = spGround.value
        PR.floors = spFloors.value
        PR.bays = spBays.value
        PR.pier = spPier.value
        PR.depth = spDepth.value
        PR.fw = spFrame.value
        PR.balcD = spBalcD.value
        PR.balcVar = spBalcVar.value
        PR.slabTh = spSlabTh.value
        PR.mixOut = spMixOut.value
        PR.mixIn = spMixIn.value
        PR.panOpaque = spPanOp.value

        PR.upperH = spUpper.value
        PR.upperMode = FR_UpperCodes[ddUpper.selection]
        PR.winPct = spWinW.value
        PR.winHt = spWinH.value
        PR.winSill = spSill.value

        PR.railMode = FR_RailCodes[ddRail.selection]
        PR.railH = spRailH.value
        PR.railD = spRailD.value
        PR.shutPct = spShutPct.value
        PR.shutOpen = spShutOpen.value
        PR.capMode = FR_CapCodes[ddCap.selection]
        PR.capD = spCapD.value
        PR.capPct = spCapPct.value

        PR.surr = cbSurr.checked
        PR.surrS = spSurrS.value
        PR.surrProf = (if pbSurrProf.object != undefined and (isValidNode pbSurrProf.object) then pbSurrProf.object.name else "")
        PR.arcPct = spArcPct.value

        PR.roofMode = FR_RoofCodes[ddRoof.selection]
        PR.roofPitch = spRoofPitch.value
        PR.roofOver = spRoofOver.value
        PR.roofPar = spRoofPar.value
        PR.roofDepth = spRoofDepth.value
        PR.acrTh = spAcrTh.value
        PR.acrGorge = spAcrGorge.value
        PR.mansP2 = spMansP2.value
        PR.mansTop = spMansTop.value
        PR.ridgeMode = FR_RidgeCodes[ddRidge.selection]
        PR.ridgeW = spRidgeW.value
        PR.ridgeH = spRidgeH.value
        PR.lucMode = FR_LucCodes[ddLuc.selection]
        PR.lucW = spLucW.value
        PR.lucH = spLucH.value
        PR.lucStep = spLucStep.value

        PR.seedVal = spSeed.value
        PR.variation = spVar.value
        PR.widthVar = spWidthVar.value
        PR.allowWide = cbWide.checked
        PR.allowBalcony = cbBalcony.checked
        PR.allowWall = cbWall.checked
        PR.entrance = FR_EntCodes[ddEntrance.selection]
        PR.entranceFactor = spEntW.value
        PR.doorH = spDoorH.value
        PR.nDoors = spDoorN.value
        PR.cornice = cbCornice.checked

        PR.colWall = cpWall.color
        PR.colFrame = cpFrame.color
        PR.colPier = cpPier.color
        PR.colGlass = cpGlass.color
        PR.colDoor = cpDoor.color
        PR.colShut = cpShut.color
        PR.colRoof = cpRoof.color
        PR.colPanel = cpPanel.color

        PR.groundMode = FR_GroundCodes[ddGround.selection]
        PR.arcType = FR_ArcCodes[ddArc.selection]
        PR.arcRecess = spArcR.value
        PR.arcLintel = spArcL.value
        PR.arcGlArch = cbArcGl.checked

        if rbFloors.state == 1 then
        (
            -- identiques : tous les étages prennent les valeurs affichées (sans toucher aux valeurs mémorisées)
            local nF = spFloors.value

            PR.flH = for k = 1 to nF collect spUpper.value
            PR.flMode = for k = 1 to nF collect (FR_UpperCodes[ddUpper.selection])
            PR.flWin = for k = 1 to nF collect spWinW.value
            PR.flHt = for k = 1 to nF collect spWinH.value
            PR.flSill = for k = 1 to nF collect spSill.value
            PR.flBalc = for k = 1 to nF collect (FR_BalcCodes[ddBalc.selection])
            PR.flBalcD = for k = 1 to nF collect spBalcD.value
            PR.flBalcVar = for k = 1 to nF collect spBalcVar.value
        )
        else
        (
            StoreFloor curFloor

            PR.flH = (FR_CopyArr FR_gH)
            PR.flMode = (FR_CopyArr FR_gMode)
            PR.flWin = (FR_CopyArr FR_gWin)
            PR.flHt = (FR_CopyArr FR_gHt)
            PR.flSill = (FR_CopyArr FR_gSill)
            PR.flBalc = (FR_CopyArr FR_gBalc)
            PR.flBalcD = (FR_CopyArr FR_gBalcD)
            PR.flBalcVar = (FR_CopyArr FR_gBalcVar)
        )

        PR
    )

    fn FR_WriteUI PR =
    (
        spLength.value = PR.width
        spGround.value = PR.groundH
        spFloors.value = PR.floors
        spBays.value = PR.bays
        spPier.value = PR.pier
        spDepth.value = PR.depth
        spFrame.value = PR.fw
        spBalcD.value = PR.balcD
        spBalcVar.value = PR.balcVar
        spSlabTh.value = PR.slabTh
        spMixOut.value = PR.mixOut
        spMixIn.value = PR.mixIn
        spPanOp.value = PR.panOpaque

        spSeed.value = PR.seedVal
        spVar.value = PR.variation
        spWidthVar.value = PR.widthVar
        cbWide.checked = PR.allowWide
        cbBalcony.checked = PR.allowBalcony
        cbWall.checked = PR.allowWall
        spEntW.value = PR.entranceFactor
        spDoorH.value = PR.doorH
        spDoorN.value = PR.nDoors
        cbCornice.checked = PR.cornice

        cpWall.color = PR.colWall
        cpFrame.color = PR.colFrame
        cpPier.color = PR.colPier
        cpGlass.color = PR.colGlass
        cpDoor.color = PR.colDoor
        cpShut.color = PR.colShut
        cpRoof.color = PR.colRoof
        cpPanel.color = PR.colPanel

        local ei = findItem FR_EntCodes PR.entrance
        if ei == 0 do ei = 1
        ddEntrance.selection = ei

        local gi = findItem FR_GroundCodes PR.groundMode
        if gi == 0 do gi = 1
        ddGround.selection = gi

        local ai = findItem FR_ArcCodes PR.arcType
        if ai == 0 do ai = 1
        ddArc.selection = ai
        spArcR.value = PR.arcRecess
        spArcL.value = PR.arcLintel
        cbArcGl.checked = PR.arcGlArch
        UpdateArcUI()

        local ri = findItem FR_RailCodes PR.railMode
        if ri == 0 do ri = 1
        ddRail.selection = ri
        spRailH.value = PR.railH
        spRailD.value = PR.railD
        spShutPct.value = PR.shutPct
        spShutOpen.value = PR.shutOpen

        local ci = findItem FR_CapCodes PR.capMode
        if ci == 0 do ci = 1
        ddCap.selection = ci
        spCapD.value = PR.capD
        spCapPct.value = PR.capPct

        cbSurr.checked = PR.surr
        spSurrS.value = PR.surrS
        spArcPct.value = PR.arcPct

        local su = undefined

        if PR.surrProf != "" do
            su = try(getNodeByName PR.surrProf)catch(undefined)

        if su != undefined and (superclassof su) != shape do su = undefined

        pbSurrProf.object = su
        pbSurrProf.caption = (if su != undefined then su.name else "Profil : (carré par défaut)")

        local roi = findItem FR_RoofCodes PR.roofMode
        if roi == 0 do roi = 1
        ddRoof.selection = roi
        spRoofPitch.value = PR.roofPitch
        spRoofOver.value = PR.roofOver
        spRoofPar.value = PR.roofPar
        spRoofDepth.value = PR.roofDepth
        spAcrTh.value = PR.acrTh
        spAcrGorge.value = PR.acrGorge
        spMansP2.value = PR.mansP2
        spMansTop.value = PR.mansTop
        local ri2 = findItem FR_RidgeCodes PR.ridgeMode
        if ri2 == 0 do ri2 = 1
        ddRidge.selection = ri2
        spRidgeW.value = PR.ridgeW
        spRidgeH.value = PR.ridgeH
        local li = findItem FR_LucCodes PR.lucMode
        if li == 0 do li = 1
        ddLuc.selection = li
        spLucW.value = PR.lucW
        spLucH.value = PR.lucH
        spLucStep.value = PR.lucStep
        UpdateRoofUI()

        -- valeurs "anciennes façades" : serviront à compléter les tableaux manquants
        spUpper.value = PR.upperH
        spWinW.value = PR.winPct
        spWinH.value = PR.winHt
        spSill.value = PR.winSill

        local ui = findItem FR_UpperCodes PR.upperMode
        if ui == 0 do ui = 1
        ddUpper.selection = ui

        FR_gH = (FR_CopyArr PR.flH)
        FR_gMode = (FR_CopyArr PR.flMode)
        FR_gWin = (FR_CopyArr PR.flWin)
        FR_gHt = (FR_CopyArr PR.flHt)
        FR_gSill = (FR_CopyArr PR.flSill)
        FR_gBalc = (FR_CopyArr PR.flBalc)
        FR_gBalcD = (FR_CopyArr PR.flBalcD)
        FR_gBalcVar = (FR_CopyArr PR.flBalcVar)

        FitFloorArrays()

        -- tous les étages identiques ?
        local same = true

        for k = 2 to FR_gH.count do
        (
            if FR_gH[k] != FR_gH[1] or FR_gMode[k] != FR_gMode[1] or FR_gWin[k] != FR_gWin[1] or FR_gHt[k] != FR_gHt[1] or FR_gSill[k] != FR_gSill[1] or FR_gBalc[k] != FR_gBalc[1] or FR_gBalcD[k] != FR_gBalcD[1] or FR_gBalcVar[k] != FR_gBalcVar[1] do same = false
        )

        -- IMPORTANT : ddBalc AVANT la bascule rbFloors — sinon StoreFloor (déclenché par
        -- spFloorSel.range dans le handler) recopie le DÉFAUT du dialogue (« Saillants »)
        -- dans l'étage 1 au lieu du « Aucun » du preset
        local bi0 = findItem FR_BalcCodes (if PR.flBalc.count > 0 then PR.flBalc[1] else "None")
        if bi0 == 0 do bi0 = 1
        ddBalc.selection = bi0

        -- IMPORTANT : flCustom AVANT rbFloors.state — affecter .state déclenche le
        -- handler « on rbFloors changed », qui fait StoreAll() si flCustom est false
        -- et écraserait les valeurs par étage du preset (balcon du 1er étage, etc.)
        flCustom = not same
        spFloorSel.enabled = not same
        btCopyAll.enabled = not same

        if same then
            rbFloors.state = 1
        else
            rbFloors.state = 2

        curFloor = 1
        spFloorSel.range = [1, spFloors.value, 1]

        LoadFloor 1

        -- une façade chargée se modifie par dimensions
        rbMode.state = 1
        spLength.enabled = true
        l_spGround.text = "Hauteur du rez-de-chaussée :"
        l_spUpper.text = "Hauteur de l'étage :"

        -- façade en contour : le sélecteur de segment devient actif
        if FR_CSegs.count > 1 do
        (
            rbMode.state = 3
            spSeg.range = [1, FR_CSegs.count, FR_CurSeg]
            spSeg.value = FR_CurSeg
        )
    )

    fn FR_SelectedRoot =
    (
        local root = undefined

        if selection.count > 0 do root = FR_FindRoot selection[1]

        root
    )

    -- charge une façade (simple ou contour) dans l'interface
    fn FR_LoadRoot root =
    (
        if FR_ContourCount root > 1 then
        (
            local cd = FR_ContourFromString (getUserPropBuffer root)

            FR_CPts = cd[1]
            FR_CSegs = cd[2]
            FR_CurSeg = 1

            FR_WriteUI FR_CSegs[1]

            true
        )
        else
        (
            FR_CPts = #()
            FR_CSegs = #()
            FR_CurSeg = 1

            FR_WriteUI (FR_ParamsFromString (getUserPropBuffer root))

            false
        )
    )

    /* ----- mise à jour : façade simple ou contour ----- */

    -- contour : la verticale et le commun de l'UI s'appliquent à tous les segments,
    -- les réglages horizontaux au segment affiché seulement
    fn FR_DoUpdateContour silent =
    (
        local root = FR_SelectedRoot()

        if root == undefined then
        (
            if not silent do messageBox "Sélectionnez d'abord une façade FRAMER (n'importe quelle partie)."
        )
        else if FR_CSegs.count < 2 or FR_CPts.count < 3 then
        (
            if not silent do messageBox "Rechargez d'abord la façade (bouton Charger la sélection)."
        )
        else
        (
            FR_CSegs[FR_CurSeg] = FR_ReadUI()

            -- verticale + commun : copiés du segment affiché vers tous les autres
            local vGH = FR_CSegs[FR_CurSeg].groundH
            local vFl = FR_CSegs[FR_CurSeg].floors
            local vFlH = (FR_CopyArr FR_CSegs[FR_CurSeg].flH)
            local vFlMode = (FR_CopyArr FR_CSegs[FR_CurSeg].flMode)
            local vFlWin = (FR_CopyArr FR_CSegs[FR_CurSeg].flWin)
            local vFlHt = (FR_CopyArr FR_CSegs[FR_CurSeg].flHt)
            local vFlSill = (FR_CopyArr FR_CSegs[FR_CurSeg].flSill)
            local vFlBalc = (FR_CopyArr FR_CSegs[FR_CurSeg].flBalc)
            local vFlBalcD = (FR_CopyArr FR_CSegs[FR_CurSeg].flBalcD)
            local vFlBalcVar = (FR_CopyArr FR_CSegs[FR_CurSeg].flBalcVar)
            local vBalcD = FR_CSegs[FR_CurSeg].balcD
            local vBalcV = FR_CSegs[FR_CurSeg].balcVar
            local vPanOp = FR_CSegs[FR_CurSeg].panOpaque
            local vDepth = FR_CSegs[FR_CurSeg].depth
            local vFw = FR_CSegs[FR_CurSeg].fw
            local vCorn = FR_CSegs[FR_CurSeg].cornice
            local vUpH = FR_CSegs[FR_CurSeg].upperH
            local vUpM = FR_CSegs[FR_CurSeg].upperMode
            local vWinP = FR_CSegs[FR_CurSeg].winPct
            local vWinH = FR_CSegs[FR_CurSeg].winHt
            local vWinS = FR_CSegs[FR_CurSeg].winSill
            local vRailK = FR_CSegs[FR_CurSeg].railMode
            local vRailH = FR_CSegs[FR_CurSeg].railH
            local vRailD = FR_CSegs[FR_CurSeg].railD
            local vShutP = FR_CSegs[FR_CurSeg].shutPct
            local vShutO = FR_CSegs[FR_CurSeg].shutOpen
            local vCapK = FR_CSegs[FR_CurSeg].capMode
            local vCapD = FR_CSegs[FR_CurSeg].capD
            local vCapP = FR_CSegs[FR_CurSeg].capPct
            local vSurr = FR_CSegs[FR_CurSeg].surr
            local vSurrS = FR_CSegs[FR_CurSeg].surrS
            local vSurrProf = FR_CSegs[FR_CurSeg].surrProf
            local vArcP = FR_CSegs[FR_CurSeg].arcPct
            local vRoofK = FR_CSegs[FR_CurSeg].roofMode
            local vRoofP = FR_CSegs[FR_CurSeg].roofPitch
            local vRoofO = FR_CSegs[FR_CurSeg].roofOver
            local vRoofPar = FR_CSegs[FR_CurSeg].roofPar
            local vRoofD = FR_CSegs[FR_CurSeg].roofDepth
            local vAcrTh = FR_CSegs[FR_CurSeg].acrTh
            local vAcrGorge = FR_CSegs[FR_CurSeg].acrGorge
            local vLucM = FR_CSegs[FR_CurSeg].lucMode
            local vLucW = FR_CSegs[FR_CurSeg].lucW
            local vLucH = FR_CSegs[FR_CurSeg].lucH
            local vLucS = FR_CSegs[FR_CurSeg].lucStep
            local vColW = FR_CSegs[FR_CurSeg].colWall
            local vColF = FR_CSegs[FR_CurSeg].colFrame
            local vColP = FR_CSegs[FR_CurSeg].colPier
            local vColG = FR_CSegs[FR_CurSeg].colGlass
            local vColD = FR_CSegs[FR_CurSeg].colDoor
            local vColS = FR_CSegs[FR_CurSeg].colShut
            local vColR = FR_CSegs[FR_CurSeg].colRoof
            local vColN = FR_CSegs[FR_CurSeg].colPanel

            for k = 1 to FR_CSegs.count do
            (
                if k != FR_CurSeg do
                (
                    FR_CSegs[k].groundH = vGH
                    FR_CSegs[k].floors = vFl
                    FR_CSegs[k].flH = (FR_CopyArr vFlH)
                    FR_CSegs[k].flMode = (FR_CopyArr vFlMode)
                    FR_CSegs[k].flWin = (FR_CopyArr vFlWin)
                    FR_CSegs[k].flHt = (FR_CopyArr vFlHt)
                    FR_CSegs[k].flSill = (FR_CopyArr vFlSill)
                    FR_CSegs[k].flBalc = (FR_CopyArr vFlBalc)
                    FR_CSegs[k].flBalcD = (FR_CopyArr vFlBalcD)
                    FR_CSegs[k].flBalcVar = (FR_CopyArr vFlBalcVar)
                    FR_CSegs[k].balcD = vBalcD
                    FR_CSegs[k].balcVar = vBalcV
                    FR_CSegs[k].panOpaque = vPanOp
                    FR_CSegs[k].depth = vDepth
                    FR_CSegs[k].fw = vFw
                    FR_CSegs[k].cornice = vCorn
                    FR_CSegs[k].upperH = vUpH
                    FR_CSegs[k].upperMode = vUpM
                    FR_CSegs[k].winPct = vWinP
                    FR_CSegs[k].winHt = vWinH
                    FR_CSegs[k].winSill = vWinS
                    FR_CSegs[k].railMode = vRailK
                    FR_CSegs[k].railH = vRailH
                    FR_CSegs[k].railD = vRailD
                    FR_CSegs[k].shutPct = vShutP
                    FR_CSegs[k].shutOpen = vShutO
                    FR_CSegs[k].capMode = vCapK
                    FR_CSegs[k].capD = vCapD
                    FR_CSegs[k].capPct = vCapP
                    FR_CSegs[k].surr = vSurr
                    FR_CSegs[k].surrS = vSurrS
                    FR_CSegs[k].surrProf = vSurrProf
                    FR_CSegs[k].arcPct = vArcP
                    FR_CSegs[k].roofMode = vRoofK
                    FR_CSegs[k].roofPitch = vRoofP
                    FR_CSegs[k].roofOver = vRoofO
                    FR_CSegs[k].roofPar = vRoofPar
                    FR_CSegs[k].roofDepth = vRoofD
                    FR_CSegs[k].acrTh = vAcrTh
                    FR_CSegs[k].acrGorge = vAcrGorge
                    FR_CSegs[k].lucMode = vLucM
                    FR_CSegs[k].lucW = vLucW
                    FR_CSegs[k].lucH = vLucH
                    FR_CSegs[k].lucStep = vLucS
                    FR_CSegs[k].colWall = vColW
                    FR_CSegs[k].colFrame = vColF
                    FR_CSegs[k].colPier = vColP
                    FR_CSegs[k].colGlass = vColG
                    FR_CSegs[k].colDoor = vColD
                    FR_CSegs[k].colShut = vColS
                    FR_CSegs[k].colRoof = vColR
                    FR_CSegs[k].colPanel = vColN
                )
            )

            FR_Silent = silent

            local ok = false

            -- en direct (silent) : PAS d'undo, sinon chaque réglage empile une façade
            -- complète en mémoire jusqu'au débordement
            if silent then
                ok = FR_BuildContour FR_CPts FR_CSegs root cbMerge.checked
            else
                undo "Mise à jour façade FRAMER" on
                (
                    ok = FR_BuildContour FR_CPts FR_CSegs root cbMerge.checked
                )

            if ok == true do
            (
                select root
                lbInfo.text = FR_Summary
                redrawViews()
            )

            FR_Silent = false
        )
    )

    fn FR_DoUpdate silent =
    (
        local root = FR_SelectedRoot()

        if root == undefined then
        (
            if not silent do messageBox "Sélectionnez d'abord une façade FRAMER (n'importe quelle partie)."
        )
        else if FR_ContourCount root > 1 then
        (
            FR_DoUpdateContour silent
        )
        else
        (
            local PR = FR_ReadUI()

            FR_Silent = silent

            if FR_Validate PR then
            (
                local ok = false

                -- en direct (silent) : PAS d'undo, sinon chaque réglage empile une façade
                -- complète en mémoire jusqu'au débordement
                if silent then
                    ok = FR_Build PR root cbMerge.checked
                else
                    undo "Mise à jour façade FRAMER" on
                    (
                        ok = FR_Build PR root cbMerge.checked
                    )

                if ok == true then
                (
                    select root
                    lbInfo.text = FR_Summary
                    redrawViews()
                )

                -- libère le tas MAXScript après chaque reconstruction (même manuelle)
                gc light:true
            )

            FR_Silent = false
        )
    )

    fn FR_LiveTick =
    (
        if cbLive.checked do
        (
            FR_DoUpdate true

            -- libère le tas MAXScript après chaque reconstruction en direct
            gc light:true
        )
    )

    /* ----- mode création / édition ----- */

    -- en mode édition, une façade sélectionnée se charge toute seule
    fn FR_SelChanged =
    (
        if FR_LastRoot != undefined and not (isValidNode FR_LastRoot) do FR_LastRoot = undefined

        if rbWork.state == 2 do
        (
            local root = FR_SelectedRoot()

            if root != undefined and root != FR_LastRoot do
            (
                FR_LastRoot = root

                FR_LoadRoot root

                lbEdit.text = "Façade en édition : " + root.name
                lbInfo.text = "Façade chargée. Les réglages s'appliquent en direct si la case est cochée."

                spSeg.enabled = (FR_CSegs.count > 1)
                btCopySeg.enabled = spSeg.enabled
            )
        )
    )

    fn SetWorkMode state =
    (
        local edit = (state == 2)

        -- marqueur visuel fort du mode courant (pour ne plus se tromper) :
        -- liseret bleu + titre simple en CRÉATION, liseret orange + « ÉDITION »
        -- dans les titres en ÉDITION
        if edit then
        (
            pbModeBar.color = color 235 130 30
            lbEdit.text = "● MODE ÉDITION : les réglages modifient la façade sélectionnée."
            gbWork.text = "Mode de travail — ÉDITION"
        )
        else
        (
            pbModeBar.color = color 120 150 190
            lbEdit.text = "Nouvelle façade : réglez puis cliquez sur Générer."
            gbWork.text = "Mode de travail"
        )

        try
        (
            setDialogTitle FRAMER_UI (if edit then \
                "FRAMER | Générateur de façades 0.6.18 — ● ÉDITION ●" else \
                "FRAMER | Générateur de façades 0.6.18")
        )
        catch()

        -- création : génération par dimensions, face ou contour ; édition : modification de la façade sélectionnée
        rbMode.enabled = not edit
        btGenerate.enabled = not edit
        pbCont.enabled = not edit

        btUpdate.enabled = edit
        btLoad.enabled = edit
        btDelete.enabled = edit
        btGuides.enabled = edit
        cbLive.enabled = edit

        spLength.enabled = edit or (rbMode.state == 1)
        l_spLength.enabled = spLength.enabled

        if edit then
        (
            cbLive.checked = true
            FR_LastRoot = undefined

            FR_SelChanged()

            if FR_LastRoot == undefined do
            (
                lbEdit.text = "Sélectionnez une façade FRAMER dans la scène."
                lbInfo.text = "Mode édition : cliquez sur n'importe quelle partie d'une façade."
            )
        )
        else
        (
            cbLive.checked = false
            lbEdit.text = "Nouvelle façade : réglez puis cliquez sur Générer."
            lbInfo.text = "Mode création."

            spSeg.enabled = false
            btCopySeg.enabled = false
        )
    )

    /* ----- événements : presets ----- */

    fn FR_RefreshPresets =
    (
        local names = FR_PresetNames()
        local sel = ddPreset.selected

        -- liste vide : .selected vaut undefined (et non 0)
        if sel == undefined do sel = 0

        ddPreset.items = names

        -- affecter .selected (même 0) sur une liste vide lève "No current selection"
        if names.count > 0 and sel >= 1 do
            ddPreset.selected = (amin #(sel, names.count))
    )

    fn FR_PresetApply nm path:undefined =
    (
        local f = if path != undefined then path else FR_PresetFile nm

        if not doesFileExist f then
            messageBox ("Preset introuvable : " + nm + "\n\nDossier attendu : " + (FR_PresetDir()))
        else
        (
            local ss = stringstream ""
            local ff = openFile f

            if ff != undefined do
            (
                while not eof ff do append ss ((readLine ff) + "\n")
                close ff
            )

            local pp = FR_ParamsFromString (ss as string)

            FR_WriteUI pp

            -- ceinture et bretelles : ré-applique les tableaux par étage, au cas où un
            -- handler déclenché par FR_WriteUI (rbFloors, spFloorSel, ddBalc...) aurait
            -- réécrit FR_gBalc/FR_gH/... avec les valeurs affichées
            -- complète les tableaux trop courts (anciens presets sans
            -- flBalcD/flBalcVar : remplis avec les valeurs globales du preset)
            FR_gH = FR_FitArr (FR_CopyArr pp.flH) pp.floors pp.upperH
            FR_gMode = FR_FitArr (FR_CopyArr pp.flMode) pp.floors pp.upperMode
            FR_gWin = FR_FitArr (FR_CopyArr pp.flWin) pp.floors pp.winPct
            FR_gHt = FR_FitArr (FR_CopyArr pp.flHt) pp.floors pp.winHt
            FR_gSill = FR_FitArr (FR_CopyArr pp.flSill) pp.floors pp.winSill
            FR_gBalc = FR_FitArr (FR_CopyArr pp.flBalc) pp.floors "None"
            FR_gBalcD = FR_FitArr (FR_CopyArr pp.flBalcD) pp.floors pp.balcD
            FR_gBalcVar = FR_FitArr (FR_CopyArr pp.flBalcVar) pp.floors 0.0
            LoadFloor 1
            flCustom = true

            lbInfo.text = "Preset chargé : " + nm

            if cbLive.checked and cbLive.enabled do FR_LiveTick()
        )
    )

    fn FR_PresetWrite nm =
    (
        local clean = FR_PresetCleanName nm

        if clean == "" then
            messageBox "Donnez un nom au preset (champ Nom)."
        else
        (
            local f = createFile (FR_PresetFile clean)

            if f == undefined then
                messageBox ("Impossible de créer le preset : " + clean)
            else
            (
                format "%" (FR_ParamsToString (FR_ReadUI())) to:f
                close f

                FR_RefreshPresets()
                ddPreset.selected = findItem ddPreset.items clean
                etPresetName.text = clean
                lbInfo.text = "Preset sauvegardé : " + clean
            )
        )
    )

    on ddPreset selected i do
    (
        if i > 0 and i <= ddPreset.items.count do FR_PresetApply ddPreset.items[i]
    )

    on btPresetSave pressed do FR_PresetWrite etPresetName.text

    on btPresetRefresh pressed do
    (
        FR_RefreshPresets()
        lbInfo.text = "Dossier presets : " + (FR_PresetDir())
    )

    on btPresetBrowse pressed do
    (
        local f = getOpenFileName caption:"Charger un preset FRAMER" \
            types:"Preset FRAMER (*.framer)|*.framer|Tous les fichiers (*.*)|*.*"

        if f != undefined do
        (
            FR_PresetApply (filenameFromPath f) path:f
            etPresetName.text = FR_PresetCleanName (getFilenameFile f)
        )
    )

    on btPresetLoad pressed do
    (
        local sel = ddPreset.selected

        if sel == undefined do sel = 0

        if sel > 0 then
            FR_PresetApply ddPreset.items[sel]
        else if (FR_PresetCleanName etPresetName.text) != "" then
            FR_PresetApply (FR_PresetCleanName etPresetName.text)
        else
            messageBox ("Choisissez un preset dans la liste (ou tapez son nom), ou cliquez … pour parcourir un dossier perso.\n\nDossier des presets : " + (FR_PresetDir()) + "\n\nCliquez ↻ pour réactualiser la liste après y avoir copié un fichier .framer.")
    )

    on btPresetDel pressed do
    (
        local sel = ddPreset.selected

        if sel == undefined do sel = 0

        local nm = if sel > 0 then ddPreset.items[sel]
                   else (FR_PresetCleanName etPresetName.text)

        if nm == "" then
            messageBox "Choisissez le preset à supprimer dans la liste."
        else
        (
            local f = FR_PresetFile nm

            if not doesFileExist f then
                messageBox ("Preset introuvable : " + nm)
            else
            (
                deleteFile f
                FR_RefreshPresets()
                etPresetName.text = ""
                lbInfo.text = "Preset supprimé : " + nm
            )
        )
    )

    /* ----- événements : mode, étages ----- */

    on rbWork changed state do SetWorkMode state
    on rbTab changed state do SetTab state

    on FRAMER_UI open do
    (
        callbacks.removeScripts id:#FRAMER_SEL
        callbacks.addScript #selectionSetChanged "try(FRAMER_UI.FR_SelChanged())catch()" id:#FRAMER_SEL

        SetTab 1
        SetWorkMode 1
        UpdateArcUI()
        UpdateRoofUI()
        FR_RefreshPresets()
    )

    on FRAMER_UI close do callbacks.removeScripts id:#FRAMER_SEL

    on rbMode changed state do
    (
        -- un seul des trois modes à la fois
        spLength.enabled = (state == 1)
        l_spLength.enabled = (state == 1)

        if state == 1 then
        (
            l_spGround.text = "Hauteur du rez-de-chaussée :"
            l_spUpper.text = "Hauteur de l'étage :"
            lbInfo.text = "Mode dimensions : crée une nouvelle façade."
        )
        else if state == 2 then
        (
            l_spGround.text = "Rez-de-chaussée (proportion) :"
            l_spUpper.text = "Hauteur de l'étage (proportion) :"
            lbInfo.text = "Mode face : les hauteurs saisies servent de proportions."
        )
        else
        (
            l_spGround.text = "Hauteur du rez-de-chaussée :"
            l_spUpper.text = "Hauteur de l'étage :"
            lbInfo.text = "Mode contour : choisissez une spline FERMÉE, puis Générez."
        )
    )

    on pbCont picked obj do
    (
        if obj != undefined do
        (
            if not (try(isClosed obj 1)catch(false)) then
                messageBox "La spline du contour doit être FERMÉE (Éditable spline : fermer)."
            else
                lbInfo.text = "Contour : " + obj.name + " (" + ((numKnots obj 1) as string) + " sommets). Cliquez sur GÉNÉRER."
        )
    )

    on spFloors buttonup do
    (
        SyncFloorCount()
        FR_LiveTick()
    )

    on spFloors entered do
    (
        SyncFloorCount()
        FR_LiveTick()
    )

    on rbFloors changed state do
    (
        local indep = (state == 2)

        spFloorSel.enabled = indep
        btCopyAll.enabled = indep

        if indep then
        (
            -- première fois : les étages partent des valeurs affichées ; ensuite on retrouve ses réglages
            if not flCustom do StoreAll()

            flCustom = true

            FitFloorArrays()

            curFloor = 1
            spFloorSel.range = [1, spFloors.value, 1]

            LoadFloor 1
        )

        FR_LiveTick()
    )

    on spFloorSel changed val do
    (
        StoreFloor curFloor

        curFloor = val

        LoadFloor curFloor
    )

    on btCopyAll pressed do
    (
        StoreAll()
        FR_LiveTick()
    )

    on btRoll pressed do
    (
        spSeed.value = ((mod (timeStamp()) 99999) as integer) + 1

        FR_LiveTick()
    )

    /* ----- segments du contour ----- */

    on spSeg changed val do
    (
        if FR_CSegs.count > 1 and val >= 1 and val <= FR_CSegs.count do
        (
            FR_CSegs[FR_CurSeg] = FR_ReadUI()

            FR_CurSeg = val

            FR_WriteUI FR_CSegs[val]
        )
    )

    on btCopySeg pressed do
    (
        if FR_CSegs.count > 1 do
        (
            local src = FR_ReadUI()

            for k = 1 to FR_CSegs.count do
            (
                FR_CSegs[k].width = src.width
                FR_CSegs[k].bays = src.bays
                FR_CSegs[k].pier = src.pier
                FR_CSegs[k].groundMode = src.groundMode
                FR_CSegs[k].entrance = src.entrance
                FR_CSegs[k].entranceFactor = src.entranceFactor
                FR_CSegs[k].seedVal = src.seedVal + k - 1
                FR_CSegs[k].variation = src.variation
                FR_CSegs[k].widthVar = src.widthVar
                FR_CSegs[k].allowWide = src.allowWide
                FR_CSegs[k].allowBalcony = src.allowBalcony
                FR_CSegs[k].allowWall = src.allowWall
                FR_CSegs[k].mixOut = src.mixOut
                FR_CSegs[k].mixIn = src.mixIn
                FR_CSegs[k].arcType = src.arcType
                FR_CSegs[k].arcRecess = src.arcRecess
                FR_CSegs[k].arcLintel = src.arcLintel
                FR_CSegs[k].arcGlArch = src.arcGlArch
            )

            FR_DoUpdateContour false
        )
    )

    /* ----- GÉNÉRER UNE NOUVELLE FAÇADE ----- */

    on btGenerate pressed do
    (
        local PR = FR_ReadUI()

        local basis = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]

        local valid = true

        if rbMode.state == 2 then
        (
            local info = undefined

            if selection.count == 1 then
                info = FR_GetSelectedFace selection[1]
            else
                messageBox "Sélectionnez un seul objet Editable Poly."

            if info == undefined then
            (
                valid = false
            )
            else
            (
                basis = info[1]
                PR.width = info[2]

                -- on met à l'échelle le rez-de-chaussée et les étages pour remplir la hauteur de la face
                local sumH = PR.groundH

                for k = 1 to PR.flH.count do sumH = sumH + PR.flH[k]

                local factor = info[3] / sumH

                PR.groundH = PR.groundH * factor

                for k = 1 to PR.flH.count do PR.flH[k] = PR.flH[k] * factor
            )
        )
        else if rbMode.state == 3 then
        (
            local shp = pbCont.object
            local pts = undefined

            -- la spline a pu être supprimée depuis le choix : on vérifie qu'elle existe encore
            if shp == undefined or not (isValidNode shp) then
            (
                messageBox "Le contour choisi n'existe plus (ou n'a pas été choisi) : choisissez à nouveau la spline."
                pbCont.object = undefined
            )
            else
                pts = FR_ReadContour shp

            if pts == undefined then
            (
                valid = false
            )
            else
            (
                local n = pts.count
                local widths = #()

                for k = 1 to n do
                (
                    local k2 = k + 1

                    if k2 > n do k2 = 1

                    append widths (length (pts[k2] - pts[k]))
                )

                local PR1 = FR_ReadUI()

                -- pas de travée visé, déduit du premier segment : sert à calculer
                -- le nombre de travées des autres côtés
                local bayPitch = amax #((PR1.width - (PR1.bays+1)*PR1.pier), 1.0) / PR1.bays

                PR1.width = widths[1]

                local segs = #(PR1)

                for k = 2 to n do
                (
                    local PRk = FRParams()

                    -- verticale et communs : identiques au premier segment
                    PRk.groundH = PR1.groundH
                    PRk.floors = PR1.floors
                    PRk.flH = (FR_CopyArr PR1.flH)
                    PRk.flMode = (FR_CopyArr PR1.flMode)
                    PRk.flWin = (FR_CopyArr PR1.flWin)
                    PRk.flHt = (FR_CopyArr PR1.flHt)
                    PRk.flSill = (FR_CopyArr PR1.flSill)
                    PRk.flBalc = (FR_CopyArr PR1.flBalc)
                    PRk.flBalcD = (FR_CopyArr PR1.flBalcD)
                    PRk.flBalcVar = (FR_CopyArr PR1.flBalcVar)
                    PRk.balcD = PR1.balcD
                    PRk.balcVar = PR1.balcVar
                    PRk.mixOut = PR1.mixOut
                    PRk.mixIn = PR1.mixIn
                    PRk.panOpaque = PR1.panOpaque
                    PRk.depth = PR1.depth
                    PRk.fw = PR1.fw
                    PRk.cornice = PR1.cornice
                    PRk.upperH = PR1.upperH
                    PRk.upperMode = PR1.upperMode
                    PRk.winPct = PR1.winPct
                    PRk.winHt = PR1.winHt
                    PRk.winSill = PR1.winSill
                    PRk.railMode = PR1.railMode
                    PRk.railH = PR1.railH
                    PRk.railD = PR1.railD
                    PRk.shutPct = PR1.shutPct
                    PRk.shutOpen = PR1.shutOpen
                    PRk.capMode = PR1.capMode
                    PRk.capD = PR1.capD
                    PRk.capPct = PR1.capPct
                    PRk.surr = PR1.surr
                    PRk.surrS = PR1.surrS
                    PRk.surrProf = PR1.surrProf
                    PRk.arcPct = PR1.arcPct
                    PRk.colWall = PR1.colWall
                    PRk.colFrame = PR1.colFrame
                    PRk.colPier = PR1.colPier
                    PRk.colGlass = PR1.colGlass
                    PRk.colDoor = PR1.colDoor
                    PRk.colShut = PR1.colShut
                    PRk.colRoof = PR1.colRoof
                    PRk.colPanel = PR1.colPanel
                    PRk.roofMode = PR1.roofMode
                    PRk.roofPitch = PR1.roofPitch
                    PRk.roofOver = PR1.roofOver
                    PRk.roofPar = PR1.roofPar
                    PRk.roofDepth = PR1.roofDepth
                    PRk.acrTh = PR1.acrTh
                    PRk.acrGorge = PR1.acrGorge
                    PRk.mansTop = PR1.mansTop
                    PRk.mansP2 = PR1.mansP2
                    PRk.ridgeMode = PR1.ridgeMode
                    PRk.ridgeW = PR1.ridgeW
                    PRk.ridgeH = PR1.ridgeH
                    PRk.lucMode = PR1.lucMode
                    PRk.lucW = PR1.lucW
                    PRk.lucH = PR1.lucH
                    PRk.lucStep = PR1.lucStep

                    -- horizontal : recalculé pour ce segment (même pas de travée)
                    PRk.width = widths[k]
                    PRk.bays = amax #(1, (((widths[k] - PR1.pier) / (bayPitch + PR1.pier)) as integer))
                    PRk.pier = PR1.pier
                    PRk.groundMode = PR1.groundMode
                    PRk.entrance = PR1.entrance
                    PRk.entranceFactor = PR1.entranceFactor
                    PRk.doorH = PR1.doorH
                    PRk.nDoors = PR1.nDoors
                    PRk.seedVal = PR1.seedVal + k - 1
                    PRk.variation = PR1.variation
                    PRk.widthVar = PR1.widthVar
                    PRk.allowWide = PR1.allowWide
                    PRk.allowBalcony = PR1.allowBalcony
                    PRk.allowWall = PR1.allowWall
                    PRk.arcType = PR1.arcType
                    PRk.arcRecess = PR1.arcRecess
                    PRk.arcLintel = PR1.arcLintel
                    PRk.arcGlArch = PR1.arcGlArch

                    append segs PRk
                )

                FR_CPts = pts
                FR_CSegs = segs
                FR_CurSeg = 1

                FR_Silent = false

                if FR_Validate segs[1] then
                (
                    local root = undefined
                    local ok = false

                    undo "Générer un bâtiment FRAMER" on
                    (
                        root = FR_NewRoot (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
                        ok = FR_BuildContour pts segs root cbMerge.checked

                        if ok == true then
                            select root
                        else
                            delete root
                    )

                    if ok == true do
                    (
                        FR_WriteUI segs[1]
                        lbInfo.text = FR_Summary
                    )

                    redrawViews()
                )

                valid = false
            )
        )

        FR_Silent = false

        if valid and FR_Validate PR then
        (
            local root = undefined
            local ok = false

            undo "Générer une façade FRAMER" on
            (
                root = FR_NewRoot basis
                ok = FR_Build PR root cbMerge.checked

                if ok == true then
                    select root
                else
                    delete root
            )

            if ok == true then
            (
                -- affiche les valeurs réelles (le mode face les calcule)
                FR_WriteUI PR
                lbInfo.text = FR_Summary
            )

            redrawViews()
        )
    )

    /* ----- METTRE À JOUR / CHARGER / SUPPRIMER ----- */

    on btUpdate pressed do FR_DoUpdate false

    on btLoad pressed do
    (
        local root = FR_SelectedRoot()

        if root == undefined then
        (
            messageBox "Sélectionnez d'abord une façade FRAMER (n'importe quelle partie)."
        )
        else
        (
            FR_LoadRoot root
            FR_LastRoot = root
            lbEdit.text = "Façade en édition : " + root.name
            lbInfo.text = "Chargée : " + root.name

            spSeg.enabled = (FR_CSegs.count > 1)
            btCopySeg.enabled = spSeg.enabled
        )
    )

    on btDelete pressed do
    (
        local root = FR_SelectedRoot()

        if root == undefined then
        (
            messageBox "Sélectionnez d'abord une façade FRAMER (n'importe quelle partie)."
        )
        else
        (
            undo "Supprimer la façade FRAMER" on
            (
                local kids = for c in root.children where (matchPattern c.name pattern:"FRAMER_*") collect c

                if kids.count > 0 do delete kids

                delete root
            )

            FR_CSegs = #()
            FR_CPts = #()

            redrawViews()
        )
    )

    /* ----- guides d'étages, profil, moulures ----- */

    on btGuides pressed do
    (
        local root = FR_SelectedRoot()

        if root == undefined then
        (
            messageBox "Sélectionnez d'abord une façade FRAMER (n'importe quelle partie)."
        )
        else
        (
            undo "Guides d'étages FRAMER" on
            (
                FR_MakeGuides root
            )

            lbInfo.text = FR_Summary

            redrawViews()
        )
    )

    on btProfile pressed do
    (
        local pn = undefined

        undo "Profil de moulure" on
        (
            pn = FR_MakeProfile()
        )

        pbProf.object = pn
        pbProf.caption = pn.name

        select pn

        lbInfo.text = "Profil créé : modifiez ses sommets (vue de dessus) pour modeler la moulure."

        redrawViews()
    )

    on btMold pressed do
    (
        FR_DoMoulding pbProf.object spMoldScale.value spMoldZ.value cbMoldFlip.checked

        redrawViews()
    )

    /* ----- accroches de la mise à jour en direct ----- */

    on spLength buttonup do FR_LiveTick()
    on spLength entered do FR_LiveTick()
    on spGround buttonup do FR_LiveTick()
    on spGround entered do FR_LiveTick()
    on spBays buttonup do FR_LiveTick()
    on spBays entered do FR_LiveTick()
    on spPier buttonup do FR_LiveTick()
    on spPier entered do FR_LiveTick()
    on spDepth buttonup do FR_LiveTick()
    on spDepth entered do FR_LiveTick()
    on spFrame buttonup do FR_LiveTick()
    on spFrame entered do FR_LiveTick()
    on spUpper buttonup do FR_LiveTick()
    on spUpper entered do FR_LiveTick()
    on spWinW buttonup do FR_LiveTick()
    on spWinW entered do FR_LiveTick()
    on spWinH buttonup do FR_LiveTick()
    on spWinH entered do FR_LiveTick()
    on spSill buttonup do FR_LiveTick()
    on spSill entered do FR_LiveTick()
    on spBalcD buttonup do FR_LiveTick()
    on spBalcVar buttonup do FR_LiveTick()
    on spBalcVar entered do FR_LiveTick()
    on spSlabTh buttonup do FR_LiveTick()
    on spSlabTh entered do FR_LiveTick()
    on spPanOp buttonup do FR_LiveTick()
    on spPanOp entered do FR_LiveTick()
    on spBalcD entered do FR_LiveTick()
    on spSeed buttonup do FR_LiveTick()
    on spSeed entered do FR_LiveTick()
    on spVar buttonup do FR_LiveTick()
    on spVar entered do FR_LiveTick()
    on spWidthVar buttonup do FR_LiveTick()
    on spWidthVar entered do FR_LiveTick()
    on spEntW buttonup do FR_LiveTick()
    on spEntW entered do FR_LiveTick()
    on spDoorN buttonup do FR_LiveTick()
    on spDoorN entered do FR_LiveTick()
    on spDoorH buttonup do FR_LiveTick()
    on spDoorH entered do FR_LiveTick()
    on spRailH buttonup do FR_LiveTick()
    on spRailH entered do FR_LiveTick()
    on spRailD buttonup do FR_LiveTick()
    on spRailD entered do FR_LiveTick()
    on spShutPct buttonup do FR_LiveTick()
    on spShutPct entered do FR_LiveTick()
    on spShutOpen buttonup do FR_LiveTick()
    on spShutOpen entered do FR_LiveTick()
    on spCapD buttonup do FR_LiveTick()
    on spCapD entered do FR_LiveTick()
    on spCapPct buttonup do FR_LiveTick()
    on spCapPct entered do FR_LiveTick()
    on spSurrS buttonup do FR_LiveTick()
    on spSurrS entered do FR_LiveTick()
    on spArcPct buttonup do FR_LiveTick()
    on spArcPct entered do FR_LiveTick()
    on spArcR buttonup do FR_LiveTick()
    on spArcR entered do FR_LiveTick()
    on spArcL buttonup do FR_LiveTick()
    on spArcL entered do FR_LiveTick()

    on cbWide changed state do FR_LiveTick()
    on cbBalcony changed state do FR_LiveTick()
    on cbWall changed state do FR_LiveTick()
    on cbCornice changed state do FR_LiveTick()
    on cbMerge changed state do FR_LiveTick()
    on cbArcGl changed state do FR_LiveTick()
    on cbSurr changed state do FR_LiveTick()

    on cpWall changed c do FR_LiveTick()
    on cpFrame changed c do FR_LiveTick()
    on cpPier changed c do FR_LiveTick()
    on cpGlass changed c do FR_LiveTick()
    on cpDoor changed c do FR_LiveTick()
    on cpShut changed c do FR_LiveTick()
    on cpRoof changed c do FR_LiveTick()
    on cpPanel changed c do FR_LiveTick()

    on ddUpper selected i do FR_LiveTick()
    on ddBalc selected i do FR_LiveTick()
    on ddEntrance selected i do FR_LiveTick()
    on ddRail selected i do FR_LiveTick()
    on ddCap selected i do FR_LiveTick()
    on pbSurrProf picked obj do FR_LiveTick()
    on ddGround selected i do
    (
        UpdateArcUI()

        -- auto-réglage de la hauteur des portes selon le type de rdc
        spDoorH.value = (if FR_GroundCodes[i] == "TownHouse" then 2.05 else 3.0)

        FR_LiveTick()
    )

    on ddArc selected i do FR_LiveTick()

    on ddRoof selected i do
    (
        UpdateRoofUI()
        FR_LiveTick()
    )

    on spRoofPitch buttonup do FR_LiveTick()
    on spRoofPitch entered do FR_LiveTick()
    on spRoofOver buttonup do FR_LiveTick()
    on spRoofOver entered do FR_LiveTick()
    on spRoofPar buttonup do FR_LiveTick()
    on spRoofPar entered do FR_LiveTick()
    on spRoofDepth buttonup do FR_LiveTick()
    on spRoofDepth entered do FR_LiveTick()
    on spMansP2 buttonup do FR_LiveTick()
    on spMansP2 entered do FR_LiveTick()
    on spMansTop buttonup do FR_LiveTick()
    on spMansTop entered do FR_LiveTick()
    on ddRidge selected i do FR_LiveTick()
    on spRidgeW buttonup do FR_LiveTick()
    on spRidgeW entered do FR_LiveTick()
    on spRidgeH buttonup do FR_LiveTick()
    on spRidgeH entered do FR_LiveTick()
    on ddLuc selected i do FR_LiveTick()
    on spLucW buttonup do FR_LiveTick()
    on spLucW entered do FR_LiveTick()
    on spLucH buttonup do FR_LiveTick()
    on spLucH entered do FR_LiveTick()
    on spLucStep buttonup do FR_LiveTick()
    on spLucStep entered do FR_LiveTick()
)

createDialog FRAMER_UI
