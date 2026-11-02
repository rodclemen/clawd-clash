import CoreGraphics
import Foundation

// The Collapse (`CrawlWipe.collapse`), the signature trip, the longest and the rarest, likelier going to Carl's street:
// night street, rain; the ground cracks and the buildings sink into the earth; a blue System box slams in, WELCOME,
// CRAWLER!; a glittering game-show title, DUNGEON CRAWLER CLAWD in the System's letters, sweeps up; and the view drops
// through the floor into the new place.

extension CrawlTrip {
    /// The Collapse, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawCollapse(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }

    /// How much of the crew shows `k` (0…1) through its own part: all of it, for the stand-in.
    func collapseCrewShown(_ k: Double) -> Double { 1 }
}
