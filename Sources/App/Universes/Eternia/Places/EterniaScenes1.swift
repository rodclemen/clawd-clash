import Foundation

// Places on Eternia, a few to a file. Filmation's palette: flat cel colours with dark edges, painted dusk skies of
// purple, orange and teal, earthy greens and sandstone. The crew stands on the ground row `g`; the busy detail is up
// and to the sides.

let eterniaScenes1: [Location: Place] = [
    .eterniaGreyskull: Place(name: "Castle Greyskull", panel: 0x1A1626, still: Scenes.eterniaGreyskull,
                             moving: Scenes.eterniaGreyskullLife),
]

// MARK: - Castle Greyskull

extension Scenes {
    /// Where things stand at Castle Greyskull, shared by the still picture and the moving layer: the far cliff's top
    /// (the castle stands on it, across the chasm), the keep (its left edge, width and height), and the mouth's
    /// opening, where the jawbridge comes down from.
    static func eterniaGreyskullFrame(_ c: PixelCanvas, _ g: Int) -> (cliff: Int, keep: (x: Int, w: Int, h: Int),
                                                                      mouth: (x: Int, w: Int, y: Int)) {
        let s = unit(g), q = 2 * s   // the castle is drawn in double units: it's the biggest thing on Eternia
        let cliff = g - 9 * s
        let w = 34 * q, h = 22 * q, x = c.w * 58 / 100 - w / 2
        return (cliff, (x, w, h), (x + 11 * q, 12 * q, cliff - 7 * q))
    }

    /// Castle Greyskull at dusk: a Filmation sky banded from deep violet down to orange, far purple peaks, the castle
    /// across the chasm on its pillar of rock. Its keep is a great skull carved in grey-green stone, brow and sockets
    /// and nose, its mouth the gate with the jawbridge lowered across the chasm to the near ledge, chains up to the
    /// jaw. A tall round tower with a peaked cap rises on its left, a squat crenellated one on its right. The chasm
    /// is black-green below the bridge, and the crew stands on the near ledge of grey rock. On the screen saver the
    /// sky goes far higher, with the first stars and a pale moon in it.
    static func eterniaGreyskull(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaGreyskullFrame(c, g), tall = isTall(c)
        c.gradient(0, f.cliff, C(0x2E2052), C(0xE88A4E), bands: 8)
        if tall {
            // The first stars, Eternia's two moons, and long clouds lit orange from underneath by the sunset.
            for k in 0..<18 {
                let x = Int(noise(k * 11 + 3) * Double(c.w)), y = Int(noise(k * 11 + 4) * Double(f.cliff / 3))
                c.rect(x, y, max(1, s / 2), max(1, s / 2), C(0xE8E0FF))
            }
            c.circle(c.w * 16 / 100, f.cliff / 5, 9 * s, C(0xE8DCD0)); c.circle(c.w * 16 / 100 + 3 * s, f.cliff / 5 - 2 * s, 7 * s, C(0xD8C8C4))
            c.circle(c.w * 26 / 100, f.cliff / 5 + 10 * s, 4 * s, C(0xC8B8D8))
            for k in 0..<6 {
                let x = c.w * (8 + k * 17) / 100, y = f.cliff * (30 + (k % 3) * 12) / 100
                cloud(c, x, y, (5 + (k % 2) * 2) * s, seed: k + 7, top: C(0xF0A07A), base: C(0x8A5A84))
            }
        }
        // The far peaks: two ranges of jagged violet, the nearer darker.
        let far = f.cliff - (tall ? 40 : 14) * s
        if tall { c.dunes(base: far - 18 * s, amp: Double(10 * s), freq: 0.03 / Double(s), phase: 4.1, bottom: f.cliff, C(0xA06A8E), shade: C(0xB27A9A)) }
        c.dunes(base: far, amp: Double(6 * s), freq: 0.05 / Double(s), phase: 0.7, bottom: f.cliff, C(0x8A5A8A), shade: C(0x9E6A96))
        c.dunes(base: far + 6 * s, amp: Double(4 * s), freq: 0.08 / Double(s), phase: 2.3, bottom: f.cliff, C(0x5E3E6E), shade: C(0x6E4A7A))

        // The far cliff the castle stands on, across the whole back, lit along its lip, cracked down its face.
        let rock = C(0x4E4A52), rockD = C(0x36323A), rockL = C(0x6A6670)
        c.rect(0, f.cliff, c.w, 3 * s, rock); c.rect(0, f.cliff, c.w, max(1, s / 2), rockL)
        for k in 0..<(c.w / (9 * s) + 1) { c.rect(k * 9 * s + Int(noise(k + 20) * Double(4 * s)), f.cliff + s, max(1, s / 2), 2 * s, rockD) }
        // The chasm under it, black-green, down to the near ledge.
        c.gradient(f.cliff + 3 * s, g - s, C(0x1E2A22), C(0x0C120E), bands: 4)

        let q = 2 * s
        // The keep: the skull. Grey-green stone in courses, its dome rounding over the top, lit on the left.
        let k = f.keep, ky = f.cliff - k.h
        let stone = C(0x7E9274), stoneD = C(0x5E7058), stoneL = C(0x9CAE90), deep = C(0x141418)
        c.rect(k.x, ky + 6 * q, k.w, k.h - 6 * q, stone)
        c.ellipse(k.x + k.w / 2, ky + 7 * q, k.w / 2, 7 * q, stone)
        c.ellipse(k.x + k.w / 2 - 3 * q, ky + 5 * q, k.w / 2 - 6 * q, 4 * q, stoneL)
        c.ellipse(k.x + k.w / 2, ky + 7 * q, k.w / 2 - 3 * q, 5 * q, stone)
        c.rect(k.x, ky + 6 * q, 2 * q, k.h - 6 * q, stoneL); c.rect(k.x + k.w - 2 * q, ky + 6 * q, 2 * q, k.h - 6 * q, stoneD)
        for y in stride(from: ky + 9 * q, to: f.cliff, by: 4 * q) {
            c.rect(k.x + 2 * q, y, k.w - 4 * q, max(1, q / 3), stoneD)
            for x in stride(from: k.x + 2 * q + ((y / (4 * q)) % 2) * 3 * q, to: k.x + k.w - 2 * q, by: 6 * q) {
                c.rect(x, y, max(1, q / 3), 4 * q, stoneD)
            }
        }
        // The brow ridge, the two sockets, the nose, the cheekbones.
        c.rect(k.x + 4 * q, ky + 6 * q, 26 * q, 2 * q, stoneD); c.rect(k.x + 4 * q, ky + 5 * q, 26 * q, s, stoneL)
        for ex in [k.x + 6 * q, k.x + 20 * q] {
            c.ellipse(ex + 4 * q, ky + 10 * q, 4 * q, 3 * q, deep)
            c.rect(ex + s, ky + 8 * q, 6 * q, s, stoneD)
        }
        c.rect(k.x + 16 * q, ky + 11 * q, 2 * q, 2 * q, deep); c.rect(k.x + 15 * q, ky + 13 * q, 4 * q, s, deep)
        c.rect(k.x + 4 * q, ky + 14 * q, 6 * q, s, stoneD); c.rect(k.x + 24 * q, ky + 14 * q, 6 * q, s, stoneD)
        // The mouth: the gateway, dark inside, a row of stone teeth along its top.
        let m = f.mouth
        c.rect(m.x, m.y, m.w, f.cliff - m.y, deep)
        for x in stride(from: m.x, to: m.x + m.w, by: 2 * q) { c.rect(x, m.y, s, s, C(0xC8D2B8)) }

        // The left tower: tall and round, its stone in courses, a ring of crenellations and a peaked cap; on the
        // screen saver it rises higher, with a window or two more.
        let tw = 9 * q, tx = k.x - tw + s, th = (tall ? 80 : 40) * s, ty = f.cliff - th
        c.rect(tx, ty, tw, th, stone); c.rect(tx, ty, 2 * q, th, stoneL); c.rect(tx + tw - 2 * q, ty, 2 * q, th, stoneD)
        for y in stride(from: ty + 3 * q, to: f.cliff, by: 4 * q) { c.rect(tx + 2 * q, y, tw - 4 * q, max(1, q / 3), stoneD) }
        for x in stride(from: tx - s, to: tx + tw + s, by: 2 * q) { c.rect(x, ty - 2 * q, s, 2 * q, stoneD) }
        c.rect(tx - s, ty - s, tw + 2 * q, s, stone)
        for i in 0..<(7 * q) { c.rect(tx + i * tw / (14 * q), ty - 3 * q - i, max(1, tw - 2 * i * tw / (14 * q)), 1, C(0x5A4A6E)) }
        for wy in stride(from: ty + 6 * q, to: f.cliff - 6 * q, by: 10 * q) { c.rect(tx + 3 * q, wy, 3 * q, 4 * q, deep) }
        // The right tower: squat, crenellated, a slit window.
        let rw = 10 * q, rx = k.x + k.w - s, rh = 20 * q, ry = f.cliff - rh
        c.rect(rx, ry, rw, rh, stone); c.rect(rx + rw - 2 * q, ry, 2 * q, rh, stoneD)
        for x in stride(from: rx, to: rx + rw, by: 3 * q) { c.rect(x, ry - 2 * q, 2 * q, 2 * q, stone) }
        c.rect(rx + 4 * q, ry + 5 * q, 2 * q, 5 * q, deep)

        // The jawbridge, lowered from the mouth across the chasm to the near ledge, widening as it comes: planks in
        // rows, lit along the left.
        let wood = C(0x8A6438), woodD = C(0x5E4224), woodL = C(0xA67C4A)
        let top = f.cliff, bottom = g - s
        for y in top..<bottom {
            let k2 = Double(y - top) / Double(max(1, bottom - top))
            let w = Int(Double(m.w) * (1 + 0.8 * k2)), x = m.x + m.w / 2 - w / 2
            c.rect(x, y, w, 1, (y - top) / max(1, s * 2) % 2 == 0 ? wood : woodD)
            c.px(x, y, woodL); c.px(x + w - 1, y, woodD)
        }
        // The near ledge: grey rock, plain and mid-dark where the crew stands, a lit lip.
        c.ground(g, C(0x56525A), edge: C(0x6E6A74), speck: C(0x46424A), seed: 41)
    }

    /// Greyskull's life: green mist curling up out of the chasm either side of the bridge, the jawbridge's chains
    /// swaying a little, and, on the screen saver, Zoar the falcon circling high over the tower.
    static func eterniaGreyskullLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let s = unit(g), f = eterniaGreyskullFrame(c, g), m = f.mouth
        // Mist: soft green wisps drifting up and fading, kept to the chasm.
        for k in 0..<10 {
            let ph = (t * 0.12 + Double(k) * 0.1).truncatingRemainder(dividingBy: 1)
            let x = Int(noise(k * 13 + 5) * Double(c.w)) + Int(sin(t * 0.6 + Double(k)) * Double(3 * s))
            let y = g - 2 * s - Int(ph * Double(g - 2 * s - f.cliff))
            c.ellipse(x, y, 4 * s, max(1, s), C(0x7AC88A, 0.22 * (1 - ph)))
        }
        // The chains, from either side of the mouth's top down to the bridge's near corners, swaying.
        let sway = sin(t * 0.9) * Double(s)
        for side in [0, 1] {
            let x0 = Double(m.x + side * m.w), y0 = Double(m.y + 2 * s)
            let x1 = Double(m.x + m.w / 2) + (side == 0 ? -1.0 : 1.0) * Double(m.w) * 0.85, y1 = Double(g - 2 * s)
            for i in 0...20 {
                let k = Double(i) / 20, sag = sin(k * .pi) * Double(2 * s) + sway * sin(k * .pi)
                c.rect(Int(x0 + (x1 - x0) * k + sag), Int(y0 + (y1 - y0) * k), max(1, s / 2), max(1, s / 2), C(0x3A3A42))
            }
        }
        guard isTall(c) else { return }
        // Zoar, a little falcon, circling over the tower.
        let a = t * 0.4, cx = Double(f.keep.x) + cos(a) * Double(30 * s), cy = Double(f.cliff - 110 * s) + sin(a) * Double(8 * s)
        let flap = Int(t * 5) % 2 == 0
        c.rect(Int(cx), Int(cy), 2 * s, s, C(0x5A4A3A))
        c.rect(Int(cx) - 2 * s, Int(cy) - (flap ? s : 0), 2 * s, s, C(0x6A5A4A)); c.rect(Int(cx) + 2 * s, Int(cy) - (flap ? s : 0), 2 * s, s, C(0x6A5A4A))
    }
}
