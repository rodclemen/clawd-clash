import Foundation

// Heroes: the Ghostfacers, Frank, Benny and the psychics. Clawd in costume like every other cast, with Clawd's own
// orange face showing. Ed and Harry wear the same black Ghostfacers jacket with its little ghost logo: Ed is the one
// with gelled black spikes and the camcorder, Harry the one with a shaggy brown mop and the EMF meter. Frank and Benny
// both wear flat caps: Frank's is a tall, puffy pale grey tweed over a glare and an army jacket, Benny's a small
// dark leather one pulled low over slicked black hair and a jacket caked in Purgatory dirt. Missouri in purple and
// beads; Pamela behind her sunglasses in a cloud of dark curls.

let huntHeroes5: [HuntHero: Persona] = [
    .edZedmore: Persona(name: "Ed Zedmore", headTop: 19, signature: 3.2, callout: "Ghostfacers!", draw: drawEdZedmore),
    .harrySpangler: Persona(name: "Harry Spangler", headTop: 19, signature: 3.2, draw: drawHarrySpangler),
    .frankDevereaux: Persona(name: "Frank Devereaux", headTop: 20, signature: 3.0, draw: drawFrankDevereaux),
    .bennyLafitte: Persona(name: "Benny Lafitte", weapon: .saber, headTop: 22, signature: 3.0, draw: drawBennyLafitte),
    .missouriMosley: Persona(name: "Missouri Mosley", headTop: 21, signature: 2.8, draw: drawMissouriMosley),
    .pamelaBarnes: Persona(name: "Pamela Barnes", headTop: 18, signature: 3.6, draw: drawPamelaBarnes),
]

// MARK: - Shared bits

/// How far through the part of the signature between `from` and `to` (0…1), or -1 outside it.
private func h5Span(_ p: Pose, _ from: Double, _ to: Double) -> Double {
    guard let s = p.signature, s > from, s < to else { return -1 }
    return (s - from) / (to - from)
}

/// Smoothstep: 0→1 eased at both ends.
private func h5Smooth(_ x: Double) -> Double {
    let u = min(1, max(0, x))
    return u * u * (3 - 2 * u)
}

/// Up over the first `edge` of `k`, held, and down again over the last `edge`; 0 when `k` is outside 0…1.
private func h5Ease(_ k: Double, edge: Double) -> Double {
    guard k >= 0, k <= 1 else { return 0 }
    return h5Smooth(min(1, k / edge, (1 - k) / edge))
}

/// A lit stripe down the front of each leg (faded denim), not when sitting.
private func h5LegLight(_ c: PixelCanvas, _ p: Pose, _ col: Px) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() {
        let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
        c.rect(lx, top, 1, 3, col)
    }
}

/// The Ghostfacers' jacket, the same on Ed and Harry: black, zipped up, its ribbed collar standing round the neck, a
/// silver zip down the middle, a welt pocket, and their logo on the chest, a little white ghost with two dark eyes.
private func h5GhostfacersJacket(_ c: PixelCanvas) {
    let jacket = C(0x26262C), jacketD = C(0x141418), jacketL = C(0x44444E)
    let logo = C(0xECECE4), logoD = C(0xA4A4A0), zip = C(0xA4A8B0)
    c.rect(18, 33, 20, 5, jacket)
    c.rect(19, 33, 4, 1, jacketL); c.rect(33, 33, 3, 1, jacketL)                  // shoulders lit
    c.rect(23, 33, 10, 1, C(0x34343C)); c.px(23, 33, jacketD); c.px(32, 33, jacketD)   // the collar
    c.rect(19, 34, 1, 3, jacketL)
    c.rect(28, 34, 1, 4, zip); c.px(28, 34, C(0xE0E2E8)); c.px(27, 35, zip)           // the zip and its pull
    c.rect(20, 36, 4, 1, jacketD)                                                    // the pocket
    c.pattern(31, 34, [
        ".LLL.",
        "LkLkD",
        "LLLLD",
        "L.L.D",
    ], ["L": logo, "D": logoD, "k": jacketD])
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD); c.px(31, 37, logo); c.px(33, 37, logo)
    c.rect(15, 35, 3, 1, jacketD)
}

// MARK: - Ed Zedmore

/// Ed Zedmore: one half of the Ghostfacers, black hair gelled up into stiff spikes that lean forward, the black
/// Ghostfacers jacket zipped to the collar, dark jeans and black sneakers on white soles, and his silver camcorder
/// always in his hand. He doesn't fight. Signature: he lifts the camcorder up to his eye and points it ahead, its flip
/// screen swinging open and the red light blinking: they're recording.
private func drawEdZedmore(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x1C181C), hairL = C(0x443C44), hairD = C(0x0C0A0C)
    let cam = C(0x9A9EA6), camL = C(0xC6CAD2), camD = C(0x666A72), barrel = C(0x1E1E24), glass = C(0x6A9ACC)
    let k = h5Span(p, 0.05, 0.95)
    let up = h5Ease(k, edge: 0.16)
    let cx = 40 - Int((up * 6).rounded()), cy = 30 - Int((up * 4).rounded())

    drawLegs(c, Look(leg: C(0x30384E)), step: p.step)
    h5LegLight(c, p, C(0x48526C))
    drawBoots(c, C(0x1A1A1E), step: p.step, rows: 2)
    drawBoots(c, C(0xE2E2DE), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: C(0x26262C)), armRight: 30 - cy)
    h5GhostfacersJacket(c)

    // Black hair gelled up into stiff, uneven spikes leaning forward, lit along their left edges, cut close at the
    // sides.
    c.pattern(17, 19, [
        "......H....HH....H....",
        "...H..HH..HHH...HHH...",
        "...HH.lHH.lHHH.lHHHH..",
        "..HlHHHlHHHlHHHHlHHHH.",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HhHHHhHHHHhHHHHhHHhH.",
        ".HH................HH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The camcorder: a silver body with its carry handle on top, lit along the top edge, the black lens barrel and its
    // blue glass at the front. At rest he holds it low by its back end; for the signature it's up at his eye.
    c.pattern(cx, cy, [
        "...TTTTT...",
        "LLLLLLLLLKK",
        "BBBBBBBBBKG",
        "BBBBBBBBBKG",
        "BBBBBBBBBKG",
        "DDDDDDDDDK.",
    ], ["T": camD, "L": camL, "B": cam, "D": camD, "K": barrel, "G": glass])
    c.px(cx + 10, cy + 2, C(0xC8E4FF))                                    // a glint on the glass
    let rec = k >= 0 && Int(p.t * 3) % 2 == 0
    c.rect(cx + 8, cy, 2, 1, rec ? C(0xFF3A2A) : C(0x7A3A34))           // the tally light
    if up > 0.5 {
        // The flip screen swung open towards us, lit, a ghost blipping across it.
        c.rect(cx + 2, cy + 1, 6, 5, barrel)
        c.rect(cx + 3, cy + 2, 4, 3, C(0x8AB4DC))
        if Int(p.t * 5) % 3 != 0 { c.px(cx + 3 + Int(p.t * 4) % 4, cy + 3, C(0xF4F8FF)) }
    }
    c.rect(38, cy + 3, 3, 3, clawdOrange); c.px(40, cy + 5, clawdShade)
}

// MARK: - Harry Spangler

/// Harry Spangler: the other Ghostfacer, a shaggy mop of mid-brown hair falling over his ears and brow, the same black
/// Ghostfacers jacket, khaki cargo trousers and brown boots, and his EMF meter in hand, a grey paddle with a row of
/// lights from green to red. He doesn't fight. Signature: he waves the meter about, sweeping it up and down, and its
/// lights jump up and down the scale, hitting the red.
private func drawHarrySpangler(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x6A4A2E), hairL = C(0x8E6A44), hairD = C(0x46301C)
    let box = C(0x4A4E56), boxL = C(0x7E828C), boxD = C(0x2E3036)
    let k = h5Span(p, 0.05, 0.95)
    let on = h5Ease(k, edge: 0.12)
    let wave = k >= 0 ? Int((on * (3 + 3 * sin(k * .pi * 6))).rounded()) : 0

    drawLegs(c, Look(leg: C(0x8A7E5E)), step: p.step)
    if !seatedPose {
        for lx in [19, 23, 31, 35] { c.px(lx + 1, 39, C(0x6A604A)) }   // the cargo pockets' flaps
        for lx in [23, 35] { c.rect(lx, 39, 2, 2, C(0x7A7054)) }
    }
    drawBoots(c, C(0x5A3E26), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: C(0x26262C)), armRight: wave)
    h5GhostfacersJacket(c)

    // A shaggy brown mop, in strokes, falling over his brow and both ears.
    c.pattern(16, 19, [
        "......H.HH..H.HH......",
        "....HlHHHlHHHlHHHH....",
        "..HHHHlHHHHlHHHHlHHH..",
        ".HHlHHHHhHHHHhHHHHlHH.",
        "HHHHHhHHHHHHHHHHhHHHHH",
        "HHhHHHHHhHHHHhHHHHHhHH",
        "HHHH.hHH..hH...hHH.HHH",
        "HHHh...h.........h.HHh",
        ".HHh................Hh",
        ".Hh..................h",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The EMF meter: a grey paddle held out flat in front of him, lit along its top, rounded at the end, and five
    // lights in a row along its face. Idle, one green glows; while he waves it, they jump about and hit the red.
    let y = 32 - wave
    c.pattern(40, y, [
        "LLLLLLLLLL.",
        "BBBBBBBBBBB",
        "BBBBBBBBBBB",
        ".DDDDDDDDD.",
    ], ["L": boxL, "B": box, "D": boxD])
    let lights = [C(0x3AE05A), C(0x9AE83A), C(0xF0D23A), C(0xF08A2A), C(0xFF3A2A)]
    let level = k >= 0 && on > 0.4 ? 1 + Int(noise(Int(p.t * 9)) * 4.99) : 1
    for i in 0..<5 {
        c.px(41 + i * 2, y + 1, i < level ? lights[i] : C(0x2A2C30))
        c.px(41 + i * 2, y + 2, i < level ? lights[i] : boxD)
    }
    if level == 5 {
        c.glowLine(49, Double(y + 1), 49, Double(y + 2), core: C(0xFF3A2A).alpha(0.2), glow: C(0xFF3A2A).alpha(0.15),
                   coreR: 1, glowR: 3)
    }
    c.rect(38, 33 - wave, 3, 3, clawdOrange); c.px(40, 35 - wave, clawdShade)
}

// MARK: - Frank Devereaux

/// Frank Devereaux: the paranoid hacker who trusts no one, in a tall, puffy flat cap of pale grey tweed with a button
/// on top, short grey hair at the sides, his brows down in a glare and his eyes darting side to side; a drab army
/// field jacket with flapped chest pockets, its collar up, over a grey sweatshirt; grey trousers and black boots. In
/// his fist, a stack of burner phones held with a rubber band. He doesn't fight. Signature: a SIM card pops up out of
/// the top phone, and he snaps it in half; the halves tumble to the floor.
private func drawFrankDevereaux(_ c: PixelCanvas, _ p: Pose) {
    let cap = C(0xA8A49C), capL = C(0xC8C4BA), capD = C(0x7A766E), fleck = C(0x8E8A82)
    let grey = C(0x9E9A96), greyD = C(0x6E6A66)
    let coat = C(0x585C40), coatD = C(0x3C3F2A), coatL = C(0x767A56), sweat = C(0x6A6A70)
    let k = h5Span(p, 0.05, 0.95)
    let raise = Int((h5Ease(k, edge: 0.15) * 3).rounded())

    drawLegs(c, Look(leg: C(0x5E5E64)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx + 1, 39, C(0x4A4A50)) } }
    drawBoots(c, C(0x1E1E22), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armRight: raise)

    // The field jacket: its collar standing up, the snap placket down the front, two flapped chest pockets with a
    // button each, lit on the near shoulder, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 2, sweat); c.rect(25, 33, 6, 1, C(0x5E5E64))
    c.rect(22, 33, 2, 2, coatL); c.rect(32, 33, 2, 2, coatD)                 // the collar points
    c.rect(28, 35, 1, 3, coatD)
    c.rect(20, 35, 5, 1, coatD); c.px(22, 35, C(0x2A2C1E)); c.rect(20, 36, 5, 1, C(0x50543A))
    c.rect(31, 35, 5, 1, coatD); c.px(33, 35, C(0x2A2C1E))
    c.rect(19, 33, 3, 1, coatL); c.rect(19, 34, 1, 3, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD); c.rect(15, 35, 3, 1, coatD)

    // His eyes dart: every so often both glance forward, a pixel over.
    if Int(p.lt / 1.7) % 3 == 1 {
        c.rect(22, 29, 1, 3, clawdOrange); c.rect(24, 29, 1, 3, ink)
        c.rect(32, 29, 1, 3, clawdOrange); c.rect(34, 29, 1, 3, ink)
    }
    // The glare: grey brows slanting down to the middle, over the inner corner of each eye.
    c.rect(21, 28, 2, 1, grey); c.px(23, 29, grey); c.px(32, 29, grey); c.rect(33, 28, 2, 1, grey)

    // The flat cap: a tall, puffy crown of pale grey tweed flecked darker, a button on top, lit on the left, shaded
    // underneath, its short brim pulled forward. Short grey hair under it at the sides.
    c.pattern(17, 20, [
        ".....CCCCCCCCCC.......",
        "...CCfCCCCfCCCCfCC....",
        "..CLfCCCfCCCCfCCCCCC..",
        ".CLCCCfCCCCfCCCCfCCCCC",
        ".DDDDDDDDDDDDDDDDDDDBBB",
        ".GG.................g..",
        ".Gg...................",
    ], ["C": cap, "L": capL, "f": fleck, "D": capD, "B": capD, "G": grey, "g": greyD])
    c.rect(22, 20, 4, 1, capL)
    c.px(25, 19, capD)                                       // the button

    // The burner phones, a stack of four in his fist, a rubber band round them; a SIM card pops out of the top one
    // during the signature and gets snapped.
    let sy = 28 - raise
    let phones = [C(0x2A2A30), C(0x9A9EA6), C(0x2A3A5E), C(0x8A2A2A)]
    for (i, col) in phones.enumerated() {
        let y = sy + i * 2
        c.rect(38, y, 6, 2, col); c.px(38, y, i == 1 ? C(0xC4C8D0) : C(0x55555E))
        c.px(43, y + 1, C(0x101014))
    }
    c.rect(41, sy, 1, 8, C(0xC09A5A))                       // the rubber band
    c.rect(38, 33 - raise, 3, 3, clawdOrange); c.px(40, 35 - raise, clawdShade)

    guard k >= 0 else { return }
    let card = C(0xF0EEE6), cardD = C(0xBEBAB0), gold = C(0xE0B444)
    if k < 0.55 {
        // Up it comes out of the top phone, held between finger and thumb.
        let rise = min(4, Int(k / 0.25 * 4))
        let y = sy - rise
        c.rect(39, y, 5, 3, card); c.rect(39, y + 2, 5, 1, cardD); c.rect(40, y + 1, 2, 1, gold)
        if k > 0.4 {   // it bends before it goes
            c.px(41, y, cardD); c.px(42, y - 1, card)
        }
    } else {
        // Snap: two halves, tilting apart and tumbling down past his hand to the floor; a little white crack of light.
        let f = (k - 0.55) / 0.45
        if f < 0.15 {
            c.px(41, sy - 6, C(0xFFFFFF)); c.px(40, sy - 7, C(0xFFFFFF).alpha(0.6)); c.px(43, sy - 7, C(0xFFFFFF).alpha(0.6))
        }
        let fall = min(Double(43 - sy + 4), f * f * 40)
        let y0 = sy - 4 + Int(fall)
        if y0 < 42 {
            c.rect(37 - Int(f * 3), y0, 2, 3, card); c.px(38 - Int(f * 3), y0 + 1, gold)
            c.rect(44 + Int(f * 3), y0 + 1, 3, 2, card); c.px(44 + Int(f * 3), y0 + 1, cardD)
        } else {
            c.rect(36, 42, 2, 1, card); c.rect(47, 42, 3, 1, card)
        }
    }
}

// MARK: - Benny Lafitte

/// Benny Lafitte: the vampire who had Dean's back in Purgatory, with black hair slicked back under a small dark leather
/// flat cap worn low, long sideburns, a battered grey-brown canvas jacket caked with Purgatory mud at the hem and
/// cuffs, over a rust-red henley; dark trousers and muddy boots. Fights with a big machete, and his fangs drop when he
/// does. Signature: he grins, and his row of vampire fangs slides down; then they slide back up.
private func drawBennyLafitte(_ c: PixelCanvas, _ p: Pose) {
    let cap = C(0x3E2E24), capL = C(0x5E4836), capD = C(0x221812)
    let hair = C(0x16120E), hairL = C(0x34281E)
    let coat = C(0x6A604E), coatD = C(0x484030), coatL = C(0x8A7E66), mud = C(0x3E3022), mudL = C(0x54422E)
    let henley = C(0x7A3A2A), henleyD = C(0x562418)
    let k = h5Span(p, 0.05, 0.95)
    let grin = p.melee != nil ? 1 : h5Ease(k, edge: 0.15)
    let drop = p.melee != nil ? 2 : k < 0 ? 0 : Int((h5Ease((k - 0.2) / 0.6, edge: 0.25) * 2).rounded())

    drawLegs(c, Look(leg: C(0x2E2C30)), step: p.step)
    drawBoots(c, C(0x3A2C20), step: p.step, rows: 2)
    if !seatedPose { for lx in [19, 31] { c.px(lx, 41, mudL); c.px(lx + 1, 40, mud) } }

    c.oy += p.breathe
    drawBody(c, Look(arm: coat), armRight: 0)

    // The canvas jacket, open on the henley and its button placket, lit on the near shoulder and edge, muddy at the
    // hem and the cuff, a tear on the far side.
    c.rect(18, 33, 20, 5, coat)
    c.rect(24, 33, 8, 5, henley); c.rect(27, 33, 1, 3, henleyD); c.px(27, 34, C(0xD8C8B0))
    c.rect(23, 33, 1, 5, coatL); c.rect(32, 33, 1, 5, coatD)
    c.rect(19, 33, 4, 1, coatL); c.rect(33, 33, 3, 1, coatL); c.rect(19, 34, 1, 3, coatL)
    c.rect(37, 33, 1, 5, coatD); c.rect(18, 37, 20, 1, coatD)
    c.rect(19, 37, 3, 1, mud); c.rect(25, 37, 2, 1, mud); c.rect(33, 37, 3, 1, mud); c.px(20, 36, mud); c.px(34, 36, mudL)
    c.px(35, 34, coatD); c.px(36, 35, coatD)                                  // the tear
    c.rect(15, 35, 3, 1, mud); c.px(38, 35, mud)

    // The grin, and his fangs: a row of little pointed teeth sliding down over his lip.
    if grin > 0.3 {
        c.rect(25, 32, 6, 1, C(0x3A1A16)); c.px(24, 31, C(0x3A1A16)); c.px(31, 31, C(0x3A1A16))
        c.rect(25, 32, 6, 1, C(0xE8E4DA))
        if drop > 0 {
            for x in [25, 27, 28, 30] { c.rect(x, 33, 1, drop, C(0xF4F2EA)) }
            c.px(26, 33, C(0xC8C2B6)); c.px(29, 33, C(0xC8C2B6))
        }
    }

    // Slicked black hair, long at the nape, with long sideburns.
    c.pattern(16, 24, [
        "..HH....................",
        ".HlH....................",
        "HHHH................H...",
        "HHHh................H...",
        ".HHh................h...",
        "..h.....................",
    ], ["H": hair, "l": hairL, "h": C(0x0A0806)])
    c.rect(19, 27, 1, 4, hair)
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)
    // The cap: small and dark, worn low and tight, with a short brim pulled down at the front.
    c.pattern(17, 22, [
        "....CCCCCCCCCCC.......",
        "..CLLCCCCCCCCCCCC.....",
        ".CLCCCCCCCCCCCCCCCCBB.",
        ".DDDDDDDDDDDDDDDDDDBBB",
    ], ["C": cap, "L": capL, "D": capD, "B": capD])
    c.rect(22, 23, 6, 1, capL)

    // The machete: swung, or held point down at his side.
    if let a = p.melee {
        huntBlade(c, p, angle: a, grip: C(0x3E2A1A), steel: C(0x8E949A), edge: C(0xD2D6DA), length: 11)
        let tip = huntReach(huntHand, a + 5, 10)   // the machete's belly, wider at the end
        c.px(Int(tip.x.rounded()), Int(tip.y.rounded()), C(0x8E949A))
    } else {
        c.rect(39, 34, 2, 3, C(0x3E2A1A))
        // Its long, broad blade hangs past his knee, widening towards the end, lit along the back, a fleck of rust.
        c.pattern(39, 37, [
            "LSS.",
            "LSS.",
            "LSSS",
            "LSSS",
            "LSSd",
            ".dd.",
        ], ["L": C(0xD2D6DA), "S": C(0x8E949A), "d": C(0x62666C)])
        c.px(41, 39, C(0x7A4E30))
        c.rect(38, 33, 3, 3, clawdOrange); c.px(40, 35, clawdShade)
    }
}

// MARK: - Missouri Mosley

/// Missouri Mosley: the psychic of Lawrence, Kansas, who reads you before you knock, in a purple silk blouse with a
/// ruffled neckline and full sleeves, strings of wooden and turquoise beads round her neck, gold hoop earrings, short
/// tight curls in black going grey, a long charcoal skirt with her stockinged legs and shoes below. She doesn't fight.
/// Signature: she draws her hand back and swats someone with the back of it, whap, then smooths her blouse.
private func drawMissouriMosley(_ c: PixelCanvas, _ p: Pose) {
    let silk = C(0x6E3A8E), silkD = C(0x4A2266), silkL = C(0x9A5EBC)
    let hair = C(0x1E1A1C), hairL = C(0x4A4448), streak = C(0x9A969A)
    let skirt = C(0x3A343C), skirtD = C(0x26222A), skirtL = C(0x4E4852)
    let k = h5Span(p, 0.05, 0.95)

    drawLegs(c, Look(leg: C(0x5A3E30)), step: p.step)
    drawBoots(c, C(0x1E1A1C), step: p.step, rows: 1)

    c.oy += p.breathe
    // The long skirt over the legs, a fold over each, the hem a shade darker, the legs showing below it.
    if seatedPose {
        c.rect(17, 38, 22, 1, skirt)
    } else {
        c.rect(17, 38, 22, 2, skirt); c.rect(17, 40, 22, 1, skirtD)
        c.rect(17, 38, 1, 2, skirtL); c.rect(38, 38, 1, 3, skirtD)
        for x in [21, 25, 29, 33] { c.rect(x, 38, 1, 2, skirtD) }
    }

    // The swat: back goes the hand, up by her ear; then it flicks forward, a smear behind it and a burst of stars
    // where it lands; then back to her side.
    var hand: (x: Int, y: Int)? = nil
    var raise = 0
    if k >= 0 {
        if k < 0.35 { raise = Int((h5Smooth(k / 0.35) * 6).rounded()) }
        else if k < 0.5 { hand = (44, 31) }
        else if k < 0.62 { hand = (43, 32) }
        else { raise = Int((h5Smooth(1 - (k - 0.62) / 0.38) * 2).rounded()) }
    }
    drawBody(c, Look(arm: silk), armRight: hand == nil ? raise : 0)

    // The blouse: the ruffled neckline, full sleeves, lit on the near side, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, silk)
    c.rect(19, 33, 4, 1, silkL); c.rect(19, 34, 1, 3, silkL)
    c.rect(37, 33, 1, 5, silkD); c.rect(18, 37, 20, 1, silkD)
    c.rect(22, 34, 1, 3, silkD); c.rect(34, 34, 1, 2, silkD)                  // folds
    c.rect(15, 35, 3, 1, silkD)
    // The ruffle round the neckline, dipping in a soft V.
    c.rect(23, 33, 10, 1, silkL); c.px(24, 34, silkL); c.px(31, 34, silkL); c.px(25, 34, silk)
    // The beads: two strings, wood and turquoise, hanging in a curve, with a red bead at the bottom of each.
    let wood = C(0xB07A3E), turq = C(0x3EB0A4)
    for (x, y) in [(23, 34), (24, 35), (26, 36), (28, 36), (30, 36), (32, 35)] { c.px(x, y, wood) }
    for (x, y) in [(25, 34), (27, 35), (29, 35), (31, 34)] { c.px(x, y, turq) }
    c.px(28, 37, C(0xC03A2E))
    // Gold hoop earrings.
    c.px(18, 31, C(0xE0B444)); c.px(18, 32, C(0xA07A28))

    // Short tight curls, black going grey, in little strokes, lit on top.
    c.pattern(17, 21, [
        ".....HHHHHHHHHH.......",
        "...HHllHHllHHllHHH....",
        "..HHHHggHHHHggHHHHH...",
        ".HHllHHllHHllHHllHHHH.",
        ".HHHHggHHHHHHggHHHgHH.",
        ".HHg..............HH..",
        ".Hh...............h...",
    ], ["H": hair, "l": hairL, "g": streak, "h": C(0x0E0C0E)])
    c.rect(22, 28, 2, 1, hair); c.rect(32, 28, 2, 1, hair)

    if let h = hand {
        // Her arm out, the full sleeve, and the back of her hand.
        c.rect(38, h.y, h.x - 38, 3, silk); c.rect(38, h.y, h.x - 38, 1, silkL)
        c.rect(h.x, h.y, 3, 3, clawdOrange); c.px(h.x + 2, h.y + 2, clawdShade)
        let f = (k - 0.35) / 0.27
        if f < 0.5 {
            for (i, yy) in [h.y - 3, h.y - 1].enumerated() {
                c.glowLine(39, Double(yy + i), Double(h.x - 1), Double(yy + 2), core: C(0xF0E8FF).alpha(0.35),
                           glow: C(0xF0E8FF).alpha(0.15), coreR: 0.4, glowR: 1.2)
            }
        }
        // Whap: little stars burst where it lands.
        let star = C(0xFFE27A)
        let r = 2 + Int(f * 3)
        let sx = h.x + 5, sy = h.y + 1
        c.px(sx + r, sy, star); c.px(sx, sy - r, star); c.px(sx, sy + r, star)
        c.px(sx + r - 1, sy - r + 1, star); c.px(sx + r - 1, sy + r - 1, star)
        c.px(sx, sy, C(0xFFFFFF))
    }
}

// MARK: - Pamela Barnes

/// Pamela Barnes: the psychic who looked on an angel's true face and lost her sight for it: a great cloud of dark
/// curls to her shoulders, black sunglasses, a fringed brown suede vest over a teal top, a stack of silver bangles,
/// jeans and black boots. She doesn't fight. Signature: a séance: she spreads her hands, three candles rise out of the
/// floor round her and their flames flare up tall, then sink and go out, and the candles are gone.
private func drawPamelaBarnes(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0x241A16), hairL = C(0x46342A), hairD = C(0x120C0A)
    let vest = C(0x8A5A34), vestD = C(0x5E3A20), vestL = C(0xAC7848)
    let top = C(0x2E5A5E), topD = C(0x1E3E42), topL = C(0x44787C)
    let k = h5Span(p, 0.05, 0.95)
    let spread = Int((h5Ease(k, edge: 0.15) * 3).rounded())
    let rise = h5Ease(k, edge: 0.18)                           // the candles up out of the floor and back
    let flare = k < 0 ? 0 : h5Ease((k - 0.25) / 0.55, edge: 0.3)   // the flames

    // The candles: cream wax, lit on the left, a drip down the side, a wick; their flames grow tall and flicker, with
    // a soft warm glow round each.
    let candles: [(x: Int, h: Int)] = [(8, 6), (47, 5), (55, 7)]
    if rise > 0 {
        for (i, cd) in candles.enumerated() {
            let h = Int((Double(cd.h) * rise).rounded())
            guard h > 0 else { continue }
            let topY = 44 - h
            c.rect(cd.x, topY, 3, h, C(0xEEE4C8)); c.rect(cd.x, topY, 1, h, C(0xFFF8E4))
            c.rect(cd.x + 2, topY, 1, h, C(0xC8BC9C))
            if h > 3 { c.px(cd.x + 1, topY + 1, C(0xFFF8E4)); c.px(cd.x + 1, topY + 2, C(0xE0D4B4)) }
            guard rise > 0.95 else { continue }
            c.px(cd.x + 1, topY - 1, C(0x2A2420))                 // the wick
            let tall = 1 + Int((flare * (4 + noise(Int(p.t * 12) + i * 7) * 1.5)).rounded())
            if flare > 0.05 {
                let gy = Double(topY - 1 - tall / 2)
                c.glowLine(Double(cd.x) + 1, gy, Double(cd.x) + 1, gy, core: C(0xFFB84A).alpha(0.18 * flare),
                           glow: C(0xFF9A3A).alpha(0.12 * flare), coreR: 2 + Double(tall) * 0.5, glowR: 3 + Double(tall))
            }
            for d in 0..<tall {
                let y = topY - 2 - d
                let col = d == tall - 1 ? C(0xFF7A2A) : d < tall / 2 ? C(0xFFF2B0) : C(0xFFC23A)
                c.px(cd.x + 1, y, col)
                if d == 0 && tall > 2 { c.px(cd.x, y, C(0xFFB23A)); c.px(cd.x + 2, y, C(0xFFB23A)) }
            }
        }
    }

    drawLegs(c, Look(leg: C(0x3E5274)), step: p.step)
    h5LegLight(c, p, C(0x56688C))
    drawBoots(c, C(0x1A181C), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(eye: nil), armLeft: spread, armRight: spread)
    // Silver bangles at her wrists.
    c.rect(38, 35 - spread, 3, 1, C(0xC8CCD4)); c.px(38, 35 - spread, C(0xEEF0F4))

    // The teal top with its scoop neck and a silver pendant, and the suede vest open over it: lit on the near side,
    // its far side in shade, fringe hanging from the hem over her hips.
    c.rect(18, 33, 20, 5, vest)
    c.rect(23, 33, 10, 5, top); c.rect(23, 33, 1, 5, topL); c.rect(32, 33, 1, 5, topD); c.rect(23, 37, 10, 1, topD)
    c.rect(26, 33, 4, 1, clawdOrange); c.px(27, 34, C(0xD8DCE4)); c.px(28, 34, C(0x9A9EA8))
    c.rect(22, 33, 1, 5, vestL); c.rect(33, 33, 1, 5, vestD)
    c.rect(19, 33, 3, 1, vestL); c.rect(19, 34, 1, 3, vestL); c.rect(34, 33, 2, 1, vestL)
    c.rect(37, 33, 1, 5, vestD); c.rect(18, 37, 20, 1, vestD)
    c.px(20, 35, vestD); c.px(35, 35, vestD)                          // stitching
    c.rect(15, 35 - spread, 3, 1, vestD)
    if !seatedPose {
        for x in stride(from: 18, through: 37, by: 2) where !(24...31).contains(x) { c.px(x, 38, vestD) }
    }

    // The sunglasses: two black lenses with a cold glint, a thin bridge, the arms back into her hair.
    let lens = C(0x0E0E12)
    c.rect(21, 29, 4, 3, lens); c.rect(31, 29, 4, 3, lens)
    c.rect(25, 29, 6, 1, C(0x2A2A32)); c.rect(19, 29, 2, 1, C(0x2A2A32))
    c.px(22, 29, C(0x8A9AB4)); c.px(32, 29, C(0x8A9AB4))
    if flare > 0.3 { c.px(23, 30, C(0xFFC86A)); c.px(33, 30, C(0xFFC86A)) }   // the candlelight in her lenses

    // The curls: a great dark cloud of them to her shoulders, every curl a little lit loop.
    c.pattern(14, 18, [
        "........HHH.HHH.HH.......",
        ".....HHlHHHlHHHHlHHH.....",
        "....HHlhHHlhHHHlhHHlH....",
        "...HHHHHHHHHHHHHHHHHHHH..",
        "..HlHHHlHHHHlHHHHlHHHlHH.",
        "..HlhHHlhHHHlhHHHlhHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHHHH",
        ".HHlHHHHhHHHHHhHHHHHhHlHH",
        ".HlhHH..............HlhH.",
        "HHHHH...............HHHH.",
        "HlHHh................HhH.",
        "HlhHH................HH..",
        "HHHH.................Hh..",
        ".HlH.................h...",
        ".HhH.....................",
        "..h......................",
    ], ["H": hair, "l": hairL, "h": hairD])
}
