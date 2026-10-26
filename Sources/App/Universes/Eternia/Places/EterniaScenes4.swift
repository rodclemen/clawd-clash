import Foundation

// More places on Eternia: the Sorceress's chamber deep inside Castle Greyskull, the Mystic Mountains and Avion, the
// city of the bird people, drawn the way Castle Greyskull is. Each is drawn once at one pixel to a unit on a canvas of
// its own as wide as the picture, and blown up `q` times: once in the window, three times or more on the screen saver.
// Its 56 bottom rows are the place itself; on the screen saver the rows over them carry the extras (the chamber's
// vault, the floating peaks, the sky over Avion). Three palettes far apart: Greyskull's green-grey stone lit sky blue
// by the pool, violet crags under a green sky, white marble and crimson roofs over a rose dawn above the clouds.

let eterniaScenes4: [Location: Place] = [
    .eterniaChamber: Place(name: "The Sorceress's Chamber", panel: 0x10181A, still: Scenes.eterniaChamber,
                           moving: Scenes.eterniaChamberLife),
    .eterniaMysticMountains: Place(name: "The Mystic Mountains", panel: 0x18122A, still: Scenes.eterniaMysticMountains,
                                   moving: Scenes.eterniaMysticMountainsLife),
    .eterniaAvion: Place(name: "Avion", panel: 0x1C1830, still: Scenes.eterniaAvion, moving: Scenes.eterniaAvionLife),
]

// MARK: - Shared

/// The frame of a place drawn whole at a unit a pixel on a canvas `w` by `h` units, blown up `q` times so that its
/// bottom row sits on the ground row and its middle column on the picture's (the same rule as Greyskull's scale).
/// A room (the chamber) already fills the screen, so it isn't blown up further on the screen saver.
private func eterniaS4Frame(_ c: PixelCanvas, _ g: Int, room: Bool = false) -> (q: Int, x: Int, y: Int, w: Int, h: Int) {
    let q0 = max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120))), q = room ? q0 : eterniaTall(c, q0)
    let w = (c.w + q - 1) / q + 2, h = (g + q - 1) / q
    return (q, c.w / 2 - w / 2 * q, g - h * q, w, h)
}

/// Paints `src` onto `c` blown up `q` times, its top left at (x, y).
private func eterniaS4BlowUp(_ c: PixelCanvas, _ src: PixelCanvas, _ x: Int, _ y: Int, _ q: Int) {
    for yy in 0..<src.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
        for xx in 0..<src.w where src.buf[(yy * src.w + xx) * 4 + 3] > 0 {
            c.rect(x + xx * q, y + yy * q, q, q, unpremultiplied(src, (yy * src.w + xx) * 4))
        }
    }
}

/// A tone out of `tones` (darkest first) for a brightness `v` of 0...1, dithered by position so the tones blend.
private func eterniaS4Dither(_ tones: [Px], _ v: Double, _ x: Int, _ y: Int, grain: Double = 0.26) -> Px {
    let n = (noise(x * 7 + y * 131) - 0.5) * grain
    let i = Int((v + n) * Double(tones.count))
    return tones[max(0, min(tones.count - 1, i))]
}

/// Spots either side of the middle of a canvas `w` wide, at `first`, `first + step` ... out from the middle, each
/// with how many steps out it is.
private func eterniaS4Bays(_ w: Int, first: Int, step: Int) -> [(x: Int, k: Int)] {
    let cx = w / 2
    var out: [(x: Int, k: Int)] = []
    var k = 0
    while first + k * step < cx + step {
        let d = first + k * step
        out.append((cx - d, k)); out.append((cx + d, k))
        k += 1
    }
    return out
}

/// A stroke from one point to another, a pixel at a time.
private func eterniaS4Line(_ u: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px) {
    let n = max(1, Int(max(abs(x1 - x0), abs(y1 - y0)).rounded()))
    for i in 0...n {
        let k = Double(i) / Double(n)
        u.px(Int((x0 + (x1 - x0) * k).rounded()), Int((y0 + (y1 - y0) * k).rounded()), col)
    }
}

/// Whether (x, y) is inside a pointed arch: `hw` either side of `cx`, straight sides down to `bottom`, the arch
/// springing at `spring` from two arcs `r` times the half-width, meeting at a point over the middle.
private func eterniaS4Arch(_ x: Int, _ y: Int, cx: Int, hw: Int, spring: Int, bottom: Int, r: Double = 1.1) -> Bool {
    guard y < bottom else { return false }
    let dx = Double(abs(x - cx)), h = Double(hw)
    if y >= spring { return dx <= h }
    let big = h * r, dy = Double(spring - y), off = big - h
    return (dx + off) * (dx + off) + dy * dy <= big * big
}

/// String art drawn `b` pixels to a character (the bird-men gliding over Avion).
private func eterniaS4Pattern(_ c: PixelCanvas, _ x: Int, _ y: Int, _ b: Int, _ rows: [String], _ pal: [Character: Px]) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * b, y + r * b, b, b, col) } }
    }
}

// MARK: - The Sorceress's chamber

/// Greyskull's stone, the castle's own grey-green, darkest first.
private let chamberStone = [C(0x121814), C(0x1A221C), C(0x232D26), C(0x2E3A30), C(0x3C4A3E), C(0x50604E),
                            C(0x687C64), C(0x8AA084)]

/// Where the hanging braziers hang on the chamber's canvas `w` by `h` (only on the screen saver, in the vault).
private func chamberBraziers(_ w: Int, _ h: Int) -> [(x: Int, y: Int)] {
    let top = h - 56
    guard top >= 30 else { return [] }
    let wallTop = top - 20, cx = w / 2
    var out = [(x: cx, y: max(10, wallTop * 55 / 100))]
    for b in eterniaS4Bays(w, first: 54, step: 80) { out.append((b.x, max(10, wallTop * 75 / 100))) }
    return out
}

extension Scenes {
    /// The Sorceress's chamber, deep inside Castle Greyskull: a dim hall of the castle's grey-green stone in big
    /// blocks, lit from below by the glowing pool. At the back a tall pointed alcove, and carved inside it the great
    /// stone falcon, Zoar, wings spread wide, its eyes lit sky blue; under it her stone throne with a sky-blue gem in
    /// its crest, on a dais of three steps, and sunk into the dais the round pool, glowing. Heavy pillars stand down
    /// the hall; between them niches, each with a stone falcon on a plinth, and narrow lancet windows with Greyskull's
    /// violet dusk in them. On the screen saver the hall rises into a ribbed vault, a clerestory of falcons carved
    /// between pairs of little dusk-lit lancets under a dog-tooth band, iron braziers hanging on long chains.
    static func eterniaChamber(_ c: PixelCanvas, _ g: Int) {
        let f = eterniaS4Frame(c, g, room: true)
        let u = PixelCanvas(f.w, f.h)
        eterniaChamberHall(u)
        eterniaS4BlowUp(c, u, f.x, f.y, f.q)
        // The floor: dark green-grey flags, the pool's light lying faintly on them in front of the dais.
        c.ground(g, C(0x222A25), edge: C(0x3E4C42), speck: C(0x1A201C), seed: 17)
        let fh = max(1, c.h - g)
        c.ellipse(c.w / 2, g + fh / 2, 30 * f.q, max(1, fh / 3), C(0x6AB8F0, 0.08))
    }

    /// The chamber itself, one pixel to a unit, its floor along the bottom row and its middle column in the middle.
    static func eterniaChamberHall(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let tone = chamberStone, glow = C(0x6AB8F0)
        let pool = (x: cx, y: B - 7)
        /// How much the pool lights a spot: full beside it, nothing a long way off.
        func lit(_ x: Int, _ y: Int) -> Double {
            let dx = Double(x - pool.x) / 1.8, dy = Double(y - pool.y)
            return max(0, 1 - (dx * dx + dy * dy).squareRoot() / 62)
        }
        /// A pixel of stone at brightness `v`, tinted sky blue as the pool's light reaches it.
        func stone(_ x: Int, _ y: Int, _ v: Double, grain: Double = 0.16) -> Px {
            let l = lit(x, y)
            let base = eterniaS4Dither(tone, v + l * 0.42, x, y, grain: grain)
            return l > 0.05 ? lerp(base, glow, l * l * 0.3) : base
        }

        // On the screen saver the hall rises higher: a clerestory over the frieze, then the vault, dark and ribbed.
        let wallTop = top >= 30 ? top - 20 : top
        let piers = eterniaS4Bays(u.w, first: 34, step: 40).map(\.x).sorted()
        if wallTop > 0 {
            u.gradient(0, wallTop, C(0x0A0E0C), C(0x1A221C), bands: 5)
            // Ribs fanning up from every pillar towards the crown of the vault.
            for x in piers {
                let tx = Double(cx) + Double(x - cx) * 0.3
                eterniaS4Line(u, Double(x), Double(wallTop), tx, 0, tone[3])
                eterniaS4Line(u, Double(x) + 1, Double(wallTop), tx + 1, 0, tone[1])
            }
            // Pointed arches from pillar to pillar along the top of the wall.
            for (a, b) in zip(piers, piers.dropFirst()) {
                let m = (a + b) / 2, hw = (b - a) / 2
                for x in a...b {
                    var y = wallTop
                    while y > 0 && eterniaS4Arch(x, y - 1, cx: m, hw: hw, spring: wallTop, bottom: wallTop + 1, r: 1.3) { y -= 1 }
                    u.rect(x, y - 1, 1, 2, tone[4]); u.px(x, y + 1, tone[0])
                }
            }
            // The boss at the crown: a ring of stone round the falcon's eye, glowing faintly.
            u.circle(cx, 3, 4, tone[3]); u.circle(cx, 3, 3, tone[1]); u.circle(cx, 3, 1, C(0x6AB8F0, 0.7))
            // The braziers: iron bowls of glowing coals hung from the vault on long chains, warm light round them.
            for b in chamberBraziers(u.w, u.h) {
                for (r, a) in [(16, 0.03), (12, 0.035), (8, 0.045)] { u.circle(b.x, b.y - 3, r, C(0xFFA050, a)) }
                for y in 0..<max(0, b.y - 8) { u.px(b.x, y, y % 2 == 0 ? C(0x3A3632) : C(0x5A544C)) }
                u.rect(b.x - 1, b.y - 9, 3, 2, C(0x6A6058))
                for dx in [-5, 0, 5] { eterniaS4Line(u, Double(b.x), Double(b.y - 8), Double(b.x + dx), Double(b.y - 1), C(0x4A4440)) }
                u.rect(b.x - 6, b.y, 13, 1, C(0x7A6A58)); u.rect(b.x - 5, b.y + 1, 11, 1, C(0x3E342C))
                u.rect(b.x - 4, b.y + 2, 9, 1, C(0x2E2622)); u.rect(b.x - 2, b.y + 3, 5, 1, C(0x221C18))
                u.rect(b.x - 6, b.y, 2, 1, C(0xA08C70)); u.px(b.x, b.y + 4, C(0x2E2622))
                u.rect(b.x - 5, b.y - 1, 11, 1, C(0xC84A1A))
                for dx in [-4, -1, 2, 4] { u.px(b.x + dx, b.y - 1, C(0xF0A040)) }
            }
        }

        // The wall: big blocks of grey-green stone in courses five rows high, each block its own shade.
        for y in max(0, wallTop)..<B {
            for x in 0..<u.w {
                let course = y / 5, off = course % 2 * 5
                if y % 5 == 4 || (x + off) % 10 == 9 { u.px(x, y, lerp(tone[1], glow, lit(x, y) * 0.2)); continue }
                let v = 0.1 + noise((x + off) / 10 * 17 + course * 59) * 0.18
                u.px(x, y, stone(x, y, v, grain: 0.12))
            }
        }
        if wallTop < top {
            // The clerestory: between the falcons, pairs of little lancet windows with the dusk in them, each in a
            // pale surround with a colonnette between the two; a band of dog-tooth along the top, a chevron moulding
            // along the bottom.
            let spots = ([cx] + eterniaS4Bays(u.w, first: 54, step: 40).map(\.x)).sorted()
            for (a, b) in zip(spots, spots.dropFirst()) {
                let m = (a + b) / 2, spring = top - 12, bottom = top - 6
                for lx in [m - 4, m + 4] {
                    for y in (spring - 5)..<(bottom + 1) {
                        for xx in (lx - 4)...(lx + 4) {
                            if eterniaS4Arch(xx, y, cx: lx, hw: 2, spring: spring, bottom: bottom, r: 1.3) {
                                let k = Double(y - (spring - 4)) / Double(bottom - spring + 4)
                                u.px(xx, y, lerp(C(0x2A1C4C), C(0xD07A4A), k * k))
                            } else if eterniaS4Arch(xx, y, cx: lx, hw: 3, spring: spring, bottom: bottom, r: 1.3) {
                                u.px(xx, y, stone(xx, y, xx < lx ? 0.5 : 0.34, grain: 0.08))
                            }
                        }
                    }
                    u.px(lx - 1, spring - 1, C(0xFFFFFF, 0.7))
                    u.rect(lx - 4, bottom, 9, 1, tone[5]); u.rect(lx - 4, bottom + 1, 9, 1, tone[2])
                }
                u.rect(m, top - 15, 1, 9, tone[5]); u.rect(m - 1, top - 16, 3, 1, tone[6]); u.rect(m - 1, top - 6, 3, 1, tone[4])
            }
            for x in stride(from: 0, to: u.w, by: 4) {
                u.pattern(x, wallTop + 2, ["TTT", ".s."], ["T": tone[4], "s": tone[2]])
            }
            for x in 0..<u.w {
                let d = x % 4, y = top - 2 - (d < 2 ? d : 4 - d)
                u.px(x, y, tone[5]); u.px(x, y + 1, tone[2])
            }
            // A falcon carved with its wings spread in every bay.
            for b in eterniaS4Bays(u.w, first: 54, step: 40) {
                chamberFalcon(u, b.x, top - 13, span: 10, eyes: false)
            }
            chamberFalcon(u, cx, top - 13, span: 14, eyes: false)
            u.rect(0, wallTop, u.w, 1, tone[4]); u.rect(0, wallTop + 1, u.w, 1, tone[2])
        }
        // The frieze along the top of the hall: a heavy cornice, dentils under it.
        u.rect(0, top, u.w, 1, tone[5]); u.rect(0, top + 1, u.w, 1, tone[4]); u.rect(0, top + 2, u.w, 1, tone[2])
        for x in stride(from: 0, to: u.w, by: 3) { u.rect(x, top + 3, 2, 1, tone[3]) }
        // The plinth along the bottom, dark and plain so the crew stands out in front of it, a ledge on top.
        for y in (B - 9)..<B { for x in 0..<u.w { u.px(x, y, stone(x, y, 0.05, grain: 0.08)) } }
        u.rect(0, B - 9, u.w, 1, tone[4]); u.rect(0, B - 8, u.w, 1, tone[1])

        // The bays between the pillars: niches with falcons standing in them, and lancet windows.
        for b in eterniaS4Bays(u.w, first: 54, step: 40) {
            if b.k % 2 == 0 { chamberNiche(u, b.x, top, B, stone) } else { chamberWindow(u, b.x, top, stone) }
        }
        // The pillars: thick and round, lit on the side towards the pool, a capital and a base.
        for x in piers {
            let side = x < cx ? 1.0 : -1.0
            for y in (top + 4)..<(B - 9) {
                for xx in (x - 4)...(x + 3) {
                    let n = (Double(xx - x) + 0.5) / 4
                    let flute = (xx - x + 4) % 3 == 2 ? -0.08 : 0
                    u.px(xx, y, stone(xx, y, 0.18 + 0.2 * n * side + flute, grain: 0.1))
                }
            }
            u.rect(x - 6, top + 4, 12, 2, tone[4]); u.rect(x - 6, top + 4, 12, 1, tone[5])
            u.rect(x - 5, top + 6, 10, 2, tone[3]); u.rect(x - 5, top + 7, 10, 1, tone[2])
            u.rect(x - 6, B - 12, 12, 3, tone[3]); u.rect(x - 6, B - 12, 12, 1, tone[5])
            u.rect(x - 5, B - 13, 10, 1, tone[4])
        }

        // The alcove behind the throne: a tall pointed arch, deep and dark at the top, the pool's light filling it
        // from below; voussoirs of paler stone round it.
        let ahw = 22, spring = top + 30, abot = B - 9
        for y in (top + 4)..<abot {
            for x in (cx - ahw - 3)...(cx + ahw + 3) {
                if eterniaS4Arch(x, y, cx: cx, hw: ahw, spring: spring, bottom: abot) {
                    u.px(x, y, stone(x, y, -0.12 + Double(y - top) / 56 * 0.08, grain: 0.1))
                } else if eterniaS4Arch(x, y, cx: cx, hw: ahw + 3, spring: spring, bottom: abot, r: 1.1) {
                    let joint = (x * 3 + y * 2) % 11 == 0
                    let inner = eterniaS4Arch(x, y, cx: cx, hw: ahw + 1, spring: spring, bottom: abot)
                    u.px(x, y, joint ? tone[2] : stone(x, y, inner ? 0.5 : 0.36, grain: 0.1))
                }
            }
        }
        // The keystone at its point, a little skull of Greyskull carved on it.
        u.rect(cx - 3, top + 3, 7, 6, tone[5]); u.rect(cx - 3, top + 3, 7, 1, tone[6]); u.rect(cx + 3, top + 3, 1, 6, tone[3])
        u.pattern(cx - 2, top + 4, [".SSS.", "SKSKS", ".SKS.", ".S.S."], ["S": tone[6], "K": tone[1]])

        // The great falcon carved across the alcove, wings spread, its eyes lit.
        chamberFalcon(u, cx, top + 10, span: 26, eyes: true)

        // The throne: a tall back of stone with a pointed crest, the sky-blue gem in it, broad arms, a heavy seat.
        let seat = B - 17
        for y in (B - 36)..<seat {
            let crest = B - 32 - y
            let hw = crest > 0 ? max(0, 6 - crest * 3 / 2) : 6
            for x in (cx - hw)...(cx + hw) {
                let n = Double(x - cx) / 6
                u.px(x, y, stone(x, y, 0.62 - abs(n) * 0.16, grain: 0.1))
            }
            u.px(cx - hw, y, tone[6]); u.px(cx + hw, y, tone[2])
        }
        u.rect(cx - 4, B - 30, 9, seat - (B - 30), tone[3]); u.rect(cx - 4, B - 30, 1, seat - (B - 30), tone[2])
        u.rect(cx - 3, B - 29, 7, 1, tone[4])
        // Feathers carved down the panel, in chevrons.
        for y in stride(from: B - 27, to: seat - 1, by: 3) { u.px(cx - 2, y, tone[4]); u.px(cx, y + 1, tone[4]); u.px(cx + 2, y, tone[4]) }
        u.circle(cx, B - 33, 2, C(0x3A7AC0)); u.rect(cx - 1, B - 34, 2, 2, glow); u.px(cx - 1, B - 34, C(0xDFF4FF))
        u.circle(cx, B - 33, 5, C(0x8AD0FF, 0.12))
        for (x0, w) in [(cx - 10, 4), (cx + 7, 4)] {
            u.rect(x0, seat - 5, w, 5, tone[4]); u.rect(x0, seat - 5, w, 1, tone[6]); u.rect(x0 + w - 1, seat - 4, 1, 4, tone[2])
        }
        u.rect(cx - 10, seat, 21, 5, tone[4]); u.rect(cx - 10, seat, 21, 1, tone[6]); u.rect(cx - 10, seat + 4, 21, 1, tone[2])
        u.rect(cx - 8, seat + 1, 17, 3, stone(cx, seat + 2, 0.5))

        // The dais: three broad steps, the pool sunk into the middle one, the bottom one plain and dark.
        for (y, hw, h, v) in [(B - 12, 15, 3, 0.4), (B - 9, 26, 4, 0.3), (B - 5, 36, 5, 0.12)] {
            for yy in y..<(y + h) {
                for x in (cx - hw)...(cx + hw) { u.px(x, yy, stone(x, yy, v, grain: 0.08)) }
            }
            u.rect(cx - hw, y, hw * 2 + 1, 1, lerp(tone[6], glow, 0.25)); u.rect(cx - hw, y + h - 1, hw * 2 + 1, 1, tone[1])
        }
        // The pool: a ring of pale stone round water glowing sky blue, brightest in the middle.
        u.ellipse(pool.x, pool.y, 14, 3, tone[6]); u.ellipse(pool.x, pool.y + 1, 13, 2, tone[4])
        u.ellipse(pool.x, pool.y, 12, 2, C(0x2E78B8)); u.ellipse(pool.x, pool.y, 9, 1, C(0x4A9ADA))
        u.rect(pool.x - 6, pool.y, 13, 1, C(0x8ACCF4)); u.rect(pool.x - 2, pool.y, 5, 1, C(0xD0F0FF))
        u.circle(pool.x, pool.y - 4, 16, C(0x8AD0FF, 0.07)); u.circle(pool.x, pool.y - 2, 9, C(0x8AD0FF, 0.08))
    }

    /// A falcon carved in the stone with its wings spread, `span` either side of `x`, its head at row `y`: long
    /// feathers fanning out and down from its shoulders, its breast in chevrons, the hooked beak; `eyes` lights them.
    private static func chamberFalcon(_ u: PixelCanvas, _ x: Int, _ y: Int, span: Int, eyes: Bool) {
        // The great falcon over the throne (`eyes`) is carved in the palest stone, a step brighter all over, so it
        // stands out against the dark of the alcove even in the window.
        let base = chamberStone, b = eyes ? 1 : 0
        let tone = (0..<base.count).map { base[min(base.count - 1, $0 + b)] }
        let sh = Double(span) / 20
        // The wings: a solid fan of long feathers each side, the outer ones longest and nearly level, the inner ones
        // short and steep, every other one a shade darker so they read as feathers; a band of small coverts over
        // their roots, lit along its top edge.
        for side in [-1.0, 1.0] {
            for i in 0..<11 {
                let a = -0.3 + Double(i) * 0.15, len = (19 - Double(i) * 1.0) * sh
                let x0 = Double(x) + side * 2 * sh, y0 = Double(y) + 4 + Double(i) * 0.4 * sh
                let x1 = x0 + side * cos(a) * len, y1 = y0 + sin(a) * len
                for w in [-1.0, 0, 1] {
                    eterniaS4Line(u, x0, y0 + w, x1, y1 + w, tone[i % 2 == 0 ? 5 : 4])
                }
                eterniaS4Line(u, x0 + side * len * 0.4 * cos(a), y0 + len * 0.4 * sin(a) + 1, x1, y1 + 1, eyes ? base[1] : tone[3])
                u.px(Int(x1.rounded()), Int(y1.rounded()), tone[6])
            }
            let ex = Double(x) + side * 6 * sh, ey = Double(y) + 5
            u.ellipse(Int(ex.rounded()), Int(ey), max(2, Int(5 * sh)), max(1, Int(2.5 * sh)), tone[4])
            eterniaS4Line(u, Double(x) + side * 2, ey - 2 * sh, Double(x) + side * 11 * sh, ey - 3 * sh, tone[6])
            for k in stride(from: 3.0, to: 10 * sh, by: 2.0) { u.px(Int(Double(x) + side * k), Int(ey + 1), tone[3]) }
        }
        // The body and breast, the tail fanning under it.
        let bh = max(4, Int(9 * sh))
        u.ellipse(x, y + 4 + bh / 2, max(2, Int(4 * sh)), bh / 2 + 1, tone[4])
        for k in stride(from: 2, to: bh, by: 2) { u.px(x - 1, y + 4 + k, tone[3]); u.px(x + 1, y + 4 + k, tone[3]); u.px(x, y + 5 + k, tone[3]) }
        for dx in -2...2 { eterniaS4Line(u, Double(x), Double(y + 4 + bh), Double(x + dx * 2), Double(y + 8 + bh), tone[dx == 0 ? 5 : 4]) }
        // The head: round, a dark band down past each eye, the hooked beak in the middle.
        u.circle(x, y + 1, 3, tone[5]); u.rect(x - 2, y - 2, 5, 1, tone[6])
        u.px(x - 2, y + 1, tone[2]); u.px(x + 2, y + 1, tone[2])
        u.px(x - 1, y, eyes ? C(0x9AD8FF) : tone[1]); u.px(x + 1, y, eyes ? C(0x9AD8FF) : tone[1])
        u.rect(x, y + 1, 1, 3, tone[7]); u.px(x - 1, y + 3, tone[6])
        if eyes { u.circle(x, y, 4, C(0x8AD0FF, 0.12)) }
    }

    /// A niche at `x`: a pointed recess, dark at the back, with a stone falcon standing in it on a plinth, wings
    /// folded, lit from the side the pool is on.
    private static func chamberNiche(_ u: PixelCanvas, _ x: Int, _ top: Int, _ B: Int, _ stone: (Int, Int, Double, Double) -> Px) {
        let tone = chamberStone, spring = top + 20, bottom = B - 9
        for y in (top + 8)..<bottom {
            for xx in (x - 9)...(x + 9) {
                if eterniaS4Arch(xx, y, cx: x, hw: 7, spring: spring, bottom: bottom) {
                    u.px(xx, y, stone(xx, y, -0.15 + Double(y - top) / 56 * 0.1, 0.1))
                } else if eterniaS4Arch(xx, y, cx: x, hw: 9, spring: spring, bottom: bottom) {
                    u.px(xx, y, (xx + y) % 5 == 0 ? tone[2] : stone(xx, y, 0.34, 0.1))
                }
            }
        }
        // The plinth.
        u.rect(x - 5, B - 15, 11, 6, stone(x, B - 12, 0.3, 0.1)); u.rect(x - 5, B - 15, 11, 1, tone[6])
        u.rect(x - 4, B - 13, 9, 1, tone[2])
        // The falcon, from the front: round head, hooked beak, folded wings down either side of the breast.
        let rows = [
            "...HHHHH...",
            "..HHHHHHH..",
            ".HHEHHHEHH.",
            ".HHHHbHHHH.",
            "..HHHbbHH..",
            "...HHbHH...",
            "..WWHHHWW..",
            ".WWWBBBWWW.",
            "WWWBcBcBWWW",
            "WWWBBcBBWWW",
            "WWWBcBcBWWW",
            ".WWBBcBBWW.",
            ".WWWBBBWWW.",
            "..WWWBWWW..",
            "...WTTTW...",
            "..TTTTTTT..",
            ".TT.T.T.TT.",
        ]
        let pal: [Character: Px] = ["H": tone[6], "E": tone[0], "b": tone[7], "W": tone[4], "B": tone[6], "c": tone[3],
                                    "T": tone[3]]
        u.pattern(x - 5, B - 32, rows, pal)
        // The light from the pool along its near side.
        let near = x < u.w / 2 ? 10 : 0
        for (r, row) in rows.enumerated() {
            let chars = Array(row)
            let idx = near == 10 ? chars.lastIndex(where: { $0 != "." }) : chars.firstIndex(where: { $0 != "." })
            if let i = idx, r > 0 { u.px(x - 5 + i, B - 32 + r, lerp(tone[7], C(0x6AB8F0), 0.3)) }
        }
    }

    /// A lancet window at `x`: narrow and pointed, Greyskull's violet-to-orange dusk outside it, a pale surround
    /// and a sill.
    private static func chamberWindow(_ u: PixelCanvas, _ x: Int, _ top: Int, _ stone: (Int, Int, Double, Double) -> Px) {
        let tone = chamberStone, spring = top + 18, bottom = top + 38
        for y in (top + 10)..<(bottom + 1) {
            for xx in (x - 6)...(x + 6) {
                if eterniaS4Arch(xx, y, cx: x, hw: 3, spring: spring, bottom: bottom, r: 1.3) {
                    let k = Double(y - (top + 13)) / 25
                    u.px(xx, y, lerp(C(0x2A1C4C), C(0xF0904A), k * k))
                } else if eterniaS4Arch(xx, y, cx: x, hw: 5, spring: spring, bottom: bottom, r: 1.3) {
                    u.px(xx, y, stone(xx, y, xx < x ? 0.44 : 0.3, 0.1))
                }
            }
        }
        u.px(x - 1, top + 17, C(0xFFFFFF, 0.8)); u.px(x + 1, top + 24, C(0xE8D8F0, 0.6))
        // A far violet peak in the bottom of the glass, the castle's dusk behind it.
        u.rect(x - 3, bottom - 3, 7, 3, C(0x56385E)); u.rect(x - 1, bottom - 4, 3, 1, C(0x6A4670))
        u.rect(x - 7, bottom, 15, 1, tone[6]); u.rect(x - 7, bottom + 1, 15, 1, tone[2])
    }

    /// The chamber's life: the pool's light rippling over the walls, the alcove and the throne, rings spreading on
    /// the water, motes of light rising off it and, on the screen saver, the braziers' flames flickering.
    static func eterniaChamberLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaS4Frame(c, g, room: true)
        let u = PixelCanvas(f.w, f.h)
        let B = f.h, cx = f.w / 2, top = B - 56
        let px0 = cx, py0 = B - 7
        // The ripples: bands of light wavering over the stone round the pool, fading with distance.
        for y in max(0, top + 4)..<(B - 10) {
            for x in max(0, cx - 80)..<min(f.w, cx + 80) {
                let dx = Double(x - px0) / 80, dy = Double(y - py0) / 46
                let d = (dx * dx + dy * dy).squareRoot()
                guard d < 1 else { continue }
                let w = sin(Double(x) * 0.42 + t * 1.5 + sin(Double(y) * 0.5 + t * 0.9) * 1.6)
                    * sin(Double(y) * 0.7 - t * 1.1 + Double(x) * 0.13)
                guard w > 0.72 else { continue }
                u.px(x, y, C(0xA8E4FF, 0.3 * (1 - d)))
            }
        }
        // Rings spreading out across the water from the middle.
        for k in 0..<3 {
            let r = (t * 0.35 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            let rx = 2 + r * 9, ry = max(0.6, rx / 6)
            for i in 0..<36 {
                let a = Double(i) / 36 * 2 * .pi
                u.px(px0 + Int((cos(a) * rx).rounded()), py0 + Int((sin(a) * ry).rounded()), C(0xE0F6FF, 0.7 * (1 - r)))
            }
        }
        // Motes of light drifting up off the pool and fading.
        for k in 0..<7 {
            let ph = (t * 0.1 + Double(k) / 7).truncatingRemainder(dividingBy: 1)
            let x = px0 - 9 + Int(noise(k * 5 + 3) * 18) + Int((sin(t * 0.8 + Double(k)) * 2).rounded())
            let y = py0 - 2 - Int(ph * 30)
            u.px(x, y, C(0xC8F0FF, 0.8 * (1 - ph)))
        }
        // The braziers' flames: tongues of orange licking up over the coals.
        for (i, b) in chamberBraziers(f.w, f.h).enumerated() {
            let ph = Int(t * 8 + Double(i) * 1.9) % 4
            let lean = [0, 1, 0, -1][ph]
            u.circle(b.x, b.y - 4, 5, C(0xFFA040, 0.05 + 0.03 * Double(ph % 2)))
            // One flame, a mound of fire tallest in the middle, yellow at heart, orange, red at its ragged tips.
            for dx in -4...4 {
                let lick = noise(dx * 7 + ph * 13 + i * 31) * 2.4
                let rise: Double = 6.5 - Double(abs(dx)) * 1.3 + lick
                let h = Int(rise.rounded())
                guard h > 0 else { continue }
                for j in 0..<h {
                    let k = Double(j) / Double(h)
                    let col = k < 0.35 && abs(dx) < 3 ? C(0xFFE890) : k < 0.75 ? C(0xF08A28) : C(0xD04A18)
                    u.px(b.x + dx + (j > 2 ? lean : 0), b.y - 2 - j, col)
                }
            }
        }
        eterniaS4BlowUp(c, u, f.x, f.y, f.q)
    }
}

// MARK: - The Mystic Mountains

/// The Mystic Mountains' violet rock, darkest first.
private let mysticRock = [C(0x1A1230), C(0x281C46), C(0x3A2A62), C(0x50397E), C(0x6A4E9C), C(0x8868BA), C(0xAC8ED8)]
/// The glowing green of the crystal veins and shards.
private let mysticGlow = (lit: C(0xA8FFD0), mid: C(0x5AE0A0), dark: C(0x2A9A6E))

/// The floating rocks near enough to bob, on the mountains' canvas `w` by `h`: the middle of each, its top row,
/// its width, whether it carries peaks of its own, and its phase. The big ones high up are the screen saver's.
private func mysticRocks(_ w: Int, _ h: Int) -> [(x: Int, y: Int, w: Int, peaks: Bool, ph: Double)] {
    let cx = w / 2, top = h - 56
    var out: [(x: Int, y: Int, w: Int, peaks: Bool, ph: Double)] = [
        (cx - 46, top + 5, 10, false, 0.0), (cx + 42, top + 3, 12, false, 1.7), (cx - 94, top + 12, 13, false, 3.1),
        (cx + 98, top + 10, 10, false, 4.4), (cx - 146, top + 4, 9, false, 2.3), (cx + 152, top + 7, 13, false, 5.2),
        (cx - 204, top + 11, 11, false, 0.9), (cx + 208, top + 3, 9, false, 3.8),
    ]
    if top >= 30 {
        // Their top rows, kept low enough that the crowns stay inside the picture.
        func row(_ k: Int, _ w: Int) -> Int { max(w / 2 + 4, top * k / 100) }
        out += [(cx - 52, row(34, 28), 28, true, 0.4), (cx + 50, row(16, 30), 30, true, 2.6),
                (cx + 4, row(62, 16), 16, true, 4.0), (cx - 18, row(8, 12), 12, false, 1.2),
                (cx + 70, row(66, 12), 12, false, 5.5), (cx - 76, row(82, 10), 10, false, 3.3)]
    }
    return out
}

/// A floating rock on a canvas of its own, `w` units wide: a flat top of pale rock (or a crown of jagged peaks),
/// tapering underneath to a point like an upturned mountain, a shard of green crystal glowing under its tip.
/// Returns the art and the row of its top surface.
private func mysticFloatingRock(_ w: Int, peaks: Bool, seed: Int) -> (art: PixelCanvas, deck: Int) {
    let crown = peaks ? w / 2 : 2, depth = max(4, w * 7 / 10)
    let art = PixelCanvas(w + 2, crown + depth + 6)
    let deck = crown + 1
    let mid = Double(w + 1) / 2, half = Double(w) / 2
    let rock = mysticRock
    // Where the peaks of the crown stand, and how tall each is.
    let tips: [(x: Double, h: Double)] = peaks
        ? [(mid - half * 0.45, Double(crown) * 0.7), (mid + half * 0.1, Double(crown)), (mid + half * 0.6, Double(crown) * 0.5)]
        : [(mid - half * 0.2, 1.5), (mid + half * 0.35, 1.0)]
    for x in 1...w {
        let k = (Double(x) - mid) / half
        var lift = 0.0
        for tip in tips { lift = max(lift, tip.h - abs(Double(x) - tip.x) * (peaks ? 1.3 : 0.8)) }
        lift += (noise(x * 13 + seed) - 0.5) * (peaks ? 1.6 : 0.8)
        let topY = deck - max(0, Int(lift.rounded()))
        let drop = Double(depth) * (1 - pow(abs(k), 1.4)) + (noise(x * 7 + seed + 40) - 0.5) * 2
        let bottomY = deck + Int(drop.rounded())
        var nearX = tips[0].x
        for tip in tips where abs(Double(x) - tip.x) < abs(Double(x) - nearX) { nearX = tip.x }
        for y in topY...max(topY, bottomY) {
            let col: Px
            if y < deck {
                // The crown: faceted, lit on the left of each peak, darkening down towards the rock's top.
                let lit = Double(x) <= nearX
                let v = (lit ? 0.84 : 0.4) - Double(y - topY) / Double(max(1, crown)) * 0.18
                col = y == topY ? (lit ? rock[6] : rock[4]) : eterniaS4Dither(rock, v, x + seed, y, grain: 0.16)
            } else if y == deck || y == topY {
                col = !peaks && x % 5 == 2 ? mysticGlow.mid : rock[6]
            } else {
                let v = 0.62 - Double(y - deck) / Double(depth) * 0.5 - k * 0.18
                col = eterniaS4Dither(Array(rock[1...5]), v, x + seed, y, grain: 0.22)
            }
            art.px(x, y, col)
        }
        if bottomY > deck { art.px(x, bottomY, rock[0]) }
        art.px(x, topY, Double(x) < mid ? rock[6] : rock[5])
    }
    // The underside broken into facets: cracks running from under the rim down towards the tip, as if the rock had
    // been torn out of the ground point first, each crack dark with a lit edge on the side facing the light.
    let cracks = max(2, w / 4)
    for j in 0..<cracks {
        let kk = -0.8 + 1.6 * (Double(j) + 0.5) / Double(cracks) + (noise(j * 17 + seed) - 0.5) * 0.2
        let x0 = mid + kk * half * 0.85, y0 = Double(deck + 2)
        let reach = 0.55 + noise(j * 23 + seed) * 0.3
        let x1 = mid + kk * half * 0.35, y1 = Double(deck) + Double(depth) * reach
        let n = max(1, Int(max(abs(x1 - x0), abs(y1 - y0)).rounded()))
        for i in 0...n {
            let k = Double(i) / Double(n)
            let x = Int((x0 + (x1 - x0) * k).rounded()), y = Int((y0 + (y1 - y0) * k).rounded())
            guard x > 0, x < art.w - 1, art.buf[(y * art.w + x) * 4 + 3] > 0, art.buf[(y * art.w + x + 1) * 4 + 3] > 0 else { continue }
            art.px(x, y, rock[1]); art.px(x + (kk < 0 ? -1 : 1), y, kk < 0 ? rock[5] : rock[2])
        }
    }
    // A lit edge down the left of the underside.
    for y in (deck + 1)..<(deck + depth) {
        if let x = (1...w).first(where: { art.buf[(y * art.w + $0) * 4 + 3] > 0 }) { art.px(x, y, rock[5]) }
    }
    let tipX = Int(mid), tipY = deck + depth
    art.px(tipX, tipY, mysticGlow.mid); art.px(tipX, tipY + 1, mysticGlow.lit); art.px(tipX, tipY + 2, mysticGlow.mid)
    art.px(tipX - 1, tipY, mysticGlow.dark)
    return (art, deck)
}

extension Scenes {
    /// The Mystic Mountains, where Zodac and Sy-Clawdne keep watch: a green Filmation sky, pale jade at the horizon,
    /// and a range of jagged violet peaks, faceted, lit lilac on their left faces and deep indigo on their right,
    /// veins of green crystal glowing in the rock. Boulders and whole crags hang in the air over them with nothing
    /// holding them up, a green shard glowing under each. Ranges fade into the haze behind, a stair climbs to a
    /// lookout door in the tallest peak, green crystals stand in clumps at the sides, and the crew stands on a ledge
    /// of dark violet scree. On the screen saver the mountains stand three times the size, upturned peaks float up
    /// into the sky, and a ringed moon hangs among the first stars.
    static func eterniaMysticMountains(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaS4Frame(c, g), tall = isTall(c)
        c.gradient(0, g, C(0x0A2A26), C(0xB4E0A4), bands: tall ? 12 : 7)
        if tall {
            c.stars(0, g / 5, density: 80, seed: 5)
            // The ringed moon, lilac, its ring tilted: the back of the ring first, then the moon, then the front.
            let mx = c.w * 61 / 100, my = g * 12 / 100, mr = 10 * s
            func ring(front: Bool) {
                for i in 0..<240 {
                    let a = Double(i) / 240 * 2 * .pi
                    guard (sin(a) > 0) == front else { continue }
                    let rx = cos(a) * Double(mr) * 2.1, ry = sin(a) * Double(mr) * 0.45
                    let x = mx + Int((rx * 0.97 - ry * 0.26).rounded()), y = my + Int((ry * 0.97 + rx * 0.26).rounded())
                    c.rect(x, y, s + 1, s, front ? C(0xF0E2B8) : C(0xB8AC94))
                }
            }
            ring(front: false)
            c.circle(mx, my, mr, C(0xC8B4E8)); c.circle(mx - mr / 4, my - mr / 4, mr * 3 / 4, C(0xDCCCF4))
            c.circle(mx + mr / 3, my + mr / 5, mr / 4, C(0xB09CD4)); c.circle(mx - mr / 3, my + mr / 3, mr / 5, C(0xB8A4DC))
            ring(front: true)
        }
        // Long violet wisps of cloud across the green.
        let wisps: [(x: Int, y: Int, len: Int)] = tall
            ? [(10, 30, 40), (60, 40, 50), (30, 58, 36), (84, 62, 30), (6, 74, 28), (52, 80, 44)]
            : [(8, 14, 30), (64, 10, 26), (88, 30, 20), (36, 24, 18)]
        for (k, w) in wisps.enumerated() {
            let x = c.w * w.x / 100, y = g * w.y / 100, len = w.len * s * (tall ? 3 : 2)
            Scenes.wisp(c, x, y, len, k % 2 == 0 ? C(0x9A7AC8, 0.55) : C(0xC0A0E0, 0.45), s: s * (tall ? 2 : 1))
        }
        let u = PixelCanvas(f.w, f.h)
        eterniaMysticRange(u)
        eterniaS4BlowUp(c, u, f.x, f.y, f.q)
        c.ground(g, C(0x2A2040), edge: C(0x4E3E72), speck: C(0x1E1630), seed: 13)
    }

    /// The mountains, one pixel to a unit, their foot along the bottom row and their 56 rows at the bottom of the
    /// canvas: the hazy ranges behind, the faceted peaks in front, scree and crystal at their feet.
    static func eterniaMysticRange(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let rock = mysticRock
        // Far islands drifting in the haze, too far off to see them move.
        var far: [(x: Int, y: Int, w: Int)] = [(cx - 70, top + 2, 8), (cx + 76, top + 14, 7), (cx - 124, top + 16, 9),
                                               (cx + 128, top + 1, 8), (cx - 178, top + 9, 7), (cx + 180, top + 18, 8)]
        if top >= 30 {
            far += [(cx - 30, top * 40 / 100, 10), (cx + 22, top * 82 / 100, 9), (cx - 66, top * 10 / 100, 8),
                    (cx + 72, top * 34 / 100, 11), (cx - 8, top * 20 / 100, 7)]
        }
        // Hazed towards the far ranges' lavender, not grey, so they stay violet rock; their crystal still glows.
        for (i, fr) in far.enumerated() {
            let r = mysticFloatingRock(fr.w, peaks: i % 3 == 0, seed: i * 11 + 300)
            for yy in 0..<r.art.h {
                for xx in 0..<r.art.w where r.art.buf[(yy * r.art.w + xx) * 4 + 3] > 0 {
                    let col = unpremultiplied(r.art, (yy * r.art.w + xx) * 4)
                    let glows = Int(col.g) > Int(col.r) + 40
                    u.px(fr.x - r.art.w / 2 + xx, fr.y + yy - r.deck, glows ? col : lerp(col, C(0x9C90C8), 0.42))
                }
            }
        }
        // The ranges behind: jagged and hazed, the far one pale, the nearer one deeper violet.
        func range(base: Int, amp: Int, period: Int, seed: Int, _ col: Px, edge: Px, lit: Px) {
            for x in 0..<u.w {
                let k = x / period, fr = Double(x % period) / Double(period)
                let h0 = noise(k * 31 + seed), h1 = noise((k + 1) * 31 + seed)
                let v = h0 * (1 - fr) + h1 * fr - 0.5 * sin(fr * .pi)
                let y0 = base - Int(v * Double(amp))
                guard y0 < B else { continue }
                u.rect(x, y0, 1, B - y0, col)
                u.px(x, y0, edge)
                // The left face of each peak catches the light.
                if (h1 < h0 && fr > 0.5) || (h1 >= h0 && fr < 0.5) { u.rect(x, y0 + 1, 1, min(3, B - y0 - 1), lit) }
            }
        }
        range(base: B - 18, amp: top >= 30 ? 34 : 26, period: 13, seed: 7, C(0x8E8EB4), edge: C(0xB8B8D8), lit: C(0xA2A2C6))
        range(base: B - 10, amp: 20, period: 9, seed: 19, C(0x564480), edge: C(0x8A74B8), lit: C(0x6C58A0))

        /// A crag: a jagged faceted peak with its tip at `tip`, `hw` either side of `x` at its foot, lit lilac on
        /// its left face, deep indigo on its right, cracks running down both faces and a vein of green crystal.
        func crag(_ x: Int, _ tip: Int, _ hw: Int, seed: Int, vein: Bool = true, leans: Double = 4) {
            let foot = B - 6
            let lean = (noise(seed + 3) - 0.5) * leans
            func ridge(_ y: Int) -> Int {
                let k = Double(y - tip) / Double(max(1, foot - tip))
                return x + Int((lean * k + (noise(seed * 5 + y / 3) - 0.5) * 1.6).rounded())
            }
            for y in tip..<B {
                let k = min(1, Double(y - tip) / Double(max(1, foot - tip)))
                // Shoulders jut out every few rows, so the flanks step out jaggedly rather than run smooth.
                let stepL = noise(seed * 7 + y / 4) > 0.6 ? 1.6 : 0.0
                let stepR = noise(seed * 7 + y / 4 + 50) > 0.6 ? 1.6 : 0.0
                let spread = Double(hw) * pow(k, 0.8)
                let l = spread + stepL + (noise(seed + y) - 0.5) * 1.2
                let r = spread * 0.9 + stepR + (noise(seed + y + 90) - 0.5) * 1.2
                let rx = ridge(y)
                let x0 = rx - Int(max(0, l).rounded()), x1 = rx + Int(max(0, r).rounded())
                for xx in x0...max(x0, x1) {
                    let col: Px
                    if xx < rx {
                        let n = Double(rx - xx) / max(1, l)
                        col = eterniaS4Dither(rock, 0.86 - n * 0.22 - k * 0.2, xx, y, grain: 0.14)
                    } else if xx == rx {
                        col = rock[6]
                    } else {
                        col = eterniaS4Dither(rock, 0.34 - k * 0.12, xx, y, grain: 0.14)
                    }
                    u.px(xx, y, col)
                }
                if x1 > x0 { u.px(x0, y, rock[6]); u.px(x1, y, rock[0]) }
            }
            // Cracks: down-left across the lit face, down-right across the shaded one.
            for i in 0..<3 {
                let y0 = tip + 4 + i * (foot - tip) / 4
                let sx = ridge(y0)
                eterniaS4Line(u, Double(sx - 1), Double(y0), Double(sx - 2 - hw / 3), Double(y0 + 5 + i), rock[4])
                eterniaS4Line(u, Double(sx + 1), Double(y0 + 2), Double(sx + 2 + hw / 3), Double(y0 + 8), rock[1])
            }
            // A vein of crystal glowing green, running crookedly down the rock.
            guard vein else { return }
            let vy = tip + (foot - tip) / 3
            var vx = Double(ridge(vy)) - Double(hw) * 0.25
            for y in vy..<max(vy + 1, min(foot - 2, vy + (foot - tip) / 2)) {
                vx += (noise(seed * 3 + y) - 0.45) * 1.4
                u.px(Int(vx.rounded()), y, y % 4 == 0 ? mysticGlow.lit : mysticGlow.mid)
                u.px(Int(vx.rounded()) + 1, y, mysticGlow.dark)
            }
        }
        // Crags along the sides first, then the massif, the tallest last and in front.
        // Each its own: a needle or a broad tooth, leaning one way or the other, some with a lower shoulder peak
        // beside them, and only some veined, so no two along the row look alike.
        for b in eterniaS4Bays(u.w, first: 100, step: 42) {
            let r1 = noise(b.x * 3 + 5), r2 = noise(b.x * 3 + 6), r3 = noise(b.x * 3 + 7)
            let x = b.x + Int((r1 - 0.5) * 24), tip = top + 12 + Int(r2 * 30), hw = 6 + Int(r3 * 11)
            if r1 > 0.45 {
                let side = r2 > 0.5 ? 1 : -1
                crag(x + side * (hw * 3 / 4 + 3), tip + 9 + Int(r3 * 8), max(5, hw * 2 / 3), seed: b.x + 77, vein: false, leans: 8)
            }
            crag(x, tip, hw, seed: b.x, vein: r3 > 0.35, leans: 4 + r1 * 10)
        }
        let massif: [(dx: Int, tip: Int, hw: Int)] = [(-72, 32, 9), (70, 30, 10), (-52, 22, 12), (52, 24, 11),
                                                       (-32, 12, 15), (32, 14, 14), (12, 6, 15), (-12, 1, 18)]
        for m in massif { crag(cx + m.dx, top + m.tip, m.hw, seed: m.dx * 3 + 500) }
        // A stone stair cut up the foot of the tallest peak, to a dark doorway (Zodac's lookout).
        for i in 0..<5 {
            u.rect(cx - 20 + i * 2, B - 10 - i * 2, 5, 2, rock[5]); u.rect(cx - 20 + i * 2, B - 9 - i * 2, 5, 1, rock[2])
        }
        u.rect(cx - 13, B - 24, 5, 6, rock[0]); u.rect(cx - 12, B - 25, 3, 1, rock[0]); u.rect(cx - 14, B - 25, 1, 7, rock[6])
        u.px(cx - 11, B - 22, mysticGlow.mid)

        // The scree at the mountains' feet: dark violet slopes, plain where the crew stands.
        u.dunes(base: B - 7, amp: 2.5, freq: 0.11, phase: 1.3, bottom: B, C(0x30244A), shade: C(0x4A3A6C))
        u.dunes(base: B - 3, amp: 1.5, freq: 0.19, phase: 0.2, bottom: B, C(0x261C3A), shade: C(0x3A2E58))
        // Clumps of green crystal at the sides, glowing.
        for b in eterniaS4Bays(u.w, first: 64, step: 47) {
            let n = noise(b.x + 11)
            // Up on the scree, behind where the crew stands, so it doesn't crowd them.
            let shards: [(ox: Int, h: Int)] = n > 0.5 ? [(-2, 3), (0, 5), (2, 4), (4, 2)] : [(-2, 3), (0, 5), (2, 3)]
            let foot = B - 8
            for sh in shards {
                let hh = sh.h + Int(n * 2), x0 = b.x + sh.ox
                for y in 0..<hh {
                    let top = y >= hh - 2
                    u.px(x0, foot - y, top ? mysticGlow.lit : mysticGlow.mid)
                    if !top { u.px(x0 + 1, foot - y, mysticGlow.dark) }
                }
            }
            u.ellipse(b.x + 1, foot - 2, 6, 3, C(0x7AF0B0, 0.07))
        }
    }

    /// The Mystic Mountains' life: the floating rocks bobbing slowly in the air, each at its own pace, a soft green
    /// glow under each; on the screen saver the great upturned peaks drift up and down high in the sky.
    static func eterniaMysticMountainsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaS4Frame(c, g), q = f.q
        for (i, r) in mysticRocks(f.w, f.h).enumerated() {
            let speed = 0.5 + Double(i % 3) * 0.12
            let bob = Int((sin(t * speed + r.ph) * 1.6 * Double(q)).rounded())
            let rock = mysticFloatingRock(r.w, peaks: r.peaks, seed: i * 17 + 40)
            let x = f.x + (r.x - rock.art.w / 2) * q, y = f.y + (r.y - rock.deck) * q + bob
            let tipX = x + (rock.art.w / 2) * q, tipY = y + (rock.art.h - 3) * q
            let pulse = 0.5 + 0.5 * sin(t * 1.3 + r.ph)
            c.ellipse(tipX, tipY + 2 * q, max(2, r.w * q / 4), max(1, q * 3 / 2), C(0x7AF0B0, 0.04 + 0.03 * pulse))
            c.ellipse(tipX, tipY + q, max(1, r.w * q / 8), max(1, q), C(0x9AFFC8, 0.06 + 0.05 * pulse))
            eterniaS4BlowUp(c, rock.art, x, y, q)
        }
    }
}

// MARK: - Avion

/// Avion's marble, darkest first, and its crimson roofs.
private let avionMarble = [C(0x7C7698), C(0xA8A2C0), C(0xD2CEE2), C(0xF4F2FA)]
private let avionRoof = [C(0x5E1626), C(0x8E2234), C(0xB83444), C(0xE05A5C)]
/// The far towers' paler marble and roofs, and the far clouds, lit pink-white on top down to lavender.
private let avionPaleWall = [C(0xB8A6C8), C(0xCCBCD8), C(0xE0D4EA), C(0xF0EAF6)]
private let avionPaleRoof = [C(0x9A5C80), C(0xB07090), C(0xC488A4), C(0xD8A0B4)]
private let avionFarClouds = [C(0xFCE6EC), C(0xEACADA), C(0xD4B4D0), C(0xBCA0C6), C(0xA88EBC)]

/// The towers of Avion on its canvas, `cx` its middle and `top` the top of its 56 rows: each one's middle, width,
/// the top of its roof, the roof's height, and what it carries (0 nothing, 1 a perch, 2 wings). The great tower last.
private func avionTowers(_ cx: Int, _ top: Int) -> [(x: Int, w: Int, roof: Int, rh: Int, extra: Int)] {
    [(cx - 46, 6, top + 22, 7, 1), (cx + 47, 7, top + 20, 7, 1), (cx - 14, 5, top + 24, 6, 0), (cx + 15, 5, top + 26, 6, 0),
     (cx - 27, 8, top + 13, 8, 1), (cx + 28, 9, top + 10, 9, 2), (cx, 12, top + 2, 10, 2)]
}

extension Scenes {
    /// Avion, Stratos's city of the bird people, high over a sea of cloud at dawn: the sky indigo overhead, going rose
    /// and then gold down to the clouds, the sun just up. Slender towers of white marble stand on the clouds, crimson
    /// cone roofs with gold spikes, arched windows in rows, perches jutting out for landing on, skybridges arching
    /// between them; the great tower in the middle has a pair of carved wings spread at its shoulders. Paler towers
    /// stand on far banks of cloud either side. The crew stands on a terrace of rose-grey stone behind a balustrade,
    /// the clouds below in shadow. On the screen saver the city stands three times the size, the sun big and low,
    /// more towers on islands of cloud higher up.
    static func eterniaAvion(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaS4Frame(c, g), tall = isTall(c)
        let mid = g * 55 / 100
        c.gradient(0, mid, C(0x1E2866), C(0xC07AA8), bands: tall ? 9 : 5)
        c.gradient(mid, g, C(0xC07AA8), C(0xF8D49A), bands: tall ? 7 : 4)
        if tall { c.stars(0, g / 6, density: 140, seed: 8) }
        // The sun, just up over the clouds, in rings of glow.
        let sun = (x: c.w * (tall ? 20 : 84) / 100, y: tall ? g * 58 / 100 : g - 24 * f.q, r: (tall ? 18 : 7) * s)
        for (k, a) in [(3.0, 0.08), (2.1, 0.12), (1.5, 0.2)] { c.circle(sun.x, sun.y, Int(Double(sun.r) * k), C(0xFFE0A0, a)) }
        c.circle(sun.x, sun.y, sun.r, C(0xFFE8B0)); c.circle(sun.x - sun.r / 5, sun.y - sun.r / 5, sun.r * 3 / 4, C(0xFFF6DC))
        // High streaks of cloud, rose underneath.
        let wisps: [(x: Int, y: Int, len: Int)] = tall
            ? [(14, 18, 40), (70, 12, 46), (42, 30, 34), (88, 36, 30), (8, 44, 26)]
            : [(10, 16, 28), (46, 8, 22), (70, 26, 18)]
        for (k, w) in wisps.enumerated() {
            let col = k % 2 == 0 ? C(0xF6C8D0, 0.6) : C(0xE8A8C0, 0.5)
            Scenes.wisp(c, c.w * w.x / 100, g * w.y / 100, w.len * s * (tall ? 3 : 2), col, s: s * (tall ? 2 : 1))
        }
        let u = PixelCanvas(f.w, f.h)
        eterniaAvionCity(u)
        eterniaS4BlowUp(c, u, f.x, f.y, f.q)
        // The terrace: rose-grey flags, mid-dark and plain.
        c.ground(g, C(0x4E4058), edge: C(0x7A6886), speck: C(0x3E3248), seed: 21)
    }

    /// The city, one pixel to a unit, the terrace's edge along the bottom row.
    static func eterniaAvionCity(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let marble = avionMarble, roof = avionRoof
        let gold = C(0xE8B848), goldL = C(0xFFE08A), window = C(0x2C3466)

        /// A bank of cloud: billows along `base`, lit pink-white on top, lavender, then shadowed down to `bottom`.
        func clouds(base: Int, bottom: Int, size: Double, seed: Int, tones: [Px]) {
            for x in 0..<u.w {
                let a = abs(sin(Double(x) / (5 * size) + Double(seed)))
                let b = abs(sin(Double(x) / (2.7 * size) + Double(seed) * 2.1))
                let h = Int((a * 4 + b * 2) * size / 2 + noise(x / 3 + seed) * 1.2)
                let y0 = base - h
                for y in y0..<bottom {
                    let d = y - y0
                    let i = d == 0 ? 0 : d < 2 ? 1 : d < 4 ? 2 : min(tones.count - 1, 3 + (d - 4) / 2)
                    u.px(x, y, tones[i])
                }
            }
        }
        let farTones = avionFarClouds
        let nearTones = [C(0xFFF0F2), C(0xF0D2E0), C(0xCCB0D2), C(0xA48CBC), C(0x847098), C(0x6A5A86), C(0x56497A), C(0x4A3E6C)]
        let paleWall = avionPaleWall, paleRoof = avionPaleRoof

        // Islands of cloud high up on the screen saver, towers standing on them, pale with distance.
        avionIsles(u)

        // The far cloud sea, and pale towers standing on it in little clusters with open sky between, each cluster
        // a tall tower among shorter ones (not a row of posts all alike).
        clouds(base: B - 22, bottom: B, size: 1.4, seed: 3, tones: farTones)
        var gx = Int(noise(950) * 10)
        var gi = 0
        while gx < u.w {
            let n = 2 + Int(noise(gi * 5 + 951) * 3)        // two to four towers in the cluster
            let tallest = Int(noise(gi * 5 + 952) * Double(n))
            var x = gx
            for j in 0..<n {
                let tw = 3 + Int(noise(gi * 9 + j + 953) * 3)
                let h = j == tallest ? 18 + Int(noise(gi * 9 + j + 954) * 12) : 4 + Int(noise(gi * 9 + j + 955) * 10)
                if abs(x - cx) > 62 {
                    avionTower(u, x, tw, B - 24 - h, 3 + tw / 2 + (j == tallest ? 2 : 0), B - 18,
                               wall: paleWall, roof: paleRoof, gold: C(0xF0D8A0), window: C(0x9888B4))
                }
                x += tw + 1 + Int(noise(gi * 9 + j + 956) * 3)
            }
            gx = x + 12 + Int(noise(gi * 5 + 957) * 22)
            gi += 1
        }

        // The city: the towers, then the skybridges between them.
        let towers = avionTowers(cx, top)
        for tw in towers {
            avionTower(u, tw.x, tw.w, tw.roof, tw.rh, B - 12, wall: marble, roof: roof, gold: gold, window: window)
            let wallTop = tw.roof + tw.rh
            if tw.extra == 1 {
                // A perch: a round platform jutting out, a gold rim along its edge.
                let py = wallTop + 12, pw = tw.w / 2
                u.ellipse(tw.x, py, pw + 5, 1, marble[2]); u.rect(tw.x - pw - 5, py, tw.w + 11, 1, marble[3])
                u.rect(tw.x - pw - 4, py + 1, tw.w + 9, 1, gold); u.rect(tw.x - pw - 2, py + 2, tw.w + 5, 1, marble[0])
                for k in [-1, 1] { u.px(tw.x + k * (pw + 3), py + 3, marble[0]); u.px(tw.x + k * (pw + 2), py + 4, marble[0]) }
            }
            if tw.extra == 2 {
                // Wings carved in white stone, spread from its shoulders and sweeping up.
                let span = tw.w + 4, y0 = wallTop + 6
                for side in [-1.0, 1.0] {
                    for i in 0..<5 {
                        let x0 = Double(tw.x) + side * (Double(tw.w) / 2 + 0.5), yy = Double(y0 + i)
                        let len = Double(span - i * 2)
                        let x1 = x0 + side * len, y1 = yy - Double(span) * 0.55 + Double(i) * 1.6
                        eterniaS4Line(u, x0, yy + 1, x1, y1 + 1, marble[0])
                        eterniaS4Line(u, x0, yy, x1, y1, marble[i == 0 ? 3 : 2])
                        u.px(Int(x1.rounded()), Int(y1.rounded()), i == 0 ? goldL : marble[3])
                    }
                }
            }
        }
        /// A skybridge from one tower's side to another's at row `y`: a white deck with a gold rail, an arch under
        /// it springing from both towers.
        func bridge(_ a: Int, _ b: Int, _ y: Int) {
            let ta = towers[a], tb = towers[b]
            let x0 = ta.x + ta.w / 2 + 1, x1 = tb.x - (tb.w - 1) / 2 - 1
            guard x1 > x0 else { return }
            for x in x0...x1 {
                let k = Double(x - x0) / Double(max(1, x1 - x0))
                let under = y + 2 + Int((4 * (1 - sin(k * .pi))).rounded())
                u.rect(x, y + 2, 1, under - y - 1, marble[1]); u.px(x, under, marble[0])
                u.px(x, y, marble[3]); u.px(x, y + 1, marble[2])
                if x % 2 == 0 { u.px(x, y - 1, gold) }
            }
            u.rect(x0, y - 2, 1, 1, gold); u.rect(x1, y - 2, 1, 1, gold)
        }
        bridge(4, 6, top + 30); bridge(6, 5, top + 26); bridge(0, 4, top + 36); bridge(5, 1, top + 34)

        // The near clouds round the city's feet, their undersides in shadow down to the terrace.
        clouds(base: B - 14, bottom: B, size: 2.0, seed: 11, tones: nearTones)
        // The balustrade along the terrace's edge: a rail of rose-grey stone on squat balusters.
        u.rect(0, B - 6, u.w, 1, C(0xA492B0)); u.rect(0, B - 5, u.w, 1, C(0x806E92))
        for x in stride(from: 0, to: u.w, by: 4) {
            u.rect(x + 1, B - 4, 2, 4, C(0x6A5A7E)); u.px(x + 1, B - 4, C(0x8A7AA0)); u.px(x + 1, B - 2, C(0x7A6A90))
        }
        u.rect(0, B - 1, u.w, 1, C(0x4E4060))
    }

    /// The islands of cloud high over Avion on the screen saver (none in the window), towers standing on them, pale
    /// with distance; also the mask the drifting clouds pass behind.
    fileprivate static func avionIsles(_ u: PixelCanvas) {
        let cx = u.w / 2, top = u.h - 56
        guard top >= 30 else { return }
        // Each island's row, low enough that its towers stay inside the picture.
        func row(_ k: Int) -> Int { 26 + (top - 32) * k / 100 }
        let isles: [(dx: Int, y: Int, n: Int)] = [(-58, row(55), 3), (52, row(20), 2), (6, row(95), 2),
                                                  (-22, row(0), 1), (80, row(80), 1)]
        for (i, isle) in isles.enumerated() {
            let x = cx + isle.dx, y = isle.y
            for j in 0..<isle.n {
                let tx = x - (isle.n - 1) * 4 + j * 8, th = 8 + Int(noise(i * 9 + j) * 8)
                avionTower(u, tx, 3 + j % 2, y - th - 4, 4, y, wall: avionPaleWall, roof: avionPaleRoof,
                           gold: C(0xF0D8A0), window: C(0x9888B4))
            }
            for k in 0..<5 {
                let px = x - 10 + k * 5, pr = 3 + (k % 2) * 2
                u.ellipse(px, y + 1, pr + 1, pr / 2 + 1, avionFarClouds[1]); u.ellipse(px - 1, y, pr, pr / 2, avionFarClouds[0])
            }
            u.ellipse(x, y + 3, 13, 2, avionFarClouds[3])
        }
    }

    /// A tower of Avion: `w` wide round `x`, its cone roof from `roofTop` down `rh` rows, the wall down to `foot`;
    /// marble lit from the left, arched windows in rows, a gold band under the roof and a gold spike on top.
    private static func avionTower(_ u: PixelCanvas, _ x: Int, _ w: Int, _ roofTop: Int, _ rh: Int, _ foot: Int,
                                   wall: [Px], roof: [Px], gold: Px, window: Px) {
        let x0 = x - w / 2, wallTop = roofTop + rh
        guard foot > wallTop else { return }
        for y in wallTop..<foot {
            for xx in x0..<(x0 + w) {
                let k = Double(xx - x0) / Double(max(1, w - 1))
                u.px(xx, y, wall[k < 0.3 ? 3 : k < 0.7 ? 2 : k < 0.9 ? 1 : 0])
            }
        }
        // The windows, storey by storey: on the wider towers a pair of arched windows, then a single tall one with
        // a balcony, in turn; on the slim ones a lancet now and then. A sill under each, a string course between the
        // storeys, and a few windows lit warm by the dawn.
        let pair = w >= 8 ? [x0 + w / 3 - 1, x0 + w * 2 / 3] : [x0 + w / 2]
        let lit = C(0xFFD890)
        for (n, y) in stride(from: wallTop + 4, to: foot - 4, by: 6).enumerated() {
            let single = w < 8 || n % 2 == 1
            let cols = single ? [x0 + (w - 1) / 2] : pair
            if w < 8 && n % 2 == 1 { continue }
            for (j, wx) in cols.enumerated() {
                let glow = noise(x * 13 + n * 7 + j) > 0.8
                let pane = glow ? lit : window, tall = single && w >= 8 ? 4 : 3
                let ww = w >= 9 && !single ? 2 : 1
                u.rect(wx - (ww - 1), y + 1, ww, tall - 1, pane); u.px(wx, y, pane)
                if ww == 2 { u.px(wx - 1, y, wall[1]) }
                u.rect(wx - ww, y + tall, ww + 2, 1, wall[3])
                if single && w >= 8 {
                    // A little balcony under the tall window, its rail gold.
                    u.rect(wx - 2, y + tall + 1, 5, 1, wall[1]); u.rect(wx - 2, y + tall, 5, 1, gold)
                }
            }
            if n > 0 && w >= 6 { u.rect(x0, y - 2, w, 1, wall[1]); u.px(x0, y - 2, wall[2]) }
        }
        // The gold band, and the cone roof overhanging it a little, lit on the left.
        u.rect(x0 - 1, wallTop, w + 2, 1, gold); u.rect(x0, wallTop + 1, w, 1, wall[0])
        let even = w % 2 == 0 ? 1 : 0
        for y in roofTop..<wallTop {
            let k = Double(y - roofTop + 1) / Double(rh)
            let hw = max(even, Int((Double(w + 2) / 2 * k).rounded()))
            for xx in (x - hw)...(x + hw - even) {
                let n = Double(xx - (x - hw)) / Double(max(1, hw * 2))
                u.px(xx, y, roof[n < 0.3 ? 3 : n < 0.65 ? 2 : n < 0.9 ? 1 : 0])
            }
        }
        u.rect(x - even, roofTop - 3, 1, 3, gold); u.px(x - even, roofTop - 4, C(0xFFF0C0))
    }

    /// Avion's life: little clouds drifting slowly past between the towers, blue pennants fluttering from the great
    /// tower, and now and then a bird-man gliding across the sky on spread blue wings (two of them on the screen saver).
    static func eterniaAvionLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaS4Frame(c, g), q = f.q, tall = isTall(c)
        let top = f.h - 56, cx = f.w / 2
        // The pennants: long and blue, hanging from the great tower's gold band, a ripple running down them.
        let tw = avionTowers(cx, top)[6]
        let u = PixelCanvas(f.w, f.h)
        for (i, px) in [tw.x - tw.w / 2 - 1, tw.x + tw.w / 2].enumerated() {
            let y0 = tw.roof + tw.rh + 1, out = i == 0 ? -1 : 1
            for j in 0..<12 {
                let sway = Int((sin(t * 2.2 - Double(j) * 0.6 + Double(i)) * Double(j) / 10).rounded())
                let x = px + out * max(0, sway)
                u.px(x, y0 + j, j > 9 ? C(0xE8B848) : C(0x3A6ACA)); u.px(x + out, y0 + j, j > 9 ? C(0xA87A20) : C(0x2A4A9A))
            }
        }
        eterniaS4BlowUp(c, u, f.x, f.y, q)
        // Little clouds drifting right, slowly, in the open sky over the city (never across the towers). On the
        // screen saver they pass behind the islands of cloud and their towers: drawn apart, then laid on only where
        // no island is.
        let lane = f.y + (top >= 30 ? 0 : 2 * q)
        let laneH = max(2, top - (top >= 30 ? 10 : 4))
        let isles = PixelCanvas(f.w, f.h)
        Scenes.avionIsles(isles)
        let sky = top >= 30 ? PixelCanvas(c.w, c.h) : c
        for k in 0..<(top >= 30 ? 6 : 4) {
            let span = c.w + 60 * q
            let start = Int(noise(k * 7 + 70) * Double(span)), drift = Int(t * Double(q) * (1.2 + Double(k % 3) * 0.5))
            let x = (start + drift) % span - 30 * q
            let y = lane + Int(noise(k * 7 + 71) * Double(laneH)) * q
            let r = (top >= 30 ? 3 + Int(noise(k * 7 + 72) * 3) : 2) * q
            sky.ellipse(x + r, y + r / 3, r * 2, r * 2 / 3, C(0xE0B8D4, 0.7))
            sky.ellipse(x, y, r * 3, r, C(0xFCE8F0, 0.75)); sky.ellipse(x - r, y - r / 2, r * 3 / 2, r, C(0xFFF6F8, 0.8))
        }
        if sky !== c {
            for y in 0..<min(c.h, f.y + f.h * q) {
                for x in 0..<c.w where sky.buf[(y * c.w + x) * 4 + 3] > 0 {
                    let ux = (x - f.x) / q, uy = (y - f.y) / q
                    if ux >= 0, uy >= 0, ux < f.w, uy < f.h, isles.buf[(uy * f.w + ux) * 4 + 3] > 0 { continue }
                    c.px(x, y, unpremultiplied(sky, (y * c.w + x) * 4))
                }
            }
        }
        // The bird-men: big enough to read as people, not planes. Wings swept up in a V, the long dark flight
        // feathers fanned apart at their tips like fingers, paler coverts at their roots; between them a grey body
        // hanging under the shoulders, the red straps of a harness, a head of white hair round a grey face, legs
        // trailing. Now and then a beat of the wings, swept down.
        let glide = ["F.F.................F.F", "FFFF...............FFFF", ".WWWW.............WWWW.", "..WWWWw.........wWWWW..",
                     "...wWWWww.HHH.wwWWWw...", ".....wwWWwHGHwWWww.....", ".......wwRBBBRww.......", "..........BBB..........",
                     "..........B.B..........", "..........L.L.........."]
        let flap = [".......................", "..........HHH..........", ".....wwWWwHGHwWWww.....", "..wWWWWWWRBBBRWWWWWWw..",
                    ".WWWWw....BBB....wWWWW.", "FWWw......BBB......wWWF", "FF........B.B........FF", "F.F.......L.L.......F.F"]
        let pal: [Character: Px] = ["H": C(0xF4F4FA), "G": C(0x9A9CAC), "B": C(0x6A6C7A), "R": C(0xC83A30), "F": C(0x1E3A84),
                                    "W": C(0x2E5EB8), "w": C(0x7AA2E4), "L": C(0x3A3A48)]
        for b in 0..<(tall ? 2 : 1) {
            let period = 19.0 + Double(b) * 7
            let phase = ((t + Double(b) * 9) / period).truncatingRemainder(dividingBy: 1)
            guard phase < 0.6 else { continue }
            let bs = q + 1
            let x = -24 * bs + Int(phase / 0.6 * Double(c.w + 48 * bs))
            let base = tall ? f.y + (top * (b == 0 ? 45 : 22) / 100) * q : f.y + (top + 4) * q
            let y = base + Int((sin(t * 1.1 + Double(b)) * Double(2 * q)).rounded())
            let rows = (Int(t * 5) % 9 < 2) ? flap : glide
            eterniaS4Pattern(c, b % 2 == 0 ? x : c.w - x, y, bs, b % 2 == 0 ? rows : rows.map { String($0.reversed()) }, pal)
        }
    }
}
