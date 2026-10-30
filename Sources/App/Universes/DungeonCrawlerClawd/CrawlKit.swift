import Foundation

// Drawing helpers the Art files share: reaching along an angle from a hand, a limb or haft drawn as a thick bar, a
// punch, a raptor's talons, and the System's little block letters. Every name starts with `crawl` (the guide's
// "Names").

/// The point `len` pixels from `from` along `angle` degrees (0 forward, -90 straight up).
func crawlReach(_ from: (x: Double, y: Double), _ angle: Double, _ len: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (from.x + cos(r) * len, from.y + sin(r) * len)
}

/// A bar `r` pixels thick along `angle` from `from`, between `a` and `b` pixels out: an arm, a haft, a neck.
func crawlBar(_ c: PixelCanvas, _ from: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double,
              _ col: Px, r: Double = 1) {
    let s = crawlReach(from, angle, a), e = crawlReach(from, angle, b)
    c.glowLine(s.x, s.y, e.x, e.y, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// A punch: the arm out from the shoulder to a 3×3 fist at `angle`, earlier fists fading behind a fast one. `fist`
/// draws the fist itself, centred on the point it's given, at the alpha it's given.
func crawlPunch(_ c: PixelCanvas, angle: Double, trail: [Double], arm: Px, reach: Double = 6,
                fist: (_ x: Int, _ y: Int, _ alpha: Double) -> Void) {
    for (i, a) in trail.enumerated() {
        let e = crawlReach(Sprite.hand, a, reach)
        fist(Int(e.x.rounded()), Int(e.y.rounded()), 0.35 / Double(i + 1))
    }
    crawlBar(c, (Sprite.hand.x - 2, Sprite.hand.y - 0.5), angle, from: 0, to: reach + 2, arm, r: 1.2)
    let e = crawlReach(Sprite.hand, angle, reach)
    fist(Int(e.x.rounded()), Int(e.y.rounded()), 1)
}

/// Three hooked talons from `at`, pointing along `angle`, fanned a little.
func crawlTalons(_ c: PixelCanvas, _ at: (x: Double, y: Double), angle: Double, len: Double, _ col: Px, alpha: Double = 1) {
    for k in [-25.0, 0, 25] {
        let e = crawlReach(at, angle + k, len)
        c.glowLine(at.x, at.y, e.x, e.y, core: col.alpha(alpha), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    }
}

/// The System's block letters, 3×5 each with a pixel between: the digits, a plus, K and the capitals the boxes use.
/// Unknown characters are a space.
/// `scale` draws each of the letters' pixels as a square that many pixels wide (a place's unit).
func crawlText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, scale: Int = 1) {
    var cx = x
    for ch in text.uppercased() {
        if let rows = crawlGlyphs[ch] {
            for (dy, row) in rows.enumerated() {
                for (dx, bit) in row.enumerated() where bit == "#" { c.rect(cx + dx * scale, y + dy * scale, scale, scale, col) }
            }
        }
        cx += 4 * scale
    }
}

/// How wide `crawlText` draws `text`, in pixels.
func crawlTextWidth(_ text: String, scale: Int = 1) -> Int { max(0, text.count * 4 - 1) * scale }

private let crawlGlyphs: [Character: [String]] = [
    "0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
    "2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
    "4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
    "6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."],
    "8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
    "+": ["...", ".#.", "###", ".#.", "..."], "!": [".#.", ".#.", ".#.", "...", ".#."],
    "A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
    "C": [".##", "#..", "#..", "#..", ".##"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
    "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
    "G": [".##", "#..", "#.#", "#.#", ".##"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"], "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "L": ["#..", "#..", "#..", "#..", "###"], "M": ["#.#", "###", "###", "#.#", "#.#"],
    "N": ["##.", "#.#", "#.#", "#.#", "#.#"], "O": [".#.", "#.#", "#.#", "#.#", ".#."],
    "P": ["##.", "#.#", "##.", "#..", "#.."], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "S": [".##", "#..", ".#.", "..#", "##."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "W": ["#.#", "#.#", "###", "###", "#.#"], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
]
