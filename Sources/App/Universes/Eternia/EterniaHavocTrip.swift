import CoreGraphics
import Foundation

// The Havoc Staff (`EterniaWipe.havoc`): Skeleclawd's staff rises into view until its ram's skull fills it, bone and
// curled horns over a purple shaft, as on his own art. Its eyes kindle yellow, forked yellow and violet bolts crack
// out of them across the scene, the scene cracks like glass along them, the staff sinks away, and the shards fall
// out of the frame onto the new place.

extension EterniaTrip {
    /// The Havoc Staff, `k` (0…1) through its own part, over the whole of `r`. The old place dims to a dusk purple as
    /// the staff rises from the bottom edge until the ram's skull fills the view (0–0.28); its eye sockets kindle, a
    /// dull gold, then yellow with white hearts and sparks round them (0.26–0.44); bolts fork out of the eyes to the
    /// edges, yellow ones and violet ones, while cracks spread out from the middle and the whole scene turns to
    /// glass (0.42–0.62); the staff sinks away (0.58–0.7) and the shards fall, the middle ones first, onto the new
    /// place (0.62–1). The skull, bolts and cracks are pixel art; the places are drawn as they are.
    func drawHavoc(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let dim = 0.375 * Self.span(k, 0.04, 0.3)

        // The shards: the frame cut into cells round scattered seeds, each falling on its own clock.
        let seeds = havocSeeds(w: w, h: h)
        let cell = havocCells(seeds, w: w, h: h)
        let fall = Self.span(k, 0.62, 1)
        var drop = [Int](repeating: 0, count: seeds.count), slide = [Int](repeating: 0, count: seeds.count)
        let starts = seeds.map { 0.62 + 0.2 * $0.order }
        if fall > 0 {
            for i in seeds.indices {
                let u = Self.span(k, starts[i], 1)
                let g: Double = u * u * Double(h) * 1.08
                drop[i] = Int(g.rounded())
                slide[i] = Int(((seeds[i].x - Double(w) / 2) * 0.12 * u).rounded())
            }
            ctx.drawShot(new, in: r)
            for i in seeds.indices {
                let rects = havocRuns(cell, i, art: art)
                let dx = CGFloat(slide[i]) * art.px, dy = -CGFloat(drop[i]) * art.px
                ctx.saveGState()
                ctx.clip(to: rects.map { $0.offsetBy(dx: dx, dy: dy) })
                ctx.drawShot(old, in: r.offsetBy(dx: dx, dy: dy))
                Self.wash(ctx, 0x2A1040, dim + 0.125 * Self.span(k, starts[i], 1), in: r.offsetBy(dx: dx, dy: dy))
                ctx.restoreGState()
            }
        } else {
            ctx.drawShot(old, in: r)
            Self.wash(ctx, 0x2A1040, dim, in: r)
        }

        // The cracks: the cells' edges, spreading out from the middle while the bolts fly, then riding their shards.
        let spread = Self.ease(Self.span(k, 0.42, 0.62))
        if spread > 0 {
            let reach = spread * Double(w + h) * 0.62
            let ink = C(0x1A0E24), glint = C(0xFFF2B0), lit = C(0xC8B8F0)
            let mx = Double(w) / 2, my = Double(h) * 0.4
            for y in 0..<h {
                for x in 0..<w {
                    let id = cell[y * w + x]
                    let right = x + 1 < w ? cell[y * w + x + 1] : id
                    let below = y + 1 < h ? cell[(y + 1) * w + x] : id
                    guard right != id || below != id else { continue }
                    let ddx = Double(x) - mx, ddy = (Double(y) - my) * 1.6
                    guard ddx * ddx + ddy * ddy < reach * reach else { continue }
                    let sx = x + slide[id], sy = y + drop[id]
                    c.px(sx, sy, ink)
                    c.px(sx + 1, sy, (x + y) % 3 == 0 ? glint : lit)
                }
            }
        }

        // The staff: up from the bottom edge, the skull filling the view, then down again.
        let s = max(2, min((h - 4) / 23, Int((Double(h) * 0.8 / 23).rounded())))
        let skullW = 30 * s, skullH = 23 * s
        let restY = max(1, (h - skullH) / 2 - s)
        let up = Self.ease(Self.span(k, 0, 0.28)), down = Self.span(k, 0.58, 0.7)
        let lift = up * (1 - down * down)
        let sy = restY + Int(((1 - lift) * Double(h - restY + 2)).rounded())
        let sx = (w - skullW) / 2
        if lift > 0 {
            let kindle = Self.span(k, 0.26, 0.36)
            let shaft = C(0x5A2E7A), shaftL = C(0x7A4A9A), shaftD = C(0x3E1E58)
            c.rect(sx + 12 * s, sy + 22 * s, 6 * s, h, shaftD)
            c.rect(sx + 12 * s + 1, sy + 22 * s, 6 * s - 2, h, shaft)
            c.rect(sx + 13 * s, sy + 22 * s, s, h, shaftL)
            let eye: Px = kindle <= 0 ? C(0x141018) : kindle < 0.5 ? C(0x8A7A20) : C(0xF4F070)
            havocBlocks(c, sx, sy, s, havocSkull, [
                "k": C(0x141018), "H": C(0x8A8478), "h": C(0x5E5A50), "l": C(0xB0AA9A),
                "B": C(0xD8D4C8), "L": C(0xF4F2EA), "d": C(0xA8A496), "K": C(0x141018),
                "E": eye, "n": C(0x2A2420), "T": C(0xF4F2EA),
            ])
            if kindle >= 1 {
                // White hearts in the eyes, and sparks crackling round them.
                let flick = Int(k * 60)
                for side in [0, 1] {
                    let ex = sx + (side == 0 ? 12 : 18) * s, ey = sy + 10 * s + s / 2
                    c.rect(ex - s / 2, ey - s / 2, s, s, C(0xFFFFF0))
                    for j in 0..<5 where noise(flick * 13 + j * 5 + side) > 0.45 {
                        let a = Double(j) * 1.2566 + noise(flick + j) * 0.8
                        let ca = cos(a), sa = sin(a)
                        let d0 = Double(s) * 2.2, d1 = Double(s) * 3.6
                        havocLine(c, Double(ex) + ca * d0, Double(ey) + sa * d0, Double(ex) + ca * d1, Double(ey) + sa * d1,
                                  thick: max(1, s / 3), j % 2 == 0 ? C(0xF4F070) : C(0xB07AE8))
                    }
                }
            }
        }

        // The bolts, forking out of the eyes to the edges, each flickering for a moment.
        if k > 0.42 && k < 0.66 {
            let flick = Int(k * 50)
            for i in 0..<8 {
                let at = 0.42 + 0.025 * Double(i)
                guard k >= at && k < at + 0.11 else { continue }
                let side = i % 2
                let ex = Double(sx + (side == 0 ? 12 : 18) * s), ey = Double(sy + 10 * s) + Double(s) / 2
                let a = (side == 0 ? Double.pi : 0) + (noise(i * 7 + 90) - 0.5) * 2.4
                let len = Double(w + h)
                let violet = i % 3 == 1
                havocBolt(c, ex, ey, ex + cos(a) * len, ey + sin(a) * len, seed: i * 31 + flick, s: s, violet: violet)
            }
        }
        art.show(ctx)
    }
}

/// A shard's seed: where it is, and its place in the falling order (0 first, 1 last), the middle ones first.
private struct HavocSeed { let x: Double, y: Double, order: Double }

/// The seeds the frame cracks round: a loose grid, jittered, so the shards come out about the same size.
private func havocSeeds(w: Int, h: Int) -> [HavocSeed] {
    let cols = max(4, w / 44), rows = max(3, h / 40)
    var out: [HavocSeed] = []
    let cw = Double(w) / Double(cols), ch = Double(h) / Double(rows)
    for j in 0..<rows {
        for i in 0..<cols {
            let n = j * cols + i
            let x = (Double(i) + 0.2 + 0.6 * noise(n * 3 + 700)) * cw
            let y = (Double(j) + 0.2 + 0.6 * noise(n * 3 + 701)) * ch
            let dx = (x - Double(w) / 2) / Double(w), dy = (y - Double(h) / 2) / Double(h)
            let far = min(1, (dx * dx + dy * dy).squareRoot() * 1.5)
            out.append(HavocSeed(x: x, y: y, order: min(1, far * 0.7 + noise(n * 3 + 702) * 0.3)))
        }
    }
    return out
}

/// Which shard each art pixel belongs to (the nearest seed), row by row.
private func havocCells(_ seeds: [HavocSeed], w: Int, h: Int) -> [Int] {
    var out = [Int](repeating: 0, count: w * h)
    for y in 0..<h {
        for x in 0..<w {
            var best = 0, bestD = Double.infinity
            for (i, s) in seeds.enumerated() {
                let dx = Double(x) - s.x, dy = Double(y) - s.y
                let d = dx * dx + dy * dy
                if d < bestD { bestD = d; best = i }
            }
            out[y * w + x] = best
        }
    }
    return out
}

/// Shard `i` as rectangles in the frame's coordinates, a run of art pixels to a rectangle.
private func havocRuns(_ cell: [Int], _ i: Int, art: EterniaArt) -> [CGRect] {
    let w = art.w
    return art.runs { x, y in cell[y * w + x] == i }
}

/// A design drawn with each of its dots `s` art pixels square.
private func havocBlocks(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int, _ rows: [String], _ palette: [Character: Px]) {
    for (j, row) in rows.enumerated() {
        for (i, ch) in row.enumerated() {
            guard let col = palette[ch] else { continue }
            c.rect(x + i * s, y + j * s, s, s, col)
        }
    }
}

/// A straight chunky line, `thick` art pixels square at each step.
private func havocLine(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, thick: Int, _ col: Px) {
    let dx = x1 - x0, dy = y1 - y0
    let n = max(1, Int(max(abs(dx), abs(dy)).rounded()))
    for i in 0...n {
        let u = Double(i) / Double(n)
        c.rect(Int((x0 + dx * u).rounded()) - thick / 2, Int((y0 + dy * u).rounded()) - thick / 2, thick, thick, col)
    }
}

/// A forked bolt from (`x0`, `y0`) towards (`x1`, `y1`): jagged legs, a white-gold heart inside a yellow or violet
/// edge, and a fork off it halfway.
private func havocBolt(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, seed: Int, s: Int, violet: Bool) {
    let edge = violet ? C(0x9A5ACC) : C(0xE8C020), core = violet ? C(0xE8D8FF) : C(0xFFF6C0)
    let legs = 9
    var pts: [(Double, Double)] = [(x0, y0)]
    let dx = x1 - x0, dy = y1 - y0
    let len = (dx * dx + dy * dy).squareRoot()
    let nx = -dy / len, ny = dx / len
    for i in 1...legs {
        let u = Double(i) / Double(legs)
        let jog = (noise(seed * 17 + i) - 0.5) * 22
        pts.append((x0 + dx * u + nx * jog, y0 + dy * u + ny * jog))
    }
    let thick = max(2, s / 2 + 1)
    for i in 1..<pts.count {
        havocLine(c, pts[i - 1].0, pts[i - 1].1, pts[i].0, pts[i].1, thick: thick + 2, edge)
    }
    for i in 1..<pts.count {
        havocLine(c, pts[i - 1].0, pts[i - 1].1, pts[i].0, pts[i].1, thick: max(1, thick - 1), core)
    }
    // The fork, off the third joint.
    let f = pts[3]
    let fa = atan2(dy, dx) + (noise(seed * 5 + 3) > 0.5 ? 0.7 : -0.7)
    let fl = len * 0.18
    let fx = f.0 + cos(fa) * fl, fy = f.1 + sin(fa) * fl
    let mid = (f.0 + cos(fa) * fl * 0.5 + nx * 4, f.1 + sin(fa) * fl * 0.5 + ny * 4)
    havocLine(c, f.0, f.1, mid.0, mid.1, thick: thick, edge)
    havocLine(c, mid.0, mid.1, fx, fy, thick: thick, edge)
    havocLine(c, f.0, f.1, mid.0, mid.1, thick: max(1, thick - 2), core)
}

/// The ram's skull on top of the Havoc Staff, front on, 30 dots wide and 23 high: ridged horns sweeping out off
/// the narrow crown and curling round in a spiral either side, the eye sockets (`E`, kindled as it casts) just under
/// them, the long tapering snout with its nostrils, and the teeth. Built from the left half, mirrored, the light only on the left.
private let havocSkull: [String] = {
    let left = [
        "...kkkkkk......",
        ".kkHhHhHhkk..kk",
        "kHhHhHhHhHhkkLB",
        "kHhkkkkkkhHhkLB",
        "kHk.....kkhHkLB",
        "khk......kHhkBB",
        "kHk..kkk.kHkBBB",
        "khk.kHhk.khkBBB",
        "kHkk.kHk.kHkdBB",
        ".kHhkkhkkHkKKBB",
        "..kHhHhHhkKEEBB",
        "...kkkkkkkKKKBB",
        ".........kdBBBB",
        ".........kdBBBB",
        "..........kdBBB",
        "..........kdBBB",
        "..........kdBBB",
        "...........kdBB",
        "...........kdnB",
        "...........kdnB",
        "...........kdBB",
        "............kTk",
        "............kkk",
    ]
    return left.map { $0 + String($0.reversed()).replacingOccurrences(of: "L", with: "B") }
}()
