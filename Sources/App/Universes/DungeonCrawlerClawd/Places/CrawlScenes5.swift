import Foundation

// Places, a few to a file (see CrawlScenes1.swift for the rules): Iron Tangle station, Hump Town, the High Elf castle
// ballroom, the Hunting Grounds.

let crawlScenes5: [Location: Place] = [
    .crawlTangle: Place(name: "Iron Tangle station", panel: 0x141A1A, still: Scenes.crawlTangle, moving: Scenes.crawlTangleLife),
    .crawlHumpTown: Place(name: "Hump Town", panel: 0x24120E, still: Scenes.crawlHumpTown, moving: Scenes.crawlHumpTownLife),
    .crawlCastle: Place(name: "The High Elf castle ballroom", panel: 0x1E0C12, still: Scenes.crawlCastle,
                        moving: Scenes.crawlCastleLife),
    .crawlHunting: Place(name: "The Hunting Grounds", panel: 0x101A12, still: Scenes.crawlHunting,
        moving: Scenes.crawlHuntingLife),
]

/// Little pixel pictures drawn from rows of letters, each letter a square `cell` pixels wide (a place's unit, or two),
/// turned to face the other way when `flip` is set.
private func crawlPic(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ palette: [Character: Px], cell: Int,
                      flip: Bool = false) {
    for (r, row) in rows.enumerated() {
        let n = row.count
        for (k, ch) in row.enumerated() {
            guard let col = palette[ch] else { continue }
            let kx = flip ? n - 1 - k : k
            c.rect(x + kx * cell, y + r * cell, cell, cell, col)
        }
    }
}

/// A thick line through `points` (in pixels), `r` pixels either side of the middle: a line on the map, a cable.
private func crawlPath(_ c: PixelCanvas, _ points: [(Int, Int)], _ col: Px, r: Double) {
    for k in 1..<points.count {
        let a = points[k - 1], b = points[k]
        c.glowLine(Double(a.0), Double(a.1), Double(b.0), Double(b.1), core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

// MARK: - Iron Tangle station

extension Scenes {
    /// Where things stand in the station, shared by the still picture and the moving layer: the track bed's top, the
    /// top of the green tiles, the iron columns, the signal lamp, the departures board, and (on the screen saver) the
    /// girders' lowest beam and the strip lights hanging under it.
    static func crawlTangleFrame(_ c: PixelCanvas, _ g: Int) -> (track: Int, band: Int, columns: [Int], signal: (x: Int, y: Int),
                                                                 board: (x: Int, y: Int, w: Int, h: Int), girders: Int,
                                                                 tubes: [(x: Int, y: Int)]) {
        let s = unit(g), tall = isTall(c)
        let columns = [c.w * 34 / 100, c.w * 78 / 100]
        let board = (x: c.w * 66 / 100 - 13 * s, y: g - 57 * s, w: 26 * s, h: 9 * s)
        let girders = tall ? g - 64 * s : -1
        let tubes = tall ? [12, 50, 88].map { (x: c.w * $0 / 100, y: girders - 14 * s) } : []
        return (g - 10 * s, g - 40 * s, columns, (x: columns[0] + 5 * s, y: g - 34 * s), board, girders, tubes)
    }

    /// Iron Tangle station: a platform of the third floor's train network, grimy and iron-built. Across the track the
    /// far wall is tiled, dark green below and dirty cream above, with a rust-red trim between; the station's name is
    /// set into the cream in a big maroon mosaic tablet (IRON TANGLE); on the left hangs the network's map, four
    /// coloured lines knotted into a tangle; a round clock, an amber departures board and a System-blue loot box
    /// poster on the right. Two riveted iron columns stand along the track, a signal lamp on one. The track bed is dark
    /// ballast with sleepers, two rails and the third rail on its insulators under a yellow cover board, and the crew
    /// stands on the concrete platform behind its yellow safety edge. On the screen saver the walls rise into a roof
    /// of riveted girders braced in crosses, cables slung between them, strip lights and two hanging signs.
    static func crawlTangle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlTangleFrame(c, g)
        let grout = C(0x24302C)

        // The upper wall: dirty cream tiles, each a little different, grimy streaks running down.
        c.rect(0, 0, c.w, f.band, C(0x5E5A4E))
        let tw = 8 * s, th = 4 * s
        for (row, y) in stride(from: f.band - th, to: -th, by: -th).enumerated() {
            let shift = row % 2 == 0 ? 0 : tw / 2
            for (k, x) in stride(from: -shift, to: c.w, by: tw).enumerated() {
                let n = noise(row * 41 + k * 7)
                c.rect(x + s, y + s, tw - s, th - s, n > 0.8 ? C(0x9E9682) : n > 0.25 ? C(0x8E8874) : C(0x807A66))
                c.rect(x + s, y + s, tw - s, s, C(0xA8A28E))
            }
        }
        for k in 0..<9 {
            let x = c.w * (5 + k * 11) / 100 + Int(noise(k + 300) * Double(6 * s)), len = (8 + Int(noise(k + 310) * 14)) * s
            c.rect(x, f.band - 3 * s - len, s, len, C(0x5A5444, 0.35))
        }

        // The rust-red trim between the two, lit along its top.
        c.rect(0, f.band - 3 * s, c.w, 3 * s, C(0x7A3A2A)); c.rect(0, f.band - 3 * s, c.w, s, C(0x9A5240))
        for x in stride(from: 2 * s, to: c.w, by: 6 * s) { c.rect(x, f.band - 2 * s, 2 * s, s, C(0xB89048)) }

        // The lower wall: dark green tiles behind the crew, plain, grout between.
        c.rect(0, f.band, c.w, f.track - f.band, grout)
        for (row, y) in stride(from: f.band, to: f.track, by: th).enumerated() {
            let shift = row % 2 == 0 ? 0 : tw / 2
            for (k, x) in stride(from: -shift, to: c.w, by: tw).enumerated() {
                let n = noise(row * 53 + k * 11 + 900)
                c.rect(x + s, y + s, tw - s, th - s, n > 0.85 ? C(0x3A5650) : C(0x34504A))
                c.rect(x + s, y + s, tw - s, s, C(0x42605A))
            }
        }

        // On the screen saver: the roof of girders.
        if tall { crawlTangleGirders(c, g, f.girders, f.columns) }

        // The station's name: a maroon mosaic tablet with a cream border, the letters big and cream.
        let label = "IRON TANGLE", lw = crawlTextWidth(label, scale: 2 * s)
        let nw = lw + 12 * s, nh = 18 * s, nx = c.w / 2 - nw / 2, ny = g - 62 * s
        c.rect(nx - 2 * s, ny - 2 * s, nw + 4 * s, nh + 4 * s, C(0xD8CCA8))
        c.rect(nx - 2 * s, ny + nh + s, nw + 4 * s, s, C(0xA89C7C))
        c.rect(nx - s, ny - s, nw + 2 * s, nh + 2 * s, C(0x3A1A16))
        c.rect(nx, ny, nw, nh, C(0x6A2622))
        for y in stride(from: ny + 2 * s, to: ny + nh, by: 4 * s) { c.rect(nx, y, nw, max(1, s / 2), C(0x5A1E1A)) }
        for x in stride(from: nx + 3 * s, to: nx + nw, by: 4 * s) { c.rect(x, ny, max(1, s / 2), nh, C(0x5A1E1A)) }
        crawlText(c, nx + 6 * s + s, ny + 4 * s + s, label, C(0x2A100C), scale: 2 * s)
        crawlText(c, nx + 6 * s, ny + 4 * s, label, C(0xF0E2C0), scale: 2 * s)

        // The network's map on the left: a black frame, cream paper, four coloured lines knotted together, white
        // stations at the knots.
        let mx = c.w * 4 / 100, my = g - 58 * s, mw = 46 * s, mh = 30 * s
        c.rect(mx - 2 * s, my - 2 * s, mw + 4 * s, mh + 4 * s, C(0x1A1C1E))
        c.rect(mx - 2 * s, my - 2 * s, mw + 4 * s, s, C(0x3A3E42))
        c.rect(mx, my, mw, mh, C(0xC4BEA8)); c.rect(mx, my, mw, 5 * s, C(0x24305A))
        crawlText(c, mx + 2 * s, my, "MAP", C(0xF0ECDC), scale: s)
        func p(_ u: Int, _ v: Int) -> (Int, Int) { (mx + u * s, my + v * s) }
        let lines: [([(Int, Int)], Px)] = [
            ([p(3, 9), p(14, 9), p(22, 17), p(30, 17), p(36, 11), p(43, 11)], C(0xC8302A)),
            ([p(5, 27), p(12, 20), p(22, 20), p(28, 12), p(38, 12), p(42, 26)], C(0x2E8A3E)),
            ([p(9, 7), p(9, 16), p(24, 26), p(34, 26), p(34, 8)], C(0x2A5AC8)),
            ([p(3, 14), p(18, 14), p(26, 8), p(26, 24), p(40, 20), p(43, 20)], C(0xE0A020)),
        ]
        for (pts, col) in lines { crawlPath(c, pts, col, r: 0.9 * Double(s)) }
        for (u, v) in [(9, 9), (22, 17), (12, 20), (28, 12), (26, 14), (34, 26), (26, 20), (36, 12), (18, 14)] {
            let q = p(u, v)
            c.rect(q.0 - s, q.1 - s, 3 * s, 3 * s, C(0x1A1C1E)); c.rect(q.0, q.1, s, s, C(0xFFFFFF))
        }

        // The station clock: a white face in a black rim, its hands at ten to two.
        let kx = c.w * 22 / 100, ky = g - 50 * s
        c.rect(kx - s, ky - 13 * s, 2 * s, 5 * s, C(0x1A1C1E))
        c.circle(kx, ky, 7 * s, C(0x1A1C1E)); c.circle(kx, ky, 6 * s, C(0xE8E4D8))
        c.circle(kx - s, ky - s, 3 * s, C(0xF6F2E8))
        for (dx, dy) in [(0, -5), (5, 0), (0, 5), (-5, 0)] { c.rect(kx + dx * s, ky + dy * s, s, s, C(0x2A2A2E)) }
        crawlPath(c, [(kx, ky), (kx - 3 * s, ky - 3 * s)], C(0x1A1A1E), r: 0.6 * Double(s))
        crawlPath(c, [(kx, ky), (kx + 4 * s, ky - 3 * s)], C(0x1A1A1E), r: 0.6 * Double(s))
        c.rect(kx, ky, s, s, C(0xC8302A))

        // The departures board: a black box on two rods, its amber text in the moving layer.
        let b = f.board
        let rod = tall ? f.girders : 0
        for x in [b.x + 4 * s, b.x + b.w - 5 * s] { c.rect(x, rod, s, b.y - rod, C(0x2A2C2E)) }
        c.rect(b.x - s, b.y - s, b.w + 2 * s, b.h + 2 * s, C(0x3A3E42)); c.rect(b.x, b.y, b.w, b.h, C(0x0E0E10))
        c.rect(b.x - s, b.y - s, b.w + 2 * s, s, C(0x5A5E62))

        // The loot box poster on the right: System blue, a gold chest glowing, LOOT! under it.
        let px = c.w * 85 / 100, py = g - 60 * s, pw = 34 * s, ph = 28 * s
        c.rect(px - s, py - s, pw + 2 * s, ph + 2 * s, C(0x1A1C1E))
        c.rect(px, py, pw, ph, C(0x14306E)); c.rect(px, py, pw, s, C(0x3A6AC8))
        c.ellipse(px + pw / 2, py + 10 * s, 11 * s, 7 * s, C(0x6AB4FF, 0.18))
        let chest = ["..gggggggg..", ".gGGGGGGGGg.", "gGGGGGGGGGGg", "kkkkkyykkkkk", "gGGGGyyGGGGg", "gGGGGGGGGGGg",
                     "gggggggggggg"]
        crawlPic(c, px + pw / 2 - 12 * s, py + 4 * s, chest, ["g": C(0x9A6A20), "G": C(0xE0B040), "k": C(0x4A3010),
                                                              "y": C(0xFFF0A0)], cell: 2 * s)
        crawlText(c, px + pw / 2 - crawlTextWidth("LOOT!", scale: s) / 2, py + 20 * s, "LOOT!", C(0xF0F6FF), scale: s)

        // The iron columns along the track: riveted I-beams, rust-dark, lit on the left, on a base plate.
        for x in f.columns {
            let top = tall ? f.girders : 0
            c.rect(x - 4 * s, top, 8 * s, f.track + 2 * s - top, C(0x4A2E26))
            c.rect(x - 4 * s, top, 2 * s, f.track + 2 * s - top, C(0x6A4434))
            c.rect(x + 2 * s, top, 2 * s, f.track + 2 * s - top, C(0x3A221C))
            c.rect(x - s, top, 2 * s, f.track + 2 * s - top, C(0x3E2620))
            for y in stride(from: top + 3 * s, to: f.track, by: 7 * s) {
                c.rect(x - 3 * s, y, s, s, C(0x8A5A44)); c.rect(x + 3 * s, y, s, s, C(0x5A3628))
            }
            c.rect(x - 6 * s, f.track, 12 * s, 3 * s, C(0x3A221C)); c.rect(x - 6 * s, f.track, 12 * s, s, C(0x6A4434))
        }
        // The signal on the first column: a black hood, the red lamp lit (the moving layer turns it green).
        let sg = f.signal
        c.rect(sg.x, sg.y - s, 6 * s, 12 * s, C(0x141416)); c.rect(sg.x, sg.y - s, 6 * s, s, C(0x3A3A3E))
        c.rect(sg.x + 2 * s, sg.y + s, 2 * s, 2 * s, C(0xE0302A))
        c.rect(sg.x + 2 * s, sg.y + 6 * s, 2 * s, 2 * s, C(0x1E3A22))
        c.ellipse(sg.x + 3 * s, sg.y + 2 * s, 4 * s, 3 * s, C(0xFF4030, 0.15))

        // The track bed: dark ballast, sleepers, two steel rails, and the third rail on its insulators under its
        // yellow cover board.
        c.rect(0, f.track, c.w, g - f.track, C(0x221E1C))
        for i in 0..<(c.w * (g - f.track) / (9 * s * s)) {
            let x = Int(noise(i * 5 + 61) * Double(c.w)), y = f.track + Int(noise(i * 5 + 62) * Double(g - f.track))
            c.rect(x, y, s, s, noise(i + 77) > 0.5 ? C(0x34302C) : C(0x161412))
        }
        for x in stride(from: 0, to: c.w, by: 7 * s) { c.rect(x, g - 7 * s, 4 * s, 6 * s, C(0x2E2620))
            c.rect(x, g - 7 * s, 4 * s, s, C(0x40362C)) }
        for y in [g - 6 * s, g - 2 * s] { c.rect(0, y, c.w, s, C(0x8A8E96)); c.rect(0, y - s, c.w, s, C(0xC0C4CC)) }
        for x in stride(from: 3 * s, to: c.w, by: 16 * s) { c.rect(x, f.track + 2 * s, 2 * s, 2 * s, C(0xC8C0B0)) }
        c.rect(0, f.track + s, c.w, s, C(0xC8A030)); c.rect(0, f.track, c.w, s, C(0xE0C050))

        // The platform: plain grey concrete behind the yellow safety edge and its row of studs.
        c.ground(g, C(0x3A3A3E), edge: C(0xE0B830), speck: C(0x323236), seed: 61)
        c.rect(0, g, c.w, 2 * s, C(0xD0A828)); c.rect(0, g, c.w, s, C(0xE8C440))
        for x in stride(from: s, to: c.w, by: 3 * s) { c.rect(x, g + s, s, s, C(0xA88418)) }
        for x in stride(from: 20 * s, to: c.w, by: 40 * s) { c.rect(x, g + 2 * s, max(1, s / 2), c.h - g - 2 * s, C(0x303034)) }
    }

    /// The screen saver's roof over the platform: a dark void crossed by riveted iron girders, a beam every so high,
    /// the columns carried up through them and braced in crosses between; cables sagging from column to column; a
    /// green WAY OUT sign and a TRAINS sign hanging off the beams, and three strip lights on wires.
    private static func crawlTangleGirders(_ c: PixelCanvas, _ g: Int, _ low: Int, _ cols: [Int]) {
        let s = unit(g), iron = C(0x4A2E26), ironL = C(0x6A4434), ironD = C(0x2E1C16)
        c.gradient(0, low, C(0x0E1012), C(0x1E2224), bands: 5)
        let posts = [0] + cols + [c.w]
        let beams = Array(stride(from: low - 6 * s, to: 0, by: -46 * s))
        // The bracing first, behind the beams: a cross in every bay between two beams.
        for (k, y) in beams.enumerated() where k + 1 < beams.count {
            let y2 = beams[k + 1] + 6 * s
            for j in 1..<posts.count {
                let a = posts[j - 1] + 4 * s, b = posts[j] - 4 * s
                crawlPath(c, [(a, y), (b, y2)], C(0x3E2620), r: 1.2 * Double(s))
                crawlPath(c, [(a, y2), (b, y)], C(0x3E2620), r: 1.2 * Double(s))
            }
        }
        // The cables, sagging between the columns over the lowest beam: the tangle the station's named for.
        for (k, droop) in [10, 16, 7].enumerated() {
            for j in 1..<posts.count {
                let a = posts[j - 1], b = posts[j], y0 = low - (20 + k * 9) * s
                var pts: [(Int, Int)] = []
                for i in 0...8 {
                    let u = Double(i) / 8
                    pts.append((a + Int(Double(b - a) * u), y0 + Int(4 * u * (1 - u) * Double(droop * s))))
                }
                crawlPath(c, pts, [C(0x5A5E64), C(0x7A3A30), C(0x3A6A4A)][k], r: 0.7 * Double(s))
            }
        }
        // The beams, riveted, lit along their tops.
        for y in beams {
            c.rect(0, y, c.w, 6 * s, iron); c.rect(0, y, c.w, s, ironL); c.rect(0, y + 5 * s, c.w, s, ironD)
            for x in stride(from: 3 * s, to: c.w, by: 9 * s) { c.rect(x, y + 2 * s, s, s, C(0x8A5A44)) }
        }
        // The hanging signs, off the second beam: WAY OUT on green with an arrow, TRAINS on blue.
        let hang = beams.count > 1 ? beams[1] + 6 * s : 0
        for (k, sign) in [("WAY OUT", C(0x1E6A3A), 26), ("TRAINS", C(0x1E3A7A), 66)].enumerated() {
            let w = crawlTextWidth(sign.0, scale: 2 * s) + (k == 0 ? 18 : 8) * s, h = 16 * s
            let x = c.w * sign.2 / 100 - w / 2, y = low - 40 * s
            for rx in [x + 4 * s, x + w - 5 * s] { c.rect(rx, hang, s, y - hang, C(0x2A2C2E)) }
            c.rect(x - s, y - s, w + 2 * s, h + 2 * s, C(0x101214)); c.rect(x, y, w, h, sign.1)
            c.rect(x, y, w, s, sign.1.alpha(0.6))
            crawlText(c, x + 4 * s, y + 3 * s, sign.0, C(0xF4F4EE), scale: 2 * s)
            if k == 0 {
                let ax = x + w - 12 * s, ay = y + 8 * s
                c.rect(ax, ay - s, 7 * s, 2 * s, C(0xF4F4EE))
                for i in 0..<4 { c.rect(ax + 4 * s + i * s, ay - (4 - i) * s, s, 2 * (4 - i) * s, C(0xF4F4EE)) }
            }
        }
        // The strip lights on their wires, the tube itself in the moving layer.
        let upper = beams.count > 1 ? beams[1] + 6 * s : 0
        for (x, y) in crawlTangleFrame(c, g).tubes {
            for wx in [x - 8 * s, x + 8 * s] { c.rect(wx, upper, max(1, s / 2), y - upper, C(0x2A2C2E)) }
            c.rect(x - 10 * s, y, 20 * s, 3 * s, C(0x3A3E42)); c.rect(x - 10 * s, y, 20 * s, s, C(0x5A5E62))
            c.rect(x - 9 * s, y + 3 * s, 18 * s, s, C(0xB8C8B8))
        }
    }

    /// The station's life: every eleven seconds a train rushes through right to left, silver cars with a red stripe
    /// and lit windows, the signal turning green as it comes and back to red after; the departures board counting
    /// down the minutes (NOW when it's in); and on the screen saver the strip lights, one of them flickering.
    static func crawlTangleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlTangleFrame(c, g), period = 11.0, run = 1.6
        let u = (t + 10.9).truncatingRemainder(dividingBy: period)
        let due = u < run || u > period - 1.5
        // The signal and the board.
        if due {
            let sg = f.signal
            c.rect(sg.x + 2 * s, sg.y + s, 2 * s, 2 * s, C(0x2A1210))
            c.rect(sg.x + 2 * s, sg.y + 6 * s, 2 * s, 2 * s, C(0x50F070))
            c.rect(sg.x + 2 * s, sg.y + 6 * s, s, s, C(0xE0FFE8))
            c.ellipse(sg.x + 3 * s, sg.y + 7 * s, 5 * s, 4 * s, C(0x50F070, 0.16))
        }
        let b = f.board, text = due ? "NOW" : "\(max(1, Int((period - u) / 3))) MIN"
        let amber = C(0xF0A830)
        crawlText(c, b.x + b.w / 2 - crawlTextWidth(text, scale: s) / 2, b.y + 2 * s, text,
            due && Int(t * 4) % 2 == 0 ? amber.alpha(0.5) : amber, scale: s)
        // The strip lights, one flickering now and then.
        for (k, l) in f.tubes.enumerated() {
            let off = k == 1 && Int(t * 11) % 23 < 2
            if off { continue }
            c.rect(l.x - 9 * s, l.y + 3 * s, 18 * s, s, C(0xF0F8EC))
            c.ellipse(l.x, l.y + 8 * s, 22 * s, 6 * s, C(0xE0F0E0, 0.05))
        }
        guard u < run else { return }
        // The train.
        let k = u / run, carW = 72 * s, cars = 5, length = cars * carW
        let head = c.w - Int(Double(c.w + length + 20 * s) * k)
        for i in 0..<cars { crawlTangleCar(c, g, x: head + i * carW, w: carW - 2 * s, front: i == 0) }
        // Speed streaks trailing off the last car.
        let tail = head + length
        if tail < c.w {
            for (j, y) in [g - 28 * s, g - 18 * s, g - 9 * s].enumerated() {
                c.rect(tail, y, (30 + j * 12) * s, s, C(0xC0C4CC, 0.18))
            }
        }
    }

    /// One car of the train, `w` wide from `x`, its wheels on the rails: a silver body lit along the top, a darker
    /// roof, a row of warm windows with a passenger or two, a pair of doors, a red stripe along its side and the
    /// bogies underneath. The front car has a sloped cab, its headlight blazing.
    private static func crawlTangleCar(_ c: PixelCanvas, _ g: Int, x: Int, w: Int, front: Bool) {
        let s = unit(g), top = g - 36 * s, bot = g - 4 * s
        guard x < c.w, x + w > 0 else { return }
        let body = C(0x8A8E98), bodyL = C(0xB0B4BE), bodyD = C(0x60646E)
        c.rect(x, top + 3 * s, w, bot - top - 3 * s, body)
        c.rect(x + 2 * s, top, w - 4 * s, 3 * s, C(0x5A5E66)); c.rect(x + 2 * s, top, w - 4 * s, s, C(0x7A7E86))
        c.rect(x, top + 3 * s, w, s, bodyL); c.rect(x, bot - 2 * s, w, 2 * s, bodyD)
        // The windows, lit warm, a passenger's head in some.
        for (k, wx) in stride(from: x + 5 * s, to: x + w - 9 * s, by: 11 * s).enumerated() {
            c.rect(wx, top + 7 * s, 8 * s, 8 * s, C(0xE8D898)); c.rect(wx, top + 7 * s, 8 * s, s, C(0xB8A868))
            if noise(x / max(1, s) + k * 13) > 0.5 {
                c.rect(wx + 2 * s, top + 10 * s, 4 * s, 5 * s, C(0x5A4A3A))
                c.rect(wx + 2 * s, top + 10 * s, 4 * s, s, C(0x3A2A20))
            }
        }
        // The doors.
        let dx = x + w / 2 - 5 * s
        c.rect(dx, top + 6 * s, 10 * s, bot - top - 8 * s, C(0x6A6E78))
        c.rect(dx + 5 * s, top + 6 * s, max(1, s / 2), bot - top - 8 * s, C(0x3A3E46))
        c.rect(dx + s, top + 8 * s, 3 * s, 6 * s, C(0xD8C888)); c.rect(dx + 6 * s, top + 8 * s, 3 * s, 6 * s, C(0xD8C888))
        // The red stripe.
        c.rect(x, g - 16 * s, w, 3 * s, C(0xB03428)); c.rect(x, g - 16 * s, w, s, C(0xD04A3A))
        // The bogies and wheels.
        c.rect(x, bot, w, 2 * s, C(0x1A1A1E))
        for wx in [x + 8 * s, x + 16 * s, x + w - 18 * s, x + w - 10 * s] {
            c.circle(wx, g - 3 * s, 2 * s, C(0x2A2A30)); c.rect(wx, g - 3 * s, s, s, C(0x8A8E96))
        }
        // The cab: sloped at the front, a dark windscreen, the headlight and its beam.
        if front {
            for i in 0..<8 { c.rect(x - (8 - i) * s, top + (3 + i * 2) * s, (8 - i) * s, bot - top - (3 + i * 2) * s, body) }
            c.rect(x - 6 * s, top + 8 * s, 6 * s, 7 * s, C(0x1A2028)); c.rect(x - 5 * s, top + 9 * s, 2 * s, s, C(0x6A8AA8))
            c.rect(x - 8 * s, g - 12 * s, 3 * s, 3 * s, C(0xFFF4C0))
            c.ellipse(x - 14 * s, g - 11 * s, 9 * s, 3 * s, C(0xFFF0B0, 0.16))
        }
    }
}

// MARK: - Hump Town

/// A camel lying down to rest, facing left: the head held up on its curved neck, the one big hump with a striped red
/// blanket over it, the legs folded under. Its tail is the moving layer's.
private let crawlHumpCamel = [
    "..llll........................",
    ".lbbbbl.......................",
    "kbbebbbd......................",
    ".bbbbbbd......................",
    "..ddbbbd...........llll.......",
    ".....bbd.........lbbbbbl......",
    "......bbd......lbbbbbbbbl.....",
    ".......bbl...lbbbbbbbbbbbll...",
    "........bbllbbrrrrrrrrrbbbbbl.",
    "........bbbbbbryyyyyyyrbbbbbd.",
    "........bbbbbbrrrrrrrrrbbbbbd.",
    "........dbbbbbbbbbbbbbbbbbbdd.",
    ".......lbbbbbddddddddddbbbbbd.",
    "......lbbbbbd.........lbbbbbd.",
    "......dddddddd........dddddddd",
]

extension Scenes {
    /// Where things stand in Hump Town, shared by the still picture and the moving layer: the horizon, the red sun,
    /// the camels (each one's left edge, and whether it faces right), the lantern on the inn's corner, and (on the
    /// screen saver) the line the vultures circle on.
    static func crawlHumpTownFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, sun: (x: Int, y: Int, r: Int),
                                                                   camels: [(x: Int, flip: Bool)], lantern: (x: Int, y: Int),
                                                                   vultures: Int) {
        let s = unit(g), tall = isTall(c)
        let sun = tall ? (x: c.w * 62 / 100, y: g - 78 * s, r: 34 * s) : (x: c.w * 62 / 100, y: g - 24 * s, r: 22 * s)
        let camels = [(x: c.w * 70 / 100, flip: false), (x: c.w * 86 / 100, flip: true)]
        return (g - 16 * s, sun, camels, (x: c.w * 4 / 100 + 81 * s, y: g - 22 * s), tall ? g * 30 / 100 : -1)
    }

    /// Hump Town: the Fifth Floor's desert stop, at sundown. The sky burns from violet down to orange, a huge red sun
    /// sinking behind the dunes, which stand dark against it with a red rim along their crests. On the left the Toe,
    /// the town's inn: a two-storey adobe block, wooden beam ends poking from the top, a parapet, blue shutters, an
    /// arched door with warm light inside, a lantern on the corner, and its signboard (THE TOE, a two-toed hoof beside the
    /// words); a palm leans over it. On the right two camels rest, legs folded under, striped blankets on their humps.
    /// The ground is plain dark sand. On the screen saver the sun rides higher over the dunes, a caravan crosses the
    /// far crest, long clouds glow red underneath, a crescent moon and the first stars
    /// come out at the top, and vultures circle.
    static func crawlHumpTown(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlHumpTownFrame(c, g)

        // The sky, violet to orange, banded.
        if tall {
            c.gradient(0, g, C(0x1C1232), C(0xE8783A), bands: 10)
            c.stars(0, g * 30 / 100, density: 70, seed: 13)
            // The moon, a pale crescent high on the left.
            let mx = c.w * 16 / 100, my = g * 6 / 100
            c.circle(mx, my, 12 * s, C(0xF4E8D0, 0.12)); c.circle(mx, my, 9 * s, C(0xF0E4C8))
            c.circle(mx + 4 * s, my - 2 * s, 8 * s, C(0x1C1232))
            // Long streaks of cloud, their bellies lit red by the sun below.
            for (k, cl) in [(30, 34, 120), (72, 28, 90), (52, 46, 150), (14, 52, 100), (86, 58, 120)].enumerated() {
                let x = c.w * cl.0 / 100, y = g * cl.1 / 100, len = cl.2 * s
                c.rect(x - len / 2, y, len, 2 * s, C(0x5A2A4A))
                c.rect(x - len / 3, y - 2 * s, len * 2 / 3, 2 * s, C(0x4A2444))
                c.rect(x - len / 2 + 4 * s, y + 2 * s, len - 8 * s, s, k % 2 == 0 ? C(0xE0605A) : C(0xF08A5A))
            }
        } else {
            c.gradient(0, g, C(0x6A2A4A), C(0xF0883E), bands: 6)
        }
        // The red sun: a soft glow round it, the disc, a brighter heart, two haze lines across its lower half.
        let sun = f.sun
        c.circle(sun.x, sun.y, sun.r + 8 * s, C(0xFF6A3A, 0.10)); c.circle(sun.x, sun.y, sun.r + 4 * s, C(0xFF6A3A, 0.14))
        c.circle(sun.x, sun.y, sun.r, C(0xC8342A))
        c.circle(sun.x - sun.r / 6, sun.y - sun.r / 6, sun.r * 3 / 4, C(0xDC4630))
        for (k, dy) in [sun.r / 3, sun.r * 2 / 3].enumerated() {
            let half = Int((Double(sun.r * sun.r - dy * dy)).squareRoot())
            c.rect(sun.x - half, sun.y + dy, half * 2, (k + 1) * s, C(0xF07840, 0.55))
        }

        // The dunes: a far range, dark against the sun, a red rim along the crest; then nearer ones, a little lighter.
        c.dunes(base: f.horizon + 2 * s, amp: Double(6 * s), freq: 0.012 / Double(s), phase: 1.3, bottom: g,
            C(0x4A2432), shade: C(0xC85040))
        if tall {
            // A caravan crossing the far crest: camels and riders in silhouette, nose to tail.
            for k in 0..<5 {
                let x = c.w * 36 / 100 + k * 16 * s, fx = Double(x + 4 * s), fq = 0.012 / Double(s)
                let wave = sin(fx * fq + 1.3) * 0.6 + sin(fx * fq * 2.3 + 1.3 * 1.7) * 0.4
                let crest = f.horizon + 2 * s - Int(wave * Double(6 * s)) + s
                c.rect(x, crest - 6 * s, 8 * s, 3 * s, C(0x2A1420))
                c.rect(x + 2 * s, crest - 8 * s, 3 * s, 2 * s, C(0x2A1420))
                c.rect(x + 8 * s, crest - 9 * s, s, 4 * s, C(0x2A1420))
                c.rect(x + 8 * s, crest - 9 * s, 3 * s, s, C(0x2A1420))
                for lx in [x + s, x + 6 * s] { c.rect(lx, crest - 3 * s, s, 4 * s, C(0x2A1420)) }
                c.rect(x + 3 * s, crest - 11 * s, 2 * s, 3 * s, C(0x2A1420))
            }
        }
        c.dunes(base: g - 7 * s, amp: Double(4 * s), freq: 0.02 / Double(s), phase: 4.1, bottom: g, C(0x6A3834),
            shade: C(0xB0583E))

        // The Toe.
        crawlHumpTownInn(c, g, x: c.w * 4 / 100)

        // The palm, leaning over the inn: a ringed trunk curving up, a crown of drooping fronds, dates under them.
        let base = (x: c.w * 30 / 100, y: g), crown = (x: c.w * 30 / 100 - 10 * s, y: g - 52 * s)
        for i in 0..<26 {
            let v = Double(i) / 25, bend = Int(sin(v * .pi / 2) * Double(crown.x - base.x))
            let y = base.y - Int(v * Double(base.y - crown.y)), x = base.x + bend
            c.rect(x - 2 * s, y - 2 * s, 4 * s, 3 * s, i % 2 == 0 ? C(0x6A4A2E) : C(0x5A3C24))
            c.rect(x - 2 * s, y - 2 * s, s, 3 * s, C(0x8A6440))
        }
        for (k, fr) in [(-160.0, 22), (-130.0, 20), (-100.0, 14), (-60.0, 20), (-25.0, 22), (5.0, 16), (-195.0, 16)].enumerated() {
            var pts: [(Int, Int)] = []
            for i in 0...6 {
                let d = Double(i) / 6 * Double(fr.1 * s), droop = Double(i * i) * 0.4 * Double(s)
                let p = crawlReach((Double(crown.x), Double(crown.y)), fr.0, d)
                pts.append((Int(p.x), Int(p.y + droop)))
            }
            crawlPath(c, pts, k % 2 == 0 ? C(0x2E5A2E) : C(0x3E6E34), r: 1.3 * Double(s))
            for (i, q) in pts.enumerated() where i > 0 && i % 2 == 0 { c.rect(q.0, q.1 + s, s, 2 * s, C(0x24461F)) }
        }
        for (dx, dy) in [(-2, 2), (1, 3), (-1, 4)] { c.rect(crown.x + dx * s, crown.y + dy * s, 2 * s, 2 * s, C(0x8A3A1A)) }
        c.rect(crown.x - s, crown.y - s, 3 * s, 2 * s, C(0x4A7A3A))

        // The camels, resting.
        let pal: [Character: Px] = ["b": C(0xA87A4E), "l": C(0xC89A64), "d": C(0x7A5434), "k": C(0x2A1A10), "e": C(0x2A1A10),
                                    "r": C(0xA8302A), "y": C(0xE8B040)]
        for cm in f.camels {
            c.ellipse(cm.x + 18 * s, g - s, 16 * s, 2 * s, C(0x2A140E, 0.35))
            crawlPic(c, cm.x, g - 15 * s, crawlHumpCamel, pal, cell: s, flip: cm.flip)
        }

        // The ground: plain dark sand, a few ripples.
        c.ground(g, C(0x5E3E2A), edge: C(0x8A5C3A), speck: C(0x523424), seed: 67)
        for k in 0..<6 {
            let x = c.w * (8 + k * 16) / 100, y = g + 3 * s + (k % 3) * 2 * s
            c.rect(x, y, 10 * s, max(1, s / 2), C(0x704A32))
        }
    }

    /// The Toe, Hump Town's inn, standing on the ground from `x`: a wide adobe ground floor with its parapet and a
    /// smaller upper storey on the left, lit from the left; beam ends poking from under the roofs; blue-shuttered
    /// windows; the arched door, warm inside; the lantern on its hook; and the painted signboard over the door.
    private static func crawlHumpTownInn(_ c: PixelCanvas, _ g: Int, x: Int) {
        let s = unit(g)
        let mud = C(0xB47A4C), mudD = C(0x8E5A38), mudL = C(0xD09868), beam = C(0x4A2E1A)
        let lw = 88 * s, lh = 30 * s, uw = 40 * s, uh = 16 * s
        // The upper storey.
        c.rect(x, g - lh - uh, uw, uh, mud); c.rect(x, g - lh - uh, 2 * s, uh, mudL)
        c.rect(x + uw - 3 * s, g - lh - uh, 3 * s, uh, mudD)
        c.rect(x - s, g - lh - uh - 2 * s, uw + 2 * s, 2 * s, mudL)
        for bx in stride(from: x + 3 * s, to: x + uw - 2 * s, by: 7 * s) { c.rect(bx, g - lh - uh + 2 * s, 2 * s, 2 * s, beam) }
        c.rect(x + 14 * s, g - lh - 11 * s, 10 * s, 8 * s, C(0x1E1410))
        c.rect(x + 11 * s, g - lh - 11 * s, 3 * s, 8 * s, C(0x2A6A7A))
        c.rect(x + 24 * s, g - lh - 11 * s, 3 * s, 8 * s, C(0x225868))
        c.rect(x + 15 * s, g - lh - 9 * s, 8 * s, 4 * s, C(0xF0A050, 0.6))
        // The ground floor.
        c.rect(x, g - lh, lw, lh, mud); c.rect(x, g - lh, 2 * s, lh, mudL); c.rect(x + lw - 3 * s, g - lh, 3 * s, lh, mudD)
        c.rect(x - s, g - lh - 2 * s, lw + 2 * s, 2 * s, mudL); c.rect(x - s, g - lh, lw + 2 * s, s, mudD)
        for bx in stride(from: x + uw + 4 * s, to: x + lw - 2 * s, by: 7 * s) { c.rect(bx, g - lh + 2 * s, 2 * s, 2 * s, beam) }
        // Cracks and patches in the mud.
        for (dx, dy) in [(6, 8), (70, 14), (52, 22), (80, 6)] {
            for i in 0..<3 { c.rect(x + (dx + i) * s, g - lh + (dy + i) * s, s, s, mudD) }
        }
        // The arched door, warm light inside, a step.
        let dx = x + 30 * s, dw = 16 * s, dh = 18 * s
        c.rect(dx - 2 * s, g - dh, dw + 4 * s, dh, mudD)
        c.ellipse(dx + dw / 2, g - dh + 2 * s, dw / 2 + 2 * s, 4 * s, mudD)
        c.rect(dx, g - dh + 2 * s, dw, dh - 2 * s, C(0x6A361A))
        c.ellipse(dx + dw / 2, g - dh + 2 * s, dw / 2, 3 * s, C(0x6A361A))
        c.rect(dx + 2 * s, g - dh + 6 * s, dw - 4 * s, dh - 6 * s, C(0x8A4A22))
        c.rect(dx + 4 * s, g - dh + 8 * s, dw - 8 * s, dh - 8 * s, C(0xC07038))
        c.rect(dx - 3 * s, g - 2 * s, dw + 6 * s, 2 * s, C(0x7A5034))
        // A window either side of the door, its blue shutters open.
        for wx in [x + 10 * s, x + 62 * s] {
            c.rect(wx, g - 22 * s, 10 * s, 9 * s, C(0x1E1410)); c.rect(wx + s, g - 20 * s, 8 * s, 5 * s, C(0xF0A050, 0.45))
            c.rect(wx - 4 * s, g - 22 * s, 4 * s, 9 * s, C(0x2A6A7A))
            c.rect(wx + 10 * s, g - 22 * s, 4 * s, 9 * s, C(0x225868))
            for k in 0..<3 { c.rect(wx - 4 * s, g - (21 - k * 3) * s, 4 * s, s, C(0x1E4E5A))
                c.rect(wx + 10 * s, g - (21 - k * 3) * s, 4 * s, s, C(0x1A4450)) }
            c.rect(wx - s, g - 13 * s, 12 * s, s, mudL)
        }
        // The signboard over the door, fixed to the wall: THE TOE and a two-toed hoof.
        let label = "THE TOE", sw = crawlTextWidth(label, scale: s) + 16 * s, sx = dx + dw / 2 - sw / 2, sy = g - 29 * s
        c.rect(sx - s, sy - s, sw + 2 * s, 10 * s, C(0x3A2210))
        c.rect(sx, sy, sw, 8 * s, C(0x7A4A26)); c.rect(sx, sy, sw, s, C(0x9A6A3A))
        crawlText(c, sx + 2 * s, sy + 2 * s, label, C(0xF4D890), scale: s)
        crawlPic(c, sx + sw - 11 * s, sy + 2 * s, [".##.##.", "###.###", "###.###", ".##.##."], ["#": C(0xF4D890)], cell: s)
        // The lantern's hook (the flame is the moving layer's).
        let l = crawlHumpTownFrame(c, g).lantern
        c.rect(l.x - 2 * s, l.y - 3 * s, 4 * s, s, C(0x2A1A10)); c.rect(l.x, l.y - 2 * s, s, 2 * s, C(0x2A1A10))
        c.rect(l.x - 2 * s, l.y, 5 * s, 6 * s, C(0x2A1A10)); c.rect(l.x - s, l.y + s, 3 * s, 4 * s, C(0x5A3A1A))
    }

    /// Hump Town's life: heat shimmering over the dunes in faint drifting streaks, the nearer camel swishing its tail,
    /// the lantern on the inn's corner flickering, and on the screen saver two vultures circling high up.
    static func crawlHumpTownLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlHumpTownFrame(c, g)
        for k in 0..<7 {
            let y = f.horizon - 2 * s + k * 2 * s, len = (30 + Int(noise(k + 500) * 40)) * s
            let x = Int(Double(c.w) * noise(k + 510) + sin(t * 0.9 + Double(k)) * Double(14 * s)) - len / 2
            c.rect(x, y, len, s, C(0xFFC890, 0.07 + 0.04 * sin(t * 2.3 + Double(k * 2))))
        }
        // The tails: hanging from each camel's rump, the nearer one swishing.
        for (i, cm) in f.camels.enumerated() {
            let swish = i == 0 ? sin(t * 2.6) : 0.15 * sin(t * 0.7)
            let rootX = cm.flip ? cm.x + s : cm.x + 29 * s, rootY = g - 7 * s, dir = cm.flip ? -1.0 : 1.0
            let a = 80.0 - 40.0 * swish * dir
            let tip = crawlReach((Double(rootX), Double(rootY)), cm.flip ? 180 - a : a, Double(7 * s))
            c.glowLine(Double(rootX), Double(rootY), tip.x, tip.y, core: C(0x7A5434), glow: C(0, 0),
                coreR: 0.6 * Double(s), glowR: 0.7 * Double(s))
            c.rect(Int(tip.x) - s, Int(tip.y), 2 * s, 2 * s, C(0x3A2414))
        }
        // The lantern.
        let l = f.lantern, flick = 0.8 + 0.2 * sin(t * 13) * sin(t * 5.3)
        c.ellipse(l.x, l.y + 3 * s, 8 * s, 6 * s, C(0xFFB050, 0.10 * flick))
        c.rect(l.x - s, l.y + s, 3 * s, 4 * s, C(0xF0A040, flick)); c.rect(l.x, l.y + 2 * s, s, 2 * s, C(0xFFE8A0, flick))
        // The vultures, circling.
        guard f.vultures > 0 else { return }
        for k in 0..<2 {
            let a = t * 0.35 + Double(k) * .pi
            let x = c.w * 36 / 100 + Int(cos(a) * Double(40 * s)), y = f.vultures + Int(sin(a) * Double(10 * s))
            let flap = Int(t * 2 + Double(k)) % 3 == 0 ? s : 0
            c.rect(x - 5 * s, y - flap, 4 * s, s, C(0x2A1420)); c.rect(x + 2 * s, y - flap, 4 * s, s, C(0x2A1420))
            c.rect(x - s, y, 3 * s, 2 * s, C(0x2A1420))
        }
    }
}

// MARK: - The High Elf castle ballroom

/// A chandelier, drawn in double units: a gold crown of arms with candles on top, tiers of crystal drops below.
private let crawlCastleChandelier = [
    "...f..f..f..f..f...",
    "...w..w..w..w..w...",
    "..GGGGGGGGGGGGGGG..",
    "..gcgggggggggggcg..",
    "...c..GGGGGGG..c...",
    ".......gcgcgg......",
    "........c.c........",
    ".........c.........",
]

/// The masks on the walls, in double units: a gold half-mask with three feathers, a white Venetian face with gold
/// trim, a black one edged in silver, a violet one with a gold swirl.
private let crawlCastleMasks: [([String], [Character: Px])] = [
    ([".....r.p.r.....", "......rpr......", ".mmmmmmmmmmmmm.", "mMMMMMmmmMMMMMm", "mM..MMmmmM..MMm", "mMM.MMm.mMM.MMm",
      ".mMMMmm.mmMMMm.", "...mmm...mmm..."],
     ["m": C(0xB88A2A), "M": C(0xF0C850), "r": C(0xC8302A), "p": C(0x4A8ACC)]),
    (["..ggggggggg..", ".gWWWWWWWWWg.", "gWWWWWWWWWWWg", "gWW..WWW..WWg", "gWWWWWWWWWWWg", ".gWWWWdWWWWg.",
      "..gWWW.WWWg..", "...gWWWWWg...", "....ggggg...."],
     ["g": C(0xD8A838), "W": C(0xEEEAE0), "d": C(0xB8B0A4)]),
    ([".sssssssssssss.", "sKKKKKKKKKKKKKs", "sKK..KKsKK..KKs", "sKK..KKsKK..KKs", ".sKKKKs.sKKKKs.", "..ssss...ssss.."],
     ["s": C(0xC8CCD8), "K": C(0x18141E)]),
    (["..y.........y..", ".vVVVVVVVVVVVv.", "vVV..VVyVV..VVv", "vVV..VyVyV..VVv", ".vVVVVv.vVVVVv.", "..vvvv...vvvv.."],
     ["v": C(0x5A2A7A), "V": C(0x8A4AB0), "y": C(0xF0C850)]),
]

extension Scenes {
    /// Where things stand in the ballroom, shared by the still picture and the moving layer: the pilasters, the
    /// chandeliers (each one's top left), the back doorway's box, and (on the screen saver) the cornice the high
    /// windows sit on.
    static func crawlCastleFrame(_ c: PixelCanvas, _ g: Int) -> (pilasters: [Int], chandeliers: [(x: Int, y: Int)],
                                                                 door: (x: Int, y: Int, w: Int, h: Int), cornice: Int,
                                                                     ceiling: Int) {
        let s = unit(g), tall = isTall(c)
        let door = (x: c.w / 2 - 22 * s, y: g - 42 * s, w: 44 * s, h: 42 * s)
        let chands = [18, 82].map { (x: c.w * $0 / 100 - 19 * s, y: g - 62 * s) }
        return ([c.w * 3 / 100, c.w * 33 / 100, c.w * 67 / 100, c.w * 97 / 100], chands, door, tall ? g - 70 * s : -1,
                tall ? max(0, g - 220 * s) : 0)
    }

    /// The High Elf castle ballroom, set for the Butcher's Masquerade: crimson damask walls between pale rose marble
    /// pilasters with gold capitals; masks hung on the walls (gold with feathers, white Venetian, black and silver,
    /// violet and gold); two gold chandeliers hanging on their chains; in the middle a tall arched doorway framed in
    /// marble, crimson drapes tied back either side and a gold mask over the keystone, opening onto the far hall,
    /// warm and gold, where a masked couple waltzes. A dark wainscot with a gilt rail runs along a floor of dark
    /// marble squares. On the screen saver the walls rise above a gilt cornice to high arched windows full of the
    /// moonlit night, and a coffered gold ceiling.
    static func crawlCastle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlCastleFrame(c, g)
        let gold = C(0xD8A838), goldD = C(0x9A7020), goldL = C(0xF4D470)
        let wain = g - 10 * s

        // The damask: crimson, a small lily motif in staggered rows.
        c.rect(0, 0, c.w, wain, C(0x561A26))
        for (row, y) in stride(from: wain - 8 * s, to: -8 * s, by: -12 * s).enumerated() {
            let shift = row % 2 == 0 ? 0 : 7 * s
            for x in stride(from: shift, to: c.w, by: 14 * s) {
                c.rect(x, y - 2 * s, s, 4 * s, C(0x6A2230)); c.rect(x - s, y - s, 3 * s, s, C(0x6A2230))
                c.rect(x - 2 * s, y + s, s, s, C(0x6A2230)); c.rect(x + 2 * s, y + s, s, s, C(0x6A2230))
            }
        }

        // On the screen saver: the high windows over a gilt cornice, and the ceiling.
        if tall { crawlCastleHigh(c, g, f.cornice, f.ceiling, f.pilasters) }

        // The pilasters: rose marble, lit on the left, faint veins, gold capitals near the top of the strip (on the
        // screen saver they run on up to the cornice).
        let capY = tall ? f.cornice : g - 60 * s
        for x in f.pilasters {
            c.rect(x - 5 * s, capY, 10 * s, wain - capY, C(0x8A7674))
            c.rect(x - 5 * s, capY, 2 * s, wain - capY, C(0xA89290))
            c.rect(x + 3 * s, capY, 2 * s, wain - capY, C(0x6A5658))
            for k in 0..<((wain - capY) / (12 * s)) {
                let y = capY + 8 * s + k * 12 * s, v = Int(noise(k + x) * 3) - 1
                for i in 0..<4 { c.rect(x + (v - 2 + i) * s, y + i * 2 * s, s, 2 * s, C(0x76625E)) }
            }
            c.rect(x - 7 * s, capY, 14 * s, 4 * s, gold); c.rect(x - 7 * s, capY, 14 * s, s, goldL)
            c.rect(x - 7 * s, capY + 3 * s, 14 * s, s, goldD)
            c.rect(x - 6 * s, capY + 4 * s, 12 * s, s, goldD)
            if !tall { c.rect(x - 5 * s, 0, 10 * s, capY, C(0x7A6866)); c.rect(x - 5 * s, 0, 2 * s, capY, C(0x98827E)) }
        }

        // The masks on the walls, two in each outer bay.
        let spots = [(c.w * 12 / 100, 0), (c.w * 24 / 100, 1), (c.w * 76 / 100, 3), (c.w * 88 / 100, 2)]
        for (k, spot) in spots.enumerated() {
            let pic = crawlCastleMasks[spot.1], w = (pic.0.first?.count ?? 0) * 2 * s
            let y = g - (k % 2 == 0 ? 40 : 44) * s
            c.rect(spot.0, y - 4 * s, s, 4 * s, C(0x2A0C12))
            crawlPic(c, spot.0 - w / 2, y, pic.0, pic.1, cell: 2 * s)
            // The ribbons trailing from the sides.
            c.rect(spot.0 - w / 2, y + 6 * s, s, 8 * s, C(0xD8A838))
            c.rect(spot.0 + w / 2 - s, y + 6 * s, s, 8 * s, C(0xD8A838))
        }

        // The doorway: the far hall first (warm gold, a far chandelier's glow, a far floor), then the marble frame and
        // its arch, the drapes and the mask over the keystone.
        let d = f.door, r = d.w / 2, cy = d.y + r
        for y in d.y..<g {
            for x in d.x..<(d.x + d.w) {
                let dx = Double(x - d.x - r) + 0.5, dy = Double(y - cy) + 0.5
                if y < cy && (dx * dx + dy * dy).squareRoot() > Double(r) { continue }
                let k = Double(y - d.y) / Double(g - d.y)
                let checker = (x / (6 * s) + y / (3 * s)) % 2 == 0
                let col: Px = k > 0.78 ? (checker ? C(0x6A4A2A) : C(0x5A3C22)) : lerp(C(0x8A6030), C(0xB88A48), k)
                c.rect(x, y, 1, 1, col)
            }
        }
        c.ellipse(d.x + r, d.y + 14 * s, 10 * s, 6 * s, C(0xFFE0A0, 0.25))
        c.rect(d.x + r - 4 * s, d.y + 12 * s, 9 * s, 2 * s, C(0xF4D470))
        c.rect(d.x + r, d.y + 4 * s, s, 8 * s, C(0x6A4A20))
        for x in stride(from: d.x + 4 * s, to: d.x + d.w - 2 * s, by: 8 * s) { c.rect(x, d.y + 30 * s, 2 * s, 6 * s,
            C(0x7A5630)) }
        crawlCastleArch(c, g, d)
        for side in [-1, 1] {
            let x = side < 0 ? d.x - 13 * s : d.x + d.w + 3 * s
            c.rect(x, d.y - 8 * s, 10 * s, g - d.y + 8 * s, C(0x8A1A2A))
            c.rect(x + (side < 0 ? 0 : 7 * s), d.y - 8 * s, 3 * s, g - d.y + 8 * s, C(0x6A1220))
            for k in 0..<3 { c.rect(x + (2 + k * 3) * s, d.y - 8 * s, s, g - d.y + 8 * s, C(0xA8283A)) }
            c.rect(x - s, g - 24 * s, 12 * s, 3 * s, gold); c.rect(x - s, g - 24 * s, 12 * s, s, goldL)
            c.rect(x + 4 * s, g - 21 * s, 2 * s, 5 * s, gold); c.rect(x + 3 * s, g - 16 * s, 4 * s, 2 * s, goldD)
        }
        let crest = crawlCastleMasks[0]
        crawlPic(c, d.x + r - 7 * s, d.y - 13 * s, crest.0, crest.1, cell: s)

        // The chandeliers on their chains.
        let pal: [Character: Px] = ["G": gold, "g": goldD, "c": C(0xC8E8F8), "w": C(0xF4ECD8), "f": C(0xFFC850)]
        for ch in f.chandeliers {
            for y in stride(from: f.ceiling, to: ch.y + 4 * s, by: 3 * s) { c.rect(ch.x + 19 * s - s, y, 2 * s, 2 * s, goldD) }
            c.ellipse(ch.x + 19 * s, ch.y + 6 * s, 26 * s, 12 * s, C(0xFFD890, 0.06))
            crawlPic(c, ch.x, ch.y, crawlCastleChandelier, pal, cell: 2 * s)
        }

        // The wainscot: dark wine-black, panelled, a gilt rail on top.
        c.rect(0, wain, c.w, g - wain, C(0x2E1418))
        for x in stride(from: 3 * s, to: c.w, by: 14 * s) { c.rect(x, wain + 3 * s, 10 * s, 5 * s, C(0x3A1A20))
            c.rect(x, wain + 3 * s, 10 * s, s, C(0x22100E)) }
        c.rect(0, wain - s, c.w, 2 * s, goldD); c.rect(0, wain - s, c.w, s, gold)

        // The floor: dark marble squares, the joints faint, the chandeliers' glow on it.
        c.ground(g, C(0x2E2830), edge: C(0x5A4C56), speck: C(0x2A242C), seed: 71)
        for (k, x) in stride(from: 0, to: c.w, by: 12 * s).enumerated() where k % 2 == 0 {
            c.rect(x, g + 1, 12 * s, (c.h - g) / 2, C(0x363038))
            c.rect(x + 12 * s, g + 1 + (c.h - g) / 2, 12 * s, c.h - g, C(0x363038))
        }
        for ch in f.chandeliers { c.ellipse(ch.x + 19 * s, g + 4 * s, 24 * s, 3 * s, C(0xFFD890, 0.05)) }
    }

    /// The doorway's marble frame: a ring of voussoirs round the arch and jambs down to the floor, lit on the left,
    /// a gold keystone at the crown.
    private static func crawlCastleArch(_ c: PixelCanvas, _ g: Int, _ d: (x: Int, y: Int, w: Int, h: Int)) {
        let s = unit(g), r = d.w / 2, ring = 4 * s, cx = d.x + r, cy = d.y + r
        for y in (d.y - ring)..<g {
            for x in (d.x - ring)..<(d.x + d.w + ring) {
                let dx = Double(x - cx) + 0.5, dy = Double(y - cy) + 0.5
                let dist = y < cy ? (dx * dx + dy * dy).squareRoot() : abs(dx)
                guard dist >= Double(r), dist < Double(r + ring) else { continue }
                let edge = dist > Double(r + ring - s)
                c.rect(x, y, 1, 1, edge ? C(0x5A4446) : dx < 0 ? C(0xB09A96) : C(0x8A7674))
            }
        }
        c.rect(cx - 3 * s, d.y - ring - s, 6 * s, ring + 3 * s, C(0xD8A838))
        c.rect(cx - 3 * s, d.y - ring - s, 6 * s, s, C(0xF4D470))
    }

    /// The screen saver's upper ballroom: a gilt cornice along the top of the walls, the pilasters running up into a
    /// coffered gold ceiling, and between them high arched windows, each a grid of leaded panes full of the night,
    /// the moonlight catching a few, deep crimson drapes swagged over the middle one.
    private static func crawlCastleHigh(_ c: PixelCanvas, _ g: Int, _ cornice: Int, _ ceil: Int, _ pilasters: [Int]) {
        let s = unit(g), gold = C(0xD8A838), goldD = C(0x9A7020), goldL = C(0xF4D470)
        // The ceiling's coffers.
        c.rect(0, 0, c.w, ceil, C(0x3A2416))
        for x in stride(from: 2 * s, to: c.w, by: 26 * s) {
            for y in stride(from: ceil - 18 * s, to: -18 * s, by: -20 * s) {
                c.rect(x, y, 22 * s, 16 * s, C(0x4A3020)); c.rect(x, y, 22 * s, s, C(0x2A180E))
                c.rect(x + 3 * s, y + 3 * s, 16 * s, 10 * s, C(0x5A3A24)); c.rect(x + 9 * s, y + 6 * s, 4 * s, 4 * s, goldD)
            }
        }
        c.rect(0, ceil, c.w, 4 * s, gold); c.rect(0, ceil, c.w, s, goldL); c.rect(0, ceil + 4 * s, c.w, 2 * s, goldD)
        // The windows, one in each bay.
        for k in 1..<pilasters.count {
            let a = pilasters[k - 1], b = pilasters[k], mid = (a + b) / 2
            let w = min(b - a - 24 * s, k == 2 ? 70 * s : 46 * s), r = w / 2
            let top = ceil + 22 * s, bottom = cornice - 16 * s, x0 = mid - r
            guard bottom - top > r + 10 * s else { continue }
            let cy = top + r
            for y in (top - 3 * s)..<(bottom + 3 * s) {
                for x in (x0 - 3 * s)..<(x0 + w + 3 * s) {
                    let dx = Double(x - mid) + 0.5, dy = Double(y - cy) + 0.5
                    let dist = y < cy ? (dx * dx + dy * dy).squareRoot() : abs(dx)
                    if y >= bottom || dist >= Double(r) {
                        if y < bottom + 3 * s && (y >= bottom || dist < Double(r + 3 * s)) { c.rect(x, y, 1, 1,
                            dx < 0 ? C(0xA89290) : C(0x7A6866)) }
                        continue
                    }
                    let lead = (x - x0) % (8 * s) < s || (y - top) % (10 * s) < s
                    let glint = noise((x - x0) / (8 * s) * 31 + (y - top) / (10 * s) * 7 + k) > 0.93
                    c.rect(x, y, 1, 1, lead ? C(0x14141E) : glint ? C(0x6A8AC8) : lerp(C(0x101A3A), C(0x24346A),
                        Double(y - top) / Double(bottom - top)))
                }
            }
            c.rect(x0 - 4 * s, bottom + 3 * s, w + 8 * s, 3 * s, C(0x8A7674))
            c.rect(x0 - 4 * s, bottom + 3 * s, w + 8 * s, s, C(0xA89290))
            if k == 2 {
                // The drapes swagged over the middle window, gold tassels at the ends.
                for i in 0..<(w + 20 * s) {
                    let u = Double(i) / Double(w + 20 * s), sag = Int(sin(u * .pi) * Double(10 * s))
                    c.rect(x0 - 10 * s + i, top - 8 * s, 1, 6 * s + sag, C(0x8A1A2A))
                    c.rect(x0 - 10 * s + i, top - 2 * s + sag, 1, s, C(0x6A1220))
                }
                for tx in [x0 - 10 * s, x0 + w + 8 * s] {
                    c.rect(tx, top - 8 * s, 4 * s, 30 * s, C(0x8A1A2A)); c.rect(tx, top + 22 * s, 4 * s, 4 * s, gold)
                }
            }
        }
        // The cornice.
        c.rect(0, cornice - 6 * s, c.w, 6 * s, gold); c.rect(0, cornice - 6 * s, c.w, s, goldL)
        c.rect(0, cornice - s, c.w, s, goldD)
        for x in stride(from: 2 * s, to: c.w, by: 6 * s) { c.rect(x, cornice - 4 * s, 3 * s, 2 * s, goldD) }
        // The pilasters' upper run.
        for x in pilasters {
            c.rect(x - 5 * s, ceil + 6 * s, 10 * s, cornice - 6 * s - ceil - 6 * s, C(0x7A6866))
            c.rect(x - 5 * s, ceil + 6 * s, 2 * s, cornice - 6 * s - ceil - 6 * s, C(0x98827E))
            c.rect(x - 7 * s, ceil + 6 * s, 14 * s, 4 * s, gold); c.rect(x - 7 * s, ceil + 9 * s, 14 * s, s, goldD)
        }
    }

    /// The ballroom's life: the chandeliers' crystals glinting one after another, the candle flames flickering, and in
    /// the far hall a masked couple waltzing, turning as they drift from side to side (her pale gold gown swinging,
    /// his dark coat).
    static func crawlCastleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlCastleFrame(c, g)
        // The couple, in the doorway's far hall.
        let d = f.door, sway = sin(t * 0.6), turn = Int(t * 2.2) % 4
        let cx = d.x + d.w / 2 + Int(sway * Double(10 * s)), fy = g - 14 * s
        let gown = C(0xE0C878), gownD = C(0xB89A50), coat = C(0x24203A), coatL = C(0x3A3458), skin = C(0xE8C0A0)
        let order = turn < 2 ? [0, 1] : [1, 0]
        for who in order {
            let side = (turn % 2 == 0 ? 1 : -1) * (who == 0 ? -1 : 1)
            let x = cx + side * 3 * s
            if who == 0 {
                // Her: a bell of a gown, a bodice, her hair up, a white mask.
                let flare = turn % 2 == 0 ? s : 0
                c.rect(x - 4 * s - flare, fy - 6 * s, 8 * s + 2 * flare, 6 * s, gown)
                c.rect(x - 4 * s - flare, fy - s, 8 * s + 2 * flare, s, gownD)
                c.rect(x - 2 * s, fy - 10 * s, 4 * s, 4 * s, gown); c.rect(x - s, fy - 13 * s, 3 * s, 3 * s, skin)
                c.rect(x - s, fy - 12 * s, 3 * s, s, C(0xFFFFFF)); c.rect(x - s, fy - 15 * s, 3 * s, 2 * s, C(0x5A3020))
            } else {
                // Him: dark tails, pale shirt front, a black mask.
                c.rect(x - 2 * s, fy - 5 * s, s, 5 * s, coat); c.rect(x + s, fy - 5 * s, s, 5 * s, coat)
                c.rect(x - 2 * s, fy - 11 * s, 4 * s, 6 * s, coat); c.rect(x - 2 * s, fy - 11 * s, s, 6 * s, coatL)
                c.rect(x - s, fy - 10 * s, s, 3 * s, C(0xE8E4DC))
                c.rect(x - s, fy - 14 * s, 3 * s, 3 * s, skin); c.rect(x - s, fy - 13 * s, 3 * s, s, C(0x1A1420))
                c.rect(x - s, fy - 15 * s, 3 * s, s, C(0x2A1A14))
            }
        }
        // The candles and the crystals.
        for (k, ch) in f.chandeliers.enumerated() {
            for i in 0..<5 where Int(t * 8 + Double(i * 3 + k)) % 5 == 0 {
                c.rect(ch.x + (6 + i * 6) * s, ch.y - s, 2 * s, s, C(0xFFE8A0))
            }
            let spots = [(4, 7), (31, 7), (16, 11), (20, 11), (18, 13), (18, 15)]
            let j = Int(t * 3 + Double(k * 2)) % (spots.count + 2)
            if j < spots.count {
                let p = (x: ch.x + spots[j].0 * s, y: ch.y + spots[j].1 * s)
                c.rect(p.x, p.y - s, s, 3 * s, C(0xFFFFFF)); c.rect(p.x - s, p.y, 3 * s, s, C(0xFFFFFF))
                c.rect(p.x - 2 * s, p.y, s, s, C(0xFFFFFF, 0.4)); c.rect(p.x + 2 * s, p.y, s, s, C(0xFFFFFF, 0.4))
            }
        }
    }
}

// MARK: - The Hunting Grounds

extension Scenes {
    /// Where things stand in the Hunting Grounds, shared by the still picture and the moving layer: the giant trunks
    /// (centre and width), the stirring fern clumps (centre and height), the raptor's clump, and (on the screen
    /// saver) the volcano's peak and the canopy's lower edge.
    static func crawlHuntingFrame(_ c: PixelCanvas, _ g: Int) -> (trunks: [(x: Int, w: Int)], ferns: [(x: Int, h: Int)],
                                                                  raptor: Int, volcano: (x: Int, y: Int), canopy: Int) {
        let s = unit(g), tall = isTall(c)
        let trunks = [(x: c.w * 13 / 100, w: 30 * s), (x: c.w * 76 / 100, w: 38 * s)]
        let raptor = c.w * 58 / 100
        let ferns = [(x: c.w * 3 / 100, h: 20 * s), (x: raptor, h: 18 * s), (x: c.w * 96 / 100, h: 22 * s),
            (x: c.w * 36 / 100, h: 10 * s)]
        return (trunks, ferns, raptor, (x: c.w * 46 / 100, y: g - 150 * s), tall ? g - 200 * s : g - 58 * s)
    }

    /// The Hunting Grounds: the Ninth Floor's prehistoric forest, damp and green. Behind, a misty wood of pale trunks
    /// fading into the haze; in front, two giant trees, their trunks wider than a crawler is tall, bark in long strokes,
    /// moss on their lit side and buttress roots splaying into the mud; vines hang from the canopy along the top. Big
    /// fern clumps crowd the sides, and in the middle of the muddy ground a huge three-toed dinosaur footprint sits
    /// pressed into the mud. On the screen saver the trees climb into the canopy, and through a gap a smoking volcano
    /// stands far off in the haze.
    static func crawlHunting(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlHuntingFrame(c, g)

        // The haze behind it all: on the screen saver a pale amber sky with the volcano in it, else the misty wood.
        if tall {
            c.gradient(0, g, C(0x9AA88A), C(0x5E7A64), bands: 8)
            crawlHuntingVolcano(c, g, f.volcano)
            c.dunes(base: g - 70 * s, amp: Double(8 * s), freq: 0.05 / Double(s), phase: 0.4, bottom: g, C(0x587866))
        } else {
            c.gradient(0, g, C(0x6A8A72), C(0x3E5A48), bands: 5)
        }
        // The misty wood: pale far trunks, then darker nearer ones, a band of mist low down.
        let woodTop = tall ? g - 76 * s : 0
        for (layer, col) in [C(0x6E8C78), C(0x4E6C58)].enumerated() {
            for k in 0..<12 {
                let x = c.w * (k * 9 + layer * 4) / 100 + Int(noise(k * 7 + layer * 50) * Double(6 * s))
                let w = (layer == 0 ? 4 : 7) * s + Int(noise(k + layer * 9) * Double(3 * s))
                c.rect(x, woodTop, w, g - woodTop, col); c.rect(x, woodTop, s, g - woodTop, lerp(col, C(0xC8D8C0), 0.2))
            }
            c.rect(0, g - (22 - layer * 10) * s, c.w, 6 * s, C(0xC8DCC8, 0.10))
        }
        c.rect(0, g - 14 * s, c.w, 14 * s, C(0xB8D0B8, 0.08))

        // The giant trees.
        for (k, tr) in f.trunks.enumerated() { crawlHuntingTrunk(c, g, tr.x, tr.w, seed: k, top: tall ? f.canopy : 0) }

        // The canopy along the top: dark leaf masses, lit clumps, vines hanging down.
        crawlHuntingCanopy(c, g, f.canopy)

        // The big fern clumps at the sides (the middle ones stir in the moving layer).
        for fern in [f.ferns[0], f.ferns[2]] { crawlHuntingFern(c, g, fern.x, fern.h, sway: 0, seed: fern.x) }

        // The ground: dark mud, plain, with the footprint pressed into it: three long toes splayed forward from a
        // round heel, each with a claw mark, the rim lit along the far edge.
        c.ground(g, C(0x3A3022), edge: C(0x56482E), speck: C(0x30281C), seed: 79)
        let fx = c.w * 22 / 100, fy = g + 5 * s
        let heel = (x: Double(fx), y: Double(fy))
        for (pass, col) in [C(0x6A5A3A), C(0x1E160E)].enumerated() {
            let lift = pass == 0 ? -Double(s) : 0
            c.ellipse(fx, fy + Int(lift), 5 * s, 2 * s, col)
            for a in [-28.0, 0, 28] {
                let tip = crawlReach(heel, a, Double(15 * s))
                let end = (x: tip.x, y: heel.y + (tip.y - heel.y) * 0.45 + lift)
                c.glowLine(heel.x, heel.y + lift, end.x, end.y, core: col, glow: C(0, 0), coreR: 1.3 * Double(s),
                    glowR: 1.4 * Double(s))
                if pass == 1 { c.rect(Int(end.x) + s, Int(end.y), 2 * s, s, C(0x141008)) }
            }
        }
    }

    /// One giant trunk centred on `x`, `w` wide, from `top` down to the ground: brown bark lit on the left in long
    /// strokes, moss on the lit side, a knot hole, and buttress roots splaying out into the mud.
    private static func crawlHuntingTrunk(_ c: PixelCanvas, _ g: Int, _ x: Int, _ w: Int, seed: Int, top: Int) {
        let s = unit(g), x0 = x - w / 2
        let bark = C(0x5A4430), barkD = C(0x3E2E20), barkL = C(0x7A5E40), moss = C(0x4E7A34), mossL = C(0x6A9A44)
        // The buttress roots first, flaring wide at the foot.
        for (side, reach) in [(-1, 16), (1, 18), (-1, 8), (1, 7)] {
            for i in 0..<(reach * s) {
                let h = (reach * s - i) * 18 / reach
                let rx = side < 0 ? x0 - i : x0 + w + i
                c.rect(rx, g - h, 1, h, side < 0 ? bark : barkD)
                if side < 0 { c.rect(rx, g - h, 1, s, barkL) }
            }
        }
        c.rect(x0, top, w, g - top, bark)
        c.rect(x0, top, 3 * s, g - top, barkL); c.rect(x0 + w - 4 * s, top, 4 * s, g - top, barkD)
        // The bark's long strokes, broken here and there.
        for k in 0..<(w / (4 * s)) {
            let bx = x0 + 4 * s + k * 4 * s
            var y = top + Int(noise(k * 13 + seed * 7) * Double(10 * s))
            while y < g {
                let len = (10 + Int(noise(y + k * 5 + seed) * 20)) * s
                c.rect(bx, y, s, min(len, g - y), barkD)
                y += len + 4 * s
            }
        }
        // Moss on the lit side, in drooping strokes.
        for k in 0..<((g - top) / (14 * s)) {
            let y = g - 30 * s - k * 14 * s
            guard y > top else { break }
            let len = (4 + Int(noise(k + seed * 31) * 6)) * s
            c.rect(x0, y, 5 * s, 2 * s, moss); c.rect(x0, y, 4 * s, s, mossL)
            c.rect(x0 + s, y + 2 * s, s, len, moss); c.rect(x0 + 3 * s, y + 2 * s, s, len / 2, moss)
        }
        // A knot hole.
        let ky = g - 40 * s + seed * 8 * s
        c.ellipse(x + w / 6, ky, 4 * s, 5 * s, barkD); c.ellipse(x + w / 6, ky + s, 3 * s, 4 * s, C(0x1A140C))
    }

    /// The canopy's lower edge at `edge`: dark leaf masses above it with a lumpy bottom, lit clumps, and vines
    /// hanging down from it with a leaf or two.
    private static func crawlHuntingCanopy(_ c: PixelCanvas, _ g: Int, _ edge: Int) {
        let s = unit(g)
        for x in stride(from: 0, to: c.w, by: s) {
            let lump = Int((sin(Double(x) / Double(9 * s)) * 0.6 + sin(Double(x) / Double(4 * s) + 1.7) * 0.4) * Double(3 * s))
            c.rect(x, 0, s, max(0, edge + lump), C(0x1E3A24))
        }
        for (row, base) in stride(from: edge - 2 * s, to: -10 * s, by: -12 * s).enumerated() {
            for k in 0..<(c.w / (10 * s) + 1) {
                let x = k * 10 * s + (row % 2) * 5 * s + Int(noise(k + row * 40 + 600) * Double(6 * s))
                let y = base - Int(noise(k + row * 40 + 610) * Double(row == 0 ? 14 * s : 8 * s))
                let lit = row == 0 ? C(0x3E6A36) : C(0x2E5230)
                c.ellipse(x, y, 7 * s, 4 * s, row == 0 ? C(0x2C4E2C) : C(0x24442A))
                c.ellipse(x - s, y - s, 4 * s, 2 * s, lit)
            }
        }
        for k in 0..<9 {
            let x = c.w * (4 + k * 11) / 100 + Int(noise(k + 620) * Double(5 * s)), len = (8 + Int(noise(k + 630) * 22)) * s
            for i in stride(from: 0, to: len, by: s) {
                let wob = Int(sin(Double(i) / Double(5 * s) + Double(k)) * Double(s))
                c.rect(x + wob, edge + i, s, s, C(0x2E5A2A))
            }
            c.rect(x - s, edge + len, 3 * s, 2 * s, C(0x4E8A3A))
        }
    }

    /// A fern clump standing on the ground at `x`, `h` tall: fronds arching out each way, leaflets along them, lit on
    /// the upper side; `sway` (-1...1) leans the tips.
    static func crawlHuntingFern(_ c: PixelCanvas, _ g: Int, _ x: Int, _ h: Int, sway: Double, seed: Int) {
        let s = unit(g)
        for (k, a) in [-150.0, -125.0, -100.0, -80.0, -55.0, -30.0, -170.0, -10.0].enumerated() {
            let len = Double(h) * (k < 6 ? 1.0 : 0.7) * (0.85 + noise(k + seed) * 0.3)
            var prev = (x: Double(x), y: Double(g))
            for i in 1...10 {
                let u = Double(i) / 10, bend = a + (a < -90 ? -1 : 1) * u * u * 60 + sway * u * 12
                let p = crawlReach(prev, bend, len / 10)
                c.glowLine(prev.x, prev.y, p.x, p.y, core: C(0x2E5A2A), glow: C(0, 0), coreR: 0.6 * Double(s),
                    glowR: 0.7 * Double(s))
                if i > 1 && i < 10 {
                    let leaf = Double(4 * s) * (1 - u * 0.6)
                    let l1 = crawlReach(p, bend - 70, leaf), l2 = crawlReach(p, bend + 70, leaf)
                    c.glowLine(p.x, p.y, l1.x, l1.y, core: C(0x5AA048), glow: C(0, 0), coreR: 0.5 * Double(s),
                        glowR: 0.6 * Double(s))
                    c.glowLine(p.x, p.y, l2.x, l2.y, core: C(0x3A7A36), glow: C(0, 0), coreR: 0.5 * Double(s),
                        glowR: 0.6 * Double(s))
                }
                prev = p
            }
        }
    }

    /// The volcano far off in the haze: a dusky cone with a glowing crater and a lava run down its side, its plume of
    /// smoke billowing up and leaning away.
    private static func crawlHuntingVolcano(_ c: PixelCanvas, _ g: Int, _ peak: (x: Int, y: Int)) {
        let s = unit(g), base = g - 60 * s, half = 90 * s
        for x in (peak.x - half)..<(peak.x + half) {
            let k = Double(abs(x - peak.x)) / Double(half)
            let top = peak.y + Int(pow(k, 0.8) * Double(base - peak.y)) + (abs(x - peak.x) < 8 * s ? 2 * s : 0)
            c.rect(x, top, 1, base - top, x < peak.x ? C(0x6A6070) : C(0x58505E))
        }
        c.rect(peak.x - 8 * s, peak.y, 16 * s, 2 * s, C(0xF07030))
        c.rect(peak.x - 5 * s, peak.y + 2 * s, 10 * s, s, C(0xC04820))
        for i in 0..<24 { c.rect(peak.x + 3 * s + i * s / 2, peak.y + 2 * s + i * s, s, s, C(0xE06030, 0.8)) }
        for k in 0..<7 {
            let r = (8 + k * 3) * s, y = peak.y - 8 * s - k * 13 * s, x = peak.x + k * k * s
            c.circle(x, y, r, C(0x8A8480, 0.55)); c.circle(x - r / 4, y - r / 4, r * 2 / 3, C(0xA8A29C, 0.45))
        }
    }

    /// The Hunting Grounds' life: the middle ferns stirring in the damp air, and now and then a raptor's head rising
    /// out of the clump in the middle (olive with dark stripes, a red crest, a yellow eye, teeth showing), looking
    /// round and sinking back; on the screen saver the volcano's smoke drifting up.
    static func crawlHuntingLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlHuntingFrame(c, g)
        // The raptor, behind its clump: rises, looks round, sinks again, every eight seconds.
        let u = t.truncatingRemainder(dividingBy: 8)
        let up = u < 0.5 ? 0 : u < 1 ? (u - 0.5) * 2 : u < 3.5 ? 1 : u < 4 ? (4 - u) * 2 : 0
        if up > 0 {
            let hx = f.raptor - 2 * s, hy = g - 30 * s + Int((1 - up) * Double(22 * s))
            let look = u > 2.2 && u < 3.2
            let head = [".....rrr.......", "...rrOOOOOO....", "..OOOOOOOOOOO..", "OOOeKOOOOOOOOO.", "OOOOOOODOODOOO.",
                        "OwwwwwOOOOOOOO.", ".OOOOOOOOOOOO..", "......OODOOO...", "......OOOOOO...", "......ODOOOD...",
                        "......OOOOOO...", ".......OODOO...", ".......OOOOO...", ".......ODOOD...", ".......OOOOO...",
                        ".......OOOOO..."]
            crawlPic(c, hx - 4 * s, hy, head, ["O": C(0x6A7A3A), "D": C(0x3A4A22), "e": C(0xF0C838), "K": C(0x101008),
                                                "w": C(0xF0ECE0), "r": C(0xB8402A)], cell: s, flip: look)
        }
        // The stirring ferns, the raptor's clump drawn over its neck.
        for (k, fern) in [f.ferns[1], f.ferns[3]].enumerated() {
            crawlHuntingFern(c, g, fern.x, fern.h, sway: sin(t * 1.3 + Double(k * 2)), seed: fern.x)
        }
        // The smoke, drifting up off the plume on the screen saver.
        guard isTall(c) else { return }
        for k in 0..<4 {
            let v = (t * 0.08 + Double(k) * 0.25).truncatingRemainder(dividingBy: 1)
            let x = f.volcano.x + Int(v * v * Double(20 * s)), y = f.volcano.y - 12 * s - Int(v * Double(30 * s))
            c.circle(x, y, (6 + Int(v * 10)) * s, C(0x9A948E, 0.35 * (1 - v)))
        }
    }
}
