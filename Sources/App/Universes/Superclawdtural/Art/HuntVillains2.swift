import Foundation

// Villains: the demons, from the Yellow-Eyed Demon to the Prince of Hell in his white suit. Drawn the same way as the
// heroes (HuntHeroes1.swift); Clawd in costume, each one in the clothes of the vessel they wore longest. A demon shows
// itself in its eyes: black, yellow, red or white. Clawd's own eyes are already dark, so a demon's eyes take a colour,
// or grow a pixel all round and fill black, rather than changing a single pixel (`hvEyes`).
//
// Magic (`weapon: .lightning`): `magic:` says how the stream looks, and the engine draws it from `pivot` (the casting
// hand, raised `p.armRaise` pixels: draw the arm raised as much). Don't set `magic.variant` yourself: the engine
// numbers every magic user in order through all the universes, so no two anywhere look exactly alike.

let huntVillains2: [HuntVillain: Persona] = [
    .azazel: Persona(name: "Azazel", weapon: .lightning,
                     magic: Magic(core: C(0xFFF6C0), glow: C(0xE8B818), jagged: false, rings: true),
                     headTop: 23, signature: 2.6, callout: "Hey, Sammy.", draw: drawAzazel),
    .megMasters: Persona(name: "Meg Masters", weapon: .saber, headTop: 21, signature: 2.8, callout: "Hey, Clarence.",
                         draw: drawMegMasters),
    .ruby: Persona(name: "Ruby", weapon: .saber, headTop: 20, signature: 2.8, draw: drawRuby),
    .lilith: Persona(name: "Lilith", weapon: .lightning, magic: Magic(core: C(0xFFFFFF), glow: C(0xDCD6F2)),
                     headTop: 21, signature: 3.0, draw: drawLilith),
    .alastair: Persona(name: "Alastair", weapon: .lightning,
                       magic: Magic(core: C(0xFFFFFF), glow: C(0xB4BCCC), jagged: false, rings: true),
                       headTop: 21, signature: 3.6, draw: drawAlastair),
    .abaddon: Persona(name: "Abaddon", weapon: .lightning,
                      magic: Magic(core: C(0xFFD4E0), glow: C(0xD0204C), jagged: false, grip: true),
                      pivot: (43.5, 34), headTop: 19, signature: 3.4, draw: drawAbaddon),
    .cain: Persona(name: "Cain", weapon: .saber, headTop: 21, signature: 3.6, draw: drawCain),
    .asmodeus: Persona(name: "Asmodeus", weapon: .lightning, magic: Magic(core: C(0xFFFCE6), glow: C(0xF0C81E)),
                       headTop: 21, signature: 3.0, draw: drawAsmodeus),
]

// MARK: - Shared bits

/// Demon eyes over Clawd's own (draw the body with `eye: nil`): both eyes in `col`, with the bottom row in `low`.
/// `big` grows each one a pixel up and outwards to 3×4, so the change reads at 1×; `glint` lights the top left pixel;
/// `glow` hazes round each eye, see-through, `k` strong.
private func hvEyes(_ c: PixelCanvas, _ col: Px, low: Px? = nil, big: Bool = false, glint: Px? = nil,
                    glow: Px? = nil, k: Double = 0) {
    for left in [true, false] {
        let x = big ? (left ? 21 : 32) : (left ? 22 : 32), y = big ? 28 : 29
        let w = big ? 3 : 2, h = big ? 4 : 3
        if let glow, k > 0 {
            for yy in (y - 2)...(y + h + 1) {
                for xx in (x - 2)...(x + w + 1) {
                    let dx = xx < x ? x - xx : xx >= x + w ? xx - (x + w - 1) : 0
                    let dy = yy < y ? y - yy : yy >= y + h ? yy - (y + h - 1) : 0
                    let d = max(dx, dy)
                    guard d > 0 else { continue }
                    c.px(xx, yy, glow.alpha(k * (d == 1 ? 0.5 : 0.2)))
                }
            }
        }
        c.rect(x, y, w, h, col)
        if let low { c.rect(x, y + h - 1, w, 1, low) }
        if let glint { c.px(x, y, glint) }
    }
}

/// Black eyes: grown a pixel up and in towards the nose (so they stay clear of the hair framing the face) and filled
/// black from edge to edge, glossy like wet ink: a bright white glint at the top left with a paler run under it, and a
/// cold blue sheen at the bottom right. The shine is what tells them from Clawd's own dark eyes at 1×.
private func hvBlackEyes(_ c: PixelCanvas) {
    for x in [22, 31] {
        c.rect(x, 28, 3, 4, C(0x060608))
        c.px(x, 28, C(0xF6F8FF)); c.px(x, 29, C(0x8C96B0)); c.px(x + 1, 28, C(0x5A6480))
        c.px(x + 2, 31, C(0x3C4866))
    }
}

/// A knife held point down at the side, the fist round its grip, for whoever carries one when not fighting.
private func hvKnifeAtRest(_ c: PixelCanvas, grip: Px, steel: Px, steelD: Px, edge: Px, notch: Px? = nil,
                           length: Int = 4) {
    c.rect(39, 34, 2, 3, grip)
    if let notch { c.px(39, 35, notch) }
    c.rect(39, 37, 2, length, steel); c.rect(40, 37, 1, length, steelD); c.px(40, 36 + length, edge)
    c.rect(38, 34, 3, 2, clawdOrange)
}

// MARK: - Azazel

/// Azazel, the Yellow-Eyed Demon: an everyday man you'd pass in the street, in a tan canvas work jacket with a
/// corduroy collar and two flapped chest pockets, open over a chambray shirt, grey slacks and brown shoes, his grey
/// hair cropped short and receding off a high brow. Only his eyes give him away: they're yellow. His telekinesis is
/// yellow rings. Signature: his eyes flash, swelling and burning bright yellow, then settle.
private func drawAzazel(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0xA08458), jacketD = C(0x735C3A), jacketL = C(0xC0A274), cord = C(0x5E4A2E)
    let shirt = C(0x8EA4BE), shirtD = C(0x687E98), shirtL = C(0xB0C2D6)
    let hair = C(0x7A7066), hairD = C(0x56504A), hairL = C(0x9E968A)
    let s = p.signature ?? -1
    let flash = s > 0.1 && s < 0.9 ? sin((s - 0.1) / 0.8 * .pi) : 0

    // Grey slacks with a lit crease down each leg, and brown shoes.
    drawLegs(c, Look(leg: C(0x55504A)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 37 : 38
            c.rect(lx, top, 1, 3, C(0x625C56))
        }
    }
    drawBoots(c, C(0x3A2416), step: p.step, rows: 1)

    c.oy += p.breathe
    // The jacket's hem, just past his waist.
    if !seatedPose { c.rect(18, 38, 20, 1, jacketD); c.px(18, 38, jacket); c.px(28, 38, cord) }
    drawBody(c, Look(arm: jacket, eye: nil), armRight: p.armRaise)

    // The jacket, open on the shirt: the shirt's collar spread over the jacket's, a button placket down it, the neck
    // showing in the V.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, shirt); c.rect(30, 33, 1, 5, shirtD); c.rect(28, 35, 1, 3, shirtD)
    c.rect(27, 33, 2, 1, clawdShade)
    c.px(25, 33, shirtL); c.px(26, 34, shirtL); c.px(30, 33, shirtL); c.px(29, 34, shirtL)
    // The corduroy collar, lit on the near side; the far side of the jacket and its hem in shade.
    c.rect(23, 33, 2, 1, cord); c.rect(31, 33, 2, 1, cord); c.rect(24, 34, 1, 3, cord); c.rect(31, 34, 1, 3, cord)
    c.rect(19, 33, 3, 1, jacketL); c.rect(33, 33, 3, 1, jacketL); c.rect(19, 34, 1, 3, jacketL)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    // Two chest pockets, their flaps a shade darker, a button on each.
    c.rect(20, 35, 3, 1, jacketD); c.rect(33, 35, 3, 1, jacketD); c.px(21, 36, cord); c.px(34, 36, cord)
    c.rect(15, 35, 3, 1, jacketD)
    c.rect(38, 35 - p.armRaise, 3, 1, jacketD)   // the near cuff

    // Grey hair cropped short, thin on top and receding at the temples, so his brow shows high and bare.
    c.pattern(17, 23, [
        "....HHHHHHHHHHHHH.....",
        "..HHllHHHHllHHHHllH...",
        ".HHHHHHHHHHHHHHHHHHH..",
        ".HHhhHH.........hhHHH.",
        ".HHh..............hHH.",
        ".Hh................hH.",
        ".H..................H.",
    ], ["H": hair, "h": hairD, "l": hairL])

    // The yellow eyes: amber underneath at rest; at the flash grown, burning pale yellow in a yellow haze, under a
    // lowered brow.
    if flash > 0.25 {
        hvEyes(c, C(0xFFF4A8), low: C(0xF0C21E), big: true, glow: C(0xFFD21E), k: flash)
        c.rect(21, 27, 3, 1, hairD); c.rect(32, 27, 3, 1, hairD)
    } else {
        hvEyes(c, C(0xF2C828), low: C(0xB4800E))
        c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    }
}

// MARK: - Meg Masters

/// Meg Masters: long straight hair so dark it's nearly black, a black leather jacket with silver zips open over a
/// deep red top, black jeans and black boots. Fights with a plain steel knife. Signature: her black eyes flick on: a
/// blink, then they're black from edge to edge, glinting, with a smirk; then a blink back.
private func drawMegMasters(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x26242C), jacketD = C(0x121116), jacketL = C(0x4C4856), zip = C(0xB4B8C2)
    let top = C(0x6E1E2C), topD = C(0x4A1420), topL = C(0x8E2E3E)
    let hair = C(0x2A1C18), hairD = C(0x150E0C), hairL = C(0x4C342A)
    let s = p.signature ?? -1
    let blink = (s > 0.08 && s < 0.13) || (s > 0.87 && s < 0.92)
    let black = s >= 0.13 && s <= 0.87

    // Black jeans lit down the front, and black boots a shade deeper, their toes catching the light.
    drawLegs(c, Look(leg: C(0x40404C)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 2, C(0x56566A)) } }
    drawBoots(c, C(0x141416), step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.px(lx + 1, p.step >= 0 && i % 2 == p.step ? 42 : 43, C(0x3A3A42))
        }
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: nil))

    // The leather jacket open on the red top: its lapels lit along the edge, a silver zip down each side of the
    // opening, the far side and the hem in shade, a zipped pocket.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(24, 33, 8, 5, top); c.rect(26, 33, 4, 1, clawdShade); c.rect(31, 34, 1, 4, topD)
    c.rect(25, 34, 1, 3, topL); c.rect(24, 37, 8, 1, topD)
    c.rect(23, 33, 1, 5, jacketL); c.rect(22, 33, 1, 2, jacketL); c.rect(32, 33, 1, 5, jacketD)
    c.rect(33, 33, 1, 2, jacketL)
    c.px(23, 35, zip); c.px(23, 37, zip); c.px(32, 36, zip)
    c.rect(19, 33, 2, 1, jacketL); c.rect(35, 33, 2, 1, jacketL)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(19, 36, 3, 1, jacketD); c.px(21, 36, zip)
    c.rect(15, 35, 3, 1, jacketD)

    // Long dark hair, falling straight past her shoulders, a fringe swept to one side.
    c.pattern(16, 21, [
        "......HHHHHHHHHHHH......",
        "....HHHllHHHHHHllHHH....",
        "...HHHHHHllHHHHHHllHH...",
        "..HHllHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHdHHHHHHHHHHH..",
        ".HHlHHHHHHHdHHHHHHHHlHH.",
        ".HHlHdHHHHH.....HHHHHlH.",
        ".HHlH.............HHlHH.",
        ".HHHd..............dHlH.",
        ".HlHd..............dHlH.",
        ".HlH................HlH.",
        "HHlHd...............dHlH",
        "HHlHd...............dHHH",
        ".HHd................dHH.",
        ".Hd..................dH.",
    ], ["H": hair, "d": hairD, "l": hairL])

    if blink {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    } else if black {
        hvBlackEyes(c)
        c.rect(27, 32, 3, 1, C(0x8A3A2A)); c.px(30, 31, C(0x8A3A2A))   // the smirk
    } else {
        hvEyes(c, ink)
        c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    }

    // The knife: drawn and swung, or held point down at her side.
    let grip = C(0x1A1A1E), steel = C(0xBCC0C8), edge = C(0xEEF0F4)
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: grip, steel: steel, edge: edge, length: 6)
    } else {
        hvKnifeAtRest(c, grip: grip, steel: steel, steelD: C(0x7E848E), edge: edge, length: 3)
    }
}

// MARK: - Ruby

/// Ruby: long chestnut hair in loose waves, a dark brown leather biker jacket with silver zips, open on a pale cream
/// top, blue jeans and brown boots. Fights with her demon-killing knife, the one she gave Sam, its blade a little
/// curved and its dark handle carved. Signature: she twirls the knife round her hand, two turns, and catches it.
private func drawRuby(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x40291F), jacketD = C(0x251710), jacketL = C(0x64463A), zip = C(0xC4C8D0)
    let top = C(0xDDD4C4), topD = C(0xB4AA98)
    let hair = C(0x7A4A2C), hairD = C(0x52301A), hairL = C(0xA2683E)
    let grip = C(0x2A1E18), steel = C(0xC8CCD4), edge = C(0xF2F4F8), notch = C(0x6A4A2A)
    let s = p.signature ?? -1
    let twirl = s > 0.06 && s < 0.94 ? (s - 0.06) / 0.88 : -1
    let raise = twirl < 0 ? 0 : Int(min(1, twirl / 0.15, (1 - twirl) / 0.15) * 5)

    // Blue jeans lit down the front, and brown boots.
    drawLegs(c, Look(leg: C(0x34466A)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 2, C(0x4C6088)) } }
    drawBoots(c, C(0x3A2416), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: ink))

    // The biker jacket, cropped at the waist and open on the cream top: wide lapels lit along their edge, a silver
    // zip running down the near side, the far side in shade, a belted hem.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, top); c.rect(26, 33, 4, 1, clawdShade); c.rect(30, 34, 1, 4, topD)
    c.rect(23, 33, 2, 1, jacketL); c.rect(24, 34, 1, 3, jacketL); c.rect(31, 33, 2, 1, jacketD)
    c.rect(31, 34, 1, 3, jacketD)
    c.rect(22, 34, 1, 3, zip); c.px(32, 33, zip)
    c.rect(19, 33, 3, 1, jacketL); c.rect(34, 33, 2, 1, jacketL)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(19, 37, 2, 1, zip)   // the hem's buckle
    c.rect(15, 35, 3, 1, jacketD)
    c.rect(38, 35, 3, 1, jacketD)

    // Long chestnut hair, side-parted, in loose waves past her shoulders: the edge bulging with each wave, strands lit.
    c.pattern(15, 20, [
        ".........HHHHHHHH.........",
        "......HHHHllHHHHHllH......",
        "....HHHllHHHHHHHHHHllH....",
        "...HHlHHHHHHHHHHHHHHHlH...",
        "...HlHHHHHHdHHHHHHHHHHlH..",
        "..HHlHHHHHHHdHHHHHHHHHlH..",
        "..HlHHHHlHHHHdHHHHHHHHlH..",
        "..HlHHHH.........HHHHHlH..",
        "..HHlH............HHHlH...",
        "...HlHd.............dHlH..",
        "..HlHd..............dHlH..",
        "..HlHd..............dHlH..",
        "...HlH...............HlH..",
        "..HlHd..............dHlH..",
        "..HHlH...............HlHH.",
        "...dHd...............dHd..",
        "....d.................d...",
    ], ["H": hair, "d": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if twirl >= 0 {
        // Her arm out in front of her, clear of her hair, the knife spinning round her hand, two whole turns, a
        // faint blur where the blade has just been, then caught point down.
        let f = Double(raise) / 5
        let hand = (x: 39.5 + 3 * f, y: 34.5 - 4 * f)
        huntLine(c, 39, 34.5, hand.x, hand.y, jacket, 1.2)
        let spin = twirl < 0.15 || twirl > 0.85 ? 90 : 90 + (twirl - 0.15) / 0.7 * 720
        if twirl > 0.15 && twirl < 0.85 {
            huntSmear(c, hand, [spin - 25, spin - 50, spin - 75], from: 2, to: 7, C(0xF0F4FF))
        }
        huntBar(c, hand, spin, from: -2.5, to: 0.5, grip, r: 0.9)
        huntBar(c, hand, spin, from: 1.5, to: 7, steel, r: 0.9)
        huntBar(c, hand, spin, from: 1.5, to: 6.5, edge, r: 0.5)
        c.rect(Int(hand.x.rounded()) - 1, Int(hand.y.rounded()) - 1, 3, 3, clawdOrange)
        return
    }
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: grip, steel: steel, edge: edge, length: 8, notches: notch)
        let tip = huntReach(huntHand, a + 8, 8.5)   // the curve near the point
        c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), steel)
    } else {
        // At rest the knife hangs point down a little out from her side, clear of her hair, so it shows against
        // whatever's behind her: the carved grip's pommel above her fist, lit on its near edge, and the long blade
        // below, bright down its edge and curving forward at the point.
        c.rect(38, 34, 2, 2, jacket)                                          // the sleeve, reaching out
        c.rect(42, 31, 2, 3, grip); c.px(42, 31, C(0x5A4636)); c.px(43, 32, notch)
        c.rect(41, 34, 3, 3, clawdOrange); c.px(43, 36, clawdShade)           // her fist round the grip
        c.rect(42, 37, 2, 5, steel); c.rect(43, 37, 1, 5, C(0x8A9098)); c.rect(42, 37, 1, 5, edge)
        c.px(43, 42, steel); c.px(44, 42, edge)
    }
}

// MARK: - Lilith

/// Lilith, the first demon, in the vessel she wore to break the last seal: a pale woman in a long white slip dress
/// on thin straps, bare arms, long sleek platinum hair from a centre parting, and pale slippers. Her power is a
/// jagged white blast. Signature: her eyes go white, growing and glowing in a white haze, then fade back.
private func drawLilith(_ c: PixelCanvas, _ p: Pose) {
    let dress = C(0xF2F0EC), dressD = C(0xC8C6D2), dressL = C(0xFFFFFF), fold = C(0xDCDAE4)
    let hair = C(0xE6DAB4), hairD = C(0xAE9C6E), hairL = C(0xFAF2D8)
    let s = p.signature ?? -1
    let white = s > 0.08 && s < 0.92 ? min(1, (s - 0.08) / 0.18, (0.92 - s) / 0.18) : 0

    // Bare legs below the hem, and pale slippers.
    drawLegs(c, Look(leg: clawdOrange), step: p.step)
    drawBoots(c, C(0xBEB8C4), step: p.step, rows: 1)

    c.oy += p.breathe
    // The dress falls to below the knee: soft folds over each leg, the far side and the hem in shade, so the four
    // legs still show below it.
    if seatedPose {
        c.rect(17, 38, 22, 1, dress)
    } else {
        c.rect(17, 38, 22, 3, dress)
        c.rect(17, 38, 1, 3, dressL); c.rect(38, 38, 1, 3, dressD)
        for x in [22, 26, 30, 34] { c.rect(x, 38, 1, 3, fold) }
        c.rect(36, 38, 1, 3, dressD)
    }
    drawBody(c, Look(arm: clawdOrange, eye: nil), armRight: p.armRaise)

    // The bodice, straight across under bare shoulders on two thin straps, gathered at the waist, lit along the
    // neckline and shaded down the far side.
    c.rect(18, 34, 20, 4, dress)
    c.rect(18, 34, 20, 1, dressL); c.px(22, 33, dress); c.px(33, 33, dress)
    c.rect(37, 34, 1, 4, dressD); c.rect(26, 36, 4, 1, fold); c.rect(27, 36, 2, 1, dressD)
    c.px(21, 35, fold); c.px(31, 35, fold); c.rect(18, 37, 20, 1, dressD)
    c.px(36, 35, dressD)

    // Long sleek platinum hair from a centre parting, straight down past her shoulders: fine strands fanning out from
    // the parting and down each side, a sheen along them, the ends parting into points.
    c.pattern(16, 21, [
        ".......HHlHHHlHHH.......",
        ".....HHlHHHdHHlHHHH.....",
        "...HHlHHHdHdHHHdHlHHH...",
        "..HlHHHdHHHdHHHHdHHlHH..",
        "..HlHHdHHHHdHHHHHdHHlH..",
        ".HHlHdHHHHd..dHHHHdHlHH.",
        ".HlHdHHHd......dHHHdHlH.",
        ".HlHHd............dHHlH.",
        ".HlHd..............dHlH.",
        ".dlHd..............dHld.",
        ".HlHd..............dHlH.",
        ".dlHd..............dHld.",
        ".HlHd..............dHlH.",
        ".dlHd..............dHld.",
        ".HlHd..............dHlH.",
        ".l.d................d.l.",
    ], ["H": hair, "d": hairD, "l": hairL])

    if white > 0.2 {
        hvEyes(c, C(0xFFFFFF), low: C(0xD8DCEC), big: white > 0.5, glow: C(0xF4F4FF), k: white)
    } else {
        hvEyes(c, ink)
        c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    }
}

// MARK: - Alastair

/// Alastair, the demon even demons fear: a mid-grey suit, the jacket buttoned over a pale open-necked shirt, a white
/// pocket square, silver hair combed straight back and long at the collar, black shoes. His telekinesis is white rings.
/// Signature: his eyes close, then slowly open again white, glowing faintly, and close back.
private func drawAlastair(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x7A7C84), suitD = C(0x55575E), suitL = C(0x9C9EA6)
    let shirt = C(0xC4C8D4), shirtL = C(0xEEF0F6)
    let hair = C(0xA8A8B0), hairD = C(0x7C7C86), hairL = C(0xD0D0D6)
    let s = p.signature ?? -1
    // Shut for a moment, then the white opening a row at a time, held, and shut again before they're back to normal.
    let shut = (s > 0.06 && s < 0.16) || (s > 0.86 && s < 0.94)
    let open = s >= 0.16 && s <= 0.86 ? min(1, (s - 0.16) / 0.4, (0.86 - s) / 0.08) : -1

    // Grey trousers with a lit crease, black shoes.
    drawLegs(c, Look(leg: C(0x6A6C74)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 37 : 38
            c.rect(lx, top, 1, 4, C(0x8A8C94))
        }
    }
    drawBoots(c, C(0x111114), step: p.step, rows: 1)

    c.oy += p.breathe
    if !seatedPose { c.rect(18, 38, 20, 1, suitD); c.px(18, 38, suit); c.px(28, 38, C(0x44464C)) }
    drawBody(c, Look(arm: suit, eye: nil), armRight: p.armRaise)

    // The jacket: lapels lit along their edge, the pale shirt between them, no tie, collar points spread, buttoned
    // below; a white pocket square on the breast; the far side and the hem in shade, a fold at the waist.
    c.rect(18, 33, 20, 5, suit)
    c.rect(26, 33, 4, 3, shirt); c.px(26, 33, shirtL); c.px(29, 33, shirtL); c.rect(27, 33, 2, 1, clawdShade)
    c.px(28, 35, C(0x9A9EAA))
    c.rect(25, 33, 1, 3, suitL); c.rect(24, 33, 1, 2, suitL)
    c.rect(30, 33, 1, 3, suitD); c.rect(31, 33, 1, 2, suitD)
    c.rect(28, 36, 1, 2, suitD); c.px(28, 36, C(0x2E2E34))   // the button and the edge below it
    c.rect(33, 34, 2, 1, C(0xF2F2F4)); c.px(34, 34, C(0xC8CAD2))
    c.rect(19, 33, 3, 1, suitL); c.rect(19, 34, 1, 3, suitL); c.rect(34, 33, 2, 1, suitL)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.px(21, 36, suitD); c.px(35, 36, suitD)
    c.rect(15, 35, 3, 1, suitD)
    c.rect(38, 35 - p.armRaise, 3, 1, suitD)

    // Silver hair combed straight back from the brow, the comb's lines lit, long at the back over his collar.
    c.pattern(17, 21, [
        "......HHHHHHHHH.......",
        "...HHHHHHHHHHHHHHH....",
        "..HHlllllHHHHlllllHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHhhhHHHHhhhHHHHHHHH.",
        ".HHHHH..........HHHH..",
        ".HHH...............H..",
        "HHHh..................",
        "HHh...................",
        "Hh....................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if shut {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    } else if open >= 0 {
        // The lids lifting on white: a slit first, growing to the full white eye.
        let h = 1 + Int(open * 3.99)
        let top = [30, 29, 29, 28][h - 1]
        for x in [21, 32] {
            if h == 4 {
                for yy in 26...33 { for xx in (x - 2)...(x + 4) where xx < x || xx > x + 2 || yy < 28 || yy > 31 {
                    c.px(xx, yy, C(0xF0F4FF, 0.18 * open))
                } }
            }
            c.rect(x, top, 3, h, C(0xF6F8FF)); c.rect(x, top + h - 1, 3, 1, C(0xD0D6E4))
            c.rect(x, top - 1, 3, 1, ink)   // the lid above
        }
    } else {
        hvEyes(c, ink)
    }
}

// MARK: - Abaddon

/// Abaddon, the last Knight of Hell: a mane of red hair in big waves swept to one side, a long-sleeved black dress
/// to the knee with a V neck and a thin silver-buckled belt, black stockings and heels, red lips. Her telekinesis is a
/// grip: her arm out, her fist clenched and glowing, she chokes whoever she's fighting from across the room, lifting
/// them off the ground in a crimson coil, her eyes going black while she holds them. Signature: she raises her hand, fingers
/// spread, and slowly closes it into a fist, her eyes black and a slow smile on her red lips.
private func drawAbaddon(_ c: PixelCanvas, _ p: Pose) {
    let dress = C(0x1C1A22), dressD = C(0x0C0B10), dressL = C(0x3E3A48)
    let hair = C(0xB8281E), hairD = C(0x7E160E), hairL = C(0xE44C34), lips = C(0xA8101E)
    let s = p.signature ?? -1
    // The signature: her hand up by a sixth of the way in, spread, closing slowly from a third, a fist by three
    // quarters, held, and lowered at the end.
    let lift = s < 0 ? 0 : min(1, s / 0.16, (1 - s) / 0.12)
    let close = s < 0 ? 0 : min(1, max(0, (s - 0.32) / 0.42))
    let raise = s < 0 ? p.armRaise : Int((lift * 6).rounded())
    let black = s > 0.36 && s < 0.9

    // Black stockings lit down the front, and black heels a shade deeper.
    drawLegs(c, Look(leg: C(0x2E2834)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 1, 2, C(0x463E4E)) } }
    drawBoots(c, C(0x0C0A0E), step: p.step, rows: 1)

    c.oy += p.breathe
    // The skirt to the knee, a sheen down its lit side, a fold over each leg.
    if seatedPose {
        c.rect(17, 38, 22, 1, dress)
    } else {
        c.rect(17, 38, 22, 2, dress); c.rect(17, 39, 22, 1, dressD)
        c.rect(17, 38, 1, 2, dressL); c.rect(18, 38, 1, 1, dressL)
        for x in [22, 26, 33] { c.px(x, 38, dressD) }
        c.rect(38, 38, 1, 2, dressD)
    }
    drawBody(c, Look(arm: dress, eye: nil), armRight: raise)

    // The bodice, a deep V neck, a thin belt with a silver buckle, the far side in shade; a lit seam down the near side.
    c.rect(18, 33, 20, 5, dress)
    c.rect(25, 33, 6, 1, clawdOrange); c.rect(26, 34, 4, 1, clawdOrange); c.rect(27, 35, 2, 1, clawdShade)
    c.rect(24, 33, 1, 2, dressL); c.px(25, 34, dressL); c.px(26, 35, dressL)
    c.rect(19, 33, 3, 1, dressL); c.rect(19, 34, 1, 2, dressL); c.rect(33, 33, 3, 1, dressL)
    c.rect(18, 36, 20, 1, dressD); c.rect(27, 36, 2, 1, C(0xB8BCC6))
    c.rect(37, 33, 1, 5, dressD); c.rect(18, 37, 20, 1, dressD)
    c.rect(15, 35, 3, 1, dressD)
    c.rect(38, 35 - raise, 3, 1, dressD)

    // The red mane: big waves swept over to one side, a lock falling across her brow, curling at the ends.
    c.pattern(14, 19, [
        "..........HHHHHHHH..........",
        ".......HHHHllHHHHHllH.......",
        ".....HHllHHHHHHHHHHHllH.....",
        "....HHlHHHHHHHHHHHHHHHllH...",
        "...HHlHHHHHdHHHHHHHHHHHlHH..",
        "...HlHHHHHHHdHHHHHHHHHHHlH..",
        "..HHlHHHHHHHHdHHHHHHHHHHHlH.",
        "..HlHHHHHHHHHHdHHHHHHHHHHHH.",
        "..HlHHHlHHHH.......HHHHHlHH.",
        "..HHlHHHH..........dHHHHlH..",
        "..HlHHd.............dHHlHH..",
        "...HlHd..............HHlH...",
        "..HHlHd..............dHlHH..",
        "..HlHHd..............dHHlH..",
        "...HlH................HlHH..",
        "...dHd................dHd...",
        "....d..................d....",
    ], ["H": hair, "d": hairD, "l": hairL])

    // Choking someone in a fight: black eyes while the grip holds them up.
    let holding = s < 0 && p.armRaise > 0 && gripHold(p.t) > 0.5
    if black || holding {
        hvBlackEyes(c)
        c.rect(26, 32, 4, 1, lips); c.px(25, 31, lips); c.px(30, 31, lips)
    } else {
        hvEyes(c, ink)
        c.rect(26, 32, 4, 1, lips)
    }

    // Her hand, at the end of her arm reaching out past her hair so it shows against the background: clenched into a
    // fist while she fights; in the signature spread wide, the fingers curling in one by one until it's a fist, a
    // crimson glow gathering round it as it closes.
    let hy = 33 - raise
    if s < 0 && raise > 0 {
        c.rect(38, hy + 1, 4, 2, dress); c.rect(38, hy + 2, 4, 1, dressD)
        c.rect(42, hy, 3, 3, clawdOrange); c.rect(42, hy, 3, 1, clawdShade); c.px(45, hy + 1, clawdOrange)
        c.px(44, hy + 2, clawdShade)
    } else if s >= 0 && lift > 0.5 {
        // The arm reaching out past her hair, so the hand shows against the background.
        c.rect(38, hy + 1, 4, 2, dress); c.rect(38, hy + 2, 4, 1, dressD)
        c.rect(42, hy, 3, 3, clawdOrange); c.px(44, hy + 2, clawdShade)
        let curled = Int((close * 4).rounded())   // fingers folded so far: the little finger first, the thumb last
        let tips: [(Int, Int, Int, Int)] = [(42, hy - 1, 42, hy - 2), (43, hy - 1, 43, hy - 3), (44, hy - 1, 45, hy - 3),
                                            (45, hy, 46, hy - 1)]
        for (i, f) in tips.enumerated() where i >= curled {
            c.px(f.0, f.1, clawdOrange); c.px(f.2, f.3, clawdOrange)
        }
        if curled >= 4 { c.rect(42, hy, 3, 1, clawdShade); c.px(45, hy + 1, clawdOrange) }
        if close > 0.2 {
            let k = close * (0.5 + 0.5 * sin(p.t * 9))
            for a in stride(from: 0.0, to: 2 * .pi, by: .pi / 5) {
                let x = Int((43.5 + cos(a + p.t * 2) * 4).rounded()), y = Int((Double(hy) + 1 + sin(a + p.t * 2) * 3.5).rounded())
                c.px(x, y, (Int(a * 10) % 2 == 0 ? C(0xFFD4E0) : C(0xD0204C)).alpha(0.22 * k))
            }
        }
    }
}

// MARK: - Cain

/// Cain, the Father of Murder, retired to keep bees: a heather-brown knitted cardigan with a ribbed hem and cream
/// buttons, open over a dark henley, brown cords and boots, dark hair going grey, swept back, and a full greying beard.
/// Fights with the First Blade, the jawbone of a beast, its teeth along the edge. Signature: he lifts a hand and his
/// bees pour out of it, swirling round him, then home again.
private func drawCain(_ c: PixelCanvas, _ p: Pose) {
    let knit = C(0x8E7A5E), knitD = C(0x66543E), knitL = C(0xAC967A), button = C(0xE6DCC4)
    let henley = C(0x3E4652), henleyD = C(0x2A303A)
    let hair = C(0x463C36), hairD = C(0x2C2420), grey = C(0x8C8680)
    let beard = C(0x5E5650), beardD = C(0x3E3832), beardL = C(0x9A928A)
    let s = p.signature ?? -1
    let swarm = s > 0.04 && s < 0.96 ? (s - 0.04) / 0.92 : -1
    let raise = swarm < 0 ? 0 : Int(min(1, swarm / 0.12, (1 - swarm) / 0.12) * 3)

    // The bees: out of his raised hand, swirling round him on a wide ring, then back. Each is striped yellow, black
    // and yellow, its wing flicking. The ones behind him are drawn before he is. They're nearly solid, so they hold up
    // on a dark desktop, but not quite: no outline, which would bury three pixels of bee in a white blob.
    let spread = swarm < 0 ? 0 : min(1, swarm / 0.22, (1 - swarm) / 0.22)
    func bees(front: Bool) {
        guard spread > 0.12 else { return }
        let hx = 39.5, hy = 32.0 - Double(raise)
        let cx = hx + (28 - hx) * spread, cy = hy + (28 - hy) * spread
        for i in 0..<9 {
            let th = p.t * 3.2 + Double(i) * 2 * .pi / 9 + sin(p.t * 5 + Double(i)) * 0.25
            guard (sin(th) > 0) == front else { continue }
            let rx = 20 * spread * (0.88 + 0.12 * noise(i)), ry = 12 * spread * (0.85 + 0.15 * noise(i + 9))
            let x = Int((cx + cos(th) * rx).rounded()), y = Int((cy + sin(th) * ry).rounded())
            c.px(x, y, C(0xFFD02A, 0.92)); c.px(x + 1, y, C(0x4A3412, 0.92)); c.px(x + 2, y, C(0xF2B81C, 0.92))
            c.px(x + 1, y - 1, Int(p.t * 14 + Double(i)) % 2 == 0 ? C(0xE4ECF4, 0.85) : C(0xB4C0CC, 0.6))
        }
    }
    bees(front: false)

    // Brown cords, a lit stripe down each, and boots.
    drawLegs(c, Look(leg: C(0x54483A)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 38, 1, 3, C(0x6A5C4A)) } }
    drawBoots(c, C(0x2C2016), step: p.step, rows: 2)

    c.oy += p.breathe
    // The cardigan's hem, a ribbed band hanging over his hips.
    if !seatedPose {
        for x in 18...37 { c.px(x, 38, x % 2 == 0 ? knitD : knit) }
        c.rect(25, 38, 1, 1, henleyD); c.rect(30, 38, 1, 1, henleyD)
    }
    drawBody(c, Look(arm: knit, eye: ink), armRight: raise)

    // The cardigan open on the henley: a button band down each side with cream buttons, a pocket on the near side, the
    // far side in shade, the knit's ribs at the cuff.
    c.rect(18, 33, 20, 5, knit)
    c.rect(26, 33, 4, 5, henley); c.rect(29, 34, 1, 4, henleyD); c.px(27, 35, button)
    c.rect(25, 33, 1, 5, knitL); c.rect(30, 33, 1, 5, knitD)
    c.px(25, 35, button); c.px(25, 37, button); c.px(30, 35, button)
    c.rect(19, 33, 3, 1, knitL); c.rect(19, 34, 1, 3, knitL)
    c.rect(20, 36, 3, 1, knitD); c.px(20, 37, knitD); c.px(22, 37, knitD)
    for x in [33, 35] { c.rect(x, 34, 1, 3, knitD) }
    c.rect(37, 33, 1, 5, knitD); c.rect(18, 37, 20, 1, knitD)
    c.rect(15, 35, 3, 1, knitD)
    c.rect(38, 35 - raise, 3, 1, knitD)

    // Dark hair going grey, swept back: the grey in long streaks combed back from the brow, and grey at the temples.
    c.pattern(17, 21, [
        ".....HHHHHHHHHH.......",
        "...HHggggHHHHgggHH....",
        "..HHHHHHHHgggggHHHH...",
        ".HHggggHHHHHHHHHgggH..",
        ".HHhhHHHHHHHhhHHHHHHH.",
        ".HgHHH.........HHHgH..",
        ".Hgg.............ggH..",
        ".Hgg.............ggH..",
        ".gG...............Gg..",
    ], ["H": hair, "h": hairD, "g": grey, "G": C(0x6A645E)])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    // The beard: full and close-cut, from the sideburns round his mouth and down over his chest, grey at the
    // sideburns and in two long streaks from the corners of his mouth, the rest still dark.
    c.pattern(19, 30, [
        "lB..............Bl",
        "lBB...MMMMMM...BBl",
        "BBlllBBBBBBBBlllBB",
        ".BBBBlllBBlllBBBB.",
        "..BBBBBBBBBBBBBB..",
        "....dBBBBBBBBd....",
    ], ["B": beard, "M": beardD, "l": beardL, "d": beardD])

    if raise > 0 {
        c.rect(38, 33 - raise, 3, 2, clawdOrange); c.px(40, 33 - raise, clawdShade)   // his palm, open
    }
    bees(front: true)

    // The First Blade, only when he fights: a long curved jawbone, pale, its teeth standing out along one side.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x6A5640), steel: C(0xD6C8A6), edge: C(0xF2EAD6), length: 8,
                  notches: C(0x3E3022))
        for d in [3.5, 5.5, 7.5] {
            let q = huntReach(huntReach(huntHand, a, d), a + 90, 1.4)
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), C(0xB4A27E))
        }
    }
}

// MARK: - Asmodeus

/// Asmodeus, Prince of Hell, the Southern gentleman: a white three-piece suit, a pale blue shirt with a black bolo
/// tie on a gold slide, a gold pocket square, dark hair slicked back to the collar, a thin moustache, yellow
/// eyes, and a black cane topped in gold. His power is jagged yellow lightning. Signature: he twirls his cane, two
/// turns, and plants it again.
private func drawAsmodeus(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xECE8DC), suitD = C(0xC2BCAC), suitL = C(0xFFFFF8)
    let shirt = C(0xA8BCD2), tie = C(0x16141A), gold = C(0xDCB440), goldD = C(0x9A7A22)
    let hair = C(0x2E221C), hairD = C(0x1A120E), hairL = C(0x4E3C30)
    let cane = C(0x1A1418), caneL = C(0x3E3440)
    let s = p.signature ?? -1
    let twirl = s > 0.06 && s < 0.94 ? (s - 0.06) / 0.88 : -1
    let raise = twirl < 0 ? p.armRaise : Int(min(1, twirl / 0.15, (1 - twirl) / 0.15) * 4)

    // White trousers, shaded down the far edge of each leg, and brown shoes.
    drawLegs(c, Look(leg: C(0xE0DCD0)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 37 : 38
            c.rect(lx + 1, top, 1, 5, C(0xBCB6A8))
        }
    }
    drawBoots(c, C(0x5A3A22), step: p.step, rows: 1)

    c.oy += p.breathe
    if !seatedPose { c.rect(18, 38, 20, 1, suitD); c.px(18, 38, suit); c.px(28, 38, C(0xA49E90)) }
    drawBody(c, Look(arm: suit, eye: nil), armRight: raise)

    // The jacket open on a waistcoat: lapels lit, the pale blue shirt and the bolo tie in the V, the waistcoat's
    // buttons, a gold pocket square, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 2, shirt); c.rect(26, 35, 4, 1, shirt)
    c.rect(27, 33, 2, 1, gold); c.px(28, 33, goldD)
    c.rect(27, 34, 1, 2, tie); c.rect(28, 34, 1, 1, tie); c.px(29, 35, tie)
    c.rect(26, 36, 4, 2, suitD); c.px(27, 36, goldD); c.px(28, 37, goldD)   // the waistcoat
    c.rect(24, 33, 1, 4, suitL); c.rect(31, 33, 1, 4, suitD); c.rect(25, 35, 1, 2, suitD)
    c.rect(33, 34, 2, 1, gold); c.px(34, 34, goldD)
    c.rect(19, 33, 3, 1, suitL); c.rect(19, 34, 1, 3, suitL)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.px(21, 36, suitD); c.px(35, 36, suitD)
    c.rect(15, 35, 3, 1, suitD)

    // Dark hair slicked back with a gleam, curling over his collar at the back; a thin, neat moustache.
    c.pattern(17, 21, [
        ".....HHHHHHHHHHH......",
        "...HHHlllHHHHlllHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHhHHHHHhHHHHHHhHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHH.............HHH..",
        ".HH...............H...",
        "HHh...................",
        "Hh....................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    c.rect(26, 32, 4, 1, hair); c.px(25, 32, hairL); c.px(30, 32, hairL)
    // Yellow eyes, paler and brassier than Azazel's, with a gleam.
    hvEyes(c, C(0xFFE45C), low: C(0xD09A12), glint: C(0xFFFCE8))

    // The cane: planted out front with his hand on its gold top; twirled two turns round his raised hand, held by the
    // middle, then planted again.
    let hand = (x: 41.0, y: 34.0 - Double(raise))
    if twirl >= 0 {
        let grab = min(1, twirl / 0.15, (1 - twirl) / 0.15)   // sliding his grip to the middle and back
        let spin = 90 + max(0, min(1, (twirl - 0.15) / 0.7)) * 720
        let near = 1.5 + grab * 3.5, far = 9 - grab * 3.5
        let k = huntReach(hand, spin, -near), t = huntReach(hand, spin, far)
        huntLine(c, k.x, k.y, t.x, t.y, cane, 0.6)
        c.rect(Int(k.x.rounded()) - 1, Int(k.y.rounded()) - 1, 2, 2, gold)
        c.px(Int(k.x.rounded()) - 1, Int(k.y.rounded()) - 1, C(0xF6DE84))
        c.px(Int(t.x.rounded()), Int(t.y.rounded()), C(0xB4B8C0))
    } else {
        let len = seatedPose ? 4 : 8   // sitting, the cane rests on the ground beside him
        c.rect(41, 35 - raise, 1, len, cane); c.rect(41, 36 - raise, 1, 3, caneL)
        c.px(41, 35 + len - raise, C(0xB4B8C0))
        c.rect(40, 31 - raise, 3, 2, gold); c.px(40, 31 - raise, C(0xF6DE84)); c.px(42, 32 - raise, goldD)
    }
    c.rect(39, 33 - raise, 3, 2, clawdOrange); c.px(41, 34 - raise, clawdShade)
}
