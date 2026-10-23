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

/// An angel's wings, as the show has them: only a shadow thrown on the wall behind, never the wings themselves. Two
/// great wings rooted at his back, opened `k` (0 folded away, 1 spread wide to either side), drawn from `huntWing`
/// and its mirror, narrower and lower while they open. They're see-through (a shadow) and faintest where they meet
/// his silhouette, so they get no outline and leave his own clean. Drawn before the body, so he stands in front.
func huntWingShadows(_ c: PixelCanvas, _ k: Double, tint: Px = C(0x06080E), strength: Double = 0.45) {
    guard k > 0.04 else { return }
    let rows = huntWing.map { Array($0) }, w = rows[0].count, h = rows.count
    let rootRow = 6.0, rootY = 27.0                        // the pattern's row that meets his back, and where
    let sx = 0.25 + 0.75 * k, sy = 0.6 + 0.65 * k         // how far open: across, and up
    for side in [-1, 1] {
        let rootX = side < 0 ? 22.0 : 33.0                 // just inside his silhouette, either side
        for y in 1..<44 {
            let v = (Double(y) - rootY) / sy + rootRow       // which pattern row this canvas row comes from
            guard v >= 0, v < Double(h) else { continue }
            for x in 1...70 {
                let out = (Double(x) - rootX) * Double(side)   // pixels out from the root, away from him
                guard out > -2 else { continue }
                let u = Double(w - 1) - out / sx               // pattern column (the root is the last one)
                guard u >= 0, u < Double(w) else { continue }
                let ch = rows[Int(v)][Int(u)]
                guard ch != "." else { continue }
                let fade = min(1, max(0, (out + 1) / 6))       // faint where it meets him
                c.px(x, y, tint.alpha(strength * (ch == "w" ? 1.35 : 1) * fade * min(1, k * 1.5)))
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
