import CoreGraphics
import Foundation

// Smoke Out (`HuntWipe.smokeOut`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawSmokeOut(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
