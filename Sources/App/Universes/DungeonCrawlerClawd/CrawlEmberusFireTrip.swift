import CoreGraphics
import Foundation

// Emberus's Fire (`CrawlWipe.emberusFire`), only ever with Emberus on stage, likelier going to his High Temple: a
// wall of fire sweeps across, and ash drifts down onto the new place.

extension CrawlTrip {
    /// Emberus's Fire, `k` (0…1) through its own part, over the whole of `r`. A plain crossfade for now: the stand-in.
    func drawEmberusFire(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
