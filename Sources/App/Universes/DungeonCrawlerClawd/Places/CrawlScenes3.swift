import Foundation

// Places, a few to a file (see CrawlScenes1.swift for the rules): the Royal Court's personal space, the Desperado Club
// casino, Odette's studio.

let crawlScenes3: [Location: Place] = [
    .crawlPersonal: Place(name: "The Royal Court's personal space", panel: 0x1C2030, still: Scenes.crawlPersonal,
                          moving: Scenes.crawlPersonalLife),
    .crawlDesperado: Place(name: "The Desperado Club casino", panel: 0x1A0C26, still: Scenes.crawlDesperado,
                           moving: Scenes.crawlDesperadoLife),
    .crawlStudio: Place(name: "Odette's After Hours studio", panel: 0x1C1A1E, still: Scenes.crawlStudio,
                        moving: Scenes.crawlStudioLife),
]

/// Little pixel pictures drawn from rows of letters, each letter a square `cell` pixels wide (a place's unit, or two).
private func crawlGrid(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ palette: [Character: Px], cell: Int) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() {
            if let col = palette[ch] { c.rect(x + k * cell, y + r * cell, cell, cell, col) }
        }
    }
}

/// Neon letters: the tube itself in `col`, a soft halo of `glow` a unit out on every side.
private func crawlNeonText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, _ glow: Px, scale: Int, s: Int) {
    for (dx, dy) in [(-s, 0), (s, 0), (0, -s), (0, s)] { crawlText(c, x + dx, y + dy, text, glow, scale: scale) }
    crawlText(c, x, y, text, col, scale: scale)
}

/// A straight neon tube across from `x0` to `x1` at row `y`, a unit thick, its halo above and below.
private func crawlNeonLine(_ c: PixelCanvas, _ x0: Int, _ x1: Int, _ y: Int, _ col: Px, _ glow: Px, s: Int) {
    c.rect(x0, y - 2 * s, x1 - x0, 2 * s, glow.alpha(0.5)); c.rect(x0, y + s, x1 - x0, 2 * s, glow.alpha(0.5))
    c.rect(x0, y - s, x1 - x0, s, glow); c.rect(x0, y + s, x1 - x0, s, glow)
    c.rect(x0, y, x1 - x0, s, col)
}

// MARK: - The Royal Court's personal space

/// Donut drawn small for her portrait: a brown cat with a ginger saddle, gold tiara on her head.
private let crawlDonutPortrait = [
    "....y.y.y....",
    "....yyyyy....",
    "..bb.....bb..",
    "..bbbbbbbbb..",
    "..bebbbbbeb..",
    "..bbbbpbbbb..",
    "...bbbbbbb...",
    "..ooobbbooo..",
    ".ooooobooooo.",
    ".ooooooooooo.",
]

extension Scenes {
    /// Where things stand in the personal space, shared by the still picture and the moving layer: the food
    /// synthesiser's box and its status light, and (on the screen saver) the loft's floor.
    static func crawlPersonalFrame(_ c: PixelCanvas, _ g: Int) -> (synth: (x: Int, y: Int, w: Int, h: Int),
                                                                  light: (x: Int, y: Int), loft: Int) {
        let s = unit(g)
        let synth = (x: c.w * 5 / 100, y: g - 42 * s, w: 22 * s, h: 42 * s)
        let light = (x: synth.x + 17 * s, y: synth.y + 3 * s)
        return (synth, light, isTall(c) ? g - 120 * s : -1)
    }

    /// The Royal Court's personal space: the crew's own flat between floors, cool and tidy where the safe room is warm
    /// wood. Dusky blue walls with a faint diamond wallpaper and a pale skirting; on the left the food synthesiser, a
    /// steel cabinet with a screen and a hatch where the meal comes out; a plum velvet couch with two cushions under a
    /// gold-framed portrait of Princess Donut in her tiara, a lamp either side; Mongo's big green pet carrier with his
    /// name on it and two yellow eyes in the dark; and on the right Donut's hat stand, a sun hat and a top hat on its
    /// hooks and a little gold tiara on top. The floor is dark slate carpet. On the screen saver the room rises to a
    /// loft behind a gold railing, the training room's door up there with its sign, and a coffered ceiling with two
    /// chandeliers; a ladder climbs to it at the right.
    static func crawlPersonal(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = crawlPersonalFrame(c, g)
        let wall = C(0x3C4462), motif = C(0x485274)
        let gold = C(0xD8A838), goldD = C(0x9A7020), goldL = C(0xF4D470)

        // The wall: dusky blue, a faint diamond wallpaper in staggered rows.
        c.rect(0, 0, c.w, g, wall)
        for row in 0..<(g / (12 * s) + 1) {
            let y = g - 8 * s - row * 12 * s, shift = row % 2 == 0 ? 0 : 7 * s
            for x in stride(from: shift, to: c.w, by: 14 * s) {
                c.rect(x, y - s, s, s, motif); c.rect(x - s, y, 3 * s, s, motif); c.rect(x, y + s, s, s, motif)
            }
        }
        // The skirting along the floor: pale lilac-grey, lit along its top.
        c.rect(0, g - 4 * s, c.w, 4 * s, C(0x6A6C84)); c.rect(0, g - 4 * s, c.w, s, C(0x8A8CA4))

        // On the screen saver: the loft. Its floor runs across on dark beams, two pendant lamps hanging under it; a
        // gold railing along its edge; the training room's steel door up there under its sign, a potted plant either
        // side; and above it all a coffered ceiling with a chandelier at each side. A ladder climbs up at the right.
        if f.loft > 0 {
            let lf = f.loft
            // The ceiling and its coffers.
            let ceil = lf - 76 * s
            if ceil > 0 {
                c.rect(0, 0, c.w, ceil, C(0x262B40))
                for x in stride(from: 2 * s, to: c.w, by: 24 * s) {
                    for y in stride(from: ceil - 14 * s, to: -14 * s, by: -16 * s) {
                        c.rect(x, y, 20 * s, 12 * s, C(0x30364E)); c.rect(x, y, 20 * s, s, C(0x1C2032))
                        c.rect(x + 2 * s, y + 2 * s, 16 * s, 8 * s, C(0x363D58))
                    }
                }
                c.rect(0, ceil, c.w, 3 * s, gold); c.rect(0, ceil, c.w, s, goldL); c.rect(0, ceil + 3 * s, c.w, s, goldD)
                // The chandeliers: a chain, a gold ring with candles, crystal drops.
                for cx in [c.w * 20 / 100, c.w * 80 / 100] {
                    let cy = ceil + 22 * s
                    c.rect(cx, ceil + 4 * s, s, 18 * s, goldD)
                    c.rect(cx - 10 * s, cy, 21 * s, 2 * s, gold); c.rect(cx - 10 * s, cy, 21 * s, s, goldL)
                    c.rect(cx - 6 * s, cy + 2 * s, 13 * s, 2 * s, goldD)
                    for k in 0..<5 {
                        let x = cx - 10 * s + k * 5 * s
                        c.rect(x, cy - 3 * s, s, 3 * s, C(0xF4ECD8)); c.rect(x, cy - 4 * s, s, s, C(0xFFC850))
                        c.rect(x, cy + 2 * s, s, 2 * s, C(0xB8E0F0)); c.rect(x, cy + 4 * s, s, s, C(0xE8F8FF))
                    }
                }
            }
            // The loft's door: steel, a round window, a push bar; its sign over it.
            let dw = 20 * s, dh = 32 * s, dx = c.w * 50 / 100 - dw / 2, dy = lf - dh
            c.rect(dx - 2 * s, dy - 2 * s, dw + 4 * s, dh + 2 * s, C(0x22263A))
            c.rect(dx, dy, dw, dh, C(0x6A7284)); c.rect(dx, dy, 2 * s, dh, C(0x8A92A4)); c.rect(dx + dw - 2 * s, dy, 2 * s, dh, C(0x50586A))
            c.circle(dx + dw / 2, dy + 9 * s, 4 * s, C(0x2A3040)); c.circle(dx + dw / 2, dy + 9 * s, 3 * s, C(0x7AA8C8))
            c.rect(dx + dw / 2 - 2 * s, dy + 7 * s, s, 2 * s, C(0xD0E8F4))
            c.rect(dx + 3 * s, dy + 18 * s, dw - 6 * s, 2 * s, C(0x3A4050))
            let label = "TRAINING", lw = crawlTextWidth(label, scale: s) + 6 * s
            let lx = dx + dw / 2 - lw / 2, ly = dy - 13 * s
            c.rect(lx, ly, lw, 10 * s, C(0x8A2A5A)); c.rect(lx, ly, lw, s, C(0xC04E8E)); c.rect(lx, ly + 9 * s, lw, s, C(0x5A1A3A))
            crawlText(c, lx + 3 * s, ly + 3 * s, label, C(0xF8E8F0), scale: s)
            // A potted plant either side of the door.
            for px in [dx - 34 * s, dx + dw + 26 * s] {
                c.rect(px, lf - 8 * s, 8 * s, 8 * s, C(0xB86A48)); c.rect(px, lf - 8 * s, 8 * s, s, C(0xD88A60))
                c.ellipse(px + 4 * s, lf - 15 * s, 6 * s, 7 * s, C(0x3A6A44))
                c.ellipse(px + 3 * s, lf - 17 * s, 3 * s, 4 * s, C(0x58905A))
            }
            // The railing along the loft's edge, gold, its uprights close.
            c.rect(0, lf - 12 * s, c.w, 2 * s, gold); c.rect(0, lf - 12 * s, c.w, s, goldL)
            for x in stride(from: 2 * s, to: c.w, by: 6 * s) { c.rect(x, lf - 10 * s, s, 10 * s, goldD) }
            // The loft's floor: a thick slab on dark beams, two lamps hanging under it.
            c.rect(0, lf, c.w, 6 * s, C(0x5A5E78)); c.rect(0, lf, c.w, s, C(0x7A7E98)); c.rect(0, lf + 6 * s, c.w, 2 * s, C(0x1E2232))
            for x in stride(from: 8 * s, to: c.w, by: 40 * s) { c.rect(x, lf + 8 * s, 4 * s, 3 * s, C(0x22263A)) }
            for lx in [c.w * 34 / 100, c.w * 64 / 100] {
                let ly = lf + 8 * s
                c.rect(lx, ly, s, 14 * s, C(0x1E2232))
                c.rect(lx - 4 * s, ly + 14 * s, 9 * s, 4 * s, C(0xC04E8E)); c.rect(lx - 4 * s, ly + 14 * s, 9 * s, s, C(0xE07AB0))
                c.rect(lx - 2 * s, ly + 18 * s, 5 * s, s, C(0xFFE0A8))
            }
            // The ladder up, at the right.
            let ldx = c.w - 16 * s
            c.rect(ldx, lf - 12 * s, s, g - lf + 12 * s, C(0x8A92A4)); c.rect(ldx + 8 * s, lf - 12 * s, s, g - lf + 12 * s, C(0x5A6274))
            for y in stride(from: lf - 8 * s, to: g, by: 7 * s) { c.rect(ldx, y, 9 * s, s, C(0x7A8294)) }
        }

        // The food synthesiser: a steel cabinet, a dark screen with the menu on it, a status light (the moving layer
        // blinks it), the hatch with tonight's dinner on a plate, a row of buttons and a plinth.
        let sy = f.synth
        c.rect(sy.x - s, sy.y - s, sy.w + 2 * s, sy.h + s, C(0x2A3040))
        c.rect(sy.x, sy.y, sy.w, sy.h, C(0x8A92A0)); c.rect(sy.x, sy.y, 2 * s, sy.h, C(0xB0B8C4)); c.rect(sy.x + sy.w - 2 * s, sy.y, 2 * s, sy.h, C(0x5E6674))
        c.rect(sy.x, sy.y, sy.w, s, C(0xC8D0DA))
        c.rect(sy.x + 3 * s, sy.y + 2 * s, 12 * s, 7 * s, C(0x10202A))
        for (k, len) in [8, 6, 9].enumerated() { c.rect(sy.x + 4 * s, sy.y + (3 + k * 2) * s, len * s, s, C(0x5AD8E8, 0.8)) }
        c.rect(f.light.x - s, f.light.y - s, 4 * s, 4 * s, C(0x3A4250)); c.rect(f.light.x, f.light.y, 2 * s, 2 * s, C(0x2A5A3A))
        let hy = sy.y + 13 * s
        c.rect(sy.x + 3 * s, hy, sy.w - 6 * s, 13 * s, C(0x3A4250)); c.rect(sy.x + 4 * s, hy + s, sy.w - 8 * s, 11 * s, C(0x1A2028))
        c.rect(sy.x + 4 * s, hy + s, sy.w - 8 * s, s, C(0x5AD8E8, 0.35))
        c.rect(sy.x + 6 * s, hy + 9 * s, 10 * s, 2 * s, C(0xE8E8E8)); c.rect(sy.x + 6 * s, hy + 10 * s, 10 * s, s, C(0xB8B8C0))
        c.rect(sy.x + 8 * s, hy + 6 * s, 6 * s, 3 * s, C(0xA8582A)); c.rect(sy.x + 9 * s, hy + 6 * s, 3 * s, s, C(0xD08040))
        for k in 0..<3 { c.rect(sy.x + (5 + k * 5) * s, hy + 16 * s, 3 * s, 2 * s, [C(0xD84848), C(0xE8C040), C(0x48A8D8)][k]) }
        c.rect(sy.x - s, g - 5 * s, sy.w + 2 * s, 5 * s, C(0x4A5262)); c.rect(sy.x - s, g - 5 * s, sy.w + 2 * s, s, C(0x6A7282))

        // The couch: plum velvet, a high back, rolled arms, a pink cushion and a gold one, little gold feet.
        let cx = c.w * 22 / 100, cw = 60 * s
        let plum = C(0x6A3A5E), plumD = C(0x4C2844), plumL = C(0x845078)
        // The portrait over it first: a gold frame, Donut on pink.
        let pw = 13 * 2 * s, ph = 10 * 2 * s, ppx = cx + cw / 2 - pw / 2, ppy = g - 52 * s
        c.rect(ppx - 3 * s, ppy - 3 * s, pw + 6 * s, ph + 6 * s, goldD); c.rect(ppx - 3 * s, ppy - 3 * s, pw + 6 * s, s, goldL)
        c.rect(ppx - 2 * s, ppy - 2 * s, pw + 4 * s, ph + 4 * s, gold)
        c.rect(ppx, ppy, pw, ph, C(0xE07AB0)); c.rect(ppx, ppy + ph - 6 * s, pw, 6 * s, C(0xC85A98))
        crawlGrid(c, ppx, ppy, crawlDonutPortrait, ["y": C(0xF8D048), "b": C(0x6A4428), "e": C(0x7AE070), "p": C(0xF0A0B8),
                                                    "o": C(0xD08038)], cell: 2 * s)
        // The lamps either side: a brass arm, a pink shade lit underneath.
        for lx in [cx + 2 * s, cx + cw - 8 * s] {
            c.rect(lx + 3 * s, g - 37 * s, s, 6 * s, goldD); c.rect(lx + s, g - 31 * s, 5 * s, s, goldD)
            c.rect(lx, g - 43 * s, 7 * s, 5 * s, C(0xE890B8)); c.rect(lx, g - 43 * s, 7 * s, s, C(0xF8C0D8))
            c.rect(lx + s, g - 38 * s, 5 * s, s, C(0xFFE8C0))
        }
        c.rect(cx, g - 19 * s, cw, 10 * s, plum); c.rect(cx, g - 19 * s, cw, s, plumL)
        for k in 1..<3 { c.rect(cx + k * cw / 3, g - 18 * s, s, 9 * s, plumD) }
        c.rect(cx, g - 9 * s, cw, 4 * s, plumL); c.rect(cx, g - 6 * s, cw, s, plumD)
        for ax in [cx - 4 * s, cx + cw - 2 * s] {
            c.rect(ax, g - 13 * s, 6 * s, 8 * s, plum); c.rect(ax, g - 13 * s, 6 * s, 2 * s, plumL)
        }
        c.rect(cx - 4 * s, g - 5 * s, cw + 8 * s, 2 * s, plumD)
        for lx in [cx - 3 * s, cx + cw + 2 * s] { c.rect(lx, g - 3 * s, 2 * s, 3 * s, goldD) }
        c.rect(cx + 6 * s, g - 15 * s, 9 * s, 6 * s, C(0xE07AB0)); c.rect(cx + 6 * s, g - 15 * s, 9 * s, s, C(0xF4A8CC))
        c.rect(cx + cw - 15 * s, g - 14 * s, 8 * s, 5 * s, gold); c.rect(cx + cw - 15 * s, g - 14 * s, 8 * s, s, goldL)

        // Mongo's pet carrier: a big green crate, a grille door with two yellow eyes behind it, a handle on top, his
        // name on a plate.
        let mx = c.w * 60 / 100, mw = 42 * s, mh = 20 * s, my = g - mh
        c.rect(mx, my, mw, mh, C(0x4A6E48)); c.rect(mx, my, mw, 2 * s, C(0x6A9064)); c.rect(mx + mw - 3 * s, my, 3 * s, mh, C(0x3A5638))
        c.rect(mx, g - 3 * s, mw, 3 * s, C(0x34502F))
        c.rect(mx + mw / 2 - 5 * s, my - 3 * s, 10 * s, s, C(0x2E3A2C)); c.rect(mx + mw / 2 - 5 * s, my - 3 * s, s, 3 * s, C(0x2E3A2C))
        c.rect(mx + mw / 2 + 4 * s, my - 3 * s, s, 3 * s, C(0x2E3A2C))
        let gx = mx + 4 * s, gy = my + 4 * s, gw = 16 * s, gh = 12 * s
        c.rect(gx, gy, gw, gh, C(0x141A14))
        c.rect(gx + 4 * s, gy + 4 * s, 2 * s, s, C(0xF0D040)); c.rect(gx + 9 * s, gy + 4 * s, 2 * s, s, C(0xF0D040))
        for x in stride(from: gx, through: gx + gw, by: 3 * s) { c.rect(x, gy, s, gh, C(0xA8B0B8)) }
        c.rect(gx, gy, gw + s, s, C(0xC8D0D8)); c.rect(gx, gy + gh - s, gw + s, s, C(0x8890A0))
        let name = "MONGO", nw = crawlTextWidth(name, scale: s) + 2 * s
        let nx = gx + gw + 2 * s
        if nx + nw <= mx + mw - 3 * s {
            c.rect(nx, gy + 3 * s, nw, 7 * s, C(0xE8DCB8)); c.rect(nx, gy + 9 * s, nw, s, C(0xB8A880))
        }
        crawlText(c, nx + s, gy + 4 * s, name, C(0x2A3A28), scale: s)

        // Donut's hat stand: a brass pole on three feet, a pink sun hat and a black top hat on its hooks, and the
        // little gold tiara on its finial, a pink jewel in the middle.
        let hx = c.w * 85 / 100, top = g - 44 * s
        c.rect(hx, top, 2 * s, g - top, goldD); c.rect(hx, top, s, g - top, gold)
        c.rect(hx - 6 * s, g - 2 * s, 14 * s, 2 * s, goldD); c.rect(hx - 4 * s, g - 3 * s, 10 * s, s, gold)
        for (k, y) in [g - 34 * s, g - 28 * s].enumerated() {
            let dir = k == 0 ? -1 : 1
            c.rect(dir < 0 ? hx - 4 * s : hx + 2 * s, y, 4 * s, s, goldD)
        }
        c.rect(hx - 14 * s, g - 33 * s, 12 * s, 2 * s, C(0xE07AB0)); c.rect(hx - 11 * s, g - 37 * s, 6 * s, 4 * s, C(0xE890B8))
        c.rect(hx - 11 * s, g - 34 * s, 6 * s, s, C(0x8A2A5A)); c.rect(hx - 14 * s, g - 33 * s, 12 * s, s, C(0xF4A8CC))
        c.rect(hx + 3 * s, g - 34 * s, 6 * s, 6 * s, C(0x1E1E26)); c.rect(hx + 3 * s, g - 34 * s, 2 * s, 6 * s, C(0x3A3A48))
        c.rect(hx + s, g - 28 * s, 10 * s, 2 * s, C(0x1E1E26)); c.rect(hx + 3 * s, g - 30 * s, 6 * s, s, C(0x8A2A3A))
        c.rect(hx - 2 * s, top - s, 6 * s, 2 * s, goldD)
        let tiara = ["y.y.y", "yyjyy", "yyyyy"]
        crawlGrid(c, hx - 4 * s, top - 7 * s, tiara, ["y": C(0xF8D048), "j": C(0xF050A0)], cell: 2 * s)
        c.rect(hx - 4 * s, top - 7 * s, s, s, C(0xFFF0B0))

        // The floor: dark slate carpet, plain so the crew reads on it.
        c.ground(g, C(0x2A2E40), edge: C(0x3E4458), speck: C(0x242838), seed: 53)
    }

    /// The personal space's life: the food synthesiser's status light blinking green while it cooks, its screen's
    /// menu line scrolling, and the hatch's light coming up when the meal is ready.
    static func crawlPersonalLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlPersonalFrame(c, g), l = f.light
        let beat = t.truncatingRemainder(dividingBy: 1.6)
        if beat < 0.8 {
            c.rect(l.x - s, l.y - s, 4 * s, 4 * s, C(0x60FF90, 0.25))
            c.rect(l.x, l.y, 2 * s, 2 * s, C(0x70FF98)); c.rect(l.x, l.y, s, s, C(0xE0FFE8))
        }
        // A cursor ticking along the screen's bottom line.
        let step = Int(t * 3) % 10
        c.rect(f.synth.x + (4 + step) * s, f.synth.y + 8 * s, s, s, C(0xE0FCFF))
    }
}

// MARK: - The Desperado Club casino

extension Scenes {
    /// Where things stand in the casino, shared by the still picture and the moving layer: the prize wheel's centre
    /// and radius, the club's neon sign, and (on the screen saver) the main hall's ceiling, where the floors above
    /// begin.
    static func crawlDesperadoFrame(_ c: PixelCanvas, _ g: Int) -> (wheel: (x: Int, y: Int, r: Int), sign: (x: Int, y: Int),
                                                                   ceiling: Int) {
        let s = unit(g)
        let wheel = (x: c.w * 14 / 100, y: g - 35 * s, r: 20 * s)
        let sign = (x: c.w / 2 - crawlTextWidth("DESPERADO", scale: 2 * s) / 2, y: g - 60 * s)
        return (wheel, sign, isTall(c) ? g - 72 * s : -1)
    }

    /// The prize wheel's face turned to `angle` radians: twelve wedges in purple, gold, pink and teal with dark
    /// spokes between, inside a gold rim, a gold hub on top.
    static func crawlPrizeWheel(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, _ s: Int, angle: Double) {
        let wedges = [C(0x7A2AB8), C(0xE8B838), C(0xD83A88), C(0x2AA0A8)]
        let shade = [C(0x5A1A8A), C(0xB88A20), C(0xA82A68), C(0x1A7880)]
        let inner = r - 2 * s, wedge = Double.pi * 2 / 12
        for dy in stride(from: -r, to: r + s, by: s) {
            for dx in stride(from: -r, to: r + s, by: s) {
                let d2 = dx * dx + dy * dy
                if d2 > r * r { continue }
                if d2 > inner * inner { c.rect(cx + dx, cy + dy, s, s, C(0xD8A838)); continue }
                var a = atan2(Double(dy), Double(dx)) - angle
                a = a.truncatingRemainder(dividingBy: Double.pi * 2)
                if a < 0 { a += Double.pi * 2 }
                let k = Int(a / wedge) % 12, frac = a / wedge - Double(Int(a / wedge))
                let far = Double(d2) > Double(inner * inner) * 0.55
                var col = far ? wedges[k % 4] : shade[k % 4]
                if frac < 0.12 && d2 > 9 * s * s { col = C(0x2A1030) }
                c.rect(cx + dx, cy + dy, s, s, col)
            }
        }
        c.circle(cx, cy, 4 * s, C(0x9A7020)); c.circle(cx, cy, 3 * s, C(0xF4D470)); c.rect(cx - s, cy - s, s, s, C(0xFFF4C0))
    }

    /// The Desperado Club casino: the dungeon's swankiest club, all neon purple and gold. A deep purple wall with gold
    /// art deco fans; the club's name in pink-purple neon over everything (DESPERADO); a gold neon tube running the
    /// length of the wall; on the left a big prize wheel on its gold stand, bulbs round its rim and a pointer at the
    /// top; on the right the VIP door, a red velvet curtain in a gold arch with VIP in teal neon over it, velvet ropes
    /// on gold posts in front. The floor is dark plum carpet. On the screen saver the club's floors stack up above
    /// the hall: galleries behind gold railings, a row of glowing arches on each, a gold number for each floor.
    static func crawlDesperado(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = crawlDesperadoFrame(c, g)
        let wall = C(0x24123A), wallD = C(0x180A28), wallL = C(0x30184C)
        let gold = C(0xD8A838), goldD = C(0x9A7020), goldL = C(0xF4D470)

        // The wall, deep purple, with gold-edged art deco fans in a row, dim so they stay behind everything.
        c.rect(0, 0, c.w, g, wall)
        for x in stride(from: c.w * 30 / 100, to: c.w * 72 / 100, by: 34 * s) {
            let fy = g - 16 * s
            for k in 0..<5 {
                let a = Double.pi * (1.0 + Double(k + 1) / 6.0)
                let ex = Double(x) + cos(a) * Double(18 * s), ey = Double(fy) + sin(a) * Double(18 * s)
                c.glowLine(Double(x), Double(fy), ex, ey, core: wallL, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            }
            for k in 0..<18 {
                let a = Double.pi * (1.0 + Double(k) / 17.0)
                c.rect(x + Int(cos(a) * Double(18 * s)), fy + Int(sin(a) * Double(18 * s)), s, s, C(0x5A3A2A))
            }
        }
        // The wainscot along the floor: dark velvet, a gold rail on top.
        c.rect(0, g - 14 * s, c.w, 14 * s, wallD)
        c.rect(0, g - 15 * s, c.w, 2 * s, goldD); c.rect(0, g - 15 * s, c.w, s, gold)

        // On the screen saver: the floors above. The hall's ceiling is a gold cornice; over it, gallery after gallery,
        // each with its row of glowing arches (rooms, bars, tables) behind a gold railing, and its number in gold.
        if f.ceiling > 0 {
            var base = f.ceiling, level = 2
            while base > 0 {
                let top = base - 54 * s
                c.rect(0, max(0, top), c.w, base - max(0, top), level % 2 == 0 ? C(0x1E0E32) : C(0x22103A))
                for (k, ax) in stride(from: 24 * s, to: c.w - 24 * s, by: 64 * s).enumerated() {
                    let ay = base - 34 * s, aw = 18 * s
                    let lit = [C(0xC04AE0), C(0x40C8D0), C(0xE8B848)][(k + level) % 3]
                    c.rect(ax - s, ay + 8 * s, aw + 2 * s, 26 * s, goldD)
                    c.ellipse(ax + aw / 2, ay + 9 * s, aw / 2 + s, 9 * s, goldD)
                    c.rect(ax, ay + 9 * s, aw, 25 * s, lit.alpha(0.4)); c.ellipse(ax + aw / 2, ay + 9 * s, aw / 2, 8 * s, lit.alpha(0.4))
                    c.rect(ax + 2 * s, ay + 12 * s, aw - 4 * s, 22 * s, lit.alpha(0.3))
                }
                crawlText(c, 4 * s, base - 48 * s, String(level), goldL, scale: 2 * s)
                c.rect(0, base - 10 * s, c.w, 2 * s, gold); c.rect(0, base - 10 * s, c.w, s, goldL)
                for x in stride(from: 2 * s, to: c.w, by: 5 * s) { c.rect(x, base - 8 * s, s, 8 * s, goldD) }
                c.rect(0, base, c.w, 4 * s, C(0x3A2050)); c.rect(0, base, c.w, s, gold); c.rect(0, base + 3 * s, c.w, s, goldD)
                base = top; level += 1
            }
            // Under the ceiling: a row of gold pendant lamps.
            for x in stride(from: c.w / 10, to: c.w, by: c.w / 5) {
                c.rect(x, f.ceiling + 4 * s, s, 6 * s, goldD)
                c.rect(x - 3 * s, f.ceiling + 10 * s, 7 * s, 3 * s, gold); c.rect(x - 2 * s, f.ceiling + 13 * s, 5 * s, s, C(0xFFE8A0))
            }
        }

        // The club's sign: a dark board with a gold edge, DESPERADO in pink-purple neon.
        let sg = f.sign, sw = crawlTextWidth("DESPERADO", scale: 2 * s)
        c.rect(sg.x - 5 * s, sg.y - 4 * s, sw + 10 * s, 18 * s, goldD)
        c.rect(sg.x - 4 * s, sg.y - 3 * s, sw + 8 * s, 16 * s, C(0x12061C))
        crawlNeonText(c, sg.x, sg.y, "DESPERADO", C(0xF4A8FF), C(0xC040F0, 0.35), scale: 2 * s, s: s)
        // The gold neon tube along the wall, broken by the sign.
        crawlNeonLine(c, 0, sg.x - 8 * s, g - 46 * s, C(0xFFE890), C(0xE8B838, 0.25), s: s)
        crawlNeonLine(c, sg.x + sw + 8 * s, c.w, g - 46 * s, C(0xFFE890), C(0xE8B838, 0.25), s: s)

        // The prize wheel: a gold stand on a round foot, a soft glow behind it, the face (still here; the moving
        // layer turns it), the bulbs round the rim unlit and the pointer at the top.
        let w = f.wheel
        c.ellipse(w.x, w.y, w.r + 6 * s, w.r + 6 * s, C(0xC040F0, 0.08))
        c.rect(w.x - 2 * s, w.y, 4 * s, g - w.y, goldD); c.rect(w.x - 2 * s, w.y, s, g - w.y, gold)
        c.rect(w.x - 9 * s, g - 3 * s, 18 * s, 3 * s, goldD); c.rect(w.x - 9 * s, g - 3 * s, 18 * s, s, goldL)
        crawlPrizeWheel(c, w.x, w.y, w.r, s, angle: 0)
        for k in 0..<12 {
            let a = Double(k) * Double.pi / 6
            let bx = w.x + Int(cos(a) * Double(w.r - s)), by = w.y + Int(sin(a) * Double(w.r - s))
            c.rect(bx - s, by - s, 2 * s, 2 * s, C(0xA88848))
        }

        // The VIP door: a gold arch, the red velvet curtain in folds, VIP in teal neon over it.
        let dw = 34 * s, dh = 36 * s, dx = c.w * 79 / 100, dy = g - dh
        c.rect(dx - 3 * s, dy, dw + 6 * s, dh, goldD); c.ellipse(dx + dw / 2, dy, dw / 2 + 3 * s, 10 * s, goldD)
        c.rect(dx - 2 * s, dy, dw + 4 * s, dh, gold); c.ellipse(dx + dw / 2, dy, dw / 2 + 2 * s, 9 * s, gold)
        c.rect(dx, dy, dw, dh, C(0x6A1430)); c.ellipse(dx + dw / 2, dy, dw / 2, 8 * s, C(0x6A1430))
        for x in stride(from: dx + 2 * s, to: dx + dw, by: 6 * s) {
            c.rect(x, dy - 4 * s, 2 * s, dh + 4 * s, C(0x8A2040)); c.rect(x + 2 * s, dy - 4 * s, s, dh + 4 * s, C(0x4E0C22))
        }
        c.rect(dx + dw / 2 - s, dy - 6 * s, 2 * s, dh + 6 * s, C(0x3A0818))
        let vip = "VIP", vw = crawlTextWidth(vip, scale: 2 * s)
        crawlNeonText(c, dx + dw / 2 - vw / 2, g - 60 * s, vip, C(0xB0FFF8), C(0x30D0D0, 0.35), scale: 2 * s, s: s)
        // The velvet ropes on their gold posts, sagging between them.
        let posts = [dx - 26 * s, dx - 4 * s, dx + dw + 4 * s]
        for (k, x) in posts.enumerated() {
            if k + 1 < posts.count {
                let x1 = posts[k + 1], mid = Double(x + x1) / 2, half = Double(x1 - x) / 2
                for rx in stride(from: x, to: x1, by: s) {
                    let u = (Double(rx) - mid) / half
                    let ry = g - 10 * s + Int((1 - u * u) * Double(4 * s))
                    c.rect(rx, ry, s, 2 * s, C(0xA81A3A)); c.rect(rx, ry, s, s, C(0xD83A5A))
                }
            }
            c.rect(x - s, g - 11 * s, 2 * s, 11 * s, goldD); c.rect(x - s, g - 11 * s, s, 11 * s, gold)
            c.rect(x - 2 * s, g - 13 * s, 4 * s, 2 * s, goldL); c.rect(x - 3 * s, g - s, 6 * s, s, goldD)
        }

        // The floor: dark plum carpet, plain under the crew, the neon's purple light on it.
        c.ground(g, C(0x2A1430), edge: C(0x4A2A5A), speck: C(0x22102A), seed: 67)
        c.ellipse(c.w / 2, g + 3 * s, c.w / 3, 4 * s, C(0xC040F0, 0.06))
    }

    /// The casino's life: the prize wheel spinning (fast, then slowing to a stop, then off again), the bulbs round
    /// its rim chasing, and the neon buzzing: the sign's glow breathing and now and then a letter flickering out.
    static func crawlDesperadoLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlDesperadoFrame(c, g), w = f.wheel
        // A spin every eight seconds: quick at first, easing out to a stop, then a pause.
        let round = Int(t / 8), into = t.truncatingRemainder(dividingBy: 8)
        let k = min(1, into / 6), eased = 1 - (1 - k) * (1 - k)
        let angle = Double(round) * 2.3 + eased * 9.0
        crawlPrizeWheel(c, w.x, w.y, w.r, s, angle: angle)
        for b in 0..<12 {
            let a = Double(b) * Double.pi / 6
            let bx = w.x + Int(cos(a) * Double(w.r - s)), by = w.y + Int(sin(a) * Double(w.r - s))
            let on = (b + Int(t * 6)) % 3 == 0
            c.rect(bx - s, by - s, 2 * s, 2 * s, on ? C(0xFFF4C0) : C(0xA88848))
        }
        // The pointer at the top, a red-and-white tick.
        let py = w.y - w.r - 3 * s
        c.rect(w.x - 3 * s, py, 6 * s, 2 * s, C(0xF0F0F0)); c.rect(w.x - 2 * s, py + 2 * s, 4 * s, 2 * s, C(0xD83030))
        c.rect(w.x - s, py + 4 * s, 2 * s, s, C(0xD83030))
        // The neon: its glow breathing, and a letter buzzing out for a moment now and then.
        let sg = f.sign, sw = crawlTextWidth("DESPERADO", scale: 2 * s), glow = 0.06 + 0.05 * sin(t * 2.3)
        c.rect(sg.x - 3 * s, sg.y - 2 * s, sw + 6 * s, 14 * s, C(0xC040F0, glow))
        let flick = t.truncatingRemainder(dividingBy: 5.0)
        if flick > 4.4 && Int(t * 20) % 2 == 0 {
            let letter = Int(t / 5) % 9
            c.rect(sg.x + letter * 8 * s - s, sg.y - s, 8 * s, 12 * s, C(0x12061C))
        }
    }
}

// MARK: - Odette's After Hours studio

/// The mantis in the middle of Odette's set, front on: the triangle head with its big eyes and feelers, the folded
/// forelegs raised, the long body.
private let crawlMantis = [
    ".d.................d.",
    "..d...............d..",
    "...d.............d...",
    "....eegggggggggee....",
    ".....ggggggggggg.....",
    "......ggggggggg......",
    ".......ggdddgg.......",
    "........ggggg........",
    ".........ggg.........",
    "..........g..........",
    "..l.......g.......l..",
    "..ll......g......ll..",
    "...ll.....g.....ll...",
    "....lll..ggg..lll....",
    "......llgggggll......",
    ".........ggg.........",
    "........ggggg........",
    "........ggggg........",
    "........ggggg........",
    ".........ggg.........",
    "..........d..........",
]

extension Scenes {
    /// Where things stand in the studio, shared by the still picture and the moving layer: the ON AIR and APPLAUSE
    /// signs' boxes, and (on the screen saver) the lighting gantry's two trusses.
    static func crawlStudioFrame(_ c: PixelCanvas, _ g: Int) -> (onAir: (x: Int, y: Int, w: Int, h: Int),
                                                                applause: (x: Int, y: Int, w: Int, h: Int), set: (x0: Int, x1: Int),
                                                                trusses: [Int]) {
        let s = unit(g)
        let x0 = c.w * 14 / 100, x1 = c.w * 86 / 100
        let ow = crawlTextWidth("ON AIR", scale: s) + 6 * s, aw = crawlTextWidth("APPLAUSE", scale: s) + 6 * s
        let onAir = (x: max(s, x0 / 2 - ow / 2), y: g - 62 * s, w: ow, h: 11 * s)
        let applause = (x: min(c.w - aw - s, x1 + (c.w - x1) / 2 - aw / 2), y: g - 62 * s, w: aw, h: 11 * s)
        return (onAir, applause, (x0, x1), isTall(c) ? [g - 128 * s, g - 196 * s] : [])
    }

    /// Odette's After Hours studio: a calm late-night talk show set. Studio black at the sides; in the middle the set
    /// itself, warm latte flats framed in cream, slatted at the sides, and in their centre a big round medallion of a
    /// green praying mantis, the show's emblem; a cream sofa for the guests on the left and a cream armchair for the
    /// host on the right; a studio lamp on a stand at each side, its light falling on the set; the ON AIR sign lit red
    /// on the left and the APPLAUSE sign on the right. The floor is dark and glossy. On the screen saver the set's top
    /// carries the show's name (AFTER HOURS) and above it hangs the lighting gantry: two lattice trusses across, lamps
    /// on them pointing down, towers at the sides and a catwalk at the top.
    static func crawlStudio(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlStudioFrame(c, g)
        let cream = C(0xE6D8BC), creamD = C(0xC8B898), creamL = C(0xF6ECD8)
        let latte = C(0x8A7660), latteD = C(0x76644E), steel = C(0x5A5E68), steelD = C(0x3A3C44)

        // The studio around the set: black, its far wall a little lighter at the bottom.
        c.rect(0, 0, c.w, g, C(0x16141A)); c.rect(0, g - 40 * s, c.w, 40 * s, C(0x1C1A20))

        // On the screen saver: the gantry. The catwalk at the top, two trusses across (top and bottom chords, a
        // zigzag between), lamps hung under them, towers up the sides, cables drooping, and soft cones of light.
        let trusses = f.trusses
        if tall {
            let catwalk = (trusses.last ?? g) - 52 * s
            if catwalk > 0 {
                c.rect(0, catwalk, c.w, 3 * s, steel); c.rect(0, catwalk - 9 * s, c.w, s, steel)
                for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x, catwalk - 9 * s, s, 9 * s, steelD) }
                c.rect(0, 0, c.w, catwalk - 9 * s, C(0x111015))
            }
            for tx in [2 * s, c.w - 10 * s] {
                let ty = trusses.last ?? 0
                c.rect(tx, ty, s, g - ty, steel); c.rect(tx + 7 * s, ty, s, g - ty, steel)
                for y in stride(from: ty, to: g - 8 * s, by: 8 * s) {
                    c.glowLine(Double(tx), Double(y), Double(tx + 7 * s), Double(y + 8 * s), core: steelD, glow: C(0, 0),
                               coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
                }
            }
            for (n, ty) in trusses.enumerated() {
                for x in stride(from: 0, to: c.w, by: 8 * s) {
                    c.glowLine(Double(x), Double(ty), Double(x + 4 * s), Double(ty + 7 * s), core: steelD, glow: C(0, 0),
                               coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
                    c.glowLine(Double(x + 4 * s), Double(ty + 7 * s), Double(x + 8 * s), Double(ty), core: steelD, glow: C(0, 0),
                               coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
                }
                c.rect(0, ty, c.w, s, C(0x7A7E88)); c.rect(0, ty + 7 * s, c.w, s, steel)
                // A cable drooping under it.
                for x in stride(from: 0, to: c.w, by: s) {
                    let u = Double(x % (c.w / 3)) / Double(c.w / 3)
                    c.rect(x, ty + 9 * s + Int(sin(u * Double.pi) * Double(5 * s)), s, s, C(0x2A2830))
                }
                // Its lamps: big black cans on yokes, a warm or cream gel lit at the face, a soft cone under each.
                let first = n == 0 ? 30 * s : 54 * s
                for (j, lx) in stride(from: first, to: c.w - 12 * s, by: 52 * s).enumerated() {
                    let ly = ty + 8 * s, gel = j % 2 == 0 ? C(0xFFE8B0) : C(0xFFF6E4)
                    for k in 0..<12 {
                        let half = (4 + k) * s
                        c.rect(lx + 5 * s - half, ly + (14 + k * 3) * s, half * 2, 3 * s, gel.alpha(0.035 - Double(k) * 0.002))
                    }
                    c.rect(lx + 4 * s, ly, 2 * s, 2 * s, steelD); c.rect(lx - s, ly + 2 * s, 12 * s, s, steelD)
                    c.rect(lx - s, ly + 2 * s, s, 6 * s, steelD); c.rect(lx + 10 * s, ly + 2 * s, s, 6 * s, steelD)
                    c.rect(lx, ly + 4 * s, 10 * s, 9 * s, C(0x2A2A32)); c.rect(lx, ly + 4 * s, 2 * s, 9 * s, C(0x4A4A56))
                    c.rect(lx - s, ly + 13 * s, 12 * s, s, steelD)
                    c.rect(lx + s, ly + 12 * s, 8 * s, 2 * s, gel)
                }
            }
        }

        // The set: latte flats framed in cream, vertical slats on the side flats, a cream cornice along the top.
        let x0 = f.set.x0, x1 = f.set.x1, top = tall ? g - 86 * s : 0
        c.rect(x0, top, x1 - x0, g - top, latte)
        for x in stride(from: x0 + 6 * s, to: x1 - 4 * s, by: 8 * s) where abs(x - c.w / 2) > 24 * s {
            c.rect(x, top, 2 * s, g - top, latteD)
        }
        c.rect(x0, top, 3 * s, g - top, cream); c.rect(x1 - 3 * s, top, 3 * s, g - top, creamD); c.rect(x0, top, s, g - top, creamL)
        for x in [c.w / 2 - 24 * s, c.w / 2 + 22 * s] { c.rect(x, top, 2 * s, g - top, creamD) }
        if tall {
            c.rect(x0 - 3 * s, top - 14 * s, x1 - x0 + 6 * s, 14 * s, cream); c.rect(x0 - 3 * s, top - 14 * s, x1 - x0 + 6 * s, s, creamL)
            c.rect(x0 - 3 * s, top - s, x1 - x0 + 6 * s, s, creamD)
            let title = "AFTER HOURS", tw = crawlTextWidth(title, scale: 2 * s)
            crawlText(c, c.w / 2 - tw / 2, top - 12 * s, title, C(0x4A6A50), scale: 2 * s)
        }
        // The mantis medallion: a cream ring, a sage disc, the mantis on it.
        let mx = c.w / 2, my = g - 42 * s
        c.circle(mx, my, 16 * s, creamD); c.circle(mx, my, 15 * s, cream); c.circle(mx, my, 13 * s, C(0x22342A))
        c.circle(mx - 2 * s, my - 2 * s, 9 * s, C(0x2A3E32))
        crawlGrid(c, mx - 10 * s, my - 10 * s, crawlMantis, ["d": C(0xA8D07A), "e": C(0xF0F4A8), "g": C(0x84B860),
                                                           "l": C(0xB8E08A)], cell: s)
        // The set's base: a dark walnut skirting with a cream line along its top.
        c.rect(x0, g - 10 * s, x1 - x0, 10 * s, C(0x3A2E26)); c.rect(x0, g - 10 * s, x1 - x0, s, cream)

        // The studio lamps at the sides: a tripod, a pole, a black can turned towards the set, a cone of its light.
        for (k, lx) in [c.w * 5 / 100, c.w * 95 / 100].enumerated() {
            let dir = k == 0 ? 1 : -1, hy = g - 40 * s
            c.rect(lx, hy, s, g - hy, steel)
            c.glowLine(Double(lx), Double(g - 6 * s), Double(lx - 5 * s), Double(g), core: steel, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            c.glowLine(Double(lx), Double(g - 6 * s), Double(lx + 5 * s), Double(g), core: steel, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            for j in 0..<12 {
                let half = (3 + j) * s / 2 + s
                c.rect(lx + dir * (6 + j * 3) * s - s, hy + 2 * s - half / 2, 3 * s, half, C(0xFFF0D0, 0.03))
            }
            let cx = dir > 0 ? lx - 2 * s : lx - 6 * s
            c.rect(cx, hy - 4 * s, 9 * s, 8 * s, C(0x2A2A32)); c.rect(cx, hy - 4 * s, 9 * s, s, C(0x4A4A56))
            c.rect(dir > 0 ? cx + 8 * s : cx, hy - 3 * s, s, 6 * s, C(0xFFF0C8))
        }

        // The signs: ON AIR lit red (the moving layer pulses its glow), APPLAUSE dark until it blinks.
        let oa = f.onAir
        c.rect(oa.x - s, oa.y - s, oa.w + 2 * s, oa.h + 2 * s, C(0xFF3030, 0.3))
        c.rect(oa.x, oa.y, oa.w, oa.h, C(0x8A1414)); c.rect(oa.x, oa.y, oa.w, s, C(0xC03030)); c.rect(oa.x, oa.y + oa.h - s, oa.w, s, C(0x5A0A0A))
        crawlText(c, oa.x + 3 * s, oa.y + 3 * s, "ON AIR", C(0xFFE8E0), scale: s)
        let ap = f.applause
        c.rect(ap.x, ap.y, ap.w, ap.h, C(0x2A1A14)); c.rect(ap.x, ap.y, ap.w, s, C(0x4A3428))
        crawlText(c, ap.x + 3 * s, ap.y + 3 * s, "APPLAUSE", C(0x6A4A30), scale: s)

        // The guests' sofa: cream, a low back in three cushions, rolled arms, a sage cushion, walnut feet.
        let sx = c.w * 22 / 100, sw = 54 * s
        c.rect(sx, g - 17 * s, sw, 9 * s, creamD); c.rect(sx, g - 17 * s, sw, s, cream)
        for k in 1..<3 { c.rect(sx + k * sw / 3, g - 16 * s, s, 8 * s, C(0xB0A080)) }
        c.rect(sx, g - 8 * s, sw, 4 * s, cream); c.rect(sx, g - 8 * s, sw, s, creamL); c.rect(sx, g - 5 * s, sw, s, creamD)
        for ax in [sx - 4 * s, sx + sw - 2 * s] { c.rect(ax, g - 12 * s, 6 * s, 8 * s, cream); c.rect(ax, g - 12 * s, 6 * s, 2 * s, creamL) }
        c.rect(sx - 4 * s, g - 4 * s, sw + 8 * s, s, C(0xA89878))
        for lx in [sx - 3 * s, sx + sw + 2 * s] { c.rect(lx, g - 3 * s, 2 * s, 3 * s, C(0x4A3424)) }
        c.rect(sx + 6 * s, g - 14 * s, 9 * s, 6 * s, C(0x6A9A6A)); c.rect(sx + 6 * s, g - 14 * s, 9 * s, s, C(0x8AB88A))
        // The host's armchair, the same cream.
        let hx = c.w * 70 / 100, hw = 20 * s
        c.rect(hx, g - 19 * s, hw, 11 * s, creamD); c.rect(hx, g - 19 * s, hw, s, cream)
        c.rect(hx, g - 8 * s, hw, 4 * s, cream); c.rect(hx, g - 8 * s, hw, s, creamL)
        for ax in [hx - 4 * s, hx + hw - 2 * s] { c.rect(ax, g - 12 * s, 6 * s, 8 * s, cream); c.rect(ax, g - 12 * s, 6 * s, 2 * s, creamL) }
        c.rect(hx - 4 * s, g - 4 * s, hw + 8 * s, s, C(0xA89878))
        for lx in [hx - 3 * s, hx + hw + 2 * s] { c.rect(lx, g - 3 * s, 2 * s, 3 * s, C(0x4A3424)) }

        // The floor: dark and glossy, a faint sheen of the set's light across it.
        c.ground(g, C(0x2A2630), edge: C(0x4A4450), speck: C(0x24202A), seed: 79)
        c.rect(x0, g + 2 * s, x1 - x0, s, C(0xE6D8BC, 0.06))
    }

    /// The studio's life: ON AIR's glow pulsing slowly, and the APPLAUSE sign blinking on and off when it's time
    /// to clap, a little bright halo round it while it's lit.
    static func crawlStudioLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlStudioFrame(c, g), oa = f.onAir, ap = f.applause
        let glow = 0.12 + 0.12 * sin(t * 1.8)
        c.rect(oa.x - 2 * s, oa.y - 2 * s, oa.w + 4 * s, s, C(0xFF3030, glow)); c.rect(oa.x - 2 * s, oa.y + oa.h + s, oa.w + 4 * s, s, C(0xFF3030, glow))
        c.rect(oa.x - 2 * s, oa.y - s, s, oa.h + 2 * s, C(0xFF3030, glow)); c.rect(oa.x + oa.w + s, oa.y - s, s, oa.h + 2 * s, C(0xFF3030, glow))
        // APPLAUSE: lit for half a second, dark for half, through a bout of clapping, then quiet a while.
        let bout = t.truncatingRemainder(dividingBy: 9)
        if bout < 4 && t.truncatingRemainder(dividingBy: 1) < 0.5 {
            c.rect(ap.x - s, ap.y - s, ap.w + 2 * s, ap.h + 2 * s, C(0xFFB040, 0.3))
            c.rect(ap.x, ap.y, ap.w, ap.h, C(0xC86A1A)); c.rect(ap.x, ap.y, ap.w, s, C(0xF09A3A))
            crawlText(c, ap.x + 3 * s, ap.y + 3 * s, "APPLAUSE", C(0xFFF4D8), scale: s)
        }
    }
}
