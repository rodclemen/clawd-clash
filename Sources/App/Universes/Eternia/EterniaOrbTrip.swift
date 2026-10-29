import CoreGraphics
import Foundation

// The Crystal Orb (`EterniaWipe.orb`): the scene shrinks into Evil-Lynn's crystal orb, teal glass in the gold cradle
// on top of her staff, out in the dark. Mist swirls up inside it until the old place is gone, the new place forms in
// it as the mist clears, and the orb grows until it fills the screen.

extension EterniaTrip {
    /// The Crystal Orb, `k` (0…1) through its own part, over the whole of `r`. The scene shrinks into the orb, a ring
    /// of glass closing in on it from the corners and the picture shrinking inside, until it sits in the gold cradle
    /// on her staff against the dark, sparkles circling it (0–0.3); teal and deep blue mist swirls up inside in three
    /// arms until it fills the orb (0.28–0.5); the mist clears onto the new place (0.52–0.72); and the orb grows,
    /// the cradle sinking off the bottom, until the new place fills the screen (0.72–1). The orb, mist, cradle and
    /// sparkles are pixel art; the places are drawn as they are, scaled.
    func drawOrb(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        // On the window's short strip the orb fills more of the height, so it reads there.
        let cx = Double(w) / 2, cy = (Double(h) * (art.wide ? 0.45 : 0.44)).rounded()
        let reachX = max(cx, Double(w) - cx), reachY = max(cy, Double(h) - cy)
        let full = (reachX * reachX + reachY * reachY).squareRoot() + 2
        let small = (Double(h) * (art.wide ? 0.41 : 0.34)).rounded()
        let shrink = Self.ease(Self.span(k, 0, 0.3)), grow = Self.span(k, 0.72, 1)
        let growE = grow * grow * (3 - 2 * grow)
        let rad = shrink < 1 ? full + (small - full) * shrink : small + (full - small) * growE
        let f = min(1, rad / min(cx, 1.6 * cy))
        let place = k < 0.5 ? old : new

        // The dark she gazes from, and the place inside the glass, shrunk about the orb's middle.
        Self.wash(ctx, 0x1C1030, 1, in: r)
        let inside = art.runs { x, y in
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            return dx * dx + dy * dy < rad * rad
        }
        let ox = r.minX + CGFloat(cx) * art.px, oy = r.maxY - CGFloat(cy) * art.px
        let mid = CGPoint(x: r.midX + (ox - r.midX) * CGFloat(1 - f), y: r.midY + (oy - r.midY) * CGFloat(1 - f))
        let pw = r.width * CGFloat(f), ph = r.height * CGFloat(f)
        if !inside.isEmpty {
            ctx.saveGState()
            ctx.clip(to: inside)
            ctx.setFillColor(eterniaTripRGB(0x2A8A9E)); ctx.fill(r)
            ctx.drawShot(place, in: CGRect(x: mid.x - pw / 2, y: mid.y - ph / 2, width: pw, height: ph))
            ctx.restoreGState()
        }

        // The mist, swirling in three arms; `m` of each turn of the arms is covered (all of it at 1).
        let m = Self.span(k, 0.28, 0.5) * (1 - Self.span(k, 0.52, 0.72))
        let spin = k * 3.2
        let teal = C(0x7AF0E0), mid1 = C(0x4AB4C8), deep = C(0x2A4AC8), deepD = C(0x1E2E8A)
        if m > 0 {
            let x0 = max(0, Int(cx - rad)), x1 = min(w - 1, Int(cx + rad))
            let y0 = max(0, Int(cy - rad)), y1 = min(h - 1, Int(cy + rad))
            if x0 <= x1 && y0 <= y1 {
                for y in y0...y1 {
                    for x in x0...x1 {
                        let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                        let d = (dx * dx + dy * dy).squareRoot()
                        guard d < rad else { continue }
                        let turn: Double = atan2(dy, dx) / (2 * .pi) * 3
                        let curl: Double = d / rad * 1.4 - spin
                        let v = (turn + curl).truncatingRemainder(dividingBy: 1)
                        let arm = abs((v < 0 ? v + 1 : v) - 0.5) * 2
                        guard arm < m * 1.05 else { continue }
                        let band = arm / max(0.05, m)
                        c.px(x, y, band < 0.3 ? teal : band < 0.55 ? mid1 : band < 0.8 ? deep : deepD)
                    }
                }
            }
        }

        // The glass: a bold dark outline, a band of teal rim inside it lit on the top left, a darker line inside that,
        // the shine curving round its top left with a bright spot, and a glint low on the right.
        let rimR = rad
        let edge = C(0x0E2430), glass = C(0x1E6A7E), rimC = C(0x3AA8BC), rimL = C(0x9AF0F0)
        let shine = C(0xE8FFFC), shineD = C(0xA8F0F0)
        let ry0 = max(0, Int(cy - rimR - 2)), ry1 = min(h - 1, Int(cy + rimR + 2))
        let rx0 = max(0, Int(cx - rimR - 2)), rx1 = min(w - 1, Int(cx + rimR + 2))
        let thick = max(2.0, (rad / 18).rounded())
        let line = rad - 1.5, band = line - thick, arc = rad * 0.74
        if rx0 <= rx1 && ry0 <= ry1 && rad < full {
            for y in ry0...ry1 {
                for x in rx0...rx1 {
                    let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                    let d = (dx * dx + dy * dy).squareRoot()
                    let a = atan2(dy, dx)
                    if d >= line && d < rad + 1 { c.px(x, y, edge) }
                    else if d >= band && d < line { c.px(x, y, a > -2.7 && a < -1.2 ? rimL : rimC) }
                    else if d >= band - 1 && d < band { c.px(x, y, glass) }
                    else if d >= arc && d < arc + thick {
                        if a > -2.65 && a < -1.75 { c.px(x, y, shine) } else if a >= -1.75 && a < -1.45 { c.px(x, y, shineD) }
                    } else if d >= arc && d < arc + 1 && a > 0.45 && a < 1.05 { c.px(x, y, shineD) }
                }
            }
            // A bright spot of shine, and a smaller one beside it.
            let sx = Int(cx - rad * 0.42), sy = Int(cy - rad * 0.48), sp = Int(thick) + 1
            c.rect(sx, sy, sp, sp, shine)
            c.rect(sx + sp + 1, sy - sp / 2 - 1, max(1, sp / 2), max(1, sp / 2), shine)
        }

        // The gold cradle round its lower half, three prongs up its sides, a collar and her dark staff below.
        if rad < full {
            let gold = C(0xE0B040), goldL = C(0xFFE08A), goldD = C(0x9A7020), ink = C(0x2A1A10)
            let band = max(2.0, (rad * 0.12).rounded())
            let by0 = Int(cy), by1 = min(h - 1, Int(cy + rad + band + 1))
            let bx0 = max(0, Int(cx - rad - band - 1)), bx1 = min(w - 1, Int(cx + rad + band + 1))
            if by0 <= by1 && bx0 <= bx1 {
                for y in by0...by1 {
                    for x in bx0...bx1 {
                        let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
                        let d = (dx * dx + dy * dy).squareRoot()
                        let a = atan2(dy, dx)   // 0 to the right, pi/2 straight down
                        let lower = a > 0.35 && a < .pi - 0.35
                        guard lower && d >= rad + 1 && d < rad + 1 + band else { continue }
                        let outer = d >= rad + band
                        c.px(x, y, outer ? ink : a > .pi / 2 + 0.6 ? goldL : a < 0.9 ? goldD : gold)
                    }
                }
            }
            // The prongs, curling up the sides of the glass.
            for side in [-1.0, 1.0] {
                for i in 0..<Int(band * 2.4) {
                    let a = 0.35 - Double(i) * 0.6 / (band * 2.4)
                    let px0 = cx + side * cos(a) * (rad + band * 0.5), py0 = cy + sin(a) * (rad + band * 0.5)
                    let wd = max(1, Int(band) - i / 3)
                    c.rect(Int(px0.rounded()) - wd / 2, Int(py0.rounded()), wd, max(1, wd), side < 0 ? goldL : gold)
                }
            }
            // The collar and the staff.
            let colTop = Int(cy + rad + band)
            let colW = Int(rad * 0.5), shaftW = max(3, Int(rad * 0.16))
            c.rect(Int(cx) - colW / 2, colTop, colW, Int(band), gold)
            c.rect(Int(cx) - colW / 2, colTop, colW, 1, goldL)
            c.rect(Int(cx) - colW / 2, colTop + Int(band) - 1, colW, 1, goldD)
            c.rect(Int(cx) - shaftW / 2, colTop + Int(band), shaftW, h, C(0x3A2A5A))
            c.rect(Int(cx) - shaftW / 2, colTop + Int(band), max(1, shaftW / 3), h, C(0x5E4A8E))
        }

        // Sparkles circling it while it is small.
        let twinkle = Self.span(k, 0.18, 0.3) * (1 - Self.span(k, 0.72, 0.8))
        if twinkle > 0 {
            for i in 0..<7 {
                let a = k * 5.5 + Double(i) * 0.8976
                let d = rad + 6 + 4 * noise(i * 9 + 300)
                let x = Int((cx + cos(a) * d * 1.25).rounded()), y = Int((cy + sin(a) * d * 0.85).rounded())
                let on = noise(Int(k * 40) * 7 + i) > 0.25
                guard on else { continue }
                let col = i % 2 == 0 ? C(0xD8FFF8) : C(0x7AF0E0)
                c.px(x, y, col)
                if i % 3 == 0 { c.px(x - 1, y, col); c.px(x + 1, y, col); c.px(x, y - 1, col); c.px(x, y + 1, col) }
            }
        }
        art.show(ctx)
    }
}
