import AppKit

// The trailer's set piece. Snake Mountain under a red sky: Skeleclawd, Beast Clawd and Trap Clawd roll out on the
// Roton. They pull up at Castle Greyskull's jawbridge and Skeleclawd raises the Havoc Staff; Orkko pops up to help,
// his spell misfires and a rain cloud opens over Skeleclawd. He-Clawd and Battle Kat leap in, He-Clawd lifts the
// Roton over his head and the crew scatters; Skeleclawd vanishes in a purple puff ("I'll get you for this,
// He-Clawd!"), and Orkko turns to us with the moral of the story.

// MARK: Its beats

/// Shot-local seconds: the cut from Snake Mountain to the jawbridge, then (from the cut) the Roton pulling up, the
/// crew hopping off, the staff raised, Orkko's spell and the rain, the leap, the lift, the scatter, the puff, the moral.
private let toJawbridge = 2.0
private let pullUp = 1.0, hopOff = 1.1, staffUp = 1.5, orkkoPops = 2.4, oops = 2.8, rainFrom = 2.95, rainTo = 5.6
private let leapFrom = 3.5, leapTo = 4.15, liftFrom = 4.45, liftTo = 4.85, scatter = 4.6, puffAt = 5.0, tossAt = 5.6, moralAt = 6.0
/// How high He-Clawd holds the Roton: its tracks this many rows off the floor, well clear of his head.
private let heldRows = 33.0
/// Where everyone stops at the jawbridge (fx units).
private let rotonX = 268.0, skeleX = 200.0, beastX = 246.0, trapX = 292.0, orkkoX = 150.0, katLands = 112.0

/// For the sound, in shot-local seconds.
let eterniaSiegeCut = toJawbridge, eterniaSiegePullUp = toJawbridge + pullUp, eterniaSiegeStaff = toJawbridge + staffUp
let eterniaSiegeOrkko = toJawbridge + orkkoPops, eterniaSiegeOops = toJawbridge + oops
let eterniaSiegeRain = (toJawbridge + rainFrom, toJawbridge + rainTo)
let eterniaSiegeLeap = toJawbridge + leapFrom, eterniaSiegeLift = toJawbridge + liftFrom, eterniaSiegeScatter = toJawbridge + scatter
let eterniaSiegePuff = toJawbridge + puffAt, eterniaSiegeMoral = toJawbridge + moralAt, eterniaSiegeToss = toJawbridge + tossAt
let eterniaSiegeLanded = toJawbridge + leapTo, eterniaSiegeHeld = toJawbridge + liftTo

// MARK: Drawing

/// The Roton side on at fx `x` (its middle), `lift` rows off the floor, nose to the right or (`facing` -1) the left.
private func roton(_ ctx: CGContext, x: Double, lift: Double, facing: Double, moving: Bool, t: Double, turn: Double = 0) {
    let ride = Ride.eterniaRoton
    let c = PixelCanvas(Ride.width, ride.canvasHeight)
    drawRide(c, ride, ramp: 0, engines: moving, gear: true, t: t)
    if facing < 0 { c.flipHorizontally() }
    guard let img = c.makeImage() else { return }
    let w = Double(Ride.width) * 6, h = Double(ride.canvasHeight) * 6
    let r = CGRect(x: (x - Double(Ride.width) / 2) * 6, y: Double(H) - groundY * 6 - 6 + lift * 6, width: w, height: h)
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.translateBy(x: r.midX, y: r.midY); ctx.rotate(by: CGFloat(turn)); ctx.translateBy(x: -r.midX, y: -r.midY)
    ctx.draw(img, in: r)
    ctx.restoreGState()
}

/// He-Clawd lifting, at fx `x` (his middle): his own sprite, sunk `crouch` rows into a squat over his four legs, and
/// (with `hull`, the fx row of the Roton's underside) both arms straight up beside his head, fists pressed under it.
/// Drawn like the kit's `draw`, outlined in Claude's colour.
private func heLifting(_ ctx: CGContext, x: Double, crouch: Int, hull: Double?, t: Double) {
    let s = PixelCanvas(Sprite.width, Sprite.height)
    Cast.hero(EterniaHero.heClawd).draw(s, t: t, mode: .idle, walking: false, role: .rest, asSession: true, habits: false)
    guard let b = s.solidBounds() else { return }
    if crouch > 0 { s.move(columns: 0..<s.w, rows: 0..<(b.maxY - 2), dy: crouch) }
    let pad = 40
    let c = PixelCanvas(Sprite.width, Sprite.height + pad)
    c.paste(s, x: 0, y: pad)
    let top = groundY - 44                                     // the fx row of the sprite's top
    if let hull = hull {
        let reach = Int((hull - (top - Double(pad))).rounded())   // the hull's underside, in canvas rows
        let shoulder = pad + b.maxY - 12 + crouch
        if reach < shoulder - 3 {
            let skin = clawdOrange, lit = C(0xF09A78), shade = C(0xB05A40), ink = C(0x1E1828)
            let leather = C(0x8A5E38), leatherL = C(0xB07C4C)
            let len = shoulder - reach
            // Each arm: a forearm three wide, a bicep bulging to five over the top third, lit on the side towards the
            // middle and shaded on the outside; a bracer at the wrist; the fist wide and flat under the hull, knuckles
            // up. `out` is the side the arm's shadow falls on.
            for (ax, out) in [(12, -1), (42, 1)] {
                let bicep = shoulder - len / 3
                c.rect(ax - 2, reach + 2, 5, len - 2, ink)
                c.rect(ax - 3 + (out > 0 ? 1 : 0), bicep - 1, 6, len / 3 + 1, ink)
                c.rect(ax - 1, reach + 3, 3, len - 3, skin)
                c.rect(ax - 2 + (out > 0 ? 1 : 0), bicep, 4, len / 3, skin)
                c.rect(out > 0 ? ax + 1 : ax - 1, reach + 3, 1, len - 3, shade)
                c.rect(out > 0 ? ax + 2 : ax - 2, bicep, 1, len / 3, shade)
                c.rect(out > 0 ? ax - 1 : ax + 1, bicep + 1, 1, len / 3 - 2, lit)
                c.rect(ax - 1, reach + 4, 3, 3, leather)          // his bracer
                c.rect(ax - 1, reach + 4, 3, 1, leatherL)
                c.rect(ax - 3, reach - 1, 7, 5, ink)              // the fist, flat under the hull
                c.rect(ax - 2, reach, 5, 3, skin)
                c.rect(ax - 2, reach, 5, 1, lit)
                c.px(ax - 1, reach + 1, shade); c.px(ax + 1, reach + 1, shade)   // the knuckles
            }
        }
    }
    c.addOutline(C(AI.claude.hex, 0.92))
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.interpolationQuality = .none
    ctx.draw(img, in: CGRect(x: (x - Sprite.bodyCenterX) * 6, y: Double(H) - (top - Double(pad) + Double(c.h)) * 6,
                             width: Double(c.w) * 6, height: Double(c.h) * 6))
    ctx.restoreGState()
}

/// Dust kicked up off the floor at fx `x`, `k` 0…1 through it: tan puffs rolling out to either side and shrinking.
private func dust(_ c: PixelCanvas, x: Double, k: Double) {
    guard k > 0 && k < 1 else { return }
    for i in 0..<4 {
        let side = i % 2 == 0 ? -1.0 : 1.0
        let far = 4 + Double(i / 2) * 6 + k * 12
        let r = max(1, Int(((1 - k) * 4).rounded()))
        let px = Int((x + side * far).rounded()), py = Int(groundY) - 1 - Int(k * 4) - i / 2 * 2
        c.circle(px, py, r, C(0xC8B48C))
        c.circle(px - 1, py - 1, max(1, r / 2), C(0xE8D8B0))
    }
}

/// The three riders, stood in the Roton behind its hull, only their tops showing over it.
private func riders(_ ctx: CGContext, x: Double, facing: Double, t: Double) {
    let crew: [(Cast, Double)] = [(.villain(EterniaVillain.trapClawd), -16), (.villain(EterniaVillain.beastClawd), 14), (.villain(EterniaVillain.skeleclawd), -2)]
    for (who, dx) in crew {
        var a = Actor(cast: who, x: x + dx * facing, facing: facing, session: false, mode: .idle)
        a.lift = 13 + (Int(t * 8 + dx) % 2 == 0 ? 0.5 : 0)
        draw(a, ctx, t: t)
    }
}

/// A grey rain cloud over fx (`x`, `y`), `size` 0…1 as it billows up, and its rain down to the floor while `rain`.
private func rainCloud(_ c: PixelCanvas, x: Double, y: Double, size: Double, rain: Bool, t: Double) {
    guard size > 0.05 else { return }
    let cx = Int(x), cy = Int(y)
    let body = C(0x7A84A0), lit = C(0xB8C0D8), dark = C(0x4E5670), ink = C(0x262A3A)
    let r = 16.0 * size
    let puffs: [(Double, Double, Double)] = [(-0.8, 0.15, 0.55), (-0.35, -0.25, 0.7), (0.2, -0.35, 0.8), (0.7, 0.05, 0.6), (0.05, 0.2, 0.75)]
    for (dx, dy, pr) in puffs {
        let rr = Int(r * pr) + 1
        c.circle(cx + Int(dx * r), cy + Int(dy * r), rr + 1, ink)
    }
    for (dx, dy, pr) in puffs {
        let rr = Int(r * pr)
        c.circle(cx + Int(dx * r), cy + Int(dy * r) + 1, rr, dark)
        c.circle(cx + Int(dx * r), cy + Int(dy * r), rr, body)
        c.circle(cx + Int(dx * r) - rr / 3, cy + Int(dy * r) - rr / 3, max(1, rr / 2), lit)
    }
    guard rain else { return }
    // The rain: short streaks of pale blue falling fast, and splashes where they land.
    let floor = Int(groundY)
    let fall = Double(floor - cy)
    for i in 0..<16 {
        let sx = cx - Int(r * 0.9) + Int(noise(i * 7 + 500) * r * 1.8)
        let ph = frac(t * 2.4 + noise(i * 7 + 501))
        let sy = cy + 4 + Int(ph * fall)
        c.rect(sx, sy, 1, 4, C(0x9AC8F0))
        c.px(sx, sy - 1, C(0xD8ECFF))
        if ph > 0.85 { c.rect(sx - 1, floor - 1, 3, 1, C(0xB8DCFF)) }
    }
}

/// Orkko's magic going off at fx (`x`, `y`): a pop of lemon and magenta sparkles, `k` 0…1 through it.
private func sparkles(_ c: PixelCanvas, x: Double, y: Double, k: Double) {
    guard k > 0 && k < 1 else { return }
    for i in 0..<10 {
        let a = Double(i) / 10 * 2 * .pi + 0.3
        let rr = 2 + k * 12
        let sx = Int((x + cos(a) * rr).rounded()), sy = Int((y + sin(a) * rr * 0.8).rounded())
        let col = i % 2 == 0 ? C(0xFFF6A0) : C(0xE040C0)
        let size = k < 0.6 ? 2 : 1
        c.rect(sx, sy, size, size, col)
    }
}

/// Snake Mountain under a red sky, the Roton rolling out with the three of them aboard and Skeleclawd cackling.
private func snakeMountain(_ ctx: CGContext, l: Double, t: Double) {
    let c = place(.eterniaSnakeMountain, floorRows: 30, t: t)
    blit(c, ctx)
    // The sky gone red: a flat stepped wash over the sky, lighter towards the floor.
    let sky = Double(H) - 112 * 6
    ctx.setFillColor(hexColor(0xC0201A, 0.32)); ctx.fill(CGRect(x: 0, y: sky, width: Double(W), height: 112 * 6))
    ctx.setFillColor(hexColor(0xFF5030, 0.12)); ctx.fill(CGRect(x: 0, y: sky, width: Double(W), height: 40 * 6))
    let x = lerp(40, 420, (l + 0.2) / (toJawbridge + 0.4))
    riders(ctx, x: x, facing: 1, t: t)
    roton(ctx, x: x, lift: 0, facing: 1, moving: true, t: t)
    if l > 0.55 && l < 1.8 {
        let a = clamp((l - 0.55) / 0.12)
        balloon("Nyah-ha-ha-ha!", ctx, center: CGPoint(x: x * 6 - 160, y: 820), tail: CGPoint(x: x * 6 - 10, y: Double(H) - 112 * 6),
                size: 46, width: 700, alpha: a)
    }
}

/// At the jawbridge, `j` seconds after the cut.
private func jawbridge(_ ctx: CGContext, j: Double, t: Double) {
    blit(place(.eterniaGreyskull, floorRows: 30, t: t), ctx)
    // The Roton: rolling in nose first, then still; He-Clawd pushes it up overhead (shaking with the strain), holds
    // it high, and tosses it away over the castle's ledge.
    let heX = rotonX
    let push = easeOut((j - liftFrom) / (liftTo - liftFrom))
    let straining = j > liftFrom && j < liftTo + 0.45
    let shake: Double = straining ? (Int(t * 20) % 2 == 0 ? 0.5 : -0.5) : 0
    let toss = clamp((j - tossAt) / 0.6)
    var rx = j < liftFrom ? lerp(420, rotonX, easeOut(j / pullUp)) : rotonX + shake
    var rLift = push * heldRows + (straining && push > 0.9 ? abs(shake) : 0)
    if toss > 0 { rx += toss * 210; rLift += sin(toss * .pi) * 40 + toss * 20 }
    if j < hopOff { riders(ctx, x: rx, facing: -1, t: t) }
    roton(ctx, x: rx, lift: rLift, facing: -1, moving: j < pullUp, t: t, turn: -toss * 2.6)
    // The crew hopping off, then (Beast and Trap) running for it.
    let hop = clamp((j - hopOff) / 0.35)
    let run = max(0, j - scatter)
    var beast = Actor(cast: .villain(EterniaVillain.beastClawd), x: lerp(rx + 14, beastX, hop) + run * 70, facing: run > 0 ? 1 : -1,
                      session: false, mode: .idle)
    beast.lift = hop < 1 ? sin(hop * .pi) * 10 + 13 * (1 - hop) : 0
    beast.walking = run > 0
    var trap = Actor(cast: .villain(EterniaVillain.trapClawd), x: lerp(rx - 16, trapX, hop) + run * 80, facing: run > 0 ? 1 : -1,
                     session: false, mode: .idle)
    trap.lift = hop < 1 ? sin(hop * .pi) * 10 + 13 * (1 - hop) : 0
    trap.walking = run > 0
    var skele = Actor(cast: .villain(EterniaVillain.skeleclawd), x: lerp(rx - 2, skeleX, hop), facing: -1, mode: .idle)
    skele.lift = hop < 1 ? sin(hop * .pi) * 12 + 13 * (1 - hop) : 0
    skele.session = false
    skele.grow = lerp(1, 1.5, hop)
    if j > staffUp { skele.role = .ready(urgent: false) }
    let soaked = j > rainFrom + 0.1 && j < puffAt
    if soaked { skele.role = .hit }
    let gone = j > puffAt + 0.16
    // Orkko, popping in out of thin air, then floating to the front for the moral.
    let toFront = easeOut((j - moralAt) / 0.6)
    var orkko = Actor(cast: .hero(EterniaHero.orkko), x: lerp(orkkoX, 160, toFront), facing: 1, mode: .idle)
    orkko.airborne = true
    orkko.lift = 12 + sin(t * 3) * 1.5 + toFront * 4
    orkko.alpha = j > orkkoPops ? 1 : 0
    // He-Clawd and Battle Kat, leaping in from the left.
    let leap = clamp((j - leapFrom) / (leapTo - leapFrom))
    var he = Actor(cast: .hero(EterniaHero.heClawd), x: lerp(-30, heX, easeOut(leap)), facing: 1, mode: .idle)
    he.lift = sin(leap * .pi) * 46
    he.alpha = j > leapFrom ? 1 : 0
    if toss > 0.2 { he.role = .ready(urgent: false) }
    let kLeap = clamp((j - leapFrom - 0.1) / (leapTo - leapFrom))
    var kat = Actor(cast: .hero(EterniaHero.battleKat), x: lerp(-40, katLands, easeOut(kLeap)), facing: 1, mode: .idle)
    kat.lift = sin(kLeap * .pi) * 30
    kat.alpha = j > leapFrom + 0.1 ? 1 : 0
    if kLeap >= 1 { kat.role = .cheer }

    if !gone { draw(skele, ctx, t: t) }
    draw(beast, ctx, t: t)
    draw(trap, ctx, t: t)
    draw(kat, ctx, t: t)
    if j >= leapTo && toss <= 0.2 {
        // Landed: down into a squat under it, then up with both arms, the fists under the hull.
        let squat = j < liftFrom ? 2 : Int((2 * (1 - push)).rounded())
        heLifting(ctx, x: heX + shake, crouch: squat, hull: j < liftFrom ? nil : groundY - rLift, t: t)
    } else {
        draw(he, ctx, t: t)
    }
    draw(orkko, ctx, t: t)

    // The pixel effects over them: Orkko's sparkles, the rain cloud, the purple puff.
    let fx = PixelCanvas(fxW, fxH)
    sparkles(fx, x: orkkoX, y: groundY - 30, k: (j - orkkoPops) / 0.4)
    dust(fx, x: rotonX - 24, k: (j - liftFrom) / 0.55)
    dust(fx, x: rotonX + 24, k: (j - liftFrom - 0.05) / 0.55)
    dust(fx, x: heX, k: (j - leapTo) / 0.4)
    sparkles(fx, x: orkkoX + 10, y: groundY - 40, k: (j - oops + 0.1) / 0.4)
    let cloud = easeOut((j - rainFrom + 0.15) / 0.3) * (1 - clamp((j - rainTo) / 0.3))
    rainCloud(fx, x: skeleX + 2, y: 92, size: cloud, rain: j > rainFrom && j < rainTo, t: t)
    blit(fx, ctx)
    if j > puffAt && j < puffAt + 1.0 {
        let puff = PixelCanvas(Sprite.width, Sprite.height)
        eterniaDrawRetreatPuff(puff, r: min(0.5, (j - puffAt) / 1.0 * 0.6), t: t)
        if let img = puff.makeImage() {
            ctx.saveGState(); ctx.interpolationQuality = .none
            ctx.draw(img, in: CGRect(x: (skeleX - 28) * 6, y: Double(H) - (skele.top + Double(Sprite.height)) * 6,
                                     width: Double(Sprite.width) * 6, height: Double(Sprite.height) * 6))
            ctx.restoreGState()
        }
    }

    // What they say.
    if j > staffUp + 0.1 && j < orkkoPops + 0.2 {
        let a = clamp((j - staffUp - 0.1) / 0.12)
        balloon("Greyskull is mine!", ctx, center: CGPoint(x: skeleX * 6 - 120, y: 880), tail: headPoint(skele), size: 50, width: 700, alpha: a)
    }
    if j > oops && j < leapFrom + 0.1 {
        let a = clamp((j - oops) / 0.1)
        balloon("Oops!", ctx, center: CGPoint(x: orkkoX * 6 - 160, y: 820), tail: headPoint(orkko), size: 50, width: 400, alpha: a)
    }
    if j > puffAt + 0.1 && j < moralAt + 0.15 {
        let a = clamp((j - puffAt - 0.1) / 0.12)
        balloon("I'll get you for this, He-Clawd!", ctx, center: CGPoint(x: 1240, y: 900), tail: CGPoint(x: skeleX * 6, y: 460),
                size: 50, width: 1000, alpha: a)
    }
    if j > moralAt + 0.2 {
        let a = clamp((j - moralAt - 0.2) / 0.15)
        balloon(eterniaMorals[0], ctx, center: CGPoint(x: 1010, y: 880), tail: headPoint(orkko), size: 56, width: 1100, alpha: a)
    }
}

/// The set piece.
func eterniaSiege(_ ctx: CGContext, local l: Double, t: Double) {
    if l < toJawbridge { snakeMountain(ctx, l: l, t: t) } else { jawbridge(ctx, j: l - toJawbridge, t: t) }
    // Out of the white of the title sequence.
    let white = 1 - clamp(l / 0.5)
    if white > 0 { ctx.setFillColor(CGColor(gray: 1, alpha: white)); ctx.fill(fullRect) }
}
