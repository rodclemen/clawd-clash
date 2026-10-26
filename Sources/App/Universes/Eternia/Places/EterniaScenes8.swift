import Foundation

// The last two places: Frosta's Castle Chill on Etheria, and, from the 1987 film, a small town on Earth at night.
// Drawn the same way as EterniaScenes1.swift: the big thing (the ice palace, the main street) is drawn at one pixel
// to a unit and blown up `q` times, once in the window and two to four times on the screen saver. Two palettes far
// apart: the palace's ice blues under a polar twilight, the town's streetlight orange and neon pink on a navy night.

let eterniaScenes8: [Location: Place] = [
    .eterniaCastleChill: Place(name: "Castle Chill", panel: 0x102034, still: Scenes.eterniaCastleChill,
                               moving: Scenes.eterniaCastleChillLife),
    .eterniaEarthTown: Place(name: "Earth", panel: 0x121628, still: Scenes.eterniaEarthTown,
                             moving: Scenes.eterniaEarthTownLife),
]

// MARK: - Shared

extension Scenes {
    /// Copies `art` onto `c` with its top left at (`x`, `y`), each of its pixels a `q`×`q` block.
    private static func eterniaPlaces8Blit(_ c: PixelCanvas, _ art: PixelCanvas, _ x: Int, _ y: Int, _ q: Int) {
        for yy in 0..<art.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
            for xx in 0..<art.w where art.buf[(yy * art.w + xx) * 4 + 3] > 0 {
                c.rect(x + xx * q, y + yy * q, q, q, unpremultiplied(art, (yy * art.w + xx) * 4))
            }
        }
    }
}

// MARK: - Castle Chill

extension Scenes {
    /// Where Castle Chill stands: blown up `q` times (the same rule as Greyskull's), its foot on `base`, its canvas's
    /// top left at `x`/`y`, `w` units wide. In the window, where it can't be blown up, the canvas is wider (200 units)
    /// for the outer walls and towers either side, the palace itself `off` units in. The frozen lake between it and
    /// the crew is wider on the screen saver.
    static func eterniaCastleChillFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int, w: Int, off: Int) {
        let q = max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120)))
        let base = g - (isTall(c) ? 10 : 5) * q
        let w = isTall(c) ? 120 : 200
        return (q, base, c.w / 2 - w / 2 * q, base - 56 * q, w, (w - 120) / 2)
    }

    /// Where the aurora's lower hem runs at column `x`: a long slow swell and a shorter one on top, about `at` of
    /// the way down to the horizon, the swells `amp` pixels high.
    private static func eterniaChillAuroraHem(_ x: Int, _ s: Int, _ horizon: Int, at: Int, amp: Int) -> Int {
        let wave = sin(Double(x) * 0.022 / Double(s)) * Double(amp * 10 / 26 * s) + sin(Double(x) * 0.009 + 1.4) * Double(amp * 16 / 26 * s)
        return horizon * at / 100 + Int(wave)
    }

    /// Ice in eight tones, darkest first: the palace's walls sit in the middle ones, so the crew's white outlines and
    /// pale costumes still read in front of them, and the white is kept for snow, lit edges and points.
    private static let eterniaChillIce = [C(0x162A48), C(0x203E66), C(0x2C5482), C(0x3C6C9C), C(0x5A8CBC),
                                          C(0x86B4D8), C(0xB8DAF0), C(0xEAF6FF)]

    /// Castle Chill: Frosta's ice palace on Etheria's frozen north, under a polar twilight going from deep navy to
    /// cold teal, snowy peaks behind. The palace is built of blocks of blue ice, lit from the left: a curtain wall
    /// with snow-capped merlons and icicles under its walk, two round towers topped with onion domes of clear ice,
    /// squat outer towers with ice cones, and the keep in the middle, crowned with a ring of jagged ice shards like
    /// Frosta's own tiara, a great snowflake on a roundel over the arched gate and windows glowing cold cyan. Icicles
    /// hang from every ledge. The crew stands on the frozen lake in front, dark ice, plain, drifts at the sides. On
    /// the screen saver the palace stands three times the size under the aurora, tall ice pinnacles either side.
    static func eterniaCastleChill(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaCastleChillFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 24 : 9) * q
        c.gradient(0, f.base, C(0x0A1430), C(0x2E6A84), bands: tall ? 12 : 8)
        c.stars(0, horizon * (tall ? 2 : 1) / 3, density: tall ? 60 : 80, seed: 47)
        // The aurora: curtains of green hanging in folds across the sky, streaked with rays, brightest along their
        // lower edges the way the real thing is, a hem of pale mint and a fringe of violet under it. Towering on the
        // screen saver; a lower ribbon of it in the window's strip, over the peaks.
        for x in 0..<c.w {
            let low = eterniaChillAuroraHem(x, s, horizon, at: tall ? 42 : 34, amp: tall ? 26 : 6)
            let len = (tall ? 34 + Int(noise(x / max(1, 2 * s) + 70) * 22) : 9 + Int(noise(x / max(1, 2 * s) + 70) * 7)) * s
            let fold = 0.55 + 0.45 * sin(Double(x) * 0.15 / Double(s))
            let ray = 0.6 + 0.4 * noise(x / max(1, s) + 90)
            for y in max(0, low - len)..<max(0, low) {
                let k = Double(y - (low - len)) / Double(len)
                c.px(x, y, C(0x6CF8AC).alpha((tall ? 0.62 : 0.5) * pow(k, 1.6) * fold * ray))
            }
            c.rect(x, low - s, 1, s, C(0xD4FFE6).alpha(0.75 * fold))
            c.rect(x, low, 1, 2 * s, C(0xB088F0).alpha(0.5 * fold)); c.rect(x, low + 2 * s, 1, s, C(0xB088F0).alpha(0.22 * fold))
        }
        // Far peaks, snow on their tops: a pale range in the haze, a nearer blue one.
        eterniaChillPeaks(c, base: horizon - (tall ? 14 : 4) * s, amp: (tall ? 26 : 9) * s, period: (tall ? 34 : 18) * s, seed: 5,
                          bottom: f.base, rock: C(0x5A7C9C), snow: C(0xB4CCE0), shade: C(0x8AA6C0))
        eterniaChillPeaks(c, base: horizon + (tall ? 8 : 2) * s, amp: (tall ? 16 : 6) * s, period: (tall ? 24 : 13) * s, seed: 12,
                          bottom: f.base, rock: C(0x34506E), snow: C(0x8EAECC), shade: C(0x5E7E9E))
        // The ice pinnacles: leaning spires of glacier ice standing out of the snowfield either side, towering on
        // the screen saver.
        let spires: [(x: Int, h: Int, w: Int, lean: Int)] = tall
            ? [(4, 62, 9, 2), (11, 44, 6, -1), (16, 30, 5, 1), (96, 66, 10, -2), (89, 46, 6, 1), (84, 28, 5, -1)]
            : [(2, 18, 8, 1), (7, 32, 13, 2), (13, 20, 9, -1), (19, 11, 6, 1), (25, 15, 8, 1),
               (98, 20, 8, -1), (93, 34, 13, -2), (87, 22, 9, 1), (81, 11, 6, -1), (75, 15, 8, -1)]
        for p in spires { eterniaChillPinnacle(c, c.w * p.x / 100, f.base, p.h * q, p.w * q, p.lean * q) }
        // The snowfield the palace stands on, banked up to its foot.
        c.dunes(base: f.base - 2 * q, amp: Double(q), freq: 0.05 / Double(q), phase: 0.8, bottom: f.base, C(0x6A8EB0), shade: C(0xA4C2DC))

        // The palace, blown up to size (with its outer walls in the window).
        let art = PixelCanvas(f.w, 56)
        eterniaCastleChillArt(art)
        eterniaPlaces8Blit(c, art, f.x, f.y, q)

        // The frozen lake in front: dark blue ice, plain where the crew stands, a few pale cracks and the palace's
        // glow faint on it; snowdrifts banked at the far sides.
        c.gradient(f.base, g, C(0x2A4A6A), C(0x203852), bands: 3)
        for k in 0..<(c.w / (30 * s) + 1) {
            let x = k * 30 * s + Int(noise(k + 140) * Double(14 * s)), y = f.base + Int(noise(k + 141) * Double(max(1, g - f.base - 1)))
            let len = (5 + Int(noise(k + 142) * 8)) * s
            for i in 0..<len { c.px(x + i, y + (i / max(1, 3 * s)) % 2, C(0x5A82A6)) }
        }
        for (x, w, h) in [(0, 9, 4), (5, 7, 2), (91, 9, 4), (88, 6, 2)] {
            let cx = c.w * x / 100 + c.w * w / 200, rx = c.w * w / 200, ry = h * q
            c.ellipse(cx, g, rx, ry, C(0x9AB8D4)); c.ellipse(cx - rx / 5, g - ry / 3, rx * 3 / 4, ry * 2 / 3, C(0xD4E6F4))
        }
        c.ground(g, C(0x24405C), edge: C(0x4E7496), speck: C(0x1C3450), seed: 37)
    }

    /// Jagged snowy peaks: tops and saddles at uneven spacing (about `period` pixels apart), the rock filled down to
    /// `bottom`, snow above a ragged snowline, lit on the slopes facing left and shaded on the ones facing right.
    private static func eterniaChillPeaks(_ c: PixelCanvas, base: Int, amp: Int, period: Int, seed: Int, bottom: Int,
                                          rock: Px, snow: Px, shade: Px) {
        // The ridge's turning points, alternately a top and a saddle.
        var knots: [(x: Int, y: Int)] = []
        var x = -period, i = 0
        while x < c.w + 2 * period {
            let top = i % 2 == 0
            let hgt = top ? 0.45 + noise(i * 17 + seed) * 0.55 : noise(i * 17 + seed) * 0.3
            knots.append((x, base - Int(hgt * Double(amp))))
            x += max(2, Int(Double(period) * (0.35 + noise(i * 17 + seed + 5) * 0.5)))
            i += 1
        }
        let snowline = base - amp * 45 / 100
        var k = 0
        for x in 0..<c.w {
            while k + 2 < knots.count && knots[k + 1].x <= x { k += 1 }
            let a = knots[k], b = knots[k + 1]
            let fr = Double(x - a.x) / Double(max(1, b.x - a.x))
            let top = a.y + Int(Double(b.y - a.y) * fr) + Int(noise(x / 2 + seed * 31) * 1.6)
            guard top < bottom else { continue }
            let lit = b.y < a.y
            c.rect(x, top, 1, bottom - top, rock)
            let line = snowline + Int(noise(x / 3 + seed * 13) * Double(max(2, amp / 6)))
            if top < line { c.rect(x, top, 1, min(bottom, line) - top, lit ? snow : shade) }
            // A streak of rock showing through the snow now and then, down the fall line.
            if top < line, noise(x * 7 + seed) > 0.86 { c.rect(x, top + (line - top) / 2, 1, (line - top) / 2, rock) }
        }
    }

    /// A pinnacle of glacier ice for the screen saver: `h` pixels tall from `foot`, `w` wide at the foot, leaning
    /// `lean` pixels over at the tip, lit on its left face, a bright edge and a seam of deeper blue up it.
    private static func eterniaChillPinnacle(_ c: PixelCanvas, _ x: Int, _ foot: Int, _ h: Int, _ w: Int, _ lean: Int) {
        let ice = eterniaChillIce
        for y in 0..<h {
            let k = Double(y) / Double(max(1, h)), half = max(0, Int(Double(w) / 2 * k))
            let cx = x + Int(Double(lean) * (1 - k))
            let row = foot - h + y
            guard half > 0 else { c.px(cx, row, ice[7]); continue }
            c.rect(cx - half, row, half, 1, ice[5]); c.rect(cx, row, half + 1, 1, ice[3])
            c.px(cx - half, row, ice[7]); c.px(cx + half, row, ice[1])
            if y > h / 3 { c.px(cx + half / 2, row, ice[2]) }
        }
    }

    /// Castle Chill itself, one pixel to a unit on a 120×56 canvas, its foot on row 55: the outer towers and curtain
    /// wall, the two domed towers, and the keep with its crown of shards, gate and snowflake. On a wider canvas (the
    /// window's) the palace stands in the middle and its outer works run on either side: a lower wall with snowy
    /// merlons and icicles, a slender domed tower and a squat coned one at each end, so the strip isn't palace in the
    /// middle and bare peaks either side.
    static func eterniaCastleChillArt(_ c: PixelCanvas) {
        let ice = eterniaChillIce
        let snow = C(0xF4FAFF), snowD = C(0xC4D8EC), glow = C(0xA8F0FF), glowL = C(0xE4FCFF), deep = C(0x0C1830)

        /// A wall of ice blocks from (x0, y0), `w` wide, down to the foot: tone `t`, a darker joint under each course
        /// and a lit line over it, staggered joints between blocks, lit down the left edge and shaded down the right.
        func blocks(_ x0: Int, _ w: Int, _ y0: Int, _ t: Int) {
            c.rect(x0, y0, w, 56 - y0, ice[t])
            for (i, y) in stride(from: y0 + 4, to: 55, by: 4).enumerated() {
                c.rect(x0, y, w, 1, ice[t - 1]); c.rect(x0, y + 1, w, 1, ice[t + 1])
                for x in stride(from: x0 + 3 + (i % 2) * 4, to: x0 + w - 1, by: 8) { c.rect(x, y - 3, 1, 3, ice[t - 1]) }
            }
            c.rect(x0, y0, 1, 56 - y0, ice[t + 2]); c.rect(x0 + w - 1, y0, 1, 56 - y0, ice[t - 1])
        }
        /// A round tower of ice from `y0` to the foot, shaded as a cylinder lit from the left, its courses curving.
        func tower(_ x0: Int, _ w: Int, _ y0: Int) {
            for x in x0..<(x0 + w) {
                let k = Double(x - x0) / Double(max(1, w - 1))
                let t = k < 0.2 ? 5 : k < 0.5 ? 4 : k < 0.8 ? 3 : 2
                c.rect(x, y0, 1, 56 - y0, ice[t])
                let bow = Int((0.5 - abs(k - 0.5)) * 2.4)
                for y in stride(from: y0 + 4, to: 55, by: 4) { c.px(x, y + bow, ice[t - 1]) }
            }
            c.rect(x0, y0, 1, 56 - y0, ice[6])
        }
        /// A row of merlons along `y` (their tops), capped with snow, `step` apart.
        func merlons(_ x0: Int, _ x1: Int, _ y: Int, _ t: Int, step: Int = 5) {
            for x in stride(from: x0, to: x1 - 2, by: step) {
                c.rect(x, y, 3, 3, ice[t]); c.px(x, y + 1, ice[t + 2]); c.px(x + 2, y + 1, ice[t - 1])
                c.rect(x, y - 1, 3, 1, snow); c.px(x + 2, y - 1, snowD); c.px(x + 1, y - 2, snow)
            }
        }
        /// Icicles hanging from a ledge along `y`, from `x0` to `x1`, of lengths picked by `seed`.
        func icicles(_ x0: Int, _ x1: Int, _ y: Int, seed: Int) {
            for x in stride(from: x0, to: x1, by: 2) {
                let len = 1 + Int(noise(seed * 50 + x) * 4.5)
                c.rect(x, y, 1, len, ice[6]); c.px(x, y + len, ice[7])
                if len > 2 { c.px(x + 1, y, ice[5]) }
            }
        }
        /// A tall narrow window, arched, glowing cold cyan from the magic inside.
        func window(_ x: Int, _ y: Int, _ h: Int) {
            c.rect(x - 2, y - 1, 5, h + 2, ice[1]); c.px(x - 2, y - 1, ice[3]); c.px(x + 2, y - 1, ice[3])
            c.px(x, y - 1, glow); c.rect(x - 1, y, 3, h, glow); c.rect(x - 1, y, 1, h, glowL)
        }
        /// An onion dome of clear ice, `hw` either side of `cx`, from `top` (its point) down to `bottom`.
        func dome(_ cx: Int, _ hw: Int, _ top: Int, _ bottom: Int) {
            let hh = bottom - top
            for y in top..<bottom {
                let k = Double(y - top) / Double(hh)
                let bulge = k < 0.7 ? sin(k / 0.7 * .pi / 2) : 1 - (k - 0.7) * 0.9
                let half = max(0, Int((Double(hw) * bulge * (k < 0.25 ? k / 0.25 * 0.6 + 0.4 * k / 0.25 : 1)).rounded()))
                for x in (cx - half)...(cx + half) {
                    let n = Double(x - cx) / Double(max(1, half))
                    let t = n < -0.55 ? 6 : n < -0.1 ? 5 : n < 0.45 ? 4 : 3
                    c.px(x, y, ice[t])
                }
                c.px(cx + half, y, ice[2])
            }
            // A glint and a band of snow round the dome's foot.
            c.rect(cx - hw / 2, top + hh / 3, 1, 2, ice[7])
            c.rect(cx - hw, bottom - 1, hw * 2 + 1, 1, snow); c.rect(cx + hw / 2, bottom - 1, hw / 2 + 1, 1, snowD)
            // The finial: a spike of ice standing up out of the point.
            c.rect(cx, top - 4, 1, 4, ice[6]); c.px(cx, top - 5, ice[7])
        }
        /// A shard of the keep's crown: a tall point of ice from `base` up `h` rows, `hw` either side, lit on its left
        /// face, dark down its right, a bright edge up the left.
        func shard(_ cx: Int, _ base: Int, _ h: Int, _ hw: Int, lean: Int = 0) {
            for r in 0..<h {
                let y = base - h + r, half = hw * (r + 1) / h
                let x = cx + lean * (h - r) / h
                c.rect(x - half, y, half, 1, ice[6]); c.rect(x, y, half + 1, 1, ice[4])
                c.px(x + half, y, ice[2]); c.px(x - half, y, ice[7])
            }
        }

        /// A squat round tower from `top`, `w` wide from `x0`, under a cone of ice `h` tall, a window in it.
        func coned(_ x0: Int, _ w: Int, _ top: Int, _ h: Int) {
            tower(x0, w, top)
            let cx = x0 + w / 2
            for r in 0..<h {
                let half = 1 + r * (w / 2 + 1) / (h - 1), y = top - h + r
                c.rect(cx - half, y, half, 1, ice[6]); c.rect(cx, y, half + 1, 1, ice[4])
                if r % 3 == 1 { c.px(cx + half - 1, y, snow) }
            }
            c.rect(cx - w / 2 - 1, top, w + 3, 1, snow); c.px(cx, top - h - 1, ice[7]); c.px(cx, top - h - 2, ice[7])
            icicles(x0, x0 + w, top + 1, seed: x0)
            window(cx, top + 8, 5)
        }

        // The outer works, where the canvas is wide enough for them: a lower wall either side, a slender domed tower
        // part way along and a squat coned one at each end, then the palace drawn in the middle over them.
        let off = (c.w - 120) / 2
        if off > 0 {
            for (x0, toEnd) in [(2, true), (c.w - 2 - (off + 4), false)] {
                let ww = off + 4
                blocks(x0, ww, 40, 2)
                merlons(x0, x0 + ww, 37, 2)
                icicles(x0 + 1, x0 + ww, 40, seed: x0 + 51)
                window(toEnd ? x0 + ww - 12 : x0 + 12, 45, 4)
                let slim = toEnd ? x0 + 18 : x0 + ww - 18 - 7
                tower(slim, 7, 28)
                c.rect(slim - 1, 26, 9, 2, ice[4]); c.rect(slim - 1, 26, 9, 1, ice[6]); merlons(slim - 1, slim + 9, 24, 4, step: 3)
                icicles(slim, slim + 7, 28, seed: slim)
                dome(slim + 3, 4, 14, 23)
                window(slim + 3, 33, 5)
                coned(toEnd ? x0 + 1 : x0 + ww - 10, 9, 32, 9)
                for (sx, sw) in [(x0 + 3, 7), (x0 + ww / 2, 6)] {
                    c.rect(sx, 53, sw, 3, snowD); c.rect(sx + 1, 52, sw - 2, 1, snowD); c.rect(sx + 1, 53, sw - 3, 1, snow)
                }
            }
            c.ox = off
        }
        defer { c.ox = 0 }

        // The outer towers, squat, with cones of ice.
        for (x0, w) in [(2, 10), (108, 10)] { coned(x0, w, 30, 11) }
        // The curtain wall across the front, merlons capped with snow along its walk, icicles under it.
        blocks(10, 100, 36, 3)
        merlons(10, 110, 33, 3)
        icicles(11, 110, 36, seed: 3)
        // The domed towers, round, a snowy crenellated ring under each dome.
        for (x0, w) in [(18, 14), (88, 14)] {
            tower(x0, w, 18)
            c.rect(x0 - 1, 15, w + 2, 3, ice[4]); c.rect(x0 - 1, 15, w + 2, 1, ice[6]); c.rect(x0 + w - 1, 15, 2, 3, ice[2])
            merlons(x0 - 1, x0 + w + 2, 13, 4, step: 4)
            icicles(x0, x0 + w, 18, seed: x0 + 7)
            dome(x0 + w / 2, w / 2 + 1, 2, 12)
            window(x0 + w / 2, 24, 7); window(x0 + w / 2, 40, 6)
        }
        // The keep: a block of brighter ice, its own merlons, the crown of shards standing up behind them.
        let shards: [(x: Int, h: Int, hw: Int, lean: Int)] = [(42, 9, 2, -1), (47, 14, 3, -1), (53, 19, 3, 0), (60, 24, 4, 0),
                                                               (67, 19, 3, 0), (73, 14, 3, 1), (78, 9, 2, 1)]
        for sh in shards { shard(sh.x, 24, sh.h, sh.hw, lean: sh.lean) }
        blocks(38, 44, 24, 4)
        merlons(38, 82, 22, 4, step: 4)
        icicles(39, 81, 25, seed: 11)
        // The roundel over the gate, darker ice, a big six-armed snowflake on it in white.
        c.circle(60, 32, 6, ice[1]); c.circle(60, 32, 5, ice[2])
        c.pattern(56, 28, [
            "W...W...W",
            ".W.WWW.W.",
            "..W.W.W..",
            ".W.WWW.W.",
            "WWWW.WWWW",
            ".W.WWW.W.",
            "..W.W.W..",
            ".W.WWW.W.",
            "W...W...W",
        ], ["W": snow])
        // Windows either side of it, glowing.
        window(45, 29, 6); window(75, 29, 6)
        // The gate: a great arch, dark inside with the cold glow of the hall far back, voussoirs of pale ice round
        // it and a row of icicles hanging in its mouth like a portcullis.
        for y in 39..<56 {
            let up = Double(45 - y)
            let span: Double = 36 - up * up
            let r = y < 45 ? Int(span.squareRoot().rounded()) : 6
            c.rect(60 - r - 2, y, 2 * r + 4, 1, ice[5])
            c.rect(60 - r, y, 2 * r, 1, y > 50 ? C(0x18304E) : deep)
        }
        for (i, x) in stride(from: 55, to: 66, by: 2).enumerated() {
            let len = 3 + (i % 2) * 2
            c.rect(x, 41, 1, len, ice[6]); c.px(x, 41 + len, ice[7])
        }
        c.rect(57, 52, 6, 3, C(0x2C5A7A)); c.rect(58, 53, 4, 2, C(0x4A86A6))
        // Steps of ice down from the gate, and snow banked along the foot.
        c.rect(52, 54, 16, 1, ice[5]); c.rect(50, 55, 20, 1, ice[4])
        for (x, w) in [(10, 8), (27, 6), (40, 9), (73, 8), (85, 5), (100, 9)] {
            c.rect(x, 53, w, 3, snowD); c.rect(x + 1, 52, w - 2, 1, snowD); c.rect(x + 1, 53, w - 3, 1, snow)
        }
    }

    /// Castle Chill's life: snow drifting down, rocking as it falls; now and then a glint running down an icicle;
    /// and on the screen saver the aurora's folds rippling slowly along.
    static func eterniaCastleChillLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaCastleChillFrame(c, g), q = f.q, tall = isTall(c)
        // The aurora's folds brightening as a ripple runs along them.
        let horizon = f.base - (tall ? 24 : 9) * q
        for x in 0..<c.w {
            let ripple = sin(Double(x) * 0.05 / Double(s) - t * 0.5) * 0.5 + 0.5
            guard ripple > 0.7 else { continue }
            let low = eterniaChillAuroraHem(x, s, horizon, at: tall ? 42 : 34, amp: tall ? 26 : 6), len = (tall ? 16 : 6) * s
            let a = (ripple - 0.7) / 0.3
            c.rect(x, low - len, 1, len, C(0x9AFFC8).alpha(0.3 * a)); c.rect(x, low - s, 1, s, C(0xF0FFF6).alpha(0.5 * a))
        }
        // Snow, falling over the whole scene, the flakes nearer the bottom a touch bigger.
        let n = tall ? 90 : 34
        for k in 0..<n {
            let speed = 0.04 + noise(k * 5 + 10) * 0.05
            let ph = (t * speed + noise(k * 5 + 11)).truncatingRemainder(dividingBy: 1)
            let y = Int(ph * Double(g))
            let x = Int(noise(k * 5 + 12) * Double(c.w)) + Int(sin(t * 0.9 + Double(k)) * Double(3 * max(s, q / 2 + 1)))
            let size = noise(k * 5 + 13) > 0.7 ? max(1, q * 2 / 3 + (q > 1 ? 0 : 1)) : max(1, q / 2)
            c.rect(x, y, size, size, C(0xF4FAFF, 0.85))
        }
        // Glints: a spark of light now and then at a dome's or a shard's point.
        let points: [(x: Int, y: Int)] = [(25, 2), (95, 2), (60, 0), (53, 5), (67, 5), (7, 18), (113, 18)]
        for (i, p) in points.enumerated() {
            let v = sin(t * 0.8 + Double(i) * 2.1)
            guard v > 0.8 else { continue }
            let x = f.x + (f.off + p.x) * q + q / 2, y = f.y + p.y * q + q / 2, r = Int(Double(3 * q) * (v - 0.8) / 0.2) + q
            c.rect(x - r, y, 2 * r + 1, max(1, q / 2), C(0xFFFFFF, 0.8)); c.rect(x, y - r, max(1, q / 2), 2 * r + 1, C(0xFFFFFF, 0.8))
        }
    }
}

// MARK: - Earth, a small town at night

/// Letters for the town's signs, three or more wide and five tall. Our own words only: DINER, OPEN, MUSIC and
/// HIGH SCHOOL.
private let eterniaTownGlyphs: [Character: [String]] = [
    "A": ["XXX", "X.X", "XXX", "X.X", "X.X"], "C": ["XXX", "X..", "X..", "X..", "XXX"],
    "D": ["XX.", "X.X", "X.X", "X.X", "XX."], "E": ["XXX", "X..", "XX.", "X..", "XXX"],
    "G": ["XXX", "X..", "X.X", "X.X", "XXX"], "H": ["X.X", "X.X", "XXX", "X.X", "X.X"],
    "I": ["XXX", ".X.", ".X.", ".X.", "XXX"], "L": ["X..", "X..", "X..", "X..", "XXX"],
    "M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X"], "N": ["X..X", "XX.X", "X.XX", "X..X", "X..X"],
    "O": ["XXX", "X.X", "X.X", "X.X", "XXX"], "P": ["XXX", "X.X", "XXX", "X..", "X.."],
    "R": ["XX.", "X.X", "XX.", "X.X", "X.X"], "S": ["XXX", "X..", "XXX", "..X", "XXX"],
    "U": ["X.X", "X.X", "X.X", "X.X", "XXX"],
]

/// How wide `text` is at one unit to a pixel of the letters: a pixel between letters, two for a space.
private func eterniaTownTextWidth(_ text: String) -> Int {
    let w = text.map { eterniaTownGlyphs[$0]?.first?.count ?? 1 }.reduce(0, +)
    return w + max(0, text.count - 1)
}

/// Writes `text` with its top left at (x, y), each letter pixel `k`×`k`; with `hi`, the top-left pixel of each block
/// along the top of a stroke is that colour, the lit top of a neon tube. `only` draws just that letter (by index), for the flicker.
private func eterniaTownText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ k: Int, _ col: Px, hi: Px? = nil,
                             only: Int? = nil) {
    var cx = x
    for (i, ch) in text.enumerated() {
        let rows = eterniaTownGlyphs[ch] ?? ["."]
        if only == nil || only == i {
            for (r, row) in rows.enumerated() {
                for (j, b) in row.enumerated() where b == "X" {
                    c.rect(cx + j * k, y + r * k, k, k, col)
                    // The tube's lit top edge, where nothing of the letter is above it.
                    let above = r > 0 && Array(rows[r - 1])[j] == "X"
                    if let hi, k > 1, !above { c.rect(cx + j * k, y + r * k, k, 1, hi) }
                }
            }
        }
        cx += ((rows.first?.count ?? 1) + 1) * k
    }
}

extension Scenes {
    /// The town's layout, shared by the still and the moving layer. It's drawn whole on a canvas `w`×`h` units at one
    /// pixel to a unit and blown up `q` times, its bottom row on the ground row and its top at `y`. On the screen
    /// saver `q` grows so the block (diner, alley, music shop, side road, school; 226 units) just fits across; in the
    /// window the street runs on either side of it. `x0` is where the block starts and `foot` the row the shop
    /// fronts stand on, both in units.
    static func eterniaEarthTownFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, w: Int, h: Int, y: Int, x0: Int, foot: Int) {
        let q = max(1, min(g * 62 / (100 * 56), c.w / 236))
        let w = c.w / q + 2, h = (g + q - 1) / q
        return (q, w, h, g - h * q, w / 2 - 113, h - 8)
    }

    /// Where the streetlights stand, in units: at the corners of the block and every 80 units along the street.
    private static func eterniaTownLamps(_ w: Int, _ x0: Int) -> [Int] {
        var xs = [x0 - 6, x0 + 135, x0 + 232]
        var x = x0 - 86
        while x > -10 { xs.append(x); x -= 80 }
        x = x0 + 312
        while x < w + 10 { xs.append(x); x += 80 }
        return xs
    }

    /// Earth, from the 1987 film: a little American main street after dark. A navy sky full of stars over the
    /// rooftops; in the middle of the block a stainless-steel diner, its ribbed panels and pink stripes lit by the
    /// streetlight, warm windows with folk at the counter, OPEN in a window and DINER in pink neon on a sign over its
    /// roof; an alley beside it (a fire escape, a dumpster, a bulb over the back door), then the music shop, brick, two
    /// storeys, MUSIC in cyan neon over a window full of keyboards on their stands. Across the side road, set back
    /// behind its lawn, the high school: red brick wings, a portico of white columns, HIGH SCHOOL on its frieze and a
    /// lit clock in a cupola, a flag. Shops and houses run on along the street, dark but for a lit window or two,
    /// sodium streetlights pooling orange on the sidewalk. The crew stands on the road. On the screen saver the town
    /// is bigger and a wooded hill rises behind it with the water tower on top, against the stars, one of them
    /// brighter than the rest: Eternia.
    static func eterniaEarthTown(_ c: PixelCanvas, _ g: Int) {
        let f = eterniaEarthTownFrame(c, g), tall = isTall(c)
        let u = PixelCanvas(f.w, f.h)
        eterniaTownArt(u, x0: f.x0, foot: f.foot, tall: tall)
        eterniaPlaces8Blit(c, u, 0, f.y, f.q)
        // The road the crew stands on: dark asphalt, plain.
        c.ground(g, C(0x23253A), edge: C(0x2E3046), speck: C(0x1C1E30), seed: 53)
    }

    /// The street itself, one pixel to a unit on a canvas of its own.
    private static func eterniaTownArt(_ u: PixelCanvas, x0: Int, foot F: Int, tall: Bool) {
        let w = u.w, h = u.h
        // The sky: navy going a little lighter and warmer low down, where the town's lights haze it.
        u.gradient(0, F, C(0x070C24), C(0x1E2448), bands: tall ? 10 : 6)
        u.gradient(max(0, F - 40), F, C(0x3A2E48, 0), C(0x4A3448, 0.5), bands: 4)
        u.stars(0, F - 20, density: tall ? 40 : 30, seed: 61)
        if tall { eterniaTownHill(u, x0: x0, foot: F) }
        // Far behind the street: trees and roofs in silhouette.
        for x in 0..<w {
            let tree = F - 38 - Int((sin(Double(x) * 0.31) * 0.5 + sin(Double(x) * 0.13 + 2) * 0.5 + noise(x / 3 + 5) * 0.8) * 3)
            u.rect(x, tree, 1, F - tree, C(0x0E1430))
        }
        for k in 0..<(w / 23 + 1) {
            let x = k * 23 + Int(noise(k + 410) * 10), rw = 10 + Int(noise(k + 411) * 8), top = F - 42 - Int(noise(k + 412) * 6)
            for r in 0..<4 { u.rect(x + 3 - r, top + r, rw - 6 + 2 * r, 1, C(0x121A38)) }
            u.rect(x, top + 4, rw, F - top - 4, C(0x121A38))
        }

        // The rest of the street either side of the block.
        var x = x0 - 2
        var seed = 0
        while x > -40 {
            let bw = 30 + Int(noise(seed + 500) * 18)
            eterniaTownShop(u, x - bw, bw, F, seed: seed); x -= bw + 1; seed += 1
        }
        x = x0 + 228; seed = 20
        while x < w + 40 {
            let bw = 30 + Int(noise(seed + 500) * 18)
            eterniaTownShop(u, x, bw, F, seed: seed); x += bw + 1; seed += 1
        }

        eterniaTownAlley(u, x0 + 64, F)
        eterniaTownDiner(u, x0, F)
        eterniaTownMusic(u, x0 + 78, F)
        eterniaTownSchool(u, x0 + 130, F)

        // The sidewalk, the kerb and the far half of the road, plain and dark behind the crew.
        u.rect(0, F, w, 2, C(0x44465A)); u.rect(0, F, w, 1, C(0x56586C))
        for k in stride(from: 0, to: w, by: 9) { u.px(k, F + 1, C(0x383A4C)) }
        u.rect(0, F + 2, w, 1, C(0x6A6C80)); u.rect(0, F + 3, w, 1, C(0x1A1C2C))
        u.rect(0, F + 4, w, h - F - 4, C(0x23253A))
        // The side road between the music shop and the school, going back past the lawn.
        u.rect(x0 + 130, F - 6, 12, 10, C(0x262840)); u.rect(x0 + 130, F - 6, 1, 8, C(0x3A3C52))
        u.rect(x0 + 141, F - 6, 1, 8, C(0x3A3C52))
        for y in stride(from: F - 5, to: F + 4, by: 3) { u.px(x0 + 136, y, C(0x8A7A40)) }
        // A fire hydrant and a mailbox on the sidewalk.
        u.pattern(x0 + 126, F - 4, [".r.", "rRr", "RRs", "RRs", "rRs"], ["R": C(0xB8302A), "r": C(0xD84A3A), "s": C(0x7A1E1A)])
        u.pattern(x0 - 12, F - 7, ["BBBB", "BLBB", "BBBb", "BBBb", ".k.k", ".k.k", ".k.k"],
                  ["B": C(0x2A4A9A), "L": C(0x4A6ACA), "b": C(0x1A2E6A), "k": C(0x1A1C28)])
        // The streetlights: a pole, an arm over the road and a sodium lamp, a cone of orange light down the front.
        for lx in eterniaTownLamps(w, x0) { eterniaTownLamp(u, lx, F) }
    }

    /// The hills behind the town on the screen saver, in units: the ridge's top at column `x`. A big wooded hill on
    /// the left with the water tower on it, a lower one on the right with the radio mast; `tx` and `rx` are their
    /// middles.
    private static func eterniaTownRidge(_ x: Int, tx: Int, rx: Int, foot F: Int) -> Int {
        let d = Double(x - tx) / 95, e = Double(x - rx) / 80
        let hill = max(30 * max(0, 1 - d * d), 22 * max(0, 1 - e * e))
        return F - 46 - Int(hill) - Int(noise(x / 4 + 30) * 2)
    }

    /// Where the hills' landmarks stand, in units: the water tower's middle and the radio mast's.
    private static func eterniaTownLandmarks(_ x0: Int) -> (tower: Int, mast: Int) { (x0 + 44, x0 + 196) }

    /// The hills behind the town on the screen saver, filling the sky over the rooftops: wooded, houses with lit
    /// windows up their slopes. On the big one the water tower, tall against the stars (four legs braced across, a
    /// catwalk round the tank, a ladder, a cone roof), the brightest star (Eternia) beside it; on the lower one a radio
    /// mast, a lattice tapering up to a red light that blinks in the moving layer.
    private static func eterniaTownHill(_ u: PixelCanvas, x0: Int, foot F: Int) {
        let (tx, rx) = eterniaTownLandmarks(x0)
        let ridge = { (x: Int) in eterniaTownRidge(x, tx: tx, rx: rx, foot: F) }
        for x in 0..<u.w {
            let top = ridge(x)
            u.rect(x, top, 1, F - top, C(0x141C3C)); u.px(x, top, C(0x1E2850))
        }
        // Trees along the brow, round and dark, lit a little on top by the stars.
        for k in 0..<(u.w / 6 + 1) {
            let x = k * 6 + Int(noise(k + 470) * 4)
            guard abs(x - tx) > 22, abs(x - rx) > 5 else { continue }
            let top = ridge(x) + 1, r = 3 + Int(noise(k + 471) * 2)
            u.circle(x, top, r, C(0x18224A)); u.rect(x - r / 2, top - r, r, 1, C(0x22305A))
        }
        // Houses up the slopes, little gables with a lit window or two.
        for k in 0..<(u.w / 15 + 1) {
            let x = k * 15 + Int(noise(k + 480) * 8)
            guard abs(x - tx) > 24, abs(x - rx) > 8, noise(k + 481) > 0.3 else { continue }
            let top = ridge(x) + 4 + Int(noise(k + 482) * 6)
            u.rect(x, top, 7, 4, C(0x1E2446))
            for r in 0..<3 { u.rect(x + r, top - 1 - r, 7 - 2 * r, 1, C(0x262C52)) }
            u.rect(x + 1, top + 1, 2, 2, noise(k + 483) > 0.4 ? C(0xE0B060) : C(0x10142A))
            u.rect(x + 4, top + 1, 2, 2, noise(k + 484) > 0.6 ? C(0xE0B060) : C(0x10142A))
        }

        // The radio mast: a lattice tapering up from the lower hill, cross-braced, guy wires out to the slopes.
        let mb = ridge(rx) + 2, mt = 12, steel = C(0x3A4258), steelD = C(0x262C40), steelL = C(0x5A6480)
        for y in mt..<mb {
            let half = 1 + (y - mt) * 3 / max(1, mb - mt)
            u.px(rx - half, y, steelL); u.px(rx + half, y, steel)
            if (y - mt) % 4 == 0 { u.rect(rx - half, y, 2 * half + 1, 1, steelD) }
            if (y - mt) % 4 == 2 { u.px(rx, y, steelD) }
        }
        for (dx, y0) in [(-22, mt + 10), (22, mt + 10), (-14, mt + 30), (14, mt + 30)] {
            let ex = rx + dx, ey = ridge(ex) + 1, n = max(abs(dx), ey - y0)
            for i in 0..<n where i % 2 == 0 { u.px(rx + dx * i / n, y0 + (ey - y0) * i / n, C(0x2A3048)) }
        }
        u.rect(rx - 1, mt - 1, 3, 1, steelL); u.px(rx, mt - 3, C(0x8A2020)); u.px(rx, mt - 2, steel)

        // The water tower: its legs splayed a little with cross bracing, the tank lit from the left with a band
        // round it, the catwalk and railing at its foot, a shallow cone roof.
        let ground = ridge(tx) + 2, legs = 30, top = ground - legs - 18, tw = 18
        for (bx, tx2) in [(tx - 14, tx - 10), (tx + 14, tx + 10), (tx - 5, tx - 4), (tx + 5, tx + 4)] {
            for y in (ground - legs)..<ground {
                let k = Double(ground - y) / Double(legs)
                u.px(bx + Int(Double(tx2 - bx) * k), y, bx < tx ? steelL : steel)
            }
        }
        for y in [ground - 10, ground - 20] {
            let k = Double(ground - y) / Double(legs)
            let l = tx - 14 + Int(4 * k), r = tx + 14 - Int(4 * k)
            u.rect(l, y, r - l + 1, 1, steelD)
        }
        for i in 0..<9 { u.px(tx - 12 + i * 3, ground - 11 - i, steelD); u.px(tx + 12 - i * 3, ground - 11 - i, steelD) }
        for x in (tx - tw)...(tx + tw) {
            let k = Double(x - (tx - tw)) / Double(2 * tw)
            let col = k < 0.2 ? C(0x9AA8C0) : k < 0.5 ? C(0x7A88A2) : k < 0.8 ? C(0x5E6A84) : C(0x465068)
            u.rect(x, top, 1, 18, col)
        }
        u.rect(tx - tw, top + 7, 2 * tw + 1, 2, C(0x3E4860)); u.rect(tx - tw, top + 7, 8, 2, C(0x5A6680))
        u.rect(tx - tw, top, 2 * tw + 1, 1, C(0xB4C0D4))
        u.rect(tx - tw - 2, top + 18, 2 * tw + 5, 1, steelL); u.rect(tx - tw - 2, top + 16, 2 * tw + 5, 1, steel)
        for x in stride(from: tx - tw - 2, through: tx + tw + 2, by: 3) { u.px(x, top + 17, steel) }
        for r in 0..<7 {
            let half = 5 + r * 2
            u.rect(tx - half, top - 7 + r, half, 1, C(0xA8B4CA)); u.rect(tx, top - 7 + r, half + 1, 1, C(0x66728C))
        }
        u.rect(tx - 1, top - 9, 2, 2, C(0x8A96AE))
        // The ladder up the right leg to the catwalk.
        for y in stride(from: ground - 1, to: top + 18, by: -2) { u.rect(tx + 7, y, 2, 1, steelD) }
        u.rect(tx + 7, top + 18, 1, ground - top - 18, steel); u.rect(tx + 9, top + 18, 1, ground - top - 18, steel)
        // The bright star, up and to the right of the tower, a halo round it (it twinkles in the moving layer).
        let (sx, sy) = eterniaTownStar(x0, F)
        u.circle(sx, sy, 5, C(0xC8D8FF, 0.12)); u.circle(sx, sy, 2, C(0xDCE6FF, 0.3))
        u.rect(sx - 1, sy, 3, 1, C(0xFFFFFF)); u.rect(sx, sy - 1, 1, 3, C(0xFFFFFF))
    }

    /// Where Eternia shines over the town on the screen saver, in units: up and to the right of the water tower.
    private static func eterniaTownStar(_ x0: Int, _ F: Int) -> (x: Int, y: Int) {
        let tx = eterniaTownLandmarks(x0).tower
        return (tx + 42, max(4, eterniaTownRidge(tx, tx: tx, rx: eterniaTownLandmarks(x0).mast, foot: F) - 44))
    }

    /// One of the shops and houses along the street, `bw` wide from `x`: brick or clapboard picked by `seed`, a
    /// cornice, upper windows (dark, now and then one lit), a dark shopfront under an awning or a door with a stoop.
    private static func eterniaTownShop(_ u: PixelCanvas, _ x: Int, _ bw: Int, _ F: Int, seed: Int) {
        let walls: [(Px, Px, Px)] = [(C(0x4A2A30), C(0x5E3438), C(0x36202A)), (C(0x3A3A52), C(0x4A4A66), C(0x2A2A40)),
                                     (C(0x4A3A2E), C(0x5E4A3A), C(0x342820)), (C(0x2E4048), C(0x3C525A), C(0x223038))]
        let (wall, wallL, wallD) = walls[seed % walls.count]
        let bh = 26 + Int(noise(seed + 520) * 16), top = F - bh
        u.rect(x, top, bw, bh, wall); u.rect(x, top, 1, bh, wallL); u.rect(x + bw - 1, top, 1, bh, wallD)
        for y in stride(from: top + 3, to: F, by: 3) where seed % 2 == 0 { u.rect(x + 1, y, bw - 2, 1, wallD) }
        // The cornice.
        u.rect(x - 1, top - 2, bw + 2, 2, C(0x5A5A6E)); u.rect(x - 1, top - 2, bw + 2, 1, C(0x76768A))
        // Upper windows.
        let n = max(2, bw / 12)
        for i in 0..<n {
            let wx = x + bw * (2 * i + 1) / (2 * n) - 2
            for (j, wy) in [top + 3, top + 12].enumerated() where wy + 6 < F - 14 {
                let lit = noise(seed * 13 + i * 3 + j + 530) > 0.78
                u.rect(wx - 1, wy - 1, 6, 8, C(0x6A6A7E)); u.rect(wx, wy, 4, 6, lit ? C(0xD8A858) : C(0x141A30))
                if lit { u.rect(wx, wy, 4, 2, C(0xA8783E)) } else { u.px(wx + 3, wy, C(0x2E3A58)); u.px(wx + 2, wy + 1, C(0x2E3A58)) }
                u.rect(wx - 1, wy + 6, 6, 1, C(0x8A8A9E))
            }
        }
        // The ground floor: a dark shopfront under a striped awning, or a house door with a stoop.
        if seed % 3 != 1 {
            let sx = x + 3, sw = bw - 14
            u.rect(sx - 1, F - 13, sw + 2, 12, C(0x22182A)); u.rect(sx, F - 12, sw, 10, C(0x161C34))
            for k in 0..<3 { u.px(sx + 2 + k * 2, F - 11 + k, C(0x2E3A5A)); u.px(sx + 3 + k * 2, F - 11 + k, C(0x2E3A5A)) }
            let stripes = [(C(0x2A6A4A), C(0xC8C8C0)), (C(0x8A2A3A), C(0xC8C0B8)), (C(0x2A4A8A), C(0xC8C8D0))][seed % 3]
            for i in 0..<(sw + 4) { u.rect(sx - 2 + i, F - 16, 1, 3, i / 2 % 2 == 0 ? stripes.0 : stripes.1) }
            u.rect(sx - 2, F - 13, sw + 4, 1, C(0x14141E))
            u.rect(x + bw - 9, F - 12, 6, 12, C(0x2A1C1A)); u.rect(x + bw - 8, F - 11, 4, 4, C(0x1A2038))
        } else {
            u.rect(x + bw / 2 - 3, F - 13, 7, 13, C(0x2A1E1A)); u.rect(x + bw / 2 - 2, F - 12, 5, 12, C(0x4A3426))
            u.px(x + bw / 2 + 1, F - 6, C(0xE0C070)); u.rect(x + bw / 2 - 4, F - 1, 9, 1, C(0x5A5A6A))
            u.rect(x + 3, F - 11, 6, 7, C(0x6A6A7E)); u.rect(x + 4, F - 10, 4, 5, C(0x141A30))
        }
    }

    /// A streetlight at `x`: a pole on the sidewalk, an arm reaching out over the road, the lamp's head and its
    /// orange light falling down the facades behind.
    private static func eterniaTownLamp(_ u: PixelCanvas, _ x: Int, _ F: Int) {
        u.ellipse(x + 5, F - 14, 8, 14, C(0xFFA040, 0.07))
        u.ellipse(x + 5, F, 12, 2, C(0xFFB050, 0.18))
        u.rect(x, F - 34, 1, 36, C(0x30344A)); u.rect(x + 1, F - 34, 1, 36, C(0x1E2232))
        u.rect(x - 1, F, 4, 2, C(0x2A2E40))
        u.rect(x, F - 35, 6, 1, C(0x30344A)); u.px(x + 1, F - 34, C(0x30344A))
        u.rect(x + 4, F - 35, 4, 2, C(0x3A3E52)); u.rect(x + 5, F - 33, 2, 1, C(0xFFD890))
        u.circle(x + 6, F - 32, 3, C(0xFFB060, 0.22))
    }

    /// The diner, 64 units wide from `x`: a stainless-steel diner on a dark plinth, its rounded roof, ribbed lower
    /// panels and two pink enamel stripes, a row of warm windows with folk in the booths inside, OPEN in neon in
    /// the wide window, the door up two steps, and on the roof the sign, DINER in pink neon over a row of bulbs.
    private static func eterniaTownDiner(_ u: PixelCanvas, _ x: Int, _ F: Int) {
        let st = [C(0x2E3648), C(0x46526A), C(0x66748E), C(0x8E9CB4), C(0xB8C4D6)]
        let pink = C(0xD04A7A), pinkL = C(0xF07AA4)
        // The body and its roof, the ends rounded.
        u.rect(x, F - 30, 64, 27, st[2]); u.rect(x, F - 30, 1, 27, st[3]); u.rect(x + 63, F - 30, 1, 27, st[1])
        u.rect(x + 1, F - 33, 62, 3, st[1]); u.rect(x + 3, F - 34, 58, 1, st[3]); u.rect(x + 2, F - 33, 20, 1, st[4])
        u.px(x, F - 31, st[1]); u.px(x + 63, F - 31, st[0])
        // The ribbed panels under the windows and the band over them.
        for y in stride(from: F - 12, to: F - 3, by: 2) { u.rect(x + 1, y, 62, 1, st[3]); u.rect(x + 1, y + 1, 62, 1, st[1]) }
        for y in [F - 28, F - 27] { u.rect(x + 1, y, 62, 1, y == F - 28 ? st[3] : st[2]) }
        u.rect(x, F - 26, 64, 1, pink); u.rect(x, F - 13, 64, 1, pink); u.rect(x, F - 13, 30, 1, pinkL)
        // The plinth.
        u.rect(x - 1, F - 3, 66, 3, C(0x262430)); u.rect(x - 1, F - 3, 66, 1, C(0x3A3644))
        // The windows: warm light, a lamp hanging in each, the counter along the bottom and folk sitting at it.
        let windows: [(x: Int, w: Int)] = [(3, 8), (13, 8), (23, 8), (43, 18)]
        for (i, win) in windows.enumerated() {
            let wx = x + win.x
            u.rect(wx - 1, F - 25, win.w + 2, 12, st[0])
            for y in (F - 24)..<(F - 14) {
                u.rect(wx, y, win.w, 1, y < F - 19 ? C(0xC08A4C) : C(0xA0703C))
            }
            u.rect(wx + win.w / 2, F - 24, 1, 1, C(0x5A3A28)); u.rect(wx + win.w / 2 - 1, F - 23, 3, 1, C(0xFFE0A0))
            if i == 3 {
                // The counter along the bottom of the wide window, a cake stand on it.
                u.rect(wx, F - 16, win.w, 2, C(0x4A2A22)); u.rect(wx, F - 16, win.w, 1, C(0xD08A60))
                u.rect(wx + 13, F - 18, 3, 2, C(0xE8D8C0)); u.px(wx + 14, F - 19, C(0xF07AA4))
                continue
            }
            // A booth: red seat backs either side of a table, and folk sitting in it facing each other, big enough to
            // read at a glance: dark hair, a pale face against the warm light, a bright shirt, a hand on the table.
            u.rect(wx, F - 21, 1, 7, C(0xB03A3A)); u.px(wx, F - 21, C(0xD85A50))
            u.rect(wx + win.w - 1, F - 21, 1, 7, C(0xB03A3A)); u.px(wx + win.w - 1, F - 21, C(0xD85A50))
            let everyone: [[(at: Int, right: Bool, hair: Px, shirt: Px)]] = [
                [(0, true, C(0x2A1A14), C(0x2A8AA8)), (4, false, C(0xE8B850), C(0xD83A3A))],
                [(0, true, C(0x5A2A18), C(0xF0E8D8))],
                [(0, true, C(0xE8B850), C(0x3A4ACA)), (4, false, C(0x2A1A14), C(0x3AA85A))],
            ]
            let folk = everyone[i]
            for p in folk {
                let rows = p.right ? [".hhh", ".hff", ".hff", "ssss", "sssa", "sss."] : ["hhh.", "ffh.", "ffh.", "ssss", "asss", ".sss"]
                u.pattern(wx + p.at, F - 22, rows, ["h": p.hair, "f": C(0xF4D0A8), "s": p.shirt, "a": C(0xF4D0A8)])
            }
            u.rect(wx + 1, F - 16, win.w - 2, 1, C(0xE8D8C0)); u.rect(wx + 2, F - 15, win.w - 4, 1, C(0x6A4A30))
            // A mug on the table where there's room for one.
            if folk.count == 1 { u.rect(wx + 5, F - 18, 2, 2, C(0xF0F0F0)); u.px(wx + 7, F - 17, C(0xD0D0D0)) }
        }
        // OPEN, small, in neon blue in the wide window.
        eterniaTownText(u, x + 44, F - 23, "OPEN", 1, C(0x5AE0FF))
        // The door, up two steps, glass in its top half.
        u.rect(x + 33, F - 27, 9, 24, st[0]); u.rect(x + 34, F - 26, 7, 23, st[1])
        u.rect(x + 35, F - 25, 5, 10, C(0xC08A4C)); u.rect(x + 35, F - 25, 5, 1, C(0xE0B070)); u.px(x + 39, F - 13, st[4])
        u.rect(x + 31, F - 3, 13, 1, st[3]); u.rect(x + 30, F - 2, 15, 2, st[2]); u.rect(x + 30, F - 2, 15, 1, st[3])
        // The sign on the roof: two posts, a dark board with a pink tube round its edge, DINER, a row of bulbs.
        u.rect(x + 16, F - 37, 2, 4, st[0]); u.rect(x + 46, F - 37, 2, 4, st[0])
        u.rect(x + 10, F - 51, 44, 15, C(0x1C1030)); u.rect(x + 10, F - 51, 44, 1, C(0x3A2A50))
        for (a, b) in [(x + 11, F - 50), (x + 11, F - 38)] { u.rect(a, b, 42, 1, C(0xE05AA0)) }
        u.rect(x + 11, F - 50, 1, 13, C(0xE05AA0)); u.rect(x + 52, F - 50, 1, 13, C(0xE05AA0))
        eterniaTownText(u, x + 13, F - 48, "DINER", 2, C(0xFF5AAE), hi: C(0xFFC4E4))
        for bx in stride(from: x + 12, to: x + 53, by: 3) { u.px(bx, F - 37, C(0xFFD890)) }
    }

    /// The alley between the diner and the music shop, 14 wide from `x`: the back of a building at its end in dark
    /// brick, a fire escape zigzagging down it, a back door under a caged bulb, a dumpster and a trash can. The Cosmic
    /// Key's portal opens here in the moving layer.
    private static func eterniaTownAlley(_ u: PixelCanvas, _ x: Int, _ F: Int) {
        u.rect(x - 2, F - 44, 18, 44, C(0x181A2E))
        for (i, y) in stride(from: F - 42, to: F, by: 3).enumerated() {
            u.rect(x - 2, y, 18, 1, C(0x121428))
            for bx in stride(from: x + (i % 2) * 2, to: x + 16, by: 5) { u.px(bx, y + 1, C(0x121428)) }
        }
        // The fire escape: landings with railings, stairs between them.
        let iron = C(0x3A3E52), ironL = C(0x52566C)
        for ly in [F - 38, F - 27] {
            u.rect(x + 1, ly, 12, 1, ironL); u.rect(x + 1, ly - 3, 12, 1, iron)
            for bx in stride(from: x + 1, to: x + 13, by: 3) { u.rect(bx, ly - 3, 1, 3, iron) }
        }
        for i in 0..<10 { u.px(x + 2 + i, F - 37 + i, iron) }
        for i in 0..<8 { u.px(x + 12 - i, F - 26 + i, iron) }
        // The back door and its caged bulb.
        u.rect(x + 3, F - 12, 6, 12, C(0x0E1020)); u.rect(x + 4, F - 11, 4, 11, C(0x22263A)); u.px(x + 7, F - 6, C(0x8A8A9A))
        u.circle(x + 6, F - 14, 4, C(0xFFD890, 0.14)); u.rect(x + 5, F - 15, 2, 2, C(0xFFE0A0)); u.px(x + 5, F - 15, C(0xFFFFFF))
        // The dumpster and a trash can.
        u.rect(x + 9, F - 6, 6, 6, C(0x2A4A3A)); u.rect(x + 9, F - 7, 6, 1, C(0x3E6A52)); u.rect(x + 9, F - 4, 6, 1, C(0x1E3628))
        u.rect(x, F - 4, 3, 4, C(0x5A5E6E)); u.rect(x, F - 5, 3, 1, C(0x7A7E8E)); u.px(x + 2, F - 3, C(0x3A3E4E))
        // The diner's and the music shop's side walls in shadow.
        u.rect(x - 2, F - 44, 1, 44, C(0x0E1020)); u.rect(x + 15, F - 44, 1, 44, C(0x0E1020))
    }

    /// The music shop, 52 wide from `x`: two storeys of brick under a stone cornice, a lit window upstairs and a dark
    /// one, MUSIC in cyan neon on a board, and the shop window: two keyboards on a two-tier stand (a red one
    /// over a black one), a big synth on its own stand, a red guitar on the wall and gig posters, spotlit, and the
    /// door beside it.
    private static func eterniaTownMusic(_ u: PixelCanvas, _ x: Int, _ F: Int) {
        let brick = C(0x5A2C2E), brickD = C(0x42201F), brickL = C(0x74403A), mortar = C(0x2E1818)
        u.rect(x, F - 46, 52, 46, brick)
        for (i, y) in stride(from: F - 44, to: F - 2, by: 3).enumerated() {
            u.rect(x, y, 52, 1, mortar)
            for bx in stride(from: x + 2 + (i % 2) * 3, to: x + 51, by: 6) { u.px(bx, y + 1, brickD) }
        }
        u.rect(x, F - 46, 1, 46, brickL); u.rect(x + 51, F - 46, 1, 46, brickD)
        // The cornice.
        u.rect(x - 1, F - 48, 54, 3, C(0x5E5868)); u.rect(x - 1, F - 48, 54, 1, C(0x847E90))
        for dx in stride(from: 0, to: 54, by: 2) { u.px(x - 1 + dx, F - 45, C(0x3A3644)) }
        // Upstairs: the left window lit behind a half-drawn blind, the right one dark.
        for (wx, lit) in [(x + 8, true), (x + 32, false)] {
            u.rect(wx - 1, F - 44, 14, 9, C(0x7A7080)); u.rect(wx, F - 43, 12, 7, lit ? C(0xD8A858) : C(0x141A30))
            if lit { u.rect(wx, F - 43, 12, 3, C(0xA8783E)); u.rect(wx, F - 40, 12, 1, C(0x7A5428)) }
            else { for k in 0..<4 { u.px(wx + 7 + k, F - 43 + k, C(0x2E3A58)) } }
            u.rect(wx + 5, F - 43, 1, 7, C(0x7A7080)); u.rect(wx - 2, F - 35, 16, 1, C(0x9A94A6))
        }
        // The sign: a dark board, MUSIC in cyan neon.
        u.rect(x + 1, F - 34, 50, 12, C(0x101426)); u.rect(x + 1, F - 34, 50, 1, C(0x2A3048)); u.rect(x + 1, F - 23, 50, 1, C(0x080A18))
        eterniaTownText(u, x + 5, F - 33, "MUSIC", 2, C(0x4AD8F0), hi: C(0xC8FAFF))
        // The shop window: a purple-lit room, posters and a guitar on the back wall, the keyboards in front.
        let wx = x + 3, wy = F - 20
        u.rect(wx - 1, wy - 1, 32, 19, C(0x2A1A14)); u.rect(wx - 1, wy - 1, 32, 1, C(0xB0904A))
        for y in wy..<(F - 3) { u.rect(wx, y, 30, 1, y < F - 8 ? C(0x4A3A6E) : C(0x30284A)) }
        u.rect(wx + 2, wy + 1, 6, 5, C(0xC8B040)); u.rect(wx + 3, wy + 2, 4, 1, C(0x8A2A2A)); u.rect(wx + 3, wy + 4, 3, 1, C(0x2A2A3A))
        u.rect(wx + 21, wy + 1, 6, 5, C(0x3A8A9A)); u.rect(wx + 22, wy + 2, 4, 2, C(0xE07A9A))
        // The guitar on the wall between them.
        u.rect(wx + 16, wy, 1, 6, C(0xA88A5A)); u.rect(wx + 15, wy, 3, 1, C(0x3A2A1A))
        u.pattern(wx + 14, wy + 6, [".RR.", "RRRr", ".Rr.", "RRRr", "RRrr", ".rr."], ["R": C(0xC83A30), "r": C(0x8A2420)])
        u.px(wx + 15, wy + 9, C(0x2A1A14))
        // Spotlights from the top of the window.
        for sx in [wx + 6, wx + 22] {
            for y in 0..<14 { u.rect(sx - y / 3, wy + y, 1 + 2 * (y / 3), 1, C(0xFFF0E0, 0.07)) }
        }
        /// A keyboard `n` wide at (kx, ky), four rows: its case with lights along the top, black keys over white,
        /// white keys, the case's lip. The keys are two rows tall so they read as a keyboard at a glance.
        func keyboard(_ kx: Int, _ ky: Int, _ n: Int, _ body: Px, _ lip: Px) {
            u.rect(kx, ky, n, 4, body); u.rect(kx, ky + 3, n, 1, lip)
            for k in stride(from: 1, to: n - 1, by: 3) { u.px(kx + k, ky, [C(0xF0C040), C(0x5AE04A), C(0xE04A4A)][k % 3]) }
            for k in 1..<(n - 1) {
                let black = [1, 3, 6, 8, 10].contains((k - 1) % 12)
                u.px(kx + k, ky + 1, black ? C(0x16161E) : C(0xF4F4FA)); u.px(kx + k, ky + 2, (k - 1) % 2 == 1 ? C(0xC8C8D4) : C(0xF4F4FA))
            }
        }
        // Two keyboards on a two-tier stand on the left, its legs splayed.
        for (lx, rx2) in [(wx + 2, wx + 4), (wx + 13, wx + 11)] {
            for y in (F - 12)..<(F - 3) { u.px(lx + (rx2 - lx) * (y - F + 12) / 9, y, C(0x9A9AAA)) }
        }
        keyboard(wx + 1, F - 15, 14, C(0xC83A30), C(0x7A1E1A))
        keyboard(wx + 3, F - 9, 13, C(0x24242E), C(0x101018))
        // The big synth on the right, on its stand, knobs along its top.
        keyboard(wx + 17, F - 11, 12, C(0x5A6A8A), C(0x34405A))
        u.rect(wx + 17, F - 12, 12, 1, C(0x3A4660)); for k in 0..<5 { u.px(wx + 18 + k * 2, F - 12, [C(0xF0C040), C(0x4AD8F0), C(0xF07AA4)][k % 3]) }
        u.rect(wx + 19, F - 7, 1, 4, C(0x9A9AAA)); u.rect(wx + 26, F - 7, 1, 4, C(0x9A9AAA))
        // Reflections across the glass.
        for k in 0..<6 { u.px(wx + 2 + k, wy + 11 - k, C(0xFFFFFF, 0.18)); u.px(wx + 4 + k, wy + 12 - k, C(0xFFFFFF, 0.1)) }
        // The sill and the door, glass in its top half lit warm, a transom over it.
        u.rect(x + 2, F - 3, 32, 1, C(0x847E90)); u.rect(x, F - 2, 52, 2, C(0x3A3644))
        u.rect(x + 37, F - 21, 11, 19, C(0x2A1A14)); u.rect(x + 38, F - 20, 9, 18, C(0x5A3A26))
        u.rect(x + 38, F - 20, 9, 2, C(0xD8B070)); u.rect(x + 39, F - 17, 7, 7, C(0xB8946A)); u.rect(x + 39, F - 17, 2, 7, C(0xD8B88A))
        u.px(x + 45, F - 10, C(0xE0C070)); u.rect(x + 36, F - 2, 13, 1, C(0x5E5868))
    }

    /// The high school, across the side road from the music shop: its foot set back behind a lawn and a hedge, two
    /// wings of red brick with rows of windows (a janitor's light on here and there), a portico of six white columns
    /// under a pediment, HIGH SCHOOL on the frieze, a cupola over it all with the clock lit, and the flag on its pole.
    /// `x` is the side road's left edge; the school is 84 wide from 12 units after it.
    private static func eterniaTownSchool(_ u: PixelCanvas, _ road: Int, _ F: Int) {
        let x = road + 12, b = F - 6
        let brick = C(0x6E3A32), brickD = C(0x52281F), brickL = C(0x8A4C3E)
        let stone = C(0xA8A49C), stoneL = C(0xC8C4BA), stoneD = C(0x7A766E)
        // The lawn and hedge in front, dark.
        u.rect(x - 1, b, 86, 6, C(0x18301E)); u.rect(x - 1, b, 86, 1, C(0x24442A))
        for hx in stride(from: x, to: x + 84, by: 4) where hx < x + 30 || hx > x + 52 {
            u.ellipse(hx + 2, b - 1, 2, 2, C(0x1E3A24)); u.px(hx + 1, b - 2, C(0x2E5234))
        }
        // The cupola and clock, behind the pediment, where there's room for it over the street (in the window's strip
        // the clock moves down into the pediment instead).
        let cupola = b - 64 >= 0
        if cupola {
            u.rect(x + 36, b - 56, 13, 14, stoneD); u.rect(x + 36, b - 56, 1, 14, stoneL)
            u.circle(x + 42, b - 50, 4, C(0x3A3A48)); u.circle(x + 42, b - 50, 3, C(0xF0E6B8))
            u.rect(x + 42, b - 53, 1, 3, C(0x2A2A3A)); u.rect(x + 42, b - 50, 2, 1, C(0x2A2A3A))
            for r in 0..<5 { u.rect(x + 36 + r, b - 61 + r, 13 - 2 * r, 1, r == 4 ? stoneD : C(0x4A5A7A)) }
            u.rect(x + 37, b - 57, 11, 1, stoneL)
            u.rect(x + 42, b - 64, 1, 4, stoneD)
        }
        // The wings: brick, a stone cap, two storeys of windows.
        for wx0 in [x, x + 66] {
            u.rect(wx0, b - 30, 18, 30, brick); u.rect(wx0, b - 30, 1, 30, brickL); u.rect(wx0 + 17, b - 30, 1, 30, brickD)
            for y in stride(from: b - 27, to: b, by: 3) { u.rect(wx0 + 1, y, 16, 1, brickD) }
            u.rect(wx0 - 1, b - 32, 20, 2, stone); u.rect(wx0 - 1, b - 32, 20, 1, stoneL)
            for (i, wx) in [wx0 + 3, wx0 + 10].enumerated() {
                for (j, wy) in [b - 26, b - 14].enumerated() {
                    let lit = (wx0 == x && i == 1 && j == 0) || (wx0 != x && i == 0 && j == 1)
                    u.rect(wx - 1, wy - 1, 6, 1, stoneL); u.rect(wx, wy, 4, 9, lit ? C(0xD8C070) : C(0x141A30))
                    u.rect(wx + 2, wy, 1, 9, lit ? C(0xA88A40) : C(0x222A44)); u.rect(wx, wy + 4, 4, 1, lit ? C(0xA88A40) : C(0x222A44))
                    u.rect(wx - 1, wy + 9, 6, 1, stone)
                }
            }
        }
        // The middle block, in shadow behind the columns, its doors lit.
        u.rect(x + 18, b - 34, 48, 34, C(0x2A2030))
        u.rect(x + 37, b - 16, 10, 13, C(0x1A1420)); u.rect(x + 38, b - 15, 8, 12, C(0xD8B070)); u.rect(x + 42, b - 15, 1, 12, C(0x8A6A3A))
        u.circle(x + 42, b - 18, 3, C(0xFFD890, 0.2)); u.px(x + 42, b - 18, C(0xFFF0C0))
        // The pediment, a triangle with its edge lit, and the frieze with HIGH SCHOOL.
        for r in 0..<10 {
            let half = 2 + r * 23 / 9
            u.rect(x + 42 - half, b - 44 + r, 2 * half + 1, 1, r == 0 ? stoneL : stoneD)
            u.px(x + 42 - half, b - 44 + r, stoneL); u.px(x + 42 + half, b - 44 + r, stoneD)
        }
        if !cupola {
            u.circle(x + 42, b - 39, 3, C(0x3A3A48)); u.circle(x + 42, b - 39, 2, C(0xF0E6B8))
            u.rect(x + 42, b - 41, 1, 2, C(0x2A2A3A)); u.px(x + 43, b - 39, C(0x2A2A3A))
        }
        u.rect(x + 17, b - 35, 51, 1, stoneL)
        u.rect(x + 18, b - 34, 48, 7, stone); u.rect(x + 18, b - 34, 48, 1, stoneL); u.rect(x + 18, b - 28, 48, 1, stoneD)
        eterniaTownText(u, x + 21, b - 33, "HIGH SCHOOL", 1, C(0x2A2A3A))
        // The columns, lit on the left.
        for cx in [x + 20, x + 27, x + 34, x + 49, x + 56, x + 63] {
            u.rect(cx, b - 27, 2, 24, stone); u.rect(cx, b - 27, 1, 24, stoneL); u.px(cx + 1, b - 27, stoneD)
            u.rect(cx - 1, b - 27, 4, 1, stoneL); u.rect(cx - 1, b - 4, 4, 1, stoneD)
        }
        // The steps.
        u.rect(x + 18, b - 3, 48, 1, stoneL); u.rect(x + 17, b - 2, 50, 1, stone); u.rect(x + 16, b - 1, 52, 1, stoneD)
        // The flag on its pole, by the right wing.
        let px = x + 86
        u.rect(px, b - 44, 1, 44, C(0x8A8A9A)); u.px(px, b - 45, C(0xE0C070))
        u.pattern(px + 1, b - 43, ["BBBRRWRR", "BWBWWRWW", "BBBRRWRR", "RRWWRRWR", "WWRRWWRW"],
                  ["B": C(0x2A3A7A), "W": C(0xC8C8D0), "R": C(0xA82A30)])
    }

    /// The town's life: the neon signs glowing, now and then a letter stuttering off and on (the DINER's N most of
    /// all); the bulbs under the diner's sign chasing; the Cosmic Key's portal shimmering open in the alley every
    /// little while, a swirl of blue-white light, and closing again; on the screen saver the bright star twinkling.
    static func eterniaEarthTownLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaEarthTownFrame(c, g), F = f.foot, x0 = f.x0, tall = isTall(c)
        let u = PixelCanvas(f.w, f.h)
        // The neon's glow: a soft halo round each sign, breathing a little.
        let hum = 0.85 + 0.15 * sin(t * 7.3)
        u.ellipse(x0 + 32, F - 44, 26, 10, C(0xFF5AAE, 0.10 * hum))
        u.ellipse(x0 + 78 + 26, F - 28, 26, 8, C(0x4AD8F0, 0.08 * hum))
        // A letter stuttering: the DINER's N every few seconds, now and then another.
        let tick = Int(t * 10)
        if Int(t) % 5 == 2 && tick % 3 != 0 {
            eterniaTownText(u, x0 + 13, F - 48, "DINER", 2, C(0x4A1A36), only: 2)
        } else if noise(Int(t * 4) + 900) > 0.93 {
            eterniaTownText(u, x0 + 78 + 5, F - 33, "MUSIC", 2, C(0x14303A), only: Int(noise(Int(t * 4) + 901) * 5))
        }
        // The bulbs under the sign, chasing along.
        for (i, bx) in stride(from: x0 + 12, to: x0 + 53, by: 3).enumerated() where (i + Int(t * 4)) % 3 == 0 {
            u.px(bx, F - 37, C(0xFFFFFF)); u.px(bx, F - 36, C(0xFFD890, 0.4))
        }
        // The portal, opening in the alley for six seconds every 22: it snaps open in about half a second, stays
        // its full size, and shrinks away again. A deep blue tunnel with a bright rim, three white arms swirling
        // into a white heart, the alley lit blue round it.
        let period = 22.0, open = 6.0, ph = t.truncatingRemainder(dividingBy: period)
        if ph < open {
            let k = min(1, sin(ph / open * .pi) * 2.2), cx = x0 + 71, cy = F - 13
            let rx = max(1, Int((6 * k).rounded())), ry = max(1, Int((12 * k).rounded()))
            u.rect(x0 + 63, F - 30, 16, 30, C(0x7AD0FF, 0.12 * k))
            u.ellipse(cx, cy, rx + 3, ry + 3, C(0x4A7AFF, 0.3 * k))
            u.ellipse(cx, cy, rx, ry, C(0x2A5AE0, 0.9 * k))
            u.ellipse(cx, cy, max(1, rx * 2 / 3), max(1, ry * 2 / 3), C(0x5A9AFF, 0.8 * k))
            // The swirl: three arms winding in to the middle, turning.
            for arm in 0..<3 {
                for st in 0..<16 {
                    let r = 1 - Double(st) / 16, a = Double(arm) * 2.094 + t * 2.6 + (1 - r) * 4.2
                    u.px(cx + Int((cos(a) * Double(rx) * r).rounded()), cy + Int((sin(a) * Double(ry) * r).rounded()),
                         r > 0.5 ? C(0x9AE8FF, 0.95 * k) : C(0xFFFFFF, 0.95 * k))
                }
            }
            u.ellipse(cx, cy, max(1, rx / 3), max(1, ry / 4), C(0xFFFFFF, 0.9 * k))
            // The rim, pale and bright all the way round.
            let steps = 6 * (rx + ry)
            for i in 0..<steps {
                let a = Double(i) / Double(steps) * 2 * .pi
                u.px(cx + Int((cos(a) * Double(rx)).rounded()), cy + Int((sin(a) * Double(ry)).rounded()), C(0xD4F6FF, 0.95 * k))
            }
        }
        // The bright star, twinkling, and the radio mast's red light blinking.
        if tall {
            let (sx, sy) = eterniaTownStar(x0, F)
            if t.truncatingRemainder(dividingBy: 2) < 1.1 {
                let mx = eterniaTownLandmarks(x0).mast
                u.circle(mx, 9, 2, C(0xFF4A3A, 0.3)); u.px(mx, 9, C(0xFF6A50))
            }
            let tw = 0.5 + 0.5 * sin(t * 2.1), r = 2 + Int(tw * 2.5)
            u.rect(sx - r, sy, 2 * r + 1, 1, C(0xFFFFFF, 0.7)); u.rect(sx, sy - r, 1, 2 * r + 1, C(0xFFFFFF, 0.7))
            u.circle(sx, sy, 1, C(0xFFFFFF, 0.6 * tw))
        }
        eterniaPlaces8Blit(c, u, 0, f.y, f.q)
    }
}
