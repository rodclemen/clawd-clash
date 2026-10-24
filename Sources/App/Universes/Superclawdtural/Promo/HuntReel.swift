import AppKit

// The Superclawdtural trailer: `REEL=hunters build/renderpromo video promo` → promo/superclawdtural-promo.mp4. Drawn
// with RenderPromo's kit (Tools/RenderPromo/Kit: `Shot`, `brawl`, `windowShot`, `statusOf`, `agentsOf`, `everyAI`,
// `Mix`…) and compiled only into that tool, never into the app: Tools/universes.sh keeps the folder's Promo/ out of it.
//
// It opens with The Road So Far, the app's own trip played slowly over stills of the show's places, and ends it by
// plunging into a pair of headlights; then the set piece, a demon smoked out at the Roadhouse; then the shared shots.
//   source Tools/universes.sh && swiftc … (Tools/RenderPromo/main.swift's header has the whole command)
//   REEL=hunters build/renderpromo storyboard promo   the storyboard sheet, from `beats`
//   REEL=hunters build/renderpromo check               every frame once

/// The trailer, as the tool asks for it (`PromoReel`, Tools/RenderPromo/Kit/Reel.swift).
struct HuntReel: PromoReel {
    /// Its REEL name (the manifest's `reel`), its video's file name and the GitHub-sized copy's.
    let name = "hunters", base = "superclawdtural-promo", small = "Superclawdtural"
    var title: String { universe.title.uppercased() }
    /// What Gemini's terminal is busy with on the desktop, in the universe's voice.
    let geminiTask = "gemini ▸ salt and burn the dead branches"
    var shots: [Shot] { huntShots }
    var beats: [(key: Double, beat: Beat)] { huntBeats }
    var universe: Universe { .hunters }
    /// Who's in its desktop brawl, and the caption under the universe's pill (the promo plays this shot too).
    var brawl: BrawlCast {
        BrawlCast(claude: .hero(HuntHero.deanWinclawdster), other: .villain(HuntVillain.clawdley),
                  agent: .hero(HuntHero.bobbyClawdsinger), otherAgent: .villain(HuntVillain.azazel),
                  line: universe.isReleased ? "Or hit the road in \(universe.title)." : "Coming soon: \(universe.title).",
                  sub: "Rock salt, devil's traps and a '67 Impala.")
    }
    /// Who's in its window, and what you asked them (the promo plays this shot too).
    var window: WindowCast {
        WindowCast(place: .huntBunker, claude: .hero(HuntHero.deanWinclawdster), other: .villain(HuntVillain.clawdley),
                   agentA: .hero(HuntHero.samWinclawdster), agentB: .hero(HuntHero.clawdstiel), extra: .villain(HuntVillain.megMasters),
                   prompt: "You: “salt and burn the flaky tests”", otherPrompt: "You: “make a deal for the merge”")
    }
    func sound(_ m: Mix) { huntSound(m) }
    /// Its panel on the promo's comic page: Dean against Clawdley, and the trailer's demon smoke pouring out of Meg
    /// over the devil's trap, with a roar and a thud as it goes into the floor.
    var comic: ComicPanel? {
        ComicPanel(hero: .hero(HuntHero.deanWinclawdster), villain: .villain(HuntVillain.clawdley), sound: "KA-CHUNK!", pop: (0x4A6AE8, 0x9CB0FF),
                   word: "HISSSS!", piece: { huntSmokeOut($0, local: smokeAt - 0.3 + $1, t: $2) },
                   hit: { m, at in m.roar(at + 0.05, 0.9, vol: 0.14); m.boom(at + 0.8, vol: 0.18) })
    }
}

/// The end card's line under "Have fun. Keep track.": never a count of universes.
let huntTagline = "One of many universes in Clawd Clash · free for macOS"

/// A Superclawdtural character's name, as the app has it.
func huntName(_ h: HuntHero) -> String { Cast.hero(h).name }
func huntName(_ v: HuntVillain) -> String { Cast.villain(v).name }

// MARK: Pixel helpers

/// Noise from a pair of numbers, 0…1.
private func rnd2(_ a: Int, _ b: Int) -> Double { noise((a &* 7919 &+ b &* 104_729) & 0xFFFFF) }

/// Smooth value noise in 0…1: random values on a unit grid, eased between (the smoke's churn).
private func valueNoise(_ x: Double, _ y: Double, _ seed: Int) -> Double {
    let x0 = floor(x), y0 = floor(y)
    let fx = x - x0, fy = y - y0
    let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
    func at(_ i: Double, _ j: Double) -> Double { noise((Int(i) &* 7919 &+ Int(j) &* 104_729 &+ seed &* 31) & 0xFFFFF) }
    let a = at(x0, y0), b = at(x0 + 1, y0), c = at(x0, y0 + 1), d = at(x0 + 1, y0 + 1)
    return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy
}

/// A pixel canvas the size of the frame's pixel art, onto the whole frame, crisp.
private func show(_ c: PixelCanvas, _ ctx: CGContext, alpha: Double = 1) {
    guard alpha > 0.01, let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none; ctx.setAlpha(CGFloat(alpha))
    ctx.draw(img, in: CGRect(x: 0, y: Double(H) - Double(c.h) * 6, width: Double(c.w) * 6, height: Double(c.h) * 6))
    ctx.restoreGState()
}

/// SUPERCLAWDTURAL in the trips' lettering at `p` pixels a dot, smouldering: a face of orange embers seething frame
/// by frame, hot yellow along the edges and the tops of the strokes, a black edge round it and a rust drop shadow,
/// short flames licking off the tops. `x`, `y` is the top-left; `heat` 0…1 fades the flames and the seething in.
private func emberTitle(_ c: PixelCanvas, centreX cx: Int, y y0: Int, p: Int, t: Double, heat: Double) {
    let title = "SUPERCLAWDTURAL"
    let w = c.w, h = c.h
    let x0 = cx - huntTripTextWidth(title, p) / 2
    let mask = PixelCanvas(w, h)
    huntTripText(mask, x0, y0, title, C(0xFFFFFF), p)
    func on(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && mask.buf[(y * w + x) * 4 + 3] > 127 }
    let frame = Int(t * 12)
    let span = huntTripTextWidth(title, p)
    for y in max(0, y0 - 2 * p)..<min(h, y0 + 5 * p + 4) {
        for x in max(0, x0 - 3)..<min(w, x0 + span + 4) where !on(x, y) {
            if on(x - 1, y) || on(x + 1, y) || on(x, y - 1) || on(x, y + 1) { c.px(x, y, C(0x0A0706)) }
            else if on(x - 2, y - 2) || on(x - 3, y - 3) || on(x - 2, y - 3) { c.px(x, y, C(0x7A3218)) }
        }
    }
    for y in max(0, y0)..<min(h, y0 + 5 * p) {
        for x in max(0, x0)..<min(w, x0 + span) where on(x, y) {
            let edge = !on(x - 1, y) || !on(x + 1, y) || !on(x, y - 1) || !on(x, y + 1)
            let seethe = rnd2(x / 2 + frame * 3, y / 2 + frame)
            let col: Px
            if edge { col = seethe < 0.3 * heat ? C(0xFFE07A) : C(0xFFB23A) }
            else { col = seethe < 0.4 ? C(0xE86A1C) : (seethe < 0.8 || heat < 0.5 ? C(0xC8461A) : C(0xFF9A30)) }
            c.px(x, y, col)
            if !on(x, y - 1), heat > 0.05 {                                   // a flame off the top of the stroke
                let tall = Int((rnd2(x / 2, frame + 400) * 1.1 + 0.2) * Double(p) * 0.8 * heat)
                if tall > 0 {
                    for f in 1...tall {
                        let up = Double(f) / Double(tall)
                        c.px(x, y - f, up < 0.45 ? C(0xFFC24A, 0.85) : (up < 0.8 ? C(0xF0701E, 0.7) : C(0xC0301A, 0.5)))
                    }
                }
            }
        }
    }
}

// MARK: The Road So Far

/// The stills the intro flashes past: frame-sized pictures of the show's places, made the first time they're needed
/// (a `static let`, since the frame's globals aren't set up yet when this file's globals are).
enum HuntStills {
    static let black: CGImage? = shotImage { $0.setFillColor(CGColor(gray: 0, alpha: 1)); $0.fill(fullRect) }
    static func of(_ l: Location) -> CGImage? { shotImage { blit(place(l, floorRows: 34, t: 2.0), $0) } }
    static let lawrence = of(.huntLawrence), crossroads = of(.huntCrossroads), stull = of(.huntStull), bunker = of(.huntBunker)
}

/// The intro's beats (shot-local seconds): the film comes up on black, THE ROAD SO FAR stamps on, the stills, the
/// title burning in, NOW, and the headlights.
let huntIntroLength = 9.0
private let stampFrom = 0.5, stampTo = 2.5, stillsFrom = 2.5, stillLen = 0.48, burnFrom = 5.38, burnTo = 7.3, nowTo = 8.05

/// The stills, in order: the picture (nil: the trip's own art for that slot), and which of the trip's five still slots
/// it plays in, so it gets that slot's framing: 0 close on the left, 1 Baby on the road, 2 close on the right, 3 the
/// yellow eyes, 4 the whole place.
private let introStills: [(img: () -> CGImage?, slot: Int)] = [
    ({ HuntStills.lawrence }, 4), ({ nil }, 1), ({ HuntStills.crossroads }, 4), ({ nil }, 3), ({ HuntStills.stull }, 4),
    ({ HuntStills.bunker }, 0),
]
private let slotEnds = [0.196, 0.393, 0.607, 0.804, 1.0]

/// Where The Road So Far's own frame stands at a moment of the intro, and the picture it's played over.
private func introK(_ l: Double) -> (k: Double, old: CGImage?) {
    let black = HuntStills.black
    if l < stampFrom { return (0.07 * l / stampFrom, black) }
    if l < stampTo { return (0.07 + 0.23 * (l - stampFrom) / (stampTo - stampFrom), black) }
    let stillsTo = stillsFrom + Double(introStills.count) * stillLen
    if l < stillsTo {
        let i = min(introStills.count - 1, Int((l - stillsFrom) / stillLen))
        let u = (l - stillsFrom - Double(i) * stillLen) / stillLen
        let s = introStills[i]
        let a = s.slot == 0 ? 0 : slotEnds[s.slot - 1], b = slotEnds[s.slot]
        return (0.3 + 0.28 * (a + (b - a) * u * 0.999), s.img() ?? black)
    }
    if l < burnTo { return (0.58 + 0.22 * clamp((l - burnFrom) / (burnTo - burnFrom)), black) }
    return (0.8 + 0.0999 * clamp((l - burnTo) / (nowTo - burnTo)), black)
}

/// The headlights, coming at us out of the dark (`f` 0…1): two round lamps low in the middle, far off, swelling, each
/// in a halo stepped from warm white through pale yellow to amber, until they fill the frame in white.
private func headlights(_ ctx: CGContext, f: Double, t: Double) {
    let c = PixelCanvas(fxW, fxH)
    c.rect(0, 0, fxW, fxH, C(0x050403))
    let z = 0.04 + pow(f, 2.2) * 3.2
    let cx = Double(fxW) / 2, cy = Double(fxH) * 0.56 + f * 10
    let gap = 70 * z, r = 9 * z
    let bands: [(Double, UInt32, Double)] = [(3.2, 0x5A3410, 0.5), (2.3, 0x9A6A22, 0.6), (1.6, 0xE0B050, 0.75), (1.15, 0xFFE8A8, 1), (0.8, 0xFFFFFF, 1)]
    for (scale, col, a) in bands {
        let rr = max(1, Int(r * scale))
        for side in [-1.0, 1.0] { c.ellipse(Int(cx + side * gap / 2), Int(cy), rr, max(1, Int(Double(rr) * 0.8)), C(col, a)) }
    }
    show(c, ctx)
    let white = clamp((f - 0.72) / 0.28)
    if white > 0 { ctx.setFillColor(CGColor(gray: 1, alpha: white)); ctx.fill(fullRect) }
}

/// The intro: The Road So Far, the app's own signature trip, slowed down and played over the show's places on film:
/// grain on black, THE ROAD SO FAR stamped on a word at a time, six jumpy stills (the house in Lawrence, Baby on the
/// road, the crossroads, yellow eyes in the dark, Stull, the Bunker), SUPERCLAWDTURAL burning in on black, NOW in red,
/// and then a pair of headlights rushing at us out of the dark into white.
func huntIntro(_ ctx: CGContext, local l: Double, t: Double) {
    if l >= nowTo { headlights(ctx, f: clamp((l - nowTo) / (huntIntroLength - nowTo)), t: t); return }
    let (k, old) = introK(l)
    guard let o = old, let n = HuntStills.black else { return }
    HuntTrip(kind: .roadSoFar).drawRoadSoFar(ctx, old: o, new: n, k: k, in: fullRect)
}

// MARK: Smoke them out

/// The set piece's timings (shot-local seconds).
let huntSmokeLength = 9.5
private let roadTo = 2.1                                      // the Impala pulls up, then inside
private let walkIn = 2.2, grin = 3.2, stepUp = 4.0, kick = 4.9, stuck = 5.3, rite = 5.9, smokeAt = 6.9, gone = 8.3, pie = 8.4
private let rugX = 192.0, megBar = 258.0, deanStop = 126.0, samStop = 90.0
private let floorRow = 150.0
/// Inside, the camera is in close: the Roadhouse half as big again (9 screen pixels to a pixel), from `roomLeft` on.
private let roomZoom = 1.5, roomLeft = 62.0

/// The Impala pulling up on the open road at night, her headlight beam on the road ahead, out of the white of the
/// headlights.
private func impalaArrives(_ ctx: CGContext, local l: Double, t: Double) {
    blit(place(.huntRoad, floorRows: 34, t: t), ctx)
    ctx.setFillColor(CGColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 0.2)); ctx.fill(fullRect)
    let f = easeOut(l / 1.6)
    let x = lerp(-120, 140, f)                               // her middle, fx units; she's drawn twice the ride's size
    let moving = l < 1.6
    let car = PixelCanvas(Ride.width, Ride.height)
    huntDrawImpala(car, ramp: 0, moving: true, t: moving ? t : 1.6)
    car.addOutline(C(0xFFFFFF, 0.92))
    // The beam: a long cone on the road ahead of her nose, pale warm light in stepped bands.
    let beam = PixelCanvas(fxW, fxH)
    let nose = Int(x) + Ride.width - 2, ly = Int(floorRow) - 22
    for b in 0..<3 {
        let len = [150, 100, 55][b], a = [0.12, 0.18, 0.26][b]
        for dx in 0..<len {
            let spread = 2 + dx * (b == 0 ? 22 : 16) / 100
            beam.rect(nose + dx, ly - spread / 3, 1, spread + 4, C(0xFFE8A8, a))
        }
    }
    show(beam, ctx)
    if let img = car.makeImage() {
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.draw(img, in: CGRect(x: (x - Double(Ride.width)) * 6, y: Double(H) - floorRow * 6 - 12,
                                 width: Double(Ride.width) * 12, height: Double(Ride.height) * 12))
        ctx.restoreGState()
    }
    let white = 1 - clamp(l / 0.5)
    if white > 0 { ctx.setFillColor(CGColor(gray: 1, alpha: white)); ctx.fill(fullRect) }
}

/// The rug at the Roadhouse, over the trap: a worn red runner with a dark border and pale fringes, flat on the
/// floor; kicked, it skids away to the right and up, flipping over.
private func drawRug(_ c: PixelCanvas, kicked f: Double) {
    guard f < 1 else { return }
    let w = 74, h = 12
    let x0 = Int(rugX) - w / 2 + Int(f * 200), y0 = Int(floorRow) - 5 - Int(sin(f * .pi) * 30)
    let flip = f > 0 ? max(1, Int(Double(h) * abs(cos(f * 7)))) : h
    let top = y0 + (h - flip) / 2
    c.rect(x0 - 3, top, w + 6, flip, C(0xD8C8A0))                      // the fringes
    c.rect(x0, top, w, flip, C(0x2A1410))
    if flip > 2 {
        c.rect(x0 + 1, top + 1, w - 2, flip - 2, C(0x8A2418))
        c.rect(x0 + 4, top + 2, w - 8, max(1, flip - 4), C(0xA83A22))
        for i in stride(from: 8, to: w - 8, by: 8) { c.px(x0 + i, top + flip / 2, C(0xE0B050)) }
    }
}

/// The devil's trap painted on the floorboards, seen low and flat: the outer ring, the five-pointed star, the inner
/// ring and the marks between, in red paint with a dark edge; `glow` 0…1 lights it up hot, `pulse` makes it throb.
private func drawTrap(_ c: PixelCanvas, glow: Double, pulse: Double) {
    let cx = rugX, cy = floorRow + 1, rx = 32.0, ry = 5.5
    let paint = C(0xB0241E), lit = C(0xFF6A3A), edge = C(0x3A0606)
    let star: [(Double, Double)] = (0..<5).map { i in
        let a = (-90 + Double(i) * 72) * .pi / 180
        return (cos(a) * 0.74, sin(a) * 0.74)
    }
    for y in Int(cy - ry - 3)...Int(cy + ry + 3) {
        for x in Int(cx - rx - 3)...Int(cx + rx + 3) {
            let u = (Double(x) + 0.5 - cx) / rx, v = (Double(y) + 0.5 - cy) / ry
            let d = (u * u + v * v).squareRoot()
            var dist = min(abs(d - 0.96), abs(d - 0.76)) * rx                    // the rings, in pixels across
            for i in 0..<5 {
                let a = star[i], b = star[(i + 2) % 5]
                let vx = b.0 - a.0, vy = b.1 - a.1
                let s = max(0, min(1, ((u - a.0) * vx + (v - a.1) * vy) / (vx * vx + vy * vy)))
                let ex = (a.0 + vx * s - u) * rx, ey = (a.1 + vy * s - v) * ry
                dist = min(dist, (ex * ex + ey * ey * 4).squareRoot())
            }
            if d > 0.78 && d < 0.94 && Int(atan2(v, u) * 6 + 20) % 2 == 0 && abs(v) < 0.6 { dist = min(dist, 0.3) }
            if dist < 0.7 {
                c.px(x, y, glow > 0.5 && (pulse > 0.5 || d < 0.5) ? lit : paint)
            } else if dist < 1.4 {
                c.px(x, y, glow > 0.1 ? C(0xFF3A1A, 0.35 * glow) : edge)
            }
        }
    }
    if glow > 0 {                                                      // the heat coming up off it
        for i in 0..<14 {
            let f = frac(Double(i) * 0.37 + pulse * 0.2)
            c.px(Int(cx - rx + noise(i + 70) * rx * 2), Int(cy - f * 24), C(0xFF6A3A, glow * (1 - f)))
        }
    }
}

/// The demon smoke, `s` seconds after it starts: a column bursting up out of the demon's mouth at `mouth`, twisting,
/// rolling out along the ceiling, then drawing in to a funnel that pours down into the middle of the trap, its tail
/// going in last. Near-black purple in three tones, but every edge lit mauve, red or hot orange and hellfire glowing
/// through it in dull red patches, so it reads on the dark Roadhouse and on a dark desktop.
private func drawSmoke(_ c: PixelCanvas, s: Double, mouth: (x: Double, y: Double)) {
    let w = c.w, h = c.h
    let rise = easeOut(s / 0.6), spread = easeOut((s - 0.35) / 0.6)
    let draw = clamp((s - 0.9) / 0.35), sink = clamp((s - 1.05) / 0.3)
    let pour = (x: rugX, y: floorRow + 1)
    let ceiling = 64.0
    func inside(_ x: Double, _ y: Double) -> Double {
        let churn = (valueNoise(x / 7 + s * 1.5, y / 6 - s * 5, 5) - 0.5) * 10 + (valueNoise(x / 3 - s * 3, y / 3 - s * 9, 9) - 0.5) * 4
        let lumps = (valueNoise(x / 18 + s * 0.8, y / 14 - s * 2.5, 41) - 0.5) * 22
        if draw <= 0 {
            var d = -99.0
            let up = mouth.y - y
            let top = mouth.y - rise * (mouth.y - ceiling + 6)
            if y < mouth.y + 2 && y > top {
                let sway = sin(up * 0.12 - s * 13) * min(1, up / 30) * 5
                d = min(3 + up * 0.28 - abs(x - mouth.x - sway), (y - top) * 0.8)
            }
            if spread > 0 {                                           // rolling out along the ceiling
                let band = ceiling + spread * 26 - abs(x - mouth.x) * (0.55 - spread * 0.35)
                d = max(d, band - y + lumps * spread)
            }
            return d + churn
        }
        // The funnel: from the cloud along the ceiling, narrowing down to the trap, its tail sinking into it.
        guard y < pour.y + 2 else { return -99 }
        var d = (ceiling + 26) * (1 - sink) - y + lumps * (1 - draw * 0.6)
        let tail = sink * (pour.y + 6) - 6
        if y > tail {
            let down = max(0, pour.y - y), u = down / (pour.y - ceiling)
            let rad = (2.5 + 3 * (1 - sink)) + 90 * (1 - draw * 0.85) * pow(u, 2.2)
            let sway = sin(down * 0.12 - s * 15) * min(1, down / 30) * (2 + 5 * (1 - sink))
            d = max(d, min(rad - abs(x - pour.x - sway), (y - tail) * 0.8))
        }
        return d + churn * (0.4 + 0.6 * (1 - draw))
    }
    let body = [C(0x0A0608), C(0x160C12), C(0x24141E), C(0x3A2436)]
    let fire = [C(0x16060A), C(0x260810), C(0x3A0C16), C(0x58121C)]
    let rimMauve = C(0x8A7088), rimRed = C(0xB02828), rimHot = C(0xFF6A3A)
    var d = [Double](repeating: -1, count: w * h)
    for y in 0..<h { for x in 0..<w { d[y * w + x] = inside(Double(x), Double(y)) } }
    for y in 0..<h {
        for x in 0..<w {
            let v = d[y * w + x]
            guard v > 0 else { continue }
            let edge = v < 1.2 || (x > 0 && d[y * w + x - 1] <= 0) || (x + 1 < w && d[y * w + x + 1] <= 0)
                || (y > 0 && d[(y - 1) * w + x] <= 0) || (y + 1 < h && d[(y + 1) * w + x] <= 0)
            let fx = Double(x), fy = Double(y)
            if edge {
                let n = valueNoise(fx / 4 + s * 2, fy / 4 - s * 6, 21)
                c.px(x, y, n > 0.7 ? rimHot : n > 0.45 ? rimRed : rimMauve)
                continue
            }
            if v < 2.6 { c.px(x, y, C(0x3A2432)); continue }
            let tone = valueNoise(fx / 11 - s * 1.2, fy / 8 - s * 4, 13) * 0.7 + valueNoise(fx / 4 - s * 2, fy / 3 - s * 7, 17) * 0.3
            let glow = v > 4 ? valueNoise(fx / 16 + s * 0.6, fy / 12 - s * 3, 37) : 0
            c.px(x, y, (glow > 0.68 ? fire : body)[min(3, Int(tone * 4.4))])
        }
    }
}

/// Smoke them out: the Impala pulls up on the road at night; inside the Roadhouse a black-eyed demon at the bar
/// grins at the boys and steps up to meet them, onto the rug; Dean kicks the rug away and there's the devil's trap
/// under her. She can't move. Sam reads the exorcism off his laptop, she thrashes, the smoke pours out of her mouth,
/// rolls along the ceiling and funnels down into the floor in a red flash. Dean takes a bite of pie.
func huntSmokeOut(_ ctx: CGContext, local l: Double, t: Double) {
    if l < roadTo { impalaArrives(ctx, local: l, t: t); return }
    ctx.saveGState()
    ctx.translateBy(x: -roomLeft * 6 * roomZoom, y: 0); ctx.scaleBy(x: roomZoom, y: roomZoom)
    set(ctx, .huntRoadhouse, t: t)
    let fx = PixelCanvas(fxW, fxH)
    // the trap, under the rug until Dean kicks it away
    let kicked = clamp((l - kick) / 0.8)
    let trapGlow = clamp((l - stuck) / 0.3) * (1 - 0.6 * clamp((l - gone - 0.3) / 0.6))
    let pulse = 0.5 + 0.5 * sin(l * 16)
    drawTrap(fx, glow: trapGlow, pulse: pulse)
    drawRug(fx, kicked: kicked)
    show(fx, ctx)

    // the boys walk in from the left
    var sam = Actor(cast: .hero(HuntHero.samWinclawdster), x: lerp(-50, samStop, easeOut((l - walkIn - 0.15) / 1.0)), facing: 1, mode: .idle)
    sam.walking = l < walkIn + 1.1
    let lunge = sin(clamp((l - kick + 0.15) / 0.4) * .pi)
    var dean = Actor(cast: .hero(HuntHero.deanWinclawdster), x: lerp(-20, deanStop, easeOut((l - walkIn) / 1.0)) + lunge * 26, facing: 1, mode: .idle)
    dean.walking = l < walkIn + 1.0 || (lunge > 0.05 && lunge < 0.95)
    // the demon: at the bar, grinning, steps up onto the rug, stuck, thrashing, then gone in the smoke
    let step = easeOut((l - stepUp) / 0.8)
    let thrash = l > rite + 0.2 && l < gone - 0.3
    var meg = Actor(cast: .villain(HuntVillain.megMasters), x: lerp(megBar, rugX, step) + (thrash ? sin(t * 50) * 1.5 : 0), facing: -1, mode: .idle)
    meg.walking = (l > stepUp && l < stepUp + 0.75) || (l > stuck && l < rite)
    if l > stuck && l < rite { meg.x += sin(t * 30) * 0.8 }
    meg.role = thrash ? .hit : .none
    meg.alpha = 1 - clamp((l - smokeAt - 0.4) / 0.9)

    // Sam's laptop: his signature, the rite read off the screen
    let samSig = 1.6
    forcedHabit = l > rite - 0.2 && l < rite - 0.2 + samSig ? HabitPlay(kind: .signature, e: l - rite + 0.2, length: samSig) : nil
    draw(sam, ctx, t: t)
    let pieLen = 1.2
    forcedHabit = l > pie ? HabitPlay(kind: .signature, e: min(l - pie, pieLen), length: pieLen) : nil
    draw(dean, ctx, t: t)
    let megSig = 0.9
    forcedHabit = l > grin && l < grin + megSig ? HabitPlay(kind: .signature, e: l - grin, length: megSig) : nil
    if meg.alpha > 0 { draw(meg, ctx, t: t) }
    forcedHabit = nil

    // the smoke, out of her mouth and down into the trap
    if l > smokeAt && l < gone + 0.1 {
        let smoke = PixelCanvas(fxW, fxH)
        let head = meg.top + Double(meg.cast.headTop) * meg.k
        drawSmoke(smoke, s: l - smokeAt, mouth: (rugX - 6, head + 10 * meg.k))
        show(smoke, ctx)
    }
    // the flash as it goes in: white-hot, then red, stepped down
    let flash = clamp((l - gone) / 0.35)
    if flash > 0 && flash < 1 {
        ctx.setFillColor(flash < 0.2 ? hexColor(0xFFE8DC, 0.6) : hexColor(0xF01C14, ((1 - flash) * 0.55 * 8).rounded() / 8))
        ctx.fill(fullRect)
    }

    ctx.restoreGState()
    // what's said, in the frame's own coordinates
    func onScreen(_ p: CGPoint) -> CGPoint { CGPoint(x: (p.x - roomLeft * 6) * roomZoom, y: p.y * roomZoom) }
    let megHead = onScreen(headPoint(meg)), samHead = onScreen(headPoint(sam))
    let hi = clamp((l - grin - 0.1) / 0.1) * (1 - clamp((l - stepUp - 0.3) / 0.15))
    balloon("Hey there, boys.", ctx, center: CGPoint(x: megHead.x - 120, y: megHead.y + 190), tail: CGPoint(x: megHead.x - 20, y: megHead.y + 20),
            size: 38, alpha: hi)
    let oops = clamp((l - stuck - 0.1) / 0.1) * (1 - clamp((l - rite) / 0.15))
    balloon("Oh, you're kidding me.", ctx, center: CGPoint(x: megHead.x + 40, y: megHead.y + 200), tail: CGPoint(x: megHead.x, y: megHead.y + 20),
            size: 38, alpha: oops)
    let latin = clamp((l - rite) / 0.1) * (1 - clamp((l - smokeAt - 0.6) / 0.2))
    balloon("Exorcizamus te, omnis immundus spiritus…", ctx, center: CGPoint(x: samHead.x + 360, y: samHead.y + 230),
            tail: CGPoint(x: samHead.x + 30, y: samHead.y + 20), size: 34, width: 560, alpha: latin)
    caption("Saving people. Hunting things.", ctx, local: l, start: pie + 0.1, y: 900, size: 70)
    // in from the road on a hard cut
}

// MARK: The shots

/// Every shot, in order, each with its start and end in seconds and how it comes in (the soft wipe unless it says).
let huntShots: [Shot] = [
    // The Road So Far, slowed down over the show's places, into a pair of headlights.
    Shot(name: "intro", start: 0, end: huntIntroLength, into: .cut) { ctx, local, t in huntIntro(ctx, local: local, t: t) },
    // The Impala pulls up at the Roadhouse, and a demon is smoked out.
    Shot(name: "smoke", start: huntIntroLength, end: huntIntroLength + huntSmokeLength, into: .cut) { ctx, local, t in
        huntSmokeOut(ctx, local: local, t: t)
    },
    Shot(name: "hook", start: 18.5, end: 22.5, into: .cut) { ctx, local, _ in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused hunter.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: 22.5, end: 27.1) { ctx, local, t in
        brawl(ctx, .hunters, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Saving people. Hunting bugs. The family business.", ctx, local: local, start: 0.35, y: 900)
        caption("A pixel-art \(Universe.hunters.title) brawl along the bottom of your screen. They fight while they work.", ctx,
                local: local, start: 0.6, y: 830, size: 36, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: 27.1, end: 31.3) { ctx, local, t in
        let cast: [Cast] = [.hero(HuntHero.deanWinclawdster), .hero(HuntHero.samWinclawdster), .hero(HuntHero.clawdstiel),
                            .hero(HuntHero.bobbyClawdsinger)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: Universe.hunters.title.uppercased(),
                 aside: "(\(cast[2].name) needs you. \(cast[3].name), napping: “Idjits.”)")
    },
    Shot(name: "agents", start: 31.3, end: 35.3) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .hero(HuntHero.bobbyClawdsinger),
                 crew: [.hero(HuntHero.samWinclawdster), .hero(HuntHero.joHarvell), .hero(HuntHero.charlieClawdbury),
                        .hero(HuntHero.garthFitzclawd)],
                 line: "Every subagent gets to be a hunter.", badgeText: Universe.hunters.title.uppercased())
    },
    // The window comes in on the app's Headlights trip: the Impala drives across and its beams sweep the Bunker in.
    Shot(name: "window", start: 35.3, end: 40.1, into: .trip(ComicTransition(HuntTrip(kind: .headlights)))) { ctx, local, t in
        windowShot(ctx, .hunters, local: local, t: t, rise: true, needsAt: 2.5, at: .huntBunker)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Driver picks the music. Claude picks the tasks.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890,
                size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: 40.1, end: 44.5) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.hero(HuntHero.deanWinclawdster), .hero(HuntHero.samWinclawdster), .villain(HuntVillain.clawdley),
                                                .villain(HuntVillain.azazel), .villain(HuntVillain.lucifer), .villain(HuntVillain.death),
                                                .villain(HuntVillain.leviathanBlob)])
    },
    // The end card: the Bunker, the crew lines up, the title burns in, then the app's icon and where to get it.
    Shot(name: "endcard", start: 44.5, end: 48.7) { ctx, local, t in huntEndcard(ctx, local: local, t: t) },
]

/// The end card, its line under "Have fun. Keep track." never a count of universes.
func huntEndcard(_ ctx: CGContext, local: Double, t: Double) {
    blit(place(.huntBunker, floorRows: 34, t: t), ctx)
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.3)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let crew: [(Cast, FightRole, AI)] = [(.hero(HuntHero.bobbyClawdsinger), .cheer, .copilot), (.hero(HuntHero.samWinclawdster), .cheer, .desktop),
                                         (.hero(HuntHero.deanWinclawdster), .shoot(offset: 0), .claude), (.villain(HuntVillain.clawdley), .zap, .codex),
                                         (.villain(HuntVillain.megMasters), .cheer, .qwen)]
    var placed: [Actor] = []
    for (i, (who, role, ai)) in crew.enumerated() {
        var a = Actor(cast: who, x: [26.0, 74, 128, 206, 262][i], facing: i < 3 ? 1 : -1, role: role, ai: ai)
        a.lift = 8
        a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
        draw(a, ctx, t: t)
        placed.append(a)
    }
    if local > 0.5 { drawFX([(placed[2], placed[3])], ctx, t: t) }
    let lit = clamp((local - 0.35) / 0.5)
    if lit > 0 {
        let c = PixelCanvas(fxW, fxH)
        emberTitle(c, centreX: fxW / 2, y: 40, p: 4, t: t, heat: lit)
        show(c, ctx, alpha: clamp(lit * 3))
    }
    caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
    caption(huntTagline, ctx, local: local, start: 0.8, y: 462, size: 34, color: NSColor(white: 0.85, alpha: 1), weight: .bold)
    let ff = easeOut((local - 0.9) / 0.3)
    if ff > 0, let icon = appIcon {
        ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
        ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
        ctx.draw(icon, in: CGRect(x: 580, y: 20, width: 130, height: 130))
        ctx.restoreGState()
        text("github.com/rodclemen/clawd-clash", ctx, x: 740, y: 60, size: 44, weight: .bold, alpha: ff)
    }
}

// MARK: The storyboard

/// The storyboard's beats: a time in the reel, and its title, what happens, what's on screen and what's heard.
let huntBeats: [(key: Double, beat: Beat)] = [
    (1.6, ("THE ROAD SO FAR", "Black, on old film: grain, dust and a scratch. THE ROAD SO FAR stamps on a word at a time, the frame jolting as each lands.",
           "THE ROAD SO FAR", "a projector's rattle and crackle; a chugging guitar riff and drums kick in, in the sound of seventies classic rock but our own notes; a thump on each word")),
    (4.0, ("THE STILLS", "Jumpy sepia stills, the frame jumping in the gate at each cut: the house in \(Location.huntLawrence.name), Baby on the road at dusk, \(Location.huntCrossroads.name) under the moon, yellow eyes in the dark, \(Location.huntStull.name), \(Location.huntBunker.name).",
           "no text", "the riff, a film splice click at each cut")),
    (6.3, ("THE TITLE", "Black, and SUPERCLAWDTURAL catches fire, a front of flame running along it, the letters smouldering orange, sparks going up.",
           "SUPERCLAWDTURAL", "a big open chord and a crash, the fire crackling")),
    (8.4, ("NOW", "NOW slams on in red; then a pair of headlights rushes at us out of the dark and everything goes white.",
           "NOW", "a slam, the Impala's engine roaring up, a whoosh into the white")),
    (10.0, ("BABY", "Out of the white onto the open road at night: the Impala pulls up, her headlight beam on the road.",
            "no text", "the engine's rumble, the brakes")),
    (12.6, ("THE ROADHOUSE", "Inside \(Location.huntRoadhouse.name): \(huntName(HuntHero.deanWinclawdster)) and \(huntName(HuntHero.samWinclawdster)) walk in. \(huntName(HuntVillain.megMasters)) at the bar turns, her eyes flick black with a glint in them, and she grins.",
            "“Hey there, boys.”", "boots on the boards, a low riff on the bass")),
    (14.2, ("THE TRAP", "She steps up onto the rug to meet them. Dean kicks the rug away: there's a devil's trap painted on the floor under her, glowing red. She can't move.",
            "“Oh, you're kidding me.”", "a whoosh, a hot hum from the trap")),
    (16.2, ("SMOKE OUT", "Sam reads the rite off his laptop; she thrashes, and black smoke with a lit red edge pours out of her mouth, rolls along the ceiling and funnels down into the trap in a red flash.",
            "“Exorcizamus te, omnis immundus spiritus…”", "a rising drone, the smoke's roar, a boom on the flash")),
    (17.9, ("PIE", "All quiet. Dean takes a big bite of pie.", "“Saving people. Hunting things.”", "a chomp, the riff's big chord")),
    (20.5, ("THE HOOK", "Three busy terminals, slow push-in.", "“Three AIs. Nine agents. One very confused hunter.”  →  “Sound familiar?”",
            "keyboard clicks, the groove fading in")),
    (24.8, ("DESKTOP MODE", "\(huntName(HuntHero.deanWinclawdster))'s pistol against \(huntName(HuntVillain.clawdley))'s red touch; \(huntName(HuntHero.bobbyClawdsinger))'s rock salt against \(huntName(HuntVillain.azazel))'s yellow rings.",
            "DESKTOP MODE  ·  “Saving people. Hunting bugs. The family business.”", "footsteps, shots, a crackle of power")),
    (29.2, ("AT A GLANCE", "\(huntName(HuntHero.deanWinclawdster)) working, \(huntName(HuntHero.samWinclawdster)) thinking, \(huntName(HuntHero.clawdstiel)) jumping NEEDS YOU, \(huntName(HuntHero.bobbyClawdsinger)) sat down napping.",
            "“All fun and games, and you still see everything.”  ·  “(\(huntName(HuntHero.clawdstiel)) needs you. \(huntName(HuntHero.bobbyClawdsinger)), napping: “Idjits.”)”", "pops, alert beeps")),
    (33.3, ("SUBAGENTS", "\(huntName(HuntHero.bobbyClawdsinger)) keeps watch; \(huntName(HuntHero.samWinclawdster)), \(huntName(HuntHero.joHarvell)), \(huntName(HuntHero.charlieClawdbury)) and \(huntName(HuntHero.garthFitzclawd)) walk in with their jobs on their labels.",
            "“Every subagent gets to be a hunter.”", "footsteps")),
    (37.7, ("WINDOW MODE", "In on the app's Headlights trip, the Impala's beams sweeping it in; the window in \(Location.huntBunker.name): Dean against \(huntName(HuntVillain.clawdley)), live cards tick, then a card flips to NEEDS YOU.",
            "WINDOW MODE  ·  “Driver picks the music. Claude picks the tasks.”", "the Impala going by, a ping")),
    (42.3, ("EVERY AI", "Seven sessions, one per AI outline: \(huntName(HuntHero.deanWinclawdster)) (Claude Code, a head taller) and \(huntName(HuntHero.samWinclawdster)) against \(huntName(HuntVillain.clawdley)), \(huntName(HuntVillain.azazel)), \(huntName(HuntVillain.lucifer)) and \(huntName(HuntVillain.death)); a \(huntName(HuntVillain.leviathanBlob)) in pi's pink.",
            "BRING YOUR OWN AI*  ·  “One AI plays everyone. Run two and they pick sides.”  ·  *README for the full list", "shots, pops")),
    (47.0, ("END CARD", "\(Location.huntBunker.name): the crew lines up, SUPERCLAWDTURAL burns in in embers, then the icon and the URL.",
            "SUPERCLAWDTURAL  ·  “Have fun. Keep track.”  ·  “\(huntTagline)”  ·  github.com/rodclemen/clawd-clash", "the riff for a bar, a last big chord, the Impala's engine turning over")),
]

// MARK: The sound

extension Mix {
    /// A power chord on the electric guitar, as near as square and saw get: the root, its fifth and the octave on
    /// two saws a hair apart and a thin square, `mute` short and choked (palm-muted) or let ring.
    func huntChord(_ t: Double, _ dur: Double, root: Int, vol: Double, mute: Bool) {
        for (n, v) in [(root, 1.0), (root + 7, 0.8), (root + 12, 0.55)] {
            tone(t, dur, midi(n) * 0.997, wave: .saw, vol: vol * v * 0.5, attack: 0.003, release: mute ? 0.02 : 0.3, decay: mute ? 0.07 : 0)
            tone(t, dur, midi(n) * 1.004, wave: .saw, vol: vol * v * 0.5, attack: 0.003, release: mute ? 0.02 : 0.3, decay: mute ? 0.07 : 0)
            tone(t, dur, midi(n), wave: .square(0.3), vol: vol * v * 0.25, attack: 0.003, release: mute ? 0.02 : 0.3, decay: mute ? 0.05 : 0)
        }
    }
    /// A crash cymbal.
    func huntCrash(_ t: Double, vol: Double = 0.1) { noise(t, 1.6, vol: vol, cutoff: 0.95, decay: 0.5, highpass: true, seed: Int(t * 131)) }
    /// The Impala's V8: a low, lumpy rumble, `rev` 0…1 how hard it's working.
    func huntEngine(_ t: Double, _ dur: Double, rev: Double, to: Double? = nil, vol: Double = 0.08) {
        let f0 = 38 + rev * 30, f1 = 38 + (to ?? rev) * 30
        tone(t, dur, f0, to: f1, wave: .saw, vol: vol, attack: 0.1, release: 0.3, vibrato: 0.08)
        tone(t, dur, f0 * 2, to: f1 * 2, wave: .square(0.25), vol: vol * 0.35, attack: 0.1, release: 0.3, vibrato: 0.11)
        noise(t, dur, vol: vol * 0.8, cutoff: 0.02, cutoffTo: 0.02 + 0.03 * (to ?? rev), attack: 0.1, release: 0.3, seed: Int(t * 77))
    }
    /// The starter whirring and the engine catching.
    func huntTurnOver(_ t: Double, vol: Double = 0.1) {
        for k in 0..<5 {
            noise(t + Double(k) * 0.11, 0.07, vol: vol, cutoff: 0.08, decay: 0.03, seed: 300 + k)
            tone(t + Double(k) * 0.11, 0.07, 110, to: 90, wave: .square(0.4), vol: vol * 0.3, release: 0.02)
        }
        huntEngine(t + 0.55, 1.6, rev: 0.9, to: 0.3, vol: vol)
    }
    /// The film running through the projector: a soft rattle on every film frame, and now and then a crackle.
    func huntProjector(_ t: Double, _ dur: Double, vol: Double = 0.012) {
        var s = t, k = 0
        while s < t + dur {
            noise(s, 0.008, vol: vol * (k % 2 == 0 ? 1 : 0.6), cutoff: 0.5, decay: 0.003, seed: 500 + k)
            if hashNoise(k + 4000) > 0.86 { noise(s, 0.012, vol: vol * 4, cutoff: 0.9, decay: 0.004, highpass: true, seed: 900 + k) }
            s += 1 / 24.0; k += 1
        }
    }
    /// A bite of pie.
    func huntChomp(_ t: Double, vol: Double = 0.14) {
        noise(t, 0.09, vol: vol, cutoff: 0.25, decay: 0.03, seed: 41)
        noise(t + 0.14, 0.07, vol: vol * 0.7, cutoff: 0.2, decay: 0.025, seed: 42)
    }
}

/// The riff, our own notes in the sound of seventies classic rock: palm-muted power chords chugging in eighths on E,
/// a lift to G and A at the end of every other bar, a bass doubling the roots, and the drums (kick, snare on two and
/// four, eighth-note hats). `bars` of 1.8 seconds from `t0`; `vol` scales the lot, `drums` false leaves them out.
func huntRiff(_ m: Mix, from t0: Double, bars: Int, vol: Double = 1, drums: Bool = true) {
    let e = 0.225
    // each bar's eighths: a root (0: rest) and whether it rings
    let a: [(Int, Bool)] = [(40, false), (40, false), (40, false), (43, true), (40, false), (40, false), (45, false), (47, true)]
    let b: [(Int, Bool)] = [(40, false), (40, false), (40, false), (40, false), (43, true), (0, false), (45, true), (0, false)]
    for bar in 0..<bars {
        let s = t0 + Double(bar) * 8 * e
        for (i, (root, ring)) in (bar % 2 == 0 ? a : b).enumerated() where root > 0 {
            let at = s + Double(i) * e
            m.huntChord(at, ring ? e * 1.9 : e * 0.9, root: root, vol: 0.06 * vol, mute: !ring)
            m.tone(at, e * 0.9, midi(root - 12), wave: .triangle, vol: 0.16 * vol, release: 0.03, decay: 0.15)
        }
        guard drums else { continue }
        for i in 0..<8 {
            let at = s + Double(i) * e
            m.hat(at, vol: 0.03 * vol)
            if i == 0 || i == 3 || i == 4 { m.kick(at, vol: 0.28 * vol) }
            if i == 2 || i == 6 { m.snare(at, vol: 0.14 * vol) }
        }
    }
}

/// The score and effects: the projector and the riff under The Road So Far, a thump on each stamped word, a big chord
/// as the title burns in, NOW slammed on and the engine roaring into the headlights; the Impala pulling up, the
/// Roadhouse, the trap, the smoke's roar and the flash, the chomp and a big chord; the shared groove under the app
/// shots, and the riff, a last chord and the engine turning over on the end card.
func huntSound(_ m: Mix) {
    // The Road So Far
    m.huntProjector(0, burnTo + 0.4)
    for (i, at) in [0.08, 0.13, 0.18, 0.225].enumerated() {                // each word landing
        let l = stampFrom + (at - 0.07) / 0.23 * (stampTo - stampFrom)
        m.boom(l, vol: 0.22); m.snare(l, vol: 0.1 + 0.02 * Double(i))
    }
    huntRiff(m, from: stampFrom, bars: 3, vol: 1.2)
    for i in 0..<introStills.count { m.noise(stillsFrom + Double(i) * stillLen, 0.02, vol: 0.08, cutoff: 0.8, decay: 0.008, highpass: true, seed: 60 + i) }
    // the title burning in: one big ringing chord over a crash, the fire crackling
    m.huntChord(burnFrom, 2.2, root: 40, vol: 0.09, mute: false)
    m.tone(burnFrom, 2.2, midi(28), wave: .triangle, vol: 0.2, release: 1.2)
    m.huntCrash(burnFrom, vol: 0.14); m.boom(burnFrom, vol: 0.35)
    m.crackle(burnFrom + 0.1, burnTo - burnFrom, vol: 0.04)
    m.noise(burnFrom, burnTo - burnFrom, vol: 0.04, cutoff: 0.05, attack: 0.3, release: 0.4, seed: 77)   // the fire's roar
    // NOW, and the headlights
    m.boom(burnTo + 0.02, vol: 0.4); m.snare(burnTo + 0.02, vol: 0.2); m.huntCrash(burnTo + 0.02, vol: 0.08)
    m.huntEngine(nowTo - 0.2, huntIntroLength - nowTo + 0.6, rev: 0.4, to: 1.0, vol: 0.1)
    m.whoosh(huntIntroLength - 0.25, 0.8, vol: 0.18)

    // Smoke them out
    let s0 = start("smoke")
    m.huntEngine(s0, 1.7, rev: 0.6, to: 0.15, vol: 0.09)
    m.tone(s0 + 1.35, 0.3, 1800, to: 1300, wave: .square(0.5), vol: 0.012, release: 0.1)   // the brakes
    m.clunk(s0 + roadTo - 0.1, vol: 0.08)                                                 // a door
    for k in 0..<7 { m.step(s0 + walkIn + Double(k) * 0.16, vol: 0.08) }
    for b in 0..<2 {                                                                       // a low riff on the bass
        for (i, n) in [28, 28, 31, 28, 33, 31, 28, 26].enumerated() {
            m.tone(s0 + walkIn + Double(b * 8 + i) * 0.225, 0.2, midi(n), wave: .triangle, vol: 0.12, release: 0.03, decay: 0.15)
        }
    }
    m.tone(s0 + grin + 0.25, 0.3, 1200, to: 2400, wave: .sine, vol: 0.03, release: 0.1)    // the eyes flicking black
    for k in 0..<4 { m.step(s0 + stepUp + Double(k) * 0.18, vol: 0.07) }
    m.whoosh(s0 + kick + 0.15, 0.5, vol: 0.14)
    m.tone(s0 + stuck, rite - stuck + 1.4, 110, wave: .saw, vol: 0.03, attack: 0.1, release: 0.3, vibrato: 0.02)   // the trap's hum
    m.boom(s0 + stuck, vol: 0.2)
    for (i, n) in [40, 43, 47, 52].enumerated() {                                          // the rite: a rising drone
        m.tone(s0 + rite + Double(i) * 0.2, smokeAt + 1.4 - rite - Double(i) * 0.2, midi(n), to: midi(n + 2), wave: .saw, vol: 0.022, attack: 0.4, release: 0.3)
    }
    m.roar(s0 + smokeAt, 1.4, vol: 0.18)
    m.noise(s0 + smokeAt, gone - smokeAt, vol: 0.1, cutoff: 0.03, cutoffTo: 0.2, attack: 0.2, release: 0.1, seed: 88)
    m.boom(s0 + gone, vol: 0.45); m.huntCrash(s0 + gone, vol: 0.06)
    m.huntChomp(s0 + pie + 0.45)
    m.huntChord(s0 + pie + 0.1, 1.0, root: 40, vol: 0.07, mute: false)
    m.kick(s0 + pie + 0.1, vol: 0.3); m.huntCrash(s0 + pie + 0.1, vol: 0.08)

    // the app shots: the shared groove, and each shot's effects
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t, vol: 0.07) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: blasterPeriod / 2) { m.pew(t, vol: 0.05) }
    m.crackle(desk + 0.5, deskEnd - desk - 0.5, vol: 0.02)
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    let wi = start("window")
    m.huntEngine(wi - 1.2, 2.0, rev: 0.7, to: 0.4, vol: 0.06)                              // Baby going by
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    for t in shotTimes(ais + 0.4, end("ais"), offset: 0) { m.pew(t, vol: 0.05) }
    for s in shots { transitionSound(m, s) }
    // the end card: the riff for a bar, a last big chord, and the engine turning over
    let ec = start("endcard")
    huntRiff(m, from: ec, bars: 1, vol: 0.8)
    m.huntChord(ec + 1.8, 2.0, root: 40, vol: 0.09, mute: false)
    m.tone(ec + 1.8, 2.0, midi(28), wave: .triangle, vol: 0.2, release: 1.2)
    m.huntCrash(ec + 1.8, vol: 0.12); m.boom(ec + 1.8, vol: 0.35)
    m.huntTurnOver(ec + 2.4, vol: 0.09)
}
