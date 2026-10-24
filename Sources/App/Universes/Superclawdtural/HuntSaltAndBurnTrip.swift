import CoreGraphics
import Foundation

// Salt and Burn (`HuntWipe.saltAndBurn`): how the boys put a ghost to rest. A handful of salt rains down over the old
// place, it catches, and flames rise from the bottom like a grave set alight, a scorched edge eating its way up and
// burning the old place away; behind it the new place shows through the smoke, which clears as the last embers go.

extension HuntTrip {
    /// A frame `k` (0…1) of Salt and Burn, over the whole of `r`. White grains of salt fall across the old place
    /// (0–0.2); fire catches along the bottom and climbs, a ragged line of burning edge with charred brown above it and
    /// tongues of pixel flame licking up off it, the old place glowing warmer as it comes (0.08–0.8); below the edge
    /// the old place is gone and the new one shows through rolling grey smoke lit orange from underneath, which thins
    /// and clears (0.5–1); embers drift up the whole way. Pixel art throughout: the flames and smoke are worked out
    /// pixel by pixel from a drifting value noise and stepped into flat tones.
    func drawSaltAndBurn(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        if k >= 1 { ctx.drawShot(new, in: r); return }
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let t = k * kind.duration
        let H = Double(h)
        let flameH = max(14, H * 0.22)
        let burn = Self.span(k, 0.08, 0.8)
        let climb = burn * burn * (2.2 - 1.2 * burn)   // catches slowly, then runs up
        let clear = Self.ease(Self.span(k, 0.62, 0.98))

        // The burning edge: a ragged line across the picture, starting out of sight below the bottom (flames and all)
        // and climbing past the top. Its raggedness drifts a little as it burns.
        let start = H + flameH * 1.4 + 4, end = -flameH * 1.4 - 6
        var front = [Double](repeating: 0, count: w)
        for x in 0..<w {
            let fx = Double(x)
            let rag = (saltValueNoise(fx / 22, t * 0.4, 3) - 0.5) * H * 0.22
                + (saltValueNoise(fx / 6, t * 1.5, 7) - 0.5) * 5
            front[x] = start + (end - start) * climb + rag * min(1, burn * 6)
        }

        // The old place, warming as the fire climbs, and the new one below the edge.
        ctx.drawShot(old, in: r)
        Self.wash(ctx, 0x5A1C06, 0.3 * Self.span(k, 0.1, 0.6), in: r)
        let hole = art.runs { x, y in Double(y) > front[x] }
        if !hole.isEmpty {
            ctx.saveGState()
            ctx.clip(to: hole)
            ctx.drawShot(new, in: r)
            ctx.restoreGState()
        }

        // The smoke where the fire has been: a dark veil over the new place, and round billows of smoke rising out
        // of the burnt ground, each a dark rim, a grey body and a lit crown, the young ones just under the edge lit
        // orange from below. They swell as they rise and older ones sit behind; towards the end the veil lifts and
        // the billows shrink away to nothing.
        let veilA = (0.45 * (1 - clear) * 4).rounded() / 4
        if veilA > 0 {
            for y in 0..<h {
                for x in 0..<w where Double(y) > front[x] + 2 { c.px(x, y, C(0x1A1616, veilA)) }
            }
        }
        let scale = H / 112
        var puffs: [(x: Int, y: Int, r: Int, age: Double)] = []
        for i in 0..<(w * h / 260) {
            let x0 = Int(noise(i * 11 + 1) * Double(w - 1))
            let y0 = noise(i * 11 + 2) * (H + 10)
            let age = (y0 - front[x0]) / H
            guard age > 0 else { continue }
            // A billow here and there goes early as the smoke clears; the rest shrink and thin out together.
            guard clear < 0.35 + noise(i * 11 + 5) * 1.2 else { continue }
            let rad = (3 + min(1.2, age) * 7 + noise(i * 11 + 3) * 4) * scale * (1 - clear * 0.5)
            let y = y0 - min(1.2, age) * H * 0.35 - clear * H * 0.25
            let x = Double(x0) + sin(age * 5 + Double(i)) * 3 * scale
            puffs.append((Int(x), Int(y), Int(rad), age))
        }
        puffs.sort { $0.age > $1.age }
        let rim = C(0x221C1C), body = C(0x4A4240), crown = C(0x726660), shine = C(0x968A80)
        let emberRim = C(0x4A1C0C), emberBody = C(0x8A3E1A), emberCrown = C(0xC8682A)
        // In layers, so the billows run together into one cloud: every rim, then every body, then the light. On a
        // canvas of their own, so the whole cloud thins at once in flat steps at the end rather than ball by ball.
        let sc = PixelCanvas(w, h)
        let fadeA = ((1 - Self.span(clear, 0.3, 1)) * 4).rounded() / 4
        for p in puffs { sc.circle(p.x, p.y, p.r + 1, p.age * H < flameH * 0.9 ? emberRim : rim) }
        for p in puffs {
            let young = p.age * H < flameH * 0.9
            sc.circle(p.x, p.y, p.r, young ? emberBody : body)
            if young { sc.circle(p.x, p.y + p.r / 3, max(1, p.r / 2), emberCrown) }
        }
        for p in puffs where p.age * H >= flameH * 0.9 {
            sc.circle(p.x - p.r / 4, p.y - p.r / 3, max(1, p.r * 3 / 5), crown)
            if p.r >= 5 { sc.circle(p.x - p.r / 3, p.y - p.r / 2, max(1, p.r / 4), shine) }
        }
        if fadeA > 0 { c.paste(sc, alpha: fadeA) }

        // The edge itself: a burning line, then charred black-brown, then the old place browned above it.
        let ember = C(0xFFC04A), hotRed = C(0xE0501A), char = C(0x24120A), brown = C(0x5A2A12)
        for x in 0..<w {
            let e = Int(front[x].rounded(.down))
            guard e > -2, e < h + 12 else { continue }
            let charW = 2 + Int(saltValueNoise(Double(x) / 3, 5, 41) * 3)
            c.px(x, e, ember)
            c.px(x, e - 1, hotRed)
            c.rect(x, e - 1 - charW, 1, charW, char)
            c.rect(x, e - 5 - charW, 1, 4, brown.alpha(0.5))
        }

        // The flames: tongues licking up off the edge, each column's height flickering, broken up by noise that
        // scrolls upwards so bits tear off and rise, in four flat tones from deep red at the tips to yellow-white.
        let tones = [C(0xA81E0C), C(0xEC5A16), C(0xFFA82A), C(0xFFF0A8)]
        let alive = min(1, burn * 8) * (1 - Self.span(k, 0.78, 0.86))
        if alive > 0 {
            for x in 0..<w {
                let fx = Double(x)
                let tall = flameH * alive * (0.45 + 0.75 * saltValueNoise(fx / 5, t * 7, 53))
                let top = max(0, Int(front[x] - tall * 1.4)), bottom = min(h - 1, Int(front[x]))
                guard top <= bottom else { continue }
                for y in top...bottom {
                    let up = (front[x] - Double(y)) / tall
                    let n = saltValueNoise(fx / 3.2, Double(y) / 3 + t * 16, 61)
                    let f = 1 - up - (n - 0.5) * 0.9
                    guard f > 0 else { continue }
                    c.px(x, y, tones[min(3, Int(f * 4.6))])
                }
            }
        }

        // Embers: sparks rising off the fire, wavering, yellow going to orange to a dull red as they cool.
        for i in 0..<60 {
            let born = 0.06 + noise(i * 7 + 1) * 0.8, life = 0.2 + noise(i * 7 + 2) * 0.15
            let age = (k - born) / life
            guard age > 0, age < 1 else { continue }
            let x0 = Int(noise(i * 7 + 3) * Double(w - 1))
            let y = Int(min(H, front[x0]) - age * H * (0.45 + noise(i * 7 + 4) * 0.4))
            let x = x0 + Int(sin(age * 9 + Double(i)) * 3)
            let col = age < 0.35 ? C(0xFFE07A) : age < 0.7 ? C(0xFF8A24) : C(0xB8361A)
            c.px(x, y, col)
            if i % 4 == 0 { c.px(x, y + 1, col.alpha(0.6)) }
        }

        // The salt: grains thrown from above, falling fast across the old place before it catches.
        if k < 0.24 {
            for i in 0..<70 {
                let fall = (k - noise(i * 5 + 1) * 0.06) / 0.16
                guard fall > 0, fall < 1 else { continue }
                let x = Int(Double(w) * (0.15 + noise(i * 5 + 2) * 0.7) + fall * Double(w) * 0.04 * (noise(i * 5 + 3) - 0.5))
                let y = Int(-4 + fall * (H + 8) * (0.7 + noise(i * 5 + 4) * 0.3))
                c.px(x, y, i % 3 == 0 ? C(0xC8CCD0) : C(0xFFFFFF))
                if i % 5 == 0 { c.px(x, y - 1, C(0xFFFFFF, 0.5)) }
            }
        }
        art.show(ctx)
    }
}

/// Smooth value noise in 0…1: random values on a unit grid, eased between (for the flames and the smoke).
private func saltValueNoise(_ x: Double, _ y: Double, _ seed: Int) -> Double {
    let x0 = floor(x), y0 = floor(y)
    let fx = x - x0, fy = y - y0
    let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
    func at(_ i: Double, _ j: Double) -> Double { noise((Int(i) &* 7919 &+ Int(j) &* 104_729 &+ seed &* 31) & 0xFFFFF) }
    let a = at(x0, y0), b = at(x0 + 1, y0), c = at(x0, y0 + 1), d = at(x0 + 1, y0 + 1)
    return (a + (b - a) * ux) * (1 - uy) + (c + (d - c) * ux) * uy
}
