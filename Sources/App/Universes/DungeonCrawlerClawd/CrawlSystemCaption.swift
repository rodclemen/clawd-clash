import CoreGraphics
import Foundation

// The finishing touch of every Dungeon Crawler Clawd trip: a small blue System notification slides down into the
// top-left corner with the new place's name, ENTERING: over it, the way the System tells the crawlers where they are.
// The same box as New Achievement!'s (CrawlAchievement.swift): navy, a bright blue frame lit on the top and left, a
// soft blue glow, the System's block letters (`crawlText`). It lands with a white flash, stays to be read and slides
// back up. Up in the corner it keeps clear of the crew, who stand along the bottom.

extension CrawlTrip {
    /// The System box, `t` seconds into it (0…`caption`), over the whole of `r`: it drops in (0 to 0.2 s), flashes as
    /// it lands, stays (to 1.3 s) and slides back up out of the frame (to the end).
    func drawSystemCaption(_ ctx: CGContext, t: Double, in r: CGRect) {
        let art = CrawlArt(r)
        let c = art.c, w = art.w
        let head = "ENTERING:", name = crawlSystemName(to)
        // Two art pixels a dot where the name fits in about half the frame, one where it doesn't.
        let s = crawlTextWidth(name, scale: 2) + 12 <= w * 11 / 20 ? 2 : 1
        let nameW = crawlTextWidth(name, scale: s), headW = crawlTextWidth(head)
        let bw = max(nameW, headW) + 8, bh = 4 + 5 + 3 + 5 * s + 4
        let x = art.wide ? 8 : 10, rest = art.wide ? 6 : 10
        let drop = Self.ease(Self.span(t, 0, 0.2)), lift = Self.ease(Self.span(t, 1.3, Self.caption))
        let y = rest - Int(((1 - drop) + lift) * Double(rest + bh + 4))
        let flash = t > 0.2 && t < 0.45 ? 1 - (t - 0.2) / 0.25 : 0
        let navy = C(0x0E2A6A, 0.94), lit = lerp(C(0x6AB4FF), C(0xFFFFFF), flash), deep = lerp(C(0x2A64C8), C(0xFFFFFF), flash)
        let halo = C(0x3A8CFF, 0.24 + 0.5 * flash)

        c.rect(x - 2, y - 1, bw + 4, bh + 2, halo)
        c.rect(x - 1, y - 2, bw + 2, 1, halo); c.rect(x - 1, y + bh + 1, bw + 2, 1, halo)
        c.rect(x, y, bw, bh, navy)
        c.rect(x, y, bw, 1, lit); c.rect(x, y, 1, bh, lit)
        c.rect(x, y + bh - 1, bw, 1, deep); c.rect(x + bw - 1, y, 1, bh, deep)
        crawlText(c, x + 4, y + 4, head, C(0x9CD8FF))
        c.rect(x + 3, y + 10, bw - 6, 1, C(0x2A64C8))
        crawlText(c, x + 4, y + 13 + s, name, C(0x08184A), scale: s)          // a shadow under the name
        crawlText(c, x + 4, y + 12, name, C(0xF0F6FF), scale: s)
        art.show(ctx)
    }
}

/// The name the System box gives a place: its own name in capitals, cut at the first comma ("CARL'S STREET",
/// "HAVANA"), so the box stays small.
func crawlSystemName(_ l: Location) -> String {
    String(l.name.split(separator: ",").first ?? Substring(l.name)).uppercased()
}
