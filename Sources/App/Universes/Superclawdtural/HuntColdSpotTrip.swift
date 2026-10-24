import CoreGraphics
import Foundation

// Cold Spot (`HuntWipe.coldSpot`): the sign a ghost is in the room. The lights flicker and the place goes cold and
// blue, breath fogs in the air, frost creeps in from the corners in feathery crystals until the whole picture is
// iced over, then it cracks across and falls away in shards onto the new place.

extension HuntTrip {
    /// A frame `k` (0…1) of the Cold Spot, over the whole of `r`. The lights stutter off and on, the old place taking
    /// a cold blue cast (0–0.2); three long breaths of fog blow out low down and drift (0.13–0.66); frost creeps in from
    /// the four corners first and then along the edges, a white rim at its front, feathery crystals growing ahead of
    /// the fill, thin and see-through at first and thick white-blue behind, closing over the middle just in time
    /// (0.1–0.64); the ice cracks out from the middle in dark blue lines (0.6–0.7), and the shards drop away, the
    /// middle first, turning over as they fall onto the new place (0.68–1).
    func drawColdSpot(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        if k >= 1 { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let W = Double(w), H = Double(h)
        let creep = Self.span(k, 0.08, 0.63)
        let reach = 1.12 * creep * (0.5 + 0.5 * creep)   // creeps slowly at first, then closes in just as it's due to crack
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

        // Breath: three long breaths of fog low down, each a plume of puffs blown out to the right, swelling and
        // rising as it goes and fading; each puff a pale rim, a white body and a bright top, on a layer of their own
        // so they read as one cloud.
        let fog = PixelCanvas(w, h)
        for (i, puff) in [(at: 0.13, x: 0.26, y: 0.72), (at: 0.27, x: 0.58, y: 0.68), (at: 0.4, x: 0.38, y: 0.74)].enumerated() {
            let age = (k - puff.at) / 0.26
            guard age > 0, age < 1 else { continue }
            let a = ((1 - age * age) * 0.875 * 8).rounded() / 8
            guard a > 0 else { continue }
            let s = H / 112
            fog.clear()
            var blobs: [(x: Int, y: Int, r: Int)] = []
            for j in 0..<6 {
                let out = Double(j) / 5                                     // how far along the plume
                guard age * 1.6 > out else { continue }                     // blown out a puff at a time
                let px = W * puff.x + (age * 26 + out * 30) * s
                let py = H * puff.y - (age * 8 + out * 6 + noise(i * 9 + j) * 3) * s
                blobs.append((Int(px), Int(py), Int((3 + age * 8 + out * 7) * s)))
            }
            for b in blobs { fog.circle(b.x, b.y, b.r + 1, C(0x86A2C2)) }
            for b in blobs { fog.circle(b.x, b.y, b.r, C(0xE2ECF6)) }
            for b in blobs { fog.circle(b.x - b.r / 4, b.y - b.r / 3, max(1, b.r / 2), C(0xFFFFFF)) }
            c.paste(fog, alpha: a)
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
        // In the window's short strip the top and bottom edges count as further in, so the frost doesn't close the
        // strip off from above and below long before it reaches the middle from the sides.
        func depth(_ x: Int, _ y: Int) -> Double {
            let u = min(Double(x), W - 1 - Double(x)) / (W / 2)
            let v0 = min(Double(y), H - 1 - Double(y)) / (H / 2), v = art.wide ? pow(v0, 0.6) : v0
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
        // gravity, the middle ones first, drifting a little outwards and tumbling as it goes.
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
        // Each shard's drop: how far it has fallen, and how far it has turned about its own middle as it goes, one
        // way or the other.
        let drops: [(dx: Double, dy: Double, turn: Double)] = seeds.enumerated().map { i, s in
            let out = ((s.x - cx) * (s.x - cx) + (s.y - cy) * (s.y - cy)).squareRoot() / far
            let fall = max(0, k - (0.68 + 0.14 * out + noise(i * 5 + 9) * 0.04))
            let spin = (noise(i * 5 + 11) > 0.5 ? 1.0 : -1.0) * (0.5 + noise(i * 5 + 12) * 0.5)
            return ((s.x - cx) / far * fall * W * 0.5, fall * fall * H * 30, spin * fall * 4.5)
        }
        // A shard's own pixel at (x, y): a crack along its border as the cracks spread, and once it's falling a white
        // lit top edge and a deeper blue underside, so each piece reads as a slab of ice.
        func shard(_ x: Int, _ y: Int, _ i: Int, falling: Bool) -> Px {
            let along = ((Double(x) - cx) * (Double(x) - cx) + (Double(y) - cy) * (Double(y) - cy)).squareRoot() / far
            let border = (x + 1 < w && cell[y * w + x + 1] != i) || (y + 1 < h && cell[(y + 1) * w + x] != i)
            if border && along < crack * 1.05 { return C(0x2A5A8E) }
            guard falling else { return ice(x, y) }
            if y > 0 && cell[(y - 1) * w + x] != i { return C(0xFFFFFF) }
            if y + 1 < h && cell[(y + 1) * w + x] != i { return C(0x6A94BE) }
            return ice(x, y)
        }
        // The pieces still in place, then the falling ones over them, turning as they drop.
        var box = [(x0: Int, y0: Int, x1: Int, y1: Int)](repeating: (Int.max, Int.max, Int.min, Int.min), count: seeds.count)
        for y in 0..<h {
            for x in 0..<w {
                let i = cell[y * w + x]
                if drops[i].dy == 0 && drops[i].dx == 0 { c.px(x, y, shard(x, y, i, falling: false)); continue }
                box[i] = (min(box[i].x0, x), min(box[i].y0, y), max(box[i].x1, x), max(box[i].y1, y))
            }
        }
        for i in seeds.indices.sorted(by: { drops[$0].dy < drops[$1].dy }) where box[i].x0 <= box[i].x1 {
            let d = drops[i], p = seeds[i], cs = cos(d.turn), sn = sin(d.turn)
            // Its box once turned and moved, then each pixel there traced back to the shard's own.
            let half = Double(max(box[i].x1 - box[i].x0, box[i].y1 - box[i].y0)) * 0.75 + 2
            let mx = Double(box[i].x0 + box[i].x1) / 2 - p.x, my = Double(box[i].y0 + box[i].y1) / 2 - p.y
            let tx = p.x + d.dx + mx * cs - my * sn, ty = p.y + d.dy + mx * sn + my * cs
            let y0 = max(0, Int(ty - half)), y1 = min(h - 1, Int(ty + half))
            let x0 = max(0, Int(tx - half)), x1 = min(w - 1, Int(tx + half))
            guard y0 <= y1, x0 <= x1 else { continue }
            for y in y0...y1 {
                for x in x0...x1 {
                    let ux = Double(x) - p.x - d.dx, uy = Double(y) - p.y - d.dy
                    let sx = Int((p.x + ux * cs + uy * sn).rounded()), sy = Int((p.y - ux * sn + uy * cs).rounded())
                    guard sx >= 0, sy >= 0, sx < w, sy < h, cell[sy * w + sx] == i else { continue }
                    c.px(x, y, shard(sx, sy, i, falling: true))
                }
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
