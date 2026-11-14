import CoreGraphics
import Foundation

// Down the Stairwell (`CrawlWipe.stairwell`), likelier with Carl, Donut or Mordecai and going to the First Floor
// tunnels: the view spirals down a stone stairwell, a floor counter ticks over, and the bottom opens onto the new place.

extension CrawlTrip {
    /// Down the Stairwell, `k` (0…1) through its own part, over the whole of `r`. The view tips down: the old place
    /// slides up and away and the stairwell's mouth comes up from below it, a round stone shaft seen from the top, its
    /// bottom lost in the dark (0–0.24). Then down it goes, round and round: block courses of grey stone rushing up
    /// past us, the steps winding round the wall as a lit spiral, torches flickering on brackets, their warm light on
    /// the stone around them (0.1–1). A System box pops up over the dark at the bottom, DESCENDING over FLOOR and the
    /// floor's number (0.3–0.7), and the number ticks over to the next floor, the old digit rolling up and out and the
    /// new one rolling in, with a flash (0.42–0.52). The bottom opens: the new place's light at the far end, small, a
    /// pale rim round it, rushing up the shaft until it fills the screen (0.62–1). Flat stone rings on the art's grid,
    /// shaded in steps toward the dark, the old and new places cut along them.
    func drawStairwell(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let tilt = Self.ease(Self.span(k, 0, 0.24))
        let open = pow(Self.span(k, 0.62, 1), 1.7)

        // The shaft is an ellipse, wider than tall on the window's strip, measured in `d` (rows) from its middle, which
        // comes up from below the frame as the view tips down.
        let ax: Double = art.wide ? 2.4 : 1.35
        let cx = Double(w) / 2, cy = Double(h) / 2 + (1 - tilt) * Double(h)
        let half = cx / ax, hh = Double(h) / 2
        let corner = (half * half + hh * hh).squareRoot() + 2
        func d(_ x: Int, _ y: Int) -> Double {
            let dx = (Double(x) + 0.5 - cx) / ax, dy = Double(y) + 0.5 - cy
            return (dx * dx + dy * dy).squareRoot()
        }
        let end = open > 0 ? 1.5 + (corner * 1.1 - 1.5) * open : 0

        // The new place at the bottom, scaled to just cover the opening.
        if end > 1.5 {
            let hole = art.runs { x, y in d(x, y) < end }
            if !hole.isEmpty {
                let fitW = 2 * end * ax / Double(w), fitH = 2 * end / Double(h)
                let scale = CGFloat(min(1, max(fitW, fitH)))
                let sw = r.width * scale, sh = r.height * scale
                ctx.saveGState(); ctx.clip(to: hole)
                ctx.drawShot(new, in: CGRect(x: r.midX - sw / 2, y: r.midY - sh / 2, width: sw, height: sh))
                ctx.restoreGState()
            }
        }

        // The shaft. `u` is depth (a course of stone a unit), running on as we go down; `a` the way round, turning.
        // Courses grow toward the rim until they're about 18 pixels deep, then stay that size: the window's strip
        // stretches them sideways, and they'd otherwise turn into slabs at its ends. More blocks to a ring there too.
        let reach = hh * hh / 7
        let flat = (18 / ax * reach).squareRoot()
        let run = 8 + k * 9, turn = k * 1.6
        let cols: Double = art.wide ? 24 : 18
        let flick = Int(k * 40)
        for y in 0..<h {
            for x in 0..<w {
                let dd = d(x, y)
                if end > 0 && dd < end { continue }
                if end > 0 && dd < end + 1.2 { c.px(x, y, C(0xFFF0C8)); continue }   // the pale rim of the opening
                if dd < 2.5 { c.px(x, y, C(0x08080C)); continue }
                let u = (dd < flat ? reach / dd : reach / flat - (dd - flat) * reach / (flat * flat)) + run
                let dx = (Double(x) + 0.5 - cx) / ax, dy = Double(y) + 0.5 - cy
                let a0 = atan2(dy, dx) / (2 * .pi) + 0.5
                let a = (a0 + turn).truncatingRemainder(dividingBy: 1)
                let row = Int(floor(u)), fu = u - floor(u)
                let ca = a * cols + (row % 2 == 0 ? 0 : 0.5)
                let col = Int(floor(ca)) % Int(cols), fa = ca - floor(ca)
                // The steps: a helix round the wall, three courses to a turn, each step a block of the course.
                let helix = (a - u / 3).truncatingRemainder(dividingBy: 1)
                let s = helix < 0 ? helix + 1 : helix
                var hex: UInt32
                if s < 0.3 {
                    // A step: its lit tread, a pale nosing along its top, the dark riser at its leading edge.
                    hex = fa < 0.14 ? 0x34303A : (fu < 0.14 ? 0xB4AEA0 : (col % 2 == 0 ? 0x8E887E : 0x857F76))
                } else if fu < 0.12 || fa < 0.07 {
                    hex = 0x26242C                                                  // mortar
                } else {
                    let tone = noise(row * 31 + col * 7 + 900)
                    hex = tone < 0.33 ? 0x5A5662 : (tone < 0.66 ? 0x524E58 : 0x625C66)
                    if fu > 0.82 { hex = 0x45414C }                                 // the shadowed foot of the course
                }
                // Torches, every third course and every sixth block, staggered, with their warm light about them.
                let torchRow = row % 3 == 0, torchCol = (col + row / 3 * 2) % 6 == 0
                var warm = 0.0
                for (dr, dc) in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)] {
                    let rr = row + dr, cc = (col + dc + Int(cols)) % Int(cols)
                    if rr % 3 == 0 && (cc + rr / 3 * 2) % 6 == 0 { warm = max(warm, dr == 0 && dc == 0 ? 0.5 : 0.25) }
                }
                if torchRow && torchCol && s >= 0.3 {
                    let fx = abs(fa - 0.5), lit = noise(flick * 13 + row * 5 + col) > 0.5
                    if fu > 0.58 && fu < 0.82 && fx < 0.1 { hex = 0x2A2018 }        // the bracket
                    else if fu > 0.26 && fu <= 0.58 && fx < 0.16 { hex = fu < 0.4 ? (lit ? 0xFFF4C0 : 0xFFD060) : 0xFF8A2A }
                    else if fu > 0.14 && fu <= 0.26 && fx < 0.07 { hex = lit ? 0xFFD060 : 0xFF8A2A }
                    else if warm > 0 { hex = Self.mixHex(hex, 0xC07A40, warm) }
                } else if warm > 0 {
                    hex = Self.mixHex(hex, 0xB07040, warm * 0.6)
                }
                // Toward the bottom the stone sinks into the dark, in steps.
                let fog = 1 - Self.clamp((dd - hh * 0.28) / (hh * 0.55))
                c.px(x, y, Self.mix(hex, 0x08080C, (fog * 6).rounded() / 6))
            }
        }

        // The floor counter: a System box over the dark at the bottom.
        let box = Self.span(k, 0.3, 0.34) * (1 - Self.span(k, 0.66, 0.7))
        if box > 0 { crawlStairCounter(c, k: k, cx: Int(cx), cy: Int(cy), size: box, wide: art.wide) }
        art.show(ctx)

        // The old place, tipping up out of sight, a dark lip along its bottom edge.
        if tilt < 1 {
            let lift = r.height * CGFloat(tilt)
            ctx.drawShot(old, in: r.offsetBy(dx: 0, dy: lift))
            ctx.setFillColor(crawlTripRGB(0x14121A)); ctx.fill(CGRect(x: r.minX, y: r.minY + lift - art.px, width: r.width, height: art.px))
        }
    }

    /// The box with DESCENDING over FLOOR and the number, centred on (`cx`, `cy`), `size` (0…1) of the way popped up:
    /// the number is the floor the crew was on, and from 0.42 to 0.52 of the trip it rolls over to the next one.
    private func crawlStairCounter(_ c: PixelCanvas, k: Double, cx: Int, cy: Int, size: Double, wide: Bool) {
        let (a, b) = crawlStairFloors(from: from, to: to)
        let s = wide ? 2 : 3
        let head = "DESCENDING", label = "FLOOR "
        let digits = max(String(a).count, String(b).count)
        let numW = crawlTextWidth(String(repeating: "0", count: digits), scale: s)
        let lineW = crawlTextWidth(label, scale: s) + 1 + numW
        let bw = max(lineW, crawlTextWidth(head)) + 10, bh = 4 + 5 + 3 + 5 * s + 5
        let pop = Self.ease(size)
        let sw = max(4, Int(Double(bw) * pop)), sh = max(2, Int(Double(bh) * pop))
        let x = cx - sw / 2, y = cy - sh / 2
        let roll = Self.ease(Self.span(k, 0.42, 0.5))
        let flash = k > 0.5 && k < 0.56 ? 1 - (k - 0.5) / 0.06 : 0
        let lit = lerp(C(0x6AB4FF), C(0xFFFFFF), flash), deep = lerp(C(0x2A64C8), C(0xFFFFFF), flash)
        let halo = C(0x3A8CFF, 0.28 + 0.5 * flash)
        c.rect(x - 2, y - 1, sw + 4, sh + 2, halo)
        c.rect(x - 1, y - 2, sw + 2, 1, halo); c.rect(x - 1, y + sh + 1, sw + 2, 1, halo)
        c.rect(x, y, sw, sh, C(0x0E2A6A))
        c.rect(x, y, sw, 1, lit); c.rect(x, y, 1, sh, lit)
        c.rect(x, y + sh - 1, sw, 1, deep); c.rect(x + sw - 1, y, 1, sh, deep)
        guard pop >= 1 else { return }

        crawlText(c, x + (bw - crawlTextWidth(head)) / 2, y + 4, head, C(0xF8D058))
        c.rect(x + 3, y + 10, bw - 6, 1, C(0x2A64C8))
        let tx = x + (bw - lineW) / 2, ty = y + 13
        crawlText(c, tx, ty + 1, label, C(0x08184A), scale: s)
        crawlText(c, tx, ty, label, C(0xF0F6FF), scale: s)
        // The number rolls up: the old one out of the top of its window, the new one in from the bottom.
        let nx = tx + crawlTextWidth(label, scale: s) + 1, nh = 5 * s
        let shift = Int((roll * Double(nh + 2)).rounded())
        let window = PixelCanvas(numW, nh + 1)
        let old = String(a), new = String(b)
        crawlText(window, numW - crawlTextWidth(old, scale: s), -shift + 1, old, C(0x08184A), scale: s)
        crawlText(window, numW - crawlTextWidth(old, scale: s), -shift, old, C(0xF0F6FF), scale: s)
        let newCol = lerp(C(0x9CFFB4), C(0xFFFFFF), flash)
        crawlText(window, numW - crawlTextWidth(new, scale: s), nh + 2 - shift + 1, new, C(0x08184A), scale: s)
        crawlText(window, numW - crawlTextWidth(new, scale: s), nh + 2 - shift, new, roll >= 1 ? newCol : C(0xF0F6FF), scale: s)
        c.paste(window, x: nx, y: ty)
    }

    /// A colour `k` of the way from `a` to `b`, as 0xRRGGBB.
    private static func mixHex(_ a: UInt32, _ b: UInt32, _ k: Double) -> UInt32 {
        func ch(_ s: UInt32) -> UInt32 {
            let x = Double(a >> s & 0xFF), y = Double(b >> s & 0xFF)
            return UInt32(max(0, min(255, (x + (y - x) * k).rounded())))
        }
        return ch(16) << 16 | ch(8) << 8 | ch(0)
    }
}

/// The floor the counter starts on and the one it ticks over to: the floors of the two places where they have one (the
/// books' floors), else one floor down from where the crew was, so it always goes down.
private func crawlStairFloors(from: Location, to: Location) -> (Int, Int) {
    let a = crawlStairFloor[from], b = crawlStairFloor[to]
    switch (a, b) {
    case let (a?, b?) where b > a: return (a, b)
    case let (_, b?): return (max(0, b - 1), b)
    case let (a?, nil): return (a, a + 1)
    default: return (1, 2)
    }
}

/// Which floor of the dungeon a place is on, for the ones that sit on one; the safe rooms, the personal space, the
/// studio, the Death Watch set and the temple are in every floor or none.
private let crawlStairFloor: [Location: Int] = [
    .crawlSeattle: 0, .crawlCorridor: 1, .crawlGuild: 1, .crawlHoard: 1, .crawlGym: 2, .crawlDesperado: 3,
    .crawlParade: 3, .crawlTangle: 4, .crawlCircus: 4, .crawlHumpTown: 5, .crawlOverCity: 6, .crawlCastle: 6,
    .crawlHunting: 6, .crawlHavana: 8, .crawlLarracos: 9,
]
