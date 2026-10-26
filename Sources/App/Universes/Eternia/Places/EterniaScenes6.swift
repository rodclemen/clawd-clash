import Foundation

// More places on Eternia: Mer-Clawd's undersea kingdom, Beast Island and the Temple of Shokoti, drawn the same way as
// EterniaScenes1.swift. Each landmark (the sunken arch and its drowned palace, the volcano, the pyramid and its idol)
// is drawn once at one pixel to a unit and blown up `q` times, so it's the whole picture on the screen saver and still
// fits the window's strip; the things round it (kelp and coral, twisted trees, stelae and braziers) stand out to the sides.
// Three palettes far apart: the sea's blues with coral pinks and violets, the island's fog greens and lava, and the
// desert's dusk, mauve shadow under an amber sky, with the idol in gold.

let eterniaScenes6: [Location: Place] = [
    .eterniaUndersea: Place(name: "Mer-Clawd's Undersea Kingdom", panel: 0x0A1A28, still: Scenes.eterniaUndersea,
                            moving: Scenes.eterniaUnderseaLife),
    .eterniaBeastIsland: Place(name: "Beast Island", panel: 0x121612, still: Scenes.eterniaBeastIsland,
                               moving: Scenes.eterniaBeastIslandLife),
    .eterniaTemple: Place(name: "The Temple of Shokoti", panel: 0x1C1420, still: Scenes.eterniaTemple,
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

// MARK: - The Temple of Shokoti

extension Scenes {
    /// Where things stand at the Temple of Shokoti: the pyramid and its idol are drawn at one pixel to a unit on a
    /// canvas of their own (`eterniaTempleArt`, 120×56) and blown up `q` times, its foot on `base`, the canvas's top
    /// left at `x`/`y`.
    static func eterniaTempleFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eterniaPlaces6Q(c, g)
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 60 * q, base - 56 * q)
    }

    /// The idol's eyes, in temple units: the left end of each, two units wide. They glow in the moving layer.
    private static let eterniaShokotiIdolEyes: [(x: Int, y: Int)] = [(57, 8), (62, 8)]
    /// The braziers either side of the idol, in temple units: the middle of each bowl's rim.
    private static let eterniaTempleBraziers: [(x: Int, y: Int)] = [(40, 16), (80, 16)]

    /// The stelae out on the sand either side, and the braziers on tall stands beside them: each stela's middle
    /// (`x`), the middle of its brazier's bowl (`bowl`), and the foot they stand on (`foot`).
    private static func eterniaTempleStelae(_ c: PixelCanvas, _ g: Int) -> [(x: Int, bowl: (x: Int, y: Int), foot: Int)] {
        let f = eterniaTempleFrame(c, g), q = f.q, foot = f.base + 2 * q
        return [(0.7, true), (0.3, false)].map { p in
            let x = eterniaPlaces6Side(c, f.x, q, p.0, left: p.1), bx = x + (p.1 ? 10 : -10) * q
            return (x, (bx, foot - 28 * q), foot)
        }
    }

    /// The Temple of Shokoti: a desert at dusk, the sun just gone down behind the temple and the sky banded from
    /// violet down to amber, wisps of rose cloud lit gold under. Far dunes and two little stepped temples on the
    /// horizon. The temple is a stepped pyramid of six tiers of sandstone in shadow against the glow, the treads lit by
    /// the sky, a carved band of glyphs and serpents round each tier, a stair up its middle between balustrades, each
    /// ending at the foot in a stone serpent's head, jaws wide. On its top platform, between two braziers, stands a
    /// great gold idol of Shokoti herself, arms raised as in her rite: her fan headdress of rays, a ruby on the brow
    /// band, her long hair and robe inlaid in black under the broad gold collar, catching the last of the light.
    /// Carved stelae stand either side, crowned with her fan of rays, a brazier on a tall bronze stand beside each, a
    /// great beast's skull lies half buried in the sand on the left, and the crew stands on sand gone mauve in the
    /// dusk. On the screen saver the pyramid stands three times the size, under the first stars and a thin moon.
    static func eterniaTemple(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaTempleFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 14 : 5) * q
        c.gradient(0, horizon, C(tall ? 0x0E0A28 : 0x4A2C5E), C(0xF2A458), bands: tall ? 14 : 7)
        c.rect(0, horizon, c.w, f.base - horizon, C(0xF2A458))
        // The glow where the sun went down, behind the pyramid, soft all the way out.
        eterniaPlaces6Glow(c, c.w / 2, horizon, 62 * q, C(0xFFD890), peak: 0.34)
        if tall {
            // The first stars, and a thin moon high on the right.
            c.stars(0, horizon * 45 / 100, density: 45, seed: 53)
            let mx = c.w * 80 / 100, my = horizon * 18 / 100, mr = 9 * s
            let sky = unpremultiplied(c, (max(0, my - mr / 4) * c.w + min(c.w - 1, mx + mr * 3)) * 4)
            c.circle(mx, my, mr * 2, C(0xFFF0D0, 0.06))
            c.circle(mx, my, mr, C(0xF4ECD4)); c.circle(mx + mr * 2 / 5, my - mr / 4, mr, sky)
        }
        // Wisps of cloud, rose, lit gold underneath.
        let wisps: [(x: Int, y: Int, len: Int)] = tall
            ? [(8, 50, 30), (60, 44, 36), (30, 62, 26), (78, 66, 22), (4, 76, 20)]
            : [(6, 24, 16), (68, 16, 18), (40, 40, 10)]
        for (k, w) in wisps.enumerated() {
            let x = c.w * w.x / 100, y = horizon * w.y / 100, len = w.len * s * (tall ? 2 : 1), th = max(1, s * (tall ? 2 : 1))
            c.rect(x, y, len, th, C(0xB06A86)); c.rect(x + len / 6, y - th, len / 2, th, C(0x8A5278))
            c.rect(x + len / 5, y + th, len * 3 / 5, th, C(0xF6B870)); c.rect(x + len * (k % 2 + 1) / 4, y + 2 * th, len / 5, th, C(0xFFD8A0, 0.6))
        }
        // The far dunes, dusky rose, and two little stepped temples on the horizon, their tiers lit along the top.
        for (frac, size) in [(0.12, 14), (0.86, 10)] {
            let px = Int(Double(c.w) * frac), h = size * s * (tall ? 2 : 1), step = max(1, h / 4)
            for i in 0..<h {
                let half = (i / step + 1) * step * 5 / 4
                c.rect(px - half, horizon - h + i, 2 * half + 1, 1, i < h / 3 ? C(0xA2647A) : C(0x9A5E74))
                if i % step == 0 { c.rect(px - half, horizon - h + i, 2 * half + 1, max(1, s), C(0xD08A80)) }
            }
        }
        c.dunes(base: horizon + s, amp: Double(3 * s), freq: 0.03 / Double(s), phase: 0.4, bottom: f.base, C(0x9A5E6E), shade: C(0xD08A7A))
        c.dunes(base: horizon + (tall ? 8 : 3) * s, amp: Double(2 * s), freq: 0.06 / Double(s), phase: 2.2, bottom: f.base,
                C(0x7A4A5C), shade: C(0xA06A6A))

        // The temple, blown up to size.
        let art = PixelCanvas(120, 56)
        eterniaTempleArt(art)
        eterniaPlaces6Blit(c, art, f.x, f.y, q)

        // The sand in front, gone mauve in the dusk, plain where the crew stands, ripples across it.
        c.gradient(f.base, g, C(0x6A4652), C(0x563A48), bands: 3)
        for k in 0..<(c.w / (10 * q) + 1) {
            let x = k * 10 * q + Int(noise(k + 950) * Double(6 * q)), y = f.base + q + Int(noise(k + 951) * Double(max(1, g - f.base - 2 * q)))
            c.rect(x, y, 4 * q, max(1, q / 2), C(0x7E5862))
        }
        // The stelae either side, a brazier on its tall stand beside each, and the beast's skull half buried on the left.
        for (i, st) in eterniaTempleStelae(c, g).enumerated() {
            let stela = PixelCanvas(16, 46)
            eterniaStela(stela, seed: i)
            eterniaPlaces6Blit(c, stela, st.x - 8 * q - q / 2, st.foot - 46 * q, q)
            let stand = PixelCanvas(9, 29)
            eterniaBrazierStand(stand)
            eterniaPlaces6Blit(c, stand, st.bowl.x - 4 * q, st.foot - 29 * q, q)
        }
        let skull = PixelCanvas(30, 14)
        eterniaSandSkull(skull)
        eterniaPlaces6Blit(c, skull, eterniaPlaces6Side(c, f.x, q, 0.25, left: true) - 15 * q, f.base + 2 * q - 14 * q, q)
        // Rocks scattered on the right.
        for (frac, w) in [(0.65, 5), (0.8, 3)] {
            let x = eterniaPlaces6Side(c, f.x, q, frac, left: false)
            c.rect(x, f.base - q, w * q, 2 * q, C(0x5A3C48)); c.rect(x + q, f.base - 2 * q, (w - 2) * q, q, C(0x7A5460))
        }
        c.ground(g, C(0x4E3644), edge: C(0x6E5058), speck: C(0x42303A), seed: 47)
    }

    /// A stela of Shokoti's cult, one pixel to a unit on a 16×46 canvas, its foot on row 45: a slab of sandstone in
    /// shadow, lit down its left edge by the glow, crowned with her fan of rays carved in the stone, their tips inlaid
    /// gold, round a gold half-sun with a ruby in it; down its face, between carved bands, the same rising sun cut
    /// small, its rays fanning up, on a stepped base. `seed` changes the carving a little.
    private static func eterniaStela(_ a: PixelCanvas, seed: Int) {
        let face = C(0x6A4448), faceD = C(0x4E3038), faceL = C(0x8A5E5C), rim = C(0xE09A78)
        let gold = C(0xE0B040), goldL = C(0xFFE08A), goldD = C(0x9A7020)
        /// A fan of rays rising from (`cx`, `cy`): `n` to a half turn, a solid hub out to `hub`, rays out to `reach`.
        func fan(_ cx: Double, _ cy: Double, n: Double, hub: Double, reach: Double, _ paint: (Int, Int, Double, Double) -> Px?) {
            for y in Int(cy - reach - 1)...Int(cy) {
                for x in Int(cx - reach - 1)...Int(cx + reach + 1) {
                    let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                    guard dy <= 0.5 else { continue }
                    let d = (dx * dx + dy * dy).squareRoot(), ph = frac((atan2(dy, dx) + .pi) / (.pi / n))
                    guard d <= hub || (ph > 0.25 && ph < 0.75 && d <= reach) else { continue }
                    if let col = paint(x, y, dx, d) { a.px(x, y, col) }
                }
            }
        }
        // The crown: long rays of lit stone, tipped gold, out of a gold half-sun with the ruby at its heart.
        fan(8.5, 12.5, n: 7, hub: 3.4, reach: 8) { _, _, dx, d in
            d <= 3.4 ? (dx < 0 ? goldL : gold) : d > 6.2 ? (dx < 0 ? goldL : gold) : dx < 0 ? faceL : face
        }
        a.px(8, 11, C(0xC8203A)); a.px(8, 10, C(0xFF7A8A)); a.px(10, 12, goldD)
        // The slab.
        for y in 13..<42 {
            a.rect(3, y, 11, 1, face); a.px(3, y, rim); a.px(4, y, faceL); a.px(13, y, faceD)
        }
        // Carved bands, and between them the rising sun cut small, its rays fanning up, a fleck of gold at its heart.
        for y in [14, 25, 36] { a.rect(4, y, 9, 1, faceD); a.rect(4, y + 1, 9, 1, faceL) }
        for (i, y0) in [23, 34].enumerated() {
            let y = y0 + (seed % 2 == 0 ? 0 : (i == 0 ? 0 : -1))
            a.rect(6, y, 5, 1, faceD); a.rect(6, y - 1, 5, 1, faceD); a.rect(7, y - 2, 3, 1, faceD)
            for deg in [22.0, 56, 90, 124, 158] {
                let ang = deg * .pi / 180
                for r in stride(from: 3.2, through: deg == 90 ? 6.2 : 4.8, by: 0.5) {
                    a.px(8 + Int((cos(ang) * r).rounded()), y - Int((sin(ang) * r).rounded()), faceD)
                }
            }
            a.px(8, y - 1, gold); a.px(8, y, goldD)
        }
        // The stepped base.
        a.rect(2, 42, 13, 2, faceD); a.rect(2, 42, 13, 1, faceL); a.px(2, 42, rim)
        a.rect(1, 44, 15, 2, faceD); a.rect(1, 44, 15, 1, C(0x7A5052)); a.px(1, 44, rim)
    }

    /// A brazier on a tall bronze stand, one pixel to a unit on a 9×29 canvas, its foot on row 28: a wide bowl lit
    /// along its rim, a slender stem with a knot in it, and three splayed feet. The fire burns in the moving layer.
    private static func eterniaBrazierStand(_ a: PixelCanvas) {
        let b = C(0x9A7038), bL = C(0xE0A860), bD = C(0x5A3E20)
        a.pattern(0, 1, ["BBBBBBBBB", ".BBBBBBB.", "..BBBBB..", "...DBD..."], ["B": b, "D": bD])
        a.rect(0, 1, 4, 1, bL); a.px(1, 2, bL)
        a.rect(0, 0, 9, 1, C(0x3A1A0E))   // the coals
        for y in 5..<24 { a.px(4, y, y % 6 == 0 ? bL : b); a.px(5, y, bD) }
        a.rect(3, 13, 3, 2, b); a.px(3, 13, bL)
        a.pattern(0, 24, ["...BBB...", "..B.B.B..", ".B..B..B.", "B...B...D", "B...B...D"], ["B": b, "D": bD])
    }

    /// A great beast's skull half buried in the sand, one pixel to a unit on a 30×14 canvas: bleached bone gone pink in
    /// the dusk, a deep round socket under a heavy brow, a long snout with a nostril, a row of teeth and a horn curling
    /// back.
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
        ], ["B": C(0xD4B0A8), "L": C(0xF0D8C8), "D": C(0x7A5458), "K": C(0x2A1820), "N": C(0x5A3A40),
            "T": C(0xF0D8C8), "h": C(0xC09888), "H": C(0x8A6A64), "S": C(0x6A4652)])
        for x in 13..<26 { a.px(x, 9 - (x > 20 ? 1 : 0), C(0xE8CCC0)) }
    }

    /// The idol of Shokoti, gold, standing on its plinth on the temple's top platform (rows 0 to 19, centred on 60):
    /// her fan headdress spreading wide behind her head, a burst of long gold rays lit white-gold at their tips out of
    /// a solid gold half-disc, a gold band across her brow with the ruby in it; a stern gold face, the eyes deep (they
    /// glow in the moving layer); her long hair down either side and her robe inlaid in black, a broad beaded gold
    /// collar over her shoulders and a gold panel down the robe's front; both arms raised high in her rite, black
    /// sleeves to gold cuffs, her gold hands open to the sky.
    private static func eterniaShokotiIdol(_ c: PixelCanvas) {
        let gold = [C(0x5A3A10), C(0x8A5A18), C(0xB88428), C(0xE0B040), C(0xF6D870), C(0xFFF0B0)]
        let onyx = C(0x16121C), onyxL = C(0x3E3448), ruby = C(0xD0203A), rubyL = C(0xFF8090)
        // The fan of rays, half as wide again as it is tall, so it spreads out past her hair either side.
        let cx = 60.5, cy = 10.0
        for y in 0...10 {
            for x in 44...76 {
                let dx = (Double(x) + 0.5 - cx) / 1.35, dy = Double(y) + 0.5 - cy
                guard dy <= 0.5 else { continue }
                let d = (dx * dx + dy * dy).squareRoot()
                let ph = frac((atan2(dy, dx) + .pi) / (.pi / 11))
                let ray = ph > 0.22 && ph < 0.78
                if d <= 6.2 {
                    c.px(x, y, d > 5.2 ? gold[2] : dx < 0 ? gold[3] : gold[2])
                } else if ray && d <= 10.6 {
                    c.px(x, y, d > 9.0 ? gold[5] : dx < 0 ? gold[4] : gold[3])
                }
            }
        }
        // The arms, raised high out to either side: black sleeves, gold cuffs, gold hands open to the sky.
        /// A pixel on her left (lit) and its mirror on her right (in shade).
        func both(_ x: Int, _ y: Int, _ l: Px, _ r: Px) { c.px(x, y, l); c.px(120 - x, y, r) }
        for k in 0...8 {
            let x = 54 - 10 * k / 8, y = 14 - 9 * k / 8
            for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] { both(x + dx, y + dy, onyx, onyx) }
            if k % 2 == 0 { both(x, y, onyxL, onyx) }
        }
        both(43, 6, gold[4], gold[3]); both(44, 6, gold[3], gold[2])
        for y in 3...5 { both(43, y, gold[4], gold[3]); both(44, y, gold[3], gold[2]) }
        both(42, 5, gold[4], gold[2])                                   // the thumbs
        both(43, 2, gold[5], gold[4]); both(44, 2, gold[4], gold[3])    // the fingertips
        // Her long hair, black, down either side of the face to the collar, in strands; and over the crown.
        c.rect(57, 4, 7, 1, onyx); c.rect(56, 5, 9, 1, onyx)
        for x in [54, 55, 65, 66] {
            for y in 6...14 { c.px(x, y, (x == 55 || x == 66) && y % 3 == 1 ? onyxL : onyx) }
        }
        c.px(58, 4, onyxL); c.px(61, 5, onyxL)
        // The gold band across her brow, the ruby in it.
        c.rect(55, 6, 11, 1, gold[4]); c.px(55, 6, gold[5]); c.px(65, 6, gold[2])
        c.px(60, 6, ruby); c.px(60, 5, rubyL)
        // The face: gold, lit from the left, deep eyes under gold lids, a stern straight mouth.
        for y in 7...11 {
            let l = y == 11 ? 57 : 56, r = y == 11 ? 63 : 64
            for x in l...r { c.px(x, y, x < 59 ? gold[4] : x < 62 ? gold[3] : gold[2]) }
        }
        c.px(56, 7, gold[5])
        for e in eterniaShokotiIdolEyes {
            c.rect(e.x, e.y, 2, 1, C(0x2A1606)); c.rect(e.x - (e.x < 60 ? 1 : 0), e.y - 1, 3, 1, gold[1])
        }
        c.px(60, 9, gold[2]); c.rect(59, 10, 3, 1, gold[1])
        // The broad gold collar over her shoulders, a row of beads round it.
        c.rect(56, 12, 9, 1, gold[4]); c.rect(54, 13, 13, 1, gold[3]); c.rect(53, 14, 15, 1, gold[2])
        for x in stride(from: 54, through: 66, by: 2) { c.px(x, 13, gold[5]) }
        c.px(53, 14, gold[4]); c.rect(56, 12, 2, 1, gold[5])
        // The robe, black, flaring to her feet, a gold panel down its front, folds lit either side.
        for y in 15...17 {
            let l = 54 - (y - 15), r = 66 + (y - 15)
            c.rect(l, y, r - l + 1, 1, onyx); c.px(l, y, onyxL)
            c.px(57, y, onyxL); c.px(63, y, onyxL)
            c.rect(59, y, 3, 1, y % 2 == 0 ? gold[3] : gold[2]); c.px(59, y, gold[4])
        }
        // The plinth.
        c.rect(49, 18, 23, 2, gold[2]); c.rect(49, 18, 23, 1, gold[5]); c.rect(71, 18, 1, 2, gold[0])
        for x in stride(from: 52, through: 68, by: 4) { c.px(x, 19, gold[1]) }
    }

    /// The temple itself, one pixel to a unit on a 120×56 canvas, its foot on row 55: six tiers of sandstone, the
    /// stair up the middle, the braziers and the idol on top.
    static func eterniaTempleArt(_ c: PixelCanvas) {
        // Sandstone in shadow, six tones, darkest first; the treads catch the sky's glow.
        let tone = [C(0x2A1A26), C(0x3E2832), C(0x54363E), C(0x6C4846), C(0x8E6052), C(0xC08A6C)]
        let rim = C(0xF0B080)
        // The tiers, bottom first: each 6 rows, 6 in from the one under it on either side.
        for i in 0..<6 {
            let top = 50 - 6 * i, hw = 54 - 6 * i
            for y in top..<(top + 6) {
                for x in (60 - hw)...(60 + hw) {
                    let n = Double(x - 60) / Double(hw)
                    c.px(x, y, eterniaPlaces6Tone(tone, 0.5 - 0.18 * n - Double(y - top) * 0.02, x, y, grain: 0.18))
                }
                c.px(60 - hw, y, tone[4]); c.px(60 + hw, y, tone[0])
            }
            // The tread on top, lit by the glow; the shadow under its lip.
            c.rect(60 - hw, top, hw * 2 + 1, 1, tone[5]); c.px(60 - hw, top, rim)
            c.rect(60 - hw, top + 1, hw * 2 + 1, 1, tone[1])
            // The carved band round it: glyph blocks on the even tiers, a zigzag serpent on the odd.
            let band = top + 3
            if i % 2 == 0 {
                for x in stride(from: 60 - hw + 3, to: 60 + hw - 3, by: 5) {
                    c.rect(x, band - 1, 3, 2, tone[1]); c.px(x + 1, band - 1, tone[3]); c.px(x, band + 1, tone[3])
                }
            } else {
                for x in (60 - hw + 2)...(60 + hw - 2) {
                    let zz = (x / 2) % 2 == 0 ? 0 : 1
                    c.px(x, band - 1 + zz, tone[1]); c.px(x, band + zz, tone[3])
                }
            }
        }
        // The stair up the middle: treads lit, risers in shade, between balustrades.
        for y in 20..<56 {
            c.rect(53, y, 15, 1, y % 2 == 0 ? tone[4] : tone[2])
            c.px(53, y, tone[5])
        }
        c.rect(51, 20, 2, 36, tone[3]); c.rect(51, 20, 1, 36, tone[5])
        c.rect(68, 20, 2, 36, tone[1]); c.rect(69, 20, 1, 36, tone[0])
        // A stone serpent's head at the foot of each balustrade, rearing out sideways in profile: a long wedge of a
        // head, a ridge over the eye, jaws gaping on two fangs, a forked tongue out, its neck coming down off the rail.
        let snake: [Character: Px] = ["S": tone[4], "s": tone[3], "d": C(0x1E121A), "K": C(0x140A10), "F": C(0xF4E4C8),
                                      "L": tone[5], "E": C(0xF0B040), "T": C(0xD0303A)]
        let head = [
            "..........dddd..",
            "........ddLLSSd.",
            "......ddLLSSSSSd",
            "....ddLLSdESSSSd",
            "..ddLLSSSSSSSSSd",
            "TdLSSSSSSSSSSSSd",
            ".TTFKKKKdSSSSSSd",
            "T..KKKFKdsSSSSSd",
            "..dsssssssSSSSSd",
            "....ddsssssSSSSd",
            "......ddddsssssd",
        ]
        c.pattern(36, 45, head, snake)
        c.pattern(68, 45, head.map { String($0.reversed()) }, snake)
        // The platform on top, the braziers on it: bronze bowls on legs.
        c.rect(34, 19, 53, 1, tone[5])
        for b in eterniaTempleBraziers {
            c.pattern(b.x - 3, b.y, ["BBBBBBB", ".BBBBB.", "..DBD..", ".D...D."], ["B": C(0x9A7038), "D": C(0x5A3E20)])
            c.px(b.x - 3, b.y, C(0xE0A860))
        }
        // The idol.
        eterniaShokotiIdol(c)
    }

    /// A brazier's fire, its bowl's rim middle at (`x`, `y`): flames flickering up out of it, a glow round them.
    private static func eterniaTempleFire(_ c: PixelCanvas, _ x: Int, _ y: Int, _ q: Int, _ t: Double, seed: Int) {
        let flick = noise(Int(t * 8) * 5 + seed * 17)
        let h = (3 + Int(flick * 2.5)) * q
        c.circle(x + q / 2, y - h / 2, h, C(0xFFA040, 0.12))
        c.rect(x - 2 * q, y - h / 2, 5 * q, h / 2, C(0xE0601A))
        c.rect(x - q, y - h, 3 * q, h, C(0xF09A30))
        c.rect(x, y - h + q, q, h - q, C(0xFFE08A))
        c.rect(x + (flick > 0.5 ? q : -q), y - h - q, q, q, C(0xF09A30))
    }

    /// Shokoti's life: heat still shimmering off the sand in wavering streaks of light, the braziers' flames
    /// flickering on the platform and on their stands, and the idol's eyes glowing gold for a few seconds, going dark,
    /// glowing again. On the screen saver a shooting star now and then.
    static func eterniaTempleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaTempleFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 14 : 5) * q
        // Heat shimmer: thin streaks of light wavering over the far dunes and the sand.
        for k in 0..<(tall ? 14 : 7) {
            let y = horizon - q + Int(noise(k + 960) * Double(max(1, g - horizon - 2 * q)))
            let x = Int(noise(k + 961) * Double(c.w)) + Int(sin(t * 1.8 + Double(k) * 1.3) * Double(5 * q))
            let a = 0.10 + 0.06 * sin(t * 3.1 + Double(k))
            let len = (14 + Int(noise(k + 962) * 18)) * q
            c.rect(x, y, len, max(1, q / 2), C(0xFFE0B0, a))
            c.rect(x + len / 4 + Int(sin(t * 2.6 + Double(k)) * Double(2 * q)), y - max(1, q / 2) - q / 2, len / 2, max(1, q / 2), C(0xFFE0B0, a * 0.7))
        }
        // The braziers' flames, on the platform and on the stands.
        for (i, b) in eterniaTempleBraziers.enumerated() {
            eterniaTempleFire(c, f.x + b.x * q, f.y + b.y * q, q, t, seed: i)
        }
        for (i, st) in eterniaTempleStelae(c, g).enumerated() {
            eterniaTempleFire(c, st.bowl.x, st.bowl.y + q, q, t, seed: i + 2)
        }
        // The idol's eyes.
        if t.truncatingRemainder(dividingBy: 5.0) < 3.2 {
            let pulse = 0.6 + 0.4 * sin(t * 4)
            for e in eterniaShokotiIdolEyes {
                let px = f.x + e.x * q + q, py = f.y + e.y * q + q / 2
                c.circle(px, py, 4 * q, C(0xFFD040, 0.10 * pulse)); c.circle(px, py, 2 * q, C(0xFFE070, 0.22 * pulse))
                c.rect(f.x + e.x * q, f.y + e.y * q, 2 * q, q, C(0xFFF4B0))
            }
        }
        // A shooting star, now and then, on the screen saver.
        if tall {
            let period = 9.0, ph = t.truncatingRemainder(dividingBy: period)
            if ph < 0.8 {
                let k = ph / 0.8, x0 = c.w * 20 / 100 + Int(noise(Int(t / period) + 970) * Double(c.w / 2)), y0 = horizon / 8
                let x = x0 + Int(k * Double(40 * s)), y = y0 + Int(k * Double(14 * s))
                for i in 0..<(12 * s) { c.px(x - i, y - i * 14 / 40, C(0xFFFFFF, 0.8 * (1 - Double(i) / Double(12 * s)))) }
            }
        }
    }
}
