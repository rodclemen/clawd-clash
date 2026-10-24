import Foundation

// Villains: Metatron and the Big Bads. Drawn the same way as the heroes (HuntHeroes1.swift); Clawd in costume, and
// every one of them in clothes you'd pass in the street: a scribe's sweater, a CEO's suit, God's bathrobe, and the
// Four Horsemen dressed as a businessman in red, a frail old man, a sick salesman and an undertaker.
//
// The suits are told apart at a glance: Clawdley's is black with an overcoat and a goatee (HuntVillains1.swift),
// Dick Roman's navy with slicked-back salt-and-pepper hair and the grin, War's red, Pestilence's a rumpled olive, and Death's black
// with a white shirt, a high grey hairline, hollow cheeks and a cane.
//
// Magic (`weapon: .lightning`): `magic:` says how the stream looks, and the engine draws it from `pivot` (the casting
// hand, raised `p.armRaise` pixels: draw the arm raised as much). Don't set `magic.variant` yourself: the engine
// numbers every magic user in order through all the universes, so no two anywhere look exactly alike.

let huntVillains4: [HuntVillain: Persona] = [
    .metatron: Persona(name: "Metatron", weapon: .lightning,
                       magic: Magic(core: C(0xFFF8E2), glow: C(0xD8C68C), jagged: false, spell: true),
                       headTop: 23, signature: 3.6, draw: drawMetatron),
    .dickRoman: Persona(name: "Dick Roman", weapon: .saber, headTop: 22, signature: 3.2, draw: drawDickRoman),
    .chuck: Persona(name: "Chuck", weapon: .lightning,
                    magic: Magic(core: C(0xFFFBF0), glow: C(0xFFDDA6), jagged: false, touch: true),
                    headTop: 21, signature: 3.6, draw: drawChuck),
    .war: Persona(name: "War", weapon: .lightning,
                  magic: Magic(core: C(0xFF9A8C), glow: C(0x86101A), jagged: false, rings: true),
                  headTop: 22, signature: 3.2, draw: drawWar),
    .famine: Persona(name: "Famine", headTop: 24, signature: 3.6, draw: drawFamine),
    .pestilence: Persona(name: "Pestilence", weapon: .lightning,
                         magic: Magic(core: C(0xE2FF9E), glow: C(0x76A42A), jagged: false, waves: true),
                         headTop: 22, signature: 3.2, draw: drawPestilence),
    .death: Persona(name: "Death", weapon: .lightning,
                    magic: Magic(core: C(0xC4C4CC), glow: C(0x1C1C24), jagged: false, touch: true),
                    headTop: 19, signature: 4.0, draw: drawDeath),
]

// MARK: - Metatron

/// Metatron, the Scribe of God: a camel-brown cardigan buttoned over a pale shirt, its collar points out at the neck,
/// cable stripes down the front and ribbed cuffs and hem; short greying hair, receding off a high brow; and his thin
/// dark-rimmed glasses. Casts from the angel tablet, a pale gold ribbon of sparkles. Signature: his old typewriter
/// appears in his hands and he types a page: the carriage creeps left, dings, and slams back for the next line.
private func drawMetatron(_ c: PixelCanvas, _ p: Pose) {
    let knit = C(0x8E6C48), knitD = C(0x684C30), knitL = C(0xB08C62), button = C(0x3A2818)
    let shirt = C(0xE2DCCC), shirtD = C(0xB4AC9A)
    let hair = C(0x6E665C), hairD = C(0x4C463E), hairL = C(0x9A9288), frame = C(0x2A2420)
    let s = p.signature ?? -1
    let tw = s > 0.05 && s < 0.95 ? (s - 0.05) / 0.9 : -1.0

    drawLegs(c, Look(leg: C(0x5A5248)), step: p.step)
    drawBoots(c, C(0x2E2219), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: knit), armRight: tw >= 0 ? 1 : p.armRaise)

    // The cardigan: a V down to the second button on the pale shirt, collar points showing, two cable stripes, the
    // ribbed hem and the far side in shade.
    c.rect(18, 33, 20, 5, knit)
    c.pattern(24, 33, ["LsSSSSsL", ".LSSSSL.", "..LSSL..", "...LL..."], ["S": shirt, "s": shirtD, "L": knitL])
    c.px(25, 33, shirt); c.px(30, 33, shirt)
    for y in [35, 37] { c.px(27, y, button) }
    c.rect(28, 35, 1, 3, knitD)
    for y in 34...36 { c.px(21, y, y % 2 == 0 ? knitL : knitD); c.px(34, y, y % 2 == 0 ? knitL : knitD) }
    c.rect(18, 34, 1, 3, knitL)
    c.rect(37, 33, 1, 5, knitD)
    for x in 18...37 { c.px(x, 37, x % 2 == 0 ? knitD : C(0x7A5C3C)) }
    c.rect(15, 35, 3, 1, knitD)

    // Short greying hair, thin on top and receding at the temples, so his brow is high; grey at the sides.
    c.pattern(17, 23, [
        ".....HHhHHHhHHHH......",
        "...HHlHHHlHHHHlHHH....",
        "..HHHHHHHHHHHHHHHHHH..",
        ".lHHH............HHHl.",
        ".HHh..............hHH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The glasses: a thin dark rim round each eye with the lens a pale tint inside it, so his eyes show through; a
    // fine bridge between them, the arms back to his ears, a glint on the near lens.
    let lens = C(0xF2B496)
    for x0 in [20, 30] {
        c.rect(x0 + 1, 28, 4, 1, frame); c.rect(x0 + 1, 32, 4, 1, frame)
        c.rect(x0, 29, 1, 3, frame); c.rect(x0 + 5, 29, 1, 3, frame)
        c.rect(x0 + 1, 29, 4, 3, lens)
        c.rect(x0 + 2, 29, 2, 3, ink)
    }
    c.rect(26, 29, 4, 1, frame)
    c.px(19, 29, frame); c.px(36, 29, frame)
    c.px(34, 29, C(0xFFFFFF)); c.px(31, 31, C(0xFFF4EC))

    guard tw >= 0 else { return }
    // The typewriter, held in front of him: a black-green body lit along its top, three rows of round keys and the
    // space bar, the chrome carriage with its knobs and return lever, and the page curling up out of the roller with
    // its typed lines.
    let open = min(1.0, tw / 0.1, (1 - tw) / 0.08)
    let drop = Int(((1 - open) * 3).rounded())
    let body = C(0x2C3A32), bodyL = C(0x5A6E60), bodyD = C(0x161E1A), key = C(0xE8E4D8), keyD = C(0xA8A49A)
    let chrome = C(0xD0D4DA), chromeD = C(0x8A9098), paper = C(0xF8F6EE), paperD = C(0xD8D4C8), typed = C(0x3A3A44)
    let typing = max(0, min(0.9999, (tw - 0.1) / 0.8)) * 3
    let line = Int(typing), frac = typing - Double(line)
    let k = tw < 0.1 || tw > 0.9 ? 0 : frac > 0.9 ? 0 : Int(frac / 0.9 * 4.99)   // the carriage creeping left
    c.oy += drop
    c.rect(40, 34, 18, 6, body); c.rect(40, 34, 18, 1, bodyL); c.rect(40, 39, 18, 1, bodyD); c.rect(57, 34, 1, 6, bodyD)
    c.px(40, 34, C(0x7A8E80))
    for x in stride(from: 41, through: 55, by: 2) { c.px(x, 35, key) }
    for x in stride(from: 42, through: 56, by: 2) { c.px(x, 36, key) }
    for x in stride(from: 41, through: 55, by: 2) { c.px(x, 37, keyD) }
    c.rect(45, 38, 8, 1, keyD)                                                   // the space bar
    // The page: a row taller for every line typed, each line a run of ink, the current one as far as he's got.
    let top = 29 - line * 2
    c.rect(45 - k, top, 8, 31 - top, paper); c.rect(52 - k, top, 1, 31 - top, paperD)
    for l in 0...line {
        let y = top + 1 + (line - l) * 2
        let len = l < line ? 6 : k + 1
        if len > 0 && y < 31 { c.rect(46 - k, y, len, 1, typed) }
    }
    c.rect(42 - k, 31, 15, 2, chrome); c.rect(42 - k, 33, 15, 1, chromeD); c.rect(43 - k, 31, 13, 1, C(0xF4F6FA))
    c.rect(41 - k, 31, 1, 3, bodyD); c.rect(57 - k, 31, 1, 3, bodyD)            // the knobs
    c.px(41 - k, 30, chrome); c.px(40 - k, 29, chrome); c.px(39 - k, 29, chrome)  // the return lever
    if frac > 0.9 && tw > 0.1 && tw < 0.9 {                                      // ding
        c.px(60, 29, C(0xFFE28A)); c.px(59, 28, C(0xFFE28A, 0.6)); c.px(61, 28, C(0xFFE28A, 0.6)); c.px(60, 27, C(0xFFE28A, 0.6))
    }
    // His hands on the keys, pecking in turn.
    let tap = Int(p.t * 8) % 2
    c.rect(41 + tap * 2, 34 + tap, 3, 2, clawdOrange)
    c.rect(49 + (1 - tap) * 2, 34 + (1 - tap), 3, 2, clawdOrange); c.px(51 + (1 - tap) * 2, 35 + (1 - tap), clawdShade)
}

// MARK: - Dick Roman

/// Dick Roman, the Leviathan in a CEO: a slick navy suit, a pale blue shirt and a silver tie with a white pocket
/// square, salt-and-pepper hair slicked straight back with a gleam on it, and a big, bright, toothy grin. Fights with a
/// Leviathan bite: a black goo tendril lashing out of his sleeve with a little set of jaws on the end. Signature: the
/// grin keeps going, and splits wide into a huge Leviathan mouth full of teeth, then folds back into the smile.
private func drawDickRoman(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x2C3A58), suitD = C(0x1A243A), suitL = C(0x4C5E84)
    let shirt = C(0xD6E4F4), tie = C(0x98A2B2), tieD = C(0x646E7E)
    let hair = C(0x34322F), hairD = C(0x1E1C1A), hairL = C(0xD0CCC4), silver = C(0x8E8A84)
    let s = p.signature ?? -1
    // The maw: opening, held wide, closing.
    var maw = s > 0.1 && s < 0.9 ? min(1.0, (s - 0.1) / 0.18, (0.9 - s) / 0.16) : 0.0
    if p.melee != nil && !p.trail.isEmpty { maw = max(maw, 0.45) }   // it snaps open mid-bite

    drawLegs(c, Look(leg: C(0x24304A)), step: p.step)
    drawBoots(c, C(0x2A1A12), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: suit))

    // The suit: notched lapels lit along their edge, the shirt and silver tie in the V, a white pocket square, a fold
    // on each side and the far side in shade.
    c.rect(18, 33, 20, 5, suit)
    c.pattern(23, 33, ["LLSSTTSSLL", ".LLSTtSLL.", "..LLTtLL..", "...LTtL...", "....TT...."],
              ["S": shirt, "T": tie, "t": tieD, "L": suitL])
    c.rect(33, 34, 2, 1, C(0xF4F6F8)); c.px(33, 33, C(0xF4F6F8))
    c.rect(18, 34, 1, 3, suitL); c.px(21, 35, suitD); c.px(21, 36, suitD); c.px(35, 36, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(15, 34, shirt)

    // Hair slicked straight back off his brow: high at the front and swept down to the back of his head, dark with
    // silver combed through it in long strokes that run back, a gleam along the top, grey at the temple.
    c.pattern(17, 22, [
        "........HHHHHHHHHH....",
        "....HHHHlllllllHHHH...",
        "..HHgggHHHHgggHHHHHH..",
        ".HgggHHHHgggHHHHgggHH.",
        ".HHHHHgggHHHHH....gg..",
        ".HHggHH...........g...",
        ".HHh..................",
    ], ["H": hair, "h": hairD, "l": hairL, "g": silver])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if maw <= 0.02 {
        // The grin: wide and white between his eyes, the corners turned up, the lower lip under it.
        c.pattern(24, 30, ["m......m", ".WWWWWW.", "..mmmm.."], ["m": C(0x5A2418), "W": C(0xFAFAF4)])
    } else {
        // The Leviathan mouth: the smile tears wide from cheek to cheek and gapes down over his chest, black inside,
        // rows of white fangs top and bottom and a second row behind, black goo dripping from the jaw.
        let h = max(1, Int((maw * 5).rounded()))
        let x0 = 23 - Int((maw * 4).rounded()), x1 = 32 + Int((maw * 4).rounded())
        let dark = C(0x120A14), gum = C(0x3A1426), fang = C(0xFAF6EA), fangD = C(0xB8B2A6)
        c.rect(x0, 31, x1 - x0 + 1, h + 2, dark)
        c.rect(x0 + 1, 31, x1 - x0 - 1, 1, gum)
        c.rect(x0 + 1, 32 + h, x1 - x0 - 1, 1, gum)
        for x in x0...x1 {
            let i = x - x0
            if i % 2 == 0 { c.px(x, 31, fang); if h > 2 { c.px(x, 32, fang) } }
            if i % 2 == 1 { c.px(x, 32 + h, fang); if h > 2 { c.px(x, 31 + h, fang) } }
            if h > 3 && i % 3 == 1 { c.px(x, 33, fangD); c.px(x, 30 + h, fangD) }
        }
        c.px(x0 - 1, 31, C(0x5A2418)); c.px(x1 + 1, 31, C(0x5A2418))
        if h > 3 {
            let drip = Int(p.t * 3) % 3
            c.rect(x0 + 2, 33 + h, 1, 1 + drip, dark); c.px(x1 - 3, 33 + h, dark)
        }
    }

    // The bite: a thick black tendril of goo lashing out of his sleeve, lit violet along its top so it shows on the
    // dark, and a pair of jaws snapping at the end of it, white fangs in a red maw.
    if let a = p.melee {
        let h = huntHand
        let goo = C(0x141018), gooL = C(0x6A4E8A)
        huntSmear(c, h, p.trail, from: 3, to: 13, C(0x6A4E8A))
        huntBar(c, h, a, from: 0, to: 11, goo, r: 1.6)
        let side = huntReach((0, 0), a - 90, 1.1)
        huntBar(c, (h.x + side.x, h.y + side.y), a, from: 2, to: 10, gooL, r: 0.45)
        // The jaws: two wedges hinged at the end of it, opening and snapping shut along the line of the lash, the red
        // maw between them and white fangs along their inner edges.
        let hinge = huntReach(h, a, 10)
        let spread = Int(p.t * 10) % 2 == 0 ? 32.0 : 18.0
        let maw = C(0x8A2038), fang = C(0xFAF6EA)
        huntBar(c, hinge, a, from: 0, to: 4.5, maw, r: 1.4)
        for sgn in [-1.0, 1.0] {
            let ang = a + sgn * spread
            huntBar(c, hinge, ang, from: -1, to: 6.5, goo, r: 1.25)
            if sgn < 0 { huntBar(c, huntReach(hinge, ang - 90, 1), ang, from: 0, to: 6, gooL, r: 0.4) }   // lit on top
            for d in [2.5, 4.5, 6.2] {
                let q = huntReach(huntReach(hinge, ang, d), ang - sgn * 90, 1.3)
                c.px(Int(q.x.rounded()), Int(q.y.rounded()), fang)
            }
        }
        c.rect(38, 33, 3, 3, suit); c.px(40, 35, shirt)
    }
}

// MARK: - Chuck

/// Chuck, the writer who turned out to be God: a tatty maroon bathrobe with its shawl collar and a tied sash, over a
/// grey t-shirt, bare legs and old slippers; messy dark hair and a scruffy beard. His acoustic guitar hangs on his back
/// by its strap. Smites with a warm white touch. Signature: he swings the guitar round to the front and strums it,
/// notes drifting up, then slings it back.
private func drawChuck(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x7C3A40), robeD = C(0x52242A), robeL = C(0xA05A5E), tee = C(0x8E949C), teeD = C(0x6E747C)
    let hair = C(0x3E2C1E), hairD = C(0x261A10), hairL = C(0x624632)
    let beard = C(0x7A5436), beardD = C(0x56391F), beardL = C(0x9E7650)
    let wood = C(0xC48A4C), woodD = C(0x8C5C2C), woodL = C(0xE0AE6E), neck = C(0x4A2E1A), strap = C(0x3A2A1E)
    let s = p.signature ?? -1
    let play = s > 0.08 && s < 0.92 ? (s - 0.08) / 0.84 : -1.0
    let front = play >= 0.08 && play <= 0.92

    // The guitar on his back: the body behind his far side, the neck up past his shoulder, the headstock and pegs.
    if !front {
        huntLine(c, 14, 29, 11, 21, neck, 0.7)
        c.rect(10, 18, 2, 3, C(0x2E1C10)); c.px(9, 18, C(0xD8D8D8)); c.px(9, 20, C(0xD8D8D8))
        c.pattern(8, 27, [
            "...WWWW...",
            "..WLLWWW..",
            ".WLWWWWWW.",
            ".WLWkkWWW.",
            "..WWkkWW..",
            "..WWWWWW..",
            ".WLWWWWWW.",
            "WLWWWWWWWW",
            "WWWWWWWWWD",
            "WWWWWWWWWD",
            ".WWWWWWWD.",
            "..DDDDDD..",
        ], ["W": wood, "L": woodL, "D": woodD, "k": C(0x1E140C)])
    }

    drawLegs(c, Look(), step: p.step)
    drawBoots(c, C(0x6E5E4C), step: p.step, rows: 1)

    c.oy += p.breathe
    // The robe's skirt, to his knees: a fold over each leg, the front overlapping, the hem a shade darker.
    if seatedPose {
        c.rect(17, 38, 22, 1, robe)
    } else {
        c.rect(17, 38, 22, 1, robe); c.rect(17, 39, 22, 1, robeD)
        c.px(17, 38, robeL); c.rect(38, 38, 1, 2, robeD)
        for x in [21, 33] { c.px(x, 38, robeD) }
        c.rect(29, 38, 1, 2, robeL); c.rect(30, 38, 1, 2, robeD)
    }
    drawBody(c, Look(arm: robe), armRight: front ? 2 : p.armRaise)

    // The robe: a wide shawl collar, lit, crossing over the grey tee; the sash tied at the waist, its ends hanging.
    c.rect(18, 33, 20, 5, robe)
    c.rect(24, 33, 8, 3, tee); c.rect(25, 35, 6, 1, tee); c.rect(24, 33, 8, 1, teeD)
    c.pattern(21, 33, ["LLL........LLL", ".LLL......LLL.", "..LLL....LLL..", "...LLL..LLL...", "....LLLLLL...."],
              ["L": robeL])
    c.rect(18, 36, 20, 1, robeD); c.rect(26, 36, 3, 1, C(0x3E1A1E)); c.px(27, 37, robeD); c.px(28, 38, robeD)
    c.rect(37, 33, 1, 5, robeD); c.rect(18, 37, 20, 1, robeD); c.px(19, 34, robeD)
    c.rect(15, 35, 3, 1, robeD)
    if !front {   // the guitar strap across his chest, from the far shoulder down to the near hip
        c.px(19, 33, strap); c.px(20, 33, strap); c.px(33, 35, strap); c.px(34, 35, strap); c.px(35, 36, strap); c.px(36, 36, strap)
    }

    // Hair a mess, sticking out every way; the beard a warmer brown, scruffy round his jaw and up his cheeks, a row of
    // bare cheek between it and his hair, his mouth just showing.
    c.pattern(17, 21, [
        "..H....H...H..H...H...",
        "...HH.HHH.HHHHH.HH.H..",
        "..HHHHlHHHHlHHHHlHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        "HHhHHHhHHHHhHHHHHhHHHH",
        ".HHHh.hH......hH..HHH.",
        ".HHh...............Hh.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    c.pattern(18, 30, [
        "bbd..............dbb",
        "blbd.bl.....bl.dbbbb",
        ".bblbbbbmmmbbbblbbb.",
    ], ["b": beard, "d": beardD, "l": beardL, "m": C(0x8A3A2A)])

    guard front else { return }
    // The guitar across his front, played: the body lit on its upper edge, the soundhole, the bridge; the neck up and
    // out to the right, frets along it, his far hand on the chords and the near one strumming.
    let strum = Int((sin(p.t * 22) * 1.5).rounded())
    c.pattern(26, 32, [
        "...WWWW.......",
        "..WLLLWWW.....",
        ".WLLWWWWWW....",
        "WLWWWkkWWWWW..",
        "WWWWkkkkWWWW..",
        "WWWWWkkWWWWW..",
        ".WWWWWWWWWWW..",
        "..WWWWWWWWD...",
        "...DDDDDD.....",
    ], ["W": wood, "L": woodL, "D": woodD, "k": C(0x1E140C), "B": C(0x2E1C10)])
    huntLine(c, 37, 35, 51, 28, neck, 0.8)
    for f in [41.0, 44.0, 47.0] { c.px(Int(f), Int((35 - (f - 37) / 2).rounded()) - 1, C(0xD8D8D0)) }
    c.rect(51, 26, 3, 3, C(0x2E1C10)); c.px(52, 25, C(0xD8D8D8)); c.px(54, 27, C(0xD8D8D8))
    c.rect(46, 29, 2, 3, clawdOrange)                                   // the chord hand
    c.rect(32, 34 + strum, 3, 3, clawdOrange); c.px(34, 35 + strum, clawdShade)   // strumming
    // Notes drifting up from the strings, warm white, fading as they rise.
    for i in 0..<3 {
        let f = (play * 3 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
        let x = 41 + i * 4 + Int(sin(f * 6 + Double(i)) * 1.5), y = 28 - Int(f * 14)
        let col = C(0xFFF2D2, f < 0.6 ? 1 : (1 - f) / 0.4)
        c.px(x, y, col); c.px(x, y - 1, col); c.px(x, y - 2, col); c.px(x + 1, y - 2, col); c.px(x - 1, y, col)
    }
}

// MARK: - War

/// War, the first Horseman: a sharp crimson suit, its lapels lit, a black shirt open at the neck, short dark hair neatly
/// parted, and on his hand the ring that is his power, gold with a blood-red stone. Sows strife with slow, deep red
/// rings. Signature: he brings his hands together and turns the ring on his finger, the stone flaring and red
/// ripples spreading out round it, his eyes catching the red.
private func drawWar(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x8E1C24), suitD = C(0x5C0E16), suitL = C(0xBC3C40), shirt = C(0x1A1418), shirtL = C(0x3A3036)
    let hair = C(0x2A1E1A), hairD = C(0x161010), hairL = C(0x4A3A32), gold = C(0xE6B848), gem = C(0xE0141E)
    let s = p.signature ?? -1
    let turn = s > 0.08 && s < 0.92 ? (s - 0.08) / 0.84 : -1.0
    let hold = turn < 0 ? 0.0 : min(1.0, turn / 0.12, (1 - turn) / 0.12)
    let raise = turn >= 0 ? Int((hold * 3).rounded()) : p.armRaise

    drawLegs(c, Look(leg: C(0x781620)), step: p.step)
    drawBoots(c, C(0x120C0C), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: raise)

    // The red suit: peaked lapels lit along their edges, the black shirt open at the collar, a fold either side, the
    // buttons, and the far side and hem in shade.
    c.rect(18, 33, 20, 5, suit)
    c.pattern(23, 33, ["LLssSSssLL", ".LLsSSsLL.", "..LLSSLL..", "...LLLL..."], ["S": shirt, "s": shirtL, "L": suitL])
    c.px(28, 36, suitD); c.px(28, 37, C(0x2A0A0E))
    c.rect(18, 34, 1, 3, suitL); c.px(21, 35, suitD); c.px(21, 36, suitD); c.px(34, 35, suitD); c.px(35, 35, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD)

    // Short dark hair, parted and combed neat, a gleam on top.
    c.pattern(17, 22, [
        "....HHHHHHHHhHHHH.....",
        "..HHlllHHHHHhHlllHH...",
        ".HHHHHHHHHHHHHHHHHHH..",
        ".HhHHHHHhHHHHHHHhHHHH.",
        ".HH..............HHHH.",
        ".Hh...............hH..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    guard turn >= 0 else {
        // The ring on his hand, the stone catching the light.
        c.px(40, 33 - raise, clawdOrange); c.px(40, 34 - raise, gold); c.px(39, 34 - raise, gem)
        return
    }
    // Both hands up before his chest, the far one turning the ring on the near one's finger.
    let hy = 33 - raise
    c.rect(39, hy, 3, 3, clawdOrange); c.px(41, hy + 2, clawdShade)
    c.rect(42, hy, 3, 3, clawdOrange); c.px(44, hy + 2, clawdShade); c.px(43, hy, C(0xF09070))
    // The ring: a broad gold band round his finger, the blood-red stone coming round over the top, to the front with a
    // glint, underneath, and out of sight behind as it turns.
    let spin = Int(turn * 12) % 4
    c.rect(41, hy, 1, 3, gold); c.px(41, hy + 2, C(0xA88020)); c.px(41, hy, C(0xFFE08A))
    switch spin {
    case 0: c.rect(41, hy - 1, 1, 1, gem); c.px(42, hy - 1, gem)
    case 1: c.rect(40, hy + 1, 2, 1, gem); c.px(40, hy, C(0xFFB0A0))
    case 2: c.px(41, hy + 3, gem); c.px(42, hy + 3, gem)
    default: break
    }
    let flare = 0.5 + 0.5 * sin(turn * 30)
    c.glowLine(41.5, Double(hy) + 1.5, 41.5, Double(hy) + 1.5, core: C(0xFF5048, 0.4), glow: C(0xE0101C),
               coreR: 0.5, glowR: 3.2, strength: (0.3 + 0.3 * flare) * hold)
    // Red rings spreading from the ring, slow and deep, each a bright red edge with a darker band inside it, and his
    // eyes gone red.
    for r in 0..<3 {
        let f = (turn * 2.5 + Double(r) / 3).truncatingRemainder(dividingBy: 1)
        let rad = 4 + f * 13
        let a0 = 0.9 * pow(1 - f, 0.6) * hold
        for k in 0..<96 {
            let a = Double(k) / 96 * 2 * .pi
            for (d, col) in [(0.0, C(0xFF4A44)), (-1.0, C(0x8E0C16))] {
                let x = 42 + Int((cos(a) * (rad + d)).rounded()), y = hy + 1 + Int((sin(a) * (rad + d) * 0.8).rounded())
                guard x > 45 else { continue }   // only out in front, clear of him
                c.px(x, y, col.alpha(a0 * (d == 0 ? 1 : 0.7)))
            }
        }
    }
    for x in [22, 32] {
        c.rect(x, 29, 2, 3, C(0x5A060C, hold)); c.px(x + 1, 29, C(0xFF3A3A, hold)); c.px(x, 30, C(0xD0101C, hold))
    }
}

// MARK: - Famine

/// Famine, the Horseman of hunger: a frail old man in a sagging grey cardigan over a yellowed shirt, baggy grey
/// trousers and slippers, bald on top with white wisps over his ears and bushy white brows, heavy lids over his eyes,
/// leaning on a wooden walking stick. He doesn't fight. Signature: he lifts his head and breathes in, and a green
/// mist curls in from the right and drains into his mouth.
private func drawFamine(_ c: PixelCanvas, _ p: Pose) {
    let card = C(0x8A887C), cardD = C(0x625F56), cardL = C(0xACAA9C), shirt = C(0xE4DCC2), button = C(0x4A463E)
    let wisp = C(0xEEEEE8), wispD = C(0xBCBCB4), cane = C(0x7A5232), caneL = C(0xA27850), caneD = C(0x4E3420)
    let s = p.signature ?? -1
    let inhale = s > 0.06 && s < 0.94 ? (s - 0.06) / 0.88 : -1.0
    let lift = inhale < 0 ? 0.0 : min(1.0, inhale / 0.15, (1 - inhale) / 0.15)

    drawLegs(c, Look(leg: C(0x5E5C56)), step: p.step)
    drawBoots(c, C(0x4A3A2C), step: p.step, rows: 1)

    // The walking stick, leaning out from his hand to a rubber tip on the floor ahead of his front feet: a thin slant,
    // nothing like his legs.
    if !seatedPose {
        huntLine(c, 43.5, 34.5, 47.5, 42.5, cane, 0.55)
        for (x, y) in [(44, 35), (45, 37), (46, 39)] { c.px(x, y, caneL) }
        c.rect(47, 42, 2, 2, C(0x22180E))
    }

    c.oy += p.breathe
    c.oy -= Int((lift * 1).rounded())
    drawBody(c, Look(arm: card))

    // The cardigan, a size too big now: sagging, buttoned low, the shirt collar crooked, a pocket pulled out of shape,
    // and the far side and hem in shade.
    c.rect(18, 33, 20, 5, card)
    c.pattern(24, 33, ["LSSSSSSL", ".LSSSSL.", "..LSSL..", "...LL..."], ["S": shirt, "L": cardL])
    c.px(25, 33, C(0xC8BFA2)); c.px(27, 36, button); c.px(28, 37, button)
    c.rect(32, 35, 3, 2, cardD); c.rect(32, 35, 3, 1, cardL)
    c.rect(18, 34, 1, 3, cardL); c.px(21, 35, cardD); c.px(22, 36, cardD)
    c.rect(37, 33, 1, 5, cardD); c.rect(18, 37, 20, 1, cardD)
    c.rect(15, 35, 3, 1, cardD)
    // The crook of the stick hooked over his hand, curling back, lit along its top.
    if !seatedPose {
        c.px(40, 33, caneD); c.px(40, 32, cane); c.rect(41, 31, 2, 1, caneL); c.px(43, 32, cane); c.px(44, 33, caneD)
        c.rect(41, 33, 3, 2, clawdOrange); c.px(43, 34, clawdShade)
    }

    // Bald on top; white wisps fluffing out over his ears and a few strands across the crown.
    c.pattern(16, 24, [
        "......................",
        ".W.....wwww.ww......W.",
        "WWw.................WW",
        "WWWw...............wWW",
        ".WWw...............wW.",
        "..w.................w.",
    ], ["W": wisp, "w": wispD])
    // Bushy white brows; heavy lids drooping over tired eyes, only the bottom of each eye showing under a dark lid
    // line that sags at the outer corner; a hollow under each cheek.
    c.rect(21, 28, 3, 1, wisp); c.rect(32, 28, 3, 1, wisp); c.px(24, 28, wispD); c.px(31, 28, wispD)
    let lid = C(0xEE9474), lidLine = C(0x7A3420)
    c.rect(22, 29, 2, 1, lid); c.rect(32, 29, 2, 1, lid)
    c.rect(22, 30, 2, 1, lidLine); c.rect(32, 30, 2, 1, lidLine); c.px(21, 30, lidLine); c.px(34, 30, lidLine)
    c.px(20, 32, clawdShade); c.px(35, 32, clawdShade)

    guard inhale >= 0 else { return }
    // His mouth open, drawing breath; the green mist streaming in from the right in curling threads, thinning to
    // nothing as it reaches him so it never smudges his outline.
    let mouth = lift > 0.3 ? 2 : 1
    c.rect(27, 32, 2, mouth, C(0x3A1C14))
    for i in 0..<16 {
        let u = (inhale * 3.2 + Double(i) / 16).truncatingRemainder(dividingBy: 1)
        let x = 66.0 - u * 26, y = 31 + sin(u * 7 + Double(i) * 1.7) * 6 * (1 - u)
        let a = 0.5 * lift * min(1, (1 - u) * 2.2) * min(1, u * 5)
        c.glowLine(x, y, x - 2, y + 0.3, core: C(0xA6F07A, a), glow: C(0x4CA040, a * 0.7), coreR: 0.5, glowR: 1.4)
    }
}

// MARK: - Pestilence

/// Pestilence, the Horseman of sickness: a rumpled olive suit gone shiny at the elbows, a yellowed shirt and a mustard
/// tie pulled loose, a hanky in the breast pocket, thin greasy hair combed over, and a green tinge to his whole face
/// with sallow rings under his eyes. Spreads plague in green waves. Signature: he coughs into his hanky, three hacking
/// coughs that shake him, and a green cloud billows out and drifts away.
private func drawPestilence(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x66684A), suitD = C(0x464832), suitL = C(0x8A8C66), shirt = C(0xD8D2A2), tie = C(0xA48C34)
    let tieD = C(0x76641E), hanky = C(0xECE8D4)
    let hair = C(0x4A4436), hairD = C(0x2E2A20), hairL = C(0x6E6650)
    let sick = C(0xA6C47A), sickD = C(0x7E9C58), sickL = C(0xC4DC9C)
    let s = p.signature ?? -1
    let cough = s > 0.05 && s < 0.95 ? (s - 0.05) / 0.9 : -1.0
    let handUp = cough < 0 ? 0.0 : min(1.0, cough / 0.1, (0.62 - cough) / 0.08)
    // Three coughs, each a sharp jerk forward and down.
    var jerk = 0
    for at in [0.16, 0.3, 0.44] where cough >= at && cough < at + 0.05 { jerk = 1 }

    drawLegs(c, Look(leg: C(0x56583E)), step: p.step)
    drawBoots(c, C(0x3A2C1E), step: p.step, rows: 1)

    c.oy += p.breathe + jerk
    let raise = handUp > 0 ? Int((handUp * 3).rounded()) : p.armRaise
    drawBody(c, Look(arm: suit), armRight: raise)
    // The green tinge: his whole face a sickly pale green, the far side in shade, his eyes redrawn on it and sallow
    // rings under them.
    c.rect(18, 26, 19, 7, sick); c.rect(37, 26, 1, 7, sickD)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(22, 32, 2, 1, sickD); c.rect(32, 32, 2, 1, sickD)

    // The suit, creased: lapels lit, the shirt and the loose tie in the V, its knot dragged down, the hanky poking out
    // of the breast pocket, wrinkles across the front, the far side and hem in shade.
    c.rect(18, 33, 20, 5, suit)
    c.pattern(23, 33, ["LLSSSSSSLL", ".LLSTTSLL.", "..LLtTLL..", "...LtTL...", "....tT...."],
              ["S": shirt, "T": tie, "t": tieD, "L": suitL])
    if handUp <= 0 { c.rect(33, 33, 2, 2, hanky); c.px(34, 33, C(0xC8C4B0)) }
    c.rect(33, 35, 3, 1, suitD)
    c.rect(18, 34, 1, 3, suitL); c.px(20, 35, suitD); c.px(21, 36, suitD); c.px(22, 35, suitD); c.px(35, 36, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD)

    // Thin greasy hair: parted low over his far ear, three long strands combed right across the top of his head,
    // the pale green scalp showing between them in bands.
    c.pattern(17, 22, [
        ".......sssssssss......",
        "....HHHHHHHHHHHHHsH...",
        "..HHHsssssssssssssss..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HH...............HHH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "s": sickL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    guard cough >= 0 else { return }
    if handUp > 0 {
        // The hanky over his mouth in his raised hand.
        let hy = 33 - raise
        c.rect(38, hy, 3, 3, clawdOrange)
        c.rect(36, hy - 1, 4, 3, hanky); c.px(36, hy + 1, C(0xC8C4B0))
    }
    // The cloud: puffs out with each cough, billows into a green cloud ahead of him and drifts up and away, fading.
    let puff = (cough - 0.16) / 0.84
    guard puff > 0 else { return }
    for i in 0..<9 {
        let n = noise(i * 7 + 3)
        let start = Double(i % 3) * 0.1
        let f = max(0, min(1, (puff - start) / 0.75))
        guard f > 0 else { continue }
        let x = 44 + f * 12 + n * 7, y = 30 - f * 7 + (Double(i % 3) - 1) * 2.4 + n * 2
        let r = 1.6 + f * 3.4 + n
        let fade = min(1.0, f * 5) * min(1.0, (1 - f) * 1.6)
        c.glowLine(x, y, x + 1, y, core: C(0xA8DC5E, 0.62 * fade), glow: C(0x5E9428, 0.62 * fade),
                   coreR: r * 0.6, glowR: r)
    }
}

// MARK: - Death

/// Death, the eldest of the Horsemen: tall and thin, in a narrow black suit with a crisp white shirt and a skinny
/// black tie, thin grey hair combed straight back off a high brow, hollow cheeks and a stern brow, and his black
/// cane with its silver knob. His touch is grey and black. Signature: a little diner table appears before him with a
/// chili dog on a plate, and he eats it neatly with a knife and fork, a bite at a time.
private func drawDeath(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x18181E), suitD = C(0x08080C), suitL = C(0x3C3C48), shirt = C(0xF0F0EC), tie = C(0x0A0A0C)
    let hair = C(0x8A8A90), hairD = C(0x5A5A62), hairL = C(0xC8C8CE)
    let cane = C(0x141418), silver = C(0xD0D4DA), silverD = C(0x8A8E96)
    let s = p.signature ?? -1
    let eat = s > 0.04 && s < 0.96 ? (s - 0.04) / 0.92 : -1.0

    // His trousers black, his shoes polished a shade apart.
    drawLegs(c, Look(leg: C(0x24242C)), step: p.step)
    drawBoots(c, C(0x060608), step: p.step, rows: 1)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 43, C(0x4A4A54)) } }

    if eat < 0 && !seatedPose {
        // The cane, its tip on the floor, its silver knob in his hand.
        let r = p.armRaise
        c.rect(41, 34 - r, 1, 10, cane); c.px(42, 36 - r, C(0x3A3A44))
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: eat >= 0 ? 3 : p.armRaise)
    // A high brow: the head a few rows taller than anyone's, the hair starting high up it.
    c.rect(19, 21, 17, 5, clawdOrange); c.rect(36, 22, 1, 4, clawdShade); c.px(19, 21, C(0, 0))

    // The suit, cut narrow: thin lapels lit at the edge, the white shirt and skinny tie, faint pinstripes running
    // down to make him look longer, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, suit)
    for x in [20, 23, 33, 36] { c.rect(x, 34, 1, 3, C(0x2A2A34)) }
    c.pattern(24, 33, ["LSSSSSSL", ".LSSTSL.", "..LSTL..", "...LTL..", "....T..."],
              ["S": shirt, "T": tie, "L": suitL])
    c.rect(18, 34, 1, 3, suitL); c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(15, 34, shirt)

    // Thin grey hair combed straight back from that high brow: a few long strands lying flat along his skull with the
    // scalp showing between them, shorter towards the front where it recedes, and thicker at the back of his head.
    c.pattern(17, 19, [
        "......HHHHHHH.........",
        "...HHHllllllHHH.......",
        ".HHHHHHHHHHHHHHHHh....",
        ".HHh..................",
        ".HHHHHHHHHHHHh........",
        ".HHh..................",
        ".HHHHHHHHh............",
        ".HHh..................",
        ".Hh...................",
    ], ["H": hair, "h": hairD, "l": hairL])
    // A stern brow, and the hollows under his cheekbones.
    c.rect(21, 28, 3, 1, hairD); c.rect(32, 28, 3, 1, hairD)
    c.rect(20, 30, 1, 3, clawdShade); c.rect(35, 30, 1, 3, clawdShade)

    if eat < 0 {
        if !seatedPose {
            let r = p.armRaise
            c.rect(40, 32 - r, 3, 2, silver); c.px(42, 33 - r, silverD); c.px(40, 32 - r, C(0xF4F6FA))
        }
        return
    }
    // The table: a red diner top edged in chrome on one chrome pedestal. On it a plate, and on the plate the chili
    // dog, big enough to see from across the room: a long bun, the sausage poking out at both ends, chili heaped
    // along the top and a squiggle of mustard over it. Each bite takes the end off.
    let k = min(1.0, eat / 0.08, (1 - eat) / 0.08)
    guard k > 0.3 else { return }
    let bites = eat < 0.32 ? 0 : eat < 0.58 ? 1 : eat < 0.84 ? 2 : 3
    c.oy -= p.breathe
    c.rect(41, 37, 18, 1, C(0xB4343A)); c.rect(41, 38, 18, 1, C(0xD8DEE2)); c.rect(41, 37, 1, 1, C(0xD84A4E))
    c.rect(49, 39, 2, 4, C(0xA8AEB4)); c.px(49, 39, C(0xDCE0E4)); c.rect(46, 43, 8, 1, C(0x8A9096))
    c.rect(42, 36, 16, 1, C(0xF2F2EE)); c.rect(43, 35, 14, 1, C(0xDCDCD6)); c.px(42, 36, C(0xFFFFFF))
    let x1 = 55 - bites * 4
    if bites < 3 {
        let bun = C(0xE0A862), bunD = C(0xAA7438), bunL = C(0xF4C88A), sausage = C(0xB0402C)
        let chili = C(0x7A2E18), chiliL = C(0xB84A28), mustard = C(0xF2CC2A)
        c.rect(44, 32, x1 - 43, 3, bun); c.rect(44, 34, x1 - 43, 1, bunD); c.rect(44, 32, x1 - 43, 1, bunL)
        c.rect(43, 31, x1 - 41, 1, sausage); c.px(43, 32, sausage)
        c.rect(44, 30, x1 - 43, 1, chili)
        for x in stride(from: 45, through: x1, by: 2) { c.px(x, 30, chiliL); c.px(x, 29, chili) }
        for x in 44...x1 { c.px(x, (x / 2) % 2 == 0 ? 29 : 30, mustard) }
        c.px(x1, 31, C(0xD86A50))   // the cut end
    }
    c.oy += p.breathe
    // Knife and fork: the fork in his near hand, the knife in the other, sawing; after each cut the fork carries a
    // bite up to his mouth.
    let phase = (eat * 3).truncatingRemainder(dividingBy: 1)
    let lifting = phase > 0.55 && phase < 0.92 && bites < 3
    let saw = Int(p.t * 10) % 2
    let fork = C(0xC8CCD2)
    if lifting {
        c.rect(38, 28, 3, 3, clawdOrange)
        huntLine(c, 37, 30, 34, 32, fork, 0.5); c.px(34, 32, C(0x6A2A18))
    } else {
        c.rect(38, 30, 3, 3, clawdOrange)
        huntLine(c, 40, 31, 44, 32, fork, 0.5); c.px(45, 31, fork); c.px(45, 32, fork)
    }
    let kx = x1 - 3 + saw
    c.rect(kx, 26, 2, 2, clawdOrange); c.px(kx + 1, 27, clawdShade)
    c.rect(kx, 28, 1, 4, C(0xE4E8EE)); c.px(kx + 1, 28, C(0x2A2A30))   // the knife, its handle in his fist
}
