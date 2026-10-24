import Foundation

// Back from Hell: Superclawdtural's compaction. The Winclawdsters never stay dead. When the session of Dean, Sam,
// Clawdstiel, Bobby or Jack has its context compacted, they're dragged down by hellhound claws and sink in a red glow;
// a moment later a fist punches up through the ground, they climb out and dust themselves off, and the caption reads
// BACK FROM HELL. Same session, same face. It runs on the engine's missing-time clock (`SessionRecord.abducted`,
// `missingTimeLength`), as The Clawd Files' missing time and Stranger Clawds' Upside Down do.
//
// Moment by moment: they shiver as three sets of glowing red claw marks rake across the ground round their feet, one
// after another (hellhounds nobody can see). A red pit opens under them, a hot rim with a dark heart and a flickering
// red glow standing over it, lighting their legs, embers rising, and they're yanked down into it in four jerks, the
// ground cutting them off at the feet, until even the top of the head is gone. The pit closes to a smouldering crack
// and goes dark. A plain wooden cross is planted, a mound of earth heaves up in front of it, and a Clawd-orange fist
// on an arm in their own sleeve punches up through the mound in a spray of clods. They climb out in two heaves, lumps
// of dirt on them, the cross tips over behind and fades where it lands, the mound flattens, and they shake themselves
// off in a puff of dust while BACK FROM HELL types itself out over the head.
//
// The sprite isn't clipped at the ground by the engine, so the sinking is done in `touch`: their picture is shifted
// down and everything under the ground row cut away, and the mound is drawn on their own picture, in front, so it
// hides the cut edge as they climb out (and gets the app's outline, so it reads on a dark desktop). `lift` stays 0.

/// The first row under the feet, on the sprite (legs run y 38…43).
private let ground = 44
/// The fist's column, a little in front of the body's middle.
private let fistX = 33

private let rakeHot = C(0xFFC060), rakeRed = C(0xFF3B1F), rakeGlow = C(0xFF3020, 0.2)
private let rimHot = C(0xFFB050), rim = C(0xF0502A), pitRed = C(0xA01812), pitDeep = C(0x5E0A10)
private let ember = C(0xFF8A30), emberHot = C(0xFFD070)
private let dirt = C(0x6E4A30), dirtLit = C(0xA87A50), dirtDark = C(0x4A3020), pebble = C(0xB8A890)
private let wood = C(0x7A5434), woodLit = C(0xC89A68)
private let dust = C(0xD8C4A0), dustLit = C(0xF2E6CC)
private let fistLit = C(0xEC9474)

/// Where it is, `k` 0…1 through it.
struct HuntBackFromHell: CompactionLook {
    let k: Double
    /// How far each of the three claw rakes has been scored across the ground, 0…1, and how bright they still glow.
    let rakes: [Double]
    let rakeGlow: Double
    /// How wide the pit under them is open (0…1), and the smouldering crack it closes to.
    let pit: Double
    let smoulder: Double
    /// How much of them is under the ground, 0…1 of their height (1: all gone), and the little hop (sprite pixels up)
    /// once they're out.
    let sunk: Double
    let hop: Double
    /// Shivering, struggling or shaking the dirt off: a pixel side to side.
    let jitter: Bool
    /// The grave: the cross (shown, and how far it's tipped over, degrees), the mound (0…1 of its height), the fist
    /// (0…1 up through the mound) and how long since it punched through (seconds), for the clods. Once it's down, the
    /// cross fades where it lies (`crossFade` 1…0).
    let cross: Bool
    let tip: Double
    let crossFade: Double
    let mound: Double
    let fist: Double
    let punched: Double?
    /// Lumps of dirt on them (0…1, dropping off as they shake), and the puff of dust (0…1 through it).
    let specks: Double
    let puff: Double
    let caption: String?

    init(k: Double) {
        func ramp(_ x: Double, _ a: Double, _ b: Double) -> Double { max(0, min(1, (x - a) / (b - a))) }
        func ease(_ x: Double) -> Double { x * x * (3 - 2 * x) }
        self.k = k
        // Three rakes, one after another: to the left of them, to the right, then right under them.
        rakes = [0.02, 0.07, 0.12].map { ramp(k, $0, $0 + 0.03) }
        rakeGlow = 1 - ramp(k, 0.38, 0.44)
        pit = ease(ramp(k, 0.15, 0.2)) * (1 - ramp(k, 0.38, 0.44))
        smoulder = ramp(k, 0.38, 0.42) * (1 - ramp(k, 0.5, 0.56))
        // Dragged down in four jerks, a struggle between them; out again in two heaves and a little hop.
        if k < 0.5 {
            let yanks: [(Double, Double, Double)] = [(0.2, 0.22, 0.12), (0.25, 0.27, 0.16), (0.3, 0.32, 0.24), (0.34, 0.37, 0.48)]
            sunk = yanks.reduce(0) { $0 + ease(ramp(k, $1.0, $1.1)) * $1.2 }
        } else {
            sunk = 1 - ease(ramp(k, 0.63, 0.68)) * 0.5 - ease(ramp(k, 0.72, 0.8)) * 0.5
        }
        hop = k > 0.8 && k < 0.83 ? 2 * sin(ramp(k, 0.8, 0.83) * .pi) : 0
        let shiver = k > 0.04 && k < 0.37
        let shake = k > 0.84 && k < 0.9
        jitter = shiver || shake
        // The grave: the cross planted, the earth heaving up, the punch, the cross tipping over once they're out.
        cross = k > 0.46 && k < 0.93
        let fall = ramp(k, 0.8, 0.83)
        tip = fall * fall * 90                         // slow to start, then it drops flat
        crossFade = 1 - ramp(k, 0.86, 0.93)
        mound = ease(ramp(k, 0.48, 0.56)) * (1 - ease(ramp(k, 0.82, 0.9)))
        fist = k < 0.665 ? ease(ramp(k, 0.58, 0.6)) : 0
        punched = k >= 0.58 && k < 0.7 ? (k - 0.58) * missingTimeLength : nil
        specks = k > 0.64 ? 1 - ramp(k, 0.84, 0.9) : 0
        puff = k > 0.84 && k < 0.97 ? ramp(k, 0.84, 0.97) : 0
        let full = "BACK FROM HELL"
        if k >= 0.8 {
            let n = min(full.count, Int((k - 0.8) / 0.08 * Double(full.count)) + 1)
            caption = String(full.prefix(n))
        } else {
            caption = nil
        }
    }

    /// The claw marks, the pit and its glow, the crack, the cross, the clods and the dust, behind them.
    func layers(cast: Cast, x: CGFloat, y: CGFloat, lift: CGFloat, scale: CGFloat, facing: CGFloat, t: Double) -> [StageLayer] {
        let fx = PixelCanvas(Sprite.width, Sprite.height)
        huntDrawBackFromHell(fx, self, t: t)
        guard let img = fx.makeImage() else { return [] }
        let w = CGFloat(fx.w) * scale, h = CGFloat(fx.h) * scale
        let mid = CGFloat(Sprite.bodyCenterX)
        let left = facing < 0 ? x - (CGFloat(fx.w) - mid) * scale : x - mid * scale
        return [StageLayer(image: img, rect: CGRect(x: left.rounded(), y: y + lift, width: w, height: h), mirrored: facing < 0)]
    }

    func touch(_ sprite: PixelCanvas, t: Double) { huntBackFromHellTouch(sprite, self, t: t) }
}

/// What's drawn round them, on its own sprite-sized canvas lined up with theirs (facing right).
func huntDrawBackFromHell(_ c: PixelCanvas, _ s: HuntBackFromHell, t: Double) {
    let mid = Int(Sprite.bodyCenterX)

    // The claw marks: three parallel scores slanting across the ground band, glowing red with a hot tip where the
    // claw is, a faint red glow round them.
    if s.rakeGlow > 0 {
        for (i, r) in s.rakes.enumerated() where r > 0 {
            let x0 = [mid - 17, mid + 9, mid - 4][i]
            let len = 6.0 * r
            for j in 0..<3 {
                let ax = Double(x0 + j * 3), ay = Double(ground)
                let bx = ax + len * 0.85, by = ay + len * 0.35     // flat along the ground, 2 rows deep at most
                c.glowLine(ax, ay, bx, by, core: rakeRed, glow: rakeGlow, coreR: 0.5, glowR: 1.4, strength: s.rakeGlow)
                if r < 1 { c.px(Int(bx.rounded()), Int(by.rounded()), rakeHot) }
            }
        }
    }

    // The pit: a red glow standing over it like heat, brightest and hottest just over the hole and flickering, then
    // the hole itself, a hot rim round a dark red heart, flat on the ground (no more than 2 rows under the feet),
    // embers floating up out of it.
    if s.pit > 0 {
        let rx = 13.0 * s.pit, ry = 2.6 * s.pit
        let cy = Double(ground)
        let flicker = 0.85 + 0.15 * sin(t * 23) * sin(t * 7.3)
        for row in 0..<30 {
            let yy = ground - 1 - row, up = Double(row) / 30
            let half = rx * (1 - up * 0.55)
            guard half > 0.5 else { continue }
            for xx in (mid - Int(half))...(mid + Int(half)) {
                let across = abs(Double(xx - mid)) / half
                let a = 0.8 * pow(1 - up, 1.5) * (1 - across * across) * s.pit * flicker
                guard a > 0.02 else { continue }
                c.px(xx, yy, (row < 3 ? C(0xFF8A3A) : row < 9 ? C(0xFF4A22) : C(0xE02A18)).alpha(a))
            }
        }
        for yy in Int(cy - ry - 1)...min(ground + 2, Int(cy + ry + 1)) {
            for xx in (mid - Int(rx) - 1)...(mid + Int(rx) + 1) {
                let u = (Double(xx) - Double(mid)) / max(rx, 0.5), v = (Double(yy) - cy) / max(ry, 0.5)
                let d = u * u + v * v
                guard d <= 1 else { continue }
                let col = d > 0.62 ? (u < -0.3 && v < 0 ? rimHot : rim) : d > 0.3 ? pitRed : pitDeep
                c.px(xx, yy, col)
            }
        }
        for i in 0..<9 {
            let f = frac(t * 0.6 + noise(i * 13 + 5))
            let ex = Double(mid) + (noise(i * 7 + 1) - 0.5) * rx * 1.6 + sin(t * 2 + Double(i)) * 1.2
            let ey = cy - 2 - f * 26
            guard f < 0.85 else { continue }
            c.px(Int(ex.rounded()), Int(ey.rounded()), noise(i * 3) < 0.4 ? emberHot : ember)
        }
    }

    // The crack it closes to: a jagged red line across the ground, specks in it winking out as it goes dark.
    if s.smoulder > 0 {
        for xx in (mid - 9)...(mid + 9) {
            let yy = ground + (noise(xx * 5) < 0.5 ? 0 : 1)
            let on = noise(xx * 11 + Int(t * 6)) < 0.85 * s.smoulder
            if on { c.px(xx, yy, noise(xx * 3 + Int(t * 4)) < 0.25 ? ember : rakeRed) }
        }
    }

    // The cross over the grave, two plain planks behind the mound and to its left, lit down their left edges. Once
    // they're out it tips over backwards, slowly and then all at once, the crossbar turning away from us as it goes
    // (so it never reads as an X), lands flat on the ground and fades there.
    if s.cross, s.crossFade > 0.02 {
        let base = (x: Double(mid - 9), y: Double(ground + 1))
        let a = (-90 - s.tip) * .pi / 180
        func at(_ d: Double, _ side: Double) -> (Double, Double) {
            (base.x + cos(a) * d - sin(a) * side, base.y + sin(a) * d + cos(a) * side)
        }
        func plank(_ p0: (Double, Double), _ p1: (Double, Double)) {
            c.glowLine(p0.0, p0.1, p1.0, p1.1, core: wood.alpha(s.crossFade), glow: C(0, 0), coreR: 0.9, glowR: 1)
            c.glowLine(p0.0 - 0.6, p0.1 - 0.4, p1.0 - 0.6, p1.1 - 0.4, core: woodLit.alpha(s.crossFade), glow: C(0, 0),
                       coreR: 0.35, glowR: 0.4)
        }
        let arm = 4 * max(0.15, pow(cos(s.tip * .pi / 180), 3))
        plank(at(0, 0), at(15, 0))
        plank(at(11, -arm), at(11, arm))
    }

    // Clods thrown up by the fist, falling back to the ground.
    if let p = s.punched {
        for i in 0..<10 {
            let vx = (noise(i * 17 + 2) - 0.5) * 44, vy = 26 + noise(i * 23 + 9) * 26
            let px = Double(fistX) + vx * p, py = Double(ground - 3) - vy * p + 70 * p * p
            guard py < Double(ground) else { continue }
            let col = noise(i * 5) < 0.4 ? dirtLit : dirt
            c.rect(Int(px.rounded()), Int(py.rounded()), noise(i * 31) < 0.4 ? 2 : 1, 1, col)
        }
    }

    // The dust they shake off: little pale puffs bursting out either side of them, drifting outwards and up and
    // shrinking away, and crumbs of dirt dropping to the ground.
    if s.puff > 0 {
        let f = s.puff
        for side in [-1.0, 1.0] {
            for i in 0..<4 {
                let n = i * 7 + (side < 0 ? 0 : 3)
                let start = noise(n + 1) * 0.25
                let g = max(0, min(1, (f - start) / 0.6))
                guard g > 0, g < 1 else { continue }
                let cx = Double(mid) + side * (9 + noise(n + 2) * 4 + 9 * g)
                let cy = Double(ground) - 5 - noise(n + 4) * 12 - 4 * g
                let r = g < 0.25 ? 1 : g < 0.7 ? 2 : 1
                c.circle(Int(cx.rounded()), Int(cy.rounded()), r, dust)
                if r > 1 { c.px(Int(cx.rounded()) - 1, Int(cy.rounded()) - 1, dustLit) }
            }
            for i in 0..<4 {
                let px = Double(mid) + side * (8 + noise(i * 13 + 5) * 6 + 4 * f)
                let py = Double(ground) - 12 + noise(i * 29 + 4) * 5 + 40 * f * f
                guard py < Double(ground) else { continue }
                c.px(Int(px.rounded()), Int(py.rounded()), noise(i) < 0.5 ? dirt : dirtLit)
            }
        }
    }
}

/// Their own picture: shaking, sunk into the ground (cut off at the ground row), red light from the pit on their legs;
/// on the way back, the fist, lumps of dirt, and the mound in front of them. Drawn on the sprite before the app adds
/// its outline, so the mound and the fist get outlined too.
func huntBackFromHellTouch(_ c: PixelCanvas, _ s: HuntBackFromHell, t: Double) {
    let saved = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = saved.0; c.oy = saved.1; c.baseY = saved.2 }
    let g = ground + (c.h - Sprite.height)
    func solid(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < c.w && y < c.h && c.buf[(y * c.w + x) * 4 + 3] == 255 }

    // Their sleeve, for the arm that punches up: the commonest colour on the arm at their back (x 14…17) that isn't
    // Clawd's own orange (the engine doesn't tell `touch` who it is, so it's read off their picture before it sinks).
    var sleeve = clawdOrange
    if s.fist > 0 {
        var counts: [UInt32: Int] = [:]
        for y in 31...36 {
            for x in 14...17 where solid(x, y) {
                let i = (y * c.w + x) * 4
                let hex = UInt32(c.buf[i]) << 16 | UInt32(c.buf[i + 1]) << 8 | UInt32(c.buf[i + 2])
                if hex == 0xD97757 || hex == 0xB85F40 || hex == 0xEC9474 { continue }   // Clawd's orange, shade, lit
                counts[hex, default: 0] += 1
            }
        }
        if let best = counts.max(by: { $0.value < $1.value || ($0.value == $1.value && $0.key < $1.key) }) {
            sleeve = C(best.key)
        }
    }

    if s.jitter { c.shift(dx: Int(t * 24) % 2 == 0 ? 1 : -1, dy: 0) }
    // Down into the ground: moved down, and everything that's gone under the ground row cut away (shifted off the
    // bottom and back).
    let top = (0..<g).first { y in (0..<c.w).contains { c.isDrawn($0, y) } } ?? g
    let d = s.sunk > 0 ? Int((s.sunk * Double(g - top + 1)).rounded(.up)) : -Int(s.hop.rounded())
    if d > 0 {
        let under = c.h - g
        c.shift(dx: 0, dy: d + under)
        c.shift(dx: 0, dy: -under)
    } else if d < 0 {
        c.shift(dx: 0, dy: d)
    }

    // The pit's red light on whatever's still above it, strongest just over the ground, flickering with the glow.
    if s.pit > 0.05 {
        let flicker = 0.85 + 0.15 * sin(t * 23) * sin(t * 7.3)
        for y in max(0, g - 10)..<g {
            let a = 0.6 * s.pit * flicker * Double(y - (g - 11)) / 11
            for x in 0..<c.w where solid(x, y) { c.px(x, y, (y >= g - 2 ? C(0xFF6A30) : C(0xFF3A20)).alpha(a)) }
        }
    }

    // Clods of dirt caught on them: little lumps (a lit top over a darker underside) along the tops of things and a
    // few smears lower down, dropping off as they shake.
    if s.specks > 0 {
        var x = 0
        while x < c.w {
            defer { x += 1 }
            guard let top = (0..<g).first(where: { solid(x, $0) }) else { continue }
            if noise(x * 19 + 3) < 0.22 * s.specks, solid(x + 1, top), top > 0 {
                c.rect(x, top - 1, 2, 1, dirtLit); c.rect(x, top, 2, 1, dirt)
                x += 2
                continue
            }
            guard top + 3 < g else { continue }
            for y in (top + 3)..<(g - 1) where solid(x, y) && solid(x + 1, y) && noise(x * 7 + y * 31) < 0.02 * s.specks {
                c.rect(x, y, 2, 1, dirt); c.px(x, y + 1, dirtDark)
            }
        }
    }

    // The fist, punched up through the mound: a blocky Clawd-orange fist, lit on its left, a dark line between the
    // knuckles, on a forearm in their own sleeve with a cuff at the wrist; it wiggles a little once it's out.
    if s.fist > 0 {
        let wig = s.fist >= 1 && Int(t * 8) % 2 == 0 ? 1 : 0
        let top = g - 1 - Int((s.fist * 11).rounded()) - wig
        let cuff = lerp(sleeve, C(0xFFFFFF), 0.3), sleeveShade = lerp(sleeve, C(0x000000), 0.35)
        c.rect(fistX - 2, top + 4, 4, g + 2 - (top + 4), sleeve)
        c.rect(fistX - 2, top + 5, 1, g + 2 - (top + 5), lerp(sleeve, C(0xFFFFFF), 0.15))
        c.rect(fistX + 1, top + 4, 1, g + 2 - (top + 4), sleeveShade)
        c.rect(fistX - 2, top + 4, 4, 1, cuff)
        c.rect(fistX - 2, top, 5, 4, clawdOrange)
        c.rect(fistX - 2, top, 1, 4, fistLit)
        c.rect(fistX + 2, top + 1, 1, 3, clawdShade)
        c.rect(fistX - 2, top, 5, 1, fistLit)
        c.px(fistX, top + 1, clawdShade)
        c.px(fistX, top + 2, clawdShade)
    }

    // The mound of fresh earth over the grave, in front of them: lit along its top and down its left, shaded on its
    // right, a few pale stones in it. It heaves a little before the fist comes through.
    if s.mound > 0 {
        let mid = Int(Sprite.bodyCenterX)
        let heave = s.fist == 0 && s.mound >= 1 && s.k < 0.58 && Int(t * 10) % 2 == 0 ? 1 : 0
        let hm = 5.0 * s.mound + Double(heave)
        for x in (mid - 16)...(mid + 16) {
            let u = Double(x - mid) / 16.5
            let top = g - Int((hm * (1 - u * u)).rounded())
            guard top < g + 2 else { continue }
            for y in top..<(g + 2) {
                var col = dirt
                if y == top { col = dirtLit } else if u > 0.45 || y == g + 1 { col = dirtDark } else if u < -0.45 && y == top + 1 { col = dirtLit }
                if y > top, noise(x * 13 + y * 7) < 0.06 { col = pebble }
                c.px(x, y, col)
            }
        }
    }
}
