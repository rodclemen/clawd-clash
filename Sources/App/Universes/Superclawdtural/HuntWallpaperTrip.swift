import CoreGraphics
import Foundation

// Motel Wallpaper (`HuntWipe.wallpaper`): to be drawn. Until then, a plain crossfade.

extension HuntTrip {
    func drawWallpaper(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        crossfade(ctx, old: old, new: new, k: k, in: r)
    }
}
