import Foundation

// Places, a few to a file (see CrawlScenes1.swift for the rules): the Death Watch stage, Havana on the Eighth Floor,
// Larracos in the Faction Wars, Emberus's High Temple.

let crawlScenes6: [Location: Place] = [
    .crawlDeathWatch: Place(name: "The Death Watch stage", panel: 0x200A0E, still: Scenes.crawlDeathWatch,
                            moving: Scenes.crawlDeathWatchLife),
    .crawlHavana: Place(name: "Havana, Eighth Floor", panel: 0x1A1C22, still: Scenes.crawlHavana, moving: Scenes.crawlHavanaLife),
    .crawlLarracos: Place(name: "Larracos, Faction Wars", panel: 0x1A1812, still: Scenes.crawlLarracos,
                          moving: Scenes.crawlLarracosLife),
    .crawlTemple: Place(name: "Emberus's High Temple", panel: 0x1E1614, still: Scenes.crawlTemple, moving: Scenes.crawlTempleLife),
]

/// Little pixel pictures drawn from rows of letters, each letter a square `cell` pixels wide (a place's unit, or two).
private func crawlGrid6(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rows: [String], _ palette: [Character: Px], cell: Int) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() {
            if let col = palette[ch] { c.rect(x + k * cell, y + r * cell, cell, cell, col) }
        }
    }
}

/// A box drawn larger than its units say: `dx`, `dy` (rows up from `oy`), `w` and `h` in units, each scaled by
/// `num / den` place pixels and placed by its edges so neighbouring boxes never leave a gap. The temple's fountain
/// and stump use it to stand bigger than their drawings.
private func crawlBig(_ c: PixelCanvas, _ ox: Int, _ oy: Int, _ dx: Int, _ dy: Int, _ w: Int, _ h: Int, _ num: Int, _ den: Int, _ col: Px) {
    let x0 = ox + dx * num / den, x1 = ox + (dx + w) * num / den
    let y0 = oy - dy * num / den, y1 = oy - (dy - h) * num / den
    c.rect(x0, y0, x1 - x0, y1 - y0, col)
}

// MARK: - The Death Watch stage

/// The orc skull over the Death Watch set's arch, front on: a broad bone dome, deep sockets with a red glow in each,
/// a gap of a nose, a row of teeth and two tusks curling up from the jaw.
private let crawlOrcSkull = [
    ".....bbbbbbb.....",
    "...bbbbbbbbbbb...",
    "..bbbbbbbbbbbbb..",
    ".bbbbbbbbbbbbbbs.",
    ".bbbbbbbbbbbbbss.",
    "bbbkkkbbbbbkkkbss",
    "bbkkkkkbbbkkkkkbs",
    "bbkkrkkbbbkkrkkbs",
    ".bbkkkbbbbbkkkbs.",
    "..bbbbbbkbbbbbs..",
    "..bbbbbkkkbbbss..",
    "w..bbbbbbbbbbs..w",
    "ww.bkbkbkbkbks.ww",
    ".wwbbbbbbbbbbsww.",
    "..wwbbbbbbbbsww..",
]

/// A little skull carved into the arch's bone blocks.
private let crawlArchSkull = [
    ".bbb.",
    "bkbkb",
    "bbbbb",
    ".bkb.",
]

private struct CrawlDeathWatchFrame {
    var sign: (x: Int, y: Int, w: Int, h: Int)
    var bulbs: [(Int, Int)]
    var lamps: [(x: Int, y: Int)]
    var wheel: (x: Int, y: Int, r: Int)
    var cage: (x: Int, w: Int, top: Int)
    /// The skull arch (screen saver only): where it springs, its half width and height, its thickness.
    var arch: (spring: Int, rx: Int, ry: Int, t: Int)
}

extension Scenes {
    /// Where things stand on the Death Watch set, shared by the still picture and the moving layer: the marquee and
    /// the bulbs round it, the two spotlights, the prize wheel, the cage, and (on the screen saver) the skull arch.
    private static func crawlDeathWatchFrame(_ c: PixelCanvas, _ g: Int) -> CrawlDeathWatchFrame {
        let s = unit(g)
        let w = crawlTextWidth("DEATH WATCH", scale: 2 * s) + 14 * s, h = 18 * s
        let sign = (x: c.w / 2 - w / 2, y: g - 60 * s, w: w, h: h)
        var bulbs: [(Int, Int)] = []
        for x in stride(from: sign.x + 2 * s, to: sign.x + w - s, by: 4 * s) { bulbs.append((x, sign.y + s)) }
        for y in stride(from: sign.y + 5 * s, to: sign.y + h - 4 * s, by: 4 * s) { bulbs.append((sign.x + w - 2 * s, y)) }
        for x in stride(from: sign.x + w - 2 * s, to: sign.x + s, by: -4 * s) { bulbs.append((x, sign.y + h - 2 * s)) }
        for y in stride(from: sign.y + h - 6 * s, to: sign.y + 4 * s, by: -4 * s) { bulbs.append((sign.x + s, y)) }
        let lamps = [(x: sign.x - 16 * s, y: g - 60 * s), (x: sign.x + w + 16 * s, y: g - 60 * s)]
        let wheel = (x: c.w * 80 / 100, y: g - 31 * s, r: 22 * s)
        let cage = (x: c.w * 9 / 100, w: 28 * s, top: g - 40 * s)
        var arch = (spring: -1, rx: 0, ry: 0, t: 14 * s)
        if isTall(c) {
            let spring = g - 72 * s, rx = c.w * 44 / 100
            arch = (spring, rx, min(rx, spring - 40 * s), 14 * s)
        }
        return CrawlDeathWatchFrame(sign: sign, bulbs: bulbs, lamps: lamps, wheel: wheel, cage: cage, arch: arch)
    }

    /// The Death Watch stage: Maestro's orc game show, loud where Odette's studio is calm. A crimson sunburst
    /// behind it all, red velvet curtains with gold tiebacks at the sides, a gold truss along the top with a
    /// spotlight either side of the marquee (DEATH WATCH in gold on black, ringed with bulbs); on the left a tall
    /// iron cage on a red and gold plinth, hung on a chain; on the right a big prize wheel in red, gold, black and
    /// cream on a gold stand, a little skull at its hub; Maestro's red podium with its skull badge and a microphone.
    /// The floor is a dark crimson stage with a gold edge. On the screen saver the whole set stands under an arch of
    /// bone blocks with little skulls carved in them, a huge tusked orc skull (in triple units) for its keystone,
    /// red eyes glowing, and dark red drapes all round it.
    static func crawlDeathWatch(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = crawlDeathWatchFrame(c, g)
        let gold = C(0xE0A830), goldD = C(0x9A6A18), goldL = C(0xFFD860)
        let red = C(0xB01820), redD = C(0x6A0C12), redL = C(0xE03838)

        // The sunburst: crimson rays fanning out from the middle of the set.
        let cx = c.w / 2, cy = g - 26 * s, ray = Double.pi / 14
        for y in stride(from: 0, to: g, by: s) {
            for x in stride(from: 0, to: c.w, by: s) {
                let a = atan2(Double(y - cy), Double(x - cx)) + Double.pi
                c.rect(x, y, s, s, Int(a / ray) % 2 == 0 ? C(0x641018) : C(0x4E0A12))
            }
        }
        // A glow behind the marquee, where the rays meet.
        c.ellipse(cx, cy, 60 * s, 30 * s, C(0xFF7040, 0.08))

        // On the screen saver: the skull arch over the set, dark drapes all round it.
        if f.arch.spring > 0 { crawlDeathWatchArch(c, g, f) }

        // The base along the floor: dark red panels, a gold rail along its top.
        c.rect(0, g - 12 * s, c.w, 12 * s, C(0x3A080E))
        for x in stride(from: 3 * s, to: c.w, by: 16 * s) { c.rect(x, g - 9 * s, 12 * s, 7 * s, C(0x4A0C14)); c.rect(x, g - 9 * s, 12 * s, s, C(0x2A0408)) }
        c.rect(0, g - 13 * s, c.w, 2 * s, goldD); c.rect(0, g - 13 * s, c.w, s, gold)

        // The curtains at the sides: red velvet in folds, a gold tieback pulling each in at the waist, a fringe.
        for side in [0, 1] {
            let w = 14 * s, x0 = side == 0 ? 0 : c.w - w
            for k in 0..<(w / (3 * s)) {
                let x = side == 0 ? x0 + k * 3 * s : x0 + w - (k + 1) * 3 * s
                c.rect(x, 0, 3 * s, g, k % 2 == 0 ? red : redD); c.rect(x, 0, s, g, k % 2 == 0 ? redL : red)
            }
            let ty = g - 30 * s, tx = side == 0 ? x0 + w - 4 * s : x0
            c.rect(tx, ty, 4 * s, 3 * s, gold); c.rect(tx, ty, 4 * s, s, goldL)
            c.rect(tx + s, ty + 3 * s, 2 * s, 5 * s, goldD); c.rect(tx, ty + 8 * s, 4 * s, s, gold)
            c.rect(x0, g - 2 * s, w, 2 * s, goldD)
        }

        // The truss along the top: a gold lattice bar, the two spotlights hung from it.
        let ty = f.lamps[0].y - 6 * s
        c.rect(14 * s, ty, c.w - 28 * s, s, gold); c.rect(14 * s, ty + 3 * s, c.w - 28 * s, s, goldD)
        for x in stride(from: 14 * s, to: c.w - 14 * s, by: 4 * s) { c.rect(x, ty + s, s, 2 * s, goldD); c.rect(x + 2 * s, ty + s, s, s, gold) }
        for l in f.lamps {
            c.rect(l.x, ty + 4 * s, s, 2 * s, C(0x2A2228))
            c.rect(l.x - 4 * s, l.y, 9 * s, 6 * s, C(0x2A2228)); c.rect(l.x - 4 * s, l.y, 9 * s, s, C(0x4A4048))
            c.rect(l.x - 3 * s, l.y + 6 * s, 7 * s, s, C(0xFFF0C0))
        }

        // The marquee: a black board in a gold frame, DEATH WATCH in gold block letters, bulbs all round (dim here; the
        // moving layer chases them).
        let sg = f.sign
        c.rect(sg.x - s, sg.y - s, sg.w + 2 * s, sg.h + 2 * s, goldD)
        c.rect(sg.x, sg.y, sg.w, sg.h, gold); c.rect(sg.x, sg.y, sg.w, s, goldL)
        c.rect(sg.x + 3 * s, sg.y + 3 * s, sg.w - 6 * s, sg.h - 6 * s, C(0x140608))
        crawlText(c, sg.x + 7 * s, sg.y + 5 * s + s, "DEATH WATCH", goldD, scale: 2 * s)
        crawlText(c, sg.x + 7 * s, sg.y + 5 * s, "DEATH WATCH", goldL, scale: 2 * s)
        for (x, y) in f.bulbs { c.rect(x, y, s, s, C(0xB89048)) }

        crawlDeathWatchCage(c, g, f.cage, ty + 4 * s, s)

        // The prize wheel: a gold stand on a wide foot, the face, a red and white pointer at the top.
        let w = f.wheel
        c.rect(w.x - 2 * s, w.y, 4 * s, g - w.y, goldD); c.rect(w.x - 2 * s, w.y, s, g - w.y, gold)
        c.rect(w.x - 10 * s, g - 3 * s, 20 * s, 3 * s, goldD); c.rect(w.x - 10 * s, g - 3 * s, 20 * s, s, goldL)
        crawlDeathWheel(c, w.x, w.y, w.r, s)
        let py = w.y - w.r - 3 * s
        c.rect(w.x - 3 * s, py, 6 * s, 2 * s, C(0xF0E8E0)); c.rect(w.x - 2 * s, py + 2 * s, 4 * s, 2 * s, red)
        c.rect(w.x - s, py + 4 * s, 2 * s, s, red)

        // Maestro's podium: a red box with gold edges, a gold skull badge low on its front, a microphone on a stalk.
        let px = c.w * 60 / 100, pw = 18 * s, ph = 18 * s
        c.rect(px, g - ph, pw, ph, red); c.rect(px, g - ph, 2 * s, ph, redL); c.rect(px + pw - 3 * s, g - ph, 3 * s, ph, redD)
        c.rect(px - s, g - ph - 2 * s, pw + 2 * s, 2 * s, gold); c.rect(px - s, g - ph - 2 * s, pw + 2 * s, s, goldL)
        c.rect(px, g - 2 * s, pw, 2 * s, goldD)
        crawlGrid6(c, px + pw / 2 - 2 * s, g - 11 * s, crawlArchSkull, ["b": gold, "k": redD], cell: s)
        c.rect(px + pw - 6 * s, g - ph - 8 * s, s, 6 * s, C(0x3A3438)); c.rect(px + pw - 7 * s, g - ph - 10 * s, 3 * s, 3 * s, C(0x6A6470))

        // The floor: a dark crimson stage, plain under the crew, its edge gold.
        c.ground(g, C(0x2E1216), edge: C(0xB88A30), speck: C(0x240E12), seed: 83)
        c.rect(0, g + s, c.w, s, C(0x5A2A1A))
    }

    /// The prize wheel's face: sixteen wedges in red, gold, black and cream with gold spokes, inside a gold rim with
    /// studs, and a little bone skull on the hub.
    private static func crawlDeathWheel(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, _ s: Int) {
        let wedges = [C(0xC81E28), C(0xE8B030), C(0x241418), C(0xF0E4C8)]
        let inner = r - 3 * s, wedge = Double.pi * 2 / 16
        for dy in stride(from: -r, to: r + s, by: s) {
            for dx in stride(from: -r, to: r + s, by: s) {
                let d2 = dx * dx + dy * dy
                if d2 > r * r { continue }
                if d2 > inner * inner { c.rect(cx + dx, cy + dy, s, s, C(0xD8A030)); continue }
                var a = atan2(Double(dy), Double(dx)) + Double.pi
                a = a.truncatingRemainder(dividingBy: Double.pi * 2)
                let k = Int(a / wedge) % 16, frac = a / wedge - Double(Int(a / wedge))
                var col = wedges[k % 4]
                if frac < 0.14 && d2 > 16 * s * s { col = C(0xA87420) }
                c.rect(cx + dx, cy + dy, s, s, col)
            }
        }
        for k in 0..<16 {
            let a = Double(k) * wedge
            let bx = cx + Int(cos(a) * Double(r - 2 * s)), by = cy + Int(sin(a) * Double(r - 2 * s))
            c.rect(bx, by, s, s, C(0xFFE8A0))
        }
        c.circle(cx, cy, 5 * s, C(0x9A6A18)); c.circle(cx, cy, 4 * s, C(0xE0A830))
        crawlGrid6(c, cx - 2 * s - s / 2, cy - 2 * s, crawlArchSkull, ["b": C(0xF0E4C8), "k": C(0x241418)], cell: s)
    }

    /// The cage: iron bars under a domed top, gold bands at the top and the foot, dark inside, standing on a red and
    /// gold plinth and hung by a chain from the truss.
    private static func crawlDeathWatchCage(_ c: PixelCanvas, _ g: Int, _ k: (x: Int, w: Int, top: Int), _ truss: Int, _ s: Int) {
        let iron = C(0x30282C), ironL = C(0x6A5A60), gold = C(0xE0A830), goldD = C(0x9A6A18)
        let foot = g - 6 * s, half = k.w / 2, mid = k.x + half, dome = 8 * s
        // The plinth.
        c.rect(k.x - 3 * s, foot, k.w + 6 * s, 6 * s, C(0x8A1018)); c.rect(k.x - 3 * s, foot, k.w + 6 * s, s, gold)
        c.rect(k.x - 3 * s, g - s, k.w + 6 * s, s, goldD)
        // The dark inside, under the dome.
        c.rect(k.x, k.top, k.w, foot - k.top, C(0x1A0A0E, 0.55))
        c.ellipse(mid, k.top, half, dome, C(0x1A0A0E, 0.55))
        // The bars, each starting where the dome curves down to it.
        for x in stride(from: k.x, through: k.x + k.w, by: 4 * s) {
            let u = Double(x - mid) / Double(half)
            let top = k.top - Int((1 - min(1, u * u)).squareRoot() * Double(dome))
            c.rect(x, top, s, foot - top, iron); c.rect(x, top, max(1, s / 2), foot - top, ironL)
        }
        // The dome's rim and the bands.
        for x in stride(from: k.x, to: k.x + k.w + s, by: s) {
            let u = Double(x - mid) / Double(half)
            c.rect(x, k.top - Int((1 - min(1, u * u)).squareRoot() * Double(dome)), s, s, ironL)
        }
        c.rect(k.x - s, k.top, k.w + 3 * s, 2 * s, gold); c.rect(k.x - s, k.top + s, k.w + 3 * s, s, goldD)
        c.rect(k.x - s, foot - 3 * s, k.w + 3 * s, 2 * s, gold); c.rect(k.x - s, foot - 2 * s, k.w + 3 * s, s, goldD)
        // The ring on top and the chain up.
        c.rect(mid - s, k.top - dome - 3 * s, 3 * s, 3 * s, gold); c.rect(mid, k.top - dome - 2 * s, s, s, C(0x3A0A10))
        for y in stride(from: k.top - dome - 6 * s, to: truss - 3 * s, by: -3 * s) {
            c.rect(mid, y, s, 2 * s, C(0x5A5058)); c.rect(mid - s, y + s, 3 * s, s, C(0x3A3238))
        }
    }

    /// The screen saver's arch: dark drapes behind and round it, the arch's two legs from the base up to its spring,
    /// the curve of bone blocks with skulls carved along it, and the big orc skull at the top.
    private static func crawlDeathWatchArch(_ c: PixelCanvas, _ g: Int, _ f: CrawlDeathWatchFrame) {
        let s = unit(g), a = f.arch, cx = c.w / 2
        let bone = C(0xE4D8BC), boneD = C(0xC8B898), mortar = C(0x8A7A60)
        // The drapes outside the arch: dark red folds, a gold fringe along the arch's outer edge.
        for y in stride(from: 0, to: a.spring, by: s) {
            let v = Double(a.spring - y) / Double(a.ry)
            let reach = v >= 1 ? 0 : Int(Double(a.rx) * (1 - v * v).squareRoot())
            for x in stride(from: 0, to: c.w, by: s) where abs(x - cx) > reach {
                c.rect(x, y, s, s, (x / (4 * s)) % 2 == 0 ? C(0x420810) : C(0x34060C))
            }
        }
        for x in stride(from: 0, to: c.w, by: 4 * s) { c.rect(x, 0, s, a.spring, C(0x58101A)) }
        // The legs: bone blocks standing on the base, little skulls on every other block.
        let legs = [cx - a.rx, cx + a.rx - a.t]
        for lx in legs {
            for (k, y) in stride(from: g - 13 * s - 12 * s, through: a.spring - 12 * s, by: -12 * s).enumerated() {
                c.rect(lx, y, a.t, 12 * s, k % 2 == 0 ? bone : boneD); c.rect(lx, y, a.t, s, mortar)
                if k % 2 == 0 { crawlGrid6(c, lx + a.t / 2 - 2 * s - s / 2, y + 4 * s, crawlArchSkull, ["b": boneD, "k": C(0x5A4A3A)], cell: s) }
            }
            c.rect(lx, a.spring, s, g - 13 * s - a.spring, C(0xF4ECD8))
        }
        // The curve: blocks between the outer and inner edge, a mortar line every tenth of a half turn.
        let irx = a.rx - a.t, iry = a.ry - a.t, block = Double.pi / 20
        for y in stride(from: a.spring - a.ry, to: a.spring, by: s) {
            for x in stride(from: cx - a.rx, to: cx + a.rx, by: s) {
                let ox = Double(x - cx) / Double(a.rx), oy = Double(a.spring - y) / Double(a.ry)
                if ox * ox + oy * oy > 1 { continue }
                let ix = Double(x - cx) / Double(irx), iy = Double(a.spring - y) / Double(iry)
                if ix * ix + iy * iy < 1 { continue }
                let ang = atan2(oy, ox), n = Int(ang / block), frac = ang / block - Double(n)
                var col = n % 2 == 0 ? bone : boneD
                if frac < 0.1 { col = mortar }
                if ix * ix + iy * iy < 1.08 { col = C(0xF4ECD8) }
                c.rect(x, y, s, s, col)
            }
        }
        // Skulls carved along the curve, on the darker blocks, leaving the top for the big one.
        for n in stride(from: 1, to: 20, by: 2) where abs(n - 10) > 2 {
            let ang = (Double(n) + 0.5) * block
            let mx = Double(a.rx - a.t / 2), my = Double(a.ry - a.t / 2)
            let x = cx + Int(cos(ang) * mx), y = a.spring - Int(sin(ang) * my)
            crawlGrid6(c, x - 2 * s - s / 2, y - 2 * s, crawlArchSkull, ["b": C(0xB0A080), "k": C(0x5A4A3A)], cell: s)
        }
        // The keystone: the orc skull, drawn in triple units, its eyes glowing red.
        let d = 3 * s, sw = 17 * d, sh = 15 * d
        let kx = cx - sw / 2, ky = a.spring - a.ry + a.t / 2 - sh / 2
        c.ellipse(cx, ky + 7 * d, 12 * d, 9 * d, C(0xFF3020, 0.10))
        crawlGrid6(c, kx, ky, crawlOrcSkull, ["b": bone, "s": boneD, "k": C(0x2A1414), "r": C(0xFF3828), "w": C(0xF8F0DC)], cell: d)
        c.rect(kx + 4 * d, ky + 7 * d, d / 2 + 1, d / 2 + 1, C(0xFFC0A0)); c.rect(kx + 12 * d, ky + 7 * d, d / 2 + 1, d / 2 + 1, C(0xFFC0A0))
    }

    /// The Death Watch stage's life: the two spotlights sweeping back and forth across the set, each with its pool
    /// on the boards, and the marquee's bulbs chasing round it.
    static func crawlDeathWatchLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlDeathWatchFrame(c, g)
        for (k, l) in f.lamps.enumerated() {
            let dir = k == 0 ? 1.0 : -1.0
            let swing = sin(t * 0.6 + Double(k) * 1.9)
            let tx = l.x + Int(dir * Double(70 * s) + swing * Double(60 * s))
            let y0 = l.y + 7 * s, span = Double(g - y0)
            for y in stride(from: y0, to: g, by: s) {
                let v = Double(y - y0) / span
                let x = l.x + Int(Double(tx - l.x) * v), half = Int(Double(3 * s) + v * Double(14 * s))
                c.rect(x - half, y, half * 2, s, C(0xFFF0C8, 0.07))
            }
            c.ellipse(tx, g + 3 * s, 18 * s, 3 * s, C(0xFFF0C8, 0.12))
            c.ellipse(tx, g + 3 * s, 10 * s, 2 * s, C(0xFFF8E0, 0.10))
        }
        let n = f.bulbs.count, step = Int(t * 8)
        for (i, b) in f.bulbs.enumerated() where (i + step) % 3 == 0 && n > 0 {
            c.rect(b.0, b.1, s, s, C(0xFFF8D0))
        }
    }
}

// MARK: - Havana, Eighth Floor

/// One pastel colour of a Havana house: its wall, the shade, the light on its trim, and the deep shadow under its
/// arcade.
private struct CrawlHavanaPaint {
    let wall: Px, shade: Px, light: Px, deep: Px
}

private let crawlHavanaPaints = [
    CrawlHavanaPaint(wall: C(0xC8848E), shade: C(0xA0646E), light: C(0xE0A4AC), deep: C(0x4A2830)),
    CrawlHavanaPaint(wall: C(0x7CB49C), shade: C(0x5C947C), light: C(0xA0D0BC), deep: C(0x26403A)),
    CrawlHavanaPaint(wall: C(0xD0B468), shade: C(0xA88C4C), light: C(0xE8CC90), deep: C(0x4A3C20)),
    CrawlHavanaPaint(wall: C(0x7CA4C8), shade: C(0x5C84A8), light: C(0xA0C0DC), deep: C(0x26344A)),
    CrawlHavanaPaint(wall: C(0xA48CC0), shade: C(0x846CA0), light: C(0xC4B0DC), deep: C(0x362C4E)),
    CrawlHavanaPaint(wall: C(0xD89C74), shade: C(0xB07858), light: C(0xECBC98), deep: C(0x4A3020)),
]

private struct CrawlHavanaFrame {
    /// The houses along the street, left to right: where each starts, how wide and tall, which paint.
    var houses: [(x: Int, w: Int, h: Int, paint: Int)]
    var tower: (x: Int, w: Int, top: Int)
    /// The column of demon fire: its middle, and how high it reaches.
    var fire: (x: Int, top: Int)

    /// The top of whatever house stands at column `x` (the sky ends there).
    func roof(_ x: Int, _ g: Int) -> Int {
        for h in houses where x >= h.x && x < h.x + h.w { return g - h.h - 1 }
        return g
    }
}

extension Scenes {
    /// Where things stand in Havana, shared by the still picture and the moving layer: the houses (so the far-off
    /// fire stays behind their roofs), the FOCSA tower, and the fire column.
    private static func crawlHavanaFrame(_ c: PixelCanvas, _ g: Int) -> CrawlHavanaFrame {
        let s = unit(g), tall = isTall(c)
        var houses: [(x: Int, w: Int, h: Int, paint: Int)] = []
        var x = -6 * s, i = 0
        let order = [0, 2, 4, 1, 5, 3]
        while x < c.w {
            let w = (40 + Int(noise(i * 7 + 3) * 14)) * s, h = (31 + Int(noise(i * 7 + 5) * 9)) * s
            houses.append((x, w, h, order[i % 6])); x += w; i += 1
        }
        let top = tall ? max(28 * s, g - 210 * s) : g - 60 * s
        let tower = (x: c.w * 64 / 100, w: 54 * s, top: top)
        let fire = (x: c.w * 24 / 100, top: tall ? max(20 * s, g - 170 * s) : 2 * s)
        return CrawlHavanaFrame(houses: houses, tower: tower, fire: fire)
    }

    /// Havana on the Eighth Floor: a hot afternoon street of old colonial houses in sun-faded pastels (pink, mint,
    /// butter yellow, sky blue, lilac and peach), each with a cornice, tall shuttered windows over little iron
    /// balconies and a shady arcade along the pavement; over their roofs the FOCSA tower, the city's great white
    /// modernist block, its two wings striped with balconies and a mast on top, and a hazy skyline far off; two
    /// vintage cars parked at the kerb, a turquoise one on the left and a cherry red one on the right, chrome and
    /// whitewall tyres. The floor is the grey street. Far off on the left a column of demon fire (the moving
    /// layer) climbs from behind the roofs. On the screen saver the tower climbs high into a deepening sky, a pall
    /// of smoke spreading where the fire column ends.
    static func crawlHavana(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlHavanaFrame(c, g)

        // The sky: a hot, hazy blue fading to cream at the horizon, deeper and bluer up high on the screen saver.
        if tall { c.gradient(0, g - 60 * s, C(0x4A84B8), C(0x8EC0D8), bands: 6) }
        c.gradient(tall ? g - 60 * s : 0, g - 20 * s, C(0x8EC0D8), C(0xE8DCC0), bands: 5)
        // On the screen saver: a pall of smoke where the fire column ends, a few hazy clouds.
        if tall {
            for k in 0..<6 {
                let x = f.fire.x + (k * 13 - 30) * s, y = f.fire.top + Int(noise(k + 31) * 10) * s
                c.ellipse(x, y, (18 + k * 3) * s, (6 + k % 3) * s, C(0x4A3A44, 0.18))
            }
            for k in 0..<4 {
                let x = Int(noise(k * 5 + 7) * Double(c.w)), y = g - (80 + Int(noise(k * 5 + 8) * 90)) * s
                if abs(x - f.fire.x) < 50 * s || abs(x - f.tower.x) < 50 * s { continue }
                cloud(c, x, y, 6 * s, seed: k + 3, top: C(0xF4F4EC, 0.7), base: C(0xD8E4E8, 0.6))
            }
        }
        // The fire's red glow on the horizon, behind the roofs.
        c.ellipse(f.fire.x, g - 30 * s, 24 * s, 10 * s, C(0xFF5020, 0.16))

        // The far skyline: low blocks in the haze.
        for k in 0..<(c.w / (10 * s) + 1) {
            let h = (6 + Int(noise(k * 3 + 11) * 12)) * s
            c.rect(k * 10 * s, g - 30 * s - h, 10 * s, h + 10 * s, C(0xC8C4C0))
            c.rect(k * 10 * s, g - 30 * s - h, s, h + 10 * s, C(0xD8D4CC))
        }

        crawlHavanaTower(c, g, f.tower, s)

        // The houses.
        for (i, h) in f.houses.enumerated() { crawlHavanaHouse(c, g, h.x, h.w, h.h, crawlHavanaPaints[h.paint], shutterTeal: i % 2 == 0, s) }

        // The street lamps between some of the houses: dark iron posts with a white globe.
        for x in [c.w * 34 / 100, c.w * 52 / 100] {
            c.rect(x, g - 24 * s, s, 24 * s, C(0x2A2428)); c.rect(x - s, g - 2 * s, 3 * s, 2 * s, C(0x2A2428))
            c.rect(x - s, g - 27 * s, 3 * s, 3 * s, C(0xF4F0E0)); c.rect(x - s, g - 24 * s, 3 * s, s, C(0x2A2428))
        }

        // The floor: the grey street, a pale kerb along the pavement's edge.
        c.ground(g, C(0x48444A), edge: C(0x9A9488), speck: C(0x3E3A40), seed: 89)
        c.rect(0, g + s, c.w, s, C(0x5A5458))

        // The cars, parked at the kerb at either side.
        crawlHavanaCar(c, c.w * 2 / 100, g, body: C(0x3AA8A8), light: C(0x70D0D0), roof: C(0xF0ECDC), flip: false, s)
        crawlHavanaCar(c, c.w * 98 / 100 - 36 * s, g, body: C(0xC83838), light: C(0xE86060), roof: C(0xF4F0E8), flip: true, s)
    }

    /// The FOCSA tower: two tall wings in a shallow V round a narrow core, the left wing lit and the right in shade,
    /// both striped with balcony bands, a block and a mast on its roof.
    private static func crawlHavanaTower(_ c: PixelCanvas, _ g: Int, _ t: (x: Int, w: Int, top: Int), _ s: Int) {
        let lit = C(0xE8E0D4), litD = C(0xB8B0A4), shade = C(0xB0A8A0), shadeD = C(0x8A8480), core = C(0xC8C0B4)
        let half = t.w / 2, bottom = g - 10 * s
        // The left wing (lit), stepping up a little to the core; the right wing (shade), stepping down from it.
        c.rect(t.x - half, t.top + 4 * s, half - 3 * s, bottom - t.top - 4 * s, lit)
        c.rect(t.x - 3 * s, t.top, 6 * s, bottom - t.top, core)
        c.rect(t.x + 3 * s, t.top + 3 * s, half - 3 * s, bottom - t.top - 3 * s, shade)
        c.rect(t.x - half, t.top + 4 * s, s, bottom - t.top, C(0xF4F0E8))
        // Balcony bands and the windows' mullions.
        for y in stride(from: t.top + 6 * s, to: bottom, by: 3 * s) {
            c.rect(t.x - half + s, y, half - 4 * s, s, litD)
            c.rect(t.x + 4 * s, y, half - 4 * s, s, shadeD)
        }
        for x in stride(from: t.x - half + 4 * s, to: t.x - 3 * s, by: 5 * s) { c.rect(x, t.top + 6 * s, max(1, s / 2), bottom - t.top - 6 * s, C(0xD4CCC0)) }
        for x in stride(from: t.x + 7 * s, to: t.x + half, by: 5 * s) { c.rect(x, t.top + 5 * s, max(1, s / 2), bottom - t.top - 5 * s, C(0x9C968E)) }
        c.rect(t.x - s, t.top, s, bottom - t.top, C(0xA8A096))
        // The roof: a block (the restaurant up there) and a mast.
        c.rect(t.x - 9 * s, t.top - 5 * s, 18 * s, 5 * s, core); c.rect(t.x - 9 * s, t.top - 5 * s, 18 * s, s, C(0xF0E8DC))
        c.rect(t.x - 8 * s, t.top - 3 * s, 16 * s, s, C(0x6A7A88))
        c.rect(t.x + 2 * s, t.top - 12 * s, s, 7 * s, C(0x8A8480)); c.rect(t.x + 2 * s, t.top - 13 * s, s, s, C(0xE04030))
    }

    /// One house on the street: its pastel wall, a cornice along the top, a row or two of tall windows with shutters
    /// and little iron balconies, and the arcade at the bottom, its arches deep in shade.
    private static func crawlHavanaHouse(_ c: PixelCanvas, _ g: Int, _ x: Int, _ w: Int, _ h: Int, _ p: CrawlHavanaPaint,
                                         shutterTeal: Bool, _ s: Int) {
        let top = g - h, arcade = g - 13 * s, iron = C(0x2A2428)
        let shutter = shutterTeal ? C(0x3A8A88) : C(0xF0ECE0)
        c.rect(x, top, w, h, p.wall); c.rect(x, top, s, h, p.light); c.rect(x + w - s, top, s, h, p.shade)
        // The cornice, and a parapet over it.
        c.rect(x, top, w, s, p.light); c.rect(x, top + s, w, 2 * s, p.wall); c.rect(x, top + 3 * s, w, s, p.shade)
        // The windows.
        for y in stride(from: top + 6 * s, through: arcade - 11 * s, by: 10 * s) {
            for wx in stride(from: x + 5 * s, through: x + w - 8 * s, by: 10 * s) {
                c.rect(wx, y - s, 4 * s, s, p.light)
                c.rect(wx, y, 4 * s, 7 * s, C(0x3A2830))
                c.rect(wx - s, y, s, 7 * s, shutter); c.rect(wx + 4 * s, y, s, 7 * s, shutter)
                c.rect(wx - s, y + 7 * s, 6 * s, s, iron); c.rect(wx - s, y + 5 * s, 6 * s, s, iron.alpha(0.7))
                c.rect(wx - s, y + 5 * s, s, 3 * s, iron); c.rect(wx + 4 * s, y + 5 * s, s, 3 * s, iron)
            }
        }
        // The arcade: a band over it, then arches between the columns, dark inside.
        c.rect(x, arcade - 2 * s, w, s, p.shade); c.rect(x, arcade - s, w, s, p.light)
        for bx in stride(from: x + 3 * s, through: x + w - 8 * s, by: 9 * s) {
            c.rect(bx, arcade + 3 * s, 6 * s, g - arcade - 3 * s, p.deep)
            c.ellipse(bx + 3 * s, arcade + 3 * s, 3 * s, 2 * s, p.deep)
            c.rect(bx + 6 * s, arcade, s, g - arcade, p.shade)
        }
    }

    /// A vintage car, side on: a long two-tone body with a tail fin, chrome bumpers and a chrome stripe, a pale roof
    /// over the cabin's windows, whitewall tyres. `flip` turns it to face left.
    private static func crawlHavanaCar(_ c: PixelCanvas, _ x: Int, _ g: Int, body: Px, light: Px, roof: Px, flip: Bool, _ s: Int) {
        let len = 36 * s
        func r(_ dx: Int, _ dy: Int, _ w: Int, _ h: Int, _ col: Px) {
            c.rect(flip ? x + len - (dx + w) * s : x + dx * s, g - dy * s, w * s, h * s, col)
        }
        let chrome = C(0xD8DCE0), glass = C(0x5A7A8A)
        // The cabin and its roof.
        r(10, 15, 16, 1, roof); r(9, 14, 18, 4, roof)
        r(11, 13, 7, 3, glass); r(19, 13, 6, 3, glass); r(11, 13, 2, 1, C(0xA8C8D4))
        // The body: rounded at the ends, a fin at the back, the stripe along it.
        r(1, 11, 33, 1, light); r(0, 10, 36, 5, body); r(32, 12, 4, 2, body); r(35, 12, 1, 1, light)
        r(2, 8, 32, 1, chrome)
        r(0, 6, 36, 1, C(0x1A1A1E, 0.35))
        // Bumpers, the headlight and the tail light.
        r(-1, 6, 3, 2, chrome); r(34, 6, 3, 2, chrome)
        r(0, 9, 1, 2, C(0xFFF0B0)); r(35, 10, 1, 2, C(0xE02020))
        // The wheels: dark tyres, a white wall, a chrome hub.
        for wx in [7, 28] {
            let cx = flip ? x + len - wx * s : x + wx * s
            c.circle(cx, g - 3 * s, 3 * s, C(0x1E1C20)); c.circle(cx, g - 3 * s, 2 * s, C(0xE8E8E0))
            c.circle(cx, g - 3 * s, s, C(0x9A9AA0))
        }
    }

    /// Havana's life: the column of demon fire far off, licking up from behind the roofs and flickering as it
    /// goes, fading out at its top, and the heat haze wavering over the rooftops.
    static func crawlHavanaLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlHavanaFrame(c, g)
        let base = g - 24 * s, top = f.fire.top, span = Double(max(1, base - top))
        for y in stride(from: top, to: base, by: s) {
            let v = Double(base - y) / span
            let wob = sin(Double(y) * 0.21 / Double(s) + t * 7) + 0.5 * sin(Double(y) * 0.07 / Double(s) - t * 3)
            let tongue = max(0, sin(Double(y) * 0.11 / Double(s) - t * 9)) * Double(3 * s) * (1 - v)
            let half = Double(7 * s) - v * Double(3 * s) + wob * Double(s) + tongue
            let shift = Int(sin(Double(y) * 0.05 / Double(s) + t * 1.3) * Double(2 * s))
            let fade = min(1, (1 - v) * 4)
            for x in stride(from: f.fire.x - Int(half) + shift, to: f.fire.x + Int(half) + shift, by: s) where y < f.roof(x, g) {
                let d = abs(Double(x - f.fire.x - shift)) / max(1, half)
                let col = d < 0.35 ? C(0xFFE070) : d < 0.7 ? C(0xF07028) : C(0xC82818)
                c.rect(x, y, s, s, col.alpha(0.85 * fade))
            }
        }
        // The heat haze: faint pale streaks wavering just over the roofs.
        for k in 0..<4 {
            let y0 = g - (38 + k * 6) * s
            for x in stride(from: 0, to: c.w, by: 3 * s) where noise(x / max(1, s) * 3 + k * 101) > 0.55 {
                let y = y0 + Int(sin(Double(x) * 0.04 / Double(s) + t * 2.2 + Double(k)) * Double(s))
                if y < f.roof(x, g) { c.rect(x, y, 3 * s, s, C(0xFFFFFF, 0.06)) }
            }
        }
    }
}

// MARK: - Larracos, Faction Wars

/// The three factions' banners at Larracos (red and black, blue and white, green and gold): the field and the band
/// across it.
private let crawlLarracosFlags: [(field: Px, band: Px)] = [
    (C(0xA82830), C(0x1A1012)), (C(0x2A4A9A), C(0xE8E8F0)), (C(0x3A7A3A), C(0xE8B840)),
]

private struct CrawlLarracosFrame {
    var trench: Int
    /// The banners: each pole's column and its top.
    var poles: [(x: Int, top: Int)]
    /// The castle's middle, the top of its hill, and its unit (bigger on the screen saver).
    var castle: (x: Int, hill: Int, u: Int)
    var smoke: [(x: Int, y: Int)]
}

extension Scenes {
    /// Where things stand at Larracos, shared by the still picture and the moving layer: the trench's lip, the banner
    /// poles, the castle on its hill, and where the smoke rises from.
    private static func crawlLarracosFrame(_ c: PixelCanvas, _ g: Int) -> CrawlLarracosFrame {
        let s = unit(g), u = isTall(c) ? 3 * s : s
        let poles = [6, 30, 92].map { (x: c.w * $0 / 100, top: g - 54 * s) }
        let castle = (x: c.w * 62 / 100, hill: g - 26 * s - 6 * u, u: u)
        let smoke = [(x: c.w * 18 / 100, y: g - 26 * s), (x: c.w * 84 / 100, y: g - 27 * s)]
        return CrawlLarracosFrame(trench: g - 14 * s, poles: poles, castle: castle, smoke: smoke)
    }

    /// Larracos in the Faction Wars: a war of armies on the Ninth Floor, seen from inside a trench. A grey, smoky sky
    /// over far brown hills; a green hill and on it the castle, a grey stone curtain wall with round towers under red
    /// cone roofs and a tall keep in the middle flying a banner; a churned battlefield of mud, craters, stakes and
    /// wire, smoke rising from it; and in front the trench itself, its wall shored with planks and posts, sandbags
    /// along its lip. The factions' banners (red and black, blue and white, green and gold) stand on tall poles. The
    /// floor is the trench's muddy duckboards. On the screen saver the castle looms up much larger and two wooden
    /// siege towers roll up to its walls.
    static func crawlLarracos(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = crawlLarracosFrame(c, g)

        // The sky: grey and heavy up high, a dusty ochre at the horizon.
        if tall { c.gradient(0, g - 80 * s, C(0x4A5262), C(0x6A7484), bands: 6) }
        c.gradient(tall ? g - 80 * s : 0, g - 26 * s, C(0x6A7484), C(0xB8AC98), bands: 5)
        // On the screen saver: heavy banks of cloud and smoke drifting over the battle.
        if tall {
            for k in 0..<10 {
                let x = Int(noise(k * 11 + 601) * Double(c.w)), y = Int(noise(k * 11 + 602) * Double(max(1, g - 140 * s))) + 10 * s
                c.ellipse(x, y, (40 + k * 4) * s, (5 + k % 3 * 2) * s, C(0x3A4250, 0.35))
                c.ellipse(x - 6 * s, y - 3 * s, (28 + k * 3) * s, (3 + k % 2) * s, C(0x7A8494, 0.25))
            }
        }
        // The far hills.
        c.dunes(base: g - 27 * s, amp: Double(3 * s), freq: 0.02 / Double(s), phase: 1.3, bottom: g, C(0x8A8670), shade: C(0x9A9680))

        crawlLarracosCastle(c, g, f.castle)

        // The smoke still rising from the battlefield: dark columns leaning with the wind.
        for p in f.smoke {
            let rows = tall ? 16 : 6
            for k in 0..<rows {
                let jx = Int((noise(p.x + k * 7) - 0.5) * Double(4 * s)), r = (4 + k * 3 / 2) * s
                let a = max(0.04, 0.22 - Double(k) * (tall ? 0.012 : 0.03))
                c.ellipse(p.x + k * 3 * s + jx, p.y - k * 5 * s, r, r * 2 / 3, C(0x3A3836, a))
            }
        }

        // The battlefield: churned mud, craters, stakes and wire.
        let field = g - 26 * s
        c.rect(0, field, c.w, f.trench - field, C(0x5E4E3A))
        for y in stride(from: field + 3 * s, to: f.trench, by: 4 * s) { c.rect(0, y, c.w, s, C(0x544432)) }
        for k in 0..<(c.w / (60 * s) + 1) {
            let x = k * 60 * s + Int(noise(k + 211) * Double(30 * s)), y = field + (4 + Int(noise(k + 223) * 4)) * s
            c.ellipse(x, y, 9 * s, 2 * s, C(0x6E5C46)); c.ellipse(x, y + s, 7 * s, s, C(0x3A3024))
        }
        let stakes = stride(from: 4 * s, to: c.w, by: 14 * s).map { $0 }
        for (k, x) in stakes.enumerated() {
            let y = field + 2 * s + (k % 2) * s
            c.rect(x, y, s, 5 * s, C(0x2E2418))
            if k + 1 < stakes.count { for wx in stride(from: x, to: stakes[k + 1], by: 2 * s) { c.rect(wx, y + s + (wx / (2 * s)) % 2 * s, s, s, C(0x3A3430)) } }
        }

        // On the screen saver: two siege towers rolling up to the walls.
        if tall {
            let u = f.castle.u
            for x in [f.castle.x - 52 * u, f.castle.x + 40 * u] { crawlSiegeTower(c, x, field + 4 * s, u, s) }
        }

        // The trench wall: planks shored up by posts, sandbags along the lip.
        let tr = f.trench
        c.rect(0, tr, c.w, g - tr, C(0x4A3424))
        for y in stride(from: tr + 3 * s, to: g, by: 3 * s) { c.rect(0, y, c.w, s, C(0x3A2818)) }
        for x in stride(from: 10 * s, to: c.w, by: 24 * s) { c.rect(x, tr, 3 * s, g - tr, C(0x34241A)); c.rect(x, tr, s, g - tr, C(0x5A4230)) }
        for (k, x) in stride(from: -2 * s, to: c.w, by: 7 * s).enumerated() {
            let y = tr - 3 * s - (k % 3 == 0 ? s : 0)
            c.ellipse(x + 3 * s, y + 2 * s, 4 * s, 2 * s, C(0x6A5C42)); c.rect(x + s, y + s, 4 * s, s, C(0x847452))
            c.rect(x + 6 * s, y + 2 * s, s, 2 * s, C(0x4A3E2A))
        }

        // The banner poles: dark wood, a gold point on top, the cloth hanging at rest (the moving layer snaps it).
        for (k, p) in f.poles.enumerated() {
            c.rect(p.x, p.top, 2 * s, tr - p.top, C(0x4A3420)); c.rect(p.x, p.top, s, tr - p.top, C(0x6A4E30))
            c.rect(p.x - s, p.top - 3 * s, 4 * s, s, C(0xC89A38)); c.rect(p.x, p.top - 4 * s, 2 * s, 4 * s, C(0xE8C050))
            crawlLarracosFlag(c, p.x + 2 * s, p.top + s, crawlLarracosFlags[k % 3], s, t: nil)
        }

        // The floor: muddy duckboards, the slats running across.
        c.ground(g, C(0x3A2E24), edge: C(0x5A4834), speck: C(0x30261C), seed: 97)
        for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x, g + 2 * s, s, c.h - g - 3 * s, C(0x342A20)) }
    }

    /// The castle on its hill, in units of `u` (one place unit in the window, three on the screen saver): the hill
    /// lit on its left, the keep behind, the curtain wall with its gate, two round towers under red cone roofs, and a
    /// purple and gold banner on the keep (the castle's own lord, none of the three in the trenches).
    private static func crawlLarracosCastle(_ c: PixelCanvas, _ g: Int, _ k: (x: Int, hill: Int, u: Int)) {
        let u = k.u, cx = k.x
        let stone = C(0x8C8880), stoneD = C(0x6C6862), stoneL = C(0xA8A49C), slit = C(0x2A2828)
        // The hill: rounded, lit on the left, its right side in shade.
        let rx = 72 * u, ry = 16 * u
        for dy in 0..<(g - k.hill) {
            let v = 1 - Double(dy) / Double(ry)
            let half = v <= 0 ? rx : Int(Double(rx) * (1 - v * v).squareRoot())
            c.rect(cx - half, k.hill + dy, half * 2, 1, C(0x5E6648))
            c.rect(cx + half / 3, k.hill + dy, half * 2 / 3, 1, C(0x4E5640))
            c.rect(cx - half, k.hill + dy, max(1, half / 4), 1, C(0x6E7656))
        }
        let base = k.hill + 2 * u
        // The keep: a tall block behind the wall, crenels on top, arrow slits, a banner flying from a pole.
        let kw = 20 * u, kt = base - 28 * u
        c.rect(cx - kw / 2, kt, kw, base - kt, stone); c.rect(cx + kw / 2 - 5 * u, kt, 5 * u, base - kt, stoneD)
        c.rect(cx - kw / 2, kt, u, base - kt, stoneL)
        for x in stride(from: cx - kw / 2, to: cx + kw / 2, by: 4 * u) { c.rect(x, kt - 2 * u, 2 * u, 2 * u, stone) }
        for x in [cx - 4 * u, cx + 3 * u] { c.rect(x, kt + 4 * u, u, 3 * u, slit) }
        c.rect(cx, kt - 7 * u, max(1, u / 2), 5 * u, C(0x4A3420))
        c.rect(cx + max(1, u / 2), kt - 7 * u, 5 * u, 3 * u, C(0x5A2A7A)); c.rect(cx + max(1, u / 2), kt - 6 * u, 5 * u, u, C(0xE8C050))
        // The curtain wall, crenellated, a dark gate in its middle.
        let ww = 64 * u, wt = base - 14 * u
        c.rect(cx - ww / 2, wt, ww, base - wt, stone); c.rect(cx - ww / 2, wt, ww, u, stoneL)
        for x in stride(from: cx - ww / 2, to: cx + ww / 2, by: 4 * u) { c.rect(x, wt - 2 * u, 2 * u, 2 * u, stone) }
        for y in stride(from: wt + 3 * u, to: base, by: 3 * u) { c.rect(cx - ww / 2, y, ww, max(1, u / 2), stoneD) }
        c.rect(cx - 4 * u, base - 8 * u, 8 * u, 8 * u, slit); c.ellipse(cx, base - 8 * u, 4 * u, 2 * u, slit)
        // The towers at either end: round (lit on the left, shaded on the right), red cone roofs.
        for tx in [cx - ww / 2 - 4 * u, cx + ww / 2 - 4 * u] {
            let tt = base - 20 * u
            c.rect(tx, tt, 8 * u, base - tt, stone); c.rect(tx, tt, 2 * u, base - tt, stoneL); c.rect(tx + 5 * u, tt, 3 * u, base - tt, stoneD)
            c.rect(tx + 3 * u, tt + 5 * u, u, 3 * u, slit)
            for row in 0..<(9 * u) {
                let half = (5 * u) * (9 * u - row) / (9 * u)
                c.rect(tx + 4 * u - half, tt - row, half * 2, 1, C(0x8A3A2A))
                c.rect(tx + 4 * u + half / 3, tt - row, max(0, half * 2 / 3), 1, C(0x6A2A20))
            }
            c.rect(tx - u, tt, 10 * u, u, C(0x5A2A20))
        }
    }

    /// A siege tower: a tall wooden frame covered in hides, cross braces showing, a drawbridge raised at its top, on
    /// big wooden wheels.
    private static func crawlSiegeTower(_ c: PixelCanvas, _ x: Int, _ foot: Int, _ u: Int, _ s: Int) {
        let w = 12 * u, h = 34 * u, top = foot - h
        let hide = C(0x8A6A48), hideD = C(0x6A4E34), wood = C(0x4A3420)
        c.rect(x, top, w, h, hide); c.rect(x + w - 3 * u, top, 3 * u, h, hideD); c.rect(x, top, u, h, C(0xA8865E))
        for y in stride(from: top + 6 * u, to: foot, by: 7 * u) { c.rect(x, y, w, u, wood) }
        c.rect(x, top, u, h, wood); c.rect(x + w - u, top, u, h, wood)
        for y in stride(from: top + 6 * u, to: foot - 7 * u, by: 7 * u) {
            c.glowLine(Double(x + u), Double(y + u), Double(x + w - u), Double(y + 7 * u), core: wood, glow: C(0, 0),
                       coreR: Double(u) * 0.5, glowR: Double(u) * 0.6)
        }
        // The fighting top: a wooden parapet, crenellated, and the drawbridge raised against its front.
        c.rect(x - u, top - 2 * u, w + 2 * u, 2 * u, wood)
        c.rect(x - u, top - 7 * u, w + 2 * u, 5 * u, C(0x5A4028)); c.rect(x - u, top - 7 * u, w + 2 * u, u, C(0x7A5A3A))
        for cx in stride(from: x - u, to: x + w + u, by: 4 * u) { c.rect(cx, top - 9 * u, 2 * u, 2 * u, C(0x5A4028)) }
        c.rect(x + 3 * u, top - 8 * u, w - 6 * u, 6 * u, C(0x6A4A30)); c.rect(x + 3 * u, top - 8 * u, w - 6 * u, u, C(0x8A6A48))
        c.rect(x + 3 * u, top - 5 * u, w - 6 * u, max(1, u / 2), C(0x3A2818))
        for wx in [x + 2 * u, x + w - 2 * u] { c.circle(wx, foot, 3 * u, C(0x3A2818)); c.circle(wx, foot, u, C(0x6A5038)) }
    }

    /// A faction's banner hanging from its pole at (`x`, `y`): at rest (`t` nil, a little smaller, so the moving
    /// layer's flapping one always covers it), or flapping in the wind at clock `t`, rippling more towards its
    /// swallowtailed end.
    private static func crawlLarracosFlag(_ c: PixelCanvas, _ x: Int, _ y: Int, _ flag: (field: Px, band: Px), _ s: Int, t: Double?) {
        guard let t else {
            c.rect(x, y + s, 13 * s, 8 * s, flag.field); c.rect(x, y + 4 * s, 13 * s, 2 * s, flag.band)
            return
        }
        for k in 0..<16 {
            let reach = Double(k) / 15
            let dy = Int((sin(Double(k) * 0.7 - t * 9) * 1.1 * reach).rounded()) * s
            let slope = cos(Double(k) * 0.7 - t * 9) * reach
            let notch = k >= 13 ? (k - 12) : 0
            let fx = x + k * s, fy = y + dy
            var field = flag.field
            if slope > 0.4 { field = lerp(flag.field, C(0xFFFFFF), 0.18) } else if slope < -0.4 { field = lerp(flag.field, C(0x000000), 0.25) }
            if notch == 0 {
                c.rect(fx, fy, s, 10 * s, field); c.rect(fx, fy + 4 * s, s, 2 * s, flag.band)
            } else {
                // The swallowtail: the cloth cut away from the middle, wider towards the end.
                c.rect(fx, fy, s, 5 * s - notch * s, field); c.rect(fx, fy + 5 * s + notch * s, s, 5 * s - notch * s, field)
            }
        }
    }

    /// Larracos's life: the banners snapping in the wind, and smoke drifting slowly across the sky.
    static func crawlLarracosLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), f = crawlLarracosFrame(c, g)
        for (k, p) in f.poles.enumerated() {
            crawlLarracosFlag(c, p.x + 2 * s, p.top + s, crawlLarracosFlags[k % 3], s, t: t + Double(k) * 0.7)
        }
        let sky = g - 30 * s, span = tall ? sky - 10 * s : sky - 4 * s
        let loop = Double(c.w + 80 * s)
        for k in 0..<(tall ? 9 : 4) {
            let x = Int((noise(k * 13 + 1) * loop + t * Double(5 * s)).truncatingRemainder(dividingBy: loop)) - 40 * s
            let y = sky - Int(noise(k * 13 + 2) * Double(max(1, span)))
            c.ellipse(x, y, 14 * s, 3 * s, C(0x5A5650, 0.12)); c.ellipse(x - 4 * s, y - 2 * s, 8 * s, 2 * s, C(0x8A8680, 0.10))
        }
    }
}

// MARK: - Emberus's High Temple

/// Emberus's sigil: a flame, orange round a yellow heart.
private let crawlEmberFlame = [
    "....o....",
    "...oo....",
    "...ooo...",
    "..oooo.o.",
    "..ooyoo..",
    ".ooyyyoo.",
    ".oyyyyyo.",
    ".oyywyyo.",
    "..oyyyo..",
    "...ooo...",
]

private struct CrawlTempleFrame {
    var frieze: Int
    var fountain: Int
    var stump: Int
    var brazier: (x: Int, y: Int)
    var pools: [Int]
    /// The cracks in the floor, as the cells (one place unit each) the lava shows through.
    var cracks: [[(Int, Int)]]
    /// The dome (screen saver only): where it springs and how high it rises.
    var dome: (spring: Int, ry: Int)
}

extension Scenes {
    /// Where things stand in the temple, shared by the still picture and the moving layer: the frieze, the fountain,
    /// the charred stump, the brazier's bowl, the lava pools and the floor's cracks, and (on the screen saver) the
    /// dome.
    private static func crawlTempleFrame(_ c: PixelCanvas, _ g: Int) -> CrawlTempleFrame {
        let s = unit(g), frieze = g - 62 * s
        var cracks: [[(Int, Int)]] = []
        for k in 0..<(c.w / (48 * s) + 1) {
            var x = k * 48 * s + Int(noise(k * 5 + 401) * Double(20 * s)), y = g + (3 + Int(noise(k * 5 + 402) * 4)) * s
            var path: [(Int, Int)] = []
            for j in 0..<(6 + Int(noise(k * 5 + 403) * 6)) {
                path.append((x, y))
                x += s
                let n = noise(k * 31 + j * 7 + 404)
                if n > 0.66 && y < c.h - 2 * s { y += s } else if n < 0.33 && y > g + 2 * s { y -= s }
            }
            cracks.append(path)
        }
        var dome = (spring: -1, ry: 0)
        if isTall(c) { let sp = frieze - 4 * s; dome = (sp, min(sp - 6 * s, c.w * 40 / 100)) }
        return CrawlTempleFrame(frieze: frieze, fountain: c.w / 2, stump: c.w * 78 / 100, brazier: (c.w * 19 / 100, g - 17 * s),
                                pools: [c.w * 6 / 100, c.w * 94 / 100], cracks: cracks, dome: dome)
    }

    /// Emberus's High Temple: the fire god's marble hall, warm grey stone rather than red so the crew reads on it.
    /// Big ashlar blocks, fluted marble columns holding up a dark frieze of little gold flames; Emberus's sigil, a
    /// flame in a gold ring, high on the wall either side; in the middle a tiered marble fountain whose water boils, spilling
    /// from its top bowl into the basin below; a bronze brazier burning on the left; on the right a charred tree
    /// stump, black and split, embers glowing in its cracks. The floor is dark basalt, molten lava showing through its
    /// cracks and welling up in pools at either side. On the screen saver a great smoky dome rises over it all, its
    /// bronze ribs and rings meeting at an oculus of hazy light, smoke hanging in wreaths under it.
    static func crawlTemple(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = crawlTempleFrame(c, g)
        let wall = C(0x84746C), wallD = C(0x6C5E58), wallL = C(0x968880)
        let gold = C(0xD8A030), goldD = C(0x9A6A20)

        // The wall: big blocks in courses, each lit along its top, the joints staggered.
        c.rect(0, 0, c.w, g, wall)
        for (row, y) in stride(from: g - 10 * s, to: -10 * s, by: -10 * s).enumerated() {
            c.rect(0, y, c.w, s, wallD); c.rect(0, y + s, c.w, s, wallL)
            for x in stride(from: (row % 2) * 12 * s, to: c.w, by: 24 * s) { c.rect(x, y, s, 10 * s, wallD) }
        }
        // The lava's warm light on the lower wall, and soot climbing it towards the top.
        for k in 0..<8 { c.rect(0, g - (k + 1) * 4 * s, c.w, 4 * s, C(0xFF8040, 0.012 * Double(8 - k))) }
        for k in 0..<6 { c.rect(0, f.frieze - (k + 1) * 4 * s, c.w, 4 * s, C(0x2A2220, 0.06 * Double(k + 1))) }
        if f.dome.spring > 0 { crawlTempleDome(c, g, f) } else { c.rect(0, 0, c.w, max(0, f.frieze - 24 * s), C(0x2A2220, 0.36)) }

        // The frieze: a dark band edged in gold, little gold flames along it.
        let fy = f.frieze
        c.rect(0, fy - 2 * s, c.w, 2 * s, C(0xA89C92)); c.rect(0, fy - 2 * s, c.w, s, C(0xC0B4A8))
        c.rect(0, fy, c.w, 6 * s, C(0x3E3430)); c.rect(0, fy, c.w, s, gold); c.rect(0, fy + 5 * s, c.w, s, goldD)
        for x in stride(from: 4 * s, to: c.w, by: 12 * s) {
            c.rect(x + s, fy + 2 * s, s, s, C(0xF0B840)); c.rect(x, fy + 3 * s, 3 * s, s, gold); c.rect(x + s, fy + 4 * s, s, s, goldD)
        }

        // The columns: fluted marble, a capital under the frieze and a base on the floor, lit on the left.
        for px in [10, 33, 67, 90] {
            let x = c.w * px / 100 - 5 * s, top = fy + 6 * s
            c.rect(x, top, 10 * s, g - top, C(0x948880))
            for k in 0..<3 { c.rect(x + (2 + k * 3) * s, top, s, g - top, C(0x847870)) }
            c.rect(x, top, 2 * s, g - top, C(0xAEA298)); c.rect(x + 8 * s, top, 2 * s, g - top, C(0x7A6E66))
            c.rect(x - 2 * s, top, 14 * s, 3 * s, C(0xAEA298)); c.rect(x - 2 * s, top + 2 * s, 14 * s, s, C(0x7A6E66))
            c.rect(x - 2 * s, g - 4 * s, 14 * s, 4 * s, C(0x8A7E76)); c.rect(x - 2 * s, g - 4 * s, 14 * s, s, C(0xAEA298))
        }

        // Emberus's sigil, once in each bay either side of the fountain: a gold ring, a dark disc, the flame.
        for mx in [c.w * 215 / 1000, c.w * 785 / 1000] {
            let my = g - 44 * s
            c.ellipse(mx, my, 16 * s, 12 * s, C(0xFF9040, 0.08))
            c.circle(mx, my, 9 * s, goldD); c.circle(mx, my, 8 * s, gold); c.circle(mx, my, 7 * s, C(0x3E3430))
            crawlGrid6(c, mx - 4 * s - s / 2, my - 5 * s, crawlEmberFlame, ["o": C(0xE86A20), "y": C(0xFFC040), "w": C(0xFFF0C0)], cell: s)
        }

        crawlTempleFountain(c, g, f.fountain, s)
        crawlTempleStump(c, g, f.stump, s); crawlTempleStumpEmbers(c, g, f.stump, s, glow: 0.55)

        // The brazier: a bronze bowl on three legs, coals in it (the moving layer lights the flame).
        let b = f.brazier
        c.rect(b.x - 6 * s, b.y, 12 * s, 3 * s, C(0x8A6A3A)); c.rect(b.x - 6 * s, b.y, 12 * s, s, C(0xB89058))
        c.rect(b.x - 4 * s, b.y + 3 * s, 8 * s, s, C(0x6A4E2A))
        for (dx, lean) in [(-4, -1), (0, 0), (3, 1)] {
            for k in 0..<4 { c.rect(b.x + (dx + lean * k / 2) * s, b.y + (4 + k * 3) * s, s, 3 * s, C(0x5A4428)) }
        }
        c.rect(b.x - 5 * s, b.y - s, 10 * s, s, C(0xC8501C)); c.rect(b.x - 3 * s, b.y - s, 2 * s, s, C(0xFFA040))

        // The floor: dark basalt, plain under the crew, lava faint in its cracks and pooling at the sides.
        c.ground(g, C(0x3E3634), edge: C(0x6A5E56), speck: C(0x342C2A), seed: 103)
        for path in f.cracks { for (x, y) in path { c.rect(x, y, s, s, C(0x8A3A1C)) } }
        for x in f.pools {
            c.ellipse(x, g - 6 * s, 22 * s, 8 * s, C(0xFF7030, 0.08))
            c.ellipse(x, g + 5 * s, 18 * s, 3 * s, C(0x2A1E1A)); c.ellipse(x, g + 5 * s, 15 * s, 2 * s, C(0xD85A1C))
            c.ellipse(x, g + 5 * s, 9 * s, s, C(0xFFA040))
        }
    }

    /// The fountain, half as big again as its units: a wide basin on a low foot, a fluted pedestal, a bowl on it and
    /// a little spout bowl on top, all in warm grey marble; boiling water spills from each bowl into the next.
    private static func crawlTempleFountain(_ c: PixelCanvas, _ g: Int, _ cx: Int, _ s: Int) {
        let marble = C(0xB8A8A0), shade = C(0x8E8078), light = C(0xD0C4BA), water = C(0x9CC8CC), waterL = C(0xD8F0F0)
        func r(_ dx: Int, _ dy: Int, _ w: Int, _ h: Int, _ col: Px) { crawlBig(c, cx, g, dx, dy, w, h, 7 * s, 5, col) }
        // The spout on top and the bowl under it.
        r(-2, 34, 4, 8, marble); r(1, 34, 1, 8, shade)
        r(-4, 36, 8, 2, light); r(-3, 37, 6, 1, water)
        r(-5, 35, 1, 9, water.alpha(0.75)); r(4, 35, 1, 9, water.alpha(0.75))
        // The pedestal.
        r(-4, 22, 8, 12, marble); r(2, 22, 2, 12, shade); r(-2, 22, 1, 12, shade); r(-4, 22, 1, 12, light)
        // The middle bowl.
        r(-13, 27, 26, 1, water); r(-9, 27, 4, 1, waterL)
        r(-14, 26, 28, 2, light); r(-12, 24, 24, 2, marble); r(4, 24, 8, 2, shade); r(-8, 22, 16, 1, shade)
        // Water spilling from its lip into the basin.
        r(-15, 25, 1, 13, water.alpha(0.7)); r(14, 25, 1, 13, water.alpha(0.7))
        // The basin: its water, a lit rim, the marble front shaded on the right, veins, a foot.
        r(-25, 12, 50, 1, water); r(-20, 12, 6, 1, waterL)
        r(-26, 11, 52, 2, light); r(-26, 9, 52, 1, shade)
        r(-24, 8, 48, 6, marble); r(10, 8, 14, 6, shade)
        for (vx, vy) in [(-18, 7), (-15, 6), (-12, 5), (4, 6), (6, 5)] { r(vx, vy, 2, 1, C(0xA0928A)) }
        r(-21, 2, 42, 2, shade)
    }

    /// The charred stump, half as big again as its units: black and split, its top jagged, a broken branch, roots
    /// clutching the floor, cracks across its bark.
    private static func crawlTempleStump(_ c: PixelCanvas, _ g: Int, _ x: Int, _ s: Int) {
        let char = C(0x2A2420), charD = C(0x161210), charL = C(0x4A403A)
        func r(_ dx: Int, _ dy: Int, _ w: Int, _ h: Int, _ col: Px) { crawlBig(c, x, g, dx, dy, w, h, 3 * s, 2, col) }
        // The trunk, flaring at the foot, its top splintered into shards of different heights.
        let heights = [15, 18, 13, 21, 16, 19, 12]
        for (k, h) in heights.enumerated() { r(k * 2, h, 2, h, char); r(k * 2 + (k % 2), h + 1, 1, 1, char) }
        r(-1, 5, 1, 5, char); r(14, 6, 1, 6, char)
        r(0, 15, 1, 15, charL)
        // The broken branch, sticking up and out to the left.
        for k in 0..<4 { r(-1 - k, 13 + k, 2, 2, char) }
        r(-4, 17, 1, 1, charL)
        // The roots.
        r(-4, 3, 4, 3, char); r(-6, 1, 3, 1, char); r(14, 4, 4, 4, char); r(17, 2, 3, 2, char)
        // The split down its middle, and the bark's grooves running up the trunk, a few checks across them.
        r(7, 20, 1, 14, charD)
        for (gx, top) in [(2, 13), (4, 16), (10, 17), (12, 14)] { r(gx, top, 1, top - 1, charD) }
        for (cx, cy) in [(2, 9), (9, 11), (4, 5), (11, 6)] { r(cx, cy, 2, 1, charD) }
    }

    /// The stump's embers, glowing in some of its cracks at `glow` strength (the still and the moving layer both).
    private static func crawlTempleStumpEmbers(_ c: PixelCanvas, _ g: Int, _ x: Int, _ s: Int, glow: Double) {
        let ember = C(0xFF7028).alpha(glow)
        func r(_ dx: Int, _ dy: Int, _ w: Int, _ h: Int) { crawlBig(c, x, g, dx, dy, w, h, 3 * s, 2, ember) }
        r(4, 11, 1, 4); r(10, 8, 1, 3); r(7, 15, 1, 2); r(-3, 16, 1, 1)
    }

    /// The screen saver's dome: the corners above the frieze in dark sooty stone, the dome's bowl a little lighter,
    /// bronze ribs climbing it to the oculus, two rings across, smoke hanging in wreaths, and hazy light coming in
    /// at the top.
    private static func crawlTempleDome(_ c: PixelCanvas, _ g: Int, _ f: CrawlTempleFrame) {
        let s = unit(g), cx = c.w / 2, sp = f.dome.spring, ry = f.dome.ry, rx = c.w * 48 / 100
        let bronze = C(0x9A7444), bronzeL = C(0xC89A5A)
        c.rect(0, 0, c.w, sp, C(0x4A403C))
        for y in stride(from: sp - ry, to: sp, by: s) {
            let v = Double(sp - y) / Double(ry), half = Int(Double(rx) * (1 - v * v).squareRoot())
            c.rect(cx - half, y, half * 2, s, lerp(C(0x6A605A), C(0x544A46), v))
        }
        // A painted band round the dome's foot: dark, edged in gold, a row of flames like the frieze's but bigger.
        let by = sp - 16 * s, bh = Int(Double(rx) * (1 - pow(Double(sp - by) / Double(ry), 2)).squareRoot())
        c.rect(cx - bh, by, bh * 2, 12 * s, C(0x3E3430)); c.rect(cx - bh, by, bh * 2, s, C(0xD8A030))
        c.rect(cx - bh, by + 11 * s, bh * 2, s, C(0x9A6A20))
        for x in stride(from: cx - bh + 8 * s, to: cx + bh - 8 * s, by: 22 * s) {
            crawlGrid6(c, x, by + s, crawlEmberFlame, ["o": C(0xC8782C), "y": C(0xE8B040), "w": C(0xF4D890)], cell: s)
        }
        // The ribs: from the spring line up to the oculus, following the dome's curve.
        for k in 1..<8 {
            let a = Double.pi * Double(k) / 8
            var last: (Double, Double)? = nil
            for step in 0...24 {
                let h = Double(step) / 24 * 0.9
                let w = Double(rx) * (1 - h * h).squareRoot()
                let p = (Double(cx) + w * cos(a), Double(sp) - Double(ry) * h)
                if let l = last {
                    c.glowLine(l.0, l.1, p.0, p.1, core: bronze, glow: C(0, 0), coreR: Double(s) * 0.9, glowR: Double(s))
                }
                last = p
            }
        }
        for v in [0.33, 0.66] {
            let y = sp - Int(Double(ry) * v), half = Int(Double(rx) * (1 - v * v).squareRoot())
            c.rect(cx - half, y, half * 2, s, bronze); c.rect(cx - half, y - s, half * 2, s, bronzeL.alpha(0.6))
        }
        // The oculus: a ring of bronze, hazy light through it, a shaft of it falling.
        let oy = sp - Int(Double(ry) * 0.92), orx = rx * 18 / 100
        c.ellipse(cx, oy, orx + 2 * s, 5 * s, bronze); c.ellipse(cx, oy, orx, 4 * s, C(0xE8DCC8))
        for k in 0..<10 { c.rect(cx - orx + k * s, oy + 5 * s + k * 8 * s, (orx - k * s) * 2, 8 * s, C(0xFFF0D0, 0.035)) }
        // The smoke: a column of it rising to the oculus, and wreaths of it hanging under the dome.
        for k in 0..<14 {
            let v = Double(k) / 14, y = sp - Int(Double(ry) * v * 0.9)
            let x = cx + Int(sin(Double(k) * 0.9) * Double(6 * s))
            c.ellipse(x, y, (8 + k) * s, 5 * s, C(0xA89A90, 0.10))
        }
        for k in 0..<7 {
            let x = cx + Int((noise(k * 3 + 501) - 0.5) * Double(rx)), y = sp - 20 * s - Int(noise(k * 3 + 502) * Double(ry) * 0.7)
            c.ellipse(x, y, (24 + k * 4) * s, (3 + k % 3) * s, C(0xA89A90, 0.20))
            c.ellipse(x - 4 * s, y - s, (16 + k * 3) * s, 2 * s, C(0xC8BCB0, 0.14))
        }
        // The cornice the dome sits on.
        c.rect(0, sp, c.w, 2 * s, C(0x8C807A)); c.rect(0, sp, c.w, s, C(0xA89C92))
    }

    /// The temple's life: the lava breathing in the floor's cracks and pools, a bubble bursting in a pool now and
    /// then, the fountain boiling (bubbles popping on its water, steam curling up from it), the brazier's flame and
    /// the stump's embers flickering, and on the screen saver the smoke wreaths turning slowly.
    static func crawlTempleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = crawlTempleFrame(c, g)
        // The cracks: a slow glow running along each.
        for (k, path) in f.cracks.enumerated() {
            for (j, p) in path.enumerated() {
                let a = 0.35 + 0.35 * sin(t * 1.6 - Double(j) * 0.5 + Double(k))
                c.rect(p.0, p.1, s, s, C(0xFF8030, a))
            }
        }
        for (k, x) in f.pools.enumerated() {
            let a = 0.3 + 0.25 * sin(t * 1.2 + Double(k) * 2)
            c.ellipse(x, g + 5 * s, 12 * s, s, C(0xFFD060, a))
            let pop = (t * 0.7 + Double(k) * 0.4).truncatingRemainder(dividingBy: 1)
            if pop < 0.3 {
                let bx = x + Int((noise(Int(t * 0.7) + k * 17) - 0.5) * Double(20 * s))
                c.rect(bx - s, g + 4 * s - Int(pop * 6) * s / 2, 2 * s, s, C(0xFFE080, 0.9))
            }
        }
        // The fountain: bubbles popping on the basin and the bowl, steam curling up.
        let cx = f.fountain, tick = Int(t * 5)
        for k in 0..<5 {
            let n = noise(tick * 7 + k * 13)
            let (y, span) = k < 3 ? (g - 13 * s, 46) : (g - 28 * s, 24)
            let bx = cx - span * s / 2 + Int(n * Double(span * s))
            c.rect(bx, y, s, s, C(0xF0FFFF, 0.9))
            if noise(tick * 7 + k * 13 + 1) > 0.5 { c.rect(bx - s, y, 3 * s, s, C(0xF0FFFF, 0.5)) }
        }
        for k in 0..<4 {
            let rise = (t * 0.5 + Double(k) * 0.25).truncatingRemainder(dividingBy: 1)
            let baseY = k % 2 == 0 ? g - 14 * s : g - 29 * s
            let x = cx + (k - 2) * 7 * s + Int(sin(t * 1.5 + Double(k)) * Double(2 * s))
            c.ellipse(x, baseY - Int(rise * 16) * s, (2 + Int(rise * 3)) * s, (1 + Int(rise * 2)) * s, C(0xF4F8F8, 0.22 * (1 - rise)))
        }
        // The brazier's flame.
        let b = f.brazier, h = 5 + Int(t * 9) % 3
        c.rect(b.x - 3 * s, b.y - h * s, 6 * s, h * s, C(0xE85A1C, 0.85))
        c.rect(b.x - 2 * s, b.y - (h + 1) * s, 3 * s, (h - 1) * s, C(0xF8A030))
        c.rect(b.x - s, b.y - (h - 1) * s, 2 * s, (h - 2) * s, C(0xFFE080))
        c.ellipse(b.x, b.y - 3 * s, 12 * s, 8 * s, C(0xFF9040, 0.08))
        // The stump's embers, breathing.
        crawlTempleStumpEmbers(c, g, f.stump, s, glow: 0.4 + 0.4 * sin(t * 2.1))
        // The smoke wreaths under the dome, turning slowly.
        if f.dome.spring > 0 {
            for k in 0..<4 {
                let x = c.w / 2 + Int(sin(t * 0.15 + Double(k) * 1.7) * Double(c.w / 4))
                let y = f.dome.spring - Int(Double(f.dome.ry) * (0.2 + 0.15 * Double(k)))
                c.ellipse(x, y, 30 * s, 3 * s, C(0xA89A90, 0.12))
            }
        }
    }
}
