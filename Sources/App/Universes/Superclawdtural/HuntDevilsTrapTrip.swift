import CoreGraphics
import Foundation

// Devil's Trap (`HuntWipe.devilsTrap`): the trap on the Bunker's floor, painted on the screen in red. The circle goes
// round first, then the five lines of the star, then the sigils between the two rings, one after another; the whole
// thing starts to turn, glowing like hot paint; and the new place opens in its middle, the trap swelling with it until
// the rings sweep out past the edges of the frame.

extension HuntTrip {
    /// A frame `k` (0…1) of the Devil's Trap, over the whole of `r`. The old place dims and the trap paints itself on,
    /// a brush going round the outer ring and the inner one, the star's lines drawn point to point, the sigils dabbed in
    /// (0–0.4); it turns, slowly and then faster, its glow pulsing (0.25–1); the new place opens from its centre in a
    /// ring of burning paint, the trap growing as it opens, and fills the frame (0.52–1). All of it worked out pixel by
    /// pixel on the art's grid, so it stays crisp as it turns.
    func drawDevilsTrap(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let open = pow(Self.span(k, 0.52, 1), 1.7)
        let spin = 2 * .pi * (0.9 * pow(Self.span(k, 0.25, 1), 2) + 0.05 * Self.span(k, 0.25, 1))
        let pulse = 0.5 + 0.5 * sin(k * 26)
        let awake = Self.span(k, 0.28, 0.45)                 // wet paint at first; it glows once it's whole and turning
        let cx = Double(w) / 2, cy = Double(h) / 2
        let r0 = Double(min(w, h)) * (art.wide ? 0.46 : 0.43)
        let big = r0 * (1 + 6 * open * open)                 // the trap's outer radius, swelling as it opens
        let hole = big * min(1.08, open * 1.5)               // the opening onto the new place

        // How far each stroke has got: the rings, the star's five lines, the twelve sigils.
        let outerP = Self.span(k, 0.0, 0.14), innerP = Self.span(k, 0.06, 0.2)
        let lineP = (0..<5).map { Self.span(k, 0.14 + Double($0) * 0.04, 0.2 + Double($0) * 0.04) }
        let sigilP = (0..<12).map { Self.span(k, 0.22 + Double($0) * 0.014, 0.23 + Double($0) * 0.014) }

        // Underneath: the old place, dimmed so the red reads on a bright place, and the new one through the opening.
        ctx.drawShot(old, in: r)
        Self.wash(ctx, 0x0C0204, 0.38 * Self.ease(Self.span(k, 0, 0.25)) + 0.12 * Self.span(k, 0.25, 0.5), in: r)
        if hole > 0.5 {
            let through = art.runs { x, y in
                let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                return dx * dx + dy * dy < hole * hole
            }
            if !through.isEmpty {
                ctx.saveGState(); ctx.clip(to: through); ctx.drawShot(new, in: r)
                Self.wash(ctx, 0x8A1A10, 0.35 * (1 - Self.span(k, 0.55, 0.9)), in: r)
                ctx.restoreGState()
            }
        }

        // The trap's parts, in its own turning frame, with the radius as the unit.
        let thin = max(0.9, big * 0.022)                      // half a line's width, in art pixels
        let star = (0..<5).map { i -> (Double, Double) in
            let a = (-90 + Double(i) * 72) * .pi / 180
            return (cos(a) * 0.76, sin(a) * 0.76)
        }
        let paint = C(0xC42A26), lit = C(0xF0603C), edge = C(0x4A0808), glow = C(0xFF3A1E)
        let hot = C(0xFFC890)

        for y in 0..<h {
            for x in 0..<w {
                let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                let d = (dx * dx + dy * dy).squareRoot()
                // The burning rim of the opening, and nothing of the trap inside it.
                if hole > 0.5 {
                    let e = d - hole
                    if e < 0 { continue }
                    if e < 1.2 { c.px(x, y, hot); continue }
                    if e < 2.6 { c.px(x, y, glow); continue }
                }
                guard d < big * 1.08 + 4 else { continue }
                let th = atan2(dy, dx) - spin
                let u = d / big
                // Where round the ring this is, from the top, clockwise in the trap's frame (for the brush's sweep).
                var round = (th + .pi / 2) / (2 * .pi)
                round -= floor(round)
                // How far it is from the nearest painted stroke, in art pixels.
                var dist = Double.infinity
                func ring(_ mid: Double, _ half: Double, _ p: Double) {
                    guard round < p else { return }
                    dist = min(dist, abs(d - mid * big) - half * big)
                }
                ring(0.97, 0.03, outerP)
                ring(0.77, 0.03, innerP)
                let lx = cos(th) * u, ly = sin(th) * u
                for i in 0..<5 where lineP[i] > 0 {
                    let a = star[i], b = star[(i + 2) % 5]
                    let vx = b.0 - a.0, vy = b.1 - a.1
                    let t = max(0, min(lineP[i], ((lx - a.0) * vx + (ly - a.1) * vy) / (vx * vx + vy * vy)))
                    let ex = a.0 + vx * t - lx, ey = a.1 + vy * t - ly
                    dist = min(dist, (ex * ex + ey * ey).squareRoot() * big - thin)
                }
                // The sigils between the rings: each a little 5×5 mark in its own slot.
                var sigil = false
                if u > 0.8 && u < 0.94 {
                    let slot = Int(round * 12) % 12
                    if sigilP[slot] > 0 {
                        let along = (round * 12 - Double(slot) - 0.5) * 2 * .pi * 0.87 * big / 12
                        let size = 0.12 * big
                        let gx = Int(floor((along / size + 0.5) * 5)), gy = Int(floor((0.5 - (d - 0.87 * big) / size) * 5))
                        if gx >= 0, gx < 5, gy >= 0, gy < 5 {
                            let g = huntTrapSigils[slot % huntTrapSigils.count]
                            let i = g.index(g.startIndex, offsetBy: gy * 5 + gx)
                            sigil = g[i] == "1"
                        }
                    }
                }
                if sigil { c.px(x, y, sigilP[Int(round * 12) % 12] < 1 ? hot : lit); continue }
                if dist <= 0 {
                    c.px(x, y, dist < -thin * 0.6 && thin > 1.2 && awake > 0.5 ? lit : paint)
                } else if dist < 1 {
                    c.px(x, y, edge)
                } else if dist < 3.5 {
                    c.px(x, y, glow.alpha(((0.08 + (0.14 + 0.12 * pulse) * awake) * (dist < 2.2 ? 1 : 0.5) * 8).rounded() / 8))
                }
            }
        }
        art.show(ctx)
    }
}

/// The sigils painted between the trap's two rings, 5×5 each, row by row: hooked crosses, forks and little closed
/// marks, after the ones round the trap on the Bunker's floor (made up, not real letters).
private let huntTrapSigils = [
    "10001" + "11011" + "00100" + "00100" + "01110",
    "00100" + "10101" + "11111" + "10101" + "00100",
    "11100" + "00100" + "11111" + "00100" + "00111",
    "01110" + "10001" + "10101" + "10001" + "01110",
    "10100" + "10100" + "11111" + "00101" + "00101",
    "00100" + "01010" + "10001" + "11111" + "00100",
]
