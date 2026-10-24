import CoreGraphics
import Foundation

// The trips between Superclawdtural places. Each is drawn in its own `Hunt…Trip.swift` file, as an extension of
// `HuntTrip`. Everything of a trip's own is pixel art in the show's palette (rust, amber, Impala black, dusty denim
// blue and motel-sign neon, with hellfire red, angel white and demon-smoke black as accents), drawn into a `HuntArt`
// canvas and scaled up crisp; the old and new places are drawn with `drawShot`, so the window's info list stays sharp
// while the universe changes. No finishing touch: the show's place captions ("LAWRENCE, KANSAS") are The Clawd Files'
// already. Look at them all with Tools/Transitions (`build/transitions`).

/// The twelve kinds of trip.
enum HuntWipe: Int, CaseIterable {
    case roadSoFar    // the opening: grainy film, THE ROAD SO FAR stamped on, flashes of the old place, the title
                      // burning in on black, NOW, and the new place (the rarest, and the longest)
    case headlights   // night falls, the Impala drives across, and its headlights sweep the new place into view
    case saltAndBurn  // flames rise from the bottom and burn the old place away; the new one shows as the smoke clears
    case devilsTrap   // a red devil's trap paints itself on and spins; the new place opens in its middle and fills it
    case smokeOut     // black demon smoke bursts up, fills the picture, and pours down into the new place; a red flash
    case angelLight   // the bulbs pop, a blinding white light rises, great wing shadows spread and fade on the new place
    case hellhound    // claw marks rip across the old place, red eyes in the dark, and the tears open on the new one
    case coldSpot     // the lights flicker, frost creeps in from the corners, cracks and falls away onto the new place
    case ghostfacers  // the camcorder's viewfinder, REC, static, a ghost flickers past, and it comes back on the new place
    case wallpaper    // the motel's loud wallpaper tiles across, then peels away strip by strip onto the new place
    case leviathanMaw // a huge toothy grin splits the old place open, the jaws close, and open on the new one
    case rewrite      // the old place becomes a page; a cursor types; Chuck crumples it, and a fresh page types the new

    /// How long it takes, in seconds.
    var duration: Double {
        switch self {
        case .roadSoFar: return 3.4
        case .smokeOut, .angelLight, .rewrite: return 2.0
        case .headlights, .saltAndBurn, .devilsTrap, .hellhound, .coldSpot, .ghostfacers, .leviathanMaw: return 1.8
        case .wallpaper: return 1.6
        }
    }

    /// Who makes it likelier (on stage when the crew moves on).
    var owners: [Cast] {
        switch self {
        case .roadSoFar: return [.hero(HuntHero.deanWinclawdster), .hero(HuntHero.samWinclawdster)]
        case .headlights: return [.hero(HuntHero.deanWinclawdster)]
        case .saltAndBurn: return [.hero(HuntHero.bobbyClawdsinger), .hero(HuntHero.johnWinclawdster), .hero(HuntHero.ellenHarvell)]
        case .devilsTrap: return [.hero(HuntHero.samWinclawdster), .hero(HuntHero.bobbyClawdsinger)]
        case .smokeOut: return [.villain(HuntVillain.clawdley), .villain(HuntVillain.megMasters), .villain(HuntVillain.ruby),
                                .villain(HuntVillain.azazel), .villain(HuntVillain.alastair), .villain(HuntVillain.abaddon),
                                .villain(HuntVillain.demonSmoke)]
        case .angelLight: return [.hero(HuntHero.clawdstiel), .hero(HuntHero.gabriel), .hero(HuntHero.balthaclawds),
                                  .villain(HuntVillain.lucifer), .villain(HuntVillain.michael), .villain(HuntVillain.zachariah),
                                  .villain(HuntVillain.uriel), .villain(HuntVillain.raphael), .villain(HuntVillain.naomi)]
        case .hellhound: return [.villain(HuntVillain.clawdley), .villain(HuntVillain.lilith), .villain(HuntVillain.hellhound)]
        case .coldSpot: return [.villain(HuntVillain.womanInWhite), .villain(HuntVillain.bloodyMary), .villain(HuntVillain.hookman)]
        case .ghostfacers: return [.hero(HuntHero.edZedmore), .hero(HuntHero.harrySpangler)]
        case .wallpaper: return []
        case .leviathanMaw: return [.villain(HuntVillain.dickRoman), .villain(HuntVillain.leviathanBlob)]
        case .rewrite: return [.villain(HuntVillain.chuck), .hero(HuntHero.beckyRosen)]
        }
    }

    /// Where it's likelier to go.
    var turf: [Location] {
        switch self {
        case .roadSoFar: return []
        case .headlights: return [.huntRoad]
        case .saltAndBurn: return [.huntStull]
        case .devilsTrap: return [.huntBunker]
        case .smokeOut: return [.huntHell, .huntCrossroads]
        case .angelLight: return [.huntHeaven]
        case .hellhound: return [.huntCrossroads]
        case .coldSpot: return [.huntAsylum, .huntStull]
        case .ghostfacers: return [.huntAsylum]
        case .wallpaper: return [.huntMotel]
        case .leviathanMaw: return [.huntRoman]
        case .rewrite: return [.huntChucks]
        }
    }

    /// Only ever with one of its owners on stage.
    var needsOwner: Bool { self == .leviathanMaw || self == .rewrite }
}

/// One trip's transition. Shared by the window and the screen saver, which hand over the old picture (frozen), the
/// new one (as it is right now) and how far through it is; a frame is drawn over the whole of `r`.
struct HuntTrip {
    let kind: HuntWipe
    var duration: Double { kind.duration }

    /// Any trip but the last one's kind, never one that needs its owner without them: likelier with one of its owners
    /// on stage or going to its turf; The Road So Far the rarest, its owners only making it a little less rare.
    static func pick(after last: HuntWipe?, cast: [Cast], to place: Location) -> HuntTrip {
        let here = Set(cast)
        var kinds: [HuntWipe] = []
        for kind in HuntWipe.allCases where kind != last {
            let owned = kind.owners.contains(where: here.contains)
            if kind.needsOwner && !owned { continue }
            if kind == .roadSoFar {
                if Double.random(in: 0..<1) < (owned ? 0.45 : 0.25) { kinds.append(kind) }
                continue
            }
            kinds.append(kind)
            if owned { kinds += [kind, kind, kind] }
            if kind.turf.contains(place) { kinds += [kind, kind] }
        }
        return HuntTrip(kind: kinds.randomElement() ?? .headlights)
    }

    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.saveGState(); defer { ctx.restoreGState() }
        ctx.interpolationQuality = .none
        ctx.clip(to: r)
        switch kind {
        case .roadSoFar: drawRoadSoFar(ctx, old: old, new: new, k: k, in: r)
        case .headlights: drawHeadlights(ctx, old: old, new: new, k: k, in: r)
        case .saltAndBurn: drawSaltAndBurn(ctx, old: old, new: new, k: k, in: r)
        case .devilsTrap: drawDevilsTrap(ctx, old: old, new: new, k: k, in: r)
        case .smokeOut: drawSmokeOut(ctx, old: old, new: new, k: k, in: r)
        case .angelLight: drawAngelLight(ctx, old: old, new: new, k: k, in: r)
        case .hellhound: drawHellhound(ctx, old: old, new: new, k: k, in: r)
        case .coldSpot: drawColdSpot(ctx, old: old, new: new, k: k, in: r)
        case .ghostfacers: drawGhostfacers(ctx, old: old, new: new, k: k, in: r)
        case .wallpaper: drawWallpaper(ctx, old: old, new: new, k: k, in: r)
        case .leviathanMaw: drawLeviathanMaw(ctx, old: old, new: new, k: k, in: r)
        case .rewrite: drawRewrite(ctx, old: old, new: new, k: k, in: r)
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
        ctx.setFillColor(huntTripRGB(hex, CGFloat(a))); ctx.fill(r)
    }

    /// Until a trip is drawn: the new place fading in over the old.
    func crossfade(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        ctx.drawShot(old, in: r)
        ctx.saveGState(); ctx.setAlpha(CGFloat(Self.ease(Self.clamp(k)))); ctx.drawShot(new, in: r); ctx.restoreGState()
    }
}

extension HuntTrip: Trip {}

/// A colour from 0xRRGGBB, for the trips' drawing with Core Graphics.
func huntTripRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// A trip's own pixel art: a canvas over the whole frame, rows counted down from the top, about 160 pixels tall (two
/// screen pixels to one at the least, so the window's strip gets real pixels too), scaled up onto the frame without
/// smoothing. The window's strip comes out about 480×112, the screen saver about 256×160.
final class HuntArt {
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

// MARK: Lettering

/// The trips' lettering, 5 dots tall, 3 wide (M, N, W and the like wider so their diagonals read, and O four wide
/// with a hollow two dots across, so at big sizes it reads as a round O, not a slashed 0), row by row.
let huntTripGlyphs: [Character: String] = [
    "A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
    "E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
    "I": "111010010010111", "J": "001001001101010", "K": "101101110101101", "L": "100100100100111",
    "M": "1000111011101011000110001", "N": "10011101101110011001", "O": "01101001100110010110", "P": "110101110100100",
    "Q": "010101101110011", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
    "U": "101101101101111", "V": "101101101101010", "W": "1000110001101011101110001", "X": "101101010101101",
    "Y": "101101010010010", "Z": "111001010100111",
    "0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001011001111",
    "4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001001010010",
    "8": "111101111101111", "9": "111101111001111",
    "'": "11000", ".": "00001", ",": "00011", "?": "111001010000010", "!": "11101", "-": "000000111000000",
    ":": "01010",
]

/// How wide `text` comes out at `p` pixels a dot (a space is three dots).
func huntTripTextWidth(_ text: String, _ p: Int) -> Int {
    var dots = 0, last = false
    for ch in text {
        if let g = huntTripGlyphs[ch] { dots += g.count / 5 + 1; last = true } else { dots += 3; last = false }
    }
    return max(0, (dots - (last ? 1 : 0)) * p)
}

/// Lettering at `p` pixels a dot, from its top-left corner, with a drop of `shadow` (if any) a dot down and right of it,
/// so it stands off whatever's behind it.
func huntTripText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, _ p: Int, shadow: Px? = nil) {
    func letters(_ x0: Int, _ y0: Int, _ col: Px) {
        var cx = x0
        for ch in text.uppercased() {
            guard let g = huntTripGlyphs[ch] else { cx += 3 * p; continue }
            let cols = g.count / 5
            for (i, bit) in g.enumerated() where bit == "1" {
                c.rect(cx + (i % cols) * p, y0 + (i / cols) * p, p, p, col)
            }
            cx += (cols + 1) * p
        }
    }
    if let shadow { letters(x + max(1, p / 2), y + max(1, p / 2), shadow) }
    letters(x, y, col)
}

/// Lettering centred on `cx`.
func huntTripCentred(_ c: PixelCanvas, _ cx: Int, _ y: Int, _ text: String, _ col: Px, _ p: Int, shadow: Px? = nil) {
    huntTripText(c, cx - huntTripTextWidth(text, p) / 2, y, text, col, p, shadow: shadow)
}
