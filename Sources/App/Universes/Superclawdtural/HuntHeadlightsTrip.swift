import CoreGraphics
import Foundation

// Headlights (`HuntWipe.headlights`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawHeadlights(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
