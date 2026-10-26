import Foundation

// Places on Eternia, a few to a file. Filmation's palette: flat cel colours with dark edges, painted dusk skies of
// purple, orange and teal, earthy greens and sandstone. The crew stands on the ground row `g`; the busy detail is up
// and to the sides.

let eterniaScenes1: [Location: Place] = [
    .eterniaGreyskull: Place(name: "Castle Greyskull", panel: 0x1A1626, still: Scenes.eterniaGreyskull,
                             moving: Scenes.eterniaGreyskullLife),
]

// MARK: - Castle Greyskull

extension Scenes {
    /// Where things stand at Castle Greyskull, shared by the still picture and the moving layer. The castle is drawn
    /// once at one pixel to a unit on a canvas of its own (`eterniaGreyskullCastle`) and blown up `q` times: once in
    /// the window, three times or more on the screen saver, where it's the whole picture. `cliff` is the far cliff's
    /// top (the castle stands on it, across the chasm), `x`/`y` the castle canvas's top left, and `mouth` the gate the
    /// jawbridge comes down from.
    static func eterniaGreyskullFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, cliff: Int, x: Int, y: Int,
                                                                      mouth: (x: Int, w: Int, y: Int)) {
        let q = max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120)))
        let cliff = g - (isTall(c) ? 12 : 9) * q
        let x = c.w * 56 / 100 - 60 * q, y = cliff - 54 * q
        return (q, cliff, x, y, (x + 47 * q, 27 * q, y + 46 * q))
    }

    /// Castle Greyskull at dusk: a Filmation sky banded from deep violet down to orange, the sun going down behind
    /// far purple peaks with long clouds lit from under, and the castle across the chasm. Its keep is a great skull
    /// carved out of grey-green stone, rounded and lit from the sunset side: a heavy brow over two deep sockets, the
    /// nose, the cheekbones, and the mouth for its gate, a row of stone teeth along the top and the jawbridge lowered
    /// out of it across the chasm, teeth along its end. A tall round tower with a cupola on its left, joined by a
    /// walkway; a domed one on its right; turrets and walls further back. The crew stands on the near ledge of grey
    /// rock. On the screen saver the castle stands three times the size, under the first stars and two moons.
    static func eterniaGreyskull(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaGreyskullFrame(c, g), q = f.q, tall = isTall(c)
        let horizon = f.cliff - (tall ? 30 : 12) * s
        c.gradient(0, f.cliff, C(0x2A1C4C), C(0xF0904A), bands: tall ? 12 : 8)
        // The sun going down behind the peaks, left of the castle, in rings of glow.
        let sun = (x: c.w * (tall ? 13 : 24) / 100, y: horizon + 2 * s, r: (tall ? 16 : 9) * s)
        for (k, a) in [(2.6, 0.10), (1.9, 0.16), (1.4, 0.24)] { c.circle(sun.x, sun.y, Int(Double(sun.r) * k), C(0xFFB060, a)) }
        c.circle(sun.x, sun.y, sun.r, C(0xFFD890)); c.circle(sun.x - sun.r / 4, sun.y - sun.r / 4, sun.r * 2 / 3, C(0xFFEAB4))
        if tall {
            // The first stars high up, and Eternia's two moons, shaded, with a crater or two.
            c.stars(0, horizon / 3, density: 60, seed: 11)
            let mx = c.w * 80 / 100, my = horizon / 6, mr = 9 * s
            c.circle(mx, my, mr, C(0xE4D8D0)); c.circle(mx + mr / 3, my + mr / 4, mr * 3 / 4, C(0xC8B8C0))
            c.circle(mx - mr / 3, my - mr / 3, mr / 4, C(0xB8A8B4)); c.circle(mx + mr / 3, my + mr / 3, mr / 5, C(0xA898A8))
            c.circle(mx - 15 * s, my + 9 * s, 4 * s, C(0xC0B0D4)); c.circle(mx - 14 * s, my + 10 * s, 3 * s, C(0xA898C0))
        }
        // Long clouds across the sky, violet on top and lit orange underneath by the sun.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(8, 30, 34), (56, 22, 28), (30, 46, 40), (82, 40, 30), (14, 62, 26), (66, 58, 36), (44, 72, 22)]
            : [(6, 22, 16), (70, 14, 14), (90, 34, 12), (34, 10, 10)]
        for (k, b) in banks.enumerated() {
            eterniaCloudBank(c, c.w * b.x / 100, horizon * b.y / 100 + (tall ? 0 : 2 * s), b.len * s * (tall ? 2 : 1),
                             s * (tall ? 2 : 1), seed: k)
        }
        // The far peaks: ranges of jagged violet, the nearer darker.
        if tall { c.dunes(base: horizon - 16 * s, amp: Double(10 * s), freq: 0.03 / Double(s), phase: 4.1, bottom: f.cliff, C(0xA86A8A), shade: C(0xC07E96)) }
        c.dunes(base: horizon, amp: Double(6 * s), freq: 0.05 / Double(s), phase: 0.7, bottom: f.cliff, C(0x8A5486), shade: C(0xA46A96))
        c.dunes(base: horizon + (tall ? 14 : 6) * s, amp: Double(4 * s), freq: 0.08 / Double(s), phase: 2.3, bottom: f.cliff, C(0x56385E), shade: C(0x6A4670))

        // The far cliff the castle stands on, across the whole back: a ragged lip lit by the sunset, its face in
        // strata down into the chasm.
        let rock = C(0x4A4652), rockD = C(0x322E3A), rockL = C(0x6E6874)
        let face = max(3 * s, 3 * q)
        for x in 0..<c.w {
            let lip = f.cliff - Int(noise(x / max(1, s) + 400) * Double(2 * s))
            c.rect(x, lip, 1, f.cliff + face - lip, rock); c.px(x, lip, rockL)
        }
        for k in 0..<(c.w / (7 * s) + 1) {
            let x = k * 7 * s + Int(noise(k + 20) * Double(4 * s))
            c.rect(x, f.cliff + s, max(1, s / 2), face - 2 * s, rockD)
        }
        c.rect(0, f.cliff + face - max(1, s / 2), c.w, max(1, s / 2), rockD)
        // The chasm under it, black-green, down to the near ledge.
        c.gradient(f.cliff + face, g - s, C(0x1A2620), C(0x080C0A), bands: 4)

        // The castle, blown up to size.
        let castle = PixelCanvas(120, 56)
        eterniaGreyskullCastle(castle)
        for yy in 0..<castle.h {
            for xx in 0..<castle.w where castle.buf[(yy * castle.w + xx) * 4 + 3] > 0 {
                c.rect(f.x + xx * q, f.y + yy * q, q, q, unpremultiplied(castle, (yy * castle.w + xx) * 4))
            }
        }

        // The jawbridge: the skull's lower jaw, lowered out of the mouth across the chasm to the near ledge and
        // widening as it comes, a plank deck between stone rails, a row of teeth standing up along its near end.
        let m = f.mouth, top = f.cliff, bottom = g - s
        let wood = C(0x8A6438), woodD = C(0x5E4224), jaw = C(0x7E9074), jawD = C(0x56664E), tooth = C(0xD4DCC0)
        for y in top..<bottom {
            let k = Double(y - top) / Double(max(1, bottom - top))
            let w = Int(Double(m.w) * (1 + 0.7 * k)), x = m.x + m.w / 2 - w / 2, rail = max(1, q * (2 + Int(k * 2)) / 2)
            c.rect(x, y, w, 1, (y - top) / max(1, q * 2) % 2 == 0 ? wood : woodD)
            c.rect(x, y, rail, 1, jaw); c.rect(x + w - rail, y, rail, 1, jawD)
        }
        let ew = Int(Double(m.w) * 1.7), ex = m.x + m.w / 2 - ew / 2, tw = max(2, ew / 10)
        for i in 0..<5 {
            let tx = ex + ew * (2 * i + 1) / 10 - tw / 2
            c.rect(tx, bottom - 2 * q, tw, 2 * q, tooth); c.rect(tx + tw - max(1, tw / 3), bottom - 2 * q, max(1, tw / 3), 2 * q, C(0xA0AC90))
        }
        // The near ledge: grey rock, plain and mid-dark where the crew stands, a lit lip.
        c.ground(g, C(0x56525A), edge: C(0x6E6A74), speck: C(0x46424A), seed: 41)
    }

    /// A long cloud lying across the sunset: puffs along a flat bank, violet-pink on top, lit orange along the
    /// underside, `len` pixels long and `t` pixels a row.
    static func eterniaCloudBank(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, _ t: Int, seed: Int) {
        let top = C(0x9A6A9E), mid = C(0xC4849E), lit = C(0xF6B47C)
        let bumps = 3 + seed % 3
        for b in 0..<bumps {
            let bx = x + len * (b * 2 + 1) / (bumps * 2), bw = len / bumps + Int(noise(seed * 9 + b) * Double(len / 4))
            let bh = 1 + Int(noise(seed * 9 + b + 50) * 2.5)
            c.rect(bx - bw / 2, y - bh * t, bw, bh * t, top)
            c.rect(bx - bw / 2 + t, y - bh * t, max(1, bw - 2 * t), t, C(0xB07CA8))
        }
        c.rect(x, y, len, t, mid)
        c.rect(x + len / 10, y + t, len * 4 / 5, t, lit)
        c.rect(x + len / 4, y + 2 * t, len / 3, t, lit.alpha(0.7))
    }

    /// Castle Greyskull itself, one pixel to a unit on a 120×56 canvas, its foot on row 54: the turrets and walls at
    /// the back, the left tower and its walkway, the domed right tower, and the skull keep in front of them all.
    static func eterniaGreyskullCastle(_ c: PixelCanvas) {
        // Grey-green stone in six tones, darkest first; the backs a cooler grey in the dusk; the slate roofs violet.
        let tone = [C(0x343E34), C(0x485646), C(0x5E6E58), C(0x76886C), C(0x92A482), C(0xAEBE9A)]
        let back = [C(0x3A4050), C(0x4A5262), C(0x5C6474)], deep = C(0x0E1012), rim = C(0xE8B488)
        let slate = C(0x5A4472), slateD = C(0x3E2E54), slateL = C(0x7E66A0)
        /// A stone pixel: lit by how far left of `cx` it is over `r`, plus `lift`, dithered so the tones blend.
        func stone(_ x: Int, _ y: Int, cx: Double, r: Double, lift: Double = 0) {
            let n = (Double(x) - cx) / r
            let v = 0.56 - 0.42 * n + lift + (noise(x * 7 + y * 131) - 0.5) * 0.28
            c.px(x, y, tone[max(0, min(5, Int(v * 5.4)))])
        }
        /// A round tower: shaded as a cylinder, its stone in courses, from `y0` to the foot.
        func tower(_ x0: Int, _ w: Int, _ y0: Int) {
            let cx = Double(x0) + Double(w) / 2 - 0.5
            for y in y0..<55 { for x in x0..<(x0 + w) { stone(x, y, cx: cx, r: Double(w) / 2) } }
            for y in stride(from: y0 + 3, to: 55, by: 4) {
                c.rect(x0 + 1, y, w - 2, 1, tone[1])
                for x in stride(from: x0 + 2 + (y / 4 % 2) * 2, to: x0 + w - 1, by: 4) { c.px(x, y - 1, tone[1]); c.px(x, y - 2, tone[2]) }
            }
            c.rect(x0 + w - 1, y0, 1, 55 - y0, tone[0])
        }
        /// A narrow window with a pointed top.
        func slit(_ x: Int, _ y: Int, _ h: Int) { c.px(x, y, deep); c.rect(x - 1, y + 1, 3, h, deep); c.px(x - 1, y + h, tone[4]) }

        // At the back: a wall across behind the keep, crenellated, and two turrets standing up behind its crown.
        c.rect(30, 30, 62, 25, back[1])
        for x in stride(from: 30, to: 92, by: 4) { c.rect(x, 28, 2, 2, back[1]) }
        c.rect(30, 30, 62, 1, back[2])
        c.rect(38, 13, 6, 18, back[1]); c.rect(38, 13, 1, 18, back[2]); c.rect(43, 13, 1, 18, back[0])
        for x in [37, 40, 43] { c.rect(x, 11, 2, 2, back[1]) }
        c.rect(77, 9, 6, 22, back[1]); c.rect(77, 9, 1, 22, back[2]); c.rect(82, 9, 1, 22, back[0])
        for i in 0..<6 { c.rect(77 + i / 2, 8 - i, max(1, 6 - i), 1, i < 3 ? slateD : slate) }
        c.px(80, 1, slateL); c.px(80, 0, slateL)

        // The left tower: tall and round, a corbelled crown of merlons, and a pointed slate roof inside it.
        tower(17, 15, 12)
        c.rect(15, 9, 19, 3, tone[3]); c.rect(15, 9, 19, 1, tone[4]); c.rect(15, 9, 2, 3, tone[4]); c.rect(32, 9, 2, 3, tone[1])
        for x in stride(from: 16, to: 33, by: 3) { c.px(x, 11, tone[0]) }
        for x in stride(from: 15, to: 34, by: 4) { c.rect(x, 6, 2, 3, x < 24 ? tone[4] : tone[2]) }
        c.rect(15, 6, 1, 3, rim)
        // A pointed slate roof inside the crown.
        for y in 0...8 {
            let hw = 1 + y * 7 / 8
            for x in (24 - hw)...(25 + hw) { c.px(x, y, x < 24 - hw / 2 ? slateL : x > 25 + hw / 3 ? slateD : slate) }
        }
        for y in [17, 28, 39] { slit(24, y, 4) }
        // The walkway from it to the keep: a stone bridge on an arch.
        c.rect(32, 30, 8, 4, tone[3]); c.rect(32, 30, 8, 1, tone[4]); c.rect(32, 33, 8, 1, tone[1])
        for x in stride(from: 32, to: 40, by: 2) { c.px(x, 29, tone[3]) }
        c.rect(33, 37, 6, 18, back[0]); c.rect(34, 36, 4, 1, back[0])

        // The right tower: squat and round, a ring of corbels, a slate dome with a spike.
        tower(88, 16, 26)
        c.rect(86, 23, 20, 3, tone[3]); c.rect(86, 23, 20, 1, tone[4]); c.rect(104, 23, 2, 3, tone[1])
        for x in stride(from: 87, to: 105, by: 3) { c.px(x, 25, tone[0]) }
        for y in 13...22 {
            let k = Double(22 - y) / 10, half = Int((9 * (1 - k * k).squareRoot()).rounded())
            for x in (96 - half)...(95 + half) { c.px(x, y, x < 94 - half / 3 ? slateL : x > 95 + half / 2 ? slateD : slate) }
        }
        c.rect(95, 9, 1, 4, slateD); c.px(95, 8, slateL)
        slit(96, 31, 5); slit(96, 43, 5)

        // The keep: the skull, rounded and lit from the left, its dome over the brow and its sides straight down to
        // the cheeks and in a little to the jaw.
        func half(_ y: Int) -> Double {
            if y < 27 { let k = Double(27 - y) / 16; return k >= 1 ? 0 : 23 * (1 - k * k).squareRoot() }
            return y < 37 ? 23 : y < 44 ? 24 : 22
        }
        func inside(_ x: Int, _ y: Int) -> Bool { y >= 11 && y < 55 && abs(Double(x) - 59.5) <= half(y) }
        for y in 11..<55 {
            let hw = half(y)
            for x in 35...84 where inside(x, y) {
                stone(x, y, cx: 59.5, r: hw, lift: (y < 27 ? Double(27 - y) / 16 * 0.22 : 0) - (y > 44 ? 0.12 : 0))
                // The sunset catching its left edge and the top of the dome.
                if !inside(x - 1, y) && x < 60 || !inside(x, y - 1) && x < 52 { c.px(x, y, rim) }
            }
        }
        // Cracks across the dome.
        for (x, y) in [(51, 14), (52, 15), (52, 16), (53, 17), (53, 18), (52, 19), (68, 16), (67, 17), (67, 18), (66, 19),
                       (66, 20), (74, 22), (75, 23), (44, 21), (43, 22)] { c.px(x, y, tone[1]) }
        // The sockets: big and dark, frowning, their inner ends pulled down by the brow, a lit rim under each.
        for (cx, dir) in [(48, 1), (71, -1)] {
            for y in 29...39 {
                for x in (cx - 8)...(cx + 8) {
                    let dx = Double(x - cx) / 8, dy = Double(y - 34) / 5
                    guard dx * dx + dy * dy <= 1 else { continue }
                    let brow = 30 + (dir > 0 ? x - (cx - 8) : (cx + 8) - x) / 4   // frowning towards the nose
                    if y < brow { c.px(x, y, tone[1]) } else { c.px(x, y, y < brow + 2 ? C(0x1A2018) : deep) }
                }
            }
            c.rect(cx - 5, 40, 11, 1, tone[4]); c.rect(cx - 3, 41, 7, 1, tone[3])
        }
        // The brow: a heavy ridge jutting out over the sockets, four rows thick, a dark groove above it cutting it off
        // the dome, its top lit by the sunset and its underside casting a shadow into the sockets where it overhangs.
        // It arches over each socket and dips to a point over the nose, the bridge between the sockets left in stone.
        for x in 37...82 {
            let d = Double(min(abs(x - 48), abs(x - 71)))
            let bottom = min(31, 29 + Int((d * d / 40).rounded()))
            let lit = Double(x) < 59.5, overSocket = abs(x - 48) <= 8 || abs(x - 71) <= 8
            func put(_ y: Int, _ col: Px) { if inside(x, y) { c.px(x, y, col) } }
            put(bottom - 5, tone[1])
            put(bottom - 4, lit ? tone[5] : tone[4])
            put(bottom - 3, lit ? tone[5] : tone[4])
            put(bottom - 2, lit ? tone[4] : tone[3])
            put(bottom - 1, lit ? tone[3] : tone[2])
            put(bottom, overSocket ? deep : tone[1])
            if !inside(x - 1, bottom - 4) && x < 60 { put(bottom - 4, rim) }
        }
        // The nose: an upturned heart, dark, lit down its right edge.
        c.pattern(56, 37, [
            "...KK...",
            "..KKKK..",
            ".KKKKKL.",
            "KKKKKKKL",
            "KKK.KKKL",
            ".K...KL.",
        ], ["K": deep, "L": tone[4]])
        // The cheekbones, standing out lit under the sockets, shadow beneath them.
        for cx in [42, 77] {
            c.ellipse(cx, 42, 4, 1, tone[4]); c.px(cx - 3, 41, tone[5])
            c.rect(cx - 4, 44, 9, 1, tone[1])
        }
        // The mouth: the gate, dark inside, its lip in shade above and a row of stone teeth hanging along its top.
        c.rect(47, 45, 27, 1, tone[1])
        c.rect(47, 46, 27, 9, deep); c.rect(46, 47, 1, 8, deep); c.rect(74, 47, 1, 8, deep)
        for i in 0..<7 {
            let tx = 47 + i * 4
            c.pattern(tx, 46, ["TTTs", "TTTs", ".Ts."], ["T": C(0xC8D0B4), "s": C(0x94A086)])
        }
        // Rubble and boulders round its foot, seating it on the cliff.
        for (x, w) in [(12, 6), (31, 4), (44, 3), (75, 4), (85, 3), (104, 7)] {
            c.rect(x, 52, w, 3, C(0x4E4A56)); c.rect(x + 1, 51, w - 2, 1, C(0x5E5A66)); c.px(x, 52, C(0x7A7480))
        }
    }

    /// Greyskull's life: green mist curling up out of the chasm either side of the bridge, the jawbridge's chains
    /// swaying a little, and, on the screen saver, Zoar the falcon circling high over the tower.
    static func eterniaGreyskullLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaGreyskullFrame(c, g), m = f.mouth, q = f.q
        // Mist: soft green wisps drifting up and fading, kept to the chasm.
        for k in 0..<10 {
            let ph = (t * 0.12 + Double(k) * 0.1).truncatingRemainder(dividingBy: 1)
            let x = Int(noise(k * 13 + 5) * Double(c.w)) + Int(sin(t * 0.6 + Double(k)) * Double(3 * s))
            let y = g - 2 * s - Int(ph * Double(g - 2 * s - f.cliff))
            c.ellipse(x, y, 4 * s * max(1, q / 2), max(1, s), C(0x7AC88A, 0.22 * (1 - ph)))
        }
        // The chains, from either side of the mouth's top down to the bridge's near corners, swaying.
        let sway = sin(t * 0.9) * Double(q)
        let link = max(1, q * 2 / 3)
        for side in [0, 1] {
            let x0 = Double(m.x + side * m.w), y0 = Double(m.y + q)
            let x1 = Double(m.x + m.w / 2) + (side == 0 ? -1.0 : 1.0) * Double(m.w) * 0.82, y1 = Double(g - 3 * q)
            let n = max(12, Int(abs(y1 - y0)) / max(1, link))
            for i in 0...n {
                let k = Double(i) / Double(n), sag = (side == 0 ? -1.0 : 1.0) * sin(k * .pi) * Double(q) + sway * sin(k * .pi)
                c.rect(Int(x0 + (x1 - x0) * k + sag), Int(y0 + (y1 - y0) * k), link, link, i % 2 == 0 ? C(0x3A3A42) : C(0x5A5A64))
            }
        }
        guard isTall(c) else { return }
        // Zoar, a little falcon, circling over the left tower.
        let a = t * 0.4, cx = Double(f.x + 24 * q) + cos(a) * Double(30 * s), cy = Double(f.y - 18 * s) + sin(a) * Double(6 * s)
        let flap = Int(t * 5) % 2 == 0
        c.rect(Int(cx), Int(cy), 2 * s, s, C(0x5A4A3A))
        c.rect(Int(cx) - 2 * s, Int(cy) - (flap ? s : 0), 2 * s, s, C(0x6A5A4A)); c.rect(Int(cx) + 2 * s, Int(cy) - (flap ? s : 0), 2 * s, s, C(0x6A5A4A))
    }
}
