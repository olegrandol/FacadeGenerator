-- ============================================================================
-- FR_TEST_BAC.ms — script de test ISOLÉ (ne touche pas à FRAMER)
-- Construit UNIQUEMENT le bac de terrasse (acrotère + plateau enfoncé)
-- à partir d'un contour, avec TRACES Listener complètes.
--
-- But : vérifier hors de FRAMER si le bac (couronne + fond de gorge) est
-- correct sur un rectangle et sur une forme complexe.
--
-- Utilisation :
--   1. Run Script → la fenêtre TEST BAC s'ouvre.
--   2. Soit "Rectangle test" (contour 20 x 10 créé automatiquement),
--      soit Pick contour : cliquez une spline fermée de la scène.
--   3. Réglez z / débord / épaisseur / parapet / gorge (défauts = FRAMER).
--   4. "Construire le bac" : crée le mesh + des sphères témoins
--      (bleues = sommets extérieurs O, rouges = sommets intérieurs I).
--   5. Ouvrez le Listener (F11) et comparez les traces.
-- ============================================================================

try (destroyDialog FR_TESTBAC) catch()

global FR_TESTBAC_Pool = #()

-- ----------------------------------------------------------------------------
-- Copie EXACTE des fonctions de FRAMER_0.6.ms (0.6.24)
-- ----------------------------------------------------------------------------

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

fn T_InTri p a b c =
(
    local d1 = cross (b-a) (p-a)
    local d2 = cross (c-b) (p-b)
    local d3 = cross (a-c) (p-c)

    ((d1.z >= 0.0) and (d2.z >= 0.0) and (d3.z >= 0.0)) or ((d1.z <= 0.0) and (d2.z <= 0.0) and (d3.z <= 0.0))
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

fn T_DedupPts pts =
(
    local out = #()

    for q in pts do
    (
        if out.count == 0 or (length (q - out[out.count])) > 0.001 do append out q
    )

    if out.count > 1 and (length (out[1] - out[out.count])) <= 0.001 do deleteItem out out.count

    out
)

fn T_OffsetContour pts d dedup:true =
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
        format "T-OFFSET: ECHEC simple, repli sans decalage (d=%)\n" d
        out = pts
    )
    else if nTry > 0 do
        format "T-OFFSET: decalage reduit a % (essais %)\n" dd nTry

    if dedup then T_DedupPts out else out
)

fn T_Triangulate pts =
(
    local tris = #()

    pts = T_PolyCCW pts

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

                if (cross (pts[b]-pts[a]) (pts[c]-pts[b])).z > 0.000001 do
                (
                    local empty = true

                    for m in rest while empty do
                    (
                        if m != a and m != b and m != c and (T_InTri pts[m] pts[a] pts[b] pts[c]) do empty = false
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
                if rest.count == 3 then
                (
                    append tris #(rest[1], rest[2], rest[3])
                    stuck = true
                )
                else
                (
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
                                if m != a and m != b and m != c and (T_InTri pts[m] pts[a] pts[b] pts[c]) do empty = false
                            )

                            if empty do
                            (
                                append tris #(a, b, c)
                                deleteItem rest k2
                                relaxed = true
                            )
                        )
                    )

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

-- ----------------------------------------------------------------------------
-- LE BAC — copie exacte de FR_RoofBac + traces détaillées
-- DIAGNOSTIC COULEUR : chaque groupe de faces a sa propre matériau/couleur :
--   paroi extérieure = ROUGE, couronne (dessus acrotère) = VERT,
--   paroi intérieure de la gorge = BLEU, fond de gorge = JAUNE,
--   dessous = VIOLET. Une zone NOIRE = faces de ce groupe mal orientées.
-- ----------------------------------------------------------------------------
fn T_RoofBac O I z0 pT gorge mat =
(
    local n = O.count

    format "T-BAC: O=% I=% parapet=% gorge=% z0=%\n" n I.count pT gorge z0

    if n < 3 or I.count != n or pT <= 0.05 do
        format "T-BAC ANNULE: garde echouee\n"

    if n >= 3 and I.count == n and pT > 0.05 do
    (
        if gorge > pT - 0.05 do gorge = pT - 0.05

        local zTop = z0 + pT
        local zFlr = z0 + (pT - gorge)

        format "T-BAC: zTop=% zFlr=%\n" zTop zFlr

        for k = 1 to n do
            format "T-BAC: O[%]=% I[%]=%\n" k O[k] k I[k]

        local vArr = #()

        -- matériaux par groupe (diagnostic couleur)
        local mExt   = standardMaterial name:"TEST_paroi_ext"  diffuse:(color 200 60 60)
        local mCrown = standardMaterial name:"TEST_couronne"   diffuse:(color 60 200 60)
        local mInt   = standardMaterial name:"TEST_paroi_int"  diffuse:(color 60 60 200)
        local mFlr   = standardMaterial name:"TEST_fond_gorge" diffuse:(color 230 230 60)
        local mBot   = standardMaterial name:"TEST_dessous"    diffuse:(color 150 60 200)

        for k = 1 to n do
        (
            append vArr [O[k].x, O[k].y, z0]
            append vArr [O[k].x, O[k].y, zTop]
            append vArr [I[k].x, I[k].y, zTop]
            append vArr [I[k].x, I[k].y, zFlr]
        )

        local totA = abs (T_PolyArea O)
        local nGorge = 0

        -- groupes : 1..2n = paroi ext (rouge), 2n+1..4n = couronne (vert),
        -- 4n+1..6n = paroi int (bleu), puis fond (jaune), dessous (violet)
        local fExt = #(), fCrown = #(), fInt = #()
        local fFlr = #(), fBot = #()

        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            append fExt [k, k2, k2+n]
            append fExt [k, k2+n, k+n]

            append fCrown [k+n, k2+n, k2+2*n]
            append fCrown [k+n, k2+2*n, k+2*n]

            append fInt [k+2*n, k2+3*n, k+3*n]
            append fInt [k+2*n, k2+2*n, k2+3*n]
        )

        local tris = T_Triangulate I

        format "T-BAC: triangulation fond de gorge: % triangles\n" tris.count

        for t in tris do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            local tA = abs ((I[b].x-I[a].x)*(I[c].y-I[a].y) - (I[c].x-I[a].x)*(I[b].y-I[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 then
            (
                append fFlr [3*n+a, 3*n+b, 3*n+c]
                nGorge = nGorge + 1
            )
            else
                format "T-BAC: triangle gorge REJETE (tA=% totA=%)\n" tA totA
        )

        format "T-BAC: faces fond de gorge retenues: %\n" nGorge

        local nDess = 0

        local tris2 = T_Triangulate O

        for t in tris2 do
        (
            local a = t[1]
            local b = t[2]
            local c = t[3]

            local tA = abs ((O[b].x-O[a].x)*(O[c].y-O[a].y) - (O[c].x-O[a].x)*(O[b].y-O[a].y)) / 2.0

            if totA <= 0.0 or tA <= totA * 1.01 then
            (
                append fBot [a, c, b]
                nDess = nDess + 1
            )
            else
                format "T-BAC: triangle dessous REJETE (tA=% totA=%)\n" tA totA
        )

        format "T-BAC: faces dessous retenues: %\n" nDess

        -- 5 meshes séparés (un par groupe coloré) pour un diagnostic sans ambiguïté
        local res = #()

        local mshE = mesh name:"TEST_paroi_ext"   vertices:vArr faces:fExt   material:mExt
        local mshC = mesh name:"TEST_couronne"    vertices:vArr faces:fCrown material:mCrown
        local mshI = mesh name:"TEST_paroi_int"   vertices:vArr faces:fInt   material:mInt

        update mshE
        update mshC
        update mshI

        append res mshE
        append res mshC
        append res mshI

        if fFlr.count > 0 do
        (
            local mshF = mesh name:"TEST_fond_gorge" vertices:vArr faces:fFlr material:mFlr
            update mshF
            append res mshF
        )

        if fBot.count > 0 do
        (
            local mshB = mesh name:"TEST_dessous" vertices:vArr faces:fBot material:mBot
            update mshB
            append res mshB
        )

        for m in res do
        (
            if (classof m) == Editable_mesh do convertToPoly m
            if (classof m) == Editable_Poly do polyop.setFaceSmoothGroup m #{1..(polyop.getNumFaces m)} 0
            append FR_TESTBAC_Pool m
        )

        format "T-BAC: mesh cree OK (% objets groupes)\n" res.count

        res[1]
    )
)

-- ----------------------------------------------------------------------------
-- Interface
-- ----------------------------------------------------------------------------
rollout FR_TESTBAC "TEST BAC (acrotere seul)"
(
    pickbutton pbContour "Pick contour (spline fermee)" width:250
    button btRect "Rectangle test (20 x 10)" width:250
    spinner spZ "Hauteur z du bac: " range:[0,100,10.0] scale:0.1
    spinner spOver "Debord: " range:[0,5,0.5] scale:0.05
    spinner spTh "Epaisseur acrotere: " range:[0.05,2,0.55] scale:0.05
    spinner spPar "Hauteur parapet: " range:[0.05,3,0.6] scale:0.05
    spinner spGorge "Gorge: " range:[0,3,0.4] scale:0.05
    button btBuild "CONSTRUIRE LE BAC" width:250 height:36
    button btClear "Effacer les objets du test" width:250
    label lbInfo "F11 = Listener pour les traces T-BAC"

    local contourNode = undefined

    fn ClearAll =
    (
        for o in FR_TESTBAC_Pool where isValidNode o do delete o
        FR_TESTBAC_Pool = #()
    )

    fn MarkerPts pts col nm zbase =
    (
        for k = 1 to pts.count do
        (
            local s = sphere radius:0.08 pos:[pts[k].x, pts[k].y, zbase] wirecolor:col
            s.name = nm + "_" + (k as string)
            append FR_TESTBAC_Pool s
        )
    )

    on btRect pressed do
    (
        ClearAll()

        -- NOTE : addSpline (avec tableau de points) n'existe pas en 2026 ->
        -- addNewSpline + addKnot, la forme canonique
        local sp = splineShape pos:[0,0,0]
        local si = addNewSpline sp
        for p in #([0,0,0],[20,0,0],[20,10,0],[0,10,0]) do addKnot sp si #corner #line p
        close sp si
        update sp

        contourNode = sp
        pbContour.text = "Rectangle 20x10 (auto)"
        format "T-TEST: rectangle cree (4 sommets)\n"
    )

    on pbContour picked obj do
    (
        if obj != undefined and ( superclassof obj == Shape ) then
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

            local pts = for k = 1 to (numKnots contourNode 1) collect (in coordsys world (getKnotPoint contourNode 1 k))

            format "T-TEST: contour % sommets\n" pts.count
            for k = 1 to pts.count do format "T-TEST: pts[%]=%\n" k pts[k]

            -- exactement la chaine FRAMER : O = +debord, I = O - epaisseur (sans dedup)
            local O = T_OffsetContour pts spOver.value
            local I = T_OffsetContour O (-spTh.value) dedup:false

            format "T-TEST: O=% sommets I=% sommets (pairing %)\n" O.count I.count (if O.count == I.count then "OK" else "PERDUE")

            local mat = standardMaterial name:"TEST_Roof" diffuse:(color 170 168 162)

            local bac = T_RoofBac O I spZ.value spPar.value spGorge.value mat

            -- temoins visuels AU NIVEAU DU BAC : cyan = O (exterieur), magenta = I (interieur)
            MarkerPts O (color 0 200 255) "TEST_O" spZ.value
            MarkerPts I (color 255 0 200) "TEST_I" spZ.value

            if bac == undefined then
                messageBox "BAC ANNULE — regardez les lignes T-BAC dans le Listener (F11)."
            else
                messageBox ("BAC construit : " + (O.count as string) + " sommets O / " + (I.count as string) + " sommets I.\nCyan = O, magenta = I.\nCouleurs : paroi ext ROUGE, couronne VERT,\nparoi int BLEU, fond de gorge JAUNE, dessous VIOLET.\nUne zone NOIRE = groupe mal oriente.\nDetail dans le Listener (F11).")
        )
    )

    on btClear pressed do ClearAll()
)

createDialog FR_TESTBAC
