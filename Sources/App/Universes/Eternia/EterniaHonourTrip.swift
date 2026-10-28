import CoreGraphics
import Foundation

// For the Honour of Greyskull (`EterniaWipe.honour`), the second rarest trip: She-Clawd's transformation. A fist comes
// up holding the Sword of Protection high, its jewel flashes, a ribbon of gold and rainbow spirals up the blade to the
// tip and bursts out of it into a whirling rainbow that floods the screen, and the colours settle, band by band, into
// the new place.

extension EterniaTrip {
    /// For the Honour of Greyskull, `k` (0…1) through its own part, over the whole of `r`. The old place dims to
    /// Etheria's plum while She-Clawd's fist rises from the bottom with the Sword of Protection (0–0.22); the red jewel
    /// in its guard flashes (0.22–0.3); a ribbon of rainbow bands edged in gold spirals up the blade from the guard to
    /// the tip, passing behind it and in front, sparkling at its head (0.28–0.56); out of the tip a whirl of gold,
    /// red, orange, yellow, green, blue and violet arms grows, turning, until it floods the screen (0.55–0.8); then
    /// the colours settle, the sword sinking back out of the bottom first and then the bands one by one, each a flat
    /// stripe thinning to nothing with a dark line along its edge, into the new place
    /// (0.8–1).
    func drawHonour(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let u = max(1, h / 80)
        let hx = w / 2, rest = art.wide ? 8 : 14
        let dim = Self.span(k, 0, 0.16), raise = Self.ease(Self.span(k, 0.04, 0.22))
        let jewel = Self.span(k, 0.22, 0.3), climb = Self.ease(Self.span(k, 0.28, 0.56))
        let flood = Self.span(k, 0.55, 0.8), settle = Self.span(k, 0.8, 1)
        let spin = k * 2.4 * 1.6 * (1 - 0.5 * settle)       // turns of the whirl
        // The sword is drawn `su` to a pixel: twice on the window's short strip, so it stays bold there, with a
        // shorter blade so the fist still shows.
        let su = art.wide ? 2 : u, blade = art.wide ? 28 : 35
        let top = rest + Int((1 - raise) * Double(h - rest + 4))
        let tip = (x: Double(hx), y: Double(top + su))

        // Underneath: the old place dimming to plum until the whirl has covered it, then the new one.
        if settle > 0 {
            ctx.drawShot(new, in: r)
        } else {
            ctx.drawShot(old, in: r)
            Self.wash(ctx, 0x2A1438, 0.55 * dim, in: r)
        }

        // The sword, the ribbon round it and the sparkles, on a canvas of their own so the settling can take it away.
        let sw = PixelCanvas(w, h)
        if raise > 0 {
            let guardY = Double(top + (3 + blade) * su), length = guardY - Double(top + 2 * su)
            let head = climb
            // The ribbon: points along a helix up the blade, the half going behind it drawn first.
            var back: [(Int, Int, Px)] = [], front: [(Int, Int, Px)] = []
            if head > 0 {
                let n = Int(length * 3)
                for i in 0...n {
                    let s = Double(i) / Double(n)
                    guard s <= head else { break }
                    let phase = s * 4.5 * 2 * .pi - spin * 2 * .pi
                    let widen = 1 + 0.6 * s
                    let x = Double(hx) + sin(phase) * 8 * Double(su) * widen, y = guardY - s * length
                    let band = Int(s * 28) % 7
                    let p = (Int(x.rounded()), Int(y.rounded()), eterniaHonourBands[band])
                    if cos(phase) < 0 { back.append(p) } else { front.append(p) }
                }
            }
            eterniaRibbon(sw, back, u: su)
            eterniaProtectionSword(sw, hx, top, u: su, blade: blade, jewel: jewel > 0 && jewel < 1 ? jewel : 0)
            eterniaRibbon(sw, front, u: su)
            // Sparkles round the ribbon's head while it climbs, and the jewel's twinkle.
            if head > 0 && head < 1 {
                let y = Int(guardY - head * length)
                for i in 0..<5 {
                    let sx = hx + Int((noise(Int(k * 60) * 7 + i) - 0.5) * 34 * Double(su))
                    let sy = y + Int((noise(Int(k * 60) * 11 + i) - 0.5) * 16 * Double(su))
                    eterniaHonourTwinkle(sw, sx, sy, u: su, size: 1 + i % 2)
                }
            }
            if jewel > 0 && jewel < 1 {
                eterniaHonourTwinkle(sw, hx, Int(guardY) + 2 * su, u: su, size: 2 + Int(sin(jewel * .pi) * 3))
            }
        }

        // The whirl: arms of gold and the rainbow, turning round the sword's tip, growing out of it to the edges with a
        // gold rim; settling, each band thins in turn, gold first and violet last, a quarter at a time, a flat stripe
        // with a dark line along its edge, until only the new place is left.
        let far = eterniaHonourFar(tip, w, h)
        let reach = pow(flood, 1.4) * (far + 4 * Double(u))
        let pitch = 8.0 * Double(u)
        let keep: [Double] = (0..<7).map { j in
            let a: Double = Double(j) / 7 * 0.55
            // In quarters, so a band thins two cells at a time, and gone once it's down to a quarter: it never frays
            // to a thread.
            let q: Double = ((1 - Self.ease(Self.span(settle, a, a + 0.45))) * 4).rounded(.up) / 4
            return q < 0.5 ? 0 : q
        }
        let line = Double(u) / pitch                        // one cell of the grid, as a share of a band
        let sink = Int(Self.ease(Self.span(settle, 0, 0.45)) * Double(h))   // the sword going back down
        for y in 0..<h {
            for x in 0..<w {
                if reach > 0 {
                    // The whirl on a grid of `u`, so it's as chunky as the sword.
                    let gx = Double(x / u * u) + Double(u) / 2, gy = Double(y / u * u) + Double(u) / 2
                    let dx = gx - tip.x, dy = gy - tip.y
                    let d = (dx * dx + dy * dy).squareRoot()
                    if d < reach {
                        let turn = atan2(dy, dx) / (2 * .pi)
                        let v = turn * 14 + d / pitch - spin * 7
                        let band = ((Int(floor(v)) % 7) + 7) % 7
                        let left = keep[band], part = v - floor(v)
                        if part < left {
                            let edge = left < 1 && left - part < line
                            let rim: Bool = reach - d < 2 * Double(u)
                            let face: Px = rim ? eterniaHonourBands[0] : eterniaHonourBands[band]
                            c.px(x, y, edge ? C(0x2A1438) : face)
                        }
                    }
                }
                // The sword and ribbon on top, sinking back out of the bottom first.
                let sy = y - sink
                guard sy >= 0 else { continue }
                let i = (sy * w + x) * 4
                if sw.buf[i + 3] > 0 { c.px(x, y, unpremultiplied(sw, i)) }
            }
        }
        art.show(ctx)
    }
}

/// The whirl's colours: gold, then the rainbow, flat Filmation cel colours.
private let eterniaHonourBands = [C(0xF4C838), C(0xE8323A), C(0xF08A2A), C(0xF8E048), C(0x4CB848), C(0x3A7AD8), C(0x8A4AC8)]

/// How far it is from `p` to the frame's farthest corner.
private func eterniaHonourFar(_ p: (x: Double, y: Double), _ w: Int, _ h: Int) -> Double {
    let dx = max(p.x, Double(w) - p.x), dy = max(p.y, Double(h) - p.y)
    return (dx * dx + dy * dy).squareRoot()
}

/// The ribbon's points, each a square `u` across and a little more, edged in dark gold.
private func eterniaRibbon(_ c: PixelCanvas, _ pts: [(Int, Int, Px)], u: Int) {
    let size = u + 1
    for (x, y, _) in pts { c.rect(x - size / 2 - 1, y - 1, size + 2, u + 2, C(0xA87C1C)) }
    for (x, y, col) in pts { c.rect(x - size / 2, y, size, u, col) }
}

/// The Sword of Protection straight up in She-Clawd's fist, blown up `u` times with its tip's top at (`x`, `top`)
/// and `x` its middle: a broad silver blade `blade` rows long, bevelled bright down its left edge and dark down its
/// right, a dark outline round it all; a wide gold crossguard with its ends curled up and the red jewel in the middle;
/// a short gold grip; her bronze fist round it, a gold bracer, and her forearm down off the bottom. `jewel` (0…1)
/// flashes the jewel pink and white.
private func eterniaProtectionSword(_ c: PixelCanvas, _ x: Int, _ top: Int, u: Int, blade: Int, jewel: Double) {
    let rows = [
        "........kk........",   // the tip
        ".......kWSk.......",
        "......kWLsSk......",
    ] + Array(repeating: ".....kWLLssSk.....", count: blade) + [   // the blade
        "kk..............kk",   // the crossguard, its ends curled up
        "kMkkkkkkkkkkkkkkMk",
        "kGMMMMMkRRkMMMMMgk",
        ".kkkkkkkrrkkkkkkk.",
        ".......kGgk.......",   // the grip
        ".......kMgk.......",
        "...kkkkkkkkkkk....",   // the fist, fingers across
        "..kOOOOOOOOOOdk...",
        "..klOOOOOOOOOdk...",
        "..kddddddddOOdk...",
        "..klOOOOOOOOOdk...",
        "..kddddddddOOdk...",
        "..klOOOOOOOOOdk...",
        "..kddddddddOOdk...",
        "...kOOOOOOOOOk....",
        "...kkkkkkkkkkk....",   // the gold bracer
        "...kGGGGGGMMgk....",
        "...kMMMMMMMMgk....",
        "...kGGGGGGMMgk....",
        "...kkkkkkkkkkk....",
    ]
    let arm = "....kOOOOOOdk....."
    let lit = jewel > 0 && Int(jewel * 8) % 2 == 0
    let pal: [Character: Px] = [
        "k": C(0x1E1828), "W": C(0xF8FAFF), "L": C(0xD8DCE6), "s": C(0xA8ACBA), "S": C(0x6A6E7C),
        "G": C(0xFFE07A), "M": C(0xE8B838), "g": C(0xA87C1C),
        "R": lit ? C(0xFFF0F0) : C(0xE8323A), "r": lit ? C(0xFF8A8A) : C(0x9A1A20),
        "O": clawdOrange, "l": C(0xF09A78), "d": C(0xA8553C),
    ]
    let x0 = x - 9 * u
    func put(_ row: String, _ y: Int) {
        for (i, ch) in row.enumerated() {
            guard let col = pal[ch] else { continue }
            c.rect(x0 + i * u, y, u, u, col)
        }
    }
    for (j, row) in rows.enumerated() { put(row, top + j * u) }
    var y = top + rows.count * u
    while y < c.h { put(arm, y); y += u }
}

/// A little four-pointed star of white with gold tips, `size` arms long, at (`x`, `y`), `u` pixels a dot.
private func eterniaHonourTwinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, u: Int, size: Int) {
    for i in -size...size {
        let col = abs(i) == size ? C(0xF4C838) : C(0xFFFFFF)
        c.rect(x + i * u - u / 2, y - u / 2, u, u, col); c.rect(x - u / 2, y + i * u - u / 2, u, u, col)
    }
}
