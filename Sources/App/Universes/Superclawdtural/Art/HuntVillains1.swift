import Foundation

// Villains: the demons. Drawn the same way as the heroes (HuntHeroes1.swift); Clawd in costume, in black suits and
// overcoats, their power a red glow from a fingertip.
//
// Magic (`weapon: .lightning`): `magic:` says how the stream looks, and the engine draws it from `pivot` (the casting
// hand, raised `p.armRaise` pixels: draw the arm raised as much). Don't set `magic.variant` yourself: the engine
// numbers every magic user in order through all the universes, so no two anywhere look exactly alike.

let huntVillains1: [HuntVillain: Persona] = [
    .clawdley: Persona(name: "Clawdley", weapon: .lightning,
                       magic: Magic(core: C(0xFFE2DE), glow: C(0xD41E2A), jagged: false, touch: true),
                       headTop: 21, signature: 3.6, callout: "Hello, boys.", draw: drawClawdley),
]

// MARK: - Clawdley

/// Clawdley, King of Hell: a sharp black suit under a long black overcoat, a white shirt and a black silk tie, short
/// dark hair combed back, and his neat goatee. His power over Hell is a fingertip lit red, and a red glow round
/// whoever he points it at. Signature: he snaps his fingers in a red flash, and Juliet, his hellhound, sits at his
/// heel for a moment: a shadow of a great dog with red eyes, since nobody can really see a hellhound.
private func drawClawdley(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1E1E26), coatD = C(0x0E0E12), coatL = C(0x4A4A56)
    let suit = C(0x34343E), shirt = C(0xEAE8E4), tie = C(0x101014), tieL = C(0x3A3A44)
    let hair = C(0x2A2220), hairL = C(0x4E423C), beard = C(0x4A3A30), beardL = C(0x7A6A5E), stubble = C(0xA85A42)
    let s = p.signature ?? -1
    // The snap: his hand up by a tenth of the way in, the flash at a fifth; then Juliet, fading in, sitting, fading out.
    let snap = s > 0.04 && s < 0.36 ? (s - 0.04) / 0.32 : -1
    let juliet = s > 0.2 && s < 0.96 ? min(1, (s - 0.2) / 0.12, (0.96 - s) / 0.16) : 0
    let raise = snap >= 0 ? Int(sin(min(1, snap * 1.6) * .pi / 2 + (snap > 0.6 ? (snap - 0.6) * 3.9 : 0)) * 6) : p.armRaise

    // Juliet, behind him on the left: a great dog sitting, all shadow, her eyes two red sparks. See-through, so she gets
    // no outline, and a pixel clear of his coat.
    if juliet > 0 {
        let dog = C(0x08080C, 0.62 * juliet), eye = C(0xFF3030, 0.92 * juliet)
        c.pattern(1, 31, [
            "..........k.k..",
            ".........kkkkk.",
            ".........kEkkkk",
            "........kkkkkkk",
            "..kkkkkkkkkkk..",
            ".kkkkkkkkkkkk..",
            "kkkkkkkkkkkk...",
            "kkkkkkkkkkkk...",
            ".kkkkkkkkkkk...",
            ".kk.kk...kk.k..",
            ".kk.kk...kk.k..",
            ".kk.kk...kk.kk.",
        ], ["k": dog, "E": eye])
        c.px(13, 33, eye)
    }

    drawLegs(c, Look(leg: C(0x3E3E4A)), step: p.step)
    drawBoots(c, C(0x0C0C0E), step: p.step, rows: 1)

    c.oy += p.breathe
    // The overcoat's skirts, to the knees, black with a dark sheen down the lit side.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat)
    } else {
        c.rect(17, 38, 22, 1, coat); c.rect(17, 39, 22, 1, coatD)
        c.rect(17, 38, 1, 1, coatL); c.rect(38, 38, 1, 2, coatD)
        for x in [21, 25, 33] { c.px(x, 38, coatD) }
        c.rect(29, 38, 1, 2, C(0x050507))
    }
    drawBody(c, Look(arm: coat), armRight: raise)

    // The overcoat over the suit: its wide lapels lit along their edge, the suit's lapels inside them, the white shirt
    // and the tie, the far side in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(22, 33, 3, 4, suit); c.rect(31, 33, 3, 4, suit)
    // The shirt showing in a narrow V between the lapels, the tie down the middle of it.
    c.rect(25, 33, 6, 1, shirt); c.rect(26, 34, 4, 1, shirt); c.rect(27, 33, 2, 5, tie); c.px(27, 34, tieL)
    c.rect(21, 33, 1, 4, coatL); c.rect(24, 34, 1, 2, C(0x3A3A46)); c.rect(34, 33, 1, 4, coatD)
    c.rect(19, 33, 2, 1, coatL); c.rect(35, 33, 2, 1, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD); c.px(15, 34, C(0xEAE8E4))   // a cuff of white shirt at his far wrist

    // Short dark hair combed back from a high brow, a gleam along it.
    c.pattern(17, 21, [
        "......HHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHlllllHHHHlllllHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHhHHHHHHHHhHHHHH.",
        ".HH...............HHH.",
        ".H..................H.",
    ], ["H": hair, "l": hairL, "h": C(0x1A1412)])
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)
    // His beard, trimmed short: a shadow of stubble along the jaw from ear to ear, and in it the goatee, a greying
    // brown in short downward strokes rather than a dark bar, so it reads as a beard and not as a mouth.
    c.pattern(18, 30, [
        "s..................s",
        "ss......BbBb......ss",
        ".sssssssbBbBsssssss.",
    ], ["s": stubble, "b": beard, "B": beardL])

    guard snap >= 0 else { return }
    // His hand up beside his face, the fingers snapping: a red flash bursting from them at the snap.
    let hy = 33 - raise
    c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy, clawdShade)
    let flash = snap > 0.45 && snap < 0.8 ? sin((snap - 0.45) / 0.35 * .pi) : 0
    if flash > 0 {
        for k in 0..<8 {
            let a = Double(k) * .pi / 4
            for r in 2...4 {
                c.px(41 + Int((cos(a) * Double(r)).rounded()), hy - 1 + Int((sin(a) * Double(r)).rounded()),
                     C(0xFF3A2A, flash * (r == 2 ? 0.9 : 0.5)))
            }
        }
        c.px(41, hy - 1, C(0xFFE2DE, flash))
    }
}
