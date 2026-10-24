import CoreGraphics
import Foundation

// The Road So Far, the signature opening (`HuntWipe.roadSoFar`): the "previously on" that opens every episode. The
// picture turns to grainy, scratched film; THE ROAD SO FAR stamps on word by word; the old place and a few other
// moments flash past as jumpy film stills (Baby on the road at dusk, yellow eyes in the dark); the title smoulders in
// on black like burning letters; then the card NOW, and the new place, the film clearing off it.

extension HuntTrip {
    /// A frame `k` (0…1) of The Road So Far, over the whole of `r`. The old place turns sepia, grain and scratches
    /// coming up, the frame weaving in the gate (0–0.07); it darkens and THE ROAD SO FAR stamps on, a word at a time,
    /// each landing with a jolt (0.07–0.3); five stills cut past, the frame jumping in the gate at each cut
    /// (0.3–0.58); black, and SUPERCLAWDTURAL catches, a front of fire running along it, and burns, flames licking
    /// off the tops of the letters and sparks going up (0.58–0.8); NOW slams on in red (0.8–0.9); a cut, and the new
    /// place, sepia at first, the colour and the grain clearing off it (0.9–1). Everything on the film moves on whole
    /// film frames, 24 a second, so it judders like the real thing.
    func drawRoadSoFar(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let under = HuntArt(r), over = HuntArt(r)
        let w = over.w, h = over.h
        let frame = Int(k * duration * 24)                       // the film's frame, 24 a second
        let filmIn = Self.span(k, 0, 0.07), filmOut = Self.span(k, 0.9, 1)
        let film = k < 0.5 ? Self.ease(filmIn) : 1 - Self.ease(filmOut)

        // The cuts, between the stills and to the new place: on the first film frame after each the frame jumps in
        // the gate, the picture riding down with the black frame line above it.
        let cuts = [0.3, 0.355, 0.41, 0.47, 0.525, 0.58, 0.9]
        let roll = cuts.contains { k >= $0 && k < $0 + 1.0 / (duration * 24) } ? h * 3 / 10 : 0

        // The gate weave: the picture shuffling a pixel or two each film frame, harder through the stills.
        let jump = (k >= 0.3 && k < 0.58) ? 3.0 : 1.4
        let dx = Int(((rnd(frame, 1) - 0.5) * jump * film).rounded())
        let dy = Int(((rnd(frame, 2) - 0.5) * jump * film).rounded()) + roll
        let weave = CGRect(x: r.minX + CGFloat(dx) * under.px, y: r.minY - CGFloat(dy) * under.px,
                           width: r.width, height: r.height)

        // The film look over whatever's showing: darkened under the words, sepia, and a flicker in the brightness,
        // frame by frame. Worked out on each picture before it goes on, not over the whole frame after.
        let flick = rnd(frame, 3)
        let step = { (a: Double) in (a * 8).rounded() / 8 }                // `wash`'s pixel-art steps
        var look: [(CGBlendMode, UInt32, Double)] = []
        if k < 0.3 { look.append((.normal, 0x000000, step(0.55 * Self.span(k, 0.06, 0.09)))) }
        if film > 0 {
            look.append((.color, 0xA27C52, 0.85 * film))
            if flick < 0.3 { look.append((.normal, 0x000000, step(0.125 * film))) }
            else if flick > 0.85 { look.append((.normal, 0xFFF0D8, step(0.125 * film))) }
        }
        func shot(_ img: CGImage, in box: CGRect) { ctx.drawShot(look.isEmpty ? img : tinted(img, under, like: ctx, look), in: box) }

        ctx.setFillColor(huntTripRGB(0x050403)); ctx.fill(r)
        if k < 0.3 {
            shot(old, in: weave)                                    // the old place on film
        } else if k < 0.58 {
            over.c.oy = roll; under.c.oy = roll
            let drawn = stills(under, old: old, k: Self.span(k, 0.3, 0.58), frame: frame, weave: weave, overArt: over,
                               shot: { shot($0, in: $1) })
            over.c.oy = 0; under.c.oy = 0
            if drawn && roll > 0 { under.c.rect(0, 0, w, roll, C(0x050403)) }   // the frame line, black above it
            if drawn, let img = under.c.makeImage() {               // Baby on the road, or the eyes: art of its own
                ctx.saveGState(); ctx.clip(to: r)
                ctx.draw(look.isEmpty ? img : tinted(img, under, like: ctx, look, keep: false), in: under.frame(0, 0, w, h))
                ctx.restoreGState()
            }
        } else if k >= 0.9 {
            shot(new, in: weave)
        }

        if k >= 0.07 && k < 0.3 { stampTitle(over, k: k) }
        if k >= 0.58 && k < 0.8 { burnTitle(over, s: Self.span(k, 0.58, 0.8), frame: frame) }
        if k >= 0.8 && k < 0.9 { stampNow(over, k: Self.span(k, 0.8, 0.9)) }

        // The grain, the dust and the scratches, and the corners going dark like an old print.
        let black = k >= 0.58 && k < 0.9                             // a card on black: no picture, no tint
        let grain = black ? 0.6 : film
        if grain > 0 { filmDirt(over.c, w, h, frame: frame, amount: grain, vignette: !black) }
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

    /// SUPERCLAWDTURAL burning in on black, `s` 0…1, nearly the width of the frame: the letters catch along a ragged
    /// front of fire running from left to right, each stroke from its foot up, each bit flaring pale as it catches and
    /// settling to a smouldering orange that seethes frame by frame, hot yellow along the edges; flames lick up off the tops of the strokes, and sparks rise off them. Just ahead of the front,
    /// a dull red heat glows up where each stroke will be.
    private func burnTitle(_ art: HuntArt, s: Double, frame: Int) {
        let c = art.c, w = art.w, h = art.h
        let title = "SUPERCLAWDTURAL"
        let p = max(2, min(w * 96 / 100 / huntTripTextWidth(title, 1), h * 26 / 100 / 5))
        let x0 = (w - huntTripTextWidth(title, p)) / 2, y0 = (h - 5 * p) / 2
        let mask = PixelCanvas(w, h)
        huntTripText(mask, x0, y0, title, C(0xFFFFFF), p)
        func on(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < w && y < h && mask.buf[(y * w + x) * 4 + 3] > 127 }
        let span = Double(huntTripTextWidth(title, p))
        // When each bit catches: a ragged front of fire running along the title from left to right, each stroke
        // catching at its foot first and burning up it.
        func catches(_ x: Int, _ y: Int) -> Double {
            let up = Double(y0 + 5 * p - y) / Double(5 * p)
            return 0.02 + 0.42 * Double(x - x0) / span + 0.07 * up + 0.025 * sin(Double(y) * 0.9 + Double(x) * 0.21)
        }
        for y in max(0, y0 - 4 * p)..<min(h, y0 + 6 * p) {
            for x in max(0, x0 - 2)..<min(w, x0 + Int(span) + 2) {
                guard on(x, y) else { continue }
                let age = s - catches(x, y)
                if age < -0.1 { continue }
                if age < 0 { c.px(x, y, C(0x6A1408, 0.9 * (age + 0.1) / 0.1)); continue }
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
    /// Says whether it drew a still of its own into `art` (Baby or the eyes) rather than putting the old place on.
    private func stills(_ art: HuntArt, old: CGImage, k s: Double, frame: Int, weave: CGRect, overArt: HuntArt,
                        shot: (CGImage, CGRect) -> Void) -> Bool {
        let ends = [0.196, 0.393, 0.607, 0.804, 1.0]
        let i = ends.firstIndex { s < $0 } ?? 4
        let from = i == 0 ? 0 : ends[i - 1]
        let push = 1 + 0.06 * Self.span(s, from, ends[i])
        func close(_ zoom: Double, _ fx: Double, _ fy: Double) -> Bool {
            let z = CGFloat(zoom * push), rw = weave.width * z, rh = weave.height * z
            let x = weave.minX - (rw - weave.width) * CGFloat(fx), y = weave.minY - (rh - weave.height) * CGFloat(fy)
            shot(old, CGRect(x: x, y: y, width: rw, height: rh))
            return false
        }
        switch i {
        case 0: return close(1.6, 0.2, 0.45)
        case 1: impalaStill(art, frame: frame); return true
        case 2: return close(2.1, 0.8, 0.6)
        case 3: eyesStill(art, over: overArt, frame: frame); return true
        default: return close(1.12, 0.5, 0.5)
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
        // Short, messy hair: the crown a touch wider than the skull above the ears, roughed up into little tufts
        // along the top that lean back, so the head's outline reads as hair, not a smooth dome.
        let hw = hr * 4 / 5 + 1, tuft = max(2, hr / 5)
        for x in (cx - hw)...(cx + hw) {
            let d = Double(x - cx) / Double(hw)
            let skull = Int(Double(hr) * (1 - d * d).squareRoot())
            let lift = Int(rnd(x / 2, 70) * Double(tuft)) + (x % 3 == 0 ? 1 : 0)
            c.rect(x, cy - skull - lift, 1, skull + lift - hr / 3, body)
            if x < cx - hw / 3, lift > tuft / 2 { c.px(x, cy - skull - lift, rim) }    // the light catching a tuft
        }
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

/// The last few tinted pictures: the old place stays frozen through the trip, and the film look over it only takes
/// a handful of turns (the flicker's three), so it's often the same one again.
private var tints: [(img: CGImage, key: [Double], out: CGImage)] = []

/// `img` with each of `fills` (a blend mode, a colour and how strongly) laid over it in turn, as filling the whole
/// frame over it would come out, but worked out on the picture at its own size, not on every pixel of a Retina frame.
/// A place's picture is pixel art with fewer than three pixels across for each of the trip's own art pixels (`art`),
/// so tinting it at no more than that loses nothing, however big the frame.
/// `keep` keeps it for next time (not for art drawn fresh every frame).
private func tinted(_ img: CGImage, _ art: HuntArt, like ctx: CGContext, _ fills: [(CGBlendMode, UInt32, Double)],
                    keep: Bool = true) -> CGImage {
    let key = fills.flatMap { [Double($0.0.rawValue), Double($0.1), $0.2] }
    if keep, let hit = tints.first(where: { $0.img === img && $0.key == key }) { return hit.out }
    let cap = ComicTransition.snapshotQuality == nil                   // not a snapshot of the whole window
    let w = cap ? min(img.width, art.w * 3) : img.width, h = cap ? min(img.height, art.h * 3) : img.height
    let space = ctx.colorSpace ?? CGColorSpaceCreateDeviceRGB()
    // In the frame's own pixel layout if it can be, so drawing it on is a straight copy, not a conversion.
    guard let s = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                            bitmapInfo: ctx.bitmapInfo.rawValue)
            ?? CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                         bitmapInfo: layerBitmapInfo) else { return img }
    let all = CGRect(x: 0, y: 0, width: w, height: h)
    s.interpolationQuality = .none
    s.draw(img, in: all)
    for (mode, hex, a) in fills where a > 0 { s.setBlendMode(mode); s.setFillColor(huntTripRGB(hex, CGFloat(a))); s.fill(all) }
    guard let out = s.makeImage() else { return img }
    if keep { tints = [(img, key, out)] + tints.prefix(5) }
    return out
}

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
