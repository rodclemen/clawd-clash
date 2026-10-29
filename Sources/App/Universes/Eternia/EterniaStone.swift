import CoreGraphics
import Foundation

// The finishing touch of every Clawds of the Universe trip: the new place's name in chunky carved-stone letters
// rises into the bottom-left corner out of a puff of dust, stays to be read, and sinks away again. Our own letters,
// blocky and square-cut, not the show's logo: sandstone faces lit from the top left, a darker cut on the bottom right
// and a dark outline, the way Eternia's places look hewn from rock.

extension EterniaTrip {
    /// The caption, `t` seconds into it (0…`caption`), over the whole of `r`: it rises out of the dust (0–0.35 s),
    /// stays (to 1.1 s) and sinks away (to the end).
    func drawStoneCaption(_ ctx: CGContext, t: Double, in r: CGRect) {
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let name = to.name.uppercased()
        // Two art pixels a dot, one where the name is too long for the frame.
        var p = 2
        if eterniaStoneWidth(name, p) + 16 > w * 9 / 10 { p = 1 }
        let tw = eterniaStoneWidth(name, p), th = 7 * p
        let x0 = art.wide ? 8 : 10
        let rest = h - th - (art.wide ? 8 : h / 12)
        let rise = Self.ease(Self.span(t, 0, 0.35)), sink = Self.ease(Self.span(t, 1.1, Self.caption))
        let y = rest + Int(((1 - rise) + sink) * Double(h - rest + 2))
        // The dust it rises out of: puffs along its foot, drifting out and fading.
        let dust = Self.span(t, 0, 0.7)
        if dust > 0 && dust < 1 {
            for i in 0..<14 {
                let fx = Double(x0) + Double(tw) * noise(i * 3 + 400)
                let drift = (noise(i * 3 + 401) - 0.5) * 18 * dust
                let up = 2 + 7 * dust * noise(i * 3 + 402)
                let size = max(1, Int((3 - 2 * dust) * Double(p)))
                c.rect(Int(fx + drift), rest + th - Int(up), size, size, C(0xC8B48C, 0.75 * (1 - dust)))
            }
        }
        // The carving, clipped to the frame's bottom so it rises out of the edge.
        eterniaStoneText(c, x0, y, name, p)
        art.show(ctx)
    }
}

/// The carved letters, 7 dots tall and 5 wide (M and W 7, so their middles read), a line to a row; anything else is a gap.
private let eterniaStoneGlyphs: [Character: [String]] = [
    "A": ["01110", "11011", "11011", "11111", "11011", "11011", "11011"],
    "B": ["11110", "11011", "11011", "11110", "11011", "11011", "11110"],
    "C": ["01111", "11000", "11000", "11000", "11000", "11000", "01111"],
    "D": ["11110", "11011", "11011", "11011", "11011", "11011", "11110"],
    "E": ["11111", "11000", "11000", "11110", "11000", "11000", "11111"],
    "F": ["11111", "11000", "11000", "11110", "11000", "11000", "11000"],
    "G": ["01111", "11000", "11000", "11011", "11011", "11011", "01111"],
    "H": ["11011", "11011", "11011", "11111", "11011", "11011", "11011"],
    "I": ["11110", "01100", "01100", "01100", "01100", "01100", "11110"],
    "J": ["00011", "00011", "00011", "00011", "11011", "11011", "01110"],
    "K": ["11011", "11011", "11110", "11100", "11110", "11011", "11011"],
    "L": ["11000", "11000", "11000", "11000", "11000", "11000", "11111"],
    "M": ["1100011", "1110111", "1111111", "1101011", "1100011", "1100011", "1100011"],
    "N": ["11001", "11101", "11111", "11011", "11011", "11011", "11011"],
    "O": ["01110", "11011", "11011", "11011", "11011", "11011", "01110"],
    "P": ["11110", "11011", "11011", "11110", "11000", "11000", "11000"],
    "Q": ["01110", "11011", "11011", "11011", "11011", "11110", "01101"],
    "R": ["11110", "11011", "11011", "11110", "11110", "11011", "11011"],
    "S": ["01111", "11000", "11000", "01110", "00011", "00011", "11110"],
    "T": ["11111", "01100", "01100", "01100", "01100", "01100", "01100"],
    "U": ["11011", "11011", "11011", "11011", "11011", "11011", "01110"],
    "V": ["11011", "11011", "11011", "11011", "11011", "01110", "00100"],
    "W": ["1100011", "1100011", "1100011", "1101011", "1111111", "1110111", "1100011"],
    "X": ["11011", "11011", "01110", "00100", "01110", "11011", "11011"],
    "Y": ["11011", "11011", "11011", "01110", "01100", "01100", "01100"],
    "Z": ["11111", "00011", "00110", "01100", "11000", "11000", "11111"],
    "-": ["00000", "00000", "00000", "11110", "00000", "00000", "00000"],
    "'": ["01100", "01100", "11000", "00000", "00000", "00000", "00000"],
    ".": ["00000", "00000", "00000", "00000", "00000", "11000", "11000"],
]

/// How wide `text` comes out at `p` art pixels a dot: each letter its own width and one between; a space 3.
private func eterniaStoneWidth(_ text: String, _ p: Int) -> Int {
    var dots = 0
    for ch in text { dots += eterniaStoneGlyphs[ch].map { $0[0].count + 1 } ?? 3 }
    return max(0, dots - 1) * p
}

/// `text` carved in stone from its top-left corner, `p` art pixels a dot: a dark outline all round, then each dot's
/// sandstone face, lit along its top and left where the dot above or beside is empty, shaded along its bottom and right.
private func eterniaStoneText(_ c: PixelCanvas, _ x: Int, _ y: Int, _ text: String, _ p: Int) {
    let face = C(0xC8A876), lit = C(0xF0DCA8), cut = C(0x8A6A44), ink = C(0x2A1C14)
    var dots: [(Int, Int)] = []
    var cx = x
    for ch in text {
        guard let g = eterniaStoneGlyphs[ch] else { cx += 3 * p; continue }
        for (row, line) in g.enumerated() {
            for (col, d) in line.enumerated() where d == "1" { dots.append((cx + col * p, y + row * p)) }
        }
        cx += (g[0].count + 1) * p
    }
    let set = Set(dots.map { "\($0.0),\($0.1)" })
    func has(_ dx: Int, _ dy: Int) -> Bool { set.contains("\(dx),\(dy)") }
    // The outline: every dot grown a pixel, then the drop to the bottom right.
    for (dx, dy) in dots {
        c.rect(dx - 1, dy - 1, p + 2, p + 2, ink)
        c.rect(dx + 1, dy + 1, p + 1, p + 1, ink)
    }
    for (dx, dy) in dots {
        c.rect(dx, dy, p, p, face)
        if !has(dx, dy - p) { c.rect(dx, dy, p, 1, lit) }
        if !has(dx - p, dy) { c.rect(dx, dy, 1, p, lit) }
        if !has(dx, dy + p) { c.rect(dx, dy + p - 1, p, 1, cut) }
        if !has(dx + p, dy) { c.rect(dx + p - 1, dy, 1, p, cut) }
    }
}
