import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The last gods and the small fry: Grull, Eris, and (agents only) a Scatterer bug, a goblin, a Tuskling, a Pooka
// and a Krakaren cloneling.

let crawlVillains7: [CrawlVillain: Persona] = [
    .grull: Persona(name: "Grull", weapon: .saber, pivot: (47, 28), bulk: 5, headTop: 6, signature: 3.0, draw: drawGrull),
    .eris: Persona(name: "Eris", weapon: .lightning, magic: Magic(core: C(0xFFE4FA), glow: C(0xF02ABE)), pivot: (43, 32),
                   headTop: 14, draw: drawEris),
    .scatterer: Persona(name: "Scatterer bug", weapon: .saber, pivot: (44, 33), headTop: 24, signature: 2.6,
                        draw: drawScatterer),
    .goblin: Persona(name: "Goblin", weapon: .blaster, shot: .thrown(C(0xD8342C)), muzzle: (45, 26), handGun: false,
                     headTop: 20, signature: 3.0, draw: drawGoblin),
    .tuskling: Persona(name: "Tuskling", headTop: 23, signature: 3.0, draw: drawTuskling),
    .pooka: Persona(name: "Pooka", weapon: .saber, headTop: 22, signature: 3.2, draw: drawPooka),
    .cloneling: Persona(name: "Krakaren cloneling", headTop: 22, signature: 2.6, draw: drawCloneling),
]

// MARK: - Helpers

/// A filled ellipse round (`cx`, `cy`), `rx` by `ry` pixels from its centre to its edge.
private func blob(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px) {
    guard rx > 0, ry > 0 else { return }
    for y in Int(floor(cy - ry))...Int(ceil(cy + ry)) {
        for x in Int(floor(cx - rx))...Int(ceil(cx + rx)) {
            let dx = (Double(x) + 0.5 - cx) / rx, dy = (Double(y) + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1 { c.px(x, y, col) }
        }
    }
}

/// A tentacle (or a tail, or a horn) through `pts`, `r0` thick at its root thinning to `r1` at its tip.
private func tentacle(_ c: PixelCanvas, _ pts: [(Double, Double)], r0: Double, r1: Double, _ col: Px) {
    guard pts.count > 1 else { return }
    for i in 0..<(pts.count - 1) {
        let k = Double(i) / Double(pts.count - 1)
        let r = r0 + (r1 - r0) * k
        c.glowLine(pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

/// String art turned to `angle` degrees (0 forward, -90 straight up, as `Pose.melee`): `rows` drawn upright, its top
/// pointing along `angle`, the point `pivot` (in pattern pixels, from its top-left) on the canvas at `at`.
private func stamp(_ c: PixelCanvas, _ rows: [String], _ palette: [Character: Px], pivot: (x: Double, y: Double),
                   at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    let grid = rows.map { Array($0) }
    let w = Double(grid.map(\.count).max() ?? 0), h = Double(grid.count)
    let reach = max(hypot(pivot.x, pivot.y), hypot(w - pivot.x, pivot.y), hypot(pivot.x, h - pivot.y),
                    hypot(w - pivot.x, h - pivot.y)) + 1
    let r = (angle + 90) * .pi / 180
    let cs = cos(r), sn = sin(r)
    for y in Int(floor(at.y - reach))...Int(ceil(at.y + reach)) {
        for x in Int(floor(at.x - reach))...Int(ceil(at.x + reach)) {
            let dx = Double(x) + 0.5 - at.x, dy = Double(y) + 0.5 - at.y
            let u = dx * cs + dy * sn, v = -dx * sn + dy * cs
            let col = Int(floor(u + pivot.x)), row = Int(floor(v + pivot.y))
            guard row >= 0, row < grid.count, col >= 0, col < grid[row].count else { continue }
            if let p = palette[grid[row][col]] { c.px(x, y, alpha < 1 ? p.alpha(alpha) : p) }
        }
    }
}

/// 0 outside `a…b`, 1 inside it, easing in and out over `edge` at each end.
private func span(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    let k = min(1, (s - a) / edge, (b - s) / edge)
    return k * k * (3 - 2 * k)
}

/// String art flipped left to right (the near side of something drawn for the far side).
private func mirrored(_ rows: [String]) -> [String] { rows.map { String($0.reversed()) } }

// MARK: - Grull

/// Grull: the bull god, a black centaur. Clawd's block is the horse's barrel, on Clawd's four legs as black horse legs
/// with grey hooves and a black tail swishing from the rump; up out of the front of it rises a bull-man's chest, a
/// gold belt where man meets horse, a gold band on the far arm. His head is a black bull's, seen from the front: ivory
/// horns sweeping out and up with dark tips, ears out under them, a curly forelock, red eyes under a scowling brow and
/// a broad grey-brown muzzle with a gold ring through it. He swings a molten axe: a black iron head veined with glowing
/// cracks, its bearded edge white-hot. Signature: he snorts steam, twice, a hind hoof pawing the ground, and two jets
/// of it blast out of his nostrils.
private func drawGrull(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x2C282C), hideD = C(0x18161A), hideL = C(0x4C464C), hideLL = C(0x6A6268)
    let muzzle = C(0x5A4A46), muzzleL = C(0x7A6660), nostril = C(0x0E0A0C)
    let horn = C(0xEADFC4), hornD = C(0xB4A482), hornT = C(0x5A4E3E)
    let gold = C(0xF0C840), goldD = C(0xB88A20), goldL = C(0xFFE890)
    let eye = C(0xFF4422), hoof = C(0x6E6256), hoofL = C(0x928676)
    let s = p.signature ?? -1
    let snorting = s > 0.05 && s < 0.95
    let paw = snorting && s < 0.5 && Int(s * 18) % 2 == 0 ? 1 : 0

    // 1. The horse legs: black, lit down the front, a shaded fetlock, grey hooves; the far hind leg paws the ground
    //    as he snorts.
    if seatedPose {
        drawLegs(c, Look(leg: hide), step: p.step)
        for lx in [19, 23, 31, 35] { c.rect(lx + 2, 39, 1, 1, hoof) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            if i == 0 && paw > 0 {
                c.rect(lx, 36, 2, 3, hide); c.rect(lx - 1, 38, 2, 2, hide); c.rect(lx - 2, 40, 2, 2, hoof)
                continue
            }
            let lift = p.step >= 0 && i % 2 == p.step ? 1 : 0
            let bottom = 43 - lift
            c.rect(lx, 36, 2, bottom - 35, hide)
            c.rect(lx, 37, 1, 3, hideL); c.px(lx + 1, bottom - 2, hideD)
            c.rect(lx, bottom - 1, 2, 2, hoof); c.px(lx, bottom - 1, hoofL)
        }
    }
    if paw > 0 { for k in 0..<3 { c.rect(12 + k * 2, 42 - k % 2, 2, 1, C(0xD8CCB0, 0.5)) } }   // the dust

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail: black, from the rump, swishing, a shaggy tuft at its end.
    let sw = sin(p.lt * 2.1) * 1.2
    for k in 0..<10 {
        let y = 28 + k, x = 16 - Int((Double(k) * 0.35 + sw * Double(k) / 10).rounded())
        c.rect(x, y, 2, 1, k % 3 == 0 ? hideL : hide)
        if k > 5 { c.px(x - 1, y, hide) }
    }

    // 4. The barrel: Clawd's block in black hide, the top corners rounded, lit along the back, the belly shaded,
    //    muscle in strokes along the flank and round the rump.
    c.rect(18, 27, 20, 10, hide); c.rect(19, 26, 18, 1, hide)
    c.rect(20, 26, 10, 1, hideL); c.rect(18, 27, 1, 4, hideL)
    c.rect(19, 36, 18, 1, hideD); c.rect(37, 27, 1, 10, hideD)
    c.pattern(19, 28, [
        ".ll.............",
        "l...............",
        "l.....ll....l...",
        ".l......ll...l..",
        "..........d.....",
        "...dd......dd...",
    ], ["l": hideLL, "d": hideD])

    // 5. The bull-man's chest rising from the front of the barrel: broad shoulders lit on top, two slabs of pec, a
    //    shadow under each, the far side in shade; the gold belt where man meets horse, a buckle on it.
    c.rect(30, 20, 12, 8, hide)
    blob(c, 30.5, 22, 2.6, 2.4, hide); blob(c, 41.5, 22, 2.6, 2.4, hide)
    c.rect(29, 20, 4, 1, hideL); c.rect(39, 20, 4, 1, hideL); c.rect(28, 21, 1, 2, hideL)
    c.rect(31, 22, 4, 1, hideLL); c.rect(36, 22, 4, 1, hideL)
    c.rect(31, 24, 4, 1, hideD); c.rect(36, 24, 4, 1, hideD); c.rect(35, 22, 1, 4, hideD)
    c.rect(41, 23, 1, 5, hideD)
    c.rect(29, 27, 14, 2, gold); c.rect(29, 28, 14, 1, goldD); c.px(29, 27, goldL)
    c.pattern(34, 26, ["GGGG", "G..G", "GGGG"], ["G": goldL])
    c.rect(35, 27, 2, 1, hide)

    // 6. The far arm, hanging, its fist on the barrel, a gold band round it.
    c.rect(26, 21, 3, 6, hide); c.px(26, 21, hideL)
    c.rect(26, 23, 3, 1, gold); c.px(26, 23, goldL)
    c.rect(25, 26, 4, 3, hide); c.px(25, 26, hideL); c.rect(25, 28, 4, 1, hideD)

    // 7. The head, a black bull's from the front: horns out and up, ears under them, the forelock curling, red eyes
    //    under a scowl, the broad muzzle with its nostrils, and the gold ring through it. Snorting, he tosses it up.
    let toss = snorting && (span(s, 0.2, 0.42) > 0.5 || span(s, 0.55, 0.77) > 0.5) ? -1 : 0
    c.oy += toss
    // The horns, ivory, sweeping out and up, dark at the tips.
    tentacle(c, [(32, 13), (29, 12), (27, 10), (26.5, 8)], r0: 1.4, r1: 0.7, horn)
    tentacle(c, [(43, 13), (46, 12), (48, 10), (48.5, 8)], r0: 1.4, r1: 0.7, horn)
    c.rect(29, 13, 3, 1, hornD); c.rect(44, 13, 3, 1, hornD)
    c.rect(26, 7, 1, 2, hornT); c.rect(48, 7, 1, 2, hornT)
    c.pattern(31, 10, [
        "....HHHHH.....",
        "..HHHHHHHHHH..",
        ".HHHHHHHHHHHH.",
        "HHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHH",
        ".HHHHHHHHHHHH.",
        ".HHHHHHHHHHHH.",
        "..HHHHHHHHHH..",
        "..HHHHHHHHHH..",
        "...HHHHHHHH...",
    ], ["H": hide])
    // The ears, out under the horns, a lit edge on top.
    c.pattern(27, 14, ["llll", "EEEE", ".EEE"], ["l": hideL, "E": hide])
    c.pattern(44, 14, ["llll", "EEEE", "EEE."], ["l": hideL, "E": hideD])
    // The forelock, curls lit on top, and the brow lit along it.
    c.pattern(34, 10, [".l.l.l.", "lHlHlHl", ".l.l.l."], ["l": hideLL, "H": hide])
    c.rect(32, 13, 1, 4, hideL)
    // The scowl, the red eyes under it.
    c.pattern(32, 14, ["dd........dd", "..dd....dd.."], ["d": hideD])
    c.rect(33, 16, 2, 2, eye); c.rect(40, 16, 2, 2, eye); c.px(33, 16, C(0xFFB090)); c.px(40, 16, C(0xFFB090))
    // The muzzle, grey-brown and broad, lit on top, the nostrils flared; the gold ring hanging through it.
    c.pattern(33, 18, [
        "..LLLLLLL..",
        ".MMMMMMMMM.",
        "MMnnMMMnnMM",
        "MMnMMMMMnMM",
        ".MMMMMMMMM.",
        "..mmmmmmm..",
    ], ["L": muzzleL, "M": muzzle, "n": nostril, "m": hideD])
    c.pattern(36, 21, [".g.g.", "g...g", "g...g", ".gGg."], ["g": gold, "G": goldL])
    c.oy -= toss

    // 8. The steam: two jets blasting out of his nostrils at each snort, puffing up and away as they go.
    if snorting {
        for start in [0.2, 0.55] {
            let k = (s - start) / 0.3
            guard k > 0, k < 1 else { continue }
            for (j, side) in [(0, -1.0), (1, 1.0)] {
                for q in 0..<4 {
                    let kk = k - Double(q) * 0.1
                    guard kk > 0 else { continue }
                    let x = 38 + side * (2 + kk * 9) + Double(j), y = 21 + kk * 4 - kk * kk * 6
                    let r = 1 + kk * 2.2
                    blob(c, x, y, r, r * 0.8, C(0xF4F6FA, 0.55 * (1 - kk)))
                }
            }
        }
    }

    // 9. The near arm, down and out to his fist, and the molten axe in it: a black iron head, cracks glowing through
    //    it, its bearded edge white-hot, on a dark haft with gold bands.
    c.rect(42, 21, 3, 3, hide); c.rect(43, 23, 3, 3, hide); c.rect(45, 25, 2, 2, hide); c.px(42, 21, hideL)
    let hot = Int(p.lt * 6) % 2 == 0 ? C(0xFFF0A0) : C(0xFFD050)
    let axe = [
        "..g.....",
        "..hIc...",
        ".ihIIcO.",
        "iihIcIOY",
        ".ihIIcOY",
        "..hIcIOY",
        "..hIIOY.",
        "..hOO...",
        "..h.....",
        "..g.....",
        "..h.....",
        "..h.....",
        "..h.....",
        "..h.....",
        "..g.....",
    ]
    let axePal: [Character: Px] = ["I": C(0x2E2628), "i": C(0x48403E), "c": C(0xFF7A1A), "O": C(0xFF9A2A), "Y": hot,
                                   "h": C(0x4A3222), "g": gold]
    let angle = p.melee ?? -62
    for (i, a) in p.trail.enumerated() {
        stamp(c, axe, axePal, pivot: (2.5, 12.5), at: (47, 28), angle: a, alpha: 0.3 / Double(i + 1))
    }
    stamp(c, axe, axePal, pivot: (2.5, 12.5), at: (47, 28), angle: angle)
    c.rect(46, 27, 3, 3, hide); c.px(46, 27, hideL); c.rect(46, 29, 3, 1, hideD)   // the fist round the haft
}

// MARK: - Eris

/// Eris: the goddess of chaos, Clawd in glowing Valkyrie armour: a silver winged helm with a gold band and a magenta
/// gem, long blonde hair falling out from under it in strands, a silver breastplate trimmed in gold with a glowing seam
/// and a magenta stone, silver pauldrons, and over it all a long black and white striped coat, open down the front,
/// hanging nearly to her silver sabatons. A sly little smile. She hurls forked magenta lightning. No signature.
private func drawEris(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF2D06A), hairD = C(0xC09A3A), hairL = C(0xFFEEA8)
    let plate = C(0xC8CCDA), plateD = C(0x8A90A6), plateL = C(0xF4F6FF)
    let gold = C(0xE8C04A), goldD = C(0xA88424)
    let blk = C(0x1C1A22), blkL = C(0x3A3844), wht = C(0xEEEEF2), whtD = C(0xB0B0C0)
    let wing = C(0xF2F2F6), wingD = C(0xB8BCCC), wingR = C(0x8A90A8)
    let gem = C(0xF02ABE), gemL = C(0xFFA0E8)
    let pulse = 0.5 + 0.5 * sin(p.lt * 3.4)
    let glow = pulse > 0.5 ? C(0xFFE4FA) : C(0xF8B8EC)

    // 1. Silver greaves and sabatons under the coat, a lit run down each, a dark toe.
    drawLegs(c, Look(leg: plateD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 39, 1, bottom - 39, plate)
            c.rect(lx, bottom, 2, 1, plateD); c.px(lx, bottom, plate); c.px(lx + 1, bottom, C(0x5A6074))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The long hair at the back, falling in strands behind her down past the coat's shoulders.
    c.pattern(13, 25, [
        ".HhHHh",
        "HHhHHh",
        "HHhHhH",
        "HhHHhH",
        "HhHHhH",
        "HhHhH.",
        "HhHhH.",
        "hHhHh.",
        "hHhH..",
        ".HhH..",
        ".Hh...",
        ".h....",
    ], ["H": hair, "h": hairD])

    // 4. Clawd's face and body, the arms in the coat's black sleeves.
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: blk, eye: nil))

    // 5. The coat: long, black and white stripes two pixels wide, open down the front over the armour, the outer
    //    edges black, the far side's white in shade, the hem flaring a pixel out; a striped collar standing up.
    let hem = 40
    for x in 15...24 {
        let dark = ((x - 15) / 2) % 2 == 0
        let top = x < 17 ? 33 : 31
        let bottom = x == 15 ? hem : hem
        if x == 15 { c.rect(x, 37, 1, bottom - 36, blk); continue }
        c.rect(x, top, 1, bottom - top + 1, dark ? blk : wht)
    }
    for x in 31...40 {
        let dark = ((40 - x) / 2) % 2 == 0
        let top = x > 38 ? 33 : 31
        if x == 40 { c.rect(x, 37, 1, hem - 36, blk); continue }
        c.rect(x, top, 1, hem - top + 1, dark ? blk : whtD)
    }
    c.rect(16, hem, 9, 1, blkL); c.rect(31, hem, 9, 1, blk)   // the hem
    c.rect(24, 31, 1, hem - 30, blk); c.rect(31, 31, 1, hem - 30, blk)   // the open edges
    c.rect(18, 36, 6, 1, blkL); c.rect(33, 36, 6, 1, blk)   // where the coat is belted in

    // 6. The breastplate between the coat's edges: silver, lit on the left, gold trim, a glowing seam down the
    //    middle and a magenta stone; plates of a skirt below it, then the legs showing under the open coat.
    c.rect(25, 32, 6, 6, plate)
    c.rect(25, 32, 1, 6, plateL); c.rect(30, 32, 1, 6, plateD); c.rect(25, 32, 6, 1, gold)
    c.rect(27, 33, 2, 3, glow); c.rect(27, 34, 2, 1, gem); c.px(27, 34, gemL)
    c.rect(25, 37, 6, 1, goldD)
    c.rect(25, 38, 6, 2, plateD); c.rect(25, 38, 6, 1, plate); c.px(27, 39, C(0x5A6074))

    // 7. The pauldrons: silver, lit on top, a gold rim, over the coat's shoulders.
    c.pattern(15, 30, [".PPPPPP", "PLLPPPP", "PPPPPPd", "gggggg."], ["P": plate, "L": plateL, "d": plateD, "g": gold])
    c.pattern(34, 30, ["PPPPPP.", "LPPPPdd", "dPPPPdd", ".gggggg"], ["P": plate, "L": plateL, "d": plateD, "g": goldD])

    // 8. The face: eyes with a magenta glint, a lash flicked out at each, and a sly little smile.
    c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink)
    c.px(23, 28, gemL); c.px(33, 28, gemL)
    c.px(21, 28, ink); c.px(34, 28, ink)
    c.pattern(26, 30, ["...m", "mmm."], ["m": C(0x8A2A3E)])

    // 9. The hair in front: strands falling from under the helm down both cheeks.
    c.pattern(18, 26, ["HhH", "HhH", "Hh.", "H..", "h.."], ["H": hair, "h": hairD])
    c.pattern(35, 26, ["HhH", "hHH", ".hH", "..H"], ["H": hairD, "h": hair])
    c.px(18, 26, hairL)

    // 10. The winged helm: a silver dome lit on its upper left, a gold band with the magenta gem, and two white wings
    //     swept up and back off its sides, their outer edges grey-blue so they hold inside the white outline.
    c.pattern(18, 20, [
        "......PPPPPPPP......",
        "....PLLPPPPPPPPP....",
        "..PLLPPPPPPPPPPPPd..",
        ".PLPPPPPPPPPPPPPPdd.",
        "PPPPPPPPPPPPPPPPPddd",
        "GGGGGGGGGGGGGGGGGGGG",
        "gggggggggggggggggggg",
    ], ["P": plate, "L": plateL, "d": plateD, "G": gold, "g": goldD])
    c.pattern(26, 24, [".mm.", "mMMm", ".mm."], ["m": gem, "M": gemL])
    let wingArt = [
        "R.......",
        "RW......",
        "RWW.....",
        "RWWW....",
        ".RWWW...",
        ".RWdWW..",
        "..RWdWW.",
        "..RWWdWW",
        "...RWWdW",
        "....RRWW",
    ]
    c.pattern(10, 15, wingArt, ["R": wingR, "W": wing, "d": wingD])
    c.pattern(38, 15, mirrored(wingArt), ["R": wingR, "W": wingD, "d": wingR])

    // 11. The near arm: in its black sleeve with a white cuff stripe, a silver gauntlet; raised when she casts.
    let raise = p.armRaise
    c.rect(38, 33 - raise, 3, 3, blk); c.rect(39, 33 - raise, 1, 3, wht)
    c.rect(41, 32 - raise, 3, 3, plate); c.px(41, 32 - raise, plateL); c.rect(41, 34 - raise, 3, 1, plateD)
    c.rect(15, 33, 3, 3, blk); c.rect(16, 33, 1, 3, whtD)
}

// MARK: - The Scatterer bug

/// The Scatterer bug: the Hoarder's brown beetle, Clawd under a domed brown shell, seen from the side: ridged wing
/// cases lit along the top with a glossy shine, a dark front shield, a black head with a glinting eye, two feelers up
/// and forward, and amber mandibles. Clawd's four legs are its dark jointed beetle legs. It bites, the mandibles
/// gaping and snapping as it lunges. Signature: the wing cases lift and its pale wings buzz, lifting it off the ground
/// for a moment.
private func drawScatterer(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0x7A5230), shellD = C(0x4E321A), shellL = C(0xA0703E), shine = C(0xD8AA70)
    let chitin = C(0x2A1C12), chitinL = C(0x5A4028), mand = C(0xD09A58), mandD = C(0x8A5E30)
    let legC = C(0x34241A), legL = C(0x5E4428)
    let membrane = C(0xEEE0BE), vein = C(0xA88A5A)
    let s = p.signature ?? -1
    let buzz = span(s, 0.1, 0.9, edge: 0.15)
    let lift = Int((buzz * 3).rounded())

    // 1. The legs: dark, a lit joint, a little hooked foot.
    drawLegs(c, Look(leg: legC), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, 2, legL); c.px(lx + 1, 40, legL)
            c.px(lx + 2, bottom, legC); c.px(lx - 1, 39, legC)
        }
    }

    // 2. The breath; buzzing, it lifts off a little.
    c.oy += p.breathe - lift

    // 3. The wings: pale and veined, fanned up out of the back, buzzing between two places.
    if buzz > 0.3 {
        let up = Int(p.lt * 24) % 2 == 0
        let art = up
            ? ["..vv....", ".vMMv...", "vMMMMv..", "vMvMMMv.", ".vMvMMMv", "..vMvMMv", "...vMvMv", "....vvMv"]
            : ["........", "vvv.....", "vMMMvv..", "vMvMMMvv", ".vMvMMMv", "..vvMvMv", "....vvvv", "........"]
        c.pattern(14, 16, art, ["v": vein, "M": membrane])
        c.pattern(20, 15, art, ["v": vein, "M": membrane])
    }

    // 4. The shell: a dome over Clawd's block, lit along its upper left, shaded underneath, ridges along the wing
    //    cases, the glossy shine, and the dark front shield; lifted a little at the back while it buzzes.
    let open = buzz > 0.3 ? 2 : 0
    for y in (24 - open)...36 {
        for x in 16...37 {
            let dx = (Double(x) + 0.5 - 27) / 11, dy = (Double(y) + 0.5 - 34 + Double(open)) / (10.5 + Double(open))
            guard dx * dx + dy * dy <= 1 else { continue }
            let rim = dx * dx + dy * dy > 0.72
            var col = shell
            if rim && dy < 0 && dx < 0.3 { col = shellL } else if rim && (dy > 0.1 || dx > 0.6) { col = shellD }
            c.px(x, y, col)
        }
    }
    c.rect(17, 35, 20, 2, shellD)
    c.pattern(18, 26 - open, [
        "......rrrrr.....",
        "...rrr..........",
        ".rr.....rrrrr...",
        "......rr........",
        "...rrr....rrrr..",
        ".r..............",
        ".....rrrr.......",
    ], ["r": shellD])
    c.pattern(19, 25 - open, ["..ssss", ".ss...", "ss...."], ["s": shine])
    // The front shield, dark and glossy, a groove behind it.
    c.pattern(31, 27, [
        "..ccc..",
        ".ccccc.",
        "cCcccc.",
        "cCccccc",
        "cccccc.",
        "ccccc..",
        "cccc...",
    ], ["c": chitin, "C": chitinL])
    c.rect(30, 28, 1, 8, shellD)

    // 5. The head and mandibles: the head pushed forward as it lunges, the mandibles gaping wide on the up-swing and
    //    snapping shut on the strike, a white snap where they meet.
    var push = 0, gape = 0
    if let a = p.melee {
        push = Int((max(0, cos(a * .pi / 180)) * 3).rounded())
        gape = a < -40 ? 2 : a < -10 ? 1 : 0
    }
    c.ox += push
    // The feelers, up and forward, clubbed at their tips.
    tentacle(c, [(39, 30), (41, 27), (43, 25), (45, 24)], r0: 0.5, r1: 0.5, legL)
    c.rect(45, 23, 2, 2, legL)
    tentacle(c, [(37, 29), (38, 26), (39, 24)], r0: 0.5, r1: 0.5, legL)
    c.px(39, 23, legL)
    c.pattern(37, 29, [
        ".hhh..",
        "hhhhh.",
        "hhEEhh",
        "hhEwhh",
        "hhhhhh",
        ".hhhh.",
    ], ["h": chitin, "E": ink, "w": white])
    c.px(38, 29, chitinL); c.px(37, 30, chitinL)
    c.pattern(42, 31 - gape, ["MMm.", "..MM", "...M"], ["M": mand, "m": mandD])
    c.pattern(42, 33 + gape, ["...M", "..MM", "MMm."], ["M": mand, "m": mandD])
    if p.melee != nil, gape == 0, !p.trail.isEmpty {
        c.px(47, 33, white); c.px(48, 32, C(0xFFFFFF, 0.7)); c.px(48, 34, C(0xFFFFFF, 0.7))
    }
    c.ox -= push
}

// MARK: - Goblin

/// A goblin: Clawd in green goblin skin, big pointed ears sticking out sideways, yellow eyes and a hooked nose, a
/// gap-toothed grin, a dented iron pot jammed on his head for a helmet, a patched brown leather jerkin with a rope
/// belt, and bare green feet. He throws lit sticks of red goblin dynamite. Signature: he lights one and holds it,
/// grinning, while the fuse fizzes down; then panics, hopping, eyes wide, and pinches it out just in time, a wisp of
/// smoke curling off it.
private func drawGoblin(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x78A040), skinD = C(0x56782C), skinL = C(0x9AC25E)
    let jerk = C(0x7A5232), jerkD = C(0x563820), jerkL = C(0x9A6E44), rope = C(0xC8AE78)
    let pot = C(0x6A6E78), potD = C(0x464A54), potL = C(0x9AA0AA)
    let red = C(0xD8342C), redD = C(0x962018), paper = C(0xE8D8A0), fuse = C(0x3A2A1A)
    let eyeC = C(0xF0D040)
    let s = p.signature ?? -1
    let lit = s > 0.08 && s < 0.78
    let panic = s > 0.5 && s < 0.78
    let smoking = s >= 0.78 && s < 0.98
    let armed = p.fire != nil || p.gunLift > 0
    let hop = panic && Int(p.lt * 10) % 2 == 0 ? 2 : 0

    // 1. Bare green legs, lit down the front, dark toe claws.
    c.oy -= hop
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 38, 1, 3, skinL); c.px(lx + 1, 39, skinD)
            c.px(lx + 2, bottom, skinD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in green; the arms bare.
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil), armRight: armed || lit ? 4 : 0)
    c.rect(18, 26, 1, 7, skinL)

    // 4. The ears: big, pointed, sticking out sideways and a little up, a darker inside.
    c.pattern(10, 25, ["EE......", ".EEEE...", "..EiEEEE", "...EEEEE", ".....EEE"], ["E": skin, "i": skinD])
    c.pattern(38, 25, ["......EE", "...EEEE.", "EEEEiEE.", "EEEEE...", "EEE....."], ["E": skinD, "i": C(0x3E5A1E)])
    c.px(10, 25, skinL)

    // 5. The jerkin: brown leather, lit on the left, the far side in shade, a stitched patch, laced at the front;
    //    a rope belt round it.
    c.rect(18, 32, 20, 6, jerk)
    c.rect(18, 32, 1, 6, jerkL); c.rect(19, 32, 6, 1, jerkL); c.rect(36, 32, 2, 6, jerkD); c.rect(18, 37, 20, 1, jerkD)
    c.pattern(27, 32, ["d.d", ".r.", "d.d", ".r."], ["d": jerkD, "r": rope])
    c.pattern(20, 33, ["PPP", "PpP", "PPP"], ["P": C(0x9A8452), "p": jerkD])
    c.rect(18, 36, 20, 1, rope); c.rect(18, 36, 3, 1, C(0xE4CC98)); c.px(33, 36, jerkD)

    // 6. The face: yellow eyes (wide in a panic), a hooked nose, the gap-toothed grin, or a gasp.
    if panic {
        c.rect(21, 28, 3, 3, eyeC); c.rect(31, 28, 3, 3, eyeC); c.px(22, 29, ink); c.px(32, 29, ink)
        c.rect(26, 33, 3, 2, C(0x3A1A1E))
    } else {
        c.rect(22, 29, 3, 2, eyeC); c.px(23, 29, ink); c.px(24, 30, ink)
        c.rect(31, 29, 3, 2, eyeC); c.px(32, 29, ink); c.px(33, 30, ink)
        c.pattern(21, 28, ["dd........dd."], ["d": skinD])
        c.pattern(24, 33, ["MWMWWM", ".MMMM."], ["M": C(0x3A1A1E), "W": C(0xF0E8D0)])
    }
    c.pattern(27, 30, ["NN", "NNN", ".NN"], ["N": skinD])   // the hooked nose

    // 7. The pot helmet: dented iron, lit on its upper left, a rim round it, a rivet, the dent on top.
    c.pattern(18, 20, [
        ".....PPPPPPPPPP.....",
        "...PLLPPPPdPPPPPP...",
        "..PLPPPPPPddPPPPPd..",
        "..PLPPPPPPPPPPPPPd..",
        "..PPPPPPPPPPPPPPdd..",
        "RRRRRRRRRRRRRRRRRRRR",
        ".rrrrrrrrrrrrrrrrrr.",
    ], ["P": pot, "L": potL, "d": potD, "R": potL, "r": potD])
    c.px(23, 23, C(0xC8CCD4))

    // 8. The near hand and the dynamite: a red stick held unlit at rest; held up ready to throw (gone the
    //    instant it's thrown); held lit in the signature, the fuse burning down, then pinched out and smoking.
    func stick(_ x: Int, _ y: Int, fuseLen: Int, sparks: Bool) {
        c.rect(x, y, 2, 5, red); c.rect(x + 1, y, 1, 5, redD); c.rect(x, y + 2, 2, 1, paper)
        for k in 0..<fuseLen { c.px(x + 1 + k / 2, y - 1 - k, fuse) }
        if sparks {
            let n = Int(p.lt * 20), tx = x + 1 + fuseLen / 2, ty = y - 1 - fuseLen
            c.px(tx, ty, C(0xFFF2A0))
            if n % 2 == 0 { c.px(tx + 1, ty - 1, C(0xFF9A2A)); c.px(tx - 1, ty, C(0xFFD050)) } else { c.px(tx + 1, ty, C(0xFF9A2A)) }
        }
    }
    if armed {
        if p.recoil == 0 { stick(42, 23, fuseLen: 2, sparks: true) }
        c.rect(41, 27, 3, 3, skin); c.px(41, 27, skinL); c.rect(41, 29, 3, 1, skinD)
    } else if lit || smoking {
        let burn = lit ? 4 - Int(((s - 0.08) / 0.7 * 4).rounded(.down)) : 1
        stick(41, 24, fuseLen: max(1, burn), sparks: lit)
        c.rect(40, 28, 3, 3, skin); c.px(40, 28, skinL); c.rect(40, 30, 3, 1, skinD)
        if panic { c.rect(43, 21, 2, 2, skin) }   // the fingers coming in to pinch it
        if smoking {
            let k = (s - 0.78) / 0.2
            for i in 0..<3 {
                let kk = k - Double(i) * 0.15
                guard kk > 0 else { continue }
                c.px(42 + Int((sin(kk * 9) * 1.5).rounded()), 21 - Int(kk * 8), C(0xD8D8E0, 0.6 * (1 - kk)))
            }
        }
    } else {
        stick(40, 28, fuseLen: 1, sparks: false)
        c.rect(39, 32, 3, 3, skin); c.px(39, 32, skinL); c.rect(39, 34, 3, 1, skinD)
    }
}

// MARK: - The Tuskling

/// A Tuskling: one of Ball of Swine's warthog aristocrats on its own, short and stout: Clawd in pale pink with pointed
/// dark-tipped ears, little black eyes, a pink snout with its nostrils, curved ivory tusks either side and a wart under
/// each eye; a black tuxedo with lit lapels over a white shirt and a black bow tie, tuxedo trousers, pink trotters and
/// a curly tail. He doesn't fight. Signature: he screws a gold monocle into his eye, lifts his snout, gives a haughty
/// snort, and the monocle pops out.
private func drawTuskling(_ c: PixelCanvas, _ p: Pose) {
    let pig = C(0xF4BCAC), pigD = C(0xD49284), pigL = C(0xFFDCD0), snout = C(0xE08A82), nostril = C(0x6A2E2E)
    let tux = C(0x24242C), tuxL = C(0x46465A), shirt = C(0xF4F2EE), shirtD = C(0xC8C6D0), tusk = C(0xF6EEDA)
    let gold = C(0xE8C040), goldD = C(0xA88424)
    let s = p.signature ?? -1
    let placing = s > 0.08 && s < 0.2
    let monocle = s >= 0.18 && s < 0.84
    let haughty = s >= 0.26 && s < 0.84
    let snort = s > 0.52 && s < 0.7
    let pop = s >= 0.84 && s < 0.98

    // 1. Tuxedo trousers, pink trotters with a split hoof.
    drawLegs(c, Look(leg: tux), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 38, 1, bottom - 39, tuxL)
            c.rect(lx, bottom - 1, 2, 2, pigD); c.px(lx, bottom - 1, pig); c.px(lx + 1, bottom, nostril)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The curly tail at his back.
    c.pattern(13, 29, [".pp.", "p..p", "..pp", ".p.."], ["p": pigD])

    // 4. The body: pale pink, lit on top and on the left, the far side in shade; short, his head a little low.
    c.rect(19, 27, 18, 1, pig); c.rect(18, 28, 20, 10, pig)
    c.rect(19, 27, 17, 1, pigL); c.rect(18, 28, 1, 5, pigL); c.rect(37, 28, 1, 10, pigD)

    // 5. The ears: pointed, dark-tipped, pricked up.
    c.pattern(19, 23, ["d...", "Dd..", "PPd.", "PPPP"], ["d": pigD, "D": C(0x8A5A50), "P": pig])
    c.pattern(33, 23, ["...d", "..dD", ".dPP", "PPPP"], ["d": pigD, "D": C(0x8A5A50), "P": pigD])
    c.px(19, 25, pigL)

    // 6. The face: small black eyes (lidded and haughty in the signature), a wart under each, the snout (lifted in
    //    the signature) with its nostrils, and the curved tusks either side of it.
    let up = haughty ? 1 : 0
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    if haughty { c.rect(22, 29, 2, 1, pigD); c.rect(32, 29, 2, 1, pigD) }
    c.px(21, 32, pigD); c.px(34, 32, pigD)
    c.pattern(25, 30 - up, [".SSSS.", "SSSSSS", "SnSSnS", ".ssss."], ["S": snout, "s": pigD, "n": nostril])
    c.pattern(23, 31 - up, ["T.", "T.", "TT"], ["T": tusk])
    c.pattern(31, 31 - up, [".T", ".T", "TT"], ["T": tusk])

    // 7. The tuxedo: black, lit lapels, the white shirt front between them, a black bow tie at the collar, two
    //    studs; the far side in shade.
    c.rect(18, 34, 20, 4, tux)
    c.rect(18, 34, 1, 4, tuxL); c.rect(36, 34, 2, 4, C(0x18181E))
    c.pattern(23, 34, ["LWWWWWWL", ".LWWWWL.", "..LWWL..", "...LL..."], ["L": tuxL, "W": shirt])
    c.rect(30, 35, 1, 1, shirtD)
    c.pattern(25, 34, ["bb.bb", ".bbb."], ["b": ink])
    c.px(27, 34, C(0x3A3A48))
    c.px(27, 36, ink); c.px(28, 37, C(0x46465A))

    // 8. The sleeves, white cuffs, pink trotter hands; the near one up at his eye placing the monocle.
    c.rect(15, 33, 3, 3, tux); c.rect(15, 35, 3, 1, shirt); c.px(15, 33, tuxL)
    if placing {
        c.rect(38, 30, 3, 3, tux); c.rect(38, 30, 1, 3, tuxL); c.rect(36, 28, 3, 2, pigD)
    } else {
        c.rect(38, 33, 3, 3, tux); c.rect(38, 35, 3, 1, shirt); c.rect(41, 34, 1, 2, pigD)
    }

    // 9. The monocle: a gold ring over his near eye, a glint on the glass, its chain hanging down to his lapel;
    //    popped out, it drops down on its chain.
    if monocle {
        c.pattern(31, 28, ["ggg.", "g..g", "g..g", ".ggg"], ["g": gold])
        c.px(32, 28, C(0xFFF2C0, 0.9))
        c.rect(34, 32, 1, 2, goldD)
    } else if pop {
        let k = (s - 0.84) / 0.14
        let y = 30 + Int((k * 4).rounded())
        c.pattern(33, y, [".g.", "g.g", ".g."], ["g": gold])
        c.rect(34, 34, 1, 1, goldD)
    }

    // 10. The snort: two little puffs out of his nostrils.
    if snort {
        let k = (s - 0.52) / 0.18
        for (x, dir) in [(26.0, -1.0), (29.0, 1.0)] {
            blob(c, x + dir * (1 + k * 4), 32 + k * 2, 0.8 + k * 1.2, 0.8 + k, C(0xF4F4FA, 0.6 * (1 - k)))
        }
    }
}

// MARK: - The Pooka

/// A Pooka: a fuzzy little goblin-like thing, Clawd in shaggy grey-violet fur in strokes, tufts sticking out all over,
/// long pointed ears pink inside, two little cream horn nubs, big round amber eyes and a wide grin full of pointed
/// teeth. It butts, lunging forward head first. Hit, it turns into a goat: a grey-brown goat on Clawd's four legs with
/// black hooves, swept-back horns, a yellow eye, a beard and a stubby tail. Signature: a puff of smoke, it's a goat,
/// it bleats, another puff and it's back.
private func drawPooka(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let goat = p.hit || (s > 0.3 && s < 0.74)
    if goat { drawPookaGoat(c, p, bleat: s > 0.42 && s < 0.62) } else { drawPookaFuzz(c, p) }
    // The smoke puffs as it changes: solid little clouds, pale with a grey-violet underside, swelling and thinning.
    for start in [0.24, 0.68] {
        let k = (s - start) / 0.14
        guard k > 0, k < 1 else { continue }
        c.ox = p.dx; c.oy = p.hop
        let r = 2 + sin(k * .pi) * 3
        for (dx, dy) in [(-6.0, 0.0), (0, -3), (6, 0), (-2, 4), (4, 4)] {
            blob(c, 28 + dx * (0.6 + k * 0.5), 31 + dy, r, r * 0.85, C(0xB4AEC4))
            blob(c, 28 + dx * (0.6 + k * 0.5) - 0.5, 30.5 + dy, r * 0.8, r * 0.7, C(0xECE8F4))
        }
    }
}

/// The Pooka itself.
private func drawPookaFuzz(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x7C6E8A), furD = C(0x5A4E68), furL = C(0xA092AE)
    let pink = C(0xE8A0B4), nub = C(0xEAD8B4), eyeC = C(0xF4B830)

    // 1. The legs: shaggy fur, tufts at the ankles, dark claws.
    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, 3, furL); c.px(lx + 1, 39, furD)
            c.px(lx - 1, bottom - 1, fur); c.px(lx + 2, bottom - 1, furD)
            c.px(lx + 2, bottom, C(0x2E2636))
        }
    }

    // 2. The breath; and the butt: the whole of it lunging forward head first.
    c.oy += p.breathe
    var push = 0
    if let a = p.melee { push = Int((max(0, cos(a * .pi / 180)) * 3).rounded()) }
    c.ox += push

    // 3. The body: fur, lit along the top and the left, the far side in shade, tufts sticking out of its outline,
    //    the fur in short strokes.
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil))
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 8, furL)
    for y in stride(from: 27, through: 35, by: 3) { c.px(17, y, fur); c.px(38, y + 1, furD) }
    for x in stride(from: 19, through: 36, by: 3) { c.px(x, 38, x % 2 == 0 ? furD : fur) }
    c.pattern(19, 33, [
        "d..d...d...d..d...",
        ".d...d...d...d..d.",
        "...d...d..d...d...",
    ], ["d": furD])
    c.pattern(20, 23, ["l..l.l..l....l..l", "lF.FlF.lFF.FlF.F.", "FFFFFFFFFFFFFFFFF"], ["l": furL, "F": fur])

    // 4. The ears: long and pointed, out sideways, pink inside.
    c.pattern(10, 25, ["F.......", "FFF.....", ".FPPFF..", "..FFFFFF", "....FFFF"], ["F": fur, "P": pink])
    c.pattern(38, 25, [".......F", ".....FFF", "..FFPPF.", "FFFFFF..", "FFFF...."], ["F": furD, "P": C(0xC07890)])
    c.px(10, 25, furL)

    // 5. The horn nubs.
    c.pattern(22, 21, [".n", "nN", "nN"], ["n": nub, "N": C(0xC4B088)])
    c.pattern(32, 21, ["n.", "nN", "nN"], ["n": nub, "N": C(0xC4B088)])

    // 6. The face: big round amber eyes with black pupils, and the wide grin of pointed teeth.
    c.pattern(21, 27, [".EE.", "EEEE", "EEkE", ".EE."], ["E": eyeC, "k": ink])
    c.pattern(31, 27, [".EE.", "EEEE", "EkEE", ".EE."], ["E": eyeC, "k": ink])
    c.pattern(23, 32, ["MMMMMMMMMM", ".WMWMWMWM.", "..MMMMMM.."], ["M": C(0x2E1A26), "W": C(0xF4F0E4)])

    // 7. The far arm and the near one, little furry fists.
    c.px(15, 33, furL)
    c.rect(38, 33, 3, 3, fur); c.px(38, 33, furL); c.rect(38, 35, 3, 1, furD)

    // 8. A star of impact as the butt lands.
    if push >= 3 {
        c.pattern(43, 23, ["..w..", "w.w.w", ".www.", "w.w.w", "..w.."], ["w": C(0xFFF4C8)])
    }
}

/// The Pooka turned goat.
private func drawPookaGoat(_ c: PixelCanvas, _ p: Pose, bleat: Bool) {
    let coat = C(0xC8BCA6), coatD = C(0x9C907A), coatL = C(0xE4DAC6)
    let horn = C(0x6A5A48), hornL = C(0x8E7C66), hoof = C(0x24201E)

    // 1. The legs: grey-brown, a shaded knee, black hooves.
    drawLegs(c, Look(leg: coat), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, 3, coatL); c.px(lx + 1, 39, coatD)
            c.rect(lx, bottom - 1, 2, 2, hoof)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The stubby tail, up.
    c.pattern(15, 26, [".C", "CC", "Cd"], ["C": coat, "d": coatD])

    // 4. The barrel: Clawd's block, a goat's, lit along its back, shaded under, the coat in strokes.
    c.rect(18, 28, 20, 9, coat); c.rect(19, 27, 18, 1, coat)
    c.rect(19, 27, 14, 1, coatL); c.rect(18, 28, 1, 5, coatL)
    c.rect(19, 36, 18, 1, coatD); c.rect(37, 28, 1, 9, coatD)
    c.pattern(20, 30, ["d...d....d..", "..d....d...d", "....d.....d."], ["d": coatD])

    // 5. The neck and head on the front of the barrel: an ear out the back, the yellow eye with its flat black pupil,
    //    the muzzle down and forward, its nostril; the beard hanging under the chin; the mouth open as it bleats.
    c.pattern(31, 17, [
        "....CCCCC.....",
        "...CCCCCCCC...",
        "...CCCCCCCCCC.",
        "..CCCCCCCCCCCC",
        "..CCCCCCCCCCCC",
        "..CCCCCCCCCCCd",
        ".CCCCCC..CCCd.",
        ".CCCCCC.......",
        "CCCCCCC.......",
        "CCCCCCd.......",
        "CCCCCd........",
    ], ["C": coat, "d": coatD])
    c.rect(35, 17, 4, 1, coatL); c.rect(33, 19, 1, 6, coatL)
    c.pattern(30, 19, ["EEE.", ".EEd"], ["E": coatD, "d": C(0x7A6E5A)])            // the ear
    c.rect(39, 19, 3, 1, C(0xE8C430)); c.rect(40, 19, 2, 1, ink)                     // the eye
    c.px(44, 21, ink)                                                                 // the nostril
    if bleat { c.rect(41, 23, 4, 1, C(0x4A2A2A)); c.px(44, 22, coat) }
    c.pattern(40, 23, ["BBB", "BBB", ".BB", ".B."], ["B": coatL])                      // the beard
    c.px(41, 24, coatD)
    // The horns, swept back off the top of the head, ridged.
    tentacle(c, [(37, 17), (35, 14), (32, 13), (30, 14), (29.5, 16)], r0: 1.2, r1: 0.6, horn)
    c.px(35, 15, hornL); c.px(33, 13, hornL)
}

// MARK: - The Krakaren cloneling

/// A Krakaren cloneling: a little pink tentacle blob, the Krakaren clone in miniature: the same deep coral pink, a
/// small round mantle bulging out behind, Clawd's four legs as tentacles with pale suckers, a stubby one trailing
/// behind and another curled in front. A tuft of blonde hair swept down over one eye like its mother's, cross little
/// brows, a lash, a streak of running mascara under each eye and pursed red lips. It doesn't fight. Signature: like
/// mother like daughter, its little tentacle rises and wags at you like a finger.
private func drawCloneling(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD8506E), skinD = C(0xA8344E), skinL = C(0xF07C98), sucker = C(0xF8C4D2)
    let hair = C(0xE8C45A), hairD = C(0xB48A30), hairL = C(0xFAE496)
    let mascara = C(0x241A30), lip = C(0xA81830)
    let s = p.signature ?? -1
    let wagging = s > 0.08 && s < 0.92

    // 1. The legs as tentacles: suckers down the front, the tips curling forward.
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, bottom - 38, skinL)
            c.px(lx + 1, 39, sucker)
            c.px(lx + 2, bottom, skin); c.px(lx + 2, bottom - 1, skinD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The stubby tentacle trailing behind, and the little mantle bulging out at the back, lit on top, a spot.
    tentacle(c, [(19, 36), (15, 39), (12, 41), (10, 40), (10, 38)], r0: 1.4, r1: 0.7, skin)
    c.px(14, 40, sucker)
    blob(c, 18, 30, 4.5, 5, skin)
    blob(c, 16.5, 28, 2, 1.4, skinL)
    c.rect(15, 32, 2, 1, skinD)

    // 4. The body: a round little blob on Clawd's block, its corners rounded, lit on the left, the far side and the
    //    bottom in shade.
    c.rect(20, 27, 16, 1, skin); c.rect(19, 28, 18, 1, skin); c.rect(18, 29, 20, 9, skin)
    c.rect(20, 27, 10, 1, skinL); c.rect(18, 29, 1, 7, skinL)
    c.rect(37, 29, 1, 9, skinD); c.rect(18, 37, 20, 1, skinD)
    c.rect(22, 35, 2, 1, skinD); c.rect(31, 35, 2, 1, skinD)

    // 5. The face: cross little brows, the eyes, a lash flicked out, a streak of mascara under each, pursed lips.
    c.pattern(21, 29, ["hh..", "..hh"], ["h": skinD])
    c.pattern(31, 29, ["hh..", "..hh"], ["h": skinD])
    c.rect(22, 31, 2, 2, ink); c.rect(32, 31, 2, 2, ink); c.px(21, 31, ink); c.px(34, 31, ink)
    c.pattern(22, 33, ["m.", ".m"], ["m": mascara])
    c.pattern(32, 33, [".m", "m."], ["m": mascara])
    c.pattern(27, 34, ["LL", "lL"], ["L": lip, "l": C(0xD84A60)])

    // 6. The hair: a little blonde tuft, spiky at the back, its fringe swept down and across.
    c.pattern(19, 22, [
        "..l.l.........",
        ".lHlHHl.......",
        "lHHHHHHlllHH..",
        ".HhHHHHHHHHHHH",
        "..HhHHhhHHHHhH",
        "...HH....HHhhH",
        "...........HhH",
    ], ["H": hair, "h": hairD, "l": hairL])

    // 7. The near tentacle: curled at rest; up beside its head, wagging, in the signature.
    var pts: [(Double, Double)]
    if wagging {
        let wag = sin(p.lt * 14) * 1.6
        pts = [(37, 34), (40, 32), (41, 28), (41 + wag * 0.5, 25), (41 + wag, 22)]
    } else {
        pts = [(37, 35), (40, 38), (43, 40), (45, 39), (45, 37)]
    }
    tentacle(c, pts, r0: 1.4, r1: 0.7, skin)
    for k in 1..<(pts.count - 2) { c.px(Int(pts[k].0 - 0.5), Int(pts[k].1 + 1), sucker) }
}
