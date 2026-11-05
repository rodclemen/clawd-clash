import CoreGraphics
import Foundation

// Recap Episode (`CrawlWipe.recap`), likelier with Odette, Zev or Cascadia and going to Odette's studio: the scene
// is a TV losing its signal, the dungeon's recap show cuts in with PREVIOUSLY ON... in the System's block letters
// (it's Odette's show, and the whole galaxy watches), and the picture tunes back in, rolling and tearing, onto the
// new place.

extension CrawlTrip {
    /// Recap Episode, `k` (0…1) through its own part, over the whole of `r`. TV static creeps in over the old place a
    /// speck at a time until it's all snow, a darker band rolling down through it (0–0.12); Odette's show cuts in: its
    /// mantis medallion over a black strip across the middle, PREVIOUSLY ON in big cream block letters, centred, the
    /// three dots tapping in one by one after them, and ODETTE'S AFTER HOURS in sage green under it (0.14–0.3); it
    /// holds, and breaks up back into the snow (0.44–0.52); the new place tunes in: the snow thins away, the picture
    /// rolls down the screen with the black blanking bar between frames, slower and slower until it settles, a few
    /// bands of it torn sideways and pulling straight (0.48–0.84); a last faint flicker of scan lines fades off it
    /// (to 0.94). Every speck of the snow is an art pixel, fresh about twenty times a second.
    func drawRecap(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.94 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let t = k * CrawlWipe.recap.effect
        let frame = Int(t * 20)
        let tune = Self.span(k, 0.48, 0.84)

        // The picture underneath: the old place until the snow has it all, then the new one, rolling and torn.
        if k < 0.48 {
            ctx.drawShot(old, in: r)
        } else {
            let roll = 1.6 * pow(1 - Self.span(k, 0.48, 0.82), 2)
            let rows = Int((frac(roll) * Double(h)).rounded())
            let off = CGFloat(rows) * art.px
            let tear = 1 - Self.span(k, 0.48, 0.74)
            ctx.drawShot(new, in: r.offsetBy(dx: 0, dy: -off))
            if rows > 0 { ctx.drawShot(new, in: r.offsetBy(dx: 0, dy: r.height - off)) }
            // Bands torn sideways, pulling straight.
            if tear > 0 {
                for i in 0..<4 {
                    let y0 = Int(noise(i * 11 + frame / 3 * 5) * Double(h - 10)), bh = 3 + Int(noise(i * 11 + 1) * 9)
                    let dx = CGFloat(Int((noise(i * 11 + 2 + frame) - 0.5) * Double(w) * 0.16 * tear)) * art.px
                    guard dx != 0 else { continue }
                    ctx.saveGState(); ctx.clip(to: art.frame(0, y0, w, bh))
                    ctx.drawShot(new, in: r.offsetBy(dx: dx, dy: -off))
                    if rows > 0 { ctx.drawShot(new, in: r.offsetBy(dx: dx, dy: r.height - off)) }
                    ctx.restoreGState()
                }
            }
            // The blanking bar between one frame and the next, as it rolls.
            if rows > 0 {
                let bar = max(3, h / 24)
                c.rect(0, rows - bar, w, bar * 2, C(0x050508))
                c.rect(0, rows - bar - 1, w, 1, C(0xFFFFFF, 0.35))
            }
        }

        // The snow: specks of grey, thick from the start to the tune-in, thinning away as the picture comes; a darker
        // band rolling down through it.
        let snow = k < 0.48 ? Self.span(k, 0, 0.12) : 1 - Self.ease(Self.span(tune, 0, 0.9))
        if snow > 0 {
            let greys = [C(0x18181C), C(0x4E4E56), C(0x8C8C96), C(0xC8C8D0), C(0xF2F2F8)]
            let band = Int(frac(t * 0.9) * Double(h + 30)) - 15
            let seed = frame * 7919
            for y in 0..<h {
                let dim = abs(y - band) < 12 ? 2 : 0
                for x in 0..<w {
                    let i = y * w + x
                    if snow < 1 && noise(i * 3 + seed + 1) >= snow { continue }
                    let v = Int(noise(i * 3 + seed) * Double(greys.count)) - dim
                    c.px(x, y, greys[max(0, min(greys.count - 1, v))])
                }
            }
        }

        // PREVIOUSLY ON..., flickering on, the dots tapping in, breaking up into the snow at the end.
        let on = Self.span(k, 0.14, 0.18), gone = Self.span(k, 0.44, 0.52)
        if on > 0 && gone < 1 && !(on < 1 && frame % 2 == 1) {
            let words = "PREVIOUSLY ON", dots = min(3, max(0, Int((k - 0.2) / 0.035)))
            let full = words + "..."
            var s = 4
            while s > 1 && crawlTextWidth(full, scale: s) > w * 82 / 100 { s -= 1 }
            if !art.wide && s > 3 { s = 3 }
            // The words alone are centred, so they don't move as the dots come; the dots hang off their end.
            let tw = crawlTextWidth(words, scale: s), th = 5 * s
            let show = "ODETTE'S AFTER HOURS"
            let ts = crawlTextWidth(show, scale: 2) <= w * 82 / 100 ? 2 : 1, showH = 5 * ts
            // Stacked and centred: the medallion, its foot over the strip's top edge, then the strip with both lines.
            let cell = art.wide ? 1 : 2, disc = 16 * cell
            let pad = 2 * s, gap = s + 2, stripH = pad + th + gap + showH + pad, over = pad - 2
            let top = (h - (2 * disc + stripH - over)) / 2
            let stripY = top + 2 * disc - over
            let x = (w - tw) / 2, y = stripY + pad
            let strip = PixelCanvas(w, h)
            strip.rect(0, stripY, w, stripH, C(0x060608, 0.9))
            strip.rect(0, stripY, w, max(1, s / 2), C(0xE23A3A))              // a thin red line, top and bottom
            strip.rect(0, stripY + stripH - max(1, s / 2), w, max(1, s / 2), C(0xE23A3A))
            crawlText(strip, (w - crawlTextWidth(show, scale: ts)) / 2, y + th + gap, show, C(0xA8D07A), scale: ts)
            recapMedallion(strip, w / 2, top + disc, cell: cell)
            let text = words + String(repeating: ".", count: dots)
            crawlText(strip, x + max(1, s / 2), y + max(1, s / 2), text, C(0x3A2A20), scale: s)   // a shadow under the cream
            crawlText(strip, x, y, text, C(0xFFF2D6), scale: s)
            if gone > 0 {
                // Breaking up: specks of it dropping out, more and more.
                for yy in 0..<h { for xx in 0..<w where noise((yy * w + xx) * 5 + frame * 31) < gone { strip.px(xx, yy, recapSpeck(xx, yy, frame)) } }
            }
            c.paste(strip)
        }

        // A last flicker of scan lines over the settled picture.
        let lines = Self.span(k, 0.78, 0.94)
        if lines > 0 && lines < 1 {
            let a = ((1 - lines) * 4).rounded(.up) / 4 * 0.22
            for y in stride(from: 0, to: h, by: 2) { c.rect(0, y, w, 1, C(0x000000, a)) }
        }
        art.show(ctx)
    }
}

/// The mantis of Odette's set, front on (the medallion in her studio, Scenes.crawlStudio).
private let recapMantis = [
    ".d.................d.",
    "..d...............d..",
    "...d.............d...",
    "....eegggggggggee....",
    ".....ggggggggggg.....",
    "......ggggggggg......",
    ".......ggdddgg.......",
    "........ggggg........",
    ".........ggg.........",
    "..........g..........",
    "..l.......g.......l..",
    "..ll......g......ll..",
    "...ll.....g.....ll...",
    "....lll..ggg..lll....",
    "......llgggggll......",
    ".........ggg.........",
    "........ggggg........",
    "........ggggg........",
    "........ggggg........",
    ".........ggg.........",
    "..........d..........",
]

/// The show's medallion centred on (`x`, `y`), `cell` art pixels to one of the mantis's: a cream ring, a dark sage
/// disc, the mantis on it, as it hangs on the studio's set.
private func recapMedallion(_ c: PixelCanvas, _ x: Int, _ y: Int, cell: Int) {
    c.circle(x, y, 16 * cell, C(0xC8B898)); c.circle(x, y, 15 * cell, C(0xE6D8BC)); c.circle(x, y, 13 * cell, C(0x22342A))
    c.circle(x - 2 * cell, y - 2 * cell, 9 * cell, C(0x2A3E32))
    let palette: [Character: Px] = ["d": C(0xA8D07A), "e": C(0xF0F4A8), "g": C(0x84B860), "l": C(0xB8E08A)]
    for (row, line) in recapMantis.enumerated() {
        for (col, ch) in line.enumerated() {
            if let p = palette[ch] { c.rect(x + (col - 10) * cell - cell / 2, y + (row - 10) * cell - cell / 2, cell, cell, p) }
        }
    }
}

/// A speck of snow for (`x`, `y`) on `frame`: one of the snow's greys.
private func recapSpeck(_ x: Int, _ y: Int, _ frame: Int) -> Px {
    let g: [UInt32] = [0x4E4E56, 0x8C8C96, 0xC8C8D0, 0xF2F2F8]
    return C(g[Int(noise(x * 7 + y * 131 + frame * 7919) * Double(g.count)) % g.count])
}
