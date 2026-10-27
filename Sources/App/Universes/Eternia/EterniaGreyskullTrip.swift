import CoreGraphics
import Foundation

// By the Power of Greyskull (`EterniaWipe.greyskull`), the signature opening and the rarest, longest trip; the
// trailer opens on it too. Dusk comes down over the old place and Castle Greyskull stands black against the setting
// sun; a fist comes up from the bottom holding the Power Sword against the sky, lightning forks down into its tip, the
// blade blazes, bolts crackle out of it to every edge, and a starburst of white swallows the screen and clears on the
// new place.

extension EterniaTrip {
    /// By the Power of Greyskull, `k` (0…1) through its own part, over the whole of `r`. Dusk comes down over the old
    /// place a band of sky at a time, violet at the top to orange at the horizon, while the castle's silhouette and its
    /// cliff rise into it against the sun (0–0.2); He-Clawd's fist rises from the bottom with the Power Sword
    /// (0.18–0.36) and a glint runs up the blade (0.36–0.42); the lightning forks down from the top of the sky into its
    /// tip (0.42–0.5) and stays there, flickering, the blade blazing white and gold, the sky flashing and the castle's
    /// edge lit white (0.5–0.86); bolts crackle out from the blade to every edge (0.6–0.8); a starburst of white with a
    /// gold rim grows out of the sword over everything (0.72–0.86), and breaks up in a dither onto the new place, the
    /// edges first (0.86–1).
    func drawGreyskull(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let u = max(1, h / 80)
        let foot = h - (art.wide ? 14 : 24)                 // the cliff's top, where the castle stands
        let castleX = Int(Double(w) * (art.wide ? 0.63 : 0.64)) - 60, castleY = foot - 55
        let hx = Int(Double(w) * (art.wide ? 0.34 : 0.27))  // the sword's middle
        let tipY = art.wide ? 10 : 18                       // where its tip comes to rest
        let heart = (x: Double(hx), y: Double(tipY + 20 * u))   // the blade's middle, where the white-out starts

        // The end: the new place, the white breaking up over it.
        if k >= 0.86 {
            ctx.drawShot(new, in: r)
            let left = 1 - Self.ease(Self.span(k, 0.86, 1))
            let far = (Double(w * w + h * h)).squareRoot()
            for y in 0..<h {
                for x in 0..<w {
                    let dx = Double(x) - heart.x, dy = Double(y) - heart.y
                    let d = (dx * dx + dy * dy).squareRoot() / far
                    let v = eterniaGreyskullBayer[(y % 4) * 4 + x % 4] * 0.6 + 0.4 * (1 - d)
                    if v < left { c.px(x, y, C(0xFFFBEA)) }
                }
            }
            art.show(ctx)
            return
        }

        let fall = Self.ease(Self.span(k, 0, 0.16)), rise = Self.ease(Self.span(k, 0.05, 0.2))
        let raise = Self.ease(Self.span(k, 0.18, 0.36))
        let glint = Self.span(k, 0.36, 0.42), strike = Self.span(k, 0.42, 0.5)
        let blazing = k >= 0.5
        let crackle = Self.span(k, 0.6, 0.8), burst = Self.span(k, 0.72, 0.86)
        let tick = Int(k * 2.8 / 0.07)                      // the lightning redraws itself every 0.07 s
        // The sky flashes as the bolt lands, and now and then while it crackles.
        var flash = blazing ? 1 - Self.span(k, 0.5, 0.56) : 0
        if blazing && noise(tick * 7 + 3) > 0.72 { flash = max(flash, 0.5) }

        // Underneath: the old place, darkening as the dusk comes over it.
        ctx.drawShot(old, in: r)
        Self.wash(ctx, 0x1A1028, 0.6 * fall, in: r)

        // The sky, on a canvas of its own so it can come down a band at a time: eight bands from violet to orange,
        // the sun low behind the castle in flat rings, long clouds, and the far peaks along the horizon.
        let sky = PixelCanvas(w, h)
        let bands = 8, bh = (foot + bands - 1) / bands
        for i in 0..<bands {
            let base = Self.mix(0x2A1C4C, 0xF0904A, Double(i) / Double(bands - 1))
            sky.rect(0, i * bh, w, bh, flash > 0 ? eterniaLighter(base, 0.55 * flash) : base)
        }
        let sun = (x: castleX + 60, y: castleY + 24, r: 20)
        for (m, a) in [(1.7, 0.12), (1.35, 0.2)] { sky.circle(sun.x, sun.y, Int(Double(sun.r) * m), C(0xFFB060, a)) }
        sky.circle(sun.x, sun.y, sun.r, C(0xFFD890)); sky.circle(sun.x - 4, sun.y - 4, sun.r * 2 / 3, C(0xFFEAB4))
        let banks: [(x: Double, y: Double, len: Int)] = art.wide
            ? [(0.04, 0.3, 40), (0.14, 0.62, 30), (0.84, 0.24, 36), (0.88, 0.56, 26), (0.5, 0.14, 22)]
            : [(0.02, 0.36, 44), (0.72, 0.16, 40), (0.5, 0.5, 30), (0.06, 0.66, 30), (0.86, 0.6, 34)]
        for (i, b) in banks.enumerated() {
            Scenes.eterniaCloudBank(sky, Int(Double(w) * b.x), Int(Double(foot) * b.y), b.len * u, u, seed: i)
        }
        sky.dunes(base: foot - 7, amp: Double(4 * u), freq: 0.07 / Double(u), phase: 1.3, bottom: foot + 2,
                  C(0x56385E), shade: C(0x6A4670))
        c.paste(sky.onlyRows(0..<Int((fall * Double(bands)).rounded(.up)) * bh))

        // The land, rising into place: the cliff in silhouette and the castle black against the sun, the lighter
        // stone a shade up from the dark so its skull still shows, its sockets and mouth darker, its edge lit.
        let land = PixelCanvas(w, h)
        for x in 0..<w {
            let top = foot - Int(noise(x / 3 + 77) * 3)
            land.rect(x, top, 1, h - top, C(0x160E20)); land.px(x, top, C(0x6A3A5A))
        }
        eterniaGreyskullSilhouette(land, castleX, castleY, rim: flash > 0.3 || burst > 0 ? C(0xFFF0B0) : C(0xE8904A))
        c.paste(land, y: Int((1 - rise) * Double(h - castleY + 4)))

        // The Power Sword, coming up from below.
        let top = tipY + Int((1 - raise) * Double(h - tipY + 4))
        guard raise > 0 else { art.show(ctx); return }
        let tip = (x: Double(hx), y: Double(top))
        // The lightning into its tip: a jagged white-gold fork from the top of the sky, growing down to it, then
        // staying, redrawing itself, two branches forking off it.
        if strike > 0 {
            let main = eterniaJag(from: (Double(hx) + Double(w) * 0.07, -4), to: tip, steps: 9, amp: 5 * Double(u), seed: tick * 31)
            let reach = -4 + strike * (tip.y + 4)
            eterniaBolt(c, eterniaUpTo(main, y: reach), core: 1 + u)
            for (n, side) in [(3, -1.0), (6, 1.0)] where main[n].1 < reach {
                let a = main[n], len = 12 + 8 * noise(tick * 5 + n)
                let fork = eterniaJag(from: a, to: (a.0 + side * len * Double(u), a.1 + 9 * Double(u)), steps: 4,
                                      amp: 2 * Double(u), seed: tick * 17 + n)
                eterniaBolt(c, fork, core: u)
            }
        }
        // Blazing, the blade stands in a flat aura the shape of the blade, pale gold inside gold, a pixel wider on
        // every other flicker.
        if blazing {
            let grow = tick % 2
            for j in -2..<41 {
                let half = j < 1 ? 1 : j < 3 ? 2 : 3
                let y = top + j * u
                c.rect(hx - (half + 2 + grow) * u, y, (2 * half + 4 + 2 * grow) * u, u, C(0xFFC830))
                c.rect(hx - (half + 1) * u, y, (2 * half + 2) * u, u, C(0xFFF0B0))
            }
        }
        eterniaPowerSword(c, hx, top, u: u, blazing: blazing)
        // The glint: a little four-pointed star running up the blade from the guard to the tip.
        if glint > 0 && glint < 1 {
            let gy = top + Int((1 - glint) * Double(38 * u))
            eterniaTwinkle(c, hx, gy, u: u, size: glint > 0.85 ? 3 : 2)
        }
        // Blazing: sparks of white and gold flickering off the blade.
        if blazing {
            for i in 0..<6 {
                let side = i % 2 == 0 ? -1 : 1
                let sx = hx + side * Int((6 + 6 * noise(tick * 13 + i)) * Double(u))
                let sy = top + Int((4 + 34 * noise(tick * 7 + i * 3)) * Double(u))
                eterniaTwinkle(c, sx, sy, u: u, size: 1 + (tick + i) % 2)
            }
        }
        // The bolts crackling out of it to every edge, one after another, each growing out from the blade.
        if crackle > 0 {
            let ends: [(x: Double, y: Double, at: Double)] = [
                (-8, 0.2, 0), (1.02, 0.14, 0.06), (-8, 0.74, 0.14), (1.02, 0.66, 0.1), (0.12, -0.06, 0.22),
                (0.9, -0.06, 0.18), (0.62, 1.08, 0.3), (-8, 1.04, 0.26), (1.02, 1.04, 0.34),
            ]
            for (i, e) in ends.enumerated() {
                let grow = Self.span(crackle, e.at, e.at + 0.4)
                guard grow > 0 else { continue }
                let from = (heart.x, Double(top) + Double((6 + (i * 7) % 28) * u))
                let ex = e.x < 0 ? -8 : e.x * Double(w), ey = e.y * Double(h)
                let steps = max(4, Int(abs(ex - from.0) + abs(ey - from.1)) / (14 * u))
                let path = eterniaJag(from: from, to: (ex, ey), steps: steps, amp: 4 * Double(u), seed: tick * 11 + i * 101)
                eterniaBolt(c, eterniaPart(path, grow), core: u)
            }
        }
        // The white-out: a starburst, twelve-pointed, white inside a pale band and a gold rim, growing over all of it.
        if burst > 0 {
            let reach = (Double(w * w + h * h).squareRoot() + 8 * Double(u)) / 0.72
            let R = pow(burst, 1.5) * reach, rim = 2 * Double(u)
            for y in 0..<h {
                for x in 0..<w {
                    let dx = Double(x) - heart.x, dy = Double(y) - heart.y
                    let d = (dx * dx + dy * dy).squareRoot()
                    guard d < R else { continue }
                    let turn = (atan2(dy, dx) / (2 * .pi) * 12 + 12).truncatingRemainder(dividingBy: 1)
                    let spike = 1 - abs(turn - 0.5) * 2
                    let edge = R * (0.72 + 0.34 * spike)
                    guard d < edge else { continue }
                    let inside = edge - d
                    c.px(x, y, inside < rim ? C(0xFFC830) : inside < 2 * rim ? C(0xFFF0B0) : C(0xFFFBEA))
                }
            }
        }
        art.show(ctx)
    }
}

/// A 4×4 ordered dither, thresholds in 0…1.
private let eterniaGreyskullBayer: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

/// `p` lightened `m` of the way to a pale lilac: the sky lit by the lightning.
private func eterniaLighter(_ p: Px, _ m: Double) -> Px {
    let q = (m * 4).rounded() / 4
    func ch(_ a: UInt8, _ b: Double) -> UInt8 { UInt8(Double(a) + (b - Double(a)) * q) }
    return Px(r: ch(p.r, 0xE8), g: ch(p.g, 0xD8), b: ch(p.b, 0xF4), a: 255)
}

/// Castle Greyskull (the place's own drawing) in silhouette with its top-left at `x`, `y`: the lighter stone a shade
/// up from the dark, its sockets and mouth darker still, and its outline lit `rim` by the sun behind it.
private func eterniaGreyskullSilhouette(_ c: PixelCanvas, _ x: Int, _ y: Int, rim: Px) {
    let castle = PixelCanvas(120, 56)
    Scenes.eterniaGreyskullCastle(castle)
    func solid(_ cx: Int, _ cy: Int) -> Bool { cx >= 0 && cy >= 0 && cx < 120 && cy < 56 && castle.buf[(cy * 120 + cx) * 4 + 3] > 0 }
    for cy in 0..<56 {
        for cx in 0..<120 where solid(cx, cy) {
            let i = (cy * 120 + cx) * 4
            let lum = Int(castle.buf[i]) + Int(castle.buf[i + 1]) + Int(castle.buf[i + 2])
            var col = lum < 90 ? C(0x0A0610) : lum > 360 ? C(0x34283E) : C(0x1E1630)
            if !solid(cx, cy - 1) || !solid(cx - 1, cy) || !solid(cx + 1, cy) { col = rim }
            c.px(x + cx, y + cy, col)
        }
    }
}

/// The Power Sword straight up in He-Clawd's fist, blown up `u` times with its tip's top at (`x`, `top`) and `x` its
/// middle: a silver blade with a dark outline, a silver crossguard, his bronze fist round the grip, a brown bracer, and
/// his forearm down off the bottom. Blazing, the blade goes white with a gold edge.
private func eterniaPowerSword(_ c: PixelCanvas, _ x: Int, _ top: Int, u: Int, blazing: Bool) {
    let rows = [
        ".......kk.......",   // the tip
        "......kLsk......",
        "......kLsk......",
    ] + Array(repeating: ".....kLLsdk.....", count: 37) + [   // the blade
        "kkkkkkkkkkkkkkkk",   // the crossguard
        "kGGGGGGgggggggHk",
        "kkkkkkkkkkkkkkkk",
        "..kkkkkkkkkkk...",   // the fist, fingers across
        ".kOOOOOOOOOOdk..",
        ".klOOOOOOOOOdk..",
        ".kddddddddOOdk..",
        ".klOOOOOOOOOdk..",
        ".kddddddddOOdk..",
        ".klOOOOOOOOOdk..",
        ".kddddddddOOdk..",
        "..kOOOOOOOOOk...",
        "..kkkkkkkkkkk...",   // the bracer
        "..kBBBBBBbbnk...",
        "..kbbbbbbbbnk...",
        "..kBBBBBBbbnk...",
        "..kkkkkkkkkkk...",
    ]
    let arm = "...kOOOOOOdk...."   // the forearm, down off the bottom
    let pal: [Character: Px] = [
        "k": blazing ? C(0x8A5A10) : C(0x1E1828),
        "L": blazing ? C(0xFFFFFF) : C(0xE2E4EC), "s": blazing ? C(0xFFF6C8) : C(0xB4B8C4),
        "d": C(0xA8553C), "G": C(0xE2E4EC), "g": C(0xB4B8C4), "H": C(0x7E8290),
        "O": clawdOrange, "l": C(0xF09A78), "B": C(0x8A5E38), "b": C(0x6A4428), "n": C(0x4A2E18),
    ]
    // The blade's dark edge is the hand's dark on the fist rows; on the blade it's steel in shade, or gold ablaze.
    let bladeD = blazing ? C(0xFFD860) : C(0x7E8290)
    let x0 = x - 8 * u
    func put(_ row: String, _ y: Int, blade: Bool) {
        for (i, ch) in row.enumerated() {
            guard var col = pal[ch] else { continue }
            if blade && ch == "d" { col = bladeD }
            if !blade && ch == "k" { col = C(0x1E1828) }
            c.rect(x0 + i * u, y, u, u, col)
        }
    }
    for (j, row) in rows.enumerated() { put(row, top + j * u, blade: j < 40) }
    var y = top + rows.count * u
    while y < c.h { put(arm, y, blade: false); y += u }
}

/// A little four-pointed star of white, `size` arms long, at (`x`, `y`), `u` pixels a dot.
private func eterniaTwinkle(_ c: PixelCanvas, _ x: Int, _ y: Int, u: Int, size: Int) {
    for i in -size...size {
        let col = abs(i) == size ? C(0xFFE07A) : C(0xFFFFFF)
        c.rect(x + i * u - u / 2, y - u / 2, u, u, col); c.rect(x - u / 2, y + i * u - u / 2, u, u, col)
    }
}

/// A jagged line from `a` to `b` in `steps` pieces, each joint knocked sideways up to `amp` (the ends stay put).
private func eterniaJag(from a: (Double, Double), to b: (Double, Double), steps: Int, amp: Double, seed: Int) -> [(Double, Double)] {
    let dx = b.0 - a.0, dy = b.1 - a.1
    let len = max(0.001, (dx * dx + dy * dy).squareRoot())
    let nx = -dy / len, ny = dx / len
    var pts: [(Double, Double)] = []
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let off = i == 0 || i == steps ? 0 : (noise((seed + i * 13) & 0xFFFFF) - 0.5) * 2 * amp
        pts.append((a.0 + dx * t + nx * off, a.1 + dy * t + ny * off))
    }
    return pts
}

/// The first `f` (0…1) of a path, by its pieces, the last one cut part way.
private func eterniaPart(_ pts: [(Double, Double)], _ f: Double) -> [(Double, Double)] {
    guard pts.count > 1, f < 1 else { return pts }
    let along = f * Double(pts.count - 1)
    let n = Int(along), t = along - Double(n)
    var out = Array(pts[0...n])
    if n + 1 < pts.count {
        let a = pts[n], b = pts[n + 1]
        out.append((a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t))
    }
    return out
}

/// A path going down, as far as row `y`, the last piece cut there.
private func eterniaUpTo(_ pts: [(Double, Double)], y: Double) -> [(Double, Double)] {
    var out: [(Double, Double)] = []
    for (i, p) in pts.enumerated() {
        if p.1 <= y { out.append(p); continue }
        if i > 0 {
            let a = pts[i - 1], t = (y - a.1) / max(0.001, p.1 - a.1)
            out.append((a.0 + (p.0 - a.0) * t, y))
        }
        break
    }
    return out
}

/// Lightning along a path: a white-hot core `core` pixels thick inside a pixel of gold either side, stamped square
/// by square so it stays chunky (all the gold first, so it never covers the core of a piece before it).
private func eterniaBolt(_ c: PixelCanvas, _ pts: [(Double, Double)], core: Int,
                         edge: Px = C(0xFFC830), hot: Px = C(0xFFFBE8)) {
    guard pts.count > 1 else { return }
    for pass in 0..<2 {
        let size = pass == 0 ? core + 2 : core, col = pass == 0 ? edge : hot
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let n = max(1, Int(max(abs(b.0 - a.0), abs(b.1 - a.1)).rounded(.up)))
            for s in 0...n {
                let t = Double(s) / Double(n)
                let x = Int((a.0 + (b.0 - a.0) * t).rounded()) - size / 2, y = Int((a.1 + (b.1 - a.1) * t).rounded()) - size / 2
                c.rect(x, y, size, size, col)
            }
        }
    }
}
