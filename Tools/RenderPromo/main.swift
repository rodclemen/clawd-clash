import AppKit
import AVFoundation
import CoreText

// Renders Clawd Clash's promo videos with the app's own sprites, places and transitions: the promo (one universe at a
// time, as in the app), the blooper reel (where the universes get mixed up), or both back to back, the Clawd Royale
// teaser, and each universe's own trailer. Each comes with its own synthesized soundtrack. This file has the owner's
// reels, the ones that mix universes; the shared parts are in Tools/RenderPromo/Kit/, and each universe's trailer is in
// its folder, `Promo/<Prefix>Reel.swift`, behind `PromoReel` (Kit/Reel.swift). Build it, then run it from the repo root
// (it reads Resources/AppIcon.png):
//   source Tools/universes.sh && swiftc -O -swift-version 5 Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          $UNIVERSE_APP $UNIVERSE_PROMO Sources/Shared/*.swift Tools/RenderPromo/Kit/*.swift Tools/RenderPromo/main.swift -o build/renderpromo
//   build/renderpromo storyboard promo           → promo/storyboard-promo.png (REEL=bloopers: storyboard-bloopers.png)
//   build/renderpromo video promo                → promo/clawd-clash-promo.mp4 (H.264 + AAC)
//   REEL=bloopers build/renderpromo video promo  → promo/clawd-clash-bloopers.mp4
//   REEL=full build/renderpromo video promo      → promo/clawd-clash-full.mp4: the promo, then the bloopers
//   REEL=starclawds build/renderpromo video promo → promo/star-clawds-promo.mp4: the Star Clawds trailer
//   REEL=marvelous build/renderpromo video promo  → promo/marvelous-clawds-promo.mp4: the Marvelous Clawds trailer
//   REEL=detective build/renderpromo video promo  → promo/detective-clawds-promo.mp4: the Detective Clawds trailer
//   REEL=doctor build/renderpromo video promo     → promo/doctor-clawd-promo.mp4: the Doctor Clawd trailer
//   REEL=files build/renderpromo video promo      → promo/the-clawd-files-promo.mp4: The Clawd Files trailer
//   REEL=clawdberg build/renderpromo video promo  → promo/stevie-clawdberg-promo.mp4: the Stevie Clawdberg trailer
//   REEL=royale build/renderpromo video promo     → promo/clawd-royale-promo.mp4: the Clawd Royale teaser
//   REEL=royale build/renderpromo 720p promo      → promo/720p/Clawd-Royale.mp4 (storyboard: storyboard-clawd-royale.png)
//   REEL=clawdoftherings build/renderpromo video promo → promo/clawd-of-the-rings-promo.mp4: the Clawd of the Rings trailer
//   REEL=slayer build/renderpromo video promo     → promo/clawd-slayer-promo.mp4: the Clawd Slayer trailer
//   build/renderpromo audio promo                → the soundtrack alone, as a .wav
//   build/renderpromo frame promo 9.5            → a single frame at 9.5 s
//   REEL=full build/renderpromo check            → renders every frame once (prints how far it got)
//   REEL=full build/renderpromo 720p promo       → promo/720p/Clawd-Clash-Full.mp4: the copy under 10 MB for GitHub
// clawdify_guide.md's "Promo: the universe's trailer" section has the whole routine (reels, music, wiring a new one).

// MARK: The cover: three slanted panels and CLAWD CLASH, as on the icon

/// Panel `i` (0 Star Clawds, 1 Marvelous Clawds, 2 Detective Clawds) at frame size.
func coverPanel(_ i: Int) -> CGPath {
    let cuts: [CGFloat] = [-400, 700, 1240, 2400], tilt: CGFloat = 110
    let p = CGMutablePath()
    p.addLines(between: [CGPoint(x: cuts[i] - tilt, y: 0), CGPoint(x: cuts[i + 1] - tilt, y: 0),
                         CGPoint(x: cuts[i + 1] + tilt, y: CGFloat(H)), CGPoint(x: cuts[i] + tilt, y: CGFloat(H))])
    p.closeSubpath()
    return p
}


/// A word of the name, block-extruded and ink-outlined, its face coloured by whichever panel each part is in.
func coverWord(_ ctx: CGContext, _ s: String, at c: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, depth: Int, scale: CGFloat) {
    let faces: [(UInt32, UInt32)] = [(0xFFFFFF, 0xFF8A8A), (0xFFFFFF, 0x8FB8FF), (0xFFF3B0, 0xFFC21A)]
    var path = letters(s)
    let k = min(width / path.boundingBox.width, height / path.boundingBox.height) * scale
    var t = CGAffineTransform(scaleX: k, y: k).concatenating(CGAffineTransform(rotationAngle: angle))
        .concatenating(CGAffineTransform(translationX: c.x, y: c.y))
    path = path.copy(using: &t)!
    let b = path.boundingBox, step = b.height / 80, line = b.height * 0.15
    ctx.saveGState()
    ctx.setLineJoin(.round)
    for i in stride(from: depth, through: 1, by: -1) {
        ctx.saveGState()
        ctx.translateBy(x: CGFloat(i) * step * 0.6, y: -CGFloat(i) * step)
        ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(line); ctx.strokePath()
        ctx.addPath(path); ctx.setFillColor(inkColor); ctx.fillPath()
        ctx.restoreGState()
    }
    ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(line); ctx.strokePath()
    for i in 0..<3 {
        ctx.saveGState()
        ctx.addPath(coverPanel(i)); ctx.clip()
        ctx.addPath(path); ctx.clip()
        let face = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hexCG(faces[i].0), hexCG(faces[i].1)] as CFArray, locations: [0.2, 1])!
        ctx.drawLinearGradient(face, start: CGPoint(x: 0, y: b.maxY), end: CGPoint(x: 0, y: b.minY), options: [])
        ctx.setFillColor(hexCG(0xFFFFFF, 0.3)); ctx.fill(CGRect(x: b.minX, y: b.midY + b.height * 0.1, width: b.width, height: b.height * 0.09))
        ctx.restoreGState()
    }
    ctx.restoreGState()
}

/// The gutters between the panels, white on ink.
func coverGutters(_ ctx: CGContext) {
    for x in [700.0, 1240.0] as [CGFloat] {
        ctx.move(to: CGPoint(x: x - 110, y: 0)); ctx.addLine(to: CGPoint(x: x + 110, y: CGFloat(H)))
        ctx.setStrokeColor(inkColor); ctx.setLineWidth(30); ctx.strokePath()
        ctx.move(to: CGPoint(x: x - 110, y: 0)); ctx.addLine(to: CGPoint(x: x + 110, y: CGFloat(H)))
        ctx.setStrokeColor(hexCG(0xFFFFFF)); ctx.setLineWidth(16); ctx.strokePath()
    }
}

/// The three worlds side by side: each panel its universe's place, tinted like the icon, with its arch-enemies
/// fighting in it.
func coverPanels(_ ctx: CGContext, t: Double, fighters: Bool = true, dim: Double = 0) {
    let worlds: [(Location, UInt32, UInt32)] = [(.deathStar, 0x6E0C1A, 0x1A0610), (.titan, 0xB81A2A, 0x0E2A6E), (.gotham, 0x2B3F7A, 0x0A1028)]
    for (i, (loc, top, bottom)) in worlds.enumerated() {
        ctx.saveGState()
        ctx.addPath(coverPanel(i)); ctx.clip()
        blit(place(loc, floorRows: 30, t: t), ctx)
        let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [hexCG(top, 0.45), hexCG(bottom, 0.25)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(sky, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])
        if fighters {
            let pairs: [(Actor, Actor)] = [
                (Actor(cast: .hero(StarClawdsHero.luke), x: 30, role: .duel), Actor(cast: .villain(StarClawdsVillain.vader), x: 87, facing: -1, role: .duel)),
                (Actor(cast: .hero(MarvelousHero.captainAmerica), x: 132, role: .block), Actor(cast: .villain(MarvelousVillain.thanos), x: 196, facing: -1, role: .zap)),
                (Actor(cast: .hero(DetectiveHero.batman), x: 236, role: .deflect), Actor(cast: .villain(DetectiveVillain.joker), x: 296, facing: -1, role: .shoot(offset: 0))),
            ]
            let (a, b) = pairs[i]
            draw(a, ctx, t: t); draw(b, ctx, t: t)
            drawFX([(a, b)], ctx, t: t)
        }
        ctx.restoreGState()
    }
    if dim > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: dim)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    coverGutters(ctx)
}

// MARK: The clapperboard

/// A film slate, `w` wide, centred on `c`: the board with its writing, and the striped clapper, `open` 0…1.
func clapper(_ ctx: CGContext, center c: CGPoint, width w: CGFloat, open: Double, take: String, title: String = "CLAWD CLASH") {
    let h = w * 0.62, arm = w * 0.17
    let board = CGRect(x: c.x - w / 2, y: c.y - h / 2, width: w, height: h - arm)
    ctx.saveGState()
    ctx.setFillColor(inkColor); ctx.fill(board)
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.9)); ctx.setLineWidth(w * 0.006)
    ctx.stroke(board.insetBy(dx: w * 0.03, dy: w * 0.03))
    for y in [0.36, 0.62] as [CGFloat] { ctx.move(to: CGPoint(x: board.minX + w * 0.03, y: board.minY + board.height * y)); ctx.addLine(to: CGPoint(x: board.maxX - w * 0.03, y: board.minY + board.height * y)) }
    ctx.strokePath()
    let tf = NSFont(name: "Futura-CondensedExtraBold", size: w * 0.15) ?? .systemFont(ofSize: w * 0.15, weight: .black)
    let big = NSAttributedString(string: title, attributes: [.font: tf, .foregroundColor: NSColor.white, .kern: w * 0.01])
    big.draw(at: NSPoint(x: c.x - big.size().width / 2, y: board.minY + board.height * 0.64))
    let small = NSFont.monospacedSystemFont(ofSize: w * 0.05, weight: .bold)
    for (i, s) in ["SCENE  CLASH", "TAKE  \(take)", "ROLL  3"].enumerated() {
        NSAttributedString(string: s, attributes: [.font: small, .foregroundColor: NSColor.white])
            .draw(at: NSPoint(x: board.minX + w * [0.06, 0.45, 0.74][i], y: board.minY + board.height * 0.43))
    }
    NSAttributedString(string: "DIRECTOR  CLAWD", attributes: [.font: small, .foregroundColor: NSColor(white: 0.75, alpha: 1)])
        .draw(at: NSPoint(x: board.minX + w * 0.06, y: board.minY + board.height * 0.12))
    // the clapper: a striped bar hinged at the top left, swinging up to `open`
    func stripes(_ r: CGRect) {
        ctx.setFillColor(CGColor(gray: 0.97, alpha: 1)); ctx.fill(r)
        ctx.saveGState(); ctx.clip(to: r)
        ctx.setFillColor(inkColor)
        var x = r.minX - r.height
        while x < r.maxX { let p = CGMutablePath(); p.addLines(between: [CGPoint(x: x, y: r.minY), CGPoint(x: x + r.height * 0.9, y: r.minY), CGPoint(x: x + r.height * 1.9, y: r.maxY), CGPoint(x: x + r.height, y: r.maxY)]); ctx.addPath(p); ctx.fillPath(); x += r.height * 2 }
        ctx.restoreGState()
        ctx.setStrokeColor(inkColor); ctx.setLineWidth(w * 0.008); ctx.stroke(r)
    }
    stripes(CGRect(x: board.minX, y: board.maxY, width: w, height: arm * 0.55))           // the fixed bar
    ctx.translateBy(x: board.minX, y: board.maxY + arm * 0.55)
    ctx.rotate(by: CGFloat(open) * 0.45)
    stripes(CGRect(x: 0, y: 0, width: w, height: arm * 0.55))                               // the clapstick
    ctx.restoreGState()
}

/// A take ending: "CUT!" shouted from off screen at the right, then a small slate snapping shut with the take number.
func cutAndSlate(_ ctx: CGContext, local l: Double, at: Double, take: String, wrap: Bool = false) {
    let u = l - at
    guard u > 0 else { return }
    let pop = backOut(u / 0.25)
    if wrap {
        balloon("CUT! THAT'S A WRAP!", ctx, center: CGPoint(x: Double(W) / 2, y: 900), tail: CGPoint(x: Double(W) / 2 + 300, y: Double(H) + 40),
                size: 70 * pop, width: 1500, color: NSColor(srgbRed: 0.85, green: 0.1, blue: 0.1, alpha: 1))
    } else {
        balloon("CUT!", ctx, center: CGPoint(x: Double(W) - 260, y: 820), tail: CGPoint(x: Double(W) + 60, y: 900), size: 90 * pop,
                width: 500, color: NSColor(srgbRed: 0.85, green: 0.1, blue: 0.1, alpha: 1))
    }
    if u > 0.45 {
        let s = u - 0.45
        let slide = easeOut(s / 0.2)
        clapper(ctx, center: CGPoint(x: 250 - 300 * (1 - slide), y: 860), width: 380, open: max(0, 1 - s / 0.25), take: take)
    }
}

// MARK: The promo

/// The status line-up in one universe: working, thinking, needs you, napping.
func statusLineup(_ ctx: CGContext, local: Double, t: Double) {
    desktop(ctx, dim: 1)
    let cast: [(Cast, AI, VaderMode, BubbleKind?, String, NSColor, Bool)] = [
        (.hero(MarvelousHero.thor), .claude, .working, nil, "WORKING", green, false),
        (.villain(MarvelousVillain.loki), .qwen, .thinking, .thinking, "THINKING…", NSColor(white: 0.9, alpha: 1), false),
        (.villain(MarvelousVillain.ultron), .gemini, .waiting, .waiting, "NEEDS YOU!", red, false),
        (.villain(MarvelousVillain.thanos), .copilot, .idle, .sleeping, "NAPPING", NSColor(srgbRed: 0.6, green: 0.55, blue: 1, alpha: 1), true),
    ]
    for (i, (who, ai, mode, bubble, word, col, sits)) in cast.enumerated() {
        let d = 0.1 + Double(i) * 0.22
        let f = backOut((local - d) / 0.35)
        guard local > d else { continue }
        var a = Actor(cast: who, x: 48 + Double(i) * 75, mode: mode, bubble: bubble, ai: ai)
        a.sitting = sits
        a.urgent = mode == .waiting
        if a.urgent { a.lift = abs(sin(t * 2 * .pi * 1.6)) * 6 }
        a.lift += (1 - f) * -8
        a.alpha = clamp(f)
        draw(a, ctx, t: t)
        let w = NSAttributedString(string: word, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .black), .kern: 2]).size().width
        text(word, ctx, x: a.x * S - w / 2, y: 70, size: 40, weight: .black, color: col, alpha: clamp(f), kern: 2)
    }
    badge(Universe.marvel.title.uppercased(), ctx, alpha: 1)
    caption("All fun and games, and you still see everything.", ctx, local: local, start: 0.05, y: 900, size: 58)
    caption("(Thanoz sits down when the job's done. Relatable.)", ctx, local: local, start: 0.9, y: 835, size: 36, color: yellow, weight: .bold)
}

/// Subagents arriving with their jobs on their labels.
func agentsArrive(_ ctx: CGContext, local: Double, t: Double) {
    desktop(ctx, dim: 1)
    draw(Actor(cast: .hero(DetectiveHero.wonderWoman), x: 262, facing: -1, mode: .standGuard, label: "idle-claude"), ctx, t: t)
    let crew: [(DetectiveHero, String, Double)] = [(.robin, "Find hook events", 190), (.nightwing, "Write changelog", 140),
                                            (.cyborg, "Check git history", 90), (.krypto, "Plan the refactor", 40)]
    for (i, (who, task, stop)) in crew.enumerated() {
        let f = easeOut((local - Double(i) * 0.18) / 0.75)
        draw(Actor(cast: .hero(who), x: lerp(-30, stop, f), session: false, walking: f < 0.98, label: task), ctx, t: t)
    }
    badge(Universe.dc.title.uppercased(), ctx, alpha: 1)
    caption("Every subagent reports for duty.", ctx, local: local, start: 0.1, y: 900)
    caption("Its job is right there on its label. No more guessing.", ctx, local: local, start: 0.45, y: 835, size: 40, color: yellow, weight: .bold)
}

// MARK: Pick your universe: the pop-art page (as on the social preview), a panel per universe round a centre panel

/// Each universe's face-off on the page, its sound word, and its panel's pop-art colours (base, pattern).
func pickVerse(_ u: Universe) -> (hero: Cast, villain: Cast, sound: String, pop: (UInt32, UInt32)) {
    switch u {
    case .starWars: return (.hero(StarClawdsHero.luke), .villain(StarClawdsVillain.vader), "VWOOM!", (0xFFD62E, 0xFFF08A))
    case .marvel: return (.hero(MarvelousHero.thor), .villain(MarvelousVillain.loki), "KRAKOOM!", (0xE8322E, 0xFF7A70))
    case .dc: return (.hero(DetectiveHero.batman), .villain(DetectiveVillain.joker), "BLAM!", (0x2EA8E8, 0x8AD8FF))
    case .doctor: return (.hero(DoctorHero.doctorTen), .villain(DoctorVillain.dalick), "VWORP!", (0x7CC84A, 0xB8EC88))
    case .clawdFiles: return (.hero(FilesHero.foxClawder), .villain(FilesVillain.grey), "ZZZT!", (0xFF7A1E, 0xFFC27A))
    case .clawdberg: return (.hero(ClawdbergHero.indianaBones), .villain(ClawdbergVillain.reneBellock), "CRACK!", (0xA65AE8, 0xD2A8FF))
    case .middleEarth: return (.hero(RingsHero.gandalf), .villain(RingsVillain.balrog), "KA-THOOM!", (0x1EB8A8, 0x8AE8DC))
    case .slayer: return (.hero(SlayerHero.buffyClawmers), .villain(SlayerVillain.oldMaster), "THWACK!", (0x2ED8D0, 0xA0F6F0))
    default: let c = comicPanel(u); return (c.hero, c.villain, c.sound, c.pop)
    }
}

/// The panel of a universe whose trailer has its own (`PromoReel.comic`): every universe from Stranger Clawds on.
func comicPanel(_ u: Universe) -> ComicPanel {
    guard let c = promoReel(u).comic else {
        preconditionFailure("\(u.title) has no panel on the promo's comic page: give its Promo/<Prefix>Reel.swift a `comic`")
    }
    return c
}

/// A pop-art fill over `r`: 0 diagonal stripes, 1 halftone dots, 2 a sunburst, 3 swirling rays, 4 dots fading up.
func pickFill(_ ctx: CGContext, _ r: CGRect, kind: Int, pair: (UInt32, UInt32), spin: Double = 0) {
    ctx.setFillColor(hexCG(pair.0)); ctx.fill(r)
    let light = hexCG(pair.1)
    func dots(_ cell: Double, _ size: (Double) -> Double) {
        var y = r.minY, row = 0
        while y < r.maxY + cell {
            var x = r.minX + (row % 2 == 0 ? 0 : cell / 2)
            while x < r.maxX + cell {
                let d = size((y - r.minY) / r.height) * cell
                if d > 0.5 { ctx.addEllipse(in: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)) }
                x += cell
            }
            y += cell; row += 1
        }
        ctx.setFillColor(light); ctx.fillPath()
    }
    switch kind {
    case 0:
        var x = r.minX - r.height
        while x < r.maxX { ctx.move(to: CGPoint(x: x, y: r.minY)); ctx.addLine(to: CGPoint(x: x + r.height, y: r.maxY)); x += 45 }
        ctx.setStrokeColor(light); ctx.setLineWidth(18); ctx.strokePath()
    case 1: dots(18) { _ in 0.55 }
    case 2, 3:
        let f = CGPoint(x: r.midX, y: r.midY), far = hypot(r.width, r.height)
        for k in 0..<40 where k % 2 == 0 {
            let a0 = Double(k) / 40 * 2 * .pi + spin, a1 = Double(k + 1) / 40 * 2 * .pi + spin
            if kind == 2 {
                ctx.move(to: f); ctx.addLine(to: CGPoint(x: f.x + cos(a0) * far, y: f.y + sin(a0) * far))
                ctx.addLine(to: CGPoint(x: f.x + cos(a1) * far, y: f.y + sin(a1) * far)); ctx.closePath()
            } else {
                ctx.move(to: f)
                ctx.addQuadCurve(to: CGPoint(x: f.x + cos(a0 + 0.6) * far, y: f.y + sin(a0 + 0.6) * far),
                                 control: CGPoint(x: f.x + cos(a0) * far * 0.5, y: f.y + sin(a0) * far * 0.5))
                ctx.addLine(to: CGPoint(x: f.x + cos(a1 + 0.6) * far, y: f.y + sin(a1 + 0.6) * far))
                ctx.addQuadCurve(to: f, control: CGPoint(x: f.x + cos(a1) * far * 0.5, y: f.y + sin(a1) * far * 0.5))
            }
        }
        ctx.setFillColor(light); ctx.fillPath()
    default: dots(15) { q in 0.15 + 0.6 * q }
    }
}

/// The page's panels: one per universe, and the centre one. The layout grows with the universes: two flank the
/// centre panel, the rest split between a row above and a row below, the gutters leaning alternately.
let pickLayout: (slots: [CGPath], centre: CGPath) = {
    let n = Universe.offered.count, edge = 26.0, gut = 18.0, lean = 27.0, w = Double(W)
    struct Band { let b0, b1, t0, t1: Double
        func bottom(_ x: Double) -> Double { b0 + (b1 - b0) * x / Double(W) }
        func top(_ x: Double) -> Double { t0 + (t1 - t0) * x / Double(W) } }
    func split(_ band: Band, _ weights: [Double]) -> [CGPath] {
        let total = weights.reduce(0, +), free = w - edge * 2 - gut * Double(weights.count - 1)
        var x = edge, out: [CGPath] = []
        for (k, wt) in weights.enumerated() {
            let wpx = free * wt / total
            let l = k == 0 ? 0 : (k % 2 == 0 ? lean : -lean), r = k == weights.count - 1 ? 0 : ((k + 1) % 2 == 0 ? lean : -lean)
            let x0b = x - l, x0t = x + l, x1b = x + wpx - r, x1t = x + wpx + r
            let p = CGMutablePath()
            p.addLines(between: [CGPoint(x: x0b, y: band.bottom(x0b)), CGPoint(x: x1b, y: band.bottom(x1b)),
                                 CGPoint(x: x1t, y: band.top(x1t)), CGPoint(x: x0t, y: band.top(x0t))])
            p.closeSubpath(); out.append(p)
            x += wpx + gut
        }
        return out
    }
    let flanks = n >= 3 ? 2 : 0, rest = n - flanks, topN = (rest + 1) / 2, botN = rest - topN
    let top = Band(b0: 742, b1: 790, t0: Double(H) - edge, t1: Double(H) - edge)
    let mid = Band(b0: 380, b1: 428, t0: 722, t1: 770)
    let bot = Band(b0: edge, b1: edge, t0: 360, t1: 408)
    var slots: [CGPath] = []
    if topN > 0 { slots = split(top, (0..<topN).map { [0.8, 1.3, 1.0][$0 % 3] }) }
    let middle = split(mid, flanks == 2 ? [0.8, 2.0, 0.8] : [1])
    if flanks == 2 { slots += [middle[0], middle[2]] }
    if botN > 0 { slots += split(bot, (0..<botN).map { [1.2, 0.9, 1.0][$0 % 3] }) }
    return (slots, flanks == 2 ? middle[1] : middle[0])
}()

func pickYourUniverse(_ ctx: CGContext, local l: Double, t: Double) {
    ctx.setFillColor(hexCG(0xFDFCF6)); ctx.fill(fullRect)
    let all = Universe.offered, step = min(0.45, 2.4 / Double(all.count))
    let lands = all.indices.map { 0.5 + Double($0) * step }
    // The centre panel first: a turning red sunburst, ONE APP. and PICK YOUR UNIVERSE.
    let cp = pickLayout.centre, cb = cp.boundingBox
    ctx.saveGState(); ctx.addPath(cp); ctx.clip()
    pickFill(ctx, cb, kind: 2, pair: (0xE8322E, 0xFF6A5A), spin: t * 0.08)
    ctx.restoreGState()
    ctx.addPath(cp); ctx.setStrokeColor(inkColor); ctx.setLineWidth(8); ctx.strokePath()
    let head = backOut((l - 0.05) / 0.35)
    if l > 0.05 {
        ctx.saveGState()
        ctx.translateBy(x: cb.midX, y: cb.midY - 20); ctx.rotate(by: 0.05); ctx.scaleBy(x: CGFloat(head), y: CGFloat(head))
        inkLettered("ONE APP.", CGPoint(x: 0, y: 92), size: 60, color: .white, kern: 4)
        inkLettered("PICK YOUR UNIVERSE", CGPoint(x: 0, y: 0), size: 104, color: yellow, kern: 4)
        ctx.restoreGState()
    }
    for (i, u) in all.enumerated() where i < pickLayout.slots.count {
        let at = lands[i]
        guard l > at else { continue }
        let v = pickVerse(u), path = pickLayout.slots[i], r = path.boundingBox
        let f = backOut((l - at) / 0.35)
        ctx.saveGState()
        ctx.translateBy(x: r.midX, y: r.midY)
        ctx.rotate(by: CGFloat((1 - f) * (i % 2 == 0 ? 0.12 : -0.12)))
        ctx.scaleBy(x: CGFloat(1.5 - 0.5 * f), y: CGFloat(1.5 - 0.5 * f))
        ctx.translateBy(x: -r.midX, y: -r.midY)
        ctx.setAlpha(CGFloat(clamp((l - at) / 0.12)))
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        pickFill(ctx, r, kind: i % 5, pair: v.pop)
        // the face-off, as the app draws it: the hero on the left, the villain on the right, the fight between them
        let scale = min(7.0, r.height * 0.62 / 44)
        onStage(ctx, r, scale: scale, ground: (r.height - 34) / scale) {
            let mid = stageW / S / 2
            var (h, vl) = versus(v.hero, mid - 22, v.villain, mid + 22)
            h.label = nil; vl.label = nil
            draw(h, ctx, t: t); draw(vl, ctx, t: t)
            drawFX([(h, vl)], ctx, t: t)
        }
        ctx.restoreGState()
        ctx.addPath(path); ctx.setStrokeColor(inkColor); ctx.setLineWidth(8); ctx.strokePath()
        captionBox(u.title.uppercased(), ctx, center: CGPoint(x: r.minX + 70 + Double(u.title.count) * 10, y: r.maxY - 48), size: 24)
        ctx.restoreGState()
        // its sound word, popping over the border and fading
        let w = l - at
        if w < 0.9 {
            let p = backOut(w / 0.2), fade = 1 - clamp((w - 0.6) / 0.3)
            let c = CGPoint(x: r.maxX - 125, y: r.midY + 30)
            ctx.saveGState(); ctx.setAlpha(CGFloat(fade))
            starburst(ctx, center: c, inner: 55 * p, outer: 95 * p, spikes: 12, color: hexCG(v.pop.1), spin: Double(i))
            ctx.restoreGState()
            inkLettered(v.sound, c, size: CGFloat(44 * p), color: NSColor(srgbRed: 0.85, green: 0.12, blue: 0.12, alpha: 1), alpha: fade, kern: 2)
        }
    }
}

/// A showcase's title card: the universe's name in a caption box and a line about it.
func showcaseTitle(_ ctx: CGContext, _ u: Universe, _ line: String, local l: Double) {
    let f = backOut((l - 0.4) / 0.35), fade = 1 - clamp((l - 4.2) / 0.5)
    guard l > 0.4, fade > 0 else { return }
    ctx.saveGState(); ctx.setAlpha(CGFloat(fade))
    ctx.translateBy(x: 960, y: 990); ctx.scaleBy(x: CGFloat(f), y: CGFloat(f)); ctx.translateBy(x: -960, y: -990)
    captionBox(u.title.uppercased(), ctx, center: CGPoint(x: 960, y: 990), size: 54)
    ctx.restoreGState()
    let sub = attributed(line, size: 40, weight: .bold, color: .white, alpha: fade * clamp((l - 0.7) / 0.3))
    sub.draw(at: NSPoint(x: (Double(W) - sub.size().width) / 2, y: 885))
}

/// The promo's opening, in the style of Doctor Clawd's title sequence: down the time vortex, with the police box and
/// every universe's legend tumbling up out of it and past us, then CLAWD CLASH flying up out of the eye of it and landing
/// with a bang in the middle of the screen. They come out in waves of two from opposite sides, the second a beat
/// later, on its own curve and at its own speed, so a new universe adds to a wave instead of making the intro longer:
/// the waves close up to fit, so the last tumbler is always past by `introLastPast` and the title always lands in time.
var introTumblers: [Cast?] { [nil] + Universe.offered.map { Theme.of($0).legend } }
let introPerWave = 2, introFly = 2.7, introLastPast = 8.4
/// The gap between waves: as long as fits every tumbler in before `introLastPast` (1.25 s at most).
var introWave: Double {
    let last = introTumblers.count - 1, waves = last / introPerWave, j = Double(last % introPerWave)
    return min(1.25, (introLastPast - 0.3 - introFly - j * 0.7) / Double(max(1, waves)))
}

/// When tumbler `i` sets off and how long it takes to fly past.
func introTiming(_ i: Int) -> (start: Double, fly: Double) {
    let wave = i / introPerWave, j = i % introPerWave
    return (0.3 + Double(wave) * introWave + Double(j) * 0.35, introFly + Double(j) * 0.35)
}
var introSlam: Double {
    let last = introTumblers.indices.map { introTiming($0).start + introTiming($0).fly }.max() ?? 0
    return last + 0.4
}

func clashIntro(_ ctx: CGContext, local l: Double, t: Double) {
    let c = CGPoint(x: Double(fxW) / 2 + sin(l * 0.7) * 14, y: Double(fxH) / 2 + cos(l * 0.5) * 6)
    let slam = introSlam, since = l - slam, shake = since > 0 && since < 0.3 ? (0.3 - since) * 60 : 0
    ctx.saveGState(); ctx.translateBy(x: sin(t * 80) * shake, y: cos(t * 70) * shake)
    if let img = lowRes({ g in
        doctorVortexTunnel(g, t: l + 2, glow: clamp(l / 0.5), centre: c)
        if l > 0.1 && l < 0.4 { doctorVortexLightning(g, seed: 11, to: c, alpha: 1 - (l - 0.1) / 0.3) }
    }) { ctx.saveGState(); ctx.interpolationQuality = .none; ctx.draw(img, in: fullRect.insetBy(dx: -40, dy: -40)); ctx.restoreGState() }
    let eye = CGPoint(x: c.x * 6, y: c.y * 6), lamp = Int(l * 5) % 2 == 0
    for (i, who) in introTumblers.enumerated() {
        let (start, fly) = introTiming(i), f = (l - start) / fly
        guard f > 0, f < 1 else { continue }
        let wave = i / introPerWave, j = i % introPerWave
        // opposite sides of the wave, but not a mirror: its own curl, reach and spin
        let z = pow(f, 2.4)
        let a = Double(wave) * 2.1 + 0.6 + Double(j) * (2 * .pi / Double(introPerWave) + 0.35) + z * (j == 0 ? 0.7 : -0.45)
        let p = CGPoint(x: eye.x + cos(a) * z * (1100 - Double(j) * 120), y: eye.y + sin(a) * z * (700 + Double(j) * 90))
        let h = 20 + z * (1000 - Double(j) * 140), turn = sin(l * (0.9 + 0.4 * Double(j)) + Double(i)) * (0.6 - 0.25 * Double(j)) + Double(i) * 0.4
        guard let who else { doctorDrawBox(ctx, at: p, height: h, turn: 0.5 * sin(l * 1.5), lamp: lamp, alpha: clamp(f * 8)); continue }
        let pc = PixelCanvas(Sprite.width, Sprite.height)
        who.draw(pc, t: l, mode: .working, walking: false, role: .none, asSession: false)   // posed, not practising
        pc.addOutline(C(AI.claude.hex, 0.92))
        guard let b = pc.opaqueBounds(), let img = pc.makeImage()?.cropping(to: b) else { continue }
        let w = h * Double(img.width) / Double(img.height)
        ctx.saveGState(); ctx.interpolationQuality = .none
        ctx.translateBy(x: p.x, y: p.y); ctx.rotate(by: CGFloat(turn)); ctx.setAlpha(CGFloat(clamp(f * 8)))
        ctx.draw(img, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
        ctx.restoreGState()
    }
    // CLAWD CLASH flies up out of the eye, faster and faster, and lands with a bang
    if l > slam - 1.1 {
        let fly = easeIn((l - (slam - 1.1)) / 1.1)
        let s = since < 0 ? CGFloat(0.04 + 0.96 * fly) : CGFloat(1 + 0.12 * sin(min(1, since / 0.35) * .pi) * max(0, 1 - since / 0.35))
        let pull = since < 0 ? 1 - fly : 0
        if since > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: 0.18 * clamp(since / 0.2))); ctx.fill(fullRect) }
        coverWord(ctx, "CLAWD", at: CGPoint(x: lerp(960, eye.x, pull), y: lerp(675, eye.y + 40, pull)), width: 1560, height: 270, angle: 0.05, depth: 14, scale: s)
        coverWord(ctx, "CLASH", at: CGPoint(x: lerp(960, eye.x, pull), y: lerp(415, eye.y - 40, pull)), width: 1680, height: 290, angle: 0.05, depth: 16, scale: s)
    }
    ctx.restoreGState()
    if since > 0 && since < 0.3 { ctx.setFillColor(CGColor(gray: 1, alpha: 0.85 * (1 - since / 0.3))); ctx.fill(fullRect) }   // the flash
}

/// Choose your universe, read as a comic: characters from every universe run along the desktop under the title, a
/// page with a panel per universe slams down over them, and the camera reads it panel by panel, each its universe's big
/// moment, then pulls back to the whole page. The layout and the reading grow with the universe list.
var chooseRunners: [Cast] {
    Universe.offered.flatMap { u -> [Cast] in
        let lead = Theme.of(u).legend
        return (0..<3).map { Cast(universe: u, isDark: false, index: $0) }.filter { $0 != lead }.prefix(2).map { $0 }
    }
}

/// Each universe's big moment, from its own trailer, and its sound word.
func setPiece(_ u: Universe) -> (word: String, draw: (CGContext, Double, Double) -> Void) {
    switch u {
    case .starWars: return ("VWOOM!", { starClawdsShowcase($0, local: 1.6 + $1, t: $2) })
    case .marvel: return ("KAPOW!", { marvelousClawvelShowcase($0, local: 3.2 + $1, t: $2) })
    case .dc: return ("KRAK!", { detectiveShowcase($0, local: 2.2 + $1, t: $2) })
    case .doctor: return ("VWORP!", { doctorInvasion($0, local: 3.3 + $1, t: $2) })
    case .clawdFiles: return ("HMMMM!", { filesWoods($0, local: 3.2 + $1, t: $2) })
    case .clawdberg: return ("88 MPH!", { clawdbergHillValley($0, local: 3.0 + $1, t: $2) })
    case .middleEarth: return ("DOOM!", { ringsBridge($0, local: 2.8 + $1, t: $2) })
    case .slayer: return ("THWACK!", { slayerHomecoming($0, local: slayerHomeCut + slayerHomeFight - 0.6 + $1, t: $2) })
    default: let c = comicPanel(u); return (c.word, c.piece)
    }
}

/// The pages, in page units (y up), screen-shaped: up to six panels each, the universes shared out evenly between as
/// many pages as that takes. On each page two rows split by a slanted divider, each row split by slanted gutters that
/// never line up with the other row's.
let pageW = 3200.0, pageH = 1800.0
struct PagePanel { let u: Universe; let corners: [CGPoint]
    var path: CGPath { let p = CGMutablePath(); p.addLines(between: corners); p.closeSubpath(); return p }
    var rect: CGRect { path.boundingBoxOfPath }
}

/// Where two lines (each a point and a direction) cross.
func crossing(_ p: CGPoint, _ d: CGVector, _ q: CGPoint, _ e: CGVector) -> CGPoint {
    let den = d.dx * e.dy - d.dy * e.dx
    let t = ((q.x - p.x) * e.dy - (q.y - p.y) * e.dx) / den
    return CGPoint(x: p.x + d.dx * t, y: p.y + d.dy * t)
}

/// One page's panels, for `shown`, its divider rising (`page` even) or falling, so facing pages differ.
func pageLayout(_ shown: [Universe], page: Int) -> [PagePanel] {
    let n = shown.count, top = (n + 1) / 2, rows = [top, n - top]
    let m = 70.0, gap = 46.0
    let mid = CGPoint(x: pageW / 2, y: pageH / 2), slope = CGVector(dx: 1, dy: page % 2 == 0 ? 0.05 : -0.045)
    let lean = page % 2 == 0 ? [CGVector(dx: 0.2, dy: 1), CGVector(dx: 0.16, dy: 1)] : [CGVector(dx: -0.17, dy: 1), CGVector(dx: 0.21, dy: 1)]
    let weights = page % 2 == 0 ? [[1.0, 1.3, 0.9], [1.25, 0.85, 1.15]] : [[1.3, 0.9, 1.1], [0.85, 1.2, 1.0]]
    var panels: [PagePanel] = [], k = 0
    for (r, count) in rows.enumerated() where count > 0 {
        let full = rows[1] == 0                                                     // one row: the whole page
        let topEdge = r == 0 ? (CGPoint(x: 0, y: pageH - m), CGVector(dx: 1, dy: 0)) : (CGPoint(x: mid.x, y: mid.y - gap / 2), slope)
        let botEdge = r == 0 && !full ? (CGPoint(x: mid.x, y: mid.y + gap / 2), slope) : (CGPoint(x: 0, y: m), CGVector(dx: 1, dy: 0))
        let ws = (0..<count).map { weights[r][$0 % weights[r].count] }, sum = ws.reduce(0, +)
        let rowMid = r == 0 ? (full ? pageH / 2 : (pageH - m + mid.y) / 2) : (mid.y + m) / 2
        var cuts = [m - gap / 2], x = m
        for c in 0..<count { x += (pageW - 2 * m) * ws[c] / sum; cuts.append(c == count - 1 ? pageW - m + gap / 2 : x) }
        for c in 0..<count {
            let left = c == 0 ? (CGPoint(x: m, y: 0), CGVector(dx: 0, dy: 1)) : (CGPoint(x: cuts[c] + gap / 2, y: rowMid), lean[r])
            let right = c == count - 1 ? (CGPoint(x: pageW - m, y: 0), CGVector(dx: 0, dy: 1)) : (CGPoint(x: cuts[c + 1] - gap / 2, y: rowMid), lean[r])
            let corners = [crossing(left.0, left.1, topEdge.0, topEdge.1), crossing(right.0, right.1, topEdge.0, topEdge.1),
                           crossing(right.0, right.1, botEdge.0, botEdge.1), crossing(left.0, left.1, botEdge.0, botEdge.1)]
            panels.append(PagePanel(u: shown[k], corners: corners)); k += 1
        }
    }
    return panels
}

let comicPages: [[PagePanel]] = {
    let shown = Universe.offered, count = (shown.count + 5) / 6, per = (shown.count + count - 1) / count
    return stride(from: 0, to: shown.count, by: per).enumerated().map { p, s in pageLayout(Array(shown[s..<min(shown.count, s + per)]), page: p) }
}()

/// What the camera looks at: a whole page, or one panel on it.
enum PageView { case whole(Int), panel(Int, Int) }
/// The camera's stops in order: each held from `from` to `to`; between two stops it moves, or, into a new page, the
/// page turns.
struct PageKey { let view: PageView; let from: Double; let to: Double; let turn: Bool }
let pageDrop = 2.4, pageHold = 0.95, pageMove = 0.4, pageTurn = 0.95
let pageKeys: [PageKey] = {
    var keys: [PageKey] = [], t = pageDrop + 0.5
    for (p, page) in comicPages.enumerated() {
        let look = p == 0 ? 0.5 : 0.35
        keys.append(PageKey(view: .whole(p), from: t, to: t + look, turn: p > 0)); t += look + pageMove
        for j in page.indices { keys.append(PageKey(view: .panel(p, j), from: t, to: t + pageHold, turn: false)); t += pageHold + pageMove }
        let last = p == comicPages.count - 1
        keys.append(PageKey(view: .whole(p), from: t, to: t + (last ? 2.6 : 0.3), turn: false)); t += last ? 2.6 : 0.3 + pageTurn
    }
    return keys
}()
/// When the camera gets to universe `i`'s panel, and when it's back on the last page as a whole.
func pageArrive(_ i: Int) -> Double {
    var k = 0
    for key in pageKeys { if case .panel = key.view { if k == i { return key.from }; k += 1 } }
    return 0
}
var pageBack: Double { pageKeys.last!.from }
var chooseLength: Double { pageKeys.last!.to }
/// When the pages turn.
var pageTurns: [Double] { pageKeys.filter(\.turn).map { $0.from - pageTurn } }

typealias Camera = (c: CGPoint, s: Double, turn: Double)
func camera(_ v: PageView) -> Camera {
    switch v {
    case .whole: return (CGPoint(x: pageW / 2, y: pageH / 2), Double(W) / pageW * 0.97, 0)
    case .panel(let p, let j):
        let r = comicPages[p][j].rect
        return (CGPoint(x: r.midX, y: r.midY), min(Double(W) * 0.9 / r.width, Double(H) * 0.9 / r.height), 0)
    }
}
func blend(_ a: Camera, _ b: Camera, _ f: Double) -> Camera {
    let e = f * f * (3 - 2 * f)
    // zooming feels even in log scale; a little pull back and a lean mid-move, like a camera finding the next panel
    let s = exp(lerp(log(a.s), log(b.s), e)) * (1 - 0.12 * sin(.pi * f))
    let lean = (b.c.x > a.c.x ? -1.0 : 1.0) * 0.05 * sin(.pi * f)
    return (CGPoint(x: lerp(a.c.x, b.c.x, e), y: lerp(a.c.y, b.c.y, e)), s, lerp(a.turn, b.turn, e) + lean)
}
func page(of v: PageView) -> Int { switch v { case .whole(let p), .panel(let p, _): return p } }

/// One page through the camera: the paper, its border, and every panel playing its universe's big moment.
func drawPage(_ ctx: CGContext, _ p: Int, cam: Camera, zoom: Double = 1, tilt: Double = 0, l: Double, t: Double) {
    ctx.saveGState()
    ctx.translateBy(x: 960, y: 540); ctx.rotate(by: CGFloat(cam.turn + tilt))
    ctx.scaleBy(x: CGFloat(cam.s * zoom), y: CGFloat(cam.s * zoom)); ctx.translateBy(x: -cam.c.x, y: -cam.c.y)
    let sheet = CGRect(x: 0, y: 0, width: pageW, height: pageH)
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.5)); ctx.fill(sheet.offsetBy(dx: 24, dy: -24))
    ctx.setFillColor(CGColor(gray: 0.96, alpha: 1)); ctx.fill(sheet)
    ctx.setStrokeColor(inkColor); ctx.setLineWidth(14); ctx.stroke(sheet.insetBy(dx: 30, dy: 30))
    let first = comicPages.prefix(p).map(\.count).reduce(0, +)
    let view = CGRect(x: cam.c.x - 960 / (cam.s * zoom), y: cam.c.y - 540 / (cam.s * zoom), width: 1920 / (cam.s * zoom), height: 1080 / (cam.s * zoom))
    for (j, panel) in comicPages[p].enumerated() {
        let i = first + j, piece = setPiece(panel.u), r = panel.rect, shape = panel.path
        ctx.saveGState(); ctx.translateBy(x: 16, y: -16); ctx.addPath(shape); ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fillPath(); ctx.restoreGState()
        // only the panels in view get their scene drawn; before the camera gets there it holds a moment of the action
        if r.insetBy(dx: -300, dy: -300).intersects(view), let full = shotImage({ piece.draw($0, max(0.8, l - pageArrive(i) + 0.6), t) }) {
            let h = min(Double(H), Double(W) * Double(r.height) / Double(r.width)), w = h * Double(r.width) / Double(r.height)
            if let img = full.cropping(to: CGRect(x: (Double(W) - w) / 2, y: (Double(H) - h) / 2, width: w, height: h)) {
                ctx.saveGState(); ctx.addPath(shape); ctx.clip()
                ctx.interpolationQuality = cam.s * zoom > 0.9 ? .none : .high; ctx.draw(img, in: r)
                ctx.restoreGState()
            }
        }
        ctx.addPath(shape); ctx.setStrokeColor(inkColor); ctx.setLineWidth(16); ctx.strokePath()
        let label = NSAttributedString(string: panel.u.title.uppercased(), attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .heavy)]).size().width
        captionBox(panel.u.title.uppercased(), ctx, center: CGPoint(x: max(panel.corners[0].x, panel.corners[3].x) + 60 + label / 2,
                                                                     y: min(panel.corners[0].y, panel.corners[1].y) - 50), size: 40)
        // the sound word pops as the camera gets there
        let w = l - pageArrive(i) + 0.1
        if w > 0 && w < pageHold + pageMove {
            let pop = backOut(w / 0.2), a = 1 - clamp((w - pageHold) / 0.3)
            ctx.saveGState()
            ctx.translateBy(x: r.maxX - r.width * 0.24, y: r.minY + r.height * 0.2); ctx.rotate(by: i % 2 == 0 ? 0.12 : -0.12)
            ctx.scaleBy(x: CGFloat(pop), y: CGFloat(pop))
            inkLettered(piece.word, .zero, size: CGFloat(min(170, r.height * 0.22)), color: yellow, alpha: a, kern: 6)
            ctx.restoreGState()
        }
    }
    ctx.restoreGState()
}

/// The part of polygon `poly` on the side of the line through `a` (direction `u`) where `keepLeft` says.
func clipPolygon(_ poly: [CGPoint], _ a: CGPoint, _ u: CGVector, keepLeft: Bool) -> [CGPoint] {
    let side = { (p: CGPoint) -> Double in let s = Double(u.dx * (p.y - a.y) - u.dy * (p.x - a.x)); return keepLeft ? s : -s }
    var out: [CGPoint] = []
    for i in poly.indices {
        let p = poly[i], q = poly[(i + 1) % poly.count], sp = side(p), sq = side(q)
        if sp >= 0 { out.append(p) }
        if (sp >= 0) != (sq >= 0) {
            let f = sp / (sp - sq)
            out.append(CGPoint(x: p.x + (q.x - p.x) * f, y: p.y + (q.y - p.y) * f))
        }
    }
    return out
}

/// `p` mirrored across the line through `a` with unit direction `u`.
func mirrored(_ p: CGPoint, _ a: CGPoint, _ u: CGVector) -> CGPoint {
    let dx = p.x - a.x, dy = p.y - a.y, d = dx * u.dx + dy * u.dy
    return CGPoint(x: a.x + 2 * d * u.dx - dx, y: a.y + 2 * d * u.dy - dy)
}

/// A page turning over, right to left, `k` 0…1, curling back from its right edge: the fold sweeps across at a slant,
/// the new page shows behind it with the curl's shadow on it, and the curled-over flap is the paper back of the old one.
func turnPage(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double) {
    let e = k * k * (3 - 2 * k), lean = 0.28
    let len = sqrt(1 + lean * lean), u = CGVector(dx: lean / len, dy: 1 / len)          // the fold, leaning right at the top
    let a = CGPoint(x: lerp(Double(W) + 60, -Double(H) * lean - 120, e), y: 0)
    let sheet = [CGPoint(x: 0, y: 0), CGPoint(x: W, y: 0), CGPoint(x: W, y: H), CGPoint(x: 0, y: H)]
    func path(_ pts: [CGPoint]) -> CGPath { let p = CGMutablePath(); if !pts.isEmpty { p.addLines(between: pts); p.closeSubpath() }; return p }
    ctx.draw(new, in: fullRect)
    // the old page, what's left of it on this side of the fold
    let stays = clipPolygon(sheet, a, u, keepLeft: true)
    if stays.count > 2 { ctx.saveGState(); ctx.addPath(path(stays)); ctx.clip(); ctx.draw(old, in: fullRect); ctx.restoreGState() }
    // the curl's shadow on the new page, just past the fold
    let n = CGVector(dx: u.dy, dy: -u.dx)                                                     // pointing right, away from the old page
    let shadow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 0, alpha: 0.5), CGColor(gray: 0, alpha: 0)] as CFArray, locations: [0, 1])!
    let turned = clipPolygon(sheet, a, u, keepLeft: false)
    if turned.count > 2 {   // (clipping to nothing would clip nothing away)
        ctx.saveGState(); ctx.addPath(path(turned)); ctx.clip()
        ctx.drawLinearGradient(shadow, start: a, end: CGPoint(x: a.x + n.dx * 140, y: a.y + n.dy * 140), options: [.drawsBeforeStartLocation])
        ctx.restoreGState()
    }
    // the flap: the turned part, mirrored over the fold, its paper back lit at the fold and shaded at its edge
    let flap = turned.map { mirrored($0, a, u) }
    guard flap.count > 2 else { return }
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -10, height: -6), blur: 30, color: CGColor(gray: 0, alpha: 0.5))
    ctx.addPath(path(flap)); ctx.setFillColor(CGColor(gray: 0.86, alpha: 1)); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState(); ctx.addPath(path(flap)); ctx.clip()
    let paper = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 1, alpha: 0.9), CGColor(gray: 0.7, alpha: 0.9)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(paper, start: a, end: CGPoint(x: a.x - n.dx * 700, y: a.y - n.dy * 700), options: [.drawsAfterEndLocation])
    ctx.restoreGState()
    ctx.addPath(path(flap)); ctx.setStrokeColor(CGColor(gray: 0.55, alpha: 1)); ctx.setLineWidth(3); ctx.strokePath()
}

func chooseUniverse(_ ctx: CGContext, local l: Double, t: Double) {
    // the runners, along the bottom of the desktop, under the title
    if l < pageDrop + 0.5 {
        desktop(ctx, dim: 1)
        for (i, who) in chooseRunners.enumerated() {
            let x = -40 + (l - Double(i) * 0.15) * 170
            guard x > -40, x < 360 else { continue }
            draw(Actor(cast: who, x: x, mode: .idle, walking: true), ctx, t: t * 1.6 + Double(i) * 0.2)
        }
        let f = backOut((l - 0.15) / 0.4)
        if f > 0 {
            ctx.saveGState(); ctx.translateBy(x: 960, y: 640); ctx.scaleBy(x: CGFloat(f), y: CGFloat(f)); ctx.rotate(by: 0.035)
            inkLettered("CHOOSE YOUR", CGPoint(x: 0, y: 110), size: 120, color: yellow, kern: 8)
            inkLettered("UNIVERSE", CGPoint(x: 0, y: -40), size: 190, color: yellow, kern: 10)
            ctx.restoreGState()
        }
    }
    guard l > pageDrop else { return }
    if l > pageDrop + 0.5 { halftone(ctx, fullRect, base: CGColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1), dot: CGColor(red: 0.13, green: 0.13, blue: 0.18, alpha: 1), step: 22) }
    let since = l - pageDrop, shake = since > 0.3 && since < 0.55 ? (0.55 - since) * 50 : 0
    ctx.saveGState(); ctx.translateBy(x: sin(t * 80) * shake, y: cos(t * 70) * shake)
    // where the camera is: on a stop, moving between two, or turning the page
    let next = pageKeys.firstIndex { $0.to > l } ?? pageKeys.count - 1, key = pageKeys[next]
    if l < pageKeys[0].from {                                  // the first page slamming down
        let drop = backOut(since / 0.4)
        ctx.setAlpha(CGFloat(clamp(since / 0.12)))
        drawPage(ctx, 0, cam: camera(.whole(0)), zoom: 1.5 - 0.5 * drop, tilt: (1 - drop) * 0.08, l: l, t: t)
    } else if l >= key.from {
        drawPage(ctx, page(of: key.view), cam: camera(key.view), l: l, t: t)
    } else {
        let prev = pageKeys[next - 1], f = (l - prev.to) / (key.from - prev.to)
        if key.turn,
           let old = shotImage({ drawPage($0, page(of: prev.view), cam: camera(prev.view), l: l, t: t) }),
           let new = shotImage({ drawPage($0, page(of: key.view), cam: camera(key.view), l: l, t: t) }) {
            turnPage(ctx, old: old, new: new, k: f)
        } else {
            drawPage(ctx, page(of: key.view), cam: blend(camera(prev.view), camera(key.view), f), l: l, t: t)
        }
    }
    ctx.restoreGState()
    // and the line, once it's back on the last page as a whole
    let f = backOut((l - pageBack - 0.2) / 0.35)
    if f > 0 {
        ctx.saveGState(); ctx.translateBy(x: 960, y: 60); ctx.scaleBy(x: CGFloat(f), y: CGFloat(f)); ctx.translateBy(x: -960, y: -60)
        captionBox("ONE APP. MULTIPLE UNIVERSES. PICK YOURS.", ctx, center: CGPoint(x: 960, y: 60), size: 46)
        ctx.restoreGState()
    }
}

/// Where the comic page ends: everything after it moves with the number of universes.
var afterChoose: Double { 16.5 + chooseLength }

let promoShots: [Shot] = [
    Shot(name: "meanwhile", start: 0, end: 3.0, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, IN A TERMINAL NEAR YOU..."
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 2.6) / 0.35)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    // Down the time vortex: a character from every universe tumbles past, and CLAWD CLASH lands with a bang.
    Shot(name: "worlds", start: 3.0, end: 12.5, into: .cut) { ctx, local, t in clashIntro(ctx, local: local, t: t) },
    Shot(name: "hook", start: 12.5, end: 16.5) { ctx, local, t in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom)
        ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused human.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    // Choose your universe: everyone runs past, a comic page slams down, and the camera reads it panel by panel.
    Shot(name: "choose", start: 16.5, end: afterChoose) { ctx, local, t in chooseUniverse(ctx, local: local, t: t) },
    // The features, one each in the newest universes, as their own trailers show them.
    Shot(name: "status", start: afterChoose, end: afterChoose + 4.5, into: .trip(ComicTransition(FilesTrip(kind: .classifiedFile)))) { ctx, local, t in
        filesShots.first { $0.name == "status" }!.render(ctx, local, t)
    },
    Shot(name: "agents", start: afterChoose + 4.5, end: afterChoose + 9.0, into: .trip(ComicTransition(ClawdbergTrip(kind: .mapRoute)))) { ctx, local, t in
        clawdbergShots.first { $0.name == "agents" }!.render(ctx, local, t)
    },
    Shot(name: "window", start: afterChoose + 9.0, end: afterChoose + 14.5, into: .middleEarth(RingsTrip(kind: .map))) { ctx, local, t in
        ringsShots.first { $0.name == "window" }!.render(ctx, local, t)
    },
    // Random: the whole window changes universe on its own, each time with that universe's transition.
    Shot(name: "random1", start: afterChoose + 14.5, end: afterChoose + 16.6) { ctx, local, t in windowShot(ctx, .middleEarth, local: local + 3, t: t, rise: false, at: .prancingPony) },
    Shot(name: "random2", start: afterChoose + 16.6, end: afterChoose + 18.9, into: .trip(ComicTransition(DoctorTrip(kind: .vortex))), inWindow: true) { ctx, local, t in
        windowShot(ctx, .doctor, local: local + 3, t: t, rise: false, at: .consoleRoom)
    },
    Shot(name: "random3", start: afterChoose + 18.9, end: afterChoose + 21.0, into: .starWars(clock: false), inWindow: true) { ctx, local, t in
        windowShot(ctx, .starWars, local: local + 3, t: t, rise: false)
    },
    // Clawd Royale: the emblems collide, then everyone at once, each as themselves.
    Shot(name: "royale", start: afterChoose + 21.0, end: afterChoose + 24.0, into: .cut) { ctx, local, t in royaleCollide(ctx, local: local, t: t) },
    Shot(name: "crossover", start: afterChoose + 24.0, end: afterChoose + 28.5, into: .marvel(MarvelousComicTrip(kind: .burst, sound: .thwip))) { ctx, local, t in
        let (fox, dalick) = versus(.hero(FilesHero.foxClawder), 30, .villain(DoctorVillain.dalick), 96)
        let (bat, vapor) = versus(.hero(DetectiveHero.batman), 150, .villain(StarClawdsVillain.vader), 207)
        let (gandclawd, thanoz) = versus(.hero(RingsHero.gandalf), 250, .villain(MarvelousVillain.thanos), 306)
        let swing = webSwing(local, start: 0.7)
        royaleScene(ctx, .cantina, t: t, fights: [(fox, dalick), (bat, vapor), (gandclawd, thanoz)], also: swing.map { [$0.actor] } ?? [])
        let bf = (local - 1.2) / 2.4                                // E.Clawd's bike, flying the other way over everyone
        if bf > 0 && bf < 1 {
            let c = PixelCanvas(Ride.width, Ride.moonBike.canvasHeight)
            drawRide(c, .moonBike, ramp: 0, engines: true, gear: false); c.flipHorizontally(); c.addOutline(C(0xFFFFFF, 0.92))
            if let img = c.makeImage() {
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: lerp(Double(W) + 60, -Double(Ride.width) * 6 - 60, bf), y: 560 + sin(bf * .pi) * 60,
                                         width: Double(Ride.width) * 6, height: Double(c.h) * 6))
                ctx.restoreGState()
            }
        }
        if let s = swing {                                          // his web line, from the raised hand up out of the frame
            let web = PixelCanvas(fxW, fxH), hand = s.actor.fighter.point(41, 22)
            web.glowLine(hand.x, hand.y, s.anchor.x, s.anchor.y, core: C(0xF4F4F8, 0.9), glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
            blit(web, ctx)
        }
        badge("CLAWD ROYALE", ctx, alpha: clamp(local / 0.3))
        caption("Nobody asked who'd win. We're answering anyway.", ctx, local: local, start: 0.8, y: 905, size: 58)
        caption("Settings → Universe → Clawd Royale. A new place every ten minutes.", ctx, local: local, start: 1.6, y: 840, size: 38, color: yellow, weight: .bold)
    },
    Shot(name: "endcard", start: afterChoose + 28.5, end: afterChoose + 33.5) { ctx, local, t in
        coverPanels(ctx, t: t, fighters: false, dim: 0.45)
        let f = backOut((local - 0.2) / 0.5)
        if let icon = appIcon, local > 0.2 {
            let s = 500 * f
            ctx.saveGState(); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: 960 - s / 2, y: 660 - s / 2, width: s, height: s))
            ctx.restoreGState()
        }
        let shown = Universe.offered
        for (i, u) in shown.enumerated() {
            let e = backOut((local - 0.5 - Double(i) * 0.08) / 0.35)
            if e > 0 { emblem(u, ctx, center: CGPoint(x: 960 + (Double(i) - Double(shown.count - 1) / 2) * 170, y: 335), px: 4 * e) }
        }
        caption("Have fun. Keep track.", ctx, local: local, start: 0.8, y: 190, size: 64)
        caption("Pick a universe, or let them collide · free for macOS · github.com/rodclemen/clawd-clash", ctx, local: local, start: 1.1, y: 120, size: 34,
                color: NSColor(white: 0.88, alpha: 1), weight: .bold)
    },
]

let promoOverlays: [Overlay] = [
    Overlay(start: afterChoose + 14.5, end: afterChoose + 21.0) { ctx, l in
        badge("RANDOM · EVERY 5 MIN", ctx, alpha: 1)
        caption("Can't decide? Random switches the whole window", ctx, local: l, start: 0.2, y: 950, size: 50)
        caption("to a new universe every few minutes.", ctx, local: l, start: 0.4, y: 885, size: 40, color: yellow, weight: .bold)
    },
]

// MARK: The blooper reel


/// Thorr's hammer, on its own, `k` sprite pixels a pixel: a stone head and a wrapped handle.
func hammer(_ ctx: CGContext, x: Double, y: Double, k: Double, tilt: Double) {
    let c = PixelCanvas(16, 18)
    c.rect(1, 1, 14, 7, C(0x8A8C92)); c.rect(1, 1, 14, 2, C(0xB8BAC0)); c.rect(1, 7, 14, 1, C(0x5A5C62))
    c.rect(7, 8, 3, 9, C(0x6A4428)); for y in stride(from: 9, to: 17, by: 2) { c.rect(7, y, 3, 1, C(0x8A6038)) }
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.translateBy(x: x * 6, y: Double(H) - y * 6); ctx.rotate(by: CGFloat(tilt))
    ctx.draw(img, in: CGRect(x: -8 * k * 6, y: -9 * k * 6, width: 16 * k * 6, height: 18 * k * 6))
    ctx.restoreGState()
}

/// The TARDIS standing at `x` (fx units) with its foot on `ground`, `door` 0…1 open, its lamp lit or not.
func standingTardis(_ ctx: CGContext, x: Double, ground: Double, alpha: Double, door: Double, lamp: Bool) {
    guard alpha > 0.01 else { return }
    let c = PixelCanvas(Ride.width, Ride.tardis.canvasHeight)
    drawRide(c, .tardis, ramp: door, engines: lamp, gear: true)
    c.addOutline(C(0xFFFFFF, 0.92))
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none; ctx.setAlpha(CGFloat(alpha))
    ctx.draw(img, in: CGRect(x: (x - Double(Ride.width) / 2) * S, y: stageH - ground * S - S, width: Double(Ride.width) * S, height: Double(c.h) * S))
    ctx.restoreGState()
}

/// How solid the TARDIS is `k` (0…1) of the way through wheezing into being: in and out, getting stronger.
func wheezePulse(_ k: Double) -> Double { min(1, max(0, k * (0.75 + 0.25 * sin(k * 7 * .pi)))) }

/// An actor drawn upside down, flipped about the middle of its sprite.
func drawUpsideDown(_ a: Actor, _ ctx: CGContext, t: Double) {
    let mid = stageH - (a.top + 22 * a.k) * S
    ctx.saveGState(); ctx.translateBy(x: 0, y: 2 * mid); ctx.scaleBy(x: 1, y: -1)
    draw(a, ctx, t: t)
    ctx.restoreGState()
}

let blooperShots: [Shot] = [
    // The clapperboard slams in: BLOOPERS.
    Shot(name: "clapper", start: 0, end: 3.0, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(red: 0.08, green: 0.07, blue: 0.1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        halftone(ctx, CGRect(x: 0, y: 0, width: W, height: H), base: CGColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1),
                 dot: CGColor(red: 1, green: 0.4, blue: 0.3, alpha: 1), step: 28)
        let drop = easeOut(local / 0.35)
        let open = local < 1.0 ? 1.0 : max(0, 1 - (local - 1.0) / 0.12)
        clapper(ctx, center: CGPoint(x: 960, y: 540 + 700 * (1 - drop)), width: 1100, open: open, take: "1", title: "BLOOPERS")
    },
    // Take 7: the TARDIS lands in the Mos Easy Cantina, in the wrong universe, and then won't take off again.
    Shot(name: "take7", start: 3.0, end: 12.4, into: .cut) { ctx, l, t in
        set(ctx, .cantina, t: t)
        let lamp = Int(l * 5) % 2 == 0
        var alpha = wheezePulse(clamp(l / 1.6)), lit = l < 1.6 && lamp
        if l > 5.4 && l < 6.8 { alpha = 0.55 + 0.45 * abs(cos((l - 5.4) / 1.4 * 3 * .pi)); lit = lamp }     // tries to go, and can't
        let door = min(1, clamp((l - 1.9) / 0.25) * (1 - clamp((l - 5.0) / 0.25)) + clamp((l - 7.0) / 0.25))
        standingTardis(ctx, x: 66, ground: groundY, alpha: alpha, door: door, lamp: lit)
        let vapor = Actor(cast: .villain(StarClawdsVillain.vader), x: 240, facing: l > 1.2 ? -1 : 1, mode: .idle)
        draw(vapor, ctx, t: t)
        // the Doctor: out, back in, and out again
        let x = l < 4.6 ? lerp(70, 112, easeOut((l - 2.1) / 0.6)) : l < 7.2 ? lerp(112, 70, easeIn((l - 4.6) / 0.5)) : lerp(70, 104, easeOut((l - 7.2) / 0.5))
        let walking = (l > 2.1 && l < 2.7) || (l > 4.6 && l < 5.1) || (l > 7.2 && l < 7.7)
        var doc = Actor(cast: .hero(DoctorHero.doctorTen), x: x, facing: l > 4.6 && l < 7.2 ? -1 : 1, mode: .idle, walking: walking)
        doc.alpha = (l > 2.05 && l < 5.15) || l > 7.15 ? 1 : 0
        draw(doc, ctx, t: t)
        if l > 2.9 && l < 4.5 { balloon("Ah. Wrong universe.", ctx, center: CGPoint(x: 700, y: 820), tail: headPoint(doc), size: 46) }
        if l > 3.6 && l < 5.3 { balloon("…Is that a phone box?", ctx, center: CGPoint(x: 1300, y: 760), tail: headPoint(vapor), size: 44) }
        if l > 7.7 { balloon("…Handbrake.", ctx, center: CGPoint(x: 700, y: 800), tail: headPoint(doc), size: 46) }
        cutAndSlate(ctx, local: l, at: 8.2, take: "7")
    },
    // Take 12: the Night Beacon over the Doom Moon; the Stormtroupers open fire and miss every shot.
    Shot(name: "take12", start: 12.4, end: 17.6, into: .cut) { ctx, l, t in
        set(ctx, .deathStar, t: t)
        let on = clamp(l / 0.25)
        let sig = CGPoint(x: 1300, y: 860)
        ctx.setFillColor(CGColor(red: 1, green: 0.89, blue: 0.42, alpha: 0.2 * on)); ctx.fillEllipse(in: CGRect(x: sig.x - 260, y: sig.y - 170, width: 520, height: 340))
        ctx.setFillColor(CGColor(red: 1, green: 0.89, blue: 0.42, alpha: 0.9 * on)); ctx.fillEllipse(in: CGRect(x: sig.x - 200, y: sig.y - 130, width: 400, height: 260))
        ctx.addPath(detectiveCowlMaskPath(sig, width: 330))                 // the cowl mask in the beacon, as on the icon
        ctx.setFillColor(inkColor.copy(alpha: on) ?? inkColor); ctx.fillPath(using: .evenOdd)
        let bat = Actor(cast: .hero(DetectiveHero.batman), x: 40, mode: .idle)
        draw(bat, ctx, t: t)
        let troopers = [Actor(cast: .villain(StarClawdsVillain.trooper), x: 150, mode: .idle, role: .none), Actor(cast: .villain(StarClawdsVillain.trooper), x: 200, mode: .idle, role: .none)]
        for tr in troopers { draw(tr, ctx, t: t) }
        let fx = PixelCanvas(fxW, fxH)
        for i in 0..<12 {                                           // wild shots, all wide of the mark
            let born = 0.5 + Double(i) * 0.22, age = l - born
            guard age > 0, age < 0.6 else { continue }
            let from = (troopers[i % 2].x + 18, stageGroundRow - 22), miss = (noise(i * 5) > 0.5 ? 1.0 : -1.0) * (40 + noise(i * 5 + 1) * 40)
            let to = (Double(sig.x) / 6 + miss, -10.0)
            let g = age / 0.6, x = lerp(from.0, to.0, g), y = lerp(from.1, to.1, g)
            fx.glowLine(x - (to.0 - from.0) * 0.05, y - (to.1 - from.1) * 0.05, x, y, core: C(0xFFE0E0), glow: C(0xFF2A2A), coreR: 0.6, glowR: 1.8)
        }
        blit(fx, ctx)
        if l > 2.2 { balloon("You know it's a light, right?", ctx, center: CGPoint(x: 600, y: 640), tail: headPoint(bat), size: 40, width: 700) }
        cutAndSlate(ctx, local: l, at: 4.0, take: "12")
    },
    // Take 15: the Jester Card flips over and Thanoz is on the back.
    Shot(name: "take15", start: 17.6, end: 21.8, into: .cut) { ctx, l, t in
        let jester = Actor(cast: .villain(DetectiveVillain.joker), x: 150, mode: .idle)
        func front() -> CGImage? { shotImage { c in set(c, .gotham, t: t); draw(jester, c, t: t) } }
        func back() -> CGImage? {
            shotImage { c in
                set(c, .titan, t: t)
                draw(Actor(cast: .villain(MarvelousVillain.thanos), x: 160, facing: -1, mode: .idle), c, t: t)
                var j = Actor(cast: .villain(DetectiveVillain.joker), x: 50, mode: .idle, bubble: .unknown); j.grow = 0.9
                if l > 2.6 { draw(j, c, t: t) }
            }
        }
        let k = clamp((l - 0.3) / (DetectiveComicWipe.jokerCard.duration * 1.2))
        if let a = front(), let b = back() {
            if k <= 0 { ctx.draw(a, in: CGRect(x: 0, y: 0, width: W, height: H)) }
            else if k >= 1 { ctx.draw(b, in: CGRect(x: 0, y: 0, width: W, height: H)) }
            else { DetectiveComicTrip(kind: .jokerCard).draw(ctx, old: a, new: b, k: k, in: CGRect(x: 0, y: 0, width: W, height: H)) }
        }
        cutAndSlate(ctx, local: l, at: 3.4, take: "15")
    },
    // Take 21: Yodle lifts Thorr's hammer. Thorr stares.
    Shot(name: "take21", start: 21.8, end: 28.0, into: .cut) { ctx, l, t in
        set(ctx, .asgard, t: t)
        let yodle = Actor(cast: .hero(StarClawdsHero.yoda), x: 90, mode: .idle)
        let thorr = Actor(cast: .hero(MarvelousHero.thor), x: 220, facing: -1, mode: .idle)
        draw(yodle, ctx, t: t); draw(thorr, ctx, t: t)
        let rise = easeOut((l - 0.5) / 1.4)
        hammer(ctx, x: 128, y: stageGroundRow - 4 - rise * 34 + sin(t * 4) * rise * 1.5, k: 1.6, tilt: sin(t * 2) * 0.1 * rise)
        if l > 0.5 {                                                // the Force, twinkling round it
            let sp = PixelCanvas(fxW, fxH), hy = stageGroundRow - 4 - rise * 34
            for i in 0..<8 where sin(t * 5 + Double(i) * 1.7) > 0 {
                sp.px(128 + Int((noise(i * 3) - 0.5) * 30), Int(hy) + Int((noise(i * 3 + 1) - 0.5) * 24), C(0xBFF0FF))
            }
            blit(sp, ctx)
        }
        if l > 1.9 { balloon("…", ctx, center: CGPoint(x: 1500, y: 700), tail: headPoint(thorr), size: 60, width: 200) }
        if l > 3.0 { balloon("Worthy, hmm. Heavy, it is not.", ctx, center: CGPoint(x: 520, y: 760), tail: headPoint(yodle), size: 40, width: 700) }
        cutAndSlate(ctx, local: l, at: 5.4, take: "21")
    },
    // Take 22: Superb-Man tries to keep up with the jump to hyperspace.
    Shot(name: "take22", start: 28.0, end: 33.0, into: .cut) { ctx, l, t in
        ctx.setFillColor(CGColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let jump = clamp((l - 0.8) / 0.6), centre = CGPoint(x: 1300, y: 600)
        for i in 0..<160 {                                           // stars, stretching into streaks
            let a = noise(i * 3) * 2 * .pi, r0 = 40 + noise(i * 3 + 1) * 1100
            let r = r0 * (1 + jump * 0.25), len = 2 + jump * jump * (60 + r0 * 0.4)
            let p = CGPoint(x: centre.x + cos(a) * r, y: centre.y + sin(a) * r * 0.6)
            ctx.move(to: p); ctx.addLine(to: CGPoint(x: p.x + cos(a) * len, y: p.y + sin(a) * len * 0.6))
            ctx.setStrokeColor(CGColor(red: 0.85, green: 0.92, blue: 1, alpha: 0.4 + 0.6 * noise(i * 3 + 2))); ctx.setLineWidth(3); ctx.strokePath()
        }
        let go = clamp((l - 0.9) / 0.4)
        if go < 1 {                                                 // the Millennial Falcon, gone in a blink
            let fc = PixelCanvas(Ride.width, Ride.height)
            drawRide(fc, .falcon, ramp: 0, engines: true, gear: false); fc.addOutline(C(0xFFFFFF, 0.92))
            if let img = fc.makeImage() {
                let s = 7 * (1 - go * 0.95)
                ctx.saveGState(); ctx.interpolationQuality = .none
                ctx.draw(img, in: CGRect(x: lerp(900, centre.x, go) - Double(Ride.width) * s / 2, y: lerp(560, centre.y, go) - Double(Ride.height) * s / 2,
                                         width: Double(Ride.width) * s, height: Double(Ride.height) * s))
                ctx.restoreGState()
            }
        }
        var sup = Actor(cast: .hero(DetectiveHero.superman), x: lerp(-20, 70, easeOut(l / 1.0)) - max(0, l - 1.6) * 6, mode: .idle)
        sup.airborne = true; sup.lift = 70
        draw(sup, ctx, t: t)
        if l > 1.8 { balloon("Hey! Wait up!", ctx, center: CGPoint(x: 700, y: 780), tail: headPoint(sup), size: 46, width: 600) }
        cutAndSlate(ctx, local: l, at: 4.0, take: "22")
    },
    // The final take: everyone in one frame, Deadpond in front, and a wrap.
    Shot(name: "wrap", start: 33.0, end: 41.9, into: .cut) { ctx, l, t in
        set(ctx, .avengersTower, t: t)
        let wave = l > 5.6
        let back: [(Cast, Double)] = [(.villain(StarClawdsVillain.vader), 22), (.hero(StarClawdsHero.luke), 58), (.villain(MarvelousVillain.thanos), 100),
                                      (.hero(MarvelousHero.thor), 146), (.villain(DoctorVillain.dalick), 190), (.villain(DetectiveVillain.joker), 232),
                                      (.hero(StarClawdsHero.han), 270), (.hero(DoctorHero.rose), 306)]
        for (i, (who, x)) in back.enumerated() {
            var a = Actor(cast: who, x: x, facing: i % 2 == 0 ? 1 : -1, mode: .idle, role: wave ? .cheer : .none)
            a.grow = 0.85; a.lift = 18
            draw(a, ctx, t: t + Double(i) * 0.3)
        }
        // the dancers moonwalk until the wrap is called
        let moon = { (who: Cast, offset: Double) in
            if !wave && who.persona.fidgets { forcedHabit = HabitPlay(kind: .moonwalk, e: (l + offset).truncatingRemainder(dividingBy: IdleHabit.moonwalk.length)) }
        }
        let front: [(Cast, Double)] = [(.hero(MarvelousHero.starLord), 36), (.hero(DoctorHero.doctorTen), 88), (.hero(DetectiveHero.batman), 236), (.hero(MarvelousHero.howardTheDuck), 288)]
        for (i, (who, x)) in front.enumerated() {
            var a = Actor(cast: who, x: x, facing: x < 160 ? 1 : -1, mode: .idle, role: wave ? .cheer : .none)
            a.grow = 1.05
            if who.universe.module.moonwalkers.contains(who) { moon(who, Double(i) * 0.9) }
            draw(a, ctx, t: t + Double(i) * 0.5)
            forcedHabit = nil
        }
        var dp = Actor(cast: .hero(MarvelousHero.deadpool), x: 162, mode: .idle, role: wave ? .cheer : .none)
        dp.grow = 1.7; dp.lift = -18
        moon(dp.cast, 1.8)
        draw(dp, ctx, t: t)
        forcedHabit = nil
        // Spider-Clawd swings across, upside down, as Superb-Man flies the other way
        let u = (l - 0.3) / 0.6
        if u > 0 && u < 4 {
            let reach = 58.0, i = floor(u), th = -swingAngle * cos(.pi * (u - i)), step = 2 * reach * sin(swingAngle)
            let anchor = (x: -20 + step * i, y: -10.0), feet = (x: anchor.x + reach * sin(th), y: anchor.y + reach * cos(th))
            var spidey = Actor(cast: .hero(MarvelousHero.spiderMan), x: feet.x, mode: .idle)
            spidey.lift = groundY - 44 - feet.y
            drawUpsideDown(spidey, ctx, t: t)
            let web = PixelCanvas(fxW, fxH)
            web.glowLine(feet.x, feet.y + 2, anchor.x, anchor.y, core: C(0xF4F4F8, 0.9), glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
            blit(web, ctx)
        }
        let fl = (l - 0.7) / 2.0
        if fl > 0 && fl < 1 {
            var sup = Actor(cast: .hero(DetectiveHero.superman), x: lerp(370, -50, fl), facing: -1, mode: .idle)
            sup.airborne = true; sup.lift = 64 + sin(fl * .pi) * 8
            draw(sup, ctx, t: t)
        }
        if l > 2.7 && l < 5.6 {
            balloon("Separate universes, they said. Totally under control.", ctx, center: CGPoint(x: 960, y: 880), tail: headPoint(dp), size: 44, width: 1100)
        }
        cutAndSlate(ctx, local: l, at: 5.6, take: "99", wrap: true)
        let fade = clamp((l - 8.1) / 0.6)
        if fade > 0 { ctx.setFillColor(CGColor(gray: 0, alpha: fade)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
    },
]

// MARK: The Clawd Royale teaser (every universe's cast in one scene)

/// `s` in Futura Condensed ExtraBold at `size`, centred on `c`: `color` inside a thick, round ink outline.
func inkLettered(_ s: String, _ c: CGPoint, size: CGFloat, color: NSColor, alpha: Double = 1, kern: CGFloat = 0) {
    let f = NSFont(name: "Futura-CondensedExtraBold", size: size) ?? .systemFont(ofSize: size, weight: .black)
    let base: [NSAttributedString.Key: Any] = [.font: f, .kern: kern]
    let sz = NSAttributedString(string: s, attributes: base).size()
    let p = NSPoint(x: c.x - sz.width / 2, y: c.y - sz.height / 2)
    var ink = base; ink[.foregroundColor] = NSColor(cgColor: inkColor)!.withAlphaComponent(alpha)
    var fill = base; fill[.foregroundColor] = color.withAlphaComponent(alpha)
    let stamp = NSAttributedString(string: s, attributes: ink), r = Double(size) * 0.06
    for k in 0..<16 {
        let a = Double(k) / 16 * 2 * .pi
        stamp.draw(at: NSPoint(x: p.x + cos(a) * r, y: p.y + sin(a) * r))
    }
    NSAttributedString(string: s, attributes: fill).draw(at: p)
}

/// CLAWD over ROYALE: yellow comic lettering with a heavy ink outline, set a little askew, like a stamp.
func royaleTitle(_ ctx: CGContext, center: CGPoint, scale s: Double, alpha: Double = 1) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y); ctx.scaleBy(x: s, y: s); ctx.rotate(by: 0.035)
    inkLettered("CLAWD", CGPoint(x: 0, y: 118), size: 130, color: yellow, alpha: alpha, kern: 8)
    inkLettered("ROYALE", CGPoint(x: 0, y: -38), size: 210, color: yellow, alpha: alpha, kern: 10)
    ctx.restoreGState()
}

/// A universe's menu bar emblem (`Theme.menuIcon`: Vader's helmet, the round shield, the C-shield), `px` screen pixels
/// a pixel, centred on `c` and turned by `angle`; ringed in ink, then white, so it reads on anything.
func emblem(_ u: Universe, _ ctx: CGContext, center c: CGPoint, px: Double, angle: Double = 0, alpha: Double = 1) {
    let icon = PixelCanvas(28, 26)
    Theme.of(u).menuIcon(icon, false)
    let e = PixelCanvas(32, 30)                     // room for the two rings
    let b = icon.buf
    for y in 0..<icon.h {
        for x in 0..<icon.w {
            let i = (y * icon.w + x) * 4, a = Double(b[i + 3])
            guard a > 0 else { continue }
            let un = { (v: UInt8) -> UInt8 in UInt8(min(255, Double(v) * 255 / a)) }   // the buffer is premultiplied
            e.px(x + 2, y + 2, Px(r: un(b[i]), g: un(b[i + 1]), b: un(b[i + 2]), a: b[i + 3]))
        }
    }
    e.addOutline(C(0x111018)); e.addOutline(C(0xFFFFFF))
    guard let img = e.makeImage() else { return }
    let w = Double(e.w) * px, h = Double(e.h) * px
    ctx.saveGState(); ctx.interpolationQuality = .none; ctx.setAlpha(CGFloat(alpha))
    ctx.translateBy(x: c.x, y: c.y); ctx.rotate(by: CGFloat(angle))
    ctx.draw(img, in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
    ctx.restoreGState()
}

/// When the emblems slam together, and when the title stamps in (shot seconds into the collision).
let royaleSlam = 0.6, royaleStamp = 1.05

/// The three menu bar emblems fly in from three sides and slam together (KRA-KOOM!), and CLAWD ROYALE stamps in.
func royaleCollide(_ ctx: CGContext, local l: Double, t: Double) {
    let since = l - royaleSlam
    let shake = since > 0 && since < 0.35 ? (0.35 - since) * 70 : 0
    let mid = CGPoint(x: Double(W) / 2, y: Double(H) / 2)
    ctx.saveGState()
    ctx.translateBy(x: sin(t * 80) * shake, y: cos(t * 70) * shake)
    halftone(ctx, fullRect.insetBy(dx: -40, dy: -40), base: hexCG(0x1B2257), dot: hexCG(0x2E3C8C), step: 26)
    // the slam's burst, staying behind the title
    if since > 0 {
        let f = backOut(since / 0.3)
        starburst(ctx, center: mid, inner: 300 * f, outer: 540 * f, spikes: 18, color: hexCG(0xFFE04A), spin: l * 0.12)
        starburst(ctx, center: mid, inner: 230 * f, outer: 400 * f, spikes: 14, color: hexCG(0xE8332A), spin: -l * 0.16)
    }
    // the emblems: in from all round the frame, spinning, then knocked out to a row over the title
    let shown = Universe.offered, n = Double(shown.count), gap = min(320, 1500 / max(1, n - 1))
    let from = shown.indices.map { i -> (x: Double, y: Double, turn: Double) in
        let a = -Double.pi / 2 + 2 * .pi * Double(i) / n
        return (960 + cos(a) * 1500, 540 + sin(a) * 950, (i % 2 == 0 ? -1 : 1) * (0.8 + Double(i % 3) * 0.3))
    }
    let meet = shown.indices.map { i -> (x: Double, y: Double) in
        let a = -Double.pi / 2 + 2 * .pi * Double(i) / n
        return (960 + cos(a) * 190, 560 + sin(a) * 150)
    }
    let rest = shown.indices.map { i -> (x: Double, y: Double) in
        let k = Double(i) - (n - 1) / 2
        return (960 + k * gap, 975 - abs(k) * 14)
    }
    for (i, u) in shown.enumerated() {
        if since < 0 {
            let f = easeIn((l - 0.05) / (royaleSlam - 0.05))
            emblem(u, ctx, center: CGPoint(x: lerp(from[i].x, meet[i].x, f), y: lerp(from[i].y, meet[i].y, f)), px: 11,
                   angle: from[i].turn * (1 - f))
        } else {
            let f = backOut((since - 0.05) / 0.4)
            emblem(u, ctx, center: CGPoint(x: lerp(meet[i].x, rest[i].x, f), y: lerp(meet[i].y, rest[i].y, f)),
                   px: lerp(11, n > 5 ? 4.2 : 5, clamp(f)), angle: sin(since * 9) * 0.25 * max(0, 1 - since / 0.6))
        }
    }
    // the sound word, popping on the slam and gone as the title lands
    if since > 0 && l < royaleStamp + 0.15 {
        let p = backOut(since / 0.18), fade = 1 - clamp((l - royaleStamp + 0.05) / 0.2)
        inkLettered("KRA-KOOM!", mid, size: CGFloat(170 * p), color: NSColor(srgbRed: 0.88, green: 0.12, blue: 0.12, alpha: 1),
                    alpha: fade, kern: 6)
    }
    ctx.restoreGState()
    if since > 0 && since < 0.3 { ctx.setFillColor(CGColor(gray: 1, alpha: 0.9 * (1 - since / 0.3))); ctx.fill(fullRect) }   // the flash, unshaken
    // CLAWD ROYALE stamps down from big to its size, then the line under it
    if l > royaleStamp {
        let s = 1 + 1.4 * (1 - backOut((l - royaleStamp) / 0.3))
        royaleTitle(ctx, center: CGPoint(x: mid.x, y: mid.y - 20), scale: s * 0.95, alpha: clamp((l - royaleStamp) / 0.08))
    }
    let sub = royaleStamp + 0.35
    if l > sub {
        let f = backOut((l - sub) / 0.3), c = CGPoint(x: mid.x, y: 130)
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y); ctx.scaleBy(x: CGFloat(f), y: CGFloat(f)); ctx.translateBy(x: -c.x, y: -c.y)
        captionBox("UNIVERSES COLLIDE.", ctx, center: c, size: 46)
        ctx.restoreGState()
    }
}

/// A hero at `hx` against a villain at `vx` (fx units), facing each other in the roles their weapons give them, each
/// with its own name on its label.
func versus(_ hero: Cast, _ hx: Double, _ villain: Cast, _ vx: Double) -> (Actor, Actor) {
    let (rh, rv) = fightRoles(hero.weapon, villain.weapon)
    let side: Double = hx < vx ? 1 : -1
    let h = Actor(cast: hero, x: hx, facing: side, role: rh, label: hero.name, labelSize: 24)
    let v = Actor(cast: villain, x: vx, facing: -side, role: rv, label: villain.name, labelSize: 24)
    return (h, v)
}

/// Spider-Clawd swinging over everyone's heads on his web, from off the left at `start` (shot seconds), arc after arc,
/// to off the right: his actor and where his line is stuck (fx units), or nil when he's out of the frame.
let swingArc = 0.55, swingReach = 80.0, swingAngle = 55.0 * Double.pi / 180
func webSwing(_ l: Double, start: Double) -> (actor: Actor, anchor: (x: Double, y: Double))? {
    let u = (l - start) / swingArc
    guard u > 0, u < 3 else { return nil }
    let i = floor(u), th: Double = -swingAngle * cos(.pi * (u - i))
    let step = 2 * swingReach * sin(swingAngle)                 // so each arc ends where the next one starts
    let anchor = (x: 45 + step * i, y: -10.0)
    let hand = (x: anchor.x + swingReach * sin(th), y: anchor.y + swingReach * cos(th))
    let who = Cast.hero(MarvelousHero.spiderMan)
    var a = Actor(cast: who, x: hand.x - 13, walking: true, label: who.name, labelSize: 24)   // the raised hand: (41, 22)
    a.lift = groundY - 44 - (hand.y - 22)
    return (a, anchor)
}

/// The crew in one of the app's places: heroes against villains from every universe, each as itself, `fights` going at
/// it (`also`: the rest), and the place's name in a caption box along the bottom; the top shaded for the captions.
func royaleScene(_ ctx: CGContext, _ loc: Location, t: Double, fights: [(Actor, Actor)], also: [Actor] = []) {
    set(ctx, loc, t: t)
    let shade = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [CGColor(gray: 0, alpha: 0.55), CGColor(gray: 0, alpha: 0)] as CFArray,
                           locations: [0, 1])!                  // so the captions read on a bright place
    ctx.drawLinearGradient(shade, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: Double(H) - 330), options: [])
    for (a, b) in fights { draw(a, ctx, t: t); draw(b, ctx, t: t) }
    for a in also { draw(a, ctx, t: t) }
    drawFX(fights, ctx, t: t)
    captionBox(loc.name.uppercased(), ctx, center: CGPoint(x: Double(W) / 2, y: 70), size: 30)
}

let royaleShots: [Shot] = [
    Shot(name: "meanwhile", start: 0, end: 3.0, into: .cut) { ctx, local, t in
        ctx.setFillColor(CGColor(gray: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
        let line = "MEANWHILE, ACROSS THE UNIVERSES…"
        let n = Int(clamp((local - 0.3) / 1.6) * Double(line.count))
        let a = 1 - clamp((local - 2.6) / 0.35)
        if n > 0 { captionBox(String(line.prefix(n)), ctx, center: CGPoint(x: Double(W) / 2, y: Double(H) / 2), size: 54, alpha: a) }
    },
    // Every universe's menu bar emblem collides: KRA-KOOM!, and CLAWD ROYALE stamps in. Never a count of universes:
    // which ones take part may become a choice.
    Shot(name: "collide", start: 3.0, end: 6.5, into: .cut) { ctx, local, t in royaleCollide(ctx, local: local, t: t) },
    // The Mos Easy Cantina, a crew from every universe: Gandclawd duels Darth Vapor, Fox Clawder and a Dalick shoot it
    // out, Spider-Clawd swings over everyone.
    Shot(name: "crossover", start: 6.5, end: 11.0, into: .marvel(MarvelousComicTrip(kind: .burst, sound: .thwip))) { ctx, local, t in
        let (fox, dalick) = versus(.hero(FilesHero.foxClawder), 34, .villain(DoctorVillain.dalick), 104)
        let (gand, vapor) = versus(.hero(RingsHero.gandalf), 196, .villain(StarClawdsVillain.vader), 253)
        let swing = webSwing(local, start: 0.9)
        royaleScene(ctx, .cantina, t: t, fights: [(fox, dalick), (gand, vapor)], also: swing.map { [$0.actor] } ?? [])
        if let s = swing {                                          // his web line, from the raised hand up out of the frame
            let web = PixelCanvas(fxW, fxH), hand = s.actor.fighter.point(41, 22)
            web.glowLine(hand.x, hand.y, s.anchor.x, s.anchor.y, core: C(0xF4F4F8, 0.9), glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
            blit(web, ctx)
        }
        caption("Nobody asked who'd win. We're answering anyway.", ctx, local: local, start: 1.0, y: 900, size: 58)
    },
    // A new place, Clawdvengers Tower: the same crew, and Thanoz drops in on Spider-Clawd.
    Shot(name: "hopMarvel", start: 11.0, end: 13.5, into: .marvel(MarvelousComicTrip(kind: .speedLines))) { ctx, local, t in
        let land = clamp((local - 0.4) / 0.5), since = local - 0.9
        if since > 0 && since < 0.3 { let sh = (0.3 - since) * 40; ctx.translateBy(x: sin(t * 90) * sh, y: cos(t * 80) * sh) }   // the landing
        let (fox, dalick) = versus(.hero(FilesHero.foxClawder), 26, .villain(DoctorVillain.dalick), 92)
        let (gand, vapor) = versus(.hero(RingsHero.gandalf), 150, .villain(StarClawdsVillain.vader), 207)
        var (spidey, thanoz) = versus(.hero(MarvelousHero.spiderMan), 246, .villain(MarvelousVillain.thanos), 304)
        thanoz.lift = 150 * (1 - easeIn(land))
        if land < 1 { spidey.role = .none; thanoz.role = .none }
        royaleScene(ctx, .avengersTower, t: t, fights: land < 1 ? [(fox, dalick), (gand, vapor)] : [(fox, dalick), (gand, vapor), (spidey, thanoz)],
                    also: land < 1 ? [spidey, thanoz] : [])
    },
    // And Gothamburg, by the Night Beacon: new match-ups, Han Yolo on the Dalick, Batclawd on Darth Vapor, Indiana Bones
    // on Thanoz.
    Shot(name: "hopDC", start: 13.5, end: 16.0,
         into: .dc(DetectiveComicTrip(kind: .batSignal, caption: "MEANWHILE, IN \(Location.gotham.name.uppercased())…"))) { ctx, local, t in
        let (han, dalick) = versus(.hero(StarClawdsHero.han), 26, .villain(DoctorVillain.dalick), 92)
        let (bat, vapor) = versus(.hero(DetectiveHero.batman), 150, .villain(StarClawdsVillain.vader), 207)
        let (indy, thanoz) = versus(.hero(ClawdbergHero.indianaBones), 246, .villain(MarvelousVillain.thanos), 304)
        royaleScene(ctx, .gotham, t: t, fights: [(han, dalick), (bat, vapor), (indy, thanoz)])
    },
    // The end card: the icon's three panels, a crew from every universe lined up, the emblems and CLAWD ROYALE.
    Shot(name: "endcard", start: 16.0, end: 20.5) { ctx, local, t in
        coverPanels(ctx, t: t, fighters: false, dim: 0.45)
        let crew: [(Cast, FightRole, AI)] = [(.hero(ClawdbergHero.indianaBones), .cheer, .desktop), (.hero(RingsHero.gandalf), .cheer, .qwen),
                                             (.hero(DetectiveHero.batman), .duel, .claude), (.villain(StarClawdsVillain.vader), .duel, .codex),
                                             (.villain(DoctorVillain.dalick), .cheer, .copilot), (.villain(MarvelousVillain.thanos), .cheer, .gemini)]
        var placed: [Actor] = []
        for (i, (who, role, ai)) in crew.enumerated() {
            var a = Actor(cast: who, x: [28.0, 84, 140, 197, 252, 300][i], facing: i < 3 ? 1 : -1, role: role, ai: ai)
            a.lift = 8
            a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
            draw(a, ctx, t: t + Double(i) * 0.3)
            placed.append(a)
        }
        if local > 0.5 { drawFX([(placed[2], placed[3])], ctx, t: t) }
        // One emblem per universe, the row centred however many there are (closer together if they'd run off the frame).
        let offered = Universe.offered, gap = min(200, Double(W - 160) / Double(offered.count))
        for (i, u) in offered.enumerated() {
            let f = backOut((local - 0.25 - Double(i) * 0.08) / 0.35)
            let x = Double(W) / 2 + (Double(i) - Double(offered.count - 1) / 2) * gap
            if f > 0 { emblem(u, ctx, center: CGPoint(x: x, y: 990), px: 4 * f) }
        }
        if local > 0.35 { royaleTitle(ctx, center: CGPoint(x: Double(W) / 2, y: 750), scale: backOut((local - 0.35) / 0.4) * 0.72) }
        caption("New in Clawd Clash", ctx, local: local, start: 0.6, y: 500, size: 56)
        let ff = easeOut((local - 0.9) / 0.3)
        if ff > 0, let icon = appIcon {
            let line = attributed("Free for macOS · github.com/rodclemen/clawd-clash", size: 44, weight: .bold, alpha: ff)
            let x = (Double(W) - 160 - line.size().width) / 2                 // the icon and the line, centred together
            ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
            ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
            ctx.draw(icon, in: CGRect(x: x, y: 20, width: 130, height: 130))
            ctx.restoreGState()
            line.draw(at: NSPoint(x: x + 160, y: 60))
        }
    },
]

let royaleOverlays: [Overlay] = [
    Overlay(start: 11.0, end: 16.0) { ctx, l in
        badge("CLAWD ROYALE · EVERY 10 MIN", ctx, alpha: clamp(l / 0.3))
        caption("A new place every ten minutes…", ctx, local: l, start: 0.2, y: 905, size: 54)
        caption("…from any universe.", ctx, local: l, start: 2.5, y: 840, size: 44, color: yellow, weight: .bold)
    },
]

let royaleBeats: [(key: Double, beat: Beat)] = [
    (1.8, ("MEANWHILE...", "Black screen. A yellow comic caption types itself out over a building drum roll.", "“MEANWHILE, ACROSS THE UNIVERSES…”", "typewriter keys, a snare roll")),
    (4.9, ("THE COLLISION", "Halftone blue. Every universe's menu bar emblem flies in from round the frame and they slam together: KRA-KOOM!, a white flash, a yellow and red burst; they bounce out to a row and CLAWD ROYALE stamps in.", "KRA-KOOM!  ·  CLAWD ROYALE  ·  “UNIVERSES COLLIDE.”", "whooshes, the big hit, a fanfare")),
    (8.4, ("THE CROSSOVER", "A FWIP! web burst into the Mos Easy Cantina: Gandclawd duels Darth Vapor, Fox Clawder and a Dalick shoot it out, Spider-Clawd swings over everyone on his web. Each has its name on its label.", "“Nobody asked who'd win. We're answering anyway.”", "the groove kicks in, sabers, blasters, web thwips")),
    (11.9, ("A NEW PLACE", "Speed lines into Clawdvengers Tower: the same crew, and Thanoz drops in on Spider-Clawd.", "CLAWD ROYALE · EVERY 10 MIN  ·  “A new place every ten minutes…”", "a whoosh, a thud, the gauntlet's crackle")),
    (15.1, ("FROM ANY UNIVERSE", "The Night Beacon transition into Gothamburg: new match-ups, Han Yolo against the Dalick, Batclawd against Darth Vapor, Indiana Bones against Thanoz.", "“…from any universe.”", "the clunk and the boom of the beacon")),
    (19.0, ("END CARD", "The icon's three panels, dimmed: a crew from every universe lines up, Batclawd duelling Darth Vapor, every universe's emblem pops in and CLAWD ROYALE lands.", "CLAWD ROYALE  ·  “New in Clawd Clash”  ·  “Free for macOS · github.com/rodclemen/clawd-clash”", "the closing chord")),
]

/// The Clawd Royale teaser's score and effects.
func royaleSound(_ m: Mix) {
    // the caption types itself out over a snare roll that builds to the slam
    let mw = start("meanwhile"), cl = start("collide"), slam = cl + royaleSlam
    for i in 0..<38 { m.type(mw + 0.3 + Double(i) / 38 * 1.6 + noise(i) * 0.02, vol: 0.16 + noise(i + 50) * 0.08) }
    m.tone(mw + 0.2, 3.4, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.4)
    var r = mw + 0.5
    while r < slam - 0.03 {
        let f = (r - mw) / (slam - mw)
        m.snare(r, vol: 0.015 + 0.1 * f * f)
        r += f > 0.75 ? 1.0 / 24 : 1.0 / 14
    }
    // the emblems fly in, slam (a big hit), and the title stamps down to a fanfare
    for k in 0..<3 { m.whoosh(cl + 0.35 + Double(k) * 0.04, 0.6, vol: 0.12) }
    m.boom(slam, vol: 0.65); m.noise(slam, 1.8, vol: 0.14, cutoff: 0.9, decay: 0.55, highpass: true, seed: 3)
    m.snare(slam, vol: 0.2); m.kick(slam, vol: 0.4)
    for n in [48, 55, 60, 64, 67] { m.tone(slam, 1.4, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.8) }
    let stamp = cl + royaleStamp
    m.clunk(stamp, vol: 0.3); m.boom(stamp, vol: 0.3)
    for (s, d, n) in [(0.0, 0.22, 67), (0.25, 0.22, 72), (0.5, 0.5, 76), (1.05, 0.22, 74), (1.3, 0.22, 76), (1.55, 0.9, 79)] as [(Double, Double, Int)] {
        m.tone(stamp + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(stamp + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }
    // the groove, from the web burst to the end card
    groove(m, from: start("crossover") - 0.5, to: start("endcard"), fadeIn: 1.0)
    // the fights: the saber duel and the shoot-out run through all three places, Spider-Clawd's web lines, Thanoz' gauntlet
    let cr = start("crossover"), hm = start("hopMarvel"), hd = start("hopDC"), se = start("endcard")
    m.hum(cr, hd - cr, vol: 0.022)
    for t in clashTimes(cr, hd) { m.clash(t, vol: 0.1) }
    for t in shotTimes(cr, se, offset: 0) { m.pew(t, vol: 0.07) }
    for t in shotTimes(cr, se, offset: blasterPeriod / 2) { m.pew(t, vol: 0.05) }
    for k in 0..<3 { m.thwip(cr + 0.9 + Double(k) * swingArc, vol: 0.12) }
    m.boom(hm + 0.9, vol: 0.3)
    m.crackle(hm + 0.9, se - hm - 0.9, vol: 0.035)
    for t in shotTimes(hd, se, offset: 0) { m.thwip(t, vol: 0.06); m.clash(t + boltArrival * blasterPeriod, vol: 0.06) }
    for s in shots { transitionSound(m, s) }
    // the end card: the closing chord
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 2.8, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.6 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.6 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.6 : 0.1)
    }
    m.boom(ec + 0.35, vol: 0.45)
    m.noise(ec + 1.4, 2.5, vol: 0.08, cutoff: 0.9, decay: 0.8, highpass: true, seed: 8)
    for t in clashTimes(ec + 0.5, duration) { m.clash(t, vol: 0.08) }
}

// MARK: Which video

/// promo, bloopers, full (the promo, then the bloopers, as one), royale, or a universe's own trailer by its REEL name.
let reel = ProcessInfo.processInfo.environment["REEL"] ?? "promo"
/// The universe's trailer REEL names, if it's one of theirs (`Promo/<Prefix>Reel.swift` in its folder).
let universeReel = registeredReels.first { $0.name == reel }
let promoLength = promoShots.last!.end
if let r = universeReel {
    softWipe = r.softWipe; poster = r.poster; geminiTask = r.geminiTask
} else if reel == "bloopers" {
    poster = ("clapper", 2.0)
} else if reel == "royale" {
    poster = ("collide", 2.2)
} else {
    poster = ("worlds", introSlam + 0.4)    // CLAWD CLASH just landed, the flash gone
}
shots = universeReel?.shots ?? {
    switch reel {
    case "bloopers": return blooperShots
    case "full": return promoShots + blooperShots.map { $0.shifted(promoLength) }
    case "royale": return royaleShots
    default: return promoShots
    }
}()
overlays = reel == "promo" || reel == "full" ? promoOverlays : reel == "royale" ? royaleOverlays : []

// MARK: Storyboard beats

var legendNames: String { listed(Universe.offered.map { Theme.of($0).legend.name }) }

var promoBeats: [(key: Double, beat: Beat)] { [
    (2.4, ("COLD OPEN", "Black screen. A yellow comic caption types itself out.", "“MEANWHILE, IN A TERMINAL NEAR YOU...”", "typewriter keys, a bell")),
    (5.6, ("DOWN THE VORTEX", "Lightning, then down Doctor Clawd's time vortex. The police box and every universe's legend tumble out two at a time, from opposite sides, on their own curves and spins: \(legendNames).", "no text", "thunder, the title-sequence tune, whooshes")),
    (11.0, ("CLAWD CLASH", "CLAWD CLASH flies up out of the eye of the vortex, faster and faster, and lands with a bang in the middle of the screen: a flash, the frame shakes.", "CLAWD CLASH", "a rising sweep, the big hit and the fanfare")),
    (14.5, ("THE HOOK", "Three busy terminals (Claude, Codex, Gemini), slow push-in.", "“Three AIs. Nine agents. One very confused human.”  →  “Sound familiar?”", "keyboard clicks")),
    (18.2, ("CHOOSE YOUR UNIVERSE", "Two heroes from every universe run along the bottom of the desktop, and CHOOSE YOUR UNIVERSE pops up over them.", "CHOOSE YOUR UNIVERSE", "running feet, a hit")),
    (16.5 + pageArrive(0) + 0.5, ("READING THE PAGE", "A comic page slams down over them, its panels split by slanted gutters that never line up. The camera swoops into the first panel and reads them one by one, straightening each up as it fills the screen with that universe's big moment.", "the universe's name on each panel  ·  \(Universe.offered.map { setPiece($0).word }.joined(separator: "  "))", "a whoosh and a hit per panel, a taste of each set piece")),
    (16.5 + (pageTurns.first ?? pageArrive(3)) + pageTurn * 0.3, ("PANEL BY PANEL", "On through the page in reading order, each with its sound word popping as the camera arrives. Back on the whole page, it curls over like a comic book's onto the next: \(listed(comicPages.map { listed($0.map(\.u.title)) }.map { "(\($0))" })).", "the panel's name and sound word", "each universe's own sound")),
    (16.5 + pageBack + 1.0, ("PICK YOURS", "The camera pulls back to the whole page, every universe's moment still playing in its panel.", "“ONE APP. MULTIPLE UNIVERSES. PICK YOURS.”", "a ping")),
    (afterChoose + 2.5, ("AT A GLANCE (THE CLAWD FILES)", "A case file opens on the status line-up: \(Cast.hero(FilesHero.foxClawder).name) working, a Grey thinking, the Flukeman's jumping NEEDS YOU, \(Cast.hero(FilesHero.skinnard).name) sat down napping.", "“All fun and games, and you still see everything.”", "blips, alert beeps")),
    (afterChoose + 7.0, ("SUBAGENTS (STEVIE CLAWDBERG)", "The treasure map routes us in: \(Cast.hero(ClawdbergHero.mikeyWaltz).name) stands guard, the Goonies walk in with their jobs on their labels.", "“Every subagent gets to be a Goonie.”", "footsteps")),
    (afterChoose + 12.3, ("WINDOW (CLAWD OF THE RINGS)", "The map of Middle-earth walks us to the window in \(Location.prancingPony.name): live cards tick, then a Codex card flips to NEEDS YOU.", "“Prefer a window? Step into \(Location.prancingPony.name).”", "a ping")),
    (afterChoose + 18.2, ("RANDOM", "The window changes universe on its own, twice, each with that universe's transition, inside the window only: down the vortex into Doctor Clawd, then a Star Clawds wipe.", "RANDOM · EVERY 5 MIN  ·  “Can't decide? Random switches the whole window to a new universe every few minutes.”", "the transitions' own sounds")),
    (afterChoose + 23.0, ("CLAWD ROYALE", "Halftone blue: every universe's menu bar emblem flies in from round the frame and they slam together, KRA-KOOM!, and CLAWD ROYALE stamps in.", "KRA-KOOM!  ·  CLAWD ROYALE  ·  “UNIVERSES COLLIDE.”", "whooshes and two smacks, like stickers slapped on, over the groove")),
    (afterChoose + 26.4, ("THE CROSSOVER", "A FWIP! web burst into \(Location.cantina.name): \(Cast.hero(FilesHero.foxClawder).name) against a Dalick, Batclawd duelling Darth Vapor, \(Cast.hero(RingsHero.gandalf).name) holding off Thanoz' gauntlet; Spider-Clawd swings over everyone as E.Clawd's bike flies the other way.", "CLAWD ROYALE  ·  “Nobody asked who'd win. We're answering anyway.”  ·  “Settings → Universe → Clawd Royale. A new place every ten minutes.”", "sabers, blasters, web thwips, a whoosh")),
    (afterChoose + 31.5, ("END CARD", "The icon lands over its dimmed panels, and every universe's emblem pops in under it.", "“Have fun. Keep track.”  ·  “Pick a universe, or let them collide · free for macOS · github.com/rodclemen/clawd-clash”", "a heroic cadence")),
] }


let blooperBeats: [(key: Double, beat: Beat)] = [
    (1.8, ("BLOOPERS", "A record scratch; a clapperboard slams down over red halftone: BLOOPERS, take 1, and snaps.", "BLOOPERS", "record scratch, slate clack, a goofier tune starts")),
    (6.9, ("TAKE 7", "The TARDIS wheezes into the Mos Easy Cantina and Doctor Ten steps out, face to face with Darth Vapor. He ducks back in, the box tries to leave, sputters and stays put; he steps out again, sheepish.", "“Ah. Wrong universe.”  ·  “…Is that a phone box?”  ·  “…Handbrake.”", "the wheeze, a sputter and a clunk, then CUT!")),
    (14.8, ("TAKE 12", "Batclawd lights the Night Beacon over the Doom Moon. Two Stormtroupers open fire on it and miss every shot.", "“You know it's a light, right?”", "blasters, all missing")),
    (20.6, ("TAKE 15", "The Jester Card transition spins in and flips: Thanoz is on the back, on Titan. The Jester peeks into the shot with a ?.", "no text", "the card flip, a slide whistle")),
    (25.6, ("TAKE 21", "Yodle calmly floats Thorr's hammer up off the floor. Thorr stares.", "“…”  ·  “Worthy, hmm. Heavy, it is not.”", "a shimmer, then CUT!")),
    (30.4, ("TAKE 22", "The Millennial Falcon jumps to hyperspace in a blink; Superb-Man is left behind in the star streaks.", "“Hey! Wait up!”", "the jump, a whoosh")),
    (34.6, ("THAT'S A WRAP", "Everyone crammed into one frame at Clawdvengers Tower, Doctor Ten, Rose Tiler and a Dalick among them. Spider-Clawd swings across upside down as Superb-Man flies the other way; Deadpond, Star-Laird and Harold the Duck moonwalk. Then the whole cast waves.", "“Separate universes, they said. Totally under control.”  ·  “CUT! THAT'S A WRAP!”", "web thwips, a whoosh, a final sting and applause")),
]

// MARK: Soundtrack

/// The promo's score and effects, `o` seconds in.
func promoSound(_ m: Mix) {
    // cold open: a key for every letter, a bell, a low drone
    let mw = start("meanwhile")
    for i in 0..<35 { m.type(mw + 0.3 + Double(i) / 35 * 1.6 + noise(i) * 0.02, vol: 0.18 + noise(i + 50) * 0.08) }
    m.ding(mw + 2.0)
    m.tone(mw + 0.2, 2.8, midi(33), wave: .sine, vol: 0.05, attack: 1.0, release: 0.8)

    // the vortex: lightning, the title-sequence tune, everyone whooshing past, then CLAWD CLASH hits with an original fanfare
    let w = start("worlds"), hit = w + introSlam
    m.noise(w + 0.1, 0.25, vol: 0.22, cutoff: 0.9, decay: 0.06, highpass: true, seed: 10); m.boom(w + 0.15, vol: 0.3)
    m.noise(w, hit - w, vol: 0.05, cutoff: 0.01, cutoffTo: 0.05, attack: 0.5, release: 0.2, seed: 3)
    doctorTune(m, from: hit - 8.0, bars: 5)
    for i in introTumblers.indices { let (s0, fly) = introTiming(i); m.whoosh(w + s0 + fly * 0.85, 0.9, vol: 0.11) }
    m.tone(hit - 1.1, 1.1, 200, to: 2400, wave: .saw, vol: 0.05, attack: 0.5, release: 0.05)
    m.boom(hit, vol: 0.6); m.noise(hit, 1.8, vol: 0.13, cutoff: 0.9, decay: 0.55, highpass: true, seed: 3)
    for n in [48, 55, 60, 64, 67] { m.tone(hit, 1.4, midi(n), wave: .saw, vol: 0.05, release: 0.6, decay: 0.8) }
    for (s, d, n) in [(0.3, 0.25, 67), (0.6, 0.25, 72), (0.9, 0.6, 76), (1.6, 0.25, 74), (1.9, 0.25, 72), (2.2, 1.2, 79)] as [(Double, Double, Int)] {
        m.tone(hit + s, d, midi(n + 12), wave: .square(0.5), vol: 0.07, release: 0.08, vibrato: 0.006)
        m.tone(hit + s, d, midi(n), wave: .saw, vol: 0.045, release: 0.08)
    }

    // the groove, from the hook to the end card, straight through Clawd Royale (its title is slapped on like a sticker,
    // no fanfare of its own to clash with it); the lead melody bows out at the slam and stays out, or its high note
    // lands on the FWIP like a fanfare, and coming back for the last bars sounds like the music starting over
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2, noLead: start("royale") + royaleSlam - 0.5...start("endcard"))
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }

    // choose your universe: running feet, the page slamming down, and for every panel a whoosh as the camera moves, a hit
    // as it lands and a taste of its big moment, then a ping for the line
    let chs = start("choose")
    for k in 0..<26 { m.step(chs + 0.2 + Double(k) * 0.08, vol: 0.05 + noise(k) * 0.03) }
    m.boom(chs + 0.2, vol: 0.18); m.snare(chs + 0.2, vol: 0.1)
    m.whoosh(chs + pageDrop + 0.1, 0.4, vol: 0.14); m.boom(chs + pageDrop + 0.35, vol: 0.3); m.snare(chs + pageDrop + 0.35, vol: 0.12)
    for (i, p) in comicPages.flatMap({ $0 }).enumerated() {
        let at = chs + pageArrive(i)
        m.whoosh(at - pageMove / 2, pageMove + 0.1, vol: 0.12); m.boom(at, vol: 0.18); m.pop(at + 0.05, step: i % 4)
        switch p.u {
        case .starWars: for k in 0..<5 { m.turbolaser(at + 0.1 + Double(k) * 0.18, pitch: k % 2 == 0 ? 1 : 0.8, vol: 0.05) }
        case .marvel: m.roar(at + 0.1, 1.0, vol: 0.16)
        case .dc: m.boom(at + 0.2, vol: 0.2); m.roar(at + 0.4, 0.8, vol: 0.14)
        case .doctor: m.wheeze(at, cycles: 2, vol: 0.08)
        case .clawdFiles: m.tone(at, 1.0, 220, to: 330, wave: .sine, vol: 0.05, attack: 0.3, release: 0.3)
        case .clawdberg: m.tone(at, 0.4, 300, to: 1800, wave: .saw, vol: 0.04, release: 0.05); m.boom(at + 0.45, vol: 0.2)
        case .middleEarth: for k in 0..<4 { m.kick(at + Double(k) * 0.24, vol: 0.25) }
        case .slayer: m.chug(at, root: 38, len: 0.5, mute: false); m.crash(at, vol: 0.08)
        default: comicPanel(p.u).hit(m, at)
        }
    }
    for at in pageTurns { m.flip(chs + at + 0.1, vol: 0.14); m.whoosh(chs + at + pageTurn / 2, pageTurn, vol: 0.1) }
    m.ping(chs + pageBack + 0.3)

    // the features
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    m.bark(ag + 1.4)
    let wi = start("window")
    m.hum(wi, 2.5, vol: 0.02)
    for k in [0.9, 1.8] { m.click(wi + k, vol: 0.06) }
    m.ping(wi + 2.5)

    // Clawd Royale: the emblems fly in and get slapped together, the title slapped on top, then everyone at once
    let ro = start("royale")
    for k in Universe.offered.indices { m.whoosh(ro + 0.3 + Double(k) * 0.03, 0.6, vol: 0.09) }
    m.smack(ro + royaleSlam, vol: 0.45)
    m.smack(ro + royaleStamp, vol: 0.38)
    let cr = start("crossover"), ce = end("crossover")
    m.hum(cr, ce - cr, vol: 0.022)
    for t in clashTimes(cr, ce) { m.clash(t, vol: 0.1) }
    for t in shotTimes(cr, ce, offset: 0) { m.pew(t, vol: 0.07) }
    for t in shotTimes(cr, ce, offset: blasterPeriod / 2) { m.pew(t, vol: 0.05) }
    for k in 0..<3 { m.thwip(cr + 0.7 + Double(k) * swingArc, vol: 0.12) }
    m.crackle(cr + 0.3, ce - cr - 0.3, vol: 0.03)
    m.whoosh(cr + 2.4, 2.0, vol: 0.1)                                             // the bike going over
    for s in shots { transitionSound(m, s) }

    // end card: a heroic cadence and the icon landing
    let ec = start("endcard")
    for (s, d, chord, lead) in [(0.0, 0.7, [53, 57, 60, 65], 81), (0.7, 0.7, [55, 59, 62, 67], 83), (1.4, 3.4, [57, 61, 64, 69], 85)] {
        for n in chord { m.tone(ec + s, d, midi(n), wave: .saw, vol: 0.045, attack: 0.02, release: d > 1 ? 1.8 : 0.1) }
        m.tone(ec + s, d, midi(lead), wave: .square(0.5), vol: 0.06, release: d > 1 ? 1.8 : 0.1, vibrato: 0.006)
        m.tone(ec + s, d, midi(chord[0] - 24), wave: .sine, vol: 0.2, release: d > 1 ? 1.8 : 0.1)
    }
    m.boom(ec + 0.3, vol: 0.45)
    for k in 0..<Universe.offered.count { m.pop(ec + 0.5 + Double(k) * 0.08, step: k % 4) }
}

/// The blooper reel's goofy tune and gags.
func bloopersSound(_ m: Mix) {
    let cl = start("clapper")
    m.scratch(cl + 0.05)
    m.clack(cl + 1.0, vol: 0.4)
    // an oom-pah tune in F, kazoo lead: from the slate to the end, quiet under the takes
    let beat = 60.0 / 140, t0 = cl + 1.1, stopA = -1.0, stopB = -1.0
    let roots = [41, 46, 48, 41], chords = [[65, 69, 72], [65, 70, 74], [64, 67, 72], [65, 69, 72]]
    let tune: [(Int, Double)] = [(72, 1), (74, 0.5), (76, 0.5), (77, 1), (72, 1), (74, 0.5), (72, 0.5), (70, 1), (69, 2),
                                 (69, 1), (70, 0.5), (72, 0.5), (74, 1), (70, 1), (72, 0.5), (70, 0.5), (69, 1), (65, 2)]
    var b = 0
    var bt = t0
    while bt < end("wrap") - 1.2 {
        let c = (b / 4) % 4
        if !(bt > stopA && bt < stopB) {
            m.tone(bt, beat * 0.5, midi(roots[c] - 12 + (b % 2 == 0 ? 0 : 7)), wave: .square(0.5), vol: 0.06, release: 0.03)   // oom
            for n in chords[c] { m.tone(bt + beat * 0.5, beat * 0.35, midi(n - 12), wave: .square(0.125), vol: 0.022, release: 0.02) }   // pah
        }
        b += 1; bt += beat
    }
    var lt = t0, i = 0
    while lt < end("wrap") - 1.4 {
        let (n, d) = tune[i % tune.count]
        if !(lt > stopA && lt < stopB) { m.tone(lt, d * beat * 0.9, midi(n), wave: .saw, vol: 0.035, attack: 0.02, release: 0.05, vibrato: 0.02) }
        lt += d * beat; i += 1
    }
    // every take ends on CUT! and a slate
    for (name, at) in [("take7", 8.2), ("take12", 4.0), ("take15", 3.4), ("take21", 5.4), ("take22", 4.0)] {
        let s = start(name)
        m.tone(s + at, 0.18, 300, to: 220, wave: .square(0.5), vol: 0.08, release: 0.05)   // a honk for the CUT!
        m.clack(s + at + 0.7)
    }
    let t7 = start("take7")
    m.wheeze(t7, cycles: 3, vol: 0.14)
    m.clunk(t7 + 1.9, vol: 0.1); m.clunk(t7 + 5.0, vol: 0.1); m.clunk(t7 + 7.0, vol: 0.1)
    for k in 0..<4 { m.step(t7 + 2.15 + Double(k) * 0.15, vol: 0.08); m.step(t7 + 4.65 + Double(k) * 0.12, vol: 0.08) }
    for n in [43, 46, 50] { m.tone(t7 + 1.3, 0.9, midi(n), wave: .saw, vol: 0.05, release: 0.4) }               // Vapor turns
    m.wheeze(t7 + 5.4, cycles: 2, vol: 0.12)                                                                     // it tries to go…
    m.tone(t7 + 6.6, 0.3, 160, to: 60, wave: .saw, vol: 0.08, release: 0.1); m.clunk(t7 + 6.8, vol: 0.25)       // …and can't
    m.wahWah(t7 + 7.7)
    let t12 = start("take12")
    m.clunk(t12)
    for i in 0..<12 { m.pew(t12 + 0.5 + Double(i) * 0.22, vol: 0.07) }
    let t15 = start("take15")
    m.flip(t15 + 0.5, vol: 0.1); m.slideWhistle(t15 + 1.4, up: false)
    m.shimmer(start("take21") + 0.5, 1.5)
    let t22 = start("take22")
    m.tone(t22 + 0.6, 0.4, 200, to: 2400, wave: .saw, vol: 0.06, release: 0.1); m.boom(t22 + 0.95, vol: 0.3); m.whoosh(t22 + 1.6, 1.2, vol: 0.12)
    let wr = start("wrap")
    for k in 0..<4 { m.thwip(wr + 0.3 + Double(k) * 0.6, vol: 0.1) }
    m.whoosh(wr + 1.7, 1.6, vol: 0.14)
    for n in [53, 57, 60, 65, 69] { m.tone(wr + 5.6, 1.8, midi(n), wave: .saw, vol: 0.045, release: 1.0) }
    m.boom(wr + 5.6, vol: 0.35)
    m.applause(wr + 5.7, 2.6)
}

/// The reel's score and effects.
func score(_ m: Mix) {
    if let r = universeReel { r.sound(m); return }
    switch reel {
    case "royale": royaleSound(m)
    default:
        if reel != "bloopers" { promoSound(m) }
        if reel != "promo" { bloopersSound(m) }
    }
}

// MARK: Main

// The baseline (Tools/Baseline) needs the same pictures every run: the cantina's band is otherwise picked at random.
if ProcessInfo.processInfo.environment["BASELINE"] != nil { starClawdsBandForced = false }
let args = CommandLine.arguments
let cmd = args.count > 1 ? args[1] : "storyboard"
let out = args.count > 2 ? args[2] : "promo"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
let base = universeReel?.base ?? ["promo": "clawd-clash-promo", "bloopers": "clawd-clash-bloopers", "full": "clawd-clash-full",
                                  "royale": "clawd-royale-promo"][reel] ?? "clawd-clash-promo"

switch cmd {
case "video":
    let tmp = NSTemporaryDirectory()
    writeVideo(to: tmp + "\(base)-silent.mp4")
    writeWAV(soundtrack(score), to: tmp + "\(base).wav")
    mux(video: tmp + "\(base)-silent.mp4", audio: tmp + "\(base).wav", to: "\(out)/\(base).mp4")
case "check":                                                   // render every frame once, saying where it got to
    for f in 0..<Int(duration * fps) {
        let t = Double(f) / fps
        FileHandle.standardError.write("\(t)\n".data(using: .utf8)!)
        autoreleasepool { _ = frame(t) }
    }
    print("all \(Int(duration * fps)) frames render")
case "720p":                                                    // the GitHub-sized copy of a reel already rendered
    let small = universeReel?.small ?? ["promo": "Clawd-Clash", "bloopers": "Bloopers", "full": "Clawd-Clash-Full",
                                        "royale": "Clawd-Royale"][reel] ?? "Clawd-Clash"
    write720p(from: "\(out)/\(base).mp4", to: "\(out)/720p/\(small).mp4")
case "audio":
    writeWAV(soundtrack(score), to: "\(out)/\(base).wav"); print("wrote \(out)/\(base).wav")
case "frame":
    let t = Double(args[3]) ?? 0
    save(frame(t), "\(out)/t\(args[3]).png"); print("wrote \(out)/t\(args[3]).png")
default:
    if let r = universeReel { save(storyboard(r.title, r.beats), "\(out)/\(r.storyboardFile)") }
    else if reel == "bloopers" { save(storyboard("CLAWD CLASH: BLOOPERS", blooperBeats), "\(out)/storyboard-bloopers.png") }
    else if reel == "royale" { save(storyboard("CLAWD ROYALE", royaleBeats), "\(out)/storyboard-clawd-royale.png") }
    else { save(storyboard("CLAWD CLASH", promoBeats), "\(out)/storyboard-promo.png") }
    print("wrote the \(reel) storyboard to \(out)")
}
