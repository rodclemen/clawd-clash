import Foundation

// Places: the hunters' haunts on the road, Singer Salvage, Harvelle's Roadhouse, a motel room and the crossroads. Each
// place is a `Place` in the dictionary below (its name, the tint of the window's card area under it, its still picture
// and what moves there) and its drawing in an extension of `Scenes`, with a frame function the still and moving layers
// share so they line up. Check them with `build/preview place out.png <key>`, at window size and at screen-saver size.
//
// The universe's palette: rust, amber, Impala black, dusty denim blue and the odd motel-sign neon. The floor and the
// band just above it stay plain and mid-to-dark so the crew's outlines and names read; the busy detail goes higher up
// and at the sides; props keep their size in `Scenes.unit(g)` steps. The two signs (SINGER SALVAGE, VACANCY) are
// lettered two pixels a dot so they read in the window.

let huntScenes2: [Location: Place] = [
    .huntSalvage: Place(name: "Singer Salvage", panel: 0x1E1612, still: Scenes.huntSalvage, moving: Scenes.huntSalvageLife),
    .huntRoadhouse: Place(name: "Harvelle's Roadhouse", panel: 0x1E130C, still: Scenes.huntRoadhouse, moving: Scenes.huntRoadhouseLife),
    .huntMotel: Place(name: "A Motel Room", panel: 0x1C1216, still: Scenes.huntMotel, moving: Scenes.huntMotelLife),
    .huntCrossroads: Place(name: "The Crossroads", panel: 0x10141C, still: Scenes.huntCrossroads, moving: Scenes.huntCrossroadsLife),
]

// MARK: - Lettering

/// A blocky 5-row alphabet, three dots wide (N four), for the signs.
private let huntP2Glyphs: [Character: String] = [
    "A": "010101111101101", "C": "011100100100011", "E": "111100110100111", "G": "011100101101011",
    "I": "111010010010111", "L": "100100100100111", "N": "10011101101110011001", "R": "110101110101101",
    "S": "011100010001110", "V": "101101101101010", "Y": "101101010010010",
]

/// How wide `text` comes out at `p` pixels a dot (a space is two dots).
private func huntP2Width(_ text: String, _ p: Int) -> Int {
    text.reduce(0) { $0 + (huntP2Glyphs[$1].map { $0.count / 5 + 1 } ?? 3) } * p - p
}

/// Lettering, `p` pixels a dot, centred on `x` with its top on row `y`.
private func huntP2Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, _ p: Int) {
    var cx = x - huntP2Width(text, p) / 2
    for ch in text {
        guard let bits = huntP2Glyphs[ch] else { cx += 3 * p; continue }
        let gw = bits.count / 5
        for (i, b) in bits.enumerated() where b == "1" {
            c.rect(cx + (i % gw) * p, y + (i / gw) * p, p, p, col)
        }
        cx += (gw + 1) * p
    }
}

// MARK: - Singer Salvage

/// One junked car side-on, 24 units long and 8 high, standing on row `base`: faded paint lit along its top, a cabin
/// with dark glass, rust eating through, a wheel or two gone. `haze` fades it into the dusk for the far ones.
private func huntP2Car(_ c: PixelCanvas, _ x: Int, _ base: Int, _ s: Int, _ seed: Int, haze: Double) {
    let paints: [UInt32] = [0x7A3A22, 0x5A4A3A, 0x3E4C5E, 0x6E5A2A, 0x26262A, 0x5A2A20, 0x4A564A, 0x6A4430]
    let far = C(0x2E2634)
    func h(_ p: Px, _ k: Double = 1) -> Px { lerp(p, far, haze * k) }
    let paint = h(C(paints[Int(noise(seed * 7 + 1) * 8) % 8]))
    let lit = lerp(paint, h(C(0xE0A060)), 0.28), shade = lerp(paint, C(0x100C0E), 0.4)
    let rust = h(C(0x8A4624)), glass = h(C(0x1C222C)), black = h(C(0x141012), 0.6)
    let left = noise(seed * 7 + 2) > 0.5
    let cab = left ? x + 5 * s : x + 8 * s
    // The body: a long low box, its top lit, its sill in shadow, the bumpers dull chrome.
    c.rect(x, base - 5 * s, 24 * s, 4 * s, paint)
    c.rect(x, base - 5 * s, 24 * s, s, lit)
    c.rect(x, base - 2 * s, 24 * s, s, shade)
    c.rect(x - s, base - 4 * s, s, 2 * s, h(C(0x6A6664))); c.rect(x + 24 * s, base - 4 * s, s, 2 * s, h(C(0x5A5654)))
    // The cabin, its roof lit, two dark windows (one smashed through), the pillar between them.
    c.rect(cab + s, base - 8 * s, 9 * s, 3 * s, paint)
    c.rect(cab + s, base - 8 * s, 9 * s, s, lit)
    c.rect(cab, base - 7 * s, s, 2 * s, paint); c.rect(cab + 10 * s, base - 7 * s, s, 2 * s, shade)
    c.rect(cab + 2 * s, base - 7 * s, 3 * s, 2 * s, glass); c.rect(cab + 6 * s, base - 7 * s, 3 * s, 2 * s, glass)
    if noise(seed * 7 + 3) > 0.55 { c.rect(cab + 6 * s, base - 7 * s, 2 * s, s, black) }
    // Rust patches eating the paint, worst low down.
    for k in 0..<3 {
        let rx = x + Int(noise(seed * 7 + 10 + k) * 20) * s, rw = (2 + Int(noise(seed * 7 + 20 + k) * 3)) * s
        c.rect(rx, base - (3 + k % 2) * s, rw, s, rust)
    }
    // The wheel arches, with a tyre in each, or none.
    for (k, wx) in [x + 5 * s, x + 19 * s].enumerated() {
        c.circle(wx, base - s, 2 * s, black)
        if noise(seed * 7 + 30 + k) > 0.3 {
            c.circle(wx, base - s, 2 * s - max(1, s / 2), h(C(0x1E1C1C))); c.rect(wx - s / 2, base - s - s / 2, max(1, s), max(1, s), h(C(0x5A5654)))
        }
    }
}

/// A stack of `n` cars crushed one on another, each a little off the one under it.
private func huntP2Stack(_ c: PixelCanvas, _ x: Int, _ base: Int, _ n: Int, _ s: Int, _ seed: Int, haze: Double) {
    for i in 0..<n {
        let dx = Int((noise(seed * 13 + i) - 0.5) * 6) * s
        huntP2Car(c, x + dx, base - i * 8 * s, s, seed * 5 + i, haze: haze)
    }
}

extension Scenes {
    /// Where things stand in the yard, shared by the still picture and the moving layer: the horizon, Bobby's house
    /// (its left edge), the porch light, the sign (its middle and its board's top), the crane (its cab and the tip of
    /// its boom) and the hook's cable length.
    static func huntSalvageFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, house: Int, light: (x: Int, y: Int),
                                                               sign: (x: Int, y: Int), crane: (x: Int, tipX: Int, tipY: Int), cable: Int) {
        let s = unit(g), tall = isTall(c)
        let house = c.w * 3 / 100
        let crane = (x: c.w * 90 / 100, tipX: c.w * 74 / 100, tipY: tall ? g - 104 * s : g - 64 * s)
        return (g - 20 * s, house, (x: house + 39 * s, y: g - 19 * s), (x: c.w * 43 / 100, y: g - 62 * s), crane,
                tall ? 54 * s : 24 * s)
    }

    /// Singer Salvage at dusk, Bobby's yard outside Sioux Falls: a sky going from denim blue to amber over the flat
    /// land, rows of rusting cars stacked two and three high, Bobby's weathered clapboard house on the left with its
    /// porch and lit windows, the hand-painted SINGER SALVAGE board on its posts, and an old boom crane on the right,
    /// its hook hanging. On the screen saver the stacks rise into towers of cars, a water tower stands over the yard
    /// and the first stars come out.
    static func huntSalvage(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntSalvageFrame(c, g), tall = isTall(c)
        // The sky: dusk, denim blue up high fading through dusty violet to amber at the horizon.
        if tall {
            c.gradient(0, g * 45 / 100, C(0x10162A), C(0x2E3452), bands: 8)
            c.gradient(g * 45 / 100, f.horizon, C(0x2E3452), C(0xC47C44), bands: 10)
            c.stars(0, g * 32 / 100, density: 70, seed: 21)
            // A thin new moon up in the dark, and the evening star brighter than the rest.
            let mx = c.w * 20 / 100, my = g * 17 / 100
            c.circle(mx, my, 9 * s, C(0xF0E2B8)); c.circle(mx + 3 * s, my - s, 9 * s, lerp(C(0x10162A), C(0x2E3452), Double((my - s) * 8 / (g * 45 / 100)) / 8))
            c.rect(c.w * 46 / 100, g * 26 / 100, 2 * s, 2 * s, C(0xFFF4D0)); c.rect(c.w * 46 / 100 - s, g * 26 / 100 + s / 2, 4 * s, max(1, s / 2), C(0xFFF4D0, 0.5))
        } else {
            c.gradient(0, f.horizon, C(0x3A3A58), C(0xC8844A), bands: 7)
        }
        // The sun just gone down: a warm glow on the horizon right of middle, and streaks of cloud lit from below.
        for r in stride(from: 40 * s, to: 4 * s, by: -4 * s) {
            c.ellipse(c.w * 62 / 100, f.horizon, r * 2, r / 2, C(0xF0A050, 0.06))
        }
        let streaks: [(Int, Int, Int)] = tall ? [(18, 40, 60), (70, 66, 80), (40, 52, 50), (88, 30, 70), (30, 92, 90), (78, 104, 60), (56, 82, 40)]
                                               : [(18, 10, 50), (70, 16, 70), (46, 6, 40)]
        for (xp, yu, len) in streaks {
            let y = tall ? f.horizon - yu * s * 2 : yu * s
            wisp(c, c.w * xp / 100, y, len * s, C(0xD08A6A, 0.55), s: s)
            c.rect(c.w * xp / 100 - len * s / 3, y + s, len * s / 2, max(1, s / 2), C(0xF0B070, 0.5))
        }
        // The flat land at the horizon: a dark line of trees and far fences.
        c.dunes(base: f.horizon, amp: Double(s), freq: 0.07, phase: 1.1, bottom: f.horizon + 3 * s, C(0x2A2230))
        c.rect(0, f.horizon + 2 * s, c.w, g - f.horizon - 2 * s, C(0x2E2622))
        // On the screen saver: the water tower over the yard, rust-streaked on four braced legs, and towers of cars.
        if tall {
            let wx = c.w * 58 / 100, legTop = f.horizon - 74 * s, tank = C(0x6A4A34), tankL = C(0x8A6444), tankD = C(0x46301F)
            for (k, lx) in [wx - 14 * s, wx - 5 * s, wx + 5 * s, wx + 14 * s].enumerated() {
                c.rect(lx, legTop, 2 * s, f.horizon - legTop, k < 2 ? C(0x3A2E2A) : C(0x2E2420))
            }
            for y in stride(from: legTop + 8 * s, to: f.horizon - 4 * s, by: 18 * s) {
                c.rect(wx - 14 * s, y, 30 * s, s, C(0x3A2E2A))
                c.glowLine(Double(wx - 14 * s), Double(y), Double(wx + 15 * s), Double(y + 18 * s), core: C(0x34282A), glow: C(0, 0),
                           coreR: Double(s) * 0.5, glowR: Double(s) * 0.6)
                c.glowLine(Double(wx + 15 * s), Double(y), Double(wx - 14 * s), Double(y + 18 * s), core: C(0x34282A), glow: C(0, 0),
                           coreR: Double(s) * 0.5, glowR: Double(s) * 0.6)
            }
            c.rect(wx - 20 * s, legTop - 2 * s, 41 * s, 2 * s, tankD)
            c.rect(wx - 18 * s, legTop - 24 * s, 37 * s, 22 * s, tank)
            c.rect(wx - 18 * s, legTop - 24 * s, 6 * s, 22 * s, tankL); c.rect(wx + 13 * s, legTop - 24 * s, 6 * s, 22 * s, tankD)
            for y in stride(from: legTop - 20 * s, to: legTop - 2 * s, by: 6 * s) { c.rect(wx - 18 * s, y, 37 * s, max(1, s / 2), tankD) }
            for k in 0..<4 { c.rect(wx - 8 * s + k * 7 * s, legTop - 20 * s, s, (6 + k * 3) * s, C(0x8A4624)) }   // rust streaks
            for k in 0..<12 {   // the conical cap
                let w = 41 * s - k * 3 * s
                c.rect(wx - w / 2, legTop - 25 * s - k * s, w, s, k < 2 ? C(0x3A2A20) : C(0x4E3626))
            }
            c.rect(wx - s / 2, legTop - 40 * s, max(1, s), 4 * s, C(0x3A2A20))
            // The towers of cars: five and six high at the sides.
            huntP2Stack(c, c.w * 22 / 100, f.horizon + 4 * s, 6, s, 61, haze: 0.45)
            huntP2Stack(c, c.w * 68 / 100, f.horizon + 4 * s, 5, s, 67, haze: 0.45)
            huntP2Stack(c, c.w * 36 / 100, f.horizon + 4 * s, 4, s, 69, haze: 0.5)
            huntP2Stack(c, c.w * 84 / 100, f.horizon + 4 * s, 7, s, 71, haze: 0.4)
        }
        // The rows of junked cars across the back of the yard, two and three high.
        let row: [(Int, Int, Int)] = [(20, 2, 3), (31, 3, 5), (60, 2, 7), (72, 1, 9), (96, 2, 11), (46, 1, 13)]
        for (xp, n, seed) in row { huntP2Stack(c, c.w * xp / 100, g - 6 * s, n, s, seed, haze: 0.22) }
        // The boom crane on the right: a squat rust-red cab on tracks, the lattice boom angled up to the left.
        let cr = f.crane, boomBase = (x: cr.x - 2 * s, y: g - 16 * s)
        let boomL = C(0xA8743A), boomD = C(0x6A4626)
        for k in [0, 3] {
            c.glowLine(Double(boomBase.x), Double(boomBase.y + k * s), Double(cr.tipX), Double(cr.tipY + k * s / 2),
                       core: k == 0 ? boomL : boomD, glow: C(0, 0), coreR: Double(s) * 0.7, glowR: Double(s) * 0.8)
        }
        let steps = max(1, (boomBase.x - cr.tipX) / (6 * s))
        for k in 0..<steps {   // the lattice between the two chords
            let a = Double(k) / Double(steps), b = Double(k + 1) / Double(steps)
            let x0 = Double(boomBase.x) + Double(cr.tipX - boomBase.x) * a, y0 = Double(boomBase.y) + Double(cr.tipY - boomBase.y) * a
            let x1 = Double(boomBase.x) + Double(cr.tipX - boomBase.x) * b, y1 = Double(boomBase.y) + Double(cr.tipY - boomBase.y) * b
            c.glowLine(x0, y0 + Double(3 * s), x1, y1, core: boomD, glow: C(0, 0), coreR: Double(s) * 0.4, glowR: Double(s) * 0.5)
        }
        c.rect(cr.tipX - s, cr.tipY - s, 3 * s, 3 * s, C(0x3A2A20))
        c.rect(cr.x - 10 * s, g - 22 * s, 22 * s, 14 * s, C(0x6A2E1E))
        c.rect(cr.x - 10 * s, g - 22 * s, 22 * s, s, C(0x8A4430)); c.rect(cr.x - 10 * s, g - 22 * s, s, 14 * s, C(0x8A4430))
        c.rect(cr.x - 6 * s, g - 20 * s, 7 * s, 5 * s, C(0x24282E)); c.rect(cr.x - 6 * s, g - 20 * s, 7 * s, s, C(0x4A5664))
        c.rect(cr.x - 12 * s, g - 8 * s, 28 * s, 6 * s, C(0x221C1C))
        for x in stride(from: cr.x - 11 * s, to: cr.x + 15 * s, by: 3 * s) { c.rect(x, g - 7 * s, s, 4 * s, C(0x3A3434)) }
        // A pile of old tyres beside it.
        for (k, (dx, dy)) in [(-24, 0), (-18, 0), (-21, -3)].enumerated() {
            c.ellipse(cr.x + dx * s, g - 2 * s + dy * s, 3 * s, 2 * s, C(0x161414)); c.ellipse(cr.x + dx * s, g - 2 * s + dy * s, s, s / 2 + 1, k == 2 ? C(0x2A2420) : C(0x221E1C))
        }
        // The sign: a long board of planks on two posts, painted rust-red, SINGER SALVAGE in cream.
        let text = "SINGER SALVAGE", p = 2 * s, bw = huntP2Width(text, p) + 10 * s, bx = f.sign.x - bw / 2, by = f.sign.y
        for px in [bx + 5 * s, bx + bw - 7 * s] {
            c.rect(px, by, 2 * s, g - by, C(0x3A2A1E)); c.rect(px, by, max(1, s / 2), g - by, C(0x5A4430))
        }
        c.rect(bx, by, bw, 16 * s, C(0x5E2E1E))
        c.rect(bx, by, bw, s, C(0x8A4A30)); c.rect(bx, by, s, 16 * s, C(0x7A4028))
        c.rect(bx, by + 15 * s, bw, s, C(0x3A1C12)); c.rect(bx + bw - s, by, s, 16 * s, C(0x3A1C12))
        c.rect(bx + s, by + 8 * s, bw - 2 * s, max(1, s / 2), C(0x4A2418))
        for k in 0..<5 { c.rect(bx + Int(noise(400 + k) * Double(bw - 8 * s)), by + (2 + k * 3) * s, 6 * s, max(1, s / 2), C(0x6E3A26)) }
        huntP2Text(c, f.sign.x + s, by + 3 * s + s / 2, text, C(0x1E0E08, 0.6), p)
        huntP2Text(c, f.sign.x, by + 3 * s, text, C(0xE2D2A8), p)
        // Bobby's house: dusty blue clapboard under a dark shingled gable, lit windows, the deep front porch.
        let hx = f.house, hw = 64 * s, eave = g - 38 * s, peak = g - 58 * s, mid = hx + hw / 2
        let side = C(0x4A5466), sideD = C(0x3A4252), sideL = C(0x66728A), roof = C(0x2A2224), roofL = C(0x4A3A36)
        let rise = eave - peak
        for k in 0..<rise {
            let half = (hw / 2 + 4 * s) * (k + 1) / rise
            c.rect(mid - half, peak + k, 2 * half, 1, roof)
            let inner = max(0, half - 5 * s)
            if inner > 0 && k > 4 * s { c.rect(mid - inner, peak + k, 2 * inner, 1, side) }
            c.rect(mid - half, peak + k, max(1, s), 1, roofL)
        }
        c.rect(hx, eave, hw, g - eave, side)
        for y in stride(from: peak + 6 * s, to: g, by: 2 * s) {
            let inGable = y < eave
            let half = inGable ? max(0, (hw / 2 + 4 * s) * (y - peak) / rise - 5 * s) : hw / 2
            c.rect(mid - half, y, 2 * half, max(1, s / 2), sideD)
        }
        c.rect(hx, eave, s, g - eave, sideL); c.rect(hx + hw - s, eave, s, g - eave, sideD)
        c.rect(hx - 2 * s, eave - s, hw + 4 * s, 2 * s, roof)
        // Windows: lit amber with a cross of mullions and a curtain, the one in the gable dark.
        func window(_ x: Int, _ y: Int, _ w: Int, _ h: Int, lit: Bool) {
            c.rect(x - s, y - s, w + 2 * s, h + 2 * s, C(0xA8A090))
            c.rect(x, y, w, h, lit ? C(0xD09A4A) : C(0x1C2230))
            if lit { c.rect(x, y, w, h / 2, C(0xE0B060)); c.rect(x, y, 2 * s, h, C(0x8A4A2A)) }
            c.rect(x + w / 2, y, max(1, s / 2), h, C(0x6A6458)); c.rect(x, y + h / 2, w, max(1, s / 2), C(0x6A6458))
        }
        window(mid - 3 * s, peak + 10 * s, 6 * s, 6 * s, lit: false)
        window(hx + 9 * s, eave + 3 * s, 9 * s, 9 * s, lit: true)
        window(hx + hw - 18 * s, eave + 3 * s, 9 * s, 9 * s, lit: false)
        // The porch: a sloped roof on square posts, the deck, the steps, the shade under it.
        let porch = g - 24 * s
        c.rect(hx, porch + 2 * s, hw, g - porch - 4 * s, C(0x0C0A10, 0.4))
        window(hx + 7 * s, g - 17 * s, 10 * s, 9 * s, lit: true)
        window(hx + hw - 17 * s, g - 17 * s, 10 * s, 9 * s, lit: true)
        c.rect(hx + 28 * s, g - 20 * s, 9 * s, 17 * s, C(0x3A2A20)); c.rect(hx + 28 * s, g - 20 * s, 9 * s, s, C(0x5A4430))
        c.rect(hx + 29 * s, g - 18 * s, 7 * s, 6 * s, C(0x2A2E36)); c.rect(hx + 35 * s, g - 11 * s, s, s, C(0xB09040))
        c.rect(f.light.x - s, f.light.y - s, 3 * s, 3 * s, C(0x2A2420))   // the porch light's fitting
        for k in 0..<3 { c.rect(hx - 4 * s, porch + k * s, hw + 8 * s, s, k == 0 ? roofL : roof) }
        for px in [hx - 2 * s, hx + 20 * s, hx + 43 * s, hx + hw] {
            c.rect(px, porch + 3 * s, 2 * s, g - porch - 6 * s, C(0x8A8474)); c.rect(px + s, porch + 3 * s, s, g - porch - 6 * s, C(0x5A5650))
        }
        c.rect(hx - 4 * s, g - 4 * s, hw + 8 * s, 2 * s, C(0x5A4A3A)); c.rect(hx - 4 * s, g - 4 * s, hw + 8 * s, max(1, s / 2), C(0x7A6650))
        c.rect(hx - 4 * s, g - 2 * s, hw + 8 * s, 2 * s, C(0x2A2220))
        for k in 0..<2 { c.rect(hx + 26 * s - k * s, g - 2 * s + k * s, 13 * s + 2 * k * s, s, k == 0 ? C(0x6A5844) : C(0x4E4034)) }
        // The yard: packed dirt, oil-dark, tyre ruts.
        c.ground(g, C(0x3A2E26), edge: C(0x4E3E30), speck: C(0x2E241E), seed: 52)
        for y in [g + 3, g + 6] where y < c.h { c.rect(0, y, c.w, max(1, s / 2), C(0x30261F)) }
    }

    /// The yard's life: the crane's hook swaying on its cable in the evening breeze, and the porch light over Bobby's
    /// door, buzzing and stuttering out now and then.
    static func huntSalvageLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntSalvageFrame(c, g)
        let a = sin(t * 0.8) * 0.09 + sin(t * 1.9) * 0.025
        let ex = Double(f.crane.tipX) + sin(a) * Double(f.cable), ey = Double(f.crane.tipY) + cos(a) * Double(f.cable)
        c.glowLine(Double(f.crane.tipX), Double(f.crane.tipY), ex, ey, core: C(0x1E1814), glow: C(0, 0),
                   coreR: Double(s) * 0.7, glowR: Double(s) * 0.75)
        let hx = Int(ex), hy = Int(ey)
        c.rect(hx - 2 * s, hy, 4 * s, 3 * s, C(0x4A3A30)); c.rect(hx - 2 * s, hy, 4 * s, s, C(0x6A5A4A))
        c.rect(hx - s / 2, hy + 3 * s, max(1, s), 2 * s, C(0x3A3230))
        c.rect(hx - 2 * s, hy + 5 * s, 3 * s, s, C(0x3A3230)); c.rect(hx - 2 * s, hy + 4 * s, s, s, C(0x3A3230))
        // The porch light: steady, then a few stuttering seconds every quarter of a minute or so.
        let phase = t.truncatingRemainder(dividingBy: 13.0)
        let out = phase > 10.5 && phase < 11.6 && Int(t * 11) % 3 != 1
        if !out {
            for r in stride(from: 14 * s, to: 2 * s, by: -3 * s) { c.ellipse(f.light.x, f.light.y + s, r, r * 3 / 4, C(0xF0B050, 0.05)) }
            c.rect(f.light.x - s / 2, f.light.y - s / 2, max(1, s), max(1, s), C(0xFFE6A0))
        }
    }
}

// MARK: - Harvelle's Roadhouse

/// A neon beer sign on its little dark backing board: a bottle (0), an oval with a script swoosh (1) or a star (2).
/// Unlit, the tubes are dim glass; lit, they glow.
private func huntP2Neon(_ c: PixelCanvas, _ kind: Int, _ x: Int, _ y: Int, _ s: Int, glow: Double) {
    let cols: [UInt32] = [0xFFB040, 0xFF4A3A, 0x5AB0FF]
    let lit = C(cols[kind]), core = glow > 0 ? lerp(lit, C(0xFFFFFF), 0.45) : lerp(lit, C(0x2A1A14), 0.6)
    let halo = glow > 0 ? lit.alpha(0.3 * glow) : C(0, 0)
    func line(_ a: (Int, Int), _ b: (Int, Int)) {
        c.glowLine(Double(x + a.0 * s), Double(y + a.1 * s), Double(x + b.0 * s), Double(y + b.1 * s), core: core, glow: halo,
                   coreR: Double(s) * 0.55, glowR: Double(s) * (glow > 0 ? 2.2 : 0.6))
    }
    var pts: [(Int, Int)] = []
    switch kind {
    case 0: pts = [(-1, -8), (1, -8), (1, -5), (3, -2), (3, 7), (-3, 7), (-3, -2), (-1, -5), (-1, -8)]
    case 1:
        for k in 0...16 { let a = Double(k) * .pi / 8; pts.append((Int((cos(a) * 9).rounded()), Int((sin(a) * 5).rounded()))) }
        line((-6, 1), (-3, -2)); line((-3, -2), (0, 1)); line((0, 1), (3, -2)); line((3, -2), (6, 0))
    default:
        for k in 0...10 {
            let a = Double(k) * .pi / 5 - .pi / 2, r = k % 2 == 0 ? 7.0 : 3.0
            pts.append((Int((cos(a) * r).rounded()), Int((sin(a) * r).rounded())))
        }
    }
    for k in 1..<pts.count { line(pts[k - 1], pts[k]) }
}

extension Scenes {
    /// Where things stand in the bar, shared by the still picture and the moving layer: the wainscot's top, the bar
    /// (its left end and its top), the pool table (middle, half its width, top), the dartboard, the neon signs (each
    /// where it hangs and which), the ceiling fan's hub, and on the screen saver the eaves of the gable above.
    static func huntRoadhouseFrame(_ c: PixelCanvas, _ g: Int) -> (rail: Int, bar: (x: Int, top: Int), pool: (x: Int, half: Int, top: Int),
                                                                  dart: (x: Int, y: Int), signs: [(x: Int, y: Int, kind: Int)],
                                                                  fan: (x: Int, y: Int), eaves: Int) {
        let s = unit(g), tall = isTall(c)
        let signs: [(x: Int, y: Int, kind: Int)] = [(c.w * 27 / 100, g - 48 * s, 0), (c.w * 55 / 100, g - 46 * s, 1),
                                                     (c.w * 86 / 100, g - 52 * s, 2)]
        return (g - 13 * s, (x: c.w * 68 / 100, top: g - 17 * s), (x: c.w * 38 / 100, half: 24 * s, top: g - 12 * s),
                (x: c.w * 11 / 100, y: g - 40 * s), signs, (x: c.w * 46 / 100, y: tall ? g - 76 * s : g - 61 * s),
                tall ? g * 40 / 100 : -1)
    }

    /// Where the bar's odds and ends stand, shared by the still picture and the moving layer: the jukebox's middle,
    /// the round table's middle, the corkboard's and the payphone's middles, and the string of bulbs' row.
    static func huntRoadhouseExtras(_ c: PixelCanvas, _ g: Int) -> (jukebox: Int, table: Int, board: Int, phone: Int, bulbs: Int) {
        let s = unit(g)
        return (c.w * 60 / 100, c.w * 19 / 100, c.w * 19 / 100, c.w * 48 / 100, g - 58 * s)
    }

    /// Harvelle's Roadhouse, the hunters' bar off a Nebraska highway: walls of warm vertical planks, a dark wood
    /// wainscot, the bar on the right with bottles on its back shelves and red stools, the pool table under its green
    /// lamp, Jo's dartboard on the left with knives stuck in it, neon beer signs on the wall and a ceiling fan. On the
    /// screen saver the room opens up into the gable: rafters, a tie beam with lanterns hanging from it, licence plates
    /// along the wall and a shotgun over the bar.
    static func huntRoadhouse(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadhouseFrame(c, g), tall = isTall(c)
        let plankA = C(0x5A3A24), plankB = C(0x4E321E), plankL = C(0x6E4A2E), plankD = C(0x2E1C10)
        let wood = C(0x4A2C18), woodD = C(0x2A180E), woodL = C(0x6A4428)
        // The plank wall, warmer in the middle where the lamps are, each board lit on its left edge.
        c.rect(0, 0, c.w, f.rail, plankA)
        for (k, x) in stride(from: 0, to: c.w, by: 7 * s).enumerated() {
            c.rect(x, 0, 7 * s, f.rail, k % 3 == 1 ? plankB : plankA)
            c.rect(x, 0, max(1, s / 2), f.rail, plankL); c.rect(x + 6 * s, 0, max(1, s / 2), f.rail, plankD)
            for y in stride(from: Int(noise(k) * 30) * s + 4 * s, to: f.rail, by: 34 * s) { c.rect(x + 3 * s, y, max(1, s / 2), max(1, s / 2), plankD) }
        }
        c.gradient(0, f.rail, C(0x0C0604, 0.35), C(0x0C0604, 0), bands: 5)
        // On the screen saver: the gable end of the roof, its rafters, the tie beam and its lanterns, the king post.
        if tall {
            let ey = f.eaves, peak = g * 6 / 100, mx = c.w / 2
            for y in 0..<ey {   // the dark of the roof's underside beyond the slopes
                let half = y <= peak ? 0 : (c.w / 2 + 10 * s) * (y - peak) / (ey - peak)
                c.rect(0, y, max(0, mx - half), 1, C(0x140C08)); c.rect(mx + half, y, max(0, c.w - mx - half), 1, C(0x140C08))
            }
            for k in [-1, 1] {   // the two rafters along the slopes
                c.glowLine(Double(mx), Double(peak), Double(mx + k * (c.w / 2 + 10 * s)), Double(ey), core: woodD, glow: C(0, 0),
                           coreR: Double(s) * 2.5, glowR: Double(s) * 2.6)
                c.glowLine(Double(mx), Double(peak + 2 * s), Double(mx + k * (c.w / 2 + 10 * s)), Double(ey + 2 * s), core: woodL,
                           glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
                c.glowLine(Double(mx), Double(ey), Double(mx + k * c.w / 4), Double(peak + (ey - peak) / 2), core: wood, glow: C(0, 0),
                           coreR: Double(s) * 1.5, glowR: Double(s) * 1.6)
            }
            c.rect(mx - 3 * s, peak, 6 * s, ey - peak, wood); c.rect(mx - 3 * s, peak, s, ey - peak, woodL)
            // Two round windows high in the gable, night and stars beyond, a mullion cross in each.
            for k in [-1, 1] {
                let wx = mx + k * c.w / 5, wy = peak + (ey - peak) * 62 / 100, wr = 11 * s
                c.circle(wx, wy, wr + 2 * s, woodD); c.circle(wx, wy, wr, C(0x141C30))
                c.stars(wy - wr, wy + wr, density: 14, seed: 30 + k, x0: wx - wr, x1: wx + wr) { x, y in (x - wx) * (x - wx) + (y - wy) * (y - wy) < (wr - s) * (wr - s) }
                c.rect(wx - wr, wy - s / 2, 2 * wr, max(1, s), woodL); c.rect(wx - s / 2, wy - wr, max(1, s), 2 * wr, woodL)
            }
            c.rect(0, ey, c.w, 5 * s, wood); c.rect(0, ey, c.w, s, woodL); c.rect(0, ey + 4 * s, c.w, s, woodD)
            // Lanterns on chains from the tie beam.
            for xp in [14, 34, 66, 86] {
                let lx = c.w * xp / 100, ly = ey + 22 * s
                c.rect(lx, ey + 5 * s, max(1, s / 2), ly - ey - 5 * s, C(0x1E1410))
                for r in stride(from: 16 * s, to: 2 * s, by: -3 * s) { c.ellipse(lx, ly + 4 * s, r, r * 3 / 4, C(0xF0A040, 0.04)) }
                c.rect(lx - 3 * s, ly, 7 * s, s, C(0x2A1E16)); c.rect(lx - 2 * s, ly + s, 5 * s, 6 * s, C(0xF0B058))
                c.rect(lx - 2 * s, ly + s, s, 6 * s, C(0x2A1E16)); c.rect(lx + 2 * s, ly + s, s, 6 * s, C(0x2A1E16))
                c.rect(lx - 3 * s, ly + 7 * s, 7 * s, s, C(0x2A1E16)); c.rect(lx - s, ly - 2 * s, 3 * s, 2 * s, C(0x2A1E16))
            }
            // A row of rusty licence plates along the wall, and a shotgun on pegs over the bar.
            let plates: [UInt32] = [0x8A6A3A, 0x4A5A6E, 0x7A3A26, 0x9A8A6A, 0x3A5A4A, 0x8A4A2A]
            for (k, x) in stride(from: 8 * s, to: c.w * 60 / 100, by: 15 * s).enumerated() {
                let col = C(plates[k % plates.count]), y = g - 84 * s + (k % 2) * s
                c.rect(x, y, 12 * s, 6 * s, col); c.rect(x, y, 12 * s, s, lerp(col, C(0xFFFFFF), 0.25))
                c.rect(x + 2 * s, y + 2 * s, 8 * s, 2 * s, lerp(col, C(0x100806), 0.5))
            }
            let gx = c.w * 72 / 100, gy = g - 70 * s
            for px in [gx + 6 * s, gx + 26 * s] { c.rect(px, gy, 2 * s, 3 * s, woodD) }
            c.rect(gx, gy - 2 * s, 22 * s, 2 * s, C(0x3A3A40)); c.rect(gx, gy - 2 * s, 22 * s, max(1, s / 2), C(0x6A6A72))
            c.rect(gx + 22 * s, gy - 2 * s, 12 * s, 3 * s, woodL); c.rect(gx + 30 * s, gy - s, 6 * s, 3 * s, wood)
        }
        // The neon signs' backing boards, and their tubes unlit (the moving layer lights them).
        for sg in f.signs {
            c.rect(sg.x - 11 * s, sg.y - 10 * s, 22 * s, 19 * s, C(0x1A100A)); c.rect(sg.x - 11 * s, sg.y - 10 * s, 22 * s, s, C(0x3A281A))
            huntP2Neon(c, sg.kind, sg.x, sg.y, s, glow: 0)
        }
        // The dartboard on its dark cabinet: black and cream sectors, the red and green rings, three knives stuck in it.
        let d = f.dart, r = 9 * s
        c.rect(d.x - 13 * s, d.y - 13 * s, 26 * s, 26 * s, C(0x3A2416)); c.rect(d.x - 13 * s, d.y - 13 * s, 26 * s, s, woodL)
        c.rect(d.x - 13 * s, d.y - 13 * s, s, 26 * s, woodL); c.rect(d.x - 12 * s, d.y - 12 * s, 24 * s, 24 * s, woodD)
        for dy in -r...r {
            for dx in -r...r {
                let rr = Double(dx * dx + dy * dy).squareRoot()
                guard rr <= Double(r) else { continue }
                let sector = Int(((atan2(Double(dy), Double(dx)) + .pi) / (2 * .pi) * 10).rounded(.down)) % 2
                let col: Px
                if rr > Double(r) - Double(s) * 1.2 { col = C(0x141010) }
                else if (rr > Double(r) - Double(s) * 2.4 && rr <= Double(r) - Double(s) * 1.2) || (rr > Double(r) * 0.42 && rr < Double(r) * 0.58) {
                    col = sector == 0 ? C(0xA8302A) : C(0x2E6A3A)
                } else if rr < Double(s) * 1.1 { col = C(0xC8302A) }
                else { col = sector == 0 ? C(0x1E1A16) : C(0xD8C8A0) }
                c.px(d.x + dx, d.y + dy, col)
            }
        }
        // Jo's knives, thrown and left there: steel blades into the board, black grips with a lit edge and a guard.
        for (u, v, ang) in [(-2, -3, 2.4), (3, 1, 0.45), (-1, 4, 3.6)] as [(Int, Int, Double)] {
            let x0 = Double(d.x + u * s), y0 = Double(d.y + v * s)
            let x1 = x0 + cos(ang) * Double(4 * s), y1 = y0 - sin(ang) * Double(4 * s)
            let x2 = x0 + cos(ang) * Double(10 * s), y2 = y0 - sin(ang) * Double(10 * s)
            c.glowLine(x0, y0, x1, y1, core: C(0xD8DCE4), glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            c.glowLine(x1, y1, x2, y2, core: C(0x161214), glow: C(0, 0), coreR: Double(s) * 1.1, glowR: Double(s) * 1.2)
            c.glowLine(x1, y1 - Double(s) * 0.5, x2, y2 - Double(s) * 0.5, core: C(0x5A5660), glow: C(0, 0), coreR: Double(s) * 0.35, glowR: Double(s) * 0.4)
            c.rect(Int(x1) - s, Int(y1) - s, 2 * s, 2 * s, C(0xA8A8B0))
        }
        // A rack of pool cues on the wall by the table.
        let rx = f.pool.x - f.pool.half - 12 * s
        c.rect(rx - s, g - 46 * s, 10 * s, 2 * s, woodD); c.rect(rx - s, g - 18 * s, 10 * s, 2 * s, woodD)
        for k in 0..<4 { c.rect(rx + k * 2 * s, g - 50 * s, max(1, s), 33 * s, k % 2 == 0 ? C(0xC8A070) : C(0xA87A4A)); c.rect(rx + k * 2 * s, g - 30 * s, max(1, s), 12 * s, C(0x2A1A10)) }
        // The back bar on the right: two shelves of bottles over the bar, catching the light.
        let bottles: [UInt32] = [0xB0782A, 0x3A6A3A, 0xA8B0A8, 0x5A3A1A, 0xC89040, 0x2E4E3A]
        for (row, shelf) in [g - 26 * s, g - 37 * s].enumerated() {
            c.rect(f.bar.x + 4 * s, shelf, c.w - f.bar.x - 4 * s, 2 * s, woodL); c.rect(f.bar.x + 4 * s, shelf + s, c.w - f.bar.x - 4 * s, s, woodD)
            var x = f.bar.x + 6 * s, i = row * 37
            while x < c.w - 3 * s {
                let col = C(bottles[Int(noise(i + 600) * 6) % 6]), bh = (5 + Int(noise(i + 601) * 3)) * s
                c.rect(x, shelf - bh, 2 * s, bh, col); c.rect(x, shelf - bh, max(1, s / 2), bh, lerp(col, C(0xFFFFFF), 0.35))
                c.rect(x + s / 2, shelf - bh - 2 * s, max(1, s), 2 * s, col)
                x += 3 * s + (noise(i + 602) > 0.75 ? 2 * s : 0); i += 7
            }
        }
        // The ceiling fan's rod and hub (the moving layer turns its blades).
        let fanTop = tall ? f.eaves + 5 * s : 0
        c.rect(f.fan.x - s / 2, fanTop, max(1, s), f.fan.y - fanTop, C(0x2A1E16))
        c.rect(f.fan.x - 3 * s, f.fan.y - s, 6 * s, 3 * s, C(0x3A2A1E)); c.rect(f.fan.x - 3 * s, f.fan.y - s, 6 * s, max(1, s / 2), C(0x6A5038))
        c.rect(f.fan.x - 2 * s, f.fan.y + 2 * s, 4 * s, 2 * s, C(0xE0C080))
        // The pool table's lamp: a green glass shade hanging over the felt, a pool of light under it.
        let p = f.pool, lampY = p.top - 24 * s, lampTop = tall ? f.eaves + 5 * s : 0
        c.rect(p.x - s / 2, lampTop, max(1, s), lampY - lampTop, C(0x1E1410))
        for r in stride(from: 26 * s, to: 4 * s, by: -4 * s) { c.ellipse(p.x, p.top + s, r + 10 * s, r / 3, C(0xF0E0A0, 0.04)) }
        for k in 0..<4 { let w = (6 + k * 4) * s; c.rect(p.x - w / 2, lampY + k * s, w, s, k == 0 ? C(0x4A7A52) : C(0x2E5A3A)) }
        c.rect(p.x - 9 * s, lampY + 4 * s, 18 * s, s, C(0xF4E2A8))
        huntRoadhouseWall(c, g)
        // The wainscot: dark horizontal boards with a lit cap rail.
        c.rect(0, f.rail, c.w, g - f.rail, wood)
        for y in stride(from: f.rail + 3 * s, to: g, by: 3 * s) { c.rect(0, y, c.w, max(1, s / 2), woodD) }
        c.rect(0, f.rail, c.w, s, woodL); c.rect(0, f.rail + s, c.w, s, woodD)
        // The pool table: worn green felt with the balls on it, wooden rails, corner pockets, a heavy apron and legs.
        let felt = C(0x2E5A3E), feltL = C(0x3E6E4C)
        c.rect(p.x - p.half - 2 * s, p.top - s, 2 * p.half + 4 * s, s, woodL)
        c.rect(p.x - p.half, p.top, 2 * p.half, 4 * s, felt); c.rect(p.x - p.half, p.top, 2 * p.half, s, feltL)
        for (u, v, col) in [(-12, 2, 0xE8E0D0), (6, 1, 0xC8302A), (9, 2, 0xE0B030), (12, 1, 0x2A4AA0), (14, 3, 0x141414), (-3, 3, 0x5A2A7A)] as [(Int, Int, UInt32)] {
            c.rect(p.x + u * s, p.top + v * s, s + s / 2, s, C(col))
        }
        c.rect(p.x - p.half - 2 * s, p.top + 4 * s, 2 * p.half + 4 * s, 2 * s, wood); c.rect(p.x - p.half - 2 * s, p.top + 4 * s, 2 * p.half + 4 * s, max(1, s / 2), woodL)
        for x in [p.x - p.half - 2 * s, p.x - s, p.x + p.half] { c.rect(x, p.top + 3 * s, 2 * s, 2 * s, C(0x0C0806)) }
        c.rect(p.x - p.half, p.top + 6 * s, 2 * p.half, 2 * s, woodD)
        for x in [p.x - p.half + s, p.x + p.half - 4 * s] { c.rect(x, p.top + 8 * s, 3 * s, g - p.top - 8 * s, woodD); c.rect(x, p.top + 8 * s, max(1, s / 2), g - p.top - 8 * s, wood) }
        // The bar: a thick lit top with three taps, panelled front, a brass foot rail, red-topped stools.
        let b = f.bar
        c.rect(b.x, b.top, c.w - b.x, 3 * s, woodL); c.rect(b.x, b.top, c.w - b.x, max(1, s / 2), C(0x9A6A40))
        c.rect(b.x, b.top + 3 * s, c.w - b.x, s, woodD)
        for k in 0..<3 { let tx = b.x + (10 + k * 5) * s; c.rect(tx, b.top - 4 * s, s, 4 * s, C(0xB0A080)); c.rect(tx - s / 2, b.top - 6 * s, 2 * s, 2 * s, k == 1 ? C(0x8A2A1E) : C(0x2A1A10)) }
        c.rect(b.x, b.top + 4 * s, c.w - b.x, g - b.top - 4 * s, C(0x3A2214))
        for x in stride(from: b.x + 2 * s, to: c.w, by: 12 * s) {
            c.rect(x, b.top + 6 * s, 9 * s, g - b.top - 9 * s, C(0x2E1A0E)); c.rect(x, b.top + 6 * s, 9 * s, max(1, s / 2), C(0x4A2E1A))
        }
        c.rect(b.x, g - 3 * s, c.w - b.x, s, C(0x8A6A34))
        for x in stride(from: b.x + 8 * s, to: c.w - 4 * s, by: 22 * s) {
            c.rect(x - 3 * s, g - 10 * s, 7 * s, 2 * s, C(0x6A2420)); c.rect(x - 3 * s, g - 10 * s, 7 * s, max(1, s / 2), C(0x8A3A30))
            c.rect(x, g - 8 * s, max(1, s), 8 * s, C(0x5A5A60)); c.rect(x - 2 * s, g - s, 5 * s, s, C(0x3A3A40))
        }
        huntRoadhouseFloor(c, g)
        // The floor: old boards, dark and scuffed.
        c.ground(g, C(0x3A281A), edge: C(0x4E3624), speck: C(0x2E2014), seed: 63)
        for x in stride(from: 0, to: c.w, by: 30 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x2C1E12)) }
    }

    /// What hangs on the Roadhouse's walls: a string of bare bulbs looped along the top, the hunters' corkboard of
    /// clippings and photos tied together with red string, the payphone, a deer's antlers over the back bar; on the
    /// screen saver, a big map of the States stuck with red pins, a row of framed photos and two mounted deer heads.
    private static func huntRoadhouseWall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRoadhouseFrame(c, g), e = huntRoadhouseExtras(c, g), tall = isTall(c)
        let woodD = C(0x2A180E), antler = C(0xD8C8A8), antlerD = C(0xA8946E)
        // The string of bulbs: a wire sagging between nails, the bulbs warm and unlit here (the moving layer lights them).
        for x in stride(from: 0, to: c.w, by: 3 * s) {
            let u = Double(x % (40 * s)) / Double(40 * s), y = e.bulbs + Int(sin(u * .pi) * Double(3 * s))
            c.rect(x, y, 3 * s, max(1, s / 2), C(0x1A120C))
            if x % (8 * s) == 0 { c.rect(x, y + s, s, 2 * s, C(0x8A6A3A)) }
        }
        // The corkboard: a cork panel in a dark frame, newspaper clippings, photos, a map scrap, pins and red string.
        let bx = e.board, by = g - 44 * s
        c.rect(bx - 15 * s, by - 9 * s, 30 * s, 20 * s, woodD); c.rect(bx - 14 * s, by - 8 * s, 28 * s, 18 * s, C(0xB08A5A))
        for i in 0..<40 { c.rect(bx - 14 * s + Int(noise(i + 1300) * Double(28 * s)), by - 8 * s + Int(noise(i + 1340) * Double(18 * s)), max(1, s), max(1, s), C(0x9A7448)) }
        let notes: [(Int, Int, Int, Int, UInt32)] = [(-12, -6, 8, 6, 0xE8E2CC), (-2, -7, 6, 7, 0xD8D0B8), (6, -5, 7, 5, 0xEEE8D4),
                                                     (-11, 2, 6, 6, 0x6A7A8A), (-3, 2, 9, 5, 0xE4DCC4), (8, 2, 5, 6, 0x8A6A5A)]
        var pins: [(Int, Int)] = []
        for (u, v, w, h, col) in notes {
            c.rect(bx + u * s, by + v * s, w * s, h * s, C(col))
            if col > 0xC00000 { for k in 0..<(h - 2) { c.rect(bx + u * s + s, by + (v + 1 + k) * s, (w - 2) * s, max(1, s / 2), C(0x8A8478)) } }
            pins.append((bx + (u + w / 2) * s, by + v * s))
            c.rect(bx + (u + w / 2) * s, by + v * s, max(1, s), max(1, s), C(0xD0302A))
        }
        for k in [0, 2, 4, 1] { let a = pins[k], b = pins[k == 4 ? 1 : k + 1]
            c.glowLine(Double(a.0), Double(a.1), Double(b.0), Double(b.1), core: C(0xC0282A), glow: C(0, 0), coreR: Double(s) * 0.35, glowR: Double(s) * 0.4) }
        // The payphone: a steel box on the wall, its handset hooked on the side, the coin slot and the keypad.
        let px = e.phone, py = g - 36 * s
        c.rect(px - 5 * s, py - 9 * s, 10 * s, 18 * s, C(0x6A6E76)); c.rect(px - 5 * s, py - 9 * s, 10 * s, s, C(0x9A9EA6))
        c.rect(px + 4 * s, py - 9 * s, s, 18 * s, C(0x44484E))
        c.rect(px - 3 * s, py - 6 * s, 5 * s, 2 * s, C(0x1A1C20)); c.rect(px - 3 * s, py - 2 * s, 5 * s, 6 * s, C(0x3A3E44))
        for k in 0..<6 { c.rect(px - 3 * s + (k % 3) * 2 * s, py - s + (k / 3) * 2 * s, s, s, C(0xC8CCD4)) }
        c.rect(px - 8 * s, py - 7 * s, 3 * s, 12 * s, C(0x1E2024)); c.rect(px - 8 * s, py - 7 * s, s, 12 * s, C(0x3A3E44))
        c.glowLine(Double(px - 7 * s), Double(py + 5 * s), Double(px - 2 * s), Double(py + 9 * s), core: C(0x1E2024), glow: C(0, 0), coreR: Double(s) * 0.4, glowR: Double(s) * 0.5)
        // A pair of deer antlers on a dark plaque over the back bar.
        let ax = c.w * 77 / 100, ay = g - 47 * s
        c.rect(ax - 3 * s, ay, 6 * s, 5 * s, woodD); c.rect(ax - 3 * s, ay, 6 * s, s, C(0x4A2E1A))
        for k in [-1, 1] {
            c.glowLine(Double(ax), Double(ay + s), Double(ax + k * 9 * s), Double(ay - 7 * s), core: antler, glow: C(0, 0), coreR: Double(s) * 0.7, glowR: Double(s) * 0.8)
            for (d, h) in [(3, 4), (6, 4), (8, 3)] {
                let tx = ax + k * d * s, ty = ay + s - d * 8 * s / 9
                c.glowLine(Double(tx), Double(ty), Double(tx + k * s), Double(ty - h * s), core: antlerD, glow: C(0, 0), coreR: Double(s) * 0.5, glowR: Double(s) * 0.6)
            }
        }
        guard tall else { return }
        // On the screen saver: the big map of the States, pinned all over with the hunts.
        let mx = c.w * 40 / 100, my = g - 118 * s
        c.rect(mx - 36 * s, my - 21 * s, 72 * s, 42 * s, woodD); c.rect(mx - 35 * s, my - 20 * s, 70 * s, 40 * s, C(0xE2D6B4))
        let land = C(0xB8C890), landD = C(0x8EA070)
        c.ellipse(mx - 2 * s, my, 30 * s, 15 * s, land); c.rect(mx - 30 * s, my - 10 * s, 56 * s, 14 * s, land)
        c.ellipse(mx + 24 * s, my + 10 * s, 5 * s, 6 * s, land)                      // Florida, roughly
        c.rect(mx - 30 * s, my + 4 * s, 22 * s, 6 * s, land); c.rect(mx - 12 * s, my + 8 * s, 10 * s, 7 * s, land)
        for x in stride(from: mx - 26 * s, to: mx + 26 * s, by: 8 * s) { c.rect(x, my - 12 * s, max(1, s / 2), 24 * s, landD) }
        for y in stride(from: my - 8 * s, to: my + 12 * s, by: 6 * s) { c.rect(mx - 30 * s, y, 56 * s, max(1, s / 2), landD) }
        for i in 0..<14 {
            let x = mx - 26 * s + Int(noise(i + 1400) * Double(50 * s)), y = my - 9 * s + Int(noise(i + 1420) * Double(18 * s))
            c.rect(x, y, 2 * s, 2 * s, C(0xD0302A)); c.rect(x, y, s, s, C(0xF08070))
        }
        // A row of framed photos.
        for (k, x) in stride(from: c.w * 62 / 100, to: c.w * 96 / 100, by: 16 * s).enumerated() {
            let y = g - 122 * s + (k % 2) * 3 * s
            c.rect(x, y, 12 * s, 14 * s, woodD); c.rect(x + s, y + s, 10 * s, 12 * s, C(0x8A8070 + UInt32(k % 3) * 0x080808))
            c.rect(x + 3 * s, y + 4 * s, 4 * s, 5 * s, C(0x4A4038)); c.rect(x + 2 * s, y + 9 * s, 7 * s, 4 * s, C(0x5A5048))
        }
        // Two mounted deer heads, facing each other across the room.
        for k in [-1, 1] {
            let hx = c.w / 2 + k * c.w * 43 / 100, hy = g - 150 * s
            c.rect(hx - 5 * s, hy - 2 * s, 10 * s, 12 * s, woodD)
            c.ellipse(hx, hy + 2 * s, 5 * s, 6 * s, C(0x8A6440)); c.ellipse(hx - k * 2 * s, hy + 7 * s, 3 * s, 3 * s, C(0x7A5434))
            c.rect(hx - k * 4 * s - s, hy + 7 * s, 2 * s, 2 * s, C(0x1A120C))
            c.rect(hx - 2 * s, hy, s, s, C(0x0C0806)); c.rect(hx + s, hy, s, s, C(0x0C0806))
            for side in [-1, 1] {
                c.glowLine(Double(hx + side * 2 * s), Double(hy - 3 * s), Double(hx + side * 10 * s), Double(hy - 14 * s), core: antler, glow: C(0, 0), coreR: Double(s) * 0.8, glowR: Double(s) * 0.9)
                c.glowLine(Double(hx + side * 6 * s), Double(hy - 8 * s), Double(hx + side * 5 * s), Double(hy - 14 * s), core: antlerD, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            }
        }
    }

    /// What stands on the Roadhouse's floor against the wall: a jukebox with its arched top, a round table with two
    /// chairs and empty bottles on it, and kegs and beer crates stacked in the corner.
    private static func huntRoadhouseFloor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), e = huntRoadhouseExtras(c, g)
        let wood = C(0x5A3620), woodL = C(0x7A4E30), woodD = C(0x2E1A0E)
        // The jukebox: a walnut cabinet with a rounded top, the chrome grille, the glass dome over the records and the
        // coloured light bands up its sides (the moving layer cycles them).
        let jx = e.jukebox, top = g - 26 * s
        c.ellipse(jx + 2 * s, g, 10 * s, s, C(0x0C0604, 0.5))
        c.rect(jx - 8 * s, top + 6 * s, 16 * s, g - top - 6 * s, wood); c.circle(jx, top + 6 * s, 8 * s, wood)
        c.rect(jx - 8 * s, top + 6 * s, s, g - top - 6 * s, woodL); c.rect(jx + 7 * s, top + 6 * s, s, g - top - 6 * s, woodD)
        c.circle(jx, top + 7 * s, 5 * s, C(0xD8E0E8)); c.circle(jx, top + 7 * s, 4 * s, C(0x3A4250))
        c.rect(jx - 4 * s, top + 13 * s, 8 * s, 4 * s, C(0xE8E0C8)); c.rect(jx - 4 * s, top + 13 * s, 8 * s, s, C(0xFFF4D8))
        for y in stride(from: top + 18 * s, to: g - 2 * s, by: 2 * s) { c.rect(jx - 5 * s, y, 10 * s, max(1, s / 2), C(0xB8C0C8)) }
        // The round table, its two chairs and a few bottles.
        let tx = e.table
        for k in [-1, 1] {
            let cx = tx + k * 11 * s
            c.rect(cx - 2 * s, g - 16 * s, 4 * s, 9 * s, wood); c.rect(cx - 3 * s, g - 8 * s, 6 * s, 2 * s, woodL)
            c.rect(cx - 3 * s, g - 6 * s, s, 6 * s, woodD); c.rect(cx + 2 * s, g - 6 * s, s, 6 * s, woodD)
        }
        c.ellipse(tx, g - 11 * s, 9 * s, 2 * s, woodL); c.rect(tx - 9 * s, g - 11 * s, 18 * s, s, wood)
        c.rect(tx - s, g - 10 * s, 2 * s, 9 * s, woodD); c.rect(tx - 4 * s, g - s, 8 * s, s, woodD)
        for (u, col) in [(-4, 0x3A6A3A), (-1, 0xB0782A), (3, 0x5A3A1A)] as [(Int, UInt32)] {
            c.rect(tx + u * s, g - 16 * s, 2 * s, 4 * s, C(col)); c.rect(tx + u * s, g - 18 * s, s, 2 * s, C(col))
            c.rect(tx + u * s, g - 16 * s, max(1, s / 2), 4 * s, lerp(C(col), C(0xFFFFFF), 0.35))
        }
        // Kegs and crates stacked in the corner on the left.
        for (k, (u, v)) in [(4, 0), (13, 0), (8, 1)].enumerated() {
            let kx = u * s, ky = g - 9 * s - v * 9 * s
            c.rect(kx - 4 * s, ky, 9 * s, 9 * s, C(0x8A8E96)); c.rect(kx - 4 * s, ky, 2 * s, 9 * s, C(0xB8BCC4))
            for b in [ky + s, ky + 7 * s] { c.rect(kx - 4 * s, b, 9 * s, s, C(0x4A4E56)) }
            if k == 2 { c.rect(kx, ky - s, s, s, C(0x4A4E56)) }
        }
        let cx = c.w * 2 / 100 + 20 * s
        for v in 0..<2 {
            let cy = g - 6 * s - v * 6 * s
            c.rect(cx, cy, 10 * s, 6 * s, C(0x8A5A2A)); c.rect(cx, cy, 10 * s, s, C(0xB07A40))
            c.rect(cx + 2 * s, cy + 2 * s, 6 * s, 2 * s, C(0xC8A040))
        }
    }

    /// The bar's life: the neon beer signs humming, one of them stuttering now and then, and the ceiling fan's blades
    /// going slowly round.
    static func huntRoadhouseLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntRoadhouseFrame(c, g)
        for (k, sg) in f.signs.enumerated() {
            var glow = 0.85 + 0.15 * sin(t * 3.1 + Double(k))
            let phase = (t + Double(k) * 4.3).truncatingRemainder(dividingBy: 9.0)
            if k == 1 && phase > 7.4 && phase < 8.2 && Int(t * 13) % 3 != 0 { glow = 0 }
            if glow > 0 { huntP2Neon(c, sg.kind, sg.x, sg.y, s, glow: glow) }
        }
        // The fan: four wooden blades seen edge-on from below the hub's height, turning about once every two seconds.
        for k in 0..<4 {
            let a = t * 3.0 + Double(k) * .pi / 2, reach = cos(a) * Double(16 * s)
            let front = sin(a) > 0
            let x0 = f.fan.x, x1 = f.fan.x + Int(reach)
            let col = front ? C(0x6A4428) : C(0x3A2416)
            c.rect(min(x0, x1), f.fan.y + (front ? s : 0), abs(x1 - x0) + 1, s, col)
            if front { c.rect(min(x0, x1), f.fan.y + s, abs(x1 - x0) + 1, max(1, s / 2), C(0x8A5E38)) }
        }
        c.rect(f.fan.x - 2 * s, f.fan.y - s, 4 * s, 2 * s, C(0x3A2A1E))
        // The string of bulbs, lit warm, one or two dimming now and then.
        let e = huntRoadhouseExtras(c, g)
        for x in stride(from: 0, to: c.w, by: 8 * s) {
            let u = Double(x % (40 * s)) / Double(40 * s), y = e.bulbs + Int(sin(u * .pi) * Double(3 * s)) + s
            let dim = sin(t * 1.7 + Double(x) * 0.37) > 0.93
            c.rect(x, y, s, 2 * s, dim ? C(0xB08A4A) : C(0xFFD890))
            if !dim { c.rect(x - s, y, 3 * s, 3 * s, C(0xFFD890, 0.18)) }
        }
        // The jukebox's light bands cycling through red, amber, green and blue, and its dome glowing.
        let jx = e.jukebox, top = g - 26 * s
        let cols = [C(0xFF4A3A), C(0xFFB040), C(0x5AD06A), C(0x5AB0FF)]
        for side in [-1, 1] {
            for k in 0..<5 {
                let col = cols[(Int(t * 3) + k + (side > 0 ? 2 : 0)) % 4]
                c.rect(jx + side * 6 * s - (side > 0 ? s : 0), top + 8 * s + k * 3 * s, s, 3 * s, col)
            }
        }
        c.circle(jx, top + 7 * s, 3 * s, C(0xFFE0A0, 0.25 + 0.1 * sin(t * 2)))
    }
}

// MARK: - A motel room

/// A framed print of three ducks flying over the reeds, `w` by `h` units with its top-left at (x, y).
private func huntP2Ducks(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ s: Int, seed: Int) {
    c.rect(x, y, w * s, h * s, C(0x8A6A2E)); c.rect(x, y, w * s, s, C(0xC8A050)); c.rect(x, y, s, h * s, C(0xB08A40))
    c.rect(x + w * s - s, y, s, h * s, C(0x5A4220)); c.rect(x, y + h * s - s, w * s, s, C(0x5A4220))
    c.rect(x + 2 * s, y + 2 * s, (w - 4) * s, (h - 4) * s, C(0x8A9AA0))
    c.rect(x + 2 * s, y + 2 * s + (h - 4) * s * 2 / 3, (w - 4) * s, (h - 4) * s / 3, C(0x7A8A70))
    for k in 0..<(w - 4) where noise(seed + k) > 0.45 {   // the reeds
        c.rect(x + (2 + k) * s, y + (h - 2) * s - (2 + Int(noise(seed + k + 50) * 3)) * s, max(1, s / 2), (2 + Int(noise(seed + k + 50) * 3)) * s, C(0x4A5A30))
    }
    for k in 0..<3 {   // the ducks, wings up, green heads, flying right and up
        let dx = x + (3 + k * (w - 8) / 3) * s, dy = y + (3 + (2 - k) * (h - 9) / 3 + 1) * s
        c.rect(dx, dy + s, 3 * s, s, C(0x6A4A2A)); c.rect(dx + 3 * s, dy, s, s, C(0x2A5A3A))
        c.rect(dx + s, dy, s, s, C(0x8A6A4A)); c.rect(dx, dy - s, s, s, C(0x8A6A4A))
    }
}

extension Scenes {
    /// Where things stand in the room, shared by the still picture and the moving layer: the chair rail, the window
    /// (its left edge, width, top and bottom), the two beds' middles, the TV screen (its top-left) and the door.
    static func huntMotelFrame(_ c: PixelCanvas, _ g: Int) -> (rail: Int, window: (x: Int, w: Int, top: Int, bottom: Int),
                                                              beds: [Int], tv: (x: Int, y: Int), door: (x: Int, w: Int), ceiling: Int) {
        let s = unit(g), tall = isTall(c)
        let tvX = c.w * 76 / 100
        return (g - 24 * s, (x: c.w * 3 / 100, w: 62 * s, top: g - 58 * s, bottom: g - 26 * s), [c.w * 33 / 100, c.w * 57 / 100],
                (x: tvX + 3 * s, y: g - 25 * s), (x: c.w * 89 / 100, w: 22 * s), tall ? g * 9 / 100 : -1)
    }

    /// A motel room somewhere on the interstate, the brothers' usual: loud brown-and-orange wallpaper over a plain
    /// dark wainscot (busy up high, calm where the crew stands), two beds with rust bedspreads, a lamp between them,
    /// a print of flying ducks, a boxy TV with rabbit ears on the dresser, the door on the right with a line of salt
    /// across its sill, and the window on the left, its blinds half up over the VACANCY sign outside. On the screen
    /// saver the wallpaper climbs to a stained ceiling, more duck prints hanging crooked on the way.
    static func huntMotel(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntMotelFrame(c, g), tall = isTall(c)
        // The wallpaper: big orange medallions on mustard-brown with teal hearts and diamonds between, half-dropped.
        let base = C(0x5A4430), ring = C(0x80492A), ringL = C(0x925834), teal = C(0x2E5E5C), cream = C(0xC09A58)
        c.rect(0, 0, c.w, f.rail, base)
        let tile = 14 * s
        for (row, cy) in stride(from: f.rail - 12 * s, to: -tile, by: -tile).enumerated() {
            for cx in stride(from: (row % 2) * tile / 2, to: c.w + tile, by: tile) {
                c.circle(cx, cy, 5 * s, ring); c.circle(cx - s, cy - s, 4 * s, ringL); c.circle(cx, cy, 3 * s, base)
                c.circle(cx, cy, 2 * s, teal); c.rect(cx, cy, max(1, s), max(1, s), cream)
                let dx = cx + tile / 2, dy = cy + tile / 2
                c.rect(dx - s, dy, 3 * s, s, teal); c.rect(dx, dy - s, s, 3 * s, teal)
            }
        }
        // A plain border strip of the paper above the rail, so the pattern stops before the crew's heads.
        c.rect(0, f.rail - 7 * s, c.w, 7 * s, C(0x4A3826)); c.rect(0, f.rail - 7 * s, c.w, s, C(0x6A4A2C))
        // On the screen saver: the popcorn ceiling with its water stain, the dome light, more duck prints going up.
        if tall {
            let ce = f.ceiling
            c.rect(0, 0, c.w, ce, C(0x5E584E))
            for i in 0..<(c.w * ce / 9) { c.px(Int(noise(i * 5 + 900) * Double(c.w)), Int(noise(i * 5 + 901) * Double(ce)), C(0x6E685C)) }
            c.rect(0, ce, c.w, 2 * s, C(0x4A3A2A)); c.rect(0, ce + 2 * s, c.w, s, C(0x2E2218))
            let sx = c.w * 70 / 100, sy = ce / 2
            for (k, r) in [18, 14, 10, 6].enumerated() {
                c.ellipse(sx + k * s, sy + k * s / 2, r * s * 3 / 2, min(ce / 2 - s, r * s * 2 / 3), k % 2 == 0 ? C(0x6E5638) : C(0x7A6648))
            }
            for k in 0..<3 { c.rect(sx - 10 * s + k * 9 * s, ce + 3 * s, 2 * s, (10 + k * 7) * s, C(0x5A4228, 0.6)) }   // runs down the paper
            c.ellipse(c.w * 36 / 100, ce + 4 * s, 9 * s, 4 * s, C(0xD8CCA8)); c.ellipse(c.w * 36 / 100, ce + 3 * s, 7 * s, 2 * s, C(0xF0E6C8))
            c.rect(c.w * 36 / 100 - 10 * s, ce + 3 * s, 20 * s, s, C(0x8A7A5A))
            huntP2Ducks(c, c.w * 10 / 100, g - 124 * s, 44, 28, s, seed: 11)
            huntP2Ducks(c, c.w * 42 / 100, g - 108 * s, 50, 32, s, seed: 23)
            huntP2Ducks(c, c.w * 76 / 100, g - 150 * s, 40, 26, s, seed: 37)
            huntP2Ducks(c, c.w * 56 / 100, g - 190 * s, 34, 22, s, seed: 41)
            // An air vent with a dark grille, and the smoke alarm, its little red dot.
            c.rect(c.w * 8 / 100, ce + 14 * s, 16 * s, 8 * s, C(0x8A8478))
            for y in stride(from: ce + 15 * s, to: ce + 21 * s, by: 2 * s) { c.rect(c.w * 8 / 100 + s, y, 14 * s, s, C(0x3A3630)) }
            c.ellipse(c.w * 58 / 100, ce + 4 * s, 4 * s, 2 * s, C(0xC8C0B0)); c.px(c.w * 58 / 100, ce + 5 * s, C(0xFF3A2A))
        }
        // The chair rail and the plain dark wainscot under it.
        c.rect(0, f.rail, c.w, g - f.rail, C(0x3A2A24))
        c.rect(0, f.rail, c.w, 2 * s, C(0x6A4A30)); c.rect(0, f.rail, c.w, max(1, s / 2), C(0x8A6440)); c.rect(0, f.rail + 2 * s, c.w, s, C(0x241A16))
        // The window: night outside, the VACANCY sign's dark box on its pole, the parking lot, the blinds half up,
        // heavy orange curtains either side.
        let w = f.window
        c.rect(w.x - 2 * s, w.top - 2 * s, w.w + 4 * s, w.bottom - w.top + 4 * s, C(0x8A8478))
        for k in 0..<4 {
            let y0 = w.top + (w.bottom - w.top) * k / 4, y1 = w.top + (w.bottom - w.top) * (k + 1) / 4
            c.rect(w.x, y0, w.w, y1 - y0, lerp(C(0x0E1222), C(0x1E2232), Double(k) / 3))
        }
        let mx = w.x + w.w / 2
        c.rect(mx - 30 * s / 2 - 2 * s, w.bottom - 17 * s, 34 * s, 14 * s, C(0x1A1418))
        c.rect(mx - s, w.bottom - 3 * s, 2 * s, 3 * s, C(0x2A2A30))
        huntP2Text(c, mx, w.bottom - 15 * s, "VACANCY", C(0x4A2032), 2 * s)
        c.rect(w.x, w.bottom - 2 * s, w.w, 2 * s, C(0x2A2A30))
        for y in stride(from: w.top, to: w.top + 15 * s, by: 3 * s) {
            c.rect(w.x, y, w.w, 2 * s, C(0xB0A690)); c.rect(w.x, y + s, w.w, max(1, s / 2), C(0x8A8270))
        }
        c.rect(w.x, w.top + 15 * s, w.w, 2 * s, C(0x9A9280))
        c.rect(w.x + 8 * s, w.top + 17 * s, max(1, s / 2), 6 * s, C(0xC8C0A8))
        for (cx, flip) in [(w.x - 8 * s, false), (w.x + w.w - s, true)] {
            c.rect(cx, w.top - 4 * s, 9 * s, w.bottom - w.top + 8 * s, C(0x7A3E1E))
            for k in 0..<3 { c.rect(cx + (flip ? 7 - k * 3 : 1 + k * 3) * s, w.top - 4 * s, s, w.bottom - w.top + 8 * s, C(0x5A2A14)) }
            c.rect(cx + (flip ? 8 : 0) * s, w.top - 4 * s, s, w.bottom - w.top + 8 * s, C(0x9A5A2E))
        }
        c.rect(w.x - 10 * s, w.top - 5 * s, w.w + 20 * s, s, C(0x6A6458))
        // A duck print over the lamp between the beds.
        let between = (f.beds[0] + f.beds[1]) / 2
        huntP2Ducks(c, between - 14 * s, g - 58 * s, 28, 19, s, seed: 5)
        // The lamp on the nightstand: a pleated cream shade glowing, a warm wash on the wall.
        for r in stride(from: 20 * s, to: 4 * s, by: -4 * s) { c.ellipse(between, g - 20 * s, r, r * 2 / 3, C(0xF0C070, 0.04)) }
        c.rect(between - 6 * s, g - 12 * s, 12 * s, 12 * s, C(0x4A2E1E)); c.rect(between - 6 * s, g - 12 * s, 12 * s, s, C(0x6A4428))
        c.rect(between - 5 * s, g - 8 * s, 10 * s, max(1, s / 2), C(0x2A1A10)); c.rect(between - s, g - 6 * s, 2 * s, s, C(0xB09040))
        c.rect(between - s, g - 15 * s, 2 * s, 3 * s, C(0x8A6A3A))
        for k in 0..<5 { let ww = (6 + k) * s; c.rect(between - ww / 2, g - 21 * s + k * s, ww, s, k % 2 == 0 ? C(0xF0D8A0) : C(0xE0C088)) }
        // The two beds: dark wood headboards, pillows, rust-striped spreads hanging to the floor.
        for (k, bx) in f.beds.enumerated() {
            c.rect(bx - 21 * s, g - 28 * s, 42 * s, 13 * s, C(0x4A2C1C)); c.rect(bx - 21 * s, g - 28 * s, 42 * s, s, C(0x6A4428))
            c.rect(bx - 19 * s, g - 26 * s, 17 * s, 9 * s, C(0x3E2416)); c.rect(bx + 2 * s, g - 26 * s, 17 * s, 9 * s, C(0x3E2416))
            for px in [bx - 17 * s, bx + 3 * s] { c.rect(px, g - 19 * s, 14 * s, 4 * s, C(0x9A9282)); c.rect(px, g - 19 * s, 14 * s, s, C(0xB0A898)) }
            let spread = k == 0 ? C(0x7A3A22) : C(0x6A4226), spreadD = lerp(spread, C(0x140A08), 0.4)
            c.rect(bx - 23 * s, g - 15 * s, 46 * s, 6 * s, spread); c.rect(bx - 23 * s, g - 15 * s, 46 * s, s, lerp(spread, C(0xE0A060), 0.25))
            c.rect(bx - 23 * s, g - 9 * s, 46 * s, 7 * s, spreadD)
            for x in stride(from: bx - 21 * s, to: bx + 22 * s, by: 6 * s) { c.rect(x, g - 9 * s, max(1, s / 2), 7 * s, lerp(spreadD, C(0x000000), 0.3)) }
            c.rect(bx - 23 * s, g - 12 * s, 46 * s, max(1, s / 2), C(0xB07040, 0.6))
            c.rect(bx - 23 * s, g - 2 * s, 46 * s, 2 * s, C(0x140C0A))
        }
        // The dresser and the TV: a wood-grain box with a grey screen, rabbit ears, a knob or two.
        let tv = f.tv, dx = tv.x - 9 * s
        c.rect(dx, g - 12 * s, 34 * s, 12 * s, C(0x4E321E)); c.rect(dx, g - 12 * s, 34 * s, s, C(0x6E4A2E))
        for k in 0..<2 { c.rect(dx + 2 * s, g - 10 * s + k * 5 * s, 30 * s, 4 * s, C(0x3A2416)); c.rect(dx + 16 * s, g - 8 * s + k * 5 * s, 2 * s, s, C(0xB09040)) }
        c.rect(tv.x - 3 * s, tv.y - 2 * s, 22 * s, 15 * s, C(0x4A3424)); c.rect(tv.x - 3 * s, tv.y - 2 * s, 22 * s, s, C(0x6A4E36))
        c.rect(tv.x, tv.y, 13 * s, 10 * s, C(0x1A222C))
        c.rect(tv.x + 15 * s, tv.y + s, 2 * s, 2 * s, C(0x8A8070)); c.rect(tv.x + 15 * s, tv.y + 5 * s, 2 * s, 2 * s, C(0x8A8070))
        c.glowLine(Double(tv.x + 8 * s), Double(tv.y - 2 * s), Double(tv.x + 2 * s), Double(tv.y - 14 * s), core: C(0x9A9A9A), glow: C(0, 0), coreR: Double(s) * 0.4, glowR: Double(s) * 0.5)
        c.glowLine(Double(tv.x + 8 * s), Double(tv.y - 2 * s), Double(tv.x + 16 * s), Double(tv.y - 13 * s), core: C(0x9A9A9A), glow: C(0, 0), coreR: Double(s) * 0.4, glowR: Double(s) * 0.5)
        // The door: brown, two panels, the chain hanging, a brass knob, a DO NOT DISTURB tag (blank) on the handle.
        let d = f.door
        c.rect(d.x - 2 * s, g - 48 * s, d.w + 4 * s, 48 * s, C(0x6A5440))
        c.rect(d.x, g - 46 * s, d.w, 46 * s, C(0x5A3422)); c.rect(d.x, g - 46 * s, s, 46 * s, C(0x7A4A30))
        for y in [g - 42 * s, g - 22 * s] { c.rect(d.x + 3 * s, y, d.w - 6 * s, 17 * s, C(0x4A2A1A)); c.rect(d.x + 3 * s, y, d.w - 6 * s, max(1, s / 2), C(0x6A4028)) }
        c.circle(d.x + d.w / 2, g - 36 * s, max(1, s / 2), C(0xB0A070))
        c.rect(d.x + 3 * s, g - 25 * s, 2 * s, 2 * s, C(0xC8A040))
        for k in 0..<4 { c.rect(d.x + 5 * s + k * s, g - 30 * s + k * s, s, s, C(0x9A9A90)) }
        c.rect(d.x + 2 * s, g - 22 * s, 4 * s, 6 * s, C(0xC0B8A0))
        // The carpet: dark brown-plum shag, and the line of salt across the door's sill.
        c.ground(g, C(0x3A2A2A), edge: C(0x4E3A36), speck: C(0x2E2020), seed: 71)
        for i in 0..<(d.w / max(1, s / 2) + 8) {
            let x = d.x - 3 * s + i * max(1, s / 2) + Int(noise(i + 800) * 2)
            c.rect(x, g + 1 + Int(noise(i + 820) * 2.4) * max(1, s / 2), max(1, s / 2) + (noise(i + 840) > 0.6 ? 1 : 0), max(1, s), C(0xECE6DA))
        }
    }

    /// The room's life: the VACANCY sign outside blinking pink through the window and its glow slipping through the
    /// slats of the blinds, and the TV's blue light flickering with whatever's on.
    static func huntMotelLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntMotelFrame(c, g), w = f.window
        if t.truncatingRemainder(dividingBy: 2.6) < 1.8 {
            let mx = w.x + w.w / 2
            for r in stride(from: 24 * s, to: 6 * s, by: -5 * s) { c.ellipse(mx, w.bottom - 10 * s, r * 2, r / 2 + 3 * s, C(0xFF4A8A, 0.05)) }
            huntP2Text(c, mx, w.bottom - 15 * s, "VACANCY", C(0xFF5A8E), 2 * s)
            for y in stride(from: w.top + 2 * s, to: w.top + 15 * s, by: 3 * s) { c.rect(w.x, y, w.w, max(1, s / 2), C(0xFF4A8A, 0.35)) }
            c.rect(w.x + 2 * s, w.bottom + 3 * s, w.w - 4 * s, s, C(0xFF4A8A, 0.18))
        }
        let tv = f.tv
        let k = 0.55 + 0.3 * sin(t * 7.3) * sin(t * 2.1) + (Int(t * 5) % 7 == 0 ? 0.15 : 0)
        let screen = lerp(C(0x2A3E5A), C(0x9AC0E8), k)
        c.rect(tv.x, tv.y, 13 * s, 10 * s, screen)
        for y in stride(from: tv.y, to: tv.y + 10 * s, by: 2 * s) { c.rect(tv.x, y, 13 * s, max(1, s / 2), screen.alpha(0.6)) }
        c.rect(tv.x + s, tv.y + (Int(t * 9) % 9) * s, 11 * s, max(1, s / 2), C(0xE0F0FF, 0.5))
        for r in stride(from: 22 * s, to: 8 * s, by: -5 * s) { c.ellipse(tv.x + 6 * s, tv.y + 5 * s, r, r * 2 / 3, C(0x8AB8F0, 0.03 * k)) }
    }
}

// MARK: - The crossroads

extension Scenes {
    /// Where things stand at the crossroads, shared by the still picture and the moving layer: the horizon, the
    /// point the far road runs off to, the dead tree's foot, and the crow's perch on it.
    static func huntCrossroadsFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, vanish: Int, tree: Int, perch: (x: Int, y: Int)) {
        let s = unit(g)
        let tree = c.w * 20 / 100
        return (g - 28 * s, c.w * 53 / 100, tree, (x: tree + 17 * s, y: g - 47 * s))
    }

    /// The crossroads at night, where deals are made: a dark denim sky with a moon, flat Kansas fields running off
    /// to a low line of trees, a dirt road meeting the one across the front, telephone poles along it, a far
    /// farmhouse with one light, and one dead tree on the left with a crow in it. On the screen saver the moon is
    /// big and low over the fields, the sky full of stars.
    static func huntCrossroads(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntCrossroadsFrame(c, g), tall = isTall(c), h = f.horizon
        // The sky, stars and moon.
        if tall {
            c.gradient(0, h, C(0x080C18), C(0x3A4660), bands: 10)
            c.stars(0, h - 30 * s, density: 40, seed: 8)
            let mx = c.w * 70 / 100, my = g * 30 / 100, r = 32 * s
            for k in stride(from: 4, to: 0, by: -1) { c.circle(mx, my, r + k * 8 * s, C(0xC8D4E8, 0.05)) }
            c.circle(mx, my, r, C(0xDCDCCC)); c.circle(mx + 4 * s, my + 3 * s, r - 3 * s, C(0xE8E6D6))
            for (u, v, rr) in [(-12, -8, 7), (8, -14, 4), (10, 6, 9), (-6, 12, 5), (-18, 6, 3), (16, -2, 3)] as [(Int, Int, Int)] {
                c.circle(mx + u * s, my + v * s, rr * s, C(0xC4C2B2)); c.circle(mx + u * s + s, my + v * s + s, rr * s - s, C(0xCECCBC))
            }
            for (xp, y, len) in [(60, my + 18 * s, 120), (78, my - 30 * s, 80), (30, g * 52 / 100, 150), (20, g * 20 / 100, 110), (52, g * 66 / 100, 90)] as [(Int, Int, Int)] {
                let x = c.w * xp / 100
                c.ellipse(x, y, len * s / 2, 3 * s, C(0x1C2438, 0.75)); c.ellipse(x - len * s / 8, y - 2 * s, len * s / 4, 3 * s, C(0x1C2438, 0.75))
                c.rect(x - len * s / 4, y - 5 * s, len * s / 3, max(1, s), C(0x7A88A8, 0.4))
            }
        } else {
            c.gradient(0, h, C(0x161E34), C(0x46506A), bands: 6)
            c.stars(0, h - 8 * s, density: 60, seed: 8)
            let mx = c.w * 80 / 100, my = 13 * s
            for k in stride(from: 3, to: 0, by: -1) { c.circle(mx, my, 6 * s + k * 3 * s, C(0xC8D4E8, 0.06)) }
            c.circle(mx, my, 6 * s, C(0xDCDCCC)); c.circle(mx + s, my + s, 5 * s, C(0xE8E6D6)); c.circle(mx - 2 * s, my - s, s, C(0xC4C2B2))
        }
        // The far line of trees, a grain silo, and the farmhouse with its one lit window.
        c.dunes(base: h, amp: Double(s) * 1.5, freq: 0.09, phase: 0.4, bottom: h + s, C(0x1A1E2A))
        let fx = c.w * 9 / 100
        c.rect(fx, h - 5 * s, 9 * s, 5 * s, C(0x1A1E2A))
        for k in 0..<3 { c.rect(fx - s + k * s, h - 6 * s - k * s, 11 * s - 2 * k * s, s, C(0x1A1E2A)) }
        c.rect(fx + 2 * s, h - 3 * s, s, s, C(0xF0B050))
        let sx = c.w * 88 / 100
        c.rect(sx, h - 12 * s, 5 * s, 12 * s, C(0x1E2230)); c.ellipse(sx + 2 * s, h - 12 * s, 2 * s, s, C(0x1E2230))
        c.rect(sx + 5 * s, h - 6 * s, 6 * s, 6 * s, C(0x1A1E2A))
        // The fields: flat stubble in bands, closer ones wider and a shade lighter where the moon catches them.
        var y = h + s, band = max(1, s), k = 0
        while y < g {
            c.rect(0, y, c.w, band, k % 2 == 0 ? C(0x2A2A24) : C(0x34322A))
            y += band; band += max(1, s / 2) + (k % 3 == 0 ? s : 0); k += 1
        }
        // The far road, running straight off to the trees, ruts down it, grass on its shoulders.
        for yy in h..<g {
            let a = Double(yy - h) / Double(g - h)
            let cx = Double(f.vanish) + a * Double(c.w * 50 / 100 - f.vanish), half = Double(s) + a * Double(34 * s)
            let dirt = lerp(C(0x2E2C2A), C(0x54483A), (a * 4).rounded(.down) / 4 + 0.15)
            c.rect(Int(cx - half), yy, Int(half * 2), 1, dirt)
            if a > 0.2 {
                let rut = lerp(dirt, C(0x1A1612), 0.25)
                c.rect(Int(cx - half * 0.55), yy, max(1, Int(half * 0.14)), 1, rut); c.rect(Int(cx + half * 0.4), yy, max(1, Int(half * 0.14)), 1, rut)
            }
            if yy % 3 == 0 { c.rect(Int(cx - half) - s, yy, s, 1, C(0x3A3A26)); c.rect(Int(cx + half), yy, s, 1, C(0x3A3A26)) }
        }
        // Telephone poles marching along a far road across the fields, the wire sagging between them.
        let poleBase = h + 4 * s, poleH = 16 * s
        var last: (Int, Int)? = nil
        for x in stride(from: c.w * 6 / 100, to: c.w + 60 * s, by: 54 * s) {
            c.rect(x, poleBase - poleH, max(1, s), poleH, C(0x201A18)); c.rect(x - 3 * s, poleBase - poleH + s, 7 * s, max(1, s), C(0x201A18))
            if let (lx, ly) = last {
                func wire(_ a: Double) -> (Double, Double) { (Double(lx) + a * Double(x - lx), Double(ly) + sin(a * .pi) * Double(3 * s)) }
                for k in 1...5 {
                    let p0 = wire(Double(k - 1) / 5), p1 = wire(Double(k) / 5)
                    c.glowLine(p0.0, p0.1, p1.0, p1.1, core: C(0x1A1618), glow: C(0, 0), coreR: Double(s) * 0.5, glowR: Double(s) * 0.55)
                }
            }
            last = (x, poleBase - poleH + s)
        }
        // The dead tree on the left: a twisted grey trunk lit on its moon side, bare branches reaching out, one
        // long branch to the right where the crow sits.
        let tx = f.tree, bark = C(0x2E2824), barkL = C(0x4E4640)
        let limbs: [(Double, Double, Double, Double, Double)] = [
            (0, 0, 1, -24, 3.0), (1, -24, -2, -38, 2.0), (-2, -38, -1, -52, 1.2), (1, -24, 8, -36, 1.4), (8, -36, 18, -46, 1.0),
            (18, -46, 28, -48, 0.7), (-1, -30, -12, -40, 1.1), (-12, -40, -16, -50, 0.7), (-12, -40, -22, -42, 0.6),
            (-2, -38, 4, -50, 0.7), (6, -33, 10, -28, 0.5), (-6, -34, -8, -30, 0.4), (-1, -52, 2, -58, 0.5),
        ]
        for (x0, y0, x1, y1, w) in limbs {
            c.glowLine(Double(tx) + x0 * Double(s), Double(g) + y0 * Double(s), Double(tx) + x1 * Double(s), Double(g) + y1 * Double(s),
                       core: bark, glow: C(0, 0), coreR: Double(s) * w, glowR: Double(s) * w + 0.3)
        }
        c.glowLine(Double(tx) - Double(s) * 1.6, Double(g - 2 * s), Double(tx) - Double(s) * 0.4, Double(g - 26 * s), core: barkL, glow: C(0, 0),
                   coreR: Double(s) * 0.5, glowR: Double(s) * 0.55)
        c.rect(tx - 4 * s, g - 2 * s, 9 * s, 2 * s, bark); c.rect(tx - 6 * s, g - s, 4 * s, s, bark); c.rect(tx + 4 * s, g - s, 4 * s, s, bark)
        // An old wooden signpost at the corner, its board long since blank.
        let px = c.w * 74 / 100
        c.rect(px, g - 30 * s, 2 * s, 29 * s, C(0x3A3028)); c.rect(px, g - 30 * s, max(1, s / 2), 29 * s, C(0x5A4A3A))
        c.rect(px - 9 * s, g - 28 * s, 18 * s, 4 * s, C(0x4A3E32)); c.rect(px - 9 * s, g - 28 * s, 18 * s, max(1, s / 2), C(0x6A5A48))
        c.rect(px + 2 * s, g - 28 * s, 7 * s, 4 * s, C(0x3A3028, 0.6))
        // The road across the front: pale dusty dirt, wheel ruts, a few stones.
        c.ground(g, C(0x4A3E30), edge: C(0x5E4E3C), speck: C(0x3A3026), seed: 84)
        for yy in [g + 3, g + 7] where yy < c.h { c.rect(0, yy, c.w, max(1, s / 2), C(0x403428)) }
    }

    /// The crossroads' life: dust lifting off the road and drifting across it in faint wisps, and the crow on its
    /// branch, mostly still, now and then turning its head, shuffling along or opening its wings.
    static func huntCrossroadsLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntCrossroadsFrame(c, g)
        for k in 0..<3 {
            let span = Double(c.w + 80 * s)
            let x = Int((t * Double(9 * s) * (1 + Double(k) * 0.3) + Double(k) * span / 3).truncatingRemainder(dividingBy: span)) - 40 * s
            let y = g - (2 + k * 3) * s
            for j in 0..<5 {   // a loose puff: a few soft blobs trailing behind, rising a little as they go
                let jx = x - j * 7 * s, jy = y - j * s / 2 - Int(sin(t * 1.3 + Double(j + k)) * Double(s))
                c.ellipse(jx, jy, (7 - j) * s, max(1, s) + (j < 2 ? s : 0), C(0xA8946E, 0.11 - Double(j) * 0.015))
            }
        }
        // The crow: what it's doing this moment of its eight-second round.
        let phase = t.truncatingRemainder(dividingBy: 8.0)
        let lookBack = phase > 3 && phase < 4.4, flap = phase > 6.2 && phase < 6.9
        let hop = phase > 4.4 && phase < 6.2 ? 2 * s : 0
        let x = f.perch.x + hop, y = f.perch.y, black = C(0x0E0E14), sheen = C(0x2A2E44)
        c.rect(x - 3 * s, y - 3 * s, 6 * s, 3 * s, black); c.rect(x - 2 * s, y - 3 * s, 4 * s, s, sheen)
        c.rect(x - 5 * s, y - 2 * s, 2 * s, s, black)   // the tail
        c.rect(x - s, y, max(1, s / 2), s, C(0x3A3630)); c.rect(x + s, y, max(1, s / 2), s, C(0x3A3630))
        let hx = lookBack ? x - 3 * s : x + 2 * s
        c.rect(hx, y - 5 * s, 2 * s, 2 * s, black)
        c.rect(lookBack ? hx - s : hx + 2 * s, y - 4 * s, s, max(1, s / 2) + (s > 1 ? s / 2 : 0), C(0x4A4640))
        c.px(lookBack ? hx : hx + s, y - 5 * s, C(0xC8C0A0))
        if flap {
            c.rect(x - 4 * s, y - 6 * s, 3 * s, 3 * s, black); c.rect(x + s, y - 6 * s, 3 * s, 3 * s, black)
            c.rect(x - 5 * s, y - 7 * s, 2 * s, s, black); c.rect(x + 3 * s, y - 7 * s, 2 * s, s, black)
        }
    }
}
