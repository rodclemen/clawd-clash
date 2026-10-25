import Foundation

// Villains: Skeleclawd and the Evil Warriors of Snake Mountain, drawn the same way as the heroes.

let eterniaVillains1: [EterniaVillain: Persona] = [
    .skeleclawd: Persona(name: "Skeleclawd", weapon: .lightning,
                         magic: Magic(core: C(0xF4F070), glow: C(0x8A3ADC)),
                         pivot: (44, 15), headTop: 16, signature: 3.2, callout: "Fools! Greyskull will be mine!",
                         draw: drawSkeleclawd),
]

// MARK: - Skeleclawd

/// Skeleclawd: the Lord of Destruction. A yellow skull for a face, its sockets black, under a purple hood with a ridge
/// down its crown; a blue body, a black harness crossed over his chest with a little bone skull at the crossing,
/// purple fur briefs, black bracers and dark purple boots. He carries the Havoc Staff, a purple shaft topped with a
/// ram's skull, its horns curled, and his forked yellow and violet bolts come out of it. Signature: he shakes his fist
/// and cackles, his jaw clacking.
private func drawSkeleclawd(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x3A62B8), blueD = C(0x284898), hood = C(0x6A3A9A), hoodD = C(0x4A2470), hoodL = C(0x8A5ABA)
    let bone = C(0xE8D85A), boneD = C(0xB8A834), boneL = C(0xFFF09A), ink = C(0x141018)
    let strap = C(0x1E1A22), strapL = C(0x3E3A46), fur = C(0x6A3A8A), furD = C(0x48246A), furL = C(0x8A5AAA)
    let s = p.signature ?? -1
    let shake = s > 0.08 && s < 0.92
    let fist = shake ? 6 + Int((sin(p.t * 22) * 1.5).rounded()) : 0
    let jaw = shake && Int(p.t * 10) % 2 == 0

    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, C(0x3A1E52), step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, C(0x5A3A72)) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: blue, shade: blueD, arm: blue, eye: nil), armLeft: fist, armRight: p.armRaise)
    c.rect(15, 34 - fist, 3, 1, strap); c.rect(38, 34 - p.armRaise, 3, 1, strap)   // the bracers

    // The skull: domed brow lit on the left, black sockets, the nose hole, cheekbones, and the grin of teeth.
    c.pattern(20, 25, [
        "..BBBBBBBBBBBB..",
        ".BLLBBBBBBBBBBB.",
        "BLBBBBBBBBBBBBBd",
        "BBKKKBBBBBKKKBBd",
        "BKKKKKBBBKKKKKBd",
        "BBKKKBBkBBKKKBBd",
        ".BBBBBkkkBBBBBd.",
        "..dBBBBBBBBBdd..",
    ], ["B": bone, "L": boneL, "K": ink, "k": C(0x4A3A1A), "d": boneD])
    c.pattern(22, 33, jaw ? ["TKTKTKTKTKT", "...........", "TKTKTKTKTKT"] : ["TKTKTKTKTKT", "KKKKKKKKKKK"],
              ["T": C(0xF4EAC0), "K": ink])

    // The hood round it, a ridge down its crown and a lit run along the top, its edge shading the brow.
    drawHood(c, hood, hoodD)
    c.rect(20, 25, 2, 1, hoodD); c.rect(34, 25, 2, 1, hoodD)
    c.rect(26, 17, 4, 2, hood); c.rect(27, 16, 2, 1, hoodL); c.rect(27, 17, 1, 3, hoodL)
    c.rect(22, 20, 4, 1, hoodL); c.px(19, 21, hoodL)
    if fist > 0 {   // the shaken fist, up in front of the hood's edge, and his arm under it
        c.rect(12, 33 - fist, 3, 3, blue); c.rect(12, 35 - fist, 3, 1, strap); c.px(12, 33 - fist, C(0x5A82D8))
        c.rect(14, 36 - fist, 2, fist - 2, blue)
    }

    // The harness: black straps crossed over his chest, the little bone skull at the crossing.
    c.pattern(18, 33, [
        "SS..............SS",
        ".SSS..........SSS.",
        "...SSSS....SSSS...",
    ], ["S": strap])
    c.px(19, 33, strapL); c.px(36, 33, strapL)
    c.pattern(26, 34, ["BBBB", "BKKB", ".BB."], ["B": bone, "K": ink])
    // The purple fur briefs on a black belt.
    c.rect(18, 36, 20, 1, strap)
    eterniaFur(c, 18, 37, 20, 1, base: fur, dark: furD, light: furL)

    // The Havoc Staff: the shaft from his fist down to the ground and up over his head, the ram's skull on top with
    // its horns curled down either side and its eyes glowing while he casts.
    let raise = p.armRaise
    let shaft = C(0x5A2E7A), shaftL = C(0x7A4A9A)
    let top = 13 - raise
    c.rect(41, top + 4, 2, 43 - (top + 4) - (seatedPose ? 4 : 0), shaft); c.rect(41, top + 4, 1, 26, shaftL)
    c.pattern(38, top, [
        "HH.BBBB.HH",
        "H.BLBBBB.H",
        "HHBKBBKBHH",
        ".H.BBBB.H.",
        "....BB....",
    ], ["B": C(0xD8D4C8), "L": C(0xF4F2EA), "K": raise > 0 ? C(0xF4F070) : ink, "H": C(0x8A8478)])
    c.rect(38, 33 - raise, 3, 3, blue); c.rect(38, 34 - raise, 3, 1, strap)   // the fist round the shaft
}
