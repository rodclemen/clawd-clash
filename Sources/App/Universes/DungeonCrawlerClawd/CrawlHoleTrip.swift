import CoreGraphics
import Foundation

// Hole (`CrawlWipe.hole`), Donut's spell, likelier with her: a black pit opens under the scene, everything drops
// through and lands in the new place.

extension CrawlTrip {
    /// Hole, `k` (0…1) through its own part (1.8 s), over the whole of `r`. A spark of Donut's hot pink magic winks
    /// on in the middle of the floor (0–0.1) and opens into a pit: a flat black oval lying on the floor, its rim a
    /// band of hot pink with a pale pink lip and a glow round it, so it reads on the darkest place, the pink light
    /// catching the top of its far wall, sparkles running round it. It widens until it's past both sides of the
    /// frame, deepening a little as it comes (0.06–0.36). Then everything drops in: the view falls into the pit, the
    /// old place and the pit's near rim going up past and away (0.26–0.46); down through the dark, pink streaks
    /// rushing up past (0.24–0.7); the new place comes up from below, faster and faster (0.58–0.84), and lands with
    /// a bump (0.84–0.92), a puff of dust and pink sparks on its floor settling away (to 0.98).
    func drawHole(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let t = k * CrawlWipe.hole.effect
        let tick = Int(t / 0.05)
        let open = Self.ease(Self.span(k, 0.06, 0.36))
        let fall = Self.span(k, 0.26, 0.46)
        let rise = Self.span(k, 0.58, 0.84), land = Self.span(k, 0.84, 0.92)

        // The pit: an oval lying on the floor, widening until it's past both sides and deepening a little as it comes
        // nearer; then the view drops into it, and the old place and the pit's near rim go up past and away.
        let floorY = Double(h) * (art.wide ? 0.8 : 0.78)
        let cx = Double(w) / 2
        let rx = 1.5 + (Double(w) * 0.62 - 1.5) * pow(open, 1.2)
        let ry = min(rx * (0.26 + 0.2 * open), Double(h) * 0.42)
        let lift = pow(fall, 1.8) * (floorY + ry + 6)
        let cy = floorY - lift
        // How far a pixel is inside the rim, in pixels (negative outside): the oval's own distance, near enough.
        func depth(_ x: Int, _ y: Int) -> Double {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let f = dx * dx / (rx * rx) + dy * dy / (ry * ry)
            let gx = dx / (rx * rx), gy = dy / (ry * ry)
            return (1 - f) / max(0.0001, 2 * (gx * gx + gy * gy).squareRoot())
        }

        // Down the hole: the dark, and pink streaks rushing up past.
        let dark = C(0x140820)
        if fall > 0 {
            c.rect(0, 0, w, h, dark)
            let streaks = Self.span(k, 0.24, 0.7)
            if streaks > 0 && streaks < 1 {
                let count = max(20, w * h / 900)
                for i in 0..<count {
                    let len = 5 + Int(noise(i * 5 + 2) * 10)
                    let loop = h + len + 8
                    let y0 = Int(noise(i * 5 + 1) * Double(loop)) - Int(t * Double(h) * (2.2 + noise(i * 5 + 3)))
                    let y = ((y0 % loop) + loop) % loop - len
                    let x = Int(noise(i * 5) * Double(w))
                    let thick = i % 4 == 0 ? 2 : 1
                    c.rect(x, y, thick, len, i % 3 == 0 ? C(0xFFB0DC) : C(0xE0409A))
                    c.rect(x, y, thick, 2, C(0xFFE0F2))
                }
            }
            art.show(ctx)
            c.clear()
        }
        // The new place coming up from below, then landing.
        if rise > 0 {
            let off = land > 0 ? -sin(land * .pi) * 3 : (1 - pow(rise, 1.3)) * Double(h)
            ctx.drawShot(new, in: r.offsetBy(dx: 0, dy: -CGFloat(Int(off.rounded())) * art.px))
            let settle = Self.span(k, 0.84, 0.98)
            if settle > 0 && settle < 1 {
                let a = ((1 - settle) * 4).rounded() / 4
                for j in 0..<12 {
                    let x = Int(Double(w) * (Double(j) + 0.5) / 12 + (noise(j * 7 + 5) - 0.5) * 10)
                    c.ellipse(x, h - 3 - Int(settle * Double(5 + j % 3 * 2)), 5 + j % 3 * 2, 2 + j % 2, C(0x9A9AA8, 0.5 * a))
                }
                for j in 0..<10 {
                    let sx = Int(noise(j * 11 + 1) * Double(w))
                    let sy = h - 4 - Int(settle * Double(10 + Int(noise(j * 11 + 2) * 16)))
                    crawlHoleTwinkle(c, sx, sy, size: (tick + j) % 3 == 0 ? 2 : 1, alpha: a)
                }
            }
            art.show(ctx)
            return
        }
        guard fall < 1 else { return }

        // The old place, going up as everything drops in.
        let up = CGFloat(Int(lift.rounded())) * art.px
        ctx.drawShot(old, in: r.offsetBy(dx: 0, dy: up))

        // The spark where it opens: a little pink and white star, swelling, then swallowed by the pit.
        let spark = Self.span(k, 0, 0.1)
        if spark < 1 {
            let size = 1 + Int((sin(spark * .pi) * 4).rounded())
            crawlHoleTwinkle(c, Int(cx), Int(floorY), size: size, alpha: 1)
        }
        // The pit itself, with its rim of hot pink.
        if rx > 2 {
            let y0 = max(0, Int(cy - ry) - 4), y1 = min(h, Int(cy + ry) + 5)
            let x0 = max(0, Int(cx - rx) - 4), x1 = min(w, Int(cx + rx) + 5)
            if y0 < y1 && x0 < x1 {
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        let d = depth(x, y)
                        if d < -3 { continue }
                        if d < -1 { c.px(x, y, C(0xFF4FB0, 0.38)); continue }    // the glow round it
                        if d < 0 { c.px(x, y, C(0xFFB0DC)); continue }           // the pale lip
                        if d < 2 { c.px(x, y, C(0xFF4FB0)); continue }           // the rim
                        if d < 3 { c.px(x, y, C(0xC02880)); continue }
                        // Inside: the pink light on the top of the far wall, then black.
                        let far = Double(y) + 0.5 < cy
                        c.px(x, y, far && d < 6 ? C(0x5A1440) : dark)
                    }
                }
            }
            // Sparkles running round the rim.
            for i in 0..<14 {
                guard (tick + i) % 3 != 0 else { continue }
                let a = Double(i) / 14 * 2 * .pi + t * 1.6
                crawlHoleTwinkle(c, Int(cx + cos(a) * rx), Int(cy + sin(a) * ry), size: i % 2 == 0 ? 2 : 1, alpha: 1)
            }
        }
        art.show(ctx)
    }

    /// The crew go down with the floor: they fade as the pit takes them (0.2–0.34) and come back as they land in the
    /// new place (0.84–0.94).
    func holeCrewShown(_ k: Double) -> Double {
        1 - Self.ease(Self.span(k, 0.2, 0.34)) + Self.ease(Self.span(k, 0.84, 0.94))
    }
}

/// A little four-pointed star of Donut's magic at (`x`, `y`), `size` arms long: white at its heart, pink at its tips.
private func crawlHoleTwinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, size: Int, alpha: Double) {
    guard alpha > 0 else { return }
    for d in -size...size {
        let col = abs(d) == size && size > 0 ? C(0xFF6AC0, alpha) : C(0xFFFFFF, alpha)
        c.px(x + d, y, col)
        if d != 0 { c.px(x, y + d, col) }
    }
}
