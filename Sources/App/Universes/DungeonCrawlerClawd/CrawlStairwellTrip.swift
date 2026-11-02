import CoreGraphics
import Foundation

// Down the Stairwell (`CrawlWipe.stairwell`), likelier with Carl, Donut or Mordecai and going to the First Floor
// tunnels: the view spirals down a stone stairwell, a floor counter ticks over, and the bottom opens onto the new place.

extension CrawlTrip {
    /// Down the Stairwell, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawStairwell(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
