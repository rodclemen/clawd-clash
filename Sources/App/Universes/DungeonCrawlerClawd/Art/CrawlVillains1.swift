import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The bosses, first: Maestro.

let crawlVillains1: [CrawlVillain: Persona] = [
    .maestro: Persona(name: "Maestro", weapon: .saber, bulk: 5, headTop: 19, signature: 3.0, draw: drawMaestro),
]

// MARK: - Maestro

/// Maestro: a boar-faced orc, Clawd with grey-green hide, one big boar's snout with two big nostrils in the middle of
/// his face, small mean eyes under a heavy brow, a crest of black bristles over his head and down his back, an ivory
/// tusk on the far side and a gold one jutting out on the near. A pink silk shirt half unbuttoned over his chest, a
/// gold chain on it, black trousers and shiny black shoes. He fights with his fists. Signature: the game-show host's
/// turn: a microphone held up in front of his snout, the tusky grin wide, a flourish of sparkle.
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

    // 3. The body in grey-green hide, the head a little taller than Clawd's so the snout and tusks have room.
    drawBody(c, Look(body: hide, shade: hideD, arm: silk, eye: nil))
    c.rect(18, 24, 20, 2, hide); c.rect(37, 24, 1, 2, hideD)
    c.rect(18, 24, 20, 1, hideL); c.rect(18, 24, 1, 9, hideL)
    c.rect(15, 33, 3, 3, silk); c.px(15, 33, silkL); c.rect(15, 35, 3, 1, silkD)

    // 4. The bristles: a crest of black bristles from his brow back over his head and down his back, in short strokes.
    c.pattern(14, 19, [
        "........B.B.B.B.B.B.....",
        ".....B.BBBBBBBBBBBBB.B..",
        "...B.BBBlBBBlBBBBlBBBB..",
        ".BBBBlBBBBBBBBBBBBBBBB..",
        "...BBBBBBBBBBBBBBBBBBB..",
    ], ["B": bristle, "l": bristleL])

    // 5. The shirt: pink silk over the body, open to the middle of his chest with the hide showing, a wide collar, a
    //    sheen on the left, the far side in shade; the gold chain over his chest.
    c.rect(18, 34, 20, 4, silk)
    c.rect(18, 34, 1, 4, silkL); c.rect(19, 35, 2, 1, silkL); c.rect(37, 34, 1, 4, silkD); c.rect(18, 37, 20, 1, silkD)
    c.pattern(23, 34, [
        "CHHHHHHHHHC",
        ".CHHHHHHHC.",
        "..CCHHHCC..",
    ], ["C": silkL, "H": hide])
    c.px(28, 37, C(0xF8F0F0))   // the first done-up button
    c.pattern(24, 34, [
        "g.......g",
        ".gg...gg.",
        "...gGg...",
    ], ["g": gold, "G": goldD])

    // 6. The face: the brow heavy and low, small eyes under it; below them one big snout with two big nostrils, the
    //    wide mouth under that, and a tusk standing clear either side of it, ivory on the far side and gold on the
    //    near, jutting out past his cheek.
    c.rect(20, 25, 16, 1, hideD)
    c.rect(23, 26, 2, 2, ink); c.rect(32, 26, 2, 2, ink)
    c.px(23, 26, C(0xE8C040)); c.px(32, 26, C(0xE8C040))
    c.pattern(24, 28, [
        ".LLLLLLLSSSS.",
        "SSSnnSSSnnSSS",
        "SSSnnSSSnnSSS",
        ".sssssssssss.",
    ], ["S": snout, "L": C(0xE4BCAC), "s": snoutD, "n": nostril])
    if grin {
        c.pattern(23, 32, ["MWWWWWWWWWWWWM", ".MMMMMMMMMMMM."], ["M": C(0x3A1A1E), "W": C(0xF0E8D8)])
    } else {
        c.rect(24, 32, 12, 1, C(0x3A2A24))
    }
    c.pattern(20, 29, ["i.", "ii", "ii", "ii"], ["i": ivory])
    c.pattern(38, 28, [".g", "gg", "gG", "gG", "GG"], ["g": gold, "G": goldD])

    // 7. The fists: hide, the cuff of the silk sleeve; or, as host, the microphone held up out in front of his snout,
    //    a flourish of sparkle round it.
    func fist(_ x: Int, _ y: Int, _ a: Double) {
        c.rect(x - 1, y - 1, 3, 3, hide.alpha(a)); c.px(x - 1, y - 1, hideL.alpha(a)); c.rect(x - 1, y + 1, 3, 1, hideD.alpha(a))
        c.px(x + 1, y - 1, gold.alpha(a))   // a ring
    }
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: silk, fist: fist)
    } else if host {
        c.rect(38, 33, 5, 3, silk); c.rect(38, 35, 5, 1, silkD)
        fist(44, 32, 1)
        c.rect(44, 25, 2, 6, C(0x2A2A30)); c.rect(43, 22, 4, 3, C(0x8A8E98)); c.px(43, 22, C(0xD8DCE4))
        if Int(p.lt * 8) % 2 == 0 {
            for (x, y) in [(49, 20), (48, 16), (52, 23)] { c.px(x, y, C(0xFFF2A0)); c.px(x + 1, y, C(0xFFFFFF, 0.6)) }
        }
    } else {
        fist(39, 34, 1)
    }
}
