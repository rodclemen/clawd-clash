import CoreGraphics
import Foundation

// Angel Light (`HuntWipe.angelLight`): an angel arriving, the way the show does it. Bare bulbs hanging over the old
// place flicker and pop one after another in showers of sparks; a blinding white light rises up the picture; on it,
// the shadow of a great pair of wings spreads from a Clawd-shaped shadow in the middle, the way Clawdstiel's wings show
// on the barn wall; and the light dies down on the new place, the wings fading last.

extension HuntTrip {
    /// A frame `k` (0…1) of Angel Light, over the whole of `r`. Four bulbs swing down on their cords and the room's
    /// light stutters (0–0.08); the bulbs pop in turn, each a white flash and a spray of falling sparks, the place a
    /// shade darker after each (0.08–0.34); white light rises from the floor in stepped bands with rays through it,
    /// until the frame is white (0.3–0.52); the shadow stands up in it and its wings open out across the frame,
    /// feathers and all, rimmed in pale gold so they still show once the light is gone (0.48–0.72); the white fades
    /// on the new place (0.62–0.9), and the wings fade after it (0.78–1).
    func drawAngelLight(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let pops: [(at: Double, x: Double, cord: Double)] = [(0.1, 0.22, 0.16), (0.16, 0.71, 0.1), (0.23, 0.45, 0.2), (0.3, 0.88, 0.13)]
        let popped = pops.filter { k >= $0.at }.count
        let rise = Self.span(k, 0.3, 0.52)
        let unblind = Self.ease(Self.span(k, 0.62, 0.9))
        let spread = Self.ease(Self.span(k, 0.48, 0.72))
        let fadeWings = Self.span(k, 0.78, 1)

        // Underneath: the old place, its lights stuttering and going out a bulb at a time; the new one once it's white.
        if k < 0.52 {
            ctx.drawShot(old, in: r)
            let frame = Int(k * 60)
            let stutter = k > 0.03 && k < 0.34 && noise(frame * 7 + 3) > 0.62 ? 0.3 : 0
            Self.wash(ctx, 0x05060C, min(0.75, Double(popped) * 0.14 + stutter), in: r)
        } else {
            ctx.drawShot(new, in: r)
        }

        // The bulbs on their cords, lit and flickering until each pops, then a jagged broken stub.
        let drop = Self.ease(Self.span(k, 0, 0.08))
        if k < 0.52 {
            for (i, b) in pops.enumerated() {
                let bx = Int(b.x * Double(w)), len = Int(b.cord * Double(h) * drop)
                guard len > 0 else { continue }
                c.rect(bx, 0, 1, len, C(0x3A322A))
                c.rect(bx - 1, len, 3, 2, C(0x8A8070))                     // the socket
                if k < b.at {
                    let on = noise(Int(k * 60) * 13 + i * 5) > 0.25
                    let glass = on ? C(0xFFE6A0) : C(0x9A8A5A)
                    if on { c.ellipse(bx, len + 4, 7, 7, C(0xFFD27A, 0.25)) }
                    c.rect(bx - 2, len + 2, 5, 3, glass); c.rect(bx - 1, len + 5, 3, 1, glass)
                    c.px(bx - 1, len + 2, C(0xFFFFFF))
                } else {
                    c.px(bx - 2, len + 2, C(0xB8B0A0)); c.px(bx + 2, len + 2, C(0xB8B0A0)); c.px(bx, len + 3, C(0xB8B0A0))
                    c.px(bx - 1, len + 2, C(0x6A6458)); c.px(bx + 1, len + 2, C(0x6A6458))
                }
                // The pop: a white flash, and sparks flying out and falling.
                let t = k - b.at
                if t >= 0 && t < 0.035 {
                    let f = 1 - t / 0.035
                    c.ellipse(bx, len + 3, 9, 9, C(0xFFF4C8, 0.35 * f))
                    for d in -5...5 { c.px(bx + d, len + 3, C(0xFFFFFF, abs(d) < 3 ? 1 : f)); c.px(bx, len + 3 + d, C(0xFFFFFF, abs(d) < 3 ? 1 : f)) }
                    for d in -2...2 { c.px(bx + d, len + 3 + d, C(0xFFF0B0)); c.px(bx + d, len + 3 - d, C(0xFFF0B0)) }
                }
                if t >= 0 && t < 0.16 {
                    for s in 0..<14 {
                        let a = noise(i * 97 + s * 7) * 2 * .pi, v = 25 + noise(i * 31 + s * 3) * 55
                        let tt = t * 2.0                                       // seconds, near enough
                        let sx = Double(bx) + cos(a) * v * tt, sy = Double(len + 3) + sin(a) * v * tt * 0.6 + 260 * tt * tt
                        let age = t / 0.16
                        let col = age < 0.3 ? C(0xFFF6C0) : age < 0.65 ? C(0xFFC040) : C(0xE86A1A)
                        c.px(Int(sx), Int(sy), col)
                        if age < 0.5 { c.px(Int(sx - cos(a) * 1.5), Int(sy - sin(a) * 1.0), col.alpha(0.6)) }
                    }
                }
            }
        }

        // The white light, rising from the floor in stepped bands, rays standing up through it.
        let white = C(0xFFFCF0), ray = C(0xFFF2C6)
        if rise > 0 && unblind < 1 {
            let top = Double(h) * (1.35 - 1.6 * rise)           // where the band of full white has got to
            for y in 0..<h {
                // Full white below the line, thinning out in steps over a third of the frame above it, and rays
                // standing up out of it, reaching higher.
                let above = max(0, top - Double(y)) / (Double(h) * 0.35)
                let a = (rise >= 1 ? 1 : max(0, 1 - above)) * (1 - unblind)
                let rayA = (rise >= 1 ? 1 : max(0, 1 - above * 0.45)) * (1 - unblind)
                guard rayA > 0 else { continue }
                for x in 0..<w {
                    // Rays in lanes across the frame, some wide, some thin, some lanes dark, drifting a little.
                    let lane = Double(x) / Double(w) * 13 + 0.25 * sin(k * 4)
                    let n = Int(lane.rounded()), roll = noise(n * 17 + 5)
                    let inRay = roll > 0.3 && abs(lane - lane.rounded()) < 0.04 + 0.12 * noise(n * 29 + 1)
                    let v = inRay ? max(a, rayA * 0.85) : a
                    let q = (v * 8).rounded() / 8
                    if q > 0 { c.px(x, y, (inRay && q < 1 ? ray : white).alpha(q)) }
                }
            }
        }

        // The shadow: a Clawd standing at the bottom middle, wings opening from his back.
        if spread > 0 && fadeWings < 1 {
            huntAngelShadow(c, w: w, h: h, spread: spread, fade: fadeWings, light: 1 - unblind)
        }
        art.show(ctx)
    }

    /// The wings' shadow and the body's, on the art: a Clawd-shaped shadow standing at the bottom middle and two great
    /// wings opening from his shoulders right across the frame, deep cool shadow on the white light, with a pale gold
    /// rim round all of it so it still reads on a dark place once the light has gone. `spread` how far open, `fade`
    /// how far gone, `light` how much of the white is still up.
    private func huntAngelShadow(_ c: PixelCanvas, w: Int, h: Int, spread: Double, fade: Double, light: Double) {
        let rows = huntAngelWing.map { Array($0) }
        let pw = rows[0].count, ph = rows.count
        // The body in sprite units (the 72×52 character canvas), feet on the bottom edge, a bit over a third as tall
        // as the frame; the wings at their own, much bigger scale.
        // The wings keep the stage's proportions (a row 1.25 times a column), as big as the frame allows and in the
        // middle of it, their tips near the sides. The body is smaller than on stage, so the wings dwarf him, and its
        // shadow is thrown up on the light with theirs.
        let fw = Double(w), fh = Double(h)
        let rowFull = min(fh * 0.8 / Double(ph), (fw * 0.47 - fh * 0.08) / Double(pw) * 1.25)
        let rootY = fh / 2 - Double(ph) * rowFull / 2 + 6 * rowFull
        let sb = rowFull / 1.25 * 0.6
        let ox = fw / 2 - 28 * sb, oy = rootY - 28 * sb
        let vy = rowFull * (0.6 + 0.4 * spread)                              // art pixels a pattern row
        // A column: the stage's proportion where the frame is tall; the window's strip is too short for that to
        // reach across it, so there they stretch out sideways, up to nearly twice as long.
        let colFull = max(rowFull / 1.25, min((fw * 0.47 - fh * 0.08) / Double(pw), rowFull / 1.25 * 1.8))
        let hx = colFull * (0.2 + 0.8 * spread)
        // Lifting a little as they open, the tips rising.
        let tilt = 7 * spread * .pi / 180, cosT = cos(tilt), sinT = sin(tilt)

        /// Whether the wing pattern covers (u, v), read smoothly between its cells so the big wing's edges curve.
        func wing(_ u: Double, _ v: Double) -> Character? {
            let u0 = u - 0.5, v0 = v - 0.5
            let i = Int(floor(u0)), j = Int(floor(v0)), fu = u0 - floor(u0), fv = v0 - floor(v0)
            func at(_ a: Int, _ b: Int) -> Double {
                guard a >= 0, a < pw, b >= 0, b < ph else { return 0 }
                return rows[b][a] == "." ? 0 : 1
            }
            let top = at(i, j) * (1 - fu) + at(i + 1, j) * fu, bottom = at(i, j + 1) * (1 - fu) + at(i + 1, j + 1) * fu
            guard top * (1 - fv) + bottom * fv > 0.5 else { return nil }
            let ci = min(pw - 1, max(0, Int(u))), cj = min(ph - 1, max(0, Int(v)))
            // Where feathers part, and the two rows of coverts across the wing, scalloped.
            let s = u / 2.2 - floor(u / 2.2), scallop = 2.4 * s * (1 - s)          // each feather's rounded end
            let covert = u < Double(pw) - 3 && ((v > 3.9 + scallop && v < 4.25 + scallop) || (v > 7.2 + scallop && v < 7.55 + scallop))
            return rows[cj][ci] == "w" || covert ? "w" : "W"
        }
        func inside(_ x: Int, _ y: Int) -> Character? {
            let ax = Double(x) + 0.5, ay = Double(y) + 0.5
            let sx = (ax - ox) / sb, sy = (ay - oy) / sb
            // Body, arm nubs, four legs.
            if sx >= 18 && sx < 38 && sy >= 26 && sy < 38 { return "B" }
            if sy >= 33 && sy < 36 && ((sx >= 15 && sx < 18) || (sx >= 38 && sx < 41)) { return "B" }
            if sy >= 36 && sy < 44 { for lx in [19.0, 23, 31, 35] where sx >= lx && sx < lx + 2 { return "B" } }
            // The wings, from huntAngelWing and its mirror, rooted at his shoulders.
            for side in [-1.0, 1.0] {
                let rootX = ox + (side < 0 ? 23 : 33) * sb
                let out = (ax - rootX) * side
                guard out > -sb else { continue }
                let up = rootY - ay
                let along = out * cosT + up * sinT, lift = -out * sinT + up * cosT
                if let ch = wing(Double(pw) - along / hx, 6 - lift / vy) { return ch }
            }
            return nil
        }
        let shade = C(0x2A2E44), deep = C(0x161828), rim = C(0xFFE3A0)
        let fadeQ = ((1 - fade) * 4).rounded() / 4
        guard fadeQ > 0 else { return }
        for y in 0..<h {
            for x in 0..<w {
                guard let ch = inside(x, y) else { continue }
                let edge = inside(x - 1, y) == nil || inside(x + 1, y) == nil || inside(x, y - 1) == nil || inside(x, y + 1) == nil
                if edge {
                    c.px(x, y, rim.alpha(fadeQ * (0.55 + 0.45 * (1 - light))))
                } else if ch == "w" {
                    // The feather lines: deeper shadow on the white, picked out in the rim's gold once it's gone.
                    c.px(x, y, light > 0.5 ? deep.alpha(fadeQ * (0.3 + 0.6 * light)) : rim.alpha(fadeQ * 0.6))
                } else {
                    c.px(x, y, shade.alpha(fadeQ * (0.3 + 0.5 * light)))
                }
            }
        }
    }
}

/// The left wing, spread, its root on the right where it meets the back: the shape of HuntKit.swift's `huntWing`
/// (the angels' wing shadows on stage), kept here so the trip draws the same wings at its own size. `w` marks where
/// two feathers part, a shade deeper.
private let huntAngelWing = [
    ".........WWWWWWW......",
    "......WWWWWWWWWWWW....",
    "....WWWWWWWWWWWWWWWW..",
    "..WWWWWWWWWWWWWWWWWWW.",
    ".WWWWWWWWWWWWWWWWWWWWW",
    "WWWWWWWWWWWWWWWWWWWWWW",
    "WWWWwWWWWwWWWWWWWWWWWW",
    "WWWWwWWWWwWWWWwWWWWWWW",
    "WWW.wWWW.wWWWWwWWWWWWW",
    "WWW..WWW..WWWWwWWWWWW.",
    "WW...WWW...WWW.WWWWWW.",
    ".W....WW...WWW..WWWW..",
    "......WW....WW...WW...",
    ".......W.....W........",
]
