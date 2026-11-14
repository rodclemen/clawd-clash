import CoreGraphics
import Foundation

// The trips between Dungeon Crawler Clawd places. Each is drawn in its own `Crawl…Trip.swift` file, and every one of
// them ends the same way: a small blue System box slides in with the new place's name, ENTERING: and the place
// (CrawlSystemCaption.swift), the books' own interface. Everything of a trip's own is pixel art in the dungeon's
// palette (the System's electric blue, dungeon stone greys, the Desperado Club's neon purple and gold, the red of boss
// music and countdowns), drawn into a `CrawlArt` canvas and scaled up crisp; the old and new places are drawn with
// `drawShot`, so the window's info list stays sharp while the universe changes. Lettering is the System's own block
// letters (`crawlText`), big and blocky like a game interface.

/// The twelve kinds of trip.
enum CrawlWipe: Int, CaseIterable {
    case collapse       // the Collapse: rain, the street sinks, WELCOME, CRAWLER!, the title, a drop through the floor (the rarest)
    case stairwell      // down a spiralling stone stairwell, a floor counter ticking over, out onto the new place
    case lootBox        // a loot box thumps down, shakes, glows and bursts open; its light becomes the new place
    case recap          // TV static, PREVIOUSLY ON..., and the picture tunes in on the new place
    case floorCollapse  // a red countdown ticks to 00:00:00 and the old floor crumbles away onto the new place below
    case ironTangle     // a train screams across, carrying the old scene off with it and leaving the new one behind
    case ping           // a radar pulse rings out over a dungeon map grid, dots light up, the map fades to the new place
    case dynamite       // a lit stick of goblin dynamite rolls in and fizzes; BOOM, and the smoke clears on the new place
    case clubDoors      // velvet club doors swing open, neon spills out, and the new place is inside
    case wheel          // Maestro's gaudy prize wheel spins, ticks and lands on the new place's name
    case hole           // Donut's Hole: a black pit opens under the scene, everything drops through into the new place
    case emberusFire    // a wall of Emberus's fire sweeps across, and ash drifts down onto the new place

    /// How long its own part takes, in seconds; the System box takes `CrawlTrip.caption` more, overlapping its end.
    var effect: Double {
        switch self {
        case .collapse: return 3.4
        case .wheel: return 2.4
        case .recap, .floorCollapse: return 2.2
        case .stairwell, .lootBox, .dynamite: return 2.0
        case .ping, .clubDoors, .hole, .emberusFire: return 1.8
        case .ironTangle: return 1.6
        }
    }

    /// The whole trip, the System box included.
    var duration: Double { effect + CrawlTrip.caption - CrawlTrip.overlap }

    /// Who makes it likelier (on stage when the crew moves on).
    var owners: [Cast] {
        switch self {
        case .collapse: return [.hero(CrawlHero.carl)]
        case .stairwell: return [.hero(CrawlHero.carl), .hero(CrawlHero.donut), .hero(CrawlHero.mordecai)]
        case .lootBox: return CrawlFacts.earthCrawlers.map { .hero($0) }
        case .recap: return [.hero(CrawlHero.odette), .hero(CrawlHero.zev), .villain(CrawlVillain.cascadia)]
        case .floorCollapse: return [.hero(CrawlHero.mordecai), .villain(CrawlVillain.cascadia)]
        case .ironTangle: return [.villain(CrawlVillain.goreGore), .hero(CrawlHero.liJun), .hero(CrawlHero.liNa),
                                  .hero(CrawlHero.zhang)]
        case .ping: return [.hero(CrawlHero.carl), .hero(CrawlHero.elle)]
        case .dynamite: return [.hero(CrawlHero.carl), .hero(CrawlHero.rory), .hero(CrawlHero.lorelai), .hero(CrawlHero.rosetta)]
        case .clubDoors: return [.hero(CrawlHero.sledge), .hero(CrawlHero.bomo), .hero(CrawlHero.doctorBones),
                                 .hero(CrawlHero.splashZone)]
        case .wheel: return [.villain(CrawlVillain.maestro), .villain(CrawlVillain.chaco)]
        case .hole: return [.hero(CrawlHero.donut)]
        case .emberusFire: return [.villain(CrawlVillain.emberus)]
        }
    }

    /// Where it's likelier to go.
    var turf: [Location] {
        switch self {
        case .collapse: return [.crawlSeattle]
        case .stairwell, .dynamite: return [.crawlCorridor]
        case .lootBox: return [.crawlSafeRoom]
        case .recap: return [.crawlStudio]
        case .ironTangle: return [.crawlTangle]
        case .clubDoors: return [.crawlDesperado, .crawlParade]
        case .wheel: return [.crawlDeathWatch]
        case .emberusFire: return [.crawlTemple]
        case .floorCollapse, .ping, .hole: return []
        }
    }

    /// Only ever with one of its owners on stage.
    var needsOwner: Bool { self == .emberusFire }
}

/// One trip's transition. Shared by the window and the screen saver, which hand over the old picture (frozen), the
/// new one (as it is right now) and how far through it is; a frame is drawn over the whole of `r`.
struct CrawlTrip {
    let kind: CrawlWipe
    var from: Location = .crawlSafeRoom, to: Location = .crawlSafeRoom
    var duration: Double { kind.duration }

    /// How long the System box takes at the end of every trip, and how much of that runs over the trip's own end.
    static let caption = 1.6, overlap = 0.3

    /// Any trip but the last one's kind, never one that needs its owner without them: likelier with one of its owners
    /// on stage or going to its turf. The Collapse is the rarest, Carl only making it a little less rare.
    static func pick(after last: CrawlWipe?, cast: [Cast], from: Location?, to place: Location) -> CrawlTrip {
        let here = Set(cast)
        let start = from.flatMap { $0.universe == .crawl ? $0 : nil } ?? .crawlSafeRoom
        var kinds: [CrawlWipe] = []
        for kind in CrawlWipe.allCases where kind != last {
            let owned = kind.owners.contains(where: here.contains)
            if kind.needsOwner && !owned { continue }
            if kind == .collapse {
                if Double.random(in: 0..<1) < (owned ? 0.35 : 0.2) { kinds.append(kind) }
                continue
            }
            kinds.append(kind)
            if owned { kinds += [kind, kind, kind] }
            if kind.turf.contains(place) { kinds += [kind, kind] }
        }
        return CrawlTrip(kind: kinds.randomElement() ?? .stairwell, from: start, to: place)
    }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`: the trip's own part, then the System box.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        ctx.clip(to: r)
        let t = k * duration
        if t < kind.effect {
            let e = t / kind.effect
            switch kind {
            case .collapse: drawCollapse(ctx, old: old, new: new, k: e, in: r)
            case .stairwell: drawStairwell(ctx, old: old, new: new, k: e, in: r)
            case .lootBox: drawLootBox(ctx, old: old, new: new, k: e, in: r)
            case .recap: drawRecap(ctx, old: old, new: new, k: e, in: r)
            case .floorCollapse: drawFloorCollapse(ctx, old: old, new: new, k: e, in: r)
            case .ironTangle: drawIronTangle(ctx, old: old, new: new, k: e, in: r)
            case .ping: drawPing(ctx, old: old, new: new, k: e, in: r)
            case .dynamite: drawDynamite(ctx, old: old, new: new, k: e, in: r)
            case .clubDoors: drawClubDoors(ctx, old: old, new: new, k: e, in: r)
            case .wheel: drawWheel(ctx, old: old, new: new, k: e, in: r)
            case .hole: drawHole(ctx, old: old, new: new, k: e, in: r)
            case .emberusFire: drawEmberusFire(ctx, old: old, new: new, k: e, in: r)
            }
        } else {
            ctx.drawShot(new, in: r)
        }
        let cap = t - (duration - Self.caption)
        if cap > 0 { drawSystemCaption(ctx, t: cap, in: r) }
    }

    /// How much of the crew shows at `k` (`ComicTransition.crewShown`): less while a trip drops the floor out from
    /// under them (the Collapse, Floor Collapse, the Hole), so nobody is left standing on thin air.
    func crewShown(_ k: Double) -> Double {
        let e = min(1, k * duration / kind.effect)
        switch kind {
        case .collapse: return collapseCrewShown(e)
        case .floorCollapse: return floorCollapseCrewShown(e)
        case .hole: return holeCrewShown(e)
        default: return 1
        }
    }

    // MARK: Shared helpers, for every trip file

    static func ease(_ k: Double) -> Double { k * k * (3 - 2 * k) }
    static func clamp(_ k: Double) -> Double { min(1, max(0, k)) }
    /// How far `k` is through `a…b`: 0 before, 1 after.
    static func span(_ k: Double, _ a: Double, _ b: Double) -> Double { clamp((k - a) / (b - a)) }

    /// A colour that's `k` of the way from `a` to `b`.
    static func mix(_ a: UInt32, _ b: UInt32, _ k: Double, _ alpha: Double = 1) -> Px {
        func ch(_ s: UInt32) -> UInt32 {
            let x = Double(a >> s & 0xFF), y = Double(b >> s & 0xFF)
            return UInt32(max(0, min(255, (x + (y - x) * k).rounded())))
        }
        return C(ch(16) << 16 | ch(8) << 8 | ch(0), alpha)
    }

    /// A whole-picture wash over `r` in `hex` at `alpha`, stepped to eighths so it darkens in pixel-art steps.
    static func wash(_ ctx: CGContext, _ hex: UInt32, _ alpha: Double, in r: CGRect) {
        let a = (alpha * 8).rounded() / 8
        guard a > 0 else { return }
        ctx.setFillColor(crawlTripRGB(hex, CGFloat(a))); ctx.fill(r)
    }

    /// A plain crossfade from `old` to `new`, in eighths: the stand-in each trip file starts with.
    static func crossfade(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.drawShot(old, in: r)
        let a = (ease(k) * 8).rounded() / 8
        guard a > 0 else { return }
        ctx.saveGState(); ctx.setAlpha(CGFloat(a)); ctx.drawShot(new, in: r); ctx.restoreGState()
    }
}

extension CrawlTrip: Trip {}

/// A colour from 0xRRGGBB, for the trips' drawing (they draw with Core Graphics, not on a `PixelCanvas`).
func crawlTripRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// A trip's own pixel art: a canvas over the whole frame, rows counted down from the top, about 160 pixels tall (two
/// screen pixels to one at the least, so the window's strip gets real pixels too), scaled up onto the frame without
/// smoothing. The window's strip comes out about 480×112, the screen saver about 256×160.
final class CrawlArt {
    let c: PixelCanvas
    let px: CGFloat
    let r: CGRect

    init(_ r: CGRect) {
        self.r = r
        px = max(2, (r.height / 160).rounded())
        c = PixelCanvas(max(1, Int((r.width / px).rounded(.up))), max(1, Int((r.height / px).rounded(.up))))
    }

    var w: Int { c.w }
    var h: Int { c.h }
    /// The window's short, wide strip, as against the screen saver's taller frame.
    var wide: Bool { Double(w) / Double(h) > 2.4 }

    /// A box of the art (`x`, `y` from the top-left, in art pixels) in the frame's own coordinates.
    func frame(_ x: Int, _ y: Int, _ w: Int, _ hh: Int) -> CGRect {
        CGRect(x: r.minX + CGFloat(x) * px, y: r.maxY - CGFloat(y + hh) * px, width: CGFloat(w) * px, height: CGFloat(hh) * px)
    }

    /// The rows `y` of the art where `inside(x, y)` holds, as one rectangle per run, in the frame's coordinates: to clip
    /// an old or new place to a shape cut on the art's grid.
    func runs(_ inside: (Int, Int) -> Bool) -> [CGRect] {
        var out: [CGRect] = []
        for y in 0..<h {
            var x = 0
            while x < w {
                guard inside(x, y) else { x += 1; continue }
                let x0 = x
                while x < w && inside(x, y) { x += 1 }
                out.append(frame(x0, y, x - x0, 1))
            }
        }
        return out
    }

    /// The art onto `ctx`, scaled up crisp.
    func show(_ ctx: CGContext, alpha: Double = 1) {
        guard alpha > 0, let img = c.makeImage() else { return }
        ctx.saveGState()
        ctx.clip(to: r)
        ctx.interpolationQuality = .none
        ctx.setAlpha(CGFloat(alpha))
        ctx.draw(img, in: frame(0, 0, w, h))
        ctx.restoreGState()
    }
}
