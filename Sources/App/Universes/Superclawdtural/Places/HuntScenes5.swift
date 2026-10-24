import Foundation

// Places: Roosevelt Asylum, a roadside diner by day, the top floor of Roman Enterprises and Apocalypse World. Each place
// is a `Place` in the dictionary below (its name, the tint of the window's card area under it, its still picture and
// what moves there) and its drawing in an extension of `Scenes`, with a frame function the still picture and the
// moving layer share so they line up. Check them with `build/preview place out.png <key>`, at window size and at
// screen-saver size.
//
// The asylum is peeling hospital green in the dark; the diner is chrome, red vinyl and mint enamel in daylight (not the
// Roadhouse's wood and amber), its floor a mid-tone checker, never white; Roman Enterprises is black glass and steel
// over a city at night, with the Leviathans' black goo; Apocalypse World is a burnt-out city under an orange sky. The
// floor and the band just above it stay plain and mid-to-dark so the crew's white outlines and names read; the busy
// detail goes higher up and at the sides; props keep their size in `Scenes.unit(g)` steps. The signs (WARD C, PIE,
// OPEN, ROMAN, MENU, EAT) are lettered in whole dots so they read in the window.

let huntScenes5: [Location: Place] = [
    .huntAsylum: Place(name: "Roosevelt Asylum", panel: 0x101812, still: Scenes.huntAsylum, moving: Scenes.huntAsylumLife),
    .huntDiner: Place(name: "A Roadside Diner", panel: 0x241618, still: Scenes.huntDiner, moving: Scenes.huntDinerLife),
    .huntRoman: Place(name: "Roman Enterprises", panel: 0x0C1018, still: Scenes.huntRoman, moving: Scenes.huntRomanLife),
    .huntApocalypse: Place(name: "Apocalypse World", panel: 0x24100A, still: Scenes.huntApocalypse, moving: Scenes.huntApocalypseLife),
]

// MARK: - Lettering and small helpers

/// A blocky 5-row alphabet, three dots wide (M and W five, N four), for the signs.
private let huntP5Glyphs: [Character: String] = [
    "A": "010101111101101", "C": "011100100100011", "D": "110101101101110", "E": "111100110100111",
    "I": "111010010010111", "M": "1000111011101011000110001", "N": "10011101101110011001", "O": "010101101101010",
    "P": "111101111100100", "R": "110101110101101", "S": "011100010001110", "T": "111010010010010",
    "U": "101101101101111", "W": "1000110001101011101110001",
]

/// How wide `text` comes out at `p` pixels a dot (a space is two dots).
private func huntP5Width(_ text: String, _ p: Int) -> Int {
    text.reduce(0) { $0 + (huntP5Glyphs[$1].map { $0.count / 5 + 1 } ?? 3) } * p - p
}

/// Lettering, `p` pixels a dot, centred on `x` with its top on row `y`.
private func huntP5Text(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ col: Px, _ p: Int) {
    var cx = x - huntP5Width(text, p) / 2
    for ch in text {
        guard let bits = huntP5Glyphs[ch] else { cx += 3 * p; continue }
        let gw = bits.count / 5
        for (i, b) in bits.enumerated() where b == "1" {
            c.rect(cx + (i % gw) * p, y + (i / gw) * p, p, p, col)
        }
        cx += (gw + 1) * p
    }
}

/// A hard-edged line `r` pixels either side of its middle, with no glow.
private func huntP5Line(_ c: PixelCanvas, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ col: Px, _ r: Double) {
    c.glowLine(Double(x0), Double(y0), Double(x1), Double(y1), core: col, glow: C(0, 0), coreR: r, glowR: r + 0.05)
}

/// A ring: the band between radius `r` and `r - thick`.
private func huntP5Ring(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, _ thick: Int, _ col: Px) {
    guard r > 0 else { return }
    let outer = Double(r) + 0.35, inner = Double(r - thick) + 0.35
    for dy in -r...r {
        for dx in -r...r {
            let d = Double(dx * dx + dy * dy).squareRoot()
            if d <= outer && d > inner { c.px(cx + dx, cy + dy, col) }
        }
    }
}

// MARK: - Roosevelt Asylum

/// A patch where the green paint has peeled off: bare plaster with the paint's edge shadowed along its top and left,
/// a lit lip of curling paint under it, and now and then a flake hanging loose.
private func huntP5Peel(_ c: PixelCanvas, _ x: Int, _ y: Int, _ rx: Int, _ ry: Int, _ s: Int, seed: Int) {
    c.ellipse(x, y, rx, ry, C(0x4A4838))
    c.ellipse(x + s, y + max(1, s / 2), max(1, rx - s), max(1, ry - s / 2), C(0x76725C))
    c.rect(x - rx / 2, y + ry + max(1, s / 2), rx, max(1, s / 2), C(0x6E8A70))
    if noise(seed * 5 + 1) > 0.45 {
        c.rect(x + rx - s, y + ry, 2 * s, s, C(0x6E8A70)); c.rect(x + rx, y + ry + s, s, 2 * s, C(0x587260))
    }
}

/// One of the ward's heavy cell doors, `w` wide (narrower when it swings), standing `h` tall from row `top`: painted
/// steel lit down its hinge side, a small barred window with dark beyond, the meal hatch, a sunken lower panel, the
/// scuffed kick plate and the handle. `shade` darkens it as it turns away from the light.
private func huntP5CellDoor(_ c: PixelCanvas, _ x: Int, _ top: Int, _ w: Int, _ h: Int, _ s: Int, shade: Double) {
    let base = lerp(C(0x56665A), C(0x222A24), shade), lit = lerp(C(0x768A7A), C(0x34403A), shade)
    let dark = lerp(C(0x3A463C), C(0x161C18), shade)
    c.rect(x, top, w, h, base)
    c.rect(x, top, s, h, lit); c.rect(x + w - s, top, s, h, dark)
    let wx = x + w * 6 / 22, ww = max(2 * s, w * 10 / 22)
    c.rect(wx - s, top + 4 * s, ww + 2 * s, 10 * s, dark)
    c.rect(wx, top + 5 * s, ww, 8 * s, C(0x0A100E))
    for k in 1..<4 { c.rect(wx + ww * k / 4, top + 5 * s, s, 8 * s, lit) }
    c.rect(wx, top + 18 * s, ww, 3 * s, dark); c.rect(wx, top + 18 * s, ww, max(1, s / 2), lit)
    let px = x + w * 3 / 22, pw = max(2 * s, w * 16 / 22)
    c.rect(px, top + 24 * s, pw, h - 30 * s, dark); c.rect(px + s, top + 25 * s, max(1, pw - 2 * s), max(1, h - 32 * s), base)
    c.rect(x + s, top + h - 5 * s, max(1, w - 2 * s), 4 * s, lerp(C(0x747872), C(0x34363A), shade))
    c.rect(x + s, top + h - 5 * s, max(1, w - 2 * s), max(1, s / 2), lerp(C(0x9A9E96), C(0x44464A), shade))
    c.rect(x + w - 4 * s, top + 15 * s, 2 * s, 3 * s, lerp(C(0x9A9A8A), C(0x4A4A44), shade))
    // Rust where the paint has chipped.
    c.rect(x + w / 3, top + 2 * s, 2 * s, s, C(0x6A4A34)); c.rect(x + w * 2 / 3, top + h - 8 * s, s, 2 * s, C(0x6A4A34))
}

/// The old wheelchair, facing left, its big wheel's hub at `x`: a spoked wheel with its hand rim, a cracked leather
/// sling seat and back, chrome tubes gone spotty with rust, the push handles, the footrest and a little front caster.
private func huntP5Wheelchair(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int) {
    let tube = C(0x8A8E88), tubeL = C(0xB4B8B0), tubeD = C(0x5A5E58), rust = C(0x7A4A2E)
    let leather = C(0x5A4232), leatherL = C(0x7A5C44), leatherD = C(0x3A2A20)
    let hub = (x: x, y: g - 9 * s), r = 9 * s
    // The back and its frame, the push handles.
    huntP5Line(c, x + 5 * s, g - 9 * s, x + 7 * s, g - 28 * s, tubeD, Double(s) * 0.6)
    c.rect(x + 2 * s, g - 27 * s, 4 * s, 13 * s, leather); c.rect(x + 2 * s, g - 27 * s, s, 13 * s, leatherL)
    c.rect(x + 2 * s, g - 21 * s, 4 * s, max(1, s / 2), leatherD)
    c.rect(x + 7 * s, g - 28 * s, 4 * s, s, tubeL); c.rect(x + 10 * s, g - 28 * s, 2 * s, 2 * s, C(0x2A2622))
    // The seat, the armrest on its post.
    c.rect(x - 9 * s, g - 15 * s, 14 * s, 3 * s, leather); c.rect(x - 9 * s, g - 15 * s, 14 * s, s, leatherL)
    c.rect(x - 4 * s, g - 14 * s, 3 * s, max(1, s / 2), leatherD)
    c.rect(x - 8 * s, g - 20 * s, 12 * s, s, tubeL); c.rect(x - 8 * s, g - 19 * s, 12 * s, s, tubeD)
    c.rect(x - 7 * s, g - 19 * s, s, 4 * s, tube); c.rect(x + 2 * s, g - 19 * s, s, 4 * s, tube)
    // The leg rest down to the footplate, and the caster.
    huntP5Line(c, x - 8 * s, g - 12 * s, x - 13 * s, g - 4 * s, tube, Double(s) * 0.6)
    c.rect(x - 17 * s, g - 4 * s, 6 * s, s, tubeL)
    huntP5Line(c, x - 6 * s, g - 12 * s, x - 9 * s, g - 3 * s, tubeD, Double(s) * 0.5)
    huntP5Ring(c, x - 9 * s, g - 2 * s, 2 * s, s, C(0x1E1E1C)); c.px(x - 9 * s, g - 2 * s, tube)
    // The big wheel: tyre, spokes, hand rim, hub.
    huntP5Ring(c, hub.x, hub.y, r, s + s / 2, C(0x1C1C1A))
    for k in 0..<8 {
        let a = Double(k) * .pi / 4 + 0.2
        huntP5Line(c, hub.x, hub.y, hub.x + Int(cos(a) * Double(r - s)), hub.y + Int(sin(a) * Double(r - s)), tubeD, Double(s) * 0.35)
    }
    huntP5Ring(c, hub.x, hub.y, r - 2 * s, max(1, s / 2), tube)
    c.circle(hub.x, hub.y, s, tubeL)
    for (u, v) in [(-6, -19), (3, -19), (-11, -8)] { c.rect(x + u * s, g + v * s, s, s, rust) }
}

extension Scenes {
    /// Where things stand in the corridor, shared by the still picture and the moving layer: the chair rail, the cell
    /// doors (their left edges; the first one stands open), the doors' top row, the wheelchair, the ceiling's line
    /// (the top of the picture in the window) and the pipe run under it.
    static func huntAsylumFrame(_ c: PixelCanvas, _ g: Int) -> (rail: Int, doors: [Int], doorTop: Int, chair: Int,
                                                               ceiling: Int, pipe: Int) {
        let s = unit(g), tall = isTall(c)
        let ceiling = tall ? g * 26 / 100 : 0
        let step = max(80 * s, c.w * 26 / 100)
        let doors = Array(stride(from: c.w * 13 / 100, to: c.w * 72 / 100, by: step))
        return (g - 18 * s, doors, g - 40 * s, c.w * 88 / 100, ceiling, ceiling + 2 * s)
    }

    /// Roosevelt Asylum after dark, the abandoned ward the Ghostfacers came to film: a long corridor wall of hospital
    /// green gone grey with damp and peeling off in curls to the plaster, glazed tiles below a chair rail with some
    /// fallen out, a row of heavy cell doors with barred windows (the first one standing open on the dark), WARD C
    /// stencilled over the middle one with its paint run, a noticeboard of curling notices, a stopped clock with a
    /// cracked face, pipes along the top dripping rust, caged bulbs dead in their cages, a barred window letting in
    /// moonlight, a broken strip light hanging by one chain, a cold radiator, and an old wheelchair left in the corner.
    /// On the screen saver the corridor rises to a high cracked ceiling with a hole through to the laths, arched
    /// windows up the wall throwing moonlight down, and enamel lamps hanging on long flexes.
    static func huntAsylum(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntAsylumFrame(c, g), tall = isTall(c)
        let paint = C(0x4A6250), paintL = C(0x6A8468)
        let iron = C(0x3A3E38), ironL = C(0x5E6258), ironD = C(0x22261F)
        if tall { huntAsylumCeiling(c, g) }
        // The wall: hospital green gone grey with damp, darkest up high where no light reaches.
        c.gradient(f.ceiling, f.rail, C(0x1A221C), paint, bands: 7)
        for i in 0..<max(1, c.w / (30 * s)) {   // damp running down from the top
            let x = Int(noise(i + 900) * Double(c.w)), w = (6 + Int(noise(i + 930) * 14)) * s
            let h = (8 + Int(noise(i + 960) * Double(tall ? 50 : 18))) * s
            c.rect(x, f.ceiling, w, h, C(0x0E140E, 0.2)); c.rect(x + w / 4, f.ceiling + h, w / 2, h / 2, C(0x0E140E, 0.15))
        }
        // Paint peeling off in patches, most of them high on the wall.
        let patchTop = tall ? f.ceiling + 8 * s : f.ceiling + 7 * s
        let span = Double(f.rail - 6 * s - patchTop)
        for i in 0..<max(1, c.w * (tall ? 3 : 1) / (20 * s)) {
            let x = Int(noise(i + 700) * Double(c.w))
            let y = patchTop + Int(noise(i + 740) * noise(i + 741) * span)
            let rx = (2 + Int(noise(i + 780) * 5)) * s, ry = (1 + Int(noise(i + 800) * 2.5)) * s
            huntP5Peel(c, x, y, rx, ry, s, seed: i)
        }
        if tall { huntAsylumHighWall(c, g) }
        // The pipes along the top, a joint collar now and then with rust running down the wall from it.
        let py = f.pipe
        c.rect(0, py, c.w, 3 * s, iron); c.rect(0, py, c.w, s, ironL); c.rect(0, py + 2 * s, c.w, s, ironD)
        c.rect(0, py + 5 * s, c.w, 2 * s, C(0x4A3A2C)); c.rect(0, py + 5 * s, c.w, max(1, s / 2), C(0x6A5440))
        for (k, x) in stride(from: 18 * s, to: c.w, by: 46 * s).enumerated() {
            c.rect(x, py - s, 3 * s, 5 * s, ironD); c.rect(x, py - s, s, 5 * s, ironL)
            c.rect(x + s, py + 7 * s, s, (4 + Int(noise(k + 1500) * 12)) * s, C(0x6A4428, 0.45))
        }
        // Caged bulbs hung under the pipe between the doors, dead.
        for x in stride(from: 40 * s, to: c.w, by: 92 * s) {
            c.rect(x, py + 7 * s, max(1, s / 2), 3 * s, ironD)
            c.rect(x - 2 * s, py + 10 * s, 5 * s, 5 * s, C(0x4A4E48))
            c.rect(x - s, py + 11 * s, 3 * s, 3 * s, C(0x5E5C4A)); c.rect(x - s, py + 11 * s, s, s, C(0x7E7A62))
            c.rect(x, py + 10 * s, max(1, s / 2), 5 * s, ironD); c.rect(x - 2 * s, py + 12 * s, 5 * s, max(1, s / 2), ironD)
        }
        // The glazed tiles below the chair rail, cracked, a few fallen out.
        let tw = 5 * s, gr = max(1, s / 2)
        c.rect(0, f.rail, c.w, g - f.rail, C(0x1E2A22))
        var n = 0
        for y in stride(from: f.rail + 2 * s, to: g - 2 * s, by: tw) {
            for x in stride(from: 0, to: c.w, by: tw) {
                n += 1
                let r = noise(n + 1100)
                if r > 0.94 {
                    c.rect(x, y, tw - gr, tw - gr, C(0x121814)); c.rect(x, y + tw - 2 * gr, tw - gr, gr, C(0x2A3A2E))
                    continue
                }
                c.rect(x, y, tw - gr, tw - gr, r > 0.5 ? C(0x324638) : C(0x2E4234))
                c.rect(x, y, tw - gr, gr, C(0x46604A))
                if r < 0.06 { huntP5Line(c, x, y + s, x + tw - 2 * s, y + tw - 2 * s, C(0x1A241E), 0.4) }
            }
        }
        c.rect(0, f.rail, c.w, 2 * s, C(0x2A3A2E)); c.rect(0, f.rail, c.w, max(1, s / 2), paintL)
        c.rect(0, g - 2 * s, c.w, 2 * s, C(0x1A221C))
        // The barred window on the left, moonlight in its panes, one pane smashed.
        let wx = c.w * 2 / 100, wy = g - 50 * s
        for r in stride(from: 22 * s, to: 4 * s, by: -4 * s) { c.ellipse(wx + 8 * s, wy + 12 * s, r, r, C(0x8AA4C8, 0.025)) }
        c.rect(wx - s, wy - s, 18 * s, 26 * s, C(0x222A24))
        c.rect(wx, wy, 16 * s, 24 * s, C(0x2A3A52)); c.rect(wx, wy, 8 * s, 12 * s, C(0x3E5274))
        c.rect(wx + 8 * s, wy + 12 * s, 8 * s, 6 * s, C(0x0C1018))
        huntP5Line(c, wx + 8 * s, wy + 14 * s, wx + 12 * s, wy + 12 * s, C(0x3E5274), 0.5)
        c.rect(wx, wy + 12 * s, 16 * s, s, C(0x1A201C)); c.rect(wx + 8 * s, wy, s, 24 * s, C(0x1A201C))
        for k in 1..<5 { c.rect(wx + k * 3 * s + s / 2, wy, s, 24 * s, C(0x141814)) }
        c.rect(wx - 2 * s, wy + 24 * s, 20 * s, 2 * s, C(0x5A6A5A)); c.rect(wx - 2 * s, wy + 24 * s, 20 * s, max(1, s / 2), C(0x7A8A78))
        // A metal chair knocked over under it.
        huntP5Line(c, wx + 2 * s, g - 2 * s, wx + 12 * s, g - 6 * s, C(0x4A4E4A), Double(s) * 0.6)
        huntP5Line(c, wx + 12 * s, g - 6 * s, wx + 16 * s, g - 2 * s, C(0x4A4E4A), Double(s) * 0.6)
        c.rect(wx + 9 * s, g - 9 * s, 7 * s, 2 * s, C(0x5A5446)); c.rect(wx + 9 * s, g - 9 * s, 7 * s, max(1, s / 2), C(0x7A7260))
        huntP5Line(c, wx + 15 * s, g - 9 * s, wx + 19 * s, g - 2 * s, C(0x3A3E3A), Double(s) * 0.5)
        // The cell doors in their frames, each with its number plate; the first stands open on the dark.
        for (k, dx) in f.doors.enumerated() {
            let top = f.doorTop, dw = 22 * s, dh = g - top
            c.rect(dx - 2 * s, top - 2 * s, dw + 4 * s, dh + 2 * s, C(0x26302A))
            c.rect(dx - 2 * s, top - 2 * s, dw + 4 * s, s, C(0x4A5A4E)); c.rect(dx - 2 * s, top - 2 * s, s, dh + 2 * s, C(0x4A5A4E))
            c.rect(dx + 8 * s, top - 6 * s, 6 * s, 3 * s, C(0x7A7864)); c.rect(dx + 8 * s, top - 6 * s, 6 * s, max(1, s / 2), C(0x9A987E))
            c.rect(dx + 9 * s, top - 5 * s, s, s, ironD); c.rect(dx + 11 * s, top - 5 * s, 2 * s, s, ironD)
            if k == 0 {
                // The room beyond: dark, a barred window at its far end letting in a little moonlight, its floor.
                c.rect(dx, top, dw, dh, C(0x070A08))
                c.rect(dx + 9 * s, top + 9 * s, 8 * s, 9 * s, C(0x16202E)); c.rect(dx + 9 * s, top + 9 * s, 4 * s, 4 * s, C(0x22304A))
                for b in 1..<4 { c.rect(dx + 9 * s + b * 2 * s, top + 9 * s, max(1, s / 2), 9 * s, C(0x070A08)) }
                c.rect(dx, g - 4 * s, dw, 4 * s, C(0x101612))
                c.rect(dx + 10 * s, g - 3 * s, 7 * s, s, C(0x2A3446, 0.6))
            } else {
                huntP5CellDoor(c, dx, top, dw, dh, s, shade: 0)
            }
        }
        // WARD C stencilled on the wall past the middle door, its paint run down in drips.
        if f.doors.count > 1 {
            let tx = f.doors[1] + 50 * s, ty = g - 50 * s
            huntP5Text(c, tx, ty, "WARD C", C(0xB4B096, 0.6), 2 * s)
            for (u, len) in [(-18, 4), (-9, 2), (3, 5), (16, 3)] { c.rect(tx + u * s, ty + 10 * s, s, len * s, C(0xB4B096, 0.4)) }
        }
        // The noticeboard between the first two doors: cork in a dark frame, curling notices, one hanging by a pin.
        if f.doors.count > 1 {
            let bx = (f.doors[0] + 24 * s + f.doors[1]) / 2, by = g - 52 * s
            c.rect(bx - 14 * s, by, 28 * s, 16 * s, C(0x222A22)); c.rect(bx - 13 * s, by + s, 26 * s, 14 * s, C(0x5E4C32))
            for i in 0..<20 { c.rect(bx - 13 * s + Int(noise(i + 1600) * Double(24 * s)), by + s + Int(noise(i + 1620) * Double(13 * s)), s, s, C(0x4E3E28)) }
            for (u, v, w, h) in [(-11, 3, 7, 8), (-2, 2, 6, 6), (6, 4, 6, 9)] as [(Int, Int, Int, Int)] {
                c.rect(bx + u * s, by + v * s, w * s, h * s, C(0x8C846A)); c.rect(bx + u * s, by + v * s, w * s, max(1, s / 2), C(0xA8A084))
                for l in stride(from: 2, to: h - 1, by: 2) { c.rect(bx + (u + 1) * s, by + (v + l) * s, (w - 2) * s, max(1, s / 2), C(0x6A644E)) }
                c.rect(bx + (u + w / 2) * s, by + v * s, s, s, C(0x9A2A22))
            }
            huntP5Line(c, bx - 2 * s, by + 10 * s, bx + 3 * s, by + 16 * s, C(0x8C846A), Double(s) * 1.4)
        }
        // A stopped clock with a cracked face between the next two doors, and the fire alarm's red bell.
        if f.doors.count > 2 {
            let cx = f.doors[2] - 22 * s, cy = g - 46 * s
            c.circle(cx, cy, 6 * s, C(0x2A2E28)); c.circle(cx, cy, 5 * s, C(0x8A8670)); c.circle(cx - s, cy - s, 2 * s, C(0x9A967E))
            for k in 0..<12 {
                let a = Double(k) * .pi / 6
                c.px(cx + Int(cos(a) * Double(4 * s)), cy + Int(sin(a) * Double(4 * s)), C(0x3A3A30))
            }
            huntP5Line(c, cx, cy, cx - 2 * s, cy - 3 * s, C(0x1E1E18), 0.5); huntP5Line(c, cx, cy, cx + 3 * s, cy + s, C(0x1E1E18), 0.5)
            huntP5Line(c, cx + s, cy - 5 * s, cx + 3 * s, cy + 2 * s, C(0xC8C4AC), 0.35)
            let ax = f.doors[2] - 9 * s, ay = g - 34 * s
            c.circle(ax, ay, 3 * s, C(0x7A2420)); c.circle(ax - s, ay - s, s, C(0xA83A30)); c.rect(ax - s / 2, ay, max(1, s), max(1, s), C(0x3A1210))
            c.rect(ax - s / 2, ay + 3 * s, max(1, s), 4 * s, C(0x3A3E38))
        }
        // On the right: a cold radiator under an open fuse box with its wires hanging, the strip light dangling by one
        // chain, and the wheelchair.
        let rx = c.w * 73 / 100
        for k in 0..<8 {
            let x = rx + k * 3 * s
            c.rect(x, g - 14 * s, 2 * s, 12 * s, C(0x46504A)); c.rect(x, g - 14 * s, max(1, s / 2), 12 * s, C(0x66726A))
            c.rect(x, g - 14 * s, 2 * s, max(1, s / 2), C(0x7A867C))
        }
        c.rect(rx - s, g - 4 * s, 26 * s, s, C(0x2E3430)); c.rect(rx - s, g - 13 * s, 26 * s, s, C(0x343C36))
        c.rect(rx + 4 * s, g - 44 * s, 12 * s, 14 * s, C(0x4A5048)); c.rect(rx + 4 * s, g - 44 * s, 12 * s, s, C(0x6A7068))
        c.rect(rx + 5 * s, g - 42 * s, 10 * s, 11 * s, C(0x161A16))
        for k in 0..<3 { c.rect(rx + 6 * s + k * 3 * s, g - 41 * s, 2 * s, 3 * s, C(0x3A3A32)) }
        c.rect(rx + 16 * s, g - 44 * s, 2 * s, 14 * s, C(0x5A6058))   // its door, hanging open
        huntP5Line(c, rx + 8 * s, g - 31 * s, rx + 6 * s, g - 25 * s, C(0x8A2A22), 0.45)
        huntP5Line(c, rx + 11 * s, g - 31 * s, rx + 13 * s, g - 24 * s, C(0x2A2A2A), 0.45)
        let lx = c.w * 96 / 100
        c.rect(lx, py + 7 * s, max(1, s / 2), 4 * s, ironD)
        huntP5Line(c, lx, py + 11 * s, lx - 20 * s, py + 22 * s, C(0x6A6C62), Double(s) * 1.2)
        huntP5Line(c, lx - s, py + 12 * s, lx - 19 * s, py + 22 * s, C(0x9A9C8C), Double(s) * 0.5)
        huntP5Line(c, lx - 20 * s, py + 22 * s, lx - 21 * s, py + 26 * s, C(0x2A2A28), 0.4)
        huntP5Wheelchair(c, f.chair, g, s)
        // The floor: old checkered linoleum, dark green and grey, a few papers blown into the corners.
        c.ground(g, C(0x2C342C), edge: C(0x46504A), speck: C(0x232A24), seed: 91)
        for (ri, y) in stride(from: g + 1, to: c.h, by: 4 * s).enumerated() {
            for (ci, x) in stride(from: 0, to: c.w, by: 10 * s).enumerated() where (ri + ci) % 2 == 0 {
                c.rect(x, y, 10 * s, min(4 * s, c.h - y), C(0x343C34))
            }
        }
        for (xp, dy) in [(5, 2), (9, 5), (93, 3), (82, 6)] {
            c.rect(c.w * xp / 100, g + dy * s, 4 * s, 2 * s, C(0x6A6A56)); c.rect(c.w * xp / 100, g + dy * s, 4 * s, max(1, s / 2), C(0x7E7E68))
        }
    }

    /// The screen saver's ceiling, high over the corridor: grey-green plaster in shadow, beams coming towards us,
    /// cracks running across it, water stains, a ragged hole through to the laths with strips hanging from it, and
    /// curls of paint hanging off the cornice.
    private static func huntAsylumCeiling(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntAsylumFrame(c, g), top = f.ceiling
        c.gradient(0, top, C(0x1A1E16), C(0x3A3E30), bands: 6)
        // Water stains: soft rings of brown.
        for (xp, yp, r) in [(22, 40, 12), (78, 62, 9), (40, 20, 14)] as [(Int, Int, Int)] {
            c.ellipse(c.w * xp / 100, top * yp / 100, r * 2 * s, r * s, C(0x3A2A14, 0.18))
            c.ellipse(c.w * xp / 100, top * yp / 100, r * 2 * s - 2 * s, r * s - s, C(0x3A3E30, 0.12))
        }
        // The cracks, wandering across the plaster, a lit edge under each.
        for k in 0..<7 {
            var x = Int(noise(k + 1700) * Double(c.w)), y = Int(noise(k + 1710) * Double(top - 8 * s)) + 2 * s
            for i in 0..<(30 + Int(noise(k + 1720) * 40)) {
                c.rect(x, y, s, s, C(0x0E100C)); c.rect(x, y + s, s, max(1, s / 2), C(0x52564A))
                x += (noise(k * 97 + i) > 0.5 ? 1 : 2) * s * (k % 2 == 0 ? 1 : -1)
                y += Int((noise(k * 97 + i + 500) - 0.45) * 3) * s
                y = max(s, min(top - 2 * s, y))
            }
        }
        // The hole through to the laths: a ragged dark gap with broken plaster round it, the laths across it, a few
        // hanging down.
        let hx = c.w * 62 / 100, hy = top * 46 / 100
        let lumps: [(Int, Int, Int, Int)] = [(0, 0, 22, 8), (-14, 2, 10, 6), (14, -1, 11, 6), (4, 5, 10, 5)]
        for (u, v, rx, ry) in lumps { c.ellipse(hx + u * s, hy + v * s, rx * s + 3 * s, ry * s + 2 * s, C(0x6A6E5C)) }
        for (u, v, rx, ry) in lumps { c.ellipse(hx + u * s, hy + v * s, rx * s + s, ry * s + s, C(0x4A4C3E)) }
        for (u, v, rx, ry) in lumps { c.ellipse(hx + u * s, hy + v * s, rx * s, ry * s, C(0x0A0C08)) }
        for (k, y) in stride(from: hy - 6 * s, to: hy + 10 * s, by: 3 * s).enumerated() {
            let gap = (4 + Int(noise(k + 1800) * 14)) * s, at = hx - 20 * s + Int(noise(k + 1810) * 30) * s
            let l = hx - (y < hy - 3 * s || y > hy + 6 * s ? 10 : 20) * s, r = hx + (y < hy - 3 * s || y > hy + 6 * s ? 12 : 22) * s
            c.rect(l, y, max(0, min(at, r) - l), s, C(0x6A5238)); c.rect(at + gap, y, max(0, r - at - gap), s, C(0x5A4630))
            c.rect(l, y + s, max(0, min(at, r) - l), max(1, s / 2), C(0x2A2018))
        }
        // The beams, spreading out as they come towards us: each lit on its left face, its underside in shadow.
        let cx = c.w / 2
        for x0 in stride(from: c.w * 8 / 100, to: c.w, by: max(60 * s, c.w * 21 / 100)) {
            for y in 0..<top {
                let k = 1 + Double(top - y) / Double(top) * 0.8
                let bx = cx + Int(Double(x0 - cx) * k), bw = Int(Double(7 * s) * k)
                c.rect(bx, y, bw, 1, C(0x202218))
                c.rect(bx, y, max(s, bw * 2 / 5), 1, x0 < cx ? C(0x5A5C4C) : C(0x46483C))
            }
        }
        // The cornice, and curls of paint hanging off it.
        c.rect(0, top - 4 * s, c.w, 4 * s, C(0x3E4A3A)); c.rect(0, top - 4 * s, c.w, s, C(0x5E6E56)); c.rect(0, top - s, c.w, s, C(0x222A20))
        for k in 0..<max(1, c.w / (40 * s)) {
            let x = Int(noise(k + 1900) * Double(c.w)), len = (4 + Int(noise(k + 1910) * 10)) * s
            c.rect(x, top, 2 * s, len, C(0x6A7A62)); c.rect(x + s, top, s, len, C(0x4E5C48)); c.rect(x - s, top + len, 2 * s, s, C(0x6A7A62))
        }
    }

    /// The screen saver's gallery row: the floor of the upper tier of cells, high on the wall.
    static func huntAsylumGallery(_ g: Int) -> Int { g - 118 * unit(g) }

    /// The screen saver's upper wall: arched windows high up, barred, some boarded over, their moonlight falling in
    /// pale shafts; under them the upper tier of cells along an iron gallery with its railing; and enamel lamps
    /// hanging on long flexes from the ceiling.
    private static func huntAsylumHighWall(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntAsylumFrame(c, g), gal = huntAsylumGallery(g)
        let wy = f.ceiling + 16 * s, wh = 28 * s
        let step = max(70 * s, c.w * 22 / 100)
        let wins = Array(stride(from: c.w * 18 / 100, to: c.w - 20 * s, by: step))
        for (k, x) in wins.enumerated() {
            // The moonlight, a faint shaft slanting down to the right.
            for y in stride(from: wy + wh, to: min(f.rail, wy + wh + 120 * s), by: s) {
                let d = y - wy - wh
                c.rect(x + d / 2, y, 20 * s, s, C(0x9AB4D8, 0.035))
            }
            c.rect(x - 2 * s, wy - 2 * s, 24 * s, wh + 4 * s, C(0x222A22)); c.circle(x + 10 * s, wy, 12 * s, C(0x222A22))
            c.rect(x, wy, 20 * s, wh, C(0x24344C)); c.ellipse(x + 10 * s, wy, 10 * s, 10 * s, C(0x24344C))
            c.rect(x, wy - 6 * s, 10 * s, wh / 2 + 6 * s, C(0x34486A))
            for b in 1..<5 { c.rect(x + b * 4 * s, wy - 9 * s, s, wh + 9 * s, C(0x121612)) }
            for y in stride(from: wy, to: wy + wh, by: 10 * s) { c.rect(x, y, 20 * s, s, C(0x121612)) }
            if k % 2 == 1 {   // boarded over
                for (j, y) in [wy + 8 * s, wy + 15 * s, wy + 22 * s].enumerated() {
                    let a = j % 2 == 0 ? 0 : 4 * s, b = j % 2 == 0 ? 4 * s : 0
                    huntP5Line(c, x - 2 * s, y + a, x + 22 * s, y + b, C(0x4A3826), Double(s) * 1.6)
                    huntP5Line(c, x - 2 * s, y - s + a, x + 22 * s, y - s + b, C(0x6A5238), Double(s) * 0.4)
                }
            }
            c.rect(x - 3 * s, wy + wh, 26 * s, 2 * s, C(0x4E5C4C)); c.rect(x - 3 * s, wy + wh, 26 * s, max(1, s / 2), C(0x6E7E6A))
        }
        // The upper tier: cell doors between the windows, the gallery's floor on its brackets, the iron railing.
        for x in wins.map({ $0 + step / 2 - 1 * s }) where x + 26 * s < c.w {
            let top = gal - 40 * s
            c.rect(x - 2 * s, top - 2 * s, 26 * s, 42 * s, C(0x26302A)); c.rect(x - 2 * s, top - 2 * s, 26 * s, s, C(0x3E4C42))
            huntP5CellDoor(c, x, top, 22 * s, 40 * s, s, shade: 0.3)
        }
        c.rect(0, gal, c.w, 4 * s, C(0x2E3430)); c.rect(0, gal, c.w, s, C(0x5A625A)); c.rect(0, gal + 4 * s, c.w, s, C(0x161A16))
        for x in stride(from: 12 * s, to: c.w, by: 36 * s) {
            for k in 0..<5 { c.rect(x + k * s, gal + 5 * s + k * s, (5 - k) * s, s, C(0x262C28)) }
            c.rect(x, gal + 5 * s, s, 6 * s, C(0x262C28))
        }
        for x in stride(from: 0, to: c.w, by: 4 * s) { c.rect(x, gal - 10 * s, max(1, s / 2), 10 * s, C(0x1E2420)) }
        c.rect(0, gal - 11 * s, c.w, s, C(0x4A524A)); c.rect(0, gal - 10 * s, c.w, max(1, s / 2), C(0x1E2420))
        c.rect(0, gal - 5 * s, c.w, max(1, s / 2), C(0x2A302C))
        // Enamel lamps on long flexes, dead, one hanging askew.
        for (j, xp) in [10, 40, 66, 92].enumerated() {
            let x = c.w * xp / 100, y = gal - 30 * s + (j % 2) * 6 * s
            c.rect(x, f.ceiling * 70 / 100, max(1, s / 2), y - f.ceiling * 70 / 100, C(0x16180F))
            c.rect(x - 2 * s, y, 5 * s, 2 * s, C(0x3A3E34))
            for k in 0..<3 { let w = (6 + k * 3) * s; c.rect(x - w / 2, y + 2 * s + k * s, w, s, k == 2 ? C(0x3A4236) : C(0x6A7462)) }
            c.rect(x - s, y + 5 * s, 3 * s, s, C(0x4A4838))
        }
    }

    /// The corridor's life: a flashlight's beam sweeping slowly along the wall as if someone were coming down the
    /// corridor with a camera, and the open cell door creaking to and fro.
    static func huntAsylumLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntAsylumFrame(c, g), tall = isTall(c)
        let x = c.w / 2 + Int(Double(c.w) * 0.38 * sin(t * 0.42))
        let y = (tall ? g - 70 * s : g - 46 * s) + Int(Double(5 * s) * sin(t * 0.9 + 1))
        for r in stride(from: 15 * s, to: 2 * s, by: -3 * s) { c.ellipse(x, y, r * 3 / 2, r, C(0xF0E8C0, 0.045)) }
        // The door, hinged on its left, swinging a little in a draught.
        guard let dx = f.doors.first else { return }
        let a = 0.78 + 0.24 * sin(t * 0.55) + 0.05 * sin(t * 1.7)
        let w = max(4 * s, Int(Double(22 * s) * cos(a)))
        huntP5CellDoor(c, dx, f.doorTop, w, g - f.doorTop, s, shade: 0.2 + 0.35 * sin(a))
    }
}

// MARK: - A roadside diner

/// A pair of booths facing each other side-on, 52 units across, standing on row `g` from `x`: tall red vinyl backs with
/// channel tufting and chrome caps, the seats, the table between them on its chrome pedestal, with the napkins, the
/// ketchup and mustard, the sugar pourer and, now and then, a plate of pie and a mug.
private func huntP5Booth(_ c: PixelCanvas, _ x: Int, _ g: Int, _ s: Int, seed: Int) {
    let red = C(0xA8282A), redL = C(0xCC4A42), redD = C(0x701A1C)
    let chrome = C(0xB4BAC0), chromeL = C(0xE4E8EC), chromeD = C(0x6E747A)
    for (bx, face) in [(x, 1), (x + 48 * s, -1)] {
        // The back.
        c.rect(bx, g - 24 * s, 4 * s, 24 * s, red)
        c.rect(bx, g - 24 * s, s, 24 * s, redL); c.rect(bx + 3 * s, g - 24 * s, s, 24 * s, redD)
        for y in stride(from: g - 21 * s, to: g - 11 * s, by: 3 * s) { c.rect(bx, y, 4 * s, max(1, s / 2), redD) }
        c.rect(bx - s, g - 25 * s, 6 * s, s, chromeL); c.rect(bx - s, g - 24 * s, 6 * s, max(1, s / 2), chromeD)
        // The seat, its cushion lit along the top, the chrome-trimmed base.
        let sx = face > 0 ? bx + 4 * s : bx - 8 * s
        c.rect(sx, g - 11 * s, 8 * s, 3 * s, red); c.rect(sx, g - 11 * s, 8 * s, s, redL); c.rect(sx, g - 8 * s, 8 * s, s, redD)
        c.rect(sx, g - 7 * s, 8 * s, 5 * s, C(0x4A1416)); c.rect(sx, g - 7 * s, 8 * s, max(1, s / 2), chrome)
        c.rect(sx, g - 2 * s, 8 * s, 2 * s, chromeD)
    }
    // The table: a pale formica top with a chrome edge, its pedestal and foot.
    let tx = x + 14 * s
    c.rect(tx, g - 16 * s, 22 * s, 2 * s, C(0xC8BC9A)); c.rect(tx, g - 16 * s, 22 * s, max(1, s / 2), C(0xE0D6B8))
    c.rect(tx, g - 14 * s, 22 * s, s, chrome)
    c.rect(tx + 10 * s, g - 13 * s, 2 * s, 12 * s, chromeD); c.rect(tx + 10 * s, g - 13 * s, max(1, s / 2), 12 * s, chromeL)
    c.rect(tx + 6 * s, g - s, 10 * s, s, chrome)
    // What's on it.
    let t = g - 16 * s
    c.rect(tx + 9 * s, t - 4 * s, 4 * s, 4 * s, chrome); c.rect(tx + 9 * s, t - 4 * s, s, 4 * s, chromeL); c.rect(tx + 10 * s, t - 4 * s, 2 * s, s, C(0xE8E4DA))
    c.rect(tx + 14 * s, t - 5 * s, s, 5 * s, C(0xB02A22)); c.rect(tx + 14 * s, t - 6 * s, s, s, C(0xE0DCD0))
    c.rect(tx + 16 * s, t - 5 * s, s, 5 * s, C(0xD8B030)); c.rect(tx + 16 * s, t - 6 * s, s, s, C(0xB02A22))
    c.rect(tx + 5 * s, t - 3 * s, 2 * s, 3 * s, C(0xB8C8C8)); c.rect(tx + 5 * s, t - 4 * s, 2 * s, s, chrome)
    if noise(seed + 2000) > 0.4 {
        c.rect(tx + 1 * s, t - s, 5 * s, s, C(0xE4DED0))
        c.rect(tx + 2 * s, t - 3 * s, 3 * s, 2 * s, C(0xC89048)); c.rect(tx + 2 * s, t - 2 * s, 3 * s, s, C(0xA8302C))
    }
    if noise(seed + 2001) > 0.3 {
        c.rect(tx + 18 * s, t - 3 * s, 3 * s, 3 * s, C(0xD8D2C4)); c.rect(tx + 18 * s, t - 3 * s, 3 * s, max(1, s / 2), C(0x3A2214))
        c.rect(tx + 21 * s, t - 2 * s, s, s, C(0xB8B2A4))
    }
}

/// The view through a diner window by day: a pale denim sky with a cloud or two, a tree line, wheat fields, the
/// highway, and a telephone pole; `car` parks a black '67 sedan on the shoulder.
private func huntP5DinerView(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ s: Int, car: Bool, seed: Int) {
    guard w > 4 * s, h > 4 * s else { return }
    let horizon = y + h * 62 / 100
    for yy in y..<horizon {
        let k = Double(yy - y) / Double(max(1, horizon - y))
        c.rect(x, yy, w, 1, lerp(C(0x6890B0), C(0xA4BCC4), (k * 4).rounded(.down) / 4))
    }
    for k in 0..<2 {
        let cx = x + Int(noise(seed + k * 3) * Double(w)), cy = y + h * (18 + k * 14) / 100
        if cx > x + 8 * s && cx < x + w - 8 * s { Scenes.cloud(c, cx, cy, 3 * s, seed: seed + k, top: C(0xD4E0E6), base: C(0xB4C6D0)) }
    }
    c.rect(x, horizon - 2 * s, w, 2 * s, C(0x4E5E44))
    for k in 0..<(w / (5 * s)) { c.rect(x + k * 5 * s, horizon - 3 * s - Int(noise(seed + 40 + k) * 2) * s, 4 * s, s + s / 2, C(0x4E5E44)) }
    c.rect(x, horizon, w, y + h - horizon, C(0x9A8A52))
    c.rect(x, horizon + 2 * s, w, max(1, s / 2), C(0x8A7A48))
    let road = y + h - 4 * s
    c.rect(x, road, w, 4 * s, C(0x54504A)); c.rect(x, road, w, max(1, s / 2), C(0x6E6A62))
    for xx in stride(from: x + 2 * s, to: x + w - 4 * s, by: 9 * s) { c.rect(xx, road + 2 * s, 4 * s, max(1, s / 2), C(0xC8B060)) }
    // A telephone pole and its wires.
    let px = x + w * 72 / 100
    c.rect(px, y + h * 20 / 100, s, road - y - h * 20 / 100, C(0x4A3A2A)); c.rect(px - 3 * s, y + h * 22 / 100, 7 * s, s, C(0x4A3A2A))
    c.rect(x, y + h * 24 / 100, w, max(1, s / 2), C(0x3A3A3A, 0.6))
    if car {
        // The black sedan, long and low, chrome along its side and its bumpers, parked facing left.
        let cx = x + w * 18 / 100, cy = road + s
        c.rect(cx, cy - 4 * s, 24 * s, 3 * s, C(0x16161A)); c.rect(cx, cy - 4 * s, 24 * s, max(1, s / 2), C(0x4A4C56))
        c.rect(cx + 7 * s, cy - 7 * s, 10 * s, 3 * s, C(0x16161A)); c.rect(cx + 8 * s, cy - 6 * s, 3 * s, 2 * s, C(0x5A7088))
        c.rect(cx + 12 * s, cy - 6 * s, 4 * s, 2 * s, C(0x5A7088)); c.rect(cx + 7 * s, cy - 7 * s, 10 * s, max(1, s / 2), C(0x3A3C44))
        c.rect(cx, cy - 2 * s, 24 * s, max(1, s / 2), C(0xA8AEB4)); c.rect(cx - s, cy - 3 * s, s, 2 * s, C(0xB4BAC0)); c.rect(cx + 24 * s, cy - 3 * s, s, 2 * s, C(0xB4BAC0))
        for wx in [cx + 5 * s, cx + 19 * s] { c.circle(wx, cy - s, 2 * s, C(0x0C0C0E)); c.rect(wx, cy - s, max(1, s / 2), max(1, s / 2), C(0x8A8E94)) }
    } else {
        // A grain elevator far off across the fields.
        let ex = x + w * 30 / 100
        c.rect(ex, horizon - 16 * s, 8 * s, 14 * s, C(0x8A8A86)); c.rect(ex, horizon - 16 * s, 2 * s, 14 * s, C(0xA4A4A0))
        c.rect(ex + 8 * s, horizon - 10 * s, 6 * s, 8 * s, C(0x7A7A76)); c.rect(ex + 2 * s, horizon - 19 * s, 4 * s, 3 * s, C(0x7A7A76))
    }
}

extension Scenes {
    /// Where things stand in the diner, shared by the still picture and the moving layer: the counter (its ends and
    /// top), the back counter's top, the pie case (its middle and the counter it stands on), the coffee pots, the mug
    /// on the counter, the chrome rail under the mint wall, the ceiling fans and their row, and the ceiling's line.
    static func huntDinerFrame(_ c: PixelCanvas, _ g: Int) -> (counter: (x0: Int, x1: Int, top: Int), back: Int, pie: (x: Int, base: Int),
                                                             pots: [Int], cup: Int, rail: Int, fans: [Int], fanY: Int, ceiling: Int) {
        let s = unit(g), tall = isTall(c)
        let x0 = c.w * 27 / 100, x1 = c.w * 77 / 100
        let ceiling = tall ? g * 16 / 100 : 0
        let fans = tall ? [c.w * 20 / 100, c.w * 50 / 100, c.w * 80 / 100] : []
        let counter = (x0: x0, x1: x1, top: g - 14 * s)
        let pie = (x: x0 + 28 * s, base: g - 14 * s)
        return (counter, g - 22 * s, pie, [c.w * 58 / 100, c.w * 58 / 100 + 7 * s], c.w * 47 / 100,
                g - 36 * s, fans, ceiling + 18 * s, ceiling)
    }

    /// A roadside diner by day, somewhere on the highway (Death's chili dogs): mint enamel walls under a red soffit, big
    /// windows on both sides with the blinds half down and the fields and the highway outside (the Impala parked on
    /// the shoulder), red vinyl booths by the windows, the long counter in red and chrome with its stools, the turning
    /// pie case and a mug on it, the till at its end, and behind it a steel wall with the coffee machine, a milkshake
    /// mixer and a toaster, a shelf of mugs, the kitchen hatch with the order wheel and a plate up, a big PIE sign and
    /// a clock. The floor is a mid-tone checker, never white. On the screen saver the room rises to a pressed tin
    /// ceiling with fans turning and globe lamps, the menu board over the counter, transom windows, and an EAT sign.
    static func huntDiner(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntDinerFrame(c, g), tall = isTall(c), k = f.counter
        let mint = C(0x6A988A), mintL = C(0x86B2A2), mintD = C(0x4E7A6C)
        let red = C(0xA8282A), redL = C(0xCC4A42), redD = C(0x701A1C)
        let chrome = C(0xB4BAC0), chromeL = C(0xE4E8EC), chromeD = C(0x6E747A)
        let steel = C(0x666C72), steelL = C(0x868C92), steelD = C(0x4A5056)
        // The mint wall, a pinstripe of red under the soffit.
        c.rect(0, f.ceiling, c.w, f.rail - f.ceiling, mint)
        c.rect(0, f.ceiling + 6 * s, c.w, s, red); c.rect(0, f.ceiling + 7 * s, c.w, max(1, s / 2), mintD)
        if tall { huntDinerCeiling(c, g) }
        // Below the windows: dark red enamel panels with a chrome strip.
        c.rect(0, f.rail, c.w, g - f.rail, C(0x5A2224))
        for x in stride(from: 0, to: c.w, by: 12 * s) { c.rect(x, f.rail + 3 * s, max(1, s / 2), g - f.rail - 3 * s, C(0x441A1C)) }
        c.rect(0, f.rail, c.w, 2 * s, chrome); c.rect(0, f.rail, c.w, max(1, s / 2), chromeL); c.rect(0, f.rail + 2 * s, c.w, max(1, s / 2), chromeD)
        // The windows each side, chrome-framed, the blinds half down, the day outside.
        let wTop = tall ? f.rail - 100 * s : f.ceiling + 9 * s, wBot = g - 24 * s
        let windows: [(x: Int, w: Int, car: Bool)] = [(x: 4 * s, w: k.x0 - 10 * s, car: true), (x: k.x1 + 6 * s, w: c.w - 34 * s - k.x1 - 6 * s, car: false)]
        for (n, win) in windows.enumerated() where win.w > 10 * s {
            c.rect(win.x - 2 * s, wTop - 2 * s, win.w + 4 * s, wBot - wTop + 4 * s, chromeD)
            c.rect(win.x - 2 * s, wTop - 2 * s, win.w + 4 * s, s, chromeL)
            huntP5DinerView(c, win.x, wTop, win.w, wBot - wTop, s, car: win.car, seed: 2100 + n * 10)
            let blind = (wBot - wTop) * 30 / 100
            for (j, y) in stride(from: wTop, to: wTop + blind, by: s).enumerated() { c.rect(win.x, y, win.w, s, j % 2 == 0 ? C(0xC4B48C) : C(0x9A8C6A)) }
            c.rect(win.x, wTop + blind, win.w, s, C(0x7A6C50))
            c.rect(win.x + win.w * 80 / 100, wTop + blind, max(1, s / 2), 6 * s, C(0x7A6C50))
            for x in stride(from: win.x + 40 * s, to: win.x + win.w - 6 * s, by: 40 * s) { c.rect(x, wTop, 2 * s, wBot - wTop, chrome); c.rect(x, wTop, max(1, s / 2), wBot - wTop, chromeL) }
            c.rect(win.x - 3 * s, wBot, win.w + 6 * s, 2 * s, chrome); c.rect(win.x - 3 * s, wBot, win.w + 6 * s, max(1, s / 2), chromeL)
        }
        // The front door on the far right: chrome frame, glass, the push bar, and the OPEN card.
        let dx = c.w - 26 * s, dTop = g - 42 * s
        c.rect(dx - 2 * s, dTop - 2 * s, 24 * s, g - dTop + 2 * s, chromeD); c.rect(dx - 2 * s, dTop - 2 * s, 24 * s, s, chromeL)
        huntP5DinerView(c, dx, dTop, 20 * s, g - dTop - 12 * s, s, car: false, seed: 2190)
        c.rect(dx, g - 12 * s, 20 * s, 12 * s, chromeD); c.rect(dx, g - 12 * s, 20 * s, s, chrome)
        c.rect(dx + 2 * s, g - 20 * s, 16 * s, 2 * s, chromeL); c.rect(dx + 2 * s, g - 18 * s, 16 * s, max(1, s / 2), chromeD)
        c.rect(dx + 2 * s, dTop + 4 * s, 16 * s, 9 * s, C(0xD8CCB0)); c.rect(dx + 2 * s, dTop + 4 * s, 16 * s, max(1, s / 2), C(0xEEE4CC))
        huntP5Text(c, dx + 10 * s, dTop + 6 * s, "OPEN", C(0xB8282A), s)
        // The booths by the windows.
        for x in stride(from: 6 * s, to: k.x0 - 56 * s, by: 58 * s) { huntP5Booth(c, x, g, s, seed: x / max(1, s)) }
        for x in stride(from: k.x1 + 6 * s, to: dx - 54 * s, by: 58 * s) { huntP5Booth(c, x, g, s, seed: x / max(1, s) + 7) }
        // Behind the counter: the steel back wall in brushed panels, a shelf of mugs and glasses.
        c.rect(k.x0, f.rail + 2 * s, k.x1 - k.x0, f.back - f.rail - 2 * s, steel)
        for x in stride(from: k.x0, to: k.x1, by: 10 * s) {
            c.rect(x, f.rail + 2 * s, max(1, s / 2), f.back - f.rail - 2 * s, steelD); c.rect(x + s, f.rail + 2 * s, max(1, s / 2), f.back - f.rail - 2 * s, steelL)
        }
        c.rect(k.x0, f.rail + 6 * s, k.x1 - k.x0, max(1, s / 2), steelL)
        let shelfY = f.rail + 7 * s, shelfEnd = f.pots[0] - 22 * s
        c.rect(k.x0 + 4 * s, shelfY, shelfEnd - k.x0 - 4 * s, s, chromeL); c.rect(k.x0 + 4 * s, shelfY + s, shelfEnd - k.x0 - 4 * s, max(1, s / 2), chromeD)
        for (j, x) in stride(from: k.x0 + 6 * s, to: shelfEnd - 3 * s, by: 4 * s).enumerated() {
            if j % 3 == 2 {
                c.rect(x, shelfY - 4 * s, 2 * s, 4 * s, C(0x8AA8B0)); c.rect(x, shelfY - 4 * s, max(1, s / 2), 4 * s, C(0xB8D0D4))
            } else {
                c.rect(x, shelfY - 3 * s, 3 * s, 3 * s, C(0xD8D2C4)); c.rect(x + 2 * s, shelfY - 3 * s, s, 3 * s, C(0xA8A294))
                c.rect(x, shelfY - 6 * s, 3 * s, 3 * s, C(0xCCC6B8)); c.rect(x + 2 * s, shelfY - 6 * s, s, 3 * s, C(0xA09A8C))
            }
        }
        // The back counter: mint top, steel cupboards.
        c.rect(k.x0, f.back, k.x1 - k.x0, 2 * s, mintL); c.rect(k.x0, f.back + 2 * s, k.x1 - k.x0, max(1, s / 2), mintD)
        c.rect(k.x0, f.back + 2 * s, k.x1 - k.x0, k.top - f.back - 2 * s, steelD)
        for x in stride(from: k.x0 + 2 * s, to: k.x1 - 6 * s, by: 14 * s) { c.rect(x, f.back + 4 * s, 12 * s, k.top - f.back - 4 * s, steel) }
        // The coffee machine over its two pots, the milkshake mixer, the toaster.
        let p0 = f.pots[0], p1 = f.pots[1]
        c.rect(p0 - 5 * s, f.back - 15 * s, p1 - p0 + 11 * s, 8 * s, steelL); c.rect(p0 - 5 * s, f.back - 15 * s, p1 - p0 + 11 * s, s, chromeL)
        c.rect(p0 - 5 * s, f.back - 15 * s, s, 15 * s, chrome); c.rect(p1 + 5 * s, f.back - 15 * s, s, 15 * s, steelD)
        c.rect(p0 - 4 * s, f.back - 12 * s, 3 * s, 2 * s, C(0x2A2E32)); c.rect(p0 - 3 * s, f.back - 12 * s, s, s, C(0xE04A2A))
        for (j, px) in [p0, p1].enumerated() {
            c.rect(px - 2 * s, f.back - 7 * s, 5 * s, s, C(0x1E1E20))   // the brew basket
            c.rect(px - s, f.back - 6 * s, 3 * s, s, C(0x9AB0B4))
            c.rect(px - 2 * s, f.back - 5 * s, 5 * s, 4 * s, C(0x9AB0B4)); c.rect(px - 2 * s, f.back - 5 * s, s, 4 * s, C(0xC8DADC))
            c.rect(px - 2 * s, f.back - 3 * s, 5 * s, 2 * s, C(0x3A2010))
            c.rect(px + 3 * s, f.back - 5 * s, s, 3 * s, j == 0 ? C(0x1E1E20) : C(0xD87A2A))
            c.rect(px - 2 * s, f.back - s, 5 * s, s, C(0x2A2A2E))
        }
        let mx = p0 - 14 * s
        c.rect(mx - s, f.back - 9 * s, 3 * s, 9 * s, C(0x7AB8A0)); c.rect(mx - s, f.back - 9 * s, s, 9 * s, C(0x9AD0B8))
        c.rect(mx + 2 * s, f.back - 9 * s, 3 * s, 2 * s, C(0x7AB8A0))
        c.rect(mx + 2 * s, f.back - 6 * s, 3 * s, 5 * s, chrome); c.rect(mx + 2 * s, f.back - 6 * s, s, 5 * s, chromeL)
        c.rect(mx - 2 * s, f.back - s, 8 * s, s, C(0x5A9A84))
        let tx = c.w * 68 / 100
        c.rect(tx, f.back - 5 * s, 8 * s, 5 * s, chrome); c.rect(tx, f.back - 5 * s, 8 * s, s, chromeL); c.rect(tx + 7 * s, f.back - 5 * s, s, 5 * s, chromeD)
        c.rect(tx + 2 * s, f.back - 5 * s, s, max(1, s / 2), C(0x2A2A2E)); c.rect(tx + 5 * s, f.back - 5 * s, s, max(1, s / 2), C(0x2A2A2E))
        // The kitchen hatch: a chrome frame, the warm dark of the kitchen, the heat lamps, the order wheel with its
        // tickets, a plate up on the sill and the bell.
        let hx0 = c.w * 47 / 100, hx1 = c.w * 64 / 100, hy0 = f.rail - 25 * s, hy1 = f.rail - 4 * s
        c.rect(hx0 - 2 * s, hy0 - 2 * s, hx1 - hx0 + 4 * s, hy1 - hy0 + 4 * s, chromeD); c.rect(hx0 - 2 * s, hy0 - 2 * s, hx1 - hx0 + 4 * s, s, chromeL)
        c.rect(hx0, hy0, hx1 - hx0, hy1 - hy0, C(0x34281E)); c.rect(hx0, hy0 + (hy1 - hy0) / 2, hx1 - hx0, (hy1 - hy0) / 2, C(0x2A2018))
        for x in stride(from: hx0 + 6 * s, to: hx1 - 4 * s, by: 10 * s) { c.rect(x, hy0 + s, 6 * s, 2 * s, C(0x4A4A4A)); c.rect(x + s, hy0 + 3 * s, 4 * s, s, C(0xE05A2A)) }
        c.rect(hx0, hy0 + 4 * s, hx1 - hx0, 5 * s, C(0xE05A2A, 0.12))
        let ow = (hx0 + hx1) / 2
        c.rect(ow - 8 * s, hy0 + 6 * s, 16 * s, s, chrome)
        for (j, u) in [-6, -1, 4].enumerated() { c.rect(ow + u * s, hy0 + 7 * s, 3 * s, (4 + j % 2) * s, C(0xD8D4C4)); c.rect(ow + u * s, hy0 + 8 * s, 3 * s, max(1, s / 2), C(0x8A8478)) }
        c.rect(hx0 - 3 * s, hy1, hx1 - hx0 + 6 * s, 2 * s, chrome); c.rect(hx0 - 3 * s, hy1, hx1 - hx0 + 6 * s, max(1, s / 2), chromeL)
        let plx = hx0 + 6 * s
        c.rect(plx, hy1 - s, 8 * s, s, C(0xE4DED0))
        c.rect(plx + 2 * s, hy1 - 2 * s, 4 * s, s, C(0x6A3A1E)); c.rect(plx + 2 * s, hy1 - 3 * s, 4 * s, s, C(0x4E8A3A)); c.rect(plx + 2 * s, hy1 - 4 * s, 4 * s, s, C(0xC88A3E))
        c.rect(hx1 - 7 * s, hy1 - 2 * s, 3 * s, 2 * s, chromeL); c.rect(hx1 - 6 * s, hy1 - 3 * s, s, s, chrome)
        // The PIE sign over the pie case, red with a dark drop shadow, and the clock.
        huntP5Text(c, f.pie.x + s, f.rail - 21 * s, "PIE", C(0x2A1A1A, 0.5), 2 * s)
        huntP5Text(c, f.pie.x, f.rail - 22 * s, "PIE", C(0xB8282A), 2 * s)
        c.rect(f.pie.x - 10 * s, f.rail - 10 * s, 20 * s, max(1, s / 2), C(0xB8282A))
        let ck = (x: c.w * 71 / 100, y: f.rail - 16 * s)
        c.circle(ck.x, ck.y, 6 * s, C(0xA8282A)); c.circle(ck.x, ck.y, 5 * s, C(0xD8D2BC)); c.circle(ck.x - s, ck.y - s, 2 * s, C(0xE8E4D4))
        for j in 0..<4 { let a = Double(j) * .pi / 2; c.px(ck.x + Int(cos(a) * Double(4 * s)), ck.y + Int(sin(a) * Double(4 * s)), C(0x3A3A3A)) }
        huntP5Line(c, ck.x, ck.y, ck.x + 2 * s, ck.y - 3 * s, C(0x1E1E1E), 0.5); huntP5Line(c, ck.x, ck.y, ck.x - 3 * s, ck.y + s, C(0x1E1E1E), 0.5)
        // Two framed photos between the sign and the hatch.
        for (j, x) in [f.pie.x + 16 * s, f.pie.x + 27 * s].enumerated() {
            let y = f.rail - 20 * s + j * 2 * s
            c.rect(x, y, 8 * s, 7 * s, chromeD); c.rect(x + s, y + s, 6 * s, 5 * s, j == 0 ? C(0x7A6A54) : C(0x5A6A78)); c.rect(x + s, y + 4 * s, 6 * s, 2 * s, C(0x4A4034))
        }
        // The counter: pale mint formica on a chrome edge, its front in red enamel ribbed with chrome.
        c.rect(k.x0 - 2 * s, k.top, k.x1 - k.x0 + 4 * s, 2 * s, C(0x9CC8B8)); c.rect(k.x0 - 2 * s, k.top, k.x1 - k.x0 + 4 * s, max(1, s / 2), C(0xB8DCCC))
        c.rect(k.x0 - 2 * s, k.top + 2 * s, k.x1 - k.x0 + 4 * s, s, chrome)
        c.rect(k.x0, k.top + 3 * s, k.x1 - k.x0, g - k.top - 3 * s, red)
        c.rect(k.x0, k.top + 3 * s, s, g - k.top - 3 * s, redL); c.rect(k.x1 - s, k.top + 3 * s, s, g - k.top - 3 * s, redD)
        for y in stride(from: k.top + 5 * s, to: g - 2 * s, by: 3 * s) { c.rect(k.x0, y, k.x1 - k.x0, max(1, s / 2), chromeD) }
        c.rect(k.x0, g - 2 * s, k.x1 - k.x0, 2 * s, chrome); c.rect(k.x0, g - 2 * s, k.x1 - k.x0, max(1, s / 2), chromeL)
        // On the counter: the pie case (its plates and dome; the moving layer turns the pies), napkins and sugar, the
        // mug, and the till at the end.
        let pc = f.pie
        c.rect(pc.x - 9 * s, pc.base - 2 * s, 18 * s, 2 * s, chrome); c.rect(pc.x - 9 * s, pc.base - 2 * s, 18 * s, max(1, s / 2), chromeL)
        c.rect(pc.x - 8 * s, pc.base - 16 * s, 16 * s, 14 * s, C(0x5A6A6E)); c.rect(pc.x - 8 * s, pc.base - 16 * s, 16 * s, 14 * s, C(0xC8E0E4, 0.18))
        c.rect(pc.x - 8 * s, pc.base - 16 * s, s, 14 * s, chromeL); c.rect(pc.x + 7 * s, pc.base - 16 * s, s, 14 * s, chromeD)
        c.rect(pc.x - s / 2, pc.base - 15 * s, max(1, s), 13 * s, chromeD)
        for y in [pc.base - 4 * s, pc.base - 10 * s] { c.rect(pc.x - 7 * s, y, 14 * s, max(1, s / 2) + s / 2, chrome) }
        c.ellipse(pc.x, pc.base - 16 * s, 8 * s, 2 * s, chrome); c.ellipse(pc.x - s, pc.base - 17 * s, 5 * s, s, chromeL)
        c.rect(pc.x - s, pc.base - 19 * s, 2 * s, 2 * s, chromeD)
        for x in [c.w * 54 / 100, c.w * 65 / 100] {
            c.rect(x, k.top - 4 * s, 4 * s, 4 * s, chrome); c.rect(x, k.top - 4 * s, s, 4 * s, chromeL); c.rect(x + s, k.top - 4 * s, 2 * s, s, C(0xE8E4DA))
            c.rect(x + 5 * s, k.top - 3 * s, 2 * s, 3 * s, C(0xB8C8C8)); c.rect(x + 5 * s, k.top - 4 * s, 2 * s, s, chrome)
            c.rect(x + 8 * s, k.top - 5 * s, s, 5 * s, C(0xB02A22)); c.rect(x + 8 * s, k.top - 6 * s, s, s, C(0xE0DCD0))
        }
        let cup = f.cup
        c.rect(cup - 3 * s, k.top - s, 7 * s, s, C(0xE4DED0))
        c.rect(cup - 2 * s, k.top - 4 * s, 4 * s, 3 * s, C(0xE0DACC)); c.rect(cup - 2 * s, k.top - 4 * s, s, 3 * s, C(0xF0ECE0))
        c.rect(cup + s, k.top - 4 * s, s, 3 * s, C(0xB0AA9C)); c.rect(cup - 2 * s, k.top - 4 * s, 4 * s, max(1, s / 2), C(0x3A2214))
        c.rect(cup + 2 * s, k.top - 3 * s, s, 2 * s, C(0xC8C2B4))
        let rgx = k.x1 - 14 * s
        c.rect(rgx, k.top - 9 * s, 12 * s, 9 * s, chrome); c.rect(rgx, k.top - 9 * s, s, 9 * s, chromeL); c.rect(rgx + 11 * s, k.top - 9 * s, s, 9 * s, chromeD)
        c.rect(rgx + 2 * s, k.top - 12 * s, 8 * s, 3 * s, chromeD); c.rect(rgx + 3 * s, k.top - 11 * s, 6 * s, s, C(0xD8CCB0))
        for j in 0..<6 { c.rect(rgx + 2 * s + (j % 3) * 3 * s, k.top - 7 * s + (j / 3) * 2 * s, 2 * s, s, C(0x2A2A2E)) }
        c.rect(rgx, k.top - 2 * s, 12 * s, max(1, s / 2), chromeD)
        // The stools along the counter: chrome posts, red seats lit on top.
        for x in stride(from: k.x0 + 10 * s, to: k.x1 - 6 * s, by: 22 * s) {
            c.rect(x - 4 * s, g - 10 * s, 9 * s, 2 * s, red); c.rect(x - 4 * s, g - 10 * s, 9 * s, max(1, s / 2), redL)
            c.rect(x - 4 * s, g - 8 * s, 9 * s, s, chrome)
            c.rect(x, g - 7 * s, s, 6 * s, chromeD); c.rect(x, g - 7 * s, max(1, s / 2), 6 * s, chromeL)
            c.rect(x - 2 * s, g - s, 5 * s, s, chrome)
        }
        // The floor: black and white checker gone to two mid greys, plain enough for the crew.
        c.ground(g, C(0x5E5852), edge: C(0x7A746C), speck: C(0x56504A), seed: 97)
        for (ri, y) in stride(from: g + 1, to: c.h, by: 5 * s).enumerated() {
            for (ci, x) in stride(from: 0, to: c.w, by: 5 * s).enumerated() where (ri + ci) % 2 == 0 {
                c.rect(x, y, 5 * s, min(5 * s, c.h - y), C(0x4A4440))
            }
        }
    }

    /// The screen saver's top of the diner: a pressed tin ceiling with the fans' rods and hubs (the moving layer turns
    /// their blades) and frosted globe lamps between them, the menu board over the counter with MENU across its top,
    /// two columns of dishes and prices and a slice of pie drawn in the corner, the EAT sign in red neon on the left,
    /// and a row of framed records on the right.
    private static func huntDinerCeiling(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntDinerFrame(c, g), top = f.ceiling
        let chrome = C(0xB4BAC0), chromeL = C(0xE4E8EC), chromeD = C(0x6E747A)
        // Pressed tin: squares with a raised middle, lit on the top and left, darker further up.
        c.gradient(0, top, C(0x5A5A52), C(0x8A8A7E), bands: 5)
        for y in stride(from: 0, to: top - 3 * s, by: 8 * s) {
            for x in stride(from: 0, to: c.w, by: 8 * s) {
                c.rect(x, y, 8 * s, max(1, s / 2), C(0x4A4A44)); c.rect(x, y, max(1, s / 2), 8 * s, C(0x4A4A44))
                c.rect(x + 2 * s, y + 2 * s, 4 * s, max(1, s / 2), C(0xA8A89A)); c.rect(x + 2 * s, y + 2 * s, max(1, s / 2), 4 * s, C(0xA8A89A))
                c.rect(x + 2 * s, y + 6 * s, 4 * s, max(1, s / 2), C(0x5A5A52)); c.rect(x + 6 * s, y + 2 * s, max(1, s / 2), 4 * s, C(0x5A5A52))
            }
        }
        // The soffit across the top of the wall, red with chrome under it.
        c.rect(0, top - 3 * s, c.w, 3 * s, C(0x9A2224)); c.rect(0, top - 3 * s, c.w, max(1, s / 2), C(0xC03A34))
        c.rect(0, top, c.w, s, chrome)
        // The fans' rods and hubs, and the globe lamps between them, a warm glow round each.
        for x in f.fans {
            c.rect(x - s / 2, top + s, max(1, s), f.fanY - top - s, C(0x3A3A3A))
            c.rect(x - 3 * s, f.fanY - s, 6 * s, 3 * s, C(0x5A3A26)); c.rect(x - 3 * s, f.fanY - s, 6 * s, max(1, s / 2), C(0x8A6040))
            c.rect(x - 2 * s, f.fanY + 2 * s, 4 * s, 2 * s, C(0xE8DCB8))
        }
        for x in [c.w * 35 / 100, c.w * 65 / 100] {
            let y = top + 26 * s
            c.rect(x - s / 2, top + s, max(1, s), y - top - 4 * s, C(0x3A3A3A))
            for r in stride(from: 18 * s, to: 3 * s, by: -3 * s) { c.ellipse(x, y, r, r, C(0xF8E8B8, 0.035)) }
            c.circle(x, y, 4 * s, C(0xE8E0C8)); c.circle(x - s, y - s, 2 * s, C(0xFAF6EA)); c.rect(x - 2 * s, y - 5 * s, 4 * s, 2 * s, chrome)
        }
        // A second red pinstripe round the room, under the lamps.
        c.rect(0, top + 40 * s, c.w, s, C(0xA8282A)); c.rect(0, top + 41 * s, c.w, max(1, s / 2), C(0x4E7A6C))
        // A big cut-out coffee cup over the menu board, its steam in red neon.
        let cupX = c.w / 2 + c.w / 100, cupY = f.rail - 96 * s
        c.ellipse(cupX + 2 * s, cupY + 2 * s, 20 * s, 3 * s, C(0x4E7A6C))
        c.ellipse(cupX, cupY, 20 * s, 3 * s, C(0xC8C0A8)); c.ellipse(cupX, cupY - s, 18 * s, 2 * s, C(0xDCD4BC))
        for k in 0..<18 {
            let half = 14 * s - k * s / 3
            c.rect(cupX - half, cupY - 2 * s - k * s, 2 * half, s, C(0xD8CCAA))
            c.rect(cupX - half, cupY - 2 * s - k * s, 3 * s, s, C(0xECE4CC)); c.rect(cupX + half - 3 * s, cupY - 2 * s - k * s, 3 * s, s, C(0xA8A086))
        }
        c.rect(cupX - 13 * s, cupY - 12 * s, 26 * s, 3 * s, C(0xA8282A)); c.rect(cupX - 13 * s, cupY - 12 * s, 26 * s, max(1, s / 2), C(0xCC4A42))
        huntP5Ring(c, cupX + 15 * s, cupY - 11 * s, 5 * s, 2 * s, C(0xC8C0A8))
        c.ellipse(cupX, cupY - 20 * s, 14 * s, 2 * s, C(0xA8A086)); c.ellipse(cupX, cupY - 20 * s, 12 * s, s + s / 2, C(0x4A2A16))
        for k in 0..<3 {
            let sx = cupX + (k - 1) * 8 * s
            for j in 0..<4 {
                let y0 = cupY - 24 * s - j * 5 * s, d = (j % 2 == 0 ? 2 : -2) * s
                c.glowLine(Double(sx), Double(y0), Double(sx + d), Double(y0 - 5 * s), core: C(0xFF8070), glow: C(0xFF4A3A, 0.3),
                           coreR: Double(s) * 0.6, glowR: Double(s) * 2)
            }
        }
        // The menu board.
        let mx0 = c.w * 33 / 100, mx1 = c.w * 69 / 100, my0 = f.rail - 82 * s, my1 = f.rail - 36 * s
        c.rect(mx0 - 2 * s, my0 - 2 * s, mx1 - mx0 + 4 * s, my1 - my0 + 4 * s, chromeD); c.rect(mx0 - 2 * s, my0 - 2 * s, mx1 - mx0 + 4 * s, s, chromeL)
        c.rect(mx0, my0, mx1 - mx0, my1 - my0, C(0x1E2220))
        huntP5Text(c, (mx0 + mx1) / 2, my0 + 3 * s, "MENU", C(0xE8DCB8), 2 * s)
        c.rect(mx0 + 6 * s, my0 + 15 * s, mx1 - mx0 - 12 * s, max(1, s / 2), C(0xB8282A))
        let colW = (mx1 - mx0) / 2
        for col in 0..<2 {
            for row in 0..<6 {
                let y = my0 + 19 * s + row * 4 * s, x = mx0 + 5 * s + col * colW
                let len = (8 + Int(noise(col * 10 + row + 2300) * Double(colW / s - 26))) * s
                c.rect(x, y, len, s, C(0xD8D0B8)); c.rect(x + colW - 14 * s, y, 4 * s, s, C(0xE0B040))
            }
        }
        // A slice of pie drawn in the corner.
        let px = mx1 - 10 * s, py = my0 + 6 * s
        c.rect(px - 3 * s, py + 3 * s, 7 * s, s, C(0xC08A44))
        for j in 0..<3 { c.rect(px - 3 * s + j * 2 * s, py + (2 - j) * s, 7 * s - j * 2 * s, s, C(0xA8302C)) }
        c.rect(px - 3 * s, py + 2 * s, 7 * s, max(1, s / 2), C(0xD8A458))
        // The EAT sign in red neon high on the left wall.
        let ex = c.w * 13 / 100, ey = f.rail - 126 * s
        c.rect(ex - 16 * s, ey - 4 * s, 32 * s, 18 * s, C(0x2A1A1A)); c.rect(ex - 16 * s, ey - 4 * s, 32 * s, s, C(0x4A3A3A))
        huntP5Text(c, ex, ey, "EAT", C(0xFF4A3A, 0.35), 2 * s + max(1, s / 2))
        huntP5Text(c, ex, ey + s, "EAT", C(0xFF8070), 2 * s)
        // Framed records on the right.
        for (j, x) in stride(from: c.w * 76 / 100, to: c.w - 12 * s, by: 14 * s).enumerated() {
            let y = f.rail - 124 * s + (j % 2) * 3 * s
            c.rect(x, y, 11 * s, 11 * s, chromeD); c.rect(x + s, y + s, 9 * s, 9 * s, C(0x3A4A48))
            c.circle(x + 5 * s + s / 2, y + 5 * s + s / 2, 4 * s, C(0x141414)); c.circle(x + 5 * s + s / 2, y + 5 * s + s / 2, s, j % 2 == 0 ? C(0xC83A2A) : C(0xE0B040))
        }
    }

    /// The diner's life: the pies going slowly round in their case, steam curling up off the coffee pots and the mug,
    /// and on the screen saver the ceiling fans turning.
    static func huntDinerLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntDinerFrame(c, g)
        // The pies: four a plate, cherry, apple, blueberry and lemon meringue, the far ones dimmer.
        let fills: [(top: UInt32, body: UInt32)] = [(0xA8302C, 0xC08A44), (0xD8A458, 0xC08A44), (0x4A3A7A, 0xC08A44), (0xEAE0C4, 0xE8D070)]
        for (tier, y) in [f.pie.base - 4 * s, f.pie.base - 10 * s].enumerated() {
            let spin = t * 0.5 + Double(tier) * 0.8
            var pies: [(x: Int, depth: Double, kind: Int)] = []
            for i in 0..<4 {
                let a = spin + Double(i) * .pi / 2
                pies.append((x: f.pie.x + Int(cos(a) * Double(4 * s)), depth: sin(a), kind: (i + tier) % 4))
            }
            for p in pies.sorted(by: { $0.depth < $1.depth }) {
                let dim = p.depth < 0 ? 0.35 : 0.0, fl = fills[p.kind]
                let body = lerp(C(fl.body), C(0x3A4448), dim), top = lerp(C(fl.top), C(0x3A4448), dim)
                c.rect(p.x - 2 * s, y - s, 5 * s, s, body); c.rect(p.x - 2 * s, y - 2 * s, 5 * s, s, top)
                if p.kind == 3 { c.rect(p.x - s, y - 3 * s, 3 * s, s, top) }
                if p.kind == 0 { c.rect(p.x, y - 2 * s, s, s, body) }
            }
        }
        c.rect(f.pie.x - 6 * s, f.pie.base - 15 * s, s, 11 * s, C(0xFFFFFF, 0.3))
        // Steam off the pots and the mug.
        let sources = [(f.pots[0], f.back - 7 * s), (f.pots[1], f.back - 7 * s), (f.cup, f.counter.top - 4 * s)]
        for (n, src) in sources.enumerated() {
            for j in 0..<4 {
                let ph = (t * 0.45 + Double(j) * 0.25 + Double(n) * 0.37).truncatingRemainder(dividingBy: 1)
                let x = src.0 + Int(sin(ph * 6 + t + Double(n)) * Double(s) * 1.5), y = src.1 - Int(ph * Double(10 * s))
                c.rect(x, y, s, s, C(0xF4F4F0, 0.38 * (1 - ph)))
            }
        }
        // The fans' blades, flattened by the angle we see them at.
        for (n, x) in f.fans.enumerated() {
            let spin = t * 2.2 + Double(n)
            for b in 0..<4 {
                let a = spin + Double(b) * .pi / 2
                let ex = x + Int(cos(a) * Double(15 * s)), ey = f.fanY + Int(sin(a) * Double(2 * s))
                huntP5Line(c, x, f.fanY, ex, ey, sin(a) < 0 ? C(0x4A2E1E) : C(0x6A4428), Double(s) * 0.9)
            }
        }
    }
}

// MARK: - Roman Enterprises

/// The city's towers outside the glass, far ones first: where each stands, how wide, its top row, and whether it's
/// in the near row. The still picture and the moving layer share it so the windows that twinkle line up.
private func huntP5Towers(_ c: PixelCanvas, _ g: Int, horizon: Int, tall: Bool) -> [(x: Int, w: Int, top: Int, near: Bool)] {
    let s = Scenes.unit(g)
    var out: [(x: Int, w: Int, top: Int, near: Bool)] = []
    for layer in 0..<2 {
        var x = -Int(noise(layer * 50 + 3) * 20) * s, i = layer * 300
        while x < c.w {
            let w = (8 + Int(noise(i) * 14)) * s
            let maxH = tall ? (layer == 0 ? 150 : 90) : (layer == 0 ? 32 : 20)
            let h = (6 + Int(noise(i + 1) * Double(maxH - 6))) * s
            out.append((x: x, w: w, top: horizon - h, near: layer == 1))
            x += w + (layer == 0 ? Int(noise(i + 2) * 4) * s : (4 + Int(noise(i + 2) * 16)) * s)
            i += 7
        }
    }
    return out
}

/// Whether the window in column `col`, row `row` of tower `n` is lit, and in what colour.
private func huntP5Lit(_ n: Int, _ col: Int, _ row: Int, near: Bool) -> Px? {
    let h = noise(n * 1009 + row * 37 + col * 7 + 2500)
    guard h > (near ? 0.62 : 0.72) else { return nil }
    let warm = noise(n * 1009 + row * 37 + col * 7 + 2501) > 0.35
    if near { return warm ? C(0xE8C070) : C(0xC8D8F0) }
    return warm ? C(0x9A7E50) : C(0x7A8AA4)
}

extension Scenes {
    /// Where things stand on Roman's floor, shared by the still picture and the moving layer: the soffit's bottom row,
    /// the walnut feature wall's right edge, the city's horizon, the desk (its middle and top), the goo's drip point,
    /// and on the screen saver the tower that rises outside (its middle and top).
    static func huntRomanFrame(_ c: PixelCanvas, _ g: Int) -> (soffit: Int, wall: Int, horizon: Int, desk: (x: Int, top: Int),
                                                              drip: (x: Int, y: Int), tower: (x: Int, top: Int)) {
        let s = unit(g), tall = isTall(c)
        let soffit = tall ? g * 7 / 100 + 6 * s : 5 * s
        let wall = max(60 * s, c.w * 14 / 100)
        // The tower outside stands in the middle of a pane, so no mullion crosses its name.
        let pane = max(0, (c.w * 58 / 100 - wall - 30 * s) / (46 * s))
        return (soffit, wall, tall ? g - 40 * s : g - 26 * s, (x: c.w * 74 / 100, top: g - 14 * s),
                (x: wall + 14 * s, y: soffit), (x: wall + 30 * s + pane * 46 * s + 24 * s, top: soffit + 34 * s))
    }

    /// Roman Enterprises, the top floor of Dick Roman's glass tower at night: floor-to-ceiling glass in a steel grid
    /// with the city's towers lit up beyond it and the streets glittering below, a walnut feature wall on the left with
    /// ROMAN ENTERPRISES in brushed steel over a black credenza, a sculpture and a decanter, tall snake plants in
    /// charcoal pots, Dick's long black desk on chrome legs with its lamp and laptop and his high-backed leather chair,
    /// recessed lights in a dark soffit, and a stain of black Leviathan goo seeping from the ceiling into a puddle on
    /// the polished stone. On the screen saver the glass rises two storeys and the company's own tower rises outside,
    /// its crown lit with the name and a red light on its spire.
    static func huntRoman(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRomanFrame(c, g), tall = isTall(c)
        let chrome = C(0x9AA0A8), chromeL = C(0xC8CED6), chromeD = C(0x5A6068)
        // The night sky over the city, the haze of its light low down.
        c.gradient(0, f.horizon, C(0x080C18), C(0x2A2A48), bands: tall ? 9 : 6)
        c.gradient(f.horizon - 10 * s, f.horizon, C(0x2A2A48), C(0x4A3A56), bands: 3)
        if tall {
            c.stars(0, f.horizon - 120 * s, density: 160, seed: 41)
            c.circle(c.w * 18 / 100, g * 18 / 100, 7 * s, C(0xD8DCE4)); c.circle(c.w * 18 / 100 + 2 * s, g * 18 / 100 - s, 6 * s, C(0xB8BEC8))
            huntRomanTower(c, g)
        }
        // The towers, far then near, their windows lit here and there.
        for (n, tw) in huntP5Towers(c, g, horizon: f.horizon, tall: tall).enumerated() {
            let body = tw.near ? C(0x10141F) : C(0x1A2034)
            c.rect(tw.x, tw.top, tw.w, f.horizon - tw.top, body)
            c.rect(tw.x, tw.top, max(1, s / 2), f.horizon - tw.top, tw.near ? C(0x1E2436) : C(0x262E46))
            for (row, y) in stride(from: tw.top + 2 * s, to: f.horizon - s, by: 3 * s).enumerated() {
                for (col, x) in stride(from: tw.x + s, to: tw.x + tw.w - s, by: 3 * s).enumerated() {
                    if let lit = huntP5Lit(n, col, row, near: tw.near) { c.rect(x, y, s, s, lit) }
                }
            }
            if !tw.near && f.horizon - tw.top > (tall ? 100 : 26) * s {   // a mast with its light on the tallest
                c.rect(tw.x + tw.w / 2, tw.top - 5 * s, max(1, s / 2), 5 * s, C(0x2A3044))
            }
        }
        // The streets below: a dark carpet of the city running to the horizon, its lights in rows.
        c.rect(0, f.horizon, c.w, g - f.horizon, C(0x0C101C))
        var gap = 2 * s, y = f.horizon + s
        while y < g - 4 * s {
            for x in stride(from: Int(noise(y) * 6) * s, to: c.w, by: max(2 * s, gap * 2)) where noise(x * 3 + y) > 0.35 {
                c.rect(x, y, s, s, noise(x + y * 5) > 0.5 ? C(0xE8B060, 0.75) : C(0xC8D0E0, 0.5))
            }
            y += gap; gap += s
        }
        // The glass: steel mullions with a lit edge, transoms, a faint reflection slanting across each pane.
        c.rect(f.wall, g - 4 * s, c.w - f.wall, 4 * s, C(0x14161C)); c.rect(f.wall, g - 4 * s, c.w - f.wall, max(1, s / 2), C(0x3A3E48))
        for x in stride(from: f.wall + 30 * s, to: c.w, by: 46 * s) {
            c.glowLine(Double(x + 8 * s), Double(f.soffit + 4 * s), Double(x + 30 * s), Double(g - 10 * s), core: C(0xA0B8D8, 0.05),
                       glow: C(0, 0), coreR: Double(3 * s), glowR: Double(3 * s) + 0.1)
            c.rect(x, f.soffit, 3 * s, g - f.soffit, C(0x1C2028)); c.rect(x, f.soffit, max(1, s / 2), g - f.soffit, C(0x4A505A))
        }
        if tall {
            for ty in stride(from: f.soffit + 50 * s, to: g - 20 * s, by: 50 * s) {
                c.rect(f.wall, ty, c.w - f.wall, 2 * s, C(0x1C2028)); c.rect(f.wall, ty, c.w - f.wall, max(1, s / 2), C(0x4A505A))
            }
        }
        // The soffit and its recessed lights, a soft cone under each.
        if tall { c.rect(0, 0, c.w, f.soffit - 6 * s, C(0x101216)); c.rect(0, f.soffit - 7 * s, c.w, s, C(0x2A2C34)) }
        c.rect(0, f.soffit - 5 * s, c.w, 5 * s, C(0x16181E)); c.rect(0, f.soffit - s, c.w, s, C(0x34363E))
        for x in stride(from: 30 * s, to: c.w, by: 54 * s) {
            c.rect(x, f.soffit - s, 3 * s, s, C(0xF4DCA0))
            for r in stride(from: 12 * s, to: 2 * s, by: -3 * s) { c.ellipse(x + s, f.soffit + r, r / 2 + s, r, C(0xF4DCA0, 0.02)) }
        }
        // The walnut feature wall with the company's name in brushed steel, lit from above.
        c.rect(0, f.soffit, f.wall, g - f.soffit, C(0x2A1C16))
        for (j, x) in stride(from: 0, to: f.wall, by: 4 * s).enumerated() {
            c.rect(x, f.soffit, s, g - f.soffit, j % 3 == 0 ? C(0x3A281E) : C(0x22160F))
        }
        c.rect(f.wall - s, f.soffit, s, g - f.soffit, chromeD); c.rect(f.wall, f.soffit, 2 * s, g - f.soffit, C(0x0A0C12))
        let lx = f.wall / 2, ly = g - 46 * s
        for r in stride(from: 22 * s, to: 4 * s, by: -4 * s) { c.ellipse(lx, ly + 2 * s, r * 2, r, C(0xF4DCA0, 0.025)) }
        huntP5Text(c, lx + s, ly + s, "ROMAN", C(0x0A0604), 2 * s)
        huntP5Text(c, lx, ly, "ROMAN", C(0xB8C0CC), 2 * s)
        c.rect(lx - 22 * s, ly + 12 * s, 44 * s, max(1, s / 2), chromeD)
        huntP5Text(c, lx, ly + 14 * s, "ENTERPRISES", C(0x9AA2AE), s)
        if tall { huntRomanArt(c, g) }
        // The credenza under it, a chrome sculpture and a decanter on it.
        let cx0 = 4 * s, cx1 = f.wall - 6 * s
        c.rect(cx0, g - 12 * s, cx1 - cx0, 10 * s, C(0x141418)); c.rect(cx0, g - 12 * s, cx1 - cx0, max(1, s / 2), C(0x44464E))
        for x in stride(from: cx0 + (cx1 - cx0) / 3, to: cx1 - 2 * s, by: (cx1 - cx0) / 3) { c.rect(x, g - 11 * s, max(1, s / 2), 9 * s, C(0x0A0A0E)) }
        c.rect(cx0 + 2 * s, g - 2 * s, s, 2 * s, chromeD); c.rect(cx1 - 3 * s, g - 2 * s, s, 2 * s, chromeD)
        huntP5Ring(c, cx0 + 10 * s, g - 18 * s, 5 * s, s + s / 2, chrome); c.rect(cx0 + 9 * s, g - 13 * s, 3 * s, s, chromeD)
        c.px(cx0 + 7 * s, g - 21 * s, chromeL)
        let dcx = cx1 - 12 * s
        c.rect(dcx, g - 17 * s, 4 * s, 5 * s, C(0xA06A28)); c.rect(dcx, g - 17 * s, s, 5 * s, C(0xD8A458))
        c.rect(dcx + s, g - 19 * s, 2 * s, 2 * s, C(0x8AA0A8)); c.rect(dcx + 6 * s, g - 15 * s, 2 * s, 3 * s, C(0x8AA0A8))
        // The snake plants, their leaves in upright strokes catching a little of the city's light.
        for px in [f.wall + 36 * s, c.w - 12 * s] {
            for j in 0..<7 {
                let tip = (16 + Int(noise(px / max(1, s) + j) * 10)) * s, lean = (j - 3) * 2 * s
                huntP5Line(c, px + (j - 3) * s, g - 10 * s, px + lean, g - 10 * s - tip, j % 2 == 0 ? C(0x2A4A34) : C(0x3A6044), Double(s) * 0.8)
                c.px(px + lean, g - 10 * s - tip, C(0x7A9A5A))
            }
            c.rect(px - 4 * s, g - 10 * s, 9 * s, 10 * s, C(0x26282E)); c.rect(px - 4 * s, g - 10 * s, 2 * s, 10 * s, C(0x40444C))
            c.rect(px - 4 * s, g - 10 * s, 9 * s, max(1, s / 2), C(0x50545C))
        }
        // Dick's chair, behind the desk: a high tufted back in black leather, lit down its left.
        let d = f.desk
        c.rect(d.x + 3 * s, g - 33 * s, 14 * s, 19 * s, C(0x1A1A20)); c.ellipse(d.x + 10 * s, g - 33 * s, 7 * s, 2 * s, C(0x1A1A20))
        c.rect(d.x + 3 * s, g - 33 * s, s, 19 * s, C(0x3A3A46)); c.rect(d.x + 16 * s, g - 33 * s, s, 19 * s, C(0x0E0E12))
        for ty in stride(from: g - 31 * s, to: g - 16 * s, by: 4 * s) { for tx in stride(from: d.x + 6 * s, to: d.x + 15 * s, by: 4 * s) { c.rect(tx, ty, s, s, C(0x0C0C10)) } }
        // The desk: a long black slab lit along its top, a drawer unit, chrome sled legs; the lamp, the laptop, files.
        c.rect(d.x - 24 * s, d.top, 48 * s, 2 * s, C(0x18181E)); c.rect(d.x - 24 * s, d.top, 48 * s, max(1, s / 2), C(0x50525C))
        c.rect(d.x - 24 * s, d.top + 2 * s, 48 * s, max(1, s / 2), C(0x0A0A0E))
        c.rect(d.x - 19 * s, d.top + 2 * s, 11 * s, 8 * s, C(0x1C1C22)); c.rect(d.x - 19 * s, d.top + 6 * s, 11 * s, max(1, s / 2), C(0x0C0C10))
        c.rect(d.x - 15 * s, d.top + 4 * s, 3 * s, max(1, s / 2), chrome)
        for lx in [d.x - 23 * s, d.x + 20 * s] {
            c.rect(lx, d.top + 2 * s, 2 * s, g - d.top - 2 * s, chrome); c.rect(lx, d.top + 2 * s, max(1, s / 2), g - d.top - 2 * s, chromeL)
            c.rect(lx - 2 * s, g - s, 6 * s, s, chromeD)
        }
        c.rect(d.x + 8 * s, g - 2 * s, 6 * s, s, chromeD); c.rect(d.x + 10 * s, g - 12 * s, s, 10 * s, chromeD)   // the chair's column
        for r in stride(from: 10 * s, to: 2 * s, by: -2 * s) { c.ellipse(d.x - 12 * s, d.top, r, r / 3 + 1, C(0xF4DCA0, 0.05)) }
        huntP5Line(c, d.x - 18 * s, d.top - s, d.x - 15 * s, d.top - 11 * s, chrome, Double(s) * 0.5)
        huntP5Line(c, d.x - 15 * s, d.top - 11 * s, d.x - 10 * s, d.top - 9 * s, chrome, Double(s) * 0.5)
        c.rect(d.x - 20 * s, d.top - s, 5 * s, s, chromeD); c.rect(d.x - 13 * s, d.top - 9 * s, 6 * s, 2 * s, C(0x2A2C32)); c.rect(d.x - 12 * s, d.top - 7 * s, 4 * s, s, C(0xF4DCA0))
        for r in stride(from: 8 * s, to: 2 * s, by: -2 * s) { c.ellipse(d.x + 4 * s, d.top - 4 * s, r, r, C(0x7AA0D0, 0.04)) }
        c.rect(d.x - s, d.top - s, 9 * s, s, chrome)
        huntP5Line(c, d.x + 7 * s, d.top - s, d.x + 4 * s, d.top - 8 * s, chromeL, Double(s) * 0.6)
        c.rect(d.x + 13 * s, d.top - 2 * s, 7 * s, 2 * s, C(0xD8D4C8)); c.rect(d.x + 13 * s, d.top - 2 * s, 7 * s, max(1, s / 2), C(0x8A3A2A))
        // The goo: a black stain seeping through the soffit, a streak under it, the puddle on the floor.
        let gx = f.drip.x
        c.rect(gx - 7 * s, f.soffit - s, 13 * s, s, C(0x060608)); c.rect(gx - 4 * s, f.soffit, 7 * s, s, C(0x060608))
        c.rect(gx - 6 * s, f.soffit, s, 2 * s, C(0x060608)); c.rect(gx + 4 * s, f.soffit, s, 3 * s, C(0x060608))
        c.rect(gx - 5 * s, f.soffit - s, 3 * s, max(1, s / 2), C(0x3A4660)); c.px(gx + 4 * s, f.soffit + s, C(0x3A4660))
        // The floor: polished dark stone, the glass's mullions faint in its shine.
        c.ground(g, C(0x24262C), edge: C(0x3A3C44), speck: C(0x202228), seed: 103)
        for x in stride(from: f.wall + 30 * s, to: c.w, by: 46 * s) { c.rect(x, g + 1, 2 * s, c.h - g - 1, C(0x2C2E36)) }
        c.ellipse(gx, g + 3 * s, 7 * s, max(1, s + s / 2), C(0x060608)); c.rect(gx - 4 * s, g + 2 * s, 3 * s, max(1, s / 2), C(0x3A4660))
    }

    /// The screen saver's feature wall, high up: a big black canvas in a thin steel frame with one red slash across it
    /// under its own picture light, and above it a row of glass awards on a floating shelf, each catching the light.
    private static func huntRomanArt(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRomanFrame(c, g)
        let cx = f.wall / 2, top = f.soffit + 40 * s, w = min(f.wall - 12 * s, 44 * s), h = 60 * s
        for r in stride(from: 30 * s, to: 4 * s, by: -5 * s) { c.ellipse(cx, top + 4 * s, r * 3 / 2, r, C(0xF4DCA0, 0.025)) }
        c.rect(cx - w / 2 - s, top - s, w + 2 * s, h + 2 * s, C(0x8A9098)); c.rect(cx - w / 2, top, w, h, C(0x0E0E12))
        c.rect(cx - w / 2, top, w, s, C(0x2A2A30))
        huntP5Line(c, cx - w / 3, top + h * 3 / 4, cx + w / 3, top + h / 5, C(0x9A1E1A), Double(s) * 1.6)
        huntP5Line(c, cx - w / 3 + s, top + h * 3 / 4 - s, cx + w / 3 - 2 * s, top + h / 5 + s, C(0xC83A2E), Double(s) * 0.5)
        c.rect(cx - 6 * s, top - 4 * s, 12 * s, 2 * s, C(0x5A6068)); c.rect(cx - 5 * s, top - 2 * s, 10 * s, max(1, s / 2), C(0xF4DCA0))
        let sy = top - 20 * s
        c.rect(cx - w / 2, sy, w, 2 * s, C(0x1A1410)); c.rect(cx - w / 2, sy, w, max(1, s / 2), C(0x4A3A2E))
        for (j, x) in stride(from: cx - w / 2 + 4 * s, to: cx + w / 2 - 4 * s, by: 9 * s).enumerated() {
            let ah = (6 + (j % 3) * 2) * s
            c.rect(x, sy - ah, 4 * s, ah, C(0x6A8A9A)); c.rect(x, sy - ah, s, ah, C(0xC8DCE4)); c.rect(x + 3 * s, sy - ah, s, ah, C(0x3A4A56))
            c.rect(x - s, sy - s, 6 * s, s, C(0x2A2C32))
        }
    }

    /// The screen saver's tower outside: Roman Enterprises' own, rising above the city in dark glass, lit floors in
    /// bands, set back at its crown, ROMAN in pale light near the top and the spire above.
    private static func huntRomanTower(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntRomanFrame(c, g), t = f.tower
        let glass = C(0x182238), glassL = C(0x2A3656), glassD = C(0x10162A)
        let w0 = 56 * s
        c.rect(t.x - w0 / 2, t.top + 24 * s, w0, f.horizon - t.top - 24 * s, glass)
        c.rect(t.x - w0 / 2, t.top + 24 * s, 6 * s, f.horizon - t.top - 24 * s, glassL)
        c.rect(t.x + w0 / 2 - 6 * s, t.top + 24 * s, 6 * s, f.horizon - t.top - 24 * s, glassD)
        for x in stride(from: t.x - w0 / 2 + 6 * s, to: t.x + w0 / 2, by: 6 * s) { c.rect(x, t.top + 24 * s, max(1, s / 2), f.horizon - t.top - 24 * s, glassD) }
        for (j, y) in stride(from: t.top + 30 * s, to: f.horizon, by: 4 * s).enumerated() where noise(j + 2700) > 0.45 {
            c.rect(t.x - w0 / 2 + 6 * s, y, w0 - 12 * s, max(1, s / 2), C(0x6A80A8, 0.55))
        }
        // The crown: two setbacks and the name panel.
        c.rect(t.x - 22 * s, t.top + 10 * s, 44 * s, 14 * s, glass); c.rect(t.x - 22 * s, t.top + 10 * s, 4 * s, 14 * s, glassL)
        c.rect(t.x - 14 * s, t.top, 28 * s, 10 * s, glass); c.rect(t.x - 14 * s, t.top, 3 * s, 10 * s, glassL)
        c.rect(t.x - 22 * s, t.top + 10 * s, 44 * s, max(1, s / 2), C(0x9AC8F0, 0.6))
        huntP5Text(c, t.x, t.top + 14 * s, "ROMAN", C(0x9AC8F0), s)
        for r in stride(from: 14 * s, to: 4 * s, by: -3 * s) { c.ellipse(t.x, t.top + 16 * s, r * 2, r, C(0x9AC8F0, 0.03)) }
        c.rect(t.x - s / 2, t.top - 22 * s, max(1, s), 22 * s, C(0x4A5068))
    }

    /// Roman's floor's life: windows across the city going on and off, the red lights on the masts and the spire
    /// blinking, and the goo forming a drop at the stain, falling and landing in its puddle.
    static func huntRomanLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntRomanFrame(c, g), tall = isTall(c)
        for (n, tw) in huntP5Towers(c, g, horizon: f.horizon, tall: tall).enumerated() {
            let body = tw.near ? C(0x10141F) : C(0x1A2034)
            for (row, y) in stride(from: tw.top + 2 * s, to: f.horizon - s, by: 3 * s).enumerated() {
                for (col, x) in stride(from: tw.x + s, to: tw.x + tw.w - s, by: 3 * s).enumerated() {
                    let k = n * 1009 + row * 37 + col * 7
                    guard noise(k + 2600) > 0.965 else { continue }
                    let on = sin(t * (0.3 + noise(k + 2601) * 0.5) + noise(k + 2602) * 6) > 0
                    let lit = huntP5Lit(n, col, row, near: tw.near) ?? (tw.near ? C(0xE8C070) : C(0x9A7E50))
                    c.rect(x, y, s, s, on ? lit : body)
                }
            }
            if !tw.near && f.horizon - tw.top > (tall ? 100 : 26) * s && sin(t * 2.4 + Double(n)) > 0.3 {
                c.rect(tw.x + tw.w / 2 - s / 2, tw.top - 6 * s, max(1, s), max(1, s), C(0xFF3A2A))
            }
        }
        if tall && sin(t * 2) > 0.2 {
            let tp = f.tower
            c.rect(tp.x - s, tp.top - 24 * s, 2 * s, 2 * s, C(0xFF3A2A))
            c.ellipse(tp.x, tp.top - 23 * s, 4 * s, 3 * s, C(0xFF3A2A, 0.2))
        }
        // The drop: swelling at the stain for three seconds, a quick fall, then a ripple on the puddle.
        let gx = f.drip.x, top = f.soffit + 2 * s, floor = g + 2 * s
        let ph = t.truncatingRemainder(dividingBy: 5.0) / 5.0
        if ph < 0.66 {
            let r = Int(ph / 0.66 * 1.6 * Double(s))
            c.rect(gx - s / 2, top - s, max(1, s), s + r, C(0x060608))
            c.circle(gx, top + r, r, C(0x060608)); c.px(gx - max(0, r - 1), top + r - max(0, r - 1), C(0x4A5A78))
        } else if ph < 0.88 {
            let q = (ph - 0.66) / 0.22, y = top + Int(q * q * Double(floor - top))
            c.rect(gx - s / 2, y - s, max(1, s), 3 * s, C(0x060608)); c.px(gx - s / 2, y - s, C(0x4A5A78))
        } else {
            let q = (ph - 0.88) / 0.12, d = Int(q * Double(6 * s))
            c.rect(gx - d - s, floor, s, max(1, s / 2), C(0x4A5A78, 0.7 * (1 - q))); c.rect(gx + d, floor, s, max(1, s / 2), C(0x4A5A78, 0.7 * (1 - q)))
        }
    }
}

// MARK: - Apocalypse World

/// A ruined building standing on row `base`: `w` wide and up to `h` tall, its top broken away in jagged steps (worst
/// on one side), the floors showing as rows of empty windows with the sky (or the dark, or a fire) through them, a
/// lit rim along its top and left edge, and rebar poking up from the break.
private func huntP5Ruin(_ c: PixelCanvas, _ x: Int, _ base: Int, _ w: Int, _ h: Int, _ s: Int, seed: Int,
                        body: Px, lit: Px, hole: Px, fire: Bool) {
    let cols = max(1, w / (2 * s))
    var tops: [Int] = []
    let fall = noise(seed + 1) > 0.5
    for k in 0..<cols {
        let u = Double(k) / Double(cols), slope = fall ? u : 1 - u
        let drop = Int((slope * slope * 0.55 + noise(seed * 31 + k) * 0.18) * Double(h))
        tops.append(base - h + drop)
    }
    for (k, top) in tops.enumerated() {
        let cx = x + k * 2 * s
        c.rect(cx, top, 2 * s, base - top, body)
        c.rect(cx, top, 2 * s, s, lit)
    }
    c.rect(x, tops[0], s, base - tops[0], lit)
    // The floors and their windows.
    for (fl, wy) in stride(from: base - h + 3 * s, to: base - 3 * s, by: 5 * s).enumerated() {
        for (j, wx) in stride(from: x + 2 * s, to: x + w - 2 * s, by: 4 * s).enumerated() {
            let k = min(cols - 1, (wx - x) / (2 * s)), k2 = min(cols - 1, (wx + 2 * s - x) / (2 * s))
            guard wy > max(tops[k], tops[k2]) + s else { continue }
            let burning = fire && noise(seed * 7 + fl * 13 + j) > 0.9
            c.rect(wx, wy, 2 * s, 2 * s, burning ? C(0xE0702A) : hole)
        }
        if noise(seed + fl * 5 + 3) > 0.6 { c.rect(x, wy + 3 * s, w, max(1, s / 2), lit) }   // a slab edge showing
    }
    // Rebar bent up out of the break.
    for j in 0..<3 {
        let k = Int(noise(seed * 3 + j + 40) * Double(cols)) % cols, rx = x + k * 2 * s
        huntP5Line(c, rx, tops[k], rx + (j - 1) * 2 * s, tops[k] - (2 + j) * s, C(0x1A100C), 0.4)
    }
}

/// A column of smoke rising from (`x`, `y0`) up to row `y1`, widening and leaning as it goes, see-through.
private func huntP5Smoke(_ c: PixelCanvas, _ x: Int, _ y0: Int, _ y1: Int, _ s: Int, lean: Double, seed: Int, col: Px) {
    guard y0 > y1 else { return }
    let total = Double(y0 - y1)
    for y in stride(from: y0, to: y1, by: -s) {
        let up = Double(y0 - y)
        let lump = noise(seed * 7 + (y0 - y) / (5 * s)) * Double(4 * s)   // billows down its sides
        let half = Int(Double(5 * s) + up * 0.1 + lump + sin(up * 0.05 + Double(seed)) * Double(2 * s))
        let cx = x + Int(up * lean + sin(up * 0.03 + Double(seed)) * Double(4 * s))
        let a = 1 - 0.55 * up / total
        c.rect(cx - half, y, 2 * half, s, col.alpha(a))
        c.rect(cx - half - s, y, s, s, col.alpha(a * 0.4)); c.rect(cx + half, y, s, s, col.alpha(a * 0.4))
    }
}

/// The great dark of an angel's wings in the cloud, spread wide from (`cx`, `cy`), each wing `span` across: drawn once
/// as one see-through shadow so its overlapping feathers don't build up.
private func huntP5WingShadow(_ c: PixelCanvas, _ cx: Int, _ cy: Int, _ span: Int, _ s: Int, _ col: Px) {
    typealias Seg = (x0: Double, y0: Double, x1: Double, y1: Double, r0: Double, r1: Double)
    var segs: [Seg] = []
    let sp = Double(span)
    for side in [-1.0, 1.0] {
        let sx = Double(cx) + side * Double(4 * s), sy = Double(cy)
        let ex = Double(cx) + side * sp * 0.4, ey = Double(cy) - sp * 0.2
        let wx = Double(cx) + side * sp * 0.78, wy = Double(cy) - sp * 0.3
        segs.append((x0: sx, y0: sy, x1: ex, y1: ey, r0: Double(6 * s), r1: Double(5 * s)))
        segs.append((x0: ex, y0: ey, x1: wx, y1: wy, r0: Double(5 * s), r1: Double(3 * s)))
        for k in 0..<14 {
            let u = Double(k) / 13
            let bx = u < 0.5 ? sx + (ex - sx) * u * 2 : ex + (wx - ex) * (u - 0.5) * 2
            let by = u < 0.5 ? sy + (ey - sy) * u * 2 : ey + (wy - ey) * (u - 0.5) * 2
            let ang = 0.1 + u * u * 1.4, len = sp * (0.26 + 0.2 * u)
            let tx = bx + side * sin(ang) * len, ty = by + cos(ang) * len
            segs.append((x0: bx, y0: by, x1: tx, y1: ty, r0: Double(5 * s) + sp * 0.02, r1: Double(2 * s)))
            segs.append((x0: bx, y0: by, x1: bx + (tx - bx) * 0.6, y1: by + (ty - by) * 0.6, r0: Double(7 * s) + sp * 0.02, r1: Double(5 * s)))
        }
    }
    let x0 = max(0, cx - span - 4 * s), x1 = min(c.w - 1, cx + span + 4 * s)
    let y0 = max(0, cy - Int(sp * 0.42)), y1 = min(c.h - 1, cy + Int(sp * 0.6))
    guard x1 > x0, y1 > y0 else { return }
    for y in y0...y1 {
        for x in x0...x1 {
            let px = Double(x) + 0.5, py = Double(y) + 0.5
            for sg in segs {
                let dx = sg.x1 - sg.x0, dy = sg.y1 - sg.y0
                let l2 = max(0.0001, dx * dx + dy * dy)
                let t = max(0, min(1, ((px - sg.x0) * dx + (py - sg.y0) * dy) / l2))
                let ex = sg.x0 + t * dx - px, ey = sg.y0 + t * dy - py
                let r = sg.r0 + (sg.r1 - sg.r0) * t
                if ex * ex + ey * ey <= r * r { c.px(x, y, col); break }
            }
        }
    }
}

extension Scenes {
    /// Where things stand in Apocalypse World, shared by the still picture and the moving layer: the horizon, the
    /// fires (each a flame's foot), the cloud deck's lower edge on the screen saver, and the burnt-out car.
    static func huntApocalypseFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, fires: [(x: Int, y: Int, size: Int)], clouds: Int, car: Int) {
        let s = unit(g), tall = isTall(c)
        let fires: [(x: Int, y: Int, size: Int)] = [(x: c.w * 30 / 100, y: g - 13 * s, size: 3), (x: c.w * 64 / 100, y: g - 21 * s, size: 2),
                                                    (x: c.w * 93 / 100, y: g - 9 * s, size: 2)]
        return (g - 22 * s, fires, tall ? g * 36 / 100 : -1, c.w * 8 / 100)
    }

    /// Apocalypse World, the world where the angels' war went on and burnt everything: an orange sky thick with smoke
    /// and a dull sun, broken towers on the skyline with the sky showing through their empty floors, nearer shells of
    /// buildings, a highway overpass snapped in the middle with its rebar hanging, a torn billboard, rubble and
    /// sandbags, a burnt-out car with no glass or tyres, a fire in an oil drum, a street lamp bent over, and cracked
    /// asphalt with the lane line fading. On the screen saver the smoke rises in columns into a heavy cloud deck lit
    /// orange from below, and in the cloud lies the vast shadow of an angel's wings.
    static func huntApocalypse(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntApocalypseFrame(c, g), tall = isTall(c)
        let rubble = C(0x4A3A32), rubbleL = C(0x6E5646), rubbleD = C(0x2A1E1A)
        // The sky: smoke-dark up high, burning orange low down.
        if tall {
            c.gradient(0, f.clouds, C(0x1E0C08), C(0x6A2A16), bands: 6)
            c.gradient(f.clouds, f.horizon, C(0x7A3218), C(0xE8823A), bands: 10)
        } else {
            c.gradient(0, f.horizon, C(0x8A3A1C), C(0xE8823A), bands: 7)
        }
        // The sun, dull through the smoke.
        let sun = (x: c.w * 22 / 100, y: tall ? g * 46 / 100 : 13 * s)
        for r in stride(from: 26 * s, to: 8 * s, by: -4 * s) { c.circle(sun.x, sun.y, r, C(0xF8B060, 0.06)) }
        c.circle(sun.x, sun.y, 7 * s, C(0xF4B868)); c.circle(sun.x - s, sun.y - s, 5 * s, C(0xFAD498))
        // Streaks of smoke across the sky.
        let streaks: [(Int, Int, Int)] = tall ? [(30, 44, 70), (70, 52, 90), (50, 60, 60), (12, 66, 50), (86, 70, 60)] : [(30, 12, 70), (72, 6, 90), (52, 20, 50)]
        for (xp, yp, len) in streaks {
            let y = tall ? g * yp / 100 : yp * s
            wisp(c, c.w * xp / 100, y, len * s, C(0x4A1E12, 0.45), s: s)
        }
        if tall { huntApocalypseClouds(c, g) }
        // The skyline: broken towers hazed by smoke, the sky through their floors.
        let farBody = C(0x7A3A22), farLit = C(0x9A4A28), farHole = C(0xC86A34)
        var x = -6 * s, i = 0
        while x < c.w {
            let w = (14 + Int(noise(i + 3000) * 18)) * s, h = (tall ? 30 + Int(noise(i + 3001) * 70) : 12 + Int(noise(i + 3001) * 20)) * s
            huntP5Ruin(c, x, f.horizon - 4 * s, w, h, s, seed: i + 3100, body: farBody, lit: farLit, hole: farHole, fire: false)
            x += w + (2 + Int(noise(i + 3002) * 10)) * s; i += 1
        }
        // On the screen saver, the stumps of the city's tallest towers, broken off high.
        if tall {
            for (j, xp) in [6, 50, 86].enumerated() {
                huntP5Ruin(c, c.w * xp / 100, f.horizon - 4 * s, (22 + j * 4) * s, (120 + j * 14) * s, s, seed: 3200 + j,
                           body: C(0x6E3420), lit: farLit, hole: farHole, fire: false)
            }
        }
        // Smoke rising off the ruins.
        let plumes: [(Int, Double)] = [(40, 0.25), (78, 0.35), (12, 0.2)]
        for (n, pl) in plumes.enumerated() {
            huntP5Smoke(c, c.w * pl.0 / 100, f.horizon - 10 * s, tall ? f.clouds : -4 * s, s, lean: pl.1, seed: n + 7, col: C(0x2A140E, 0.55))
        }
        // The snapped overpass on the right: the deck on its piers, the break, the far end sagging to the ground,
        // rebar hanging from the gap.
        let ox0 = c.w * 56 / 100, ox1 = c.w, oy = g - 34 * s, brk = c.w * 76 / 100
        let deck = C(0x3A2420), deckL = C(0x7A4428), deckD = C(0x221410)
        c.rect(ox0, oy, brk - ox0, 4 * s, deck); c.rect(ox0, oy, brk - ox0, s, deckL); c.rect(ox0, oy + 4 * s, brk - ox0, s, deckD)
        for k in 0..<(4 * s) {
            huntP5Line(c, brk + 8 * s, oy + 6 * s + k, ox1, oy + 16 * s + k, k == 0 ? deckL : deck, 0.5)
        }
        for px in [ox0 + 10 * s, brk - 12 * s, c.w * 92 / 100] {
            c.rect(px, oy + 4 * s, 5 * s, f.horizon - oy, deck); c.rect(px, oy + 4 * s, s, f.horizon - oy, deckL)
        }
        for k in 0..<5 { huntP5Line(c, brk + k * s, oy + 4 * s, brk + k * s + (k % 2) * s, oy + (8 + k * 2) * s, C(0x1A0E0A), 0.4) }
        c.rect(ox0 - 2 * s, oy - 3 * s, brk - ox0 + 2 * s, s, deckD)
        for xx in stride(from: ox0, to: brk, by: 5 * s) { c.rect(xx, oy - 3 * s, max(1, s / 2), 3 * s, deckD) }
        // The nearer shells of buildings on the left and middle.
        let nearBody = C(0x341C16), nearLit = C(0x8A4422), nearHole = C(0x140A08)
        huntP5Ruin(c, c.w * 14 / 100, f.horizon + 2 * s, 30 * s, (tall ? 60 : 34) * s, s, seed: 3301, body: nearBody, lit: nearLit, hole: nearHole, fire: true)
        huntP5Ruin(c, c.w * 40 / 100, f.horizon + 2 * s, 24 * s, (tall ? 44 : 26) * s, s, seed: 3302, body: nearBody, lit: nearLit, hole: nearHole, fire: true)
        // The torn billboard on its legs, strips of its paper hanging.
        let bx = c.w * 47 / 100, by = g - 44 * s
        for lx in [bx + 4 * s, bx + 24 * s] { c.rect(lx, by + 14 * s, 2 * s, f.horizon - by - 14 * s, C(0x221410)) }
        c.rect(bx, by, 30 * s, 14 * s, C(0x2A1812)); c.rect(bx, by, 30 * s, s, nearLit)
        c.rect(bx + 2 * s, by + 2 * s, 10 * s, 10 * s, C(0x6A5A44)); c.rect(bx + 14 * s, by + 2 * s, 6 * s, 6 * s, C(0x5A4E3A))
        for (u, len) in [(4, 6), (8, 4), (15, 9), (22, 5)] { c.rect(bx + u * s, by + 12 * s, 2 * s, len * s, C(0x5A4A38)) }
        // The ground between: dark rubble, lumps catching the orange light on their tops.
        c.rect(0, f.horizon, c.w, g - f.horizon, C(0x2E201A))
        for k in 0..<max(1, c.w / (9 * s)) {
            let rx = Int(noise(k + 3400) * Double(c.w)), ry = f.horizon + Int(noise(k + 3401) * Double(g - f.horizon - 4 * s))
            let rw = (3 + Int(noise(k + 3402) * 8)) * s
            c.rect(rx, ry, rw, 2 * s, rubbleD); c.rect(rx, ry, rw, max(1, s / 2), C(0x5A3A28))
        }
        // The near rubble at both sides: broken slabs, rebar.
        for (side, x0) in [(0, 0), (1, c.w * 86 / 100)] {
            for k in 0..<7 {
                let sx = x0 + Int(noise(side * 50 + k + 3500) * Double(c.w * 12 / 100)), sw = (5 + Int(noise(side * 50 + k + 3510) * 10)) * s
                let sh = (3 + Int(noise(side * 50 + k + 3520) * 6)) * s
                c.rect(sx, g - sh, sw, sh, rubble); c.rect(sx, g - sh, sw, s, rubbleL); c.rect(sx + sw - s, g - sh, s, sh, rubbleD)
            }
            huntP5Line(c, x0 + 6 * s, g - 6 * s, x0 + 9 * s, g - 14 * s, C(0x1A100C), 0.5)
        }
        // Sandbags piled at the left, behind the car.
        let sbx = f.car - 6 * s
        for (row, n) in [(0, 6), (1, 5), (2, 3)] {
            for j in 0..<n {
                let x = sbx + j * 6 * s + row * 3 * s, y = g - (row + 1) * 3 * s
                c.rect(x, y, 6 * s, 3 * s, C(0x6A5A44)); c.rect(x, y, 6 * s, s, C(0x8A765A)); c.rect(x + 5 * s, y, s, 3 * s, C(0x4A3E30))
            }
        }
        // The burnt-out car: charred black and rust, no glass, no tyres.
        let cx = f.car + 22 * s, cb = g
        c.rect(cx, cb - 7 * s, 28 * s, 5 * s, C(0x2A201C)); c.rect(cx, cb - 7 * s, 28 * s, s, C(0x6A4030))
        c.rect(cx + 7 * s, cb - 11 * s, 12 * s, 4 * s, C(0x2A201C)); c.rect(cx + 7 * s, cb - 11 * s, 12 * s, s, C(0x6A4030))
        c.rect(cx + 8 * s, cb - 10 * s, 4 * s, 3 * s, C(0x0E0A08)); c.rect(cx + 13 * s, cb - 10 * s, 5 * s, 3 * s, C(0x0E0A08))
        for (u, w) in [(2, 5), (14, 4), (22, 3)] { c.rect(cx + u * s, cb - 5 * s, w * s, 2 * s, C(0x6A3420)) }
        for wx in [cx + 5 * s, cx + 22 * s] { huntP5Ring(c, wx, cb - 2 * s, 2 * s, s, C(0x4A2A1C)); c.circle(wx, cb - 2 * s, s, C(0x140C0A)) }
        c.rect(cx - s, cb - 6 * s, s, 2 * s, C(0x4A3A32)); c.rect(cx + 28 * s, cb - 6 * s, s, 2 * s, C(0x4A3A32))
        // The oil drum with its fire (the moving layer draws the flames), a glow round it.
        let fd = f.fires[0]
        for r in stride(from: 20 * s, to: 4 * s, by: -4 * s) { c.ellipse(fd.x, fd.y, r, r * 3 / 4, C(0xF09040, 0.045)) }
        c.rect(fd.x - 4 * s, fd.y, 8 * s, g - fd.y, C(0x5A3424)); c.rect(fd.x - 4 * s, fd.y, 2 * s, g - fd.y, C(0x7A4A30))
        c.rect(fd.x + 3 * s, fd.y, s, g - fd.y, C(0x3A2018))
        for y in [fd.y + 3 * s, fd.y + 9 * s] { c.rect(fd.x - 4 * s, y, 8 * s, s, C(0x3A2018)) }
        c.rect(fd.x - 4 * s, fd.y, 8 * s, s, C(0x2A140E))
        for fr in f.fires.dropFirst() {
            for r in stride(from: 12 * s, to: 2 * s, by: -3 * s) { c.ellipse(fr.x, fr.y, r, r * 2 / 3, C(0xF09040, 0.04)) }
            c.rect(fr.x - 4 * s, fr.y, 8 * s, 2 * s, rubbleD); c.rect(fr.x - 4 * s, fr.y, 8 * s, max(1, s / 2), C(0x6A3A22))
        }
        // The street lamp, bent over at the top, its head hanging.
        let lx = c.w * 82 / 100
        c.rect(lx, g - 30 * s, 2 * s, 30 * s, C(0x2A2422)); c.rect(lx, g - 30 * s, max(1, s / 2), 30 * s, C(0x6A4A38))
        huntP5Line(c, lx + s, g - 30 * s, lx - 6 * s, g - 36 * s, C(0x2A2422), Double(s))
        huntP5Line(c, lx - 6 * s, g - 36 * s, lx - 11 * s, g - 31 * s, C(0x2A2422), Double(s))
        c.rect(lx - 14 * s, g - 31 * s, 6 * s, 3 * s, C(0x3A302C)); c.rect(lx - 13 * s, g - 28 * s, 4 * s, s, C(0x5A4A3A))
        c.rect(lx - 3 * s, g - 2 * s, 8 * s, 2 * s, C(0x221A18))
        // The road: cracked asphalt, the lane line fading.
        c.ground(g, C(0x2C2422), edge: C(0x4A3C32), speck: C(0x221A18), seed: 107)
        for xx in stride(from: 6 * s, to: c.w, by: 22 * s) where noise(xx + 3600) > 0.25 { c.rect(xx, g + 5 * s, 10 * s, s, C(0x6A5A34)) }
        for k in 0..<max(1, c.w / (40 * s)) {
            var px = Int(noise(k + 3700) * Double(c.w)), py = g + 1
            for j in 0..<6 { c.rect(px, py, s, s, C(0x1A1412)); px += (noise(k * 13 + j) > 0.5 ? 1 : -1) * s; py += s; if py >= c.h { break } }
        }
    }

    /// The screen saver's sky: a heavy deck of smoke-cloud lit orange from below by the fires, and lying across it the
    /// vast shadow of an angel's wings, spread.
    private static func huntApocalypseClouds(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntApocalypseFrame(c, g), base = f.clouds
        for row in 0..<7 {
            let y = base * (row + 1) / 8
            for k in 0..<max(2, c.w / (26 * s)) {
                let i = row * 100 + k
                let x = Int(noise(i + 3800) * Double(c.w + 40 * s)) - 20 * s
                let yy = y + Int((noise(i + 3860) - 0.5) * Double(base / 7))
                let r = (6 + Int(noise(i + 3850) * 12)) * s
                let body = lerp(C(0x2A120C), C(0x5A2616), Double(row) / 6), lit = lerp(C(0x5A2614), C(0xC0602A), Double(row) / 6)
                c.ellipse(x, yy + r / 3, r * 2, max(1, r / 2), lit)
                c.ellipse(x, yy, r * 2, max(1, r * 2 / 3), body)
                c.ellipse(x - r / 2, yy - r / 3, r, max(1, r / 2), body)
                c.ellipse(x + r * 2 / 3, yy - r / 4, r * 3 / 4, max(1, r / 3), body)
            }
        }
        // The wings' shadow in the cloud.
        let span = min(c.w * 42 / 100, 190 * s)
        huntP5WingShadow(c, c.w * 54 / 100, base * 56 / 100, span, s, C(0x120604, 0.42))
    }

    /// Apocalypse World's life: ash falling slowly over everything, and the fires flickering with sparks going up.
    static func huntApocalypseLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntApocalypseFrame(c, g)
        // The ash: grey flakes drifting down, swaying, wrapping round from the top.
        let n = max(20, c.w * g / (700 * s * s))
        for i in 0..<n {
            let speed = (3 + noise(i + 3900) * 5) * Double(s)
            let y = Int((noise(i + 3901) * Double(g) + t * speed).truncatingRemainder(dividingBy: Double(g)))
            let x = Int(noise(i + 3902) * Double(c.w)) + Int(sin(t * 0.7 + Double(i)) * Double(3 * s)) + Int(t * Double(s) * 1.5) % c.w
            let px = ((x % c.w) + c.w) % c.w
            c.rect(px, y, s, s, C(0xC8C0B8, noise(i + 3903) > 0.7 ? 0.7 : 0.45))
            if noise(i + 3904) > 0.8 { c.rect(px + s, y, s, s, C(0xC8C0B8, 0.3)) }
        }
        // The flames, licking up in tongues, and sparks rising off them.
        for (n, fr) in f.fires.enumerated() {
            let z = fr.size
            for k in 0..<(z + 2) {
                let fx = fr.x + (k - (z + 1) / 2) * 2 * s
                let h = Int((Double(z * 3) + sin(t * 9 + Double(k * 3 + n)) * 1.8 + sin(t * 5.3 + Double(k)) * 1.2) * Double(s))
                let hh = max(2 * s, h)
                c.rect(fx, fr.y - hh, 2 * s, hh, C(0xE0601E))
                c.rect(fx, fr.y - hh * 2 / 3, 2 * s, hh * 2 / 3, C(0xF09A30))
                c.rect(fx + s / 2, fr.y - hh / 3, max(1, s), hh / 3, C(0xFFE08A))
            }
            for j in 0..<3 {
                let ph = (t * 0.6 + Double(j) / 3 + Double(n) * 0.2).truncatingRemainder(dividingBy: 1)
                let sx = fr.x + Int(sin(ph * 9 + Double(j)) * Double(3 * s)), sy = fr.y - z * 4 * s - Int(ph * Double(14 * s))
                c.rect(sx, sy, max(1, s), max(1, s), C(0xFFC060, 0.8 * (1 - ph)))
            }
        }
    }
}
