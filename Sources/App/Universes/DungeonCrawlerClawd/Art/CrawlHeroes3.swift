import Foundation

// Heroes, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// Florin and Ifechi, the Desperado Club's bouncers and dancers, the goblin shamankas, and the show's side.

let crawlHeroes3: [CrawlHero: Persona] = [
    .florin: Persona(name: "Florin", weapon: .blaster, shot: .bullet, muzzle: (57, 34),
                     headTop: 24, signature: 2.8, callout: "Good.", draw: drawFlorin),
    .ifechi: Persona(name: "Ifechi", weapon: .none, headTop: 24, signature: 3.2, draw: drawIfechi),
    .sledge: Persona(name: "The Sledge", weapon: .saber, armoured: true, bulk: 4, headTop: 5, signature: 3.0,
                     callout: "He buy spell with own money.", draw: drawSledge),
    .bomo: Persona(name: "Bomo", weapon: .saber, armoured: true, bulk: 5, headTop: 15, signature: 2.6, draw: drawBomo),
    .doctorBones: Persona(name: "Doctor Bones", weapon: .lightning,
                          magic: Magic(core: C(0xFFF4C0), glow: C(0xF0B820), jagged: false, notes: true),
                          pivot: (45, 32), headTop: 20, signature: 3.0, draw: drawDoctorBones),
    .splashZone: Persona(name: "Splash Zone", weapon: .blaster, shot: .beam(core: C(0xE0F4FF), glow: C(0x3A9AF0)),
                         muzzle: (43, 34), handGun: false, headTop: 24, signature: 3.2, draw: drawSplashZone),
    .rory: Persona(name: "Rory", weapon: .blaster, shot: .energy(core: C(0xE0F0FF), glow: C(0x3A7AF0)),
                   muzzle: (43, 17), headTop: 20, signature: 2.8, draw: drawRory),
    .lorelai: Persona(name: "Lorelai", weapon: .blaster, shot: .energy(core: C(0xF0E4FF), glow: C(0x9A4AF0)),
                      muzzle: (43, 17), headTop: 15, signature: 2.8, draw: drawLorelai),
    .odette: Persona(name: "Odette", weapon: .none, headTop: 17, signature: 3.4, draw: drawOdette),
    .zev: Persona(name: "Zev", weapon: .none, headTop: 10, signature: 3.0, draw: drawZev),
]

// MARK: - Shared bits

/// The goblin shamankas' staff, held upright in the near hand (its foot on the ground), a pineapple on top: a ripe
/// yellow fruit in a criss-cross of darker scales, its spiky green crown above. `angle` tilts or spins it round the
/// hand (-90 upright); the pineapple is always on the upper end of a still staff.
private func crawlH3Staff(_ c: PixelCanvas, angle: Double = -90) {
    let wood = C(0x6A4A2A), woodL = C(0x8A643A)
    let hand = (x: 41.5, y: 34.5)
    let top = crawlReach(hand, angle, 15), foot = crawlReach(hand, angle + 180, 8)
    c.glowLine(foot.x, foot.y, top.x, top.y, core: wood, glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    if angle == -90 { c.rect(41, 22, 1, 20, woodL) }
    crawlH3Pineapple(c, Int(top.x.rounded()), Int(top.y.rounded()))
}

/// A pineapple centred at (`x`, `y`): a 5×6 fruit with its crown of leaves above.
private func crawlH3Pineapple(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.pattern(x - 3, y - 7, [
        ".g.g.g.",
        "..ggg..",
        ".gGgGg.",
        "..YyY..",
        ".YyYyY.",
        ".YYyYY.",
        ".yYyYy.",
        ".YyYyY.",
        "..yyy..",
    ], ["g": C(0x4AA83A), "G": C(0x2E7A28), "Y": C(0xF0C838), "y": C(0xB88A1E)])
}

/// A stone fist, 4×3, centred on (`x`, `y`): lit on the top left, the knuckles picked out, shaded underneath.
private func crawlH3StoneFist(_ c: PixelCanvas, _ x: Int, _ y: Int, _ a: Double,
                              _ stone: Px, _ stoneD: Px, _ stoneL: Px) {
    c.rect(x - 1, y - 1, 4, 3, stone.alpha(a))
    c.rect(x - 1, y - 1, 4, 1, stoneL.alpha(a))
    c.px(x, y, stoneD.alpha(a)); c.px(x + 2, y, stoneD.alpha(a))
    c.rect(x - 1, y + 1, 4, 1, stoneD.alpha(a))
}

// MARK: - Florin

/// Florin: a crocodile, Clawd in a green scaly hide: his eyes on two bumps on top of his head, a long toothy snout
/// pushed out in front, a ridged tail lying out behind. Combat gear: a black plate carrier with three tan pouches, and
/// black combat boots. His endless shotgun: a black barrel and magazine tube, a wooden pump and stock. Signature: he
/// racks it, the pump going back and forward, and a spent red shell spins out.
private func drawFlorin(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x5E7E3A), hideD = C(0x42602A), hideL = C(0x80A050), belly = C(0xD8D09A)
    let vest = C(0x2E3034), vestD = C(0x1C1E22), vestL = C(0x4A4E56), pouch = C(0x8A7A50), pouchD = C(0x645834)
    let steel = C(0x34363E), steelL = C(0x7A808C), wood = C(0x7A4A26), woodL = C(0x9E6838)
    let tooth = C(0xF4F0E0), eye = C(0xE8C030)
    let s = p.signature ?? -1
    // The rack: the pump slides back 3 pixels from 0.2 to 0.38, forward again by 0.55; the shell flies 0.36 to 0.8.
    var slide = 0
    if s > 0.2 && s < 0.38 { slide = Int(((s - 0.2) / 0.18 * 3).rounded()) }
    if s >= 0.38 && s < 0.55 { slide = 3 - Int(((s - 0.38) / 0.17 * 3).rounded()) }

    // 1. Scaly legs and black combat boots, a lit toe on each.
    drawLegs(c, Look(leg: hide), step: p.step)
    drawBoots(c, C(0x1E1E22), step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, bottom - 1, C(0x4A4A52))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail, lying out behind: thick at the body, tapering to a point, a row of dark ridges along its top.
    let sway = sin(p.lt * 1.2)
    for x in 5...17 {
        let f = Double(17 - x) / 12
        let top = 30 + Int((f * 5 + sway * f).rounded())
        let bottom = 37 - Int((f * 1.4).rounded())
        c.rect(x, top, 1, max(1, bottom - top + 1), hide)
        c.px(x, bottom, hideD)
        if x % 2 == 1 { c.px(x, top - 1, hideD) }
    }

    // 4. The body in green hide, lit along the top and the left; a few scale strokes on the head.
    drawBody(c, Look(body: hide, shade: hideD, arm: hide, eye: nil))
    c.rect(18, 26, 20, 1, hideL); c.rect(18, 26, 1, 6, hideL)
    for (x, y) in [(21, 28), (26, 29), (24, 27)] { c.rect(x, y, 2, 1, hideD) }

    // 5. The eyes on their bumps on top of the head: yellow, a black slit, under a heavy lid.
    for x in [20, 30] {
        c.rect(x, 24, 5, 2, hide); c.rect(x + 1, 23, 3, 1, hideL)
        c.rect(x + 1, 25, 3, 2, eye); c.px(x + 2, 25, ink); c.px(x + 2, 26, ink)
        c.rect(x + 1, 24, 3, 1, hideD)
    }

    // 6. The plate carrier: black over his chest, lit along its top, the far side in shade, three tan pouches.
    c.rect(18, 31, 20, 6, vest)
    c.rect(18, 31, 20, 1, vestL); c.rect(36, 32, 2, 5, vestD)
    for x in [20, 25, 30] {
        c.rect(x, 33, 4, 3, pouch); c.rect(x, 33, 4, 1, pouchD)
    }

    // 7. The snout, pushed out in front: the upper jaw lit along its top, a nostril bump at the end, a row of teeth
    //    in the long grin, the lower jaw with its pale underside.
    c.pattern(34, 26, [
        "............hh..",
        ".LLLLLLLLLLLLLL.",
        "SSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSd",
        "SSSmTmTmTmTmTmTm",
        "SSSSSSSSSSSSSSd.",
        "..BBBBBBBBBBBB..",
    ], ["S": hide, "L": hideL, "h": hide, "d": hideD, "m": ink, "T": tooth, "B": belly])

    // 8. The shotgun, under his snout: the wooden stock back against his side, the black receiver and barrel, the
    //    magazine tube under it, the wooden pump on that (racked back in the signature), his scaly hand on the grip.
    c.oy += p.gunY
    c.rect(32, 35, 7, 2, wood); c.rect(32, 35, 7, 1, woodL)
    c.rect(39, 34, 6, 3, steel); c.rect(39, 34, 6, 1, steelL)
    c.rect(45, 34, 12, 1, steelL); c.px(56, 34, C(0xB4BAC4))
    c.rect(45, 35, 9, 1, steel)
    c.rect(47 - slide, 35, 5, 2, wood); c.rect(47 - slide, 35, 5, 1, woodL)
    c.rect(38, 35, 3, 3, hide); c.px(38, 35, hideL); c.rect(38, 37, 3, 1, hideD)

    // 9. The spent shell, spinning up and back out of the port, red with a brass base.
    if s > 0.36 && s < 0.8 {
        let k = (s - 0.36) / 0.44
        let x = 42 - Int((k * 10).rounded()), y = 32 - Int((sin(k * .pi) * 9).rounded()) + Int(k * 8)
        if Int(k * 8) % 2 == 0 {
            c.rect(x, y, 2, 1, C(0xC8302A)); c.px(x + 2, y, C(0xE0B040))
        } else {
            c.rect(x, y, 1, 2, C(0xC8302A)); c.px(x, y + 2, C(0xE0B040))
        }
    }
}

// MARK: - Ifechi

/// Ifechi: Clawd bald, her round head with a shine on top, calm brows; a red shirt under an open khaki vest with its
/// pockets, dark trousers and boots. In her near hand, by its handle, a white medic bag with a red cross. She doesn't
/// fight: she heals. Signature: she opens the bag and a green heal glows up out of it and round her, little green
/// crosses floating up.
private func drawIfechi(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0xC42E2E), shirtD = C(0x922020), shirtL = C(0xE05048)
    let vest = C(0x7A7258), vestD = C(0x5A5440), vestL = C(0x9A9276)
    let bag = C(0xF0ECE4), bagD = C(0xC4C0B8), cross = C(0xD02A2A)
    let brow = C(0x4A2818), shine = C(0xF0A486)
    let s = p.signature ?? -1
    let open = s > 0.15 && s < 0.85
    let glow = open ? sin((s - 0.15) / 0.7 * .pi) : 0

    // 1. Dark trousers and boots.
    drawLegs(c, Look(leg: C(0x3A3E48)), step: p.step)
    drawBoots(c, C(0x2A2420), step: p.step, rows: 2)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The heal's glow behind her, soft green round her whole body.
    if glow > 0 {
        for r in stride(from: 16, through: 12, by: -2) {
            c.ellipse(29, 31, r + 2, r - 2, C(0x6AF08A, 0.07 * glow))
        }
    }

    // 4. The body, her far arm in the red shirt; her head rounded at the top, bald, a shine on it; calm brows.
    drawBody(c, Look(arm: shirt))
    c.rect(20, 25, 16, 1, clawdOrange); c.rect(23, 24, 10, 1, clawdOrange)
    c.rect(24, 24, 3, 1, shine); c.rect(21, 25, 3, 1, shine); c.px(20, 26, shine)
    c.rect(21, 27, 3, 1, brow); c.rect(32, 27, 3, 1, brow)
    c.rect(26, 31, 3, 1, clawdShade)   // a small smile
    c.rect(15, 35, 3, 1, shirtD)

    // 5. The red shirt, a lit fold on the left and a V at the neck; over it the open vest, khaki, lit along the top,
    //    a pocket on each side.
    c.rect(18, 32, 20, 6, shirt)
    c.rect(19, 33, 1, 4, shirtL); c.rect(18, 37, 20, 1, shirtD)
    c.pattern(26, 32, ["O..O", ".OO."], ["O": clawdOrange])
    c.rect(18, 32, 6, 6, vest); c.rect(32, 32, 6, 6, vest)
    c.rect(18, 32, 6, 1, vestL); c.rect(32, 32, 6, 1, vestL); c.rect(37, 33, 1, 5, vestD)
    c.rect(19, 35, 3, 1, vestD); c.rect(33, 35, 3, 1, vestD)
    c.rect(18, 37, 6, 1, vestD); c.rect(32, 37, 6, 1, vestD)

    // 6. The near hand and the medic bag hanging from it: white, its lid a shade darker, the red cross on its side;
    //    in the signature the lid flips up and the green glow pours out of it.
    c.rect(38, 33, 3, 3, shirt); c.rect(38, 35, 3, 1, shirtD)
    c.rect(40, 34, 2, 2, clawdOrange)
    c.rect(41, 36, 1, 1, C(0x3A3630)); c.rect(44, 36, 1, 1, C(0x3A3630)); c.rect(41, 35, 4, 1, C(0x3A3630))
    c.rect(39, 37, 8, 5, bag); c.rect(39, 41, 8, 1, bagD); c.rect(46, 37, 1, 5, bagD)
    c.rect(42, 38, 2, 3, cross); c.rect(41, 39, 4, 1, cross)
    if open {
        c.rect(39, 36, 1, 1, bagD); c.rect(38, 33, 1, 3, bagD)   // the lid, flipped back
        let n = Int(p.lt * 12)
        for i in 0..<4 {
            let k = ((s - 0.15) / 0.7 * 2 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
            let x = 40 + (i * 5 + n / 3) % 6, y = 36 - Int(k * 18)
            let a = glow * (1 - k)
            c.px(x, y, C(0x9AFFB0, a)); c.px(x - 1, y, C(0x6AF08A, a * 0.8)); c.px(x + 1, y, C(0x6AF08A, a * 0.8))
            c.px(x, y - 1, C(0x6AF08A, a * 0.8)); c.px(x, y + 1, C(0x6AF08A, a * 0.8))
        }
        c.rect(40, 34, 6, 2, C(0xA8FFC0, 0.6 * glow))
    }
}

// MARK: - The Sledge

/// The Sledge: a seven-foot stone bouncer, Clawd grown huge in pale grey granite, a square head over a great chest, a
/// heavy brow and small eyes, a crack or two. A black tuxedo with a white shirt front and a bow tie, a brown cowboy hat
/// with a dark band and a curled brim, and a pink feather boa slung round his shoulders, its ends hanging down his
/// front. He fights with his stone fists. Signature: he adjusts the cowboy hat, a finger and thumb on its brim.
private func drawSledge(_ c: PixelCanvas, _ p: Pose) {
    let stone = C(0xA8A49C), stoneD = C(0x7C786E), stoneL = C(0xCCC8BE), crack = C(0x5A564E)
    let tux = C(0x1C1C22), tuxL = C(0x34343E), shirt = C(0xF2F0EA), shirtD = C(0xC8C6BE)
    let hat = C(0x8A5A32), hatD = C(0x603E1E), hatL = C(0xAC7848), band = C(0x2E1C10)
    let boa = C(0xF878BC), boaD = C(0xCC4E92), boaL = C(0xFFB2DA)
    let s = p.signature ?? -1
    let tipping = s > 0.12 && s < 0.88
    let tug = s > 0.35 && s < 0.65 ? 1 : 0

    // 1. Black trousers, bare stone feet.
    drawLegs(c, Look(leg: tux), step: p.step)
    drawBoots(c, stoneD, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, in its sleeve, a stone fist at the end.
    c.rect(13, 24, 4, 10, tux); c.rect(13, 24, 1, 10, tuxL)
    crawlH3StoneFist(c, 14, 35, 1, stone, stoneD, stoneL)

    // 4. The tuxedo jacket over the great chest: lit on the left, the far side in shade; the white shirt front in a V
    //    with two studs, the black bow tie at the neck.
    c.rect(16, 22, 24, 16, tux)
    c.rect(16, 22, 1, 16, tuxL); c.rect(17, 22, 5, 1, tuxL); c.rect(39, 22, 1, 16, C(0x111116))
    c.pattern(23, 22, [
        "WWWWWWWWWW",
        ".WWWWWWWW.",
        ".WWWWWWWW.",
        "..WWWWWW..",
        "..WWWsWW..",
        "...WWWW...",
        "...WWsW...",
        "....WW....",
        "....WW....",
    ], ["W": shirt, "s": tux])
    c.rect(24, 23, 1, 3, shirtD)
    c.pattern(25, 22, ["BB..BB", "BBBBBB", "BB..BB"], ["B": tux])
    c.rect(19, 30, 2, 8, tuxL)   // a fold in the jacket

    // 5. The square stone head: lit on top and the left, a heavy brow, small dark eyes, a broad flat nose, a grim
    //    mouth, two cracks.
    c.rect(20, 11, 16, 11, stone)
    c.rect(20, 11, 16, 1, stoneL); c.rect(20, 11, 1, 11, stoneL); c.rect(35, 12, 1, 10, stoneD); c.rect(21, 21, 15, 1, stoneD)
    c.rect(21, 14, 14, 2, stoneD); c.rect(21, 14, 14, 1, stoneL)
    c.rect(23, 16, 2, 2, ink); c.rect(31, 16, 2, 2, ink)
    c.rect(27, 17, 2, 2, stoneD)
    c.rect(25, 19, 7, 1, crack)
    c.pattern(21, 12, [".c", "c.", "c."], ["c": crack]); c.pattern(33, 17, ["c.", ".c"], ["c": crack])

    // 6. The pink feather boa slung round his shoulders, fluffy at its edges, its ends hanging down his front either
    //    side of the shirt.
    c.pattern(15, 21, [
        ".LLlLL.L.........L.LlLLL.",
        "LBBBBBBBl.......LBBBBBBBB",
        "BBDBBDBBBL.....LBBDBBBDBB",
        ".BBBBBBBBB.....BBBBBBBB.",
        "....LBBBB.......BBBBL...",
        ".....BBDB.......BDBB....",
        "....LBBBB.......BBBBL...",
        ".....BBBD.......DBBB....",
        "....LBBBB.......BBBB....",
        ".....BDBB.......BBDB....",
        "......BB.........BB.....",
    ], ["B": boa, "D": boaD, "L": boaL, "l": boaL])

    // 7. The cowboy hat: the crown with its dent, a dark band, the wide brim curled up at both ends. Tugged a
    //    pixel forward in the middle of the signature.
    c.ox += tug
    c.pattern(16, 4, [
        "........HHHH..HHHH........",
        ".......HHlHHHHHHHHH.......",
        ".......HlHHHHHHHHHHd......",
        ".......HlHHHHHHHHHHd......",
        ".......bbbbbbbbbbbbb......",
        ".h...HHHHHHHHHHHHHHHHd..h.",
        "..hHHHHHHHHHHHHHHHHHHHHh..",
    ], ["H": hat, "l": hatL, "d": hatD, "b": band, "h": hatD])
    c.ox -= tug
    c.rect(20, 11, 16, 1, stoneL)   // no gap between the brim and his head

    // 8. The near arm: the sleeve down from the shoulder and the stone fist; up at the brim in the signature, or
    //    punching.
    if let a = p.melee {
        c.rect(38, 23, 4, 10, tux); c.rect(38, 23, 1, 10, tuxL)
        crawlPunch(c, angle: a, trail: p.trail, arm: tux, reach: 6) { x, y, al in
            crawlH3StoneFist(c, x, y, al, stone, stoneD, stoneL)
        }
    } else if tipping {
        c.rect(38, 23, 4, 6, tux); c.rect(38, 23, 1, 6, tuxL)
        crawlBar(c, (40, 26), -80, from: 0, to: 13, tux, r: 1.6)
        crawlH3StoneFist(c, 41 + tug, 11, 1, stone, stoneD, stoneL)
    } else {
        c.rect(38, 23, 4, 11, tux); c.rect(38, 23, 1, 11, tuxL); c.rect(38, 33, 4, 1, shirt)
        crawlH3StoneFist(c, 40, 35, 1, stone, stoneD, stoneL)
    }
}

// MARK: - Bomo

/// Bomo: a stone bouncer, squat and wide where the Sledge is tall, in rust-brown sandstone: a broad bald stone head
/// sat straight on his shoulders, a heavy brow, small eyes, a wide jaw with a chip out of it. A black tuxedo with a
/// white shirt front and a bow tie. No hat, no boa. He fights with his stone fists. Signature: he cracks his knuckles,
/// fist in palm in front of his chest, little puffs of grit flying off.
private func drawBomo(_ c: PixelCanvas, _ p: Pose) {
    let stone = C(0xB07A52), stoneD = C(0x84583A), stoneL = C(0xD09A70), crack = C(0x5E3A24)
    let tux = C(0x1C1C22), tuxL = C(0x34343E), shirt = C(0xF2F0EA), shirtD = C(0xC8C6BE)
    let s = p.signature ?? -1
    let cracking = s > 0.1 && s < 0.9
    let pop = cracking && Int(s * 14) % 3 == 0

    // 1. Black trousers, bare stone feet.
    drawLegs(c, Look(leg: tux), step: p.step)
    drawBoots(c, stoneD, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, a thick sleeve, its stone fist (across his chest in the signature).
    if !cracking {
        c.rect(11, 26, 5, 9, tux); c.rect(11, 26, 1, 9, tuxL)
        crawlH3StoneFist(c, 13, 35, 1, stone, stoneD, stoneL)
    }

    // 4. The broad tuxedo jacket: lit on the left, the shirt front and the bow tie.
    c.rect(14, 24, 28, 14, tux)
    c.rect(14, 24, 1, 14, tuxL); c.rect(15, 24, 6, 1, tuxL); c.rect(41, 24, 1, 14, C(0x111116))
    c.pattern(23, 24, [
        "WWWWWWWWWW",
        ".WWWWWWWW.",
        "..WWWsWW..",
        "..WWWWWW..",
        "...WWsW...",
        "...WWWW...",
        "....WW....",
    ], ["W": shirt, "s": tux])
    c.rect(24, 25, 1, 2, shirtD)
    c.pattern(25, 24, ["BB..BB", "BBBBBB", "BB..BB"], ["B": tux])
    c.rect(17, 30, 2, 8, tuxL); c.rect(36, 30, 2, 8, tuxL)

    // 5. The head: wide and flat-topped, sat on his shoulders: lit on top and the left, the heavy brow, small eyes,
    //    the wide jaw with its chip, a crack down the cheek.
    c.rect(16, 18, 2, 3, stoneD); c.rect(38, 18, 2, 3, stoneD)        // the ears, little stone knobs
    c.rect(18, 16, 20, 8, stone); c.rect(19, 15, 18, 1, stone); c.rect(21, 14, 14, 1, stoneL)
    c.rect(19, 15, 18, 1, stoneL); c.rect(18, 16, 1, 7, stoneL); c.rect(37, 16, 1, 8, stoneD)
    c.rect(23, 15, 4, 1, C(0xE8BC94))                                  // the shine on his bald dome
    c.rect(19, 18, 18, 1, stoneD)
    c.rect(22, 19, 3, 2, ink); c.rect(31, 19, 3, 2, ink)
    c.rect(27, 20, 2, 2, stoneD)
    c.rect(24, 22, 9, 1, crack)
    c.rect(18, 23, 20, 1, stoneD)
    c.pattern(20, 19, ["c", "c", ".c"], ["c": crack]); c.pattern(34, 14, ["c", ".c"], ["c": crack])

    // 6. The near arm and fist; punching; or, in the signature, fist pressed into the far palm in front of his
    //    chest, the knuckles popping with puffs of grit.
    if let a = p.melee {
        c.rect(39, 26, 4, 7, tux); c.rect(39, 26, 1, 7, tuxL)
        crawlPunch(c, angle: a, trail: p.trail, arm: tux, reach: 6) { x, y, al in
            crawlH3StoneFist(c, x, y, al, stone, stoneD, stoneL)
        }
    } else if cracking {
        let push = pop ? 1 : 0
        c.rect(39, 26, 4, 6, tux); c.rect(39, 26, 1, 6, tuxL)
        c.rect(31, 29, 8, 3, tux)                                       // the far forearm, across
        crawlH3StoneFist(c, 33, 30, 1, stone, stoneD, stoneL)           // the far palm
        crawlH3StoneFist(c, 37 - push, 29, 1, stone, stoneD, stoneL)    // the near fist in it
        if pop {
            for (x, y) in [(42, 27), (44, 29), (42, 32), (35, 26)] { c.px(x, y, C(0xE8D8C0)) }
            c.px(45, 26, C(0xE8D8C0, 0.6)); c.px(46, 31, C(0xE8D8C0, 0.6))
        }
    } else {
        c.rect(39, 26, 4, 8, tux); c.rect(39, 26, 1, 8, tuxL); c.rect(39, 33, 4, 1, shirt)
        crawlH3StoneFist(c, 40, 35, 1, stone, stoneD, stoneL)
    }
}

// MARK: - Doctor Bones

/// Doctor Bones: a skeleton DJ, Clawd in black with his bones in white over it: a big round skull for a face, its
/// eye sockets dark with a gold glint in each, a grin of teeth, the ribs and spine down his front, a bone in each leg.
/// A gold crown with a red gem on his skull. In his near hand, a little turntable: a grey deck, a black record with a
/// gold label. His music is gold. Signature: he scratches the record back and forth, nodding along.
private func drawDoctorBones(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1E1C24), blackL = C(0x302E38)
    let bone = C(0xEEEAE0), boneD = C(0xBCB6A8)
    let gold = C(0xF0C840), goldD = C(0xB88A20), gem = C(0xD83A4A)
    let deck = C(0x4A4A54), deckL = C(0x6A6A76), deckD = C(0x2E2E36), record = C(0x0E0E12), groove = C(0x2A2A30)
    let s = p.signature ?? -1
    let scratching = s > 0.1 && s < 0.9
    let nod = scratching && Int(s * 12) % 2 == 0 ? 1 : 0
    let playing = p.zap == true

    // 1. The legs in black, a white bone down each with a knob at the knee.
    drawLegs(c, Look(leg: black), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, bottom - 37, bone)
            c.rect(lx, 39, 2, 1, bone)
            c.rect(lx, bottom, 2, 1, bone)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in black, lit a little on the left; his bony arms.
    drawBody(c, Look(body: black, shade: C(0x141218), arm: bone, eye: nil))
    c.rect(18, 26, 1, 11, blackL)
    c.rect(15, 35, 3, 1, boneD)

    // 4. The ribs: the spine down the middle, three ribs either side curving round.
    c.rect(27, 34, 2, 4, boneD)
    for y in [34, 36] {
        c.rect(21, y, 5, 1, bone); c.rect(30, y, 5, 1, bone)
        c.px(20, y + 1, bone); c.px(35, y + 1, bone)
    }

    // 5. The skull, nodding along in the signature: big and round, deep eye sockets with a gold glint, the nose
    //    hole, the grin of teeth.
    c.oy += nod
    c.pattern(18, 24, [
        "....SSSSSSSSSS....",
        "..SSSSSSSSSSSSSS..",
        ".SSSSSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSSs",
        "SSEEEESSSSSSEEEESs",
        "SSEEEESSSSSSEEEESs",
        "SSEEEESSSSSSEEEESs",
        "SSSEESSSSNNSSEESSs",
        ".SSSSSSSSNNSSSSSs.",
        "..sSSSSSSSSSSSSs..",
        "...TtTtTtTtTtTt...",
    ], ["S": bone, "s": boneD, "E": record, "N": C(0x3A3640), "T": bone, "t": record])
    c.px(22, 29, gold); c.px(32, 29, gold)

    // 6. The crown on his skull: gold, three points, a red gem in front, sat straight on the bone.
    c.pattern(21, 19, [
        "g...g...g...",
        "G..GGG..G...",
        "GG.GGG.GG...",
        "GGGGGEGGGG..",
        "gggggggggg..",
    ], ["G": gold, "g": goldD, "E": gem])
    c.rect(22, 24, 9, 1, bone)
    c.oy -= nod

    // 7. The near hand and the little turntable on it: the grey deck lit along its top, the black record with its
    //    grooves and gold label (turning), the silver tone arm, his bony fingers on the record, scratching it back
    //    and forth in the signature.
    c.rect(38, 33, 3, 3, bone); c.rect(38, 35, 3, 1, boneD)
    c.rect(39, 34, 11, 3, deck); c.rect(39, 34, 11, 1, deckL); c.rect(39, 36, 11, 1, deckD)
    c.rect(41, 32, 7, 2, record); c.rect(42, 31, 5, 1, record)
    c.rect(42, 32, 5, 1, groove)
    let spin = Int(p.lt * (playing ? 16 : 6)) % 3
    c.px(43 + spin, 32, gold)
    c.rect(48, 31, 1, 3, C(0xC8CCD4)); c.px(47, 31, C(0xC8CCD4))
    let wiggle = scratching ? (Int(s * 30) % 2 == 0 ? -1 : 1) : 0
    c.rect(43 + wiggle, 30, 2, 2, bone); c.px(43 + wiggle, 30, boneD)
    if scratching && Int(s * 30) % 3 != 0 {
        c.px(40 + wiggle, 28, C(0xFFF4C0, 0.8)); c.px(39 + wiggle, 27, C(0xFFF4C0, 0.6))
        c.px(47 - wiggle, 28, C(0xFFF4C0, 0.8)); c.px(48 - wiggle, 27, C(0xFFF4C0, 0.6))
    }
}

// MARK: - Splash Zone

/// Splash Zone: an otter, Clawd in sleek brown fur, a pale cream face and chest, small round ears, a black nose and
/// whiskers, a thick tapering tail out behind; a black leather vest hanging open with a silver stud on each side, and
/// little red boots. A water mage: his jet of water is blue. Signature: the Wet Spot, a spray of water arcing out all
/// round him and a puddle at his feet.
private func drawSplashZone(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x7A5232), furD = C(0x5A3A22), furL = C(0x9A6C44), cream = C(0xE6CCA4), creamD = C(0xC4A87E)
    let vest = C(0x2A2426), vestL = C(0x4A3E42), stud = C(0xC8CCD4)
    let boot = C(0xC8302A), bootD = C(0x8E1E1A), bootL = C(0xE85A48)
    let water = C(0x4AA8F0), waterL = C(0xB0E0FF)
    let s = p.signature ?? -1
    let spray = s > 0.1 && s < 0.9 ? (s - 0.1) / 0.8 : -1.0

    // 1. Furry legs and little red boots, a lit cuff on top.
    drawLegs(c, Look(leg: fur), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 1, bootL); c.rect(lx, bottom, 2, 1, bootD)
        }
    }

    // 2. The puddle of the Wet Spot, under his feet.
    if spray > 0 {
        let w = Int(min(1, spray * 3) * 16)
        c.rect(28 - w, 44, w * 2, 1, C(0x4AA8F0, 0.55)); c.rect(30 - w / 2, 44, w / 2, 1, C(0xB0E0FF, 0.6))
    }

    // 3. The breath.
    c.oy += p.breathe

    // 4. The tail: thick at the root, tapering, curving up a little at the tip, lit along its top.
    for x in 7...17 {
        let f = Double(17 - x) / 10
        let top = 32 + Int((f * 3).rounded()) - Int((f * f * 3).rounded())
        let bottom = 37 - Int((f * 2).rounded())
        c.rect(x, top, 1, max(1, bottom - top + 1), fur)
        c.px(x, top, furL); c.px(x, bottom, furD)
    }

    // 5. The body in brown fur, lit along the top, short fur strokes; the small round ears.
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil))
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 8, furL)
    for (x, y) in [(20, 28), (35, 29), (21, 31)] { c.rect(x, y, 2, 1, furD) }
    c.pattern(18, 24, [".FF.", "FDDF"], ["F": fur, "D": furD]); c.pattern(33, 24, [".FF.", "FDDF"], ["F": fur, "D": furD])

    // 6. The face: dark eyes with a glint, the cream muzzle with its black nose, the whiskers, the cream running
    //    down his chest.
    c.rect(22, 28, 2, 2, ink); c.px(22, 28, C(0xFFFFFF))
    c.rect(32, 28, 2, 2, ink); c.px(32, 28, C(0xFFFFFF))
    c.pattern(23, 29, [
        "...nnnn...",
        ".CCCnnCCC.",
        "CCCCCCCCCC",
        ".CCCcCcCC.",
        "..CCCCCC..",
    ], ["C": cream, "c": creamD, "n": ink])
    c.rect(24, 34, 8, 4, cream); c.rect(24, 37, 8, 1, creamD)

    // 7. The black leather vest, hanging open either side of the chest: lit on the left, a silver stud each side.
    c.pattern(18, 31, [
        "LLLL..............LL",
        "LVVVV............VVV",
        "LVVVV...........VVVV",
        "LVVVVV.........VVVVV",
        "LVVVVV.........VVVVV",
        "LVVVVV.........VVVVV",
        "LVVVVV.........VVVVV",
    ], ["V": vest, "L": vestL])
    c.px(22, 34, stud); c.px(33, 34, stud)
    // The whiskers, out from the muzzle.
    for y in [30, 31] { c.rect(19, y, 4, 1, C(0xF4F0E8)); c.rect(33, y, 4, 1, C(0xF4F0E8)) }

    // 8. The near paw: a little ball of water swirling in it when he fires.
    c.rect(38, 33, 3, 3, fur); c.px(38, 33, furL); c.rect(38, 35, 3, 1, furD)
    if p.fire != nil || p.ready {
        c.rect(41, 33, 2, 2, water); c.px(41, 33, waterL)
    }

    // 9. The Wet Spot: water spraying up and out all round him in arcs, droplets falling back.
    if spray > 0 {
        for i in 0..<10 {
            let k = (spray * 2.4 + Double(i) / 10).truncatingRemainder(dividingBy: 1)
            let side = i % 2 == 0 ? -1.0 : 1.0
            let reach = 8 + Double(i % 5) * 3
            let x = 28 + side * (6 + k * reach)
            let y = 30 - sin(k * .pi) * (10 + Double(i % 3) * 3) + k * 10
            let col = i % 3 == 0 ? waterL : water
            let ix = Int(x.rounded()), iy = Int(y.rounded())
            c.px(ix, iy, col); c.px(ix, iy + 1, col.alpha(0.6))
        }
    }
}

// MARK: - Rory

/// Rory: a goblin shamanka, Clawd in green goblin skin under a black hooded robe that falls to the ground: big
/// pointed ears out through the hood, yellow eyes, a hooked nose, a red forked tongue flicking out. Her staff has a
/// pineapple on top; her anguish magic flies from it in blue. Signature: she twirls the pineapple staff.
private func drawRory(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x6E9A48), skinD = C(0x507A34), skinL = C(0x8EB862)
    let robe = C(0x26232A), robeD = C(0x141218), robeL = C(0x3E3A46)
    let s = p.signature ?? -1
    let twirl = s > 0.1 && s < 0.9 ? (s - 0.1) / 0.8 : -1.0

    // 1. The legs under the robe, their toes peeping out under the hem.
    drawLegs(c, Look(leg: robeD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 2, 1, skinD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body: goblin green, the far arm in the robe's sleeve.
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil))

    // 4. The long black robe from the shoulders to the ground, lit on the left, a fold by each leg.
    crawlH3Robe(c, robe, robeD, robeL, from: 32)

    // 5. The hood over her head, framing the face, lit along its top; her ears out through it.
    c.pattern(16, 21, [
        "......HHHHHHHHHHH.....",
        "....HHLLLLLLLLLLHHH...",
        "...HHLHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHH.",
        "..HHHH..........HHHHH.",
        "..HHH............HHHH.",
        "..HHH............HHHH.",
        "..HHH.............HHH.",
        "..HHH.............HHH.",
        "..HHH.............HHH.",
        "..HHH.............HHH.",
    ], ["H": robe, "L": robeL])
    crawlH3Ears(c, skin, skinD, skinL)

    // 6. The face: yellow eyes with black pupils under a frown, the hooked nose, the mouth and the forked tongue,
    //    flicking further out now and then.
    crawlH3GoblinFace(c, skin: skin, skinD: skinD)
    let flick = Int(p.lt * 1.7) % 3 == 0 ? 2 : 0
    c.rect(28, 32, 1, 1 + flick, C(0xD0404A)); c.px(27, 33 + flick, C(0xD0404A)); c.px(29, 33 + flick, C(0xD0404A))

    // 7. The near hand and the pineapple staff, twirling round the hand in the signature.
    c.oy += p.gunY
    if twirl > 0 {
        crawlH3Staff(c, angle: -90 + twirl * 720)
    } else {
        crawlH3Staff(c)
    }
    c.rect(39, 33, 4, 3, robe); c.px(39, 33, robeL); c.rect(41, 33, 2, 2, skin)
}

// MARK: - Lorelai

/// Lorelai: Rory's sister, a goblin shamanka too, but bare-headed: a shaggy black topknot, her big pointed ears ringed
/// with silver piercings, a silver ring in her nose, and a long violet robe with a necklace of white bones across it.
/// The same pineapple staff; her anguish magic is violet. Signature: she rattles the bone necklace.
private func drawLorelai(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x86A84C), skinD = C(0x627E34), skinL = C(0xA6C66A)
    let robe = C(0x5E3A82), robeD = C(0x40265C), robeL = C(0x7E58A6)
    let hair = C(0x1E1A20), hairL = C(0x3A343C), silver = C(0xD8DCE4), bone = C(0xF0ECE0), boneD = C(0xBCB6A8)
    let s = p.signature ?? -1
    let rattle = s > 0.1 && s < 0.9

    // 1. The legs under the robe, toes peeping out under the hem.
    drawLegs(c, Look(leg: robeD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 2, 1, skinD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, goblin green, lit along the top; the far arm in the violet sleeve.
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil))
    c.rect(18, 26, 20, 1, skinL); c.rect(18, 26, 1, 6, skinL)

    // 4. The long violet robe.
    crawlH3Robe(c, robe, robeD, robeL, from: 32)

    // 5. Her hair: cropped close and black over the top of her head, and a tall spiky topknot tied with a bone.
    c.pattern(19, 15, [
        "........h.h.......",
        ".......hHhHh......",
        "........HlHH......",
        ".......HHHHH......",
        "........HHH.......",
        "......wWWWWw......",
        "...HHHHHHHHHHHH...",
        ".HHHlHHHHHlHHHHH..",
        "HHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHH",
        "HH..............HH",
    ], ["H": hair, "h": hair, "l": hairL, "w": boneD, "W": bone])

    // 6. The ears, ringed with silver.
    crawlH3Ears(c, skin, skinD, skinL)
    for (x, y) in [(15, 27), (17, 28), (40, 27), (38, 28)] { c.px(x, y, silver) }

    // 7. The face: yellow eyes, the hooked nose with its silver ring, a smirk.
    crawlH3GoblinFace(c, skin: skin, skinD: skinD)
    c.rect(25, 31, 7, 1, skin); c.rect(29, 31, 3, 1, C(0x2A1A1A)); c.px(32, 30, C(0x2A1A1A))   // a smirk
    c.px(27, 31, silver)

    // 8. The bone necklace across her chest: small white bones on a cord, jiggling when she rattles it, little
    //    rattle marks either side.
    let j = rattle && Int(s * 20) % 2 == 0 ? 1 : 0
    let cord = C(0x3A2A20)
    for x in 20...36 {
        let y = 32 + min(5, min(x - 20, 36 - x) / 2 + 1)
        c.px(x, y, cord)
    }
    for (i, at) in [(21, 34), (25, 36), (30, 36), (34, 34)].enumerated() {
        let dy = rattle ? (i % 2 == 0 ? j : -j) : 0
        c.pattern(at.0 - 1, at.1 - 1 + dy, ["W.W", "WWW", "w.w"], ["W": bone, "w": boneD])
    }
    if rattle && j == 1 {
        c.pattern(17, 33, ["l.", ".l", "l."], ["l": C(0xFFFFFF, 0.8)])
        c.pattern(37, 33, [".l", "l.", ".l"], ["l": C(0xFFFFFF, 0.8)])
    }

    // 9. The near hand and the pineapple staff.
    c.oy += p.gunY
    crawlH3Staff(c, angle: rattle ? -90 + Double(j) * 4 : -90)
    c.rect(39, 33, 4, 3, robe); c.px(39, 33, robeL); c.rect(41, 33, 2, 2, skin)
}

/// A long robe from row `from` down to just above the toes, flared a pixel at the hem, lit on the left, a soft fold
/// beside each leg; shorter when seated.
private func crawlH3Robe(_ c: PixelCanvas, _ robe: Px, _ robeD: Px, _ robeL: Px, from: Int) {
    let hem = seatedPose ? 39 : 42
    c.rect(18, from, 20, hem - from, robe)
    c.rect(17, from + 4, 22, hem - from - 4, robe)
    c.rect(16, hem - 2, 24, 2, robe)
    c.rect(18, from, 1, hem - from - 2, robeL); c.rect(17, from + 4, 1, hem - from - 4, robeL)
    c.rect(16, hem - 1, 24, 1, robeD); c.rect(38, from + 4, 1, hem - from - 4, robeD)
    if !seatedPose {
        for x in [22, 27, 30, 34] { c.rect(x, from + 5, 1, hem - from - 6, robeD) }
    }
}

/// The goblins' big pointed ears, sticking out sideways from the top of the head.
private func crawlH3Ears(_ c: PixelCanvas, _ skin: Px, _ skinD: Px, _ skinL: Px) {
    c.pattern(12, 26, [
        "LL.....",
        ".SLSS..",
        "..SSSSS",
        "...dSSS",
    ], ["S": skin, "L": skinL, "d": skinD])
    c.pattern(37, 26, [
        ".....LL",
        "..SSLS.",
        "SSSSS..",
        "SSSd...",
    ], ["S": skin, "L": skinL, "d": skinD])
}

/// The goblins' face: yellow eyes with black pupils under a frown, the hooked nose, the mouth.
private func crawlH3GoblinFace(_ c: PixelCanvas, skin: Px, skinD: Px) {
    let eye = C(0xF0D040)
    c.rect(21, 28, 3, 2, eye); c.px(23, 29, ink); c.rect(31, 28, 3, 2, eye); c.px(33, 29, ink)
    c.rect(21, 27, 3, 1, skinD); c.rect(31, 27, 3, 1, skinD)
    c.pattern(27, 28, [".s", "ss", "sss"], ["s": skinD])
    c.rect(25, 31, 7, 1, C(0x2A1A1A))
}

// MARK: - Odette

/// Odette: the talk-show host, a crab-taur: Clawd's four legs drawn as a crab's, red shell, jointed at the knee and
/// pointed at the tip, under a red crab carapace; above it an ivory blazer with a black V and a gold button, and a
/// handheld microphone. On her head, a black mantis helmet: triangular, its two great mirrored eyes at the top
/// corners, mandibles below, and two huge antennae curving up out of it. Signature: an ON AIR light glows red beside
/// her, and her antennae twitch.
private func drawOdette(_ c: PixelCanvas, _ p: Pose) {
    let crab = C(0xC8442E), crabD = C(0x8E2A1C), crabL = C(0xE87050)
    let blazer = C(0xECE6D8), blazerD = C(0xC0B8A6)
    let helmet = C(0x1A1A20), helmetL = C(0x3A3A46)
    let mirror = C(0x8ABCE0), mirrorL = C(0xEAF6FF), mirrorD = C(0x3E6A90)
    let s = p.signature ?? -1
    let onAir = s > 0.08 && s < 0.92 ? sin((s - 0.08) / 0.84 * .pi) : 0
    let twitch = s > 0.3 && s < 0.8 ? Int(p.lt * 14) % 2 : 0

    // 1. The crab legs over Clawd's four: red shell, a knee jutting out (backwards on the back pair, forwards on the
    //    front), the lower leg tapering to a point on the ground.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, crab); c.rect(lx - 1, 38, 4, 1, crabL); c.px(lx + 2, 39, crabD) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            let out = i < 2 ? -1 : 2
            c.rect(lx, 36, 2, bottom - 37, crab)
            c.rect(lx, 36, 1, 3, crabL)
            c.px(lx + out, 38, crab); c.px(lx + out, 39, crabD)
            c.rect(lx, 39, 2, 1, crabD)
            c.rect(lx, bottom - 1, 2, 1, crabD)
            c.px(i < 2 ? lx : lx + 1, bottom, crabD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body: an ivory blazer, its far side in shade, a black V at the neck, a gold button; then the red crab
    //    carapace over the bottom of it, rounded at the ends, lit along its top, two darker spots.
    drawBody(c, Look(body: blazer, shade: blazerD, arm: blazer, eye: nil))
    c.rect(18, 26, 1, 10, C(0xFFFFFF))
    c.pattern(25, 29, ["HHHHHH", ".HHHH.", "..HH.."], ["H": helmet])
    c.px(28, 33, C(0xF0C840))
    c.rect(16, 35, 24, 3, crab); c.rect(17, 34, 22, 1, crab); c.rect(18, 38, 20, 1, crab)
    c.rect(17, 34, 22, 1, crabL); c.rect(16, 35, 1, 2, crabL)
    c.rect(18, 38, 20, 1, crabD); c.rect(39, 35, 1, 3, crabD)
    c.rect(22, 36, 2, 1, crabD); c.rect(32, 36, 2, 1, crabD)

    // 4. The antennae: two huge thin feelers curving up out of the top of the helmet, the far one back, the near one
    //    forward, twitching in the signature.
    func feeler(_ x0: Double, _ y0: Double, _ cx: Double, _ cy: Double, _ x1: Double, _ y1: Double) {
        var last = (x0, y0)
        for i in 1...14 {
            let k = Double(i) / 14
            let x = (1 - k) * (1 - k) * x0 + 2 * (1 - k) * k * cx + k * k * x1
            let y = (1 - k) * (1 - k) * y0 + 2 * (1 - k) * k * cy + k * k * y1
            c.glowLine(last.0, last.1, x, y, core: helmetL, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
            last = (x, y)
        }
    }
    let tw = Double(twitch) * 2
    feeler(25, 18, 22, 6, 13 - tw, 6 + tw)
    feeler(31, 18, 33, 5, 41 + tw, 5 + tw)

    // 5. The mantis helmet: black, triangular, the two great mirrored eyes at its top corners (a glint and a darker
    //    lower edge), tapering down to the mandibles.
    c.pattern(17, 17, [
        "......HHHHHHHHHH......",
        "...LLLHHHHHHHHHHLLL...",
        ".LLMMLLHHHHHHHHLLMMLL.",
        "LLMWWMMLHHHHHHLMMWWMLL",
        "LMMWMMMLHHHHHHLMMWMMML",
        "LMMMMMMLHHHHHHLMMMMMML",
        "LMMMMMDLHHHHHHLMMMMMDL",
        ".LMMMDDLHHHHHHLMMMDDL.",
        "..LLLLHHHHHHHHHHLLLL..",
        "....HHHHHHHHHHHHHH....",
        ".....HHHHHHHHHHHH.....",
        "......HHHLHHLHHH......",
        ".......HHHHHHHH.......",
        "........hH..Hh........",
    ], ["H": helmet, "L": helmetL, "M": mirror, "W": mirrorL, "D": mirrorD, "h": helmetL])

    // 6. The near arm in the blazer, holding the microphone up: a black handle, a silver head.
    c.rect(38, 31, 3, 4, blazer); c.rect(38, 34, 3, 1, blazerD)
    c.rect(40, 28, 2, 5, C(0x2A2A30)); c.rect(39, 26, 4, 2, C(0x9A9EA8)); c.px(39, 26, C(0xD8DCE4))
    c.rect(39, 30, 3, 2, blazerD)

    // 7. The ON AIR light: a red box beside her that lights up, its letters glowing.
    if onAir > 0 {
        let text = "ON AIR", w = crawlTextWidth(text)
        let x = 45, y = 12
        c.rect(x - 2, y - 2, w + 4, 9, lerp(C(0x4A1414), C(0xE02A2A), onAir))
        c.rect(x - 2, y - 2, w + 4, 1, lerp(C(0x6A2020), C(0xFF7A6A), onAir))
        crawlText(c, x, y, text, lerp(C(0x7A3A3A), C(0xFFF0E8), onAir))
        if onAir > 0.6 { c.rect(x - 4, y - 4, w + 8, 13, C(0xFF4A3A, 0.08)) }
    }
}

// MARK: - Zev

/// Zev: a small fish alien, Clawd orange as a fish (a big round eye, a pouting mouth, fins and a fan of a tail) in a
/// round glass helmet full of water, bubbles rising in it, a lit glint on the glass; a white mesh spacesuit with a grey
/// collar ring and grey boots, and a grey backpack with a little antenna and a blinking light. She doesn't fight.
/// Signature: a flurry of bubbles rises in her helmet.
private func drawZev(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0xF2F2F4), suitD = C(0xC4C6CC), mesh = C(0xDCDEE4)
    let metal = C(0x8A9098), metalD = C(0x5E646C), metalL = C(0xB4BAC2)
    let water = C(0x7AC8E8), waterD = C(0x5AAAD4), glass = C(0xD8EEF8), bubble = C(0xF2FCFF)
    let fish = clawdOrange, fin = clawdShade, finL = C(0xEE9A7A)
    let s = p.signature ?? -1
    let flurry = s > 0.1 && s < 0.9

    // 1. White suit legs and grey boots.
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, metal, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 1, metalL)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The backpack behind her: grey, lit on top, a vent, the little antenna with its blinking light.
    c.rect(12, 27, 6, 10, metal); c.rect(12, 27, 6, 1, metalL); c.rect(12, 36, 6, 1, metalD)
    c.rect(13, 30, 4, 1, metalD); c.rect(13, 32, 4, 1, metalD)
    c.rect(14, 22, 1, 5, metalD)
    c.px(14, 21, Int(p.lt * 2) % 2 == 0 ? C(0x5AF07A) : C(0x2A6A3A))

    // 4. The white mesh suit: a faint lattice over it, a grey collar ring for the helmet to sit on.
    drawBody(c, Look(body: suit, shade: suitD, arm: suit, eye: nil))
    for y in 31...36 {
        for x in 19...36 where (x + y) % 4 == 0 || (x - y + 40) % 4 == 0 { c.px(x, y, mesh) }
    }
    c.rect(19, 29, 18, 2, metal); c.rect(19, 29, 18, 1, metalL)
    c.rect(15, 35, 3, 1, suitD); c.rect(38, 35, 3, 1, suitD)

    // 5. The glass helmet: a round bubble full of water, a pale rim, a glint on the upper left.
    c.circle(28, 20, 10, glass)
    c.circle(28, 20, 9, water)
    c.rect(19, 25, 19, 4, water)
    c.ellipse(28, 27, 7, 1, waterD)
    c.rect(22, 13, 3, 1, C(0xFFFFFF)); c.rect(21, 14, 1, 2, C(0xFFFFFF))

    // 6. The fish inside, facing right: an orange body, a fan of a tail, a fin on top and one below, a big round eye
    //    with a black pupil, a pouting mouth, a gill line.
    let bob = Int((sin(p.lt * 2) * 1).rounded())
    c.pattern(20, 15 + bob, [
        "........FFF.....",
        ".......FFFFF....",
        "FF...OOOOOOOOO..",
        "FFF.OOOOOOWWOOO.",
        "FFFOOOOOOOWkOOOO",
        "FFFFOOOOgOOOOOOm",
        "FFFOOOOOgOOOOOOO",
        "FFF.OOOOOOOOOOO.",
        "FF...OOOOOOOOO..",
        "........FF......",
    ], ["F": fin, "O": fish, "W": C(0xFFFFFF), "k": ink, "g": fin, "m": C(0x8A3A2A)])
    c.rect(26, 17 + bob, 7, 1, finL)

    // 7. The bubbles: a few always rising from her mouth to the top of the helmet; a flurry of them in the
    //    signature, some bigger.
    let count = flurry ? 7 : 2
    for i in 0..<count {
        let k = (p.lt * (flurry ? 0.9 : 0.4) + Double(i) / Double(count)).truncatingRemainder(dividingBy: 1)
        let x = 34 - (i * 3) % 12 + Int(sin(k * 6 + Double(i)) * 1.2)
        let y = 22 - Int(k * 10)
        if flurry && i % 3 == 0 {
            c.pattern(x - 1, y - 1, [".b.", "b.b", ".b."], ["b": bubble])
        } else {
            c.px(x, y, bubble)
        }
    }

    // 8. The near arm, a white suit sleeve.
    c.rect(38, 33, 3, 3, suit); c.px(38, 33, C(0xFFFFFF))
}
