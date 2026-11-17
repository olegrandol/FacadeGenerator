-- ============================================================================
-- FR_TEST_SLAB.ms — test MINIMAL (étape par étape, étape 1)
-- NE FAIT QUE : contour -> outline vers l'EXTÉRIEUR (débord) -> extrusion
-- d'une épaisseur réglable. PAS de contour intérieur, PAS de gorge,
-- PAS d'acrotère. Juste la dalle.
--
-- Utilisation :
--   1. Run Script -> fenêtre TEST SLAB.
--   2. "Rectangle test" (20 x 10 auto) ou Pick contour (spline fermée).
--   3. "CONSTRUIRE LA DALLE".
--   4. Listener (F11) : lignes T-SLAB.
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
        format "T-SLAB: ECHEC offset, repli sans decalage\n"
        out = pts
    )
    else if nTry > 0 do
        format "T-SLAB: offset reduit a %\n" dd

    out
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

-- ============================================================================
-- LA DALLE : contour offset -> dessus (normal haut) + dessous (normal bas)
-- + tranche périphérique. AUCUN contour intérieur.
-- ============================================================================
fn T_Slab O z0 th mat =
(
    local n = O.count

    format "T-SLAB: O=% sommets z0=% epaisseur=%\n" n z0 th

    for k = 1 to n do
        format "T-SLAB: O[%]=%\n" k O[k]

    if n < 3 or th <= 0.001 do
    (
        format "T-SLAB ANNULE: garde echouee\n"
        undefined
    )
    else
    (
        local zTop = z0 + th

        -- dessus et dessous : 2 jeux de sommets (n chacun)
        local vArr = #()

        for k = 1 to n do append vArr [O[k].x, O[k].y, z0]    -- 1..n   : dessous
        for k = 1 to n do append vArr [O[k].x, O[k].y, zTop]  -- n+1..2n: dessus

        local fTop = #()
        local fBot = #()
        local fSide = #()

        local tris = T_Triangulate O

        format "T-SLAB: triangulation: % triangles\n" tris.count

        for t in tris do
        (
            -- dessus : normal vers le HAUT
            append fTop [n + t[1], n + t[2], n + t[3]]
            -- dessous : normal vers le BAS
            append fBot [t[1], t[3], t[2]]
        )

        -- tranche : normales vers l'EXTÉRIEUR
        for k = 1 to n do
        (
            local k2 = k + 1
            if k2 > n do k2 = 1

            append fSide [k, k2, k2 + n]
            append fSide [k, k2 + n, k + n]
        )

        format "T-SLAB: faces dessus=% dessous=% tranche=%\n" fTop.count fBot.count fSide.count

        -- 3 meshes séparés colorés : dessus VERT, dessous VIOLET, tranche ROUGE
        local mT = mesh name:"TEST_dessus"  vertices:vArr faces:fTop  material:(standardMaterial name:"TEST_m_dessus"  diffuse:(color 60 200 60))
        local mB = mesh name:"TEST_dessous" vertices:vArr faces:fBot  material:(standardMaterial name:"TEST_m_dessous" diffuse:(color 150 60 200))
        local mS = mesh name:"TEST_tranche" vertices:vArr faces:fSide material:(standardMaterial name:"TEST_m_tranche" diffuse:(color 200 60 60))

        update mT
        update mB
        update mS

        for m in #(mT, mB, mS) do
        (
            if (classof m) == Editable_mesh do convertToPoly m
            if (classof m) == Editable_Poly do polyop.setFaceSmoothGroup m #{1..(polyop.getNumFaces m)} 0
            append FR_TESTSLAB_Pool m
        )

        format "T-SLAB: mesh cree OK (3 objets)\n"

        mT
    )
)

rollout FR_TESTSLAB "TEST SLAB (etape 1)"
(
    pickbutton pbContour "Pick contour (spline fermee)" width:250
    button btRect "Rectangle test (20 x 10)" width:250
    spinner spZ "Hauteur z: " range:[0,100,10.0] scale:0.1
    spinner spOver "Outline exterieur (debord): " range:[0,5,0.5] scale:0.05
    spinner spTh "Epaisseur extrusion: " range:[0.001,2,0.5] scale:0.05
    button btBuild "CONSTRUIRE LA DALLE" width:250 height:36
    button btClear "Effacer les objets du test" width:250
    label lbInfo "F11 = Listener : lignes T-SLAB"

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
        addSpline sp #([0,0,0],[20,0,0],[20,10,0],[0,10,0])
        close sp 1
        update sp

        contourNode = sp
        pbContour.text = "Rectangle 20x10 (auto)"
        format "T-SLAB: rectangle cree (4 sommets)\n"
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

            local pts = for k = 1 to (numKnots contourNode 1) collect (in coordsys world (getKnotPoint contourNode 1 k))

            format "T-SLAB: contour % sommets\n" pts.count
            for k = 1 to pts.count do format "T-SLAB: pts[%]=%\n" k pts[k]

            local O = T_OffsetContour pts spOver.value

            format "T-SLAB: O=% sommets\n" O.count

            local slab = T_Slab O spZ.value spTh.value undefined

            if slab == undefined then
                messageBox "DALLE ANNULEE — regardez les lignes T-SLAB dans le Listener (F11)."
            else
                messageBox "DALLE construite : dessus VERT, dessous VIOLET, tranche ROUGE.\nDetail dans le Listener (F11)."
        )
    )

    on btClear pressed do ClearAll()
)

createDialog FR_TESTSLAB
