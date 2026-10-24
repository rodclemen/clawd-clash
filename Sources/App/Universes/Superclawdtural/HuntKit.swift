import Foundation

// Superclawdtural's shared drawing bits, used across its Art files (and by HEM): geometry for swung blades, the plaid
// of a flannel shirt, an angel's wing shadows and the steel of a blade. Everything here is prefixed `hunt` so it can't
// clash with another universe's helpers in the tools that compile every universe together.

let huntHand = Sprite.hand
private let huntNone = C(0, 0)

/// A point `d` pixels out from `h` at `angle` degrees.
func huntReach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid straight stroke from (x0, y0) to (x1, y1), `r` pixels from its centre line.
func huntLine(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: huntNone, coreR: r, glowR: r + 0.1)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h` (blades, knives, a hilt).
func huntBar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
             r: Double = 0.8) {
    let p0 = huntReach(h, angle, a), p1 = huntReach(h, angle, b)
    huntLine(c, p0.x, p0.y, p1.x, p1.y, col, r)
}

/// The fading smear a fast swing leaves behind.
func huntSmear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double, _ col: Px) {
    for (i, angle) in trail.enumerated() {
        let p0 = huntReach(h, angle, a), p1 = huntReach(h, angle, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: col, coreR: 0.5, glowR: 1.6, strength: 0.3 / Double(i + 1))
    }
}

/// A blade swung along `angle` from the hand: the grip in the fist, the steel with a bright edge, a smear behind it.
/// `notches`: dark marks along the grip (Ruby's knife's carved handle).
func huntBlade(_ c: PixelCanvas, _ p: Pose, angle a: Double, grip: Px, steel: Px, edge: Px, length: Double,
               notches: Px? = nil) {
    let h = huntHand
    huntSmear(c, h, p.trail, from: 2, to: length + 1, C(0xF0F4FF))
    huntBar(c, h, a, from: -2.5, to: 1.5, grip, r: 1)
    if let notches {
        for d in [-1.5, 0.5] { let q = huntReach(h, a, d); c.px(Int(q.x.rounded()), Int(q.y.rounded()), notches) }
    }
    huntBar(c, h, a, from: 2, to: length + 0.5, steel, r: 0.9)
    huntBar(c, h, a, from: 2, to: length, edge, r: 0.5)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)   // the fist round the grip
}

/// Flannel: a plaid in three tones over the rectangle, a darker band every third row and column where the threads
/// cross, and a lit thread between them. It reads as checks at 1×, not as noise.
func huntPlaid(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, base: Px, dark: Px, light: Px) {
    for yy in y..<(y + h) {
        for xx in x..<(x + w) {
            let col = (xx % 3 == 0) && (yy % 3 == 0) ? dark : (xx % 3 == 0 || yy % 3 == 0) ? dark.mixed(base) :
                      (xx % 3 == 1 && yy % 3 == 2) ? light : base
            c.px(xx, yy, col)
        }
    }
}

/// The left wing's shadow, spread wide, its root on the right where it meets his back: the leading edge arching up
/// and out, the long flight feathers hanging in fingers at the outer end, the shorter ones scalloped back towards the
/// root. `w` marks where two feathers part, a shade deeper. The right wing is this one mirrored.
private let huntWing = [
    ".........WWWWWWW......",
    "......WWWWWWWWWWWW....",
    "....WWWWWWWWWWWWWWWW..",
    "..WWWWWWWWWWWWWWWWWWW.",
    ".WWWWWWWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWWWWWWWW",
    "WWWWwWWWWwWWWWWWWWWWWW",
    "WWWWwWWWWwWWWWwWWWWWWW",
    "WWW.wWWW.wWWWWwWWWWWWW",
    "WWW..WWW..WWWWwWWWWWW.",
    "WW...WWW...WWW.WWWWWW.",
    ".W....WW...WWW..WWWW..",
    "......WW....WW...WW...",
    ".......W.....W........",
]

/// Where an angel's own figure reaches while his wings show, row by row (`huntWingNear`): the first and last column
/// of anything solid of any of them (hair, the arms, a hand raised to the face, the coat's skirts) through their
/// signatures and Clawdstiel's flutter, from row `huntFigureTop` down.
private let huntFigureTop = 20
private let huntFigureSpans: [(lo: Int, hi: Int)] = [
    (23, 32), (20, 34), (19, 38),                                                             // rows 20…22
    (18, 40), (18, 40), (18, 40), (18, 40), (18, 40), (18, 40), (18, 40), (18, 40), (18, 40), // rows 23…31
    (15, 40), (15, 40), (15, 40), (15, 40), (18, 37),                                         // rows 32…36
    (17, 38), (17, 38), (17, 38), (17, 38), (19, 36), (19, 36), (19, 36),                     // rows 37…43
]

/// How close a pixel is to an angel's figure: 2 a pixel or less from it (the shadow leaves that clear, so the app's
/// outline goes all the way round him, hair and all), 1 where Balthaclawds' wine glass reaches when he raises it to
/// his lips (the shadow goes faint there, faint enough for the outline to show over it, so the wings don't look cut
/// off for everyone else), else 0.
private func huntWingNear(_ x: Int, _ y: Int) -> Int {
    for yy in (y - 1)...(y + 1) {
        let i = yy - huntFigureTop
        guard i >= 0, i < huntFigureSpans.count else { continue }
        if x >= huntFigureSpans[i].lo - 1 && x <= huntFigureSpans[i].hi + 1 { return 2 }
    }
    return y >= 21 && y <= 32 && x <= 43 && x >= 39 ? 1 : 0
}

/// An angel's wings, as the show has them: only a shadow thrown on the wall behind, never the wings themselves. Two
/// great wings rooted at his back, opened `k` (0 folded away, 1 spread wide to either side), drawn from `huntWing`
/// and its mirror, narrower and lower while they open; `tall` stretches them higher above his head (Clawdstiel's,
/// the grandest). They're see-through (a shadow), so they get no outline, and they keep a pixel clear of him all
/// round, so his own outline isn't broken where they meet his hair. Where two feathers part, a paler line, and along
/// the leading edge a pale rim, both see-through too, so the shape reads as wings on a near-black desktop and not as
/// a smudge on a bright place. Drawn before the body, so he stands in front.
///
/// At full `strength` the shadow is someone's stencil (the angels' drill reads its shape for its flare): drawn whole
/// then, with no gap, so the stencil keeps its shape.
func huntWingShadows(_ c: PixelCanvas, _ k: Double, tint: Px = C(0x06080E), strength: Double = 0.45,
                     tall: Double = 1) {
    guard k > 0.04 else { return }
    let rows = huntWing.map { Array($0) }, w = rows[0].count, h = rows.count
    let rootRow = 6.0, rootY = 27.0 - (tall - 1) * 3      // the pattern's row that meets his back, and where
    let sx = 0.25 + 0.75 * k, sy = (0.6 + 0.65 * k) * tall // how far open: across, and up
    let stencil = strength >= 0.99
    let pale = lerp(tint, C(0xD4DEF6), 0.85), parting = lerp(tint, C(0xD4DEF6), 0.4)
    /// The pattern's character at a canvas pixel, if the wing on `side` covers it, and how far out from the root.
    func cell(_ x: Int, _ y: Int, _ side: Int) -> (ch: Character, out: Double)? {
        let rootX = side < 0 ? 22.0 : 33.0                 // just inside his silhouette, either side
        let v = (Double(y) - rootY) / sy + rootRow          // which pattern row this canvas row comes from
        guard v >= 0, v < Double(h) else { return nil }
        let out = (Double(x) - rootX) * Double(side)        // pixels out from the root, away from him
        guard out > -2 else { return nil }
        let u = Double(w - 1) - out / sx                    // pattern column (the root is the last one)
        guard u >= 0, u < Double(w) else { return nil }
        let ch = rows[Int(v)][Int(u)]
        return ch == "." ? nil : (ch, out)
    }
    for side in [-1, 1] {
        for y in 1..<44 {
            for x in 1...70 {
                guard let (ch, out) = cell(x, y, side) else { continue }
                let near = stencil ? 0 : huntWingNear(x, y)
                if near == 2 { continue }
                var fade = min(1, max(0, (out + 1) / 6)) * min(1, k * 1.5)   // faint where it meets him
                if near == 1 { fade = min(fade, 0.18 / strength) }            // under a quarter: the outline shows
                // The rim: the wing's leading edge along the top and round its outer bend, well out from him (not where
                // it tucks in behind his back, and not down the hanging feathers, which would turn them to claws).
                let edge = out > 5 && (cell(x, y - 1, side) == nil || (Double(y) <= rootY && cell(x + side, y, side) == nil))
                if edge {
                    c.px(x, y, pale.alpha(min(1, strength * 1.1) * fade))
                } else if ch == "w" {
                    c.px(x, y, parting.alpha(min(1, strength * 1.2) * fade))
                } else {
                    c.px(x, y, tint.alpha(strength * fade))
                }
            }
        }
    }
}

extension Px {
    /// Halfway between this colour and `other`.
    fileprivate func mixed(_ other: Px) -> Px {
        Px(r: UInt8((Int(r) + Int(other.r)) / 2), g: UInt8((Int(g) + Int(other.g)) / 2), b: UInt8((Int(b) + Int(other.b)) / 2), a: a)
    }
}
