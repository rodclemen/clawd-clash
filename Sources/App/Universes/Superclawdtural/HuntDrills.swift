import Foundation

// Superclawdtural's own solo practice (`UniverseModule.drills`). Nobody floats cross-legged in meditation here
// (`Meditation(who: .never)`).
//
// The hunters lay a devil's trap: a spray can shaken till it rattles, then turned upside down and a red trap painted
// on the floor in front of them stroke by stroke (the ring, the star in one line, the sigils), a step back and two
// nods; the paint glints once, as if it holds, and a boot scuffs it out for the next go. The angels run through a few
// quick strikes with their angel blades, each in their own way, and on the last thrust a flash lights the wall behind
// them and their wings' shadow flares out wide, then folds away.

let huntBespokeDrills: [Cast: BespokeDrill] = {
    var drills: [Cast: BespokeDrill] = [:]
    let hunters: [HuntHero] = [
        .deanWinclawdster, .samWinclawdster, .bobbyClawdsinger, .johnWinclawdster, .maryWinclawdster, .ellenHarvell,
        .joHarvell, .rufusTurner, .garthFitzclawd, .jodyMills, .donnaHanscum, .claireNovak, .eileenLeahy,
        .charlieClawdbury,
    ]
    for h in hunters { drills[.hero(h)] = drawDevilsTrap }
    for h in [HuntHero.clawdstiel, .balthaclawds] { drills[.hero(h)] = drawBladePractice }
    for v in [HuntVillain.uriel, .gadreel] { drills[.villain(v)] = drawBladePractice }
    return drills
}()

/// Eased 0…1.
private func ease(_ k: Double) -> Double {
    let u = max(0, min(1, k))
    return u * u * (3 - 2 * u)
}

// MARK: - The devil's trap

/// The trap on the floor in front of the hunter, seen from the side: a flattened ring round (`trapX`, `trapY`), kept
/// inside column 67 and row 48 so it stays clear of the frame's edges.
private let trapX = 55.0, trapY = 43.0
private let trapRX = 12.0, trapRY = 5.4       // the ring
private let trapIX = 9.6, trapIY = 4.6      // where the star's points reach

/// A point on a ring `rx` by `ry` at `a` radians (0 the near right, going round through the near side first).
private func ringPoint(_ rx: Double, _ ry: Double, _ a: Double) -> (x: Double, y: Double) {
    (trapX + cos(a) * rx, trapY + sin(a) * ry)
}

/// The strokes in the order they're sprayed, each a run of points: the ring in two sweeps (over the back, then round
/// the front), the star in one unbroken line the way it's always drawn, and the sigils, a dab of paint in each gap
/// between the star's points and the ring. Seen this flat, a second ring and proper sigils filled the trap in solid,
/// so it's the one ring and a star clear of it.
private let trapStrokes: [[(x: Double, y: Double)]] = {
    func arc(_ rx: Double, _ ry: Double, from a0: Double, to a1: Double) -> [(x: Double, y: Double)] {
        (0...48).map { ringPoint(rx, ry, a0 + (a1 - a0) * Double($0) / 48) }
    }
    var strokes = [arc(trapRX, trapRY, from: .pi, to: 2 * .pi), arc(trapRX, trapRY, from: 0, to: .pi)]
    // The star: its top point at the back, joined every other point.
    let points = (0..<5).map { k in ringPoint(trapIX, trapIY, -.pi / 2 + Double(k) * 2 * .pi / 5) }
    strokes.append([0, 2, 4, 1, 3, 0].map { points[$0] })
    for k in 0..<5 {
        let p = ringPoint(trapRX - 1.5, trapRY - 0.8, -.pi / 2 + (Double(k) + 0.5) * 2 * .pi / 5)
        strokes.append([(p.x - 0.4, p.y), (p.x + 0.4, p.y)])
    }
    return strokes
}()

/// How long each stroke is, for spraying them at an even pace.
private let trapLengths: [Double] = trapStrokes.map { s in
    zip(s, s.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
}

/// The trap sprayed `done` (0…1) of the way through, the far half a shade darker than the near; `glint` (0…1)
/// brightens it all for a moment. `scuff`: a boot dragging through it from the left has got to this column; behind it
/// the paint is gone but for a few dark smudges (faded by `smudge`), and at its front the paint is dragged along in a
/// dark smear. Returns where the wet end of the paint is, if it's still going.
@discardableResult
private func drawTrap(_ c: PixelCanvas, done: Double, glint: Double, scuff: Double? = nil, smudge: Double = 1)
    -> (x: Double, y: Double)? {
    let total = trapLengths.reduce(0, +)
    var left = done * total, tip: (x: Double, y: Double)?
    var cells = Set<Int>()
    for (s, len) in zip(trapStrokes, trapLengths) {
        guard left > 0 else { break }
        var run = min(left, len)
        left -= len
        for (a, b) in zip(s, s.dropFirst()) {
            guard run > 0 else { break }
            let seg = hypot(b.x - a.x, b.y - a.y), k = min(1, run / seg)
            run -= seg
            let n = max(1, Int(seg * k * 4))
            for i in 0...n {
                let u = Double(i) / Double(n) * k
                let x = a.x + (b.x - a.x) * u, y = a.y + (b.y - a.y) * u
                cells.insert(Int(y.rounded()) * 1000 + Int(x.rounded()))
                tip = (x, y)
            }
        }
        if left < 0 { break } else { tip = nil }
    }
    let far = lerp(C(0xC42424), C(0xFF7A5A), glint), near = lerp(C(0xEC3C30), C(0xFFA080), glint)
    // Every pixel is set once, so nothing stacks up to solid paint (which would get the app's outline).
    var paint: [Int: Px] = [:]
    for cell in cells {
        let x = cell % 1000, y = cell / 1000
        if let sx = scuff {
            if Double(x) < sx - 1.5 {           // scuffed off: a few dark smudges left behind
                if noise(cell) < 0.2, smudge > 0.05 { paint[cell] = C(0x6A1416, 0.6 * smudge) }
                continue
            }
            if Double(x) < sx + 1.5 {           // dragged along by the boot
                paint[cell + 1] = C(0x9A1C1C, 0.85)
                if paint[cell + 2] == nil { paint[cell + 2] = C(0x6A1416, 0.5) }
                continue
            }
        }
        if paint[cell] == nil { paint[cell] = (Double(y) < trapY ? far : near).alpha(0.9) }
    }
    for (cell, col) in paint { c.px(cell % 1000, cell / 1000, col) }
    return tip
}

/// The spray can in the fist: upright (`tilt` false), a red cap and its nozzle on top, the grey tin lit down its left
/// and a red label band; or turned upside down to spray the floor, the fist round its middle, its base up and the red
/// cap and nozzle at the bottom, leaning forward over the trap. Returns the nozzle.
@discardableResult
private func drawCan(_ c: PixelCanvas, dy: Int, tilt: Bool) -> (x: Double, y: Double) {
    let tin = C(0xB8BCC4), tinL = C(0xE2E4E8), tinD = C(0x7C808A), cap = C(0xC8282A), capD = C(0x8A1A1C)
    let nozzle = C(0x2A2A30)
    let palette: [Character: Px] = ["T": tin, "L": tinL, "D": tinD, "R": cap, "r": capD, "n": nozzle,
                                    "O": clawdOrange, "o": clawdShade]
    if tilt {
        // Upside down, leaning forward: the tin's base on top, the fist round it, the cap and nozzle pointing down.
        c.pattern(40, 28 + dy, [
            ".DD.",
            "LTD.",
            "LRD.",
            "LTD.",
            "OOO.",
            "OOOD",
            "OOoD",
            ".LTD",
            ".RRr",
            "..n.",
        ], palette)
        return (42.5, 37.5 + Double(dy))
    }
    c.pattern(40, 26 + dy, [
        ".n.",
        "RRr",
        "LTD",
        "LRD",
        "LTD",
        "LTD",
        "LTD",
        "OOO",
        "OOO",
        "OOo",
    ], palette)
    return (41.5, 26.5 + Double(dy))
}

/// One of the hunters laying a devil's trap. The can comes out and is shaken hard, rattling; then turned over and the
/// trap sprayed onto the floor in front, a mist of red from the nozzle to the wet end of the line, stroke after stroke.
/// A good step back, a look, two clear nods, and the paint glints red once, as if it holds. Then they step up and
/// scuff it out with a boot, dragged through from the left in a dark smear and a kick of dust, and the gun goes back in
/// the hand.
private func drawDevilsTrap(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let L = d.length, e = d.e
    let shake = (0.35, 1.35), spray = (1.45, L * 0.66), back = (L * 0.68, L * 0.74), nods = (L * 0.77, L * 0.86)
    let scuffing = (L * 0.88, L * 0.95)
    let canOut = e >= shake.0 && e < L - 0.45
    let stepping = (e >= back.0 && e < back.1) || (e >= scuffing.0 && e < scuffing.1)
    // Four pixels back to look it over, and forward again to scuff it.
    let stepped = e >= scuffing.0 ? Int((4 * (1 - ease((e - scuffing.0) / (scuffing.1 - scuffing.0)))).rounded())
                : e >= back.0 ? Int((4 * ease((e - back.0) / (back.1 - back.0))).rounded()) : 0
    let body = PixelCanvas(c.w, c.h)
    standing(body, who, t: t) { p in
        if stepping { p.step = Int(e / 0.1) % 2; p.breathe = 0 }
        // A blade carried upright at rest (Charlie's sword) is lowered to point ahead, out past the fist.
        if canOut, who.weapon == .saber { p.melee = 20 }
    }
    if canOut {
        // The gun or blade put away while the hands are busy: whatever sticks out past the fist goes.
        body.move(columns: 41..<72, rows: 22..<52, dy: 100)
    }
    // Two nods: the head and shoulders dip two pixels and come back up.
    if e >= nods.0 && e < nods.1 {
        let f = frac((e - nods.0) / ((nods.1 - nods.0) / 2))
        let dip = f < 0.2 || f > 0.8 ? 0 : f < 0.35 || f > 0.65 ? 1 : 2
        if dip > 0 { body.move(columns: 0..<72, rows: 0..<33, dy: dip) }
    }

    // The trap goes under everything, on the floor.
    let sprayK = (e - spray.0) / (spray.1 - spray.0)
    let glint = e >= nods.0 ? max(0, 1 - abs(e - (nods.1 - 0.15)) / 0.25) : 0
    let scuffK = (e - scuffing.0) / (scuffing.1 - scuffing.0)
    let sweep = e >= scuffing.0 ? trapX - trapRX - 2 + (2 * trapRX + 5) * ease(scuffK) : nil
    let smudge = e > scuffing.1 ? max(0, 1 - (e - scuffing.1) / 0.35) : 1
    let tip = e >= spray.0 && smudge > 0 ? drawTrap(c, done: min(1, sprayK), glint: glint, scuff: sweep, smudge: smudge) : nil
    if let sx = sweep, scuffK < 1 {
        // The dust the boot kicks up, at the front of the scuff.
        for i in 0..<4 {
            let f = frac(t * 3 + Double(i) / 4)
            c.px(Int((sx + 2 + f * 7).rounded()), Int((trapY + 2 - f * 3 - noise(i * 7) * 2).rounded()), C(0xD8CCB4, 0.5 * (1 - f)))
        }
    }

    c.paste(body, x: -stepped, y: 0)
    guard canOut else { return }
    c.ox = -stepped
    defer { c.ox = 0 }

    let spraying = e >= spray.0 && e < spray.1
    let jiggle = e >= shake.0 && e < shake.1 ? (Int(e * 15) % 2 == 0 ? -1 : 1) : 0
    let nozzle = drawCan(c, dy: jiggle, tilt: spraying)
    if jiggle != 0, Int(e * 7.5) % 2 == 0 {
        // The rattle: little marks either side of the shaking can.
        c.px(38, 27, C(0xF4F0E8, 0.8)); c.px(44, 28, C(0xF4F0E8, 0.8)); c.px(44, 25, C(0xF4F0E8, 0.6))
    }
    guard spraying, let tip else { return }
    // The mist: fine red flecks streaming from the nozzle to the wet end, thicker as they land, and a puff there.
    let to = (x: tip.x + Double(stepped), y: tip.y)
    for i in 0..<9 {
        let u = 0.18 + 0.82 * frac(t * 2.6 + Double(i) / 9)
        let spread = u * 1.6
        let x = nozzle.x + (to.x - nozzle.x) * u + (noise(Int(t * 30) + i * 7) - 0.5) * spread * 2
        let y = nozzle.y + (to.y - nozzle.y) * u + (noise(Int(t * 30) + i * 13) - 0.5) * spread
        c.px(Int(x.rounded()), Int(y.rounded()), C(0xFF6A50, 0.5 + 0.35 * u))
    }
    for (dx, dy) in [(-1, -1), (1, -1), (0, -2)] where noise(Int(t * 20) + dx * 5 + dy) > 0.4 {
        c.px(Int(to.x.rounded()) + dx, Int(to.y.rounded()) + dy, C(0xFF8A70, 0.45))
    }
}

// MARK: - Angel blade practice

/// The strikes, as moments (seconds into the set) and the blade's angle then (0 forward, -90 straight up), with how
/// far the angel has stepped in; `fast` marks a strike, which leaves a smear behind it. Each angel has a set of its
/// own, all ending on the last thrust at `flareAt` (the flash and the wings).
private typealias BladeMove = (at: Double, angle: Double, dx: Double, fast: Bool)

/// Clawdstiel, by the book: a thrust, a rising slash and a cut straight back down, then the blade raised high.
private let bladeByTheBook: [BladeMove] = [
    (0.0, -50, 0, false),
    (0.5, -45, 0, false),        // on guard
    (0.9, -25, -1, false),       // drawn back
    (1.0, 0, 2, true),           // the thrust
    (1.4, -10, 1, false),
    (1.8, 45, 0, false),         // low
    (1.92, -105, 1, true),       // a rising slash
    (2.4, -110, 0, false),
    (2.52, 35, 1, true),         // and straight back down
    (3.0, -45, 0, false),        // on guard again
    (3.6, -100, -1, false),      // raised high, drawn back
    (3.72, 5, 2, true),          // the last thrust: the flash and the wings
    (4.9, 0, 2, false),
    (5.6, -45, 0, false),
]

/// Balthaclawds, showing off: the blade flicked up and down and up again, a lazy low sweep, a twirl overhead.
private let bladeShowy: [BladeMove] = [
    (0.0, -50, 0, false),
    (0.5, -30, 0, false),        // held loose
    (0.8, -95, 0, true),         // flick up
    (0.95, -5, 1, true),         // and down
    (1.1, -95, 0, true),         // and up again
    (1.6, -80, 0, false),
    (2.0, 50, 1, false),         // a lazy low sweep
    (2.12, -60, 1, true),
    (2.7, -120, 0, false),       // the twirl overhead
    (2.84, -60, 0, true),
    (2.98, -120, 0, true),
    (3.5, -40, -1, false),       // drawn back
    (3.72, 0, 2, true),          // the last thrust
    (4.9, 0, 2, false),
    (5.6, -45, 0, false),
]

/// Uriel, all force: the blade raised right up and brought down in two great chops.
private let bladeHeavy: [BladeMove] = [
    (0.0, -50, 0, false),
    (0.6, -60, 0, false),        // on guard
    (1.2, -120, -1, false),      // raised right up
    (1.36, 45, 2, true),         // the first chop
    (2.0, 40, 2, false),
    (2.4, -50, 0, false),
    (2.9, -120, -1, false),      // up again
    (3.06, 50, 2, true),         // the second chop
    (3.45, 30, 1, false),
    (3.6, -30, -1, false),       // drawn back
    (3.72, 0, 2, true),          // the last thrust
    (4.9, 0, 2, false),
    (5.6, -45, 0, false),
]

/// Gadreel, careful: on a high guard, two short jabs, a block overhead and a quick low cut.
private let bladeGuarded: [BladeMove] = [
    (0.0, -50, 0, false),
    (0.6, -70, 0, false),        // a high guard
    (0.9, -70, 0, false),
    (1.0, -5, 2, true),          // a short jab
    (1.25, -65, 0, false),
    (1.55, -65, 0, false),
    (1.65, -5, 2, true),         // and another
    (1.9, -65, 0, false),
    (2.4, -90, -1, false),       // a block overhead
    (2.9, -90, -1, false),
    (3.02, 25, 1, true),         // a quick low cut
    (3.4, -40, 0, false),
    (3.6, -25, -1, false),       // drawn back
    (3.72, 0, 2, true),          // the last thrust
    (4.9, 0, 2, false),
    (5.6, -45, 0, false),
]

/// Whose set is whose.
private func bladeMoves(for who: Cast) -> [BladeMove] {
    if who == .hero(HuntHero.balthaclawds) { return bladeShowy }
    if who == .villain(HuntVillain.uriel) { return bladeHeavy }
    if who == .villain(HuntVillain.gadreel) { return bladeGuarded }
    return bladeByTheBook
}

/// When the last thrust lands, in every set.
private let flareAt = 3.72

/// Where the blade is `e` seconds in: eased between the moves, a strike snapping through quickly.
private func bladeAt(_ bladeMoves: [BladeMove], _ e: Double) -> (angle: Double, dx: Double, fast: Bool) {
    guard let i = bladeMoves.lastIndex(where: { $0.at <= e }) else { return (bladeMoves[0].angle, 0, false) }
    guard i + 1 < bladeMoves.count else { return (bladeMoves[i].angle, bladeMoves[i].dx, false) }
    let a = bladeMoves[i], b = bladeMoves[i + 1]
    let k = (e - a.at) / (b.at - a.at)
    let u = b.fast ? k * k : ease(k)
    return (a.angle + (b.angle - a.angle) * u, a.dx + (b.dx - a.dx) * u, b.fast)
}

/// One of the angels at practice: on guard with the angel blade and through their own few strikes (`bladeMoves`),
/// each snapping through with a smear behind it; then the last thrust driven home, and as it lands a cold flash
/// lights the wall behind and the wings' shadow is thrown across it, spread wide, its edge lit by the flash so it
/// shows even in the dark; it holds a moment and folds away as the blade comes back up.
private func drawBladePractice(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let s = min(1.25, max(1, d.length / 7))       // a longer set plays the same moves a little slower
    let e = d.e / s
    let r = setRamp(d)
    let moves = bladeMoves(for: who)
    let move = bladeAt(moves, e)
    let since = e - flareAt
    let wings = since < 0 ? 0 : since < 0.22 ? ease(since / 0.22) : since < 1.3 ? 1 : max(0, 1 - ease((since - 1.3) / 0.6))
    let flash = since < 0 ? 0 : max(0, 1 - since / 0.5)

    let dx = Int((move.dx * r).rounded())
    let body = PixelCanvas(c.w, c.h)
    standing(body, who, t: t) { p in
        guard r > 0.05 else { return }
        p.melee = -60 + (move.angle + 60) * r
        p.breathe = 0
        if move.fast, r > 0.9 {
            p.trail = [0.03, 0.06, 0.09].map { bladeAt(moves, max(0, e - $0)).angle }
        }
    }
    if wings > 0.04 { drawFlaredWings(c, wings, flash: flash, around: body, dx: dx) }
    c.paste(body, x: dx, y: 0)
}

/// The wings' shadow thrown on the wall by a flash, opened `k`. The shadow itself is the angels' usual one, a shade
/// stronger; the flash lights the wall round it, a cold see-through wash that fades as fast as it came, and catches its
/// outer edge in a pale rim, so the shape reads on a near-black desktop as well as on a bright place. All of it keeps
/// a pixel clear of the angel (`around`, drawn `dx` across), so the app's outline still goes all the way round him.
private func drawFlaredWings(_ c: PixelCanvas, _ k: Double, flash: Double, around body: PixelCanvas, dx: Int) {
    // Where the wings are, from the shared shadow drawn alone at full strength.
    let mask = PixelCanvas(c.w, c.h)
    huntWingShadows(mask, k, tint: C(0xFFFFFF), strength: 1)
    func solid(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < c.w && y < c.h && mask.buf[(y * c.w + x) * 4 + 3] >= 240
    }
    let layer = PixelCanvas(c.w, c.h)
    // The flash on the wall: a pale wash round the wings, gone in half a second.
    if flash > 0.02 {
        for y in 4..<44 {
            for x in 2..<70 where !solid(x, y) {
                let fx = (Double(x) - 28) / 40, fy = (Double(y) - 28) / 20
                let fall = max(0, 1 - (fx * fx + fy * fy))
                guard fall > 0 else { continue }
                layer.px(x, y, C(0xD8E4FF, 0.22 * fall * flash))
            }
        }
    }
    huntWingShadows(layer, k, strength: 0.6)
    // The rim: wing pixels on the edge of the shape, well out from the body.
    let rim = C(0xC4D2F0, 0.5 + 0.3 * flash)
    for y in 1..<45 {
        for x in 1..<71 where solid(x, y) && (x < 15 || x > 41 || y < 20) {
            if !solid(x - 1, y) || !solid(x + 1, y) || !solid(x, y - 1) || !solid(x, y + 1) { layer.px(x, y, rim) }
        }
    }
    // Onto the canvas, leaving a pixel's gap round everything solid of his.
    func his(_ x: Int, _ y: Int) -> Bool {
        let bx = x - dx
        return bx >= 0 && y >= 0 && bx < body.w && y < body.h && body.buf[(y * body.w + bx) * 4 + 3] >= 250
    }
    for y in 0..<c.h {
        for x in 0..<c.w {
            let i = (y * c.w + x) * 4, a = layer.buf[i + 3]
            guard a > 0 else { continue }
            var near = false
            for oy in -1...1 { for ox in -1...1 where his(x + ox, y + oy) { near = true } }
            guard !near else { continue }
            let m = 255 / Double(a)
            c.px(x, y, Px(r: UInt8(min(255, Double(layer.buf[i]) * m)), g: UInt8(min(255, Double(layer.buf[i + 1]) * m)),
                          b: UInt8(min(255, Double(layer.buf[i + 2]) * m)), a: a))
        }
    }
}
