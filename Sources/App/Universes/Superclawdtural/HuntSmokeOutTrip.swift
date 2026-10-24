import CoreGraphics
import Foundation

// Smoke Out (`HuntWipe.smokeOut`): a demon leaving its host and taking another. A column of black smoke bursts up out
// of the old place, roaring and twisting, fills the picture and thrashes about, then funnels down in one tight stream
// and pours into the new place, which clears as the last wisp goes in. A flash at the end, and red eyes flicking on.

extension HuntTrip {
    /// A frame `k` (0…1) of Smoke Out, over the whole of `r`. The old place shudders red and a column of smoke bursts
    /// up from where the crew stands, twisting as it climbs to the top (0.04–0.3); it mushrooms out along the top and
    /// rolls down until it fills the picture, churning, the old place going dark behind it (0.22–0.5); it thrashes,
    /// and behind it the new place takes over (0.5–0.56); it draws in to a twisting funnel, then one tight stream
    /// pouring down into a spot where the crew will stand, its tail going in last (0.55–0.92); a white-hot then red
    /// flash, and red eyes open over the spot and blink shut (0.88–0.995). The smoke is near-black, a purple-black in
    /// three tones, but every edge of it is lit a dusty mauve or a red, hellfire glows through it in dull red patches,
    /// and the funnel has lit bands winding round it, so it reads on a dark desktop. Pixel art, worked out pixel by pixel.
    func drawSmokeOut(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        if k >= 1 { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let W = Double(w), H = Double(h), s = H / 112
        let t = k * kind.duration
        let swapped = k >= 0.53

        let rise = Self.ease(Self.span(k, 0.04, 0.3))
        let fill = Self.ease(Self.span(k, 0.22, 0.5))
        let draw = Self.ease(Self.span(k, 0.55, 0.8))
        let sink = Self.span(k, 0.74, 0.92)
        let mouth = (x: W * 0.5, y: H * 0.74)      // where it comes out of the old place
        let pour = (x: W * 0.5, y: H * 0.76)       // where it goes into the new one

        // Underneath: the old place shuddering red and darkening as the smoke comes, then the new place, dimmed under
        // the smoke and brightening as it goes.
        ctx.drawShot(swapped ? new : old, in: r)
        if swapped {
            Self.wash(ctx, 0x0C0408, 0.6 * (1 - Self.span(k, 0.6, 0.9)), in: r)
        } else {
            Self.wash(ctx, 0x2A0408, 0.25 * Self.span(k, 0, 0.08) + 0.4 * fill, in: r)
        }

        // How deep inside the smoke a point is, in art pixels (more than 0 is smoke).
        func inside(_ x: Double, _ y: Double) -> Double {
            let churn = (smokeValueNoise(x / (7 * s) + t * 1.5, y / (6 * s) - t * 5, 5) - 0.5) * 10 * s
                + (smokeValueNoise(x / (3 * s) - t * 3, y / (3 * s) - t * 9, 9) - 0.5) * 4 * s
            // Big rolling lumps along the edge of the mass, so it billows rather than sliding in a straight line.
            let lumps = (smokeValueNoise(x / (18 * s) + t * 0.8, y / (14 * s) - t * 2.5, 41) - 0.5) * 30 * s
            if k < 0.55 {
                // The column out of the mouth: widening as it climbs, twisting, its top climbing to the top edge.
                var d = -99.0
                if y < mouth.y + 2 * s && rise > 0 {
                    let up = mouth.y - y
                    let top = mouth.y - rise * (mouth.y + 12 * s)
                    if y > top {
                        let sway = sin(up * 0.09 / s - t * 13) * min(1, up / (H * 0.3)) * 7 * s
                        let rad = 4 * s + up * 0.3
                        d = rad - abs(x - mouth.x - sway)
                        d = min(d, (y - top) * 0.8)
                    }
                }
                // The mass rolling down from the top, mushrooming out from over the column first.
                if fill > 0 {
                    let spread = abs(x - mouth.x) / W
                    let reach = fill * (H * 1.4 + 20 * s) - spread * H * 0.9 * (1 - fill)
                    d = max(d, reach - y + lumps * min(1, fill * 3))
                }
                return d + churn
            }
            // The funnel: hanging from a band of storm cloud along the top, wide where it leaves it and narrowing to
            // the pour spot, drawing in to one tight stream, its tail end sinking down into the spot as the cloud
            // goes up after it.
            guard y < pour.y + 2 * s else { return -99 }
            var d = H * 0.2 * (1 - sink) - y
            if let f = funnel(y) { d = max(d, min(f.rad - abs(x - f.mid), (y - f.tail) * 0.8)) }
            return d + churn * (0.4 + 0.6 * (1 - draw)) + lumps * (1 - draw * 0.6)
        }
        // The funnel's middle, its half-width and its tail at row `y`: a twister's trumpet, its sides curving in under
        // the wide top so it narrows to a rope of smoke above the spot, the rope swaying.
        func funnel(_ y: Double) -> (mid: Double, rad: Double, tail: Double)? {
            let down = max(0, pour.y - y)
            let tail = sink * (pour.y + 6 * s) - 6 * s
            guard y > tail else { return nil }
            let u = down / pour.y
            // In the window's short strip it draws in to a trumpet a little wider than the strip is tall, not a V
            // across the whole width.
            let top = art.wide ? max(H * 0.9 * (1 - draw * 0.5), W * 1.3 * pow(1 - draw, 2.5)) : W * 1.3 * (1 - draw)
            let wide = top + 14 * s * (1 - sink)
            let rad = (3 + 3 * (1 - sink)) * s + wide * pow(u, 1.9)
            let sway = sin(down * 0.1 / s - t * 15) * min(1, down / (H * 0.25)) * (3 + 6 * (1 - sink)) * s
            return (pour.x + sway, rad, tail)
        }

        // The smoke: three near-black purple tones in drifting patches, an edge lit mauve or red all round it, and
        // hellfire glowing dull red deep inside it in slow patches. Once it's a funnel, lit bands wind round it as it
        // twists. Worked out a pixel at a time; an edge pixel is one with no smoke next to it.
        let body = [C(0x0A0608), C(0x160C12), C(0x24141E), C(0x3A2436)]
        let fire = [C(0x16060A), C(0x260810), C(0x3A0C16), C(0x58121C)]
        let band = C(0x5A3A56), bandLit = C(0x7E5C78)
        let twisting = k >= 0.55
        let rimMauve = C(0x8A7088), rimRed = C(0xB02828), rimHot = C(0xFF6A3A)
        var d = [Double](repeating: -1, count: w * h)
        for y in 0..<h { for x in 0..<w { d[y * w + x] = inside(Double(x), Double(y)) } }
        for y in 0..<h {
            for x in 0..<w {
                let v = d[y * w + x]
                guard v > 0 else { continue }
                let fx = Double(x), fy = Double(y)
                let edge = v < 1.2 * s
                    || (x > 0 && d[y * w + x - 1] <= 0) || (x + 1 < w && d[y * w + x + 1] <= 0)
                    || (y > 0 && d[(y - 1) * w + x] <= 0) || (y + 1 < h && d[(y + 1) * w + x] <= 0)
                if edge {
                    let n = smokeValueNoise(fx / 4 + t * 2, fy / 4 - t * 6, 21)
                    c.px(x, y, n > 0.72 ? rimHot : n > 0.5 ? rimRed : rimMauve)
                    continue
                }
                if v < 2.6 * s { c.px(x, y, C(0x3A2432)); continue }   // a second, dimmer ring inside the edge
                // The bands winding round the funnel as it twists: across it, from one side round to the other.
                if twisting, let f = funnel(fy), f.rad > 2 * s, f.rad < 16 * s {
                    let across = max(-1, min(1, (fx - f.mid) / f.rad))
                    let wind = sin(asin(across) * 1.6 + (pour.y - fy) * 0.45 / s - t * 22)
                    if wind > 0.75 { c.px(x, y, across < -0.2 ? bandLit : band); continue }
                    if wind > 0.45 { c.px(x, y, body[3]); continue }
                }
                // The billows rolling inside it: big soft shapes, their crowns a dim lit purple; in the slow patches
                // where hellfire shows through, the same shapes in deep reds.
                let tone = smokeValueNoise(fx / (11 * s) - t * 1.2, fy / (8 * s) - t * 4, 13) * 0.7
                    + smokeValueNoise(fx / (4 * s) - t * 2, fy / (3 * s) - t * 7, 17) * 0.3
                let glow = v > 4 * s ? smokeValueNoise(fx / (16 * s) + t * 0.6, fy / (12 * s) - t * 3, 37) : 0
                c.px(x, y, (glow > 0.72 ? fire : body)[min(3, Int(tone * 4.4))])
            }
        }

        // The roar: wisps torn off the column's sides as it bursts out, curling up and away.
        if k > 0.06 && k < 0.4 {
            for i in 0..<26 {
                let born = 0.06 + noise(i * 5 + 1) * 0.22, age = (k - born) / 0.12
                guard age > 0, age < 1 else { continue }
                let up = noise(i * 5 + 2) * mouth.y * 0.8
                let side = noise(i * 5 + 3) > 0.5 ? 1.0 : -1.0
                let x = mouth.x + side * (4 + up * 0.18 + age * 14) * s, y = mouth.y - up - age * 10 * s
                c.rect(Int(x), Int(y), Int(2 * s), Int(max(1, s)), i % 3 == 0 ? rimRed : C(0x24141E))
                c.px(Int(x), Int(y) - 1, rimMauve)
            }
        }

        // The flash as the last of it goes in: a white-hot pop, then the whole picture lit red and stepped down, so it
        // shows even over Hell.
        let flash = Self.span(k, 0.9, 0.99)
        if flash > 0 && flash < 1 {
            c.rect(0, 0, w, h, flash < 0.22 ? C(0xFFE8DC, 0.625) : C(0xF01C14, ((1 - flash) * 0.6 * 8).rounded() / 8))
        }
        // The eyes, flicking on red over the spot it went into as it flashes, holding a moment, and blinking shut.
        let open = Self.span(k, 0.88, 0.9) * (1 - Self.span(k, 0.975, 0.995))
        if open > 0 { smokeEyes(c, x: pour.x, y: pour.y - H * 0.2, size: H * (art.wide ? 0.11 : 0.08), open: open) }
        art.show(ctx)
    }
}

/// A demon's eyes, red right through, as an almond each side of `x`, `size` art pixels from the middle to the corner
/// of an eye, `open` (0…1) how far the lids have parted: a dark lid line, the red, a hot slit of light across the
/// middle, and a smoky dark shadow round them so they read on a bright place, a dark one and Hell's red.
private func smokeEyes(_ c: PixelCanvas, x cx: Double, y cy: Double, size: Double, open: Double) {
    let a = max(3, size), b = max(1, a * 0.42 * open)
    for side in [-1.0, 1.0] {
        let ex = cx + side * a * 1.35
        for y in Int(cy - b - 3)...Int(cy + b + 3) {
            for x in Int(ex - a - 3)...Int(ex + a + 3) {
                let u = abs(Double(x) + 0.5 - ex) / a, v = abs(Double(y) + 0.5 - cy) / b
                let f = u + v * v                       // under 1 inside the almond, pointed at the corners
                if f < 1 {
                    c.px(x, y, v < 0.34 && u < 0.6 ? C(0xFFB08A) : f > 0.78 ? C(0x9A0C0C) : C(0xF02018))
                } else if f < 1.35 {
                    c.px(x, y, C(0x3A0204))
                } else if f < 2.0 {
                    c.px(x, y, C(0x0A0204, 0.5))
                }
            }
        }
    }
}

/// Smooth value noise in 0…1: random values on a unit grid, eased between (for the smoke's churn and its sparks).
private func smokeValueNoise(_ x: Double, _ y: Double, _ seed: Int) -> Double {
    let x0 = floor(x), y0 = floor(y)
    let fx = x - x0, fy = y - y0
    let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
    func at(_ i: Double, _ j: Double) -> Double { noise((Int(i) &* 7919 &+ Int(j) &* 104_729 &+ seed &* 31) & 0xFFFFF) }
    let a = at(x0, y0), b = at(x0 + 1, y0), c = at(x0, y0 + 1), d = at(x0 + 1, y0 + 1)
    return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy
}
