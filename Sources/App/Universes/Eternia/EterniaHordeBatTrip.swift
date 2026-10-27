import CoreGraphics
import Foundation

// The Horde Bat (`EterniaWipe.hordeBat`): the Horde's red bat, the emblem on Hordakk's brow and on the side of the
// skiff, ears up and wings raised, comes flapping at the screen out of the distance. Its
// wings sweep round and close over the scene, a wall of red membrane and dark ribs, then part down the middle and
// open on the new place, where a small bat flaps away into the sky.

extension EterniaTrip {
    /// The Horde Bat, `k` (0…1) through its own part, over the whole of `r`. The bat flies at the screen from the
    /// distance, flapping, growing until it fills the middle of the frame (0–0.4); its wings sweep up and round
    /// and reach out past every corner, closing over the whole scene (0.4–0.58) and hold there a moment, red with dark ribs; then the two wings part
    /// down the middle and open outwards on the new place (0.62–0.86), and a small bat flaps off up into its sky
    /// (0.8–0.97). The bat is pixel art, a flat cel red with dark ribs and outline; the places are drawn as they are.
    func drawHordeBat(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let cxEnd = Double(w) / 2, cyEnd = (Double(h) * 0.52).rounded()
        let s0 = max(1.6, Double(h) / 64), s1 = (Double(h) * 0.15).rounded()

        // Where the bat is and how it holds its wings: nearer and nearer, then its wings sweeping round until they
        // reach past every corner.
        let near = Self.span(k, 0, 0.4), close = Self.ease(Self.span(k, 0.4, 0.58))
        let z = 1 - (1 - s0 / s1) * near
        var bat = HordeBat(cx: cxEnd, cy: cyEnd, s: s0 / z, upper: -1.2, lower: 0.6, len: 4.6, body: true, lit: true)
        let drift = 1 - Self.ease(near)
        bat.cx = cxEnd + Double(w) * 0.14 * drift
        bat.cy = cyEnd - Double(h) * 0.14 * drift
        if close <= 0 {
            let beat = sin(k * 44)
            bat.upper = -1.2 + 0.32 * beat
            bat.lower = 0.6 + 0.22 * beat
        } else {
            let reach = Double(w + h) / s1
            bat.lit = false
            bat.upper = -1.2 - 1.45 * close
            bat.lower = 0.6 + 2.05 * close
            bat.len = 4.6 + (reach - 4.6) * close
        }
        let open = Self.ease(Self.span(k, 0.62, 0.86))
        let gap = open * (Double(w) / 2 + bat.s * 3)

        ctx.drawShot(open > 0 ? new : old, in: r)
        if open < 1 {
            let red = C(0xE0282A), redS = C(0xB81C22), redL = C(0xFF5A4A), redD = C(0x7A1012), ink = C(0x2A0A0C)
            for y in 0..<h {
                for x in 0..<w {
                    // Opening, each half slides out to its own side and the gap between shows the new place.
                    var sx = Double(x) + 0.5
                    if open > 0 {
                        let left = sx < cxEnd
                        sx += left ? gap : -gap
                        if left ? sx >= cxEnd : sx < cxEnd { continue }
                    }
                    let sy = Double(y) + 0.5
                    let part = bat.part(sx, sy)
                    guard part != .none else { continue }
                    let rim = bat.part(sx - 1, sy) == .none || bat.part(sx + 1, sy) == .none
                        || bat.part(sx, sy - 1) == .none || bat.part(sx, sy + 1) == .none
                    let col: Px
                    if rim { col = ink } else {
                        switch part {
                        case .rib: col = redD
                        case .shade: col = redS
                        case .lit: col = redL
                        default: col = red
                        }
                    }
                    c.px(x, y, col)
                }
            }
            // The seam down the middle while they part.
            if open > 0 {
                let l = Int((cxEnd - gap).rounded()) - 1, rr = Int((cxEnd + gap).rounded())
                c.rect(l, 0, 1, h, ink); c.rect(rr, 0, 1, h, ink)
            }
        }

        // A small bat flapping off into the new place's sky.
        let away = Self.span(k, 0.8, 0.97)
        if away > 0 && away < 1 {
            let bx = Int((Double(w) * (0.5 + 0.18 * away)).rounded()), by = Int((Double(h) * (0.3 - 0.36 * away)).rounded())
            let up = Int(k * 30) % 2 == 0
            c.pattern(bx - 5, by - 2, up ? [
                "R...R.R...R",
                "RR..RRR..RR",
                "RRRRRdRRRRR",
                ".RR.RRR.RR.",
                "....R.R....",
            ] : [
                "....R.R....",
                "....RRR....",
                "RRRRRdRRRRR",
                "RRR.RRR.RRR",
                "R...R.R...R",
            ], ["R": C(0xE0282A), "d": C(0x7A1012)])
        }
        art.show(ctx)
    }
}

/// The Horde's bat, front on, as a shape to test art pixels against: a head with two pointed ears over a body, two
/// little feet, and a wing out of each shoulder, a fan of four bony fingers with the membrane scalloped between their
/// tips, its panels a lighter and a darker red in turn. `s` is its scale in art pixels; the wings run from `upper` to `lower` (radians from straight out, up
/// negative) and reach `len` times `s`; `lit` lights the wings' leading edges, while they are spread.
private struct HordeBat {
    var cx: Double, cy: Double, s: Double
    var upper: Double, lower: Double, len: Double
    var body: Bool, lit: Bool

    enum Part { case none, membrane, shade, rib, lit }

    /// Which part of the bat the point (`x`, `y`) is on.
    func part(_ x: Double, _ y: Double) -> Part {
        if body && onBody(x, y) { return .membrane }
        let dy = y - (cy - 0.2 * s)
        for side in [1.0, -1.0] {
            let dx = (x - (cx + side * 0.9 * s)) * side
            let a = atan2(dy, dx)
            guard a >= upper && a <= lower else { continue }
            let d = (dx * dx + dy * dy).squareRoot()
            let step = (lower - upper) / 3
            let u = (a - upper) / step
            let between = u - u.rounded(.down)
            let reach: Double = len * s * (1 - 0.2 * sin(between * .pi))
            guard d < reach else { continue }
            let rib = max(1.0, 0.16 * s)
            let off = min(between, 1 - between) * step * d
            if lit && (a - upper) * d < max(1.0, 0.1 * s) { return .lit }
            if off < rib / 2 { return .rib }
            return Int(u) % 2 == 0 ? .membrane : .shade
        }
        return .none
    }

    /// The head, ears, body and feet.
    private func onBody(_ x: Double, _ y: Double) -> Bool {
        let hx = (x - cx) / (1.3 * s), hy = (y - (cy - 1.2 * s)) / (1.2 * s)
        if hx * hx + hy * hy < 1 { return true }
        let bx = (x - cx) / (1.1 * s), by = (y - (cy + 0.8 * s)) / (1.8 * s)
        if bx * bx + by * by < 1 { return true }
        let top = cy - 3.2 * s, tall = 1.8 * s
        if y > top && y < top + tall {
            let wide = 0.5 * s * (y - top) / tall
            if abs(x - (cx - 0.85 * s)) < wide || abs(x - (cx + 0.85 * s)) < wide { return true }
        }
        let foot = 0.18 * s
        if y > cy + 2.2 * s && y < cy + 3.2 * s && (abs(x - (cx - 0.45 * s)) < foot || abs(x - (cx + 0.45 * s)) < foot) { return true }
        return false
    }
}
