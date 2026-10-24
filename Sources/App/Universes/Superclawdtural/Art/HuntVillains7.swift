import Foundation

// Villains: the last of the monsters of the week, and the agent-only small fry. Drawn the same way as the heroes
// (HuntHeroes1.swift); the Hookman, the Shapeshifter, the Djinn, the Clown and the Scarecrow are Clawd in costume: a
// preacher's ghost with a hook for a hand, a lookalike with silver eyeshine and a cheek starting to peel, a bald man
// covered in blue tattoos, a clown in a rainbow wig (never purple: he is not a Joker) and a burlap-headed god on his
// post with a scythe. The hellhound, the Leviathan blob and the demon smoke are creatures, with their own shapes: a
// shadow dog prowling low, a grinning lump of black goo and a twisting wisp of smoke with red in it.
//
// Magic (`weapon: .lightning`): `magic:` says how the stream looks, and the engine draws it from `pivot` (the casting
// hand, raised `p.armRaise` pixels: draw the arm raised as much). Don't set `magic.variant` yourself: the engine
// numbers every magic user in order through all the universes, so no two anywhere look exactly alike.

let huntVillains7: [HuntVillain: Persona] = [
    .hookman: Persona(name: "The Hookman", weapon: .saber, headTop: 19, signature: 3.4, draw: drawHookman),
    .shapeshifter: Persona(name: "The Shapeshifter", weapon: .saber, headTop: 22, signature: 3.0,
                           draw: drawShapeshifter),
    .djinn: Persona(name: "The Djinn", weapon: .lightning,
                    magic: Magic(core: C(0xE6FAFF), glow: C(0x1E96FF), jagged: false, touch: true),
                    headTop: 26, signature: 3.2, draw: drawDjinn),
    .clown: Persona(name: "The Clown", weapon: .saber, headTop: 20, signature: 3.0, draw: drawClown),
    .scarecrow: Persona(name: "The Scarecrow", weapon: .saber, headTop: 17, signature: 3.8, draw: drawScarecrow),
    .hellhound: Persona(name: "Hellhound", canSit: false, headTop: 23, fidgets: false, draw: drawHellhound),
    .leviathanBlob: Persona(name: "Leviathan Blob", canSit: false, headTop: 28, fidgets: false,
                            draw: drawLeviathanBlob),
    .demonSmoke: Persona(name: "Demon Smoke", motion: .hover, canSit: false, headTop: 19, fidgets: false,
                         draw: drawDemonSmoke),
]

// MARK: - The Hookman

/// The Hookman: the ghost of a preacher from the 1860s, in a long dark frock coat with its tails behind, a buttoned
/// waistcoat, a white collar with the two preacher's bands hanging from it, a flat black hat with a wide brim and
/// long straggly white hair under it. Where his right hand was there's a silver hook. Signature: he lowers the hook
/// to the ground and scrapes it slowly forward, sparks spitting off the point and a bright scratch left behind.
private func drawHookman(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2C313C), coatD = C(0x181B22), coatL = C(0x4C5466)
    let vest = C(0x3C3833), vestD = C(0x28251F), shirt = C(0xE6E4DE), bands = C(0xFAFAF6)
    let hat = C(0x17171B), hatL = C(0x36363E), hatBand = C(0x2C2C32)
    let hair = C(0xC6CACE), hairD = C(0x8C9298)
    let steel = C(0xB8BEC8), steelL = C(0xEEF2F6), steelD = C(0x6E7480)
    let s = p.signature ?? -1
    // The scrape: down to the ground, dragged forward, lifted back.
    let scraping = s > 0.06 && s < 0.94
    let drag = s < 0.2 ? 0 : s < 0.8 ? (s - 0.2) / 0.6 : 1
    let tipX = 45 + Int((drag * 9).rounded())

    // Grey trousers, lit down the front, and old black shoes with a dull shine on the toe: a shade apart from
    // the dark coat, so all four legs show under it.
    drawLegs(c, Look(leg: C(0x5C5E6A)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lift = p.step >= 0 && i % 2 == p.step ? 1 : 0
            c.rect(lx, 39 - lift, 1, 3, C(0x7A7C88))
        }
    }
    drawBoots(c, C(0x101012), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx + 1, p.step >= 0 && i % 2 == p.step ? 42 : 43, C(0x3A3A44))
        }
    }

    c.oy += p.breathe
    // The frock coat's skirts to just above the knee, the tails at the back hanging lower, a fold over each leg.
    if seatedPose {
        c.rect(16, 38, 23, 1, coat); c.px(16, 38, coatL)
    } else {
        c.rect(17, 38, 22, 1, coat); c.rect(17, 39, 22, 1, coatD)
        c.rect(16, 38, 3, 4, coat); c.rect(16, 38, 1, 4, coatL); c.rect(16, 41, 3, 1, coatD)
        for x in [21, 25, 33] { c.px(x, 38, coatD) }
        c.rect(29, 38, 1, 2, C(0x101318)); c.rect(38, 38, 1, 2, coatD)
    }
    drawBody(c, Look(arm: coat), armRight: scraping ? -2 : 0)

    // The coat over the waistcoat: lapels lit along their edge, the waistcoat's buttons, the white collar and the two
    // bands at his throat, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 5, vest); c.rect(31, 33, 1, 5, vestD); c.rect(24, 37, 8, 1, vestD)
    for y in [34, 36] { c.px(28, y, C(0x8A8070)) }
    c.rect(25, 33, 6, 1, shirt)
    c.rect(26, 34, 2, 2, bands); c.rect(29, 34, 2, 2, bands); c.px(27, 35, C(0xC8C8C2)); c.px(30, 35, C(0xC8C8C2))
    c.rect(23, 33, 1, 5, coatL); c.rect(22, 34, 1, 3, coatL); c.rect(32, 33, 1, 5, coatD); c.rect(33, 34, 1, 2, coatD)
    c.rect(19, 33, 3, 1, coatL); c.rect(34, 33, 3, 1, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD); c.px(20, 36, coatD)
    c.rect(15, 35, 3, 1, coatD)

    // Long white hair, thin and straggly, hanging from under the brim past his ears.
    c.pattern(17, 26, [
        "HH.................HH",
        "Hh..................H",
        "HH..................h",
        "hH..................H",
        ".h...................",
    ], ["H": hair, "h": hairD])
    // The hat: a low flat crown with its band, and a broad flat brim, lit along the top and the left.
    c.rect(22, 20, 13, 5, hat); c.rect(22, 20, 13, 1, hatL); c.rect(22, 20, 1, 5, hatL)
    c.rect(22, 23, 13, 1, hatBand); c.rect(34, 21, 1, 2, C(0x0C0C0E))
    c.rect(15, 25, 26, 1, hat); c.rect(15, 25, 11, 1, hatL); c.px(41, 25, C(0x0C0C0E))
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)   // pale brows

    if scraping {
        // The arm down, the hook's shaft reaching to the ground ahead and its curve dragging along it.
        let ground = s < 0.2 ? Int(((s - 0.06) / 0.14 * 6).rounded()) : s > 0.8 ? Int(((0.94 - s) / 0.14 * 6).rounded()) : 6
        let footY = 37 + ground
        huntLine(c, 41, 37, Double(tipX - 1), Double(footY - 2), steel, 0.6)
        c.px(tipX - 1, footY - 1, steel); c.px(tipX, footY, steelD); c.px(tipX + 1, footY, steel)
        c.px(tipX + 2, footY - 1, steel); c.px(tipX + 2, footY - 2, steelL)
        c.rect(40, 36, 2, 1, steelD)
        if ground == 6 && s > 0.2 && s < 0.82 {
            // Sparks off the point, thrown up and back; the scratch glinting on the ground behind it.
            for k in 0..<5 {
                let n = noise(Int(p.t * 24) * 5 + k)
                let sx = tipX - 1 - Int(n * 5), sy = 42 - Int(noise(Int(p.t * 24) * 7 + k) * 4)
                c.px(sx, sy, (k % 2 == 0 ? C(0xFFE27A) : C(0xFF9A3A)).alpha(0.85))
            }
            if tipX > 47 { c.rect(45, 44, tipX - 47, 1, C(0xE8ECF2, 0.55)) }
        } else if s >= 0.8 && tipX > 47 {
            c.rect(45, 44, tipX - 47, 1, C(0xE8ECF2, 0.55 * max(0, (0.94 - s) / 0.14)))
        }
        return
    }

    if let a = p.melee {
        // The hook swung: a short shaft out of the cuff, curving round to its point.
        let h = huntHand
        huntSmear(c, h, p.trail, from: 2, to: 7, C(0xF0F4FF))
        huntBar(c, h, a, from: -0.5, to: 6, steel, r: 0.8)
        let end = huntReach(h, a, 6), centre = huntReach(end, a - 90, 2.6)
        for k in 0...16 {
            let q = huntReach(centre, a + 90 - Double(k) * 15, 2.6)
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), k >= 14 ? steelL : steel)
        }
        c.rect(38, 33, 3, 3, coat); c.rect(40, 33, 1, 3, coatD)
    } else {
        // The hook at rest, hanging from his cuff and curling forward to its point.
        c.pattern(41, 34, [
            "dd....",
            ".L....",
            ".S....",
            ".S...L",
            ".S...S",
            "..SSS.",
        ], ["S": steel, "L": steelL, "d": steelD])
        c.px(42, 39, steelD)
    }
}

// MARK: - The Shapeshifter

/// The Shapeshifter: whoever he last copied, in their borrowed clothes, but never quite right: a worn olive canvas
/// jacket over a black tee, jeans and boots, lank mousy hair, his eyes catching the light with a silver glint, and a
/// flap of skin starting to peel off one cheek like a costume coming loose. Fights with a butcher's knife. Signature:
/// his eyes flash silver twice, the way a shifter's do on a security camera, then go back to normal.
private func drawShapeshifter(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x535A3A), jacketD = C(0x363C24), jacketL = C(0x737C52), tee = C(0x222226), teeL = C(0x34343A)
    let hair = C(0x6A5C48), hairD = C(0x483E30), hairL = C(0x8C7C64)
    let silver = C(0xEEF4FA), silverD = C(0xA4AEBC)
    let peel = C(0xF2BE9E), peelD = C(0xC48466)
    let s = p.signature ?? -1
    let mirror = s > 0.16 && s < 0.86
    func flash(_ at: Double) -> Double { max(0, 1 - abs(s - at) / 0.12) }
    let glint = max(flash(0.3), flash(0.62))

    drawLegs(c, Look(leg: C(0x445A7C)), step: p.step)
    if !seatedPose {
        for (i, lx) in [20, 24, 32, 36].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 37 : 38, 1, 2, C(0x5C7296))
        }
    }
    drawBoots(c, C(0x30261C), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: nil))

    // The canvas jacket open on the black tee: a collar turned up and lit, a chest pocket with its flap, a fold, a
    // frayed cuff, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, tee); c.rect(26, 33, 4, 1, clawdShade); c.rect(25, 34, 1, 3, teeL)
    c.rect(24, 33, 1, 5, jacketL); c.rect(23, 33, 1, 2, jacketL); c.rect(31, 33, 1, 5, jacketD); c.rect(32, 33, 1, 2, jacketL)
    c.rect(19, 33, 3, 1, jacketL); c.rect(34, 33, 3, 1, jacketL)
    c.rect(33, 35, 3, 1, jacketD); c.rect(33, 36, 3, 1, C(0x646C46)); c.px(34, 35, C(0x9A9A80))
    c.rect(20, 35, 1, 2, jacketD)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(15, 35, 3, 1, jacketD)

    // Lank hair, flat on top and hanging in a ragged fringe, as if it had been put on in a hurry.
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH.....",
        "..HHHlHHHHlHHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHH..",
        ".HHhHHHHhHHHHHhHHHHHH.",
        ".HHH.h.H..h..H..hHHHH.",
        ".HH................HH.",
        ".Hh.................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The peeling flap on his far cheek, curling out past his face, its pale underside showing.
    c.rect(34, 31, 3, 2, C(0xE49686)); c.px(34, 32, C(0xC87466))   // the paler skin underneath
    c.pattern(35, 28, [
        "...l",
        "..lp",
        ".lpd",
        "lpd.",
    ], ["p": peel, "l": C(0xFFE4CE), "d": peelD])

    // The eyes: dark with a silver glint, or, while the camera catches him, all silver.
    for ex in [22, 32] {
        if mirror {
            // Eyeshine: the whole eye a flat bright silver, wide open in a dark rim, like a lens catching the light.
            c.rect(ex - 1, 28, 4, 5, ink)
            c.rect(ex, 29, 2, 3, silver); c.px(ex + 1, 31, silverD); c.px(ex, 29, C(0xFFFFFF))
        } else {
            // Dark, but a silver catchlight two pixels tall that gives him away.
            c.rect(ex, 29, 2, 3, ink); c.rect(ex, 29, 1, 2, C(0xD4DEEA))
        }
    }
    if glint > 0 {
        // The flash: a four-pointed star off each eye, see-through like a reflection.
        for (ex, ey) in [(22.5, 30.0), (32.5, 30.0)] {
            for r in 1...5 {
                let a = glint * (r <= 2 ? 0.95 : r == 3 ? 0.75 : r == 4 ? 0.5 : 0.3)
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                    c.px(Int(ex + Double(dx * r) + (dx > 0 ? 0.5 : -0.5)), Int(ey) + dy * r, C(0xFFFFFF, a))
                }
            }
            for (dx, dy) in [(1, 1), (-1, 1), (1, -1), (-1, -1)] {
                c.px(Int(ex + Double(dx) * 1.5 + 0.5 * Double(dx)), Int(ey) + dy * 2, C(0xDDE8FF, glint * 0.7))
                c.px(Int(ex + Double(dx) * 2.5 + 0.5 * Double(dx)), Int(ey) + dy * 3, C(0xDDE8FF, glint * 0.35))
            }
            for dy in -2...2 { for dx in -2...3 { c.px(Int(ex) + dx, Int(ey) + dy, C(0xFFFFFF, glint * 0.18)) } }
        }
    }

    // The butcher's knife: only out when he fights, a wide blade with a bright edge.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x221A14), steel: C(0xA8AEB8), edge: C(0xE8ECF2), length: 7)
        huntBar(c, huntHand, a, from: 3, to: 7, C(0xA8AEB8), r: 1.3)
        huntBar(c, huntHand, a, from: 3, to: 7.5, C(0xE8ECF2), r: 0.4)
    }
}

// MARK: - The Djinn

/// The Djinn: a bald man covered in tattoos, dark blue swirls and lines of script over his scalp, curling down round
/// his eyes and across his chin, down his chest and in bands round his bare arms; a dark sleeveless shirt open in a
/// deep V, a sash, dark trousers and soft boots. His touch is a bright blue glow, and his tattoos light up blue
/// whenever he uses it. Signature: a ripple of blue light runs through his tattoos from back to front, twice.
private func drawDjinn(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0x262B3E), shirtD = C(0x161926), shirtL = C(0x3E4662), sash = C(0x2A3A6A), sashL = C(0x42569A)
    let tat = C(0x2C4A7E), lit = C(0x4CC4FF), hot = C(0xD2F6FF)
    let s = p.signature ?? -1
    let casting = p.zap != nil || p.armRaise > 0
    // The ripple: a band of light sweeping from back to front, twice.
    let wave: Double? = s > 0.06 && s < 0.5 ? 10 + (s - 0.06) / 0.44 * 38 : s >= 0.5 && s < 0.94 ? 10 + (s - 0.5) / 0.44 * 38 : nil
    func tattoo(_ x: Int, _ y: Int) -> Px {
        if casting { return (x + y + Int(p.t * 8)) % 5 == 0 ? hot : lit }
        guard let w = wave else { return tat }
        let d = abs(Double(x) + Double(y - 30) * 0.4 - w)
        return d < 1.2 ? hot : d < 3.5 ? lit : tat
    }

    // Dark trousers lit down the front, soft dark boots.
    drawLegs(c, Look(leg: C(0x2E2C36)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 37 : 38, 1, 3, C(0x46445A))
        }
    }
    drawBoots(c, C(0x16141A), step: p.step, rows: 2)

    c.oy += p.breathe
    let raise = casting ? p.armRaise : 0
    drawBody(c, Look(), armRight: raise)

    // The shirt, sleeveless, open in a deep V on his tattooed chest: its edges lit, a fold, the sash at the waist
    // with its knot and a hanging end, the far side in shade.
    c.pattern(18, 33, [
        "LSSSSSLL......LSSSSD",
        "LSSSSSSL......SSSSSD",
        "LSSSSSSSL....SSSSSSD",
        "LSSSSSSSSL..SSSSSSSD",
    ], ["S": shirt, "L": shirtL, "D": shirtD])
    c.rect(21, 34, 1, 3, shirtD); c.rect(34, 34, 1, 3, shirtD)   // folds
    c.rect(18, 37, 20, 1, sash); c.rect(18, 37, 6, 1, sashL); c.rect(26, 37, 2, 2, sashL); c.px(27, 39, sash)
    c.rect(15, 35, 3, 1, clawdShade)

    // The tattoos, in strokes, kept off his face: swirls over the scalp, a line down the edge of each cheek curling
    // in under the jaw, a small mark on the chin, a pattern down the V of his chest, and a band round each arm.
    let face = [
        "..TT..TTTTTTTT..TT..",
        ".T..T.T......T.T..T.",
        "T.T..............T.T",
        "T..................T",
        ".T................T.",
        ".T................T.",
        "..TT.....TT.....TT..",
        "........T..T........",
        ".........TT.........",
    ]
    for (dy, row) in face.enumerated() {
        for (dx, ch) in row.enumerated() where ch == "T" { c.px(18 + dx, 26 + dy, tattoo(18 + dx, 26 + dy)) }
    }
    c.px(28, 36, tattoo(28, 36)); c.px(27, 35, tattoo(27, 35)); c.px(28, 35, tattoo(28, 35))
    // The bald scalp's shine, top left.
    c.rect(20, 27, 2, 1, C(0xF09878)); c.px(19, 28, C(0xF09878))
    for x in 15...17 { c.px(x, 34, tattoo(x, 34)) }
    for x in 38...40 { c.px(x, 34 - raise, tattoo(x, 34 - raise)) }
    c.px(16, 33, tattoo(16, 33)); c.px(39, 33 - raise, tattoo(39, 33 - raise))

    // His eyes glow blue while he works.
    if casting || (wave.map { $0 > 20 && $0 < 36 } ?? false) {
        for ex in [22, 32] { c.rect(ex, 29, 2, 3, hot); c.px(ex + 1, 31, lit) }   // white-hot, apart from the tattoos
    }
}

// MARK: - The Clown

/// The Clown, a rakshasa that hides as a children's-party clown: a big round wig in rainbow bands, red outermost and
/// blue against his face, white greasepaint above his eyes and round a wide red smile, a round red nose, a white
/// ruff, a baggy yellow suit with red, blue and green polka dots and pom-pom buttons, white gloves and long red shoes.
/// Fights with the rakshasa's claws, which slide out of his glove. Signature: he squeezes his nose, twice: honk, honk.
private func drawClown(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xE6C23A), suitD = C(0xB8942A), suitL = C(0xF6DC6E)
    let red = C(0xD8282C), redD = C(0x9A1A1E), blue = C(0x2A5AC8), green = C(0x2E9A4A)
    let paint = C(0xF8F6F0), paintD = C(0xD8D4CC), glove = C(0xFAFAF6), gloveD = C(0xCCCAC4)
    let shoe = C(0xC8282A), shoeL = C(0xE8504A)
    let s = p.signature ?? -1
    let honking = s > 0.08 && s < 0.92
    let squeeze = honking && ((s > 0.3 && s < 0.42) || (s > 0.6 && s < 0.72))
    let boing = squeeze ? -1 : 0

    // Baggy yellow trousers with a dot or two, and the long red shoes, their toes poking out in front.
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lift = p.step >= 0 && i % 2 == p.step ? -1 : 0
            c.rect(lx + 1, 36 + lift, 1, 5, suitD)
            c.px(lx, 38 + lift, i % 2 == 0 ? red : blue)
            c.rect(lx, 42 + lift, 4, 2, shoe); c.rect(lx, 42 + lift, 3, 1, shoeL)
        }
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: nil), armRight: 0)

    // The suit: yellow, lit on the left, shaded far side and hem, polka dots, and three pom-pom buttons.
    c.rect(18, 34, 20, 4, suit)
    c.rect(18, 34, 1, 4, suitL); c.rect(37, 34, 1, 4, suitD); c.rect(18, 37, 20, 1, suitD); c.rect(15, 35, 3, 1, suitD)
    for (x, y, col) in [(20, 35, red), (23, 36, blue), (33, 35, green), (35, 37, red), (16, 34, blue), (31, 37, blue)] {
        c.px(x, y, col)
    }
    c.rect(27, 35, 2, 1, red); c.rect(27, 37, 2, 1, blue)
    // The ruff: white, scalloped, its frills edged in red.
    c.pattern(16, 32, [
        "..WWWWWWWWWWWWWWWWWWW...",
        "WWWWWWWWWWWWWWWWWWWWWWW.",
        ".rWWrWWrWWrWWrWWrWWrWWr.",
    ], ["W": paint, "r": red])
    for x in stride(from: 18, to: 38, by: 3) { c.px(x, 33, paintD) }

    // Greasepaint: white over his brows with black painted arches, white round the mouth, and the big red smile.
    c.rect(21, 27, 4, 2, paint); c.rect(31, 27, 4, 2, paint)
    c.px(21, 27, ink); c.rect(22, 26, 2, 1, ink); c.px(31, 27, ink); c.rect(32, 26, 2, 1, ink)
    c.rect(24, 31, 8, 1, paint)
    c.rect(24, 31, 1, 1, red); c.rect(25, 31, 6, 1, paint); c.px(31, 31, red)
    // The eyes (squeezed shut at each honk).
    if squeeze {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    // The nose: round and red with a shine, squashed flat while he squeezes it.
    if squeeze {
        c.rect(25, 30, 6, 1, red); c.rect(26, 29, 4, 1, red); c.px(26, 29, C(0xFF8A86))
    } else {
        c.rect(26, 29, 4, 2, red); c.rect(27, 28, 2, 1, red); c.rect(27, 31, 2, 1, redD); c.px(27, 29, C(0xFF8A86))
    }

    // The wig: a rainbow mop in bands, low on the crown and puffed out over each ear (the classic party-clown
    // shape, so his painted face keeps most of the sprite), its curls scalloped round the edge, lifting a pixel at
    // each honk.
    let bands: [(Px, Px)] = [(C(0xD8282C), C(0xA81C20)), (C(0xF08A24), C(0xC06A18)), (C(0xF4D23A), C(0xC8A626)),
                             (C(0x3AAE4E), C(0x26803A)), (C(0x3A6AD8), C(0x2A4CA8))]
    for y in 19...31 {
        for x in 13...42 {
            if y >= 25 && x >= 20 && x <= 35 { continue }
            if y >= 24 && x >= 22 && x <= 33 { continue }
            let dx = Double(x) - 27.5, dy = (Double(y) - 27.5) * 1.4
            let r = (dx * dx + dy * dy).squareRoot()
            let curl = sin(atan2(dy, dx) * 9) * 0.7
            let edge = 10.6 + curl
            guard r <= edge else { continue }
            let band = min(4, max(0, Int((edge - r) / 1.3)))
            let (base, dark) = bands[band]
            c.px(x, y + boing, (x * 2 + y * 3) % 7 == 0 ? dark : base)
        }
    }

    if honking {
        // His glove up at his nose, the sleeve across his chest; sound rings out in front at each squeeze.
        c.rect(33, 32, 6, 2, suit); c.rect(33, 33, 6, 1, suitD); c.px(38, 32, suitL)
        c.rect(29, 29, 3, 4, glove); c.rect(29, 32, 3, 1, gloveD); c.rect(29, 30, 1, 2, gloveD)
        c.rect(32, 32, 1, 2, suit)
        if squeeze {
            for r in [2, 4] {
                for dy in -r...r {
                    c.px(40 + r - abs(dy) / 2, 29 + dy, C(0xFFFFFF, r == 2 ? 0.8 : 0.5))
                }
            }
        }
        return
    }

    c.rect(38, 33, 3, 3, glove); c.rect(38, 35, 3, 1, gloveD)
    if let a = p.melee {
        // The claws: three long, pale talons out of the glove, curved a little at the tips.
        let h = huntHand
        huntSmear(c, h, p.trail, from: 2, to: 7, C(0xF4ECE0))
        for off in [-16.0, 0, 16] {
            huntBar(c, h, a + off, from: 1.5, to: 6.5, C(0xEEE6D2), r: 0.5)
            let tip = huntReach(h, a + off + 12, 7)
            c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), C(0xB8B0A0))
        }
        c.rect(40, 33, 2, 3, glove); c.px(41, 35, gloveD)
    }
}

// MARK: - The Scarecrow

/// The Scarecrow, the old pagan god of the orchard: a burlap sack for a head, tied at the neck with rope, two dark
/// eye holes and a mouth stitched shut in big black crosses, straw poking out at the collar and cuffs, a ragged brown
/// coat with a patch and a rope belt, its hem torn in points, and the wooden post and crossbar he hangs from rising
/// behind him. Fights with a rusty scythe on a long wooden snath. Signature: his head turns, slowly, all the way
/// round to look behind him, holds there, and snaps back.
private func drawScarecrow(_ c: PixelCanvas, _ p: Pose) {
    let sack = C(0xB8965E), sackD = C(0x8A6C3E), sackL = C(0xD4B47A), thread = C(0x2A1C10)
    let coat = C(0x4E3E30), coatD = C(0x30261C), coatL = C(0x6C5A46), patch = C(0x5E6A4A), patchD = C(0x3E4630)
    let straw = C(0xE2C662), strawD = C(0xB89A3E), rope = C(0x9A8256), ropeD = C(0x6E5A38)
    let wood = C(0x6A4A2A), woodD = C(0x48301A), woodL = C(0x8C6A42)
    let blade = C(0x9EA2A8), bladeL = C(0xDCE0E4), rust = C(0x8A5A36), snath = C(0x7A5A34), snathD = C(0x52381E)
    let s = p.signature ?? -1
    // The turn: slowly round (0…1 of the way), held, then snapping back.
    let turn: Double = s < 0.06 ? 0 : s < 0.5 ? (s - 0.06) / 0.44 : s < 0.82 ? 1 : s < 0.9 ? 1 - (s - 0.82) / 0.08 : 0
    let shift = Int((turn * 17).rounded())

    // The post behind him: an old grey-brown pole lit on the left, and the crossbar behind his shoulders.
    c.rect(26, 17, 4, 10, wood); c.rect(26, 17, 1, 10, woodL); c.rect(29, 17, 1, 10, woodD); c.rect(26, 17, 4, 1, woodL)
    c.px(27, 20, woodD); c.px(28, 23, woodD)
    c.rect(11, 29, 7, 3, wood); c.rect(11, 29, 7, 1, woodL); c.rect(11, 31, 7, 1, woodD)
    c.rect(38, 29, 6, 3, wood); c.rect(38, 29, 6, 1, woodL); c.rect(38, 31, 6, 1, woodD)
    c.px(14, 30, woodD)

    // Old trousers, stained, and cracked boots.
    drawLegs(c, Look(leg: C(0x4A4438)), step: p.step)
    drawBoots(c, C(0x2A2018), step: p.step, rows: 2)

    c.oy += p.breathe
    // The coat's hem, torn into points over the legs.
    if !seatedPose {
        c.pattern(17, 38, [
            "CCCCCCCCCCCCCCCCCCCCCC",
            "CdC.CCdC..CCC.dCCC.CdC",
            ".d...d.....C...d....d.",
        ], ["C": coat, "d": coatD])
    } else {
        c.rect(17, 38, 22, 1, coat)
    }
    drawBody(c, Look(arm: coat, eye: nil))

    // The coat: lapels lit, a green patch stitched on, the rope belt with its knot, the far side in shade, and straw
    // at the cuffs.
    c.rect(18, 33, 20, 5, coat)
    c.rect(19, 33, 3, 1, coatL); c.rect(33, 33, 3, 1, coatL); c.rect(18, 33, 1, 4, coatL)
    c.rect(26, 33, 4, 4, coatD); c.rect(25, 33, 1, 3, coatL); c.rect(30, 33, 1, 3, coatD)
    c.rect(20, 34, 3, 2, patch); c.px(20, 34, patchD); c.px(22, 35, patchD)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(18, 36, 20, 1, rope); c.rect(31, 36, 2, 2, ropeD); c.px(31, 37, rope)
    c.rect(15, 35, 3, 1, coatD)
    c.px(14, 35, straw); c.px(14, 34, strawD); c.px(15, 36, straw)

    // The sack over his head: burlap with a lit top and a coarse weave, gathered by a rope round the neck, straw
    // sticking out under it and in a tuft from the top.
    c.rect(18, 25, 20, 8, sack)
    c.rect(17, 26, 1, 6, sack); c.rect(38, 26, 1, 6, sackD)
    c.rect(18, 25, 3, 1, sackL); c.rect(18, 26, 1, 5, sackL); c.rect(37, 25, 1, 7, sackD)
    c.pattern(18, 21, [
        ".......y.y..y......",
        "......y.yYy.y.y....",
        ".......yYYYYy......",
        "...SSSSSSSSSSSSSSs.",
    ], ["S": sack, "s": sackD, "y": straw, "Y": strawD])
    c.rect(24, 24, 7, 1, ropeD)
    for y in stride(from: 26, to: 32, by: 2) {
        for x in stride(from: 19 + (y / 2) % 2, to: 37, by: 4) { c.px(x, y, sackD) }
    }
    c.rect(18, 32, 20, 1, rope); for x in stride(from: 19, to: 37, by: 3) { c.px(x, 32, ropeD) }
    for (x, len) in [(20, 2), (23, 1), (27, 2), (31, 1), (34, 2)] { c.rect(x, 33, 1, len, straw) }
    c.px(25, 33, strawD); c.px(36, 33, strawD)

    // The face, sliding round with the turn and over the edge of the sack, the back seam coming round after it.
    func feature(_ x: Int, _ y: Int, _ col: Px) {
        let fx = x - shift
        if fx >= 18 && fx <= 37 { c.px(fx, y, col) }
    }
    for ex in [22, 32] {
        feature(ex, 27, thread); feature(ex + 1, 27, thread); feature(ex, 28, C(0x140C06)); feature(ex + 1, 28, C(0x140C06))
        feature(ex - 1, 27, sackD); feature(ex + 2, 28, sackD)   // the cut edge of each hole
    }
    for x in 24...31 { feature(x, 30, thread) }
    for x in stride(from: 24, through: 31, by: 2) { feature(x, 29, thread); feature(x, 31, thread) }
    let seam = 28 - shift + 17
    if seam >= 18 && seam <= 37 {
        for y in 25...31 { c.px(seam, y, y % 2 == 0 ? thread : sackD) }
    }

    // The scythe: a long wooden snath with a rusty curved blade at the top.
    if let a = p.melee {
        let h = huntHand
        huntSmear(c, h, p.trail, from: 8, to: 15, C(0xE8ECF0))
        huntBar(c, h, a, from: -7, to: 11, snath, r: 0.7)
        huntBar(c, h, a, from: -7, to: -2, snathD, r: 0.5)
        let e = huntReach(h, a, 11)
        let mid = huntReach(e, a + 95, 4), tip = huntReach(mid, a + 135, 3.5)
        huntLine(c, e.x, e.y, mid.x, mid.y, blade, 0.9)
        huntLine(c, mid.x, mid.y, tip.x, tip.y, blade, 0.6)
        huntLine(c, e.x, e.y, mid.x, mid.y, bladeL, 0.35)
        c.px(Int(e.x.rounded()), Int(e.y.rounded()), rust)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, coat)
        c.px(Int(h.x.rounded()) + 1, Int(h.y.rounded()) + 1, straw)
    } else {
        // At rest, standing upright beside him, the blade curving out over his head.
        c.rect(42, 21, 1, 22, snath); c.rect(43, 21, 1, 22, snathD); c.rect(42, 34, 2, 1, snathD)
        c.pattern(42, 19, [
            "rrBBB......",
            "rBLLLBBB...",
            "..BBLLLBBB.",
            "......BBLBB",
            ".........BB",
        ], ["B": blade, "L": bladeL, "r": rust])
        c.rect(38, 33, 3, 3, coat); c.px(40, 35, straw); c.px(41, 33, coat)
    }
}

// MARK: - Hellhound

/// A hellhound, as the show never quite lets you see one: a great black dog of shadow prowling low, its head held
/// level with its shoulders, ears pricked, hackles up in spikes along its back, a long tail hanging low, and a red
/// eye glowing in the dark. Wisps of shadow rise off its back. While it waits it sniffs the ground, growls now and
/// then with a flash of teeth, and rakes the floor, leaving three red scratches that fade.
private func drawHellhound(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x1A171E), furD = C(0x0A090D), furL = C(0x38323F), eye = C(0xFF2A1E), tooth = C(0xF0ECE0)
    let rim = C(0x5E2228)
    let t = p.lt
    let sniff = !p.walking && sin(t * 0.9) > 0.55
    let growl = !p.walking && !sniff && Int(t * 1.3) % 6 == 0
    let rake = !p.walking && !sniff && !growl ? (t * 0.35).truncatingRemainder(dividingBy: 1) : -1
    let dip = sniff ? 3 : 0
    let pace = p.step >= 0 ? (p.step == 0 ? 1 : -1) : 0

    // The rising shadow, see-through and faint.
    for k in 0..<4 {
        let ph = (t * 0.6 + Double(k) * 0.25).truncatingRemainder(dividingBy: 1)
        let x = 21 + k * 5 + Int((sin(t * 2 + Double(k)) * 1.5).rounded())
        let y = 27 - Int(ph * 8)
        c.rect(x, y, 2, 1, C(0x1A171E, 0.22 * (1 - ph)))
        c.px(x + 1, y - 1, C(0x1A171E, 0.16 * (1 - ph)))
    }

    // Four long, thin legs, each pair set well apart: the hind ones bent at the hock, the front ones straight; they
    // stride when it moves. The far leg of each pair is a shade blacker, the near one lit down its front edge with a
    // dim ember rim, so the two never run together.
    for (i, lx) in [18, 25, 35, 42].enumerated() {
        let sw = i % 2 == 0 ? pace : -pace
        let lift = p.step >= 0 && i % 2 == p.step ? 1 : 0
        let near = i % 2 == 1
        let col = near ? fur : furD
        if i < 2 {
            c.rect(lx + sw, 37, 2, 3, col); c.rect(lx + sw - 1, 40, 2, 3 - lift, col)
            c.rect(lx + sw - 1, 42 - lift, 3, 1 + lift, near ? fur : furD)
            if near { c.rect(lx + sw, 37, 1, 3, furL); c.rect(lx + sw - 1, 40, 1, 2 - lift, rim) }
        } else {
            c.rect(lx + sw, 37, 2, 6 - lift, col)
            c.rect(lx + sw, 42 - lift, 3, 1 + lift, near ? fur : furD)
            if near { c.rect(lx + sw, 38, 1, 4 - lift, rim) }
        }
        c.px(lx + sw + (i < 2 ? 1 : 2), 43 - lift, near ? furL : fur)
    }
    c.oy += p.breathe
    // The tail, long and low, swaying.
    let sway = sin(t * 2.4) * 1.2
    huntLine(c, 18, 32, 13, 34 + sway * 0.5, fur, 0.8); huntLine(c, 13, 34 + sway * 0.5, 10, 38 + sway, furD, 0.6)
    // The body: a deep chest at the front, a tucked waist, lean haunches.
    c.pattern(17, 29, [
        ".....HHHHHHHHHHHHHHHHHH....",
        "..HHHHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHHHHH",
        ".HHHHHHHHDDDDDDDDHHHHHHHHHH",
        ".HHHHHHHD........DHHHHHHHH.",
        "..HHHHHH...........HHHHHH..",
        "...HHH..............HHHH...",
    ], ["H": fur, "D": furD])
    // Fur in strokes along its back and shoulder, lit from the front left.
    for (x, y) in [(20, 31), (25, 30), (30, 30), (35, 31), (22, 33), (28, 32), (38, 33), (19, 35), (40, 31)] {
        c.rect(x, y, 3, 1, furL)
    }
    c.rect(41, 34, 1, 3, furL)
    // The hackles: ragged spikes up along its spine, higher when it growls.
    for (i, hx) in [22, 25, 28, 31, 34, 37].enumerated() {
        let h = 2 + (i % 2) + (growl ? 1 : 0)
        for k in 0..<h { c.px(hx + (k == h - 1 ? 1 : 0), 28 - k, k == h - 1 ? furL : fur) }
    }
    // The head, held low and forward: pricked ears, a broad skull, a long muzzle, the jaw under it; dipped to the
    // ground while it sniffs.
    c.pattern(41, 23 + dip, [
        "..e..e.......",
        ".eH.eH.......",
        ".HH.HH.......",
        "HHHHHHH......",
        "HHHHHHHHH....",
        "HHHHHHHHHHHH.",
        "HHHHHHHHHHHHH",
        "HHHHHHHHHHHHm",
        ".HHHHHmmmmmm.",
        "..HHHH.......",
    ], ["H": fur, "e": furL, "m": furD])
    c.rect(43, 27 + dip, 4, 1, furL); c.rect(48, 28 + dip, 4, 1, furL)
    c.px(53, 29 + dip, C(0x2E2A30))   // its nose
    // The eye, a red ember with a faint glow round it.
    let ey = 28 + dip
    c.rect(47, ey, 2, 1, eye); c.px(48, ey, C(0xFFB0A0))
    for (dx, dy) in [(-1, 0), (2, 0), (0, -1), (1, -1), (0, 1), (1, 1)] { c.px(47 + dx, ey + dy, C(0xFF2A1E, 0.35)) }
    if growl {
        // Lips drawn back: a row of teeth along the muzzle.
        c.rect(47, 31 + dip, 6, 1, C(0x3A0E10))
        for x in stride(from: 47, through: 52, by: 2) { c.px(x, 31 + dip, tooth) }
    }
    // A dim ember rim along the top of its back, neck and head, as if lit from below by hellfire: enough to keep the
    // black shape on a dark desktop.
    hv7Rim(c, rim, from: 13, to: 53)
    if rake >= 0 && rake < 0.5 {
        // Three red scratches glowing on the floor in front of its paws, fading.
        let fade = rake < 0.1 ? rake / 0.1 : max(0, 1 - (rake - 0.1) / 0.4)
        for k in 0..<3 { c.rect(46 + k * 3, 44, 2, 1, C(0xE0281E, 0.75 * fade)); c.px(47 + k * 3, 45, C(0xE0281E, 0.4 * fade)) }
    }
}

/// Turns the topmost solid pixel of each column from `from` to `to` into `rim`, where it's one of the near-black fur
/// tones (never the eye, the teeth or a lit stroke).
private func hv7Rim(_ c: PixelCanvas, _ rim: Px, from x0: Int, to x1: Int) {
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    for x in max(0, x0)...min(c.w - 1, x1) {
        for y in 0..<c.h {
            let i = (y * c.w + x) * 4
            guard c.buf[i + 3] >= 250 else { continue }
            if Int(c.buf[i]) + Int(c.buf[i + 1]) + Int(c.buf[i + 2]) < 100 { c.px(x, y, rim) }
            break
        }
    }
}

// MARK: - Leviathan Blob

/// A Leviathan in its own shape: a wobbling lump of shiny black goo, a dark violet sheen on it, nothing for a face
/// but a huge grin of white teeth that opens wide and snaps shut. It oozes along, bubbles rise and pop on top, and
/// black goo drips off its lip.
private func drawLeviathanBlob(_ c: PixelCanvas, _ p: Pose) {
    let goo = C(0x110C16), gooM = C(0x22182C), sheen = C(0x52446A), gloss = C(0xC8C0DC)
    let gum = C(0x4A1830), mouth = C(0x1E0612), fang = C(0xFAF6EA), fangD = C(0xB8B2A6)
    let t = p.lt
    // Its squash and stretch: bouncing along when it moves, a slow heave when it doesn't.
    let squash = p.walking ? sin(t * 10) : sin(t * 2.2) * 0.4
    let wide = 13.0 + squash * 1.2, tall = 12.0 - squash * 1.4
    // The chomp: the grin gapes open every few seconds and snaps shut.
    let cyc = (t * 0.45).truncatingRemainder(dividingBy: 1)
    let gape = cyc < 0.25 ? cyc / 0.25 : cyc < 0.32 ? 1 : cyc < 0.36 ? (0.36 - cyc) / 0.04 : 0
    let open = Int((gape * 3).rounded())

    // The mass, column by column, rounded on top and spreading at the base, its top rippling.
    let cx = 30.0
    for x in 15...46 {
        let dx = (Double(x) - cx) / wide
        guard abs(dx) <= 1 else { continue }
        let k = (1 - dx * dx).squareRoot()
        let wobble = sin(t * 3.5 + Double(x) * 0.55) * 0.6
        let h = 2 + k * tall + wobble * k
        let top = 44 - Int(h.rounded())
        c.rect(x, top, 1, 44 - top, x > 36 ? goo : gooM)
        c.px(x, top, dx < 0 ? sheen : gooM)
        if x < 25 && top + 2 < 43 { c.px(x, top + 1, gooM) }
    }
    c.rect(15, 43, 32, 1, goo)
    // The sheen: a bright curved highlight up on its left shoulder.
    c.px(24, 35, gloss); c.px(25, 34, gloss); c.px(26, 34, sheen); c.px(23, 36, sheen)

    // The grin: wide across its front, corners turned up, white fangs top and bottom; it gapes open, then snaps.
    let my = 37
    // A gaping dark mouth, a cheek-to-cheek curve, its corners turned up.
    c.rect(27, my - open, 15, 4 + open, mouth)
    c.rect(26, my - 1 - open, 2, 2, mouth); c.rect(41, my - 1 - open, 2, 2, mouth)
    c.rect(27, my - open, 15, 1, gum); c.rect(28, my + 3, 13, 1, gum)
    // Fangs: pointed, two pixels long, down from the top jaw and up from the bottom, meeting when it shuts.
    for x in stride(from: 27, through: 41, by: 3) {
        c.rect(x, my - open, 2, 1, fang); c.px(x, my - open + 1, fang); c.px(x + 1, my - open + 1, fangD)
    }
    for x in stride(from: 28, through: 40, by: 3) {
        c.rect(x, my + 3, 2, 1, fang); c.px(x + 1, my + 2, fang); c.px(x, my + 2, fangD)
    }
    c.px(26, my - 1 - open, fang); c.px(42, my - 1 - open, fang)
    // Goo dripping from its lip.
    let drip = Int(t * 2) % 4
    c.rect(34, my + 4, 1, 1 + drip, goo)
    // A bubble swelling on top and popping.
    let b = (t * 0.7).truncatingRemainder(dividingBy: 1)
    if b < 0.8 {
        let r = b < 0.6 ? 1 : 2
        let by = 44 - Int(2 + tall) - r
        c.rect(30 - r / 2, by, r, r, gooM); c.px(30 - r / 2, by, sheen)
    } else {
        c.px(29, 44 - Int(2 + tall) - 3, C(0x52446A, 0.6)); c.px(32, 44 - Int(2 + tall) - 2, C(0x52446A, 0.6))
    }
}

// MARK: - Demon Smoke

/// A demon out of its host: a twisting column of thick black smoke, a billowing head over a tail that thins to a
/// wisp, coiling as it drifts, with red flickering deep inside it like lightning in a cloud. Its soft edge, the
/// puffs it sheds off its head and the wisps off its tail are see-through, in a smoky grey with a red glow so they
/// still show on a dark desktop; the core is solid black.
private func drawDemonSmoke(_ c: PixelCanvas, _ p: Pose) {
    let smoke = C(0x1A171E), smokeD = C(0x0C0A0E), smokeL = C(0x3C3644)
    let t = p.lt
    let lean = p.walking ? 2.0 : 0.0
    for y in 20...42 {
        let u = Double(y - 20) / 22
        let cx = 30 + sin(Double(y) * 0.35 - t * 3) * 2.6 * u + lean * (1 - u)
        let dome = min(1, Double(y - 19) / 4).squareRoot()
        let rag = (noise(y * 13 + Int(t * 5)) - 0.5) * 1.4 * (1 - u)
        let w = (0.7 + 6.8 * pow(1 - u, 0.9)) * dome * (0.88 + 0.12 * sin(t * 2.4 + Double(y) * 0.5)) + rag
        let x0 = Int((cx - w).rounded()), x1 = Int((cx + w).rounded())
        guard x1 >= x0 else { continue }
        // The soft edge: a faint, smoky grey pixel either side (pale enough to show on a dark desktop).
        c.px(x0 - 1, y, C(0x6A6078, 0.2)); c.px(x1 + 1, y, C(0x6A6078, 0.2))
        for x in x0...x1 {
            // Coils: lit and dark bands twisting down it, lit on the left.
            let band = (Double(x) - cx) * 0.6 + Double(y) * 0.5 - t * 4
            let b = (Int(floor(band)) % 4 + 4) % 4
            let col: Px = x == x0 ? smokeL : x == x1 ? smokeD : b == 0 ? smokeL : b == 2 ? smokeD : b == 1 && y % 3 == 0 ? C(0x4E4858) : smoke
            c.px(x, y, col)
        }
    }
    // Puffs shed off the head, curling up and back: see-through, a smoky grey lit on top with a red glow under
    // them from the fire inside, swelling in from nothing just clear of the head, then thinning away.
    for k in 0..<4 {
        let ph = (t * 0.45 + Double(k) / 4).truncatingRemainder(dividingBy: 1)
        let a = 0.62 * sin(ph * .pi)
        let x = 23 + k * 4 - Int(ph * 6) + Int((sin(t * 2 + Double(k) * 1.7) * 1.2).rounded()), y = 17 - Int(ph * 9)
        if ph > 0.25 && ph < 0.85 {
            // Grown into a round puff: a rounded 4×3 blob, lit along its top.
            c.rect(x + 1, y, 2, 1, C(0x9A90AC, a)); c.rect(x, y + 1, 4, 1, C(0x6A6078, a))
            c.px(x, y + 1, C(0x9A90AC, a)); c.rect(x + 1, y + 2, 2, 1, C(0x6A6078, a))
            c.rect(x + 1, y + 3, 2, 1, C(0xC03028, a * 0.5))
        } else {
            c.rect(x, y, 2, 2, C(0x6A6078, a)); c.px(x, y, C(0x9A90AC, a)); c.px(x + 1, y + 2, C(0xC03028, a * 0.5))
        }
    }
    // Wisps unravelling off the tip of its tail, drifting down and back.
    for k in 0..<2 {
        let ph = (t * 0.7 + Double(k) * 0.5).truncatingRemainder(dividingBy: 1)
        let a = 0.6 * sin(ph * .pi)
        let x = 29 - Int(ph * 5) + Int((sin(t * 3 + Double(k)) * 1).rounded()), y = 43 + Int(ph * 3)
        c.rect(x, y, 3, 1, C(0x7A7090, a)); c.rect(x - 2, y + 1, 2, 1, C(0x8A8098, a * 0.8))
    }
    // The red: a jagged flicker inside, now here, now there, and an ember glow at its heart.
    let flick = Int(t * 7)
    if noise(flick) > 0.45 {
        var x = 26 + Int(noise(flick * 3) * 7), y = 22 + Int(noise(flick * 5) * 8)
        for k in 0..<5 {
            c.px(x, y, k == 1 ? C(0xFF8A5A) : C(0xE0201E))
            c.px(x - 1, y, C(0xE0201E, 0.35)); c.px(x + 1, y, C(0xE0201E, 0.35))
            x += noise(flick * 7 + k) > 0.5 ? 1 : -1; y += 1
        }
    }
    let ember = 0.5 + 0.5 * sin(t * 5)
    c.px(30, 26, C(0x8A1010)); c.px(31, 27, C(0xB01818, 0.6 + 0.4 * ember)); c.px(29, 28, C(0x8A1010, 0.8))
}
