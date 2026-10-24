import CoreGraphics
import Foundation

// Salt and Burn (`HuntWipe.saltAndBurn`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawSaltAndBurn(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
