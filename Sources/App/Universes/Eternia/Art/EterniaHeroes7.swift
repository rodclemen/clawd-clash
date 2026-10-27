import Foundation

// Heroes: the rest of the Great Rebellion, drawn the same way as EterniaHeroes4.swift. Peekablue's tail, Flutterina's
// wings and Netossa's net cape go behind and round Clawd's body; Light Hope is a robe of rainbow light and Stonedar a
// body of stone, and both still stand on Clawd's four legs. Loo-Kee is agent-only small fry, with full art all the same.

let eterniaHeroes7: [EterniaHero: Persona] = [
    .peekablue: Persona(name: "Peekablue", headTop: 15, signature: 3.6, draw: drawPeekablue),
    .netossa: Persona(name: "Netossa", weapon: .blaster, shot: .thrown(C(0xE8ECF4)), muzzle: (44, 30), handGun: false,
                      headTop: 20, signature: 3.4, draw: drawNetossa),
    .flutterina: Persona(name: "Flutterina", motion: .fly, headTop: 16, signature: 3.2, draw: drawFlutterina),
    .lightHope: Persona(name: "Light Hope", motion: .hover, canSit: false, headTop: 5, signature: 3.6,
                        draw: drawLightHope),
    .stonedar: Persona(name: "Stonedar", weapon: .saber, armoured: true, headTop: 22, signature: 3.6,
                       draw: drawStonedar),
    .looKee: Persona(name: "Loo-Kee", headTop: 14, signature: 4.0, draw: drawLooKee),
]

private let none = C(0, 0)

/// A solid line from one point to another, `r` from its centre (a feather, an arm, a crack).
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.7) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: none, coreR: r, glowR: r + 0.1)
}

/// Boots on the four legs: `col` for the bottom `rows`, a lit cuff along the top and a shaded toe.
private func cuffedBoots(_ c: PixelCanvas, step: Int, rows: Int, _ col: Px, _ lit: Px, _ dark: Px) {
    drawBoots(c, col, step: step, rows: rows)
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let bottom = step >= 0 && i % 2 == step ? 42 : 43
        c.rect(lx, bottom - rows + 1, 2, 1, lit); c.px(lx + 1, bottom, dark)
    }
}

// MARK: - Peekablue

/// Peekablue: the rebel who sees far off through the eyes in her tail. Long pale-gold hair in strands, a crest of
/// three little blue feathers on her crown, each tipped with an eye, a white tunic with a royal-blue neckline, belt
/// and skirt, blue boots, and a great peacock tail, teal and green, folded behind her into a long train that sweeps
/// down to the ground, its eyes shut. Her long hair falls in strands either side, to her waist behind. She doesn't fight. Signature: she fans the tail up into a wheel behind her, every
/// gold-ringed eye on it opening wide, holds it, and folds it away again.
private func drawPeekablue(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF0D88A), hairD = C(0xC4A85A), hairL = C(0xFFF0BE)
    let tunic = C(0xF4F4FA), tunicD = C(0xC6C8D8), tunicF = C(0xDADCE8)
    let blue = C(0x2E5AD8), blueD = C(0x1E3C9C), blueL = C(0x5A86F4)
    let s = p.signature ?? -1
    let fan = s < 0 ? 0 : habitArc(s, hold: 0.5)
    let open = max(0, (fan - 0.65) / 0.35)

    if fan > 0.08 { peacockFan(c, spread: fan, open: open, t: p.t) } else { peacockTrain(c) }
    drawLegs(c, Look(), step: p.step)
    cuffedBoots(c, step: p.step, rows: 4, blue, blueL, blueD)
    c.oy += p.breathe
    drawBody(c, Look(arm: tunic), armRight: p.armRaise)
    // The white tunic under a blue neckline, a fold either side; the blue belt with a feather-eye clasp; the blue
    // skirt over her legs in pleats, lit on the left.
    c.rect(18, 33, 20, 3, tunic); c.rect(37, 33, 1, 3, tunicD)
    c.rect(18, 33, 20, 1, blue); c.rect(18, 33, 6, 1, blueL); c.rect(36, 33, 2, 1, blueD)
    c.rect(21, 34, 1, 2, tunicF); c.rect(34, 34, 1, 2, tunicF)
    c.rect(15, 35, 3, 1, blue); c.rect(38, 35 - p.armRaise, 3, 1, blue)   // blue cuffs
    c.rect(18, 36, 20, 1, blueD)
    c.pattern(26, 35, [".G.", "GTG", ".G."], ["G": C(0xE8C848), "T": C(0x22A88A)])
    for y in 37...39 where y + c.oy <= 42 {
        let w = y == 39 ? 1 : 0
        c.rect(18 - w, y, 20 + 2 * w, 1, blue)
        for x in [21, 25, 30, 34] { c.px(x, y, blueD) }
        c.px(18 - w, y, blueL)
    }
    // The hair: a soft fringe, parted, and long either side in strands down past her shoulders.
    c.pattern(15, 20, [
        ".......HHHHHlHHHHH......",
        ".....HHHlHHHHHlHHHHH....",
        "...HHHhHHHHhHHHHhHHHHH..",
        "..HHhHHHHhHHHHHHHhHHHHH.",
        ".HHhHHHHhHHHhHHHHHhHHHH.",
        ".HHhh.hH..hH...hH..hhHHH",
        ".HHh...............hHHHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HhH..................hHH",
        "Hh...................hH.",
        ".h....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The long locks either side, out past her face and down over her shoulders in strands, a darker edge so the
    // white outline doesn't swallow the pale gold: down her back to her waist behind, to her shoulder in front.
    c.pattern(12, 24, [
        "....HH",
        "...HHH",
        "..hHlH",
        ".hHlHH",
        ".hHlHh",
        "hHlHHh",
        "hHlHhh",
        "hHlHh.",
        "hHlHh.",
        "hHlHh.",
        ".hlHh.",
        ".hH.h.",
        "..h...",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.pattern(37, 24, [
        "HH....",
        "HHH...",
        "HlHh..",
        "HHlHh.",
        "hHlHh.",
        "hHlHHh",
        "hHlHhh",
        ".hlHh.",
        "..hh..",
    ], ["H": hair, "h": hairD, "l": hairL])
    // Her front arm over the lock, its blue cuff.
    c.rect(38, 33 - p.armRaise, 3, 3, tunic); c.rect(38, 35 - p.armRaise, 3, 1, blue)
    // The crest: three blue feathers fanned up from her crown, each tipped with a little gold-ringed eye.
    let crest: [(Double, Double)] = [(25, 14.5), (28.5, 13), (32, 14.5)]
    for (x, y) in crest {
        line(c, 28.5, 20.5, x, y + 2, blue, 0.6)
        c.pattern(Int(x) - 1, Int(y) - 1, [".G.", "GBG", ".G."], ["G": C(0xE8C848), "B": blueD])
    }
    c.px(28, 19, blueL)
}

/// The tail folded: a long train of feathers from her rump down and back to the ground, in strokes, the shut eyes
/// near their tips a gold line each.
private func peacockTrain(_ c: PixelCanvas) {
    let teal = C(0x24907A), tealD = C(0x186654), tealL = C(0x52C4A4)
    c.pattern(4, 29, [
        "..........TTTTL",
        "........TTTdTTL",
        "......TTTdTTTdT",
        ".....TTdTTTdTTT",
        "....TTdTTTdTTTd",
        "...TTdTTTdTTTdT",
        "..TTdTTTdTTTdT.",
        "..TdTTTdTTTdTT.",
        ".TTTTdTTTdTTT..",
        ".TdTTTTdTTTT...",
        "TTTdTTTTdT.....",
        "TLTTdTTT.......",
        "LTLTTT.........",
    ], ["T": teal, "d": tealD, "L": tealL])
    // The shut eyes along the train's lower edge.
    for (x, y) in [(5, 39), (8, 37), (11, 35)] {
        c.rect(x, y, 2, 1, C(0xE8C848)); c.px(x + 1, y + 1, C(0x1E3C9C))
    }
}

/// The tail fanned: a wheel of feathers behind her, from her rump up over her head, `spread` (0…1) of the way open; a
/// lit rim of feather tips, darker spokes between the feathers, and an eye on each that opens with `open`.
private func peacockFan(_ c: PixelCanvas, spread: Double, open: Double, t: Double) {
    let teal = C(0x24907A), tealD = C(0x186654), tealL = C(0x52C4A4), green = C(0x3AAA5A)
    // Angles as on screen (y down): the wheel opens from back and a little down (160°), up over the top (270°) to
    // up and forward (320°).
    let cx = 20.5, cy = 33.0
    let span = 160 * spread, r = 8 + 10 * spread, start = 160.0
    let n = 8
    for y in 8...43 {
        for x in 1...42 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let d = sqrt(dx * dx + dy * dy)
            guard d >= 2, d <= r else { continue }
            var u = atan2(dy, dx) * 180 / .pi - start
            u = u.truncatingRemainder(dividingBy: 360)
            if u < 0 { u += 360 }
            guard u <= span else { continue }
            let k = u / span * Double(n)
            let edge = abs(k - k.rounded()) < 0.12
            let col: Px = d > r - 1.2 ? tealL : edge ? tealD : d < r * 0.45 ? green : teal
            c.px(x, y, col)
        }
    }
    // The eyes, one on each feather near its tip: a gold ring, a blue middle, a dark pupil, opening as it spreads.
    for i in 0..<n {
        let a = (start + span * (Double(i) + 0.5) / Double(n)) * .pi / 180
        let ex = Int((cx + cos(a) * (r - 3.5)).rounded()), ey = Int((cy + sin(a) * (r - 3.5)).rounded())
        if open > 0.5 {
            c.pattern(ex - 2, ey - 2, [".GGG.", "GBBBG", "GBKBG", "GBBBG", ".GGG."],
                      ["G": C(0xE8C848), "B": C(0x2E5AD8), "K": C(0x101848)])
            if Int(t * 3 + Double(i)) % 7 == 0 { c.px(ex - 1, ey - 1, white) }   // a glint, now and then
        } else {
            c.rect(ex - 1, ey, 3, 1, C(0xE8C848))
        }
    }
}

// MARK: - Netossa

/// Netossa: the Rebellion's net-thrower. Short black curls with a gold band round her brow, a slate-blue bodysuit
/// with a silver collar, belt and cuffs, slate boots, and a white cape that is really her net: a diamond mesh of
/// silver cord, weighted along its hem with silver beads. She throws nets (spinning silver bundles). Signature: she
/// swirls her cape up over her head and out in front of her, where it spreads into a great round net, then gathers
/// it back onto her shoulders.
private func drawNetossa(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x2A1E24), hairD = C(0x140E12), hairL = C(0x50404A)
    let suit = C(0x3E4E78), suitD = C(0x2A3656), suitL = C(0x5A6C9C)
    let silver = C(0xB8BECC), silverL = C(0xE8ECF4), gold = C(0xE0B040)
    let s = p.signature ?? -1
    let cast = s < 0 ? 0 : habitArc(s, hold: 0.45)
    var raise = p.armRaise
    if cast > 0.05 { raise = Int((cast * 6).rounded()) }
    var winding = false
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        winding = ph >= 0.4
        if winding { raise = max(raise, 3) }
    }

    if cast < 0.25 { netCape(c, t: p.t, speed: p.capeSpeed) }
    drawLegs(c, Look(), step: p.step)
    cuffedBoots(c, step: p.step, rows: 4, suit, suitL, suitD)
    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: raise)
    // The bodysuit from the collar down: lit along the top, the far side shaded, a seam down each side; the silver
    // belt and buckle; the silver cuffs.
    c.rect(18, 33, 20, 5, suit); c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(18, 33, 20, 1, silver); c.rect(18, 33, 6, 1, silverL)
    c.rect(21, 34, 1, 2, suitD); c.rect(34, 34, 1, 2, suitD)
    c.rect(18, 36, 20, 1, silver); c.rect(26, 35, 4, 3, silverL); c.rect(27, 36, 2, 1, suitD)
    c.rect(15, 35, 3, 1, silver); c.rect(38, 35 - raise, 3, 1, silverL)
    // The cape's clasp at each shoulder: a silver bead.
    if cast < 0.25 { c.rect(18, 32, 2, 2, silverL); c.px(19, 33, silver) }
    // The hair: short black curls, a fringe of curls across her brow under a gold band, curls round her ears.
    c.pattern(15, 20, [
        "......hHHhHHhHHhH.......",
        "....hHHlHHhHHlHHhHHh....",
        "...HHhHHHhHlHHhHHHhHH...",
        "..hHlHHhHHHhHHlHhHHlHh..",
        "..HHHhHHlHhHHhHHHhHHHH..",
        ".hHHh................hHh",
        ".HlH..................HH",
        ".hHh..................Hh",
        "..Hh..................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(19, 25, 18, 1, gold); c.rect(19, 25, 6, 1, C(0xFFE07A)); c.rect(34, 25, 3, 1, C(0xA87C1C))

    if winding && cast < 0.05 {
        // A net balled up in her raised hand, ready to throw: silver, its cords crossing.
        c.pattern(39, 26 - raise + 3, [".SSS.", "SsSsS", "SSsSS", ".SSS."], ["S": silverL, "s": silver])
    }
    if cast >= 0.25 { castNet(c, spread: (cast - 0.25) / 0.75, hand: (40.5, Double(33 - raise))) }
}

/// The cape hanging behind her shoulders: white, a diamond mesh of silver cord across it, its hem weighted with silver
/// beads, the edge swaying.
private func netCape(_ c: PixelCanvas, t: Double, speed: Double) {
    let cloth = C(0xEEF0F6), cord = C(0x8A92A8), edge = C(0xB8BECC), bead = C(0xD8DCE6)
    let hem = 41
    let last = min(hem, 43 - c.oy)
    guard last >= 27 else { return }
    for y in 27...last {
        let k = Double(y - 27) / Double(hem - 27)
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((15.5 - k * 5 + sway).rounded())
        c.rect(l, y, 24 - l, 1, cloth)
        for x in l..<24 where (x + y) % 4 == 0 || (x - y + 40) % 4 == 0 { c.px(x, y, cord) }
        c.px(l, y, edge)
        if y == last { for x in stride(from: l, to: 24, by: 2) { c.px(x, y, bead) } }
    }
}

/// The net cast out from her raised hand: a fan of mesh swirling open from straight up round to the front, `spread`
/// 0…1, its silver cords bright against the dusk showing through the holes, a scalloped rim weighted with white beads.
private func castNet(_ c: PixelCanvas, spread: Double, hand: (Double, Double)) {
    let hole = C(0x3A4258), cord = C(0xDDE2EC), cordD = C(0x9CA4B8), rim = C(0xF0F2F8), bead = C(0xFFFFFF)
    // Angles as on screen (y down): it opens from straight up (-100°) towards the front (-10°).
    let start = -100.0, span = 90 * spread, r = 8 + 13 * spread
    let (hx, hy) = hand
    for y in Int(hy - r) - 1...Int(hy) + 2 {
        for x in Int(hx) - 3...Int(hx + r) + 1 {
            let dx = Double(x) + 0.5 - hx, dy = Double(y) + 0.5 - hy
            let d = sqrt(dx * dx + dy * dy)
            let a = atan2(dy, dx) * 180 / .pi
            let u = a - start
            guard d >= 2, u >= 0, u <= span else { continue }
            // The rim scallops between the spokes.
            let spoke = u / 15
            let scallop = 1.5 * abs(sin(spoke * .pi))
            guard d <= r - scallop + 1.5 else { continue }
            if d > r - scallop - 0.2 { c.px(x, y, rim); continue }
            let radial = abs(spoke - spoke.rounded()) * 15 * d / 57 < 0.55
            let ring = Int(d) % 3 == 0
            c.px(x, y, radial || ring ? (d > r * 0.6 ? cord : cordD) : hole)
        }
    }
    // The beads at the end of each spoke.
    for k in 0...Int(span / 15) {
        let a = (start + Double(k) * 15) * .pi / 180
        c.rect(Int((hx + cos(a) * (r + 0.5)).rounded()), Int((hy + sin(a) * (r + 0.5)).rounded()), 1, 1, bead)
    }
}

// MARK: - Flutterina

/// Flutterina: the butterfly girl of the Rebellion. A blonde bob with a fringe and two butterfly antennae curling up
/// from it, tipped in orange, a leaf-green tunic and skirt with a yellow belt, green boots, and two pairs of butterfly
/// wings on her back, orange shading to yellow at the root, a dark border round them and yellow spots, the far pair a
/// shade darker. She flies, wings beating fast. Signature: she flutters up off the ground, hangs on slow beats, and
/// settles again.
private func drawFlutterina(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF0CC5A), hairD = C(0xC09A30), hairL = C(0xFFE898)
    let green = C(0x3AA86A), greenD = C(0x26784A), greenL = C(0x62CC8C), yellow = C(0xF4D040)
    let s = p.signature ?? -1
    let aloft = s < 0 ? 0 : habitArc(s, hold: 0.45)
    let lift = Int((aloft * 8).rounded())
    // How far open the wings are, from the side (1: spread flat, low: closed up together over her back).
    var openK = 0.85 + 0.15 * sin(p.t * 2.2)
    // Closed up they still show a good width of orange, never a thin dark stick.
    if p.flying { openK = Int(p.t * 10) % 2 == 0 ? 1 : 0.6 }
    else if s >= 0.04 && s < 0.96 { openK = Int(p.t * (aloft > 0.95 ? 4 : 10)) % 2 == 0 ? 1 : 0.6 }

    c.oy -= lift
    // The wings behind her: the far pair, then the near pair, both from her back.
    butterflyWings(c, root: (29, 26), open: openK, far: true)
    butterflyWings(c, root: (20, 28), open: openK, far: false)
    drawLegs(c, Look(), step: p.step)
    cuffedBoots(c, step: p.step, rows: 3, green, greenL, greenD)
    c.oy += p.breathe
    drawBody(c, Look(arm: green), armRight: p.armRaise)
    // The green tunic, a scalloped leaf neckline, folds; the yellow belt; the skirt cut in petals over her legs.
    c.rect(18, 34, 20, 2, green); c.rect(37, 33, 1, 3, greenD)
    c.pattern(18, 33, ["GGGGgGGGgGGGgGGGgGGG"], ["G": greenL, "g": green])
    c.rect(21, 34, 1, 2, greenD); c.rect(34, 34, 1, 2, greenD)
    c.rect(15, 35, 3, 1, greenD); c.rect(38, 35 - p.armRaise, 3, 1, greenD)
    c.rect(18, 36, 20, 1, yellow); c.rect(18, 36, 5, 1, C(0xFFEA88)); c.rect(35, 36, 3, 1, C(0xC8A020))
    for y in 37...38 where y + c.oy <= 42 {
        c.rect(18, y, 20, 1, green)
        for x in stride(from: 21, to: 38, by: 4) { c.px(x, y, greenD) }
        c.px(18, y, greenL)
    }
    if 39 + c.oy <= 42 { for x in stride(from: 18, to: 38, by: 4) { c.rect(x + 1, 39, 2, 1, green) } }   // petal points
    // The hair: a blonde bob with a straight fringe, curling under at her jaw.
    c.pattern(16, 21, [
        "......HHHHHlHHHHH......",
        "...HHHlHHHHHHHlHHHH....",
        "..HHhHHHHhHHHHHhHHHHH..",
        ".HHHhHHHhHHHHHhHHHhHHH.",
        "HHHhHHHhHHHhHHHhHHHhHHH",
        "HHhhhhhhhhhhhhhhhhhhhHH",
        "HHh..................hH",
        "HHh..................hH",
        "HhH..................Hh",
        ".HH..................HH",
        "..h..................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The antennae: two dark stalks curling up and forward from her crown, an orange bead on each tip.
    c.pattern(23, 13, [
        "OO.......OO",
        "Oo.......Oo",
        "..K.......K",
        "..K.......K",
        "...K.....K.",
        "...K....K..",
        "....K..K...",
        "....K..K...",
    ], ["K": C(0x3A2A1A), "O": C(0xF08A2A), "o": C(0xFFC060)])

    if lift > 1 && !p.flying {
        // The air under her wings as she rises and settles, pale so it shows on a dark desktop.
        let k = 1 - aloft
        for dx in [-6.0, 6] {
            c.glowLine(28 + dx - 3, 44 + Double(lift), 28 + dx + 3, 44 + Double(lift), core: C(0xF4F8FF, 0.25 + 0.4 * k),
                       glow: C(0xD8E4F8, 0.15 + 0.25 * k), coreR: 0.4, glowR: 1.3)
        }
    }
}

/// A pair of butterfly wings from `root` on her back, `open` (0…1) as wide as they are spread flat (narrower when
/// they close up, seen edge-on): the big forewing up and back, the hindwing back and a little down; the far pair (`far`)
/// up and forward over her head, a shade darker.
private func butterflyWings(_ c: PixelCanvas, root: (Double, Double), open: Double, far: Bool) {
    if far {
        leafWing(c, root: root, angle: -62, length: 16, width: 12 * open, far: true)
    } else {
        leafWing(c, root: root, angle: -140, length: 19, width: 16 * open, far: false)
        leafWing(c, root: (root.0, root.1 + 3), angle: 168, length: 11, width: 10 * max(0.5, open), far: false)
    }
}

/// One wing along `angle` from `root`: narrow at the root and widest near the rounded tip, yellow at the root shading
/// to orange, dark veins running out along it, a dark border with white dots in it near the tip.
private func leafWing(_ c: PixelCanvas, root: (Double, Double), angle: Double, length: Double, width: Double, far: Bool) {
    let orange = far ? C(0xC8601C) : C(0xF07A22), yellow = far ? C(0xD0A030) : C(0xF8C440)
    let edge = far ? C(0x3A1E10) : C(0x40200E), vein = far ? C(0x7A3A14) : C(0x8E4416), dot = C(0xFFF4D8)
    let a = angle * .pi / 180
    let ux = cos(a), uy = sin(a)
    let half = max(1, width / 2)
    let reach = Int(length + half) + 1
    for y in Int(root.1) - reach...Int(root.1) + reach {
        for x in Int(root.0) - reach...Int(root.0) + reach {
            let dx = Double(x) + 0.5 - root.0, dy = Double(y) + 0.5 - root.1
            let u = dx * ux + dy * uy, v = -dx * uy + dy * ux
            guard u >= 0, u <= length else { continue }
            let k = u / length
            let tip = k > 0.6 ? sqrt(max(0, 1 - pow((k - 0.6) / 0.4, 2))) : 0.3 + k / 0.6 * 0.7
            let w = half * tip
            guard abs(v) <= w else { continue }
            // A narrow wing gets a thinner border, so the orange inside still shows.
            let border = abs(v) > w - (w > 3.5 ? 1.3 : 0.7) || k > 0.94
            let isVein = !border && k > 0.15 && k < 0.75 && abs(v) < 0.5
            let isSpot = !border && w > 3 && abs(k - 0.62) < 0.08 && abs(abs(v) - w * 0.45) < 1
            var col: Px = k < 0.3 ? yellow : orange
            if isVein { col = vein }
            if isSpot { col = yellow }
            if border { col = (x + y) % 3 == 0 && k > 0.55 && w > 2.5 ? dot : edge }
            c.px(x, y, col)
        }
    }
}

// MARK: - Light Hope

/// Light Hope: the spirit of the Crystal Castle, a pillar of rainbow light. No body to speak of: a tall column of
/// light rising from a robe of it, in bands of red, orange, yellow, green, blue and violet, a calm pale face in the
/// middle with its eyes peacefully shut, and four pale legs of light under the hem, never quite on the ground. The
/// pillar has no top: it pales and fades away as it rises, soft motes drifting up through it. He doesn't fight. Signature: the light cycles through the rainbow, the bands running
/// down the pillar and the face glowing brighter.
private func drawLightHope(_ c: PixelCanvas, _ p: Pose) {
    let bands: [(Px, Px)] = [
        (C(0xA070F0), C(0xC4A0FF)), (C(0x4E8CF4), C(0x86B4FF)), (C(0x4CC878), C(0x86E8A8)),
        (C(0xF4D84A), C(0xFFF09A)), (C(0xF49A3C), C(0xFFC488)), (C(0xEC4E5C), C(0xFF8A94)),
    ]
    let s = p.signature ?? -1
    let cycling = s > 0.05 && s < 0.95
    let glow = s < 0 ? 0 : habitArc(s, hold: 0.6)
    // Where the bands are: drifting slowly, or running down fast while the signature cycles them.
    let shift = cycling ? Int(s * 36) : Int(p.lt * 1.2)
    func band(_ y: Int) -> (Px, Px) {
        let i = ((y - 7 - shift) / 3 % 6 + 6) % 6
        return bands[i]
    }

    // The legs: light, pale lilac, a brighter run down the front of each.
    drawLegs(c, Look(leg: C(0xE0D8FF)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx + 1, 39, 1, bottom - 39, C(0xFFFFFF)); c.px(lx, bottom, C(0xB8ACE8))
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: C(0xFFF6E2), shade: C(0xE8D8C0), arm: band(34).0, eye: nil), armRight: p.armRaise)
    // The robe and the pillar, row by row: each row in its band's colour, lit on its left edge. The pillar has no
    // top: it rises out of the frame of light, its upper rows paling and fading away to nothing, so it's a beam, not
    // a cap. Lower down it widens smoothly into the hood with no step, and the robe flares to the hem.
    for y in 3...40 where y + c.oy <= 41 {
        var (col, lit) = band(y)
        var l = 0, r = 0
        switch y {
        case 3...20: (l, r) = (21, 34)
        case 21...25: (l, r) = (21 - (y - 20) * 4 / 5, 34 + (y - 20) * 4 / 5)
        case 26...32: (l, r) = (17, 38)
        default: (l, r) = (17 - (y - 33) / 3, 38 + (y - 33) / 3)
        }
        if y < 12 {
            // Paling to white as it fades, so it reads as light thinning out, not as a dark cap.
            let k = Double(y - 2) / 10
            col = lit.alpha(0.25 + 0.75 * k * k); lit = C(0xFFFFFF, 0.25 + 0.75 * k * k)
        }
        if (26...32).contains(y) {
            // Round the face: the robe's sides only, as a hood.
            c.rect(l, y, 4, 1, col); c.rect(r - 3, y, 4, 1, col); c.px(l, y, lit)
        } else {
            c.rect(l, y, r - l + 1, 1, col); c.px(l, y, lit); c.px(l + 1, y, lit)
        }
    }
    // A soft fold down the robe, and the lit seam where hood meets face.
    for y in 34...39 where y + c.oy <= 41 { c.px(23, y, C(0xFFFFFF, 0.35)); c.px(32, y, C(0x000000, 0.18)) }
    // The face: pale and calm, shaded on the far side, the eyes shut in two gentle curves, glowing in the signature.
    c.rect(21, 26, 14, 7, C(0xFFF6E2)); c.rect(33, 26, 2, 7, C(0xF0E2C8)); c.rect(21, 26, 14, 1, C(0xFFFFF4))
    let lid = C(0x5A4A8A)
    for ex in [22, 30] {
        c.pattern(ex, 29, ["L..L", ".LL."], ["L": lid])
    }
    c.rect(26, 31, 3, 1, C(0xF0D0C8))   // a faint, calm mouth
    if glow > 0 {
        c.glowLine(28, 29, 28, 29, core: C(0xFFFFFF, 0.25 * glow), glow: C(0xFFF4C0, 0.22 * glow), coreR: 3, glowR: 9)
    }
    // The shimmer up the fading beam: soft white motes rising through it and fading out, never solid.
    for (i, x) in [24, 28, 31].enumerated() {
        let f = frac(p.t * 0.7 + Double(i) * 0.33)
        c.px(x, 14 - Int(f * 10), C(0xFFFFFF, 0.7 * (1 - f)))
    }
}

// MARK: - Stonedar

/// Stonedar: the Comet Warrior, a man of living stone. A body of grey-brown rock, lumpy along the top and in cracks
/// rather than bricks, heavy brows over small amber eyes, and the Comet Warriors' armour over it: dark teal shoulder
/// plates and a chest plate lit along the top, a comet streaking across it on a slant, its bright gold head high by his
/// front shoulder and its silver tail streaming down to the far hip. Big stone fists. Signature: he
/// curls up into a boulder, rolls a little way forward and back, his armour and cracks going round with him, and
/// stands up again, pale dust billowing up behind him as he rolls.
private func drawStonedar(_ c: PixelCanvas, _ p: Pose) {
    let rock = C(0x8E8272), rockD = C(0x62584A), rockL = C(0xB4A896), crack = C(0x463E34)
    let teal = C(0x2E6E6A), tealD = C(0x1E4C4A), tealL = C(0x4E9A92)
    let s = p.signature ?? -1
    if s > 0.12 && s < 0.88 {
        boulder(c, p, s: (s - 0.12) / 0.76)
        return
    }
    // Stone legs, cracked, with broad dark feet.
    drawLegs(c, Look(leg: rock), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 1, 2, 2, rockD); c.px(lx, bottom - 5, rockL); c.px(lx + 1, bottom - 3, crack)
        }
    }
    c.oy += p.breathe
    let raise = p.melee == nil ? p.armRaise : 0
    drawBody(c, Look(body: rock, shade: rockD, leg: rock, arm: rock, eye: nil), armRight: raise)
    // The lumpy top of his head and shoulders, lit; and cracks in short strokes over the stone.
    c.pattern(18, 23, [
        "......LLLL..........",
        "..LLLRRRRRRL..LLL...",
        ".LRRRRRRRRRRLLRRRRL.",
    ], ["L": rockL, "R": rock])
    c.rect(18, 26, 1, 6, rockL)
    for (x, y, w) in [(20, 27, 2), (31, 27, 2), (26, 24, 1)] { c.rect(x, y, w, 1, crack) }
    c.px(19, 32, crack); c.px(20, 33, crack); c.px(36, 30, crack); c.px(35, 31, crack)
    // The heavy brow and the small amber eyes under it.
    c.rect(20, 28, 6, 1, rockD); c.rect(30, 28, 6, 1, rockD); c.rect(21, 28, 4, 1, crack); c.rect(31, 28, 4, 1, crack)
    c.rect(22, 29, 2, 2, C(0xF2B636)); c.rect(32, 29, 2, 2, C(0xF2B636)); c.px(22, 29, C(0xFFE8A0)); c.px(32, 29, C(0xFFE8A0))
    // The Comet Warrior chest plate: dark teal, lit along the top, shaded underneath, the comet streaking across it.
    c.rect(19, 32, 18, 5, teal); c.rect(19, 32, 18, 1, tealL); c.rect(19, 36, 18, 1, tealD); c.rect(36, 32, 1, 5, tealD)
    // The comet: a small bright head high on the plate by his front shoulder, its silver tail streaming down and back
    // across the whole plate to the far hip, widening as it goes; off centre and on a slant, so never a buckle.
    line(c, 33.5, 33, 21, 35.8, C(0x7A8494), 0.9)
    line(c, 33.5, 33, 21.5, 35, C(0xC4CAD6), 0.45)
    line(c, 33, 33.5, 25, 35.5, C(0xE8ECF4), 0.4)
    c.glowLine(34.5, 33.5, 34.5, 33.5, core: C(0xFFFFFF, 0), glow: C(0xFFE070, 0.35), coreR: 0.1, glowR: 2.6)
    c.pattern(32, 31, ["..Y..", ".YWY.", "YWWWY", ".YWY.", "..Y.."], ["Y": C(0xF8D860), "W": white])
    c.rect(18, 37, 20, 1, rockD)
    // The shoulder plates over his arms.
    c.rect(14, 32, 5, 2, teal); c.rect(14, 32, 5, 1, tealL)
    if p.melee == nil {
        c.rect(37, 32 - raise, 5, 2, teal); c.rect(37, 32 - raise, 5, 1, tealL)
        c.rect(38, 35 - raise, 3, 1, rockD)
        return
    }
    stoneFist(c, angle: p.melee ?? 0, trail: p.trail, rock: rock, rockD: rockD, rockL: rockL)
    c.rect(36, 32, 4, 2, teal); c.rect(36, 32, 4, 1, tealL)
}

/// A punch along `angle` from his shoulder: a stone arm and a big four-square stone fist, a smear behind a fast one.
private func stoneFist(_ c: PixelCanvas, angle a: Double, trail: [Double], rock: Px, rockD: Px, rockL: Px) {
    let sh = (x: 39.0, y: 34.5)
    let e = eterniaReach(sh, a, 6)
    for (i, t) in trail.enumerated() {
        let q = eterniaReach(sh, t, 6)
        c.glowLine(q.x, q.y, e.x, e.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.6, glowR: 1.8,
                   strength: 0.3 / Double(i + 1))
    }
    line(c, sh.x - 1, sh.y, e.x, e.y, rock, 1.4)
    let x0 = Int(e.x.rounded()) - 2, y0 = Int(e.y.rounded()) - 2
    c.rect(x0, y0, 4, 4, rock); c.rect(x0, y0, 4, 1, rockL); c.rect(x0 + 3, y0, 1, 4, rockD); c.rect(x0, y0 + 3, 4, 1, rockD)
    c.px(x0 + 1, y0 + 1, rockD)
}

/// Stonedar curled up as a boulder (`k` 0…1 through the roll): a round stone, lit top-left, rolling forward and back
/// on his four stubby stone feet, the comet plate and the cracks turning with it.
private func boulder(_ c: PixelCanvas, _ p: Pose, s k: Double) {
    let rock = C(0x8E8272), rockD = C(0x62584A), rockL = C(0xB4A896), crack = C(0x463E34)
    let teal = C(0x2E6E6A), tealL = C(0x4E9A92), silver = C(0xD8DCE4)
    let roll = sin(k * .pi) * 8
    let cx = 28.0 + roll, cy = 31.0, r = 9.5
    let turn = roll / r   // radians it has turned, rolling without slipping
    // The four stubby feet under it, keeping up.
    for lx in [20, 24, 30, 34] {
        let x = lx + Int(roll.rounded())
        c.rect(x, 40, 2, 4, rock); c.rect(x, 42, 2, 2, rockD)
    }
    for y in 21...41 {
        for x in 17...48 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let d = sqrt(dx * dx + dy * dy)
            guard d <= r else { continue }
            let lit = -dx * 0.6 - dy * 0.8
            let col: Px = d > r - 1.2 ? (lit > 0 ? rockL : rockD) : lit > 3.5 ? rockL : lit < -4 ? rockD : rock
            c.px(x, y, col)
        }
    }
    // The cracks, three strokes turning with the stone.
    for i in 0..<3 {
        let a = turn + Double(i) * 2.1
        let p0 = (cx + cos(a) * 2.5, cy + sin(a) * 2.5), p1 = (cx + cos(a + 0.3) * 7.5, cy + sin(a + 0.3) * 7.5)
        line(c, p0.0, p0.1, p1.0, p1.1, crack, 0.45)
    }
    // The comet plate on its side, going round.
    let pa = turn - 0.9
    let px = Int((cx + cos(pa) * 5).rounded()), py = Int((cy + sin(pa) * 5).rounded())
    c.rect(px - 2, py - 1, 5, 3, teal); c.rect(px - 2, py - 1, 5, 1, tealL); c.px(px, py, silver); c.px(px + 1, py, silver)
    // The dust he kicks up rolling: pale puffs billowing up off the ground behind him, growing and fading, bright
    // enough to show on a dark desktop.
    let speed = abs(cos(k * .pi))
    if speed > 0.2 {
        let back = cos(k * .pi) > 0 ? -1.0 : 1.0
        for n in 0..<3 {
            let f = frac(p.t * 2.2 + Double(n) / 3)
            let x = cx - back * (9 + f * 6), y = 42 - f * 4
            let a = min(1, speed * 1.5) * (1 - f * 0.7)
            c.glowLine(x, y, x, y, core: C(0xFAF4E6, 0.9 * a), glow: C(0xE8DCC0, 0.5 * a),
                       coreR: 0.8 + f * 1.2, glowR: 1.8 + f * 1.6)
        }
    }
}

// MARK: - Loo-Kee

/// Loo-Kee: the little yellow Kon-Seal who hides somewhere in every story. Short yellow fur all over in strokes, a
/// pale belly, two big pointed ears standing up and out from the top of his head with pink insides, an orange tuft on top, a leaf collar from the
/// Whispering Woods, and big round eyes, white with large dark pupils that look about. Signature: he hides behind a
/// leafy branch, his ears giving him away, then lowers it just enough to peek over the top, as if asking whether
/// you've found him.
private func drawLooKee(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xF0C838), furD = C(0xC09A20), furL = C(0xFFE476), belly = C(0xFFF0B4)
    let tuft = C(0xD8782A), tuftD = C(0xA85418), inner = C(0xF0A0A8)
    let leaf = C(0x3A9A48), leafD = C(0x266E32), leafL = C(0x62C46A)
    let s = p.signature ?? eterniaHabitK(p.who) ?? -1   // or on the stage's cue (EterniaHabits.swift)
    // 0…0.15 the branch comes up, 0.15…0.45 he's hidden, 0.45…0.8 he peeks over it, then it goes down.
    var cover = -1   // the top row of the branch in front of him, or none
    if s >= 0 && s < 0.15 { cover = 44 - Int((s / 0.15 * 22).rounded()) }
    else if s >= 0.15 && s < 0.45 { cover = 22 }
    else if s >= 0.45 && s < 0.8 { cover = 32 }
    else if s >= 0.8 && s < 1 { cover = 32 + Int(((s - 0.8) / 0.2 * 12).rounded()) }
    let look = s >= 0.45 && s < 0.8 ? (Int(s * 10) % 2 == 0 ? -1 : 1) : sin(p.lt * 0.9) > 0.6 ? 1 : 0

    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 2, 1, furD); c.px(lx, bottom - 4, furL)
        }
    }
    c.oy += p.breathe
    // The ears, big and pointed, standing up and leaning out from the top corners of his head, a broad pink inside
    // running up each: tall and upright, so they read as ears, never as wings.
    let ear = [
        "E.........",
        "EE........",
        "EIE.......",
        "EIIE......",
        ".EIIE.....",
        ".EIIIE....",
        ".EIIIEE...",
        "..EIIIEE..",
        "..EIIIIEE.",
        "..eEIIIIEE",
        "...eEIIIEE",
        "....eEEEEE",
        ".....eeEEE",
    ]
    c.pattern(11, 14, ear, ["E": furL, "e": furD, "I": inner])
    c.pattern(35, 14, ear.map { String($0.reversed()) }, ["E": fur, "e": furD, "I": inner])
    drawBody(c, Look(body: fur, shade: furD, leg: fur, arm: fur, eye: nil), armRight: p.armRaise)
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 8, furL)
    // Fur strokes on his sides, and the pale belly.
    for (x, y) in [(20, 35), (35, 34), (19, 29), (36, 28)] { c.rect(x, y, 1, 2, furD) }
    c.pattern(23, 34, [".BBBBBBBBB.", "BBbBBBBbBBB", ".BBBBbBBBB."], ["B": belly, "b": C(0xE8D490)])
    // The orange tuft on top, in strands.
    c.pattern(23, 21, [
        "...T.T..t...",
        "..TtT.TtT.t.",
        ".TtTTtTTtTT.",
        "TTtTTtTtTTtT",
        "tTTtTTTtTTTt",
    ], ["T": tuft, "t": tuftD])
    // The big round eyes, white, with large dark pupils that dart about, and a glint.
    for ex in [21, 30] {
        c.pattern(ex, 27, [".WWWW.", "WWWWWW", "WWWWWW", "WWWWWW", ".WWWW."], ["W": white])
        c.rect(ex + 2 + look, 28, 3, 3, ink)
        c.px(ex + 2 + look, 28, white)
    }
    c.rect(27, 30, 2, 1, furD)   // the little nose between them
    // The leaf collar round his neck, three leaves pointing down.
    c.pattern(18, 32, [
        "LLLLLLLLLLLLLLLLLLLL",
        ".lLl..lLLl..lLLl.lL.",
        "..l....ll....ll...l.",
    ], ["L": leafL, "l": leaf])

    if cover >= 0 && cover <= 43 {
        // The leafy branch held up in front of him: a stem in his paw, leaves in clusters, lit on top. His ear tips
        // still show either side.
        c.oy -= p.breathe
        let top = Double(cover)
        // The stem down to his paw, then the leaves in round clumps over it, each lit top-left and shaded bottom-right,
        // short leaf strokes across them.
        c.rect(27, min(43, cover + 14), 2, max(0, 44 - cover - 14), C(0x7A5230))
        let clumps: [(Double, Double, Double)] = [(22, 4.5, 4.5), (29.5, 3.5, 4.5), (35, 5.5, 4), (19, 9, 4),
                                                 (25.5, 9.5, 5), (32.5, 10, 5), (28.5, 14, 4)]
        for (bx, by, r) in clumps {
            let cy = top + by
            for y in Int(cy - r)...Int(cy + r) where y <= 43 {
                for x in Int(bx - r)...Int(bx + r) {
                    let dx = Double(x) + 0.5 - bx, dy = Double(y) + 0.5 - cy
                    guard dx * dx + dy * dy <= r * r else { continue }
                    let lit = -dx - dy
                    var col = lit > r * 0.7 ? leafL : lit < -r * 0.8 ? leafD : leaf
                    if (x * 2 + y) % 5 == 0 && lit > -r * 0.8 { col = leafD }
                    c.px(x, y, col)
                }
            }
        }
        // A few leaf tips poking out round the edge.
        for (x, y) in [(16, 8), (40, 4), (24, 0), (38, 10)] where cover + y <= 43 {
            c.rect(x, cover + y, 2, 1, leafL)
        }
        if cover == 32 {
            // His paws over the top of it.
            c.rect(21, 31, 3, 2, fur); c.rect(32, 31, 3, 2, fur); c.px(23, 32, furD); c.px(34, 32, furD)
        }
    }
}
