import CoreGraphics
import Foundation

// Shadow Weave (`EterniaWipe.shadowWeave`): Shadow Weaver's dark magic, only ever with her on stage. Crimson strands
// weave a cloth over the scene, a real over-and-under weave, then unravel strand by strand on the new place.

extension EterniaTrip {
    /// Shadow Weave, `k` (0…1) through its own part, over the whole of `r`. The old place darkens as the strands come:
    /// the warp drops from the top, column after column from the left, while the weft shoots across, row after row
    /// from the top, from the left and the right in turn, over one warp and under the next, so the cloth grows from
    /// the top-left corner and covers the scene (0–0.44). Under the whole cloth the old place is swapped for the new
    /// (0.44–0.5), and the strands unravel one by one in a loose order, the warp sliding out at the bottom and the weft
    /// out the far side, so holes open from the top left where a warp and a weft have both gone (0.5–0.97). Every
    /// strand is cel crimson with a hot pink edge lit along it and a dark gap either side, so the cloth still reads over
    /// a dark place, and its moving end glints.
    func drawShadowWeave(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let s = eterniaWeaveStrand
        let cols = (w + s - 1) / s, rows = (h + s - 1) / s

        // The place under the cloth: the old one, darkening, until the cloth is whole; the new one after.
        let weaving = k < 0.5
        ctx.drawShot(weaving ? old : new, in: r)
        if weaving { Self.wash(ctx, 0x1E0A12, 0.35 * Self.ease(Self.span(k, 0, 0.35)), in: r) }

        // How far each strand reaches (0 gone, 1 all the way across): in order while weaving, loosely while unravelling.
        func reach(_ order: Double, _ seed: Int) -> Double {
            if weaving {
                let a: Double = 0.02 + 0.28 * order
                return Self.ease(Self.span(k, a, a + 0.14))
            }
            let loose: Double = 0.75 * order + 0.25 * noise(seed)
            let a: Double = 0.5 + 0.33 * loose
            return 1 - Self.ease(Self.span(k, a, a + 0.14))
        }
        let warp: [Int] = (0..<cols).map { i in
            Int((reach(Double(i) / Double(max(1, cols - 1)), i * 7 + 911) * Double(h + 2)).rounded())
        }
        let weft: [Int] = (0..<rows).map { j in
            Int((reach(Double(j) / Double(max(1, rows - 1)), j * 13 + 577) * Double(w + 2)).rounded())
        }
        guard warp.contains(where: { $0 > 0 }) || weft.contains(where: { $0 > 0 }) else { return }

        for y in 0..<h {
            let j = y / s, v = y % s
            let fromLeft = j % 2 == 0
            let wl = weft[j]
            for x in 0..<w {
                let i = x / s, u = x % s
                let along = fromLeft ? x : w - 1 - x
                let onWarp = eterniaWeaveCovers(y, warp[i], h, weaving)
                let onWeft = eterniaWeaveCovers(along, wl, w, weaving)
                guard onWarp || onWeft else { continue }
                // A strand fills the middle of its cell, a dark gap either side; where two cross, the one on top
                // runs right through the cell, the one under shows only in the gaps beside it, in its shadow.
                let inWarp = u > 0 && u < s - 1, inWeft = v > 0 && v < s - 1
                let warpTip = eterniaWeaveEnd(y, warp[i], h, weaving)
                let weftTip = eterniaWeaveEnd(along, wl, w, weaving)
                if !(onWarp && onWeft) {
                    if onWarp && inWarp { c.px(x, y, eterniaWeaveWarp(u, v, over: false, tip: warpTip)) }
                    if onWeft && inWeft { c.px(x, y, eterniaWeaveWeft(u, v, over: false, tip: weftTip)) }
                    continue
                }
                let warpOver = (i + j) % 2 == 0
                if warpOver && inWarp {
                    c.px(x, y, eterniaWeaveWarp(u, v, over: true, tip: warpTip))
                } else if !warpOver && inWeft {
                    c.px(x, y, eterniaWeaveWeft(u, v, over: true, tip: weftTip))
                } else if warpOver && inWeft {
                    c.px(x, y, eterniaWeftShade)
                } else if !warpOver && inWarp {
                    c.px(x, y, eterniaWarpShade)
                } else {
                    c.px(x, y, eterniaWeaveInk)
                }
            }
        }
        art.show(ctx)
    }
}

/// A weave cell's side, in art pixels: a strand six wide down its middle and a dark pixel of gap either side.
private let eterniaWeaveStrand = 8

/// The warp's crimson (Shadow Weaver's robe), its hot pink lit edge (her magic) and the dark between strands.
private let eterniaWarpLit = C(0xFF5470), eterniaWarpFace = C(0xB01E2C), eterniaWarpGrain = C(0x961826)
private let eterniaWarpShade = C(0x781220), eterniaWeaveInk = C(0x1E0A12), eterniaWeaveGlint = C(0xFFC8D0)
/// The weft's deeper wine, so the two ways of the cloth read apart.
private let eterniaWeftLit = C(0xE8466A), eterniaWeftFace = C(0x8A1636), eterniaWeftGrain = C(0x721230)
private let eterniaWeftShade = C(0x560C24)

/// Whether a strand `len` long covers the point `pos` along it (counted from the edge it came in at, `full` long): its
/// front end runs in from that edge while weaving, and its tail end runs out at the far edge while unravelling.
private func eterniaWeaveCovers(_ pos: Int, _ len: Int, _ full: Int, _ weaving: Bool) -> Bool {
    weaving ? pos < len : pos >= full + 2 - len
}

/// Whether `pos` is at the moving end of a strand still travelling: the two pixels that glint.
private func eterniaWeaveEnd(_ pos: Int, _ len: Int, _ full: Int, _ weaving: Bool) -> Bool {
    guard len < full + 2 else { return false }
    return weaving ? pos >= len - 2 : pos < full + 4 - len
}

/// A pixel of a warp (running down), `u` across its cell (1 to 6, the strand) and `v` down it: lit on its left,
/// shaded on its right, a twist of grain down its face; where it lies over a weft (`over`), shaded at the cell's top
/// and bottom where it dives under the wefts either side. Its leading end (`tip`) glints.
private func eterniaWeaveWarp(_ u: Int, _ v: Int, over: Bool, tip: Bool) -> Px {
    let s = eterniaWeaveStrand
    if tip { return u == 1 ? eterniaWeaveGlint : eterniaWarpLit }
    if over && (v == 0 || v == s - 1) { return eterniaWarpShade }
    if u == 1 { return eterniaWarpLit }
    if u == s - 2 { return eterniaWarpShade }
    return (u + v) % 4 == 0 ? eterniaWarpGrain : eterniaWarpFace
}

/// A pixel of a weft (running across), `u` along its cell and `v` across it (1 to 6, the strand): lit along its top,
/// shaded along its bottom, a twist of grain; where it lies over a warp, shaded at the cell's sides where it dives
/// under. Its leading end glints.
private func eterniaWeaveWeft(_ u: Int, _ v: Int, over: Bool, tip: Bool) -> Px {
    let s = eterniaWeaveStrand
    if tip { return v == 1 ? eterniaWeaveGlint : eterniaWeftLit }
    if over && (u == 0 || u == s - 1) { return eterniaWeftShade }
    if v == 1 { return eterniaWeftLit }
    if v == s - 2 { return eterniaWeftShade }
    return (u + v) % 4 == 0 ? eterniaWeftGrain : eterniaWeftFace
}
