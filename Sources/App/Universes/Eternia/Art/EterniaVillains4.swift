import Foundation

// Villains: the rest of Skeleclawd's Evil Warriors, drawn the same way as EterniaVillains1.swift. Each is told apart
// by a colour pair and a head: Webstor's red bug eyes on navy blue and his black spider pack, Whiplash's long gator
// snout over an orange belly, Spikor's crown of orange spikes on blue-purple, Two Bad's two heads (one blue, one
// green) on one body, Faker's red pageboy on He-Clawd's pose in blue and orange, Panthor the only purple cat, and
// Stinkor's white blaze and bushy black-and-white tail.

let eterniaVillains4: [EterniaVillain: Persona] = [
    .webstor: Persona(name: "Webstor", weapon: .blaster, motion: .swing, shot: .web, muzzle: (45, 34), handGun: false,
                      headTop: 20, signature: 5.0, draw: drawWebstor),
    .whiplash: Persona(name: "Whiplash", weapon: .saber, bulk: 3, headTop: 21, signature: 3.0, draw: drawWhiplash),
    .spikor: Persona(name: "Spikor", weapon: .saber, headTop: 18, signature: 3.0, draw: drawSpikor),
    .twoBad: Persona(name: "Two Bad", weapon: .saber, bulk: 3, headTop: 16, signature: 3.6, draw: drawTwoBad),
    .faker: Persona(name: "Faker", weapon: .saber, headTop: 20, signature: 3.6, draw: drawFaker),
    .panthor: Persona(name: "Panthor", weapon: .saber, bulk: 3, headTop: 21, signature: 3.2, draw: drawPanthor),
    .stinkor: Persona(name: "Stinkor", headTop: 20, signature: 3.6, draw: drawStinkor),
]

private let v4None = C(0, 0)

/// 0…1 easing in over `a…b` and back out over `c…d` of a signature's run (0 before and after).
private func v4Ramp(_ s: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
    if s < a || s > d { return 0 }
    if s < b { return (s - a) / (b - a) }
    if s > c { return (d - s) / (d - c) }
    return 1
}

/// A solid line from `a` to `b`, `r` from its centre line, with no glow.
private func v4Line(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ col: Px, r: Double = 0.55) {
    c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: v4None, coreR: r, glowR: r + 0.1)
}

/// The smear a fast swing leaves along `trail`, from `a` to `b` pixels out of the fist `h`.
private func v4Smear(_ c: PixelCanvas, _ h: (x: Double, y: Double), _ trail: [Double], from a: Double, to b: Double) {
    for (i, t) in trail.enumerated() {
        let p0 = eterniaReach(h, t, a), p1 = eterniaReach(h, t, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.5, glowR: 1.6,
                   strength: 0.3 / Double(i + 1))
    }
}

/// A tail as a chain of `n` links `step` pixels long from `base`, setting off at `dir` degrees and turning `bend`
/// more at each link (plus `curl` more at each link after that), never below the floor. Its points, base first.
private func v4Tail(_ base: (x: Double, y: Double), dir: Double, bend: Double, curl: Double = 0, n: Int, step: Double,
                    floor: Double) -> [(x: Double, y: Double)] {
    var pts = [base]
    var d = dir
    for k in 0..<n {
        d += bend + curl * Double(k)
        var q = eterniaReach(pts[pts.count - 1], d, step)
        q.y = min(q.y, floor)
        pts.append(q)
    }
    return pts
}

// MARK: - Webstor

/// Webstor: Skeleclawd's climber and spy. Navy blue skin, a bug's head with a domed, ridged crown, two big red
/// compound eyes and two little ones over them, and a pair of pale fangs; orange armour with a black spider on its
/// front side, a
/// black belt and briefs, orange boots. On his back the black spider pack, its orange legs bent round it and a spool of
/// line on top; on his front arm a grapple gun that shoots a sticky line (a web). He swings from place to place on
/// it. Signature: he springs up and hangs upside down on a long line from the top of the frame, his head just off the
/// floor, bobbing and slowly turning round, then drops back down onto his feet.
private func drawWebstor(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let hang = v4Ramp(s, 0.06, 0.18, 0.82, 0.94)
    guard hang > 0 else { webstorArt(c, p, swinging: p.walking && !seatedPose); return }
    if hang < 0.5 {
        // Springing up off the floor (or dropping back to it): himself, the right way up, a little higher each frame.
        c.oy -= Int((hang * 10).rounded())
        webstorArt(c, p, swinging: false)
        return
    }
    // Hanging: drawn on a canvas of his own and turned over top to bottom, his feet up by the line, and now and then
    // turned round on it.
    var q = p
    q.signature = nil; q.melee = nil; q.trail = []; q.step = -1; q.breathe = 0
    let art = PixelCanvas(Sprite.width, Sprite.height)
    webstorArt(art, q, swinging: false)
    let flipped = art.rotated(180, about: (36, 26), into: Sprite.width, Sprite.height, at: (36, 26))
    flipped.flipHorizontally()
    if s > 0.38 && s < 0.62 { flipped.mirror(aboutX: 28) }
    let bob = Int((sin(p.t * 4) * 1.2).rounded())
    let dy = 9 - Int(((1 - hang) * 14).rounded()) + bob
    // The line, from his belt up between his legs to the top of the frame, a long bright thread with a glint on it,
    // fading out only in the last few rows so it never ends in a hard edge.
    let beltY = Double(51 - 36 + dy)
    var y = beltY
    while y > 2 {
        let ny = max(2, y - 2)
        let fade = min(1, (ny - 2) / 4)
        v4Line(c, (27.5, y), (27.5, ny), C(0xF4F6FC, 0.95 * fade), r: 0.6)
        y = ny
    }
    let glint = beltY - 4 - frac(p.t * 0.7) * (beltY - 10)
    c.px(27, Int(glint), C(0xFFFFFF))
    c.paste(flipped, x: 0, y: dy)
}

/// Webstor himself, the right way up. `swinging`: on his line between places, legs trailing, his front hand up on it.
private func webstorArt(_ c: PixelCanvas, _ p: Pose, swinging: Bool) {
    let skin = C(0x2E58B0), skinD = C(0x1E3C80), skinL = C(0x5682D8)
    let orange = C(0xF0862A), orangeD = C(0xB85A16), orangeL = C(0xFFB45A)
    let black = C(0x1E1C24), blackL = C(0x4A4856)
    let red = C(0xE8302A), redL = C(0xFF9A7A), redD = C(0x8A1418)
    let line = C(0xEEF0F6), lineD = C(0xA8ACB8)

    if swinging {
        // Legs trailing back and down as he swings, orange boots on the ends.
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let kick = (i + max(0, p.step)) % 2
            for r in 0..<7 { c.rect(lx - r / 2 - kick, 36 + r, 2, 1, r >= 5 ? orange : skin) }
        }
    } else {
        drawLegs(c, Look(leg: skin), step: p.step)
        drawBoots(c, orange, step: p.step, rows: 3)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
                c.rect(lx, bottom - 2, 2, 1, orangeL); c.px(lx + 1, bottom, orangeD)
            }
        }
    }
    c.oy += p.breathe

    // The spider pack on his back: a black case lit down its near edge, an orange rim top and bottom, three bent
    // orange legs out of its side, the spool of line on top with a grapple hook clipped to it.
    c.rect(11, 24, 7, 12, black); c.rect(11, 24, 1, 12, blackL)
    c.rect(11, 24, 7, 1, orange); c.rect(11, 35, 7, 1, orangeD)
    for y in [26, 29, 32] {
        c.rect(8, y, 3, 1, orange); c.px(8, y, orangeL)
        c.px(7, y + 1, orange); c.px(7, y + 2, orangeD)
    }
    c.rect(12, 22, 5, 2, line); c.rect(12, 22, 5, 1, C(0xFFFFFF)); c.rect(14, 22, 1, 2, lineD)
    c.pattern(16, 19, ["SS.", "..S", ".SS"], ["S": C(0xB8BCC8)])

    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 27, 1, 5, skinL)

    // The bug's head: a domed crown over his brow, lit on the left, ridged across in dark bands.
    c.rect(23, 20, 10, 1, skin); c.rect(21, 21, 14, 1, skin); c.rect(19, 22, 18, 4, skin)
    c.rect(24, 20, 3, 1, skinL); c.rect(21, 21, 3, 1, skinL); c.rect(19, 22, 1, 3, skinL); c.rect(36, 22, 1, 4, skinD)
    c.rect(22, 22, 12, 1, skinD); c.rect(20, 24, 16, 1, skinD); c.rect(27, 20, 2, 2, skinD)
    // Two little eyes on his brow and the two big compound ones under them, lit at the top; two pale fangs.
    c.rect(24, 26, 2, 1, red); c.rect(30, 26, 2, 1, red)
    let eyeRows = [
        ".EEE.",
        "ELLEE",
        "EEEdE",
        "EEddE",
        ".ddd.",
    ]
    for ex in [20, 31] { c.pattern(ex, 27, eyeRows, ["E": red, "L": redL, "d": redD]) }
    let fang = C(0xE4E0D2)
    c.px(25, 31, fang); c.px(26, 32, fang); c.px(30, 31, fang); c.px(29, 32, fang)

    // The armour: orange across his chest, lit along the top, a black spider on it, set off to his front side (a dark
    // bar centred under those red eyes read as a mouth): head up, its round body and four legs a side bent out.
    // The black belt and briefs.
    c.rect(18, 33, 20, 4, orange); c.rect(18, 33, 20, 1, orangeL); c.rect(36, 33, 2, 4, orangeD)
    c.rect(18, 37, 20, 1, black); c.rect(23, 37, 2, 1, orange)
    c.pattern(28, 33, [
        "K.....K",
        ".K.K.K.",
        "KKKKKKK",
        "..KKK..",
        "K.KKK.K",
    ], ["K": black])
    c.px(31, 33, black); c.px(31, 35, C(0x6A2A1E))
    c.rect(15, 33, 3, 1, orange)

    if swinging {
        // His front hand up on the line.
        c.glowLine(39, 32, 41, 23, core: skin, glow: v4None, coreR: 1.1, glowR: 1.2)
        c.rect(40, 21, 3, 3, skin); c.px(42, 21, skinD)
        c.rect(38, 30, 3, 2, black); c.px(39, 30, orange)
        return
    }
    // The grapple gun on his front arm: a black cuff with an orange band, a short barrel and the line's tip in it.
    c.oy += p.gunY
    c.rect(38, 33, 4, 3, black); c.rect(38, 33, 4, 1, blackL); c.rect(39, 33, 1, 3, orange)
    c.rect(42, 33, 3, 2, C(0x5A5E6A)); c.rect(42, 33, 3, 1, C(0x8A8E9C))
    c.px(45, 33, line); c.px(45, 34, lineD)
    c.oy -= p.gunY
}

// MARK: - Whiplash

/// Whiplash: the alligator man who knocks foes flat with his tail. Olive-brown scales all over, a long gator snout
/// out in front with a row of white teeth along its jaw, his yellow slit eyes up on bumps on top of his head; a bright
/// orange belly in bands, a dark leather strap across it studded in steel, dark boots. A thick ridged tail lies along
/// the floor behind him. He fights with a long spear, held upright at his side when he isn't. Signature: he swishes
/// his tail up and down behind him, three times.
private func drawWhiplash(_ c: PixelCanvas, _ p: Pose) {
    let sc = C(0x7C7236), scD = C(0x56501E), scL = C(0xA69E56)
    let belly = C(0xF08C2C), bellyD = C(0xC4661A), bellyL = C(0xFFC478)
    let strap = C(0x3A2616), stud = C(0xC8CCD4)
    let eye = C(0xF4D030), mouth = C(0x3A1A12)
    let s = p.signature ?? -1
    let swish = v4Ramp(s, 0.06, 0.14, 0.86, 0.94)
    let wag = swish * sin(max(0, s - 0.06) / 0.88 * 3 * 2 * .pi)

    // The tail, behind him: thick at his rump, tapering to the tip, a ridge of dark scutes along its top.
    let tail = v4Tail((17.5, 35), dir: 135, bend: 5 - wag * 11, n: 6, step: 2.5, floor: 42.5 - Double(c.oy))
    let radii = [2.3, 2.0, 1.7, 1.4, 1.1, 0.8, 0.6]
    for k in 1..<tail.count {
        v4Line(c, tail[k - 1], tail[k], sc, r: radii[k])
        v4Line(c, (tail[k - 1].x, tail[k - 1].y + 0.6 * radii[k]), (tail[k].x, tail[k].y + 0.6 * radii[k]), scD,
               r: radii[k] * 0.35)
    }
    for k in 1..<tail.count - 1 {
        c.px(Int(tail[k].x.rounded(.down)), Int((tail[k].y - radii[k] - 0.4).rounded(.down)), scD)
    }

    drawLegs(c, Look(leg: sc), step: p.step)
    drawBoots(c, strap, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 4, scD); c.px(lx + 1, bottom - 6, scL)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: sc, shade: scD, arm: sc, eye: nil))
    for y in stride(from: 27, through: 35, by: 2) { c.px(18, y, scL); c.px(19, y + 1, scD) }

    // The head: a flat scaly crown, and his eyes up on bumps on top of it, yellow with a black slit.
    c.rect(22, 23, 12, 1, sc); c.rect(20, 24, 16, 1, sc); c.rect(19, 25, 18, 1, sc)
    c.rect(22, 23, 3, 1, scL); c.rect(20, 24, 2, 1, scL); c.rect(35, 24, 1, 2, scD)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 25, scD); c.px(x + 1, 26, scD) }
    for bx in [21, 30] {
        c.pattern(bx, 20, [
            ".SSS.",
            "SYYKS",
            "SYYKS",
            "dSSSd",
        ], ["S": sc, "Y": eye, "K": ink, "d": scD])
        c.px(bx + 1, 20, scL)
    }

    // The snout: long and flat out in front of him, lit along the top with a ridge of dark scutes, the nostril bump
    // at its tip, the jaw line with a row of white teeth hanging over it, a pale chin under.
    c.rect(27, 27, 17, 1, sc); c.rect(26, 28, 19, 2, sc); c.rect(43, 26, 3, 2, sc)
    c.rect(28, 27, 15, 1, scL); c.px(44, 26, scL); c.px(45, 27, ink)
    for x in stride(from: 30, through: 41, by: 3) { c.px(x, 27, scD) }
    c.rect(26, 30, 20, 1, mouth)
    for x in stride(from: 30, through: 44, by: 2) { c.px(x, 30, white) }
    c.rect(27, 31, 17, 1, bellyL); c.rect(30, 32, 12, 1, bellyD)
    for x in stride(from: 31, through: 42, by: 2) { c.px(x, 31, white) }
    c.rect(36, 32, 2, 1, sc)

    // The orange belly in bands, the studded strap across it, the belt.
    for y in 33...37 { c.rect(21, y, 14, 1, y % 2 == 1 ? belly : bellyD) }
    c.rect(21, 33, 1, 5, bellyL)
    v4Line(c, (19.5, 33.5), (35.5, 36.5), strap, r: 0.7)
    for x in [23, 27, 31] { c.px(x, 34 + (x - 21) / 6, stud) }
    c.rect(18, 37, 20, 1, strap)

    // The spear: held upright at his side, or swung from his fist; a dark shaft, a long steel head, a red tassel.
    let wood = C(0x6A4428), woodL = C(0x8E6440), steel = C(0xC8CCD8), tassel = C(0xC8302A)
    if let a = p.melee {
        let h = eterniaHand
        v4Smear(c, h, p.trail, from: 3, to: 17)
        eterniaBar(c, h, a, from: -8, to: 11, wood, r: 0.8)
        eterniaBar(c, h, a, from: 11, to: 14.5, steel, r: 1.3)
        eterniaBar(c, h, a, from: 14, to: 17, steel, r: 0.7)
        eterniaBar(c, h, a, from: 11.5, to: 16.5, white, r: 0.35)
        let t0 = eterniaReach(h, a, 10.5)
        c.rect(Int(t0.x.rounded(.down)), Int(t0.y.rounded(.down)), 2, 2, tassel)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, sc); c.px(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, scL)
    } else {
        let top = 14
        c.rect(41, top, 2, 43 - top - (seatedPose ? 4 : 0), wood); c.rect(41, top, 1, 20, woodL)
        c.pattern(39, top - 7, [
            "..S..",
            ".SWS.",
            ".SWS.",
            "SSWSS",
            ".SWS.",
            "..S..",
            ".RRR.",
        ], ["S": steel, "W": white, "R": tassel])
        c.rect(40, top, 1, 3, tassel); c.px(39, top + 2, tassel)
        c.rect(40, 33, 3, 3, sc); c.px(40, 33, scL)   // his fist round the shaft
    }
}

// MARK: - Spikor

/// Spikor: Skeleclawd's spiked warrior. Blue-purple skin bristling with orange spikes: a crown of them round his
/// head, more down his back, on his back arm and his knees; red eyes under a heavy brow, a grim mouth with two fangs
/// poking up out of it, a gunmetal chest plate studded in orange, black boots. His front arm ends in a steel
/// trident instead of a hand. Signature: every spike on him stands up at once, twice as long, and quivers, then
/// they settle back down.
private func drawSpikor(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5A4CB4), skinD = C(0x3C2F86), skinL = C(0x7E70DA)
    let spike = C(0xF08A2A), spikeL = C(0xFFD070), spikeD = C(0xB85A16)
    let plate = C(0x3A3A46), plateL = C(0x62626E), plateD = C(0x24242C)
    let s = p.signature ?? -1
    let up = v4Ramp(s, 0.06, 0.16, 0.8, 0.94)
    let quiver = up > 0.9 ? (Int(p.t * 16) % 2 == 0 ? 0.6 : -0.6) : 0

    /// One spike out of `b` at `angle`: a broad orange base tapering to a pale point, longer as they stand up.
    func spikeAt(_ b: (x: Double, y: Double), _ angle: Double, _ len: Double) {
        let l = len * (1 + 0.9 * up)
        let a = angle + quiver * 6
        let mid = eterniaReach(b, a, l * 0.55), tip = eterniaReach(b, a, l)
        v4Line(c, b, mid, spike, r: 0.95)
        v4Line(c, mid, tip, spike, r: 0.5)
        c.px(Int(tip.x.rounded(.down)), Int(tip.y.rounded(.down)), spikeL)
        let sh = eterniaReach(b, a + 90, 0.8)
        c.px(Int(sh.x.rounded(.down)), Int(sh.y.rounded(.down)), spikeD)
    }

    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, plateD, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 1, plateL)
            if i == 0 { spikeAt((19, Double(bottom - 4)), 190, 2.5) }
            if i == 3 { spikeAt((37, Double(bottom - 4)), -10, 2.5) }
        }
    }
    c.oy += p.breathe

    // Spikes down his back and on his back arm, behind the body.
    spikeAt((18.5, 29), 195, 3)
    spikeAt((18.5, 33), 180, 2.5)
    spikeAt((15.5, 33.5), 225, 2.5)
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 27, 1, 5, skinL)

    // The crown of spikes, round the top of his head, and the head under it, lit on the left.
    for a in stride(from: -165.0, through: -15, by: 25) {
        let r = a * .pi / 180
        spikeAt((27.5 + 8.6 * cos(r), 27.6 + 6.2 * sin(r)), a, a > -100 && a < -80 ? 4 : 3)
    }
    c.rect(23, 22, 10, 1, skin); c.rect(21, 23, 14, 1, skin); c.rect(19, 24, 18, 2, skin)
    c.rect(23, 22, 3, 1, skinL); c.rect(21, 23, 2, 1, skinL); c.rect(19, 24, 1, 2, skinL); c.rect(36, 24, 1, 2, skinD)
    // The heavy brow, his red eyes under it, and the grim mouth with two fangs poking up.
    c.rect(21, 27, 5, 1, skinD); c.rect(30, 27, 5, 1, skinD); c.px(25, 28, skinD); c.px(30, 28, skinD)
    for ex in [22, 32] { c.rect(ex, 29, 2, 2, C(0xE8302A)); c.px(ex, 29, C(0xFFA080)); c.rect(ex, 31, 2, 1, skinD) }
    c.rect(24, 32, 8, 1, C(0x1E1440)); c.px(25, 31, white); c.px(30, 31, white)

    // The gunmetal chest plate, lit along the top, orange studs along it; the belt.
    c.rect(19, 33, 18, 4, plate); c.rect(19, 33, 18, 1, plateL); c.rect(36, 33, 1, 4, plateD)
    for x in [21, 25, 30, 34] { c.px(x, 35, spike) }
    c.rect(18, 37, 20, 1, plateD); c.rect(27, 37, 2, 1, spike)

    // The trident in place of his front hand: a gunmetal cuff with an orange ring, a shaft, a crossbar and three
    // barbed steel prongs. Upright when he isn't fighting.
    let h = eterniaHand
    let a = p.melee ?? (-78 + up * 4)
    let steel = C(0xC8CCD8), steelD = C(0x7C808E)
    if p.melee != nil { v4Smear(c, h, p.trail, from: 4, to: 16) }
    eterniaBar(c, h, a, from: 0, to: 9, steelD, r: 0.8)
    let j = eterniaReach(h, a, 9)
    let l = eterniaReach(j, a + 90, 2.8), r = eterniaReach(j, a - 90, 2.8)
    v4Line(c, l, r, steelD, r: 0.6)
    eterniaBar(c, j, a, from: 0, to: 6.5, steel, r: 0.6)
    for side in [l, r] {
        eterniaBar(c, side, a, from: 0, to: 4.5, steel, r: 0.55)
        let tip = eterniaReach(side, a, 4.5)
        c.px(Int(tip.x.rounded(.down)), Int(tip.y.rounded(.down)), white)
    }
    let top = eterniaReach(j, a, 6.5)
    c.px(Int(top.x.rounded(.down)), Int(top.y.rounded(.down)), white)
    c.rect(38, 33, 4, 3, plate); c.rect(38, 33, 4, 1, plateL); c.rect(40, 33, 1, 3, spike)
}

// MARK: - Two Bad

/// Two Bad: two villains on one body, who never agree on anything. A broad body split down the middle, its left half
/// blue and its right half green to match the heads above it: a blue one in a black skullcap and a green one with a
/// shock of dark hair under a red headband. A red harness crosses his chest to a gold disc, a red belt with a gold
/// buckle, red boots. He fights with his big fists. Signature: the two heads turn right round in profile, nose to
/// nose, and argue, each shouting in turn with its mouth wide, angry sparks flying up between them.
private func drawTwoBad(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x4A7EDC), blueD = C(0x2E5AAE), blueL = C(0x7CA6F2)
    let green = C(0x5AAE3E), greenD = C(0x3A7E26), greenL = C(0x88D262)
    let red = C(0x9A2632), redL = C(0xC84452)
    let gold = C(0xE0B040), goldL = C(0xFFE08A)
    let s = p.signature ?? -1
    let argue = v4Ramp(s, 0.05, 0.14, 0.86, 0.95)
    let turned = argue > 0.4
    let talker = Int(max(0, s) * 12) % 2   // 0: the blue head has the floor, 1: the green one

    // The legs: blue on his left, green on his right, red boots.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, lx < 28 ? blue : green) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            c.rect(lx, 36, 2, lifted ? 7 : 8, lx < 28 ? blue : green)
        }
        drawBoots(c, red, step: p.step, rows: 3)
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, redL) }
    }
    c.oy += p.breathe

    // The broad body, a blue half and a green half, lit on the left and shaded on the right and underneath; the
    // back fist blue, the front one green.
    c.rect(15, 26, 13, 12, blue); c.rect(28, 26, 12, 12, green)
    c.rect(15, 26, 1, 12, blueL); c.rect(39, 26, 1, 12, greenD)
    c.rect(15, 37, 13, 1, blueD); c.rect(28, 37, 12, 1, greenD)
    c.rect(16, 26, 11, 1, blueL); c.rect(28, 26, 11, 1, greenL)
    c.rect(12, 33, 3, 3, blue); c.px(12, 33, blueL); c.px(14, 35, blueD)

    // The harness: two red straps from his shoulders down to a gold disc on his chest, the red belt and buckle.
    v4Line(c, (17.5, 27.5), (27.5, 34), red, r: 0.75)
    v4Line(c, (38, 27.5), (28.5, 34), red, r: 0.75)
    c.rect(26, 33, 4, 3, gold); c.rect(26, 33, 4, 1, goldL); c.px(29, 35, C(0x9A7420))
    c.rect(15, 36, 25, 1, red); c.rect(15, 36, 4, 1, redL); c.rect(27, 36, 2, 1, gold)

    // The two heads: looking out front, or turned right round in profile, nose to nose, the one shouting thrust
    // forward and up a pixel.
    let shoutBob = turned && Int(p.t * 10) % 2 == 0 ? 1 : 0
    twoBadHead(c, x: 16, y: turned && talker == 0 ? -shoutBob : 0, skin: blue, dark: blueD, lit: blueL,
               facing: turned ? .right : .front, open: turned && talker == 0 && shoutBob == 1, hat: .cap)
    twoBadHead(c, x: 29, y: turned && talker == 1 ? -shoutBob : 0, skin: green, dark: greenD, lit: greenL,
               facing: turned ? .left : .front, open: turned && talker == 1 && shoutBob == 1, hat: .band(red, redL))
    if turned {
        // Angry sparks flying up between them, bright on a hot orange glow, and a cross little vein on the listener.
        let on = Int(p.t * 12) % 2 == 0
        let zig = C(0xFFF6C0)
        c.glowLine(27.5, 13, 27.5, 13, core: C(0xFFF0B0, 0), glow: C(0xFF7A2A), coreR: 0.2, glowR: 4.5, strength: 0.6)
        let burst = on ? ["Z.....Z", ".Z...Z.", "..Z.Z..", "...Z...", "..Z.Z..", ".Z...Z.", "Z.....Z"]
                       : ["...Z...", "...Z...", "...Z...", "ZZZ.ZZZ", "...Z...", "...Z...", "...Z..."]
        c.pattern(25, 10, burst, ["Z": zig])
        let vx = talker == 0 ? 37 : 18
        c.pattern(vx - 1, 15, ["R.R", ".R.", "R.R"], ["R": C(0xFF3A3A)])
    }

    // The front fist: at his side, or swung on his arm.
    let h = eterniaHand
    if let a = p.melee {
        v4Smear(c, h, p.trail, from: 2, to: 7)
        eterniaBar(c, h, a, from: -1, to: 4, green, r: 1.4)
        let f = eterniaReach(h, a, 5)
        c.rect(Int(f.x.rounded()) - 2, Int(f.y.rounded()) - 2, 4, 4, green)
        c.px(Int(f.x.rounded()) - 2, Int(f.y.rounded()) - 2, greenL); c.rect(Int(f.x.rounded()) - 2, Int(f.y.rounded()) + 1, 4, 1, greenD)
    } else {
        c.rect(40, 33, 4, 4, green); c.rect(40, 33, 4, 1, greenL); c.rect(40, 36, 4, 1, greenD)
    }
}

private enum TwoBadHat { case cap, band(Px, Px) }
private enum TwoBadFacing { case front, left, right }

/// One of Two Bad's heads, 11 wide, its left edge at `x`, from row 17 down onto his shoulders (`y` lifts it): two
/// eyes and a scowl looking out front, or (`facing` left or right) turned in profile to the other head, one eye at
/// its near side under a hard brow, the nose jutting out past its edge, an ear on the back of it and the mouth at the
/// front, shouting (`open`) wide with its teeth showing. And its own headgear.
private func twoBadHead(_ c: PixelCanvas, x: Int, y: Int, skin: Px, dark: Px, lit: Px, facing: TwoBadFacing,
                        open: Bool, hat: TwoBadHat) {
    c.oy += y
    defer { c.oy -= y }
    c.pattern(x, 18, [
        "..HHHHHHH..",
        ".HHHHHHHHH.",
        "HHHHHHHHHHH",
        "HHHHHHHHHHH",
        "HHHHHHHHHHH",
        "HHHHHHHHHHH",
        "HHHHHHHHHHH",
        ".HHHHHHHHH.",
        "..HHHHHHH..",
    ], ["H": skin])
    c.rect(x, 20, 1, 5, lit); c.rect(x + 10, 20, 1, 5, dark); c.rect(x + 2, 26, 7, 1, dark)
    let maw = C(0x3A0E14)
    switch facing {
    case .front:
        // The eyes, under a brow slanting down to the middle, and a grim mouth.
        c.rect(x + 4, 22, 1, 2, ink); c.rect(x + 7, 22, 1, 2, ink)
        c.rect(x + 3, 21, 2, 1, dark); c.rect(x + 7, 21, 2, 1, dark)
        c.rect(x + 4, 25, 4, 1, dark)
    case .left, .right:
        // In profile: everything drawn for facing right, mirrored across the head for facing left.
        let r = facing == .right
        func fx(_ dx: Int, _ w: Int = 1) -> Int { r ? x + dx : x + 10 - dx - (w - 1) }
        c.rect(fx(11), 21, 1, 3, skin); c.px(fx(11), 23, dark)            // the nose, jutting out
        c.rect(fx(7), 22, 2, 2, ink)                                      // the near eye
        c.rect(fx(6, 4), 21, 4, 1, dark); c.px(fx(9), 20, dark)           // the hard brow, down at the front
        c.rect(fx(2, 2), 22, 2, 3, dark); c.px(fx(2), 22, lit)            // the ear, on the back of his head
        if open {
            c.rect(fx(6, 5), 24, 5, 3, maw); c.rect(fx(6, 5), 24, 5, 1, white); c.px(fx(9), 26, white)
        } else {
            c.rect(fx(7, 4), 25, 4, 1, dark)
        }
    }
    switch hat {
    case .cap:
        // A black skullcap over the crown, lit on the left, a little crest along its top.
        let capC = C(0x22202A), capL = C(0x4E4C5C)
        c.rect(x + 2, 17, 7, 1, capC); c.rect(x + 1, 18, 9, 1, capC); c.rect(x, 19, 11, 2, capC)
        c.rect(x + 2, 17, 2, 1, capL); c.rect(x + 1, 18, 1, 2, capL)
        c.rect(x + 4, 16, 3, 1, capC); c.px(x + 4, 16, capL)
    case .band(let band, let bandL):
        // A shock of dark hair in strands over a red headband, its knot's ends flying out behind.
        let hair = C(0x3A2616), hairL = C(0x6A4A2A)
        c.pattern(x, 15, [
            "..h.H.H.H..",
            ".HHHHlHHHH.",
            "HHlHHHHHlHH",
            "HHHHHHHHHHH",
        ], ["H": hair, "h": hairL, "l": hairL])
        c.rect(x, 19, 11, 2, band); c.rect(x, 19, 11, 1, bandL)
        c.px(x + 11, 20, band); c.px(x + 12, 21, band)
    }
}

// MARK: - Faker

/// Faker: Skeleclawd's robot copy of He-Clawd, and not a very good one. The same pageboy (cropped short, so his blue
/// face shows), harness and stance in the wrong colours: blue skin, the pageboy red, an orange chest plate with a little control panel of lights where the
/// iron cross should be, the same brown fur briefs and boots and gold-studded belt; his eyes glow yellow. He fights
/// with a copy of the Power Sword with an orange guard. Signature: he strikes He-Clawd's pose, sword overhead, but no
/// lightning comes; sparks fizz out of his ear instead, and a wisp of smoke, before he lowers it.
private func drawFaker(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5A8EE0), skinD = C(0x3E6CB8), skinL = C(0x86B0F0)
    let hair = C(0xD8442A), hairD = C(0x9A2A1A), hairL = C(0xF8805A)
    let orange = C(0xE8822A), orangeD = C(0xA8561A), orangeL = C(0xFFB868)
    let fur = C(0x7A4E2A), furD = C(0x54341A), furL = C(0x9A6A3E), gold = C(0xE0B040), goldD = C(0x9A7420)
    let bracer = C(0x6A4428), bracerL = C(0x8A5E38)
    let glowEye = C(0xFFF4A0)
    let s = p.signature ?? -1
    let up = s < 0 ? 0 : s < 0.2 ? s / 0.2 : s > 0.85 ? max(0, (1 - s) / 0.15) : 1
    let raise = Int((up * 9).rounded())
    let fizz = s > 0.28 && s < 0.8 ? (s - 0.28) / 0.52 : -1

    // Bare blue legs, and furry boots: brown, a lit cuff of fur round the top.
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 4, fur)
            c.rect(lx, bottom - 3, 2, 1, furL); c.px(lx + 1, bottom - 1, furD)
        }
    }

    c.oy += p.breathe
    // The sword on his back while it's put away: its hilt over his far shoulder.
    if p.melee == nil && raise == 0 {
        c.rect(14, 24, 2, 6, C(0x4A2A5A)); c.px(14, 24, C(0x6A4A7A))
        c.rect(12, 29, 6, 1, orange); c.px(12, 29, orangeL)
        c.rect(14, 22, 2, 2, gold)
    }
    drawBody(c, Look(body: skin, shade: skinD, leg: skin, arm: skin, eye: nil), armRight: raise)
    c.rect(18, 27, 1, 5, skinL)
    c.rect(15, 34, 3, 1, bracer); c.px(15, 34, bracerL)
    c.rect(38, 34 - raise, 3, 1, bracer); c.px(38, 34 - raise, bracerL)

    // His blue brow, lit, where He-Clawd's fringe would hang; his eyes, glowing yellow, a glow round them.
    c.rect(20, 26, 16, 1, skinL); c.rect(20, 27, 16, 1, skin)
    for ex in [22, 32] {
        c.glowLine(Double(ex) + 1, 30, Double(ex) + 1, 30, core: C(0xFFF4A0, 0), glow: C(0xFFD040), coreR: 0.2,
                   glowR: 3.4, strength: 0.75)
        c.rect(ex, 29, 3, 2, glowEye); c.px(ex, 29, white); c.px(ex + 1, 29, white)
        c.rect(ex, 28, 3, 1, skinD)   // a straight, mechanical brow
    }
    c.px(27, 31, skinD); c.px(28, 31, skinD)

    // The chest plate: orange where He-Clawd's is silver, lit along the top, and a dark control panel in the middle
    // with three little lights where the iron cross should be.
    c.rect(19, 33, 18, 3, orange); c.rect(19, 33, 18, 1, orangeL); c.rect(36, 33, 1, 3, orangeD); c.rect(19, 35, 18, 1, orangeD)
    c.rect(25, 33, 6, 3, C(0x1E1E26)); c.rect(25, 33, 6, 1, C(0x3A3A46))
    let blink = Int(p.t * 3) % 3
    c.px(26, 34, blink == 0 ? C(0xFF5A4A) : C(0x8A2A2A))
    c.px(28, 34, blink == 1 ? C(0x7AF07A) : C(0x2A6A2A))
    c.px(29, 34, blink == 2 ? C(0xFFE04A) : C(0x8A7A2A))
    c.px(20, 34, orangeD); c.px(34, 34, orangeD)
    c.rect(18, 36, 20, 1, C(0x4A2E18))
    for x in stride(from: 19, through: 35, by: 4) { c.px(x, 36, gold); c.px(x + 1, 36, goldD) }
    eterniaFur(c, 18, 37, 20, 1, base: fur, dark: furD, light: furL)

    // The pageboy, He-Clawd's cut in red, and a poor copy of it: cropped short, the fringe high on his brow and the
    // sides thin, so his blue face and glowing eyes show where He-Clawd's hair hangs.
    c.pattern(16, 20, [
        ".....HHHHHlHHHHHH......",
        "...HHHlHHHHHlHHHHHH....",
        "..HHhHHHHhHHHHHhHHHHH..",
        ".HHHhHHlHhHHHHHhHHHhHH.",
        "HHHhHH.hHH.hH.hHH.hHhHH",
        "HHh...................H",
        "HHh...................h",
        ".h....................h",
    ], ["H": hair, "h": hairD, "l": hairL])

    if fizz >= 0 {
        // Sparks fizzing out of his ear (under the hair, on his far side), and a wisp of grey smoke rising off it.
        let seed = Int(p.t * 18)
        for k in 0..<4 where noise(seed + k * 7) > 0.35 {
            let a = -100 - noise(seed + k) * 80
            let u = eterniaReach((16, 29), a, 1.5), v = eterniaReach((16, 29), a, 3 + noise(seed + k * 3) * 3)
            c.glowLine(u.x, u.y, v.x, v.y, core: C(0xFFFBE0), glow: C(0xFFB030), coreR: 0.3, glowR: 1.1, strength: 0.9)
        }
        for k in 0..<3 {
            let f = frac(p.t * 0.9 + Double(k) / 3)
            let x = 14 - f * 4 + sin(f * 6 + Double(k)) * 1.2, y = 26 - f * 12
            c.glowLine(x, y, x, y, core: C(0xB4B4BC, 0.5 * (1 - f)), glow: C(0x8A8A94, 0.3 * (1 - f)), coreR: 0.8 + f,
                       glowR: 1.6 + f * 1.5)
        }
    }

    if raise > 0 {
        // The copy of the Power Sword held up overhead, straight up from his raised fist, and nothing comes.
        let h = (x: eterniaHand.x - 1.5, y: eterniaHand.y - Double(raise))
        eterniaSword(c, p, angle: -90, at: h, grip: C(0x4A2A5A), guardCol: orange, steel: C(0xC8CCD8),
                     edge: white, length: 14, pommel: gold)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, skin)
        return
    }
    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: C(0x4A2A5A), guardCol: orange, steel: C(0xC8CCD8), edge: white,
                     length: 14, pommel: gold)
        let h = eterniaHand
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, skin)   // his blue fist round the grip
    }
}

// MARK: - Panthor

/// Panthor: Skeleclawd's great purple panther, the only purple cat on Eternia. Clawd's block in sleek dark purple
/// fur, lit along its top, a panther's face on its front with slanted yellow eyes, a paler muzzle and a dark nose,
/// tall pointed ears; a haunch behind and a long tail; a gold saddle with a high cantle on his back over a red cloth,
/// a gold strap round his middle. No helmet. He fights with his paws, nails out. Signature: he snarls, his ears going flat
/// and his fangs out, his tail swishing hard behind him.
private func drawPanthor(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x5E3092), furD = C(0x3E1C68), furL = C(0x8A5AC4)
    let muz = C(0x8E6CBC), muzD = C(0x6A4A96), nose = C(0x24142E)
    let gold = C(0xE8B838), goldD = C(0xA87E1E), goldL = C(0xFFE07A)
    let cloth = C(0xA02A2A), clothL = C(0xC8443A)
    let eye = C(0xF4E040)
    let s = p.signature ?? -1
    let snarl = v4Ramp(s, 0.06, 0.16, 0.84, 0.94)
    let wag = snarl * sin(max(0, s - 0.06) / 0.88 * 4 * 2 * .pi)
    let top = 25

    // The legs: Clawd's four, in purple fur, paler paws.
    if seatedPose {
        drawLegs(c, Look(leg: fur), step: p.step)
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, muz) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            let bottom = lifted ? 42 : 43
            c.rect(lx, 36, 2, bottom - 35, fur)
            c.px(lx + 1, 36, furD); c.px(lx, 38, furL)
            c.rect(lx, bottom - 1, 2, 2, muz); c.px(lx + 1, bottom, muzD)
        }
    }
    c.oy += p.breathe

    // The tail: long and low from his haunch, curling up at the tip, swishing hard while he snarls.
    let tail = v4Tail((12.5, 30), dir: 105, bend: 10 - wag * 16, curl: 4, n: 5, step: 2.3, floor: 42.5 - Double(c.oy))
    for k in 1..<tail.count {
        v4Line(c, tail[k - 1], tail[k], fur, r: k < 3 ? 1.7 : k < 5 ? 1.4 : 1.1)
        v4Line(c, (tail[k - 1].x, tail[k - 1].y - 0.8), (tail[k].x, tail[k].y - 0.8), furL, r: 0.4)
    }

    // The haunch behind the block, rounded on top.
    c.rect(12, top + 3, 6, 38 - top - 3, fur); c.rect(13, top + 2, 5, 1, fur)
    c.rect(12, 37, 6, 1, furD); c.rect(13, top + 2, 4, 1, furL); c.rect(12, top + 3, 1, 9, furL)

    // The block: sleek purple, lit on top and the left, shaded under and on the right, a paler chest.
    c.rect(18, top, 20, 38 - top, fur)
    c.rect(18, top, 20, 1, furL); c.rect(18, top, 1, 38 - top, furL)
    c.rect(37, top, 1, 38 - top, furD); c.rect(18, 37, 20, 1, furD)
    c.rect(22, 35, 12, 2, muzD)

    // The ears: tall and pointed, pink-lined; while he snarls, pinned flat back against his head, low rounded flaps
    // lying along the top of it in his own fur with the pink showing under them, nothing sticking up or out.
    if snarl > 0.4 {
        c.pattern(18, top - 2, ["lFFFF.", "FFppFF"], ["F": fur, "l": furL, "p": C(0xC86A9A)])
        c.pattern(32, top - 2, [".FFFFl", "FFppFF"], ["F": fur, "l": furL, "p": C(0xC86A9A)])
        c.px(24, top - 1, furD); c.px(31, top - 1, furD)
    } else {
        c.pattern(19, top - 4, ["F.......", "FF......", "FpF.....", "FFFF...."], ["F": fur, "p": C(0xC86A9A)])
        c.pattern(29, top - 4, [".......F", "......FF", ".....FpF", "....FFFF"], ["F": fur, "p": C(0xC86A9A)])
        c.px(19, top - 4, furL); c.px(36, top - 4, furL)
    }

    // The face: slanted yellow eyes with black slits under a frown, the muzzle, the nose, the whiskers; and the
    // snarl, his lip drawn back on two long fangs.
    c.pattern(21, 28, ["KK..", ".KK."], ["K": furD]); c.pattern(31, 28, [".KK", "KK."], ["K": furD])
    for ex in [22, 32] {
        c.rect(ex, 29, 3, 2, eye); c.px(ex + 1, 29, ink); c.px(ex + 1, 30, ink)
        c.px(ex, 31, furD)
    }
    if snarl > 0.3 {
        c.pattern(23, 31, [
            "..MMNNMM..",
            ".MkMMMMkM.",
            "MWkkkkkkWM",
            "MWkrrrrkWM",
            ".MkkkkkkM.",
        ], ["M": muz, "N": nose, "k": C(0x2A0A1E), "r": C(0xA83A6A), "W": C(0xF8F6EC)])
        c.px(24, 31, muzD); c.px(31, 31, muzD)   // the wrinkles of the snarl
    } else {
        c.pattern(24, 31, [
            ".MMNNMM.",
            "MMMMNMMM",
            ".MkkMkkM",
        ], ["M": muz, "N": nose, "k": muzD])
        c.px(25, 34, C(0xF8F6EC)); c.px(30, 34, C(0xF8F6EC))
    }
    for y in [32, 34] {
        c.rect(19, y, 4, 1, C(0xE8DCF4, 0.8)); c.rect(34, y, 3, 1, C(0xE8DCF4, 0.8))
    }

    // The gold saddle: a seat on his back with a high cantle behind, a red cloth under it, the gold strap round his
    // middle with a buckle.
    c.rect(10, top - 2, 2, 4, gold); c.px(10, top - 2, goldL); c.px(11, top + 1, goldD)
    c.rect(10, top + 2, 10, 2, gold); c.rect(10, top + 2, 10, 1, goldL); c.rect(19, top + 2, 1, 2, goldD)
    c.rect(10, top + 4, 10, 1, cloth); c.rect(10, top + 4, 3, 1, clothL)
    c.rect(15, top + 5, 2, 37 - top - 5, goldD); c.px(15, top + 5, gold)
    c.rect(14, 33, 4, 2, gold); c.px(14, 33, goldL)

    // The front paw: at rest, or swiping on its foreleg, nails out.
    let paw: (x: Double, y: Double)
    if let a = p.melee {
        v4Smear(c, (38.5, 33.5), p.trail, from: 4, to: 9)
        eterniaBar(c, (38.5, 33.5), a, from: 0, to: 5, fur, r: 1.3)
        paw = eterniaReach((38.5, 33.5), a, 6)
    } else {
        paw = (39.5, 34.5)
    }
    let px0 = Int(paw.x.rounded()) - 1, py0 = Int(paw.y.rounded()) - 1
    c.rect(px0, py0, 3, 3, fur); c.rect(px0, py0 + 2, 3, 1, muz); c.px(px0, py0, furL)
    if p.melee != nil || snarl > 0.3 { for y in [py0, py0 + 2] { c.px(px0 + 3, y, C(0xFAFAF0)) } }
}

// MARK: - Stinkor

/// Stinkor: the skunk man, whose smell is his only weapon. Slate black fur with a white blaze from his crown down between
/// his eyes, small round ears, a pink nose; orange armour across his chest on black straps, a black belt with a
/// silver buckle, white feet. Behind him stands his big bushy tail, black with a white stripe down it. Signature: he
/// lifts his tail high over his back with a smug look, and a pale green stink cloud puffs out of it and drifts up
/// and away, wavy lines rising off it.
private func drawStinkor(_ c: PixelCanvas, _ p: Pose) {
    // The fur a slate black, a good step lighter than a dark desktop, with a pale sheen along its lit edges.
    let fur = C(0x5E5C72), furD = C(0x3C3A4C), furL = C(0x9896B2)
    let wht = C(0xF2F2F4), whtD = C(0xBCBCC8)
    let orange = C(0xE8822A), orangeD = C(0xA8561A), orangeL = C(0xFFB868)
    let s = p.signature ?? -1
    let lift = v4Ramp(s, 0.06, 0.2, 0.84, 0.95)
    let cloud = v4Ramp(s, 0.18, 0.3, 0.8, 0.98)

    drawLegs(c, Look(leg: fur), step: p.step)
    drawBoots(c, wht, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, bottom, whtD); c.px(lx, bottom - 4, furL)
        }
    }
    c.oy += p.breathe

    // The tail: a chain of fluffy black puffs with the white stripe down its middle, curling up behind him at rest,
    // lifted high over his back for the signature.
    let rest: [(x: Double, y: Double)] = [(17, 33), (13.5, 30), (11, 26), (10.5, 21.5), (12.5, 18), (15.5, 16.5)]
    let high: [(x: Double, y: Double)] = [(17, 31), (15, 26), (15.5, 20.5), (18.5, 16), (23, 13.5), (27.5, 13)]
    var pts: [(x: Double, y: Double)] = []
    for k in 0..<rest.count {
        let w = sin(p.t * 3 + Double(k)) * 0.3 * Double(k) / 5
        pts.append((rest[k].x + (high[k].x - rest[k].x) * lift + w, rest[k].y + (high[k].y - rest[k].y) * lift))
    }
    for k in 1..<pts.count {
        let r = k < 2 ? 3.4 : k < 5 ? 4.1 : 3.5
        v4Line(c, pts[k - 1], pts[k], fur, r: r)
    }
    for k in 1..<pts.count {
        // Tufts along its outer edge, lit, so it reads fluffy.
        let q = pts[k]
        c.px(Int(q.x.rounded(.down)) - 4, Int(q.y.rounded(.down)), furL)
        c.px(Int(q.x.rounded(.down)) - 3, Int(q.y.rounded(.down)) - 1, furL)
    }
    for k in 1..<pts.count { v4Line(c, pts[k - 1], pts[k], wht, r: k < 2 ? 0.8 : 1.3) }
    if let tip = pts.last { c.rect(Int(tip.x.rounded(.down)) - 2, Int(tip.y.rounded(.down)) - 2, 4, 3, wht) }

    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil))
    c.rect(18, 27, 1, 5, furL)

    // His head: rounded on top, small round ears, the white blaze from the crown down between his eyes.
    c.rect(22, 22, 12, 1, fur); c.rect(20, 23, 16, 1, fur); c.rect(19, 24, 18, 2, fur)
    c.rect(20, 23, 2, 1, furL); c.rect(19, 24, 1, 2, furL); c.rect(36, 24, 1, 2, furD)
    for ex in [19, 33] {
        c.pattern(ex, 20, [".EE.", "EppE", "EEEE"], ["E": fur, "p": C(0xD88AA4)])
    }
    c.rect(25, 22, 6, 2, wht); c.rect(26, 24, 4, 2, wht); c.rect(27, 26, 2, 3, wht)
    c.px(25, 22, white); c.rect(29, 24, 1, 2, whtD); c.px(28, 28, whtD)
    // The eyes, half shut and smug while he lets fly; the pink nose; white cheeks.
    for ex in [22, 32] {
        if cloud > 0.2 {
            c.rect(ex, 30, 2, 2, ink); c.rect(ex - 1, 29, 4, 1, furL)
        } else {
            c.rect(ex, 29, 2, 3, ink); c.px(ex, 29, C(0xE8E8F0))
        }
    }
    c.rect(27, 30, 2, 1, C(0xE87A9A)); c.px(27, 31, C(0xB85A7A))
    c.rect(19, 31, 2, 1, whtD); c.rect(35, 31, 2, 1, whtD)

    // The orange armour on black straps over his shoulders, lit along the top; the black belt and silver buckle.
    c.rect(18, 33, 20, 4, orange); c.rect(18, 33, 20, 1, orangeL); c.rect(36, 33, 2, 4, orangeD)
    c.rect(27, 34, 1, 2, orangeD); c.px(21, 34, orangeL); c.px(33, 34, orangeL)
    c.rect(20, 32, 2, 1, furD); c.rect(34, 32, 2, 1, furD)
    c.rect(18, 37, 20, 1, furD); c.rect(27, 37, 2, 1, C(0xC8CCD4))
    c.rect(15, 33, 3, 1, orange); c.rect(38, 33, 3, 1, orange)

    if cloud > 0, let tip = pts.last {
        // The stink cloud: pale green puffs out of the tail, swelling and fading as they drift up and forward,
        // wavy lines rising off them.
        for k in 0..<4 {
            let f = frac(p.t * 0.55 + Double(k) / 4)
            let x = tip.x + 2 + f * 13 + sin(f * 5 + Double(k)) * 1.5, y = tip.y - 1 - f * 6
            let a = cloud * (1 - f) * (f < 0.1 ? f / 0.1 : 1)
            c.glowLine(x, y, x + 1.5, y, core: C(0xD4F48A, 0.8 * a), glow: C(0x8ACB3A, 0.65 * a), coreR: 2 + f * 2.2,
                       glowR: 3.4 + f * 2.2)
        }
        for k in 0..<3 {
            let f = frac(p.t * 0.8 + Double(k) / 3)
            let x0 = tip.x + 4 + Double(k) * 4, y0 = tip.y - 2 - f * 5
            for j in 0..<3 {
                let yy = y0 - Double(j)
                c.px(Int(x0 + (j % 2 == 0 ? 0 : 1)), Int(yy), C(0xB4E86A, cloud * 0.85 * (1 - f)))
            }
        }
    }
}
