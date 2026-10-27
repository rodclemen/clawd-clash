import CoreGraphics
import Foundation

// The Portal (`EterniaWipe.portal`): a tunnel between worlds, likelier on a trip from one world to another and with
// Gwildor, whose Cosmic Key opens it. It opens in the middle of the scene, swirling blue and white, and the new place
// waits small at its far end, then rushes up through it to fill the screen.

extension EterniaTrip {
    /// The Portal, `k` (0…1) through its own part, over the whole of `r`. The key's spark catches in the middle of the
    /// old place, a white-gold star (0–0.12); the tunnel opens out of it and widens until its mouth is past the frame's
    /// corners (0.04–0.5): rings of blue stepping paler toward the far end, running outward toward us, swirling streaks
    /// across them, a pale rim and a dark edge round the mouth, and white streaks flying out; at the far end the new
    /// place, small, framed in white. Then the far end rushes up the tunnel, the new place growing as it comes, until
    /// it fills the screen (0.55–1). Flat cel rings on the art's grid, the old and new places cut along them.
    func drawPortal(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        // The tunnel is an ellipse wider than tall, wider still on the window's strip, measured in `d` (rows).
        let ax: Double = art.wide ? 2.4 : 1.4
        let cx = Double(w) / 2, cy = Double(h) / 2
        let half = cx / ax
        let corner = (half * half + cy * cy).squareRoot() + 2
        func d(_ x: Int, _ y: Int) -> Double {
            let dx = (Double(x) + 0.5 - cx) / ax, dy = Double(y) + 0.5 - cy
            return (dx * dx + dy * dy).squareRoot()
        }

        let open = Self.ease(Self.span(k, 0.04, 0.5))
        let rush = pow(Self.span(k, 0.55, 1), 1.6)
        let mouth = max(corner * 1.05 * open, 0)
        let small = max(1.5, mouth * 0.2)
        let end = small + (corner * 1.1 - small) * rush

        // The old place round the mouth; the new one at the far end, scaled to just cover it.
        ctx.drawShot(old, in: r)
        if end > 1.5 {
            let hole = art.runs { x, y in d(x, y) < end }
            if !hole.isEmpty {
                let fitW = 2 * end * ax / Double(w), fitH = 2 * end / Double(h)
                let scale = CGFloat(min(1, max(fitW, fitH)))
                let sw = r.width * scale, sh = r.height * scale
                ctx.saveGState()
                ctx.clip(to: hole)
                ctx.drawShot(new, in: CGRect(x: r.midX - sw / 2, y: r.midY - sh / 2, width: sw, height: sh))
                ctx.restoreGState()
            }
        }

        // The key's spark: a four-pointed star, white at its heart, gold at its points, swelling then swallowed.
        let spark = Self.span(k, 0, 0.12)
        if spark > 0 && spark < 1 {
            let arm = Int((2 + 6 * sin(spark * .pi)).rounded())
            let mx = Int(cx), my = Int(cy)
            for i in -arm...arm {
                let col = abs(i) < arm / 2 ? C(0xFFFFFF) : C(0xF8D058)
                c.px(mx + i, my, col); c.px(mx, my + i, col)
            }
            c.rect(mx - 1, my - 1, 3, 3, C(0xFFFFFF))
        }

        // The walls, between the far end and the mouth.
        if mouth > end + 0.5 {
            let ramp = eterniaPortalRamp
            let depth = max(0.001, log(mouth / end))
            let reach = corner * 2.6
            let run = k * 14, turn = k * 2.2
            for y in 0..<h {
                for x in 0..<w {
                    let dd = d(x, y)
                    guard dd >= end, dd < mouth + 1.2 else { continue }
                    if dd >= mouth { c.px(x, y, C(0x0A1030)); continue }
                    if dd >= mouth - 2 { c.px(x, y, ramp[1]); continue }
                    if dd < end + 1.2 { c.px(x, y, ramp[0]); continue }
                    let u = log(dd / end) / depth
                    let ring = Int(floor(reach / dd + run))
                    let dx = (Double(x) + 0.5 - cx) / ax, dy = Double(y) + 0.5 - cy
                    let angle = atan2(dy, dx) / (2 * .pi)
                    let swirl = angle * 6 + reach / dd * 0.1 + turn
                    let streak = swirl - floor(swirl) < 0.2
                    var i = Int(u * 5.6) + (ring % 2 == 0 ? 1 : 0)
                    if streak { i -= 2 }
                    c.px(x, y, ramp[max(0, min(ramp.count - 1, i))])
                }
            }
            // White streaks flying out along the walls toward us.
            for n in 0..<26 {
                let a = noise(n * 5 + 71) * 2 * .pi
                let p = (noise(n * 5 + 72) + k * 2.4).truncatingRemainder(dividingBy: 1)
                let from = end + (mouth - end) * p * p
                let len = 1 + Int(p * 5)
                for step in 0..<len {
                    let rr = from + Double(step)
                    guard rr < mouth - 2 else { break }
                    let px = Int(cx + cos(a) * rr * ax), py = Int(cy + sin(a) * rr)
                    c.px(px, py, step == len - 1 ? C(0xFFFFFF) : ramp[1])
                }
            }
        }
        art.show(ctx)
    }
}

/// The tunnel's blues, from the white light at its far end to the deep blue near its mouth.
private let eterniaPortalRamp: [Px] = [
    C(0xFFFFFF), C(0xDCEEFF), C(0xA8D0FF), C(0x6AA4F4), C(0x3A6ED8), C(0x234A9E), C(0x142A62),
]
