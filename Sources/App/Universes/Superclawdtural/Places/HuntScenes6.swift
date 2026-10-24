import Foundation

// Places: the friends' places and the odd ones out, Moondoor, the Burkitsville orchard, Chuck's house and Jody's
// kitchen in Sioux Falls. Each place is a `Place` in the dictionary below (its name, the tint of the window's card area
// under it, its still picture and what moves there) and its drawing in an extension of `Scenes`, with a frame function
// the still picture and the moving layer share so they line up. Check them with `build/preview place out.png <key>`, at
// window size and at screen-saver size.
//
// Four places a little off the universe's road: Moondoor is a sunny LARP field (its grass kept mid-green, never bright,
// so white outlines read), the orchard is rust and amber under a sunset, Chuck's study is a dim lamplit den of dark wood
// and sage-grey wallpaper at night, and Jody's kitchen is a warm afternoon of butter-yellow walls, sage cupboards and
// denim-blue tiles. The floor and the band just above it stay plain and mid-to-dark so the crew's outlines and names
// read; the busy detail goes higher up and at the sides; props keep their size in `Scenes.unit(g)` steps.

let huntScenes6: [Location: Place] = [
    .huntMoondoor: Place(name: "Moondoor", panel: 0x142016, still: Scenes.huntMoondoor, moving: Scenes.huntMoondoorLife),
    .huntOrchard: Place(name: "The Orchard", panel: 0x1E140E, still: Scenes.huntOrchard, moving: Scenes.huntOrchardLife),
    .huntChucks: Place(name: "Chuck's House", panel: 0x16130E, still: Scenes.huntChucks, moving: Scenes.huntChucksLife),
    .huntSiouxFalls: Place(name: "Sioux Falls", panel: 0x1E1912, still: Scenes.huntSiouxFalls, moving: Scenes.huntSiouxFallsLife),
]

// MARK: - Shared bits

/// A thin pole or stick from one point to another, `r` pixels round.
private func huntP6Stick(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, _ r: Double) {
    c.glowLine(Double(x0), Double(y0), Double(x1), Double(y1), core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// A flag flying from a pole's top at (`x`, `y`), `len` long and `h` deep, waving more towards its tip; a pennant
/// (`tail`) narrows to a point, a banner keeps its depth. `stripe` runs along its middle.
private func huntP6Flag(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, _ h: Int, _ col: Px, _ stripe: Px,
                        tail: Bool, t: Double, phase: Double, s: Int) {
    let shade = lerp(col, C(0x101010), 0.3)
    for k in 0..<len {
        let f = Double(k) / Double(len)
        let wave = sin(t * 4.2 + phase - Double(k) * 0.45 / Double(s)) * f * Double(2 * s)
        let depth = tail ? max(1, Int(Double(h) * (1 - f * 0.85))) : h
        let top = y + Int(wave.rounded()) + (h - depth) / 2
        let lit = cos(t * 4.2 + phase - Double(k) * 0.45 / Double(s)) > 0
        c.rect(x + k, top, 1, depth, lit ? col : shade)
        if depth >= 3 * s { c.rect(x + k, top + depth / 2 - s / 2, 1, max(1, s), stripe) }
    }
}

// MARK: - Moondoor

/// A string of bunting sagging from one point to another: a dark cord, and little triangular flags hanging off it in
/// turn red, cream, blue and gold.
private func huntP6Bunting(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, sag: Int, _ s: Int) {
    let tones: [UInt32] = [0xC03A2E, 0xEEE4C8, 0x2E5A9A, 0xE0B040, 0x6A3A8A]
    let n = max(1, abs(x1 - x0))
    func y(_ x: Int) -> Int {
        let k = Double(x - x0) / Double(n)
        return y0 + Int(Double(y1 - y0) * k + Double(sag) * 4 * k * (1 - k))
    }
    for x in min(x0, x1)..<max(x0, x1) { c.rect(x, y(x), 1, max(1, s / 2), C(0x3A2E24)) }
    for (k, fx) in stride(from: min(x0, x1) + 2 * s, to: max(x0, x1) - 2 * s, by: 5 * s).enumerated() {
        let col = C(tones[k % tones.count]), top = y(fx) + max(1, s / 2)
        for r in 0..<(3 * s) {
            let half = max(0, (3 * s - r) * 3 / (2 * 3))
            c.rect(fx - half, top + r, 2 * half + 1, 1, col)
        }
    }
}

/// A small far-off tent in the haze on row `base`: a striped body, a cone roof and a pennant pole, half the size of
/// the near pavilions.
private func huntP6FarTent(_ c: PixelCanvas, _ x: Int, _ base: Int, _ s: Int, kind: Int) {
    let tones: [UInt32] = [0x9A6A70, 0x6A84A8, 0x8A78A0, 0xB09070]
    let col = C(tones[kind % tones.count]), cream = C(0xD8DCD8), shade = lerp(col, C(0x6A7A90), 0.4)
    for (k, sx) in stride(from: x - 6 * s, to: x + 6 * s, by: 2 * s).enumerated() {
        c.rect(sx, base - 6 * s, 2 * s, 6 * s, k % 2 == 0 ? col : cream)
    }
    c.rect(x + 3 * s, base - 6 * s, 3 * s, 6 * s, shade.alpha(0.6))
    c.rect(x - s, base - 4 * s, 2 * s, 4 * s, C(0x5A6070))
    for k in 0..<6 {
        let w = 7 * s * (6 - k) / 6
        c.rect(x - w, base - 7 * s - k * s, 2 * w, s, k % 2 == 0 ? col : shade)
    }
    c.rect(x, base - 16 * s, max(1, s), 4 * s, C(0x6A6A70))
}

/// A striped LARP pavilion standing on row `base`, its middle on `x`: a round tent of canvas in alternating colour and
/// cream under a cone roof with a scalloped valance, the door flap tied back on a dark inside, guy ropes pegged out.
private func huntP6Tent(_ c: PixelCanvas, _ x: Int, _ base: Int, _ s: Int, kind: Int, haze: Double = 0) {
    let tones: [UInt32] = [0xB03A2E, 0x2E5A9A, 0x6A3A8A]
    let far = C(0x9AC0D8)
    func h(_ p: Px) -> Px { lerp(p, far, haze) }
    let col = h(C(tones[kind % tones.count])), colD = h(lerp(C(tones[kind % tones.count]), C(0x180C10), 0.35))
    let cream = h(C(0xEAE0C4)), creamD = h(C(0xBEB294)), dark = h(C(0x2A1E1A))
    let half = 15 * s, wall = 13 * s, roofH = 12 * s
    // The walls: vertical stripes, the far right side in shade.
    for (k, sx) in stride(from: x - half, to: x + half, by: 3 * s).enumerated() {
        let right = sx > x + half / 3
        let base0 = k % 2 == 0 ? col : cream, baseD = k % 2 == 0 ? colD : creamD
        c.rect(sx, base - wall, min(3 * s, x + half - sx), wall, right ? baseD : base0)
    }
    c.rect(x - half, base - wall, s, wall, h(C(0xF6F0DC)))
    // The door: tied-back flaps on a dark inside.
    c.rect(x - 4 * s, base - 9 * s, 8 * s, 9 * s, dark)
    for k in 0..<5 {
        c.rect(x - 4 * s, base - 9 * s + k * s, max(1, (5 - k) * s / 2), s, cream)
        c.rect(x + 4 * s - max(1, (5 - k) * s / 2), base - 9 * s + k * s, max(1, (5 - k) * s / 2), s, creamD)
    }
    // The cone roof: stripes running up to the peak, lit on its left.
    for k in 0..<roofH {
        let w = (half + s) * (roofH - k) / roofH
        let y = base - wall - k - 1
        c.rect(x - w, y, 2 * w, 1, k % (2 * s) < s ? col : colD)
        c.rect(x - w, y, max(1, s), 1, h(C(0xF0E2C8)))
        c.rect(x + w / 3, y, max(1, w * 2 / 3), 1, colD)
    }
    // The valance: a row of scallops round the eave.
    for sx in stride(from: x - half - s, to: x + half + s, by: 3 * s) {
        c.rect(sx, base - wall - s, 3 * s, 2 * s, cream)
        c.rect(sx + s, base - wall + s, s, s, cream)
    }
    c.rect(x - half - s, base - wall - s, 2 * half + 2 * s, max(1, s / 2), h(C(0xC8A04A)))
    // The centre pole above the peak, a gold knob on top, and the guy ropes to their pegs.
    c.rect(x - s / 2, base - wall - roofH - 5 * s, max(1, s), 5 * s, h(C(0x5A4230)))
    c.rect(x - s, base - wall - roofH - 6 * s, 2 * s, s, h(C(0xD8B048)))
    for k in [-1, 1] {
        huntP6Stick(c, x + k * half, base - wall, x + k * (half + 6 * s), base - s, h(C(0x8A7A5A)), Double(s) * 0.35)
        c.rect(x + k * (half + 6 * s) - s / 2, base - 2 * s, max(1, s), 2 * s, h(C(0x4A3828)))
    }
}

extension Scenes {
    /// Where things stand at Moondoor, shared by the still picture and the moving layer: the far edge of the field,
    /// the cardboard castle (its left edge and the tops of its two towers' flagpoles), the big pavilions (each one's
    /// middle and colour), the banner poles (each one's foot and which banner), and the far tents.
    static func huntMoondoorFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, castle: Int, tents: [(x: Int, kind: Int)],
                                                                 banners: [(x: Int, kind: Int)], poleTop: Int) {
        let s = unit(g)
        let tents = [(x: c.w * 74 / 100, kind: 0), (x: c.w * 91 / 100, kind: 1)]
        let banners = [(x: c.w * 33 / 100, kind: 2), (x: c.w * 57 / 100, kind: 0)]
        return (g - 22 * s, c.w * 2 / 100 + 2 * s, tents, banners, g - 54 * s)
    }

    /// Moondoor, the LARP kingdom in a sunny field: a bright blue sky with fair-weather clouds, a line of summer trees
    /// along the far edge, Queen Charlie's cardboard castle on the left (painted grey stone, a corner of brown
    /// cardboard showing, duct tape on a seam, a plank propping it up from behind), hay bales, banners on tall poles,
    /// far tents in the haze, and striped pavilions on the right with a rack of foam swords between them. The grass the
    /// crew stands on stays mid-green. On the screen saver big oaks frame the field, the clouds pile up and the sun
    /// blazes high on the left.
    static func huntMoondoor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntMoondoorFrame(c, g), tall = isTall(c)
        // The sky: deep summer blue up high, paler towards the trees.
        c.gradient(0, f.horizon, C(0x4A8CD4), C(0xAAD4EE), bands: tall ? 9 : 5)
        // The sun, high on the left, its glow soft round it.
        let sun = (x: c.w * 13 / 100, y: tall ? g * 14 / 100 : 9 * s)
        for r in stride(from: 22 * s, to: 6 * s, by: -4 * s) { c.circle(sun.x, sun.y, r, C(0xFFF6C8, 0.08)) }
        c.circle(sun.x, sun.y, 6 * s, C(0xFFF4C0)); c.circle(sun.x - s, sun.y - s, 4 * s, C(0xFFFCE8))
        // Fair-weather clouds, more and bigger on the screen saver.
        let clouds: [(Int, Int, Int)] = tall
            ? [(28, 8, 14), (60, 16, 11), (84, 6, 13), (44, 30, 9), (18, 42, 10), (72, 40, 12), (52, 54, 7), (34, 62, 6),
               (88, 58, 7), (10, 22, 8)]
            : [(31, 8, 4), (49, 13, 3), (68, 6, 4), (88, 12, 3)]
        for (k, (xp, yp, r)) in clouds.enumerated() {
            let y = tall ? g * yp / 100 : yp * s
            cloud(c, c.w * xp / 100, y, r * s, seed: 60 + k, top: C(0xFAFCFF), base: C(0xD4E4F0))
        }
        // On the screen saver: big oaks standing in from either side of the field, whole crowns over the corners.
        if tall {
            // Far blue-green hills beyond the trees, and a second line of woods on them.
            c.dunes(base: f.horizon - 22 * s, amp: Double(7 * s), freq: 0.012 / Double(s), phase: 0.8, bottom: f.horizon, C(0x7AA4B0))
            c.dunes(base: f.horizon - 12 * s, amp: Double(4 * s), freq: 0.03 / Double(s), phase: 2.2, bottom: f.horizon, C(0x5A8A70))
            // A few birds high up, little dark ticks.
            for k in 0..<7 {
                let bx = c.w * (30 + k * 9) / 100 + Int(noise(k + 980) * 30) * s, by = g * 18 / 100 + Int(noise(k + 990) * 40) * s
                c.rect(bx - 2 * s, by, 2 * s, max(1, s), C(0x3A4A5E)); c.rect(bx + s, by, 2 * s, max(1, s), C(0x3A4A5E))
                c.rect(bx, by + max(1, s), max(1, s), max(1, s), C(0x3A4A5E))
            }
            for (k, xp) in [14, 86].enumerated() {   // far enough in that the frame cuts neither crown
                huntMoondoorOak(c, c.w * xp / 100, f.horizon + 2 * s, f.horizon - 90 * s, s, seed: 30 + k)
            }
        }
        // The far edge of the field: a line of summer trees, round crowns lit on the left, a darker underside.
        for x in stride(from: -4 * s, to: c.w + 8 * s, by: 7 * s) {
            let i = x / max(1, s)
            let r = (5 + Int(noise(i + 900) * 3)) * s, y = f.horizon - 3 * s - Int(noise(i + 901) * 4) * s
            c.ellipse(x, y, r, r * 4 / 5, C(0x2E6230))
            c.ellipse(x - r / 3, y - r / 3, r / 2, r / 3, C(0x4A8A40))
        }
        c.rect(0, f.horizon - 3 * s, c.w, 3 * s, C(0x2A5428))
        // The field: sunlit grass, a little deeper near the crew, mown stripes running across.
        c.gradient(f.horizon, g, C(0x6E9C46), C(0x547E36), bands: 4)
        for y in stride(from: f.horizon + 3 * s, to: g - 4 * s, by: 5 * s) { c.rect(0, y, c.w, max(1, s / 2), C(0x648F40)) }
        // Far tents in the haze between the banners, a little encampment.
        for (k, xp) in [39, 43, 47, 51].enumerated() {
            huntP6FarTent(c, c.w * xp / 100 + (k % 2) * 2 * s, f.horizon + 3 * s + (k % 2) * s, s, kind: k)
        }
        // A worn dirt path from the castle gate out across the field.
        let gate = f.castle + 34 * s
        for y in (g - 9 * s)..<g {
            let k = y - (g - 9 * s)
            c.rect(gate - 6 * s - k / 2, y, 12 * s + k, 1, C(0x8A7048))
        }
        huntMoondoorCastle(c, g)
        // Hay bales beside the castle, two side by side and one on top, straw strokes and a twine band round each.
        let hb = f.castle + 74 * s
        for (dx, dy) in [(0, 0), (12, 0), (6, -6)] {
            let bx = hb + dx * s, by = g - 6 * s + dy * s
            c.rect(bx, by, 11 * s, 6 * s, C(0xC8A44E)); c.rect(bx, by, 11 * s, s, C(0xE2C470))
            c.rect(bx + 10 * s, by, s, 6 * s, C(0x9A7A36)); c.rect(bx, by + 5 * s, 11 * s, s, C(0x9A7A36))
            for k in 0..<4 { c.rect(bx + (1 + k * 3) * s, by + 2 * s, 2 * s, max(1, s / 2), C(0xA88A3E)) }
            c.rect(bx + 3 * s, by, max(1, s / 2), 6 * s, C(0x6A5030)); c.rect(bx + 8 * s, by, max(1, s / 2), 6 * s, C(0x6A5030))
        }
        // An archery butt beyond the bales: a straw boss on a wooden easel, its painted rings, two arrows in it.
        let ax = f.castle + 104 * s, ay = g - 17 * s
        huntP6Stick(c, ax - 6 * s, g, ax - 2 * s, ay - 6 * s, C(0x6A4A2E), Double(s) * 0.7)
        huntP6Stick(c, ax + 6 * s, g, ax + 2 * s, ay - 6 * s, C(0x5A3E26), Double(s) * 0.7)
        huntP6Stick(c, ax + 2 * s, g - s, ax + 4 * s, ay, C(0x4A3420), Double(s) * 0.6)
        c.circle(ax, ay, 7 * s, C(0xC8A44E)); c.circle(ax, ay, 6 * s, C(0xF2EEE2)); c.circle(ax, ay, 5 * s, C(0x2A2A2E))
        c.circle(ax, ay, 4 * s, C(0x3A7AC0)); c.circle(ax, ay, 3 * s, C(0xD03A2E)); c.circle(ax, ay, s + s / 2, C(0xF0C840))
        c.rect(ax - 7 * s, ay - s, s, 2 * s, C(0xE2C470))
        for (u, v) in [(-2, -2), (3, 1)] {
            huntP6Stick(c, ax + u * s, ay + v * s, ax + (u - 6) * s, ay + (v - 2) * s, C(0x8A6A44), Double(s) * 0.45)
            c.rect(ax + (u - 7) * s, ay + (v - 3) * s, 2 * s, 2 * s, C(0xE8E4D8))
        }
        // Bunting strung high from the castle's tower to the banner poles and on to the near pavilion.
        let pts = [(f.castle + 61 * s, g - 50 * s), (f.banners[0].x, f.poleTop + 2 * s), (f.banners[1].x, f.poleTop + 2 * s),
                   (f.tents[0].x, g - 38 * s)]
        for k in 1..<pts.count {
            huntP6Bunting(c, pts[k - 1].0, pts[k - 1].1, pts[k].0, pts[k].1, sag: 6 * s, s)
        }
        // The banner poles: tall ash staves with a gilt knob, a crossbar the banner hangs from (it flies in the moving
        // layer), and a little shadow at the foot.
        for b in f.banners {
            c.ellipse(b.x + 2 * s, g, 5 * s, s, C(0x3A5A28, 0.6))
            c.rect(b.x, f.poleTop, 2 * s, g - f.poleTop, C(0x7A5A3A)); c.rect(b.x, f.poleTop, max(1, s / 2), g - f.poleTop, C(0xA27E52))
            c.rect(b.x - s, f.poleTop - 3 * s, 4 * s, 3 * s, C(0xD8B048)); c.rect(b.x - s, f.poleTop - 3 * s, 2 * s, s, C(0xF4DA80))
            c.rect(b.x - 5 * s, f.poleTop + 2 * s, 12 * s, s, C(0x5A4230))
        }
        // The striped pavilions on the right, and the foam-sword rack between them.
        for tn in f.tents { huntP6Tent(c, tn.x, g - s, s, kind: tn.kind) }
        let rx = (f.tents[0].x + f.tents[1].x) / 2 - 2 * s
        huntP6Stick(c, rx - 6 * s, g, rx, g - 14 * s, C(0x6A4A2E), Double(s) * 0.7)
        huntP6Stick(c, rx + 6 * s, g, rx, g - 14 * s, C(0x5A3E26), Double(s) * 0.7)
        c.rect(rx - 6 * s, g - 9 * s, 13 * s, s, C(0x7A5A3A))
        let hilts: [UInt32] = [0x2E5A9A, 0x8A2A2A, 0x3A7A3A, 0xD8A030]
        for k in 0..<4 {
            let sx = rx - 5 * s + k * 3 * s
            c.rect(sx, g - 19 * s, 2 * s, 10 * s, C(0xB8BCC4)); c.rect(sx, g - 19 * s, max(1, s / 2), 10 * s, C(0xDDE0E6))
            c.rect(sx - s / 2, g - 9 * s, 3 * s, s, C(hilts[k])); c.rect(sx, g - 8 * s, 2 * s, 3 * s, C(hilts[k]))
        }
        // A cooler of drinks by the near pavilion, blue with a white lid.
        let cx = f.tents[0].x - 26 * s
        c.rect(cx, g - 6 * s, 10 * s, 6 * s, C(0x2E6AB0)); c.rect(cx, g - 7 * s, 10 * s, 2 * s, C(0xEEF0F2))
        c.rect(cx + 9 * s, g - 6 * s, s, 6 * s, C(0x1E4A80)); c.rect(cx + 3 * s, g - 8 * s, 4 * s, s, C(0x9AA0A8))
        // The grass the crew stands on: mid-green, trampled, a few clover flowers.
        c.ground(g, C(0x4A6E32), edge: C(0x5E8640), speck: C(0x42642C), seed: 113)
        for i in 0..<(c.w / (16 * s)) {
            let x = Int(noise(i * 3 + 950) * Double(c.w)), y = g + 2 * s + Int(noise(i * 3 + 951) * Double(max(1, c.h - g - 3 * s)))
            c.rect(x, y, max(1, s), max(1, s), C(0xD8D4C0))
        }
    }

    /// One summer oak on the screen saver: a stout trunk from the field's edge forking into big limbs, and a broad
    /// crown of round clumps centred on row `cy`, dark underneath and lit on the upper left.
    private static func huntMoondoorOak(_ c: PixelCanvas, _ x: Int, _ base: Int, _ cy: Int, _ s: Int, seed: Int) {
        let bark = C(0x4A3A2A), barkL = C(0x6A5640), barkD = C(0x2E241A)
        let trunkTop = cy + 20 * s
        c.rect(x - 7 * s, trunkTop, 14 * s, base - trunkTop, bark); c.rect(x - 7 * s, trunkTop, 3 * s, base - trunkTop, barkL)
        c.rect(x + 4 * s, trunkTop, 3 * s, base - trunkTop, barkD)
        for k in [-1, 1] {
            huntP6Stick(c, x, trunkTop + 10 * s, x + k * 30 * s, cy - 4 * s, bark, Double(s) * 2.6)
            huntP6Stick(c, x, trunkTop + 4 * s, x + k * 12 * s, cy - 24 * s, bark, Double(s) * 2)
        }
        let tones = [C(0x234E24), C(0x2E6230), C(0x3E7A38), C(0x5A9A48)]
        for (layer, tone) in tones.enumerated() {
            let n = 16 - layer * 3
            for k in 0..<n {
                let i = seed * 200 + layer * 40 + k
                let a = noise(i) * 2 * .pi, d = noise(i + 20).squareRoot()
                let dx = Int(cos(a) * d * 44 - Double(layer) * 5) * s
                let dy = Int(sin(a) * d * 24 - Double(layer) * 4) * s
                let r = (15 - layer * 3 + Int(noise(i + 30) * 6)) * s
                c.ellipse(x + dx, cy + dy, r, r * 4 / 5, tone)
            }
        }
    }

    /// The cardboard castle: a wall with crenellations between two square towers, painted grey stone with the
    /// courses drawn on in marker, arrow slits, an arched gate with a portcullis drawn on it, a corner of brown
    /// corrugated cardboard showing where the paint ran out, a strip of duct tape over a seam, and a plank propping the
    /// right tower up from behind.
    private static func huntMoondoorCastle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x0 = huntMoondoorFrame(c, g).castle
        let paint = C(0x9A9890), paintL = C(0xB8B6AE), paintD = C(0x74726C), marker = C(0x5E5C58)
        let card = C(0xB88E58), cardD = C(0x8E6A3E)
        let wallTop = g - 24 * s, towerTop = g - 36 * s, towerW = 14 * s, width = 68 * s
        // The prop behind the right tower: a bare plank leaning in from the field.
        huntP6Stick(c, x0 + width + 8 * s, g, x0 + width - 4 * s, towerTop + 8 * s, C(0xA88458), Double(s) * 1.1)
        // The curtain wall and its merlons.
        c.rect(x0 + towerW, wallTop, width - 2 * towerW, g - wallTop, paint)
        for mx in stride(from: x0 + towerW, to: x0 + width - towerW - s, by: 6 * s) {
            c.rect(mx, wallTop - 3 * s, 3 * s, 3 * s, paint); c.rect(mx, wallTop - 3 * s, 3 * s, s, paintL)
        }
        c.rect(x0 + towerW, wallTop, width - 2 * towerW, s, paintL)
        // The two towers, each lit on its left, with its own merlons.
        for tx in [x0, x0 + width - towerW] {
            c.rect(tx, towerTop, towerW, g - towerTop, paint)
            c.rect(tx, towerTop, 2 * s, g - towerTop, paintL); c.rect(tx + towerW - 2 * s, towerTop, 2 * s, g - towerTop, paintD)
            for k in 0..<3 {
                let mx = tx + k * 5 * s
                c.rect(mx, towerTop - 3 * s, 4 * s, 3 * s, k == 2 ? paintD : paint); c.rect(mx, towerTop - 3 * s, 4 * s, s, paintL)
            }
            c.rect(tx + 6 * s, towerTop + 8 * s, 2 * s, 6 * s, C(0x2A2826))   // an arrow slit
            c.rect(tx + 5 * s, towerTop + 10 * s, 4 * s, s, C(0x2A2826))
            c.rect(tx, towerTop + 18 * s, towerW, max(1, s / 2), marker)
        }
        // The stone courses, drawn on in marker, staggered like brick.
        for (row, y) in stride(from: wallTop + 4 * s, to: g - s, by: 4 * s).enumerated() {
            c.rect(x0 + towerW, y, width - 2 * towerW, max(1, s / 2), marker)
            for x in stride(from: x0 + towerW + (row % 2) * 4 * s + 2 * s, to: x0 + width - towerW, by: 8 * s) {
                c.rect(x, y - 4 * s + max(1, s / 2), max(1, s / 2), 4 * s - max(1, s / 2), marker)
            }
        }
        // The gate: a dark arch with the portcullis drawn on it in thick marker.
        let gx = x0 + 34 * s
        c.rect(gx - 6 * s, g - 12 * s, 12 * s, 12 * s, C(0x24221E)); c.circle(gx, g - 12 * s, 6 * s, C(0x24221E))
        for x in stride(from: gx - 4 * s, through: gx + 4 * s, by: 3 * s) { c.rect(x, g - 16 * s, max(1, s), 14 * s, C(0x3E3C38)) }
        for y in stride(from: g - 13 * s, to: g - 2 * s, by: 3 * s) { c.rect(gx - 5 * s, y, 10 * s, max(1, s), C(0x3E3C38)) }
        c.rect(gx - 7 * s, g - 18 * s, 14 * s, s, paintD)
        // Where the paint ran out: a corner of brown corrugated cardboard on the left tower's top, its flutes showing.
        c.rect(x0 + 2 * s, towerTop, 7 * s, 6 * s, card)
        for x in stride(from: x0 + 3 * s, to: x0 + 9 * s, by: 2 * s) { c.rect(x, towerTop, max(1, s / 2), 6 * s, cardD) }
        c.rect(x0 + 2 * s, towerTop + 6 * s, 4 * s, s, card)
        // Duct tape over the seam where the wall meets the right tower, silver with a crinkle.
        let tx = x0 + width - towerW - 2 * s
        c.rect(tx, wallTop + 2 * s, 4 * s, 14 * s, C(0xB4B8BE)); c.rect(tx, wallTop + 2 * s, s, 14 * s, C(0xD4D8DE))
        c.rect(tx + s, wallTop + 8 * s, 3 * s, max(1, s / 2), C(0x8A8E94))
        // A shield painted on the wall between gate and tower: Moondoor's purple and gold.
        let sx = x0 + 22 * s, sy = wallTop + 4 * s
        c.rect(sx - 3 * s, sy, 6 * s, 5 * s, C(0x5A2E7A)); c.rect(sx - 2 * s, sy + 5 * s, 4 * s, s, C(0x5A2E7A)); c.rect(sx - s, sy + 6 * s, 2 * s, s, C(0x5A2E7A))
        c.rect(sx - s, sy + s, 2 * s, 3 * s, C(0xE0B848)); c.rect(sx - 2 * s, sy + 2 * s, 4 * s, s, C(0xE0B848))
        // Its shadow on the grass.
        c.rect(x0 + 2 * s, g - s, width, s, C(0x3A5A28, 0.5))
    }

    /// Moondoor's life: every flag flapping in the summer breeze, the banners on their crossbars, the pennants on the
    /// pavilions and the castle's towers.
    static func huntMoondoorLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntMoondoorFrame(c, g)
        let towerTop = g - 36 * s
        // The castle's pennants on short staves above each tower.
        for (k, tx) in [f.castle + 7 * s, f.castle + 61 * s].enumerated() {
            c.rect(tx, towerTop - 13 * s, max(1, s), 10 * s, C(0x4A3828))
            huntP6Flag(c, tx + s, towerTop - 13 * s, 10 * s, 5 * s, C(0x6A3A9A), C(0xE8C050), tail: true, t: t, phase: Double(k) * 1.3, s: s)
        }
        // The banners on their poles: long gonfalons hanging from the crossbar, their tails swinging.
        let colours: [(UInt32, UInt32)] = [(0x6A3A9A, 0xE8C050), (0xB03A2E, 0xF0E4C8), (0x2E5A9A, 0xE8C050)]
        for (k, b) in f.banners.enumerated() {
            let (col, mark) = colours[b.kind % colours.count]
            let top = f.poleTop + 3 * s, w = 10 * s, len = 15 * s
            for y in 0..<len {
                let sway = Int((sin(t * 2.6 + Double(k) * 1.7 - Double(y) * 0.2 / Double(s)) * Double(y) / Double(len) * Double(2 * s)).rounded())
                let notch = y > len - 4 * s ? (y - (len - 4 * s)) : 0   // the swallowtail
                let x = b.x - 4 * s + sway
                c.rect(x, top + y, w / 2 - notch, 1, C(col))
                c.rect(x + w / 2 + notch, top + y, w / 2 - notch, 1, lerp(C(col), C(0x100810), 0.25))
                c.rect(x, top + y, max(1, s / 2), 1, lerp(C(col), C(0xFFFFFF), 0.3))
                // A gold crown on the purple and blue, a cream cross on the red, on the banner's middle.
                let v = y / max(1, s)
                if b.kind == 1 {
                    if v >= 3 && v < 10 { c.rect(x + w / 2 - s, top + y, 2 * s, 1, C(mark)) }
                    if v == 5 || v == 6 { c.rect(x + w / 2 - 3 * s, top + y, 6 * s, 1, C(mark)) }
                } else {
                    let mid = x + w / 2 - s / 2
                    if v == 3 || v == 4 { for u in [-3, 0, 3] { c.rect(mid + u * s, top + y, max(1, s), 1, C(mark)) } }
                    if v == 5 || v == 6 { c.rect(mid - 3 * s, top + y, 7 * s, 1, C(mark)) }
                    if v == 7 { c.rect(mid - 3 * s, top + y, 7 * s, 1, lerp(C(mark), C(0x6A4A10), 0.45)) }
                }
            }
        }
        // The pavilions' pennants on their centre poles.
        for (k, tn) in f.tents.enumerated() {
            let py = g - s - 13 * s - 12 * s - 6 * s
            c.rect(tn.x - s / 2, py - 8 * s, max(1, s), 8 * s, C(0x5A4230))
            huntP6Flag(c, tn.x + s / 2, py - 8 * s, 11 * s, 4 * s, k == 0 ? C(0xE8C050) : C(0xF0E8D4), k == 0 ? C(0xB03A2E) : C(0x2E5A9A),
                       tail: true, t: t, phase: 2.1 + Double(k), s: s)
        }
    }
}

// MARK: - The Orchard

/// One apple tree standing on row `base` with its middle on `x`, `r` its crown's half-width: a gnarled trunk forking
/// into the crown, round clumps of leaves dark against the sunset and rimmed with its glow on the left, red apples
/// dotted through. `haze` sinks the far rows into the dusk.
private func huntP6AppleTree(_ c: PixelCanvas, _ x: Int, _ base: Int, _ r: Int, _ s: Int, seed: Int, haze: Double) {
    let dusk = C(0x5A3A40)
    func h(_ p: Px) -> Px { lerp(p, dusk, haze) }
    let bark = h(C(0x3A2A20)), barkL = h(C(0x6A4A30)), leaf = h(C(0x2A3A20)), leafL = h(C(0x4A5A28))
    let crown = base - r * 2
    c.rect(x - 2 * s, crown + r / 2, 4 * s, base - crown - r / 2, bark); c.rect(x - 2 * s, crown + r / 2, max(1, s), base - crown - r / 2, barkL)
    huntP6Stick(c, x, crown + r, x - r / 2, crown + r / 3, bark, Double(s) * 1.2)
    huntP6Stick(c, x, crown + r, x + r / 2, crown + r / 4, bark, Double(s) * 1.2)
    for k in 0..<7 {
        let dx = Int((noise(seed * 31 + k) - 0.5) * Double(r * 2)), dy = Int((noise(seed * 31 + k + 9) - 0.5) * Double(r))
        let rr = r / 2 + Int(noise(seed * 31 + k + 17) * Double(r / 3))
        c.ellipse(x + dx, crown + dy, rr, rr * 3 / 4, leaf)
        c.ellipse(x + dx - rr / 4, crown + dy - rr / 4, rr / 2, rr / 3, leafL)
    }
    if haze < 0.5 {
        for k in 0..<(r / (2 * s) + 2) {
            let ax = x - r + Int(noise(seed * 31 + k + 40) * Double(2 * r)), ay = crown - r / 2 + Int(noise(seed * 31 + k + 60) * Double(r))
            c.rect(ax, ay, 2 * s, 2 * s, C(0xA82A20)); c.rect(ax, ay, s, s, C(0xE0603A))
        }
    }
}

/// The scarecrow on its crossbar, leaning `lean` pixels at the head (the wind sways it): a burlap sack head with
/// button eyes and a stitched grin under a battered straw hat, a patched brown coat stretched along the bar, straw
/// poking out at the cuffs, the collar and the hem, and two sacking trouser legs dangling with straw for feet. It's
/// drawn on a grid half as big again as the crew's pixels, so it stands a little taller than they do.
private func huntP6Scarecrow(_ c: PixelCanvas, _ x: Int, _ bar: Int, _ s: Int, lean: Double) {
    /// `n` grid steps in pixels, half as big again, rounded down so neighbouring parts still meet.
    func q(_ n: Int) -> Int { Int((Double(n * 3 * s) / 2).rounded(.down)) }
    func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) {
        let shift = Int((lean * Double(-v + 6) / 16.0).rounded())
        c.rect(x + q(u) + shift, bar + q(v), q(u + w) - q(u), q(v + h) - q(v), col)
    }
    let sack = C(0xB89462), sackL = C(0xD4B07A), sackD = C(0x8A6A42), straw = C(0xE0C060), strawD = C(0xB0903A)
    let coat = C(0x5A4232), coatL = C(0x7A5A40), coatD = C(0x3A2A20), patch = C(0x7A3A2A), patch2 = C(0x4A5A6A)
    // The trouser legs, dangling, straw for feet.
    r(-4, 9, 3, 7, sackD); r(1, 9, 3, 7, sack); r(1, 9, 1, 7, sackL)
    r(-4, 16, 3, 1, straw); r(-5, 17, 1, 1, strawD); r(-3, 17, 1, 1, straw); r(1, 16, 3, 1, straw); r(3, 17, 1, 1, strawD)
    // The coat: body and the arms out along the bar, a patch on each, straw at the cuffs and the hem.
    r(-6, -1, 12, 11, coat); r(-6, -1, 2, 11, coatL); r(4, -1, 2, 11, coatD)
    r(-15, -1, 9, 4, coat); r(6, -1, 9, 4, coat); r(-15, -1, 9, 1, coatL); r(6, -1, 9, 1, coatL)
    r(-15, 2, 9, 1, coatD); r(6, 2, 9, 1, coatD)
    r(-3, 3, 3, 3, patch); r(-3, 3, 3, 1, lerp(patch, C(0xFFFFFF), 0.2)); r(9, 0, 3, 2, patch2)
    r(-1, 0, 1, 9, coatD)   // the coat's front edge
    r(-6, 7, 12, 1, C(0x2A1E16)); r(-1, 7, 2, 1, C(0x8A7040))   // a rope belt
    for k in 0..<4 { r(-6 + k * 3, 10, 2, 1, straw); r(-5 + k * 3, 11, 1, 1, strawD) }
    r(-17, -1, 2, 1, straw); r(-18, 0, 3, 1, straw); r(-17, 1, 2, 1, strawD)
    r(15, -1, 2, 1, straw); r(15, 0, 3, 1, straw); r(15, 1, 2, 1, strawD)
    r(-3, -2, 6, 1, straw); r(-2, -3, 1, 1, strawD); r(1, -3, 1, 1, straw)
    // The sack head, tied at the neck, lit on the left, with two dark button eyes and a stitched grin.
    r(-4, -10, 8, 8, sack); r(-4, -10, 2, 8, sackL); r(2, -10, 2, 8, sackD); r(-3, -11, 6, 1, sack)
    r(-2, -8, 1, 1, C(0x1A1410)); r(1, -8, 1, 1, C(0x1A1410))
    r(-2, -5, 4, 1, C(0x3A2A1E)); r(-2, -6, 1, 1, C(0x3A2A1E)); r(1, -6, 1, 1, C(0x3A2A1E))
    // The straw hat: a wide floppy brim and a dented crown, a dark band round it.
    r(-7, -12, 14, 1, C(0xB89448)); r(-6, -11, 2, 1, C(0x9A7A38)); r(4, -11, 2, 1, C(0x9A7A38))
    r(-4, -16, 8, 4, C(0xC8A454)); r(-4, -16, 2, 4, C(0xDCBC6C)); r(-1, -16, 2, 1, C(0x9A7A38))
    r(-4, -13, 8, 1, C(0x4A2A1E))
}

/// A crow standing at (`x`, `base`), facing left or right: a glossy black body, a dark grey beak, a tail.
private func huntP6Crow(_ c: PixelCanvas, _ x: Int, _ base: Int, _ s: Int, right: Bool) {
    let d = right ? 1 : -1
    func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) {
        let ux = d == 1 ? u : -u - w
        c.rect(x + ux * s, base + v * s, w * s, h * s, col)
    }
    r(-3, -4, 5, 3, C(0x161418)); r(-2, -4, 3, 1, C(0x34303C)); r(1, -6, 3, 3, C(0x161418)); r(2, -5, 1, 1, C(0xC8B060))
    r(4, -5, 2, 1, C(0x4A4650)); r(-5, -4, 2, 2, C(0x101014)); r(-1, -1, 1, 1, C(0x3A3640)); r(1, -1, 1, 1, C(0x3A3640))
}

extension Scenes {
    /// Where things stand in the orchard, shared by the still picture and the moving layer: the far horizon, the
    /// setting sun's middle, the scarecrow's post (its middle and its crossbar's row), Cain's beehives (the left one's
    /// edge), and the crows' perches.
    static func huntOrchardFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, sun: Int, post: (x: Int, bar: Int), hives: Int,
                                                                crows: [(x: Int, y: Int)]) {
        let s = unit(g)
        let post = (x: c.w * 21 / 100, bar: g - 36 * s)
        let hives = c.w - 54 * s
        let crows = [(x: c.w * 8 / 100, y: g), (x: c.w * 34 / 100, y: g), (x: hives + 14 * s, y: g - 18 * s)]
        return (g - 20 * s, c.w * 58 / 100, post, hives, crows)
    }

    /// The Burkitsville orchard at sunset: a sky going from dusky violet through rose to a blaze of orange, the sun
    /// sinking behind the far rows of apple trees, the town's white church steeple and a barn on the skyline, a split
    /// rail fence, the near apple trees heavy with red fruit at either side, the scarecrow on its post on the left (in
    /// the moving layer, so it can sway), a crate of picked apples, and Cain's white beehives on the right with his
    /// veiled hat hung on a stake. The grass under the crew is in the trees' evening shade. On the screen saver the sky
    /// rises through bands of lit cloud to the first stars, and a flock of crows wheels far off.
    static func huntOrchard(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntOrchardFrame(c, g), tall = isTall(c)
        // The sky.
        if tall {
            c.gradient(0, g * 40 / 100, C(0x1E1A3A), C(0x5A3A5E), bands: 7)
            c.gradient(g * 40 / 100, f.horizon, C(0x5A3A5E), C(0xF0904A), bands: 10)
            c.stars(0, g * 22 / 100, density: 90, seed: 77)
            c.rect(c.w * 30 / 100, g * 12 / 100, 2 * s, 2 * s, C(0xFFF4D8))
        } else {
            c.gradient(0, f.horizon, C(0x6A3E5E), C(0xF09048), bands: 6)
        }
        // The sun, a great orange disc half sunk, its glow spreading along the horizon.
        for r in stride(from: 46 * s, to: 6 * s, by: -5 * s) { c.ellipse(f.sun, f.horizon, r * 2, r / 2, C(0xFFB050, 0.07)) }
        c.circle(f.sun, f.horizon - 2 * s, 11 * s, C(0xF8A848)); c.circle(f.sun - 2 * s, f.horizon - 4 * s, 8 * s, C(0xFFC868))
        // Streaks of cloud lit from below, rose and gold.
        let streaks: [(Int, Int, Int)] = tall
            ? [(20, 30, 70), (64, 44, 90), (40, 58, 60), (84, 66, 50), (14, 76, 60), (52, 84, 80), (76, 90, 50)]
            : [(24, 8, 60), (72, 5, 70), (46, 14, 40), (90, 15, 40)]
        for (xp, yp, len) in streaks {
            let y = tall ? g * yp / 100 : yp * s
            wisp(c, c.w * xp / 100, y, len * s, C(0xC86A6A, 0.6), s: s)
            c.rect(c.w * xp / 100 - len * s / 3, y + s, len * s / 2, max(1, s / 2), C(0xFFC070, 0.6))
        }
        // On the screen saver: banks of cloud lit rose and gold from below, a pale moon rising, a farm windpump
        // dark against the glow, and a flock of crows wheeling far off, little dark Vs.
        if tall {
            let mx = c.w * 84 / 100, my = g * 16 / 100
            c.circle(mx, my, 8 * s, C(0xF4E8D0)); c.circle(mx - 3 * s, my - s, 7 * s, C(0x241E3E))
            for (k, (xp, yp, len)) in [(30, 34, 46), (74, 48, 38), (16, 58, 34), (54, 64, 50)].enumerated() {
                let x = c.w * xp / 100, y = g * yp / 100, l = len * s
                for j in 0..<5 {
                    let dx = Int((noise(k * 10 + j + 1500) - 0.5) * Double(l)), r = (5 + Int(noise(k * 10 + j + 1510) * 5)) * s
                    c.ellipse(x + dx, y - r / 2, r * 2, r, C(0x5A3A5E))
                }
                c.ellipse(x, y, l, 4 * s, C(0x6A4060))
                c.rect(x - l * 3 / 4, y + 3 * s, l * 3 / 2, s, C(0xE88A6A)); c.rect(x - l / 2, y + 4 * s, l, s, C(0xFFC070))
            }
            let wx = c.w * 10 / 100, wt = f.horizon - 56 * s, dark = C(0x2E2030)
            huntP6Stick(c, wx - 8 * s, f.horizon, wx - s, wt, dark, Double(s) * 0.8)
            huntP6Stick(c, wx + 8 * s, f.horizon, wx + s, wt, dark, Double(s) * 0.8)
            for y in stride(from: wt + 10 * s, to: f.horizon, by: 12 * s) {
                let half = 1 + (y - wt) * 8 / (f.horizon - wt)
                c.rect(wx - half * s, y, 2 * half * s, max(1, s / 2), dark)
            }
            for k in 0..<12 {
                let a = Double(k) * .pi / 6
                huntP6Stick(c, wx, wt, wx + Int(cos(a) * Double(9 * s)), wt + Int(sin(a) * Double(9 * s)), dark, Double(s) * 0.7)
            }
            c.circle(wx, wt, 2 * s, dark); c.rect(wx, wt - s, 12 * s, 2 * s, dark); c.rect(wx + 10 * s, wt - 4 * s, 4 * s, 7 * s, dark)
            for k in 0..<11 {
                let bx = c.w * 62 / 100 + Int((noise(k + 500) - 0.5) * 120) * s, by = g * 30 / 100 + Int((noise(k + 520) - 0.5) * 50) * s
                c.rect(bx - 2 * s, by, 2 * s, max(1, s), C(0x241A26)); c.rect(bx + s, by, 2 * s, max(1, s), C(0x241A26))
                c.rect(bx, by + s, max(1, s), max(1, s), C(0x241A26))
            }
        }
        c.dunes(base: f.horizon, amp: Double(s), freq: 0.05, phase: 0.4, bottom: f.horizon + 3 * s, C(0x3A2830))
        // The far rows of apple trees, sinking into the dusk.
        for (k, x) in stride(from: 4 * s, to: c.w, by: 18 * s).enumerated() where abs(x - f.sun) > 8 * s || k % 2 == 0 {
            huntP6AppleTree(c, x, f.horizon + 4 * s, 6 * s, s, seed: k + 3, haze: 0.62)
        }
        // The skyline: the far fields dark, a barn and silo, and the town's church steeple, white against the glow.
        let bx = c.w * 82 / 100
        c.rect(bx, f.horizon - 9 * s, 14 * s, 9 * s, C(0x5A2A26)); for k in 0..<5 { c.rect(bx - s + k * s, f.horizon - 10 * s - k * s, 16 * s - 2 * k * s, s, C(0x3A2026)) }
        c.rect(bx + 16 * s, f.horizon - 16 * s, 5 * s, 16 * s, C(0x4A3A3E)); c.circle(bx + 18 * s, f.horizon - 16 * s, 2 * s, C(0x4A3A3E))
        let ch = c.w * 47 / 100
        c.rect(ch, f.horizon - 8 * s, 12 * s, 8 * s, C(0xD8C8B8)); c.rect(ch + 9 * s, f.horizon - 8 * s, 3 * s, 8 * s, C(0xA89888))
        c.rect(ch + 2 * s, f.horizon - 16 * s, 4 * s, 8 * s, C(0xE4D4C2))
        for k in 0..<6 { c.rect(ch + 4 * s - (6 - k) * s / 3, f.horizon - 22 * s + k * s, max(1, (6 - k) * 2 * s / 3), s, C(0xE4D4C2)) }
        c.rect(ch + 4 * s - s / 2, f.horizon - 25 * s, max(1, s), 3 * s, C(0x5A4A4A))
        // The grass between: rust and olive in the long light, deeper towards the crew.
        c.gradient(f.horizon + 3 * s, g, C(0x6A5432), C(0x4A3E26), bands: 4)
        // The split rail fence along the back of the orchard.
        let fy = f.horizon + 6 * s
        for x in stride(from: 0, to: c.w, by: 22 * s) { c.rect(x, fy - 7 * s, 2 * s, 9 * s, C(0x4A3426)); c.rect(x, fy - 7 * s, max(1, s / 2), 9 * s, C(0x7A5A3A)) }
        for dy in [-6, -2] { c.rect(0, fy + dy * s, c.w, s, C(0x5A4230)); c.rect(0, fy + dy * s, c.w, max(1, s / 2), C(0x8A6A44)) }
        // The near apple trees at either side, big crowns over the crew's heads.
        let near: [(Int, Int)] = tall ? [(3, 30), (36, 24), (70, 26), (99, 28)] : [(4, 20), (42, 16), (74, 18), (99, 18)]
        for (k, (xp, r)) in near.enumerated() { huntP6AppleTree(c, c.w * xp / 100, g, r * s, s, seed: 40 + k, haze: 0) }
        // The scarecrow's post and crossbar (the scarecrow itself hangs in the moving layer).
        let p = f.post
        c.rect(p.x - s, p.bar - 22 * s, 4 * s, g - p.bar + 22 * s, C(0x4A3426)); c.rect(p.x - s, p.bar - 22 * s, max(1, s), g - p.bar + 22 * s, C(0x7A5A3A))
        c.rect(p.x - 24 * s, p.bar, 49 * s, 2 * s, C(0x4A3426)); c.rect(p.x - 24 * s, p.bar, 49 * s, max(1, s / 2), C(0x7A5A3A))
        c.ellipse(p.x, g, 8 * s, s, C(0x1E1610, 0.5))
        // A crate of picked apples by the post, and a few windfalls in the grass.
        let cx = p.x + 20 * s
        c.rect(cx, g - 7 * s, 14 * s, 7 * s, C(0x8A6A44)); c.rect(cx, g - 7 * s, 14 * s, s, C(0xA88A5A))
        c.rect(cx, g - 4 * s, 14 * s, max(1, s / 2), C(0x5A4228)); c.rect(cx + 13 * s, g - 7 * s, s, 7 * s, C(0x5A4228))
        for k in 0..<6 { c.rect(cx + s + k * 2 * s, g - 9 * s + (k % 2) * s, 2 * s, 2 * s, C(0xB02A20)); c.rect(cx + s + k * 2 * s, g - 9 * s + (k % 2) * s, s, s, C(0xE8603A)) }
        for k in 0..<7 {
            let ax = Int(noise(k + 300) * Double(c.w)), ay = g - 2 * s + Int(noise(k + 310) * 2) * s
            if abs(ax - c.w / 2) > c.w / 5 { c.rect(ax, ay, 2 * s, 2 * s, C(0x8A2A1E)) }
        }
        huntOrchardHives(c, g)
        // The grass the crew stands on: in the trees' evening shade, plain.
        c.ground(g, C(0x3E3622), edge: C(0x5A4A2C), speck: C(0x342E1C), seed: 131)
    }

    /// Cain's beehives on the right: three white wooden hives on a low stand, two and three boxes high, warm in the
    /// sunset, each with a lid and a dark entrance slot; his beekeeper's hat and veil hung on a stake beside them.
    private static func huntOrchardHives(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x0 = huntOrchardFrame(c, g).hives
        let white = C(0xE8D8C0), whiteL = C(0xFFF0D8), whiteD = C(0xB4A28C), lid = C(0x8A7A66)
        c.rect(x0 - 2 * s, g - 4 * s, 50 * s, 2 * s, C(0x4A3426)); c.rect(x0 - 2 * s, g - 4 * s, 50 * s, max(1, s / 2), C(0x6A4A34))
        for x in [x0, x0 + 44 * s] { c.rect(x, g - 2 * s, 2 * s, 2 * s, C(0x3A281E)) }
        for (k, n) in [2, 3, 2].enumerated() {
            let hx = x0 + k * 16 * s, h = n * 5 * s, top = g - 4 * s - h
            c.rect(hx, top, 13 * s, h, white); c.rect(hx, top, 2 * s, h, whiteL); c.rect(hx + 11 * s, top, 2 * s, h, whiteD)
            for b in 1..<n { c.rect(hx, top + b * 5 * s, 13 * s, max(1, s / 2), whiteD) }
            c.rect(hx - s, top - 2 * s, 15 * s, 2 * s, lid); c.rect(hx - s, top - 2 * s, 15 * s, max(1, s / 2), C(0xAA9A84))
            c.rect(hx + 3 * s, g - 6 * s, 7 * s, s, C(0x2A1E16))
            for b in 0..<n { c.rect(hx + 5 * s, top + b * 5 * s + 2 * s, 3 * s, s, whiteD) }   // the hand holds
        }
        // The stake with his beekeeper's hat hung on it: a round cream helmet with a wide brim, and the veil hanging
        // from the brim, a fine dark mesh you can see the stake and the sunset through, gathered at the bottom on its
        // drawstring.
        let sx = x0 - 8 * s, brim = g - 24 * s
        c.rect(sx, g - 22 * s, 2 * s, 22 * s, C(0x5A4230)); c.rect(sx, g - 22 * s, max(1, s / 2), 22 * s, C(0x7A5A40))
        let vx = sx - 5 * s, vw = 12 * s, vTop = brim + s, vBot = g - 11 * s
        for y in stride(from: vTop, to: vBot, by: max(1, s)) {
            let pinch = (y - vTop) > (vBot - vTop) * 2 / 3 ? s : 0   // drawn in towards the drawstring
            for x in stride(from: vx + pinch, to: vx + vw - pinch, by: max(1, s)) where ((x - vx) / max(1, s) + (y - vTop) / max(1, s)) % 2 == 0 {
                c.rect(x, y, max(1, s), max(1, s), C(0x2A2622, 0.55))
            }
            c.rect(vx + pinch, y, max(1, s), max(1, s), C(0x4A443A, 0.85)); c.rect(vx + vw - pinch - s, y, max(1, s), max(1, s), C(0x3A342C, 0.85))
        }
        c.rect(vx + s, vBot, vw - 2 * s, s, C(0xD8CCB0)); c.rect(sx + 3 * s, vBot + s, s, 2 * s, C(0xD8CCB0))
        c.ellipse(sx + s, brim, 8 * s, 2 * s, C(0xB8AC94)); c.ellipse(sx + s, brim - max(1, s / 2), 8 * s, s + s / 2, C(0xEADEC6))
        c.rect(sx - 6 * s, brim - s, 4 * s, max(1, s / 2), C(0xFFF4DC))
        c.ellipse(sx + s, brim - 3 * s, 4 * s, 3 * s, C(0xE4D8BE)); c.ellipse(sx, brim - 4 * s, 2 * s, s + s / 2, C(0xFFF6E2))
        c.rect(sx - 3 * s, brim - 2 * s, 8 * s, max(1, s), C(0x9A8A6A))
    }

    /// The orchard's life: the scarecrow swaying slowly on its bar, crows hopping in the grass and one riding the
    /// scarecrow's arm, and Cain's bees drifting round their hives.
    static func huntOrchardLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntOrchardFrame(c, g)
        let lean = sin(t * 0.9) * 1.6 * Double(s) + sin(t * 2.3) * 0.4 * Double(s)
        huntP6Scarecrow(c, f.post.x, f.post.bar, s, lean: lean)
        // A crow on the scarecrow's right arm, riding its sway.
        let armShift = Int((lean * 7.0 / 16.0).rounded())
        huntP6Crow(c, f.post.x + 17 * s + armShift, f.post.bar - 2 * s, s, right: false)
        // Crows in the grass and on the hive stand, each hopping now and then.
        for (k, cr) in f.crows.enumerated() {
            let phase = (t + Double(k) * 0.9).truncatingRemainder(dividingBy: 2.6)
            let hop = phase < 0.35 ? Int((sin(phase / 0.35 * .pi) * Double(3 * s)).rounded()) : 0
            let step = Int((t + Double(k) * 0.9) / 2.6) % 3 - 1
            huntP6Crow(c, cr.x + step * 2 * s, cr.y - hop, s, right: k != 1)
        }
        // The bees, specks of gold looping round the hives.
        for k in 0..<12 {
            let a = t * (0.8 + noise(k + 700) * 0.9) + Double(k) * 1.9
            let bx = f.hives + 22 * s + Int(cos(a) * Double((14 + k % 4 * 4) * s))
            let by = g - 20 * s + Int(sin(a * 1.6) * Double((5 + k % 3 * 2) * s))
            c.rect(bx, by, max(1, s), max(1, s), k % 3 == 0 ? C(0x2A1E10) : C(0xF0C040))
        }
    }
}

// MARK: - Chuck's House

extension Scenes {
    /// Where things stand in Chuck's study, shared by the still picture and the moving layer: the desk (its left
    /// edge, its width and its top), the desk lamp's shade, the window (left edge and top), the armchair's left edge,
    /// and the bookcases on the right (their left edge).
    static func huntChucksFrame(_ c: PixelCanvas, _ g: Int) -> (desk: (x: Int, w: Int, top: Int), lamp: (x: Int, y: Int),
                                                               window: (x: Int, y: Int), chair: Int, shelves: Int) {
        let s = unit(g)
        let desk = (x: c.w * 3 / 100, w: 74 * s, top: g - 16 * s)
        return (desk, (x: desk.x + 60 * s, y: desk.top - 22 * s), (x: c.w * 34 / 100, y: g - 56 * s), c.w * 50 / 100,
                c.w - 92 * s)
    }

    /// Chuck's house, the prophet's cluttered study at night: faded sage-grey striped wallpaper, a sash window on the
    /// dark street with rain on it, the desk on the left under a gooseneck lamp, buried in manuscript stacks with the
    /// laptop open among them, a whisky bottle and a mug, a corkboard of index cards, a bathrobe on the door hook, his
    /// own book covers framed on the wall over a sagging oxblood armchair, pizza boxes, empty bottles lined along the
    /// skirting, an overflowing wastebasket, his guitar on its stand, and bookcases on the right crammed every which
    /// way, with a run of his own Supernatural paperbacks. On the screen saver the bookcases climb to the ceiling on
    /// both sides, boxes of manuscripts on top, a crooked print hangs between, his plot board of cards and red string
    /// fills the wall beside it over his old typewriter, and a bare bulb hangs on its flex.
    static func huntChucks(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntChucksFrame(c, g), tall = isTall(c)
        let paper = C(0x4E5448), stripe = C(0x454C40), paperL = C(0x5E6454)
        let woodD = C(0x2A1A10), woodL = C(0x6A4A30)
        // The wallpaper: dull sage-grey in narrow stripes with a little damask diamond between, darker up high.
        c.rect(0, 0, c.w, g, paper)
        for (k, x) in stride(from: 0, to: c.w, by: 8 * s).enumerated() {
            c.rect(x, 0, 2 * s, g, stripe)
            for y in stride(from: (k % 2) * 6 * s + 3 * s, to: g, by: 12 * s) {
                c.rect(x + 5 * s, y, max(1, s), max(1, s), paperL); c.rect(x + 4 * s, y + s, 3 * s, max(1, s), paperL)
                c.rect(x + 5 * s, y + 2 * s, max(1, s), max(1, s), paperL)
            }
        }
        c.gradient(0, g, C(0x0C0A08, 0.3), C(0x0C0A08, 0), bands: 4)
        // The desk lamp's warm light washing the wall round the desk.
        for r in stride(from: 70 * s, to: 10 * s, by: -6 * s) {
            c.ellipse(f.lamp.x - 10 * s, f.desk.top - 4 * s, r * 3 / 2, r, C(0xE8B060, 0.03))
        }
        if tall { huntChucksHigh(c, g) }
        // The sash window: night outside, a streetlamp on the pavement, the houses across the road with a lit
        // window or two, rain on the glass, chipped white paint, and a sill with two empty bottles on it.
        let w = f.window, ww = 30 * s, wh = 30 * s
        c.rect(w.x - 2 * s, w.y - 2 * s, ww + 4 * s, wh + 4 * s, C(0xB8B4A4)); c.rect(w.x - 2 * s, w.y - 2 * s, ww + 4 * s, s, C(0xD8D4C4))
        c.rect(w.x, w.y, ww, wh, C(0x121A2E)); c.rect(w.x, w.y + wh / 2, ww, wh / 2, C(0x182238))
        c.circle(w.x + 6 * s, w.y + 6 * s, 3 * s, C(0xE8E4D0)); c.circle(w.x + 7 * s, w.y + 5 * s, 3 * s, C(0x121A2E))
        c.rect(w.x, w.y + 19 * s, ww, 11 * s, C(0x0C101A))   // the houses across the road
        for k in 0..<3 { c.rect(w.x + (k * 10 + 2) * s, w.y + 15 * s + (k % 2) * 2 * s, 8 * s, 5 * s, C(0x0C101A)) }
        c.rect(w.x + 4 * s, w.y + 21 * s, 2 * s, 2 * s, C(0xD8A858)); c.rect(w.x + 16 * s, w.y + 22 * s, 2 * s, 2 * s, C(0xD8A858))
        c.rect(w.x + 23 * s, w.y + 9 * s, max(1, s), 21 * s, C(0x2A2E36))
        for r in stride(from: 7 * s, to: s, by: -2 * s) { c.circle(w.x + 23 * s, w.y + 9 * s, r, C(0xF0C060, 0.12)) }
        c.rect(w.x + 22 * s, w.y + 8 * s, 3 * s, 2 * s, C(0xF8E0A0))
        for k in 0..<10 {
            let rx = w.x + Int(noise(k + 1200) * Double(ww - s)), ry = w.y + Int(noise(k + 1210) * Double(wh - 3 * s))
            c.rect(rx, ry, max(1, s / 2), 2 * s, C(0x8A9AB8, 0.5))
        }
        c.rect(w.x, w.y + wh / 2 - s, ww, 2 * s, C(0xB8B4A4)); c.rect(w.x + ww / 2 - s / 2, w.y, max(1, s), wh, C(0xA8A494))
        c.rect(w.x - 4 * s, w.y + wh + 2 * s, ww + 8 * s, 2 * s, C(0xC8C4B4)); c.rect(w.x - 4 * s, w.y + wh + 4 * s, ww + 8 * s, s, C(0x7A7668))
        huntChucksBottle(c, w.x + 3 * s, w.y + wh + 2 * s, s, 0); huntChucksBottle(c, w.x + 24 * s, w.y + wh + 2 * s, s, 2)
        // The bathrobe on its hook beside the window: a faded blue towelling robe, its sleeves hanging, the belt
        // looped through and dangling.
        let rx = w.x + ww + 8 * s, ry = w.y - 2 * s
        let robe = C(0x4A5A72), robeL = C(0x6A7A92), robeD = C(0x34405A)
        c.rect(rx + 6 * s, ry - 2 * s, 2 * s, 3 * s, C(0x8A7A50))
        c.rect(rx + 2 * s, ry + s, 10 * s, 3 * s, robe)
        c.rect(rx, ry + 3 * s, 14 * s, 30 * s, robe); c.rect(rx, ry + 3 * s, 3 * s, 30 * s, robeL); c.rect(rx + 11 * s, ry + 3 * s, 3 * s, 30 * s, robeD)
        c.rect(rx + 5 * s, ry + s, 4 * s, 6 * s, robeD); c.rect(rx + 7 * s, ry + 7 * s, max(1, s), 26 * s, robeD)
        c.rect(rx - s, ry + 4 * s, 3 * s, 16 * s, robeL); c.rect(rx + 12 * s, ry + 4 * s, 3 * s, 16 * s, robeD)
        c.rect(rx - s, ry + 18 * s, 3 * s, 2 * s, C(0x3A4660)); c.rect(rx + 12 * s, ry + 18 * s, 3 * s, 2 * s, C(0x2A3448))
        c.rect(rx + 2 * s, ry + 17 * s, 10 * s, 2 * s, C(0x5E6E86)); c.rect(rx + 8 * s, ry + 19 * s, s, 10 * s, C(0x5E6E86))
        c.rect(rx + 9 * s, ry + 19 * s, s, 8 * s, C(0x5E6E86))
        for y in stride(from: ry + 8 * s, to: ry + 32 * s, by: 6 * s) { c.rect(rx + 3 * s, y, 3 * s, max(1, s / 2), robeD) }
        // The corkboard over the desk: index cards and notes pinned up, a red pin in each.
        let cb = (x: f.desk.x + 6 * s, y: f.desk.top - 40 * s)
        c.rect(cb.x - s, cb.y - s, 36 * s, 20 * s, woodL); c.rect(cb.x, cb.y, 34 * s, 18 * s, C(0x9A7A4A))
        for (k, (u, v, cw, chh)) in [(2, 2, 8, 6), (12, 1, 7, 5), (21, 3, 9, 6), (4, 10, 9, 6), (15, 9, 6, 7), (24, 11, 8, 5)].enumerated() {
            let col = [C(0xEEE8D8), C(0xE8D888), C(0xEEE8D8), C(0xC8D8E0), C(0xEEE8D8), C(0xE8B8A8)][k]
            c.rect(cb.x + u * s, cb.y + v * s, cw * s, chh * s, col)
            for l in 1..<(chh / 2 + 1) { c.rect(cb.x + (u + 1) * s, cb.y + (v + l * 2) * s, (cw - 2) * s, max(1, s / 2), C(0x8A8478)) }
            c.rect(cb.x + (u + cw / 2) * s, cb.y + v * s, s, s, C(0xC03030))
        }
        // A page taped to the wall beside the board, and another curling off it.
        c.rect(cb.x + 38 * s, cb.y + 2 * s, 7 * s, 9 * s, C(0xE4DECC)); c.rect(cb.x + 40 * s, cb.y + s, 3 * s, 2 * s, C(0xC8C0A0, 0.8))
        for l in 0..<3 { c.rect(cb.x + 39 * s, cb.y + (4 + l * 2) * s, 5 * s, max(1, s / 2), C(0x8A8478)) }
        huntChucksCorner(c, g)
        huntChucksShelves(c, g, x0: f.shelves, x1: c.w, top: tall ? 10 * s : 0, seed: 1, novels: true)
        // The skirting board, and empty bottles lined up along it under the window.
        c.rect(0, g - 3 * s, c.w, 3 * s, woodD); c.rect(0, g - 3 * s, c.w, max(1, s / 2), woodL)
        for k in 0..<5 { huntChucksBottle(c, w.x + 2 * s + k * 5 * s, g, s, k) }
        // The guitar on its stand by the bookcase, a sunburst acoustic, its neck up.
        let gx = f.shelves - 12 * s
        huntP6Stick(c, gx - 4 * s, g, gx, g - 8 * s, C(0x1E1A18), Double(s) * 0.6); huntP6Stick(c, gx + 4 * s, g, gx, g - 8 * s, C(0x1E1A18), Double(s) * 0.6)
        c.rect(gx - s, g - 36 * s, 3 * s, 20 * s, C(0x3A2416)); c.rect(gx - s, g - 36 * s, max(1, s), 20 * s, C(0x5A3A22))
        for y in stride(from: g - 34 * s, to: g - 17 * s, by: 3 * s) { c.rect(gx - s, y, 3 * s, max(1, s / 2), C(0xB8B0A0)) }
        c.rect(gx - 2 * s, g - 40 * s, 4 * s, 4 * s, C(0x2A1A10)); c.rect(gx - 2 * s, g - 39 * s, s, s, C(0xC8C0B0)); c.rect(gx + s, g - 38 * s, s, s, C(0xC8C0B0))
        c.ellipse(gx, g - 9 * s, 7 * s, 6 * s, C(0x8A4A1E)); c.ellipse(gx, g - 16 * s, 5 * s, 4 * s, C(0x8A4A1E))
        c.ellipse(gx, g - 9 * s, 5 * s, 4 * s, C(0xC8803A)); c.ellipse(gx, g - 16 * s, 3 * s, 3 * s, C(0xC8803A))
        c.ellipse(gx - s, g - 10 * s, 2 * s, 2 * s, C(0xE0A050))
        c.circle(gx, g - 12 * s, 2 * s, C(0x1A100A)); c.rect(gx - 2 * s, g - 7 * s, 5 * s, s, C(0x2A1A10))
        huntChucksDesk(c, g)
        // The floor: dark old floorboards, plain.
        c.ground(g, C(0x3A2A1E), edge: C(0x4E3A2A), speck: C(0x30221A), seed: 151)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x2A1E16)) }
    }

    /// The reading corner in the middle of the room: three of his own book covers framed on the wall, black with an
    /// amber title band and a little black car on each, over a sagging oxblood leather armchair with a crocheted
    /// throw, a side table with a stack of books and a tumbler, and pizza boxes piled on the floor beside it.
    private static func huntChucksCorner(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x = huntChucksFrame(c, g).chair
        // The framed covers.
        for k in 0..<3 {
            let fx = x + 2 * s + k * 13 * s, fy = g - 56 * s + (k == 1 ? -2 * s : 0)
            c.rect(fx, fy, 11 * s, 15 * s, C(0x6A5230)); c.rect(fx, fy, 11 * s, max(1, s / 2), C(0x9A7A48))
            c.rect(fx + s, fy + s, 9 * s, 13 * s, C(0x1A1614))
            c.rect(fx + s, fy + 3 * s, 9 * s, 2 * s, C(0xD89A3A)); c.rect(fx + 2 * s, fy + 3 * s + s / 2, 7 * s, max(1, s / 2), C(0x5A3A14))
            c.rect(fx + 2 * s, fy + 10 * s, 7 * s, 2 * s, C(0x2A2A30)); c.rect(fx + 3 * s, fy + 9 * s, 4 * s, s, C(0x2A2A30))
            c.rect(fx + 3 * s, fy + 12 * s, s, s, C(0x5A5A60)); c.rect(fx + 7 * s, fy + 12 * s, s, s, C(0x5A5A60))
            c.rect(fx + 8 * s, fy + 10 * s, s, s, C(0xE8D890))
        }
        // The armchair: high back, rolled arms, a sagging seat, dark legs; the throw over one arm.
        let leather = C(0x5A2420), leatherL = C(0x7A3A30), leatherD = C(0x3A1614)
        let ax = x + 4 * s, top = g - 28 * s
        c.rect(ax + 4 * s, top, 24 * s, 16 * s, leather); c.rect(ax + 4 * s, top, 24 * s, 2 * s, leatherL); c.rect(ax + 4 * s, top, 2 * s, 16 * s, leatherL)
        c.rect(ax + 26 * s, top, 2 * s, 16 * s, leatherD)
        for k in 0..<3 { c.rect(ax + (9 + k * 6) * s, top + 5 * s, s, s, leatherD) }   // the buttons
        c.rect(ax + 6 * s, g - 13 * s, 20 * s, 4 * s, leatherL); c.rect(ax + 6 * s, g - 10 * s, 20 * s, s, leatherD)
        for side in [ax, ax + 26 * s] {
            c.rect(side, g - 18 * s, 6 * s, 12 * s, leather); c.rect(side, g - 19 * s, 6 * s, 2 * s, leatherL)
            c.rect(side + 5 * s, g - 18 * s, s, 12 * s, leatherD)
        }
        c.rect(ax + s, g - 6 * s, 30 * s, 3 * s, leatherD)
        for lx in [ax + 2 * s, ax + 28 * s] { c.rect(lx, g - 3 * s, 2 * s, 3 * s, C(0x1E120C)) }
        for k in 0..<5 {   // the crocheted throw over the left arm, in squares of mustard and teal
            c.rect(ax - s, g - 19 * s + k * 3 * s, 7 * s, 3 * s, k % 2 == 0 ? C(0xB88A3A) : C(0x3A6A6A))
            c.rect(ax - s, g - 19 * s + k * 3 * s, 7 * s, max(1, s / 2), C(0xD8B060))
        }
        // The side table, books stacked on it and a tumbler.
        let tx = ax + 34 * s
        c.rect(tx, g - 14 * s, 12 * s, 2 * s, C(0x5A3A24)); c.rect(tx, g - 14 * s, 12 * s, max(1, s / 2), C(0x7A5434))
        c.rect(tx + s, g - 12 * s, 2 * s, 12 * s, C(0x3A2416)); c.rect(tx + 9 * s, g - 12 * s, 2 * s, 12 * s, C(0x3A2416))
        c.rect(tx + s, g - 6 * s, 10 * s, s, C(0x3A2416))
        for (k, col) in [C(0x2E4A5A), C(0x7A2A22), C(0x5A5A2A)].enumerated() {
            c.rect(tx + s + k * s / 2, g - (16 + k * 2) * s, 8 * s, 2 * s, col); c.rect(tx + s + k * s / 2, g - (16 + k * 2) * s, 8 * s, max(1, s / 2), C(0xD8CCB0))
        }
        c.rect(tx + 9 * s, g - 17 * s, 2 * s, 3 * s, C(0xA8B0B0, 0.7)); c.rect(tx + 9 * s, g - 15 * s, 2 * s, s, C(0xA86A2A))
        // Pizza boxes stacked on the floor past the table, the top one's lid ajar.
        let px = tx + 15 * s
        for k in 0..<4 {
            let dx = (k % 2) * s
            c.rect(px + dx, g - (k + 1) * 2 * s, 16 * s, 2 * s, k % 2 == 0 ? C(0xC8A878) : C(0xB89868))
            c.rect(px + dx, g - (k + 1) * 2 * s, 16 * s, max(1, s / 2), C(0xE0C898))
        }
        c.rect(px + 4 * s, g - 7 * s, 8 * s, max(1, s / 2), C(0xB03A2A))
        c.rect(px + 2 * s, g - 10 * s, 14 * s, s, C(0xD8BC88))
    }

    /// On the screen saver: the high cornice, a second bookcase climbing the wall over the desk, a long shelf of
    /// manuscript boxes across the top, a crooked print of a rocky coast, a water stain, and the bare bulb hanging on
    /// its flex over the middle of the room.
    private static func huntChucksHigh(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntChucksFrame(c, g)
        c.rect(0, 0, c.w, 6 * s, C(0x3A3A30)); c.rect(0, 6 * s, c.w, 2 * s, C(0x5A5A4C)); c.rect(0, 8 * s, c.w, s, C(0x2A2A22))
        huntChucksShelves(c, g, x0: 0, x1: c.w * 34 / 100, top: 10 * s, bottom: g - 64 * s, seed: 7, novels: false)
        // A long shelf across the top between the cases, boxes of manuscripts on it, papers spilling.
        let sy = 40 * s, x0 = c.w * 34 / 100, x1 = f.shelves
        c.rect(x0, sy, x1 - x0, 2 * s, C(0x5E4028)); c.rect(x0, sy + 2 * s, x1 - x0, s, C(0x22140C))
        for bx in stride(from: x0 + 4 * s, to: x1 - 22 * s, by: 24 * s) {
            let bh = (10 + Int(noise(bx / max(1, s) + 1300) * 5)) * s
            c.rect(bx, sy - bh, 20 * s, bh, C(0x9A7A4E)); c.rect(bx, sy - bh, 20 * s, s, C(0xB8966A)); c.rect(bx + 18 * s, sy - bh, 2 * s, bh, C(0x6A5232))
            c.rect(bx + 6 * s, sy - bh + 3 * s, 8 * s, 3 * s, C(0xE8E0CC))
            c.rect(bx + 2 * s, sy - bh - 2 * s, 14 * s, 2 * s, C(0xE8E0CC))
        }
        for k in 0..<4 { c.rect(x0 + (30 + k * 50) * s, sy + 3 * s, 6 * s, (3 + k % 2 * 3) * s, C(0xE4DECC)) }   // pages hanging over the edge
        // The bare bulb on its flex, a faint halo, and a water stain on the plaster near it.
        let bx = c.w * 56 / 100, by = g * 34 / 100
        c.rect(bx, sy + 3 * s, max(1, s / 2), by - sy - 3 * s, C(0x1E1A16))
        for r in stride(from: 30 * s, to: 4 * s, by: -5 * s) { c.circle(bx, by + 3 * s, r, C(0xF0D090, 0.03)) }
        c.rect(bx - s, by, 3 * s, 2 * s, C(0x6A6458)); c.ellipse(bx + s / 2, by + 4 * s, 2 * s, 2 * s, C(0xF8E8B8))
        c.ellipse(c.w * 70 / 100, sy + 24 * s, 12 * s, 6 * s, C(0x6A6040, 0.22))
        // The crooked print: a rocky coast under a grey sky, its frame hanging a little askew.
        let px = c.w * 40 / 100, py = g * 44 / 100
        for row in 0..<(24 * s) {
            let dx = row / (8 * s)
            c.rect(px + dx, py + row, 32 * s, 1, C(0x5A4228))
        }
        for row in (2 * s)..<(22 * s) {
            let dx = row / (8 * s), col: Px = row < 10 * s ? C(0x8A98A0) : row < 13 * s ? C(0xC8D0D0) : row < 18 * s ? C(0x3A5A6A) : C(0x4A4A44)
            c.rect(px + dx + 2 * s, py + row, 28 * s, 1, col)
        }
        c.rect(px + 18 * s, py + 9 * s, 6 * s, 9 * s, C(0x3E3E3A))
        huntP6Stick(c, px + 10 * s, py, px + 17 * s, py - 6 * s, C(0x8A7A50), Double(s) * 0.4)
        huntP6Stick(c, px + 24 * s, py + 2 * s, px + 17 * s, py - 6 * s, C(0x8A7A50), Double(s) * 0.4)
        // Round the print, a little gallery: a framed certificate, two small photos, and his first book's cover.
        for (u, v, fw, fh, inner) in [(-16, -14, 10, 8, 0xE8E0C8), (40, -10, 8, 10, 0x8A7A6A), (44, 6, 8, 8, 0x6A7A86), (-14, 30, 12, 16, 0x1A1614)] {
            c.rect(px + u * s, py + v * s, fw * s, fh * s, C(0x5A4228)); c.rect(px + (u + 1) * s, py + (v + 1) * s, (fw - 2) * s, (fh - 2) * s, C(UInt32(inner)))
            if inner == 0x1A1614 { c.rect(px + (u + 1) * s, py + (v + 4) * s, (fw - 2) * s, 2 * s, C(0xD89A3A)) }
            if inner == 0xE8E0C8 { c.rect(px + (u + 3) * s, py + (v + 3) * s, (fw - 6) * s, max(1, s / 2), C(0x8A8070)); c.rect(px + (u + 4) * s, py + (v + 5) * s, 2 * s, s, C(0xC03030)) }
        }
        // The library ladder leaning on the right-hand bookcase, and a cobweb in the corner of the ceiling.
        let lx = f.shelves - 14 * s, lt = 60 * s, lb = g - 4 * s
        huntP6Stick(c, lx, lb, f.shelves + 10 * s, lt, C(0x7A5434), Double(s) * 0.9)
        huntP6Stick(c, lx + 8 * s, lb, f.shelves + 18 * s, lt, C(0x5A3A24), Double(s) * 0.9)
        for k in 1..<Int((lb - lt) / (10 * s)) {
            let y = lb - k * 10 * s, kx = lx + (f.shelves + 10 * s - lx) * k * 10 * s / max(1, lb - lt)
            c.rect(kx, y, 8 * s, s, C(0x8A6440))
        }
        for k in 0..<4 { huntP6Stick(c, x0, 9 * s, x0 + (12 - k * 3) * s, 9 * s + (k * 4) * s, C(0xC8C8C0, 0.35), Double(s) * 0.3) }
        // A wall sconce on either side of the print, unlit.
        for sx in [px - 20 * s, px + 52 * s] {
            c.rect(sx, py + 6 * s, 3 * s, 5 * s, C(0x6A5A3A)); c.rect(sx - s, py + 2 * s, 5 * s, 4 * s, C(0xC8B890))
        }
        huntChucksPlotBoard(c, g)
    }

    /// On the screen saver, filling the wall between the tall bookcases: the big plot board where he works out the
    /// story, cork in a dark frame covered in index cards, notes and snapshots with red string pinned from card to card,
    /// and under it a little shelf with his old typewriter and a stack of fresh pages.
    private static func huntChucksPlotBoard(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntChucksFrame(c, g)
        let x0 = c.w * 60 / 100, x1 = min(f.shelves - 8 * s, x0 + 100 * s), y0 = g * 36 / 100, y1 = y0 + 58 * s
        guard x1 - x0 > 40 * s else { return }
        c.rect(x0 - 2 * s, y0 - 2 * s, x1 - x0 + 4 * s, y1 - y0 + 4 * s, C(0x3A2416)); c.rect(x0 - 2 * s, y0 - 2 * s, x1 - x0 + 4 * s, s, C(0x6A4A30))
        c.rect(x0, y0, x1 - x0, y1 - y0, C(0x9A7A4A))
        for i in 0..<((x1 - x0) * (y1 - y0) / (40 * s * s)) {
            c.rect(x0 + Int(noise(i + 1400) * Double(x1 - x0 - s)), y0 + Int(noise(i + 1450) * Double(y1 - y0 - s)), s, s, C(0x86683C))
        }
        // The cards, in loose rows; each one's pin is where the string goes.
        let tones = [C(0xEEE8D8), C(0xE8D888), C(0xC8D8E0), C(0xEEE8D8), C(0xE8B8A8), C(0xEEE8D8)]
        var pins: [(Int, Int)] = []
        let cols = max(2, (x1 - x0) / (17 * s)), rows = 3
        for row in 0..<rows {
            for col in 0..<cols {
                let n = row * cols + col
                guard noise(n + 1500) > 0.18 else { continue }
                let cx = x0 + 3 * s + col * (x1 - x0 - 6 * s) / cols + Int(noise(n + 1510) * Double(4 * s))
                let cy = y0 + 3 * s + row * 18 * s + Int(noise(n + 1520) * Double(4 * s))
                let photo = noise(n + 1530) > 0.78
                if photo {   // a snapshot: white border, a dark little scene
                    c.rect(cx, cy, 9 * s, 10 * s, C(0xF0ECE0)); c.rect(cx + s, cy + s, 7 * s, 6 * s, C(0x3A4A5A)); c.rect(cx + s, cy + 5 * s, 7 * s, 2 * s, C(0x2A2A22))
                } else {
                    c.rect(cx, cy, 11 * s, 8 * s, tones[n % tones.count])
                    for l in 0..<3 { c.rect(cx + s, cy + (2 + l * 2) * s, (l == 2 ? 5 : 9) * s, max(1, s / 2), C(0x6A6458)) }
                }
                c.rect(cx + 4 * s, cy, s, s, C(0xC03030))
                pins.append((cx + 4 * s, cy))
            }
        }
        // The red string, from pin to pin, criss-crossing the board.
        for k in 0..<max(0, pins.count - 1) where noise(k + 1540) > 0.25 {
            let a = pins[k], b = pins[(k + 1 + Int(noise(k + 1550) * 3)) % pins.count]
            huntP6Stick(c, a.0, a.1, b.0, b.1, C(0xC8302A), Double(s) * 0.4)
        }
        // The typewriter shelf under the board.
        let ty = y1 + 26 * s, tx = (x0 + x1) / 2
        c.rect(tx - 24 * s, ty, 48 * s, 2 * s, C(0x5E4028)); c.rect(tx - 24 * s, ty, 48 * s, max(1, s / 2), C(0x8A6440))
        for bx in [tx - 20 * s, tx + 17 * s] { c.rect(bx, ty + 2 * s, 2 * s, 4 * s, C(0x3A2416)) }
        c.rect(tx - 10 * s, ty - 6 * s, 20 * s, 6 * s, C(0x2A2C2A)); c.rect(tx - 10 * s, ty - 6 * s, 20 * s, s, C(0x4A4E4A))
        c.rect(tx - 7 * s, ty - 9 * s, 14 * s, 3 * s, C(0x222422)); c.rect(tx - 12 * s, ty - 9 * s, 24 * s, s, C(0x1A1A1A))
        c.rect(tx - 5 * s, ty - 14 * s, 10 * s, 5 * s, C(0xEEE8D8)); c.rect(tx - 4 * s, ty - 12 * s, 7 * s, max(1, s / 2), C(0x6A6458))
        for k in 0..<4 { c.rect(tx - 8 * s + k * 4 * s, ty - 3 * s, 3 * s, s, C(0xC8C4B8)) }
        for j in 0..<5 { c.rect(tx + 14 * s, ty - (j + 1) * s, 8 * s, s, j % 2 == 0 ? C(0xE8E2D0) : C(0xCCC4B0)) }
    }

    /// An empty bottle standing on row `base`: whisky brown, beer green or clear, lit on its left.
    private static func huntChucksBottle(_ c: PixelCanvas, _ x: Int, _ base: Int, _ s: Int, _ k: Int) {
        let tones: [(UInt32, UInt32)] = [(0x6A3A16, 0xA8642A), (0x2A5A2A, 0x4A8A44), (0x8A9A9A, 0xC8D4D4), (0x5A2A12, 0x8A4A1E), (0x2E4A2A, 0x50784A)]
        let (col, lit) = tones[k % tones.count]
        let tallB = k % 2 == 0 ? 7 : 6
        c.rect(x, base - tallB * s, 3 * s, (tallB - 3) * s, C(col)); c.rect(x, base - tallB * s, max(1, s), (tallB - 3) * s, C(lit))
        c.rect(x, base - 3 * s, 3 * s, 3 * s, C(col)); c.rect(x + s, base - (tallB + 3) * s, s, 3 * s, C(col))
        c.rect(x + s, base - (tallB + 3) * s, s, max(1, s / 2), C(0x2A1A10))
    }

    /// A bookcase from `x0` to `x1`, from `top` down to `bottom` (the skirting by default): dark wood, crammed with
    /// books upright, leaning and stacked flat, and (where `novels` says) a run of his own Supernatural paperbacks in
    /// matching black-and-amber spines. On the screen saver the tall one has boxes of manuscripts on top.
    private static func huntChucksShelves(_ c: PixelCanvas, _ g: Int, x0: Int, x1: Int, top: Int, bottom: Int? = nil,
                                          seed: Int, novels: Bool) {
        let s = unit(g)
        let foot = bottom ?? g - 3 * s, width = x1 - x0
        let wood = C(0x3E2618), woodD = C(0x22140C), woodL = C(0x5E4028)
        let tones: [UInt32] = [0x6A2A22, 0x2E4A5A, 0x5A5A2A, 0x7A4A2A, 0x3A2A3E, 0x8A7A5A, 0x4A3A2A, 0x2A4A3A]
        c.rect(x0, top, width, foot - top, woodD)
        let pitch = 13 * s
        var row = 0
        for base in stride(from: foot - 2 * s, to: top + 9 * s, by: -pitch) {
            var x = x0 + 3 * s, i = row * 97 + 11 + seed * 1000
            let ownRow = novels && row == 2
            while x < x1 - 3 * s {
                let r = noise(i)
                if ownRow && x < x0 + 46 * s {
                    c.rect(x, base - 9 * s, 3 * s, 9 * s, C(0x1E1A18)); c.rect(x, base - 7 * s, 3 * s, 2 * s, C(0xD89A3A))
                    c.rect(x, base - 9 * s, max(1, s / 2), 9 * s, C(0x3A3430)); x += 3 * s; i += 7; continue
                }
                let col = C(tones[Int(noise(i + 1) * Double(tones.count)) % tones.count])
                if r > 0.86 && x + 10 * s < x1 - 3 * s {   // a stack lying flat
                    for k in 0..<3 { c.rect(x, base - (k + 1) * 2 * s, 9 * s, 2 * s, C(tones[(i + k) % tones.count])); c.rect(x, base - (k + 1) * 2 * s, 9 * s, max(1, s / 2), C(0xD8CCB0)) }
                    x += 10 * s
                } else if r > 0.76 && x + 6 * s < x1 - 3 * s {   // one leaning on the next
                    huntP6Stick(c, x + s, base, x + 5 * s, base - 8 * s, col, Double(s) * 1.3); x += 6 * s
                } else {
                    let bw = min((2 + Int(noise(i + 2) * 2.5)) * s, x1 - 3 * s - x), bh = (7 + Int(noise(i + 3) * 3)) * s
                    c.rect(x, base - bh, bw, bh, col); c.rect(x, base - bh, max(1, s / 2), bh, lerp(col, C(0xFFFFFF), 0.2))
                    if noise(i + 4) > 0.7 { c.rect(x, base - bh + 2 * s, bw, max(1, s / 2), C(0xC8A858)) }
                    x += max(s, bw)
                }
                i += 13
            }
            c.rect(x0, base, width, 2 * s, wood); c.rect(x0, base, width, max(1, s / 2), woodL)
            row += 1
        }
        // The sides and the uprights between the cases.
        for ux in stride(from: x0, to: x1, by: 46 * s) { c.rect(ux, top, 3 * s, foot - top, wood); c.rect(ux, top, s, foot - top, woodL) }
        c.rect(x1 - 2 * s, top, 2 * s, foot - top, wood)
        c.rect(x0, top, width, 2 * s, wood)
    }

    /// The desk on the left: a heavy old writing desk with drawers, buried in manuscript stacks, the laptop open
    /// among them, a whisky bottle and a mug, the gooseneck lamp bent over it all, and a wastebasket spilling
    /// crumpled pages beside it.
    private static func huntChucksDesk(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntChucksFrame(c, g), d = f.desk
        let wood = C(0x5A3A24), woodD = C(0x3A2416), woodL = C(0x7A5434)
        // The lamp's pool of light on the wall and desk.
        for r in stride(from: 34 * s, to: 6 * s, by: -4 * s) { c.ellipse(f.lamp.x - 8 * s, d.top, r, r * 2 / 3, C(0xF0C070, 0.035)) }
        // The desk: top, drawer pedestals either end, a dark knee-hole between.
        c.rect(d.x, d.top, d.w, 3 * s, wood); c.rect(d.x, d.top, d.w, s, woodL); c.rect(d.x, d.top + 3 * s, d.w, s, woodD)
        for px in [d.x + s, d.x + d.w - 21 * s] {
            c.rect(px, d.top + 4 * s, 20 * s, g - d.top - 4 * s, wood); c.rect(px + 18 * s, d.top + 4 * s, 2 * s, g - d.top - 4 * s, woodD)
            for y in stride(from: d.top + 5 * s, to: g - 3 * s, by: 4 * s) {
                c.rect(px + 2 * s, y, 15 * s, 3 * s, woodD); c.rect(px + 2 * s, y, 15 * s, max(1, s / 2), woodL)
                c.rect(px + 8 * s, y + s, 3 * s, s, C(0xB89048))
            }
        }
        c.rect(d.x + 21 * s, d.top + 4 * s, d.w - 42 * s, g - d.top - 4 * s, C(0x1A120C))
        // The manuscript stacks: piles of paper, each sheet's edge a line, a rubber band round one.
        for (k, (u, n)) in [(2, 7), (11, 11), (20, 5), (64, 8)].enumerated() {
            let px = d.x + u * s
            for j in 0..<n {
                let dx = Int((noise(k * 40 + j) - 0.5) * 2.4) * s
                c.rect(px + dx, d.top - (j + 1) * s, 8 * s, s, j % 2 == 0 ? C(0xE8E2D0) : C(0xCCC4B0))
            }
            if k == 1 { c.rect(px + 5 * s, d.top - n * s, s, n * s, C(0xA83A2A)) }
        }
        // The laptop open on the desk, its screen glowing pale (the cursor blinks in the moving layer).
        let lx = d.x + 30 * s
        c.rect(lx, d.top - s, 16 * s, s, C(0x5A5A60)); c.rect(lx + 2 * s, d.top - 12 * s, 12 * s, 11 * s, C(0x2A2A30))
        c.rect(lx + 3 * s, d.top - 11 * s, 10 * s, 9 * s, C(0xC8D0D8))
        for l in 0..<4 { c.rect(lx + 4 * s, d.top - (10 - l * 2) * s, (l == 3 ? 4 : 8) * s, max(1, s / 2), C(0x5A6070)) }
        for r in stride(from: 10 * s, to: 2 * s, by: -3 * s) { c.ellipse(lx + 8 * s, d.top - 6 * s, r, r * 3 / 4, C(0xC8D8F0, 0.04)) }
        // The whisky bottle and a tumbler, and a mug of cold coffee.
        let bx = d.x + 50 * s
        c.rect(bx, d.top - 9 * s, 4 * s, 9 * s, C(0x7A4214)); c.rect(bx, d.top - 9 * s, s, 9 * s, C(0xB06A2A))
        c.rect(bx + s, d.top - 13 * s, 2 * s, 4 * s, C(0x7A4214)); c.rect(bx + s, d.top - 14 * s, 2 * s, s, C(0x1A1410))
        c.rect(bx, d.top - 6 * s, 4 * s, 3 * s, C(0xE8D8B0))
        c.rect(bx + 6 * s, d.top - 4 * s, 3 * s, 4 * s, C(0xA8B0B0, 0.7)); c.rect(bx + 6 * s, d.top - 2 * s, 3 * s, 2 * s, C(0xA86A2A))
        c.rect(d.x + 74 * s - 8 * s, d.top - 4 * s, 4 * s, 4 * s, C(0xC84A3A)); c.rect(d.x + 74 * s - 4 * s, d.top - 3 * s, s, 2 * s, C(0xC84A3A))
        // The gooseneck lamp: a heavy base, the neck curving up and over, a green enamel shade bent down at the desk.
        let base = (x: d.x + 58 * s, y: d.top)
        c.rect(base.x - 3 * s, base.y - 2 * s, 7 * s, 2 * s, C(0x1E2A22)); c.rect(base.x - 3 * s, base.y - 2 * s, 7 * s, max(1, s / 2), C(0x3E5A46))
        huntP6Stick(c, base.x, base.y - 2 * s, base.x - 2 * s, f.lamp.y + 8 * s, C(0x5A5A50), Double(s) * 0.6)
        huntP6Stick(c, base.x - 2 * s, f.lamp.y + 8 * s, f.lamp.x, f.lamp.y + s, C(0x5A5A50), Double(s) * 0.6)
        c.rect(f.lamp.x - 6 * s, f.lamp.y, 8 * s, 3 * s, C(0x2E5A3E)); c.rect(f.lamp.x - 6 * s, f.lamp.y, 8 * s, s, C(0x4A7A56))
        c.rect(f.lamp.x - 7 * s, f.lamp.y + 3 * s, 9 * s, s, C(0x1E3A28))
        // The wastebasket beside the desk, crumpled pages heaped over its rim and on the floor round it.
        let wx = d.x + d.w + 4 * s
        c.rect(wx, g - 9 * s, 9 * s, 9 * s, C(0x3A3A40)); c.rect(wx, g - 9 * s, 2 * s, 9 * s, C(0x5A5A62)); c.rect(wx, g - 9 * s, 9 * s, s, C(0x6A6A72))
        for (u, v) in [(1, -11), (4, -12), (6, -10), (-3, -2), (11, -2), (13, -3)] {
            c.circle(wx + u * s + s, g + v * s + s, s + s / 2, C(0xE0DACA)); c.rect(wx + u * s + s, g + v * s, s, s, C(0xB8B2A2))
        }
    }

    /// The study's life: the desk lamp's warm pool of light, buzzing and dipping now and then, the cursor blinking on
    /// the laptop, the top sheet of a manuscript pile lifting in a draught, and now and then a loose page drifting
    /// down off the desk to the floor.
    static func huntChucksLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntChucksFrame(c, g), d = f.desk
        let phase = t.truncatingRemainder(dividingBy: 9.0)
        let dip = phase > 7.2 && phase < 7.8 && Int(t * 13) % 3 != 0
        if !dip {
            for r in stride(from: 16 * s, to: 3 * s, by: -3 * s) { c.ellipse(f.lamp.x - 2 * s, d.top - 2 * s, r * 3 / 2, r / 2, C(0xFFD890, 0.06)) }
            c.rect(f.lamp.x - 5 * s, f.lamp.y + 4 * s, 6 * s, max(1, s), C(0xFFF0C0))
        }
        if Int(t * 2) % 2 == 0 { c.rect(d.x + 38 * s, d.top - 4 * s, max(1, s), 2 * s, C(0x2A3040)) }
        // The top sheet of the tall stack lifting at one corner.
        let lift = max(0, sin(t * 1.7)) * Double(2 * s)
        let px = d.x + 11 * s, py = d.top - 12 * s
        c.rect(px, py, 5 * s, s, C(0xF2ECDC)); c.rect(px + 5 * s, py - Int(lift), 3 * s, s, C(0xF2ECDC))
        // A loose page, every dozen seconds, see-sawing down off the desk's right end to the floor.
        let cycle = t.truncatingRemainder(dividingBy: 12.0)
        if cycle < 3.0 {
            let k = cycle / 3.0
            let x = d.x + d.w - 6 * s + Int(sin(k * .pi * 3) * Double(4 * s)) + Int(k * Double(6 * s))
            let y = d.top - 2 * s + Int(k * Double(g - d.top))
            let flat = cos(k * .pi * 3) > 0
            c.rect(x, y, flat ? 5 * s : 3 * s, flat ? s : 2 * s, C(0xEEE8D6))
        }
    }
}

// MARK: - Sioux Falls

extension Scenes {
    /// Where things stand in Jody's kitchen, shared by the still picture and the moving layer: the counter's top, the
    /// window over the sink (its left edge and top), the wall clock, the opening into the stair hall (its left edge),
    /// and on the screen saver the kitchen's ceiling (the landing's floor above it) and the landing's ceiling.
    static func huntSiouxFallsFrame(_ c: PixelCanvas, _ g: Int) -> (counter: Int, window: (x: Int, y: Int), clock: (x: Int, y: Int),
                                                                   hall: Int, ceiling: Int, attic: Int) {
        let s = unit(g)
        return (g - 14 * s, (x: c.w * 24 / 100, y: g - 50 * s), (x: c.w * 62 / 100, y: g - 50 * s), c.w - 70 * s,
                g - 70 * s, g - 144 * s)
    }

    /// Jody's kitchen in Sioux Falls on a warm afternoon: butter-yellow walls, sage-green cupboards and a run of
    /// denim-blue tiles behind the counter, the window over the sink with red gingham curtains and the garden beyond,
    /// a cream fridge covered in magnets and a kid's drawing, the stove with a red kettle, a pie cooling on the sill,
    /// an open shelf of mugs and jars, the coffee maker, the wall clock, a row of family photos (Jody, Claire, Alex,
    /// Donna), a calendar, the gun rack high on the wall with a shotgun and a rifle, and on the right the stair hall,
    /// the stairs climbing away, her tan sheriff's jacket and hat on the coat stand and the old phone on the wall. On
    /// the screen saver the house is cut away: the stairs reach the upstairs landing, with the girls' bedroom doors and
    /// a hall lamp, and above that the attic under the rafters.
    static func huntSiouxFalls(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g), tall = isTall(c)
        let wall = C(0xCCAE6A), wallL = C(0xDCC07C)
        let sage = C(0x6A7A5A), sageL = C(0x84946E), sageD = C(0x4E5C42)
        // The wall: butter yellow, a faint vertical pattern, a touch darker low down.
        c.rect(0, 0, c.w, g, wall)
        for x in stride(from: 0, to: c.w, by: 10 * s) { c.rect(x, 0, max(1, s / 2), g, wallL) }
        c.gradient(0, g, C(0x3A2A10, 0), C(0x3A2A10, 0.12), bands: 3)
        if tall { huntSiouxFallsUpstairs(c, g) }
        huntSiouxFallsHall(c, g)
        // The upper cupboards either side of the window: sage green doors with panels and brass knobs.
        let w = f.window, ww = 40 * s, wh = 24 * s
        let cupTop = w.y - 4 * s, cupH = 20 * s
        for (x, n) in [(4 * s, 3), (w.x + ww + 14 * s, 2)] {
            c.rect(x, cupTop, n * 14 * s, cupH, sageD)
            for k in 0..<n {
                let dx = x + k * 14 * s + s
                c.rect(dx, cupTop + s, 12 * s, cupH - 2 * s, sage); c.rect(dx, cupTop + s, 12 * s, s, sageL); c.rect(dx, cupTop + s, s, cupH - 2 * s, sageL)
                c.rect(dx + 2 * s, cupTop + 3 * s, 8 * s, cupH - 6 * s, sageD); c.rect(dx + 3 * s, cupTop + 4 * s, 6 * s, cupH - 8 * s, sage)
                c.rect(dx + (k % 2 == 0 ? 10 : 1) * s, cupTop + cupH - 5 * s, s, s, C(0xC8A048))
            }
            c.rect(x - s, cupTop - 2 * s, n * 14 * s + 2 * s, 2 * s, sageL)
        }
        // The window over the sink: the garden in the afternoon, sky, a tree and a picket fence, in a white frame.
        c.rect(w.x - 2 * s, w.y - 2 * s, ww + 4 * s, wh + 4 * s, C(0xF0EADA))
        c.rect(w.x, w.y, ww, wh, C(0x8ABCE0)); c.rect(w.x, w.y + wh / 2, ww, wh / 2, C(0xB0D0E0))
        c.ellipse(w.x + 28 * s, w.y + 12 * s, 9 * s, 7 * s, C(0x4A7A3A)); c.ellipse(w.x + 26 * s, w.y + 10 * s, 5 * s, 4 * s, C(0x6A9A4A))
        c.rect(w.x + 27 * s, w.y + 17 * s, 2 * s, 5 * s, C(0x5A4230))
        c.rect(w.x, w.y + 18 * s, ww, 6 * s, C(0x6A8A48))
        for x in stride(from: w.x + s, to: w.x + ww, by: 4 * s) { c.rect(x, w.y + 16 * s, 2 * s, 4 * s, C(0xE8E4D8)) }
        c.rect(w.x, w.y + 17 * s, ww, max(1, s / 2), C(0xE8E4D8))
        c.rect(w.x + ww / 2 - s / 2, w.y, max(1, s), wh, C(0xF0EADA)); c.rect(w.x, w.y + wh / 2, ww, max(1, s), C(0xF0EADA))
        // The curtain rail and its valance, red gingham (the curtains themselves hang in the moving layer).
        c.rect(w.x - 8 * s, w.y - 5 * s, ww + 16 * s, s, C(0x8A6A3A))
        for x in stride(from: w.x - 8 * s, to: w.x + ww + 8 * s, by: 2 * s) {
            let k = (x - w.x) / (2 * s)
            c.rect(x, w.y - 4 * s, 2 * s, 4 * s, abs(k) % 2 == 0 ? C(0xC0342A) : C(0xF0E4D8))
            c.rect(x, w.y - 2 * s, 2 * s, 2 * s, abs(k) % 2 == 0 ? C(0xE08A80) : C(0xC0342A))
        }
        // The sill: a pie cooling, a potted geranium.
        c.rect(w.x - 3 * s, w.y + wh + 2 * s, ww + 6 * s, 2 * s, C(0xE8E0CC))
        c.ellipse(w.x + 9 * s, w.y + wh + s, 6 * s, 2 * s, C(0xC89048)); c.rect(w.x + 4 * s, w.y + wh, 10 * s, max(1, s / 2), C(0xE8B868))
        for k in 0..<3 { c.rect(w.x + (6 + k * 3) * s, w.y + wh, s, s, C(0x7A3A2A)) }
        c.rect(w.x + 30 * s, w.y + wh - 2 * s, 5 * s, 4 * s, C(0xA85A3A)); c.rect(w.x + 30 * s, w.y + wh - 2 * s, 5 * s, s, C(0xC8784A))
        c.ellipse(w.x + 32 * s, w.y + wh - 4 * s, 3 * s, 2 * s, C(0x3E6A30)); c.rect(w.x + 31 * s, w.y + wh - 6 * s, 2 * s, 2 * s, C(0xE03A3A))
        // The tile splashback: denim-blue squares with pale grout, from the counter up to the sill.
        let tileTop = w.y + wh + 4 * s
        c.rect(0, tileTop, f.hall - 2 * s, f.counter - tileTop, C(0x5A7088))
        for y in stride(from: tileTop + 4 * s, to: f.counter, by: 4 * s) { c.rect(0, y, f.hall - 2 * s, max(1, s / 2), C(0x7A8EA2)) }
        for x in stride(from: 0, to: f.hall - 2 * s, by: 4 * s) { c.rect(x, tileTop, max(1, s / 2), f.counter - tileTop, C(0x7A8EA2)) }
        huntSiouxFallsWall(c, g)
        // The fridge on the left: a rounded old cream fridge, chrome handle, magnets, a crayon drawing and a photo.
        let fx = 6 * s, ft = g - 48 * s
        c.rect(fx, ft + 2 * s, 22 * s, g - ft - 2 * s, C(0xE4DCC4)); c.rect(fx + 2 * s, ft, 18 * s, 2 * s, C(0xE4DCC4))
        c.rect(fx, ft + 2 * s, 3 * s, g - ft - 2 * s, C(0xF4EEDC)); c.rect(fx + 19 * s, ft + 2 * s, 3 * s, g - ft - 2 * s, C(0xB8B098))
        c.rect(fx, ft + 16 * s, 22 * s, max(1, s / 2), C(0x9A9280)); c.rect(fx + 17 * s, ft + 6 * s, s, 7 * s, C(0xB8BCC0)); c.rect(fx + 17 * s, ft + 20 * s, s, 9 * s, C(0xB8BCC0))
        c.rect(fx + 4 * s, ft + 19 * s, 8 * s, 7 * s, C(0xF4F0E8)); c.rect(fx + 5 * s, ft + 23 * s, 3 * s, 2 * s, C(0x3A8A3A)); c.circle(fx + 9 * s, ft + 21 * s, s, C(0xE8C030))
        c.rect(fx + 5 * s, ft + 5 * s, 6 * s, 5 * s, C(0x8A7A6A)); c.rect(fx + 6 * s, ft + 6 * s, 4 * s, 3 * s, C(0xC8A47A))
        for (u, v, col) in [(13, 4, 0xC0342A), (4, 12, 0x3A6AB0), (14, 26, 0xE8B030), (8, 18, 0xC0342A)] { c.rect(fx + u * s, ft + v * s, 2 * s, 2 * s, C(UInt32(col))) }
        // The counter: butcher-block top, sage cupboard doors below, a plain run behind the crew.
        let cx0 = fx + 24 * s, cx1 = f.hall - 4 * s
        c.rect(cx0, f.counter, cx1 - cx0, 2 * s, C(0x9A7A50)); c.rect(cx0, f.counter, cx1 - cx0, max(1, s / 2), C(0xBA9A6A))
        c.rect(cx0, f.counter + 2 * s, cx1 - cx0, g - f.counter - 2 * s, sageD)
        // The cupboards under it, not all alike: pairs of doors, a stack of drawers, a single door with a tea towel
        // over its knob, raised panels on some; all in the same quiet sage so the run stays calm behind the crew.
        let ch = g - f.counter - 5 * s, cy = f.counter + 3 * s, knob = C(0xC8A048)
        for (k, x) in stride(from: cx0 + s, to: cx1 - 12 * s, by: 15 * s).enumerated() {
            switch k % 4 {
            case 1:   // three drawers, each with a brass pull
                for d in 0..<3 {
                    let dy = cy + d * ch / 3
                    c.rect(x, dy, 13 * s, ch / 3 - max(1, s / 2), sage); c.rect(x, dy, 13 * s, max(1, s / 2), sageL)
                    c.rect(x + 4 * s, dy + s, 5 * s, max(1, s / 2), knob)
                }
            case 2:   // one door, the tea towel hanging off its knob in red gingham
                c.rect(x, cy, 13 * s, ch, sage); c.rect(x, cy, 13 * s, max(1, s / 2), sageL); c.rect(x, cy, max(1, s / 2), ch, sageL)
                c.rect(x + 2 * s, cy + 2 * s, 9 * s, ch - 4 * s, sageD); c.rect(x + 3 * s, cy + 3 * s, 7 * s, ch - 6 * s, sage)
                c.rect(x + 10 * s, cy + 2 * s, s, s, knob)
                for ty in 0..<4 { for tx in 0..<2 { c.rect(x + (9 + tx * 2) * s, cy + (3 + ty * 2) * s, 2 * s, 2 * s, (tx + ty) % 2 == 0 ? C(0xA83A30) : C(0xE8DCCC)) } }
            default:  // a pair of doors meeting in the middle, raised panels on every other pair
                for d in 0..<2 {
                    let dx = x + d * 7 * s
                    c.rect(dx, cy, 6 * s, ch, sage); c.rect(dx, cy, 6 * s, max(1, s / 2), sageL); c.rect(dx, cy, max(1, s / 2), ch, sageL)
                    if k % 4 == 3 { c.rect(dx + s, cy + 2 * s, 4 * s, ch - 4 * s, sageD); c.rect(dx + 2 * s, cy + 3 * s, 3 * s, ch - 6 * s, sage) }
                    c.rect(d == 0 ? dx + 5 * s : dx, cy + 2 * s, s, s, knob)
                }
            }
        }
        c.rect(cx0, g - 2 * s, cx1 - cx0, 2 * s, C(0x3A4430))
        // The sink under the window and its tap; a dish rack beside it.
        c.rect(w.x + 8 * s, f.counter - s, 24 * s, s, C(0xC8CCD0))
        huntP6Stick(c, w.x + 20 * s, f.counter - s, w.x + 20 * s, f.counter - 6 * s, C(0xB8BCC4), Double(s) * 0.6)
        huntP6Stick(c, w.x + 20 * s, f.counter - 6 * s, w.x + 23 * s, f.counter - 5 * s, C(0xB8BCC4), Double(s) * 0.6)
        for k in 0..<4 { c.rect(w.x + 36 * s + k * 2 * s, f.counter - 6 * s, s, 6 * s, C(0xE8E4DA)) }
        c.rect(w.x + 35 * s, f.counter - 2 * s, 9 * s, 2 * s, C(0x9AA0A8))
        // The stove right of the sink: white, black burners, a red kettle, its oven door with a window.
        let sx = w.x + ww + 17 * s
        c.rect(sx, f.counter - s, 22 * s, g - f.counter + s, C(0xE8E4DA)); c.rect(sx + 20 * s, f.counter - s, 2 * s, g - f.counter + s, C(0xB8B4AA))
        c.rect(sx, f.counter - s, 22 * s, s, C(0xF8F4EA))
        c.rect(sx + 3 * s, f.counter + 3 * s, 16 * s, 7 * s, C(0x2A2A2E)); c.rect(sx + 4 * s, f.counter + 4 * s, 14 * s, max(1, s / 2), C(0x5A5A60))
        c.rect(sx + 3 * s, f.counter + s, 16 * s, s, C(0xB8BCC0))
        c.rect(sx + 3 * s, f.counter - 2 * s, 5 * s, s, C(0x1E1E22)); c.rect(sx + 13 * s, f.counter - 2 * s, 5 * s, s, C(0x1E1E22))
        let kx = sx + 13 * s, ky = f.counter - 2 * s
        c.ellipse(kx + 3 * s, ky - 3 * s, 4 * s, 3 * s, C(0xC0342A)); c.ellipse(kx + 2 * s, ky - 4 * s, 2 * s, s, C(0xE06A5A))
        c.rect(kx + 2 * s, ky - 7 * s, 2 * s, s, C(0x2A1E1A)); huntP6Stick(c, kx - s, ky - 3 * s, kx - 3 * s, ky - 5 * s, C(0xC0342A), Double(s) * 0.6)
        // Along the counter: the coffee maker with its pot, a bowl of apples, the cookie jar.
        let cm = sx + 28 * s
        c.rect(cm, f.counter - 12 * s, 9 * s, 12 * s, C(0x2A2A2E)); c.rect(cm, f.counter - 12 * s, 9 * s, s, C(0x4A4A50))
        c.rect(cm + 2 * s, f.counter - 7 * s, 6 * s, 6 * s, C(0x9AA8B0, 0.8)); c.rect(cm + 2 * s, f.counter - 4 * s, 6 * s, 3 * s, C(0x3A2014))
        c.rect(cm + 6 * s, f.counter - 10 * s, s, s, C(0xE84A3A))
        let fb = cm + 20 * s
        c.ellipse(fb, f.counter - 2 * s, 6 * s, 2 * s, C(0xE8E0D0)); c.rect(fb - 6 * s, f.counter - 3 * s, 12 * s, s, C(0xC8C0B0))
        for (k, col) in [C(0xC0342A), C(0x8AAA3A), C(0xD84A2A), C(0xE8B030)].enumerated() {
            c.circle(fb - 3 * s + k * 2 * s, f.counter - 5 * s + (k % 2) * s, 2 * s, col)
        }
        let cj = fb + 30 * s
        c.rect(cj, f.counter - 8 * s, 8 * s, 8 * s, C(0xD8C8A0)); c.rect(cj, f.counter - 8 * s, 2 * s, 8 * s, C(0xEADCB8))
        c.rect(cj - s, f.counter - 10 * s, 10 * s, 2 * s, C(0x8A5A3A)); c.rect(cj + 3 * s, f.counter - 12 * s, 2 * s, 2 * s, C(0x8A5A3A))
        c.rect(cj + 2 * s, f.counter - 5 * s, 4 * s, 2 * s, C(0x6A8AA0))
        // The floor: warm old pine boards, plain.
        c.ground(g, C(0x5A402C), edge: C(0x6E5238), speck: C(0x4E3826), seed: 171)
        for x in stride(from: 0, to: c.w, by: 26 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x4A3424)) }
    }

    /// The wall between the cupboards and the hall: an open shelf of mugs and jars, the gun rack high up with a pump
    /// shotgun and a scoped rifle on its pegs (out of reach of anyone under twelve), the clock's face, the family photos
    /// in a row, and a calendar.
    private static func huntSiouxFallsWall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g)
        let k = f.clock
        // The open shelf: mugs on hooks under it, jars on top.
        let shx = f.window.x + 40 * s + 46 * s, shy = g - 38 * s
        c.rect(shx, shy, 26 * s, 2 * s, C(0x8A6A44)); c.rect(shx, shy, 26 * s, max(1, s / 2), C(0xAA8A5A))
        for (j, col) in [C(0xC8A048), C(0xA8C0C8), C(0xD87A4A), C(0xE8E0D0)].enumerated() {
            let jx = shx + s + j * 6 * s
            c.rect(jx, shy - 6 * s, 4 * s, 6 * s, col.alpha(0.85)); c.rect(jx, shy - 7 * s, 4 * s, s, C(0x5A4A3A))
        }
        for (j, col) in [C(0xF0EADA), C(0x4A6A9A), C(0xC0342A)].enumerated() {
            let mx = shx + 3 * s + j * 8 * s
            c.rect(mx, shy + 3 * s, 4 * s, 4 * s, col); c.rect(mx + 4 * s, shy + 4 * s, s, 2 * s, col)
            c.rect(mx + s, shy + 2 * s, max(1, s / 2), s, C(0x6A6A6A))
        }
        // The gun rack: two varnished uprights with pegs, a pump shotgun on top and a scoped rifle below.
        let rx = k.x - 48 * s, ry = k.y - 12 * s
        for ux in [rx + 2 * s, rx + 30 * s] {
            c.rect(ux, ry, 4 * s, 26 * s, C(0x7A5434)); c.rect(ux, ry, s, 26 * s, C(0xA27A4C)); c.rect(ux + 3 * s, ry, s, 26 * s, C(0x5A3A22))
        }
        for (j, gy) in [ry + 8 * s, ry + 19 * s].enumerated() {
            for ux in [rx + 2 * s, rx + 30 * s] { c.rect(ux - s, gy + s, 6 * s, 2 * s, C(0x4A3420)) }
            // The barrel and action, blued steel lit along the top.
            c.rect(rx - 4 * s, gy - 2 * s, 28 * s, 2 * s, C(0x3A3E48)); c.rect(rx - 4 * s, gy - 2 * s, 28 * s, max(1, s / 2), C(0x8A92A0))
            c.rect(rx + 16 * s, gy - 2 * s, 8 * s, 3 * s, C(0x2E323A))
            // The wooden stock, sloping down to the butt.
            c.rect(rx + 24 * s, gy - 2 * s, 8 * s, 3 * s, C(0x9A5E2E)); c.rect(rx + 24 * s, gy - 2 * s, 8 * s, max(1, s / 2), C(0xC07A40))
            c.rect(rx + 30 * s, gy - s, 8 * s, 4 * s, C(0x8A4E24)); c.rect(rx + 37 * s, gy - s, s, 4 * s, C(0x3A2010))
            if j == 0 {   // the shotgun's pump under the barrel
                c.rect(rx + 4 * s, gy, 8 * s, 2 * s, C(0x9A5E2E)); c.rect(rx + 4 * s, gy, 8 * s, max(1, s / 2), C(0xC07A40))
            } else {   // the rifle's scope over its action
                c.rect(rx + 12 * s, gy - 5 * s, 10 * s, 2 * s, C(0x22262E)); c.rect(rx + 12 * s, gy - 5 * s, 2 * s, 2 * s, C(0x6A7A8A))
                c.rect(rx + 15 * s, gy - 3 * s, s, s, C(0x22262E)); c.rect(rx + 19 * s, gy - 3 * s, s, s, C(0x22262E))
            }
        }
        // The clock: a round white face in a wooden rim (the hands tick in the moving layer).
        c.circle(k.x, k.y, 7 * s, C(0x6A4A2E)); c.circle(k.x, k.y, 6 * s, C(0xF4EEE0))
        for a in 0..<12 {
            let ang = Double(a) * .pi / 6
            c.rect(k.x + Int(cos(ang) * Double(5 * s)), k.y + Int(sin(ang) * Double(5 * s)), max(1, s / 2 + 1), max(1, s / 2 + 1), C(0x3A3A3A))
        }
        // The family photos: four frames in a row, each a little portrait against a sky-blue backdrop.
        let hair: [UInt32] = [0x4A2E1E, 0xE8C878, 0x2A1A14, 0xF0D890]
        let frames: [UInt32] = [0x3A2A1E, 0xD8D0C0, 0x8A6A3A, 0x3A2A1E]
        for (n, h) in hair.enumerated() {
            let px = k.x + 12 * s + n * 11 * s, py = k.y - 6 * s + (n % 2) * 3 * s
            c.rect(px, py, 9 * s, 11 * s, C(frames[n])); c.rect(px + s, py + s, 7 * s, 9 * s, C(0x9AB8D0))
            c.rect(px + 2 * s, py + 7 * s, 5 * s, 3 * s, n == 0 ? C(0xA8925A) : C(0x7A4A6A))
            c.rect(px + 3 * s, py + 3 * s, 3 * s, 4 * s, C(0xE0B090))
            c.rect(px + 2 * s, py + 2 * s, 5 * s, 2 * s, C(h)); c.rect(px + 2 * s, py + 4 * s, s, (n == 1 || n == 3 ? 4 : 2) * s, C(h))
            if n == 1 || n == 3 { c.rect(px + 6 * s, py + 4 * s, s, 4 * s, C(h)) }
        }
        // The calendar under the photos: a picture of a lake on top, the month's grid below, a day ringed in red.
        let cx = k.x + 22 * s, cy = k.y + 10 * s
        c.rect(cx, cy, 12 * s, 16 * s, C(0xF4F0E4)); c.rect(cx + s, cy + s, 10 * s, 6 * s, C(0x5A8AB0)); c.rect(cx + s, cy + 5 * s, 10 * s, 2 * s, C(0x4A7A3A))
        for r in 0..<3 { for q in 0..<4 { c.rect(cx + (1 + q * 3) * s, cy + (9 + r * 2) * s, 2 * s, max(1, s / 2), C(0xA8A090)) } }
        c.rect(cx + 6 * s, cy + 10 * s, 3 * s, s, C(0xD03A2E))
    }

    /// The stair hall through the wide opening on the right: a darker sage wall, the stairs climbing away to the
    /// left from the far corner under a dark handrail, the old cream phone on the wall with its curly cord, and
    /// Jody's tan sheriff's jacket and hat on the coat stand.
    private static func huntSiouxFallsHall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g), tall = isTall(c)
        let x0 = f.hall, top = tall ? f.ceiling : 0
        c.rect(x0, top, c.w - x0, g - top, C(0x6E7A62))
        for x in stride(from: x0, to: c.w, by: 8 * s) { c.rect(x, top, max(1, s / 2), g - top, C(0x64705A)) }
        c.rect(x0, g - 4 * s, c.w - x0, 4 * s, C(0xE8E0CC)); c.rect(x0, g - 4 * s, c.w - x0, max(1, s / 2), C(0xF4EEDC))
        // The stairs: treads lit on their noses, risers in shadow, white spindles under the handrail.
        let foot = c.w - 6 * s
        var sx = foot - 10 * s, sy = g
        let stop = tall ? f.ceiling : -10 * s
        while sy > stop && sx > x0 - 6 * s {
            c.rect(sx, sy - 4 * s, c.w - sx, 4 * s, C(0x6A4E32)); c.rect(sx, sy - 4 * s, c.w - sx, s, C(0xA07E52))
            c.rect(sx + 2 * s, sy - 16 * s, s, 12 * s, C(0xF0EADA))
            sx -= 3 * s; sy -= 4 * s
        }
        c.rect(foot - 10 * s, g - 22 * s, 3 * s, 22 * s, C(0x5A3A24)); c.rect(foot - 11 * s, g - 24 * s, 5 * s, 2 * s, C(0x8A6040))
        huntP6Stick(c, foot - 9 * s, g - 22 * s, sx + 2 * s, sy - 16 * s, C(0x5A3A24), Double(s) * 1.1)
        // The frame of the opening, white.
        c.rect(x0 - 3 * s, top, 3 * s, g - top, C(0xF0EADA)); c.rect(x0 - s, top, s, g - top, C(0xC8C0B0))
        // The phone on the hall wall, under the stairs: a cream wall phone, its handset, its curly cord.
        let px = x0 + 4 * s, py = g - 40 * s
        c.rect(px, py, 6 * s, 9 * s, C(0xE8DCC0)); c.rect(px, py, 6 * s, s, C(0xF4ECD8)); c.rect(px + 5 * s, py, s, 9 * s, C(0xB8AC90))
        c.rect(px - s, py + s, 2 * s, 8 * s, C(0xD8CCB0)); c.rect(px + 2 * s, py + 3 * s, 2 * s, 2 * s, C(0x8A8070))
        for k in 0..<4 { c.rect(px + (k % 2) * s - s, py + (9 + k * 2) * s, 2 * s, s, C(0xC8BCA0)) }
        // The coat stand: Jody's tan uniform jacket with its star, and her hat on the top hook.
        let cx = x0 + 16 * s
        c.rect(cx, g - 40 * s, 2 * s, 36 * s, C(0x4A3020)); c.rect(cx - 4 * s, g - 6 * s, 10 * s, 2 * s, C(0x3A2418))
        c.rect(cx - 5 * s, g - 34 * s, 12 * s, 18 * s, C(0xB89A68)); c.rect(cx - 5 * s, g - 34 * s, 2 * s, 18 * s, C(0xD0B47E))
        c.rect(cx + 5 * s, g - 34 * s, 2 * s, 18 * s, C(0x8A7048)); c.rect(cx, g - 34 * s, max(1, s), 18 * s, C(0x8A7048))
        c.rect(cx - 4 * s, g - 34 * s, 3 * s, 3 * s, C(0x7A5E38)); c.rect(cx + 3 * s, g - 34 * s, 3 * s, 3 * s, C(0x7A5E38))
        c.rect(cx + 2 * s, g - 29 * s, 2 * s, 2 * s, C(0xE8C850)); c.rect(cx - 4 * s, g - 27 * s, 3 * s, 2 * s, C(0x8A7048))
        c.rect(cx - 5 * s, g - 42 * s, 12 * s, 2 * s, C(0x8A6A3A)); c.rect(cx - 2 * s, g - 46 * s, 6 * s, 4 * s, C(0xA07E48))
        c.rect(cx - 2 * s, g - 43 * s, 6 * s, s, C(0x4A3420))
    }

    /// On the screen saver: the house cut away above the kitchen. The kitchen's ceiling with its lamp, the landing's
    /// floor resting on it, the upstairs hall in a soft blue-grey with a runner on the boards, Claire's door with a
    /// band poster, Alex's door, the bathroom door ajar, a hall lamp on a little table, and above that the attic under
    /// its rafters: a round window, boxes, an old trunk and a rocking chair.
    private static func huntSiouxFallsUpstairs(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g)
        let floorY = f.ceiling
        // The kitchen ceiling, the joists' ends and the landing's floorboards on top.
        c.rect(0, floorY - 4 * s, c.w, 4 * s, C(0x6A4A30)); c.rect(0, floorY - 4 * s, c.w, s, C(0x8A6A44))
        c.rect(0, floorY, c.w, 3 * s, C(0xE8E0CC)); c.rect(0, floorY + 3 * s, c.w, s, C(0xB8AE98))
        let lx = c.w * 40 / 100
        c.rect(lx - s / 2, floorY + 4 * s, max(1, s), 8 * s, C(0x3A3028))
        c.ellipse(lx, floorY + 13 * s, 8 * s, 3 * s, C(0xF4ECD0)); c.rect(lx - 8 * s, floorY + 13 * s, 16 * s, s, C(0xC8BCA0))
        for r in stride(from: 30 * s, to: 6 * s, by: -6 * s) { c.ellipse(lx, floorY + 18 * s, r, r / 2, C(0xFFF4D0, 0.04)) }
        // The upstairs hall's wall, a soft blue-grey with a white dado rail.
        let wallTop = f.attic, x1 = f.hall
        c.rect(0, wallTop, x1, floorY - 4 * s - wallTop, C(0x8A98A4))
        for x in stride(from: 0, to: x1, by: 12 * s) { c.rect(x, wallTop, max(1, s / 2), floorY - 4 * s - wallTop, C(0x7E8C98)) }
        c.rect(0, floorY - 26 * s, x1, 2 * s, C(0xF0EADA))
        c.rect(0, floorY - 8 * s, x1, 4 * s, C(0x5A3E28)); c.rect(0, floorY - 8 * s, x1, s, C(0x7A5A3A))   // the boards, edge on
        c.rect(c.w * 8 / 100, floorY - 7 * s, c.w * 60 / 100, 2 * s, C(0x8A2E2A))   // the runner
        // The doors: Claire's with its poster, Alex's with a dreamcatcher, the bathroom ajar on white tile.
        for (k, xp) in [10, 30, 52].enumerated() {
            let dx = c.w * xp / 100, dt = floorY - 46 * s
            c.rect(dx - 2 * s, dt - 2 * s, 22 * s, 40 * s, C(0xF0EADA))
            if k == 2 {
                c.rect(dx, dt, 18 * s, 38 * s, C(0xE4E8EC))
                for y in stride(from: dt + 3 * s, to: dt + 38 * s, by: 3 * s) { c.rect(dx, y, 18 * s, max(1, s / 2), C(0xB8C4CC)) }
                c.rect(dx + 10 * s, dt, 8 * s, 38 * s, C(0x9A7A52)); c.rect(dx + 10 * s, dt, 2 * s, 38 * s, C(0xB8966A))
                continue
            }
            c.rect(dx, dt, 18 * s, 38 * s, C(0x8A6A44)); c.rect(dx, dt, 2 * s, 38 * s, C(0xA88A5A))
            c.rect(dx + 3 * s, dt + 3 * s, 12 * s, 14 * s, C(0x7A5A38)); c.rect(dx + 3 * s, dt + 20 * s, 12 * s, 14 * s, C(0x7A5A38))
            c.rect(dx + 15 * s, dt + 19 * s, 2 * s, 2 * s, C(0xC8A048))
            if k == 0 {   // Claire's: a band poster, black with a red slash and a white star
                c.rect(dx + 3 * s, dt + 4 * s, 12 * s, 15 * s, C(0x1E1A1E)); c.rect(dx + 4 * s, dt + 8 * s, 10 * s, 2 * s, C(0xC03030))
                c.rect(dx + 8 * s, dt + 12 * s, 2 * s, 4 * s, C(0xE8E0D0)); c.rect(dx + 7 * s, dt + 13 * s, 4 * s, 2 * s, C(0xE8E0D0))
            } else {   // Alex's: a dreamcatcher hanging on its hook
                c.circle(dx + 9 * s, dt + 9 * s, 4 * s, C(0xC8A870)); c.circle(dx + 9 * s, dt + 9 * s, 3 * s, C(0x7A5A38))
                c.rect(dx + 7 * s, dt + 9 * s, 4 * s, max(1, s / 2), C(0xC8A870)); c.rect(dx + 9 * s, dt + 7 * s, max(1, s / 2), 4 * s, C(0xC8A870))
                for u in [-3, 0, 3] { c.rect(dx + (9 + u) * s, dt + 13 * s, s, 4 * s, C(0xE8E0D0)) }
            }
        }
        // The hall table and its lamp, and a framed sampler.
        let tx = c.w * 72 / 100
        c.rect(tx, floorY - 22 * s, 16 * s, 2 * s, C(0x6A4A30)); c.rect(tx + s, floorY - 20 * s, 2 * s, 12 * s, C(0x4A3220)); c.rect(tx + 13 * s, floorY - 20 * s, 2 * s, 12 * s, C(0x4A3220))
        c.rect(tx + 6 * s, floorY - 28 * s, 4 * s, 6 * s, C(0x8A6A3A)); c.rect(tx + 3 * s, floorY - 34 * s, 10 * s, 6 * s, C(0xF0D890))
        for r in stride(from: 18 * s, to: 4 * s, by: -4 * s) { c.circle(tx + 8 * s, floorY - 31 * s, r, C(0xFFE8A8, 0.05)) }
        c.rect(tx + 2 * s, floorY - 52 * s, 12 * s, 12 * s, C(0x6A4A30)); c.rect(tx + 3 * s, floorY - 51 * s, 10 * s, 10 * s, C(0xF0E8D8))
        c.rect(tx + 5 * s, floorY - 48 * s, 6 * s, 4 * s, C(0xC04A4A)); c.rect(tx + 7 * s, floorY - 49 * s, 2 * s, 6 * s, C(0xC04A4A))
        // The stairwell's banister along the landing's edge, over the hall.
        c.rect(x1 - 6 * s, floorY - 22 * s, c.w - x1 + 6 * s, 2 * s, C(0x5A3A24)); c.rect(x1 - 6 * s, floorY - 22 * s, c.w - x1 + 6 * s, max(1, s / 2), C(0x8A6040))
        for x in stride(from: x1 - 4 * s, to: c.w, by: 4 * s) { c.rect(x, floorY - 20 * s, s, 16 * s, C(0xF0EADA)) }
        c.rect(x1 - 8 * s, floorY - 26 * s, 4 * s, 22 * s, C(0x5A3A24)); c.rect(x1 - 8 * s, floorY - 28 * s, 4 * s, 2 * s, C(0x8A6040))
        c.rect(x1, f.attic, c.w - x1, floorY - 22 * s - f.attic, C(0x7A8894))
        // The landing's ceiling and the attic's floor over it.
        c.rect(0, f.attic - 4 * s, c.w, 4 * s, C(0x6A4A30)); c.rect(0, f.attic - 4 * s, c.w, s, C(0x8A6A44))
        huntSiouxFallsAttic(c, g)
    }

    /// The attic under the gable: bare rafters sloping up to the ridge, the dark of the roof beyond them, a gable wall
    /// of odd old boards, a round window with the afternoon sky in it, snowshoes, Christmas lights, a lantern, an old
    /// coat and a toboggan, cardboard boxes, an old steamer trunk and a rocking chair under a sheet.
    private static func huntSiouxFallsAttic(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g)
        let base = f.attic - 4 * s, mx = c.w / 2, peak = 2 * s
        let wood = C(0x8A6A44), woodD = C(0x5A4028), woodL = C(0xA88A5A)
        // The gable wall: rough boards, each its own shade of old pine, butt joints staggered, knots and nail heads,
        // darker up towards the ridge where the light doesn't reach.
        let boards = [C(0x9A8462), C(0x8E7858), C(0xA48C68), C(0x86704E), C(0x96805C)]
        for (k, x) in stride(from: 0, to: c.w, by: 8 * s).enumerated() {
            c.rect(x, 0, 8 * s, base, boards[Int(noise(k + 1700) * 5) % 5])
            c.rect(x, 0, max(1, s / 2), base, C(0x6A5A40))
            let joint = Int(noise(k + 1710) * Double(base))
            c.rect(x, joint, 8 * s, max(1, s / 2), C(0x6A5A40))
            if noise(k + 1720) > 0.55 {
                let ky = Int(noise(k + 1730) * Double(base))
                c.ellipse(x + 4 * s, ky, 2 * s, s, C(0x6A5034)); c.px(x + 4 * s, ky, C(0x4A3624))
            }
            for ny in stride(from: base - 3 * s, to: 0, by: -40 * s) { c.rect(x + 2 * s, ny, max(1, s / 2), max(1, s / 2), C(0x3A3028)) }
        }
        c.gradient(0, base, C(0x1E140C, 0.4), C(0x1E140C, 0), bands: 6)
        for y in 0..<base {   // the roof's underside beyond the slopes
            let half = y <= peak ? 0 : (c.w / 2 + 8 * s) * (y - peak) / max(1, base - peak)
            c.rect(0, y, max(0, mx - half), 1, C(0x3A2C22)); c.rect(mx + half, y, max(0, c.w - mx - half), 1, C(0x3A2C22))
        }
        for k in [-1, 1] {
            huntP6Stick(c, mx, peak, mx + k * (c.w / 2 + 8 * s), base, woodD, Double(s) * 2.4)
            huntP6Stick(c, mx, peak + 2 * s, mx + k * (c.w / 2 + 8 * s), base + 2 * s, woodL, Double(s) * 0.6)
        }
        c.rect(mx - 3 * s, peak, 6 * s, base - peak, wood); c.rect(mx - 3 * s, peak, s, base - peak, woodL)
        let tie = peak + (base - peak) * 55 / 100
        c.rect(0, tie, c.w, 4 * s, wood); c.rect(0, tie, c.w, s, woodL); c.rect(0, tie + 3 * s, c.w, s, woodD)
        // On the boards: a pair of old snowshoes crossed on a nail, a string of Christmas lights looped along the tie
        // beam (unlit), a storm lantern hanging from it, an old army coat on a hook, and a wooden sled leaning on the wall.
        let shoe = (x: mx - 66 * s, y: tie + 26 * s)
        for k in [-1, 1] {
            c.ellipse(shoe.x + k * 4 * s, shoe.y, 4 * s, 9 * s, C(0x5A3A22)); c.ellipse(shoe.x + k * 4 * s, shoe.y, 3 * s, 8 * s, C(0x9A8462))
            for l in stride(from: -6, to: 7, by: 3) { c.rect(shoe.x + k * 4 * s - 3 * s, shoe.y + l * s, 6 * s, max(1, s / 2), C(0x6A5034)) }
        }
        c.rect(shoe.x - s, shoe.y - 10 * s, 2 * s, 2 * s, C(0x3A3028))
        for (k, x) in stride(from: mx - 120 * s, to: mx + 120 * s, by: 6 * s).enumerated() {
            let sag = Int(sin(Double(k % 5) / 4 * .pi) * Double(3 * s))
            c.rect(x, tie + 4 * s + sag, 6 * s, max(1, s / 2), C(0x2A3A22))
            c.rect(x + 3 * s, tie + 5 * s + sag, s, 2 * s, [C(0xA83A30), C(0x3A7A3A), C(0xC8A040), C(0x3A5A9A)][k % 4])
        }
        let ln = (x: mx + 34 * s, y: tie + 4 * s)
        c.rect(ln.x, ln.y, max(1, s / 2), 6 * s, C(0x2A2420)); c.rect(ln.x - 3 * s, ln.y + 6 * s, 7 * s, s, C(0x6A2A1E))
        c.rect(ln.x - 2 * s, ln.y + 7 * s, 5 * s, 6 * s, C(0xC8BC90, 0.8)); c.rect(ln.x - 2 * s, ln.y + 7 * s, max(1, s / 2), 6 * s, C(0x6A2A1E))
        c.rect(ln.x + 2 * s, ln.y + 7 * s, max(1, s / 2), 6 * s, C(0x6A2A1E)); c.rect(ln.x - 3 * s, ln.y + 13 * s, 7 * s, s, C(0x6A2A1E))
        let coat = (x: mx + 60 * s, y: tie + 10 * s)
        c.rect(coat.x, coat.y - 2 * s, s, 2 * s, C(0x3A3028))
        c.rect(coat.x - 6 * s, coat.y, 13 * s, 18 * s, C(0x4E5236)); c.rect(coat.x - 6 * s, coat.y, 2 * s, 18 * s, C(0x62664A))
        c.rect(coat.x - 8 * s, coat.y + s, 3 * s, 14 * s, C(0x44482E)); c.rect(coat.x + 6 * s, coat.y + s, 3 * s, 14 * s, C(0x3A3E28))
        c.rect(coat.x, coat.y + 2 * s, max(1, s / 2), 16 * s, C(0x34381F)); c.rect(coat.x - 4 * s, coat.y + 8 * s, 3 * s, 2 * s, C(0x3A3E28))
        let sled = mx + 142 * s
        // (the sled: an old wooden toboggan stood on its end, its slats running up it, the curl at the top, a red tow rope)
        for k in 0..<4 { huntP6Stick(c, sled + k * 2 * s, base - s, sled + 6 * s + k * 2 * s, base - 28 * s, k % 2 == 0 ? C(0xA86A38) : C(0x8A5430), Double(s) * 0.8) }
        for k in 1..<4 { huntP6Stick(c, sled + k * 3 * s / 2, base - k * 7 * s, sled + 8 * s + k * 3 * s / 2, base - k * 7 * s, C(0x5A3A22), Double(s) * 0.4) }
        c.circle(sled + 10 * s, base - 30 * s, 4 * s, C(0x8A5430)); c.circle(sled + 10 * s, base - 30 * s, 2 * s, C(0x9A8462))
        huntP6Stick(c, sled + 13 * s, base - 30 * s, sled + 16 * s, base - 6 * s, C(0xA83A30), Double(s) * 0.5)
        // The round window, sky and a cloud in it, a cross of glazing bars.
        let wx = mx, wy = peak + (base - peak) * 30 / 100, wr = 10 * s
        c.circle(wx, wy, wr + 2 * s, C(0xF0EADA)); c.circle(wx, wy, wr, C(0x8ABCE0)); c.ellipse(wx - 3 * s, wy + 2 * s, 5 * s, 2 * s, C(0xF4F8FC))
        c.rect(wx - wr, wy - s / 2, 2 * wr, max(1, s), C(0xF0EADA)); c.rect(wx - s / 2, wy - wr, max(1, s), 2 * wr, C(0xF0EADA))
        for r in stride(from: 40 * s, to: 12 * s, by: -7 * s) { c.ellipse(wx, base - 4 * s, r, r / 3, C(0xFFF0C8, 0.04)) }
        // The boxes, the trunk and the sheeted rocking chair on the attic floor.
        for (k, (xp, bw, bh)) in [(18, 18, 12), (22, 14, 9), (70, 20, 14), (76, 12, 8)].enumerated() {
            let bx = c.w * xp / 100, by = base - bh * s - (k % 2 == 1 ? 12 * s : 0)
            c.rect(bx, by, bw * s, bh * s, C(0xB08A58)); c.rect(bx, by, bw * s, s, C(0xC8A472)); c.rect(bx + (bw - 2) * s, by, 2 * s, bh * s, C(0x7A5E38))
            c.rect(bx + bw * s / 2 - s, by, 2 * s, bh * s, C(0xC8B890, 0.8))
        }
        let tk = c.w * 32 / 100
        c.rect(tk, base - 12 * s, 24 * s, 12 * s, C(0x3A4A5A)); c.rect(tk, base - 14 * s, 24 * s, 3 * s, C(0x4A5A6A))
        for x in [tk + 2 * s, tk + 20 * s] { c.rect(x, base - 14 * s, 2 * s, 14 * s, C(0xA88A48)) }
        c.rect(tk + 11 * s, base - 10 * s, 3 * s, 3 * s, C(0xC8A858))
        let rc = c.w * 58 / 100
        c.ellipse(rc + 6 * s, base - 11 * s, 9 * s, 10 * s, C(0xE8E4DA)); c.rect(rc - 3 * s, base - 11 * s, 18 * s, 10 * s, C(0xE8E4DA))
        c.rect(rc + 11 * s, base - 20 * s, 4 * s, 18 * s, C(0xD0CCC2))
        huntP6Stick(c, rc - 6 * s, base - s, rc + 18 * s, base + s, C(0x5A4028), Double(s) * 0.8)
    }

    /// The kitchen's life: the clock's hands going round, its red second hand ticking, and the gingham curtains
    /// stirring in the breeze from the open window.
    static func huntSiouxFallsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntSiouxFallsFrame(c, g)
        let k = f.clock
        let sec = Double(Int(t) % 60) / 60 * 2 * .pi - .pi / 2
        let mins = (t / 600).truncatingRemainder(dividingBy: 1) * 2 * .pi - .pi / 2
        huntP6Stick(c, k.x, k.y, k.x + Int(cos(.pi * 1.6) * Double(3 * s)), k.y + Int(sin(.pi * 1.6) * Double(3 * s)), C(0x1E1E1E), Double(s) * 0.6)
        huntP6Stick(c, k.x, k.y, k.x + Int(cos(mins) * Double(5 * s)), k.y + Int(sin(mins) * Double(5 * s)), C(0x2A2A2A), Double(s) * 0.5)
        huntP6Stick(c, k.x, k.y, k.x + Int(cos(sec) * Double(5 * s)), k.y + Int(sin(sec) * Double(5 * s)), C(0xC0342A), Double(s) * 0.35)
        c.rect(k.x, k.y, max(1, s), max(1, s), C(0x1E1E1E))
        // The curtains: gingham panels either side of the window, their inner edges stirring.
        let w = f.window, ww = 40 * s
        for side in [0, 1] {
            for y in 0..<(28 * s) {
                let blow = sin(t * 1.3 + Double(side) * 2 - Double(y) * 0.15 / Double(s)) * Double(y) / Double(28 * s)
                let pull = side == 0 ? Int((blow * Double(3 * s) + Double(2 * s)).rounded()) : Int((-blow * Double(3 * s) + Double(2 * s)).rounded())
                let width = 8 * s + pull
                let x0 = side == 0 ? w.x - 8 * s : w.x + ww + 8 * s - width
                let row = (y / (2 * s)) % 2
                for x in stride(from: x0, to: x0 + width, by: 2 * s) {
                    let col = ((x - x0) / (2 * s) + row) % 2
                    let tone = row == 0 ? (col == 0 ? C(0xC0342A) : C(0xF0E4D8)) : (col == 0 ? C(0xE08A80) : C(0xF0E4D8))
                    c.rect(x, w.y + y, min(2 * s, x0 + width - x), 1, tone)
                }
                c.rect(side == 0 ? x0 + width - s : x0, w.y + y, max(1, s), 1, C(0x8A2A20, 0.6))
            }
        }
    }
}
