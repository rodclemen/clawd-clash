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
        eterniaAndreenosHive(hive)
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
        // Two leaves, out either side of the stem.
        for (k, side) in [(0.55, -1), (0.75, 1)] {
            let ly = top + Int(Double(h) * k), lw = r * 3 / 2
            for i in 0..<lw {
                let lx = side < 0 ? x - sw / 2 - i : x + sw / 2 + i, th = max(1, Int(Double(r) / 3 * sin(Double(i) / Double(lw) * .pi)))
                c.rect(lx, ly - i / 2 - th / 2, 1, th, i % 4 == 0 ? C(0x4A7A30) : C(0x5A8E38))
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
    /// on top, rows of cells, doorways with ledges, the grand door at the foot and honey hanging from the eaves.
    static func eterniaAndreenosHive(_ c: PixelCanvas) {
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
            for row in 0..<2 {
                let cy = tier.top + 2 + row * 3
                guard cy + 4 < tier.bottom else { continue }
                for cx in stride(from: 60 - hw + 3 + row * 3, to: 60 + hw - 6, by: 6) {
                    let pick = noise(cx * 17 + cy * 5 + i)
                    let fill: Px = pick < 0.45 ? wax[4] : pick < 0.8 ? honey[1] : deep
                    c.pattern(cx, cy, [".RRR.", "RCCCR", "RCCCR", ".RRR."], ["R": wax[1], "C": fill])
                    if pick < 0.45 { c.px(cx + 1, cy + 1, wax[5]) } else if pick < 0.8 { c.px(cx + 1, cy + 1, honey[2]); c.px(cx + 3, cy + 2, honey[0]) }
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

extension Scenes {
    /// Where Granamyr's cliffs stand at Darksmoke: drawn at one pixel to a unit on a 120×56 canvas
    /// (`eterniaDarksmokeCliffs`, 180 wide, wider than the window's strip) and blown up `q` times, their foot on `base`, their canvas's top left at `x`/`y`.
    static func eterniaDarksmokeFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eternia5Scale(c, g)
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 90 * q, base - 55 * q)
    }

    /// The caves in the cliffs, in cliff units: each mouth's middle and its half width and height. The first is
    /// Granamyr's own, at the foot.
    private static let eterniaDarksmokeCaves: [(x: Int, y: Int, rx: Int, ry: Int)] = [
        (90, 48, 11, 10), (44, 22, 4, 4), (128, 29, 5, 4), (72, 31, 3, 3), (152, 41, 4, 4), (26, 40, 3, 4), (106, 19, 3, 3),
    ]
    /// Where smoke comes out of the cliff tops, in cliff units.
    private static let eterniaDarksmokeVents: [(x: Int, y: Int)] = [(44, 4), (86, 10), (100, 9), (140, 17)]

    /// Darksmoke, where Granamyr the dragon lives: a sky thick with smoke, near black overhead and lit dull orange
    /// at the horizon by the fires underground, long banks of grey-violet smoke rolling across it, black crags far
    /// off with ember light along their tops. The cliffs are columns of black basalt standing shoulder to shoulder,
    /// each lit cold grey down its left edge, jointed across, their six-sided tops stepping up to a peak on the left;
    /// caves open in them, dark mouths with a fire glowing deep inside, and Granamyr's great cave at the foot, its
    /// glow the brightest. Stumps of basalt columns stand about the ash plain the crew stands on. On the screen saver
    /// the cliffs stand three times the size and the smoke goes up a long way, dragons gliding across it.
    static func eterniaDarksmoke(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaDarksmokeFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 20 : 8) * q
        c.gradient(0, f.base, C(0x18141E), C(0x7A4632), bands: tall ? 12 : 8)
        // Banks of smoke rolling across the sky: billows of grey-violet, lighter on top, lit ember under.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(0, 12, 46), (50, 6, 50), (20, 26, 44), (68, 24, 36), (2, 42, 38), (54, 40, 44), (26, 58, 34), (78, 60, 26)]
            : [(0, 20, 22), (48, 8, 26), (80, 34, 16), (24, 44, 14)]
        for (k, b) in banks.enumerated() {
            let x = c.w * b.x / 100, y = horizon * b.y / 100, len = b.len * s * (tall ? 2 : 1), t = s * (tall ? 2 : 1)
            let bumps = 4 + k % 3
            for i in 0..<bumps {
                let bx = x + len * (i * 2 + 1) / (bumps * 2), r = (len / bumps) * (6 + Int(noise(k * 9 + i) * 5)) / 10
                c.circle(bx, y - r / 3, r, C(0x3A3442))
                c.circle(bx - r / 4, y - r / 2, r * 2 / 3, C(0x4A4352))
                c.circle(bx - r / 3, y - r * 2 / 3, r / 3, C(0x5C5464))
            }
            c.rect(x + len / 10, y, len * 4 / 5, t, C(0x3A3442)); c.rect(x + len / 5, y + t / 2, len * 3 / 5, t, C(0x7A4232, 0.45))
        }
        // The far crags, black, ember light along their tops, a farther range behind them on the screen saver.
        if tall { eterniaDarksmokeCrags(c, base: horizon - 30 * s, amp: 18 * s, period: 24 * s, seed: 7, bottom: f.base, C(0x2E2632), edge: C(0x4A3438)) }
        eterniaDarksmokeCrags(c, base: horizon, amp: (tall ? 12 : 6) * s, period: (tall ? 16 : 11) * s, seed: 13,
                              bottom: f.base, C(0x1E1A22), edge: C(0x8A4428))
        // The ash plain under the cliffs.
        c.rect(0, horizon + (tall ? 6 : 3) * s, c.w, f.base - horizon, C(0x2A2430))

        // The cliffs, blown up to size.
        let cliffs = PixelCanvas(180, 56)
        eterniaDarksmokeCliffs(cliffs)
        eternia5BlowUp(c, cliffs, f.x, f.y, q)

        // The plain in front: dark ash, plain where the crew stands, a few cracks glowing ember.
        c.gradient(f.base + q, g, C(0x34303A), C(0x2C2832), bands: 3)
        for k in 0..<(c.w / (36 * s) + 1) {
            let x = k * 36 * s + Int(noise(k + 140) * Double(18 * s)), y = f.base + q + Int(noise(k + 141) * Double(max(1, (g - f.base) / 2)))
            c.rect(x, y, (3 + Int(noise(k + 142) * 5)) * s, max(1, q / 2), C(0xD05A22, 0.5))
        }
        // Stumps of basalt columns either side, six-sided tops lit, the nearer ones taller.
        let stumps: [(x: Int, h: Int, w: Int)] = [(2, 16, 6), (7, 10, 5), (11, 6, 4), (16, 3, 4), (84, 4, 4), (89, 7, 5),
                                                  (93, 12, 5), (98, 18, 6)]
        for st in stumps {
            let x = c.w * st.x / 100, w = st.w * q, h = st.h * q
            eterniaDarksmokeColumn(c, x - w / 2, g - h, w, h + q, q)
        }
        c.ground(g, C(0x302C34), edge: C(0x4C4652), speck: C(0x24202A), seed: 53)
    }

    /// A basalt column from (`x`, `top`), `w` wide and `h` tall, `q` pixels a unit: a six-sided top lit pale, the
    /// face lit cold grey down its left, dark down its right, a joint across it now and then.
    private static func eterniaDarksmokeColumn(_ c: PixelCanvas, _ x: Int, _ top: Int, _ w: Int, _ h: Int, _ q: Int) {
        let tone = eterniaDarksmokeRock
        c.rect(x, top, w, h, tone[2])
        c.rect(x, top, max(1, q), h, tone[4]); c.rect(x + max(1, q), top, max(1, q), h, tone[3])
        c.rect(x + w - max(1, q), top, max(1, q), h, tone[0])
        for j in stride(from: top + 7 * q, to: top + h - 2 * q, by: 8 * q) {
            c.rect(x, j, w, max(1, q / 2), tone[1]); c.rect(x, j - max(1, q / 2), max(1, q), max(1, q / 2), tone[5])
        }
        c.rect(x, top, w, max(1, q), tone[4]); c.rect(x + max(1, q), top, max(1, w - 2 * q), max(1, q), tone[5])
        c.rect(x, top + max(1, q), w, max(1, q / 2), tone[1])
    }

    /// Basalt in six tones, darkest first: black, but never so black the crew can't read in front of it.
    private static let eterniaDarksmokeRock = [C(0x141118), C(0x1E1A24), C(0x2C2734), C(0x3A3444), C(0x504858), C(0x6C6478)]

    /// Jagged ranges along the horizon: peaks at every `period` pixels at heights of their own, filled to `bottom`.
    private static func eterniaDarksmokeCrags(_ c: PixelCanvas, base: Int, amp: Int, period: Int, seed: Int, bottom: Int,
                                              _ col: Px, edge: Px) {
        let p = max(1, period)
        for x in 0..<c.w {
            let k = x / p, f = Double(x % p) / Double(p)
            let h0 = noise(k * 31 + seed), h1 = noise((k + 1) * 31 + seed)
            let v = h0 * (1 - f) + h1 * f - 0.45 * sin(f * .pi)
            let top = base - Int(v * Double(amp))
            if top < bottom { c.rect(x, top, 1, bottom - top, col); c.px(x, top, edge) }
        }
    }

    /// Granamyr's cliffs, one pixel to a unit on a 180×56 canvas, their foot on row 55: columns of basalt stepping
    /// up to a peak left of the middle and a shoulder on the right, the caves in them, ledges across.
    static func eterniaDarksmokeCliffs(_ c: PixelCanvas) {
        let tone = eterniaDarksmokeRock, ember = C(0xD86A2A), emberD = C(0x7A3420)
        /// The height of the cliff top over column `x`: a peak on the left, a saddle, a shoulder on the right, low at
        /// the ends.
        func ridge(_ x: Double) -> Double {
            let peak = 51 * exp(-pow((x - 46) / 20, 2)), saddle = 43 * exp(-pow((x - 94) / 22, 2))
            let shoulder = 39 * exp(-pow((x - 140) / 16, 2)), body = 24 * exp(-pow((x - 90) / 78, 4))
            return max(peak, saddle, shoulder, body)
        }
        // The columns, each its own width and height.
        var x = 0
        var k = 0
        while x < 180 {
            let w = 4 + Int(noise(k * 3 + 200) * 3)
            let mid = Double(x) + Double(w) / 2
            let h = Int(ridge(mid) + (noise(k * 3 + 201) - 0.5) * 6)
            let top = max(1, 55 - h)
            if h > 2 {
                for y in top..<56 {
                    for xx in x..<min(180, x + w) {
                        let across = Double(xx - x) / Double(max(1, w - 1))
                        // Lit on the left, the far side of each column in shadow; a little darker low down.
                        let v = 0.72 - 0.6 * across - (y > 44 ? 0.06 : 0)
                        c.px(xx, y, eternia5Dither(tone, v, xx, y, grain: 0.18))
                    }
                }
                c.rect(x, top, 1, 56 - top, tone[4]); c.rect(min(179, x + w - 1), top, 1, 56 - top, tone[0])
                // Joints across the column, each its own heights.
                var j = top + 5 + Int(noise(k * 3 + 202) * 4)
                while j < 54 {
                    c.rect(x, j, w, 1, tone[1]); c.px(x, j - 1, tone[5])
                    j += 6 + Int(noise(j * 7 + k) * 5)
                }
                // The six-sided top: a pale face, its near edge darker.
                c.rect(x, top, w, 1, tone[4]); c.rect(x + 1, top, max(1, w - 2), 1, tone[5]); c.rect(x, top + 1, w, 1, tone[2])
            }
            x += w
            k += 1
        }
        // Ledges across the face, where the dragons perch: lighter, a dark shadow under each.
        for (x0, x1, y) in [(30, 60, 26), (100, 136, 33), (58, 84, 34), (12, 38, 44), (146, 166, 45)] {
            c.rect(x0, y, x1 - x0, 1, tone[5]); c.rect(x0, y + 1, x1 - x0, 1, tone[3]); c.rect(x0 + 1, y + 2, x1 - x0 - 2, 1, tone[0])
        }
        // The caves: arched mouths standing on a ledge, black up under their roofs, the fire glowing up from deep
        // inside, its light spilling out over the sill.
        for (i, cave) in eterniaDarksmokeCaves.enumerated() {
            let top = cave.y - cave.ry, bottom = i == 0 ? 55 : cave.y + cave.ry
            for y in top...bottom {
                for xx in (cave.x - cave.rx)...(cave.x + cave.rx) {
                    let dx = Double(xx - cave.x) / Double(cave.rx), dy = Double(y - cave.y) / Double(cave.ry)
                    guard y >= cave.y || dx * dx + dy * dy <= 1 else { continue }
                    let depth = Double(y - top) / Double(max(1, bottom - top))
                    let glow = max(0, depth - 0.3) / 0.7 * (1 - abs(dx) * 0.6)
                    c.px(xx, y, lerp(C(0x0C0608), i == 0 ? C(0xD0561E) : C(0xB04A1C), glow))
                }
            }
            // The roof's lip over the mouth, dark, and the sill under it, lit by the fire.
            for a in stride(from: Double.pi + 0.2, through: 2 * .pi - 0.2, by: 0.15) {
                c.px(cave.x + Int((cos(a) * Double(cave.rx + 1)).rounded()), cave.y + Int((sin(a) * Double(cave.ry + 1)).rounded()), tone[0])
            }
            if i > 0 {
                c.rect(cave.x - cave.rx - 1, bottom + 1, cave.rx * 2 + 3, 1, ember); c.rect(cave.x - cave.rx, bottom + 2, cave.rx * 2 + 1, 1, emberD)
                c.rect(cave.x - cave.rx - 1, bottom, 1, 1, tone[4])
            }
        }
        // Granamyr's cave: fangs of basalt hanging over its mouth and standing either side, ember-lit.
        for (fx, len) in [(82, 3), (86, 4), (94, 4), (98, 3)] {
            for j in 0..<len { c.rect(fx, 39 + j, max(1, 2 - j / 2), 1, j == len - 1 ? emberD : tone[4]) }
        }
        for fx in [79, 100] { c.rect(fx, 49, 2, 7, tone[3]); c.px(fx + (fx < 90 ? 1 : 0), 49, ember); c.rect(fx + (fx < 90 ? 1 : 0), 50, 1, 6, emberD) }
    }

    /// Darksmoke's life: smoke curling up out of the cliff tops and the caves, embers floating up and drifting, two
    /// great eyes opening now and then in the dark of Granamyr's cave and, on the screen saver, dragons gliding
    /// across the smoke high up.
    static func eterniaDarksmokeLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaDarksmokeFrame(c, g), q = f.q, tall = isTall(c)
        // Smoke from the vents and the upper caves: grey puffs rising, swelling and thinning, lighter than the
        // cliffs so it reads on them.
        let rise = Double((tall ? 40 : 14) * q)
        let sources = eterniaDarksmokeVents.map { ($0.x, $0.y) } + eterniaDarksmokeCaves.dropFirst().prefix(3).map { ($0.x, $0.y - $0.ry) }
        for (i, src) in sources.enumerated() {
            let cx = Double(f.x + src.0 * q), top = Double(f.y + src.1 * q)
            for k in 0..<8 {
                let ph = (t * 0.12 + Double(k) / 8 + Double(i) * 0.17).truncatingRemainder(dividingBy: 1)
                let x = cx - ph * Double(6 * q) + sin(t * 0.7 + Double(k + i)) * Double(q)
                let y = top - ph * rise
                let r = Double(q) * (1 + ph * (tall ? 4 : 2.5))
                let a = min(1, (1 - ph) * 1.4) * 0.6
                c.circle(Int(x), Int(y), Int(r), C(0x5E5664, a))
                c.circle(Int(x - r / 3), Int(y - r / 3), Int(r * 0.55), C(0x7A7280, a))
            }
        }
        // Embers: sparks drifting up out of the great cave, flickering, going out as they climb.
        let cave = eterniaDarksmokeCaves[0]
        for k in 0..<(tall ? 30 : 14) {
            let ph = (t * (0.1 + noise(k * 3 + 70) * 0.08) + noise(k * 3 + 71)).truncatingRemainder(dividingBy: 1)
            let x0 = Double(f.x + (cave.x - cave.rx) * q) + noise(k * 3 + 72) * Double(2 * cave.rx * q)
            let x = x0 + sin(t * 1.1 + Double(k)) * Double(3 * q) + ph * Double((k % 2 == 0 ? 8 : -8) * q)
            let y = Double(f.y + (cave.y - cave.ry) * q) - ph * Double((tall ? 70 : 40) * q)
            guard y > 0, noise(Int(t * 8) + k * 13) > 0.15 else { continue }
            let sz = max(1, q / 2 + (k % 3 == 0 ? 1 : 0))
            c.rect(Int(x), Int(y), sz, sz, (k % 2 == 0 ? C(0xFFB050) : C(0xF06A28)).alpha(1 - ph * 0.8))
        }
        // Granamyr's eyes, opening in the dark of the cave for a few seconds, then shut again.
        let blink = t.truncatingRemainder(dividingBy: 7.5)
        if blink > 4.5 {
            let open = min(1, (blink - 4.5) * 3, (7.5 - blink) * 3)
            for ex in [cave.x - 4, cave.x + 3] {
                let x = f.x + ex * q, y = f.y + (cave.y - 3) * q
                c.circle(x + q / 2, y + q / 2, 2 * q, C(0xF0D040, 0.18 * open))
                c.rect(x - q, y, 3 * q, max(1, Int(Double(q) * open)), C(0xF8E060))
                c.rect(x, y, max(1, q / 2), max(1, Int(Double(q) * open)), C(0x201008))
            }
        }
        guard tall else { return }
        // Dragons gliding across the smoke high up, black against the grey, wings beating slowly.
        let up = [
            "............W......W...........",
            "...........WW.....WW...........",
            "..........WWW....WWW...........",
            ".........WWWW...WWWW...........",
            "........WWWWW..WWWWW.......HHH.",
            ".......WWWWWW.WWWWWW......HHHHH",
            "S.......BBBBBBBBBBBNNNNNNNH....",
            "SS.TTTTTBBBBBBBBBB......H......",
            ".S......L.....L................",
        ]
        let down = [
            "...........................HHH.",
            "..........................HHHHH",
            "S.......BBBBBBBBBBBNNNNNNNH....",
            "SS.TTTTTBBBBBBBBBB......H......",
            ".S.....WWWWWW.WWWWWW...........",
            "........WWWWW..WWWWW...........",
            ".........WWWW...WWWW...........",
            "..........WWW....WWW...........",
            "...........WW.....WW...........",
        ]
        let horizon = f.base - 20 * q
        for k in 0..<3 {
            let b = max(1, q * (4 - k) / 4), speed = 0.012 + Double(k) * 0.006, dir = k == 1 ? -1.0 : 1.0
            let span = Double(c.w + 40 * b)
            var x = (t * speed * span + Double(k) * span * 0.41).truncatingRemainder(dividingBy: span)
            if dir < 0 { x = span - x }
            let y = Double(horizon) * (0.08 + Double(k) * 0.2) + sin(t * 0.4 + Double(k)) * Double(4 * b)
            let flap = Int(t * (1.2 + Double(k) * 0.3)) % 2 == 0
            eternia5Pattern(c, Int(x) - 31 * b, Int(y) + (flap ? 0 : 2 * b), b, flap ? up : down,
                            ["W": C(0x120C16), "B": C(0x120C16), "H": C(0x120C16), "T": C(0x120C16), "L": C(0x120C16), "N": C(0x120C16), "S": C(0x120C16)], flip: dir < 0)
        }
    }
}

// MARK: - Trolla

extension Scenes {
    /// Where the village stands on Trolla: drawn at one pixel to a unit on a 120×56 canvas (`eterniaTrollaVillage`)
    /// and blown up `q` times, its foot on `base`, its canvas's top left at `x`/`y`.
    static func eterniaTrollaFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eternia5Scale(c, g)
        let base = g - (isTall(c) ? 12 : 7) * q
        return (q, base, c.w / 2 - 60 * q, base - 55 * q)
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
        let outliers: [Int] = tall ? [] : [7, 18, 82, 93]
        for (k, at) in outliers.enumerated() {
            let art = PixelCanvas(12, 15)
            eterniaTrollaHouse(art, 6, 14, 3 + k % 2, 3 + k % 2, eterniaTrollaDomes[(k * 3 + 1) % eterniaTrollaDomes.count], top: k % 2)
            eternia5BlowUp(c, art, c.w * at / 100 - 6 * q, lip(c.w * at / 100) - 13 * q + (k % 2) * q, q)
        }

        // The village, blown up to size.
        let village = PixelCanvas(120, 56)
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

    /// Where the windows are on the village canvas, so the moving layer can make them flicker.
    private static let eterniaTrollaHouses: [(cx: Int, foot: Int, hw: Int, wall: Int, dome: Int, top: Int)] = [
        (14, 52, 4, 4, 2, 1), (26, 50, 6, 6, 0, 0), (40, 46, 5, 6, 1, 1), (80, 46, 5, 6, 3, 0), (94, 50, 6, 6, 4, 1),
        (106, 52, 4, 4, 1, 0), (49, 40, 4, 5, 4, 0), (71, 40, 4, 5, 2, 1), (33, 54, 3, 3, 3, 0), (87, 54, 3, 3, 0, 1),
    ]

    /// The village, one pixel to a unit on a 120×56 canvas, its foot on row 55: a knoll of moon rock, the little
    /// houses round its slopes, steps up to the tall house at the top with its onion dome and star.
    static func eterniaTrollaVillage(_ c: PixelCanvas) {
        let rock = [C(0x2C2240), C(0x3A2E52), C(0x4A3C64), C(0x5E4E7A), C(0x76648E)]
        // The knoll: a broad mound, lit on the left, rocks along its brow.
        func top(_ x: Int) -> Int { 38 + Int(17 * pow(abs(Double(x) - 60) / 58, 1.5)) }
        for x in 2..<118 {
            let t = top(x)
            guard t < 56 else { continue }
            for y in t..<56 {
                let side = Double(60 - x) / 60 * 0.3, depth = Double(y - t) / 18
                c.px(x, y, eternia5Dither(rock, 0.62 + side - depth * 0.5, x, y, grain: 0.22))
            }
            c.px(x, t, rock[4])
        }
        // Steps up the middle to the tall house.
        for (i, y) in stride(from: 54, through: 42, by: -2).enumerated() {
            let w = 12 - i
            c.rect(60 - w / 2, y, w, 1, rock[4]); c.rect(60 - w / 2, y + 1, w, 1, rock[2])
        }
        // The tall house: a round tower of pale stone, an onion dome of rose and gold, a spire with a star.
        let stone = [C(0x5A4A6A), C(0x7E6C88), C(0xA492A8), C(0xC4B4C0)]
        for y in 18...40 {
            for x in 54...66 {
                let n = Double(x - 60) / 6
                c.px(x, y, stone[max(0, min(3, Int(2.4 - n * 1.6)))])
            }
        }
        c.rect(53, 26, 15, 1, stone[0]); c.rect(53, 25, 15, 1, stone[3])
        // Its windows, round, glowing, and the door.
        for (x, y) in [(57, 29), (62, 29), (59, 21)] { c.rect(x, y, 2, 2, C(0xFFD870)); c.px(x + 1, y + 1, C(0xD89A40)) }
        c.rect(58, 35, 4, 6, C(0x2A1838)); c.rect(59, 34, 2, 1, C(0x2A1838)); c.px(58, 35, stone[0])
        // The onion dome: swelling out over the tower and drawing in to a point.
        for j in 0..<16 {
            let k = Double(j) / 15
            let bulge = k < 0.4 ? sin(0.5 + k / 0.4 * (Double.pi / 2 - 0.5)) : pow(1 - (k - 0.4) / 0.6, 0.65)
            let half = Int((9 * bulge).rounded())
            let y = 17 - j
            for x in (60 - half)...(60 + half) {
                let n = Double(x - 60) / Double(max(1, half))
                let band = j == 2 || j == 6
                c.px(x, y, band ? C(0xE8B850) : n < -0.2 ? C(0xD07AA8) : n < 0.5 ? C(0xA85486) : C(0x6E2E5A))
            }
        }
        c.px(56, 10, C(0xFFE0F0)); c.px(55, 11, C(0xF0B0D0))
        c.rect(60, 0, 1, 3, C(0xE8B850))
        // The other houses round the knoll, the far ones first.
        for h in eterniaTrollaHouses.sorted(by: { $0.foot < $1.foot }) {
            eterniaTrollaHouse(c, h.cx, h.foot, h.hw, h.wall, eterniaTrollaDomes[h.dome], top: h.top)
        }
        // Little round lamps on posts along the steps.
        for x in [52, 68] { c.rect(x, 44, 1, 6, rock[0]); c.rect(x - 1, 42, 3, 2, C(0xFFE8A0)) }
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
        let sx = f.x + 60 * q, sy = f.y - q
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
            c.rect(f.x + (h.cx + h.hw / 2) * q, f.y + (h.foot - h.wall + 1) * q, 2 * q, 2 * q, C(0xFFF4C0, 0.9))
        }
    }
}
