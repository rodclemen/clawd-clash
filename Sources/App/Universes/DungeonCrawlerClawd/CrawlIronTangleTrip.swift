import CoreGraphics
import Foundation

// The Iron Tangle (`CrawlWipe.ironTangle`), likelier with Gore-Gore, Li Jun, Li Na or Zhang and going to Iron
// Tangle station: a train screams across the screen, carrying the old scene away with it, and leaves the new one behind.

extension CrawlTrip {
    /// The Iron Tangle, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawIronTangle(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
