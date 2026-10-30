import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The First Floor's and Second Floor's bosses: the Hoarder, the Juicer, the Krakaren clone, the Ball of Swine, Ralph.

let crawlVillains2: [CrawlVillain: Persona] = [
    .hoarder: Persona(name: "The Hoarder", weapon: .blaster, shot: .thrown(C(0x7A5230)), muzzle: (46, 30), handGun: false,
                      bulk: 4, headTop: 14, signature: 3.4, draw: drawHoarder),
    .juicer: Persona(name: "The Juicer", weapon: .saber, bulk: 4, headTop: 15, signature: 3.0, draw: drawJuicer),
    .krakaren: Persona(name: "Krakaren clone", weapon: .lightning,
                       magic: Magic(core: C(0xE4FFD0), glow: C(0x4CC23A), jagged: false, waves: true), pivot: (45, 30),
                       bulk: 3, headTop: 16, signature: 2.8, callout: "Let me talk to your manager.", draw: drawKrakaren),
    .ballOfSwine: Persona(name: "Ball of Swine", weapon: .saber, bulk: 4, headTop: 14, signature: 3.6, draw: drawBallOfSwine),
    .ralph: Persona(name: "Ralph", weapon: .saber, headTop: 20, signature: 3.0, draw: drawRalph),
]

// MARK: - Shared shapes

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

/// A tentacle through `pts`, `r0` thick at its root thinning to `r1` at its tip.
private func tentacle(_ c: PixelCanvas, _ pts: [(Double, Double)], r0: Double, r1: Double, _ col: Px) {
    guard pts.count > 1 else { return }
    for i in 0..<(pts.count - 1) {
        let k = Double(i) / Double(pts.count - 1)
        let r = r0 + (r1 - r0) * k
        c.glowLine(pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

// MARK: - The Hoarder

/// The Hoarder: a huge Clawd sunk in a heap of junk in her lair: a great mat of grey-brown hair hanging in clumps over
/// her brow and down past her shoulders, sad heavy brows, a small downturned mouth, a faded grey-lilac T-shirt
/// stretched over her, and pink sweatpants down to her bare feet. Behind her a black bin bag, a split cardboard box
/// and an old broom sticking up out of the pile; in front two pizza boxes with a can on them. She throws Scatterer
/// bugs. Signature: she rummages in the pile
/// behind her, a tin can, an old boot and a teddy bear tossed up out of it and dropping back in.
private func drawHoarder(_ c: PixelCanvas, _ p: Pose) {
    let pants = C(0xEC8CBC), pantsD = C(0xC4668F), pantsL = C(0xFAB6D6)
    let tee = C(0x8E889A), teeD = C(0x6C667A), teeL = C(0xACA6B8)
    let hair = C(0x6E6352), hairD = C(0x4A4136), hairL = C(0x8E8472)
    let box = C(0xB88E58), boxD = C(0x8C6A3C), boxL = C(0xD4AE78)
    let bag = C(0x34343E), bagD = C(0x22222A), bagL = C(0x565664)
    let mouth = C(0x6A2E26), bug = C(0x7A5230), bugD = C(0x4A3018)
    let s = p.signature ?? -1
    let rummage = s > 0.05 && s < 0.95
    let jiggle = rummage && Int(p.lt * 9) % 2 == 0 ? 1 : 0
    let armed = p.fire != nil || p.gunLift > 0

    // 1. Pink sweatpants down each leg, a darker cuff, bare toes.
    drawLegs(c, Look(leg: pants), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, bottom - 39, pantsL)
            c.rect(lx, bottom - 1, 2, 1, pantsD)
            c.rect(lx, bottom, 2, 1, clawdOrange); c.px(lx + 1, bottom, clawdShade)
        }
    }

    // 2. The heap, planted on the ground whatever she does: behind her the black bin bag, tied at the top, the split
    //    cardboard box leaning on it and a broom sticking up out of the back; in front two pizza boxes and a can.
    c.oy -= p.hop
    c.glowLine(3, 21, 9, 34, core: C(0x8A6A4A), glow: C(0, 0), coreR: 0.6, glowR: 0.7)   // a broom handle
    c.pattern(1, 17, ["bbbbb", "bBbBb", "bBbBb", ".rrr."], ["b": C(0xC8A858), "B": C(0x8A7038), "r": C(0xA83A32)])
    blob(c, 9, 36 - Double(jiggle), 7.5, 8, bag)
    blob(c, 11, 39 - Double(jiggle), 5, 5, bagD)
    c.rect(5, 31 - jiggle, 3, 1, bagL); c.rect(4, 32 - jiggle, 1, 3, bagL)   // the shine
    c.pattern(7, 26 - jiggle, ["B.B", ".B.", "BBB"], ["B": bag])             // the knot
    c.rect(10, 35, 9, 9, box); c.rect(10, 35, 1, 9, boxL); c.rect(17, 35, 2, 9, boxD)
    c.pattern(9, 32, ["LL.......", ".LLL...DD", "..LLL.DD."], ["L": boxL, "D": boxD])   // the flaps, open
    c.rect(11, 39, 6, 1, boxD)                                                   // a split
    c.rect(40, 38, 11, 3, box); c.rect(40, 38, 11, 1, boxL); c.rect(40, 40, 11, 1, boxD)
    c.rect(41, 41, 11, 3, box); c.rect(41, 41, 11, 1, boxL); c.rect(41, 43, 11, 1, boxD)
    c.rect(47, 34, 3, 4, C(0xA83A32)); c.rect(47, 34, 3, 1, C(0xD0D4DA)); c.rect(49, 35, 1, 3, C(0x7A2420))
    c.oy += p.hop

    // 3. The breath.
    c.oy += p.breathe

    // 4. Her body, huge: the face and arms Clawd's own orange, the T-shirt stretched over her chest and belly, the
    //    pink waistband of the sweatpants.
    c.rect(16, 23, 24, 10, clawdOrange)
    c.rect(38, 23, 2, 10, clawdShade)
    c.rect(15, 32, 26, 5, tee); c.rect(14, 34, 28, 3, tee)
    c.rect(15, 32, 26, 1, teeL); c.rect(15, 33, 1, 3, teeL); c.rect(38, 33, 4, 4, teeD); c.rect(14, 36, 28, 1, teeD)
    c.rect(25, 32, 6, 1, clawdOrange); c.rect(24, 32, 1, 1, teeD); c.rect(31, 32, 1, 1, teeD)   // the neckline
    c.pattern(20, 34, ["d.......d.....", ".d......dd...."], ["d": teeD])                            // creases
    c.rect(15, 37, 26, 1, pants); c.rect(15, 37, 23, 1, pantsL); c.rect(38, 37, 3, 1, pantsD)

    // 5. The arms: the far one in its sleeve, or plunged back into the bag while she rummages; the near one resting on
    //    her belly, or forward with a bug ready to throw.
    if rummage {
        c.rect(8, 32 + jiggle, 8, 3, clawdOrange); c.rect(8, 34 + jiggle, 8, 1, clawdShade)
        c.rect(13, 31, 3, 3, tee)
    } else {
        c.rect(11, 32, 4, 4, clawdOrange); c.rect(11, 35, 4, 1, clawdShade); c.rect(12, 31, 3, 2, tee)
    }
    if armed {
        let fwd = p.recoil > 0 ? 1 : 0
        c.rect(40, 30, 3, 3, tee); c.rect(40, 32, 3, 1, teeD)
        c.rect(43, 29, 3 + fwd, 3, clawdOrange); c.rect(43, 31, 3 + fwd, 1, clawdShade)
        if p.recoil == 0 { c.rect(45, 27, 2, 2, bug); c.px(46, 27, bugD); c.px(44, 27, bugD); c.px(47, 28, bugD) }
    } else {
        c.rect(40, 31, 3, 2, tee); c.rect(40, 32, 3, 1, teeD)
        c.rect(40, 33, 4, 3, clawdOrange); c.rect(40, 35, 4, 1, clawdShade)
    }

    // 6. The face: sad brows sloping down at the outsides, the eyes, a small downturned mouth.
    c.pattern(20, 27, ["..hh", "hh.."], ["h": hairD])
    c.pattern(32, 27, ["hh..", "..hh"], ["h": hairD])
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(26, 31, 4, 1, mouth); c.px(25, 32, mouth); c.px(30, 32, mouth)
    c.rect(20, 31, 2, 1, C(0xC86A50)); c.rect(34, 31, 2, 1, C(0xC86A50))   // tired cheeks

    // 7. The hair: a great mat of it, clumped, lit along the top, a fringe of clumps over her brow and long hanks down
    //    past her shoulders, the back one longest.
    c.pattern(12, 14, [
        ".......HHlHHHHlHHHHHlHH.......",
        "....HHHHlHHHHHHHHHHlHHHHHH....",
        "..HHHlHHHHhHHHHHlHHHHhHHHHH...",
        ".HHHHHHHHhHHHHHHHHhHHHHhHHHHH.",
        ".HHhHHHHHhHHHHhHHHhHHHHhHHHHH.",
        "HHHhHHHHhHHHHHhHHHHhHHHHhHHHHH",
        "HHHhHHHHhHHHHhHHHHHhHHHHhHHhHH",
        "HHhHHHHhHHHHHhHHHHhHHHHHhHHhHH",
        "HHhHHHHhHHHHhHHHHHhHHHHhHHHhHH",
        "HHhHHHHhHHHHhHHHHhHHHHHhHHHhHH",
        "HHhHHhHHHHhHHHHhHHHHhHHHHhHhHH",
        "HHhHH.HHhH..HHh..HHh..HHhHHhHH",
        "HHhH...Hh....H....H....hH.HhHH",
        "HHhH..........................",
        "HhHH......................HhH.",
        "HHhH......................HhH.",
        "HhHH......................Hh..",
        "HHh.......................H...",
        ".Hh...........................",
        ".hH...........................",
        "..H...........................",
    ], ["H": hair, "h": hairD, "l": hairL])

    // 8. The rummage: things tossed up out of the bag in a high arc and dropping back on the heap.
    if rummage {
        let items: [[String]] = [
            ["LGG", "GGg", "GGg", "GGg"],
            ["BB...", "BB...", "BBBBB", "bbbbb"],
            ["T...T", "TTTTT", "TtTtT", ".TnT.", ".TTT."],
        ]
        let pal: [Character: Px] = ["G": C(0xA8AEB6), "g": C(0x70767E), "L": C(0xE0E4EA), "B": C(0x6A4428),
                                    "b": C(0x3A2414), "T": C(0xC09060), "t": ink, "n": C(0x6A4428)]
        for (i, art) in items.enumerated() {
            let k = (s - 0.12 - Double(i) * 0.24) / 0.36
            guard k > 0, k < 1 else { continue }
            let x = 11 - k * 8, y = 26 - sin(k * .pi) * 18
            c.pattern(Int(x.rounded()), Int(y.rounded()), art, pal)
        }
    }
}

// MARK: - The Juicer

/// The Juicer: a steroid lizard-man, Clawd in green scales pumped up past any sense: a small lizard's head on a neck
/// lost in his trapezius, a spiny ridge on top, a heavy brow over a yellow slit eye, a smug toothy line of a mouth;
/// round shoulders, a slab of a chest, a pale six-pack, arms like hams with blue veins standing out on them, a thick
/// tail, and tiny black shorts. He fights with his fists. Signature: he curls a dumbbell, three reps, the bicep peaking
/// and its veins swelling at the top of each.
private func drawJuicer(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x5C9A3C), hideD = C(0x3E6C28), hideL = C(0x86C25A)
    let belly = C(0xD0D48E), bellyD = C(0xA4A866)
    let vein = C(0x3C6E9A), veinL = C(0x5A92C4)
    let shorts = C(0x1A1A20), shortsL = C(0x3C3C48)
    let claw = C(0x2A2420), eye = C(0xF0D030)
    let iron = C(0x3A3A42), ironL = C(0x6A6A76), bar = C(0xA8ACB4)
    let s = p.signature ?? -1
    let curling = s > 0.08 && s < 0.92
    var lift = 0.0
    if curling { lift = 0.5 - 0.5 * cos((s - 0.08) / 0.84 * 3 * 2 * .pi) }
    let peak = lift > 0.6

    // 1. Green legs, a lit run down the front, dark claws.
    drawLegs(c, Look(leg: hide), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, 3, hideL); c.px(lx + 1, 40, hideD)
            c.px(lx + 2, bottom, claw)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail, thick at the root, down to the ground behind him.
    tentacle(c, [(18, 34), (13, 36), (9, 39), (6, 42)], r0: 2.2, r1: 0.8, hide)
    c.rect(8, 37, 3, 1, hideL); c.px(5, 42, hideD)

    // 4. The torso: Clawd's block swollen into a wedge, the trapezius sloping up to the head, the round shoulders lit
    //    on top.
    c.rect(17, 25, 22, 13, hide)
    c.pattern(15, 21, [
        "..........hhhhhhhhhhhh.....",
        "......hhhhhhhhhhhhhhhhhh...",
        "...hhhhhhhhhhhhhhhhhhhhhhh.",
        ".hhhhhhhhhhhhhhhhhhhhhhhhhh",
    ], ["h": hide])
    blob(c, 16, 28, 4, 4, hide); blob(c, 40, 28, 4, 4, hide)
    c.rect(14, 25, 4, 1, hideL); c.rect(13, 26, 2, 3, hideL); c.rect(19, 23, 9, 1, hideL); c.rect(16, 24, 4, 1, hideL)
    c.rect(38, 25, 4, 1, hideL)
    c.rect(37, 30, 2, 8, hideD); c.rect(17, 37, 22, 1, hideD)

    // 5. The chest: two slabs of pec, lit along the top, a deep shadow under each; the pale six-pack below.
    c.rect(19, 27, 8, 1, hideL); c.rect(29, 27, 8, 1, hideL)
    c.rect(19, 31, 8, 1, hideD); c.rect(29, 31, 8, 1, hideD); c.rect(27, 27, 2, 5, hideD)
    c.rect(23, 32, 10, 3, belly)
    c.rect(27, 32, 1, 3, bellyD); c.rect(23, 33, 10, 1, bellyD); c.px(23, 32, C(0xE8EAB0))

    // 6. Tiny black shorts, a sheen across them.
    c.rect(17, 35, 22, 3, shorts); c.rect(18, 35, 8, 1, shortsL); c.rect(27, 36, 1, 2, shortsL)

    // 7. The head: small, a lizard's, on the front of the traps: the spiny ridge, the heavy brow, the yellow slit eye,
    //    the long snout with its nostril, the smug line of a mouth and its little teeth, the pale jaw.
    c.pattern(26, 14, [
        "..s.s.s.s........",
        ".sSSSSSSSSs......",
        "SSSSSSSSSSSSS....",
        "SSSSSSDDDDSSSSS..",
        "SSSSSSSyyESSSSSS.",
        "SSSSSSSyiESSSSSSn",
        "SSSSSSSSSSSSSSSSS",
        "SSSSSSMMMMMMMMMM.",
        "SSSSSSStStStSt...",
        "BBBBBBBBBBBBB....",
    ], ["S": hide, "s": hideD, "D": hideD, "y": eye, "E": hideD, "i": ink, "n": ink, "M": C(0x2A3A1E),
        "t": C(0xF2EEDC), "B": belly])
    c.rect(28, 15, 8, 1, hideL)

    // 8. The arms: the far one hanging, huge, its fist at its side; the near one a ham of a bicep, veins standing
    //    out, and either punching, curling the dumbbell, or hanging with its fist clenched.
    blob(c, 15, 31, 2.6, 3.4, hide); c.rect(13, 34, 4, 3, hide); c.rect(13, 36, 4, 1, hideD)
    c.pattern(13, 28, ["v..", "v..", ".v.", ".vv", "..v"], ["v": vein])
    func fist(_ x: Int, _ y: Int, _ a: Double) {
        c.rect(x - 1, y - 1, 4, 4, hide.alpha(a)); c.rect(x - 1, y - 1, 4, 1, hideL.alpha(a))
        c.rect(x - 1, y + 2, 4, 1, hideD.alpha(a)); c.px(x + 2, y, hideD.alpha(a))
    }
    // The bicep, fixed to the shoulder.
    blob(c, 41, 30, 3, 3 + (peak ? 0.6 : 0), hide)
    c.rect(40, 27 - (peak ? 1 : 0), 3, 1, hideL)
    c.pattern(38, 28, ["v....", ".vv..", "...vv", "..v..", "..v.."], ["v": peak ? veinL : vein])
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            let e = crawlReach((41, 31), ta, 7)
            fist(Int(e.x.rounded()), Int(e.y.rounded()), 0.35 / Double(i + 1))
        }
        crawlBar(c, (41, 31), a, from: 0, to: 6, hide, r: 1.8)
        let e = crawlReach((41, 31), a, 7)
        fist(Int(e.x.rounded()), Int(e.y.rounded()), 1)
    } else {
        // The forearm from the elbow: hanging down, or curled up towards the shoulder with the dumbbell.
        let ang = 85 - lift * 170
        crawlBar(c, (42, 31), ang, from: 0, to: 5.5, hide, r: 1.5)
        let e = crawlReach((42, 31), ang, 6)
        let fx = Int(e.x.rounded()), fy = Int(e.y.rounded())
        if curling {
            c.rect(fx - 5, fy, 11, 1, bar)
            c.rect(fx - 6, fy - 3, 3, 7, iron); c.rect(fx - 6, fy - 3, 3, 1, ironL)
            c.rect(fx + 4, fy - 3, 3, 7, iron); c.rect(fx + 4, fy - 3, 3, 1, ironL)
        }
        fist(fx - 1, fy - 1, 1)
    }
}

// MARK: - The Krakaren clone

/// The Krakaren clone: Clawd as a deep coral-pink octopus, its round mantle bulging out behind, darker spots on it; legs
/// and arms as tentacles with pale suckers, one trailing on the ground behind, one curled in front. A blonde manager-mom haircut: short and
/// spiky at the back, a long angled fringe swept down over the front. Cross brows, lashes, mascara running down from
/// both eyes in black streaks, pursed red lips. It casts a green mist. Signature: its near tentacle rises and wags at
/// you like a finger.
private func drawKrakaren(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xD8506E), skinD = C(0xA8344E), skinL = C(0xF07C98), sucker = C(0xF8C4D2)
    let hair = C(0xE8C45A), hairD = C(0xB48A30), hairL = C(0xFAE496)
    let mascara = C(0x241A30), lip = C(0xA81830)
    let s = p.signature ?? -1
    let wagging = s > 0.08 && s < 0.92
    let casting = p.zap != nil

    // 1. The legs as tentacles: pink, suckers down the front, the tips curling forward.
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 36, 1, bottom - 37, skinL)
            c.px(lx + 1, 38, sucker); c.px(lx + 1, 40, sucker)
            c.px(lx + 2, bottom, skin); c.px(lx + 2, bottom - 1, skinD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The mantle, a round bulb bulging out behind, lit on its upper left, two darker spots; a tentacle trailing
    //    behind along the ground, its tip curled up.
    tentacle(c, [(19, 35), (14, 38), (10, 41), (6, 41), (5, 38), (7, 37)], r0: 1.8, r1: 0.8, skin)
    for (x, y) in [(13, 40), (9, 42)] { c.px(x, y, sucker) }
    blob(c, 17, 27, 6, 7, skin)
    blob(c, 15, 24.5, 2.5, 1.8, skinL)
    blob(c, 18.5, 31.5, 5, 3, skinD); blob(c, 17, 30, 5.5, 3.5, skin)
    c.rect(13, 28, 2, 1, skinD); c.rect(15, 32, 2, 1, skinD)

    // 4. The body: the pink block, lit on the left, the far side and bottom in shade; filled up under the hair so
    //    nothing shows through.
    c.rect(18, 23, 20, 15, skin)
    c.rect(18, 26, 1, 11, skinL); c.rect(37, 26, 1, 12, skinD); c.rect(18, 37, 20, 1, skinD)
    for (x, y) in [(21, 35), (31, 35)] { c.rect(x, y, 2, 1, skinD) }

    // 5. The face: cross brows sloping in, the eyes with a lash flicked out at each, mascara streaking down from both,
    //    pursed red lips.
    c.pattern(20, 27, ["hh..", "..hh"], ["h": hairD])
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 29, ink); c.px(34, 29, ink)
    c.pattern(22, 32, ["m.", "m.", ".m", ".m", "m."], ["m": mascara])
    c.pattern(32, 32, [".m", ".m", "m.", "m.", ".m"], ["m": mascara])
    c.pattern(26, 33, [".LL.", "LllL", ".LL."], ["L": lip, "l": C(0xD84A60)])

    // 6. The hair: short and spiky at the back, high on top, the long fringe swept down across the front in one
    //    angled sheet; dark lowlights following the sweep, a pale highlight on the crown.
    c.pattern(14, 16, [
        "..l.l..l...................",
        ".lHlHHlHHl.................",
        "lHHHHHHHlllllHHHHH.........",
        ".HhHHHHHHHHHHlllHHHHH......",
        "..HhHHHHHhhHHHHHHHHHHHH....",
        "...HhHHHHHHhhHHHHHhhHHHHH..",
        "....HhHHHHHHHhhHHHHHhhHHHH.",
        "....HHhHHHHHHHHhhHHHHHhhHHH",
        "....HHHHHHHHHHHHHhhHHHHHhHH",
        "....HHH.......HHHHHhhHHHHhH",
        "....HH..........HHHHHhhHHhH",
        "..................HHHHHHhhH",
        ".....................HHHHhH",
        "......................HHHhH",
        "........................HH.",
    ], ["H": hair, "h": hairD, "l": hairL])

    // 7. The near tentacle: curled at rest; out in front, its tip raised, while it casts; up beside its head and
    //    wagging at you during the signature.
    var pts: [(Double, Double)]
    if wagging {
        let wag = sin(p.lt * 14) * 2.2
        pts = [(38, 33), (42, 31), (44, 26), (44 + wag * 0.5, 21), (44 + wag, 17), (43 + wag * 1.2, 16)]
    } else if casting {
        let tip = 30 - Double(p.armRaise)
        pts = [(38, 34), (41, 34), (43, 32), (45, tip)]
    } else {
        pts = [(38, 34), (42, 37), (45, 41), (48, 41), (49, 38), (47, 37)]
    }
    tentacle(c, pts, r0: 1.7, r1: 0.8, skin)
    for k in 1..<(pts.count - 2) { c.px(Int(pts[k].0 - 0.5), Int(pts[k].1 + 1), sucker) }
}

// MARK: - Ball of Swine

/// Ball of Swine: a big rolling ball of pale pink warthog aristocrats clinging together, each a tusked face over a
/// black tuxedo front, white shirt and bow tie; the front one in a gold monocle; a curly tail sticking out at the back.
/// Under the ball Clawd's four legs peek out in tuxedo trousers, pink trotters on the ground. He crushes, rolling into
/// you. Signature: the ball bursts apart into little Tusklings that scatter, hop about, and roll back together.
private func drawBallOfSwine(_ c: PixelCanvas, _ p: Pose) {
    let pig = C(0xF4BCAC), pigD = C(0xD49284), pigL = C(0xFFDCD0), snout = C(0xE08A82), nostril = C(0x6A2E2E)
    let tux = C(0x24242C), tuxL = C(0x46465A), shirt = C(0xF4F2EE), tusk = C(0xF6EEDA), gold = C(0xE8C040)
    let s = p.signature ?? -1

    // The signature's beats: up to 0.12 the ball quivers; to 0.3 it bursts, the Tusklings flying out and the ball
    // shrinking to its core; to 0.7 they hop about; to 0.92 they roll back in and it grows again.
    var burst = 0.0   // 0 the whole ball, 1 burst to its core
    if s > 0.12 && s < 0.3 { burst = (s - 0.12) / 0.18 } else if s >= 0.3 && s < 0.7 { burst = 1 } else if s >= 0.7 && s < 0.92 { burst = 1 - (s - 0.7) / 0.22 }
    let quiver = s > 0 && s < 0.12 ? (Int(p.lt * 20) % 2 == 0 ? 0.6 : -0.6) : 0

    // 1. The legs under the ball: black tuxedo trousers, pink trotters with a split hoof.
    drawLegs(c, Look(leg: tux), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 39, 1, bottom - 40, tuxL)
            c.rect(lx, bottom - 1, 2, 2, pigD); c.px(lx, bottom - 1, pig); c.px(lx + 1, bottom, nostril)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The roll: rolling along when it walks, into you when it crushes.
    var roll = p.walking ? p.t * 260 : 0
    var push = 0.0
    if let a = p.melee {
        roll += a * 1.5
        push = max(0, cos(a * .pi / 180)) * 4
    }
    let r = 12 - burst * 5.5 + quiver
    let cx = 28 + push, cy = 38 - r

    // 4. The ball: pale pink, lit along its upper left, shaded along its lower right.
    let x0 = Int(floor(cx - r)), x1 = Int(ceil(cx + r)), y0 = Int(floor(cy - r)), y1 = Int(ceil(cy + r))
    for y in y0...y1 {
        for x in x0...x1 {
            let nx = (Double(x) + 0.5 - cx) / r, ny = (Double(y) + 0.5 - cy) / r
            let d = (nx * nx + ny * ny).squareRoot()
            guard d <= 1 else { continue }
            let light = -(nx * 0.6 + ny * 0.8)
            var col = pig
            if d > 1 - 2 / r && light > 0.3 { col = pigL } else if d > 1 - 2.5 / r && light < -0.25 { col = pigD }
            c.px(x, y, col)
        }
    }

    // 5. The curly tail at the back of the ball.
    let ta = (200 + roll) * .pi / 180
    let tx = Int((cx + cos(ta) * (r + 0.5)).rounded()), ty = Int((cy + sin(ta) * (r + 0.5)).rounded())
    c.pattern(tx - 2, ty - 2, [".pp.", "p..p", "..pp", ".p.."], ["p": pigD])

    // 6. The aristocrats: tusked faces over tuxedo fronts, set round the ball and turning with it (just the monocled
    //    one at its core when it's burst).
    func aristocrat(_ ux: Int, _ uy: Int, monocle: Bool) {
        c.pattern(ux - 4, uy - 5, [
            ".D.....D.",
            ".........",
            "..k...k..",
            "T..SSS..T",
            "T.SnSnS.T",
            ".T.SSS.T.",
            ".........",
            "BLWbbbWLB",
            "BBLWWWLBB",
            ".BBLWLBB.",
        ], ["D": pigD, "k": ink, "T": tusk, "S": snout, "n": nostril, "B": tux, "L": tuxL, "W": shirt, "b": ink])
        if monocle { c.pattern(ux + 1, uy - 4, ["ggg", "g.g", "ggg"], ["g": gold]); c.px(ux + 3, uy, gold) }
    }
    if burst > 0.5 {
        aristocrat(Int(cx.rounded()), Int(cy.rounded()) + 1, monocle: true)
    } else {
        for (i, base) in [-90.0, 30, 150].enumerated() {
            let a = (base + roll) * .pi / 180
            let ux = Int((cx + cos(a) * 6).rounded()), uy = Int((cy + sin(a) * 6.4).rounded())
            aristocrat(ux, uy, monocle: i == 1)
        }
    }

    // 7. The crush: speed lines streaming off the back of the ball.
    if p.melee != nil, !p.trail.isEmpty {
        for (i, dy) in [-6, 0, 6].enumerated() {
            let y = Int(cy.rounded()) + dy, x = Int((cx - r).rounded()) - 3 - i % 2
            c.rect(x - 4, y, 4, 1, C(0xFFFFFF, 0.5))
        }
    }

    // 8. The Tusklings: little tuxedoed warthogs, flying out from the ball, hopping where they land, rolling back.
    if s > 0.12 && s < 0.92 {
        let targets: [(Double, Double)] = [(-18, 11), (-12, -9), (14, -13), (20, 9), (3, -17)]
        let out = s < 0.3 ? (s - 0.12) / 0.18 : s < 0.7 ? 1 : 1 - (s - 0.7) / 0.22
        for (i, t) in targets.enumerated() {
            let hop = s >= 0.3 && s < 0.7 && Int(p.lt * 6 + Double(i)) % 2 == 0 ? 1.0 : 0
            let x = 28 + t.0 * out, y = 26 + t.1 * out - sin(out * .pi) * 4 - hop
            let left = t.0 < 0
            let art = left
                ? [".DD....", "kPPBBB.", "SPPWBBB", ".TPBBB.", "..P..P."]
                : ["....DD.", ".BBBPPk", "BBBWPPS", ".BBBPT.", ".P..P.."]
            c.pattern(Int(x.rounded()) - 3, Int(y.rounded()) - 2, art,
                      ["D": pigD, "P": pig, "k": ink, "S": snout, "B": tux, "W": shirt, "T": tusk])
        }
    }
}

// MARK: - Ralph

/// Ralph: an absurdly cute gerbil, Clawd in golden-sand fur: big round ears with pink insides, huge glossy black eyes
/// with two glints each, pink cheeks, a tiny pink nose, two little buck teeth, a cream belly, tiny paws held up at its
/// chest and a long thin tail with a dark tuft. It fights with its scream. Signature: its mouth opens, and keeps
/// opening, until it is wider than its whole body, a dark maw ringed with tiny teeth, the big cute eyes still on top;
/// then it snaps shut.
private func drawRalph(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xD8A868), furD = C(0xB07E46), furL = C(0xF0CC90), cream = C(0xFAEEDA), creamD = C(0xE6D2B4)
    let pink = C(0xF4A0B0), pinkD = C(0xD87890), nose = C(0xE8708A)
    let maw = C(0x4A0A18), throat = C(0x2A0410), tongue = C(0xD85A70), tooth = C(0xFFFFFF)
    let s = p.signature ?? -1
    var open = 0.0
    if s > 0.12 && s < 0.32 { open = (s - 0.12) / 0.2 } else if s >= 0.32 && s < 0.8 { open = 1 } else if s >= 0.8 && s < 0.86 { open = 1 - (s - 0.8) / 0.06 }
    let gaping = open > 0.05

    // 1. The legs in fur, pink toes.
    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, 3, furL)
            c.rect(lx, bottom, 2, 1, pink); c.px(lx + 1, bottom, pinkD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail: long and thin, curving up behind, a dark tuft at its tip.
    tentacle(c, [(18, 35), (12, 37), (8, 35), (6, 31), (6, 28)], r0: 0.9, r1: 0.6, furD)
    c.rect(5, 26, 2, 3, C(0x6A4A2A))

    // 4. The body: golden fur, its top corners rounded, lit on top and on the left, the far side in shade; the cream
    //    belly. While it gapes, the top of its head is pushed up above the maw.
    let headY = 26 - Int((open * 12).rounded())
    c.rect(19, headY, 18, 1, fur); c.rect(18, headY + 1, 20, 37 - headY, fur)
    c.rect(19, headY, 18, 1, furL); c.rect(18, headY + 1, 1, 36 - headY, furL)
    c.rect(37, headY + 1, 1, 36 - headY, furD); c.rect(18, 37, 20, 1, furD)
    blob(c, 28, 35, 7, 3.5, cream)
    c.rect(24, 37, 8, 1, creamD)

    // 5. The ears: big and round, pink inside.
    for ex in [21.5, 34.5] {
        blob(c, ex, Double(headY) - 2, 3.2, 3.4, fur)
        blob(c, ex, Double(headY) - 1.6, 1.8, 2.2, pink)
        c.px(Int(ex) - 2, headY - 4, furL)
    }

    // 6. The face: huge glossy eyes, two glints each; pink cheeks; and below them either the tiny nose, mouth and buck
    //    teeth, the scream, or the maw.
    let ey = headY + 2
    for x in [21, 31] {
        c.rect(x, ey, 4, 4, ink); c.rect(x + 1, ey - 1, 2, 1, ink); c.rect(x + 1, ey + 4, 2, 1, ink)
        c.rect(x + 1, ey, 1, 1, tooth); c.px(x + 2, ey + 2, C(0xC8D8F0))
    }
    if gaping {
        let mcx = 28.0, mcy = 31.0
        let rx = 3 + open * 15, ry = 2 + open * 5.5
        blob(c, mcx, mcy, rx + 2, ry + 2, fur)
        blob(c, mcx, mcy + 1, rx + 2, ry + 1.2, furD)
        blob(c, mcx, mcy, rx, ry, maw)
        blob(c, mcx, mcy + 0.5, rx * 0.5, ry * 0.5, throat)
        blob(c, mcx, mcy + ry * 0.6, rx * 0.4, ry * 0.3, tongue)
        // Tiny teeth all along the top and bottom of the maw.
        for x in stride(from: Int(mcx - rx) + 1, through: Int(mcx + rx) - 1, by: 2) {
            let u = (Double(x) + 0.5 - mcx) / rx
            guard abs(u) < 0.92 else { continue }
            let h = ry * (1 - u * u).squareRoot()
            c.px(x, Int((mcy - h).rounded()), tooth)
            c.px(x, Int((mcy + h).rounded()) - 1, tooth)
        }
        c.rect(19, ey + 5, 2, 1, pink); c.rect(35, ey + 5, 2, 1, pink)
    } else if let a = p.melee {
        c.rect(19, 32, 2, 1, pink); c.rect(35, 32, 2, 1, pink)
        c.rect(27, 30, 2, 1, nose)
        c.rect(26, 32, 4, 3, maw); c.rect(27, 32, 2, 1, tooth); c.rect(27, 34, 2, 1, tongue)
        // The scream: arcs pulsing out along the swing, fainter for the trail.
        func arcs(_ ang: Double, _ alpha: Double) {
            let from = crawlReach((39, 32), ang, 1)
            for (j, rad) in [2.0, 4.5, 7.0].enumerated() {
                let rr = rad + frac(p.lt * 3) * 2
                for th in stride(from: -40.0, through: 40, by: 10) {
                    let e = crawlReach(from, ang + th, rr)
                    c.px(Int(e.x.rounded()), Int(e.y.rounded()), C(0xFFF2D0, alpha * (0.9 - Double(j) * 0.2)))
                }
            }
        }
        for (i, ta) in p.trail.enumerated() { arcs(ta, 0.3 / Double(i + 1)) }
        arcs(a, 1)
    } else {
        c.rect(19, 32, 2, 1, pink); c.rect(35, 32, 2, 1, pink)
        c.rect(27, 30, 2, 1, nose)
        c.pattern(25, 31, ["m.mm.m", ".m..m."], ["m": furD])
        c.rect(27, 32, 2, 2, tooth); c.px(27, 33, creamD)
    }

    // 7. The paws: tiny, held up at its chest.
    if !gaping {
        c.rect(15, 32, 3, 2, fur); c.rect(15, 33, 3, 1, pink)
        c.rect(38, 32, 3, 2, fur); c.rect(38, 33, 3, 1, pink)
    }
}
