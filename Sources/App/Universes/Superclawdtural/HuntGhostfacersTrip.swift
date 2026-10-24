import CoreGraphics
import Foundation

// Ghostfacers Cam (`HuntWipe.ghostfacers`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawGhostfacers(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
