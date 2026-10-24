import CoreGraphics
import Foundation

// Chuck's Rewrite (`HuntWipe.rewrite`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawRewrite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
