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
            // Closing, the wings meet down the middle in an inked seam, the line they part along.
            let seam = close > 0, mx = Int(cxEnd.rounded())
            // The outline two art pixels thick once the bat is big, so it holds against the wall of red.
            let o: Double = bat.s >= 10 ? 2 : 1
            // Closing, the wings harden into the Fright Zone's riveted plate from their tips in, the front inked; by
            // the time they meet the whole wall is plate round the red bat, the Horde's emblem on the fortress.
            let front = 4.6 * bat.s * (1 - close)
            let plate = HordePlate(h: h)
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
                    let nb = [bat.part(sx - o, sy), bat.part(sx + o, sy), bat.part(sx, sy - o), bat.part(sx, sy + o)]
                    let onBody = part == .body || part == .bodyS
                    let rim = nb.contains(.none)
                        || (onBody && nb.contains { $0 != .body && $0 != .bodyS && $0 != .eye })
                        || (seam && open <= 0 && !onBody && part != .eye && (x == mx || (o > 1 && x == mx - 1)))
                    let past = close > 0 && !onBody && part != .eye ? bat.past(sx, sy, front) : -1
                    let metal = past > 0
                    let col: Px
                    if rim || (metal && past < o) { col = ink } else if metal {
                        let strut = part == .rib && (bat.part(sx - 1, sy) != .rib || bat.part(sx + 1, sy) != .rib
                            || bat.part(sx, sy - 1) != .rib || bat.part(sx, sy + 1) != .rib)
                        col = plate.colour(Int(sx.rounded(.down)), y, part: part, edge: strut)
                    } else {
                        switch part {
                        case .rib: col = redD
                        case .shade: col = redS
                        case .lit: col = redL
                        case .bodyS: col = redS
                        case .eye: col = ink
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

    enum Part { case none, membrane, shade, rib, lit, body, bodyS, eye }

    /// Which part of the bat the point (`x`, `y`) is on.
    func part(_ x: Double, _ y: Double) -> Part {
        if body, let b = bodyPart(x, y) { return b }
        let dy = y - (cy - 0.2 * s)
        // Each wing keeps to its own half, so that closed they meet down the middle rather than overlap.
        for side in [x < cx ? -1.0 : 1.0] {
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
            let nearest = u.rounded()
            if off < rib / 2 && nearest > 0 && nearest < 3 { return .rib }   // the fingers; the edges are outlined
            return Int(u) % 2 == 0 ? .membrane : .shade
        }
        return .none
    }

    /// How far the point (`x`, `y`) on a wing lies past the scalloped edge that wing would have, reaching `reach`
    /// from its shoulder: negative inside it. The closed wall's plate starts there.
    func past(_ x: Double, _ y: Double, _ reach: Double) -> Double {
        let side: Double = x < cx ? -1 : 1
        let dx = (x - (cx + side * 0.9 * s)) * side, dy = y - (cy - 0.2 * s)
        let u = (atan2(dy, dx) - upper) / ((lower - upper) / 3)
        let between = u - u.rounded(.down)
        let edge: Double = reach * (1 - 0.2 * sin(between * .pi))
        return (dx * dx + dy * dy).squareRoot() - edge
    }

    /// The head, ears, body and feet, shaded down the right; the two slit eyes in the head.
    private func bodyPart(_ x: Double, _ y: Double) -> Part? {
        guard onBody(x, y) else { return nil }
        for side in [-1.0, 1.0] {
            let ex = (x - (cx + side * 0.5 * s)) / (0.34 * s)
            let ey = (y - (cy - 1.25 * s) + side * (x - cx) * 0.25) / (0.15 * s)
            if ex * ex + ey * ey < 1 { return .eye }
        }
        return x > cx + 0.45 * s ? .bodyS : .body
    }

    /// Whether the point is on the head, ears, body or feet.
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

/// The Fright Zone's plate, for the Horde Bat's closed wall: soot-grey plates laid like brick, each lit along its top
/// and left and seamed dark along its bottom and right, a row of rivets under its top edge and a bolt in some, the
/// lower rows of each plate a flat shadow band; the wing's darker panels a tone down, a flat cel shadow side; its bony
/// fingers red girders, like the bands on the smokestacks. `h` is the art's height, which sizes the plates.
private struct HordePlate {
    let ph: Int, pw: Int
    let tone: [Px] = [C(0x1C1C22), C(0x2A2A32), C(0x3A3A44), C(0x4C4C56), C(0x62626C), C(0x7E7E88)]

    init(h: Int) {
        ph = max(10, h / 9)
        pw = ph * 2
    }

    /// The colour at art pixel (`x`, `y`) of a wing `part`; `edge` marks a girder's rim.
    func colour(_ x: Int, _ y: Int, part: HordeBat.Part, edge: Bool) -> Px {
        if part == .rib { return edge ? C(0x7A1410) : C(0xC42418) }
        let base = part == .shade ? 2 : 3
        let row = y / ph, ly = y % ph
        let shifted = x + (row % 2 == 0 ? 0 : pw / 2) + pw * 64
        let col = shifted / pw, lx = shifted % pw
        // Seams dark along the bottom and right, lit along the top and left.
        if ly == ph - 1 || lx == pw - 1 { return tone[base - 2] }
        if ly == 0 || lx == 0 { return tone[base + 1] }
        // A row of rivets just under the top edge: a lit head, its shadow under it.
        let rivet = lx >= 3 && lx <= pw - 4 && (lx - 3) % 5 == 0
        if rivet && ly == 2 { return tone[base + 2] }
        if rivet && ly == 3 { return tone[base - 2] }
        // A bolt in some plates, low and off centre: a lit head and its dark side.
        if (col * 5 + row * 3) % 7 < 2 {
            let bx = lx - pw * 2 / 3, by = ly - ph / 2
            if bx >= 0 && bx < 3 && by >= 0 && by < 3 {
                if bx == 2 || by == 2 { return tone[base - 2] }
                return bx == 0 && by == 0 ? tone[base + 2] : tone[base + 1]
            }
        }
        // The lower rows of each plate in a flat shadow band, so the courses step like the fortress's.
        if ly >= ph - 3 { return tone[base - 1] }
        return tone[base]
    }
}
