import Foundation

// Every character is drawn the same way: `drawPersona` works out what it's doing this frame (a `Pose`: walking,
// fighting, idle habits, waiting for you…), its `Persona.draw` draws the costume and weapon in that pose, and
// `drawPersona` adds the shared effects on top (muzzle flash and solo practice shots, magic streams, smoke).
//
// Writing a character's drawing function (`(PixelCanvas, Pose) -> Void`), facing right on the 72×52 canvas:
//   - the canvas origin (`c.ox`, `c.oy`) is already shifted by `p.dx`, `p.hop` (fight footwork, hops, sitting);
//   - legs: `drawLegs(c, look, step: p.step)` (they fold up by themselves when it's sitting);
//   - then the body and everything above the legs `p.breathe` (0 or -1) higher: `c.oy += p.breathe`;
//   - a melee weapon at `p.melee` degrees (0 forward, -90 straight up), pivoting on `Persona.pivot`; nil = put away
//     (on its back, at its belt, shield on the arm); `p.trail` holds earlier angles of a fast swing, for a smear;
//   - a held gun `p.gunY` higher or lower than its resting place (recoil, raised to check it);
//   - a magic caster's hand raised `p.armRaise` pixels; the stream itself is drawn for you;
//   - `p.flying`: on the move through the air, draw it in flight; `p.signature`: 0…1 through its signature move.
// Restore nothing: `drawPersona` resets the canvas offsets afterwards.

struct Pose {
    let who: Cast
    let t: Double              // the shared clock (both sides of a fight are in step on it)
    let lt: Double             // its own clock, so solo moves aren't in lockstep with everyone else's
    let mode: VaderMode
    let role: FightRole
    let walking: Bool
    var flying = false         // a flyer on the move: draw it in flight
    var seated = false
    var urgent = false
    var step = -1              // walk cycle for `drawLegs`: -1 standing, 0/1 which legs are lifted
    var breathe = 0            // -1 or 0: the upper body's breathing bob
    var dx = 0, hop = 0        // whole-sprite shift, already applied to the canvas origin
    var melee: Double?         // melee weapon angle in degrees; nil = put away
    var trail: [Double] = []   // earlier angles of a fast swing
    var fire: (t: Double, bolt: Bool)?   // ranged: firing on this clock (`bolt`: the shot is drawn in-canvas too)
    var firePeriod = blasterPeriod       // seconds between its shots
    var recoil = 0             // 1 as the gun kicks
    var gunLift = 0            // idle habit: weapon raised to eye level
    var smoke: Double?         // idle habit: 0…1 through blowing the smoke off the barrel
    var zap: Bool?             // magic: true = casting (stream drawn in-canvas), false = crackling in the hand
    var armRaise = 0           // casting hand raised this many pixels
    var signature: Double?     // 0…1 through its signature move
    var capeSpeed = 1.6        // how hard a cape billows

    /// Doing nothing in particular: weapon lowered or put away.
    var resting: Bool {
        if walking { return false }
        switch role {
        case .rest: return true
        case .none: return mode == .idle || mode == .thinking
        default: return false
        }
    }
    /// Waiting for you: weapon held up (waved and hopping when `urgent`).
    var ready: Bool {
        if case .ready = role { return true }
        if case .none = role { return mode == .waiting && !walking }
        return false
    }
    var cheering: Bool { if case .cheer = role { return true } else { return false } }
    var hit: Bool { if case .hit = role { return true } else { return false } }
    /// Where to draw a held gun relative to its resting height: recoil and the idle check lift it.
    var gunY: Int { -recoil - gunLift }
}

/// Draw `who` this frame. `airborne`: a flyer on the move (the renderer lifts it off the ground too).
/// `aloft`: lifted off the ground in place (a flyer's sortie, or fighting from the air): it gets an air wash under its feet.
func drawPersona(_ c: PixelCanvas, _ who: Cast, t: Double, mode: VaderMode, walking: Bool, role: FightRole,
                 urgent: Bool = false, sitting: Bool = false, airborne: Bool = false, aloft: Bool = false) {
    let persona = who.persona
    var role = role
    // A session's mood becomes a role: waiting for you holds the weapon up, the rest is resting.
    var mode = mode
    if case .rest = role { mode = .idle }
    if case .ready(let u) = role { mode = .waiting; role = .none; _ = u }
    let lt = t + Double(who.id) * 0.77
    // Star Wars draws guns as Clawd Wars did: never raised while waiting or cheering, the flash at the resting
    // muzzle, and heroes don't raise theirs to check them either (the smoke shows what they're doing).
    let classic = who.universe.module.poseStyle == .classic
    var p = Pose(who: who, t: t, lt: lt, mode: mode, role: role, walking: walking)
    p.flying = airborne || (walking && persona.motion == .fly)
    p.urgent = urgent
    p.step = p.flying ? -1 : walkStep(t, walking)
    p.breathe = walking ? (p.step == 0 ? -1 : 0) : (sin(lt * 2 * .pi / 2.6) > 0.35 ? -1 : 0)
    var unengaged = false
    if case .none = role { unengaged = true }
    if case .rest = role { unengaged = true }
    p.seated = sitting && persona.canSit && !walking && unengaged && (mode == .idle || mode == .standGuard)

    if walking {
        if mode != .idle && mode != .thinking && persona.weapon == .saber { p.melee = -60 }
    } else {
        switch mode {
        case .idle, .thinking, .standGuard:
            if mode == .standGuard { p.melee = -65 + 3 * sin(t * 2.2); p.capeSpeed = 2.2 }   // on guard, its agents out
            if case .rest = role {} else if case .none = role {} else { break }
            guard mode != .thinking, let h = idleHabit else { break }
            switch h.kind {
            case .flourish:
                // Weapon swung up, round once and back down.
                if h.p > 0.08 && h.p < 0.92 {
                    let len = h.length, start = t - h.e
                    let spin = { (u: Double) -> Double in
                        let s = min(1, max(0, ((u - start) / len - 0.25) / 0.5))
                        return -70 - 360 * (0.5 - 0.5 * cos(s * .pi))
                    }
                    p.melee = spin(t)
                    if h.p > 0.25 && h.p < 0.75 { p.trail = saberTrail(t, pose: spin) }
                }
            case .checkWeapon:
                if classic && !who.isDark {
                    if h.p > 0.4 { p.smoke = (h.p - 0.4) / 0.6 }
                } else {
                    p.gunLift = Int((2 * habitArc(min(1, h.p / 0.55), hold: 0.5)).rounded())
                    if h.p > 0.45 { p.smoke = (h.p - 0.45) / 0.55 }
                }
            case .crackle:
                p.zap = false; p.armRaise = 2
            case .signature:
                p.signature = h.p
            default: break
            }
        case .waiting:
            p.melee = urgent ? -90 + 25 * sin(t * 12) : -90 + 2 * sin(t * 3)
            if persona.weapon == .blaster && !classic { p.gunLift = 1 }
            if persona.weapon == .lightning { p.zap = false; p.armRaise = 2 }
            if urgent { p.hop = cheerHop(t * 1.5); p.breathe = 0 }
        case .working:
            p.capeSpeed = 4.5
            switch role {
            case .duel:
                let d = duelPose(t)
                p.melee = d.angle; p.dx = Int(d.dx.rounded()); p.hop = Int(d.dy.rounded()); p.breathe = 0
                p.trail = saberTrail(t, pose: { duelPose($0).angle })
            case .deflect:
                p.melee = deflectAngle(t)
                p.trail = saberTrail(t, pose: deflectAngle)
            case .block:
                p.melee = -60 + 2 * sin(t * 37)
                p.dx = -1
            case .shoot(let offset):
                p.fire = (t + offset, false)
            case .zap:
                p.zap = false; p.armRaise = 2      // the stream between the two is drawn by the fight layer
            case .hit:
                p.dx = noise(Int(t * 30)) > 0.5 ? 1 : -1
                p.hop = noise(Int(t * 30) + 7) > 0.6 ? -1 : 0
            case .cheer:
                p.hop = cheerHop(t); p.breathe = 0
                switch persona.weapon {
                case .saber: p.melee = -95 + 18 * sin(t * 9)
                case .lightning: p.zap = false; p.armRaise = 2
                case .blaster: if !classic { p.gunLift = -cheerHop(t) + 1 }
                case .none: break
                }
            case .none, .rest, .ready:
                switch persona.weapon {
                case .saber:
                    let k = kataPose(lt)
                    p.melee = k.angle; p.dx = Int(k.dx.rounded()); p.hop = Int(k.dy.rounded()); p.breathe = 0
                    p.trail = saberTrail(lt)
                case .blaster:
                    if soloDrill?.kind == .skyShots {
                        p.fire = (lt, false)                 // the flash here; the shot goes up (below)
                        if !classic { p.gunLift = 1 }
                    } else if let solo = persona.soloFire { p.fire = (t + solo.phase, true); p.firePeriod = solo.period }
                    else { p.fire = (lt, true) }
                case .lightning:
                    if let d = soloDrill, d.kind == .skyCast || d.kind == .portal { p.armRaise = 3 }
                    else { p.zap = true; p.armRaise = 2 }
                case .none: break
                }
            }
        }
    }
    drillPose?(&p)
    if let fire = p.fire { p.recoil = shotRecoil(t: fire.t, period: p.firePeriod) }
    if p.seated { p.hop += 4 }
    // Hovering: a few pixels off the ground, bobbing gently (not when sitting down, or flying past).
    var float = 0
    if persona.motion == .hover && !p.seated && !p.flying { float = -3 + (sin(lt * 2.4) > 0 ? -1 : 0) }

    if p.cheering, !walking { drawCheerSparkles(c, t: t) }
    if aloft, !p.flying { drawAirWash(c, t: t) }
    seatedPose = p.seated
    poseLift = max(0, -(p.hop + float)); poseShift = p.dx
    let baseY = c.baseY
    c.baseY += float
    c.ox = p.dx; c.oy = p.hop
    persona.draw(c, p)

    // Shared effects, from the same origin the art used for its upper body.
    c.ox = p.dx; c.oy = p.hop + p.breathe
    switch persona.weapon {
    case .blaster:
        if let fire = p.fire {
            var (style, muzzle) = (persona.shot, persona.muzzle)
            if !persona.shotTurns.isEmpty {
                (style, muzzle) = persona.shotTurns[shotTurn(t: fire.t, period: p.firePeriod, count: persona.shotTurns.count)]
            }
            drawMuzzleShot(c, t: fire.t, period: p.firePeriod, muzzle: muzzle, style: style, bolt: fire.bolt,
                           gunY: classic ? 0 : p.gunY, classic: classic)
            if soloDrill?.kind == .skyShots {
                drawSkyShot(c, t: fire.t, period: p.firePeriod,
                            muzzle: (muzzle.x, muzzle.y + Double(classic ? 0 : p.gunY)), style: style)
            }
        }
        if let smoke = p.smoke { drawBarrelSmoke(c, x: persona.muzzle.x, y: persona.muzzle.y + Double(classic ? 0 : p.gunY), smoke) }
    case .lightning:
        let hand = (persona.pivot.x, persona.pivot.y - Double(p.armRaise))
        if let d = soloDrill, d.kind == .skyCast || d.kind == .portal, !walking {
            let on = d.kind == .skyCast ? drawSkyCast(c, persona.magic, hand: hand, t: lt, seed: d.seed)
                                        : drawPortal(c, persona.magic, t: lt, seed: d.seed)
            if !on { p.zap = false }                 // between goes: crackling in the hand
        }
        if p.zap == true {
            // Practising alone, at nobody: a stream may run off the frame's edge, but whatever lands (rings and arcs
            // swelling as they arrive) stops short of it, so it isn't cut in half. A touch or a grip has nothing to land on: its
            // glow and rising motes gather round the caster's own hand.
            let to = persona.magic.touch || persona.magic.grip ? hand : (70 - persona.magic.landing, hand.1 - (classic ? 2.5 : 2))
            drawMagic(c, persona.magic, from: hand, to: to, t: t)
        } else if p.zap == false {
            // Crackling between the fingers (the Emperor's, as in Clawd Wars: pale blue and white, a pixel further on).
            let i = Int(t * 20), dx = classic ? 0 : -1
            c.px(Int(hand.0) + Int(noise(i) * 3) + dx, Int(hand.1) + Int(noise(i + 1) * 3) - 1, classic ? C(0xBFD8FF) : persona.magic.glow)
            c.px(Int(hand.0) + Int(noise(i + 2) * 3) + dx, Int(hand.1) + Int(noise(i + 3) * 3) - 1, classic ? white : persona.magic.core)
        }
    default: break
    }
    c.ox = 0; c.oy = 0; c.baseY = baseY
    seatedPose = false
}


// MARK: - Flight

/// How high (0…1 of `flightHeight`) a flyer is on a sortie at `t`: now and then it takes off, hangs in the air and comes
/// back down. Ranged and magic flyers do it in fights too, more often, and keep shooting from up there; melee flyers
/// stay down to duel. `seed` (0…1) keeps everyone on their own schedule. Stateless, so the screen saver can use it.
func sortieAir(_ who: Cast, seed: Double, fighting: Bool, t: Double) -> Double {
    guard who.motion == .fly else { return 0 }
    if fighting && !(who.weapon == .blaster || who.weapon == .lightning) { return 0 }
    let period = fighting ? 9.0 : 26.0, share = fighting ? 0.4 : 0.15
    let f = frac(t / period + seed)
    guard f < share else { return 0 }
    let k = f / share, ramp = 0.2
    if k < ramp { return 0.5 - 0.5 * cos(k / ramp * .pi) }
    if k > 1 - ramp { return 0.5 - 0.5 * cos((1 - k) / ramp * .pi) }
    return 1
}

/// Air pushed down under someone hanging in the air: a few pale streaks flickering below the feet.
func drawAirWash(_ c: PixelCanvas, t: Double) {
    let i = Int(t * 18)
    for k in 0..<3 {
        let x = 20 + k * 6 + Int(noise(i + k * 5) * 3), y = 45 + Int(noise(i * 3 + k) * 4)
        c.rect(x, y, 3 + Int(noise(i + k) * 3), 1, C(0xE8F4FF, 0.35 + 0.3 * noise(i * 7 + k)))
    }
}

// MARK: - Shots

/// 1 while a gun on clock `t` is kicking back from a shot.
func shotRecoil(t: Double, period: Double = blasterPeriod) -> Int { frac(t / period) < 0.15 ? 1 : 0 }

/// Muzzle flash, and (solo practice) the shot flying off to the canvas edge. `classic`: Clawd Wars' bolt, which runs
/// 5 px ahead of where it's got to.
func drawMuzzleShot(_ c: PixelCanvas, t: Double, period: Double = blasterPeriod, muzzle: (x: Double, y: Double),
                    style: ShotStyle, bolt: Bool, gunY: Int, classic: Bool = false) {
    let f = frac(t / period)
    let mx = muzzle.x, my = muzzle.y + Double(gunY)
    var flash = true                     // no flash from a bow, a web-shooter, an ice stream or a throw
    switch style { case .beam, .web, .ice, .arrow, .thrown: flash = false; default: break }
    if flash, f < 0.08 {
        c.rect(Int(mx), Int(my) - 1, 2, 3, C(0xFFE27A))
        c.px(Int(mx) + 2, Int(my), C(0xFFF6C8))
    }
    guard bolt, f < 0.4 else { return }
    let x = mx + 2 + f / 0.4 * (Double(Sprite.width) - mx) + (classic ? 5 : 0)
    drawProjectile(c, style, from: (mx + 2, my + 0.5), head: (x, my + 0.5), t: t)
}

/// A shot `style` in flight: its head at `head`, fired from `from`. `alpha` fades it.
func drawProjectile(_ c: PixelCanvas, _ style: ShotStyle, from a: (x: Double, y: Double), head h: (x: Double, y: Double),
                    t: Double, alpha: Double = 1) {
    let len = max(hypot(h.x - a.x, h.y - a.y), 0.01)
    let ux = (h.x - a.x) / len, uy = (h.y - a.y) / len
    switch style {
    case .energy(let core, let glow):
        c.glowLine(h.x - ux * 5, h.y - uy * 5, h.x, h.y, core: core.alpha(alpha), glow: glow.alpha(alpha), coreR: 0.6, glowR: 1.8)
    case .beam(let core, let glow):
        let flicker = 0.85 + 0.15 * sin(t * 50)
        c.glowLine(a.x, a.y, h.x, h.y, core: core.alpha(alpha), glow: glow.alpha(alpha), coreR: 0.7, glowR: 2.2,
                   strength: flicker)
    case .bullet:
        c.glowLine(h.x - ux * 3, h.y - uy * 3, h.x, h.y, core: C(0xFFF6D0).alpha(alpha), glow: C(0xFFB02A).alpha(alpha * 0.7),
                   coreR: 0.4, glowR: 1)
    case .arrow:
        let shaft = C(0x6A4A2A).alpha(alpha), tip = C(0xC8CCD4).alpha(alpha), fletch = C(0xC83A2A).alpha(alpha)
        for k in 0..<7 { c.px(Int((h.x - ux * Double(k)).rounded()), Int((h.y - uy * Double(k)).rounded()), k == 0 ? tip : shaft) }
        c.px(Int((h.x + ux).rounded()), Int((h.y + uy).rounded()), tip)
        c.px(Int((h.x - ux * 7).rounded()), Int((h.y - uy * 7 - 1).rounded()), fletch)
        c.px(Int((h.x - ux * 7).rounded()), Int((h.y - uy * 7 + 1).rounded()), fletch)
    case .web:
        c.glowLine(a.x, a.y, h.x, h.y, core: C(0xF4F4F8).alpha(alpha * 0.85), glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
        c.rect(Int(h.x) - 1, Int(h.y) - 1, 3, 3, C(0xF4F4F8).alpha(alpha))
        c.px(Int(h.x) + 2, Int(h.y), C(0xF4F4F8).alpha(alpha * 0.6)); c.px(Int(h.x), Int(h.y) - 2, C(0xF4F4F8).alpha(alpha * 0.6))
    case .fire:
        let flick = noise(Int(t * 30))
        c.glowLine(h.x - ux * 6, h.y - uy * 6, h.x - ux * 2, h.y - uy * 2, core: C(0xFFB02A).alpha(alpha * 0.6),
                   glow: C(0xFF4A1A).alpha(alpha * 0.5), coreR: 0.6, glowR: 1.6)
        c.glowLine(h.x, h.y, h.x, h.y, core: C(0xFFF2B0).alpha(alpha), glow: C(0xFF7A1A).alpha(alpha),
                   coreR: 1.2, glowR: 2.4 + flick)
    case .ice:
        c.glowLine(a.x, a.y, h.x, h.y, core: C(0xE8FAFF).alpha(alpha * 0.8), glow: C(0x7FD8FF).alpha(alpha * 0.6),
                   coreR: 0.5, glowR: 1.6)
        c.rect(Int(h.x) - 1, Int(h.y) - 1, 3, 3, C(0xE8FAFF).alpha(alpha))
    case .card:
        c.glowLine(h.x - 1, h.y - 1, h.x + 1, h.y + 1, core: C(0xFFE8F8).alpha(alpha), glow: C(0xFF3AC8).alpha(alpha),
                   coreR: 0.8, glowR: 2)
    case .thrown(let col):
        let spin = Int(t * 24) % 2
        if spin == 0 { c.rect(Int(h.x) - 1, Int(h.y), 3, 1, col.alpha(alpha)) } else { c.rect(Int(h.x), Int(h.y) - 1, 1, 3, col.alpha(alpha)) }
        c.px(Int(h.x), Int(h.y), white.alpha(alpha * 0.8))
    }
}

/// One of `options`, by the next digit of `v` (counting in base `options.count`), so a run of variants changes the
/// earliest pick first.
private func pick<T>(_ v: inout Int, _ options: [T]) -> T {
    let o = options[v % options.count]
    v /= options.count
    return o
}

/// A magic or energy stream from `a` to `b`: forked like lightning, or a steady wavering ray. `m.variant` tweaks the
/// shape a little (forks, kinks, thickness, speed…); variant 0 is the classic look.
func drawMagic(_ c: PixelCanvas, _ m: Magic, from a: (Double, Double), to b: (Double, Double), t: Double) {
    var seed = Int(t * 20)
    let dx = b.0 - a.0, dy = b.1 - a.1
    let len = max(sqrt(dx * dx + dy * dy), 0.01)
    let nx = -dy / len, ny = dx / len
    var v = m.variant
    if m.grip {
        // No beam: the clenched hand glows, brighter while it holds. A faint thread wavers from it to whoever's held,
        // and a coil of light wraps round them, squeezing in tight as they're lifted and loosening as they drop, wisps
        // curling up off it. The coil is drawn as a smooth band, never as loose specks.
        let k = gripHold(t)
        c.glowLine(a.0, a.1, a.0 + 0.5, a.1, core: m.core.alpha(0.25 + 0.35 * k), glow: m.glow.alpha(0.2 + 0.4 * k),
                   coreR: 0.5, glowR: 2.6 + 1.2 * k)
        guard k > 0.02 else { return }
        // `b` is the side of them facing the caster: the coil is centred on the body behind it, round its middle below
        // the eyes, and wider than the body so it wraps round rather than sitting on it.
        let cx = b.0 + (b.0 >= a.0 ? 8 : -8), cy = b.1 + 3
        let r = 14 - 2.5 * k + 0.4 * sin(t * 31)
        let wob = sin(t * 17) * 0.8
        c.glowLine(a.0, a.1, (a.0 + b.0) / 2, (a.1 + b.1) / 2 + wob, core: m.core.alpha(0.18 * k), glow: m.glow.alpha(0.22 * k),
                   coreR: 0.3, glowR: 1.3)
        c.glowLine((a.0 + b.0) / 2, (a.1 + b.1) / 2 + wob, b.0, b.1, core: m.core.alpha(0.18 * k), glow: m.glow.alpha(0.22 * k),
                   coreR: 0.3, glowR: 1.3)
        let n = 40, spin = t * 2.2
        func at(_ i: Int) -> (Double, Double) {
            let ang = Double(i) / Double(n) * 2 * .pi + spin
            return (cx + cos(ang) * r, cy + sin(ang) * r * 0.3)
        }
        for i in 0..<n where i % 10 != 9 {   // a few gaps, so it reads as a coil turning
            let p0 = at(i), p1 = at(i + 1)
            c.glowLine(p0.0, p0.1, p1.0, p1.1, core: m.core.alpha(0.9 * k), glow: m.glow.alpha(0.55 * k), coreR: 0.5, glowR: 1.7)
        }
        for i in 0..<5 {
            let f = frac(t * 0.8 + Double(i) / 5)
            let x = cx + (Double(i) - 2) * 3 + sin(t * 3 + Double(i)) * 1.2, y = cy - r * 0.3 - 1 - f * 8
            c.px(Int(x.rounded()), Int(y.rounded()), (i % 2 == 0 ? m.core : m.glow).alpha(k * 0.75 * (1 - f)))
        }
        return
    }
    if m.touch {
        // No stream: the fingertip lights up, and whoever it points at glows, motes of light drifting up round them.
        let pulse = 0.75 + 0.25 * sin(t * 7)
        c.glowLine(a.0, a.1, a.0 + 0.5, a.1, core: m.core.alpha(pulse), glow: m.glow.alpha(pulse), coreR: 0.9, glowR: 3.2)
        c.glowLine(b.0 - 1, b.1, b.0 + 1, b.1, core: m.glow.alpha(0.18 * pulse), glow: m.glow.alpha(0.25 * pulse),
                   coreR: 3, glowR: 9)
        for k in 0..<6 {
            let f = frac(t * 0.6 + Double(k) / 6)
            let x = b.0 + (noise(k * 7 + Int(t * 0.6 + Double(k) / 6) * 3) - 0.5) * 14, y = b.1 + 6 - f * 16
            c.px(Int(x.rounded()), Int(y.rounded()), (k % 2 == 0 ? m.core : m.glow).alpha(1 - f))
        }
        return
    }
    if m.rings {
        // Mind powers, sent in pulses: a burst of rings leaves the caster, swelling as they go and fading as they land,
        // then a pause; the thread of light between them throbs with each pulse, and so does the caster's end. The
        // variant sets the rhythm: rings in a burst, how close they follow each other, the beat, single or double rings.
        let burst = pick(&v, [2, 3, 1, 4]), gap = pick(&v, [0.15, 0.24, 0.1])
        let period = pick(&v, [1.1, 0.8, 1.45]), double = pick(&v, [false, true])
        let grow = pick(&v, [3.4, 2.4, 4.4]), dots = pick(&v, [2, 3, 1])
        let travel = 0.62 * period + 0.1
        let beat = frac(t / period), throb = max(0, 1 - beat / 0.35)   // 1 as a pulse leaves, easing off
        c.glowLine(a.0, a.1, b.0, b.1, core: m.core.alpha(0.12 + 0.3 * throb), glow: m.glow.alpha(0.12 + 0.25 * throb),
                   coreR: 0.4, glowR: 1.4)
        c.glowLine(a.0, a.1, a.0 + 0.5, a.1, core: m.core.alpha(0.4 + 0.6 * throb), glow: m.glow.alpha(0.3 + 0.5 * throb),
                   coreR: 0.6 + 0.6 * throb, glowR: 1.8 + 1.6 * throb)
        let cycle = floor(t / period)
        for n in [cycle - 1, cycle] {
            for i in 0..<burst {
                let age = t - (n * period + Double(i) * gap)
                guard age >= 0, age < travel else { continue }
                let g = age / travel, f = 1 - (1 - g) * (1 - g)    // fast off the caster, slowing as it reaches
                let cx = a.0 + dx * f, cy = a.1 + dy * f, r = 1.2 + f * grow
                let fade = min(1, g / 0.12) * min(1, (1 - g) / 0.25)
                for (rr, dim) in double ? [(r, 1.0), (max(0.8, r - 1.6), 0.6)] : [(r, 1.0)] {
                    for s in 0..<24 {
                        let ang = Double(s) / 24 * 2 * .pi
                        let x = Int((cx + cos(ang) * rr).rounded()), y = Int((cy + sin(ang) * rr * 0.85).rounded())
                        c.px(x, y, (s % dots == 0 ? m.core : m.glow).alpha(fade * dim))
                    }
                }
            }
        }
        return
    }
    if m.notes {
        // Music: blasts in a heartbeat rhythm, bam!.bam!.. then a pause. Each is a big thick arc punching out fast and
        // slowing as it lands (fading, so it doesn't sit over the foe's face), a note riding behind it.
        let period = 1.5, beats = [0.0, 0.28], travel = 0.75
        let ang0: Double = atan2(dy, dx)
        let cycle = floor(t / period)
        for n in [cycle - 1, cycle] {
            for (bi, beat) in beats.enumerated() {
                let age = t - (n * period + beat)
                guard age >= 0, age < travel else { continue }
                let g = age / travel
                let f = 1 - (1 - g) * (1 - g)                    // fast out, easing in
                let cx = a.0 + dx * f, cy = a.1 + dy * f, r = 3 + f * 7
                let fade = min(1, (1 - g) / 0.3)
                for s in -8...8 {
                    let ang = ang0 + Double(s) / 8 * 1.15
                    for w in 0..<2 {
                        let x = Int((cx + cos(ang) * (r + Double(w))).rounded()), y = Int((cy + sin(ang) * (r + Double(w))).rounded())
                        c.px(x, y, (abs(s) < 5 ? m.core : m.glow).alpha(fade * (w == 0 ? 1 : 0.6)))
                    }
                }
                if g > 0.8 { drawSparks(c, x: b.0, y: b.1, t: t, size: 2.5) }   // bam!
                let fn = max(0, f - 0.12), bob = sin(g * 10 + Double(bi)) * 1.5
                let x = Int((a.0 + dx * fn + nx * bob).rounded()), y = Int((a.1 + dy * fn + ny * bob).rounded())
                let col = (bi == 0 ? m.core : m.glow).alpha(fade)
                c.rect(x, y + 1, 2, 2, col); c.rect(x + 1, y - 2, 1, 3, col); c.px(x + 2, y - 2, col)
            }
        }
        return
    }
    if m.waves {
        // Sound and force: arcs pulsing out towards the target, wider as they go.
        let count = pick(&v, [5, 4, 6]), spread = pick(&v, [1.1, 0.8, 1.4]), grow = pick(&v, [4.0, 3, 5.5])
        let speed = pick(&v, [1.3, 1.0, 1.7])
        let ang0: Double = atan2(dy, dx)
        for k in 0..<count {
            let f: Double = frac(t * speed + Double(k) / Double(count))
            let cx: Double = a.0 + dx * f, cy: Double = a.1 + dy * f, r: Double = 1.5 + f * grow
            let fade: Double = 1 - f * 0.5
            for s in -5...5 {
                let ang: Double = ang0 + Double(s) / 5 * spread
                let x = Int((cx + cos(ang) * r).rounded()), y = Int((cy + sin(ang) * r).rounded())
                c.px(x, y, (abs(s) < 3 ? m.core : m.glow).alpha(fade))
            }
        }
        return
    }
    if m.rcCar {
        // A little DeLorean on the ground under the stream's line, racing from the caster's feet to the target's,
        // two trails of fire burning behind it; the remote's signal pulses off the hand.
        let ground = a.1 + 12, sgn: Double = dx >= 0 ? 1 : -1
        let f = min(frac(t * 0.7) / 0.85, 1)
        let x0 = a.0 + sgn * 2, x = x0 + (b.0 - 4 * sgn - x0) * f
        let gy = Int(ground.rounded())
        var tx = x0
        while sgn * (x - tx) > 3 {
            let fade = 0.35 + 0.65 * (1 - abs(x - tx) / max(abs(x - x0), 1))
            let flick = noise(seed * 13 + Int(tx))
            c.px(Int(tx.rounded()), gy + 1, (flick > 0.5 ? C(0xFFD040) : C(0xFF6A1A)).alpha(fade))
            c.px(Int(tx.rounded()), gy - 1, (flick > 0.3 ? C(0xFF8A2A) : C(0xFFE07A)).alpha(fade * 0.8))
            if flick > 0.75 { c.px(Int(tx.rounded()), gy - 2, C(0xFFB040).alpha(fade * 0.6)) }
            tx += sgn
        }
        if f < 1 {
            let ix = Int(x.rounded())
            let body = C(0xC8CCD4), dark = C(0x4A4E58)
            // Side on, nose to the right: a wedge of brushed steel, a dark window, two black wheels.
            let rows = ["...ddd...", ".bbdddbb.", "bbbbbbbbb", "bwwbbbwwb", ".ww...ww."]
            for (ry, row) in rows.enumerated() {
                for (rx, ch) in row.enumerated() {
                    let col: Px? = ch == "b" ? body : ch == "d" ? dark : ch == "w" ? ink : nil
                    if let col { c.px(ix + Int(sgn) * (rx - 4), gy - 4 + ry, col) }
                }
            }
            c.px(ix - Int(sgn) * 4, gy - 2, C(0xFF4A2A))   // the tail light
        }
        // The signal off the remote's aerial: small arcs, pulsing.
        let ring = Int(t * 6) % 3
        for s in -1...1 { c.px(Int(a.0 + sgn * Double(2 + ring)), Int(a.1) - 3 + s - ring, C(0xFFE07A).alpha(0.8 - Double(ring) * 0.2)) }
        return
    }
    if m.spell {
        // Sorcery: a ribbon of sparkles winding along the path, each one twinkling.
        let count = pick(&v, [9, 7, 11]), wobble = pick(&v, [2.2, 1.4, 3.0]), cross = pick(&v, [false, true])
        let speed = pick(&v, [0.7, 0.5, 0.95])
        let star = cross ? [(1, 1), (-1, -1), (1, -1), (-1, 1)] : [(1, 0), (-1, 0), (0, 1), (0, -1)]
        c.glowLine(a.0, a.1, b.0, b.1, core: m.core.alpha(0.25), glow: m.glow.alpha(0.25), coreR: 0.3, glowR: 1.2)
        for k in 0..<count {
            let f: Double = frac(t * speed + Double(k) / Double(count))
            let wob: Double = sin(f * 10 + t * 6 + Double(k)) * wobble
            let x: Double = a.0 + dx * f + nx * wob, y: Double = a.1 + dy * f + ny * wob
            let tw: Double = 0.5 + 0.5 * sin(t * 18 + Double(k) * 2.3)
            let ix = Int(x.rounded()), iy = Int(y.rounded())
            c.px(ix, iy, m.core.alpha(0.6 + 0.4 * tw))
            if tw > 0.45 {   // a little four-point star
                for (ox, oy) in star { c.px(ix + ox, iy + oy, m.glow.alpha(tw)) }
            }
        }
        return
    }
    if !m.jagged {
        // A steady ray, wavering; some have bright beads running along it.
        var width = pick(&v, [(0.7, 2.2), (0.5, 1.6), (1.0, 2.8)]), beads = pick(&v, [false, true])
        if m.thick { width = (1.0, 2.8) }
        let wobble = pick(&v, [1.4, 0.5, 2.4]), waves = pick(&v, [9.0, 5, 14])
        let speed = pick(&v, [14.0, 8, 20])
        let n = 8
        var prev = a
        for i in 1...n {
            let f = Double(i) / Double(n)
            let off = i == n ? 0 : sin(f * waves + t * speed) * wobble
            let q = (a.0 + dx * f + nx * off, a.1 + dy * f + ny * off)
            c.glowLine(prev.0, prev.1, q.0, q.1, core: m.core, glow: m.glow, coreR: width.0, glowR: width.1,
                       strength: 0.85 + 0.15 * noise(seed + i))
            prev = q
        }
        if beads {
            for k in 0..<3 {
                let f = frac(t * 1.4 + Double(k) / 3)
                let off = sin(f * waves + t * speed) * wobble
                c.glowLine(a.0 + dx * f + nx * off, a.1 + dy * f + ny * off, a.0 + dx * f + nx * off + 0.5, a.1 + dy * f + ny * off,
                           core: white, glow: m.glow, coreR: 0.9, glowR: 2.4)
            }
        }
        return
    }
    // Lightning: forked bolts, re-struck many times a second. Each bolt after the first is a shade of its own (a
    // little brighter or darker, the hue nudged one way or the other) and re-strikes on its own beat, so the strands
    // read as separate and alive rather than one thick line.
    let bolts = m.bolts ?? pick(&v, [2, 1, 3]), n = pick(&v, [6, 4, 8, 5, 7]), spread = pick(&v, [7.0, 5, 9.5])
    let sprigs = pick(&v, [false, true]), width = pick(&v, [(0.5, 1.8), (0.7, 2.3)])
    let rate = pick(&v, [20.0, 12, 30])
    for bolt in 0..<bolts {
        seed = Int(t * rate * (1 + 0.23 * Double(bolt)) + Double(bolt) * 0.37) + bolt * 101
        let core = boltShade(m.core, bolt), glow = boltShade(m.glow, bolt)
        var prev = a
        for i in 1...n {
            let f = Double(i) / Double(n)
            // Later strands wander further from the line, so they part from the first instead of hugging it.
            let off = i == n ? 0 : (noise(seed * 31 + bolt * 7 + i) - 0.5) * spread * (1 + 0.45 * Double(bolt))
            let q = (a.0 + dx * f + nx * off, a.1 + dy * f + ny * off)
            c.glowLine(prev.0, prev.1, q.0, q.1, core: core, glow: glow, coreR: width.0, glowR: width.1,
                       strength: bolt == 0 ? 1 : bolt == 1 ? 0.6 : 0.45)
            if sprigs, bolt == 0, i < n, noise(seed * 17 + i) > 0.45 {
                // A little side fork off the kink.
                let side: Double = noise(seed * 5 + i) > 0.5 ? 1 : -1
                c.glowLine(q.0, q.1, q.0 + dx / len * 2 + nx * side * 3, q.1 + dy / len * 2 + ny * side * 3,
                           core: core, glow: glow, coreR: 0.4, glowR: 1.3, strength: 0.55)
            }
            prev = q
        }
    }
}

/// Bolt `k`'s shade of `c`: the first as it is, the others brighter or darker and their hue turned a little, in turn.
private func boltShade(_ c: Px, _ k: Int) -> Px {
    guard k > 0 else { return c }
    var r = Double(c.r) / 255, g = Double(c.g) / 255, b = Double(c.b) / 255
    let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
    var h = 0.0, s = mx == 0 ? 0 : d / mx, val = mx
    if d > 0 {
        h = mx == r ? (g - b) / d : mx == g ? 2 + (b - r) / d : 4 + (r - g) / d
        h = (h / 6).truncatingRemainder(dividingBy: 1); if h < 0 { h += 1 }
    }
    let odd = k % 2 == 1
    h += odd ? 0.035 : -0.04
    s = min(1, s * (odd ? 0.8 : 1.1))
    val = odd ? min(1, val * 1.25 + 0.08) : val * 0.78
    h -= floor(h)
    let i = Int(h * 6) % 6, f = h * 6 - floor(h * 6)
    let p = val * (1 - s), q = val * (1 - s * f), u = val * (1 - s * (1 - f))
    switch i {
    case 0: (r, g, b) = (val, u, p)
    case 1: (r, g, b) = (q, val, p)
    case 2: (r, g, b) = (p, val, u)
    case 3: (r, g, b) = (p, q, val)
    case 4: (r, g, b) = (u, p, val)
    default: (r, g, b) = (val, p, q)
    }
    return Px(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: c.a)
}

// MARK: - A stand-in

/// Plain Clawd in a costume colour, holding something that says how it fights. For a character whose art isn't
/// drawn yet.
func drawStandIn(_ c: PixelCanvas, _ p: Pose, body: Px, trim: Px) {
    let look = Look(body: body, shade: trim, leg: trim, arm: body)
    drawLegs(c, look, step: p.step)
    c.oy += p.breathe
    drawBody(c, look, armRight: p.armRaise)
    c.rect(18, 26, 20, 3, trim)
    switch p.who.weapon {
    case .saber:
        let r = (p.melee ?? 75) * .pi / 180
        c.glowLine(Sprite.hand.x, Sprite.hand.y, Sprite.hand.x + cos(r) * 12, Sprite.hand.y + sin(r) * 12,
                   core: C(0xC8CCD4), glow: C(0x000000, 0), coreR: 0.8, glowR: 0.9)
    case .blaster:
        c.oy += p.gunY
        c.rect(40, 31, 9, 2, C(0x2A2A30)); c.rect(40, 33, 2, 2, C(0x2A2A30))
    default: break
    }
}
