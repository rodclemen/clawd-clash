import CoreGraphics
import Foundation

// The Iron Tangle (`CrawlWipe.ironTangle`), likelier with Gore-Gore, Li Jun, Li Na or Zhang and going to Iron
// Tangle station: a train screams across the screen, carrying the old scene away with it, and leaves the new one behind.

extension CrawlTrip {
    /// The Iron Tangle, `k` (0…1) through its own part, over the whole of `r`. The station's own train (the silver
    /// cars with the red stripe and the warm lit windows, Scenes.crawlTangleCar), right up close so a car fills the
    /// frame from top to bottom. The old place rumbles and a headlight glares in from the right (0–0.06); the train's
    /// sloped nose bursts in, its headlight blazing, and the old place is shoved off to the left in front of it,
    /// pinned to the cab (0.06–0.3); the cars scream past, passengers in the windows, the wheels throwing sparks off
    /// the rails, speed lines streaking along the sides (to 0.78); the last car's red tail lamps go by and the new
    /// place is there behind it, a wake of wind lines trailing off after the train (0.6–0.9).
    func drawIronTangle(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.92 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let frame = Int(k * CrawlWipe.ironTangle.effect * 30)
        let hh = Double(h)

        // The train: a sloped cab and its cars, `cw` each with a dark gap between, as long as it needs to be to
        // fill the frame for a moment.
        let cw = Int(hh * 1.5), gap = 4, nose = Int(hh * 0.36)
        let cars = max(2, Int((Double(w) / Double(cw + gap)).rounded(.up)))
        let length = nose + cars * (cw + gap) - gap
        let run = Self.span(k, 0.06, 0.8)
        let head = Int((Double(w + 2) - Double(w + 2 + length) * run).rounded())    // the nose's tip
        let tail = head + length
        func noseEdge(_ y: Int) -> Int {
            let yn = (Double(y) + 0.5) / hh
            return head + Int((Double(nose) * pow(max(0, 0.52 - yn) / 0.52, 1.5)).rounded())
        }
        let jolt = frame % 3 == 0 ? 1 : 0                              // the cars rocking on the rails

        // The old place in front of the train: rumbling as it nears, then shoved along ahead of the cab.
        let push = min(0, head + nose - w)
        let rumble = k < 0.1 && frame % 2 == 0 ? 1 : 0
        let ahead = art.runs { x, y in x < noseEdge(y) }
        if !ahead.isEmpty {
            ctx.saveGState(); ctx.clip(to: ahead)
            ctx.drawShot(old, in: r.offsetBy(dx: CGFloat(push) * art.px, dy: CGFloat(rumble) * art.px))
            ctx.restoreGState()
        }
        // The new place behind it.
        if tail < w {
            let behind = art.runs { x, _ in x >= tail }
            ctx.saveGState(); ctx.clip(to: behind); ctx.drawShot(new, in: r); ctx.restoreGState()
        }

        // The headlight's glare, coming in from the right before the train, then out in front of the nose.
        let glare = Self.span(k, 0, 0.06)
        let lampY = Int(hh * 0.72)
        if head > w - 2 {
            let reach = Int(Double(w) * 0.25 * glare)
            for (i, a) in [0.12, 0.22, 0.4].enumerated() {
                let rr = max(1, reach - i * reach / 3)
                c.ellipse(w, lampY, rr, max(1, rr / 3), C(0xFFF4C0, a * glare))
            }
        } else if head > 0 {
            let len = Int(hh * 0.9)
            for (i, a) in [0.1, 0.18].enumerated() {
                c.ellipse(head - len / 2 + i * len / 6, lampY, len / 2 - i * len / 6, Int(hh * 0.07) - i * 2, C(0xFFF0B0, a))
            }
        }

        // The cars, from the back of the cab.
        for i in 0..<cars {
            let x = head + nose + i * (cw + gap)
            if x > w || x + cw + gap < 0 { continue }
            tangleCar(c, x: x, w: cw, h: h, jolt: jolt, seed: i, frame: frame)
            // The gap and the bellows between this car and the one before.
            c.rect(x - gap, 0, gap, h, C(0x141618))
            for y in stride(from: Int(hh * 0.12), to: Int(hh * 0.82), by: 3) { c.rect(x - gap + 1, y, gap - 2, 1, C(0x2E3238)) }
        }
        // The tail: the last car's end, red lamps lit.
        if tail > 0 && tail - 4 < w {
            c.rect(tail - 4, Int(hh * 0.1) + jolt, 4, Int(hh * 0.74), C(0x60646E))
            for ly in [Int(hh * 0.18), Int(hh * 0.66)] {
                c.rect(tail - 5, ly + jolt, 3, 4, C(0xFF3A2A)); c.px(tail - 5, ly + jolt, C(0xFFB0A0))
                c.ellipse(tail + 2, ly + 2 + jolt, 6, 3, C(0xFF3A2A, 0.22))
            }
        }
        // The cab.
        if head < w && head + nose + 2 > 0 { tangleCab(c, head: head, nose: nose, h: h, jolt: jolt, edge: noseEdge) }

        // Speed lines streaking along the sides, and the wake trailing off behind the last car.
        if tail > 0 {
            for i in 0..<8 {
                let y = Int(hh * (0.1 + 0.08 * Double(i))) + Int(noise(i * 7 + frame) * 3)
                let x = head + nose + Int(noise(i * 11 + frame * 3) * Double(max(1, length - nose)))
                let l = 6 + Int(noise(i * 13 + frame) * hh * 0.3)
                c.rect(max(head + nose, x), y, min(l, max(0, tail - 6 - x)), 1, C(0xF0F4FA, 0.45))
            }
        }
        let wake = 1 - Self.span(k, 0.6, 0.9)
        if wake > 0 && tail < w + 30 {
            for i in 0..<6 {
                let y = Int(hh * (0.4 + 0.08 * Double(i)))
                let x = tail + 4 + Int(noise(i * 5 + 300) * 20) + Int((1 - wake) * hh * 0.4)
                let l = Int((20 + noise(i * 5 + 301) * hh * 0.6) * wake)
                c.rect(x, y, l, 1, C(0xE8EEF4, 0.55 * wake))
                c.rect(x + l / 3, y + 1, l / 3, 1, C(0xE8EEF4, 0.3 * wake))
            }
        }
        art.show(ctx)
    }
}

/// One car of the train, `w` wide from `x` and the frame's full `h` tall: a dark roof with its lit edge, the silver
/// body lit along the top, four warm windows with passengers (Clawds, mostly) and a pair of doors, the red stripe,
/// fluted steel under it with IRON TANGLE and the car's number on dark plates, a shaded skirt with its vents, and the
/// bogies with their wheels spinning on the rail, throwing sparks.
private func tangleCar(_ c: PixelCanvas, x: Int, w: Int, h: Int, jolt: Int, seed: Int, frame: Int) {
    let hh = Double(h)
    func y(_ f: Double) -> Int { Int((hh * f).rounded()) + jolt }
    let body = C(0x8A8E98), bodyL = C(0xB0B4BE), bodyD = C(0x60646E)
    // Under it all, the dark of the underframe, so nothing shows through between the wheels.
    c.rect(x, 0, w, h, C(0x1A1A1E))
    c.rect(x, 0, w, y(0.1), C(0x5A5E66)); c.rect(x, y(0.06), w, 1, C(0x7A7E86))
    c.rect(x, y(0.1), w, y(0.84) - y(0.1), body)
    c.rect(x, y(0.1), w, 2, bodyL); c.rect(x, y(0.8), w, y(0.84) - y(0.8), bodyD)
    c.rect(x, y(0.1), 2, y(0.84) - y(0.1), bodyD); c.rect(x + w - 2, y(0.1), 2, y(0.84) - y(0.1), bodyL)
    // The windows, warm, a passenger standing in most: Clawd, whole, on his four legs, now and then a goblin.
    let wins = [0.05, 0.23, 0.62, 0.8]
    let ww = Int(Double(w) * 0.15)
    for (k, f) in wins.enumerated() {
        let wx = x + Int(Double(w) * f), wy = y(0.2), wh = y(0.5) - y(0.2)
        c.rect(wx - 1, wy - 1, ww + 2, wh + 2, C(0x3A3E46))
        c.rect(wx, wy, ww, wh, C(0xE8D898)); c.rect(wx, wy, ww, 2, C(0xB8A868))
        let n = noise(seed * 31 + k * 7 + 50)
        if n > 0.25 {
            tanglePassenger(c, x: wx, w: ww, floor: wy + wh, goblin: n > 0.88, armUp: noise(seed * 31 + k * 7 + 51) > 0.5)
        }
    }
    // The doors in the middle.
    let dx = x + Int(Double(w) * 0.42), dw = Int(Double(w) * 0.16)
    c.rect(dx, y(0.15), dw, y(0.82) - y(0.15), C(0x6A6E78))
    c.rect(dx + dw / 2, y(0.15), 1, y(0.82) - y(0.15), C(0x3A3E46))
    for side in [dx + 2, dx + dw / 2 + 2] {
        c.rect(side, y(0.22), dw / 2 - 4, y(0.44) - y(0.22), C(0xD8C888))
    }
    // The red stripe along the side, the network's name under it, and the seams between the body's panels.
    c.rect(x, y(0.58), w, y(0.65) - y(0.58), C(0xB03428)); c.rect(x, y(0.58), w, 1, C(0xD04A3A))
    // The steel under it, fluted: broad ribs along the car, each lit on top and shaded under, stopping at the doors.
    let rib = max(4, h / 26)
    for ry in stride(from: y(0.65), to: y(0.8), by: rib) {
        let rh = min(rib, y(0.8) - ry)
        for (from, to) in [(x, dx), (dx + dw, x + w)] {
            c.rect(from, ry, to - from, 1, bodyL)
            c.rect(from, ry + rh - 1, to - from, 1, bodyD)
        }
    }
    for f in [0.6, 0.98] { c.rect(x + Int(Double(w) * f), y(0.65), 1, y(0.8) - y(0.65), bodyD) }
    // The network's name and the car's number, pale on dark plates.
    let s = hh >= 140 ? 2 : 1, label = "IRON TANGLE", number = "\(seed + 1)0\(seed + 3)"
    let py = (y(0.65) + y(0.8) - 5 * s) / 2
    let lx = x + (Int(Double(w) * 0.42) - crawlTextWidth(label, scale: s)) / 2, nx = x + Int(Double(w) * 0.8)
    for (px, text) in [(lx, label), (nx, number)] {
        let tw = crawlTextWidth(text, scale: s)
        c.rect(px - 3, py - 2, tw + 6, 5 * s + 4, C(0x2A2E36)); c.rect(px - 3, py - 2, tw + 6, 1, C(0x4A4E58))
        crawlText(c, px, py, text, C(0xE8ECF2), scale: s)
    }
    // The skirt: a row of dark vents along it.
    let vent = max(8, h / 12)
    for vx in stride(from: x + vent / 2, to: x + w - vent, by: vent * 2) where vx + vent < dx || vx > dx + dw {
        c.rect(vx, y(0.81), vent, max(2, y(0.83) - y(0.81)), C(0x34363E))
    }
    // The bogies and the wheels, spokes turning, sparks off the rail.
    c.rect(x, y(0.84), w, 2, C(0x2A2A30))
    let rad = max(3, Int(hh * 0.065))
    for f in [0.1, 0.24, 0.76, 0.9] {
        let cx = x + Int(Double(w) * f), cy = h - rad - 1
        c.circle(cx, cy, rad, C(0x2A2A30)); c.circle(cx, cy, rad - 1, C(0x40424A))
        let a = Double(frame) * 1.3 + f * 9
        for s in 0..<2 {
            let aa = a + Double(s) * .pi / 2
            c.rect(cx + Int((cos(aa) * Double(rad - 1)).rounded()), cy + Int((sin(aa) * Double(rad - 1)).rounded()), 1, 1, C(0x8A8E96))
            c.rect(cx - Int((cos(aa) * Double(rad - 1)).rounded()), cy - Int((sin(aa) * Double(rad - 1)).rounded()), 1, 1, C(0x8A8E96))
        }
        c.rect(cx - 1, cy - 1, 2, 2, C(0x9A9EA6))
        if noise(frame * 7 + Int(f * 100) + seed * 3) > 0.45 {
            for j in 0..<4 {
                let sx = cx + rad - 1 + j * 2 + Int(noise(frame + j * 3 + seed) * 3), sy = h - 1 - Int(noise(frame * 2 + j) * 3)
                c.px(sx, sy, j % 2 == 0 ? C(0xFFF4A0) : C(0xFF9A30))
            }
        }
    }
    c.rect(x, h - 1, w, 1, C(0x8A8E96))                               // the rail, polished
}

/// A passenger standing in a window `w` wide from `x`, on its sill at `floor`: Clawd as he always is, the wide orange
/// block with its shaded side, two tall dark eyes, an arm nub each side (one up, holding on, if `armUp`) and his four
/// legs; or a goblin, the same in green with pointed ears. Sized to fill the window's width.
private func tanglePassenger(_ c: PixelCanvas, x: Int, w: Int, floor: Int, goblin: Bool, armUp: Bool) {
    let q = Double(w) / 27
    func u(_ n: Double) -> Int { max(1, Int((n * q).rounded())) }
    let body = goblin ? C(0x5A8A3A) : clawdOrange, shade = goblin ? C(0x3E6A26) : clawdShade
    let eye = goblin ? C(0x1A2A0E) : C(0x16161B)
    let bw = u(20), bh = u(12), legH = u(6), legW = max(2, u(2))
    let bx = x + (w - bw) / 2, by = floor - legH - bh
    for lx in [1.0, 5.0, 13.0, 17.0] { c.rect(bx + u(lx), by + bh, legW, legH, shade) }
    c.rect(bx, by, bw, bh, body)
    c.rect(bx, by + bh - 1, bw, 1, shade); c.rect(bx + bw - 1, by, 1, bh, shade)
    let arm = u(3)
    c.rect(bx - arm, by + u(7), arm, arm, shade)
    c.rect(bx + bw, by + (armUp ? u(1) : u(7)), arm, arm, shade)
    c.rect(bx + u(4), by + u(3), u(2), u(3), eye); c.rect(bx + u(14), by + u(3), u(2), u(3), eye)
    if goblin {
        for ex in [bx, bx + bw - u(3)] { c.rect(ex, by - u(3), u(3), u(3), body) }
    }
}

/// The cab at the front, its tip at `head`, `nose` long, its sloped front along `edge`: the silver body curving
/// back toward the roof, a dark windscreen with a glint on it, an amber line number over it, yellow and black
/// chevrons low on the nose, and the headlight blazing.
private func tangleCab(_ c: PixelCanvas, head: Int, nose: Int, h: Int, jolt: Int, edge: (Int) -> Int) {
    let hh = Double(h), back = head + nose
    let body = C(0x8A8E98), bodyL = C(0xB0B4BE), bodyD = C(0x60646E)
    for y in 0..<h {
        let e = edge(y)
        guard e < back else { continue }
        let yn = Double(y - jolt) / hh
        var col = body
        if yn < 0.1 { col = C(0x5A5E66) } else if yn > 0.84 { col = C(0x1A1A1E) } else if yn > 0.8 { col = bodyD }
        c.rect(e, y, back - e, 1, col)
        c.px(e, y, yn > 0.84 ? C(0x2A2A30) : bodyL)                     // the lit leading edge
    }
    // The windscreen, set back along the slope, and the line number over it.
    for y in Int(hh * 0.16)..<Int(hh * 0.46) {
        let e = edge(y) + 3
        c.rect(e, y + jolt, back - 4 - e, 1, C(0x1A2028))
    }
    let gy = Int(hh * 0.22)
    c.rect(edge(gy) + 5, gy + jolt, 2, Int(hh * 0.12), C(0x6A8AA8)); c.px(edge(gy) + 7, gy + jolt, C(0xC8DCF0))
    c.rect(back - 12, Int(hh * 0.04) + jolt, 9, 7, C(0x2A1A0A))
    crawlText(c, back - 9, Int(hh * 0.04) + 1 + jolt, "3", C(0xF0A830))
    // The red stripe round the nose, the chevrons under it, the headlight.
    let sy = Int(hh * 0.58)
    for y in sy..<Int(hh * 0.65) { c.rect(edge(y), y + jolt, back - edge(y), 1, C(0xB03428)) }
    for y in Int(hh * 0.67)..<Int(hh * 0.8) {
        let e = edge(y)
        for x in e..<back where ((x - e) + y) / 3 % 2 == 0 { c.px(x, y + jolt, C(0xF0C028)) }
        for x in e..<back where ((x - e) + y) / 3 % 2 != 0 { c.px(x, y + jolt, C(0x24242A)) }
    }
    let ly = Int(hh * 0.72) - 2
    c.rect(head + 1, ly + jolt, 4, 4, C(0xFFF4C0)); c.rect(head + 1, ly + jolt, 2, 2, C(0xFFFFFF))
}
