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
    /// (0.52–0.98). The cloud is Filmation's: cel puffs piled up, each with a scalloped top and a flat underside, lavender
    /// lit white on the upper left, a flat blue-grey shadow side and a curl, a dark outline round each; where it's thin
    /// (the trail, the torn edge) it's wisps curling away.
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

/// Cloud billows on a jittered grid `size` apart, shifted right by `drift`: each a cel cloud puff whose size is
/// `cover(x, y, wobble)` (0…1, at its centre; `wobble` a steady 0…1 of its own), so where every cover is 1 they hide
/// everything, and where it's small they've thinned to curling wisps. Lavender, lit white on the upper left, a flat
/// blue-grey underside, a dark outline round each scalloped puff (`eterniaCelPuffs`).
private func eterniaRaiderBillows(_ c: PixelCanvas, size S: Double, drift: Double, seed: Int,
                                  cover: (Double, Double, Double) -> Double) {
    let cols = Int(Double(c.w) / S) + 4, rows = Int(Double(c.h) / S) + 3
    let first = Int(floor(-drift / S)) - 1
    var puffs: [EterniaPuff] = []
    puffs.reserveCapacity(cols * rows)
    for j in 0..<rows {
        for i in 0..<cols {
            let g = (first + i) & 0xFFF
            let id = seed + g * 131 + j * 7
            let x: Double = (Double(first + i) + 0.5 + (noise(id) - 0.5) * 0.5) * S + drift
            let y: Double = (Double(j) - 1 + 0.5 + (noise(id + 1) - 0.5) * 0.3) * S
            let full: Double = S * (1.2 + 0.3 * noise(id + 2))
            let size: Double = max(0, min(1, cover(x, y, noise(id + 3))))
            puffs.append(EterniaPuff(x: x, y: y, full: full, size: size, over: noise(id + 4), tone: 0, seed: noise(id + 5)))
        }
    }
    eterniaCelPuffs(c, puffs, cols: cols, rows: rows, cell: S, origin: (Double(first) * S + drift, -S),
                    tones: [[C(0xA89CC8), C(0xD8D0EC), C(0xFAF6FF)]], ink: C(0x5A4A88), flat: true)
}

// MARK: Cel smoke and cloud

/// One puff of a cel cloud (or of Orkko's smoke): its centre, its full radius, how much of it is there (`size` 0…1;
/// a puff under 0.4 of its size has thinned to a curl of smoke, under 0.08 it's gone), where it lies in the pile
/// (`over`, higher on top), which of the palettes it's in, and a steady 0…1 of its own for its scallops and curl.
struct EterniaPuff {
    var x: Double, y: Double, full: Double, size: Double, over: Double, tone: Int, seed: Double
}

/// Puffs on a grid of `cols` by `rows` cells `cell` apart from `origin` (the puff of cell i, j at `puffs[j * cols + i]`,
/// its centre in or near its cell), piled up in their `over` order, drawn as pixel-art smoke. A whole puff is a cel
/// billow: a scalloped edge of round bumps with a dark `ink` outline, a crescent lit on its upper left, a flat shadow
/// side across its lower right, and a curl drawn into it in the shadow tone; with `flat`, its underside is cut off
/// straight, as a cartoon cloud's is. A thinning puff is a wisp: a curling line of smoke with its own outline, rising a
/// little as it goes. `tones` are each a palette of shadow, middle and lit.
func eterniaCelPuffs(_ c: PixelCanvas, _ puffs: [EterniaPuff], cols: Int, rows: Int, cell S: Double,
                     origin: (Double, Double), tones: [[Px]], ink: Px, flat: Bool) {
    for y in 0..<c.h {
        let gy = Int(floor((Double(y) + 0.5 - origin.1) / S))
        guard gy >= -2 && gy <= rows + 1 else { continue }
        for x in 0..<c.w {
            let gx = Int(floor((Double(x) + 0.5 - origin.0) / S))
            guard gx >= -2 && gx <= cols + 1 else { continue }
            var top = -1.0, hit = -1, tone = 0
            for j in max(0, gy - 2)...max(0, min(rows - 1, gy + 2)) where j < rows {
                for i in max(0, gx - 2)...max(0, min(cols - 1, gx + 2)) where i < cols {
                    let p = puffs[j * cols + i]
                    guard p.size >= 0.08, p.over > top else { continue }
                    let dx: Double = Double(x) + 0.5 - p.x, dy: Double = Double(y) + 0.5 - p.y
                    let found = eterniaPuffAt(p, dx, dy, flat: flat)
                    if found >= 0 { top = p.over; hit = found; tone = p.tone }
                }
            }
            guard hit >= 0 else { continue }
            c.px(x, y, hit == 3 ? ink : tones[tone][hit])
        }
    }
}

/// What puff `p` shows at (`dx`, `dy`) from its centre: -1 nothing, 0 its shadow tone, 1 its middle, 2 lit, 3 outline.
private func eterniaPuffAt(_ p: EterniaPuff, _ dx: Double, _ dy: Double, flat: Bool) -> Int {
    if p.size < 0.4 { return eterniaWispAt(p, dx, dy) }
    let r: Double = p.full * p.size
    let d2: Double = dx * dx + dy * dy
    guard d2 < (r + 1.5) * (r + 1.5) else { return -1 }
    let cut: Double = flat ? r * 0.5 : r * 2
    guard dy < cut + 1.3 else { return -1 }
    // The scalloped edge: round bumps, sharp where two meet.
    let bumps: Double = 5 + (p.seed * 3).rounded(.down)
    let theta: Double = atan2(dy, dx)
    let bump: Double = abs(sin(theta * bumps / 2 + p.seed * 6)).squareRoot()
    let R: Double = r * (0.8 + 0.2 * bump)
    let d: Double = d2.squareRoot()
    guard d < R + 1.3 else { return -1 }
    if d >= R || dy >= cut { return 3 }
    // Lit on the upper left, a crescent; the flat shadow side across the lower right.
    let off: Double = 0.24 * r
    let lx: Double = dx + off, ly: Double = dy + off
    if (lx * lx + ly * ly).squareRoot() > 0.98 * R { return 2 }
    let slope: Double = dy + 0.35 * dx
    if slope > (flat ? 0.12 : 0.2) * r { return 0 }
    // The curl, in the shadow tone, a turn and a half winding in towards the middle.
    if r > 7 {
        let ux: Double = dx - 0.08 * r, uy: Double = dy + 0.12 * r
        let rho: Double = (ux * ux + uy * uy).squareRoot()
        let spin: Double = p.seed > 0.5 ? 1 : -1
        var phi: Double = atan2(uy, ux * spin)
        if phi < 0 { phi += 2 * .pi }
        let b: Double = 0.4 * r / (3 * .pi)
        let th: Double = 0.5 + r / 36
        for turn in 0..<2 {
            let a: Double = phi + Double(turn) * 2 * .pi
            guard a > 1.2 * .pi && a < 3 * .pi else { continue }
            if abs(rho - b * a) < th { return 0 }
        }
    }
    return 1
}

/// A wisp of a thinning puff at (`dx`, `dy`): a curl of smoke, a line winding out from the middle a turn and more,
/// thinner and smaller the less of the puff is left, rising as it thins. Same answers as `eterniaPuffAt`.
private func eterniaWispAt(_ p: EterniaPuff, _ dx: Double, _ dy: Double) -> Int {
    let left: Double = p.size / 0.4                                 // 1 just thinned, 0 gone
    let outer: Double = p.full * (0.3 + 0.3 * left)
    let rise: Double = (1 - left) * p.full * 0.35
    let uy: Double = dy + rise
    let rho: Double = (dx * dx + uy * uy).squareRoot()
    guard rho < outer + 3 else { return -1 }
    let spin: Double = p.seed > 0.5 ? 1 : -1
    var phi: Double = atan2(uy, dx * spin)
    if phi < 0 { phi += 2 * .pi }
    let b: Double = outer / (3 * .pi)
    let th: Double = max(0.8, p.full * 0.1 * left + 0.5)
    var best: Double = 99
    for turn in 0..<2 {
        let a: Double = phi + Double(turn) * 2 * .pi
        guard a > 0.6 * .pi && a < 3 * .pi else { continue }
        best = min(best, abs(rho - b * a))
    }
    if best < th { return uy > 0 ? 0 : 1 }
    if best < th + 1 { return 3 }
    return -1
}
