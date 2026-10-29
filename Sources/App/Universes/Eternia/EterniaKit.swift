import Foundation

// Drawing helpers several of Eternia's art files share: swords and staffs swung from the hand, and the fur Eternia's
// warriors wear on their hips and boots.

let eterniaHand = Sprite.hand
private let eterniaNone = C(0, 0)

/// A point `d` pixels out from `h` at `angle` degrees.
func eterniaReach(_ h: (x: Double, y: Double), _ angle: Double, _ d: Double) -> (x: Double, y: Double) {
    let r = angle * .pi / 180
    return (h.x + cos(r) * d, h.y + sin(r) * d)
}

/// A solid bar along `angle` from `a` to `b` pixels out from `h` (a blade, a hilt, a staff), `r` from its centre line.
func eterniaBar(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ angle: Double, from a: Double, to b: Double, _ col: Px,
                r: Double = 0.8) {
    let p0 = eterniaReach(h, angle, a), p1 = eterniaReach(h, angle, b)
    c.glowLine(p0.x, p0.y, p1.x, p1.y, core: col, glow: eterniaNone, coreR: r, glowR: r + 0.1)
}

/// A broadsword in the fist at `angle` degrees: the smear a fast swing leaves, the grip and pommel, a crossguard
/// across the blade's root, then the blade, its edge lit along the middle. `h` is the fist (the hand, unless raised).
func eterniaSword(_ c: PixelCanvas, _ p: Pose, angle a: Double, at h: (x: Double, y: Double) = eterniaHand,
                  grip: Px, guardCol: Px, steel: Px, edge: Px, length: Double, pommel: Px? = nil) {
    for (i, t) in p.trail.enumerated() {
        let p0 = eterniaReach(h, t, 3), p1 = eterniaReach(h, t, length + 2)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.5, glowR: 1.6,
                   strength: 0.3 / Double(i + 1))
    }
    eterniaBar(c, h, a, from: -3, to: 1.5, grip, r: 0.9)
    if let pommel { let q = eterniaReach(h, a, -3); c.rect(Int(q.x.rounded()) - 1, Int(q.y.rounded()) - 1, 2, 2, pommel) }
    // The crossguard, square to the blade.
    let g = eterniaReach(h, a, 2)
    let gx0 = eterniaReach(g, a + 90, 2.6), gx1 = eterniaReach(g, a - 90, 2.6)
    c.glowLine(gx0.x, gx0.y, gx1.x, gx1.y, core: guardCol, glow: eterniaNone, coreR: 0.8, glowR: 0.9)
    eterniaBar(c, h, a, from: 3, to: length + 1.5, steel, r: 1.1)
    eterniaBar(c, h, a, from: 3.5, to: length + 0.5, edge, r: 0.45)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)   // the fist round the grip
}

/// A row of fur: a band of `base` with short strokes of `dark` and `light` hanging from it, so it reads as a pelt at 1×
/// rather than a flat block. `ragged` lets every other stroke hang a pixel lower along the bottom.
func eterniaFur(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, base: Px, dark: Px, light: Px, ragged: Bool = true) {
    c.rect(x, y, w, h, base)
    for xx in x..<(x + w) {
        switch (xx - x) % 3 {
        case 0: c.rect(xx, y + 1, 1, max(1, h - 1), dark)
        case 1: c.px(xx, y, light)
        default: break
        }
        if ragged && (xx - x) % 2 == 0 { c.px(xx, y + h, (xx - x) % 4 == 0 ? dark : base) }
    }
}

/// How many times a landmark is blown up, `q` from the usual rule (the floor's height, kept inside the width): on the
/// screen saver half as big again, so the castles fill the screen rather than standing small under a lot of sky.
func eterniaTall(_ c: PixelCanvas, _ q: Int) -> Int { Scenes.isTall(c) ? (q * 3 + 1) / 2 : q }
