import CoreGraphics
import Foundation

// The Wind Raider (`EterniaWipe.windRaider`): the Masters' green and orange flier swoops across the scene trailing
// cloud; the cloud billows out until it covers everything, then the wind blows it away on the new place.

extension EterniaTrip {
    /// A frame `k` (0…1) of the Wind Raider, over the whole of `r`. The Wind Raider (the same craft as its ride, drawn
    /// twice as big, its jet lit) comes in from the left, dipping its nose as it swoops down and lifting it as it climbs
    /// out on the right, a trail of little puffs out of its tail (0–0.44); the puffs swell up and down behind it until
    /// the cloud covers the whole picture (to 0.5); then a wind from the left blows it away to the right, the billows
    /// shrinking off its ragged edge as it drifts, streaks of wind in the clear behind them, onto the new place
    /// (0.52–0.98). The cloud is Filmation's: round billows piled up in flat cel tones, lavender lit white on the
    /// upper left and shaded blue-grey on the lower right, a dark outline round each.
    func drawWindRaider(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let fw = Double(w), fh = Double(h)
        let m = 2                                         // the craft at twice its ride's size
        let craftW = Double(Ride.width * m)
        let pass = Self.span(k, 0, 0.44)
        let fill = Self.ease(Self.span(k, 0.3, 0.5))
        let blow = Self.ease(Self.span(k, 0.52, 0.98))
        // The craft's left edge, and its tail (where the cloud comes out), across the picture.
        let left = -craftW + (fw + craftW + fh * 0.4) * pass
        let tail = left + Double(8 * m)

        ctx.drawShot(k < 0.5 ? old : new, in: r)

        // The swoop: the height the craft's tail was at as it passed each column.
        func path(_ x: Double) -> Double {
            let u: Double = Self.clamp((x + craftW) / (fw + 2 * craftW))
            return fh * (0.34 + 0.24 * sin(u * .pi))
        }

        // The cloud. Before the wind: puffs behind the tail, swelling with how long ago the craft went by, then
        // everywhere. After: the whole of it drifting right, the billows shrinking away off its torn left edge.
        let drift = blow * blow * fw * 0.4
        if k < 0.5 || blow < 1 {
            eterniaRaiderBillows(c, size: max(7, fh / 6), drift: drift, seed: 31) { x, y, wobble in
                if k < 0.5 {
                    guard x < tail else { return 0 }
                    let ago: Double = (tail - x) / fw
                    let thick: Double = fh * (0.04 + 0.8 * ago) + fill * fh * 1.2
                    let near: Double = 1 - abs(y - path(x)) / thick
                    let swell: Double = Self.clamp((tail - x) / (fh * 0.15))
                    return Self.clamp(near * 1.6 + wobble * 0.3 + fill * 1.3) * (0.3 + 0.7 * swell)
                }
                let jag: Double = sin(y / fh * 9.0) * fh * 0.08 + (wobble - 0.5) * fh * 0.2
                let front: Double = blow * (fw + fh) - fh * 0.5 + jag
                return Self.clamp((x - front) / (fh * 0.3))
            }
        }

        // The wind in the clear behind the cloud: white streaks running right.
        if blow > 0 && blow < 1 {
            for i in 0..<12 {
                let y = Int(fh * (0.06 + 0.88 * noise(i * 11 + 2)))
                let len = Int(fh * (0.06 + 0.1 * noise(i * 11 + 3)))
                let x = Int(blow * (fw + fh) * (0.7 + 0.35 * noise(i * 11 + 4)) - fh * 0.75) - len
                c.rect(x, y, len, 1, C(0xF6F2FC))
                c.rect(x + len / 3, y + 1, len / 2, 1, C(0xC8BEE2))
            }
        }

        // The Wind Raider itself, its nose dipping as it dives and lifting as it climbs.
        if pass > 0 && pass < 1 {
            let ride = PixelCanvas(Ride.width, Ride.height)
            Ride.eterniaWindRaider.draw(ride, 0, true, false, k * 1.7)
            let big = PixelCanvas(Ride.width * m, Ride.height * m)
            for y in 0..<Ride.height {
                for x in 0..<Ride.width {
                    let i = (y * Ride.width + x) * 4
                    guard ride.buf[i + 3] > 0 else { continue }
                    big.rect(x * m, y * m, m, m, unpremultiplied(ride, i))
                }
            }
            let tilt: Double = cos(pass * .pi) * 12
            let bw = Ride.width * m + 24, bh = Ride.height * m + 40
            let turned = big.rotated(tilt, about: (Double(Ride.width * m) / 2, Double(Ride.height * m) / 2),
                                     into: bw, bh, at: (Double(bw) / 2, Double(bh) / 2))
            let cy = path(tail) - Double(16 * m) + Double(Ride.height * m) / 2
            c.paste(turned, x: Int(left) - 12, y: Int(cy) - bh / 2)
        }
        art.show(ctx)
    }
}

/// Cloud billows on a jittered grid `size` apart, shifted right by `drift`: each a round cel puff whose radius is
/// `cover(x, y, wobble)` (0…1, at its centre; `wobble` a steady 0…1 of its own) of its full size, so where every cover
/// is 1 they hide everything. They pile up over one another in a fixed order, each with a dark outline, lavender with
/// a white crescent on its upper left and a blue-grey one on its lower right.
private func eterniaRaiderBillows(_ c: PixelCanvas, size S: Double, drift: Double, seed: Int,
                                  cover: (Double, Double, Double) -> Double) {
    let w = c.w, h = c.h
    let cols = Int(Double(w) / S) + 4, rows = Int(Double(h) / S) + 3
    let first = Int(floor(-drift / S)) - 1
    var cx = [Double](repeating: 0, count: cols * rows), cy = cx, rad = cx, over = cx
    for j in 0..<rows {
        for i in 0..<cols {
            let n = j * cols + i, g = (first + i) & 0xFFF
            let id = seed + g * 131 + j * 7
            let x: Double = (Double(first + i) + 0.5 + (noise(id) - 0.5) * 0.5) * S + drift
            let y: Double = (Double(j) - 1 + 0.5 + (noise(id + 1) - 0.5) * 0.5) * S
            cx[n] = x; cy[n] = y
            rad[n] = S * (0.95 + 0.3 * noise(id + 2)) * max(0, min(1, cover(x, y, noise(id + 3))))
            over[n] = noise(id + 4)
        }
    }
    let ink = C(0x5A4A88)
    for y in 0..<h {
        let gy = Int(Double(y) / S) + 1
        for x in 0..<w {
            let gx = Int(floor((Double(x) - drift) / S)) - first
            var top = -1.0, bi = -1, bd = 0.0
            for j in max(0, gy - 2)...min(rows - 1, gy + 2) {
                for i in max(0, gx - 2)...min(cols - 1, gx + 2) {
                    let n = j * cols + i
                    guard rad[n] > 0.5, over[n] > top else { continue }
                    let dx = Double(x) + 0.5 - cx[n], dy = Double(y) + 0.5 - cy[n]
                    let d: Double = (dx * dx + dy * dy).squareRoot()
                    if d < rad[n] + 1.3 { top = over[n]; bi = n; bd = d }
                }
            }
            guard bi >= 0 else { continue }
            if bd > rad[bi] { c.px(x, y, ink); continue }
            let r0 = rad[bi], off = 0.24 * r0
            let lx = Double(x) + 0.5 - (cx[bi] + off), ly = Double(y) + 0.5 - (cy[bi] + off)
            let sx = Double(x) + 0.5 - (cx[bi] - off), sy = Double(y) + 0.5 - (cy[bi] - off)
            let lit: Bool = (lx * lx + ly * ly).squareRoot() > 0.98 * r0
            let shaded: Bool = (sx * sx + sy * sy).squareRoot() > 0.98 * r0
            c.px(x, y, lit ? C(0xFAF6FF) : shaded ? C(0xA89CC8) : C(0xD8D0EC))
        }
    }
}
