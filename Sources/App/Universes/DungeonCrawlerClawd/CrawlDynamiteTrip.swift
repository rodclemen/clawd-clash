import CoreGraphics
import Foundation

// Goblin Dynamite (`CrawlWipe.dynamite`), likelier with Carl, Rory, Lorelai or Rosetta and going to the First Floor
// tunnels: a lit red stick of goblin dynamite rolls in across the floor and fizzes; BOOM, and the smoke clears on the
// new place.

extension CrawlTrip {
    /// Goblin Dynamite, `k` (0…1) through its own part, over the whole of `r`. A red stick, a tan paper band round its
    /// middle with a green goblin face on it, comes tumbling in end over end from the right along the floor, skidding
    /// to a stop flat on its side a little right of the middle (0–0.3). Its fuse fizzes down, spraying sparks and
    /// puffing smoke, the stick shivering harder as the spark nears it while the old place darkens (0.3–0.6). BOOM: a
    /// white flash, a chunky fireball of puffs bursting out from the stick, white at its heart, then yellow, orange
    /// and red as each puff cools to grey smoke, bits of stick and paper flying, the screen shaking, and BOOM in big
    /// block letters, yellow over orange with a dark red edge (0.6–0.8); the place behind the smoke is the new one
    /// from 0.74, once it covers everything. Then the smoke thins away, the top-left corner first so the System box
    /// has a clear corner, the letters crumbling with it (0.76–0.97).
    func drawDynamite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.97 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let frame = Int(k * CrawlWipe.dynamite.effect * 30)          // about 30 a second, for the sparks and the shake
        let floor = h - (art.wide ? 12 : 18)
        let len = Double(h) * (art.wide ? 0.34 : 0.3), thick = (len * 0.3).rounded()
        let bang = 0.6
        // The blast centre: where the stick comes to rest.
        let restX = Double(w) * 0.56, restY = Double(floor) - thick / 2

        // Underneath: the old place, darkening as the fuse burns down, and the new one once the smoke covers it all.
        if k < 0.74 {
            ctx.drawShot(old, in: r)
            Self.wash(ctx, 0x000000, 0.3 * Self.span(k, 0.3, bang), in: r)
        } else {
            ctx.drawShot(new, in: r)
        }

        if k < bang {
            // Rolling in: end over end, slowing, its lower end always on the floor, coming down flat.
            let roll = Self.span(k, 0, 0.3)
            let slow = 1 - pow(1 - roll, 2.4)
            var x = Double(w) + len - (Double(w) + len - restX) * slow
            let turn = pow(1 - roll, 1.8) * 4.5 * .pi
            let lift = abs(sin(turn)) * len / 2 + abs(cos(turn)) * thick / 2
            let shiver = Self.span(k, 0.42, bang)
            if roll >= 1, shiver > 0, frame % 2 == 0 { x += shiver > 0.5 ? 1 : (frame % 4 == 0 ? 1 : 0) }
            let y = Double(floor) - lift
            let fuse = 1 - Self.span(k, 0.3, bang)
            let tip = dynamiteStick(c, x: x, y: y, angle: turn, len: len, thick: thick, fuse: fuse, k: k)
            // Skidding: a few sparks off the floor as it comes down.
            if roll < 1 {
                for i in 0..<3 where noise(frame * 5 + i) > 0.4 {
                    c.px(Int(x - len / 3 + noise(frame * 5 + i + 9) * len / 1.5), floor - 1 - i % 2, C(0xFFD860))
                }
            }
            // The fuse fizzing: sparks thrown out from its burning tip, embers falling, a wisp of smoke.
            let fizz = k < 0.3 ? 0.5 : 1.0
            for i in 0..<Int(14 * fizz) {
                let s = frame * 31 + i * 7
                let a = noise(s) * 2 * .pi, d = 1 + noise(s + 1) * (art.wide ? 7 : 9)
                let col = noise(s + 2) > 0.6 ? C(0xFFFFFF) : noise(s + 3) > 0.4 ? C(0xFFE060) : C(0xFF8A20)
                let sx = Int(tip.x + cos(a) * d), sy = Int(tip.y + sin(a) * d * 0.8)
                c.px(sx, sy, col)
                if d < 4 { c.px(sx + (sx > Int(tip.x) ? 1 : -1), sy, col) }
            }
            c.rect(Int(tip.x) - 1, Int(tip.y) - 1, 3, 3, C(0xFFF4C0)); c.px(Int(tip.x), Int(tip.y), C(0xFFFFFF))
            for i in 0..<4 {
                let up = Double((frame + i * 5) % 20)
                c.px(Int(tip.x + sin(up * 0.5 + Double(i)) * 2), Int(tip.y - 3 - up * 0.6), C(0xB8B0B4, 0.7 - up / 30))
            }
            art.show(ctx)
            return
        }

        // BOOM. The fireball and the smoke after it, a field of round puffs on a grid that covers the whole frame,
        // each bursting out at its own moment (sooner nearer the stick) and cooling through the fire's colours to grey.
        let sp = Double(art.wide ? 16 : 18)
        let cols = Int(Double(w) / sp) + 2, rows = Int(Double(h) / sp) + 2
        let far = max(1, hypot(max(restX, Double(w) - restX), max(restY, Double(h) - restY)))
        struct Puff { let x: Double, y: Double, r: Double, born: Double, corner: Double, late: Double }
        var puffs: [Puff] = []
        for j in 0..<rows {
            for i in 0..<cols {
                let n = j * 97 + i * 13
                let x0 = (Double(i) - 0.5 + (noise(n) - 0.5) * 0.6) * sp
                let y0 = (Double(j) - 0.5 + (noise(n + 1) - 0.5) * 0.6) * sp
                let d = hypot(x0 - restX, y0 - restY) / far
                // Drifting a little out from the blast and up as it clears.
                let drift = Self.span(k, bang, 1) * sp * 0.5
                let ax = (x0 - restX) / max(1, hypot(x0 - restX, y0 - restY))
                puffs.append(Puff(x: x0 + ax * drift, y: y0 - drift * 0.8, r: sp * (1.2 + 0.35 * noise(n + 2)),
                                  born: bang + 0.07 * d, corner: 1 - min(1, x0 / Double(w) * 0.9 + y0 / Double(h) * 0.6), late: noise(n + 3)))
            }
        }
        let fire: [Px] = [C(0xFFFFFF), C(0xFFF0A0), C(0xFFC838), C(0xFF8A20), C(0xE04A1C), C(0x9A2A1C)]
        let smoke: [Px] = [C(0x5E585E), C(0x847E86), C(0xA8A2AA), C(0xCCC6CC)]
        let shake = k < 0.72 ? Int((1 - Self.span(k, bang, 0.72)) * 3 + 0.5) : 0
        let sx = shake > 0 ? Int((noise(frame * 3) - 0.5) * Double(shake * 2 + 1)) : 0
        let sy = shake > 0 ? Int((noise(frame * 3 + 1) - 0.5) * Double(shake * 2 + 1)) : 0
        for y in 0..<h {
            for x in 0..<w {
                let fx = Double(x - sx) + 0.5, fy = Double(y - sy) + 0.5
                var best = -1.0, who = -1
                // Only the puffs of the grid cells round this one can reach it.
                let ci = min(cols - 1, max(0, Int(fx / sp + 0.5))), cj = min(rows - 1, max(0, Int(fy / sp + 0.5)))
                for j in max(0, cj - 2)...min(rows - 1, cj + 2) {
                    for i in max(0, ci - 2)...min(cols - 1, ci + 2) {
                        let p = puffs[j * cols + i]
                        let grow = 1 - pow(1 - Self.span(k, p.born, p.born + 0.045), 2)
                        guard grow > 0 else { continue }
                        // Clearing: each puff shrinks away, those toward the top left sooner.
                        let gone = Self.span(k, 0.76 + 0.06 * p.late * (1 - p.corner), 0.95 - 0.1 * p.corner)
                        let rad = p.r * grow * (1 - gone * gone * 0.15) * (1 - gone)
                        guard rad > 0.5 else { continue }
                        let f = 1 - hypot(fx - p.x, fy - p.y) / rad
                        if f > best { best = f; who = j * cols + i }
                    }
                }
                guard best > 0, who >= 0 else { continue }
                let p = puffs[who]
                let age = k - p.born
                let col: Px
                if age < 0.07 {
                    // Fire: hotter in the puff's middle and the younger it is.
                    let heat = age / 0.07 * 0.8 + (1 - best) * 0.3
                    col = fire[min(fire.count - 1, Int(heat * Double(fire.count)))]
                } else {
                    // Smoke: a pale lit middle, a darker rim, shaded toward the bottom right.
                    let lit = best + (fx < p.x - 1 && fy < p.y - 1 ? 0.15 : 0) - (fx > p.x + 2 && fy > p.y + 2 ? 0.15 : 0)
                    col = smoke[lit > 0.7 ? 3 : lit > 0.42 ? 2 : lit > 0.18 ? 1 : 0]
                }
                c.px(x, y, col)
            }
        }

        // Bits of the stick and its paper flying out, tumbling down.
        let fly = Self.span(k, bang, 0.82)
        if fly > 0 && fly < 1 {
            for i in 0..<10 {
                let a = -.pi * (0.1 + 0.8 * noise(i * 7 + 400)), v = (0.6 + noise(i * 7 + 401)) * Double(h) * 0.9
                let bx = restX + cos(a) * v * fly + Double(sx), by = restY + sin(a) * v * fly + Double(h) * 0.9 * fly * fly
                let col = i % 3 == 0 ? C(0xD8C49A) : C(0xC82A22)
                c.rect(Int(bx), Int(by), 2 + i % 2, 2, col); c.px(Int(bx), Int(by), i % 3 == 0 ? C(0xF0E2C0) : C(0xF05A4A))
            }
        }

        // BOOM, popping up big, shaking with the blast, crumbling away as the smoke goes.
        let pop = Self.span(k, 0.605, 0.65)
        let crumble = Self.span(k, 0.8, 0.9)
        if pop > 0 && crumble < 1 {
            let full = max(2, min((w * 3 / 5) / 15, (h * 2 / 5) / 5))
            let s = max(1, Int((Double(full) * (pop < 1 ? 0.6 + 0.55 * pop : 1)).rounded()))
            dynamiteBoom(c, cx: Int(restX * 0.4 + Double(w) * 0.3) + sx, cy: h * 2 / 5 + sy, s: s, crumble: crumble)
        }
        art.show(ctx)

        // The flash: the whole frame white for a moment, fading in steps.
        let flash = 1 - Self.span(k, bang, bang + 0.06)
        if flash > 0 { Self.wash(ctx, 0xFFFFFF, flash, in: r) }
    }
}

/// The stick of goblin dynamite, centred on `x`, `y`, turned to `angle`: red, lit along its top edge and shaded along
/// its bottom, darker caps at both ends, a tan paper band round its middle with a green goblin face; its fuse, a dark
/// cord curling out of the right-hand cap, `fuse` (0…1) of it left. Gives back where the fuse's burning tip is.
private func dynamiteStick(_ c: PixelCanvas, x: Double, y: Double, angle: Double, len: Double, thick: Double,
                           fuse: Double, k: Double) -> (x: Double, y: Double) {
    let ca = cos(angle), sa = sin(angle)
    let half = len / 2, th = thick / 2
    let reach = Int(half + 2)
    let red = C(0xC82A22), redL = C(0xF05A4A), redD = C(0x8A1A16), cap = C(0x6A1410)
    let paper = C(0xD8C49A), paperD = C(0xB09A70), gob = C(0x4A8A2A), gobD = C(0x2A4A16)
    let band = len * 0.17
    for py in Int(y) - reach...Int(y) + reach {
        for px in Int(x) - reach...Int(x) + reach {
            let dx = Double(px) + 0.5 - x, dy = Double(py) + 0.5 - y
            let u = dx * ca + dy * sa, v = -dx * sa + dy * ca
            guard abs(u) <= half, abs(v) <= th else { continue }
            var col = red
            if abs(u) <= band {
                col = paper
                if v > th - 1.5 { col = paperD }
                // The goblin's face on the band: a green head with two dark eyes and a toothy grin.
                let fu = u / band, fv = v / th
                if abs(fu) < 0.62 && abs(fv) < 0.62 {
                    col = gob
                    if abs(fv + 0.2) < 0.2 && abs(abs(fu) - 0.28) < 0.15 { col = gobD }
                    if fv > 0.22 && fv < 0.48 && abs(fu) < 0.34 { col = Int(u.rounded()) % 2 == 0 ? paper : gobD }
                }
            } else if half - abs(u) < 1.6 {
                col = cap
            } else if v < -th + 1.6 {
                col = redL
            } else if v > th - 1.6 {
                col = redD
            }
            c.px(px, py, col)
        }
    }
    // The fuse: a curl of dark cord out of the end, shorter as it burns.
    let total = len * 0.42, left = total * fuse
    var tip = (x: x + half * ca, y: y + half * sa)
    var step = 0.0
    while step <= left {
        let fu = half + step * 0.8, fv = -sin(step * 0.45) * 2.4 - step * 0.35
        let wx = x + fu * ca - fv * sa, wy = y + fu * sa + fv * ca
        c.px(Int(wx), Int(wy), C(0x2A2420))
        tip = (wx, wy)
        step += 0.5
    }
    return tip
}

/// BOOM in the System's block letters at `s` pixels a dot, centred on `cx`, `cy`: yellow on top fading to orange
/// below, a dark red edge two pixels round, a deeper red drop under it; `crumble` (0…1) takes it away a dot at a time.
private func dynamiteBoom(_ c: PixelCanvas, cx: Int, cy: Int, s: Int, crumble: Double) {
    let text = "BOOM", tw = crawlTextWidth(text, scale: s), th = 5 * s
    let tmp = PixelCanvas(tw, th)
    crawlText(tmp, 0, 0, text, C(0xFFFFFF), scale: s)
    let x0 = cx - tw / 2, y0 = cy - th / 2
    let edge = max(2, s / 3)
    func on(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < tw && y < th && tmp.isDrawn(x, y) }
    func kept(_ x: Int, _ y: Int) -> Bool {
        crumble <= 0 || noise((y / max(1, s / 2)) * 977 + (x / max(1, s / 2)) * 13 + 5) >= crumble
    }
    // The drop and the edge first, then the face.
    for y in -edge..<(th + edge * 2) {
        for x in -edge..<(tw + edge) where kept(x, y) {
            if on(x, y - edge) && !on(x, y) { c.px(x0 + x, y0 + y, C(0x5A0A0A)) }
        }
    }
    for y in -edge..<(th + edge) {
        for x in -edge..<(tw + edge) where kept(x, y) && !on(x, y) {
            var near = false
            for dy in -edge...edge where !near { for dx in -edge...edge where on(x + dx, y + dy) { near = true; break } }
            if near { c.px(x0 + x, y0 + y, C(0x8A1410)) }
        }
    }
    for y in 0..<th {
        let col = y < th * 2 / 5 ? C(0xFFF07A) : y < th * 3 / 4 ? C(0xFFC030) : C(0xFF8020)
        for x in 0..<tw where on(x, y) && kept(x, y) {
            c.px(x0 + x, y0 + y, (y % s == 0 && y < th / 2) ? C(0xFFFFE0) : col)
        }
    }
}
