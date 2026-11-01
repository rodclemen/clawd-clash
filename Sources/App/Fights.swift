import Foundation

// How fights work: who takes which role, how shots and blocks play out, and the effects drawn between fighters.


/// What a leader is doing on screen.
enum VaderMode {
    case idle, thinking, working, waiting
    case standGuard     // Claude is idle but its agents are still out on missions
}

/// Role in a fight between two neighbouring Claudes that are both working.
enum FightRole {
    case none
    case duel                    // saber vs saber, both on the shared clock so blades meet
    case shoot(offset: Double)   // blaster: fire at the opponent (bolts are drawn by the FX layer)
    case deflect                 // saber vs blaster: swing to meet each incoming bolt
    case block                   // saber vs lightning: hold the blade into the arc
    case zap                     // lightning (arcs drawn by the FX layer)
    case hit                     // non-saber caught by lightning: shake
    case cheer                   // odd one out: bounce and wave the weapon
    case rest                    // any character leading an idle session: saber off, blaster lowered
    case ready(urgent: Bool)     // a hero whose session needs you: weapon held up (waved, with hops, when urgent)
}

func fightRoles(_ a: Weapon, _ b: Weapon) -> (FightRole, FightRole) {
    switch (a, b) {
    case (.saber, .saber): return (.duel, .duel)
    case (.blaster, .saber): return (.shoot(offset: 0), .deflect)
    case (.saber, .blaster): return (.deflect, .shoot(offset: 0))
    case (.blaster, .blaster): return (.shoot(offset: 0), .shoot(offset: blasterPeriod / 2))
    case (.lightning, .saber): return (.zap, .block)
    case (.saber, .lightning): return (.block, .zap)
    case (.lightning, .blaster): return (.zap, .hit)
    case (.blaster, .lightning): return (.hit, .zap)
    case (.lightning, .lightning): return (.zap, .zap)
    case (.none, _), (_, .none): return (.none, .none)
    }
}

/// Saber fighters close in for a duel; ranged fights keep normal spacing.
func fightIsCloseQuarters(_ a: Weapon, _ b: Weapon) -> Bool { a == .saber && b == .saber }

let blasterPeriod = 0.9

/// A telekinetic grip (`Magic.grip`) in rhythm: how far its victim is lifted, 0…1, at fight time `t`. They're hauled
/// up, held there kicking, dropped, and get a breath before the next.
func gripHold(_ t: Double) -> Double {
    let f = frac(t / gripPeriod) * gripPeriod
    if f < 0.35 { let g = f / 0.35; return 1 - (1 - g) * (1 - g) }
    if f < 1.9 { return 1 }
    if f < 2.1 { return 1 - (f - 1.9) / 0.2 }
    return 0
}
let gripPeriod = 2.6
/// How high a grip holds its victim off the ground, in the victim's own pixels.
let gripHeight = 5.0

/// What happens to a bolt in a blaster-vs-blaster shoot-out. Plain hits stay in the mix, but most shots are saved.
enum BoltOutcome { case hit, duck, collide, shield, ricochet }

/// The outcome of the shot a shooter (by its clock offset) is firing at time `t`. A fixed cycle, so the effects
/// layer and the defender's own sprite (ducking) always agree, and both shooters run through it out of step.
func boltOutcome(t: Double, offset: Double, defenderArmoured: Bool) -> BoltOutcome {
    let cycle: [BoltOutcome] = [.hit, .duck, .collide, .shield, .ricochet, .duck, .collide, .hit, .ricochet, .shield, .duck]
    let n = Int(floor((t + offset) / blasterPeriod)) + (offset > 0 ? 4 : 0)
    let o = cycle[((n % cycle.count) + cycle.count) % cycle.count]
    return o == .ricochet && !defenderArmoured ? .duck : o   // no armour to bounce it off: get down instead
}

/// How far (0…1) a defender squats to let a bolt from the shooter with clock `offset` whizz over its head.
func duckAmount(t: Double, shooterOffset: Double, armoured: Bool) -> Double {
    guard boltOutcome(t: t, offset: shooterOffset, defenderArmoured: armoured) == .duck else { return 0 }
    let f = frac((t + shooterOffset) / blasterPeriod)
    // Down as the bolt closes in, held while it passes, back up after.
    let down = min(max((f - 0.12) / 0.12, 0), 1), up = min(max((f - 0.55) / 0.15, 0), 1)
    return down * (1 - up)
}
let boltArrival = 0.4          // fraction of the period a bolt spends in flight
private let deflectPeak = -15.0   // the top of `deflectAngle`'s swing (-75 + 60): keep the two in step

func frac(_ v: Double) -> Double { v - floor(v) }

func deflectAngle(_ t: Double) -> Double {
    let d = frac(t / blasterPeriod) - boltArrival
    return -75 + 60 * exp(-pow(d / 0.07, 2))
}


func drawCape(_ c: PixelCanvas, t: Double, speed: Double, color: Px, edge: Px, extra: Double = 0) {
    for y in 27...43 where y + c.oy <= 43 {      // hem ends on the feet's row (43), never below
        let k = Double(y - 27) / 16
        let hw = 10.5 + k * (4.5 + extra)
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((Sprite.bodyCenterX - hw + sway).rounded())
        let r = Int((Sprite.bodyCenterX + hw + sway).rounded()) - 1
        c.rect(l, y, r - l + 1, 1, color)
        c.px(l, y, edge)
        c.px(r, y, edge)
    }
}

// MARK: - Effects

func drawSparks(_ c: PixelCanvas, x: Double, y: Double, t: Double, size: Double = 3) {
    let seed = Int(t * 30)
    c.glowLine(x, y, x, y, core: white, glow: C(0xFFD25A), coreR: 0.8, glowR: 2.2)
    for i in 0..<6 {
        let a = noise(seed * 13 + i) * 2 * .pi
        let r = 1 + noise(seed * 17 + i) * size
        c.px(Int(x + cos(a) * r), Int(y + sin(a) * r), noise(seed + i) > 0.5 ? white : C(0xFFC23A))
    }
}

/// One side of a fight, in FX-canvas units (leader pixels, y down from the top of a leader canvas).
struct Fighter {
    let weapon: Weapon
    let x: Double                        // body centre
    let k: Double                        // sprite scale relative to a leader (agents are 2/3)
    let top: Double                      // y of this sprite's canvas top
    let side: Double                     // +1 facing right, -1 facing left
    var muzzle: (x: Double, y: Double)   // in its own canvas coordinates
    var armoured = false                 // bolts ricochet off it
    var pivot = Sprite.hand              // where its weapon swings from (`Cast.weaponPivot`), own canvas coordinates
    var shot: ShotStyle = .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A))   // what its shots look like
    var magic: Magic = .lightning        // what its magic looks like
    var missesEverything = false         // its bolts never land (`Persona.missesEverything`)
    var shotTurns: [(shot: ShotStyle, muzzle: (x: Double, y: Double))] = []   // `Persona.shotTurns`

    /// This fighter with `who`'s shots and magic.
    func dressed(as who: Cast) -> Fighter {
        var f = self
        f.shot = who.persona.shot; f.magic = who.persona.magic; f.missesEverything = who.persona.missesEverything
        f.shotTurns = who.persona.shotTurns
        return f
    }

    /// A point given in the sprite's own (right-facing) canvas coordinates.
    func point(_ cx: Double, _ cy: Double) -> (x: Double, y: Double) {
        (x + side * (cx - Sprite.bodyCenterX) * k, top + cy * k)
    }
    var hand: (x: Double, y: Double) { point(pivot.x, pivot.y) }
    var body: (x: Double, y: Double) { point(Sprite.bodyCenterX + 9, 31) }
    /// Where this fighter's blade sits along its length `u` (in its own pixels) at `angle`.
    func blade(_ angle: Double, _ u: Double, dx: Double = 0) -> (x: Double, y: Double) {
        let r = angle * .pi / 180, h = point(pivot.x + dx, pivot.y)
        return (h.x + side * cos(r) * u * k, h.y + sin(r) * u * k)
    }
}

/// One bolt of a blaster-vs-blaster shoot-out, played out per `outcome`. `f` is the shooter's phase in its period.
private func drawShootout(_ c: PixelCanvas, f: Double, t: Double, m: (x: Double, y: Double), me: Fighter, foe: Fighter,
                          outcome: BoltOutcome,
                          bolt: ((x: Double, y: Double), (x: Double, y: Double), Double, Double) -> Void) {
    let arrive = boltArrival
    switch outcome {
    case .hit where me.missesEverything:
        // A Stormtrouper's sure shot: it sails high and wide past the shoulder and away, and the target doesn't flinch.
        let head = foe.point(Sprite.bodyCenterX + 4, 21)
        let wide = (x: foe.x - foe.side * 48 * foe.k, y: head.y - 9 * foe.k)
        let total = arrive * 1.7
        if f < total {
            let g = f / total
            bolt(m, wide, g, g > 0.8 ? (1 - g) / 0.2 : 1)
        }

    case .hit:
        if f < arrive { bolt(m, foe.body, f / arrive, 1) }
        else if f < arrive + 0.06 { drawSparks(c, x: foe.body.x, y: foe.body.y, t: t, size: 2) }

    case .duck:
        // Aimed at head height; the defender squats (see duckAmount) and it whizzes over, out behind them.
        let head = foe.point(Sprite.bodyCenterX + 4, 21)
        let behind = (x: foe.x - foe.side * 40 * foe.k, y: head.y - 2 * foe.k)
        let total = arrive * 1.6
        if f < total {
            let g = f / total
            let fade = g > 0.8 ? (1 - g) / 0.2 : 1
            bolt(m, behind, g, fade)
        }

    case .collide:
        // The defender fires back at the same moment; the bolts meet in the middle and burst.
        let fm = foe.point(foe.muzzle.x + 2, foe.muzzle.y + 0.5)
        let meet = (x: (m.x + fm.x) / 2, y: (m.y + fm.y) / 2)
        let flight = arrive * 0.55
        if f < flight {
            let g = f / flight
            bolt(m, meet, g, 1)
            bolt(fm, meet, g, 1)
        } else if f < flight + 0.16 {
            let g = (f - flight) / 0.16
            // a bright starburst that grows and fades
            let r = (2 + g * 7) * me.k, a = 1 - g
            for i in 0..<8 {
                let ang = Double(i) * .pi / 4 + g * 0.6
                c.glowLine(meet.x + cos(ang) * r * 0.35, meet.y + sin(ang) * r * 0.35, meet.x + cos(ang) * r, meet.y + sin(ang) * r,
                           core: C(0xFFF4D0).alpha(a), glow: C(0xFF6A2A).alpha(a * 0.8), coreR: 0.5, glowR: 1.6)
            }
            c.glowLine(meet.x, meet.y, meet.x, meet.y, core: C(0xFFFFFF).alpha(a), glow: C(0xFFD25A).alpha(a), coreR: 1.2, glowR: 3.2 * (1 - g * 0.5))
        }

    case .shield:
        // A blue bubble flickers up around the defender and the bolt splashes on it.
        let centre = foe.point(Sprite.bodyCenterX + 1, 31)
        let r = 15 * foe.k
        let front = (x: centre.x + foe.side * r, y: m.y + (centre.y - m.y) * 0.3)
        if f < arrive {
            bolt(m, front, f / arrive, 1)
        } else if f < arrive + 0.3 {
            let g = (f - arrive) / 0.3
            let a = (1 - g) * (0.6 + 0.4 * sin(g * 40))   // flicker
            let n = 22
            for i in 0..<n {
                let a0 = Double(i) / Double(n) * 2 * .pi, a1 = Double(i + 1) / Double(n) * 2 * .pi
                c.glowLine(centre.x + cos(a0) * r, centre.y + sin(a0) * r * 1.05, centre.x + cos(a1) * r, centre.y + sin(a1) * r * 1.05,
                           core: C(0xBFF0FF).alpha(a * 0.9), glow: C(0x3AA8FF).alpha(a * 0.6), coreR: 0.4, glowR: 1.4)
            }
            if g < 0.35 { c.glowLine(front.x, front.y, front.x, front.y, core: C(0xFFFFFF).alpha(1 - g / 0.35),
                                     glow: C(0x3AA8FF).alpha(1 - g / 0.35), coreR: 1, glowR: 3) }
        }

    case .ricochet:
        // Armour: a "tink" of sparks and the bolt glances off up into the sky.
        let impact = foe.point(Sprite.bodyCenterX + 8, 27)
        if f < arrive {
            bolt(m, impact, f / arrive, 1)
        } else if f < arrive + 0.4 {
            let g = (f - arrive) / 0.4
            if g < 0.18 { drawSparks(c, x: impact.x, y: impact.y, t: t, size: 2) }
            let x = impact.x + foe.side * g * 22 * foe.k, y = impact.y - g * 40
            drawProjectile(c, me.shot, from: (x - foe.side * 2.5, y + 4), head: (x, y), t: t, alpha: 1 - g)
        }
    }
}

/// Whether `drawFightFX` has anything to draw at `t`: a saber duel only sparks while the blades clash.
func fightFXVisible(t: Double, _ a: Weapon, _ b: Weapon) -> Bool {
    switch fightRoles(a, b).0 {
    case .duel: return duelPose(t).clash
    case .none: return false
    default: return true
    }
}

/// Bolts, deflections, lightning and clash sparks between two fighters (villains or agents).
func drawFightFX(_ c: PixelCanvas, t: Double, left: Fighter, right: Fighter) {
    let (lRole, rRole) = fightRoles(left.weapon, right.weapon)

    // Saber duel: sparks where the two (mirrored, possibly different-sized) blades cross.
    if case .duel = lRole {
        let p = duelPose(t)
        guard p.clash else { return }
        let r = p.angle * .pi / 180
        let a = left.point(left.pivot.x + p.dx, left.pivot.y), b = right.point(right.pivot.x + p.dx, right.pivot.y)
        let cs = cos(r), sn = sin(r)
        guard cs > 0.2 else { return }
        var s: Double, u: Double
        if abs(sn) < 0.05 {
            s = (b.x - a.x) / cs / 2; u = s
        } else {
            let sum = (b.x - a.x) / cs, diff = (b.y - a.y) / sn
            s = (sum + diff) / 2; u = (sum - diff) / 2
        }
        guard s >= 3 * left.k, s <= 23 * left.k, u >= 3 * right.k, u <= 23 * right.k else { return }
        drawSparks(c, x: a.x + cs * s, y: a.y + sn * s, t: t)
        return
    }

    for (me, role, foe, foeRole) in [(left, lRole, right, rRole), (right, rRole, left, lRole)] {
        switch role {
        case .shoot(let offset):
            var me = me
            if !me.shotTurns.isEmpty {
                // Whose turn it is to shoot: its look, and where it leaves from.
                let turn = me.shotTurns[shotTurn(t: t + offset, period: blasterPeriod, count: me.shotTurns.count)]
                me.shot = turn.shot; me.muzzle = turn.muzzle
            }
            let f = frac((t + offset) / blasterPeriod)
            let m = me.point(me.muzzle.x + 2, me.muzzle.y + 0.5)
            func bolt(from a: (x: Double, y: Double), to b: (x: Double, y: Double), _ g: Double, alpha: Double = 1) {
                let x = a.x + (b.x - a.x) * g, y = a.y + (b.y - a.y) * g
                drawProjectile(c, me.shot, from: a, head: (x, y), t: t, alpha: alpha)
            }
            if case .shoot = foeRole {
                drawShootout(c, f: f, t: t, m: m, me: me, foe: foe,
                             outcome: boltOutcome(t: t, offset: offset, defenderArmoured: foe.armoured), bolt: bolt)
                continue
            }
            var impact = foe.body
            var deflects = false
            if case .deflect = foeRole {
                // Where the defender's blade sits at the peak of its swing; the bolt is aimed there.
                let pr = deflectPeak * .pi / 180
                let u = min(max((m.y - foe.hand.y) / sin(pr) / foe.k, 4), 20)
                impact = foe.blade(deflectPeak, u)
                deflects = true
            }
            if f < boltArrival {
                bolt(from: m, to: impact, f / boltArrival)
            } else if f < boltArrival + 0.06 {
                drawSparks(c, x: impact.x, y: impact.y, t: t, size: 2)
            }
            if deflects && f >= boltArrival && f < boltArrival + 0.35 {
                // Bounced bolt flies off up and back over the shooter's head.
                let g = (f - boltArrival) / 0.35
                let x = impact.x - foe.side * -g * 30, yy = impact.y - g * 34
                drawProjectile(c, me.shot, from: (x - foe.side * 3, yy + 3.4), head: (x, yy), t: t, alpha: 1 - g)
            }
        case .zap:
            let h = me.hand
            let from = (h.x, h.y - 2 * me.k)
            let to: (x: Double, y: Double)
            switch foeRole {
            case _ where me.magic.gadget || me.magic.notes: to = foe.body   // a touch, a gadget or music goes for the foe itself
            case .block: to = foe.blade(-60, 13)
            case .zap: to = ((me.x + foe.x) / 2, h.y - 4)
            default: to = foe.body
            }
            // A grip keeps the fight's own clock, so its haze tightens just as the victim leaves the ground.
            drawMagic(c, me.magic, from: from, to: (to.x, to.y), t: me.magic.grip ? t : t + me.side)
            // Music sparks only as each blast lands (drawn with it); gadgets and touches don't spark.
            if !me.magic.gadget && !me.magic.notes { drawSparks(c, x: to.x, y: to.y, t: t + me.side, size: 2.5) }
        default:
            break
        }
    }
}

// MARK: - Speech bubbles (drawn separately so they can flip to whichever side has room)

enum Bubble { static let width = 18, height = 13 }

/// What a Claude's bubble says. There's never real text: dots, "!", "?", zZz or a number.
enum BubbleKind: Equatable {
    case thinking
    case waiting        // needs your attention
    case unknown        // session without hooks: we can't tell what it's doing
    case sleeping       // idle for a long time
    case agentsOut(Int) // done for now, but this many of its agents are still out: it's waiting on them, not on you
    case background     // done for now, but something it left running (a build, a render) will wake it: an hourglass
}

/// Compact bubble, it only ever holds three thinking dots, a "!", a "?", zZz, how many agents are out or an hourglass.
/// `tailRight`: the bubble sits left of the head, so its tail points right. Only the frame is
/// mirrored for that, the symbol inside never reads backwards.
func drawBubble(_ c: PixelCanvas, kind: BubbleKind, t: Double, urgent: Bool = false, tailRight: Bool = false) {
    let border: Px
    switch kind {
    case .waiting: border = sin(t * (urgent ? 14 : 6)) > 0 ? C(0xE0303A) : C(0xFF6A6A)
    case .unknown: border = C(0xC98A1A)
    case .sleeping: border = C(0x6A5ACD)
    case .agentsOut: border = C(0x5B8FE8)   // the blue of an agent's name tag
    case .background: border = C(0x2FA89A)
    case .thinking: border = outline
    }
    c.rect(5, 1, 11, 7, white)
    c.rect(4, 2, 13, 5, white)
    c.rect(5, 0, 11, 1, border); c.rect(5, 8, 11, 1, border)
    c.rect(3, 2, 1, 5, border); c.rect(17, 2, 1, 5, border)
    c.px(4, 1, border); c.px(16, 1, border); c.px(4, 7, border); c.px(16, 7, border)
    c.rect(1, 10, 2, 2, white); c.px(1, 10, border)
    c.px(0, 12, border)
    if tailRight { c.flipHorizontally(); c.ox = -3 }   // box moved from x 3...17 to 0...14
    defer { c.ox = 0 }
    switch kind {
    case .waiting:
        c.rect(9, 2, 2, 3, border)
        c.rect(9, 6, 2, 1, border)
    case .unknown:
        c.pattern(8, 2, ["XXX", "..X", ".X.", "...", ".X."], ["X": border])
    case .sleeping:
        // zZz, drifting gently
        let off = Int(t * 1.5) % 2
        c.pattern(5, 3 + off, ["ZZ", ".Z", "ZZ"], ["Z": border.alpha(0.6)])
        c.pattern(8, 2, ["ZZZ", ".Z.", "ZZZ"], ["Z": border])
        c.pattern(12, 4 - off, ["ZZ", ".Z", "ZZ"], ["Z": border.alpha(0.6)])
    case .thinking:
        let step = Int(t * 3) % 4
        for i in 0..<3 where step > i { c.rect(6 + i * 3, 3, 2, 2, border) }
    case .background:
        // An hourglass: the sand runs from the top bulb to the bottom one in 3 s, a grain falling through the neck,
        // then it turns over (drawn the right way up again at once, since the full bulb is now on top).
        let sand = C(0xE8B04A), p = (t / 3).truncatingRemainder(dividingBy: 1)
        c.pattern(8, 2, ["XXXXX", ".X.X.", "..X..", ".X.X.", "XXXXX"], ["X": border])
        if p < 0.5 { c.px(10, 3, sand) }                      // the top bulb, until it's run out
        if p > 0.25 { c.px(10, 5, sand) }                     // the bottom one, filling
        if Int(t * 4) % 2 == 0 && p < 0.9 { c.px(10, 4, sand) } // a grain in the neck
    case .agentsOut(let n):
        // The number out, in a 3×5 pixel figure (9 and over: a "+").
        let digits: [[String]] = [["XXX", "X.X", "X.X", "X.X", "XXX"], [".X.", "XX.", ".X.", ".X.", "XXX"],
                                  ["XXX", "..X", "XXX", "X..", "XXX"], ["XXX", "..X", ".XX", "..X", "XXX"],
                                  ["X.X", "X.X", "XXX", "..X", "..X"], ["XXX", "X..", "XXX", "..X", "XXX"],
                                  ["XXX", "X..", "XXX", "X.X", "XXX"], ["XXX", "..X", ".X.", ".X.", ".X."],
                                  ["XXX", "X.X", "XXX", "X.X", "XXX"]]
        let figure = n >= 1 && n <= 8 ? digits[n] : n > 8 ? ["...", ".X.", "XXX", ".X.", "..."] : digits[0]
        c.pattern(9, 2, figure, ["X": border])
    }
}

/// Bobbing marker over the Claude whose terminal you're in right now.
func drawFocusCaret(_ c: PixelCanvas) {
    c.pattern(0, 0, [".Y.", "YYY", ".Y."], ["Y": C(0xFFE14A)])
}

/// A fighting pair's clock offset, 0…10 s: the same for the same two characters (from their keys), different from
/// pair to pair, so several fights on screen are out of step with each other while each pair stays in step.
func fightPhaseOffset(_ a: String, _ b: String) -> Double {
    var h: UInt64 = 0xCBF2_9CE4_8422_2325   // FNV-1a: stable across launches, unlike hashValue
    for byte in (min(a, b) + "|" + max(a, b)).utf8 { h = (h ^ UInt64(byte)) &* 0x100_0000_01B3 }
    return Double(h % 10_000) / 1000
}
