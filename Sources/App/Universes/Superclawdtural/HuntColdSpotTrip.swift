import CoreGraphics
import Foundation

// Cold Spot (`HuntWipe.coldSpot`): the sign a ghost is in the room. The lights flicker and the place goes cold and
// blue, breath fogs in the air, frost creeps in from the corners in feathery crystals until the whole picture is
// iced over, then it cracks across and falls away in shards onto the new place.

extension HuntTrip {
    /// A frame `k` (0…1) of the Cold Spot, over the whole of `r`. The lights stutter off and on, the old place taking
    /// a cold blue cast (0–0.2); two breaths of fog puff out low down and drift (0.15–0.55); frost creeps in from the
    /// four corners first and then along the edges, a white rim at its front, feathery crystals growing ahead of the
    /// fill, thin and see-through at first and thick white-blue behind (0.1–0.64); the ice cracks out from the middle
    /// in dark blue lines (0.6–0.7), and the shards drop away, the middle first, onto the new place (0.68–1).
    func drawColdSpot(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        if k >= 1 { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let W = Double(w), H = Double(h)
        let creep = Self.span(k, 0.08, 0.63)
        let reach = 1.75 * creep * (0.5 + 0.5 * creep)   // creeps slowly at first, then closes in
        let iced = k >= 0.64   // the whole picture is under the ice from here: the new place goes in behind it
        let crack = Self.span(k, 0.6, 0.7)

        // Underneath: the old place, flickering and going cold; once it's iced over, the new place.
        if iced {
            ctx.drawShot(new, in: r)
        } else {
            ctx.drawShot(old, in: r)
            Self.wash(ctx, 0x0A1A34, 0.35 * Self.span(k, 0, 0.25), in: r)
            let flicker: [(Double, Double)] = [(0.03, 0.065), (0.09, 0.105), (0.15, 0.185), (0.23, 0.245)]
            if flicker.contains(where: { k >= $0.0 && k < $0.1 }) { Self.wash(ctx, 0x02040A, 0.7, in: r) }
        }

        // Breath: two puffs of fog low down, swelling and drifting off to the right as they fade.
        for (i, puff) in [(at: 0.15, x: 0.32, y: 0.7), (at: 0.32, x: 0.6, y: 0.66)].enumerated() {
            let age = (k - puff.at) / 0.24
            guard age > 0, age < 1 else { continue }
            let a = ((1 - age) * 0.6 * 4).rounded() / 4
            let s = H / 112
            for j in 0..<4 {
                let px = W * puff.x + (age * 16 + Double(j) * 4) * s
                let py = H * puff.y - (age * 6 + noise(i * 9 + j) * 3) * s
                c.circle(Int(px), Int(py), Int((2 + age * 6 + Double(j)) * s), C(0xE6EEF8, a))
            }
        }

        // The ice's own look at every pixel: three pale blues in drifting patches, feathery crystals in white, a
        // glint here and there.
        let tones = [C(0xA8CAE6), C(0xC0DAEE), C(0xD6EAF8)]
        let fern = coldSpotFerns(w, h)
        func ice(_ x: Int, _ y: Int) -> Px {
            if fern[y * w + x] { return C(0xF4FBFF) }
            if noise(x &* 7 &+ y &* 131) > 0.993 { return C(0xFFFFFF) }
            let v = coldSpotValueNoise(Double(x) / 4, Double(y) / 3, 3) * 0.6 + coldSpotValueNoise(Double(x) / 12, Double(y) / 9, 5) * 0.4
            return tones[min(2, Int(v * 3.2))]
        }
        // How far in from the edge a pixel is: 0 in a corner, a little more along an edge, 1 in the middle; the
        // frost covers it once `reach` passes that, with a jagged front.
        func depth(_ x: Int, _ y: Int) -> Double {
            let u = min(Double(x), W - 1 - Double(x)) / (W / 2), v = min(Double(y), H - 1 - Double(y)) / (H / 2)
            let m = 0.55 * min(u, v) + 0.45 * max(u, v)
            return reach - m - (coldSpotValueNoise(Double(x) / 5, Double(y) / 4, 17) - 0.5) * 0.16
        }

        if !iced {
            // The frost creeping in: a white rim at its front, a deeper blue just behind it so it shows on a bright
            // place, see-through near the front and solid further in. The crystals run on ahead of the fill.
            for y in 0..<h {
                for x in 0..<w {
                    let d = depth(x, y)
                    if d <= 0 {
                        if fern[y * w + x] && d > -0.09 { c.px(x, y, C(0xEAF6FF, 0.75)) }
                        continue
                    }
                    if d < 0.025 { c.px(x, y, C(0xFFFFFF)); continue }
                    if d < 0.05 { c.px(x, y, C(0x5E90C0)); continue }
                    c.px(x, y, ice(x, y).alpha(d < 0.15 ? 0.4 : d < 0.32 ? 0.6 : d < 0.55 ? 0.8 : 1))
                }
            }
        }

        // The shards: the ice in pieces, cracked from the middle outwards. Each is a cell round a point on a jittered
        // grid; the crack lines show along their borders as they spread from the middle, then each drops away under
        // gravity, the middle ones first, drifting a little outwards as it goes.
        guard crack > 0 else { art.show(ctx); return }
        let cols = art.wide ? 9 : 5, rows = art.wide ? 3 : 4
        var seeds: [(x: Double, y: Double)] = []
        for j in 0..<rows {
            for i in 0..<cols {
                let n = j * cols + i
                seeds.append(((Double(i) + 0.2 + noise(n * 3 + 1) * 0.6) * W / Double(cols),
                              (Double(j) + 0.2 + noise(n * 3 + 2) * 0.6) * H / Double(rows)))
            }
        }
        let cx = W / 2, cy = H / 2, far = (cx * cx + cy * cy).squareRoot()
        var cell = [Int](repeating: 0, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                var best = 0, bd = Double.infinity
                for (i, s) in seeds.enumerated() {
                    let dx = Double(x) - s.x, dy = (Double(y) - s.y) * 1.3
                    let d = dx * dx + dy * dy
                    if d < bd { bd = d; best = i }
                }
                cell[y * w + x] = best
            }
        }
        let shifts: [(dx: Int, dy: Int)] = seeds.enumerated().map { i, s in
            let out = ((s.x - cx) * (s.x - cx) + (s.y - cy) * (s.y - cy)).squareRoot() / far
            let fall = max(0, k - (0.68 + 0.14 * out + noise(i * 5 + 9) * 0.04))
            return (Int((s.x - cx) / far * fall * W * 0.5), Int(fall * fall * H * 30))
        }
        for y in 0..<h {
            for x in 0..<w {
                let i = cell[y * w + x]
                let along = ((Double(x) - cx) * (Double(x) - cx) + (Double(y) - cy) * (Double(y) - cy)).squareRoot() / far
                let border = (x + 1 < w && cell[y * w + x + 1] != i) || (y + 1 < h && cell[(y + 1) * w + x] != i)
                let top = y > 0 && cell[(y - 1) * w + x] != i
                let col: Px = border && along < crack * 1.05 ? C(0x2A5A8E) : top && shifts[i].dy > 0 ? C(0xFFFFFF) : ice(x, y)
                c.px(x + shifts[i].dx, y + shifts[i].dy, col)
            }
        }
        // A cold white flash where it gives, just as it cracks.
        if crack > 0 && crack < 0.4 { c.circle(Int(cx), Int(cy), Int(H * 0.08 * (1 + crack * 4)), C(0xFFFFFF, 0.5)) }
        art.show(ctx)
    }

    /// The frost's feathery crystals, as a mask over the art: long spines growing in from the four corners and from
    /// along the edges towards the middle, with short twigs off them at an angle, all wavering a little.
    private func coldSpotFerns(_ w: Int, _ h: Int) -> [Bool] {
        var mask = [Bool](repeating: false, count: w * h)
        let W = Double(w), H = Double(h)
        func plot(_ x: Double, _ y: Double) {
            let xi = Int(x.rounded()), yi = Int(y.rounded())
            if xi >= 0, yi >= 0, xi < w, yi < h { mask[yi * w + xi] = true }
        }
        func spine(_ x0: Double, _ y0: Double, _ angle: Double, _ length: Double, _ seed: Int, twigs: Bool) {
            var x = x0, y = y0, a = angle
            for s in 0..<Int(length) {
                plot(x, y)
                a += (noise(seed * 31 + s) - 0.5) * 0.18
                x += cos(a); y += sin(a)
                guard twigs, s % 4 == 2, s > 3 else { continue }
                let side = s % 8 == 2 ? 1.0 : -1.0
                spine(x, y, a + side * 0.8, max(2, (length - Double(s)) * 0.22 + noise(seed + s) * 4), seed * 7 + s, twigs: false)
            }
        }
        let corners: [(Double, Double)] = [(0, 0), (W - 1, 0), (0, H - 1), (W - 1, H - 1)]
        for (ci, p) in corners.enumerated() {
            let toMid = atan2(H / 2 - p.1, W / 2 - p.0)
            for j in 0..<5 {
                let a = toMid + (Double(j) - 2) * 0.32 + (noise(ci * 13 + j) - 0.5) * 0.2
                spine(p.0, p.1, a, H * (0.45 + noise(ci * 17 + j) * 0.35), ci * 50 + j, twigs: true)
            }
        }
        // Along the top and bottom edges, a spine every so often, growing inwards.
        let along = max(2, Int(W / 60))
        for i in 0..<along {
            let x = (Double(i) + 0.5 + (noise(i * 5) - 0.5) * 0.5) * W / Double(along)
            spine(x, 0, .pi / 2 + (noise(i * 7) - 0.5) * 0.8, H * 0.3, 900 + i, twigs: true)
            spine(x, H - 1, -.pi / 2 + (noise(i * 9) - 0.5) * 0.8, H * 0.3, 950 + i, twigs: true)
        }
        return mask
    }
}

/// Smooth value noise in 0…1: random values on a unit grid, eased between (for the frost's patches and its front).
private func coldSpotValueNoise(_ x: Double, _ y: Double, _ seed: Int) -> Double {
    let x0 = floor(x), y0 = floor(y)
    let fx = x - x0, fy = y - y0
    let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
    func at(_ i: Double, _ j: Double) -> Double { noise((Int(i) &* 7919 &+ Int(j) &* 104_729 &+ seed &* 31) & 0xFFFFF) }
    let a = at(x0, y0), b = at(x0 + 1, y0), c = at(x0, y0 + 1), d = at(x0 + 1, y0 + 1)
    return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy
}
