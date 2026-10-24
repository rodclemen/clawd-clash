import CoreGraphics
import Foundation

// Angel Light (`HuntWipe.angelLight`): an angel arriving, the way the show does it. Bare bulbs hanging over the old
// place flicker and pop one after another in showers of sparks; a blinding white light rises up the picture; on it,
// the shadow of a great pair of wings spreads from a Clawd-shaped shadow in the middle, the way Clawdstiel's wings show
// on the barn wall; and the light dies down on the new place, the wings fading last.

extension HuntTrip {
    /// A frame `k` (0…1) of Angel Light, over the whole of `r`. Four bulbs swing down on their cords and the room's
    /// light stutters (0–0.08); the bulbs pop in turn, each a white flash and a spray of falling sparks, the place a
    /// shade darker and bluer after each, as a room goes when its lights die (0.08–0.34); white light rises from the
    /// floor in stepped bands, rays fanning up through it from below, until the frame is white (0.3–0.52); the shadow
    /// stands up in it and its wings swing open either side of him, feather over feather, rimmed in pale gold so they
    /// still show once the light is gone (0.48–0.72); the white fades on the new place (0.62–0.9), and the wings fade
    /// after it (0.78–1).
    func drawAngelLight(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let pops: [(at: Double, x: Double, cord: Double)] = [(0.1, 0.22, 0.14), (0.16, 0.71, 0.08), (0.23, 0.45, 0.18), (0.3, 0.88, 0.11)]
        let popped = pops.filter { k >= $0.at }.count
        let rise = Self.span(k, 0.3, 0.52)
        let unblind = Self.ease(Self.span(k, 0.62, 0.9))
        let spread = Self.ease(Self.span(k, 0.48, 0.72))
        let fadeWings = Self.span(k, 0.78, 1)

        // Underneath: the old place, its lights stuttering and going out a bulb at a time; the new one once it's white.
        // The dark comes down as a deep blue multiplied over it, in eighths, so a bright place (Heaven) goes to a
        // blue dusk rather than flat grey, and a dark one goes darker still.
        if k < 0.52 {
            ctx.drawShot(old, in: r)
            let frame = Int(k * 60)
            let stutter = k > 0.03 && k < 0.34 && noise(frame * 7 + 3) > 0.62 ? 0.3 : 0
            let dim = (min(0.8, Double(popped) * 0.16 + stutter) * 8).rounded() / 8
            if dim > 0 {
                ctx.saveGState()
                ctx.setBlendMode(.multiply)
                let blue = Self.mix(0xFFFFFF, 0x1A2250, dim)
                ctx.setFillColor(huntTripRGB(UInt32(blue.r) << 16 | UInt32(blue.g) << 8 | UInt32(blue.b)))
                ctx.fill(r)
                ctx.restoreGState()
            }
        } else {
            ctx.drawShot(new, in: r)
        }

        // The bulbs on their cords, lit and flickering until each pops, then a jagged broken stub.
        let drop = Self.ease(Self.span(k, 0, 0.08))
        if k < 0.52 {
            for (i, b) in pops.enumerated() {
                let bx = Int(b.x * Double(w)), len = Int(b.cord * Double(h) * drop)
                guard len > 0 else { continue }
                huntAngelBulb(c, bx, len, lit: k < b.at ? noise(Int(k * 60) * 13 + i * 5) > 0.25 : nil)
                // The pop: a white flash, and sparks flying out and falling.
                let t = k - b.at, cy = len + 7
                if t >= 0 && t < 0.035 {
                    let f = 1 - t / 0.035
                    c.ellipse(bx, cy, 16, 16, C(0xFFF4C8, 0.3 * f))
                    c.ellipse(bx, cy, 9, 9, C(0xFFF4C8, 0.4 * f))
                    for d in -9...9 { c.px(bx + d, cy, C(0xFFFFFF, abs(d) < 4 ? 1 : f)); c.px(bx, cy + d, C(0xFFFFFF, abs(d) < 4 ? 1 : f)) }
                    for d in -4...4 { c.px(bx + d, cy + d, C(0xFFF0B0)); c.px(bx + d, cy - d, C(0xFFF0B0)) }
                    c.rect(bx - 1, cy - 1, 3, 3, C(0xFFFFFF))
                }
                if t >= 0 && t < 0.16 {
                    for s in 0..<18 {
                        let a = noise(i * 97 + s * 7) * 2 * .pi, v = 30 + noise(i * 31 + s * 3) * 60
                        let tt = t * 2.0                                       // seconds, near enough
                        let sx = Double(bx) + cos(a) * v * tt, sy = Double(cy) + sin(a) * v * tt * 0.6 + 260 * tt * tt
                        let age = t / 0.16
                        let col = age < 0.3 ? C(0xFFF6C0) : age < 0.65 ? C(0xFFC040) : C(0xE86A1A)
                        c.px(Int(sx), Int(sy), col)
                        if age < 0.5 { c.px(Int(sx - cos(a) * 1.5), Int(sy - sin(a) * 1.0), col.alpha(0.6)) }
                    }
                }
            }
        }

        // The white light, rising from the floor in stepped bands, rays fanning up through it from a point below the
        // middle of the frame: some wide, some thin, gaps between, each softer at its edges.
        let white = C(0xFFFCF0), ray = C(0xFFF2C6)
        if rise > 0 && unblind < 1 {
            let top = Double(h) * (1.35 - 1.6 * rise)           // where the band of full white has got to
            let sx = Double(w) / 2, sy = Double(h) * 1.3
            let sway = 0.04 * sin(k * 5)
            for y in 0..<h {
                // Full white below the line, thinning out in steps over a third of the frame above it, and rays
                // standing up out of it, reaching higher.
                let above = max(0, top - Double(y)) / (Double(h) * 0.35)
                let a = (rise >= 1 ? 1 : max(0, 1 - above)) * (1 - unblind)
                let rayA = (rise >= 1 ? 1 : max(0, 1 - above * 0.45)) * (1 - unblind)
                guard rayA > 0 else { continue }
                // Once the white is all the way up the rays are lost in it: an even row.
                if rise >= 1 {
                    let q = (a * 8).rounded() / 8
                    if q > 0 { c.rect(0, y, w, 1, white.alpha(q)) }
                    continue
                }
                let dy = sy - Double(y) - 0.5
                for x in 0..<w {
                    let lane = (atan2(Double(x) + 0.5 - sx, dy) + sway) * 9
                    let n = Int(lane.rounded()), off = abs(lane - lane.rounded())
                    let width = noise(n * 17 + 5) > 0.3 ? 0.07 + 0.2 * noise(n * 29 + 1) : 0
                    let glow = off < width * 0.55 ? 0.85 : off < width ? 0.6 : off < width * 1.5 ? 0.3 : 0
                    let v = max(a, rayA * glow)
                    let q = (v * 8).rounded() / 8
                    if q > 0 { c.px(x, y, (glow > 0 && q < 1 ? ray : white).alpha(q)) }
                }
            }
        }

        // The shadow: a Clawd standing in the middle, wings opening from his back.
        if spread > 0 && fadeWings < 1 {
            huntAngelShadow(c, w: w, h: h, wide: art.wide, spread: spread, fade: fadeWings, light: 1 - unblind)
        }
        art.show(ctx)
    }

    /// A bare bulb hanging on its cord from the top, its socket `len` rows down: the cord, a brass socket, and a pear of
    /// glass with a dark edge so it shows on a bright place, lit (a filament and a warm halo), off, or (`lit` nil)
    /// broken, a few jagged shards left in the socket.
    private func huntAngelBulb(_ c: PixelCanvas, _ bx: Int, _ len: Int, lit: Bool?) {
        let edge = C(0x2A2218)
        c.rect(bx, 0, 1, len, C(0x3A322A))
        c.rect(bx - 3, len - 1, 7, 5, edge)                                  // the socket
        c.rect(bx - 2, len, 5, 3, C(0x9A8C70)); c.rect(bx - 2, len, 5, 1, C(0xC8BA98)); c.rect(bx - 2, len + 2, 5, 1, C(0x6A604E))
        let top = len + 3
        guard let lit else {
            for (dx, n) in [(-2, 3), (-1, 1), (0, 2), (1, 1), (2, 3)] {
                c.rect(bx + dx, top, 1, n + 1, edge); c.rect(bx + dx, top, 1, n, C(0xC8C0B0))
            }
            return
        }
        let glass = lit ? C(0xFFE6A0) : C(0x9A8A5A)
        if lit { c.ellipse(bx, top + 5, 13, 12, C(0xFFD27A, 0.18)); c.ellipse(bx, top + 5, 8, 8, C(0xFFE2A0, 0.3)) }
        let shape = ["..xxx..", ".xxxxx.", "xxxxxxx", "xxxxxxx", "xxxxxxx", ".xxxxx.", "..xxx.."]
        for (j, row) in shape.enumerated() {
            for (i, ch) in row.enumerated() where ch == "x" {
                c.px(bx - 3 + i, top + j, glass)
            }
        }
        // The dark edge: every glass pixel's empty neighbour.
        for (j, row) in shape.enumerated() {
            let cells = Array(row)
            for i in 0..<cells.count where cells[i] == "x" {
                for (di, dj) in [(-1, 0), (1, 0), (0, 1)] {
                    let ni = i + di, nj = j + dj
                    let empty = nj >= shape.count || ni < 0 || ni >= cells.count || Array(shape[nj])[ni] != "x"
                    if empty { c.px(bx - 3 + ni, top + nj, edge) }
                }
            }
        }
        c.px(bx - 2, top + 2, C(0xFFFFFF)); c.px(bx - 2, top + 3, C(0xFFFFFF, lit ? 1 : 0.5))
        // The filament, a little zigzag, white-hot when lit.
        let fil = lit ? C(0xFFFFFF) : C(0x5A4E36)
        c.px(bx - 1, top + 3, fil); c.px(bx, top + 4, fil); c.px(bx + 1, top + 3, fil); c.rect(bx, top + 1, 1, 2, C(0x6A604E))
    }

    /// The wings' shadow and the body's, on the art: a Clawd-shaped shadow in the middle and two great wings swinging
    /// open from his shoulders across the frame, deep cool shadow on the white light, with a pale gold rim round all of
    /// it so it still reads on a dark place once the light has gone. Each wing is built of feathers, not one blot: a
    /// row of long pointed flight feathers fanning out from the wrist, the shorter ones hanging from the arm, and two
    /// scalloped rows of coverts over them, every feather parted from the next by a deeper line. He stands in front of
    /// them, his own shadow a shade deeper with the rim between him and the wings and his eyes left light, so he
    /// never gets lost in them. In the window's short strip the wings spread flatter, not stretched. `spread` how far
    /// open, `fade` how far gone, `light` how much of the white is still up.
    private func huntAngelShadow(_ c: PixelCanvas, w: Int, h: Int, wide: Bool, spread: Double, fade: Double, light: Double) {
        let fadeQ = ((1 - fade) * 4).rounded() / 4
        guard fadeQ > 0 else { return }
        let fw = Double(w), fh = Double(h)
        let flat = wide ? 0.6 : 1.0
        let feathers = huntAngelFeathers(flat: flat)
        // The wing's length (from the shoulder to the farthest tip is about 1.15 of it), as big as the frame allows:
        // a body as wide as half of it, the wings' rise above the shoulder and his legs below it.
        let up = 0.62 * flat, down = 0.42
        let L = min(fh * 0.9 / (up + down), fw * 0.96 / 2.7)
        let sb = L * 0.025                                                 // art pixels a sprite pixel of his body
        let rootY = (fh - (up + down) * L) / 2 + up * L
        let ox = fw / 2 - 28 * sb, oy = rootY - 28 * sb
        // Swinging open: from folded down behind him to spread, growing as they go.
        let swing = -75 * (1 - spread) * .pi / 180, grow = L * (0.45 + 0.55 * spread)
        let cosS = cos(swing), sinS = sin(swing)

        // What each pixel is: 0 nothing, 1 his body, 2 his eyes, 3 and on a feather (its number + 3).
        let x0 = max(0, Int(fw / 2 - 1.2 * L * (0.45 + 0.55 * spread) - 14 * sb)), x1 = min(w, w - x0)
        guard x0 < x1 else { return }
        var id = [Int16](repeating: 0, count: w * h)
        // The wings, rooted at his shoulders, the left one and its mirror: each feather filled in over its own box,
        // in order, so each lies over the last.
        for side in [-1.0, 1.0] {
            let rootX = ox + (side < 0 ? 21 : 35) * sb
            /// A point of the wing's own frame (unswung, in wing lengths) on the art.
            func onArt(_ along: Double, _ lift: Double) -> (Double, Double) {
                let ux = grow * (along * cosS - lift * sinS), uy = grow * (along * sinS + lift * cosS)
                return (rootX + ux * side, rootY - uy)
            }
            for (i, f) in feathers.enumerated() {
                let a = onArt(f.x - f.dx * f.wd, f.y - f.dy * f.wd), b = onArt(f.x + f.dx * f.len, f.y + f.dy * f.len)
                let pad = f.wd * grow + 2
                let bx0 = max(side < 0 ? x0 : w / 2, Int(min(a.0, b.0) - pad)), bx1 = min(side < 0 ? w / 2 : x1, Int(max(a.0, b.0) + pad) + 1)
                let by0 = max(0, Int(min(a.1, b.1) - pad)), by1 = min(h, Int(max(a.1, b.1) + pad) + 1)
                guard bx0 < bx1, by0 < by1 else { continue }
                for y in by0..<by1 {
                    for x in bx0..<bx1 {
                        let ux = (Double(x) + 0.5 - rootX) * side, uy = rootY - Double(y) - 0.5
                        let px = (ux * cosS + uy * sinS) / grow - f.x, py = (-ux * sinS + uy * cosS) / grow - f.y
                        let t = (px * f.dx + py * f.dy) / f.len
                        guard t > -f.wd / f.len, t < 1 else { continue }
                        let s = abs(-px * f.dy + py * f.dx)
                        // Rounded at the root, tapering to a point at the tip.
                        let half = t < 0 ? f.wd : f.wd * (1 - t * t * t).squareRoot() * (1 - 0.3 * t)
                        if s < half { id[y * w + x] = Int16(i + 3) }
                    }
                }
            }
        }
        // His body over them: body, arm nubs, four legs, Clawd's own layout (Characters.swift), eyes and all.
        let legs: [Double] = [19, 23, 31, 35]
        for y in stride(from: max(0, Int(oy + 25 * sb)), to: min(h, Int(oy + 45 * sb)), by: 1) {
            for x in stride(from: max(0, Int(ox + 14 * sb)), to: min(w, Int(ox + 42 * sb)), by: 1) {
                let sx = (Double(x) + 0.5 - ox) / sb, sy = (Double(y) + 0.5 - oy) / sb
                if (sx >= 18 && sx < 38 && sy >= 26 && sy < 38) || (sy >= 33 && sy < 36 && ((sx >= 15 && sx < 18) || (sx >= 38 && sx < 41)))
                    || (sy >= 36 && sy < 44 && legs.contains { sx >= $0 && sx < $0 + 2 }) {
                    let eye = sy >= 29 && sy < 32 && ((sx >= 22 && sx < 24) || (sx >= 32 && sx < 34))
                    id[y * w + x] = eye ? 2 : 1
                }
            }
        }

        let shade = C(0x2A2E44), deep = C(0x161828), rim = C(0xFFE3A0), body = C(0x10111C)
        let rimA = fadeQ * (0.55 + 0.45 * (1 - light))
        for y in 0..<h {
            for x in x0..<x1 {
                let me = id[y * w + x]
                guard me > 0 else { continue }
                let l = x > 0 ? id[y * w + x - 1] : 0, r = x < w - 1 ? id[y * w + x + 1] : 0
                let u = y > 0 ? id[(y - 1) * w + x] : 0, d = y < h - 1 ? id[(y + 1) * w + x] : 0
                let outside = l == 0 || r == 0 || u == 0 || d == 0
                let byWing = me <= 2 && (l >= 3 || r >= 3 || u >= 3 || d >= 3)
                if outside || byWing {
                    // The outside edge, and the line between him and the wings, in the rim's gold.
                    c.px(x, y, rim.alpha(rimA))
                } else if me == 2 {
                    c.px(x, y, rim.alpha(fadeQ * (0.45 + 0.4 * light)))
                } else if me == 1 {
                    c.px(x, y, body.alpha(fadeQ * (0.45 + 0.45 * light)))
                } else if l > me || r > me || u > me || d > me {
                    // Where a feather lies under the next: deeper shadow on the white, picked out in the rim's gold
                    // once it's gone.
                    c.px(x, y, light > 0.5 ? deep.alpha(fadeQ * (0.35 + 0.55 * light)) : rim.alpha(fadeQ * 0.6))
                } else {
                    c.px(x, y, shade.alpha(fadeQ * (0.3 + 0.5 * light)))
                }
            }
        }
    }

    /// The left wing's feathers, spread, in wing lengths from its root at his shoulder (x out, y up), drawn in order,
    /// each over the last: the shorter flight feathers hanging from the arm, the long ones fanning out from the wrist
    /// (the outermost reaching up and out), then two rows of coverts over the arm and a leading edge along its top.
    /// `flat` lowers the rise for the window's strip, so the wings spread wide without being stretched.
    private func huntAngelFeathers(flat: Double) -> [(x: Double, y: Double, dx: Double, dy: Double, len: Double, wd: Double)] {
        var out: [(x: Double, y: Double, dx: Double, dy: Double, len: Double, wd: Double)] = []
        func add(_ x: Double, _ y: Double, _ deg: Double, _ len: Double, _ wd: Double) {
            let a = deg * .pi / 180
            out.append((x, y, cos(a), sin(a), len, wd))
        }
        // The arm: its top edge from the shoulder up to the wrist, and on along the hand.
        func arm(_ u: Double) -> Double { (u < 0.5 ? 0.36 * sin(u / 0.5 * .pi / 2) : 0.36 + 0.08 * (u - 0.5) / 0.2) * flat }
        // Secondaries, inner to outer, hanging down and a little out, overlapping like slats.
        for i in 0..<6 {
            let t = Double(i) / 5, u = 0.05 + 0.42 * t
            add(u, arm(u) - 0.06, -96 + 26 * t, 0.36, 0.1)
        }
        // Primaries, inner to outer, fanning from down-and-out to out-and-up, the outer ones longest.
        for i in 0..<6 {
            let t = Double(i) / 5, u = 0.48 + 0.14 * t
            add(u, arm(u) - 0.06, (-52 + 70 * t) * (t > 0.7 ? flat : 1), 0.42 + 0.22 * t, 0.095)
        }
        // Coverts: a row of short round feathers along the arm, pointing down and out, and the leading edge above.
        for i in 0..<7 {
            let u = 0.03 + 0.095 * Double(i)
            add(u, arm(u) - 0.01, -72, 0.2, 0.085)
        }
        for i in 0..<8 {
            let u = 0.085 * Double(i)
            add(u, arm(u) + 0.02, atan2(arm(u + 0.085) - arm(u), 0.085) * 180 / .pi, 0.12, 0.06)
        }
        return out
    }
}
