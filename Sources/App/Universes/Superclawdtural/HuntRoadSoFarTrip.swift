import CoreGraphics
import Foundation

// The Road So Far, the signature opening (`HuntWipe.roadSoFar`): the "previously on" that opens every episode. The
// picture turns to grainy, scratched film; THE ROAD SO FAR stamps on word by word; the old place and a few other
// moments flash past as jumpy film stills (Baby on the road at dusk, yellow eyes in the dark); the title smoulders in
// on black like burning letters; then the card NOW, and the new place, the film clearing off it.

extension HuntTrip {
    /// A frame `k` (0…1) of The Road So Far, over the whole of `r`. The old place turns sepia, grain and scratches
    /// coming up, the frame weaving in the gate (0–0.07); it darkens and THE ROAD SO FAR stamps on, a word at a time,
    /// each landing with a jolt (0.07–0.3); five stills cut past, a white flash between each, jumping in the gate
    /// (0.3–0.58); black, and SUPERCLAWDTURAL catches light by light and burns, flames licking off the tops of the
    /// letters and sparks going up (0.58–0.8); NOW slams on in red (0.8–0.9); a flash, and the new place, sepia at
    /// first, the colour and the grain clearing off it (0.9–1). Everything on the film moves on whole film frames, 24 a
    /// second, so it judders like the real thing.
    func drawRoadSoFar(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let under = HuntArt(r), over = HuntArt(r)
        let w = over.w, h = over.h
        let frame = Int(k * duration * 24)                       // the film's frame, 24 a second
        let filmIn = Self.span(k, 0, 0.07), filmOut = Self.span(k, 0.9, 1)
        let film = k < 0.5 ? Self.ease(filmIn) : 1 - Self.ease(filmOut)

        // The gate weave: the picture shuffling a pixel or two each film frame, harder through the stills.
        let jump = (k >= 0.3 && k < 0.58) ? 3.0 : 1.4
        let dx = Int(((rnd(frame, 1) - 0.5) * jump * film).rounded())
        let dy = Int(((rnd(frame, 2) - 0.5) * jump * film).rounded())
        let weave = CGRect(x: r.minX + CGFloat(dx) * under.px, y: r.minY - CGFloat(dy) * under.px,
                           width: r.width, height: r.height)

        ctx.setFillColor(huntTripRGB(0x050403)); ctx.fill(r)
        var black = false                                        // a card on black: no picture, no tint
        if k < 0.3 {
            // The old place on film, darkening under the words as they come.
            ctx.drawShot(old, in: weave)
            Self.wash(ctx, 0x000000, 0.55 * Self.span(k, 0.06, 0.09), in: r)
        } else if k < 0.58 {
            stills(ctx, under, old: old, k: Self.span(k, 0.3, 0.58), frame: frame, weave: weave, overArt: over)
        } else if k < 0.9 {
            black = true
        } else {
            ctx.drawShot(new, in: weave)
        }
        under.show(ctx)

        // The film look over whatever's showing: sepia, and a flicker in the brightness, frame by frame.
        if !black && film > 0 {
            ctx.saveGState()
            ctx.setBlendMode(.color)
            ctx.setFillColor(huntTripRGB(0xA27C52, CGFloat(0.85 * film))); ctx.fill(r)
            ctx.restoreGState()
            let flick = rnd(frame, 3)
            if flick < 0.3 { Self.wash(ctx, 0x000000, 0.125 * film, in: r) }
            else if flick > 0.85 { Self.wash(ctx, 0xFFF0D8, 0.125 * film, in: r) }
        }
        // The white flashes: one film frame between the stills, and the one that cuts to the new place.
        let cuts = [0.3, 0.355, 0.41, 0.47, 0.525, 0.58, 0.9]
        let flash = cuts.contains { k >= $0 && k < $0 + 1.0 / (duration * 24) }

        if k >= 0.07 && k < 0.3 { stampTitle(over, k: k) }
        if k >= 0.58 && k < 0.8 { burnTitle(over, s: Self.span(k, 0.58, 0.8), frame: frame) }
        if k >= 0.8 && k < 0.9 { stampNow(over, k: Self.span(k, 0.8, 0.9)) }

        // The grain, the dust and the scratches, and the corners going dark like an old print.
        let grain = black ? 0.6 : film
        if grain > 0 { filmDirt(over.c, w, h, frame: frame, amount: grain, vignette: !black) }
        if flash { over.c.rect(0, 0, w, h, C(0xFFF6E4, 0.6)) }
        over.show(ctx)
    }

    /// THE ROAD SO FAR, stamped on a word at a time: each word drops from big to its place in a few frames and the
    /// whole line jolts as it lands. Cream, on a hard black edge and a rust drop shadow, worn like an old stamp, so it
    /// reads on the darkened film whatever the place under it is. One line on the window's strip, two on the screen
    /// saver.
    private func stampTitle(_ art: HuntArt, k: Double) {
        let w = art.w, h = art.h
        let lines = art.wide ? ["THE ROAD SO FAR"] : ["THE ROAD", "SO FAR"]
        let dots = lines.map { huntTripTextWidth($0, 1) }.max()!
        let p = max(2, min(w * 80 / 100 / dots, h * 44 / 100 / (lines.count * 7 - 2)))
        let blockH = (lines.count * 7 - 2) * p
        let top = (h - blockH) / 2
        let lands = [0.08, 0.13, 0.18, 0.225]                   // when each word lands
        var words: [(text: String, x: Int, y: Int, at: Double)] = []
        for (li, line) in lines.enumerated() {
            let x0 = (w - huntTripTextWidth(line, p)) / 2
            var prefix = ""
            for word in line.split(separator: " ") {
                let x = x0 + huntTripTextWidth(prefix, p)
                words.append((String(word), x, top + li * 7 * p, lands[words.count]))
                prefix += word + " "
            }
        }
        // The jolt from the last word down, dying away.
        let last = lands.last { k >= $0 } ?? 0
        let since = k - last
        let shake = k >= lands[0] && since < 0.03 ? (Int(k * 300) % 2 == 0 ? 1 : -1) * max(1, Int(Double(p) * (1 - since / 0.03))) : 0
        var ink = [Bool](repeating: false, count: w * h)
        for word in words {
            let fall = Self.span(k, word.at - 0.025, word.at)
            guard fall > 0 else { continue }
            let mask = PixelCanvas(w, h)
            huntTripText(mask, word.x, word.y, word.text, C(0xFFFFFF), p)
            let s = 1 + 1.4 * pow(1 - fall, 2)
            let cx = Double(word.x) + Double(huntTripTextWidth(word.text, p)) / 2, cy = Double(word.y) + Double(5 * p) / 2
            for y in 0..<h {
                for x in 0..<w {
                    let u = Int((cx + (Double(x - shake) + 0.5 - cx) / s).rounded(.down))
                    let v = Int((cy + (Double(y) + 0.5 - cy) / s).rounded(.down))
                    guard u >= 0, v >= 0, u < w, v < h, mask.buf[(v * w + u) * 4 + 3] > 127 else { continue }
                    ink[y * w + x] = true
                }
            }
        }
        letters(art.c, ink, w, h) { x, y in
            rnd(x, y * 13 + 77) < 0.07 ? C(0xC8BCA6) : C(0xF2E8D4)                // a worn speck here and there
        }
    }

    /// NOW, the card before the episode starts: slammed on in red in the middle of the black, a hot lit edge on top.
    private func stampNow(_ art: HuntArt, k: Double) {
        let w = art.w, h = art.h
        let p = max(3, min(w * 40 / 100 / huntTripTextWidth("NOW", 1), h * 36 / 100 / 5))
        let x0 = (w - huntTripTextWidth("NOW", p)) / 2, y0 = (h - 5 * p) / 2
        let mask = PixelCanvas(w, h)
        huntTripText(mask, x0, y0, "NOW", C(0xFFFFFF), p)
        let fall = Self.span(k, 0, 0.22)
        let s = 1 + 1.2 * pow(1 - fall, 2)
        let shake = fall >= 1 && k < 0.4 ? (Int(k * 60) % 2 == 0 ? 1 : -1) * max(1, p / 3) : 0
        let cx = Double(w) / 2, cy = Double(y0) + Double(5 * p) / 2
        var ink = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            for x in 0..<w {
                let u = Int((cx + (Double(x - shake) + 0.5 - cx) / s).rounded(.down))
                let v = Int((cy + (Double(y) + 0.5 - cy) / s).rounded(.down))
                guard u >= 0, v >= 0, u < w, v < h, mask.buf[(v * w + u) * 4 + 3] > 127 else { continue }
                ink[y * w + x] = true
            }
        }
        letters(art.c, ink, w, h) { x, y in
            let above = y > 0 && ink[(y - 1) * w + x]
            return above ? C(0xD8261A) : C(0xFF8A62)                              // lit along the top of each stroke
        }
    }

    /// Lettering from a mask: a black edge round it, a rust drop shadow down and right, and the face in `face`.
    private func letters(_ c: PixelCanvas, _ ink: [Bool], _ w: Int, _ h: Int, face: (Int, Int) -> Px) {
        func on(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && ink[y * w + x] }
        for y in 0..<h {
            for x in 0..<w where !on(x, y) {
                if on(x - 1, y) || on(x + 1, y) || on(x, y - 1) || on(x, y + 1) || on(x - 1, y - 1) || on(x + 1, y + 1) {
                    c.px(x, y, C(0x0A0706))
                } else if on(x - 2, y - 2) || on(x - 3, y - 3) || on(x - 2, y - 3) || on(x - 3, y - 2) {
                    c.px(x, y, C(0x7A3218))
                }
            }
        }
        for y in 0..<h { for x in 0..<w where ink[y * w + x] { c.px(x, y, face(x, y)) } }
    }

    /// SUPERCLAWDTURAL burning in on black, `s` 0…1: the letters catch in patches from left to right, each bit of a
    /// stroke flaring pale as it catches and settling to a smouldering orange that seethes frame by frame, hot yellow
    /// along the edges; flames lick up off the tops of the strokes, and sparks rise off them. Just before it catches,
    /// a dull red heat shows where each stroke will be.
    private func burnTitle(_ art: HuntArt, s: Double, frame: Int) {
        let c = art.c, w = art.w, h = art.h
        let title = "SUPERCLAWDTURAL"
        let p = max(2, min(w * 84 / 100 / huntTripTextWidth(title, 1), h * 26 / 100 / 5))
        let x0 = (w - huntTripTextWidth(title, p)) / 2, y0 = (h - 5 * p) / 2
        let mask = PixelCanvas(w, h)
        huntTripText(mask, x0, y0, title, C(0xFFFFFF), p)
        func on(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && mask.buf[(y * w + x) * 4 + 3] > 127 }
        let span = Double(huntTripTextWidth(title, p))
        func catches(_ x: Int, _ y: Int) -> Double {
            0.02 + 0.42 * Double(x - x0) / span + 0.2 * rnd(x / max(1, p), y / max(1, p) + 900)
        }
        for y in max(0, y0 - 4 * p)..<min(h, y0 + 6 * p) {
            for x in max(0, x0 - 2)..<min(w, x0 + Int(span) + 2) {
                guard on(x, y) else { continue }
                let age = s - catches(x, y)
                if age < -0.12 { continue }
                if age < 0 { c.px(x, y, C(0x6A1408, 0.5 + 4 * (age + 0.12))); continue }
                let edge = !on(x - 1, y) || !on(x + 1, y) || !on(x, y - 1) || !on(x, y + 1)
                let seethe = rnd(x / 2 + frame * 3, y / 2 + frame)
                let col: Px
                if age < 0.05 { col = C(0xFFF4C8) }
                else if edge { col = seethe < 0.3 ? C(0xFFE07A) : C(0xFFB23A) }
                else { col = seethe < 0.4 ? C(0xE86A1C) : (seethe < 0.8 ? C(0xC8461A) : C(0xFF9A30)) }
                c.px(x, y, col)
                // A flame off the top of the stroke, its height flickering every frame.
                if !on(x, y - 1), age > 0.04 {
                    let tall = Int((rnd(x / 2, frame + 400) * 1.3 + 0.3) * Double(p) * min(1, age * 8))
                    for f in 1...max(1, tall) {
                        let up = Double(f) / Double(max(1, tall))
                        c.px(x, y - f, up < 0.45 ? C(0xFFC24A, 0.85) : (up < 0.8 ? C(0xF0701E, 0.7) : C(0xC0301A, 0.5)))
                    }
                }
            }
        }
        // The sparks: rising off the letters, drifting and winking out.
        for i in 0..<36 {
            let born = rnd(i, 500) * 0.8, life = Self.span(s, born, born + 0.35)
            guard life > 0 && life < 1, s > catches(x0 + Int(rnd(i, 501) * span), y0) else { continue }
            let sx = x0 + Int(rnd(i, 501) * span + sin(life * 6 + Double(i)) * 3)
            let sy = y0 - Int(life * Double(h) * 0.35)
            c.px(sx, sy, life < 0.6 ? C(0xFFE08A) : C(0xE8701E, 1 - life))
        }
    }

    /// The five stills that flash past, `s` 0…1 through them, each held a moment and pushing in a touch: the old place
    /// close up on one side, Baby on the road at dusk, the old place close on the other side, yellow eyes in the dark,
    /// and the old place whole. The pictures go under the film's sepia; the eyes go over it, so they stay yellow.
    private func stills(_ ctx: CGContext, _ art: HuntArt, old: CGImage, k s: Double, frame: Int, weave: CGRect,
                        overArt: HuntArt) {
        let ends = [0.196, 0.393, 0.607, 0.804, 1.0]
        let i = ends.firstIndex { s < $0 } ?? 4
        let from = i == 0 ? 0 : ends[i - 1]
        let push = 1 + 0.06 * Self.span(s, from, ends[i])
        func close(_ zoom: Double, _ fx: Double, _ fy: Double) {
            let z = CGFloat(zoom * push), rw = weave.width * z, rh = weave.height * z
            let x = weave.minX - (rw - weave.width) * CGFloat(fx), y = weave.minY - (rh - weave.height) * CGFloat(fy)
            ctx.drawShot(old, in: CGRect(x: x, y: y, width: rw, height: rh))
        }
        switch i {
        case 0: close(1.6, 0.2, 0.45)
        case 1: impalaStill(art, frame: frame)
        case 2: close(2.1, 0.8, 0.6)
        case 3: eyesStill(art, over: overArt, frame: frame)
        default: close(1.12, 0.5, 0.5)
        }
    }

    /// Baby on an empty road at dusk: a sky in stepped bands, telegraph poles, the road with its dashes, and the
    /// Impala, side on, at twice the ride's size.
    private func impalaStill(_ art: HuntArt, frame: Int) {
        let c = art.c, w = art.w, h = art.h
        let ground = h * 68 / 100
        let bands: [UInt32] = [0x2A3448, 0x4A3A44, 0x7A4432, 0xB8683A, 0xE0A050]
        for (b, col) in bands.enumerated() {
            let y0 = ground * b / bands.count
            c.rect(0, y0, w, ground - y0, C(col))
        }
        c.rect(0, ground - 3, w, 3, C(0x2A2018))                                  // the far fields, a dark line
        for i in 0..<6 {                                                          // telegraph poles and the wire
            let px = (i * w / 5 + w / 9) % w
            c.rect(px, ground - h / 3, 2, h / 3, C(0x1A1410)); c.rect(px - 4, ground - h / 3 + 2, 10, 1, C(0x1A1410))
        }
        c.rect(0, ground - h / 3 + 4, w, 1, C(0x1A1410, 0.6))
        c.rect(0, ground, w, h - ground, C(0x26262A))
        c.rect(0, ground, w, 1, C(0x3E3E44))
        let lane = ground + (h - ground) / 2
        for x in stride(from: (frame * 3) % 24 - 24, to: w, by: 24) { c.rect(x, lane, 12, 2, C(0xD8B040)) }
        let car = PixelCanvas(Ride.width, Ride.height)
        huntDrawImpala(car, ramp: 0, moving: true, t: Double(frame) / 24)
        let s = 2
        blit(car, into: c, x: w / 2 - Ride.width * s / 2, y: lane + 4 - Ride.height * s, scale: s)
    }

    /// Yellow eyes in the dark: a man's dark shape, head and shoulders in a jacket, against a dim wall, a thin rim
    /// of light down his left side; and his eyes lit yellow. The figure goes under the film; the eyes over it, so the
    /// sepia never dulls them.
    private func eyesStill(_ art: HuntArt, over: HuntArt, frame: Int) {
        let c = art.c, w = art.w, h = art.h
        c.rect(0, 0, w, h, C(0x2A2420))
        for y in stride(from: 0, to: h, by: 6) { c.rect(0, y, w, 1, C(0x221C18)) }       // the wall's boards
        let cx = w / 2, hr = max(8, h / 7), cy = h * 40 / 100
        let body = C(0x0E0C0C), rim = C(0x8A7A66)
        // The shoulders and the jacket, sloping out from the neck, its collar turned up.
        for y in (cy + hr)..<h {
            let half = hr / 2 + min(hr * 2, (y - cy - hr) * 3) + (y - cy - hr) / 4
            c.rect(cx - half, y, half * 2, 1, body)
            c.px(cx - half, y, rim)
        }
        c.rect(cx - hr * 2 / 3, cy + hr - 1, hr * 4 / 3, 3, body)                        // the neck and collar
        c.ellipse(cx, cy, hr * 4 / 5, hr, body)                                           // the head
        c.ellipse(cx, cy - hr * 3 / 4, hr * 4 / 5, hr / 3, body)                          // short hair on top
        for y in (cy - hr + 2)...(cy + hr - 2) {                                          // lit down the left
            let d = Double(y - cy) / Double(hr)
            c.px(cx - Int(Double(hr * 4 / 5) * (1 - d * d).squareRoot()), y, rim)
        }
        let ey = cy - hr / 5, gap = max(3, hr * 2 / 5), e = max(1, hr / 9)
        let blink = frame % 9 == 4
        for ex in [cx - gap, cx + gap] where !blink {
            over.c.rect(ex - e - 2, ey - 2, 2 * e + 5, 5, C(0xFFD21A, 0.25))
            over.c.rect(ex - e - 1, ey - 1, 2 * e + 3, 3, C(0xFFD21A, 0.45))
            over.c.rect(ex - e, ey, 2 * e + 1, 1, C(0xFFE45A)); over.c.px(ex, ey, C(0xFFFFFF))
        }
    }
}

/// A ride's canvas onto `c` at `scale`, its top-left at `x`, `y`.
private func blit(_ src: PixelCanvas, into c: PixelCanvas, x: Int, y: Int, scale s: Int) {
    for v in 0..<src.h {
        for u in 0..<src.w {
            let i = (v * src.w + u) * 4, a = src.buf[i + 3]
            guard a > 0 else { continue }
            func un(_ ch: UInt8) -> UInt8 { UInt8(min(255, Int(ch) * 255 / Int(a))) }
            c.rect(x + u * s, y + v * s, s, s, Px(r: un(src.buf[i]), g: un(src.buf[i + 1]), b: un(src.buf[i + 2]), a: a))
        }
    }
}

/// Noise from a pair of numbers, 0…1.
private func rnd(_ a: Int, _ b: Int) -> Double { noise((a &* 7919 &+ b &* 104729) & 0xFFFFF) }

/// The film's dirt, `amount` 0…1, new every film frame: fine grain over everything, a few flecks of dust light and
/// dark, a scratch or two running down the frame, and, with `vignette`, the corners darkened in steps.
private func filmDirt(_ c: PixelCanvas, _ w: Int, _ h: Int, frame: Int, amount: Double, vignette: Bool) {
    for y in 0..<h {
        for x in 0..<w {
            let g = noise((x &* 7919 &+ y &* 104729 &+ frame &* 15485863) & 0xFFFFFF)
            if g > 0.93 { c.px(x, y, C(0xF4E8D0, 0.22 * amount)) }
            else if g < 0.07 { c.px(x, y, C(0x000000, 0.28 * amount)) }
        }
    }
    if vignette {
        let cx = Double(w) / 2, cy = Double(h) / 2
        for y in 0..<h {
            for x in 0..<w {
                let u = (Double(x) - cx) / cx, v = (Double(y) - cy) / cy
                let d = u * u * 0.7 + v * v
                if d > 0.75 { c.px(x, y, C(0x000000, (d > 1.2 ? 0.5 : (d > 0.95 ? 0.33 : 0.18)) * amount)) }
            }
        }
    }
    // Dust: specks and hairs, a few a frame.
    for i in 0..<5 where rnd(frame, i + 10) < 0.7 {
        let x = Int(rnd(frame, i + 20) * Double(w)), y = Int(rnd(frame, i + 30) * Double(h))
        let light = rnd(frame, i + 40) < 0.4
        let col = light ? C(0xFFF4E0, 0.7 * amount) : C(0x0A0806, 0.8 * amount)
        if i % 2 == 0 { c.rect(x, y, 2, 2, col); c.px(x + 2, y + 1, col) }
        else { for j in 0..<6 { c.px(x + j, y + Int(sin(Double(j) * 0.9) * 2), col) } }
    }
    // Scratches: a thin line down the whole frame, broken here and there, in the same place for a few frames.
    for i in 0..<2 where rnd(frame / 3, i + 50) < 0.6 {
        let x = Int(rnd(frame / 3, i + 60) * Double(w)) + (frame % 3 == 0 ? 1 : 0)
        for y in 0..<h where rnd(y / 6, frame + i * 7) > 0.15 { c.px(x, y, C(0xF0E4CC, 0.45 * amount)) }
    }
}
