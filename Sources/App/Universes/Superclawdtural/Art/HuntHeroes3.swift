import Foundation

// Heroes: the Roadhouse regulars and the friends who stuck. Clawd in costume like every other cast, with Clawd's own
// orange face showing. Jo in her denim jacket with a knife ready; Charlie in a geeky tee with her LARP sword; Ash with
// his mullet and his laptop; Kevin in a hoodie with the angel tablet; Gabriel in his brown jacket, a lollipop in his
// mouth on its long stick; and Rowena in green velvet under a cloud of red curls. The two redheads are told apart by everything below
// the hair: Charlie's teal tee and jeans, Rowena's long gown.

let huntHeroes3: [HuntHero: Persona] = [
    .joHarvell: Persona(name: "Jo Harvell", weapon: .blaster, shot: .thrown(C(0xD0D4DC)), muzzle: (43, 28),
                        headTop: 20, signature: 3.2, draw: drawJoHarvell),
    .charlieClawdbury: Persona(name: "Charlie Clawdbury", weapon: .saber, headTop: 21, signature: 3.4,
                               callout: "Queen of Moondoor!", draw: drawCharlieClawdbury),
    .ash: Persona(name: "Ash", headTop: 21, signature: 3.2, callout: "Dr. Badass.", draw: drawAsh),
    .kevinTran: Persona(name: "Kevin Tran", headTop: 21, signature: 3.4, draw: drawKevinTran),
    .gabriel: Persona(name: "Gabriel", weapon: .lightning,
                      magic: Magic(core: C(0xFFE6F4), glow: C(0xFF4FA8), jagged: false, spell: true),
                      headTop: 21, signature: 3.2, callout: "Heya, Sammy!", draw: drawGabriel),
    .rowenaMacClawd: Persona(name: "Rowena MacClawd", weapon: .lightning,
                             magic: Magic(core: C(0xFFE2D6), glow: C(0xE0242C), jagged: false, spell: true),
                             headTop: 18, signature: 3.4, callout: "Boys.", draw: drawRowenaMacClawd),
]

// MARK: - Shared bits

/// How far through the part of the signature between `from` and `to` (0…1), or -1 outside it.
private func h3Span(_ p: Pose, _ from: Double, _ to: Double) -> Double {
    guard let s = p.signature, s > from, s < to else { return -1 }
    return (s - from) / (to - from)
}

/// Smoothstep: 0→1 eased at both ends.
private func h3Smooth(_ x: Double) -> Double {
    let u = min(1, max(0, x))
    return u * u * (3 - 2 * u)
}

/// Up over the first `edge` of `k`, held, and down again over the last `edge`; 0 when `k` is outside 0…1.
private func h3Ease(_ k: Double, edge: Double) -> Double {
    guard k >= 0, k <= 1 else { return 0 }
    return h3Smooth(min(1, k / edge, (1 - k) / edge))
}

// MARK: - Jo Harvell

/// Jo Harvell: Ellen's daughter, young and keen, with straight blonde hair to her shoulders; a light denim jacket with
/// its collar up and two stitched chest pockets, open over a soft grey top; dark jeans and brown boots. She fights with
/// throwing knives, a small all-steel one always ready in her hand. Signature: a dartboard hops out from behind her
/// and rolls to a stop upright ahead of her; she cocks her arm, throws, and the knife spins across and thunks into
/// the bullseye, quivering there; then the board rolls back and hops away behind her, her knife going round with it.
private func drawJoHarvell(_ c: PixelCanvas, _ p: Pose) {
    let denim = C(0x6C8EBA), denimD = C(0x4C6A94), denimL = C(0x94B2D6), thread = C(0xD8AC5C)
    let top = C(0x9A94A2), topL = C(0xB8B2C0), topD = C(0x76707E)
    let jeans = C(0x2E3C5C), jeansL = C(0x46567A)
    let hair = C(0xE4C676), hairL = C(0xF6E4AA), hairD = C(0xBC9A4E)
    let steel = C(0xC4C8D0), steelD = C(0x8A9098), edge = C(0xF2F4F8), wrap = C(0x2A2228)
    // The signature: arm back and up, the throw, the knife in flight, then stuck in the board while the hand is empty
    // until she slips another knife out of her sleeve.
    let k = h3Span(p, 0.04, 0.96)
    let raise: Int
    if k < 0 { raise = 0 }
    else if k < 0.22 { raise = Int((h3Smooth(k / 0.22) * 7).rounded()) }
    else if k < 0.3 { raise = 7 - Int((k - 0.22) / 0.08 * 6) }
    else if k < 0.4 { raise = Int(((0.4 - k) / 0.1 * 1).rounded()) }
    else { raise = 0 }
    let flight = k >= 0.28 && k < 0.42 ? (k - 0.28) / 0.14 : -1
    let stuck = k >= 0.42
    let empty = k >= 0.28 && k < 0.74

    // The dartboard, kept behind her back: she flips it out, and it hops out from behind her, lands on its rim ahead
    // of her, rolls to a stop, rocks and takes the knife; at the end it rolls back and hops up behind her again, the
    // knife going round with it. Drawn before her, so she hides it at both ends, and it never leaves the frame.
    var board: (x: Double, y: Double, spin: Double)? = nil
    if k >= 0 {
        let r = 5.5, rest = 62.5, home = (x: 28.0, y: 31.5), ground = 38.5
        // f: 0 behind her back, 1 at rest on the ground; a little hop on the way.
        func out(_ f: Double) -> (x: Double, y: Double, spin: Double) {
            let x = home.x + (rest - home.x) * f
            let y = home.y + (ground - home.y) * min(1, f * 1.6) - sin(min(1, f * 1.6) * .pi) * 4
            return (x, y, (x - rest) / r)
        }
        if k < 0.16 {
            board = out(h3Smooth(k / 0.16))
        } else if k < 0.86 {
            let rock = k < 0.24 ? sin((k - 0.16) / 0.08 * .pi * 2) * 0.12 * (0.24 - k) / 0.08 : 0
            board = (rest, ground, rock)
        } else {
            board = out(1 - h3Smooth((k - 0.86) / 0.14))
        }
    }
    if let b = board { joDartboard(c, cx: b.x, cy: b.y, spin: b.spin) }
    if stuck, let b = board {
        // Stuck in the bullseye, its point buried and the grip sticking out towards her, quivering for a moment after
        // it hits, then going round with the board as it rolls away. Drawn with the board, so she hides both.
        let wob = k < 0.52 ? (Int(p.t * 24) % 2 == 0 ? -0.2 : 0.2) : 0
        let a = .pi + b.spin + wob, h = (x: b.x, y: b.y)
        let along = { (d: Double) in (Int((h.x + cos(a) * d).rounded(.down)), Int((h.y + sin(a) * d).rounded(.down))) }
        for d in stride(from: 0.5, through: 9.0, by: 0.5) {
            let q = along(d)
            c.px(q.0, q.1, d < 2 ? steelD : d < 5.5 ? (d < 3 ? edge : steel) : wrap)
        }
    }

    // Dark jeans, faded at the knee, and brown boots.
    drawLegs(c, Look(leg: jeans), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 39, jeansL) } }
    drawBoots(c, C(0x5A3A26), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: denim), armRight: raise)

    // The denim jacket, open over the grey top: the collar up and lit, the front edges a shade apart, a stitched
    // pocket each side, the far side and the waistband in shade, a cuff. The top is a mid tone, narrow and straight
    // from collar to hem, so it reads as a strip of top under the jacket and not as a gap under her face.
    c.rect(18, 33, 20, 5, denim)
    c.rect(26, 33, 4, 5, top); c.rect(26, 33, 1, 4, topL); c.rect(29, 33, 1, 5, topD); c.rect(27, 33, 2, 1, topL)
    c.pattern(20, 33, ["LLLLL.....LLLLL", ".LLLL.....LLLL."], ["L": denimL])
    c.rect(25, 34, 1, 4, denimL); c.rect(30, 34, 1, 4, denimD); c.px(24, 36, C(0xC8CCD4))
    c.rect(20, 35, 3, 1, denimD); c.px(21, 36, thread); c.rect(33, 35, 3, 1, denimD); c.px(34, 36, thread)
    c.rect(37, 33, 1, 5, denimD); c.rect(18, 37, 20, 1, denimD); c.px(19, 37, thread); c.px(36, 37, thread)
    c.rect(15, 35, 3, 1, denimD)

    // Straight blonde hair to her shoulders, parted a little off centre: lit in long strokes on the near side, the
    // ends cut blunt, the far side in shade.
    c.pattern(16, 20, [
        ".....HHHHHHHHHHHH.......",
        "...HHHHllHdHHHllHHH.....",
        "..HHHllHHHdHHHHHllHHH...",
        ".HHHlHHHHdHHHHHHHHllHH..",
        ".HHlHHHHdHHHHHHHHHHHHHd.",
        ".HHHHHHdHHHHHHHHHHHHHHd.",
        ".HHHHHHH.......HHHHHHHd.",
        ".HHHH.............HHHHd.",
        ".HlH...............HHd..",
        ".HlH................Hd..",
        ".HlH................Hd..",
        ".HHH................Hd..",
        ".HHH................HH..",
        ".HHd................dd..",
        ".ddd....................",
    ], ["H": hair, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)   // her brows

    if flight >= 0 {
        // The knife in flight, spinning end over end on its way down to the board.
        let x = 43 + flight * 19, y = 26 + flight * 12.5 - sin(flight * .pi) * 4
        let a = flight * 4 * .pi
        for d in -3...3 {
            let col = d < -1 ? wrap : d == 3 ? edge : steel
            c.px(Int((x + cos(a) * Double(d) * 0.6).rounded()), Int((y + sin(a) * Double(d) * 0.6).rounded()), col)
        }
    }
    // The throwing knife in her fist, its point up and forward: lit along the near edge, its wrapped grip in her hand. It rises with the
    // idle gun habits like anyone's weapon.
    c.oy += p.gunY
    let hy = 33 - raise
    if !empty {
        c.pattern(40, hy - 6, ["...E", "..ES", ".ESs", "ESs.", "Ss..", "W..."],
                  ["E": edge, "S": steel, "s": steelD, "W": wrap])
    }
    c.rect(38, hy, 3, 2, clawdOrange); c.px(40, hy + 1, clawdShade)
}

/// A dartboard about 11 pixels across, centred on (cx, cy), its segments turned by `spin` radians as it rolls.
private func joDartboard(_ c: PixelCanvas, cx: Double, cy: Double, spin: Double) {
    let rim = C(0x1C1A1C), cream = C(0xEADCB4), black = C(0x2A2626), red = C(0xC02A2A), green = C(0x2A8A46)
    let x0 = Int(cx.rounded(.down)) - 6, y0 = Int(cy.rounded(.down)) - 6
    for y in y0...(y0 + 13) {
        for x in x0...(x0 + 13) {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy, d = sqrt(dx * dx + dy * dy)
            guard d <= 5.6 else { continue }
            let turn = (atan2(dy, dx) - spin + 4 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
            let seg = Int(turn / (2 * .pi) * 12) % 2
            let col: Px = d < 0.8 ? red : d < 1.7 ? green : d < 3.1 ? (seg == 0 ? cream : black) :
                          d < 4.2 ? (seg == 0 ? red : green) : rim
            c.px(x, y, col)
        }
    }
    // The rim catching the light on its top left.
    let lx = Int(cx.rounded(.down)), ly = Int(cy.rounded(.down))
    c.px(lx - 3, ly - 4, C(0x5A5660)); c.px(lx - 4, ly - 3, C(0x5A5660)); c.px(lx - 2, ly - 5, C(0x46424A))
}

// MARK: - Charlie Clawdbury

/// Charlie Clawdbury: bright copper-red hair to her chin, a side fringe swept across; a teal t-shirt with a gold
/// twenty-sided die printed on the front, jeans and black sneakers with white soles, and her messenger bag on her hip
/// with her laptop's corner showing. She fights with her LARP sword from Moondoor, a plain long blade with a gold
/// guard. Signature: as Queen of Moondoor she raises the sword straight up overhead, a little gold crown appears on
/// her head, and the blade glints.
private func drawCharlieClawdbury(_ c: PixelCanvas, _ p: Pose) {
    let tee = C(0x2E7C80), teeD = C(0x1E5A5E), teeL = C(0x48A0A2), print = C(0xF2C84A), printD = C(0xB89028)
    let jeans = C(0x3C5078), jeansD = C(0x2C3C5E)
    let hair = C(0xD0482A), hairL = C(0xF0763E), hairD = C(0x962E18)
    let bag = C(0x6A4E34), bagD = C(0x4A3622), bagL = C(0x8A6A48)
    let gold = C(0xF0C850), goldD = C(0xB08A2C)
    let k = h3Span(p, 0.06, 0.94)
    let up = h3Ease(k, edge: 0.18)
    let raise = Int((up * 7).rounded())

    drawLegs(c, Look(leg: jeans), step: p.step)
    if !seatedPose { for lx in [20, 24, 32, 36] { c.px(lx, 40, jeansD) } }
    drawBoots(c, C(0x24242A), step: p.step, rows: 2)
    drawBoots(c, C(0xEAE6DE), step: p.step, rows: 1)

    // The messenger bag at her far hip on its strap, her closed laptop sticking up out of the flap at a slant: silver,
    // lit along its top edge, the dark seam between lid and base, a pink sticker on the lid.
    c.pattern(10, 31, [
        "..lS..",
        ".lSSS.",
        "lSSpSs",
        "kkkkks",
    ], ["l": C(0xEEF0F4), "S": C(0xC8CCD4), "s": C(0x9AA0AA), "k": C(0x4A4E58), "p": C(0xE85A9A)])
    c.rect(12, 35, 6, 4, bag); c.rect(12, 35, 6, 1, bagL); c.rect(12, 38, 6, 1, bagD); c.rect(17, 36, 1, 3, bagD)
    c.px(15, 36, gold)

    c.oy += p.breathe
    drawBody(c, Look(arm: tee), armRight: raise)

    // The tee: a round neck, light along the shoulders, the strap across the near shoulder, the die printed on the
    // front, and the far side and the hem in shade.
    c.rect(18, 33, 20, 5, tee)
    c.rect(25, 33, 6, 1, teeD); c.rect(20, 33, 4, 1, teeL); c.rect(32, 33, 3, 1, teeL)
    c.rect(37, 33, 1, 5, teeD); c.rect(18, 37, 20, 1, teeD); c.rect(15, 35, 3, 1, teeD)
    c.px(19, 33, bag); c.px(18, 34, bag)
    c.pattern(26, 34, [".PPP.", "PpPpP", ".PpP."], ["P": print, "p": printD])
    c.px(22, 36, teeD); c.px(34, 35, teeD)

    // Chin-length copper hair, the fringe swept across from the left and lit in strokes, the ends flicking out.
    c.pattern(17, 21, [
        "......HHHHHHHHH.......",
        "...HHHHlllHHHHHHH.....",
        "..HHHllHHHHHHHHHHHH...",
        ".HHHlHHHHHHHlllHHHHH..",
        ".HHHHHHHHHHHHHHHHHHdH.",
        ".HHHHHHHHHHHHH..HHHdH.",
        ".HHHH...........HHHdH.",
        ".HHH.............HHd..",
        ".HlH.............HdH..",
        ".HlH.............dHH..",
        ".HHd..............Hd..",
        "HHd...............dHH.",
        "dd.................dd.",
    ], ["H": hair, "l": hairL, "d": hairD])

    if up > 0 {
        // The crown of Moondoor, popping on once the sword is up: three gold points and a red stone.
        if up > 0.6 {
            c.pattern(24, 18, ["Y..Y..Y", "YY.YY.Y", "YYYrYYY"], ["Y": gold, "r": C(0xC8203A)])
            c.rect(24, 20, 7, 1, goldD); c.px(27, 20, C(0xC8203A))
        }
        // The sword held straight up, its glint running up the blade.
        let hand = (x: 41.5, y: 34.5 - Double(raise))
        charlieSword(c, hand: hand, angle: -90, trail: [], smear: false)
        if up > 0.9 {
            let g = Int(p.t * 10) % 8
            if g < 6 { c.px(41, Int(hand.y) - 3 - g, white) }
        }
        return
    }
    if let a = p.melee {
        charlieSword(c, hand: huntHand, angle: a, trail: p.trail, smear: true)
    } else {
        // At rest: held upright by her side, the blade leaning back a little.
        charlieSword(c, hand: huntHand, angle: seatedPose ? -80 : -100, trail: [], smear: false)
    }
}

/// The LARP sword from `hand` along `angle`: the leather grip, a gold cross-guard and pommel, the long blade with its
/// lit edge, and her fist round the grip.
private func charlieSword(_ c: PixelCanvas, hand h: (x: Double, y: Double), angle a: Double, trail: [Double],
                          smear: Bool) {
    let gold = C(0xE0B848)
    if smear { huntSmear(c, h, trail, from: 3, to: 12, C(0xF0F4FF)) }
    huntBar(c, h, a, from: -2.5, to: 1.5, C(0x5A3A24), r: 1)
    let pommel = huntReach(h, a, -3)
    c.px(Int(pommel.x.rounded()), Int(pommel.y.rounded()), gold)
    huntBar(c, h, a, from: 2.5, to: 11.5, C(0xA8ACB6), r: 0.9)
    huntBar(c, h, a, from: 2.5, to: 11, C(0xE6EAF0), r: 0.5)
    let g = huntReach(h, a, 2)
    huntBar(c, g, a + 90, from: -2, to: 2, gold, r: 0.6)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
}

// MARK: - Ash

/// Ash: the Roadhouse's genius, with a sandy mullet, short and spiky on top and long down the back of his neck; a
/// faded black tee with the sleeves cut off, frayed at the armholes, and a red lightning bolt printed on it; ripped
/// jeans and scuffed black boots. He doesn't fight. Signature: out comes his laptop, stickers on its bezel; he flips it
/// open, and its screen of lights blinks and chases while he taps away.
private func drawAsh(_ c: PixelCanvas, _ p: Pose) {
    let tee = C(0x36343C), teeD = C(0x1E1D22), teeL = C(0x58555F), fray = C(0xA29EA8)
    let wash = C(0x403E47), rib = C(0x4E4B56)
    let bolt = C(0xC8402E), boltL = C(0xF0884A)
    let jeans = C(0x5E769A), jeansD = C(0x44587C), rip = C(0xD2DAE6)
    let hair = C(0xA27E48), hairL = C(0xC8A464), hairD = C(0x6E5230)
    let shell = C(0x2E3036), shellL = C(0x4A4C54), shellD = C(0x1C1D22)
    let k = h3Span(p, 0.05, 0.95)
    let open = h3Ease(k, edge: 0.14)

    // Jeans ripped across the near knees, and black boots.
    drawLegs(c, Look(leg: jeans), step: p.step)
    if !seatedPose {
        for lx in [23, 35] { c.rect(lx, 39, 2, 1, rip) }
        for lx in [19, 31] { c.px(lx + 1, 40, jeansD) }
    }
    drawBoots(c, C(0x222024), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(), armRight: k >= 0 ? 1 : 0)   // his arms bare, the sleeves long gone

    // The sleeveless tee, washed to a faded charcoal: a stretched crew neck scooping under his chin with its rib lit,
    // pale frayed threads down both armholes where the sleeves were torn off, the near shoulder lit, a faded patch and a
    // fold across the front, the big red bolt, the far side and the hem in shade.
    c.pattern(18, 33, [
        "FLLLLTnoooooonLTTTDF",
        "FFLTWWTnnnnnnTTTTTDF",
        "FLTWWTTTTTTTTTTTTWDF",
        "LTTWTTTTTTTTTTTWWTDD",
        "DDDDDDDDDDDDDDDDDDDD",
    ], ["T": tee, "D": teeD, "L": teeL, "W": wash, "n": rib, "o": clawdOrange, "F": fray])
    c.pattern(26, 34, ["...bB", "..bB.", ".bBBb", "bB..."], ["b": bolt, "B": boltL])

    // The mullet: short and spiky on top, combed up in strokes, cut close over the ears, and long down the back of his
    // neck to his shoulders.
    c.pattern(15, 20, [
        ".......H..H.H..H.H......",
        "......HlHHlHHlHHlHH.....",
        ".....HHlHHlHHlHHlHHHH...",
        "....HHHHHHHHHHHHHHHHHH..",
        "...HHHhhHHHHhhHHHHhhHHH.",
        "...HHHHHHHHHHHHHHHHHHHH.",
        "..HHHHh............hH...",
        ".HHHHH..................",
        "HHlHHh..................",
        "HHlHH...................",
        "HHHHh...................",
        ".HHHh...................",
        ".HHh....................",
        "..dh....................",
    ], ["H": hair, "l": hairL, "h": hairD, "d": hairD])
    c.rect(21, 27, 1, 2, hairD)                                   // a sideburn
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    guard open > 0 else { return }
    // Open in front of him: the black deck and the lid up, its screen a grid of lights chasing in red, green and
    // amber; his fingers tapping on the keys.
    c.rect(37, 36, 13, 2, shell); c.rect(37, 36, 13, 1, shellL)
    for x in stride(from: 38, to: 49, by: 2) { c.px(x, 36, shellD) }
    let lid = Int((open * 8).rounded())
    if lid > 0 {
        c.rect(41, 36 - lid, 9, lid, shellD)
        c.px(48, 36 - lid, C(0xE85A9A)); c.px(42, 36 - lid, C(0xF0C838))   // stickers on the bezel
        if lid > 3 {
            let lights = [C(0xFF4A3A), C(0x4AE05A), C(0xFFC23A), C(0x3A3A44)]
            c.rect(42, 37 - lid, 7, lid - 2, C(0x101014))
            for row in 0..<(lid - 3) where row % 2 == 0 {
                for col in 0..<4 {
                    let i = (Int(p.t * 9) + col + row / 2 * 2) % 4
                    c.px(42 + col * 2, 38 - lid + row, lights[i])
                }
            }
        }
    }
    let tap = Int(p.t * 8) % 2
    c.rect(38 + tap * 2, 33 + tap, 3, 2, clawdOrange)
}

// MARK: - Kevin Tran

/// Kevin Tran: the prophet, a straight-A student pulled into it all, with neat short black hair parted to the side; a
/// navy hoodie with its hood bunched at the back of his neck, white drawstrings and a pouch pocket; khaki trousers and
/// grey sneakers. In his hand, the Word of God: a chipped stone tablet whose carved angel writing glows pale blue. He
/// doesn't fight. Signature: he lifts the tablet, it blazes with light, and its writing scrolls up line by line as he
/// reads.
private func drawKevinTran(_ c: PixelCanvas, _ p: Pose) {
    let hoodie = C(0x34406A), hoodieD = C(0x222A4A), hoodieL = C(0x4E5C90), string = C(0xE4E2DA)
    let khaki = C(0x8E8466), khakiD = C(0x6E6650)
    let hair = C(0x1C1A20), hairL = C(0x3C3844)
    let stone = C(0x8A8274), stoneD = C(0x5E584C), stoneL = C(0xB2AA94)
    let glyph = C(0x9ED4F4), glyphHot = C(0xF2FAFF), glowC = C(0x7FC8FF)
    let k = h3Span(p, 0.05, 0.95)
    let shine = h3Ease(k, edge: 0.2)
    let lift = Int((shine * 3).rounded())
    let ty = 25 - lift

    // The tablet's light, soft and see-through, behind him while it blazes.
    if shine > 0 {
        let pulse = 0.85 + 0.15 * sin(p.t * 6)
        c.glowLine(42, Double(ty + 4), 42, Double(ty + 4), core: glowC.alpha(0.2 * shine * pulse),
                   glow: glowC.alpha(0.2 * shine * pulse), coreR: 6, glowR: 11)
    }

    // Khakis with a crease, grey sneakers on white soles.
    drawLegs(c, Look(leg: khaki), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx + 1, 39, khakiD) } }
    drawBoots(c, C(0x7A7E88), step: p.step, rows: 2)
    drawBoots(c, C(0xE6E6E2), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: hoodie), armRight: 1 + lift)

    // The hoodie: its hood down and bunched round his neck in a thick roll, lit along the top, rising a little behind
    // his head on the far side; the drawstrings hanging, a pouch pocket across the front, ribbed cuff and hem.
    c.rect(18, 33, 20, 5, hoodie)
    c.pattern(18, 30, [
        "D...................",
        "HL..................",
        "HHLLLL........LLLLHD",
        "DHHHHHd......dHHHHDD",
    ], ["H": hoodie, "L": hoodieL, "D": hoodieD, "d": C(0x182038)])
    c.rect(24, 33, 8, 1, hoodieD)
    c.rect(26, 34, 1, 2, string); c.rect(29, 34, 1, 2, string)
    c.rect(20, 33, 3, 1, hoodieL); c.rect(19, 34, 1, 2, hoodieL)
    c.rect(23, 36, 10, 1, hoodieD); c.px(23, 35, hoodieD); c.px(32, 35, hoodieD)
    c.rect(37, 33, 1, 5, hoodieD); c.rect(18, 37, 20, 1, hoodieD); c.rect(15, 35, 3, 1, hoodieD)

    // Neat short black hair, parted on the left and combed across, lit in two strokes.
    c.pattern(17, 21, [
        "....HHHHHHHHHHHH......",
        "..HHHlllHhHHlllHHH....",
        ".HHHHHHHHhHHHHHHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HhHHHHHHHHHHHHHHHHhH.",
        ".HH.HHHhH..........H..",
        ".Hh................h..",
    ], ["H": hair, "l": hairL, "h": C(0x0E0C10)])
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)

    // The tablet: a slab of stone chipped along the top, a crack running down it, lit on the left; rows of carved angel
    // writing glowing in it, scrolling up while it blazes.
    c.pattern(38, ty, [
        ".SSS..SS",
        "LSSSSSSSS",
        "LSSSSSSSD",
        "LSSSSSSD.",
        "LSSSSSSSD",
        "LSSSSSSSD",
        "LSSSSSSSD",
        "LSSSSSSD.",
        "LSSSSSSSD",
        "DDDDDDDD.",
    ], ["S": stone, "L": stoneL, "D": stoneD])
    c.px(43, ty + 1, stoneD); c.px(44, ty + 2, stoneD); c.px(44, ty + 3, stoneD)   // the crack
    // Lines of writing on every other row, so they read as text; while it blazes they scroll up, a line at a time,
    // and odd marks flare white.
    let scroll = shine > 0.5 ? Int(p.t * 3) : 0
    for row in 0..<4 {
        let line = row + scroll
        for col in 0..<6 where noise(line * 11 + col * 3) > 0.3 {
            let hot = shine > 0.5 && noise(line * 5 + col + Int(p.t * 6)) > 0.75
            c.px(39 + col, ty + 2 + row * 2, hot ? glyphHot : shine > 0 ? glyph : C(0x8CB4CC))
        }
    }
    c.rect(38, ty + 8, 2, 2, clawdOrange)   // his thumb over the bottom corner
}

// MARK: - Gabriel

/// Gabriel, the Trickster: an archangel hiding as a joker, with honey-brown hair slicked back to his collar; a tan
/// suede jacket open over a dark olive henley, its buttons undone at the neck; dark jeans and brown shoes; a swirled
/// pink lollipop always in his mouth. His magic is a twinkling ribbon of candy pink. Signature: he raises his hand and
/// snaps his fingers, a pink sparkle pops, and there's a candy bar in his hand; he takes a bite, and it's gone.
private func drawGabriel(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x9A6E42), jacketD = C(0x6C4A2A), jacketL = C(0xBC905E)
    let shirt = C(0x3E4A36), shirtD = C(0x2A3424), button = C(0xA8A48C)
    let hair = C(0x8A5E32), hairL = C(0xB07E46), hairD = C(0x5A3C1C)
    let pink = C(0xF0589C), pinkL = C(0xFFD0E6)
    let k = h3Span(p, 0.05, 0.95)
    // Up to snap, held a moment, then down to show off the bar, and down to rest.
    let raise: Int
    if k < 0 { raise = 0 }
    else if k < 0.2 { raise = Int((h3Smooth(k / 0.2) * 7).rounded()) }
    else if k < 0.38 { raise = 7 }
    else if k < 0.48 { raise = 7 - Int((h3Smooth((k - 0.38) / 0.1) * 4).rounded()) }
    else if k < 0.84 { raise = 3 }
    else { raise = Int(((1 - h3Smooth((k - 0.84) / 0.16)) * 3).rounded()) }
    let snap = k >= 0.28 && k < 0.42 ? (k - 0.28) / 0.14 : -1
    let barOn = k >= 0.34 && k < 0.86

    drawLegs(c, Look(leg: C(0x343C52)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 39, C(0x48526A)) } }
    drawBoots(c, C(0x5A3E26), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: raise > 0 ? raise : p.armRaise)

    // The suede jacket, open over the henley: wide lapels folded back either side, lit on the near one and edged in
    // shade, the button placket undone at the neck, a flapped pocket each side with a stitched line, soft folds in the
    // suede, the far side in shade and a waistband at the hem, a cuff.
    c.pattern(18, 33, [
        "JLLLLAAsoooosaaJJJJD",
        "JLJJJeAsSbSsaeJJJJJD",
        "JJPPPJeAsSSsaeJPPPJD",
        "JJJfJJJeASbsaJJfJJJD",
        "WWWWWWWWWsssWWWWWWWD",
    ], ["J": jacket, "L": jacketL, "D": jacketD, "A": C(0xD0A672), "a": C(0x7E5834), "e": C(0x4E3418),
        "S": shirt, "s": shirtD, "b": button, "o": clawdOrange, "P": jacketD, "f": C(0x86603A),
        "W": C(0x7E5A36)])
    c.rect(15, 35, 3, 1, jacketD)

    // Slicked-back hair, combed straight back in long lit strokes, down over his collar at the back.
    c.pattern(15, 21, [
        ".......HHHHHHHHHH......",
        ".....HHlllllllHHHHH....",
        "...HHHHHHHHHHHHHHHHHH..",
        "..HHHlllHHHHHlllHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHH.",
        ".HHHhHHHhHH.........HH.",
        "HHHHH...............h..",
        "HHHh...................",
        ".HHh...................",
        ".Hdd...................",
        "..d....................",
    ], ["H": hair, "l": hairL, "h": hairD, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The lollipop: its long white stick out of the corner of his mouth, tilted up, a grey line under it so it shows
    // against his face, and the pink swirl on the end.
    c.pattern(34, 29, [
        ".....ww",
        "...wwg.",
        ".wwgg..",
        "wgg....",
    ], ["w": C(0xF8F6F0), "g": C(0xA8A49A)])
    c.pattern(40, 26, [".PpP", "PpPp", "pPpd", "Ppd."], ["p": pink, "P": pinkL, "d": C(0xC83C78)])

    let hy = 33 - raise
    if snap >= 0 {
        // The snap: a pink star bursting at his fingertips, its rays shooting out and fading.
        let r = 1 + snap * 4, a = 1 - snap
        c.px(41, hy - 1, white.alpha(a))
        for (dx, dy) in [(1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0), (0.7, 0.7), (-0.7, -0.7), (0.7, -0.7), (-0.7, 0.7)] {
            let x = 41 + Int((dx * r).rounded()), y = hy - 1 + Int((dy * r).rounded())
            c.px(x, y, (abs(dx) == 1 || abs(dy) == 1 ? pink : pinkL).alpha(a))
        }
    }
    if barOn {
        // The candy bar in his fist: a red wrapper with a white band, torn open on the chocolate end, which loses a
        // bite halfway.
        let bite = k > 0.62
        let wrap = C(0xC8283A), wrapD = C(0x921C2A), choc = C(0x6A3A1E), chocL = C(0x8E5430)
        c.rect(39, hy - 6, 3, 7, wrap); c.rect(41, hy - 6, 1, 7, wrapD); c.rect(39, hy - 4, 3, 1, white)
        c.rect(39, hy - 1, 3, 1, wrapD)
        // The chocolate end, out of the torn wrapper; after the bite, its top corner is gone and a crumb falls.
        c.rect(39, hy - 7, 3, 1, choc)
        if bite {
            c.rect(39, hy - 9, 1, 2, chocL); c.px(40, hy - 8, choc)
            c.px(43, hy - 9 + Int(p.t * 8) % 3, chocL)
        } else {
            c.rect(39, hy - 9, 3, 2, choc); c.rect(39, hy - 9, 1, 3, chocL)
        }
        c.rect(38, hy, 3, 2, clawdOrange); c.px(40, hy + 1, clawdShade)
    } else if raise > 0 {
        c.rect(38, hy, 3, 3, clawdOrange)
        c.px(40, hy - 1, clawdOrange)   // finger and thumb pressed together for the snap
    }
}

// MARK: - Rowena MacClawd

/// Rowena MacClawd: the witch, centuries old and very Scottish, with a great cloud of deep red curls; a long gown of
/// emerald velvet to the floor, its sheen catching the light in the folds, a gold-trimmed neckline and a ruby pendant,
/// long sleeves with gold cuffs, her shoes peeping out under the hem, a hex bag tied at her hip. Her spells are a
/// ribbon of red sparks. Signature: she unhooks the hex bag and holds it up, tosses it at the floor ahead of her, and
/// it bursts in a fountain of red sparks before vanishing in a puff.
private func drawRowenaMacClawd(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0x1E6A44), gownD = C(0x0F4229), gownL = C(0x3E9668), gold = C(0xD8AE4A), goldD = C(0x9A7428)
    let ruby = C(0xC8202E)
    let hair = C(0xA8261E), hairL = C(0xD44E34), hairD = C(0x6E1610)
    let burlap = C(0xA88A5A), burlapD = C(0x76603E), string = C(0xC0202A)
    let k = h3Span(p, 0.04, 0.96)
    let raise: Int
    if k < 0 { raise = 0 }
    else if k < 0.16 { raise = Int((h3Smooth(k / 0.16) * 6).rounded()) }
    else if k < 0.26 { raise = 6 }
    else if k < 0.34 { raise = 6 - Int(((k - 0.26) / 0.08 * 6).rounded()) }
    else { raise = 0 }
    let flight = k >= 0.26 && k < 0.42 ? (k - 0.26) / 0.16 : -1
    let landed = k >= 0.42 && k < 0.84 ? (k - 0.42) / 0.42 : -1
    let poof = k >= 0.84 && k < 0.98 ? (k - 0.84) / 0.14 : -1

    // Dark stockings and black shoes under the gown.
    drawLegs(c, Look(leg: C(0x1E1A1E)), step: p.step)
    drawBoots(c, C(0x0E0C0E), step: p.step, rows: 2)

    // The gown's skirt, long to the floor and flaring at the hem, the velvet lit down the near side of each leg and
    // in shadow between them, so the four legs show through the folds and the toes peep out below.
    if seatedPose {
        c.rect(16, 37, 24, 3, gown); c.rect(16, 39, 24, 1, gownD)
        for x in [20, 24, 32, 36] { c.px(x, 38, gownL) }
    } else {
        c.rect(17, 37, 22, 3, gown); c.rect(16, 40, 24, 2, gown); c.rect(16, 41, 24, 1, gownD)
        for x in [19, 31] { c.rect(x, 38, 1, 2, gownL) }
        for x in [22, 34] { c.rect(x, 39, 1, 2, gownD) }
        c.rect(28, 38, 1, 3, gownD); c.px(27, 40, gownD)
        c.rect(38, 37, 1, 4, gownD); c.px(16, 40, gownL); c.px(17, 39, gownL)
    }

    c.oy += p.breathe
    let arm = raise > 0 ? raise : p.armRaise
    drawBody(c, Look(arm: gown), armRight: arm)

    // The bodice: a gold-trimmed neckline on bare shoulders, the ruby on its chain, the velvet's sheen in strokes on
    // the near side, a seam at the waist, gold cuffs on the long sleeves.
    c.rect(18, 33, 20, 5, gown)
    c.rect(24, 33, 8, 1, clawdOrange); c.rect(25, 34, 6, 1, clawdOrange)
    c.pattern(23, 33, ["G........G", ".GG....GG.", "...GGGG..."], ["G": gold])
    c.px(27, 35, goldD); c.px(28, 35, ruby); c.px(28, 36, C(0x8A1420))
    c.rect(19, 34, 1, 2, gownL); c.rect(20, 33, 2, 1, gownL); c.px(33, 34, gownL)
    c.rect(37, 33, 1, 5, gownD); c.rect(18, 37, 20, 1, gownD); c.px(28, 37, gold)
    c.rect(15, 35, 3, 1, gold); c.px(17, 35, goldD)

    // The curls: a great cloud of deep red hair, piled high and tumbling past her shoulders, each curl a lit stroke
    // with a shadow under it.
    c.pattern(15, 18, [
        "........HHHHHHHHH.........",
        ".....HHHlllHHHlllHHH......",
        "...HHlllHddHlllHddHHHH....",
        "..HHHddHHlllHddHHlllHHH...",
        ".HlllHHlllHddHlllHddHHHH..",
        ".HHddHHHddHlllHddHlllHHHH.",
        "HlllHlllHHHHddHHlllHddHHH.",
        "HHddHHddHlllHHlllHddHlllH.",
        "HlllHHddH.......HHddHHddH.",
        "HHddlll...........lllHHH..",
        "HlllHd.............HllHd..",
        ".HHddH.............HddH...",
        "HlllHH.............HllH...",
        "HHddlH.............HHdd...",
        ".HlllH.............Hll....",
        "HHddH..............HdH....",
        ".Hlld..............dHH....",
        ".dHd...............dd.....",
        "..d.......................",
    ], ["H": hair, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // Her near sleeve again, in front of her hair, and her hand out of it when she casts.
    c.rect(38, 33 - arm, 3, 3, gown); c.rect(38, 35 - arm, 3, 1, gold)
    if arm > 0 && raise == 0 { c.rect(41, 33 - arm, 2, 3, clawdOrange); c.px(42, 35 - arm, clawdShade) }

    // The hex bag: a little burlap pouch gathered at the neck and tied with red string.
    func hexBag(_ x: Int, _ y: Int) {
        c.pattern(x, y, [".r.", ".B.", "BBB", "BbB"], ["r": string, "B": burlap, "b": burlapD])
    }
    // She keeps one tied at her near hip, on the gown. For the signature she unhooks it and lifts it up in her hand;
    // once it has gone up in smoke, a new one knots itself on at her hip in a twinkle of red.
    let hip = (x: 34, y: 36)
    if k < 0 || k >= 0.9 {
        hexBag(hip.x, hip.y)
        if k >= 0.9 && k < 0.98 {
            let f = (k - 0.9) / 0.08
            for i in 0..<4 {
                let a = Double(i) * .pi / 2 + f * 3, r = 3 - f * 2
                c.px(hip.x + 1 + Int((cos(a) * r).rounded()), hip.y + 2 + Int((sin(a) * r).rounded()),
                     i % 2 == 0 ? C(0xFF6A4A) : C(0xFFD0A0))
            }
        }
    } else if flight < 0 && k < 0.26 {
        // Unhooked from her hip and carried up into her raised hand.
        let f = h3Smooth(k / 0.12)
        let x = Double(hip.x) + Double(40 - hip.x) * f, y = Double(hip.y) + Double(29 - raise - hip.y) * f
        hexBag(Int(x.rounded()), Int(y.rounded()))
        if raise > 0 { c.rect(41, 33 - raise, 2, 2, clawdOrange) }
    } else if flight >= 0 {
        // Tossed in an arc to the floor ahead of her, tumbling.
        let x = 41 + flight * 18, y = 27 + flight * 13 - sin(flight * .pi) * 6
        hexBag(Int(x.rounded()), Int(y.rounded()))
    } else if landed >= 0 {
        // Down on the floor, jumping as it bursts, red sparks fountaining up out of it.
        let jump = Int(p.t * 14) % 3 == 0 ? 1 : 0
        hexBag(59, 40 - jump)
        for i in 0..<9 {
            let f = (landed * 2.2 + Double(i) / 9).truncatingRemainder(dividingBy: 1)
            let x = 60.5 + sin(Double(i) * 2.3 + f * 3) * (1 + f * 5), y = 40 - f * 16
            let col = (i % 3 == 0 ? C(0xFFD0A0) : i % 3 == 1 ? C(0xFF4A3A) : C(0xD01E2A)).alpha(1 - f)
            c.px(Int(x.rounded()), Int(y.rounded()), col)
        }
    } else if poof >= 0 {
        // Gone in a puff of red smoke.
        let r = 1.5 + poof * 4
        c.glowLine(60.5, 40, 60.5, 40 - poof * 3, core: C(0xC03030).alpha(0.3 * (1 - poof)),
                   glow: C(0x802028).alpha(0.25 * (1 - poof)), coreR: r * 0.6, glowR: r)
    }
}
