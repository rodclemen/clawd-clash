import Foundation

// Places: the Men of Letters' Bunker, home base. Each place is a `Place` in the dictionary below (its name, the tint of
// the window's card area under it, its still picture and what moves there) and its drawing in an extension of
// `Scenes`. Check them with `build/preview place out.png <key>`, at window size and at screen-saver size.
//
// The universe's palette: rust, amber, Impala black, dusty denim blue and the odd motel-sign neon. The floor and the
// band just above it stay plain and mid-to-dark so the crew's outlines and names read; the busy detail goes higher up
// and at the sides; props keep their size in `Scenes.unit(g)` steps.

let huntScenes1: [Location: Place] = [
    .huntBunker: Place(name: "The Bunker", panel: 0x1C1610, still: Scenes.huntBunker, moving: Scenes.huntBunkerLife),
]

// MARK: - The Bunker

/// The world on the map table's glass, a row a unit, each dot two units wide: the Americas on the left, Europe and
/// Africa in the middle, Asia and Australia on the right.
private let huntBunkerMap = [
    "..#########........###..##########....",
    "...#######........####.############...",
    "....#####.........###...##########....",
    "......##..........####....######..#...",
    ".......###.........###......#....##...",
    "........##..........#............###..",
]

extension Scenes {
    /// Where things stand in the war room, shared by the still picture and the moving layer so they line up: the
    /// wainscot's top, the map table (its middle, half its width and its top), the wall lamps' row and x positions,
    /// and the foot of the iron stairs.
    static func huntBunkerFrame(_ c: PixelCanvas, _ g: Int) -> (wainscot: Int, table: (x: Int, half: Int, top: Int),
                                                               lampY: Int, lamps: [Int], stairs: Int) {
        let s = unit(g)
        let lamps = [c.w * 34 / 100, c.w * 62 / 100]
        // On the screen saver the stairs climb all the way to the door's landing, two units across for every three up.
        let stairs = isTall(c) ? max(c.w * 66 / 100, c.w - 34 * s - (g - huntBunkerLanding(g)) * 2 / 3) : c.w * 76 / 100
        return (g - 9 * s, (x: c.w * 48 / 100, half: 40 * s, top: g - 20 * s), g - 27 * s, lamps, stairs)
    }

    /// The screen saver's landing at the top of the stairs, and the balcony's floor.
    static func huntBunkerLanding(_ g: Int) -> Int { g * 30 / 100 }
    static func huntBunkerBalcony(_ g: Int) -> Int { g * 46 / 100 }

    /// The Bunker's war room, the Men of Letters' 1950s headquarters under a Kansas hillside: walls of dark walnut
    /// panelling under a brick vault, art deco lamps in brass fans along the wall, the long map table in the middle
    /// with the world lit up through its glass top, shelves of the order's books on the left, and on the right the
    /// iron stairs climbing to the door. On the screen saver, the shelves rise two storeys to a balcony with a brass
    /// rail, green-shaded lamps hang on chains from the vault, and the stairs reach the steel door at the top.
    static func huntBunker(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntBunkerFrame(c, g), tall = isTall(c)
        let brick = C(0x3E2A1E), brickD = C(0x2E1E14)
        let wood = C(0x4A3020), woodD = C(0x2E1C12), woodL = C(0x6A4630)
        let brass = C(0xC8A04A), brassD = C(0x8A6A2A)
        // The vault above the panelling: dark brick in courses, warmer near the lamps' level.
        c.gradient(0, f.wainscot, C(0x1C140E), brick, bands: 6)
        for (row, y) in stride(from: 0, to: f.wainscot - 4 * s, by: 3 * s).enumerated() {
            c.rect(0, y + 2 * s, c.w, max(1, s / 2), brickD)
            for x in stride(from: (row % 2) * 4 * s, to: c.w, by: 8 * s) { c.rect(x, y, max(1, s / 2), 2 * s, brickD) }
        }
        // Upright walnut pilasters between the bays, each lit on its left.
        for x in stride(from: 14 * s, to: c.w, by: 56 * s) {
            c.rect(x, 0, 5 * s, f.wainscot, wood); c.rect(x, 0, s, f.wainscot, woodL); c.rect(x + 4 * s, 0, s, f.wainscot, woodD)
        }
        // The library on the left: tall cases of the order's books, leather spines in deep reds, greens and browns,
        // gilt on some, a shelf lit along each front.
        let shelfW = c.w * 26 / 100, shelfTop = tall ? g * 14 / 100 : 0
        let tones = [C(0x6A2A1E), C(0x2E3E2A), C(0x5A4A2A), C(0x4A1E1A), C(0x7A5A2E), C(0x2A3446)]
        c.rect(0, shelfTop, shelfW, f.wainscot - shelfTop, woodD)
        let pitch = 9 * s
        for (row, base) in stride(from: f.wainscot - 2 * s, to: shelfTop + 6 * s, by: -pitch).enumerated() {
            var x = 2 * s, i = row * 71 + 5
            while x < shelfW - 3 * s {
                let bw = (2 + Int(noise(i) * 2.6)) * s, bh = (5 + Int(noise(i + 1) * 2.4)) * s
                let col = tones[Int(noise(i + 2) * Double(tones.count)) % tones.count]
                c.rect(x, base - bh, min(bw, shelfW - 3 * s - x), bh, col); c.rect(x, base - bh, max(1, s / 2), bh, col.alpha(0.7))
                if noise(i + 3) > 0.8 { c.rect(x, base - bh + s, min(bw, shelfW - 3 * s - x), max(1, s / 2), brass.alpha(0.8)) }
                x += bw + (noise(i + 4) > 0.85 ? 2 * s : 0); i += 13
            }
            c.rect(0, base, shelfW, s, woodL); c.rect(0, base + s, shelfW, s, woodD)
        }
        c.rect(shelfW, shelfTop, 2 * s, f.wainscot - shelfTop, wood); c.rect(shelfW + s, shelfTop, s, f.wainscot - shelfTop, woodD)
        // On the screen saver: the balcony across the shelves with its brass rail, and the vault's ceiling ribs.
        if tall {
            let bal = huntBunkerBalcony(g), end = c.w * 64 / 100
            // Arched doorways off the balcony into the rest of the Bunker, dark corridors with a lamp glowing far down
            // each, and an art deco fan lamp between each pair.
            for x in stride(from: shelfW + 16 * s, to: end - 20 * s, by: 46 * s) {
                let dh = 26 * s
                c.rect(x - s, bal - dh - s, 18 * s, dh + s, woodD)
                c.rect(x, bal - dh + 8 * s, 16 * s, dh - 8 * s, C(0x120C08)); c.circle(x + 8 * s, bal - dh + 8 * s, 8 * s, C(0x120C08))
                c.rect(x + 7 * s, bal - 12 * s, 2 * s, 2 * s, C(0xE8B860, 0.6))
                let lx = x + 31 * s
                if lx < end - 6 * s {
                    for k in 0..<4 { let w = (2 + k * 2) * s; c.rect(lx - w / 2, bal - 20 * s - k * s, w, s, k % 2 == 0 ? C(0xF4DCA0) : brass) }
                    c.rect(lx - s / 2, bal - 20 * s, max(1, s), 3 * s, brassD)
                }
            }
            // The balcony's floor, deep enough to stand on, a lit edge and brackets under it, and its brass rail.
            c.rect(0, bal, end, 5 * s, woodD); c.rect(0, bal, end, s, woodL); c.rect(0, bal + 4 * s, end, s, C(0x1A100A))
            for x in stride(from: 10 * s, to: end, by: 28 * s) {
                for k in 0..<5 { c.rect(x + k * s, bal + 5 * s, (5 - k) * s, s, woodD) }
            }
            c.rect(0, bal - 8 * s, end, s, brass); c.rect(0, bal - 7 * s, end, max(1, s / 2), brassD)
            for x in stride(from: 2 * s, to: end, by: 6 * s) { c.rect(x, bal - 7 * s, max(1, s / 2), 7 * s, brassD) }
            // Below the balcony, over the map table: the Men of Letters' emblem in brass, a ring round an eight-rayed
            // star with the eye of knowledge in its middle.
            let ex = c.w * 48 / 100, ey = (bal + f.lampY) / 2 - 4 * s, er = 13 * s
            c.circle(ex, ey, er, brassD); c.circle(ex, ey, er - s, brass); c.circle(ex, ey, er - 3 * s, C(0x2A1C12))
            for k in 0..<8 {
                let a = Double(k) * .pi / 4, len = Double(k % 2 == 0 ? er - 3 * s : er - 6 * s)
                c.glowLine(Double(ex), Double(ey), Double(ex) + cos(a) * len, Double(ey) + sin(a) * len,
                           core: brass, glow: C(0, 0), coreR: Double(s) * 0.7, glowR: Double(s) * 0.8)
            }
            c.ellipse(ex, ey, 4 * s, 2 * s, C(0xF0E2B0)); c.circle(ex, ey, s, C(0x2A1C12))
            for x in stride(from: 0, to: c.w, by: 40 * s) {
                c.rect(x, 0, 3 * s, g * 12 / 100, woodD); c.rect(x, 0, s, g * 12 / 100, woodL)
            }
            c.rect(0, g * 12 / 100, c.w, 2 * s, woodD)
        }
        // The panelling round the room below: walnut panels in frames, a rail along the top lit on its upper edge.
        c.rect(0, f.wainscot, c.w, g - f.wainscot, wood)
        for x in stride(from: 3 * s, to: c.w, by: 18 * s) {
            c.rect(x, f.wainscot + 2 * s, 14 * s, g - f.wainscot - 3 * s, woodD)
            c.rect(x + s, f.wainscot + 3 * s, 12 * s, g - f.wainscot - 5 * s, wood)
            c.rect(x + s, f.wainscot + 3 * s, 12 * s, max(1, s / 2), woodL)
        }
        c.rect(0, f.wainscot, c.w, s, woodL); c.rect(0, f.wainscot + s, c.w, s, woodD)
        // The wall lamps: art deco fans of brass and frosted glass on short brackets, their light washing the brick.
        for x in f.lamps {
            for r in stride(from: 16 * s, to: 2 * s, by: -2 * s) {
                c.ellipse(x, f.lampY + 2 * s, r * 3 / 2, r, C(0xE8A84A, 0.035))
            }
            c.rect(x - s / 2, f.lampY + 2 * s, max(1, s), 4 * s, brassD)
            for k in 0..<5 {   // the fan, widening upwards in bands of glass and brass
                let w = (2 + k * 2) * s
                c.rect(x - w / 2, f.lampY + 2 * s - k * s, w, s, k % 2 == 0 ? C(0xF4DCA0) : brass)
            }
        }
        // The iron stairs on the right, climbing away up the wall: dark treads lit on their noses, the stringer under
        // them, a railing of thin balusters. In the window they leave the top of the picture; on the screen saver they
        // reach a landing and the steel door, its wheel and rivets.
        let iron = C(0x2A2A2E), ironL = C(0x4E4E56), step = 3 * s, run = tall ? 2 * s : 3 * s
        var sx = f.stairs, sy = g
        let landing = tall ? huntBunkerLanding(g) : -10 * s
        while sy > max(0, landing) && sx < c.w {
            c.rect(sx, sy - step, 6 * s, s, ironL); c.rect(sx, sy - step + s, 6 * s, step - s, iron)
            c.rect(sx + 2 * s, sy - step - 9 * s, max(1, s / 2), 9 * s, iron)
            sx += run; sy -= step
        }
        c.glowLine(Double(f.stairs + 2 * s), Double(g - 12 * s), Double(sx + 2 * s), Double(sy - 9 * s),
                   core: ironL, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        if tall && sx < c.w {
            c.rect(sx - 4 * s, landing, c.w - sx + 4 * s, 2 * s, ironL); c.rect(sx - 4 * s, landing + 2 * s, c.w - sx + 4 * s, s, iron)
            let dx = min(c.w - 26 * s, sx + 6 * s), dh = 30 * s
            c.rect(dx, landing - dh, 20 * s, dh, C(0x5A5E66)); c.rect(dx, landing - dh, 20 * s, s, C(0x8A8E96))
            c.rect(dx + 19 * s, landing - dh, s, dh, C(0x3A3C42))
            c.circle(dx + 10 * s, landing - dh / 2, 5 * s, C(0x3A3C42)); c.circle(dx + 10 * s, landing - dh / 2, 3 * s, C(0x5A5E66))
            for y in stride(from: landing - dh + 3 * s, to: landing - 2 * s, by: 5 * s) {
                c.rect(dx + 2 * s, y, s, s, C(0x8A8E96)); c.rect(dx + 17 * s, y, s, s, C(0x8A8E96))
            }
        }
        // On the screen saver, green-shaded banker's lamps hanging on chains over the map table.
        if tall {
            for k in [-1, 1] {
                let x = f.table.x + k * f.table.half * 2 / 3, y = f.table.top - 36 * s
                c.rect(x, huntBunkerBalcony(g) + 5 * s, max(1, s / 2), y - huntBunkerBalcony(g) - 5 * s, brassD)
                c.ellipse(x, y + 4 * s, 12 * s, 3 * s, C(0xF4E2A8, 0.08))
                c.rect(x - 2 * s, y - s, 4 * s, s, brassD)
                c.rect(x - 6 * s, y, 12 * s, 3 * s, C(0x2E5A3A)); c.rect(x - 6 * s, y, 12 * s, s, C(0x4A7A52)); c.rect(x - 7 * s, y + 2 * s, 14 * s, s, C(0x22442C))
                c.rect(x - 5 * s, y + 3 * s, 10 * s, s, C(0xF4E2A8))
            }
        }
        // The map table: long and heavy walnut, its glass top lit from inside, the world on it in warm amber, the
        // light spilling up onto the wall behind it. Its legs stand on the floor; the crew stands in front of it.
        let t = f.table
        for r in stride(from: 30 * s, to: 4 * s, by: -3 * s) {
            c.ellipse(t.x, t.top, t.half + r, r / 2, C(0xF0D890, 0.035))
        }
        // The glass, seen from a little above: lit cream, brightest along the far edge, a faint grid of latitude and
        // longitude lines, and the world map in amber.
        c.rect(t.x - t.half, t.top, 2 * t.half, 8 * s, C(0xE4CE92))
        c.rect(t.x - t.half, t.top, 2 * t.half, s, C(0xFFF2C8))
        for y in [t.top + 3 * s, t.top + 6 * s] { c.rect(t.x - t.half, y, 2 * t.half, max(1, s / 2), C(0xD2B97C)) }
        for x in stride(from: t.x - t.half + 7 * s, to: t.x + t.half, by: 10 * s) { c.rect(x, t.top + s, max(1, s / 2), 7 * s, C(0xD2B97C)) }
        let mapW = huntBunkerMap[0].count
        for (v, row) in huntBunkerMap.enumerated() {
            for (u, ch) in row.enumerated() where ch == "#" {
                c.rect(t.x + (2 * u - mapW) * s, t.top + (v + 1) * s, 2 * s, s, C(0xB08A44))
            }
        }
        // The heavy rim round the glass, lit along its top, the apron under it and three square legs.
        c.rect(t.x - t.half - 2 * s, t.top - s, 2 * t.half + 4 * s, s, woodL)
        c.rect(t.x - t.half - 2 * s, t.top, 2 * s, 8 * s, wood); c.rect(t.x + t.half, t.top, 2 * s, 8 * s, woodD)
        c.rect(t.x - t.half - 2 * s, t.top + 8 * s, 2 * t.half + 4 * s, 2 * s, wood)
        c.rect(t.x - t.half - 2 * s, t.top + 8 * s, 2 * t.half + 4 * s, max(1, s / 2), woodL)
        c.rect(t.x - t.half - 2 * s, t.top + 10 * s, 2 * t.half + 4 * s, s, woodD)
        for x in [t.x - t.half, t.x - 2 * s, t.x + t.half - 4 * s] {
            c.rect(x, t.top + 11 * s, 4 * s, g - t.top - 11 * s, woodD); c.rect(x, t.top + 11 * s, max(1, s / 2), g - t.top - 11 * s, wood)
        }
        // The floor: dark polished tile in big squares, plain enough that the crew reads on it.
        c.ground(g, C(0x3A2E26), edge: C(0x54443A), speck: C(0x30261E), seed: 41)
        for x in stride(from: 0, to: c.w, by: 24 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x30261E)) }
    }

    /// The war room's life: the map table's little lights blinking where the order's cases are, and the left wall
    /// lamp's bulb flickering now and then, as old wiring does.
    static func huntBunkerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntBunkerFrame(c, g)
        let pins = [(-30, 2, C(0xFF4A3A)), (-24, 4, C(0xFFD04A)), (-6, 2, C(0xFF4A3A)), (8, 3, C(0x6AD0FF)),
                    (18, 2, C(0xFFD04A)), (-20, 6, C(0x6AD0FF)), (30, 6, C(0xFF4A3A))]
        for (k, (u, v, col)) in pins.enumerated() {
            let on = sin(t * (1.3 + Double(k) * 0.37) + Double(k) * 1.7) > 0.1
            if on { c.rect(f.table.x + u * s, f.table.top + v * s, max(1, s), max(1, s), col) }
        }
        // The flicker: most of the time steady; for a few moments every dozen seconds, the bulb stutters.
        let phase = t.truncatingRemainder(dividingBy: 11.0)
        if phase > 9.6 && phase < 10.4 && Int(t * 14) % 3 != 0 {
            let x = f.lamps[0]
            c.ellipse(x, f.lampY + 2 * s, 8 * s, 5 * s, C(0x0C0806, 0.35))
        }
    }
}
