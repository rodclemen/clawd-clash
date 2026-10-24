import CoreGraphics
import Foundation

// Smoke Out (`HuntWipe.smokeOut`): a demon leaving its host and taking another. A column of black smoke bursts up out
// of the old place, roaring and twisting, fills the picture and thrashes about, then funnels down in one tight stream
// and pours into the new place, which clears as the last wisp goes in. A red flash at the end, like the eyes flicking on.

extension HuntTrip {
    /// A frame `k` (0…1) of Smoke Out, over the whole of `r`. The old place shudders red and a column of smoke bursts
    /// up from where the crew stands, twisting as it climbs to the top (0.04–0.3); it mushrooms out along the top and
    /// rolls down until it fills the picture, churning, the old place going dark behind it (0.22–0.5); it thrashes,
    /// and behind it the new place takes over (0.5–0.56); it draws in to a twisting funnel, then one tight stream
    /// pouring down into a spot where the crew will stand, its tail going in last (0.55–0.92); a red flash (0.92–0.98).
    /// The smoke is near-black, a purple-black in three tones, but every edge of it is lit a dusty mauve or a red, and
    /// red sparks flicker inside it, so it reads on a dark desktop. Pixel art, worked out pixel by pixel.
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
            // The funnel: wide at the top, narrowing to the pour spot, drawing in to one tight stream, its tail end
            // sinking down into the spot.
            guard y < pour.y + 2 * s else { return -99 }
            let down = max(0, pour.y - y)
            let tail = sink * (pour.y + 6 * s) - 6 * s
            guard y > tail else { return -99 }
            let u = down / pour.y
            let wide = W * 1.3 * (1 - draw) + 9 * s * (1 - sink)
            let rad = (1.5 + 2.5 * (1 - sink)) * s + wide * pow(u, 1.3)
            let sway = sin(down * 0.1 / s - t * 15) * min(1, down / (H * 0.25)) * (3 + 6 * (1 - sink)) * s
            return min(rad - abs(x - pour.x - sway), (y - tail) * 0.8) + churn * (0.4 + 0.6 * (1 - draw)) + lumps * (1 - draw * 0.6)
        }

        // The smoke: three near-black purple tones in drifting patches, an edge lit mauve or red all round it, and
        // red sparks flickering inside. Worked out a pixel at a time; an edge pixel is one with no smoke next to it.
        let body = [C(0x0A0608), C(0x160C12), C(0x24141E), C(0x3A2436)]
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
                // The billows rolling inside it: big soft shapes, their crowns a dim lit purple.
                let tone = smokeValueNoise(fx / (11 * s) - t * 1.2, fy / (8 * s) - t * 4, 13) * 0.7
                    + smokeValueNoise(fx / (4 * s) - t * 2, fy / (3 * s) - t * 7, 17) * 0.3
                c.px(x, y, body[min(3, Int(tone * 4.4))])
                // Red sparks inside, now and then: hellfire glimpsed through the smoke, flickering.
                let spark = smokeValueNoise(fx / (2.5 * s) + t * 4, fy / (2.5 * s) - t * 14, 33)
                    * smokeValueNoise(fx / (12 * s), fy / (12 * s) - t * 3, 37)
                if spark > 0.63 && v > 4 * s { c.px(x, y, spark > 0.7 ? C(0xFF5A2A) : C(0xA01C1C)) }
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

        // The red flash as the last of it goes in: the whole picture lit red for a moment, stepped down.
        let flash = Self.span(k, 0.92, 0.98)
        if flash > 0 && flash < 1 {
            c.rect(0, 0, w, h, C(0xE01818, ((1 - flash) * 0.45 * 4).rounded() / 4))
            if flash < 0.6 {
                for side in [-1.0, 1.0] { c.rect(Int(pour.x + side * 3 * s) - 1, Int(pour.y - 4 * s), 2, 1, C(0xFF3020)) }
            }
        }
        art.show(ctx)
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
