import CoreGraphics
import Foundation

// Loot Box (`CrawlWipe.lootBox`), likelier with the Earth crawlers and going to a safe room: a box thumps down,
// shakes, glows and bursts open, and its light becomes the new place.

extension CrawlTrip {
    /// Loot Box, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawLootBox(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
