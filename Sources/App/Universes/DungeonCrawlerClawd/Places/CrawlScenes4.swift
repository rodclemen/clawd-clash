import Foundation

// Places, a few to a file (see CrawlScenes1.swift for the rules): Carl's street the night of the collapse, the Parade,
// the Over City, Grimaldi's circus tent.

let crawlScenes4: [Location: Place] = [
    .crawlSeattle: Place(name: "Carl's street, the night of the collapse", panel: 0x10141E, still: Scenes.crawlSeattle,
                         moving: Scenes.crawlSeattleLife),
    .crawlParade: Place(name: "The Parade", panel: 0x0C1418, still: Scenes.crawlParade, moving: Scenes.crawlParadeLife),
    .crawlOverCity: Place(name: "The Over City", panel: 0x1C2436, still: Scenes.crawlOverCity, moving: Scenes.crawlOverCityLife),
    .crawlCircus: Place(name: "Grimaldi's circus tent", panel: 0x1A1012, still: Scenes.crawlCircus, moving: Scenes.crawlCircusLife),
]

/// Little pixel pictures drawn from rows of letters, each letter a square `cell` pixels wide.
private func crawlSketch(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ palette: [Character: Px], cell: Int) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() {
            if let col = palette[ch] { c.rect(x + k * cell, y + r * cell, cell, cell, col) }
        }
    }
}

/// A cone of light from a lamp at (`x`, `y`) down to row `bottom`, `spread` pixels wide there, in `col`.
private func crawlBeam(_ c: PixelCanvas, _ x: Int, _ y: Int, _ bottom: Int, spread: Int, _ col: Px, lean: Int = 0) {
    guard bottom > y else { return }
    for yy in y..<bottom {
        let k = Double(yy - y) / Double(bottom - y)
        let half = Int(Double(spread / 2) * k) + 1
        let mid = x + Int(Double(lean) * k)
        c.rect(mid - half, yy, half * 2, 1, col)
    }
}

// MARK: - Carl's street, the night of the collapse

extension Scenes {
    /// Where things stand on Carl's street, shared by the still picture and the moving layer: the apartment block's
    /// right edge and (on the screen saver) its roof, Carl's window, the street lamp's head, the corner building that
    /// sinks (its left edge, width, height and the line it sinks behind), and the far tower's beacon.
    static func crawlSeattleFrame(_ c: PixelCanvas, _ g: Int) -> (block: Int, roof: Int, window: (x: Int, y: Int),
                                                                  tree: (x: Int, y: Int), lamp: (x: Int, y: Int),
                                                                  sinker: (x: Int, w: Int, h: Int, base: Int),
                                                                  beacon: (x: Int, y: Int)) {
        let s = unit(g), tall = isTall(c)
        let block = c.w * 36 / 100
        let tree = (x: c.w * 22 / 100, y: g - 38 * s)
        // Carl's window: the second floor, the first column right of the tree's crown.
        var wx = 6 * s
        while wx < tree.x + 10 * s && wx + 18 * s < block - 12 * s { wx += 18 * s }
        let window = (x: wx, y: g - 44 * s)
        let lamp = (x: c.w * 50 / 100 + 9 * s, y: g - 50 * s)
        let sw = 40 * s
        let sinker = (x: c.w * 70 / 100, w: sw, h: 46 * s, base: g - 8 * s)
        let beacon = tall ? (x: c.w * 60 / 100, y: g - 118 * s) : (x: -1, y: -1)
        return (block, tall ? g - 150 * s : -1, window, tree, lamp, sinker, beacon)
    }

    /// Carl's street, the night the world ended: a wet Seattle street in the rain, after midnight. On the left Carl's
    /// apartment block, dull red brick, windows lit here and there, an iron fire escape down its side and a tree
    /// outside his window (lit, the curtains open, where Donut went out); a doorway with a lamp over it. In the middle
    /// a sodium street lamp throws an orange cone onto the pavement; a fire hydrant and a newspaper box stand by the
    /// kerb. On the right the pavement has split open round the corner building's foot (the moving layer sinks it
    /// into the earth), a crack running off along the kerb with the System's blue light glowing up out of it. Behind
    /// it all the low city under a rain-heavy sky lit orange from below. The street is dark wet asphalt with the
    /// lights' reflections in it. On the screen saver the block rises into a tower with a stair hut and an aerial,
    /// and the night sky opens over the city: banks of cloud, the moon breaking through, the Needle far off.
    static func crawlSeattle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlSeattleFrame(c, g)

        // The sky: rain cloud, dark overhead, lit dull orange from below by the city.
        c.gradient(0, g, C(0x0C101C), C(0x2E2A38), bands: tall ? 8 : 5)
        if tall {
            // Banks of cloud, the moon breaking through between two of them.
            let mx = c.w * 82 / 100, my = g * 22 / 100
            c.circle(mx, my, 26 * s, C(0xC8D0E0, 0.05)); c.circle(mx, my, 18 * s, C(0xC8D0E0, 0.07))
            c.circle(mx, my, 10 * s, C(0xD8DCE4)); c.circle(mx + 2 * s, my - 2 * s, 7 * s, C(0xEEF0F4))
            c.rect(mx - 5 * s, my + 3 * s, 3 * s, 2 * s, C(0xB8BECA)); c.rect(mx + 3 * s, my - 6 * s, 2 * s, 2 * s, C(0xC4CAD4))
            let banks: [(Int, Int, Int, Int)] = [(10, 12, 70, 9), (64, 26, 60, 7), (30, 34, 80, 10), (88, 40, 50, 8), (50, 52, 90, 9)]
            for (k, b) in banks.enumerated() {
                let bx = c.w * b.0 / 100, by = g * b.1 / 100, rx = b.2 * s, ry = b.3 * s
                c.ellipse(bx, by + ry / 2, rx, ry, C(0x2A2C3A)); c.ellipse(bx - rx / 3, by, rx / 2, ry, C(0x30323F))
                c.ellipse(bx + rx / 3, by - ry / 3, rx / 2, ry, C(0x2C2E3C))
                c.rect(bx - rx * 2 / 3, by + ry + ry / 2, rx * 4 / 3, s, C(0x4A3A3A, 0.6 + 0.1 * Double(k % 2)))
            }
            // The Needle, far off over the low city: three legs tapering up, the halo of its deck, the spire.
            let nx = f.beacon.x, base = g - 30 * s, needle = C(0x181E2C), deck = f.beacon.y + 12 * s
            for y in stride(from: deck, to: base, by: 1) {
                let k = Double(y - deck) / Double(base - deck)
                let spread = Int(Double(2 * s) + k * Double(9 * s)), waist = Int(Double(s) * (1 - abs(k - 0.35)) * 2)
                c.rect(nx - spread + waist - s, y, 2 * s, 1, needle); c.rect(nx + spread - waist - s, y, 2 * s, 1, needle)
                c.rect(nx - s, y, 2 * s, 1, needle)
            }
            // The saucer: a wide disc flaring out over a narrower ring, its windows lit in a band.
            let disc = C(0x283246)
            for k in 0..<(7 * s) {
                let half = 8 * s + k * 2
                c.rect(nx - half, deck - k, 2 * half, 1, k == 7 * s - 1 ? C(0x3A4660) : disc)
            }
            c.rect(nx - 22 * s, deck - 8 * s, 44 * s, 2 * s, C(0x3A4660)); c.rect(nx - 20 * s, deck - 10 * s, 40 * s, 2 * s, disc)
            c.rect(nx - 14 * s, deck - 13 * s, 28 * s, 3 * s, disc)
            for k in 0..<10 { c.rect(nx - 18 * s + k * 4 * s, deck - 4 * s, 2 * s, s, C(0xE8C070, 0.85)) }
            c.rect(nx - s / 2, f.beacon.y, max(1, s), deck - 13 * s - f.beacon.y, C(0x283246))
            // Taller towers far off.
            for (k, x) in stride(from: c.w * 40 / 100, to: c.w, by: 26 * s).enumerated() where abs(x - nx) > 16 * s {
                let h = (40 + Int(noise(k * 19 + 3) * 46)) * s, w = (12 + Int(noise(k * 7 + 1) * 8)) * s
                c.rect(x, g - 8 * s - h, w, h, C(0x1C2232)); c.rect(x, g - 8 * s - h, s, h, C(0x242A3C))
                for wy in stride(from: g - 8 * s - h + 4 * s, to: g - 30 * s, by: 6 * s) where noise(k * 31 + wy) > 0.78 {
                    c.rect(x + 3 * s + Int(noise(wy + k) * Double(w - 6 * s)), wy, s, s, C(0xD8B070, 0.6))
                }
            }
        }

        // The low city behind the street: flat roofs at different heights, a lit window here and there.
        for (k, x) in stride(from: f.block, to: c.w, by: 22 * s).enumerated() {
            let h = (18 + Int(noise(k * 13 + 7) * 20)) * s, w = (18 + Int(noise(k * 5 + 2) * 10)) * s
            c.rect(x, g - 8 * s - h, w, h, C(0x1A1E2A)); c.rect(x, g - 8 * s - h, w, s, C(0x262A38))
            for wy in stride(from: g - 8 * s - h + 3 * s, to: g - 10 * s, by: 5 * s) {
                for wx in stride(from: x + 3 * s, to: x + w - 3 * s, by: 5 * s) where noise(k * 97 + wx / max(1, s) * 3 + wy) > 0.82 {
                    c.rect(wx, wy, 2 * s, 2 * s, C(0xD8A860, 0.55))
                }
            }
        }
        // A water tower on one roof and an aerial on another, to break the line.
        let wt = c.w * 58 / 100, wtTop = g - 44 * s
        c.rect(wt - 6 * s, wtTop + 13 * s, 20 * s, g - 8 * s - wtTop - 13 * s, C(0x1A1E2A)); c.rect(wt - 6 * s, wtTop + 13 * s, 20 * s, s, C(0x262A38))
        c.rect(wt, wtTop, 8 * s, 7 * s, C(0x22242E)); c.ellipse(wt + 4 * s, wtTop, 4 * s, 2 * s, C(0x22242E))
        for lx in [wt + s, wt + 6 * s] { c.rect(lx, wtTop + 7 * s, s, 6 * s, C(0x1A1C24)) }

        // The pit the corner building stands in: the pavement split round it, dark, the System's blue light coming
        // up through the gap, broken slabs tipped up either side.
        let sk = f.sinker
        c.rect(sk.x - 2 * s, sk.base - s, sk.w + 4 * s, 9 * s, C(0x0C0E14))
        c.rect(sk.x - s, sk.base + 2 * s, sk.w + 2 * s, 2 * s, C(0x3A8CFF, 0.22))
        c.rect(sk.x + 4 * s, sk.base + 4 * s, sk.w - 8 * s, s, C(0x6AB4FF, 0.18))

        // Carl's block: dull red brick in courses, lit from the left, a shadowed right edge.
        let top = f.roof > 0 ? f.roof : 0
        let brick = C(0x4E2E2E), brickD = C(0x3C2224), brickL = C(0x60383A)
        c.rect(0, top, f.block, g - top, brick)
        for y in stride(from: g - 8 * s, to: top, by: -3 * s) {
            c.rect(0, y - s, f.block, max(1, s / 2), brickD)
            let shift = ((g - y) / (3 * s)) % 2 == 0 ? 0 : 3 * s
            for x in stride(from: shift, to: f.block, by: 6 * s) where noise(x * 3 + y) > 0.6 { c.rect(x, y - 3 * s, s, 2 * s, brickL) }
        }
        c.rect(f.block - 4 * s, top, 4 * s, g - top, C(0x2E1A1C)); c.rect(f.block - 4 * s, top, s, g - top, brickD)
        // The floors: a stone sill course under each, windows in a row (some lit warm, one blue with a TV, most dark).
        var row = 0
        for base in stride(from: g - 28 * s, to: top + 6 * s, by: -20 * s) {
            c.rect(0, base, f.block - 4 * s, s, C(0x6A5A52))
            for (k, x) in stride(from: 6 * s, to: f.block - 12 * s, by: 18 * s).enumerated() {
                let wy = base - 14 * s
                if wy < top + 2 * s { continue }
                let carl = row == 0 && x == f.window.x
                let n = noise(row * 41 + k * 17 + 5)
                let pane = carl ? C(0xF0C878) : n > 0.78 ? C(0xE0B868) : n > 0.7 ? C(0x7A9AD8) : C(0x141A26)
                c.rect(x - s, wy - s, 10 * s, 13 * s, C(0x2A1A1A))
                c.rect(x, wy, 8 * s, 11 * s, pane)
                c.rect(x + 4 * s, wy, s, 11 * s, C(0x2A1A1A)); c.rect(x, wy + 5 * s, 8 * s, s, C(0x2A1A1A))
                if carl {
                    // Carl's: the curtains drawn back either side and the lower sash pushed up, open on the night.
                    c.rect(x, wy, 2 * s, 11 * s, C(0xA85838)); c.rect(x + 6 * s, wy, 2 * s, 11 * s, C(0xA85838))
                    c.rect(x + 2 * s, wy + 6 * s, 4 * s, 5 * s, C(0x2A2018))
                    c.rect(x - s, wy + 11 * s, 10 * s, s, C(0x8A7A6E))
                } else if n > 0.7 {
                    c.rect(x, wy, 8 * s, s, pane.alpha(0.6))
                }
                c.rect(x - s, wy + 12 * s, 10 * s, s, C(0x6A5A52))
            }
            row += 1
        }
        // On the screen saver: the roof, a parapet with a stone cap, the stair hut and an aerial.
        if f.roof > 0 {
            c.rect(0, f.roof - 4 * s, f.block, 4 * s, C(0x5A4A44)); c.rect(0, f.roof - 4 * s, f.block, s, C(0x7A6A62))
            let hx = f.block / 3
            c.rect(hx, f.roof - 18 * s, 22 * s, 14 * s, C(0x3E2628)); c.rect(hx, f.roof - 18 * s, 22 * s, s, C(0x5A4A44))
            c.rect(hx + 8 * s, f.roof - 14 * s, 6 * s, 10 * s, C(0x1A1214))
            let ax = f.block * 2 / 3
            c.rect(ax, f.roof - 40 * s, s, 36 * s, C(0x22222A))
            for (k, w) in [10, 7, 4].enumerated() { c.rect(ax - w * s / 2, f.roof - (34 - k * 8) * s, w * s, s, C(0x22222A)) }
        }
        // The fire escape down the block's right side: a black iron landing at each floor, a stair between.
        let fe = f.block - 22 * s
        for base in stride(from: g - 28 * s, to: top + 20 * s, by: -20 * s) {
            c.rect(fe, base, 16 * s, s, C(0x121318)); c.rect(fe, base - 5 * s, 16 * s, s, C(0x121318))
            for x in stride(from: fe, through: fe + 16 * s, by: 4 * s) { c.rect(x, base - 5 * s, max(1, s / 2), 5 * s, C(0x121318)) }
            for k in 0..<16 { c.rect(fe + 14 * s - k * s, base + s + k * s, s, s, C(0x121318)) }
        }

        // The door: a recess, a lamp over it, three steps.
        let dx = 10 * s
        c.rect(dx - 2 * s, g - 26 * s, 16 * s, 18 * s, C(0x3A2A26)); c.rect(dx, g - 24 * s, 12 * s, 16 * s, C(0x241818))
        c.rect(dx + s, g - 23 * s, 10 * s, 5 * s, C(0x8A7050)); c.rect(dx + 6 * s, g - 23 * s, s, 5 * s, C(0x3A2A26))
        c.rect(dx + 9 * s, g - 15 * s, s, 2 * s, C(0xC8A048))
        c.rect(dx + 4 * s, g - 30 * s, 4 * s, 3 * s, C(0xF0D090)); c.ellipse(dx + 6 * s, g - 28 * s, 10 * s, 6 * s, C(0xF0C070, 0.08))
        for k in 0..<2 { c.rect(dx - (3 + k) * s, g - (8 - k * 3) * s, (18 + 2 * k) * s, 3 * s, k == 0 ? C(0x5A5458) : C(0x4A4448)) }

        // The tree outside Carl's window: a dark trunk out of a square of earth, a crown of night-green leaves in
        // clumps, lit along their left edges.
        let tr = f.tree
        c.rect(tr.x - 2 * s, tr.y, 4 * s, g - 2 * s - tr.y, C(0x2A2018)); c.rect(tr.x - 2 * s, tr.y, s, g - 2 * s - tr.y, C(0x3E3022))
        c.rect(tr.x - 6 * s, tr.y + 10 * s, 5 * s, s, C(0x2A2018)); c.rect(tr.x + 2 * s, tr.y + 6 * s, 6 * s, s, C(0x2A2018))
        let clumps: [(Int, Int, Int, Int)] = [(-10, 2, 9, 7), (8, 0, 10, 7), (-2, -6, 11, 8), (0, 6, 12, 6), (-12, -6, 6, 5), (12, -6, 6, 5)]
        for (dx, dy, rx, ry) in clumps { c.ellipse(tr.x + dx * s, tr.y + dy * s, rx * s, ry * s, C(0x1E3424)) }
        for (dx, dy, rx, ry) in clumps { c.ellipse(tr.x + dx * s - 2 * s, tr.y + dy * s - s, rx * s - 3 * s, ry * s - 2 * s, C(0x284430)) }
        for (dx, dy, _, _) in clumps { c.rect(tr.x + dx * s - 5 * s, tr.y + dy * s - 3 * s, 2 * s, s, C(0x3A5A40)) }
        c.rect(tr.x - 4 * s, g - 2 * s, 8 * s, 2 * s, C(0x241C14))

        // The pavement: concrete slabs, lit along the front, the joints dark, the kerb's lip at the street.
        c.rect(0, g - 8 * s, c.w, 8 * s, C(0x363A44)); c.rect(0, g - 8 * s, c.w, s, C(0x464A56))
        for x in stride(from: 4 * s, to: c.w, by: 18 * s) { c.rect(x, g - 7 * s, max(1, s / 2), 6 * s, C(0x2A2E36)) }
        c.rect(0, g - 2 * s, c.w, 2 * s, C(0x4A4E5A))
        // The crack: from the pit off to the left along the kerb, its edges black, blue light at the bottom of it.
        var cx = sk.x, cy = g - 4 * s
        for k in 0..<18 {
            let nx = cx - (4 + Int(noise(k * 3 + 11) * 4)) * s, ny = g - (2 + Int(noise(k * 5 + 1) * 5)) * s
            let step = nx < cx ? -s : s
            var x = cx
            while x != nx { let y = cy + (ny - cy) * (x - cx) / (nx - cx == 0 ? 1 : nx - cx); c.rect(x, y, s, s, C(0x0C0E14)); c.rect(x, y + s, s, max(1, s / 2), C(0x3A8CFF, 0.3)); x += step }
            cx = nx; cy = ny
            if cx < c.w * 56 / 100 { break }
        }
        // Tipped slabs at the pit's sides.
        c.rect(sk.x - 8 * s, sk.base - 3 * s, 7 * s, 2 * s, C(0x464A56)); c.rect(sk.x - 7 * s, sk.base - s, 5 * s, 2 * s, C(0x2A2E36))
        c.rect(sk.x + sk.w + s, sk.base - 2 * s, 7 * s, 2 * s, C(0x464A56)); c.rect(sk.x + sk.w + 2 * s, sk.base, 5 * s, 2 * s, C(0x2A2E36))

        // The far right: the next building along, dark, a lit window or two, so the street doesn't stop short.
        let nx = sk.x + sk.w + 12 * s
        if nx < c.w {
            c.rect(nx, top, c.w - nx, g - 8 * s - top, C(0x2A2830)); c.rect(nx, top, s, g - 8 * s - top, C(0x3A3842))
            for y in stride(from: g - 26 * s, to: top + 4 * s, by: -16 * s) {
                for x in stride(from: nx + 5 * s, to: c.w - 4 * s, by: 14 * s) {
                    let lit = noise(x + y * 3) > 0.7
                    c.rect(x, y, 7 * s, 9 * s, lit ? C(0xD8B068) : C(0x141820)); c.rect(x + 3 * s, y, s, 9 * s, C(0x2A2830))
                }
            }
        }

        // The street lamp: a grey pole on a foot, its arm out over the street, the head; its orange cone and the
        // pool it throws on the pavement.
        let lp = f.lamp, px = lp.x - 9 * s
        crawlBeam(c, lp.x, lp.y + 2 * s, g, spread: 34 * s, C(0xFFA040, 0.05))
        c.ellipse(lp.x, g - 4 * s, 20 * s, 4 * s, C(0xFFA040, 0.08))
        c.rect(px - s, lp.y - 2 * s, 2 * s, g - 2 * s - lp.y, C(0x3A3E48)); c.rect(px - s, lp.y - 2 * s, s, g - 2 * s - lp.y, C(0x525664))
        c.rect(px - 2 * s, g - 4 * s, 4 * s, 2 * s, C(0x2A2E36))
        c.rect(px, lp.y - 2 * s, 10 * s, s, C(0x3A3E48)); c.rect(lp.x - 3 * s, lp.y - s, 6 * s, 2 * s, C(0x2A2E36))
        c.rect(lp.x - 2 * s, lp.y + s, 4 * s, s, C(0xFFC870))
        // The hydrant and the newspaper box by the kerb.
        let hy = c.w * 60 / 100
        c.rect(hy, g - 7 * s, 4 * s, 5 * s, C(0x9A2A24)); c.rect(hy, g - 7 * s, s, 5 * s, C(0xC04034))
        c.rect(hy - s, g - 6 * s, 6 * s, s, C(0x9A2A24)); c.rect(hy + s, g - 8 * s, 2 * s, s, C(0x9A2A24))
        let nb = c.w * 42 / 100
        c.rect(nb, g - 12 * s, 7 * s, 9 * s, C(0x2A4A8A)); c.rect(nb, g - 12 * s, 7 * s, s, C(0x4A6AAA))
        c.rect(nb + s, g - 10 * s, 5 * s, 3 * s, C(0xC8C8C0)); c.rect(nb + s, g - 4 * s, s, 2 * s, C(0x1A2A4A)); c.rect(nb + 5 * s, g - 4 * s, s, 2 * s, C(0x1A2A4A))

        // The street: dark wet asphalt, the lights' reflections broken up in it, a faded line down the middle.
        c.ground(g, C(0x1C2028), edge: C(0x5A5E6A), speck: C(0x16191F), seed: 73)
        for y in stride(from: g + 2 * s, to: c.h, by: 2 * s) {
            c.rect(lp.x - 3 * s + Int(noise(y) * 4) * s, y, 3 * s, s, C(0xFFA040, 0.14))
            c.rect(f.window.x + 2 * s + Int(noise(y + 9) * 3) * s, y, 2 * s, s, C(0xF0C878, 0.07))
        }
        let mid = g + (c.h - g) * 2 / 3
        for x in stride(from: 4 * s, to: c.w, by: 20 * s) { c.rect(x, mid, 9 * s, max(1, s / 2), C(0x8A7A40, 0.35)) }
    }

    /// The corner building that sinks: three floors of grey-green stucco with a flat roof, windows (a few lit), and a
    /// corner shop at the bottom under a striped awning, `drop` pixels down into the pit and leaning a little to the
    /// right as it goes, nothing drawn below the pit's line; `a` fades it.
    private static func crawlSeattleSinker(_ c: PixelCanvas, _ g: Int, drop: Int, lean: Int, a: Double) {
        let s = unit(g), f = crawlSeattleFrame(c, g), sk = f.sinker, bw = sk.w / s
        let top = sk.base - sk.h + drop
        func put(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) {
            for k in 0..<w {
                let tilt = (u + k) * lean / max(1, bw)
                let y0 = top + (v + tilt) * s, y1 = min(sk.base, y0 + h * s)
                if y1 > y0 { c.rect(sk.x + (u + k) * s, y0, s, y1 - y0, col.alpha(a)) }
            }
        }
        let bh = sk.h / s
        put(0, 0, bw, bh, C(0x4A5A5E)); put(0, 0, 3, bh, C(0x5A6A6E)); put(bw - 4, 0, 4, bh, C(0x38464A))
        put(-1, 0, bw + 2, 3, C(0x3A4448)); put(-1, 0, bw + 2, 1, C(0x5E6A6E))
        for (r, v) in [6, 18].enumerated() {
            for (k, u) in [5, 17, 29].enumerated() {
                let lit = (r + k) % 3 == 1
                put(u - 1, v - 1, 8, 10, C(0x2A3236))
                put(u, v, 6, 8, lit ? C(0xD8B068) : C(0x141A22)); put(u + 3, v, 1, 8, C(0x2A3236))
            }
        }
        // The corner shop: its striped awning, the lit window, the door.
        for k in 0..<(bw / 4) { put(k * 4, 30, 4, 3, k % 2 == 0 ? C(0x8A3030) : C(0xB8B0A0)) }
        put(0, 33, bw, 1, C(0x2A2424))
        put(3, 35, 22, 9, C(0x2A3236)); put(4, 36, 20, 8, C(0xC8A858, 0.75)); put(14, 36, 1, 8, C(0x2A3236))
        put(29, 35, 7, 11, C(0x1A1E22)); put(34, 40, 1, 2, C(0xC8A048))
    }

    /// The street's life: the rain coming down slantwise over everything and splashing on the street; the corner
    /// building sinking slowly into the pit, leaning as it goes, dust puffing up at its foot, until it's gone (it
    /// stands again a while later, for the next one); the street lamp buzzing; and on the screen saver the Needle's
    /// beacon blinking red.
    static func crawlSeattleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlSeattleFrame(c, g), sk = f.sinker

        // The sinking: 30 seconds a round. It fades up standing, sinks for 24 seconds, fades out, and is gone a while.
        let into = t.truncatingRemainder(dividingBy: 30)
        let sink = min(1, max(0, (into - 1.5) / 24))
        var a = 1.0
        if into < 1.5 { a = into / 1.5 }
        if into > 25.5 { a = max(0, 1 - (into - 25.5) / 1.5) }
        if a > 0 {
            let drop = Int(sink * 24) * s, lean = Int(sink * 5)
            crawlSeattleSinker(c, g, drop: drop, lean: lean, a: a)
            // The pit's broken lip over its foot, and dust puffing up while it goes down.
            c.rect(sk.x - 2 * s, sk.base - s, sk.w + 4 * s, 2 * s, C(0x0C0E14))
            c.rect(sk.x - s, sk.base, sk.w + 2 * s, s, C(0x3A8CFF, 0.25))
            if sink > 0, sink < 1 {
                for k in 0..<7 {
                    let ph = (t * 0.7 + Double(k) * 0.37).truncatingRemainder(dividingBy: 1)
                    let dx = sk.x + Int(Double(sk.w) * noise(k * 13 + Int(t * 0.7))), dy = sk.base - Int(ph * Double(10 * s))
                    c.ellipse(dx, dy, (3 + k % 3) * s, (2 + k % 2) * s, C(0x8A8A90, 0.16 * (1 - ph) * a))
                }
            }
        }

        // The rain: thin pale streaks falling slantwise, fast.
        let count = c.w * c.h / (160 * s * s)
        let fall = Double(c.h + 20 * s)
        for i in 0..<count {
            let speed = 1.6 + noise(i * 7 + 2) * 0.5
            let y = Int((noise(i * 7 + 1) * fall + t * Double(c.h) * speed).truncatingRemainder(dividingBy: fall)) - 10 * s
            let x = Int(noise(i * 7) * Double(c.w + 20 * s)) - y / 4
            let col = C(0xB8C8E8, 0.22 + 0.12 * noise(i * 7 + 3))
            for k in 0..<4 { c.rect(x - k * s / 4, y + k * s, max(1, s / 2) + (s > 1 ? s / 2 : 0), s, col) }
        }
        // Splashes on the street: a tick up either side where a drop lands.
        for i in 0..<(c.w / (14 * s)) {
            let ph = (t * 2.2 + noise(i * 5 + 4) * 7).truncatingRemainder(dividingBy: 1)
            guard ph < 0.25 else { continue }
            let x = Int(noise(i * 5 + Int(t * 2.2 + noise(i * 5 + 4) * 7)) * Double(c.w))
            let y = g + 2 * s + Int(noise(i * 5 + 1) * Double(max(1, c.h - g - 4 * s)))
            c.rect(x - s, y - s, s, s, C(0xC8D8F0, 0.5)); c.rect(x + s, y - s, s, s, C(0xC8D8F0, 0.5))
        }
        // The lamp buzzing: a flicker now and then.
        let lp = f.lamp, buzz = t.truncatingRemainder(dividingBy: 7.0)
        if !(buzz > 6.3 && Int(t * 18) % 2 == 0) {
            c.rect(lp.x - 2 * s, lp.y + s, 4 * s, s, C(0xFFE0A0)); c.ellipse(lp.x, lp.y + 2 * s, 6 * s, 3 * s, C(0xFFB050, 0.12))
        }
        // The Needle's beacon.
        if f.beacon.y > 0 && Int(t * 1.2) % 2 == 0 {
            c.rect(f.beacon.x - s, f.beacon.y - 2 * s, 2 * s, 2 * s, C(0xFF4040)); c.circle(f.beacon.x, f.beacon.y - s, 3 * s, C(0xFF4040, 0.2))
        }
    }
}

// MARK: - The Parade

/// Doctor Bones's face for the front of his booth: a white skull under a gold crown.
private let crawlBonesSkull = [
    ".y.y.y.",
    ".yyyyy.",
    ".wwwww.",
    "wwwwwww",
    "wkkwkkw",
    "wkkwkkw",
    "wwwkwww",
    ".wwwww.",
    ".w.w.w.",
]

extension Scenes {
    /// Where things stand on the Parade, shared by the still picture and the moving layer: the light rig's truss,
    /// the lamps hanging from it (each with its colour), the disco ball, the marquee, the booth, the stage riser's
    /// top, and (on the screen saver) the balconies' floors.
    static func crawlParadeFrame(_ c: PixelCanvas, _ g: Int) -> (truss: Int, cans: [(x: Int, col: Px)], ball: (x: Int, y: Int, r: Int),
                                                                sign: (x: Int, y: Int, w: Int, h: Int), booth: (x: Int, w: Int, top: Int),
                                                                riser: Int, tiers: [Int]) {
        let s = unit(g), tall = isTall(c)
        let truss = g - 60 * s
        let cols = [C(0xFF4AB0), C(0x40E0F0), C(0xB8F040), C(0xFFB040)]
        let cans: [(x: Int, col: Px)] = [8, 20, 34, 46, 66, 80, 92].enumerated().map { k, p in (x: c.w * p / 100, col: cols[k % 4]) }
        let ball = (x: c.w * 56 / 100, y: g - 38 * s, r: 10 * s)
        let sw = crawlTextWidth("PARADE", scale: 3 * s) + 8 * s, sh = 15 * s + 8 * s
        let sign = (x: c.w * 30 / 100 - sw / 2, y: g - 48 * s, w: sw, h: sh)
        let booth = (x: c.w * 72 / 100, w: 50 * s, top: g - 21 * s)
        let tiers = tall ? [truss - 70 * s, truss - 150 * s] : []
        return (truss, cans, ball, sign, booth, g - 8 * s, tiers)
    }

    /// The disco ball: a sphere of little mirror tiles turned to `turn` (0...1 a full turn), each tile a silver of its
    /// own, brighter towards the top left, with a hot glint now and then.
    static func crawlParadeBall(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, _ s: Int, turn: Double) {
        let tones = [C(0x5A6070), C(0x8A92A4), C(0xB4BCCC), C(0x6E7688), C(0xD8E0EC)]
        let tile = 2 * s
        for dy in stride(from: -r, to: r, by: s) {
            for dx in stride(from: -r, to: r, by: s) {
                let x = Double(dx) + Double(s) / 2, y = Double(dy) + Double(s) / 2
                let d2 = x * x + y * y, rr = Double(r * r)
                if d2 > rr { continue }
                // The tile under this pixel: its column follows the sphere's turn, its row the latitude.
                let lon = asin(max(-1, min(1, x / max(1, (rr - y * y).squareRoot())))) / Double.pi + turn * 2
                let col = Int((lon * Double(r) / Double(tile)).rounded(.down)), rowK = (dy + r) / tile
                let n = noise(((col % 40) + 40) % 40 * 31 + rowK * 7)
                var tone = tones[Int(n * 5) % 5]
                let light = (-x - y) / Double(r * 2)
                if light > 0.25 { tone = lerp(tone, C(0xF0F4FA), 0.4) }
                if light < -0.3 { tone = lerp(tone, C(0x2A2E3A), 0.5) }
                let edge = (dx + r) % tile == 0 || (dy + r) % tile == 0
                c.rect(cx + dx, cy + dy, s, s, edge ? lerp(tone, C(0x2A2E3A), 0.45) : tone)
            }
        }
    }

    /// The Parade: the club's own stage, where the dancers perform, all black lacquer, chrome and teal tinsel where
    /// the casino is purple and gold. Across the top the light rig, a silver truss with coloured lamps hanging off it
    /// (pink, cyan, lime, amber), each throwing a faint beam onto the stage; a mirror ball hangs in the middle on its
    /// chain. Behind the stage a curtain of teal tinsel; the show's name in a marquee of warm bulbs on a teal board
    /// (PARADE); stacks of speakers at both ends; on the right Doctor Bones's DJ booth, his skull in a gold crown on
    /// its front, two turntables, a mixer and a lamp on top. The stage riser runs along the back with a row of little
    /// coloured lights; the stage itself is plain black boards. On the screen saver the room goes up: two tiers of
    /// balconies with chrome rails and coloured light along their edges, booths glowing behind them, a big screen over
    /// the stage, and the top truss with its own lamps.
    static func crawlParade(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = crawlParadeFrame(c, g)
        let chrome = C(0x9AA2B4), chromeD = C(0x5A6274), chromeL = C(0xD4DAE6)

        // The room: near-black blue.
        c.rect(0, 0, c.w, g, C(0x0A0E16))

        // On the screen saver: the balconies, the screen and the top rig.
        if !f.tiers.isEmpty { crawlParadeTiers(c, g, f.tiers, f.truss) }

        // The tinsel curtain behind the stage: thin teal strands side by side, each its own shade, a glint or two.
        let tTop = f.tiers.isEmpty ? f.truss + 6 * s : f.tiers[0] + 12 * s
        for x in stride(from: 0, to: c.w, by: s) {
            let n = noise(x / s * 7 + 3)
            let col = n > 0.66 ? C(0x24485A) : n > 0.33 ? C(0x1C3C4C) : C(0x16303E)
            c.rect(x, tTop, s, f.riser - tTop, col)
            let glints = (f.riser - tTop) / (40 * s) + 1
            for k in 0..<glints where noise(x / s * 11 + k * 5) > 0.9 {
                let y = tTop + Int(noise(x / s * 13 + k) * Double(f.riser - tTop - 2 * s))
                c.rect(x, y, s, 2 * s, C(0x5AA0B0))
            }
        }
        // The curtain's fringe of light along its top, and a shadow along its foot.
        c.rect(0, tTop, c.w, s, C(0x4A8898)); c.rect(0, f.riser - 3 * s, c.w, 3 * s, C(0x000000, 0.25))

        // The beams from the lamps, faint, and the pools they make on the riser.
        for can in f.cans {
            crawlBeam(c, can.x, f.truss + 10 * s, f.riser, spread: 30 * s, can.col.alpha(0.06))
            c.ellipse(can.x, f.riser + s, 14 * s, 2 * s, can.col.alpha(0.12))
        }

        // The riser along the back of the stage: black, a chrome lip, a row of little lights.
        c.rect(0, f.riser, c.w, g - f.riser, C(0x12101A)); c.rect(0, f.riser, c.w, s, chromeD)
        for (k, x) in stride(from: 3 * s, to: c.w, by: 8 * s).enumerated() {
            let col = [C(0xFF4AB0), C(0x40E0F0), C(0xB8F040), C(0xFFB040)][k % 4]
            c.rect(x, g - 5 * s, s, s, col.alpha(0.55))
        }

        // The speakers at both ends: two cabinets stacked, a woofer and a horn on each.
        for x in [2 * s, c.w - 22 * s] {
            for (k, y) in [g - 40 * s, g - 20 * s].enumerated() {
                c.rect(x, y, 20 * s, 20 * s, C(0x16161E)); c.rect(x, y, 20 * s, s, C(0x2E2E3A)); c.rect(x, y, s, 20 * s, C(0x2A2A36))
                c.rect(x + 6 * s, y + 3 * s, 8 * s, 3 * s, C(0x0C0C12)); c.rect(x + 7 * s, y + 4 * s, 6 * s, s, C(0x3A3A48))
                c.circle(x + 10 * s, y + 12 * s, 6 * s, C(0x3A3A48)); c.circle(x + 10 * s, y + 12 * s, 5 * s, C(0x0E0E14))
                c.circle(x + 10 * s, y + 12 * s, 2 * s, C(0x2A2A36)); c.rect(x + 9 * s, y + 11 * s, s, s, C(0x5A5A6A))
                if k == 0 { c.rect(x + 2 * s, y + 18 * s, 16 * s, s, C(0x2A2A36)) }
            }
        }

        // The marquee: a teal board in a chrome frame, PARADE in warm bulbs (the lettering drawn, then split into
        // bulbs by the board's colour showing between them); the moving layer chases a brighter bulb along.
        let sg = f.sign
        c.rect(sg.x - 2 * s, sg.y - 2 * s, sg.w + 4 * s, sg.h + 4 * s, chromeD); c.rect(sg.x - 2 * s, sg.y - 2 * s, sg.w + 4 * s, s, chromeL)
        c.rect(sg.x - s, sg.y - s, sg.w + 2 * s, sg.h + 2 * s, chrome)
        c.rect(sg.x, sg.y, sg.w, sg.h, C(0x0E3A44))
        crawlParadeLetters(c, sg, s, lit: C(0xFFE8B0), dim: C(0x6A5A40), chase: -1)
        // Hung from the truss on two chains.
        for x in [sg.x + 6 * s, sg.x + sg.w - 7 * s] { c.rect(x, f.truss + 5 * s, s, sg.y - 2 * s - f.truss - 5 * s, chromeD) }

        // The light rig: a silver truss, two chords and a zigzag between, with the lamps hanging under it.
        crawlParadeTruss(c, f.truss, 0, c.w, s)
        for can in f.cans {
            c.rect(can.x - s, f.truss + 5 * s, 2 * s, 2 * s, chromeD)
            c.rect(can.x - 3 * s, f.truss + 7 * s, 6 * s, 4 * s, C(0x1A1A22)); c.rect(can.x - 3 * s, f.truss + 7 * s, s, 4 * s, C(0x3A3A48))
            c.rect(can.x - 2 * s, f.truss + 11 * s, 4 * s, s, can.col)
        }
        // The disco ball on its chain.
        let b = f.ball
        c.rect(b.x - s / 2, f.truss + 5 * s, max(1, s), b.y - b.r - f.truss - 5 * s, chromeD)
        c.rect(b.x - s, b.y - b.r - s, 2 * s, 2 * s, chromeD)
        c.circle(b.x, b.y, b.r + 4 * s, C(0xD8E8FF, 0.05))
        crawlParadeBall(c, b.x, b.y, b.r, s, turn: 0)

        // Doctor Bones's booth: a black box with a chrome rim, his crowned skull on the front, a strip of light under
        // it; on top two turntables, the mixer between, a gooseneck lamp and his headphones.
        let bo = f.booth, bh = g - bo.top
        c.rect(bo.x, bo.top, bo.w, bh, C(0x14121C)); c.rect(bo.x, bo.top, s, bh, C(0x2A2836)); c.rect(bo.x + bo.w - 2 * s, bo.top, 2 * s, bh, C(0x0C0A12))
        c.rect(bo.x - s, bo.top - 2 * s, bo.w + 2 * s, 2 * s, chrome); c.rect(bo.x - s, bo.top - 2 * s, bo.w + 2 * s, s, chromeL)
        let skullX = bo.x + bo.w / 2 - 7 * s
        crawlSketch(c, skullX, bo.top + 2 * s, crawlBonesSkull, ["y": C(0xF0C040), "w": C(0xE8E4D8), "k": C(0x14121C)], cell: 2 * s)
        c.rect(bo.x + 2 * s, g - 3 * s, bo.w - 4 * s, s, C(0xF0C040, 0.7))
        for (k, x) in [bo.x + 5 * s, bo.x + bo.w - 17 * s].enumerated() {
            c.rect(x, bo.top - 4 * s, 12 * s, 2 * s, C(0x2A2A34)); c.ellipse(x + 6 * s, bo.top - 4 * s, 5 * s, s, C(0x0C0C10))
            c.rect(x + 5 * s, bo.top - 5 * s, 2 * s, s, k == 0 ? C(0xF0C040) : C(0xFF4AB0))
            c.rect(x + 10 * s, bo.top - 7 * s, s, 3 * s, chrome)
        }
        let mx = bo.x + bo.w / 2 - 4 * s
        c.rect(mx, bo.top - 5 * s, 8 * s, 3 * s, C(0x22222C))
        for k in 0..<3 { c.rect(mx + (1 + k * 2) * s, bo.top - 5 * s + (k % 2) * s, s, s, C(0x40E0F0)) }
        c.rect(bo.x + 2 * s, bo.top - 10 * s, s, 8 * s, chromeD); c.rect(bo.x + 2 * s, bo.top - 10 * s, 4 * s, s, chromeD)
        c.rect(bo.x + 5 * s, bo.top - 10 * s, 3 * s, 2 * s, C(0x2A2A34)); c.rect(bo.x + 5 * s, bo.top - 8 * s, 3 * s, s, C(0xFFE8B0))

        // The stage: black lacquer boards, the lamps' colours lying faintly on it.
        c.ground(g, C(0x16141E), edge: C(0x3A3848), speck: C(0x121018), seed: 81)
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x100E16)) }
        for can in f.cans { c.ellipse(can.x, g + 3 * s, 16 * s, 2 * s, can.col.alpha(0.06)) }
    }

    /// The marquee's letters: PARADE in bulbs on the sign's board, every bulb `lit` but those `dim`, the `chase`-th
    /// bulb along brightest (or none, below 0).
    private static func crawlParadeLetters(_ c: PixelCanvas, _ sg: (x: Int, y: Int, w: Int, h: Int), _ s: Int,
                                           lit: Px, dim: Px, chase: Int) {
        let cell = 3 * s, tx = sg.x + 4 * s, ty = sg.y + 4 * s
        crawlText(c, tx, ty, "PARADE", lit, scale: cell)
        // Split the strokes into bulbs: the board's colour between them, a row and a column a cell.
        let board = C(0x0E3A44)
        for y in stride(from: ty, to: ty + 5 * cell, by: cell) { c.rect(tx, y + cell - s, crawlTextWidth("PARADE", scale: cell), s, board) }
        for x in stride(from: tx, to: tx + crawlTextWidth("PARADE", scale: cell), by: cell) { c.rect(x + cell - s, ty, s, 5 * cell, board) }
        // The frame of bulbs round the board's edge, one in three dim, the chased one bright.
        var k = 0
        for x in stride(from: sg.x + s, to: sg.x + sg.w - s, by: 3 * s) {
            for y in [sg.y + s, sg.y + sg.h - 2 * s] {
                let on = chase < 0 ? k % 3 != 0 : (k + chase) % 3 == 0
                c.rect(x, y, s, s, on ? lit : dim); k += 1
            }
        }
    }

    /// A silver truss from `x0` to `x1` with its top chord at `y`: two chords, a zigzag of struts between.
    private static func crawlParadeTruss(_ c: PixelCanvas, _ y: Int, _ x0: Int, _ x1: Int, _ s: Int) {
        let chrome = C(0x9AA2B4), chromeD = C(0x5A6274), chromeL = C(0xD4DAE6)
        c.rect(x0, y, x1 - x0, s, chromeL); c.rect(x0, y + s, x1 - x0, s, chrome)
        c.rect(x0, y + 4 * s, x1 - x0, s, chrome); c.rect(x0, y + 5 * s, x1 - x0, s, chromeD)
        for x in stride(from: x0, to: x1, by: 6 * s) {
            for k in 0..<3 { c.rect(x + k * s, y + (2 + k) * s, s, s, chromeD); c.rect(x + (5 - k) * s, y + (2 + k) * s, s, s, chromeD) }
        }
    }

    /// The screen saver's upper room over the stage: two tiers of balconies (a slab with a chrome rail, a strip of
    /// coloured light along the edge, booths glowing behind), the big screen over the stage between them with a
    /// starburst on it, and the top truss with its own lamps throwing beams down at an angle.
    private static func crawlParadeTiers(_ c: PixelCanvas, _ g: Int, _ tiers: [Int], _ truss: Int) {
        let s = unit(g), chrome = C(0x9AA2B4), chromeD = C(0x5A6274)
        let side = c.w * 30 / 100
        // The big screen in the middle: a chrome frame, a dark face with a pink and cyan starburst.
        let scx = c.w / 2, scy = (tiers[0] + tiers[1]) / 2 + 10 * s, shw = c.w * 16 / 100, shh = 30 * s
        c.rect(scx - shw - 2 * s, scy - shh - 2 * s, 2 * shw + 4 * s, 2 * shh + 4 * s, chromeD)
        c.rect(scx - shw, scy - shh, 2 * shw, 2 * shh, C(0x0C1420))
        for k in 0..<16 {
            let a = Double(k) * Double.pi / 8
            let ex = Double(scx) + cos(a) * Double(shw - 4 * s), ey = Double(scy) + sin(a) * Double(shh - 4 * s)
            c.glowLine(Double(scx), Double(scy), ex, ey, core: (k % 2 == 0 ? C(0xFF4AB0) : C(0x40E0F0)).alpha(0.55),
                       glow: C(0, 0), coreR: Double(s) * 0.8, glowR: Double(s))
        }
        c.circle(scx, scy, 6 * s, C(0xFFE8B0)); c.circle(scx, scy, 3 * s, C(0xFFFFFF))
        for y in stride(from: scy - shh, to: scy + shh, by: 2 * s) { c.rect(scx - shw, y, 2 * shw, max(1, s / 2), C(0x000000, 0.25)) }

        for (k, floor) in tiers.enumerated() {
            let edge = k == 0 ? C(0xFF4AB0) : C(0x40E0F0)
            for (x0, x1) in [(0, side), (c.w - side, c.w)] {
                // The booths behind the rail, glowing.
                for bx in stride(from: x0 + 8 * s, to: x1 - 20 * s, by: 30 * s) {
                    c.rect(bx, floor - 34 * s, 20 * s, 34 * s, C(0x16121E))
                    c.ellipse(bx + 10 * s, floor - 34 * s, 10 * s, 6 * s, C(0x16121E))
                    c.rect(bx + 2 * s, floor - 30 * s, 16 * s, 30 * s, edge.alpha(0.16))
                    c.rect(bx + 6 * s, floor - 8 * s, 8 * s, 2 * s, C(0xFFE8B0, 0.6))
                }
                // The slab, its lit edge, the rail.
                c.rect(x0, floor, x1 - x0, 6 * s, C(0x22202C)); c.rect(x0, floor, x1 - x0, s, C(0x3A3848))
                c.rect(x0, floor + 4 * s, x1 - x0, s, edge.alpha(0.8)); c.rect(x0, floor + 5 * s, x1 - x0, 2 * s, edge.alpha(0.2))
                c.rect(x0, floor - 10 * s, x1 - x0, s, chrome)
                for x in stride(from: x0 + 2 * s, to: x1, by: 7 * s) { c.rect(x, floor - 9 * s, s, 9 * s, chromeD) }
            }
        }
        // The top truss with its lamps, beams slanting down across the room.
        let topY = tiers[1] - 60 * s
        if topY > 0 {
            crawlParadeTruss(c, topY, 0, c.w, s)
            let cols = [C(0xFF4AB0), C(0x40E0F0), C(0xB8F040)]
            for (k, x) in stride(from: c.w / 10, to: c.w, by: c.w / 5).enumerated() {
                let lean = (x < c.w / 2 ? 1 : -1) * 60 * s
                crawlBeam(c, x, topY + 10 * s, tiers[0] - 20 * s, spread: 40 * s, cols[k % 3].alpha(0.035), lean: lean)
                c.rect(x - 3 * s, topY + 7 * s, 6 * s, 4 * s, C(0x1A1A22)); c.rect(x - 2 * s, topY + 11 * s, 4 * s, s, cols[k % 3])
            }
        }
    }

    /// The Parade's life: the mirror ball turning, flecks of its light sweeping round the room (never down on the
    /// stage), the lamps' colours swapping round every few beats, the marquee's bulbs chasing, and the riser's lights
    /// running.
    static func crawlParadeLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlParadeFrame(c, g), b = f.ball
        crawlParadeBall(c, b.x, b.y, b.r, s, turn: (t * 0.08).truncatingRemainder(dividingBy: 1))
        // A hot glint on the ball's face now and then.
        let gl = Int(t * 3) % 5
        if gl < 2 { c.rect(b.x - 3 * s + gl * 2 * s, b.y - 3 * s, s, s, C(0xFFFFFF)) }
        // The flecks: each on its own latitude, sweeping round; only the half facing us is drawn.
        let top = f.tiers.last.map { $0 - 60 * s } ?? 0
        for i in 0..<48 {
            let a = noise(i * 5) * Double.pi * 2 + t * 0.5
            guard cos(a) > 0 else { continue }
            let x = b.x + Int(sin(a) * Double(c.w) * 0.7)
            let y = max(0, top) + Int(noise(i * 5 + 1) * Double(f.riser - 6 * s - max(0, top)))
            guard x >= 0, x < c.w else { continue }
            let col = [C(0xFFFFFF), C(0xFF8AD0), C(0x8AF0FF), C(0xFFF0B0)][i % 4]
            c.rect(x, y, s, s, col.alpha(0.35 + 0.35 * cos(a)))
        }
        // The lamps' lenses and beams in new colours each few beats.
        let cols = [C(0xFF4AB0), C(0x40E0F0), C(0xB8F040), C(0xFFB040)]
        let beat = Int(t / 1.5)
        for (k, can) in f.cans.enumerated() {
            let col = cols[(k + beat) % 4]
            c.rect(can.x - 2 * s, f.truss + 11 * s, 4 * s, s, col)
            crawlBeam(c, can.x, f.truss + 12 * s, f.riser, spread: 22 * s, col.alpha(0.04))
        }
        // The marquee's chase and the riser's run.
        crawlParadeLetters(c, f.sign, s, lit: C(0xFFF4D0), dim: C(0x6A5A40), chase: Int(t * 6) % 3)
        for (k, x) in stride(from: 3 * s, to: c.w, by: 8 * s).enumerated() where (k + Int(t * 5)) % 6 == 0 {
            c.rect(x, g - 5 * s, s, s, cols[k % 4]); c.rect(x - s, g - 6 * s, 3 * s, 3 * s, cols[k % 4].alpha(0.2))
        }
    }
}

// MARK: - The Over City

extension Scenes {
    /// Where things stand in the Over City, shared by the still picture and the moving layer: the balustrade's top,
    /// the admin building's box, the perches the birds land on, and the flag on the dome.
    static func crawlOverCityFrame(_ c: PixelCanvas, _ g: Int) -> (rail: Int, admin: (x: Int, w: Int, top: Int),
                                                                  perches: [(x: Int, y: Int)], flag: (x: Int, y: Int)) {
        let s = unit(g), tall = isTall(c)
        let admin = (x: c.w * 54 / 100, w: 84 * s, top: g - 34 * s)
        // The two nest houses' roofs first, then the three poles, then the flag's finial.
        var perches: [(x: Int, y: Int)] = [(x: c.w * 4 / 100 + 4 * s, y: g - 44 * s), (x: c.w * 20 / 100, y: g - 45 * s),
                                           (x: c.w * 32 / 100, y: g - 50 * s), (x: c.w * 44 / 100, y: g - 46 * s),
                                           (x: c.w * 92 / 100, y: g - 50 * s)]
        let flag = (x: admin.x + admin.w / 2, y: admin.top - 26 * s)
        perches.append((x: flag.x, y: flag.y - s))
        if tall {
            perches.append((x: c.w * 16 / 100, y: g - 196 * s))
            perches.append((x: c.w * 82 / 100, y: g - 160 * s))
        }
        return (g - 9 * s, admin, perches, flag)
    }

    /// The Over City: the Skyfowl's town above the clouds, at the end of the afternoon. A deep blue sky over a sea of
    /// lilac cloud, a slender spire or two poking out of it far off. On the left the birds' houses, round woven
    /// domes on stilted platforms with dark round doorways, a rope bridge sagging between them, and tall perches (a
    /// pole with a crossbar) here and there; on the right the admin building, pale stone with four columns, ADMIN on
    /// its frieze, a teal copper dome with a flag on top, broad steps down to the plaza. In front a stone balustrade,
    /// and the plaza's flagstones, plain. On the screen saver two great towers rise into the clouds: the Skyfowl's,
    /// stacked rings of woven nests on a stone shaft, and a slender white spire with a balcony and a bridge out to a
    /// floating perch; banks of cloud drift across them, the sun low on the left.
    static func crawlOverCity(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlOverCityFrame(c, g)

        // The sky, deep blue overhead, paler down towards the cloud sea.
        c.gradient(0, g, tall ? C(0x1A2A58) : C(0x2A4478), C(0x6A84B2), bands: tall ? 9 : 5)
        if tall { crawlOverCityTowers(c, g) }

        // The cloud sea: billows lit pale along the top, a shadow under, far spires standing out of it.
        let sea = g - 24 * s
        for (k, x) in [6, 41, 79].enumerated() {
            let sx = c.w * x / 100, h = (20 + k * 8) * s
            c.rect(sx - s, sea - h, 3 * s, h, C(0x8A98BC)); c.rect(sx - s, sea - h, s, h, C(0xA8B4D0))
            c.rect(sx - 2 * s, sea - h + 4 * s, 5 * s, s, C(0x8A98BC)); c.rect(sx, sea - h - 4 * s, s, 4 * s, C(0x8A98BC))
        }
        for x in stride(from: -8 * s, to: c.w + 8 * s, by: 14 * s) {
            let h = Int(noise(x / max(1, s) + 7) * 5) * s
            c.ellipse(x, sea - h + 3 * s, 12 * s, 6 * s, C(0x9AA6C8)); c.ellipse(x - 2 * s, sea - h + 2 * s, 9 * s, 4 * s, C(0xBAC4DC))
        }
        c.rect(0, sea + 6 * s, c.w, f.rail - sea - 6 * s, C(0x7A88B0))
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.ellipse(x + 10 * s, sea + 6 * s, 10 * s, 3 * s, C(0x8A98BC)) }

        // The perches: a tall weathered pole with a crossbar on top, standing up from behind the balustrade.
        for p in f.perches[2..<5] { crawlOverCityPerch(c, p.x, p.y, f.rail, s) }

        // The nest houses on the left: a woven dome on a platform on stilts, a round doorway, a rope bridge between.
        let huts: [(x: Int, floor: Int, r: Int)] = [(c.w * 4 / 100 + 4 * s, g - 30 * s, 14 * s), (c.w * 20 / 100, g - 34 * s, 11 * s)]
        let bridgeA = (x: huts[0].x + huts[0].r + 4 * s, y: huts[0].floor), bridgeB = (x: huts[1].x - huts[1].r - 4 * s, y: huts[1].floor)
        for x in stride(from: bridgeA.x, to: bridgeB.x, by: s) {
            let u = Double(x - bridgeA.x) / Double(max(1, bridgeB.x - bridgeA.x))
            let y = bridgeA.y + Int(Double(bridgeB.y - bridgeA.y) * u) + Int(sin(u * Double.pi) * Double(5 * s))
            c.rect(x, y, s, s, C(0x8A6A44)); c.rect(x, y - 5 * s, s, s, C(0x6A5034))
            if (x - bridgeA.x) % (4 * s) == 0 { c.rect(x, y - 4 * s, s, 4 * s, C(0x6A5034)) }
        }
        for h in huts { crawlOverCityHut(c, h.x, h.floor, h.r, f.rail, s) }

        // The admin building: broad steps, a stone hall with four columns under a pediment, ADMIN on the frieze, a dark
        // doorway; the copper dome behind and above, its flagpole.
        let ad = f.admin, stone = C(0xB0A898), stoneD = C(0x847C70), stoneL = C(0xCCC4B4)
        // The dome on its drum.
        let dcx = ad.x + ad.w / 2, dcy = ad.top - 8 * s
        c.rect(dcx - 22 * s, dcy - 2 * s, 44 * s, 10 * s, stoneD); c.rect(dcx - 22 * s, dcy - 2 * s, 44 * s, s, stone)
        for x in stride(from: dcx - 19 * s, to: dcx + 20 * s, by: 6 * s) { c.rect(x, dcy + s, 2 * s, 6 * s, C(0x5A5448)) }
        for y in 0..<(15 * s) {
            let half = Int(Double(20 * s) * (1 - pow(Double(y) / Double(15 * s), 2)).squareRoot())
            let col = y > 10 * s ? C(0x3E7A72) : y % (4 * s) < s ? C(0x5A9A8E) : C(0x4A8A80)
            c.rect(dcx - half, dcy - 2 * s - y, 2 * half, 1, col)
            c.rect(dcx - half, dcy - 2 * s - y, min(2 * half, 3 * s), 1, C(0x6AB0A2))
        }
        c.rect(dcx - s, f.flag.y, s, dcy - 17 * s - f.flag.y, C(0x4A4440))
        c.rect(dcx - 2 * s, f.flag.y - s, 3 * s, s, C(0xD8B048))
        // The hall.
        c.rect(ad.x, ad.top, ad.w, f.rail - ad.top, stone); c.rect(ad.x, ad.top, 2 * s, f.rail - ad.top, stoneL)
        c.rect(ad.x + ad.w - 3 * s, ad.top, 3 * s, f.rail - ad.top, stoneD)
        // The pediment: a low gable over the frieze.
        for k in 0..<(8 * s) {
            let half = ad.w / 2 + 3 * s - k * (ad.w / 2 + 3 * s) / (8 * s)
            c.rect(ad.x + ad.w / 2 - half, ad.top - k, 2 * half, 1, k == 0 ? stoneD : stone)
        }
        c.rect(ad.x + ad.w / 2 - 6 * s, ad.top - 5 * s, 12 * s, 2 * s, C(0xD8B048))
        // The frieze with its name.
        let label = "ADMIN", lw = crawlTextWidth(label, scale: s)
        c.rect(ad.x - 2 * s, ad.top, ad.w + 4 * s, 9 * s, stoneL); c.rect(ad.x - 2 * s, ad.top + 8 * s, ad.w + 4 * s, s, stoneD)
        crawlText(c, ad.x + ad.w / 2 - lw / 2, ad.top + 2 * s, label, C(0x4A4440), scale: s)
        // The columns and the shade between them, the doorway in the middle.
        let colTop = ad.top + 9 * s, colH = f.rail - 6 * s - colTop
        c.rect(ad.x + 4 * s, colTop, ad.w - 8 * s, colH, C(0x6A6458))
        c.rect(ad.x + ad.w / 2 - 6 * s, colTop + 4 * s, 12 * s, colH - 4 * s, C(0x2A2830))
        c.ellipse(ad.x + ad.w / 2, colTop + 4 * s, 6 * s, 3 * s, C(0x2A2830))
        for k in 0..<4 {
            let x = ad.x + 6 * s + k * (ad.w - 18 * s) / 3
            c.rect(x, colTop, 6 * s, colH, stone); c.rect(x, colTop, 2 * s, colH, stoneL); c.rect(x + 5 * s, colTop, s, colH, stoneD)
            c.rect(x - s, colTop, 8 * s, s, stoneL); c.rect(x - s, colTop + colH - s, 8 * s, s, stoneD)
        }
        // The steps.
        for k in 0..<3 {
            let y = f.rail - (6 - k * 2) * s
            c.rect(ad.x - k * 3 * s, y, ad.w + 6 * k * s, 2 * s, k % 2 == 0 ? stone : stoneL); c.rect(ad.x - k * 3 * s, y + s, ad.w + 6 * k * s, s, stoneD)
        }

        // The balustrade: a stone rail on short fat balusters, a plinth under them.
        c.rect(0, f.rail, c.w, g - f.rail, C(0x4E4C5E))
        for x in stride(from: 2 * s, to: c.w, by: 6 * s) {
            c.rect(x, f.rail + 2 * s, 3 * s, 5 * s, C(0x646276)); c.rect(x, f.rail + 2 * s, s, 5 * s, C(0x7A788C))
            c.rect(x + s, f.rail + 3 * s, 2 * s, 2 * s, C(0x3E3C4C))
        }
        c.rect(0, f.rail, c.w, 2 * s, C(0x7A788C)); c.rect(0, f.rail, c.w, s, C(0x9290A4))
        c.rect(0, g - 2 * s, c.w, 2 * s, C(0x5A586C))

        // The plaza: worn grey flagstones, plain.
        c.ground(g, C(0x3E3C4C), edge: C(0x5E5C70), speck: C(0x343240), seed: 89)
        for x in stride(from: 0, to: c.w, by: 22 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x343240)) }
    }

    /// A perch: a weathered grey-brown pole from behind the balustrade up to `top`, a crossbar there, worn pale where
    /// the birds stand.
    private static func crawlOverCityPerch(_ c: PixelCanvas, _ x: Int, _ top: Int, _ rail: Int, _ s: Int) {
        c.rect(x - s, top, 2 * s, rail - top, C(0x6A5A48)); c.rect(x - s, top, s, rail - top, C(0x8A7A62))
        c.rect(x - 6 * s, top, 12 * s, 2 * s, C(0x6A5A48)); c.rect(x - 6 * s, top, 12 * s, s, C(0xA89A80))
        c.rect(x - 4 * s, top + 2 * s, s, 2 * s, C(0x5A4A3A)); c.rect(x + 3 * s, top + 2 * s, s, 2 * s, C(0x5A4A3A))
    }

    /// A Skyfowl house: a woven dome `r` wide each side of `x` on a plank platform at `floor`, stilts down to behind the
    /// balustrade, a dark round doorway, its weave in rings, lit from the left.
    private static func crawlOverCityHut(_ c: PixelCanvas, _ x: Int, _ floor: Int, _ r: Int, _ rail: Int, _ s: Int) {
        for sx in [x - r + 2 * s, x - s, x + r - 4 * s] {
            c.rect(sx, floor, 2 * s, rail - floor, C(0x5A4430)); c.rect(sx, floor, s, rail - floor, C(0x7A5E40))
        }
        c.rect(x - r - 4 * s, floor, 2 * r + 8 * s, 3 * s, C(0x7A5E40)); c.rect(x - r - 4 * s, floor, 2 * r + 8 * s, s, C(0x9A7A54))
        let h = r * 4 / 5
        for y in 0..<h {
            let half = Int(Double(r) * (1 - pow(Double(y) / Double(h), 2)).squareRoot())
            let ring = (y / (2 * s)) % 2 == 0
            c.rect(x - half, floor - y - 1, 2 * half, 1, ring ? C(0xA07A48) : C(0x8A6A3C))
            c.rect(x - half, floor - y - 1, min(2 * half, 2 * s), 1, C(0xC09A60))
            c.rect(x + half - 2 * s, floor - y - 1, min(2 * half, 2 * s), 1, C(0x6A5030))
        }
        // A tuft of twigs at the top, and the doorway.
        for k in -1...1 { c.rect(x + k * 2 * s, floor - h - 3 * s + abs(k) * s, s, 3 * s, C(0x8A6A3C)) }
        c.ellipse(x + s, floor - h / 3, r / 3, h / 3, C(0x2A2018)); c.rect(x + s - r / 3, floor - h / 3, 2 * (r / 3) + s, h / 3, C(0x2A2018))
    }

    /// The screen saver's sky: the sun low on the left, two great towers (the Skyfowl's stacked nests on a stone
    /// shaft at the left, a slender white spire with a bridge to a floating perch at the right) and banks of cloud
    /// across them.
    private static func crawlOverCityTowers(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g)
        // The sun and its glow.
        let sx = c.w * 34 / 100, sy = g - 210 * s
        c.circle(sx, sy, 34 * s, C(0xFFB060, 0.07)); c.circle(sx, sy, 22 * s, C(0xFFC070, 0.1)); c.circle(sx, sy, 11 * s, C(0xFFD890))
        c.circle(sx - 2 * s, sy - 2 * s, 7 * s, C(0xFFECC0))
        // A far tower or two, faint.
        for (x, h) in [(c.w * 50 / 100, 120), (c.w * 64 / 100, 90)] {
            c.rect(x, g - 24 * s - h * s, 8 * s, h * s, C(0x6A7EAA)); c.ellipse(x + 4 * s, g - 24 * s - h * s, 6 * s, 4 * s, C(0x6A7EAA))
            c.rect(x + 3 * s, g - 30 * s - h * s, s, 6 * s, C(0x6A7EAA))
        }
        // The Skyfowl tower on the left: a tapering stone shaft, rings of woven nests up it, a perch at the top.
        let lx = c.w * 16 / 100, ltop = g - 190 * s
        for y in ltop..<(g - 24 * s) {
            let k = Double(y - ltop) / Double(g - 24 * s - ltop)
            let half = Int(Double(10 * s) + k * Double(8 * s))
            c.rect(lx - half, y, 2 * half, 1, C(0x8A8698)); c.rect(lx - half, y, 3 * s, 1, C(0xA8A4B4)); c.rect(lx + half - 3 * s, y, 3 * s, 1, C(0x6A6678))
        }
        for (k, y) in stride(from: ltop + 14 * s, to: g - 40 * s, by: 34 * s).enumerated() {
            let half = 24 * s - k * s
            c.rect(lx - half, y, 2 * half, 3 * s, C(0x7A5E40)); c.rect(lx - half, y, 2 * half, s, C(0x9A7A54))
            for n in stride(from: lx - half + 3 * s, to: lx + half - 6 * s, by: 11 * s) {
                c.ellipse(n + 4 * s, y - 3 * s, 5 * s, 4 * s, C(0x8A6A3C)); c.ellipse(n + 3 * s, y - 4 * s, 3 * s, 2 * s, C(0xA07A48))
                c.rect(n + 3 * s, y - 2 * s, 2 * s, 2 * s, C(0x2A2018))
            }
        }
        c.ellipse(lx, ltop, 14 * s, 5 * s, C(0x8A6A3C)); c.ellipse(lx - 2 * s, ltop - s, 10 * s, 3 * s, C(0xA07A48))
        crawlOverCityPerch(c, lx, g - 196 * s, ltop - 2 * s, s)
        // The white spire on the right: slender, a balcony ring, a pointed cap, a bridge out to a floating perch.
        let rx = c.w * 70 / 100, rtop = g - 230 * s
        c.rect(rx - 7 * s, rtop, 14 * s, g - 24 * s - rtop, C(0xC8C4D0)); c.rect(rx - 7 * s, rtop, 3 * s, g - 24 * s - rtop, C(0xE0DCE6))
        c.rect(rx + 4 * s, rtop, 3 * s, g - 24 * s - rtop, C(0x9894A6))
        for y in stride(from: rtop + 20 * s, to: g - 40 * s, by: 22 * s) { c.rect(rx - 2 * s, y, 4 * s, 6 * s, C(0x3A3850)) }
        for k in 0..<(16 * s) {
            let half = 8 * s - k / 2
            if half > 0 { c.rect(rx - half, rtop - k, 2 * half, 1, k % (3 * s) < s ? C(0x3E7A72) : C(0x4A8A80)) }
        }
        let by = g - 150 * s
        c.rect(rx - 14 * s, by, 28 * s, 3 * s, C(0xB0ACBC)); c.rect(rx - 14 * s, by, 28 * s, s, C(0xE0DCE6))
        c.rect(rx - 14 * s, by - 5 * s, 28 * s, s, C(0x9894A6))
        let px = c.w * 82 / 100
        for x in stride(from: rx + 14 * s, to: px - 6 * s, by: s) {
            let u = Double(x - rx - 14 * s) / Double(max(1, px - 6 * s - rx - 14 * s))
            let y = by + Int(sin(u * Double.pi) * Double(4 * s))
            c.rect(x, y, s, s, C(0x8A6A44)); c.rect(x, y - 4 * s, s, s, C(0x6A5034))
        }
        // The floating perch: a rock lump with a perch on it.
        c.ellipse(px, by + 3 * s, 10 * s, 4 * s, C(0x6A6678)); c.ellipse(px - 2 * s, by + 2 * s, 7 * s, 2 * s, C(0x8A8698))
        for k in 0..<5 { c.rect(px - 4 * s + k * 2 * s, by + 6 * s, 2 * s, (4 - abs(k - 2)) * 2 * s, C(0x5A5668)) }
        crawlOverCityPerch(c, px, g - 160 * s, by, s)
        // Banks of cloud drifting across the towers.
        for (k, b) in [(8, 120, 60), (60, 96, 80), (90, 170, 50), (30, 250, 70), (76, 270, 60)].enumerated() {
            let bx = c.w * b.0 / 100, byy = g - b.1 * s
            if byy < 0 { continue }
            c.ellipse(bx, byy + 4 * s, b.2 * s, 6 * s, C(0x8A98BC, 0.85))
            c.ellipse(bx - b.2 * s / 3, byy, b.2 * s / 2, 7 * s, C(0xB0BCD6, 0.9))
            c.ellipse(bx + b.2 * s / 4, byy - s, b.2 * s / 2, 6 * s + (k % 2) * s, C(0xC4CEE2, 0.9))
        }
    }

    /// The Over City's life: birds flitting from perch to perch (a short hop up and over, wings beating, then a rest
    /// on the crossbar), the flag on the dome flapping, and a wisp of cloud drifting slowly across the sky.
    static func crawlOverCityLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlOverCityFrame(c, g), p = f.perches, n = p.count
        // Wisps of cloud.
        for k in 0..<(isTall(c) ? 4 : 2) {
            let span = Double(c.w + 80 * s)
            let x = Int((Double(k) * 0.37 * span + t * Double(3 * s)).truncatingRemainder(dividingBy: span)) - 40 * s
            let y = g - (54 + k * 46) * s
            if y > 0 { wisp(c, x, y, 40 * s, C(0xD8E0F0, 0.35), s: s) }
        }
        // The flag.
        let fl = f.flag, wave = Int(t * 4) % 3
        for k in 0..<8 {
            let dy = Int(sin(Double(k) * 0.9 - t * 5) * Double(s))
            c.rect(fl.x + k * s, fl.y + dy, s, 5 * s, k < 2 ? C(0x8A2A2A) : C(0xC84038))
            if k == 4 + wave % 2 { c.rect(fl.x + k * s, fl.y + dy + 2 * s, s, s, C(0xF0D060)) }
        }
        // The birds: each hops between two perches and rests on each.
        let tones = [C(0x5A3E2A), C(0x7A7888), C(0x3A3A4A), C(0xC8C4BC), C(0x8A5A30), C(0x4A4A5E)]
        for k in 0..<min(6, n) {
            let a = p[k % n], b = p[(k * 2 + 3) % n]
            if a.x == b.x { continue }
            let period = 9 + Double(k) * 1.3
            let u = (t / period + Double(k) * 0.23).truncatingRemainder(dividingBy: 1)
            var x = a.x, y = a.y, flying = false
            if u < 0.3 || (u >= 0.5 && u < 0.8) {
                let from = u < 0.3 ? a : b, to = u < 0.3 ? b : a
                let v = (u < 0.3 ? u : u - 0.5) / 0.3
                let hop = Double(max(0, min(30 * s, abs(to.x - from.x) / 3 + 8 * s, min(from.y, to.y) - 10 * s)))
                x = from.x + Int(Double(to.x - from.x) * v)
                y = from.y + Int(Double(to.y - from.y) * v) - Int(sin(v * Double.pi) * hop)
                flying = true
            } else if u >= 0.3 && u < 0.5 { x = b.x; y = b.y }
            let col = tones[k % tones.count], dir = flying && (u < 0.3 ? b.x < a.x : a.x < b.x) ? -1 : 1
            crawlOverCityBird(c, x + (flying ? 0 : (k % 2 == 0 ? -3 : 2) * s), y, col, flying: flying, flap: Int(t * 9 + Double(k)) % 2 == 0, dir: dir, s)
        }
    }

    /// A bird: perched, a little body and head on the bar with a tail; flying, the body with wings up or down.
    private static func crawlOverCityBird(_ c: PixelCanvas, _ x: Int, _ y: Int, _ col: Px, flying: Bool, flap: Bool, dir: Int, _ s: Int) {
        let beak = C(0xE0A030)
        if flying {
            c.rect(x - 2 * s, y - s, 4 * s, 2 * s, col)
            c.rect(x + dir * 2 * s - (dir < 0 ? s : 0), y - 2 * s, s * 2, 2 * s, col)
            c.rect(x + dir * 4 * s - (dir < 0 ? s : 0), y - s, s, s, beak)
            if flap {
                c.rect(x - 3 * s, y - 3 * s, 2 * s, 2 * s, col); c.rect(x + s, y - 3 * s, 2 * s, 2 * s, col)
                c.rect(x - 4 * s, y - 4 * s, s, s, col); c.rect(x + 3 * s, y - 4 * s, s, s, col)
            } else {
                c.rect(x - 4 * s, y + s, 3 * s, s, col); c.rect(x + s, y + s, 3 * s, s, col)
            }
        } else {
            c.rect(x, y - 3 * s, 3 * s, 3 * s, col); c.rect(x + s, y - 5 * s, 2 * s, 2 * s, col)
            c.rect(x + 3 * s, y - 4 * s, s, s, beak); c.rect(x - s, y - 2 * s, s, 2 * s, col)
            c.rect(x + 2 * s, y - 4 * s, s, s, C(0x101010))
        }
    }
}

// MARK: - Grimaldi's circus tent

extension Scenes {
    /// Where things stand in the circus tent, shared by the still picture and the moving layer: the eave where the
    /// roof meets the wall, the roof's peak (off the top of the window), the king poles, the ring's middle and
    /// half-width, the top of the vine mound, and (on the screen saver) where the trapezes hang from.
    static func crawlCircusFrame(_ c: PixelCanvas, _ g: Int) -> (eave: Int, peak: Int, poles: [Int], ring: (x: Int, y: Int, rx: Int),
                                                                mound: Int, swing: Int) {
        let s = unit(g), tall = isTall(c)
        let ring = (x: c.w / 2, y: g - 9 * s, rx: c.w * 22 / 100)
        return (g - 30 * s, tall ? g - 262 * s : g - 160 * s, [c.w * 24 / 100, c.w * 76 / 100], ring, ring.y - 24 * s,
                tall ? g - 190 * s : -1)
    }

    /// The vine mound's top over column `x`: highest in the ring's middle, lumpy.
    private static func crawlCircusMoundTop(_ x: Int, _ f: (eave: Int, peak: Int, poles: [Int], ring: (x: Int, y: Int, rx: Int), mound: Int, swing: Int),
                                            _ s: Int) -> Int {
        let u = Double(x - f.ring.x) / Double(f.ring.rx)
        guard abs(u) < 1 else { return f.ring.y + 1 }
        let h = pow(1 - u * u, 0.6) * Double(f.ring.y - f.mound) + (noise(x / max(1, s) / 3 + 17) - 0.5) * Double(4 * s)
        return f.ring.y - Int(h)
    }

    /// Grimaldi's circus tent: the big top, gone quiet and wrong. Red and cream stripes run up the roof to the peak;
    /// a scalloped valance with a gold fringe hangs where it meets the wall; the wall's own stripes, darker, go down
    /// to the floor. Two king poles, painted in a red spiral, stand either side of the centre ring, and pale-green
    /// vines climb them. The ring itself is choked: its red and gold curb is buried in a mound of pale-green vines,
    /// leaves and curling tendrils, an old star-painted pedestal and a hoop strangled in them. Strings of bulbs
    /// droop from the poles, a few of them dead. On the left the bleachers' wooden tiers; on the right the entrance,
    /// its flaps tied back on the dark outside, the show's name over it on a banner (GRIMALDI). The floor is dark
    /// sawdust. On the screen saver the roof climbs to its peak, a crown of bulbs round it, rope ladders up the
    /// poles to little platforms, and the vines up there too, wound round the trapezes' ropes.
    static func crawlCircus(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlCircusFrame(c, g)
        let red = C(0x7A2228), redD = C(0x5A1A20), cream = C(0xA89878), creamD = C(0x7E715A)
        let vine = C(0x7AA472), vineL = C(0xA8D09A), vineD = C(0x4A6E4A)

        // The roof: stripes fanning out from the peak, darker high up where the lamps don't reach.
        let stripe = 16 * s, depth = Double(f.eave - f.peak)
        for y in stride(from: 0, to: f.eave, by: s) {
            let dy = Double(y - f.peak)
            let dark = max(0, min(0.85, (Double(f.eave - y) / depth) * 0.85))
            if dy <= 0 { c.rect(0, y, c.w, s, C(0x140A0C)); continue }
            let w = Double(stripe) * dy / depth, blend = lerp(lerp(red, cream, 0.4), C(0x140A0C), dark)
            for x in stride(from: 0, to: c.w, by: s) {
                // Where the stripes crowd closer than a few pixels (near the peak, or slanting at the far sides),
                // the canvas reads as one dark tone instead of flickering.
                let rise = w * dy / max(1, Double(abs(x - f.ring.x)))
                if min(w, rise) < Double(4 * s) { c.rect(x, y, s, s, blend); continue }
                let k = Int((Double(x - f.ring.x) * depth / dy / Double(stripe)).rounded(.down))
                let seam = Int((Double(x + s - f.ring.x) * depth / dy / Double(stripe)).rounded(.down)) != k
                let base = seam ? C(0x2A1214) : (k % 2 == 0 ? red : cream)
                c.rect(x, y, s, s, lerp(base, C(0x140A0C), dark))
            }
        }
        if tall {
            // The crown of bulbs round the peak, and the iron ring the canvas is laced to.
            c.ellipse(f.ring.x, f.peak, 22 * s, 6 * s, C(0x2A1A16)); c.ellipse(f.ring.x, f.peak, 18 * s, 4 * s, C(0x140A0C))
            for k in 0..<12 {
                let a = Double(k) * Double.pi / 6
                c.rect(f.ring.x + Int(cos(a) * Double(21 * s)), f.peak + Int(sin(a) * Double(5 * s)), s, s, k % 5 == 3 ? C(0x5A4A30) : C(0xFFD890))
            }
        }

        // The wall: straight stripes, darker than the roof, a shadowed band at the foot.
        for (k, x) in stride(from: f.ring.x - 80 * stripe, to: c.w, by: stripe).enumerated() where x + stripe > 0 {
            let even = k % 2 == 0
            c.rect(x, f.eave, stripe, g - f.eave, even ? redD : creamD)
            c.rect(x, f.eave, s, g - f.eave, even ? C(0x481418) : C(0x6A5E4A))
        }
        c.rect(0, g - 10 * s, c.w, 10 * s, C(0x000000, 0.3))

        // The valance: scallops in red and cream, a gold fringe along their edge.
        for (k, x) in stride(from: 0, to: c.w, by: 12 * s).enumerated() {
            c.ellipse(x + 6 * s, f.eave, 6 * s, 4 * s, C(0xC89A3A)); c.ellipse(x + 6 * s, f.eave - s, 6 * s, 4 * s, k % 2 == 0 ? red : cream)
        }
        c.rect(0, f.eave - 4 * s, c.w, 3 * s, C(0x3A1A18)); c.rect(0, f.eave - 2 * s, c.w, s, C(0xC89A3A))

        // The bleachers on the left: three wooden tiers, a board along each, dark under.
        let bx = c.w * 12 / 100
        for k in 0..<3 {
            let y = g - (6 + k * 6) * s, w = bx - k * 10 * s + 10 * s
            c.rect(0, y, w, 6 * s, C(0x2A1C14)); c.rect(0, y, w, 2 * s, C(0x6A4A2E)); c.rect(0, y, w, s, C(0x8A6440))
            for x in stride(from: 6 * s, to: w, by: 14 * s) { c.rect(x, y + 2 * s, s, 4 * s, C(0x1E140E)) }
        }

        // The entrance on the right: the flaps tied back, the dark outside, the banner over it.
        let ex = c.w * 88 / 100, ew = 24 * s
        c.rect(ex, f.eave + 4 * s, ew, g - f.eave - 4 * s, C(0x0A0A12))
        for x in stride(from: ex + 3 * s, to: ex + ew - 2 * s, by: 7 * s) { c.rect(x, g - 20 * s + Int(noise(x) * 6) * s, s, s, C(0xC8D0E0, 0.5)) }
        for (side, dir) in [(ex, 1), (ex + ew, -1)] {
            for k in 0..<7 {
                let w = (7 - k) * s
                let x = dir > 0 ? side : side - w
                c.rect(x, f.eave + 4 * s + k * 3 * s, w, 3 * s, k % 2 == 0 ? red : cream)
            }
            c.rect(dir > 0 ? side : side - 2 * s, f.eave + 24 * s, 2 * s, g - f.eave - 24 * s, dir > 0 ? redD : creamD)
            c.rect(side - s, f.eave + 22 * s, 2 * s, 2 * s, C(0xC89A3A))
        }
        let name = "GRIMALDI", nw = crawlTextWidth(name, scale: s) + 6 * s
        let nx = min(c.w - nw - 2 * s, ex + ew / 2 - nw / 2), ny = f.eave - 2 * s
        c.rect(nx, ny, nw, 9 * s, C(0xD8C8A0)); c.rect(nx, ny, nw, s, C(0xF0E4C0)); c.rect(nx, ny + 8 * s, nw, s, C(0x9A8A68))
        crawlText(c, nx + 3 * s, ny + 2 * s, name, C(0x8A1A20), scale: s)

        // The king poles: wood painted in a red spiral, a vine wound up each.
        for (k, x) in f.poles.enumerated() {
            let top = tall ? f.peak + 60 * s : 0
            c.rect(x - 2 * s, top, 5 * s, g - 2 * s - top, C(0xC8B898)); c.rect(x + 2 * s, top, s, g - 2 * s - top, C(0x8A7C60))
            for y in stride(from: g - 2 * s, to: top, by: -6 * s) {
                for i in 0..<3 { c.rect(x - 2 * s + i * 2 * s, y - i * s, 2 * s, 2 * s, C(0x9A2A30)) }
            }
            c.rect(x - 4 * s, g - 3 * s, 9 * s, 3 * s, C(0x3A2A1E))
            let vineTop = tall ? g - 150 * s : f.eave - 20 * s
            for y in stride(from: g - 4 * s, to: vineTop, by: -s) {
                let wob = Int(sin(Double(y) / Double(4 * s) + Double(k) * 2) * Double(3 * s))
                c.rect(x + wob, y, s, s, sin(Double(y) / Double(4 * s) + Double(k) * 2 + 1.57) > 0 ? vineL : vineD)
                if (y / s) % 9 == 0 { c.rect(x + wob + (wob > 0 ? s : -2 * s), y, 2 * s, s, vine) }
            }
            if tall { crawlCircusRig(c, g, x, k, f) }
        }

        // The strings of bulbs, drooping from the poles out to the walls and across the ring, a few dead.
        let hangY = f.eave - 6 * s
        let spans: [(Int, Int)] = [(0, f.poles[0]), (f.poles[0], f.poles[1]), (f.poles[1], c.w)]
        for (k, sp) in spans.enumerated() {
            let sag = Double((sp.1 - sp.0) / 10)
            for x in stride(from: sp.0, to: sp.1, by: s) {
                let u = Double(x - sp.0) / Double(max(1, sp.1 - sp.0))
                let y = hangY + Int(sin(u * Double.pi) * sag)
                c.rect(x, y, s, s, C(0x1A1010))
                if (x - sp.0) % (9 * s) == 4 * s {
                    let dead = noise(k * 31 + x / max(1, s)) > 0.75
                    c.rect(x, y + s, s, 2 * s, dead ? C(0x4A4030) : C(0xFFD890))
                    if !dead { c.ellipse(x, y + 2 * s, 4 * s, 3 * s, C(0xFFC870, 0.1)) }
                }
            }
        }

        // The vine mound in the ring: a dark mass, strands of pale green across it lit along their tops, leaves.
        let r = f.ring
        for x in stride(from: r.x - r.rx, to: r.x + r.rx, by: s) {
            let top = crawlCircusMoundTop(x, f, s)
            if top < r.y { c.rect(x, top, s, r.y - top, vineD) }
        }
        for k in 0..<9 {
            let y0 = r.y - (3 + k * 2) * s, amp = Double(2 * s), ph = Double(k) * 1.7
            for x in stride(from: r.x - r.rx, to: r.x + r.rx, by: s) {
                let top = crawlCircusMoundTop(x, f, s)
                let y = y0 + Int(sin(Double(x) / Double(7 * s) + ph) * amp)
                guard y > top + s else { continue }
                c.rect(x, y, s, s, k % 3 == 0 ? vineL : vine)
                if (x / s + k * 5) % 13 == 0 { c.rect(x, y - s, 2 * s, s, vineL); c.rect(x + s, y - 2 * s, s, s, vineL) }
            }
        }
        // The mound's lumpy edge, lit, with leaves sticking up.
        for x in stride(from: r.x - r.rx, to: r.x + r.rx, by: s) {
            let top = crawlCircusMoundTop(x, f, s)
            guard top < r.y else { continue }
            c.rect(x, top, s, s, vineL)
            if noise(x / max(1, s) + 41) > 0.85 { c.rect(x - s, top - 2 * s, 2 * s, 2 * s, vine); c.rect(x - s, top - 2 * s, s, s, vineL) }
        }
        // The pedestal half buried at the left, its gold star, and the hoop at the right, both wound with vine.
        let pdx = r.x - r.rx * 55 / 100, pdy = r.y - 16 * s
        c.rect(pdx, pdy, 14 * s, 10 * s, C(0x8A2228)); c.rect(pdx, pdy, 14 * s, 2 * s, C(0xC89A3A)); c.rect(pdx, pdy, 2 * s, 10 * s, C(0xA83038))
        crawlSketch(c, pdx + 4 * s, pdy + 3 * s, [".#.", "###", "#.#"], ["#": C(0xE8C050)], cell: 2 * s)
        for y in stride(from: pdy, to: pdy + 10 * s, by: 3 * s) { c.rect(pdx + Int(noise(y) * 10) * s, y, 4 * s, s, vine) }
        let hx = r.x + r.rx * 50 / 100, hyy = r.y - 20 * s
        for k in 0..<28 {
            let a = Double(k) * Double.pi / 14
            c.rect(hx + Int(cos(a) * Double(10 * s)), hyy + Int(sin(a) * Double(12 * s)), s, s, k % 4 == 0 ? C(0xE8E0D0) : C(0xC83040))
        }
        for k in 0..<10 {
            let a = Double(k) * 0.7 + 0.4
            c.rect(hx + Int(cos(a) * Double(10 * s)), hyy + Int(sin(a) * Double(12 * s)), 2 * s, s, vineL)
        }
        // The curb, in front of the mound: red boards, a gold top, vines spilling over it.
        for x in stride(from: r.x - r.rx - 2 * s, to: r.x + r.rx + 2 * s, by: s) {
            let u = Double(x - r.x) / Double(r.rx + 2 * s)
            let y = r.y - Int((1 - u * u).squareRoot() * Double(3 * s))
            c.rect(x, y, s, 5 * s, C(0x8A2228)); c.rect(x, y, s, s, C(0xC89A3A)); c.rect(x, y + 4 * s, s, s, C(0x4A1218))
            if noise(x / max(1, s) + 5) > 0.7 { c.rect(x, y - s, s, 3 * s + Int(noise(x / max(1, s) + 9) * 4) * s, vine) }
        }

        // The floor: dark sawdust, plain.
        c.ground(g, C(0x382A1E), edge: C(0x5A4430), speck: C(0x2C2016), seed: 97)
        c.ellipse(r.x, g + 3 * s, r.rx, 3 * s, C(0x7AA472, 0.05))
    }

    /// One king pole's rigging on the screen saver: its cap where the canvas meets it, a little platform with a rail
    /// halfway up, a rope ladder from the floor's height up to the platform, and vines at its edge.
    private static func crawlCircusRig(_ c: PixelCanvas, _ g: Int, _ x: Int, _ k: Int,
                                       _ f: (eave: Int, peak: Int, poles: [Int], ring: (x: Int, y: Int, rx: Int), mound: Int, swing: Int)) {
        let s = unit(g), py = g - 120 * s, dir = k == 0 ? 1 : -1
        let top = f.peak + 60 * s
        c.rect(x - 4 * s, top - 2 * s, 9 * s, 3 * s, C(0x3A2A1E)); c.rect(x - 4 * s, top - 2 * s, 9 * s, s, C(0x6A4A2E))
        let px0 = dir > 0 ? x - 2 * s : x - 18 * s
        c.rect(px0, py, 20 * s, 3 * s, C(0x6A4A2E)); c.rect(px0, py, 20 * s, s, C(0x8A6440))
        c.rect(px0, py - 8 * s, 20 * s, s, C(0x9A8A6A))
        for xx in [px0, px0 + 19 * s] { c.rect(xx, py - 8 * s, s, 8 * s, C(0x9A8A6A)) }
        for y in stride(from: py + 3 * s, to: py + 10 * s, by: s) { c.rect(x + dir * (2 + (y - py) / s) * s, y, s, s, C(0x4A3A2A)) }
        // The rope ladder down from the platform's outer edge.
        let lx = dir > 0 ? px0 + 16 * s : px0 + 2 * s, ly1 = g - 3 * s
        c.rect(lx, py + 3 * s, s, ly1 - py - 3 * s, C(0xB8A880)); c.rect(lx + 4 * s, py + 3 * s, s, ly1 - py - 3 * s, C(0xB8A880))
        for y in stride(from: py + 6 * s, to: ly1, by: 5 * s) { c.rect(lx, y, 5 * s, s, C(0x8A7A5A)) }
        c.rect(px0 + 3 * s, py - 3 * s, 14 * s, s, C(0x7AA472)); c.rect(px0 + 5 * s, py - 4 * s, 2 * s, s, C(0xA8D09A))
    }

    /// The circus's life: tendrils of vine reaching up out of the mound and off the poles, creeping a little longer
    /// and drawing back, their tips swaying and curling; a dead bulb on the strings buzzing on for a moment and out;
    /// and on the screen saver the two trapezes swinging slowly on their ropes, vine wound round one of them.
    static func crawlCircusLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlCircusFrame(c, g), r = f.ring
        let vine = C(0x7AA472), vineL = C(0xA8D09A), vineD = C(0x4A6E4A)
        // The tendrils.
        let roots: [(Double, Int)] = [(-0.7, 10), (-0.42, 16), (-0.15, 20), (0.1, 14), (0.32, 18), (0.62, 12), (0.85, 8)]
        for (k, root) in roots.enumerated() {
            let bx = r.x + Int(root.0 * Double(r.rx)), by = crawlCircusMoundTop(bx, f, s)
            guard by < r.y else { continue }
            let len = root.1 + Int(3 + 3 * sin(t * 0.35 + Double(k) * 1.3))
            let sway = sin(t * 0.9 + Double(k) * 2.1) * 3
            var lastX = bx, lastY = by
            for i in 0..<len {
                let v = Double(i) / Double(len)
                let x = bx + Int((sway * v * v + sin(v * 4 + Double(k)) * 1.5) * Double(s))
                let y = by - i * s
                c.rect(x, y, s, s, i % 2 == 0 ? vine : vineL); c.rect(x + s, y, max(1, s / 2), s, vineD)
                if i % 5 == 3 { c.rect(x + (k % 2 == 0 ? s : -2 * s), y, 2 * s, s, vineL) }
                lastX = x; lastY = y
            }
            // The curl at the tip.
            let cd = sway >= 0 ? 1 : -1
            c.rect(lastX + cd * s, lastY - s, s, s, vineL); c.rect(lastX + 2 * cd * s, lastY, s, s, vineL)
            c.rect(lastX + cd * s, lastY + s, s, s, vine)
        }
        // A tendril off each pole, reaching out sideways.
        for (k, x) in f.poles.enumerated() {
            let dir = k == 0 ? 1 : -1, y0 = f.eave - 6 * s - 10 * s + k * 4 * s
            let len = 8 + Int(3 * sin(t * 0.4 + Double(k)))
            for i in 0..<len {
                let yy = y0 + Int(sin(Double(i) / 3 + t * 0.8 + Double(k)) * Double(s)) + i * s / 3
                c.rect(x + dir * (3 + i) * s, yy, s, s, i % 2 == 0 ? vineL : vine)
            }
        }
        // The dead bulb's buzz.
        let buzz = t.truncatingRemainder(dividingBy: 6.5)
        if buzz > 5.6 && Int(t * 14) % 2 == 0 {
            let x = f.poles[0] + 22 * s, u = Double(x - f.poles[0]) / Double(max(1, f.poles[1] - f.poles[0]))
            let y = f.eave - 6 * s + Int(sin(u * Double.pi) * Double((f.poles[1] - f.poles[0]) / 10))
            c.rect(x, y + s, s, 2 * s, C(0xFFE8B0)); c.ellipse(x, y + 2 * s, 4 * s, 3 * s, C(0xFFC870, 0.14))
        }
        // The trapezes.
        guard f.swing > 0 else { return }
        for k in 0..<2 {
            let ax = r.x + (k == 0 ? -1 : 1) * r.rx * 45 / 100, len = Double(60 * s)
            let a = sin(t * 0.7 + Double(k) * 2.4) * 0.22
            let bx = ax + Int(sin(a) * len), by = f.swing + Int(cos(a) * len)
            for dx in [-7 * s, 7 * s] {
                c.glowLine(Double(ax + dx), Double(f.swing), Double(bx + dx), Double(by), core: C(0xB8A880), glow: C(0, 0),
                           coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            }
            c.rect(bx - 8 * s, by, 17 * s, 2 * s, C(0xC83040)); c.rect(bx - 8 * s, by, 17 * s, s, C(0xE85060))
            c.rect(bx - 8 * s, by, 2 * s, 2 * s, C(0xC89A3A)); c.rect(bx + 7 * s, by, 2 * s, 2 * s, C(0xC89A3A))
            if k == 0 {
                // Vine wound down the left rope, a leaf hanging from the bar.
                for i in 0..<14 {
                    let v = Double(i) / 14
                    let x = ax - 7 * s + Int(Double(bx - ax) * v), y = f.swing + Int(Double(by - f.swing) * v)
                    c.rect(x + (i % 2 == 0 ? -s : s), y, s, 2 * s, i % 3 == 0 ? vineL : vine)
                }
                c.rect(bx - 6 * s, by + 2 * s, s, 3 * s, vine); c.rect(bx - 7 * s, by + 5 * s, 2 * s, s, vineL)
            }
        }
        // Where the ropes are tied: an iron bar under the canvas.
        c.rect(r.x - r.rx * 45 / 100 - 10 * s, f.swing - s, r.rx * 90 / 100 + 20 * s, 2 * s, C(0x2A2020))
    }
}
