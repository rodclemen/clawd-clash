import Foundation

// Hook: Neverland, Pirate Town and the Jolly Roger.

let clawdbergScenes10: [Location: Place] = [
    .neverland: Place(name: "Neverland", panel: 0x16261A, still: Scenes.neverland, moving: Scenes.neverlandLife),
    .pirateTown: Place(name: "Pirate Town", panel: 0x2A1E14, still: Scenes.pirateTown, moving: Scenes.pirateTownLife),
    .jollyRoger: Place(name: "The Jolly Roger", panel: 0x221424, still: Scenes.jollyRoger, moving: Scenes.jollyRogerLife),
]

// MARK: - Shared bits for Neverland

/// A hard pixel line with no glow (ropes, rigging, masts).
private func hkLine(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px,
                    _ r: Double = 0.5) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.01)
}

/// A rope slung between two points, sagging by `sag` in the middle, drawn in `n` straight pieces; returns the
/// points along it (for hanging lights on).
@discardableResult
private func hkRope(_ c: PixelCanvas, _ a: (Int, Int), _ b: (Int, Int), sag: Int, _ col: Px, n: Int = 16,
                    draw: Bool = true) -> [(Double, Double)] {
    var pts: [(Double, Double)] = []
    for i in 0...n {
        let q = Double(i) / Double(n)
        let x = Double(a.0) + Double(b.0 - a.0) * q
        let y = Double(a.1) + Double(b.1 - a.1) * q + sin(q * .pi) * Double(sag)
        pts.append((x, y))
    }
    if draw {
        for (p, q) in zip(pts, pts.dropFirst()) { hkLine(c, p.0, p.1, q.0, q.1, col) }
    }
    return pts
}

/// The fairy lights' colours, in the order they hang.
private let hkFairy: [UInt32] = [0xFFD84A, 0xFF7AB8, 0x7AE8FF, 0xFFFFFF, 0xB8FF6A]

// MARK: - Neverland

extension Scenes {
    /// Where Neverland's things are: the giant tree's middle and trunk half-width, the cliff's lip and the
    /// waterfall's left edge and width, the treehouse platforms (x, y, width), and the zip line's two ends.
    private static func hkNeverFrame(_ c: PixelCanvas, _ g: Int) -> (tree: Int, trunk: Int, cliff: Int, fall: (x: Int, w: Int),
                                                                       decks: [(x: Int, y: Int, w: Int)],
                                                                       zip: ((Int, Int), (Int, Int)),
                                                                       lights: [((Int, Int), (Int, Int), Int)]) {
        let s = unit(g), tall = isTall(c)
        let tree = c.w * 74 / 100
        if tall {
            let trunk = 34 * s
            let decks = [(tree - trunk - 40 * s, g - 70 * s, 50 * s), (tree + trunk - 6 * s, g - 120 * s, 56 * s),
                         (tree - trunk - 34 * s, g - 170 * s, 46 * s), (tree + trunk - 10 * s, g - 214 * s, 44 * s)]
            let zip = ((tree - trunk - 30 * s, g - 168 * s), (c.w * 14 / 100, g - 216 * s))
            let lights = [((tree - trunk - 40 * s, g - 70 * s), (c.w * 40 / 100, g - 60 * s), 16 * s),
                          ((tree + trunk + 46 * s, g - 120 * s), (c.w - 2 * s, g - 96 * s), 14 * s),
                          ((c.w * 40 / 100, g - 60 * s), (c.w * 10 / 100 + 42 * s, g - 120 * s), 14 * s)]
            return (tree, trunk, g - 226 * s, (c.w * 10 / 100, 18 * s), decks, zip, lights)
        }
        let trunk = 15 * s
        let decks = [(tree - trunk - 26 * s, 17 * s, 30 * s), (tree + trunk - 4 * s, 12 * s, 32 * s)]
        let zip = ((tree - trunk - 24 * s, 16 * s), (c.w * 9 / 100 + 18 * s, 8 * s))
        let lights = [((tree - trunk - 26 * s, 18 * s), (c.w * 44 / 100, 14 * s), 6 * s),
                      ((tree + trunk + 28 * s, 13 * s), (c.w - 2 * s, 9 * s), 5 * s)]
        return (tree, trunk, 4 * s, (c.w * 9 / 100, 10 * s), decks, zip, lights)
    }

    /// A Lost Boys' hut on a platform: a patchwork box of planks in a bright colour, a little window and a pointed
    /// roof, with the platform's plank edge under it.
    private static func hkHut(_ c: PixelCanvas, x: Int, y: Int, w: Int, s: Int, col: Px, roof: Px) {
        c.rect(x, y, w, 2 * s, C(0x7A5232)); c.rect(x, y, w, s, C(0xA8784A))
        for px in stride(from: x + 2 * s, to: x + w, by: 8 * s) { c.rect(px, y + 2 * s, s, 3 * s, C(0x5A3A22)) }
        let hw = w * 3 / 5, hx = x + (w - hw) / 2, hh = max(5 * s, w / 3)
        c.rect(hx, y - hh, hw, hh, col)
        c.rect(hx + hw / 2, y - hh, hw / 2, hh / 2, col.alpha(0.75))
        c.rect(hx + 2 * s, y - hh + 2 * s, 3 * s, 3 * s, C(0x2A1A10)); c.rect(hx + 2 * s, y - hh + 2 * s, 3 * s, s, C(0xFFD87A))
        for i in 0..<(hw / 2 + 2 * s) {
            let rw = max(s, hw + 4 * s - 2 * i)
            c.rect(hx - 2 * s + i, y - hh - i / 2 - s, rw, 1, roof)
            if rw <= s { break }
        }
    }

    /// The Lost Boys' Neverland in full colour: a teal-to-gold sky, soft island hills, a mossy cliff on the left with
    /// its waterfall pouring into a pool, and on the right the giant tree, its huge trunk and roots, its canopy
    /// overhead, and the boys' patchwork huts on plank platforms. Rope zip lines run off it and strings of fairy
    /// lights hang in loops. On the screen saver the giant tree climbs the whole height with more huts and ladders.
    static func neverland(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = hkNeverFrame(c, g)
        c.gradient(0, g, C(0x5ABED0), C(0xF6DC96), bands: 7)
        for i in 0..<(tall ? 8 : 4) {
            cloud(c, Int(noise(i + 3000) * Double(c.w)), Int(noise(i + 3010) * Double(tall ? g / 2 : 14 * s)), 4 * s,
                  seed: i + 30, top: C(0xFFF6E0), base: C(0xF0D8B0))
        }
        // The island's hills and forest.
        c.dunes(base: g - (tall ? 70 : 26) * s, amp: Double((tall ? 18 : 6) * s), freq: 0.02, phase: 1.1, bottom: g, C(0x7AB89A))
        c.dunes(base: g - (tall ? 40 : 16) * s, amp: Double((tall ? 10 : 4) * s), freq: 0.045, phase: 3.0, bottom: g, C(0x4E9A5E))
        // The cliff and its waterfall.
        let cw = f.fall.x + f.fall.w + (tall ? 40 : 26) * s
        for x in 0..<cw {
            let lip = f.cliff + Int(noise(x / max(1, 3 * s) + 3100) * 3) * s
            let edge = x > cw - 14 * s ? (x - (cw - 14 * s)) * (g - f.cliff) / max(1, 14 * s) : 0
            let top = lip + edge
            if top < g {
                c.rect(x, top, 1, g - top, (x / max(1, 4 * s)) % 3 == 0 ? C(0x5A6A66) : C(0x6A7C74))
                c.rect(x, top, 1, 2 * s, C(0x5AA84A))
            }
        }
        for i in 0..<(tall ? 26 : 10) {
            let mx = Int(noise(i + 3200) * Double(cw)), my = f.cliff + Int(noise(i + 3210) * Double(g - f.cliff))
            c.ellipse(mx, my, 3 * s, s, C(0x4A8A3E))
        }
        c.rect(f.fall.x, f.cliff, f.fall.w, g - f.cliff, C(0x9ADCE4))
        for x in stride(from: f.fall.x, to: f.fall.x + f.fall.w, by: 2 * s) { c.rect(x, f.cliff, s, g - f.cliff, C(0xD4F4F4)) }
        c.ellipse(f.fall.x + f.fall.w / 2, g - s, f.fall.w + 10 * s, 3 * s, C(0x6AC8D4))
        c.ellipse(f.fall.x + f.fall.w / 2, g - 2 * s, f.fall.w, 2 * s, C(0xF0FFFF, 0.8))
        // The giant tree: roots, the trunk and its grooves, the canopy.
        let t = f.tree, tw = f.trunk
        for i in 0..<5 {
            let dir = i < 2 ? -1.0 : (i > 2 ? 1.0 : 0.3)
            let len = Double((tall ? 50 : 26) * s) * (0.6 + noise(i + 3300) * 0.6)
            let rx = Double(t + (i - 2) * tw / 2)
            hkLine(c, rx, Double(g - (tall ? 30 : 12) * s), rx + dir * len, Double(g), C(0x5A3C24), Double((tall ? 4 : 2) * s))
        }
        c.rect(t - tw, 0, tw * 2, g, C(0x6A4A2E))
        c.rect(t - tw, 0, 3 * s, g, C(0x8A6440)); c.rect(t + tw - 4 * s, 0, 4 * s, g, C(0x4A3220))
        for i in 0..<(tall ? 14 : 6) {
            let gx = t - tw + 5 * s + Int(noise(i + 3400) * Double(tw * 2 - 10 * s))
            var y = 0
            while y < g {
                c.rect(gx + Int(sin(Double(y) * 0.08 + Double(i)) * 1.5), y, s, 1, C(0x523822))
                y += 1
            }
        }
        // Ladders up the trunk and the canopy.
        c.rect(t - 4 * s, f.decks[0].y, s, g - f.decks[0].y, C(0xA8784A)); c.rect(t + 2 * s, f.decks[0].y, s, g - f.decks[0].y, C(0xA8784A))
        for y in stride(from: f.decks[0].y + 2 * s, to: g, by: 4 * s) { c.rect(t - 4 * s, y, 7 * s, s, C(0xA8784A)) }
        let crown = tall ? -14 * s : -6 * s
        for i in 0..<(tall ? 34 : 9) {
            let lx = t + Int((noise(i + 3500) - 0.5) * Double((tall ? 300 : 170) * s))
            let ly = crown + Int(noise(i + 3510) * Double((tall ? 100 : 10) * s))
            let r = (tall ? 30 : 16) * s + Int(noise(i + 3520) * 10) * s
            c.ellipse(lx, ly, r, r * 2 / 3, i % 2 == 0 ? C(0x3E8A3A) : C(0x5AA848))
            c.ellipse(lx - r / 4, ly - r / 4, r / 2, r / 4, C(0x7AC85A))
        }
        if tall {
            // Branches reaching out to the higher huts.
            for d in f.decks {
                let from = Double(d.x < t ? t - tw : t + tw), to = Double(d.x < t ? d.x : d.x + d.w)
                hkLine(c, from, Double(d.y + 8 * s), to, Double(d.y + 2 * s), C(0x5A3C24), Double(3 * s))
            }
        }
        // The huts.
        let cols: [(UInt32, UInt32)] = [(0xC84A2A, 0x3A6AB8), (0xE8B83A, 0xC84A2A), (0x3A6AB8, 0xE8B83A), (0x8A4AB8, 0x5AA848)]
        for (i, d) in f.decks.enumerated() {
            hkHut(c, x: d.x, y: d.y, w: d.w, s: s, col: C(cols[i % 4].0), roof: C(cols[i % 4].1))
        }
        // The zip line, and the fairy lights on their strings.
        hkRope(c, f.zip.0, f.zip.1, sag: (tall ? 10 : 4) * s, C(0x3A2818))
        for l in f.lights {
            let pts = hkRope(c, l.0, l.1, sag: l.2, C(0x3A2818, 0.8), n: 20)
            for (i, p) in pts.enumerated() where i % 2 == 0 {
                c.rect(Int(p.0), Int(p.1) + s, s, s, C(hkFairy[(i / 2) % hkFairy.count]))
            }
        }
        for l in f.lights where l.1.0 < c.w - 4 * s && l.1.1 > (tall ? g - 80 * s : 12 * s) {
            c.rect(l.1.0, l.1.1, s * 2, g - l.1.1, C(0x7A5232))   // a pole holding the far end
        }
        for l in f.lights where tall && l.1.0 < c.w - 4 * s && l.1.1 <= g - 80 * s {
            c.rect(l.1.0 - 2 * s, l.1.1 - s, 3 * s, 2 * s, C(0x5A3A22))   // a peg in the cliff holding the far end
        }
        // The grass, with flowers.
        c.ground(g, C(0x4A8A3A), edge: C(0x7AC858), speck: C(0x3E7A30), seed: 91)
        for i in 0..<24 {
            let fx = Int(noise(i + 3600) * Double(c.w)), fy = g + 2 + Int(noise(i + 3610) * Double(max(1, c.h - g - 3)))
            c.rect(fx, fy, s, s, C(hkFairy[i % 3]))
        }
    }

    /// What moves in Neverland: the waterfall pouring, the fairy lights twinkling, a Lost Boy whizzing down the zip
    /// line now and then, and a fairy's spark darting about the tree.
    static func neverlandLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), f = hkNeverFrame(c, g)
        // The water.
        let h = Double(g - f.cliff)
        for i in 0..<(f.fall.w / s * 3) {
            let x = f.fall.x + Int(noise(i + 3700) * Double(f.fall.w))
            let y = (noise(i + 3710) * h + t * (40 + noise(i + 3720) * 30)).truncatingRemainder(dividingBy: h)
            c.rect(x, f.cliff + Int(y), s, 4 * s, C(0xFFFFFF, 0.7))
        }
        for i in 0..<5 {
            let k = (t * 0.8 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
            let x = f.fall.x + f.fall.w / 2 + Int((noise(i + 3730) - 0.5) * Double(f.fall.w * 2))
            c.rect(x, g - 2 * s - Int(k * Double(5 * s)), s, s, C(0xFFFFFF, 1 - k))
        }
        // The fairy lights twinkling.
        for (li, l) in f.lights.enumerated() {
            let pts = hkRope(c, l.0, l.1, sag: l.2, C(0, 0), n: 20, draw: false)
            for (i, p) in pts.enumerated() where i % 2 == 0 && noise(i + li * 50 + Int(t * 3)) > 0.7 {
                let col = C(hkFairy[(i / 2) % hkFairy.count])
                c.glowLine(p.0, p.1 + Double(s), p.0 + 0.1, p.1 + Double(s), core: col, glow: col.alpha(0.5),
                           coreR: Double(s) * 0.7, glowR: Double(s) * 2.2)
            }
        }
        // A Lost Boy down the zip line: a little figure hanging from a handle, every 7 seconds.
        let ride = t.truncatingRemainder(dividingBy: 7)
        if ride < 2.2 {
            let k = ride / 2.2
            let pts = hkRope(c, f.zip.0, f.zip.1, sag: (tall ? 10 : 4) * s, C(0, 0), draw: false)
            let fi = min(Double(pts.count - 1), k * Double(pts.count - 1))
            let p = pts[Int(fi)]
            let x = Int(p.0), y = Int(p.1)
            c.rect(x - s, y, 3 * s, s, C(0x2A1A10))                         // the handle
            c.rect(x - s, y + s, s, 3 * s, C(0xE8A86A)); c.rect(x + s, y + s, s, 3 * s, C(0xE8A86A))
            c.rect(x - s, y + 3 * s, 3 * s, 4 * s, C(0x5AA848))             // the tunic
            c.rect(x - s, y + 2 * s, 3 * s, 2 * s, C(0xE8A86A))             // the face
            c.rect(x - s, y + s, 3 * s, s, C(0xC84A2A))                     // the cap
            c.rect(x - s, y + 7 * s, s, 2 * s, C(0x5A3A22)); c.rect(x + s, y + 7 * s, s, 2 * s, C(0x5A3A22))
        }
        // A fairy's spark round the tree.
        let fx = Double(f.tree) + sin(t * 1.3) * Double((tall ? 90 : 60) * s) + sin(t * 3.1) * Double(8 * s)
        let fy = Double(tall ? g / 2 : 20 * s) + sin(t * 2.1) * Double((tall ? 60 : 10) * s)
        for k in 1...5 {
            let back = Double(k) * 0.06
            let tx = Double(f.tree) + sin((t - back) * 1.3) * Double((tall ? 90 : 60) * s) + sin((t - back) * 3.1) * Double(8 * s)
            let ty = Double(tall ? g / 2 : 20 * s) + sin((t - back) * 2.1) * Double((tall ? 60 : 10) * s)
            c.rect(Int(tx), Int(ty), s, s, C(0xFFE88A, 0.6 - Double(k) * 0.1))
        }
        c.glowLine(fx, fy, fx + 0.1, fy, core: C(0xFFFFF0), glow: C(0xFFD84A), coreR: Double(s) * 0.9, glowR: Double(s) * 3)
    }
}

// MARK: - Pirate Town

extension Scenes {
    /// Where things stand in Pirate Town: the horizon, the crocodile tower's middle, its plinth top, its body's top,
    /// half-width and head size, and the clock's centre and radius.
    private static func hkTownFrame(_ c: PixelCanvas, _ g: Int) -> (sea: Int, cx: Int, plinth: Int, top: Int, hw: Int,
                                                                     head: Int, clock: (x: Int, y: Int, r: Int)) {
        let s = unit(g), tall = isTall(c)
        let cx = c.w * 44 / 100
        if tall { return (g - 70 * s, cx, g - 26 * s, g - 206 * s, 32 * s, 32 * s, (cx, g - 150 * s, 20 * s)) }
        return (g - 28 * s, cx, g - 8 * s, 13 * s, 13 * s, 8 * s, (cx, 21 * s, 6 * s))
    }

    /// A ship riding at anchor: a dark hull with a gold stripe, two masts with square cream sails, all leaning by
    /// `tilt` (pixels across per pixel up) as it rocks, its waterline on `base`; `k` is its size.
    private static func hkShip(_ c: PixelCanvas, x: Int, base: Int, k: Int, tilt: Double, hull: Px) {
        let hullH = 4 * k, len = 26 * k
        for r in 0..<hullH {
            let y = base - r
            let inset = (hullH - r) * k / 2
            let lean = Int(tilt * Double(r))
            c.rect(x + inset + lean - (r > hullH - 2 ? 2 * k : 0), y, len - inset * 2 + (r > hullH - 2 ? 4 * k : 0), 1, hull)
        }
        c.rect(x + Int(tilt * Double(hullH)), base - hullH + k, len, max(1, k / 2), C(0xD8A83A))
        for (m, h) in [(x + 8 * k, 18 * k), (x + 18 * k, 14 * k)] {
            let foot = Double(base - hullH)
            let topX = Double(m) + tilt * Double(h), topY = foot - Double(h)
            hkLine(c, Double(m), foot, topX, topY, C(0x3A2818), Double(k) * 0.5)
            for sail in 0..<2 {
                let sy = Int(topY) + 2 * k + sail * (h / 2 - k)
                let sh = h / 2 - 3 * k
                for r in 0..<sh {
                    let lean = Int(tilt * Double(base - hullH - (sy + r)))
                    let w = 8 * k + (sail == 1 ? 2 * k : 0)
                    c.rect(m + lean - w / 2, sy + r, w, 1, r == 0 ? C(0xC8B890) : C(0xF0E6CC))
                }
            }
        }
    }

    /// A row of crooked Pirate Town houses from `x0` to `x1`: painted timber fronts in faded bright colours, each one
    /// a different height, with an overhanging upper storey, shuttered windows and a roof.
    private static func hkHouses(_ c: PixelCanvas, x0: Int, x1: Int, g: Int, maxH: Int, s: Int, seed: Int) {
        let fronts: [UInt32] = [0xC88A3A, 0x3A7A7A, 0xA83A2A, 0xD8C49A, 0x5A6A9A]
        var x = x0
        var k = 0
        while x < x1 {
            let w = min(x1 - x, (26 + Int(noise(seed + k * 3) * 16)) * s)
            let h = maxH * 3 / 5 + Int(noise(seed + k * 3 + 1) * Double(maxH * 2 / 5))
            let col = C(fronts[(k + seed) % fronts.count])
            let top = g - h
            c.rect(x, top, w, h, col)
            c.rect(x, top, s, h, col.alpha(0.6))
            for pl in stride(from: top + 3 * s, to: g, by: 3 * s) { c.rect(x, pl, w, 1, C(0x2A1A10, 0.18)) }
            let over = top + h / 2
            c.rect(x - s, over, w + 2 * s, 2 * s, C(0x4A3020))
            for wy in [top + 4 * s, over + 5 * s] where wy + 5 * s < g - 8 * s {
                for wx in stride(from: x + 4 * s, to: x + w - 6 * s, by: 10 * s) {
                    c.rect(wx, wy, 4 * s, 5 * s, C(0x2A1A10)); c.rect(wx + s, wy + s, 2 * s, 3 * s, C(0xF4C860, 0.7))
                    c.rect(wx - 2 * s, wy, 2 * s, 5 * s, C(0x4A6A3A)); c.rect(wx + 4 * s, wy, 2 * s, 5 * s, C(0x4A6A3A))
                }
            }
            // The roof: a dark peak or a slant.
            let roof = C(0x5A3A2A)
            for i in 0..<(w / 2 + s) {
                let lean = k % 2 == 0 ? i / 2 : i / 3
                c.rect(x - s + i, top - lean - s, max(1, w + 2 * s - 2 * i), 1, roof)
                if w + 2 * s - 2 * i <= 1 { break }
            }
            c.rect(x + w / 2 - 2 * s, g - 9 * s, 5 * s, 9 * s, C(0x3A2416))   // the door
            x += w + s; k += 1
        }
    }

    /// Pirate Town on the waterfront: a warm afternoon sky over the harbour, crooked painted houses crowding both
    /// sides of the quay, and in the square the stuffed crocodile stood on its tail as the clock tower, jaws gaping
    /// at the sky and the clock set in its belly. Barrels, rope and a lamp post on the planks. Ships and gulls are in
    /// the moving layer. On the screen saver the crocodile towers over the dock, the town stacked up behind.
    static func pirateTown(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = hkTownFrame(c, g)
        c.gradient(0, f.sea, C(0x7AB8DA), C(0xF6DCA8), bands: 6)
        c.circle(c.w * 80 / 100, f.sea - (tall ? 50 : 12) * s, (tall ? 14 : 6) * s, C(0xFFF0C0, 0.8))
        // The sea.
        c.gradient(f.sea, g, C(0x4A9AA8), C(0x2A6A7A), bands: 4)
        c.rect(0, f.sea, c.w, s, C(0xC8E4E0))
        for i in 0..<(tall ? 60 : 24) {
            let wx = Int(noise(i + 4000) * Double(c.w)), wy = f.sea + 2 * s + Int(noise(i + 4010) * Double(g - f.sea - 2 * s))
            c.rect(wx, wy, (3 + Int(noise(i + 4020) * 4)) * s, s, C(0xA8E0E0, 0.6))
        }
        if tall {
            // The town climbing the hill behind the harbour.
            c.dunes(base: f.sea - 30 * s, amp: Double(14 * s), freq: 0.02, phase: 0.4, bottom: f.sea, C(0x8AA86A))
            for i in 0..<24 {
                let hx = Int(noise(i + 4100) * Double(c.w)), hy = f.sea - Int(noise(i + 4110) * 34) * s
                let col = [C(0xC88A3A), C(0xD8C49A), C(0xA83A2A), C(0x5A6A9A)][i % 4]
                c.rect(hx, hy - 6 * s, 9 * s, 7 * s, col); c.rect(hx - s, hy - 8 * s, 11 * s, 2 * s, C(0x5A3A2A))
                c.rect(hx + 3 * s, hy - 4 * s, 2 * s, 2 * s, C(0x2A1A10))
            }
        }
        // The houses either side.
        let maxH = (tall ? 150 : 50) * s
        hkHouses(c, x0: 0, x1: c.w * 24 / 100, g: g, maxH: maxH, s: s, seed: 1)
        hkHouses(c, x0: c.w * 70 / 100, x1: c.w, g: g, maxH: maxH, s: s, seed: 4)
        // The crocodile clock tower: the plinth, the tail curled round it, the body, belly scutes, arms, head.
        let plinthW = f.hw * 2 + 10 * s
        c.rect(f.cx - plinthW / 2, f.plinth, plinthW, g - f.plinth, C(0x6A4A30))
        c.rect(f.cx - plinthW / 2, f.plinth, plinthW, s, C(0xA8784A))
        let green = C(0x4A7A3A), dark = C(0x2E5A2A), belly = C(0xB8C07A)
        for i in 0..<(f.hw * 3) {   // the tail along the plinth
            let tx = f.cx + f.hw / 2 + i
            let th = max(s, (f.hw * 3 - i) / 6)
            c.rect(tx, f.plinth - th, 1, th, green)
            if i % (3 * s) == 0 { c.rect(tx, f.plinth - th - s, s, s, dark) }
        }
        let bodyH = f.plinth - f.top
        for y in f.top..<f.plinth {
            let k = Double(y - f.top) / Double(max(1, bodyH))
            let hw = Int(Double(f.hw) * (0.7 + 0.3 * sin(k * .pi * 0.9 + 0.2)))
            c.rect(f.cx - hw, y, hw * 2, 1, green)
            c.rect(f.cx - hw, y, s, 1, dark); c.rect(f.cx + hw - s, y, s, 1, dark)
            let bw = hw * 3 / 5
            c.rect(f.cx - bw, y, bw * 2, 1, (y - f.top) % (3 * s) == 0 ? C(0x8A9A5A) : belly)
            if (y / s) % 4 == 0 {   // the ridged back showing at the edges
                c.rect(f.cx - hw - s, y, s, s, dark); c.rect(f.cx + hw, y, s, s, dark)
            }
        }
        // The hind feet on the plinth and the little arms either side of the clock.
        c.rect(f.cx - f.hw - 2 * s, f.plinth - 3 * s, 6 * s, 3 * s, green); c.rect(f.cx + f.hw - 4 * s, f.plinth - 3 * s, 6 * s, 3 * s, green)
        let ck = f.clock
        for side in [-1, 1] {
            let ax = Double(f.cx + side * (f.hw - s)), ay = Double(ck.y - ck.r / 2)
            hkLine(c, ax, ay, ax + Double(side * 4 * s), ay + Double(ck.r), green, Double(s) * 1.2)
            c.rect(Int(ax) + side * 4 * s - s, Int(ay) + ck.r, 3 * s, s, C(0xF0EAD0))
        }
        // The head: thrown back, the long jaws gaping at the sky with the pink mouth between them, teeth along
        // both, nostrils on the snout's tip and an eye bulging either side.
        let hx = f.cx, hy = f.top
        let jawLen = f.head * 3 / 2
        let white = C(0xF4F0E0)
        c.ellipse(hx - f.hw / 6, hy - jawLen / 3, f.hw / 2, jawLen / 3, C(0xC85A64))
        for i in 0..<jawLen {   // the upper jaw, up and to the right
            let k = Double(i) / Double(jawLen)
            let w = max(2 * s, Int(Double(f.hw) * (0.95 - 0.5 * k)))
            let x = hx - f.hw / 5 + Int(Double(i) * 0.45)
            c.rect(x, hy - i, w, 1, green); c.rect(x + w - s, hy - i, s, 1, dark)
            if i % (2 * s) == 0 && i > s { c.rect(x - s, hy - i, s, s, white) }
        }
        let tip = (x: hx - f.hw / 5 + Int(Double(jawLen) * 0.45), y: hy - jawLen)
        c.rect(tip.x + s, tip.y - s, 2 * s, s, green); c.rect(tip.x + s, tip.y, s, s, C(0x1A2A14))
        let lowLen = jawLen * 2 / 3
        for i in 0..<lowLen {   // the lower jaw, dropped back up and to the left
            let k = Double(i) / Double(lowLen)
            let w = max(2 * s, Int(Double(f.hw) * (0.75 - 0.4 * k)))
            let x = hx - f.hw / 5 - w - Int(Double(i) * 0.9)
            c.rect(x, hy - i, w, 1, green); c.rect(x, hy - i, s, 1, dark)
            if i % (2 * s) == 0 && i > s { c.rect(x + w, hy - i, s, s, white) }
        }
        for side in [-1, 1] {   // the eyes
            let ex = hx + side * (f.hw * 3 / 4)
            c.ellipse(ex, hy + s, max(2 * s, f.hw / 4), max(s, f.hw / 6), green)
            c.rect(ex - s, hy, 2 * s, max(s, f.hw / 8), C(0xF0D04A)); c.rect(ex, hy, s, max(s, f.hw / 8), C(0x1A1A10))
        }
        // The clock in its belly: brass rim, cream face, hour ticks (the hands are in the moving layer).
        c.circle(ck.x, ck.y, ck.r + 2 * s, C(0x8A6A2A)); c.circle(ck.x, ck.y, ck.r + s, C(0xD8A83A))
        c.circle(ck.x, ck.y, ck.r, C(0xF4ECD0))
        for h in 0..<12 {
            let a = Double(h) / 12 * 2 * .pi
            let rr = Double(ck.r - s)
            c.rect(ck.x + Int(sin(a) * rr), ck.y - Int(cos(a) * rr), s, s, C(0x2A2018))
        }
        // The quay: planks, barrels, a coil of rope, a lamp post.
        c.ground(g, C(0x7A5A3A), edge: C(0xB08A5A), speck: C(0x6A4A2E), seed: 41)
        for y in stride(from: g + 3, to: c.h, by: 3) { c.rect(0, y, c.w, 1, C(0x5A402A)) }
        for bx in [c.w * 26 / 100, c.w * 28 / 100, c.w * 66 / 100] {
            c.rect(bx, g - 8 * s, 7 * s, 8 * s, C(0x8A5A2E)); c.rect(bx, g - 7 * s, 7 * s, s, C(0x3A3A3A))
            c.rect(bx, g - 2 * s, 7 * s, s, C(0x3A3A3A)); c.rect(bx + s, g - 8 * s, 5 * s, s, C(0xA87A44))
        }
        c.ellipse(c.w * 63 / 100, g - s, 5 * s, 2 * s, C(0xC8A870)); c.ellipse(c.w * 63 / 100, g - s, 2 * s, s, C(0x7A5A3A))
        let lp = c.w * 58 / 100, lpTop = g - (tall ? 70 : 34) * s
        c.rect(lp, lpTop, 2 * s, g - lpTop, C(0x2A2420)); c.rect(lp - 2 * s, lpTop - 5 * s, 6 * s, 5 * s, C(0x2A2420))
        c.rect(lp - s, lpTop - 4 * s, 4 * s, 3 * s, C(0xF8D878))
    }

    /// What moves in Pirate Town: the clock's hands ticking round (the second hand jumping once a second), two ships
    /// rocking at anchor in the harbour, gulls wheeling over the roofs, and the sun glinting off the water.
    static func pirateTownLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), f = hkTownFrame(c, g)
        // The ships, out in the harbour behind the quay.
        let k = tall ? 3 * s : s
        let ships: [(x: Int, ph: Double, hull: UInt32)] = [(c.w * 27 / 100, 0, 0x3A2418), (c.w * 55 / 100, 1.7, 0x4A1A1A)]
        for sh in ships {
            let tilt = sin(t * 1.1 + sh.ph) * 0.12
            let bob = Int((sin(t * 1.4 + sh.ph) * Double(s)).rounded())
            hkShip(c, x: sh.x, base: g - (tall ? 6 : 3) * s + bob, k: k, tilt: tilt, hull: C(sh.hull))
        }
        // The water glinting.
        for i in 0..<(tall ? 12 : 6) {
            let on = noise(i * 13 + Int(t * 2)) > 0.5
            if on {
                let wx = Int(noise(i + 4200) * Double(c.w)), wy = f.sea + 2 * s + Int(noise(i + 4210) * Double(g - f.sea - 4 * s))
                c.rect(wx, wy, 2 * s, s, C(0xFFFFF0, 0.9))
            }
        }
        // The clock's hands.
        let ck = f.clock
        let sec = floor(t).truncatingRemainder(dividingBy: 60)
        let minute = (t / 60 + 22).truncatingRemainder(dividingBy: 60)
        let hour = 10 + minute / 60
        let hands: [(Double, Double, Double, Px)] = [
            (hour / 12, 0.5, 0.8, C(0x1A1410)), (minute / 60, 0.8, 0.6, C(0x1A1410)), (sec / 60, 0.9, 0.4, C(0xB02A1A)),
        ]
        for h in hands {
            let a = h.0 * 2 * .pi
            let len = Double(ck.r) * h.1
            let ex = Double(ck.x) + 0.5 + sin(a) * len, ey = Double(ck.y) + 0.5 - cos(a) * len
            c.glowLine(Double(ck.x) + 0.5, Double(ck.y) + 0.5, ex, ey, core: h.3, glow: C(0, 0),
                       coreR: Double(s) * h.2, glowR: Double(s) * h.2 + 0.01)
        }
        c.rect(ck.x, ck.y, s, s, C(0xD8A83A))
        // The gulls.
        for i in 0..<(tall ? 6 : 4) {
            let span = Double(c.w + 60)
            let speed = 14 + noise(i + 4300) * 12
            let x = Int((noise(i + 4310) * span + t * speed).truncatingRemainder(dividingBy: span)) - 30
            let y = Int(noise(i + 4320) * Double(tall ? g / 2 : 14 * s)) + 2 * s + Int(sin(t * 0.9 + Double(i)) * Double(2 * s))
            let flap = Int(t * 6 + Double(i)) % 2 == 0
            let wy = flap ? -s : s
            c.rect(x, y, s, s, C(0xF8F8F4))
            c.rect(x - s, y + (flap ? -s : 0), s, s, C(0xF8F8F4)); c.rect(x + s, y + (flap ? -s : 0), s, s, C(0xF8F8F4))
            c.rect(x - 2 * s, y + wy, s, s, C(0x3A3A3A)); c.rect(x + 2 * s, y + wy, s, s, C(0x3A3A3A))
        }
    }
}

// MARK: - The Jolly Roger

extension Scenes {
    /// One mast: its x, its top row, and its yards' rows, sails' heights and sails' half-widths, top sail first.
    private typealias HkMast = (x: Int, top: Int, yards: [Int], heights: [Int], halves: [Int])

    /// Captain Clawd's galleon at the quay: the horizon, the waterline and the main deck, bow and stern, the
    /// forecastle's back edge and top, the stern castle's front edge and top, the three masts (fore, main, mizzen),
    /// the bowsprit's tip, where the flag's staff is and the flag's pixel size, and where the lanterns hang.
    private typealias HkGalleon = (sea: Int, water: Int, deck: Int, x0: Int, x1: Int, fore: (x: Int, top: Int),
                                   castle: (x: Int, top: Int), masts: [HkMast], sprit: (x: Int, y: Int),
                                   flag: (x: Int, y: Int, k: Int), lanterns: [(Int, Int)])

    /// Where the galleon lies. In the window's strip the fore- and mainmast run off the top and the flag flies from
    /// a staff on the stern; on the screen saver every sail shows and the flag flies from the maintop.
    private static func hkGalleonFrame(_ c: PixelCanvas, _ g: Int) -> HkGalleon {
        let s = unit(g), tall = isTall(c)
        let x0 = c.w * 9 / 100, x1 = c.w * 90 / 100, span = x1 - x0
        let water = g - (tall ? 12 : 3) * s
        let deck = water - (tall ? 56 : 15) * s
        let fore = (x: x0 + span * 16 / 100, top: deck - (tall ? 12 : 4) * s)
        let castle = (x: x0 + span * 74 / 100, top: deck - (tall ? 34 : 10) * s)
        let cap = span * 11 / 100   // the widest half a sail may have, so neighbours don't overlap
        let mainYards = tall ? [g - 250 * s, g - 196 * s, g - 142 * s] : [g - 62 * s, g - 49 * s, g - 34 * s]
        let mainH = tall ? [34, 44, 50] : [9, 11, 12], mainHalf = tall ? [34, 44, 52] : [18, 24, 30]
        func mast(_ x: Int, top: Int, yards: [Int], heights: [Int], halves: [Int], scale: Double) -> HkMast {
            (x, max(0, top), yards, heights.map { $0 * s }, halves.map { min(cap, Int(Double($0 * s) * scale)) })
        }
        let foreDrop = (tall ? 10 : 2) * s, mizDrop = (tall ? 16 : 6) * s
        let foremast = mast(x0 + span * 28 / 100, top: mainYards[0] + foreDrop - (tall ? 18 : 8) * s,
                            yards: mainYards.map { $0 + foreDrop }, heights: mainH, halves: mainHalf, scale: 0.9)
        let mainmast = mast(x0 + span * 51 / 100, top: g - 286 * s, yards: mainYards, heights: mainH, halves: mainHalf,
                            scale: 1)
        let mizzen = mast(x0 + span * 84 / 100, top: mainYards[0] + mizDrop - (tall ? 16 : 6) * s,
                          yards: mainYards.prefix(2).map { $0 + mizDrop }, heights: Array(mainH.prefix(2)),
                          halves: Array(mainHalf.prefix(2)), scale: 0.75)
        let sprit = (x: x0 - span * 9 / 100, y: fore.top - (tall ? 34 : 10) * s)
        let flag = tall ? (x: mainmast.x, y: mainmast.top + 2 * s, k: 2 * s)
                        : (x: x1 - 2 * s, y: castle.top - 20 * s, k: s)
        let lift = (tall ? 16 : 5) * s
        let lanterns = [(x1 - 3 * s, castle.top - lift), (castle.x + (tall ? 8 : 3) * s, castle.top - lift),
                        (x0 + span * 4 / 100, fore.top - lift)]
        return (tall ? g - 120 * s : g - 34 * s, water, deck, x0, x1, fore, castle, [foremast, mainmast, mizzen], sprit,
                flag, lanterns)
    }

    /// The hull's top and bottom rows at column `x` (nil past the bow or the stern): the deck's sheer rising to both
    /// ends, the forecastle and the stern castle raised over it, the stem raking forward up from the waterline and
    /// the stern's counter overhanging the water.
    private static func hkHullSpan(_ f: HkGalleon, _ x: Int, s: Int, tall: Bool) -> (top: Int, bottom: Int)? {
        guard x >= f.x0 && x <= f.x1 else { return nil }
        let t = Double(x - f.x0) / Double(f.x1 - f.x0)
        let sheer = Double((tall ? 10 : 3) * s)
        let dip: Double = abs(t - 0.5) / 0.5
        var top = f.deck - Int(sheer * dip * dip)
        if x < f.fore.x { top = min(top, f.fore.top - Int(sheer * (1 - t / 0.16))) }
        if x >= f.castle.x { top = min(top, f.castle.top - Int(sheer * 0.6 * (t - 0.74) / 0.26)) }
        var bottom = f.water
        let hullH = Double(bottom - top)
        if t < 0.08 {
            let k: Double = 1 - t / 0.08
            bottom -= Int(hullH * pow(k, 1.5) * 0.85)
        }
        if t > 0.95 { bottom -= Int(hullH * 0.45 * (t - 0.95) / 0.05) }
        return (top, max(top + s, bottom))
    }

    /// A sail set and drawing: cream canvas bellied out by the wind, its sides bowed and its foot curved, the cloth
    /// panels running down it, warm sunset light on it and shadow in the belly, the bolt rope round the edge and a
    /// patch or two sewn on.
    private static func hkSail(_ c: PixelCanvas, m: Int, y: Int, half: Int, h: Int, s: Int, seed: Int) {
        let bow = Double(3 * s), sag = Double((h > 10 * s ? 4 : 2) * s)
        for r in 0..<(h + Int(sag)) {
            let q = Double(r) / Double(h)
            let hw = half - s + Int(sin(min(1, q) * .pi) * bow)
            for dx in -hw...hw {
                let u = Double(dx + hw) / Double(2 * hw)
                let foot = h + Int(sin(u * .pi) * sag)
                guard r < foot else { continue }
                let rim = abs(dx) == hw || r >= foot - s
                var col = q < 0.35 ? C(0xF6E8CC) : (q < 0.75 ? C(0xEAD4AC) : C(0xD8B88C))
                if (dx + hw) % (6 * s) == 0 { col = C(0xD0B48A) }
                c.rect(m + dx, y + r, 1, 1, rim ? C(0xA8845A) : col)
                if u > 0.6 && !rim { c.rect(m + dx, y + r, 1, 1, C(0xB8805A, (u - 0.6) * 0.8)) }
            }
        }
        if h > 10 * s {
            for p in 0..<2 {
                let px = m - half / 2 + Int(noise(seed + p) * Double(half)), py = y + h / 4 + p * h / 3
                c.rect(px, py, 6 * s, 4 * s, C(0xC8A87A))
                for k in 0..<3 { c.rect(px + k * 2 * s, py, s, s, C(0x8A6A48)); c.rect(px + k * 2 * s + s, py + 3 * s, s, s, C(0x8A6A48)) }
            }
        }
        // The yard it hangs from: tapered to the yardarms.
        c.rect(m - half - 3 * s, y - 2 * s, 2 * half + 6 * s, 2 * s, C(0x4A3020))
        c.rect(m - half + 4 * s, y - 2 * s, 2 * half - 8 * s, s, C(0x7A5232))
    }

    /// A filled triangle (the jibs).
    private static func hkTriangle(_ c: PixelCanvas, _ a: (Int, Int), _ b: (Int, Int), _ p: (Int, Int), _ col: Px) {
        let minX = min(a.0, b.0, p.0), maxX = max(a.0, b.0, p.0), minY = min(a.1, b.1, p.1), maxY = max(a.1, b.1, p.1)
        func side(_ u: (Int, Int), _ v: (Int, Int), _ x: Int, _ y: Int) -> Int { (v.0 - u.0) * (y - u.1) - (v.1 - u.1) * (x - u.0) }
        for y in minY...maxY {
            for x in minX...maxX {
                let d1 = side(a, b, x, y), d2 = side(b, p, x, y), d3 = side(p, a, x, y)
                let neg = d1 < 0 || d2 < 0 || d3 < 0, pos = d1 > 0 || d2 > 0 || d3 > 0
                if !(neg && pos) { c.px(x, y, col) }
            }
        }
    }

    /// The Jolly Roger moored at the quay at sunset, seen whole from the dock: a violet-to-orange sky with the sun
    /// going down into a purple sea, the galleon side-on with the bowsprit and its jibs out over the water, three
    /// masts with sail over patched sail, the shrouds and stays, the hull with its gold cap rail, scarlet strake and
    /// open gun ports with cannons in them, the raised forecastle and the tall stern castle with its row of lit
    /// windows and lanterns on its rail, its reflection in the water, and the planks of the quay underfoot with
    /// mooring posts, ropes out to the hull and the gangplank up to the deck. On the screen saver the masts climb to
    /// the topgallants and a second tier of gun ports shows (the flag flies in the moving layer).
    static func jollyRoger(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), tall = isTall(c), f = hkGalleonFrame(c, g)
        let gold = C(0xD8A83A), rope = C(0x2A1A14)
        c.gradient(0, f.sea, C(0x2E1C4A), C(0xF29A4A), bands: 8)
        let sunX = (f.masts[0].x + f.masts[1].x) / 2, sunY = f.sea - (tall ? 22 : 6) * s
        c.circle(sunX, sunY, (tall ? 26 : 12) * s, C(0xFFC87A, 0.25))
        c.circle(sunX, sunY, (tall ? 18 : 7) * s, C(0xFFD27A))
        for i in 0..<(tall ? 6 : 3) {
            let wx = Int(noise(i + 5000) * Double(c.w)), wy = sunY - Int(noise(i + 5010) * Double((tall ? 120 : 20) * s))
            wisp(c, wx, wy, (40 + Int(noise(i + 5020) * 50)) * s, C(0xF8B8A0, 0.5), s: s)
        }
        // The sea, the sun's path on it, and on the screen saver the far shore of Neverland.
        c.gradient(f.sea, g, C(0x5A3A6A), C(0x2A1E4A), bands: 4)
        if tall {
            c.dunes(base: f.sea - 4 * s, amp: Double(6 * s), freq: 0.03, phase: 2.2, bottom: f.sea, C(0x3A2A4A))
            c.rect(0, f.sea, c.w, s, C(0xF8B880, 0.6))
        }
        c.rect(sunX - (tall ? 22 : 8) * s, f.sea, (tall ? 44 : 16) * s, s, C(0xFFC87A, 0.8))
        for i in 0..<(tall ? 24 : 10) {
            let wx = sunX + Int((noise(i + 5100) - 0.5) * Double((tall ? 70 : 30) * s))
            let wy = f.sea + 2 * s + Int(noise(i + 5110) * Double(g - f.sea - 3 * s))
            c.rect(wx, wy, (2 + Int(noise(i + 5120) * 4)) * s, s, C(0xF8A85A, 0.6))
        }
        // The stays from mast to mast, behind the sails: the backstay to the stern, the forestay out to the bowsprit.
        let fm = f.masts[0], main = f.masts[1], miz = f.masts[2]
        let foreHead = (x: Double(fm.x), y: Double(fm.yards[0] - 2 * s))
        hkLine(c, foreHead.x, foreHead.y, Double(f.sprit.x), Double(f.sprit.y), rope, 0.5)
        hkLine(c, Double(main.x), Double(main.yards[0] - 2 * s), Double(fm.x), Double(fm.yards[2] + 2 * s), rope, 0.5)
        hkLine(c, Double(miz.x), Double(miz.yards[0] - 2 * s), Double(main.x), Double(main.yards[2] + 2 * s), rope, 0.5)
        hkLine(c, Double(miz.x), Double(miz.top), Double(f.x1), Double(f.castle.top - (tall ? 6 : 2) * s), rope, 0.5)
        // The bowsprit, and the jibs set on the forestay: each one's luff up the stay, its foot down to the bow.
        let bowTop = (f.x0 + 2 * s, f.fore.top - (tall ? 6 : 2) * s)
        hkLine(c, Double(bowTop.0), Double(bowTop.1), Double(f.sprit.x), Double(f.sprit.y), C(0x5A3A22), Double(s) * (tall ? 1.6 : 0.8))
        func onStay(_ u: Double) -> (Int, Int) {
            (Int(Double(f.sprit.x) + (foreHead.x - Double(f.sprit.x)) * u), Int(Double(f.sprit.y) + (foreHead.y - Double(f.sprit.y)) * u))
        }
        for (tackU, headU) in (tall ? [(0.04, 0.5), (0.3, 0.72)] : [(0.06, 0.55)]) {
            let tack = onStay(tackU), head = onStay(headU)
            let clew = (head.0 + (tall ? 4 : 1) * s, bowTop.1 - (tall ? 8 : 2) * s)
            hkTriangle(c, tack, head, clew, C(0xEAD4AC))
            hkLine(c, Double(head.0), Double(head.1), Double(clew.0), Double(clew.1), C(0xA8845A), 0.5)
            hkLine(c, Double(tack.0), Double(tack.1), Double(clew.0), Double(clew.1), C(0xA8845A), 0.5)
            hkLine(c, Double(tack.0), Double(tack.1), Double(head.0), Double(head.1), C(0xA8845A), 0.5)
        }
        // The masts with their yards and sails, and fighting tops on the screen saver.
        let mw = (tall ? 7 : 3) * s
        for (mi, m) in f.masts.enumerated() {
            c.rect(m.x - mw / 2, m.top, mw, f.deck - m.top, C(0x5A3A22))
            c.rect(m.x - mw / 2 + s, m.top, s, f.deck - m.top, C(0x8A5E36))
            for by in stride(from: m.top + 6 * s, to: f.deck, by: (tall ? 24 : 12) * s) { c.rect(m.x - mw / 2, by, mw, s, C(0x2A1A10)) }
            for (yi, y) in m.yards.enumerated() {
                hkSail(c, m: m.x, y: y + 2 * s, half: m.halves[yi], h: m.heights[yi], s: s, seed: mi * 10 + yi + 5200)
            }
            if tall {
                for y in m.yards.dropFirst() {
                    c.rect(m.x - 9 * s, y - 8 * s, 18 * s, 3 * s, C(0x4A3020)); c.rect(m.x - 9 * s, y - 8 * s, 18 * s, s, gold)
                }
            }
        }
        // The shrouds: rope ladders from below each mast's lowest yard down to the rail either side.
        for m in f.masts {
            let top = m.yards[m.yards.count - 1] - s
            let foot = m.x >= f.castle.x ? f.castle.top : f.deck - (tall ? 4 : 1) * s
            let spread = (foot - top) * 3 / 10
            for side in [-1, 1] {
                let feet = (0..<3).map { m.x + side * (spread + $0 * (tall ? 5 : 3) * s) }
                for x in feet { hkLine(c, Double(m.x), Double(top), Double(x), Double(foot), rope, 0.5) }
                for y in stride(from: top + 6 * s, to: foot - s, by: (tall ? 4 : 3) * s) {
                    let k = Double(y - top) / Double(foot - top)
                    let a = m.x + Int(Double(feet[0] - m.x) * k), b = m.x + Int(Double(feet[2] - m.x) * k)
                    c.rect(min(a, b), y, abs(b - a) + 1, 1, C(0x3A2A1E, 0.85))
                }
            }
        }
        // The flag's staff on the stern (in the strip) and the lanterns' posts on the rails.
        if !tall { c.rect(f.flag.x, f.flag.y, s, f.castle.top - f.flag.y, C(0x4A3020)) }
        for l in f.lanterns {
            let base = l.0 < f.castle.x ? f.fore.top : f.castle.top
            c.rect(l.0, l.1, s, base - l.1, C(0x2A1A14))
        }
        hkHull(c, g, f)
        // The quay: planks running along, tarred seams, the mooring posts with ropes out to the hull, and the
        // gangplank up to the deck.
        c.ground(g, C(0x7A5A3A), edge: C(0xB08A5A), speck: C(0x6A4A2E), seed: 43)
        for (i, y) in stride(from: g + 2 * s, to: c.h, by: 3 * s).enumerated() {
            c.rect(0, y, c.w, s, C(0x5A402A))
            for x in stride(from: (i * 23 % 47) * s, to: c.w, by: 47 * s) { c.rect(x, y - 2 * s, s, 2 * s, C(0x5A402A)) }
        }
        let span = f.x1 - f.x0
        let gx = f.x0 + span * 38 / 100, plankTop = f.deck - (tall ? 2 : 1) * s, rise = g - plankTop
        let run = rise * 3 / 2
        for i in 0..<run {
            let y = g - i * rise / run
            c.rect(gx + i, y - (tall ? 5 : 2) * s, 1, (tall ? 5 : 2) * s, C(0x8A6440))
            c.rect(gx + i, y - (tall ? 5 : 2) * s, 1, s, C(0xB08A5A))
            if i % ((tall ? 8 : 5) * s) == 0 { c.rect(gx + i, y - (tall ? 6 : 3) * s, s, s, C(0x5A402A)) }
        }
        let pw = (tall ? 6 : 3) * s, ph = (tall ? 12 : 5) * s
        for px in [f.x0 + span * 14 / 100, f.x0 + span * 66 / 100, f.x0 + span * 94 / 100] {
            hkRope(c, (px + pw / 2, g - ph + s), (px + (tall ? 30 : 10) * s, f.deck + (tall ? 6 : 2) * s), sag: (tall ? 6 : 2) * s,
                   C(0xC8A870))
            c.rect(px, g - ph, pw, ph, C(0x3A2818)); c.rect(px, g - ph, s, ph, C(0x6A4A2E))
            c.rect(px - s, g - ph - s, pw + 2 * s, 2 * s, C(0x2A1A10))
            c.rect(px, g - ph + 2 * s, pw, s, C(0xC8A870))
        }
    }

    /// The hull, column by column: the gold cap rail, the upper works in planks, the scarlet strake, the dark lower
    /// hull down to the water; the gun ports along the waist with a cannon's mouth in each, the forecastle's rail,
    /// the stern castle's lit windows and gilded stern; then the hull's broken reflection in the water below and the
    /// water slapping along its foot.
    private static func hkHull(_ c: PixelCanvas, _ g: Int, _ f: HkGalleon) {
        let s = unit(g), tall = isTall(c), gold = C(0xD8A83A)
        let strake = f.deck + (tall ? 4 : 1) * s, strakeH = (tall ? 6 : 2) * s
        for x in max(0, f.x0)...min(c.w - 1, f.x1) {
            guard let sp = hkHullSpan(f, x, s: s, tall: tall) else { continue }
            for y in sp.top..<sp.bottom {
                let col: Px
                if y < sp.top + s { col = gold }
                else if y < sp.top + 2 * s { col = C(0x8A5A30) }
                else if y >= strake && y < strake + strakeH { col = y == strake ? gold : (y >= strake + strakeH - s ? C(0x5A1A14) : C(0x9A2A22)) }
                else if y < strake { col = (y - sp.top) % (3 * s) == 0 ? C(0x4A2E1A) : C(0x6A4428) }
                else if y >= f.water - 2 * s { col = C(0x241610) }
                else { col = (y - strake) % (3 * s) == 0 ? C(0x2E1C12) : C(0x46301E) }
                c.px(x, y, col)
            }
            // A touch of light on the bow, shade under the counter.
            if x < f.x0 + 3 * s { c.rect(x, sp.top + 2 * s, 1, max(0, sp.bottom - sp.top - 2 * s), C(0xF8B880, 0.18)) }
        }
        // The gun ports: lids hinged up, the port dark, a cannon's muzzle looking out. Two tiers on the screen saver.
        let p = (tall ? 8 : 3) * s
        let tiers = tall ? [f.deck + 14 * s, f.deck + 30 * s] : [f.deck + 4 * s]
        for (ti, py) in tiers.enumerated() {
            let step = (tall ? 24 : 11) * s
            for gx in stride(from: f.fore.x + (tall ? 8 : 4) * s + ti * step / 2, to: f.castle.x + (tall ? 20 : 6) * s - p, by: step) {
                c.rect(gx - s, py - s, p + 2 * s, p + 2 * s, gold)
                c.rect(gx, py, p, p, C(0x140E0C))
                c.rect(gx, py - p / 2 - s, p, p / 2, C(0x9A2A22)); c.rect(gx, py - p / 2 - s, p, s, C(0x5A1A14))
                if tall {
                    c.circle(gx + p / 2, py + p / 2, 3 * s, C(0x2A2A30)); c.circle(gx + p / 2, py + p / 2, s, C(0x0A0808))
                    c.rect(gx + p / 2 - 2 * s, py + p / 2 - 3 * s, 3 * s, s, C(0x5A5A62))
                } else {
                    c.rect(gx + s, py + s, max(1, p - 2 * s), max(1, p - 2 * s), C(0x3A3A40))
                }
            }
        }
        // The forecastle's rail.
        let rail = (tall ? 8 : 3) * s
        for x in stride(from: f.x0 + (tall ? 8 : 3) * s, to: f.fore.x, by: (tall ? 4 : 2) * s) {
            guard let sp = hkHullSpan(f, x, s: s, tall: tall) else { continue }
            c.rect(x, sp.top - rail, s, rail, C(0xB8862A))
        }
        // The stern castle: its balustrade, a row of lit windows (two on the screen saver), the gilded stern post.
        let cx0 = f.castle.x + (tall ? 6 : 2) * s
        for x in stride(from: f.castle.x, to: f.x1, by: (tall ? 4 : 2) * s) {
            guard let sp = hkHullSpan(f, x, s: s, tall: tall) else { continue }
            c.rect(x, sp.top - rail, s, rail, C(0xB8862A))
        }
        if let sp = hkHullSpan(f, f.castle.x + 1, s: s, tall: tall) {
            c.rect(f.castle.x, sp.top - rail, f.x1 - f.castle.x, s, gold)
        }
        let ww = (tall ? 6 : 2) * s, wh = (tall ? 8 : 3) * s
        let rows = tall ? [f.castle.top + 8 * s, f.castle.top + 22 * s] : [f.castle.top + 3 * s]
        for wy in rows {
            for wx in stride(from: cx0, to: f.x1 - ww - (tall ? 6 : 2) * s, by: ww + (tall ? 6 : 3) * s) {
                c.rect(wx - s, wy - s, ww + 2 * s, wh + 2 * s, gold)
                c.rect(wx, wy, ww, wh, C(0xFFD27A))
                if tall { c.rect(wx + ww / 2, wy, s, wh, C(0xB8862A)); c.rect(wx, wy + wh / 2, ww, s, C(0xB8862A)) }
            }
        }
        if let sp = hkHullSpan(f, f.x1, s: s, tall: tall) {
            c.rect(f.x1 - (tall ? 4 : 1) * s, sp.top, (tall ? 4 : 1) * s + s, sp.bottom - sp.top, gold)
        }
        // The reflection, broken by the ripples, and the water along the hull's foot.
        for x in max(0, f.x0)...min(c.w - 1, f.x1) {
            guard let sp = hkHullSpan(f, x, s: s, tall: tall), sp.bottom >= f.water - s else { continue }
            for y in stride(from: f.water, to: g, by: 1) where ((y - f.water) / s) % 2 == 0 {
                let wob = Int(sin(Double(y) * 0.9) * Double(s))
                c.px(x + wob, y, C(0x1A1024, 0.55))
            }
            if (x / s) % 5 != 0 { c.px(x, f.water, C(0xF8C890, 0.35)) }
        }
    }

    /// What moves on the Jolly Roger: the lanterns glowing and flickering on the rails, glints on the sea, the
    /// water lapping at the hull, gulls wheeling round the masts, and the black skull-and-crossbones flag streaming
    /// out from the maintop (from the stern's staff in the window's strip).
    static func jollyRogerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), tall = isTall(c), f = hkGalleonFrame(c, g)
        // The lanterns.
        for (i, l) in f.lanterns.enumerated() {
            let flick = 0.85 + sin(t * 9 + Double(i) * 2.1) * 0.08 + sin(t * 23 + Double(i)) * 0.05
            let w = (tall ? 6 : 3) * s, h = (tall ? 8 : 4) * s
            let lx = Double(l.0), ly = Double(l.1 - h / 2)
            c.glowLine(lx, ly, lx + 0.1, ly, core: C(0xFFE8A0, 0.3 * flick), glow: C(0xFFB84A, 0.25 * flick),
                       coreR: Double(s), glowR: Double(h + 3 * s))
            c.rect(l.0 - w / 2, l.1 - h, w, h, C(0x3A2A1A))
            c.rect(l.0 - w / 2 + s, l.1 - h + s, w - 2 * s, h - 2 * s, C(0xFFD27A, flick))
            c.rect(l.0 - w / 2 - s, l.1 - h - s, w + 2 * s, s, C(0x2A1A10))
        }
        // Glints on the open sea either side of the ship and in the water at its foot.
        for i in 0..<(tall ? 10 : 6) where noise(i * 7 + Int(t * 3)) > 0.5 {
            let wx = Int(noise(i + 5300) * Double(c.w))
            let front = i % 2 == 0
            if !front && wx > f.sprit.x - 4 * s && wx < f.x1 + 4 * s { continue }
            let y0 = front ? f.water + s : f.sea + 2 * s
            let wy = y0 + Int(noise(i + 5310) * Double(max(1, (front ? g : f.water) - y0 - s)))
            c.rect(wx, wy, 2 * s, s, C(0xFFD8A0, 0.8))
        }
        // The water lapping along the hull.
        for x in stride(from: f.x0, to: f.x1, by: s) where sin(Double(x) * 0.35 + t * 3) > 0.55 {
            c.rect(x, f.water - s, s, s, C(0xF8D0A0, 0.6))
        }
        // The gulls.
        for i in 0..<(tall ? 5 : 3) {
            let span = Double(c.w + 60)
            let speed = 12 + noise(i + 5400) * 10
            let x = Int((noise(i + 5410) * span + t * speed).truncatingRemainder(dividingBy: span)) - 30
            let y = Int(noise(i + 5420) * Double(tall ? g / 3 : 10 * s)) + 2 * s + Int(sin(t * 0.9 + Double(i)) * Double(2 * s))
            let flap = Int(t * 6 + Double(i)) % 2 == 0
            c.rect(x, y, s, s, C(0xF8F8F4))
            c.rect(x - s, y + (flap ? -s : 0), s, s, C(0xF8F8F4)); c.rect(x + s, y + (flap ? -s : 0), s, s, C(0xF8F8F4))
            c.rect(x - 2 * s, y + (flap ? -s : s), s, s, C(0x3A3A3A)); c.rect(x + 2 * s, y + (flap ? -s : s), s, s, C(0x3A3A3A))
        }
        // The flag, streaming and rippling.
        let k = f.flag.k
        let fw = 25 * k, fh = 16 * k
        let flag = PixelCanvas(fw, fh)
        flag.rect(0, 0, fw, fh, C(0x141014))
        let sk: [String] = [
            "...#####...",
            "..#######..",
            "..#.###.#..",
            "..#######..",
            "...##.##...",
            "...#####...",
            "....#.#....",
            "#.........#",
            ".##.....##.",
            "...##.##...",
            ".....#.....",
            "...##.##...",
            ".##.....##.",
            "#.........#",
        ]
        for (ry, row) in sk.enumerated() {
            for (rx, p) in row.enumerated() where p == "#" {
                flag.rect(fw / 2 - 11 * k / 2 + rx * k, k + ry * k, k, k, C(0xF0ECE0))
            }
        }
        for x in 0..<fw {
            let phase = Double(x) / Double(k) * 0.36 - t * 5
            let wave = sin(phase) * Double(k) * Double(x) / Double(fw)
            let shade = sin(phase) > 0.6 ? 0.85 : 1.0
            for y in 0..<fh {
                let i = (y * fw + x) * 4
                let a = flag.buf[i + 3]
                guard a > 0 else { continue }
                c.px(f.flag.x + s + x, f.flag.y + y + Int(wave),
                     Px(r: UInt8(Double(flag.buf[i]) * shade), g: UInt8(Double(flag.buf[i + 1]) * shade),
                        b: UInt8(Double(flag.buf[i + 2]) * shade), a: 255))
            }
        }
    }
}
