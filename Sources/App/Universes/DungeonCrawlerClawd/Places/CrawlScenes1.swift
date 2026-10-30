import Foundation

// Places, a few to a file: each one a `Place` in the dictionary below (its name, the tint of the window's card area
// under it, its still picture and what moves there) and its drawing in an extension of `Scenes`. Check them with
// `build/preview place out.png <key>`, which draws each at window size and at screen-saver size.
//
// The rules, from the clawdify guide's "Look and style": the same pixel art as the crew, flat colours, two or three
// tones a material, the light from the front left; the floor and the band just above it plain and mid-to-dark, the
// busy detail higher up and at the sides; props sized in `Scenes.unit(g)` steps; something in the screen saver's upper
// part; a light, subtle moving layer; text short and big enough to read, or left out.

let crawlScenes1: [Location: Place] = [
    .crawlSafeRoom: Place(name: "A safe room", panel: 0x1E140E, still: Scenes.crawlSafeRoom, moving: Scenes.crawlSafeRoomLife),
]

// MARK: - A safe room

extension Scenes {
    /// Where things stand in the safe room, shared by the still picture and the moving layer so they line up: the
    /// wainscot's top, the TV's box, the System sign's box, the bar's left edge and top, and (on the screen saver) the
    /// vault's spring line and the lanterns.
    static func crawlSafeRoomFrame(_ c: PixelCanvas, _ g: Int) -> (wainscot: Int, tv: (x: Int, y: Int, w: Int, h: Int),
                                                                     sign: (x: Int, y: Int, w: Int, h: Int),
                                                                     bar: (x: Int, top: Int), vault: Int, lanterns: [(Int, Int)]) {
        let s = unit(g), tall = isTall(c)
        let tv = (x: c.w * 30 / 100, y: g - 36 * s, w: 24 * s, h: 15 * s)
        let label = "SAFE ROOM", sw = crawlTextWidth(label, scale: s) + 6 * s
        let sign = (x: c.w * 52 / 100 - sw / 2, y: g - 38 * s, w: sw, h: 11 * s)
        let vault = tall ? g * 30 / 100 : -1
        let lanterns = tall ? (0..<5).map { k in (c.w * (10 + k * 20) / 100, vault + 24 * s + (k % 2) * 10 * s) } : []
        return (g - 13 * s, tv, sign, (x: c.w * 64 / 100, top: g - 17 * s), vault, lanterns)
    }

    /// A safe room: a cosy pub tucked into the dungeon, where no mob can follow. Warm wood panelling under rough stone,
    /// a wainscot along the floor, a chalkboard of the day's specials on the left, a TV on the wall for the recap
    /// episode, a glowing blue System sign over it all (SAFE ROOM), and on the right the bar: its counter, bottles on
    /// a shelf behind it, a row of taps and two stools in front. The floor is dark boards. On the screen saver the
    /// stone rises into a vault with hanging lanterns.
    static func crawlSafeRoom(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlSafeRoomFrame(c, g)
        let stone = C(0x4A4440), stoneD = C(0x34302E), stoneL = C(0x5E5852)
        let wood = C(0x6A4428), woodD = C(0x4A2E1A), woodL = C(0x86583A)

        // The stone behind it all: rough blocks in courses, each lit along its top, the mortar dark.
        c.rect(0, 0, c.w, g, stone)
        for row in 0..<(g / (6 * s) + 1) {
            let y = g - (row + 1) * 6 * s, shift = row % 2 == 0 ? 0 : 7 * s
            c.rect(0, y, c.w, s, stoneD)
            for x in stride(from: -shift, to: c.w, by: 14 * s) {
                c.rect(x, y, s, 6 * s, stoneD)
                c.rect(x + s, y + s, 13 * s, s, stoneL)
                if noise(row * 37 + x / max(1, s)) > 0.7 { c.rect(x + 4 * s, y + 3 * s, 3 * s, s, stoneD) }
            }
        }
        // On the screen saver: the vault above, dark, its ribs springing from stone pillars; on the wall between the
        // pillars, torches in iron sconces and a banner of the Royal Court (a gold crown on pink); and the lanterns
        // hanging on their chains, a warm glow round each.
        if tall {
            c.gradient(0, f.vault, C(0x16120F), C(0x2E2824), bands: 5)
            let bay = c.w / 4
            for x in stride(from: 0, through: c.w, by: bay) {
                for k in 0...(bay / 2) {
                    let y = f.vault - Int((1 - pow(Double(k) / Double(bay / 2), 2)).squareRoot() * Double(min(f.vault, bay / 3)))
                    c.rect(x + k, y, max(1, s), 2 * s, stoneD); c.rect(x + bay - k, y, max(1, s), 2 * s, stoneD)
                }
                c.rect(x - 3 * s, f.vault, 6 * s, g - f.vault, stoneD); c.rect(x - 3 * s, f.vault, s, g - f.vault, stoneL)
            }
            for k in 0..<4 {
                let x = k * bay + bay / 2, y = f.vault + (g - f.vault) / 3
                if k % 2 == 0 {
                    c.rect(x - 7 * s, y, 14 * s, 20 * s, C(0xC04E8E)); c.rect(x - 7 * s, y, 2 * s, 20 * s, C(0xF07AB8))
                    c.rect(x - 8 * s, y - s, 16 * s, 2 * s, C(0x3A2A1A))
                    for j in 0..<3 { c.rect(x - 7 * s + j * 5 * s, y + 20 * s, 4 * s, 2 * s, C(0xC04E8E)) }
                    c.rect(x - 4 * s, y + 7 * s, 8 * s, 4 * s, C(0xF0C840)); c.rect(x - 4 * s, y + 10 * s, 8 * s, s, C(0xB88A20))
                    for j in [-4, -1, 2] { c.rect(x + j * s, y + 5 * s, 2 * s, 2 * s, C(0xF0C840)) }
                } else {
                    c.rect(x - 2 * s, y + 6 * s, 4 * s, 2 * s, C(0x2A2A30)); c.rect(x - s, y + 2 * s, 2 * s, 5 * s, C(0x4A3020))
                    c.ellipse(x, y, 10 * s, 8 * s, C(0xFF9A40, 0.10))
                    c.rect(x - s, y - s, 2 * s, 3 * s, C(0xF0A030))
                }
            }
            for (x, y) in f.lanterns {
                c.rect(x, 0, max(1, s), y, C(0x1A1410))
                c.rect(x - 2 * s, y, 5 * s, 6 * s, C(0x2A1E14)); c.rect(x - s, y + s, 3 * s, 4 * s, C(0xF0B050))
                c.rect(x - 3 * s, y + 6 * s, 7 * s, s, C(0x2A1E14))
                c.ellipse(x, y + 3 * s, 8 * s, 6 * s, C(0xFFB050, 0.10))
            }
        }

        // The panelling: warm wood up to above the TV, in boards, a rail along its top.
        let panelTop = g - 44 * s
        c.rect(0, panelTop, c.w, g - panelTop, wood)
        for x in stride(from: 0, to: c.w, by: 9 * s) { c.rect(x, panelTop, s, g - panelTop, woodD); c.rect(x + s, panelTop, s, g - panelTop, woodL) }
        c.rect(0, panelTop - 2 * s, c.w, 2 * s, woodD); c.rect(0, panelTop - 2 * s, c.w, s, woodL)
        // The wainscot along the floor, darker, its rail lit.
        c.rect(0, f.wainscot, c.w, g - f.wainscot, woodD)
        for x in stride(from: 4 * s, to: c.w, by: 12 * s) { c.rect(x, f.wainscot + 3 * s, 8 * s, 7 * s, C(0x3E2614)); c.rect(x, f.wainscot + 3 * s, 8 * s, s, C(0x2E1C0E)) }
        c.rect(0, f.wainscot - s, c.w, 2 * s, wood); c.rect(0, f.wainscot - s, c.w, s, woodL)

        // The chalkboard of specials on the left: a wooden frame, chalk lines, a little drawn mug.
        let cb = (x: c.w * 6 / 100, y: g - 34 * s, w: 20 * s, h: 15 * s)
        c.rect(cb.x - s, cb.y - s, cb.w + 2 * s, cb.h + 2 * s, woodD); c.rect(cb.x - s, cb.y - s, cb.w + 2 * s, s, woodL)
        c.rect(cb.x, cb.y, cb.w, cb.h, C(0x22302A))
        for (k, len) in [14, 10, 12, 8].enumerated() { c.rect(cb.x + 2 * s, cb.y + (2 + k * 3) * s, len * s, s, C(0xD8DCD0, 0.75)) }
        c.rect(cb.x + 16 * s, cb.y + 8 * s, 2 * s, 3 * s, C(0xE8E0B0, 0.8)); c.rect(cb.x + 18 * s, cb.y + 9 * s, s, s, C(0xE8E0B0, 0.8))

        // The System sign: a glowing blue box with white letters, the books' own interface.
        let sg = f.sign
        c.rect(sg.x - s, sg.y - s, sg.w + 2 * s, sg.h + 2 * s, C(0x3A8CFF, 0.25))
        c.rect(sg.x, sg.y, sg.w, sg.h, C(0x0E2A6A)); c.rect(sg.x, sg.y, sg.w, s, C(0x6AB4FF)); c.rect(sg.x, sg.y + sg.h - s, sg.w, s, C(0x2A64C8))
        c.rect(sg.x, sg.y, s, sg.h, C(0x6AB4FF)); c.rect(sg.x + sg.w - s, sg.y, s, sg.h, C(0x2A64C8))
        crawlText(c, sg.x + 3 * s, sg.y + 3 * s, "SAFE ROOM", C(0xF0F6FF), scale: s)

        // The TV on its bracket, the screen dark here (the moving layer plays the recap on it).
        let tv = f.tv
        c.rect(tv.x + tv.w / 2 - s, tv.y + tv.h, 2 * s, 3 * s, C(0x2A2A30))
        c.rect(tv.x - s, tv.y - s, tv.w + 2 * s, tv.h + 2 * s, C(0x1A1A20)); c.rect(tv.x - s, tv.y - s, tv.w + 2 * s, s, C(0x3A3A44))
        c.rect(tv.x, tv.y, tv.w, tv.h, C(0x10161E))

        // The bar on the right: the shelf of bottles behind it, the counter with its lit top edge and panelled front,
        // the taps, two stools in front.
        let b = f.bar, bw = c.w - b.x
        c.rect(b.x, g - 32 * s, bw, 2 * s, woodD); c.rect(b.x, g - 32 * s, bw, s, woodL)
        for k in 0..<(bw / (4 * s)) {
            let x = b.x + 2 * s + k * 4 * s, h = (4 + Int(noise(k + 71) * 3)) * s
            let col = [C(0x3A7A3A), C(0x8A3A2A), C(0xC89A3A), C(0x3A5A8A)][k % 4]
            c.rect(x, g - 32 * s - h, 2 * s, h, col); c.rect(x, g - 32 * s - h - s, s, s, C(0x2A2A2A)); c.rect(x, g - 32 * s - h + s, s, h - 2 * s, col.alpha(0.6))
        }
        c.rect(b.x, b.top, bw, g - b.top, C(0x5A3820))
        for x in stride(from: b.x + 3 * s, to: c.w, by: 10 * s) { c.rect(x, b.top + 5 * s, 7 * s, 8 * s, C(0x4A2C18)); c.rect(x, b.top + 5 * s, 7 * s, s, C(0x3A2010)) }
        c.rect(b.x - 2 * s, b.top - 2 * s, bw + 2 * s, 3 * s, C(0x7A5030)); c.rect(b.x - 2 * s, b.top - 2 * s, bw + 2 * s, s, C(0xA07048))
        for k in 0..<3 {
            let x = b.x + 6 * s + k * 5 * s
            c.rect(x, b.top - 7 * s, s, 5 * s, C(0xC8CCD4)); c.rect(x - s, b.top - 8 * s, 3 * s, s, C(0x8A3A2A))
        }
        for x in [b.x - 10 * s, b.x + 12 * s] {
            c.rect(x, g - 9 * s, 7 * s, 2 * s, C(0x8A2A22)); c.rect(x, g - 9 * s, 7 * s, s, C(0xA83A30))
            c.rect(x + 3 * s, g - 7 * s, s, 7 * s, C(0x2A2A2E)); c.rect(x + s, g - 2 * s, 5 * s, s, C(0x2A2A2E))
        }

        // The floor: dark boards, plain so the crew's outlines and names read on it, the seams running across.
        c.ground(g, C(0x3A2618), edge: C(0x5A3C24), speck: C(0x2E1E12), seed: 41)
        for x in stride(from: 0, to: c.w, by: 16 * s) { c.rect(x, g + 1, s, c.h - g - 1, C(0x2E1E12)) }
        // The warm light of the room pooling on the boards.
        c.ellipse(c.w / 2, g + 3 * s, c.w / 3, 4 * s, C(0xFFB060, 0.06))
    }

    /// The safe room's life: the TV playing the recap episode (a bright scene that cuts every few seconds, a
    /// PREVIOUSLY ON caption in its corner now and then, a flicker of static at each cut), the System sign's glow
    /// breathing, and on the screen saver the lanterns' flames flickering.
    static func crawlSafeRoomLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlSafeRoomFrame(c, g), tv = f.tv
        let cut = Int(t / 3.2), into = t.truncatingRemainder(dividingBy: 3.2)
        if into < 0.15 {
            for y in stride(from: tv.y, to: tv.y + tv.h, by: s) {
                for x in stride(from: tv.x, to: tv.x + tv.w, by: s) where noise(x * 7 + y * 13 + Int(t * 30)) > 0.5 {
                    c.rect(x, y, s, s, C(0xD8E0E8, 0.7))
                }
            }
        } else {
            // A scene: a sky and a ground in the shot's own colours, and two little figures squaring up.
            let skies = [C(0x6A3A8A), C(0xC85A2A), C(0x2A6A9A), C(0x8A2A3A)]
            let grounds = [C(0x3A2A4A), C(0x6A3A1A), C(0x2A4A3A), C(0x3A1A1A)]
            let k = cut % 4
            c.rect(tv.x, tv.y, tv.w, tv.h * 2 / 3, skies[k]); c.rect(tv.x, tv.y + tv.h * 2 / 3, tv.w, tv.h - tv.h * 2 / 3, grounds[k])
            let bob = Int(t * 4) % 2 * s
            c.rect(tv.x + 6 * s, tv.y + 6 * s + bob, 3 * s, 4 * s, C(0xD97757)); c.rect(tv.x + 6 * s, tv.y + 5 * s + bob, 3 * s, s, C(0x5A3A22))
            c.rect(tv.x + 15 * s, tv.y + 5 * s, 4 * s, 5 * s, C(0x7A8A62))
            if cut % 3 == 0 { crawlText(c, tv.x + s, tv.y + s, "PREV", C(0xFFFFFF, 0.9), scale: s) }
            // Scan lines.
            for y in stride(from: tv.y, to: tv.y + tv.h, by: 2 * s) { c.rect(tv.x, y, tv.w, max(1, s / 2), C(0x000000, 0.15)) }
        }
        // The sign's glow, breathing.
        let sg = f.sign, glow = 0.12 + 0.1 * sin(t * 1.6)
        c.rect(sg.x - 2 * s, sg.y - 2 * s, sg.w + 4 * s, s, C(0x3A8CFF, glow)); c.rect(sg.x - 2 * s, sg.y + sg.h + s, sg.w + 4 * s, s, C(0x3A8CFF, glow))
        for (k, l) in f.lanterns.enumerated() where Int(t * 7 + Double(k * 3)) % 4 == 0 {
            c.rect(l.0 - s, l.1 + s, 3 * s, s, C(0xFFE8A0))
        }
        // The torches' flames, flickering (the odd bays of the screen saver's wall).
        if f.vault > 0 {
            let bay = c.w / 4
            for k in [1, 3] {
                let x = k * bay + bay / 2, y = f.vault + (g - f.vault) / 3
                let h = 2 + Int(t * 9 + Double(k)) % 3
                c.rect(x - s, y - h * s, 2 * s, h * s, C(0xF0A030)); c.rect(x, y - (h - 1) * s, s, (h - 1) * s, C(0xFFE8A0))
            }
        }
    }
}
