import Foundation

// Dungeon Crawler Clawd's habits, the things that make the crawl behave like the books rather than just look like
// them, all through the engine's stage quirks (`StageQuirks`):
//  - the fans: while Princess Donut is on stage, now and then a camera flash goes off near her, then another, and a
//    little green "+10,000 VIEWERS" ticker floats up over her name and fades (about every 47 seconds, 3.4 long);
//  - Mongo and Donut: when both stand about with Mongo on her tail's side, now and then he creeps up behind her,
//    sniffing, and nips her tail; she yowls, hops, turns round and swats his snout twice, and he backs off and slinks
//    back to his spot (the stage's beat: every 63 seconds, 5.6 long);
//  - Prepotente's scream: whenever his signature plays (he throws his head back and screams), the crew standing next
//    to him jump, then shiver till he stops, the nearest one complaining (his signature's own beat, about once a
//    minute while he idles);
//  - the AI's petty achievements: now and then a small blue System toast pops up over a session that's idling,
//    "ACHIEVEMENT" over something like "STOOD THERE": no loot box, about 50 pixels wide at most, three seconds (the
//    stage's beat: once every 110 seconds, to one idler at a time, taking turns).
//
// How it's done: the stage asks each character for its `remark` (only while it stands about, out of a fight), then
// draws it, then asks for its `jitter`, then its `prop`. So `crawlStageRemark` works out whose habit is on and notes
// it (`crawlTurn`, `crawlToastNow`), `crawlStageJitter` moves them, and `crawlStageProp` draws what goes over and
// round them (the flashes, the ticker, the swat, the toast) and clears the notes. Every note is for one character,
// so nobody else's drawing ever picks it up. Prepotente's scream is read off his own drawing (`drawnSignature`, still
// set when his jitter is asked for) and kept a moment (`crawlScream`), so those drawn before him the next frame jump
// too.
//
// The engine doesn't say who is idling, so a session counts as idling while it stands about out of a fight and has
// played one of its idle signatures in the last 30 seconds (`crawlIdleSeen`): only an idle session ever does.

/// The habits, as the module's `quirks`.
let crawlQuirks = StageQuirks(jitter: crawlStageJitter, prop: crawlStageProp, remark: crawlStageRemark)

// MARK: - Who's doing what

private let crawlDonut = Cast.hero(CrawlHero.donut), crawlMongo = Cast.hero(CrawlHero.mongo)
private let crawlPrepotente = Cast.hero(CrawlHero.prepotente)

/// The habits a preview can force (`crawlHabitForced`).
enum CrawlHabit { case fans, nip, toast }

/// Previews: play this habit, `k` (0…1) through it, whatever the stage's clock says (`cycle` picks the toast's
/// achievement). The fans play over Donut, the nip between Mongo and Donut (still only with Mongo on her tail's side,
/// near enough), the toast over the leftmost session standing about. Prepotente's scream needs no forcing: force his
/// signature (`forcedHabit`) while he's drawn.
var crawlHabitForced: (habit: CrawlHabit, k: Double, cycle: Int)?

/// How long each lasts, and how often it comes round (seconds).
private let crawlFansLength = 3.4, crawlFansPeriod = 47.0
private let crawlNipLength = 5.6, crawlNipPeriod = 63.0
private let crawlToastLength = 3.2, crawlToastPeriod = 110.0
/// How long after its last idle signature a session still counts as idling.
private let crawlIdleWindow = 30.0

/// Mongo and Donut's habit being played: by which of them, `e` seconds in, how far it moves them (sprite pixels),
/// and, for Donut, how far (0…1) into a swat she is, and how far (0…1) into the bite on her tail, at which row of her
/// art.
private struct CrawlTurn {
    let cast: Cast
    let e: Double
    var dx = 0, up = 0
    var swat: Double?
    var bite: (k: Double, row: Int)?
}

/// The nip, for whoever is being drawn now: noted by `crawlStageRemark`, cleared by `crawlStageProp`.
private var crawlTurn: CrawlTurn?

/// The toast, for whoever is being drawn now: which achievement, `e` seconds in.
private var crawlToastNow: (cast: Cast, e: Double, which: Int)?

/// How far the last `jitter` moved whoever is being drawn now, so their prop goes with them.
private var crawlMoved: (cast: Cast, dx: Int, up: Int)?

/// When each character was last seen playing its idle signature (the system clock).
private var crawlIdleSeen: [Cast: Double] = [:]

/// The stage's zoom, as the last remark was told it: a leader is drawn 3 points to an art pixel times it, an agent 2.
private var crawlZoom: CGFloat = 1

/// Prepotente screaming: where, how big, how far into his signature, and when it was seen (the system clock).
private var crawlScream: (x: CGFloat, scale: CGFloat, s: Double, at: Double)?

private var crawlUptime: Double { ProcessInfo.processInfo.systemUptime }

/// 0…1, eased in and out.
private func crawlSmooth(_ k: Double) -> Double { let k = max(0, min(1, k)); return k * k * (3 - 2 * k) }

/// Whether `a` is drawn as a session (a leader) rather than an agent.
private func crawlIsLeader(_ a: OnStage) -> Bool { a.scale / max(0.01, crawlZoom) > 2.5 }

/// Standing about: on stage, not walking, not on the way out.
private func crawlStill(_ a: OnStage) -> Bool { !a.walking && !a.leaving }

// MARK: - The remark: whose habit is on

/// Someone of the crawl standing about, out of a fight: works out whether Mongo and Donut's habit is on (and gives
/// the line, turned the way they say it), and whether the System picks them for a toast.
func crawlStageRemark(_ a: OnStage, others: [OnStage], zoom z: CGFloat, t: Double) -> (facing: CGFloat, line: String)? {
    crawlZoom = z
    crawlTurn = nil
    crawlToastNow = nil
    guard crawlStill(a), a.cast.universe == .crawl else { return nil }
    crawlPickToast(a, others: others, t: t)
    if a.cast == crawlMongo || a.cast == crawlDonut { return crawlNip(a, others: others, t: t) }
    return nil
}

/// Mongo and Donut, on the stage's beat: both standing about, near each other, Mongo behind her (on her tail's
/// side). Worked out the same way from each of them, so they keep in step.
///  - 0 to 1.4 s: Mongo creeps up behind her till his snout is at her tail, sniffing;
///  - 1.4: he lunges and nips it ("CHOMP!"); 1.5: she yowls and hops;
///  - 2.0 to 3.6: she turns round on him and swats his snout twice ("Bad Mongo! BAD!"); after the first he jerks back
///    with a screech;
///  - 3.6 to 5.2: he slinks back to where he was.
private func crawlNip(_ a: OnStage, others: [OnStage], t: Double) -> (facing: CGFloat, line: String)? {
    let isMongo = a.cast == crawlMongo
    let partner = isMongo ? crawlDonut : crawlMongo
    guard let b = others.filter({ $0.cast == partner && crawlStill($0) }).min(by: { abs($0.x - a.x) < abs($1.x - a.x) })
    else { return nil }
    let (donut, mongo) = isMongo ? (b, a) : (a, b)
    let f = donut.facing
    // Mongo on her tail's side, near enough to creep up in a second or so.
    guard (mongo.x - donut.x) * f < 0, abs(mongo.x - donut.x) < 130 * donut.scale else { return nil }
    let e: Double
    if let forced = crawlHabitForced {
        guard forced.habit == .nip else { return nil }
        e = forced.k * crawlNipLength
    } else {
        e = frac(t / crawlNipPeriod) * crawlNipPeriod
    }
    guard e < crawlNipLength else { return nil }
    var turn = CrawlTurn(cast: a.cast, e: e)

    // Her tail's plume is round column 10 of her art, its outer edge column 6, his snout's tip column 47. He's as
    // likely as not drawn before her (an agent always is), so his teeth stop at the plume's edge, where they still
    // show, and the bite itself is drawn on her (`crawlDrawBite`).
    let target = donut.x - f * ((Sprite.bodyCenterX - 6) * donut.scale + (47 - Sprite.bodyCenterX) * mongo.scale)
    let reach = Double((target - mongo.x) / mongo.scale)
    let swats: [(from: Double, to: Double)] = [(2.2, 2.5), (2.75, 3.05)]

    if isMongo {
        // Creeping up, there, jerked back, and slinking off home again.
        var there = crawlSmooth(e / 1.4)
        if e > 3.6 { there = 1 - crawlSmooth((e - 3.6) / 1.6) }
        var dx = reach * there
        if e > 1.4 && e < 1.7 { dx += Double(f) * 2 }                          // the nip
        if e > 2.3 && e < 3.6 { dx -= Double(f) * 4 * min(1, (e - 2.3) / 0.15) }   // swatted back
        turn.dx = Int(dx.rounded())
        let moving = (e > 0.1 && e < 1.3) || (e > 3.7 && e < 5.1)
        turn.up = moving && frac(t * 4) < 0.5 ? 1 : 0
        crawlTurn = turn
        // He faces her while he's at it (a line turns him only while it's up), and walks off home whichever way he
        // faces.
        if e < 1.4 { return (f, "Sniff… sniff…") }
        if e < 2.3 { return (f, "CHOMP!") }
        if e < 3.4 { return (f, "SKREE!") }
        return nil
    }
    // Donut: a hop when she's bitten, then round on him, a step in with each swat.
    if e > 1.5 && e < 1.9 { turn.up = Int((sin((e - 1.5) / 0.4 * .pi) * 3).rounded()) }
    if e >= 1.4 && e < 1.9 {
        // His snout's row (22 of his art), in the rows of hers: an agent is smaller, and stands on a raised ground.
        let ratio = Double(mongo.scale / donut.scale)
        let row = Double(Sprite.height) - (Double(Sprite.height) - 22) * ratio - (1 - ratio) * 8
        turn.bite = ((e - 1.4) / 0.5, Int(row.rounded()))
    }
    for s in swats where e >= s.from && e < s.to {
        let k = (e - s.from) / (s.to - s.from)
        turn.swat = k
        turn.dx = Int((-Double(f) * 3 * sin(k * .pi)).rounded())
    }
    crawlTurn = turn
    if e > 1.5 && e < 2.0 { return (f, "YEOWL!") }
    if e >= 2.0 && e < 3.6 { return (-f, "Bad Mongo! BAD!") }
    return nil
}

/// The System's toast, on the stage's beat: once a beat, to one of the sessions idling (standing about, out of a
/// fight, an idle signature seen lately), taking turns left to right. Noted for `a` if it's theirs.
private func crawlPickToast(_ a: OnStage, others: [OnStage], t: Double) {
    let forced = crawlHabitForced.flatMap { $0.habit == .toast ? $0 : nil }
    guard crawlIsLeader(a) else { return }
    let now = crawlUptime
    let idling = (others + [a]).filter {
        $0.cast.universe == .crawl && crawlStill($0) && crawlIsLeader($0)
            && (forced != nil || crawlIdleSeen[$0.cast].map { now - $0 < crawlIdleWindow } ?? false)
    }.sorted { $0.x < $1.x }
    guard !idling.isEmpty else { return }
    let cycle: Int, e: Double
    if let forced {
        cycle = forced.cycle; e = forced.k * crawlToastLength
    } else {
        let lt = t / crawlToastPeriod
        cycle = Int(floor(lt)); e = frac(lt) * crawlToastPeriod
    }
    guard e < crawlToastLength else { return }
    let pick = forced != nil ? idling[0] : idling[abs(cycle) % idling.count]
    guard pick.cast == a.cast, pick.x == a.x else { return }
    crawlToastNow = (a.cast, e, abs(cycle) % crawlAchievements.count)
}

// MARK: - The jitter: the nip, and jumping at the scream

/// Mongo's creep and Donut's hop and swats while their habit plays; Prepotente's scream noted when his drawing shows
/// it; and anyone of the crawl standing near him then jumps: a hop as it starts, a shiver till it stops, the nearest
/// one complaining.
func crawlStageJitter(_ a: OnStage, others: [OnStage], place: Location?, t: Double) -> (dx: Int, up: Int, line: String?) {
    var out: (dx: Int, up: Int, line: String?) = (0, 0, nil)
    defer { crawlMoved = (a.cast, out.dx, out.up) }
    let now = crawlUptime
    if a.cast == crawlPrepotente {
        // His signature is the scream (from 0.1 to 0.9 of it): still set from his drawing, just now.
        if let s = drawnSignature, s > 0.1, s < 0.9, crawlStill(a) { crawlScream = (a.x, a.scale, s, now) }
        return out
    }
    if let turn = crawlTurn, turn.cast == a.cast, !a.walking {
        out = (turn.dx, turn.up, nil)
        return out
    }
    guard let sc = crawlScream, now - sc.at < 0.3, crawlStill(a), a.cast.universe == .crawl else { return out }
    let reach = 46 * sc.scale
    guard abs(a.x - sc.x) < reach else { return out }
    let k = (sc.s - 0.1) / 0.8
    if k < 0.25 {
        out.up = Int((sin(k / 0.25 * .pi) * 4).rounded())
    } else if k < 0.95 {
        out.dx = Int(t * 10) % 2 == 0 ? 1 : -1
    }
    // The nearest one standing by says something about it.
    let near = (others + [a]).filter { $0.cast != crawlPrepotente && $0.cast.universe == .crawl && crawlStill($0) && abs($0.x - sc.x) < reach }
    if k > 0.25 && k < 0.85, let first = near.min(by: { (abs($0.x - sc.x), $0.x) < (abs($1.x - sc.x), $1.x) }), first.x == a.x {
        let lines = ["Gah! My ears!", "Every single time!", "Prepotente, PLEASE!", "Who let the goat in?"]
        out.line = lines[Int(sc.at / 60) % lines.count]
    }
    return out
}

// MARK: - The prop: what's drawn over and round them

/// The achievements the System hands out for standing about, in its block letters, a line or two each, a word of
/// thirteen letters at most so the toast stays small.
private let crawlAchievements: [[String]] = [
    ["STOOD THERE"], ["PROFESSIONAL", "LOITERER"], ["BREATHED IN", "AND OUT"], ["NOT DEAD YET"],
    ["IDLE HANDS"], ["PARTICIPATION", "TROPHY"], ["STILL HERE"], ["SPECTACULARLY", "AVERAGE"],
]

/// The prop's canvas: art pixels wide (centred on the character), and rows over a sprite's for what goes over its
/// name tag.
private let crawlPropWidth = 120, crawlHeadroom = 48
/// The toast's bottom edge, in rows over the head: clear of a name tag wrapped onto two lines. And the highest its top
/// goes, in rows of their art, so it stays in the window's scene over the tallest of them.
private let crawlToastRoom = 17, crawlToastCeiling = -31

/// A picture over and round `a`, on a canvas centred on it: the fans' flashes and ticker over Donut, her swat, the
/// System's toast over an idler. Nothing (no canvas at all) for anyone else, most of the time. Also notes who was
/// just seen playing an idle signature (`crawlIdleSeen`), and clears the notes the remark made.
func crawlStageProp(_ a: OnStage, ground y: CGFloat, scale: CGFloat, t: Double) -> StageLayer? {
    let turn = crawlTurn.flatMap { $0.cast == a.cast ? $0 : nil }
    let toast = crawlToastNow.flatMap { $0.cast == a.cast ? $0 : nil }
    let moved = crawlMoved.flatMap { $0.cast == a.cast ? $0 : nil }
    defer { crawlTurn = nil; crawlToastNow = nil; crawlMoved = nil }
    let signature = drawnSignature
    if signature != nil, crawlStill(a) { crawlIdleSeen[a.cast] = crawlUptime }
    guard a.cast.universe == .crawl, !a.leaving else { return nil }

    // The fans, on Donut's own beat, but never over her signature (which is her posing for them already).
    var fans: (e: Double, cycle: Int)?
    if a.cast == crawlDonut, signature == nil {
        if let forced = crawlHabitForced {
            if forced.habit == .fans { fans = (forced.k * crawlFansLength, forced.cycle) }
        } else {
            let lt = t / crawlFansPeriod + a.phase
            let e = frac(lt) * crawlFansPeriod
            if e < crawlFansLength { fans = (e, Int(floor(lt))) }
        }
    }
    guard fans != nil || turn?.swat != nil || turn?.bite != nil || toast != nil else { return nil }

    let c = PixelCanvas(crawlPropWidth, Sprite.height + crawlHeadroom)
    let f = a.facing
    // Art pixel (x, y), facing right, to the canvas.
    func cx(_ x: Double) -> Int { crawlPropWidth / 2 + Int((Double(f) * (x - Sprite.bodyCenterX)).rounded()) }
    func cy(_ y: Int) -> Int { y + crawlHeadroom }
    // Above the name tag: it sits 8 (agents 5) zoomed points over the head, about 19 (16) tall.
    let tagRows = crawlIsLeader(a) ? 10 : 12
    let over = cy(a.cast.drawnTop() - tagRows)

    if let fans { crawlDrawFans(c, e: fans.e, cycle: fans.cycle, over: over, cx: cx, cy: cy) }
    if let k = turn?.swat { crawlDrawSwat(c, k: k, cx: cx, cy: cy) }
    if let bite = turn?.bite { crawlDrawBite(c, k: bite.k, row: bite.row, cx: cx, cy: cy) }
    if let toast {
        crawlDrawToast(c, e: toast.e, lines: crawlAchievements[toast.which], bottom: cy(a.cast.drawnTop() - crawlToastRoom),
                       ceiling: cy(crawlToastCeiling))
    }

    guard let img = c.makeImage() else { return nil }
    let x = a.x + CGFloat(moved?.dx ?? 0) * scale - CGFloat(crawlPropWidth / 2) * scale
    return StageLayer(image: img, rect: CGRect(x: x.rounded(), y: y + CGFloat(moved?.up ?? 0) * scale,
                                               width: CGFloat(c.w) * scale, height: CGFloat(c.h) * scale))
}

/// The fans: three camera flashes from the crowd, here and there round her, a white star each that bursts and
/// shrinks away; with the second, the ticker: "+10,000 VIEWERS" in the green the counter uses, on a dark green strip,
/// floating up from over her name tag and fading.
private func crawlDrawFans(_ c: PixelCanvas, e: Double, cycle: Int, over: Int, cx: (Double) -> Int, cy: (Int) -> Int) {
    for i in 0..<3 {
        let from = Double(i) * 0.38, k = (e - from) / 0.3
        guard k > 0, k < 1 else { continue }
        // Low on one side or the other, at about her height: the crowd's cameras.
        let side = (Int(noise(cycle * 13) * 2) + i) % 2 == 0 ? -1.0 : 1.0
        let x = cx(Sprite.bodyCenterX + side * (24 + 12 * noise(cycle * 7 + i))), y = cy(16 + Int(noise(cycle * 3 + i * 11) * 18))
        // A four-pointed star with a soft halo, swelling and shrinking: 3 by 3 white at its height.
        let size = sin(k * .pi)
        let arm = Int((1 + size * 5).rounded())
        if size > 0.4 { c.ellipse(x, y, 3, 3, C(0xFFF6D0, 0.35 * size)) }
        for d in 1...arm {
            let fade = C(0xFFFFFF, max(0.35, 1 - Double(d) / Double(arm + 1)))
            c.px(x + d, y, fade); c.px(x - d, y, fade); c.px(x, y + d, fade); c.px(x, y - d, fade)
        }
        if size > 0.5 {
            for (dx, dy) in [(2, 2), (-2, 2), (2, -2), (-2, -2)] { c.px(x + dx, y + dy, C(0xFFF6C0, 0.8)) }
            c.rect(x - 1, y - 1, 3, 3, C(0xFFFFFF))
        }
        c.px(x, y, C(0xFFFFFF))
    }
    let from = 0.35
    guard e > from else { return }
    let k = (e - from) / (crawlFansLength - from)
    let a = min(1, k / 0.06, (1 - k) / 0.35)
    guard a > 0 else { return }
    let green = C(0x7AF08A, a), strip = C(0x103A1E, a * 0.85)
    // "+10" and "000 VIEWERS" with a comma drawn between (the letters have none).
    let w = 15 + crawlTextWidth("000 VIEWERS"), x = crawlPropWidth / 2 - w / 2, top = over - 7 - Int((k * 10).rounded())
    c.rect(x - 2, top - 2, w + 4, 10, strip)
    crawlText(c, x, top, "+10", green)
    c.px(x + 13, top + 4, green); c.px(x + 12, top + 5, green)
    crawlText(c, x + 15, top, "000 VIEWERS", green)
}

/// Donut's swat: her foreleg up, fawn with its cream paw, and slapped down across in front of her face in an arc of
/// quick white streaks, and a white smack star where it lands, on Mongo's snout.
private func crawlDrawSwat(_ c: PixelCanvas, k: Double, cx: (Double) -> Int, cy: (Int) -> Int) {
    let cream = C(0xEAD2A0), creamD = C(0xC8AE7C), fur = C(0xA88058)
    // Up over his snout, then down across it: her foreleg from the shoulder at (37, 31), the paw at its end, quick
    // white streaks behind it.
    let ang = (-70 + 120 * crawlSmooth(k / 0.7)) * .pi / 180
    func at(_ a: Double, _ r: Double) -> (Int, Int) { (cx(37 + cos(a) * r), cy(Int((31 + sin(a) * r).rounded()))) }
    for i in 1...3 where k > 0.15 && k < 0.8 {
        let p = at(ang - Double(i) * 0.28, 10)
        c.rect(p.0, p.1, 1, 2, C(0xFFFFFF, 0.7 / Double(i)))
    }
    for r in stride(from: 1.0, through: 8, by: 1) {
        let p = at(ang, r)
        c.rect(p.0, p.1, 2, 2, fur)
    }
    let paw = at(ang, 9.5)
    c.rect(paw.0 - 1, paw.1 - 1, 3, 3, cream); c.rect(paw.0 - 1, paw.1 + 1, 3, 1, creamD)
    if k > 0.55 && k < 0.95 {
        // The smack, just past her paw.
        let sx = cx(48), sy = cy(29), r = k < 0.75 ? 3 : 2
        for d in 1...r { for (dx, dy) in [(d, 0), (-d, 0), (0, d), (0, -d)] { c.px(sx + dx, sy + dy, C(0xFFFFFF)) } }
        for (dx, dy) in [(2, 2), (-2, 2), (2, -2), (-2, -2)] { c.px(sx + dx, sy + dy, C(0xFFE860)) }
    }
}

/// The bite on Donut's tail, `k` 0…1 through it, on the plume's edge at `row` of her art: a white and yellow smack star,
/// shrinking, drawn on her so it shows whichever of them the stage drew last.
private func crawlDrawBite(_ c: PixelCanvas, k: Double, row: Int, cx: (Double) -> Int, cy: (Int) -> Int) {
    let x = cx(8), y = cy(row)
    let r = k < 0.5 ? 3 : 2
    for d in 1...r { for (dx, dy) in [(d, 0), (-d, 0), (0, d), (0, -d)] { c.px(x + dx, y + dy, C(0xFFFFFF)) } }
    for (dx, dy) in [(2, 2), (-2, 2), (2, -2), (-2, -2)] { c.px(x + dx, y + dy, C(0xFFE860)) }
}

/// The System's toast: a small blue box over the idler's name tag, a bright blue title bar with "ACHIEVEMENT" in white,
/// under it the achievement, a line or two, in pale blue on deep navy, a light blue rim. It pops in (opening from its
/// middle row out), sits there and fades. No loot box: that's New Achievement!'s. It sits on `bottom` and rises a little,
/// but never over `ceiling`.
private func crawlDrawToast(_ c: PixelCanvas, e: Double, lines: [String], bottom: Int, ceiling: Int) {
    let k = e / crawlToastLength
    let a = min(1, (1 - k) / 0.15)
    guard a > 0 else { return }
    let title = "ACHIEVEMENT"
    let inner = max(crawlTextWidth(title), lines.map { crawlTextWidth($0) }.max() ?? 0)
    let w = inner + 4, h = 1 + 7 + 2 + lines.count * 6 - 1 + 2 + 1
    let x = crawlPropWidth / 2 - w / 2, top = max(ceiling, bottom - h - Int((crawlSmooth(k / 0.1) * 2).rounded()))
    let rim = C(0x8ACCFF, a), body = C(0x0C1E4A, a * 0.94), bar = C(0x2A6AE0, a), ink = C(0xFFFFFF, a), text = C(0xB8E2FF, a)
    // Opening from its middle row out: the empty box first, the words once it's open.
    let open = crawlSmooth(e / 0.18)
    if open < 1 {
        let hh = max(3, Int((Double(h) * open).rounded())), y0 = top + (h - hh) / 2
        c.rect(x, y0, w, hh, rim); c.rect(x + 1, y0 + 1, w - 2, hh - 2, body)
        return
    }
    c.rect(x, top, w, h, rim)
    c.rect(x + 1, top + 1, w - 2, h - 2, body)
    c.rect(x + 1, top + 1, w - 2, 7, bar)
    crawlText(c, x + w / 2 - crawlTextWidth(title) / 2, top + 2, title, ink)
    for (i, line) in lines.enumerated() {
        crawlText(c, x + w / 2 - crawlTextWidth(line) / 2, top + 10 + i * 6, line, text)
    }
}
