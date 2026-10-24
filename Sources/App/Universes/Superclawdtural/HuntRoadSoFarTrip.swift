import CoreGraphics
import Foundation

// The Road So Far, the signature opening (`HuntWipe.roadSoFar`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawRoadSoFar(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
