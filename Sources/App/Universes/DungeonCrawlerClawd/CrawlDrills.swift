import Foundation

// Dungeon Crawler Clawd's own solo practice (`UniverseModule.drills`): Carl punching a training dummy and finishing
// with a Smush, Princess Donut firing Magic Missiles at a target, Katia swelling into her combat form for a few air
// punches and shrinking back, and Bautista and Tran at sword practice. Nobody floats cross-legged in meditation here
// (`Meditation(who: .never)`).
//
// These are practice, not the signature moves again: Katia's signature swells and shrinks once, so here it's a set,
// held in between for punches at the air. Bautista and Tran spar together in the books, but a drill draws one
// character alone in its own frame, so each has a partner that stands in: Bautista a wooden sword post, Tran a
// quintain whose sandbag swings round at him when he hits its shield.

let crawlBespokeDrills: [Cast: BespokeDrill] = [
    .hero(CrawlHero.carl): drawDummyDrill,
    .hero(CrawlHero.donut): drawMissileDrill,
    .hero(CrawlHero.katia): drawSwellDrill,
    .hero(CrawlHero.bautista): drawPostDrill,
    .hero(CrawlHero.tran): drawQuintainDrill,
]

// MARK: - Shared bits

/// Eased 0…1.
private func ease(_ k: Double) -> Double {
    let u = max(0, min(1, k))
    return u * u * (3 - 2 * u)
}

/// A value keyed through a loop: `keys` are (time, value) pairs, eased from one to the next; past the last it eases
/// back to the first at `period`.
private func keyed(_ e: Double, period: Double, _ keys: [(Double, Double)]) -> Double {
    let u = e.truncatingRemainder(dividingBy: period)
    for i in 0..<keys.count {
        let a = keys[i], b = i + 1 < keys.count ? keys[i + 1] : (period, keys[0].1)
        if u >= a.0 && u < b.0 { return a.1 + (b.1 - a.1) * ease((u - a.0) / max(0.001, b.0 - a.0)) }
    }
    return keys[0].1
}

/// A solid line from one point to another, `r` from its centre.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.6) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// A little puff of dust on the ground at `x`, `k` 0…1 through it.
private func dustPuff(_ c: PixelCanvas, x: Double, y: Double = 43, k: Double, spread: Double = 4) {
    guard k >= 0, k < 1 else { return }
    for (dx, dy) in [(-1.0, 0.0), (1.0, 0.0), (-0.6, -1.0), (0.6, -1.0)] {
        let px = x + dx * spread * (0.5 + k), py = y + dy * (1 + 2 * k)
        c.glowLine(px, py, px, py, core: C(0xE8DCC0, 0.75 * (1 - k)), glow: C(0xE8DCC0, 0), coreR: 0.7, glowR: 0.8)
    }
}

/// The burst of a blow landing at (`x`, `y`), `k` 0…1 through it: a solid four-pointed flash that opens out into a
/// ring of sparks and fades. `hot` is the sparks' colour, `core` the flash's.
private func hitBurst(_ c: PixelCanvas, x: Int, y: Int, k: Double, core: Px, hot: Px) {
    guard k >= 0, k < 1 else { return }
    if k < 0.35 {
        c.pattern(x - 3, y - 3, ["...h...", "...c...", "..hch..", "hcccccch", "..hch..", "...c...", "...h..."],
                  ["c": core, "h": hot])
    }
    let r = 2 + k * 4
    for i in 0..<6 {
        let a = Double(i) * 60 + 30
        let q = crawlReach((Double(x) + 0.5, Double(y) + 0.5), a, r)
        c.px(Int(q.x.rounded(.down)), Int(q.y.rounded(.down)), (i % 2 == 0 ? core : hot).alpha(1 - k))
    }
}

// MARK: - Carl

/// Carl at the training dummy: a straw-stuffed sackcloth dummy on a post in front of him, a red and white target
/// painted on its chest. Three punches with the War Gauntlet, each landing with a little burst and rocking the dummy
/// back on its post; then the Smush: he springs up and comes down on all four feet, the ground shakes, the dummy
/// rattles, dust puffs up round his feet and its base, and the System's blue box pops up over him: SMUSH!
private func drawDummyDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 4.2
    let working = r > 0.6
    let u = working ? (d.e - 0.5).truncatingRemainder(dividingBy: period) : -1
    // The punches: (when it lands, its angle). Each is out from 0.1 s before it lands to 0.18 s after.
    let punches: [(Double, Double)] = [(0.35, -22), (0.85, -38), (1.3, -14)]
    var melee: Double?, lunge = 0, rock = 0.0
    for (at, a) in punches {
        if u > at - 0.1 && u < at + 0.18 { melee = a; lunge = u > at - 0.04 ? 1 : 0 }
        if u >= at && u < at + 0.6 {
            let k = (u - at) / 0.6
            rock += 7 * sin(k * .pi * 2.5) * (1 - k)
        }
    }
    // The Smush: up from 2.0, held at the top, slammed down at 2.62.
    let slam = 2.62
    var hop = 0.0
    if u > 2.0 && u < 2.45 { hop = -7 * ease((u - 2.0) / 0.45) } else if u >= 2.45 && u < 2.52 { hop = -7 } else if u >= 2.52 && u < slam {
        hop = -7 * (1 - pow((u - 2.52) / (slam - 2.52), 2))
    }
    let since = u >= slam ? u - slam : -1
    let shake = since >= 0 && since < 0.5 ? (1 - since / 0.5) : 0
    let jitter = shake > 0 ? (Int(since * 30) % 2 == 0 ? 1 : -1) : 0
    if shake > 0 { rock += 4 * shake * Double(jitter) }

    // The dummy, drawn on its own and rocked about the foot of its post.
    if r > 0.15 {
        let dummy = PixelCanvas(c.w, c.h)
        let sack = C(0xC8B080), sackD = C(0x9A8458), sackL = C(0xE0CCA0), straw = C(0xF0D060), strawD = C(0xC8A030)
        let wood = C(0x8A5E34), woodD = C(0x5E3E20), rope = C(0x6A5030)
        let paint = C(0xD83A32), paintL = C(0xF4EEE0)
        // The post and its two crossed feet.
        dummy.rect(53, 36, 2, 7, wood); dummy.rect(54, 36, 1, 7, woodD)
        dummy.rect(49, 43, 10, 1, woodD); dummy.rect(50, 42, 8, 1, wood)
        // The arms: a stick through the shoulders, straw sticking out of its ends.
        dummy.rect(46, 24, 16, 2, wood); dummy.rect(46, 25, 16, 1, woodD)
        dummy.px(45, 23, straw); dummy.px(45, 25, strawD); dummy.px(62, 23, straw); dummy.px(62, 26, strawD)
        // The body: a stuffed sack, lit on the left, tied off at the waist, straw poking out at the bottom.
        dummy.rect(49, 22, 10, 14, sack)
        dummy.rect(49, 22, 1, 14, sackL); dummy.rect(58, 22, 1, 14, sackD); dummy.rect(49, 35, 10, 1, sackD)
        for (x, y) in [(51, 26), (56, 31), (52, 33)] { dummy.px(x, y, sackD) }   // the stitching
        dummy.rect(49, 34, 10, 1, rope)
        for x in [50, 52, 55, 57] { dummy.px(x, 36, x % 2 == 0 ? straw : strawD) }
        // The head: a smaller sack tied off at the neck, a tuft of straw on top.
        dummy.rect(50, 15, 8, 6, sack); dummy.rect(50, 15, 1, 6, sackL); dummy.rect(57, 15, 1, 6, sackD)
        dummy.rect(51, 21, 6, 1, rope)
        dummy.px(52, 14, straw); dummy.px(54, 13, straw); dummy.px(55, 14, strawD)
        dummy.px(51, 17, C(0x3A2A1A)); dummy.rect(51, 19, 2, 1, sackD)          // a stitched eye and mouth
        // The target painted on its chest: red, white, red.
        dummy.pattern(50, 26, [
            ".RRRRR.",
            "RRWWWRR",
            "RWWRWWR",
            "RRWWWRR",
            ".RRRRR.",
        ], ["R": paint, "W": paintL])
        let hopUp = shake > 0.5 ? -1 : 0
        let pivot = (54.0, 43.5)
        c.paste(dummy.rotated(rock, about: pivot, into: c.w, c.h, at: (pivot.0 + Double(jitter), pivot.1 + Double(hopUp))))
    }

    // Carl himself.
    standing(c, who, t: t) { p in
        p.melee = melee
        if let m = melee { p.trail = [m + 6] }
        p.dx = lunge
        p.hop = Int(hop.rounded())
        if hop < -1 { p.breathe = 0 }
    }
    guard working else { return }

    // Each punch's burst, where the fist meets the dummy.
    for (at, a) in punches where u >= at && u < at + 0.3 {
        let fist = crawlReach(Sprite.hand, a, 6)
        hitBurst(c, x: Int(fist.x.rounded()) + 3, y: Int(fist.y.rounded()), k: (u - at) / 0.3,
                 core: C(0xFFFFFF), hot: C(0xFFD040))
    }
    // The Smush's landing: dust up round his feet and the dummy's base, the ground's shock lines, and the box.
    if since >= 0 {
        dustPuff(c, x: 21, k: since / 0.5, spread: 3)
        dustPuff(c, x: 36, k: since / 0.5, spread: 3)
        dustPuff(c, x: 54, k: (since - 0.08) / 0.5, spread: 5)
        if since < 0.2 {
            let a = 1 - since / 0.2
            for x in [12, 14, 42, 44] { c.px(x, 41 - (x % 4 == 0 ? 1 : 0), C(0xFFF2C8, a)) }
            c.rect(10, 43, 3, 1, C(0xFFF2C8, a * 0.7)); c.rect(43, 43, 3, 1, C(0xFFF2C8, a * 0.7))
        }
        if since < 1.2 {
            let k = since / 1.2
            let a = min(1, (1 - k) * 4), y = 8 - Int(k * 3)
            let text = "SMUSH!", w = crawlTextWidth(text)
            let x = 28 - w / 2
            c.rect(x - 2, y - 2, w + 4, 9, C(0x123A7A, a * 0.9))
            c.rect(x - 2, y - 2, w + 4, 1, C(0x6AA8FF, a))
            crawlText(c, x, y, text, C(0xE8F2FF, a))
        }
    }
}

// MARK: - Princess Donut

/// Princess Donut's target practice: a round target on a stand across from her, and a volley of three Magic Missiles
/// at a time, hot pink streaks that leave her with a spark one after another and weave in on it from above, level and
/// below. Each one lights the target up pink where it lands, and it glows a moment and fades before the next.
private func drawMissileDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 1.8
    let firing = d.e > 0.7 && d.length - d.e > 1.0
    standing(c, who, t: t)
    guard r > 0.15 else { return }

    let pink = C(0xFF3AB0), pinkL = C(0xFFE2F4)
    let cx = 62.5, cy = 29.5
    // How lit the target is: each hit flares it up and it fades over 0.5 s.
    let volley = Int(floor((d.e - 0.7) / period)), u = (d.e - 0.7) - Double(volley) * period
    let flight = 0.32
    var lit = 0.0
    var hits: [(x: Double, y: Double, k: Double)] = []
    if d.e > 0.7 {
        for v in [volley - 1, volley] where v >= 0 {
            for i in 0..<3 {
                let shot = 0.7 + Double(v) * period + Double(i) * 0.22
                guard shot < d.length - 1.0 else { continue }
                let since = d.e - shot - flight
                if since >= 0 && since < 0.5 {
                    lit = max(lit, 1 - since / 0.5)
                    let hy = cy + Double(i - 1) * 3
                    hits.append((cx - 2, hy, since / 0.5))
                }
            }
        }
    }

    // The target: a stand of two legs, a round boss of straw seen side on with its rings painted in, glowing pink
    // while it's lit.
    let straw = C(0xC8A060), strawD = C(0x8A6A34)
    line(c, 61, 36, 59, 43, strawD, 0.6); line(c, 64, 36, 66, 43, strawD, 0.6)
    let rings: [(Double, Px)] = [(1, C(0xF0ECE0)), (0.72, C(0x3A5CAA)), (0.46, C(0xF0ECE0)), (0.22, C(0xF0C040))]
    for y in 21...38 {
        for x in 58...67 {
            let dx = (Double(x) + 0.5 - cx) / 4.2, dy = (Double(y) + 0.5 - cy) / 8.2
            let dd = sqrt(dx * dx + dy * dy)
            guard dd <= 1 else { continue }
            var col = straw
            for (rr, ring) in rings where dd <= rr { col = ring }
            if dd > 0.86 { col = dd > 0.94 || dx > 0.5 ? strawD : straw }
            if lit > 0 { col = lerp(col, dd < 0.5 ? pinkL : pink, lit * (dd < 0.5 ? 0.8 : 0.55)) }
            c.px(x, y, col)
        }
    }
    if lit > 0.3 {
        // The glow round its rim.
        for y in 21...38 {
            let dy = (Double(y) + 0.5 - cy) / 8.6
            guard abs(dy) < 1 else { continue }
            let half = 4.6 * sqrt(1 - dy * dy)
            c.px(Int((cx - half - 0.5).rounded()), y, pink.alpha(lit * 0.7))
            c.px(Int((cx + half + 0.5).rounded()), y, pink.alpha(lit * 0.5))
        }
    }
    for h in hits { hitBurst(c, x: Int(h.x.rounded()), y: Int(h.y.rounded()), k: h.k, core: pinkL, hot: pink) }

    // The missiles in flight: from her, each curving in on its own line, a short trail of sparkles behind it.
    guard firing || u < 1 else { return }
    let style = who.persona.shot
    let from = (x: 45.0, y: 30.0)
    for i in 0..<3 {
        let shot = 0.7 + Double(volley) * period + Double(i) * 0.22
        guard shot < d.length - 1.0 else { continue }
        let k = (d.e - shot) / flight
        // A pink spark at her paw as each one leaves.
        if k >= 0 && k < 0.35 {
            let a = 1 - k / 0.35
            c.pattern(43, 29, [".p.", "pWp", ".p."], ["p": pink.alpha(a), "W": pinkL.alpha(a)])
        }
        guard k >= 0, k < 1 else { continue }
        let to = (x: cx - 2, y: cy + Double(i - 1) * 3)
        let bow = Double(1 - i) * -7          // the first arcs over, the last dips under
        func at(_ k: Double) -> (x: Double, y: Double) {
            (from.x + (to.x - from.x) * k, from.y + (to.y - from.y) * k + bow * sin(k * .pi))
        }
        let head = at(k), back = at(max(0, k - 0.3))
        drawProjectile(c, style, from: back, head: head, t: t)
        for s in 1...2 {
            let q = at(max(0, k - Double(s) * 0.18))
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), pink.alpha(0.6 / Double(s)))
        }
    }
}

// MARK: - Katia

/// Katia's combat-form set: she swells into her hulking pink form (body, arms and legs thickening, brow knitting,
/// teeth clenched), holds it and throws four punches at the air, a puff of air at the end of each, then shrinks back
/// down to her own size and catches her breath before the next.
private func drawSwellDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 5.4
    let working = r > 0.6
    let u = working ? (d.e - 0.5).truncatingRemainder(dividingBy: period) : -1
    // Her signature's clock does the change: 0.08 → 0.3 is the swell, 0.3 → 0.72 the full form, 0.72 → 0.92 the
    // shrink.
    var s: Double?
    if u >= 0 && u < 0.9 { s = 0.08 + 0.22 * ease(u / 0.9) } else if u >= 0.9 && u < 3.6 { s = 0.5 } else if u >= 3.6 && u < 4.4 {
        s = 0.72 + 0.2 * ease((u - 3.6) / 0.8)
    }
    let punches: [(Double, Double)] = [(1.25, -12), (1.75, -30), (2.25, -6), (2.9, -50)]
    var melee: Double?, trail: [Double] = [], lunge = 0
    for (at, a) in punches where u > at - 0.12 && u < at + 0.2 {
        melee = a; trail = [a + 10, a + 20]; lunge = u > at - 0.05 ? 1 : 0
    }
    standing(c, who, t: t) { p in
        p.signature = s
        p.melee = melee; p.trail = trail; p.dx = lunge
        if s != nil { p.breathe = 0 }
    }
    guard working else { return }
    // The air punched: a little arc of white pushed out in front of the fist.
    for (at, a) in punches where u >= at && u < at + 0.3 {
        let k = (u - at) / 0.3
        let tip = crawlReach(Sprite.hand, a, 10 + k * 4)
        let rad = 2 + k * 2.5
        for j in 0..<5 {
            let q = crawlReach(tip, a + Double(j - 2) * 32, rad)
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), C(0xFFFFFF, 1 - k))
        }
    }
    // Catching her breath after the shrink: a little puff from her mouth now and then.
    if u >= 4.5 {
        let k = frac((u - 4.5) / 0.45)
        if k < 0.6 { c.px(37 + Int(k * 4), 31 - Int(k * 3), C(0xF0F4FF, 0.7 * (1 - k / 0.6))) }
    }
}

// MARK: - Bautista

/// Bautista at the sword post: a thick wooden post in front of him with two pegs sticking out for arms, and his
/// orange-hot blade worked through a set at it: a cut down from overhead, a cut across, a thrust, back on guard.
/// Each blow lands with a spray of embers and leaves a glowing scorch on the wood that cools and fades.
private func drawPostDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 3.0
    let working = r > 0.6
    let e = d.e - 0.5
    let angleKeys: [(Double, Double)] = [(0, -60), (0.35, -125), (0.5, -18), (0.85, -18), (1.15, -70), (1.3, 8),
                                         (1.65, 8), (1.9, -10), (2.0, -4), (2.35, -4), (2.7, -60)]
    let dxKeys: [(Double, Double)] = [(0, 0), (1.85, 0), (2.0, 3), (2.35, 3), (2.7, 0)]
    // When each blow lands, and where on the post.
    let blows: [(at: Double, x: Int, y: Int)] = [(0.5, 50, 24), (1.3, 50, 33), (2.0, 50, 29)]
    let u = working ? e.truncatingRemainder(dividingBy: period) : -1
    let a = working ? keyed(e, period: period, angleKeys) : -60
    var trail: [Double] = []
    if working {
        let p1 = keyed(e - 0.03, period: period, angleKeys), p2 = keyed(e - 0.06, period: period, angleKeys)
        if abs(a - p1) > 5 { trail = [p1, p2] }
    }
    let dx = working ? Int(keyed(e, period: period, dxKeys).rounded()) : 0
    var since: [Double] = blows.map { u >= $0.at ? u - $0.at : u + period - $0.at }
    if !working || e < 0.5 { since = since.map { _ in 9 } }

    // The post: a squared timber on a broad foot, lit on the left, its grain and old notches; two pegs at the front.
    if r > 0.15 {
        let wood = C(0x9A6A3C), woodD = C(0x6A4424), woodL = C(0xC08C58), peg = C(0x7A5230)
        c.rect(51, 16, 5, 27, wood)
        c.rect(51, 16, 1, 27, woodL); c.rect(55, 16, 1, 27, woodD); c.rect(51, 15, 5, 1, woodL)
        for (x, y) in [(53, 20), (52, 27), (54, 31), (53, 38)] { c.px(x, y, woodD) }
        c.rect(48, 43, 11, 1, woodD); c.rect(49, 42, 9, 1, wood)
        c.rect(47, 26, 4, 2, peg); c.rect(47, 27, 4, 1, woodD)
        c.rect(47, 35, 4, 2, peg); c.rect(47, 36, 4, 1, woodD)
        // The scorches: orange-hot where the blade's just been, cooling to a dark char that fades out.
        for (i, b) in blows.enumerated() {
            let s = since[i]
            guard s < 2.4 else { continue }
            let k = s / 2.4
            let col = k < 0.3 ? lerp(C(0xFFE8A8), C(0xFF7A1A), k / 0.3) : lerp(C(0xFF7A1A), C(0x3A2214), (k - 0.3) / 0.4)
            let al = k < 0.7 ? 1 : 1 - (k - 0.7) / 0.3
            c.rect(51, b.y, 3, 1, col.alpha(al)); c.rect(51, b.y + 1, 2, 1, col.alpha(al * 0.7))
            c.px(51, b.y - 1, col.alpha(al * 0.5))
        }
    }

    standing(c, who, t: t) { p in
        p.melee = a; p.trail = trail; p.dx = dx
    }
    guard working else { return }

    // The embers off each blow, flying back toward him and falling.
    for (i, b) in blows.enumerated() where since[i] < 0.5 {
        let k = since[i] / 0.5
        if k < 0.25 { hitBurst(c, x: b.x, y: b.y, k: k / 0.25 * 0.5, core: C(0xFFF2C0), hot: C(0xFF8A24)) }
        for j in 0..<5 {
            let vx = -2 - noise(j * 7 + i) * 6, vy = -3 - noise(j * 13 + i) * 4
            let x = Double(b.x) + vx * k * 1.6, y = Double(b.y) + vy * k + 14 * k * k
            c.px(Int(x.rounded()), Int(y.rounded()), (j % 2 == 0 ? C(0xFFD050) : C(0xFF7A1A)).alpha(1 - k))
        }
    }
}

// MARK: - Tran

/// Tran at the quintain: a post in front of him with a bar turning on top of it, a painted shield hanging off its
/// near end and a sandbag off the far one. He cuts at the shield (a clang and white sparks), the bar spins round, and
/// as the sandbag comes swinging at him he gets the sabre up in a block (a thump and a puff of sand); it carries on
/// round, the shield comes back to the front, and he does it again, looking no less tired.
private func drawQuintainDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 3.0
    let working = r > 0.6
    let e = d.e - 0.5
    let u = working ? e.truncatingRemainder(dividingBy: period) : -1
    // The sabre: drooping on guard, wound up, a cut onto the shield at 0.4, back down, up into a high block for the
    // sandbag at 1.03, and down again.
    let angleKeys: [(Double, Double)] = [(0, 50), (0.25, -100), (0.4, -15), (0.6, -15), (0.85, -65), (1.5, -65),
                                         (1.8, 50)]
    let a = working ? keyed(e, period: period, angleKeys) : 55
    var trail: [Double] = []
    if working {
        let p1 = keyed(e - 0.03, period: period, angleKeys), p2 = keyed(e - 0.06, period: period, angleKeys)
        if abs(a - p1) > 5 { trail = [p1, p2] }
    }
    let strike = 0.4, block = 1.03
    // The bar's turn: still until the strike, then a full turn, the sandbag passing his side at the block.
    var phi = 0.0
    if u > strike && u < 2.2 {
        let k = (u - strike) / (2.2 - strike)
        phi = 2 * .pi * (1 - pow(1 - k, 1.6))
    }
    let since = (strike: u >= strike ? u - strike : 9, block: u >= block ? u - block : 9)

    // The quintain: a post on a cross foot, the bar on top seen side on, so its ends swing in and out as it turns.
    if r > 0.15 {
        let wood = C(0x8A5E34), woodD = C(0x5E3E20), woodL = C(0xB08050)
        let px = 56.5, top = 20.0, arm = 10.0
        let near = (x: px - cos(phi) * arm, z: sin(phi)), far = (x: px + cos(phi) * arm, z: -sin(phi))
        func drawEnd(_ x: Double, shield: Bool, behind: Bool) {
            let ix = Int(x.rounded())
            let fade = behind ? 0.75 : 1
            if shield {
                // A kite shield on a chain: a steel rim round a red and white checker.
                c.px(ix, Int(top) + 1, C(0xB0B4BC, fade))
                c.pattern(ix - 2, Int(top) + 2, ["GGGGG", "GRWRG", "GWRWG", "GRWRG", ".GWG.", "..G.."],
                          ["R": C(0xC83A32, fade), "W": C(0xF0ECE0, fade), "G": C(0xA8AEB8, fade)])
            } else {
                // The sandbag on its rope, swinging out the way it's going.
                let swing = Int((sin(phi) * 2).rounded())
                line(c, Double(ix), top + 1, Double(ix + swing), top + 5, C(0x6A5030, fade), 0.4)
                let bag = C(0xC8B080, fade), bagD = C(0x9A8458, fade)
                c.rect(ix + swing - 2, Int(top) + 5, 5, 7, bag)
                c.rect(ix + swing + 2, Int(top) + 5, 1, 7, bagD); c.rect(ix + swing - 2, Int(top) + 11, 5, 1, bagD)
                c.rect(ix + swing - 1, Int(top) + 5, 3, 1, C(0x6A5030, fade))
            }
        }
        // What's turned away goes behind the post.
        if near.z > 0 { drawEnd(near.x, shield: true, behind: true) }
        if far.z > 0 { drawEnd(far.x, shield: false, behind: true) }
        c.rect(55, Int(top), 3, 23, wood); c.rect(55, Int(top), 1, 23, woodL); c.rect(57, Int(top), 1, 23, woodD)
        c.rect(50, 43, 12, 1, woodD); c.rect(52, 42, 8, 1, wood)
        line(c, near.x, top, far.x, top, wood, 0.7)
        c.rect(55, Int(top) - 1, 3, 2, woodD)   // the pivot cap
        if near.z <= 0 { drawEnd(near.x, shield: true, behind: false) }
        if far.z <= 0 { drawEnd(far.x, shield: false, behind: false) }
    }

    standing(c, who, t: t) { p in
        p.melee = a; p.trail = trail
    }
    guard working else { return }

    // The clang on the shield and the thump of the sandbag on his blade.
    if since.strike < 0.3 {
        hitBurst(c, x: 47, y: 25, k: since.strike / 0.3, core: C(0xFFFFFF), hot: C(0xC8E0FF))
    }
    if since.block < 0.5 {
        let k = since.block / 0.5
        for j in 0..<6 {
            let ang = -150 + Double(j) * 40
            let q = crawlReach((47, 28), ang, 2 + k * 5)
            c.px(Int(q.x.rounded()), Int((q.y + 6 * k * k).rounded()), C(0xE8D8A8, 0.85 * (1 - k)))
        }
    }
}
