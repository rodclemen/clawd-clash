import Foundation

// Clawds of the Universe's rides (`Ride`), drawn nose to the right on the ships' `Ride.width`×`Ride.height` canvas
// with the ride kit (Rides.swift). Eternia's heroes get the green-and-orange Wind Raider, swooping in on its swept
// wings with the tail fin up; She-Clawd and the Great Rebellion get Swift Wind, the white winged unicorn with the
// pink mane, his wings beating as he comes in; Skeleclawd's Evil Warriors (Jitsu and the film's mercenaries too)
// get the Roton, rolling in along the ground with its ring of blades spinning; the Horde gets a bat-winged skiff, and
// Hordakk his own grey rocket with the red bat on its side. Who rides what is `eterniaRide(_:)` below.

extension Ride {
    /// The Wind Raider: lands on its skids, `ramp` lets a little ladder down from the open cockpit.
    static let eterniaWindRaider = Ride(key: "eterniaWindRaider", boardingOffset: 6) { c, ramp, engines, gear, t in
        eterniaDrawWindRaider(c, ramp: ramp, engines: engines, gear: gear, t: t)
    }

    /// Swift Wind: flies in with his wings beating, lands on his four hooves and lowers his near wing to climb on.
    /// Six rows taller than a ship's canvas (drawn six rows down), so his raised wings and horn have room above him.
    static let eterniaSwiftWind = Ride(key: "eterniaSwiftWind",
                                       canvasHeight: Ride.height + 6) { c, ramp, engines, gear, t in
        let s = PixelCanvas(c.w, c.h)
        s.oy = 6
        eterniaDrawSwiftWind(s, ramp: ramp, flying: engines, gear: gear, t: t)
        eterniaRim(s, C(0x8A8EAC))
        c.paste(s)
    }

    /// The Roton: rolls in along the ground on its tracks, its blades spinning; its side hatch drops open to board.
    static let eterniaRoton = Ride(key: "eterniaRoton", arrival: .drives) { c, ramp, engines, _, t in
        eterniaDrawRoton(c, ramp: ramp, moving: engines, t: t)
    }

    /// The Horde skiff: a grey hull under a raised bat wing, the Horde's bat on its side, a ramp and landing legs.
    static let eterniaHordeSkiff = Ride(key: "eterniaHordeSkiff", boardingOffset: 11) { c, ramp, engines, gear, t in
        eterniaDrawHordeSkiff(c, ramp: ramp, engines: engines, gear: gear, t: t)
    }

    /// Hordakk's rocket: grey, a red nose and red bat-wing fins, the bat on its side; a ramp and three landing legs.
    static let eterniaHordeRocket = Ride(key: "eterniaHordeRocket", boardingOffset: 10) { c, ramp, engines, gear, t in
        eterniaDrawHordeRocket(c, ramp: ramp, engines: engines, gear: gear, t: t)
    }
}

/// Every ride, for Preview's sheet.
let eterniaRides: [Ride] = [.eterniaWindRaider, .eterniaSwiftWind, .eterniaRoton, .eterniaHordeSkiff,
                            .eterniaHordeRocket]

/// The ride that picks `c` up when its agent is done; nil: it walks (or flies) off on its own.
/// - The Masters, Gwildor too: the Wind Raider. Not Granamyr: a dragon that size flies off on his own wings.
/// - She-Clawd, Adorra and the Great Rebellion: Swift Wind. Not Spirit or Swift Wind himself: the same horse in two
///   guises, never on stage together, so neither waits for the other.
/// - Skeleclawd and the Evil Warriors, Jitsu, the film's mercenaries and their Dark Troopers: the Roton.
/// - The Horde and its troopers: the skiff; Hordakk his rocket.
/// - On foot (or wing): King Hiss, Count Marzo, Shokoti, Horde Prime (only ever smoke and a hand), the Imp and
///   Screeech (they fly), Light Hope (a pillar of light), Loo-Kee and HEM.
func eterniaRide(_ c: Cast) -> Ride? {
    guard c.universe == .eternia else { return nil }
    if c.isDark {
        switch EterniaVillain(rawValue: c.index) {
        case .skeleclawd?, .evilLynn?, .beastClawd?, .trapClawd?, .triClawdps?, .merClawd?, .kobraKhan?, .clawdful?,
             .webstor?, .whiplash?, .spikor?, .twoBad?, .faker?, .panthor?, .stinkor?, .jitsu?, .blade?, .saurod?,
             .karg?, .darkTrooper?:
            return .eterniaRoton
        case .hordakk?:
            return .eterniaHordeRocket
        case .shadowWeaver?, .katra?, .scorpia?, .mantenna?, .hordeTrooper?, .leach?, .grizzlor?, .modulok?,
             .multiBot?, .entrapta?, .octavia?, .rattlor?, .tungLashor?, .vultak?:
            return .eterniaHordeSkiff
        default:
            return nil
        }
    }
    switch EterniaHero(rawValue: c.index) {
    case .heClawd?, .orkko?, .princeAddam?, .battleKat?, .cringer?, .teelah?, .manAtClawds?, .sorceress?, .kingRandor?,
         .queenMarlena?, .stratos?, .ramClawd?, .manEClawds?, .mekaneck?, .buzzOff?, .clawdfist?, .roboto?, .mossClawd?,
         .syClawdne?, .snoutSpout?, .zodac?, .gwildor?:
        return .eterniaWindRaider
    case .sheClawd?, .adorra?, .bow?, .glimmer?, .madameRazz?, .kowl?, .queenAngella?, .clawdstaspella?, .frosta?,
         .seaHawk?, .mermista?, .perfuma?, .peekablue?, .netossa?, .flutterina?, .stonedar?:
        return .eterniaSwiftWind
    default:
        return nil
    }
}

// MARK: - Shared

/// A polygon filled row by row (even-odd), for fins, wings and blades.
private func eterniaFill(_ c: PixelCanvas, _ pts: [(Double, Double)], _ col: Px) {
    let ys = pts.map(\.1)
    guard let lo = ys.min(), let hi = ys.max() else { return }
    for y in Int(lo.rounded(.down))...Int(hi.rounded(.up)) {
        let fy = Double(y) + 0.5
        var xs: [Double] = []
        for i in pts.indices {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            guard (a.1 <= fy && b.1 > fy) || (b.1 <= fy && a.1 > fy) else { continue }
            let k: Double = (fy - a.1) / (b.1 - a.1)
            xs.append(a.0 + (b.0 - a.0) * k)
        }
        xs.sort()
        var i = 0
        while i + 1 < xs.count {
            let x0 = Int((xs[i] - 0.5).rounded(.up)), x1 = Int((xs[i + 1] - 0.5).rounded(.down))
            if x1 >= x0 { c.rect(x0, y, x1 - x0 + 1, 1, col) }
            i += 2
        }
    }
}

/// Every near-white pixel along the silhouette of what's drawn on `s` turned `rim`: a white coat inside the app's white
/// outline otherwise has no edge at all.
private func eterniaRim(_ s: PixelCanvas, _ rim: Px) {
    var edge: [(Int, Int)] = []
    for y in 0..<s.h {
        for x in 0..<s.w where s.isDrawn(x, y) {
            let i = (y * s.w + x) * 4
            guard s.buf[i + 3] == 255, min(s.buf[i], s.buf[i + 1], s.buf[i + 2]) >= 0xC0 else { continue }
            if !s.isDrawn(x - 1, y) || !s.isDrawn(x + 1, y) || !s.isDrawn(x, y - 1) || !s.isDrawn(x, y + 1) {
                edge.append((x, y))
            }
        }
    }
    let (ox, oy, by) = (s.ox, s.oy, s.baseY)
    s.ox = 0; s.oy = 0; s.baseY = 0
    for (x, y) in edge { s.px(x, y, rim) }
    s.ox = ox; s.oy = oy; s.baseY = by
}

/// The Horde's red bat, ears up and wings spread, 11 wide and 5 high, its top-left corner at (`x`, `y`).
private func eterniaHordeBat(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.pattern(x, y, [
        "R...R.R...R",
        "RR..RRR..RR",
        "RRRRRdRRRRR",
        ".RR.RRR.RR.",
        "....R.R....",
    ], ["R": C(0xE0282A), "d": C(0x7A1012)])
}

/// A jet's flame out of the back of a nozzle whose left edge is at (`x`, `y`), `y` its middle row: solid pixels in three
/// flat colours, a pale `core` at the nozzle, then `mid`, then the `outer` tongue, `len` px back to the left along the
/// middle row and `half` rows either side, each row a little shorter. The rows' lengths flicker on the clock `t`, and
/// now and then a loose lick flies off the tip.
private func eterniaFlame(_ c: PixelCanvas, x: Int, y: Int, len: Int, half: Int, t: Double, core: Px, mid: Px,
                          outer: Px) {
    let f = Int(t * 14)
    let jitter = [0, 2, 1, 3, 0, 1, 2, 1]
    for dy in -half...half {
        let edge = abs(dy)
        let j = jitter[(f + edge * 3 + (dy < 0 ? 5 : 0)) % jitter.count]
        let l = max(2, len - edge * 2 - j)
        let coreEnd: Int = edge == half ? 0 : l * 2 / 5
        let midEnd: Int = edge == half ? l / 3 : l * 3 / 4
        for i in 0..<l {
            c.px(x - 1 - i, y + dy, i < coreEnd ? core : i < midEnd ? mid : outer)
        }
    }
    let j0 = jitter[f % jitter.count]
    if j0 >= 2 {   // a lick torn off the middle row's tip while it's drawn in short
        c.px(x - (len - j0) - 2, y, outer)
    }
}

// MARK: - The Wind Raider

/// The Wind Raider, Eternia's flying sled, side on: a long green hull with an orange stripe and an orange nose, the
/// tall swept orange tail fin at the back, the near wing swept back under it, the open cockpit (a seat back and a
/// windscreen) and the grappling anchor hanging under the nose on its line. Landed it stands on two long skids
/// (`gear`), and `ramp` lets a short rope ladder down from the cockpit's side; `engines` lights the jet at the back.
private func eterniaDrawWindRaider(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool, t: Double) {
    let green = C(0x3E9A3A), greenL = C(0x7CD060), greenD = C(0x245E22)
    let orange = C(0xF08A28), orangeL = C(0xFFC060), orangeD = C(0xA85A18)
    let steel = C(0x9AA0AA), steelD = C(0x5A606A), glass = C(0xBFE8F0, 0.75)
    // Drawn four columns right, so the jet's flame has room before the canvas's left edge.
    c.ox += 4
    defer { c.ox -= 4 }
    if engines {
        eterniaFlame(c, x: 6, y: 16, len: 10, half: 1, t: t, core: C(0xFFF4B0), mid: C(0xFFB830), outer: C(0xE8501C))
    }
    // The skids: two struts down to a long runner, curled up at the front.
    if gear {
        for x in [20, 44] { c.rect(x, 20, 2, 7, steelD); c.px(x, 20, steel) }
        c.rect(14, 27, 34, 1, steel); c.rect(14, 28, 34, 1, steelD)
        c.px(48, 26, steel); c.px(48, 27, steel); c.px(49, 25, steel)
    }
    // The tail fin, tall and swept back, lit along its leading edge.
    eterniaFill(c, [(8, 15), (8, 4), (11, 3), (20, 14)], orange)
    for y in 4...13 { c.px(11 + (y - 3) * 9 / 11, y, orangeL) }
    c.rect(8, 4, 1, 11, orangeD)
    // The nozzle at the back.
    c.rect(6, 15, 3, 3, steelD); c.px(7, 15, steel)
    // The hull.
    rideHull(c, x0: 8, x1: 60, top: [(8, 14), (18, 13), (34, 13), (48, 14), (56, 16), (60, 17)],
             bottom: [(8, 19), (16, 20), (46, 20), (54, 19), (60, 17)], body: green, light: greenL, dark: greenD)
    // The orange stripe down its length, and the orange nose.
    c.rect(9, 17, 47, 1, orange)
    eterniaFill(c, [(53, 15.4), (61, 17), (53, 19.6)], orange)
    c.px(54, 15, orangeL); c.px(56, 16, orangeL); c.px(58, 16, orangeL)
    // The open cockpit: a dark well, the seat back, a little dash and the windscreen raked back.
    c.rect(26, 12, 11, 2, C(0x14301A))
    c.rect(26, 8, 3, 5, orange); c.rect(26, 8, 3, 1, orangeL); c.rect(28, 9, 1, 4, orangeD)
    c.rect(35, 11, 2, 1, steelD)
    for y in 8...12 { c.px(37 + (y - 8) / 2, y, glass); c.px(38 + (y - 8) / 2, y, C(0xBFE8F0, 0.35)) }
    c.px(37, 8, C(0xF4FCFF))
    // The near wing, swept back from the hull's underside, lit along its leading edge.
    eterniaFill(c, [(28, 19), (44, 19), (32, 23.5), (18, 23.5)], orange)
    for x in 19...43 { let y = 23 - (x - 19) * 4 / 25; if x > 31 || y >= 22 { c.px(x, y + 0, orangeL) } }
    c.rect(18, 23, 14, 1, orangeD)
    c.rect(24, 21, 10, 1, orangeD.alpha(0.6))
    // The anchor on its line under the nose: the ring, the shank, and the arms curving wide and up either side to their
    // pointed flukes, open between them so the app's outline doesn't fill it in.
    c.pattern(51, 19, [
        ".....r.....",
        ".....r.....",
        "....SSS....",
        "....S.S....",
        "....SSS....",
        "L....S....L",
        "SS...S...SS",
        ".SD..S..DS.",
        "..SD.S.DS..",
        "...SSSSS...",
    ], ["S": steel, "D": steelD, "L": C(0xD8DCE4), "r": C(0x4A2E14)])
    // The ladder, let down from the cockpit's side.
    if ramp > 0 {
        let len = Int((6 * ramp).rounded())
        c.rect(22, 21, 1, len, C(0x4A2E14)); c.rect(25, 21, 1, len, C(0x4A2E14))
        for y in stride(from: 22, through: 20 + len, by: 2) { c.rect(23, y, 2, 1, C(0xF0DCA8)) }
    }
}

// MARK: - Swift Wind

/// One of Swift Wind's wings from the shoulder (`hx`, `hy`) along `angle` (radians, y down) for `len` px: white
/// coverts along the leading edge, then pale grey and lilac flight feathers striped across, parting at the tip.
/// `side` +1 puts the trailing edge clockwise of the wing's direction on screen, -1 anticlockwise.
private func eterniaHorseWing(_ c: PixelCanvas, hx: Double, hy: Double, angle: Double, len: Double, width: Double,
                              side: Double, far: Bool) {
    let cover = far ? C(0xC8CCDC) : C(0xFAFAFF), flight = far ? C(0xA8A8C4) : C(0xDCDCEC)
    let stripe = far ? C(0x9090B0) : C(0xB8B4D8), tip = far ? C(0x8A88AC) : C(0xC0B8E8)
    let dx = cos(angle), dy = sin(angle), nx = -dy * side, ny = dx * side
    let x0 = Int(floor(min(hx, hx + dx * len) - width - 1)), x1 = Int(ceil(max(hx, hx + dx * len) + width + 1))
    let y0 = Int(floor(min(hy, hy + dy * len) - width - 1)), y1 = Int(ceil(max(hy, hy + dy * len) + width + 1))
    for y in y0...y1 { for x in x0...x1 {
        let px: Double = Double(x) + 0.5 - hx, py: Double = Double(y) + 0.5 - hy
        let a: Double = px * dx + py * dy, b: Double = px * nx + py * ny
        let f: Double = a / len, half: Double = width * (1 - 0.35 * f)
        guard a >= 0, b >= -1.4, b <= half else { continue }
        let reach: Double = len + 2.5 * (b / half)
        guard a <= reach else { continue }
        if f > 0.62 && b > 1.2 && Int((a * 0.9).rounded()) % 3 == 0 { continue }   // the gaps between the primaries
        let col: Px
        if b < 0.6 { col = cover }
        else { col = Int(b.rounded()) % 2 == 0 ? (f > 0.7 ? tip : flight) : stripe }
        c.px(x, y, col)
    } }
}

/// His pink mane and tail, the same three pinks as his own art: the mane, its shade and its light.
private let eterniaManePink = C(0xF070B8), eterniaManePinkD = C(0xC04890), eterniaManePinkL = C(0xFFA8D8)
/// The tail's strands, top to bottom.
private let eterniaTailStrands: [Px] = [eterniaManePinkL, eterniaManePink, eterniaManePinkD, eterniaManePink,
                                        eterniaManePink, eterniaManePinkD]

/// Swift Wind, side on and facing right: a white horse with a spiralled gold horn, a pink mane flowing back down his
/// neck and a long pink tail. Flying (`flying`), his legs tuck up and his great white wings beat on the clock `t`,
/// up over his back and down below his belly, his body bobbing against each beat. Landed he stands on four hooves with
/// his wings folded along his back, and `ramp` swings the near wing down to the ground to climb on; `gear` puts his
/// hooves down as he settles.
private func eterniaDrawSwiftWind(_ c: PixelCanvas, ramp: Double, flying: Bool, gear: Bool, t: Double) {
    let coat = C(0xF4F4FA), coatL = C(0xFFFFFF), coatD = C(0xBCC0D4), hoof = C(0x8A8494)
    let horn = C(0xF0C850), hornD = C(0xB08A2A), hornL = C(0xFFF0B0), ink = C(0x1E1A2A)
    var up = false
    if flying { let beat: Double = (t * 2.2).truncatingRemainder(dividingBy: 1); up = beat < 0.5 }
    let bob = flying ? (up ? 1 : -1) : 0
    c.oy += bob
    defer { c.oy -= bob }
    // The far wing, behind him while he flies.
    if flying {
        eterniaHorseWing(c, hx: 34, hy: 11, angle: up ? -1.95 : 2.2, len: 16, width: 5.5, side: up ? -1 : 1, far: true)
    }
    // The tail: pink strands flowing back and down, waving.
    for (i, col) in eterniaTailStrands.enumerated() {
        let row: Double = 13 + Double(i) * 0.8
        let sway: Double = sin(t * 4 + Double(i) * 0.7) * (flying ? 1.2 : 0.6)
        let endY: Double = flying ? row + 3 + sway : row + 8 + sway
        c.glowLine(19, row, 8, endY, core: col, glow: C(0, 0), coreR: 0.6, glowR: 0.7)
    }
    // The legs: straight down, or tucked up in flight until he puts his hooves down to land (`gear`).
    let legs: [(x: Int, front: Bool)] = [(21, false), (25, false), (37, true), (41, true)]
    for l in legs {
        if flying && !gear {
            let kx = l.front ? 3 : -3, x0 = Double(l.x) + 0.5, knee = Double(l.x + kx) + 0.5
            c.glowLine(x0, 20, knee, 23, core: coatD, glow: C(0, 0), coreR: 0.9, glowR: 1)
            c.glowLine(knee, 23, Double(l.x + kx / 3) + 0.5, 25, core: coatD, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
            c.rect(l.x + kx / 3, 25, 2, 1, hoof)
        } else {
            c.rect(l.x, 20, 2, 7, l.x == 25 || l.x == 41 ? coat : coatD)
            c.px(l.x + 1, 23, coatD)
            c.rect(l.x, 27, 2, 1, hoof); c.rect(l.x - 1, 28, 3, 1, hoof)
        }
    }
    // The body: a white barrel, lit along the back, shaded along the belly.
    c.ellipse(31, 16, 12, 5, coat)
    for x in 20...42 {
        let u: Double = Double(x - 31) / 12, hh: Double = (max(0, 1 - u * u)).squareRoot() * 5
        c.px(x, Int((16 - hh).rounded()), coatL)
        c.px(x, Int((16 + hh).rounded()), coatD)
    }
    // The neck, up and forward to the head, and the head with its muzzle forward.
    eterniaFill(c, [(37, 12), (43, 4), (48, 5), (44, 16), (38, 19)], coat)
    c.pattern(42, 2, [
        "..EE.........",
        ".EWWE........",
        ".WWWWWWW.....",
        "WWWWWKWWWW...",
        "WWWWWWWWWWWW.",
        "WWWWWWWWWWWWN",
        ".WWWWWWWWWWDD",
        "..WWWW.DDDDD.",
    ], ["W": coat, "E": coatD, "K": ink, "N": C(0x6A5E6A), "D": coatD])
    c.px(43, 3, C(0xE8B8C8))
    c.rect(45, 4, 5, 1, coatL)
    // The horn, spiralled gold, up and forward from his brow.
    c.pattern(47, -4, ["......L", ".....GL", "....gG.", "...Gg..", "..gG...", ".Gg....", "gG....."],
              ["G": horn, "g": hornD, "L": hornL])
    // The mane: pink strands down the top of his neck, flowing back, each tip in the shade.
    for k in 0..<9 {
        let y = 4 + k
        let x0 = 43 - k * 5 / 8
        let len = 3 + (k % 2) + (flying ? 2 : 0)
        let wave = Int((sin(t * 3 + Double(k) * 0.8) * 0.8).rounded())
        c.rect(x0 - len, y + wave, len + 1, 1, k % 2 == 0 ? eterniaManePink : eterniaManePinkD)
        c.px(x0 - len, y + wave, eterniaManePinkD)
    }
    c.rect(43, 2, 2, 2, eterniaManePink); c.px(43, 2, eterniaManePinkL)   // the forelock
    c.px(41, 5, eterniaManePinkL); c.px(40, 7, eterniaManePinkL)
    if flying {
        eterniaHorseWing(c, hx: 32, hy: 11, angle: up ? -2.2 : 2.5, len: up ? 19 : 20, width: 7, side: up ? -1 : 1,
                         far: false)
    } else {
        // Folded along his back; `ramp` swings the near wing down about the shoulder to its foot on the ground.
        let hx = 34.0, hy = 11.0
        let foot = (x: 19.0, y: 27.5)
        let closed: Double = atan2(-2.5, -17.0), open: Double = atan2(foot.y - hy, foot.x - hx)
        let a: Double = closed + (open - closed) * ramp
        let len: Double = 17.0 + (hypot(foot.x - hx, foot.y - hy) - 17.0) * ramp
        eterniaHorseWing(c, hx: hx, hy: hy, angle: a, len: len, width: 4.5, side: -1, far: false)
    }
}

// MARK: - The Roton

/// The Roton, Skeleclawd's assault vehicle, side on: a squat dark-purple hull on a tracked base, the ring of silver
/// blades round its middle (seen edge-on, the blades' points sticking out above and below), a smoky violet canopy on
/// top and Skeleclawd's ram skull on its nose, its eyes lit red. `moving`: the blades sweep round and the tracks
/// run, exhaust puffing from the stacks at the back; `ramp` 0…1 drops the side hatch open as a step.
private func eterniaDrawRoton(_ c: PixelCanvas, ramp: Double, moving: Bool, t: Double) {
    let purple = C(0x5A2E86), purpleL = C(0x8A56C0), purpleD = C(0x341A50), black = C(0x1A1420)
    let blade = C(0xD8DCE6), bladeD = C(0x7A7E8C), bone = C(0xE8DCA8), boneD = C(0xA89A68)
    let red = C(0xFF3A2A)
    // The exhaust: cel puffs of smoke chuffing off the stacks and drifting back, each a solid lobed puff with a dark
    // outline and a flat shadow side, swelling as it leaves and then tearing into a trailing wisp.
    if moving {
        let ks: [Double] = (0..<2).map { (t * 1.5 + Double($0) / 2).truncatingRemainder(dividingBy: 1) }
        for k in ks.sorted(by: >) { eterniaRotonPuff(c, k: k) }
    }
    // The stacks.
    c.rect(9, 6, 2, 6, black); c.rect(12, 7, 2, 5, black); c.px(9, 6, bladeD); c.px(12, 7, bladeD)
    // The tracked base: a black track round road wheels, its links running when it moves.
    c.rect(11, 22, 44, 6, black)
    c.rect(10, 23, 1, 4, black); c.rect(55, 23, 1, 4, black)
    let shift = moving ? Int(t * 18) % 3 : 0
    for x in stride(from: 11 + shift, through: 54, by: 3) { c.px(x, 22, C(0x4A4452)); c.px(x, 27, C(0x4A4452)) }
    for wx in [15, 23, 31, 39, 47] {
        c.circle(wx, 25, 2, C(0x3A3444)); c.px(wx, 25, bladeD)
        if moving {   // a glint going round the hub
            let a: Double = t * 9
            c.px(wx + Int((cos(a) * 1.4).rounded()), 25 + Int((sin(a) * 1.4).rounded()), blade)
        }
    }
    // The lower hull.
    rideHull(c, x0: 8, x1: 57, top: [(8, 17), (57, 17)], bottom: [(8, 21), (12, 22), (54, 22), (57, 20)],
             body: purple, light: purpleL, dark: purpleD)
    // The upper hull and its smoky canopy.
    rideHull(c, x0: 14, x1: 50, top: [(14, 13), (20, 9), (42, 9), (50, 13)], bottom: [(14, 14), (50, 14)],
             body: purple, light: purpleL, dark: purpleD)
    eterniaFill(c, [(23, 9), (27, 4.5), (38, 4.5), (42, 9)], C(0x6A4A9A, 0.85))
    c.rect(27, 5, 10, 1, C(0xB8A0E0)); c.px(28, 6, C(0xE0D4FF)); c.px(29, 6, C(0xB8A0E0))
    c.rect(23, 9, 20, 1, purpleD)
    // The blade ring: a steel band, and the blades' points above and below it, sweeping round when it moves.
    c.rect(3, 15, 60, 2, bladeD); c.rect(3, 15, 60, 1, blade)
    let sweep = moving ? Int(t * 30) % 6 : 0
    for x in stride(from: 3 + sweep, through: 61, by: 6) {
        c.pattern(x, 13, ["B..", "BB.", "...", "...", "dd.", "d.."], ["B": blade, "d": bladeD])
    }
    c.px(2, 15, blade); c.px(2, 16, bladeD); c.px(63, 15, blade); c.px(63, 16, bladeD)
    if moving {   // the blur of the blades going round
        c.rect(4, 13, 58, 2, C(0xD8DCE6, 0.25)); c.rect(4, 17, 58, 2, C(0x7A7E8C, 0.3))
    }
    // The ram skull on its nose: black sockets with red eyes, the snout and teeth.
    c.pattern(47, 4, [
        "............",
        "......BBBB..",
        ".....BBBBBBB",
        "....BBBBBBBB",
        "...BKKBBBKKB",
        "...BKEBBBEKB",
        "...BBBBBBBBB",
        "....BBbBbBB.",
        "....TbTTbT..",
    ], ["B": bone, "b": boneD, "K": C(0x2A1020), "E": red, "T": C(0xF4EED0)])
    c.rect(53, 5, 4, 1, C(0xFFF6D8))
    // The ram's horns: a thick ridged curl from the top of the skull, back, round and down, its tip curling in.
    c.pattern(43, 1, [
        "...OOOO...",
        "..OHHHHO..",
        ".OHrHHrHO.",
        "OHrOOOOHHO",
        "OHO....OHH",
        "OrO.OO..OH",
        "OHHOHO....",
        ".OHrHO....",
        "..OOO.....",
    ], ["O": C(0x4A3818), "H": C(0xE0C27A), "r": C(0xA8884A)])
    // The hatch at the boarding point: closed, a riveted panel; open, it drops down to a step, showing the violet hold.
    if ramp > 0 {
        c.rect(15, 18, 7, 4, C(0x1A0C2A))
        c.rect(16, 18, 5, 1, C(0xB070FF, 0.4 + 0.5 * ramp))
        let drop = Int((4 * ramp).rounded())
        c.rect(15, 22 + drop - 1, 7, 1, purpleL); c.rect(15, 22, 7, max(0, drop - 1), purpleD)
    } else {
        c.rect(15, 18, 7, 4, purpleD); c.rect(16, 19, 5, 2, purple)
        c.px(15, 18, purpleL); c.px(21, 21, black)
    }
}

/// One puff of the Roton's exhaust, `k` 0…1 from the stack top to gone: a small puff over the stacks, a bigger
/// two-lobed one drifting back and up, then a wisp tearing away into a tail. Solid pixels, never faded.
private func eterniaRotonPuff(_ c: PixelCanvas, k: Double) {
    let pal: [Character: Px] = ["O": C(0x2E2838), "L": C(0xD4CCE0), "S": C(0x8C82A0)]
    // Back along the hull more than up: the canvas's top edge is only a few rows over the stacks.
    let back: Double = k * 10
    let x = 9 - Int(back.rounded())
    if k < 0.3 {
        c.pattern(x, 3, [".OO.", "OLLO", "OLSO", ".OO."], pal)
    } else if k < 0.68 {
        c.pattern(x - 2, 2, ["..OO.OO.", ".OLLOLLO", "OLLLLLSO", "OLLLLSSO", ".OSSSSO.", "..OOOO.."], pal)
    } else {
        c.pattern(x - 2, 1, ["...OOO..", "..OLLSO.", ".OLLSSOO", "OLSOOOSO", ".OO...O."], pal)
    }
}

// MARK: - The Horde skiff

/// The Horde's skiff, side on: a grey armoured hull with a dark keel, the red Horde bat big on its side and a red spur
/// at the prow, under a great black bat wing raised from its back, finger bones fanning out to scalloped edges. A
/// little railed pilot's deck up front. `engines` lights the red thrusters at the stern and beats the wing a little;
/// `ramp` and `gear` are the kit's ramp and landing legs.
private func eterniaDrawHordeSkiff(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool, t: Double) {
    let grey = C(0x6A6A78), greyL = C(0x9A9AAA), greyD = C(0x3A3A46), black = C(0x1E1A24)
    // Drawn three columns right, so the thrusters' flame has room before the canvas's left edge.
    c.ox += 3
    defer { c.ox -= 3 }
    let membrane = C(0x521C2C), membraneL = C(0x8A3044), bone = C(0xB0A8BC), red = C(0xD02828)
    if engines {
        eterniaFlame(c, x: 6, y: 16, len: 9, half: 1, t: t, core: C(0xFFE08A), mid: C(0xFF7A28), outer: C(0xD02020))
    }
    if gear { rideGear(c, xs: [14, 48], from: 20, strut: greyD, foot: grey) }
    // The bat wing, raised over the deck: the arm up from the root to the wrist, the top edge sweeping back to the
    // wingtip, and the trailing edge scalloped between the fingertips, each finger a bone fanning out from the wrist.
    let flap: Double = engines ? sin(t * 8) * 1.5 : 0
    func lift(_ p: (Double, Double)) -> (Double, Double) { (p.0, p.1 + flap * (38 - p.0) / 32) }
    let root = (38.0, 13.0), wrist = lift((33, 1))
    let tips = [lift((6, 7)), lift((14, 11)), lift((24, 12.5))]
    var outline: [(Double, Double)] = [root, wrist, lift((24, 1.2)), lift((15, 2.6)), tips[0]]
    for (a, b) in [(tips[0], tips[1]), (tips[1], tips[2]), (tips[2], root)] {
        for k in [0.33, 0.66] {   // the scallop, curving up between two fingertips
            outline.append((a.0 + (b.0 - a.0) * k, a.1 + (b.1 - a.1) * k - 2.2))
        }
        outline.append(b)
    }
    eterniaFill(c, outline, membrane)
    for x in 7...32 {   // the top edge, lit
        let p = lift((Double(x), Double(rideProfile(x, [(6, 7), (15, 2.6), (24, 1.2), (33, 1)]))))
        c.px(x, Int(p.1.rounded()), membraneL)
    }
    for tp in tips {
        c.glowLine(wrist.0, wrist.1, tp.0, tp.1, core: bone, glow: C(0, 0), coreR: 0.45, glowR: 0.55)
    }
    c.glowLine(root.0, root.1, wrist.0, wrist.1, core: bone, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    c.pattern(Int(wrist.0), Int(wrist.1) - 1, ["k.", ".k"], ["k": C(0xE0D8EC)])   // the claw on the wrist
    // The nozzle at the stern.
    c.rect(6, 15, 3, 3, greyD); c.px(7, 15, greyL)
    // The hull.
    rideHull(c, x0: 8, x1: 59, top: [(8, 13), (48, 13), (54, 14), (59, 16)],
             bottom: [(8, 18), (14, 20), (48, 20), (59, 16)], body: grey, light: greyL, dark: greyD)
    c.rect(9, 18, 41, 1, black.alpha(0.6))
    for x in stride(from: 9, through: 49, by: 8) { c.px(x, 15, greyD); c.px(x, 18, greyL) }   // the rivets
    // The red spur at the prow.
    eterniaFill(c, [(54, 14.5), (62, 16), (54, 18)], red); c.px(55, 15, C(0xFF5A4A))
    // The Horde's bat, big on the side.
    eterniaHordeBat(c, 23, 14)
    // The pilot's deck: a rail and a red-lit console.
    c.rect(46, 9, 1, 4, greyL); c.rect(52, 10, 1, 3, greyL); c.rect(46, 9, 7, 1, greyL)
    c.rect(53, 11, 2, 2, black); c.px(54, 11, red)
    rideRamp(c, ramp: ramp, hx: 32, hy: 19.5, plate: greyD, edge: greyL)
}

// MARK: - Hordakk's rocket

/// Hordakk's rocket, side on (in the show he turns into one himself; here he rides one): a grey body lit along the top,
/// a red nose cone, two swept red fins at the back cut into bat-wing scallops, a keel fin down the top like the one on
/// his cowl, a porthole, and the Horde's red bat on its side. `engines` lights the rocket's flame; `ramp` and `gear`
/// are the kit's ramp and landing legs.
private func eterniaDrawHordeRocket(_ c: PixelCanvas, ramp: Double, engines: Bool, gear: Bool, t: Double) {
    let grey = C(0x8A8A96), greyL = C(0xC0C0CC), greyD = C(0x50505C), red = C(0xC82828), redL = C(0xF05A48)
    let redD = C(0x7A1414)
    // Drawn four columns right, so the flame has room before the canvas's left edge.
    c.ox += 4
    defer { c.ox -= 4 }
    if engines {
        eterniaFlame(c, x: 6, y: 15, len: 10, half: 2, t: t, core: C(0xFFF4B0), mid: C(0xFFA028), outer: C(0xE0381E))
    }
    if gear { rideGear(c, xs: [16, 32, 48], from: 21, strut: greyD, foot: grey) }
    // The fins: swept back and red, scalloped like a bat's wing along their trailing edge.
    eterniaFill(c, [(10, 10), (5, 2), (8, 3.5), (10, 2.5), (13, 5), (22, 10)], red)
    eterniaFill(c, [(10, 20), (5, 26), (8, 25), (10, 26), (13, 24), (22, 20)], red)
    c.glowLine(6, 3, 21, 10, core: redL, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    // The nozzle.
    c.rect(7, 12, 3, 7, greyD); c.rect(6, 13, 1, 5, C(0x2A2A32))
    // The body: a long grey tube, tapering into the red nose cone.
    rideHull(c, x0: 10, x1: 61, top: [(10, 10), (46, 10), (53, 11), (58, 13), (61, 15)],
             bottom: [(10, 20), (46, 20), (53, 19), (58, 17), (61, 15)], body: grey, light: greyL, dark: greyD)
    for x in 51...61 {
        let tp = rideProfile(x, [(46, 10), (53, 11), (58, 13), (61, 15)])
        let bt = rideProfile(x, [(46, 20), (53, 19), (58, 17), (61, 15)])
        c.rect(x, tp, 1, bt - tp + 1, red)
        c.px(x, tp, redL); c.px(x, bt, redD)
    }
    c.rect(50, 10, 1, 11, greyD)
    // The bands round the tube, and the keel fin down its top (his cowl's).
    c.rect(14, 10, 1, 11, greyD); c.rect(40, 10, 1, 11, greyD)
    eterniaFill(c, [(26, 10), (32, 7), (44, 7), (46, 10)], greyD)
    c.rect(32, 7, 12, 1, grey)
    // The porthole, and the Horde's bat on the side.
    c.circle(45, 14, 2, greyD); c.circle(45, 14, 1, C(0xE03030)); c.px(44, 13, C(0xFFB0A0))
    eterniaHordeBat(c, 26, 12)
    rideRamp(c, ramp: ramp, hx: 33, hy: 20.5, plate: greyD, edge: greyL)
}
