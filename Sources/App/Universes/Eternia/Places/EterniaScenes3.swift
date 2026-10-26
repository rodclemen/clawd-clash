import Foundation

// More places, these on Etheria: the Horde's Fright Zone, the rebels' Whispering Woods and Light Hope's Crystal
// Castle, drawn the same way as EterniaScenes1.swift. Each landmark is drawn once at one pixel to a unit and blown up
// `q` times, so it's the whole picture on the screen saver and still fits the window's strip. Three palettes far
// apart: the Fright Zone's soot greys and Horde red, the Woods' pastels, the Castle's night blues and crystal.

let eterniaScenes3: [Location: Place] = [
    .eterniaFrightZone: Place(name: "The Fright Zone", panel: 0x1C1416, still: Scenes.eterniaFrightZone,
                              moving: Scenes.eterniaFrightZoneLife),
    .eterniaWhisperingWoods: Place(name: "The Whispering Woods", panel: 0x1E1A2C, still: Scenes.eterniaWhisperingWoods,
                                   moving: Scenes.eterniaWhisperingWoodsLife),
    .eterniaCrystalCastle: Place(name: "The Crystal Castle", panel: 0x101830, still: Scenes.eterniaCrystalCastle,
                                 moving: Scenes.eterniaCrystalCastleLife),
]

// MARK: - Shared

extension Scenes {
    /// How many times a landmark drawn `w` units wide is blown up: once in the window, three times or more on the
    /// screen saver (the same rule as Greyskull's).
    private static func eterniaPlaces3Q(_ c: PixelCanvas, _ g: Int, _ w: Int) -> Int {
        max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * w)))
    }

    /// Copies `art` onto `c` with its top left at (`x`, `y`), each of its pixels a `q`×`q` block.
    private static func eterniaPlaces3Blit(_ c: PixelCanvas, _ art: PixelCanvas, _ x: Int, _ y: Int, _ q: Int) {
        for yy in 0..<art.h {
            for xx in 0..<art.w where art.buf[(yy * art.w + xx) * 4 + 3] > 0 {
                c.rect(x + xx * q, y + yy * q, q, q, unpremultiplied(art, (yy * art.w + xx) * 4))
            }
        }
    }
}

// MARK: - The Fright Zone

extension Scenes {
    /// Where the Fright Zone's fortress stands: blown up `q` times, its foot on `base`, its canvas's top left at
    /// `x`/`y`. The plain of slag between it and the crew is wider on the screen saver.
    static func eterniaFrightZoneFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int) {
        let q = eterniaPlaces3Q(c, g, 120)
        let base = g - (isTall(c) ? 10 : 6) * q
        return (q, base, c.w / 2 - 60 * q, base - 56 * q)
    }

    /// The smokestacks, in fortress units: each one's left edge, width and top.
    private static let eterniaFrightStacks: [(x: Int, w: Int, top: Int)] = [(8, 6, 7), (20, 5, 15), (95, 5, 12), (106, 6, 4)]
    /// The red windows, in fortress units: top left, each two wide and three tall.
    private static let eterniaFrightWindows: [(x: Int, y: Int)] = [
        (15, 40), (27, 40), (15, 47), (89, 40), (101, 40), (113, 40), (89, 47), (113, 47),
        (39, 28), (45, 28), (74, 28), (80, 28), (39, 35), (80, 35), (57, 25), (62, 25),
    ]

    /// The Fright Zone: the Horde's fortress on Etheria, under a sky of soot going red at the horizon, a dull red sun
    /// sunk behind it. A great grey keep of riveted plate with a row of spikes along its top, buttresses either side
    /// and a portcullis gate, a tower rising out of it with horns on its crown and the red Horde bat on a black plate
    /// high on its face. A long factory hall with a sawtooth roof runs behind, four smokestacks banded in red standing
    /// out of it, pipes between. Dead trees, bare and twisted, stand either side of the plain of slag the crew stands
    /// on. On the screen saver the fortress stands three times the size, under banks of smog.
    static func eterniaFrightZone(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaFrightZoneFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 22 : 8) * q
        c.gradient(0, f.base, C(0x161014), C(0x8A3828), bands: tall ? 12 : 7)
        // The sun, dull red through the smog, low behind the fortress's right shoulder.
        let sun = (x: f.x + 88 * q, y: horizon - (tall ? 6 : 2) * q, r: 9 * q)
        for (k, a) in [(2.4, 0.08), (1.7, 0.14), (1.3, 0.22)] { c.circle(sun.x, sun.y, Int(Double(sun.r) * k), C(0xE05A30, a)) }
        c.circle(sun.x, sun.y, sun.r, C(0xC8442C)); c.circle(sun.x - sun.r / 5, sun.y - sun.r / 5, sun.r * 3 / 4, C(0xDC5A36))
        // Smog lying across the sky in long bands, sooty on top and lit dull red under.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(4, 14, 40), (52, 8, 44), (20, 30, 36), (70, 26, 34), (2, 46, 30), (58, 44, 38), (30, 60, 26), (80, 62, 22)]
            : [(2, 18, 18), (62, 10, 20), (86, 30, 12), (30, 6, 12)]
        for (k, b) in banks.enumerated() {
            let x = c.w * b.x / 100, y = horizon * b.y / 100, len = b.len * s * (tall ? 2 : 1), t = s * (tall ? 2 : 1)
            let bumps = 3 + k % 3
            for i in 0..<bumps {
                let bx = x + len * (i * 2 + 1) / (bumps * 2), bw = len / bumps + Int(noise(k * 9 + i) * Double(len / 4))
                let bh = 1 + Int(noise(k * 9 + i + 50) * 2.5)
                c.rect(bx - bw / 2, y - bh * t, bw, bh * t, C(0x2E2226))
            }
            c.rect(x, y, len, t, C(0x40282A)); c.rect(x + len / 8, y + t, len * 3 / 4, t, C(0x6A3028))
        }
        // Far off, the rest of the Horde's works: low blocks and chimneys in silhouette along the horizon.
        for k in 0..<(c.w / (9 * s) + 1) {
            let x = k * 9 * s + Int(noise(k + 300) * Double(4 * s)), h = (2 + Int(noise(k + 310) * 5)) * s * (tall ? 2 : 1)
            c.rect(x, horizon - h, 7 * s, h + 1, C(0x4A2624))
            if noise(k + 320) > 0.6 { c.rect(x + 2 * s, horizon - h - 4 * s * (tall ? 2 : 1), s, 4 * s * (tall ? 2 : 1), C(0x4A2624)) }
        }
        c.rect(0, horizon, c.w, f.base - horizon, C(0x4A2624))
        c.dunes(base: horizon + (tall ? 8 : 3) * q, amp: Double(2 * q), freq: 0.04 / Double(q), phase: 1.3, bottom: f.base,
                C(0x362426), shade: C(0x52302C))

        // The fortress, blown up to size.
        let fort = PixelCanvas(120, 56)
        eterniaFrightFortress(fort)
        eterniaPlaces3Blit(c, fort, f.x, f.y, q)

        // The plain of slag in front, plain and dark so the crew reads on it, a ramp down from the gate.
        c.gradient(f.base, g, C(0x3A2E30), C(0x2C2426), bands: 3)
        let gateL = f.x + 52 * q, gateW = 16 * q
        for y in f.base..<g {
            let k = Double(y - f.base) / Double(max(1, g - f.base)), w = Int(Double(gateW) * (1 + 0.9 * k))
            c.rect(gateL + gateW / 2 - w / 2, y, w, 1, (y - f.base) / max(1, q * 2) % 2 == 0 ? C(0x4A4248) : C(0x40383E))
        }
        // Dead trees either side, the nearer ones bigger.
        let trees: [(x: Int, size: Int, seed: Int, flip: Bool)] = [(3, 4, 1, false), (14, 2, 2, true), (85, 2, 3, false), (96, 4, 4, true)]
        for t in trees {
            let tq = max(1, q * t.size / 4), foot = t.size == 4 ? g : f.base + (g - f.base) / 3
            eterniaDeadTree(c, c.w * t.x / 100, foot, tq, seed: t.seed, flip: t.flip)
        }
        c.ground(g, C(0x342C2E), edge: C(0x4E4446), speck: C(0x262022), seed: 15)
    }

    /// A dead tree, bare and twisted, drawn at one pixel to a unit on a canvas of its own and blown up `q` times, its
    /// foot at (`x`, `foot`): a black trunk lit dull red down one side, crooked branches forking to twigs.
    private static func eterniaDeadTree(_ c: PixelCanvas, _ x: Int, _ foot: Int, _ q: Int, seed: Int, flip: Bool) {
        let art = PixelCanvas(30, 40)
        let bark = C(0x231C1E), barkL = C(0x5A3A36), barkM = C(0x3A2A2A)
        /// A branch from (x0, y0) going `len` units at angle `a` (radians, 0 up), forking `depth` more times: a
        /// stroke `wide` units thick all the way along (square dabs, so slanting limbs keep their weight), lit dull
        /// red down its left edge, tapering a unit at each fork.
        func branch(_ x0: Double, _ y0: Double, _ a: Double, _ len: Double, _ wide: Int, _ depth: Int, _ k: Int) {
            let n = max(1, Int(len))
            var x = x0, y = y0
            for i in 0..<n {
                let bend = sin(Double(i) * 0.9 + Double(k)) * 0.25
                x += sin(a + bend); y -= cos(a + bend)
                let lx = Int(x) - wide / 2, ly = Int(y) - (wide - 1) / 2
                art.rect(lx, ly, wide, wide, bark)
                if wide > 2 { art.rect(lx + 1, ly, 1, wide, barkM) }
                art.px(lx, Int(y), barkL)
            }
            guard depth > 0 else { return }
            let spread = 0.5 + noise(seed * 31 + k) * 0.4
            branch(x, y, a - spread, len * 0.66, max(1, wide - 1), depth - 1, k * 2 + 1)
            branch(x, y, a + spread * 0.8, len * 0.58, max(1, wide - 1), depth - 1, k * 2 + 2)
        }
        // The trunk, leaning a little and thick, its roots spread over the ground.
        art.rect(10, 36, 10, 4, bark); art.rect(7, 38, 16, 2, bark); art.px(6, 39, bark); art.px(23, 39, bark)
        art.rect(7, 38, 2, 1, barkL); art.rect(10, 36, 1, 2, barkL)
        branch(14.5, 38, 0.1, 15, 5, 0, 0)
        branch(15, 25, -0.6, 11, 3, 2, 1)
        branch(16, 27, 0.7, 10, 3, 2, 2)
        branch(16, 24, 0.05, 9, 3, 2, 3)
        // A knot hole, dark, its lower lip lit.
        art.rect(14, 30, 2, 2, C(0x0E0A0A)); art.rect(14, 32, 2, 1, barkL)
        let draw = flip ? { () -> PixelCanvas in
            let m = PixelCanvas(30, 40)
            for yy in 0..<40 { for xx in 0..<30 where art.buf[(yy * 30 + xx) * 4 + 3] > 0 { m.px(29 - xx, yy, unpremultiplied(art, (yy * 30 + xx) * 4)) } }
            return m
        }() : art
        eterniaPlaces3Blit(c, draw, x - 15 * q, foot - 40 * q, q)
    }

    /// The Horde's fortress, one pixel to a unit on a 120×56 canvas, its foot on row 55: the factory hall and its
    /// smokestacks at the back, the keep and its buttresses, the tower with the bat, the gate.
    static func eterniaFrightFortress(_ c: PixelCanvas) {
        // Soot-grey plate in six tones, darkest first; the sunset catches the left edges dull red.
        let tone = [C(0x1C1C22), C(0x2A2A32), C(0x3A3A44), C(0x4C4C56), C(0x62626C), C(0x7E7E88)]
        let rim = C(0xA85444), red = C(0xC42418), redD = C(0x7A1410), deep = C(0x0E0A0C)
        /// A block of plate from (x0, y0), `w` wide, down to the foot: lit on the left, dark on the right, seams in
        /// rows and columns and a rivet at each crossing.
        func block(_ x0: Int, _ w: Int, _ y0: Int, _ t: Int, seam: Int = 6) {
            c.rect(x0, y0, w, 56 - y0, tone[t])
            c.rect(x0, y0, 1, 56 - y0, tone[min(5, t + 1)]); c.rect(x0 + w - 1, y0, 1, 56 - y0, tone[max(0, t - 2)])
            for y in stride(from: y0 + seam, to: 55, by: seam) {
                c.rect(x0 + 1, y, w - 2, 1, tone[max(0, t - 1)])
                for x in stride(from: x0 + 3, to: x0 + w - 2, by: 6) { c.px(x, y - 1, tone[min(5, t + 1)]) }
            }
            c.rect(x0, y0, w, 1, tone[min(5, t + 1)])
        }
        /// A smokestack: a round chimney, shaded as a cylinder, rings down it, a red band and a lip at the top.
        func stack(_ x0: Int, _ w: Int, _ top: Int) {
            for x in x0..<(x0 + w) {
                let k = Double(x - x0) / Double(max(1, w - 1)), t = k < 0.25 ? 4 : k < 0.6 ? 3 : k < 0.85 ? 2 : 1
                c.rect(x, top, 1, 56 - top, tone[t])
            }
            for y in stride(from: top + 8, to: 52, by: 5) { c.rect(x0, y, w, 1, tone[1]) }
            c.rect(x0, top + 3, w, 2, red); c.rect(x0 + w - 2, top + 3, 2, 2, redD); c.px(x0, top + 3, C(0xE85A3A))
            c.rect(x0 - 1, top, w + 2, 2, tone[3]); c.rect(x0 - 1, top, w + 2, 1, tone[4]); c.rect(x0 + w, top, 1, 2, tone[1])
            c.rect(x0, top, w, 1, deep)
            c.px(x0 - 1, top, rim)
        }

        // The factory hall across the back, its roof in sawtooth bays, the stacks standing out of it.
        block(4, 112, 38, 2)
        for x in 4..<116 {
            let d = (x - 4) % 8, h = d < 6 ? d / 2 : 0
            c.rect(x, 37 - h, 1, h + 1, d < 6 ? tone[3] : tone[1])
            if d == 5 { c.rect(x, 34, 1, 4, tone[1]) }
        }
        c.px(4, 37, rim)
        for s in eterniaFrightStacks { stack(s.x, s.w, s.top) }
        // Pipes from the inner stacks to the keep, and one along the hall.
        for (x0, x1) in [(25, 32), (88, 95)] {
            c.rect(x0, 29, x1 - x0, 3, tone[3]); c.rect(x0, 29, x1 - x0, 1, tone[4]); c.rect(x0, 31, x1 - x0, 1, tone[1])
            c.rect(x0 + 2, 28, 2, 5, tone[2])
        }
        c.rect(4, 51, 112, 2, tone[3]); c.rect(4, 51, 112, 1, tone[4])

        // The keep: a great block of plate, a raking buttress either side: a straight slope, one column out every
        // two rows, its sloped face lit (dull red on the sunset side), plate courses across it and a cap at the top.
        for y in 32..<56 {
            let k = (y - 32) / 2 + 1
            c.rect(36 - k, y, k, 1, tone[3]); c.rect(84, y, k, 1, tone[1])
            // The sloped faces: a bright edge and a softer one just inside it.
            c.px(36 - k, y, (y - 32) % 2 == 0 ? rim : tone[5]); c.px(37 - k, y, tone[4])
            c.px(83 + k, y, tone[2]); c.px(82 + k, y, tone[2])
            if y % 6 == 3 && k > 2 {
                c.rect(37 - k, y, k - 1, 1, tone[2]); c.rect(84, y, k - 1, 1, tone[0])
                c.px(37 - k + (k - 1) / 2, y - 1, tone[5]); c.px(84 + (k - 1) / 2, y - 1, tone[2])
            }
        }
        c.rect(34, 30, 3, 2, tone[5]); c.px(34, 30, rim); c.rect(84, 30, 3, 2, tone[2]); c.rect(84, 30, 3, 1, tone[3])
        block(36, 48, 24, 3)
        c.rect(36, 24, 1, 32, rim)
        // A row of spikes along its top.
        for x in stride(from: 36, to: 84, by: 4) {
            c.pattern(x, 20, ["..T.", ".TTs", ".TTs", "TTTs"], ["T": tone[4], "s": tone[2]])
        }
        c.px(38, 20, rim)
        // The tower: rising out of the keep, a crown of plate at its top and three horns on it.
        block(48, 24, 8, 3, seam: 7)
        c.rect(48, 8, 1, 16, rim)
        c.rect(46, 4, 28, 5, tone[3]); c.rect(46, 4, 28, 1, tone[5]); c.rect(46, 4, 2, 5, tone[4]); c.rect(72, 4, 2, 5, tone[1])
        c.rect(46, 8, 28, 1, tone[1])
        for x in stride(from: 49, to: 72, by: 4) { c.px(x, 6, tone[1]) }
        // Two great horns curling up and out from the crown's corners, and a spike between them.
        c.pattern(42, 0, ["T.....", "TT....", ".TT...", ".TTs..", "..TTs.", "...TTs"], ["T": tone[4], "s": tone[2]])
        c.pattern(72, 0, [".....s", "....ss", "...Ts.", "..TTs.", ".TTs..", "TTs..."], ["T": tone[3], "s": tone[1]])
        c.pattern(57, 0, ["..Ts..", ".TTss.", ".TTss.", "TTTsss"], ["T": tone[4], "s": tone[2]])
        c.px(42, 0, rim); c.px(59, 0, rim)
        // The Horde bat on its plate, high on the tower's face: wings swept up, a horned head with yellow eyes.
        c.rect(50, 10, 20, 12, deep); c.rect(50, 10, 20, 1, tone[1]); c.rect(50, 21, 20, 1, tone[4])
        c.pattern(51, 11, [
            "R................R",
            "RR......R..R....RR",
            "RRR.....RRRR...RRR",
            "RRRR...RRRRRR.RRRR",
            "RRRRRRRRRRRRRRRRRR",
            ".RRRRRRRYRRYRRRRR.",
            "..RRRRRRRRRRRRRR..",
            "...RRR.RRRRRR.RR..",
            "....R...RRRR...R..",
            ".........RR.......",
        ], ["R": red, "Y": C(0xF0D040)])
        // Its lit edges, so it glows on the black.
        for (x, y) in [(51, 11), (52, 12), (53, 13), (54, 14), (59, 12), (60, 12)] { c.px(x, y, C(0xF05A3A)) }
        // The gate: an arch of plate, black inside, a red glow at its foot and the portcullis bars across it.
        c.rect(51, 40, 18, 16, tone[1])
        c.rect(53, 43, 14, 13, deep); c.rect(54, 42, 12, 1, deep)
        c.rect(53, 53, 14, 3, C(0x3A0E0C)); c.rect(55, 52, 10, 1, C(0x2A0A0A))
        for x in stride(from: 54, to: 67, by: 3) { c.rect(x, 43, 1, 10, tone[3]) }
        for y in [46, 50] { c.rect(53, y, 14, 1, tone[3]) }
        c.pattern(55, 38, ["..T..T..T..", ".TTsTTsTTs.", "TTTsTTsTTss"], ["T": tone[4], "s": tone[2]])
        // The red windows, lit from inside.
        for w in eterniaFrightWindows {
            c.rect(w.x - 1, w.y - 1, 4, 5, tone[1])
            c.rect(w.x, w.y, 2, 3, red); c.px(w.x, w.y, C(0xF06A40)); c.px(w.x + 1, w.y + 2, redD)
        }
    }

    /// The Fright Zone's life: smoke belching from the stacks, rolling up and drifting off, and the red windows
    /// flickering as the furnaces inside flare and die.
    static func eterniaFrightZoneLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaFrightZoneFrame(c, g), q = f.q, tall = isTall(c)
        let rise = Double((tall ? 44 : 12) * q)
        for (i, st) in eterniaFrightStacks.enumerated() {
            let cx = Double(f.x + (st.x * 2 + st.w) * q / 2), top = Double(f.y + st.top * q)
            // Every few seconds a stack belches: its puffs come thicker for a moment.
            let belch = max(0, sin(t * 0.7 + Double(i) * 1.9))
            for k in 0..<12 {
                let ph = (t * 0.16 + Double(k) / 12 + Double(i) * 0.13).truncatingRemainder(dividingBy: 1)
                let x = cx + ph * Double(9 * q) + sin(t * 0.8 + Double(k + i)) * Double(q)
                let y = top - Double(q) - ph * rise
                let r = Double(q) * (1.5 + ph * (tall ? 5 : 3)) * (1 + 0.3 * belch)
                // Thick near the stack, thinning as it climbs: a sooty puff, its top catching grey light, its
                // underside the furnace's red.
                let a = min(1, (1 - ph) * 1.6) * (0.75 + 0.25 * belch)
                c.circle(Int(x), Int(y), Int(r), C(0x3E3638, a))
                c.circle(Int(x + r / 4), Int(y + r / 3), Int(r * 0.6), C(0x6A2C26, a))
                c.circle(Int(x - r / 4), Int(y - r / 4), Int(r * 0.65), C(0x5A5254, a))
                c.circle(Int(x - r / 3), Int(y - r / 3), Int(r * 0.35), C(0x7A7072, a))
            }
        }
        // The windows: now and then one flares bright or goes nearly dark.
        for (i, w) in eterniaFrightWindows.enumerated() {
            let v = noise(Int(t * 5) * 7 + i * 37)
            guard v > 0.78 || v < 0.12 else { continue }
            c.rect(f.x + w.x * q, f.y + w.y * q, 2 * q, 3 * q, v > 0.78 ? C(0xFF8A50, 0.85) : C(0x3A0A08, 0.8))
        }
    }
}

// MARK: - The Whispering Woods

extension Scenes {
    /// The Whispering Woods are drawn whole on a small canvas, one pixel to a unit, and blown up `q` times: `w`×`h`
    /// units, its bottom row resting on the ground row, its top at `y` (a little above the frame when `g` doesn't
    /// divide by `q`). On the screen saver there's room for the trunks to climb a long way up into the canopy.
    static func eterniaWhisperingWoodsFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, w: Int, h: Int, y: Int) {
        let q = eterniaPlaces3Q(c, g, 120)
        let w = c.w / q + 2, h = (g + q - 1) / q
        return (q, w, h, g - h * q)
    }

    /// The Whispering Woods: the rebels' forest on Etheria, in pastels. A haze of lavender going pink and peach, far
    /// trees pale lilac in it, nearer ones a deeper violet, and three giant trees in front: trunks of violet bark
    /// lit from the left, grooved, mossy in mint, their roots spread over the ground. Above, the canopy of teal and
    /// mint leaves dotted with pink blossom hangs down in lobes, and soft shafts of light come through it. The
    /// undergrowth under the trees is in shadow, and the path the crew stands on is dark moss. On the screen saver
    /// the trunks rise a long way up into the canopy.
    static func eterniaWhisperingWoods(_ c: PixelCanvas, _ g: Int) {
        let f = eterniaWhisperingWoodsFrame(c, g), tall = isTall(c)
        let a = PixelCanvas(f.w, f.h)
        eterniaWoods(a, canopy: tall ? f.h * 30 / 100 : 9, q: f.q)
        eterniaPlaces3Blit(c, a, 0, f.y, f.q)
        c.ground(g, C(0x3A5A54), edge: C(0x5A8070), speck: C(0x2E4A46), seed: 23)
        // Fallen petals on the path, a few.
        for i in 0..<(c.w / 14) {
            let x = Int(noise(i * 5 + 900) * Double(c.w)), y = g + 1 + Int(noise(i * 5 + 901) * Double(max(1, c.h - g - 2)))
            c.rect(x, y, max(1, f.q), max(1, f.q / 2), noise(i * 5 + 902) > 0.5 ? C(0xE8A0C0) : C(0x9AD8C0))
        }
    }

    /// The woods themselves, on a canvas of their own at one pixel to a unit; `canopy` is the row the canopy's
    /// underside hangs down to (its lobes hang lower), `q` how many times it will be blown up.
    private static func eterniaWoods(_ c: PixelCanvas, canopy cb: Int, q: Int) {
        let w = c.w, h = c.h
        // Where the crew stands in front: their heads come up about 36 pixels over the ground, whatever the scale.
        // From a little over that down to the ground the woods sink into dusk, so white outlines and names read on
        // them; the pastels stay above, in the light.
        let crewTop = h - 36 / q, duskTop = max(cb + 4, crewTop - 12 / q)
        func dusk(_ col: Px, _ strength: Double) {
            for y in duskTop..<h {
                let k = Double(y - duskTop) / Double(max(1, h - duskTop))
                let a = strength * min(1, k * 1.5)
                c.rect(0, y, w, 1, col.alpha((a * 8).rounded() / 8))
            }
        }
        // The haze between the trees: lavender up top, pink, then peach low down, and darker under the trees.
        c.gradient(0, h * 7 / 10, C(0xB0A0E0), C(0xF6C8D6), bands: 6)
        c.gradient(h * 7 / 10, h, C(0xE8B4C8), C(0x7A6A90), bands: 4)

        /// A trunk from the ground up past the canopy: `x0`, `tw` wide, in a ramp of tones darkest first, grooved,
        /// its roots flaring out over the bottom rows when `roots` is set.
        func trunk(_ x0: Int, _ tw: Int, _ ramp: [Px], roots: Bool, seed: Int) {
            for y in 0..<h {
                let flare = roots ? max(0, 9 - (h - y)) : 0
                let l = x0 - flare * flare / 6, r = x0 + tw + flare * flare / 5
                for x in l..<r {
                    let k = Double(x - l) / Double(max(1, r - l - 1)) + (noise(x * 7 + y * 13) - 0.5) * 0.08
                    var t = k < 0.18 ? 4 : k < 0.45 ? 3 : k < 0.75 ? 2 : k < 0.92 ? 1 : 0
                    // The grooves of the bark, wavering down the trunk.
                    let gx = (x - x0 + 50 + Int(sin(Double(y) * 0.21 + Double(seed)) * 1.5)) % 5
                    if tw > 9 && gx == 0 && t > 0 { t -= 1 }
                    c.px(x, y, ramp[min(ramp.count - 1, t)])
                }
            }
        }

        // The far trees, pale in the haze.
        let far = [C(0x9C8CC0), C(0xAE9CCC), C(0xBCACD6), C(0xCCBCE0), C(0xDACCE8)]
        for k in 0..<(w / 11 + 1) {
            let x = k * 11 + Int(noise(k + 600) * 6), tw = 3 + Int(noise(k + 610) * 3)
            trunk(x, tw, far, roots: false, seed: k)
        }
        // Dusk falling among the far trees, deep violet behind the crew.
        dusk(C(0x3E3260), 0.82)
        // The nearer trees, deeper violet, branches reaching up into the leaves.
        let mid = [C(0x5E4A7A), C(0x6E5A8A), C(0x80689A), C(0x9478AA), C(0xA88ABA)]
        for k in 0..<(w / 34 + 1) {
            let x = k * 34 + 14 + Int(noise(k + 620) * 12), tw = 7 + Int(noise(k + 630) * 3)
            trunk(x, tw, mid, roots: true, seed: k + 5)
            for (dx, dir) in [(1, -1), (tw - 2, 1)] {
                for i in 0..<10 { c.rect(x + dx + dir * i, cb + 6 - i, 2, 1, mid[1]) }
            }
        }
        // The undergrowth under them, in shade: low mounds of dusky teal, plain so the crew reads on them.
        for x in 0..<w {
            let top = h - 7 - Int((sin(Double(x) * 0.19) * 0.6 + sin(Double(x) * 0.07 + 1) * 0.4) * 2.5)
            c.rect(x, top, 1, h - top, C(0x3E5868)); c.px(x, top, C(0x587886))
        }

        // And deeper still over the nearer trees and the undergrowth.
        dusk(C(0x2A2244), 0.5)

        // Shafts of light down through the canopy, leaning right, fading out before they reach the crew.
        for k in 0..<(w / 40 + 1) {
            let x0 = k * 40 + 6 + Int(noise(k + 640) * 20), sw = 5 + Int(noise(k + 650) * 6)
            for y in cb..<max(cb, duskTop) {
                let x = x0 + (y - cb) / 3
                c.rect(x, y, sw, 1, C(0xFFF2D8, 0.16 * (1 - Double(y - cb) / Double(h))))
            }
        }

        // The giant trees in front.
        let near = [C(0x3A2846), C(0x4E3660), C(0x684A78), C(0x86628E), C(0xA27EA6)]
        let giants: [(x: Int, tw: Int)] = [(w * 8 / 100, 26), (w * 54 / 100, 21), (w * 88 / 100, 28)]
        for (i, t) in giants.enumerated() {
            let x0 = t.x - t.tw / 2
            trunk(x0, t.tw, near, roots: true, seed: i * 3 + 1)
            // Branches up into the leaves either side.
            for (dx, dir) in [(2, -1), (t.tw - 4, 1)] {
                for j in 0..<16 { c.rect(x0 + dx + dir * j, cb + 10 - j * 2 / 3, 4, 2, near[dir < 0 ? 3 : 1]) }
            }
            // Ivy climbing the trunk: a vine winding up from the roots, leaves of mint either side of it.
            let ivyX = x0 + t.tw * (i == 1 ? 6 : 2) / 10
            for y in stride(from: h - 4, to: cb + 6, by: -1) {
                let vx = ivyX + Int(sin(Double(y) * 0.28 + Double(i * 2)) * 3)
                c.px(vx, y, C(0x3E7A62))
                if (y + i) % 3 == 0 {
                    let side = (y / 3) % 2 == 0 ? -1 : 1
                    c.rect(vx + (side < 0 ? -2 : 1), y, 2, 1, C(0x7CC4A0)); c.px(vx + (side < 0 ? -2 : 2), y - 1, C(0xA8E2C2))
                }
            }
            // A knot hole, dark, its rim lit.
            let ky = cb + (h - cb) * (3 + i) / 9, kx = x0 + t.tw * (i == 1 ? 3 : 7) / 10
            c.ellipse(kx, ky, 2, 3, C(0x1E1428)); c.px(kx - 2, ky - 2, near[4]); c.px(kx - 2, ky - 1, near[4])
        }

        // The canopy: masses of leaves across the top, lobes hanging down, shaded darker underneath and lit on top,
        // dotted with pink blossom.
        let leaf = [C(0x2A5E62), C(0x3A7C78), C(0x56A090), C(0x7CC4A8), C(0xA8E2C2)]
        c.rect(0, 0, w, max(0, cb - 4), leaf[1])
        // Lighter masses higher in the canopy, so it isn't one flat lid.
        for k in 0..<(w * max(0, cb - 4) / 50) {
            let x = Int(noise(k * 3 + 800) * Double(w)), y = Int(noise(k * 3 + 801) * Double(max(1, cb - 4)))
            let r = 5 + Int(noise(k * 3 + 802) * 5)
            c.ellipse(x, y + 1, r, r * 2 / 3, leaf[0])
            c.ellipse(x, y, r, r * 2 / 3, leaf[2])
            c.ellipse(x - r / 4, y - r / 4, r / 2, r / 3, leaf[3])
        }
        for k in 0..<(w / 7 + 2) {
            let x = k * 7 - 3 + Int(noise(k + 700) * 5)
            let r = 6 + Int(noise(k + 710) * 6)
            let cy = cb - r / 2 + Int(noise(k + 720) * Double(r))
            c.ellipse(x, cy + 2, r + 1, r * 2 / 3 + 1, leaf[0])
            c.ellipse(x, cy, r, r * 2 / 3, leaf[1])
            c.ellipse(x - r / 4, cy - r / 4, r * 2 / 3, r / 2, leaf[2])
            c.ellipse(x - r / 3, cy - r / 2, r / 3, r / 4, leaf[3])
        }
        // Blossom: round clumps of pink among the leaves, lit on top and shaded rose underneath, so they read as
        // flowers and not as twinkling stars.
        for k in 0..<(w * (cb + 6) / 150) {
            let x = Int(noise(k * 2 + 850) * Double(w - 4)), y = Int(noise(k * 2 + 851) * Double(cb + 6))
            guard y < h - 4 else { continue }
            let i = (min(h - 1, y + 1) * w + x + 1) * 4
            guard c.buf[i + 1] > c.buf[i] && c.buf[i + 1] > 0x50 else { continue }
            let big = noise(k * 2 + 852) > 0.6
            c.pattern(x, y, big ? [".LP..", "LPPPP", "PPPPd", "PPPdd", ".dd.."] : [".LP.", "LPPP", "PPPd", ".dd."],
                      ["P": C(0xF0A0C8), "L": C(0xFFD8EA), "d": C(0xB8608E)])
        }
        // Vines hanging from the canopy between the trunks, a blossom at the end of each.
        for k in 0..<(w / 23 + 1) {
            let x = k * 23 + 9 + Int(noise(k + 880) * 10), len = 6 + Int(noise(k + 890) * Double(max(6, (h - cb) / 3)))
            for y in (cb + 2)..<max(cb + 2, min(h - 10, cb + 2 + len)) {
                let vx = x + Int(sin(Double(y) * 0.4 + Double(k)) * 1.2)
                c.px(vx, y, C(0x3E7A70))
                if y % 3 == k % 3 { c.px(vx + 1, y, C(0x7CC4A8)) }
            }
            c.px(x, min(h - 11, cb + 1 + len), C(0xF0A0C8))
        }
    }

    /// The Woods' life: leaves and petals drifting down through the shafts of light, rocking as they fall.
    static func eterniaWhisperingWoodsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let q = eterniaWhisperingWoodsFrame(c, g).q, tall = isTall(c)
        let cols = [C(0xF0A0C8), C(0xA8E2C2), C(0xFFD0E6), C(0x7CC4A8)]
        for k in 0..<(tall ? 26 : 12) {
            let speed = 0.05 + noise(k * 7 + 40) * 0.05
            let ph = (t * speed + noise(k * 7 + 41)).truncatingRemainder(dividingBy: 1)
            let y = Int(ph * Double(g - q))
            let x = Int(noise(k * 7 + 42) * Double(c.w)) + Int(sin(t * 1.3 + Double(k)) * Double(4 * q))
            let flat = Int(t * 2 + Double(k)) % 2 == 0
            c.rect(x, y, (flat ? 2 : 1) * q, (flat ? 1 : 2) * q, cols[k % 4])
        }
    }
}

// MARK: - The Crystal Castle

extension Scenes {
    /// Where the Crystal Castle stands: blown up `q` times, the foot of its hill on `base`, its canvas's top left at
    /// `x`/`y`, and `peak` the tip of its tallest spire.
    static func eterniaCrystalCastleFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, base: Int, x: Int, y: Int,
                                                                         peak: (x: Int, y: Int)) {
        let q = eterniaPlaces3Q(c, g, 120)
        let base = g - (isTall(c) ? 8 : 4) * q
        let x = c.w / 2 - 60 * q, y = base - 56 * q
        return (q, base, x, y, (x + 60 * q + q / 2, y))
    }

    /// The Crystal Castle: Light Hope's castle on its hill, at night under an indigo sky full of stars. A cluster of
    /// crystal spires, six-sided and pointed, pale blue and white with a blush of lilac, cut into facets lit from
    /// the left; the tallest in the middle, with a column of light inside it that runs every colour of the rainbow,
    /// and a glowing arched door at its foot. A terrace of crystal blocks rings them, the hill falls away in dark
    /// teal grass with a pale path up it, and shards of crystal stick up out of the meadow in front. On the screen
    /// saver the castle stands three times the size under an aurora, beams of light fanning out of its peak.
    static func eterniaCrystalCastle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaCrystalCastleFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.base - (tall ? 18 : 6) * q
        c.gradient(0, f.base, C(0x0C1030), C(0x34507E), bands: tall ? 12 : 7)
        c.stars(0, horizon, density: tall ? 50 : 70, seed: 31)
        if tall {
            // An aurora across the top: two curtains hanging in folds, as a real one does: brightest along a wavy
            // lower hem of green, rays of light climbing from it and fading softly upwards, going teal and then
            // pink-violet at their tops. Each ray its own height and brightness, so the curtain looks pleated.
            let curtains: [(hem: Int, len: Int, amp: Double, freq: Double, ph: Double, peak: Double)] = [
                (horizon * 30 / 100, 34, 10, 0.022, 0.0, 0.58), (horizon * 17 / 100, 22, 7, 0.031, 2.2, 0.38),
            ]
            let green = C(0x7CF5B4), teal = C(0x5ADCD8), pink = C(0xE07AE0)
            for cu in curtains {
                for x in 0..<c.w {
                    let xs = Double(x) / Double(s)
                    let hem = cu.hem + Int((sin(xs * cu.freq + cu.ph) * cu.amp + sin(xs * cu.freq * 2.7 + cu.ph * 3) * cu.amp * 0.4) * Double(s))
                    // The rays: a few units wide each, every one its own height and strength.
                    let ray = Int(xs / 3)
                    let ry = 0.55 + noise(ray + Int(cu.ph * 10) + 70) * 0.45
                    let len = Int(Double(cu.len * s) * (0.6 + noise(ray + Int(cu.ph * 10) + 90) * 0.6))
                    // The curtain thins out at its ends and in a gap or two along it.
                    let span = 0.5 + 0.5 * sin(xs * 0.008 + cu.ph * 1.7)
                    let strength = cu.peak * ry * min(1, span * 1.6)
                    guard strength > 0.03, len > 0 else { continue }
                    for y in max(0, hem - len)...hem {
                        let k = Double(hem - y) / Double(len)   // 0 at the hem, 1 at the top of the ray
                        let a = strength * (k < 0.06 ? 0.6 + k / 0.06 * 0.4 : pow(1 - k, 1.6))
                        let col = k < 0.3 ? lerp(green, teal, k / 0.3) : lerp(teal, pink, (k - 0.3) / 0.4)
                        c.px(x, y, col.alpha((a * 12).rounded() / 12))
                    }
                    // The hem itself, a bright green line.
                    c.px(x, hem + 1, green.alpha(strength * 0.5))
                }
            }
            // A big pale moon, low on the left.
            let mx = c.w * 16 / 100, my = horizon * 40 / 100, mr = 12 * s
            c.circle(mx, my, mr * 2, C(0xC8D8FF, 0.08)); c.circle(mx, my, mr, C(0xDCE4F4))
            c.circle(mx + mr / 3, my + mr / 5, mr * 4 / 5, C(0xC4CCE4)); c.circle(mx - mr / 3, my - mr / 3, mr / 4, C(0xB4BCD8))
        }
        // Far hills in ranges of blue, the nearer darker.
        c.dunes(base: horizon, amp: Double(5 * s), freq: 0.05 / Double(s), phase: 0.4, bottom: f.base, C(0x2C3A68), shade: C(0x3E5080))
        c.dunes(base: horizon + (tall ? 10 : 4) * s, amp: Double(3 * s), freq: 0.08 / Double(s), phase: 2.1, bottom: f.base,
                C(0x1E2A4E), shade: C(0x2C3C62))

        // The castle and its hill, blown up to size.
        let castle = PixelCanvas(120, 56)
        eterniaCrystalCastleArt(castle)
        eterniaPlaces3Blit(c, castle, f.x, f.y, q)

        // The meadow in front, dark teal and plain, shards of crystal up out of it to the sides.
        c.gradient(f.base, g, C(0x1E3A40), C(0x182C34), bands: 3)
        let shards: [(x: Int, h: Int)] = [(3, 7), (7, 4), (11, 5), (88, 4), (93, 8), (97, 5)]
        for sh in shards {
            let x = c.w * sh.x / 100, hh = sh.h * q, hw = max(1, q * 3 / 2)
            for y in 0..<hh {
                let half = min(hw, y / 2)
                c.rect(x - half, g - hh + y, half, 1, C(0xC8ECFA)); c.rect(x, g - hh + y, half + 1, 1, C(0x6AA4D0))
            }
        }
        c.ground(g, C(0x24403E), edge: C(0x3E6460), speck: C(0x1A302E), seed: 29)
    }

    /// The castle and its hill, one pixel to a unit on a 120×56 canvas, the hill's foot on row 55.
    static func eterniaCrystalCastleArt(_ c: PixelCanvas) {
        // Crystal in six tones, darkest first, a blush of lilac in the middle ones; grass in five.
        let ice = [C(0x2E4C8A), C(0x4A74B4), C(0x74A6D8), C(0xA6D0EE), C(0xD4EEFA), C(0xF6FCFF)]
        let blush = C(0xD8C4F4), grass = [C(0x163030), C(0x1E4040), C(0x285250), C(0x346660), C(0x447A6E)]

        // The hill: a broad mound of dark teal grass, lit on the left, a pale path winding up to the door.
        func hillTop(_ x: Int) -> Int { 45 + Int(12 * pow(abs(Double(x) - 60) / 62, 1.6)) }
        for x in 0..<120 {
            let top = hillTop(x)
            for y in top..<56 {
                let side = Double(60 - x) / 60 * 0.7, depth = Double(y - top) / 16, grain = (noise(x * 13 + y * 71) - 0.5) * 0.25
                c.px(x, y, grass[max(0, min(4, Int(2.6 + (side - depth + grain) * 2)))])
            }
            c.px(x, top, grass[4])
            // Tufts of grass along the brow.
            if noise(x * 5 + 77) > 0.7 { c.px(x, top - 1, grass[3]) }
        }
        for y in 47..<56 {
            let k = Double(y - 47) / 9, x = 60 + Int(sin(k * 3.2) * 7 * k), pw = 3 + Int(k * 4)
            c.rect(x - pw / 2, y, pw, 1, C(0x6A8A8A)); c.px(x - pw / 2, y, C(0x8AAAA6))
        }

        /// A crystal spire: six-sided, `hw` either side of `cx`, its body from `top` down to `foot` and its point
        /// `tip` rows above `top`. Three faces seen: lit left, the front, the shaded right, bright edges between
        /// them, a chevron of facets just under the point and a cut across each face lower down.
        func spire(_ cx: Int, _ hw: Int, _ top: Int, _ tip: Int, foot: Int, tint: Bool) {
            let l = cx - hw + hw * 2 * 3 / 10, r = cx - hw + hw * 2 * 7 / 10
            for y in (top - tip)..<foot {
                let half = y < top ? hw * (y - top + tip) / tip : hw
                guard half > 0 else { c.px(cx, y, ice[5]); continue }
                for x in (cx - half)...(cx + half) {
                    var t = x < l ? 4 : x <= r ? 3 : 2
                    if y < top { t = x < cx ? 5 : x == cx ? 4 : 2 }
                    // The faces darken a little towards the foot.
                    if y > foot - (foot - top) / 3 && t > 2 { t -= 1 }
                    c.px(x, y, tint && t == 3 && (y * 3 + x) % 9 < 2 ? blush : ice[t])
                }
                c.px(cx - half, y, ice[5]); c.px(cx + half, y, ice[1])
            }
            c.rect(l, top, 1, foot - top, ice[5]); c.rect(r, top, 1, foot - top, ice[1])
            // The chevron under the point.
            for d in 0...hw {
                c.px(cx - hw + d, top + d / 2, ice[5]); c.px(cx + hw - d, top + d / 2, ice[1])
            }
            // A cut across each face, stepping down from the lit side.
            let cut = top + (foot - top) / 2
            if foot - top > 8 {
                c.rect(cx - hw + 1, cut - 1, l - (cx - hw) - 1, 1, ice[5])
                c.rect(l + 1, cut + 1, r - l - 1, 1, ice[4])
                c.rect(r + 1, cut + 2, cx + hw - r - 1, 1, ice[1])
            }
            // A glint high on the lit face.
            c.px(cx - hw + 1, top + 2, C(0xFFFFFF)); c.px(cx - hw + 2, top + 3, C(0xFFFFFF))
        }

        // The spires, the outer ones first, the tallest in the middle, shards leaning out at the ends.
        for (x, y) in [(9, 44), (10, 43), (11, 42), (12, 41), (10, 44), (11, 43), (12, 42)] { c.px(x, y, ice[3]) }
        for (x, y) in [(110, 44), (109, 43), (108, 42), (107, 41), (109, 44), (108, 43), (107, 42)] { c.px(x, y, ice[2]) }
        spire(15, 2, 37, 4, foot: 46, tint: false); spire(105, 2, 36, 4, foot: 46, tint: false)
        spire(23, 4, 29, 6, foot: 46, tint: true); spire(97, 4, 28, 6, foot: 46, tint: true)
        spire(33, 5, 21, 8, foot: 46, tint: false); spire(87, 5, 20, 8, foot: 46, tint: false)
        spire(45, 6, 13, 10, foot: 46, tint: true); spire(75, 6, 12, 10, foot: 46, tint: true)
        spire(60, 10, 14, 14, foot: 47, tint: true)
        // The chamber the column of light climbs, up the middle of the tallest and on into its point: a pale window
        // (the light itself is in the moving layer).
        for y in 6..<38 {
            let hw = y < 16 ? (y - 6) * 3 / 10 : 3
            c.rect(60 - hw, y, hw * 2 + 1, 1, ice[5])
            c.px(60 - hw - 1, y, ice[4]); c.px(60 + hw + 1, y, ice[1])
        }
        // The terrace: a ring of crystal blocks round the foot of the spires.
        for (i, x) in stride(from: 12, to: 108, by: 6).enumerated() {
            let bh = 3 + i % 2
            c.rect(x, 47 - bh, 6, bh + 1, ice[2]); c.rect(x, 47 - bh, 6, 1, ice[4]); c.rect(x, 47 - bh, 1, bh + 1, ice[4])
            c.rect(x + 5, 47 - bh, 1, bh + 1, ice[0])
        }
        // The door: an arch at the foot of the tallest, glowing white-gold.
        c.rect(55, 38, 11, 10, ice[0]); c.rect(56, 37, 9, 1, ice[0]); c.rect(58, 36, 5, 1, ice[0])
        c.rect(56, 39, 9, 9, C(0xFFF4D0)); c.rect(57, 38, 7, 1, C(0xFFF4D0)); c.rect(58, 37, 5, 1, C(0xFFF4D0))
        c.rect(59, 40, 3, 8, C(0xFFFFFF))
    }

    /// Where the crystal glints on the screen, in castle units: edges and points that catch the light.
    private static let eterniaCrystalGlints: [(x: Int, y: Int)] = [
        (50, 18), (39, 16), (69, 15), (28, 25), (82, 24), (19, 33), (93, 32), (55, 28), (44, 30), (76, 29), (60, 2),
    ]

    /// The Crystal Castle's life: the column of light inside the tallest spire, its rainbow bands climbing, a glow
    /// round the door, glints twinkling on the crystal, and beams of coloured light fanning slowly out of the peak.
    static func eterniaCrystalCastleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaCrystalCastleFrame(c, g), q = f.q
        let rainbow = [C(0xFF6A6A), C(0xFFB060), C(0xFFF07A), C(0x7AF0A0), C(0x7AC8FF), C(0xB898FF)]
        // The column: rainbow bands climbing the window, from the door up into the point.
        let band = max(2, 2 * q)
        for y in (f.y + 6 * q)..<(f.y + 38 * q) {
            let u = (y - f.y) / q, hw = u < 16 ? (u - 6) * 3 / 10 : 3
            let i = ((f.y + 38 * q - y) + Int(t * Double(6 * q))) / band
            let w = (hw * 2 + 1) * q
            c.rect(f.x + (60 - hw) * q, y, w, 1, rainbow[i % 6].alpha(0.7))
        }
        // A soft glow round the door, breathing.
        let breath = 0.5 + 0.5 * sin(t * 1.4)
        c.ellipse(f.x + 60 * q + q / 2, f.y + 43 * q, 9 * q, 5 * q, C(0xFFF0C0, 0.10 + 0.08 * breath))
        // Glints: now and then one of the crystal's edges catches the light in a little four-pointed star.
        for (i, p) in eterniaCrystalGlints.enumerated() {
            let v = sin(t * 0.9 + Double(i) * 2.3)
            guard v > 0.7 else { continue }
            let x = f.x + p.x * q + q / 2, y = f.y + p.y * q + q / 2, r = Int(Double(3 * q) * (v - 0.7) / 0.3) + q
            c.rect(x - r, y, 2 * r + 1, max(1, q / 2), C(0xFFFFFF, 0.85)); c.rect(x, y - r, max(1, q / 2), 2 * r + 1, C(0xFFFFFF, 0.85))
        }
        // Beams of light out of the peak, turning slowly.
        let beams = isTall(c) ? 6 : 3, len = Double(isTall(c) ? 44 * q : 10 * q)
        for b in 0..<beams {
            let a = -Double.pi / 2 + sin(t * 0.25 + Double(b) * 1.1) * 0.9
            let col = rainbow[b % 6]
            for i in stride(from: 2 * q, to: Int(len), by: 1) {
                let k = Double(i) / len
                let x = Double(f.peak.x) + cos(a) * Double(i), y = Double(f.peak.y) + sin(a) * Double(i)
                let bw = max(1, Int(Double(q) * (1 + 3 * k)))
                c.rect(Int(x) - bw / 2, Int(y), bw, 1, col.alpha(0.3 * (1 - k)))
            }
        }
        // The peak itself, a bright star.
        let r = Int(Double(3 * q) * (1 + 0.4 * breath))
        c.rect(f.peak.x - r, f.peak.y, 2 * r + 1, max(1, q / 2) + 1, C(0xFFFFFF, 0.9))
        c.rect(f.peak.x, f.peak.y - r, max(1, q / 2) + 1, 2 * r + 1, C(0xFFFFFF, 0.9))
        c.circle(f.peak.x, f.peak.y, q, C(0xFFFFFF))
    }
}
