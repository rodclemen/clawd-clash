import Foundation

// New Achievement!: Dungeon Crawler Clawd's compaction. When the session of one of the Earth crawlers among the heroes
// (Carl, Donut, Katia and the rest; `compaction: .away(who:)` in the facts) has its context compacted, the System
// congratulates them on it: a blue System box slams down over their head, NEW ACHIEVEMENT!, and a beat later the
// achievement itself pops in under it, YOU FORGOT EVERYTHING!. A loot box thumps down at their feet, in front of
// them, sits a moment, starts to rattle with light leaking round its lid, rattles harder, and bursts open: the lid
// flies off spinning, a flash, rays of light fan up out of it and sparkles rise. Then the box and the System box fade.
// Same session, same face. It runs on the engine's missing-time clock (`SessionRecord.abducted`,
// `missingTimeLength`), as The Clawd Files' missing time and Stevie Clawdberg's 88 mph do.
//
// The box's tier is random for each compaction: usually bronze, sometimes silver or gold, rarely legendary, now and
// then celestial, each its own colours, trim and glow (the celestial one deep blue and full of stars). The engine
// only hands over `k` and the cast, so the tier is noted the first time a compaction is asked about, against when it
// must have started (now less `k` of `missingTimeLength`), and every later call that works out the same start (give
// or take half a second) gets the same tier: fixed for the whole compaction, whichever overlay asks (the desktop and
// the window each ask every frame), even two sessions with the same leader compacting at once.
//
// The System box is drawn as a layer, not the engine's caption: the caption is dark type on a cream backing, and this
// is the System's own interface, blue with its block letters (`crawlText`). The letters have no lower case (they're
// drawn as capitals) but do have "!". It sits clear above the status bubble's corner of the frame, so the bubble
// never covers its lettering, and `markRoom` lifts the name tag over it. The loot box is drawn on their own picture
// in `touch`, in front of them, so it gets the app's outline and reads on a dark desktop; the light, the flying
// sparkles and the System box are a layer behind them.

/// A loot box's tier: how rare it is, and how it looks.
enum CrawlLootTier: CaseIterable {
    case bronze, silver, gold, legendary, celestial

    /// How likely each is, out of 100.
    var weight: Int {
        switch self {
        case .bronze: return 58
        case .silver: return 24
        case .gold: return 11
        case .legendary: return 5
        case .celestial: return 2
        }
    }

    /// The box's wood or metal: its face, its lit edge and its shadow.
    var body: (face: Px, lit: Px, dark: Px) {
        switch self {
        case .bronze: return (C(0xB0652E), C(0xE0904E), C(0x6E3C1A))
        case .silver: return (C(0xA8B4C2), C(0xEEF4FA), C(0x66717E))
        case .gold: return (C(0xE4AC2C), C(0xFFE47E), C(0x9A6814))
        case .legendary: return (C(0x7A34C8), C(0xAC6CF0), C(0x48207A))
        case .celestial: return (C(0x3436A8), C(0x6468E0), C(0x1E1E66))
        }
    }

    /// The bands and the clasp.
    var trim: (face: Px, lit: Px) {
        switch self {
        case .bronze: return (C(0xD8A060), C(0xF6CC90))
        case .silver: return (C(0xD8E2EE), C(0xFFFFFF))
        case .gold: return (C(0xFFF0B0), C(0xFFFFFF))
        case .legendary: return (C(0xFFC830), C(0xFFF0A0))
        case .celestial: return (C(0x9CEEFF), C(0xFFFFFF))
        }
    }

    /// The light that leaks out and bursts from it.
    var glow: Px {
        switch self {
        case .bronze: return C(0xFFB262)
        case .silver: return C(0xDCEEFF)
        case .gold: return C(0xFFE264)
        case .legendary: return C(0xD88CFF)
        case .celestial: return C(0xB8F4FF)
        }
    }

    /// How grand its burst is: more rays, more sparkles, a bigger flash.
    var grandeur: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 1
        case .gold: return 2
        case .legendary: return 3
        case .celestial: return 4
        }
    }

    /// One at random, by weight.
    static func roll() -> CrawlLootTier {
        var n = Int.random(in: 0..<allCases.reduce(0) { $0 + $1.weight })
        for tier in allCases {
            if n < tier.weight { return tier }
            n -= tier.weight
        }
        return .bronze
    }
}

/// The tiers rolled for compactions playing now, by leader, with when each must have started (see the top).
private var tiersRolled: [Cast: [(start: Double, tier: CrawlLootTier)]] = [:]
private let tiersLock = NSLock()

/// This compaction's tier: the one already rolled for a compaction of `cast` that started when this one did, else a
/// new roll. Old ones are forgotten once they're over.
private func tierOfCompaction(cast: Cast, k: Double) -> CrawlLootTier {
    let now = Date().timeIntervalSinceReferenceDate
    let start = now - k * missingTimeLength
    tiersLock.lock(); defer { tiersLock.unlock() }
    var playing = (tiersRolled[cast] ?? []).filter { now - $0.start < missingTimeLength + 2 }
    if let hit = playing.first(where: { abs($0.start - start) < 0.5 }) {
        tiersRolled[cast] = playing
        return hit.tier
    }
    let tier = CrawlLootTier.roll()
    playing.append((start, tier))
    tiersRolled[cast] = playing
    return tier
}

/// What a compacted Earth crawler looks like while the achievement plays, `k` (0…1) through it.
func crawlAchievement(k: Double, cast: Cast) -> CompactionLook? {
    CrawlAchievement(k: k, tier: tierOfCompaction(cast: cast, k: k), cast: cast)
}

private func ramp(_ x: Double, _ a: Double, _ b: Double) -> Double { max(0, min(1, (x - a) / (b - a))) }

/// The System box: its size in art pixels (two lines of block letters, a rule between, a 1-pixel frame), not counting
/// the glow round it.
private let panelW = crawlTextWidth("YOU FORGOT EVERYTHING!") + 6, panelH = 17
/// How far above the sprite's top the layer canvas reaches, for the System box over a tall head.
private let headroom = 56
/// The layer canvas's width; the character's middle is its middle.
private let layerW = 120

/// Where the loot box stands on their picture (facing right): its middle column, in front of them, and the ground.
private let boxX = 48, ground = 44

/// Where an achievement is, `k` 0…1 through it, with the box's tier.
struct CrawlAchievement: CompactionLook {
    let k: Double
    let tier: CrawlLootTier

    // The System box.
    /// Its top, in rows of their picture (negative: above its top edge), where it lands: clear of the head, and clear
    /// of the status bubble that sits beside the head (rows 1 to 14, raised by `bubbleLift`), so the bubble never
    /// covers its lettering. And the head's top, for the room the name tag needs over it.
    let panelTop: Int
    let headTop: Int
    /// Art pixels it's still above where it lands (slamming down), its sideways jolt on landing, the white flash of
    /// the landing, whether the second line is in yet (and its own little flash), and how much of it shows (it fades
    /// at the end).
    let panelDrop: Int
    let panelJolt: Int
    let panelFlash: Double
    let subline: Bool
    let sublineFlash: Double
    let panelAlpha: Double

    // The loot box.
    /// Art pixels it's still above the ground (dropping), the dust puff of its landing (0…1 through it), how hard it
    /// rattles (0…1), the light leaking round the lid, whether it's open, how far the lid has flown (0…1), the flash,
    /// the rays, the sparkles (0…1 through them), and how much of it shows.
    let boxDrop: Int
    let dust: Double
    let rattle: Double
    let leak: Double
    let open: Bool
    let lidFlight: Double
    let flash: Double
    let rays: Double
    let sparkles: Double
    let boxAlpha: Double
    /// Room kept over the head for the System box, 0…1 of it: the name tag moves up first, and back down once it's gone.
    let room: Double

    init(k: Double, tier: CrawlLootTier, cast: Cast) {
        self.k = k
        self.tier = tier
        headTop = cast.drawnTop()
        panelTop = max(2 - headroom, min(headTop - 3, -cast.bubbleLift) - panelH)
        room = ramp(k, 0, 0.03) * (1 - ramp(k, 0.95, 1))
        // Down it slams, faster and faster; a jolt, a flash and a little bounce where it lands.
        let fall = ramp(k, 0.02, 0.06)
        let bounce = k > 0.06 && k < 0.09 ? Int((2 * sin(ramp(k, 0.06, 0.09) * .pi)).rounded()) : 0
        panelDrop = k < 0.02 ? 1000 : Int((30 * (1 - fall * fall)).rounded()) + bounce
        panelJolt = k > 0.06 && k < 0.08 ? (Int(k * 500) % 2 == 0 ? 1 : -1) : 0
        panelFlash = k < 0.06 ? 0 : 1 - ramp(k, 0.06, 0.1)
        subline = k >= 0.13
        sublineFlash = k < 0.13 ? 0 : 1 - ramp(k, 0.13, 0.16)
        panelAlpha = 1 - ramp(k, 0.9, 0.97)
        // The loot box thumps down, sits, rattles harder and harder, and bursts.
        let drop = ramp(k, 0.14, 0.19)
        boxDrop = k < 0.14 ? 1000 : Int((34 * (1 - drop * drop)).rounded())
        dust = k < 0.19 ? 0 : ramp(k, 0.19, 0.26)
        rattle = ramp(k, 0.3, 0.56)
        leak = k < 0.56 ? ramp(k, 0.32, 0.56) : 0
        open = k >= 0.56
        lidFlight = ramp(k, 0.56, 0.72)
        flash = k < 0.56 ? 0 : 1 - ramp(k, 0.56, 0.63)
        rays = k < 0.56 ? 0 : ramp(k, 0.56, 0.59) * (1 - ramp(k, 0.7, 0.88))
        sparkles = k < 0.56 ? 0 : ramp(k, 0.56, 0.92)
        boxAlpha = 1 - ramp(k, 0.88, 0.97)
    }

    /// The name tag goes up over the System box (and its glow) while it's there.
    var markRoom: Double { room * Double(headTop - panelTop + 2) }

    /// The System box over the head, and the loot box's light, behind them.
    func layers(cast: Cast, x: CGFloat, y: CGFloat, lift: CGFloat, scale: CGFloat, facing: CGFloat, t: Double) -> [StageLayer] {
        let c = PixelCanvas(layerW, Sprite.height + headroom)
        let mid = layerW / 2
        func col(_ spriteX: Double) -> Double { Double(mid) + Double(facing < 0 ? -1 : 1) * (spriteX - Sprite.bodyCenterX) }
        crawlDrawLootLight(c, self, mouth: (col(Double(boxX) + 0.5), Double(headroom + ground - 7)), t: t)
        if panelDrop < 1000 {
            crawlDrawSystemBox(c, self, x: mid - panelW / 2 + panelJolt, y: headroom + panelTop - panelDrop, t: t)
        }
        guard let img = c.makeImage() else { return [] }
        let w = CGFloat(c.w) * scale, h = CGFloat(c.h) * scale
        return [StageLayer(image: img, rect: CGRect(x: (x - CGFloat(mid) * scale).rounded(), y: y + lift, width: w, height: h))]
    }

    /// The loot box at their feet, in front of them.
    func touch(_ sprite: PixelCanvas, t: Double) { crawlDrawLootBox(sprite, self, t: t) }
}

/// The System box, its top-left at (`x`, `y`): navy with a bright blue frame (lit top and left, deeper bottom and
/// right) and a soft blue glow round it, NEW ACHIEVEMENT! in gold, a rule, then YOU FORGOT EVERYTHING! in white.
/// Landing, its frame and glow flash white; the second line flashes in the same way when it pops in.
func crawlDrawSystemBox(_ c: PixelCanvas, _ a: CrawlAchievement, x: Int, y: Int, t: Double) {
    let al = a.panelAlpha
    guard al > 0 else { return }
    let w = panelW, h = panelH
    let navy = C(0x0E2A6A, al), lit = lerp(C(0x6AB4FF), C(0xFFFFFF), a.panelFlash).alpha(al)
    let deep = lerp(C(0x2A64C8), C(0xFFFFFF), a.panelFlash).alpha(al)
    let halo = C(0x3A8CFF, (0.22 + 0.06 * sin(t * 4) + 0.5 * a.panelFlash) * al)
    c.rect(x - 2, y - 1, w + 4, h + 2, halo)
    c.rect(x - 1, y - 2, w + 2, 1, halo); c.rect(x - 1, y + h + 1, w + 2, 1, halo)
    c.rect(x, y, w, h, navy)
    c.rect(x, y, w, 1, lit); c.rect(x, y, 1, h, lit)
    c.rect(x, y + h - 1, w, 1, deep); c.rect(x + w - 1, y, 1, h, deep)
    let head = "NEW ACHIEVEMENT!", sub = "YOU FORGOT EVERYTHING!"
    let hx = x + (w - crawlTextWidth(head)) / 2, sx = x + (w - crawlTextWidth(sub)) / 2
    crawlText(c, hx, y + 3, head, C(0x7A4A10, al))                   // a shadow under the gold, so it stands up
    crawlText(c, hx, y + 2, head, C(0xFFD84A, al))
    c.rect(x + 3, y + 8, w - 6, 1, C(0x2A64C8, al))
    if a.subline {
        crawlText(c, sx, y + 10, sub, lerp(C(0xF0F6FF), C(0x9CD8FF), a.sublineFlash).alpha(al))
        if a.sublineFlash > 0 { c.rect(x + 1, y + 9, w - 2, 7, C(0xFFFFFF, 0.3 * a.sublineFlash * al)) }
    }
}

/// The loot box's light on the layer behind them, around `mouth` (the box's top, in the layer's pixels): glints
/// escaping up out of it while it rattles, then the burst's flash, rays fanning up and turning, and sparkles rising
/// and drifting (four-point stars of every colour for a celestial box). Bright and small: a faint wide glow just reads
/// as a grey smudge on a dark desktop.
func crawlDrawLootLight(_ c: PixelCanvas, _ a: CrawlAchievement, mouth: (x: Double, y: Double), t: Double) {
    let tier = a.tier, glow = tier.glow, g = Double(tier.grandeur)
    let mx = Int(mouth.x), my = Int(mouth.y)
    if a.leak > 0 {
        for i in 0..<(2 + Int(a.leak * 4)) {
            let f = frac(t * 1.4 + noise(i * 17) )
            let gx = mx + Int((noise(i * 17 + 1) - 0.5) * 12), gy = my - Int(f * 8 * (0.5 + a.leak))
            c.px(gx, gy, lerp(glow, C(0xFFFFFF), 0.4).alpha(a.leak * (1 - f)))
        }
    }
    if a.flash > 0 {
        c.ellipse(mx, my, 10 + Int(g * 2), 8 + Int(g), glow.alpha(0.75 * a.flash))
        c.ellipse(mx, my, 6 + Int(g), 5, C(0xFFFFFF, 0.95 * a.flash))
    }
    if a.rays > 0 {
        let n = 5 + tier.grandeur * 2, reach = 20 + g * 4
        for i in 0..<n {
            let spread = 130.0 / Double(n - 1)
            let ang = -155 + spread * Double(i) + 8 * sin(t * 1.5 + Double(i))
            let len = reach * (0.7 + 0.3 * noise(i * 7 + 5)) * min(1, a.rays * 1.6)
            let e = crawlReach((mouth.x, mouth.y), ang, len)
            c.glowLine(mouth.x, mouth.y, e.x, e.y, core: glow.alpha(0.75), glow: glow.alpha(0.35), coreR: 0.6, glowR: 1.8,
                       strength: a.rays)
        }
    }
    if a.sparkles > 0 && a.sparkles < 1 {
        let n = 6 + tier.grandeur * 3
        let starry = [C(0xFFFFFF), C(0xB8F4FF), C(0xFFB8F0), C(0xFFF2A0), C(0xA8B8FF)]
        for i in 0..<n {
            let delay = noise(i * 13 + 1) * 0.3
            let f = max(0, min(1, (a.sparkles - delay) / 0.7))
            guard f > 0 && f < 1 else { continue }
            let sx = mouth.x + (noise(i * 13 + 2) - 0.5) * 18 + sin(t * 3 + Double(i)) * 2
            let sy = mouth.y - f * (26 + noise(i * 13 + 3) * 14)
            let fade = 1 - f
            let colour = tier == .celestial ? starry[i % starry.count]
                : (i % 3 == 0 ? tier.trim.lit : glow)
            let px = Int(sx), py = Int(sy)
            c.px(px, py, colour.alpha(fade))
            if tier.grandeur >= 2 && (i + Int(t * 8)) % 3 == 0 {   // gold and up twinkle into little crosses
                for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(px + dx, py + dy, colour.alpha(fade * 0.6)) }
            }
        }
    }
}

/// The loot box on their picture (facing right), its middle at `boxX`, standing on the ground: a chest with a domed
/// lid, a band of trim down its middle and a clasp at the seam, lit on the left and shaded on the right. A celestial
/// one is deep blue with stars twinkling all over it. Dropping, it's higher up; landing, it squats a row and puffs
/// dust; rattling, it shakes a pixel each way, hops, and its lid lifts on a line of light; open, its mouth glows and
/// the lid spins up and away.
func crawlDrawLootBox(_ c: PixelCanvas, _ a: CrawlAchievement, t: Double) {
    guard a.boxDrop < 1000, a.boxAlpha > 0 else { return }
    let tier = a.tier, body = tier.body, trim = tier.trim, al = a.boxAlpha
    func p(_ col: Px) -> Px { col.alpha(al) }
    // Shake and hop while it rattles (in bursts that come closer together), squat a row as it lands.
    var dx = 0, up = a.boxDrop, lidUp = 0
    let squat = a.dust > 0 && a.dust < 0.25
    if a.rattle > 0 && !a.open {
        let burst = frac(t * (1.5 + 3 * a.rattle)) < 0.35 + 0.6 * a.rattle
        if burst {
            dx = Int(t * 30) % 2 == 0 ? 1 : -1
            if a.rattle > 0.55 && Int(t * 14) % 3 == 0 { up += 1 }
            if a.rattle > 0.4 && Int(t * 20) % 4 < 2 { lidUp = 1 }
        }
    }
    let x0 = boxX - 6 + dx, bottom = ground - 1 - up
    let bodyTop = bottom - 5 + (squat ? 1 : 0)     // the body: 13 wide, 6 rows (5 landing)
    let lidTop = bodyTop - 3 - lidUp                // the lid: 3 rows, a pixel wider each side
    // The body.
    c.rect(x0, bodyTop, 13, bottom - bodyTop + 1, p(body.face))
    c.rect(x0, bodyTop, 1, bottom - bodyTop + 1, p(body.lit))
    c.rect(x0 + 12, bodyTop, 1, bottom - bodyTop + 1, p(body.dark))
    c.rect(x0, bottom, 13, 1, p(body.dark))
    c.rect(x0 + 1, bodyTop + 2, 11, 1, p(lerp(body.face, body.dark, 0.35)))   // a plank line
    c.rect(x0 + 5, bodyTop, 3, bottom - bodyTop + 1, p(trim.face))        // the band
    c.rect(x0 + 5, bodyTop, 1, bottom - bodyTop + 1, p(trim.lit))
    if a.open {
        // Open: its mouth full of light.
        c.rect(x0, bodyTop - 1, 13, 1, p(body.dark))
        c.rect(x0 + 1, bodyTop - 1, 11, 1, p(lerp(tier.glow, C(0xFFFFFF), 0.5)))
        c.rect(x0 + 2, bodyTop - 2, 9, 1, tier.glow.alpha(0.8 * al * (1 - a.sparkles * 0.5)))
    } else {
        // The light leaking out under the lid as it lifts.
        if lidUp > 0 || a.leak > 0.6 {
            c.rect(x0, bodyTop - 1, 13, 1, lerp(tier.glow, C(0xFFFFFF), a.leak * 0.6).alpha(al * max(0.6, a.leak)))
        }
        crawlDrawLid(c, tier, x: x0 - 1, y: lidTop, alpha: al, t: t)
    }
    if tier == .celestial { crawlStars(c, x: x0 + 1, y: bodyTop + 1, w: 11, h: bottom - bodyTop - 1, alpha: al, t: t, seed: 3) }
    // The clasp at the seam.
    if !a.open { c.rect(x0 + 5, bodyTop - 1 - lidUp + (lidUp > 0 ? 0 : 1), 3, 2, p(trim.lit)) }
    // The lid flying off, spinning, up and forward; gone as it fades.
    if a.open && a.lidFlight < 1 {
        let f = a.lidFlight
        let lx = Double(boxX) + 0.5 + 9 * f, ly = Double(bodyTop - 2) - 30 * (1 - (1 - f) * (1 - f))
        let fade = al * (1 - ramp(f, 0.5, 1))
        prop(c, at: (lx, ly), angle: -f * 600, alpha: fade) { s in crawlDrawLid(s, tier, x: 13, y: 19, alpha: 1, t: t) }
    }
    // The dust puff where it landed: grey-gold pixels thrown out low either side.
    if a.dust > 0 && a.dust < 1 {
        for i in 0..<6 {
            let side = i % 2 == 0 ? -1.0 : 1.0
            let out = 7 + a.dust * (4 + noise(i * 5) * 5)
            let rise = a.dust * (1 + noise(i * 5 + 1) * 3)
            c.px(boxX + Int(side * out), ground - 1 - Int(rise), C(0xE0D2B0, 0.8 * (1 - a.dust)))
        }
    }
}

/// The lid, 15 pixels wide and 3 tall, its top-left at (`x`, `y`): domed (its top row inset), lit along the top, the
/// band of trim over it, shaded at the right.
private func crawlDrawLid(_ c: PixelCanvas, _ tier: CrawlLootTier, x: Int, y: Int, alpha: Double, t: Double) {
    let body = tier.body, trim = tier.trim
    c.rect(x + 1, y, 13, 1, body.lit.alpha(alpha))
    c.rect(x, y + 1, 15, 2, body.face.alpha(alpha))
    c.rect(x + 14, y + 1, 1, 2, body.dark.alpha(alpha))
    c.rect(x, y + 2, 15, 1, lerp(body.face, body.dark, 0.5).alpha(alpha))
    c.rect(x + 6, y, 3, 3, trim.face.alpha(alpha))
    c.rect(x + 6, y, 1, 3, trim.lit.alpha(alpha))
    if tier == .celestial { crawlStars(c, x: x + 1, y: y + 1, w: 13, h: 1, alpha: alpha, t: t, seed: 11) }
}

/// Stars twinkling over a box (`w`×`h` from (`x`, `y`)): a handful of fixed spots, each lit now and then, white, pale
/// cyan or pink.
private func crawlStars(_ c: PixelCanvas, x: Int, y: Int, w: Int, h: Int, alpha: Double, t: Double, seed: Int) {
    let colours = [C(0xFFFFFF), C(0xB8F4FF), C(0xFFC8F4)]
    for i in 0..<max(2, w * h / 4) {
        let sx = x + Int(noise(seed * 31 + i * 3) * Double(w)), sy = y + Int(noise(seed * 31 + i * 3 + 1) * Double(h))
        let on = noise(seed * 31 + i * 3 + 2 + Int(t * 5) * 7) > 0.35
        guard on else { continue }
        c.px(sx, sy, colours[i % colours.count].alpha(alpha))
    }
}
