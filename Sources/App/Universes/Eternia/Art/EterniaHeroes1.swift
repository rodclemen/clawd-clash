import Foundation

// Heroes: the Masters of the Universe, the defenders of Castle Greyskull. Clawd in costume like every other cast: the
// harness, the fur and the hair drawn over the blocky body, Clawd's own orange showing for the bare arms and legs the
// Filmation heroes went about in.

let eterniaHeroes1: [EterniaHero: Persona] = [
    .heClawd: Persona(name: "He-Clawd", weapon: .saber, headTop: 20, signature: 3.6, callout: "I have the power!",
                      draw: drawHeClawd),
    .orkko: Persona(name: "Orkko", weapon: .lightning, motion: .hover,
                    magic: Magic(core: C(0xFFF6A0), glow: C(0xE040C0), jagged: false, spell: true),
                    canSit: false, headTop: 14, signature: 3.4, callout: "Oops!", draw: drawOrkko),
]

// MARK: - He-Clawd

/// He-Clawd: the most powerful man in the universe. A blond pageboy cut straight across his brow and round over his
/// ears, the silver chest harness with its red iron cross, brown fur briefs on a belt of round gold studs, brown wrist
/// bracers and furry brown boots, Clawd's bronze everywhere else. Fights with the Power Sword; when it's put away, its
/// hilt shows over his back. Signature: he raises the sword overhead and a fork of white-gold lightning comes down
/// into its tip, the blade blazing, then he lowers it.
private func drawHeClawd(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xE8C25A), hairD = C(0xB88E32), hairL = C(0xFFE48E)
    let silver = C(0xB4B8C4), silverD = C(0x7E8290), silverL = C(0xE2E4EC), cross = C(0xC8302A), crossD = C(0x8A1E1A)
    let fur = C(0x7A4E2A), furD = C(0x54341A), furL = C(0x9A6A3E), gold = C(0xE0B040), goldD = C(0x9A7420)
    let bracer = C(0x6A4428), bracerL = C(0x8A5E38)
    // The signature, 0…1: the arm goes up by a fifth of the way in, the lightning strikes from a quarter to three
    // quarters, and the arm comes down before the end.
    let s = p.signature ?? -1
    let up = s < 0 ? 0 : s < 0.2 ? s / 0.2 : s > 0.85 ? max(0, (1 - s) / 0.15) : 1
    let raise = Int((up * 9).rounded())
    let strike = s > 0.25 && s < 0.78 ? (s - 0.25) / 0.53 : -1

    // Bare legs, and furry boots: brown, a lit cuff of fur round the top, strokes down them.
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 4, fur)
            c.rect(lx, bottom - 3, 2, 1, furL); c.px(lx + 1, bottom - 1, furD)
        }
    }

    c.oy += p.breathe
    // The Power Sword on his back while it's put away: its hilt over his far shoulder, behind him.
    if p.melee == nil && raise == 0 {
        c.rect(14, 24, 2, 6, C(0x5A4A6A)); c.px(14, 24, C(0x7A6A8A))
        c.rect(12, 29, 6, 1, silver); c.px(12, 29, silverL)
        c.rect(14, 22, 2, 2, gold)
    }
    drawBody(c, Look(), armRight: raise)
    // The bracers, a band round each wrist with a lit edge.
    c.rect(15, 34, 3, 1, bracer); c.px(15, 34, bracerL)
    c.rect(38, 34 - raise, 3, 1, bracer); c.px(38, 34 - raise, bracerL)

    // The harness: a silver plate across his chest with the red iron cross in its middle, lit along the top and
    // shaded on the far side, rivets at its corners.
    c.rect(19, 33, 18, 3, silver); c.rect(19, 33, 18, 1, silverL); c.rect(36, 33, 1, 3, silverD); c.rect(19, 35, 18, 1, silverD)
    c.pattern(25, 33, [
        ".XXXX.",
        "XXxxXX",
        ".XXXX.",
    ], ["X": cross, "x": crossD])
    c.px(20, 34, silverD); c.px(34, 34, silverD)
    // The belt of round gold studs, and the fur briefs under it, hanging ragged over the tops of his legs.
    c.rect(18, 36, 20, 1, C(0x4A2E18))
    for x in stride(from: 19, through: 35, by: 4) { c.px(x, 36, gold); c.px(x + 1, 36, goldD) }
    eterniaFur(c, 18, 37, 20, 1, base: fur, dark: furD, light: furL)

    // The pageboy: a round cap of blond hair combed down in strands from the crown, a ragged fringe across his brow,
    // and down over his ears either side, lit along the top.
    c.pattern(16, 21, [
        ".....HHHHHlHHHHHH......",
        "...HHHlHHHHHlHHHHHH....",
        "..HHhHHHHhHHHHHhHHHHH..",
        ".HHHhHHlHhHHHHHhHHHhHH.",
        "HHHHhHHHHhHHHhHHhHHhHHH",
        "HHHHHhHHHHhHHhHHHhHHhHH",
        "HHh.hH.hHH.hH.hHH.hH.HH",
        "HHh..................HH",
        "HHh..................hH",
        ".Hh..................h.",
        ".h....................h",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)   // his brows

    if raise > 0 {
        // The Power Sword held up overhead, straight up from his raised fist.
        let h = (x: eterniaHand.x - 1.5, y: eterniaHand.y - Double(raise))
        let blaze = strike >= 0 ? 0.6 + 0.4 * sin(p.t * 40) : 0
        eterniaSword(c, p, angle: -90, at: h, grip: C(0x5A4A6A), guardCol: silver, steel: silverL,
                     edge: strike >= 0 ? C(0xFFF8D8) : C(0xFFFFFF), length: 14, pommel: gold)
        if strike >= 0 {
            // The blade blazing, and the fork of lightning down into its tip from the top of the frame: a jagged
            // white-gold line that redraws itself, a branch off it, all see-through glow (no outline).
            let tipY = h.y - 16
            c.glowLine(h.x, h.y - 4, h.x, tipY, core: C(0xFFF6C8, 0.9 * blaze), glow: C(0xFFD040, 0),
                       coreR: 0.6, glowR: 2.4, strength: blaze)
            var x = h.x, y = tipY
            let seed = Int(p.t * 14)
            // It fades out going up, gone a few rows short of the frame's top, so it never ends in a hard edge.
            while y > 4 {
                let nx = h.x + (noise(seed + Int(y)) - 0.5) * 7, ny = max(4, y - 3)
                let fade = min(1, (ny - 4) / max(1, tipY - 4) * 1.6)
                c.glowLine(x, y, nx, ny, core: C(0xFFFBE8, 0.95 * fade), glow: C(0xFFC830, 0.7 * fade), coreR: 0.5, glowR: 1.6)
                if Int(y) % 6 == 0 { c.glowLine(nx, ny, nx + 4, ny + 2, core: C(0xFFF4C0, 0.7 * fade), glow: C(0xFFC830, 0.4 * fade), coreR: 0.3, glowR: 1) }
                x = nx; y = ny
            }
        }
        return
    }
    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: C(0x5A4A6A), guardCol: silver, steel: silverL, edge: C(0xFFFFFF),
                     length: 14, pommel: gold)
    }
}

// MARK: - Orkko

/// Orkko: the Trollan court magician, floating a little off the ground. A big floppy orange hat with a wide brim, its
/// tip folding over behind him, a purple scarf wound round to just under his eyes with its end flying out behind, and
/// a magenta robe to the ground with a big black O on its front. His magic is a twinkle of lemon and magenta that
/// mostly works. Signature: a trick goes wrong and a little grey rain cloud gathers over his own hat and rains on it.
private func drawOrkko(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xC03A8A), robeD = C(0x8A2464), robeL = C(0xE060A8)
    let hat = C(0xE8782A), hatD = C(0xB4521A), hatL = C(0xFFA050)
    let scarf = C(0x6A3AA8), scarfD = C(0x4A2478), scarfL = C(0x8E5ACC), ink = C(0x1A1420)
    let s = p.signature ?? -1
    let rain = s > 0.1 && s < 0.92 ? (s - 0.1) / 0.82 : -1

    // The legs under the robe: drawn first all the same, then the robe over them; the hem stops short of the
    // ground, since he floats.
    drawLegs(c, Look(leg: robeD), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe), armRight: p.armRaise)

    // The robe: from the shoulders to the hem, flaring, a shadow between each leg, lit on the left.
    c.rect(18, 33, 20, 5, robe)
    for y in 38...41 where y + c.oy <= 42 {
        let flare = (y - 38) / 2
        c.rect(17 - flare, y, 22 + 2 * flare, 1, robe)
        c.px(17 - flare, y, robeL); c.px(38 + flare, y, robeD)
        if y >= 39 { for x in [22, 26, 30, 34] { c.px(x, y, robeD) } }
    }
    c.rect(18, 33, 1, 5, robeL); c.rect(37, 33, 1, 5, robeD)
    // The black O on his front.
    c.pattern(25, 34, [
        ".KKKK.",
        "KK..KK",
        "KK..KK",
        ".KKKK.",
    ], ["K": ink])
    // The scarf: wound round his neck and up over the lower half of his face, its end flying out behind him.
    c.rect(18, 31, 20, 2, scarf); c.rect(18, 31, 20, 1, scarfL); c.rect(36, 31, 2, 2, scarfD)
    for x in stride(from: 20, to: 36, by: 4) { c.px(x, 32, scarfD) }
    c.pattern(11, 31, [
        "SSSSSSS",
        ".sSSSS.",
        "...ss..",
    ], ["S": scarf, "s": scarfD])

    // The hat: a wide brim with its underside in shade over his eyes, a tall crown, and the floppy tip folding over
    // towards his back.
    c.pattern(13, 13, [
        "......TTTT..............",
        "....TTTTTTTT............",
        "...TTLTT..TTT...........",
        "..TTTT.....TTH..........",
        ".TTT.......HHHH.........",
        "..T......HHLHHHHH.......",
        ".........HHLHHHHHH......",
        "........HHLHHHHHHHH.....",
        ".......HHLHHHHHHHHHH....",
        "......HHLHHHHHHHHHHHH...",
        "....HHHLHHHHHHHHHHHHHHH.",
        "..BBBBBBBBBBBBBBBBBBBBBBB",
        ".BBBBBBBBBBBBBBBBBBBBBBBB",
        "..bbbbbbbbbbbbbbbbbbbbbb.",
    ], ["T": hatD, "H": hat, "L": hatL, "B": hat, "b": hatD])
    c.rect(19, 27, 18, 1, C(0x9A5A3A))   // the brim's shadow on his brow

    if rain >= 0 {
        // The rain cloud: it gathers over the hat, rains for most of the trick, and thins away.
        let size = min(1, rain / 0.15) * min(1, (1 - rain) / 0.15)
        let w = Int((14 * size).rounded())
        if w > 1 {
            let cx = 29, cy = 6
            c.rect(cx - w / 2, cy, w, 3, C(0x8A8E9A)); c.rect(cx - w / 2 + 2, cy - 2, max(1, w - 6), 2, C(0x9EA2AE))
            c.rect(cx - w / 2, cy + 2, w, 1, C(0x6A6E7A))
            if size > 0.6 {
                for k in 0..<4 {
                    let x = cx - 5 + k * 3, y = cy + 3 + Int((p.t * 14 + Double(k) * 1.7).truncatingRemainder(dividingBy: 6))
                    c.px(x, y, C(0x7AB4F0))
                }
            }
        }
    }
}
