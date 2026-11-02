import CoreGraphics
import Foundation

// Floor Collapse (`CrawlWipe.floorCollapse`), likelier with Mordecai or Cascadia: a big red countdown ticks to
// 00:00:00, and the old floor crumbles away, revealing the new place below.

extension CrawlTrip {
    /// Floor Collapse, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawFloorCollapse(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }

    /// How much of the crew shows `k` (0…1) through its own part: all of it, for the stand-in.
    func floorCollapseCrewShown(_ k: Double) -> Double { 1 }
}
