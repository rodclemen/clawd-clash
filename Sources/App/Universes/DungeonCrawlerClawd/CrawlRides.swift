import Foundation

// Dungeon Crawler Clawd's ride (`Ride`): Katia's monster truck, drawn nose to the right on the ships' `Ride.width`×
// `Ride.height` canvas with the ride kit (Rides.swift). A battered, dungeon-modded pickup in Katia's purple on four
// huge knobbly tyres taller than its body, the chassis lifted high on yellow coil-over springs, a supercharger
// sticking out of its bonnet, a roll bar with a light bar over the bed, a bolted-on steel plate down its side and a
// spiked ram bar on its nose. It roars in along the ground (`Ride.drives`) with its tyres turning and its body
// bobbing on its springs, bounces to a stop, and drops its tailgate and a steel ladder for the crawlers to climb
// into the bed. Who rides is `crawlRide(_:)` below.

extension Ride {
    /// Katia's monster truck: drives in, its tailgate and ladder at the back, 31 left of centre.
    static let crawlMonsterTruck = Ride(key: "crawlMonsterTruck", arrival: .drives,
                                        boardingOffset: 31) { c, ramp, engines, _, t in
        crawlDrawMonsterTruck(c, ramp: ramp, moving: engines, t: t)
    }
}

/// Every ride, for Preview's sheet.
let crawlRides: [Ride] = [.crawlMonsterTruck]

/// The ride that picks `c` up when its agent is done; nil: it walks off on foot.
/// - The crawlers, the Royal Court and Meadow Lark: the truck, Mongo too (he rides along with Donut).
/// - The show's friendlier side off their posts (Rosetta, Tipid, Princess Formidable) and Ferdinand: the truck as well,
///   as the plan only keeps the NPCs tied to their posts on foot.
/// - On foot: HEM, Orthrus and Garret; the Desperado Club's staff and dancers, Rory, Lorelai, Pater Coal, Edgar,
///   Odette, Zev and Quasar (tied to their posts); and every villain.
func crawlRide(_ c: Cast) -> Ride? {
    guard c.universe == .crawl, !c.isDark, let hero = CrawlHero(rawValue: c.index) else { return nil }
    switch hero {
    case .carl, .donut, .mongo, .katia, .mordecai, .samantha, .prepotente, .louis,
         .elle, .imani, .brandon, .chris,
         .bautista, .florin, .ifechi,
         .tran, .liJun, .liNa, .zhang, .sisterInes, .tserendolgor, .langley, .gwendolyn, .jurgen, .osvaldo, .popovs,
         .miriamDom, .juiceBox,
         .ferdinand,
         .rosetta, .tipid, .formidable:
        return .crawlMonsterTruck
    case .sledge, .bomo, .doctorBones, .splashZone,
         .gluteusMaxx, .dongQuixote, .damascusSteel, .anaconda, .rosemarie,
         .rory, .lorelai, .paterCoal, .edgar,
         .odette, .zev, .quasar,
         .orthrus, .garret, .hem:
        return nil
    }
}

// MARK: - The truck

private let crawlTruckPurple = C(0x8A44D8), crawlTruckLight = C(0xB880F4), crawlTruckDark = C(0x4E2288)
private let crawlTruckSteel = C(0x9AA2AE), crawlTruckSteelLight = C(0xD4DAE2), crawlTruckSteelDark = C(0x545A66)
private let crawlTruckIron = C(0x3A3E48), crawlTruckPink = C(0xFF5AB4), crawlTruckPinkLight = C(0xFFA8D8)

/// The truck, step by step from the back: the suspension between the wheels, the frame, the four tyres (two seen, side
/// on), then the body riding on its springs.
/// - `moving`: driving in or revving to leave. The tyres' knobs turn on the clock `t`, the body bobs a pixel over the
///   ground's bumps, the headlights and the roll bar's light bar are on.
/// - `ramp` 0…1: the tailgate swings down flat and the steel ladder unrolls from it to the ground. The body bounces as
///   it does, sinking on its springs and rising back once, so it settles from its stop as the crawlers get on (and
///   again as the ladder comes up behind them).
private func crawlDrawMonsterTruck(_ c: PixelCanvas, ramp: Double, moving: Bool, t: Double) {
    let rolling = moving && ramp == 0
    // How far the body rides down (+) or up (-) on its springs.
    let dy: Int
    if ramp > 0 {
        dy = Int((2 * sin(ramp * 2 * .pi) * (1 - 0.4 * ramp)).rounded())
    } else if rolling {
        dy = [0, -1, 0, 0, 1, 0, -1, 0][Int(t * 10) % 8]
    } else {
        dy = 0
    }
    crawlTruckSuspension(c, dy: dy)
    for wx in [14, 51] { crawlTruckTyre(c, wx: wx, spin: rolling ? t * 9 : 0) }
    let oy = c.oy
    c.oy += dy
    crawlTruckBody(c, lit: moving)
    crawlTruckTailgate(c, ramp: ramp)
    c.oy = oy
    // The ladder hangs from the open tailgate to the ground, which doesn't bounce.
    crawlTruckLadder(c, ramp: ramp, top: 12 + dy)
}

/// The lifted chassis: the dark frame rail high over the tyres, and in the gap between the wheels the lower links
/// running in from the axles, the gearbox and driveshaft, and two fat yellow coil-over springs from the links up to the
/// frame, stretching and squashing as the body (`dy`) moves.
private func crawlTruckSuspension(_ c: PixelCanvas, dy: Int) {
    let spring = C(0xF4C430), springDark = C(0xA87A10), link = C(0x2A2C34)
    // The lower links, from each hub in toward the middle.
    c.glowLine(14, 21, 28, 19.5, core: link, glow: C(0x000000, 0), coreR: 0.9, glowR: 1)
    c.glowLine(51, 21, 37, 19.5, core: link, glow: C(0x000000, 0), coreR: 0.9, glowR: 1)
    // The gearbox under the cab and the driveshaft back to the rear axle.
    c.glowLine(16, 20, 32, 16.5, core: crawlTruckIron, glow: C(0x000000, 0), coreR: 0.6, glowR: 0.7)
    c.rect(31, 14 + max(0, dy), 5, 3, crawlTruckIron); c.rect(31, 14 + max(0, dy), 5, 1, crawlTruckSteelDark)
    // The coil-overs: a chrome shaft, the yellow coil wound round it.
    for (bx, tx) in [(24.0, 27.0), (41.0, 38.0)] {
        let by = 19.0, ty = 12.5 + Double(dy)
        c.glowLine(bx, by, tx, ty, core: crawlTruckSteelLight, glow: C(0x000000, 0), coreR: 0.5, glowR: 0.6)
        let n = 6
        for i in 0...n {
            let k = Double(i) / Double(n), x = bx + (tx - bx) * k, y = by + (ty - by) * k
            c.px(Int(x.rounded()) - 1, Int(y.rounded()), i % 2 == 0 ? spring : springDark)
            c.px(Int(x.rounded()) + 1, Int(y.rounded()), i % 2 == 0 ? springDark : spring)
        }
        c.rect(Int(bx) - 1, Int(by), 3, 1, crawlTruckSteelDark)   // the shock's foot on the link
    }
    // The frame rail, riveted, high over the tyres.
    c.rect(4, 12 + dy, 58, 2, crawlTruckIron)
    c.rect(4, 12 + dy, 58, 1, C(0x5A606C))
    for x in stride(from: 7, through: 59, by: 6) { c.px(x, 13 + dy, crawlTruckSteel) }
}

/// One huge tyre centred at (`wx`, 21), 15 px tall from the frame's underside to the ground: a black tread ringed with
/// square knobs that stand proud of the outline, a dark sidewall, a chrome beadlock rim with its bolts and a dark hub.
/// The knobs and bolts go round by `spin` radians.
private func crawlTruckTyre(_ c: PixelCanvas, wx: Int, spin: Double) {
    let cy = 21, tread = C(0x18181C), knob = C(0x26262C), wall = C(0x30303A), wallLight = C(0x50505C)
    c.circle(wx, cy, 6, tread)
    let lugs = 12
    for i in 0..<lugs {
        let a = spin + Double(i) * 2 * .pi / Double(lugs)
        for da in [-0.11, 0.11] {
            c.px(wx + Int((cos(a + da) * 7).rounded()), cy + Int((sin(a + da) * 7).rounded()), knob)
        }
        // The groove between two knobs, cut into the tread.
        let g = a + .pi / Double(lugs)
        c.px(wx + Int((cos(g) * 6).rounded()), cy + Int((sin(g) * 6).rounded()), C(0x0C0C0E))
    }
    c.circle(wx, cy, 5, wall)
    c.px(wx - 3, cy - 4, wallLight); c.px(wx - 4, cy - 3, wallLight); c.px(wx - 2, cy - 4, wallLight)   // the sheen
    // The beadlock rim: a chrome ring with its bolts, round the dark hub.
    c.circle(wx, cy, 3, crawlTruckSteel)
    c.circle(wx, cy, 2, crawlTruckSteelDark)
    c.px(wx, cy, crawlTruckSteelLight)
    for i in 0..<5 {
        let a = spin + Double(i) * 2 * .pi / 5
        c.px(wx + Int((cos(a) * 3).rounded()), cy + Int((sin(a) * 3).rounded()), crawlTruckIron)
    }
    c.px(wx - 1, cy - 3, crawlTruckSteelLight)   // the glint, top left
}

/// The body on the frame: a short pickup bed with a bolted-on steel plate, the cab with its mesh-screened window and
/// door, the bonnet with Katia's pink flames and the supercharger sticking up out of it, the grille and the spiked
/// ram bar out front, and the roll bar standing in the bed with its light bar. Dents, scrapes and rust from the
/// dungeon all over. `lit`: the headlight and the light bar on.
private func crawlTruckBody(_ c: PixelCanvas, lit: Bool) {
    let body = crawlTruckPurple, light = crawlTruckLight, dark = crawlTruckDark
    let glass = C(0x2A3A4C), shine = C(0x9AB8D0), rust = C(0xA0603A), scrape = C(0xA894C0)
    // The roll bar, behind the cab: two tubes up from the bed, a crossbar and its light bar on top, a dark steel
    // grate welded in between (an open hoop fills with the outline and reads as a white box).
    c.rect(23, 3, 5, 3, C(0x26262C))
    for (x, y) in [(24, 3), (26, 3), (25, 4), (24, 5), (26, 5)] { c.px(x, y, crawlTruckSteelDark) }
    c.rect(22, 2, 1, 5, crawlTruckSteel); c.rect(28, 2, 1, 5, crawlTruckSteel)
    c.rect(22, 2, 7, 1, crawlTruckSteelLight)
    c.rect(22, 1, 7, 1, C(0x26262C))
    for x in [23, 25, 27] {
        c.px(x, 1, lit ? C(0xFFF6C8) : C(0x8A8A80))
        if lit { c.px(x, 0, C(0xFFF6C8, 0.45)) }
    }
    // The bed: a short box, its top lip lit, with the back end catching the light.
    c.rect(6, 6, 24, 6, body)
    c.rect(6, 6, 24, 1, light)
    c.rect(6, 11, 24, 1, dark)
    // The bolted-on armour plate down the bed's side, riveted at its corners and dented.
    c.rect(9, 7, 13, 4, crawlTruckSteel)
    c.rect(9, 7, 13, 1, crawlTruckSteelLight); c.rect(9, 10, 13, 1, crawlTruckSteelDark)
    for (x, y) in [(10, 8), (20, 8), (10, 9), (20, 9)] { c.px(x, y, crawlTruckIron) }
    c.px(15, 8, crawlTruckSteelDark); c.px(16, 8, crawlTruckSteelDark); c.px(15, 9, crawlTruckSteelLight)   // a dent
    c.px(14, 9, crawlTruckSteelDark)
    // The cab: square, the roof a step up from the bed, the windscreen raked forward.
    for x in 30...46 {
        let top = x < 44 ? 2 : 2 + (x - 43)
        c.rect(x, top, 1, 12 - top, body)
        c.px(x, top, light)
    }
    c.rect(30, 2, 1, 10, dark)                                  // the cab's back edge, in shade
    c.rect(30, 11, 17, 1, dark)
    // The side window behind its wire mesh, and the windscreen's edge.
    c.rect(33, 3, 9, 4, glass)
    for y in 3...6 { for x in 33...41 where (x + y) % 2 == 0 { c.px(x, y, C(0x6A707C)) } }
    c.px(34, 3, shine); c.px(35, 4, shine)
    for y in 3...6 { let x = 43 + (y - 3); c.px(x, y, glass); c.px(x + 1, y, glass.alpha(0.7)) }
    c.px(44, 4, shine)
    // The door: its seams and handle.
    c.rect(32, 3, 1, 9, dark); c.rect(42, 3, 1, 9, dark)
    c.rect(39, 8, 2, 1, crawlTruckSteelLight)
    // The bonnet, a step down from the windscreen, out to the grille.
    c.rect(46, 6, 16, 6, body)
    c.rect(46, 6, 16, 1, light)
    c.rect(46, 11, 16, 1, dark)
    // Katia's pink flames licking back along the bonnet and onto the door.
    c.pattern(34, 8, [
        "..........P..P...P..P.....",
        "....P..PPPPPPPPPPPPPPPPPP.",
        "..PPPPPPPPpppppppppppppPPP",
    ], ["P": crawlTruckPink, "p": crawlTruckPinkLight])
    // The supercharger out of the bonnet: a chrome blower with its black intake scoop on top.
    c.pattern(49, 1, [
        "..KKKKK.",
        "..KKKKMM",
        ".LLLLLL.",
        ".SdSdSS.",
        ".SSSSSS.",
    ], ["K": C(0x26262C), "M": C(0x0C0C0E), "L": crawlTruckSteelLight, "S": crawlTruckSteel, "d": crawlTruckSteelDark])
    // The grille, the headlight and its beam.
    c.rect(61, 7, 2, 4, crawlTruckIron)
    for y in stride(from: 8, through: 10, by: 2) { c.px(62, y, crawlTruckSteel) }
    c.rect(61, 6, 2, 1, lit ? C(0xFFF6C8) : C(0xC8C8B8))
    if lit { c.rect(63, 5, 2, 2, C(0xFFF6C8, 0.5)) }
    // The ram bar across the nose, with three steel spikes pointing forward.
    c.rect(60, 11, 4, 2, crawlTruckSteelDark); c.rect(60, 11, 4, 1, crawlTruckSteel)
    for y in [8, 10, 12] { c.px(63, y, crawlTruckSteel); c.px(64, y, crawlTruckSteelLight) }
    c.px(63, 9, crawlTruckSteelDark); c.px(63, 11, crawlTruckSteelDark)
    // The back end: the tail light, the bumper.
    c.rect(4, 11, 3, 2, crawlTruckSteelDark); c.rect(4, 11, 3, 1, crawlTruckSteel)
    // The dungeon's wear: a caved-in panel on the bonnet, scrapes down the bed, rust round the arches.
    c.rect(56, 8, 3, 1, dark); c.rect(56, 9, 3, 1, light)
    for (x, y) in [(24, 9), (25, 9), (26, 10), (27, 10), (44, 9), (45, 10)] { c.px(x, y, scrape) }
    for (x, y) in [(7, 10), (8, 11), (21, 11), (47, 10), (48, 11), (58, 11)] { c.px(x, y, rust) }
}

/// The tailgate at the bed's back end, hinged at its foot: closed, an upright panel with the red tail light; opening
/// (`ramp` 0…1), it swings down and back until it lies flat, the bed's dark inside showing behind it.
private func crawlTruckTailgate(_ c: PixelCanvas, ramp: Double) {
    if ramp <= 0 {
        c.rect(5, 6, 2, 6, crawlTruckPurple)
        c.rect(5, 6, 2, 1, crawlTruckLight); c.rect(5, 6, 1, 6, crawlTruckLight)
        c.rect(5, 7, 1, 2, C(0xE83A3A))
        return
    }
    c.rect(5, 7, 2, 5, C(0x1E1228))                                   // the bed's inside, dark behind
    c.rect(6, 7, 1, 1, C(0xE83A3A))                                    // the tail light, on the bed's corner post
    let a = ramp * .pi / 2, len = 5.5, hx = 5.5, hy = 11.5
    let tx = hx - sin(a) * len, ty = hy - cos(a) * len
    c.glowLine(hx, hy, tx, ty, core: crawlTruckPurple, glow: C(0x000000, 0), coreR: 0.9, glowR: 1)
    c.glowLine(hx, hy - 0.5, tx, ty - 0.5, core: crawlTruckLight, glow: C(0x000000, 0), coreR: 0.35, glowR: 0.4)
}

/// The steel ladder, unrolling from the open tailgate's edge (`top`, the row under it) to the ground over the second
/// half of `ramp`: two bright rails a rung's width apart behind the back tyre, a rung every other row.
private func crawlTruckLadder(_ c: PixelCanvas, ramp: Double, top: Int) {
    guard ramp > 0.5 else { return }
    let bottom = top + Int((Double(28 - top) * min(1, (ramp - 0.5) * 2)).rounded())
    guard bottom > top else { return }
    c.rect(0, top, 1, bottom - top + 1, crawlTruckSteelLight)
    c.rect(3, top, 1, bottom - top + 1, crawlTruckSteel)
    for y in stride(from: top + 1, through: bottom, by: 2) { c.rect(1, y, 2, 1, crawlTruckSteel) }
    c.rect(0, top, 4, 1, crawlTruckSteelDark)                           // the hooks over the tailgate's edge
}
