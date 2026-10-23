import Foundation

// Heroes: the last of the allies, and Miracle. Becky the superfan, the FBI agent who chased the brothers, the
// British Man of Letters who came over to their side, the reaper who was kind to them, and Balthaclawds, the angel
// who'd rather be drinking. Clawd in costume like the rest, hair and clothes over the blocky body, his own orange
// face showing. Miracle is Dean's dog, the one exception: drawn as a dog, a shaggy mutt on the ground row, since he's
// a pet who tags along as an agent and never takes the lead.

let huntHeroes6: [HuntHero: Persona] = [
    .beckyRosen: Persona(name: "Becky Rosen", headTop: 20, signature: 3.2, callout: "Sam!", draw: drawBeckyRosen),
    .victorHenriksen: Persona(name: "Victor Henriksen", weapon: .blaster, shot: .bullet, muzzle: (49, 31), headTop: 23,
                              signature: 3.0, draw: drawVictorHenriksen),
    .mickDavies: Persona(name: "Mick Davies", weapon: .blaster, shot: .bullet, muzzle: (53, 31), headTop: 20,
                         draw: drawMickDavies),
    .tessa: Persona(name: "Tessa", headTop: 20, signature: 3.2, draw: drawTessa),
    .balthaclawds: Persona(name: "Balthaclawds", weapon: .saber, headTop: 21, signature: 3.6, draw: drawBalthaclawds),
    .miracle: Persona(name: "Miracle", headTop: 21, signature: 3.0, draw: drawMiracle),
]

// MARK: - Shared bits

/// How far through the part of the signature between `from` and `to` (0…1), or -1 outside it.
private func h6Span(_ p: Pose, _ from: Double, _ to: Double) -> Double {
    guard let s = p.signature, s > from, s < to else { return -1 }
    return (s - from) / (to - from)
}

/// Smoothstep: 0→1 eased at both ends.
private func h6Smooth(_ x: Double) -> Double {
    let u = min(1, max(0, x))
    return u * u * (3 - 2 * u)
}

/// Up over the first `edge` of `k`, held, and down again over the last `edge`; 0 when `k` is outside 0…1.
private func h6Ease(_ k: Double, edge: Double) -> Double {
    guard k >= 0, k <= 1 else { return 0 }
    return h6Smooth(min(1, k / edge, (1 - k) / edge))
}

/// Suit trousers: the far side of each leg a shade darker, so they read as cloth and not as four flat sticks.
private func h6Trousers(_ c: PixelCanvas, _ p: Pose, _ shade: Px, rows: Int = 4) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
        c.rect(lx + 1, top, 1, rows, shade)
    }
}

// MARK: - Becky Rosen

/// Becky Rosen: the superfan who runs the Supernatural fan site, with honey-brown hair to her shoulders held back by a
/// pink headband, big plum-pink glasses, a rose-pink cardigan buttoned over a cream blouse with a round collar, a
/// plum skirt, dark tights and little Mary Janes. She always has one of Carver Edlund's books with her. Signature: she
/// clutches the book to her chest and squeezes it, eyes shut, hearts floating up.
private func drawBeckyRosen(_ c: PixelCanvas, _ p: Pose) {
    let cardi = C(0xD8708E), cardiD = C(0xA84E6A), cardiL = C(0xF29AB2)
    let blouse = C(0xF6EEDC), blouseD = C(0xD8CCB4), skirt = C(0x6A3462), skirtD = C(0x4A2244), skirtL = C(0x8A4E80)
    let hair = C(0xB88A4E), hairD = C(0x8A6232), hairL = C(0xDAB070), band = C(0xF0589C), bandL = C(0xFFA6CC)
    let frame = C(0x8A2E6E), frameL = C(0xC458A0)
    let k = h6Span(p, 0.04, 0.96)
    let hug = h6Ease(k, edge: 0.14)              // 0 at her side, 1 clutched to her chest
    let hugging = hug > 0.5
    let squeeze = hugging && k > 0.2 && k < 0.82 && Int(k * 14) % 3 == 0 ? 1 : 0

    // Dark plum tights and maroon Mary Janes with a strap.
    drawLegs(c, Look(leg: C(0x3E3448)), step: p.step)
    h6Trousers(c, p, C(0x2E2638), rows: 3)
    drawBoots(c, C(0x7A2440), step: p.step, rows: 1)

    c.oy += p.breathe
    // The skirt over the tops of her legs: pleats lit on the near side, the hem a shade darker.
    if seatedPose {
        c.rect(17, 38, 22, 1, skirt)
    } else {
        c.rect(17, 38, 22, 2, skirt); c.rect(17, 40, 22, 1, skirtD)
        for x in [20, 24, 28, 32] { c.rect(x, 38, 1, 2, skirtL) }
        for x in [22, 26, 30, 34] { c.rect(x, 38, 1, 3, skirtD) }
        c.rect(38, 38, 1, 3, skirtD)
    }
    if hugging {
        // No arms out at her sides while she hugs it: they're wrapped round the book.
        c.rect(18, 26, 20, 12, clawdOrange); c.rect(18, 37, 20, 1, clawdShade); c.rect(37, 26, 1, 12, clawdShade)
    } else {
        drawBody(c, Look(arm: cardi), armRight: hug > 0 ? 2 : 0)
    }

    // The cardigan: buttoned at the waist, open at the neck on the blouse's round collar, buttons on the near edge,
    // the ribbed hem in shade with its stripes.
    c.rect(18, 33, 20, 5, cardi)
    c.rect(25, 33, 6, 3, blouse); c.rect(26, 36, 4, 1, blouse); c.rect(30, 33, 1, 3, blouseD)
    c.px(25, 33, C(0xFFFFFF)); c.px(26, 34, blouseD); c.px(30, 33, C(0xFFFFFF)); c.px(29, 34, blouseD)
    c.rect(24, 33, 1, 4, cardiL); c.rect(31, 33, 1, 4, cardiD)
    c.px(25, 36, cardiL); c.px(30, 36, cardiD)
    c.rect(19, 33, 4, 1, cardiL); c.rect(33, 33, 3, 1, cardiL)
    c.px(24, 34, C(0xFFF2F6)); c.px(24, 36, C(0xFFF2F6))
    c.rect(18, 37, 20, 1, cardiD); for x in stride(from: 19, to: 37, by: 2) { c.px(x, 37, cardi) }
    c.rect(37, 33, 1, 4, cardiD); c.rect(18, 34, 1, 3, cardiL)
    if !hugging { c.rect(15, 35, 3, 1, cardiD) }

    // Hair to her shoulders, parted and held back by the headband, flicking out at the ends.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHlllllllHHHHHH....",
        "...BbbBBBBBBBBBBBBBBBB..",
        "..HHlllHHHHHHlllllHHHH..",
        ".HHHHHHHHHHHHHHHHHHHHHH.",
        ".HHHHhhhHHHHHHHHhhhhHHH.",
        ".HHHHH..........HHHHHHH.",
        ".HHHd............HHHdHH.",
        "HHHd..............dHdHH.",
        ".HHd...............dHHH.",
        "HHld...............dlHH.",
        ".Hld...............dlHH.",
        "HHld...............dlHH.",
        ".HHH................HHH.",
        "HHd..................dHH",
        ".d....................d.",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD, "B": band, "b": bandL])

    // The glasses: big plum-pink rims all the way round each eye, joined over the nose, a glint on the near rim.
    for x in [21, 31] {
        c.rect(x, 28, 4, 1, frame); c.rect(x, 32, 4, 1, frame)
        c.rect(x, 29, 1, 3, frame); c.rect(x + 3, 29, 1, 3, frame)
    }
    c.rect(25, 29, 6, 1, frame); c.px(21, 28, frameL); c.px(22, 28, frameL)
    if hugging {
        // Eyes shut tight with happiness behind the lenses.
        c.rect(22, 29, 2, 3, clawdOrange); c.rect(32, 29, 2, 3, clawdOrange)
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
        c.px(22, 29, clawdShade); c.px(33, 29, clawdShade)
    }

    // The book: a dark paperback, its title band in gold, a little red flame of a cover picture, the pages' cream edge.
    func book(_ x: Int, _ y: Int) {
        let cover = C(0x2A3048), coverD = C(0x1A1E30), title = C(0xE0A840), pages = C(0xF2E8D0)
        c.rect(x, y, 6, 8, cover); c.rect(x, y, 1, 8, coverD)
        c.rect(x + 1, y + 1, 4, 1, title); c.rect(x + 2, y + 3, 2, 2, C(0xC8402A)); c.px(x + 3, y + 3, C(0xF07A3A))
        c.rect(x + 1, y + 6, 3, 1, title.alpha(1)); c.px(x + 5, y + 7, coverD)
        c.rect(x + 5, y + 1, 1, 6, pages)
    }
    if hugging {
        // Clutched to her chest, both arms wrapped round it, squeezed now and then.
        book(25, 30 - squeeze)
        c.rect(18, 35, 8, 2, cardi); c.rect(18, 36, 8, 1, cardiD); c.rect(26, 35, 2, 2, clawdOrange)
        c.rect(32, 34, 6, 2, cardi); c.rect(32, 35, 6, 1, cardiD); c.rect(30, 34, 2, 2, clawdOrange)
        c.px(31, 35, clawdShade)
        // Hearts drifting up out of the hug.
        for i in 0..<3 {
            let f = (k * 2.2 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            guard k > 0.16, k < 0.84 else { continue }
            let hx = 39 + i * 4 + Int(sin(f * 6 + Double(i)) * 1.5), hy = 24 - Int(f * 16)
            c.pattern(hx, hy, ["HH.HH", "HHHHH", ".HHH.", "..H.."], ["H": i == 1 ? C(0xF0507A) : C(0xFF7AA6)])
        }
    } else if hug > 0 {
        book(37, 28)   // on its way up
        c.rect(38, 31, 3, 3, clawdOrange)
    } else {
        // Held at her side, her hand round the spine.
        book(39, 29)
        c.rect(38, 33, 3, 3, clawdOrange); c.px(40, 35, clawdShade)
    }
}

// MARK: - Victor Henriksen

/// Victor Henriksen: the FBI agent who hunted the Winchesters across the country, his head shaved to a dark buzz, in a
/// sharp charcoal suit, a pale blue shirt and a navy tie striped in gold, black shoes polished bright. Fights with his
/// black Glock. Signature: he whips out his badge wallet and holds it up, flipped open on the gold shield and his ID
/// card, FBI in big blue letters.
private func drawVictorHenriksen(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x34363F), suitD = C(0x202229), suitL = C(0x50545F)
    let shirt = C(0xC4D6EE), shirtD = C(0x98AACA), tie = C(0x22346A), stripe = C(0xC8A848)
    let buzz = C(0x221C1A), buzzL = C(0x443A34)
    let k = h6Span(p, 0.04, 0.96)
    let up = h6Ease(k, edge: 0.16)
    let raise = Int((up * 7).rounded())
    let open = k < 0 ? 0 : min(1, max(0, (k - 0.16) / 0.1), max(0, (0.86 - k) / 0.1))

    drawLegs(c, Look(leg: C(0x30323A)), step: p.step)
    h6Trousers(c, p, C(0x24262C))
    drawBoots(c, C(0x0E0E10), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where !(p.step >= 0 && i % 2 == p.step) { c.px(lx, 43, C(0x4A4A52)) }
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: raise)

    // The suit jacket: notched lapels lit on the near side, the pale blue shirt and the striped tie, a pocket square
    // line, two buttons done up, the far side and the hem in shade, a white cuff showing at his wrist.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 4, shirt); c.rect(30, 33, 1, 4, shirtD)
    c.rect(27, 33, 2, 1, C(0x18244A)); c.rect(27, 34, 2, 3, tie)
    c.px(27, 34, stripe); c.px(28, 35, stripe); c.px(27, 36, stripe)
    c.rect(24, 33, 1, 4, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 4, suitD); c.px(32, 34, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL)
    c.rect(33, 35, 3, 1, suitD); c.px(28, 37, C(0x16161A)); c.px(26, 37, C(0x16161A))
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.rect(18, 34, 1, 3, suitL)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 34, C(0xEEF0F4))

    // The buzz cut: hair shaved right down, a dark stubble close over the top of his head, flecked with light.
    c.pattern(17, 23, [
        "....hHhHhHhHhHhh....",
        "..hHHlHHHlHHHlHHHh..",
        ".HHHHHHHHHHHHHHHHHHH",
        ".Hh...............H.",
    ], ["H": buzz, "h": C(0x141010), "l": buzzL])
    c.rect(22, 28, 2, 1, buzz); c.rect(32, 28, 2, 1, buzz)   // straight, serious brows

    if raise > 0 || open > 0 {
        // The badge wallet held up in his fist, flipped open: the top flap black leather with the gold shield, the
        // bottom his white ID card with FBI across it in blue.
        let hy = 33 - raise
        let leather = C(0x1A1A1E), leatherL = C(0x3A3A40), gold = C(0xE6BC48), goldD = C(0xA07E24), goldL = C(0xFFE88A)
        let wx = 40, wy = hy - 8
        c.rect(wx, wy + 1, 12, 8, leather); c.rect(wx, wy + 1, 12, 1, leatherL)
        if open > 0.5 {
            c.rect(wx, wy - 6, 12, 7, leather); c.rect(wx, wy - 6, 12, 1, leatherL); c.rect(wx, wy, 12, 1, C(0x0A0A0C))
            c.pattern(wx + 3, wy - 5, ["GLLGG", "GGGGG", "GgGgG", ".GGG.", "..G.."], ["G": gold, "g": goldD, "L": goldL])
            c.rect(wx + 1, wy + 2, 10, 6, C(0xF4F4F0))
            let blue = C(0x2A50B0)
            c.pattern(wx + 1, wy + 2, [
                "FFF.BB..III",
                "F...B.B..I.",
                "FF..BB...I.",
                "F...B.B..I.",
                "F...BB..III",
            ], ["F": blue, "B": blue, "I": blue])
            c.rect(wx + 1, wy + 7, 10, 1, C(0xC8CCD4))
        }
        c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 2, clawdShade)
        return   // the Glock back in its holster while he shows his badge
    }

    // The Glock: a squared-off black slide lit along its top, the frame and trigger guard, the grip in his fist. It
    // kicks up `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..LLLLLLLLLl",
        "..KKKKKKKKKK",
        "OOOGk.k.....",
        "OOOG........",
        ".OG.........",
    ], ["L": C(0x5A5E68), "l": C(0x3A3C44), "K": C(0x26282E), "k": C(0x18181C), "G": C(0x1E1E22), "O": clawdOrange])
}

// MARK: - Mick Davies

/// Mick Davies: the young British Man of Letters, polite to a fault, in a tidy slate-blue three-piece suit with the
/// waistcoat buttoned under it, a white shirt and a slim navy tie, a white pocket square folded to a point, brown
/// Oxford shoes, and his brown hair neatly side-parted with a lift at the front. Fights with a silenced pistol, the
/// way the British Men of Letters work: quietly.
private func drawMickDavies(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x5A6882), suitD = C(0x3E4A60), suitL = C(0x7C8AA4), vest = C(0x4A566E)
    let shirt = C(0xF4F4F0), tie = C(0x1C2844)
    let hair = C(0x6A4A30), hairD = C(0x4A3220), hairL = C(0x8E6C4A)

    drawLegs(c, Look(leg: C(0x56647E)), step: p.step)
    h6Trousers(c, p, C(0x44506A))
    drawBoots(c, C(0x6A4226), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where !(p.step >= 0 && i % 2 == p.step) { c.px(lx, 43, C(0x8C5E36)) }
    }

    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: 0)

    // The jacket open on the waistcoat: its V of shirt and the slim tie, the waistcoat's buttons, the pocket square,
    // lapels lit on the near side, the far side and the hem in shade, a white cuff.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 5, vest); c.rect(30, 33, 1, 5, C(0x3A4458))
    c.rect(26, 33, 4, 1, shirt); c.rect(27, 34, 2, 1, shirt)
    c.px(27, 33, tie); c.px(28, 33, tie); c.px(28, 34, tie); c.px(28, 35, tie)
    c.px(27, 35, C(0xB8BEC8)); c.px(27, 37, C(0xB8BEC8)); c.px(27, 36, vest)
    c.rect(24, 33, 1, 5, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 5, suitD); c.px(32, 34, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL)
    c.pattern(20, 34, ["W.W", "WWW"], ["W": white])
    c.rect(20, 36, 3, 1, suitD); c.rect(33, 36, 3, 1, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.rect(18, 34, 1, 3, suitL)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 34, shirt)

    // Neatly combed hair: a clean side parting, the front lifted in a small quiff, short at the back and sides.
    c.pattern(17, 20, [
        "...........HHHHH......",
        "........HHHHlllHH.....",
        "....HHHHHHHHHHHHHHH...",
        "..HHlllllHHHHlllHHHH..",
        ".HHHHHHHhHHHHHHHHHHHH.",
        ".HHHHHHHHhHHHHHHHHHHH.",
        ".HHh..............hHH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The pistol: a black slide with a long grey silencer screwed on the end, the grip in his fist. It kicks up
    // `p.gunY` with each shot.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..SSSSSSSMMMMMm",
        "..KKKKKKKmmmmmm",
        "OOOGk.k........",
        "OOOG...........",
        ".OG............",
    ], ["S": C(0x4A4C54), "K": C(0x26282E), "k": C(0x18181C), "G": C(0x2A2420), "M": C(0x8A8E98),
        "m": C(0x5E626C), "O": clawdOrange])
}

// MARK: - Tessa

/// Tessa: the reaper, gentle with the dying, long straight dark hair parted in the middle and falling past her
/// shoulders, a long black coat to the knees with its collar turned up, double-breasted with pewter buttons, over a
/// dark grey top; black trousers and boots. No scythe: she just guides people on. Signature: she holds out her hand,
/// softly, palm up, and a pale light gathers in it.
private func drawTessa(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x302D36), coatD = C(0x1A181E), coatL = C(0x55505E), top = C(0x4A4652), pewter = C(0x9A98A4)
    let hair = C(0x33231C), hairD = C(0x1C120E), hairL = C(0x5A4234)
    let k = h6Span(p, 0.04, 0.96)
    let reach = h6Ease(k, edge: 0.2)
    let out = Int((reach * 4).rounded())

    drawLegs(c, Look(leg: C(0x2E2C34)), step: p.step)
    drawBoots(c, C(0x121014), step: p.step, rows: 2)

    c.oy += p.breathe
    // The coat's skirts to the knees, split at the front, a fold over each leg, the hem a shade darker.
    if seatedPose {
        c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL)
    } else {
        c.rect(17, 38, 22, 2, coat); c.rect(17, 40, 22, 1, coatD)
        c.px(17, 38, coatL); c.px(17, 39, coatL); c.rect(38, 38, 1, 3, coatD)
        for x in [22, 26, 34] { c.rect(x, 38, 1, 2, coatL) }
        c.rect(29, 38, 1, 3, coatD)
    }
    drawBody(c, Look(arm: coat), armRight: out > 0 ? 1 : 0)
    if reach > 0.5 {
        // Her eyes soften, the lids half down.
        c.rect(22, 29, 2, 1, clawdShade); c.rect(32, 29, 2, 1, clawdShade)
    }

    // The coat over the body: the turned-up collar either side of her neck, lit on the near side, the grey top in
    // the opening, two rows of pewter buttons, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(25, 33, 6, 5, top); c.rect(30, 33, 1, 5, C(0x36323C)); c.rect(26, 33, 4, 1, clawdOrange)
    c.rect(23, 32, 2, 3, coatL); c.rect(31, 32, 2, 3, coatD); c.px(22, 33, coatL); c.px(33, 33, coatD)
    c.px(24, 35, coatL); c.rect(24, 36, 1, 2, coat)
    c.px(23, 36, pewter); c.px(32, 36, pewter); c.px(23, 35, C(0x6A6874)); c.px(32, 35, C(0x6A6874))
    c.rect(19, 33, 3, 1, coatL); c.rect(34, 33, 2, 1, coatL); c.rect(18, 34, 1, 3, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(15, 35, 3, 1, coatD)

    // Long straight hair, parted in the middle, falling past her shoulders in long lit strands.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHlllHlllHHHHH....",
        "...HHlllHHHhHHHlllHHH...",
        "..HHHHHHHHhhHHHHHHHHHH..",
        "..HHHHHHHhhhhHHHHHHHHH..",
        ".HHHHHHhhHHHHhhHHHHHHH..",
        ".HHHHh..........hHHHHH..",
        ".HHHh............hHHHH..",
        ".HHl..............hlHH..",
        "HHHl...............lHHH.",
        "HHHl...............lHH..",
        "HHlH...............HlH..",
        "HHlH...............HlH..",
        "HHlH...............HlH..",
        "HHlHd..............HlH..",
        "HHHd...............HHd..",
        ".Hd................dH...",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if out > 0 {
        // The arm held out in its black sleeve, the hand open, palm up; a soft pale light gathers over the palm, and
        // a few motes drift up from it.
        c.rect(38, 32, 2 + out, 3, coat); c.rect(38, 32, 2 + out, 1, coatL); c.rect(38, 34, 2 + out, 1, coatD)
        let hx = 40 + out
        c.rect(hx, 33, 3, 2, clawdOrange); c.px(hx + 2, 32, clawdOrange); c.px(hx, 34, clawdShade)
        if reach > 0.6 {
            // A little orb of light floating a pixel clear of the palm, solid at its heart, a faint halo round it.
            let glow = C(0xDCE6FF), g = (reach - 0.6) / 0.4
            let oy = 29 + (Int(p.t * 2) % 2)
            for (dx, dy, a) in [(-1, 0, 0.2), (1, 0, 0.2), (0, -1, 0.2), (0, 1, 0.16), (-1, -1, 0.1), (1, -1, 0.1),
                                (-1, 1, 0.08), (1, 1, 0.08), (0, -2, 0.08)] {
                c.px(hx + 1 + dx, oy + dy, glow.alpha(a * g))
            }
            if g > 0.5 { c.px(hx + 1, oy, C(0xF4F8FF)) }
            for i in 0..<3 {
                let f = (p.t * 0.7 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                c.px(hx + 1 + Int(sin(f * 5 + Double(i) * 2) * 1.6), 30 - Int(f * 9), white.alpha(0.6 * (1 - f) * g))
            }
        }
    }
}

// MARK: - Balthaclawds

/// Balthaclawds: the angel who faked his death to enjoy the finer things, smug and pleased with himself, his dark hair
/// combed back and gone silver at the temples, a plum velvet blazer over a charcoal tee with a deep V-neck, a thin
/// silver chain at his throat, dark trousers and polished black shoes. One eyebrow up, eyes half-lidded, a smirk, and
/// always a glass of red wine in his hand. Fights with his angel blade. Signature: he sips his wine while his wings'
/// shadow spreads across the wall behind him.
private func drawBalthaclawds(_ c: PixelCanvas, _ p: Pose) {
    let blazer = C(0x4A2C4C), blazerD = C(0x2E1A30), blazerL = C(0x6E4A70)
    let tee = C(0x3A3A40), teeD = C(0x26262C), chain = C(0xD0D4DC)
    let hair = C(0x2A2224), hairD = C(0x161214), hairL = C(0x4A3E42), grey = C(0x9A989C)
    let s = p.signature ?? -1
    let wings = s > 0.04 && s < 0.96 ? sin((s - 0.04) / 0.92 * .pi) : 0
    let sip = h6Span(p, 0.28, 0.72)
    let lift = h6Ease(sip, edge: 0.3)
    let sipping = lift > 0.8

    huntWingShadows(c, min(1, wings * 1.3), tint: C(0x0A060E), strength: 0.42)

    drawLegs(c, Look(leg: C(0x2E2A32)), step: p.step)
    h6Trousers(c, p, C(0x221E26))
    drawBoots(c, C(0x101012), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where !(p.step >= 0 && i % 2 == p.step) { c.px(lx + 1, 43, C(0x50505A)) }
    }

    c.oy += p.breathe
    let raise = Int((lift * 5).rounded())
    drawBody(c, Look(arm: blazer, eye: nil), armRight: p.melee == nil ? raise : p.armRaise)

    // The velvet blazer, open: the tee's deep V showing his chest with the chain round it, wide lapels with a soft
    // sheen on the near side, a pocket each side, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, blazer)
    c.rect(24, 33, 8, 5, tee); c.rect(31, 33, 1, 5, teeD)
    c.pattern(25, 33, ["OOOOOO", ".OOOO.", "..OO..", "..OO."], ["O": clawdOrange])
    c.px(25, 33, chain); c.px(30, 33, chain); c.px(26, 34, chain); c.px(29, 34, chain); c.px(27, 35, chain)
    c.px(28, 35, chain)
    c.rect(23, 33, 1, 5, blazerL); c.px(22, 34, blazerL); c.px(24, 33, blazerL); c.rect(32, 33, 1, 5, blazerD)
    c.px(33, 34, blazerD)
    c.rect(19, 33, 3, 1, blazerL); c.rect(34, 33, 2, 1, blazerL)
    c.rect(19, 36, 3, 1, blazerD); c.rect(33, 36, 3, 1, blazerD)
    c.rect(37, 33, 1, 5, blazerD); c.rect(18, 37, 20, 1, blazerD); c.rect(18, 34, 1, 3, blazerL)
    c.rect(15, 35, 3, 1, blazerD)

    // Dark hair combed straight back off a widow's peak, cut short at the sides, silver over the ears.
    c.pattern(17, 21, [
        "........HHHHHHH.......",
        ".....HHHlllllHHHHH....",
        "...HHHHHHHHHHHHHHHHH..",
        "..HlllHHHHlllllHHHHHH.",
        ".HHHHHHHHHHHhHHHHHHHH.",
        ".gHHHh....hHh...hHHHg.",
        ".gg................gg.",
        ".g..................g.",
    ], ["H": hair, "h": hairD, "l": hairL, "g": grey])

    // The smug face: one brow cocked high, the eyes half-lidded, a sideways smirk.
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 27, 2, 1, hairD); c.px(34, 28, hairD)
    c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)
    c.rect(22, 29, 2, 1, clawdShade); c.rect(32, 29, 2, 1, clawdShade)
    c.rect(27, 32, 2, 1, C(0x8A3A2E)); c.px(29, 31, C(0x8A3A2E))

    // The angel blade, drawn when he fights: the long silver spike, three-sided, with a bright edge.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x8A8E96), steel: C(0xB4BAC4), edge: C(0xF4F6FA), length: 10)
        return
    }

    // The wine glass: a clear bowl of red wine on its stem, held by the stem; tipped to his lips for the sip.
    let glass = C(0xD8E2EA), wine = C(0x7A1230), wineL = C(0xB0304A)
    let hy = 33 - raise
    if sipping {
        // Tipped towards him, the wine running to the rim at his lips, the stem pointing up and out.
        c.pattern(37, hy - 5, [
            "gR....",
            "gRRg..",
            ".gRrg.",
            "..ggg.",
            "...s..",
        ], ["g": glass, "R": wine, "r": wineL, "s": glass])
    } else {
        c.pattern(38, hy - 5, ["g...g", "gRRRg", "gRrRg", ".gRg.", "..g.."], ["g": glass, "R": wine, "r": wineL])
        if lift == 0 { c.px(38, hy - 4, white) }
    }
    c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 2, clawdShade)
}

// MARK: - Miracle

/// Miracle: the shaggy stray Dean took in at the end of the world, a big scruffy mutt with wiry wheaten fur, darker
/// streaks through it, a whiskery beard on his muzzle, floppy ears and a brown leather collar with its tag. Not Clawd
/// in costume: a dog, on four legs on the ground row, his tail always going. He lies down when the session is idle.
/// Signature: he wags harder and harder, then spins round and round chasing his tail, and stops, tongue out.
private func drawMiracle(_ c: PixelCanvas, _ p: Pose) {
    let k = h6Span(p, 0.02, 0.98)
    let chase = k > 0.2 && k < 0.84 ? (k - 0.2) / 0.64 : -1
    let turn = chase >= 0 ? Int(chase * 8) : 0
    let flip = chase >= 0 && turn % 2 == 1
    let happy = k >= 0 || p.cheering || p.ready
    let pant = k > 0.84 || p.cheering

    // Drawn on its own canvas so the whole dog can be turned round mid-spin.
    let d = PixelCanvas(c.w, c.h)
    h6Dog(d, p, wagSpeed: k >= 0 ? (k < 0.2 ? 16 : 22) : happy ? 11 : 5, pant: pant,
          hop: chase >= 0 && Int(chase * 16) % 2 == 1 ? -1 : 0)
    if flip { d.mirror(aboutX: 29) }
    c.paste(d)

    // A little dust kicked up off the floor while he spins: faint, so it gets no outline.
    if chase >= 0 && !seatedPose {
        for i in 0..<5 {
            let f = (p.t * 2.4 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
            let x = 18 + Int(noise(i * 7 + Int(p.t * 2.4)) * 24), y = 43 - Int(f * 3)
            c.px(x, y, C(0xB8AE98).alpha(0.22 * (1 - f)))
        }
    }
}

/// The dog itself, facing right: the shaggy body, four legs, the tail, the bearded head.
private func h6Dog(_ c: PixelCanvas, _ p: Pose, wagSpeed: Double, pant: Bool, hop: Int) {
    let fur = C(0xC8B08A), furD = C(0x9A8264), furL = C(0xE6D4B0), streak = C(0x7A6A58), belly = C(0xD8C8A8)
    let nose = C(0x1A1416), collar = C(0x7A4A26), tag = C(0xE6C050)
    let lying = seatedPose
    c.oy += hop

    // Legs, wiry fur down the back of each, the paws a shade paler; folded flat in front of him when he lies down.
    if lying {
        c.rect(19, 38, 7, 2, fur); c.rect(19, 39, 7, 1, furD)
        c.rect(36, 39, 9, 2, fur); c.rect(36, 40, 9, 1, furD); c.px(44, 39, belly); c.px(44, 40, belly)
    } else {
        for (i, lx) in [20, 24, 33, 37].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            let foot = lifted ? 42 : 43
            c.rect(lx, 38, 2, foot - 38, i == 1 || i == 3 ? fur : furD)
            c.px(lx - 1, 39, i == 1 || i == 3 ? furD : streak)
            c.rect(lx, foot, 3, 1, belly); c.px(lx + 2, foot, furD)
        }
    }

    c.oy += p.breathe

    // The tail: a shaggy plume off his rump, wagging between two positions, faster when he's excited.
    if Int(p.t * wagSpeed) % 2 == 0 {
        c.pattern(12, 23, ["..l..", ".FFl.", ".FFF.", "..FFd", "..FFF", "...FF", "...dF", "....F"],
                  ["F": fur, "l": furL, "d": furD])
    } else {
        c.pattern(9, 26, ["l.....", "FFl...", ".FFFF.", "..dFFF", "...FFF", ".....F"], ["F": fur, "l": furL, "d": furD])
    }

    // The body: a deep shaggy barrel, the back lit along the top in ragged tufts, darker streaks through the coat,
    // the haunch and shoulder picked out, the belly fur hanging in a fringe.
    c.pattern(16, 28, [
        "..l.l..l.l..l..l..l.l.l...",
        ".lFLLFLLFLLFLLFLLFLLFLLFF.",
        "FFFFFssFFFFFFssFFFFFFFFFFF",
        "FFFFFFFFFFssFFFFFFFssFFFFF",
        "FFFssFdFFFFFFFFssFFFFFdFFF",
        "FFFFFFdFFssFFFFFFFFFFFdFFF",
        "FssFFFdFFFFFFFFFssFFFFdFFF",
        "dFFFFFdFFFFFssFFFFFFFFdFFF",
        "dddFFFFFFFFFFFFFFFFFFFFFFd",
        ".dddBBBBBBBBBBBBBBBBBBBdd.",
        "..d.B.B..B.B..B.B..B.B.d..",
    ], ["F": fur, "L": furL, "l": furL, "s": streak, "d": furD, "B": belly])

    // The head on its neck: a scruffy crown, a long floppy ear, the eye under shaggy brows, the long muzzle with its
    // wiry beard and black nose; the collar round his neck with the tag hanging.
    c.pattern(35, 21, [
        "....l.l.l.......",
        "...lFLFLFl......",
        "..FFFLLLFFF.....",
        ".EEFFFFFFFFFl...",
        "EEEFFbbFFFFFFl..",
        "EEEFFbKbFFFFFFFl",
        "EEEFFFKFFFFFFFNN",
        "EEEFFFFFFFFFFFNN",
        "EEEFFFFFFFFFFFF.",
        ".EEFFFFFFwFwFwF.",
        ".EEFFFFFFFwFwFw.",
        "..EFFFFFFwFwFw..",
        "..E.FFFFF.w.w...",
    ], ["F": fur, "L": furL, "l": furL, "E": streak, "b": furD, "K": ink, "N": nose, "w": belly])
    c.px(50, 27, C(0x5A4E50))                                   // the shine on his nose
    if pant {
        c.rect(46, 30, 2, 2, C(0xE0607A)); c.px(47, 31, C(0xB8405A))   // tongue out, panting
    }
    c.rect(37, 31, 7, 1, collar); c.px(38, 31, C(0xA06A3A)); c.px(41, 32, tag)
}
