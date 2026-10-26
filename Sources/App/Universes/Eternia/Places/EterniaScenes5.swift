import Foundation

// More places on Eternia: the bee people's hive at Andreenos, Granamyr's black cliffs at Darksmoke and Orkko's home
// moon of Trolla, drawn the way Castle Greyskull is. The big thing in each (the hive, the cliffs, the village) is
// drawn once at one pixel to a unit on a canvas of its own and blown up `q` times: once in the window, three times or
// more on the screen saver, where it fills the picture. Three palettes far apart: Andreenos's gold and meadow green,
// Darksmoke's smoke and ember, Trolla's violet night and pastel domes.

let eterniaScenes5: [Location: Place] = [
    .eterniaAndreenos: Place(name: "Andreenos", panel: 0x1E1608, still: Scenes.eterniaAndreenos,
                             moving: Scenes.eterniaAndreenosLife),
    .eterniaDarksmoke: Place(name: "Darksmoke", panel: 0x16121A, still: Scenes.eterniaDarksmoke,
                             moving: Scenes.eterniaDarksmokeLife),
    .eterniaTrolla: Place(name: "Trolla", panel: 0x160E2A, still: Scenes.eterniaTrolla,
                          moving: Scenes.eterniaTrollaLife),
]

// MARK: - Shared

/// How many times the big things are blown up: once in the window, growing with the screen saver (as Greyskull).
private func eternia5Scale(_ c: PixelCanvas, _ g: Int) -> Int { max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120))) }

/// Paints `src` onto `c` blown up `q` times, its top left at (x, y), skipping rows off the picture.
private func eternia5BlowUp(_ c: PixelCanvas, _ src: PixelCanvas, _ x: Int, _ y: Int, _ q: Int) {
    for yy in 0..<src.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
        for xx in 0..<src.w where src.buf[(yy * src.w + xx) * 4 + 3] > 0 {
            c.rect(x + xx * q, y + yy * q, q, q, unpremultiplied(src, (yy * src.w + xx) * 4))
        }
    }
}

/// A tone out of `tones` (darkest first) for a brightness `v` of 0...1, dithered by position so the tones blend.
private func eternia5Dither(_ tones: [Px], _ v: Double, _ x: Int, _ y: Int, grain: Double = 0.26) -> Px {
    let n = (noise(x * 7 + y * 131) - 0.5) * grain
    let i = Int((v + n) * Double(tones.count))
    return tones[max(0, min(tones.count - 1, i))]
}

/// String art drawn `b` pixels to a character, mirrored when `flip` is set, for the little things that fly about.
private func eternia5Pattern(_ c: PixelCanvas, _ x: Int, _ y: Int, _ b: Int, _ rows: [String], _ pal: [Character: Px],
                             flip: Bool = false) {
    for (r, row) in rows.enumerated() {
        let n = row.count
        for (k, ch) in row.enumerated() {
            guard let col = pal[ch] else { continue }
            c.rect(x + (flip ? n - 1 - k : k) * b, y + r * b, b, b, col)
        }
    }
}

/// The rows a polygon through `pts` covers, from `y0` to `y1`: calls `span` with each row and the first and last
/// pixel whose middle is inside it.
private func eternia5Spans(_ pts: [(Double, Double)], _ y0: Int, _ y1: Int, _ span: (Int, Int, Int) -> Void) {
    guard pts.count > 2 else { return }
    let ys = pts.map(\.1)
    let top = max(y0, Int(ys.min()!.rounded(.down))), bottom = min(y1, Int(ys.max()!.rounded(.up)))
    guard top <= bottom else { return }
    for y in top...bottom {
        let cy = Double(y) + 0.5
        var xs: [Double] = []
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if (a.1 <= cy) != (b.1 <= cy) { xs.append(a.0 + (cy - a.1) / (b.1 - a.1) * (b.0 - a.0)) }
        }
        xs.sort()
        var i = 0
        while i + 1 < xs.count {
            let xa = Int((xs[i] - 0.5).rounded(.up)), xb = Int((xs[i + 1] - 0.5).rounded(.down))
            if xb >= xa { span(y, xa, xb) }
            i += 2
        }
    }
}

/// Fills the polygon through `pts` on `c` in `col`.
private func eternia5Fill(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    eternia5Spans(pts, 0, c.h - 1) { y, xa, xb in c.rect(xa, y, xb - xa + 1, 1, col) }
}

/// A little four-pointed twinkle at (x, y), its arms `r` long, `t` thick.
private func eternia5Twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ t: Int, _ col: Px) {
    c.rect(x - r, y, 2 * r + t, t, col); c.rect(x, y - r, t, 2 * r + t, col)
    c.rect(x, y, t, t, C(0xFFFFFF, Double(col.a) / 255))
}

// MARK: - Andreenos

extension Scenes {
    /// Where the hive stands at Andreenos, shared by the still picture and the moving layer: drawn at one pixel to a
    /// unit on a 120×72 canvas (`eterniaAndreenosHive`) and blown up `q` times, its foot on `base`, its canvas's top
    /// left at `x`/`y`. It's taller than the window's strip, so there its crown is out of sight above; the screen
    /// saver shows every tier rising.
    static func eterniaAndreenosFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eternia5Scale(c, g)
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 60 * q, base - 71 * q)
    }

    /// The hive's tiers, lowest first, in hive units: each band's top row, the row under it and its half width.
    private static let eterniaHiveTiers: [(top: Int, bottom: Int, hw: Int)] = [
        (57, 72, 50), (44, 58, 42), (32, 45, 34), (21, 33, 26), (11, 22, 18),
    ]
    /// Where honey hangs from the hive's eaves, in hive units: each drip's top and how far it runs down.
    private static let eterniaHiveDrips: [(x: Int, y: Int, len: Int)] = [
        (24, 57, 4), (33, 57, 2), (47, 58, 3), (79, 58, 5), (90, 57, 2), (30, 44, 3), (41, 45, 2), (73, 45, 4),
        (86, 44, 2), (38, 32, 3), (69, 33, 2), (80, 32, 3), (46, 21, 2), (72, 22, 3), (55, 11, 2),
    ]

    /// Andreenos, the city of the bee people: a golden afternoon, a blue sky going to honey-coloured haze at the
    /// horizon, soft clouds lit gold underneath, green hills far off with giant flowers standing up out of them.
    /// The hive is a great skep of wax, five tiers each narrower than the one under it, every band rounded and lit
    /// from the left, rows of hexagonal cells round it (some capped, some brimming with honey, some dark and empty),
    /// round doorways with landing ledges for the fliers, honey dripping from the eaves, a grand hexagonal door at the
    /// foot glowing amber. Giant flowers stand either side in the meadow the crew stands on. On the screen saver the
    /// hive stands three times the size and its tiers rise to a crown under the sun.
    static func eterniaAndreenos(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaAndreenosFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 22 : 8) * q
        c.gradient(0, f.base, C(0x3C6EA8), C(0xF2CC80), bands: tall ? 12 : 8)
        // The sun, high on the left, in rings of warm light.
        let sun = (x: c.w * (tall ? 14 : 6) / 100, y: tall ? horizon * 18 / 100 : 4 * s, r: (tall ? 12 : 7) * s)
        for (k, a) in [(2.8, 0.10), (2.0, 0.16), (1.4, 0.26)] { c.circle(sun.x, sun.y, Int(Double(sun.r) * k), C(0xFFF0B0, a)) }
        c.circle(sun.x, sun.y, sun.r, C(0xFFF4C8)); c.circle(sun.x - sun.r / 4, sun.y - sun.r / 4, sun.r * 2 / 3, C(0xFFFCE8))
        // Fair-weather clouds, cream on top and gold underneath.
        let puffs: [(x: Int, y: Int, r: Int)] = tall
            ? [(30, 14, 7), (78, 10, 8), (60, 30, 6), (8, 40, 5), (90, 44, 6), (40, 52, 4)]
            : [(26, 18, 3), (72, 10, 3), (92, 30, 2)]
        for (k, p) in puffs.enumerated() {
            cloud(c, c.w * p.x / 100, horizon * p.y / 100, p.r * s, seed: k + 3, top: C(0xFFF6E0), base: C(0xF0C878))
        }
        // The far hills, the nearer greener, giant flowers standing out of them small with distance.
        c.dunes(base: horizon, amp: Double((tall ? 6 : 3) * s), freq: 0.04 / Double(s), phase: 1.2, bottom: f.base,
                C(0x8AA864), shade: C(0xA4C078))
        for k in 0..<(c.w / (14 * s) + 1) {
            let x = k * 14 * s + Int(noise(k + 500) * Double(8 * s)), h = (6 + Int(noise(k + 510) * 8)) * s * (tall ? 2 : 1)
            let top = horizon + (tall ? 6 : 2) * s - h, r = (2 + Int(noise(k + 520) * 2)) * s * (tall ? 2 : 1) / 2 + s
            c.rect(x, top, max(1, s), h, C(0x6E9058))
            c.circle(x, top, r, noise(k + 530) > 0.5 ? C(0xD49ACC) : C(0xF0B888)); c.circle(x, top, max(1, r / 3), C(0xB08040))
        }
        c.dunes(base: horizon + (tall ? 10 : 4) * s, amp: Double(3 * s), freq: 0.07 / Double(s), phase: 3.0, bottom: f.base,
                C(0x5E7E44), shade: C(0x76964E))

        // The hive, blown up to size.
        let hive = PixelCanvas(120, 72)
        eterniaAndreenosHive(hive, fine: tall)
        eternia5BlowUp(c, hive, f.x, f.y, q)

        // The meadow in front: deep green, plain and dark where the crew stands, a worn path from the door.
        c.gradient(f.base + q, g, C(0x4C622E), C(0x3A4C24), bands: 3)
        let doorW = 14 * q, doorX = f.x + 60 * q
        for y in (f.base + q)..<g {
            let k = Double(y - f.base) / Double(max(1, g - f.base)), w = Int(Double(doorW) * (1 + 0.8 * k))
            c.rect(doorX - w / 2, y, w, 1, (y - f.base) / max(1, q * 2) % 2 == 0 ? C(0x6A5A30) : C(0x5E5028))
        }
        // Giant flowers either side, the nearer bigger.
        let flowers: [(x: Int, h: Int, r: Int, petal: [Px])] = [
            (5, 50, 9, [C(0x7A2E7A), C(0xA4489C), C(0xCE72C0)]), (15, 34, 6, [C(0xA44A1E), C(0xD87432), C(0xF4A04E)]),
            (86, 36, 6, [C(0x2E5A9A), C(0x4A80C4), C(0x7AA8E4)]), (96, 52, 10, [C(0x9A2A44), C(0xC84866), C(0xEC7A8E)]),
        ]
        for (k, fl) in flowers.enumerated() {
            eterniaAndreenosFlower(c, c.w * fl.x / 100, g + q, fl.h * q, fl.r * q, q, fl.petal, seed: k)
        }
        c.ground(g, C(0x3A4822), edge: C(0x56682E), speck: C(0x2C3818), seed: 37)
    }

    /// A giant flower standing in the meadow, its foot at (`x`, `foot`): a stem `h` tall with two leaves, a head of
    /// eight petals `r` across round a dark seed disc, the petals in `petal`'s three tones (darkest first).
    private static func eterniaAndreenosFlower(_ c: PixelCanvas, _ x: Int, _ foot: Int, _ h: Int, _ r: Int, _ q: Int,
                                               _ petal: [Px], seed: Int) {
        let sw = max(2, q * 2), top = foot - h
        c.rect(x - sw / 2, top, sw, h, C(0x3E6A2A)); c.rect(x - sw / 2, top, max(1, sw / 2), h, C(0x5E8E3A))
        // Two broad leaves, out either side of the stem and curving up, lit on their upper halves, a dark midrib.
        for (k, side) in [(0.58, -1.0), (0.76, 1.0)] {
            let p = (Double(x) + side * Double(sw) / 2, Double(top) + Double(h) * k)
            let len = Double(r) * 2.1, wid = Double(r) * 0.62
            // Out along the leaf (`a`, 0 at the stem, 1 at the tip) and across it (`b`, plus on its upper side).
            let along = (side * 0.86, -0.5), up = (side * along.1, -side * along.0)
            func pt(_ a: Double, _ b: Double) -> (Double, Double) {
                (p.0 + along.0 * len * a + up.0 * wid * b, p.1 + along.1 * len * a + up.1 * wid * b)
            }
            let tip = pt(1, -0.15)
            eternia5Fill(c, [p, pt(0.25, 0.75), pt(0.55, 0.8), pt(0.8, 0.5), tip, pt(0.6, 0.05), pt(0.3, 0.05)], C(0x6AA040))
            eternia5Fill(c, [p, pt(0.3, 0.05), pt(0.6, 0.05), tip, pt(0.75, -0.45), pt(0.45, -0.7), pt(0.2, -0.55)], C(0x3E7028))
            let n = max(2, Int(len))
            for i in 0...n {
                let m = pt(Double(i) / Double(n) * 0.95, 0.02 - Double(i) / Double(n) * 0.15)
                c.rect(Int(m.0), Int(m.1), max(1, q / 2), max(1, q / 2), C(0x2E5A20))
            }
        }
        // The head: petals round the disc, the far ones darker, each lit along its upper edge.
        for i in 0..<8 {
            let a = Double(i) / 8 * 2 * .pi + Double(seed) * 0.4
            let px = x + Int(cos(a) * Double(r) * 0.62), py = top + Int(sin(a) * Double(r) * 0.62)
            let pr = max(2, r * 5 / 12)
            c.circle(px, py, pr, sin(a) > 0.3 ? petal[0] : petal[1])
            c.circle(px - pr / 4, py - pr / 4, max(1, pr / 2), petal[2])
        }
        let dr = max(2, r * 4 / 11)
        c.circle(x, top, dr, C(0x4A2C10)); c.circle(x - dr / 4, top - dr / 4, max(1, dr * 2 / 3), C(0x6A4418))
        for i in 0..<5 {
            let a = Double(i) * 1.3 + Double(seed)
            c.rect(x + Int(cos(a) * Double(dr) * 0.5), top + Int(sin(a) * Double(dr) * 0.5), max(1, q / 2), max(1, q / 2), C(0xE0B040))
        }
    }

    /// The hive itself, one pixel to a unit on a 120×72 canvas, its foot on row 71: five rounded tiers of wax, a crown
    /// on top, rows of cells (two to a tier when it's blown up big, `fine`, one in the window where more would be busy),
    /// doorways with ledges, the grand door at the foot and honey hanging from the eaves.
    static func eterniaAndreenosHive(_ c: PixelCanvas, fine: Bool) {
        // Wax in six tones, darkest first; honey in three; the dark of an empty cell or a doorway.
        let wax = [C(0x3A2208), C(0x5C3810), C(0x82561A), C(0xA87426), C(0xCC9838), C(0xEAC062)]
        let honey = [C(0xB86A10), C(0xE09A22), C(0xFFD060)], deep = C(0x1E0E02)
        let tiers = eterniaHiveTiers

        // The crown: a small dome on top, a knob of honey-gold wax at its tip.
        for y in 3..<12 {
            let k = Double(11 - y) / 9, half = Int((11 * (1 - k * k).squareRoot()).rounded())
            for x in (60 - half)...(59 + half) {
                let n = (Double(x) - 59.5) / Double(max(1, half))
                c.px(x, y, eternia5Dither(wax, 0.62 - 0.4 * n + k * 0.15, x, y))
            }
        }
        c.rect(58, 0, 4, 3, wax[4]); c.rect(58, 0, 1, 3, wax[5]); c.rect(61, 0, 1, 3, wax[2]); c.rect(59, 3, 2, 1, wax[1])

        // The tiers, the highest first so each lower band's top lip sits over the one above's foot. Each is rounded
        // like a coil of a skep: widest in its middle, lit along its top, dark under its lip.
        for (i, tier) in tiers.enumerated().reversed() {
            let rows = tier.bottom - tier.top
            for y in tier.top..<tier.bottom {
                let k = (Double(y - tier.top) + 0.5) / Double(rows), bulge = sin(k * .pi)
                let half = Double(tier.hw) - 3 + 3 * bulge
                // The lowest band is in the hive's own shade, so the crew reads in front of it.
                let lift = (0.5 - k) * 0.34 + (i == 0 ? -0.14 : 0)
                for x in Int((59.5 - half).rounded())...Int((59.5 + half).rounded()) {
                    let n = (Double(x) - 59.5) / half
                    c.px(x, y, eternia5Dither(wax, 0.56 - 0.36 * n + lift, x, y, grain: 0.18))
                }
                // The band's left rim caught by the sun, its right in shadow.
                c.px(Int((59.5 - half).rounded()), y, k < 0.8 ? wax[4] : wax[2])
                c.px(Int((59.5 + half).rounded()), y, wax[0])
            }
            // A dark seam under the band, where it sits on the one below.
            let hw = tier.hw - 3
            c.rect(60 - hw, tier.bottom - 1, hw * 2, 1, wax[1])
            c.rect(60 - hw + 2, tier.top, hw * 2 - 6, 1, wax[5])

            // The cells: a honeycomb band round its middle, in two staggered rows, fading out where the band curves
            // away at the sides. The lowest band has only a few, low down either side of the door.
            guard i > 0 else { continue }
            for row in 0..<(fine ? 2 : 1) {
                let cy = tier.top + 2 + row * 3
                guard cy + 4 < tier.bottom else { continue }
                for cx in stride(from: 60 - hw + 3 + row * 3, to: 60 + hw - 6, by: 6) {
                    let pick = noise(cx * 17 + cy * 5 + i)
                    // Capped wax mostly, honey in some, an empty one now and then; ringed in a tone just darker than
                    // the band, so the comb reads as a texture, not a row of holes.
                    let fill: Px = pick < 0.6 ? wax[4] : pick < 0.92 ? honey[1] : wax[1]
                    c.pattern(cx, cy, [".RRR.", "RCCCR", "RCCCR", ".RRR."], ["R": wax[2], "C": fill])
                    if pick < 0.6 { c.px(cx + 1, cy + 1, wax[5]) } else if pick < 0.92 { c.px(cx + 1, cy + 1, honey[2]) }
                }
            }
        }
        // A few cells low on the bottom band, either side of the door, in shade.
        for cx in [26, 32, 38, 78, 84, 90] {
            let cy = 62 + (cx / 6) % 2 * 3
            c.pattern(cx, cy, [".RRR.", "RCCCR", "RCCCR", ".RRR."], ["R": wax[0], "C": cx % 12 == 2 ? honey[0] : wax[2]])
        }

        // Doorways on the upper tiers: round, dark inside with a glow of honey low down, a ledge of wax under each
        // for the fliers to land on.
        for (x, y) in [(37, 49), (82, 49), (47, 37), (72, 37), (60, 25), (44, 26)] {
            c.ellipse(x, y, 3, 3, wax[1])
            c.ellipse(x, y, 2, 2, deep); c.rect(x - 1, y + 1, 3, 1, honey[0])
            c.rect(x - 4, y + 3, 9, 1, wax[5]); c.rect(x - 3, y + 4, 7, 1, wax[2]); c.px(x - 4, y + 4, wax[1])
        }

        // The grand door at the foot: a hexagon of thick wax, dark inside with the amber glow of the halls beyond.
        c.pattern(51, 56, [
            "....FFFFFFFFFF....",
            "...FFDDDDDDDDFF...",
            "..FFDDDDDDDDDDFF..",
            ".FFDDDDDDDDDDDDFF.",
            "FFDDDDDDDDDDDDDDFF",
            "FFDDDDDDDDDDDDDDFF",
            "FFDDDDDDDDDDDDDDFF",
            "FFDDDDGGGGGGDDDDFF",
            "FFDDDGGGGGGGGDDDFF",
            "FFDDGGGGHHGGGGDDFF",
            "FFDDGGGHHHHGGGDDFF",
            "FFDGGGGHHHHGGGGDFF",
            "FFDGGGGHHHHGGGGDFF",
            "FFDGGGGHHHHGGGGDFF",
            "FFDGGGGHHHHGGGGDFF",
            "FFDDGGGHHHHGGGDDFF",
        ], ["F": wax[4], "D": deep, "G": honey[0], "H": honey[1]])
        c.rect(51, 60, 1, 12, wax[5]); c.rect(68, 60, 1, 12, wax[2])

        // Honey hanging from the eaves: amber runs ending in a fat drop.
        for d in eterniaHiveDrips {
            c.rect(d.x, d.y, 1, d.len, honey[1]); c.px(d.x, d.y, honey[2])
            c.rect(d.x - 1, d.y + d.len, 2, 1, honey[1]); c.px(d.x, d.y + d.len + 1, honey[0])
        }
    }

    /// Andreenos's life: bees zipping about the hive, darting and turning, and honey dripping from the eaves, a
    /// drop swelling at the end of each run and falling.
    static func eterniaAndreenosLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaAndreenosFrame(c, g), q = f.q, tall = isTall(c)
        // The drips: each drop swells, lets go, falls a little way and fades.
        for (k, d) in eterniaHiveDrips.enumerated() {
            let ph = (t * 0.22 + Double(k) * 0.37).truncatingRemainder(dividingBy: 1)
            let x = f.x + d.x * q, y0 = f.y + (d.y + d.len + 1) * q
            if ph < 0.65 {
                let r = max(1, Int(Double(q) * ph / 0.65 * 1.2))
                c.rect(x - r / 2, y0, r + (q > 1 ? 0 : 1), r + 1, C(0xF0B030))
            } else {
                let k2 = (ph - 0.65) / 0.35, y = y0 + Int(k2 * k2 * Double(10 * q))
                c.rect(x, y, max(1, q), max(2, q * 3 / 2), C(0xF0B030, 1 - k2 * 0.7)); c.px(x, y, C(0xFFE080, 1 - k2))
            }
        }
        // The bees: little black-and-gold bodies, wings a pale blur flickering over their backs. They keep above
        // the crew's heads, over the hive.
        let b = max(1, (q + 1) / 2)
        let up = [".WW.W.", "KYKYKY", ".KYKY."], down = ["......", "KYKYKY", ".WWWW."]
        let pal: [Character: Px] = ["K": C(0x1A1206), "Y": C(0xF4C430), "W": C(0xE8F4FF, 0.75)]
        let top = max(3 * b, f.y + 6 * q), bottom = f.base - (tall ? 34 : 30) * q
        for k in 0..<(tall ? 18 : 9) {
            let w1 = 0.45 + noise(k * 5 + 60) * 0.5, w2 = 1.7 + noise(k * 5 + 61) * 1.4
            let cx = Double(c.w) * (0.15 + 0.7 * noise(k * 5 + 62))
            let x = cx + sin(t * w1 + Double(k)) * Double(c.w) * 0.18 + sin(t * w2 * 2.3 + Double(k)) * Double(5 * q)
            let dx = cos(t * w1 + Double(k)) * w1 * Double(c.w) * 0.18 + cos(t * w2 * 2.3 + Double(k)) * w2 * 2.3 * Double(5 * q)
            let v = 0.5 + 0.5 * sin(t * w1 * 1.3 + Double(k) * 2.1) * cos(t * w2 + Double(k))
            let y = Double(top) + v * Double(max(1, bottom - top))
            eternia5Pattern(c, Int(x) - 3 * b, Int(y) - b, b, Int(t * 14 + Double(k)) % 2 == 0 ? up : down, pal, flip: dx < 0)
        }
    }
}

// MARK: - Darksmoke

/// Which pixels of a `w`×`h` picture a shape covers, for rock drawn as polygons and shaded afterwards. Off the sides
/// and below the foot counts as covered (the rock goes on), above the top as open sky.
private struct Eternia5Mask {
    let w: Int, h: Int
    var on: [Bool]
    /// How far down everything drawn is moved, so shapes may reach a little above row 0.
    var drop = 0.0
    init(_ w: Int, _ h: Int) { self.w = w; self.h = h; on = [Bool](repeating: false, count: w * h) }
    subscript(x: Int, y: Int) -> Bool {
        if y < 0 { return false }
        if x < 0 || x >= w || y >= h { return true }
        return on[y * w + x]
    }
    /// Covers (or, with `value` false, carves out) the polygon through `pts`, shifted by (`dx`, `dy`): every pixel
    /// whose middle is inside it.
    mutating func poly(_ pts: [(Double, Double)], dx: Double = 0, dy: Double = 0, value: Bool = true) {
        let dy = dy + drop, w = w
        var on = on
        eternia5Spans(pts.map { ($0.0 + dx, $0.1 + dy) }, 0, h - 1) { y, xa, xb in
            let a = max(0, xa), b = min(w - 1, xb)
            if b >= a { for x in a...b { on[y * w + x] = value } }
        }
        self.on = on
    }
    /// Covers a round blob `r` across at (`x`, `y`).
    mutating func disc(_ x: Double, _ y: Double, _ r: Double) {
        let y = y + drop
        let ri = Int(r.rounded(.up)) + 1
        for yy in (Int(y) - ri)...(Int(y) + ri) where yy >= 0 && yy < h {
            for xx in (Int(x) - ri)...(Int(x) + ri) where xx >= 0 && xx < w {
                let ddx = Double(xx) + 0.5 - x, ddy = Double(yy) + 0.5 - y
                if ddx * ddx + ddy * ddy <= r * r { on[yy * w + xx] = true }
            }
        }
    }
    /// Covers a tapering curve from `a` to `b` bending towards `ctl`, `r0` thick at `a` and `r1` at `b`.
    mutating func curve(_ a: (Double, Double), _ ctl: (Double, Double), _ b: (Double, Double), _ r0: Double, _ r1: Double) {
        for i in 0...16 {
            let k = Double(i) / 16, m = 1 - k
            disc(m * m * a.0 + 2 * m * k * ctl.0 + k * k * b.0, m * m * a.1 + 2 * m * k * ctl.1 + k * k * b.1, r0 + (r1 - r0) * k)
        }
    }
}

extension Scenes {
    /// Where Granamyr's crags stand at Darksmoke, shared by the still picture and the moving layer: drawn at one
    /// pixel to a unit, 200 units wide and 60 tall (wider than the window's strip on the screen saver), blown up `q`
    /// times, their foot on `base`, their top left at `x`/`y`. The great cave's mouth is at units (100, 40).
    static func eterniaDarksmokeFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eternia5Scale(c, g)
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 100 * q, base - 59 * q)
    }

    private typealias Eternia5Shape = [(Double, Double)]

    /// The near crags, in units, black and lit from below: the great cliff with its two horns of rock, the leaning
    /// spire on the left, the hooked one on the right, an overhang either side and a few lesser teeth. The last few
    /// stand out past the 200 units, at the window's ends.
    private static let eterniaDarksmokeNear: [Eternia5Shape] = [
        // The great cliff, a horn of rock curling up and out at each shoulder.
        [(58, 60), (61, 46), (63, 36), (67, 29), (71, 26), (69, 18), (66, 10), (62, 3), (64.5, 2.5), (70, 8), (76, 15),
         (81, 21), (86, 19.5), (91, 21.5), (96, 18.5), (101, 20.5), (106, 18), (111, 21), (116, 19), (121, 13), (127, 7),
         (134, 2), (135.5, 3.5), (131, 9), (128, 17), (129, 25), (133, 29), (137, 36), (139, 46), (142, 60)],
        // The leaning spire, its tip out over the left.
        [(28, 60), (32, 46), (32, 36), (29, 26), (25, 16), (20, 8), (17, 2), (21, 4), (28, 11), (36, 21), (43, 30),
         (48, 40), (51, 50), (54, 60)],
        // The overhang, jutting towards the cave.
        [(47, 60), (46, 48), (49, 40), (55, 35), (64, 32), (60, 37), (57, 42), (56, 50), (59, 60)],
        // The hooked spire on the right, curling over like a talon.
        [(146, 60), (149, 48), (152, 38), (156, 28), (161, 19), (168, 12), (176, 7), (181, 7.5), (174, 12), (168, 20),
         (166, 30), (167, 42), (171, 52), (174, 60)],
        // A slab leaning on the cliff's right shoulder.
        [(138, 48), (141, 40), (147, 35), (153, 37), (148, 42), (144, 50), (146, 60), (139, 60)],
        // Lesser teeth either end.
        [(4, 60), (8, 46), (11, 38), (13.5, 33), (16, 40), (19, 52), (22, 60)],
        [(178, 60), (181, 46), (185, 35), (187.5, 30), (190, 37), (192, 48), (196, 60)],
        // At the window's ends: a tall spire leaning in at each edge and lesser crags inside them.
        [(-152, 60), (-152, 6), (-146, 4), (-138, 9), (-130, 2), (-125, -1), (-123, 4), (-124, 14), (-120, 28),
         (-113, 44), (-108, 60)],
        [(-98, 60), (-93, 46), (-90, 34), (-87, 24), (-83, 16), (-80, 14), (-78, 20), (-76, 32), (-70, 46), (-66, 60)],
        [(-52, 60), (-47, 50), (-41, 43), (-36, 41), (-31, 47), (-26, 60)],
        [(352, 60), (352, 4), (344, 8), (336, 3), (329, 0), (327, 5), (328, 16), (323, 30), (316, 46), (311, 60)],
        [(302, 60), (298, 48), (295, 36), (295, 25), (298, 15), (301, 12), (302, 20), (305, 32), (309, 46), (312, 60)],
        [(222, 60), (226, 52), (232, 45), (238, 42), (243, 49), (248, 60)],
    ]
    /// Granamyr's cave: the maw carved out of the great cliff, the fangs of rock hanging in its roof and standing on
    /// its sill, and the ledge he sleeps on, out in front.
    private static let eterniaDarksmokeMaw: Eternia5Shape = [
        (74, 52), (72.5, 45), (74, 38), (78, 33), (85, 30), (93, 28.5), (100, 29.5), (107, 28), (115, 30), (121, 33),
        (126, 38), (127.5, 45), (126, 52),
    ]
    private static let eterniaDarksmokeFangs: [Eternia5Shape] = [
        [(81, 31), (87, 30), (84, 38.5)], [(87.5, 29.5), (92.5, 29), (90, 36)], [(97.5, 29.5), (102, 29.5), (99.8, 33)],
        [(108, 28.5), (112.5, 29.2), (110, 36)], [(113, 30), (119, 31.5), (116, 38.5)],
        [(76, 51.5), (81.5, 51.5), (79.5, 44.5)], [(118.5, 51.5), (124, 51.5), (120.5, 44)],
    ]
    private static let eterniaDarksmokeLedge: Eternia5Shape = [(66, 60), (66, 54), (70, 51), (130, 51), (134, 54), (134, 60)]
    /// The crags behind, hazier with the smoke between: a spire leaning right behind the near one leaning left, the
    /// cliff's own back ridge showing over its crest, a spire behind the hooked one, and more at the window's ends.
    private static let eterniaDarksmokeBack: [Eternia5Shape] = [
        [(10, 60), (17, 40), (25, 22), (33, 10), (40, 2), (43, 0.5), (44.5, 6), (47, 18), (53, 32), (58, 46), (60, 60)],
        [(56, 60), (60, 30), (66, 22), (74, 25), (80, 17), (88, 11), (94, 14), (100, 8), (106, 13), (113, 9), (120, 17),
         (126, 21), (134, 19), (140, 27), (146, 60)],
        [(136, 60), (144, 40), (149, 28), (152, 14), (155, 5), (157.5, 2), (160, 12), (164, 26), (171, 42), (177, 60)],
        [(174, 60), (183, 36), (190, 24), (197, 30), (203, 42), (208, 60)],
        [(-8, 60), (-2, 38), (3, 27), (8, 34), (14, 60)],
        [(-124, 60), (-114, 30), (-106, 17), (-102, 23), (-96, 42), (-88, 60)],
        [(-44, 60), (-36, 36), (-29, 25), (-24, 31), (-14, 60)],
        [(236, 60), (246, 32), (253, 21), (258, 28), (268, 60)],
        [(312, 60), (316, 36), (322, 22), (327, 31), (336, 60)],
    ]
    /// On the screen saver, the crags rising high behind everything, faint in the smoke.
    private static let eterniaDarksmokeHigh: [Eternia5Shape] = [
        [(-14, 60), (-2, 22), (8, -2), (17, -20), (24, -28), (26, -22), (29, -6), (36, 18), (48, 60)],
        [(104, 60), (112, 14), (118, -2), (123, -12), (125, -8), (128, 6), (136, 60)],
        [(150, 60), (160, 22), (168, -4), (175, -17), (181, -24), (183, -18), (184, -4), (190, 20), (204, 60)],
        [(60, 60), (66, 22), (72, 6), (76, 2), (79, 10), (86, 60)],
    ]
    /// The cracks of lava running down the near crags, in units, each from its top to the pool at its foot.
    private static let eterniaDarksmokeCracks: [[(Int, Int)]] = [
        [(67, 30), (65, 37), (68, 43), (66, 50), (67, 59)],
        [(133, 31), (135, 38), (132, 45), (134, 52), (133, 59)],
        [(39, 34), (41, 41), (38, 46), (42, 52), (41, 59)],
        [(164, 38), (166, 44), (163, 50), (164, 59)],
    ]
    /// Vents along the cliff's crest, between the horns, where smoke pours out, in units.
    private static let eterniaDarksmokeVents: [(x: Int, y: Int)] = [(91, 21), (101, 20), (111, 20), (-81, 14), (300, 12)]

    /// Darksmoke, the black crags where Granamyr and Eternia's ancient dragons live: a sky choked with smoke, near
    /// black overhead and lit red and orange from below by the fires underground, long streamers of smoke lying across
    /// it. The crags are jagged black rock, a strong ragged skyline: a spire leaning out on the left, a talon of rock
    /// hooking over on the right, overhangs, and in the middle the great cliff, two horns of rock curling up off its
    /// shoulders. Under them Granamyr's cave, a huge maw in the rock, fangs of stone hanging in its roof and standing
    /// on its sill, dark inside with a deep red glow far back and old dragon bones on the ledge he sleeps on out in
    /// front. Lava glows in cracks down the crags and pools at their feet, and every edge facing it is rim-lit orange;
    /// up high the rock goes black against the lighter smoke, hazier the further back. The crew stands on a plain of
    /// grey ash. On the screen saver the crags stand three times the size, more rising high behind them into the smoke.
    static func eterniaDarksmoke(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaDarksmokeFrame(c, g), q = f.q, tall = isTall(c)
        // The sky: near black up top, smoke-brown, then red and orange where the fires light it from below.
        let glowTop = max(0, f.y + (tall ? -10 : 18) * q)
        c.gradient(0, glowTop, C(0x221820), C(0x4A2A2C), bands: tall ? 8 : 4)
        c.gradient(glowTop, f.base, C(0x4A2A2C), C(0xC8582C), bands: tall ? 10 : 6)
        // Long streamers of smoke lying across it, grey-violet above and lit ember underneath.
        let streams: [(x: Int, y: Int, len: Int, th: Int)] = tall
            ? [(-6, 8, 70, 4), (40, 15, 66, 5), (2, 25, 54, 3), (52, 32, 56, 4), (-4, 44, 62, 5), (36, 54, 70, 4),
               (6, 66, 50, 3), (60, 74, 44, 3), (20, 82, 60, 2)]
            : [(-4, 10, 40, 2), (44, 4, 46, 2), (26, 30, 36, 2), (70, 40, 34, 2)]
        let skyH = Double(tall ? f.y + 40 * q : f.y + 30 * q)
        for (k, st) in streams.enumerated() {
            eterniaDarksmokeStreamer(c, c.w * st.x / 100, Int(skyH * Double(st.y) / 100), c.w * st.len / 100,
                                     st.th * s * (tall ? 2 : 1), seed: k, lit: Double(st.y) / 100)
        }

        // The crags, drawn a unit to a pixel on a canvas the size of the picture and blown up to size.
        let uw = c.w / q + 2, uh = f.base / q + 1
        let lx = uw / 2 - 100, ly = uh - 60
        let art = PixelCanvas(uw, uh)
        eterniaDarksmokeCrags(art, lx: lx, ly: ly, tall: tall)
        eternia5BlowUp(c, art, f.x - lx * q, f.base - (uh - 1) * q, q)

        // The plain in front: grey ash, plain where the crew stands, warmed near the lava pools.
        c.gradient(f.base + q, g, C(0x3E3238), C(0x342A30), bands: 3)
        for crack in eterniaDarksmokeCracks {
            let x = f.x + crack.last!.0 * q
            c.ellipse(x, f.base + q, 9 * q, max(1, q), C(0xE06A2A, 0.22)); c.ellipse(x, f.base + q, 5 * q, max(1, q / 2), C(0xF09040, 0.35))
        }
        c.ground(g, C(0x3A3034), edge: C(0x5A4844), speck: C(0x2E2628), seed: 53)
    }

    /// A long streamer of smoke from (`x`, `y`), `len` pixels long and about `th` thick, wavering along its length,
    /// thinning at both ends, its edges soft: grey-violet along its top, lit ember along its underside, more so the
    /// lower in the sky it lies (`lit`, 0...1).
    private static func eterniaDarksmokeStreamer(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, _ th: Int, seed: Int,
                                                 lit: Double) {
        let top = lerp(C(0x5A4A58), C(0x7A5A60), lit), under = lerp(C(0x7A3A30), C(0xD86E3E), lit)
        let ph = noise(seed * 13 + 900) * 6, f1 = 0.018 + noise(seed * 13 + 901) * 0.02
        for i in 0..<max(1, len) {
            let k = Double(i) / Double(max(1, len))
            let taper = min(1, k * 5, (1 - k) * 4)
            let half = Double(th) * taper * (0.7 + 0.3 * sin(Double(i) * f1 * 2.7 + ph))
            guard half >= 0.5 else { continue }
            let cy = Double(y) + sin(Double(i) * f1 + ph) * Double(th) * 0.5 + Double(i) * 0.04
            for dy in Int(-half)...Int(half) {
                let e = abs(Double(dy)) / half
                // Three steps of softness, so it stays pixel art but has no hard rim.
                let a = e < 0.45 ? 0.62 : e < 0.75 ? 0.4 : 0.18
                c.px(x + i, Int(cy) + dy, (dy > Int(half / 3) ? under : top).alpha(a * min(1, taper * 1.4)))
            }
        }
    }

    /// The crags themselves on `c`, a pixel to a unit, the 200-unit landmark's top left at (`lx`, `ly`): the far ranges,
    /// on the screen saver the high crags, the crags behind, the cave's dark, the near crags, lava and the bones.
    private static func eterniaDarksmokeCrags(_ c: PixelCanvas, lx: Int, ly: Int, tall: Bool) {
        let dx = Double(lx), dy = Double(ly)
        /// Where the lava lights the rock from: the cave and each crack and pool, in units of the landmark.
        var glows: [(x: Double, y: Double, r: Double, k: Double)] = [(100, 42, 27, 0.95)]
        for crack in eterniaDarksmokeCracks {
            let mid = crack[crack.count / 2], foot = crack.last!
            glows.append((Double(mid.0), Double(mid.1), 8, 0.45)); glows.append((Double(foot.0), Double(foot.1), 13, 0.75))
        }
        let shifted = glows.map { (x: $0.x + dx, y: $0.y + dy, r: $0.r, k: $0.k) }

        // The far ranges along the horizon: ragged teeth, brown-black in the haze, their tops lit by the glow.
        var far = Eternia5Mask(c.w, c.h)
        var pts: Eternia5Shape = [(-2, Double(c.h))]
        var x = -2.0, k = 0
        while x < Double(c.w) + 6 {
            let big = noise(k * 7 + 604) > 0.75
            pts.append((x, dy + 40 - noise(k * 7 + 600) * 9 - (big ? 9 : 0)))
            x += 3 + noise(k * 7 + 601) * (big ? 9 : 6)
            pts.append((x, dy + 47 - noise(k * 7 + 602) * 5))
            x += 2 + noise(k * 7 + 603) * 7
            k += 1
        }
        pts.append((x, Double(c.h)))
        far.poly(pts)
        if tall { var high = Eternia5Mask(c.w, c.h); for sh in eterniaDarksmokeHigh { high.poly(sh, dx: dx, dy: dy) }
                  eterniaDarksmokeShade(c, high, haze: 0.62, glows: [], seed: 5) }
        eterniaDarksmokeShade(c, far, haze: 0.5, glows: [], seed: 7)
        var back = Eternia5Mask(c.w, c.h)
        for sh in eterniaDarksmokeBack { back.poly(sh, dx: dx, dy: dy) }
        eterniaDarksmokeShade(c, back, haze: 0.28, glows: shifted.map { (x: $0.x, y: $0.y, r: $0.r * 1.3, k: $0.k * 0.5) }, seed: 11)

        // The cave's dark: black at its edges, a deep red glow far back where the dragon's fire smoulders.
        var maw = Eternia5Mask(c.w, c.h)
        maw.poly(eterniaDarksmokeMaw, dx: dx, dy: dy)
        var near = Eternia5Mask(c.w, c.h)
        for sh in eterniaDarksmokeNear { near.poly(sh, dx: dx, dy: dy) }
        near.poly(eterniaDarksmokeMaw, dx: dx, dy: dy, value: false)
        for sh in eterniaDarksmokeFangs { near.poly(sh, dx: dx, dy: dy) }
        near.poly(eterniaDarksmokeLedge, dx: dx, dy: dy)
        for yy in 0..<c.h {
            for xx in 0..<c.w where maw[xx, yy] && !near[xx, yy] {
                let ux = (Double(xx) - dx - 100) / 21, uy = (Double(yy) - dy - 42) / 10
                let d = (ux * ux + uy * uy).squareRoot()
                let v = max(0, 1 - d) + (noise(xx * 5 + yy * 77) - 0.5) * 0.12
                c.px(xx, yy, v > 0.72 ? C(0x521610) : v > 0.42 ? C(0x2E0C0C) : v > 0.12 ? C(0x18060A) : C(0x090306))
            }
        }
        eterniaDarksmokeShade(c, near, haze: 0, glows: shifted, seed: 3)

        // The lava: cracks running down the rock, white-hot at the core, orange either side.
        for crack in eterniaDarksmokeCracks {
            for i in 0..<(crack.count - 1) {
                // Smouldering dark red near its top, hotter as it runs down to the pool.
                let hot = Double(i + 1) / Double(crack.count - 1)
                eterniaDarksmokeLine(c, crack[i].0 + lx, crack[i].1 + ly, crack[i + 1].0 + lx, crack[i + 1].1 + ly) { px, py, n in
                    if hot > 0.5 { c.px(px + (n % 2 == 0 ? -1 : 1), py, C(0x6A2014)) }
                    c.px(px, py, hot < 0.3 ? C(0x8A2A16) : hot < 0.6 ? C(0xC8461C) : n % 7 == 3 ? C(0xFFD070) : C(0xEC6A24))
                }
            }
            // The pool at its foot.
            let p = crack.last!
            c.rect(p.0 + lx - 4, p.1 + ly, 9, 1, C(0xC8501E)); c.rect(p.0 + lx - 2, p.1 + ly, 5, 1, C(0xF8A040))
            c.rect(p.0 + lx - 3, p.1 + ly - 1, 7, 1, C(0x7A2414))
        }

        // Old dragon bones on the ledge, lit from the cave: a ribcage on the left, a horned skull on the right.
        let bone = C(0xDCC8A4), boneS = C(0x8E7656), boneL = C(0xF4C890)
        let ox = lx, oy = ly
        c.rect(ox + 84, oy + 50, 11, 1, boneS)
        for (i, rx) in [85, 87, 89, 91, 93].enumerated() {
            let h = 3 + (i == 2 ? 1 : i == 0 || i == 4 ? -1 : 0)
            c.rect(ox + rx, oy + 50 - h, 1, h, bone); c.px(ox + rx + 1, oy + 50 - h, bone); c.px(ox + rx, oy + 50 - h, boneL)
        }
        c.pattern(ox + 104, oy + 46, [
            "...H......",
            "..HBBB....",
            ".BBKBBBBB.",
            "BBBBBBBBBB",
            ".SBSBSBSS.",
        ], ["H": boneL, "B": bone, "K": C(0x1A0A08), "S": boneS])
    }

    /// Shades the rock `m` covers onto `c`: near-black basalt in angular facets, the lava's glow (`glows`, each a
    /// place, a reach and a strength) warming it and catching its edges orange where they face the light; edges up
    /// in the dark stay black against the smoke. `haze` lightens it towards the smoke's colour for rock further back.
    private static func eterniaDarksmokeShade(_ c: PixelCanvas, _ m: Eternia5Mask, haze: Double,
                                              glows: [(x: Double, y: Double, r: Double, k: Double)], seed: Int) {
        let rock = [C(0x08060A), C(0x110C12), C(0x1A1218), C(0x261A20), C(0x34242A), C(0x463036)]
        let smoke = C(0x4E3238), emberD = C(0x5E2216), ember = C(0xC8501E), hot = C(0xF8A048)
        for y in 0..<m.h {
            for x in 0..<m.w where m.on[y * m.w + x] {
                var warm = 0.0
                for gl in glows {
                    let ddx = Double(x) - gl.x, ddy = Double(y) - gl.y
                    let d = (ddx * ddx + ddy * ddy).squareRoot()
                    if d < gl.r { let k = 1 - d / gl.r; warm += gl.k * k * k }
                }
                warm = min(1, warm)
                // Angular facets: the rock broken into slanting planes, each a little lighter or darker.
                let facet = noise(((x * 2 + y) / 7) * 7919 + ((y - x / 3) / 5) * 131 + seed) - 0.5
                let v = 0.2 + facet * 0.3 + Double(y) / Double(m.h) * 0.08
                var col = eternia5Dither(rock, v, x, y, grain: 0.14)
                col = lerp(col, emberD, warm * 0.5)
                // Edges: facing the glow, rim-lit; up in the dark, the darkest tone, crisp against the smoke.
                let side = !m[x - 1, y] || !m[x + 1, y], up = !m[x, y - 1]
                let edge = side || up
                let near2 = !m[x - 2, y] || !m[x + 2, y]
                if up && !side && warm > 0.12 && warm < 0.4 {
                    col = lerp(emberD, ember, warm * 1.5)
                } else if edge {
                    col = warm > 0.12 ? (warm > 0.55 ? lerp(ember, hot, min(1, (warm - 0.55) * 1.6)) : lerp(emberD, ember, (warm - 0.12) * 2.3))
                        : haze > 0 ? lerp(rock[3], smoke, 0.4) : rock[0]
                } else if near2 && warm > 0.3 {
                    col = lerp(emberD, ember, (warm - 0.3) * 0.8)
                }
                if haze > 0 { col = lerp(col, smoke, haze * (0.75 + 0.25 * (1 - Double(y) / Double(m.h)))) }
                c.px(x, y, col)
            }
        }
    }

    /// Calls `plot` for each pixel along the line from (`x0`, `y0`) to (`x1`, `y1`), with its step number.
    private static func eterniaDarksmokeLine(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int,
                                             _ plot: (Int, Int, Int) -> Void) {
        let n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in 0...n {
            plot(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, i + x0 * 3)
        }
    }

    /// Darksmoke's life: smoke pouring out of the vents and the cracks' tops in long plumes that rise and lean away on
    /// the wind, embers floating up off the lava, the lava and the cave's glow pulsing, Granamyr's great eyes opening
    /// now and then in the dark of his cave and, on the screen saver, dragons gliding through the smoke.
    static func eterniaDarksmokeLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaDarksmokeFrame(c, g), q = f.q, tall = isTall(c)
        func at(_ u: Double, _ v: Double) -> (x: Int, y: Int) { (f.x + Int(u * Double(q)), f.y + Int(v * Double(q))) }
        // The cave's glow breathing, slow, as the dragon inside does.
        let breath = 0.5 + 0.5 * sin(t * 0.7)
        let m = at(100, 44)
        c.ellipse(m.x, m.y - 2 * q, 8 * q, 4 * q, C(0xA02814, 0.04 + 0.12 * breath))
        // The lava pulsing: a brighter glow running down each crack, the pools swelling.
        for (i, crack) in eterniaDarksmokeCracks.enumerated() {
            let pulse = 0.5 + 0.5 * sin(t * 1.3 + Double(i) * 1.7)
            let p = at(Double(crack.last!.0) + 0.5, Double(crack.last!.1) + 0.5)
            c.ellipse(p.x, p.y, 6 * q, max(1, q * 3 / 2), C(0xF89040, 0.12 + 0.2 * pulse))
            let run = (t * 0.35 + Double(i) * 0.3).truncatingRemainder(dividingBy: 1)
            let j = min(crack.count - 2, Int(run * Double(crack.count - 1))), k = run * Double(crack.count - 1) - Double(j)
            let a = crack[j], b = crack[j + 1]
            let r = at(Double(a.0) + Double(b.0 - a.0) * k + 0.5, Double(a.1) + Double(b.1 - a.1) * k + 0.5)
            c.ellipse(r.x, r.y, q, 2 * q, C(0xFFC060, 0.35))
        }
        // Granamyr's eyes, opening in the dark of the cave for a few seconds, blinking once, then shut again.
        let cyc = t.truncatingRemainder(dividingBy: 9)
        if cyc > 4.5 {
            var open = min(1, (cyc - 4.5) * 2.5, (9 - cyc) * 2.5)
            if abs(cyc - 6.8) < 0.12 { open = 0.2 }
            for (ex, dir) in [(92.0, 1), (103.0, -1)] {
                let e = at(ex, 37.5)
                c.ellipse(e.x + 5 * q / 2, e.y + q, 5 * q, 2 * q, C(0xF0C030, 0.14 * open))
                // An almond, its inner corner lower, the lid closing down over it, a slit of pupil.
                for i in 0..<5 {
                    let rows = i == 0 || i == 4 ? 1 : 2, drop = (dir > 0 ? i : 4 - i) >= 3 ? 1 : 0
                    let hgt = max(0, Int((Double(rows * q) * open).rounded()))
                    guard hgt > 0 else { continue }
                    let y = e.y + drop * q / 2 + (2 * q - rows * q) / 2 + (rows * q - hgt)
                    c.rect(e.x + i * q, y, q, hgt, i == 2 ? C(0x1A0806) : i == 0 || i == 4 ? C(0xE08A20) : C(0xF8DC48))
                }
            }
        }

        // Smoke: plumes pouring up out of the vents and the cracks' tops, leaning away on the wind into long trails,
        // soft-edged, lit ember low down and going grey-violet as they climb.
        let rise = Double((tall ? 72 : 24) * q), lean = Double((tall ? 60 : 34) * q)
        var sources = eterniaDarksmokeVents.map { (Double($0.x), Double($0.y), 1.0) }
        sources += eterniaDarksmokeCracks.map { (Double($0[0].0), Double($0[0].1), 0.6) }
        for (i, src) in sources.enumerated() {
            let base = at(src.0 + 0.5, src.1)
            let n = 46, speed = 0.05 + noise(i * 5 + 40) * 0.03
            let flow = t * speed * Double(n)
            for j in 0..<n {
                let u = (Double(j) + flow.truncatingRemainder(dividingBy: 1)) / Double(n)
                let id = j - Int(flow)
                let sway = sin(u * 5 - t * 0.6 + Double(i)) * Double(2 * q) * (0.3 + u)
                let x = Double(base.x) + pow(u, 1.6) * lean * src.2 + sway
                let y = Double(base.y) - u * rise * (0.6 + 0.4 * src.2)
                let w = Double(q) * (1.2 + u * (tall ? 9 : 6)) * (0.8 + 0.4 * noise(id * 7 + i * 31))
                let a = min(1, u * 8) * pow(1 - u, 0.7) * 0.17 * src.2
                let col = lerp(C(0xB85A3A), C(0x7A6876), min(1, u * 1.8))
                c.ellipse(Int(x), Int(y), max(1, Int(w * 1.7)), max(1, Int(w * 0.85)), col.alpha(a))
                c.ellipse(Int(x - w * 0.4), Int(y - w * 0.3), max(1, Int(w)), max(1, Int(w * 0.45)), C(0x9A8A96, a * 0.6))
            }
        }

        // Embers: sparks floating up off the lava and out of the cave, drifting on the wind, flickering, going out.
        let fromAt: [(Double, Double)] = eterniaDarksmokeCracks.map { (Double($0.last!.0), Double($0.last!.1)) } + [(100, 50), (92, 50), (108, 50)]
        for k in 0..<(tall ? 40 : 18) {
            let ph = (t * (0.08 + noise(k * 3 + 70) * 0.07) + noise(k * 3 + 71)).truncatingRemainder(dividingBy: 1)
            let src = fromAt[k % fromAt.count], o = at(src.0 + (noise(k * 3 + 72) - 0.5) * 8, src.1)
            let x = Double(o.x) + sin(t * 1.3 + Double(k)) * Double(2 * q) + ph * Double((tall ? 30 : 16) * q)
            let y = Double(o.y) - ph * Double((tall ? 90 : 46) * q)
            guard y > 0, noise(Int(t * 9) + k * 13) > 0.12 else { continue }
            let sz = max(1, q / 2 + (k % 4 == 0 ? 1 : 0))
            c.rect(Int(x), Int(y), sz, sz, (k % 3 == 0 ? C(0xFFD070) : C(0xF8782C)).alpha(1 - ph * 0.85))
        }

        guard tall else { return }
        // Dragons gliding through the smoke, black with their undersides lit by the fires, wings beating slowly.
        for k in 0..<3 {
            let b = max(1, q * (3 - k) / 3), speed = 0.011 + Double(k) * 0.005, dir = k == 1 ? -1.0 : 1.0
            let span = Double(c.w + 56 * b)
            var x = (t * speed * span + Double(k) * span * 0.41).truncatingRemainder(dividingBy: span) - Double(52 * b)
            if dir < 0 { x = Double(c.w) - x - Double(52 * b) }
            let y = Double(f.y) * (0.12 + Double(k) * 0.24) + sin(t * 0.35 + Double(k)) * Double(5 * b)
            let flap = t * (0.9 + Double(k) * 0.25) + Double(k) * 2
            eterniaDarksmokeDragon(c, Int(x), Int(y), b, flap: flap, flip: dir < 0, haze: Double(k) * 0.3)
        }
    }

    /// A dragon in flight at (`x`, `y`), `b` pixels to a unit, facing right (left when `flip`): a long neck and horned
    /// head, a body, legs tucked up, a long tail ending in a spade, and two great bat wings, the near one black, the
    /// far one a shade lighter behind it, swinging between raised high and spread back flat with `flap` (in radians)
    /// so the wings, neck and tail always stand clear of one another. Black, its underside lit ember; `haze` (0...1)
    /// pales it with distance.
    private static func eterniaDarksmokeDragon(_ c: PixelCanvas, _ x: Int, _ y: Int, _ b: Int, flap: Double, flip: Bool,
                                               haze: Double) {
        let w = 52, h = 38
        var near = Eternia5Mask(w, h), farWing = Eternia5Mask(w, h), skin = Eternia5Mask(w, h)
        near.drop = 11; farWing.drop = 11; skin.drop = 11
        /// A bat wing from the shoulder `sh` to the hip `hip`: the arm out to the wrist, three long fingers fanning
        /// back from it, the first pointing at angle `a` (radians, y down) and `len` units out, the membrane between
        /// them scalloped.
        func wing(_ m: inout Eternia5Mask, _ bones: inout Eternia5Mask, _ sh: (Double, Double), _ hip: (Double, Double),
                  _ len: Double, _ a: Double) {
            let wrist = (sh.0 + cos(a + 0.55) * len * 0.42, sh.1 + sin(a + 0.55) * len * 0.42)
            let tips = [(a, 0.7), (a - 0.6, 0.62), (a - 1.2, 0.48)].map { (wrist.0 + cos($0.0) * len * $0.1, wrist.1 + sin($0.0) * len * $0.1) }
            var pts: Eternia5Shape = [sh, wrist, tips[0]]
            for (i, end) in [tips[1], tips[2], hip].enumerated() {
                let from = tips[i], mid = ((from.0 + end.0) / 2, (from.1 + end.1) / 2)
                pts.append((mid.0 + (wrist.0 - mid.0) * 0.38, mid.1 + (wrist.1 - mid.1) * 0.38))
                pts.append(end)
            }
            m.poly(pts)
            // The arm and its fingers, thicker than the membrane, so the wing keeps its shape however it's held.
            bones.curve(sh, ((sh.0 + wrist.0) / 2, (sh.1 + wrist.1) / 2), wrist, 0.9, 0.7)
            for tp in tips { bones.curve(wrist, ((wrist.0 + tp.0) / 2, (wrist.1 + tp.1) / 2), tp, 0.6, 0.3) }
        }
        let a = (-130 + 32 * sin(flap)) * Double.pi / 180
        var farBones = Eternia5Mask(w, h)
        farBones.drop = 11
        wing(&farWing, &farBones, (27.5, 16.5), (23, 17.5), 17, a + 0.95)
        wing(&skin, &near, (24.5, 17.5), (17, 18.6), 23, a)
        near.poly([(15, 18.4), (21, 16.8), (27, 17), (29.5, 18.4), (27, 20.2), (20, 20.6)])   // the body
        near.curve((29, 18), (35, 18.5), (38.5, 13), 1.2, 0.8)                             // the neck
        near.poly([(37, 12), (40, 11), (43, 11.6), (47, 12.8), (47, 13.8), (43, 14), (40.5, 15.2), (37.6, 15)])  // the head
        near.poly([(38, 12.4), (34, 8.6), (39.4, 11.4)])                                   // its horn
        near.curve((16, 19), (7, 23), (2.5, 17), 1.1, 0.4)                                   // the tail
        near.poly([(2.6, 17.4), (0.5, 15), (4, 16), (1.8, 19.4)])                            // its spade
        near.poly([(21, 20), (20.4, 22.6), (22, 22.6), (22.8, 20.2)]); near.poly([(25.6, 19.8), (27.2, 22), (28.4, 21.4), (27.2, 19.4)])
        let body = lerp(C(0x120A10), C(0x4A3440), haze), skinC = lerp(C(0x2E1A22), C(0x5A3E48), haze)
        let farC = lerp(C(0x2A1A22), C(0x5A4450), haze), farSkin = lerp(C(0x3E2830), C(0x66505A), haze)
        let rim = lerp(C(0x9A3A1E), C(0x8A5048), haze)
        for yy in 0..<h {
            for xx in 0..<w {
                let col: Px
                let i = yy * w + xx
                if near.on[i] { col = yy + 1 < h && !near.on[i + w] && !skin.on[i + w] && yy > 27 ? rim : body }
                else if skin.on[i] { col = skinC }
                else if farBones.on[i] { col = farC }
                else if farWing.on[i] { col = farSkin }
                else { continue }
                c.rect(x + (flip ? w - 1 - xx : xx) * b, y + yy * b, b, b, col)
            }
        }
        // The eye, a fleck of ember.
        c.rect(x + (flip ? w - 1 - 42 : 42) * b, y + 23 * b, b, b, C(0xF8A040))
    }
}

// MARK: - Trolla

extension Scenes {
    /// Where the village stands on Trolla: drawn at one pixel to a unit on a 200×56 canvas (`eterniaTrollaVillage`),
    /// wide so it spreads across the window's strip, and blown up `q` times, its foot on `base`, its canvas's top left
    /// at `x`/`y` (on the screen saver its outermost houses run off the sides).
    static func eterniaTrollaFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eternia5Scale(c, g)
        let base = g - (isTall(c) ? 12 : 7) * q
        return (q, base, c.w / 2 - 100 * q, base - 55 * q)
    }

    /// Trolla's moons, in hundredths of the sky's width and height: where each is, its radius in units, its two
    /// colours (lit and shaded) and its look (0 plain, 1 ringed, 2 a crescent, 3 banded). The first few are in the
    /// window too; the screen saver's sky is full of them.
    private static let eterniaTrollaMoons: [(x: Int, y: Int, r: Int, lit: UInt32, dark: UInt32, look: Int)] = [
        (82, 26, 9, 0x7ADCD0, 0x3A8A9A, 1), (16, 18, 6, 0xF4D070, 0xB08A3A, 2), (52, 10, 4, 0xF4A0C8, 0xB0608E, 0),
        (34, 34, 3, 0xC8B4F4, 0x8070B4, 3), (94, 8, 3, 0xF4B080, 0xB0704A, 0),
        (8, 52, 7, 0xA0E4A0, 0x5A9A6A, 3), (66, 46, 5, 0xF4E0A0, 0xB09A5A, 1), (28, 70, 4, 0xF08080, 0xA04A5A, 0),
        (88, 62, 6, 0xB4C8FF, 0x6A7AC0, 2), (46, 62, 2, 0xFFFFFF, 0xB0B0D0, 0), (74, 80, 3, 0xF4A0C8, 0xB0608E, 3),
    ]

    /// Trolla, Orkko's home: a moon of its own floating in a violet sky that goes pink at the horizon, stars
    /// everywhere and other moons hanging all round it, one ringed, one a crescent, some banded. The ground is the
    /// floating moon's own lilac rock, pocked with craters, its rim falling away at either side so the sky shows
    /// under it. On a knoll in the middle stands the village: little round houses with domed roofs in dusky pastel,
    /// lit from the left, round windows glowing warm, round doors, a spike or a ball on top of each, and the tallest
    /// in the middle with an onion dome and a star on its spire. On the screen saver the village stands three times
    /// the size, islets with a house each float about it, and the sky is full of moons.
    static func eterniaTrolla(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaTrollaFrame(c, g), q = f.q, tall = isTall(c)
        let mid = g * 55 / 100
        c.gradient(0, mid, C(0x120C30), C(0x4A2A7E), bands: tall ? 8 : 5)
        c.gradient(mid, g, C(0x4A2A7E), C(0xD86C9E), bands: tall ? 8 : 5)
        c.stars(0, g * 80 / 100, density: tall ? 40 : 30, seed: 41)
        // The moons, shaded, each with its look.
        let moons = tall ? eterniaTrollaMoons : Array(eterniaTrollaMoons.prefix(5))
        let sky = f.base - 30 * q
        for m in moons {
            let r = m.r * s * (tall ? 2 : 1), x = c.w * m.x / 100, y = max(r + s, (tall ? sky : f.base) * m.y / 100)
            eterniaTrollaMoon(c, x, y, r, s, lit: C(m.lit), dark: C(m.dark), look: m.look)
        }
        // The floating moon's surface: flat in the middle, its rim falling away at either side so the sky shows
        // under it, lilac rock in bands going darker towards the crew.
        let rock = [C(0x2C2240), C(0x3A2E52), C(0x4A3C64), C(0x5E4E7A), C(0x76648E)]
        let lip = { (x: Int) -> Int in
            let k = abs(Double(x) - Double(c.w) / 2) / (Double(c.w) / 2)
            return f.base - 2 * q + Int(pow(k, 5) * Double(g - f.base + 2 * q))
        }
        for x in 0..<c.w {
            let top = lip(x)
            guard top < g else { continue }
            for y in top..<g {
                let d = Double(y - top) / Double(max(1, g - f.base + 2 * q))
                c.px(x, y, eternia5Dither(rock, 0.75 - d * 0.5, x / max(1, q), y / max(1, q), grain: 0.2))
            }
            c.px(x, top, rock[4])
            // The rim's underside where it curls away, a darker band.
            if top > f.base + q { c.rect(x, top + 1, 1, max(1, q), rock[0]) }
        }
        // Craters on the surface: shallow dishes, a lit far rim and a shaded near one.
        for k in 0..<(c.w / (24 * s) + 2) {
            let x = Int(noise(k * 3 + 300) * Double(c.w)), y = f.base + Int(noise(k * 3 + 301) * Double(max(1, g - f.base - 2 * q)))
            let rx = (3 + Int(noise(k * 3 + 302) * 4)) * q, ry = max(1, rx / 3)
            guard y > lip(x) + ry, y + ry < g else { continue }
            c.ellipse(x, y, rx, ry, rock[1]); c.ellipse(x, y + max(1, ry / 2), rx - max(1, q), max(1, ry - 1), rock[2])
            c.rect(x - rx + q, y - ry, rx * 2 - 2 * q, max(1, q / 2), rock[0])
        }

        // On the screen saver, islets of rock float about, a little house on each.
        if tall {
            for (k, p) in [(14, 40), (86, 36), (70, 18), (26, 22)].enumerated() {
                let x = c.w * p.0 / 100, y = sky * p.1 / 100 + 30 * q, w = (8 + k % 2 * 4) * q
                eterniaTrollaIslet(c, x, y, w, q, seed: k)
            }
        }

        // In the window, outlying houses on the plain either side of the village (the screen saver has its islets).
        // In the window the village runs on out along the plain either side, so it spans most of the strip.
        let outliers: [(off: Int, hw: Int, wall: Int)] = tall ? [] : [
            (-156, 4, 4), (-138, 5, 6), (-121, 4, 5), (-108, 3, 3), (110, 3, 3), (122, 5, 5), (139, 4, 6), (157, 5, 4),
        ]
        for (k, o) in outliers.enumerated() {
            let art = PixelCanvas(16, 19), x = c.w / 2 + o.off * q
            eterniaTrollaHouse(art, 8, 18, o.hw, o.wall, eterniaTrollaDomes[(k * 3 + 1) % eterniaTrollaDomes.count], top: k % 2)
            eternia5BlowUp(c, art, x - 8 * q, lip(x) - 17 * q, q)
        }

        // The village, blown up to size.
        let village = PixelCanvas(200, 56)
        eterniaTrollaVillage(village)
        eternia5BlowUp(c, village, f.x, f.y, q)
        c.ground(g, C(0x3A2E52), edge: C(0x5E4E7A), speck: C(0x2C2240), seed: 61)
    }

    /// A moon in the sky at (`x`, `y`), `r` across: lit from the left, a crater or two, and its look: plain, a
    /// ring round it, a crescent (the dark side the sky's own colour), or banded like a gas giant.
    private static func eterniaTrollaMoon(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ s: Int, lit: Px, dark: Px, look: Int) {
        if look == 1 {
            // The far half of the ring, behind the moon.
            for dx in -r * 2...r * 2 {
                let k = Double(dx) / Double(r * 2), dy = Int((1 - k * k).squareRoot() * Double(max(1, r / 4)))
                c.rect(x + dx, y - dy, 1, max(1, s), C(0xC8B8E0, 0.6))
            }
        }
        c.circle(x, y, r + max(1, s), lit.alpha(0.18))
        c.circle(x, y, r, dark)
        c.circle(x - r / 5, y - r / 5, r * 4 / 5, lit)
        if look == 2 {
            c.circle(x + r / 3, y - r / 6, r * 5 / 6, C(0x2A1A5A))
        } else if look == 3 {
            for k in stride(from: -r + r / 3, to: r, by: max(2, r / 2)) { c.rect(x - r * 3 / 4, y + k, r * 3 / 2, max(1, r / 6), dark.alpha(0.8)) }
        } else {
            c.circle(x - r / 3, y + r / 4, max(1, r / 5), dark); c.circle(x + r / 4, y - r / 3, max(1, r / 6), dark)
        }
        if look == 1 {
            // The near half of the ring, in front.
            for dx in -r * 2...r * 2 {
                let k = Double(dx) / Double(r * 2), dy = Int((1 - k * k).squareRoot() * Double(max(1, r / 4)))
                c.rect(x + dx, y + dy, 1, max(1, s), C(0xF4ECFF, 0.85))
            }
        }
    }

    /// A small floating islet of rock at (`x`, `y`), `w` across, a domed house on its top and the rock tapering to a
    /// point underneath.
    private static func eterniaTrollaIslet(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ q: Int, seed: Int) {
        let rock = [C(0x2C2240), C(0x3A2E52), C(0x4A3C64), C(0x5E4E7A)]
        let depth = w * 3 / 4
        for j in 0..<depth {
            let half = (w / 2) * (depth - j) / depth
            c.rect(x - half, y + j, half * 2, 1, j < q ? rock[3] : rock[1 + (j / max(1, q)) % 2])
            c.px(x - half, y + j, rock[3]); c.px(x + half - 1, y + j, rock[0])
        }
        let art = PixelCanvas(12, 15)
        eterniaTrollaHouse(art, 6, 14, 4, 4, eterniaTrollaDomes[seed % eterniaTrollaDomes.count], top: seed % 2)
        eternia5BlowUp(c, art, x - 6 * q, y - 14 * q, q)
    }

    /// The domes' colours, lit then shaded, in dusky pastels: gold, rose, teal, lilac and peach.
    private static let eterniaTrollaDomes: [(lit: Px, dark: Px)] = [
        (C(0xD8AC48), C(0x8E6828)), (C(0xC86A9A), C(0x7E3A64)), (C(0x4AAA9C), C(0x266A66)),
        (C(0x8C74C8), C(0x52428A)), (C(0xD88A5A), C(0x8E5030)),
    ]

    /// A little Trollan house, its foot's middle at (`cx`, `foot`): a round wall `hw` either side and `wall` tall in
    /// pale stone lit from the left, a round door and window, and a dome on top in `dome`'s colours with a spike
    /// (`top` 0) or a ball (`top` 1) on it.
    private static func eterniaTrollaHouse(_ c: PixelCanvas, _ cx: Int, _ foot: Int, _ hw: Int, _ wall: Int,
                                           _ dome: (lit: Px, dark: Px), top: Int) {
        let stone = [C(0x5A4A6A), C(0x7E6C88), C(0xA492A8), C(0xC4B4C0)]
        let y0 = foot - wall
        for y in y0...foot {
            for x in (cx - hw)...(cx + hw) {
                let n = Double(x - cx) / Double(max(1, hw))
                c.px(x, y, stone[max(0, min(3, Int(2.4 - n * 1.6)))])
            }
        }
        // The dome: a half-ellipse a little wider than the wall, lit on the left, a pale catch-light.
        let dr = hw + 1, dh = hw + 1
        for j in 0...dh {
            let k = Double(j) / Double(dh), half = Int((Double(dr) * (1 - k * k).squareRoot()).rounded())
            for x in (cx - half)...(cx + half) {
                c.px(x, y0 - j, Double(x - cx) < Double(half) * 0.25 ? dome.lit : dome.dark)
            }
        }
        c.rect(cx - dr, y0, dr * 2 + 1, 1, dome.dark)
        c.px(cx - dr / 2, y0 - dh / 2 - 1, C(0xFFF0F8, 0.85))
        if top == 0 { c.rect(cx, y0 - dh - 3, 1, 3, dome.dark); c.px(cx, y0 - dh - 4, C(0xFFE080)) }
        else { c.rect(cx, y0 - dh - 1, 1, 1, dome.dark); c.rect(cx - 1, y0 - dh - 3, 2, 2, dome.lit) }
        // A round door, dark, and a round window glowing warm.
        if wall >= 4 {
            c.rect(cx - 1, foot - 2, 2, 3, C(0x2A1838)); c.px(cx - 1, foot - 3, C(0x2A1838))
            if hw >= 4 { c.rect(cx + hw / 2, y0 + 1, 2, 2, C(0xFFD870)); c.px(cx + hw / 2 + 1, y0 + 2, C(0xD89A40)) }
        }
    }

    /// The top of the village's knoll over column `x` of its canvas: a broad mound, highest in the middle.
    private static func eterniaTrollaKnoll(_ x: Int) -> Int { 34 + Int(21 * pow(abs(Double(x) - 100) / 96, 1.4)) }

    /// The houses round the knoll, so the moving layer can make their windows flicker: each one's middle, how far
    /// into the knoll its foot sits (`sink`), its half width, wall, dome colours and top.
    private static let eterniaTrollaHouses: [(cx: Int, sink: Int, hw: Int, wall: Int, dome: Int, top: Int)] = [
        (78, 1, 5, 6, 4, 0), (122, 1, 5, 6, 2, 1), (64, 1, 6, 7, 1, 1), (136, 1, 6, 7, 3, 0), (47, 2, 6, 7, 0, 0),
        (153, 2, 6, 7, 4, 1), (86, 9, 4, 5, 3, 1), (114, 9, 4, 5, 0, 0), (32, 2, 6, 6, 2, 1), (168, 2, 6, 6, 1, 0),
        (22, 4, 5, 5, 3, 0), (178, 4, 5, 5, 0, 1), (62, 12, 5, 6, 4, 1), (138, 12, 5, 6, 2, 0), (42, 10, 4, 4, 1, 0),
        (158, 10, 4, 4, 3, 1),
    ]

    /// The village, one pixel to a unit on a 200×56 canvas, its foot on row 55: a broad knoll of moon rock, the little
    /// houses crowding its slopes, steps up to the tall house at the top with its onion dome and star.
    static func eterniaTrollaVillage(_ c: PixelCanvas) {
        let rock = [C(0x2C2240), C(0x3A2E52), C(0x4A3C64), C(0x5E4E7A), C(0x76648E)]
        // The knoll: a broad mound, lit on the left, rocks along its brow.
        for x in 3..<197 {
            let t = eterniaTrollaKnoll(x)
            guard t < 56 else { continue }
            for y in t..<56 {
                let side = Double(100 - x) / 100 * 0.3, depth = Double(y - t) / 20
                c.px(x, y, eternia5Dither(rock, 0.62 + side - depth * 0.5, x, y, grain: 0.22))
            }
            c.px(x, t, rock[4])
        }
        // Steps up the middle to the tall house.
        for (i, y) in stride(from: 54, through: 38, by: -2).enumerated() {
            let w = 14 - i
            c.rect(100 - w / 2, y, w, 1, rock[4]); c.rect(100 - w / 2, y + 1, w, 1, rock[2])
        }
        // The tall house: a broad round tower of pale stone, an onion dome of rose and gold, a spire with a star.
        let stone = [C(0x5A4A6A), C(0x7E6C88), C(0xA492A8), C(0xC4B4C0)]
        for y in 18...37 {
            for x in 91...109 {
                let n = Double(x - 100) / 9
                c.px(x, y, stone[max(0, min(3, Int(2.4 - n * 1.6)))])
            }
        }
        c.rect(90, 26, 21, 1, stone[0]); c.rect(90, 25, 21, 1, stone[3])
        // Its windows, round, glowing, and the door.
        for (x, y) in [(94, 29), (98, 21), (105, 29), (102, 21)] { c.rect(x, y, 2, 2, C(0xFFD870)); c.px(x + 1, y + 1, C(0xD89A40)) }
        c.rect(98, 31, 5, 7, C(0x2A1838)); c.rect(99, 30, 3, 1, C(0x2A1838)); c.px(98, 31, stone[0])
        // The onion dome: swelling out over the tower and drawing in to a point.
        for j in 0..<16 {
            let k = Double(j) / 15
            let bulge = k < 0.4 ? sin(0.5 + k / 0.4 * (Double.pi / 2 - 0.5)) : pow(1 - (k - 0.4) / 0.6, 0.65)
            let half = Int((12 * bulge).rounded())
            let y = 17 - j
            for x in (100 - half)...(100 + half) {
                let n = Double(x - 100) / Double(max(1, half))
                let band = j == 2 || j == 6
                c.px(x, y, band ? C(0xE8B850) : n < -0.2 ? C(0xD07AA8) : n < 0.5 ? C(0xA85486) : C(0x6E2E5A))
            }
        }
        c.px(95, 10, C(0xFFE0F0)); c.px(94, 11, C(0xF0B0D0)); c.px(94, 12, C(0xF0B0D0))
        c.rect(100, 0, 1, 3, C(0xE8B850))
        // The other houses round the knoll, the far ones first.
        for h in eterniaTrollaHouses.sorted(by: { eterniaTrollaKnoll($0.cx) + $0.sink < eterniaTrollaKnoll($1.cx) + $1.sink }) {
            eterniaTrollaHouse(c, h.cx, eterniaTrollaKnoll(h.cx) + h.sink, h.hw, h.wall, eterniaTrollaDomes[h.dome], top: h.top)
        }
        // Little round lamps on posts along the steps.
        for x in [91, 109] { c.rect(x, 44, 1, 6, rock[0]); c.rect(x - 1, 42, 3, 2, C(0xFFE8A0)) }
    }

    /// Trolla's life: the nearer moons orbiting slowly round the sky, passing in front of the stars; a star
    /// twinkling on the tall house's spire; sparkles of Trollan magic winking on and off in the air, and the windows
    /// flickering warm.
    static func eterniaTrollaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaTrollaFrame(c, g), q = f.q, tall = isTall(c)
        // Little moons orbiting: each on a tilted ellipse round the sky, kept up above the village.
        let orbit = (cx: c.w / 2, cy: tall ? (f.y - 20 * q) / 2 + 10 * q : 10 * s, rx: c.w * 44 / 100, ry: tall ? f.y / 3 : 6 * s)
        let moons: [(col: Px, dark: Px, r: Int, speed: Double)] = [
            (C(0xF4E4B0), C(0xB09A6A), 3, 0.05), (C(0x9AE4F4), C(0x4A8AA4), 2, -0.07), (C(0xF4B0D4), C(0xA45A8A), 2, 0.09),
        ]
        for (k, m) in moons.enumerated() {
            let a = t * m.speed + Double(k) * 2.1
            let x = orbit.cx + Int(cos(a) * Double(orbit.rx)), y = orbit.cy + Int(sin(a) * Double(orbit.ry) * (1 - Double(k) * 0.2))
            let r = m.r * s * (tall ? 2 : 1)
            c.circle(x, y, r, m.dark); c.circle(x - r / 4, y - r / 4, max(1, r * 3 / 4), m.col)
        }
        // The star on the spire, twinkling.
        let pulse = 0.6 + 0.4 * sin(t * 2.2)
        let sx = f.x + 100 * q, sy = f.y - q
        eternia5Twinkle(c, sx, sy, Int(Double(3 * q) * pulse) + q, max(1, q / 2), C(0xFFE890, 0.9))
        // Sparkles: little twinkles winking on in the air over the village and fading.
        let cols = [C(0xFFE080), C(0xF4A0D8), C(0x90F0F0), C(0xFFFFFF)]
        for k in 0..<(tall ? 22 : 10) {
            let ph = (t * 0.5 + noise(k * 7 + 90) * 3).truncatingRemainder(dividingBy: 1)
            let cycle = Int(t * 0.5 + noise(k * 7 + 90) * 3)
            let x = Int(noise(k * 7 + cycle * 31 + 91) * Double(c.w))
            let y = Int(noise(k * 7 + cycle * 31 + 92) * Double(max(1, f.base - (tall ? 20 : 30) * q)))
            let a = sin(ph * .pi)
            eternia5Twinkle(c, x, y, max(1, Int(a * Double(2 * max(1, q)))), max(1, q / 2), cols[k % 4].alpha(0.9 * a))
        }
        // The windows: now and then one flickers brighter, as a lamp inside is turned up.
        for (i, h) in eterniaTrollaHouses.enumerated() where h.wall >= 4 && h.hw >= 4 {
            guard noise(Int(t * 3) * 11 + i * 29) > 0.8 else { continue }
            let foot = eterniaTrollaKnoll(h.cx) + h.sink
            c.rect(f.x + (h.cx + h.hw / 2) * q, f.y + (foot - h.wall + 1) * q, 2 * q, 2 * q, C(0xFFF4C0, 0.9))
        }
    }
}
