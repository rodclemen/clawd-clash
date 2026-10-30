import Foundation

// Places, a few to a file (see CrawlScenes1.swift for the rules): the First Floor tunnels, Mordecai's Tutorial Guild,
// the Hoarder's lair, the Juicer's gym.

let crawlScenes2: [Location: Place] = [
    .crawlCorridor: Place(name: "First Floor tunnels", panel: 0x16181E, still: Scenes.crawlCorridor, moving: Scenes.crawlCorridorLife),
    .crawlGuild: Place(name: "Mordecai's Tutorial Guild", panel: 0x141C1E, still: Scenes.crawlGuild, moving: Scenes.crawlGuildLife),
    .crawlHoard: Place(name: "The Hoarder's lair", panel: 0x1C1612, still: Scenes.crawlHoard, moving: Scenes.crawlHoardLife),
    .crawlGym: Place(name: "The Juicer's gym", panel: 0x1A1216, still: Scenes.crawlGym, moving: Scenes.crawlGymLife),
]

/// Draws `rows` with each `#` a square `s` pixels wide: the spray-painted tag, the gym's emblem.
private func crawlStamp(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ col: Px, _ s: Int) {
    for (dy, row) in rows.enumerated() {
        for (dx, ch) in row.enumerated() where ch == "#" { c.rect(x + dx * s, y + dy * s, s, s, col) }
    }
}

// MARK: - First Floor tunnels

extension Scenes {
    /// Where things stand in the tunnels, shared by the still picture and the moving layer so they line up: the top of
    /// the plain foundation course, the torches (where each flame sits), the System box, and (on the screen saver) the
    /// line the vault's arches spring from.
    static func crawlCorridorFrame(_ c: PixelCanvas, _ g: Int) -> (band: Int, torches: [(x: Int, y: Int)],
                                                                   box: (x: Int, y: Int, w: Int, h: Int), spring: Int) {
        let s = unit(g)
        let torches = [12, 46, 70].map { (x: c.w * $0 / 100, y: g - 32 * s) }
        let bw = crawlTextWidth("FLOOR 1", scale: s) + 6 * s
        let box = (x: c.w * 58 / 100 - bw / 2, y: g - 52 * s, w: bw, h: 11 * s)
        return (g - 10 * s, torches, box, isTall(c) ? g - 72 * s : -1)
    }

    /// The First Floor tunnels: a bare corridor of the dungeon, rough blue-grey blocks of uneven size laid in courses,
    /// lit from the front left, over a plain foundation course and dark flagstones. Torches burn in iron sconces, a
    /// warm pool of light round each; a goblin has sprayed his tag on the wall (a grinning green face and GOB!); on
    /// the right a side passage opens under a round arch, dark but not black, a far torch glowing faintly inside. On
    /// the screen saver the walls rise into the vaulted roof: round arches on corbels, ribs meeting at a ridge, roots
    /// hanging through the cracks and an iron cage on a chain.
    static func crawlCorridor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlCorridorFrame(c, g)
        let stone = C(0x545866), stoneM = C(0x4C505D), stoneD = C(0x3A3D49), stoneL = C(0x6A6E7C), mortar = C(0x2E3039)

        // The walls: rough blocks in courses, each a little different in width and tone, lit along the top, a
        // shadow along the bottom, a corner chipped off here and there and the odd crack.
        c.rect(0, 0, c.w, f.band, mortar)
        let course = 8 * s
        var row = 0
        while f.band - row * course > 0 {
            let y = f.band - (row + 1) * course
            var x = -Int(noise(row * 13 + 5) * Double(12 * s)), k = 0
            while x < c.w {
                let w = (12 + Int(noise(row * 31 + k * 7) * 12)) * s
                let n = noise(row * 17 + k * 3)
                c.rect(x + s, y + s, w - s, course - s, n > 0.5 ? stone : stoneM)
                c.rect(x + s, y + s, w - s, s, stoneL)
                c.rect(x + s, y + course - s, w - s, s, stoneD)
                if n > 0.75 { c.rect(x + s, y + s, s, s, mortar) }
                if n < 0.12 {
                    let cx = x + w / 2
                    for i in 0..<3 { c.rect(cx + i * s, y + (2 + i) * s, s, s, stoneD) }
                }
                x += w; k += 1
            }
            row += 1
        }

        // On the screen saver: the vaulted roof.
        if tall { crawlCorridorVault(c, g, f.spring) }

        // The foundation course along the floor: big plain blocks, darker, so the crew's outlines read on it.
        c.rect(0, f.band, c.w, g - f.band, C(0x41444E))
        c.rect(0, f.band, c.w, s, C(0x5A5E6A))
        for x in stride(from: 9 * s, to: c.w, by: 30 * s) { c.rect(x, f.band, s, g - f.band, mortar) }

        // The goblin's tag: a grinning face with pointed ears in green spray paint, GOB! beside it, the paint
        // misted round the edges and dripping.
        let tag = (x: c.w * 24 / 100, y: g - 50 * s)
        let face = ["#.............#", "##...#####...##", ".##.#.....#.##.", "..##.......##..", "...#.##.##.#...",
                    "...#.##.##.#...", "...#.......#...", "...#.#####.#...", "...#.#.#.#.#...", "....#.....#....",
                    ".....#####....."]
        let paint = C(0x62C444)
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] { crawlStamp(c, tag.x + dx * s, tag.y + dy * s, face, paint.alpha(0.18), s) }
        crawlStamp(c, tag.x, tag.y, face, paint, s)
        crawlText(c, tag.x + 18 * s, tag.y + 3 * s, "GOB!", paint, scale: 2 * s)
        for (dx, len) in [(5, 4), (9, 6), (19, 3), (27, 5), (35, 4)] {
            c.rect(tag.x + dx * s, tag.y + 11 * s, s, len * s, paint.alpha(0.55))
        }

        // The side passage on the right: a round arch of dressed stones over a dark mouth, a far torch's glow
        // inside, a step of rubble at its foot.
        crawlCorridorArch(c, g, x: c.w * 86 / 100, w: 26 * s, h: 40 * s)

        // The torches: a wooden haft in an iron sconce, a warm pool of light on the stones round it; the flames
        // themselves are in the moving layer.
        for t in f.torches {
            c.ellipse(t.x, t.y - 2 * s, 18 * s, 13 * s, C(0xFF9A40, 0.06))
            c.ellipse(t.x, t.y - 2 * s, 10 * s, 8 * s, C(0xFFA850, 0.08))
            c.rect(t.x - s, t.y + s, 2 * s, 8 * s, C(0x6A4428)); c.rect(t.x - s, t.y + s, s, 8 * s, C(0x8A5C38))
            c.rect(t.x - 2 * s, t.y, 4 * s, 2 * s, C(0x2A2B31)); c.rect(t.x - 2 * s, t.y + 4 * s, 4 * s, s, C(0x2A2B31))
            c.rect(t.x - s, t.y + 9 * s, 2 * s, 2 * s, C(0x2A2B31)); c.rect(t.x - 2 * s, t.y + 11 * s, 4 * s, 3 * s, C(0x2A2B31))
            c.rect(t.x - s, t.y - s, 2 * s, s, C(0xF08030))
        }

        // The floor: dark flagstones, plain, a seam across the middle and joints staggered along it.
        c.ground(g, C(0x34363E), edge: C(0x4E515C), speck: C(0x2C2D34), seed: 52)
        let mid = g + (c.h - g) / 2
        c.rect(0, mid, c.w, max(1, s / 2), C(0x2C2D34))
        for x in stride(from: 0, to: c.w, by: 24 * s) {
            c.rect(x, g + 1, max(1, s / 2), mid - g - 1, C(0x2C2D34)); c.rect(x + 12 * s, mid, max(1, s / 2), c.h - mid, C(0x2C2D34))
        }
    }

    /// The side passage: a round-topped mouth `w` wide and `h` high centred on `x`, standing on the floor, ringed by
    /// voussoirs lit on the left, the dark inside lifting a little towards a far torch's glow.
    private static func crawlCorridorArch(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, h: Int) {
        let s = unit(g), r = w / 2, ring = 4 * s, top = g - h, cy = top + r
        for y in (top - ring)..<g {
            for xx in (x - r - ring)..<(x + r + ring) {
                let dx = Double(xx - x) + 0.5, dy = Double(y - cy) + 0.5
                let d = y < cy ? (dx * dx + dy * dy).squareRoot() : abs(dx)
                if d < Double(r) {
                    let deep = Double(y - top) / Double(h)
                    c.rect(xx, y, 1, 1, deep > 0.55 ? C(0x2A2C34) : C(0x23252C))
                } else if d < Double(r + ring) {
                    // A voussoir: the stones counted round the arch, or up the jambs, a mortar line between.
                    let lit = dx < 0
                    var joint = false, odd = false
                    if y < cy {
                        let a = atan2(-dy, dx), step = Double.pi / 9
                        let q = a / step
                        joint = (q - q.rounded(.down)) * step * Double(r) < Double(s)
                        odd = Int(q) % 2 == 0
                    } else {
                        joint = (y - cy) % (7 * s) < s
                        odd = ((y - cy) / (7 * s)) % 2 == 0
                    }
                    let col = joint ? C(0x2E3039) : lit ? (odd ? C(0x727684) : C(0x666A78)) : (odd ? C(0x565A68) : C(0x4C505D))
                    c.rect(xx, y, 1, 1, col)
                }
            }
        }
        // The far torch, deep inside.
        c.ellipse(x + 2 * s, g - 14 * s, 6 * s, 5 * s, C(0xFF9A40, 0.10))
        c.rect(x + 2 * s, g - 15 * s, s, 2 * s, C(0xD88030, 0.7))
        // Rubble at the foot of the left jamb.
        for (dx, wv, hv) in [(-r - 6, 5, 3), (-r - 2, 4, 2), (r + 3, 4, 2)] {
            c.rect(x + dx * s, g - hv * s, wv * s, hv * s, C(0x4C505D)); c.rect(x + dx * s, g - hv * s, wv * s, s, C(0x6A6E7C))
        }
    }

    /// The screen saver's vaulted roof over the tunnel: three bays of round arches on stone corbels, their voussoirs
    /// lit on the left and a pale keystone at each crown; above them the vault's dark stone, its courses darkening up
    /// to a ridge rib with a boss over each bay, slit vents letting a cold glimmer down, roots hanging
    /// through the cracks, chains with hooks in the outer bays and, in the middle, an iron cage with a skull in it.
    private static func crawlCorridorVault(_ c: PixelCanvas, _ g: Int, _ spring: Int) {
        let s = unit(g), bay = c.w / 3, r = bay / 2 - 6 * s, ring = 7 * s, ridge = 16 * s
        let webTop = C(0x2C2E37), webLow = C(0x40434F), webJoint = C(0x24262D), course = 8 * s
        for y in 0..<spring {
            let row = (spring - y) / course, inRow = (spring - y) % course
            let band = Double(min(4, y * 5 / max(1, spring))) / 4
            let tone = lerp(webTop, webLow, band), toneL = lerp(tone, C(0x8A8E9C), 0.18)
            for x in 0..<c.w {
                let k = x / bay, cx = k * bay + bay / 2
                let dx = Double(x - cx) + 0.5, dy = Double(y - spring) + 0.5
                let d = (dx * dx + dy * dy).squareRoot()
                if d >= Double(r + ring) {
                    // The vault's stone: blocks in courses, darker towards the top, each lit along its top.
                    let joint = inRow == 0 || (x + row * 9 * s) % (18 * s) < s
                    c.rect(x, y, 1, 1, joint ? webJoint : inRow == course - s ? toneL : tone)
                } else if d >= Double(r) {
                    let a = atan2(-dy, dx), step = Double.pi / 13
                    let q = a / step
                    let joint = (q - q.rounded(.down)) * step * Double(r) < Double(s)
                    let odd = Int(q) % 2 == 0, key = Int(q) == 6
                    let col = joint ? C(0x2E3039) : key ? C(0x8A8E9C) : dx < 0 ? (odd ? C(0x72768A) : C(0x666A7A)) : (odd ? C(0x585C6A) : C(0x4E5260))
                    c.rect(x, y, 1, 1, col)
                }
            }
        }
        // A slit vent high over each inner corbel, a cold glimmer falling from it.
        for k in 1...2 {
            let cx = k * bay, vy = ridge + 22 * s
            c.rect(cx - 2 * s, vy - s, 5 * s, 16 * s, C(0x5E6270)); c.rect(cx - s, vy, 3 * s, 14 * s, C(0x1A1C22))
            c.rect(cx, vy + s, s, 12 * s, C(0x8AB0D0, 0.35))
            for i in 0..<5 { c.rect(cx - 2 * s - i * s, vy + 15 * s + i * 4 * s, 5 * s + 2 * i * s, 4 * s, C(0x8AB0D0, 0.035)) }
        }
        // The ridge rib along the top and a boss over each bay.
        c.rect(0, 0, c.w, ridge, C(0x22242B))
        c.rect(0, ridge, c.w, 5 * s, C(0x4E5260)); c.rect(0, ridge, c.w, s, C(0x6A6E7C)); c.rect(0, ridge + 4 * s, c.w, s, C(0x30323B))
        for k in 0..<3 {
            let cx = k * bay + bay / 2
            c.circle(cx, ridge + 2 * s, 5 * s, C(0x5E6270)); c.circle(cx - s, ridge + s, 3 * s, C(0x7C808E))
        }
        // The corbels the arches spring from: three stepped stones.
        for k in 0...3 {
            let x = k * bay
            c.rect(x - 7 * s, spring, 14 * s, 3 * s, C(0x6A6E7C)); c.rect(x - 7 * s, spring + 2 * s, 14 * s, s, C(0x3A3D49))
            c.rect(x - 5 * s, spring + 3 * s, 10 * s, 3 * s, C(0x585C6A)); c.rect(x - 3 * s, spring + 6 * s, 6 * s, 2 * s, C(0x4C505D))
        }
        // Roots hanging through the cracks, wavering down, a fork near the end of each.
        let roots: [(Int, Int)] = [(9, 46), (24, 30), (40, 22), (61, 36), (77, 50), (93, 26)]
        for (k, root) in roots.enumerated() {
            let x0 = c.w * root.0 / 100, len = root.1 * s
            for i in 0..<len {
                let wob = Int(sin(Double(i) / Double(6 * s) + Double(k)) * Double(s))
                c.rect(x0 + wob, ridge + 5 * s + i, s, 1, C(0x5E4632))
                if i < len / 2 { c.rect(x0 + wob - s, ridge + 5 * s + i, s, 1, C(0x4A3626)) }
            }
            c.rect(x0 - 2 * s, ridge + 5 * s + len - 6 * s, s, 5 * s, C(0x5E4632))
        }
        // Chains with hooks in the outer bays.
        for fx in [1, 5] {
            let x = c.w * fx / 6, end = spring - r - 30 * s
            for y in stride(from: ridge + 5 * s, to: end, by: 3 * s) { c.rect(x - s, y, 3 * s, 2 * s, C(0x26282E)); c.rect(x, y + 2 * s, s, s, C(0x26282E)) }
            c.rect(x, end, s, 4 * s, C(0x3A3C44)); c.rect(x - 3 * s, end + 4 * s, 4 * s, s, C(0x3A3C44)); c.rect(x - 3 * s, end + 2 * s, s, 2 * s, C(0x3A3C44))
        }
        // The cage on its chain in the middle bay: an iron dome and ring, bars, a floor plate, a skull inside.
        let cx = c.w / 2, top = spring - r + 10 * s, iron = C(0x22242A), ironL = C(0x4A4C56)
        for y in stride(from: ridge + 7 * s, to: top - 6 * s, by: 3 * s) { c.rect(cx - s, y, 3 * s, 2 * s, iron); c.rect(cx, y + 2 * s, s, s, iron) }
        c.rect(cx - 2 * s, top - 7 * s, 5 * s, 2 * s, iron)
        for dy in 0..<(5 * s) {
            let half = Int(Double(13 * s) * (1 - pow(Double(dy) / Double(5 * s), 2)).squareRoot())
            c.rect(cx - half, top - dy, 2 * half + 1, 1, dy > 3 * s ? iron : dy % (2 * s) == 0 ? ironL : iron)
        }
        c.rect(cx - 13 * s, top, 27 * s, 2 * s, iron); c.rect(cx - 13 * s, top, 27 * s, s, ironL)
        // The skull lying on the floor plate, the jaw beside it.
        let fy = top + 34 * s
        c.rect(cx - 5 * s, fy - 8 * s, 9 * s, 6 * s, C(0xC8C0A8)); c.rect(cx - 4 * s, fy - 9 * s, 7 * s, s, C(0xC8C0A8))
        c.rect(cx - 4 * s, fy - 6 * s, 2 * s, 2 * s, C(0x22242A)); c.rect(cx, fy - 6 * s, 2 * s, 2 * s, C(0x22242A))
        c.rect(cx - 3 * s, fy - 2 * s, 5 * s, 2 * s, C(0xA8A090)); c.rect(cx + 5 * s, fy - 2 * s, 4 * s, 2 * s, C(0xA8A090))
        for k in 0..<9 { c.rect(cx - 13 * s + k * 3 * s + (k > 4 ? s : 0), top + 2 * s, s, fy - top - 2 * s, k == 0 ? ironL : iron) }
        c.rect(cx - 13 * s, top + 16 * s, 27 * s, s, iron)
        c.rect(cx - 14 * s, fy, 29 * s, 3 * s, iron); c.rect(cx - 14 * s, fy, 29 * s, s, ironL)
        c.rect(cx - s, fy + 3 * s, 3 * s, 3 * s, iron)
    }

    /// The tunnels' life: the torches' flames flickering, their light breathing on the stones, and the System's blue
    /// box blinking on the wall (FLOOR 1), its glow pulsing while it's up.
    static func crawlCorridorLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlCorridorFrame(c, g)
        for (k, p) in f.torches.enumerated() {
            let h = 3 + Int(t * 9 + Double(k * 5)) % 3, lean = Int(t * 5 + Double(k)) % 3 == 0 ? s : 0
            c.ellipse(p.x, p.y - 3 * s, 7 * s, 6 * s, C(0xFFB050, 0.04 + 0.03 * sin(t * 6 + Double(k))))
            c.rect(p.x - s, p.y - h * s, 2 * s, h * s, C(0xF08A30))
            c.rect(p.x - s + lean, p.y - (h + 1) * s, s, s, C(0xF0A040))
            c.rect(p.x, p.y - (h - 1) * s, s, (h - 1) * s, C(0xFFE8A0))
        }
        let b = f.box, on = t.truncatingRemainder(dividingBy: 2.6) < 2.0
        guard on else { return }
        let glow = 0.18 + 0.1 * sin(t * 3)
        c.rect(b.x - 2 * s, b.y - 2 * s, b.w + 4 * s, b.h + 4 * s, C(0x3A8CFF, glow))
        c.rect(b.x, b.y, b.w, b.h, C(0x0E2A6A)); c.rect(b.x, b.y, b.w, s, C(0x6AB4FF)); c.rect(b.x, b.y + b.h - s, b.w, s, C(0x2A64C8))
        c.rect(b.x, b.y, s, b.h, C(0x6AB4FF)); c.rect(b.x + b.w - s, b.y, s, b.h, C(0x2A64C8))
        crawlText(c, b.x + 3 * s, b.y + 3 * s, "FLOOR 1", C(0xF0F6FF), scale: s)
    }
}

// MARK: - Mordecai's Tutorial Guild

extension Scenes {
    /// Where things stand in the guild, shared by the still picture and the moving layer: the bench's left edge and
    /// top, the flasks' liquids (where bubbles rise: centre, top, bottom), the burner, and the round flask's mouth.
    static func crawlGuildFrame(_ c: PixelCanvas, _ g: Int) -> (bench: (x: Int, top: Int), liquids: [(x: Int, top: Int, bottom: Int)],
                                                                burner: (x: Int, y: Int), neck: (x: Int, y: Int)) {
        let s = unit(g), x = c.w * 4 / 100, top = g - 20 * s
        let flask = (x: x + 11 * s, y: top - 15 * s)
        let liquids = [(x: flask.x, top: flask.y, bottom: flask.y + 5 * s),
                       (x: x + 44 * s, top: top - 8 * s, bottom: top - 2 * s)]
        return ((x, top), liquids, (x + 11 * s, top - 4 * s), (x + 11 * s, flask.y - 15 * s))
    }

    /// Mordecai's Tutorial Guild: the guide's cramped room off the first floor. Dusky teal plaster on stone, fallen
    /// away in places to show the blocks behind, over a plain dark plinth and slate flags. On the left his alchemy
    /// bench: a round flask of green brew on a tripod over a burner, a copper retort dripping into a little flask, a
    /// purple potion in a conical flask and a tall red vial. In the middle, two shelves of potions (red, blue, green,
    /// amber, purple) in round, square and tall bottles. On the right, his cot with its headboard, the blanket pulled
    /// up, and the guild's sign hanging over it. On the screen saver the wall rises to bookcases either side, jars of
    /// things in murky liquid between the books, and between them an alchemical chart pinned
    /// up over a brass lantern hanging on its chain.
    static func crawlGuild(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlGuildFrame(c, g)
        let wall = C(0x3A5052), wallD = C(0x2C3E40), wallL = C(0x4A6062)
        let wood = C(0x6A4428), woodD = C(0x4A2E1A), woodL = C(0x8A5C38)
        let iron = C(0x2A2B31), glass = C(0xA8C8D0, 0.55)

        // The plaster, flat, fallen away in a few places to show the stone behind.
        c.rect(0, 0, c.w, g, wall)
        for (fx, fy) in [(29, 56), (64, 60), (93, 28)] {
            let x = c.w * fx / 100, y = g - fy * s
            c.rect(x - s, y - s, 18 * s, 12 * s, wallD)
            for row in 0..<2 {
                for k in 0..<2 {
                    let bx = x + row * 4 * s + k * 8 * s, by = y + row * 5 * s
                    c.rect(bx, by, 7 * s, 4 * s, C(0x5A5650)); c.rect(bx, by, 7 * s, s, C(0x6E6A62))
                }
            }
        }

        // On the screen saver: bookcases up to the ceiling either side, the chart and the lantern between.
        if tall { crawlGuildStacks(c, g) }

        // The plinth along the floor, plain dark stone, its top lit.
        let band = g - 10 * s
        c.rect(0, band, c.w, g - band, C(0x263436)); c.rect(0, band, c.w, s, wallL)
        for x in stride(from: 14 * s, to: c.w, by: 32 * s) { c.rect(x, band + s, s, g - band - s, C(0x1E2A2C)) }

        // The potion shelves in the middle: two planks on brackets, a row of bottles on each.
        let sx = c.w * 37 / 100, sw = 72 * s
        let potions = [C(0xD03A3A), C(0x3A7AE0), C(0x4AC060), C(0xE0A030), C(0x9A4AD0)]
        for (row, py) in [g - 46 * s, g - 28 * s].enumerated() {
            var bx = sx + 3 * s, k = 0
            while bx + 8 * s < sx + sw {
                let col = potions[(k * 2 + row) % potions.count], shape = (k + row) % 3
                crawlGuildBottle(c, bx, py, shape, col, s)
                bx += (shape == 2 ? 8 : 11) * s; k += 1
            }
            c.rect(sx, py, sw, 3 * s, wood); c.rect(sx, py, sw, s, woodL); c.rect(sx, py + 2 * s, sw, s, woodD)
            for bxk in [sx + 5 * s, sx + sw - 8 * s] {
                c.rect(bxk, py + 3 * s, 3 * s, 5 * s, woodD); c.rect(bxk, py + 3 * s, s, 5 * s, wood)
            }
        }

        // The alchemy bench on the left: a thick top on two legs, a stretcher low down.
        let b = f.bench, bw = 60 * s
        for lx in [b.x + 3 * s, b.x + bw - 7 * s] {
            c.rect(lx, b.top + 4 * s, 4 * s, g - b.top - 4 * s, woodD); c.rect(lx, b.top + 4 * s, s, g - b.top - 4 * s, wood)
        }
        c.rect(b.x + 3 * s, g - 6 * s, bw - 6 * s, 2 * s, woodD)
        c.rect(b.x, b.top, bw, 4 * s, wood); c.rect(b.x, b.top, bw, s, woodL); c.rect(b.x, b.top + 3 * s, bw, s, woodD)
        // The burner, its tripod and the round flask of green brew on it.
        let bu = f.burner
        c.rect(bu.x - 4 * s, b.top - 4 * s, 8 * s, 4 * s, C(0xB08A40)); c.rect(bu.x - 4 * s, b.top - 4 * s, 2 * s, 4 * s, C(0xD0AA60))
        c.rect(bu.x - 7 * s, b.top - 9 * s, s, 9 * s, iron); c.rect(bu.x + 6 * s, b.top - 9 * s, s, 9 * s, iron)
        c.rect(bu.x - 7 * s, b.top - 9 * s, 14 * s, s, iron)
        let fl = f.liquids[0], fr = 7 * s
        c.circle(fl.x, fl.top, fr, glass)
        c.rect(fl.x - s, fl.top - 15 * s, 3 * s, 9 * s, glass); c.rect(fl.x - 2 * s, fl.top - 15 * s, 5 * s, s, C(0xC8E0E8, 0.8))
        for dy in 0...(6 * s) {
            let half = Int((Double((fr - s) * (fr - s) - dy * dy)).squareRoot())
            if half > 0 { c.rect(fl.x - half, fl.top + dy, 2 * half + 1, 1, C(0x58C868)) }
        }
        c.rect(fl.x - 5 * s, fl.top, 11 * s, s, C(0x8AE898))
        c.rect(fl.x - 4 * s, fl.top - 4 * s, s, 3 * s, C(0xFFFFFF, 0.8))
        // The copper retort on its stand, its long spout running down into a little flask of amber.
        let rx = b.x + 27 * s
        c.rect(rx - 4 * s, b.top - 3 * s, 8 * s, 3 * s, iron)
        c.ellipse(rx, b.top - 8 * s, 7 * s, 5 * s, C(0xA05A28)); c.ellipse(rx - 2 * s, b.top - 9 * s, 4 * s, 3 * s, C(0xC87A40))
        c.rect(rx - 3 * s, b.top - 11 * s, 2 * s, s, C(0xF0B080))
        c.glowLine(Double(rx + 2 * s), Double(b.top - 12 * s), Double(rx + 6 * s), Double(b.top - 17 * s), core: C(0xA05A28), glow: C(0, 0), coreR: Double(s) * 1.4, glowR: Double(s) * 1.5)
        c.glowLine(Double(rx + 6 * s), Double(b.top - 17 * s), Double(rx + 9 * s), Double(b.top - 7 * s), core: C(0xA05A28), glow: C(0, 0), coreR: Double(s) * 0.8, glowR: Double(s) * 0.9)
        c.circle(rx + 9 * s, b.top - 4 * s, 4 * s, glass); c.rect(rx + 6 * s, b.top - 4 * s, 7 * s, 4 * s, C(0xE0A030))
        // The conical flask of purple and the tall red vial.
        let lq = f.liquids[1]
        for k in 0..<(11 * s) {
            let half = s + k * 5 / 11
            c.rect(lq.x - half, b.top - 11 * s + k, 2 * half + 1, 1, k >= 3 * s ? C(0x9A4AD0) : glass)
        }
        c.rect(lq.x - s, b.top - 15 * s, 3 * s, 4 * s, glass); c.rect(lq.x - s, b.top - 16 * s, 3 * s, s, C(0x8A6A40))
        c.rect(lq.x - 3 * s, b.top - 6 * s, s, 3 * s, C(0xD8A8F8))
        let vx = b.x + 52 * s
        c.rect(vx, b.top - 18 * s, 4 * s, 18 * s, glass); c.rect(vx, b.top - 12 * s, 4 * s, 12 * s, C(0xD03A3A))
        c.rect(vx, b.top - 19 * s, 4 * s, 2 * s, C(0x8A6A40)); c.rect(vx, b.top - 11 * s, s, 7 * s, C(0xF07A6A))

        // The cot on the right: a headboard at the left, a low wooden frame, a thin mattress, a red blanket pulled
        // up, a pillow at the head.
        let cx = c.w * 72 / 100, cw = 56 * s
        c.rect(cx, g - 20 * s, 4 * s, 20 * s, woodD); c.rect(cx, g - 20 * s, s, 20 * s, wood)
        c.rect(cx - s, g - 21 * s, 6 * s, 2 * s, wood); c.rect(cx - s, g - 21 * s, 6 * s, s, woodL)
        c.rect(cx + cw - 3 * s, g - 9 * s, 3 * s, 9 * s, woodD); c.rect(cx + cw - 3 * s, g - 9 * s, s, 9 * s, wood)
        c.rect(cx + 4 * s, g - 8 * s, cw - 7 * s, 3 * s, wood); c.rect(cx + 4 * s, g - 8 * s, cw - 7 * s, s, woodL)
        c.rect(cx + 4 * s, g - 12 * s, cw - 7 * s, 4 * s, C(0x6A7480))
        c.rect(cx + 5 * s, g - 15 * s, 11 * s, 4 * s, C(0xD0C8B4)); c.rect(cx + 5 * s, g - 15 * s, 11 * s, s, C(0xE8E2D0))
        c.rect(cx + 17 * s, g - 14 * s, cw - 20 * s, 7 * s, C(0x8A3434)); c.rect(cx + 17 * s, g - 14 * s, cw - 20 * s, s, C(0xA84A44))
        c.rect(cx + 17 * s, g - 14 * s, 3 * s, 7 * s, C(0xC8B890)); c.rect(cx + 17 * s, g - 14 * s, 3 * s, s, C(0xE0D4B0))
        for x in stride(from: cx + 28 * s, to: cx + cw - 4 * s, by: 10 * s) { c.rect(x, g - 12 * s, s, 4 * s, C(0x6A2626)) }
        // The guild's sign over it, hung from a nail by two cords.
        let label = "GUILD", signW = crawlTextWidth(label, scale: 2 * s) + 8 * s, signH = 16 * s
        let sgx = cx + cw / 2 - signW / 2, sgy = g - 48 * s
        c.rect(cx + cw / 2, sgy - 7 * s, s, s, iron)
        c.glowLine(Double(cx + cw / 2), Double(sgy - 7 * s), Double(sgx + 3 * s), Double(sgy), core: C(0x2A2016), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.glowLine(Double(cx + cw / 2), Double(sgy - 7 * s), Double(sgx + signW - 3 * s), Double(sgy), core: C(0x2A2016), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.rect(sgx, sgy, signW, signH, woodD); c.rect(sgx + s, sgy + s, signW - 2 * s, signH - 2 * s, wood); c.rect(sgx + s, sgy + s, signW - 2 * s, s, woodL)
        crawlText(c, sgx + 4 * s, sgy + 3 * s, label, C(0xF0E0B0), scale: 2 * s)

        // The floor: slate flags, plain.
        c.ground(g, C(0x2E2C34), edge: C(0x46444E), speck: C(0x26242C), seed: 61)
        for x in stride(from: 10 * s, to: c.w, by: 26 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x26242C)) }
    }

    /// One potion bottle standing on a shelf at `y`: round (0), square (1) or tall (2), the glass full of `col`, a
    /// cork in its neck and a glint on its left.
    private static func crawlGuildBottle(_ c: PixelCanvas, _ x: Int, _ y: Int, _ shape: Int, _ col: Px, _ s: Int) {
        let cork = C(0x8A6A40), glint = lerp(col, C(0xFFFFFF), 0.55), dark = lerp(col, C(0x000000), 0.3)
        switch shape {
        case 0:
            c.circle(x + 4 * s, y - 5 * s, 5 * s, col); c.rect(x + 5 * s, y - 2 * s, 3 * s, 2 * s, dark)
            c.rect(x + 3 * s, y - 13 * s, 3 * s, 4 * s, col.alpha(0.7)); c.rect(x + 3 * s, y - 14 * s, 3 * s, s, cork)
            c.rect(x + s, y - 7 * s, s, 2 * s, glint)
        case 1:
            c.rect(x, y - 10 * s, 8 * s, 10 * s, col); c.rect(x + s, y - 11 * s, 6 * s, s, col); c.rect(x + 6 * s, y - 10 * s, 2 * s, 10 * s, dark)
            c.rect(x + 3 * s, y - 14 * s, 2 * s, 3 * s, col.alpha(0.7)); c.rect(x + 3 * s, y - 15 * s, 2 * s, s, cork)
            c.rect(x + s, y - 9 * s, s, 4 * s, glint)
        default:
            c.rect(x, y - 14 * s, 5 * s, 14 * s, col); c.rect(x + 4 * s, y - 14 * s, s, 14 * s, dark); c.rect(x, y - 16 * s, 5 * s, 2 * s, cork)
            c.rect(x + s, y - 12 * s, s, 6 * s, glint)
        }
    }

    /// The screen saver's wall above the room: a bookcase up to the ceiling on each side (a dark frame, deep shelves,
    /// books in runs of one dusty colour and big jars of murky things between them),
    /// and between them the plaster with an alchemical chart pinned up and a brass lantern hanging on a chain.
    private static func crawlGuildStacks(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), bottom = g - 72 * s, top = 8 * s, pitch = 24 * s
        let frame = C(0x3A2416), plank = C(0x5A3A22), plankL = C(0x7A5232)
        let books = [C(0x7A2E2A), C(0x2E4A66), C(0x6E6230)]
        let murk = [C(0x8A9A3A), C(0x6A3A7A), C(0x3A7A6A)]
        for (side, (x0, x1)) in [(c.w * 2 / 100, c.w * 36 / 100), (c.w * 64 / 100, c.w * 98 / 100)].enumerated() {
            c.rect(x0, top, x1 - x0, bottom - top, C(0x1E1612))
            var row = 0
            for py in stride(from: bottom - 4 * s, to: top + pitch, by: -pitch) {
                var x = x0 + 5 * s, k = 0
                while x < x1 - 14 * s {
                    if (k + row + side) % 3 == 1 {
                        // A big jar: glass, a murky liquid, something pale floating in it, a pewter lid.
                        let jc = murk[(row + k / 3 + side) % murk.count]
                        c.rect(x, py - 16 * s, 12 * s, 16 * s, C(0xA8C8D0, 0.35)); c.rect(x, py - 12 * s, 12 * s, 12 * s, jc)
                        c.rect(x + 9 * s, py - 12 * s, 3 * s, 12 * s, lerp(jc, C(0x000000), 0.25))
                        c.rect(x + 4 * s, py - 8 * s, 4 * s, 4 * s, C(0xD8D0B0, 0.75)); c.rect(x + s, py - 11 * s, s, 8 * s, lerp(jc, C(0xFFFFFF), 0.4))
                        c.rect(x - s, py - 18 * s, 14 * s, 3 * s, C(0x7A7A84)); c.rect(x - s, py - 18 * s, 14 * s, s, C(0x9A9AA4))
                        x += 17 * s
                    } else {
                        // A run of books in one colour, upright, a gilt band across each spine.
                        let col = books[(row * 2 + k + side) % books.count], n = 4 + (k + row) % 3
                        for j in 0..<n where x + 4 * s < x1 - 5 * s {
                            let bh = (15 + (j * 3 + row) % 4) * s
                            c.rect(x, py - bh, 4 * s, bh, col); c.rect(x, py - bh, s, bh, lerp(col, C(0xFFFFFF), 0.2))
                            c.rect(x + 3 * s, py - bh, s, bh, lerp(col, C(0x000000), 0.3))
                            c.rect(x, py - bh + 3 * s, 4 * s, s, C(0xC8A860, 0.7))
                            x += 4 * s
                        }
                        x += 4 * s
                    }
                    k += 1
                }
                c.rect(x0, py, x1 - x0, 4 * s, plank); c.rect(x0, py, x1 - x0, s, plankL)
                row += 1
            }
            c.rect(x0 - 2 * s, top - 4 * s, x1 - x0 + 4 * s, 5 * s, frame); c.rect(x0 - 2 * s, top - 4 * s, x1 - x0 + 4 * s, s, plankL)
            c.rect(x0 - 2 * s, top, 4 * s, bottom - top, frame); c.rect(x1 - 2 * s, top, 4 * s, bottom - top, frame)
            c.rect(x0 - 2 * s, top, s, bottom - top, plankL)
            c.rect(x0 - 2 * s, bottom, x1 - x0 + 4 * s, 5 * s, frame); c.rect(x0 - 2 * s, bottom, x1 - x0 + 4 * s, s, plankL)
        }
        // The lantern's chain, hanging behind the chart.
        let mx = c.w / 2, cy = top + (bottom - top) * 35 / 100, pw = 46 * s, ph = 56 * s
        let ly = cy + ph / 2 + 30 * s
        for y in stride(from: top, to: ly, by: 3 * s) { c.rect(mx - s, y, 3 * s, 2 * s, C(0x2A2216)) }
        // The chart in the middle: a parchment pinned up, a circle, a triangle in it and an eye at its heart.
        c.rect(mx - pw / 2 + 2 * s, cy - ph / 2 + 2 * s, pw, ph, C(0x1E2A2C))
        c.rect(mx - pw / 2, cy - ph / 2, pw, ph, C(0xD8C89C)); c.rect(mx - pw / 2, cy - ph / 2, pw, s, C(0xF0E2B8))
        c.rect(mx + pw / 2 - 3 * s, cy - ph / 2, 3 * s, ph, C(0xB8A87C))
        let ink = C(0x6A3A1E)
        for a in stride(from: 0.0, to: 360.0, by: 2.0) {
            let r = a * Double.pi / 180
            c.rect(mx + Int(cos(r) * Double(17 * s)), cy + Int(sin(r) * Double(17 * s)), s, s, ink)
        }
        let p1 = (Double(mx), Double(cy - 17 * s)), p2 = (Double(mx - 15 * s), Double(cy + 9 * s)), p3 = (Double(mx + 15 * s), Double(cy + 9 * s))
        for (a, b) in [(p1, p2), (p2, p3), (p3, p1)] {
            c.glowLine(a.0, a.1, b.0, b.1, core: ink, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        }
        c.ellipse(mx, cy, 5 * s, 3 * s, ink); c.ellipse(mx, cy, 4 * s, 2 * s, C(0xD8C89C)); c.rect(mx - s, cy - s, 2 * s, 2 * s, C(0x3A7A6A))
        for (dx, dy) in [(-pw / 2 + 2 * s, -ph / 2 + 2 * s), (pw / 2 - 3 * s, -ph / 2 + 2 * s)] { c.rect(mx + dx, cy + dy, s, s, C(0xC03030)) }
        // The lantern, with its glow.
        c.ellipse(mx, ly + 9 * s, 26 * s, 20 * s, C(0xFFB050, 0.05)); c.ellipse(mx, ly + 9 * s, 14 * s, 12 * s, C(0xFFB050, 0.07))
        c.rect(mx - 6 * s, ly, 13 * s, 3 * s, C(0x8A6A30)); c.rect(mx - 4 * s, ly - 2 * s, 9 * s, 2 * s, C(0x8A6A30))
        c.rect(mx - 5 * s, ly + 3 * s, 11 * s, 12 * s, C(0xF0C060)); c.rect(mx - s, ly + 6 * s, 3 * s, 6 * s, C(0xFFF0C0))
        c.rect(mx - 5 * s, ly + 3 * s, 2 * s, 12 * s, C(0x8A6A30)); c.rect(mx + 4 * s, ly + 3 * s, 2 * s, 12 * s, C(0x8A6A30))
        c.rect(mx - 6 * s, ly + 15 * s, 13 * s, 3 * s, C(0x8A6A30))
    }

    /// The guild's life: bubbles rising through the green brew and the purple potion, a wisp of steam curling from
    /// the round flask's mouth, and the burner's blue flame flickering.
    static func crawlGuildLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlGuildFrame(c, g)
        for (i, l) in f.liquids.enumerated() {
            for k in 0..<3 {
                let p = (t * (0.9 + Double(i) * 0.3) + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                let y = l.bottom - Int(p * Double(l.bottom - l.top))
                c.rect(l.x + (k - 1) * 2 * s, y, s, s, C(0xF0FFF0, 0.85))
            }
        }
        for k in 0..<3 {
            let p = (t * 0.5 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            let y = f.neck.y - Int(p * Double(16 * s)), x = f.neck.x + Int(sin(p * 6 + Double(k)) * Double(2 * s))
            c.rect(x - s, y, 3 * s, s, C(0xD8F0E0, 0.45 * (1 - p)))
        }
        let h = 2 + Int(t * 11) % 2
        c.rect(f.burner.x - 2 * s, f.burner.y - h * s, 4 * s, h * s, C(0x5A9AFF)); c.rect(f.burner.x - s, f.burner.y - (h - 1) * s, 2 * s, (h - 1) * s, C(0xC8E0FF))
    }
}

// MARK: - The Hoarder's lair

extension Scenes {
    /// Where things stand in the Hoarder's lair, shared by the still picture and the moving layer: the heap's middle,
    /// its peak and half width, and the bin bag that shifts (centre and radii).
    static func crawlHoardFrame(_ c: PixelCanvas, _ g: Int) -> (cx: Int, peak: Int, half: Int, base: Int, bag: (x: Int, y: Int, rx: Int, ry: Int)) {
        let s = unit(g), tall = isTall(c)
        let peak = tall ? g * 12 / 100 : g - 42 * s
        let half = tall ? c.w * 50 / 100 : c.w * 38 / 100
        return (c.w / 2, peak, half, g - 10 * s, (x: c.w * 57 / 100, y: g - 22 * s, rx: 13 * s, ry: 9 * s))
    }

    /// The top of the heap at column `x`: rising from the base to the peak, flat at the very top, lumpy all the way.
    private static func crawlHoardTop(_ x: Int, _ f: (cx: Int, peak: Int, half: Int, base: Int, bag: (x: Int, y: Int, rx: Int, ry: Int)), _ s: Int) -> Int {
        let u = min(1.0, Double(abs(x - f.cx)) / Double(f.half))
        let lump = Int(noise(x / max(1, 6 * s) + 300) * Double(3 * s))
        return f.base - Int(Double(f.base - f.peak) * max(0, 1 - pow(max(0, u - 0.04) / 0.96, 1.4))) + lump
    }

    /// The Hoarder's lair: a cave of lumpy brown rock where the Hoarder has piled a mountain of junk from the surface.
    /// The heap is a mass of dim bags, boxes and tyres, and on it the things that stand out: car tyres (one on its
    /// edge, two lying flat), a pile of shiny black bin bags and a blue one, an old fridge with a dent and rust, an
    /// orange traffic cone, and on the very top, standing proud, a pink plastic flamingo. The heap stops a little
    /// above the packed dirt floor, plain where the crew stands. On the screen saver the heap towers almost to the
    /// cave's roof, stalactites hanging over it: a mustard sofa, a washing machine, an old TV, a shopping trolley,
    /// more tyres, bags and cones all the way up, the flamingo at the summit.
    static func crawlHoard(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlHoardFrame(c, g)
        let rock = C(0x46392F), rockD = C(0x372C25), rockL = C(0x56473B)

        // The cave: lumpy rock, each lump lit on its upper left and shadowed on its lower right, a crack or two.
        c.rect(0, 0, c.w, g, rock)
        let cell = 26 * s
        for j in 0..<(g / (cell * 2 / 3) + 2) {
            for i in 0..<(c.w / cell + 2) {
                let n = noise(j * 53 + i * 7 + 900)
                let x = i * cell + (j % 2) * cell / 2 + Int(n * Double(8 * s)), y = g - j * cell * 2 / 3 + Int(noise(j * 53 + i * 7 + 901) * Double(6 * s))
                let rx = (10 + Int(n * 6)) * s, ry = (6 + Int(n * 4)) * s
                c.ellipse(x + 2 * s, y + 2 * s, rx, ry, rockD); c.ellipse(x, y, rx, ry, rock)
                c.ellipse(x - rx / 3, y - ry / 3, rx / 2, ry / 3, rockL)
            }
        }
        // On the screen saver: the cave's roof, stalactites hanging from it.
        if tall {
            c.rect(0, 0, c.w, 10 * s, rockD)
            for k in 0..<14 {
                let x = c.w * (3 + k * 7) / 100 + Int(noise(k + 950) * Double(8 * s)), len = (12 + Int(noise(k + 951) * 26)) * s, w = (5 + Int(noise(k + 952) * 4)) * s
                for i in 0..<len { let half = w * (len - i) / (2 * len); c.rect(x - half, 10 * s + i, 2 * half + s, 1, rockD); c.rect(x - half, 10 * s + i, s, 1, rockL) }
            }
        }

        // The heap: a dark mass of junk, filled with dim bags, boxes and tyres, low in contrast so the things on it
        // stand out.
        for x in 0..<c.w {
            let top = crawlHoardTop(x, f, s)
            if top < g { c.rect(x, top, 1, g - top, C(0x2C2624)) }
        }
        let dims = [C(0x3A3430), C(0x463A2E), C(0x32363E), C(0x3E3A36)]
        var i = 0
        for y in stride(from: f.base - 6 * s, to: f.peak, by: -7 * s) {
            for x in stride(from: f.cx - f.half, to: f.cx + f.half, by: 12 * s) {
                i += 1
                let jx = x + Int(noise(i * 5 + 500) * Double(8 * s)) + ((y / (7 * s)) % 2) * 6 * s, jy = y + Int(noise(i * 5 + 501) * Double(3 * s))
                guard crawlHoardTop(jx, f, s) < jy - 4 * s else { continue }
                let col = dims[i % dims.count]
                switch Int(noise(i * 5 + 502) * 4) {
                case 0:
                    c.ellipse(jx, jy, 6 * s, 4 * s, col); c.rect(jx - 3 * s, jy - 3 * s, 3 * s, s, lerp(col, C(0xFFFFFF), 0.1))
                case 1:
                    c.rect(jx - 5 * s, jy - 4 * s, 10 * s, 7 * s, col); c.rect(jx - 5 * s, jy - 4 * s, 10 * s, s, lerp(col, C(0xFFFFFF), 0.1))
                    c.rect(jx - s, jy - 4 * s, 2 * s, 7 * s, lerp(col, C(0x000000), 0.15))
                case 2:
                    c.circle(jx, jy, 5 * s, C(0x26262A)); c.circle(jx, jy, 2 * s, C(0x302E30))
                default:
                    c.ellipse(jx, jy, 7 * s, 4 * s, col)
                }
            }
        }
        // Along the outline, a rim of lumps lit from the left.
        for x in stride(from: f.cx - f.half, to: f.cx + f.half, by: 5 * s) {
            let top = crawlHoardTop(x, f, s)
            guard top < f.base - 2 * s else { continue }
            c.ellipse(x, top + 2 * s, 3 * s, 2 * s, C(0x3A3230)); c.rect(x - 2 * s, top, 2 * s, s, C(0x544A44))
        }

        // The screen saver's tower of junk: big things all the way up.
        if tall {
            crawlHoardSofa(c, f.cx - 92 * s, g - 64 * s, s)
            crawlHoardWasher(c, f.cx + 60 * s, g - 60 * s, s)
            crawlHoardTyre(c, f.cx + 112 * s, g - 34 * s, 11 * s, s)
            crawlHoardBag(c, f.cx - 140 * s, g - 30 * s, 12 * s, 8 * s, C(0x24262C), s)
            crawlHoardTrolley(c, f.cx - 54 * s, g - 100 * s, s)
            crawlHoardTV(c, f.cx + 10 * s, g - 96 * s, s)
            crawlHoardBag(c, f.cx + 64 * s, g - 92 * s, 12 * s, 8 * s, C(0x3A5A8A), s)
            crawlHoardFridge(c, f.cx - 30 * s, g - 132 * s, s)
            crawlHoardTyreFlat(c, f.cx + 16 * s, g - 132 * s, 24 * s, s); crawlHoardTyreFlat(c, f.cx + 16 * s, g - 138 * s, 24 * s, s)
            crawlHoardCone(c, f.cx + 46 * s, g - 130 * s, s)
            crawlHoardBag(c, f.cx - 4 * s, g - 166 * s, 12 * s, 8 * s, C(0x24262C), s)
            crawlHoardTyre(c, f.cx + 20 * s, g - 176 * s, 11 * s, s)
            crawlHoardCone(c, f.cx - 26 * s, g - 178 * s, s)
            crawlHoardBag(c, f.cx + 2 * s, f.peak + 30 * s, 12 * s, 8 * s, C(0x2C2E36), s)
            crawlHoardTyre(c, f.cx - 16 * s, f.peak + 40 * s, 11 * s, s)
        }

        // The strip's heroes of the heap, from the left: a tyre on its edge and two lying flat, the bin bags with the
        // flamingo on top, the fridge, the cone.
        crawlHoardTyre(c, c.w * 18 / 100, g - 21 * s, 11 * s, s)
        crawlHoardTyreFlat(c, c.w * 27 / 100, g - 24 * s, 24 * s, s); crawlHoardTyreFlat(c, c.w * 27 / 100, g - 30 * s, 24 * s, s)
        crawlHoardFridge(c, c.w * 66 / 100, g - 11 * s, s)
        crawlHoardBag(c, c.w * 42 / 100, g - 21 * s, 12 * s, 8 * s, C(0x24262C), s)
        crawlHoardBag(c, f.bag.x, f.bag.y, f.bag.rx, f.bag.ry, C(0x24262C), s)
        crawlHoardBag(c, c.w * 39 / 100, g - 33 * s, 9 * s, 6 * s, C(0x3A5A8A), s)
        crawlHoardBag(c, c.w * 50 / 100, g - 33 * s, 12 * s, 8 * s, C(0x2C2E36), s)
        crawlHoardCone(c, c.w * 79 / 100, g - 14 * s, s)
        crawlHoardFlamingo(c, f.cx - 2 * s, tall ? f.peak + 2 * s : g - 40 * s, s)

        // The floor: packed dirt, plain, the heap's foot a dark plain wedge above it.
        c.rect(0, f.base, c.w, g - f.base, C(0x2C2624)); c.rect(0, f.base, c.w, s, C(0x3A3230))
        c.ground(g, C(0x3A3029), edge: C(0x54463A), speck: C(0x2E2620), seed: 73)
    }

    /// A shopping trolley tipped in the junk with its foot at `y`: a wire basket (a frame and a grid), the handle,
    /// the chassis and two wheels.
    private static func crawlHoardTrolley(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let wire = C(0xA8ACB4), wireD = C(0x6A6E76)
        c.rect(x, y - 22 * s, 26 * s, s, wire); c.rect(x + 2 * s, y - 10 * s, 22 * s, s, wire)
        c.glowLine(Double(x), Double(y - 22 * s), Double(x + 2 * s), Double(y - 10 * s), core: wire, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        c.glowLine(Double(x + 26 * s), Double(y - 22 * s), Double(x + 24 * s), Double(y - 10 * s), core: wire, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
        for k in 1..<6 { c.rect(x + k * 4 * s + s, y - 21 * s, max(1, s / 2), 11 * s, wireD) }
        for k in 1..<3 { c.rect(x + s, y - 22 * s + k * 4 * s, 24 * s, max(1, s / 2), wireD) }
        c.rect(x + 26 * s, y - 25 * s, 2 * s, 4 * s, wire); c.rect(x + 25 * s, y - 26 * s, 6 * s, 2 * s, C(0xC03030))
        c.rect(x + 4 * s, y - 7 * s, 20 * s, s, wireD)
        c.circle(x + 6 * s, y - 3 * s, 2 * s, C(0x1A1A1E)); c.circle(x + 21 * s, y - 3 * s, 2 * s, C(0x1A1A1E))
    }

    /// A black bin bag (or a white or blue carrier) slumped at (`x`, `y`): a round body, a knot and two ears on top,
    /// a shine on its upper left and a crease or two.
    static func crawlHoardBag(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rx: Int, _ ry: Int, _ col: Px, _ s: Int) {
        let hi = lerp(col, C(0xFFFFFF), 0.3), lo = lerp(col, C(0x000000), 0.3)
        c.ellipse(x, y, rx, ry, col)
        c.ellipse(x + rx / 4, y + ry / 3, rx * 3 / 4, ry * 2 / 3, lo)
        c.ellipse(x - s, y, rx - 2 * s, ry - 2 * s, col)
        c.rect(x - rx / 2, y - ry / 2, rx / 3, s, hi); c.rect(x - rx / 2 - s, y - ry / 2 + s, s, 2 * s, hi)
        c.rect(x + rx / 3, y - ry / 4, s, ry / 2, lo)
        c.rect(x - s, y - ry - 2 * s, 3 * s, 3 * s, col); c.rect(x - 3 * s, y - ry - 4 * s, 2 * s, 2 * s, col); c.rect(x + 2 * s, y - ry - 4 * s, 2 * s, 2 * s, col)
        c.rect(x - 3 * s, y - ry - 4 * s, s, s, hi)
    }

    /// A car tyre on its edge, centred at (`x`, `y`), `r` across: black rubber lit on the upper left, a grey rim
    /// and a dark hub.
    static func crawlHoardTyre(_ c: PixelCanvas, _ x: Int, _ y: Int, _ r: Int, _ s: Int) {
        c.circle(x, y, r, C(0x18181C))
        c.circle(x - s, y - s, r - s, C(0x3A3A42))
        c.circle(x, y, r - 2 * s, C(0x222228))
        c.circle(x, y, r * 50 / 100, C(0x8A8A92)); c.circle(x + s / 2, y + s / 2, r * 38 / 100, C(0x5A5A62))
        c.circle(x, y, max(1, r / 7), C(0x1A1A1E))
    }

    /// A car tyre lying flat with its top at `y`, `w` wide from `x`: its tread seen side on, the hole a dark oval.
    static func crawlHoardTyreFlat(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ s: Int) {
        c.ellipse(x + w / 2, y + 5 * s, w / 2, 3 * s, C(0x18181C))
        c.rect(x, y, w, 5 * s, C(0x1E1E22)); c.rect(x, y, 2 * s, 5 * s, C(0x34343A))
        c.rect(x + w / 2 - 2 * s, y + 2 * s, 4 * s, 2 * s, C(0x2A2A30))
        c.ellipse(x + w / 2, y, w / 2, 3 * s, C(0x2E2E34))
        c.ellipse(x + w / 2, y, w / 2 - 2 * s, 2 * s, C(0x26262C))
        c.ellipse(x + w / 2, y, w / 4, s, C(0x101012))
        c.rect(x + 3 * s, y - 2 * s, w / 4, s, C(0x4A4A52))
    }

    /// An old fridge standing in the junk with its foot at `y`: off-white, lit on the left, the door's split and
    /// handles, a dent and rust at the bottom.
    static func crawlHoardFridge(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let w = 15 * s, h = 27 * s
        c.rect(x, y - h, w, h, C(0xBCB6A4)); c.rect(x, y - h, 2 * s, h, C(0xD8D2C0)); c.rect(x + w - 2 * s, y - h, 2 * s, h, C(0x8E887A))
        c.rect(x, y - h, w, s, C(0xE4DECC))
        c.rect(x, y - 18 * s, w, s, C(0x6E6A5E))
        c.rect(x + w - 4 * s, y - 24 * s, s, 4 * s, C(0x6E6A5E)); c.rect(x + w - 4 * s, y - 15 * s, s, 6 * s, C(0x6E6A5E))
        c.rect(x + 5 * s, y - 12 * s, 3 * s, 2 * s, C(0x9E9888))
        c.rect(x + s, y - 3 * s, 6 * s, 2 * s, C(0x8A5A3A)); c.rect(x + 9 * s, y - 2 * s, 3 * s, s, C(0x8A5A3A))
    }

    /// An orange traffic cone with its foot at `y`, centred on `x`: a white band round its middle, a square base.
    static func crawlHoardCone(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        for k in 0..<12 {
            let half = (1 + k / 2) * s, col = (k >= 5 && k <= 7) ? C(0xF0EEE8) : C(0xE8701E)
            c.rect(x - half, y - (14 - k) * s, 2 * half, s, col)
            c.rect(x - half, y - (14 - k) * s, s, s, (k >= 5 && k <= 7) ? C(0xFFFFFF) : C(0xF8963E))
        }
        c.rect(x - 9 * s, y - 2 * s, 18 * s, 2 * s, C(0xC05A14)); c.rect(x - 9 * s, y - 2 * s, 18 * s, s, C(0xE07A2E))
    }

    /// The pink plastic flamingo, standing on its wire legs with its feet at (`x`, `y`) and facing left: a round pink
    /// body lit along its top, a darker wing, the S of its neck, a pale beak tipped black.
    static func crawlHoardFlamingo(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let pink = C(0xF07AB0), pinkL = C(0xFFA8D0), pinkD = C(0xC8508A)
        c.rect(x, y - 9 * s, s, 9 * s, C(0x9A4068)); c.rect(x + 3 * s, y - 9 * s, s, 9 * s, C(0x9A4068))
        c.ellipse(x + 3 * s, y - 12 * s, 7 * s, 4 * s, pink)
        c.rect(x - 2 * s, y - 16 * s, 9 * s, s, pinkL)
        c.ellipse(x + 5 * s, y - 11 * s, 4 * s, 2 * s, pinkD); c.rect(x + 8 * s, y - 13 * s, 3 * s, 2 * s, pinkD)
        c.rect(x - 4 * s, y - 20 * s, 2 * s, 7 * s, pink); c.rect(x - 3 * s, y - 20 * s, s, 7 * s, pinkD)
        c.rect(x - 2 * s, y - 23 * s, 2 * s, 4 * s, pink); c.rect(x - 2 * s, y - 23 * s, s, 4 * s, pinkL)
        c.rect(x - 5 * s, y - 26 * s, 5 * s, 4 * s, pink); c.rect(x - 5 * s, y - 26 * s, 5 * s, s, pinkL)
        c.rect(x - 4 * s, y - 25 * s, s, s, C(0x1A1A1A))
        c.rect(x - 8 * s, y - 25 * s, 3 * s, 2 * s, C(0xF0E0D0)); c.rect(x - 8 * s, y - 24 * s, 2 * s, 2 * s, C(0x1A1A1A))
    }

    /// A mustard sofa sunk in the heap with its foot at `y`: the back, two cushions, an arm at each end.
    private static func crawlHoardSofa(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let m = C(0xB0842C), mL = C(0xD0A44C), mD = C(0x80601E)
        c.rect(x, y - 18 * s, 40 * s, 10 * s, m); c.rect(x, y - 18 * s, 40 * s, s, mL)
        c.rect(x + 5 * s, y - 9 * s, 15 * s, 5 * s, mL); c.rect(x + 20 * s, y - 9 * s, 15 * s, 5 * s, m)
        c.rect(x + 20 * s, y - 9 * s, s, 5 * s, mD)
        c.rect(x, y - 11 * s, 5 * s, 11 * s, mL); c.rect(x + 35 * s, y - 11 * s, 5 * s, 11 * s, mD)
        c.rect(x + 5 * s, y - 4 * s, 30 * s, 4 * s, mD)
        c.rect(x + 25 * s, y - 15 * s, 4 * s, 3 * s, C(0x5A4418))
    }

    /// A washing machine with its foot at `y`: a white box, a round porthole, a dial.
    private static func crawlHoardWasher(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        c.rect(x, y - 20 * s, 18 * s, 20 * s, C(0xC8C8C4)); c.rect(x, y - 20 * s, 2 * s, 20 * s, C(0xE4E4E0)); c.rect(x + 16 * s, y - 20 * s, 2 * s, 20 * s, C(0x9A9A96))
        c.rect(x, y - 16 * s, 18 * s, s, C(0x8A8A86))
        c.circle(x + 9 * s, y - 8 * s, 6 * s, C(0x6A6A70)); c.circle(x + 9 * s, y - 8 * s, 4 * s, C(0x2A3440))
        c.rect(x + 7 * s, y - 10 * s, 2 * s, s, C(0x6A8AA8))
        c.rect(x + 13 * s, y - 19 * s, 3 * s, 2 * s, C(0x5A5A60))
    }

    /// An old box TV with its foot at `y`: a wood-grain cabinet, a grey screen, two knobs.
    private static func crawlHoardTV(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        c.rect(x, y - 16 * s, 24 * s, 16 * s, C(0x6A4428)); c.rect(x, y - 16 * s, 24 * s, s, C(0x8A5C38))
        c.rect(x + 2 * s, y - 14 * s, 15 * s, 11 * s, C(0x5A6066)); c.rect(x + 3 * s, y - 13 * s, 4 * s, s, C(0x8A9096))
        c.rect(x + 19 * s, y - 13 * s, 3 * s, 3 * s, C(0x2A2A2E)); c.rect(x + 19 * s, y - 8 * s, 3 * s, 3 * s, C(0x2A2A2E))
        c.glowLine(Double(x + 8 * s), Double(y - 16 * s), Double(x + 4 * s), Double(y - 24 * s), core: C(0x8A8A92), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.glowLine(Double(x + 12 * s), Double(y - 16 * s), Double(x + 17 * s), Double(y - 23 * s), core: C(0x8A8A92), glow: C(0, 0), coreR: 0.5, glowR: 0.6)
    }

    /// The lair's life: flies buzzing round the bin bags in little loops, and now and then one bag shifting, as if
    /// something under it turned over.
    static func crawlHoardLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlHoardFrame(c, g)
        let into = t.truncatingRemainder(dividingBy: 4.0)
        if into < 0.6 {
            let lift = into < 0.3 ? s : 0
            crawlHoardBag(c, f.bag.x + (into < 0.3 ? 0 : s), f.bag.y - lift, f.bag.rx, f.bag.ry + lift, C(0x24262C), s)
        }
        let hubs = [(c.w * 46 / 100, g - 34 * s), (c.w * 57 / 100, g - 32 * s), (c.w * 40 / 100, g - 40 * s)]
        for k in 0..<6 {
            let h = hubs[k % hubs.count], ph = Double(k) * 1.7
            let x = h.0 + Int(sin(t * (5 + Double(k)) + ph) * Double(7 * s)), y = h.1 + Int(sin(t * (8 + Double(k)) + ph * 2) * Double(3 * s))
            c.rect(x, y, s, s, C(0x141414))
            if Int(t * 20 + Double(k)) % 2 == 0 { c.rect(x, y - s, s, s, C(0xD8E0E8, 0.6)) }
        }
    }
}

// MARK: - The Juicer's gym

extension Scenes {
    /// Where things stand in the gym, shared by the still picture and the moving layer: the top of the rubber skirting,
    /// the wall lamps, and (on the screen saver) the truss the banners and the hanging lamps hang from.
    static func crawlGymFrame(_ c: PixelCanvas, _ g: Int) -> (band: Int, lamps: [(x: Int, y: Int)], truss: Int, hanging: [(x: Int, y: Int)]) {
        let s = unit(g), tall = isTall(c)
        let lamps = [22, 56, 78].map { (x: c.w * $0 / 100, y: g - 58 * s) }
        let truss = tall ? g * 16 / 100 : -1
        let hanging = tall ? [25, 50, 75].map { (x: c.w * $0 / 100, y: truss + 40 * s) } : []
        return (g - 10 * s, lamps, truss, hanging)
    }

    /// The Juicer's gym: a boss room fitted out as a gym, walls of painted block (charcoal, a red stripe along them),
    /// a black rubber skirting and a rubber floor, plain. On the left a squat rack, its bar loaded with big red bumper
    /// plates; a yellow GAINS poster on the wall; a dumbbell rack in two tiers; on the right the turnstile at the
    /// entrance, its card light green. Caged lamps light the wall. On the screen saver the walls rise to a tall
    /// ceiling with a steel truss across, long red banners with a white dumbbell hanging from it and dome lamps
    /// on cords between them.
    static func crawlGym(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlGymFrame(c, g)
        let block = C(0x464A54), blockD = C(0x383B44), blockL = C(0x545864)

        // The block walls: courses of painted blocks, lit along their tops, and a red stripe along them.
        c.rect(0, 0, c.w, g, block)
        var row = 0
        for y in stride(from: f.band - 7 * s, to: -7 * s, by: -7 * s) {
            c.rect(0, y, c.w, s, blockD); c.rect(0, y + s, c.w, s, blockL)
            for x in stride(from: row % 2 == 0 ? 0 : 8 * s, to: c.w, by: 16 * s) { c.rect(x, y, s, 7 * s, blockD) }
            row += 1
        }
        let stripe = g - 42 * s
        c.rect(0, stripe, c.w, 6 * s, C(0x8A2228)); c.rect(0, stripe, c.w, s, C(0xA83038)); c.rect(0, stripe + 6 * s, c.w, s, C(0x2A1A1E))
        if tall {
            for y in [g - 120 * s, g - 200 * s] where y > f.truss + 10 * s {
                c.rect(0, y, c.w, 6 * s, C(0x8A2228)); c.rect(0, y, c.w, s, C(0xA83038)); c.rect(0, y + 6 * s, c.w, s, C(0x2A1A1E))
            }
            crawlGymCeiling(c, g, f.truss, f.hanging)
        }

        // The caged wall lamps, lit warm white here (the moving layer turns them red when the boss music hits).
        for l in f.lamps {
            c.ellipse(l.x, l.y + 2 * s, 12 * s, 8 * s, C(0xFFF0C0, 0.07))
            c.rect(l.x - 3 * s, l.y - 2 * s, 6 * s, 2 * s, C(0x2A2B31))
            c.rect(l.x - 2 * s, l.y, 4 * s, 4 * s, C(0xFFF0C8))
            c.rect(l.x - 3 * s, l.y, s, 5 * s, C(0x2A2B31)); c.rect(l.x + 2 * s, l.y, s, 5 * s, C(0x2A2B31))
            c.rect(l.x - 3 * s, l.y + 2 * s, 6 * s, s, C(0x2A2B31)); c.rect(l.x - 2 * s, l.y + 5 * s, 4 * s, s, C(0x2A2B31))
        }

        // The GAINS poster: yellow, a black frame, the word big, a red dumbbell under it.
        let label = "GAINS", pw = crawlTextWidth(label, scale: 2 * s) + 8 * s, ph = 24 * s
        let px = c.w * 40 / 100 - pw / 2, py = g - 60 * s
        c.rect(px - s, py - s, pw + 2 * s, ph + 2 * s, C(0x1A1A1E)); c.rect(px, py, pw, ph, C(0xF0C030))
        c.rect(px, py, pw, s, C(0xFFE070))
        crawlText(c, px + 4 * s, py + 3 * s, label, C(0x1A1A1E), scale: 2 * s)
        let mx = px + pw / 2
        c.rect(mx - 10 * s, py + 17 * s, 20 * s, 2 * s, C(0x2A2A2E))
        c.rect(mx - 12 * s, py + 15 * s, 3 * s, 6 * s, C(0xC02828)); c.rect(mx + 9 * s, py + 15 * s, 3 * s, 6 * s, C(0xC02828))
        c.rect(mx - 9 * s, py + 16 * s, 2 * s, 4 * s, C(0xC02828)); c.rect(mx + 7 * s, py + 16 * s, 2 * s, 4 * s, C(0xC02828))
        c.rect(px + s, py + s, s, s, C(0x8A8A92)); c.rect(px + pw - 2 * s, py + s, s, s, C(0x8A8A92))

        // The rubber skirting, plain.
        c.rect(0, f.band, c.w, g - f.band, C(0x2C2D33)); c.rect(0, f.band, c.w, s, C(0x3E4048))

        // The squat rack on the left: two steel uprights, holes up them, a crossbar on top, the bar on its hooks
        // with big red plates either side.
        let rx = c.w * 5 / 100, rw = 40 * s
        let steel = C(0x6A6E78), steelL = C(0x9A9EA8), steelD = C(0x40434C)
        for ux in [rx + 6 * s, rx + rw - 9 * s] {
            c.rect(ux, g - 46 * s, 3 * s, 46 * s, steel); c.rect(ux, g - 46 * s, s, 46 * s, steelL); c.rect(ux + 2 * s, g - 46 * s, s, 46 * s, steelD)
            for y in stride(from: g - 42 * s, to: g - 4 * s, by: 4 * s) { c.rect(ux + s, y, s, s, C(0x22242A)) }
            c.rect(ux - 2 * s, g - s, 7 * s, s, steelD)
        }
        c.rect(rx + 6 * s, g - 46 * s, rw - 12 * s, 3 * s, steel); c.rect(rx + 6 * s, g - 46 * s, rw - 12 * s, s, steelL)
        let barY = g - 30 * s
        c.rect(rx, barY, rw, 2 * s, C(0xB8BCC4)); c.rect(rx, barY, rw, s, C(0xE0E4EA))
        for (k, ex) in [rx - 3 * s, rx + rw - s].enumerated() {
            let lit = k == 0
            c.rect(ex - 2 * s, barY - 9 * s, 4 * s, 20 * s, C(0xB02828)); c.rect(ex - 2 * s, barY - 9 * s, lit ? 2 * s : s, 20 * s, C(0xD84848))
            c.rect(ex + 2 * s, barY - 7 * s, 2 * s, 16 * s, C(0x8A1E1E))
            c.rect(ex - 2 * s, barY - 9 * s, 4 * s, s, C(0xE86060))
        }

        // The dumbbell rack: a steel frame in two sloped tiers, a row of big dumbbells on each, hex heads and silver
        // handles, the heavier ones on the bottom.
        let dx = c.w * 55 / 100, dw = 52 * s
        for lx in [dx + 2 * s, dx + dw - 5 * s] {
            c.rect(lx, g - 24 * s, 3 * s, 24 * s, steel); c.rect(lx, g - 24 * s, s, 24 * s, steelL); c.rect(lx + 2 * s, g - 24 * s, s, 24 * s, steelD)
        }
        for (tier, ty) in [g - 22 * s, g - 11 * s].enumerated() {
            let big = tier == 1, hw = big ? 4 * s : 3 * s, hh = big ? 8 * s : 7 * s
            for k in 0..<4 {
                let bx = dx + 3 * s + k * 12 * s
                c.rect(bx + hw, ty - hh / 2 - s, 11 * s - 2 * hw, 2 * s, C(0xB8BCC4)); c.rect(bx + hw, ty - hh / 2 - s, 11 * s - 2 * hw, s, C(0xE0E4EA))
                for hx in [bx, bx + 11 * s - hw] {
                    c.rect(hx, ty - hh, hw, hh, C(0x2A2A30)); c.rect(hx, ty - hh, s, hh, C(0x4E4E58)); c.rect(hx, ty - hh, hw, s, C(0x4E4E58))
                }
            }
            c.rect(dx, ty, dw, 3 * s, steel); c.rect(dx, ty, dw, s, steelL); c.rect(dx, ty + 2 * s, dw, s, steelD)
        }

        // The turnstile on the right: a waist-high steel cabinet with a card reader and its green light on top, the
        // three-armed hub on its side (one arm barring the way, the other two angled back), a rail behind it to the
        // wall.
        let tx = c.w * 85 / 100
        c.rect(tx + 8 * s, g - 22 * s, c.w - tx, 3 * s, steel); c.rect(tx + 8 * s, g - 22 * s, c.w - tx, s, steelL)
        for px in [tx + 22 * s, tx + 40 * s] { c.rect(px, g - 22 * s, 3 * s, 22 * s, steelD); c.rect(px, g - 22 * s, s, 22 * s, steel) }
        c.rect(tx, g - 26 * s, 12 * s, 26 * s, steel); c.rect(tx, g - 26 * s, 3 * s, 26 * s, steelL); c.rect(tx + 10 * s, g - 26 * s, 2 * s, 26 * s, steelD)
        c.rect(tx - s, g - 27 * s, 14 * s, 2 * s, steelL)
        c.rect(tx + 3 * s, g - 24 * s, 6 * s, 4 * s, C(0x22242A)); c.rect(tx + 5 * s, g - 23 * s, 2 * s, 2 * s, C(0x4AE070))
        let hub = (x: Double(tx - s), y: Double(g - 16 * s))
        for (a, len, col) in [(180.0, 16.0, C(0xD8DCE4)), (240.0, 9.0, C(0x9A9EA8)), (120.0, 9.0, C(0x9A9EA8))] {
            let e = crawlReach(hub, a, len * Double(s))
            c.glowLine(hub.x, hub.y, e.x, e.y, core: col, glow: C(0, 0), coreR: Double(s) * 1.2, glowR: Double(s) * 1.3)
        }
        c.circle(tx - s, g - 16 * s, 3 * s, C(0x5A5E68)); c.circle(tx - 2 * s, g - 17 * s, s, C(0x9A9EA8))

        // The rubber floor: black tiles, plain, a faint seam every so often.
        c.ground(g, C(0x26262C), edge: C(0x3C3C44), speck: C(0x202026), seed: 83)
        for x in stride(from: 20 * s, to: c.w, by: 40 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x1E1E24)) }
    }

    /// The screen saver's tall ceiling: dark above a steel truss that spans the room (two chords and the zigzag
    /// between them), long red banners hanging from it with a white dumbbell and a swallowtail, and dome lamps on
    /// cords between them; above the truss a big duct along the ceiling.
    private static func crawlGymCeiling(_ c: PixelCanvas, _ g: Int, _ truss: Int, _ hanging: [(x: Int, y: Int)]) {
        let s = unit(g)
        c.gradient(0, truss, C(0x1E1E24), C(0x2E3038), bands: 4)
        // A big round duct running along the ceiling, banded at its joints, hung on straps.
        let dy = truss / 2
        c.rect(0, dy - 7 * s, c.w, 14 * s, C(0x4A4E58)); c.rect(0, dy - 7 * s, c.w, 3 * s, C(0x6E727C)); c.rect(0, dy + 4 * s, c.w, 3 * s, C(0x363942))
        for x in stride(from: 20 * s, to: c.w, by: 48 * s) {
            c.rect(x, dy - 8 * s, 3 * s, 16 * s, C(0x5A5E68)); c.rect(x, dy - 8 * s, s, 16 * s, C(0x7A7E88))
            c.rect(x + s, 0, s, dy - 8 * s, C(0x26282E))
        }
        let steel = C(0x4A4E58), steelL = C(0x6A6E78)
        let h = 12 * s
        c.rect(0, truss, c.w, 3 * s, steel); c.rect(0, truss, c.w, s, steelL)
        c.rect(0, truss + h, c.w, 3 * s, steel); c.rect(0, truss + h, c.w, s, steelL)
        for x in stride(from: 0, to: c.w + h, by: h) {
            let up = (x / h) % 2 == 0
            c.glowLine(Double(x), Double(up ? truss + h : truss + 2 * s), Double(x + h), Double(up ? truss + 2 * s : truss + h), core: steel, glow: C(0, 0), coreR: Double(s), glowR: Double(s) * 1.1)
        }
        // The banners.
        let emblem = ["##.........##", "##.........##", "#############", "##.........##", "##.........##"]
        for fx in [12, 37, 63, 88] {
            let x = c.w * fx / 100, w = 24 * s, top = truss + h + 3 * s, len = 80 * s
            c.rect(x - w / 2, top, w, len, C(0xA02828)); c.rect(x - w / 2, top, 2 * s, len, C(0xC03838))
            c.rect(x - w / 2, top, w, 2 * s, C(0x2A1A1E)); c.rect(x - w / 2 + 2 * s, top + 4 * s, w - 4 * s, s, C(0xE0B040))
            c.rect(x - w / 2 + 2 * s, top + len - 8 * s, w - 4 * s, s, C(0xE0B040))
            for k in 0..<(w / 2) where k < w / 2 {
                c.rect(x - w / 2 + k, top + len, 1, w / 2 - k, C(0xA02828)); c.rect(x + w / 2 - 1 - k, top + len, 1, w / 2 - k, C(0xA02828))
            }
            crawlStamp(c, x - 13 * s, top + 20 * s, emblem, C(0xF0ECE4), 2 * s)
        }
        // The dome lamps on their cords, a pool of light under each.
        for l in hanging {
            c.rect(l.x, truss + h + 3 * s, s, l.y - truss - h - 3 * s, C(0x1A1A1E))
            c.ellipse(l.x, l.y + 10 * s, 14 * s, 10 * s, C(0xFFF0C0, 0.06))
            c.rect(l.x - 6 * s, l.y + 2 * s, 13 * s, 3 * s, C(0x3A3D46)); c.rect(l.x - 3 * s, l.y, 7 * s, 2 * s, C(0x3A3D46))
            c.rect(l.x - 6 * s, l.y + 2 * s, 13 * s, s, C(0x5A5E68)); c.rect(l.x - 3 * s, l.y + 5 * s, 7 * s, s, C(0xFFF0C8))
        }
    }

    /// The gym's life: every few seconds the boss music hits and the lights pulse red with the beat, the lamps
    /// glowing red and a faint red wash thumping over the walls; between hits, nothing moves.
    static func crawlGymLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlGymFrame(c, g)
        let into = t.truncatingRemainder(dividingBy: 6.0)
        guard into < 2.4 else { return }
        let beat = (into * 2.5).truncatingRemainder(dividingBy: 1), k = 1 - beat
        c.rect(0, 0, c.w, f.band, C(0xFF2020, 0.07 * k))
        for l in f.lamps {
            c.ellipse(l.x, l.y + 2 * s, 14 * s, 10 * s, C(0xFF3030, 0.16 * k))
            c.rect(l.x - 2 * s, l.y, 4 * s, 4 * s, C(0xFF4040, 0.5 + 0.5 * k)); c.rect(l.x - 2 * s, l.y + 2 * s, 4 * s, s, C(0x2A2B31))
        }
        for l in f.hanging {
            c.ellipse(l.x, l.y + 10 * s, 16 * s, 12 * s, C(0xFF3030, 0.14 * k))
            c.rect(l.x - 3 * s, l.y + 5 * s, 7 * s, s, C(0xFF4040, 0.5 + 0.5 * k))
        }
    }
}
