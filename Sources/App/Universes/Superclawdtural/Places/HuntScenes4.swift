import Foundation

// Places: home, and the dark places: the house in Lawrence, Purgatory, the Empty and the open road. Each place is a
// `Place` in the dictionary below (its name, the tint of the window's card area under it, its still picture and what
// moves there) and its drawing in an extension of `Scenes`, with a frame function the still picture and the moving
// layer share so they line up. Check them with `build/preview place out.png <key>`, at window size and at screen-saver
// size.
//
// Lawrence and the road keep the universe's night palette (Impala black, dusty denim blue, amber light); Purgatory is
// green mist and the Empty black goo with a faint violet sheen, standing apart. Both dark places keep a mid-dark band
// of mist or haze over a mid-dark floor, so the crew's white outlines and names still read on them. The busy detail
// goes higher up and at the sides; props keep their size in `Scenes.unit(g)` steps.

let huntScenes4: [Location: Place] = [
    .huntLawrence: Place(name: "Lawrence, Kansas", panel: 0x10141E, still: Scenes.huntLawrence, moving: Scenes.huntLawrenceLife),
    .huntPurgatory: Place(name: "Purgatory", panel: 0x101A14, still: Scenes.huntPurgatory, moving: Scenes.huntPurgatoryLife),
    .huntEmpty: Place(name: "The Empty", panel: 0x0E0A14, still: Scenes.huntEmpty, moving: Scenes.huntEmptyLife),
    .huntRoad: Place(name: "The Open Road", panel: 0x0E121C, still: Scenes.huntRoad, moving: Scenes.huntRoadLife),
]

// MARK: - Lawrence, Kansas

/// A neighbour's house in the dark, `w` wide on row `base`: dusky siding, a dark roof (hipped, or a gable seen side on),
/// unlit windows with a glint of moonlight, a little porch. Everyone else on the street is asleep.
private func huntP4Neighbour(_ c: PixelCanvas, _ x: Int, _ base: Int, _ w: Int, _ s: Int, hipped: Bool) {
    let side = C(0x3A4258), sideD = C(0x31384C), sideL = C(0x4A536C), roof = C(0x15151B), roofL = C(0x2C2C38)
    let trim = C(0x5A6072), pane = C(0x111520), glint = C(0x3A4660)
    let wallH = 20 * s
    c.rect(x, base - wallH, w, wallH, side)
    for y in stride(from: base - wallH + s, to: base, by: 2 * s) { c.rect(x, y, w, max(1, s / 2), sideD) }
    c.rect(x, base - wallH, s, wallH, sideL)
    // The roof: a hip in a trapezoid, or a gable end facing us.
    let rise = 12 * s
    for k in 0..<rise {
        let y = base - wallH - rise + k
        if hipped {
            let inset = (rise - k) * 2
            c.rect(x - 2 * s + inset, y, w + 4 * s - 2 * inset, 1, roof)
            c.rect(x - 2 * s + inset, y, max(1, s), 1, roofL)
        } else {
            let half = (w / 2 + 2 * s) * (k + 1) / rise
            c.rect(x + w / 2 - half, y, 2 * half, 1, roof)
            let inner = half - 3 * s
            if inner > 0 && k > 2 * s { c.rect(x + w / 2 - inner, y, 2 * inner, 1, side) }
            c.rect(x + w / 2 - half, y, max(1, s), 1, roofL)
        }
    }
    c.rect(x - 2 * s, base - wallH - s, w + 4 * s, s, roof)
    // The windows, two up and two down, dark, a pale glint on each pane.
    for (u, v) in [(4, -17), (w / s - 10, -17), (4, -9), (w / s - 10, -9)] {
        c.rect(x + u * s - s, base + v * s - s, 8 * s, 7 * s, trim)
        c.rect(x + u * s, base + v * s, 6 * s, 5 * s, pane)
        c.rect(x + u * s, base + v * s, 2 * s, max(1, s / 2), glint); c.rect(x + u * s, base + v * s, max(1, s / 2), 2 * s, glint)
        c.rect(x + u * s + 3 * s, base + v * s, max(1, s / 2), 5 * s, trim.alpha(0.6))
    }
    if !hipped { c.rect(x + w / 2 - 2 * s, base - wallH - 7 * s, 4 * s, 4 * s, pane); c.rect(x + w / 2 - 2 * s, base - wallH - 7 * s, 4 * s, max(1, s / 2), glint) }
    // The door and its stoop.
    let dx = x + w / 2 - 3 * s
    c.rect(dx, base - 10 * s, 6 * s, 10 * s, C(0x22242C)); c.rect(dx, base - 10 * s, 6 * s, max(1, s / 2), C(0x3A3E4A))
    c.rect(dx - 2 * s, base - s, 10 * s, s, C(0x3A3C44))
}

extension Scenes {
    /// Where things stand on the street in Lawrence, shared by the still picture and the moving layer: the far tree
    /// line, the Winchester house (its left edge, width and foot), the lit nursery window (its top-left corner), the
    /// old tree (its trunk and the row its canopy hangs down to) and the street lamp.
    static func huntLawrenceFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, house: (x: Int, w: Int, base: Int),
                                                                 lit: (x: Int, y: Int), tree: (x: Int, canopy: Int), lamp: Int) {
        let s = unit(g), tall = isTall(c)
        let house = (x: c.w * 47 / 100, w: 60 * s, base: g - 7 * s)
        let lit = (x: house.x + 10 * s, y: house.base - 25 * s)
        let tree = (x: c.w * 14 / 100, canopy: tall ? g - 88 * s : g - 32 * s)
        return (g - 22 * s, house, lit, tree, c.w * 88 / 100)
    }

    /// The house at 1458 Lawrence Street, Lawrence, Kansas, late at night: a two-storey clapboard house under its
    /// front gable, a porch across the front, every window dark but one, upstairs on the left, the nursery, lit amber.
    /// Dark neighbours either side, the back-yard trees black against a denim sky, a full moon, the old tree on the
    /// left with autumn in its leaves, a street lamp on the right, and the sidewalk in front. On the screen saver the
    /// old tree spreads its whole crown with a rope swing under it, power lines cross the sky, and banks of night cloud
    /// lit silver by the moon drift over the stars, a skein of geese below them.
    static func huntLawrence(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntLawrenceFrame(c, g), tall = isTall(c)
        // The sky: near black up high, a dusty denim blue down at the roofs.
        if tall {
            c.gradient(0, f.horizon, C(0x070A16), C(0x2A3450), bands: 9)
            c.stars(0, f.horizon - 40 * s, density: 110, seed: 41)
        } else {
            c.gradient(0, f.horizon, C(0x0C1222), C(0x2C3652), bands: 6)
            c.stars(0, f.horizon - 10 * s, density: 70, seed: 41)
        }
        // The moon, full, with a pale halo and its grey seas.
        let mx = c.w * (tall ? 58 : 30) / 100, my = tall ? g * 16 / 100 : 9 * s, mr = tall ? 10 * s : 5 * s
        for r in stride(from: mr * 4, to: mr, by: -max(1, mr / 2)) { c.circle(mx, my, r, C(0xC8D0E8, 0.035)) }
        c.circle(mx, my, mr, C(0xE6E2CE))
        c.circle(mx + mr / 3, my - mr / 4, max(1, mr / 3), C(0xC6C2B0)); c.circle(mx - mr / 3, my + mr / 3, max(1, mr / 4), C(0xC6C2B0))
        c.rect(mx - mr + s, my - s, max(1, s), 2 * s, C(0xF6F2E2))
        if tall {
            huntLawrenceClouds(c, g)
            // A skein of geese flying south across the moonlight, a little V of dark specks.
            for k in 0..<7 {
                let gx = mx - 40 * s + (k - 3) * 4 * s, gy = my + 26 * s + abs(k - 3) * 2 * s
                c.rect(gx - s, gy, 3 * s, max(1, s / 2), C(0x0A0C14)); c.rect(gx, gy - max(1, s / 2), max(1, s), max(1, s / 2), C(0x0A0C14))
            }
        } else {
            for (xp, yp, len) in [(62, 6, 50), (86, 14, 40)] {
                wisp(c, c.w * xp / 100, yp * s, len * s, C(0x46506E, 0.6), s: s)
                c.rect(c.w * xp / 100 - len * s / 3, yp * s - s, len * s / 3, max(1, s / 2), C(0x8A94B0, 0.35))
            }
        }
        if tall { huntLawrenceWires(c, g) }
        // The back-yard trees behind the houses, rounded crowns black against the sky, taller on the screen saver.
        var x = -4 * s, i = 0
        while x < c.w + 6 * s {
            let r = (tall ? 6 + Int(noise(i + 1500) * 10) : 5 + Int(noise(i + 1500) * 6)) * s
            c.circle(x, f.horizon - r / 2, r, C(0x121822)); c.circle(x - r / 3, f.horizon - r / 2 - r / 3, r / 2, C(0x18202C))
            x += r + Int(noise(i + 1501) * Double(5 * s)); i += 1
        }
        // The lawns: dark grass from the houses down to the sidewalk.
        c.gradient(f.horizon, g, C(0x1E2A22), C(0x24301F), bands: 3)
        for i in 0..<(c.w / (3 * s)) {
            let gx = Int(noise(i * 3 + 1520) * Double(c.w)), gy = f.horizon + Int(noise(i * 3 + 1521) * Double(g - f.horizon))
            c.rect(gx, gy, max(1, s / 2), s, C(0x2E3C28))
        }
        // The neighbours, dark and asleep.
        huntP4Neighbour(c, c.w * 21 / 100, g - 9 * s, 44 * s, s, hipped: true)
        huntP4Neighbour(c, c.w * 71 / 100, g - 9 * s, 40 * s, s, hipped: false)
        if !tall {
            // In the window, the telephone line along the backs of the yards, clear of the moon.
            let poles = [c.w * 41 / 100, c.w * 77 / 100, c.w + c.w * 36 / 100]
            for px in poles.dropLast() {
                c.rect(px, f.horizon - 38 * s, max(1, s), 38 * s, C(0x1A1A20)); c.rect(px - 4 * s, f.horizon - 36 * s, 9 * s, max(1, s), C(0x1A1A20))
                for k in [-4, 4] { c.rect(px + k * s, f.horizon - 37 * s, max(1, s), max(1, s), C(0x5A7A8A)) }
            }
            for k in [-4, 4] {
                for p in 0..<(poles.count - 1) {
                    let a = poles[p] + k * s, b = poles[p + 1] + k * s
                    for xx in a..<min(c.w, b) {
                        let u = Double(xx - a) / Double(b - a)
                        c.px(xx, f.horizon - 36 * s + Int(sin(u * .pi) * Double((k < 0 ? 3 : 4) * s)), C(0x14141A, 0.85))
                    }
                }
            }
        }
        huntLawrenceHouse(c, g)
        // A low hedge along the front of the porch, and the front walk down to the sidewalk.
        let h = f.house
        c.rect(h.x + 26 * s, h.base, 8 * s, g - h.base, C(0x44464C)); c.rect(h.x + 26 * s, h.base, max(1, s), g - h.base, C(0x55575E))
        for (k, bx) in [h.x + 2 * s, h.x + 10 * s, h.x + 18 * s, h.x + 42 * s, h.x + 50 * s, h.x + 58 * s].enumerated() {
            c.ellipse(bx, h.base, 5 * s, 3 * s, C(0x16221A)); c.ellipse(bx - s, h.base - s, 3 * s, 2 * s, k % 2 == 0 ? C(0x22301F) : C(0x1E2A1C))
        }
        // The mailbox at the end of the walk, its flag down.
        let mb = h.x - 8 * s
        c.rect(mb, g - 7 * s, max(1, s), 7 * s, C(0x3A2C22)); c.rect(mb - 2 * s, g - 10 * s, 5 * s, 3 * s, C(0x3A404C))
        c.rect(mb - 2 * s, g - 10 * s, 5 * s, max(1, s / 2), C(0x5A6272)); c.rect(mb + 3 * s, g - 10 * s, max(1, s), 2 * s, C(0x8A2A22))
        // A picket fence along the neighbours' lawns, grey in the moonlight, low.
        for (x0, x1) in [(0, c.w * 9 / 100), (c.w * 69 / 100, c.w * 84 / 100)] {
            c.rect(x0, g - 4 * s, x1 - x0, max(1, s / 2), C(0x4E5464))
            for px in stride(from: x0, to: x1, by: 3 * s) { c.rect(px, g - 6 * s, max(1, s), 6 * s, C(0x4E5464)); c.px(px, g - 6 * s, C(0x6A7082)) }
        }
        huntLawrenceTree(c, g)
        huntLawrenceLamp(c, g)
        // The sidewalk: dark concrete slabs, plain enough for the crew to stand on.
        c.ground(g, C(0x34363C), edge: C(0x4E5058), speck: C(0x2C2E34), seed: 81)
        for x in stride(from: 0, to: c.w, by: 18 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x2A2C32)) }
    }

    /// The Winchester house: pale clapboard in the moonlight under a dark front gable, white trim, shutters by the
    /// upstairs windows, a chimney, the porch on square posts with a rail, a red door. Every window dark but the
    /// nursery's.
    private static func huntLawrenceHouse(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntLawrenceFrame(c, g), h = f.house
        let x = h.x, b = h.base
        func r(_ u: Int, _ v: Int, _ w: Int, _ hh: Int, _ col: Px) { c.rect(x + u * s, b + v * s, w * s, hh * s, col) }
        let side = C(0x5A6480), sideD = C(0x4C5570), sideL = C(0x727C98), trim = C(0x9EA4B6), trimD = C(0x6E7488)
        let roof = C(0x1C1A22), roofL = C(0x3A3644), roofM = C(0x2A2832)
        // The chimney on the right slope, old red brick, behind the roof.
        r(47, -45, 5, 12, C(0x5A3028)); r(47, -45, 1, 12, C(0x7A4436)); r(46, -46, 7, 1, C(0x3A2420))
        // The walls, the clapboard in courses, lit on the left.
        r(0, -28, 60, 28, side)
        for v in stride(from: -27, to: 0, by: 2) { c.rect(x, b + v * s, 60 * s, max(1, s / 2), sideD) }
        r(0, -28, 1, 28, sideL); r(59, -28, 1, 28, sideD)
        // The front gable: the roof's two rakes, the siding between them, a small attic window, white bargeboards.
        let rise = 18 * s, peak = b - 46 * s, mid = x + 30 * s
        for k in 0..<rise {
            let half = 34 * s * (k + 1) / rise, y = peak + k
            c.rect(mid - half, y, 2 * half, 1, roof)
            let inner = half - 5 * s
            if inner > 0 && k > 3 * s {
                c.rect(mid - inner, y, 2 * inner, 1, (y - peak) % (2 * s) < s ? side : sideD)
                c.rect(mid - inner, y, max(1, s / 2), 1, trim); c.rect(mid + inner - max(1, s / 2), y, max(1, s / 2), 1, trimD)
            }
            c.rect(mid - half, y, max(1, s), 1, roofL)
        }
        c.rect(x - 4 * s, b - 28 * s, 68 * s, s, roofM); c.rect(x - 4 * s, b - 27 * s, 68 * s, max(1, s / 2), trimD)
        r(27, -38, 6, 5, trim); r(28, -37, 4, 3, C(0x121622)); r(28, -37, 2, 1, C(0x3A4660))
        // The trim between the floors and the corner boards.
        r(-1, -15, 62, 1, trim); r(0, -28, 1, 13, trim)
        // The upstairs windows: the nursery on the left lit amber behind thin curtains, the other dark; shutters.
        func window(_ u: Int, _ v: Int, _ w: Int, _ hh: Int, lit: Bool, shutters: Bool) {
            if shutters {
                for su in [u - 3, u + w + 1] {
                    r(su, v, 2, hh, C(0x26343C))
                    for k in stride(from: 1, to: hh, by: 2) { c.rect(x + su * s, b + (v + k) * s, 2 * s, max(1, s / 2), C(0x1C262C)) }
                }
            }
            r(u - 1, v - 1, w + 2, hh + 2, trim); r(u - 1, v + hh, w + 2, 1, trimD)
            if lit {
                r(u, v, w, hh, C(0xE0A048)); r(u, v, w, hh / 2, C(0xF0C068)); r(u + 2, v + 1, w - 4, 2, C(0xFFE0A0))
                r(u, v, 2, hh, C(0xA85A30)); r(u + w - 2, v, 2, hh, C(0xA85A30))
            } else {
                r(u, v, w, hh, C(0x111520)); r(u, v + hh / 2, w, hh - hh / 2, C(0x0C0F18))
                r(u, v, 2, 1, C(0x3E4A66)); r(u, v, 1, 2, C(0x3E4A66))
            }
            c.rect(x + (u + w / 2) * s, b + v * s, max(1, s / 2), hh * s, lit ? C(0x7A4A2A) : trimD)
            c.rect(x + u * s, b + (v + hh / 2) * s, w * s, max(1, s / 2), lit ? C(0x7A4A2A) : trimD)
        }
        // The nursery's glow on the siding round its window.
        for rr in stride(from: 14 * s, to: 4 * s, by: -2 * s) { c.ellipse(f.lit.x + 4 * s, f.lit.y + 4 * s, rr, rr * 3 / 4, C(0xF0A850, 0.035)) }
        window(10, -25, 8, 9, lit: true, shutters: true)
        window(42, -25, 8, 9, lit: false, shutters: true)
        // The ground floor: two dark windows and the door, all in the porch's shade.
        window(7, -11, 9, 7, lit: false, shutters: false)
        window(44, -11, 9, 7, lit: false, shutters: false)
        r(26, -12, 8, 10, trim); r(27, -11, 6, 9, C(0x5A2620)); r(27, -11, 1, 9, C(0x7A3A2E))
        r(28, -10, 4, 3, C(0x48201A)); r(28, -6, 4, 3, C(0x48201A)); r(32, -6, 1, 1, C(0xC8A050))
        r(0, -14, 60, 12, C(0x080A12, 0.42))
        // The porch: its roof across the front lit along the top, square posts, a rail with balusters, the deck.
        r(-3, -15, 66, 2, roofM); r(-3, -15, 66, 1, roofL); r(-3, -13, 66, 1, trim)
        for (k, u) in [-2, 18, 40, 60].enumerated() {
            r(u, -12, 2, 10, k == 3 ? trimD : trim); r(u + 1, -12, 1, 10, trimD)
        }
        for (u0, u1) in [(0, 18), (20, 26), (34, 40), (42, 60)] {
            r(u0, -6, u1 - u0, 1, trim)
            for u in stride(from: u0 + 1, to: u1, by: 2) { r(u, -5, 1, 3, trimD) }
        }
        r(-3, -2, 66, 1, C(0x5A5A64)); r(-3, -1, 66, 1, C(0x2C2C34))
        r(25, -1, 10, 1, C(0x5A5A62)); r(24, 0, 12, 1, C(0x4A4A52))
    }

    /// The old tree on the left: a broad trunk, its roots in the lawn, heavy limbs, and a crown of dark leaves going
    /// to rust and amber with autumn, lit faintly from the moon on the upper left.
    private static func huntLawrenceTree(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntLawrenceFrame(c, g), tall = isTall(c)
        let tx = f.tree.x, top = f.tree.canopy, base = g - 6 * s
        let bark = C(0x2C2620), barkL = C(0x443A30), barkD = C(0x1A1614)
        let tw = tall ? 14 * s : 8 * s
        c.ellipse(tx + 4 * s, g - 2 * s, 20 * s, 2 * s, C(0x0A0E0A, 0.5))
        c.rect(tx - tw / 2, top, tw, base - top, bark)
        c.rect(tx - tw / 2, top, 2 * s, base - top, barkL); c.rect(tx + tw / 2 - 2 * s, top, 2 * s, base - top, barkD)
        for y in stride(from: top + 3 * s, to: base, by: 5 * s) {   // bark in short furrows
            c.rect(tx - tw / 2 + 3 * s + (y / max(1, s)) % 3 * s, y, max(1, s), 3 * s, barkD)
        }
        for k in [-1, 1] {   // the roots flaring into the lawn
            for d in 0..<4 { c.rect(tx + k * (tw / 2 + d * s) - (k < 0 ? s : 0), base - (3 - d) * s, s, (4 - d) * s + s, bark) }
        }
        // The limbs reaching up and out into the crown.
        let reach = tall ? 62 : 30, rise = tall ? 50 : 34
        for (ex, ey) in [(-reach, -rise / 2), (reach, -rise * 3 / 5), (-reach / 2, -rise * 4 / 5), (reach / 2, -rise * 9 / 10), (0, -rise)] {
            c.glowLine(Double(tx), Double(top + 4 * s), Double(tx + ex * s), Double(top + ey * s), core: bark, glow: C(0, 0),
                       coreR: Double(s) * (tall ? 2.4 : 1.6), glowR: Double(s) * (tall ? 2.5 : 1.7))
        }
        // The crown: clumps of leaves, dark below, lit on top and to the left, the leaves turning rust and amber in
        // short strokes here and there.
        let cy = top - (tall ? 40 : 14) * s, rx = (tall ? 84 : 40) * s, ry = (tall ? 52 : 20) * s
        let n = tall ? 130 : 40
        let clumps = (0..<n).map { i -> (x: Int, y: Int, r: Int) in
            let a = noise(i * 3 + 1600) * 2 * .pi, d = noise(i * 3 + 1601).squareRoot()
            return (tx + Int(cos(a) * d * Double(rx)), cy + Int(sin(a) * d * Double(ry)), (5 + Int(noise(i * 3 + 1602) * (tall ? 8 : 5))) * s)
        }
        // In passes, so the clumps run together into one crown: the dark mass, the leaves catching a little light on
        // each clump's upper left, the brightest on the side towards the moon, then the turning leaves in strokes.
        for cl in clumps { c.circle(cl.x, cl.y, cl.r, C(0x141C14)) }
        for (i, cl) in clumps.enumerated() where cl.y < cy + ry / 2 {
            c.circle(cl.x - cl.r / 4, cl.y - cl.r / 3, cl.r / 2, noise(i + 1700) > 0.75 ? C(0x2A2818) : C(0x1C281A))
        }
        for cl in clumps where cl.x < tx + rx / 4 && cl.y < cy { c.circle(cl.x - cl.r / 3, cl.y - cl.r / 2, cl.r / 4, C(0x2A3824)) }
        for (i, cl) in clumps.enumerated() {
            for k in 0..<3 where noise(i * 5 + k + 1710) > 0.55 {
                let lx = cl.x + Int((noise(i * 5 + k + 1720) - 0.5) * Double(cl.r * 2)), ly = cl.y + Int((noise(i * 5 + k + 1730) - 0.5) * Double(cl.r * 2))
                c.rect(lx, ly, 2 * s, max(1, s), k == 0 ? C(0x8A4A22) : C(0x6A3A1E))
            }
        }
        if tall {
            // A rope swing on the low limb on the right, its board hanging still.
            let sx = tx + 22 * s, sy = top - 6 * s
            c.rect(sx, sy, max(1, s / 2), 30 * s, C(0x6A604E)); c.rect(sx + 8 * s, sy - 2 * s, max(1, s / 2), 32 * s, C(0x6A604E))
            c.rect(sx - s, sy + 30 * s, 10 * s, 2 * s, C(0x5A4430)); c.rect(sx - s, sy + 30 * s, 10 * s, max(1, s / 2), C(0x7A6048))
        }
    }

    /// On the screen saver: the power lines across the sky, wooden poles with crossarms and glass insulators, three
    /// wires sagging between.
    private static func huntLawrenceWires(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntLawrenceFrame(c, g)
        let poles = [c.w * 4 / 100, c.w * 36 / 100, c.w * 68 / 100, c.w * 100 / 100]
        let top = f.horizon - 70 * s
        for px in poles {
            c.rect(px - s, top, 2 * s, f.horizon - top, C(0x1A1A20)); c.rect(px - s, top, max(1, s / 2), f.horizon - top, C(0x2C2A30))
            c.rect(px - 9 * s, top + 3 * s, 19 * s, 2 * s, C(0x1A1A20))
            for k in [-8, -3, 4, 9] { c.rect(px + k * s, top + s, max(1, s), 2 * s, C(0x6A8A9A)) }
        }
        for (k, sag) in [(-8, 7), (9, 10)] {
            for i in 0..<(poles.count - 1) {
                let a = poles[i] + k * s, b = poles[i + 1] + k * s
                for xx in max(0, a)..<min(c.w, b) {
                    let u = Double(xx - a) / Double(max(1, b - a))
                    c.px(xx, top + s + Int(sin(u * .pi) * Double(sag * s)), C(0x101016, 0.85))
                }
            }
        }
    }

    /// On the screen saver: banks of night cloud drifting across the upper sky, dark blue puffs lit silver along their
    /// tops by the moon.
    private static func huntLawrenceClouds(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let banks: [(Int, Int, Int)] = [(16, 10, 9), (40, 26, 7), (84, 20, 10), (70, 40, 6), (24, 46, 7), (92, 54, 5)]
        for (k, (xp, yp, r0)) in banks.enumerated() {
            let x = c.w * xp / 100, y = g * yp / 100, r = r0 * s
            let puffs = (0..<6).map { p -> (x: Int, y: Int, r: Int) in
                (x + Int((noise(k * 13 + p + 1900) - 0.5) * Double(r * 7)), y - Int(noise(k * 13 + p + 1910) * Double(r / 2)), r * (2 + p % 3) / 3 + s)
            }
            // In passes, so the puffs run together: the silver rim, the body, the shade along the belly.
            c.ellipse(x, y + r / 2, r * 5, r / 2 + s, C(0x1E2640))
            for p in puffs { c.ellipse(p.x, p.y - p.r / 6, p.r * 3 / 2 + s, p.r * 2 / 3 + s, C(0x5A6688)) }
            for p in puffs { c.ellipse(p.x, p.y, p.r * 3 / 2, p.r * 2 / 3, C(0x2A3452)) }
            for p in puffs { c.ellipse(p.x + p.r / 4, p.y + p.r / 4, p.r, p.r / 3, C(0x222A44)) }
        }
    }

    /// The street lamp on the right: a grey pole, an arm out over the sidewalk, a sodium lamp with its amber pool.
    private static func huntLawrenceLamp(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), lx = huntLawrenceFrame(c, g).lamp, top = g - 40 * s
        for rr in stride(from: 24 * s, to: 4 * s, by: -4 * s) { c.ellipse(lx - 8 * s, g, rr, rr / 4, C(0xE8A040, 0.04)) }
        for rr in stride(from: 10 * s, to: 2 * s, by: -2 * s) { c.circle(lx - 10 * s, top + 3 * s, rr, C(0xF0B050, 0.04)) }
        c.rect(lx, top, 2 * s, g - top, C(0x2A2C32)); c.rect(lx, top, max(1, s / 2), g - top, C(0x464850))
        c.rect(lx - 2 * s, g - 3 * s, 6 * s, 3 * s, C(0x22242A))
        c.rect(lx - 10 * s, top, 11 * s, s, C(0x2A2C32))
        c.rect(lx - 13 * s, top + s, 6 * s, 2 * s, C(0x34363E)); c.rect(lx - 12 * s, top + 3 * s, 4 * s, s, C(0xFFD890))
    }

    /// Lawrence's life: the nursery window's light breathing and, every so often, flickering the way the lights did the
    /// night Azazel came, and autumn leaves blowing off the old tree across the lawns.
    static func huntLawrenceLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntLawrenceFrame(c, g)
        let phase = t.truncatingRemainder(dividingBy: 9.5)
        let stutter = phase > 7.0 && phase < 8.1
        let off = stutter && Int(t * 13) % 3 != 0
        if off {
            c.rect(f.lit.x, f.lit.y, 8 * s, 9 * s, C(0x140C08, 0.7))
        } else {
            let a = 0.05 + (sin(t * 1.7) * 0.5 + 0.5) * 0.04
            for rr in stride(from: 10 * s, to: 4 * s, by: -3 * s) { c.ellipse(f.lit.x + 4 * s, f.lit.y + 4 * s, rr, rr * 3 / 4, C(0xF4B058, a)) }
            if stutter { c.rect(f.lit.x, f.lit.y, 8 * s, 9 * s, C(0xFF7A30, 0.25)) }
        }
        // The leaves, carried off to the right, tumbling as they go and settling on the lawn.
        for i in 0..<8 {
            let speed = 0.07 + noise(i + 1800) * 0.05
            let u = (t * speed + noise(i + 1810)).truncatingRemainder(dividingBy: 1)
            let x0 = f.tree.x + Int((noise(i + 1820) - 0.5) * Double(50 * s)), y0 = f.tree.canopy - Int(noise(i + 1830) * Double(10 * s))
            let x = x0 + Int(u * Double(150 * s)) + Int(sin(t * 1.9 + Double(i)) * Double(3 * s))
            let y = y0 + Int(u * Double(g - y0 - s)) + Int(sin(t * 2.6 + Double(i) * 1.3) * Double(2 * s))
            guard y < g else { continue }
            let tone = [C(0xA85A24), C(0xC8862E), C(0x7A3A1E)][i % 3]
            let flat = Int(t * 3 + Double(i)) % 2 == 0
            c.rect(x, y, flat ? 2 * s : s, flat ? s : 2 * s, tone)
        }
    }
}

// MARK: - Purgatory

extension Scenes {
    /// Where things stand in Purgatory, shared by the still picture and the moving layer: the middle row of trunks
    /// (each one's left edge and width), the near trunks, and the eyes that watch from beside the middle trunks (where,
    /// and whether they're a monster's red or a vampire's gold).
    static func huntPurgatoryFrame(_ c: PixelCanvas, _ g: Int) -> (mid: [(x: Int, w: Int)], near: [(x: Int, w: Int)],
                                                                  eyes: [(x: Int, y: Int, gold: Bool)]) {
        let s = unit(g), tall = isTall(c)
        var mid: [(x: Int, w: Int)] = []
        var x = -2 * s, i = 0
        while x < c.w {
            let w = (5 + Int(noise(i + 2000) * 4)) * s
            mid.append((x, w)); x += w + (22 + Int(noise(i + 2001) * 20)) * s; i += 1
        }
        let near: [(x: Int, w: Int)] = [(c.w * 2 / 100, 13 * s), (c.w * 30 / 100, 10 * s), (c.w * 67 / 100, 11 * s), (c.w * 92 / 100, 14 * s)]
        var eyes: [(x: Int, y: Int, gold: Bool)] = []
        for (k, m) in mid.enumerated() where noise(k + 2050) > 0.3 {
            let right = noise(k + 2051) > 0.4
            let high = tall ? 26 + Int(noise(k + 2052) * 90) : 26 + Int(noise(k + 2052) * 20)
            eyes.append((right ? m.x + m.w + s : m.x - 5 * s, g - high * s, noise(k + 2053) > 0.55))
        }
        return (mid, near, eyes)
    }

    /// Purgatory: an endless wood of bare grey-green trunks fading into a sickly green mist, layer behind layer, the
    /// near trees black and gnarled with roots in the leaf litter, ferns and a fallen log at the sides, the mist lying
    /// thick and pale along the ground so the crew stands out against it. On the screen saver the trunks climb into a
    /// tangle of branches and hanging moss, with a pale green light seeping through the canopy far overhead.
    static func huntPurgatory(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntPurgatoryFrame(c, g), tall = isTall(c)
        // The mist-filled air: dark green high up, paler and greyer towards the ground.
        if tall {
            c.gradient(0, g * 30 / 100, C(0x4A6A52), C(0x1E2C22), bands: 6)
            c.gradient(g * 30 / 100, g - 14 * s, C(0x1E2C22), C(0x40564A), bands: 8)
        } else {
            c.gradient(0, g - 14 * s, C(0x16221A), C(0x40564A), bands: 6)
        }
        c.rect(0, g - 14 * s, c.w, 14 * s, C(0x44594C))
        // The far trunks, ghosts in the mist, thin and many.
        var x = 0, i = 0
        while x < c.w {
            let w = (2 + Int(noise(i + 2100) * 3)) * s
            c.rect(x, 0, w, g, C(0x34483C)); c.rect(x, 0, max(1, s / 2), g, C(0x3E5446))
            x += w + (7 + Int(noise(i + 2101) * 10)) * s; i += 1
        }
        huntPurgatoryMist(c, g, 0, 0.10)
        // The middle row: grey-green trunks with a lit left edge, a few bare branches, bark in strokes.
        let midTop = tall ? g * 24 / 100 : 0, nearTop = tall ? g * 30 / 100 : 0
        for (k, m) in f.mid.enumerated() {
            c.rect(m.x, midTop, m.w, g - midTop, C(0x22302A)); c.rect(m.x, midTop, s, g - midTop, C(0x34463A))
            c.rect(m.x + m.w - s, midTop, s, g - midTop, C(0x1A2620))
            for y in stride(from: midTop + Int(noise(k + 2150) * 8) * s, to: g, by: 9 * s) { c.rect(m.x + 2 * s, y, max(1, s / 2), 4 * s, C(0x1A2620)) }
            let branches = tall ? 4 : 2
            for b in 0..<branches {
                let by = (tall ? g * 34 / 100 : 4 * s) + b * (tall ? g * 11 / 100 : 12 * s) + Int(noise(k * 7 + b + 2160) * Double(6 * s))
                let dir = noise(k * 7 + b + 2165) > 0.5 ? 1 : -1
                let bx = dir > 0 ? m.x + m.w : m.x, len = Double((10 + Int(noise(k * 7 + b + 2170) * 10)) * s)
                c.glowLine(Double(bx), Double(by), Double(bx) + Double(dir) * len, Double(by) - len * 0.6, core: C(0x22302A), glow: C(0, 0),
                           coreR: Double(s) * 0.8, glowR: Double(s) * 0.9)
                c.glowLine(Double(bx) + Double(dir) * len * 0.6, Double(by) - len * 0.36, Double(bx) + Double(dir) * len * 0.9, Double(by) - len * 0.1,
                           core: C(0x22302A), glow: C(0, 0), coreR: Double(s) * 0.5, glowR: Double(s) * 0.6)
            }
        }
        huntPurgatoryMist(c, g, 1, 0.12)
        if tall { huntPurgatoryCanopy(c, g, f.mid, near: false) }
        // The near trees: black, gnarled, roots gripping the leaf litter, lit faintly green on the left.
        for (k, n) in f.near.enumerated() {
            // The trunk row by row, swaying a little side to side and thickening at the foot, its bark in strokes.
            for y in stride(from: nearTop, to: g, by: max(1, s)) {
                let sway = Int(sin(Double(y) / Double(s) * 0.045 + Double(k) * 1.7) * 2.5) * s
                let flare = max(0, y - (g - 14 * s)) / 3
                let x0 = n.x + sway - flare, w = n.w + 2 * flare
                c.rect(x0, y, w, max(1, s), C(0x0E1610)); c.rect(x0, y, 2 * s, max(1, s), C(0x22322A)); c.rect(x0 + 2 * s, y, s, max(1, s), C(0x18241C))
                if (y / max(1, s) + k * 3) % 7 < 4 { c.rect(x0 + w / 2 + ((y / max(1, s) / 7 + k) % 3 - 1) * 2 * s, y, max(1, s), max(1, s), C(0x1A261E)) }
            }
            // A broken branch stub, and a knot, a dark hollow with a lip lit beneath it.
            let sy = max(nearTop + 12 * s, g * 20 / 100 + Int(noise(k + 2215) * Double(g / 3))), right = k % 2 == 0
            let sway = Int(sin(Double(sy) / Double(s) * 0.045 + Double(k) * 1.7) * 2.5) * s
            let sx = right ? n.x + sway + n.w : n.x + sway
            c.glowLine(Double(sx), Double(sy), Double(sx + (right ? 7 : -7) * s), Double(sy - 5 * s), core: C(0x0E1610), glow: C(0, 0),
                       coreR: Double(s) * 1.3, glowR: Double(s) * 1.4)
            let ky = g - (30 + Int(noise(k + 2220) * 14)) * s
            let kx = n.x + n.w / 2 + Int(sin(Double(ky) / Double(s) * 0.045 + Double(k) * 1.7) * 2.5) * s
            c.ellipse(kx, ky, 2 * s, 3 * s, C(0x040806)); c.rect(kx - 2 * s, ky + 3 * s, 4 * s, max(1, s / 2), C(0x2A3C30))
            for (dx, len) in [(-1, 6), (1, 7), (-1, 3), (1, 4)] {
                let rx0 = dx < 0 ? n.x + 2 * s : n.x + n.w - 2 * s
                c.glowLine(Double(rx0), Double(g - 6 * s), Double(rx0 + dx * len * s), Double(g), core: C(0x0E1610), glow: C(0, 0),
                           coreR: Double(s) * 1.2, glowR: Double(s) * 1.3)
            }
            c.rect(n.x - 2 * s, g - 3 * s, n.w + 4 * s, 3 * s, C(0x0E1610))
        }
        if tall { huntPurgatoryCanopy(c, g, f.near, near: true) }
        // Ferns and brambles at the sides, and a fallen log on the left, moss along its top.
        for (k, fx) in [c.w * 8 / 100, c.w * 13 / 100, c.w * 84 / 100, c.w * 88 / 100, c.w * 98 / 100].enumerated() {
            for a in 0..<5 {
                let ang = Double(a) * 0.32 + 0.9, len = Double((5 + (a + k) % 3 * 2) * s)
                let dir = a % 2 == 0 ? -1.0 : 1.0
                c.glowLine(Double(fx), Double(g), Double(fx) + dir * cos(ang) * len, Double(g) - sin(ang) * len, core: C(0x1E3022), glow: C(0, 0),
                           coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            }
        }
        let lx = c.w * 15 / 100
        c.rect(lx, g - 5 * s, 34 * s, 5 * s, C(0x1A221C)); c.rect(lx, g - 5 * s, 34 * s, s, C(0x2E4430))
        c.ellipse(lx, g - 3 * s, 2 * s, 3 * s, C(0x2A3428)); c.ellipse(lx, g - 3 * s, s, 2 * s, C(0x141A14))
        for k in 0..<5 { c.rect(lx + (4 + k * 6) * s, g - 6 * s, 3 * s, s, C(0x3A5A3A)) }
        // The forest floor: dead leaves and dirt, mid-dark, a pale lick of mist over its edge.
        c.ground(g, C(0x34402F), edge: C(0x4C5A44), speck: C(0x2A3426), seed: 91)
        for i in 0..<(c.w / (6 * s)) {
            let px = Int(noise(i * 2 + 2300) * Double(c.w)), py = g + 2 * s + Int(noise(i * 2 + 2301) * Double(max(1, c.h - g - 3 * s)))
            c.rect(px, py, 2 * s, max(1, s), C(0x4A3E2A))
        }
        c.rect(0, g - 3 * s, c.w, 3 * s, C(0xA8C8AC, 0.08)); c.rect(0, g - 6 * s, c.w, 3 * s, C(0xA8C8AC, 0.05))
    }

    /// A layer of mist: long see-through banks drifting between the trunks, thicker towards the ground.
    private static func huntPurgatoryMist(_ c: PixelCanvas, _ g: Int, _ layer: Int, _ a: Double) {
        let s = unit(g), tall = isTall(c)
        let banks = c.w / (40 * s) * (tall ? 4 : 1) + 3
        let span = tall ? g * 70 / 100 : g - 8 * s
        for k in 0..<banks {
            // Lower banks thicker: the height is squared towards the ground.
            let u = noise(layer * 97 + k * 3 + 2400)
            let y = g - 6 * s - Int(u * u * Double(span))
            let x = Int(noise(layer * 97 + k * 3 + 2401) * Double(c.w + 40 * s)) - 20 * s
            let rx = (24 + Int(noise(layer * 97 + k * 3 + 2402) * 40)) * s, ry = (2 + Int(noise(layer * 97 + k + 2403) * 3)) * s
            c.ellipse(x, y, rx, ry, C(0xB0D0B4, a * (1.2 - u * 0.6)))
            c.ellipse(x - rx / 4, y - ry / 2, rx / 2, max(s, ry / 2), C(0xB0D0B4, a * 0.6))
        }
    }

    /// On the screen saver: the canopy far overhead, a black tangle of branches and hanging moss with a pale green
    /// light seeping through its gaps, faint shafts of it slanting down into the mist.
    private static func huntPurgatoryCanopy(_ c: PixelCanvas, _ g: Int, _ trunks: [(x: Int, w: Int)], near: Bool) {
        let s = unit(g), fork = g * (near ? 30 : 24) / 100
        let bark = near ? C(0x0E1610) : C(0x1C2822), leaf = near ? C(0x0A120C) : C(0x16221A)
        if !near {
            // Faint shafts of the pale light slanting down through the gaps.
            for k in 0..<6 {
                let x0 = c.w * (6 + k * 17) / 100 + Int(noise(k + 2500) * Double(10 * s)), w = (8 + k % 3 * 4) * s
                for y in stride(from: fork / 2, to: g - 20 * s, by: 1) { c.rect(x0 + y / 4, y, w, 1, C(0xC8E8C0, 0.03)) }
            }
        }
        // Each trunk forks into limbs, the limbs into branches and twigs, a tangle against the light.
        func limb(_ x: Double, _ y: Double, _ ang: Double, _ len: Double, _ r: Double, _ depth: Int, _ seed: Int) {
            let ex = x + sin(ang) * len, ey = y - cos(ang) * len
            c.glowLine(x, y, ex, ey, core: bark, glow: C(0, 0), coreR: r, glowR: r + 0.1)
            guard depth > 0 else {
                // A ragged clump of dark leaves and a strand of moss hanging from the twig's end.
                for k in 0..<5 {
                    let lx = Int(ex) + Int((noise(seed * 7 + k + 2560) - 0.5) * Double(10 * s))
                    let ly = Int(ey) + Int((noise(seed * 7 + k + 2570) - 0.5) * Double(6 * s))
                    c.rect(lx, ly, (2 + k % 3) * s, 2 * s, leaf)
                }
                if noise(seed + 2580) > 0.5 { c.rect(Int(ex), Int(ey), max(1, s), (6 + Int(noise(seed + 2590) * 14)) * s, C(0x2A3A2C)) }
                return
            }
            for side in [-1.0, 1.0] {
                let spread = 0.35 + noise(seed * 3 + Int(side + 1) + 2600) * 0.4
                limb(ex, ey, ang + side * spread, len * 0.68, max(Double(s) * 0.5, r * 0.62), depth - 1, seed * 2 + Int(side + 1))
            }
        }
        for (k, t) in trunks.enumerated() {
            let sway = near ? Int(sin(Double(fork) / Double(s) * 0.045 + Double(k) * 1.7) * 2.5) * s : 0
            let cx = Double(t.x + sway + t.w / 2), len = Double(g) * (near ? 0.12 : 0.09)
            limb(cx, Double(fork), (noise(k + 2610) - 0.5) * 0.3, len, Double(t.w) * 0.32, near ? 3 : 2, k + (near ? 50 : 0))
        }
    }

    /// Purgatory's life: eyes in the dark beside the trunks, red for the monsters and gold for the vampires, opening,
    /// blinking and closing again, and a slow drift of mist low across the wood.
    static func huntPurgatoryLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntPurgatoryFrame(c, g)
        for (k, e) in f.eyes.enumerated() {
            let period = 7.0 + noise(k + 2600) * 6
            let u = (t / period + noise(k + 2610)).truncatingRemainder(dividingBy: 1)
            guard u > 0.15 && u < 0.7 else { continue }
            let blink = (u * period).truncatingRemainder(dividingBy: 2.7) < 0.12
            let col = e.gold ? C(0xF0B828) : C(0xE0281E)
            if blink { c.rect(e.x, e.y + s / 2, 4 * s, max(1, s / 2), col.alpha(0.5)); continue }
            c.ellipse(e.x + 2 * s, e.y, 5 * s, 2 * s, col.alpha(0.12))
            c.rect(e.x, e.y, s, s, col); c.rect(e.x + 3 * s, e.y, s, s, col)
        }
        let x = Int((t * 6).truncatingRemainder(dividingBy: Double(c.w + 120 * s))) - 60 * s
        for (dy, a) in [(0, 0.06), (-2 * s, 0.04), (2 * s, 0.05)] { c.rect(x, g - 9 * s + dy, 70 * s, 2 * s, C(0xC0DCC0, a)) }
    }
}

// MARK: - The Empty

extension Scenes {
    /// Where things stand in the Empty, shared by the still picture and the moving layer: the far edge of the goo
    /// plain, and the goo strands hanging from the dark above (each one's x and the row of its tip), which drip.
    static func huntEmptyFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, strands: [(x: Int, tip: Int)]) {
        let s = unit(g), tall = isTall(c)
        var strands: [(x: Int, tip: Int)] = []
        var x = 3 * s, i = 0
        while x < c.w {
            let len = (tall ? 20 + Int(noise(i + 3000) * 60) : 6 + Int(noise(i + 3000) * 18)) * s
            strands.append((x, len)); x += (6 + Int(noise(i + 3001) * 12)) * s; i += 1
        }
        return (tall ? g * 56 / 100 : g - 14 * s, strands)
    }

    /// The Empty: a black nothing, the cosmic dark where angels and demons go when they die and sleep for ever. A ceiling
    /// of black goo sags down in drips and strands, a glossy plain of the same goo stretches away to a horizon you can
    /// barely see, pools and mounds of it glinting with a faint violet sheen, and a violet haze rising off it so the
    /// crew stays visible. On the screen saver the plain stretches far back, and on it, small and still, lie the
    /// sleepers: dim curled shapes, here and there the shadow of a folded wing.
    static func huntEmpty(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntEmptyFrame(c, g), tall = isTall(c)
        // The void: black, a faint violet glow welling up from the plain.
        c.gradient(0, f.horizon, C(0x120E1E), C(0x221A36), bands: tall ? 9 : 6)
        c.gradient(0, f.horizon / 2, C(0x18122A), C(0x120E1E, 0), bands: 4)   // the glow caught under the ceiling
        for r in stride(from: 40 * s, to: 6 * s, by: -6 * s) { c.ellipse(c.w * 52 / 100, f.horizon, r * 5, r, C(0x5A3A8A, 0.04)) }
        // Motes of faint violet light hanging in the dark.
        for i in 0..<(c.w * f.horizon / (260 * s * s)) {
            let x = Int(noise(i * 3 + 3100) * Double(c.w)), y = Int(noise(i * 3 + 3101) * Double(f.horizon))
            c.px(x, y, C(0x8A70C8, noise(i * 3 + 3102) > 0.8 ? 0.5 : 0.22))
        }
        // The plain: black goo, glossy, a thin violet line where it meets the dark, streaks of sheen across it.
        c.gradient(f.horizon, g, C(0x0C0A12), C(0x1E1A28), bands: tall ? 8 : 4)
        c.rect(0, f.horizon, c.w, max(1, s / 2), C(0x4A3A6A))
        for i in 0..<(tall ? 40 : 12) {
            let u = noise(i * 3 + 3200), y = f.horizon + 2 * s + Int(u * u * Double(g - f.horizon - 3 * s))
            let len = Int((10 + noise(i * 3 + 3201) * 40) * (0.4 + u)) * s
            c.rect(Int(noise(i * 3 + 3202) * Double(c.w)), y, len, max(1, s / 2), C(0x3A2E54, 0.7))
        }
        if tall { huntEmptySleepers(c, g) }
        // Mounds of goo welling up at the sides, glossy and dripping, lit violet on the upper left.
        let mounds: [(Int, Int, Int)] = [(3, 16, 14), (12, 10, 9), (22, 6, 5), (80, 7, 6), (89, 12, 10), (97, 17, 15)]
        for (k, (xp, rw, rh)) in mounds.enumerated() {
            let mx = c.w * xp / 100, base = g - s
            c.ellipse(mx, base, rw * s, rh * s, C(0x08060C))
            c.ellipse(mx - rw * s / 3, base - rh * s / 2, rw * s / 3, rh * s / 4, C(0x2A2040))
            c.rect(mx - rw * s / 2, base - rh * s * 3 / 4, 2 * s, max(1, s), C(0x7A64B0))
            for d in 0..<2 {   // runs of goo sliding down its side
                let dx = mx + (d == 0 ? rw / 3 : -rw / 5) * s
                c.rect(dx, base - rh * s / 2 + d * 2 * s, 2 * s, rh * s / 2, C(0x08060C)); c.circle(dx + s, base - s, s, C(0x08060C))
            }
            if k % 2 == 0 { c.circle(mx + rw * s / 4, base - rh * s * 2 / 3, 2 * s, C(0x14101C)); c.px(mx + rw * s / 4 - s, base - rh * s * 2 / 3 - s, C(0x8A74C0)) }
        }
        // Pools of goo on the plain near the front, blacker than the plain, a violet rim and a glossy highlight.
        for (xp, rw) in [(30, 16), (47, 9), (62, 13), (75, 8)] {
            let px = c.w * xp / 100, py = g - 4 * s
            c.ellipse(px, py, rw * s + 2 * s, 3 * s, C(0x2E2444)); c.ellipse(px, py, rw * s, 2 * s, C(0x040306))
            c.rect(px - rw * s / 2, py - s, rw * s / 2, max(1, s / 2), C(0x5A4A8A)); c.rect(px + rw * s / 3, py + s, 2 * s, max(1, s / 2), C(0x3A2E54))
        }
        huntEmptyCeiling(c, g)
        huntEmptyColumns(c, g)
        // The floor: the goo near us, mid-dark violet-grey and plain so the crew reads on it.
        c.ground(g, C(0x241E2E), edge: C(0x3E3450), speck: C(0x1C1824), seed: 103)
        for x in stride(from: 6 * s, to: c.w, by: 37 * s) { c.rect(x, g + 2 * s, 9 * s, max(1, s / 2), C(0x342C44)) }
    }

    /// The ceiling of goo: a black mass sagging along the top, hanging in strands and fat drips, each with a violet
    /// glint along its left edge and a bead on its tip.
    private static func huntEmptyCeiling(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntEmptyFrame(c, g), tall = isTall(c)
        let goo = C(0x07050B), sheen = C(0x3A2C56), glint = C(0x7A66B4)
        let mass = tall ? 14 * s : 3 * s
        c.rect(0, 0, c.w, mass, goo)
        for x in stride(from: 0, to: c.w, by: max(1, s)) {
            let sag = Int((sin(Double(x) * 0.09 / Double(s)) * 0.5 + 0.5) * Double(3 * s) + noise(x / max(1, s) + 3300) * Double(s))
            c.rect(x, mass, max(1, s), sag, goo)
        }
        for x in stride(from: 0, to: c.w, by: 3 * s) where noise(x / max(1, s) + 3310) > 0.6 {
            c.rect(x, mass + s, 2 * s, max(1, s / 2), sheen.alpha(0.6))
        }
        // Each strand thick where it pulls out of the mass and thinning as it stretches, ending in a fat bead.
        for (k, st) in f.strands.enumerated() {
            let w0 = (3 + Int(noise(k + 3320) * 4)) * s, len = max(1, st.tip - mass)
            for y in stride(from: mass, to: st.tip, by: max(1, s)) {
                let u = Double(y - mass) / Double(len)
                let w = max(s, Int(Double(w0) * (1 - u).squareRoot()) / s * s)
                let x0 = st.x + (w0 - w) / 2
                c.rect(x0, y, w, max(1, s), goo)
                c.rect(x0, y, max(1, s / 2), max(1, s), u < 0.4 ? sheen : sheen.alpha(0.6))
            }
            let br = max(s, w0 / 3)
            c.circle(st.x + w0 / 2, st.tip, br, goo)
            c.px(st.x + w0 / 2 - br / 2, st.tip - br / 2, glint)
        }
    }

    /// Columns of goo at the sides, where the ceiling has sagged all the way down to the plain and joined it: thick at
    /// the top and the foot, pinched in the middle, glossy, lit violet along the left and dripping.
    private static func huntEmptyColumns(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        let goo = C(0x07050B), sheen = C(0x3A2C56), glint = C(0x7A66B4)
        for (k, (xp, w0)) in [(5, 16), (91, 20)].enumerated() {
            let cx = c.w * xp / 100
            for y in stride(from: 0, to: g, by: max(1, s)) {
                let u = Double(y) / Double(g)
                let pinch = 1 - 0.55 * sin(u * .pi), wobble = sin(Double(y) / Double(s) * 0.12 + Double(k) * 2) * 1.5
                let w = Int(Double(w0 * s) * pinch + (u > 0.8 ? (u - 0.8) * Double(60 * s) : 0))
                let x0 = cx - w / 2 + Int(wobble) * s
                c.rect(x0, y, w, max(1, s), goo)
                c.rect(x0 + s, y, max(1, s), max(1, s), sheen)
                if (y / max(1, s) + k * 5) % 23 < 2 { c.px(x0 + 2 * s, y, glint) }
            }
        }
    }

    /// On the screen saver: the sleepers, lying still on the goo plain all the way to the horizon, small and dim far
    /// off, a little larger nearer; each a curled dark shape with a violet rim along its back, some with the shadow of
    /// a folded wing.
    private static func huntEmptySleepers(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntEmptyFrame(c, g)
        let near = g - 30 * s
        guard near > f.horizon + 6 * s else { return }
        let n = c.w * (near - f.horizon) / (1400 * s * s) + 8
        let shapes = (0..<n).map { i -> (x: Int, d: Double) in (Int(noise(i * 2 + 3400) * Double(c.w)), noise(i * 2 + 3401)) }.sorted { $0.d < $1.d }
        for (i, sh) in shapes.enumerated() {
            let d = sh.d * sh.d, y = f.horizon + 4 * s + Int(d * Double(near - f.horizon - 4 * s))
            huntEmptySleeper(c, sh.x, y, 0.5 + d * 1.1, dir: i % 2 == 0 ? 1 : -1, wing: i % 3 == 0, s: s)
        }
        // A few more drifting high in the dark above the plain, asleep in mid-air, a faint violet glow round each.
        for i in 0..<(c.w / (90 * s) + 2) {
            let x = Int(noise(i * 3 + 3450) * Double(c.w)), y = g * (22 + Int(noise(i * 3 + 3451) * 26)) / 100
            for r in stride(from: 18 * s, to: 4 * s, by: -4 * s) { c.ellipse(x, y, r * 3 / 2, r / 2, C(0x5A4A8A, 0.04)) }
            huntEmptySleeper(c, x, y, 0.9 + noise(i * 3 + 3452) * 0.6, dir: i % 2 == 0 ? -1 : 1, wing: i % 2 == 1, s: s)
        }
    }

    /// One sleeper, `k` times its usual size, its head towards `dir`: curled on its side, knees drawn up, a dark shape
    /// with a violet rim along its back and head, and if it was an angel the shadow of a folded wing over it.
    private static func huntEmptySleeper(_ c: PixelCanvas, _ x: Int, _ y: Int, _ k: Double, dir: Int, wing: Bool, s: Int) {
        func u(_ v: Double) -> Int { max(s, Int(v * k * Double(s))) }
        let dark = C(0x0E0A16), rim = C(0x5A4A88)
        if wing { c.ellipse(x - dir * u(2), y - u(5), u(9), u(4), C(0x3A2E5A, 0.4)) }
        c.ellipse(x, y + u(3), u(13), max(1, s / 2), C(0x3A2E54, 0.5))
        // The parts: the body lying along the ground, the knees drawn up, the head pillowed on an arm with a little
        // gap at the neck. Each is drawn in the rim's violet and then again in black a pixel lower, so the light runs
        // along the top of every curve.
        let parts: [(dx: Double, dy: Double, rx: Double, ry: Double)] = [(0, 0, 8, 3), (-6, 1, 4, 2.4), (7, 1.5, 3, 1.2), (11, -1, 2.8, 2.6)]
        func o(_ v: Double) -> Int { Int((v * k * Double(s)).rounded()) }
        for p in parts { c.ellipse(x + dir * o(p.dx), y + o(p.dy) - s, u(p.rx), u(p.ry), rim) }
        for p in parts { c.ellipse(x + dir * o(p.dx), y + o(p.dy), u(p.rx), u(p.ry), dark) }
    }

    /// The Empty's life: drops of goo swelling on the strands' tips, falling, and landing on the plain in a little violet
    /// ring, and the haze over the plain breathing faintly.
    static func huntEmptyLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntEmptyFrame(c, g)
        let a = (sin(t * 0.5) * 0.5 + 0.5) * 0.05
        c.ellipse(c.w * 52 / 100, f.horizon, 120 * s, 10 * s, C(0x6A4A9A, a))
        for (k, st) in f.strands.enumerated() where k % 2 == 0 {
            let period = 3.5 + noise(k + 3500) * 3.5
            let u = (t / period + noise(k + 3510)).truncatingRemainder(dividingBy: 1)
            let land = f.horizon + Int(noise(k + 3520) * Double(max(1, (g - f.horizon) / 2)))
            let x = st.x + (3 + Int(noise(k + 3320) * 4)) * s / 2
            if u < 0.55 {
                c.circle(x, st.tip + s, max(1, Int(u / 0.55 * Double(s) * 1.5)), C(0x07050B))
            } else if u < 0.8 {
                let v = (u - 0.55) / 0.25, y = st.tip + s + Int(v * v * Double(land - st.tip - s))
                c.rect(x - s / 2, y - s, max(1, s), 2 * s, C(0x07050B)); c.px(x - s / 2, y - s, C(0x6A58A0))
            } else {
                let v = (u - 0.8) / 0.2
                c.ellipse(x, land, Int(2 + v * 6) * s, max(1, s / 2), C(0x8A74C8, 0.5 * (1 - v)))
            }
        }
    }
}

// MARK: - The open road

extension Scenes {
    /// Where things stand on the road, shared by the still picture and the moving layer: the horizon, the road (its far
    /// edge, the centre line and its near edge), the Impala (the left end of its back bumper and the ground under it)
    /// and the trunk light.
    static func huntRoadFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, road: (far: Int, centre: Int, near: Int),
                                                             car: (x: Int, y: Int), bulb: (x: Int, y: Int)) {
        let s = unit(g)
        let car = (x: c.w - 62 * s, y: g + s)
        return (g - 24 * s, (far: g - 11 * s, centre: g - 6 * s, near: g - s), car, (x: car.x + 20 * s, y: car.y - 35 * s))
    }

    /// The open road at night, somewhere in Kansas: a two-lane blacktop running across the flat dark land, its white
    /// edge lines and the yellow centre dashes, a barbed-wire fence along the stubble fields, telephone poles striding
    /// along with their wires sagging, a grain elevator and a farm's lit window far off, a curve sign, and on the
    /// gravel shoulder on the right Baby, the black '67 Impala, seen from behind with her trunk up and the arsenal lit.
    /// On the screen saver the sky opens up huge and full of stars, the Milky Way arching over it.
    static func huntRoad(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadFrame(c, g), tall = isTall(c)
        // The sky: deep navy up high, a dusty blue at the horizon, the glow of a far town low on the left.
        c.gradient(0, f.horizon, C(0x060A16), C(0x2A3452), bands: tall ? 10 : 6)
        if tall { huntRoadSky(c, g) } else { c.stars(0, f.horizon - 6 * s, density: 34, seed: 61) }
        for r in stride(from: 30 * s, to: 4 * s, by: -4 * s) { c.ellipse(c.w * 12 / 100, f.horizon, r * 2, r / 2, C(0xC88A50, 0.05)) }
        // A thin crescent moon low on the left.
        let mx = c.w * 22 / 100, my = tall ? g * 36 / 100 : 8 * s, mr = tall ? 8 * s : 4 * s
        for dy in -mr...mr {
            for dx in -mr...mr where dx * dx + dy * dy <= mr * mr {
                let ox = dx - mr / 2 - s, oy = dy + s
                if ox * ox + oy * oy > mr * mr { c.px(mx + dx, my + dy, C(0xE8E2C8)) }
            }
        }
        // The far land along the horizon: windbreak trees, a grain elevator, a farmhouse with one lit window.
        c.rect(0, f.horizon - s, c.w, s, C(0x141A24))
        for i in 0..<(c.w / (5 * s)) where noise(i + 4000) > 0.55 {
            let x = i * 5 * s, r = (2 + Int(noise(i + 4001) * 3)) * s
            c.circle(x, f.horizon - r / 2, r, C(0x121822))
        }
        let ex = c.w * 33 / 100, eb = f.horizon
        for k in 0..<4 { c.rect(ex + k * 5 * s, eb - 18 * s, 5 * s, 18 * s, k % 2 == 0 ? C(0x2A3040) : C(0x252A38)); c.ellipse(ex + k * 5 * s + 2 * s, eb - 18 * s, 2 * s, s, C(0x2E3446)) }
        c.rect(ex + 6 * s, eb - 26 * s, 7 * s, 8 * s, C(0x252A38)); c.rect(ex + 7 * s, eb - 29 * s, 5 * s, 3 * s, C(0x2A3040))
        c.rect(ex, eb - 18 * s, max(1, s / 2), 18 * s, C(0x3A4258)); c.rect(ex + 9 * s, eb - 24 * s, max(1, s), max(1, s), C(0xC84030))
        let fx = c.w * 62 / 100
        c.circle(fx - 6 * s, eb - 4 * s, 5 * s, C(0x101620)); c.circle(fx + 14 * s, eb - 5 * s, 6 * s, C(0x101620))
        c.rect(fx, eb - 7 * s, 10 * s, 7 * s, C(0x1A202C)); for k in 0..<4 { c.rect(fx - s + k, eb - 7 * s - k * s, 12 * s - 2 * k, s, C(0x141820)) }
        c.rect(fx + 2 * s, eb - 5 * s, 2 * s, 2 * s, C(0xE8B060)); c.rect(fx + 12 * s, eb - 4 * s, 4 * s, 4 * s, C(0x1A202C))
        // The stubble fields, rows running away, a little lighter towards us.
        c.gradient(f.horizon, f.road.far - 2 * s, C(0x221E1C), C(0x302A22), bands: 4)
        for (k, y) in stride(from: f.horizon + s, to: f.road.far - 3 * s, by: 2 * s).enumerated() {
            c.rect(0, y, c.w, max(1, s / 2), k % 2 == 0 ? C(0x3A3226) : C(0x1C1A18))
        }
        // The fence: wooden posts, two strands of wire.
        let fy = f.road.far - 2 * s
        for x in stride(from: 2 * s, to: c.w, by: 11 * s) { c.rect(x, fy - 5 * s, max(1, s), 5 * s, C(0x2E2620)) }
        c.rect(0, fy - 4 * s, c.w, max(1, s / 2), C(0x4A4A4E, 0.8)); c.rect(0, fy - 2 * s, c.w, max(1, s / 2), C(0x4A4A4E, 0.8))
        huntRoadPoles(c, g)
        // The verge: dry grass at the road's far edge.
        c.rect(0, fy, c.w, f.road.far - fy, C(0x2A2A22))
        for i in 0..<(c.w / (2 * s)) { c.rect(i * 2 * s, fy - Int(noise(i + 4100) * 2) * s, max(1, s / 2), 2 * s, C(0x3A3A2C)) }
        // A yellow curve sign on its post, and a mile marker.
        let sx = c.w * 9 / 100
        c.rect(sx, fy - 12 * s, max(1, s), 12 * s, C(0x6A6E76))
        for k in 0..<5 { c.rect(sx - k * s, fy - 21 * s + k * s, 2 * k * s + s, s, C(0xC8A020)); c.rect(sx - k * s, fy - 13 * s - k * s, 2 * k * s + s, s, C(0xC8A020)) }
        c.rect(sx - 4 * s, fy - 17 * s, 9 * s, s, C(0xC8A020)); c.rect(sx - 5 * s, fy - 17 * s, s, s, C(0x8A6A10))
        c.glowLine(Double(sx - 2 * s), Double(fy - 14 * s), Double(sx), Double(fy - 18 * s), core: C(0x141414), glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        c.glowLine(Double(sx), Double(fy - 18 * s), Double(sx + 2 * s), Double(fy - 18 * s), core: C(0x141414), glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        c.rect(sx + 2 * s, fy - 19 * s, max(1, s), 3 * s, C(0x141414))
        let mk = c.w * 52 / 100
        c.rect(mk, fy - 6 * s, 2 * s, 6 * s, C(0xC8CCD0)); c.rect(mk, fy - 6 * s, 2 * s, 2 * s, C(0x2E6A3E))
        // The road: worn blacktop, tar patches, a white line each side and the yellow dashes down the middle.
        c.rect(0, f.road.far, c.w, g - f.road.far, C(0x26262C))
        for i in 0..<(c.w / (20 * s)) {
            let px = Int(noise(i + 4200) * Double(c.w)), py = f.road.far + s + Int(noise(i + 4201) * Double(8 * s))
            c.rect(px, py, (4 + Int(noise(i + 4202) * 8)) * s, max(1, s / 2), C(0x1C1C22))
        }
        c.rect(0, f.road.far, c.w, max(1, s / 2), C(0x8A8A86))
        for x in stride(from: 0, to: c.w, by: 14 * s) { c.rect(x, f.road.centre, 8 * s, max(1, s / 2), C(0xA88A30)) }
        c.rect(0, f.road.near, c.w, max(1, s / 2), C(0x7A7A76))
        // The shoulder: gravel, mid-dark, plain enough for the crew to stand on, the trunk light's warmth on it.
        c.ground(g, C(0x38332C), edge: C(0x4C463C), speck: C(0x2C2822), seed: 113)
        for r in stride(from: 26 * s, to: 4 * s, by: -4 * s) { c.ellipse(f.car.x + 22 * s, g + 2 * s, r * 2, r / 3, C(0xF0B860, 0.035)) }
        huntRoadImpala(c, g)
    }

    /// The telephone poles along the far side of the road: tall and dark, crossarms with glass insulators, the wires
    /// sagging from one to the next and off past the edges.
    private static func huntRoadPoles(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadFrame(c, g), tall = isTall(c)
        let foot = f.road.far - 2 * s, h = tall ? 60 * s : 36 * s, gap = 96 * s
        let poles = Array(stride(from: c.w * 4 / 100 - gap, through: c.w + gap, by: gap))
        for px in poles {
            c.rect(px - s, foot - h, 2 * s, h, C(0x241E1A)); c.rect(px - s, foot - h, max(1, s / 2), h, C(0x3A322A))
            c.rect(px - 8 * s, foot - h + 3 * s, 17 * s, 2 * s, C(0x241E1A)); c.rect(px - 8 * s, foot - h + 3 * s, 17 * s, max(1, s / 2), C(0x3A322A))
            for k in [-7, -3, 3, 7] { c.rect(px + k * s, foot - h + s, max(1, s), 2 * s, C(0x5A7A8A)) }
        }
        for (k, sag) in [(-7, 4), (7, 6)] {
            for i in 0..<(poles.count - 1) {
                let a = poles[i] + k * s, b = poles[i + 1] + k * s
                for xx in max(0, a)..<min(c.w, b) {
                    let u = Double(xx - a) / Double(max(1, b - a))
                    c.px(xx, foot - h + s + Int(sin(u * .pi) * Double(sag * s)), C(0x0E0E14, 0.9))
                }
            }
        }
    }

    /// On the screen saver: the big Kansas sky, thick with stars, the Milky Way a pale river arching from the lower
    /// left to the upper right with a dark lane of dust down it, and a few bright stars.
    private static func huntRoadSky(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadFrame(c, g)
        c.stars(0, f.horizon - 4 * s, density: 60, seed: 61)
        let x0 = Double(-c.w / 10), y0 = Double(f.horizon), x1 = Double(c.w + c.w / 10), y1 = Double(-f.horizon / 4)
        let steps = 40
        for k in 0..<steps {
            let u = Double(k) / Double(steps - 1)
            let x = x0 + (x1 - x0) * u, y = y0 + (y1 - y0) * u - sin(u * .pi) * Double(f.horizon) * 0.25
            let w = Int((0.5 + sin(u * .pi)) * Double(26 * s))
            c.ellipse(Int(x), Int(y), w, w / 2, C(0xA8B4D8, 0.035))
            c.ellipse(Int(x), Int(y), w / 2, w / 4, C(0xC8D0F0, 0.04))
            if k % 3 == 1 { c.ellipse(Int(x) + w / 6, Int(y), w / 2, max(1, w / 10), C(0x05070F, 0.35)) }
        }
        // Denser stars along the band.
        for i in 0..<(c.w * 3) {
            let u = noise(i * 3 + 4300), x = x0 + (x1 - x0) * u, y = y0 + (y1 - y0) * u - sin(u * .pi) * Double(f.horizon) * 0.25
            let off = (noise(i * 3 + 4301) - 0.5) * Double(36 * s)
            c.px(Int(x + off * 0.4), Int(y + off), C(0xFFFFFF, noise(i * 3 + 4302) > 0.85 ? 0.85 : 0.35))
        }
        for k in 0..<6 {   // a few bright ones, with a little cross of light
            let x = Int(noise(k * 2 + 4400) * Double(c.w)), y = Int(noise(k * 2 + 4401) * Double(f.horizon - 30 * s))
            c.rect(x, y, s, s, C(0xFFFFFF)); c.rect(x - s, y, 3 * s, max(1, s / 2), C(0xFFFFFF, 0.4)); c.rect(x, y - s, max(1, s / 2), 3 * s, C(0xFFFFFF, 0.4))
        }
    }

    /// Baby, the black 1967 Chevrolet Impala four-door hardtop, seen from behind and a little to the left, parked on
    /// the shoulder: the wide chrome bumper, three tail lights a side, the Kansas plate, her flank running away to the
    /// right, and the trunk lid up. Inside, lit warm by the trunk light: the false floor propped open on a shotgun, and
    /// under it the arsenal, shotguns, a rifle, the machete, knives, stakes, salt and holy water, the Colt.
    private static func huntRoadImpala(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadFrame(c, g)
        let x = f.car.x, y = f.car.y
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
        let body = C(0x15171B), mid = C(0x22262E), top = C(0x46526A), low = C(0x0C0D10)
        let chrome = C(0xA8B0BC), chromeL = C(0xD8DEE6), chromeD = C(0x6A727E)
        // Her shadow on the gravel.
        c.ellipse(x + 28 * s, y, 32 * s, 3 * s, C(0x0A0A0C, 0.6))
        // The flank, running away to the right and up a little: the side, its chrome spear, the rear wheel, and the
        // roof and side glass above it.
        for u in 44..<60 {
            let lift = (u - 44) / 4
            r(u, -18 - lift, 1, 10, body); r(u, -18 - lift, 1, 1, top); r(u, -13 - lift, 1, 1, chromeD)
            if u > 45 { r(u, -26 - lift, 1, 7, u < 48 ? body : C(0x1E2834)); r(u, -26 - lift, 1, 1, top) }
            if u > 55 { r(u, -8 - lift, 1, 2, low) }
        }
        c.circle(x + 53 * s, y - 7 * s, 4 * s, low); c.circle(x + 53 * s, y - 7 * s, 2 * s, C(0x2E3238))
        r(48, -25, 1, 5, C(0x0A0B0D)); r(52, -27, 3, 1, C(0x5A6A82))
        // The tyres and the dark under the car.
        r(4, -6, 8, 6, low); r(32, -6, 8, 6, low); r(4, -6, 8, 1, C(0x26262C)); r(32, -6, 8, 1, C(0x26262C))
        r(2, -8, 40, 3, C(0x08080A)); r(8, -7, 3, 1, C(0x5A5A60))
        // The rear panel: black, lit faintly along its top by the sky and the trunk light, the tail lights in their
        // chrome bezels, the plate in the middle.
        r(0, -18, 44, 8, body); r(0, -18, 44, 1, mid); r(0, -18, 1, 8, mid)
        for u in [3, 7, 11, 29, 33, 37] {
            r(u - 1, -16, 5, 4, chromeD); r(u, -15, 3, 2, C(0xA01A16)); r(u, -15, 3, 1, C(0xE0402E))
        }
        r(18, -16, 8, 5, C(0xC8C0A0)); r(18, -16, 8, 1, C(0x2E4A8A)); r(19, -14, 6, 1, C(0x3A3226)); r(19, -12, 6, 1, C(0x8A8470))
        // The bumper, wide and chrome, its guards, a bright line along the top.
        r(-1, -11, 46, 3, chrome); r(-1, -11, 46, 1, chromeL); r(-1, -9, 46, 1, chromeD)
        r(12, -12, 3, 5, chrome); r(29, -12, 3, 5, chrome); r(12, -12, 1, 5, chromeL); r(29, -12, 1, 5, chromeL)
        // The trunk opening: the lid's lip, the dark lining, and the false floor's tray lit warm.
        r(1, -27, 42, 9, C(0x5A4430)); r(1, -27, 42, 2, C(0x7A5E3E)); r(1, -19, 42, 1, C(0x2A1E16))
        r(1, -27, 1, 9, C(0x3A2A1E)); r(42, -27, 1, 9, C(0x2A1E16))
        // The arsenal in the tray, dark steel and wood on the lit tan lining: a shotgun and a rifle laid side by side
        // along the front, the machete, a knife, a stake, the Colt, two salt canisters and a flask of holy water.
        r(3, -21, 15, 1, C(0x1E1E24)); r(3, -21, 15, 1, C(0x1E1E24)); r(4, -22, 12, 1, C(0x6A6E78)); r(17, -22, 5, 2, C(0x8A4E26))
        r(17, -22, 5, 1, C(0xA86A38))                                                              // the shotgun
        r(23, -21, 13, 1, C(0x1E1E24)); r(24, -22, 10, 1, C(0x5A5E68)); r(35, -22, 5, 2, C(0x6A3A1E))  // the rifle
        r(4, -25, 10, 1, C(0xD8DCE4)); r(4, -24, 9, 1, C(0x8A8E98)); r(14, -25, 3, 2, C(0x141214))  // the machete
        r(18, -25, 4, 1, C(0xC8CCD4)); r(22, -25, 2, 1, C(0x141214))                               // a knife
        r(25, -26, 6, 1, C(0xC8A060)); r(25, -25, 6, 1, C(0x8A6A40))                               // a stake
        r(25, -24, 3, 1, C(0x2A2C32)); r(25, -23, 1, 1, C(0x3A2418))                               // the Colt
        for u in [32, 35] { r(u, -26, 2, 4, C(0x2E5A9A)); r(u, -26, 2, 1, C(0xE8E8E0)); r(u, -24, 2, 1, C(0xE8E8E0)) }  // salt
        r(38, -25, 2, 3, C(0xA8C8E0)); r(38, -25, 1, 3, C(0xD8ECF8)); r(38, -26, 2, 1, C(0x3A2A1E))  // holy water
        // The false floor propped open behind the arsenal on a shotgun, its plywood underside lit, a crowbar and a
        // crossbow strapped to it.
        r(2, -33, 40, 6, C(0x6A5034)); r(2, -33, 40, 1, C(0x8A6A44)); r(2, -28, 40, 1, C(0x3A2A1E))
        r(5, -31, 13, 1, C(0x2A2C32)); r(5, -32, 1, 2, C(0x2A2C32)); r(17, -30, 1, 2, C(0x2A2C32))     // the crowbar
        r(23, -31, 13, 1, C(0x4A2E1A)); r(29, -33, 1, 5, C(0x1E1E24)); r(26, -32, 7, 1, C(0x1E1E24))  // the crossbow
        for b in [11, 31] { r(b, -33, 1, 6, C(0x2A1C12)) }
        c.glowLine(Double(x + 41 * s), Double(y - 21 * s), Double(x + 40 * s), Double(y - 28 * s), core: C(0x1E1E24), glow: C(0, 0),
                   coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        // The trunk lid, swung up high: its underside dark with the inner ribs, lit along its lower edge, the outer
        // skin's edge catching the sky, the trunk light in its middle, the hinges at the sides.
        r(2, -35, 40, 2, C(0x1E2834)); r(2, -35, 40, 1, C(0x2E3A4C))   // the back window, glimpsed under the lid
        r(0, -41, 44, 6, C(0x1C1E22)); r(0, -42, 44, 1, top); r(-1, -41, 1, 6, body); r(44, -41, 1, 6, body)
        r(3, -40, 38, 1, C(0x2C2E34)); r(3, -38, 15, 1, C(0x2C2E34)); r(26, -38, 15, 1, C(0x2C2E34)); r(0, -36, 44, 1, C(0x8A7250))
        r(3, -35, 1, 8, C(0x3A3C44)); r(40, -35, 1, 8, C(0x3A3C44))
        // The rear fenders' tops either side of the opening.
        r(0, -27, 2, 9, body); r(42, -27, 2, 9, body); r(0, -27, 2, 1, top); r(42, -27, 2, 1, top)
    }

    /// The road's life: now and then a car comes along the far lane, its headlights sweeping ahead of it and its tail
    /// lights red behind, and the Impala's trunk light glows, flickering on its loose wire every so often.
    static func huntRoadLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntRoadFrame(c, g)
        let cycle = Int(t / 14), phase = t.truncatingRemainder(dividingBy: 14)
        if phase < 4.5 {
            let u = phase / 4.5, right = cycle % 2 == 0
            let span = Double(f.car.x + 40 * s)
            let cx = right ? Int(u * span) - 30 * s : Int((1 - u) * span) - 10 * s
            let dir = right ? 1 : -1, ly = f.road.centre - 3 * s
            let front = cx + dir * 14 * s, back = cx - dir * 14 * s
            // The beam lying along the road ahead, and the car's dark shape, cut off behind the Impala.
            for k in 0..<4 {
                let len = (40 - k * 8) * s
                let bx0 = dir > 0 ? front : front - len
                let x0 = max(0, bx0), x1 = min(f.car.x - s, bx0 + len)
                if x1 > x0 { c.rect(x0, ly - k / 2 * s, x1 - x0, (1 + k / 2) * s + s, C(0xF4ECC8, 0.05)) }
            }
            // The car itself, a dark shape side on: the long body, the cabin set back with a glint on its glass, two
            // wheels; only the columns left of the Impala, which stands in front of the road.
            for u in -14..<14 {
                let px = cx + u * s * dir
                guard px >= 0 && px < f.car.x - s else { continue }
                let a = abs(u)
                c.rect(px, ly - 3 * s, max(1, s), (a > 12 ? 2 : 3) * s, C(0x0C0E12))
                let cab = dir * u
                if cab > -9 && cab < 5 { c.rect(px, ly - (cab > -7 && cab < 3 ? 6 : 5) * s, max(1, s), 3 * s, C(0x0C0E12)) }
                if cab > -6 && cab < 2 && (cab + 6) % 4 != 3 { c.rect(px, ly - 5 * s, max(1, s), max(1, s), C(0x2A3446)) }
                if a == 8 { c.rect(px - s, ly, 3 * s, s, C(0x060608)) }
            }
            if front > 0 && front < f.car.x - s { c.rect(front - s, ly - 2 * s, 2 * s, s, C(0xFFF4D0)) }
            if back > 0 && back < f.car.x - s { c.rect(back - s, ly - 2 * s, 2 * s, s, C(0xC82418)) }
        }
        // The trunk light.
        let ph = t.truncatingRemainder(dividingBy: 10.5)
        let out = ph > 8.2 && ph < 9.0 && Int(t * 12) % 3 != 1
        let b = f.bulb
        if out {
            c.rect(f.car.x + s, f.car.y - 27 * s, 42 * s, 9 * s, C(0x000000, 0.45))
        } else {
            for r in stride(from: 16 * s, to: 2 * s, by: -3 * s) { c.ellipse(b.x + s, b.y + 8 * s, r * 3 / 2, r / 2, C(0xFFD890, 0.04)) }
            c.rect(b.x, b.y, 3 * s, s, C(0xFFF0C0))
        }
    }
}
