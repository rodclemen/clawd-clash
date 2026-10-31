import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// Bosses and player killers: Amayon, the Reminiscence Hydra, Mrs. Ghazi, Ruckus, Denise, the Station Mimic, Eva,
// Quan Ch.

let crawlVillains5: [CrawlVillain: Persona] = [
    .amayon: Persona(name: "Amayon", weapon: .blaster, shot: .fire, muzzle: (51, 18), handGun: false, bulk: 4,
                     headTop: 4, signature: 3.2, draw: drawAmayon),
    .hydra: Persona(name: "The Reminiscence Hydra", weapon: .blaster,
                    shot: .energy(core: C(0xF4FFD8), glow: C(0x9ADC2A)), muzzle: (55, 24), handGun: false, bulk: 4,
                    headTop: 5, signature: 3.0, draw: drawHydra),
    .mrsGhazi: Persona(name: "Mrs. Ghazi", weapon: .blaster, shot: .thrown(C(0xC8A464)), muzzle: (46, 28),
                       handGun: false, headTop: 21, signature: 3.4, draw: drawMrsGhazi),
    .ruckus: Persona(name: "Ruckus", weapon: .saber, motion: .fly, armoured: true, headTop: 13, signature: 3.0,
                     draw: drawRuckus),
    .denise: Persona(name: "Denise", weapon: .saber, headTop: 12, signature: 2.6, callout: "HONK!", draw: drawDenise),
    .stationMimic: Persona(name: "Station Mimic", weapon: .saber, headTop: 22, signature: 3.0, draw: drawStationMimic),
    .eva: Persona(name: "Eva", weapon: .saber, headTop: 7,
 signature: 3.0, draw: drawEva),
    .quanCh: Persona(name: "Quan Ch", weapon: .blaster, motion: .fly,
                     shot: .energy(core: C(0xE0F4FF), glow: C(0x2E96FF)), muzzle: (46, 31), handGun: false,
                     headTop: 19, signature: 3.2, draw: drawQuanCh),
]

// MARK: - Shared shapes

/// A filled ellipse round (`cx`, `cy`), `rx` by `ry` pixels from its centre to its edge, nothing drawn below `maxY`.
private func v5Blob(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, _ col: Px,
                    maxY: Int = 99) {
    guard rx > 0, ry > 0 else { return }
    for y in Int(floor(cy - ry))...min(maxY, Int(ceil(cy + ry))) {
        for x in Int(floor(cx - rx))...Int(ceil(cx + rx)) {
            let dx = (Double(x) + 0.5 - cx) / rx, dy = (Double(y) + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1 { c.px(x, y, col) }
        }
    }
}

/// A limb, horn or neck through `pts`, `r0` thick at its root thinning to `r1` at its tip.
private func v5Limb(_ c: PixelCanvas, _ pts: [(Double, Double)], r0: Double, r1: Double, _ col: Px) {
    guard pts.count > 1 else { return }
    for i in 0..<(pts.count - 1) {
        let k = Double(i) / Double(pts.count - 1)
        let r = r0 + (r1 - r0) * k
        c.glowLine(pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

/// The point `t` (0…1) of the way along a curve from `a` bending towards `ctrl` to `b`.
private func v5Bend(_ a: (Double, Double), _ ctrl: (Double, Double), _ b: (Double, Double), _ t: Double) -> (Double, Double) {
    let u = 1 - t
    let x = u * u * a.0 + 2 * u * t * ctrl.0 + t * t * b.0
    let y = u * u * a.1 + 2 * u * t * ctrl.1 + t * t * b.1
    return (x, y)
}

/// A neck along that curve, `r` thick.
private func v5Neck(_ c: PixelCanvas, _ a: (Double, Double), _ ctrl: (Double, Double), _ b: (Double, Double),
                    r: Double, _ col: Px) {
    var last = a
    for i in 1...10 {
        let pt = v5Bend(a, ctrl, b, Double(i) / 10)
        c.glowLine(last.0, last.1, pt.0, pt.1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
        last = pt
    }
}

/// 0 outside `a…b`, 1 inside it, easing in and out over `edge` at each end.
private func v5Arc(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    let k = min(1, (s - a) / edge, (b - s) / edge)
    return k * k * (3 - 2 * k)
}

/// How far down a leg's foot is this frame: 42 lifted, 43 on the ground.
private func v5Foot(_ p: Pose, _ i: Int) -> Int { p.step >= 0 && i % 2 == p.step ? 42 : 43 }

// MARK: - Amayon

/// Amayon: a demon lord, Clawd grown huge in lava-red hide, cracks of glowing lava on his shoulder and chest, a black
/// belt with gold studs and a short black flap. His head is a deer's, long and narrow on a thick neck, a burning
/// yellow eye under a heavy brow, a deer's ears laid back, and four black horns: two long ones swept back, two short
/// ones curling forward. The deer's snout ends in a fiery gold beak with little flames licking off it. Pig's legs,
/// pink and bristled, on black cloven trotters. He breathes fire from the beak. Signature: he opens the beak and a
/// column of fire roars straight up out of it into the sky.
private func drawAmayon(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0xB4261C), hideD = C(0x7A1612), hideL = C(0xDC4A2C)
    let lava = C(0xFFA62E), lavaL = C(0xFFE07A)
    let pig = C(0xD08A84), pigD = C(0xA4625E), pigL = C(0xDE9E98), hoof = C(0x2A2224)
    let horn = C(0x2C2426), hornF = C(0x1A1416), hornL = C(0x5E5054)
    let beak = C(0xFFC23A), beakD = C(0xE0761A), beakL = C(0xFFF2A8)
    let belt = C(0x24181A), gold = C(0xE8B840), goldD = C(0xA87E1E)
    let flameR = C(0xE8341A), flameO = C(0xFF8A1E), flameY = C(0xFFE45A)
    let s = p.signature ?? -1
    let column = v5Arc(s, 0.1, 0.9, edge: 0.18)
    let open = p.fire != nil || column > 0.05

    // 1. Pig's legs: pink, lit down the front, a bristle or two, black cloven trotters.
    drawLegs(c, Look(leg: pig), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx, 37, 1, bottom - 39, pigL)
            c.px(lx + 1, 38, pigD); c.px(lx + 1, 40, pigD)
            c.rect(lx, bottom - 1, 2, 2, hoof); c.px(lx, bottom - 1, hornL)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, in shade behind him, black claws hanging.
    c.rect(11, 27, 4, 8, hideD); c.rect(11, 27, 4, 1, hide)
    crawlTalons(c, (12.5, 35), angle: 95, len: 2.5, horn)

    // 4. The body, huge: lava-red, lit on the top and left, the far side and underneath in shade; glowing cracks on
    //    the shoulder and chest; the black belt with its gold studs and buckle, a short flap hanging between the legs.
    c.rect(15, 24, 24, 14, hide)
    c.rect(15, 24, 24, 1, hideL); c.rect(15, 25, 1, 11, hideL)
    c.rect(37, 25, 2, 13, hideD); c.rect(15, 37, 24, 1, hideD)
    c.rect(19, 30, 7, 1, hideD); c.rect(28, 30, 7, 1, hideD)   // the line under the chest
    for (x, y) in [(17, 26), (18, 27), (18, 28), (20, 31), (21, 32), (21, 33), (22, 34)] { c.px(x, y, lava) }
    for (x, y) in [(33, 31), (32, 32), (32, 33), (33, 34)] { c.px(x, y, lava) }
    c.px(21, 32, lavaL); c.px(32, 32, lavaL)
    c.rect(15, 35, 24, 2, belt)
    for x in [17, 21, 33, 37] { c.px(x, 35, gold) }
    c.rect(25, 35, 4, 2, gold); c.rect(26, 36, 2, 1, goldD)
    c.rect(26, 37, 4, 3, belt); c.rect(26, 39, 4, 1, goldD)

    // 5. The near arm, thick, hanging, black claws at the hand.
    c.rect(39, 27, 4, 8, hide); c.rect(39, 27, 4, 1, hideL); c.rect(39, 28, 1, 7, hideL); c.rect(42, 28, 1, 7, hideD)
    c.rect(39, 34, 5, 2, hide); c.rect(39, 35, 5, 1, hideD)
    crawlTalons(c, (42.5, 36), angle: 75, len: 2.5, horn)

    // 6. The far horns, behind his head: one long and swept back, one short and curling forward.
    v5Limb(c, [(31, 12), (29, 8), (26, 6), (23, 6)], r0: 1.1, r1: 0.5, hornF)
    v5Limb(c, [(36, 12), (38, 9), (40, 8)], r0: 1.0, r1: 0.5, hornF)

    // 7. The neck, thick, lit down the back.
    c.rect(30, 19, 7, 6, hide); c.rect(30, 19, 1, 6, hideL); c.rect(36, 20, 1, 5, hideD)

    // 8. The deer's head: the ears laid back, the long skull lit along its top, the heavy brow over the burning eye,
    //    the jaw in shade.
    c.pattern(27, 10, [
        "...KK",
        "..KHHK",
        "..KHHHHHHHH",
        "...HLLLLLLLHH",
        "...HHHHHHHHHHHH",
        "...HHHHHBBBHHHHH",
        "...HHHHHHYeHHHHHH",
        "....HHHHHHHHHHHHH",
        "....DHHHHHHHHHHHD",
        ".....DDHHHHHHHDD",
        ".......DDDDDDD",
    ], ["K": hideD, "H": hide, "L": hideL, "B": hideD, "D": hideD, "Y": lavaL, "e": ink])

    // 9. The near horns over the skull, lit along their curve: the long one with its tine, the short one forward.
    v5Limb(c, [(33, 12), (32, 8), (29, 5), (26, 4)], r0: 1.1, r1: 0.5, horn)
    v5Limb(c, [(31, 7.5), (33, 4.5)], r0: 0.7, r1: 0.5, horn)
    v5Limb(c, [(38, 13), (40, 10), (43, 9), (44, 7)], r0: 1.0, r1: 0.5, horn)
    for (x, y) in [(32, 9), (30, 6), (40, 10)] { c.px(x, y, hornL) }

    // 10. The beak, gold and hot: shut, or open with the fire glowing in it; little flames lick off the top.
    if open {
        c.pattern(43, 14, ["LBB....", "BBBBBBB", "bbbbb.."], ["B": beak, "b": beakD, "L": beakL])
        c.rect(43, 17, 6, 1, lavaL); c.rect(43, 18, 5, 1, lava)
        c.pattern(43, 19, ["bbbbb.", "bbb..."], ["b": beakD])
    } else {
        c.pattern(43, 15, ["LBB....", "BBBBB..", "BBBBBBB", "bbbbbb.", "bbb...."], ["B": beak, "b": beakD, "L": beakL])
    }
    let lick = Int(p.lt * 7) % 3
    c.px(45 + lick % 2, open ? 13 : 14, flameO); c.px(46, open ? 12 : 13, lick == 0 ? flameY : flameR)

    // 11. The column: fire roaring up out of the open beak and on up out of the sky, red outside, orange, a yellow
    //     heart, wavering; it climbs as it starts and thins as it ends. Solid flame, so it keeps its outline.
    if column > 0.05 {
        let top = 18 - column * 26
        for y in Int(top.rounded())...18 {
            let k = Double(18 - y) / 26
            let cx = 50 + sin(Double(y) * 0.55 + p.lt * 10) * 0.9
            let half = (1.0 + 1.9 * column) * (0.8 + 0.5 * k)
            let x0 = Int((cx - half).rounded()), x1 = Int((cx + half).rounded())
            c.rect(x0, y, x1 - x0 + 1, 1, flameR)
            if x1 - x0 >= 2 { c.rect(x0 + 1, y, x1 - x0 - 1, 1, flameO) }
            if x1 - x0 >= 4 { c.rect(x0 + 2, y, x1 - x0 - 3, 1, flameY) }
        }
        for i in 0..<4 where Int(p.lt * 9) % 4 != i {
            let k = (p.lt * 1.3 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
            c.px(45 + i * 3 - (i > 1 ? 1 : 0), 16 - Int(k * 14), C(0xFFE07A, 0.8 * (1 - k)))
        }
    }
}

// MARK: - The Reminiscence Hydra

/// The Reminiscence Hydra: Clawd as a great ball of stitched flesh, pink-tan, a grey-green patch sewn into its lower
/// side and a seam across it, dark stitches crossing both, Clawd's two eyes peering out of the middle; it sits on four
/// short stumpy legs. Out of the top grow nine long necks, each with a little head of its own, swaying, the left four
/// looking back and the rest forward, every head's eye glowing a different colour and the colours shifting along.
/// The front head spits its energy, acid green. Signature: a head pops off with a puff, and a new one balloons back
/// out of the stump.
private func drawHydra(_ c: PixelCanvas, _ p: Pose) {
    let flesh = C(0xC88E78), fleshD = C(0x9A6252), fleshL = C(0xE6B4A0)
    let patch = C(0x8EA070), patchD = C(0x6E7E54)
    let head = C(0xE8B49C), headL = C(0xFAD4C0), neckC = C(0xA86A58)
    let stitch = C(0x3A2226), mouth = C(0x5A2A2E), glow = C(0xD8FF7A)
    let eyes: [Px] = [C(0xFF5AA0), C(0xFF9A3A), C(0xFFE04A), C(0x9AF04A), C(0x3AE8D0), C(0x4A9AFF), C(0xB070FF),
                      C(0xFF4AE0), C(0xFFFFFF)]
    let s = p.signature ?? -1
    let firing = p.fire != nil

    // 1. The stumpy legs: flesh, lit down the front, a stitch across each, darker toes.
    drawLegs(c, Look(leg: flesh), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx, 38, 1, bottom - 38, fleshL)
            c.px(lx, 40, stitch); c.px(lx + 1, 41, stitch)
            c.rect(lx, bottom, 2, 1, fleshD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The ball: shaded round its lower right, lit on its upper left.
    v5Blob(c, 29, 30.5, 12.5, 8.5, fleshD)
    v5Blob(c, 28, 29.5, 12.5, 8.5, flesh)
    v5Blob(c, 22, 24.5, 4, 1.6, fleshL)
    c.rect(17, 27, 1, 4, fleshL)

    // 4. The patch sewn in, grey-green, stitched round; the seam across the ball with its cross-stitches.
    v5Blob(c, 21.5, 34, 4.5, 3, patch)
    c.rect(18, 36, 7, 1, patchD)
    for i in 0..<14 where i % 2 == 0 {
        let a = Double(i) / 14 * 2 * .pi
        c.px(Int((21.5 + cos(a) * 5).rounded(.down)), Int((34 + sin(a) * 3.4).rounded(.down)), stitch)
    }
    for i in 0...10 {
        let pt = v5Bend((26, 37), (34, 27), (40, 30), Double(i) / 10)
        let x = Int(pt.0.rounded()), y = Int(pt.1.rounded())
        c.px(x, y, i % 2 == 0 ? stitch : fleshD)
    }

    // 5. Clawd's eyes, peering out of the middle of it.
    c.rect(22, 28, 2, 3, ink); c.rect(31, 28, 2, 3, ink)
    c.px(22, 28, C(0x6A4A44)); c.px(31, 28, C(0x6A4A44))

    // 6. The nine necks and heads, swaying: the left four look back, the rest forward. The top one pops off and
    //    balloons back in the signature; the front one spits.
    let spots: [(Double, Double)] = [(6, 24), (9, 16), (15, 10), (22, 7), (29, 6.5), (36, 7), (43, 10), (48, 16),
                                     (51, 23)]
    let popping = s > 0.06 && s < 0.9
    for (i, spot) in spots.enumerated() {
        let a = (-165 + Double(i) * 18.75) * .pi / 180
        let base = (28 + 11.5 * cos(a), 29.5 + 8 * sin(a))
        let still = i == 8 && firing
        let wx = still ? 0 : sin(p.lt * 2.3 + Double(i) * 1.7) * 1.0
        let wy = still ? 0 : cos(p.lt * 1.9 + Double(i) * 1.3) * 0.8
        let hx = spot.0 + wx, hy = spot.1 + wy
        let left = i < 4
        let neckEnd = (hx + (left ? 1.5 : -1.5), hy + 1.5)
        let ctrl = ((base.0 * 2 + hx) / 3, (base.1 + hy * 2) / 3)
        v5Neck(c, base, ctrl, neckEnd, r: 1.0, neckC)
        v5Neck(c, (base.0 - 0.4, base.1 - 0.4), (ctrl.0 - 0.4, ctrl.1 - 0.4), (neckEnd.0 - 0.3, neckEnd.1 - 0.4),
               r: 0.35, flesh)
        let mid = v5Bend(base, ctrl, neckEnd, 0.5)
        c.px(Int(mid.0.rounded()), Int(mid.1.rounded()), stitch)

        let eye = eyes[(i + Int(p.lt * 1.2)) % eyes.count]
        let open = i == 8 && firing
        var rows = ["..LLL.", ".HHHEH", "HHHHHH", ".HHMMM"]
        if left { rows = rows.map { String($0.reversed()) } }
        let pal: [Character: Px] = ["L": headL, "H": head, "E": eye, "M": open ? glow : mouth]
        let ox = Int(hx.rounded()) - 3, oy = Int(hy.rounded()) - 2

        if i == 4 && popping {
            if s < 0.3 {
                // Popped: the head flies up, fading, a puff where it was.
                let k = (s - 0.06) / 0.24
                if k < 0.6 { c.pattern(ox + Int(k * 6), oy - Int(k * 4), rows, pal) }
                if k < 0.5 {
                    for (dx, dy) in [(-3, 0), (3, 0), (0, -3), (-2, -2), (2, -2)] {
                        c.px(Int(neckEnd.0) + dx, Int(neckEnd.1) + dy, C(0xFFF4E8, 0.9 * (1 - k * 2)))
                    }
                }
            } else if s < 0.45 {
                // The stump, a drop on it.
                c.px(Int(neckEnd.0), Int(neckEnd.1) + 1, fleshD)
            } else if s < 0.82 {
                // A new head ballooning out of the stump, round and shiny, growing.
                let k = (s - 0.45) / 0.37
                let r = 0.8 + k * 2.4
                v5Blob(c, hx, hy, r, r * 0.85, head)
                v5Blob(c, hx - r * 0.35, hy - r * 0.35, r * 0.35, r * 0.3, headL)
            } else {
                c.pattern(ox, oy, rows, pal)
            }
            continue
        }
        c.pattern(ox, oy, rows, pal)
    }
}

// MARK: - Mrs. Ghazi

/// Mrs. Ghazi: a sand ooze, Clawd's block gone soft and lumpy in warm tan sand: a slumping dome on top, ripples of
/// darker sand along it like a dune, lit along the top, drips of sand sagging down her sides and a thin trickle always
/// running off her to little heaps on the ground. Two deep-set eyes and a thin wobbly mouth pressed into the sand.
/// She throws clumps of sand from a pseudopod. Signature: she slumps down into a low heap of sand, her eyes just
/// peeping out of the top, and slowly rises again.
private func drawMrsGhazi(_ c: PixelCanvas, _ p: Pose) {
    let sand = C(0xD8B472), sandD = C(0xAE8848), sandL = C(0xF0D49A), deep = C(0x4A361C)
    let s = p.signature ?? -1
    let slump = v5Arc(s, 0.06, 0.94, edge: 0.32)
    let sink = Int((slump * 10).rounded())
    let sp = Int((slump * 4).rounded())
    let armed = p.fire != nil || p.gunLift > 0

    // 1. The legs, sand to the toes, shaded on their far side, a little heap of fallen sand by each outer foot.
    drawLegs(c, Look(leg: sand), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx + 1, 38, 1, bottom - 38, sandD)
            c.px(lx, 39 + i % 2, sandL)
        }
        c.pattern(13, 42, [".dd.", "dDDd"], ["d": sandD, "D": sand])
        c.pattern(39, 42, [".dd.", "dDDd"], ["d": sandD, "D": sand])
    }

    // 2. The trickles: a thin stream of sand running off each side down to its heap, a lighter grain sliding down.
    if !seatedPose {
        for (n, x) in [15, 40].enumerated() {
            c.rect(x, 35, 1, 7, sandD)
            let f = (p.lt * 1.4 + Double(n) * 0.5).truncatingRemainder(dividingBy: 1)
            c.px(x, 35 + Int(f * 7), sandL)
        }
    }

    // 3. The breath.
    c.oy += p.breathe

    // 4. The body: the block gone soft, a lumpy dome slumping into it, lower and wider as she sinks.
    let top = 22 + sink
    let foot = 37 + Int((slump * 3).rounded())   // the heap's bottom edge, down over the tops of the legs as she slumps
    c.rect(18 - sp, top + 4, 20 + 2 * sp, foot + 1 - top - 4, sand)
    if slump > 0.3 { c.rect(16 - sp, foot - 2, 24 + 2 * sp, 3, sand); c.rect(16 - sp, foot, 24 + 2 * sp, 1, sandD) }
    v5Blob(c, 28, Double(top) + 5.5, 10.5 + Double(sp), 5.5, sand, maxY: top + 5)
    v5Blob(c, 22, Double(top) + 3.5, 4, 3, sand, maxY: top + 5)
    v5Blob(c, 33, Double(top) + 4, 3.5, 2.6, sand, maxY: top + 5)
    v5Blob(c, 22, Double(top) + 2.2, 2.6, 1.0, sandL)
    v5Blob(c, 28, Double(top) + 1.4, 3.2, 0.9, sandL)
    c.rect(18 - sp, top + 5, 1, 32 - top, sandL)
    c.rect(37 + sp, top + 5, 1, 32 - top, sandD); c.rect(18 - sp, foot, 20 + 2 * sp, 1, sandD)
    // Drips sagging off her bottom edge down the fronts of two legs.
    if !seatedPose && slump < 0.3 {
        c.rect(20, 38, 1, 2, sand); c.px(20, 40, sandD)
        c.rect(32, 38, 1, 1, sand); c.px(32, 39, sandD)
    }

    // 5. The ripples, dune lines along her, and the drips sagging down her sides.
    for (row, line) in [(top + 9, "dd.....dddd.....dd"), (top + 12, "...ddd......ddd...")] where row < 37 {
        c.pattern(19, row, [line], ["d": sandD])
    }
    let sag = Int((sin(p.lt * 1.6) * 1.2).rounded())
    c.rect(17 - sp, top + 7, 1, 6 + sag, sand); c.px(17 - sp, top + 13 + sag, sandD)
    c.rect(38 + sp, top + 8, 1, 4 - sag, sand); c.px(38 + sp, top + 12 - sag, sandD)

    // 6. The face: deep-set eyes and a thin wobbly mouth, pressed into the sand.
    let ey = min(top + 7, 33)
    c.rect(22, ey, 2, 3, deep); c.rect(32, ey, 2, 3, deep)
    c.px(22, ey - 1, sandD); c.px(23, ey - 1, sandD); c.px(32, ey - 1, sandD); c.px(33, ey - 1, sandD)
    if ey + 4 <= 36 { c.pattern(25, ey + 4, ["d.dd.d", ".d..d."], ["d": deep]) }

    // 7. The pseudopods: the far one a lump at her side; the near one too, or pushed out with a clump of sand on it.
    let ay = 32 + Int((slump * 5).rounded())   // the pseudopods sink with her
    c.rect(14 - sp, ay, 4, 3, sand); c.rect(14 - sp, ay + 2, 4, 1, sandD)
    if armed {
        c.rect(38 + sp, 30, 4, 3, sand); c.rect(41 + sp, 28, 3, 3, sand); c.rect(38 + sp, 32, 6, 1, sandD)
        if p.recoil == 0 {
            c.pattern(44 + sp, 26, [".LL", "LSS", "SSd"], ["L": sandL, "S": sand, "d": sandD])
        }
    } else {
        c.rect(38 + sp, ay, 3, 3, sand); c.rect(38 + sp, ay + 2, 3, 1, sandD)

    }
}

// MARK: - Ruckus

/// A steel wing spread from the shoulder `sh`: long feathers fanned between `from` and `to` degrees, `len` long, each
/// lit along its top, the leading one brightest.
private func ruckusWing(_ c: PixelCanvas, _ sh: (x: Double, y: Double), from: Double, to: Double, len: Double,
                        _ col: Px, _ colD: Px, _ colL: Px) {
    for k in 0..<6 {
        let a = from + (to - from) * Double(k) / 5
        let l = len - Double(k) * 1.2
        crawlBar(c, sh, a, from: 0, to: l, k % 2 == 0 ? col : colD, r: 1.2)
    }
    crawlBar(c, sh, from, from: 1, to: len, colL, r: 0.5)
}

/// Ruckus: a clockwork chicken hawk sentinel, Clawd in riveted brass, a steel gear turning on his breast. A hawk's
/// head of steel up on a brass collar: a crest of steel plumes swept back, a red glass eye under a dark brow and a big
/// hooked brass beak. A brass wind-up key in his back, a great steel wing folded along his side in long feather plates,
/// its tips trailing back over the steel tail, and steel bird's legs. Flying, both wings spread and beat. He fights
/// with his talons. Signature: the key spins as he winds himself up, the gear whirring, then with a clank a spring
/// boings out of his back in a puff of steam and his eye flares.
private func drawRuckus(_ c: PixelCanvas, _ p: Pose) {
    let brass = C(0xC8983A), brassD = C(0x8C6620), brassL = C(0xF0CA6A)
    let steel = C(0x8C949E), steelD = C(0x5A616A), steelL = C(0xC8D0D8)
    let rivet = C(0x5A4216), eye = C(0xFF3A26), eyeL = C(0xFFC0B0)
    let s = p.signature ?? -1
    let winding = s > 0.05 && s < 0.55
    let clank = s >= 0.55 && s < 0.92
    let up = Int(p.t * 8) % 2 == 0

    // 1. Steel bird's legs: lit down the front, scale strokes, a talon forward and a spur back on each foot.
    drawLegs(c, Look(leg: steel), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx, 37, 1, bottom - 37, steelL)
            c.px(lx + 1, 39, steelD); c.px(lx + 1, 41, steelD)
            c.px(lx + 2, bottom, steelD); c.px(lx - 1, bottom - 1, steelD)
        }
    }

    // 2. The breath, and the jolt of the clank.
    c.oy += p.breathe
    if clank && s < 0.62 { c.oy -= 1 }

    // 3. Flying, the far wing spread behind, beating.
    if p.flying {
        ruckusWing(c, (24, 28), from: up ? -150 : 160, to: up ? -105 : 205, len: 15, steelD, steelD, steel)
    }

    // 4. The tail: long steel feathers sloping down behind, lit along the top.
    c.pattern(7, 31, [
        "LLLLSS.......",
        "SSSSSSSSSS...",
        ".dSdSdSSSSSS.",
        "..SSSSSSSSSSS",
        "....dddSSSS..",
    ], ["S": steel, "d": steelD, "L": steelL])

    // 5. The wind-up key in his back: a brass shaft and its bow, turning (fast while he winds himself up).
    let turn = Int(p.lt * (winding ? 12 : 1.5)) % 4
    let bowW = [3, 2, 1, 2][turn]
    c.rect(18, 23, 1, 3, brassD)
    c.rect(18 - bowW / 2, 18, bowW, 5, brass); c.rect(18 - bowW / 2, 18, bowW, 1, brassL)

    // 6. The body: brass plates, lit along their tops, a seam across, rivets; the breast at the front with the
    //    steel gear on it, turning (whirring while he winds).
    drawBody(c, Look(body: brass, shade: brassD, arm: steel, eye: nil))
    c.rect(18, 26, 19, 1, brassL); c.rect(18, 27, 1, 10, brassL)
    c.rect(19, 35, 18, 1, brassD)
    for (x, y) in [(20, 27), (35, 27), (20, 36), (35, 36)] { c.px(x, y, rivet) }
    let gearA = winding ? Int(p.lt * 14) % 2 == 0 : Int(p.lt * 1.2) % 2 == 0
    c.pattern(31, 31, gearA ? [".S.S.", "SSsSS", ".sos.", "SSsSS", ".S.S."] : ["S.S.S", ".SsS.", "SsosS", ".SsS.", "S.S.S"],
              ["S": steelL, "s": steel, "o": ink])

    // 7. The folded wing along his side: long steel feather plates, lit along the top, their tips trailing back over
    //    the tail; a rivet at the shoulder.
    if !p.flying {
        c.pattern(11, 27, [
            ".......LLLLLLLLLLLL.",
            ".....SSSSSSSSSSSSSSS",
            "...SSSSdSSSSdSSSSSSS",
            "LLSSSSSSdSSSSdSSSSSS",
            "SSSSSSSSSdSSSSdSSSS.",
            ".dddddSSSSdSSSSdSS..",
            "......ddddddddddd...",
        ], ["S": steel, "d": steelD, "L": steelL])
        c.px(28, 29, rivet)
    }

    // 8. The head, up on its brass collar: steel, the crest of plumes swept back, the red glass eye under a dark
    //    brow (flaring at the clank), the big hooked brass beak.
    c.rect(29, 23, 9, 4, brass); c.rect(29, 23, 9, 1, brassL); c.rect(29, 25, 9, 1, brassD)
    c.pattern(27, 14, [
        "....LLLL.......",
        "..SSSSSSSL.....",
        ".SSSSSSSSSSL...",
        "SSSSSSSddddSS..",
        "SSSSSSSSSERSSS.",
        ".SSSSSSSSRRSSSS",
        "..SSSSSSSSSSSS.",
        "...dSSSSSSSSd..",
        "....dddddddd...",
    ], ["S": steel, "d": steelD, "L": steelL, "E": eyeL, "R": eye])
    c.pattern(21, 13, ["LL.....", ".LSS...", "..dSSSS", "...dSSS", ".....dS"], ["S": steel, "d": steelD, "L": steelL])
    c.pattern(40, 17, [
        "LBB....",
        "BBBBB..",
        "bBBBBB.",
        "..bbBBB",
        "....bBb",
        ".....b.",
    ], ["B": brass, "b": brassD, "L": brassL])
    if clank && s < 0.75 {
        c.rect(36, 18, 2, 2, C(0xFFA080)); c.rect(35, 17, 4, 4, C(0xFF5A3A, 0.22))
    }

    // 9. Flying, the near wing spread too, beating.
    if p.flying {
        ruckusWing(c, (27, 29), from: up ? -140 : 165, to: up ? -95 : 210, len: 16, steel, steelD, steelL)
    }

    // 10. The spring, boinging out of his back at the clank, a puff of steam, then pulling back in.
    if clank {
        let k = s < 0.62 ? (s - 0.55) / 0.07 : max(0, 1 - (s - 0.75) / 0.17)
        let len = Int((min(1, k) * 7).rounded())
        if len > 0 {
            for j in 0..<len {
                c.px(j % 2 == 0 ? 23 : 25, 25 - j, j % 2 == 0 ? steelL : steel)
                c.px(24, 25 - j, steelD)
            }
            c.rect(22, 25 - len, 5, 1, brass)
        }
        if s < 0.8 {
            let f = (s - 0.55) / 0.25
            for (dx, dy) in [(-4, -1), (4, -2), (-2, -5), (3, -6)] {
                c.circle(24 + dx, 20 + dy - Int(f * 3), 1, C(0xF0F4F8, 0.55 * (1 - f)))
            }
        }
    }

    // 11. The talons: a steel foot with its claws resting at his front, or striking out.
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            crawlTalons(c, crawlReach((39, 34), ta, 5), angle: ta, len: 4, steelL, alpha: 0.35 / Double(i + 1))
        }
        crawlBar(c, (39, 34), a, from: 0, to: 5, steel, r: 1.1)
        crawlTalons(c, crawlReach((39, 34), a, 5), angle: a, len: 3.5, steelL)
    } else {
        c.rect(38, 33, 3, 3, steel); c.px(38, 33, steelL)
        crawlTalons(c, (40.5, 35), angle: 80, len: 2.5, steelL)
    }
}

// MARK: - Denise

/// Denise: a feral goose, Clawd as a Canada goose: a grey-brown body with its wing folded at the side in scalloped
/// feathers, a pale buff breast, a white rump under a short black tail. A long black neck up to a black head with the
/// white chinstrap under its cheek, a mean glinting eye and a long dark beak; black legs. She fights by darting her
/// neck out and biting. Signature: she spreads her wings wide, drops her head low and forward, opens her beak with its
/// pink tongue and hisses.
private func drawDenise(_ c: PixelCanvas, _ p: Pose) {
    let plum = C(0x8A7A6A), plumD = C(0x62564A), plumL = C(0xB0A08C)
    let breast = C(0xCFC2AC), breastD = C(0xA8987E)
    let black = C(0x1E1C20), blackL = C(0x4A4850), whiteF = C(0xF2F0EA)
    let tongue = C(0xE86A7A), leg = C(0x2E2C30)
    let s = p.signature ?? -1
    let hiss = v5Arc(s, 0.08, 0.92, edge: 0.15)
    var lunge = 0.0
    if let a = p.melee { lunge = max(0, min(1, (a + 110) / 120)) }
    let low = max(lunge, hiss * 0.75)
    let open = lunge > 0.55 || hiss > 0.3

    // 1. Black legs, a lit run down the front, webbed feet spread forward.
    drawLegs(c, Look(leg: leg), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx, 38, 1, bottom - 39, C(0x4E4C54))
            c.px(lx + 2, bottom, leg)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The wings spread, when she hisses: both raised behind her and arched, the bend of each wing up high, the
    //    grey-brown feathers falling back from it to the dark primaries at the tip, the leading edge lit.
    if hiss > 0.05 {
        let l = hiss
        let wings: [(sh: (Double, Double), wrist: (Double, Double), tip: (Double, Double), col: Px)] = [
            ((22, 28), (19, 28 - 13 * l), (6, 29 - 7 * l), plumD),
            ((26, 29), (25, 29 - 16 * l), (9, 30 - 5 * l), plum),
        ]
        for w in wings {
            for k in 0...12 {
                let t = Double(k) / 12
                let pt = (w.wrist.0 + (w.tip.0 - w.wrist.0) * t, w.wrist.1 + (w.tip.1 - w.wrist.1) * t)
                c.glowLine(w.sh.0, w.sh.1, pt.0, pt.1, core: k % 4 == 3 ? plumD : w.col, glow: C(0, 0),
                           coreR: 0.8, glowR: 0.9)
                if t > 0.45 && k % 2 == 0 {
                    c.glowLine(pt.0, pt.1, pt.0 + 1, pt.1 + 3, core: C(0x3A322A), glow: C(0, 0), coreR: 0.6, glowR: 0.7)
                }
            }
            c.glowLine(w.sh.0, w.sh.1, w.wrist.0, w.wrist.1, core: plumL, glow: C(0, 0), coreR: 0.6, glowR: 0.7)
            c.glowLine(w.wrist.0, w.wrist.1, w.tip.0, w.tip.1, core: plumL, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        }
    }

    // 4. The tail: short and black, tipped up behind, the white rump under it.
    c.pattern(12, 26, ["BB....", "BBBBB.", ".BBBBB", "..LLBB"], ["B": black, "L": blackL])
    c.rect(15, 32, 4, 4, whiteF); c.rect(15, 35, 4, 1, C(0xC8C6C0))

    // 5. The body: grey-brown, lit on top; the pale breast at the front; the wing folded along the side in scalloped
    //    feathers, its dark primaries trailing back over the rump.
    drawBody(c, Look(body: plum, shade: plumD, arm: plum, eye: nil))
    c.rect(18, 26, 19, 1, plumL); c.rect(18, 27, 1, 5, plumL)
    c.rect(29, 30, 9, 8, breast); c.rect(29, 37, 9, 1, breastD); c.rect(37, 30, 1, 8, breastD)
    for (x, y) in [(31, 32), (34, 33), (32, 35), (35, 36)] { c.rect(x, y, 2, 1, breastD) }
    if hiss < 0.05 {
        c.pattern(17, 27, [
            "..WWWWWWWWWW..",
            ".WWWWWWWWWWWWW",
            "WlWWWlWWWlWWWW",
            "WWlWWWlWWWlWWW",
            "WWWWWWWWWWWWW.",
        ], ["W": plumD, "l": plumL])
        c.rect(12, 31, 7, 2, C(0x3A322A)); c.rect(12, 31, 7, 1, plumD)   // the primaries, trailing back over the rump
    }
    c.rect(15, 33, 3, 3, plum); c.rect(38, 33, 3, 3, plum); c.rect(38, 35, 3, 1, plumD)

    // 6. The neck: long and black, rising off her front, or darting low and forward to bite.
    let hx = 39 + low * 9, hy = 15 + low * 8
    let base = (34.5, 28.0)
    let end = (hx - 1.5, hy + 1.5)
    let ctrl = (32 + low * 4, (28 + hy) / 2 - low * 3)
    v5Neck(c, base, ctrl, end, r: 2.0, black)

    let ghost = p.trail.first.map { max(0, min(1, ($0 + 110) / 120)) }
    if let g = ghost, abs(g - lunge) > 0.1 {
        let gx = 39 + g * 9, gy = 15 + g * 8
        c.rect(Int(gx) - 1, Int(gy) - 1, 6, 3, black.alpha(0.3))
    }

    // 7. The head: black, the white chinstrap under the cheek, the mean eye with its glint, the long dark beak, shut
    //    or open with the pink tongue.
    let ox = Int(hx.rounded()) - 4, oy = Int(hy.rounded()) - 2
    c.pattern(ox, oy, ["..BBBBB", ".BBBBBEB", ".BBWWWBBkkk.", ".BWWWWWBkkkk", "..WWWWW"],
              ["B": black, "W": whiteF, "E": C(0xF0E8D8), "k": blackL])
    c.px(ox + 5, oy, blackL)
    if open {
        c.pattern(ox + 8, oy + 3, ["tttt", "kkkk"], ["t": tongue, "k": blackL])
        if hiss > 0.3, Int(p.lt * 10) % 3 != 0 {
            for i in 0..<3 { c.px(ox + 14 + i, oy + 2 + (i % 2) * 2, C(0xFFFFFF, 0.7)) }
        }
    }
}

// MARK: - The Station Mimic

/// The Station Mimic: Clawd in a treasure chest, his orange legs out underneath: a wooden chest with a rounded lid,
/// planks picked out, two black iron straps over it, gold corner caps and a gold lock plate with its keyhole. Yellow
/// eyes on the lid, and a row of teeth always peeping out of the seam. It bites: the lid swings up on its hinge at
/// the back, showing the dark red maw, the teeth top and bottom and a lolling pink tongue, and snaps shut. Signature:
/// the lid creaks slowly open, the tongue licks round, and it snaps shut with a jump.
private func drawStationMimic(_ c: PixelCanvas, _ p: Pose) {
    let wood = C(0x9A6434), woodD = C(0x6E4420), woodL = C(0xC08850)
    let iron = C(0x3E424C), ironL = C(0x6E7480), gold = C(0xE8C04A), goldD = C(0xB08A24)
    let maw = C(0x6A1424), mawD = C(0x3A0812), tooth = C(0xF4EEDC), tongue = C(0xE0607A), tongueD = C(0xA83850)
    let eye = C(0xF8D838)
    let s = p.signature ?? -1
    var gape = 0
    var snap = false
    if let a = p.melee {
        gape = Int(max(0, min(6, (-a - 10) / 12)).rounded())
    } else if s > 0.08 && s < 0.9 {
        if s < 0.55 { gape = Int(((s - 0.08) / 0.47 * 7).rounded()) } else if s < 0.74 { gape = 7 } else { snap = true }
    }

    // 1. Clawd's own orange legs out under the chest.
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx + 1, 39, clawdShade); c.px(lx + 1, v5Foot(p, i), clawdShade)
        }
    }

    // 2. The breath, and the jump as it snaps shut.
    c.oy += p.breathe
    if snap && s < 0.8 { c.oy -= 1 }

    // 3. The base of the chest: planks, the far side and bottom in shade, the iron straps, gold corner caps and the
    //    lock plate with its keyhole; its top edge is the lower jaw.
    c.rect(17, 29, 22, 9, wood)
    c.rect(17, 29, 22, 1, woodL); c.rect(17, 30, 1, 7, woodL)
    c.rect(17, 33, 22, 1, woodD); c.rect(37, 30, 2, 8, woodD); c.rect(17, 37, 22, 1, woodD)
    for x in [19, 34] { c.rect(x, 29, 2, 9, iron); c.px(x, 29, ironL); c.px(x, 31, ironL); c.px(x, 35, ironL) }
    c.rect(17, 35, 2, 3, gold); c.rect(37, 35, 2, 3, goldD)
    c.rect(26, 30, 4, 4, gold); c.rect(26, 33, 4, 1, goldD); c.rect(29, 30, 1, 4, goldD)
    c.px(27, 31, ink); c.px(27, 32, ink); c.px(28, 31, ink)

    // 4. The lid, hinged at the back: column by column, raised more towards the front the wider it gapes; the maw
    //    and its teeth in the gap; a row of teeth peeping out of the seam when it's shut.
    func lift(_ x: Int) -> Int { Int((Double(gape) * Double(x - 17) / 21).rounded()) }
    for x in 17...38 {
        let off = lift(x)
        let t0 = (x == 17 || x == 38) ? 24 : (x == 18 || x == 37) ? 23 : 22
        let y0 = t0 - off, y1 = 28 - off
        if off > 0 {
            c.rect(x, y1 + 1, 1, off, x < 21 ? mawD : maw)
            if x % 2 == 1 && x > 19 {
                c.px(x, y1 + 1, tooth)
                if off >= 2 { c.px(x, 28, tooth) }
            }
        }
        let strap = x == 19 || x == 20 || x == 34 || x == 35
        let side = x >= 37
        c.rect(x, y0, 1, y1 - y0 + 1, strap ? iron : side ? woodD : wood)
        c.px(x, y0, strap ? ironL : woodL)
        if !strap { c.px(x, 25 - off, woodD) }
        if !strap && x == 17 { c.rect(x, y0 + 1, 1, y1 - y0, woodL) }
        c.px(x, y1, strap ? iron : woodD)
    }
    if gape == 0 {
        for x in stride(from: 22, through: 36, by: 3) where x != 34 { c.px(x, 29, tooth); c.px(x + 1, 29, tooth) }
    }
    for x in [23, 30] {
        let off = lift(x)
        c.rect(x, 24 - off, 2, 2, eye); c.px(x + 1, 25 - off, ink); c.px(x, 23 - off, woodD); c.px(x + 1, 23 - off, woodD)
    }

    // 5. The tongue: lolling out over the front when the lid's well up, licking round in the signature.
    if gape >= 3 {
        let lick = s > 0.55 && s < 0.74 ? Int((sin(p.lt * 12) * 1.5).rounded()) : 0
        let ty = 29 - gape / 2
        c.rect(34, ty, 5, 2, tongue); c.rect(39, ty + 1 + lick, 2, 3, tongue); c.px(40, ty + 3 + lick, tongueD)
        c.rect(34, ty + 1, 5, 1, tongueD)
    }

    // 6. The snap: lines flying off the front as it slams shut.
    if snap && s < 0.82, Int(p.lt * 12) % 2 == 0 {
        for (x, y) in [(41, 25), (42, 28), (41, 31)] { c.rect(x, y, 2, 1, C(0xFFFFFF, 0.8)) }
    }
}

// MARK: - Eva

/// A sword, its hilt in the hand at `at`, pointing along `angle`: a short dark grip back from the hand, a gold
/// crossguard, a steel blade `len` long, lit along one edge.
private func evaSword(_ c: PixelCanvas, _ at: (x: Double, y: Double), _ angle: Double, len: Double, alpha: Double = 1) {
    let grip = C(0x3A2A4A), guardC = C(0xD8B040), steel = C(0xD8DEE6), steelD = C(0x9098A4)
    crawlBar(c, at, angle + 180, from: 0, to: 2.5, grip.alpha(alpha), r: 0.6)
    let g = crawlReach(at, angle, 0.8)
    crawlBar(c, g, angle + 90, from: -1.8, to: 1.8, guardC.alpha(alpha), r: 0.55)
    crawlBar(c, at, angle, from: 1.5, to: len, steelD.alpha(alpha), r: 0.7)
    crawlBar(c, at, angle, from: 1.5, to: len - 0.5, steel.alpha(alpha), r: 0.4)
}

/// Eva: green and opalescent, Clawd in jade-green scales with a sheen of violet and sky-blue along them, a cobra's
/// flared hood behind her head with pale belly scales down its front, a narrow snake's head with a yellow slit eye and
/// a flicking red tongue, four arms, a plum sash. At rest her twin swords are crossed in an X on her back, their hilts
/// over her shoulders. She fights with both swords at once. Signature: all four arms draw, the two swords and the
/// two knives at her sash, the four blades fanned out round her with a glint.
private func drawEva(_ c: PixelCanvas, _ p: Pose) {
    let scale = C(0x3E9E78), scaleD = C(0x2A7056), scaleL = C(0x6CCAA0)
    let violet = C(0xB49AF0), sky = C(0x8AE0F0)
    let belly = C(0xD8E8B0), bellyD = C(0xA8BC80)
    let sash = C(0x5A2A6A), sashL = C(0x7E4A8E)
    let s = p.signature ?? -1
    let reach = s > 0.08 && s < 0.28
    let drawn = s >= 0.28 && s < 0.9
    let wave = drawn ? sin((s - 0.28) * 18) * 6 : 0

    // 1. The legs: jade scales, lit down the front, a darker scale stroke, the toes in shade.
    drawLegs(c, Look(leg: scale), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = v5Foot(p, i)
            c.rect(lx, 38, 1, bottom - 39, scaleL); c.px(lx + 1, 40, scaleD); c.rect(lx, bottom, 2, 1, scaleD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The twin swords crossed on her back at rest, their hilts up over her shoulders.
    let onBack = p.melee == nil && !drawn
    if onBack {
        evaSword(c, (17, 18), 115, len: 15)
        evaSword(c, (9, 18), 65, len: 15)
    }

    // 4. The far arms, in shade: two of them, empty, or drawing the far sword and knife back behind her.
    if drawn {
        evaSword(c, (13.5, 28.5), -128 + wave, len: 11)
        evaSword(c, (14.5, 33.5), -168 - wave, len: 6)
    }
    c.rect(12, 27, 4, 3, scaleD); c.px(11, 29, scaleD); c.rect(14, 33, 3, 3, scaleD)
    if reach { c.rect(13, 24, 3, 4, scaleD) }

    // 5. The hood behind her head: flared wide, dark at the rim, pale belly scales down its front.
    v5Blob(c, 28, 19, 8, 8.5, scaleD)
    v5Blob(c, 28.5, 19.5, 6.5, 7, scale)
    c.rect(34, 13, 2, 14, belly)
    for y in stride(from: 14, to: 27, by: 2) { c.rect(34, y, 2, 1, bellyD) }
    c.pattern(22, 14, ["LL.", "L..", "L.."], ["L": scaleL])
    c.pattern(23, 18, [".pp..pp.", "p..pp..p", ".pp..pp."], ["p": scaleL])   // the spectacle mark on the hood

    // 6. The body: jade, lit on the top and left with the opal sheen, scale strokes, the pale belly down the front,
    //    the plum sash with a knife hilt at either side.
    drawBody(c, Look(body: scale, shade: scaleD, arm: scale, eye: nil))
    c.rect(19, 26, 12, 1, scaleL); c.rect(18, 27, 1, 9, scaleL)
    c.rect(20, 27, 5, 1, violet); c.rect(18, 29, 1, 3, sky)
    for (x, y) in [(21, 29), (25, 31), (29, 29), (22, 33)] { c.px(x, y, scaleD); c.px(x + 1, y + 1, scaleD) }
    c.rect(32, 27, 5, 8, belly)
    for y in [28, 30, 32, 34] { c.rect(32, y, 5, 1, bellyD) }
    c.rect(18, 35, 20, 2, sash); c.rect(18, 35, 20, 1, sashL)
    if !drawn { c.rect(20, 33, 1, 2, C(0xD8DEE6)); c.rect(35, 33, 1, 2, C(0xD8DEE6)) }

    // 7. The head: a cobra's, narrow, on the front of the hood: the yellow slit eye, the pale jaw, the red tongue.
    c.pattern(30, 7, [
        "..SSSS...",
        ".SLLLSSS.",
        "SSSSyiSSS",
        "SSSSSSSSS",
        ".bbbbbbb.",
    ], ["S": scale, "L": scaleL, "y": C(0xF0D030), "i": ink, "b": belly])
    c.px(33, 8, violet)
    if Int(p.lt * 1.5) % 3 == 0 { c.rect(39, 10, 2, 1, C(0xD83040)); c.px(41, 9, C(0xD83040)); c.px(41, 11, C(0xD83040)) }

    // 8. The near arms: the upper one and the lower one, holding the twin swords in a fight, the sword and the knife
    //    drawn in the signature, reaching back for the hilts as she starts, or resting.
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            evaSword(c, Sprite.hand, ta, len: 13, alpha: 0.3 / Double(i + 1))
        }
        evaSword(c, (40.5, 29.5), a - 40, len: 12)
        c.rect(38, 28, 3, 3, scale); c.px(38, 28, scaleL)
        evaSword(c, Sprite.hand, a, len: 13)
        c.rect(38, 33, 4, 3, scale); c.px(38, 33, scaleL)
    } else if drawn {
        evaSword(c, (40.5, 29.5), -55 - wave, len: 12)
        evaSword(c, Sprite.hand, -12 + wave, len: 7)
        c.rect(38, 28, 3, 3, scale); c.rect(38, 33, 4, 3, scale)
        let glint = s < 0.4
        if glint { for (x, y) in [(47, 19), (50, 33), (5, 18)] { c.px(x, y, white); c.px(x - 1, y, C(0xFFFFFF, 0.5)); c.px(x + 1, y, C(0xFFFFFF, 0.5)) } }
    } else if reach {
        c.rect(36, 23, 3, 4, scale); c.rect(38, 28, 3, 3, scale); c.rect(38, 33, 3, 3, scale)
    } else {
        c.rect(38, 27, 4, 3, scale); c.px(38, 27, scaleL); c.rect(38, 29, 4, 1, scaleD); c.px(42, 28, scaleD)

    }
}

// MARK: - Quan Ch

/// A wing of light from `sh` out to the arc between `a` (the leading tip) and `b`: a faint fill, solid ribs and a lit
/// leading edge, so it stays see-through but its edges read on a dark desktop.
private func quanWing(_ c: PixelCanvas, _ sh: (Double, Double), _ a: (Double, Double), _ b: (Double, Double),
                      rib: Px, edge: Px, fill: Px) {
    let scratch = PixelCanvas(c.w, c.h)
    scratch.ox = 0; scratch.oy = 0
    for k in 0...16 {
        let t = Double(k) / 16
        let tip = (a.0 + (b.0 - a.0) * t - 2 * sin(t * .pi), a.1 + (b.1 - a.1) * t - 2 * sin(t * .pi))
        scratch.glowLine(sh.0, sh.1, tip.0, tip.1, core: fill, glow: C(0, 0), coreR: 0.9, glowR: 1.0)
    }
    c.paste(scratch, alpha: 0.2)
    for t in [0.33, 0.66, 1.0] {
        let tip = (a.0 + (b.0 - a.0) * t - 2 * sin(t * .pi), a.1 + (b.1 - a.1) * t - 2 * sin(t * .pi))
        c.glowLine(sh.0, sh.1, tip.0, tip.1, core: rib, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    }
    c.glowLine(sh.0, sh.1, a.0, a.1, core: edge, glow: C(0, 0), coreR: 0.55, glowR: 0.65)
}

/// Quan Ch: Clawd in a long glowing robe, pale gold, a high collar and sky-blue trim down the front and round the
/// hem, a soft glow round it; black hair in strands swept back off a stern brow. Wings of light behind him, see-through
/// with pale blue ribs, folded up at rest, beating when he flies. His near hand, the left, glows blue: his energy is
/// blue. Signature: the robe lifts him off the ground, the hem billowing, and the wings flare wide.
private func drawQuanCh(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xF0E2B0), robeD = C(0xC8B47A), robeL = C(0xFFF6D8), trim = C(0x4AB4F0)
    let rib = C(0x8AD4FF), edge = C(0xD8F2FF), fill = C(0x9ADCFF)
    let hair = C(0x1E1C24), hairL = C(0x46424E)
    let blue = C(0x3AA0FF), blueL = C(0xD8F0FF)
    let s = p.signature ?? -1
    let flare = v5Arc(s, 0.08, 0.92, edge: 0.22)
    let rise = Int((flare * 4).rounded())
    let casting = p.fire != nil

    // 1. Lifted by the robe in the signature: everything rises.
    c.oy -= rise

    // 2. The legs under the robe, only the toes peeping out under the hem.
    drawLegs(c, Look(), step: p.step)

    // 3. The breath.
    c.oy += p.breathe

    // 4. The wings: folded up behind him, beating in flight, flared wide in the signature.
    let beat = p.flying && Int(p.t * 8) % 2 == 0
    let f = max(flare, p.flying ? 1 : 0)
    let farA = (16 - f * 10, 16 - f * 7 + (beat ? 10 : 0)), farB = (11 - f * 4, 26 - f * 2)
    let nearA = (20 - f * 4, 14 - f * 6 + (beat ? 12 : 0)), nearB = (13 - f * 5, 24 + f * 2)
    quanWing(c, (23, 28), farA, farB, rib: rib.alpha(0.8), edge: rib, fill: fill)
    quanWing(c, (26, 28), nearA, nearB, rib: rib, edge: edge, fill: fill)

    // 5. The glow round the robe, soft and faint.
    v5Blob(c, 28, 33, 14, 11, C(0xFFF2B0, 0.12))

    // 6. The face, Clawd's own orange; below it the long robe to the ground: pale gold, a high collar edged in sky
    //    blue, lit on the left, folds by each leg, the trim down the front and round the hem, which flares and
    //    billows as he lifts.
    drawBody(c, Look(body: clawdOrange, shade: clawdShade, arm: robe, eye: nil))
    let hem = seatedPose ? 39 : 42
    let billow = flare > 0.1 ? Int((sin(p.lt * 9) * 1.2).rounded()) : 0
    c.rect(18, 33, 20, hem - 33, robe)
    c.rect(17, 34, 22, hem - 34, robe)
    c.rect(16 - (flare > 0.1 ? 1 : 0), hem - 2, 24 + (flare > 0.1 ? 2 : 0), 2 + (billow > 0 ? 1 : 0), robe)
    c.rect(17, 34, 1, hem - 34, robeL); c.rect(18, 34, 1, hem - 35, robeL)
    c.rect(38, 34, 1, hem - 34, robeD); c.rect(37, 33, 1, 1, robeD)
    if !seatedPose { for x in [22, 27, 30, 34] { c.rect(x, 36, 1, hem - 37, robeD) } }
    c.rect(16 - (flare > 0.1 ? 1 : 0), hem - 1, 24 + (flare > 0.1 ? 2 : 0), 1, trim)
    c.rect(17, 33, 22, 1, trim); c.rect(16, 32, 3, 1, robe); c.rect(16, 33, 1, 1, trim)   // the high collar
    c.rect(32, 34, 1, hem - 35, trim)

    // 7. The face and the hair: Clawd's eyes under a stern brow, black hair in strands swept back off it and down
    //    the back of his head.
    c.rect(22, 29, 2, 3, ink); c.rect(31, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, hair); c.rect(30, 28, 3, 1, hair)
    c.pattern(16, 21, [
        "......hhhhhhhhhhhh....",
        "...hhhhHHHHHhhhhhhhh..",
        ".hhhhhhhhhhhhHHHHHhhhh",
        "hhhHHHHHhhhhhhhhhhhh..",
        "hhhhhhhhhh............",
        "hhhHHHh...............",
        ".hhhhh................",
        "..hhh.................",
    ], ["h": hair, "H": hairL])

    // 8. The near hand, his left, glowing blue: at his side, or forward and blazing as he casts.
    c.rect(38, 33, 3, 3, robe); c.rect(38, 35, 3, 1, robeD)
    let hx = casting ? 44 : 41, hy = casting ? 31 : 35
    if casting { c.rect(40, 31, 4, 2, robe); c.rect(40, 32, 4, 1, robeD) }
    let pulse = 0.5 + 0.5 * sin(p.lt * 6)
    c.circle(hx, hy, 3, blue.alpha(0.18 + 0.06 * pulse))
    c.circle(hx, hy, 2, blue.alpha(0.24))
    c.rect(hx - 1, hy - 1, 3, 3, blue); c.px(hx, hy, blueL); c.px(hx - 1, hy - 1, blueL)
}
