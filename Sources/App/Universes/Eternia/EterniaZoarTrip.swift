import CoreGraphics
import Foundation

// Zoar's Flight (`EterniaWipe.zoar`): the Sorceress of Greyskull's falcon. Zoar swoops across the scene seen from
// above, wings spread from the top of the picture to the bottom, and the new place is behind its wings as it goes.

extension EterniaTrip {
    /// A frame `k` (0…1) of Zoar's Flight, over the whole of `r`. Zoar comes in from the left, so big its wing tips reach
    /// the top and the bottom of the picture, its shadow ahead of it on the old place; it crosses in one long swoop,
    /// beating its wings twice (a wide, lit downstroke, then the wings bent back and folded on the upstroke), and the
    /// new place is everywhere behind the wings' trailing edge (0.04–0.88); a few feathers shaken loose drift
    /// down in its wake and are gone (0.3–0.97). Zoar is the Sorceress's own falcon in her art's
    /// colours, with a falcon's shape: broad wings swept back to sharp points, a long fanned tail barred in sky blue,
    /// a small sky-blue head with a dark cheek stripe and a gold hooked beak; white flight feathers tipped in blue,
    /// sky-blue coverts and back, a dark outline round it all.
    func drawZoar(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let s = Double(h) / 112
        let fly = Self.span(k, 0.04, 0.88)
        let move = 0.45 * fly + 0.55 * Self.ease(fly)
        let x0 = -42 * s, x1 = Double(w) + 50 * s
        let X = x0 + (x1 - x0) * move
        let Y = Double(h) / 2 - sin(fly * .pi) * 3 * s
        // Two wingbeats: `lift` 0 at the bottom of each downstroke (wings spread wide and forward), 1 at the top of
        // the upstroke (wings bent back at the wrist, the hands folded in), eased so each pose holds a moment.
        let wave: Double = 0.5 + 0.5 * cos(fly * .pi * 4)
        let lift: Double = wave * wave * (3 - 2 * wave)
        let half = Double(h) / 2 - 7 * s
        let bird = EterniaFalcon(s: s, half: half, lift: lift)

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
                let sx: Double = (7 + 3 * (1 - lift)) * s, sy: Double = (6 + 3 * (1 - lift)) * s   // further below as it pushes up
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
/// is +u) and `v` across it (down the picture is +v), nil off the bird. A falcon's shape: broad wings out from the
/// shoulders, tapering to sharp swept-back points (`half` out either side, at the picture's edges), a long tail fanned
/// out behind, a small round head and a hooked beak. Past its wing tips (the picture's top and bottom rows) the new
/// place trails away behind them. `lift` (0…1) is the wingbeat: at 0 the bottom of the downstroke, the wings spread
/// their widest, reaching forward, lit; at 1 the top of the upstroke, the wings bent back at the wrist, the hands
/// folded in narrow and swept back, a quarter shorter, their outer feathers in shadow.
private struct EterniaFalcon {
    let s: Double, half: Double, lift: Double

    static let white = C(0xF6F6FA), whiteD = C(0xC8D2E4), sky = C(0x6AB8F0), skyL = C(0x9AD8FF)
    static let skyD = C(0x3A7AC0), deep = C(0x24508A), gold = C(0xE8B040), goldD = C(0xA87A20), ink = C(0x1A1638)

    /// How far out along a wing `v` is: 0 at the shoulder, 1 at the tip.
    private func out(_ v: Double) -> Double {
        let span: Double = half * (1 - 0.22 * lift)
        return (abs(v) - 5 * s) / (span - 5 * s)
    }

    /// How far the wing sweeps forward (+) or back (-) at `f` out along it with the beat: forward on the downstroke,
    /// raked well back from the wrist on the upstroke.
    private func sweep(_ f: Double) -> Double {
        let reach: Double = 9 - 23 * lift
        return f * f * s * reach
    }

    /// The wing's leading edge at `f`: out and a little forward to the wrist, then raked hard back to the point.
    private func lead(_ f: Double) -> Double {
        if f < 0.35 { return s * (10 + 6 * f / 0.35) + sweep(f) }
        let g: Double = (f - 0.35) / 0.65
        let fold: Double = 6 * lift * g                       // the hand narrower as it folds
        return s * (16 - 38 * pow(g, 1.35) - fold) + sweep(f)
    }

    /// The wing's trailing edge at `f`: near straight from the body back to the point, a scallop at each feather.
    private func back(_ f: Double) -> Double { s * (-15 - 7 * f + 3 * sin(f * .pi)) + sweep(f) }

    /// Where the new place starts on the row `v` across the bird: behind the wing's trailing edge, or the body's.
    func trail(_ v: Double) -> Double {
        let f = out(v)
        if f <= 0 { return -16 * s }
        if f >= 1 { return back(1) - (abs(v) - half * (1 - 0.22 * lift)) * 1.5 }
        return back(f)
    }

    func paint(_ u: Double, _ v: Double) -> Px? {
        let av = abs(v)
        // The beak: gold, hooked, a short point out from the front of the face, its hooked tip darker.
        let bu: Double = u - 24 * s
        if bu > 0 && bu < 5.5 * s && av < 2.6 * s * (1 - bu / (6 * s)) + 0.5 {
            return bu > 3.5 * s ? Self.goldD : Self.gold
        }
        // The head: small and round, a sky-blue crown, a dark stripe down each cheek, white either side of it.
        let hu: Double = u - 18.5 * s
        if hu * hu + v * v < 36 * s * s {
            if av > 3.4 * s && av < 5 * s && hu > -0.5 * s && hu < 2.5 * s { return Self.ink }
            if av > 3.4 * s && hu < -1 * s && hu > -4 * s { return Self.skyD }
            if av > 4 * s { return Self.white }
            return hu > 2.5 * s ? Self.skyL : Self.sky
        }
        // The body: a long tapering oval, the sky-blue back barred with darker chevrons, white along its flanks.
        let bx: Double = (u + 2 * s) / (17 * s), by: Double = v / (7.5 * s)
        if bx * bx + by * by < 1 {
            if av > 5.5 * s { return Self.white }
            let bar = Int(((u + av * 0.8) / (3.5 * s)).rounded(.down))
            return bar % 3 == 0 ? Self.skyD : Self.sky
        }
        // The tail: a long fan out of the body's rear, its end rounded; white feathers barred in sky blue, a deep-blue
        // band at the tip, and a line between each feather.
        let tu: Double = -u - 12 * s
        let fan: Double = (tu * tu + v * v).squareRoot()
        if tu > 0 && fan < 24 * s && av < 3 * s + tu * 0.36 {
            if fan > 21 * s { return Self.skyD }
            let feather: Double = atan2(v, tu) / 0.16
            if abs(feather - feather.rounded()) * 0.16 * fan < 0.5 && fan > 6 * s { return Self.whiteD }
            if (fan > 11 * s && fan < 13 * s) || (fan > 16 * s && fan < 18 * s) { return Self.sky }
            return Self.white
        }
        // The wings.
        let f = out(v)
        guard f > -0.05 && f < 1 else { return nil }
        let fc = max(0, f)
        let front = lead(fc), rear = back(fc)
        // A rounded tip at the end of each flight feather along the trailing edge.
        let fw: Double = 3.4 * s
        let along: Double = (av / fw).truncatingRemainder(dividingBy: 1) * 2 - 1    // -1…1 across one feather
        let notch: Double = (1 - (1 - along * along).squareRoot()) * 1.6 * s
        guard u < front && u > rear + notch else { return nil }
        let chord: Double = max(0.01, front - rear)
        let dep: Double = front - u                              // how far back from the leading edge
        let q: Double = dep / chord                              // 0 at the leading edge, 1 at the trailing edge
        // The hand: long primaries running out to the point, their outer half dark blue as a falcon's wing tips are,
        // a line between each.
        // On the upstroke the hand is turned up out of the light, a tone darker all over.
        if fc > 0.55 {
            let lines = [0.34, 0.62]
            let tip = fc > 0.78
            let up = lift > 0.55
            if lines.contains(where: { abs(q - $0) * chord < 0.6 }) { return tip || up ? Self.deep : Self.skyD }
            if tip { return up ? Self.deep : Self.skyD }
            if dep < 1.2 { return up ? Self.sky : Self.skyL }
            if dep < 0.3 * chord { return up ? Self.skyD : Self.sky }
            return up ? Self.skyL : Self.white
        }
        // The arm: sky-blue coverts along the front, lit along the edge, a row of darker scallops where they end;
        // white flight feathers behind, a line between each near their ends, their tips banded sky blue.
        let edge: Double = 0.36 * chord + (1 - along * along) * 1.2 * s
        if dep < 1.2 { return Self.skyL }
        if dep < edge - 1.2 * s { return Self.sky }
        if dep < edge { return Self.skyD }
        if u < rear + notch + 2.2 * s { return Self.skyD }
        if q > 0.62 && abs(along) > 0.82 { return Self.whiteD }
        return Self.white
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
