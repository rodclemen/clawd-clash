import Foundation

// More places on Etheria: Glimmer's Bright Moon and Clawdstaspella's Mystacor, drawn the same way as
// EterniaScenes1.swift. Each landmark is drawn once at one pixel to a unit on a canvas of its own and blown up `q`
// times, so it's the whole picture on the screen saver and still fits the window's strip. Etheria's pastels, kept far
// from the Crystal Castle's night blues: Bright Moon is white marble and rose-pink roofs at moonrise, a lake in front,
// and Mystacor a city of white towers and violet domes on floating rocks, in a peach and aqua sky over a sea of cloud.

let eterniaScenes7: [Location: Place] = [
    .eterniaBrightMoon: Place(name: "Bright Moon", panel: 0x1C1630, still: Scenes.eterniaBrightMoon,
                              moving: Scenes.eterniaBrightMoonLife),
    .eterniaMystacor: Place(name: "Mystacor", panel: 0x18203A, still: Scenes.eterniaMystacor,
                            moving: Scenes.eterniaMystacorLife),
]

// MARK: - Shared

extension Scenes {
    /// How many times a landmark drawn `w` units wide is blown up: once in the window, three times or more on the
    /// screen saver (the same rule as Greyskull's).
    private static func eterniaPlaces7Q(_ c: PixelCanvas, _ g: Int, _ w: Int) -> Int {
        max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * w)))
    }

    /// Copies `art` onto `c` with its top left at (`x`, `y`), each of its pixels a `q`×`q` block, faded to `alpha`.
    private static func eterniaPlaces7Blit(_ c: PixelCanvas, _ art: PixelCanvas, _ x: Int, _ y: Int, _ q: Int,
                                           alpha: Double = 1) {
        for yy in 0..<art.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
            for xx in 0..<art.w where art.buf[(yy * art.w + xx) * 4 + 3] > 0 {
                let p = unpremultiplied(art, (yy * art.w + xx) * 4)
                c.rect(x + xx * q, y + yy * q, q, q, alpha < 1 ? p.alpha(alpha) : p)
            }
        }
    }

    /// An onion dome's half-width, as a share of its widest, `k` of the way up from its foot (0) to its point (1):
    /// pinched a little at the foot, swelling round, then drawn up into a fine point.
    private static func eterniaPlaces7Onion(_ k: Double) -> Double {
        min(1, pow(max(0, sin(.pi * k)), 0.7) * pow(max(0, 1 - k), 0.5) * 1.6)
    }

    /// Mystacor's onion domes, the same way: a waist a little narrower than the widest at the foot, swelling to the
    /// widest a quarter of the way up, then curving in smoothly (no straight sides) and drawn up into a fine point.
    private static func eterniaPlaces7Bulb(_ k: Double) -> Double {
        if k < 0.28 { return 0.74 + 0.26 * sin(k / 0.28 * .pi / 2) }
        return pow(cos((k - 0.28) / 0.72 * .pi / 2), 1.5)
    }

    /// The first row of `art` with anything drawn on it.
    private static func eterniaPlaces7Top(_ art: PixelCanvas) -> Int {
        for y in 0..<art.h { for x in 0..<art.w where art.buf[(y * art.w + x) * 4 + 3] > 0 { return y } }
        return 0
    }

    /// A little four-pointed twinkle at (x, y), arms `r` long and `t` thick.
    private static func eterniaPlaces7Twinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ t: Int, _ col: Px) {
        c.rect(x - r, y, 2 * r + t, t, col); c.rect(x, y - r, t, 2 * r + t, col)
        c.rect(x - t, y - t, 3 * t, 3 * t, col)
    }
}

// MARK: - Bright Moon

extension Scenes {
    /// Where things stand at Bright Moon: the palace drawn on a 120×56 canvas and blown up `q` times, standing on the
    /// far shore of the lake at `shore`, its canvas's top left at `x`/`y`; the moon behind it, centred at `moon` with
    /// radius `mr`.
    static func eterniaBrightMoonFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, shore: Int, x: Int, y: Int,
                                                                       moon: (x: Int, y: Int), mr: Int) {
        let q = eterniaPlaces7Q(c, g, 120), tall = isTall(c)
        let shore = g - (tall ? 12 : 7) * q
        let x = c.w / 2 - 60 * q, y = shore - 55 * q
        let mr = (tall ? 30 : 21) * q
        return (q, shore, x, y, (c.w / 2 + (tall ? 18 : 30) * q, y + (tall ? 14 : 20) * q), mr)
    }

    /// Bright Moon at moonrise: a sky banded from deep violet down to rose, and a huge moon rising behind the palace,
    /// pale cream with lilac seas, haloed. Glimmer's palace is white marble, rounded towers in pairs either side of a
    /// tall middle one, each under a rose-pink cone or onion dome tipped with a crystal; the Moonstone itself floats
    /// glowing over the middle spire. A great hall runs along the front, its arched windows lit pink-gold, a gold
    /// crescent over the open gate. It stands on a ledge of lilac rock over a still lake that mirrors it; the crew
    /// stands on the near terrace of dusky flagstones. On the screen saver the palace stands three times the size,
    /// the moon huge behind it and the stars out over pastel clouds.
    static func eterniaBrightMoon(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaBrightMoonFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.shore - (tall ? 16 : 6) * q
        c.gradient(0, horizon, C(0x221A4E), C(0xD884AE), bands: tall ? 12 : 8)
        c.gradient(horizon, f.shore, C(0xD884AE), C(0xF0A8B8), bands: 2)
        c.stars(0, horizon * (tall ? 6 : 4) / 10, density: tall ? 55 : 70, seed: 71)
        // The moon: soft rings of halo, a cream disc, lilac seas, a rim shaded on the lower right.
        let m = f.moon, r = f.mr
        for (k, a) in [(1.7, 0.08), (1.4, 0.12), (1.18, 0.18)] { c.circle(m.x, m.y, Int(Double(r) * k), C(0xFFE8F4, a)) }
        c.circle(m.x, m.y, r, C(0xF4E6D8))
        c.circle(m.x + r / 10, m.y + r / 10, r * 9 / 10, C(0xFAF0E4))
        // The seas: soft lilac blotches, each a cluster of overlapping ovals, so they read as markings, not bubbles.
        let seas: [(x: Int, y: Int, rx: Int, ry: Int)] = [
            (-34, -22, 20, 13), (-20, -30, 14, 9), (-42, -6, 10, 12), (16, -36, 12, 7), (28, -26, 9, 8),
            (20, 10, 22, 12), (34, 22, 12, 10), (6, 24, 10, 6), (-18, 34, 14, 7), (-30, 22, 8, 6),
        ]
        for p in seas { c.ellipse(m.x + r * p.x / 100, m.y + r * p.y / 100, r * p.rx / 100, r * p.ry / 100, C(0xE0CCD8)) }
        // A few craters: a shaded bowl, its lower rim lit.
        for (dx, dy, rr) in [(-8, -12, 6), (40, -2, 5), (-36, 40, 4), (2, 44, 5), (-50, -30, 3)] {
            let cx = m.x + r * dx / 100, cy = m.y + r * dy / 100, cr = max(1, r * rr / 100)
            c.circle(cx, cy, cr, C(0xCCB6CA)); c.circle(cx + cr / 3, cy + cr / 3, max(1, cr * 2 / 3), C(0xF6EAE0))
        }
        // The rim on the lower right in a crescent of shade.
        for y in (m.y - r)...(m.y + r) {
            for x in (m.x - r)...(m.x + r) {
                let dx = x - m.x, dy = y - m.y
                guard dx * dx + dy * dy <= r * r else { continue }
                let ex = dx + r / 7, ey = dy + r / 7
                if ex * ex + ey * ey > r * r * 81 / 100 { c.px(x, y, C(0xC0A8C8, 0.6)) }
            }
        }
        // Long pastel clouds drifting across, lilac on top and lit pink underneath.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(4, 26, 30), (60, 18, 22), (80, 44, 34), (16, 54, 26), (40, 68, 20)]
            : [(4, 40, 18), (78, 24, 14), (60, 62, 12)]
        for b in banks {
            let x = c.w * b.x / 100, y = horizon * b.y / 100, len = b.len * s * (tall ? 2 : 1), t = s * (tall ? 2 : 1)
            c.rect(x, y, len, t, C(0xB088C4)); c.rect(x + len / 8, y - t, len * 5 / 8, t, C(0x9A78B8))
            c.rect(x + len / 10, y + t, len * 4 / 5, t, C(0xF4B4CC)); c.rect(x + len / 4, y + 2 * t, len / 3, t, C(0xF4B4CC, 0.6))
        }
        // Far hills in lilac, the nearer deeper.
        c.dunes(base: horizon, amp: Double(4 * s), freq: 0.05 / Double(s), phase: 1.3, bottom: f.shore, C(0xA078A8), shade: C(0xB88CB8))
        c.dunes(base: horizon + (tall ? 8 : 4) * s, amp: Double(3 * s), freq: 0.09 / Double(s), phase: 3.0, bottom: f.shore,
                C(0x7A5A8C), shade: C(0x8E6CA0))

        // The palace, blown up to size.
        let palace = PixelCanvas(120, 56)
        eterniaBrightMoonPalace(palace)
        eterniaPlaces7Blit(c, palace, f.x, f.y, q)

        // The lake: deep violet, mirroring the palace and the sky, dimmed and broken by ripples.
        let lakeTop = f.shore, lake = C(0x2E2856)
        c.rect(0, lakeTop, c.w, g - lakeTop, lake)
        for y in lakeTop..<g {
            let src = lakeTop - 1 - (y - lakeTop) * 3 / 2
            guard src >= 0 else { continue }
            let ripple = (y - lakeTop) / max(1, q) % 3 == 1
            for x in 0..<c.w {
                let i = (src * c.w + x) * 4
                let p = Px(r: c.buf[i], g: c.buf[i + 1], b: c.buf[i + 2], a: 255)
                c.px(x + (ripple ? q : 0), y, p.alpha(ripple ? 0.22 : 0.38))
            }
        }
        // Lily pads and a reed or two at the lake's ends.
        for k in 0..<(c.w / (40 * s) + 1) {
            let x = k * 40 * s + Int(noise(k + 730) * Double(20 * s)), y = lakeTop + (g - lakeTop) * (1 + k % 3) / 4
            guard x < c.w * 22 / 100 || x > c.w * 78 / 100 else { continue }
            c.ellipse(x, y, 2 * q, max(1, q / 2), C(0x3E7A6A)); c.px(x + q, y - max(1, q / 2), C(0xF0A0C8))
        }
        // The near terrace: dusky lilac flagstones, plain and darker where the crew stands.
        c.ground(g, C(0x3E3458), edge: C(0x6A5A88), speck: C(0x332A4A), seed: 73)
        for x in stride(from: Int(noise(3) * Double(9 * s)), to: c.w, by: 18 * s) { c.rect(x, g + 1, max(1, s), c.h - g - 1, C(0x342C4C)) }
        // Crystal lamps on posts at the terrace's far ends, glowing pink.
        for x in [c.w * 3 / 100, c.w * 97 / 100] {
            let ph = 9 * s
            c.rect(x - s, g - ph, 2 * s, ph, C(0x5A4A78)); c.rect(x - s, g - ph, s, ph, C(0x7A6A98))
            c.rect(x - 2 * s, g - ph - s, 4 * s, s, C(0xC8A048))
            c.rect(x - s, g - ph - 5 * s, 2 * s, 4 * s, C(0xE070B0)); c.rect(x - 2 * s, g - ph - 4 * s, 4 * s, 2 * s, C(0xE070B0))
            c.rect(x - s, g - ph - 4 * s, s, 2 * s, C(0xFFD0EC))
        }
    }

    /// The palace on its ledge, one pixel to a unit on a 120×56 canvas, its foot on row 55: the towers in pairs out
    /// from the middle, the great hall in front, the Moonstone over the middle spire.
    static func eterniaBrightMoonPalace(_ c: PixelCanvas) {
        // Marble in six tones, darkest first, lilac in the shade; rose roofs in five; gold; the windows' glow.
        let marble = [C(0x5A4A7A), C(0x76669A), C(0x9888BA), C(0xBCAED6), C(0xDCD2EC), C(0xF8F2FF)]
        let roof = [C(0x7A2E6A), C(0xA4448A), C(0xCC66A8), C(0xEC92C6), C(0xFFC4E2)]
        let gold = C(0xF0C860), goldD = C(0xA8822E), glow = C(0xFFC8DC), glowL = C(0xFFF0D8)
        /// A marble pixel: lit by how far left of `cx` it is over `r`, darkening down towards the foot so the hall
        /// behind the crew stays mid-dark, dithered so the tones blend.
        func stone(_ x: Int, _ y: Int, cx: Double, r: Double, lift: Double = 0) {
            let n = (Double(x) - cx) / max(1, r)
            let fall = Double(max(0, y - 30)) / 25 * 0.5
            let v = 0.66 - 0.4 * n + lift - fall + (noise(x * 7 + y * 131) - 0.5) * 0.18
            c.px(x, y, marble[max(0, min(5, Int(v * 5.6)))])
        }
        /// A round tower from `top` to the foot, `hw` either side of `cx`, shaded as a cylinder, a ring of gold
        /// under its roof, lit windows down it.
        func tower(_ cx: Int, _ hw: Int, _ top: Int, windows: [Int]) {
            for y in top..<56 { for x in (cx - hw)...(cx + hw) { stone(x, y, cx: Double(cx), r: Double(hw)) } }
            c.rect(cx - hw - 1, top, 2 * hw + 3, 1, gold); c.rect(cx - hw - 1, top + 1, 2 * hw + 3, 1, goldD)
            c.rect(cx + hw, top + 2, 1, 54 - top, marble[0])
            for wy in windows {
                c.rect(cx - 1, wy, 2, 4, glow); c.px(cx - 1, wy, glowL); c.rect(cx - 1, wy - 1, 2, 1, marble[1])
                c.px(cx - 1, wy + 4, marble[4]); c.px(cx, wy + 4, marble[4])
            }
        }
        /// A pointed cone of rose slate over a tower, `hw` wide at its foot on `base`, `h` tall, lit from the left,
        /// banded, a crystal at its tip (or, with `tip` off, just a gold point, for the Moonstone to float over).
        func cone(_ cx: Int, _ hw: Int, _ base: Int, _ h: Int, tip: Bool = true) {
            for y in (base - h)..<base {
                let half = (hw + 1) * (y - base + h + 1) / h
                for x in (cx - half)...(cx + half) {
                    let k = Double(x - cx) / Double(max(1, half))
                    var t = k < -0.45 ? 3 : k < 0.2 ? 2 : k < 0.7 ? 1 : 0
                    if (y - base) % 3 == 0 && t > 0 && half > 1 { t -= 1 }
                    c.px(x, y, roof[t])
                }
                c.px(cx - half, y, roof[4])
            }
            c.rect(cx - hw - 1, base - 1, 2 * hw + 3, 1, roof[0])
            c.px(cx, base - h - 1, gold)
            if tip { c.px(cx, base - h - 2, C(0xFFB0DC)); c.px(cx, base - h - 3, C(0xFFE4F2)) }
        }
        /// An onion dome over a tower: bulging past it, pinched to a spike, a crystal on top.
        func onion(_ cx: Int, _ hw: Int, _ base: Int) {
            let h = hw * 2 + 4
            for y in (base - h)..<base {
                let k = Double(base - y) / Double(h)
                let bulge = eterniaPlaces7Onion(k) * Double(hw + 2)
                let half = Int(bulge.rounded())
                for x in (cx - half)...(cx + half) {
                    let d = Double(x - cx) / Double(max(1, half))
                    c.px(x, y, roof[d < -0.4 ? 3 : d < 0.25 ? 2 : d < 0.7 ? 1 : 0])
                }
                if half > 0 { c.px(cx - half, y, roof[4]) }
            }
            c.rect(cx, base - h - 3, 1, 3, gold); c.px(cx, base - h - 4, C(0xFFE4F2))
            c.rect(cx - hw - 1, base - 1, 2 * hw + 3, 1, roof[0])
        }

        // The ledge it stands on: lilac rock, lit on its lip, steps down to the water in the middle.
        for x in 4..<116 {
            let lip = 49 + Int(noise(x / 2 + 300) * 2) + (abs(x - 60) > 50 ? (abs(x - 60) - 50) / 2 : 0)
            for y in lip..<56 {
                let v = 0.5 - Double(x - 60) / 120 * 0.4 - Double(y - lip) / 7 * 0.3 + (noise(x * 3 + y * 17) - 0.5) * 0.2
                c.px(x, y, [C(0x3A2C50), C(0x4E3E66), C(0x66547E), C(0x806C96)][max(0, min(3, Int(v * 4)))])
            }
            c.px(x, lip, C(0x9A86B0))
        }
        for k in 0..<4 { c.rect(53 - k * 2, 52 + k, 15 + k * 4, 1, k % 2 == 0 ? marble[3] : marble[2]) }

        // The outer towers, then the next pair in, the onion-domed pair, and the tall middle one.
        tower(13, 3, 34, windows: [38]); tower(107, 3, 34, windows: [38])
        cone(13, 3, 34, 9); cone(107, 3, 34, 9)
        tower(26, 4, 27, windows: [31, 38]); tower(94, 4, 27, windows: [31, 38])
        cone(26, 4, 27, 12); cone(94, 4, 27, 12)
        // Slender bridges on arches from the outer towers in.
        for (x0, x1) in [(16, 22), (98, 104), (30, 38), (82, 90)] {
            c.rect(x0, 33, x1 - x0, 2, marble[3]); c.rect(x0, 33, x1 - x0, 1, marble[4])
            for x in x0..<x1 { let d = abs(Double(x - x0) - Double(x1 - x0 - 1) / 2); if d < 2 { c.px(x, 35, marble[2]) } }
        }
        tower(41, 4, 22, windows: [27, 34]); tower(79, 4, 22, windows: [27, 34])
        onion(41, 4, 22); onion(79, 4, 22)
        tower(60, 7, 26, windows: [])
        cone(60, 7, 26, 12, tip: false)
        // Bright Moon's crescent high on the middle tower, in gold, lit along its outer edge.
        c.pattern(57, 28, [
            "..GGGG.",
            ".GGL...",
            "GGL....",
            "GGL....",
            ".GGL...",
            "..GGGG.",
        ], ["G": gold, "L": goldD])
        c.px(58, 29, C(0xFFF0B0)); c.px(57, 30, C(0xFFF0B0)); c.px(57, 31, C(0xFFF0B0))

        // The great hall across the front: a long block of marble, a balustrade along its top, an arcade of tall
        // arched windows glowing pink-gold, pilasters between them.
        let hallTop = 38
        for y in hallTop..<52 { for x in 18...102 { stone(x, y, cx: 60, r: 70, lift: -0.06) } }
        c.rect(17, hallTop - 1, 87, 1, marble[4]); c.rect(17, hallTop, 87, 1, gold)
        for x in stride(from: 18, to: 103, by: 3) { c.rect(x, hallTop - 3, 1, 2, marble[3]) }
        c.rect(17, hallTop - 4, 87, 1, marble[4])
        for x in stride(from: 22, to: 100, by: 7) where abs(x + 2 - 60) > 7 {
            c.rect(x, 42, 4, 7, glow); c.rect(x + 1, 41, 2, 1, glow); c.rect(x + 1, 43, 1, 6, glowL)
            c.rect(x - 2, 40, 1, 12, marble[4]); c.rect(x + 5, 40, 1, 12, marble[1])
        }
        // The gate under the middle tower: a tall arch, warm light inside, a gold crescent moon over it.
        c.rect(55, 43, 11, 10, marble[0]); c.rect(56, 42, 9, 1, marble[0]); c.rect(57, 41, 7, 1, marble[0])
        c.rect(56, 44, 9, 9, C(0xFFD8B0)); c.rect(57, 43, 7, 1, C(0xFFD8B0)); c.rect(58, 42, 5, 1, C(0xFFD8B0))
        c.rect(59, 45, 3, 8, glowL)

        // Clusters of rose crystal growing out of the ledge at its ends, in front of the outer towers: fat prisms
        // three wide, lit on their left faces, a white point on each, edged in dark plum so they read on the marble.
        /// One prism: its foot on `base`, `h` tall, its tip leaning `lean` over, drawn as a dark silhouette first and
        /// the crystal inside it.
        func prism(_ x: Int, _ base: Int, _ h: Int, _ lean: Int) {
            for pass in 0..<2 {
                for r in 0..<h {
                    let y = base - h + r, cx = x + lean * (h - r) / 5, half = r == 0 ? 0 : 1
                    if pass == 0 { c.rect(cx - half - 1, y - (r == 0 ? 1 : 0), 2 * half + 3, r == 0 ? 2 : 1, C(0x4A1A40)); continue }
                    if r == 0 { c.px(cx, y, C(0xFFF4FA)); continue }
                    let facet = r == h / 3
                    c.px(cx - 1, y, r == 1 ? C(0xFFF4FA) : roof[3]); c.px(cx, y, facet ? roof[4] : roof[2]); c.px(cx + 1, y, roof[0])
                }
            }
        }
        for (x, base, h, lean) in [(6, 52, 10, -1), (12, 52, 8, 1), (9, 53, 15, 0), (17, 53, 6, 1),
                                   (114, 52, 10, 1), (108, 52, 8, -1), (111, 53, 15, 0), (103, 53, 6, -1)] {
            prism(x, base, h, lean)
        }

        // The Moonstone, floating over the middle spire: a big pink crystal, faceted and lit on its left, edged in
        // dark plum so it reads on the night sky and on the moon both, a soft glow round it.
        c.circle(60, 6, 9, C(0xFFB0DC, 0.2)); c.circle(60, 6, 7, C(0xFFD0EC, 0.22))
        let stone = [
            ".....W.....",
            "....WLP....",
            "...WLLPM...",
            "..WLLLPPM..",
            ".WLLWLPPMM.",
            "WLLLLPPPMMD",
            ".LLLLPPMMD.",
            "..LLLPPMD..",
            "...LLPMD...",
            "....LPD....",
            ".....D.....",
        ]
        let grid = stone.map { Array($0) }
        func filled(_ x: Int, _ y: Int) -> Bool { y >= 0 && y < grid.count && x >= 0 && x < 11 && grid[y][x] != "." }
        for y in -1...grid.count {
            for x in -1...11 where !filled(x, y) && (filled(x - 1, y) || filled(x + 1, y) || filled(x, y - 1) || filled(x, y + 1)) {
                c.px(55 + x, 1 + y, C(0x5A1A4A))
            }
        }
        c.pattern(55, 1, stone, ["W": C(0xFFF4FA), "L": C(0xFFC4E6), "P": C(0xF07ABE), "M": C(0xC04A96), "D": C(0x8A2A6E)])
    }

    /// Where the palace's crystals catch the light, in palace units: the Moonstone, the cone tips and finials.
    private static let eterniaBrightMoonGems: [(x: Int, y: Int)] = [
        (60, 1), (56, 5), (59, 28), (13, 22), (107, 22), (26, 12), (94, 12), (41, 6), (79, 6), (9, 38), (111, 38),
    ]

    /// Bright Moon's life: the Moonstone breathing a pink glow, the crystals on the spires twinkling in turn, and the
    /// moon's path across the lake glittering; on the screen saver, motes of light drift up past the towers.
    static func eterniaBrightMoonLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaBrightMoonFrame(c, g), q = f.q, tall = isTall(c)
        let breath = 0.5 + 0.5 * sin(t * 1.1)
        let sx = f.x + 60 * q + q / 2, sy = f.y + 6 * q
        c.circle(sx, sy, Int(Double(9 * q) * (1 + 0.3 * breath)), C(0xFF9AD0, 0.12 + 0.1 * breath))
        c.circle(sx, sy, 4 * q, C(0xFFD0EC, 0.16 + 0.12 * breath))
        for (i, p) in eterniaBrightMoonGems.enumerated() {
            let v = sin(t * 0.8 + Double(i) * 2.1)
            guard v > 0.72 else { continue }
            let r = Int(Double(3 * q) * (v - 0.72) / 0.28) + q, th = max(1, q / 2)
            eterniaPlaces7Twinkle(c, f.x + p.x * q + q / 2, f.y + p.y * q + q / 2, r, th, C(0xFFF0FA, 0.9))
        }
        // The moon's path on the water: short bright dashes under it, coming and going.
        for k in 0..<(tall ? 14 : 6) {
            let y = f.shore + 1 + Int(noise(k * 3 + 500) * Double(g - f.shore - 2))
            let on = sin(t * 1.6 + Double(k) * 1.7) > 0.1
            guard on else { continue }
            let w = (2 + Int(noise(k * 3 + 501) * 4)) * q, x = f.moon.x - w / 2 + Int((noise(k * 3 + 502) - 0.5) * Double(f.mr))
            c.rect(x, y, w, max(1, q / 2), C(0xFFF0E0, 0.55))
        }
        guard tall else { return }
        for k in 0..<12 {
            let ph = (t * 0.05 + noise(k * 5 + 600)).truncatingRemainder(dividingBy: 1)
            let x = Int(noise(k * 5 + 601) * Double(c.w)) + Int(sin(t * 0.7 + Double(k)) * Double(3 * q))
            let y = f.shore - Int(ph * Double(f.shore))
            c.rect(x, y, max(1, q / 2), max(1, q / 2), C(0xFFD8EE, 0.7 * sin(ph * .pi)))
        }
    }
}

// MARK: - Mystacor

extension Scenes {
    /// Where things stand at Mystacor: the cloud sea's top at `sea`, the city's main rock drawn on a 120×56 canvas
    /// and blown up `q` times with its top left at `x`/`y`, and its tallest spire's tip at `spire`.
    static func eterniaMystacorFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, sea: Int, x: Int, y: Int,
                                                                     spire: (x: Int, y: Int)) {
        let q = eterniaPlaces7Q(c, g, 120), tall = isTall(c)
        let sea = g - (tall ? 16 : 9) * q
        let x = c.w / 2 - 60 * q, y = sea - 51 * q
        return (q, sea, x, y, (x + 60 * q + q / 2, y))
    }

    /// The smaller floating rocks round the city, each with a house or tower or two on it: its middle as a percent
    /// across, its top as a percent of the way down to the cloud sea, how big (in 1/3s of `q`), and a seed for what
    /// stands on it. The screen saver's list climbs far up the sky.
    private static func eterniaMystacorIsles(_ tall: Bool) -> [(x: Int, y: Int, k: Int, seed: Int)] {
        tall ? [(9, 42, 3, 1), (90, 30, 3, 2), (27, 8, 2, 3), (72, 0, 2, 4), (6, 20, 1, 5), (50, 2, 1, 6), (94, 14, 1, 7)]
             : [(9, -12, 3, 1), (29, 6, 3, 3), (72, 0, 3, 2), (92, -14, 3, 4)]
    }

    /// Mystacor, the city of sorcerers, high over a sea of cloud in a pastel sky going from periwinkle down through
    /// aqua to peach. The city stands on a great floating rock: cream stone in strata tapering down to a point,
    /// mint grass on top, lilac crystals and roots hanging under it, a waterfall pouring off its edge into the clouds.
    /// On it, white towers under violet domes and cones with gold finials, round lilac windows, and Clawdstaspella's
    /// tower in the middle, tallest of all, an onion dome and a gold spire. Smaller rocks float round it, each with a
    /// house or two, bobbing (they're in the moving layer). The crew stands on the near terrace of slate-blue stone,
    /// a low balustrade at its edge. On the screen saver the city is three times the size, more rocks up the sky.
    static func eterniaMystacor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaMystacorFrame(c, g), q = f.q, tall = isTall(c)
        c.gradient(0, f.sea * 55 / 100, C(0x6E78CE), C(0x9CD4DC), bands: tall ? 9 : 5)
        c.gradient(f.sea * 55 / 100, f.sea, C(0x9CD4DC), C(0xFCDCC0), bands: tall ? 6 : 4)
        // A pale sun low on the left, and soft bands of high cloud.
        let sun = (x: c.w * 14 / 100, y: f.sea * 70 / 100, r: (tall ? 12 : 6) * s)
        for (k, a) in [(2.4, 0.12), (1.6, 0.2)] { c.circle(sun.x, sun.y, Int(Double(sun.r) * k), C(0xFFF4D8, a)) }
        c.circle(sun.x, sun.y, sun.r, C(0xFFF8E4))
        for k in 0..<(tall ? 7 : 3) {
            let x = Int(noise(k + 820) * Double(c.w)), y = f.sea * (10 + Int(noise(k + 821) * 70)) / 100
            wisp(c, x, y, (20 + Int(noise(k + 822) * 30)) * s * (tall ? 2 : 1), C(0xFFFFFF, 0.35), s: s)
        }
        // Far rocks, pale in the haze: little floating islands with a tower or two, small and faded into the sky (only on
        // the screen saver: the window's strip has no room for them).
        let far: [(x: Int, y: Int, seed: Int)] = tall
            ? [(18, 30, 11), (42, 20, 12), (63, 28, 13), (84, 22, 14), (36, 44, 15), (78, 50, 16)]
            : []
        for r in far {
            let art = eterniaMystacorIsle(seed: r.seed), k = max(1, q / 2)
            eterniaPlaces7Blit(c, art, c.w * r.x / 100 - 22 * k, f.sea * r.y / 100, k, alpha: 0.4)
        }

        // The city's rock, blown up to size.
        let city = PixelCanvas(120, 56)
        eterniaMystacorCity(city)
        eterniaPlaces7Blit(c, city, f.x, f.y, q)

        // The cloud sea below: rolling tops lit peach, lilac in the troughs, dusky lower down behind the terrace.
        c.gradient(f.sea, g, C(0x7A72A8), C(0x4E4878), bands: 3)
        for k in 0..<(c.w / (14 * q) + 2) {
            let x = k * 14 * q + Int(noise(k + 840) * Double(8 * q)), r = (5 + Int(noise(k + 841) * 4)) * q
            c.ellipse(x, f.sea + r / 3, r, r / 2, C(0x9A90C4))
            c.ellipse(x - r / 4, f.sea + r / 5, r * 2 / 3, r / 3, C(0xD4B0C4))
            c.ellipse(x + r / 3, f.sea + r * 2 / 3, r, r / 3, C(0x6A6298))
        }
        // The near terrace's balustrade: a low rail of slate-blue posts along its edge.
        let rail = g - 4 * q, stone = C(0x4A5A80), stoneD = C(0x3A4868), stoneL = C(0x6A7AA0)
        c.rect(0, rail, c.w, max(1, q), stoneL); c.rect(0, rail + max(1, q), c.w, max(1, q), stone)
        for x in stride(from: 0, to: c.w, by: 4 * q) {
            c.rect(x, rail + 2 * q, 2 * q, g - rail - 2 * q, stone); c.rect(x, rail + 2 * q, max(1, q / 2), g - rail - 2 * q, stoneL)
            c.rect(x + 2 * q - max(1, q / 2), rail + 2 * q, max(1, q / 2), g - rail - 2 * q, stoneD)
        }
        // The terrace: slate-blue flagstones, plain where the crew stands, a rune ring set in it here and there.
        c.ground(g, C(0x3A4664), edge: C(0x5A6A8E), speck: C(0x303A56), seed: 83)
        for x in stride(from: Int(noise(5) * Double(11 * s)), to: c.w, by: 22 * s) { c.rect(x, g + 1, max(1, s), c.h - g - 1, C(0x323E5A)) }
    }

    /// Draws one floating rock on `c`: its top at `top`, `hw` either side of `cx`, `depth` rows down to its point.
    /// Cream stone in strata lit from the left, mint grass along the top, lilac crystals and roots hanging under it.
    private static func eterniaMystacorRock(_ c: PixelCanvas, _ cx: Int, _ top: Int, _ hw: Int, _ depth: Int, seed: Int) {
        let rock = [C(0x6A5A6A), C(0x8A7682), C(0xAE9A9A), C(0xCCB8AA), C(0xE6D4BE)]
        let grass = [C(0x3E8A78), C(0x5AB094), C(0x8CD6B4)]
        for x in (cx - hw)...(cx + hw) {
            let d = Double(x - cx) / Double(hw)
            let jag = Int(noise(x * 3 + seed * 97) * 3)
            let bottom = top + Int(Double(depth) * pow(max(0, 1 - d * d), 0.7)) - jag
            guard bottom > top else { continue }
            for y in top...bottom {
                let strata = (y + Int(sin(Double(x) * 0.3 + Double(seed)) * 1.5)) % 4 == 0 ? -0.18 : 0
                let v = 0.62 - d * 0.35 - Double(y - top) / Double(max(1, depth)) * 0.45 + strata + (noise(x * 7 + y * 13) - 0.5) * 0.16
                c.px(x, y, rock[max(0, min(4, Int(v * 5)))])
            }
            // Grass along the top, a lit tuft here and there.
            c.px(x, top, grass[1]); c.px(x, top + 1, grass[0])
            if noise(x * 5 + seed) > 0.6 { c.px(x, top - 1, grass[2]) }
            // Roots and crystals hanging underneath.
            if noise(x * 11 + seed * 7) > 0.86 {
                let len = 2 + Int(noise(x * 13 + seed) * 4)
                if noise(x * 17 + seed) > 0.5 {
                    for k in 0..<len { c.px(x + (k > 2 ? 1 : 0), bottom + k, C(0x5A4A4A)) }
                } else {
                    for k in 0..<len { c.rect(x - (len - k) / 3, bottom + k, 1 + 2 * ((len - k) / 3), 1, k == 0 ? C(0xE0C8FF) : C(0xA884E0)) }
                }
            }
        }
    }

    /// A white tower on a floating rock: `w` wide from `base` up `h` rows, lit from the left, round windows glowing
    /// lilac, and a roof (0 a dome, 1 a cone, 2 an onion) of violet with a gold finial.
    private static func eterniaMystacorTower(_ c: PixelCanvas, _ x0: Int, _ w: Int, _ base: Int, _ h: Int, roof: Int) {
        let wall = [C(0x9A92B4), C(0xBEB6D2), C(0xDCD6EA), C(0xF6F2FC)]
        let vio = [C(0x4A2E7E), C(0x6A44A4), C(0x8E66C8), C(0xB896E8)]
        let gold = C(0xF0C860), win = C(0xD8B8FF), deep = C(0x3A2A5A)
        for y in (base - h)..<base {
            for x in x0..<(x0 + w) {
                let k = Double(x - x0) / Double(max(1, w - 1))
                c.px(x, y, wall[k < 0.25 ? 3 : k < 0.6 ? 2 : k < 0.85 ? 1 : 0])
            }
        }
        // Windows: round ones up the middle, a lilac glow in a dark rim.
        let cx = x0 + w / 2
        for wy in stride(from: base - h + 3, to: base - 2, by: 5) {
            c.rect(cx - 1, wy, 2, 2, win); c.px(cx - 1, wy, C(0xF4E8FF))
            c.px(cx - 1, wy - 1, deep); c.px(cx, wy - 1, deep)
        }
        // A door at the foot of the wider ones.
        if w >= 6 { c.rect(cx - 1, base - 3, 3, 3, deep); c.px(cx, base - 4, deep) }
        c.rect(x0 - 1, base - h, w + 2, 1, gold)
        let top = base - h
        switch roof {
        case 0:
            let r = w / 2 + 1
            for dy in 0...r {
                let half = Int((Double(r * r - dy * dy)).squareRoot().rounded())
                for x in (cx - half)...max(cx - half, cx + half - (w % 2 == 0 ? 1 : 0)) { c.px(x, top - 1 - dy, vio[x < cx - half / 2 ? 3 : x < cx + half / 3 ? 2 : 1]) }
            }
            c.rect(cx, top - r - 4, 1, 3, gold)
        case 1:
            let hh = w + 3
            for y in 0..<hh {
                let half = (w / 2 + 1) * (y + 1) / hh
                for x in (cx - half)...(cx + half) { c.px(x, top - hh + y, vio[x < cx ? 3 : x == cx ? 2 : 1]) }
            }
            c.px(cx, top - hh - 1, gold); c.px(cx, top - hh - 2, gold)
        default:
            // An onion: rounded all the way up, lit on its left, a darker rim down the right, a highlight, ribs.
            let hh = w + 5, widest = Double(w) / 2 + 1.6
            for y in 0..<hh {
                let k = (Double(hh - y) - 0.5) / Double(hh)
                let half = Int((eterniaPlaces7Bulb(k) * widest).rounded())
                for x in (cx - half)...(cx + half) {
                    let d = Double(x - cx) / Double(max(1, half))
                    c.px(x, top - hh + y, vio[d < -0.45 ? 3 : d < 0.15 ? 2 : d < 0.65 ? 1 : 0])
                }
                if half > 1 { c.px(cx + half, top - hh + y, vio[0]) }
                // A lit fleck high on the left of the bulb.
                if half > 2, k > 0.18, k < 0.42 { c.px(cx - half + 1, top - hh + y, C(0xDCC4FF)) }
                // A rib up the middle of the bigger domes.
                if w >= 9, half > 1 { c.px(cx, top - hh + y, vio[1]) }
            }
            c.rect(cx - Int(widest * 0.74), top - 1, 2 * Int(widest * 0.74) + 1, 1, vio[0])
            c.rect(cx, top - hh - 4, 1, 4, gold); c.px(cx, top - hh - 5, C(0xFFF0B0))
        }
    }

    /// The city's great rock, one pixel to a unit on a 120×56 canvas: the rock's top on row 36, its point near the
    /// bottom; the waterfall off its left end; the houses and towers on it, Clawdstaspella's in the middle.
    static func eterniaMystacorCity(_ c: PixelCanvas) {
        eterniaMystacorRock(c, 60, 36, 54, 18, seed: 0)
        // The waterfall's lip and fall, pale aqua, pouring off the left end (the moving layer runs streaks down it).
        c.rect(12, 36, 4, 1, C(0x8AD8E8))
        for y in 37..<56 { c.rect(11 - (y - 37) / 8, y, 4, 1, y % 3 == 0 ? C(0xC8F0F8) : C(0x9ADCEC)) }
        // A wall along the back with arches, then the towers, back to front.
        for x in 22..<98 {
            c.rect(x, 30, 1, 6, x % 6 == 0 ? C(0xA49CBE) : C(0xC4BCD8))
            if x % 6 == 3 { c.rect(x, 33, 2, 3, C(0x5A4A7A)) }
        }
        c.rect(22, 29, 76, 1, C(0xF0C860))
        eterniaMystacorTower(c, 20, 6, 36, 14, roof: 1)
        eterniaMystacorTower(c, 92, 7, 36, 16, roof: 0)
        eterniaMystacorTower(c, 30, 8, 36, 10, roof: 0)
        eterniaMystacorTower(c, 80, 8, 36, 12, roof: 1)
        eterniaMystacorTower(c, 42, 6, 36, 20, roof: 2)
        eterniaMystacorTower(c, 72, 6, 36, 22, roof: 2)
        eterniaMystacorTower(c, 103, 5, 36, 8, roof: 1)
        eterniaMystacorTower(c, 9, 5, 36, 7, roof: 0)
        // Clawdstaspella's tower: the tallest, wider, a balcony ring and a big onion dome, a gold spire.
        eterniaMystacorTower(c, 55, 11, 36, 24, roof: 2)
        c.rect(53, 22, 15, 1, C(0xF0C860)); c.rect(53, 23, 15, 1, C(0xA8822E))
        for x in stride(from: 54, to: 67, by: 2) { c.px(x, 21, C(0xDCD6EA)) }
        // Her sigil over the door: a lilac ring with a star in it.
        c.pattern(57, 27, [".LLL.", "L.S.L", "LSSSL", "L.S.L", ".LLL."], ["L": C(0xC8A0FF), "S": C(0xFFF4FF)])
        // Little houses with domes between them.
        for (x, w, h) in [(37, 5, 5), (49, 5, 4), (66, 5, 5), (87, 5, 4)] {
            eterniaMystacorTower(c, x, w, 36, h, roof: 0)
        }
    }

    /// A small floating rock with a house or tower or two on it, on a 44×40 canvas, its grass on row 26; `seed`
    /// picks what stands on it and how tall.
    private static func eterniaMystacorIsle(seed: Int) -> PixelCanvas {
        let art = PixelCanvas(44, 40)
        eterniaMystacorRock(art, 22, 26, 19, 12, seed: seed)
        let kinds = [(14, 6, 9, 2), (24, 7, 12, 1), (31, 5, 6, 0)]
        for (i, kd) in kinds.enumerated() where (seed + i) % 3 != 2 || i == 1 {
            eterniaMystacorTower(art, kd.0 + (seed % 2) * 2 - 1, kd.1, 26, kd.2 + seed % 3 * 2, roof: (kd.3 + seed) % 3)
        }
        return art
    }

    /// Mystacor's life: the smaller rocks bobbing round the city with their towers, the waterfall's streaks running
    /// down, lilac sparks rising from the windows and the spire, and now and then a hypnotic ring rippling out from
    /// the top of Clawdstaspella's tower.
    static func eterniaMystacorLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaMystacorFrame(c, g), q = f.q, tall = isTall(c)
        // The isles, each drawn small and blown up, bobbing on its own beat, never so high that the frame's top cuts
        // off a finial (the window's strip is only just tall enough for them).
        for isle in eterniaMystacorIsles(tall) {
            let k = max(1, q * isle.k / 3)
            let art = eterniaMystacorIsle(seed: isle.seed)
            let lift = Double(k) * 1.4
            let bob = Int((sin(t * 0.7 + Double(isle.seed) * 1.7) * lift).rounded())
            let top = eterniaPlaces7Top(art)
            let x = c.w * isle.x / 100 - 22 * k
            let high: Int = Int(lift.rounded(.up)) + 2 - top * k
            let y: Int = max(f.sea * isle.y / 100, high) + bob
            eterniaPlaces7Blit(c, art, x, y, k, alpha: isle.k < 3 ? 0.9 : 1)
        }
        // The waterfall: pale streaks running down it.
        for k in 0..<6 {
            let ph = (t * 0.6 + Double(k) / 6).truncatingRemainder(dividingBy: 1)
            let y = 37 + Int(ph * 18)
            let x = 11 - (y - 37) / 8 + k % 3
            c.rect(f.x + x * q, f.y + y * q, q, 2 * q, C(0xFFFFFF, 0.7))
        }
        // Sparks: magic rising from the spire and the windows, fading as they climb. Each is a little four-pointed
        // star, its arms a deep, strong violet and its heart white, so it reads on the pale sky and the white towers
        // both (a plain lilac mote vanished into the periwinkle).
        for k in 0..<(tall ? 18 : 10) {
            let ph = (t * 0.18 + noise(k * 7 + 900)).truncatingRemainder(dividingBy: 1)
            let ox = Int(noise(k * 7 + 901) * 100) + 10
            let x = f.x + ox * q + Int(sin(t * 1.2 + Double(k)) * Double(2 * q))
            let y = f.y + (32 - Int(ph * 34)) * q
            let a = min(1, 1.6 * (1 - ph)), th = max(1, (q + 1) / 2), r = q + 1 + (k % 3 == 0 ? th : 0)
            let arm = C(k % 2 == 0 ? 0x8A3CEC : 0xB04ADC, 0.95 * a)
            c.rect(x - r, y, 2 * r + th, th, arm); c.rect(x, y - r, th, r, arm); c.rect(x, y + th, th, r, arm)
            c.rect(x, y, th, th, C(0xFFFFFF, a))
        }
        // The hypnotic ring: every six seconds one ripples out from the spire's tip, lilac, fading.
        let ring = t.truncatingRemainder(dividingBy: 6) / 2.4
        if ring < 1 {
            let rx = Double((6 + Int(ring * 30)) * q), ry = rx * 0.35, a = 0.55 * (1 - ring)
            for st in 0..<Int(rx * 4) {
                let ang = Double(st) / (rx * 4) * 2 * .pi
                c.rect(f.spire.x + Int(cos(ang) * rx), f.spire.y + 2 * q + Int(sin(ang) * ry), max(1, q / 2 + 1), max(1, q / 2 + 1),
                       C(0x9A5AF0, a))
            }
        }
    }
}
