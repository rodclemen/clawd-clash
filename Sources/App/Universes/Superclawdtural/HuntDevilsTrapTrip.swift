import CoreGraphics
import Foundation

// Devil's Trap (`HuntWipe.devilsTrap`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawDevilsTrap(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
