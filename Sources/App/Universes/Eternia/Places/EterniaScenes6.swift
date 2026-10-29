import Foundation

// More places on Eternia: Mer-Clawd's undersea kingdom, Beast Island and the House of Shokoti, drawn the same way as
// EterniaScenes1.swift. Each landmark (the sunken arch and its drowned palace, the volcano, the witch's spire)
// is drawn once at one pixel to a unit and blown up `q` times, so it's the whole picture on the screen saver and still
// fits the window's strip; the things round it (kelp and coral, twisted trees, jagged rocks) stand out to the sides.
// Three palettes far apart: the sea's blues with coral pinks and violets, the island's fog greens and lava, and the
// Sands of Time at night, pale blue stone and blue sand under a dark red sky.

let eterniaScenes6: [Location: Place] = [
    .eterniaUndersea: Place(name: "Mer-Clawd's Undersea Kingdom", panel: 0x0A1A28, still: Scenes.eterniaUndersea,
                            moving: Scenes.eterniaUnderseaLife),
    .eterniaBeastIsland: Place(name: "Beast Island", panel: 0x121612, still: Scenes.eterniaBeastIsland,
                               moving: Scenes.eterniaBeastIslandLife),
    .eterniaTemple: Place(name: "The House of Shokoti", panel: 0x1C1420, still: Scenes.eterniaTemple,
                          moving: Scenes.eterniaTempleLife),
]

// MARK: - Shared

extension Scenes {
    /// How many times a landmark drawn 120 units wide is blown up: once in the window, three times or more on the
    /// screen saver (the same rule as Greyskull's).
    private static func eterniaPlaces6Q(_ c: PixelCanvas, _ g: Int) -> Int {
        eterniaTall(c, max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120))))
    }

    /// Copies `art` onto `c` with its top left at (`x`, `y`), each of its pixels a `q`×`q` block, mirrored when `flip`.
    private static func eterniaPlaces6Blit(_ c: PixelCanvas, _ art: PixelCanvas, _ x: Int, _ y: Int, _ q: Int, flip: Bool = false) {
        for yy in 0..<art.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
            for xx in 0..<art.w where art.buf[(yy * art.w + xx) * 4 + 3] > 0 {
                let dx = flip ? art.w - 1 - xx : xx
                c.rect(x + dx * q, y + yy * q, q, q, unpremultiplied(art, (yy * art.w + xx) * 4))
            }
        }
    }

    /// A tone out of `tones` (darkest first) for a brightness `v` of 0...1, dithered by position so the tones blend.
    private static func eterniaPlaces6Tone(_ tones: [Px], _ v: Double, _ x: Int, _ y: Int, grain: Double = 0.26) -> Px {
        let n = (noise(x * 7 + y * 131) - 0.5) * grain
        return tones[max(0, min(tones.count - 1, Int((v + n) * Double(tones.count))))]
    }

    /// String art painted with each character a `b`×`b` block (fish, beasts in the sky).
    private static func eterniaPlaces6Pattern(_ c: PixelCanvas, _ x: Int, _ y: Int, _ b: Int, _ rows: [String],
                                              _ pal: [Character: Px]) {
        for (r, row) in rows.enumerated() {
            for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * b, y + r * b, b, b, col) } }
        }
    }

    /// A soft round glow: `col` at `peak` opacity in the middle, fading smoothly out to nothing at `r`, each pixel
    /// worked out on its own and dithered a little, so it never steps in rings.
    private static func eterniaPlaces6Glow(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, _ col: Px, peak: Double) {
        guard r > 0 else { return }
        for y in max(0, cy - r)..<min(c.h, cy + r + 1) {
            for x in max(0, cx - r)..<min(c.w, cx + r + 1) {
                let dx = Double(x - cx), dy = Double(y - cy), k = (dx * dx + dy * dy).squareRoot() / Double(r)
                guard k < 1 else { continue }
                let a = peak * pow(1 - k, 1.8) + (noise(x * 13 + y * 7919) - 0.5) * 0.01
                if a > 0.003 { c.px(x, y, col.alpha(a)) }
            }
        }
    }

    /// Where the things beside a landmark stand: `frac` (0...1) of the way across the room left of it (`left`) or
    /// right of it, so they frame it in the window and close in on it on the screen saver.
    private static func eterniaPlaces6Side(_ c: PixelCanvas, _ x: Int, _ q: Int, _ frac: Double, left: Bool) -> Int {
        left ? Int(Double(x) * frac) : x + 120 * q + Int(Double(c.w - x - 120 * q) * frac)
    }
}

// MARK: - Mer-Clawd's undersea kingdom

extension Scenes {
    /// Where things stand in the undersea kingdom: the sunken arch and the drowned palace behind it are drawn at one
    /// pixel to a unit on a canvas of their own (`eterniaUnderseaArt`, 120×56) and blown up `q` times, its foot on the
    /// sea floor `floor`, its canvas's top left at `x`/`y`.
    static func eterniaUnderseaFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, floor: Int, x: Int, y: Int) {
        let q = eterniaPlaces6Q(c, g)
        let floor = g - (isTall(c) ? 8 : 5) * q
        return (q, floor, c.w / 2 - 60 * q, floor - 56 * q)
    }

    /// Mer-Clawd's undersea kingdom: deep water, teal up where the light comes down and navy at the bottom, pale
    /// shafts of light slanting through it. A drowned palace in the blue haze, its dome and two shell-capped spires
    /// lit aqua at the windows, its gate glowing; in front of it a great sunken arch of sea-worn green stone on two
    /// fluted columns, a bronze trident on its keystone, a bite broken out of one shoulder, weed hanging from it and
    /// barnacles on it. A reef of pink, mauve and violet coral grows at its left foot and a giant clam sits open on
    /// a pearl at its right. Kelp stands up out of the sand either side, and the crew stands on blue-grey sand. On
    /// the screen saver the arch stands three times the size, the drowned city fills the haze behind and the surface
    /// shines far above, rippling, the sun a blur through it.
    static func eterniaUndersea(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaUnderseaFrame(c, g), q = f.q, tall = isTall(c)
        c.gradient(0, f.floor, C(tall ? 0x4CB4C8 : 0x22708C), C(0x0A2240), bands: tall ? 14 : 7)
        if tall {
            // The surface far above: a rippling bright skin, the sun a soft blur through it.
            let sun = (x: c.w * 30 / 100, y: 0)
            for (k, a) in [(60, 0.10), (40, 0.14), (24, 0.20)] { c.circle(sun.x, sun.y, k * s, C(0xE8FFF4, a)) }
            for x in 0..<c.w {
                let d = 3 * s + Int((sin(Double(x) * 0.07 / Double(s)) * 0.6 + sin(Double(x) * 0.023 / Double(s) + 1.3) * 0.4) * Double(2 * s))
                c.rect(x, 0, 1, d, C(0x9AE2EA)); c.rect(x, d, 1, max(1, s / 2), C(0xD8FAF8))
                if x / (5 * s) % 3 == 0 { c.rect(x, d + s, 1, max(1, s / 2), C(0xB8F0F0, 0.6)) }
            }
            // The drowned city far off in the haze: towers and domes in silhouette, a window lit here and there.
            let city = f.floor - 70 * s
            for k in 0..<(c.w / (16 * s) + 1) {
                let x = k * 16 * s + Int(noise(k + 500) * Double(6 * s)), w = (6 + Int(noise(k + 510) * 6)) * s
                let h = (16 + Int(noise(k + 520) * 30)) * s, top = city - h
                c.rect(x, top, w, f.floor - top, C(0x1E5C78))
                if noise(k + 530) > 0.5 { c.ellipse(x + w / 2, top, w / 2, w / 3, C(0x1E5C78)) }
                else { for i in 0..<(w / s / 2) { c.rect(x + w / 2 - i * s, top - (w / s / 2 - i) * s, 2 * i * s + s, s, C(0x1E5C78)) } }
                if noise(k + 540) > 0.45 { c.rect(x + w / 3, top + h / 3, s, 2 * s, C(0x5ACCD0, 0.6)) }
            }
            c.rect(0, city, c.w, f.floor - city, C(0x1E5C78))
        }
        // Shafts of light slanting down from the surface, fading as they go.
        for k in 0..<(c.w / (70 * s) + 1) {
            let x0 = k * 70 * s + Int(noise(k + 560) * Double(30 * s)), w0 = (6 + Int(noise(k + 570) * 8)) * s
            for y in 0..<f.floor {
                let a = 0.10 * (1 - Double(y) / Double(f.floor))
                c.rect(x0 + y / 3, y, w0 + y / 10, 1, C(0xD0FAF0, a))
            }
        }
        // The far ridges of the sea bed, in the haze.
        c.dunes(base: f.floor - (tall ? 22 : 8) * s, amp: Double(4 * s), freq: 0.04 / Double(s), phase: 0.9, bottom: f.floor,
                C(0x174A64), shade: C(0x22607A))
        c.dunes(base: f.floor - (tall ? 8 : 3) * s, amp: Double(2 * s), freq: 0.07 / Double(s), phase: 2.6, bottom: f.floor,
                C(0x123A52), shade: C(0x1C4E66))

        // Kelp behind the arch, the far stalks darker, in clumps and alone at uneven gaps, each its own height.
        let farKelp: [(frac: Double, left: Bool, h: Int)] = [(0.07, true, 64), (0.13, true, 46), (0.46, true, 82),
                                                             (0.8, true, 56), (0.18, false, 74), (0.25, false, 50),
                                                             (0.6, false, 88), (0.93, false, 58)]
        for (i, k) in farKelp.enumerated() {
            eterniaKelp(c, eterniaPlaces6Side(c, f.x, q, k.frac, left: k.left), f.floor, f.floor * k.h / 100, q, seed: i, far: true)
        }

        // The arch and the palace, blown up to size.
        let art = PixelCanvas(120, 56)
        eterniaUnderseaArt(art)
        eterniaPlaces6Blit(c, art, f.x, f.y, q)

        // The sand: blue-grey and plain where the crew stands, ripples across it, shells and pebbles.
        c.gradient(f.floor, g, C(0x3A5866), C(0x2E4856), bands: 3)
        for k in 0..<(c.w / (12 * q) + 1) {
            let x = k * 12 * q + Int(noise(k + 620) * Double(6 * q)), y = f.floor + Int(noise(k + 621) * Double(max(1, g - f.floor - q)))
            c.rect(x, y, 5 * q, max(1, q / 2), C(0x4E6E7A))
        }
        // Coral and kelp in front at the sides, framing it: each reef a different mix, none at the same spot either side.
        let reefs: [(frac: Double, left: Bool, seed: Int)] = [(0.24, true, 0), (0.72, true, 1), (0.4, false, 2), (0.86, false, 3)]
        for r in reefs {
            let reef = PixelCanvas(40, 26)
            eterniaCoral(reef, seed: r.seed)
            let x = eterniaPlaces6Side(c, f.x, q, r.frac, left: r.left)
            eterniaPlaces6Blit(c, reef, x - 20 * q, f.floor + 2 * q - 26 * q, q, flip: r.seed % 2 == 1)
        }
        let nearKelp: [(frac: Double, left: Bool, h: Int)] = [(0.03, true, 92), (0.1, true, 68), (0.95, false, 80)]
        for (i, k) in nearKelp.enumerated() {
            eterniaKelp(c, eterniaPlaces6Side(c, f.x, q, k.frac, left: k.left), g, g * k.h / 100, q, seed: 9 + i * 2, far: false)
        }
        c.ground(g, C(0x2E4652), edge: C(0x4A6874), speck: C(0x243A46), seed: 37)
    }

    /// A stalk of kelp from (`x0`, `foot`) up `h` pixels, `q` thick, waving a little as it climbs: long olive blades
    /// off alternate sides, a gas bladder at the root of each. `far` ones are darker, in the haze.
    private static func eterniaKelp(_ c: PixelCanvas, _ x0: Int, _ foot: Int, _ h: Int, _ q: Int, seed: Int, far: Bool) {
        let stem = far ? C(0x2A4E3E) : C(0x3E6A2E), leaf = far ? C(0x34604A) : C(0x5A8C38)
        let leafL = far ? C(0x447460) : C(0x86B44E), bladder = far ? C(0x5A7A54) : C(0xB0B44A)
        var blade = 0
        for y in stride(from: foot, to: max(0, foot - h), by: -1) {
            let u = Double(foot - y) / Double(q)
            let x = x0 + Int(sin(u * 0.11 + Double(seed)) * Double(2 * q))
            c.rect(x, y, q, 1, stem)
            if (foot - y) % (6 * q) == 0 && foot - y > 3 * q {
                blade += 1
                let side = blade % 2 == 0 ? 1 : -1
                for i in 0..<5 {
                    let bx = x + side * (q + i * q), by = y - (i * q) / 2 - (i > 2 ? q / 2 : 0)
                    c.rect(side > 0 ? bx : bx - q + 1, by, q, max(1, q * 3 / 2), leaf)
                    if i == 2 { c.rect(side > 0 ? bx : bx - q + 1, by, q, max(1, q / 2), leafL) }
                }
                c.rect(x + (side > 0 ? q : -q), y, q, q, bladder)
            }
        }
        // The top: a last blade, curling over.
        let tx = x0 + Int(sin(Double(h / q) * 0.11 + Double(seed)) * Double(2 * q))
        c.rect(tx, foot - h - q, 2 * q, q, leaf); c.rect(tx + q, foot - h, 2 * q, q, leafL)
    }

    /// A reef, one pixel to a unit on a 40×26 canvas, its foot on row 25: a ledge of rock and on it four of a sea fan
    /// (F), a mound of brain coral (B), violet tubes (T), branches of pale staghorn (S) and a sea anemone (A). Which
    /// four, in what order, how big and in which shades are all set by `seed`, so no two reefs look alike. Pinks,
    /// mauves and violets, never orange, so a Clawd in front still stands out.
    private static func eterniaCoral(_ a: PixelCanvas, seed: Int) {
        // The rock it grows on, higher or lower.
        let ledge = 19 + seed % 3
        for x in 1..<39 {
            let top = ledge + Int(noise(seed * 40 + x) * 2.5) + (x < 4 || x > 35 ? 2 : 0)
            a.rect(x, top, 1, 26 - top, C(0x1E3644)); a.px(x, top, C(0x34525E))
        }
        let base = ledge + 1
        let layouts = ["SFBT", "TBFA", "BFSA", "FTAB", "ASTF", "SFBT"]
        let slots = [5, 13, 23, 32]
        let fans = [(C(0xC8408E), C(0xF07AC0)), (C(0x9A40C0), C(0xCA7AF0)), (C(0xD84C78), C(0xFF96B4))]
        let brains = [(C(0x8A4E8E), C(0xB27AB4), C(0x5E3066)), (C(0x6A5AA8), C(0x9A8AD0), C(0x443878)),
                      (C(0xA05070), C(0xCC8AA2), C(0x6A2E48))]
        for (i, kind) in layouts[seed % layouts.count].enumerated() {
            let x0 = slots[i] + Int(noise(seed * 7 + i) * 3) - 1, v = seed + i
            switch kind {
            case "F":
                // The sea fan: a lattice spreading up from its root.
                let (fan, fanL) = fans[v % fans.count], reach = 8 + (seed * 5 + i) % 7
                for d in stride(from: -60, through: 60, by: 12) {
                    let ang = Double(d) * .pi / 180
                    for r in 0..<reach { a.px(x0 + Int(sin(ang) * Double(r)), base - Int(cos(ang) * Double(r) * 0.95), d < 0 ? fanL : fan) }
                }
                for r in [5, 9, 13] where r < reach {
                    for d in -60...60 {
                        let ang = Double(d) * .pi / 180
                        a.px(x0 + Int(sin(ang) * Double(r)), base - Int(cos(ang) * Double(r) * 0.95), d < 0 ? fanL : fan)
                    }
                }
            case "B":
                // The brain coral: a mound, grooves winding over it, lit on top.
                let (col, lit, groove) = brains[v % brains.count], rx = 5 + v % 3, ry = 3 + v % 2 * 2
                let by = base - ry + 1
                a.ellipse(x0, by, rx, ry, col)
                a.ellipse(x0 - 2, by - ry / 2, rx / 2 + 1, max(1, ry / 2), lit)
                for x in (x0 - rx + 1)...(x0 + rx - 1) {
                    for row in [-1, 1] where ry > 3 || row == 1 {
                        a.px(x, by + row + Int(sin(Double(x) * 1.3 + Double(row + seed)) * 1.2), groove)
                    }
                }
                a.px(x0 - 3, by - ry + 1, C(0xDCC0E8))
            case "T":
                // The tubes: violet, lit down their left, open at the top.
                for k in 0..<(2 + v % 3) {
                    let x = x0 - 2 + k * 3, top = base - 8 - Int(noise(seed * 11 + k) * 8)
                    a.rect(x, top, 2, base + 1 - top, C(0x6448A8)); a.rect(x, top, 1, base + 1 - top, C(0x9478D4))
                    a.rect(x - (k % 2), top - 1, 3, 1, C(0xC4B0F0)); a.px(x, top, C(0x281C48))
                }
            case "S":
                // Staghorn: pale pink branches forking up.
                let stag = C(0xF0B4C4), stagD = C(0xB87890)
                for (dx, lean) in [(-1, 1), (1, -1), (3, 1)].prefix(2 + seed % 2) {
                    var x = x0 + dx
                    for y in stride(from: base, to: base - 10 - seed % 3, by: -1) {
                        if y % 3 == 0 { x += lean }
                        a.px(x, y, stag); a.px(x + 1, y, stagD)
                        if y == base - 5 { a.px(x - lean, y - 1, stag); a.px(x - 2 * lean, y - 2, stag) }
                    }
                }
            default:
                // A sea anemone: a squat column, a crown of tentacles splaying out, their tips bright.
                let col = C(0xC86AA8), colL = C(0xE8A0CC), tip = C(0xFFE0F4)
                a.rect(x0 - 2, base - 3, 5, 4, col); a.rect(x0 - 2, base - 3, 1, 4, colL)
                for k in -3...3 {
                    for r in 1...5 {
                        let x = x0 + k * r / 3 + (r > 3 ? k.signum() : 0), y = base - 3 - r + abs(k) / 2
                        a.px(x, y, r == 5 ? tip : r % 2 == 0 ? colL : col)
                    }
                }
            }
        }
    }

    /// The arch and the drowned palace behind it, one pixel to a unit on a 120×56 canvas, the plinth's foot on row
    /// 55: the palace's spires, walls and dome in the haze, its glowing gate, then the arch on its two columns, the
    /// reef at its left foot and the clam at its right.
    static func eterniaUnderseaArt(_ c: PixelCanvas) {
        let stone = [C(0x0E2630), C(0x163844), C(0x224C58), C(0x30646C), C(0x447E80), C(0x62A09A)]
        let haze = [C(0x123448), C(0x184256), C(0x205066), C(0x2A6278)]
        let lit = C(0x5ACCC8), weed = C(0x4E8A3A), weedL = C(0x7AB04E), barnacle = C(0xB8CCC0)

        // The palace's spires, each capped with a spiral shell, aqua windows up them.
        for x0 in [16, 96] {
            c.rect(x0, 14, 9, 42, haze[1]); c.rect(x0, 14, 2, 42, haze[2]); c.rect(x0 + 8, 14, 1, 42, haze[0])
            for i in 0..<12 {
                let hw = 5 - i * 5 / 12
                c.rect(x0 + 4 - hw, 13 - i, hw * 2 + 1, 1, i % 3 == 0 ? haze[0] : haze[3])
            }
            for y in [20, 30, 40] { c.rect(x0 + 4, y, 1, 3, lit); c.px(x0 + 4, y - 1, C(0x3A9AA0)) }
        }
        // The walls between, crenellated.
        for (x0, w) in [(25, 16), (79, 17)] {
            c.rect(x0, 32, w, 24, haze[0]); c.rect(x0, 32, w, 1, haze[2])
            for x in stride(from: x0, to: x0 + w, by: 3) { c.rect(x, 30, 2, 2, haze[0]) }
        }
        // The drum and the dome, ribbed, a spire of shell on top.
        c.rect(40, 26, 40, 30, haze[1]); c.rect(40, 26, 3, 30, haze[2]); c.rect(78, 26, 2, 30, haze[0])
        for y in 8..<27 {
            let k = Double(26 - y) / 18, half = Int((20 * (1 - k * k).squareRoot()).rounded())
            for x in (60 - half)...(60 + half) {
                let n = Double(x - 60) / Double(max(1, half))
                c.px(x, y, n < -0.45 ? haze[3] : n < 0.35 ? haze[2] : haze[1])
            }
        }
        for rib in [-12, -5, 5, 12] {
            for y in 10..<27 {
                let k = Double(26 - y) / 18, x = 60 + Int(Double(rib) * (1 - k * k).squareRoot())
                c.px(x, y, haze[0])
            }
        }
        for i in 0..<8 { c.rect(60 - (8 - i) / 3, 8 - i, (8 - i) / 3 * 2 + 1, 1, i % 2 == 0 ? haze[3] : haze[1]) }
        for x in [45, 75] { c.rect(x, 30, 2, 5, lit); c.px(x, 29, C(0x3A9AA0)); c.px(x + 1, 29, C(0x3A9AA0)) }
        // The palace gate, seen through the arch: a tall doorway glowing aqua inside.
        c.rect(52, 34, 17, 16, C(0x0A1C28)); c.rect(54, 32, 13, 2, C(0x0A1C28)); c.rect(57, 31, 7, 1, C(0x0A1C28))
        c.rect(54, 35, 13, 15, C(0x1A5C66)); c.rect(56, 33, 9, 2, C(0x1A5C66))
        c.rect(57, 36, 7, 14, C(0x2E8A8A)); c.rect(59, 37, 3, 13, C(0x6AD8CC))

        // The plinth: two steps of stone, lit along their tops.
        c.rect(24, 52, 72, 4, stone[2]); c.rect(24, 52, 72, 1, stone[4]); c.rect(95, 52, 1, 4, stone[0])
        c.rect(30, 49, 60, 3, stone[3]); c.rect(30, 49, 60, 1, stone[5]); c.rect(89, 49, 1, 3, stone[1])
        // The columns: round, fluted, lit from above-left, a capital and a base on each.
        for x0 in [35, 74] {
            for y in 26..<49 {
                for x in x0..<(x0 + 11) {
                    let k = Double(x - x0) / 10
                    var v = 0.78 - 0.62 * k
                    if (x - x0) % 3 == 1 { v -= 0.18 }
                    c.px(x, y, eterniaPlaces6Tone(stone, v, x, y))
                }
            }
            c.rect(x0 - 2, 23, 15, 3, stone[4]); c.rect(x0 - 2, 23, 15, 1, stone[5]); c.rect(x0 - 2, 25, 15, 1, stone[1])
            c.rect(x0 - 1, 46, 13, 3, stone[3]); c.rect(x0 - 1, 46, 13, 1, stone[4])
        }
        // The arch: a half-ring of voussoirs over them, lit on top and in shade underneath, a bite broken out of its
        // right shoulder.
        for y in 0...25 {
            for x in 35...85 {
                let dx = Double(x - 60), dy = Double(y - 25), d = (dx * dx + dy * dy).squareRoot()
                guard d >= 14, d <= 25.5 else { continue }
                let ang = atan2(-dy, dx) * 180 / .pi
                if ang > 22 && ang < 38 && d > 18 + noise(x * 3 + y) * 3 { continue }
                var v = 0.5 - dx / 25 * 0.25 + (25 - Double(y)) / 25 * 0.18
                if d < 15.5 { v = 0.12 } else if d > 24.6 { v = dx < 8 ? 0.95 : 0.4 }
                if Int(ang.rounded()) % 13 == 0 && d > 15.5 { v = 0.18 }
                c.px(x, y, eterniaPlaces6Tone(stone, v, x, y, grain: 0.2))
            }
        }
        // The keystone, standing proud, a bronze trident on it.
        c.rect(56, 0, 9, 12, stone[4]); c.rect(56, 0, 9, 1, stone[5]); c.rect(56, 0, 1, 12, stone[5]); c.rect(64, 0, 1, 12, stone[1])
        c.pattern(57, 2, [
            "B.B.B",
            "B.B.B",
            "BBBBB",
            "..B..",
            "..B..",
            "..D..",
            "..D..",
        ], ["B": C(0xD8B048), "D": C(0x8A6A28)])
        // Cracks, a fallen block at the foot of the broken shoulder.
        for (x, y) in [(41, 30), (42, 31), (42, 32), (41, 33), (79, 36), (78, 37), (78, 38), (46, 8), (47, 9), (72, 4), (73, 5)] {
            c.px(x, y, stone[0])
        }
        c.rect(88, 45, 7, 4, stone[3]); c.rect(88, 45, 7, 1, stone[5]); c.rect(94, 45, 1, 4, stone[1]); c.px(90, 47, stone[1])
        // Weed hanging from the underside of the arch and tufted along its top.
        for (x, len) in [(47, 7), (51, 4), (69, 5), (73, 8)] {
            for k in 0..<len {
                let wx = x + (k / 2 % 2)
                c.px(wx, 25 - Int((196 - Double((x - 60) * (x - 60))).squareRoot()) + k, k % 3 == 0 ? weedL : weed)
            }
        }
        for x in stride(from: 37, to: 84, by: 3) {
            let dx = Double(x - 60), y = 25 - Int((650 - dx * dx).squareRoot())
            if noise(x + 77) > 0.4 && (x < 64 || x > 79) { c.px(x, y - 1, weedL); c.px(x + 1, y, weed) }
        }
        // Barnacles, little pale pocks on the stone.
        for (x, y) in [(36, 40), (37, 41), (44, 34), (75, 42), (76, 41), (84, 30), (38, 14), (82, 18), (33, 50), (86, 53)] {
            c.px(x, y, barnacle)
        }

        // The reef at the arch's left foot.
        let reef = PixelCanvas(40, 26)
        eterniaCoral(reef, seed: 5)
        for yy in 0..<26 {
            for xx in 0..<40 where reef.buf[(yy * 40 + xx) * 4 + 3] > 0 { c.px(xx - 2, 30 + yy, unpremultiplied(reef, (yy * 40 + xx) * 4)) }
        }

        // The giant clam at its right: two fluted lavender shells, the top one gaping, a pink inside and the pearl.
        let shell = C(0x8C8AC4), shellD = C(0x5A5890), shellL = C(0xB8B6E4)
        for y in 38..<56 {
            for x in 91...115 {
                let dx = Double(x - 103) / 12
                if y >= 49 {
                    let dy = Double(y - 49) / 6
                    guard dx * dx + dy * dy <= 1 else { continue }
                    c.px(x, y, (x - 91) % 4 == 0 ? shellD : y == 49 ? shellL : shell)
                } else {
                    let dy = Double(49 - y) / 11
                    guard dx * dx + dy * dy <= 1 else { continue }
                    c.px(x, y, (x - 91) % 4 == 0 ? shellD : dx < -0.3 ? shellL : shell)
                }
            }
        }
        // The scalloped lips and the inside.
        for x in 92...114 { c.px(x, 48 + ((x / 2) % 2), shellD) }
        c.ellipse(103, 47, 8, 2, C(0xE8B4C8)); c.ellipse(103, 47, 6, 1, C(0xF4D0DC))
        c.circle(103, 46, 2, C(0xF4F0FF)); c.px(102, 45, C(0xFFFFFF)); c.px(104, 47, C(0xC8C0E0))
    }

    /// Where bubbles come up from, in arch units: the clam, the reef, cracks in the sea bed.
    private static let eterniaUnderseaVents: [(x: Int, y: Int)] = [(103, 44), (8, 42), (30, 52), (62, 30), (92, 52)]

    /// The kingdom's life: bubbles wobbling up from the clam, the reef and the sea bed, a school of little yellow fish
    /// and a pair of blue ones swimming by, light rippling over the sand, and the palace gate's glow breathing. On the
    /// screen saver the light rays from the surface sway and jellyfish drift up, pulsing.
    static func eterniaUnderseaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaUnderseaFrame(c, g), q = f.q, tall = isTall(c)
        // The gate's glow.
        let breath = 0.5 + 0.5 * sin(t * 1.1)
        c.ellipse(f.x + 60 * q + q / 2, f.y + 42 * q, 6 * q, 8 * q, C(0x7AF0E0, 0.08 + 0.10 * breath))
        // Light rippling over the sand: little bright dashes drifting and winking.
        for k in 0..<(c.w / (18 * q) + 1) {
            let v = sin(t * 1.6 + Double(k) * 2.1)
            guard v > 0.2 else { continue }
            let x = k * 18 * q + Int(noise(k + 700) * Double(10 * q)) + Int(sin(t * 0.5 + Double(k)) * Double(3 * q))
            let y = f.floor + Int(noise(k + 701) * Double(max(1, g - f.floor)))
            c.rect(x, y, 3 * q, max(1, q / 2), C(0xC8F4F0, 0.25 * v))
        }
        if tall {
            // The rays from the surface, swaying.
            for b in 0..<5 {
                let x0 = c.w * (b * 2 + 1) / 10 + Int(sin(t * 0.3 + Double(b) * 1.7) * Double(14 * s))
                let a = 0.05 + 0.03 * sin(t * 0.8 + Double(b))
                for y in stride(from: 0, to: f.floor, by: 1) {
                    c.rect(x0 + y / 4, y, (5 + y / (12 * s)) * s, 1, C(0xE8FFF8, a * (1 - Double(y) / Double(f.floor))))
                }
            }
            // Jellyfish drifting up, their bells pulsing, frilled arms under them and long tentacles trailing, sized to
            // the arch so they read on a big screen: the biggest bell about as wide as a Clawd.
            for j in 0..<3 {
                let ph = (t * 0.02 + Double(j) * 0.33).truncatingRemainder(dividingBy: 1)
                let x = Int(noise(j + 720) * Double(c.w)) + Int(sin(t * 0.4 + Double(j)) * Double(4 * q))
                let y = f.floor - Int(ph * Double(f.floor + 30 * q)) + 10 * q
                let size = [7, 5, 6][j], pulse = 0.88 + 0.12 * sin(t * 2.4 + Double(j))
                let r = Int(Double(size * q) * pulse), ry = r * 3 / 4, long = size * 3 * q, w = max(1, q / 2)
                // The tentacles, thin and long, fading as they go.
                for k in 0..<5 {
                    for i in 0..<long {
                        let wob = Int(sin(Double(i) * 0.25 / Double(q) + t * 2 + Double(k)) * Double(q))
                        c.rect(x - r * 3 / 4 + r * 3 * k / 8 + wob, y + i, w, 1, C(0xF4B8F4, 0.6 * (1 - Double(i) / Double(long))))
                    }
                }
                // The frilled arms, shorter and thicker, down the middle.
                for k in [-1, 1] {
                    for i in 0..<(r * 3 / 2) {
                        let wob = Int(sin(Double(i) * 0.3 / Double(q) + t * 1.5 + Double(k)) * Double(q))
                        c.rect(x + k * r / 4 + wob - q / 2, y + i, q, 1, C(0xE890E0, 0.7 * (1 - Double(i) / Double(r * 2))))
                    }
                }
                // The bell: a dome, paler inside its rim, lit at its crown, its rim scalloped and bright.
                for dy in -ry...0 {
                    let half = Int((Double(r) * (1 - Double(dy * dy) / Double(ry * ry)).squareRoot()).rounded())
                    c.rect(x - half, y + dy, 2 * half + 1, 1, C(0xD890E8, 0.72))
                    if half > q { c.rect(x - half + q, y + dy, 2 * (half - q) + 1, 1, C(0xF0B8F8, 0.3)) }
                }
                c.ellipse(x - r / 3, y - ry / 2, max(1, r / 3), max(1, ry / 5), C(0xFFE8FF, 0.8))
                for k in 0..<5 { c.ellipse(x - r + r * k / 2, y + q / 2, max(1, r / 5), max(1, q / 2 + 1), C(0xF8D0FC, 0.8)) }
            }
        }
        // Bubbles: each vent lets a string of them go, wobbling up and growing a little.
        let rise = Double(f.floor)
        var vents = eterniaUnderseaVents.map { (x: f.x + $0.x * q, y: f.y + $0.y * q) }
        for frac in [0.2, 0.6] {
            vents.append((x: eterniaPlaces6Side(c, f.x, q, frac, left: true), y: f.floor))
            vents.append((x: eterniaPlaces6Side(c, f.x, q, frac, left: false), y: f.floor))
        }
        for (i, v) in vents.enumerated() {
            for k in 0..<5 {
                let ph = (t * (0.09 + noise(i + 730) * 0.05) + Double(k) / 5 + noise(i + 731)).truncatingRemainder(dividingBy: 1)
                let y = Double(v.y) - ph * rise
                guard y > 0 else { continue }
                let x = v.x + Int(sin(t * 2.2 + Double(k * 3 + i)) * Double(q))
                let r = max(1, Int(Double(q) * (0.6 + ph * 0.8)))
                c.circle(x, Int(y), r, C(0xB8F0FA, 0.35))
                c.px(x - r / 2, Int(y) - r / 2, C(0xFFFFFF, 0.9))
            }
        }
        // Fish: a school of little yellow ones swimming right, and two blue ones swimming left.
        let b = max(1, (q + 1) / 2)
        let right = ["..YYY..", "TYYYYEY", "TYSYYYY", "..YYY.."]
        let left = right.map { String($0.reversed()) }
        let span = Double(c.w + 40 * b)
        let schoolX = (t * Double(9 * b)).truncatingRemainder(dividingBy: span) - Double(20 * b)
        let schoolY = Double(f.floor) * (tall ? 0.45 : 0.30)
        for k in 0..<7 {
            let x = Int(schoolX) - Int(noise(k + 740) * Double(28 * b)), y = Int(schoolY + noise(k + 741) * Double(10 * b) + sin(t * 1.5 + Double(k)) * Double(b))
            eterniaPlaces6Pattern(c, x, y, b, right, ["Y": C(0xF0D84A), "T": C(0xC8A830), "E": C(0x1A1A2A), "S": C(0x6A8AE0)])
        }
        let pairX = span - (t * Double(6 * b) + span / 2).truncatingRemainder(dividingBy: span) - Double(20 * b)
        for k in 0..<2 {
            let x = Int(pairX) + k * 12 * b, y = Int(Double(f.floor) * (tall ? 0.62 : 0.5)) + k * 5 * b + Int(sin(t + Double(k)) * Double(b))
            eterniaPlaces6Pattern(c, x, y, b, left, ["Y": C(0x4A7AF0), "T": C(0xF0D84A), "E": C(0x101828), "S": C(0x2A48A8)])
        }
    }
}

// MARK: - Beast Island

extension Scenes {
    /// Where things stand on Beast Island: the volcano and its crags are drawn at one pixel to a unit on a canvas of
    /// their own (`eterniaBeastIslandArt`, 120×56) and blown up `q` times, a little right of the middle, their foot on
    /// `base`, the canvas's top left at `x`/`y`. `crater` is the middle of the crater's mouth.
    static func eterniaBeastIslandFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int, crater: (x: Int, y: Int)) {
        let q = eterniaPlaces6Q(c, g)
        let base = g - (isTall(c) ? 10 : 6) * q
        let x = c.w * 54 / 100 - 60 * q, y = base - 56 * q
        return (q, base, x, y, (x + 66 * q + q / 2, y + 5 * q))
    }

    /// The caves in the crags, in island units, where eyes blink: the middle of each mouth.
    private static let eterniaBeastCaves: [(x: Int, y: Int)] = [(14, 46), (31, 43), (108, 47)]

    /// The dark thickets beside the volcano where more eyes watch: each one's middle, its foot on `base`.
    private static func eterniaBeastThickets(_ c: PixelCanvas, _ g: Int) -> [(x: Int, y: Int, r: Int)] {
        let f = eterniaBeastIslandFrame(c, g), q = f.q
        return [(0.45, true), (0.85, true), (0.35, false), (0.75, false)].map { p in
            (eterniaPlaces6Side(c, f.x, q, p.0, left: p.1), f.base - 2 * q, 6 * q)
        }
    }

    /// Beast Island: a dim green-grey sky going sickly olive at the horizon, ash lying across it in long bands, the
    /// glow of the volcano reddening the air round its top. Jagged islands far off in the murk, fog along their foot.
    /// The volcano: a cone of dark basalt, gullies running down it, its crater glowing, lava trickling down in three
    /// crooked runs. Mossy crags at its foot with black caves in them (eyes blink in them in the moving layer), dark
    /// thickets beside it, and twisted trees, gnarled and hung with moss, framing it either side. The crew stands on
    /// dark mossy rock. On the screen saver the volcano stands three times the size, a ghostly moon behind the ash.
    static func eterniaBeastIsland(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaBeastIslandFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 20 : 8) * q
        c.gradient(0, f.base, C(tall ? 0x0A0E10 : 0x1C2622), C(0x7C7C58), bands: tall ? 12 : 7)
        if tall {
            c.stars(0, horizon / 3, density: 160, seed: 41)
            // A pale, sickly moon behind the ash.
            let mx = c.w * 18 / 100, my = horizon / 5, mr = 11 * s
            c.circle(mx, my, mr * 2, C(0xD8E0B0, 0.06)); c.circle(mx, my, mr, C(0xC8D0A4))
            c.circle(mx + mr / 3, my + mr / 4, mr * 3 / 4, C(0xB4BC92)); c.circle(mx - mr / 3, my - mr / 3, mr / 4, C(0xA0A884))
        }
        // The volcano's glow reddening the air round its top, strongest at the crater and fading smoothly out.
        eterniaPlaces6Glow(c, f.crater.x, f.crater.y, 54 * q, C(0xE0602A), peak: 0.34)
        // Ash across the sky in long bands, lit dull orange underneath.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(30, 12, 36), (66, 22, 40), (6, 34, 30), (44, 46, 34), (80, 56, 26), (14, 64, 30)]
            : [(4, 20, 18), (64, 12, 16), (86, 36, 12), (30, 8, 12)]
        for (k, b) in banks.enumerated() {
            let x = c.w * b.x / 100, y = horizon * b.y / 100, len = b.len * s * (tall ? 2 : 1), th = s * (tall ? 2 : 1)
            for p in 0..<4 {
                let px = x + len * p / 4 + Int(noise(k * 7 + p + 200) * Double(len / 6)), pw = len / 3 + Int(noise(k * 7 + p + 240) * Double(len / 5))
                c.rect(px, y - th * (1 + p % 2), pw, th * (1 + p % 2), C(0x2A2E2A))
            }
            c.rect(x, y, len, th, C(0x3C3E36)); c.rect(x + len / 8, y + th, len * 3 / 4, th, C(0x7A5A3A))
        }
        // The far islands, jagged, the nearer darker, fog lying along their foot.
        if tall { eterniaBeastCrags(c, base: horizon - 14 * s, amp: 16 * s, period: 22 * s, seed: 5, bottom: f.base, C(0x3E4842), edge: C(0x56625A)) }
        eterniaBeastCrags(c, base: horizon, amp: (tall ? 10 : 6) * s, period: (tall ? 16 : 12) * s, seed: 13, bottom: f.base,
                          C(0x2A3430), edge: C(0x46544C))
        for y in (horizon - 2 * s)..<(horizon + 4 * s) { c.rect(0, y, c.w, 1, C(0xA8B4A0, 0.14)) }

        // The volcano and its crags, blown up to size.
        let art = PixelCanvas(120, 56)
        eterniaBeastIslandArt(art)
        eterniaPlaces6Blit(c, art, f.x, f.y, q)

        // The rock in front, dark and mossy and plain where the crew stands.
        c.gradient(f.base, g, C(0x323A32), C(0x283028), bands: 3)
        // The thickets: dark mounds of fern and thorn, a few fronds standing up out of them.
        for t in eterniaBeastThickets(c, g) {
            c.ellipse(t.x, t.y + t.r / 3, t.r * 3 / 2, t.r, C(0x161E18))
            c.ellipse(t.x - t.r / 3, t.y, t.r, t.r * 2 / 3, C(0x1E2A20))
            for k in 0..<5 {
                let fx = t.x - t.r + k * t.r / 2
                for i in 0..<(t.r) { c.rect(fx + (k - 2) * i / 4, t.y - t.r / 2 - i, max(1, q / 2 + 1), 1, C(0x2E4230)) }
            }
        }
        // Twisted trees either side, the nearer bigger.
        let trees: [(frac: Double, left: Bool, size: Int, seed: Int)] = [(0.12, true, 4, 1), (0.62, true, 2, 2), (0.3, false, 2, 3), (0.88, false, 4, 4)]
        for tr in trees {
            let tq = max(1, q * tr.size / 4), foot = tr.size == 4 ? g : f.base + q
            let art = PixelCanvas(36, 46)
            eterniaTwistedTree(art, seed: tr.seed)
            eterniaPlaces6Blit(c, art, eterniaPlaces6Side(c, f.x, q, tr.frac, left: tr.left) - 18 * tq, foot - 46 * tq, tq, flip: !tr.left)
        }
        c.ground(g, C(0x2A322C), edge: C(0x46544A), speck: C(0x202620), seed: 43)
    }

    /// Jagged ranges along the horizon: peaks every `period` pixels at heights of their own, filled to `bottom`.
    private static func eterniaBeastCrags(_ c: PixelCanvas, base: Int, amp: Int, period: Int, seed: Int, bottom: Int, _ col: Px, edge: Px) {
        let p = max(1, period)
        for x in 0..<c.w {
            let k = x / p, f = Double(x % p) / Double(p)
            let h0 = noise(k * 31 + seed), h1 = noise((k + 1) * 31 + seed)
            let top = base - Int((h0 * (1 - f) + h1 * f - 0.45 * sin(f * .pi)) * Double(amp))
            if top < bottom { c.rect(x, top, 1, bottom - top, col); c.px(x, top, edge) }
        }
    }

    /// A twisted tree, one pixel to a unit on a 36×46 canvas, its foot on row 45: a crooked trunk of dark wood,
    /// gnarled and knotted, lit dull green down one side, limbs bending back on themselves, dark clumps of leaves at
    /// their ends and grey-green moss hanging off them in strands.
    private static func eterniaTwistedTree(_ a: PixelCanvas, seed: Int) {
        let bark = C(0x241E18), barkL = C(0x4E4A36), leaf = C(0x1E2E1E), leafL = C(0x34482C), moss = C(0x8A9670)
        var ends: [(Int, Int)] = []
        /// A limb from (x0, y0) going `len` units at angle `a` (0 up), bending as it goes, forking `depth` more times.
        func limb(_ x0: Double, _ y0: Double, _ dir: Double, _ len: Double, _ wide: Int, _ depth: Int, _ k: Int) {
            var x = x0, y = y0, ang = dir
            for _ in 0..<max(1, Int(len)) {
                ang += 0.08 * (k % 2 == 0 ? 1 : -1)
                x += sin(ang); y -= cos(ang)
                a.rect(Int(x), Int(y), wide, 1, bark); a.px(Int(x), Int(y), barkL)
            }
            guard depth > 0 else { ends.append((Int(x), Int(y))); return }
            let spread = 0.6 + noise(seed * 31 + k) * 0.4
            limb(x, y, ang - spread, len * 0.7, max(1, wide - 1), depth - 1, k * 2 + 1)
            limb(x, y, ang + spread * 0.9, len * 0.6, max(1, wide - 1), depth - 1, k * 2 + 2)
        }
        // Roots clawing at the rock, and the trunk, writhing up.
        a.rect(10, 43, 14, 3, bark); a.px(8, 45, bark); a.px(9, 44, bark); a.px(24, 44, bark); a.px(25, 45, bark); a.px(10, 43, barkL)
        var x = 14.0
        for y in stride(from: 44, to: 22, by: -1) {
            x += sin(Double(y) * 0.35 + Double(seed)) * 0.6
            a.rect(Int(x), y, 5, 1, bark); a.px(Int(x), y, barkL)
            if y % 7 == seed % 7 { a.rect(Int(x) - 1, y, 2, 2, bark) }   // a knot
        }
        a.rect(Int(x) + 2, 32, 1, 3, C(0x0A0806))   // a hollow
        limb(x + 1, 23, -0.6, 10, 3, 2, 1)
        limb(x + 3, 24, 0.7, 11, 3, 2, 2)
        limb(x + 2, 26, -1.2, 7, 2, 1, 3)
        // Clumps of dark leaves at the ends, moss hanging off the limbs.
        for (i, e) in ends.enumerated() {
            a.ellipse(e.0, e.1, 4, 2, leaf); a.ellipse(e.0 - 1, e.1 - 1, 2, 1, leafL)
            let len = 4 + Int(noise(seed * 13 + i) * 6)
            for k in 0..<len { a.px(e.0 + (i % 2 == 0 ? -2 : 2) + (k / 3) % 2, e.1 + 2 + k, moss.alpha(1 - Double(k) / Double(len) * 0.5)) }
        }
    }

    /// The volcano and its crags, one pixel to a unit on a 120×56 canvas, their foot on row 55.
    static func eterniaBeastIslandArt(_ c: PixelCanvas) {
        let rock = [C(0x100E0C), C(0x1C1916), C(0x2A2520), C(0x3A332B), C(0x4C4337), C(0x625746)]
        let mossy = [C(0x141A16), C(0x1E2620), C(0x2A342C), C(0x3A463A), C(0x4E5C4A), C(0x66765E)]
        let lava = C(0xF06A1E), lavaL = C(0xFFC44A), crust = C(0x3A1A10), glow = C(0x5A2A18)
        let cx = 66.0
        /// How far the cone reaches either side of its middle at row `y`.
        func hw(_ y: Int) -> Double { let k = Double(y - 5) / 50; return 8 + 28 * k + 16 * pow(k, 2.2) }
        // The cone: dark basalt lit from the left by the last of the sky, darker on the right.
        for y in 5..<56 {
            let r = hw(y), jag = (noise(y * 3 + 900) - 0.5) * 2
            for x in Int(cx - r + jag)...Int(cx + r - jag) {
                let n = (Double(x) - cx) / r
                c.px(x, y, eterniaPlaces6Tone(rock, 0.55 - 0.35 * n - Double(y - 5) / 50 * 0.12, x, y, grain: 0.3))
            }
            c.px(Int(cx - r + jag), y, rock[5])
        }
        // Gullies running down from the rim.
        for (i, off) in [-5.0, -2.5, 1.0, 3.5, 6.0].enumerated() {
            for y in 8..<56 {
                let x = Int(cx + off * hw(y) / 8 + sin(Double(y) * 0.3 + Double(i)) * 0.8)
                c.px(x, y, rock[0]); c.px(x - 1, y, rock[4])
            }
        }
        // The crater: a jagged rim, lit by what's in it.
        for x in 56...76 {
            let top = 3 + Int(noise(x + 920) * 2.2)
            c.rect(x, top, 1, 6 - top, rock[3]); c.px(x, top, C(0xC86A3A))
        }
        c.ellipse(Int(cx), 5, 7, 1, lava); c.rect(Int(cx) - 4, 5, 9, 1, lavaL)
        // Lava trickling down in three crooked runs, a crust either side, the rock glowing round them.
        for (i, (x0, len)) in [(60, 22), (69, 34), (73, 16)].enumerated() {
            var x = Double(x0)
            for y in 6..<(6 + len) {
                x += sin(Double(y) * 0.5 + Double(i * 2)) * 0.5 + (Double(x0) - cx) * 0.02
                let ix = Int(x)
                c.px(ix - 2, y, glow); c.px(ix + 2, y, glow)
                c.px(ix - 1, y, crust); c.px(ix + 1, y, crust)
                c.px(ix, y, y % 3 == 0 ? lavaL : lava)
            }
        }
        /// A crag: a jagged spire of mossy rock from the foot to `top`, `w` wide at its base, moss on its ledges.
        func crag(_ x0: Int, _ w: Int, _ top: Int, lean: Int) {
            for y in top..<56 {
                let k = Double(y - top) / Double(56 - top)
                let half = Double(w) / 2 * pow(k, 0.55) + 0.6
                let mid = Double(x0) + Double(lean) * pow(1 - k, 2) + (noise(y / 2 + x0 * 3) - 0.5) * 2
                let l = Int((mid - half).rounded()), r = Int((mid + half).rounded())
                for x in l...r { c.px(x, y, eterniaPlaces6Tone(mossy, 0.62 - 0.45 * (Double(x) - mid) / max(1, half), x, y, grain: 0.3)) }
                c.px(l, y, mossy[5]); c.px(r, y, mossy[0])
                if noise(y * 5 + x0) > 0.82 { c.rect(l, y, max(1, (r - l) / 2), 1, C(0x5A7444)) }
            }
        }
        crag(14, 24, 16, lean: -3)
        crag(31, 16, 28, lean: 2)
        crag(108, 22, 26, lean: 3)
        crag(92, 10, 40, lean: -1)
        // The caves: black mouths in the crags, a lip of lit rock over each.
        for cave in eterniaBeastCaves {
            c.ellipse(cave.x, cave.y, 4, 3, C(0x060806)); c.rect(cave.x - 4, cave.y + 2, 9, 2, C(0x060806))
            c.rect(cave.x - 3, cave.y - 4, 7, 1, mossy[4])
        }
        // Boulders round the foot, seating it all on the rock.
        for (x, w) in [(2, 6), (40, 5), (52, 3), (84, 4), (116, 4)] {
            c.rect(x, 52, w, 4, rock[2]); c.rect(x + 1, 51, w - 2, 1, rock[3]); c.px(x, 52, rock[5])
        }
    }

    /// Beast Island's life: fog rolling along the foot of the volcano and over the rock, smoke climbing out of the
    /// crater lit orange from under, the crater's glow breathing, and red eyes opening in the caves and thickets,
    /// blinking, and shutting again. On the screen saver the smoke climbs high and a winged beast circles in it.
    static func eterniaBeastIslandLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaBeastIslandFrame(c, g), q = f.q, tall = isTall(c)
        // The crater's glow.
        let breath = 0.5 + 0.5 * sin(t * 1.3)
        c.ellipse(f.crater.x, f.crater.y, 9 * q, 3 * q, C(0xFF8A30, 0.14 + 0.14 * breath))
        // Smoke out of the crater, rolling up and drifting off to the right.
        let rise = Double((tall ? 50 : 10) * q)
        for k in 0..<16 {
            let ph = (t * 0.06 + Double(k) / 16).truncatingRemainder(dividingBy: 1)
            let x = Double(f.crater.x) + ph * ph * Double((tall ? 40 : 16) * q) + sin(ph * 7 + t * 0.4 + Double(k)) * Double(q) * (1 + ph * 5)
            let y = Double(f.crater.y) - Double(q) - ph * rise
            let r = Double(q) * (2.5 + ph * (tall ? 10 : 4))
            let a = min(1, (1 - ph) * 1.4) * 0.8
            c.circle(Int(x), Int(y), Int(r), C(0x3A3A36, a))
            c.circle(Int(x + r / 4), Int(y + r / 3), Int(r * 0.6), C(0x7A3E22, a * (1 - ph)))
            c.circle(Int(x - r / 4), Int(y - r / 4), Int(r * 0.6), C(0x55554E, a))
        }
        if tall {
            // A winged beast circling in the smoke.
            let b = max(1, q * 2 / 3), a = t * 0.3
            let x = f.crater.x + Int(cos(a) * Double(34 * q)), y = f.crater.y - 24 * q + Int(sin(a) * Double(6 * q))
            let up = ["W...........W", "WW....H....WW", ".WWW.HHH.WWW.", "...WWWWWWW...", "......T......", "......T......"]
            let down = ["......H......", ".....HHH.....", ".WWWWWWWWWWW.", "WW...WWW...WW", "W.....T.....W", "......T......"]
            eterniaPlaces6Pattern(c, x - 6 * b, y, b, Int(t * 3) % 2 == 0 ? up : down, ["W": C(0x1A1614), "H": C(0x241C18), "T": C(0x1A1614)])
        }
        // Fog: long pale banks rolling slowly across, low along the rock and round the volcano's foot.
        let span = Double(c.w + 80 * q)
        for k in 0..<9 {
            let speed = Double(q) * (2 + noise(k + 800) * 2)
            let x = (t * speed + noise(k + 801) * span).truncatingRemainder(dividingBy: span) - Double(40 * q)
            let y = k < 4 ? f.y + (38 + k * 4) * q : f.base - 3 * q + Int(noise(k + 802) * Double(max(1, g - f.base)))
            c.ellipse(Int(x), y, (18 + Int(noise(k + 803) * 14)) * q, max(1, 2 * q), C(0xB0BCA8, 0.16))
            c.ellipse(Int(x) + 6 * q, y - q, 10 * q, max(1, q), C(0xC8D2C0, 0.10))
        }
        // Eyes in the dark: a pair opens in a cave or a thicket, blinks, and shuts again.
        var spots = eterniaBeastCaves.map { (x: f.x + $0.x * q + q / 2, y: f.y + $0.y * q) }
        spots += eterniaBeastThickets(c, g).map { (x: $0.x, y: $0.y) }
        for (i, p) in spots.enumerated() {
            let period = 5.0 + Double(i % 3) * 1.3
            let ph = (t + Double(i) * 2.1).truncatingRemainder(dividingBy: period) / period
            guard ph < 0.5, !(ph > 0.22 && ph < 0.26) else { continue }
            let e = max(1, q * 2 / 3), gap = max(2, q * 2)
            for ex in [p.x - gap, p.x + gap - e] {
                c.circle(ex, p.y, 2 * q, C(0xFF2A1A, 0.16))
                c.rect(ex, p.y, e + (q > 1 ? q / 2 : 0), e, C(0xFF3A22))
            }
        }
    }
}

// MARK: - The House of Shokoti

extension Scenes {
    /// Where things stand at the House of Shokoti: the spire is drawn at one pixel to a unit on a canvas of its own
    /// (`eterniaTempleArt`, 120 wide and `rows` tall) and blown up `q` times, its foot on `base`, the canvas's top left
    /// at `x`/`y`. On the screen saver the canvas is 76 rows, taller than the other landmarks', as the spire is taller
    /// than it is wide; in the window's strip it's the usual 56, so the needle still fits under the top.
    static func eterniaTempleFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int, rows: Int) {
        let q = eterniaPlaces6Q(c, g), rows = isTall(c) ? 76 : 56
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 60 * q, base - rows * q, rows)
    }

    /// Half the spire's width on row `y` of a canvas `rows` tall: a needle at the top, 30 either side at its foot.
    private static func eterniaHouseHalf(_ y: Int, _ rows: Int) -> Int {
        let k = Double(max(0, y)) / Double(rows - 1)
        return Int((30 * pow(k, 1.5)).rounded())
    }

    /// Shokoti's eyes in the face over the door, one unit each, in the door's units (rows 31 to 55, moved down to the
    /// foot of the canvas with the door). They glow white in the moving layer.
    private static let eterniaShokotiEyes: [(x: Int, y: Int)] = [(59, 42), (61, 42)]

    /// The rocks of the Sands of Time either side: each one's middle (`x`) and the foot it stands on.
    private static func eterniaHouseRocks(_ c: PixelCanvas, _ g: Int) -> [(x: Int, foot: Int)] {
        let f = eterniaTempleFrame(c, g), q = f.q, foot = f.base + 2 * q
        return [(0.7, true), (0.3, false)].map { p in (eterniaPlaces6Side(c, f.x, q, p.0, left: p.1), foot) }
    }

    /// The House of Shokoti, the House of Darkness: the witch's prison, sealed under the Sands of Time and raised out
    /// of the desert again by Masque, as in the cartoon. Night under a dark red sky, heavy clouds darker still, and
    /// jagged rocks along the horizon. The house is a tall, steep spire of pale blue stone running up to a needle,
    /// lit on its left face and shaded on its right, a ridge down the middle where they meet, cut into great blocks
    /// and cracked all over, the sand swirling round its foot. Its door, at the foot, is set in a niche of mauve stone
    /// between two pointed fins carved with glyphs, and over it is her face: small, carved and painted, tan, with red
    /// hair, horns curving up either side, a crescent on her brow and a great crescent collar under her chin, her eyes
    /// blank (they glow in the moving layer). Jagged rocks stand out of the sand either side, a beast's skull lies
    /// half buried on the left, and the crew stands on blue sand swirled by the wind.
    static func eterniaTemple(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaTempleFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 14 : 5) * q
        c.gradient(0, horizon, C(tall ? 0x1E060C : 0x3A0E14), C(0x8A2A28), bands: tall ? 12 : 6)
        c.rect(0, horizon, c.w, f.base - horizon, C(0x8A2A28))
        // Heavy clouds, darker than the sky, their undersides catching a little red.
        let clouds: [(x: Int, y: Int, len: Int)] = tall
            ? [(4, 20, 40), (52, 12, 46), (20, 46, 30), (70, 40, 34), (40, 64, 26)]
            : [(6, 20, 22), (58, 14, 26), (30, 50, 16), (82, 44, 14)]
        for (k, w) in clouds.enumerated() {
            let x = c.w * w.x / 100, y = horizon * w.y / 100, len = w.len * s * (tall ? 2 : 1), th = max(1, s * (tall ? 3 : 1))
            c.ellipse(x + len / 2, y + th, len / 2, th * 2, C(0x2A080E, 0.8))
            c.ellipse(x + len * (k % 2 + 1) / 4, y - th / 2, len / 5, th * 2, C(0x2A080E, 0.8))
            c.rect(x + len / 4, y + th * 3, len / 2, max(1, th / 2), C(0xA83A30, 0.5))
        }
        // Jagged rocks along the horizon, lavender against the red.
        for k in 0..<(c.w / (14 * s) + 1) {
            let x = k * 14 * s + Int(noise(k + 940) * Double(8 * s))
            let h = (3 + Int(noise(k + 941) * 7)) * s * (tall ? 2 : 1), w = max(2, h / 3)
            guard abs(x - c.w / 2) > 30 * q else { continue }
            for i in 0..<h {
                let half = w * (i + 1) / h
                c.rect(x - half, horizon - h + i, 2 * half + 1, 1, C(0x6A6290))
                c.px(x - half, horizon - h + i, C(0x9A94C0))
            }
        }
        c.dunes(base: horizon + s, amp: Double(3 * s), freq: 0.03 / Double(s), phase: 0.4, bottom: f.base, C(0x3A5482), shade: C(0x7A98C8))
        c.dunes(base: horizon + (tall ? 8 : 3) * s, amp: Double(2 * s), freq: 0.06 / Double(s), phase: 2.2, bottom: f.base,
                C(0x445E8E), shade: C(0x86A2CC))

        // The house, blown up to size.
        let art = PixelCanvas(120, f.rows)
        eterniaTempleArt(art)
        eterniaPlaces6Blit(c, art, f.x, f.y, q)

        // The sand in front, blue in the night, swirled by the wind, plain where the crew stands.
        c.gradient(f.base, g, C(0x4A6694), C(0x3E5888), bands: 3)
        for k in 0..<(c.w / (12 * q) + 1) {
            let x = k * 12 * q + Int(noise(k + 950) * Double(8 * q)), y = f.base + q + Int(noise(k + 951) * Double(max(1, g - f.base - 2 * q)))
            let len = (5 + Int(noise(k + 952) * 5)) * q, th = max(1, q / 2)
            c.rect(x, y, len, th, C(0x86A2CC)); c.rect(x + len, y - th, len / 2, th, C(0x86A2CC))
            c.rect(x + len / 3, y + th, len / 2, th, C(0x30487A))
        }
        // The rocks either side, and the beast's skull half buried on the left.
        for (i, r) in eterniaHouseRocks(c, g).enumerated() {
            let rock = PixelCanvas(16, 46)
            eterniaHouseRock(rock, seed: i)
            eterniaPlaces6Blit(c, rock, r.x - 8 * q, r.foot - 46 * q, q)
        }
        let skull = PixelCanvas(30, 14)
        eterniaSandSkull(skull)
        eterniaPlaces6Blit(c, skull, eterniaPlaces6Side(c, f.x, q, 0.25, left: true) - 15 * q, f.base + 2 * q - 14 * q, q)
        c.ground(g, C(0x34497A), edge: C(0x5A76A8), speck: C(0x2C3E6A), seed: 47)
    }

    /// A jagged rock standing out of the sand, one pixel to a unit on a 16×46 canvas, its foot on row 45: a tall
    /// spike leaning out (`seed` 0 one way, 1 the other), lit lavender down its left and inked dark down its right, a
    /// smaller one beside it, a crack or two, and blue sand heaped round their feet.
    private static func eterniaHouseRock(_ a: PixelCanvas, seed: Int) {
        let tone = [C(0x2A2448), C(0x4A4472), C(0x6A6494), C(0x8A86B4), C(0xB4B0D4)]
        let lean: Double = seed % 2 == 0 ? 3 : -3
        /// One spike: its foot centred on `foot`, its point on row `top`, leaning `tilt` units over, `width` across.
        func spike(_ foot: Double, _ top: Int, _ tilt: Double, _ width: Double) {
            for y in top...45 {
                let k = Double(45 - y) / Double(45 - top)
                let cx: Double = foot + tilt * k
                var half: Double = 0.5 + (1 - k) * width
                if y % 9 == 4 { half -= 1 }
                let l = Int((cx - half).rounded()), r = Int((cx + half).rounded())
                guard l <= r else { continue }
                for x in l...r { a.px(x, y, x == l ? tone[4] : Double(x) < cx ? tone[3] : tone[2]) }
                a.px(r, y, tone[0])
            }
        }
        spike(seed % 2 == 0 ? 13 : 3, 24, lean * 0.6, 2.4)
        spike(8, 3, lean, 5.2)
        for y in stride(from: 16, through: 38, by: 11) { a.px(7 + (y / 11) % 2, y, tone[0]); a.px(8, y + 1, tone[1]) }
        for x in 0..<16 {
            let h = 3 - abs(x - 8) / 3
            if h > 0 { a.rect(x, 46 - h, 1, h, C(0x4A6694)); a.px(x, 46 - h, C(0x86A2CC)) }
        }
    }

    /// A great beast's skull half buried in the sand, one pixel to a unit on a 30×14 canvas: bleached bone gone cold
    /// in the night, a deep round socket under a heavy brow, a long snout with a nostril, a row of teeth and a horn
    /// curling back.
    private static func eterniaSandSkull(_ a: PixelCanvas) {
        a.pattern(0, 0, [
            "...................hh.........",
            ".................hhH..........",
            "...............hhH............",
            "..........BBBBBhH.............",
            ".......BBLLLLBBBBBB...........",
            ".....BBBDKKKDBBBBBBBB.........",
            "...BBBBBKKKKKBBBBBBBBBB.......",
            "..BBBBBBDKKKDBBBBBBBBBBBB.....",
            ".BBNBBBBBBBBBBBBBBBBBBBBBBB...",
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBB.",
            "BTTTBTTTBTTTBBBBBBBBBBBBBBBBBB",
            "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
            "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
            "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
        ], ["B": C(0xB4AEC8), "L": C(0xE0DCEC), "D": C(0x5A5674), "K": C(0x16142A), "N": C(0x3E3A5A),
            "T": C(0xE0DCEC), "h": C(0xA4A0BC), "H": C(0x625E80), "S": C(0x4A6694)])
        for x in 13..<26 { a.px(x, 9 - (x > 20 ? 1 : 0), C(0xCCC8DC)) }
    }

    /// The house itself, one pixel to a unit on a canvas 120 wide, its foot on the bottom row: the spire of pale blue stone,
    /// cracked and cut in blocks, its door at the foot with her face over it, and the sand swirled round its foot.
    static func eterniaTempleArt(_ c: PixelCanvas) {
        let ink = C(0x1A2440)
        let lit = [C(0x8EA6C8), C(0xA6BCDA), C(0xBCD0E8)], shade = [C(0x5A7098), C(0x6A82AA), C(0x7A92B8)]
        // The spire: the left face lit, the right in shade, inked round its edge, a ridge where the faces meet.
        let rows = c.h
        for y in 0..<rows {
            let hw = eterniaHouseHalf(y, rows) + (y > 10 && noise(y + 930) > 0.8 ? 1 : 0)
            guard hw > 0 else { c.px(60, y, ink); continue }
            for x in (60 - hw)...(60 + hw) {
                let n = noise(x * 7 + y * 131)
                let band = n > 0.96 ? 2 : n < 0.04 ? 0 : 1
                c.px(x, y, x < 60 ? lit[x > 60 - hw / 3 ? min(2, band + 1) : band] : shade[band])
            }
            c.px(60 - hw, y, ink); c.px(60 + hw, y, ink)
            c.px(60, y, C(0x3A4C70))
        }
        // The blocks: seams across each face, staggered, and cracks wandering down.
        for y in stride(from: 18, through: rows - 6, by: 7) {
            let hw = eterniaHouseHalf(y, rows)
            guard hw > 3 else { continue }
            for x in (60 - hw + 1)..<(60 + hw) where x != 60 && noise(x / 4 + y * 17) > 0.35 { c.px(x, y, C(0x4A5E84)) }
            for k in 0..<max(1, hw / 8) {
                let x = 60 - hw + 2 + Int(noise(k * 5 + y * 31) * Double(2 * hw - 3))
                for yy in (y + 1)..<min(rows, y + 7) { c.px(x, yy, C(0x4A5E84)) }
            }
        }
        for (k, start) in [(x: 56, y: 30), (x: 66, y: 38), (x: 48, y: 56), (x: 74, y: 60), (x: 59, y: 10), (x: 52, y: 46)].enumerated() {
            var x = start.x
            let y0 = start.y * rows / 76
            for y in y0..<min(rows, y0 + 9) {
                c.px(x, y, ink)
                if noise(k * 41 + y) > 0.6 { x += noise(k * 43 + y) > 0.5 ? 1 : -1 }
            }
        }

        // The door's niche of mauve stone, between two pointed fins carved with glyphs.
        c.oy = rows - 56
        let mauve = [C(0x3A1A30), C(0x6A3A58), C(0x9A5878), C(0xC07898)]
        for y in 37...55 {
            c.rect(54, y, 13, 1, y < 39 ? mauve[2] : mauve[1])
        }
        c.rect(54, 37, 13, 1, mauve[0])
        for side in [-1, 1] {
            for y in 32...55 {
                let w = 2 + (y - 32) / 9
                let x0 = side < 0 ? 54 - w : 66
                c.rect(x0, y, w, 1, side < 0 ? mauve[3] : mauve[2])
                c.px(side < 0 ? x0 : x0 + w - 1, y, mauve[0]); c.px(side < 0 ? 53 : 66, y, mauve[0])
            }
            c.px(side < 0 ? 53 : 66, 31, mauve[0])
            for (gy, gw) in [(46, 2), (49, 1), (52, 2)] {
                c.rect(side < 0 ? 52 - gw : 68, gy, gw, 1, mauve[0])
            }
        }
        // The doorway, dark, under her face.
        c.rect(57, 50, 7, 6, C(0x0A0610)); c.rect(57, 50, 7, 1, mauve[0])

        // Her face over the door: tan, red hair, horns, a crescent on the brow and a great crescent collar.
        c.pattern(55, 38, [
            "....H.H....",
            "H....H....H",
            "H...RRR...H",
            ".H.RFFFR.H.",
            ".hHRKFKRHh.",
            "...RFfFR...",
            "...RFMFR...",
            "...r.F.r...",
            "H.........H",
            ".HH.....HH.",
            "..hHHHHHh..",
        ], ["H": C(0xF0D0A0), "h": C(0xB08A60), "R": C(0xA83A28), "r": C(0x6A2418), "F": C(0xE8A878),
            "f": C(0xC08058), "K": C(0xF8F0E8), "M": C(0x8A3A30)])

        // The sand swirled round its foot, piled against it, lit along the top.
        for (cx, width, peak) in [(36.0, 18.0, 5.0), (86.0, 16.0, 4.0)] {
            for x in 0..<120 {
                let k = (Double(x) - cx) / width
                let h = Int((peak * (1 - k * k)).rounded())
                guard h > 0 else { continue }
                for y in (56 - h)...55 { c.px(x, y, noise(x * 7 + y * 131) > 0.85 ? C(0x3E5888) : C(0x4A6694)) }
                c.px(x, 56 - h, C(0x86A2CC))
            }
        }
        c.oy = 0
    }

    /// A tentacle shooting out of the door, drawn straight onto the screen: its root at (`x`, `y`) in pixels, heading
    /// off at `angle` (0 straight down, negative to the left) and curling `curl` more at each segment, swaying with `t`,
    /// out `reach` of its full length (0 is back inside).
    private static func eterniaHouseTentacle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ floor: Int, _ q: Int, _ t: Double,
                                             reach: Double, angle: Double, curl: Double, seed: Int) {
        let n = Int((reach * 11).rounded())
        guard n >= 2 else { return }
        var px = Double(x), py = Double(y)
        var a = angle
        let step = Double(q) * 1.2
        for i in 0..<n {
            let sway: Double = 0.18 * sin(t * 1.3 + Double(seed) * 1.7 - Double(i) * 0.45)
            a += curl + sway * 0.4 + (i > n - 4 ? 0.45 * (angle < 0 ? 1 : -1) : 0)
            px += sin(a) * step; py += cos(a) * step
            if py > Double(floor) { py = Double(floor) }
            let r = max(1, Int((Double(q) * (1.2 - 0.9 * Double(i) / Double(n))).rounded()))
            c.circle(Int(px), Int(py), r, C(0x0C0A12))
            if r > 1 { c.px(Int(px) - r / 2, Int(py) - r / 2, C(0x3A3A5A)) }
        }
    }

    /// Shokoti's life: her eyes glowing white and dimming as she breathes; every ten seconds or so black tentacles
    /// shooting out of the door, grabbing at the sand and pulling back in, as they grabbed Stanlin; the wind blowing streaks of sand across the desert; and every so often
    /// the burst of light from the spire's middle, as when Masque raised it, flaring up and dying away.
    static func eterniaTempleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaTempleFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 14 : 5) * q
        // The wind blowing streaks of sand across the desert.
        for k in 0..<(tall ? 14 : 7) {
            let y = horizon + Int(noise(k + 960) * Double(max(1, g - horizon - 2 * q)))
            let speed = 20 + noise(k + 963) * 30
            let span = Double(c.w + 60 * s)
            let x = Int((noise(k + 961) * span + t * speed * Double(s)).truncatingRemainder(dividingBy: span)) - 30 * s
            let len = (10 + Int(noise(k + 962) * 16)) * s
            c.rect(x, y, len, max(1, s / 2), C(0xA8C0E0, 0.25)); c.rect(x + len / 3, y - max(1, s / 2), len / 2, max(1, s / 2), C(0xA8C0E0, 0.15))
        }
        // The tentacles, now and then: out fast, a grab at the sand, back in, one a moment behind the next. (The door's
        // units are moved down `drop` rows to the foot of the canvas.)
        let drop = f.rows - 56
        for (i, tn) in [(58, 53, -0.7, -0.10), (60, 53, 0.0, 0.02), (62, 53, 0.7, 0.09)].enumerated() {
            let ph = (t + 5 - Double(i) * 0.15).truncatingRemainder(dividingBy: 10.0)
            guard ph > 0, ph < 2.4 else { continue }
            let reach = ph < 0.5 ? ph / 0.5 : ph < 1.6 ? 1 : (2.4 - ph) / 0.8
            eterniaHouseTentacle(c, f.x + tn.0 * q, f.y + (tn.1 + drop) * q, f.base + 3 * q, q, t, reach: reach,
                                 angle: tn.2, curl: tn.3, seed: i)
        }
        // Her eyes.
        let breath = 0.6 + 0.4 * sin(t * 1.2)
        for e in eterniaShokotiEyes {
            let ex = f.x + e.x * q + q, ey = f.y + (e.y + drop) * q + q / 2
            let ex2 = ex - q / 2
            c.circle(ex2, ey, 3 * q, C(0xFFFFFF, 0.08 * breath)); c.circle(ex2, ey, 2 * q, C(0xFFF8F0, 0.16 * breath))
            c.rect(f.x + e.x * q, f.y + (e.y + drop) * q, q, q, C(0xFFFFFF, breath))
        }
        // The burst of light from the spire, every so often.
        let ph = t.truncatingRemainder(dividingBy: 14.0)
        if ph < 1.6 {
            let k = sin(ph / 1.6 * .pi)
            let bx = f.x + 60 * q, by = f.y + f.rows * 2 / 5 * q
            eterniaPlaces6Glow(c, bx, by, Int(Double(30 * q) * k) + 1, C(0xFFF0B0), peak: 0.5 * k)
            for r in 0..<18 {
                let ang = Double(r) / 18 * 2 * .pi + 0.2
                let len = Double(q) * (18 + noise(r + 990) * 22) * k
                for i in stride(from: Double(2 * q), to: len, by: max(1, Double(q) / 2)) {
                    let w = max(1, Int(Double(q) * 2.5 * (1 - i / len)))
                    c.rect(bx + Int(cos(ang) * i), by + Int(sin(ang) * i * 0.8), w, w, C(i < len / 2 ? 0xFFFFF0 : 0xFFD860, 0.7 * k))
                }
            }
        }
    }
}
