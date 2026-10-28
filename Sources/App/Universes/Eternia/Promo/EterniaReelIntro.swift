import AppKit

// The trailer's title sequence, By the Power of Greyskull, and the carved-stone title it ends on. Dusk at Castle
// Greyskull, mist drifting in the chasm; Prince Addam rides in on a trembling Cringer and stops at the edge, draws the
// sword and raises it: "By the power of Greyskull!" Then the app's own Greyskull trip, in close-up: the fist and the
// sword against the sunset, lightning down into the tip, bolts crackling to every edge and the white-out. Out of it
// He-Clawd stands where Addam was, sword high, Battle Kat roaring beside him: "I HAVE THE POWER!" CLAWDS OF THE
// UNIVERSE rises over the castle in carved stone, and the camera plunges through the jawbridge into white.

// MARK: The title in carved stone

/// The carved letters, 7 dots tall and 5 wide (M and W 7), a line to a row: our own blocky square-cut letters, the
/// same as the trips' stone caption (EterniaStone.swift), never the show's logo.
private let titleGlyphs: [Character: [String]] = [
    "A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
    "C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
    "D": ["11110", "11011", "11011", "11011", "11011", "11011", "11110"],
    "E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
    "F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
    "H": ["11011", "11011", "11011", "11111", "11011", "11011", "11011"],
    "I": ["11110", "01100", "01100", "01100", "01100", "01100", "11110"],
    "L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
    "N": ["11001", "11101", "11111", "11011", "11011", "11011", "11011"],
    "O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
    "R": ["11110", "11011", "11011", "11110", "11110", "11011", "11011"],
    "S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
    "T": ["11111", "01100", "01100", "01100", "01100", "01100", "01100"],
    "U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
    "V": ["11011", "11011", "11011", "11011", "11011", "01110", "00100"],
    "W": ["1100011", "1100011", "1100011", "1101011", "1111111", "1110111", "1100011"],
]

/// How wide `text` comes out at `p` pixels a dot: each letter its own width and one between, a space 3.
private func titleWidth(_ text: String, _ p: Int) -> Int {
    var dots = 0
    for ch in text { dots += titleGlyphs[ch].map { $0[0].count + 1 } ?? 3 }
    return max(0, dots - 1) * p
}

/// `text` carved in stone from its top-left corner, `p` pixels a dot: a dark outline and a drop to the bottom right,
/// then each dot's sandstone face, lit along its top and left, cut darker along its bottom and right.
private func titleCarve(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ p: Int) {
    let face = C(0xC8A876), lit = C(0xF0DCA8), cut = C(0x8A6A44), ink = C(0x2A1C14)
    var dots: [(Int, Int)] = []
    var cx = x
    for ch in text {
        guard let g = titleGlyphs[ch] else { cx += 3 * p; continue }
        for (row, line) in g.enumerated() {
            for (col, d) in line.enumerated() where d == "1" { dots.append((cx + col * p, y + row * p)) }
        }
        cx += (g[0].count + 1) * p
    }
    let set = Set(dots.map { $0.0 * 4096 + $0.1 })
    func has(_ dx: Int, _ dy: Int) -> Bool { set.contains(dx * 4096 + dy) }
    let edge = max(1, p / 3)
    for (dx, dy) in dots {
        c.rect(dx - 1, dy - 1, p + 2, p + 2, ink)
        c.rect(dx + 1, dy + 1, p + edge + 1, p + edge + 1, ink)
    }
    for (dx, dy) in dots {
        c.rect(dx, dy, p, p, face)
        if !has(dx, dy - p) { c.rect(dx, dy, p, edge, lit) }
        if !has(dx - p, dy) { c.rect(dx, dy, edge, p, lit) }
        if !has(dx, dy + p) { c.rect(dx, dy + p - edge, p, edge, cut) }
        if !has(dx + p, dy) { c.rect(dx + p - edge, dy, edge, p, cut) }
    }
}

/// The title's two lines and their dot sizes: CLAWDS big over OF THE UNIVERSE.
private let titleTop = "CLAWDS", titleBottom = "OF THE UNIVERSE"
private let titleTopP = 4, titleBottomP = 2

/// The title as pixel art, `glint` 0…1 a twinkle running along it left to right (outside that, none).
private func titleArt(glint: Double) -> PixelCanvas {
    let w1 = titleWidth(titleTop, titleTopP), w2 = titleWidth(titleBottom, titleBottomP)
    let w = max(w1, w2) + 8, h = 7 * titleTopP + 7 * titleBottomP + 4 * titleBottomP + 8
    let c = PixelCanvas(w, h)
    titleCarve(c, (w - w1) / 2, 3, titleTop, titleTopP)
    titleCarve(c, (w - w2) / 2, 3 + 7 * titleTopP + 4 * titleBottomP, titleBottom, titleBottomP)
    if glint > 0 && glint < 1 {
        // The sword's glint: a four-pointed star of white, sliding along the top of the big letters.
        let gx = 4 + Int(glint * Double(w - 8)), gy = 3 + titleTopP + 1
        let size = glint > 0.3 && glint < 0.7 ? 4 : 3
        for i in -size...size {
            let col = abs(i) == size ? C(0xFFE07A) : C(0xFFFFFF)
            c.rect(gx + i, gy, 1, 1, col); c.rect(gx, gy + i, 1, 1, col)
        }
        c.rect(gx - 1, gy - 1, 3, 3, C(0xFFFFFF))
    }
    return c
}

/// CLAWDS OF THE UNIVERSE in carved stone, centred on `center` (screen pixels, y up), `scale` 1 at six screen pixels a
/// dot pixel (the frame's pixel art), drawn crisp; `glint` runs the sword's glint along it.
func eterniaDrawTitle(_ ctx: CGContext, center: CGPoint, scale: Double, alpha: Double = 1, glint: Double = -1) {
    guard scale > 0.01, alpha > 0.01 else { return }
    let art = titleArt(glint: glint)
    guard let img = art.makeImage() else { return }
    let px = 6 * scale
    let w = Double(art.w) * px, h = Double(art.h) * px
    ctx.saveGState(); ctx.interpolationQuality = .none; ctx.setAlpha(CGFloat(alpha))
    ctx.draw(img, in: CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h))
    ctx.restoreGState()
}

// MARK: Lightning, chunky and white-gold

/// A jagged line from `a` to `b` in `steps` pieces, each joint knocked sideways up to `amp` (the ends stay put).
func eterniaReelJag(from a: (Double, Double), to b: (Double, Double), steps: Int, amp: Double, seed: Int) -> [(Double, Double)] {
    let dx = b.0 - a.0, dy = b.1 - a.1
    let len = max(0.001, (dx * dx + dy * dy).squareRoot())
    let nx = -dy / len, ny = dx / len
    var pts: [(Double, Double)] = []
    for i in 0...steps {
        let f = Double(i) / Double(steps)
        let off: Double = i == 0 || i == steps ? 0 : (noise((seed + i * 13) & 0xFFFFF) - 0.5) * 2 * amp
        pts.append((a.0 + dx * f + nx * off, a.1 + dy * f + ny * off))
    }
    return pts
}

/// Lightning along a path: a white-hot core `core` pixels thick in a pixel of gold either side, stamped square by
/// square so it stays chunky.
func eterniaReelBolt(_ c: PixelCanvas, _ pts: [(Double, Double)], core: Int) {
    guard pts.count > 1 else { return }
    for pass in 0..<2 {
        let size = pass == 0 ? core + 2 : core
        let col = pass == 0 ? C(0xFFC830) : C(0xFFFBE8)
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let n = max(1, Int(max(abs(b.0 - a.0), abs(b.1 - a.1)).rounded(.up)))
            for s in 0...n {
                let f = Double(s) / Double(n)
                let x = Int((a.0 + (b.0 - a.0) * f).rounded()) - size / 2
                let y = Int((a.1 + (b.1 - a.1) * f).rounded()) - size / 2
                c.rect(x, y, size, size, col)
            }
        }
    }
}

// MARK: The title sequence

/// Its beats (shot-local seconds): Addam rides in to `addamStops`, raises the sword at `swordUp`; the cut to the
/// close-up at `closeUp`, the Greyskull trip played from `tripFrom` to its end at `heStands`; the title rises at
/// `titleRise` and the camera plunges from `plunge`.
private let addamStops = 2.4, swordUp = 2.8, closeUp = 4.2, heStands = 6.7, titleRise = 7.7, plunge = 8.8
private let tripFrom = 0.2
/// Where Addam (and He-Clawd after him) stands, on the near ledge left of the jawbridge, and Cringer (Battle Kat).
private let heroX = 104.0, katX = 66.0
/// The floor rows under Castle Greyskull in the intro: the ledge on the stage's floor.
private let introFloor = 30

/// The time into the intro at which the thunder lands (the trip's strike), for the sound.
let eterniaThunderAt = closeUp + (0.46 - tripFrom) / (1 - tripFrom) * (heStands - closeUp)
/// When the sword goes up, He-Clawd stands, the title rises (its glint) and the plunge starts: for the sound.
let eterniaSwordUpAt = swordUp, eterniaHeStandsAt = heStands, eterniaTitleShingAt = titleRise + 0.7, eterniaPlungeAt = plunge

/// The mist in the chasm: flat lavender banks drifting slowly, a few rows above the ledge.
private func chasmMist(_ c: PixelCanvas, t: Double) {
    for i in 0..<7 {
        let speed = 3.0 + 3.0 * noise(i * 5 + 300)
        let x = (noise(i * 5 + 301) * 420 + t * speed).truncatingRemainder(dividingBy: 420) - 60
        let y = 128 + Int(noise(i * 5 + 302) * 14)
        let rx = 26 + Int(noise(i * 5 + 303) * 22)
        c.ellipse(Int(x), y, rx, 3, C(0xB8A0D8, 0.28))
        c.ellipse(Int(x) + rx / 3, y - 2, rx / 2, 2, C(0xD8C4F0, 0.22))
    }
}

/// Castle Greyskull at dusk, the mist in the chasm, at frame size.
private func dusk(_ ctx: CGContext, t: Double) {
    let c = place(.eterniaGreyskull, floorRows: introFloor, t: t)
    let mist = PixelCanvas(c.w, c.h)
    chasmMist(mist, t: t)
    c.paste(mist)
    blit(c, ctx)
}

/// The jawbridge's mouth at frame size (fx pixels, y down): where the camera plunges.
private func mouth() -> (x: Double, y: Double) {
    let c = PixelCanvas(fxW, fxH)
    let f = Scenes.eterniaGreyskullFrame(c, fxH - introFloor)
    return (Double(f.mouth.x) + Double(f.mouth.w) / 2, Double(f.mouth.y) + 6)
}

/// The Power Sword held straight up, its fist at (`x`, `hand`) on the fx canvas: a dark outline, a silver blade
/// `blade` rows long lit down its left, a two-tone crossguard, the grip in a bronze fist; `glint` 0…1 runs a twinkle
/// up the blade.
private func raisedSword(_ c: PixelCanvas, x: Int, hand: Int, arm: Int, blade: Int, glint: Double) {
    let ink = C(0x1E1828), steel = C(0xD4D8E2), lit = C(0xF8FAFF), shade = C(0x7E8290), guardL = C(0xE2E4EC)
    let tip = hand - 4 - blade
    c.rect(x - 2, tip - 1, 4, blade + 2, ink)
    c.rect(x - 1, tip, 2, blade, steel); c.rect(x - 1, tip, 1, blade, lit); c.rect(x, tip + 1, 1, blade - 1, shade)
    c.rect(x - 1, tip - 1, 2, 1, ink); c.px(x - 1, tip, lit)
    c.rect(x - 4, hand - 4, 8, 3, ink); c.rect(x - 3, hand - 3, 6, 1, guardL)
    c.rect(x - 2, hand - 1, 4, arm + 2, ink); c.rect(x - 1, hand, 2, arm, C(0xF0B48C))   // the fist and the arm up to it
    c.rect(x - 1, hand + arm - 3, 2, 3, C(0xB8A8E0))
    if glint > 0 && glint < 1 {
        let gy = hand - 5 - Int(glint * Double(blade - 2))
        for i in -2...2 { c.px(x + i, gy, C(0xFFFFFF)); c.px(x, gy + i, C(0xFFFFFF)) }
        c.px(x - 3, gy, C(0xFFE07A)); c.px(x + 3, gy, C(0xFFE07A)); c.px(x, gy - 3, C(0xFFE07A)); c.px(x, gy + 3, C(0xFFE07A))
    }
}

/// The first part, wide: Addam rides in on Cringer, stops at the edge and raises the sword, the camera easing in.
private func ridesIn(_ ctx: CGContext, l: Double, t: Double) {
    let push = 1 + 0.07 * easeOut(l / closeUp)
    let focus = CGPoint(x: heroX * 6, y: Double(H) - 120 * 6)
    ctx.saveGState()
    ctx.translateBy(x: focus.x, y: focus.y); ctx.scaleBy(x: push, y: push); ctx.translateBy(x: -focus.x, y: -focus.y)
    dusk(ctx, t: t)
    let ride = easeOut(l / addamStops)
    let stopped = l > addamStops - 0.1
    // Cringer, trembling once he's stopped and the sword is out.
    let shiver: Double = stopped && Int(t * 24) % 2 == 0 ? 0.5 : 0
    var cringer = Actor(cast: .hero(EterniaHero.cringer), x: lerp(-50, heroX, ride) + shiver, facing: 1, mode: .idle)
    cringer.walking = !stopped
    // Addam riding on his back, then up with the sword.
    var addam = Actor(cast: .hero(EterniaHero.princeAddam), x: lerp(-50, heroX, ride) + 1 + shiver, facing: 1, mode: .idle)
    addam.sitting = false
    addam.lift = 15 + (cringer.walking ? abs(sin(t * 9)) * 1.5 : 0)
    if l > swordUp { addam.role = .ready(urgent: false) }
    draw(cringer, ctx, t: t)
    draw(addam, ctx, t: t)
    // The sword: drawn from behind him and raised in his fist, the blade catching the light at the top.
    if l > swordUp {
        let up = easeOut((l - swordUp) / 0.3)
        let c = PixelCanvas(fxW, fxH)
        let hx = Int(addam.x.rounded()) + 11, hy = Int((groundY - addam.lift - 13 - 6 * up).rounded())
        raisedSword(c, x: hx, hand: hy, arm: Int((6 * up).rounded()) + 4, blade: 16, glint: (l - swordUp - 0.3) / 0.4)
        blit(c, ctx)
    }
    let head = headPoint(addam)
    ctx.restoreGState()
    // "By the power of Greyskull!"
    if l > swordUp + 0.15 {
        let a = clamp((l - swordUp - 0.15) / 0.15)
        balloon("By the power of Greyskull!", ctx, center: CGPoint(x: 1000, y: 900), tail: head, size: 54, width: 900, alpha: a)
    }
}

/// The last part, wide again: He-Clawd where Addam was, sword high and crackling, Battle Kat roaring beside him,
/// "I HAVE THE POWER!", the title rising in stone, then the plunge through the jawbridge.
private func heStandsShot(_ ctx: CGContext, l: Double, t: Double, plain: Bool = false) {
    let m = mouth()
    let dive = easeIn((l - plunge) / (eterniaIntroLength - plunge - 0.15))
    let zoom = 1 + 9 * dive
    let target = CGPoint(x: m.x * 6, y: Double(H) - m.y * 6)
    ctx.saveGState()
    ctx.translateBy(x: target.x, y: target.y); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -target.x, y: -target.y)
    dusk(ctx, t: t)
    let since = l - heStands
    var kat = Actor(cast: .hero(EterniaHero.battleKat), x: katX, facing: 1, mode: .idle)
    kat.role = .cheer
    kat.lift = since < 1.2 ? abs(sin(since * 7)) * 3 : 0
    var he = Actor(cast: .hero(EterniaHero.heClawd), x: heroX, facing: 1, mode: .idle)
    he.role = .ready(urgent: false)
    draw(kat, ctx, t: t)
    draw(he, ctx, t: t)
    // The power still crackling round him as the white clears.
    let crackle = 1 - clamp(since / 1.1)
    if crackle > 0 {
        let c = PixelCanvas(fxW, fxH)
        let tick = Int(t * 14)
        for i in 0..<4 where noise(tick * 3 + i) < 0.4 + crackle * 0.6 {
            let a = Double(i) / 4 * 2 * .pi + Double(tick) * 0.7
            let cx = heroX + cos(a) * 16, cy = 128 + sin(a) * 14
            let end = (cx + cos(a + 1.3) * 7, cy + sin(a + 1.3) * 7)
            eterniaReelBolt(c, eterniaReelJag(from: (cx, cy), to: end, steps: 3, amp: 2, seed: tick * 7 + i), core: 1)
        }
        blit(c, ctx)
    }
    // The title, rising over the castle out of the dusk, the scene dimming under it in steps.
    let dim = (clamp((l - titleRise) / 0.4) * 4).rounded() / 4 * 0.4
    if dim > 0 && !plain { ctx.setFillColor(hexColor(0x140A24, dim)); ctx.fill(fullRect) }
    if l > titleRise && !plain {
        let up = backOut((l - titleRise) / 0.7)
        let y = 860 - 260 * (1 - up)
        eterniaDrawTitle(ctx, center: CGPoint(x: Double(W) / 2, y: y), scale: 7.0 / 6, alpha: clamp((l - titleRise) / 0.2),
                         glint: (l - titleRise - 0.6) / 0.5)
    }
    ctx.restoreGState()
    // "I HAVE THE POWER!"
    if since > 0.15 && since < 1.1 && !plain {
        let a = clamp((since - 0.15) / 0.12) * (1 - clamp((since - 0.9) / 0.2))
        balloon("I HAVE THE POWER!", ctx, center: CGPoint(x: 1000, y: 880), tail: headPoint(he), size: 64, width: 1000, alpha: a)
    }
    // And through the jawbridge into white.
    let white = clamp((l - plunge - 0.4) / 0.25)
    if white > 0 { ctx.setFillColor(CGColor(gray: 1, alpha: white)); ctx.fill(fullRect) }
}

/// The title sequence.
func eterniaIntro(_ ctx: CGContext, local l: Double, t: Double) {
    if l < closeUp {
        ridesIn(ctx, l: l, t: t)
        return
    }
    if l < heStands {
        // The close-up: the app's own Greyskull trip, from the fist rising to the white clearing on He-Clawd.
        let k = tripFrom + (l - closeUp) / (heStands - closeUp) * (1 - tripFrom)
        guard let old = shotImage({ dusk($0, t: t) }) else { return }
        var new = old
        if k >= 0.86, let img = shotImage({ heStandsShot($0, l: heStands, t: t, plain: true) }) { new = img }
        EterniaTrip(kind: .greyskull).drawGreyskull(ctx, old: old, new: new, k: min(0.999, k), in: fullRect)
        return
    }
    heStandsShot(ctx, l: l, t: t)
}
