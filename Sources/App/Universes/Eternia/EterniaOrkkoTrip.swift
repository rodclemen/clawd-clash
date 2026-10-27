import CoreGraphics
import Foundation

// Orkko's Trick: still a plain crossfade (phase 5 draws it; see the plan's Transitions table).

extension EterniaTrip {
    /// Orkko's Trick, `k` (0…1) through its own part, over the whole of `r`.
    func drawOrkko(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        Self.crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
