import Foundation

// Villains: Hordakk and the Evil Horde of the Fright Zone, and the small fry who only ever turn up as agents (Hordakk's
// spy, his foot soldiers and Skeleclawd's bird), drawn the same way as EterniaVillains1.swift.

let eterniaVillains3: [EterniaVillain: Persona] = [
    .hordakk: Persona(name: "Hordakk", weapon: .blaster, shot: .energy(core: C(0xFFF4F2), glow: C(0xD0102E)),
                      muzzle: (48, 33), handGun: false, headTop: 16, signature: 3.4, draw: drawHordakk),
    .shadowWeaver: Persona(name: "Shadow Weaver", weapon: .lightning,
                           magic: Magic(core: C(0xFF5470), glow: C(0x9A0E2A), jagged: false, waves: true),
                           headTop: 14, signature: 3.6, draw: drawShadowWeaver),
    .katra: Persona(name: "Katra", weapon: .saber, headTop: 16, signature: 3.4, draw: drawKatra),
    .scorpia: Persona(name: "Scorpia", weapon: .saber, headTop: 19, signature: 3.0, draw: drawScorpia),
    .mantenna: Persona(name: "Mantenna", weapon: .blaster, shot: .beam(core: C(0xFFD8D0), glow: C(0xE81A1A)),
                       muzzle: (36, 22), handGun: false, headTop: 20, signature: 3.2, draw: drawMantenna),
    .imp: Persona(name: "Imp", headTop: 20, signature: 3.6, draw: drawImp),
    .hordeTrooper: Persona(name: "Horde Trooper", weapon: .blaster, shot: .energy(core: C(0xFFD8D0), glow: C(0xE8281E)),
                           armoured: true, muzzle: (50, 33), headTop: 19, signature: 3.2, draw: drawHordeTrooper),
    .screeech: Persona(name: "Screeech", motion: .fly, headTop: 20, signature: 2.6, draw: drawScreeech),
]

// MARK: - Shared bits

/// 0 before `a`, 1 after `b`, a straight run between.
private func hordeRamp(_ s: Double, _ a: Double, _ b: Double) -> Double { min(1, max(0, (s - a) / (b - a))) }

/// A plain chest plate from row 33 to 37, its top edge dark so it parts cleanly from the face, lit under that.
private func hordePlate(_ c: PixelCanvas, plate: Px, plateD: Px, plateL: Px) {
    c.rect(20, 33, 16, 5, plate); c.rect(20, 33, 16, 1, plateD); c.rect(20, 34, 16, 1, plateL)
    c.rect(35, 34, 1, 4, plateD); c.rect(20, 37, 16, 1, plateD)
}

/// The Horde's red bat, ears up and wings raised, 9 wide and 4 high, its top-left corner at (`x`, `y`). It goes on the
/// brow, above the eyes: anything red and spiky on the chest just under Clawd's eyes reads as a grinning mouth.
private func hordeBat(_ c: PixelCanvas, _ x: Int, _ y: Int, red: Px, redD: Px) {
    c.pattern(x, y, [
        "R..R.R..R",
        "RR.RRR.RR",
        ".RRRdRRR.",
        "...R.R...",
    ], ["R": red, "d": redD])
}

// MARK: - Hordakk

/// Hordakk: the ruthless leader of the Evil Horde, Skeleclawd's old teacher. A white face like a mask, its red eyes
/// glaring under heavy brows, an upturned pig's snout and a grim black mouth, all inside a smooth bony grey cowl with a
/// keel fin down the crown and two bat-ear points on top; a dark navy suit, the Horde's red bat on a steel chest plate,
/// bone-grey bracers and boot cuffs. No skull, no teeth and no purple, so he never reads as Skeleclawd. He fights with
/// his own right arm, which turns into a steel cannon to fire white and crimson bolts. Signature: the arm turns into
/// the cannon and back while he snorts with laughter, puffs of breath out of his snout.
private func drawHordakk(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x262C52), suitD = C(0x181C38), suitL = C(0x3C4676)
    let mask = C(0xF2F0EA), maskD = C(0xC4C0B8), maskL = C(0xFFFFFF), snout = C(0xE4D8D2), ink = C(0x141018)
    let bone = C(0x9E9A92), boneD = C(0x6E6A64), boneL = C(0xCCC8BE)
    let red = C(0xD0202A), redD = C(0x8A1018), glare = C(0xFF3A24), glareL = C(0xFFB8A0)
    let steel = C(0x8A8E9C), steelD = C(0x5A5E6C), steelL = C(0xB8BCC8)
    let s = p.signature ?? -1
    let morph = s < 0 ? 0 : hordeRamp(s, 0.08, 0.3) * (1 - hordeRamp(s, 0.74, 0.92))
    let armed = p.fire != nil || p.gunLift > 0 || p.smoke != nil
    let cannon = armed ? 1 : morph
    let laughing = s > 0.34 && s < 0.72
    let snort = laughing && Int(p.t * 7) % 2 == 0

    // Navy legs, black boots with a bony cuff round the top.
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x12142A), step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 1, boneD); c.px(lx, bottom - 3, bone)
        }
    }
    c.oy += p.breathe + (snort ? -1 : 0)
    drawBody(c, Look(body: suit, shade: suitD, arm: suit, eye: nil))
    c.rect(18, 32, 1, 5, suitL)
    c.rect(15, 33, 3, 1, boneD); c.px(15, 33, bone)   // the bracer on his far wrist

    // A plain steel chest plate (the bat is on his brow).
    hordePlate(c, plate: steel, plateD: steelD, plateL: steelL)

    // The face: a white mask lit at the top left, heavy black brows, red eyes, the upturned snout and the grim mouth.
    c.pattern(20, 25, [
        "..WWWWWWWWWWWW..",
        ".WLLWWWWWWWWWWW.",
        "WLKKKWWWWWWKKKWd",
        "WWRRrKWWWWKrRRWd",
        "WWRRRWWWWWWRRRWd",
        "WWWWWWddddWWWWWd",
        "WWWWWdSKSKSdWWWd",
        ".WWWdKKKKKKdWWd.",
    ], ["W": mask, "L": maskL, "d": maskD, "K": ink, "R": glare, "r": glareL, "S": snout])

    // The bony cowl: one smooth shell of bone round his face, polished to a shine on the dome and shaded down the far
    // side, a raised keel down the middle that stands up off the crown as a fin, a dark rim where it meets the mask,
    // and the two bat-ear points standing up off the top. No ribs across it: lines across a grey hood read as hair.
    drawHood(c, bone, boneD)
    c.rect(22, 19, 5, 1, boneL); c.rect(20, 20, 4, 1, boneL); c.rect(19, 21, 2, 2, boneL); c.px(18, 23, boneL)
    c.rect(16, 25, 1, 5, boneL); c.px(17, 24, boneL)
    c.rect(36, 21, 1, 3, boneD); c.rect(37, 22, 1, 9, boneD); c.rect(38, 25, 1, 7, boneD); c.px(39, 29, boneD)
    c.rect(19, 24, 18, 1, boneD); c.rect(19, 25, 1, 7, boneD); c.rect(36, 25, 1, 7, boneD)
    c.pattern(26, 16, [".LD.", "LLDD", "LLDD", ".LD.", ".LD.", ".LD.", ".LD."], ["L": boneL, "D": boneD])
    c.px(20, 16, bone); c.rect(20, 17, 2, 1, bone); c.rect(20, 18, 3, 1, bone); c.px(20, 17, boneL)
    c.px(35, 16, bone); c.rect(34, 17, 2, 1, bone); c.rect(33, 18, 3, 1, bone); c.px(35, 17, boneD)
    // The Horde's red bat on the cowl's brow, like a crest, on a dark plate so it stands off the bone.
    c.pattern(22, 20, [".DDDDDDDDD.", "DDDDDDDDDDD", "DDDDDDDDDDD", ".DDDDDDDDD."], ["D": boneD])
    hordeBat(c, 23, 20, red: red, redD: redD)

    // The right arm: a plain gauntleted fist, or, as it changes, a steel cannon growing out of it, red bands round the
    // barrel and a heavy ring at the muzzle.
    c.oy += p.gunY
    let len = Int((cannon * 8).rounded())
    if len <= 1 {
        c.rect(38, 33, 3, 1, boneD); c.px(38, 33, bone)
    } else {
        c.rect(38, 32, len, 4, steel); c.rect(38, 32, len, 1, steelL); c.rect(38, 35, len, 1, steelD)
        c.rect(40, 32, 1, 4, red)
        if len >= 6 { c.rect(43, 32, 1, 4, redD) }
        c.rect(38 + len, 31, 2, 6, steelD); c.rect(38 + len, 31, 2, 1, steel)
        c.rect(39 + len, 33, 1, 2, p.fire != nil ? C(0xFFE0E0) : ink)
        if cannon < 1 {   // a crimson shimmer where flesh turns to steel
            c.glowLine(38.5, 33.5, 38.5 + Double(len), 33.5, core: C(0xFF8A9A, 0.25), glow: C(0xE8203A, 0.35),
                       coreR: 0.4, glowR: 2.2)
        }
    }
    c.oy -= p.gunY

    // The snorts: little puffs of breath blown out of his snout, forward and down, fading.
    if laughing {
        let f = (p.t * 3.5).truncatingRemainder(dividingBy: 1)
        let a = (1 - f) * 0.55
        c.rect(30 + Int(f * 6), 32 + Int(f * 2), 2, 1, C(0xFFFFFF, a))
        c.px(31 + Int(f * 8), 33 + Int(f * 2), C(0xFFFFFF, a * 0.7))
    }
}

// MARK: - Shadow Weaver

/// Shadow Weaver: the Horde's sorceress, who brought up Adorra in the Fright Zone. A long crimson robe to the ground,
/// its skirts shaded between her feet, wide bell sleeves lined in black, a black sash with a gold knot, and a tall
/// peaked hood over a face that is only blackness, two glowing yellow eyes in it. A red robe like the Emperor's Royal
/// Guards, but nobody else has the black face and the eyes, and she casts: pulses of crimson shadow from her sleeves,
/// lit bright at the edge so they show against the dark. Signature: she raises both hands and weaves them round each
/// other, curls of shadow winding round her fingers.
private func drawShadowWeaver(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xB01E2C), robeD = C(0x781220), robeL = C(0xD8404E), lining = C(0x1E0A12)
    let face = C(0x0A070A), eye = C(0xFFE27A), hand = C(0x4A3A4A), gold = C(0xD8A838), goldD = C(0x9A7420)
    let s = p.signature ?? -1
    let weave = s < 0 ? 0 : hordeRamp(s, 0.05, 0.2) * (1 - hordeRamp(s, 0.82, 0.95))
    let wob = sin(p.t * 6) * weave
    let frontUp = max(p.armRaise, Int((weave * 5 + wob * 1.5).rounded()))
    let backUp = Int((weave * 5 - wob * 1.5).rounded())

    // The feet, black, peeping out under the hem; then the skirts, drawn with the legs so the hem never bobs.
    drawLegs(c, Look(leg: lining), step: p.step)
    let hem = seatedPose ? 39 : 42
    for y in 37...hem {
        let flare = (y - 37) / 2
        c.rect(17 - flare, y, 22 + 2 * flare, 1, y == hem ? robeD : robe)
        c.px(17 - flare, y, robeL); c.px(38 + flare, y, robeD)
        if y >= 39 && y < hem { for x in [22, 27, 30, 34] { c.px(x, y, robeD) } }
    }

    c.oy += p.breathe
    drawBody(c, Look(body: robe, shade: robeD, arm: robe, eye: nil), armLeft: backUp, armRight: frontUp)
    // The bodice: folds down it, lit on the left, the black sash and its gold knot.
    c.rect(18, 26, 1, 11, robeL)
    for x in [22, 29, 34] { c.rect(x, 33, 1, 3, robeD) }
    c.rect(18, 36, 20, 1, lining); c.rect(26, 36, 2, 1, gold); c.px(27, 37, goldD)
    // The bell sleeves, black inside, and her grey hands.
    c.rect(37, 32 - frontUp, 5, 4, robe); c.rect(37, 32 - frontUp, 5, 1, robeL); c.rect(41, 33 - frontUp, 1, 3, lining)
    c.rect(42, 34 - frontUp, 1, 2, hand)
    c.rect(14, 32 - backUp, 5, 4, robe); c.rect(14, 32 - backUp, 5, 1, robeL); c.rect(14, 33 - backUp, 1, 3, lining)
    c.rect(13, 34 - backUp, 1, 2, hand)

    // The face: nothing but blackness inside the hood, and two glowing eyes.
    c.rect(19, 25, 18, 7, face)
    c.rect(22, 29, 2, 1, eye); c.rect(32, 29, 2, 1, eye)
    c.glowLine(22.5, 29.5, 23.5, 29.5, core: C(0xFFF4C0, 0.0), glow: C(0xFFC040, 0.45), coreR: 0.2, glowR: 1.6)
    c.glowLine(32.5, 29.5, 33.5, 29.5, core: C(0xFFF4C0, 0.0), glow: C(0xFFC040, 0.45), coreR: 0.2, glowR: 1.6)
    // The hood, and its tall peak leaning back, lit on the left and shaded on the right; a dark rim round her face.
    drawHood(c, robe, robeD)
    c.pattern(21, 14, [
        "..LR......",
        "..LRRR....",
        ".LRRRRRd..",
        ".LRRRRRRd.",
        "LRRRRRRRRd",
    ], ["R": robe, "L": robeL, "d": robeD])
    c.rect(22, 19, 1, 4, robeL); c.px(18, 22, robeL); c.px(16, 25, robeL)
    c.rect(21, 24, 14, 1, robeD); c.px(19, 26, robeD); c.px(36, 26, robeD)

    // The shadows curling round her weaving hands: dark crimson smoke threaded with a bright crimson edge.
    if weave > 0 {
        let hands = [(41.5, 34.5 - Double(frontUp)), (13.5, 34.5 - Double(backUp))]
        for (n, h) in hands.enumerated() {
            var prev: (Double, Double)? = nil
            for k in 0..<11 {
                let a = p.t * 5 * (n == 0 ? 1 : -1) + Double(k) * 0.62 + Double(n) * 2
                let r = 1.8 + Double(k) * 0.32
                let pt = (h.0 + cos(a) * r, h.1 + sin(a) * r * 0.8 - 1)
                let fade = weave * (1 - Double(k) / 12)
                if let q = prev {
                    c.glowLine(q.0, q.1, pt.0, pt.1, core: C(0xFF4A62, 0.85 * fade), glow: C(0x3A0614, 0.6 * fade),
                               coreR: 0.35, glowR: 1.4)
                }
                prev = pt
            }
        }
    }
}

// MARK: - Katra

/// Katra: the Horde's Force Captain. Long black hair down her back in strands, a red cat mask with pointed ears worn
/// up on her crown like a tiara, a black catsuit lit along the shoulders, a red belt with a gold buckle, red gloves
/// with silver claws, black tights and red boots. The red mask and the long black hair keep her apart from the
/// panther-suited cats in the other universes; she never turns into a panther. She fights with her claws and a red
/// leather whip, coiled at her hip when it's put away. Signature: she pulls the mask down over her eyes, cracks the
/// whip overhead with a spark at its tip, and pushes the mask back up.
private func drawKatra(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x1E1A26), suitL = C(0x3E3850), red = C(0xC8202E), redD = C(0x86121C), redL = C(0xEC5A62)
    let hair = C(0x16141C), hairL = C(0x4A4660), hairM = C(0x2C2838), steel = C(0xDCE0EA), gold = C(0xE8C04A)
    let whip = C(0x9A2A2A)
    let s = p.signature ?? -1
    let down = s < 0 ? 0 : hordeRamp(s, 0.14, 0.28) * (1 - hordeRamp(s, 0.84, 0.96))
    let reach = s > 0.04 && s < 0.34 ? sin((s - 0.04) / 0.3 * .pi) : s > 0.8 && s < 0.98 ? sin((s - 0.8) / 0.18 * .pi) : 0
    let crack = s > 0.4 && s < 0.74 ? (s - 0.4) / 0.34 : -1

    // Black tights, red boots lit along the top.
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 3, red); c.rect(lx, bottom - 2, 2, 1, redL); c.px(lx + 1, bottom, redD)
        }
    }
    c.oy += p.breathe
    // The long hair down her back, behind her: strands, a lit one and a dark one, ragged at the ends.
    for y in 24...38 {
        let w = y < 26 ? 3 + (y - 24) : 5
        c.rect(18 - w, y, w, 1, hair)
        c.px(14, y, hairL); c.px(16, y, hairM)
    }
    c.px(13, 39, hair); c.px(15, 39, hairM); c.px(17, 39, hair)

    let raise = Int((reach * 8).rounded())
    drawBody(c, Look(), armRight: raise)
    // The catsuit: black from the shoulders down, lit along the top, the red belt and its gold buckle.
    c.rect(18, 32, 20, 6, suit); c.rect(18, 32, 20, 1, suitL); c.rect(18, 32, 1, 5, suitL)
    c.rect(18, 36, 20, 1, red); c.rect(27, 36, 2, 1, gold)
    // Red gloves, silver claws on the free hand.
    c.rect(15, 33, 3, 3, red); c.px(15, 33, redL); c.px(14, 33, steel); c.px(14, 35, steel)
    c.rect(38, 33 - raise, 3, 3, red); c.px(38, 33 - raise, redL)
    let whipAngle: Double? = p.melee ?? (crack >= 0 ? -140 + 160 * (1 - pow(1 - crack, 3)) : nil)
    if whipAngle == nil { c.px(41, 33 - raise, steel); c.px(41, 35 - raise, steel) }

    // Her hair over the crown, a ragged fringe, and down over the far side of her face.
    c.pattern(16, 19, [
        ".....HHHHHHHHHHH......",
        "...HHHHlHHHHHHlHHHH...",
        "..HHHlHHHHmHHHHHHHHHH.",
        ".HHHlHHHHmHHHHHmHHHHHH",
        ".HHlHHHHmHHHHHHHmHHHHH",
        "HHHlHHHmHHHHHHHHHmHHHH",
        "HHlHHHmHHHmHHHHmHHHmHH",
        "HHlHHmH.mH..Hm..HmH.HH",
        "HHlHH...............HH",
        "HlHH.................H",
        "HlHH..................",
        "HlH...................",
    ], ["H": hair, "l": hairL, "m": hairM])

    // The cat mask: pointed ears with a lit inner edge, slanted eye holes and a gold gem between them. It rides up on
    // her crown, or down over her eyes.
    let my = 16 + Int((down * 8).rounded())
    c.pattern(18, my, [
        "..R..............R..",
        "..RR............RR..",
        "..RlR..........RRd..",
        "..RlRRRRRRRRRRRRRd..",
        ".RlRRRRRRRRRRRRRRRR.",
        "RRR..RRRRGGRRRR..RRR",
        "RRRR..RRRRRRRR..RRRd",
        ".dRRRRRRRRRRRRRRRRd.",
    ], ["R": red, "l": redL, "d": redD, "G": gold])

    if let a = whipAngle {
        katraWhip(c, angle: a, colour: whip, crack: crack > 0.6 && crack < 0.9)
    } else {
        // The whip coiled at her hip.
        c.pattern(35, 35, [".WWW.", "W...W", "W.WWW", ".WW.."], ["W": whip])
    }
}

/// Katra's whip from her fist at `angle`: a short black handle, then the lash curling down along its length; `crack`
/// puts a white spark at its tip.
private func katraWhip(_ c: PixelCanvas, angle a: Double, colour: Px, crack: Bool) {
    let h = eterniaHand
    eterniaBar(c, h, a, from: -1, to: 3, C(0x2A1A16), r: 0.8)
    var pt = eterniaReach(h, a, 3), ang = a
    for i in 0..<13 {
        ang += 4.5
        let next = eterniaReach(pt, ang, 1.2)
        c.glowLine(pt.x, pt.y, next.x, next.y, core: i < 9 ? colour : C(0xB84040), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        pt = next
    }
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, C(0xC8202E))   // the gloved fist round the handle
    if crack {
        let x = Int(pt.x.rounded()), y = Int(pt.y.rounded())
        c.glowLine(pt.x, pt.y, pt.x, pt.y, core: C(0xFFFFFF, 0), glow: C(0xFFE08A, 0.5), coreR: 0.2, glowR: 2.6)
        c.px(x, y, white); c.px(x - 1, y, C(0xFFF4C0)); c.px(x + 1, y, C(0xFFF4C0))
        c.px(x, y - 1, C(0xFFF4C0)); c.px(x, y + 1, C(0xFFF4C0))
    }
}

// MARK: - Scorpia

/// Scorpia: the Horde's scorpion woman. Short black hair in strokes, a red scorpion's shell over her chest banded in
/// black, red shell down her legs and black boots, two big red pincers for hands with
/// black tips, and a scorpion's tail, bead on bead of red shell, rising off her back and arching right over her head,
/// a pale stinger at its end. She fights with the pincers. Signature: she clacks both pincers open and shut, and the
/// tail flicks back and forth over her head.
private func drawScorpia(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0xD03A34), shellD = C(0x922420), shellL = C(0xF06A5A), black = C(0x1E1A20), blackL = C(0x46404C)
    let hair = C(0x221C24), hairL = C(0x4E424E), sting = C(0xF4DC8A), stingD = C(0xB89A4A)
    let s = p.signature ?? -1
    let clack = s > 0.1 && s < 0.86
    let open = clack ? (Int(p.t * 10) % 2 == 0 ? 0 : 3) : 1
    let flick = s > 0.12 && s < 0.88 ? sin((s - 0.12) / 0.76 * .pi * 4) : 0

    // Legs in red segmented armour, black at the joints, and black boots.
    drawLegs(c, Look(leg: shell), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, 39, shellD)
            c.rect(lx, bottom - 1, 2, 2, black); c.px(lx, bottom - 1, blackL)
        }
    }
    c.oy += p.breathe

    // The tail, behind her: from the small of her back up and over her head in beads of shell, dark at the joints.
    let f = flick * 2
    let pts: [(Double, Double)] = [(17, 35), (13.5, 31.5), (12, 27), (12.5, 22), (15, 18), (19, 15), (24, 13),
                                   (29 + f * 0.5, 12.5), (33 + f, 14)]
    for k in 1..<pts.count {
        c.glowLine(pts[k - 1].0, pts[k - 1].1, pts[k].0, pts[k].1, core: shellD, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
    }
    for (k, q) in pts.enumerated() where k > 0 {
        let x = Int(q.0.rounded()), y = Int(q.1.rounded())
        c.rect(x - 1, y - 1, 3, 3, shell); c.px(x - 1, y - 1, shellL); c.px(x + 1, y + 1, shellD)
    }
    // The stinger: hooked down and forward off the last bead.
    let tx = Int((35 + f).rounded())
    c.pattern(tx, 14, ["SS.", "sSS", "..S", "..s"], ["S": sting, "s": stingD])

    // The far pincer, raised up and out behind her past the tail, the near one's twin: a fat palm angled up off her
    // wrist, two curved jaws with black tips, clacking with the near one's. A black rim all round parts it from the red
    // tail behind it.
    let g = Double(open == 0 ? 0 : open == 1 ? 1 : 2)
    let jaws: [[(Double, Double)]] = [
        [(11, 28), (8.5, 25), (6.5 + g * 0.3, 22.5 - g * 0.7), (5 + g * 0.5, 22 - g)],          // the upper jaw
        [(9.5, 30.5), (6.5, 29.5 + g * 0.3), (4.5 - g * 0.3, 28 + g * 0.5), (3.5 - g * 0.4, 26.5 + g * 0.6)],
    ]
    func farPincer(_ grow: Double, _ col: Px?) {
        func seg(_ a: (Double, Double), _ b: (Double, Double), _ r: Double, _ k: Px) {
            c.glowLine(a.0, a.1, b.0, b.1, core: col ?? k, glow: C(0, 0), coreR: r + grow, glowR: r + grow + 0.1)
        }
        seg((16, 33.5), (11, 29.5), 2.0, shell)                                    // the wrist and palm
        for (n, j) in jaws.enumerated() {
            for k in 1..<j.count { seg(j[k - 1], j[k], k == 1 ? 1.3 : 0.75, n == 0 ? shell : shellD) }
        }
    }
    farPincer(1, black)
    farPincer(0, nil)
    c.glowLine(15, 31.5, 11, 28, core: shellL, glow: C(0, 0), coreR: 0.45, glowR: 0.5)   // lit along the top
    c.glowLine(9, 26, 7.5, 24, core: shellL, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    for j in jaws {   // the black tips
        let t = j[j.count - 1]
        c.px(Int(t.0.rounded()), Int(t.1.rounded()), black)
    }

    drawBody(c, Look())
    // The shell over her chest: lit along the top, banded in black, shaded on the far side.
    c.rect(18, 32, 20, 6, shell); c.rect(18, 32, 20, 1, shellL); c.rect(37, 32, 1, 6, shellD)
    c.rect(18, 34, 20, 1, black); c.rect(18, 36, 20, 1, black)
    c.px(27, 33, shellL); c.px(27, 35, shellL)
    // The far pincer's wrist, over the arm.
    c.rect(14, 32, 4, 3, shell); c.px(14, 32, shellL); c.rect(14, 34, 4, 1, shellD)

    // Short black hair: a round cap combed in strokes, a fringe, and down a little over her ears.
    c.pattern(17, 20, [
        "....HHHHHHHHHHH...",
        "..HHHlHHHHlHHHHHH.",
        ".HHlHHHhHHHHhHHHHH",
        "HHlHHhHHHHhHHHHhHHH",
        "HHlHhHHHhHHHhHHHhHH",
        "HHHhHH.hHH.hHH.hHHH",
        "HHh...............H",
        "Hh.................",
    ], ["H": hair, "h": C(0x100C12), "l": hairL])

    // The near pincer, swung at the weapon's angle (resting a little down), its jaws `open` pixels apart.
    let a = p.melee ?? (clack ? -30 : 12)
    prop(c, at: eterniaHand, angle: a) { q in
        q.rect(16, 18, 8, 5, shell); q.rect(16, 18, 8, 1, shellL); q.rect(16, 22, 8, 1, shellD)
        q.rect(24, 17 - open, 4, 2, shell); q.px(24, 17 - open, shellL); q.px(28, 18 - open, black); q.px(27, 19 - open, black)
        q.rect(24, 21 + open, 3, 2, shell); q.px(27, 21 + open, black); q.px(26, 22 + open, shellD)
    }
}

// MARK: - Mantenna

/// Mantenna: the Horde's four-legged bug. A brown shell lit along the top, a pale belly in ridged plates, jointed
/// brown legs with little hooked feet, a wide fanged mouth, and two big red eyes sitting up on short stalks, black
/// pupils looking ahead. He fires red beams out of his eyes, which glow while he does. Signature: his eyes pop right
/// out on their stalks with a boing, wobble about up there, and sink back down.
private func drawMantenna(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0x7A5230), shellD = C(0x55381E), shellL = C(0xA2784A), belly = C(0xCCAA74), bellyD = C(0x9E7E50)
    let stalk = C(0x8E6A3E), stalkD = C(0x6A4A28), ink = C(0x141018), fang = C(0xF4F0E4)
    let firing = p.fire != nil
    let eye = firing ? C(0xFF6A50) : C(0xE8302A), eyeD = firing ? C(0xE8302A) : C(0xA01A18), eyeL = C(0xFFB0A0)
    let s = p.signature ?? -1
    let out = s < 0 ? 0 : hordeRamp(s, 0.1, 0.18) * (1 - hordeRamp(s, 0.8, 0.92))
    let boing = s > 0.18 && s < 0.46 ? sin((s - 0.18) / 0.28 * .pi * 3) * (1 - (s - 0.18) / 0.28) * 2 : 0
    let h = 2 + Int((out * 9 + boing).rounded())
    let sway = Int((sin(p.t * 6) * 1.5 * out).rounded())

    // The legs: brown, a dark joint at the knee, a little hooked foot.
    drawLegs(c, Look(leg: shell), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, bottom - 4, shellD)
            c.px(lx + 2, bottom, shellD)
        }
    }
    c.oy += p.breathe
    // The body: Clawd's block with its top corners rounded off into a domed shell, lit along the top and down the
    // left, the seam of the wing cases down his back.
    c.rect(18, 28, 20, 10, shell); c.rect(19, 27, 18, 1, shell); c.rect(20, 26, 16, 1, shell)
    c.rect(22, 25, 12, 1, shell); c.rect(25, 24, 6, 1, shell)
    c.rect(18, 37, 20, 1, shellD); c.rect(37, 28, 1, 10, shellD); c.px(36, 27, shellD); c.px(35, 26, shellD)
    c.rect(25, 24, 4, 1, shellL); c.rect(22, 25, 3, 1, shellL); c.px(20, 26, shellL); c.px(19, 27, shellL)
    c.rect(18, 28, 1, 5, shellL); c.rect(21, 27, 1, 5, shellD)
    c.rect(15, 33, 3, 3, shell); c.rect(38, 33, 3, 3, shell)   // his arms
    // The belly: a bug's underside in overlapping plates, each one bowed down in the middle like a smile, lit along
    // its top edge and shaded under, narrowing as they go down, a dark seam down the middle where they meet.
    c.pattern(20, 33, [
        "..LLLLLLLLLLLL..",
        ".dBBBBBBBBBBBBd.",
        "..ddLLLLLLLLdd..",
        "...dBBBBBBBBd...",
        "....ddLLLLdd....",
    ], ["B": belly, "L": C(0xE8CC98), "d": bellyD])
    c.px(28, 34, bellyD); c.px(27, 36, bellyD)
    // The feelers, curling forward off the front of his shell.
    c.px(36, 25, shellD); c.px(37, 24, shellD); c.px(38, 23, shellD); c.px(39, 23, shellD); c.px(40, 24, shellD)
    // The mouth: wide and black, a fang at each end, and hooked mandibles at the front.
    c.rect(25, 31, 8, 1, ink); c.px(26, 32, fang); c.px(31, 32, fang)
    c.px(37, 31, shellD); c.px(38, 32, shellD); c.px(37, 33, shellD)
    // Claw tips on his hands.
    c.px(41, 35, shellD); c.px(14, 35, shellD)

    // The eyes on their stalks: the stalks up off the top of his head, then the round red eyes.
    for (n, bx) in [23, 32].enumerated() {
        let ex = bx + (n == 0 ? -sway : sway)
        let top = 25 - h
        for y in top..<26 {
            let k = Double(25 - y) / Double(max(1, h))
            let x = bx + Int((Double(ex - bx) * k).rounded())
            c.rect(x, y, 2, 1, stalk); c.px(x + 1, y, stalkD)
        }
        c.pattern(ex - 2, top - 4, [
            ".RRR.",
            "RLRRd",
            "RRRKd",
            ".ddd.",
        ], ["R": eye, "L": eyeL, "d": eyeD, "K": ink])
        if firing {
            c.glowLine(Double(ex) + 0.5, Double(top) - 2, Double(ex) + 0.5, Double(top) - 2, core: C(0xFFFFFF, 0),
                       glow: C(0xFF4A3A, 0.5), coreR: 0.2, glowR: 3)
        }
    }
}

// MARK: - Imp

/// Imp: Hordakk's tiny spy. A purple little thing with big pointed bat ears pink inside, bright yellow eyes, a sly
/// grin with a fang, a pink belly, small bat wings folded behind him, fluttering now and then, and a thin tail with a
/// spade at its end. He doesn't fight. Signature: in a puff of lilac smoke he turns into a wooden stool (four legs,
/// of course), sits there being furniture with only his tail tip twitching under the seat, and puffs back.
private func drawImp(_ c: PixelCanvas, _ p: Pose) {
    let imp = C(0x8A4EC0), impD = C(0x62348E), impL = C(0xAE78E0), belly = C(0xE0A0DA), bellyD = C(0xB872B8)
    let wing = C(0x4E2878), wingL = C(0x9A6ACA), eyeY = C(0xFFE04A), ink = C(0x141018)
    let s = p.signature ?? eterniaHabitK(p.who) ?? -1   // or on the stage's cue (EterniaHabits.swift)
    let stool = s > 0.22 && s < 0.78
    let puffs = [s > 0.14 && s < 0.34 ? (s - 0.14) / 0.2 : -1, s > 0.7 && s < 0.9 ? (s - 0.7) / 0.2 : -1]

    if stool {
        // The stool: a plank seat lit along the top, its apron, four legs and a rung.
        let wood = C(0xA8743E), woodD = C(0x7A5028), woodL = C(0xCC9A5E)
        c.rect(17, 33, 22, 2, wood); c.rect(17, 33, 22, 1, woodL); c.rect(17, 35, 22, 1, woodD)
        c.rect(18, 36, 20, 1, woodD)
        for lx in [19, 23, 31, 35] { c.rect(lx, 36, 2, 8, wood); c.rect(lx + 1, 37, 1, 7, woodD) }
        c.rect(21, 40, 2, 1, woodD); c.rect(33, 40, 2, 1, woodD); c.rect(25, 40, 6, 1, woodD)
        // His tail tip, twitching under the seat.
        let tw = Int(p.t * 6) % 2
        c.px(17, 37, imp); c.px(16, 38 - tw, imp); c.rect(14, 38 - tw, 2, 2, impD); c.px(13, 38 - tw, impD)
    } else {
        let flutter = Int(p.t * 9) % 2 == 0 && sin(p.lt * 0.9) > 0.6
        // The tail, curling down behind him to its spade.
        c.px(17, 36, imp); c.px(16, 37, imp); c.px(15, 38, imp); c.px(14, 38, imp)
        c.pattern(11, 37, [".K.", "KKK", ".K."], ["K": impD])
        drawLegs(c, Look(leg: imp), step: p.step)
        drawBoots(c, impD, step: p.step, rows: 1)
        c.oy += p.breathe
        // The bat wing folded behind him: a lit bone along the top edge, the membrane scalloped below it.
        let lift = flutter ? 3 : 0
        for x in 9...17 {
            let rise: Double = Double(4 + lift) * Double(18 - x) / 9
            let top = 27 - Int(rise.rounded())
            let bottom = 32 - ((x - 9) % 3 == 0 ? 1 : 0)
            c.rect(x, top, 1, max(1, bottom - top), wing)
            c.px(x, top, wingL)
        }
        c.px(12, 28, wingL); c.px(12, 29, wingL); c.px(15, 28, wingL)
        drawBody(c, Look(body: imp, shade: impD, arm: imp, eye: nil))
        c.rect(18, 26, 1, 7, impL); c.rect(19, 26, 17, 1, impL)
        // The pink belly.
        c.rect(22, 34, 12, 3, belly); c.rect(22, 36, 12, 1, bellyD); c.rect(23, 33, 10, 1, belly)
        // Big yellow eyes looking ahead, and the sly grin with a fang.
        c.rect(21, 28, 3, 3, eyeY); c.rect(23, 29, 1, 2, ink)
        c.rect(31, 28, 3, 3, eyeY); c.rect(33, 29, 1, 2, ink)
        c.rect(25, 32, 6, 1, ink); c.px(24, 31, ink); c.px(31, 31, ink); c.px(29, 33, white)
        // The big bat ears, pink inside.
        c.pattern(18, 20, ["E....", "EE...", "EpE..", "EppE.", "EEEEE", ".EEEE"], ["E": imp, "p": belly])
        c.pattern(33, 20, ["....E", "...EE", "..EpE", ".EppE", "EEEEE", "EEEE."], ["E": impD, "p": bellyD])
        c.px(18, 20, impL)
        c.px(41, 35, impD)   // a little claw
    }

    // The puffs of lilac smoke as he changes, swelling and thinning away.
    for f in puffs where f >= 0 {
        let a = (1 - f) * 0.7, r = 3 + f * 9
        for k in 0..<9 {
            let ang = Double(k) / 9 * 2 * .pi + f
            let x = 28 + cos(ang) * r, y = 33 + sin(ang) * r * 0.75
            c.glowLine(x, y, x, y, core: C(0xF4ECFF, a * 0.8), glow: C(0xC8A8F0, a * 0.6), coreR: 0.8, glowR: 2)
        }
    }
}

// MARK: - Horde Trooper

/// A Horde Trooper: one of Hordakk's robot foot soldiers. Grey all over, a domed helmet with a ridge down the
/// middle, a black visor band with two red lights for eyes, the red bat on its chest plate, jointed grey legs and dark
/// feet, and a black laser rifle that fires red bolts. Grey with the bat keeps it apart from the film's black-armoured
/// Dark Troopers. Signature: it shoulders its rifle and marches on the spot, stamping, a little dust off each stamp.
private func drawHordeTrooper(_ c: PixelCanvas, _ p: Pose) {
    let grey = C(0x9498A6), greyD = C(0x646876), greyL = C(0xC6CAD4), dark = C(0x24262E), darkL = C(0x40434E)
    let red = C(0xD8202A), redD = C(0x8A1018), lamp = C(0xFF4A3A)
    let s = p.signature ?? -1
    let march = s > 0.08 && s < 0.92
    let beats = s * 3.2 * 2.5
    let beat = march ? Int(beats) % 2 : -1

    // The legs: grey, a joint at the knee, dark feet. Marching, each pair stamps up and down in turn.
    if seatedPose {
        drawLegs(c, Look(leg: grey))
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = march ? i % 2 == beat : p.step >= 0 && i % 2 == p.step
            let bottom = march && lifted ? 40 : lifted ? 42 : 43
            c.rect(lx, 36, 2, bottom - 35, grey); c.px(lx, 37, greyL)
            c.px(lx + 1, bottom - 4, darkL)
            c.rect(lx, bottom - 1, 2, 2, dark); c.px(lx + 2, bottom, dark)
        }
        if march {
            let f = beats.truncatingRemainder(dividingBy: 1)
            if f < 0.35 {
                for (i, lx) in [19, 23, 31, 35].enumerated() where i % 2 != beat {
                    let a = 0.45 * (1 - f / 0.35)
                    c.px(lx - 1 - Int(f * 6), 43, C(0xE4E4EC, a)); c.px(lx + 3 + Int(f * 6), 43, C(0xE4E4EC, a))
                }
            }
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: grey, shade: greyD, arm: grey, eye: nil))
    c.rect(18, 26, 1, 11, greyL)
    // The domed helmet, lit on the left, a ridge down the middle.
    c.pattern(18, 20, [
        "......GGGGGGGG......",
        "....GGLLGGGGGGGG....",
        "..GGGLGGGGGGGGGGGG..",
        ".GGGLGGGGGGGGGGGGGd.",
        "GGGLGGGGGGGGGGGGGGGd",
        "GGGGGGGGGGGGGGGGGGGd",
    ], ["G": grey, "L": greyL, "d": greyD])
    c.rect(28, 20, 1, 6, greyD); c.rect(18, 26, 20, 1, greyD)
    // The visor, and its two red lights.
    c.rect(19, 28, 18, 3, dark); c.rect(19, 28, 18, 1, darkL)
    c.rect(22, 29, 2, 1, lamp); c.rect(32, 29, 2, 1, lamp)
    c.glowLine(22.5, 29.5, 33.5, 29.5, core: C(0xFF4A3A, 0), glow: C(0xFF3020, 0.18), coreR: 0.1, glowR: 1.4)
    // The Horde's bat on the helmet's forehead, above the visor.
    hordeBat(c, 23, 22, red: red, redD: redD)
    // A seam under the visor, then a plain chest plate with a few rivets.
    c.rect(20, 31, 16, 1, greyD)
    hordePlate(c, plate: greyL, plateD: greyD, plateL: C(0xE2E4EA))
    c.px(22, 35, greyD); c.px(27, 35, greyD); c.px(32, 35, greyD)

    if march {
        // The rifle shouldered, straight up against him, its muzzle up past his helmet.
        c.rect(39, 19, 2, 15, dark); c.rect(39, 19, 1, 15, darkL); c.rect(39, 17, 1, 2, greyD); c.px(41, 25, red)
        c.rect(38, 33, 3, 3, grey); c.px(38, 33, greyL)
    } else {
        // The rifle: a black body, a red sight, a grey barrel, a grip under the fist.
        c.oy += p.gunY
        c.rect(36, 32, 11, 3, dark); c.rect(36, 32, 11, 1, darkL)
        c.rect(47, 33, 3, 1, greyD); c.px(43, 31, red); c.px(44, 31, redD)
        c.rect(41, 35, 2, 2, dark)
        c.rect(38, 33, 3, 3, grey); c.px(38, 33, greyL)
        c.oy -= p.gunY
    }
}

// MARK: - Screeech

/// Screeech: Skeleclawd's bird. A purple bird with a lavender breast, a crest of green feathers swept back off his
/// head, green wings and a fan of green tail feathers, a big hooked yellow beak, angry brows, and four yellow
/// bird's legs with talons. He flies about, wings beating; standing, they fold at his sides. Signature: he flings his
/// wings up, opens his beak wide and screeches, rings of sound pulsing out in front of him.
private func drawScreeech(_ c: PixelCanvas, _ p: Pose) {
    let plum = C(0x7A3A9E), plumD = C(0x56247A), plumL = C(0xA060C4), breast = C(0xC09ADA), breastD = C(0x9A72B8)
    let green = C(0x4CA83A), greenD = C(0x2E7424), greenL = C(0x86D45E)
    let beak = C(0xF0B830), beakD = C(0xB4801A), beakL = C(0xFFDA70), talon = C(0xE0A834), talonD = C(0xA8761E)
    let s = p.signature ?? -1
    let cry = s > 0.15 && s < 0.8
    let spread = p.flying || cry
    let up = p.flying ? Int(p.t * 8) % 2 == 0 : true

    // Yellow bird's legs, scaled, talons out to either side.
    drawLegs(c, Look(leg: talon), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, bottom - 4, talonD); c.px(lx + 1, bottom - 2, talonD)
            c.px(lx - 1, bottom, talonD); c.px(lx + 2, bottom, talonD)
        }
    }
    c.oy += p.breathe

    // The tail feathers fanned out behind him.
    c.pattern(8, 30, [
        "LLGGG.....",
        "GGGGGGGG..",
        ".gggGGGGGG",
        "LLGGGGGGGG",
        "GGGGGGGG..",
        ".ggggg....",
    ], ["G": green, "g": greenD, "L": greenL])
    // Spread, both wings open behind his back, up (or down on the beat): a fan of green feathers from the shoulder,
    // a lit leading edge and darker strokes between the long flight feathers.
    if spread {
        for (n, sh) in [(23.0, 29.0), (27.0, 30.0)].enumerated() {
            let dx = Double(n) * 5
            let a: (Double, Double) = up ? (8 + dx, 21) : (7 + dx, 33)
            let b: (Double, Double) = up ? (17 + dx, 9) : (12 + dx, 42)
            for k in 0...16 {
                let t = Double(k) / 16
                let tip = (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t - (up ? 3 : -1) * sin(t * .pi))
                let feather = k % 4 == 2
                c.glowLine(sh.0, sh.1, tip.0, tip.1, core: n == 0 || feather ? greenD : green, glow: C(0, 0),
                           coreR: 0.7, glowR: 0.8)
            }
            c.glowLine(sh.0, sh.1 - 0.5, b.0, b.1, core: greenL, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        }
    }

    drawBody(c, Look(body: plum, shade: plumD, arm: plum, eye: nil))
    c.rect(18, 26, 1, 7, plumL); c.rect(19, 26, 16, 1, plumL)
    // The lavender breast, feathered in short strokes.
    c.rect(25, 33, 12, 5, breast); c.rect(24, 34, 1, 3, breast)
    for x in stride(from: 26, to: 37, by: 3) { c.px(x, 34, breastD); c.px(x + 1, 36, breastD) }
    // Angry eyes under heavy brows.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink); c.px(22, 29, white); c.px(32, 29, white)
    c.rect(21, 28, 3, 1, plumD); c.px(24, 29, plumD); c.rect(32, 28, 3, 1, plumD); c.px(31, 29, plumD)
    // The crest, swept back off his head.
    c.pattern(14, 20, [
        "LL............",
        "GGGL..........",
        ".GGGGGL.......",
        "..gGGGGGGL....",
        "...ggGGGGGGGG.",
        ".....gGGGGGGGG",
    ], ["G": green, "g": greenD, "L": greenL])
    // The near wing folded at his side, when it isn't spread.
    if !spread {
        c.pattern(18, 32, [
            "LLLLLLLLL..",
            "GGGGGGGGGG.",
            "GgGgGgGGGGG",
            ".GgGgGgGGGg",
            "..g.g.g.gg.",
        ], ["G": green, "g": greenD, "L": greenL])
    }

    // The beak: hooked, shut, or open wide and screeching.
    if cry {
        c.pattern(36, 26, [
            ".....BB.",
            "...BBBBB",
            "LBBBBBBb",
            "BBMMMM..",
            "bMMMMM..",
            "bMMMM...",
            "bbbbbb..",
            ".bbbb...",
        ], ["B": beak, "b": beakD, "L": beakL, "M": C(0xC0304A)])
        // Rings of sound pulsing out in front of him.
        for k in 0..<3 {
            let f = (s * 6 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            let r = 3 + f * 12, a = (1 - f) * 0.75
            for d in stride(from: -40.0, through: 40.0, by: 8) {
                let ang = d * .pi / 180
                c.px(Int((45 + cos(ang) * r).rounded()), Int((30 + sin(ang) * r).rounded()), C(0xF4F0FF, a))
            }
        }
    } else {
        c.pattern(36, 28, [
            "LBBB....",
            "BBBBBB..",
            "BBBBBBBB",
            "bbbbbbBB",
            "......bB",
        ], ["B": beak, "b": beakD, "L": beakL])
    }
}
