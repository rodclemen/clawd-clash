import CoreGraphics
import Foundation

// The Death Watch Wheel (`CrawlWipe.wheel`), likelier with Maestro or Chaco and going to the Death Watch stage:
// Maestro's gaudy prize wheel spins, ticks, and lands on the new place's name.

extension CrawlTrip {
    /// The Death Watch Wheel, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawWheel(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
