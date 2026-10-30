import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The bosses, first: Maestro.

let crawlVillains1: [CrawlVillain: Persona] = [
    .maestro: Persona(name: "Maestro", weapon: .saber, bulk: 5, headTop: 19, signature: 3.0, draw: drawMaestro),
]

// MARK: - Maestro

/// Maestro: a boar-faced orc, Clawd with grey-green hide, a big boar's snout pushed forward with its pink nostrils,
/// small mean eyes under a heavy brow, a crest of black bristles over his head and down his back, an ivory tusk on the
/// far side and a gold one on the near. A pink silk shirt half unbuttoned over his chest, gold chains on it, black
/// trousers and shiny black shoes. He fights with his fists. Signature: the game-show host's turn: a microphone up to
/// his snout, the tusky grin wide, a flourish of sparkle.
private func drawMaestro(_ c: PixelCanvas, _ p: Pose) {
    let hide = C(0x7A8A62), hideD = C(0x58663E), hideL = C(0x98A87A)
    let snout = C(0xC89A8A), snoutD = C(0x9A6E62), nostril = C(0x4A2A2A)
    let bristle = C(0x1E1A1C), bristleL = C(0x3E383A)
    let silk = C(0xF07AB8), silkD = C(0xC04E8E), silkL = C(0xFFA8D4)
    let gold = C(0xF0C840), goldD = C(0xB88A20), ivory = C(0xF0E8D0)
    let s = p.signature ?? -1
    let host = s > 0.08 && s < 0.92
    let grin = host || p.melee != nil

    // 1. Black trousers and shiny shoes.
    drawLegs(c, Look(leg: C(0x24222A)), step: p.step)
    drawBoots(c, C(0x101014), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where !(p.step >= 0 && i % 2 == p.step) { c.px(lx, 43, C(0x5A5A66)) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in grey-green hide; the near arm rises with the mic.
    drawBody(c, Look(body: hide, shade: hideD, arm: silk, eye: nil), armRight: host ? 5 : 0)
    c.rect(18, 26, 20, 1, hideL); c.rect(18, 26, 1, 7, hideL)
    c.rect(15, 33, 3, 3, silk); c.px(15, 33, silkL); c.rect(15, 35, 3, 1, silkD)

    // 4. The bristles: a crest of black bristles from his brow back over his head and down his back, in short strokes.
    c.pattern(14, 19, [
        "........B.B.B.B.B.B.....",
        ".....B.BBBBBBBBBBBBB.B..",
        "...B.BBBlBBBlBBBBlBBBB..",
        "..BBBBBBBBBBBBBBBBBBBB..",
        ".BBBBlBBBBBBBBBBBBBBBB..",
        "..BBBBBBBBBBBBBBBBBBBB..",
        "...BBBBBBBBBBBBBBBBBBB..",
        "....BB..................",
    ], ["B": bristle, "l": bristleL])

    // 5. The shirt: pink silk over the body, open to the middle of his chest with the hide showing, a wide collar, a
    //    sheen on the left, the far side in shade; the gold chains over his chest.
    c.rect(18, 32, 20, 6, silk)
    c.rect(18, 32, 1, 6, silkL); c.rect(19, 33, 2, 1, silkL); c.rect(37, 32, 1, 6, silkD); c.rect(18, 37, 20, 1, silkD)
    c.pattern(23, 32, [
        "CC.......CC",
        ".CHHHHHHHC.",
        "..CHHHHHC..",
        "...CHHHC...",
        "....CsC....",
    ], ["C": silkL, "H": hide, "s": silkD])
    c.px(28, 37, C(0xF8F0F0))   // the first done-up button
    c.pattern(24, 33, [
        "g.......g",
        ".g.....g.",
        "..gGgGg..",
        "....G....",
    ], ["g": gold, "G": goldD])
    c.px(26, 34, hideD); c.px(29, 35, hideD)   // hair on his chest

    // 6. The face: the brow heavy and low, small eyes under it, the snout pushed forward with its nostrils, the
    //    tusks: ivory on the far side, gold on the near, and the grin.
    c.rect(20, 27, 15, 1, hideD)
    c.rect(22, 28, 2, 2, ink); c.rect(30, 28, 2, 2, ink)
    c.px(22, 28, C(0xE8C040)); c.px(30, 28, C(0xE8C040))
    c.pattern(30, 29, [
        "....SSSSSSSS.",
        "..SSSSSSSSSSS",
        "..SSSSSSnSSnS",
        "..SSSSSSnSSnS",
        "...sssssssss.",
    ], ["S": snout, "s": snoutD, "n": nostril])
    c.rect(41, 30, 1, 3, snoutD)   // the flat end of the snout
    if grin {
        c.pattern(27, 33, ["MWWWWWWWWM", ".MMMMMMMM."], ["M": C(0x3A1A1E), "W": C(0xF0E8D8)])
    } else {
        c.rect(28, 33, 8, 1, C(0x3A2A24))
    }
    c.pattern(26, 30, ["i.", "ii", "ii"], ["i": ivory])
    c.pattern(36, 29, ["g.", "gG", "gG", "GG"], ["g": gold, "G": goldD])

    // 7. The fists: hide, the cuff of the silk sleeve; or, as host, the microphone up at his snout, a flourish of
    //    sparkle round it.
    func fist(_ x: Int, _ y: Int, _ a: Double) {
        c.rect(x - 1, y - 1, 3, 3, hide.alpha(a)); c.px(x - 1, y - 1, hideL.alpha(a)); c.rect(x - 1, y + 1, 3, 1, hideD.alpha(a))
        c.px(x + 1, y - 1, gold.alpha(a))   // a ring
    }
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: silk, fist: fist)
    } else if host {
        fist(39, 29, 1)
        c.rect(40, 24, 2, 5, C(0x2A2A30)); c.rect(39, 22, 4, 3, C(0x8A8E98)); c.px(39, 22, C(0xD8DCE4))
        if Int(p.lt * 8) % 2 == 0 {
            for (x, y) in [(45, 20), (44, 16), (48, 23)] { c.px(x, y, C(0xFFF2A0)); c.px(x + 1, y, C(0xFFFFFF, 0.6)) }
        }
    } else {
        fist(39, 34, 1)
    }
}
