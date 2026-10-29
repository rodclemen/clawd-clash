import CoreGraphics
import Foundation

// Light Hope's Rainbow (`EterniaWipe.lightHope`): the spirit of the Crystal Castle, likelier with him or the rebels on
// stage and on the way to Etheria's places. A column of his rainbow light rises in the middle of the scene, splits
// into prism bands that sweep out across it, and lifts away band by band on the new place.

extension EterniaTrip {
    /// Light Hope's Rainbow, `k` (0…1) through its own part, over the whole of `r`. A narrow column of light rises from
    /// the bottom in the middle of the old place, red at its heart, then orange, yellow, green, blue and violet out to
    /// either side, its leading end pale, sparkles rising through it (0–0.28). It splits: the bands sweep outward to
    /// both edges, fanning wider at the top as they go, until they cover the whole scene (0.3–0.68). Under them the
    /// old place gives way to the new, and the bands lift off it one after another, each rising up out of the top
    /// like the column came in, the heart first and violet last (0.7–1), each a flat band with a lit edge and a dark
    /// line along its rising foot. Flat cel bands, each lit along its inner edge, a dark line round the outside.
    func drawLightHope(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let rise = Self.ease(Self.span(k, 0, 0.28))
        let spread = Self.ease(Self.span(k, 0.3, 0.68))
        let covered = k >= 0.69
        ctx.drawShot(covered ? new : old, in: r)

        // The bands' width: three pixels in the column, growing until six of them reach past either edge.
        let cx = w / 2
        let full = ceil((Double(w) / 2 + 2) / 6)
        let band = 3 + (full - 3) * spread
        let fan = 0.45 * sin(spread * .pi)
        let top = Int((1 - rise) * Double(h + 6)) - 4
        let ink = C(0x2A1C3A)
        // Lifting off: the row each band's foot has risen to, from the bottom out of the top.
        let feet: [Int] = (0..<6).map { j in
            guard covered else { return h }
            let a: Double = 0.7 + 0.025 * Double(j)
            let f = Self.ease(Self.span(k, a, a + 0.16))
            return Int(((1 - f) * Double(h + 2)).rounded())
        }

        for y in max(0, min(h, top))..<h {
            // Wider toward the top while they sweep, like light fanning out of a prism.
            let lean: Double = 1 + fan * (1 - Double(y) / Double(h))
            let bw = band * lean
            for x in 0..<w {
                let off = x >= cx ? Double(x - cx) : Double(cx - 1 - x)
                let j = Int(off / bw)
                guard j < 6 else {
                    if j == 6 && off - 6 * bw < 1 && y < feet[5] { c.px(x, y, ink) }
                    continue
                }
                let foot = feet[j]
                guard y < foot else { continue }
                if covered && y >= foot - 1 { c.px(x, y, ink); continue }
                let (face, lit) = eterniaHopeBands[j]
                let inner = off - Double(j) * bw < 1
                // Its inner side, once the band inside it has lifted away, outlined dark against the new place.
                if inner && j > 0 && y >= feet[j - 1] { c.px(x, y, ink); continue }
                let tip = y < top + 3 || covered && y >= foot - 3
                c.px(x, y, inner || tip ? lit : face)
            }
        }

        // Sparkles rising through the column: chunky white crosses.
        let glitter = Self.span(k, 0.05, 0.2) * (1 - Self.span(k, 0.55, 0.75))
        if glitter > 0 {
            for n in 0..<12 {
                let p = (noise(n * 3 + 41) + k * 1.6).truncatingRemainder(dividingBy: 1)
                let sy = h - Int(p * Double(h + 8))
                guard sy > top + 2 else { continue }
                let reachX = band * 6 * 0.8
                let sx = cx + Int((noise(n * 3 + 42) - 0.5) * 2 * reachX)
                guard noise(n * 3 + 43) < glitter else { continue }
                c.rect(sx - 1, sy, 3, 1, C(0xFFFFFF)); c.rect(sx, sy - 1, 1, 3, C(0xFFFFFF))
            }
        }
        art.show(ctx)
    }
}

/// Light Hope's bands from his heart outward, each a face and its lit edge: his own six colours.
private let eterniaHopeBands: [(Px, Px)] = [
    (C(0xEC4E5C), C(0xFF8A94)), (C(0xF49A3C), C(0xFFC488)), (C(0xF4D84A), C(0xFFF09A)),
    (C(0x4CC878), C(0x86E8A8)), (C(0x4E8CF4), C(0x86B4FF)), (C(0xA070F0), C(0xC4A0FF)),
]
