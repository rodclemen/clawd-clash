import CoreGraphics
import Foundation

// Hole (`CrawlWipe.hole`), Donut's spell, likelier with her: a black pit opens under the scene, everything drops
// through and lands in the new place.

extension CrawlTrip {
    /// Hole, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawHole(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }

    /// How much of the crew shows `k` (0…1) through its own part: all of it, for the stand-in.
    func holeCrewShown(_ k: Double) -> Double { 1 }
}
