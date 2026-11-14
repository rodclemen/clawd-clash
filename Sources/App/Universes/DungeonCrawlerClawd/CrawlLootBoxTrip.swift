import CoreGraphics
import Foundation

// Loot Box (`CrawlWipe.lootBox`), likelier with the Earth crawlers and going to a safe room: a big loot box thumps
// down in the middle of the scene, shakes, glows and bursts open, and its light floods out to become the new place.
// It's New Achievement!'s box (CrawlAchievement.swift) blown up: the same chest, domed lid, band of trim and clasp,
// in one of the same tiers (bronze, silver, gold, legendary or celestial), the tier picked from the trip's two places
// so it stays the same for every frame of a trip.

extension CrawlTrip {
    /// Loot Box, `k` (0…1) through its own part, over the whole of `r`. The box drops out of the top into the middle
    /// of the old place, its shadow growing under it (0–0.14), and lands with a thump: the scene jolts, dust rolls out
    /// either side in chunky clouds along the ground (0.14–0.34); the old place dims and the box rattles in bursts that
    /// come closer together, light leaking round its lid and glints escaping up (0.2–0.5); it bursts open, a flash, the
    /// lid spinning up and away,
    /// rays fanning up out of its mouth and sparkles rising (0.5–0.8); its light floods out in a widening oval, rimmed
    /// white and the tier's glow, swallowing the box, solid light inside in stepped rings, white at the middle (a
    /// silver box's cool blue, a sheen sweeping over it), and the light clears off the new place from the middle
    /// outward in quarters, the top-left corner among the last but done before the System box comes (0.68–0.84). The
    /// box is drawn on the art's grid, every pixel of New Achievement!'s box a square of three or four.
    func drawLootBox(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.85 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let tier = lootTier
        let t = k * CrawlWipe.lootBox.effect
        let s = art.wide ? max(3, h / 32) : max(2, h / 40)       // art pixels to one of the box's
        let cx = w / 2, ground = h * 68 / 100
        let fall = Self.span(k, 0, 0.14), rattle = Self.span(k, 0.2, 0.5)
        let open = k >= 0.5, flood = Self.span(k, 0.54, 0.78), clear = Self.span(k, 0.68, 0.84)

        // Where the box is: falling (accelerating) from above the frame, then on the ground; shaking and hopping in
        // bursts while it rattles, its lid lifting on a line of light.
        let bodyH = 6 * s, lidH = 3 * s
        var dx = 0, up = Int(Double(ground + 4) * (1 - fall * fall)), lidUp = 0
        if rattle > 0 && !open {
            let burst = frac(t * (1.5 + 3 * rattle)) < 0.35 + 0.6 * rattle
            if burst {
                dx = Int(t * 30) % 2 == 0 ? max(1, s / 2) : -max(1, s / 2)
                if rattle > 0.55 && Int(t * 14) % 3 == 0 { up += s }
                if rattle > 0.35 && Int(t * 20) % 4 < 2 { lidUp = s }
            }
        }
        let squat = k > 0.14 && k < 0.18 ? s / 2 : 0
        let x0 = cx - 13 * s / 2 + dx, bottom = ground - up
        let bodyTop = bottom - bodyH + squat, lidTop = bodyTop - lidH - lidUp
        let mouth = (x: Double(cx), y: Double(bodyTop))

        // Under it all: the old place, jolting a row as the box lands and dimming as it rattles; inside the flood, the
        // new place under the light, thinning.
        let jolt = k > 0.14 && k < 0.2 ? (Int(k * 200) % 2 == 0 ? art.px : -art.px) : 0
        if jolt != 0 { ctx.setFillColor(crawlTripRGB(0x08060E)); ctx.fill(r) }
        ctx.drawShot(old, in: r.offsetBy(dx: 0, dy: jolt))
        Self.wash(ctx, 0x08060E, 0.45 * Self.span(k, 0.18, 0.48) * (1 - flood), in: r)
        let ax: Double = art.wide ? 2.6 : 1.5
        func d(_ x: Int, _ y: Int) -> Double {
            let ddx = (Double(x) + 0.5 - mouth.x) / ax, ddy = Double(y) + 0.5 - mouth.y
            return (ddx * ddx + ddy * ddy).squareRoot()
        }
        let corner = [(0, 0), (w, 0), (0, h), (w, h)].map { d($0.0, $0.1) }.max() ?? 1
        let reach = (corner + 4) * pow(flood, 1.4)
        if reach > 1 {
            let inside = art.runs { x, y in d(x, y) < reach }
            if !inside.isEmpty {
                ctx.saveGState(); ctx.clip(to: inside)
                ctx.drawShot(new, in: r)
                ctx.restoreGState()
            }
            // The light over it: stepped rings, clearing from the middle out, a ring of quarters at a time.
            let rings = lootFloodRings(tier)
            let front = clear * 1.5 - 0.5
            for y in 0..<h {
                for x in 0..<w {
                    let dd = d(x, y)
                    guard dd < reach else { continue }
                    let u = dd / corner
                    let a = (Self.clamp((u - front) / 0.5) * 4).rounded(.up) / 4
                    guard a > 0 else { continue }
                    var col = rings[min(rings.count - 1, Int(u * 5))]
                    if tier == .silver {
                        // The sheen: broad bright bars sweeping across, as off polished metal.
                        let bar = Int(Double(x) + Double(y) * 1.3 + 2000 - t * 120) % (h * 3 / 4)
                        if bar < h / 8 { col = lerp(col, C(0xFFFFFF), 0.6) }
                    }
                    c.px(x, y, col.alpha(a))
                }
            }
        }
        // The burst's flash over everything, in steps.
        let flash = Self.span(k, 0.5, 0.58)
        if flash > 0 && flash < 1 { Self.wash(ctx, 0xFFFFFF, 0.6 * (1 - flash), in: r) }

        // The rays fanning up out of its mouth, longer as the light comes, turning a little.
        let g = Double(tier.grandeur)
        if open && flood < 1 {
            let n = 7 + tier.grandeur * 2
            let grow = Self.span(k, 0.5, 0.62), fade = 1 - Self.span(k, 0.66, 0.8)
            let len = Double(h) * (0.6 + 0.08 * g) * grow
            for i in 0..<n {
                let ang = -165 + 150 / Double(n - 1) * Double(i) + 6 * sin(t * 2 + Double(i))
                let e = crawlReach(mouth, ang, len * (0.75 + 0.25 * noise(i * 7 + 5)))
                c.glowLine(mouth.x, mouth.y, e.x, e.y, core: lerp(tier.glow, C(0xFFFFFF), 0.5).alpha(0.8),
                           glow: tier.glow.alpha(0.4), coreR: Double(s) * 0.4, glowR: Double(s) * 1.2, strength: fade)
            }
        }

        // Its shadow while it falls, the dust as it lands, the glints while it rattles.
        if k < 0.5 {
            let spread = Int(Double(7 * s) * (0.4 + 0.6 * fall))
            c.ellipse(cx, ground + 1, spread, max(1, s / 2), C(0x000000, 0.3 + 0.3 * fall))
        }
        let dust = Self.span(k, 0.14, 0.34)
        if dust > 0 && dust < 1 {
            // Two clouds rolling out along the ground from under the box: fat round puffs, lit on top and shaded under
            // so they show on a pale floor as well as a dark one, swelling and then thinning in quarters.
            let thin = (1 - Self.span(dust, 0.55, 1)) * 4
            let a = thin.rounded(.up) / 4
            for i in 0..<12 {
                let side = i % 2 == 0 ? -1.0 : 1.0
                let lane = noise(i * 5)
                let out = Double(6 * s) + (1 - pow(1 - dust, 2.2)) * Double(s) * (2 + lane * 10)
                let rad = Double(s) * (0.9 + noise(i * 5 + 2) * 1.1) * (0.6 + 0.8 * dust)
                let rise = dust * Double(s) * (0.3 + noise(i * 5 + 1) * 1.6)
                let px = cx + Int(side * out), py = ground - Int(rise + rad * 0.6)
                c.circle(px, py + 1, Int(rad.rounded()), C(0x8A7A62, a))
                c.circle(px, py, Int((rad * 0.86).rounded()), C(0xCDBE9C, a))
                c.circle(px - Int(rad / 4), py - Int(rad / 3), Int((rad * 0.5).rounded()), C(0xF4EAD0, a))
            }
        }
        if rattle > 0 && !open {
            let leak = rattle
            for i in 0..<(3 + Int(leak * 8)) {
                let f = frac(t * 1.6 + noise(i * 17))
                let gx = cx + Int((noise(i * 17 + 1) - 0.5) * Double(14 * s))
                let gy = lidTop - Int(f * Double(10 * s) * (0.5 + leak))
                let size = max(1, s / 2)
                c.rect(gx, gy, size, size, lerp(tier.glow, C(0xFFFFFF), 0.4).alpha(leak * (1 - f)))
            }
        }

        // The box, swallowed by the light as it floods out.
        let boxFade = 1 - Self.span(k, 0.62, 0.74)
        if boxFade > 0 {
            let box = PixelCanvas(w, h)
            lootDrawBox(box, tier, x0: x0, bodyTop: bodyTop, bottom: bottom, lidTop: lidTop, s: s, open: open,
                        leak: rattle, t: t)
            let white = Self.span(k, 0.56, 0.7)
            if white > 0 {
                // Whitening into the light, in steps.
                let q = (white * 4).rounded() / 4
                for y in 0..<h { for x in 0..<w where box.isDrawn(x, y) { box.px(x, y, lerp(tier.glow, C(0xFFFFFF), 0.5).alpha(q)) } }
            }
            c.paste(box, alpha: (boxFade * 4).rounded(.up) / 4)
        }

        // The lid flying off, spinning, up and to the right, gone as it fades.
        let flight = Self.span(k, 0.5, 0.78)
        if open && flight < 1 {
            let n = 16 * s + 6
            let lid = PixelCanvas(n, n)
            lootDrawLid(lid, tier, x: n / 2 - 15 * s / 2, y: n / 2 - lidH / 2, s: s, t: t)
            let turned = lid.rotated(-flight * 540, about: (Double(n) / 2, Double(n) / 2), into: n, n,
                                     at: (Double(n) / 2, Double(n) / 2))
            let lx = Double(cx) + Double(w) * 0.22 * flight
            let ly = Double(bodyTop - lidH) - Double(h) * 0.7 * (1 - (1 - flight) * (1 - flight))
            c.paste(turned, x: Int(lx) - n / 2, y: Int(ly) - n / 2, alpha: 1 - Self.span(flight, 0.5, 1))
        }

        // Sparkles rising from its mouth and drifting out, twinkling into crosses for gold and up; all gone before
        // the System box comes.
        let rise = Self.span(k, 0.52, 0.8)
        if rise > 0 && rise < 1 {
            let n = 14 + tier.grandeur * 5
            let starry = [C(0xFFFFFF), C(0xB8F4FF), C(0xFFB8F0), C(0xFFF2A0), C(0xA8B8FF)]
            for i in 0..<n {
                let delay = noise(i * 13 + 1) * 0.35
                let f = min(1, max(0, (rise - delay) / 0.65))
                guard f > 0 && f < 1 else { continue }
                let sx = mouth.x + (noise(i * 13 + 2) - 0.5) * Double(w) * 0.5 * f + sin(t * 3 + Double(i)) * 2
                let sy = mouth.y - f * Double(h) * (0.35 + noise(i * 13 + 3) * 0.3)
                let col = tier == .celestial ? starry[i % starry.count] : (i % 3 == 0 ? tier.trim.lit : tier.glow)
                let px = Int(sx), py = Int(sy), size = max(1, s / 2)
                c.rect(px, py, size, size, col.alpha(1 - f))
                if tier.grandeur >= 2 && (i + Int(t * 8)) % 3 == 0 {
                    for (ox, oy) in [(size, 0), (-size, 0), (0, size), (0, -size)] {
                        c.rect(px + ox, py + oy, size, size, col.alpha((1 - f) * 0.6))
                    }
                }
            }
        }

        // The flood's edge: a white rim inside, the tier's glow round it, a faint halo outside.
        if reach > 1 && reach < corner + 4 {
            let rim = Double(max(2, s))
            for y in 0..<h {
                for x in 0..<w {
                    let dd = d(x, y)
                    guard dd > reach - rim * 2, dd < reach + rim else { continue }
                    if dd < reach - rim { c.px(x, y, C(0xFFFFFF, 0.9)) }
                    else if dd < reach { c.px(x, y, tier.glow) }
                    else { c.px(x, y, tier.glow.alpha(0.45)) }
                }
            }
        }
        art.show(ctx)
    }

    /// This trip's tier, from its two places, so it's the same on every frame of the trip: bronze, silver and gold
    /// most often, legendary now and then, celestial rarely (a little grander than New Achievement!'s odds: a trip is
    /// a show).
    private var lootTier: CrawlLootTier {
        var n = 17
        for u in (from.rawValue + ">" + to.rawValue).unicodeScalars { n = (n &* 31 &+ Int(u.value)) % 99_991 }
        var roll = Int(noise(n) * 100)
        for (tier, weight) in [(CrawlLootTier.bronze, 30), (.silver, 26), (.gold, 24), (.legendary, 13), (.celestial, 7)] {
            if roll < weight { return tier }
            roll -= weight
        }
        return .bronze
    }
}

/// The flood's light from its middle out, in steps: white, then down through the tier's glow. Silver's own glow is
/// nearly white, so it goes on to a cool steel blue, or the whole flood would be one flat pale grey.
private func lootFloodRings(_ tier: CrawlLootTier) -> [Px] {
    if tier == .silver { return [C(0xFFFFFF), C(0xE6F3FF), C(0xBCD8F6), C(0x92B8E6), C(0x7096D0)] }
    let g = tier.glow, white = C(0xFFFFFF)
    return [white, lerp(g, white, 0.7), lerp(g, white, 0.4), lerp(g, white, 0.15), g]
}

/// New Achievement!'s loot box at `s` art pixels to one of its own, its body from `x0` (13 wide) and `bodyTop` to
/// `bottom`, its lid (15 wide, 3 tall, a pixel wider each side) from `lidTop`: a dark outline round it so it stands
/// off any place; the body lit on the left, shaded on the right, a plank line and the band of trim; the lid domed with
/// its band; the clasp at the seam; light leaking from the seam as `leak` rises. Open, there's no lid and its mouth is
/// full of light. A celestial one is deep blue with stars twinkling over it.
private func lootDrawBox(_ c: PixelCanvas, _ tier: CrawlLootTier, x0: Int, bodyTop: Int, bottom: Int, lidTop: Int,
                         s: Int, open: Bool, leak: Double, t: Double) {
    let body = tier.body, trim = tier.trim, ink = C(0x140C1A)
    let bw = 13 * s, bh = bottom - bodyTop
    c.rect(x0 - 1, bodyTop - 1, bw + 2, bh + 2, ink)
    if !open { c.rect(x0 - s - 1, lidTop - 1, bw + 2 * s + 2, 3 * s + 2, ink) }
    c.rect(x0, bodyTop, bw, bh, body.face)
    c.rect(x0, bodyTop, s, bh, body.lit)
    c.rect(x0 + 12 * s, bodyTop, s, bh, body.dark)
    c.rect(x0, bottom - s, bw, s, body.dark)
    c.rect(x0 + s, bodyTop + 2 * s, 11 * s, s, lerp(body.face, body.dark, 0.35))
    c.rect(x0 + 5 * s, bodyTop, 3 * s, bh, trim.face)
    c.rect(x0 + 5 * s, bodyTop, s, bh, trim.lit)
    if tier == .celestial { lootStars(c, x: x0 + s, y: bodyTop + s, w: 11 * s, h: bh - 2 * s, s: s, t: t, seed: 3) }
    if open {
        c.rect(x0, bodyTop - s, bw, s, body.dark)
        c.rect(x0 + s, bodyTop - s, 11 * s, s, lerp(tier.glow, C(0xFFFFFF), 0.6))
        c.rect(x0 + 2 * s, bodyTop - 2 * s, 9 * s, s, tier.glow.alpha(0.85))
        return
    }
    if lidTop + 3 * s < bodyTop || leak > 0.6 {
        c.rect(x0, lidTop + 3 * s, bw, max(s / 2, bodyTop - lidTop - 3 * s), lerp(tier.glow, C(0xFFFFFF), leak * 0.6))
    }
    lootDrawLid(c, tier, x: x0 - s, y: lidTop, s: s, t: t)
    c.rect(x0 + 5 * s, lidTop + 2 * s, 3 * s, 2 * s, trim.lit)     // the clasp
}

/// The lid, 15 of the box's pixels wide and 3 tall at `s` art pixels each, its top-left at (`x`, `y`): domed (its top
/// row inset), lit along the top, the band of trim over it, shaded at the right.
private func lootDrawLid(_ c: PixelCanvas, _ tier: CrawlLootTier, x: Int, y: Int, s: Int, t: Double) {
    let body = tier.body, trim = tier.trim
    c.rect(x + s, y, 13 * s, s, body.lit)
    c.rect(x, y + s, 15 * s, 2 * s, body.face)
    c.rect(x + 14 * s, y + s, s, 2 * s, body.dark)
    c.rect(x, y + 2 * s, 15 * s, s, lerp(body.face, body.dark, 0.5))
    c.rect(x + 6 * s, y, 3 * s, 3 * s, trim.face)
    c.rect(x + 6 * s, y, s, 3 * s, trim.lit)
    if tier == .celestial { lootStars(c, x: x + s, y: y + s, w: 13 * s, h: s, s: s, t: t, seed: 11) }
}

/// Stars twinkling over a celestial box (`w`×`h` art pixels from (`x`, `y`)): fixed spots, each lit now and then,
/// white, pale cyan or pink, a box pixel's half each.
private func lootStars(_ c: PixelCanvas, x: Int, y: Int, w: Int, h: Int, s: Int, t: Double, seed: Int) {
    let colours = [C(0xFFFFFF), C(0xB8F4FF), C(0xFFC8F4)]
    let size = max(1, s / 2)
    for i in 0..<max(2, w * h / (s * s * 4)) {
        let sx = x + Int(noise(seed * 31 + i * 3) * Double(w - size)), sy = y + Int(noise(seed * 31 + i * 3 + 1) * Double(h - size))
        guard noise(seed * 31 + i * 3 + 2 + Int(t * 5) * 7) > 0.35 else { continue }
        c.rect(sx, sy, size, size, colours[i % colours.count])
    }
}
