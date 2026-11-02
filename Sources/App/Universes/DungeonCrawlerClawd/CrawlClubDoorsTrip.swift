import CoreGraphics
import Foundation

// The Club Doors (`CrawlWipe.clubDoors`), likelier with the Sledge, Bomo, Doctor Bones or Splash Zone and going to
// the casino or the Parade: velvet doors swing open, neon spills out, and the new place is inside.

extension CrawlTrip {
    /// The Club Doors, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawClubDoors(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
