import Foundation

// Clawds of the Universe's habits, the things that make Eternia behave like the show rather than just look like it,
// all through the engine's stage quirks (`StageQuirks`):
//  - Orkko's magic goes wrong: now and then a rubber fish pops out of thin air and flops on the ground in front of
//    him, or his own scarf winds itself round him and he wobbles (his rain cloud is his signature);
//  - Skeleclawd's retreat: once a fight he was in is over, he vanishes in a purple puff, "I'll get you for this,
//    He-Clawd!", and turns up again when the smoke clears (`afterDuel`, the end of his signature);
//  - Cringer hides: while a villain is on stage, now and then he slinks round behind the nearest hero, covering his
//    eyes and trembling; Gwildor does the same, clutching the Cosmic Key to his chest;
//  - Loo-Kee hides behind a leafy branch and peeks out (he's only ever an agent, who never idles, so this is the only
//    place his signature plays);
//  - Imp turns into a stool for a few seconds, in a puff of lilac smoke;
//  - Two Bad's heads argue, nose to nose, each shouting in turn;
//  - Stinkor lifts his tail, and anyone of Eternia standing near him shuffles away from the cloud;
//  - the Dark Troopers, two or more of them on stage, now and then march on the spot in step, one calling time.
//
// How it's done: the stage asks each character for its `remark` (only while it stands about, out of a fight), then
// draws it, then asks for its `jitter`. So `eterniaStageRemark` works out whose habit is on and notes it
// (`eterniaTurn`), the drawing code reads the note (`eterniaHabitK`, `eterniaMarchStep`, …) and `eterniaStageJitter`
// moves them and clears it. Every note is for one character, so nobody else's drawing ever picks it up.

/// The habits, as the module's `quirks`.
let eterniaQuirks = StageQuirks(jitter: eterniaStageJitter, remark: eterniaStageRemark,
                                afterDuel: [.villain(EterniaVillain.skeleclawd)],
                                afterDuelFrom: [.villain(EterniaVillain.skeleclawd): eterniaRetreatFrom])

// MARK: - Who's doing what

private let eterniaOrkko = Cast.hero(EterniaHero.orkko), eterniaCringer = Cast.hero(EterniaHero.cringer)
private let eterniaGwildor = Cast.hero(EterniaHero.gwildor), eterniaLooKee = Cast.hero(EterniaHero.looKee)
private let eterniaImp = Cast.villain(EterniaVillain.imp), eterniaTwoBad = Cast.villain(EterniaVillain.twoBad)
private let eterniaStinkor = Cast.villain(EterniaVillain.stinkor), eterniaDarkTrooper = Cast.villain(EterniaVillain.darkTrooper)
private let eterniaSkeleclawd = Cast.villain(EterniaVillain.skeleclawd)

private enum EterniaHabit { case fish, scarf, cower, hide, disguise, argue, stink, march }

/// A habit being played: by whom, which, `e` seconds into its `length`, and how far it moves them (sprite pixels).
private struct EterniaTurn {
    let cast: Cast
    let habit: EterniaHabit
    let e: Double, length: Double
    var dx = 0, up = 0
    var step = -1
    var talker = 0
    var k: Double { min(1, e / length) }
}

/// The habit of whoever is being drawn now, noted by `eterniaStageRemark` and cleared by `eterniaStageJitter`.
private var eterniaTurn: EterniaTurn?

/// Who `eterniaStageRemark` was last asked about: standing about, out of a fight (only they shuffle away from Stinkor).
private var eterniaFree: Cast?

/// Previews: play this character's habit, `k` (0…1) through it, whatever the stage is doing (`cycle` 1: Orkko's scarf
/// rather than his fish).
var eterniaHabitForced: (cast: Cast, k: Double, cycle: Int)?

/// The habit playing for `who` right now, if it's one its own drawing shows.
private func eterniaTurnFor(_ who: Cast) -> EterniaTurn? {
    if let f = eterniaHabitForced, f.cast == who, let h = eterniaHabitOf(who, cycle: f.cycle) {
        let length = eterniaLength(h)
        var turn = EterniaTurn(cast: who, habit: h, e: f.k * length, length: length)
        turn.step = Int(f.k * 20) % 2
        turn.talker = Int(f.k * 6) % 2
        return turn
    }
    guard let turn = eterniaTurn, turn.cast == who else { return nil }
    return turn
}

/// Which habit `who` has (Orkko's two take turns, a cycle each).
private func eterniaHabitOf(_ who: Cast, cycle: Int) -> EterniaHabit? {
    switch who {
    case eterniaOrkko: return cycle % 2 == 0 ? .fish : .scarf
    case eterniaCringer, eterniaGwildor: return .cower
    case eterniaLooKee: return .hide
    case eterniaImp: return .disguise
    case eterniaTwoBad: return .argue
    case eterniaStinkor: return .stink
    case eterniaDarkTrooper: return .march
    default: return nil
    }
}

/// How long each lasts, and how often it comes round (seconds): a few seconds in every half minute or so.
private func eterniaLength(_ h: EterniaHabit) -> Double {
    switch h {
    case .fish, .scarf: return 4.2
    case .cower: return 6.5
    case .hide: return 5.0
    case .disguise: return 6.0
    case .argue: return 6.6
    case .stink: return 5.0
    case .march: return 5.6
    }
}

private func eterniaPeriod(_ h: EterniaHabit) -> Double {
    switch h {
    case .fish, .scarf: return 34
    case .cower: return 27
    case .hide: return 31
    case .disguise: return 41
    case .argue: return 33
    case .stink: return 37
    case .march: return 29
    }
}

/// 0…1 easing in over `a…b` and back out over `c…d` (0 before and after).
private func eterniaEase(_ k: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
    if k < a || k > d { return 0 }
    if k < b { return (k - a) / (b - a) }
    if k > c { return (d - k) / (d - c) }
    return 1
}

private var eterniaUptime: Double { ProcessInfo.processInfo.systemUptime }

// MARK: - The remark: whose habit is on

/// Someone of Eternia standing about, out of a fight: works out whether their habit is on (on their own beat, the
/// Dark Troopers on the stage's, so they keep in step), notes it for their drawing and their steps, and gives the
/// line they say with it, if any, turned the way they'd say it.
func eterniaStageRemark(_ a: OnStage, others: [OnStage], zoom z: CGFloat, t: Double) -> (facing: CGFloat, line: String)? {
    eterniaFree = a.cast
    eterniaTurn = nil
    guard !a.leaving, !a.walking, a.cast.universe == .eternia else { return nil }
    let march = a.cast == eterniaDarkTrooper
    let first = eterniaHabitOf(a.cast, cycle: 0)
    guard let first else { return nil }
    let period = eterniaPeriod(first)
    let lt = t / period + (march ? 0 : a.phase)
    let cycle = Int(floor(lt)), e = frac(lt) * period
    guard let habit = eterniaHabitOf(a.cast, cycle: cycle) else { return nil }
    let length = eterniaLength(habit)
    guard e < length else { return nil }
    var turn = EterniaTurn(cast: a.cast, habit: habit, e: e, length: length)
    let k = turn.k
    var said: (facing: CGFloat, line: String)?

    switch habit {
    case .fish:
        if k > 0.3 && k < 0.62 { said = (a.facing, "Oops!") }
    case .scarf:
        // Wound up and wobbling.
        if k > 0.2 && k < 0.8 { turn.dx = Int(e / 0.25) % 2 == 0 ? 1 : 0; said = (a.facing, "Oh dear, oh dear!") }
    case .cower:
        // Only with a villain about, and a hero near enough to hide behind: round the far side of them from the
        // nearest villain, a few seconds there, and back.
        let villains = others.filter { $0.cast.isDark && !$0.leaving }
        guard let villain = villains.min(by: { abs($0.x - a.x) < abs($1.x - a.x) }) else { return nil }
        let heroes = others.filter {
            !$0.cast.isDark && !$0.leaving && $0.cast != eterniaCringer && $0.cast != eterniaGwildor && $0.cast != eterniaLooKee
                && abs($0.x - a.x) < 140 * a.scale
        }
        guard let hero = heroes.min(by: { abs($0.x - a.x) < abs($1.x - a.x) }) else { return nil }
        let away: CGFloat = hero.x >= villain.x ? 1 : -1
        let target = hero.x + away * 11 * hero.scale
        let there = min(1, e / 1.0) * min(1, (length - e) / 1.0)
        turn.dx = Int(((target - a.x) / a.scale * CGFloat(there)).rounded())
        turn.up = (there > 0 && there < 1) && frac(t * 4) < 0.5 ? 1 : 0
        if a.cast == eterniaGwildor, there == 1 { turn.dx += Int(t * 14) % 2 }   // trembling
        // Said the way they already face: a line only turns them while it's up, and turning back mid-hide reads badly.
        if e > 0.6 && e < 2.6 { said = (a.facing, a.cast == eterniaCringer ? "Hide me!" : "Not the Key!") }
    case .hide:
        if k > 0.47 && k < 0.8 { said = (a.facing, "Did you find me?") }
    case .disguise:
        if k > 0.8 { said = (a.facing, "Heh heh heh!") }
    case .argue:
        // Turn and turn about, a line each, nose to nose.
        let lines = [["Left!", "Right!"], ["My turn!", "No, mine!"], ["Shut up!", "YOU shut up!"], ["I'm in charge!", "Ha!"]]
        let turnLength = 1.15, from = 0.15 * length
        let n = max(0, Int((e - from) / turnLength))
        turn.talker = n % 2
        let pair = lines[(cycle + n / 2) % lines.count]
        if e > from && k < 0.85 { said = (a.facing, pair[turn.talker]) }
    case .stink:
        eterniaStink = (a.x, a.scale, k, eterniaUptime)
    case .march:
        // Two or more of them standing about: all in step on the stage's clock, the one furthest left calling it.
        let squad = others.filter { $0.cast == eterniaDarkTrooper && !$0.leaving && !$0.walking }
        guard !squad.isEmpty else { return nil }
        let lead = (squad + [a]).min { $0.x < $1.x }!
        turn.step = Int(t * 2.6) % 2
        if a.x == lead.x && k > 0.1 && k < 0.9 { said = (lead.facing, "Hup, two! Hup, two!") }
    }
    eterniaTurn = turn
    return said
}

// MARK: - The jitter: their steps, and shuffling away from Stinkor

/// When Stinkor last let his cloud go, where and how far through it (`eterniaStageRemark` notes it while his habit
/// plays): anyone standing near him then shuffles away.
private var eterniaStink: (x: CGFloat, scale: CGFloat, k: Double, at: Double)?

/// The steps of whoever's habit is on (Cringer and Gwildor round behind a hero, Orkko's wobble), Skeleclawd's parting
/// line while he vanishes, and a shuffle away from Stinkor's cloud for anyone else standing near him.
func eterniaStageJitter(_ a: OnStage, others: [OnStage], place: Location?, t: Double) -> (dx: Int, up: Int, line: String?) {
    defer { eterniaTurn = nil; eterniaFree = nil }
    if a.cast == eterniaSkeleclawd, let at = eterniaRetreatSeen, eterniaUptime - at < 0.25 {
        return (0, 0, "I'll get you for this, He-Clawd!")
    }
    if let turn = eterniaTurn, turn.cast == a.cast, !a.walking { return (turn.dx, turn.up, nil) }
    // Stinkor's cloud: anyone of Eternia standing about within reach of it steps away, holding their nose.
    if eterniaFree == a.cast, a.cast != eterniaStinkor, !a.walking, !a.leaving, let s = eterniaStink,
       eterniaUptime - s.at < 0.3, abs(a.x - s.x) < 46 * s.scale {
        let away: CGFloat = a.x >= s.x ? 1 : -1
        let out = eterniaEase(s.k, 0.24, 0.4, 0.86, 0.98)
        let moving = out > 0 && out < 1
        return (Int((Double(away) * 13 * out).rounded()), moving && frac(t * 4) < 0.5 ? 1 : 0,
                s.k > 0.34 && s.k < 0.6 ? "Pee-yew!" : nil)
    }
    return (0, 0, nil)
}

// MARK: - What their drawing reads

/// How far (0…1) into the habit `who` is playing, for those whose habit is their own signature played on the stage's
/// cue (Cringer's cowering, Loo-Kee's peek, Imp's stool, Two Bad's argument, Stinkor's cloud): their drawing takes it
/// for the signature's progress.
func eterniaHabitK(_ who: Cast) -> Double? {
    guard let turn = eterniaTurnFor(who) else { return nil }
    switch turn.habit {
    case .cower: return who == eterniaCringer ? turn.k : nil
    case .hide, .disguise, .argue, .stink: return turn.k
    default: return nil
    }
}

/// Which of Two Bad's heads has the floor in the argument (0 the blue one, 1 the green), while it's on.
func eterniaTwoBadTalker(_ who: Cast) -> Int? {
    guard let turn = eterniaTurnFor(who), turn.habit == .argue else { return nil }
    return turn.talker
}

/// Gwildor, hiding: he holds the Cosmic Key in close to his chest.
func eterniaClutchingKey(_ who: Cast) -> Bool { eterniaTurnFor(who)?.habit == .cower && who == eterniaGwildor }

/// A Dark Trooper marching on the spot with the rest: which legs are up (`drawLegs`' step), in step with the others.
func eterniaMarchStep(_ who: Cast) -> Int? {
    guard let turn = eterniaTurnFor(who), turn.habit == .march else { return nil }
    return turn.step
}

/// A Dark Trooper marching: the lifted pair of legs (`eterniaMarchStep`) raised high off the ground, knees up, drawn
/// over the end of his drawing.
func eterniaMarchKnees(_ c: PixelCanvas, _ who: Cast) {
    guard let step = eterniaMarchStep(who), step >= 0, !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() where i % 2 == step {
        c.move(columns: lx..<(lx + 2), rows: 38..<44, dy: -2)
    }
}

// MARK: - Orkko's magic going wrong

/// Orkko's trick gone wrong, drawn over him at the end of his drawing: a rubber fish popping out of thin air in front
/// of him, dropping to the ground with a bounce and lying there flapping its tail till it pops away again; or his own
/// scarf come alive and wound round and round him, its end flailing.
func eterniaOrkkoMishap(_ c: PixelCanvas, _ p: Pose) {
    guard let turn = eterniaTurnFor(p.who) else { return }
    switch turn.habit {
    case .fish: eterniaDrawFish(c, k: turn.k, t: p.t)
    case .scarf: eterniaDrawTangle(c, k: turn.k, t: p.t)
    default: break
    }
}

private func eterniaDrawFish(_ c: PixelCanvas, k: Double, t: Double) {
    // On the ground, whatever his floating and breathing did to the canvas's origin.
    let (ox, oy, baseY) = (c.ox, c.oy, c.baseY)
    c.ox = 0; c.oy = 0; c.baseY = 0
    defer { c.ox = ox; c.oy = oy; c.baseY = baseY }
    let yellow = C(0xFFD23A), yellowD = C(0xE0862A), yellowL = C(0xFFF0A0), ink = C(0x1A1420)
    // The pops it comes and goes in: a star of sparks.
    func pop(_ x: Double, _ y: Double, _ f: Double) {
        // Solid sparks flying out, a little cross each while it's fresh, a dot as it goes.
        let r = 1.5 + f * 5
        for i in 0..<6 {
            let ang = Double(i) / 6 * 2 * .pi + 0.3
            let px = Int((x + cos(ang) * r).rounded()), py = Int((y + sin(ang) * r).rounded())
            c.px(px, py, C(0xFFFFFF))
            if f < 0.6 { for (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)] { c.px(px + dx, py + dy, C(0xFFE060)) } }
        }
    }
    if k > 0.06 && k < 0.2 { pop(52, 16, (k - 0.06) / 0.14) }
    if k > 0.84 && k < 0.98 { pop(52, 39, (k - 0.84) / 0.14) }
    guard k > 0.1 && k < 0.88 else { return }
    // Falling from where it popped, a bounce, then lying there.
    var y: Double
    if k < 0.3 { let f = (k - 0.1) / 0.2; y = 14 + f * f * 25 }
    else if k < 0.42 { let f = (k - 0.3) / 0.12; y = 39 - sin(f * .pi) * 5 }
    else { y = 39 }
    let lying = k >= 0.42
    let flap = lying && Int(t * 6) % 2 == 0
    let x = 47, top = Int(y.rounded()) - 2
    // A fat little toy fish, head to the left: rubber-duck yellow, a pale belly, a round black eye, its tail fanned behind it.
    c.pattern(x, top, [
        "..PPPPP..TT",
        ".PPPPPPPTT.",
        "PKPPPPPPPT.",
        ".pLLLLLp.TT",
        "..ppppp....",
    ], ["P": yellow, "p": yellowD, "L": yellowL, "K": ink, "T": flap ? yellowL : yellowD])
    if flap { c.px(x + 10, top - 1, yellowL) }
    c.px(x + 3, top, yellowL)   // the shine along its back
}

private func eterniaDrawTangle(_ c: PixelCanvas, k: Double, t: Double) {
    let wound = eterniaEase(k, 0.04, 0.2, 0.8, 0.96)
    guard wound > 0 else { return }
    let scarf = C(0x6A3AA8), scarfD = C(0x4A2478), scarfL = C(0x8E5ACC)
    // Loop after loop round his robe and arms, wound on from the top down, then off again.
    let loops: [(Double, Double, Double, Double)] = [
        (15, 30, 40, 34), (16, 35, 40, 31), (16, 37, 40, 39), (17, 39.5, 39, 36.5),
    ]
    let shown = Int((wound * Double(loops.count)).rounded(.up))
    for (i, l) in loops.prefix(shown).enumerated() {
        c.glowLine(l.0, l.1, l.2, l.3, core: scarf, glow: C(0, 0), coreR: 1.0, glowR: 1.1)
        c.glowLine(l.0, l.1 - 1, l.2, l.3 - 1, core: scarfL, glow: C(0, 0), coreR: 0.35, glowR: 0.4)
        c.px(i % 2 == 0 ? 39 : 16, Int(i % 2 == 0 ? l.3 : l.1), scarfD)
    }
    // Its end, flailing up over his hat.
    let flail = sin(t * 9) * 3
    c.glowLine(37, 31, 43, 24 + flail * 0.4, core: scarf, glow: C(0, 0), coreR: 1.0, glowR: 1.1)
    c.glowLine(43, 24 + flail * 0.4, 46 + flail * 0.5, 18 + flail, core: scarf, glow: C(0, 0), coreR: 0.9, glowR: 1.0)
    c.px(46 + Int((flail * 0.5).rounded()), 18 + Int(flail.rounded()), scarfL)
}

// MARK: - Skeleclawd's retreat

/// How far into Skeleclawd's signature (the shaken fist, then the retreat) the retreat starts, and where an
/// after-fight one starts from (a last shake of the fist, then the puff).
let eterniaRetreatStart = 0.62
let eterniaRetreatFrom = 0.5

/// When Skeleclawd's drawing last showed him retreating (the system clock): his line goes with it.
private var eterniaRetreatSeen: Double?

/// Skeleclawd's retreat, 0…1, if his signature `s` is into it and it's playing because a fight is over (or a preview
/// asked for it): played as an idle habit, his signature stops at the shaken fist.
func eterniaSkeleclawdRetreat(_ s: Double) -> Double? {
    guard s >= eterniaRetreatStart, forcedHabit?.kind == .signature else { return nil }
    eterniaRetreatSeen = eterniaUptime
    return min(1, (s - eterniaRetreatStart) / (1 - eterniaRetreatStart))
}

/// Whether he's gone, `r` into his retreat: the smoke has swallowed him and not yet given him back.
func eterniaRetreatGone(_ r: Double) -> Bool { r > 0.16 && r < 0.84 }

/// The purple puff he vanishes in: a cartoon cloud of round billows, lit on top, swelling over him and shrinking
/// away to a few wisps while he's gone; a second one he turns up again in, shrinking away off him.
func eterniaDrawRetreatPuff(_ c: PixelCanvas, r: Double, t: Double) {
    let base = C(0x9A5AD8), lit = C(0xDCC0FA), dark = C(0x6A2AB0)
    // `size` 0…1: how big the billows are (they shrink rather than fade, the pixel-art way).
    func cloud(_ size: Double, spin: Double) {
        guard size > 0.05 else { return }
        let ring = 4 + 7 * size
        let blobs = (0..<7).map { i -> (Int, Int, Int) in
            let ang = Double(i) / 7 * 2 * .pi + spin
            let rad = (2.5 + 2.5 * noise(i * 5 + 1)) * size + 0.5
            return (28 + Int((cos(ang) * ring).rounded()), 31 + Int((sin(ang) * ring * 0.75).rounded()), Int(rad.rounded()))
        }
        for b in blobs { c.ellipse(b.0, b.1 + 1, b.2, b.2, dark) }
        c.ellipse(28, 31, Int((ring * 0.9).rounded()), Int((ring * 0.7).rounded()), base)
        for b in blobs { c.ellipse(b.0, b.1, b.2, b.2, base) }
        for b in blobs where b.1 <= 31 { c.ellipse(b.0 - 1, b.1 - 1, max(1, b.2 / 2), max(1, b.2 / 2), lit) }
    }
    // Out: it swells over him, holds while he goes, and shrinks away.
    if r < 0.5 { cloud(r < 0.12 ? r / 0.12 : r < 0.24 ? 1 : max(0, 1 - (r - 0.24) / 0.26), spin: r * 2) }
    if r > 0.3 && r < 0.84 {
        // Wisps drifting up off where he stood.
        for i in 0..<3 {
            let f = frac(t * 0.8 + Double(i) / 3)
            let x = 23 + i * 5 + Int((sin(f * 6 + Double(i)) * 1.5).rounded()), y = 37 - Int(f * 18)
            let w = f < 0.6 ? 2 : 1
            c.rect(x, y, w, w, f < 0.5 ? lit : base)
        }
    }
    // Back: a smaller one, swelling just before he shows and shrinking off him.
    if r > 0.74 { cloud(r < 0.84 ? (r - 0.74) / 0.1 * 0.8 : max(0, 0.8 * (1 - (r - 0.84) / 0.16)), spin: 1 + r) }
}
