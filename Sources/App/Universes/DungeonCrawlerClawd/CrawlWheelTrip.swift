import CoreGraphics
import Foundation

// The Death Watch Wheel (`CrawlWipe.wheel`), likelier with Maestro or Chaco and going to the Death Watch stage:
// Maestro's gaudy prize wheel spins, ticks, and lands on the new place's name.

extension CrawlTrip {
    /// The Death Watch Wheel, `k` (0…1) through its own part, over the whole of `r`. Maestro's big game-show wheel,
    /// a drum standing on its side so its wedges come over the top and down the front toward us, each a band of red,
    /// gold, black or cream with a prize or a place on it in the System's letters. A crimson sunburst dithers in over
    /// the old place while the wheel drops in from above with a bounce, already spinning (0–0.14); it spins down,
    /// wedge after wedge flicking the two gold pointers either side of the front as they tick past, slowing and
    /// going a hair too far (to 0.68), then rocks back onto the winning wedge, the new place's name (to 0.73); the
    /// wedge flashes, the bulbs down the wheel's gold rails all blinking (to 0.8); then the camera dives into it, the
    /// wheel and its frame flying off the edges, the wedge's face opening onto the new place and the name crumbling
    /// away (0.8–0.92). Names up to about 32 letters fit: a long one goes on two lines, or in smaller letters where
    /// the wedge is short.
    func drawWheel(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.92 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let frame = Int(k * CrawlWipe.wheel.effect * 30)

        // The drum: `n` wedges round it, seen from the front, `rad` rows from its middle to its top and bottom.
        let n = 12, step = 2 * Double.pi / Double(n)
        let rad = Double(h) * 0.4
        let face = Int((rad * step).rounded())                       // a wedge's own height, flat on
        let dw = art.wide ? min(w * 62 / 100, 330) : w * 84 / 100
        let dx = (w - dw) / 2
        let drop = Self.span(k, 0.02, 0.14)
        let fall = (1 - drop) * (1 - drop) * Double(h) * 1.1
        let bounce = drop >= 1 ? -sin(Self.span(k, 0.14, 0.2) * .pi) * 3 : 0
        let cy = Double(h) / 2 + (art.wide ? 2 : 4) - fall + bounce

        // How far round it is: fast at first, slowing, past the winner by a quarter of a wedge, then back onto it.
        let spin = Self.span(k, 0, 0.68)
        var angle = 0.25 * step - 8 * .pi * pow(1 - spin, 2.2)
        if spin >= 1 { angle = 0.25 * step * (1 - Self.ease(Self.span(k, 0.68, 0.73))) }
        let tick = (angle / step + 0.5) - floor(angle / step + 0.5)
        let flap = k < 0.73 ? max(0, 1 - tick / 0.35) : 0

        // The zoom into the winning wedge at the end.
        let dive = Self.ease(Self.span(k, 0.8, 0.9))
        let open = Self.span(k, 0.8, 0.85)                           // the wedge's face giving way to the new place
        let crumble = Self.span(k, 0.83, 0.88)

        // The sunburst behind it all, dithering in over the old place.
        let come = Self.span(k, 0, 0.1)
        let bx = Double(w) / 2, by = cy + fall
        let turn = k * 0.6
        // Where the winning wedge's face has given way, nothing is drawn, so the new place shows through.
        func opened(_ x: Int, _ y: Int) -> Bool {
            guard open > 0, x >= dx, x < dx + dw, wheelBayer[(y % 4) * 4 + x % 4] < open else { return false }
            let sn = (Double(y) + 0.5 - cy) / rad
            return abs(sn) < 1 && abs(asin(sn) - angle) < step / 2
        }
        for y in 0..<h {
            for x in 0..<w {
                if come < 1 && wheelBayer[(y % 4) * 4 + x % 4] >= come { continue }
                if opened(x, y) { continue }
                let a = atan2(Double(y) - by, (Double(x) - bx) * 0.8) + turn
                let ray = Int(floor(a / (Double.pi / 10) + 20)) % 2 == 0
                let d = hypot(Double(x) - bx, Double(y) - by) / Double(h)
                c.px(x, y, ray ? (d < 0.5 ? C(0xB81A24) : C(0x96121C)) : (d < 0.5 ? C(0x7E0E18) : C(0x620A12)))
            }
        }

        // The wedges, round the drum.
        let labels = wheelLabels(to: to)
        let faces = (0..<n).map { wheelFace(labels[$0], index: $0, w: dw, h: face) }
        let lit = k >= 0.73 && k < 0.8 && frame % 4 < 2
        let top = Int((cy - rad).rounded()), bottom = Int((cy + rad).rounded())
        for y in max(0, top)..<max(0, min(h, bottom)) {
            let sn = (Double(y) + 0.5 - cy) / rad
            guard abs(sn) < 1 else { continue }
            let phi = asin(sn) - angle                                // where on the drum this row looks, from the front
            let u = phi / step + 0.5
            let i = ((Int(floor(u)) % n) + n) % n
            let row = Int(((u - floor(u)) * Double(face)).rounded(.down))
            let (src, words) = faces[i]
            // Shaded toward the top and bottom, where the drum turns away, in steps.
            let dim = abs(sn) > 0.9 ? 0.55 : abs(sn) > 0.72 ? 0.32 : abs(sn) > 0.45 ? 0.14 : 0
            for x in 0..<dw {
                guard src.isDrawn(x, row) else { continue }
                if i == 0 && opened(dx + x, y) {
                    // Opening onto the new place: a hole here, but the name stays a little longer.
                    if !(words.isDrawn(x, row) && crumble < 1 &&
                         noise(row / 2 * 977 + x / 2 * 13) >= crumble) { continue }
                }
                var col = unpremultiplied(src, (row * dw + x) * 4)
                if lit && i == 0 && !words.isDrawn(x, row) { col = lerp(col, C(0xFFF4C0), 0.5) }
                if dim > 0 { col = lerp(col, C(0x1A0608), dim) }
                c.px(dx + x, y, col)
            }
        }

        // The frame: gold rails down both sides with chasing bulbs, a red housing over the top and bottom with gold
        // trim and a bone skull on the top, the pointers either side of the front.
        let rail = 7
        let gold = C(0xE8B030), goldL = C(0xFFE07A), goldD = C(0x9A6A18), red = C(0xA8141C), redD = C(0x5A0A10)
        let hy0 = top - 6, hy1 = bottom
        for side in 0..<2 {
            let x0 = side == 0 ? dx - rail : dx + dw
            c.rect(x0, hy0, rail, hy1 + 6 - hy0, gold)
            c.rect(x0, hy0, 1, hy1 + 6 - hy0, goldL); c.rect(x0 + rail - 1, hy0, 1, hy1 + 6 - hy0, goldD)
            var b = 0
            for y in stride(from: hy0 + 8, to: hy1 - 2, by: 7) {
                let on = lit ? true : (b + frame / 2) % 3 != 0
                c.rect(x0 + 2, y, 3, 3, on ? C(0xFFF8D8) : C(0x8A5A10))
                if on { c.px(x0 + 2, y, C(0xFFFFFF)) }
                b += 1
            }
        }
        for (y0, hh) in [(hy0, 6), (hy1, 6)] {
            c.rect(dx - rail - 2, y0, dw + 2 * rail + 4, hh, red)
            c.rect(dx - rail - 2, y0, dw + 2 * rail + 4, 1, gold)
            c.rect(dx - rail - 2, y0 + hh - 1, dw + 2 * rail + 4, 1, redD)
            for x in stride(from: dx - rail + 2, to: dx + dw + rail - 1, by: 6) { c.px(x, y0 + 3, goldL) }
        }
        wheelSkull(c, w / 2, hy0 - 4)
        // The pointers: red and white flappers, knocked up by every wedge going past.
        let mid = Int(cy.rounded())
        let lift = Int((flap * 3).rounded())
        for side in 0..<2 {
            let base = side == 0 ? dx - rail - 3 : dx + dw + rail + 2
            let dir = side == 0 ? 1 : -1
            for i in 0..<9 {
                let x = base + dir * i
                let half = max(0, 3 - i / 3), yy = mid - (lift * i) / 8
                c.rect(x, yy - half, 1, half * 2 + 1, i < 3 ? C(0xF0E8E0) : C(0xD02028))
                c.px(x, yy - half, i < 3 ? C(0xFFFFFF) : C(0xF04A4A))
            }
            c.rect(base - dir, mid - 2, 2, 5, goldD)
        }

        // Onto the frame: the old place under the sunburst until it's in, the new place under the wedge as it opens,
        // and the art blown up about the winning wedge's middle as the camera dives into it.
        ctx.drawShot(k < 0.5 ? old : new, in: r)
        guard let img = c.makeImage() else { return }
        let zoomTo = max(Double(w) / Double(dw), Double(h) / Double(face)) * 1.15
        let z = CGFloat(pow(zoomTo, dive))
        let full = art.frame(0, 0, w, h)
        let p = CGPoint(x: art.frame(dx + dw / 2, mid, 1, 1).minX, y: art.frame(dx + dw / 2, mid, 1, 1).maxY)
        let target = CGRect(x: p.x + (full.minX - p.x) * z, y: p.y + (full.minY - p.y) * z, width: full.width * z,
                            height: full.height * z)
        ctx.saveGState()
        ctx.clip(to: r)
        ctx.interpolationQuality = .none
        ctx.draw(img, in: target)
        ctx.restoreGState()
    }
}

/// A 4×4 ordered dither, thresholds in 0…1.
private let wheelBayer: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

/// What's on the wheel's twelve wedges: the new place's name on the winner (number 0), then prizes and other places
/// in turn, the way Maestro's wheel mixes good fortune with very bad.
private func wheelLabels(to: Location) -> [String] {
    let prizes = ["LOOT BOX", "BOSS FIGHT", "DOUBLE OR DEATH", "1000 GOLD", "MYSTERY BOX", "SPIN AGAIN"]
    let places = [Location.crawlHumpTown, .crawlOverCity, .crawlHavana, .crawlLarracos, .crawlCircus, .crawlGym,
                  .crawlHoard].filter { $0 != to }.prefix(5).map { crawlSystemName($0) }
    var out = [crawlSystemName(to)]
    for i in 0..<11 { out.append(i % 2 == 0 ? prizes[i / 2] : places[i / 2]) }
    return out
}

/// The colours a wedge comes in, by its number: red, gold, black and cream in turn, with the letters' colour and
/// their shadow on each.
private let wheelColours: [(face: UInt32, light: UInt32, dark: UInt32, text: UInt32, shadow: UInt32)] = [
    (0xE8B030, 0xFFE07A, 0x9A6A18, 0x7A0A12, 0xFFF0B0),
    (0xC81E28, 0xF05A4A, 0x7A0E14, 0xFFE07A, 0x3A0408),
    (0x241418, 0x4A3036, 0x0E0608, 0xE8B030, 0x000000),
    (0xF0E4C8, 0xFFFFFF, 0xB8A888, 0xB81A24, 0xFFFFFF),
]

/// One wedge's face, flat on, `w` by `h`: its colour lit along the top and shaded along the bottom, a dark line
/// between it and the next, gold studs at both ends, and its words in the middle, as big as fit (up to three pixels
/// a dot). Along with it, the words on their own, to tell them apart from the rest of the face.
private func wheelFace(_ text: String, index: Int, w: Int, h: Int) -> (face: PixelCanvas, words: PixelCanvas) {
    let c = PixelCanvas(w, max(1, h)), words = PixelCanvas(w, max(1, h))
    let col = index == 0 ? wheelColours[0] : wheelColours[1 + (index - 1) % 3]
    c.rect(0, 0, w, h, C(col.face))
    c.rect(0, 1, w, 1, C(col.light)); c.rect(0, h - 2, w, 1, C(col.dark)); c.rect(0, h - 1, w, 1, C(0x1A0608))
    c.rect(0, 0, w, 1, C(0x1A0608))
    for x in [3, w - 6] { c.rect(x, h / 2 - 1, 3, 3, C(0xE8B030)); c.px(x, h / 2 - 1, C(0xFFF0B0)) }
    // One line as big as fits; a long one at two pixels a dot that won't fit on one line goes on two, broken at
    // the space nearest its middle, if the wedge is tall enough; otherwise one line, smaller.
    var s = 3
    while s > 1 && (crawlTextWidth(text, scale: s) > w - 18 || 5 * s > h - 8) { s -= 1 }
    var lines = [text]
    if s < 2 && 13 * 2 <= h - 6 {
        let mid = text.count / 2
        let spaces = text.indices.filter { text[$0] == " " }
        if let cut = spaces.min(by: { abs(text.distance(from: text.startIndex, to: $0) - mid) <
                                      abs(text.distance(from: text.startIndex, to: $1) - mid) }) {
            let two = [String(text[..<cut]), String(text[text.index(after: cut)...])]
            if two.allSatisfy({ crawlTextWidth($0, scale: 2) <= w - 18 }) { lines = two; s = 2 }
        }
    }
    let block = lines.count * 5 * s + (lines.count - 1) * 3
    for (n, line) in lines.enumerated() {
        let tw = crawlTextWidth(line, scale: s), tx = (w - tw) / 2, ty = (h - block) / 2 + n * (5 * s + 3)
        crawlText(c, tx + 1, ty + 1, line, C(col.shadow), scale: s)
        crawlText(c, tx, ty, line, C(col.text), scale: s)
        crawlText(words, tx + 1, ty + 1, line, C(0xFFFFFF), scale: s)
        crawlText(words, tx, ty, line, C(0xFFFFFF), scale: s)
    }
    return (c, words)
}

/// A little bone skull, `x` its middle and `y` its top: Maestro's badge on the wheel's housing.
private func wheelSkull(_ c: PixelCanvas, _ x: Int, _ y: Int) {
    c.pattern(x - 4, y, [
        "..#####..",
        ".#######.",
        "##..#..##",
        "##..#..##",
        ".###.###.",
        "..#.#.#..",
    ], ["#": C(0xF0E4C8)])
    c.rect(x - 2, y + 2, 2, 2, C(0x2A0608)); c.rect(x + 1, y + 2, 2, 2, C(0x2A0608))
}
