import CoreGraphics
import Foundation

// Orkko's Trick (`EterniaWipe.orkko`): the Trollan magician tries to magic everyone to the new place and gets it wrong
// twice first. Each go is a puff of pink and yellow smoke from his hand; the first lands on a beach, the second in a
// field of rubber chickens ("OOPS!"), and the third, at last, on the right place.

extension EterniaTrip {
    /// A frame `k` (0…1) of Orkko's Trick, over the whole of `r`. Orkko pops up in front of the old place in a burst of
    /// sparks and waves his hand, twinkling lemon and magenta (0–0.2); a puff of pink and yellow smoke billows out of
    /// it over everything and clears on a sunny beach (0.2–0.38); he waves again, another puff, and it clears on a
    /// field of rubber chickens bobbing in rows (0.38–0.58); "OOPS!" pops up over them (0.6–0.74); one more wave and a
    /// last puff takes him with it, clearing on the new place (0.66–0.98). Orkko is his own sprite, as he is on stage.
    func drawOrkko(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let puffs: [(grow: Double, clear: Double)] = [
            (Self.span(k, 0.2, 0.28), Self.span(k, 0.3, 0.38)),
            (Self.span(k, 0.44, 0.5), Self.span(k, 0.52, 0.58)),
            (Self.span(k, 0.72, 0.8), Self.span(k, 0.82, 0.98)),
        ]
        // What's behind the smoke: the old place, the beach, the chickens, the new place, each from when the puff
        // before it covered everything.
        let stage = puffs.filter { $0.grow >= 1 }.count
        switch stage {
        case 0: ctx.drawShot(old, in: r)
        case 3: ctx.drawShot(new, in: r)
        case 1: eterniaOrkkoBeach(c, t: k * 2.2)
        default: eterniaOrkkoChickens(c, t: k * 2.2)
        }

        // Orkko, floating in front, to the right of the middle; gone with the last puff.
        let m = art.wide ? 1 : 2                     // twice his stage size on the screen saver
        let ox = Int(Double(w) * (art.wide ? 0.66 : 0.6)) - 28 * m
        let bob = sin(k * 2.2 * 2.4) > 0 ? -m : 0
        let oy = h - Sprite.height * m - (art.wide ? 0 : h / 20) - 3 * m + bob
        let shown = k > 0.05 && puffs[2].grow < 1
        let waving = [(0.08, 0.22), (0.38, 0.46), (0.64, 0.74)].contains { k > $0.0 && k < $0.1 }
        let raise = waving ? (Int(k * 2.2 * 12) % 2 == 0 ? 6 : 2) : 0
        let hand = (x: ox + Int(Sprite.hand.x) * m, y: oy + (Int(Sprite.hand.y) - raise) * m)
        if shown {
            let sprite = PixelCanvas(Sprite.width, Sprite.height)
            let wasSeated = seatedPose
            seatedPose = false
            var pose = Pose(who: .hero(EterniaHero.orkko), t: k * 2.2, lt: k * 2.2, mode: .idle, role: .none, walking: false)
            pose.armRaise = raise
            Cast.hero(EterniaHero.orkko).persona.draw(sprite, pose)
            seatedPose = wasSeated
            for y in 0..<Sprite.height {
                for x in 0..<Sprite.width {
                    let i = (y * Sprite.width + x) * 4
                    guard sprite.buf[i + 3] > 0 else { continue }
                    c.rect(ox + x * m, oy + y * m, m, m, unpremultiplied(sprite, i))
                }
            }
        }
        // The burst of sparks he pops up in.
        let pop = Self.span(k, 0.02, 0.12)
        if pop > 0 && pop < 1 { eterniaOrkkoSparks(c, ox + 28 * m, oy + 30 * m, radius: (4 + pop * 18) * Double(m), n: 10, spin: pop) }
        // The twinkle at his hand while he waves.
        if waving && shown {
            eterniaOrkkoSparks(c, hand.x + 2, hand.y - 2, radius: (3 + Double(Int(k * 40) % 3) * 2) * Double(m), n: 5, spin: k * 6)
        }

        // The smoke: each puff billows out of his hand over everything, then breaks up and clears.
        for (i, p) in puffs.enumerated() where p.grow > 0 && p.clear < 1 {
            eterniaOrkkoPuff(c, from: (Double(hand.x), Double(hand.y)), grow: p.grow, clear: p.clear, seed: i * 97 + 5)
        }

        // "OOPS!" over the chickens, popping in big and settling.
        let oops = Self.span(k, 0.6, 0.63)
        if oops > 0 && k < 0.74 {
            let size = art.wide ? 4 : 5
            let p = oops < 1 ? size + 1 : size
            let tw = eterniaOopsWidth("OOPS!", p)
            let tx = art.wide ? ox - tw - 2 * p : (w - tw) / 2
            let ty = art.wide ? h / 6 : h / 8
            eterniaOopsText(c, tx, ty, "OOPS!", p)
        }
        art.show(ctx)
    }
}

// MARK: The puff

/// A puff of pink and yellow smoke: round billows on a jittered grid, each swelling out from `from` as `grow` goes
/// 0…1 (by 1 they cover everything) and shrinking away in its own time as `clear` goes 0…1. The billows pile up over
/// one another, each a flat cel ball with a dark outline, a crescent lit on its upper left and one shaded on its lower
/// right.
private func eterniaOrkkoPuff(_ c: PixelCanvas, from: (Double, Double), grow: Double, clear: Double, seed: Int) {
    let w = c.w, h = c.h
    let S = max(8.0, Double(h) / 4.5)
    let cols = Int(Double(w) / S) + 3, rows = Int(Double(h) / S) + 3
    let far: Double = Double(w + h)
    let reach: Double = grow * (far + S)
    // Each billow: its centre, its radius, its colour and which billows it lies over.
    var cx = [Double](repeating: 0, count: cols * rows), cy = cx, rad = cx, over = cx
    var pink = [Bool](repeating: false, count: cols * rows)
    for j in 0..<rows {
        for i in 0..<cols {
            let n = j * cols + i
            let x: Double = (Double(i) - 1 + 0.5 + (noise(seed + n * 3) - 0.5) * 0.5) * S
            let y: Double = (Double(j) - 1 + 0.5 + (noise(seed + n * 3 + 1) - 0.5) * 0.5) * S
            let dx = x - from.0, dy = y - from.1
            let dist: Double = (dx * dx + dy * dy).squareRoot()
            let swell: Double = EterniaTrip.clamp((reach - dist) / (S * 1.5))
            let fade: Double = EterniaTrip.clamp((1 - clear) * 1.7 - noise(seed + n * 3 + 2) * 0.7)
            cx[n] = x; cy[n] = y
            rad[n] = S * (0.95 + 0.3 * noise(seed + n * 5 + 4)) * min(swell, fade)
            over[n] = noise(seed + n * 5 + 9)
            pink[n] = noise(seed + n * 7 + 11) < 0.55
        }
    }
    let pinkC = [C(0xC8508E), C(0xF27AB8), C(0xFFC4E2)], yellowC = [C(0xE0A030), C(0xFFD84A), C(0xFFF6B8)]
    let ink = C(0x3A1A48)
    for y in 0..<h {
        let gy = Int(Double(y) / S) + 1
        for x in 0..<w {
            let gx = Int(Double(x) / S) + 1
            // The top billow at this pixel, its outline included.
            var top = -1.0, bi = -1, bd = 0.0
            for j in max(0, gy - 2)...min(rows - 1, gy + 2) {
                for i in max(0, gx - 2)...min(cols - 1, gx + 2) {
                    let n = j * cols + i
                    guard rad[n] > 0.5, over[n] > top else { continue }
                    let dx = Double(x) + 0.5 - cx[n], dy = Double(y) + 0.5 - cy[n]
                    let d: Double = (dx * dx + dy * dy).squareRoot()
                    if d < rad[n] + 1.3 { top = over[n]; bi = n; bd = d }
                }
            }
            guard bi >= 0 else { continue }
            if bd > rad[bi] { c.px(x, y, ink); continue }
            // Flat cel light: a crescent lit on the upper left, one in shade on the lower right.
            let r0 = rad[bi], off = 0.24 * r0
            let lx = Double(x) + 0.5 - (cx[bi] + off), ly = Double(y) + 0.5 - (cy[bi] + off)
            let sx = Double(x) + 0.5 - (cx[bi] - off), sy = Double(y) + 0.5 - (cy[bi] - off)
            let lit: Bool = (lx * lx + ly * ly).squareRoot() > 0.98 * r0
            let shaded: Bool = (sx * sx + sy * sy).squareRoot() > 0.98 * r0
            let tone = lit ? 2 : shaded ? 0 : 1
            c.px(x, y, (pink[bi] ? pinkC : yellowC)[tone])
        }
    }
}

/// A ring of `n` little four-pointed sparks, lemon and magenta in turn, `radius` out from (`x`, `y`).
private func eterniaOrkkoSparks(_ c: PixelCanvas, _ x: Int, _ y: Int, radius: Double, n: Int, spin: Double) {
    for i in 0..<n {
        let a: Double = Double(i) / Double(n) * 2 * .pi + spin * 2
        let sx = x + Int((cos(a) * radius).rounded()), sy = y + Int((sin(a) * radius).rounded())
        let col = i % 2 == 0 ? C(0xFFF07A) : C(0xF04AB0)
        c.px(sx, sy, C(0xFFFFFF))
        for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(sx + dx, sy + dy, col) }
    }
}

// MARK: The wrong places

/// The first wrong place: a sunny beach. A blue sky in bands with the sun and two little clouds, the sea in teal
/// bands with white wave crests, the sand, a red and white umbrella, and a palm tree leaning in from the right.
private func eterniaOrkkoBeach(_ c: PixelCanvas, t: Double) {
    let w = c.w, h = c.h
    let s = max(1, h / 80)
    let sea = h * 52 / 100, sand = h * 70 / 100
    let skies: [UInt32] = [0x5AB8E8, 0x7ACAF0, 0x9ADAF4, 0xBAE6F6]
    for (i, col) in skies.enumerated() { c.rect(0, sea * i / 4, w, sea - sea * i / 4, C(col)) }
    // The sun, with a dark rim, and two clouds.
    let sunX = w / 5, sunY = h / 5
    c.circle(sunX, sunY, 9 * s + 1, C(0xE0802A)); c.circle(sunX, sunY, 9 * s, C(0xFFE04A)); c.circle(sunX - 2 * s, sunY - 2 * s, 4 * s, C(0xFFF4A0))
    for (cx, cy) in [(w * 45 / 100, h / 7), (w * 72 / 100, h / 4)] {
        c.ellipse(cx, cy, 12 * s + 1, 4 * s + 1, C(0x8AA8C8)); c.ellipse(cx, cy, 12 * s, 4 * s, C(0xFFFFFF))
        c.ellipse(cx - 4 * s, cy - 3 * s, 6 * s, 3 * s, C(0xFFFFFF))
    }
    // The sea, in bands, the crests rolling.
    c.rect(0, sea, w, sand - sea, C(0x2A9AB8))
    c.rect(0, sea, w, max(1, s), C(0x1A6A90))
    c.rect(0, sea + (sand - sea) / 3, w, (sand - sea) / 3, C(0x3AB0C8))
    c.rect(0, sea + (sand - sea) * 2 / 3, w, (sand - sea) / 3, C(0x5AC6D8))
    let roll = Int(t * 10)
    for i in 0..<(w / 12 + 2) {
        let y = sea + 2 + (i * 7 % max(1, sand - sea - 4))
        let x = (i * 23 + roll + (i % 3) * 5) % (w + 12) - 6
        c.rect(x, y, 4 * s, 1, C(0xFFFFFF))
    }
    // The sand, speckled, a white line of surf along its edge.
    c.rect(0, sand, w, h - sand, C(0xF0D890))
    c.rect(0, sand, w, max(1, s), C(0xFFFFFF))
    for i in 0..<(w * (h - sand) / 40) {
        c.px(Int(noise(i * 2 + 900) * Double(w)), sand + 2 + Int(noise(i * 2 + 901) * Double(h - sand - 2)), C(0xD0B060))
    }
    // The umbrella: red and white panels over a pole, its shadow on the sand, a towel under it.
    let ux = w * 30 / 100, uy = sand + (h - sand) / 4
    c.rect(ux - 10 * s, uy + 14 * s, 20 * s, 3 * s, C(0x3A8ADA)); c.rect(ux - 10 * s, uy + 15 * s, 20 * s, 1, C(0xFFFFFF))
    c.rect(ux, uy - 12 * s, max(1, s), 27 * s, C(0x6A4A2A))
    for dy in 0..<(7 * s) {
        let half = (dy + 2) * 2
        for dx in -half...half {
            let panel = ((dx + 100 * s) / (4 * s)) % 2 == 0
            c.px(ux + dx, uy - 18 * s + dy, panel ? C(0xE03A2A) : C(0xFFFFFF))
        }
        c.px(ux - half - 1, uy - 18 * s + dy, C(0x6A1A14)); c.px(ux + half + 1, uy - 18 * s + dy, C(0x6A1A14))
    }
    c.rect(ux - (7 * s + 2) * 2 - 1, uy - 11 * s, (7 * s + 2) * 4 + 3, 1, C(0x6A1A14))
    // The palm: a curving trunk in rings from the sand up and left, its fronds drooping.
    let px0 = w * 88 / 100, base = h - 2
    var tx = Double(px0), ty = Double(base)
    let top = Double(h) * 0.2
    let rings = 14
    for i in 0..<rings {
        let u = Double(i) / Double(rings)
        tx = Double(px0) - u * u * Double(18 * s)
        ty = Double(base) - u * (Double(base) - top)
        c.rect(Int(tx) - 2 * s, Int(ty) - 3 * s, 4 * s + 1, 3 * s, C(0x8A5A2A))
        c.rect(Int(tx) - 2 * s, Int(ty) - 3 * s, 4 * s + 1, max(1, s / 2), C(0x5A3A18))
    }
    for f in 0..<6 {
        let a: Double = Double(f) / 6 * 2 * .pi + 0.4
        let len = Double(16 * s)
        var fx = tx, fy = ty - Double(3 * s)
        for j in 0..<16 {
            let u = Double(j) / 16
            fx += cos(a) * len / 16
            fy += sin(a) * len / 16 * 0.5 + u * Double(s) * 0.9
            c.rect(Int(fx), Int(fy), max(2, 2 * s), max(2, 2 * s), C(0x2A8A2A))
            c.px(Int(fx), Int(fy), C(0x5AC040))
        }
    }
    c.circle(Int(tx) - 2 * s, Int(ty) - s, 2 * s, C(0x6A3A1A)); c.circle(Int(tx) + 2 * s, Int(ty), 2 * s, C(0x6A3A1A))
}

/// The second wrong place: a field of rubber chickens. A pale sky, green rolling ground in stripes, and rows of yellow
/// rubber chickens standing in it, small at the back and big at the front, bobbing as if they're squawking.
private func eterniaOrkkoChickens(_ c: PixelCanvas, t: Double) {
    let w = c.w, h = c.h
    let horizon = h * 36 / 100
    let skies: [UInt32] = [0x8AC8F0, 0xA8D8F4, 0xC8E6F4]
    for (i, col) in skies.enumerated() { c.rect(0, horizon * i / 3, w, horizon - horizon * i / 3, C(col)) }
    // Rolling hills on the horizon, then the field in stripes, wider towards the front.
    for x in 0..<w {
        let hill = Int(sin(Double(x) / Double(h) * 3.1) * Double(h) * 0.04 + sin(Double(x) / Double(h) * 7.3) * Double(h) * 0.015)
        c.rect(x, horizon - h * 4 / 100 + hill, 1, h, C(0x3E8A30))
    }
    var y = horizon, band = max(2, h / 40), i = 0
    while y < h {
        c.rect(0, y, w, band, C(i % 2 == 0 ? 0x5AB040 : 0x4A9C36))
        y += band; band += max(1, h / 80); i += 1
    }
    // The chickens, row by row from the back.
    let rowsY = [0.48, 0.62, 0.8, 1.02]
    for (row, fy) in rowsY.enumerated() {
        // Smaller in the window's short strip, so they don't stand taller than Orkko.
        let scale = (h < 140 ? [1, 1, 1, 2] : [1, 1, 2, 3])[row]
        let step = (row + 2) * (h < 140 ? 7 : 9)
        let footY = Int(Double(h) * fy) - 2
        var x = (row * 13) % step - step / 2
        var n = 0
        while x < w + step {
            let hop = sin(t * 9 + Double(n) * 1.3 + Double(row)) > 0.6 ? scale : 0
            eterniaRubberChicken(c, x, footY - 20 * scale - hop, scale, flip: (n + row) % 3 == 0)
            x += step; n += 1
        }
    }
}

/// A rubber chicken standing, 12 by 20 at `scale` 1, from its top-left: pale plucked yellow, a long skinny neck, a
/// big red comb and wattle, an orange beak gaping, a tuft of a tail, long thin orange legs, a dark outline.
private func eterniaRubberChicken(_ c: PixelCanvas, _ x: Int, _ y: Int, _ scale: Int, flip: Bool) {
    let rows = [
        "......rrr...",
        ".....rrrrr..",
        "....kYYYYk..",
        "....YYKYYoo.",
        "....YYYYYk.o",
        "....YYYYYoo.",
        "....kYrYk...",
        ".....YYk....",
        ".....YYk....",
        ".....YYk....",
        ".....YYk....",
        "kk...YYk....",
        "kYk.kYYYk...",
        "kYYkYYYYYk..",
        ".kYYYYYYYk..",
        "..kyYYYyyk..",
        "...kkkkk....",
        "....o..o....",
        "....o..o....",
        "...oo.oo....",
    ]
    let pal: [Character: Px] = ["r": C(0xE03A2A), "k": C(0x7A5418), "Y": C(0xFAE478), "y": C(0xE0B848),
                                "K": C(0x1A1420), "o": C(0xF08A28)]
    for (j, row) in rows.enumerated() {
        for (i, ch) in row.enumerated() {
            guard let col = pal[ch] else { continue }
            let cx = flip ? 11 - i : i
            c.rect(x + cx * scale, y + j * scale, scale, scale, col)
        }
    }
}

// MARK: Lettering

/// "OOPS!" in chunky letters, 5 dots tall (row by row, as the glyph strings are read).
private let eterniaOopsGlyphs: [Character: String] = [
    "O": "010101101101010", "P": "110101110100100", "S": "011100010001110", "!": "11101",
]

private func eterniaOopsWidth(_ text: String, _ p: Int) -> Int {
    var dots = 0
    for ch in text { dots += (eterniaOopsGlyphs[ch]?.count ?? 15) / 5 + 1 }
    return max(0, dots - 1) * p
}

/// The lettering at `p` pixels a dot from its top-left: lemon yellow with a magenta drop under it and a dark outline
/// round both, the colours of Orkko's magic.
private func eterniaOopsText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ p: Int) {
    func dots(_ dx: Int, _ dy: Int, _ col: Px, _ grow: Int) {
        var cx = x
        for ch in text {
            guard let g = eterniaOopsGlyphs[ch] else { continue }
            let gw = g.count / 5
            for (i, bit) in g.enumerated() where bit == "1" {
                c.rect(cx + (i % gw) * p + dx - grow, y + (i / gw) * p + dy - grow, p + 2 * grow, p + 2 * grow, col)
            }
            cx += (gw + 1) * p
        }
    }
    let d = max(1, p / 2)
    dots(d, d, C(0x2A1030), 2)
    dots(0, 0, C(0x2A1030), 2)
    dots(d, d, C(0xC03A8A), 0)
    dots(0, 0, C(0xFFE84A), 0)
}
