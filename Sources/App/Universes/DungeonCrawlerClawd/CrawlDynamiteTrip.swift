import CoreGraphics
import Foundation

// Goblin Dynamite (`CrawlWipe.dynamite`), likelier with Carl, Rory, Lorelai or Rosetta and going to the First Floor
// tunnels: a lit stick rolls in and fizzes; BOOM, and the smoke clears on the new place.

extension CrawlTrip {
    /// Goblin Dynamite, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawDynamite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
