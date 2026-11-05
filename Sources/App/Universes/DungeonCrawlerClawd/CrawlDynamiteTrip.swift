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
    /// white flash, a chunky fireball of billows, big and small, bursting out from the stick, white at its heart, then
    /// yellow, orange and red as each cools to grey smoke, bits of stick and paper flying, the screen shaking, and BOOM
    /// in big block letters, yellow over orange with a dark red edge (0.6–0.8); the place behind the smoke is the new
    /// one from 0.74, once it covers everything. Then the cloud opens up in big holes that spread and join, the top-left
    /// corner first so the System box has a clear corner (0.76–0.95), and each letter breaks in two, the pieces dropping
    /// away one after another (0.8–0.93).
    func drawDynamite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.95 else { ctx.drawShot(new, in: r); return }
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

        // BOOM. The fireball and the smoke after it: the body of the cloud spreading out from the stick, and over it
        // billows of very different sizes, scattered in a spiral rather than a grid, each bursting out as the front
        // reaches it and cooling through the fire's colours to grey.
        let far = max(1, hypot(max(restX, Double(w) - restX), max(restY, Double(h) - restY)))
        let fire: [Px] = [C(0xFFFFFF), C(0xFFF0A0), C(0xFFC838), C(0xFF8A20), C(0xE04A1C), C(0x9A2A1C)]
        let smoke: [Px] = [C(0x5E585E), C(0x847E86), C(0xA8A2AA), C(0xCCC6CC)]
        let shake = k < 0.72 ? Int((1 - Self.span(k, bang, 0.72)) * 3 + 0.5) : 0
        let sx = shake > 0 ? Int((noise(frame * 3) - 0.5) * Double(shake * 2 + 1)) : 0
        let sy = shake > 0 ? Int((noise(frame * 3 + 1) - 0.5) * Double(shake * 2 + 1)) : 0
        let cool = 0.07                                               // how long a billow stays fire
        let cloud = PixelCanvas(w, h)
        for y in 0..<h {
            for x in 0..<w {
                let fx = Double(x - sx) + 0.5, fy = Double(y - sy) + 0.5
                // The front's ragged edge; once it has passed everywhere the edge no longer matters.
                let ragged = k < 0.69 ? 0.02 * (dynamiteField(x, y, seed: 9) - 0.5) : 0
                let born = bang + 0.07 * hypot(fx - restX, fy - restY) / far + ragged
                let age = k - born
                guard age > 0 else { continue }
                cloud.px(x, y, age < cool ? fire[min(fire.count - 1, 1 + Int(age / cool * 5))] : smoke[1])
            }
        }
        // The billows, the farthest first so the ones nearer the blast sit over them.
        let base = Double(h) * 0.17
        let count = Int(.pi * far * far / (base * base * 1.3))
        let rise = Self.span(k, bang, 1)
        for i in stride(from: count - 1, through: 0, by: -1) {
            let dist = (Double(i) + 0.5).squareRoot() / Double(count).squareRoot() * far * 1.06
            let turn = Double(i) * 2.39996 + (noise(i * 7 + 3) - 0.5) * 1.4
            let x0 = restX + cos(turn) * dist * (0.92 + 0.16 * noise(i * 7 + 4))
            let y0 = restY + sin(turn) * dist * (0.92 + 0.16 * noise(i * 7 + 5))
            let size = noise(i * 7 + 6)
            let full = base * (0.45 + 1.15 * size * size)
            guard x0 > -full * 1.2, y0 > -full * 1.2, x0 < Double(w) + full * 1.2, y0 < Double(h) + full * 1.2 else { continue }
            let born = bang + 0.07 * dist / far
            let grow = 1 - pow(1 - Self.span(k, born, born + 0.05), 2)
            guard grow > 0 else { continue }
            let rad = full * grow
            // Drifting a little out from the blast and up as it clears.
            let out = rise * base * 0.5, ux = cos(turn)
            let px = x0 + ux * out + Double(sx), py = y0 - out * 0.8 + Double(sy)
            let age = k - born
            let tones: (rim: Px, face: Px, top: Px)
            if age < cool {
                let n = Int(age / cool * 4)
                tones = (fire[min(5, n + 2)], fire[min(5, n + 1)], fire[n])
            } else {
                tones = (smoke[0], smoke[2], smoke[3])
            }
            // Lit from the top left: a shaded rim, a face set up and left inside it, a bright cap on the bigger ones.
            cloud.circle(Int(px), Int(py), Int(rad.rounded()), tones.rim)
            cloud.circle(Int(px - rad * 0.1), Int(py - rad * 0.12), Int((rad * 0.86).rounded()), tones.face)
            if size > 0.35 {
                cloud.circle(Int(px - rad * 0.28), Int(py - rad * 0.32), Int((rad * 0.48).rounded()), tones.top)
            }
        }
        // Clearing: holes open where the slow field is lowest and spread until they join, the top left first, so what's
        // left is always a few big banks of smoke, never specks; a thin soft lip along each edge.
        let clearing = Self.span(k, 0.76, 0.95) * 1.04
        if clearing > 0 {
            for y in 0..<h {
                for x in 0..<w where cloud.isDrawn(x, y) {
                    let left = 1 - min(1, Double(x) / Double(w) * 0.9 + Double(y) / Double(h) * 0.6)
                    let v = dynamiteField(x, y + Int(rise * base), seed: 2) * 0.55 + (1 - left) * 0.45
                    guard v > clearing else { continue }
                    let col = unpremultiplied(cloud, (y * w + x) * 4)
                    c.px(x, y, v - clearing < 0.025 ? col.alpha(0.5) : col)
                }
            }
        } else {
            c.paste(cloud)
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
        let crumble = Self.span(k, 0.8, 0.93)
        if pop > 0 && crumble < 1 {
            let full = max(2, min((w * 3 / 5) / 15, (h * 2 / 5) / 5))
            let s = max(1, Int((Double(full) * (pop < 1 ? 0.6 + 0.55 * pop : 1)).rounded()))
            dynamiteBoom(c, cx: Int(restX * 0.4 + Double(w) * 0.3) + sx, cy: h * 2 / 5 + sy, s: s, crumble: crumble, drop: h)
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

/// The smoke's slow field at (`x`, `y`), 0…1: soft value noise in two sizes, the large one leading, so it rises and
/// falls in big smooth banks.
private func dynamiteField(_ x: Int, _ y: Int, seed: Int) -> Double {
    func layer(_ cell: Double, _ salt: Int) -> Double {
        let fx = Double(x) / cell, fy = Double(y) / cell
        let ix = Int(floor(fx)), iy = Int(floor(fy))
        let tx = fx - floor(fx), ty = fy - floor(fy)
        let sx = tx * tx * (3 - 2 * tx), sy = ty * ty * (3 - 2 * ty)
        func at(_ a: Int, _ b: Int) -> Double { noise((a + 40) * 157 + (b + 40) * 311 + salt) }
        let top = at(ix, iy) + (at(ix + 1, iy) - at(ix, iy)) * sx
        let bottom = at(ix, iy + 1) + (at(ix + 1, iy + 1) - at(ix, iy + 1)) * sx
        return top + (bottom - top) * sy
    }
    let v = layer(44, seed * 977) * 0.75 + layer(20, seed * 977 + 501) * 0.25
    return max(0, min(1, (v - 0.15) / 0.7))
}

/// BOOM in the System's block letters at `s` pixels a dot, centred on `cx`, `cy`: yellow on top fading to orange
/// below, a dark red edge round it, a deeper red drop under it. It's built from the letters' own dots, so when `crumble`
/// (0…1) comes each letter breaks cleanly in two, across its middle: the pieces go one after another, bottoms before
/// tops, each falling whole up to `drop` pixels and thinning out at the end.
private func dynamiteBoom(_ c: PixelCanvas, cx: Int, cy: Int, s: Int, crumble: Double, drop: Int) {
    let text = "BOOM", tw = crawlTextWidth(text, scale: s), th = 5 * s
    let tmp = PixelCanvas(tw, th)
    crawlText(tmp, 0, 0, text, C(0xFFFFFF), scale: s)
    let x0 = cx - tw / 2, y0 = cy - th / 2
    let edge = max(2, s / 3)
    var blocks: [(x: Int, y: Int, row: Int, alpha: Double)] = []
    // Which letter each column of dots belongs to: a new one after every empty column.
    var letterOf: [Int] = [], letter = 0, gapBefore = false
    for gx in 0..<(tw / s) {
        let empty = !(0..<5).contains { tmp.isDrawn(gx * s + s / 2, $0 * s + s / 2) }
        if !empty && gapBefore { letter += 1 }
        gapBefore = empty
        letterOf.append(letter)
    }
    for gy in 0..<5 {
        for gx in 0..<(tw / s) where tmp.isDrawn(gx * s + s / 2, gy * s + s / 2) {
            let top = gy < 2
            let start = noise(letterOf[gx] * 13 + (top ? 7 : 0) + 5) * 0.3 + (top ? 0.25 : 0)
            let f = max(0, min(1, (crumble - start) / 0.42))
            let alpha = ((1 - max(0, f - 0.7) / 0.3) * 4).rounded(.up) / 4
            guard alpha > 0 else { continue }
            blocks.append((x0 + gx * s, y0 + gy * s + Int(f * f * Double(drop) * 0.55), gy, alpha))
        }
    }
    // The drop and the edge first, under all the blocks, then the faces.
    for b in blocks { c.rect(b.x, b.y + edge, s, s + edge, C(0x5A0A0A, b.alpha)) }
    for b in blocks { c.rect(b.x - edge, b.y - edge, s + 2 * edge, s + 2 * edge, C(0x8A1410, b.alpha)) }
    for b in blocks {
        let col = b.row < 2 ? C(0xFFF07A) : b.row < 4 ? C(0xFFC030) : C(0xFF8020)
        c.rect(b.x, b.y, s, s, col.alpha(b.alpha))
        if b.row < 2 { c.rect(b.x, b.y, s, 1, C(0xFFFFE0, b.alpha)) }
    }
}
