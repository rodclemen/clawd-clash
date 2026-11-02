import CoreGraphics
import Foundation

// Recap Episode (`CrawlWipe.recap`), likelier with Odette, Zev or Cascadia and going to Odette's studio: TV static,
// PREVIOUSLY ON..., and the picture tunes in onto the new place.

extension CrawlTrip {
    /// Recap Episode, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawRecap(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
