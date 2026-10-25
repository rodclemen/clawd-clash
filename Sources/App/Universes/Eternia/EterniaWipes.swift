import CoreGraphics
import Foundation

// The trips between this universe's places: what the window and the screen saver play when the scene moves on. A full
// universe has 8 to 15 kinds. If the franchise has a signature opening (a title sequence, an opening crawl, a logo
// sting), it must be one of them: usually the longest and rarest, and it opens the trailer too. Base the rest on how
// the franchise itself changes scene: its effects, props and creatures. Everything is drawn in the app's pixel art, in
// the franchise's palette, never painted or glossy, and nothing so fine it won't read at pixel scale.
//
// Each kind has owners (characters who make it likelier when they're on stage) and maybe a turf (places that do the
// same); a few only ever come with their owner there (`needsOwner`: Dark Willow's veins, the Gentlemen's silence).
// When a universe has more than a handful, each kind's drawing goes in a file of its own (`<Prefix><Name>Trip.swift`,
// an extension of the trip), as Slayer/ does. Look at them all with Tools/Transitions (`build/transitions`).

/// The kinds of trip, one so far.
enum EterniaWipe: Int, CaseIterable {
    case petals   // a gust of petals blows across from the left, and the new place is behind it

    var duration: Double {
        switch self {
        case .petals: return 1.6
        }
    }

    /// Who makes it likelier, on stage when the crew moves on.
    var owners: [Cast] {
        switch self {
        case .petals: return [.hero(EterniaHero.heClawd)]
        }
    }

    /// Where it's likelier to go.
    var turf: [Location] {
        switch self {
        case .petals: return [.eterniaGreyskull]
        }
    }

    /// Only ever with one of its owners on stage.
    var needsOwner: Bool { false }
}

/// One trip. Shared by the window and the screen saver, which hand over the old picture (frozen), the new one (as it
/// is right now) and how far through it is; a frame is drawn over the whole of `r`.
struct EterniaTrip {
    let kind: EterniaWipe
    var duration: Double { kind.duration }

    /// Any kind but the last one's (when there's another to pick), never one that needs its owner without them;
    /// likelier with an owner on stage, or going to its turf.
    static func pick(after last: EterniaWipe?, cast: [Cast], to place: Location) -> EterniaTrip {
        let here = Set(cast)
        var kinds: [EterniaWipe] = []
        for kind in EterniaWipe.allCases where kind != last || EterniaWipe.allCases.count == 1 {
            let owned = kind.owners.contains(where: here.contains)
            if kind.needsOwner && !owned { continue }
            kinds.append(kind)
            if owned { kinds += [kind, kind, kind] }
            if kind.turf.contains(place) { kinds += [kind, kind] }
        }
        return EterniaTrip(kind: kinds.randomElement() ?? .petals)
    }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        switch kind {
        case .petals: drawPetals(ctx, old: old, new: new, k: k, in: r)
        }
    }

    /// Petals: a slanted front of petals, pink, white and yellow, blows across from left to right (0.05 to 0.85), a
    /// few loose ones ahead of it. Behind the front the new place shows; ahead of it the old place stays as it was. The
    /// petals are pixel art on a grid 4 screen pixels to a petal pixel, cut on that grid, so they match the scene.
    private func drawPetals(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let px: CGFloat = 4
        let w = Int(r.width / px) + 1, h = Int(r.height / px) + 1
        let sweep = min(1, max(0, (k - 0.05) / 0.8))
        let eased = sweep * sweep * (3 - 2 * sweep)
        let slant = Double(h) * 0.3, front = -slant - 12 + (Double(w) + 2 * slant + 24) * eased
        /// The front's place along the row `y` (art pixels, from the bottom).
        func edge(_ y: Int) -> Double { front + (Double(y) / Double(h) - 0.5) * slant }

        // The new place everywhere, and the old one still showing ahead of the front, row by row on the art's grid.
        ctx.draw(new, in: r)
        var rows: [CGRect] = []
        for y in 0..<h where edge(y) < Double(w) {
            let x = max(0, Int(edge(y).rounded()))
            rows.append(CGRect(x: r.minX + CGFloat(x) * px, y: r.minY + CGFloat(y) * px, width: CGFloat(w - x) * px, height: px))
        }
        if !rows.isEmpty { ctx.saveGState(); ctx.clip(to: rows); ctx.draw(old, in: r); ctx.restoreGState() }

        // The petals: thick along the front, thinning out behind it, a few blown on ahead. Each is two pixels, a
        // colour and its shade, tumbling as it goes.
        guard sweep > 0 && sweep < 1 else { return }
        let colours: [(UInt32, UInt32)] = [(0xF4A8C8, 0xD27898), (0xFAF4F0, 0xD8D0CC), (0xF4D04A, 0xD0A82A)]
        for i in 0..<(h * 3) {
            let y = Int(noise(i * 5) * Double(h))
            let spread = noise(i * 5 + 1)
            let x = Int((edge(y) - 18 * spread * spread + (noise(i * 5 + 2) < 0.15 ? 8 * noise(i * 5 + 3) : 0)).rounded())
            guard x >= 0, x < w else { continue }
            let (a, b) = colours[i % colours.count], flip = Int(k * 20 + Double(i)) % 2
            ctx.setFillColor(eterniaTripRGB(a))
            ctx.fill(CGRect(x: r.minX + CGFloat(x) * px, y: r.minY + CGFloat(y) * px, width: px, height: px))
            ctx.setFillColor(eterniaTripRGB(b))
            ctx.fill(CGRect(x: r.minX + CGFloat(x + flip) * px, y: r.minY + CGFloat(y + 1 - flip) * px, width: px, height: px))
        }
    }
}

extension EterniaTrip: Trip {}

/// A colour from 0xRRGGBB, for the trips' drawing (they draw with Core Graphics, not on a `PixelCanvas`).
func eterniaTripRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
