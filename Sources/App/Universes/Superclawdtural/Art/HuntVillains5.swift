import Foundation

// Villains: the rest of Heaven's angels and the last Big Bads. Drawn the way HuntVillains1.swift draws Clawdley
// (HuntHeroes1.swift's header has the Persona fields; HuntKit.swift the shared helpers): each one a `Persona` in the
// dictionary below and a `private func draw…` further down.
//
// The angels keep to their vessels' clothes: Uriel's long brown overcoat with its collar up, Raphael's charcoal
// three-piece, Naomi's dove-grey skirt suit, Gadreel's olive field jacket. Only Raphael shows his wings, and only as
// a shadow in the lightning. The Big Bads: Eve barefoot in a ragged linen shift under a mane of wild copper hair,
// Amara in a floor-length black gown with a violet sheen, and Billie the reaper in a long black leather coat with
// Death's scythe. The two redheads here are told apart from Abaddon, Rowena and Charlie by everything below the
// hair: Naomi's prim suit and neat auburn bob, Eve's bare feet and the twigs in her mane.

let huntVillains5: [HuntVillain: Persona] = [
    .uriel: Persona(name: "Uriel", weapon: .saber, headTop: 24, draw: drawUriel),
    .raphael: Persona(name: "Raphael", weapon: .lightning,
                      magic: Magic(core: C(0xFFFFFF), glow: C(0x9AA8C8), bolts: 3),
                      headTop: 24, signature: 3.2, draw: drawRaphael),
    .naomi: Persona(name: "Naomi", weapon: .lightning,
                    magic: Magic(core: C(0xFFFFFF), glow: C(0xECEEF4), jagged: false, touch: true),
                    pivot: (45, 34.5), headTop: 20, draw: drawNaomi),
    .gadreel: Persona(name: "Gadreel", weapon: .saber, headTop: 22, draw: drawGadreel),
    .eve: Persona(name: "Eve", headTop: 16, signature: 3.6, draw: drawEve),
    .amara: Persona(name: "Amara", weapon: .lightning,
                    magic: Magic(core: C(0x6A3C9A), glow: C(0x10061A), jagged: false),
                    headTop: 20, signature: 3.6, draw: drawAmara),
    .billie: Persona(name: "Billie", weapon: .saber, headTop: 18, signature: 3.6, draw: drawBillie),
]

// MARK: - Shared bits

/// How far `s` is from `a` to `b`, 0 before and 1 after.
private func hv5Ramp(_ s: Double, _ a: Double, _ b: Double) -> Double { min(1, max(0, (s - a) / (b - a))) }

/// An angel blade held point down at his side, the fist round its grip, for the angels when they're not fighting.
private func hv5BladeAtRest(_ c: PixelCanvas, grip: Px, steel: Px, steelD: Px, edge: Px) {
    c.rect(39, 34, 2, 2, grip)
    c.rect(39, 36, 2, 6, steel); c.rect(40, 36, 1, 6, steelD); c.px(39, 36, edge); c.px(40, 42, edge)
    c.rect(38, 34, 3, 2, clawdOrange)
}

// MARK: - Uriel

/// Uriel, Heaven's soldier: stern, a long dark brown wool overcoat to the knees, double-breasted and buttoned, its
/// collar turned up round his jaw, a black roll-neck under it, his head shaved close with a little grey at the
/// temples, and a heavy frown. Fights with his angel blade.
private func drawUriel(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x3E332A), coatD = C(0x241D18), coatL = C(0x5E4E40), button = C(0x16120E)
    let knit = C(0x3A3A44), knitL = C(0x5A5A6A)
    let hair = C(0x221C18), hairL = C(0x44392F), grey = C(0x8A8580)

    // Charcoal trousers and black shoes under the coat.
    drawLegs(c, Look(leg: C(0x2A282E)), step: p.step)
    drawBoots(c, C(0x0E0C0C), step: p.step, rows: 1)

    c.oy += p.breathe
    // The coat's skirts to the knees: a fold over each leg, the front edge where the two sides overlap, the hem a
    // shade darker, and four legs showing below.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 22, 1, coatD)
        c.rect(17, 38, 1, 2, coatL); c.rect(38, 38, 1, 3, coatD)
        for x in [21, 25, 34] { c.rect(x, 38, 1, 2, coatD) }
        c.rect(31, 38, 1, 3, C(0x1A1410))
    }
    drawBody(c, Look(arm: coat), armRight: p.armRaise)

    // The coat over the body, closed: the roll-neck in the V of the lapels, two rows of buttons, the shoulders lit,
    // the far side in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 1, knitL); c.rect(25, 34, 6, 1, knit); c.rect(26, 35, 4, 1, knit)
    for x in [26, 28, 30] { c.px(x, 34, knitL) }
    c.px(23, 33, coatL); c.px(24, 34, coatL); c.px(25, 35, coatL); c.px(26, 36, coatL)
    c.px(32, 33, coatD); c.px(31, 34, coatD); c.px(30, 35, coatD); c.px(29, 36, coatD)
    c.rect(19, 33, 3, 1, coatL); c.rect(34, 33, 2, 1, coatL); c.rect(18, 34, 1, 3, coatL)
    for (x, y) in [(23, 36), (33, 36), (22, 34), (34, 34)] { c.px(x, y, button) }
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD)

    // Shaved close: a dark cap of stubble lit along the top, a little grey at the temple.
    c.pattern(18, 24, [
        "...HHHHHHHHHHHHHH...",
        ".HHHlHHlHHlHHlHHHH..",
        "HHHHHHHHHHHHHHHHHHHH",
        "Hg................gH",
        "g...................",
    ], ["H": hair, "l": hairL, "g": grey])
    // The frown: brows drawn down to the middle, a hard straight mouth.
    c.px(21, 27, hair); c.px(22, 27, hair); c.px(23, 28, hair)
    c.px(32, 28, hair); c.px(33, 27, hair); c.px(34, 27, hair)
    c.rect(26, 32, 4, 1, C(0x7A3A2C))

    let grip = C(0x5A5E66), steel = C(0xB4BAC4), edge = C(0xF4F6FA)
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: grip, steel: steel, edge: edge, length: 11)
    } else {
        hv5BladeAtRest(c, grip: grip, steel: steel, steelD: C(0x7E848E), edge: edge)
    }
}

// MARK: - Raphael

/// Raphael, the archangel: big and imposing, his head shaved bald with a shine on it, heavy brows, a charcoal
/// three-piece suit over a black shirt and a silver tie. His power is a jagged white lightning, thick with forks.
/// Signature: thunder cracks behind him, twice, and in each flash his wings' shadow shows on the wall, his eyes
/// lit white.
private func drawRaphael(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x34343C), suitD = C(0x1C1C22), suitL = C(0x56566A), vest = C(0x26262C)
    let shirt = C(0x101014), tie = C(0xA8ACB6), tieD = C(0x6E727C)
    let s = p.signature ?? -1
    // Two cracks: a sharp flash at each, dying away fast; the wings open over the whole of it, darkest in the flashes.
    let cracks = [0.16, 0.5]
    let flash = s < 0 ? 0 : cracks.map { at -> Double in
        let d = s - at
        return d < 0 || d > 0.2 ? 0 : d < 0.02 ? d / 0.02 : pow(1 - (d - 0.02) / 0.18, 2)
    }.max() ?? 0
    let wings = s < 0 ? 0 : sin(hv5Ramp(s, 0.12, 0.92) * .pi)

    if flash > 0.05 {
        // The room lit white for a moment, and the bolt itself coming down out of the sky behind him on the left: a
        // forked line of light, re-struck as it flickers. See-through, so it gets no outline.
        c.glowLine(28, 30, 28, 30, core: C(0xFFFFFF, 0), glow: C(0xE8EEFF), coreR: 0.1, glowR: 24,
                   strength: 0.22 * flash)
        let which = s < 0.4 ? 0 : 1
        let seed = which * 37 + Int(p.t * 14) % 3
        var prev = (which == 0 ? 9.0 : 5.0, -1.0)
        for i in 1...6 {
            let f = Double(i) / 6
            let q = ((which == 0 ? 9.0 : 5.0) + 4 * f + (noise(seed * 11 + i) - 0.5) * 7, -1 + 27 * f)
            c.glowLine(prev.0, prev.1, q.0, q.1, core: C(0xFFFFFF, 0.95 * flash), glow: C(0xB8C8FF, flash),
                       coreR: 0.9, glowR: 3)
            if i == 3 {   // a fork off to the side
                c.glowLine(q.0, q.1, q.0 - 4, q.1 + 5, core: C(0xFFFFFF, 0.8 * flash), glow: C(0xB8C8FF, flash),
                           coreR: 0.4, glowR: 1.6)
            }
            prev = q
        }
    }
    huntWingShadows(c, min(1, wings * 1.3), strength: 0.3 + 0.35 * flash)

    drawLegs(c, Look(leg: C(0x2C2C34)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx, top, 1, 4, C(0x40404C))   // the crease down each trouser leg
        }
    }
    drawBoots(c, C(0x0A0A0C), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: nil), armRight: p.armRaise)
    // His bald head, rising a little above anyone else's, lit on top at the front, a shine on the crown.
    c.rect(20, 24, 16, 1, clawdOrange); c.rect(19, 25, 18, 1, clawdOrange)
    c.rect(22, 24, 4, 1, C(0xF2A688)); c.rect(20, 25, 2, 1, C(0xF2A688)); c.px(21, 26, C(0xF2A688))
    c.px(35, 24, clawdShade); c.px(36, 25, clawdShade)

    // The suit: notched lapels lit along their edge, the black shirt and silver tie, the waistcoat buttoned under
    // it, the shoulders lit, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 2, shirt); c.rect(25, 35, 6, 2, vest); c.px(25, 35, suitL); c.px(30, 35, suitD)
    c.rect(27, 33, 2, 1, tieD); c.rect(27, 34, 2, 2, tie); c.px(28, 35, tieD); c.px(27, 36, tie)
    c.rect(24, 33, 1, 4, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 4, suitD); c.px(32, 34, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL); c.rect(18, 34, 1, 3, suitL)
    c.rect(20, 36, 3, 1, suitD); c.rect(33, 36, 3, 1, suitD)   // the pocket flaps
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 35, C(0x0A0A0C))

    // Heavy brows and a set mouth; his eyes white while the lightning lasts.
    c.rect(21, 28, 3, 1, C(0x5A2A1C)); c.rect(32, 28, 3, 1, C(0x5A2A1C))
    c.rect(26, 32, 4, 1, C(0x8A3A2C))
    if flash > 0.3 {
        for x in [22, 32] { c.rect(x, 29, 2, 3, C(0xF2F6FF)); c.px(x, 29, white); c.rect(x, 31, 2, 1, C(0xC8D4EC)) }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
}

// MARK: - Naomi

/// Naomi, Heaven's head of security: a neat auburn bob, side-parted and turned under at the jaw, a prim dove-grey skirt
/// suit with a little gold brooch on the lapel, a cream blouse with a burgundy ribbon bow at the throat, sheer stockings and grey
/// heels. Her mind-wipe is a touch: one finger out, a needle-thin point of white light.
private func drawNaomi(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xB4B2BA), suitD = C(0x8A8892), suitL = C(0xD4D2DA)
    let blouse = C(0xF2E8D6), blouseD = C(0xCCBEA6), gold = C(0xE0B848), goldD = C(0x9A7A28)
    let hair = C(0x8E3A22), hairD = C(0x5E2214), hairL = C(0xBA5E3C)

    // Sheer tan stockings, a sheen down the front of each, and grey heels.
    drawLegs(c, Look(leg: C(0xC4826A)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 40, 1, 2, C(0xD8A08A)) } }
    drawBoots(c, C(0x3A3840), step: p.step, rows: 1)

    c.oy += p.breathe
    // The pencil skirt to the knee, straight down, a kick pleat at the back and a fold at the front.
    if seatedPose {
        c.rect(17, 38, 22, 1, suit); c.px(17, 38, suitL)
    } else {
        c.rect(18, 38, 20, 2, suit); c.rect(18, 39, 20, 1, suitD)
        c.px(18, 38, suitL); c.rect(20, 38, 1, 2, suitD); c.px(27, 38, suitD); c.rect(37, 38, 1, 2, suitD)
    }
    drawBody(c, Look(arm: suit), armRight: p.armRaise)

    // The jacket: narrow lapels lit along their edge, the cream blouse and its bow, the brooch, one button at the waist,
    // a dart either side, the far side in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 1, blouse); c.rect(26, 34, 4, 1, blouse); c.rect(27, 35, 2, 1, blouse)
    c.px(30, 33, blouseD); c.px(29, 34, blouseD)
    c.rect(27, 33, 2, 1, C(0x7A2A3A)); c.px(27, 34, C(0x5A1E2A)); c.px(28, 35, C(0x7A2A3A))   // the bow, a ribbon
    c.rect(24, 33, 1, 3, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 3, suitD); c.px(32, 34, suitD)
    c.px(21, 34, gold); c.px(21, 35, goldD)
    c.px(28, 36, C(0x5A5862)); c.px(21, 37, suitD); c.px(34, 37, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL); c.rect(18, 34, 1, 3, suitL)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.px(28, 37, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 35, blouse)

    // The bob: parted on the far side and swept across her brow, sleek, the ends turned under at her jaw; on the near
    // side it's tucked back off her face.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHlllHHHHHHHH....",
        "...HHHHHHHHHlllHHHHHH...",
        "..HHHHlHHHHHHHHHHHHHHH..",
        "..HHHlHHHHHHHHHHHHHHHHH.",
        "..HHlHHHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHdddd....HHH.",
        "..HHHHd..............HH.",
        "..HHHd...............dH.",
        "..HHHd...............d..",
        "..HHHd..................",
        "..HHHHd.................",
        "...dHHd.................",
    ], ["H": hair, "d": hairD, "l": hairL])
    // Fine arched brows, and a prim little mouth.
    c.rect(22, 27, 2, 1, hairD); c.rect(32, 27, 2, 1, hairD)
    c.rect(27, 32, 2, 1, C(0xB0505A))

    // Casting: one finger held out from the fist, the white point of light at its tip (the engine's touch).
    if p.armRaise > 0 {
        let y = 34 - p.armRaise
        c.rect(41, y, 3, 1, clawdOrange); c.px(43, y, C(0xF0A080))
    }
}

// MARK: - Gadreel

/// Gadreel, the angel who let the serpent in: a plain olive canvas field jacket with chest pockets, open over a
/// charcoal henley, dark jeans and brown boots, short dark hair, a shadow of stubble and a sorry, worried brow.
/// Fights with his angel blade.
private func drawGadreel(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x5C5E40), jacketD = C(0x3C3E2A), jacketL = C(0x7E8058)
    let henley = C(0x2E2E34), henleyL = C(0x46464E), button = C(0x9A9AA2)
    let hair = C(0x3A2A1E), hairD = C(0x22180E), hairL = C(0x5E4632), stubble = C(0xA45A40)

    // Dark jeans, faded down the front of each leg, and brown boots.
    drawLegs(c, Look(leg: C(0x2E3650)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx, top, 1, 3, C(0x465070))
        }
    }
    drawBoots(c, C(0x4A3624), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: p.armRaise)

    // The jacket, open down the front on the henley and its buttoned placket: a stand collar, two chest pockets with
    // flaps and buttons, the near edge lit, the waistband and the far side in shade, cuffs.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, henley); c.rect(25, 33, 6, 1, henleyL); c.rect(28, 34, 1, 2, henleyL)
    c.px(28, 34, button); c.px(28, 36, button)
    c.rect(24, 33, 1, 5, jacketL); c.rect(31, 33, 1, 5, jacketD)
    c.rect(22, 33, 2, 1, jacketL); c.rect(32, 33, 2, 1, jacketD)
    c.rect(19, 34, 4, 1, jacketD); c.px(21, 35, jacketL); c.rect(19, 35, 1, 2, jacketL)
    c.rect(33, 34, 3, 1, jacketD); c.px(34, 35, jacketL)
    c.rect(18, 37, 20, 1, jacketD); c.rect(37, 33, 1, 5, jacketD); c.rect(18, 34, 1, 3, jacketL)
    c.rect(15, 35, 3, 1, jacketD); c.rect(38, 35 - p.armRaise, 3, 1, jacketD)

    // Short dark hair, neat but tousled on top, cut close at the sides.
    c.pattern(17, 22, [
        ".....HHHHHHHHHHHH.....",
        "...HHHlHHHlHHHHlHHH...",
        "..HHHHHHHHHHHHHHHHHH..",
        ".HHhHHHhHHHHhHHHHhHH..",
        ".HH...............hH..",
        ".Hh...............h...",
    ], ["H": hair, "h": hairD, "l": hairL])
    // A sorry brow, raised in the middle; stubble along the jaw.
    c.px(22, 28, hairD); c.px(23, 27, hairD); c.px(32, 27, hairD); c.px(33, 28, hairD)
    c.rect(19, 32, 3, 1, stubble); c.px(20, 31, stubble); c.rect(34, 32, 3, 1, stubble); c.px(35, 31, stubble)

    let grip = C(0x6A6E76), steel = C(0xB4BAC4), edge = C(0xF4F6FA)
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: grip, steel: steel, edge: edge, length: 11)
    } else {
        hv5BladeAtRest(c, grip: grip, steel: steel, steelD: C(0x7E848E), edge: edge)
    }
}

// MARK: - Eve

/// Eve, the Mother of All monsters: barefoot and wild, a mane of copper hair to her waist with a twig and its leaves
/// caught in it, a ragged linen shift tied with a rope, and a claw on a cord round her neck. She doesn't fight.
/// Signature: she holds out her hand, palm up, and a little monster crawls out of it, looks about, hops down and
/// scuttles off, then burrows into the ground.
private func drawEve(_ c: PixelCanvas, _ p: Pose) {
    let linen = C(0xD6C8A8), linenD = C(0xA89878), linenL = C(0xECE2C8)
    let rope = C(0x7A5A34), ropeL = C(0xA07C4E), bone = C(0xE8E0CC)
    let hair = C(0xA4482A), hairD = C(0x6A2A14), hairL = C(0xD0703E)
    let twig = C(0x4A3420), leaf = C(0x5A7A34), leafL = C(0x86A84C)
    let s = p.signature ?? -1
    let raise = s < 0 ? 0 : Int((min(hv5Ramp(s, 0.04, 0.14), 1 - hv5Ramp(s, 0.54, 0.62)) * 3).rounded())

    // Bare legs, her soles dusty.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, C(0xB86A50), step: p.step, rows: 1)

    c.oy += p.breathe
    // The shift to the knee, its hem ragged, folds over the legs, the near side lit.
    if seatedPose {
        c.rect(17, 38, 22, 1, linen); c.px(17, 38, linenL)
    } else {
        c.rect(17, 38, 22, 2, linen)
        for x in 17...38 where x % 3 != 1 { c.px(x, 40, x % 3 == 0 ? linen : linenD) }
        c.rect(17, 38, 1, 2, linenL); c.rect(38, 38, 1, 2, linenD)
        for x in [21, 26, 33] { c.rect(x, 38, 1, 2, linenD) }
    }
    drawBody(c, Look(), armRight: raise)

    // The bodice: bare shoulders and a scoop neck, the claw hanging on its cord, the rope tied at her waist with its
    // ends hanging, folds in the linen, the far side in shade.
    c.rect(18, 33, 20, 5, linen)
    c.rect(24, 33, 8, 1, clawdOrange); c.rect(25, 34, 6, 1, clawdOrange)
    c.px(25, 34, rope); c.px(26, 35, rope); c.px(29, 35, rope); c.px(30, 34, rope)
    c.rect(27, 35, 2, 1, bone); c.px(28, 36, bone); c.px(27, 36, C(0xB8AE96))
    c.rect(18, 36, 20, 1, rope); for x in stride(from: 19, to: 38, by: 3) { c.px(x, 36, ropeL) }
    c.rect(22, 37, 1, 3, rope); c.px(23, 38, ropeL)
    c.rect(20, 33, 1, 3, linenD); c.rect(34, 34, 1, 2, linenD)
    c.rect(18, 33, 1, 3, linenL); c.rect(37, 33, 1, 5, linenD); c.rect(18, 37, 20, 1, linenD)

    // The mane: wild copper hair, tangled, streaming down her back to the waist, a twig with leaves caught on top and a
    // leaf in the tangles behind.
    c.pattern(12, 18, [
        "...........HH..HHH..........",
        ".........HHHHHHHHHHHH.H.....",
        "......H.HHHlHHHHHlHHHHHH....",
        ".....HHHHlHHHHHHHHHlHHHHH...",
        "....HHHlHHHHHdHHHHHHHlHHHH..",
        "...HHHlHHHHHHHHdHHHHHHHlHHH.",
        "..HHHlHHHHHHHHHHHHHHHHHHlHH.",
        "..HHlHHHHdHHHHHHHHHHdHHHHHHH",
        ".HHHlHHHHHHHdHHHHHdHHHHHHHH.",
        ".HHlHHHHH....HHH.....HHHHHH.",
        "HHHlHHHd..............dHHHH.",
        ".HHlHHd................dHHH.",
        "HHHlHHd................dHH..",
        ".HHHlHd.................dH..",
        "HHHlHHd..................d..",
        ".HHlHHd.....................",
        "HHHHlHd.....................",
        ".HHlHHd.....................",
        "HHHlHd......................",
        ".HHlHd......................",
        "..HHd.......................",
        ".HdH........................",
        "..d.........................",
    ], ["H": hair, "d": hairD, "l": hairL])
    c.px(32, 19, twig); c.px(33, 18, twig); c.px(34, 17, twig); c.px(35, 17, leaf); c.px(35, 16, leafL)
    c.px(33, 17, leaf)
    c.px(14, 27, leaf); c.px(15, 26, leafL)
    // Her brows low and wild, a wide mouth.
    c.rect(21, 28, 3, 1, hairD); c.rect(32, 28, 3, 1, hairD)
    c.rect(26, 32, 4, 1, C(0x9A4A3A))

    guard s >= 0 else { return }
    // The little monster: a mossy, spiny thing with a glowing eye, a tail and six scrabbling legs.
    let legsUp = Int(p.t * 12) % 2 == 0
    func beastie(_ x: Int, _ y: Int, rows: Int = 4, sink: Int = 0) {
        let art = [
            "..s.s..",
            ".kkkkkk",
            "tkKKkEk",
            legsUp ? ".l.l.l." : "..l.l.l",
        ]
        let cols: [Character: Px] = ["s": C(0x2A3220), "k": C(0x3E4A2C), "K": C(0x62763E), "t": C(0x3E4A2C),
                                     "E": C(0xFF6A2A), "l": C(0x2A3220)]
        for (dy, row) in art.enumerated() where dy >= 4 - rows {
            guard y + dy + sink <= 43 else { continue }
            for (dx, ch) in row.enumerated() { if let col = cols[ch] { c.px(x + dx, y + dy + sink, col) } }
        }
    }
    let palmY = 33 - raise
    if raise > 0 {
        // Her hand turned palm up, the fingers cupped.
        c.px(41, palmY, clawdOrange); c.px(41, palmY - 1, C(0xF0A080))
    }
    if s > 0.16 && s < 0.36 {
        // It climbs up out of her palm, a row at a time, a faint dark glow round it.
        let k = hv5Ramp(s, 0.16, 0.34)
        c.glowLine(41, Double(palmY - 2), 41, Double(palmY - 2), core: C(0x3E4A2C, 0), glow: C(0x6A8A3A),
                   coreR: 0.1, glowR: 4, strength: 0.18 * sin(k * .pi))
        beastie(37, palmY - 4, rows: max(1, Int((k * 4).rounded(.up))))
    } else if s >= 0.36 && s < 0.5 {
        beastie(37, palmY - 4)   // sitting on her palm, looking about
    } else if s >= 0.5 && s < 0.62 {
        // The hop down to the floor, in an arc.
        let k = hv5Ramp(s, 0.5, 0.62)
        c.oy -= p.breathe
        let x = 37 + Int((k * 7).rounded()), y = Int((Double(palmY - 4) + (40 - Double(palmY - 4)) * k - sin(k * .pi) * 5).rounded())
        beastie(x, y)
        c.oy += p.breathe
    } else if s >= 0.62 && s < 0.96 {
        // Scuttling off to the right, then burrowing into the ground with a spray of dirt.
        c.oy -= p.breathe
        let run = hv5Ramp(s, 0.62, 0.84), dig = hv5Ramp(s, 0.84, 0.95)
        let x = 44 + Int((run * 12).rounded())
        beastie(x, 40, sink: Int((dig * 4).rounded()))
        if dig > 0 && dig < 1 {
            let dirt = C(0x6A4A2E)
            let hop = Int(p.t * 10) % 2
            c.px(x - 1, 42 - hop, dirt); c.px(x + 7, 41 + hop, dirt); c.px(x - 2, 40 + hop, C(0x8A6440))
        }
        c.oy += p.breathe
    }
}

// MARK: - Amara

/// Whether the canvas already holds a solid pixel at (x, y) (in the current offsets).
private func hv5Solid(_ c: PixelCanvas, _ x: Int, _ y: Int) -> Bool {
    let xx = x + c.ox, yy = y + c.oy + c.baseY
    guard xx >= 0, yy >= 0, xx < c.w, yy < c.h else { return false }
    return c.buf[(yy * c.w + xx) * 4 + 3] >= 250
}

/// A pixel of Amara's mist, drawn once she's drawn: behind her it doesn't show over her, in front it does; and
/// right next to her silhouette it stays faint, so her outline stays whole.
private func hv5Mist(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px, _ a: Double, front: Bool) {
    let solid = hv5Solid(c, x, y)
    if solid && !front { return }
    let edge = !solid && (hv5Solid(c, x + 1, y) || hv5Solid(c, x - 1, y) || hv5Solid(c, x, y + 1) || hv5Solid(c, x, y - 1))
    c.px(x, y, col.alpha(edge ? min(a, 0.2) : solid ? min(a, 0.5) : a))
}

/// Amara, the Darkness, God's sister: long dark brown hair falling in soft waves, a black gown to the floor with long
/// sleeves and a straight off-the-shoulder neckline, a violet sheen in its folds, her shoes peeping under the hem,
/// plum lips. Her power is the Darkness, a steady black-violet ray. Signature: black mist gathers and swirls round
/// her, rising, her eyes catching violet, then it thins away.
private func drawAmara(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0x1A1422), gownD = C(0x0C0812), gownL = C(0x3A2850), sheen = C(0x5A4280)
    let hair = C(0x3A261C), hairD = C(0x20140E), hairL = C(0x60442F)
    let s = p.signature ?? -1
    let mist = s < 0 ? 0 : sin(hv5Ramp(s, 0.04, 0.96) * .pi)

    // The swirl: wisps of black mist going round her on a tilted ring and rising as they go. `front`: the half that
    // passes in front of her (drawn over her), or the half behind.
    func swirl(front: Bool) {
        guard mist > 0.02 else { return }
        for i in 0..<22 {
            let a = p.t * 1.6 + Double(i) / 22 * 2 * .pi
            let inFront = sin(a) > 0
            guard inFront == front else { continue }
            let rise = (p.t * 0.25 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let cx = 28 + cos(a) * 20, cy = 40 - rise * 20 + sin(a) * 5
            let fade = mist * sin(rise * .pi)
            let col = i % 3 == 0 ? C(0x7A52B4) : i % 3 == 1 ? C(0x4A2C78) : C(0x140A20)
            for (dx, dy, k) in [(0, 0, 1.0), (1, 0, 0.85), (-1, 0, 0.85), (0, -1, 0.75), (1, -1, 0.6), (-1, -1, 0.5),
                                (-2, 0, 0.5), (2, 0, 0.4), (0, 1, 0.5)] {
                hv5Mist(c, Int(cx.rounded()) + dx, Int(cy.rounded()) + dy, col, 0.9 * fade * k, front: front)
            }
        }
    }
    // Dark stockings and black shoes under the gown.
    drawLegs(c, Look(leg: C(0x1A1620)), step: p.step)
    drawBoots(c, C(0x0A080C), step: p.step, rows: 2)

    // The gown's skirt to the floor, flaring at the hem: the violet sheen down the near side of each leg, shadow
    // between them, so the four legs show through the folds and the shoes peep out below.
    if seatedPose {
        c.rect(16, 37, 24, 3, gown); c.rect(16, 39, 24, 1, gownD)
        for x in [20, 24, 32, 36] { c.px(x, 38, gownL) }
    } else {
        c.rect(17, 37, 22, 3, gown); c.rect(16, 40, 24, 2, gown); c.rect(16, 41, 24, 1, gownD)
        for x in [19, 31] { c.rect(x, 38, 1, 3, gownL); c.px(x, 38, sheen) }
        for x in [23, 35] { c.rect(x, 38, 1, 2, gownL) }
        for x in [22, 34] { c.rect(x, 39, 1, 2, gownD) }
        c.rect(28, 38, 1, 3, gownD); c.px(27, 40, gownD)
        c.rect(38, 37, 1, 4, gownD); c.px(16, 40, gownL); c.px(17, 39, gownL)
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: gown, eye: nil), armRight: p.armRaise)

    // The bodice: a straight neckline across bare shoulders, edged in violet, a seam at the waist, the sheen in strokes
    // down the near side, the far side in shade.
    c.rect(18, 33, 20, 5, gown)
    c.rect(20, 33, 16, 1, clawdOrange); c.px(35, 33, clawdShade)
    c.rect(20, 34, 16, 1, gownL); c.rect(21, 34, 3, 1, sheen)
    c.rect(19, 35, 1, 2, gownL); c.px(20, 35, sheen); c.rect(25, 35, 1, 2, gownL)
    c.rect(18, 37, 20, 1, gownD); c.rect(18, 36, 20, 1, C(0x221A2E)); c.rect(37, 33, 1, 5, gownD)
    c.rect(15, 35, 3, 1, gownD); c.rect(38, 35 - p.armRaise, 3, 1, gownD)

    // Long dark brown hair, parted on the far side, falling in soft waves past her shoulders, a gleam along each wave.
    c.pattern(15, 20, [
        "......HHHHHHHHHHHH.......",
        "....HHHHHHllHHHHHHHH.....",
        "...HHlHHHHHHHHlllHHHHH...",
        "..HHlHHHHHHHHHHHHHHHHHH..",
        "..HlHHHHHHHHHHHHHHHHHHHH.",
        ".HHlHHHHHHdHHHHHHHHHHHHH.",
        ".HlHHHHHH...........HHHH.",
        ".HHlHHd..............HHH.",
        "HHlHHd...............dHHd",
        ".HHlHd...............dHH.",
        ".HlHHd................HHd",
        "HHlHd.................dHH",
        ".HHlHd................HHd",
        ".HlHHd.................d.",
        "HHlHd....................",
        ".HHlHd...................",
        "..HlHd...................",
        "...dd....................",
    ], ["H": hair, "d": hairD, "l": hairL])
    // Dark brows, eyes catching violet in the mist, plum lips.
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    for x in [22, 32] {
        c.rect(x, 29, 2, 3, ink)
        if mist > 0.4 { c.px(x + 1, 29, C(0xB48AE8)); c.px(x, 31, C(0x4A2A6A)) }
    }
    c.rect(26, 32, 4, 1, C(0x6A2440)); c.px(27, 32, C(0x8A3458))

    swirl(front: false)
    swirl(front: true)
}

// MARK: - Billie

/// Billie's hourglass, rotated `turn` radians about its neck at (cx, cy) (pixel centres): a brass frame top and
/// bottom, two glass bulbs, `upper` and `lower` grains of sand (of 13 each) and the thread falling between them.
private func hv5Hourglass(_ c: PixelCanvas, cx: Double, cy: Double, turn: Double, upper: Int, lower: Int,
                          falling: Bool) {
    let brass = C(0xD0A848), brassD = C(0x8A6A2A), glass = C(0xB8CCDA), glassL = C(0xEAF4FA)
    let sand = C(0xE4BE6C), sandD = C(0xB8903C)
    var grid = [[Px?]](repeating: [Px?](repeating: nil, count: 7), count: 9)
    for x in 0..<7 { grid[0][x] = x < 3 ? brass : brassD; grid[8][x] = x < 3 ? brass : brassD }
    for r in [1, 2, 6, 7] { for x in 1...5 { grid[r][x] = glass } }
    for r in [3, 5] { for x in 2...4 { grid[r][x] = glass } }
    grid[4][3] = glass
    for r in 1...7 where grid[r][1] != nil { grid[r][1] = glassL }
    if grid[3][2] != nil { grid[3][2] = glassL }; grid[5][2] = glassL
    // The sand: the upper bulb holds its grains down at the neck, the lower one fills from the bottom.
    let up: [(Int, Int)] = [(3, 2), (3, 3), (3, 4)] + (1...5).map { (2, $0) } + (1...5).map { (1, $0) }
    let low: [(Int, Int)] = (1...5).map { (7, $0) } + (1...5).map { (6, $0) } + [(5, 2), (5, 3), (5, 4)]
    for (i, cell) in up.enumerated() where i < upper { grid[cell.0][cell.1] = i % 4 == 3 ? sandD : sand }
    for (i, cell) in low.enumerated() where i < lower { grid[cell.0][cell.1] = i % 4 == 2 ? sandD : sand }
    if falling { grid[4][3] = sand; if lower < 13 { grid[5][3] = sand } }
    let co = cos(turn), si = sin(turn)
    for y in Int(cy - 7)...Int(cy + 7) {
        for x in Int(cx - 7)...Int(cx + 7) {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let u = dx * co + dy * si, v = -dx * si + dy * co
            let col = Int(floor(u + 3.5)), row = Int(floor(v + 4.5))
            guard row >= 0, row < 9, col >= 0, col < 7, let px = grid[row][col] else { continue }
            c.px(x, y, px)
        }
    }
}

/// Death's scythe in Billie's hand along `angle`: the black shaft from `butt` pixels behind the fist to 14 ahead, and
/// the steel blade out at right angles from its head, curving back, lit along its inner edge. `trail`: the smear of a
/// fast swing.
private func hv5Scythe(_ c: PixelCanvas, hand h: (x: Double, y: Double), angle a: Double, butt: Double,
                       trail: [Double] = [], fist: Bool = true, back: Bool = false) {
    let w = back ? -1.0 : 1.0
    let shaft = C(0x2A2420), shaftL = C(0x54463A), steel = C(0xC4C8D0), steelD = C(0x7E848E), edge = C(0xF4F6FA)
    if !trail.isEmpty { huntSmear(c, h, trail, from: 10, to: 17, C(0xF0F4FF)) }
    huntBar(c, h, a, from: -butt, to: 14, shaft, r: 0.9)
    let lit = huntReach(h, a, 6), lit2 = huntReach(h, a, 11)
    c.px(Int(lit.x.rounded()), Int(lit.y.rounded()), shaftL); c.px(Int(lit2.x.rounded()), Int(lit2.y.rounded()), shaftL)
    let tip = huntReach(h, a, 14)
    let p1 = huntReach(tip, a + 90 * w, 4), p2 = huntReach(p1, a + 128 * w, 3.5), p3 = huntReach(p2, a + 165 * w, 2.5)
    huntLine(c, tip.x, tip.y, p1.x, p1.y, steelD, 1.0)
    huntLine(c, p1.x, p1.y, p2.x, p2.y, steel, 0.8)
    huntLine(c, p2.x, p2.y, p3.x, p3.y, steel, 0.6)
    let e0 = huntReach(tip, a + 180, 0.9), e1 = huntReach(p1, a + 180 + 20 * w, 0.8)
    huntLine(c, e0.x, e0.y, e1.x, e1.y, edge, 0.4)
    let e2 = huntReach(p2, a + 128 * w + 180, 0.4)
    huntLine(c, e1.x, e1.y, e2.x, e2.y, edge, 0.4)
    let ferrule = huntReach(h, a, 13)
    c.px(Int(ferrule.x.rounded()), Int(ferrule.y.rounded()), C(0xA8ACB4))
    if fist { c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange) }
}

/// Billie, the reaper who became Death: very short dark natural hair, a long black leather coat to the knees with a
/// wide collar and a sheen on the leather, open over a charcoal jumper, dark trousers and boots, berry lips. She
/// carries Death's scythe, planted beside her when she isn't swinging it. Signature: she takes the scythe in her
/// other hand, holds up an hourglass and turns it over, and watches the sand run down.
private func drawBillie(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1E1E24), coatD = C(0x0A0A0E), coatL = C(0x46464E), sheen = C(0x6A6A76)
    let jumper = C(0x3C3A42), jumperL = C(0x55525C)
    let hair = C(0x1A1410), hairL = C(0x3C2E24)
    let s = p.signature ?? -1
    let sig = s > 0.04 && s < 0.96
    let raise = sig ? Int((min(hv5Ramp(s, 0.04, 0.12), 1 - hv5Ramp(s, 0.88, 0.96)) * 4).rounded()) : p.armRaise

    // While she holds the hourglass, the scythe stands in her far hand, behind her, its blade turned back.
    if sig && p.melee == nil {
        c.oy += p.breathe
        hv5Scythe(c, hand: (14.5, 34.5), angle: -90, butt: 9, fist: false, back: true)
        c.oy -= p.breathe
    }

    drawLegs(c, Look(leg: C(0x24242C)), step: p.step)
    drawBoots(c, C(0x0C0C0E), step: p.step, rows: 2)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 42, C(0x3A3A44)) } }

    c.oy += p.breathe
    // The coat's skirts to the knees, the leather lit down the near side and in each fold, split at the front.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 22, 1, coatD)
        c.rect(17, 38, 1, 3, coatL); c.rect(38, 38, 1, 3, coatD)
        for x in [20, 32] { c.rect(x, 38, 1, 2, sheen) }
        for x in [24, 35] { c.rect(x, 38, 1, 2, coatD) }
        c.rect(28, 38, 1, 3, C(0x050507))
    }
    drawBody(c, Look(arm: coat), armRight: raise)

    // The coat over the jumper: a wide collar lit along its top, the open front, the leather's sheen in strokes, a
    // pocket, the far side in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, jumper); c.rect(25, 33, 6, 1, jumperL); for x in [26, 28, 30] { c.rect(x, 35, 1, 2, jumperL) }
    c.rect(24, 33, 1, 5, coatL); c.rect(31, 33, 1, 5, coatD)
    c.rect(20, 33, 4, 1, sheen); c.rect(32, 33, 4, 1, coatL); c.px(23, 34, coatL); c.px(32, 34, coatL)
    c.rect(19, 34, 1, 3, sheen); c.rect(20, 36, 3, 1, coatD); c.rect(34, 35, 1, 2, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD); c.rect(38, 35 - raise, 3, 1, coatD)

    // Close-cropped natural hair, a little rounded on top, its curl in short strokes.
    c.pattern(18, 22, [
        "....HHHHHHHHHHHH....",
        "..HHlHHlHHHlHHlHHH..",
        ".HHHHlHHHlHHHHlHHHH.",
        "HHlHHHHHHHHHHHHHHlHH",
        "HHHHHHHHHHHHHHHHHHHH",
        "HH................HH",
        "H..................H",
    ], ["H": hair, "l": hairL])
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)
    c.rect(27, 32, 2, 1, C(0x7A3040))

    if let a = p.melee {
        hv5Scythe(c, hand: huntHand, angle: a, butt: 5, trail: p.trail)
        return
    }
    guard sig else {
        hv5Scythe(c, hand: huntHand, angle: -90, butt: seatedPose ? 5 : 9)
        return
    }
    // The hourglass, held up by its frame: turned over, then the sand running down from the top.
    let turn = hv5Ramp(s, 0.14, 0.34)
    let flow = hv5Ramp(s, 0.36, 0.9)
    let hy = 33 - raise
    if turn < 1 {
        let k = turn * turn * (3 - 2 * turn)
        hv5Hourglass(c, cx: 44.5, cy: Double(hy) - 4.5, turn: k * .pi, upper: 0, lower: 13, falling: false)
    } else {
        let up = Int((13 * (1 - flow)).rounded())
        hv5Hourglass(c, cx: 44.5, cy: Double(hy) - 4.5, turn: 0, upper: up, lower: 13 - up, falling: up > 0)
    }
    c.rect(40, hy, 3, 2, clawdOrange); c.px(42, hy + 1, clawdShade)   // her fingers under its base
}
