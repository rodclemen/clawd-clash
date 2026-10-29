import CoreGraphics
import Foundation

// The trips between Clawds of the Universe places. Each is drawn in its own `Eternia…Trip.swift` file, and every one
// of them ends the same way: the new place's name in carved stone letters rises into the corner with a little dust
// (EterniaStone.swift), the way Eternia's places look hewn from rock. Everything of a trip's own is pixel art in
// Filmation's palette (flat, saturated cel colours with dark outlines; dusk skies of purple, orange and teal; Eternia's
// greens and sandstone, Etheria's pinks and lavenders, Skeleclawd's purples and sickly yellows, the Horde's black, grey
// and red), drawn into an `EterniaArt` canvas and scaled up crisp; the old and new places are drawn with `drawShot`,
// so the window's info list stays sharp while the universe changes. No glossy or neon effects: lightning is chunky
// white-gold pixels.

/// The twelve kinds of trip.
enum EterniaWipe: Int, CaseIterable {
    case greyskull    // By the Power of Greyskull: a sword raised against the dusk, lightning, a white-out (the rarest)
    case jawbridge    // Greyskull's stone face; the jawbridge drops like a mouth, the new place rushes up through it
    case zoar         // the Sorceress's falcon swoops across, its wings wiping the scene
    case orkko        // Orkko's trick: a puff of smoke, two wrong places ("Oops!"), then the right one
    case havoc        // the Havoc Staff's eyes glow, bolts crack the scene like glass, the shards fall away
    case orb          // the scene shrinks into a crystal orb, mist swirls, the new place forms and grows
    case windRaider   // the Wind Raider swoops across trailing cloud, which blows away on the new place
    case honour       // For the Honour of Greyskull: a sword held high, a gold and rainbow spiral floods the screen
    case hordeBat     // the red Horde bat flies at the screen, its wings close over the scene and open on the new place
    case shadowWeave  // dark crimson strands weave a cloth over the scene, then unravel strand by strand
    case portal       // a swirling blue-white tunnel between worlds opens and widens onto the new place
    case lightHope    // a column of rainbow light rises, splits into prism bands that sweep across, and fades

    /// How long its own part takes, in seconds; the stone caption takes `EterniaTrip.caption` more, overlapping its end.
    var effect: Double {
        switch self {
        case .greyskull: return 2.8
        case .honour: return 2.4
        case .orkko: return 2.2
        case .jawbridge, .orb, .portal, .shadowWeave: return 1.9
        case .zoar, .havoc, .windRaider, .hordeBat, .lightHope: return 1.7
        }
    }

    /// The whole trip, the caption included.
    var duration: Double { effect + EterniaTrip.caption - EterniaTrip.overlap }

    /// Who makes it likelier (on stage when the crew moves on).
    var owners: [Cast] {
        switch self {
        case .greyskull: return [.hero(EterniaHero.heClawd), .hero(EterniaHero.princeAddam)]
        case .jawbridge: return [.hero(EterniaHero.sorceress), .hero(EterniaHero.heClawd)]
        case .zoar: return [.hero(EterniaHero.sorceress)]
        case .orkko: return [.hero(EterniaHero.orkko)]
        case .havoc: return [.villain(EterniaVillain.skeleclawd), .villain(EterniaVillain.beastClawd), .villain(EterniaVillain.trapClawd),
                             .villain(EterniaVillain.triClawdps), .villain(EterniaVillain.merClawd), .villain(EterniaVillain.clawdful)]
        case .orb: return [.villain(EterniaVillain.evilLynn), .villain(EterniaVillain.countMarzo)]
        case .windRaider: return [.hero(EterniaHero.manAtClawds), .hero(EterniaHero.teelah), .hero(EterniaHero.stratos),
                                  .hero(EterniaHero.ramClawd), .hero(EterniaHero.mekaneck)]
        case .honour: return [.hero(EterniaHero.sheClawd), .hero(EterniaHero.adorra)]
        case .hordeBat: return [.villain(EterniaVillain.hordakk), .villain(EterniaVillain.katra), .villain(EterniaVillain.scorpia),
                                .villain(EterniaVillain.mantenna), .villain(EterniaVillain.grizzlor), .villain(EterniaVillain.hordeTrooper)]
        case .shadowWeave: return [.villain(EterniaVillain.shadowWeaver)]
        case .portal: return [.hero(EterniaHero.gwildor)]
        case .lightHope: return [.hero(EterniaHero.lightHope), .hero(EterniaHero.glimmer), .hero(EterniaHero.bow),
                                 .hero(EterniaHero.madameRazz), .hero(EterniaHero.kowl)]
        }
    }

    /// Where it's likelier to go.
    var turf: [Location] {
        switch self {
        case .greyskull: return [.eterniaGreyskull]
        case .jawbridge: return [.eterniaGreyskull, .eterniaChamber]
        case .havoc, .orb: return [.eterniaSnakeMountain]
        case .honour: return [.eterniaCrystalCastle]
        case .hordeBat: return [.eterniaFrightZone]
        case .lightHope: return EterniaTrip.etheria
        case .zoar, .orkko, .windRaider, .shadowWeave, .portal: return []
        }
    }

    /// Only ever with one of its owners on stage.
    var needsOwner: Bool { [.zoar, .orkko, .shadowWeave].contains(self) }
}

/// One trip's transition. Shared by the window and the screen saver, which hand over the old picture (frozen), the
/// new one (as it is right now) and how far through it is; a frame is drawn over the whole of `r`.
struct EterniaTrip {
    let kind: EterniaWipe
    var from: Location = .eterniaGreyskull, to: Location = .eterniaGreyskull
    var duration: Double { kind.duration }

    /// How long the stone caption takes at the end of every trip, and how much of that runs over the trip's own end.
    static let caption = 1.4, overlap = 0.3

    /// Etheria's places, She-Clawd's world; the Earth town is a world of its own; everywhere else is Eternia.
    static let etheria: [Location] = [.eterniaWhisperingWoods, .eterniaCrystalCastle, .eterniaFrightZone, .eterniaBrightMoon,
                                      .eterniaMystacor, .eterniaCastleChill]
    /// Which world a place is on: 0 Eternia, 1 Etheria, 2 Earth.
    static func world(_ l: Location) -> Int { etheria.contains(l) ? 1 : l == .eterniaEarthTown ? 2 : 0 }

    /// Any trip but the last one's kind, never one that needs its owner without them: likelier with one of its owners
    /// on stage or going to its turf. By the Power of Greyskull is the rarest and For the Honour of Greyskull the next,
    /// their owners only making them a little less rare; the Portal is likelier between worlds and the Wind Raider
    /// across Eternia.
    static func pick(after last: EterniaWipe?, cast: [Cast], from: Location?, to place: Location) -> EterniaTrip {
        let here = Set(cast)
        let start = from.flatMap { $0.universe == .eternia ? $0 : nil } ?? .eterniaGreyskull
        var kinds: [EterniaWipe] = []
        for kind in EterniaWipe.allCases where kind != last {
            let owned = kind.owners.contains(where: here.contains)
            if kind.needsOwner && !owned { continue }
            if kind == .greyskull || kind == .honour {
                let odds = kind == .greyskull ? (owned ? 0.4 : 0.2) : (owned ? 0.5 : 0.3)
                if Double.random(in: 0..<1) < odds { kinds.append(kind) }
                continue
            }
            kinds.append(kind)
            if owned { kinds += [kind, kind, kind] }
            if kind.turf.contains(place) { kinds += [kind, kind] }
            if kind == .portal && world(start) != world(place) { kinds += [kind, kind, kind] }
            if kind == .windRaider && world(start) == 0 && world(place) == 0 && start != place { kinds += [kind] }
        }
        return EterniaTrip(kind: kinds.randomElement() ?? .windRaider, from: start, to: place)
    }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`: the trip's own part, then the caption.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        ctx.clip(to: r)
        let t = k * duration
        if t < kind.effect {
            let e = t / kind.effect
            switch kind {
            case .greyskull: drawGreyskull(ctx, old: old, new: new, k: e, in: r)
            case .jawbridge: drawJawbridge(ctx, old: old, new: new, k: e, in: r)
            case .zoar: drawZoar(ctx, old: old, new: new, k: e, in: r)
            case .orkko: drawOrkko(ctx, old: old, new: new, k: e, in: r)
            case .havoc: drawHavoc(ctx, old: old, new: new, k: e, in: r)
            case .orb: drawOrb(ctx, old: old, new: new, k: e, in: r)
            case .windRaider: drawWindRaider(ctx, old: old, new: new, k: e, in: r)
            case .honour: drawHonour(ctx, old: old, new: new, k: e, in: r)
            case .hordeBat: drawHordeBat(ctx, old: old, new: new, k: e, in: r)
            case .shadowWeave: drawShadowWeave(ctx, old: old, new: new, k: e, in: r)
            case .portal: drawPortal(ctx, old: old, new: new, k: e, in: r)
            case .lightHope: drawLightHope(ctx, old: old, new: new, k: e, in: r)
            }
        } else {
            ctx.drawShot(new, in: r)
        }
        let cap = t - (duration - Self.caption)
        if cap > 0 { drawStoneCaption(ctx, t: cap, in: r) }
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
        ctx.setFillColor(eterniaTripRGB(hex, CGFloat(a))); ctx.fill(r)
    }

    /// A plain crossfade from `old` to `new`, in eighths: the stand-in each trip file starts with.
    static func crossfade(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.drawShot(old, in: r)
        let a = (ease(k) * 8).rounded() / 8
        guard a > 0 else { return }
        ctx.saveGState(); ctx.setAlpha(CGFloat(a)); ctx.drawShot(new, in: r); ctx.restoreGState()
    }
}

extension EterniaTrip: Trip {}

/// A colour from 0xRRGGBB, for the trips' drawing (they draw with Core Graphics, not on a `PixelCanvas`).
func eterniaTripRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// A trip's own pixel art: a canvas over the whole frame, rows counted down from the top, about 160 pixels tall (two
/// screen pixels to one at the least, so the window's strip gets real pixels too), scaled up onto the frame without
/// smoothing. The window's strip comes out about 480×112, the screen saver about 256×160.
final class EterniaArt {
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
