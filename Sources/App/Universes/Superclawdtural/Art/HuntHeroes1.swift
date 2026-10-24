import Foundation

// Heroes: Team Free Will. Clawd in costume like every other cast: hair and clothes drawn over the blocky body, with
// Clawd's own orange face showing. The brothers dress the way they did for fifteen seasons, flannel and denim under
// a jacket; their angel never takes off his trench coat.

let huntHeroes1: [HuntHero: Persona] = [
    .deanWinclawdster: Persona(name: "Dean Winclawdster", weapon: .blaster, shot: .bullet, muzzle: (48, 31),
                               headTop: 22, signature: 3.4, callout: "Son of a…!", draw: drawDeanWinclawdster),
    .samWinclawdster: Persona(name: "Sam Winclawdster", weapon: .saber, headTop: 20, signature: 3.6, callout: "Jerk.",
                              draw: drawSamWinclawdster),
    .clawdstiel: Persona(name: "Clawdstiel", weapon: .saber, headTop: 22, signature: 3.6, callout: "Hello, Dean.",
                         draw: drawClawdstiel),
]

// MARK: - Dean Winclawdster

/// Dean Winclawdster: short sandy-brown hair spiked up at the front, a worn brown leather jacket with its collar
/// turned out, open over a dark red flannel shirt and a charcoal tee, the little gold amulet Sam gave him on its cord,
/// jeans and brown boots. Fights with his pearl-gripped Colt M1911. Signature: he pulls out a slice of cherry pie and
/// takes three huge bites out of it, crumbs and all.
private func drawDeanWinclawdster(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x5E3C22), jacketD = C(0x3E2614), jacketL = C(0x7E5636)
    let flannel = C(0x7A2A26), flannelD = C(0x4A1A18), flannelL = C(0xA4483C), tee = C(0x2E2E34)
    let hair = C(0x7A5632), hairD = C(0x56391E), hairL = C(0x9A7444)
    let gold = C(0xE0B040), goldD = C(0x9A7420), cord = C(0x2A1A10)
    // The signature: the pie comes out and up to his mouth, three bites, then it's gone (eaten) and the arm comes down.
    let pie = p.signature.map { $0 > 0.06 && $0 < 0.94 ? ($0 - 0.06) / 0.88 : -1 } ?? -1
    let raise = pie < 0 ? 0 : pie < 0.15 ? Int(pie / 0.15 * 5) : pie > 0.88 ? Int((1 - pie) / 0.12 * 5) : 5

    // Jeans, faded lighter down the front of each leg, and brown boots.
    drawLegs(c, Look(leg: C(0x3E5A86)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx, top, 1, 3, C(0x5A76A0))
        }
    }
    drawBoots(c, C(0x4A3020), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: raise)

    // The jacket, open down the front: the flannel shirt either side of the tee, the amulet on its cord over it.
    c.rect(18, 33, 20, 5, jacket)
    huntPlaid(c, 24, 33, 2, 5, base: flannel, dark: flannelD, light: flannelL)
    huntPlaid(c, 30, 33, 2, 5, base: flannel, dark: flannelD, light: flannelL)
    c.rect(26, 33, 4, 5, tee)
    c.px(26, 33, cord); c.px(29, 33, cord)
    c.rect(27, 34, 2, 2, gold); c.px(28, 35, goldD); c.px(26, 34, goldD); c.px(29, 34, goldD)   // its little horns
    // The leather: a turned-out collar lit on top, the far side and the hem in shade, a seam and a pocket flap, cuffs.
    c.rect(20, 33, 4, 1, jacketL); c.rect(32, 33, 3, 1, jacketL); c.px(18, 33, jacketL)
    c.rect(23, 33, 1, 5, jacketD); c.rect(32, 34, 1, 4, jacketD)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(19, 34, 1, 3, jacketL); c.rect(34, 35, 3, 1, jacketD); c.px(20, 36, jacketD)
    c.rect(15, 35, 3, 1, jacketD)
    if raise == 0 { c.rect(38, 35, 3, 1, jacketD) }

    // Short hair, spiked up at the front (on the right, the way he faces), cut close round the ears.
    c.pattern(17, 21, [
        "................H.H...",
        "....H.HH.HH.HHH.HHH...",
        "..HHHlHHHlHHHHlHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HhHHHhHHHHhHHHHhHHhH.",
        ".HH................HH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)   // his brows

    if pie >= 0 {
        // The slice in his raised hand, its point to his mouth: the lattice crust lit, the cherry filling, the thick
        // back crust. Each bite takes two columns off the point; crumbs drop after each.
        let bites = pie < 0.3 ? 0 : pie < 0.5 ? 1 : pie < 0.7 ? 2 : 3
        let hy = 33 - raise
        c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 1, clawdShade)
        if bites < 3 {
            let crust = C(0xE2B66A), crustD = C(0xB0823E), cherry = C(0xB4203A), cherryD = C(0x7E1428)
            let rows = ["..LLLLC", "LLRrLRC", "..RRRRC"]
            for (dy, row) in rows.enumerated() {
                for (dx, ch) in row.enumerated() where dx >= bites * 2 && ch != "." {
                    let col: Px = ch == "L" ? crust : ch == "C" ? crustD : ch == "R" ? cherry : cherryD
                    c.px(36 + dx, hy - 3 + dy, col)
                }
            }
        }
        // Crumbs falling just after each bite.
        for b in 1...3 {
            let at = [0.3, 0.5, 0.7][b - 1], k = (pie - at) / 0.12
            guard k > 0 && k < 1 else { continue }
            c.px(37, hy + Int(k * 6), C(0xE2B66A)); c.px(39, hy + 1 + Int(k * 5), C(0xB4203A))
        }
        return   // the Colt stays tucked in his waistband while he eats
    }

    // The Colt: a stainless slide lit along the top, the dark frame and trigger guard, the pearl grip in his fist. It
    // kicks up `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..SSSSSSSSs",
        "..sKKKKKKK.",
        "OOOPk.k....",
        "OOOP.......",
        ".OP........",
    ], ["S": C(0xD4D8DE), "s": C(0x8A909A), "K": C(0x3A3C44), "k": C(0x2A2A30), "P": C(0xEEE8DA), "O": clawdOrange])
}

// MARK: - Sam Winclawdster

/// Sam Winclawdster: the tall one, with long brown hair to his shoulders, swept to the side, a blue-grey flannel shirt
/// open over a grey hoodie with its white drawstrings, jeans and boots. Fights with Ruby's demon-killing knife, its
/// blade a little curved and its dark handle carved. Signature: he opens his laptop, types away at it, closes it, and
/// sweeps his hair back out of his eyes.
private func drawSamWinclawdster(_ c: PixelCanvas, _ p: Pose) {
    let flannel = C(0x4A5E7A), flannelD = C(0x2E3C54), flannelL = C(0x7088A8)
    let hoodie = C(0x8A8A92), hoodieD = C(0x66666E), string = C(0xE8E6E0)
    let hair = C(0x5E3E24), hairD = C(0x3E2614), hairL = C(0x80583A)
    // The signature: the laptop out and open for most of it, typing; then put away, and the hand up to his hair.
    let s = p.signature ?? -1
    let laptop = s > 0.05 && s < 0.74 ? (s - 0.05) / 0.69 : -1
    let sweep = s >= 0.76 && s < 0.98 ? (s - 0.76) / 0.22 : -1
    let raise = sweep >= 0 ? Int(sin(sweep * .pi) * 8) : laptop >= 0 ? 1 : 0

    drawLegs(c, Look(leg: C(0x3A5480)), step: p.step)
    drawBoots(c, C(0x3E2A1C), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: flannel), armLeft: laptop >= 0 ? 1 : 0, armRight: raise)

    // The flannel, open over the hoodie: the hood bunched round his neck, the drawstrings hanging.
    huntPlaid(c, 18, 33, 6, 5, base: flannel, dark: flannelD, light: flannelL)
    huntPlaid(c, 32, 33, 6, 5, base: flannel, dark: flannelD, light: flannelL)
    c.rect(24, 33, 8, 5, hoodie); c.rect(24, 33, 8, 1, hoodieD); c.rect(25, 34, 6, 1, C(0x9E9EA6))
    c.rect(26, 35, 1, 2, string); c.rect(29, 35, 1, 2, string)
    c.rect(23, 33, 1, 5, flannelL); c.rect(32, 33, 1, 5, flannelD)
    c.rect(37, 33, 1, 5, flannelD); c.rect(18, 37, 20, 1, flannelD)
    c.rect(15, 35, 3, 1, flannelD)

    // Long hair, parted and swept across, falling past his ears to his shoulders on both sides. While he sweeps it
    // back, the fringe lifts off his brow.
    let fringe = sweep >= 0 && sweep > 0.35 && sweep < 0.85
    c.pattern(16, 20, [
        ".....HHHHHHHHHHHH.......",
        "...HHHHHlHHHHHHlHHHH....",
        "..HHHHHHHHHHHHHHHHHHHH..",
        ".HHHlHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHhHHHHHHHHHHH.",
        ".HHhHHHHHHHHHHHHhHHHHHH.",
        fringe ? ".HHHH...........HHHHHHH." : ".HHHHHH.........HHHHHHH.",
        fringe ? ".HHH.............HHHHd." : ".HHHH............HHHHHd.",
        "HHHd................dHHH",
        ".HHd................dHH.",
        "HHHd................dHHH",
        ".HHd................HHd.",
        "HHd..................dH.",
        ".d....................d.",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if sweep >= 0 && raise > 4 {
        c.rect(38, 33 - raise, 3, 3, clawdOrange)   // his hand at his hairline
    }
    if laptop >= 0 {
        // The laptop held out in front: the lid tipped back, its screen lit pale blue with lines of text scrolling, the
        // silver keyboard deck, and his fingers tapping on the keys. It opens at the start and shuts at the end.
        let open = min(1, laptop / 0.12, (1 - laptop) / 0.1)
        let deck = C(0xB8BCC4), deckD = C(0x80848C), frame = C(0x2A2C32), screen = C(0x9CCAF0)
        c.rect(37, 35, 11, 2, deck); c.rect(37, 36, 11, 1, deckD)
        for x in stride(from: 38, to: 47, by: 2) { c.px(x, 35, deckD) }
        let lid = Int(open * 6)
        if lid > 0 {
            c.rect(46, 35 - lid, 2, lid, frame)
            c.rect(41, 35 - lid, 5, lid, frame)
            if lid > 2 {
                c.rect(42, 36 - lid, 4, lid - 2, screen)
                for k in 0..<(lid - 2) where Int(p.t * 4 + Double(k)) % 3 != 0 {
                    c.rect(42, 36 - lid + k, 1 + Int(noise(Int(p.t * 4) + k) * 3), 1, C(0x4A7AB0))
                }
            }
        }
        let tap = Int(p.t * 9) % 2
        c.rect(38 + tap * 2, 33 + tap, 3, 2, clawdOrange)   // fingers on the keys
        return
    }

    // Ruby's knife: drawn and swung, or held point down at his side.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x2A1E18), steel: C(0xC8CCD4), edge: C(0xF2F4F8), length: 8,
                  notches: C(0x6A4A2A))
        let tip = huntReach(huntHand, a + 8, 8.5)   // the curve near the point
        c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), C(0xC8CCD4))
    } else {
        c.rect(39, 34, 2, 3, C(0x2A1E18)); c.px(39, 35, C(0x6A4A2A))
        c.rect(39, 37, 2, 4, C(0xC8CCD4)); c.rect(40, 37, 1, 4, C(0x8A9098)); c.px(40, 41, C(0xF2F4F8))
        c.rect(38, 34, 3, 2, clawdOrange)
    }
}

// MARK: - Clawdstiel

/// Clawdstiel: the angel in his vessel's clothes, never changed: a beige trench coat to the knees, belted, open over a
/// white shirt and a navy suit, the blue tie knotted crooked, dark hair rumpled as if he'd just flown in. Fights with
/// his angel blade, a long silver spike that slides out of his sleeve. Signature: the lights dim and his wings show as
/// a shadow thrown on the wall behind him, spreading wide, then folding away.
private func drawClawdstiel(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xC8B48A), coatD = C(0xA08C64), coatL = C(0xDECCA2), belt = C(0x9A845C)
    let shirt = C(0xF2F0EA), tie = C(0x2E4E9A), tieD = C(0x1E3470)
    let hair = C(0x2E2420), hairD = C(0x1A1412), hairL = C(0x4A3A32)
    // The signature: the wings' shadow opens, holds spread, and folds again. Turning up behind someone, or going home
    // (HuntHabits.swift), they flutter open for a moment in a flash of pale light.
    let flutter = huntClawdstielFlutter
    let wings = max(p.signature.map { $0 > 0.06 && $0 < 0.94 ? sin(($0 - 0.06) / 0.88 * .pi) : 0 } ?? 0, flutter)

    // Behind everything: the flash, faint and see-through, and the wings' shadow on the wall.
    if flutter > 0 {
        c.ellipse(28, 31, Int(10 + 14 * flutter), Int(8 + 9 * flutter), C(0xF4F6FF, 0.22 * flutter))
        c.ellipse(28, 31, Int(6 + 8 * flutter), Int(5 + 5 * flutter), C(0xFFFFFF, 0.2 * flutter))
    }
    huntWingShadows(c, min(1, wings * 1.3))

    // Navy suit trousers and black shoes under the coat.
    drawLegs(c, Look(leg: C(0x2A2E3E)), step: p.step)
    drawBoots(c, C(0x16161A), step: p.step, rows: 1)

    c.oy += p.breathe
    // The coat's skirts to the knees, over the legs: split at the back and down the front, a fold over each leg, the
    // hem a shade darker, so the four legs still show below it.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.rect(17, 38, 1, 1, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 22, 1, coatD)
        c.px(17, 38, coatL); c.px(17, 39, coatL); c.rect(38, 38, 1, 3, coatD)
        for x in [21, 25, 33] { c.rect(x, 38, 1, 2, coatD) }
        c.rect(29, 38, 1, 3, C(0x7A6844))   // the front opening
    }
    drawBody(c, Look(arm: coat), armRight: p.armRaise)

    // The coat over the body: epaulettes lit on the shoulders, wide lapels open on the shirt and the crooked tie, the
    // belt cinched at the waist with its buckle, the far side in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(19, 33, 3, 1, coatL); c.rect(33, 33, 3, 1, coatL)
    c.rect(25, 33, 6, 4, shirt)
    c.rect(24, 33, 1, 4, coatL); c.rect(23, 34, 1, 2, coatL); c.rect(31, 33, 1, 4, coatD); c.rect(32, 34, 1, 2, coatD)
    c.rect(26, 33, 2, 1, tie); c.px(27, 34, tie); c.px(28, 34, tieD); c.px(28, 35, tie); c.px(29, 36, tie)
    c.rect(18, 36, 20, 1, belt); c.rect(27, 36, 2, 1, C(0x5E4E34)); c.px(37, 36, coatD)
    c.rect(37, 33, 1, 3, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD)

    // Dark hair, rumpled, sticking up in tufts on top and falling a little over his brow.
    c.pattern(17, 21, [
        "......H....H..H.......",
        "...HH.HH.HHH.HHH.H....",
        "..HHHHlHHHHlHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHhHHHHhHHHHHhHHHHhH.",
        ".HHHh..hH.......HHHH..",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The angel blade: out of his sleeve when he fights, long and three-sided, a dull silver with a bright edge.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x8A8E96), steel: C(0xB4BAC4), edge: C(0xF4F6FA), length: 11)
    }
}
