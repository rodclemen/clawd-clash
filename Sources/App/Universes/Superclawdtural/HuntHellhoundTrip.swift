import CoreGraphics
import Foundation

// Hellhound (`HuntWipe.hellhound`): the invisible dog. The old place goes dark, something unseen rakes it with its
// claws, three long tears at a time, one rake after another, the picture jolting with each; red eyes glow low in the
// dark between them; and the tears, which show the new place through them, rimmed in hellfire, open up until it's all
// that's left. Eerie, never gory: they're rips in the picture, not wounds.

extension HuntTrip {
    /// A frame `k` (0…1) of the Hellhound, over the whole of `r`. The old place darkens (0–0.5); four rakes rip
    /// across it, at 0.08, 0.22, 0.36 and 0.5, each three curved tears drawn out fast from one end with a spark at the
    /// claw's tip, the picture jolting as it goes; between them a pair of red eyes opens in the dark, blinks and is
    /// gone, somewhere else each time, always on a quiet, dark patch of the old place away from the tears; then
    /// every tear widens, steadily and then faster, and the new place is all there is (0.58–1). The tears' rims are
    /// ember orange, their edges glowing.
    func drawHellhound(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let fw = Double(w), fh = Double(h)
        let open = pow(Self.span(k, 0.58, 1), 1.6)

        // The rakes: where their middles fall, which way they run (radians, 0 is right, y down), when they come.
        let rakes: [(x: Double, y: Double, a: Double, at: Double)] = [
            (0.3, 0.42, 0.75, 0.08), (0.7, 0.4, 2.3, 0.22), (0.48, 0.66, -0.4, 0.36), (0.85, 0.55, 1.95, 0.5),
        ]
        let len = min((fw * fw + fh * fh).squareRoot() * 0.45, fh * 1.25)
        let gap = fh * 0.07                                   // between the three claws of a rake
        struct Tear { let x0, y0, dx, dy, nx, ny, len, bend, reach, base: Double }
        var tears: [Tear] = []
        var tips: [(Double, Double)] = []
        var jolt = 0.0
        for (i, rk) in rakes.enumerated() where k >= rk.at {
            let dx = cos(rk.a), dy = sin(rk.a), nx = -dy, ny = dx
            let bend = gap * 1.1 * (i % 2 == 0 ? 1 : -1)             // claw marks curve, like a swipe
            for j in 0..<3 {
                let off = Double(j - 1) * gap
                let start = Double(j == 1 ? 0 : 1) * len * 0.06         // the middle claw reaches a little further
                let l = len * (j == 1 ? 1 : 0.86)
                let sx = rk.x * fw - dx * len / 2 + nx * off + dx * start, sy = rk.y * fh - dy * len / 2 + ny * off + dy * start
                let reach = Self.ease(Self.span(k, rk.at + Double(j) * 0.012, rk.at + Double(j) * 0.012 + 0.07))
                // A slit at first, opening a little as it settles.
                let settle = Self.span(k, rk.at + 0.05, rk.at + 0.2)
                tears.append(Tear(x0: sx, y0: sy, dx: dx, dy: dy, nx: nx, ny: ny, len: l, bend: bend,
                                  reach: reach, base: 1.0 + 1.6 * settle + gap * 0.45 * Self.ease(Self.span(k, 0.52, 0.72))))
                if reach > 0 && reach < 1 {
                    let t = reach * l, b = sin(reach * .pi) * bend
                    tips.append((sx + nx * b + dx * t, sy + ny * b + dy * t))
                }
            }
            let since = k - rk.at
            if since < 0.06 { jolt = (i % 2 == 0 ? 1 : -1) * (since < 0.03 ? 1 : -0.5) }
        }

        // What each art pixel is: 0 the old place, 1 a tear (the new place), 2 its burning rim, 3 the glow round it.
        // At the end each tear also swells out round its whole length, raggedly, until they swallow the frame: slowly
        // at first, so the last rake's tears get their moment, then faster.
        let swell = pow(Self.span(k, 0.58, 1), 2.2) * max(fw, fh) * 0.75
        var kind = [UInt8](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let px = Double(x) + 0.5, py = Double(y) + 0.5
                let rag = swell > 0 ? (noise((x / 3) * 131 + (y / 3) * 977) - 0.5) * min(6, swell * 0.3) : 0
                var best: UInt8 = 0
                for t in tears where t.reach > 0 {
                    let rx = px - t.x0, ry = py - t.y0
                    let along = rx * t.dx + ry * t.dy
                    let u = along / t.len
                    let uc = min(max(u, 0), t.reach)
                    let side = rx * t.nx + ry * t.ny - sin(uc * .pi) * t.bend
                    let d = abs(side)
                    if swell > 0 {
                        let past = max(0, abs(u - uc)) * t.len
                        let e = (d * d + past * past).squareRoot() - swell - rag
                        if e < 0 { best = 1; break }
                        if e < 1.1 { best = max(best, 2) } else if e < 2.6 { best = max(best, 3) }
                    }
                    guard u > -0.02, u < t.reach + 0.01 else { continue }
                    // Tapered at both ends, widest a third of the way along, where the claw dug in deepest.
                    let taper = pow(max(0, sin(uc * .pi)), 0.6) * (0.55 + 0.45 * sin(uc * .pi * 1.3 + 0.4))
                    let hw = t.base * taper
                    if d < hw { best = 1; break }
                    if d < hw + 1.1 { best = max(best, 2) } else if d < hw + 2.4 { best = max(best, 3) }
                }
                kind[y * w + x] = best
            }
        }

        // The old place, darkening and jolting; through the tears, the new one.
        ctx.setFillColor(huntTripRGB(0x050204)); ctx.fill(r)
        ctx.drawShot(old, in: r.offsetBy(dx: jolt * art.px, dy: 0))
        Self.wash(ctx, 0x080204, 0.2 + 0.4 * Self.ease(Self.span(k, 0, 0.5)), in: r)
        let through = art.runs { x, y in kind[y * w + x] == 1 }
        if !through.isEmpty {
            ctx.saveGState(); ctx.clip(to: through); ctx.drawShot(new, in: r); ctx.restoreGState()
        }

        // Red eyes, low in the dark between the rakes: a pair opens, looks, blinks, and is gone, each pair somewhere
        // new, on the quietest dark patch of the old place that's clear of every tear torn while it's there.
        let eyes = huntHoundEyes(old, fw: fw, fh: fh, rakes: rakes, len: len, gap: gap)
        for e in eyes where k > e.from && k < e.to {
            let s = (k - e.from) / (e.to - e.from)
            let a = (min(1, s * 6) * min(1, (1 - s) * 5) * 4).rounded() / 4
            let blink = s > 0.5 && s < 0.58
            let ex = Int(e.x), ey = Int(e.y)
            guard a > 0, kind[min(h - 1, max(0, ey)) * w + min(w - 1, max(0, ex))] == 0 else { continue }
            c.ellipse(ex, ey, 17, 10, C(0x020001, 0.375 * a))               // the darker dark it's standing in
            c.ellipse(ex, ey, 12, 7, C(0x020001, 0.5 * a))
            for side in [-1, 1] {
                let cx = ex + side * 4
                c.ellipse(cx, ey, 4, 3, C(0xE0200E, 0.3 * a))
                if blink { c.rect(cx - 1, ey, 3, 1, C(0xFF3A1A, a)); continue }
                // Slanted, mean: the inner end lower than the outer.
                c.rect(cx - 1, ey, 3, 1, C(0xFF3A1A, a))
                c.px(cx + (side < 0 ? -1 : 1), ey - 1, C(0xFF3A1A, a))
                c.px(cx - (side < 0 ? -1 : 1), ey + 1, C(0xC01808, a))
                c.px(cx, ey, C(0xFFD8A0, a))
            }
        }

        // The tears' rims and glow, and a spark at every claw's tip while it rips.
        let rim = C(0xFFB040), glow = C(0xE0501A)
        for y in 0..<h {
            for x in 0..<w {
                switch kind[y * w + x] {
                case 2: c.px(x, y, rim)
                case 3: c.px(x, y, glow.alpha(0.375))
                default: break
                }
            }
        }
        for (i, tip) in tips.enumerated() {
            let tx = Int(tip.0), ty = Int(tip.1)
            c.ellipse(tx, ty, 3, 3, C(0xFFB040, 0.5))
            c.rect(tx - 1, ty, 3, 1, C(0xFFF4D0)); c.rect(tx, ty - 1, 1, 3, C(0xFFF4D0))
            for s in 0..<4 {
                let a = noise(i * 13 + s + Int(k * 90)) * 2 * .pi, d = 2 + noise(i * 7 + s * 3 + Int(k * 90)) * 5
                c.px(tx + Int(cos(a) * d), ty + Int(sin(a) * d), C(s % 2 == 0 ? 0xFFD070 : 0xFF7A20))
            }
        }
        // Embers lifting off the open tears as they widen.
        if open > 0 && open < 0.9 {
            for s in 0..<40 {
                let x = Int(noise(s * 11 + 3) * fw), rise = (noise(s * 5 + 1) + k * 2).truncatingRemainder(dividingBy: 1)
                let y = Int(fh - rise * (fh + 8))
                guard x >= 0, x < w, y >= 0, y < h, kind[y * w + x] >= 2 || noise(s * 3) > 0.6 else { continue }
                c.px(x, y, C(s % 3 == 0 ? 0xFFD070 : 0xFF7A20, 1 - open))
            }
        }
        art.show(ctx)
    }

    /// Where the three pairs of eyes go, and when, in art pixels: the old place shrunk to a coarse grid, and for each
    /// pair the grid cell low in the frame that's darkest and plainest (least different from its neighbours), at least
    /// a rake's width clear of every tear torn before the pair is gone, and well away from the pair before it.
    private func huntHoundEyes(_ old: CGImage, fw: Double, fh: Double, rakes: [(x: Double, y: Double, a: Double, at: Double)],
                               len: Double, gap: Double) -> [(x: Double, y: Double, from: Double, to: Double)] {
        let times: [(Double, Double)] = [(0.12, 0.3), (0.27, 0.45), (0.42, 0.6)]
        let gw = 48, gh = max(8, Int((48 * fh / fw).rounded()))
        var lum = [Double](repeating: 0.5, count: gw * gh)
        if let g = CGContext(data: nil, width: gw, height: gh, bitsPerComponent: 8, bytesPerRow: gw * 4,
                             space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
            g.interpolationQuality = .low
            g.draw(old, in: CGRect(x: 0, y: 0, width: gw, height: gh))
            if let d = g.data?.assumingMemoryBound(to: UInt8.self) {
                for i in 0..<(gw * gh) {
                    lum[i] = (0.3 * Double(d[i * 4]) + 0.55 * Double(d[i * 4 + 1]) + 0.15 * Double(d[i * 4 + 2])) / 255
                }
            }
        }
        var out: [(x: Double, y: Double, from: Double, to: Double)] = []
        for (n, t) in times.enumerated() {
            var best = (score: 1e9, x: fw / 2, y: fh / 2)
            for cy in 1..<(gh - 1) {
                let y = (Double(cy) + 0.5) / Double(gh) * fh
                guard y > fh * 0.3, y < fh * 0.74 else { continue }
                for cx in 2..<(gw - 2) {
                    let x = (Double(cx) + 0.5) / Double(gw) * fw
                    guard x > fw * 0.1, x < fw * 0.9 else { continue }
                    if let last = out.last, abs(last.x - x) < fw * 0.22 { continue }
                    // Clear of the tears: far enough from the middle line of every rake torn by now.
                    var clear = true
                    for rk in rakes where rk.at < t.1 {
                        let dx = cos(rk.a), dy = sin(rk.a), px = x - rk.x * fw, py = y - rk.y * fh
                        let along = max(-len / 2, min(len / 2, px * dx + py * dy))
                        let ex = px - dx * along, ey = py - dy * along
                        if (ex * ex + ey * ey).squareRoot() < gap * 2.6 + 14 { clear = false; break }
                    }
                    guard clear else { continue }
                    var busy = 0.0
                    let me = lum[cy * gw + cx]
                    for oy in -1...1 { for ox in -2...2 { busy += abs(lum[(cy + oy) * gw + cx + ox] - me) } }
                    // Dark and plain, and the lower the better: it's a dog.
                    let score = me + busy / 15 * 2 + (0.74 - y / fh) * 0.25 + noise(n * 131 + cy * 17 + cx) * 0.02
                    if score < best.score { best = (score, x, y) }
                }
            }
            out.append((best.x, best.y, t.0, t.1))
        }
        return out
    }
}
