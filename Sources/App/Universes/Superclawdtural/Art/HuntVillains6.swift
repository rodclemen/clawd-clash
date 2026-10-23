import Foundation

// Villains: the human villains and the first monsters of the week. Drawn the way HuntVillains1.swift draws Clawdley (HuntHeroes1.swift's header has the Persona fields;
// HuntKit.swift the shared helpers): each one a `Persona` in the dictionary below and a `private func draw…` further down.
//
// The British Men of Letters and two rogue hunters with their pistols and a machete, a vampire from before the
// Civil War, and two ghosts. The three pistols are told apart by the drawing: Lady Bevell's slim black one with its
// long silencer, Ketch's chunky gunmetal one with a torch under the barrel, Bela's little gold-plated one. The ghosts
// are drawn whole and opaque, so their outline holds, then cooled towards their ghost colour on a scratch canvas
// (`hv6Ghost`), with see-through rags at the hem and a faint halo; when they fade they drop straight to faint
// rather than through half, so the outline never goes dotted.

let huntVillains6: [HuntVillain: Persona] = [
    .toniBevell: Persona(name: "Lady Toni Bevell", weapon: .blaster, shot: .bullet, muzzle: (53, 31), headTop: 20,
                         draw: drawToniBevell),
    .arthurKetch: Persona(name: "Arthur Ketch", weapon: .blaster, shot: .bullet, muzzle: (50, 31), headTop: 21,
                          signature: 3.0, draw: drawArthurKetch),
    .gordonWalker: Persona(name: "Gordon Walker", weapon: .saber, headTop: 24, signature: 3.6, draw: drawGordonWalker),
    .belaTalbot: Persona(name: "Bela Talbot", weapon: .blaster, shot: .bullet, muzzle: (46, 31), headTop: 21,
                         draw: drawBelaTalbot),
    .alphaVampire: Persona(name: "The Alpha Vampire", weapon: .saber, headTop: 21, signature: 3.6,
                           draw: drawAlphaVampire),
    .bloodyMary: Persona(name: "Bloody Mary", weapon: .lightning,
                         magic: Magic(core: C(0xE87080), glow: C(0x6E0A18), jagged: false, touch: true),
                         headTop: 20, signature: 4.0, draw: drawBloodyMary),
    .womanInWhite: Persona(name: "The Woman in White", weapon: .lightning, motion: .hover,
                           magic: Magic(core: C(0xEAF8FF), glow: C(0xA6D8EE), jagged: false, touch: true),
                           canSit: false, headTop: 20, signature: 3.4, draw: drawWomanInWhite),
]

// MARK: - Shared bits

/// Where `s` (0…1 through a signature) is inside `a`…`b`, as 0…1 again; -1 outside it or with no signature.
private func hv6Span(_ s: Double?, _ a: Double, _ b: Double) -> Double {
    guard let s, s >= a, s < b else { return -1 }
    return (s - a) / (b - a)
}

/// `a` moved `k` (0…1) of the way to `b`, keeping `a`'s alpha.
private func hv6Mix(_ a: Px, _ b: Px, _ k: Double) -> Px {
    func m(_ x: UInt8, _ y: UInt8) -> UInt8 { UInt8(max(0, min(255, Double(x) + (Double(y) - Double(x)) * k))) }
    return Px(r: m(a.r, b.r), g: m(a.g, b.g), b: m(a.b, b.b), a: a.a)
}

/// A ghost: `art` drawn on a scratch canvas with `c`'s offsets, then copied onto `c` with every colour cooled `k`
/// of the way to `tint`, each row moved `shift(row)` pixels across (a flicker's tear), faded to `alpha`, and a faint
/// one-pixel `halo` round its solid edges (faint enough that the outline still goes round it).
private func hv6Ghost(_ c: PixelCanvas, alpha: Double, tint: Px, k: Double, halo: Px? = nil,
                      shift: (Int) -> Int = { _ in 0 }, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    s.ox = c.ox; s.oy = c.oy; s.baseY = c.baseY
    art(s)
    let (ox, oy, by) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = by }
    let solid = { (x: Int, y: Int) -> Bool in
        x >= 0 && y >= 0 && x < s.w && y < s.h && s.buf[(y * s.w + x) * 4 + 3] >= 250
    }
    for y in 0..<s.h {
        let dx = shift(y)
        for x in 0..<s.w {
            let i = (y * s.w + x) * 4
            if s.buf[i + 3] > 0 {
                c.px(x + dx, y, hv6Mix(unpremultiplied(s, i), tint, k).alpha(alpha))
            } else if let halo, solid(x - 1, y) || solid(x + 1, y) || solid(x, y - 1) || solid(x, y + 1) {
                c.px(x + dx, y, halo.alpha(min(1, alpha)))
            }
        }
    }
}

/// Tweed: a herringbone in three tones, the slant turning every two columns, and a rust thread of overcheck every
/// sixth column. Reads as a woven texture at 1×, not as stripes.
private func hv6Tweed(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, base: Px, dark: Px, light: Px,
                      check: Px) {
    for yy in y..<(y + h) {
        for xx in x..<(x + w) {
            let d = (xx / 2) % 2 == 0 ? (xx + yy) % 3 : (xx - yy + 300) % 3
            let col = xx % 7 == 3 && yy % 2 == 0 ? check : d == 0 ? dark : d == 2 && (xx + yy) % 4 == 0 ? light : base
            c.px(xx, yy, col)
        }
    }
}

// MARK: - Lady Toni Bevell

/// Lady Toni Bevell of the British Men of Letters: honey-blonde hair swept back smooth into a neat chignon, a fitted
/// heather-brown tweed skirt suit (a herringbone with a rust overcheck), its notched collar open on a cream silk
/// blouse and a string of pearls, the skirt to the knee, tan tights and dark brown court shoes. Fights with a slim
/// black pistol with a long silencer screwed on, very quiet, very British.
private func drawToniBevell(_ c: PixelCanvas, _ p: Pose) {
    let tweed = C(0x7C6A4C), tweedD = C(0x56462E), tweedL = C(0x9A8862), check = C(0x8E5236)
    let weave = C(0x6C5C40)
    let blouse = C(0xF0E8D8), blouseD = C(0xCCC0AA), pearl = C(0xFAF8F2), pearlD = C(0xB4B0A8)
    let hair = C(0xD6BA80), hairD = C(0xA88A50), hairL = C(0xF0DCA6)

    // Tan tights, lit down the front of each leg below the hem, and dark brown court shoes.
    drawLegs(c, Look(leg: C(0xC0937A)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 40 : 41
            c.rect(lx, top, 1, 2, C(0xD8AE94))
        }
    }
    drawBoots(c, C(0x3A2418), step: p.step, rows: 1)

    c.oy += p.breathe
    // The pencil skirt to the knee, the tweed shaded down its far side, a kick pleat at the back, the hem darker.
    if seatedPose {
        c.rect(17, 38, 22, 1, tweed)
    } else {
        hv6Tweed(c, 18, 38, 20, 2, base: tweed, dark: weave, light: tweedL, check: check)
        c.rect(18, 40, 20, 1, tweedD); c.rect(18, 38, 1, 2, tweedL)
        c.rect(37, 38, 1, 3, tweedD); c.rect(20, 39, 1, 2, tweedD)
    }
    drawBody(c, Look(arm: tweed), armRight: 0)

    // The jacket: tweed all over, shoulders lit, a notched collar open on the blouse, the pearls round her neck, two
    // horn buttons below, pocket flaps, the far side and the hem in shade.
    hv6Tweed(c, 18, 33, 20, 5, base: tweed, dark: weave, light: tweedL, check: check)
    c.rect(19, 33, 4, 1, tweedL); c.rect(33, 33, 3, 1, tweedL)
    c.rect(25, 33, 6, 1, blouseD); c.rect(26, 34, 4, 1, blouse); c.rect(27, 35, 2, 1, blouseD)
    c.rect(23, 33, 2, 1, tweedL); c.px(24, 34, tweedL); c.px(25, 35, tweedL)          // the near lapel, lit
    c.rect(31, 33, 2, 1, tweedD); c.px(31, 34, tweedD); c.px(30, 35, tweedD)          // the far lapel, in shade
    c.px(22, 34, tweedD); c.px(33, 34, tweedD)                                       // the notches
    for (x, y) in [(23, 33), (25, 33), (26, 34), (28, 34), (30, 33), (32, 33)] { c.px(x, y, pearl) }
    for (x, y) in [(24, 33), (27, 34), (29, 34), (31, 33)] { c.px(x, y, pearlD) }
    c.px(28, 36, C(0x4A3624)); c.px(28, 37, C(0x4A3624))
    c.rect(20, 36, 4, 1, tweedD); c.rect(32, 36, 3, 1, tweedD)
    c.rect(37, 33, 1, 5, tweedD); c.rect(18, 37, 20, 1, tweedD)
    c.rect(15, 35, 3, 1, tweedD); c.px(15, 34, blouse)                                // a silk cuff at the far wrist

    // The chignon at the back of her head, a coil lit on top.
    c.pattern(12, 21, [
        "..hhhh.",
        ".hHlHHh",
        "hHlHHHH",
        "hHHHHhH",
        ".hHHHHH",
        "..hhhh.",
    ], ["H": hair, "h": hairD, "l": hairL])
    // Smooth blonde hair from a side parting, every strand swept back to it, close round the ears.
    c.pattern(16, 20, [
        ".......HHHHHHHHHH......",
        "....HHHHlllHHHHHHHH....",
        "...HHHlllHHHHHHHHHHH...",
        "..HHlHHHHHlllHHHhHHHH..",
        ".HHHHHHlHHHHHHHHHhHHHH.",
        ".HHHHHHHHHHHHHHHHHhHHH.",
        ".HHHh.............hHHH.",
        ".HHh...............hHh.",
        "..Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The pistol: a slim black slide lit along its top, the long matte silencer screwed onto the barrel with a band
    // round its end, the grip in her fist. It kicks up `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGLLLLLLLl",
        "..KKKKKKMMMMMMMm",
        "OOOKk.k.........",
        "OOOK............",
        ".OK.............",
    ], ["G": C(0x4A4C54), "K": C(0x1C1C20), "k": C(0x101012), "L": C(0x70747C), "M": C(0x3C3E44),
        "l": C(0x2A2C30), "m": C(0x202226), "O": clawdOrange])
}

// MARK: - Arthur Ketch

/// Arthur Ketch, the British Men of Letters' killer: short dark hair neatly side-parted, a fitted black suit open on a
/// white shirt and a slim black tie, and weapons everywhere: the hilt of a big knife over his shoulder from the sheath
/// on his back, a shoulder holster's strap and a second pistol under his jacket, a knife sheathed on his hip. Fights
/// with a chunky gunmetal pistol with a torch fixed under the barrel. Signature: he straightens his tie, a tug at the
/// knot one way and the other, then smooths it flat.
private func drawArthurKetch(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x26272E), suitD = C(0x131419), suitL = C(0x464852)
    let shirt = C(0xF0F0EE), tie = C(0x0E0E12), tieL = C(0x383842)
    let leather = C(0x5E3E24), leatherD = C(0x3A2414), steel = C(0xB8BCC4), steelL = C(0xEEF0F4)
    let hair = C(0x3A2A20), hairD = C(0x22180F), hairL = C(0x5C4636)
    let fix = hv6Span(p.signature, 0.06, 0.94)
    // While he fixes his tie: the hand up to the knot, tugging it one way, then the other, then running down it.
    let tug = fix > 0.2 && fix < 0.6 ? (Int(fix * 24) % 2 == 0 ? -1 : 1) : 0
    let smooth = fix >= 0.6 && fix < 0.85 ? (fix - 0.6) / 0.25 : -1

    // Behind him, the hilt of the knife in the sheath on his back, over his far shoulder: a steel pommel, the dark
    // grip, the guard.
    c.pattern(12, 19, [
        ".LS...",
        ".SSs..",
        "..GG..",
        "..gGG.",
        "...GG.",
        "..SSSS",
        "...gG.",
    ], ["L": steelL, "S": steel, "s": C(0x7A7E86), "G": leather, "g": leatherD])

    drawLegs(c, Look(leg: C(0x2C2D34)), step: p.step)
    drawBoots(c, C(0x0C0C0E), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx + 1, p.step >= 0 && i % 2 == p.step ? 42 : 43, C(0x40404A))   // a shine on each toe
        }
    }

    c.oy += p.breathe
    // The knife on his far hip, its sheath hanging below the jacket, the pommel catching the light.
    if !seatedPose {
        c.rect(16, 36, 2, 4, leather); c.px(16, 36, C(0x7A5434)); c.px(17, 39, leatherD)
        c.px(16, 35, steel); c.px(17, 35, steelL)
    }
    // The jacket's hem, a row below the body.
    c.rect(18, 38, 20, 1, suit); c.px(18, 38, suitL); c.rect(29, 38, 1, 1, suitD); c.px(37, 38, suitD)
    drawBody(c, Look(arm: suit), armRight: fix >= 0 ? 1 : 0)

    // The suit jacket open on the shirt and tie: narrow lapels lit along the near edge, the shoulder holster's strap
    // and the grip of the second pistol inside the jacket, a pocket flap, the far side in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 4, shirt); c.rect(26, 37, 4, 1, shirt)
    c.rect(24, 33, 1, 4, suitL); c.px(25, 36, suitL); c.rect(31, 33, 1, 4, suitD); c.px(30, 36, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL); c.rect(19, 34, 1, 3, suitL)
    c.rect(23, 34, 1, 3, leather); c.px(22, 33, leather)                                // the holster strap
    c.rect(21, 35, 2, 2, C(0x18181C)); c.px(21, 35, C(0x4A4C54))                         // the second pistol's grip
    c.rect(33, 36, 3, 1, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(15, 34, shirt)
    // The tie: its knot (tugged one way or the other while he fixes it) and the blade down the shirt.
    c.rect(27 + tug, 33, 2, 1, tie); c.px(27 + tug, 33, tieL)
    c.rect(27, 34, 2, 4, tie); c.px(27, 35, tieL)
    if tug != 0 { c.px(tug < 0 ? 28 : 27, 34, tieL) }                                // the blade pulled askew

    // Short dark hair, side-parted and combed neat, a gleam along the parting, short sideburns.
    c.pattern(17, 21, [
        "......HHHHHHHH........",
        "...HHHHHHHHHlllHHH....",
        "..HHHHHlllllHHHHHHH...",
        ".HHHHhHHHHHHHHHHHHHHH.",
        ".HhHHHHHHhHHHHHHHHHhH.",
        ".HH................HH.",
        ".Hh................h..",
        "..h...................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if fix >= 0 {
        // His hand across his chest at the knot (or running down the tie), the sleeve from his shoulder, a white cuff.
        let up = min(1, fix / 0.14, (1 - fix) / 0.12)
        let hx = 29 + Int(((1 - up) * 9).rounded()), hy = smooth >= 0 ? 33 + Int(smooth * 2) : 33
        c.rect(hx + 3, hy + 1, max(0, 38 - hx - 3), 2, suit); c.rect(hx + 3, hy + 1, max(0, 38 - hx - 3), 1, suitL)
        c.px(hx + 3, hy + 2, shirt)
        c.rect(hx, hy, 3, 3, clawdOrange); c.rect(hx, hy + 2, 3, 1, clawdShade); c.px(hx, hy, clawdShade)
        return   // the pistol back in its holster while he does it
    }

    // The pistol: a chunky gunmetal slide lit along the top, the black frame, and a torch clamped under the barrel,
    // its lens a pale point at the front. It kicks up `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGGGGl",
        "..KKKKKKKKKK",
        "OOOKk.kTTTTW",
        "OOOK........",
        ".OK.........",
    ], ["G": C(0x6A6E76), "l": C(0x9EA4AE), "K": C(0x2A2C32), "k": C(0x18181C), "T": C(0x1E1E22),
        "W": C(0xF4F0C8), "O": clawdOrange])
}

// MARK: - Gordon Walker

/// Gordon Walker, the hunter who hunted Sam: close-cropped black hair, an olive drab field jacket with its collar up,
/// epaulettes and two flapped chest pockets, open over a black tee, charcoal jeans and heavy brown boots. Fights with a
/// long, broad machete (his way with vampires); when he swings it his mouth pulls back on two little fangs, since
/// he became one of them in the end. Signature: he lifts the machete and runs a whetstone down its edge, three long
/// strokes, sparks flicking off the steel.
private func drawGordonWalker(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x56593A), jacketD = C(0x3A3D26), jacketL = C(0x767A50)
    let tee = C(0x222226), teeL = C(0x3A3A42)
    let hair = C(0x16120F), hairL = C(0x342A24)
    let grip = C(0x1A1614), gripL = C(0x4A4038), steel = C(0x8E949C), steelD = C(0x5A6068), edge = C(0xC8CED6)
    let hone = hv6Span(p.signature, 0.05, 0.95)

    // Charcoal jeans, and heavy brown boots, laced, a shade apart.
    drawLegs(c, Look(leg: C(0x3A3A42)), step: p.step)
    drawBoots(c, C(0x5C4228), step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx + 1, p.step >= 0 && i % 2 == p.step ? 41 : 42, C(0x8A6A44))   // the laces
        }
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: hone >= 0 ? 1 : 0)

    // The field jacket: the collar up round his neck, epaulettes lit on the shoulders, the zip open on the black tee,
    // two chest pockets with flaps and buttons, a drawstring at the waist, the far side in shade.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, tee); c.rect(26, 33, 4, 1, teeL)
    c.rect(20, 32, 4, 1, jacketL); c.rect(32, 32, 4, 1, jacketD); c.px(24, 33, jacketL); c.px(31, 33, jacketD)
    c.rect(18, 33, 3, 1, jacketL); c.rect(34, 33, 3, 1, jacketL)
    c.rect(20, 34, 4, 1, jacketD); c.rect(20, 35, 4, 2, jacket); c.px(21, 34, C(0x2A2C1C))     // the near pocket
    c.rect(32, 34, 4, 1, jacketD); c.px(34, 34, C(0x2A2C1C))                                    // the far pocket
    c.rect(24, 34, 1, 4, jacketL); c.rect(31, 34, 1, 4, jacketD)
    c.rect(18, 37, 20, 1, jacketD); c.px(22, 37, jacketL); c.px(33, 37, jacketL)
    c.rect(37, 33, 1, 5, jacketD); c.rect(19, 35, 1, 2, jacketL)
    c.rect(15, 35, 3, 1, jacketD)

    // Close-cropped black hair, a cap of fine stubble that catches the light in short strokes.
    c.pattern(17, 24, [
        "...HHHHHHHHHHHHHH....",
        "..HHlHHlHHHlHHHlHHH..",
        ".HHHHHHHHHHHHHHHHHHH.",
        ".HH...............HH.",
    ], ["H": hair, "l": hairL])
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)

    if let a = p.melee {
        // The grimace and the fangs.
        c.rect(26, 31, 4, 1, C(0x2A0C10)); c.px(26, 32, C(0xF6F2EA)); c.px(29, 32, C(0xF6F2EA))
        drawMachete(c, p.trail, angle: a, grip: grip, gripL: gripL, steel: steel, steelD: steelD, edge: edge)
        return
    }
    if hone >= 0 {
        // Up from his side to held out level, the whetstone run down the edge three times, and back down.
        let lift = min(1, hone / 0.14, (1 - hone) / 0.12)
        let a = 80 - lift * 140
        drawMachete(c, [], angle: a, grip: grip, gripL: gripL, steel: steel, steelD: steelD, edge: edge)
        let run = hv6Span(hone, 0.16, 0.86)
        if run >= 0 {
            let k = (run * 3).truncatingRemainder(dividingBy: 1)
            let n = (x: -sin(a * .pi / 180), y: cos(a * .pi / 180))
            let at = huntReach(huntHand, a, 4 + k * 8)
            let sx = Int((at.x + n.x * 2).rounded()) - 1, sy = Int((at.y + n.y * 2).rounded())
            c.rect(sx, sy, 3, 2, C(0x8A8478)); c.rect(sx, sy, 3, 1, C(0xB6AE9C))      // the stone
            c.rect(sx, sy + 2, 3, 1, clawdOrange); c.px(sx + 2, sy + 2, clawdShade)     // his fingers under it
            if k > 0.25 && k < 0.9 {
                let f = Int(p.t * 20) % 2
                c.px(sx + 3 + f, sy - 1, C(0xFFE08A, 0.95)); c.px(sx + 4, sy - 2 - f, C(0xFFC050, 0.7))
            }
        }
        return
    }
    // At rest, point down at his side: the fist round the grip, the broad blade's spine dark and its edge lit.
    c.rect(39, 34, 2, 3, grip); c.px(39, 35, gripL)
    c.rect(39, 37, 3, 5, steel); c.rect(39, 37, 1, 5, steelD); c.rect(41, 37, 1, 5, edge)
    c.rect(40, 42, 2, 1, steel); c.px(41, 42, edge)
    c.rect(38, 33, 3, 2, clawdOrange)
}

/// Gordon's machete from the hand along `angle`: the black grip with a rivet, a small guard, and the long broad blade,
/// its spine dark, its edge lit, a smear behind a fast swing.
private func drawMachete(_ c: PixelCanvas, _ trail: [Double], angle a: Double, grip: Px, gripL: Px, steel: Px,
                         steelD: Px, edge: Px) {
    let h = huntHand
    huntSmear(c, h, trail, from: 2, to: 14, C(0xF0F4FF))
    huntBar(c, h, a, from: -2.5, to: 1.5, grip, r: 1)
    let rivet = huntReach(h, a, -1.5)
    c.px(Int(rivet.x.rounded()), Int(rivet.y.rounded()), gripL)
    let n = (x: -sin(a * .pi / 180), y: cos(a * .pi / 180))
    let g = huntReach(h, a, 2)
    huntLine(c, g.x - n.x * 1.5, g.y - n.y * 1.5, g.x + n.x * 1.5, g.y + n.y * 1.5, C(0x3A3632), 0.6)   // the guard
    huntBar(c, h, a, from: 2.5, to: 13, steelD, r: 1.3)
    let p0 = huntReach(h, a, 2.5), p1 = huntReach(h, a, 13)
    huntLine(c, p0.x + n.x * 0.6, p0.y + n.y * 0.6, p1.x + n.x * 0.6, p1.y + n.y * 0.6, steel, 0.8)
    huntLine(c, p0.x + n.x * 1.3, p0.y + n.y * 1.3, p1.x + n.x * 1.1, p1.y + n.y * 1.1, edge, 0.45)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)   // the fist round the grip
}

// MARK: - Bela Talbot

/// Bela Talbot, the thief who sells what hunters need: a sleek near-black bob with a side-swept fringe, red lips, a
/// knee-length plum wrap coat with a wide shawl collar and its belt knotted at her hip, a cream silk top and a gold
/// pendant under it, black stockings and heeled black boots. Fights with a small gold-plated pistol, as chic as she is.
private func drawBelaTalbot(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x5C2A4A), coatD = C(0x3E1A32), coatL = C(0x80486A), collar = C(0x6E3858)
    let top = C(0xEEE4D4), topD = C(0xC8BCA8), gold = C(0xE4BC52), lips = C(0xB01E2E)
    let hair = C(0x2A1C18), hairD = C(0x160E0C), hairL = C(0x4E362C)

    // Black stockings, a sheen down the front, and heeled black boots.
    drawLegs(c, Look(leg: C(0x26222A)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, C(0x423C48))
        }
    }
    drawBoots(c, C(0x121014), step: p.step, rows: 2)

    c.oy += p.breathe
    // The coat's skirts to the knee, wrapped across, a fold over each leg, the hem in shade.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 22, 1, coatD)
        c.rect(17, 38, 1, 2, coatL); c.rect(38, 38, 1, 3, coatD)
        for x in [21, 25, 34] { c.rect(x, 38, 1, 2, coatD) }
        c.rect(30, 38, 1, 3, C(0x2A1022))                                          // where the wrap crosses
        c.rect(32, 38, 1, 3, coatD); c.px(33, 40, coatD)                           // the belt's ends hanging
    }
    drawBody(c, Look(arm: coat), armRight: 0)

    // The coat over the body: a wide shawl collar lit along its roll, crossing over a cream top, the gold pendant, the
    // belt knotted at her hip, the far side in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 5, 2, top); c.rect(26, 35, 2, 1, top); c.px(29, 34, topD)
    c.px(27, 34, gold); c.px(26, 33, C(0xB8923A)); c.px(28, 33, C(0xB8923A))
    c.rect(21, 33, 4, 1, coatL); c.rect(22, 34, 3, 1, collar); c.rect(24, 35, 2, 1, collar); c.px(23, 34, coatL)
    c.rect(30, 33, 4, 1, collar); c.rect(30, 34, 2, 1, coatD); c.rect(28, 36, 2, 1, coatD)
    c.rect(18, 36, 20, 1, coatD); c.rect(31, 36, 3, 2, collar); c.px(32, 37, coatD)     // the belt and its knot
    c.rect(19, 33, 2, 1, coatL); c.rect(34, 33, 2, 1, coatL); c.rect(19, 34, 1, 2, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD); c.rect(31, 37, 2, 1, collar)
    c.rect(15, 35, 3, 1, coatD)

    // The bob: near-black, glossy, cut level with her jaw and curling under, the fringe swept across her brow.
    c.pattern(16, 20, [
        ".......................",
        "......HHHHHHHHHHH......",
        "...HHHHHlllllHHHHHHH...",
        "..HHHlllHHHHHHHlllHHH..",
        ".HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHHHHHHHHHHHhd.HHH",
        "HHHHhd.....dHHHd....HHH",
        "HHlHh...............dHH",
        "HHHHh...............dHH",
        "HlHHh...............dHH",
        "HHlHh...............dHH",
        ".HHHh...............HHd",
        "..dd...............dd..",
    ], ["H": hair, "h": hairD, "d": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    c.rect(26, 32, 3, 1, lips); c.px(29, 32, C(0x7A1420))

    // The pistol: small and gold-plated, the slide lit along its top, a darker gold frame, the grip in her fist. It
    // kicks up `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..YYYYYy",
        "..ggggg.",
        "OOOgk...",
        "OOOg....",
        ".Og.....",
    ], ["Y": C(0xF0CC5A), "y": C(0xFFF0B8), "g": C(0xA87C22), "k": C(0x5A4010), "O": clawdOrange])
}

// MARK: - The Alpha Vampire

/// The Alpha Vampire, the first of them, dressed as he was in the 1800s: a long frock coat of black-wine wool to the
/// knee with a high black velvet collar, a waistcoat of old gold brocade with a watch chain, a white shirt collar and
/// a black silk cravat with a garnet pin, dark trousers and tall riding boots; dark hair swept back, grey at the
/// temples, and long Victorian sideburns. Fights with his fangs: his mouth opens on the second row of teeth and he
/// rakes with his long nails. Signature: his fangs drop slowly, one pixel at a time, a row of them, and slide back.
private func drawAlphaVampire(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2E1C26), coatD = C(0x180E14), coatL = C(0x4E3444)
    let velvet = C(0x140A10), velvetL = C(0x3C2432)
    let vest = C(0x7E6028), vestD = C(0x54401A), vestL = C(0xA88644), chain = C(0xE0C060)
    let cravat = C(0x18141A), cravatL = C(0x3C3444), shirt = C(0xF0ECE2), garnet = C(0xA0101E)
    let hair = C(0x241C1C), hairD = C(0x120C0C), hairL = C(0x40343A), grey = C(0x8E8A90)
    let tooth = C(0xF6F2EA), toothD = C(0xC8C0B4), mouth = C(0x2A060C)
    let s = hv6Span(p.signature, 0.04, 0.96)
    // How far the fangs are down (0…3): slowly down, held, back up; out while he fights.
    let fangs: Int = p.melee != nil ? 3 : s < 0 ? 0 :
        s < 0.12 ? 0 : s < 0.5 ? Int((s - 0.12) / 0.38 * 3.99) : s < 0.78 ? 3 : s < 0.92 ? Int((0.92 - s) / 0.14 * 3.99) : 0
    let open = p.melee != nil || (s > 0.06 && s < 0.94)

    // Dark trousers and tall black riding boots, lit down the shin.
    drawLegs(c, Look(leg: C(0x3A3640)), step: p.step)
    drawBoots(c, C(0x0E0C10), step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, b - 2, 1, 2, C(0x34303A))
        }
    }

    c.oy += p.breathe
    // The frock coat's skirts to the knee, longer at the back, open down the front, folds over the legs.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 12, 1, coat); c.rect(17, 41, 7, 1, coatD)
        c.rect(29, 40, 10, 1, coatD); c.rect(17, 38, 1, 4, coatL)
        for x in [21, 25, 34] { c.rect(x, 38, 1, 2, coatD) }
        c.rect(29, 38, 1, 2, C(0x0A0608)); c.rect(38, 38, 1, 3, coatD)
    }
    drawBody(c, Look(arm: coat), armRight: 0)

    // The coat over the body, open on the waistcoat; the velvet collar standing high either side of the neck, lit on
    // its edge; the shirt's collar points, the black cravat with its garnet pin; the brocade and the watch chain.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 34, 8, 4, vest)
    for (x, y) in [(25, 35), (27, 36), (30, 35), (29, 37), (25, 37)] { c.px(x, y, vestL) }
    c.rect(31, 34, 1, 4, vestD); c.px(28, 35, vestD); c.px(28, 37, vestD)              // the buttons
    c.rect(25, 36, 3, 1, chain); c.px(24, 35, vestD)
    c.rect(26, 33, 4, 2, cravat); c.px(26, 33, cravatL); c.px(27, 34, garnet)
    c.px(25, 33, shirt); c.px(30, 33, shirt)
    c.rect(19, 32, 4, 2, velvet); c.rect(19, 32, 4, 1, velvetL); c.rect(33, 32, 4, 2, velvet); c.px(33, 32, velvetL)
    c.rect(23, 33, 1, 5, coatL); c.rect(32, 33, 1, 5, coatD)
    c.rect(19, 34, 1, 3, coatL); c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD); c.px(15, 34, shirt)

    // Dark hair swept back from a high brow, a gleam along it, grey at the temples, and long sideburns down the cheeks.
    c.pattern(17, 21, [
        "......HHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHlllHHHHHlllHHHH...",
        ".HHHHHHHHlllHHHHHHHHH.",
        ".HHhHHHHHHHHHHHHHhHHH.",
        ".HgHg.............gHH.",
        ".HHg..............HgH.",
        ".HH................HH.",
        ".Hh................hH.",
        ".hh................hh.",
        ".h..................h.",
    ], ["H": hair, "h": hairD, "l": hairL, "g": grey])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if open {
        // The mouth open, and the second row of fangs coming down over the cravat.
        c.rect(25, 31, 6, 2, mouth)
        for x in [25, 26, 29, 30] {
            let len = (x == 26 || x == 29) ? fangs : max(0, fangs - 2)
            if len > 0 { c.rect(x, 31, 1, len, tooth); if len > 1 { c.px(x, 30 + len, toothD) } }
        }
    }

    // His raking hand: long pale nails out from the fist along `p.melee`, a smear behind a fast swing.
    if let a = p.melee {
        let h = huntHand
        huntSmear(c, h, p.trail, from: 2, to: 7, C(0xFFE0E4))
        let n = (x: -sin(a * .pi / 180), y: cos(a * .pi / 180))
        for o in [-1.2, 0, 1.2] {
            let p0 = huntReach(h, a, 1.5), p1 = huntReach(h, a, o == 0 ? 6.5 : 5.5)
            huntLine(c, p0.x + n.x * o, p0.y + n.y * o, p1.x + n.x * o, p1.y + n.y * o, C(0xE6DED4), 0.45)
        }
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
    }
}

// MARK: - Bloody Mary

/// Bloody Mary, the ghost in the mirror: an old oval looking glass in a gilt frame on its stand goes everywhere with
/// her, its silvering dark and a crack across one corner. She's a pale, cold version of Clawd with long wet black hair
/// hanging straight down either side of her face, a faint red light in her eyes, an old high-necked gown of dusty
/// mauve with a yellowed lace collar, its hem rotting into see-through rags. Her touch is a dark red glow. Signature:
/// she flickers out and is gone, and her face looks out of the mirror instead, eyes red; then it's gone too, the glass
/// cracks with a glint, and she flickers back where she stood.
private func drawBloodyMary(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature
    // How much of her is there: whole, or (flickering) all but gone; and when her face is in the glass.
    let gone = hv6Span(s, 0.04, 0.86)
    var alpha = 1.0
    if gone >= 0 {
        let flick = noise(Int(p.t * 18)) > 0.45
        alpha = gone < 0.16 ? (flick ? 1 : 0.14) : gone < 0.84 ? 0.1 : (flick ? 0.14 : 1)
    }
    let face = hv6Span(s, 0.18, 0.62)
    let crack = hv6Span(s, 0.6, 0.9)

    drawMaryMirror(c, p, face: face, crack: crack)
    hv6Ghost(c, alpha: alpha, tint: C(0xB8C4D4), k: 0.22, halo: C(0xC04050, 0.16)) { g in
        drawMaryBody(g, p)
    }
}

/// The mirror on Mary's far side: a tall gilt oval on a stand, lit on its top left, the glass dark and misty with a
/// glint; `face` (0…1) her face looking out of it, `crack` (0…1) the glass cracking with a glint and settling.
private func drawMaryMirror(_ c: PixelCanvas, _ p: Pose, face: Double, crack: Double) {
    let gilt = C(0xB08A3A), giltD = C(0x765818), giltL = C(0xE4C66E)
    let glass = C(0x2E3A46), glassD = C(0x222A34), mist = C(0x46525E), glint = C(0xA8B8C8)
    let cx = 8.0, cy = 27.0, rx = 5.6, ry = 10.2
    // The stand: a turned post and two feet on the floor.
    c.rect(7, 38, 2, 3, giltD); c.px(7, 38, gilt)
    c.rect(4, 41, 8, 1, gilt); c.rect(4, 42, 2, 1, giltD); c.rect(10, 42, 2, 1, giltD); c.rect(5, 41, 3, 1, giltL)
    // The oval: a frame two pixels deep, the glass inside.
    for y in 16...38 {
        for x in 2...14 {
            let e = pow((Double(x) - cx) / rx, 2) + pow((Double(y) - cy) / ry, 2)
            guard e <= 1 else { continue }
            if e > 0.6 {
                let lit = Double(x) < cx - 1 && Double(y) < cy
                let shade = Double(x) > cx + 1 || Double(y) > cy + 5
                c.px(x, y, lit ? giltL : shade ? giltD : gilt)
            } else {
                c.px(x, y, (x + y) % 5 == 0 ? mist : y > 30 ? glassD : glass)
            }
        }
    }
    // A little scrolled crest on top.
    c.rect(7, 15, 3, 1, gilt); c.px(8, 14, giltL); c.px(6, 16, giltD); c.px(10, 16, giltD)
    c.px(6, 21, glint); c.px(7, 20, glint); c.px(6, 22, mist)

    if face >= 0 {
        // Her face behind the glass, swimming up and fading out: the wet black hair either side, eyes lit red.
        let k = min(1, face / 0.2, (1 - face) / 0.2)
        let a = k > 0.5 ? 1.0 : 0.2
        c.pattern(5, 21 + Int((1 - k) * 2), [
            ".HHHHH.",
            "HHHHHHH",
            "HFFFFFH",
            "HEFFFEH",
            "HFFFFFH",
            "HHFFFHH",
            "HH...HH",
            "H.....H",
        ], ["H": C(0x0E0A0C, a), "F": C(0xB89488, a), "E": C(0xFF3A3A, a)])
        if k > 0.5 { c.px(6, 24, C(0xFF6A6A, 0.4)); c.px(10, 24, C(0xFF6A6A, 0.4)) }
    }
    // The old crack in one corner, and the new one that runs right across while she's away.
    c.px(11, 33, glint); c.px(10, 34, mist); c.px(12, 32, mist)
    if crack >= 0 {
        let fade = crack < 0.7 ? 1.0 : 0.25
        for (x, y) in [(4, 23), (5, 24), (6, 24), (7, 25), (8, 27), (9, 27), (10, 28), (11, 30), (8, 28), (7, 30)] {
            c.px(x, y, C(0xDCE6F0, fade))
        }
        if crack < 0.25 { c.px(7, 25, C(0xFFFFFF)); c.px(6, 23, C(0xFFFFFF, 0.6)) }
    }
}

/// Bloody Mary herself, opaque, for `hv6Ghost` to cool and fade.
private func drawMaryBody(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0x5A4A56), gownD = C(0x3A2E3A), gownL = C(0x7A6A76)
    let lace = C(0xE4DCC4), laceD = C(0xB4A88C)
    let hair = C(0x0E0A0C), hairD = C(0x050405), hairL = C(0x2E2830)

    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    drawBoots(c, C(0x16121A), step: p.step, rows: 1)

    c.oy += p.breathe
    // The gown to below the knee, folds over the legs; below its hem it rots into see-through rags.
    if seatedPose {
        c.rect(17, 38, 22, 1, gown)
    } else {
        c.rect(17, 38, 22, 3, gown); c.rect(17, 38, 1, 3, gownL); c.rect(38, 38, 1, 3, gownD)
        for x in [21, 25, 30, 34] { c.rect(x, 38, 1, 3, gownD) }
        for x in 17...38 where noise(x * 7) > 0.35 {
            let len = 1 + Int(noise(x * 11) * 2.5 + sin(p.lt * 2.4 + Double(x)) * 0.6)
            c.rect(x, 41, 1, len, gown.alpha(0.2))
        }
    }
    drawBody(c, Look(arm: gown, eye: nil), armRight: p.armRaise)

    // The bodice: the yellowed lace collar high round her neck, scalloped, a row of tiny buttons, the far side shaded.
    c.rect(18, 33, 20, 5, gown)
    c.rect(24, 33, 8, 1, lace); c.px(24, 34, lace); c.px(26, 34, lace); c.px(29, 34, lace); c.px(31, 34, lace)
    c.px(25, 34, laceD); c.px(30, 34, laceD)
    for y in [35, 36, 37] { c.px(28, y, laceD) }
    c.rect(19, 33, 4, 1, gownL); c.rect(19, 34, 1, 3, gownL); c.rect(22, 35, 1, 2, gownD); c.rect(33, 35, 1, 2, gownD)
    c.rect(37, 33, 1, 5, gownD); c.rect(18, 37, 20, 1, gownD)
    c.rect(15, 35, 3, 1, gownD)

    // Her eyes: dark, a faint red light low in each.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(22, 31, C(0x8A1424)); c.px(32, 31, C(0x8A1424))

    // Long wet black hair from a centre parting, hanging straight and lank either side of her face, past her
    // shoulders, the ends ragged; a lit streak where it's wet.
    c.pattern(15, 20, [
        "........HHHHHHHHH........",
        "......HHHHHHhHHHHHH......",
        "....HHHHlHHHhHHHlHHHH....",
        "...HHHlHHHHHhHHHHHlHHH...",
        "..HHHlHHHHHhhHHHHHHlHHH..",
        "..HHlHHHHHHh.hHHHHHHlHHH.",
        "..HHlHHHHh....hHHHHHlHHH.",
        "..HlHHd..........dHHHlHH.",
        ".HHlHd............dHHlHH.",
        ".HHlHd..............HlHHH",
        ".HHlHd..............HlHHH",
        ".HlHHd..............dHlHH",
        ".HlHH................HlHH",
        ".HlHH................HlHh",
        ".HHlH................HlHh",
        ".HlHh................hlHh",
        ".HHlH................HlH.",
        ".hHlh.................Hh.",
        "..H.h.................h..",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])

    // Her reaching hand, over the hair when it's raised to touch.
    if p.armRaise > 0 { c.rect(38, 33 - p.armRaise, 3, 3, clawdOrange); c.px(40, 35 - p.armRaise, clawdShade) }
}

// MARK: - The Woman in White

/// The Woman in White, the ghost who hitches on Centennial Highway: long dark hair in loose waves, a long white
/// dress with long sleeves and a little lace at the throat, a pale blue sash, its skirt to her ankles and its hem
/// trailing away in see-through wisps, bare feet that never touch the road. She hovers, cold, cooled pale blue with a
/// faint halo. Her touch is a pale blue glow. Signature: she flickers like a bad signal, tearing sideways, gone; shows
/// up again a little further down the road, flickers, and is back where she was.
private func drawWomanInWhite(_ c: PixelCanvas, _ p: Pose) {
    let s = hv6Span(p.signature, 0.04, 0.94)
    let on = noise(Int(p.t * 16)) > 0.4
    var alpha = 1.0, dx = 0, tear = false
    if s >= 0 {
        switch s {
        case ..<0.24: alpha = on ? 1 : 0.12; tear = true
        case ..<0.4: alpha = 0.08
        case ..<0.46: alpha = on ? 1 : 0.12; dx = 6; tear = true
        case ..<0.62: dx = 6
        case ..<0.72: alpha = 0.08; dx = 6
        default: alpha = on ? 1 : 0.12; tear = true
        }
    }
    let band = Int(p.t * 12)
    hv6Ghost(c, alpha: alpha, tint: C(0xD4ECFF), k: 0.26, halo: C(0xBEE4FF, 0.18), shift: { y in
        dx + (tear && (y + band) % 5 < 2 ? ((y / 5 + band) % 2 == 0 ? 2 : -2) : 0)
    }) { g in
        drawWomanInWhiteBody(g, p)
    }
}

/// The Woman in White, opaque, for `hv6Ghost` to cool, tear and fade.
private func drawWomanInWhiteBody(_ c: PixelCanvas, _ p: Pose) {
    let dress = C(0xF0F2F6), dressD = C(0xC6D0DE), dressL = C(0xFFFFFF), fold = C(0xDAE2EC), sash = C(0x9CC0DE)
    let hair = C(0x2A1E1C), hairD = C(0x160F0E), hairL = C(0x4A3832)

    // Bare legs, the feet hanging below the hem.
    drawLegs(c, Look(leg: clawdOrange), step: p.step)

    c.oy += p.breathe
    // The skirt, long, to just above her feet: soft folds down each leg, the far side in shade, and below the hem,
    // see-through wisps trailing off.
    c.rect(17, 38, 22, 4, dress)
    c.rect(17, 38, 1, 4, dressL); c.rect(38, 38, 1, 4, dressD); c.rect(17, 41, 22, 1, fold)
    for x in [21, 25, 29, 33] { c.rect(x, 38, 1, 4, fold) }
    c.rect(36, 38, 1, 4, dressD)
    for x in stride(from: 17, through: 38, by: 2) {
        let len = 1 + Int((sin(p.lt * 3 + Double(x) * 0.9) + 1) * 0.8)
        c.rect(x, 42, 1, len, dress.alpha(0.2))
    }
    drawBody(c, Look(arm: dress), armRight: p.armRaise)

    // The bodice: a little lace at the throat, a pale blue sash at the waist with its bow, the far side shaded.
    c.rect(18, 33, 20, 5, dress)
    c.rect(25, 33, 6, 1, fold); c.px(25, 33, dressL); c.px(27, 33, dressL); c.px(29, 33, dressL)
    c.rect(18, 36, 20, 1, sash); c.rect(20, 36, 2, 1, C(0x7EA4C8)); c.px(20, 37, sash)
    c.rect(22, 34, 1, 2, fold); c.rect(33, 34, 1, 2, fold)
    c.rect(37, 33, 1, 5, dressD); c.rect(18, 37, 20, 1, fold)
    c.rect(15, 35, 3, 1, dressD); c.rect(38, 35 - p.armRaise, 3, 1, dressD)

    // Long dark hair in loose waves, parted at the side, falling over her shoulders and down her back.
    c.pattern(15, 20, [
        "........HHHHHHHHH........",
        "......HHHHHlllHHHHH......",
        "....HHHHlllHHHHHHHHHH....",
        "...HHHlHHHHHHHHHHlHHHH...",
        "..HHlHHHHHHHHHHHHHHlHHH..",
        "..HHlHHHHHHHHHHHHHHHlHHH.",
        "..HlHHHHh.......hHHHHlHH.",
        ".HHlHHh...........hHHlHH.",
        ".HlHHd.............dHlHH.",
        "HHlHHd..............dHlHH",
        ".HHlHd..............dHHl.",
        "HlHHd................HlHH",
        ".HlHH................HHl.",
        "HHlHd................dHlH",
        ".HlHH.................Hl.",
        "..HlH.................dH.",
        "..hHd....................",
        "...h.....................",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if p.armRaise > 0 { c.rect(38, 33 - p.armRaise, 3, 3, clawdOrange); c.px(40, 35 - p.armRaise, clawdShade) }
}
