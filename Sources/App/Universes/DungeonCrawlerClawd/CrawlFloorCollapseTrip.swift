import CoreGraphics
import Foundation

// Floor Collapse (`CrawlWipe.floorCollapse`), likelier with Mordecai or Cascadia: a big red countdown ticks to
// 00:00:00, and the old floor crumbles away, revealing the new place below.

extension CrawlTrip {
    /// Floor Collapse, `k` (0…1) through its own part, over the whole of `r`. A big red countdown slams up in the
    /// middle of the old place, 00:00:03, in the System's block letters with a dark edge so it reads on anything, and
    /// ticks down a second at a time to 00:00:00, each tick a flash and a red pulse round the frame, the ground
    /// shaking harder as it goes (0.04–0.36). At zero it blinks (0.36–0.46) while cracks run across the old place
    /// along a grid of chunky blocks, each block cracking just before it goes. Then the floor gives way: the
    /// blocks drop one after another, the middle of the floor first and the edges and the top last, each falling
    /// faster as it goes and darkening, a rim of stone along its edges and dust puffing up where it was (0.36–0.92).
    /// Below, the new place, in shadow at first, lighting up as the last of the old floor goes (0.55–0.97).
    func drawFloorCollapse(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 1 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h, px = art.px

        // The blocks: rows of them, every other row staggered by half a block, about six rows to the frame.
        let bs = max(10, h / 6)
        let rows = (h + bs - 1) / bs, cols = w / bs + 2
        struct Block { let x: Int, y: Int, w: Int, start: Double }
        var blocks: [Block] = []
        for row in 0..<rows {
            let off = row % 2 == 0 ? 0 : -bs / 2
            for col in 0..<cols {
                let x0 = max(0, off + col * bs), x1 = min(w, off + (col + 1) * bs)
                guard x1 > x0 else { continue }
                // From the middle of the floor out: distance from the bottom middle, across and up.
                let mx = Double(x0 + x1) / 2, my = Double(row * bs + bs / 2)
                let dx = abs(mx - Double(w) / 2) / Double(w / 2), dy = (Double(h) - my) / Double(h)
                let far = min(1, (dx * dx * 0.8 + dy * dy * 1.1).squareRoot())
                let start = 0.36 + 0.32 * far + 0.05 * noise(row * 37 + col * 11 + 300)
                blocks.append(Block(x: x0, y: row * bs, w: x1 - x0, start: start))
            }
        }
        func drop(_ b: Block) -> Double {
            let t = (k - b.start) / 0.2
            return t > 0 ? Double(h) * 1.25 * t * t : 0
        }

        // The ground shaking with the countdown, hardest at zero, and as the floor goes.
        let quake = Self.span(k, 0.04, 0.36) * (1 - Self.span(k, 0.5, 0.6))
        let f = Int(k * 50)
        let sx = Int(((noise(f * 7 + 1) * 2 - 1) * 2 * quake).rounded()), sy = Int(((noise(f * 7 + 2) * 2 - 1) * 1.4 * quake).rounded())
        let shake = CGVector(dx: CGFloat(sx) * px, dy: CGFloat(sy) * px)

        // The new place, below, in shadow until the old floor has gone.
        ctx.drawShot(new, in: r)
        Self.wash(ctx, 0x0A0608, 0.8 * (1 - Self.span(k, 0.55, 0.97)), in: r)

        // The old floor where it still stands, in one piece, then each falling block on its own.
        let standing = blocks.filter { drop($0) == 0 }
        if !standing.isEmpty {
            ctx.saveGState()
            ctx.clip(to: standing.map { art.frame($0.x, $0.y, $0.w, bs) })
            // A touch bigger while it shakes, so no gap opens at the frame's edges.
            let grow = quake > 0 ? -2 * px : 0
            ctx.drawShot(old, in: r.insetBy(dx: grow, dy: grow).offsetBy(dx: shake.dx, dy: -shake.dy))
            ctx.restoreGState()
        }
        for b in blocks {
            let dy = drop(b)
            guard dy > 0, Double(b.y) + dy < Double(h) else { continue }
            let iy = Int(dy.rounded()), drift = Int(((noise(b.x * 3 + b.y + 77) - 0.5) * dy * 0.12).rounded())
            ctx.saveGState()
            ctx.clip(to: art.frame(b.x + drift, b.y + iy, b.w, bs))
            ctx.drawShot(old, in: r.offsetBy(dx: CGFloat(drift) * px, dy: -CGFloat(iy) * px))
            Self.wash(ctx, 0x0A0608, min(0.375, dy / Double(h)), in: r)
            ctx.restoreGState()
        }

        // The art: cracks along the blocks, the rims of the falling ones, dust, and the countdown.
        let stone = C(0x6A6670), stoneD = C(0x2E2C34), rift = C(0x1A0E0E)
        for b in blocks {
            let dy = drop(b)
            if dy == 0 {
                // A block cracks just before it goes: a jagged split along part of its top and down part of its
                // side, so the cracks spread through the floor in the order it falls.
                let lead = b.start - k
                guard lead < 0.08 else { continue }
                let x = b.x + sx, y = b.y + sy, n = noise(b.x * 7 + b.y * 13 + 11)
                let top = Int(Double(b.w) * (0.35 + 0.65 * (1 - lead / 0.08)))
                let side = Int(Double(bs) * (0.3 + 0.7 * (1 - lead / 0.08)))
                let tx = n < 0.5 ? x : x + b.w - top
                for i in 0..<top { c.px(tx + i, y + ((i / 3 + b.y) % 3 == 0 ? 1 : 0), rift) }
                for i in 0..<side { c.px(x + ((i / 2 + b.x) % 3 == 0 ? 1 : 0), y + i, rift) }
            } else if Double(b.y) + dy < Double(h) {
                let iy = Int(dy.rounded()), drift = Int(((noise(b.x * 3 + b.y + 77) - 0.5) * dy * 0.12).rounded())
                let x = b.x + drift, y = b.y + iy
                c.rect(x, y, b.w, 1, stone); c.rect(x, y, 1, bs, stone)
                c.rect(x, y + bs - 2, b.w, 2, stoneD); c.rect(x + b.w - 1, y, 1, bs, stoneD)
                // Dust where it was, puffing up and thinning out.
                let age = Self.clamp((k - b.start) / 0.14)
                if age < 1 {
                    for n in 0..<5 {
                        let ux = b.x + Int(noise(b.x * 13 + b.y * 3 + n) * Double(b.w))
                        let uy = b.y + bs - Int(age * Double(bs) * (0.4 + noise(b.x + n * 7) * 0.6))
                        let size = 1 + Int(noise(n + b.y) * 2)
                        c.rect(ux, uy, size, size, C(0x9A9088, 0.7 * (1 - age)))
                    }
                }
            }
        }
        crawlCollapseCountdown(c, k: k, w: w, h: h, sx: sx, sy: sy, wide: art.wide)
        art.show(ctx)
    }

    /// How much of the crew shows `k` (0…1) through its own part: all of them while the countdown runs, fading as
    /// the floor drops away under them (0.36–0.48), gone while they fall, and back as the new place lights up
    /// (0.84–0.97), where they've landed.
    func floorCollapseCrewShown(_ k: Double) -> Double {
        if k < 0.6 { return 1 - Self.span(k, 0.36, 0.48) }
        return Self.span(k, 0.84, 0.97)
    }

    /// The countdown, 00:00:03 to 00:00:00, in the middle of the frame (moved with the shaking by `sx`, `sy`): big
    /// red block letters with a dark edge, a white flash on each tick and a red pulse round the frame; at zero it
    /// blinks and is gone by 0.46.
    private func crawlCollapseCountdown(_ c: PixelCanvas, k: Double, w: Int, h: Int, sx: Int, sy: Int, wide: Bool) {
        let ticks = [0.04, 0.14, 0.24, 0.34]
        guard k >= ticks[0], k < 0.46 else { return }
        let n = ticks.lastIndex(where: { k >= $0 }) ?? 0
        let since = k - ticks[n]
        if n == 3 && Int(since / 0.03) % 2 == 1 { return }                        // zero blinks
        let text = "00:00:0\(3 - n)"
        let s = max(2, min(wide ? 4 : 6, (w * 3 / 5) / crawlTextWidth(text)))
        let tw = crawlTextWidth(text, scale: s), th = 5 * s
        let x = (w - tw) / 2 + sx, y = (h - th) / 2 - h / 10 + sy
        let flash = max(0, 1 - since / 0.04)

        // The pulse round the frame, on every tick.
        let pulse = max(0, 1 - since / 0.08)
        if pulse > 0 {
            for i in 0..<3 {
                let a = 0.55 * pulse * (1 - Double(i) / 3)
                let col = C(0xFF2020, a)
                c.rect(i, i, w - 2 * i, 1, col); c.rect(i, h - 1 - i, w - 2 * i, 1, col)
                c.rect(i, i + 1, 1, h - 2 - 2 * i, col); c.rect(w - 1 - i, i + 1, 1, h - 2 - 2 * i, col)
            }
        }
        // A dark band behind it, the edge round each letter, then the letters, a deeper red along their foot.
        c.rect(x - s * 2, y - s * 2, tw + s * 4, th + s * 4, C(0x1A0404, 0.55))
        let edge = C(0x2A0000)
        for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (1, -1), (-1, 1), (1, 1)] {
            crawlText(c, x + dx * max(1, s / 2), y + dy * max(1, s / 2), text, edge, scale: s)
        }
        crawlText(c, x, y + s / 2, text, C(0x9A0A10), scale: s)
        crawlText(c, x, y, text, lerp(C(0xFF2A2A), C(0xFFFFFF), flash * 0.8), scale: s)
    }
}
