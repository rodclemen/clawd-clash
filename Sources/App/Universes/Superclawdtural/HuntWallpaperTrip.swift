import CoreGraphics
import Foundation

// Motel Wallpaper (`HuntWipe.wallpaper`): the motel room's wallpaper, only louder. Strips of it unroll down over the
// old place one after another, left to right, each a different clashing 70s pattern (the room's orange medallions,
// wavy orange-and-mustard stripes, cream daisies on avocado, op-art squares with a hot-pink middle, a mustard trellis
// on teal), until the whole picture is papered. Then the strips peel off one at a time, a corner lifting first, the
// paper curling over into a cream roll that rolls down the strip and drops off the bottom, the new place behind.

extension HuntTrip {
    /// A frame `k` (0…1) of Motel Wallpaper, over the whole of `r`. The strips unroll from the top, left to right, a
    /// roll of paper at each one's foot (0.02–0.38); the picture is all wallpaper for a beat; then the strips peel away
    /// in a jumbled order, each from one top corner, its curl rolling down and off (0.46–0.96), onto the new place.
    func drawWallpaper(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let n = max(5, Int((Double(w) / (art.wide ? 40 : 32)).rounded()))
        let roll = art.wide ? 6 : 8

        // Behind the paper: the old place while it goes up, the new one once it's all covered.
        ctx.drawShot(k < 0.42 ? old : new, in: r)

        // The order the strips come off: jumbled, but every one gone by the end.
        let order = (0..<n).sorted { noise($0 * 29 + 7) < noise($1 * 29 + 7) }
        var rank = [Int](repeating: 0, count: n)
        for (i, s) in order.enumerated() { rank[s] = i }

        for i in 0..<n {
            let xa = i * w / n, xb = (i + 1) * w / n, sw = max(1, xb - xa)
            let hangAt = 0.02 + Double(i) / Double(n) * 0.22
            let hang = Self.ease(Self.span(k, hangAt, hangAt + 0.14))
            guard hang > 0 else { continue }
            let peelAt = 0.46 + Double(rank[i]) / Double(max(1, n - 1)) * 0.32
            let peel = pow(Self.span(k, peelAt, peelAt + 0.18), 1.3)
            let tilt = 3 + Int(noise(i * 17 + 4) * 6)
            let leftFirst = noise(i * 17 + 3) > 0.5
            let pattern = [0, 2, 1, 4, 3][i % 5]
            let drop = Int(noise(i * 17 + 9) * 14)     // each strip hung a little out of step with its neighbour

            // The foot of the paper while it unrolls, and the curl line while it peels (lower at the corner it
            // started from).
            let foot = hang < 1 ? Int((hang * Double(h + roll + 2)).rounded()) - roll / 2 : h + roll
            let base = Int((peel * Double(h + roll * 2 + tilt + 2)).rounded()) - tilt - roll
            func curl(_ x: Int) -> Int {
                let u = Double(x - xa) / Double(sw)
                return base + Int((Double(tilt) * (leftFirst ? 1 - u : u)).rounded())
            }

            for x in xa..<xb {
                let top = peel > 0 ? curl(x) : 0
                let bottom = min(h, foot)
                if top < bottom {
                    for y in max(0, top)..<bottom {
                        c.px(x, y, C(huntWallpaperPattern(pattern, x - xa, y + drop, xa)))
                    }
                }
                // A dark seam down the strip's left edge where it butts against the last.
                if x == xa && i > 0 && top < bottom { c.rect(x, max(0, top), 1, bottom - max(0, top), C(0x1A0E08, 0.45)) }
            }
            // The rolls: the paper's cream back, rolled up, at the foot while it unrolls and at the curl while it
            // peels, with a shadow under each.
            if hang < 1 { huntWallpaperRoll(c, xa, xb, roll) { _ in foot } }
            if peel > 0 && peel < 1 { huntWallpaperRoll(c, xa, xb, 8, curl) }
        }
        art.show(ctx)
    }

    /// A roll of wallpaper lying across the strip from `xa` to `xb`, centred on the row `y(x)`, `size` rows thick: the
    /// cream back of the paper lit along its top, shaded under, a dark edge round it so it reads on any place, the
    /// spiral of the paper showing at its two ends, and a shadow under it.
    private func huntWallpaperRoll(_ c: PixelCanvas, _ xa: Int, _ xb: Int, _ size: Int, _ y: (Int) -> Int) {
        let bands: [UInt32] = size >= 8
            ? [0x3A2A1A, 0xFAF2DE, 0xF0E4C6, 0xE6D8B6, 0xD6C6A0, 0xBCA882, 0x8E7A58, 0x3A2A1A]
            : [0x3A2A1A, 0xF8EED6, 0xE8DABA, 0xCDBB94, 0x95805E, 0x3A2A1A]
        for x in xa..<xb {
            let top = y(x) - size / 2
            for (j, col) in bands.enumerated() { c.px(x, top + j, C(col)) }
            c.rect(x, top + size, 1, 2, C(0x000000, 0.4))
        }
        // The ends: the paper's spiral, a curl of shade with the lit edge of the outer turn.
        for x in [xa, xb - 1] {
            let top = y(x) - size / 2
            for j in 1..<(size - 1) { c.px(x, top + j, C(0x7A6648)) }
            c.px(x, top + size / 2, C(0x3A2A1A)); c.px(x, top + 1, C(0xFAF2DE))
        }
    }
}

/// The colour of the wallpaper pattern `kind` at (x, y) within a strip (whose left edge is at `x0` on the screen, so
/// the half-drop repeats line up the way a real roll's would): five loud 70s papers, all from the motel room's family.
private func huntWallpaperPattern(_ kind: Int, _ x: Int, _ y: Int, _ x0: Int) -> UInt32 {
    let gx = x + x0
    switch kind {
    case 0:
        // The room's own paper, turned up: orange medallions lit at the top left, a teal middle with a cream dot, on
        // brown, half-dropped, with teal crosses between.
        let t = 14, col = ((gx % t) + t) % t, colN = gx / t
        let u = Double(col) - 6.5, v = Double((((y + (colN % 2) * 7) % t) + t) % t) - 6.5
        let d = (u * u + v * v).squareRoot()
        if d < 1.2 { return 0xF6DCA0 }
        if d < 2.8 { return 0x1E8A84 }
        if d < 3.6 { return 0x4A2A16 }
        if d < 5.8 { return u + v < -2.5 ? 0xF7A848 : (u + v > 3.5 ? 0xB0541E : 0xE4762A) }
        if abs(abs(u) - 6.5) + abs(abs(v) - 6.5) < 1.6 { return 0x2AA6A0 }
        return 0x5A3A20
    case 1:
        // Wavy stripes: orange, mustard, chocolate and cream, rippling down the wall.
        let s = ((gx + Int((sin(Double(y) * 0.32) * 3).rounded())) % 16 + 16) % 16
        return s < 5 ? 0xE0681A : s < 9 ? 0xEAAE2A : s < 13 ? 0x4E2410 : 0xF4DCA8
    case 2:
        // Cream daisies with orange middles on avocado, a darker leaf diamond between them.
        let t = 16, colN = gx / t
        let u = Double(((gx % t) + t) % t) - 7.5, v = Double((((y + (colN % 2) * 8) % t) + t) % t) - 7.5
        let d = (u * u + v * v).squareRoot(), a = atan2(v, u)
        if d < 2.0 { return d < 1 ? 0xF8B040 : 0xE0701C }
        if d < 6.3 && cos(a * 6) > -0.05 { return d > 5.3 ? 0xC8B88A : 0xF6ECCA }
        if abs(abs(u) - 7.5) + abs(abs(v) - 7.5) < 2.5 { return 0x3E4A12 }
        return (gx + y) % 6 == 0 ? 0x7C8A2C : 0x6A7820
    case 3:
        // Op-art: nested squares in brown, orange and mustard, a hot motel-neon pink in each middle.
        let t = 12
        let u = abs(Double(((gx % t) + t) % t) - 5.5), v = abs(Double(((y % t) + t) % t) - 5.5)
        let ring = Int(max(u, v)) / 2
        return [0xF0508A, 0xF2C040, 0x5A2410, 0xE87A22][min(3, ring)]
    default:
        // A trellis: mustard diamonds over teal, a pink bud where the lines cross.
        let a = ((gx + y) % 10 + 10) % 10, b = ((gx - y) % 10 + 10) % 10
        if (a == 0 && b == 0) || (a <= 1 && b <= 1) { return 0xF26A8E }
        if a == 0 || b == 0 { return 0xE8B23A }
        if a == 5 && b == 5 { return 0x123E3C }
        return 0x2A6E6A
    }
}
