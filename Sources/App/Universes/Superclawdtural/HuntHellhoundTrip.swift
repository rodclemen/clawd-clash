import CoreGraphics
import Foundation

// Hellhound (`HuntWipe.hellhound`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawHellhound(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
