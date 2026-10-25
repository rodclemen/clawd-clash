import Foundation

// Heroes: She-Clawd and the Great Rebellion of Etheria, drawn the same way as EterniaHeroes1.swift. The two horses
// and Kowl are Clawd in costume too: the blocky body is the horse's barrel or the koala-owl's round middle, always on
// Clawd's four legs.

let eterniaHeroes4: [EterniaHero: Persona] = [
    .sheClawd: Persona(name: "She-Clawd", weapon: .saber, headTop: 17, signature: 3.8, callout: "I am She-Clawd!",
                       draw: drawSheClawd),
    .adorra: Persona(name: "Princess Adorra", weapon: .saber, headTop: 20, signature: 3.4,
                     callout: "For the honour of Greyskull!", draw: drawAdorra),
    .spirit: Persona(name: "Spirit", bulk: 8, headTop: 12, signature: 3.2, draw: drawSpirit),
    .swiftWind: Persona(name: "Swift Wind", weapon: .saber, motion: .fly, pivot: (49, 17), bulk: 8, headTop: 9,
                        signature: 3.4, draw: drawSwiftWind),
    .bow: Persona(name: "Bow", weapon: .blaster, shot: .arrow, muzzle: (49, 34), handGun: false, headTop: 20,
                  signature: 3.4, callout: "Here's Bow!", draw: drawBow),
    .glimmer: Persona(name: "Glimmer", weapon: .lightning,
                      magic: Magic(core: C(0xFFF6FB), glow: C(0xFF5AB0), jagged: false),
                      headTop: 20, signature: 3.2, draw: drawGlimmer),
    .madameRazz: Persona(name: "Madame Razz", weapon: .lightning,
                         magic: Magic(core: C(0xFFC8F0), glow: C(0xA040D0), jagged: false, touch: true),
                         headTop: 9, signature: 4.2, draw: drawMadameRazz),
    .kowl: Persona(name: "Kowl", motion: .fly, headTop: 18, signature: 3.0, callout: "Typical.", draw: drawKowl),
]

private let none = C(0, 0)

/// Draws `art` (in sprite coordinates, no offsets) on a scratch canvas, turns it `degrees` about `pivot` (negative:
/// anticlockwise, a right-facing sprite rears up) and lays it on `c` with its offsets.
private func turned(_ c: PixelCanvas, _ degrees: Double, about pivot: (x: Double, y: Double), _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    if abs(degrees) < 0.5 { c.paste(s); return }
    c.paste(s.rotated(degrees, about: pivot, into: c.w, c.h, at: pivot))
}

/// A cape hanging behind the left shoulder from row 27 to `hem`, its edge swaying.
private func backCape(_ c: PixelCanvas, t: Double, speed: Double, _ col: Px, _ edge: Px, _ fold: Px, hem: Int = 41) {
    let last = min(hem, 43 - c.oy)
    guard last >= 27 else { return }
    for y in 27...last {
        let k = Double(y - 27) / Double(max(1, hem - 27))
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((15.5 - k * 4 + sway).rounded())
        c.rect(l, y, 24 - l, 1, col)
        c.px(l, y, edge)
        if y > 30 { c.px(l + 3, y, fold) }
    }
}

/// A feathered wing from `root`: six feathers fanned between `from` and `to` degrees, `length` long, grey-edged so
/// they read apart; `near` is the lit, white wing, the far one a shade greyer.
private func wing(_ c: PixelCanvas, root: (Double, Double), edge a: Double, feathers f: Double, length: Double,
                  near: Bool) {
    let main = near ? C(0xFCFCFF) : C(0xD8DAE4), shade = near ? C(0xC4C8D6) : C(0xA8ACBC)
    let ar = a * .pi / 180, fr = f * .pi / 180
    // The feathers, from the tip in to the root, each hanging back from a point along the edge, a shaded line under
    // each so they read apart.
    for i in (1...6).reversed() {
        let k = Double(i) / 6
        let p0 = (root.0 + cos(ar) * length * k, root.1 + sin(ar) * length * k)
        let l = 3 + 5 * k
        let p1 = (p0.0 + cos(fr) * l, p0.1 + sin(fr) * l)
        c.glowLine(p0.0, p0.1 + 1, p1.0, p1.1 + 1, core: shade, glow: none, coreR: 0.6, glowR: 0.65)
        c.glowLine(p0.0, p0.1, p1.0, p1.1, core: main, glow: none, coreR: 0.8, glowR: 0.85)
    }
    // The leading edge, thick and lit.
    let tip = (root.0 + cos(ar) * length, root.1 + sin(ar) * length)
    c.glowLine(root.0, root.1, tip.0, tip.1, core: main, glow: none, coreR: 1.2, glowR: 1.25)
}

// MARK: - She-Clawd

/// She-Clawd: the Princess of Power. Long bright-gold hair falling in strands down her back and over her shoulder, a
/// winged golden tiara with a red jewel at its middle, a white tunic and short skirt with a gold neckline and belt,
/// gold bracers and tall gold boots, and a red cape behind. The Sword of Protection is silver with a gold hilt and a
/// red jewel in its guard; at rest its point is on the ground at her side. Signature: she raises the sword, its jewel
/// glows, and in a flash it turns into a round gold shield on her arm, then flashes back into the sword.
private func drawSheClawd(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF4CE50), hairD = C(0xC89A2A), hairL = C(0xFFEA90)
    let gold = C(0xE8B838), goldD = C(0xA87C1C), goldL = C(0xFFE07A)
    let tunic = C(0xF4F2EE), tunicD = C(0xC8C4C8), tunicF = C(0xDCD8DC)
    let cape = C(0xC8282E), capeD = C(0x8E1A20), jewel = C(0xE8323A), silver = C(0xB8BCC8), silverL = C(0xE8EAF2)
    // The signature, 0…1: the sword goes up, the jewel glows, a flash, the shield, a flash, the sword comes down.
    let s = p.signature ?? -1
    let shieldOn = s >= 0.42 && s < 0.76
    let swordUp = s >= 0 && !shieldOn
    let up = s < 0 ? 0.0 : s < 0.12 ? s / 0.12 : s > 0.88 ? max(0, (1 - s) / 0.12) : 1
    let raise = swordUp ? Int((up * 8).rounded()) : 0
    let glow = s > 0.18 && s < 0.42 ? (s - 0.18) / 0.24 : s >= 0.76 && s < 0.86 ? 1 - (s - 0.76) / 0.1 : 0
    let flash = max(0, 1 - abs(s - 0.42) / 0.05, 1 - abs(s - 0.76) / 0.05)

    backCape(c, t: p.t, speed: p.capeSpeed, cape, capeD, capeD)
    // The long hair down her back, in strands, over the cape.
    for (i, x) in [14, 15, 16, 17].enumerated() {
        let len = 37 - (i == 0 ? 3 : 0) + (i == 2 ? 1 : 0)
        c.rect(x, 26, 1, len - 26, i % 2 == 0 ? hair : hairD)
    }
    c.px(15, 37, hair); c.px(17, 38, hairD)

    // Bare legs, and the tall gold boots: a lit cuff round the top, a crease down the front.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 1, goldL); c.px(lx + 1, bottom - 1, goldD)
        }
    }

    c.oy += p.breathe
    drawBody(c, Look(), armRight: raise)
    // The white tunic: a gold neckline lit along the top, folds, the far side shaded; the gold belt with its jewel;
    // the short skirt hanging over her legs in pleats.
    c.rect(18, 33, 20, 4, tunic); c.rect(37, 33, 1, 4, tunicD)
    c.pattern(18, 32, [
        "GGGGGGg......gGGGGGG",
        ".gGGGGGGg..gGGGGGGg.",
    ], ["G": gold, "g": goldD])
    c.px(19, 32, goldL); c.px(20, 32, goldL)
    c.rect(21, 34, 1, 2, tunicF); c.rect(33, 34, 1, 2, tunicF)
    c.rect(18, 36, 20, 1, gold); c.rect(18, 36, 6, 1, goldL); c.rect(27, 36, 2, 1, jewel)
    for y in 37...38 where y + c.oy <= 42 {
        c.rect(18, y, 20, 1, tunic)
        for x in [21, 25, 30, 34] { c.px(x, y, tunicF) }
        c.px(37, y, tunicD)
    }
    // Gold bracers on both wrists.
    c.rect(15, 35, 3, 1, gold); c.px(15, 35, goldL)
    c.rect(38, 35 - raise, 3, 1, gold); c.px(38, 35 - raise, goldL)

    // The hair: a crown of bright strands, parted a little off-centre, falling long past her ears either side.
    c.pattern(15, 20, [
        "......HHHHHlHHHHHHH.......",
        "....HHHlHHHHHHlHHHHHH.....",
        "...HHHhHHHlHHhHHHHHHHH....",
        "..HHhHHHHHhHHHHHhHHHhHH...",
        "..HHhHHHHhHHHHHHHhHHHhHH..",
        ".HHhHHHHhHHHHHHHHHhHHHhHH.",
        ".HHh.hH..hH....Hh..Hh.hHH.",
        "HHh...................hHHH",
        "HHh....................hHH",
        "HHh....................hH.",
        "HhH....................hH.",
        "HHh.....................h.",
        ".Hh.......................",
        ".hH.......................",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The tiara: a gold band across her brow with the red jewel at its middle, and a gold wing swept up at each side.
    c.rect(19, 25, 18, 1, gold); c.rect(19, 25, 7, 1, goldL); c.rect(33, 25, 4, 1, goldD)
    c.pattern(26, 23, [".J.", "JJJ", ".J."], ["J": jewel]); c.px(27, 23, C(0xFF8A8A))
    c.pattern(12, 21, [
        "L.L.L....",
        "WWWWWW...",
        ".wWWWWWW.",
        "...wwWWWW",
    ], ["W": gold, "w": goldD, "L": goldL])
    c.pattern(35, 21, [
        "....L.L.L",
        "...WWWWWW",
        ".WWWWWWw.",
        "WWWWww...",
    ], ["W": gold, "w": goldD, "L": goldL])

    let hilt = (grip: C(0xD8A830), guardCol: gold, pommel: goldL)
    // The Sword of Protection's jewel, on the guard: glowing while the signature charges it.
    func jewelAt(_ h: (x: Double, y: Double), _ a: Double) {
        let g = eterniaReach(h, a, 2)
        c.rect(Int(g.x.rounded()) - 1, Int(g.y.rounded()) - 1, 2, 2, jewel)
        if glow > 0 {
            c.glowLine(g.x - 0.5, g.y - 0.5, g.x - 0.5, g.y - 0.5, core: C(0xFFF0F0, 0.9 * glow), glow: C(0xFF5050, 0.8 * glow),
                       coreR: 0.8, glowR: 1.5 + 2.5 * glow)
        }
    }
    if shieldOn {
        // The shield on her forearm: round, a gold rim lit top-left, a silver face, the red jewel at its heart.
        c.pattern(39, 26, [
            "...RRRRR...",
            ".RRLLLLLRR.",
            ".RLSSSSSsR.",
            "RLSSSSSSSsR",
            "RLSSSjjSSsR",
            "RLSSjJJjSsR",
            "RLSSjJJjSsR",
            "RLSSSjjSSsR",
            "RLSSSSSSSsR",
            ".RSSSSSSsR.",
            ".RRsssssRR.",
            "...rrrrr...",
        ], ["R": gold, "r": goldD, "L": goldL, "S": silverL, "s": silver, "j": jewel, "J": C(0xFF8A80)])
    } else if swordUp {
        let h = (x: eterniaHand.x - 1.5, y: eterniaHand.y - Double(raise))
        eterniaSword(c, p, angle: -90, at: h, grip: hilt.grip, guardCol: hilt.guardCol, steel: silverL,
                     edge: C(0xFFFFFF), length: 13, pommel: hilt.pommel)
        jewelAt(h, -90)
    } else if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: hilt.grip, guardCol: hilt.guardCol, steel: silverL, edge: C(0xFFFFFF),
                     length: 13, pommel: hilt.pommel)
        jewelAt(eterniaHand, a)
    } else {
        // At rest: the sword held point down at her side, its tip on the ground.
        eterniaSword(c, p, angle: seatedPose ? 15 : 82, grip: hilt.grip, guardCol: hilt.guardCol, steel: silverL, edge: C(0xFFFFFF),
                     length: 8, pommel: hilt.pommel)
        jewelAt(eterniaHand, seatedPose ? 15 : 82)
    }
    if flash > 0 {
        // The change: a white-gold burst round her hand, see-through.
        let h = (x: eterniaHand.x + 2, y: eterniaHand.y - 4)
        c.glowLine(h.x, h.y, h.x, h.y, core: C(0xFFFFFF, 0.9 * flash), glow: C(0xFFE070, 0.8 * flash), coreR: 2.5 * flash,
                   glowR: 2.5 + 5 * flash)
    }
}

// MARK: - Princess Adorra

/// Princess Adorra: She-Clawd before the change. Shoulder-length honey-blond hair with a straight fringe and no
/// tiara, a white long-sleeved tunic with a thin gold V at the neck, a red skirt, a brown belt and brown boots, no
/// cape. Her sword is the same Sword of Protection, worn over her back while it's put away. Signature: she holds the
/// sword up to the light, looking up at it and thinking, a glint running up the blade.
private func drawAdorra(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xD8B050), hairD = C(0xA8822C), hairL = C(0xF0D07A)
    let tunic = C(0xF2F0EC), tunicD = C(0xC4C0C6), tunicF = C(0xD8D4D8)
    let skirt = C(0xC03036), skirtD = C(0x8A1E24), skirtL = C(0xE05058)
    let boot = C(0x7A4A28), bootD = C(0x54321A), bootL = C(0x9A6638), belt = C(0x5A3820)
    let gold = C(0xE0B040), jewel = C(0xE8323A), silverL = C(0xE8EAF2)
    let s = p.signature ?? -1
    let up = s < 0 ? 0.0 : s < 0.15 ? s / 0.15 : s > 0.85 ? max(0, (1 - s) / 0.15) : 1
    let raise = Int((up * 8).rounded())
    let thinking = s > 0.2 && s < 0.82

    // The sword over her back while it's put away.
    if p.melee == nil && raise == 0 {
        c.rect(14, 23, 2, 7, C(0xD8A830)); c.px(14, 23, C(0xFFE07A))
        c.rect(12, 29, 6, 1, gold); c.px(15, 29, jewel)
    }
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 1, bootL); c.px(lx + 1, bottom - 1, bootD); c.px(lx, bottom - 2, bootD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: tunic), armRight: raise)
    if thinking { c.rect(22, 31, 2, 1, clawdOrange); c.rect(32, 31, 2, 1, clawdOrange) }   // looking up at the blade
    // The tunic: sleeves to the wrist, the gold V at her neck, a fold either side; the brown belt and the red skirt
    // in pleats over her legs.
    c.rect(18, 32, 20, 5, tunic); c.rect(37, 32, 1, 5, tunicD)
    c.rect(18, 32, 20, 1, gold); c.rect(18, 32, 6, 1, C(0xFFE07A)); c.rect(36, 32, 2, 1, C(0xA87C1C))
    c.rect(20, 33, 1, 3, tunicF); c.rect(35, 33, 1, 3, tunicF)
    c.rect(15, 35, 3, 1, tunicD); c.rect(38, 35 - raise, 3, 1, tunicD)   // the cuffs
    c.rect(18, 36, 20, 1, belt); c.px(27, 36, gold); c.px(28, 36, C(0xA87C1C))
    for y in 37...39 where y + c.oy <= 42 {
        let w = y == 39 ? 1 : 0
        c.rect(18 - w, y, 20 + 2 * w, 1, skirt)
        for x in [21, 25, 30, 34] { c.px(x, y, skirtD) }
        c.px(18 - w, y, skirtL); c.px(37 + w, y, skirtD)
    }

    // The hair: a straight fringe across her brow and down to her shoulders either side, in strands.
    c.pattern(16, 21, [
        "......HHHHHHHlHHH......",
        "...HHHlHHHHHHHHHHHH....",
        "..HHhHHHHhHHHHHhHHHHH..",
        ".HHHhHHHHhHHHHHhHHHhHH.",
        "HHHhHHHHhHHHHHhHHHhHHHH",
        "HHHhHHHhHHHhHHHhHHHhHHH",
        "HHhhhhhhhhhhhhhhhhhhhHH",
        "HHh..................hH",
        "HHh..................hH",
        "HHh..................hH",
        "HhH..................Hh",
        "Hh....................h",
    ], ["H": hair, "h": hairD, "l": hairL])

    let grip = C(0xD8A830)
    if raise > 0 {
        let h = (x: eterniaHand.x - 1.5, y: eterniaHand.y - Double(raise))
        eterniaSword(c, p, angle: -90, at: h, grip: grip, guardCol: gold, steel: silverL, edge: C(0xFFFFFF), length: 13,
                     pommel: C(0xFFE07A))
        let g = eterniaReach(h, -90, 2); c.rect(Int(g.x.rounded()) - 1, Int(g.y.rounded()) - 1, 2, 2, jewel)
        if thinking {
            // The glint running up the blade, and three little dots of thought rising past her head.
            let k = frac((s - 0.2) / 0.3)
            let gy = h.y - 4 - k * 10
            c.glowLine(h.x, gy, h.x, gy, core: C(0xFFFFFF, 0.95), glow: C(0xFFF4B0, 0.7), coreR: 0.6, glowR: 2.2)
            let dots = min(3, Int((s - 0.2) / 0.1))
            for i in 0..<dots { c.rect(30 - i * 4, 17 - i * 3, 2, 2, C(0xF4F4FA, 0.9)) }
        }
        return
    }
    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: grip, guardCol: gold, steel: silverL, edge: C(0xFFFFFF), length: 13,
                     pommel: C(0xFFE07A))
        let g = eterniaReach(eterniaHand, a, 2); c.rect(Int(g.x.rounded()) - 1, Int(g.y.rounded()) - 1, 2, 2, jewel)
    }
}

// MARK: - The horses

private struct Horse {
    var coat = C(0xF4F2EC), coatD = C(0xC8C6C2), coatL = C(0xFFFFFF)
    var mane: Px, maneD: Px, maneL: Px
    var hoof = C(0x8A8480)
    var longMane = false
}

/// A horse's legs and hooves on Clawd's four legs: white, a shaded fetlock, grey hooves. `fold` lifts and bends the
/// front pair forward (rearing); `paw` lifts the front leg by that much (pawing the ground).
private func horseLegs(_ c: PixelCanvas, _ h: Horse, step: Int, fold: Bool = false, paw: Int = 0) {
    if seatedPose {
        drawLegs(c, Look(leg: h.coat), step: step)
        for lx in [19, 23, 31, 35] { c.rect(lx + 2, 39, 1, 1, h.hoof) }
        return
    }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let front = i >= 2
        if fold && front {
            // Bent at the knee, the hoof tucked forward.
            c.rect(lx, 36, 2, 3, h.coat); c.rect(lx + 1, 38, 3, 2, h.coat); c.rect(lx + 4, 38, 1, 2, h.hoof)
            c.px(lx + 1, 36, h.coatD)
            continue
        }
        if i == 3 && paw > 0 {
            // Lifted and bent at the knee, the hoof forward, ready to strike the ground.
            c.rect(lx, 36, 2, 3, h.coat); c.rect(lx + 1, 38, 2, 2, h.coat); c.rect(lx + 2, 40, 2, 2, h.hoof)
            c.px(lx + 1, 37, h.coatD)
            continue
        }
        let lift = step >= 0 && i % 2 == step ? 1 : 0
        let bottom = 43 - lift
        c.rect(lx, 36, 2, bottom - 36 + 1, h.coat)
        c.px(lx + 1, 37, h.coatD); c.px(lx + 1, bottom - 2, h.coatD)
        c.rect(lx, bottom - 1, 2, 2, h.hoof); c.px(lx, bottom - 1, C(0xAAA49E))
    }
}

/// The horse's barrel (Clawd's body), its tail, and its neck and head on top of the front, turned `nod` degrees about
/// the withers (positive: head down). The body is drawn `c.oy` as it stands; the head is drawn from (31, 11).
private func horseBody(_ c: PixelCanvas, _ h: Horse, t: Double, nod: Double, toss: Double) {
    // The tail, hanging from the rump and swishing.
    let sw = sin(t * 2.3) * 1.2
    for k in 0..<10 {
        let y = 28 + k, x = 16 - Int((Double(k) * 0.4 + sw * Double(k) / 10).rounded())
        c.rect(x, y, 2, 1, k % 3 == 0 ? h.maneD : h.mane)
        if k > 3 { c.px(x - 1, y, h.maneD) }
    }
    c.px(17, 27, h.mane)
    // The barrel: Clawd's block in white, the top corners rounded, lit along the back, the belly shaded.
    c.rect(18, 27, 20, 10, h.coat); c.rect(19, 26, 18, 1, h.coatL); c.rect(19, 37, 18, 1, h.coatD)
    c.rect(37, 27, 1, 10, h.coatD); c.rect(19, 36, 18, 1, h.coatD)
    for (x, y) in [(21, 30), (25, 32), (29, 30), (33, 33)] { c.rect(x, y, 2, 1, C(0xE2E0DA)) }   // coat in strokes
    // The neck and head, turned at the withers.
    turned(c, nod, about: (35, 27)) { horseHead($0, h, toss: toss, t: t) }
}

/// The neck rising from the front of the barrel and the head at its top, its muzzle forward and down, an eye, a
/// nostril, an ear pricked up, and the mane along the top of the neck (long and flowing for Swift Wind).
private func horseHead(_ c: PixelCanvas, _ h: Horse, toss: Double, t: Double) {
    c.pattern(30, 12, [
        ".......EE.........",
        "......EEE.........",
        ".....WWWWWW.......",
        "....WWWWWWWWW.....",
        "...WWWWWKWWWWWW...",
        "...WWWWWKWWWWWWWW.",
        "..WWWWWWWWWWWWWWWW",
        "..WWWWWWWWWWWWWWMM",
        ".WWWWWWWW..WWWMMNM",
        ".WWWWWWW.....MMMM.",
        ".WWWWWWW..........",
        "WWWWWWWW..........",
        "WWWWWWWW..........",
        "WWWWWWWd..........",
        "WWWWWWdd..........",
        "WWWWWWd...........",
    ], ["W": h.coat, "E": h.coatD, "K": ink, "M": C(0xD8CCC8), "N": C(0x6A5E5A), "d": h.coatD])
    c.px(37, 13, C(0xE8B8C0))                       // the inside of the ear
    c.rect(36, 15, 4, 1, h.coatL); c.rect(33, 17, 1, 5, h.coatL)
    c.rect(38, 17, 1, 1, h.coatD)                   // the brow over the eye
    c.rect(41, 20, 4, 1, h.coatD)                   // the jaw line
    // The mane: short strands down the top of the neck, or long ones flowing back when it's Swift Wind's.
    let flow = toss * 3
    for k in 0..<8 {
        let y = 14 + k
        let x0 = 33 - k / 2
        let len = h.longMane ? 4 + (k % 2) + Int(flow) : 2 + Int(flow)
        let wave = h.longMane ? Int((sin(t * 3 + Double(k) * 0.8) * 0.8).rounded()) : 0
        c.rect(x0 - len, y + wave, len + 1, 1, k % 2 == 0 ? h.mane : h.maneD)
        c.px(x0 - len, y + wave, h.maneD)
    }
    c.rect(34, 13, 3, 2, h.mane); c.px(35, 13, h.maneL)   // the forelock between the ears
    c.px(31, 16, h.maneL); c.px(30, 18, h.maneL)
}

// MARK: - Spirit

/// Spirit: Adorra's horse, white all over with a short cream mane and tail, grey hooves and a pink-grey muzzle,
/// standing on Clawd's four legs with his neck up and his head forward. He stays out of the fighting. Signature: he
/// paws the ground with a front hoof, dust puffing up, then tosses his head, his mane flying.
private func drawSpirit(_ c: PixelCanvas, _ p: Pose) {
    let h = Horse(mane: C(0xEADDB0), maneD: C(0xC8B888), maneL: C(0xFFF4D0))
    let s = p.signature ?? -1
    let pawing = s > 0.05 && s < 0.55
    let paw = pawing ? (Int(s * 16) % 2 == 0 ? 1 : 0) : 0
    let tossK = s > 0.6 && s < 0.95 ? sin((s - 0.6) / 0.35 * .pi) : 0
    let nod = p.walking ? sin(p.t * 8 * .pi) * 2 : pawing ? 8 : -20 * tossK

    horseLegs(c, h, step: p.step, paw: paw)
    if pawing && paw == 0 {
        // The dust off the struck ground, light and see-through.
        for k in 0..<3 { c.rect(37 + k * 2, 42 - k % 2, 2, 1, C(0xE8DCC0, 0.6)) }
    }
    c.oy += p.breathe
    horseBody(c, h, t: p.t, nod: nod, toss: tossK)
}

// MARK: - Swift Wind

/// Swift Wind: Spirit changed, a white winged unicorn. A long pink mane and tail flowing, a spiralled gold horn on
/// his brow, and two great white wings, folded up over his back at rest and beating in flight. He fights with the
/// horn, lowering his head to charge. Signature: he rears up on his hind legs, front hooves tucked, wings spread
/// wide, and comes back down.
private func drawSwiftWind(_ c: PixelCanvas, _ p: Pose) {
    let h = Horse(mane: C(0xF070B8), maneD: C(0xC04890), maneL: C(0xFFA8D8), longMane: true)
    let s = p.signature ?? -1
    let rear = s < 0 ? 0 : habitArc(s, hold: 0.55)
    var spread = rear
    if p.flying { spread = 0.5 + 0.5 * sin(p.t * 9) }
    // The horn charge: the swing's angle becomes how far he lowers his head.
    var nod = p.walking ? sin(p.t * 8 * .pi) * 2 : 12 * rear
    var lunge = 0
    if let a = p.melee {
        nod = max(-16, min(22, (a + 60) * 0.25))
        lunge = a > -20 ? 2 : 0
    }
    let tilt = -18 * rear
    let breathe = p.breathe
    let step = p.step
    let flying = p.flying
    let t = p.t
    turned(c, tilt, about: (22, 43)) { s in
        s.ox = lunge
        horseLegs(s, h, step: step, fold: rear > 0.3 || flying)
        s.oy += breathe
        // The far wing behind him, then the body, then the near wing over it.
        let root = (27.0, 27.0)
        wing(s, root: (root.0 - 2, root.1 - 1), edge: -150 + 50 * spread, feathers: 170 - 60 * spread,
             length: 12 + 5 * spread, near: false)
        horseBody(s, h, t: t, nod: nod, toss: rear)
        // The horn: spiralled gold, from the brow forward and up (turned with the head).
        turned(s, nod, about: (35, 27)) {
            $0.pattern(42, 8, ["......L", "....GL.", "..gG...", ".Gg....", "gG....."],
                       ["G": C(0xF0C850), "g": C(0xB08A2A), "L": C(0xFFF0B0)])
        }
        wing(s, root: root, edge: -158 + 58 * spread, feathers: 165 - 50 * spread, length: 14 + 5 * spread, near: true)
    }
    if !p.trail.isEmpty, let a = p.melee {
        // A streak behind the horn on a fast charge.
        let n = max(-16, min(22, (a + 60) * 0.25)) * .pi / 180
        let tipX = 35 + 16 * cos(-0.95 + n) + Double(lunge), tipY = 27 + 16 * sin(-0.95 + n)
        c.glowLine(tipX - 8, tipY + 1, tipX, tipY, core: C(0xFFF0F8, 0.5), glow: C(0xFF90D0, 0.3), coreR: 0.5, glowR: 1.6)
    }
}

// MARK: - Bow

/// Bow: the Rebellion's archer. Short dark-brown hair swept back, a thin dark moustache, a red shirt with a pink
/// heart on his chest, a brown belt with a gold buckle, brown bracers and boots, a blue cape and a quiver over his
/// back. His bow is a golden-tan recurve, an arrow nocked and drawn back before he looses it. Signature: he holds the
/// bow up and plucks its string like a harp, the string trembling and little notes floating off it.
private func drawBow(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x4A2E1E), hairD = C(0x2E1C12), hairL = C(0x6E4A32)
    let shirt = C(0xC83838), shirtD = C(0x902424), shirtL = C(0xE45A50), heart = C(0xFFA8C0)
    let cape = C(0x3A5AC8), capeD = C(0x26409A), brown = C(0x6A4428), brownL = C(0x8A5E38), brownD = C(0x4A2E1A)
    let s = p.signature ?? -1
    let harp = s > 0.08 && s < 0.92

    backCape(c, t: p.t, speed: p.capeSpeed, cape, capeD, capeD, hem: 40)
    // The quiver over his back, the fletchings over his shoulder.
    c.pattern(11, 19, [
        "W.W.....",
        "WW.W....",
        ".WWW....",
        "..QQQ...",
        "..QqQq..",
        "...QQQq.",
        "...QqQQ.",
        "....QQQq",
        "....QqQQ",
        ".....QQq",
    ], ["W": C(0xF0ECE0), "Q": brown, "q": brownD])
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, brown, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 1, brownL); c.px(lx + 1, bottom, brownD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: shirt))
    // The red shirt from the collar down: lit on top, shaded on the far side, the heart on his chest, the quiver
    // strap across it, the belt with its buckle.
    c.rect(18, 34, 20, 4, shirt); c.rect(18, 34, 20, 1, shirtL); c.rect(37, 34, 1, 4, shirtD)
    c.rect(18, 37, 20, 1, shirtD)
    c.pattern(26, 35, ["HH.HH", "HHHHH", ".HHH."], ["H": heart])
    c.px(26, 35, C(0xFFD8E2))
    c.rect(20, 35, 1, 2, shirtD); c.rect(34, 35, 1, 2, shirtD)    // folds
    c.rect(15, 35, 3, 1, brown)                                   // the bracer on his back arm
    // The moustache, a bushy dark bar under his nose drooping at both ends, and his hair swept back off his brow
    // in long strokes.
    c.pattern(23, 32, [".MMMMMMMMMM.", "MMm......mMM"], ["M": hairD, "m": hair])
    c.pattern(17, 21, [
        "....HHHHHHHHHHHH.....",
        "..HHHHlllHHHHHHHHH...",
        ".HHlllHHHHHhhHHHHHH..",
        "HHHHHHhhHHHHHHhhHHHH.",
        "HHhhHHHHHHhhhHHHHHhHH",
        "HHH...hhHHH....hhHHHH",
        "HH..................H",
        "Hh..................h",
    ], ["H": hair, "h": hairD, "l": hairL])

    // The bow, held out at arm's length; while harping, held up a little with his other hand at the string.
    var pull = 0, nocked = p.ready && !harp
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        nocked = ph >= 0.45
        if ph > 0.6 { pull = Int(((ph - 0.6) / 0.4 * 3).rounded()) }
    }
    let lift = harp ? -2 : seatedPose ? -3 : 0
    c.oy += p.gunY + lift
    let twang = harp && Int(p.t * 12) % 2 == 0 ? 1 : 0
    // The recurve: tan limbs bending back at the tips, a dark grip, the string.
    let limb = C(0xC89A48), limbD = C(0x8A6A2A), grip = C(0x4A3420), string = C(0xF0F0F4)
    for y in 25...43 where y + c.oy <= 43 {
        let d = abs(y - 34)
        let x = d <= 2 ? 46 : d <= 5 ? 45 : d <= 8 ? 44 : 45
        c.px(x, y, d <= 1 ? grip : d % 3 == 0 ? limbD : limb)
    }
    for y in 26...42 where y + c.oy <= 43 {
        let d = Double(abs(y - 34)) / 8
        let bend = Double(pull) * (1 - d) + Double(twang) * (1 - d) * 1.2
        c.px(42 - Int(bend.rounded()), y, string)
    }
    c.rect(38, 33, 6, 2, shirt); c.rect(44, 33, 2, 3, clawdOrange)
    c.rect(42, 33, 2, 2, brown); c.px(42, 33, brownL)              // the bracer
    if nocked {
        let tail = 42 - pull
        c.rect(tail, 34, 49 - tail, 1, C(0x6A4A2A))
        c.px(49, 34, C(0xC8CCD4)); c.px(50, 34, C(0xE8ECF4))
        c.px(tail, 33, C(0xF0ECE0)); c.px(tail, 35, C(0xF0ECE0))
        c.rect(tail - 1, 34, 2, 2, clawdOrange)
    }
    if harp {
        c.rect(41 - twang, 29 + (Int(p.t * 6) % 2) * 2, 2, 2, clawdOrange)   // his fingers at the string
        // The notes, floating up off the string, bright on a dark desktop, fading only at the end.
        for i in 0..<3 {
            let f = frac(p.t * 0.9 + Double(i) / 3)
            let x = 48 + i * 4 + Int(f * 5), y = 28 - Int(f * 14)
            guard f < 0.85 else { continue }
            c.pattern(x, y, ["..NN.", "..N.N", "..N..", "NNN..", "NN..."],
                      ["N": i % 2 == 0 ? C(0xFFF4A8) : C(0xFFC0DC)])
        }
    }
}

// MARK: - Glimmer

/// Glimmer: the Princess of Bright Moon. Long dark-red hair down her back and over her shoulder, a pink tunic with
/// pink sleeves, a purple belt with a pink gem, a purple skirt and purple boots. Her magic is a bright white ray with
/// a pink glow from her palm. Signature: she holds out her palm and a glowing ball of light swells in it, sparkles
/// circling it, then fades.
private func drawGlimmer(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x9A2A3E), hairD = C(0x681A2A), hairL = C(0xC44A5E)
    let pink = C(0xEC70B0), pinkD = C(0xB84A86), pinkL = C(0xFFA0CC)
    let purple = C(0x7A3AB0), purpleD = C(0x542484), purpleL = C(0x9A5ACC)
    let s = p.signature ?? -1
    let ball = s < 0 ? 0 : habitArc(s, hold: 0.6)
    let palm = ball > 0.05 ? 3 : 0
    let raise = max(p.armRaise, palm)

    // Her long hair down her back, in strands.
    for (i, x) in [15, 16, 17].enumerated() { c.rect(x, 27, 1, 11 - i % 2, i % 2 == 0 ? hair : hairD) }
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, purple, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 1, purpleL); c.px(lx + 1, bottom, purpleD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: pink), armRight: raise)
    // The pink tunic, a scooped neckline, folds; the purple belt and gem; the purple skirt over her legs.
    c.rect(18, 34, 20, 2, pink); c.rect(37, 33, 1, 3, pinkD)
    c.rect(18, 33, 5, 1, pinkL); c.rect(33, 33, 4, 1, pinkL)
    c.rect(23, 34, 10, 1, pinkL)
    c.rect(21, 34, 1, 2, pinkD); c.rect(34, 34, 1, 2, pinkD)
    c.rect(15, 35, 3, 1, pinkD); c.rect(38, 35 - raise, 3, 1, pinkD)
    c.rect(18, 36, 20, 1, purpleD); c.rect(27, 36, 2, 1, pinkL)
    for y in 37...39 where y + c.oy <= 42 {
        let w = y - 37
        c.rect(18 - w / 2, y, 20 + w, 1, purple)
        for x in [22, 27, 32] { c.px(x, y, purpleD) }
        c.px(18 - w / 2, y, purpleL)
    }
    // The hair: parted in the middle, a soft fringe, long either side, falling over her near shoulder.
    c.pattern(15, 20, [
        ".......HHHHHHHHHH.......",
        ".....HHHHlHHHHHlHHHH....",
        "...HHHlHHHHhhHHHHHHHHH..",
        "..HHHhHHHHHhhHHHHHhHHHH.",
        "..HHhHHHHHhhhhHHHHHhHHH.",
        ".HHhHHHHHhHHHHhHHHHHhHHH",
        ".HHhhHh..........hHhhHHH",
        ".HHh..............hhHHHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HhH..................hHH",
        "Hh...................hH.",
        ".h....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])

    if ball > 0.05 {
        // The ball of light in her palm: a white core in a pink glow, see-through, sparkles going round it.
        let bx = 41.0, by = Double(33 - raise) - 3.5
        let pulse = 0.9 + 0.1 * sin(p.t * 14)
        c.glowLine(bx, by, bx, by, core: C(0xFFFFFF, 0.95 * ball), glow: C(0xFF6AB8, 0.85 * ball), coreR: 1.2 * ball,
                   glowR: (1.6 + 2.6 * ball) * pulse)
        for k in 0..<3 {
            let a = p.t * 5 + Double(k) * 2.1
            let x = Int((bx + cos(a) * 5).rounded()), y = Int((by + sin(a) * 3).rounded())
            c.px(x, y, C(0xFFE8F4, 0.9 * ball))
        }
    }
}

// MARK: - Madame Razz

/// Madame Razz: the little Twigget witch of the Whispering Woods. A tall purple pointed hat, its tip flopping back, a
/// wide brim, wisps of grey hair under it, a green shawl knotted over a long rose-red dress, and little black shoes.
/// Broom, her living broom, stands at her side with two goggling eyes on his binding. Her magic is a touch: a pink
/// glowing fingertip. Signature: she climbs aboard Broom, wobbles about on him, and falls off; Broom carries on
/// without her, and she sits there with stars round her hat.
private func drawMadameRazz(_ c: PixelCanvas, _ p: Pose) {
    let hat = C(0x7A3AA8), hatD = C(0x54247A), hatL = C(0x9A5ACC)
    let shawl = C(0x3A9A4A), shawlD = C(0x26703A), shawlL = C(0x5ABA6A)
    let dress = C(0xA83A5E), dressD = C(0x7A2440), dressL = C(0xC85A7A), wisp = C(0xD0D0D8)
    let s = p.signature ?? -1
    // 0…0.2 Broom slides under her and she climbs up; 0.2…0.66 she rides, wobbling; 0.66…0.74 she falls; then she sits,
    // dazed, and Broom comes back to her side.
    let up = s < 0 ? 0 : s < 0.2 ? s / 0.2 : s < 0.66 ? 1 : s < 0.74 ? 1 - (s - 0.66) / 0.08 : 0
    let lift = Int((up * 3).rounded())
    let wobble = s > 0.25 && s < 0.7 ? sin(p.t * 9) * 6 : s >= 0.66 && s < 0.74 ? -25 * (s - 0.66) / 0.08 : 0
    let riding = s > 0.08 && s < 0.7
    let dazed = s >= 0.74 && s < 0.97
    let broomAway = s >= 0.66 && s < 0.9
    let t = p.t

    // Broom standing at her side (when he isn't under her): a brown handle, a straw head, a red binding with eyes.
    if !riding && !broomAway {
        let hop = Int(frac(t * 0.8) * 10) == 0 ? -1 : 0
        let bx = 9, by = 18 + hop
        c.rect(bx + 2, by, 2, 16, C(0x8A5A30)); c.rect(bx + 2, by, 1, 16, C(0xAA7A48))
        c.rect(bx, by + 16, 6, 2, C(0xC83A3A)); c.px(bx + 1, by + 16, white); c.px(bx + 4, by + 16, white)
        c.px(bx + 1, by + 17, ink); c.px(bx + 4, by + 17, ink)
        c.pattern(bx - 1, by + 18, [
            "SSSSSSSS",
            "SsSSsSSs",
            "SSsSSsSS",
            "SsSSsSsS",
            "sSsSSsSs",
            "S.sS.sSS",
        ], ["S": C(0xE0C060), "s": C(0xB0902E)])
    }

    turned(c, wobble, about: (28, 40)) { k in
        k.oy = -lift
        if riding && up > 0.5 {
            // Broom under her, flying level: the handle forward, the straw out behind, his eyes on the binding.
            k.rect(14, 41, 34, 2, C(0x8A5A30)); k.rect(14, 41, 34, 1, C(0xAA7A48))
            k.rect(14, 40, 3, 4, C(0xC83A3A)); k.px(15, 40, white); k.px(15, 41, ink)
            k.pattern(6, 39, ["SSSSSSSS", "sSSsSSsS", "SsSSsSSs", "SSsSSsSS", "sSSsS.sS"], ["S": C(0xE0C060), "s": C(0xB0902E)])
        }
        // Her legs in black stockings under the dress, and little black shoes.
        drawLegs(k, Look(leg: C(0x2E2A34)), step: riding ? -1 : p.step)
        drawBoots(k, C(0x16141A), step: riding ? -1 : p.step, rows: 1)
        k.oy += p.breathe
        drawBody(k, Look(arm: dress), armRight: riding ? 2 : p.armRaise)
        // The long dress: from the shawl to just above her shoes, flaring, a shadow either side of each leg.
        k.rect(18, 35, 20, 3, dress)
        for y in 38...40 where y + k.oy <= 41 {
            let flare = y - 38
            k.rect(18 - flare / 2, y, 20 + flare, 1, dress)
            k.px(18 - flare / 2, y, dressL); k.px(37 + flare / 2, y, dressD)
            if y >= 39 { for x in [21, 25, 29, 33] { k.px(x, y, dressD) } }
        }
        k.rect(18, 34, 1, 4, dressL); k.rect(37, 34, 1, 4, dressD)
        // The green shawl over her shoulders, crossed and knotted at the front, its fringe hanging.
        k.pattern(16, 33, [
            "SSSSSS..........SSSSSS",
            ".sSSSSSSSS..SSSSSSSSs.",
            "..sSSSSSSSKKSSSSSSSs..",
            "...f.f.f.sKKs.f.f.f...",
        ], ["S": shawl, "s": shawlD, "K": shawlD, "f": shawlL])
        k.rect(16, 33, 5, 1, shawlL); k.rect(22, 34, 12, 1, dress)
        // Wisps of grey hair either side under the brim.
        k.pattern(16, 26, ["WW.................WW", "W.W...............W.W", "W..................W."], ["W": wisp])
        // The hat: a wide brim shading her brow, a tall crown with a band, its tip flopping back.
        k.pattern(12, 7, [
            ".TTTTT.................",
            "TT..TTH................",
            ".....HHH...............",
            "......HHH..............",
            "......HHHH.............",
            ".......HLHH............",
            ".......HLHHH...........",
            "......HHLHHHH..........",
            "......HLHHHHH..........",
            ".....HHLHHHHHH.........",
            ".....HLHHHHHHHH........",
            "....HHLHHHHHHHHH.......",
            "....bbbbbbbbbbbbb......",
            "....HLHHHHHHHHHHHH.....",
            "..BBBBBBBBBBBBBBBBBBBB.",
            "BBBBBBBBBBBBBBBBBBBBBBBB",
            ".dddddddddddddddddddddd.",
        ], ["T": hatD, "H": hat, "L": hatL, "b": C(0x3A9A4A), "B": hat, "d": hatD])
        k.rect(16, 21, 6, 1, hatL)
        k.rect(19, 24, 18, 1, C(0x9A5A3A))   // the brim's shadow on her brow
        k.oy -= p.breathe
    }
    if broomAway {
        // Broom flying off without her, and back.
        let f = (s - 0.66) / 0.24
        let x = 30 + Int(sin(f * .pi) * 18)
        c.rect(x, 40, 18, 1, C(0x8A5A30)); c.rect(x, 39, 2, 3, C(0xC83A3A)); c.px(x, 39, white)
        c.pattern(x - 6, 38, ["SSSSSS", "sSSsSS", "SsSSsS", "SSsSS."], ["S": C(0xE0C060), "s": C(0xB0902E)])
    }
    if dazed {
        // Stars going round her hat.
        for k in 0..<3 {
            let a = t * 6 + Double(k) * 2.1
            let x = Int((26 + cos(a) * 9).rounded()), y = Int((18 + sin(a) * 2).rounded())
            c.pattern(x - 1, y - 1, [".S.", "SSS", ".S."], ["S": C(0xFFE860, 0.95)])
        }
    }
}

// MARK: - Kowl

/// Kowl: the know-it-all koala-owl. Round and grey, the body's corners rounded off, big round koala ears with pale
/// insides, pale grey disks round his eyes, a big dark nose, a cream feathered belly, little grey wings for arms and
/// yellow feet. He flies, flapping hard. Signature: he folds his wings across his belly and rolls his eyes.
private func drawKowl(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x8E909A), furD = C(0x6A6C78), furL = C(0xB0B2BC), disk = C(0xC8CAD2)
    let belly = C(0xE2DCCC), bellyD = C(0xC0B8A6), inner = C(0xE0BCC6), foot = C(0xE8B840)
    let s = p.signature ?? -1
    let folded = s > 0.08 && s < 0.92
    let roll = s > 0.25 && s < 0.85 ? (s - 0.25) / 0.6 : -1

    // Short grey legs and yellow feet.
    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 3, 1, foot); c.px(lx + 1, bottom - 1, furD)
        }
    }
    c.oy += p.breathe
    let flap = p.flying ? Int((sin(p.t * 18) * 3).rounded()) : 0
    // The round body: Clawd's block with its corners rounded off, lit along the top, shaded on the far side.
    c.rect(18, 27, 20, 10, fur); c.rect(19, 26, 18, 1, furL); c.rect(19, 37, 18, 1, furD); c.rect(37, 27, 1, 10, furD)
    // The big round ears, lit on top, pale inside.
    c.pattern(13, 18, [
        "..EEEE..................EEEE..",
        ".EELLEE................ELLEEE.",
        "EELIIIEE..............EEIIIEEE",
        "ELIIIIIE..............EIIIIIEe",
        "EEIIIIEE..............EEIIIIEe",
        ".EEIIEE................EEIIEe.",
        "..EEEE..................EEee..",
    ], ["E": fur, "e": furD, "L": furL, "I": inner])
    // Tufts of fur round the ears' outer edges, in short strokes.
    c.pattern(11, 17, [
        "..T.T.......................T.T..",
        ".T..........................t..t.",
        "T..............................t.",
        ".T.............................t",
        "T..............................t.",
    ], ["T": furL, "t": fur])
    // The cream belly, in feather strokes.
    c.pattern(22, 33, [
        ".BBBBBBBBBBB.",
        "BBbBBBbBBBbBB",
        "BBBBbBBBbBBBB",
        ".BbBBBbBBBbB.",
    ], ["B": belly, "b": bellyD])
    // The disks round his eyes and his eyes in them; while he rolls them, white with a pupil going round the top,
    // the lids half down.
    c.rect(21, 28, 4, 5, disk); c.rect(31, 28, 4, 5, disk)
    if roll >= 0 {
        let a = Double.pi * (1 + roll)   // left, over the top, to the right
        let dx = Int((cos(a) * 0.9).rounded()), dy = Int((sin(a) * 1.2).rounded())
        for ex in [22, 32] {
            c.rect(ex - 1, 29, 4, 3, white)
            c.rect(ex + dx, 30 + dy, 2, 2, ink)
            c.rect(ex - 1, 28, 4, 1, furD)   // the lid
        }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.px(22, 29, C(0x5A5A66)); c.px(32, 29, C(0x5A5A66))
    }
    // The nose, big and dark, between his eyes and a little below, with a shine.
    c.pattern(26, 31, [".NNNN.", "NnNNNN", ".NNNN."], ["N": C(0x34303C), "n": C(0x6A6674)])
    c.rect(19, 27, 2, 1, furL); c.rect(23, 33, 1, 1, furD); c.rect(33, 33, 1, 1, furD)

    if folded {
        // The wings folded across his belly, one over the other.
        c.pattern(17, 33, [
            "WWWWWWWWWw.........",
            ".wWWWWWWWWWw.......",
            "..wwWWWWWWWWWw.....",
        ], ["W": fur, "w": furD])
        c.pattern(23, 34, [
            ".......wWWWWWWWWWW",
            ".....wWWWWWWWWWWw.",
            "...wWWWWWWWWWww...",
        ], ["W": furL, "w": furD])
    } else {
        // The little wings: three feathers each, out at his sides, flapping in flight.
        c.pattern(12, 31 - flap, ["..WWWW", ".WWLWW", "WWWWWW", "wW.wW.", "w..w.."], ["W": fur, "L": furL, "w": furD])
        c.pattern(38, 31 - flap, ["WWWW..", "WWLWW.", "WWWWWW", ".Ww.Ww", "..w..w"], ["W": fur, "L": furL, "w": furD])
    }
}
