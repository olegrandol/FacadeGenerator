-- ============================================================================
-- FR_TEST_SLAB.ms — ETAPE 1, version "OUTILS NATIFS MAX"
-- NE FAIT QUE : contour -> outline vers l'EXTÉRIEUR (débord) -> Extrude
-- (MODIFICATEUR NATIF de Max, comme la manip manuelle de l'utilisateur).
-- AUCUN mesh custom, AUCUNE triangulation : si ça ne s'affiche pas,
-- le problème est dans l'affichage, pas dans le calcul.
--
-- Utilisation :
--   1. Run Script -> fenêtre TEST OUTLINE.
--   2. "Rectangle test" (20 x 10 auto) ou Pick contour (spline fermée).
--   3. "OUTLINE + EXTRUDE".
--   4. Listener (F11) : lignes T-OUT.
-- ============================================================================

try (destroyDialog FR_TESTSLAB) catch()

global FR_TESTSLAB_Pool = #()

fn T_Cross2 a b = (a.x * b.y - a.y * b.x)

fn T_PolyArea pts =
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

fn T_PolyCCW pts =
(
    local out = #()

    if (T_PolyArea pts) < 0.0 then
        for k = pts.count to 1 by -1 do append out pts[k]
    else
        for k = 1 to pts.count do append out pts[k]

    out
)

fn T_SegX p1 p2 p3 p4 =
(
    local d1 = T_Cross2 (p2 - p1) (p3 - p1)
    local d2 = T_Cross2 (p2 - p1) (p4 - p1)
    local d3 = T_Cross2 (p4 - p3) (p1 - p3)
    local d4 = T_Cross2 (p4 - p3) (p2 - p3)

    ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))
)

fn T_PolySimple pts =
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

                local adj = (j == i2) or (i == 1 and j == n)

                if not adj and (T_SegX pts[i] pts[i2] pts[j] pts[j2]) do ok = false
            )
        )
    )

    ok
)

fn T_OffsetMitre pts d =
(
    pts = T_PolyCCW pts

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

fn T_OffsetContour pts d =
(
    pts = T_PolyCCW pts

    local out = T_OffsetMitre pts d
    local dd = d
    local nTry = 0

    while nTry < 4 and not ((T_PolySimple out) and (dd >= 0.0 or (T_PolyArea out) > 0.0)) do
    (
        nTry = nTry + 1
        dd /= 2.0
        out = T_OffsetMitre pts dd
    )

    if not (T_PolySimple out) then
    (
        format "T-OUT: ECHEC offset, repli sans decalage\n"
        out = pts
    )
    else if nTry > 0 do
        format "T-OUT: offset reduit a %\n" dd

    out
)

-- spline VISIBLE à partir de points (outil natif Max)
fn T_PtsToSpline pts nm col =
(
    local sp = splineShape pos:[0,0,0]
    local si = addNewSpline sp

    for p in pts do addKnot sp si #corner #line p
    close sp si
    updateShape sp  -- (update est une operation MESH ; sur une spline : updateShape)

    sp.name = nm
    sp.wirecolor = col

    append FR_TESTSLAB_Pool sp

    sp
)

-- mesure le z du FOND du bac = plus bas z parmi les faces orientées vers le
-- HAUT (le dessous de la dalle a le même centre XY mais normale -Z : ignoré.
-- Sur une dalle neuve le résultat = z du dessus ; avec un bac = z du fond)
fn T_MesureFond o =
(
    local zMin = 1e9
    local nf = polyop.getNumFaces o

    for f = 1 to nf do
    (
        if (polyop.getFaceNormal o f).z > 0.9 do
        (
            local z = (polyop.getFaceCenter o f).z
            if z < zMin do zMin = z
        )
    )

    if zMin == 1e9 then 0.0 else zMin
)

rollout FR_TESTSLAB "TEST OUTLINE (etape 1)"
(
    pickbutton pbContour "Pick contour (spline fermee)" width:250
    button btRect "Rectangle test (20 x 10)" width:250
    spinner spOver "Outline exterieur: " range:[0,5,0.5] scale:0.05
    spinner spTh "Extrusion (modif. natif): " range:[0.001,2,0.5] scale:0.05
    spinner spInset "Inset (epaisseur acrotere): " range:[0.01,2,0.3] scale:0.05
    spinner spExtr "Extrusion face milieu (négatif = vers le bas): " range:[-2,-0.01,-0.4] scale:0.05
    button btBuild "OUTLINE + EXTRUDE" width:250 height:36
    button btBac "ETAPE 2 : INSET + EXTRUDE BAS (bac)" width:250 height:36
    button btClear "Effacer les objets du test" width:250
    label lbInfo "F11 = Listener : lignes T-OUT"

    local contourNode = undefined

    fn ClearAll =
    (
        for o in FR_TESTSLAB_Pool where isValidNode o do delete o
        FR_TESTSLAB_Pool = #()
    )

    on btRect pressed do
    (
        ClearAll()

        local sp = splineShape pos:[0,0,0]
        local si = addNewSpline sp
        for p in #([0,0,0],[20,0,0],[20,10,0],[0,10,0]) do addKnot sp si #corner #line p
        close sp si
        updateShape sp

        contourNode = sp
        pbContour.text = "Rectangle 20x10 (auto)"
        format "T-OUT: rectangle cree (4 sommets)\n"
    )

    on pbContour picked obj do
    (
        if obj != undefined and (superclassof obj == Shape) then
        (
            contourNode = obj
            pbContour.text = obj.name + " (" + ((numKnots obj 1) as string) + " sommets)"
        )
        else
            messageBox "Choisissez une SPLINE (ligne fermee)."
    )

    on btBuild pressed do
    (
        if contourNode == undefined then
            messageBox "D'abord : Rectangle test ou Pick contour."
        else
        (
            ClearAll()

            -- supprimer les ANCIENS objets homonymes encore en scène :
            -- une relance du script vide le pool mais laisse les objets, et le
            -- nouveau serait renommé TEST_outline001 ; getNodeByName prendrait
            -- alors le VIEIL objet (cause des doubles extrusions et du L raté)
            local old = getNodeByName "TEST_outline"
            if old != undefined do delete old
            old = getNodeByName "TEST_contour_origine"
            if old != undefined do delete old

            local pts = for k = 1 to (numKnots contourNode 1) collect (in coordsys world (getKnotPoint contourNode 1 k))

            format "T-OUT: contour % sommets\n" pts.count
            for k = 1 to pts.count do format "T-OUT: pts[%]=%\n" k pts[k]

            -- 1) outline vers l'exterieur
            local O = T_OffsetContour pts spOver.value

            format "T-OUT: outline O=% sommets\n" O.count
            for k = 1 to O.count do format "T-OUT: O[%]=%\n" k O[k]

            -- 2) spline VISIBLE de l'outline (rouge) + copie du contour d'origine (blanc)
            local spO = T_PtsToSpline O "TEST_outline" (color 255 30 30)
            local spC = T_PtsToSpline (T_PolyCCW pts) "TEST_contour_origine" (color 255 255 255)

            -- 3) Extrude NATIF de Max sur l'outline (exactement la manip manuelle)
            select spO
            modPanel.addModToSelection (Extrude()) ui:on
            spO.modifiers[#Extrude].amount = spTh.value

            format "T-OUT: Extrude natif applique, amount=%\n" spTh.value
            format "T-OUT: TERMINE — spline rouge = outline, blanche = contour d'origine\n"

            messageBox ("Outline cree : " + (O.count as string) + " sommets.\nSpline ROUGE = outline + Extrude natif (" + (spTh.value as string) + " m).\nSpline BLANCHE = contour d'origine.\nDetail dans le Listener (F11).")
        )
    )

    -- ETAPE 2 : sur la dalle existante (TEST_outline extrudée + convertie),
    -- inset de l'épaisseur d'acrotère puis extrusion négative du fond
    -- = EXACTEMENT la manip manuelle de l'utilisateur (macro Edit_Poly)
    on btBac pressed do
    (
        local o = getNodeByName "TEST_outline"

        if o == undefined then
            messageBox "D'abord : OUTLINE + EXTRUDE (étape 1)."
        else
        (
            -- aplatir la pile : spline + Extrude -> Editable Poly
            select o
            convertToPoly o

            -- faces du DESSUS (normale +Z)
            local topF = #()
            local nf = polyop.getNumFaces o

            for f = 1 to nf do
            (
                if (polyop.getFaceNormal o f).z > 0.9 do append topF f
            )

            format "T-BAC2: poly=% faces=% faces dessus=%\n" nf nf topF.count

            if topF.count == 0 then
                messageBox "Aucune face du dessus trouvée — bizarre."
            else
            (
                local zTop = (polyop.getFaceCenter o topF[1]).z

                -- Garde-fou ANTI-VIEILLE-DALLE : sur une dalle neuve, TOUTES les
                -- faces du dessus sont à z = hauteur d'extrusion. S'il existe déjà
                -- une face du dessus plus bas, un bac a déjà été creusé (ou c'est
                -- un vieil objet homonyme) -> on refuse au lieu d'enfoncer encore
                if ((T_MesureFond o) < zTop - 0.01) then
                    messageBox ("Cette dalle a déjà un bac (ou est un vieil objet) : fond à z=" + ((T_MesureFond o) as string) + ".\nRefais OUTLINE + EXTRUDE (étape 1) d'abord.")
                else
                (
                    -- memoriser les centres des faces du dessus AVANT inset
                    -- (repli si le modificateur perd la sélection)
                    local centers = for f in topF collect polyop.getFaceCenter o f

                    -- UN SEUL Edit_Poly, comme la macro utilisateur :
                    -- inset puis extrusion négative dans le même modificateur.
                    -- IMPORTANT : mode Modify + modificateur COURANT du panneau
                    -- + niveau sous-objet 4, sinon Commit() reste sans effet
                    max modify mode
                    modPanel.addModToSelection (Edit_Poly()) ui:on
                    local ep = o.modifiers[#Edit_Poly]
                    modPanel.setCurrentObject ep
                    subobjectLevel = 4

                    -- SetSelection (et NON Select : Select = enregistrement de
                    -- clic interactif, sans effet en scripté)
                    ep.SetSelection #Face (topF as bitArray)
                    local selBA = ep.GetSelection #Face
                    format "T-BAC2: selection dans Edit_Poly=%\n" (selBA as string)

                    if selBA.isEmpty then
                        messageBox "Edit_Poly a refusé la sélection — colle les traces T-BAC2."
                    else
                    (
                        ep.SetOperation #Inset
                        ep.insetType = 0
                        ep.insetAmount = spInset.value
                        ep.Commit ()

                        format "T-BAC2: inset % commité\n" spInset.value

                        -- après l'inset, la sélection du modificateur doit pointer
                        -- sur le MILIEU (comme interactivement)
                        local midBA = ep.GetSelection #Face
                        format "T-BAC2: selection apres inset=%\n" (midBA as string)

                        if midBA.isEmpty then
                        (
                            -- REPLI : cuire l'inset puis retrouver le milieu par
                            -- les centres (fiable sur les faces simples)
                            format "T-BAC2: selection vide apres inset — repli polyop\n"
                            convertToPoly o

                            local nf2 = polyop.getNumFaces o
                            local midF = #()

                            for f = 1 to nf2 do
                            (
                                if (polyop.getFaceNormal o f).z > 0.9 do
                                (
                                    local c = polyop.getFaceCenter o f
                                    for k = 1 to centers.count do
                                    (
                                        if distance c centers[k] < 0.005 do append midF f
                                    )
                                )
                            )

                            format "T-BAC2: repli — faces milieu=% sur %\n" midF.count nf2

                            if midF.count == 0 then
                                messageBox "Faces du milieu introuvables — colle les traces T-BAC2."
                            else
                                polyop.extrudeFaces o (midF as bitArray) spExtr.value
                        )
                        else
                        (
                            -- chemin normal (macro utilisateur) : extrusion dans
                            -- le MÊME Edit_Poly, la sélection pointe le milieu
                            ep.SetOperation #ExtrudeFace
                            ep.extrudeFaceType = 0
                            ep.extrudeFaceHeight = spExtr.value
                            ep.Commit ()

                            format "T-BAC2: extrusion % commitée\n" spExtr.value

                            -- cuire l'Edit_Poly dans le poly de base
                            convertToPoly o
                        )

                        -- PREUVE PAR LA MESURE (une seule extrusion, jamais deux) :
                        -- le fond doit être à zTop + extrusion
                        local zF = T_MesureFond o
                        local zAtt = zTop + spExtr.value
                        format "T-BAC2: z fond mesuré=% (attendu %)\n" zF zAtt

                        if (abs (zF - zAtt)) > 0.01 then
                            messageBox "Le fond n'est pas à la bonne hauteur — colle les traces T-BAC2."
                        else
                        (
                            format "T-BAC2: BAC TERMINE\n"
                            messageBox "Bac construit (manip native Max) :\noutline + extrude + inset + extrude négatif.\nListener (F11) : lignes T-BAC2."
                        )
                    )
                )
            )
        )
    )

    on btClear pressed do ClearAll()
)

createDialog FR_TESTSLAB
