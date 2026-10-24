import CoreGraphics
import Foundation

// Motel Wallpaper (`HuntWipe.wallpaper`): the motel room's wallpaper, only louder. Strips of it unroll down over the
// old place one after another, left to right, each a different clashing 70s pattern (the room's orange medallions,
// wavy orange-and-mustard stripes, cream daisies on avocado, op-art squares with a hot-pink middle, a mustard trellis
// on teal), until the whole picture is papered. Then the strips peel off one at a time: a top corner lifts and folds
// down, its cream back showing, and the fold runs down the strip, the peeled flap hanging over the paper below it and
// curling under at its end, until the strip has come away and the new place is behind.

extension HuntTrip {
    /// A frame `k` (0…1) of Motel Wallpaper, over the whole of `r`. The strips unroll from the top, left to right, a
    /// roll of paper at each one's foot (0.02–0.38); the picture is all wallpaper for a beat; then the strips peel away
    /// in a jumbled order, each from one top corner, the fold running down and off (0.46–0.96), onto the new place.
    /// In the window's short strip the patterns come on smaller tiles, so a repeat is about as big against the
    /// picture as on the screen saver.
    func drawWallpaper(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let small = art.wide
        let n = max(5, Int((Double(w) / (small ? 34 : 32)).rounded()))
        let roll = small ? 6 : 8

        // Behind the paper: the old place while it goes up, the new one once it's all covered.
        ctx.drawShot(k < 0.42 ? old : new, in: r)

        // The order the strips come off: jumbled, but every one gone by the end.
        let order = (0..<n).sorted { noise($0 * 29 + 7) < noise($1 * 29 + 7) }
        var rank = [Int](repeating: 0, count: n)
        for (i, s) in order.enumerated() { rank[s] = i }

        var flaps: [(xa: Int, xb: Int, a: Double, b: Double)] = []
        for i in 0..<n {
            let xa = i * w / n, xb = (i + 1) * w / n, sw = max(1, xb - xa)
            let hangAt = 0.02 + Double(i) / Double(n) * 0.22
            let hang = Self.ease(Self.span(k, hangAt, hangAt + 0.14))
            guard hang > 0 else { continue }
            let peelAt = 0.46 + Double(rank[i]) / Double(max(1, n - 1)) * 0.32
            let peel = Self.span(k, peelAt, peelAt + 0.18)
            let leftFirst = noise(i * 17 + 3) > 0.5
            let pattern = [0, 2, 1, 4, 3][i % 5]
            let drop = Int(noise(i * 17 + 9) * 14)     // each strip hung a little out of step with its neighbour

            // The foot of the paper while it unrolls, and the fold while it peels: a straight line running down the
            // strip, steep across it from the corner it started at, so it begins as a dog-ear, flattening as it goes.
            let foot = hang < 1 ? Int((hang * Double(h + roll + 2)).rounded()) - roll / 2 : h + roll
            let tilt = Double(sw) * (0.9 - 0.5 * peel) * (leftFirst ? -1 : 1)
            let base = pow(peel, 1.25) * (Double(h) * 1.2 + abs(tilt)) - abs(tilt)
            // The fold as y = a + b x: `base` at the corner it started from, `tilt` higher at the other.
            let b = tilt / Double(sw), a = base + max(0, -tilt) - b * Double(xa)
            if peel > 0 && peel < 1 { flaps.append((xa, xb, a, b)) }

            for x in xa..<xb {
                let top = peel > 0 ? Int((a + b * (Double(x) + 0.5)).rounded()) : 0
                let bottom = min(h, foot)
                guard top < bottom else { continue }
                for y in max(0, top)..<bottom {
                    c.px(x, y, C(huntWallpaperPattern(pattern, x - xa, y + drop, xa, small: small)))
                }
                // A dark seam down the strip's left edge where it butts against the last.
                if x == xa && i > 0 { c.rect(x, max(0, top), 1, bottom - max(0, top), C(0x1A0E08, 0.45)) }
            }
            // The roll at the foot while it unrolls: the paper's cream back, rolled up, with a shadow under it.
            if hang < 1 { huntWallpaperRoll(c, xa, xb, roll) { _ in foot } }
        }
        // The flaps, over everything, as they can hang past their own strip.
        for f in flaps { huntWallpaperFlap(c, xa: f.xa, xb: f.xb, a: f.a, b: f.b, most: Double(h) * 0.32) }
        art.show(ctx)
    }

    /// The peeled part of a strip from `xa` to `xb` whose fold runs along y = a + b x: the paper that was above the
    /// fold, folded down over the paper below it (mirrored across the fold, foreshortened as it curls away, never more
    /// than `most` rows below it), its cream back out. Lit along the fold where it bends over, cream down its length,
    /// shading darker towards its free end where it curls back under, a dark edge round it so it stands off the paper
    /// and the place behind, and its shadow on the paper below.
    private func huntWallpaperFlap(_ c: PixelCanvas, xa: Int, xb: Int, a: Double, b: Double, most: Double) {
        let squash = 0.6
        let nl = (1 + b * b).squareRoot(), nx = -b / nl, ny = 1 / nl          // the fold's normal, pointing down
        let sw = xb - xa
        let x0 = max(0, xa - sw), x1 = min(c.w, xb + sw)
        let ya = a + b * Double(x0), yb = a + b * Double(x1)
        let y0 = max(0, Int(min(ya, yb)) - 1), y1 = min(c.h, Int(max(ya, yb) + most) + 3)
        guard x0 < x1, y0 < y1 else { return }
        let fw = x1 - x0
        // What each pixel is: 0 none, 1 the flap, 2 its edge; and how far each flap pixel is from its free end.
        var cell = [UInt8](repeating: 0, count: fw * (y1 - y0))
        var end = [Double](repeating: 0, count: fw * (y1 - y0))
        for y in y0..<y1 {
            for x in x0..<x1 {
                let px = Double(x) + 0.5, py = Double(y) + 0.5
                let d = (py - (a + b * px)) / nl                                // how far below the fold
                guard d >= 0, d < most else { continue }
                // Where on the strip this bit of the flap came from: mirrored back up across the fold.
                let back = d + d / squash
                let sx = px - back * nx, sy = py - back * ny
                guard sy >= 0, sx >= Double(xa), sx < Double(xb) else { continue }
                let edge = sy < 1.2 / squash || sx < Double(xa) + 1 || sx >= Double(xb) - 1
                cell[(y - y0) * fw + x - x0] = edge ? 2 : 1
                end[(y - y0) * fw + x - x0] = sy * squash
            }
        }
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y - y0) * fw + x - x0
                switch cell[i] {
                case 0:
                    // Its shadow, on whatever's just below it.
                    if (y - 1 >= y0 && cell[i - fw] != 0) || (y - 2 >= y0 && cell[i - 2 * fw] != 0) { c.px(x, y, C(0x000000, 0.35)) }
                case 2:
                    c.px(x, y, C(0x4A3824))
                default:
                    let d = (Double(y) + 0.5 - (a + b * (Double(x) + 0.5))) / nl
                    // The bend: a lit roll with its underside in shade; then the flat of the flap; then its end
                    // turning under, darker and darker.
                    let col: UInt32 = d < 1.2 ? 0xFFFCF2 : d < 2.4 ? 0xF4EAD0 : d < 3.6 ? 0xD2C29C : end[i] < 1.6 ? 0x7E6A4A
                        : end[i] < 3.2 ? 0xAE9A74 : end[i] < 6 ? 0xD6C8A6 : 0xECE0C2
                    c.px(x, y, C(col))
                }
            }
        }
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
/// `small`: the window's tighter repeat, each pattern on a smaller tile.
private func huntWallpaperPattern(_ kind: Int, _ x: Int, _ y: Int, _ x0: Int, small: Bool) -> UInt32 {
    let gx = x + x0
    func wrap(_ v: Int, _ t: Int) -> Int { ((v % t) + t) % t }
    switch kind {
    case 0:
        // The room's own paper, turned up: orange medallions lit at the top left, a teal middle with a cream dot, on
        // brown, half-dropped, with teal crosses between.
        let t = small ? 10 : 14, f = Double(t) / 14, mid = Double(t - 1) / 2
        let u = Double(wrap(gx, t)) - mid, v = Double(wrap(y + (gx / t % 2) * t / 2, t)) - mid
        let d = (u * u + v * v).squareRoot() / f
        if d < 1.2 { return 0xF6DCA0 }
        if d < 2.8 { return 0x1E8A84 }
        if d < 3.6 { return 0x4A2A16 }
        if d < 5.8 { return (u + v) / f < -2.5 ? 0xF7A848 : ((u + v) / f > 3.5 ? 0xB0541E : 0xE4762A) }
        if (abs(abs(u) - mid) + abs(abs(v) - mid)) / f < 1.6 { return 0x2AA6A0 }
        return 0x5A3A20
    case 1:
        // Wavy stripes: orange, mustard, chocolate and cream, rippling down the wall.
        let p = small ? 10 : 16
        let s = wrap(gx + Int((sin(Double(y) * (small ? 0.45 : 0.32)) * (small ? 2 : 3)).rounded()), p) * 16 / p
        return s < 5 ? 0xE0681A : s < 9 ? 0xEAAE2A : s < 13 ? 0x4E2410 : 0xF4DCA8
    case 2:
        // Cream daisies with orange middles on avocado, a darker leaf diamond between them.
        let t = small ? 11 : 16, f = Double(t) / 16, mid = Double(t - 1) / 2
        let u = Double(wrap(gx, t)) - mid, v = Double(wrap(y + (gx / t % 2) * t / 2, t)) - mid
        let d = (u * u + v * v).squareRoot() / f, a = atan2(v, u)
        if d < 2.0 { return d < 1 ? 0xF8B040 : 0xE0701C }
        if d < 6.3 && cos(a * 6) > -0.05 { return d > 5.3 ? 0xC8B88A : 0xF6ECCA }
        if (abs(abs(u) - mid) + abs(abs(v) - mid)) / f < 2.5 { return 0x3E4A12 }
        return (gx + y) % 6 == 0 ? 0x7C8A2C : 0x6A7820
    case 3:
        // Op-art: nested squares in brown, orange and mustard, a hot motel-neon pink in each middle.
        let t = small ? 8 : 12, ring0 = small ? 1.0 : 2.0, mid = Double(t - 1) / 2
        let u = abs(Double(wrap(gx, t)) - mid), v = abs(Double(wrap(y, t)) - mid)
        let ring = Int(max(u, v) / ring0)
        return [0xF0508A, 0xF2C040, 0x5A2410, 0xE87A22][min(3, ring)]
    default:
        // A trellis: mustard diamonds over teal, a pink bud where the lines cross.
        let p = small ? 7 : 10
        let a = wrap(gx + y, p), b = wrap(gx - y, p)
        if (a == 0 && b == 0) || (a <= 1 && b <= 1) { return 0xF26A8E }
        if a == 0 || b == 0 { return 0xE8B23A }
        if a == p / 2 && b == p / 2 { return 0x123E3C }
        return 0x2A6E6A
    }
}
