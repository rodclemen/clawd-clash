import Foundation

// Gremlins: Kingston Falls at Christmas, Mr. Wing's shop in Chinatown, and the gene lab in the Clamp Centre.

let clawdbergScenes4: [Location: Place] = [
    .kingstonFalls: Place(name: "Kingston Falls", panel: 0x0E1426, still: Scenes.kingstonFalls,
                          moving: Scenes.kingstonFallsLife),
    .wingShop: Place(name: "Mr. Wing's Shop", panel: 0x22100C, still: Scenes.wingShop, moving: Scenes.wingShopLife),
    .clampCentre: Place(name: "The Clamp Centre", panel: 0x101C1E, still: Scenes.clampCentre,
                        moving: Scenes.clampCentreLife),
]

// MARK: - Shared bits for this file

/// Signwriting in a 3×5 pixel font (M and W five wide, N four), centred on `cx`.
private func cb4Text(_ c: PixelCanvas, _ text: String, cx: Int, y: Int, s: Int, col: Px) {
    let width = text.reduce(0) { $0 + (cb4Glyphs[$1]?[0].count ?? 3) + 1 } - 1
    var x = cx - width * s / 2
    for ch in text {
        let rows = cb4Glyphs[ch] ?? cb4Glyphs[" "]!
        for (dy, row) in rows.enumerated() {
            for (dx, p) in row.enumerated() where p == "#" { c.rect(x + dx * s, y + dy * s, s, s, col) }
        }
        x += (rows[0].count + 1) * s
    }
}

private let cb4Glyphs: [Character: [String]] = [
    "A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"], "G": [".##", "#..", "#.#", "#.#", ".##"],
    "H": ["#.#", "#.#", "###", "#.#", "#.#"], "I": ["###", ".#.", ".#.", ".#.", "###"],
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"], "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "O": [".#.", "#.#", "#.#", "#.#", ".#."], "P": ["##.", "#.#", "##.", "#..", "#.."],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"], "S": [".##", "#..", ".#.", "..#", "##."],
    "T": ["###", ".#.", ".#.", ".#.", ".#."], "W": ["#...#", "#...#", "#.#.#", "##.##", "#...#"],
    "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
    " ": [".", ".", ".", ".", "."],
]

/// A short wiggly smoke or steam trail rising from (`x`, `y`), `n` puffs long, drifting with the clock.
private func cb4Wisp(_ c: PixelCanvas, x: Int, y: Int, n: Int, s: Int, t: Double, col: Px) {
    for k in 0..<n {
        let age = (t * 0.6 + Double(k) / Double(n)).truncatingRemainder(dividingBy: 1)
        let sway = sin(t * 1.3 + age * 6) * Double(3 * s) * age
        let py = y - Int(age * Double(n * 4 * s))
        c.rect(x + Int(sway), py, s + Int(age * 2) * s, s, col.alpha(1 - age))
    }
}

// MARK: - Kingston Falls

extension Scenes {
    /// Where things are on Main Street: the bank's middle and roof, the shops' roof line, the tree in the square
    /// and, on the screen saver, the hill with the Peltclawd house on it.
    private static func kfFrame(_ c: PixelCanvas, _ g: Int) -> (bank: Int, bankRoof: Int, shopTop: Int, tree: Int,
                                                                hill: Int, house: Int) {
        let s = unit(g), tall = isTall(c)
        return (c.w * 62 / 100, g - (tall ? 40 : 32) * s, g - (tall ? 32 : 26) * s, c.w * 34 / 100,
                g - 110 * s, c.w * 70 / 100)
    }

    /// Main Street, Kingston Falls, the week before Christmas: a deep blue night, snow heaped on every roof and
    /// ledge, the shop fronts lit warm with strings of coloured bulbs along their eaves, the bank with its columns
    /// and clock, the cinema's marquee, and the town's Christmas tree in the square. On the screen saver the town
    /// climbs a snowy hill under the stars, a church spire and the Peltclawd house up top with its windows lit.
    static func kingstonFalls(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = kfFrame(c, g)
        c.gradient(0, g, C(0x0A1030), C(0x2A3460), bands: 7)
        c.stars(0, f.shopTop - 10 * s, density: 70, seed: 9)
        if tall { kfHill(c, g) }
        // The shops down the street.
        let names = ["TOYS", "", "COLONY", "", "DINER", "HARDWARE", ""]
        var x = -4 * s
        var k = 0, shop = 0
        while x < c.w {
            let w = (34 + Int(noise(k * 3 + 37) * 16)) * s
            let h = (g - f.shopTop) - Int(noise(k * 3 + 38) * 6) * s
            let mid = x + w / 2
            if abs(mid - f.bank) > 36 * s + w / 2 && abs(mid - f.tree) > 12 * s + w / 2 {
                let col = [C(0x5A2E2A), C(0x3E3A4A), C(0x6A4A34)][k % 3]
                c.rect(x, g - h, w, h, col)
                c.rect(x - s, g - h - 2 * s, w + 2 * s, 3 * s, C(0xEEF2FA))   // snow on the roof
                for wx in stride(from: x + 4 * s, to: x + w - 7 * s, by: 9 * s) {
                    c.rect(wx, g - h + 4 * s, 5 * s, 5 * s, C(0xF2C870, 0.85)); c.rect(wx, g - h + 9 * s, 5 * s, s, C(0xEEF2FA))
                }
                let name = names[shop % names.count]
                shop += 1
                if name == "COLONY" {   // the cinema's marquee
                    c.rect(x + 2 * s, g - 16 * s, w - 4 * s, 7 * s, C(0xF6E8B0))
                    cb4Text(c, name, cx: mid, y: g - 15 * s, s: s, col: C(0xB8202A))
                } else if !name.isEmpty {
                    c.rect(x + 3 * s, g - 15 * s, w - 6 * s, 6 * s, C(0x1A1A24))
                    cb4Text(c, name, cx: mid, y: g - 15 * s + s / 2, s: s, col: C(0xF2E6C8))
                }
                c.rect(x + 3 * s, g - 9 * s, w - 6 * s, 9 * s, C(0x2A1E1A))
                c.rect(x + 4 * s, g - 8 * s, w - 8 * s, 5 * s, C(0xF2D898, 0.55))
                c.rect(x + 3 * s, g - 9 * s, w - 6 * s, s, C(0xEEF2FA))
                // The bulbs along the eaves (the blinking ones are in the moving layer).
                for bx in stride(from: x, to: x + w, by: 3 * s) { c.rect(bx, g - h + s, s, s, C(0x3A3A2A)) }
            }
            x += w + 2 * s; k += 1
        }
        // The bank: stone, a pediment, four columns, its clock and name.
        let bl = f.bank - 34 * s, bw = 68 * s
        c.rect(bl, f.bankRoof, bw, g - f.bankRoof, C(0xB8B0A0))
        for i in 0..<5 { c.rect(f.bank - 30 * s + i * 6 * s, f.bankRoof - (i + 1) * 2 * s, 60 * s - i * 12 * s, 2 * s, C(0xC8C0B0)) }
        for i in 0..<5 { c.rect(f.bank - 30 * s + i * 6 * s, f.bankRoof - (i + 1) * 2 * s - s, 60 * s - i * 12 * s, s, C(0xEEF2FA)) }
        c.circle(f.bank, f.bankRoof - 5 * s, 3 * s, C(0xF4EEDA)); c.rect(f.bank, f.bankRoof - 7 * s, s, 2 * s, C(0x2A2420))
        c.rect(bl, f.bankRoof, bw, 7 * s, C(0xA8A090))
        cb4Text(c, "BANK", cx: f.bank, y: f.bankRoof + s, s: s, col: C(0x3A3428))
        for i in 0..<4 {
            let colX = bl + 8 * s + i * 16 * s
            c.rect(colX, f.bankRoof + 7 * s, 4 * s, g - f.bankRoof - 9 * s, C(0xDCD6C8)); c.rect(colX + 3 * s, f.bankRoof + 7 * s, s, g - f.bankRoof - 9 * s, C(0xA8A090))
        }
        c.rect(f.bank - 5 * s, g - 12 * s, 10 * s, 12 * s, C(0x3A2A1E)); c.rect(f.bank - 4 * s, g - 11 * s, 8 * s, 5 * s, C(0xF2D898, 0.5))
        for i in 0..<3 { c.rect(bl + 2 * s - i * s, g - (3 - i) * s, bw - 4 * s + 2 * i * s, s, C(0xEEF2FA)) }
        // The Christmas tree in the square, a star on top.
        let th = (tall ? 38 : 30) * s
        for k in 0..<(th / s) {
            let half = k * 2 / 5 * s + s
            c.rect(f.tree - half, g - th - 2 * s + k * s, half * 2 + s, s, k % 6 == 5 ? C(0xEEF2FA) : C(0x1E5A34))
        }
        c.rect(f.tree - s, g - 3 * s, 3 * s, 3 * s, C(0x5A3A22))
        c.rect(f.tree - s, g - th - 4 * s, 3 * s, 3 * s, C(0xFFE04A))
        // The snowy street, ploughed ruts and the kerb.
        c.ground(g, C(0xDCE4F0), edge: C(0xFFFFFF), speck: C(0xB8C4D8), seed: 61)
        c.rect(0, g + 4, c.w, 1, C(0xA8B4C8)); c.rect(0, g + 7, c.w, 1, C(0xA8B4C8))
    }

    /// The screen saver's hill behind Main Street: snow under the stars, pines, a church spire, and the Peltclawd
    /// house at the top, a gabled two-storey with lit windows and a wreath on the door.
    private static func kfHill(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = kfFrame(c, g)
        c.circle(c.w * 16 / 100, g / 7, 10 * s, C(0xF2F2E4))
        let amp = Double(18 * s), freq = 0.012, phase = 1.2
        c.dunes(base: f.hill, amp: amp, freq: freq, phase: phase, bottom: g, C(0xB8C4DC), shade: C(0xEEF2FA))
        for i in 0..<14 {   // pines on the hill
            let px = Int(noise(i + 960) * Double(c.w)), py = f.hill + 14 * s + Int(noise(i + 970) * 40) * s
            for k in 0..<(10 * s) { c.rect(px - k / 3, py + k, k * 2 / 3 + s, 1, C(0x1A3A2E)) }
            c.rect(px - s, py, s * 2, s, C(0xEEF2FA))
        }
        let sx = c.w * 22 / 100, sy = f.hill + 10 * s   // the church and its spire
        c.rect(sx, sy, 22 * s, 20 * s, C(0x8A8278)); c.rect(sx + 8 * s, sy - 18 * s, 6 * s, 18 * s, C(0x8A8278))
        for k in 0..<10 { c.rect(sx + 11 * s - k / 2 * s / 2 - s, sy - 28 * s + k * s, (k / 2 + 1) * s, s, C(0x5A5650)) }
        c.rect(sx + 9 * s, sy - 12 * s, 4 * s, 5 * s, C(0xF2C870, 0.8))
        // The Peltclawd house.
        // It stands on the hill: its floor at the lowest point of the snow under it, a little sunk in, so no sky
        // shows beneath it wherever the hill dips.
        let hx = f.house, hw = 44 * s
        let ground = (hx - hw / 2 - 3 * s...hx + hw / 2 + 3 * s).map { x -> Int in
            let a: Double = sin(Double(x) * freq + phase) * 0.6
            let b: Double = sin(Double(x) * freq * 2.3 + phase * 1.7) * 0.4
            return f.hill - Int((a + b) * amp)
        }
        let hy = (ground.max() ?? f.hill) + 2 * s
        c.rect(hx - hw / 2, hy - 26 * s, hw, 26 * s, C(0x6A7A8A))
        for k in 0..<12 { c.rect(hx - hw / 2 - 2 * s + k * 2 * s, hy - 26 * s - k * s, hw + 4 * s - k * 4 * s, s, C(0xEEF2FA)) }
        c.rect(hx + 10 * s, hy - 44 * s, 5 * s, 10 * s, C(0x6A3A2A)); c.rect(hx + 10 * s, hy - 45 * s, 5 * s, 2 * s, C(0xEEF2FA))
        for wx in [hx - 18 * s, hx - 7 * s, hx + 8 * s] {
            c.rect(wx, hy - 22 * s, 7 * s, 6 * s, C(0xF2C870, 0.9)); c.rect(wx, hy - 11 * s, 7 * s, 6 * s, C(0xF2C870, 0.9))
        }
        c.rect(hx - 2 * s, hy - 9 * s, 5 * s, 9 * s, C(0x3A2216)); c.circle(hx, hy - 6 * s, s, C(0x2A7A3A))
        c.rect(hx - hw / 2 - 3 * s, hy, hw + 6 * s, 2 * s, C(0xEEF2FA))
    }

    /// What moves in Kingston Falls: snow falling, and the coloured bulbs along every eave and round the tree
    /// blinking in turns.
    static func kingstonFallsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = kfFrame(c, g)
        for i in 0..<(c.w * g / 220) {
            let speed = 10 + noise(i * 5 + 3) * 10
            let y = (noise(i * 5 + 1) * Double(g) + t * speed).truncatingRemainder(dividingBy: Double(g))
            let x = Int(noise(i * 5 + 2) * Double(c.w) + sin(t + Double(i)) * 3)
            c.rect(x, Int(y), s, s, C(0xFFFFFF, 0.5 + noise(i * 5 + 4) * 0.4))
        }
        let cols = [C(0xFF3A3A), C(0x3AE85A), C(0xFFD23A), C(0x3A8AFF)]
        let phase = Int(t * 2)
        // The eaves: the same bulbs the still picture laid out.
        var x = -4 * s
        var k = 0
        while x < c.w {
            let w = (34 + Int(noise(k * 3 + 37) * 16)) * s
            let h = (g - f.shopTop) - Int(noise(k * 3 + 38) * 6) * s
            let mid = x + w / 2
            if abs(mid - f.bank) > 36 * s + w / 2 && abs(mid - f.tree) > 12 * s + w / 2 {
                var i = 0
                for bx in stride(from: x, to: x + w, by: 3 * s) {
                    if (i + phase) % 2 == 0 { c.rect(bx, g - h + s, s, s, cols[(i + k) % 4]) }
                    i += 1
                }
            }
            x += w + 2 * s; k += 1
        }
        // The tree's lights.
        let th = (isTall(c) ? 38 : 30) * s
        for i in 0..<12 where (i + phase) % 3 != 0 {
            let row = Int(noise(i + 990) * Double(th / s - 4)) + 3
            let half = row * 2 / 5 * s
            let bx = f.tree - half + Int(noise(i + 995) * Double(half * 2 + s))
            c.rect(bx, g - th - 2 * s + row * s, s, s, cols[i % 4])
        }
    }
}

// MARK: - Mr. Wing's shop

extension Scenes {
    /// Where things are in the shop: the counter's left, right and top, the shelves' bottom, where the lanterns hang
    /// from, and the covered cage on the counter.
    private static func wingFrame(_ c: PixelCanvas, _ g: Int) -> (counter: (l: Int, r: Int, top: Int), shelf: Int,
                                                                  hang: Int, cage: Int, burner: Int) {
        let s = unit(g), tall = isTall(c)
        let counter = (c.w * 52 / 100, c.w * 52 / 100 + 90 * s, g - 14 * s)
        return (counter, g - (tall ? 46 : 40) * s, tall ? g - 200 * s : 0, counter.0 + 66 * s, counter.0 + 16 * s)
    }

    /// Mr. Wing's curio shop in Chinatown: dark red walls in the low light, wooden shelves packed with vases, jars,
    /// a jade figure and a brass gong, a carved doorway hung with a bead curtain, and the long counter with an
    /// incense burner on it. On the screen saver the shelves go all the way up to the beamed ceiling. The lanterns,
    /// the smoke and Gizmoe's covered cage are in the moving layer.
    static func wingShop(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = wingFrame(c, g)
        c.gradient(0, g, C(0x2A0E0C), C(0x5A1E16), bands: 6)
        if tall {
            for x in stride(from: 0, to: c.w, by: 60 * s) { c.rect(x, 0, 6 * s, 14 * s, C(0x2A140C)) }
            c.rect(0, 12 * s, c.w, 4 * s, C(0x3A1E10))
        }
        // The shelves: a dark wood case down the left and right, the doorway between.
        let door = c.w * 40 / 100
        let top = tall ? 18 * s : 0
        let step = 14 * s
        for side in 0..<2 {
            let x0 = side == 0 ? 6 * s : c.w * 50 / 100, x1 = side == 0 ? door - 14 * s : c.w - 6 * s
            c.rect(x0 - 2 * s, top, x1 - x0 + 4 * s, f.shelf - top + 2 * s, C(0x2A120A))
            var row = 0
            for y in stride(from: f.shelf, to: top + 4 * s, by: -step) {
                c.rect(x0 - 2 * s, y, x1 - x0 + 4 * s, 2 * s, C(0x6A3A1E))
                var x = x0
                var k = row * 13 + side * 101
                while x < x1 - 6 * s {
                    let w = wingCurio(c, x: x, base: y, kind: k, s: s, maxH: step - 3 * s)
                    x += w + (2 + Int(noise(k + 77) * 3)) * s; k += 1
                }
                row += 1
            }
            c.rect(x0 - 2 * s, top, 2 * s, f.shelf - top + 2 * s, C(0x6A3A1E)); c.rect(x1, top, 2 * s, f.shelf - top + 2 * s, C(0x6A3A1E))
        }
        // The doorway to the back: carved red frame, the bead curtain.
        let dw = 24 * s, dTop = g - 40 * s
        if tall {   // a long scroll over the doorway, a gold dragon winding down it
            let sx = door - 4 * s, sTop = top + 16 * s, sBottom = dTop - 30 * s
            c.rect(sx - 2 * s, sTop - 2 * s, dw + 12 * s, 3 * s, C(0x5A3A1E))
            c.rect(sx, sTop, dw + 8 * s, sBottom - sTop, C(0xA8241C)); c.rect(sx + 2 * s, sTop + 2 * s, dw + 4 * s, sBottom - sTop - 4 * s, C(0xC8382A))
            c.rect(sx - 2 * s, sBottom, dw + 12 * s, 3 * s, C(0x5A3A1E))
            let mid = sx + (dw + 8 * s) / 2
            for y in stride(from: sTop + 10 * s, to: sBottom - 10 * s, by: s) {
                let wave = Int(sin(Double(y - sTop) / Double(9 * s)) * 6) * s
                c.rect(mid + wave - s, y, 3 * s, s, C(0xE8B84A))
            }
            c.rect(mid - 4 * s, sTop + 5 * s, 8 * s, 5 * s, C(0xE8B84A)); c.rect(mid - 2 * s, sTop + 7 * s, s, s, C(0x5A1E14))
        }
        c.rect(door - 2 * s, dTop - 4 * s, dw + 4 * s, g - dTop + 4 * s, C(0xA8241C))
        c.rect(door, dTop, dw, g - dTop, C(0x140806))
        c.rect(door - 4 * s, dTop - 6 * s, dw + 8 * s, 3 * s, C(0xD8A83A))
        for bx in stride(from: door + s, to: door + dw, by: 3 * s) {
            for by in stride(from: dTop, to: g - 4 * s, by: 2 * s) {
                c.rect(bx, by, s, s, (by / s + bx / s) % 3 == 0 ? C(0xD8A83A) : C(0xA8241C, 0.8))
            }
        }
        // The counter: dark lacquered wood with a gold edge, and the incense burner on it.
        let ct = f.counter
        c.rect(ct.l, ct.top, ct.r - ct.l, g - ct.top, C(0x3A160C))
        c.rect(ct.l, ct.top, ct.r - ct.l, 2 * s, C(0xD8A83A))
        for px in stride(from: ct.l + 6 * s, to: ct.r - 6 * s, by: 20 * s) {
            c.rect(px, ct.top + 5 * s, 12 * s, 6 * s, C(0x5A2414)); c.rect(px + 5 * s, ct.top + 7 * s, 2 * s, 2 * s, C(0xD8A83A))
        }
        c.rect(f.burner - 3 * s, ct.top - 3 * s, 7 * s, 3 * s, C(0xB8862A)); c.rect(f.burner - 2 * s, ct.top - 4 * s, 5 * s, s, C(0x8A6420))
        c.rect(f.burner, ct.top - 8 * s, s, 4 * s, C(0x6A4A2A))
        // The floor: old boards.
        c.ground(g, C(0x3A2014), edge: C(0x5A3420), speck: C(0x2A160E), seed: 71)
        for y in stride(from: g + 3, to: c.h, by: 3) { c.rect(0, y, c.w, 1, C(0x2A160E, 0.7)) }
    }

    /// One curio standing on a shelf at `base`: a vase, a lidded jar, a jade figure, a gong, a stack of boxes or a
    /// bottle, chosen by `kind`. Returns its width.
    private static func wingCurio(_ c: PixelCanvas, x: Int, base: Int, kind: Int, s: Int, maxH: Int) -> Int {
        let pick = Int(noise(kind * 7 + 3) * 6)
        let tints = [C(0x2A5AA8), C(0x2A8A6A), C(0xD8A83A), C(0xC8C0A8), C(0xA8241C)]
        let col = tints[Int(noise(kind * 7 + 4) * 5)]
        switch pick {
        case 0:   // a ginger jar
            c.rect(x, base - 7 * s, 6 * s, 7 * s, col); c.rect(x + s, base - 9 * s, 4 * s, 2 * s, col)
            c.rect(x + s, base - 5 * s, 4 * s, s, C(0xF4EEDA, 0.7))
            return 6 * s
        case 1:   // a tall vase
            let h = min(maxH, 11 * s)
            c.rect(x + s, base - h, 3 * s, h, col); c.rect(x, base - h / 2, 5 * s, h / 2, col)
            c.rect(x + s, base - h, 3 * s, s, C(0xF4EEDA, 0.6))
            return 5 * s
        case 2:   // a jade figure, sitting
            c.rect(x, base - 4 * s, 6 * s, 4 * s, C(0x3AA87A)); c.rect(x + s, base - 7 * s, 4 * s, 3 * s, C(0x3AA87A))
            c.rect(x + 2 * s, base - 6 * s, s, s, C(0x1E5A3A))
            return 6 * s
        case 3:   // a brass gong on its stand
            c.rect(x, base - 10 * s, s, 10 * s, C(0x5A3A1E)); c.rect(x + 8 * s, base - 10 * s, s, 10 * s, C(0x5A3A1E))
            c.rect(x, base - 10 * s, 9 * s, s, C(0x5A3A1E)); c.circle(x + 4 * s, base - 5 * s, 3 * s, C(0xD8A83A))
            c.rect(x + 4 * s, base - 5 * s, s, s, C(0x8A6420))
            return 9 * s
        case 4:   // stacked boxes
            c.rect(x, base - 4 * s, 8 * s, 4 * s, C(0x8A2418)); c.rect(x + s, base - 7 * s, 6 * s, 3 * s, C(0x2A2A3A))
            c.rect(x + 3 * s, base - 4 * s, 2 * s, 4 * s, C(0xD8A83A))
            return 8 * s
        default:  // a bottle
            c.rect(x, base - 6 * s, 3 * s, 6 * s, col.alpha(0.8)); c.rect(x + s, base - 8 * s, s, 2 * s, col)
            return 3 * s
        }
    }

    /// What moves in Mr. Wing's shop: paper lanterns swaying on their cords, incense smoke curling up from the
    /// burner, and the cloth-covered cage on the counter that every few seconds rattles and hums (Gizmoe).
    static func wingShopLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = wingFrame(c, g)
        // Lanterns.
        let len = (isTall(c) ? 40 : 6) * s
        for (i, lx) in [c.w * 12 / 100, c.w * 30 / 100, c.w * 64 / 100, c.w * 86 / 100].enumerated() {
            let sway = sin(t * 1.4 + Double(i) * 1.7) * 0.18
            let bx = lx + Int(sin(sway) * Double(len)), by = f.hang + Int(cos(sway) * Double(len))
            for k in 0..<(len / s) { c.rect(lx + (bx - lx) * k * s / len, f.hang + (by - f.hang) * k * s / len, s, s, C(0x1A0A06)) }
            c.ellipse(bx, by + 6 * s, 6 * s, 5 * s, C(0xD82A1E)); c.rect(bx - 6 * s, by + 4 * s, 12 * s, s, C(0xA81A14))
            c.rect(bx - 6 * s, by + 8 * s, 12 * s, s, C(0xA81A14))
            c.rect(bx - 3 * s, by, 7 * s, s, C(0xD8A83A)); c.rect(bx - 3 * s, by + 11 * s, 7 * s, s, C(0xD8A83A))
            c.rect(bx, by + 12 * s, s, 3 * s, C(0xD8A83A))
            c.ellipse(bx, by + 6 * s, 12 * s, 9 * s, C(0xFF8A3A, 0.06))
        }
        // Incense smoke.
        cb4Wisp(c, x: f.burner, y: f.counter.top - 9 * s, n: 7, s: s, t: t, col: C(0xD8CCC0, 0.7))
        cb4Wisp(c, x: f.burner + s, y: f.counter.top - 9 * s, n: 5, s: s, t: t + 0.37, col: C(0xD8CCC0, 0.45))
        // The covered cage: a domed shape under a cloth, a ring on top, shaking now and then.
        let rattle = t.truncatingRemainder(dividingBy: 5) < 0.8
        let dx = rattle ? (Int(t * 30) % 2 == 0 ? -s : s) : 0
        let cx = f.cage + dx, base = f.counter.top
        c.rect(cx - 9 * s, base - 12 * s, 18 * s, 12 * s, C(0xC8B48A))
        c.ellipse(cx, base - 12 * s, 9 * s, 4 * s, C(0xC8B48A))
        c.rect(cx - 9 * s, base - 2 * s, 18 * s, 2 * s, C(0x8A7656))
        for fx in stride(from: cx - 7 * s, to: cx + 9 * s, by: 4 * s) { c.rect(fx, base - 11 * s, s, 9 * s, C(0xA8946C)) }
        c.rect(cx - s, base - 19 * s, 3 * s, 3 * s, C(0xB8862A)); c.rect(cx, base - 18 * s, s, s, C(0x3A160C))
        if rattle {   // a hum: little notes above
            let k = Int(t * 4) % 2
            c.rect(cx + 10 * s, base - 18 * s - k * s, s, 3 * s, C(0xF4EEDA)); c.rect(cx + 9 * s, base - 16 * s - k * s, s, s, C(0xF4EEDA))
        }
    }
}

// MARK: - The Clamp Centre

extension Scenes {
    /// Where things are in the gene lab: the row of vats along the back, the monitors' wall, the bench, the
    /// sparking cable, and (on the screen saver) Grandpa Dread's set.
    private static func clampFrame(_ c: PixelCanvas, _ g: Int) -> (vats: [Int], vatTop: Int, monitors: (x: Int, y: Int),
                                                                   cable: (x: Int, y: Int), set: Int) {
        let s = unit(g), tall = isTall(c)
        let vats = [c.w * 8 / 100, c.w * 20 / 100, c.w * 74 / 100, c.w * 88 / 100]
        let vatTop = g - (tall ? 150 : 44) * s
        return (vats, vatTop, (c.w * 34 / 100, g - (tall ? 62 : 52) * s), (c.w * (tall ? 70 : 64) / 100, g - (tall ? 60 : 50) * s),
                c.w * 46 / 100)
    }

    /// The gene lab high in the Clamp Centre: cold blue-grey walls in panels, the CLAMP logo, tall glass vats of
    /// glowing green along the back with pipes between, a wall of monitors over the bench, test tubes in a rack,
    /// a cut cable hanging from a ceiling panel. On the screen saver the tanks rise to the ceiling and Grandpa
    /// Dread's horror-show set sits off to the side: a painted crypt backdrop, a coffin, a candelabra and the TV
    /// camera on its stand.
    static func clampCentre(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = clampFrame(c, g)
        c.gradient(0, g, C(0x1A2A32), C(0x3A5058), bands: 5)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, 0, s, g, C(0x2A3C44)) }   // wall panels
        c.rect(0, g - 18 * s, c.w, s, C(0x4A6A72))
        if tall {
            for y in stride(from: 12 * s, to: g - 30 * s, by: 34 * s) { c.rect(0, y, c.w, s, C(0x2A3C44)) }
            c.rect(0, 0, c.w, 10 * s, C(0x101C22))
            for x in stride(from: 20 * s, to: c.w, by: 70 * s) { c.rect(x, 8 * s, 30 * s, 2 * s, C(0xD8F4F8, 0.8)) }
            clampSet(c, g)
        }
        // The CLAMP logo on the wall.
        let logoY = tall ? g - 140 * s : 3 * s
        c.rect(c.w * 46 / 100 - 16 * s, logoY, 32 * s, 9 * s, C(0x101C22))
        cb4Text(c, "CLAMP", cx: c.w * 46 / 100, y: logoY + 2 * s, s: s, col: C(0x8AF2E8))
        // The vats: a steel cap and base, glass walls, green inside, pipes between them.
        for (i, vx) in f.vats.enumerated() {
            let w = 20 * s, l = vx - w / 2
            if i % 2 == 0 { c.rect(vx + w / 2, f.vatTop + 6 * s, f.vats[i + 1] - vx - w, 2 * s, C(0x6A7A80)) }
            c.rect(l, f.vatTop + 4 * s, w, g - f.vatTop - 10 * s, C(0x3AD86A, 0.55))
            c.rect(l, f.vatTop + 4 * s, 2 * s, g - f.vatTop - 10 * s, C(0xC8FFE0, 0.5))
            c.rect(l + w - 3 * s, f.vatTop + 4 * s, s, g - f.vatTop - 10 * s, C(0x1A6A3A, 0.6))
            c.rect(l - 2 * s, f.vatTop, w + 4 * s, 5 * s, C(0x8A9AA0)); c.rect(l - 2 * s, f.vatTop, w + 4 * s, s, C(0xC8D4D8))
            c.rect(l - 2 * s, g - 7 * s, w + 4 * s, 7 * s, C(0x6A7A80)); c.rect(l, g - 5 * s, w, s, C(0x3AFF8A))
            c.rect(vx - s, 0, 2 * s, f.vatTop, C(0x4A5A60))
            // Something floating in it: a dark curled shape.
            let fy = f.vatTop + (g - f.vatTop) / 2 - 6 * s
            c.ellipse(vx, fy, 4 * s, 3 * s, C(0x1A4A2A, 0.8)); c.rect(vx + 2 * s, fy + 2 * s, 3 * s, 3 * s, C(0x1A4A2A, 0.8))
        }
        // The monitors' wall: a grid of dark screens on a steel frame.
        let m = f.monitors
        c.rect(m.x - 2 * s, m.y - 2 * s, 64 * s, 24 * s, C(0x5A6A70))
        for r in 0..<2 {
            for k in 0..<5 {
                let x = m.x + k * 12 * s, y = m.y + r * 10 * s
                c.rect(x, y, 10 * s, 8 * s, C(0x0E1A1A)); c.rect(x + s, y + s, 8 * s, 6 * s, C(0x1E4A44))
            }
        }
        // The bench under it, with a rack of test tubes and a microscope.
        let bx = m.x - 6 * s
        c.rect(bx, g - 18 * s, 80 * s, 3 * s, C(0xC8D4D8)); c.rect(bx + 2 * s, g - 15 * s, 3 * s, 15 * s, C(0x6A7A80))
        c.rect(bx + 75 * s, g - 15 * s, 3 * s, 15 * s, C(0x6A7A80))
        for k in 0..<6 {
            let tube = [C(0x3AFF8A), C(0xFF4AA8), C(0x4AC8FF)][k % 3]
            c.rect(bx + (8 + k * 3) * s, g - 24 * s, 2 * s, 6 * s, C(0xE8F4F4, 0.6)); c.rect(bx + (8 + k * 3) * s, g - 21 * s, 2 * s, 3 * s, tube)
        }
        c.rect(bx + 6 * s, g - 20 * s, 20 * s, 2 * s, C(0x8A9AA0))
        c.rect(bx + 56 * s, g - 20 * s, 8 * s, 2 * s, C(0x2A2A30)); c.rect(bx + 59 * s, g - 28 * s, 3 * s, 8 * s, C(0x2A2A30))
        c.rect(bx + 57 * s, g - 30 * s, 4 * s, 3 * s, C(0x2A2A30))
        // The cut cable hanging from a lifted ceiling panel.
        let cb = f.cable
        c.rect(cb.x - 6 * s, 0, 12 * s, s, C(0x6A7A80))
        for y in stride(from: 0, to: cb.y, by: s) { c.rect(cb.x + Int(sin(Double(y) / Double(6 * s)) * 2) * s, y, s, s, C(0x16161B)) }
        // The floor: white tiles, scuffed.
        c.ground(g, C(0xB8C4C8), edge: C(0xE8F0F2), speck: C(0x98A4A8), seed: 81)
        for x in stride(from: 0, to: c.w, by: 12) { c.rect(x, g + 1, 1, c.h - g - 1, C(0x98A4A8)) }
    }

    /// Grandpa Dread's set on the screen saver: a crypt backdrop with a painted arch, a coffin stood on end, a
    /// candelabra and the studio camera on its tripod, under a studio light.
    private static func clampSet(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = clampFrame(c, g)
        let x = f.set - 50 * s, top = g - 250 * s, w = 100 * s, h = 80 * s
        c.rect(x, top, w, h, C(0x2A1E34))
        for k in 0..<8 { c.rect(x + k * 13 * s, top + h - 8 * s - (k % 3) * 4 * s, 12 * s, 8 * s + (k % 3) * 4 * s, C(0x3A2E44)) }
        c.ellipse(x + w / 2, top + 30 * s, 20 * s, 22 * s, C(0x140E1C)); c.rect(x + w / 2 - 20 * s, top + 30 * s, 40 * s, h - 30 * s, C(0x140E1C))
        // Cobwebs in the corners.
        for k in 0..<10 { c.rect(x + k * s, top + (10 - k) * s, s, s, C(0xC8C8D8, 0.6)); c.rect(x + w - (k + 1) * s, top + (10 - k) * s, s, s, C(0xC8C8D8, 0.6)) }
        // The coffin, on end, lid ajar.
        let cx = x + w / 2 - 8 * s
        c.rect(cx, top + 26 * s, 16 * s, h - 26 * s, C(0x4A2A1A)); c.rect(cx + 2 * s, top + 28 * s, 12 * s, h - 30 * s, C(0x6A0E1A))
        c.rect(cx + 7 * s, top + 34 * s, 2 * s, 10 * s, C(0xD8C8A8)); c.rect(cx + 4 * s, top + 37 * s, 8 * s, 2 * s, C(0xD8C8A8))
        // The candelabra.
        let lx = x + 18 * s
        c.rect(lx, top + h - 26 * s, 2 * s, 26 * s, C(0xB8862A)); c.rect(lx - 6 * s, top + h - 26 * s, 14 * s, 2 * s, C(0xB8862A))
        for k in 0..<3 { c.rect(lx - 6 * s + k * 6 * s, top + h - 31 * s, 2 * s, 5 * s, C(0xF4EEDA)); c.rect(lx - 6 * s + k * 6 * s, top + h - 33 * s, 2 * s, 2 * s, C(0xFFC84A)) }
        // The studio floor: a balcony slab off the wall, on brackets, with a rail.
        let slabR = x + w + 44 * s
        c.rect(x - 8 * s, top + h, slabR - x + 8 * s, 4 * s, C(0x5A6A70)); c.rect(x - 8 * s, top + h, slabR - x + 8 * s, s, C(0x8A9AA0))
        for bx in [x, x + w / 2, slabR - 8 * s] {
            for k in 0..<(8 * s) { c.rect(bx + k, top + h + 4 * s + k, s, s, C(0x4A5A60)) }
        }
        cb4Text(c, "GRANDPA DREAD", cx: x + w / 2, y: top - 10 * s, s: s, col: C(0xB88AF2))
        // The camera on its tripod, pointing at the set, and a studio light above.
        let camX = x + w + 26 * s, camY = top + h - 30 * s
        c.rect(camX - 8 * s, camY, 18 * s, 12 * s, C(0x2A2A30)); c.rect(camX - 14 * s, camY + 3 * s, 6 * s, 6 * s, C(0x16161B))
        c.circle(camX - 3 * s, camY - 4 * s, 4 * s, C(0x2A2A30)); c.circle(camX + 5 * s, camY - 4 * s, 4 * s, C(0x2A2A30))
        for k in 0..<(top + h - camY - 12 * s) / s {
            c.rect(camX - k / 3 * s / 2, camY + 12 * s + k * s, s, s, C(0x5A5A60)); c.rect(camX + 2 * s + k / 3 * s / 2, camY + 12 * s + k * s, s, s, C(0x5A5A60))
        }
        c.rect(x + w / 2 - 6 * s, top - 22 * s, 12 * s, 6 * s, C(0x3A3A40)); c.rect(x + w / 2 - 5 * s, top - 16 * s, 10 * s, s, C(0xFFF2C8))
    }

    /// What moves in the gene lab: bubbles rising in the vats, the monitors flickering between readouts (a helix,
    /// a pulse line, static), sparks spitting from the cut cable, and on the screen saver the studio light's
    /// beam on Grandpa Dread's set.
    static func clampCentreLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = clampFrame(c, g)
        // Bubbles.
        for (i, vx) in f.vats.enumerated() {
            let span = Double(g - f.vatTop - 14 * s)
            for k in 0..<5 {
                let age = (t * 0.4 + noise(i * 9 + k) ).truncatingRemainder(dividingBy: 1)
                let bx = vx - 6 * s + Int(noise(i * 9 + k + 50) * 12) * s + Int(sin(t * 3 + Double(k)) * 1.2) * s
                let by = g - 8 * s - Int(age * span)
                c.rect(bx, by, s + (k % 2) * s, s + (k % 2) * s, C(0xD8FFE8, 0.8))
            }
        }
        // Monitors.
        let m = f.monitors
        for r in 0..<2 {
            for k in 0..<5 {
                let x = m.x + k * 12 * s + s, y = m.y + r * 10 * s + s
                let slot = Int(noise(r * 5 + k + Int(t * 1.5) * 13) * 4)
                switch slot {
                case 0:   // a helix
                    for j in 0..<8 {
                        let a = Double(j) * 0.8 + t * 3
                        c.rect(x + j * s, y + 3 * s + Int(sin(a) * 2) * s, s, s, C(0x6AFFC8))
                        c.rect(x + j * s, y + 3 * s - Int(sin(a) * 2) * s, s, s, C(0xFF6AC8))
                    }
                case 1:   // a pulse line
                    for j in 0..<8 { c.rect(x + j * s, y + 3 * s - (j == (Int(t * 8) % 8) ? 2 * s : 0), s, s, C(0x6AFF8A)) }
                case 2:   // static
                    for j in 0..<12 { c.rect(x + Int(noise(j + Int(t * 20)) * 8) * s, y + Int(noise(j * 3 + Int(t * 20)) * 6) * s, s, s, C(0xE8F4F4, 0.8)) }
                default:  // text scrolling
                    for j in 0..<3 { c.rect(x + s, y + (j * 2) * s, (2 + Int(noise(j + Int(t * 2)) * 5)) * s, s, C(0x8AF2E8, 0.8)) }
                }
            }
        }
        // Sparks from the cable.
        let cb = f.cable
        if noise(Int(t * 6)) > 0.45 {
            for k in 0..<6 {
                let a = noise(k + Int(t * 12) * 7) * .pi
                let r = Double((2 + Int(noise(k * 3 + Int(t * 12)) * 6)) * s)
                c.rect(cb.x + Int(cos(a) * r), cb.y + Int(sin(a) * r), s, s, k % 2 == 0 ? C(0xFFF6A8) : C(0x8AE8FF))
            }
            c.circle(cb.x, cb.y, 3 * s, C(0xC8F0FF, 0.3))
        }
        // The studio light's beam on the set.
        if isTall(c) {
            let x = f.set, top = g - 272 * s
            let flick = noise(Int(t * 5)) > 0.9 ? 0.03 : 0.08
            for y in 0..<(100 * s) {
                let half = 5 * s + y * 2 / 5
                c.rect(x - half, top + 6 * s + y, half * 2, 1, C(0xFFF2C8, flick))
            }
        }
    }
}
