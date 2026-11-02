import CoreGraphics
import Foundation

// Emberus's Fire (`CrawlWipe.emberusFire`), only ever with Emberus on stage, likelier going to his High Temple: a
// wall of fire sweeps across, and ash drifts down onto the new place.

extension CrawlTrip {
    /// Emberus's Fire, `k` (0…1) through its own part (1.8 s), over the whole of `r`. An orange glow comes up on the
    /// old place's left edge, sparks flying ahead of it (0–0.08); then a wall of fire sweeps across from left to
    /// right, its foot running a little ahead of its top (0.04–0.72): chunky pixel flames, a hot yellow core behind
    /// a leading edge of tongues licking forward and flickering, the orange of Emberus's thick ray through the middle,
    /// red and dark red where it burns out at the back, the whole of it streaming upward; embers rise off it and
    /// the old place glows orange just ahead of it. Behind it the new place, warm with its afterglow for a moment
    /// (to 0.9). Grey ash and a few last embers drift down over the new place as soon as it shows, swaying as they
    /// fall, and thin away to nothing (0.2–1).
    func drawEmberusFire(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let t = k * CrawlWipe.emberusFire.effect
        let tick = Int(t / 0.06)
        let u = 2                                            // the flames' blocks, two pixels square
        let wall = art.wide ? Double(max(70, h)) : Double(h) * 0.75
        let lean = Double(h) * 0.3                           // how far the foot runs ahead of the top
        let sweep = Self.span(k, 0.04, 0.72)
        let start = -16.0, end = Double(w) + lean + wall * 1.2 + 6
        let front = start + (end - start) * sweep
        /// The leading edge on row `y`, before its tongues.
        func edge(_ y: Int) -> Double { front - lean * Double(h - y) / Double(h) }

        // The old place ahead of the fire, the new one behind it, up under the fire's solid front half (its tongues
        // reach up to 8 pixels ahead of the edge).
        ctx.drawShot(old, in: r)
        let behind = art.runs { x, y in Double(x) < edge(y) - wall * 0.5 + 8 }
        if !behind.isEmpty {
            ctx.saveGState(); ctx.clip(to: behind); ctx.drawShot(new, in: r); ctx.restoreGState()
        }

        let afterglow = 1 - Self.span(k, 0.7, 0.9)
        for by in stride(from: 0, to: h, by: u) {
            let row = by / u
            // The tongues along the leading edge: one every two rows of blocks, a new length each flicker.
            let tongue = noise(row / 2 * 7 + tick * 13 + 5) * 12 - 4
            let lead = edge(by) + tongue
            for bx in stride(from: 0, to: w, by: u) {
                let x = Double(bx) + 1
                let into = lead - x                          // how far behind the leading edge
                if into < 0 {
                    // Ahead of it: the old place lit orange, in steps.
                    if into > -24 { c.rect(bx, by, u, u, C(0xFF6A1A, into > -8 ? 0.34 : into > -16 ? 0.2 : 0.1)) }
                    continue
                }
                let p = into / wall
                if p > 1.25 {
                    // Well behind it: the new place, warm for a moment with its afterglow.
                    let glow = ((afterglow * (1 - min(1, (p - 1.25) / 0.8))) * 4).rounded() / 4
                    if glow > 0 { c.rect(bx, by, u, u, C(0xFF6A1A, 0.24 * glow)) }
                    continue
                }
                // The heat: from the orange-red tongues at the front up to the core, cooling toward the back; flames
                // streaming up through it in columns two blocks wide, a wave running up each; the back ragged in
                // tongues trailing behind, two rows of blocks each, every one burning out at its own length.
                let col = bx / (2 * u), climb = (row + tick) / 2
                if p > 0.66 + 0.5 * noise(row / 2 * 37 + (tick / 2) * 11 + 3) { continue }
                var heat = p < 0.3 ? 0.35 + p / 0.3 * 0.65 : 1 - (p - 0.3) / 0.9
                heat += sin((Double(by) + t * Double(h) * 1.4) / 5 + Double(col) * 1.7) * 0.16
                heat += (noise(col * 131 + climb * 977 + 17) - 0.5) * 0.3
                if p <= 0.5 { heat = max(heat, 0.25) }          // solid at the front, so the old place never shows
                let colour = heat > 0.9 ? C(0xFFF0A0) : heat > 0.72 ? C(0xFFC040) : heat > 0.44 ? C(0xFF6A1A)
                    : heat > 0.22 ? C(0xD8341A) : C(0x8A1A10)
                c.rect(bx, by, u, u, colour)
            }
        }

        // Embers off the fire: sparks rising and drifting back from the flames, and flying out ahead of them.
        if sweep < 1 {
            for i in 0..<36 {
                let ph = frac(t * 0.9 + noise(i * 7 + 1))
                let y = h - Int(ph * Double(h) * 1.15)
                let back = noise(i * 7 + 2) * wall * 1.1 - 10
                let x = Int(edge(max(0, min(h - 1, y))) - back + sin(t * 5 + Double(i)) * 3)
                let hot = (tick + i) % 4 != 0
                c.rect(x, y, i % 3 == 0 ? 2 : 1, i % 3 == 0 ? 2 : 1, hot ? C(0xFFD060) : C(0xFF8A3A))
            }
        }

        // The ash, drifting down over the new place, swaying as it falls, thinning away to nothing.
        let ash = Self.span(k, 0.2, 1)
        let fade = ((1 - Self.span(k, 0.8, 1)) * 4).rounded() / 4
        if ash > 0 && fade > 0 {
            let count = max(30, w * h / 220)
            let loop = Double(h + 12)
            for i in 0..<count {
                let speed = 0.22 + noise(i * 5 + 2) * 0.2
                let y = Int((noise(i * 5 + 1) * loop + t * Double(h) * speed).truncatingRemainder(dividingBy: loop)) - 6
                let x = Int(noise(i * 5) * Double(w) + sin(t * 2.6 + Double(i)) * 3)
                guard y >= 0, y < h, Double(x) < edge(y) - wall * 1.1 else { continue }
                if i % 6 == 0 {
                    // A last ember, glowing as it drifts, going out sooner than the ash.
                    let ember = ((1 - Self.span(k, 0.6, 0.85)) * 4).rounded() / 4
                    if ember > 0 { c.rect(x, y, 2, 1, (tick + i) % 3 == 0 ? C(0xFFD060, ember) : C(0xFF8A3A, ember)) }
                } else if i % 3 == 0 {
                    c.rect(x, y, 1, 2, C(0xD8D0C8, fade))
                } else {
                    c.rect(x, y, 2, 2, C(0xA8A098, fade)); c.px(x, y, C(0xC8C0B8, fade))
                }
            }
        }
        art.show(ctx)
    }
}
