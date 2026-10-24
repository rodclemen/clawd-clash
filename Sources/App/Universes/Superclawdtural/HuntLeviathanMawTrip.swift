import CoreGraphics
import Foundation

// Leviathan Maw (`HuntWipe.leviathanMaw`, only with Dick Roman or the Leviathan blob about): Dick Roman's grin, the
// size of the screen. A smile line spreads across the old place, white teeth showing, and splits it open: the top half
// lifts as the upper jaw and the bottom half drops as the lower one, rows of fangs along both, a dark purple throat
// and a tongue between. The jaws snap shut with a jolt, black goo oozing out of the seam and dripping down, then they
// open again, wide, strings of goo stretching across and snapping, and pull right off the screen onto the new place.
// Funny-eerie, never gory: the goo is glossy black with purple-grey light on it, so it reads on a dark place.

extension HuntTrip {
    /// A frame `k` (0…1) of Leviathan Maw, over the whole of `r`. The grin spreads from the middle (0–0.12); the jaws
    /// open on the throat (0.1–0.34); they snap shut with a shake (0.36–0.43) and goo oozes from the seam and runs
    /// down (0.43–0.62); they open again on the new place and leave the screen top and bottom, goo strands snapping
    /// between them (0.6–0.96).
    func drawLeviathanMaw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let cx = Double(w) / 2
        let frame = Int(k * 54)

        // How open the jaws are, and how far they go: a first bite on the throat, the snap, then wide and away.
        let first = Self.ease(Self.span(k, 0.1, 0.32))
        let shut = pow(Self.span(k, 0.36, 0.43), 2)
        let away = Self.ease(Self.span(k, 0.6, 0.96))
        let onNew = k >= 0.6
        let snapShake = k > 0.43 && k < 0.5 ? Int(((noise(frame * 13) - 0.5) * 4).rounded()) : 0
        let reveal = Self.ease(Self.span(k, 0, 0.12))

        // The smile line: low in the middle, the corners turned up; how wide the mouth gapes along it, nearly shut at
        // the corners until it opens right out.
        func e(_ x: Int) -> Double { min(1, abs(Double(x) + 0.5 - cx) / cx) }
        func seam(_ x: Int) -> Int {
            let u = e(x)
            return Int((Double(h) * (0.42 + 0.14 * (1 - pow(u, 4))))).advanced(by: snapShake)
        }
        func pinch(_ x: Int) -> Double { pow(max(0, 1 - pow(e(x), 2.4)), 0.6) }
        // Each jaw stands off the seam by its gum and half its teeth once the grin has spread that far, so shut, the
        // fangs meet and interlock along the smile instead of crossing.
        let tw = 10, tBase = art.wide ? 11 : 13, gum = art.wide ? 2 : 3
        let reach = reveal * cx + 2, grow = 0.4 + 0.6 * reveal
        func clear(_ x: Int) -> Int {
            let inside = reach - abs(Double(x) + 0.5 - cx)
            guard inside > 0 else { return 0 }
            let taper = reveal < 1 ? min(1, inside / 10) : 1    // the spreading ends of the grin come to a point
            return Int((Double(gum + 1) * taper + Double(tBase) * (0.35 + 0.65 * pinch(x)) * grow * 0.55 * taper).rounded())
        }
        func upper(_ x: Int) -> Int {
            let p = pinch(x)
            if onNew { return Int((Double(h) * 0.86 * away * (p + (1 - p) * away)).rounded()) + clear(x) }
            let o = k < 0.36 ? first : 1 - shut
            return Int((Double(h) * 0.26 * o * p).rounded()) + clear(x)
        }
        func lower(_ x: Int) -> Int {
            let p = pinch(x)
            if onNew { return Int((Double(h) * 0.7 * away * (p + (1 - p) * away)).rounded()) + clear(x) }
            let o = k < 0.36 ? first : 1 - shut
            return Int((Double(h) * 0.32 * o * p).rounded()) + clear(x)
        }
        let top = (0..<w).map { seam($0) - upper($0) }, bottom = (0..<w).map { seam($0) + lower($0) }

        // Behind the jaws: the new place once they open the second time (the throat is drawn in the art).
        if onNew { ctx.drawShot(new, in: r) }

        // The two halves of the old place, each column moved with its jaw, grouped by how far they've moved.
        for upperJaw in [true, false] {
            var groups: [Int: [CGRect]] = [:]
            for x in 0..<w {
                let d = upperJaw ? upper(x) : lower(x)
                let rect = upperJaw ? art.frame(x, 0, 1, max(0, top[x])) : art.frame(x, bottom[x], 1, max(0, h - bottom[x]))
                if rect.height > 0 { groups[d, default: []].append(rect) }
            }
            for (d, rects) in groups {
                ctx.saveGState()
                ctx.clip(to: rects)
                let dy = CGFloat(d - snapShake) * art.px
                ctx.drawShot(old, in: r.offsetBy(dx: 0, dy: upperJaw ? dy : -dy))
                ctx.restoreGState()
            }
        }

        // The throat, between the jaws until they open on the new place.
        if !onNew {
            for x in 0..<w where bottom[x] > top[x] {
                let gap = Double(bottom[x] - top[x])
                for y in top[x]..<bottom[x] {
                    let t = Double(y - top[x]) / gap
                    let deep = 1 - ((2 * t - 1) * (2 * t - 1) + e(x) * e(x)).squareRoot()
                    c.px(x, y, C(deep < 0.12 ? 0x3A1430 : deep < 0.35 ? 0x26102A : deep < 0.6 ? 0x180A1C : 0x0C0612))
                }
                // The tongue, a purple hump in the bottom of it.
                let tx = abs(Double(x) - cx) / (Double(w) * 0.2)
                if tx < 1 {
                    let th = Int(gap * 0.28 * (1 - tx * tx))
                    if th > 1 {
                        c.rect(x, bottom[x] - th, 1, th, C(0x5A2648))
                        c.px(x, bottom[x] - th, C(0x8A4672)); c.px(x, bottom[x] - th + 1, C(0x6E3258))
                        if abs(Double(x) - cx) < 1 { c.rect(x, bottom[x] - th + 2, 1, th / 2, C(0x3A1430)) }
                    }
                }
            }
        }

        // Gums, teeth and the goo rim along both jaws. The teeth grow in as the grin spreads.
        let biteOn = k < 0.6 ? 1.0 : 1 - Self.span(k, 0.96, 1)
        guard biteOn > 0 else { art.show(ctx); return }
        for x in 0..<w where abs(Double(x) + 0.5 - cx) < reach {
            // Upper gum and its goo lip, then the lower.
            for j in 0..<gum { c.px(x, top[x] + j, C(j == gum - 1 ? 0x6A2238 : 0x8E3450)) }
            c.px(x, top[x] - 1, C(0x141018)); c.px(x, top[x] - 2, C(x % 7 == 0 ? 0x7A6AA0 : 0x2A2038))
            for j in 0..<gum { c.px(x, bottom[x] - 1 - j, C(j == gum - 1 ? 0x6A2238 : 0x8E3450)) }
            c.px(x, bottom[x], C(0x141018)); c.px(x, bottom[x] + 1, C(x % 9 == 4 ? 0x7A6AA0 : 0x2A2038))
        }
        // The fangs: upper ones hanging, lower ones standing between them, a dark edge round each so they read on a
        // bright place, a second, dimmer row behind them while the throat shows.
        func fang(_ x0: Int, down: Bool, _ size: Double, dim: Bool) {
            let th = max(2, Int((Double(tBase) * size).rounded()))
            for rrow in -1..<th + 1 {
                let f = Double(max(0, rrow)) / Double(th)
                let hw = Int((Double(tw / 2) * (1 - f)).rounded())
                for dx in -hw - 1...hw {
                    let x = x0 + dx
                    guard x >= 0 && x < w, abs(Double(x) + 0.5 - cx) < reach else { continue }
                    let y = down ? top[x] + gum + rrow : bottom[x] - 1 - gum - rrow
                    let edge = rrow < 0 || rrow == th || dx == -hw - 1 || dx == hw
                    if edge { c.px(x, y, C(0x2A1422)); continue }
                    let col: UInt32 = dim ? (dx >= hw - 1 ? 0x8A8478 : 0xB8B0A2) : (dx >= hw - 1 ? 0xC4BCAC : dx <= -hw + 1 ? 0xFFFFFF : 0xF6F0E2)
                    c.px(x, y, C(col))
                }
            }
        }
        if !onNew && first > 0.4 {
            for x0 in stride(from: tw / 2, to: w, by: tw) {
                let p = pinch(x0), g = bottom[x0] - top[x0]
                guard p > 0.4, g > tBase * 3 else { continue }
                fang(x0, down: true, 0.55 * p, dim: true); fang(x0 + tw / 2, down: false, 0.55 * p, dim: true)
            }
        }
        for x0 in stride(from: 0, to: w + tw, by: tw) {
            let p = pinch(min(w - 1, max(0, x0)))
            fang(x0, down: true, (0.35 + 0.65 * p) * grow, dim: false)
            fang(x0 + tw / 2, down: false, (0.35 + 0.65 * p) * grow, dim: false)
        }

        // The goo. Drips hang from the upper jaw and fall; after the snap it oozes out along the seam and runs down
        // the lower jaw; as they part the second time, strings of it stretch across and snap.
        if k > 0.16 && k < 0.88 {
            for i in 0..<(art.wide ? 9 : 6) {
                let x = Int((0.12 + 0.76 * (Double(i) + noise(i * 5 + 1) * 0.6) / Double(art.wide ? 9 : 6)) * Double(w))
                guard x >= 0 && x < w, pinch(x) > 0.3 else { continue }
                let cycle = (k * (1.6 + noise(i * 5 + 2)) + noise(i * 5 + 3)).truncatingRemainder(dividingBy: 1)
                let hang = Int(cycle * Double(tBase + 10))
                let yTip = top[x] + gum + Int(Double(tBase) * 0.6)
                if cycle < 0.7 {
                    huntMawDrip(c, x, yTip, hang, bulb: true)
                } else {
                    let fall = Int((cycle - 0.7) / 0.3 * Double(h) * 0.5)
                    huntMawDrip(c, x, yTip, 2, bulb: false)
                    huntMawDrip(c, x, yTip + hang + fall, 2, bulb: true)
                }
            }
        }
        let ooze = Self.span(k, 0.43, 0.6)
        if ooze > 0 {
            // A bead of goo along the shut seam, glossy on top, and runs down the lower jaw.
            let bead = k < 0.6 ? 1.0 : 1 - away
            for x in 0..<w where bead > 0 && noise(x / 3 * 7 + 11) < 0.6 * bead {
                let y = bottom[x] + gum / 2
                c.rect(x, y, 1, 3, C(0x141018)); c.px(x, y, C((x / 3) % 3 == 0 ? 0xC8C0E8 : 0x5A4A7A))
            }
            for i in 0..<(art.wide ? 12 : 8) {
                let x = Int((0.06 + 0.88 * (Double(i) + noise(i * 7 + 31) * 0.7) / Double(art.wide ? 12 : 8)) * Double(w))
                guard x >= 0 && x < w else { continue }
                let run = Int(pow(Self.span(ooze, noise(i * 7 + 32) * 0.4, 1), 0.8) * Double(h) * (0.18 + 0.2 * noise(i * 7 + 33)))
                if run > 0 { huntMawDrip(c, x, bottom[x] + 2, run, bulb: true) }
            }
        }
        if onNew {
            for i in 0..<(art.wide ? 7 : 5) {
                let x = Int((0.15 + 0.7 * (Double(i) + noise(i * 3 + 51) * 0.5) / Double(art.wide ? 7 : 5)) * Double(w))
                guard x >= 0 && x < w else { continue }
                let a = top[x], b = bottom[x], gap = b - a
                let snapAt = Double(h) * (0.35 + 0.4 * noise(i * 3 + 52))
                if Double(gap) < snapAt {
                    // Still holding: thick at both ends, thin in the middle, sagging a little to one side.
                    let thin = Double(gap) / snapAt
                    for y in a..<b {
                        let t = Double(y - a) / Double(max(1, gap))
                        let wdt = max(1, Int((3.5 - (2.5 + thin) * sin(t * .pi)).rounded()))
                        let sx = x + Int((sin(t * .pi) * Double(gap) * 0.05).rounded())
                        c.rect(sx - wdt / 2, y, wdt, 1, C(0x141018))
                        c.px(sx - wdt / 2 - 1, y, C(0x5A4A7A)); c.px(sx + (wdt + 1) / 2, y, C(0x2A2038))
                        if (y + i) % 9 == 0 { c.px(sx - wdt / 2, y, C(0xC8C0E8)) }
                    }
                } else {
                    // Snapped: a stub hanging from the top and a puddle sagging off the bottom.
                    let over = min(1, (Double(gap) - snapAt) / (Double(h) * 0.3))
                    huntMawDrip(c, x, a, Int(4 + 8 * (1 - over)), bulb: true)
                    huntMawDrip(c, x + 1, b - Int(4 + 6 * (1 - over)), Int(4 + 6 * (1 - over)), bulb: false)
                }
            }
        }
        art.show(ctx)
    }

    /// A drip of Leviathan goo hanging from (x, y), `len` rows long: glossy black, a purple-grey light down its left
    /// side and a dark rim down its right, and a fat bead on the end with a white glint, so it reads on a dark place.
    private func huntMawDrip(_ c: PixelCanvas, _ x: Int, _ y: Int, _ len: Int, bulb: Bool) {
        guard len > 0 else { return }
        c.rect(x, y, 2, len, C(0x141018))
        c.rect(x - 1, y, 1, len, C(0x5A4A7A)); c.rect(x + 2, y, 1, len, C(0x2A2038))
        guard bulb else { return }
        let by = y + len
        c.rect(x - 1, by - 1, 4, 4, C(0x141018)); c.rect(x, by + 3, 2, 1, C(0x141018))
        c.rect(x - 2, by, 1, 3, C(0x5A4A7A)); c.rect(x + 3, by, 1, 3, C(0x2A2038))
        c.px(x - 1, by - 1, C(0x8A7AB0)); c.px(x, by, C(0xEEE8FF)); c.px(x - 1, by + 3, C(0x3A2A4A)); c.px(x + 2, by + 3, C(0x2A2038))
    }
}
