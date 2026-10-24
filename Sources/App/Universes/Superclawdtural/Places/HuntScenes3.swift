import Foundation

// Places: Stull Cemetery in a storm, Clawdley's Hell and Heaven's garden. Each place is a `Place` in the dictionary
// below (its name, the tint of the window's card area under it, its still picture and what moves there) and its
// drawing in an extension of `Scenes`, with a frame function the still picture and the moving layer share so they line
// up. Check them with `build/preview place out.png <key>`, at window size and at screen-saver size.
//
// Three places that stand apart from the universe's rust and amber: Stull is a flat Kansas field under storm blues
// (not a gothic crypt: other universes have those), Hell is red stone and hellfire, Heaven is white light over a
// mid-green garden. The floor and the band just above it stay plain (mid-tone in Heaven, never white) so the crew's
// white outlines and names read; the busy detail goes higher up and at the sides; props keep their size in
// `Scenes.unit(g)` steps.

let huntScenes3: [Location: Place] = [
    .huntStull: Place(name: "Stull Cemetery", panel: 0x10141C, still: Scenes.huntStull, moving: Scenes.huntStullLife),
    .huntHell: Place(name: "Clawdley's Hell", panel: 0x1C0806, still: Scenes.huntHell, moving: Scenes.huntHellLife),
    .huntHeaven: Place(name: "Heaven", panel: 0x18241A, still: Scenes.huntHeaven, moving: Scenes.huntHeavenLife),
]

// MARK: - Stull Cemetery

extension Scenes {
    /// Where things stand at Stull, shared by the still picture and the moving layer: the far horizon, the ruined
    /// church (its left edge, width and foot), the grave being salted and burnt (its middle and the ground it lies on),
    /// the Impala (its front end and the ground under its wheels), and where the storm clouds' lowest edge hangs.
    static func huntStullFrame(_ c: PixelCanvas, _ g: Int) -> (horizon: Int, church: (x: Int, w: Int, base: Int),
                                                              grave: (x: Int, y: Int), car: (x: Int, y: Int), cloudBase: Int) {
        let s = unit(g)
        let church = (x: c.w * 7 / 100, w: 46 * s, base: g - 10 * s)
        let car = (x: c.w - 78 * s, y: g - 2 * s)
        let cloudBase = isTall(c) ? g - 70 * s : 9 * s
        return (g - 15 * s, church, (x: c.w * 61 / 100, y: g - 8 * s), car, cloudBase)
    }

    /// Stull Cemetery, Kansas, on the night of the storm: a flat field under a low sky of storm blues, the roofless
    /// limestone church on the left with its gable end still standing and the long wall crumbling away, a scatter of
    /// plain old headstones behind a wire fence, one bare tree, a grave dug open and burning in the middle distance
    /// with the shovel stuck in its mound and the salt beside it, and the black '67 Impala parked on the right. On the
    /// screen saver the storm clouds pile up overhead in heavy banks lit from beneath.
    static func huntStull(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntStullFrame(c, g), tall = isTall(c)
        // The sky: near black up top, a dusty denim blue down at the horizon.
        c.gradient(0, f.horizon, C(0x0C1018), C(0x34425A), bands: 7)
        huntStullClouds(c, g)
        // The far tree line along the horizon, a low ragged band of black.
        for x in 0..<c.w {
            let bump = Int((sin(Double(x) * 0.05 / Double(s)) * 0.5 + 0.5 + noise(x / max(1, s) + 7) * 0.6) * Double(2 * s))
            c.rect(x, f.horizon - bump - s, 1, bump + s, C(0x141A22))
        }
        // The field: wet prairie grass, darker towards us, a few tussocks.
        c.gradient(f.horizon, g, C(0x2A3230), C(0x222A26), bands: 4)
        c.rect(0, f.horizon, c.w, max(1, s / 2), C(0x3A4644))
        for i in 0..<(c.w / (5 * s)) {
            let x = Int(noise(i * 5 + 11) * Double(c.w)), y = f.horizon + 2 * s + Int(noise(i * 5 + 12) * Double(g - f.horizon - 3 * s))
            c.rect(x, y, s, s, C(0x323C38)); c.rect(x + s, y - s, max(1, s / 2), s, C(0x3A4640))
        }
        // The wire fence round the graveyard, just this side of the horizon: thin posts, two strands.
        let fy = f.horizon + 2 * s
        c.rect(0, fy - 4 * s, c.w, max(1, s / 2), C(0x4A5458)); c.rect(0, fy - 2 * s, c.w, max(1, s / 2), C(0x4A5458))
        for x in stride(from: 3 * s, to: c.w, by: 13 * s) { c.rect(x, fy - 6 * s, s, 6 * s, C(0x1E2224)) }
        huntStullChurch(c, g)
        // The bare tree beside the church, its branches clawing at the sky.
        let tx = f.church.x + f.church.w + 18 * s, ty = f.horizon + 3 * s
        let bark = C(0x1A1C1E)
        c.rect(tx - s, ty - 22 * s, 3 * s, 22 * s, bark); c.rect(tx - 2 * s, ty - 2 * s, 5 * s, 2 * s, bark)
        for (dx, dy, ex, ey) in [(0, -20, -9, -31), (1, -16, 10, -27), (0, -12, -7, -17), (1, -22, 4, -33), (-5, -27, -11, -30),
                                 (6, -23, 13, -24)] {
            c.glowLine(Double(tx + dx * s), Double(ty + dy * s), Double(tx + ex * s), Double(ty + ey * s),
                       core: bark, glow: C(0, 0), coreR: Double(s) * 0.7, glowR: Double(s) * 0.8)
        }
        // Old headstones, plain and leaning a little: small and far off near the fence, a few nearer at the sides.
        let stones: [(Int, Int, Int, Int)] = [(30, 3, 3, 4), (34, 4, 4, 5), (39, 3, 3, 4), (45, 5, 4, 6), (51, 3, 3, 4),
                                              (70, 4, 3, 5), (75, 3, 3, 4), (80, 4, 3, 4), (3, 11, 6, 9), (25, 10, 5, 8),
                                              (43, 9, 4, 6), (71, 11, 6, 8)]
        for (k, (px, dy, w, h)) in stones.enumerated() {
            let x = c.w * px / 100, y = f.horizon + dy * s
            huntStullStone(c, x, y, w * s, h * s, cross: k % 4 == 2, s: s)
        }
        // The grave in the middle distance, dug open: its headstone, the dark pit, the dirt heaped beside it with the
        // shovel standing in it, and a cylinder of salt. The fire is in the moving layer; here, its glow on the ground.
        // The grave is a long straight-sided slot, seen from a little above: the far wall of the pit lit by the fire,
        // its floor black, a lip of fresh dirt along the near side (the moving layer draws it again over the flames'
        // feet), the headstone at its head end lit on its face, the spoil heaped at the foot with the shovel in it.
        let gx = f.grave.x, gy = f.grave.y
        for r in stride(from: 18 * s, to: 2 * s, by: -3 * s) { c.ellipse(gx, gy, r * 2, r / 2, C(0xE87A2A, 0.05)) }
        c.ellipse(gx, gy + s, 13 * s, 2 * s, C(0x2E2A20))                          // the dug-over earth round it
        huntStullStone(c, gx - 15 * s, gy - s, 6 * s, 10 * s, cross: false, s: s)
        c.rect(gx - 10 * s, gy - 9 * s, s, 7 * s, C(0xD8A060, 0.5))                 // firelight on its face
        c.rect(gx - 8 * s, gy - s, 16 * s, s, C(0x7A3E1C)); c.rect(gx - 8 * s, gy, 16 * s, s, C(0x120C08))
        c.rect(gx - 9 * s, gy + s, 18 * s, s, C(0x26221C))
        c.ellipse(gx + 13 * s, gy, 5 * s, 2 * s, C(0x4A3624)); c.ellipse(gx + 12 * s, gy - s, 3 * s, s, C(0x5E4630))
        c.rect(gx + 14 * s, gy - 8 * s, max(1, s / 2) + s / 2, 7 * s, C(0x6A4A2A))   // the shovel's handle
        c.rect(gx + 13 * s, gy - 9 * s, 3 * s, s, C(0x6A4A2A)); c.rect(gx + 13 * s, gy - 2 * s, 3 * s, 2 * s, C(0x7A8088))
        c.rect(gx - 19 * s, gy - s, 2 * s, 3 * s, C(0x2E5A9A)); c.rect(gx - 19 * s, gy - s, 2 * s, max(1, s / 2), C(0xE8E8E0))
        huntStullImpala(c, f.car.x, f.car.y, s)
        // The floor: muddy grass, plain and dark so the crew reads.
        c.ground(g, C(0x2C3228), edge: C(0x404A3C), speck: C(0x252A22), seed: 71)
        if tall {
            // Puddles catching the storm light here and there on the floor's far edge.
            for k in 0..<4 {
                let x = c.w * (12 + k * 24) / 100
                c.ellipse(x, g + 3 * s, 7 * s, s, C(0x4A5A70, 0.6))
            }
        }
    }

    /// The storm clouds, as layers of low ragged cloud one behind another: a few in the window, a deep stack on the
    /// screen saver, lit faintly from beneath.
    private static func huntStullClouds(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntStullFrame(c, g), tall = isTall(c)
        // One layer: a sheet of cloud whose lower edge sags in heavy, uneven rolls, deep in places and pinched up in
        // others, black-blue above, shading lighter down towards the edge in two steps, with a thin rim lit faintly
        // from beneath. It fills up to the top, and the next, nearer layer is drawn over it, so each layer shows as a
        // band of rolls.
        func layer(_ base: Int, _ amp: Int, _ seed: Int, dark: Px, mid: Px, lit: Px) {
            let f1 = 1 / Double(9 * s + amp), f2 = 1 / Double(31 * s + amp * 3), f3 = 1 / Double(4 * s + amp / 3)
            let ph = noise(seed) * 40, ph2 = noise(seed + 1) * 40, ph3 = noise(seed + 2) * 40
            let shade = lerp(dark, mid, 0.5)
            for x in 0..<c.w {
                let u = Double(x)
                let swell = sin(u * f2 + ph2) * 0.5 + 0.5
                let roll = abs(sin(u * f1 + ph)) * (0.35 + 0.45 * swell) + swell * 0.4 + (sin(u * f3 + ph3) * 0.5 + 0.5) * 0.12
                let edge = base + Int(roll * Double(amp)) - amp / 2
                guard edge > 0 else { continue }
                let depth = max(2 * s, Int(roll * Double(amp)) / 2 + 2 * s)
                c.rect(x, 0, 1, edge, dark)
                c.rect(x, max(0, edge - depth), 1, min(edge, depth), shade)
                c.rect(x, max(0, edge - depth / 2), 1, min(edge, depth / 2), mid)
                c.rect(x, max(0, edge - s), 1, min(edge, s), lit)
            }
        }
        if !tall {
            // In the window: a low ragged ceiling of two layers, the lower and further one paler.
            for (k, (dy, amp)) in [(0, 6), (-4, 5)].enumerated() {
                let d = Double(k)
                layer(f.cloudBase + dy * s, amp * s, 200 + k * 3, dark: lerp(C(0x161C26), C(0x0C1016), d),
                      mid: lerp(C(0x222A38), C(0x141A24), d), lit: lerp(C(0x3E4A66), C(0x26304A), d))
            }
            return
        }
        // On the screen saver: grey curtains of rain trailing from the cloud base to the horizon, here and there.
        for k in 0..<4 {
            let x0 = c.w * (10 + k * 24) / 100 + Int(noise(k + 260) * Double(20 * s)), w = (18 + Int(noise(k + 261) * 20)) * s
            for y in stride(from: f.cloudBase, to: f.horizon - s, by: 1) {
                let lean = (y - f.cloudBase) / 4
                for xx in stride(from: x0 + lean, to: x0 + lean + w, by: 3 * s) {
                    if noise(xx * 3 + y * 7 + k) > 0.55 { c.px(xx, y, C(0x8A98B0, 0.12)) }
                }
            }
        }
        // The storm piled overhead: heavy banks of cloud, small and far off low down, big and near overhead, each a
        // long mass with a flattish base and a heaped, lumpy top. Each bank is drawn as one shape: its lobes all in
        // the lit tone a little low, then all in a mid tone, then all in the dark, so the light runs only along the
        // bank's underside instead of round every lobe. The far ones go first.
        let count = c.w * f.cloudBase / (1400 * s * s) + 6
        let banks = (0..<count).map { i -> (x: Int, y: Int, k: Double) in
            let k = noise(i * 3 + 400)
            return (Int(noise(i * 3 + 401) * Double(c.w + 40 * s)) - 20 * s, f.cloudBase - Int(k * Double(f.cloudBase)), k)
        }.sorted { $0.y > $1.y }
        for (i, b) in banks.enumerated() {
            let r = (7 + Int(b.k * 14) + Int(noise(i + 450) * 5)) * s
            let dark = lerp(C(0x2A3448), C(0x0E121A), b.k), mid = lerp(C(0x323E56), C(0x161C28), b.k)
            let lit = lerp(C(0x56668A), C(0x2C3850), b.k)
            let lobes = (0..<6).map { p -> (x: Int, y: Int, w: Int, h: Int) in
                let w = r * (14 + Int(noise(i * 11 + p + 460) * 12)) / 10, h = r * (4 + Int(noise(i * 11 + p + 480) * 4)) / 10 + s
                let x = b.x + Int((noise(i * 11 + p + 470) - 0.5) * Double(r * 5))
                return (x, b.y - h + Int(noise(i * 11 + p + 490) * Double(r / 4)), w, h)
            }
            for l in lobes { c.ellipse(l.x, l.y + 2 * s, l.w, l.h, lit) }
            for l in lobes { c.ellipse(l.x, l.y + s, l.w, l.h, mid) }
            for l in lobes { c.ellipse(l.x, l.y - s, l.w, l.h, dark) }
        }
    }

    /// The ruined church: limestone blocks, the gable end standing whole with its arched doorway, the long wall gone
    /// to broken steps along the top with two arched windows open to the sky, lit from the left.
    private static func huntStullChurch(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), ch = huntStullFrame(c, g).church
        let stone = C(0x6E665A), lit = C(0x8E8574), shade = C(0x4C463E), mortar = C(0x3E3A34)
        let x = ch.x, base = ch.base, end = 16 * s
        // Courses of blocks inside a box: mortar lines every three units up from the foot, joints staggered.
        func masonry(_ x0: Int, _ y0: Int, _ w: Int, _ h: Int) {
            guard w > 0, h > 0 else { return }
            var y = base - 3 * s, row = 0
            while y > y0 - 3 * s {
                if y >= y0 && y < y0 + h { c.rect(x0, y, w, max(1, s / 2), mortar.alpha(0.55)) }
                var jx = x + (row % 2) * 3 * s
                while jx < x0 + w {
                    if jx >= x0 {
                        let top = max(y0, y - 3 * s), bottom = min(y0 + h, y)
                        if bottom > top { c.rect(jx, top, max(1, s / 2), bottom - top, mortar.alpha(0.45)) }
                    }
                    jx += 6 * s
                }
                y -= 3 * s; row += 1
            }
        }
        // The gable end, facing us and lit: walls up to the eaves, then the pointed gable, a cross on its peak.
        c.rect(x, base - 26 * s, end, 26 * s, lit)
        masonry(x, base - 26 * s, end, 26 * s)
        for k in 0..<(end / 2) {
            let y = base - 26 * s - k
            c.rect(x + k, y, end - 2 * k, 1, lit)
        }
        c.rect(x + end / 2 - s / 2, base - 26 * s - end / 2 - 5 * s, max(1, s), 5 * s, shade)
        c.rect(x + end / 2 - 2 * s, base - 26 * s - end / 2 - 4 * s, 4 * s, max(1, s), shade)
        // The long wall running away to the right, its top broken into steps lower and lower.
        let wallX = x + end, wallW = ch.w - end
        for col in stride(from: 0, to: wallW, by: 3 * s) {
            let drop = Int(noise(col / max(1, s) + 5) * 4) * s + col * 12 / max(1, wallW) * s
            let top = base - 22 * s + drop, w = min(3 * s, wallW - col)
            c.rect(wallX + col, top, w, base - top, stone)
            masonry(wallX + col, top, w, base - top)
            c.rect(wallX + col, top, w, max(1, s / 2), lit)
        }
        c.rect(wallX, base - 22 * s, s, 22 * s, shade)   // the corner, in shadow
        // The arched doorway in the gable end and the two windows in the long wall: open, black, with a sill.
        let dark = C(0x0E1218)
        c.rect(x + 5 * s, base - 12 * s, 6 * s, 12 * s, dark); c.circle(x + 8 * s, base - 12 * s, 3 * s, dark)
        c.rect(x + 4 * s, base - 15 * s, s, 15 * s, shade)
        for wx in [wallX + 6 * s, wallX + 18 * s] {
            c.rect(wx, base - 15 * s, 4 * s, 7 * s, C(0x26303E)); c.circle(wx + 2 * s, base - 15 * s, 2 * s, C(0x26303E))
            c.rect(wx - s, base - 8 * s, 6 * s, s, lit)
        }
        // A small round window up in the gable.
        c.circle(x + 8 * s, base - 29 * s, s + s / 2, dark)
        // Rubble at the foot of the long wall.
        for k in 0..<6 {
            let rx = wallX + Int(noise(k + 40) * Double(wallW)), rw = (2 + Int(noise(k + 50) * 3)) * s
            c.rect(rx, base - s, rw, s + s / 2, stone); c.rect(rx, base - s, rw, max(1, s / 2), lit)
        }
        c.rect(x - s, base, ch.w + 2 * s, s, C(0x1E2420))
    }

    /// A plain old headstone, rounded on top (or a small cross), lit on its left, with its shadow on the grass.
    private static func huntStullStone(_ c: PixelCanvas, _ x: Int, _ y: Int, _ w: Int, _ h: Int, cross: Bool, s: Int) {
        let face = C(0x6A6C6E), lit = C(0x8A8C8C), dark = C(0x46484A)
        c.rect(x + s, y, w + s, max(1, s / 2), C(0x161A18))
        if cross {
            c.rect(x + w / 2 - s / 2, y - h, max(1, s), h, face); c.rect(x, y - h + h / 3, w, max(1, s), face)
            c.rect(x + w / 2 - s / 2, y - h, max(1, s / 2), h, lit)
            return
        }
        c.rect(x, y - h + w / 2, w, h - w / 2, face)
        c.ellipse(x + w / 2, y - h + w / 2, w / 2, w / 2, face)
        c.rect(x, y - h + w / 2, max(1, s / 2), h - w / 2, lit)
        c.rect(x + w - max(1, s / 2), y - h + w / 2, max(1, s / 2), h - w / 2, dark)
    }

    /// The Impala, a black 1967 Chevy four-door hardtop seen side on, nose to the left: long low body, chrome strip
    /// and bumpers, the roof set back, red tail lights, storm light glinting off the top edges.
    private static func huntStullImpala(_ c: PixelCanvas, _ x: Int, _ y: Int, _ s: Int) {
        let body = C(0x15171B), top = C(0x46526A), mid = C(0x262A32), low = C(0x0E1012)
        let chrome = C(0xA8B0BC), chromeD = C(0x6A727E), glass = C(0x2C3848), glint = C(0x7A8AA4)
        func r(_ u: Int, _ v: Int, _ w: Int, _ h: Int, _ col: Px) { c.rect(x + u * s, y + v * s, w * s, h * s, col) }
        // Its shadow on the grass.
        c.ellipse(x + 36 * s, y, 38 * s, 2 * s, C(0x0A0C0C, 0.7))
        // The greenhouse: a raked windscreen, a long flat roof, the wide sail of the rear pillar sloping to the trunk.
        for v in -19 ... -13 {
            let left = 22 + (-12 - v) * 6 / 7, right = 57 - (-12 - v) * 8 / 7
            r(left, v, right - left, 1, body)
        }
        r(28, -19, 21, 1, top)
        for v in -17 ... -13 {   // the side glass, front and back, no pillar between (a hardtop)
            let left = 24 + (-12 - v) * 6 / 7
            r(left, v, 37 - left, 1, glass); r(38, v, 9 - (v < -15 ? 1 : 0), 1, glass)
        }
        r(26, -17, 3, 1, glint); r(39, -17, 2, 1, glint); r(30, -14, 1, 2, glint.alpha(0.6))
        // The long body: hood, doors, trunk, a lit top edge, the chrome spear down the side, darker below.
        r(1, -12, 70, 8, body)
        r(0, -11, 1, 6, body); r(71, -12, 1, 7, body)
        r(1, -12, 21, 1, top); r(56, -12, 15, 1, top); r(1, -11, 70, 1, mid)
        r(2, -9, 68, 1, chrome); r(2, -8, 68, 1, chromeD.alpha(0.5))
        r(1, -6, 70, 2, low)
        r(24, -11, 1, 6, C(0x0A0B0D)); r(37, -11, 1, 6, C(0x0A0B0D)); r(49, -11, 1, 5, C(0x0A0B0D))   // door seams
        r(33, -10, 2, 1, chrome); r(45, -10, 2, 1, chrome)                                                // handles
        r(5, -5, 64, 1, chromeD)                                                                          // rocker trim
        // Bumpers, the headlight and the tail light.
        r(-1, -7, 3, 3, chrome); r(-1, -7, 3, 1, C(0xD8DEE6)); r(70, -7, 3, 3, chrome); r(70, -7, 3, 1, C(0xD8DEE6))
        r(0, -11, 1, 3, C(0xE8E2C0)); r(71, -11, 1, 3, C(0xB82020))
        // The wheels in their arches: black tyres, dark rims, chrome caps.
        for wx in [14, 58] {
            c.circle(x + wx * s, y - 5 * s, 6 * s, low)
            c.circle(x + wx * s, y - 4 * s, 4 * s, C(0x0A0A0C))
            c.circle(x + wx * s, y - 4 * s, 2 * s + s / 2, C(0x3A3E46))
            c.circle(x + wx * s, y - 4 * s, s, chrome); c.rect(x + wx * s - s, y - 6 * s, max(1, s), max(1, s), C(0xE0E4EA))
        }
    }

    /// Stull's life: every so often lightning splits the sky off to one side, the sky flashing pale for a moment, and
    /// the grave burns: flames licking up out of the pit and a thin smoke drifting off.
    static func huntStullLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntStullFrame(c, g)
        // The lightning: two quick pulses every eight seconds, a bolt from the clouds to the horizon at one side.
        let cycle = Int(t / 8), phase = t.truncatingRemainder(dividingBy: 8)
        let flash = phase < 0.12 || (phase > 0.22 && phase < 0.32)
        if flash {
            c.rect(0, 0, c.w, f.horizon, C(0xC8D6F0, 0.10))
            let side = noise(cycle * 13 + 1) > 0.5
            var bx = Double(side ? c.w * (72 + Int(noise(cycle * 13 + 2) * 20)) / 100 : c.w * (6 + Int(noise(cycle * 13 + 2) * 18)) / 100)
            var by = Double(max(0, f.cloudBase - 2 * s))
            let step = Double(4 * s)
            var k = 0
            while by < Double(f.horizon - 2 * s) {
                let nx = bx + (noise(cycle * 41 + k) - 0.5) * Double(6 * s), ny = min(Double(f.horizon - 2 * s), by + step)
                c.glowLine(bx, by, nx, ny, core: C(0xF4F8FF), glow: C(0x9AB4E8, 0.6), coreR: Double(s) * 0.6, glowR: Double(s) * 1.6)
                if k == 3 {   // a fork splitting off partway down
                    let side = noise(cycle * 41 + 90) > 0.5 ? 1.0 : -1.0
                    c.glowLine(nx, ny, nx + side * Double(6 * s), ny + Double(7 * s), core: C(0xE4ECFF), glow: C(0x9AB4E8, 0.4),
                               coreR: Double(s) * 0.5, glowR: Double(s) * 1.2)
                }
                bx = nx; by = ny; k += 1
            }
        }
        // The burning grave: a long sheet of fire the length of the slot, tongues of uneven heights licking up out of
        // the ground, their feet hidden behind the dark near lip, sparks lifting off it and a thick smoke, lit orange
        // by the fire low down, rolling up and away to the right.
        let gx = f.grave.x, gy = f.grave.y
        for k in 0..<16 {
            let fx = gx - 8 * s + k * s
            let flick = sin(t * (6.0 + Double(k % 5) * 1.7) + Double(k) * 2.3) * 0.5 + 0.5
            let base = 2.0 + noise(k + 3100) * 4.0 - (k == 0 || k == 15 ? 1.5 : 0)
            let h = max(2 * s, Int((base + flick * 3.0) * Double(s)))
            c.rect(fx, gy - h, s, h + s, C(0xC8361A))
            c.rect(fx, gy - h * 2 / 3, s, h * 2 / 3 + s, C(0xF07A22))
            if k > 1 && k < 14 { c.rect(fx, gy - h / 3, s, h / 3 + s, C(0xFFD46A)) }
        }
        c.rect(gx - 9 * s, gy + s, 18 * s, s, C(0x26221C))
        for k in 0..<5 {   // sparks
            let u = (t * 0.6 + noise(k + 3120)).truncatingRemainder(dividingBy: 1)
            let sx = gx - 7 * s + Int(noise(k + 3130) * Double(14 * s)) + Int(u * Double(5 * s)), sy = gy - 5 * s - Int(u * Double(14 * s))
            c.rect(sx, sy, max(1, s), max(1, s), C(0xFFB040, 0.9 * (1 - u)))
        }
        for k in 0..<8 {   // the smoke, see-through, rolling up and away to the right
            let u = (t * 0.28 + Double(k) / 8).truncatingRemainder(dividingBy: 1)
            let sx = gx - 6 * s + Int(u * Double(20 * s) + sin(t + Double(k)) * Double(s)) + (k % 3) * 4 * s
            let sy = gy - 7 * s - Int(u * Double(28 * s))
            c.ellipse(sx, sy, (3 + Int(u * 5)) * s, (1 + Int(u * 3)) * s, lerp(C(0x9A6448), C(0x5A606A), min(1, u * 2.5)).alpha(0.32 * (1 - u)))
        }
    }
}

// MARK: - Clawdley's Hell

extension Scenes {
    /// Where things stand in Clawdley's throne room: the ledge the queue stands on (its row and where the queue's
    /// archway is), the throne's middle and the top of its dais, the braziers' x positions and the row their fire
    /// burns on, and on the screen saver where the vault springs from the walls.
    static func huntHellFrame(_ c: PixelCanvas, _ g: Int) -> (ledge: Int, arch: Int, throne: (x: Int, dais: Int),
                                                             braziers: [Int], fireY: Int, vault: Int) {
        let s = unit(g)
        let throneX = c.w * 82 / 100
        let vault = isTall(c) ? g * 34 / 100 : -40 * s
        return (g - 38 * s, c.w * 62 / 100, (x: throneX, dais: g - 5 * s), [c.w * 6 / 100, throneX - 20 * s, throneX + 20 * s],
                g - 19 * s, vault)
    }

    /// Clawdley's Hell, run his way: a throne room of dark red stone in blocks, pillars down the wall, and along a
    /// ledge at the back the endless queue of souls, kept in line by brass posts and red velvet rope, shuffling off
    /// into a dark archway. On the right his throne on its dais, black and gold with red velvet, a brazier burning on
    /// either side. On the screen saver the walls rise to a ribbed vault, iron chains hang from it, and the queue
    /// zigzags on up the far wall into the dark, as queues in Hell do.
    static func huntHell(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHellFrame(c, g), tall = isTall(c)
        let red = C(0x4A1410), redD = C(0x2C0A08), redL = C(0x6A2018), gold = C(0xC8A04A), goldD = C(0x8A6A2A)
        // The wall: dark red stone, blackest up high, in big rough-cut blocks of uneven lengths, course on course,
        // some a shade darker or warmer than the next, lit along the top here and there, a crack running through
        // the odd one. Below the queue's ledge the joints are fainter, so the wall behind the crew stays calm.
        c.gradient(0, g, C(0x160404), red, bands: 7)
        for (row, y) in stride(from: g - 6 * s, to: -6 * s, by: -6 * s).enumerated() {
            let calm = y > f.ledge, joint = calm ? redD.alpha(0.55) : redD
            c.rect(0, y, c.w, max(1, s / 2), joint)
            var x = -Int(noise(row + 2000) * 12) * s, i = row * 31
            while x < c.w {
                let len = (9 + Int(noise(i + 2010) * 10)) * s
                let shade = noise(i + 2020)
                if shade > 0.72 { c.rect(x, y - 6 * s, len, 6 * s, C(0x0C0202, calm ? 0.12 : 0.2)) }
                else if shade < 0.18 { c.rect(x, y - 6 * s, len, 6 * s, C(0x8A2A1E, calm ? 0.06 : 0.1)) }
                if !calm && noise(i + 2030) > 0.7 { c.rect(x + s, y - 6 * s + max(1, s / 2), len - 2 * s, max(1, s / 2), redL.alpha(0.5)) }
                if !calm && noise(i + 2040) > 0.9 {   // a crack, stepping down across the block
                    for k in 0..<4 { c.rect(x + (3 + k) * s, y - (5 - k) * s, max(1, s / 2), s, redD) }
                }
                c.rect(x, y - 6 * s, max(1, s / 2), 6 * s, joint)
                x += len; i += 1
            }
        }
        // Pillars down the wall, lit on their left, with gold-banded capitals.
        let pillarTop = tall ? f.vault : 0
        for x in stride(from: 22 * s, to: c.w, by: 64 * s) {
            c.rect(x, pillarTop, 7 * s, g - pillarTop, redD); c.rect(x, pillarTop, s, g - pillarTop, redL)
            c.rect(x + 6 * s, pillarTop, s, g - pillarTop, C(0x1A0505))
            if tall { c.rect(x - s, f.vault, 9 * s, 2 * s, goldD); c.rect(x - s, f.vault, 9 * s, max(1, s / 2), gold) }
        }
        if tall { huntHellVault(c, g) }
        // The archway the queue shuffles off into, black inside with a red glow far down it.
        let ax = f.arch
        c.rect(ax - 2 * s, f.ledge - 22 * s, 16 * s, 22 * s, redL)
        c.rect(ax, f.ledge - 18 * s, 12 * s, 18 * s, C(0x0A0202)); c.circle(ax + 6 * s, f.ledge - 18 * s, 6 * s, C(0x0A0202))
        c.ellipse(ax + 6 * s, f.ledge - 6 * s, 3 * s, 4 * s, C(0xC03018, 0.25))
        // The ledge the queue stands on: a stone shelf with a lit lip, and the shadow under it.
        c.rect(0, f.ledge, ax + 12 * s, 3 * s, redD); c.rect(0, f.ledge, ax + 12 * s, max(1, s / 2), redL)
        c.rect(0, f.ledge + 3 * s, ax + 12 * s, s, C(0x140303))
        for k in 0..<3 { c.rect(0, f.ledge + (4 + 2 * k) * s, ax + 12 * s, 2 * s, C(0x0C0202, 0.3 - Double(k) * 0.1)) }
        huntHellRope(c, g)
        // The wall's foot: a plain dark plinth, so the crew reads in front of it.
        c.rect(0, g - 9 * s, c.w, 9 * s, C(0x340E0B)); c.rect(0, g - 9 * s, c.w, max(1, s / 2), C(0x541A14))
        // The throne on its dais.
        let tx = f.throne.x, dy = f.throne.dais
        for k in 0..<3 {   // the dais, three steps of black stone with gold nosings
            let w = (34 - k * 6) * s, y = g - (k + 1) * 2 * s + s
            c.rect(tx - w / 2, y, w, 2 * s, C(0x1A1012)); c.rect(tx - w / 2, y, w, max(1, s / 2), gold)
        }
        let blk = C(0x161012), blkL = C(0x3A2C30), vel = C(0x8A1A1E), velL = C(0xB02A2C), velD = C(0x5E1014)
        c.rect(tx - 8 * s, dy - 34 * s, 16 * s, 29 * s, blk)                         // the high back
        c.rect(tx - 7 * s, dy - 36 * s, 14 * s, 2 * s, blk)
        c.rect(tx - 2 * s, dy - 39 * s, 4 * s, 3 * s, blk); c.rect(tx - s, dy - 41 * s, 2 * s, 2 * s, gold)   // its crest
        for ex in [tx - 9 * s, tx + 7 * s] { c.rect(ex, dy - 37 * s, 2 * s, 4 * s, blk); c.rect(ex, dy - 38 * s, 2 * s, s, gold) }
        c.rect(tx - 6 * s, dy - 31 * s, 12 * s, 19 * s, vel); c.rect(tx - 6 * s, dy - 31 * s, 2 * s, 19 * s, velL)
        c.rect(tx + 4 * s, dy - 31 * s, 2 * s, 19 * s, velD)
        for y in stride(from: dy - 28 * s, to: dy - 13 * s, by: 5 * s) { c.rect(tx - s, y, 2 * s, s, velD) }   // buttons
        c.rect(tx - 8 * s, dy - 34 * s, 16 * s, max(1, s / 2), gold); c.rect(tx - 8 * s, dy - 34 * s, max(1, s / 2), 29 * s, gold)
        c.rect(tx - 10 * s, dy - 12 * s, 20 * s, 4 * s, vel); c.rect(tx - 10 * s, dy - 12 * s, 20 * s, s, velL)   // the seat
        c.rect(tx - 11 * s, dy - 15 * s, 3 * s, 10 * s, blk); c.rect(tx + 8 * s, dy - 15 * s, 3 * s, 10 * s, blk)   // the arms
        c.rect(tx - 11 * s, dy - 15 * s, 3 * s, s, blkL); c.rect(tx + 8 * s, dy - 15 * s, 3 * s, s, gold)
        c.rect(tx - 10 * s, dy - 8 * s, 20 * s, 3 * s, blk); c.rect(tx - 10 * s, dy - 8 * s, 20 * s, max(1, s / 2), blkL)
        // The braziers: brass bowls on three legs, red coals in them; the flames are in the moving layer.
        for bx in f.braziers {
            let by = f.fireY
            c.ellipse(bx, by + s, 8 * s, 3 * s, C(0xE05020, 0.08))
            c.rect(bx - 4 * s, by, 8 * s, 2 * s, goldD); c.rect(bx - 5 * s, by - s, 10 * s, s, gold)
            c.rect(bx - 4 * s, by - s, 8 * s, max(1, s / 2) + s / 2, C(0xD03A18))
            c.rect(bx - s / 2, by + 2 * s, max(1, s), g - by - 2 * s, goldD)
            for k in [-1, 1] {
                c.glowLine(Double(bx), Double(by + 2 * s), Double(bx + k * 4 * s), Double(g),
                           core: goldD, glow: C(0, 0), coreR: Double(s) * 0.6, glowR: Double(s) * 0.7)
            }
        }
        // The floor: dark red flagstones, plain.
        c.ground(g, C(0x341A16), edge: C(0x5A2C22), speck: C(0x2A1210), seed: 83)
        for x in stride(from: 0, to: c.w, by: 20 * s) { c.rect(x, g + 1, max(1, s / 2), c.h - g - 1, C(0x2A1210)) }
    }

    /// The velvet rope along the front of the queue's ledge: brass posts, red rope sagging between them.
    private static func huntHellRope(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHellFrame(c, g)
        let posts = Array(stride(from: 4 * s, through: f.arch, by: 14 * s))
        for (k, x) in posts.enumerated() {
            if k + 1 < posts.count {
                let nx = posts[k + 1]
                for u in stride(from: 0, to: nx - x, by: 1) {
                    let d = Double(u) / Double(nx - x), sag = Int(sin(d * .pi) * Double(2 * s))
                    c.rect(x + u, f.ledge - 6 * s + sag, 1, max(1, s), C(0x9A1A20))
                }
            }
            c.rect(x - s / 2, f.ledge - 7 * s, max(1, s), 7 * s, C(0xC8A04A))
            c.rect(x - s, f.ledge - 8 * s, 2 * s, s, C(0xE8C870))
            c.rect(x - s, f.ledge - s, 2 * s, s, C(0x8A6A2A))
        }
    }

    /// The screen saver's vault: pointed ribs springing from the pillars, the ceiling black between them, iron chains
    /// hanging down, and the far wall's queue zigzagging up into the dark.
    private static func huntHellVault(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHellFrame(c, g)
        // The zigzag of more souls on ramps up the wall, faint and far off and fainter the higher they go: each ramp
        // its own length and pitch, a stone landing at each turn, the souls of uneven heights with gaps in the line
        // here and there, a short flight of steps up from each landing to the next ramp.
        let rx = c.w * 8 / 100
        var x0 = rx, y0 = f.ledge - 34 * s, k = 0
        while y0 - 16 * s > f.vault + 8 * s && k < 5 {
            let len = c.w * (38 + Int(noise(k + 2100) * 18)) / 100, rise = (5 + Int(noise(k + 2110) * 6)) * s
            let dir = k % 2 == 0 ? 1 : -1, x1 = min(c.w * 68 / 100, max(c.w * 5 / 100, x0 + dir * len)), y1 = y0 - rise
            let fade = max(0.15, 0.42 - Double(k) * 0.06), soul = C(0xB0A0A8, fade)
            c.glowLine(Double(x0), Double(y0), Double(x1), Double(y1), core: C(0x6A2018), glow: C(0x2A0806), coreR: Double(s) * 0.8, glowR: Double(s) * 2.2)
            let n = abs(x1 - x0) / (5 * s)
            for i in 0..<n where noise(k * 41 + i + 2120) > 0.14 {
                let u = (Double(i) + 0.5) / Double(n), hh = 4 + Int(noise(k * 41 + i + 2160) * 3)
                let px = x0 + Int(Double(x1 - x0) * u), py = y0 + Int(Double(y1 - y0) * u)
                c.rect(px - s, py - hh * s, 3 * s, hh * s, soul); c.circle(px + (noise(k * 41 + i + 2200) > 0.5 ? s / 2 : 0), py - (hh + 1) * s, s, soul)
            }
            // The landing at the turn, a short flat ledge lit on top, and the steps up from it to the next ramp.
            let climb = (12 + Int(noise(k + 2120) * 6)) * s
            c.rect(x1 - (dir > 0 ? 2 : 8) * s, y1, 10 * s, 2 * s, C(0x3A0E0A)); c.rect(x1 - (dir > 0 ? 2 : 8) * s, y1, 10 * s, max(1, s / 2), C(0x6A2018))
            for j in 1...4 {
                let sx = x1 + dir * (5 - j) * 2 * s - (dir > 0 ? 0 : 2 * s)
                c.rect(sx, y1 - j * climb / 4, 3 * s, max(1, s), C(0x6A2018)); c.rect(sx, y1 - j * climb / 4 + max(1, s), 3 * s, climb / 4 - max(1, s), C(0x3A0E0A))
            }
            x0 = x1; y0 = y1 - climb; k += 1
        }
        // The vault: black up top, ribs in pointed arches from pillar to pillar.
        c.gradient(0, f.vault, C(0x080101), C(0x1E0605), bands: 5)
        let rib = C(0x5A1A14), ribL = C(0x7A2A1E)
        for x in stride(from: 22 * s, to: c.w + 64 * s, by: 64 * s) {
            let a = x + 3 * s, b = a + 64 * s, mid = (a + b) / 2, rise = 40 * s
            for (x0, x1) in [(a, mid), (b, mid)] {
                var px = Double(x0), py = Double(f.vault)
                for k in 1...12 {
                    let u = Double(k) / 12
                    let nx = Double(x0) + Double(x1 - x0) * u
                    let ny = Double(f.vault) - Double(rise) * sin(u * .pi / 2)
                    c.glowLine(px, py, nx, ny, core: rib, glow: ribL.alpha(0.6), coreR: Double(s) * 1.2, glowR: Double(s) * 2)
                    px = nx; py = ny
                }
            }
            c.circle(mid, f.vault - rise, 2 * s, C(0xC8A04A))   // the gold boss where the ribs meet
        }
        // Heavy chains swagged from boss to boss across the vault.
        for x in stride(from: 22 * s, to: c.w, by: 64 * s) {
            let a = x + 3 * s + 32 * s, b = a + 64 * s, y0 = f.vault - 40 * s
            for u in stride(from: 0, to: b - a, by: 2 * s) {
                let d = Double(u) / Double(b - a), y = y0 + Int(sin(d * .pi) * Double(16 * s))
                c.rect(a + u, y, 2 * s, max(1, s), (u / max(1, 2 * s)) % 2 == 0 ? C(0x5A5A62) : C(0x2E2E34))
            }
        }
        // Chains hanging down from the dark above, iron links lit on one side, a ring at the end.
        for (k, cx) in [c.w * 14 / 100, c.w * 38 / 100, c.w * 58 / 100, c.w * 90 / 100, c.w * 26 / 100, c.w * 74 / 100].enumerated() {
            let top = 0, len = f.vault - (k < 4 ? 14 : 34) * s + Int(noise(k + 300) * Double(12 * s))
            var y = top
            var flip = false
            while y < top + len {
                if flip { c.rect(cx - s / 2, y, max(1, s), 3 * s, C(0x5A5A62)) }
                else { c.rect(cx - s, y, 2 * s, 3 * s, C(0x2E2E34)); c.rect(cx - s, y, max(1, s / 2), 3 * s, C(0x6A6A72)) }
                y += 2 * s; flip.toggle()
            }
            c.circle(cx, y + 2 * s, 2 * s, C(0x3A3A42)); c.circle(cx, y + 2 * s, s, C(0x0E0303))
        }
    }

    /// Hell's life: the queue shuffles one place forward every few seconds, the soul at the front fading into the
    /// archway and a new one fading in at the back, and the braziers' flames dance with embers drifting up off them.
    static func huntHellLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntHellFrame(c, g)
        let gap = 10 * s, span = f.arch + 6 * s
        let period = 3.2, step = Int(floor(t / period)), frac = t / period - floor(t / period)
        // Soul number `id` keeps its own look all the way up the line. The front of the queue shuffles forward first
        // and the step ripples back down the line, the way a real queue moves, each soul taking a fifth of the
        // round to make its step, with a little lift as it goes; in between they sway where they stand.
        for id in (-step - 2)...(span / gap - step + 2) {
            let rest = (id + step) * gap - gap
            let delay = 0.45 * min(1, max(0, Double(span - rest) / Double(span)))
            let k = min(1, max(0, (frac - delay) / 0.2))
            let ease = (1 - cos(k * .pi)) / 2
            let sway = k <= 0 || k >= 1 ? Int((sin(t * (0.9 + noise(id * 7 + 1004) * 0.6) + Double(id)) * 0.8).rounded()) * s : 0
            let x = rest + Int(ease * Double(gap)) + sway
            guard x > -3 * s, x < span + 3 * s else { continue }
            let fadeIn = min(1, Double(x + 3 * s) / Double(8 * s)), fadeOut = min(1, Double(span - x) / Double(8 * s))
            let a = max(0, min(fadeIn, fadeOut))
            let tints: [UInt32] = [0xA89AA2, 0x9AA6B4, 0xB0A496]
            let h = (11 + Int(noise(id * 7 + 1000) * 5)) * s, wide = noise(id * 7 + 1002) > 0.7 ? s : 0
            let body = C(tints[Int(noise(id * 7 + 1001) * 3) % 3], 0.6 * a), rim = C(0xE4DCE4, 0.45 * a)
            let y = f.ledge - (k > 0.2 && k < 0.8 ? s : 0)
            let pose = noise(id * 7 + 1003)                              // how this one waits
            let stoop = pose < 0.45 ? s : 0, lookBack = pose > 0.88
            // A soul in the queue, see-through and pale: the head bowed or turned back down the line, the shoulders
            // slumped, the arms hanging, folded or one hand up to its face, two legs, waiting.
            let top = y - h, hx = lookBack ? x - 2 * s : x + stoop
            c.rect(hx, top, 3 * s, 3 * s, body); c.rect(x + s, top + 3 * s, s, s, body)
            c.rect(x - 3 * s - wide, top + 4 * s, 7 * s + 2 * wide, 2 * s, body)
            c.rect(x - 2 * s - wide, top + 6 * s, 5 * s + 2 * wide, h - 9 * s, body)
            if pose > 0.6 && pose <= 0.75 {
                c.rect(x - 2 * s, top + 7 * s, 5 * s, s, rim)                                     // arms folded
            } else if pose > 0.75 && pose <= 0.88 {
                c.rect(x - 3 * s - wide, top + 6 * s, s, 4 * s, body); c.rect(x + 3 * s + wide, top + 2 * s, s, 4 * s, body)   // a hand to its face
            } else {
                c.rect(x - 3 * s - wide, top + 6 * s, s, 4 * s, body); c.rect(x + 3 * s + wide, top + 6 * s, s, 4 * s, body)
            }
            c.rect(x - 2 * s, y - 3 * s, 2 * s, 3 * s, body); c.rect(x + s, y - 3 * s, 2 * s, 3 * s, body)
            c.rect(x - 3 * s - wide, top + 4 * s, max(1, s / 2), 6 * s, rim); c.rect(hx, top, max(1, s / 2), 3 * s, rim)
        }
        huntHellRope(c, g)
        // The braziers' flames and the embers drifting up off them.
        for (b, bx) in f.braziers.enumerated() {
            for k in 0..<4 {
                let fx = bx - 4 * s + k * 2 * s
                let flick = sin(t * (6.0 + Double(k + b) * 1.1) + Double(k * 3 + b)) * 0.5 + 0.5
                let h = max(s, Int((2.0 + Double(1 + (k == 1 || k == 2 ? 2 : 0)) + flick * 3) * Double(s)))
                c.rect(fx, f.fireY - s - h, 2 * s, h, C(0xC8301A))
                c.rect(fx, f.fireY - s - h * 2 / 3, 2 * s, h * 2 / 3, C(0xF07A22))
                c.rect(fx + s / 2, f.fireY - s - h / 3, max(1, s), h / 3, C(0xFFD46A))
            }
            for e in 0..<5 {
                let u = (t * 0.22 + noise(b * 31 + e) ).truncatingRemainder(dividingBy: 1)
                let ex = bx + Int(sin(t * 0.9 + Double(e * 2 + b)) * Double(3 * s) + (noise(b * 31 + e + 9) - 0.5) * Double(10 * s))
                let ey = f.fireY - 6 * s - Int(u * Double(40 * s))
                c.rect(ex, ey, max(1, s), max(1, s), C(e % 2 == 0 ? 0xFFB040 : 0xFF6A2A, 0.85 * (1 - u)))
            }
        }
    }
}

// MARK: - Heaven

extension Scenes {
    /// Where things stand in Heaven's garden: the far hedge's top, the near hedge's top, the great tree's trunk (its
    /// middle and the row its canopy hangs down to), the fountain's middle and the ground under it, and on the screen
    /// saver the doorway of light's middle and foot.
    static func huntHeavenFrame(_ c: PixelCanvas, _ g: Int) -> (far: Int, near: Int, tree: (x: Int, canopy: Int),
                                                               fountain: (x: Int, y: Int), door: (x: Int, y: Int)) {
        let s = unit(g)
        let door = (x: c.w * 56 / 100, y: isTall(c) ? g - 74 * s : -100 * s)
        return (g - 34 * s, g - 16 * s, (x: c.w * 20 / 100, canopy: g - 32 * s), (x: c.w * 78 / 100, y: g - 2 * s), door)
    }

    /// The rose arbour's middle and the garden bench's middle, shared by the still picture and the butterflies.
    static func huntHeavenGarden(_ c: PixelCanvas, _ g: Int) -> (arbour: Int, bench: Int) {
        (c.w * 43 / 100, c.w * 62 / 100)
    }

    /// Heaven, as Joshua's garden: white light pouring from a far-off doorway, a far bank of soft trees, a clipped hedge
    /// with flowers in it, the one great tree on the left spreading its canopy over everything, and a stone fountain
    /// on the right. The grass and the hedge stay mid-green, never white, so the crew stands out. On the screen saver
    /// the sky blazes white, rays fan out from a doorway of light standing on a green rise beyond the garden, steps of
    /// white stone climbing to it.
    static func huntHeaven(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHeavenFrame(c, g), tall = isTall(c)
        // The sky: blinding cream-white, warming to pale gold low down. In the window it's a warmer gold, so the white
        // light pouring from the doorway (below) stands out against it.
        if tall { c.gradient(0, f.far, C(0xFFFCF0), C(0xEADFAE), bands: 6); huntHeavenDoor(c, g) }
        else {
            c.gradient(0, f.far, C(0xEEDCA4), C(0xE2CC8C), bands: 5)
            // The light from the doorway, far off between the trees: a blaze of white round it and broad rays
            // fanning up and out across the sky.
            let dx = f.door.x, dy = f.far
            for r in stride(from: 60 * s, to: 4 * s, by: -6 * s) { c.ellipse(dx, dy, r * 2, r, C(0xFFFFF4, 0.10)) }
            for k in 0..<7 {
                let a = Double.pi + Double(k + 1) / 8 * Double.pi, len = Double(c.w)
                c.glowLine(Double(dx), Double(dy), Double(dx) + cos(a) * len, Double(dy) + sin(a) * len,
                           core: C(0xFFFFF4, 0.2), glow: C(0xFFFFF4, 0.08), coreR: Double(2 * s), glowR: Double(6 * s))
            }
        }
        // Rays of light slanting down from the upper left, see-through.
        for k in 0..<5 {
            let x0 = c.w * (8 + k * 21) / 100, w = (6 + k % 3 * 3) * s
            for y in stride(from: 0, to: f.near, by: 1) { c.rect(x0 + (y * 2) / 5, y, w, 1, C(0xFFFFF4, 0.10)) }
        }
        // The far bank of trees: soft rounded crowns, lit on their left.
        for x in stride(from: -6 * s, to: c.w + 10 * s, by: 11 * s) {
            let r = (7 + Int(noise(x / max(1, s) + 600) * 5)) * s, y = f.far + Int(noise(x / max(1, s) + 601) * Double(4 * s))
            c.ellipse(x, y, r, r * 3 / 4, C(0x6A9A54))
            c.ellipse(x - r / 3, y - r / 4, r / 2, r / 3, C(0x86B468))
        }
        c.rect(0, f.far + 3 * s, c.w, f.near - f.far - 3 * s, C(0x5A8A48))
        // In the window, the doorway of light far off between the trees, a small bright arch with a halo round it: the
        // screen saver shows it close up.
        if !tall {
            let dx = f.door.x, dy = f.far + 2 * s
            for r in stride(from: 16 * s, to: 2 * s, by: -2 * s) { c.circle(dx, dy - 3 * s, r, C(0xFFFFFF, 0.12)) }
            c.rect(dx - 3 * s, dy - 7 * s, 6 * s, 7 * s, C(0xD8D2BE)); c.circle(dx, dy - 7 * s, 3 * s, C(0xD8D2BE))
            c.rect(dx - 2 * s, dy - 7 * s, 4 * s, 7 * s, C(0xFFFFFF)); c.circle(dx, dy - 7 * s, 2 * s, C(0xFFFFFF))
            c.rect(dx - 4 * s, dy, 8 * s, s, C(0xE4DECA))
            // Its light falling on the garden: the hedge's top washed paler either side of it.
            c.ellipse(dx, f.near, 60 * s, 4 * s, C(0xFFFFF0, 0.18))
        }
        // The near hedge, clipped flat, a little darker, flowers dotted along its top.
        c.rect(0, f.near, c.w, g - f.near, C(0x3E6A34))
        c.rect(0, f.near, c.w, s, C(0x5A8A48)); c.rect(0, f.near + s, c.w, max(1, s / 2), C(0x4E7C42))
        for i in 0..<(c.w / (4 * s)) {
            let x = Int(noise(i * 3 + 700) * Double(c.w)), y = f.near + Int(noise(i * 3 + 701) * Double(4 * s))
            let tone = [C(0xF4E8F0), C(0xF2C8D8), C(0xF8E070)][i % 3]
            c.rect(x, y, max(1, s), max(1, s), tone)
        }
        for x in stride(from: 0, to: c.w, by: 8 * s) { c.rect(x, f.near + 3 * s, max(1, s / 2), g - f.near - 4 * s, C(0x365E2E)) }
        // Rose bushes along the hedge's foot, big blooms in pink, white and gold, lit on top.
        for i in 0..<(c.w / (9 * s)) {
            let x = i * 9 * s + Int(noise(i * 5 + 720) * Double(4 * s)), y = g - 6 * s
            c.ellipse(x, y, 4 * s, 3 * s, C(0x2E5A2A)); c.ellipse(x - s, y - s, 3 * s, 2 * s, C(0x427A36))
            for k in 0..<3 {
                let bx = x - 3 * s + Int(noise(i * 5 + k + 730) * Double(6 * s)), by = y - 2 * s + Int(noise(i * 5 + k + 740) * Double(3 * s))
                let tone = [C(0xF08AB0), C(0xF8F4EC), C(0xF4D050), C(0xE05A78)][(i + k) % 4]
                c.rect(bx, by, 2 * s, 2 * s, tone); c.rect(bx, by, s, s, C(0xFFFFFF, 0.5))
            }
        }
        huntHeavenArbour(c, g)
        huntHeavenBench(c, g)
        huntHeavenFountain(c, g)
        huntHeavenTree(c, g)
        // The grass: mid-green, plain, a few daisies.
        c.ground(g, C(0x4E7A3A), edge: C(0x6A9A4A), speck: C(0x446E32), seed: 97)
        for i in 0..<(c.w / (14 * s)) {
            let x = Int(noise(i * 3 + 800) * Double(c.w)), y = g + 2 * s + Int(noise(i * 3 + 801) * Double(max(1, c.h - g - 3 * s)))
            c.rect(x, y, max(1, s), max(1, s), C(0xE8E4D0))
        }
    }

    /// The great tree: a broad trunk with roots splayed on the grass, limbs spreading, and a huge canopy of greens
    /// lit from the upper left.
    private static func huntHeavenTree(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHeavenFrame(c, g)
        let tx = f.tree.x, bark = C(0x5A4430), barkL = C(0x7A5E42), barkD = C(0x3E2E20)
        // Its shadow on the hedge foot and grass.
        c.ellipse(tx + 4 * s, g, 22 * s, 2 * s, C(0x2E4A26, 0.55))
        // The trunk, flaring into roots at the foot.
        c.rect(tx - 4 * s, f.tree.canopy, 9 * s, g - f.tree.canopy, bark)
        c.rect(tx - 4 * s, f.tree.canopy, 2 * s, g - f.tree.canopy, barkL)
        c.rect(tx + 4 * s, f.tree.canopy, s, g - f.tree.canopy, barkD)
        for y in stride(from: f.tree.canopy + 4 * s, to: g - 3 * s, by: 5 * s) { c.rect(tx - s, y, max(1, s / 2), 3 * s, barkD) }
        for (dx, w) in [(-8, 5), (5, 5), (-6, 3), (8, 3)] { c.rect(tx + dx * s, g - 2 * s, w * s, 2 * s, bark) }
        c.rect(tx - 7 * s, g - 3 * s, 15 * s, s, bark)
        // Limbs up into the canopy.
        for (ex, ey) in [(-22, -20), (20, -18), (-8, -28), (10, -30)] {
            c.glowLine(Double(tx), Double(f.tree.canopy + 4 * s), Double(tx + ex * s), Double(f.tree.canopy + ey * s),
                       core: bark, glow: C(0, 0), coreR: Double(s) * 1.4, glowR: Double(s) * 1.5)
        }
        // The canopy: clusters of leaves, dark beneath, mid in the body, light on the upper left of each clump.
        let clumps: [(Int, Int, Int)] = [(-30, -6, 12), (-14, -2, 13), (4, -4, 13), (22, -8, 12), (36, -4, 9), (-40, 0, 8),
                                         (-24, -18, 13), (-4, -20, 15), (16, -22, 13), (32, -18, 10), (-12, -34, 13),
                                         (8, -36, 12), (-30, -30, 9), (24, -32, 8)]
        for (u, v, r) in clumps { c.ellipse(tx + u * s, f.tree.canopy + v * s + 2 * s, r * s + s, r * s * 2 / 3 + s, C(0x2E5A2A)) }
        for (u, v, r) in clumps { c.ellipse(tx + u * s, f.tree.canopy + v * s, r * s, r * s * 2 / 3, C(0x3E7236)) }
        for (u, v, r) in clumps { c.ellipse(tx + u * s - r * s / 4, f.tree.canopy + v * s - r * s / 5, r * s / 2, r * s / 3, C(0x5A9246)) }
        for (u, v, r) in clumps { c.ellipse(tx + u * s - r * s / 3, f.tree.canopy + v * s - r * s / 3, r * s / 4, r * s / 6, C(0x86B860)) }
        // Here and there a leaf caught gold in the light.
        for i in 0..<30 {
            let x = tx + Int((noise(i * 2 + 900) - 0.5) * Double(80 * s)), y = f.tree.canopy - Int(noise(i * 2 + 901) * Double(40 * s))
            c.rect(x, y, max(1, s), max(1, s), C(0xD8E07A))
        }
    }

    /// A white rose arbour over the garden's path: two lattice posts, an arched top of white slats, and roses
    /// climbing both posts and blooming over the arch.
    private static func huntHeavenArbour(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x = huntHeavenGarden(c, g).arbour
        let white = C(0xF2EEE2), whiteD = C(0xC8C2B0), leaf = C(0x3E7236), leafL = C(0x5A9246)
        let half = 13 * s, top = g - 30 * s
        c.ellipse(x + 2 * s, g, 18 * s, 2 * s, C(0x2E4A26, 0.5))
        for px in [x - half, x + half - 3 * s] {   // the posts, a lattice of slats
            c.rect(px, top + 6 * s, 3 * s, g - top - 6 * s, white); c.rect(px + 2 * s, top + 6 * s, s, g - top - 6 * s, whiteD)
            for y in stride(from: top + 9 * s, to: g, by: 4 * s) { c.rect(px, y, 3 * s, max(1, s / 2), whiteD) }
        }
        for k in 0...(2 * half) {   // the arch, stepped
            let u = Double(k - half) / Double(half), y = top + 6 * s - Int((1 - u * u) * Double(6 * s))
            c.rect(x - half + k, y, 1, 2 * s, white); c.rect(x - half + k, y + 2 * s, 1, max(1, s / 2), whiteD)
        }
        // The roses climbing the posts and over the top.
        for i in 0..<34 {
            let side = i % 2 == 0, v = noise(i + 760)
            let px = side ? x - half + s : x + half - 2 * s, py = top + 2 * s + Int(v * Double(g - top - 4 * s))
            let over = i % 5 == 0
            let lx = over ? x - half + Int(noise(i + 770) * Double(2 * half)) : px + Int((noise(i + 780) - 0.5) * Double(5 * s))
            let ly = over ? top + Int(noise(i + 790) * Double(5 * s)) : py
            c.rect(lx, ly, 2 * s, 2 * s, i % 3 == 0 ? leafL : leaf)
            if i % 2 == 1 || over { c.rect(lx, ly, s, s, [C(0xF08AB0), C(0xE05A78), C(0xF8F4EC)][i % 3]) }
        }
    }

    /// A garden bench of white stone before the hedge: a long seat on two scrolled legs, lit along its top.
    private static func huntHeavenBench(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), x = huntHeavenGarden(c, g).bench
        let st = C(0xD8D4C4), stL = C(0xF0ECDE), stD = C(0xA8A496)
        c.ellipse(x + 2 * s, g, 14 * s, s, C(0x2E4A26, 0.5))
        c.rect(x - 12 * s, g - 8 * s, 24 * s, 2 * s, st); c.rect(x - 12 * s, g - 8 * s, 24 * s, max(1, s / 2), stL)
        c.rect(x - 12 * s, g - 6 * s, 24 * s, max(1, s / 2), stD)
        for lx in [x - 10 * s, x + 7 * s] {
            c.rect(lx, g - 6 * s, 3 * s, 6 * s, st); c.rect(lx + 2 * s, g - 6 * s, s, 6 * s, stD)
            c.rect(lx - s, g - s, 5 * s, s, st)
        }
    }

    /// The fountain: a wide stone basin, a pedestal, a smaller bowl and a finial, water spilling from the bowl's lip.
    private static func huntHeavenFountain(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHeavenFrame(c, g)
        let x = f.fountain.x, y = f.fountain.y
        let st = C(0x9C988A), stL = C(0xBAB6A6), stD = C(0x726E62), water = C(0x6A9AC0), waterL = C(0xA8D0EA)
        c.ellipse(x + 3 * s, y + s, 20 * s, 2 * s, C(0x2E4A26, 0.5))
        // The pedestal and the bowl above.
        c.rect(x - 2 * s, y - 20 * s, 4 * s, 14 * s, st); c.rect(x - 2 * s, y - 20 * s, s, 14 * s, stL); c.rect(x + s, y - 20 * s, s, 14 * s, stD)
        c.rect(x - 8 * s, y - 22 * s, 16 * s, 2 * s, st); c.rect(x - 8 * s, y - 22 * s, 16 * s, max(1, s / 2), stL)
        c.rect(x - 6 * s, y - 20 * s, 12 * s, s, stD)
        c.rect(x - 7 * s, y - 23 * s, 14 * s, s, water)
        c.rect(x - s, y - 27 * s, 2 * s, 5 * s, st); c.rect(x - s, y - 27 * s, max(1, s / 2), 5 * s, stL); c.circle(x, y - 28 * s, s, stL)
        // Water falling from the bowl's lip into the basin.
        for wx in [x - 8 * s, x + 7 * s] { c.rect(wx, y - 20 * s, max(1, s), 13 * s, waterL.alpha(0.55)) }
        // The basin: water in it, a lit rim, carved panels down its face.
        c.rect(x - 16 * s, y - 7 * s, 32 * s, 7 * s, st)
        c.rect(x - 16 * s, y - 7 * s, 32 * s, s, stL); c.rect(x - 16 * s, y - 7 * s, s, 7 * s, stL)
        c.rect(x + 15 * s, y - 7 * s, s, 7 * s, stD)
        c.rect(x - 15 * s, y - 8 * s, 30 * s, s, water); c.rect(x - 12 * s, y - 8 * s, 6 * s, max(1, s / 2), waterL)
        for px in stride(from: x - 13 * s, to: x + 13 * s, by: 7 * s) { c.rect(px, y - 5 * s, 5 * s, 3 * s, stD.alpha(0.5)) }
    }

    /// The screen saver's sky: a blaze of white round a doorway of light standing at the top of white steps on a green
    /// rise, rays fanning out from it, soft gold-edged clouds drifting either side.
    private static func huntHeavenDoor(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = huntHeavenFrame(c, g)
        let dx = f.door.x, dy = f.door.y, glowY = dy - 30 * s
        // The blaze round the doorway: rings of white, and rays fanning up and out across the sky.
        for r in stride(from: 150 * s, to: 10 * s, by: -14 * s) { c.circle(dx, glowY, r, C(0xFFFFFF, 0.07)) }
        for k in 0..<9 {
            let a = Double.pi + Double(k + 1) / 10 * Double.pi, len = Double(c.w)
            c.glowLine(Double(dx), Double(glowY), Double(dx) + cos(a) * len, Double(glowY) + sin(a) * len,
                       core: C(0xFFF8DC, 0.14), glow: C(0xFFF8DC, 0.06), coreR: Double(3 * s), glowR: Double(10 * s))
        }
        // Banks of cloud, white with gold along their bases, near and big up high, smaller lower down.
        let banks: [(Int, Int, Int)] = [(8, 8, 16), (34, 4, 14), (70, 10, 18), (96, 5, 14), (20, 24, 11), (84, 28, 12),
                                        (4, 42, 9), (44, 20, 8), (94, 46, 9), (28, 50, 7), (74, 40, 7)]
        for (k, (u, v, r)) in banks.enumerated() {
            cloud(c, c.w * u / 100, g * v / 100, r * s, seed: 40 + k, top: C(0xFFFFFA), base: C(0xF2DC98))
        }
        // The green rise beyond the garden that the doorway stands on: a long hill with a gentle shoulder to one side,
        // its crest lit white-gold from the doorway, the slopes stepping down through mid greens to a shade at the
        // foot, two terraces following its shape, a white path winding up it to the steps, and dark cypresses and
        // round bushes dotted over it.
        let foot = f.far + 6 * s, rise = foot - dy + 2 * s, half = 140 * s
        func crest(_ x: Int) -> Int? {
            let d = Double(x - dx) / Double(half)
            guard abs(d) < 1 else { return nil }
            let shoulder = 0.18 * exp(-pow((d + 0.55) / 0.22, 2)) - 0.08 * exp(-pow((d - 0.5) / 0.2, 2))
            return foot - Int(Double(rise) * (pow(1 - d * d, 1.4) + shoulder))
        }
        for x in stride(from: max(0, dx - half), to: min(c.w, dx + half), by: 1) {
            guard let top = crest(x) else { continue }
            let depth = foot - top
            c.rect(x, top, 1, depth, C(0x6E9E54))
            c.rect(x, top, 1, depth * 55 / 100, C(0x7AAA5E))
            c.rect(x, top, 1, max(1, min(depth, 3 * s)), abs(x - dx) < 70 * s ? C(0xA8D486) : C(0x8CBC6C))
            for frac in [40, 72] where depth * frac / 100 > 4 * s {   // the terraces
                c.rect(x, top + depth * frac / 100, 1, max(1, s), C(0x5E8E48)); c.rect(x, top + depth * frac / 100 - max(1, s / 2), 1, max(1, s / 2), C(0x96C478))
            }
        }
        // The path, winding up from the garden to the foot of the steps.
        var prev: (Double, Double)? = nil
        for k in 0...40 {
            let u = Double(k) / 40
            let p = (Double(dx) + sin(u * .pi * 2.2) * Double(26 * s) * (1 - u) + Double(30 * s) * (1 - u), Double(foot) - Double(foot - dy - 12 * s) * u)
            if let q = prev {
                c.glowLine(q.0, q.1, p.0, p.1, core: C(0xF0EAD4), glow: C(0xC8C2A8, 0.6), coreR: Double(s) * (1.6 - u), glowR: Double(s) * (2.4 - u))
            }
            prev = p
        }
        // Cypresses, tall and dark, and round bushes, standing on the slopes.
        for (k, xp) in [-110, -86, -60, 52, 78, 104, 122].enumerated() {
            let x = dx + xp * s
            guard let top = crest(x) else { continue }
            if k % 2 == 0 {
                c.ellipse(x, top - 7 * s, 3 * s, 9 * s, C(0x2E5A2E)); c.ellipse(x - s, top - 9 * s, s, 6 * s, C(0x4A7A3E))
            } else {
                c.ellipse(x, top - 2 * s, 6 * s, 4 * s, C(0x3E7236)); c.ellipse(x - 2 * s, top - 3 * s, 3 * s, 2 * s, C(0x5A9246))
            }
        }
        // The steps climbing to the doorway, white stone with grey treads.
        for k in 0..<7 {
            let w = (50 - k * 4) * s, y = dy + (6 - k) * 2 * s
            c.rect(dx - w / 2, y, w, 2 * s, C(0xD8D4C4)); c.rect(dx - w / 2, y + 2 * s - max(1, s / 2), w, max(1, s / 2), C(0xA8A496))
        }
        // The doorway: a tall stone arch framing pure light, a glow spilling down the steps.
        let w = 34 * s, h = 62 * s, top = dy - h
        c.rect(dx - w / 2 - 3 * s, top + 4 * s, w + 6 * s, h - 4 * s, C(0xC8C2AE))
        c.circle(dx, top + 4 * s, w / 2 + 3 * s, C(0xC8C2AE))
        c.rect(dx - w / 2 - 3 * s, top + 4 * s, s, h - 4 * s, C(0xE4DECA)); c.rect(dx + w / 2 + 2 * s, top + 4 * s, s, h - 4 * s, C(0xA09A88))
        c.rect(dx - w / 2, top + 4 * s, w, h - 4 * s, C(0xFFFFFF)); c.circle(dx, top + 4 * s, w / 2, C(0xFFFFFF))
        c.ellipse(dx, dy + 8 * s, 24 * s, 7 * s, C(0xFFFFFF, 0.3))
    }

    /// Heaven's life: leaves drifting down from the great tree, swaying as they fall, and the light shimmering:
    /// the rays breathing brighter and dimmer, sparkles winking over the fountain's water.
    static func huntHeavenLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = huntHeavenFrame(c, g)
        // The rays breathe.
        for k in 0..<3 {
            let a = (sin(t * 0.6 + Double(k) * 2.1) * 0.5 + 0.5) * 0.08
            let x0 = c.w * (12 + k * 30) / 100, w = 8 * s
            for y in stride(from: 0, to: f.far, by: 1) { c.rect(x0 + (y * 2) / 5, y, w, 1, C(0xFFFFFF, a)) }
        }
        // Sparkles over the fountain.
        for k in 0..<5 {
            let on = sin(t * (2.3 + Double(k) * 0.7) + Double(k) * 1.9) > 0.6
            if on {
                let x = f.fountain.x - 12 * s + Int(noise(k + 950) * Double(24 * s)), y = f.fountain.y - 8 * s - Int(noise(k + 960) * Double(14 * s))
                c.rect(x, y, max(1, s), max(1, s), C(0xFFFFFF, 0.9))
            }
        }
        // Two white butterflies fluttering round the arbour's roses, wings opening and shutting.
        let arbour = huntHeavenGarden(c, g).arbour
        for k in 0..<2 {
            let ph = t * (0.35 + 0.1 * Double(k)) + Double(k) * 2.4
            let x = arbour + Int(sin(ph * 1.3) * Double(16 * s)), y = g - 26 * s + Int(sin(ph * 2.1) * Double(5 * s))
            let open = Int(t * 7 + Double(k)) % 2 == 0
            c.rect(x, y, max(1, s), max(1, s), C(0x6A6A5A))
            if open { c.rect(x - s, y - s, s, s, C(0xFFFFFA)); c.rect(x + s, y - s, s, s, C(0xFFFFFA)) } else { c.rect(x, y - s, s, s, C(0xFFFFFA)) }
        }
        // The falling leaves.
        for i in 0..<9 {
            let speed = 0.06 + noise(i + 980) * 0.05
            let u = (t * speed + noise(i + 990)).truncatingRemainder(dividingBy: 1)
            let fall = Double(g - f.tree.canopy + 30 * s)
            let x = f.tree.x + Int((noise(i + 1000) - 0.4) * Double(90 * s) + sin(t * 1.4 + Double(i)) * Double(3 * s))
            let y = f.tree.canopy - 20 * s + Int(u * fall)
            guard y < g else { continue }
            let tone = i % 3 == 0 ? C(0xD8C850) : C(0x6AA048)
            let flat = Int(t * 2 + Double(i)) % 2 == 0
            c.rect(x, y, flat ? 2 * s : s, flat ? s : 2 * s, tone.alpha(min(1, (1 - u) * 3)))
        }
    }
}
