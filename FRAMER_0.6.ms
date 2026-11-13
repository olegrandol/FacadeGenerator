/*
    FRAMER 0.6.1
    Générateur procédural de façades
    Autodesk 3ds Max 2026

    NOUVEAU EN 0.6.1 :
    - TOITS (nouvel onglet Toit) : toit-terrasse avec acrotère (suit EXACTEMENT le contour,
      polygone triangulé), toit à deux pentes (pignons) ou à quatre pans (croupes).
      Pente, débord et hauteur d'acrotère réglables. Un toit remplace la corniche.
      En mode contour, le faîtage des toits à pentes est aligné sur le plus long segment
      et couvre le rectangle englobant (recommandé pour footprints convexes).

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
global FR_GroundCodes = #("Storefront","Door + sidelight","Alternating storefront / door","Opaque infill","Empty bay","Arcade","Portico")
global FR_ArcCodes = #("Round","Segment","Flat")
global FR_LastRoot = undefined   -- façade actuellement en édition
global FR_UpperCodes = #("Window","Glazed panel","Opaque panel","Plain wall")
global FR_BalcCodes = #("None","Out","In","Cont")
global FR_EntCodes = #("None","Center","Left","Right","Random")
global FR_RailCodes = #("None","Glass","Bars","Solid")
global FR_CapCodes = #("None","Slab","Lam")
global FR_RoofCodes = #("None","Flat","Gable","Hip")

-- valeurs par étage du mode "indépendants" (globales : un local de rollout valait OK)
global FR_gH = #(3.0)
global FR_gMode = #("Window")
global FR_gWin = #(70.0)
global FR_gHt = #(1.5)
global FR_gSill = #(0.9)
global FR_gBalc = #("Out")

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
    fw = 0.12,
    groundMode = "Storefront",
    upperMode = "Window",
    winPct = 70.0,
    winHt = 1.5,
    winSill = 0.9,
    balcD = 0.8,
    seedVal = 1,
    variation = 30.0,
    widthVar = 10.0,
    allowWide = true,
    allowBalcony = false,
    allowWall = false,
    entrance = "Center",
    entranceFactor = 1.6,
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
    -- toit (commun à tout le bâtiment)
    roofMode = "None",
    roofPitch = 30.0,
    roofOver = 0.4,
    roofPar = 0.5,
    roofDepth = 8.0,
    -- un élément par étage d'élévation
    flH = #(),
    flMode = #(),
    flWin = #(),
    flHt = #(),
    flSill = #(),
    flBalc = #()
)

fn FR_Msg txt =
(
    if not FR_Silent do messageBox (FR_Ctx + txt)
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

/* =========================================================
   PARAMÈTRES <-> TEXTE (mémorisés dans le helper racine)
========================================================= */

fn FR_F v =
(
    formattedPrint v format:".4f"
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

    format "FRAMER_PARAMS=4\n" to:ss
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
    format "seedVal=%\n" PR.seedVal to:ss
    format "variation=%\n" (FR_F PR.variation) to:ss
    format "widthVar=%\n" (FR_F PR.widthVar) to:ss
    format "allowWide=%\n" PR.allowWide to:ss
    format "allowBalcony=%\n" PR.allowBalcony to:ss
    format "allowWall=%\n" PR.allowWall to:ss
    format "entrance=%\n" PR.entrance to:ss
    format "entranceFactor=%\n" (FR_F PR.entranceFactor) to:ss
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
    format "roofMode=%\n" PR.roofMode to:ss
    format "roofPitch=%\n" (FR_F PR.roofPitch) to:ss
    format "roofOver=%\n" (FR_F PR.roofOver) to:ss
    format "roofPar=%\n" (FR_F PR.roofPar) to:ss
    format "roofDepth=%\n" (FR_F PR.roofDepth) to:ss
    format "flH=%\n" (FR_JoinF PR.flH) to:ss
    format "flMode=%\n" (FR_JoinS PR.flMode) to:ss
    format "flWin=%\n" (FR_JoinF PR.flWin) to:ss
    format "flHt=%\n" (FR_JoinF PR.flHt) to:ss
    format "flSill=%\n" (FR_JoinF PR.flSill) to:ss
    format "flBalc=%\n" (FR_JoinS PR.flBalc) to:ss

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

    local lines = filterString txt "\r\n"

    for ln in lines do
    (
        local pos = findString ln "="

        if pos != undefined and pos > 1 do
        (
            local k = substring ln 1 (pos-1)
            local v = substring ln (pos+1) ln.count

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
                "seedVal": PR.seedVal = v as integer
                "variation": PR.variation = v as float
                "widthVar": PR.widthVar = v as float
                "allowWide": PR.allowWide = (v == "true")
                "allowBalcony": PR.allowBalcony = (v == "true")
                "allowWall": PR.allowWall = (v == "true")
                "entrance": PR.entrance = v
                "entranceFactor": PR.entranceFactor = v as float
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
                "roofMode": PR.roofMode = v
                "roofPitch": PR.roofPitch = v as float
                "roofOver": PR.roofOver = v as float
                "roofPar": PR.roofPar = v as float
                "roofDepth": PR.roofDepth = v as float
                "flH": PR.flH = for s in (filterString v ",") collect (s as float)
                "flMode": PR.flMode = for s in (filterString v ",") collect s
                "flWin": PR.flWin = for s in (filterString v ",") collect (s as float)
                "flHt": PR.flHt = for s in (filterString v ",") collect (s as float)
                "flSill": PR.flSill = for s in (filterString v ",") collect (s as float)
                "flBalc": PR.flBalc = for s in (filterString v ",") collect s
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

fn FR_Material n c opacityVal =
(
    local res = undefined

    for m in sceneMaterials do
    (
        if m.name == n do res = m
    )

    if res == undefined do res = standardMaterial name:n diffuse:c opacity:opacityVal

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

-- rectangle de mur entre u1..u2 et z1..z2, épaisseur t, sur le plan du mur
fn FR_WallRect n u1 u2 z1 z2 t basis mat =
(
    FR_LocalBox n ((u1+u2)/2) FR_VC ((z1+z2)/2) (u2-u1) t (z2-z1) basis mat
)

/* =========================================================
   CADRE  (depth = épaisseur du mur)
========================================================= */

fn FR_Frame prefix u1 u2 z1 z2 depth fw basis mat =
(
    local midU = (u1+u2)/2
    local midZ = (z1+z2)/2

    FR_LocalBox (prefix+"_Left") (u1+fw/2) FR_VC midZ fw depth (z2-z1) basis mat
    FR_LocalBox (prefix+"_Right") (u2-fw/2) FR_VC midZ fw depth (z2-z1) basis mat
    FR_LocalBox (prefix+"_Top") midU FR_VC (z2-fw/2) (u2-u1) depth fw basis mat
    FR_LocalBox (prefix+"_Bottom") midU FR_VC (z1+fw/2) (u2-u1) depth fw basis mat
)

/* =========================================================
   ÉLÉMENT VITRÉ
========================================================= */

fn FR_Glass prefix u1 u2 z1 z2 depth fw basis frameMat glassMat mullions =
(
    local a = u1+fw
    local b = u2-fw
    local c = z1+fw
    local d = z2-fw

    if b > a and d > c then
    (
        FR_LocalBox (prefix+"_Glass") ((a+b)/2) (FR_VC+depth*0.1) ((c+d)/2) (b-a) (depth*0.28) (d-c) basis glassMat

        FR_Frame prefix u1 u2 z1 z2 depth fw basis frameMat

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

    FR_LocalBox (p+"_RailHand") ((a+b)/2) rv (c+railH+0.025) w (railD+0.04) 0.05 basis frameMat
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
        FR_LocalBox (p+"_Cap") ((a+b)/2) (FR_VC - T/2 - capD/2) (zbase+0.04) (b-a+0.15) capD 0.08 basis frameMat
    else if capK == "Lam" then
    (
        for k = 0 to 4 do
            FR_LocalBox (p+"_Blade_"+(k as string)) ((a+b)/2) (FR_VC - T/2 - capD*0.4) (zbase+0.05+k*0.13) (b-a+0.1) (capD*0.8) 0.035 basis frameMat
    )
)

/* =========================================================
   MUR AVEC OUVERTURE CENTRÉE (trumeaux, allège, linteau + fenêtre)
   Options facultatives (mots-clés) : garde-corps, volet, casquette
========================================================= */

fn FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat winW winH sill railK:"None" railH:1.0 railD:0.15 shutOpen:-1.0 capK:"None" capD:0.4 =
(
    local bw = bu2-bu1
    local h = z2-z1

    -- on garde un linteau minimum au-dessus de la fenêtre
    if sill + winH > h - 0.1 do winH = h - sill - 0.1

    if winH < 0.3 or winW < 0.3 then
    (
        FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat
    )
    else
    (
        local a = bu1 + (bw-winW)/2
        local c = z1 + sill

        FR_WallRect (p+"_WallL") bu1 a z1 z2 T basis wallMat
        FR_WallRect (p+"_WallR") (a+winW) bu2 z1 z2 T basis wallMat
        FR_WallRect (p+"_Sill") a (a+winW) z1 c T basis wallMat
        FR_WallRect (p+"_Lintel") a (a+winW) (c+winH) z2 T basis wallMat

        FR_Glass p a (a+winW) c (c+winH) T fw basis frameMat glassMat 1

        if railK != "None" and sill > 0.05 do
            FR_WinRail p a (a+winW) c T fw basis frameMat glassMat railK (amin #(railH, winH)) railD

        if shutOpen >= 0.0 do
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
    )
)

/* =========================================================
   BALCON SAILLANT (dalle + garde-corps vitré), sort devant les piliers
   proj = saillie au-delà des piliers
========================================================= */

fn FR_Balcony p bu1 bu2 z depth proj basis slabMat railMat glassMat =
(
    local outer = -depth - proj
    local inner = -depth*0.5
    local sy = inner - outer
    local cv = (inner+outer)/2
    local uc = (bu1+bu2)/2
    local bw = bu2-bu1

    FR_LocalBox (p+"_Slab") uc cv (z+0.075) bw sy 0.15 basis slabMat
    FR_LocalBox (p+"_Rail") uc (outer+0.02) (z+0.65) bw 0.03 1.0 basis glassMat
    FR_LocalBox (p+"_RailTop") uc (outer+0.02) (z+1.17) bw 0.06 0.04 basis railMat
    FR_LocalBox (p+"_RailL") (bu1+0.015) cv (z+0.65) 0.03 sy 1.0 basis glassMat
    FR_LocalBox (p+"_RailR") (bu2-0.015) cv (z+0.65) 0.03 sy 1.0 basis glassMat
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

fn FR_Entrance p bu1 bu2 groundH T depth fw basis frameMat glassMat doorMat canopy =
(
    local bw = bu2-bu1
    local dW = amin #(1.2, bw*0.4)
    local dH = amin #(2.4, groundH-0.3)
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

    m.name = nm
    m.material = mat

    append FR_Pool m

    m
)

-- vitrage qui suit l'arche : partie basse rectangulaire construite EXACTEMENT comme une
-- vitrine du premier plan (FR_Glass), puis verre et cadre en arc au-dessus.
-- Les bandes en arc ne gardent que les positions où la courbe s'élève : plus aucune
-- station dégénérée aux naissances de l'arc.
fn FR_ArchGlazing p u1 u2 zsp rise T fw basis frameMat glassMat =
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

    -- partie basse rectangulaire
    FR_Glass p u1 u2 0.0 zsp T fw basis frameMat glassMat 1

    if xsG.count >= 2 do
        FR_StripMesh (p+"_ArchGlass") xsG (for k = 1 to xsG.count collect zsp) yGlass (FR_VC + T*0.1 - T*0.14) (FR_VC + T*0.1 + T*0.14) basis glassMat

    if xsF.count >= 2 do
        FR_StripMesh (p+"_ArchFrame") xsF yLoF yHiF (FR_VC - T/2) (FR_VC + T/2) basis frameMat
)

-- une travée en arcade : mur au-dessus de l'ouverture + vitrine (ou entrée) reculée de "recess"
-- arcType : "Round" plein cintre, "Segment" arc surbaissé, "Flat" linteau droit (portique)
fn FR_Arcade p bu1 bu2 groundH T depth recess lintelH arcType fw basis frameMat glassMat doorMat wallMat isEnt glArch =
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
        FR_Entrance p bu1 bu2 crown T depth fw basis frameMat glassMat doorMat false
    else if glArch and rise >= 0.05 then
        FR_ArchGlazing p bu1 bu2 zsp rise T fw basis frameMat glassMat
    else
        FR_Glass p bu1 bu2 0.0 crown T fw basis frameMat glassMat 1

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

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
    else
        undefined
)

-- toit-terrasse sur un rectangle (u 0..W, v 0..D dans le repère) : dalle + acrotère
fn FR_RoofFlatRect p basis W D z0 over parH mat =
(
    local slabT = 0.2
    local parT = 0.2

    FR_LocalBox (p+"_Slab") (W/2) (D/2) (z0 + slabT/2) (W + over*2) (D + over*2) slabT basis mat

    if parH > 0.05 do
    (
        FR_LocalBox (p+"_ParF") (W/2) (-over + parT/2) (z0 + parH/2) (W + over*2) parT parH basis mat
        FR_LocalBox (p+"_ParB") (W/2) (D + over - parT/2) (z0 + parH/2) (W + over*2) parT parH basis mat
        FR_LocalBox (p+"_ParL") (-over + parT/2) (D/2) (z0 + parH/2) parT (D + over*2) parH basis mat
        FR_LocalBox (p+"_ParR") (W + over - parT/2) (D/2) (z0 + parH/2) parT (D + over*2) parH basis mat
    )
)

-- toit à deux pentes sur un rectangle : faîtage au milieu de v, pignons aux extrémités u
fn FR_RoofGableRect p basis W D z0 pitch over matRoof matWall =
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
    )
)

-- toit à quatre pans sur un rectangle : faîtage raccourci (pentes égales des 4 côtés)
fn FR_RoofHipRect p basis W D z0 pitch over matRoof =
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

-- triangulation d'un polygone planaire (découpe d'oreilles, contour anti-horaire)
fn FR_Triangulate pts =
(
    local tris = #()

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
                        deleteItem rest k
                        clipped = true
                    )
                )
            )

            if not clipped do stuck = true
        )
    )

    tris
)

-- dalle de la terrasse sur le contour : polygone triangulé (dessus, dessous, tranche)
fn FR_RoofSlabContour p pts z0 th mat =
(
    local tris = FR_Triangulate pts

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

            append fArr [a, c, b]
            append fArr [a+n, b+n, c+n]
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

        m.name = p
        m.material = mat

        append FR_Pool m

        m
    )
)

-- toit du contour : terrasse (polygone exact) ou pentes (rectangle englobant, faîtage sur le plus long segment)
fn FR_RoofContour pts segPRs bases totalH =
(
    local PR0 = segPRs[1]
    local roofMat = FR_Material "FRAMER_Roof" (color 122 84 66) 100
    local wallMat = FR_Material "FRAMER_Walls" (color 214 204 188) 100

    if PR0.roofMode == "Flat" then
    (
        FR_RoofSlabContour "FRAMER_Roof_Slab" pts totalH 0.2 roofMat

        -- acrotère : un bandeau par segment, prolongé jusqu'aux colonnes d'angle
        if PR0.roofPar > 0.05 do
        (
            local parT = 0.2

            for k = 1 to pts.count do
            (
                local kL = k - 1
                if kL < 1 do kL = pts.count

                local kR = k + 1
                if kR > pts.count do kR = 1

                local cL = amax #(segPRs[kL].pier, segPRs[k].pier, PR0.depth*2.0)
                local cR = amax #(segPRs[k].pier, segPRs[kR].pier, PR0.depth*2.0)

                FR_LocalBox ("FRAMER_Roof_Par_"+(k as string)) (bases[k][2]/2) (-PR0.depth/2) (totalH + PR0.roofPar/2) (bases[k][2] + (cL+cR)/2 + 0.2) parT PR0.roofPar bases[k][1] roofMat
            )
        )
    )
    else if PR0.roofMode == "Gable" or PR0.roofMode == "Hip" then
    (
        -- le plus long segment donne la direction du faîtage
        local kLong = 1

        for k = 2 to pts.count do
        (
            if bases[k][2] > bases[kLong][2] do kLong = k
        )

        local ex = bases[kLong][1]
        local inw = bases[kLong][2]
        local p1 = pts[kLong]

        local uMin = 0.0
        local uMax = 0.0
        local wMin = 0.0
        local wMax = 0.0

        for p in pts do
        (
            local du = dot (p - p1) ex
            local dw = dot (p - p1) inw

            if du < uMin do uMin = du
            if du > uMax do uMax = du
            if dw < wMin do wMin = dw
            if dw > wMax do wMax = dw
        )

        local bR = matrix3 ex inw [0,0,1] (p1 + ex*uMin + inw*wMin)
        local W = uMax - uMin
        local D = wMax - wMin

        if PR0.roofMode == "Gable" then
            FR_RoofGableRect "FRAMER_Roof" bR W D totalH PR0.roofPitch PR0.roofOver roofMat wallMat
        else
            FR_RoofHipRect "FRAMER_Roof" bR W D totalH PR0.roofPitch PR0.roofOver roofMat
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

fn FR_Generate PR basis noEndPiers:false endExt:0.0 =
(
    local width = PR.width
    local groundH = PR.groundH
    local floors = PR.floors
    local bays = PR.bays
    local pier = PR.pier
    local depth = PR.depth
    local fw = PR.fw
    local balcD = PR.balcD

    -- complète les tableaux par étage (façades créées avec une version plus ancienne)
    PR.flH = FR_FitArr PR.flH floors PR.upperH
    PR.flMode = FR_FitArr PR.flMode floors PR.upperMode
    PR.flWin = FR_FitArr PR.flWin floors PR.winPct
    PR.flHt = FR_FitArr PR.flHt floors PR.winHt
    PR.flSill = FR_FitArr PR.flSill floors PR.winSill
    PR.flBalc = FR_FitArr PR.flBalc floors "None"

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

    local frameMat = FR_Material "FRAMER_Frame" (color 55 62 70) 100
    local pierMat = FR_Material "FRAMER_Piers" (color 135 138 142) 100
    local glassMat = FR_Material "FRAMER_Glass" (color 95 170 205) 42
    local panelMat = FR_Material "FRAMER_Panels" (color 190 188 178) 100
    local doorMat = FR_Material "FRAMER_Door" (color 95 72 52) 100
    local wallMat = FR_Material "FRAMER_Walls" (color 214 204 188) 100

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
            )
            else
            (
                FR_LocalBox ("FRAMER_Pier_"+(k as string)) u (-depth/2) (totalH/2) pier depth totalH basis pierMat
            )
        )
    )

    /* ---------- rez-de-chaussée ---------- */

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
        (
            if (mod i 2) == 1 then
                mode = "Storefront"
            else
                mode = "Door + sidelight"
        )

        if i == entIdx and mode != "Arcade" do mode = "Entrance"

        if mode == "Entrance" then
        (
            FR_Entrance p bu1 bu2 groundH T depth fw basis frameMat glassMat doorMat true
        )
        else if mode == "Arcade" then
        (
            FR_Arcade p bu1 bu2 groundH T depth PR.arcRecess PR.arcLintel arcT fw basis frameMat glassMat doorMat wallMat (i == entIdx) (PR.arcGlArch and not isPort)
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

            FR_LocalBox (p+"_Door") ((bu1+splitU)/2) FR_VC ((z1+z2)/2) doorW (T*0.7) (z2-z1-fw) basis doorMat
            FR_Glass (p+"_Side") splitU bu2 z1 z2 T fw basis frameMat glassMat 0
            FR_LocalBox (p+"_DoorHead") ((bu1+bu2)/2) FR_VC (z2-fw/2) (bu2-bu1) T fw basis frameMat
        )
        -- "Empty bay" : passage ouvert, rien n'est généré
    )

    -- arcades : plafond de la galerie couverte (sous la clef des arches)
    if isArc and PR.arcRecess > 0.3 do
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
        local pf = "FRAMER_F"+(f as string)

        z1 = zs[f]
        z2 = zs[f+1]

        for i = 1 to bays do
        (
            bu1 = bayU[i]
            bu2 = bu1 + bayW[i]

            local bw = bayW[i]

            p = pf + "_B" + (i as string)

            if fm == "Window" then
            (
                local variant = colVar[i]

                -- balcon filant : toutes les travées deviennent des porte-fenêtres
                if kind == "Cont" do variant = "Wide"

                -- tirages volets roulants et casquettes (après les variantes, pour garder la séquence du hasard)
                local railK = PR.railMode
                local shutOpen = -1.0

                if PR.shutPct > 0.0 and (random 0.0 100.0) < PR.shutPct do shutOpen = PR.shutOpen

                local capK = "None"

                if PR.capMode != "None" do
                (
                    if PR.capPct >= 100.0 then
                        capK = PR.capMode
                    else if (random 0.0 100.0) < PR.capPct do
                        capK = PR.capMode
                )

                if variant == "Wall" then
                (
                    FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat
                )
                else if kind == "In" then
                (
                    -- loggia : le réglage d'étage s'applique à toutes les travées
                    FR_Loggia p bu1 bu2 z1 z2 T depth balcD fw basis wallMat frameMat glassMat pierMat
                )
                else
                (
                    if variant == "Window" then
                    (
                        FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat (bw*fWin/100.0) fHt fSill railK:railK railH:PR.railH railD:PR.railD shutOpen:shutOpen capK:capK capD:PR.capD
                    )
                    else
                    (
                        local wideW = amin #((bw*(fWin+15.0)/100.0), (bw*0.92))
                        local wideH = amin #(2.3, (uH-0.25))

                        FR_WallWindow p bu1 bu2 z1 z2 T fw basis wallMat frameMat glassMat wideW wideH 0.0 railK:railK railH:PR.railH railD:PR.railD shutOpen:shutOpen capK:capK capD:PR.capD
                    )

                    -- balcon saillant : réglage d'étage (kind) OU variante tirée au hasard
                    if kind == "Out" or variant == "Balcony" do
                        FR_Balcony p bu1 bu2 z1 depth balcD basis pierMat frameMat glassMat
                )
            )
            else if fm == "Glazed panel" then
            (
                FR_Glass p bu1 bu2 z1 z2 T fw basis frameMat glassMat 1
            )
            else if fm == "Opaque panel" then
            (
                FR_Panel p bu1 bu2 z1 z2 T fw basis frameMat panelMat
            )
            else if fm == "Plain wall" then
            (
                FR_WallRect (p+"_Wall") bu1 bu2 z1 z2 T basis wallMat
            )
        )

        -- balcon filant : une seule dalle sur toute la longueur de la façade
        if kind == "Cont" do FR_Balcony (pf+"_Cont") (-endM) (width+endM) z1 depth balcD basis pierMat frameMat glassMat
    )

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

    if PR.roofMode != "None" do
    (
        local roofMat = FR_Material "FRAMER_Roof" (color 122 84 66) 100

        -- rectangle couvert : du plan des piliers (v = -depth) vers l'arrière (roofDepth)
        local bR = matrix3 basis[1] basis[2] basis[3] (basis[4] + basis[2]*(-depth))
        local W = width + endM*2
        local D = depth + PR.roofDepth

        if PR.roofMode == "Flat" then
            FR_RoofFlatRect "FRAMER_Roof" bR W D totalH PR.roofOver PR.roofPar roofMat
        else if PR.roofMode == "Gable" then
            FR_RoofGableRect "FRAMER_Roof" bR W D totalH PR.roofPitch PR.roofOver roofMat pierMat
        else if PR.roofMode == "Hip" do
            FR_RoofHipRect "FRAMER_Roof" bR W D totalH PR.roofPitch PR.roofOver roofMat
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

fn FR_Build PR root doMerge =
(
    FR_Pool = #()

    local basis = root.transform

    local oldKids = for c in root.children where (matchPattern c.name pattern:"FRAMER_*") collect c

    local ok = FR_Generate PR basis

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

    if shapeNode == undefined or (superclassof shapeNode) != shape then
    (
        FR_Msg "Le contour doit être une spline."
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
        local pts = for k = 1 to (numKnots shapeNode 1) collect ((getKnotPoint shapeNode 1 k) * shapeNode.objectTransform)

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
        FR_Pool = #()

        local bases = FR_ContourSegs pts

        -- hauteur totale commune (la verticale est la même pour tous les segments)
        local PR0 = segPRs[1]
        PR0.flH = FR_FitArr PR0.flH PR0.floors PR0.upperH

        local totalH = PR0.groundH

        for k = 1 to PR0.floors do totalH = totalH + PR0.flH[k]

        -- un segment de façade par côté du contour
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

            if (FR_Generate segPRs[k] bases[k][1] noEndPiers:true endExt:ext) != true do ok = false
        )

        FR_Ctx = ""

        -- colonnes d'angle, centrées sur chaque sommet du contour
        if ok do
        (
            local pierMat = FR_Material "FRAMER_Piers" (color 135 138 142) 100

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
        if ok and PR0.roofMode != "None" do FR_RoofContour pts segPRs bases totalH

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
                -- espace objet -> espace monde
                local pts = for id in ids collect ((polyop.getVert obj id) * obj.objectTransform)

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
            local kp = getKnotPoint node 1 k

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
        for k = 1 to (numKnots node 1) do append pts ((getKnotPoint node 1 k) * node.objectTransform)
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

-- filtre des pickbuttons de splines
fn FR_ShapeFilter o = (superclassof o == shape)

/* =========================================================
   INTERFACE (6 onglets)
========================================================= */

rollout FRAMER_UI "FRAMER | Générateur de façades 0.6.1" width:430
(
    -- valeurs par étage du mode "indépendants" : variables globales FR_gH, FR_gMode, ... (voir plus haut)
    local curFloor = 1
    local flCustom = false   -- true si des valeurs par étage ont été saisies (mode indépendant)

    /* ----- bandeau du haut : mode de travail ----- */

    groupBox gbWork "Mode de travail" pos:[10,6] width:410 height:118
    radioButtons rbWork labels:#("CRÉATION : générer une nouvelle façade","ÉDITION : modifier la façade sélectionnée") columns:1 default:1 pos:[25,26] tooltip:"Création : génère une nouvelle façade. Édition : sélectionnez une façade, elle se charge et les réglages s'appliquent à elle."
    label lbEdit "Nouvelle façade : réglez puis cliquez sur Générer." pos:[25,70] width:390 height:18
    checkbox cbLive "Mise à jour en direct (mode édition)" pos:[25,92] checked:false tooltip:"Applique chaque réglage tout de suite à la façade sélectionnée."

    radioButtons rbTab labels:#("Général","Étages","Rez-de-ch.","Fenêtres","Toit","Variation","Moulures") columns:7 default:1 pos:[18,132] tooltip:"Changer de page de réglages."

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
    spinner spFrame "" pos:[215,480] width:190 range:[0.01,1,0.12] type:#float scale:0.01 tooltip:"Épaisseur des cadres de fenêtres et des bandeaux."
    checkbox cbCornice "Corniche en haut" pos:[25,508] checked:true tooltip:"Ajoute une corniche en haut de la façade."
    checkbox cbMerge "Fusionner en un objet par matériau" pos:[25,528] checked:true tooltip:"Regroupe la façade en un objet par matériau (plus léger). Décoché : chaque élément reste séparé."

    /* ----- onglet 2 : Étages ----- */

    groupBox gb3 "Étages" pos:[10,160] width:410 height:150
    label l_spFloors "Nombre d'étages :" pos:[25,186] width:185 height:16
    spinner spFloors "" pos:[215,184] width:190 range:[1,60,3] type:#integer tooltip:"Nombre d'étages au-dessus du rez-de-chaussée."
    -- un seul des deux modes à la fois
    radioButtons rbFloors labels:#("Identiques (une même hauteur et composition)","Indépendants (réglage étage par étage)") columns:1 default:1 pos:[22,212] tooltip:"Identiques : un seul réglage pour tous les étages. Indépendants : chaque étage a sa hauteur, son type, ses fenêtres et son balcon."
    label l_spFloorSel "Étage n° :" pos:[25,254] width:185 height:16
    spinner spFloorSel "" pos:[215,252] width:190 range:[1,3,1] type:#integer tooltip:"Étage dont vous modifiez les réglages (mode indépendants)." enabled:false
    button btCopyAll "Appliquer cet étage à tous" pos:[25,278] width:380 height:22 tooltip:"Copie les réglages de l'étage affiché sur tous les autres étages." enabled:false
    groupBox gb5 "Réglages de l'étage affiché" pos:[10,318] width:410 height:270
    label l_spUpper "Hauteur de l'étage :" pos:[25,344] width:185 height:16
    spinner spUpper "" pos:[215,342] width:190 range:[2,15,3] type:#float scale:0.1 tooltip:"Hauteur de l'étage affiché (de tous les étages en mode identiques)."
    dropdownList ddUpper "Type de l'étage :" pos:[25,370] width:380 items:#("Fenêtres","Panneaux vitrés","Panneaux pleins","Mur plein") selection:1 tooltip:"Fenêtres dans un mur, panneaux vitrés, panneaux pleins ou mur plein."
    label l_spWinW "Largeur fenêtre (% travée) :" pos:[25,422] width:185 height:16
    spinner spWinW "" pos:[215,420] width:190 range:[20,100,70] type:#float scale:1 tooltip:"Largeur de la fenêtre en pourcentage de la largeur de la travée."
    label l_spWinH "Hauteur fenêtre :" pos:[25,450] width:185 height:16
    spinner spWinH "" pos:[215,448] width:190 range:[0.3,4,1.5] type:#float scale:0.05 tooltip:"Hauteur de la fenêtre."
    label l_spSill "Hauteur d'allège :" pos:[25,478] width:185 height:16
    spinner spSill "" pos:[215,476] width:190 range:[0,3,0.9] type:#float scale:0.05 tooltip:"Hauteur entre le sol de l'étage et le bas de la fenêtre."
    dropdownList ddBalc "Balcons de l'étage :" pos:[25,504] width:380 items:#("Aucun","Saillants","Rentrants (loggias)","Filant (continu)") selection:2 tooltip:"Aucun, saillants, rentrants (loggias) ou filants (dalle continue). S'applique à TOUTES les travées de l'étage."
    label l_spBalcD "Profondeur balcon / loggia :" pos:[25,558] width:185 height:16
    spinner spBalcD "" pos:[215,556] width:190 range:[0.3,2.5,0.8] type:#float scale:0.05 tooltip:"Profondeur des balcons saillants et des loggias."

    /* ----- onglet 3 : Rez-de-chaussée ----- */

    groupBox gb7 "Rez-de-chaussée" pos:[10,160] width:410 height:206
    dropdownList ddGround "Type du rez-de-chaussée :" pos:[25,182] width:380 items:#("Vitrine","Porte + vitrage","Alternance vitrine / porte","Panneaux pleins","Travée vide (passage)","Arcades en arc","Portique à colonnes (type Perret)") selection:1 tooltip:"Composition du rez-de-chaussée."
    dropdownList ddArc "Forme des arcades :" pos:[25,232] width:380 items:#("Plein cintre","Arc surbaissé","Linteau droit (portique)") selection:1 tooltip:"Forme des ouvertures des arcades (type Perret, Le Havre)."
    label l_spArcR "Retrait de la vitrine :" pos:[25,286] width:185 height:16
    spinner spArcR "" pos:[215,284] width:190 range:[0.5,6,2] type:#float scale:0.1 tooltip:"Retrait de la vitrine derrière les arcades (galerie couverte)."
    label l_spArcL "Bande pleine au-dessus :" pos:[25,314] width:185 height:16
    spinner spArcL "" pos:[215,312] width:190 range:[0.2,3,0.6] type:#float scale:0.05 tooltip:"Hauteur de mur plein entre le haut des arcades et le bandeau."
    checkbox cbArcGl "Vitrines en arc (suivent l'arche)" pos:[25,342] checked:true tooltip:"Coché : le vitrage de la galerie suit la forme de l'arche. Décoché : vitrines rectangulaires."
    groupBox gb9 "Travée d'entrée" pos:[10,374] width:410 height:106
    dropdownList ddEntrance "Position de l'entrée :" pos:[25,396] width:380 items:#("Aucune","Centre","Gauche","Droite","Aléatoire") selection:2 tooltip:"Position de la travée d'entrée : plus large, avec porte, vitrages, imposte et auvent."
    label l_spEntW "Largeur de l'entrée (facteur) :" pos:[25,450] width:185 height:16
    spinner spEntW "" pos:[215,448] width:190 range:[1,3,1.6] type:#float scale:0.1 tooltip:"Largeur de la travée d'entrée par rapport aux autres."

    /* ----- onglet 4 : Fenêtres (garde-corps, volets, casquettes) ----- */

    groupBox gb10 "Garde-corps de fenêtres" pos:[10,160] width:410 height:120
    dropdownList ddRail "Type :" pos:[25,182] width:380 items:#("Aucun","Vitré","Barreaudé","Plein") selection:1 tooltip:"Garde-corps devant l'allège des fenêtres à allège."
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

    /* ----- onglet 5 : Toit ----- */

    groupBox gbRoof "Toit" pos:[10,160] width:410 height:250
    dropdownList ddRoof "Type de toit :" pos:[25,182] width:380 items:#("Aucun","Terrasse + acrotère","Deux pentes (pignons)","Quatre pans (croupes)") selection:1 tooltip:"Aucun : façade nue. Terrasse : dalle + acrotère (remplace la corniche). Deux ou quatre pans : toiture en pente."
    label l_spRoofPitch "Pente (degrés) :" pos:[25,232] width:185 height:16
    spinner spRoofPitch "" pos:[215,230] width:190 range:[10,60,30] type:#float scale:1 tooltip:"Pente des versants (toits à deux ou quatre pans)."
    label l_spRoofOver "Débord du toit :" pos:[25,260] width:185 height:16
    spinner spRoofOver "" pos:[215,258] width:190 range:[0,2,0.4] type:#float scale:0.05 tooltip:"Saillie du toit au-delà des murs, sur les 4 côtés."
    label l_spRoofPar "Hauteur de l'acrotère :" pos:[25,288] width:185 height:16
    spinner spRoofPar "" pos:[215,286] width:190 range:[0,2,0.5] type:#float scale:0.05 tooltip:"Garde-corps plein autour de la terrasse (toit-terrasse uniquement)."
    label l_spRoofDepth "Profondeur du bâtiment :" pos:[25,316] width:185 height:16
    spinner spRoofDepth "" pos:[215,314] width:190 range:[2,60,8] type:#float scale:0.5 tooltip:"Profondeur couverte derrière la façade (façade simple ; en mode contour, le toit couvre tout le polygone)."
    label lbRoofHelp "Terrasse : le polygone du contour est couvert exactement, l'acrotère suit chaque segment jusqu'aux colonnes d'angle. Deux/quatre pans : faîtage aligné sur le plus long segment, couverture du rectangle englobant (recommandé pour footprints convexes). Un toit remplace la corniche." pos:[25,350] width:380 height:48

    /* ----- onglet 6 : Variation ----- */

    groupBox gb6 "Variation aléatoire" pos:[10,160] width:410 height:215
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

    button btGenerate "GÉNÉRER" pos:[10,600] width:205 height:32 tooltip:"Crée une nouvelle façade (ou tout le contour) avec les réglages affichés (mode création)."
    button btUpdate "METTRE À JOUR" pos:[215,600] width:205 height:32 tooltip:"Reconstruit la façade sélectionnée avec les réglages affichés (mode édition)."
    button btLoad "Charger la sélection" pos:[10,638] width:205 height:24 tooltip:"Charge dans la fenêtre les réglages de la façade sélectionnée."
    button btDelete "Supprimer la sélection" pos:[215,638] width:205 height:24 tooltip:"Supprime la façade sélectionnée."

    -- mode contour : réglages du segment affiché
    label l_spSeg "Segment n° :" pos:[15,672] width:110 height:16
    spinner spSeg "" pos:[130,670] width:80 range:[1,1,1] type:#integer tooltip:"Segment du contour dont vous modifiez les réglages (côté rue, côté jardin...)." enabled:false
    button btCopySeg "Appliquer ce segment à tous" pos:[230,668] width:190 height:22 tooltip:"Copie les réglages horizontaux du segment affiché sur tous les autres segments." enabled:false

    label lbInfo "Mode création." pos:[15,698] width:400 height:30
    label lbLegend "F fenêtre | P porte-fenêtre | B balcon | M mur plein" pos:[15,732] width:400 height:16

    -- affiche les contrôles de l'onglet n et cache les autres
    fn SetTab n =
    (
        local t1 = (n == 1)
        local t2 = (n == 2)
        local t3 = (n == 3)
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
        lbRoofHelp.visible = t5

        gb6.visible = t6
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
    )

    -- la pente ne sert qu'aux toits à pentes, l'acrotère qu'à la terrasse
    fn UpdateRoofUI =
    (
        local r = FR_RoofCodes[ddRoof.selection]
        local flat = (r == "Flat")
        local sloped = (r == "Gable" or r == "Hip")

        spRoofPitch.enabled = sloped
        l_spRoofPitch.enabled = sloped
        spRoofPar.enabled = flat
        l_spRoofPar.enabled = flat
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

        PR.roofMode = FR_RoofCodes[ddRoof.selection]
        PR.roofPitch = spRoofPitch.value
        PR.roofOver = spRoofOver.value
        PR.roofPar = spRoofPar.value
        PR.roofDepth = spRoofDepth.value

        PR.seedVal = spSeed.value
        PR.variation = spVar.value
        PR.widthVar = spWidthVar.value
        PR.allowWide = cbWide.checked
        PR.allowBalcony = cbBalcony.checked
        PR.allowWall = cbWall.checked
        PR.entrance = FR_EntCodes[ddEntrance.selection]
        PR.entranceFactor = spEntW.value
        PR.cornice = cbCornice.checked

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
        )
        else
        (
            StoreFloor curFloor

            PR.flH = copy FR_gH
            PR.flMode = copy FR_gMode
            PR.flWin = copy FR_gWin
            PR.flHt = copy FR_gHt
            PR.flSill = copy FR_gSill
            PR.flBalc = copy FR_gBalc
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

        spSeed.value = PR.seedVal
        spVar.value = PR.variation
        spWidthVar.value = PR.widthVar
        cbWide.checked = PR.allowWide
        cbBalcony.checked = PR.allowBalcony
        cbWall.checked = PR.allowWall
        spEntW.value = PR.entranceFactor
        cbCornice.checked = PR.cornice

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

        local roi = findItem FR_RoofCodes PR.roofMode
        if roi == 0 do roi = 1
        ddRoof.selection = roi
        spRoofPitch.value = PR.roofPitch
        spRoofOver.value = PR.roofOver
        spRoofPar.value = PR.roofPar
        spRoofDepth.value = PR.roofDepth
        UpdateRoofUI()

        -- valeurs "anciennes façades" : serviront à compléter les tableaux manquants
        spUpper.value = PR.upperH
        spWinW.value = PR.winPct
        spWinH.value = PR.winHt
        spSill.value = PR.winSill

        local ui = findItem FR_UpperCodes PR.upperMode
        if ui == 0 do ui = 1
        ddUpper.selection = ui

        FR_gH = copy PR.flH
        FR_gMode = copy PR.flMode
        FR_gWin = copy PR.flWin
        FR_gHt = copy PR.flHt
        FR_gSill = copy PR.flSill
        FR_gBalc = copy PR.flBalc

        FitFloorArrays()

        -- tous les étages identiques ?
        local same = true

        for k = 2 to FR_gH.count do
        (
            if FR_gH[k] != FR_gH[1] or FR_gMode[k] != FR_gMode[1] or FR_gWin[k] != FR_gWin[1] or FR_gHt[k] != FR_gHt[1] or FR_gSill[k] != FR_gSill[1] or FR_gBalc[k] != FR_gBalc[1] do same = false
        )

        if same then
            rbFloors.state = 1
        else
            rbFloors.state = 2

        flCustom = not same
        spFloorSel.enabled = not same
        btCopyAll.enabled = not same

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
            local vFlH = copy FR_CSegs[FR_CurSeg].flH
            local vFlMode = copy FR_CSegs[FR_CurSeg].flMode
            local vFlWin = copy FR_CSegs[FR_CurSeg].flWin
            local vFlHt = copy FR_CSegs[FR_CurSeg].flHt
            local vFlSill = copy FR_CSegs[FR_CurSeg].flSill
            local vFlBalc = copy FR_CSegs[FR_CurSeg].flBalc
            local vBalcD = FR_CSegs[FR_CurSeg].balcD
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
            local vRoofK = FR_CSegs[FR_CurSeg].roofMode
            local vRoofP = FR_CSegs[FR_CurSeg].roofPitch
            local vRoofO = FR_CSegs[FR_CurSeg].roofOver
            local vRoofPar = FR_CSegs[FR_CurSeg].roofPar
            local vRoofD = FR_CSegs[FR_CurSeg].roofDepth

            for k = 1 to FR_CSegs.count do
            (
                if k != FR_CurSeg do
                (
                    FR_CSegs[k].groundH = vGH
                    FR_CSegs[k].floors = vFl
                    FR_CSegs[k].flH = copy vFlH
                    FR_CSegs[k].flMode = copy vFlMode
                    FR_CSegs[k].flWin = copy vFlWin
                    FR_CSegs[k].flHt = copy vFlHt
                    FR_CSegs[k].flSill = copy vFlSill
                    FR_CSegs[k].flBalc = copy vFlBalc
                    FR_CSegs[k].balcD = vBalcD
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
                    FR_CSegs[k].roofMode = vRoofK
                    FR_CSegs[k].roofPitch = vRoofP
                    FR_CSegs[k].roofOver = vRoofO
                    FR_CSegs[k].roofPar = vRoofPar
                    FR_CSegs[k].roofDepth = vRoofD
                )
            )

            FR_Silent = silent

            local ok = false

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
            )

            FR_Silent = false
        )
    )

    fn FR_LiveTick =
    (
        if cbLive.checked do FR_DoUpdate true
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

            if shp == undefined then
                messageBox "Choisissez d'abord la spline du contour (fermée)."
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
                    PRk.flH = copy PR1.flH
                    PRk.flMode = copy PR1.flMode
                    PRk.flWin = copy PR1.flWin
                    PRk.flHt = copy PR1.flHt
                    PRk.flSill = copy PR1.flSill
                    PRk.flBalc = copy PR1.flBalc
                    PRk.balcD = PR1.balcD
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
                    PRk.roofMode = PR1.roofMode
                    PRk.roofPitch = PR1.roofPitch
                    PRk.roofOver = PR1.roofOver
                    PRk.roofPar = PR1.roofPar
                    PRk.roofDepth = PR1.roofDepth

                    -- horizontal : recalculé pour ce segment (même pas de travée)
                    PRk.width = widths[k]
                    PRk.bays = amax #(1, (((widths[k] - PR1.pier) / (bayPitch + PR1.pier)) as integer))
                    PRk.pier = PR1.pier
                    PRk.groundMode = PR1.groundMode
                    PRk.entrance = PR1.entrance
                    PRk.entranceFactor = PR1.entranceFactor
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
    on spBalcD entered do FR_LiveTick()
    on spSeed buttonup do FR_LiveTick()
    on spSeed entered do FR_LiveTick()
    on spVar buttonup do FR_LiveTick()
    on spVar entered do FR_LiveTick()
    on spWidthVar buttonup do FR_LiveTick()
    on spWidthVar entered do FR_LiveTick()
    on spEntW buttonup do FR_LiveTick()
    on spEntW entered do FR_LiveTick()
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

    on ddUpper selected i do FR_LiveTick()
    on ddBalc selected i do FR_LiveTick()
    on ddEntrance selected i do FR_LiveTick()
    on ddRail selected i do FR_LiveTick()
    on ddCap selected i do FR_LiveTick()
    on ddGround selected i do
    (
        UpdateArcUI()
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
)

/* =========================================================
   OUVERTURE DE L'INTERFACE
========================================================= */

createDialog FRAMER_UI
