import CoreGraphics
import Foundation

// Zoar's Flight (`EterniaWipe.zoar`): the Sorceress of Greyskull's falcon. Zoar swoops across the scene seen from
// above, wings spread from the top of the picture to the bottom, and the new place is behind its wings as it goes.

extension EterniaTrip {
    /// A frame `k` (0…1) of Zoar's Flight, over the whole of `r`. Zoar comes in from the left, so big its wings run off
    /// the top and the bottom of the picture, its shadow ahead of it on the old place; it crosses in one long swoop,
    /// beating its wings twice, and the new place is everywhere behind their trailing edge (0.04–0.88); a few feathers
    /// shaken loose drift down in its wake and are gone (0.3–0.97). Zoar is the Sorceress's own falcon in her art's
    /// colours: white flight feathers tipped in deep blue, sky-blue coverts and back, a gold hooked beak, and the
    /// show's orange and red along the leading edge of the wings.
    func drawZoar(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let s = Double(h) / 112
        let fly = Self.span(k, 0.04, 0.88)
        let move = 0.45 * fly + 0.55 * Self.ease(fly)
        let x0 = -42 * s, x1 = Double(w) + 50 * s
        let X = x0 + (x1 - x0) * move
        let Y = Double(h) / 2 - sin(fly * .pi) * 3 * s
        let beat = sin(fly * .pi * 4)
        let bird = EterniaFalcon(s: s, half: Double(h) / 2 + 20 * s, beat: beat)

        // The new place behind the wings' trailing edge, the old one ahead of it.
        ctx.drawShot(old, in: r)
        if fly > 0 {
            let behind = art.runs { x, y in
                Double(x) + 0.5 < X + bird.trail(Double(y) + 0.5 - Y)
            }
            if !behind.isEmpty {
                ctx.saveGState(); ctx.clip(to: behind); ctx.drawShot(new, in: r); ctx.restoreGState()
            }
        }
        if fly >= 1 { ctx.drawShot(new, in: r) }

        // The falcon, its shadow first: the same shape, a little ahead and below, on whatever it passes over.
        if fly > 0 && fly < 1 {
            let lo = max(0, Int(X - 50 * s)), hi = min(w, Int(X + 52 * s))
            if lo < hi {
                let shade = C(0x140A2A, 0.375)
                let sx = 7 * s, sy = 6 * s
                for y in 0..<h {
                    for x in lo..<hi where bird.paint(Double(x) + 0.5 - X - sx, Double(y) + 0.5 - Y - sy) != nil {
                        c.px(x, y, shade)
                    }
                }
                // The bird itself, with a dark outline round it.
                let line = C(0x1A1638)
                for y in 0..<h {
                    for x in lo..<hi {
                        let u = Double(x) + 0.5 - X, v = Double(y) + 0.5 - Y
                        if let col = bird.paint(u, v) {
                            c.px(x, y, col)
                        } else if bird.paint(u + 1, v) != nil || bird.paint(u - 1, v) != nil
                                    || bird.paint(u, v + 1) != nil || bird.paint(u, v - 1) != nil {
                            c.px(x, y, line)
                        }
                    }
                }
            }
        }

        // Feathers shaken loose: each falls and sways from where the wings were, then is gone.
        for i in 0..<7 {
            let born = 0.26 + Double(i) * 0.06
            let life = 0.3
            let a = (k - born) / life
            guard a > 0 && a < 1 else { continue }
            let at = x0 + (x1 - x0) * (0.45 * Self.span(born, 0.04, 0.88) + 0.55 * Self.ease(Self.span(born, 0.04, 0.88)))
            let fx = at - 24 * s - noise(i * 7 + 3) * 10 * s + sin(a * 7 + Double(i)) * 4 * s
            let fy = Double(h) * (0.1 + 0.8 * noise(i * 7 + 5)) + a * 26 * s
            eterniaZoarFeather(c, Int(fx), Int(fy), big: s > 1.2, blue: i % 3 == 1, tilt: sin(a * 7 + Double(i)) > 0)
        }
        art.show(ctx)
    }
}

/// Zoar from above, facing right, centred on its body: `paint(u, v)` is the colour at `u` along its flight (forward
/// is +u) and `v` across it (down the picture is +v), nil off the bird. `half` is how far the wings reach either side,
/// past the edges of the picture; `beat` (-1…1) sweeps the wing tips back and forward.
private struct EterniaFalcon {
    let s: Double, half: Double, beat: Double

    static let white = C(0xF6F6FA), whiteD = C(0xC8D2E4), sky = C(0x6AB8F0), skyL = C(0x9AD8FF)
    static let skyD = C(0x3A7AC0), deep = C(0x24508A), orange = C(0xF08A30), red = C(0xC83A2A)
    static let gold = C(0xE8B040), goldD = C(0xA87A20), ink = C(0x1A1638)

    /// How far out along a wing `v` is: 0 at the shoulder, 1 at the tip.
    private func out(_ v: Double) -> Double { (abs(v) - 6 * s) / (half - 6 * s) }

    /// The wing's leading edge at `f` out along it: out and forward to the wrist, then raked back to the tip.
    private func lead(_ f: Double) -> Double {
        let sweep: Double = beat * f * f * 9 * s
        if f < 0.42 { return s * (12 + 8 * f / 0.42) + sweep }
        let g: Double = (f - 0.42) / 0.58
        return s * (20 - 38 * pow(g, 1.3)) + sweep
    }

    /// The wing's trailing edge at `f`, without the gaps between the primaries.
    private func back(_ f: Double) -> Double {
        let sweep: Double = beat * f * f * 9 * s
        let bow: Double = sin(min(f, 1) * .pi * 0.82)
        return s * (-14 - 14 * bow) + sweep
    }

    /// Where the new place starts on the row `v` across the bird: behind the wing's trailing edge, or the body's.
    func trail(_ v: Double) -> Double {
        let f = out(v)
        if f <= 0 { return -16 * s }
        let rear = back(min(f, 1))
        return gap(f, v) ? rear + 3.5 * s : rear
    }

    /// Whether row `v` is one of the gaps between the long primaries at the wing tip.
    private func gap(_ f: Double, _ v: Double) -> Bool { f > 0.6 && Int(abs(v) / (3 * s)) % 2 == 0 }

    func paint(_ u: Double, _ v: Double) -> Px? {
        let av = abs(v)
        // The head: a round sky-blue crown, white cheeks with a dark falcon's stripe, the eyes either side.
        let hu = u - 24 * s
        if hu * hu + v * v < 64 * s * s {
            if av > 4.6 * s && hu > -2 * s && hu < 3 * s { return Self.ink }
            if av > 5.4 * s && hu < -2 * s { return Self.ink }
            if av > 3.6 * s { return Self.white }
            return hu > 4 * s ? Self.skyL : Self.sky
        }
        // The beak: gold, hooked, out from the front of the face.
        let bu = u - 31 * s
        if bu > 0 && bu < 8 * s && av < 3.4 * s * (1 - bu / (8.5 * s)) + 0.5 {
            return bu > 5.5 * s ? Self.goldD : Self.gold
        }
        // The body: a long oval, the sky-blue back with darker chevrons, white along its sides.
        let bx: Double = u / (22 * s), by: Double = v / (9.5 * s)
        if bx * bx + by * by < 1 {
            if av > 7 * s { return Self.white }
            let row = Int((u / (4 * s) + av / (3 * s)).rounded(.down))
            return row % 3 == 0 ? Self.skyD : Self.sky
        }
        // The tail: fanned out behind, white, a sky-blue band across it, its tip deep blue.
        let tu = -u - 17 * s
        if tu > 0 && tu < 22 * s && av < (4 + 7 * tu / (22 * s)) * s {
            if tu > 19 * s { return Self.deep }
            if tu > 13 * s && tu < 16 * s { return Self.sky }
            return Int(av / (2 * s)) % 2 == 0 ? Self.white : Self.whiteD
        }
        // The wings.
        let f = out(v)
        guard f > -0.05 && f < 1 else { return nil }
        let fc = max(0, f)
        let front = lead(fc), rear = back(fc)
        guard u < front && u > rear else { return nil }
        // The gaps between the long primaries at the tip.
        let d = front - u
        if gap(fc, v) && u < rear + 3.5 * s { return nil }
        if d < 1.5 * s { return Self.red }
        if d < 3.5 * s { return Self.orange }
        if d < 10 * s { return Int(av / (2.5 * s)) % 2 == 0 && Int(d / (2 * s)) % 2 == 0 ? Self.skyD : Self.sky }
        if u < rear + 3.5 * s { return Self.deep }
        return Int(av / (3 * s)) % 3 == 0 ? Self.whiteD : Self.white
    }
}

/// A loose feather: a white (or blue) quill lying one way or the other, with a dark outline.
private func eterniaZoarFeather(_ c: PixelCanvas, _ x: Int, _ y: Int, big: Bool, blue: Bool, tilt: Bool) {
    let body = blue ? EterniaFalcon.sky : EterniaFalcon.white, tip = blue ? EterniaFalcon.skyD : EterniaFalcon.whiteD
    let rows = tilt ? ["kkk....", "kbbkk..", ".kbbbkk", "..kktTk", "....kk."] : ["....kkk", "..kkbbk", "kkbbbk.", "kTtkk..", ".kk...."]
    let pal: [Character: Px] = ["k": EterniaFalcon.ink, "b": body, "t": tip, "T": EterniaFalcon.deep]
    if big {
        for (j, row) in rows.enumerated() {
            for (i, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + i * 2, y + j * 2, 2, 2, col) } }
        }
    } else {
        c.pattern(x, y, rows, pal)
    }
}
