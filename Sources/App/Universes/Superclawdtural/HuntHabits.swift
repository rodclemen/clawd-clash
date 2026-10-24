import Foundation

// Superclawdtural's habits, the things that make the universe behave like the show rather than just look like it, all
// through the engine's stage quirks (`StageQuirks`, `huntQuirks` below, used by HuntUniverse.swift):
//  - "Bitch." "Jerk.": with Dean and Sam both on stage and standing about, now and then Dean turns to his brother and
//    says it, and Sam answers a beat later (`remark`, both off the same clock so the answer always follows);
//  - personal space: now and then Clawdstiel vanishes with a flutter of wings and a few feathers drifting down where
//    he stood, and turns up right behind the nearest hero, far too close ("Hello, Dean."). If it's Dean, he turns round
//    and says so. A few seconds later Clawdstiel flutters back to his spot (`remark` for who he visits and what's said,
//    `jitter` to put him there, his name tag going with him, `prop` for the feathers; his drawing shows the flutter).

let huntQuirks = StageQuirks(jitter: huntStageJitter, prop: huntFeathers, remark: huntRemark)

private let dean = Cast.hero(HuntHero.deanWinclawdster), sam = Cast.hero(HuntHero.samWinclawdster)
private let clawdstiel = Cast.hero(HuntHero.clawdstiel)

/// Every remark on stage: the brothers' exchange, Clawdstiel's hello, and Dean telling him about personal space.
func huntRemark(_ a: OnStage, others: [OnStage], zoom z: CGFloat, t: Double) -> (facing: CGFloat, line: String)? {
    guard !a.leaving else { return nil }
    if a.cast == clawdstiel { return huntVisit(a, others: others, t: t) }
    if a.cast == dean, let v = huntLiveVisit, v.target == dean, v.e > 1.4, v.e < huntVisitStay - 0.3 {
        return (v.side, "Cas. Personal space.")   // turned round to face him
    }
    return huntBrothers(a, others: others, zoom: z, t: t)
}

// MARK: - "Bitch." "Jerk."

private let huntBrothersPeriod = 46.0

/// Dean and Sam, both standing about within a short walk of each other: once every 46 seconds or so Dean turns to Sam
/// and says "Bitch.", and Sam turns back and answers "Jerk." a beat later. One clock for both, so the answer always
/// comes after.
private func huntBrothers(_ a: OnStage, others: [OnStage], zoom z: CGFloat, t: Double) -> (facing: CGFloat, line: String)? {
    guard a.cast == dean || a.cast == sam else { return nil }
    let other = a.cast == dean ? sam : dean
    guard let b = others.first(where: { $0.cast == other && !$0.leaving && !$0.walking && abs($0.x - a.x) < 260 * z }) else {
        return nil
    }
    let e = frac(t / huntBrothersPeriod) * huntBrothersPeriod
    let toward: CGFloat = b.x > a.x ? 1 : -1
    if a.cast == dean, e < 2.2 { return (toward, "Bitch.") }
    if a.cast == sam, e > 1.3, e < 3.6 { return (toward, "Jerk.") }
    return nil
}

// MARK: - Personal space

private let huntVisitPeriod = 52.0
/// How long he stays, in seconds, from the moment he turns up to the moment he flutters home.
let huntVisitStay = 5.0

/// One of Clawdstiel's visits, as last worked out.
private struct HuntVisit {
    let at: Double           // when (the system clock)
    let cycle: Int           // which visit, so the side he picked holds for all of it
    let target: Cast
    let side: CGFloat        // which side of them he stands: the one they had their back to when he came
    let dx: CGFloat          // how far that is from his own spot, in screen points
    let e: Double            // seconds into the visit
}
private var huntLastVisit: HuntVisit?

/// The visit going on right now, if there is one.
private var huntLiveVisit: HuntVisit? {
    guard let v = huntLastVisit, ProcessInfo.processInfo.systemUptime - v.at < 0.25 else { return nil }
    return v
}

/// Previews: the flutter, 0…1, whatever the stage is doing.
var huntFlutterForced: Double?

/// Once every 52 seconds or so, with a hero about, Clawdstiel goes and stands right behind the nearest one, Dean if
/// he's there: on the side they have their back to, facing the back of their head, a step too close.
private func huntVisit(_ a: OnStage, others: [OnStage], t: Double) -> (facing: CGFloat, line: String)? {
    let lt = t / huntVisitPeriod + a.phase
    let cycle = Int(floor(lt)), e = frac(lt) * huntVisitPeriod
    guard e < huntVisitStay, !a.walking else { huntLastVisit = nil; return nil }
    let heroes = others.filter { !$0.cast.isDark && $0.cast.universe == .hunters && !$0.leaving && !$0.walking
                                 && !$0.cast.universe.isHem($0.cast.id) }
    guard let target = heroes.first(where: { $0.cast == dean })
            ?? heroes.min(by: { abs($0.x - a.x) < abs($1.x - a.x) }) else { huntLastVisit = nil; return nil }
    let side = huntLastVisit.flatMap { $0.cycle == cycle && $0.target == target.cast ? $0.side : nil } ?? -target.facing
    let spot = target.x + side * 21 * target.scale   // shoulder to shoulder: one step too close
    huntLastVisit = HuntVisit(at: ProcessInfo.processInfo.systemUptime, cycle: cycle, target: target.cast, side: side,
                              dx: spot - a.x, e: e)
    let name = target.cast.name.split(separator: " ").first.map(String.init) ?? "friend"
    return (-side, "Hello, \(name).")
}

/// How far through the flutter of his wings Clawdstiel is (0…1, 0 when he isn't fluttering): the first half second
/// after he turns up, and the half second before he goes home. His drawing spreads his wings' shadow and a flash of
/// light by it.
var huntClawdstielFlutter: Double {
    if let f = huntFlutterForced { return f }
    guard let v = huntLiveVisit else { return 0 }
    if v.e < 0.6 { return 1 - v.e / 0.6 }
    if v.e > huntVisitStay - 0.5 { return (v.e - (huntVisitStay - 0.5)) / 0.5 }
    return 0
}

/// Where Clawdstiel stands while he visits: the whole way over, in his own sprite pixels.
func huntStageJitter(_ a: OnStage, others: [OnStage], place: Location?, t: Double) -> (dx: Int, up: Int, line: String?) {
    guard a.cast == clawdstiel, !a.walking, !a.leaving, let v = huntLiveVisit else { return (0, 0, nil) }
    return (Int((v.dx / max(a.scale, 0.01)).rounded()), 0, nil)
}

/// The feathers he leaves behind where he stood: a few pale feathers drifting down for a second and a half after he
/// goes.
func huntFeathers(_ a: OnStage, ground y: CGFloat, scale: CGFloat, t: Double) -> StageLayer? {
    guard a.cast == clawdstiel, let v = huntLiveVisit, v.e < 1.5 else { return nil }
    let c = PixelCanvas(30, Sprite.height)
    huntDrawFeathers(c, k: v.e / 1.5, t: t)
    guard let img = c.makeImage() else { return nil }
    return StageLayer(image: img, rect: CGRect(x: (a.x - 15 * scale).rounded(), y: y, width: 30 * scale,
                                               height: CGFloat(c.h) * scale))
}

/// Five feathers, `k` 0…1 through their fall: they burst out from where his shoulders were, then drift down, swaying,
/// fading as they settle. Pale grey-white with a darker quill and a grey edge, so they show on a dark desktop and in
/// Heaven's white light alike.
func huntDrawFeathers(_ c: PixelCanvas, k: Double, t: Double) {
    let fade = min(1, (1 - k) / 0.35)
    guard fade > 0 else { return }
    let vane = C(0xEEF0F4, fade), edge = C(0x9AA0AC, fade), quill = C(0x6A707C, fade)
    for i in 0..<5 {
        let spread = Double(i - 2) * 4.2 * min(1, k * 4)
        let fall = 24 + k * 16 + Double(i % 2) * 3
        let sway = sin(t * 3 + Double(i) * 1.7)
        let x = Int((15 + spread + sway * 1.5).rounded()), y = Int(fall.rounded())
        guard y < 43 else { continue }
        // A feather three pixels long, tilted as it swings: the quill at its tip, the vane either side.
        let tilt = sway > 0 ? 1 : 0
        c.px(x, y, edge); c.px(x + 1, y, vane); c.px(x + 2, y, edge)
        c.px(x + tilt, y + 1, vane); c.px(x + 1 + tilt, y + 1, edge)
        c.px(x + 1, y - 1, quill)
    }
}
