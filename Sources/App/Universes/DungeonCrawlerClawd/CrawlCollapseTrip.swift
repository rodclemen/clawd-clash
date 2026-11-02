import CoreGraphics
import Foundation

// The Collapse (`CrawlWipe.collapse`), the signature trip, the longest and the rarest, likelier going to Carl's street;
// the trailer opens on it too. Night street, rain; the ground cracks and the buildings sink into the earth; a blue
// System box slams in, WELCOME, CRAWLER!; a glittering game-show title, DUNGEON CRAWLER CLAWD in the System's
// letters, sweeps up; and the view drops through the floor into the new place.

extension CrawlTrip {
    /// The Collapse, `k` (0…1) through its own part (3.4 s), over the whole of `r`. Rain sweeps in and Carl's street
    /// comes up over the old place in a dither, at night: the low city under a rain-heavy sky, Carl's red brick block
    /// with its fire escape and his lit window, the grey-green corner building with its striped awning, a street lamp's
    /// orange cone, a dark tower with a red beacon, the wet street shining (0.02–0.12). Lightning flickers twice
    /// (0.13–0.18). Cracks race out across the pavement and the street, black with the System's blue light in them,
    /// and the street starts to shake (0.16–0.3); one by one the buildings sink straight down into the earth, leaning
    /// as they go, dust puffing at their feet and blue light pouring up out of the gaps, the lamp sputtering out, the
    /// low city last (0.2–0.42). A big System box slams down into the middle, WELCOME, CRAWLER! in gold, landing with
    /// a white flash and a jolt (0.34–0.41), and stays to be read; the title sweeps up from the bottom and knocks it
    /// off the top (0.5–0.6): DUNGEON CRAWLER CLAWD in big gold block letters, an orange-brown edge under them, on a
    /// purple game-show plate ringed with chasing bulbs, purple rays turning behind it. It glitters, a shine running
    /// across the letters and stars twinkling on them (0.58–0.76), while the cracks blaze wider (0.66–0.74). Then the
    /// floor gives way: the whole street, title and all, shoots up out of the top, its broken earth and the blue
    /// cracks running through it going past (0.74–0.84), into a deep blue fall, streaks of System blue rushing up;
    /// the new place comes up from below (0.8–0.9), lands with a bump (0.9–0.95) and the dust settles (to 0.99).
    func drawCollapse(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        let art = CrawlArt(r)
        let w = art.w, h = art.h
        let t = k * CrawlWipe.collapse.effect
        let tick = Int(t / 0.05)
        let come = Self.span(k, 0.02, 0.12)
        let drop = Self.span(k, 0.74, 0.84), rise = Self.span(k, 0.8, 0.9), land = Self.span(k, 0.9, 0.95)
        let earth = art.wide ? 22 : 30
        let lift = Int((pow(drop, 1.7) * Double(h + earth + 2)).rounded())

        // The street shakes while it goes down, and again as the box slams in.
        var shake = 0
        if (k > 0.18 && k < 0.4) || (k > 0.37 && k < 0.43) { shake = Int(((noise(tick * 3 + 1) - 0.5) * 5).rounded()) }

        if come < 1 { ctx.drawShot(old, in: r) }
        // Under the street, once it starts to go: the fall, and the new place coming up out of it.
        if drop > 0 {
            let fall = CrawlArt(r)
            crawlCollapseFall(fall.c, t: t)
            fall.show(ctx)
            if rise > 0 {
                let off = land > 0 ? -sin(land * .pi) * 3 : (1 - pow(rise, 1.3)) * Double(h)
                ctx.drawShot(new, in: r.offsetBy(dx: 0, dy: -CGFloat(Int(off.rounded())) * art.px))
            }
        }
        // The street, with the box and the title over it, on a canvas a little wider than the frame (for the shake)
        // and deeper (for the earth under it).
        if lift < h + earth {
            let world = PixelCanvas(w + 6, h + earth)
            world.ox = 3
            crawlCollapseStreet(world, w: w, h: h, earth: earth, k: k, t: t, wide: art.wide)
            crawlCollapseBox(world, w: w, h: h, k: k, wide: art.wide)
            crawlCollapseTitle(world, w: w, h: h, k: k, t: t, wide: art.wide)
            if come < 1 {
                // Dithered in over the old place, an ordered pattern of pixels at a time.
                for y in 0..<h {
                    for x in 0..<w where crawlCollapseBayer[(y % 4) * 4 + x % 4] < come {
                        let i = (y * world.w + x + 3) * 4
                        if world.buf[i + 3] > 0 { art.c.px(x, y, unpremultiplied(world, i)) }
                    }
                }
            } else {
                art.c.paste(world, x: shake - 3, y: -lift)
            }
        }
        // Landed: dust puffing up along the floor and settling.
        let dust = Self.span(k, 0.9, 0.99)
        if dust > 0 && dust < 1 {
            let a = ((1 - dust) * 4).rounded() / 4 * 0.5
            for j in 0..<12 {
                let x = Int(Double(w) * (Double(j) + 0.5) / 12 + (noise(j * 7 + 3) - 0.5) * 10)
                let y = h - 3 - Int(dust * Double(6 + j % 3 * 2))
                art.c.ellipse(x, y, 5 + j % 3 * 2, 2 + j % 2, C(0x9A9AA8, a))
            }
        }
        art.show(ctx)
    }

    /// The crew go with the old place: they fade as the street comes up over it (0.02–0.1), stay away while the
    /// street collapses and the view falls, and come back as the new place lands (0.9–0.97).
    func collapseCrewShown(_ k: Double) -> Double {
        1 - Self.ease(Self.span(k, 0.02, 0.1)) + Self.ease(Self.span(k, 0.9, 0.97))
    }
}

/// A 4×4 ordered dither, thresholds in 0…1.
private let crawlCollapseBayer: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

/// The fall under the street, `t` seconds in: deep System blue, streaks of brighter blue rushing up past.
private func crawlCollapseFall(_ c: PixelCanvas, t: Double) {
    c.rect(0, 0, c.w, c.h, C(0x081430))
    let count = max(20, c.w * c.h / 900)
    for i in 0..<count {
        let len = 6 + Int(noise(i * 5 + 2) * 12)
        let loop = Double(c.h + len + 8)
        let y = Int((noise(i * 5 + 1) * loop - t * Double(c.h) * (2.4 + noise(i * 5 + 3))).truncatingRemainder(dividingBy: loop) + loop)
            % Int(loop) - len
        let x = Int(noise(i * 5) * Double(c.w))
        let thick = noise(i * 5 + 4) > 0.6 ? 2 : 1
        c.rect(x, y, thick, len, C(0x2A64C8))
        c.rect(x, y, thick, 2, C(0x9CD8FF))
    }
}

/// Carl's street, the night of the collapse, `k` through the trip: the sky, the low city, the four buildings and the
/// lamp (each sinking in its turn), the pavement and the street, the earth under it (`earth` rows below the frame),
/// the cracks and the rain. Drawn `w` by `h`, in the spirit of the place itself (CrawlScenes4.swift).
private func crawlCollapseStreet(_ c: PixelCanvas, w: Int, h: Int, earth: Int, k: Double, t: Double, wide: Bool) {
    let gb = h - (wide ? 18 : 28)                // the pavement's top, where the buildings stand
    let tick = Int(t / 0.05)

    // The sky: rain cloud in bands, dark overhead, dull orange-grey low down; white with the lightning.
    let flash = (k > 0.13 && k < 0.15) || (k > 0.163 && k < 0.178)
    let bands = 6, bandH = (gb + bands - 1) / bands
    for i in 0..<bands {
        let col = CrawlTrip.mix(0x0C101C, 0x2E2A38, Double(i) / Double(bands - 1))
        c.rect(-3, i * bandH, w + 6, bandH, flash ? lerp(col, C(0xB8C0E0), 0.55) : col)
    }

    // The low city behind: flat roofs, a lit window here and there; it goes down last.
    let far = CrawlTrip.span(k, 0.28, 0.42)
    let farDrop = Int(far * far * Double(h) * 0.5)
    var fx = -3, n = 0
    while fx < w + 3 {
        let bw = 14 + Int(noise(n * 5 + 2) * 12)
        let tall = Int(Double(h) * (0.16 + noise(n * 13 + 7) * 0.22))
        let top = gb - tall + farDrop
        if top < gb {
            c.rect(fx, top, bw, gb - top, C(0x1A1E2A)); c.rect(fx, top, bw, 1, C(0x2C3242))
            for wy in stride(from: top + 3, to: gb - 3, by: 5) {
                for wx in stride(from: fx + 2, to: fx + bw - 3, by: 4) where noise(n * 97 + wx * 3 + wy * 7) > 0.8 {
                    c.rect(wx, wy, 2, 2, C(0x9A7A48))
                }
            }
        }
        fx += bw + 2 + Int(noise(n * 3) * 6); n += 1
    }

    // The blue light of the cracks, coming up behind everything once the ground has split.
    let glow = (CrawlTrip.span(k, 0.22, 0.4) * 4).rounded() / 4
    if glow > 0 {
        for i in 0..<4 { c.rect(-3, gb - (i + 1) * 4, w + 6, 4, C(0x3A8CFF, glow * (0.34 - Double(i) * 0.08))) }
    }

    // The buildings, each sinking in its turn: how far down it is (0 standing, 1 gone), easing in as it gives way.
    func sunk(_ start: Double) -> Double { let v = CrawlTrip.span(k, start, start + 0.14); return v * v }
    let a = crawlCollapseBlock(w * 30 / 100, h * 62 / 100), aSink = sunk(0.23)
    let b = crawlCollapseCorner(max(40, w * 16 / 100), h * 42 / 100), bSink = sunk(0.2)
    let cTower = crawlCollapseTower(max(30, w * 17 / 100), h * 76 / 100, tick: tick), cSink = sunk(0.25)
    let dx0 = w * 77 / 100
    let d = crawlCollapseRight(w - dx0 + 3, h * 52 / 100), dSink = sunk(0.22)
    let lampSink = sunk(0.21)
    let stands: [(PixelCanvas, Int, Double, Int)] = [
        (a, 0, aSink, -4), (b, w * 33 / 100, bSink, 6), (cTower, w * 55 / 100, cSink, 5), (d, dx0, dSink, -3),
    ]
    for (img, x0, s, lean) in stands { crawlCollapseSink(c, img, x0: x0, base: gb, sunk: s, lean: lean) }

    // The street lamp between the corner building and the tower, its orange cone sputtering out as it goes down.
    let lx = w * 52 / 100, lampH = h * 40 / 100
    let lampDrop = Int(lampSink * Double(lampH + 6))
    let headY = gb - lampH + lampDrop
    let lit = lampSink < 0.25 && !(lampSink > 0 && noise(tick * 5 + 9) > 0.5)
    if lampSink < 1 {
        if lit {
            for i in 0..<max(0, gb - headY - 2) {
                let spread = 1 + i * 11 / 20
                c.rect(lx - spread, headY + 2 + i, 2 * spread, 1, C(0xFFA040, 0.12))
            }
        }
        let poleTop = headY - 2
        if poleTop < gb {
            c.rect(lx - 10, poleTop, 2, gb - poleTop, C(0x3A3E48)); c.rect(lx - 10, poleTop, 1, gb - poleTop, C(0x525664))
            c.rect(lx - 10, poleTop, 11, 1, C(0x3A3E48)); c.rect(lx - 3, poleTop + 1, 6, 2, C(0x2A2E36))
            if poleTop + 3 < gb { c.rect(lx - 2, poleTop + 3, 4, 1, lit ? C(0xFFC870) : C(0x5A5040)) }
        }
    }

    // The pavement: concrete slabs, their joints dark, the kerb's lip; then the wet street, the lamp and the lit
    // windows broken up in it, a faded line down the middle.
    c.rect(-3, gb, w + 6, 5, C(0x363A44)); c.rect(-3, gb, w + 6, 1, C(0x464A56))
    for x in stride(from: 4, to: w, by: 18) { c.rect(x, gb + 1, 1, 4, C(0x2A2E36)) }
    c.rect(-3, gb + 5, w + 6, 2, C(0x4A4E5A))
    c.rect(-3, gb + 7, w + 6, h - gb - 7, C(0x1C2028))
    for y in stride(from: gb + 9, to: h, by: 2) {
        if lit { c.rect(lx - 3 + Int(noise(y) * 4), y, 3, 1, C(0xFFA040, 0.3)) }
        if aSink < 0.5 { c.rect(w * 12 / 100 + Int(noise(y + 9) * 3), y, 2, 1, C(0xF0C878, 0.18)) }
    }
    let mid = gb + 7 + (h - gb - 7) * 2 / 3
    for x in stride(from: 4, to: w, by: 20) { c.rect(x, mid, 9, 1, C(0x8A7A40, 0.5)) }
    // The earth under it all, seen as the floor goes up: a dark layer of soil, stones, a broken pipe, the bottom edge
    // ragged where it tore away.
    c.rect(-3, h, w + 6, 2, C(0x3A2E26))
    for x in -3..<(w + 3) {
        let bottom = h + earth - Int(noise(x / 3 + 211) * 7)
        c.rect(x, h + 2, 1, bottom - h - 2, C(0x2A201C))
    }
    for i in 0..<(w / 9) {
        let sx = Int(noise(i * 3 + 61) * Double(w)), sy = h + 3 + Int(noise(i * 3 + 62) * Double(earth - 10))
        c.rect(sx, sy, 3, 2, C(0x4A3E36)); c.rect(sx, sy, 3, 1, C(0x5A4E44))
    }
    c.rect(-3, h + earth / 3, w * 2 / 5, 3, C(0x5A5E6A)); c.rect(-3, h + earth / 3, w * 2 / 5, 1, C(0x7A7E8A))

    // The gaps the buildings leave: black slots in the pavement, the System's blue at the bottom of each, its light
    // pouring up, and dust puffing at the feet of those still going down.
    for (img, x0, s, _) in stands where s > 0 {
        c.rect(x0 - 2, gb - 1, img.w + 4, 3, C(0x0C0E14)); c.rect(x0, gb + 1, img.w, 1, C(0x6AB4FF))
        let beam = (min(1, s * 3) * 4).rounded() / 4
        c.rect(x0, gb - 26, img.w, 25, C(0x3A8CFF, 0.14 * beam)); c.rect(x0 + 3, gb - 14, max(1, img.w - 6), 13, C(0x6AB4FF, 0.14 * beam))
        if s < 1 {
            for j in 0..<6 {
                let ph = frac(t * 1.3 + Double(j) * 0.19)
                let px = x0 + Int(Double(img.w) * noise(j * 13 + x0))
                let py = gb - 2 - Int(ph * 14)
                c.ellipse(px, py, 4 + j % 3, 2 + j % 2, C(0x8A8A94, ((1 - ph) * 4).rounded() / 4 * 0.6))
            }
        }
    }

    // The cracks: out from the buildings' feet across the pavement and the street, and down through the earth,
    // black edged with the System's blue in them, widening and blazing white-blue just before the floor goes.
    let grow = CrawlTrip.span(k, 0.16, 0.3), blaze = CrawlTrip.span(k, 0.66, 0.74)
    let starts: [(Int, Int)] = [(w * 41 / 100, 1), (w * 41 / 100, -1), (w * 63 / 100, 1), (w * 15 / 100, 1),
                                (w * 87 / 100, -1), (w * 63 / 100, -1)]
    for (i, s) in starts.enumerated() {
        let g = CrawlTrip.span(grow, Double(i) * 0.08, Double(i) * 0.08 + 0.55)
        guard g > 0 else { continue }
        var pts: [(Int, Int)] = [(s.0, gb + 2)]
        var x = s.0, y = gb + 2
        for step in 0..<12 {
            x += s.1 * (3 + Int(noise(i * 41 + step * 7) * 5))
            y = min(h - 2, y + Int(noise(i * 29 + step * 3) * 3))
            pts.append((x, y))
        }
        crawlCollapseCrack(c, pts, part: g, blaze: blaze)
        // Down through the earth from where it starts.
        var down: [(Int, Int)] = [(s.0, h + 1)]
        var ex = s.0
        for step in 0..<5 {
            ex += Int((noise(i * 17 + step * 5) - 0.5) * 8)
            down.append((ex, h + (step + 1) * earth / 5))
        }
        crawlCollapseCrack(c, down, part: g, blaze: blaze)
    }

    // The rain, thin pale streaks falling slantwise over everything, and splashes on the street.
    let count = w * h / 70
    let loop = Double(h + 12)
    for i in 0..<count {
        let speed = 1.6 + noise(i * 7 + 2) * 0.5
        let y = Int((noise(i * 7 + 1) * loop + t * Double(h) * speed).truncatingRemainder(dividingBy: loop)) - 6
        let x = Int(noise(i * 7) * Double(w + 30)) - y / 4
        for j in 0..<5 where y + j < gb + 7 || noise(i) > 0.4 { c.px(x - j / 4, y + j, C(0xB8C8E8, 0.45)) }
    }
    for j in 0..<10 {
        let sx = Int(noise(tick * 11 + j) * Double(w)), sy = gb + 8 + Int(noise(tick * 13 + j) * Double(max(1, h - gb - 9)))
        c.rect(sx - 1, sy, 3, 1, C(0xB8C8E8, 0.5))
    }
}

/// A building drawn on its own (`img`, standing on `base` at `x0`) into the street, `sunk` of the way down into the
/// earth, its `lean` (pixels across its width, either way) tipping it as it goes. Whatever's sunk below the pavement
/// is covered by it, drawn after.
private func crawlCollapseSink(_ c: PixelCanvas, _ img: PixelCanvas, x0: Int, base: Int, sunk: Double, lean: Int) {
    guard sunk < 1 else { return }
    let drop = sunk * Double(img.h + 6)
    for col in 0..<img.w {
        let tip = Double(abs(lean)) * Double(lean > 0 ? col : img.w - col) / Double(max(1, img.w))
        let off = Int((drop + sunk * tip).rounded())
        for row in 0..<img.h {
            let y = base - img.h + row + off
            guard y < base else { break }
            let i = (row * img.w + col) * 4
            if img.buf[i + 3] > 0 { c.px(x0 + col, y, unpremultiplied(img, i)) }
        }
    }
}

/// A crack along `pts`, the first `part` of it: two pixels of black with the System's blue down its middle, wider
/// and paler as it `blaze`s.
private func crawlCollapseCrack(_ c: PixelCanvas, _ pts: [(Int, Int)], part: Double, blaze: Double) {
    guard pts.count > 1, part > 0 else { return }
    let along = part * Double(pts.count - 1)
    let core = blaze > 0.5 ? C(0xE8F4FF) : blaze > 0 ? C(0x9CD8FF) : C(0x6AB4FF)
    let width = blaze > 0.5 ? 2 : 1
    for i in 1..<pts.count where Double(i - 1) < along {
        let a = pts[i - 1], b = pts[i]
        let f = min(1, along - Double(i - 1))
        let n = max(1, max(abs(b.0 - a.0), abs(b.1 - a.1)))
        let steps = Int(Double(n) * f)
        for s in 0...steps {
            let x = a.0 + (b.0 - a.0) * s / n, y = a.1 + (b.1 - a.1) * s / n
            c.rect(x - 1, y - 1, width + 2, width + 1, C(0x0C0E14))
        }
        for s in 0...steps {
            let x = a.0 + (b.0 - a.0) * s / n, y = a.1 + (b.1 - a.1) * s / n
            c.rect(x, y - 1, width, width, core)
        }
    }
}

/// Carl's apartment block, `w` by `h`: dull red brick in courses with a stone cap, rows of windows (some lit warm,
/// one blue with a TV, most dark), Carl's own lit on the bottom row with its curtains drawn back, a black iron fire
/// escape down its right side, its edge in shadow, and the door with a lamp over it.
private func crawlCollapseBlock(_ w: Int, _ h: Int) -> PixelCanvas {
    let c = PixelCanvas(w, h)
    let brick = C(0x4E2E2E), brickD = C(0x3C2224), brickL = C(0x60383A), frame = C(0x2A1A1A), sill = C(0x6A5A52)
    c.rect(0, 0, w, h, brick)
    for y in stride(from: h - 3, to: 3, by: -3) {
        c.rect(0, y, w, 1, brickD)
        for x in stride(from: (y / 3) % 2 * 3, to: w, by: 6) where noise(x * 3 + y) > 0.6 { c.rect(x, y + 1, 2, 1, brickL) }
    }
    c.rect(0, 0, w, 3, C(0x5A4A44)); c.rect(0, 0, w, 1, C(0x7A6A62))
    var row = 0
    var wy = 7
    while wy + 10 < h - 12 {
        var col = 0
        for x in stride(from: 5, to: w - 14, by: 13) {
            let carl = wy + 10 + 15 >= h - 12 && col == 1
            let n = noise(row * 41 + col * 17 + 5)
            let pane = carl ? C(0xF0C878) : n > 0.78 ? C(0xE0B868) : n > 0.7 ? C(0x7A9AD8) : C(0x141A26)
            c.rect(x - 1, wy - 1, 10, 12, frame); c.rect(x, wy, 8, 10, pane)
            c.rect(x + 4, wy, 1, 10, frame); c.rect(x, wy + 5, 8, 1, frame)
            if carl { c.rect(x, wy, 2, 10, C(0xA85838)); c.rect(x + 6, wy, 2, 10, C(0xA85838)) }
            c.rect(x - 1, wy + 11, 10, 1, sill)
            col += 1
        }
        row += 1; wy += 15
    }
    // The fire escape: a landing under each row of windows, railings, a stair between.
    let fe = w - 20
    for base in stride(from: 19, to: h - 12, by: 15) {
        c.rect(fe, base, 14, 1, C(0x121318)); c.rect(fe, base - 4, 14, 1, C(0x121318))
        for x in stride(from: fe, through: fe + 14, by: 4) { c.rect(x, base - 4, 1, 4, C(0x121318)) }
        for s in 0..<12 where base + 1 + s < h - 12 { c.rect(fe + 12 - s, base + 1 + s, 1, 1, C(0x121318)) }
    }
    c.rect(w - 3, 3, 3, h - 3, C(0x2E1A1C))
    // The door, a recess with a lamp over it.
    c.rect(6, h - 15, 14, 15, C(0x3A2A26)); c.rect(8, h - 13, 10, 13, C(0x241818)); c.rect(9, h - 12, 8, 4, C(0x8A7050))
    c.rect(11, h - 18, 4, 2, C(0xF0D090))
    return c
}

/// The corner building, `w` by `h`: grey-green stucco lit on its left, a cornice, windows (a few lit), and the corner
/// shop at the bottom under a striped red and cream awning, its window lit.
private func crawlCollapseCorner(_ w: Int, _ h: Int) -> PixelCanvas {
    let c = PixelCanvas(w, h)
    c.rect(0, 0, w, h, C(0x4A5A5E)); c.rect(0, 0, 2, h, C(0x5A6A6E)); c.rect(w - 3, 0, 3, h, C(0x38464A))
    c.rect(0, 0, w, 3, C(0x3A4448)); c.rect(0, 0, w, 1, C(0x5E6A6E))
    var r = 0
    for wy in stride(from: 6, to: h - 22, by: 12) {
        var k = 0
        for x in stride(from: 4, to: w - 9, by: 11) {
            let lit = (r + k) % 3 == 1
            c.rect(x - 1, wy - 1, 8, 10, C(0x2A3236)); c.rect(x, wy, 6, 8, lit ? C(0xD8B068) : C(0x141A22))
            c.rect(x + 3, wy, 1, 8, C(0x2A3236))
            k += 1
        }
        r += 1
    }
    for s in 0..<(w / 4 + 1) { c.rect(s * 4, h - 14, 4, 3, s % 2 == 0 ? C(0x8A3030) : C(0xB8B0A0)) }
    c.rect(0, h - 11, w, 1, C(0x2A2424))
    c.rect(3, h - 9, w * 3 / 5, 8, C(0x2A3236)); c.rect(4, h - 8, w * 3 / 5 - 2, 7, C(0xC8A858))
    c.rect(w - 11, h - 10, 7, 10, C(0x1A1E22))
    return c
}

/// The dark tower, `w` by `h`: a slab of night grey, its left edge catching the light, rows of small windows (some
/// lit), an aerial on top with a red beacon blinking.
private func crawlCollapseTower(_ w: Int, _ h: Int, tick: Int) -> PixelCanvas {
    let c = PixelCanvas(w, h)
    let top = 10
    c.rect(0, top, w, h - top, C(0x2A2830)); c.rect(0, top, 2, h - top, C(0x3A3842)); c.rect(w - 3, top, 3, h - top, C(0x201E26))
    c.rect(0, top, w, 2, C(0x3A3842))
    for (ry, wy) in stride(from: top + 5, to: h - 6, by: 7).enumerated() {
        for (rx, x) in stride(from: 4, to: w - 6, by: 6).enumerated() {
            c.rect(x, wy, 3, 4, noise(ry * 53 + rx * 11 + 3) > 0.72 ? C(0xD8B068) : C(0x141820))
        }
    }
    let ax = w / 2
    c.rect(ax, 1, 1, top, C(0x3A3842)); c.rect(ax - 3, 5, 7, 1, C(0x3A3842))
    c.rect(ax - 1, 0, 3, 2, tick % 12 < 6 ? C(0xFF3A3A) : C(0x5A1A1A))
    return c
}

/// The next block along on the right, `w` by `h`: brown, a cornice, windows lit warm here and there.
private func crawlCollapseRight(_ w: Int, _ h: Int) -> PixelCanvas {
    let c = PixelCanvas(w, h)
    c.rect(0, 0, w, h, C(0x3E3438)); c.rect(0, 0, 2, h, C(0x4E4448))
    c.rect(0, 0, w, 3, C(0x2E2628)); c.rect(0, 0, w, 1, C(0x5A5054))
    for (ry, wy) in stride(from: 7, to: h - 9, by: 13).enumerated() {
        for (rx, x) in stride(from: 6, to: w - 6, by: 12).enumerated() {
            c.rect(x, wy, 6, 8, noise(ry * 31 + rx * 7 + 1) > 0.66 ? C(0xD8B068) : C(0x141820))
            c.rect(x + 3, wy, 1, 8, C(0x2E2628))
        }
    }
    return c
}

/// The box's size and where it rests, for a frame `w` by `h`: its letters `scale`, its top-left at rest.
private func crawlCollapseBoxPlace(w: Int, h: Int, wide: Bool) -> (scale: Int, x: Int, y: Int, w: Int, h: Int) {
    let s = max(2, min(3, (w - 24) / 67))
    let bw = crawlTextWidth("WELCOME, CRAWLER!", scale: s) + 16, bh = 4 + 5 + 3 + 5 * s + 5
    let y = wide ? (h - bh) / 2 - 8 : h * 3 / 10 - bh / 2
    return (s, (w - bw) / 2, y, bw, bh)
}

/// The System box, `k` through the trip: it slams down into the middle (0.34–0.37), lands with a white flash and
/// white streaks either side (0.37–0.41), stays, and is knocked off the top by the title (0.5–0.56). The System's
/// own look: navy, a bright blue frame lit on the top and left, a soft blue glow; SYSTEM MESSAGE small in pale blue,
/// a rule, and WELCOME, CRAWLER! big in gold over a brown shadow.
private func crawlCollapseBox(_ c: PixelCanvas, w: Int, h: Int, k: Double, wide: Bool) {
    guard k >= 0.34 && k < 0.56 else { return }
    let p = crawlCollapseBoxPlace(w: w, h: h, wide: wide)
    let slam = CrawlTrip.span(k, 0.34, 0.37), push = CrawlTrip.ease(CrawlTrip.span(k, 0.5, 0.56))
    let y = p.y - Int(((1 - slam * slam) + push) * Double(p.y + p.h + 8))
    let x = p.x, bw = p.w, bh = p.h
    let flash = k >= 0.37 ? 1 - CrawlTrip.span(k, 0.37, 0.41) : 0
    let navy = C(0x0E2A6A, 0.96), lit = lerp(C(0x6AB4FF), C(0xFFFFFF), flash), deep = lerp(C(0x2A64C8), C(0xFFFFFF), flash)
    let halo = C(0x3A8CFF, 0.3 + 0.5 * flash)
    c.rect(x - 3, y - 1, bw + 6, bh + 2, halo); c.rect(x - 1, y - 3, bw + 2, 2, halo); c.rect(x - 1, y + bh + 1, bw + 2, 2, halo)
    c.rect(x, y, bw, bh, navy)
    c.rect(x, y, bw, 1, lit); c.rect(x, y, 1, bh, lit)
    c.rect(x, y + bh - 1, bw, 1, deep); c.rect(x + bw - 1, y, 1, bh, deep)
    crawlText(c, x + 8, y + 4, "SYSTEM MESSAGE", C(0x9CD8FF))
    c.rect(x + 3, y + 10, bw - 6, 1, C(0x2A64C8))
    crawlText(c, x + 8, y + 13 + max(1, p.scale / 2), "WELCOME, CRAWLER!", C(0x7A4A10), scale: p.scale)
    crawlText(c, x + 8, y + 13, "WELCOME, CRAWLER!", C(0xFFD84A), scale: p.scale)
    if flash > 0 {
        c.rect(x + 1, y + 1, bw - 2, bh - 2, C(0xFFFFFF, 0.35 * flash))
        // The landing's streaks, out either side.
        for (i, dy) in [bh / 4, bh / 2, bh * 3 / 4].enumerated() {
            let len = 6 + i % 2 * 6, gap = 4 + Int((1 - flash) * 10)
            c.rect(x - gap - len, y + dy, len, 1, C(0xFFFFFF)); c.rect(x + bw + gap, y + dy, len, 1, C(0xFFFFFF))
        }
    }
}

/// The title, `k` through the trip: it sweeps up from the bottom and overshoots a little into place (0.5–0.6),
/// glitters (0.58–0.76), and goes up with the street. DUNGEON CRAWLER CLAWD in the System's block letters, big, gold
/// lit pale along the top of each letter and deep at the bottom, an orange-brown edge under them, CLAWD the biggest;
/// on a deep purple plate in a neon purple frame ringed with chasing bulbs; purple rays turning behind it all.
private func crawlCollapseTitle(_ c: PixelCanvas, w: Int, h: Int, k: Double, t: Double, wide: Bool) {
    guard k >= 0.5 else { return }
    let tick = Int(t / 0.05)
    // The lines and their sizes: one line over CLAWD on the window's strip, two on the screen saver.
    let words = wide ? ["DUNGEON CRAWLER"] : ["DUNGEON", "CRAWLER"]
    let longest = wide ? 59 : 27
    let s1 = max(2, min((w - 48) / longest, wide ? (h - 40) / 14 : h / 30))
    let s2Fit = (w - 48) / 19
    let s2 = max(s1 + 1, min(s2Fit, wide ? min(s1 * 9 / 5, (h - 30 - 5 * s1) / 5) : s1 * 7 / 5))
    var lines: [(text: String, scale: Int, dy: Int)] = []
    var bodyH = 0
    for word in words { lines.append((word, s1, bodyH)); bodyH += 5 * s1 + max(2, s1 / 2) + 1 }
    bodyH += max(1, s1 / 2)
    lines.append(("CLAWD", s2, bodyH)); bodyH += 5 * s2
    let bodyW = lines.map { crawlTextWidth($0.text, scale: $0.scale) }.max() ?? 0
    let mx = wide ? 12 : 10, my = wide ? 8 : 9
    let pw = bodyW + 2 * mx, ph = bodyH + 2 * my
    let px0 = (w - pw) / 2, rest = (h - ph) / 2 - (wide ? 1 : 4)

    // The sweep up, overshooting a touch and settling back.
    let sweep = CrawlTrip.span(k, 0.5, 0.6)
    let u = sweep - 1
    let back = 1 + 2.70158 * u * u * u + 1.70158 * u * u
    let py0 = rest + Int(((1 - back) * Double(h - rest + 4)).rounded())
    let cx = Double(px0) + Double(pw) / 2, cy = Double(py0) + Double(ph) / 2

    // The rays behind, opening out and turning.
    let open = CrawlTrip.span(k, 0.52, 0.62)
    if open > 0 {
        let reach = open * Double(w + h)
        let turn = t * 0.08
        let shade = C(0x4A1E78, 0.75)
        for y in 0..<h {
            for x in -3..<(w + 3) {
                let dx = Double(x) + 0.5 - cx, dy = (Double(y) + 0.5 - cy) * 1.6
                guard dx * dx + dy * dy < reach * reach else { continue }
                let slot = Int(floor((atan2(dy, dx) / (2 * .pi) + turn) * 18 + 36))
                if slot % 2 == 0 { c.px(x, y, shade) }
            }
        }
    }

    // The plate: deep purple, a neon purple frame round it, bulbs chasing round the frame in white and gold.
    c.rect(px0 - 3, py0 - 3, pw + 6, ph + 6, C(0x1A0830))
    c.rect(px0 - 2, py0 - 2, pw + 4, ph + 4, C(0xB04AE8))
    c.rect(px0, py0, pw, ph, C(0x24104A))
    c.rect(px0 + 1, py0 + 1, pw - 2, 1, C(0x3A1C6A))
    let perimeter = 2 * (pw + 4) + 2 * (ph + 4)
    var i = 0
    for along in stride(from: 0, to: perimeter, by: 7) {
        var bx = 0, by = 0
        let top = pw + 4, side = ph + 4
        if along < top { bx = px0 - 2 + along; by = py0 - 3 }
        else if along < top + side { bx = px0 + pw + 1; by = py0 - 2 + (along - top) }
        else if along < 2 * top + side { bx = px0 + pw + 1 - (along - top - side); by = py0 + ph + 1 }
        else { bx = px0 - 3; by = py0 + ph + 1 - (along - 2 * top - side) }
        let on = (i + tick / 2) % 3 == 0
        c.rect(bx, by, 2, 2, on ? C(0xFFFBE0) : C(0xD89A28))
        i += 1
    }

    // The letters: a dark edge round them, the orange-brown depth under them, then the gold faces.
    let mask = PixelCanvas(w, h)
    for line in lines {
        let lw = crawlTextWidth(line.text, scale: line.scale)
        let lx = px0 + (pw - lw) / 2, ly = py0 + my + line.dy
        let e = max(1, line.scale / 3)
        for (ox, oy) in [(-1, 0), (1, 0), (0, -1), (0, e + 1), (e + 1, e)] {
            crawlText(c, lx + ox, ly + oy, line.text, C(0x140610), scale: line.scale)
        }
        for d in 1...e { crawlText(c, lx + d, ly + d, line.text, C(0x9A4A10), scale: line.scale) }
        crawlText(mask, lx, ly, line.text, C(0xFFFFFF), scale: line.scale)
    }
    let shine = CrawlTrip.span(k, 0.62, 0.72)
    let band = shine > 0 && shine < 1 ? Int(shine * Double(pw + ph + 16)) - 8 : -999
    for line in lines {
        let ly = py0 + my + line.dy, lh = 5 * line.scale
        guard ly < h && ly + lh > 0 else { continue }
        for y in max(0, ly)..<min(h, ly + lh) {
            let rel = Double(y - ly) / Double(lh)
            let face = rel < 0.2 ? C(0xFFF2A8) : rel < 0.6 ? C(0xFFD84A) : C(0xF0A428)
            for x in max(0, px0)..<min(w, px0 + pw) where mask.buf[(y * w + x) * 4 + 3] > 0 {
                let d = (x - px0) + (y - py0) - band
                c.px(x, y, d >= 0 && d < 6 ? C(0xFFFBE8) : face)
            }
        }
    }

    // The glitter: little four-pointed stars winking on and off over the letters.
    if k >= 0.58 {
        for n in 0..<7 {
            let seed = (tick / 2) * 7 + n
            let sx = px0 + mx + Int(noise(seed * 3 + 1) * Double(bodyW))
            let sy = py0 + my + Int(noise(seed * 5 + 2) * Double(bodyH))
            let size = noise(seed * 7 + 3) > 0.5 ? 2 : 1
            for d in -size...size {
                let col = abs(d) == size ? C(0xFFE07A) : C(0xFFFFFF)
                c.px(sx + d, sy, col); c.px(sx, sy + d, col)
            }
        }
    }
}
