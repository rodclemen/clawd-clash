import CoreGraphics
import Foundation

// Ping (`CrawlWipe.ping`), Carl's spell, likelier with Carl or Elle the scout: a radar pulse rings out over a dungeon
// map grid, dots light up, and the map fades into the new place.

extension CrawlTrip {
    /// Ping, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawPing(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
