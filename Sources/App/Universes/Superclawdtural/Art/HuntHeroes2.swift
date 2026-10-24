import Foundation

// Heroes: Jack and the Winclawdster family, with Bobby and Ellen. Clawd in costume as in HuntHeroes1.swift: hair and
// clothes over the blocky body, Clawd's own orange face showing. Kept apart from Dean and Sam at a glance: Jack in a
// short tan jacket, Mary blonde, John older and stubbled in a darker, more worn jacket than Dean's with his journal,
// Henry in a 1958 suit and fedora, Bobby in his cap and grey beard, Ellen in her Roadhouse apron.
//
// Guns (`weapon: .blaster`, `shot: .bullet`): rock salt and lead both fly as the engine's bullet; the drawing tells a
// pistol from a shotgun. Jack's power (`weapon: .lightning`) is gold `waves`; don't set `magic.variant` yourself.

let huntHeroes2: [HuntHero: Persona] = [
    .jackKlyne: Persona(name: "Jack Klyne", weapon: .lightning,
                        magic: Magic(core: C(0xFFF6D0), glow: C(0xE8B02A), jagged: false, waves: true),
                        headTop: 21, signature: 3.6, callout: "I'm Jack.", draw: drawJackKlyne),
    .maryWinclawdster: Persona(name: "Mary Winclawdster", weapon: .blaster, shot: .bullet, muzzle: (48, 31),
                               headTop: 20, signature: 3.4, callout: "Angels are watching over you.",
                               draw: drawMaryWinclawdster),
    .johnWinclawdster: Persona(name: "John Winclawdster", weapon: .blaster, shot: .bullet, muzzle: (51, 31),
                               headTop: 21, signature: 3.6, callout: "Take care of Sammy.", draw: drawJohnWinclawdster),
    .henryWinclawdster: Persona(name: "Henry Winclawdster", headTop: 18, signature: 3.6, callout: "Men of Letters.",
                                draw: drawHenryWinclawdster),
    .bobbyClawdsinger: Persona(name: "Bobby Clawdsinger", weapon: .blaster, shot: .bullet, muzzle: (55, 31),
                               headTop: 20, signature: 3.2, callout: "Idjits.", draw: drawBobbyClawdsinger),
    .ellenHarvell: Persona(name: "Ellen Harvell", weapon: .blaster, shot: .bullet, muzzle: (54, 31), headTop: 22,
                           signature: 2.8, draw: drawEllenHarvell),
]

/// Where `s` (0…1 through a signature) is inside `a`…`b`, as 0…1 again; -1 outside it or with no signature.
private func span(_ s: Double?, _ a: Double, _ b: Double) -> Double {
    guard let s, s > a, s < b else { return -1 }
    return (s - a) / (b - a)
}

// MARK: - Jack Klyne

/// Jack Klyne: the young Nephilim, light brown hair cut short and neat with a fringe swept across, a tan canvas work
/// jacket with a brown corduroy collar and two flapped chest pockets, open over a dark grey tee, dark jeans and tan
/// boots. His power is a gold force pulsing out in waves, and his eyes light gold while he uses it. Signature: his eyes
/// glow gold, a halo of it round them; then the glow goes, he grins, and he eats a bar of nougat in three bites.
private func drawJackKlyne(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0xB8965E), jacketD = C(0x8C6E3E), jacketL = C(0xD6B67E), cord = C(0x5A3E24), cordL = C(0x86643E)
    let hem = C(0x7A5E34), brass = C(0xE8C462)
    let tee = C(0x3E4048), teeD = C(0x2C2E34)
    let hair = C(0x8A6844), hairD = C(0x624828), hairL = C(0xAC8A5C)
    let gold = C(0xFFD24A), goldL = C(0xFFF4C0)
    let glow = span(p.signature, 0.04, 0.42), grin = span(p.signature, 0.38, 0.97)
    let bar = span(p.signature, 0.46, 0.94)
    let raise = bar < 0 ? p.armRaise : bar < 0.15 ? Int(bar / 0.15 * 5) : bar > 0.85 ? Int((1 - bar) / 0.15 * 5) : 5

    drawLegs(c, Look(leg: C(0x2E3A54)), step: p.step)
    drawBoots(c, C(0x7A5634), step: p.step, rows: 2)
    drawBoots(c, C(0x4E3420), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: raise)

    // The jacket, a canvas work jacket short to the hip and open on the tee: the wide brown corduroy collar lying
    // flat over the shoulders, its ribs catching the light, its points down the front; the chest pockets with
    // stitched flaps and a brass snap each; the lit front edge, the far side in shade, brown cuffs to match the
    // collar, and the hem band a shade darker.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(26, 33, 4, 5, tee); c.rect(26, 33, 4, 1, teeD)
    c.rect(18, 33, 8, 1, cord); c.rect(30, 33, 8, 1, cord)
    for x in [19, 21, 23] { c.px(x, 33, cordL) }
    c.rect(24, 34, 2, 2, cord); c.px(24, 34, cordL); c.rect(30, 34, 2, 2, cord)
    c.rect(25, 36, 1, 2, jacketL); c.rect(30, 36, 1, 2, jacketD)
    c.rect(19, 35, 4, 1, jacketD); c.px(21, 35, brass); c.rect(19, 36, 4, 1, jacketL)
    c.rect(32, 35, 4, 1, jacketD); c.px(34, 35, brass)
    c.px(18, 34, jacketL); c.px(18, 35, jacketL); c.px(36, 34, jacketD); c.rect(37, 33, 1, 5, jacketD)
    c.rect(18, 37, 20, 1, hem)
    c.rect(15, 35, 3, 1, cord)
    if raise == 0 { c.rect(38, 35, 3, 1, cord) }

    // Short, tidy hair, flat on top and lifting a little at the front, lit in slanting strokes that run the way it's
    // combed, the fringe swept down across his brow towards where he faces, its edge a slant over his face rather
    // than a straight line.
    c.pattern(17, 21, [
        "..............HHlH....",
        "...HHHlHHHHlHHHHlHHH..",
        "..HHHHHlHHHHlHHHHlHHH.",
        ".HHHHHHHhHHHHhHHHHhHHH",
        ".HHhHHHHHhHHHHhHHHHhHH",
        ".HHh.HHHHHhHHHHhHHHh..",
        ".Hh.....hHHHHHhHHh....",
        "............hHHHh.....",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // His eyes go gold while he uses his power, and through the first half of the signature, a soft halo round them.
    let lit = glow >= 0 ? sin(glow * .pi) : p.zap == true ? 0.7 : 0
    if lit > 0.15 {
        for ex in [22, 32] {
            c.rect(ex, 29, 2, 3, gold); c.px(ex, 29, goldL)
            for (hx, hy) in [(ex - 1, 29), (ex - 1, 30), (ex - 1, 31), (ex + 2, 29), (ex + 2, 30), (ex + 2, 31),
                             (ex, 28), (ex + 1, 28), (ex, 32), (ex + 1, 32)] {
                c.px(hx, hy, C(0xFFE27A, 0.55 * lit))
            }
        }
    }
    // The grin: wide and open under his eyes, all teeth.
    if grin >= 0 && glow < 0 {
        let mouth = C(0x4A1E12)
        c.px(24, 31, mouth); c.rect(25, 31, 6, 1, C(0xF6F2EA)); c.px(31, 31, mouth); c.rect(25, 32, 6, 1, mouth)
    }

    guard bar >= 0 else { return }
    // The nougat bar in his raised hand, held up to his face: cream nougat dotted with nuts, the red and white wrapper
    // peeled back at his fist. Each bite takes two columns off the end; crumbs drop after each.
    let hy = 33 - raise
    c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 1, clawdShade)
    let bites = bar < 0.3 ? 0 : bar < 0.5 ? 1 : bar < 0.7 ? 2 : 3
    if bites < 3 {
        let rows = ["NNNnNNWRW", "NnNNNnRWR", "nnnnnnWRW"]
        for (dy, row) in rows.enumerated() {
            for (dx, ch) in row.enumerated() where dx >= bites * 2 && ch != "." {
                let col: Px = ch == "N" ? C(0xF2E6C8) : ch == "n" ? C(0xC8B080) : ch == "R" ? C(0xC8282E) : C(0xF4F4F0)
                c.px(33 + dx, hy - 3 + dy, col)
            }
        }
        if bites < 2 { c.px(34 + bites * 2, hy - 2, C(0x9A6A34)); c.px(36, hy - 3, C(0x9A6A34)) }   // the nuts
    }
    for b in 0..<3 {
        let k = (bar - [0.3, 0.5, 0.7][b]) / 0.12
        guard k > 0 && k < 1 else { continue }
        c.px(34 + b, hy + Int(k * 6), C(0xF2E6C8))
    }
}

// MARK: - Mary Winclawdster

/// Mary Winclawdster: wavy blonde hair to her shoulders, parted and swept across, a caramel leather jacket (lighter
/// and warmer than either of her boys'), open over a dusty blue knit top, jeans and dark boots. Fights with a black
/// 9mm pistol. Signature: she pushes her hair back off her face, then lifts the pistol, drops the clip out of the grip
/// to check it, and slaps it home.
private func drawMaryWinclawdster(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x8E5C34), jacketD = C(0x643E1E), jacketL = C(0xB07C4E)
    let knit = C(0x6A84A6), knitD = C(0x4E6686)
    let hair = C(0xDEBE6C), hairD = C(0xB0903E), hairL = C(0xF4DC9A)
    let push = span(p.signature, 0.04, 0.36), check = span(p.signature, 0.42, 0.96)
    let raise = push >= 0 ? Int(sin(push * .pi) * 8) : 0

    drawLegs(c, Look(leg: C(0x3E5072)), step: p.step)
    drawBoots(c, C(0x3A2A20), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: raise)

    // The jacket, fitted, with a narrow collar turned out, open on the knit top in a V, a seam down each front, the
    // far side and the hem in shade, cuffs.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, knit); c.rect(25, 33, 6, 1, knitD); c.rect(26, 34, 4, 1, C(0x5A7496))
    c.rect(24, 33, 1, 4, jacketL); c.rect(31, 33, 1, 4, jacketD); c.px(23, 33, jacketL); c.px(32, 33, jacketD)
    c.rect(19, 33, 3, 1, jacketL); c.rect(34, 33, 2, 1, jacketL)
    c.rect(21, 35, 1, 2, jacketD); c.rect(34, 35, 1, 2, jacketD)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD); c.rect(19, 34, 1, 3, jacketL)
    c.rect(15, 35, 3, 1, jacketD)

    // Blonde hair, parted on the right and swept across from the parting in lit strokes, the fringe a paler lock
    // sweeping across her brow with a shadow above it; then in waves to her shoulders, in at the cheek, out again,
    // the ends flicking out. As she pushes it back, the fringe lifts off her face.
    let lifted = push > 0.3 && push < 0.85
    c.pattern(16, 20, [
        "........HHHHHHHH........",
        ".....HHlllHHHHHdHHH.....",
        "...HHlllHHHHHHdHHlHH....",
        "..HHllHHHHHHHdHHHHlHH...",
        "..HlHHHddHHHHHHdHHHHHd..",
        ".HHHddllllllllHHdHHHHHd.",
        lifted ? ".HHHHHH...........HHHHd." : ".HHdllllllllld.....HHHHd",
        lifted ? ".HHHH..............HHHd." : ".HHHd.............HHHd..",
        "..HHH..............HHd..",
        "..HlH...............HHd.",
        ".HHd................dHH.",
        ".HlHd..............HdHd.",
        "HHd.................dHHd",
        "Hd...................d.d",
    ], ["H": hair, "d": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    if push >= 0 {
        if raise > 4 { c.rect(38, 33 - raise, 3, 3, clawdOrange) }   // her hand at her hairline
        return   // the pistol tucked away for a moment
    }

    // The pistol: a black slide lit grey along the top, the frame and trigger guard, the grip in her fist. Checking
    // it, she lifts it to eye level and the clip drops out of the grip, then goes back in with a slap.
    c.oy += p.gunY
    var drop = 0
    if check >= 0 {
        c.oy -= 4
        drop = check < 0.2 ? Int(check / 0.2 * 6) : check < 0.6 ? 6 : check < 0.72 ? Int((0.72 - check) / 0.12 * 6) : 0
    }
    c.pattern(38, 30, [
        "..GGGGGGGGl",
        "..KKKKKKKK.",
        "OOOKk.k....",
        "OOOK.......",
        ".OK........",
    ], ["G": C(0x5A5E66), "l": C(0x9AA0AA), "K": C(0x202024), "k": C(0x141416), "O": clawdOrange])
    if drop > 0 {
        // The clip below her fist: a long dark steel box lit down its near side, the brass rounds stacked at its
        // lips, a black base plate at the bottom.
        let top = 33 + drop
        c.pattern(38, top, [
            ".bB.",
            ".LS.",
            ".LS.",
            ".LS.",
            ".LS.",
            "kkkk",
        ], ["b": C(0xF0D070), "B": C(0xC09030), "L": C(0x9AA0AE), "S": C(0x4A4E58), "k": C(0x1E2026)])
    }
    if check > 0.72 && check < 0.8 {
        // The slap home: a white flick of motion off the grip.
        c.px(42, 33, C(0xFFFFFF, 0.9)); c.px(43, 34, C(0xFFFFFF, 0.6)); c.px(42, 35, C(0xFFFFFF, 0.5))
    }
}

// MARK: - John Winclawdster

/// John Winclawdster: the boys' father, older and harder than Dean: dark hair cut short and greying at the temples, a
/// day's dark stubble and a moustache, a heavy near-black leather jacket gone pale with wear at the seams, its big
/// collar up, over a charcoal henley; worn jeans and black boots. Fights with the Colt, Samuel Colt's long-barrelled
/// revolver with its walnut grip. Signature: he pulls out his hunting journal, the battered brown one stuffed with
/// notes, and writes in it, lines of ink filling the page.
private func drawJohnWinclawdster(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x3A2A1E), jacketD = C(0x22180E), jacketL = C(0x56402E), worn = C(0x6E5844)
    let henley = C(0x3A3C40), henleyL = C(0x50535A), button = C(0x8A8A8E)
    let hair = C(0x2E2218), hairD = C(0x1A120C), hairL = C(0x46382A), grey = C(0x8C8882)
    let stubble = C(0x94503A), stubbleD = C(0x6E3A28)
    let book = span(p.signature, 0.06, 0.94)

    drawLegs(c, Look(leg: C(0x3C4862)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {   // the knees worn pale
            c.px(lx, p.step >= 0 && i % 2 == p.step ? 38 : 39, C(0x56647E))
        }
    }
    drawBoots(c, C(0x1E1A16), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armLeft: book >= 0 ? 1 : 0, armRight: book >= 0 ? 2 : 0)

    // Stubble along his jaw and a moustache: darker strokes over the lower face, thickest at the chin.
    c.pattern(18, 30, [
        "SS................SS",
        "SSs..sSSSSSSs....sSS",
        "SsSSsSSsSSsSSsSSsSSS",
    ], ["S": stubble, "s": stubbleD])

    // The jacket: heavy and worn, its big collar standing up round his neck and lit along the top, open on the
    // henley and its buttons, scuffed pale along the seams and the pocket, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(26, 33, 4, 5, henley); c.rect(27, 33, 2, 2, henleyL); c.px(28, 34, button); c.px(28, 36, button)
    c.rect(19, 32, 5, 1, jacketL); c.rect(32, 32, 4, 1, jacket); c.px(35, 32, jacketD)
    c.rect(24, 33, 2, 2, jacketL); c.rect(30, 33, 2, 2, jacketD)
    c.rect(25, 35, 1, 3, worn); c.px(19, 35, worn); c.px(20, 36, worn); c.rect(33, 35, 2, 1, worn)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(15, 35 - (book >= 0 ? 1 : 0), 3, 1, jacketD)

    // Short dark hair, receding a little and combed back, grey coming in over the ears.
    c.pattern(17, 21, [
        ".......HHHHHHH........",
        "....HHHHlHHHlHHHH.....",
        "..HHHHlHHHHlHHHHHH....",
        ".HHHHHHHHHHHHHHHHHHH..",
        ".gHhHHHhHHHHhHHHhHHHg.",
        ".gg................gg.",
        ".g..................g.",
    ], ["H": hair, "h": hairD, "l": hairL, "g": grey])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD); c.px(21, 28, hairD); c.px(34, 28, hairD)

    if book >= 0 {
        // The journal, held open in front of him: battered brown covers, the cream pages, the old lines of ink on the
        // left page, and new ones filling the right as his pen moves. It opens at the start and shuts at the end.
        let open = min(1, book / 0.12, (1 - book) / 0.1)
        let cover = C(0x5E3C22), coverD = C(0x3A2414), page = C(0xEEE4CA), pageD = C(0xC8BC9C), ink = C(0x2A2A3A)
        if open < 0.5 {
            c.rect(39, 32, 6, 4, cover); c.rect(39, 35, 6, 1, coverD); c.px(39, 32, C(0x7A5434))
            c.rect(44, 32, 1, 4, page)
        } else {
            c.rect(38, 31, 12, 5, cover); c.rect(38, 35, 12, 1, coverD)
            c.rect(39, 31, 4, 4, page); c.rect(44, 31, 5, 4, page); c.rect(43, 31, 1, 4, pageD)
            c.rect(39, 32, 3, 1, ink); c.rect(40, 34, 2, 1, ink); c.px(39, 33, C(0xA03028))   // a note circled red
            let w = (book - 0.12) / 0.76
            for (row, from) in [(32, 0.0), (33, 0.3), (34, 0.6)] {
                let k = max(0, min(1, (w - from) / 0.3))
                if k > 0 { c.rect(44, row, max(1, Int(k * 4)), 1, ink) }
            }
            // The pen in his fist, tip on the line he's writing.
            if w > 0 && w < 1 {
                let line = w < 0.3 ? 0 : w < 0.6 ? 1 : 2
                let k = max(0, min(1, (w - Double(line) * 0.3) / 0.3))
                let tx = 44 + Int(k * 3), ty = 32 + line
                c.px(tx, ty - 1, C(0x1A1A20)); c.px(tx + 1, ty - 2, C(0x1A1A20))
                c.rect(tx + 1, ty - 4, 3, 2, clawdOrange)
            }
        }
        c.rect(38, 31, 1, 4, clawdOrange)   // his far hand's fingers round the cover
        return
    }

    // The Colt: a long, blued barrel lit along the top, the cylinder behind it, the hammer back, the walnut grip in
    // his fist.
    c.oy += p.gunY
    c.pattern(38, 29, [
        "..k...........",
        "...SSSSSSSSSSl",
        "..cCCKKKKKKKK.",
        "OOOWk.k.......",
        "OOOW..........",
        ".OWW..........",
    ], ["S": C(0x5A6070), "l": C(0x9AA2B4), "K": C(0x30343E), "k": C(0x30343E), "C": C(0x464C5A), "c": C(0x6A7284),
        "W": C(0x6A4226), "O": clawdOrange])
}

// MARK: - Henry Winclawdster

/// Henry Winclawdster: the boys' grandfather, a Man of Letters straight out of 1958: a grey felt fedora with a black
/// band and its brim snapped down at the front, dark hair neat underneath, a warm grey suit buttoned over a white
/// shirt, a dark burgundy tie with a gold clip, a white pocket square, the brass key to the Bunker on a chain across
/// his front, trousers to match and polished black shoes. He doesn't fight. Signature: he tips his fedora, then holds
/// up the Men of Letters key, its bow set with their symbol, and it glints.
private func drawHenryWinclawdster(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x6C6456), suitD = C(0x4C463C), suitL = C(0x8C8474), suitN = C(0x3C372F)
    let shirt = C(0xEEECE6), tie = C(0x6A1E26), tieD = C(0x4A1218), brass = C(0xD8A840), brassD = C(0x8E6620)
    let felt = C(0x5E5650), feltD = C(0x423C36), feltL = C(0x7E766C), band = C(0x18161A)
    let hair = C(0x2E241C), hairD = C(0x1A140E)
    let tip = span(p.signature, 0.04, 0.44), key = span(p.signature, 0.48, 0.96)
    let raise = tip >= 0 ? Int(min(1, sin(tip * .pi) * 1.6) * 10) : key >= 0 ? Int(min(1, sin(key * .pi) * 2.5) * 3) : 0
    let lift = tip > 0.3 && tip < 0.75 ? Int(sin((tip - 0.3) / 0.45 * .pi) * 3 + 0.5) : 0

    drawLegs(c, Look(leg: C(0x5C5548)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {   // the trousers' pressed crease
            let top = p.step >= 0 && i % 2 == p.step ? 37 : 38
            c.rect(lx + 1, top, 1, 3, C(0x4A4438))
        }
    }
    drawBoots(c, C(0x101012), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: suit), armRight: raise)

    // The suit coat, buttoned: notched lapels lit on the near side, the shirt and tie in the V between them, the
    // pocket square, the key's chain hanging across his front, two buttons, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(26, 33, 4, 2, shirt); c.rect(27, 33, 2, 4, tie); c.px(28, 34, tieD); c.rect(27, 35, 2, 1, brass)
    // Each lapel a narrow slanting band from the shoulder to the button, its edge lit on the near side and shaded on
    // the far one, the notch a dark nick at the top.
    c.pattern(22, 33, [
        ".nLL....Dln",
        "..nL....Dn.",
        "...L....D..",
    ], ["L": suitL, "l": suit, "D": suitD, "n": suitN])
    c.px(26, 36, C(0x2A2622)); c.px(26, 37, C(0x2A2622))
    c.rect(33, 34, 2, 1, shirt)                                                   // the pocket square
    c.rect(19, 33, 3, 1, suitL); c.rect(19, 34, 1, 3, suitL)
    c.pattern(30, 36, ["k...k", ".kkk."], ["k": brassD])                           // the key's chain
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD)
    c.rect(15, 35, 3, 1, suitD); c.px(15, 34, shirt)

    // Neat dark hair under the hat, short over the ears.
    c.pattern(17, 26, [
        ".HHh...............H.",
        ".Hh...............hH.",
        ".h.................h.",
    ], ["H": hair, "h": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The fedora: a pinched crown dented down the middle, lit on the left, the black band, the brim snapped down at the
    // front. Tipping it, he lifts it clear of his head by its brim.
    c.pattern(16, 18 - lift, [
        "........FFFF..FFFF......",
        ".......FlFFFFdFFFFF.....",
        "......FlFFFFFdFFFFFd....",
        "......FlFFFFFFFFFFFd....",
        "......FlFFFFFFFFFFFd....",
        "......BBBBBBBBBBBBBB....",
        "..llFFFFFFFFFFFFFFFFFFF.",
        ".ddddddddddddddddddddFFF",
        ".....................dd.",
    ], ["F": felt, "l": feltL, "d": feltD, "B": band])

    if tip >= 0 && raise > 6 {
        c.rect(38, 33 - raise, 3, 3, clawdOrange)   // his fingers on the brim
    }
    guard key >= 0, raise > 0 else { return }
    // The key, held up in his fist: an ornate brass bow set with the Men of Letters' red star, a long shaft, the bit
    // with its wards; a glint runs along it.
    let ky = 33 - raise
    c.pattern(41, ky - 1, [
        "BLB.......",
        "LrBBBBBBBB",
        "BdB....d.d",
    ], ["B": brass, "L": C(0xF8E08A), "d": brassD, "r": C(0xB02A2A)])
    let g = key > 0.35 && key < 0.7 ? sin((key - 0.35) / 0.35 * .pi) : 0
    if g > 0 {
        let gx = 43 + Int((key - 0.35) / 0.35 * 6)
        c.px(gx, ky, C(0xFFFFFF, g))
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] { c.px(gx + dx, ky + dy, C(0xFFF6D0, 0.6 * g)) }
        c.px(gx, ky - 2, C(0xFFF6D0, 0.4 * g))
    }
}

// MARK: - Bobby Clawdsinger

/// Bobby Clawdsinger: the boys' surrogate dad, in his battered trucker cap (a faded rust-red front, tan mesh behind,
/// the bill curved down), grey hair poking out under it, a full grey beard, a dark brown quilted vest over an olive
/// flannel shirt, worn jeans and tan work boots. Fights with a long double-barrelled shotgun loaded with rock salt.
/// Signature: he takes a swig from his silver hip flask of holy water and lowers it again.
private func drawBobbyClawdsinger(_ c: PixelCanvas, _ p: Pose) {
    let vest = C(0x3E3226), vestD = C(0x281E16), vestL = C(0x5A4A38)
    let flannel = C(0x5A6C3E), flannelD = C(0x3A4828), flannelL = C(0x7E9258)
    let beard = C(0xA8A49C), beardD = C(0x7C7872), beardL = C(0xD0CCC4)
    let cap = C(0x8A3A26), capD = C(0x5E2418), capL = C(0xAE5236), mesh = C(0x9A8A66), meshD = C(0x6E6248)
    let swig = span(p.signature, 0.06, 0.94)
    let raise = swig < 0 ? 0 : swig < 0.18 ? Int(swig / 0.18 * 4) : swig > 0.82 ? Int((1 - swig) / 0.18 * 4) : 4
    let tipped = swig > 0.22 && swig < 0.72

    drawLegs(c, Look(leg: C(0x4A5A72)), step: p.step)
    drawBoots(c, C(0x8A6038), step: p.step, rows: 2)
    drawBoots(c, C(0x5E3E22), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: flannel), armRight: raise)

    // The flannel in the vest's open front and at the far cuff; the vest quilted in rows, lit on the near edge, its
    // pockets with flaps, the far side and the hem in shade.
    c.rect(18, 33, 20, 5, vest)
    huntPlaid(c, 25, 33, 6, 5, base: flannel, dark: flannelD, light: flannelL)
    for y in [34, 36] { c.rect(19, y, 5, 1, vestD); c.rect(32, y, 5, 1, vestD) }
    c.rect(24, 33, 1, 5, vestL); c.rect(31, 33, 1, 5, vestD); c.rect(19, 33, 4, 1, vestL)
    c.rect(20, 35, 3, 1, vestL); c.rect(33, 35, 3, 1, C(0x4A3C2E))
    c.rect(37, 33, 1, 5, vestD); c.rect(18, 37, 20, 1, vestD)
    c.rect(15, 35, 3, 1, flannelD)

    // The full grey beard: sideburns down from the cap, a moustache, and the beard over his chin and the top of his
    // chest, in strokes, lit on top.
    c.pattern(18, 27, [
        "BB................BB",
        "Bb................bB",
        "BB................BB",
        "BBb...............bB",
        "BBb....LLLLLL....bBB",
        "BBBdBBBLBBBBLBBBdBBb",
        ".BBdBBBdBBBBdBBBdBb.",
        "..BdBBBdBBBBdBBBdb..",
        "....BBBdBBBBdBBb....",
    ], ["B": beard, "b": beardD, "d": beardD, "L": beardL])

    // The cap: a curved rust-red front panel lit on the left, the mesh behind it, the band, the bill out front.
    c.pattern(17, 20, [
        "......MMMMFFFFFF.......",
        "....MmMmMFFFlFFFF......",
        "...MMMMMMFFlFFFFFF.....",
        "..MmMmMmMFFFFFFFFFF....",
        "..MMMMMMMFFFFFFFFFFF...",
        ".DDDDDDDDDDDDDDDDDDBBBBB",
        "...................bbbb.",
    ], ["M": mesh, "m": meshD, "F": cap, "l": capL, "D": capD, "B": C(0x6E2A1C), "b": C(0x3E1810)])
    c.rect(22, 28, 2, 1, beardD); c.rect(32, 28, 2, 1, beardD)

    if swig >= 0 {
        // The flask in his fist, up to his mouth, tipped back for the swig: a flat silver hip flask, its shoulders
        // curved in to a short neck and a black screw cap, a bright shine slanting across it and a brown leather band
        // round its middle.
        let hy = 33 - raise
        let pal: [Character: Px] = ["S": C(0xB4BAC4), "L": C(0xF4F6FA), "D": C(0x7E848E), "c": C(0x26282E),
                                    "B": C(0x6A4428), "b": C(0x8E5E36)]
        if tipped {
            // Tipped back, the cap to his lips.
            c.pattern(32, hy - 6, [
                ".......SSS",
                "......SLSSD",
                ".....SLSSDD",
                "....bBBBBD.",
                "...SSSLSD..",
                "..SSSLSD...",
                ".cSSSDD....",
                "cc.........",
            ], pal)
        } else {
            c.pattern(38, hy - 7, [
                "..cc..",
                ".SSSS.",
                "SLSSSD",
                "SSLSSD",
                "bBBBBB",
                "SSSLSD",
                "SSSSDD",
                ".SDDD.",
            ], pal)
        }
        c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 1, clawdShade)   // his fist round it
        return   // the shotgun leaning out of sight while he drinks
    }

    // The shotgun: two long barrels lit along the top, the rib between them, the action and trigger guard, and the
    // walnut stock running back from his fist under his arm, lit along its top, to the black butt plate.
    c.oy += p.gunY
    c.pattern(31, 30, [
        "...........BBBBBBBBBBBBBl",
        "..........KbbbbbbbbbbbbbK",
        ".....LLOOOKKk............",
        "...LLWWOOOW..............",
        ".kWWWWwWOW...............",
        "kkwwww...................",
    ], ["B": C(0x6A707C), "l": C(0xB0B6C2), "b": C(0x3A3E46), "K": C(0x2A2C32), "k": C(0x1A1A1E),
        "W": C(0x8A5430), "w": C(0x5E3418), "L": C(0xB07040), "O": clawdOrange])
}

// MARK: - Ellen Harvell

/// Ellen Harvell: who runs the Roadhouse, dark brown hair straight to her shoulders with a centre parting, a long
/// cream bar apron tied over a slate-blue flannel shirt, a bar towel hanging from its pocket, jeans and brown boots.
/// Fights with a pump shotgun. Signature: she racks it, the pump sliding back and forward and a spent red shell
/// spinning out.
private func drawEllenHarvell(_ c: PixelCanvas, _ p: Pose) {
    let flannel = C(0x3E5E6A), flannelD = C(0x26404C), flannelL = C(0x6A8C98)
    let apron = C(0xE2D8C2), apronD = C(0xBEB298), apronL = C(0xF4EEE0)
    let hair = C(0x3A2418), hairD = C(0x22140C), hairL = C(0x5C3C28)
    let k = span(p.signature, 0.08, 0.92)

    drawLegs(c, Look(leg: C(0x3A4A66)), step: p.step)
    drawBoots(c, C(0x5A3A24), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: flannel))

    // The flannel shirt round the apron, its collar points out at the neck.
    huntPlaid(c, 18, 33, 20, 5, base: flannel, dark: flannelD, light: flannelL)
    c.rect(37, 33, 1, 5, flannelD); c.rect(18, 37, 20, 1, flannelD); c.rect(15, 35, 3, 1, flannelD)
    // The apron: its bib over her chest, the straps to her shoulders, tied at the waist, the skirt hanging past her
    // hips with the four legs below it; a pocket with the striped bar towel hanging out, a fold down the skirt.
    c.rect(23, 33, 10, 5, apron); c.rect(22, 33, 1, 1, apron); c.rect(33, 33, 1, 1, apronD)
    c.rect(23, 33, 1, 4, apronL); c.rect(32, 33, 1, 5, apronD)
    c.rect(18, 36, 20, 1, apronD); c.rect(23, 36, 10, 1, apron); c.px(37, 36, C(0x9E9278))
    if seatedPose {
        c.rect(22, 38, 12, 1, apron)
    } else {
        c.rect(22, 38, 12, 2, apron); c.rect(22, 40, 12, 1, apronD)
        c.px(22, 38, apronL); c.rect(27, 38, 1, 2, apronD); c.rect(33, 38, 1, 2, apronD)
    }
    c.rect(28, 35, 4, 1, apronD)                                                         // the pocket's edge
    c.rect(29, 36, 2, 3, C(0xF4F4EE)); c.px(29, 37, C(0xB8302A)); c.px(30, 37, C(0xB8302A))   // the bar towel

    // Dark hair, straight, lying flat on top with the centre parting running down to her brow, combed away from it
    // either side in lit strokes, and hanging straight to her shoulders, the ends flicking out.
    c.pattern(16, 22, [
        "......HHHHHdHHHHHH......",
        "...HHHlHHHHdHHHHlHHH....",
        "..HHlHHHHHhdhHHHHHlHHH..",
        "..HHHHHHHhhdhhHHHHHHHd..",
        "..HHHHHh.........hHHHHd.",
        "..HHHH............HHHd..",
        "..HHH..............HHd..",
        "..HlH..............dHd..",
        "..HHd..............dHH..",
        "..HHd..............dHd..",
        ".HHd................dHH.",
        ".Hd..................dd.",
    ], ["H": hair, "d": hairD, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The pump shotgun at her hip: the dark receiver, the barrel and the magazine tube under it, the wooden pump, and
    // the stock running back from her fist under her arm, lit along its top, to the black butt plate. Racking it, she
    // lifts it a little and the pump slides back and forward again.
    c.oy += p.gunY
    var back = 0
    if k >= 0 {
        c.oy -= 2
        back = k > 0.2 && k < 0.36 ? 3 : k >= 0.36 && k < 0.44 ? 1 : 0
    }
    c.pattern(31, 30, [
        ".........KKKGGGGGGGGGGGl",
        "........KKKKK.....TTTTT.",
        "....LLLWW.KK............",
        "..LLWWWWWW..............",
        ".kWWWWww................",
        "kkwwww..................",
    ], ["K": C(0x26262C), "G": C(0x4A4E58), "l": C(0x8A8F9C), "T": C(0x363A42), "W": C(0x8A5430),
        "w": C(0x5E3418), "L": C(0xB07040), "k": C(0x1A1A1E)])
    c.rect(46 - back, 31, 5, 1, C(0x7A4A2A)); c.px(46 - back, 31, C(0xA06A3C))
    c.rect(38, 32, 3, 3, clawdOrange)
    if k > 0.22 && k < 0.62 {
        // The spent shell, spinning up and back out of the port.
        let f = (k - 0.22) / 0.4
        let x = 42 - Int(f * 10), y = 29 - Int(sin(f * .pi) * 8)
        let flat = Int(f * 8) % 2 == 0
        c.rect(x, y, flat ? 2 : 1, flat ? 1 : 2, C(0xC8302A)); c.px(x + (flat ? 2 : 0), y + (flat ? 0 : 2), C(0xD8B048))
    }
}
