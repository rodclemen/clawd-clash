import Foundation

// Clawds of the Universe's own solo practice (`UniverseModule.drills`): He-Clawd pressing a boulder over his head,
// Teelah running her staff through a kata, Man-At-Clawds at his anvil, Orkko juggling until a ball turns into a fish,
// Ram Clawd charging a wall and bouncing off it, Bow shooting at a target, Jitsu chopping a stack of planks, Gwildor
// tuning the Cosmic Key a note at a time, the Horde Troopers at rifle drill (in step with each other, on the shared
// clock) and Skeleclawd practising his cackle on Screeech. Nobody floats cross-legged in meditation here
// (`Meditation(who: .never)`): Orkko floats already.
//
// These are practice, not the signature moves again: Man-At-Clawds' signature tinkers with his gauntlet, so here he
// beats out a hot blade on an anvil; Jitsu's chops one plank, so here it's a stack of four on bricks; the Troopers'
// marches with the rifle shouldered, so here it's spun and ported too; Gwildor's plays a run on the Key held high, so
// here he tries one note at a time and gets some wrong; Skeleclawd's cackle gets an audience, and a reply.

let eterniaBespokeDrills: [Cast: BespokeDrill] = [
    .hero(EterniaHero.heClawd): drawBoulderPress,
    .hero(EterniaHero.teelah): drawStaffKata,
    .hero(EterniaHero.manAtClawds): drawAnvil,
    .hero(EterniaHero.orkko): drawJuggling,
    .hero(EterniaHero.ramClawd): drawWallCharge,
    .hero(EterniaHero.bow): drawTargetPractice,
    .villain(EterniaVillain.jitsu): drawPlankStack,
    .hero(EterniaHero.gwildor): drawKeyTuning,
    .villain(EterniaVillain.hordeTrooper): drawRifleDrill,
    .villain(EterniaVillain.skeleclawd): drawCacklePractice,
]

// MARK: - Shared bits

/// Eased 0…1.
private func ease(_ k: Double) -> Double {
    let u = max(0, min(1, k))
    return u * u * (3 - 2 * u)
}

/// The breathing bob `drawPersona` gives the upper body right now (-1 or 0), so a prop held in the hand moves with it.
private func breath(_ who: Cast, _ t: Double) -> Int {
    sin((t + Double(who.id) * 0.77) * 2 * .pi / 2.6) > 0.35 ? -1 : 0
}

/// Wipe what's drawn in `columns` × `rows` (an arm or a weapon the drill draws its own way).
private func wipe(_ c: PixelCanvas, columns: Range<Int>, rows: Range<Int>) {
    c.move(columns: columns, rows: rows, dy: c.h)
}

/// A solid line from one point to another, `r` from its centre.
private func line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.6) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// A value keyed through a loop: `keys` are (time, value) pairs, eased from one to the next; past the last it eases
/// back to the first at `period`.
private func keyed(_ e: Double, period: Double, _ keys: [(Double, Double)]) -> Double {
    let u = e.truncatingRemainder(dividingBy: period)
    for i in 0..<keys.count {
        let a = keys[i], b = i + 1 < keys.count ? keys[i + 1] : (period, keys[0].1)
        if u >= a.0 && u < b.0 { return a.1 + (b.1 - a.1) * ease((u - a.0) / max(0.001, b.0 - a.0)) }
    }
    return keys[0].1
}

/// A little puff of dust on the ground at `x`, `k` 0…1 through it.
private func dustPuff(_ c: PixelCanvas, x: Double, y: Double = 43, k: Double, spread: Double = 4) {
    guard k >= 0, k < 1 else { return }
    for (dx, dy) in [(-1.0, 0.0), (1.0, 0.0), (-0.6, -1.0), (0.6, -1.0)] {
        let px = x + dx * spread * (0.5 + k), py = y + dy * (1 + 2 * k)
        c.glowLine(px, py, px, py, core: C(0xE8DCC0, 0.75 * (1 - k)), glow: C(0xE8DCC0, 0), coreR: 0.7, glowR: 0.8)
    }
}

// MARK: - He-Clawd

/// A rock to lift, centred on (`cx`, `cy`): a lumpy grey-brown boulder, lit on its upper left and shaded under,
/// a crack across it and a few pits.
private func boulder(_ c: PixelCanvas, cx: Double, cy: Double) {
    let rock = C(0x8E8270), rockD = C(0x5E5446), rockL = C(0xB8AC96), pit = C(0x4A4238)
    let rx = 10.0, ry = 6.0
    for y in Int(cy - ry - 1)...Int(cy + ry + 1) {
        for x in Int(cx - rx - 1)...Int(cx + rx + 1) {
            let dx = (Double(x) + 0.5 - cx) / rx, dy = (Double(y) + 0.5 - cy) / ry
            let bump = 0.08 * sin(atan2(dy, dx) * 5)
            let d = dx * dx + dy * dy
            guard d <= 1 + bump else { continue }
            let col = dx + dy < -0.9 ? rockL : dy > 0.55 || dx + dy > 0.95 ? rockD : rock
            c.px(x, y, col)
        }
    }
    let x0 = Int(cx.rounded()), y0 = Int(cy.rounded())
    c.px(x0 - 3, y0 - 2, rockD); c.px(x0 - 2, y0 - 1, rockD); c.px(x0 - 1, y0 - 1, rockD); c.px(x0, y0, rockD)
    c.px(x0 + 1, y0, rockD); c.px(x0 + 2, y0 + 1, rockD)                      // the crack
    c.px(x0 + 4, y0 - 3, pit); c.px(x0 - 6, y0 + 1, pit); c.px(x0 + 6, y0 + 2, pit)
}

/// He-Clawd pressing a boulder: it sits on the ground beside him, he heaves it up over his head in both hands,
/// presses it up and down twice like a weight, then sets it back down with a thump and a puff of dust.
private func drawBoulderPress(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    standing(c, who, t: t)
    guard r > 0.15 else { return }
    let period = 3.8
    let lifting = r > 0.6
    let f = lifting ? frac(d.e / period) : 0
    // How far up: 0 on the ground, 1 overhead; the presses on top of that.
    var u = 0.0
    if f > 0.1 && f < 0.3 { u = ease((f - 0.1) / 0.2) } else if f >= 0.3 && f < 0.74 { u = 1 } else if f >= 0.74 && f < 0.9 {
        u = 1 - ease((f - 0.74) / 0.16)
    }
    let press = f > 0.34 && f < 0.7 ? Int((2 * (0.5 - 0.5 * cos((f - 0.34) / 0.18 * 2 * .pi))).rounded()) : 0
    let b = breath(who, t)
    let ground = (x: 52.0, y: 37.5), over = (x: 28.0, y: 13.5)
    let bx = ground.x + (over.x - ground.x) * u * u
    let by = ground.y + (over.y - ground.y) * (1 - (1 - u) * (1 - u)) + Double(press)
    boulder(c, cx: bx, cy: by)
    guard u > 0 else {
        dustPuff(c, x: 52, k: f >= 0.9 ? (f - 0.9) / 0.1 : -1, spread: 6)
        return
    }
    // His arms, both fists under the rock: the near one goes up with it all the way, the back one joins it once it's
    // over his head. Clawd's arms are short nubs, so the fists simply rise, as when he raises the Power Sword.
    wipe(c, columns: 15..<18, rows: 31..<37)
    wipe(c, columns: 38..<41, rows: 31..<37)
    let near = Int((33 + Double(b) + (by + 4.5 - 33 - Double(b)) * min(1, u * 1.2)).rounded())
    let back = Int((33 + Double(b) + (18 + Double(press) - 33 - Double(b)) * ease((u - 0.5) / 0.5)).rounded())
    let nearX = Int((38 - 2 * ease((u - 0.6) / 0.4)).rounded()), backX = Int((15 + 2 * ease((u - 0.6) / 0.4)).rounded())
    let bracer = C(0x6A4428), bracerL = C(0x8A5E38)
    for (x, y) in [(backX, back), (nearX, near)] {
        c.rect(x, y, 3, 3, clawdOrange); c.rect(x, y + 1, 3, 1, bracer); c.px(x, y + 1, bracerL)
    }
}

// MARK: - Teelah

/// Teelah's staff kata, looping: on guard, the staff wound back overhead and brought down in a strike, a low sweep,
/// a full spin with a hop, a thrust straight out, a high block, and back on guard. A smear behind every fast move.
private func drawStaffKata(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 3.6
    let angleKeys: [(Double, Double)] = [(0, -60), (0.4, -150), (0.55, 20), (0.9, 20), (1.1, 30), (1.6, -330), (1.8, -330),
                                         (2.05, -360), (2.4, -360), (2.75, -450), (3.15, -450),
                                         (3.6, -420)]
    let dxKeys: [(Double, Double)] = [(0, 0), (0.4, -1), (0.55, 2), (1.1, 2), (1.6, 1), (2.05, 4), (2.4, 4), (2.75, 0)]
    let hopKeys: [(Double, Double)] = [(0, 0), (1.25, 0), (1.45, -3), (1.65, 0)]
    let raiseKeys: [(Double, Double)] = [(0, 0), (0.4, 2), (0.55, 0), (2.4, 0), (2.75, 3), (3.15, 3)]
    guard r > 0.5 else { standing(c, who, t: t); return }
    let e = d.e - 0.4
    // The angle runs on round past a full turn and a bit: -420 at the end of the loop is -60 again, its start.
    let a = keyed(e, period: period, angleKeys)
    var trail: [Double] = []
    let prev = keyed(e - 0.035, period: period, angleKeys), prev2 = keyed(e - 0.07, period: period, angleKeys)
    if abs(a - prev) > 6 { trail = [prev, prev2] }
    let dx = Int(keyed(e, period: period, dxKeys).rounded())
    let hop = Int(keyed(e, period: period, hopKeys).rounded())
    let raise = Int(keyed(e, period: period, raiseKeys).rounded())
    standing(c, who, t: t) { p in
        p.melee = a; p.trail = trail; p.dx = dx; p.hop = hop; p.armRaise = raise; p.breathe = 0
    }
}

// MARK: - Man-At-Clawds

/// Man-At-Clawds at the anvil: a blade glowing hot on it, his mace for a hammer, wound up high and brought down on
/// it with a shower of sparks, again and again; the blade cools a shade between blows and flares at each one.
private func drawAnvil(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 1.3
    let working = r > 0.5
    let f = frac(d.e / period)
    func swing(_ f: Double) -> Double {
        if f < 0.45 { return -8 + (-105 + 8) * ease(f / 0.45) }
        if f < 0.55 { return -105 }
        if f < 0.6 { return -105 + 97 * (1 - pow(1 - (f - 0.55) / 0.05, 2)) }
        if f < 0.8 { return -8 }
        return -8 - 6 * ease((f - 0.8) / 0.2) * (1 - ease((f - 0.8) / 0.2)) * 4
    }
    let angle = swing(f)
    var trail: [Double] = []
    if f > 0.55 && f < 0.62 { trail = [swing(f - 0.012), swing(f - 0.024)] }

    // The anvil, drawn first so the mace comes down on top of it: a dark iron top face with its horn out to the
    // right, a narrow waist and a broad foot, lit along the top.
    if r > 0.15 {
        let iron = C(0x4A4E58), ironD = C(0x2E3038), ironL = C(0x7A808E)
        c.rect(45, 37, 13, 2, iron); c.rect(45, 37, 13, 1, ironL)
        c.rect(58, 37, 3, 1, iron); c.px(61, 37, ironD); c.rect(58, 38, 2, 1, ironD)   // the horn
        c.rect(48, 39, 7, 2, ironD); c.rect(48, 39, 1, 2, iron)
        c.rect(46, 41, 11, 2, iron); c.rect(46, 41, 11, 1, ironL); c.rect(45, 43, 13, 1, ironD)
        // The blade on it, hot: orange through to yellow-white where it's just been struck.
        let since = working ? (f >= 0.6 ? f - 0.6 : f + 0.4) : 1
        let heat = max(0, 1 - since * 1.4)
        let hot = heat > 0.6 ? C(0xFFF0B0) : heat > 0.25 ? C(0xFFC040) : C(0xF07A20)
        c.rect(46, 35, 10, 2, C(0xD8501A)); c.rect(47, 35, 8, 1, hot); c.px(56, 36, C(0xB03A12))
        c.glowLine(47, 35.5, 55, 35.5, core: C(0xFFB040, 0), glow: C(0xFF8A20, 0.25 + 0.3 * heat), coreR: 0.1, glowR: 2.2)
    }
    standing(c, who, t: t) { p in if working { p.melee = angle; p.trail = trail } }

    // The sparks off each blow, flying up and out, falling back, gone before they reach the frame's edge.
    guard working, f >= 0.6, f < 0.9 else { return }
    let k = (f - 0.6) / 0.3, n = Int(floor(d.e / period))
    if k < 0.15 {   // the flash of the blow
        c.glowLine(51, 34, 51, 34, core: C(0xFFFFFF, 0.9), glow: C(0xFFD060), coreR: 0.8, glowR: 3.5, strength: 1 - k / 0.15)
    }
    for i in 0..<9 {
        let vx = (noise(n * 31 + i * 7) - 0.35) * 30, vy = 14 + noise(n * 17 + i * 3) * 14
        let x = 51 + vx * k, y = 34 - vy * k + 34 * k * k
        guard y < 43, y > 2, x > 2, x < 69 else { continue }
        let tail = (x - vx * 0.07, y + (vy - 68 * k) * 0.07)
        c.glowLine(tail.0, tail.1, x, y, core: (i % 3 == 0 ? C(0xFFFFFF) : C(0xFFE070)).alpha(1 - k * 0.6),
                   glow: C(0xFF9A20, 0.6 * (1 - k)), coreR: 0.45, glowR: 1.3)
    }
}

// MARK: - Orkko

/// Orkko juggling three glowing balls in his raised hand, up and round in a loop; at the top of a throw one of them
/// turns into a fish with a pop of sparkles, which flops down on the floor in front of him, wriggles, and vanishes in
/// another pop, and the trick starts over with three balls.
private func drawJuggling(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let juggling = r > 0.5
    standing(c, who, t: t) { p in if juggling { p.armRaise = 2 } }
    guard juggling else { return }
    // His float and breath, so the balls stay with his hand.
    let lt = t + Double(who.id) * 0.77
    let lift = -3 + (sin(lt * 2.4) > 0 ? -1 : 0) + breath(who, t)
    let hand = (x: 40.5, y: 31.0 + Double(lift))
    let round = 4.4, f = frac(d.e / round), throwT = 1.1
    let cols: [(Px, Px)] = [(C(0xFFF6A0), C(0xE040C0)), (C(0xA0F8FF), C(0x2AA8E8)), (C(0xC8FFA0), C(0x4CC83A))]
    // Where a ball is, 0…1 through its loop: thrown up the inside and over, caught on the outside, carried back in.
    func at(_ u: Double) -> (x: Double, y: Double) {
        if u < 0.78 {
            let k = u / 0.78
            return (hand.x + 1 + 7 * k, hand.y - 1 - 13 * 4 * k * (1 - k))
        }
        let k = (u - 0.78) / 0.22
        return (hand.x + 8 - 7 * k, hand.y - 1 + sin(k * .pi) * 1.5)
    }
    // The fish: ball 0 turns at the top of its throw a third of the way into the round, falls, flops, and goes.
    let turnAt = 0.3, landAt = 0.42, goneAt = 0.82
    for i in 0..<3 {
        let u = frac(d.e / throwT + Double(i) / 3)
        var p = at(u)
        if i == 0 && f > turnAt {
            if f > goneAt { continue }
            // Falling from where it turned, out past his hand to the floor, then flopping there.
            let k = min(1, (f - turnAt) / (landAt - turnAt))
            let start = (x: hand.x + 5, y: hand.y - 13)
            p = (start.x + 9 * k, start.y + (41.5 - start.y) * k * k)
            drawFish(c, x: p.x, y: p.y, flop: k >= 1 ? frac(d.e * 3) : 0, t: t)
            if f - turnAt < 0.05 { sparklePop(c, x: start.x, y: start.y, k: (f - turnAt) / 0.05) }
            continue
        }
        if i == 0 && f < 0.04 && d.e > round { sparklePop(c, x: p.x, y: p.y, k: f / 0.04) }
        let (core, glow) = cols[i]
        let bx = Int(p.x.rounded()) - 1, byy = Int(p.y.rounded()) - 1
        c.glowLine(p.x, p.y, p.x, p.y, core: C(0, 0), glow: glow.alpha(0.55), coreR: 0.1, glowR: 2.8)
        c.rect(bx, byy, 2, 2, core); c.px(bx + 1, byy + 1, glow)
    }
    if f > goneAt && f < goneAt + 0.05 { sparklePop(c, x: hand.x + 14, y: 41, k: (f - goneAt) / 0.05) }
}

/// A little orange fish at (`x`, `y`), nose to the left; `flop` 0…1 flips its tail up and down on the floor.
private func drawFish(_ c: PixelCanvas, x: Double, y: Double, flop: Double, t: Double) {
    let body = C(0xF08A30), bodyD = C(0xB85A18), bodyL = C(0xFFC070)
    let x0 = Int(x.rounded()) - 3, y0 = Int(y.rounded()) - 1
    let up = flop > 0.5 ? -1 : 0
    c.pattern(x0, y0 + up, [
        ".LBBB.T",
        "LBkBBTT",
        ".dBBd.T",
    ], ["B": body, "L": bodyL, "d": bodyD, "T": bodyD, "k": C(0x1A1420)])
}

/// A pop of lemon and magenta sparkles at (`x`, `y`), `k` 0…1 through it: Orkko's magic going off.
private func sparklePop(_ c: PixelCanvas, x: Double, y: Double, k: Double) {
    for i in 0..<6 {
        let a = Double(i) / 6 * 2 * .pi
        let rr = 1.5 + k * 4
        c.px(Int((x + cos(a) * rr).rounded()), Int((y + sin(a) * rr).rounded()),
             (i % 2 == 0 ? C(0xFFF6A0) : C(0xE040C0)).alpha(1 - k * 0.6))
    }
}

// MARK: - Ram Clawd

/// Ram Clawd charging a wall: a stone wall out in front, he hunkers down, charges at it head first, slams into it
/// (the wall shudders, grit falls off it), bounces back off in a hop, stands there dizzy with stars round his helmet,
/// and walks back to where he started.
private func drawWallCharge(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 3.6
    let going = r > 0.6
    let f = going ? frac(d.e / period) : -1
    var dx = 0.0, hop = 0.0, crouch: Double?, running = false
    if f < 0 {
        // Not yet (or no longer) at it: stood in front of the wall.
    } else if f < 0.2 { crouch = 0.05 + 0.17 * ease(f / 0.15) }
    else if f < 0.38 { dx = 7 * pow((f - 0.2) / 0.18, 1.6); running = true }
    else if f < 0.42 { dx = 7 }
    else if f < 0.56 { let k = (f - 0.42) / 0.14; dx = 7 - 8 * ease(k); hop = 4 * sin(k * .pi) }
    else if f < 0.86 { dx = -1 }
    else { dx = -1 + ease((f - 0.86) / 0.12); running = f < 0.98 }

    // The wall: blocks of grey stone in courses, lit along the top of each, mortar between. It shudders on impact.
    if r > 0.15 {
        let shake = f >= 0.38 && f < 0.46 ? (Int(t * 40) % 2 == 0 ? 1 : 0) : 0
        let stone = C(0x8A7E6E), stoneD = C(0x5A5046), stoneL = C(0xB0A490)
        let x0 = 58 + shake
        c.rect(x0, 16, 9, 28, stone)
        for row in 0..<7 {
            let y = 16 + row * 4
            c.rect(x0, y, 9, 1, stoneL)
            c.rect(x0, y + 3, 9, 1, stoneD)
            c.rect(x0 + (row % 2 == 0 ? 4 : 2), y + 1, 1, 2, stoneD)
            if row % 2 == 1 { c.rect(x0 + 6, y + 1, 1, 2, stoneD) }
        }
        c.rect(x0 + 8, 16, 1, 28, stoneD)
        if f >= 0.4 && f < 0.7 {
            // Grit shaken off the face, falling.
            let k = (f - 0.4) / 0.3
            for i in 0..<4 {
                let y = 20 + Double(i) * 4 + k * k * 24
                guard y < 43 else { continue }
                c.px(57 - i % 2, Int(y), i % 2 == 0 ? stoneL : stone)
            }
        }
    }

    let body = PixelCanvas(c.w, c.h)
    drillPose = { p in if let s = crouch { p.signature = s } }
    drawPersona(body, who, t: t, mode: .idle, walking: running, role: .none)
    drillPose = nil
    let ix = Int(dx.rounded()), iy = Int(hop.rounded())
    if running && f < 0.4 {
        // The rush of air behind him as he charges.
        for (k, y) in [27.0, 31, 35].enumerated() {
            let x = 13 + dx, len = 3 + Double(k % 2) * 3 + dx * 0.5
            c.glowLine(x - len, y, x, y, core: C(0xF4F8FF, 0.8), glow: C(0xD8E4F8, 0.35), coreR: 0.4, glowR: 1.2)
        }
    }
    c.paste(body, x: ix, y: -iy)
    if f >= 0.38 && f < 0.44 {
        // The clonk: a white burst where his horn meets the stone.
        let k = (f - 0.38) / 0.06
        for (ax, ay) in [(-1.0, -1.0), (-1.0, 1.0), (-1.4, 0.0), (0.0, -1.4), (0.0, 1.4)] {
            let x = 57 + ax * (1 + k * 3), y = 24 + ay * (1 + k * 3)
            c.px(Int(x.rounded()), Int(y.rounded()), C(0xFFF8D8, 1 - k * 0.5))
        }
    }
    if f >= 0.5 && f < 0.86 {
        // Dizzy: three stars circling over his helmet.
        for i in 0..<3 {
            let a = t * 5 + Double(i) * 2.1
            let x = 28 + cos(a) * 9 + Double(ix), y = 13 + sin(a) * 2
            let col = C(0xFFE860)
            let sx = Int(x.rounded()), sy = Int(y.rounded())
            c.px(sx, sy, col); c.px(sx - 1, sy, col.alpha(0.7)); c.px(sx + 1, sy, col.alpha(0.7))
            c.px(sx, sy - 1, col.alpha(0.7)); c.px(sx, sy + 1, col.alpha(0.7))
        }
    }
}

// MARK: - Bow

/// Bow at the butts: a round target on a stand out in front, an arrow loosed at it every second and a half, each one
/// staying where it struck (now and then dead centre), so they gather in it through the set.
private func drawTargetPractice(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 1.6
    let shooting = d.e > 0.6 && d.length - d.e > 0.8
    standing(c, who, t: t) { p in if shooting { p.fire = (d.e, false); p.firePeriod = period } }
    guard r > 0.15 else { return }
    // The target: seen side on, a tall oval of straw, white, red and gold rings, on a two-legged stand.
    let cx = 63.5, cy = 30.5
    let straw = C(0xC8A060), strawD = C(0x8A6A34)
    line(c, 62, 36, 60, 43, strawD, 0.6); line(c, 65, 36, 67, 43, strawD, 0.6)
    let rings: [(Double, Px)] = [(1, C(0xF0ECE0)), (0.72, C(0xC83838)), (0.46, C(0xF0ECE0)), (0.22, C(0xF0C040))]
    for y in 22...39 {
        for x in 59...68 {
            let dx = (Double(x) + 0.5 - cx) / 4.2, dy = (Double(y) + 0.5 - cy) / 8.2
            let dd = sqrt(dx * dx + dy * dy)
            guard dd <= 1 else { continue }
            var col = straw
            for (rr, ring) in rings where dd <= rr { col = ring }
            if dd > 0.86 { col = dd > 0.94 || dx > 0.5 ? strawD : straw }
            c.px(x, y, col)
        }
    }
    // The arrows: the one in flight, and every one that's landed this set, stuck in the face.
    let arrow = C(0x6A4A2A), head = C(0xC8CCD4), fletch = C(0xF0ECE0)
    func hit(_ k: Int) -> (x: Double, y: Double) {
        let bull = noise(d.seed &+ k * 13) < 0.25
        return bull ? (cx - 1, cy) : (cx - 1.5 + (noise(k * 7 + d.seed) - 0.5) * 2, cy + (noise(k * 11 + d.seed) - 0.5) * 11)
    }
    func stuck(_ h: (x: Double, y: Double), alpha: Double = 1) {
        let y = Int(h.y.rounded()), x = Int(h.x.rounded())
        c.rect(x - 6, y, 6, 1, arrow.alpha(alpha)); c.px(x - 7, y - 1, fletch.alpha(alpha)); c.px(x - 7, y + 1, fletch.alpha(alpha))
        c.px(x - 6, y - 1, fletch.alpha(alpha * 0.8)); c.px(x - 6, y + 1, fletch.alpha(alpha * 0.8))
    }
    let first = Int(ceil(0.6 / period)), last = Int(floor(d.e / period))
    guard last >= first else { return }
    for k in first...last {
        let shot = Double(k) * period
        guard shot < d.length - 0.8 else { break }
        let flight = (d.e - shot) / 0.2
        let h = hit(k)
        if flight >= 1 { stuck(h); continue }
        let x = 50 + (h.x - 50) * flight, y = 34 + (h.y - 34) * flight
        line(c, x - 7, y, x - 1, y, arrow, 0.45)
        c.px(Int(x.rounded()), Int(y.rounded()), head); c.px(Int((x - 7).rounded()), Int(y.rounded()), fletch)
    }
}

// MARK: - Jitsu

/// Jitsu chopping a stack of planks: four boards laid on two piles of bricks in front of him, the gold hand raised
/// high and brought down through the lot, each board snapping a moment after the one above it and folding down into
/// a V, splinters flying; then a fresh stack for the next one.
private func drawPlankStack(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 2.8
    let working = r > 0.5
    let f = working ? frac(d.e / period) : 0
    func swing(_ f: Double) -> Double? {
        if f < 0.08 || f > 0.86 { return nil }
        if f < 0.4 { return -78 - 40 * ease((f - 0.08) / 0.3) }
        if f < 0.47 { let k = (f - 0.4) / 0.07; return -118 + 128 * (1 - pow(1 - k, 3)) }
        if f < 0.74 { return 10 }
        return 10 - 88 * ease((f - 0.74) / 0.12)
    }
    var trail: [Double] = []
    if f > 0.4, f < 0.48, let a = swing(f), let b = swing(f - 0.012), abs(a - b) > 6 { trail = [b, swing(f - 0.024) ?? b] }
    let broke = f >= 0.44 && f < 0.92 ? f - 0.44 : -1

    if r > 0.15 {
        // The bricks: two piles of two, red, mortar between.
        let brick = C(0xA8483A), brickD = C(0x6E2A22), brickL = C(0xC86A54)
        for x in [46, 58] {
            for y in [39, 41] {
                c.rect(x, y, 5, 2, brick); c.rect(x, y, 5, 1, brickL); c.px(x + 4, y + 1, brickD)
            }
            c.rect(x, 43, 5, 1, brickD)
        }
        // The planks, top first.
        let wood = C(0xC89A5A), woodD = C(0x8A6232), woodL = C(0xE8C080)
        let fresh = f >= 0.92 ? (f - 0.92) / 0.08 : 1
        for i in 0..<4 {
            let y = 31 + i * 2
            let snap = broke - Double(i) * 0.012
            if broke < 0 || snap < 0 {
                let a = broke < 0 && f >= 0.92 ? fresh : 1
                c.rect(45, y, 18, 2, wood.alpha(a)); c.rect(45, y, 18, 1, woodL.alpha(a)); c.px(62, y + 1, woodD.alpha(a))
                for x in [48, 55, 59] { c.px(x, y + 1, woodD.alpha(a)) }
                continue
            }
            // Snapped: the two halves fold down into a V from their outer ends.
            let droop = 26 * ease(min(1, snap / 0.06))
            for (pivot, dir) in [((45.5, Double(y) + 0.5), 0.0), ((62.5, Double(y) + 0.5), 180.0)] {
                let a = dir == 0 ? droop : 180 - droop
                let tip = eterniaReach(pivot, a, 8.5)
                line(c, pivot.0, pivot.1, tip.x, tip.y, wood, 0.9)
                let q0 = eterniaReach(pivot, a, 2), q1 = eterniaReach(pivot, a, 7)
                line(c, q0.x, q0.y - 0.6, q1.x, q1.y - 0.6, woodL, 0.3)
            }
        }
        if broke >= 0 && broke < 0.2 {
            // Splinters thrown up off the break, and the flash of the blow.
            let u = broke / 0.2
            for k in 0..<6 {
                let vx = (Double(k) - 2.5) * 2.2, vy = 8 + Double(k % 3) * 2.5
                let x = 54 + vx * u * 2, y = 31 - vy * u + 16 * u * u
                guard y < 43 else { continue }
                c.px(Int(x.rounded()), Int(y.rounded()), k % 2 == 0 ? woodL : wood)
            }
            if broke < 0.04 {
                c.glowLine(54, 31, 54, 31, core: C(0xFFFFFF, 0.9), glow: C(0xFFE28A), coreR: 0.8, glowR: 4,
                           strength: 1 - broke / 0.04)
            }
        }
    }
    standing(c, who, t: t) { p in
        if working, let a = swing(f) { p.melee = a; p.trail = trail }
    }
}

// MARK: - Gwildor

/// Gwildor tuning the Cosmic Key at his side, one note at a time up its row of lights: a light flares, a single note
/// floats up off it in its colour; now and then the note comes out sour (grey and wobbling, drooping instead of
/// rising) and he tries that one again.
private func drawKeyTuning(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    standing(c, who, t: t)
    guard r > 0.5 else { return }
    let beat = 1.1
    let n = Int(floor((d.e - 0.4) / beat))
    guard n >= 0 else { return }
    // Walk the notes so far: a sour one is played again, a good one moves on to the next light.
    var light = 0, sour = false
    for k in 0...n {
        if k > 0 && !sour { light = (light + 1) % 4 }
        sour = noise(d.seed &+ k * 29) < 0.3
    }
    let k = frac((d.e - 0.4) / beat)
    let b = breath(who, t)
    let lights: [UInt32] = [0xFF4A4A, 0xFFE040, 0x40F060, 0x30D8FF]
    let lx = 42 + light * 3, ly = 34 + b
    let col = C(lights[light])
    if k < 0.35 {
        // The light he's sounding, flaring (or flickering dully, for a sour one).
        let on = !sour || Int(t * 16) % 2 == 0
        if on {
            c.rect(lx, ly, 2, 2, sour ? col.alpha(0.6) : C(0xFFFFFF)); c.px(lx + 1, ly + 1, col)
            c.glowLine(Double(lx) + 1, Double(ly) + 1, Double(lx) + 1, Double(ly) + 1, core: C(0xFFFFFF, 0),
                       glow: col.alpha(sour ? 0.3 : 0.8), coreR: 0.1, glowR: 3.2)
        }
    }
    // The note: up and away in the light's colour, or a sour grey one that wobbles, sags and fades.
    let x0 = Double(lx + 1), y0 = Double(ly - 3)
    let x = sour ? x0 + 1 + (Int(t * 14) % 2 == 0 ? 1 : 0) : x0 + 2 + sin(k * 5) * 1.2
    let y = sour ? y0 - 4 * sin(min(1, k * 1.6) * .pi * 0.6) + max(0, k - 0.5) * 6 : y0 - k * 15
    let a = k < 0.6 ? 1 : max(0, 1 - (k - 0.6) / 0.4)
    let nc = sour ? C(0x8A9A7A, a) : col.alpha(a)
    c.pattern(Int(x.rounded()), Int(y.rounded()) - 4, sour ? ["..N", "..N", "NNN", "NN."] : ["..NN", "..N.", "..N.", "NNN.", "NN.."],
              ["N": nc])
}

// MARK: - Horde Trooper

/// A Horde Trooper at rifle drill, marking time on the spot: four counts with the rifle shouldered, a spin of it
/// in the hand, two at the port (slanted out in front), and back to the shoulder. The counts run on the shared
/// clock, so two Troopers practising at once drill in step.
private func drawRifleDrill(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let drilling = d.e > 0.4 && d.length - d.e > 0.4
    guard drilling else { standing(c, who, t: t); return }
    let count = 0.5
    let beats = t / count
    let step = Int(floor(beats)) % 2, ph = frac(beats)
    // The signature's marching legs, stepped to this clock: it reads `beats` from how far through it is.
    standing(c, who, t: t) { p in p.signature = (2 + Double(step) + ph) / 8 }
    // Its shouldered rifle comes off; the drill's own is drawn in the fist.
    let b = breath(who, t)
    wipe(c, columns: 39..<42, rows: 14..<33)
    let n = Int(floor(beats)) % 8
    var angle = -90.0, trail: [Double] = []
    switch n {
    case 4:
        let spin = { (u: Double) -> Double in -90 - 360 * ease(u) }
        angle = spin(ph); trail = [spin(ph - 0.08), spin(ph - 0.16)]
    case 5: angle = -90 + 45 * ease(ph / 0.4)
    case 6: angle = -45
    case 7: angle = -45 - 45 * ease(ph / 0.4)
    default: break
    }
    let hand = (x: 39.5, y: 34.5 + Double(b))
    let dark = C(0x24262E), darkL = C(0x40434E), greyD = C(0x646876), red = C(0xD8202A)
    for (i, a) in trail.enumerated() where abs(a - angle) > 4 {
        let e0 = eterniaReach(hand, a, 4), e1 = eterniaReach(hand, a, 14)
        c.glowLine(e0.x, e0.y, e1.x, e1.y, core: C(0xE8E8F0), glow: C(0xE8E8F0), coreR: 0.5, glowR: 1.4,
                   strength: 0.3 / Double(i + 1))
    }
    eterniaBar(c, hand, angle, from: -4, to: 11, dark, r: 1.0)
    eterniaBar(c, hand, angle, from: -3, to: 10, darkL, r: 0.3)
    eterniaBar(c, hand, angle, from: 11, to: 14, greyD, r: 0.5)
    let sight = eterniaReach(eterniaReach(hand, angle, 7), angle - 90, 1.6)
    c.px(Int(sight.x.rounded()), Int(sight.y.rounded()), red)
    c.rect(38, 33 + b, 3, 3, C(0x9498A6)); c.px(38, 33 + b, C(0xC6CAD4))   // the fist round it
}

// MARK: - Skeleclawd

/// A copy of `src` at half its size: each 2×2 block becomes the colour most of it is (any drawn colour beating an
/// empty one), so a sprite shrinks without losing its thin bits.
private func halfSize(_ src: PixelCanvas) -> PixelCanvas {
    let out = PixelCanvas(src.w, src.h)
    for y in 0..<(src.h / 2) {
        for x in 0..<(src.w / 2) {
            var seen: [(Px, UInt32, Int)] = []
            for (dx, dy) in [(0, 0), (1, 0), (0, 1), (1, 1)] {
                let i = ((y * 2 + dy) * src.w + x * 2 + dx) * 4
                let a = src.buf[i + 3]
                guard a > 0 else { continue }
                let m = 255 / Double(a)
                let px = Px(r: UInt8(min(255, Double(src.buf[i]) * m)), g: UInt8(min(255, Double(src.buf[i + 1]) * m)),
                            b: UInt8(min(255, Double(src.buf[i + 2]) * m)), a: a)
                let key = UInt32(px.r) << 24 | UInt32(px.g) << 16 | UInt32(px.b) << 8 | UInt32(a)
                if let j = seen.firstIndex(where: { $0.1 == key }) { seen[j].2 += 1 } else { seen.append((px, key, 1)) }
            }
            if let best = seen.max(by: { $0.2 < $1.2 }) { out.px(x, y, best.0) }
        }
    }
    return out
}

/// The 3×5 letters of his "HA HA".
private let cackleGlyphs: [Character: [String]] = [
    "H": ["X.X", "X.X", "XXX", "X.X", "X.X"],
    "A": [".X.", "X.X", "XXX", "X.X", "X.X"],
]

/// Skeleclawd practising his cackle on Screeech, perched in front of him at half his size: he shakes his fist and
/// cackles, HAs floating up off him; the bird sits through it unimpressed, then flings up his wings and screeches
/// right back at him, and Skeleclawd shuts up and flinches.
private func drawCacklePractice(_ c: PixelCanvas, _ who: Cast, _ d: DrillPlay, _ t: Double) {
    let r = setRamp(d)
    let period = 4.6
    let on = r > 0.5
    let f = on ? frac(d.e / period) : 0
    let cackling = on && f > 0.08 && f < 0.56
    let reply = on && f > 0.62 && f < 0.9
    let body = PixelCanvas(c.w, c.h)
    standing(body, who, t: t) { p in if cackling { p.signature = 0.5 } }
    c.paste(body, x: reply ? -1 : 0)
    guard r > 0.15 else { return }

    // Screeech: his own art, drawn full size on a canvas of its own, halved and turned to face his master.
    let bird = PixelCanvas(c.w, c.h)
    standing(bird, Cast.villain(EterniaVillain.screeech), t: t) { p in if reply { p.signature = 0.5 } }
    let small = halfSize(bird)
    small.flipHorizontally()
    c.paste(small, x: 0, y: 22)

    // The HAs, rising off him while he cackles.
    guard cackling else { return }
    let ink = C(0xFFF09A)
    for i in 0..<2 {
        let u = frac((d.e - 0.08 * period) / 1.0 + Double(i) / 2)
        let x = 17 + i * 10 + Int((sin(u * 6 + Double(i)) * 1.2).rounded()), y = 10 - Int(u * 8)
        guard y >= 2 else { continue }
        let a = 0.95 * (u < 0.6 ? 1 : 1 - (u - 0.6) / 0.4)   // just short of solid: no outline, so the letters stay crisp
        c.pattern(x, y, cackleGlyphs["H"]!, ["X": ink.alpha(a)])
        c.pattern(x + 4, y, cackleGlyphs["A"]!, ["X": ink.alpha(a)])
    }
}
