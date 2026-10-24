import Foundation

// Superclawdtural's ride (`Ride`): Baby, the black 1967 Chevrolet Impala, drawn nose to the right on the rides'
// `Ride.width`×`Ride.height` canvas. Who rides is `huntTheme`'s `ride:` closure (HuntRoster.swift): everyone.
//
// She's long and low: a four-door hardtop, so no pillar between the side windows, and both of them wound down on the
// dark cabin and the seat backs. A long trunk behind, a long hood in front, the rear hips kicked up a row over the back
// wheel. Black paint would vanish on a dark desktop, so she's lit in cool blue-grey: a bright run along the roof and
// down the back pillar, a catch light along both flanks, and plenty of chrome (the belt line, the rocker strip, the
// wheel-arch lips, the bumpers, the hubcaps, the barred grille at her nose). She drives in along the ground
// (`Ride.drives`) with her round headlight lit and red tail lights, the hubcaps turning. When she stops (`ramp` 0…1)
// the rear door swings out for whoever's leaving, and the trunk lid swings up, its underside lit warm, on the arsenal
// standing up in the trunk light: a canister of salt, a pump shotgun standing tall and the machete, a glint hopping
// over them. As they get in, the lid comes down over it
// all and the door shuts, and she drives off.

extension Ride {
    /// Baby: she drives in, and whoever's leaving gets in at the back door, the trunk up behind them.
    static let huntImpala = Ride(key: "huntImpala", arrival: .drives, boardingOffset: 8) { c, ramp, engines, _, t in
        huntDrawImpala(c, ramp: ramp, moving: engines, t: t)
    }
}

// Her paint, chrome and cabin.
private let paint = C(0x15171B), paintMid = C(0x262A32), paintLow = C(0x0B0C0F), seam = C(0x060709)
private let roofLight = C(0x9AAECC), flank = C(0x56667E), sheen = C(0x343C4A)
private let chrome = C(0xC8D0DA), chromeD = C(0x7A8494), chromeL = C(0xF2F6FA)
private let cabin = C(0x0A0B0E), headliner = C(0x1E2128), seat = C(0x2C2F36), seatL = C(0x4C515C)

/// The wheels' centres: the tyres reach down to the canvas's bottom row (28).
private let wheels = [12, 53], hub = 24

/// The Impala. `moving`: driving, the wheels turning and the headlights lit; `ramp` 0…1 is the stop and the boarding.
func huntDrawImpala(_ c: PixelCanvas, ramp: Double, moving: Bool, t: Double) {
    let open = ramp * ramp * (3 - 2 * ramp)          // eased, so the lid and door slow at either end
    huntImpalaGreenhouse(c)
    huntImpalaBody(c, lit: moving)
    for wx in wheels { huntImpalaWheel(c, wx, spin: moving ? t * 12 + Double(wx) : 0.8) }
    if ramp > 0 {
        huntImpalaDoor(c, open)
        huntImpalaTrunk(c, open, t: t)
    }
}

/// The roof and the side windows: the back pillar sloping long and wide down to the trunk, a flat roof lit along its
/// top with a chrome drip rail under it, the windscreen raked down to the hood; both windows wound down, so the
/// openings (four rows tall) show the dark cabin, the back seat and the front seat's backs, the rear-view mirror and
/// the rim of the steering wheel, with no pillar between them, and the glass's top edge peeping up over the door.
private func huntImpalaGreenhouse(_ c: PixelCanvas) {
    func rear(_ y: Int) -> Int { 18 + (15 - y) * 7 / 4 }       // the back pillar's slope, row by row
    func front(_ y: Int) -> Int { 46 - (15 - y) * 7 / 4 }      // the windscreen's
    for y in 10...15 { c.rect(rear(y), y, front(y) - rear(y) + 1, 1, paint) }
    c.rect(rear(10), 10, front(10) - rear(10) + 1, 1, roofLight)                    // the roof, catching the light
    for y in 11...15 { c.px(rear(y), y, roofLight); c.px(rear(y) + 1, y, flank) }   // down the back pillar's edge
    // The open windows, from the wide back pillar to the thin chrome-edged windscreen pillar, the drip rail over them.
    for y in 11...14 {
        let l = rear(y) + 3, r = front(y) - 2
        c.rect(l, y, r - l + 1, 1, y == 11 ? headliner : cabin)
        c.px(r + 1, y, chrome)
    }
    c.rect(26, 12, 5, 3, seat); c.rect(26, 12, 5, 1, seatL)                          // the back seat's back
    c.rect(35, 12, 4, 3, seat); c.rect(35, 12, 4, 1, seatL); c.px(38, 13, C(0x1E2026))   // the front seat's back
    c.rect(40, 11, 2, 1, C(0x5A606C))                                                // the rear-view mirror
    c.px(41, 13, C(0x4E535E)); c.px(42, 14, C(0x4E535E))                            // the steering wheel's rim
    // The wound-down glass, its top edge just showing over the door in both openings.
    c.rect(rear(14) + 4, 14, 8, 1, C(0x3C4656)); c.rect(rear(14) + 4, 14, 2, 1, C(0x6C7C94))
    c.rect(33, 14, 9, 1, C(0x3C4656)); c.rect(33, 14, 2, 1, C(0x6C7C94))
    c.rect(19, 15, 27, 1, chrome)                                                    // the chrome belt line
    c.px(19, 15, chromeL)
}

/// The long body: the trunk deck and the rear hips a row higher than the doors and hood, lit along the top, a catch
/// light down both flanks, darker below; door seams and handles, the chrome rocker strip, bumpers, the barred grille at
/// the nose, the round headlight (lit while she drives, a soft beam ahead) and the red tail lights.
private func huntImpalaBody(_ c: PixelCanvas, lit: Bool) {
    c.rect(2, 16, 61, 9, paint)
    c.rect(3, 15, 16, 1, paint)                                     // the rear hips and the trunk lid
    c.rect(3, 15, 16, 1, flank); c.px(3, 15, roofLight); c.px(4, 15, roofLight)
    c.rect(2, 16, 17, 1, sheen); c.rect(19, 16, 44, 1, flank)       // the flanks' catch light
    c.rect(2, 17, 61, 1, paintMid)
    c.rect(2, 16, 1, 6, sheen)                                      // the tail, facing the light
    c.rect(62, 17, 1, 5, paintLow)                                  // the nose, in shade
    c.rect(2, 23, 61, 2, paintLow)
    c.rect(5, 20, 55, 1, sheen)                                     // the crease along the side
    // The doors: frameless (a hardtop's), their seams and chrome handles.
    c.rect(19, 16, 1, 7, seam); c.rect(32, 16, 1, 8, seam); c.rect(46, 16, 1, 7, seam)
    c.rect(29, 18, 2, 1, chrome); c.rect(43, 18, 2, 1, chrome)
    c.rect(18, 23, 31, 1, chromeD)                                  // the rocker strip
    c.rect(18, 24, 31, 1, paintLow)
    // The badge on the front fender: a little chrome bar and a red fleck.
    c.rect(53, 18, 3, 1, chromeD); c.px(53, 18, C(0xC8303A))
    // The lights: three red lenses at the tail, the round headlight in the fender's front.
    c.rect(2, 17, 2, 3, C(0xB8202A)); c.px(2, 17, C(0xFF6A5A)); c.px(3, 19, C(0x7A1018))
    c.rect(57, 17, 3, 3, chromeD)                                    // the headlight's bezel
    c.rect(58, 17, 2, 2, lit ? C(0xFFF6C8) : C(0xBFC2B6)); c.px(58, 17, lit ? C(0xFFFFFF) : C(0xE4E6DC))
    // The grille, turned a little toward us: a chrome surround, its bars across a black mouth, the top one lit.
    c.rect(60, 16, 5, 5, chromeD); c.rect(60, 16, 5, 1, chrome); c.px(60, 16, chromeL)
    for y in 17...19 { c.rect(61, y, 3, 1, y == 18 ? chrome : seam) }
    // The bumpers' chrome.
    c.rect(1, 21, 4, 2, chrome); c.rect(1, 21, 4, 1, chromeL); c.rect(1, 23, 3, 1, chromeD)
    c.rect(59, 21, 6, 2, chrome); c.rect(59, 21, 6, 1, chromeL); c.rect(60, 23, 4, 1, chromeD)
    if lit {
        c.px(60, 17, C(0xFFF6C8, 0.22)); c.px(60, 18, C(0xFFF6C8, 0.22))   // the headlight's glow, then its beam
        c.rect(65, 16, 1, 4, C(0xFFF6C8, 0.2))
        c.rect(1, 17, 1, 3, C(0xFF4A3A, 0.2))                              // the tail lights' glow
    }
}

/// A wheel at column `wx`: the arch cut dark into the body with a chrome lip round its top, a black tyre (no
/// whitewall) and a chrome hubcap whose dimple and the tread's glint turn by `spin`.
private func huntImpalaWheel(_ c: PixelCanvas, _ wx: Int, spin: Double) {
    for y in (hub - 6)...23 {
        for x in (wx - 6)...(wx + 6) {
            let d = Double((x - wx) * (x - wx) + (y - hub) * (y - hub))
            if d <= 25.5 { c.px(x, y, C(0x060708)) }
            else if d <= 33, y <= hub - 2 { c.px(x, y, chrome) }
        }
    }
    c.circle(wx, hub, 4, C(0x111216))
    c.circle(wx, hub, 3, C(0x23252B))
    c.circle(wx, hub, 2, chrome)
    c.px(wx, hub, chromeD); c.px(wx - 1, hub - 1, chromeL)
    let a = spin
    c.px(wx + Int((cos(a) * 2).rounded()), hub + Int((sin(a) * 2).rounded()), chromeD)          // the hubcap's dimple
    c.px(wx + Int((cos(a + 2) * 3.6).rounded()), hub + Int((sin(a + 2) * 3.6).rounded()), C(0x40434B))   // the tread
}

/// How wide a panel `w` px long looks, side on, swung `k` 0…1 of the way open (about 63°).
private func huntSwung(_ w: Int, _ k: Double) -> Int { max(2, Int((Double(w) * cos(k * 1.1)).rounded())) }

/// The rear door, hinged at its front edge (x 32), swinging out toward us: frameless, so only its lower panel moves,
/// narrowing to an edge-on panel at the hinge, and the doorway shows the back seat, its cushion and the dark footwell.
private func huntImpalaDoor(_ c: PixelCanvas, _ k: Double) {
    c.rect(20, 16, 12, 8, cabin)
    c.rect(21, 15, 4, 5, seat); c.rect(21, 15, 4, 1, seatL); c.rect(24, 16, 1, 4, C(0x1E2026))   // the seat back
    c.rect(21, 19, 10, 1, seatL); c.rect(21, 20, 10, 1, seat); c.rect(21, 21, 10, 1, C(0x1A1C22))
    c.rect(20, 23, 12, 1, chromeD)                                                                  // the sill plate
    let pw = huntSwung(12, k), x0 = 32 - pw, drop = Int((2 * k).rounded()), rise = Int((1.5 * k).rounded())
    c.rect(x0, 16, pw, 8, k < 0.25 ? paint : sheen)                    // the door's skin, turning to the light
    c.rect(x0, 16, pw, 1, flank); c.rect(x0, 23, pw, 1, chrome)
    if pw > 2 { c.px(x0 + 1, 18, chrome) }                             // the handle
    for i in 0..<pw {   // nearer us toward its free edge, it reaches a little past the body, top and bottom
        let f = Double(pw - 1 - i) / Double(max(1, pw - 1))
        let down = Int((Double(drop) * f).rounded()), up = Int((Double(rise) * f).rounded())
        if down > 0 { c.rect(x0 + i, 25, 1, down, paintLow) }
        if up > 0 { c.rect(x0 + i, 16 - up, 1, up, flank) }
    }
    c.rect(x0, 16 - rise, 1, 8 + rise + drop, chrome)                  // its free edge, nearest us
    c.rect(31, 16, 1, 8, seam)                                         // the hinge side, in shade
}

/// The trunk: its lid hinged at the front (by the back window) swinging up to about 65°, its top lit cool and its
/// underside warm from the trunk light, and the arsenal rising into view over the sill as it opens: a big canister of
/// salt, a pump shotgun standing on its stock (the steel barrel tall and lit, the wooden pump halfway up) and the
/// machete, a glint hopping over them.
private func huntImpalaTrunk(_ c: PixelCanvas, _ k: Double, t: Double) {
    let hinge = (x: 18.5, y: 15.5), len = 13.0, a = k * 1.13
    let d = (x: -cos(a), y: -sin(a)), n = (x: -sin(a), y: cos(a))             // along the lid, and toward its underside
    let tip = (x: hinge.x + d.x * len, y: hinge.y + d.y * len)
    func line(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double) {
        c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.05)
    }
    c.rect(3, 15, 16, 1, C(0x2A2016))                                          // the opening, warm in the trunk light
    // The space under the raised lid, lit a dim warm brown by the trunk light: everything stands against it, so the
    // arsenal reads as one lit shape rather than loose bits.
    if tip.y < 14 {
        for y in Int(tip.y.rounded())...14 {
            let f = (hinge.y - Double(y)) / (hinge.y - tip.y)
            let r = Int((hinge.x + d.x * len * f).rounded()) - 1
            let l = Int((3 + (tip.x - 3) * (14.5 - Double(y)) / (14.5 - tip.y)).rounded())
            if r >= l { c.rect(l, y, r - l + 1, 1, C(0x3A2A1C)) }
        }
    }
    let down = 9 - Int((9 * min(1, k / 0.8)).rounded())                        // 9 rows down while it's shut, 0 open
    func art(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ col: Px) {   // only what's above the sill and under the lid shows
        for cx in x..<(x + w) {
            let lid = Int((hinge.y - (hinge.x - Double(cx)) * tan(a)).rounded()) + 2
            let top = max(y + down, lid), bottom = min(14, y + down + h - 1)
            if bottom >= top { c.rect(cx, top, 1, bottom - top + 1, col) }
        }
    }
    // The salt: a big blue canister, lit down its left, a silver cap and a white label band.
    art(3, 9, 4, 6, C(0x2E62B8)); art(3, 10, 1, 5, C(0x6A9AE8)); art(6, 10, 1, 5, C(0x1C3E7A))
    art(3, 9, 4, 1, C(0xC8D0DA)); art(3, 12, 4, 1, C(0xF0F2F6)); art(6, 12, 1, 1, C(0xB0B8C4))
    // The shotgun on its stock: the wooden stock in the trunk, the dark receiver, the steel barrel standing tall (lit
    // down its left, the magazine tube in shade beside it) and the wooden pump halfway up.
    art(8, 12, 3, 3, C(0x9A5E30)); art(8, 12, 1, 3, C(0xC8844A)); art(10, 13, 1, 2, C(0x6A3E1E))
    art(8, 10, 2, 2, C(0x2E3238)); art(8, 10, 1, 1, C(0x5A606C))
    art(8, 2, 1, 8, C(0xC8D0DA)); art(9, 3, 1, 7, C(0x6A7484))
    art(8, 5, 2, 2, C(0xB87A44)); art(8, 5, 1, 1, C(0xE0A468))
    // The machete: the dark grip and its guard, the wide pale blade, its edge catching the light.
    art(12, 12, 2, 3, C(0x2A1A12)); art(12, 11, 3, 1, C(0x5A606C))
    art(12, 5, 2, 6, C(0xC8D0DA)); art(12, 6, 1, 5, chromeL); art(13, 5, 1, 1, C(0x8A94A2))
    if k > 0.8 {   // a glint, hopping from one to the next
        let spots = [(8, 2), (12, 6), (3, 9), (8, 5)]
        let g = spots[Int(t * 4) % spots.count]
        c.px(g.0, g.1, C(0xFFFFFF))
    }
    // The lid: black, its top lit cool, its underside warm.
    line(hinge.x, hinge.y, tip.x, tip.y, paint, 0.95)
    line(hinge.x - n.x * 0.9, hinge.y - n.y * 0.9, tip.x - n.x * 0.9, tip.y - n.y * 0.9, roofLight, 0.4)
    if k > 0.15 { line(hinge.x + n.x * 0.9, hinge.y + n.y * 0.9, tip.x + n.x * 0.9, tip.y + n.y * 0.9, C(0xD8A060), 0.35) }
}
