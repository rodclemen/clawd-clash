import CoreGraphics
import Foundation

// Ghostfacers Cam (`HuntWipe.ghostfacers`): the trip as Ed and Harry's camcorder sees it. The viewfinder clicks on
// over the old place, night-shot green, with its red REC dot, the battery and the timecode; the picture tears and
// breaks up into static; a ghost flickers past right up against the lens, draining the battery as it goes; and the
// picture comes back on the new place, the green and the viewfinder going off it.

extension HuntTrip {
    /// A frame `k` (0…1) of Ghostfacers Cam, over the whole of `r`. The viewfinder clicks on and the picture turns
    /// night-shot green, with scan lines and video grain (0–0.1); the picture starts slipping in torn bands (0.12–0.34)
    /// and goes to snow (0.28–0.4); the ghost flickers past, pale and glowing, her face still and blank, the
    /// battery running down and LOW BATTERY blinking (0.38–0.66); the snow thins on the new place, still torn (0.48–0.74),
    /// the green goes off it (0.76–0.9) and the viewfinder blinks off (0.9–0.97). Everything over the picture is white
    /// with a black edge, so it reads on any place.
    func drawGhostfacers(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let frame = Int(k * duration * 30)                                   // video, 30 frames a second
        let onAt = k >= 0.015 && k < 0.95 && !(k >= 0.91 && k < 0.93)        // the viewfinder, blinking off at the end
        let green = Self.ease(Self.span(k, 0.02, 0.1)) * (1 - Self.ease(Self.span(k, 0.76, 0.9)))
        let tear = k < 0.45 ? Self.span(k, 0.12, 0.34) : 1 - Self.span(k, 0.5, 0.74)
        let snow = k < 0.45 ? Self.ease(Self.span(k, 0.28, 0.4)) : 1 - Self.ease(Self.span(k, 0.48, 0.7))
        let ghostAt = Self.span(k, 0.38, 0.66)

        // The picture, torn into bands that slip sideways as the signal goes: the old place, then the new one. Night
        // shot turns it green and lifts its darks; that's worked out on the picture itself, not over the whole frame,
        // and where a band slips off the edge the gap shows the bare green.
        let night: [(CGBlendMode, UInt32, Double)] = [(.color, 0x4CE878, 0.85 * green), (.screen, 0x0E3A16, green)]
        let picture = green > 0 ? tinted(k < 0.44 ? old : new, art, like: ctx, night) : (k < 0.44 ? old : new)
        let gap = green > 0 ? bare(like: ctx, night) : nil
        let wobble = (x: Int(sin(k * 9) * 1.5), y: Int(cos(k * 7) * 1.0))     // a handheld camera's sway
        let band = max(3, h / 12)
        for b in 0...(h / band) {
            let big = rnd(b, frame / 2 + 40) > 0.6
            let slip = tear * (rnd(b, frame) - 0.5) * Double(w) * (big ? 0.18 : 0.04)
            let rows = art.frame(0, b * band, w, band).intersection(r)
            guard !rows.isEmpty else { continue }
            let dx = CGFloat((slip.rounded() + Double(wobble.x)) * Double(onAt ? 1 : 0)) * art.px
            let dy = CGFloat(onAt ? -wobble.y : 0) * art.px
            let shot = r.offsetBy(dx: dx, dy: dy).insetBy(dx: onAt ? -2 * art.px : 0, dy: onAt ? -2 * art.px : 0)
            ctx.saveGState(); ctx.clip(to: rows)
            ctx.drawShot(picture, in: shot)
            if let gap {
                ctx.setFillColor(gap)
                for bit in uncovered(rows, by: shot) { ctx.fill(bit) }
            }
            ctx.restoreGState()
        }

        // The static: snow over all of it, green while night shot's on, and lines of it through the torn picture.
        for y in 0..<h {
            let line = rnd(y, frame * 3 + 1) < tear * 0.3
            let a = max(snow, line ? 0.8 : 0)
            guard a > 0.02 else { continue }
            for x in 0..<w {
                let v = noise((x &* 7919 &+ y &* 104729 &+ frame &* 15485863) & 0xFFFFFF)
                let g = v < 0.5 ? 0.08 + v * 0.4 : 0.3 + v * 0.65
                c.px(x, y, Self.mix(0x000000, Self.mixHex(0xF0F0F0, 0xA8FFB8, green), g, a))
            }
        }

        if ghostAt > 0 && ghostAt < 1 { ghost(c, w, h, at: ghostAt, frame: frame) }

        // Video grain and scan lines while the camera's on.
        if onAt {
            for y in 0..<h {
                if y % 2 == 1 { c.rect(0, y, w, 1, C(0x000000, 0.12)) }
                for x in 0..<w {
                    let g = noise((x &* 104729 &+ y &* 7919 &+ frame &* 2750159) & 0xFFFFFF)
                    if g > 0.95 { c.px(x, y, C(green > 0.5 ? 0xC8FFD0 : 0xF0F0F0, 0.2)) }
                    else if g < 0.04 { c.px(x, y, C(0x000000, 0.25)) }
                }
            }
            // How much battery's left: full, drained by the ghost, and back when it's gone.
            let drain = ghostAt > 0 && ghostAt < 1 ? Self.span(ghostAt, 0.1, 0.6) : 0
            let bars = drain > 0.75 ? 0 : (drain > 0.4 ? 1 : (drain > 0.1 ? 2 : 3))
            viewfinder(c, w, h, k: k, frame: frame, bars: bars, nightShot: green > 0.5)
        }
        art.show(ctx)
    }

    /// The camcorder's viewfinder: white corner marks, REC with its red dot blinking, the battery top right (LOW
    /// BATTERY blinking under it when it's flat), NIGHT SHOT while it's green, the timecode counting along the bottom
    /// left, and GHOSTFACERS in amber in the bottom right, as on their footage.
    private func viewfinder(_ c: PixelCanvas, _ w: Int, _ h: Int, k: Double, frame: Int, bars: Int, nightShot: Bool) {
        let p = 2, ink = C(0xF6F6F0), edge = C(0x000000, 0.85)
        let m = max(5, h / 10), arm = max(8, h / 6)
        func mark(_ x: Int, _ y: Int, _ ww: Int, _ hh: Int) {
            c.rect(x - 1, y - 1, ww + 2, hh + 2, edge); c.rect(x, y, ww, hh, ink)
        }
        // The corner marks.
        for (x, y, sx, sy) in [(m, m, 1, 1), (w - m, m, -1, 1), (m, h - m, 1, -1), (w - m, h - m, -1, -1)] {
            mark(sx > 0 ? x : x - arm, sy > 0 ? y : y - 1, arm, 1)
            mark(sx > 0 ? x : x - 1, sy > 0 ? y : y - arm, 1, arm)
        }
        // A small cross in the middle.
        mark(w / 2 - 3, h / 2, 7, 1); mark(w / 2, h / 2 - 3, 1, 7)
        // REC, the dot blinking twice a second.
        let tx = m + 4, ty = m + 4
        if Int(k * duration * 2) % 2 == 0 {
            c.circle(tx + 3, ty + 4, 4, C(0x000000, 0.85)); c.circle(tx + 3, ty + 4, 3, C(0xFF2A1E))
            c.px(tx + 2, ty + 3, C(0xFF9A88))
        }
        huntTripText(c, tx + 10, ty, "REC", ink, p, shadow: C(0x000000))
        let small = w > h * 12 / 5 ? 2 : 1                                   // the window's strip: as big as REC
        if nightShot { huntTripText(c, tx, ty + 7 * p, "NIGHT SHOT", C(0xC8FFD0), small, shadow: C(0x000000)) }
        // The battery: an outline with a nub, and its bars.
        let bw = 9 * p, bh = 4 * p, bx = w - m - 4 - bw - p, by = ty + 1
        c.rect(bx - 1, by - 1, bw + 2, bh + 2, edge); c.rect(bx + bw + 1, by + p - 1, p + 1, bh - 2 * p + 2, edge)
        c.rect(bx, by, bw, bh, ink); c.rect(bx + 1, by + 1, bw - 2, bh - 2, C(0x000000, 0.85))
        c.rect(bx + bw, by + p, p, bh - 2 * p, ink)
        let bar = (bw - 4) / 3
        for i in 0..<bars { c.rect(bx + 2 + i * bar, by + 2, bar - 1, bh - 4, bars == 1 ? C(0xFF4A2A) : ink) }
        if bars == 0 && frame / 4 % 2 == 0 {
            let s = "LOW BATTERY"
            huntTripText(c, w - m - 4 - huntTripTextWidth(s, small), by + bh + 3, s, C(0xFF5A3A), small, shadow: C(0x000000))
        }
        // The timecode, counting in frames.
        let f = 13 * 60 * 30 + 7 * 30 + frame
        let code = String(format: "00:%02d:%02d:%02d", f / 1800 % 60, f / 30 % 60, f % 30)
        huntTripText(c, m + 4, h - m - 4 - 5 * p, code, ink, p, shadow: C(0x000000))
        let name = "GHOSTFACERS"
        huntTripText(c, w - m - 4 - huntTripTextWidth(name, p), h - m - 4 - 5 * p, name, C(0xFFC840), p, shadow: C(0x000000))
    }

    /// A ghost going past right up against the lens, `at` 0…1 from off the left to off the right: a pale woman in a
    /// long white gown flaring out and trailing off behind her in ragged wisps, leaning into her way, an arm reaching
    /// ahead, her long hair streaming back in locks; her face still and blank under a
    /// curtain of hair. A bright rim and a blue glow round her so
    /// she shows on the snow and on any place. She flickers, missing frames and slipping sideways in bands like a bad
    /// signal.
    private func ghost(_ c: PixelCanvas, _ w: Int, _ h: Int, at: Double, frame: Int) {
        guard rnd(frame, 900) > 0.22 else { return }                       // the frames she drops out of
        let gh = Double(h) * 0.92, R = gh / 3
        let cx = -R * 2 + at * (Double(w) + R * 5)
        let top = Double(h) * 0.06 + sin(at * 9) * 2
        let lean = R * 0.35                                                 // her head ahead of her hem
        let head = (x: cx + lean, y: top + R * 0.62)
        func inside(_ x: Double, _ y: Double) -> Bool {
            let v = (y - top) / gh                                          // 0 at the top of her head, 1 at her hem
            guard v >= 0, v <= 1 else { return false }
            // The head.
            let hx = (x - head.x) / (R * 0.46), hy = (y - head.y) / (R * 0.6)
            if hx * hx + hy * hy <= 1 { return true }
            // The gown: from narrow shoulders, flaring, and trailing back off behind her as it goes down, its hem
            // torn into wisps that wave.
            if v > 0.34 {
                let f = (v - 0.34) / 0.66
                let mid = cx + lean * (1 - v) - R * 0.9 * f * f
                let half = R * (0.36 + 0.55 * f)
                let wisp = sin((x - cx) * 0.22 + at * 24) * 0.5 + 0.5
                let hem = 0.82 + 0.16 * wisp
                if abs(x - mid) <= half, v <= hem { return true }
            }
            // The arm, reaching ahead.
            let ax0 = cx + lean * 0.6, ay0 = top + R * 1.3, ax1 = cx + lean + R * 1.2, ay1 = top + R * 1.12
            let t = max(0, min(1, ((x - ax0) * (ax1 - ax0) + (y - ay0) * (ay1 - ay0)) / (pow(ax1 - ax0, 2) + pow(ay1 - ay0, 2))))
            let ex = ax0 + (ax1 - ax0) * t - x, ey = ay0 + (ay1 - ay0) * t - y
            return ex * ex + ey * ey <= pow(R * (0.15 - 0.06 * t), 2)
        }
        // Her hair, streaming back off her head and down her back in long locks, light and dark, that wave as she
        // goes, each ending at its own length so the ends hang in ragged points.
        func hair(_ x: Double, _ y: Double) -> Px? {
            let v = (y - (head.y - R * 0.62)) / (R * 1.9)
            guard v >= 0, v <= 1 else { return nil }
            let front = head.x + R * 0.36 * (1 - v * 1.4), back = head.x - R * (0.55 + 0.7 * v)
            let ragged = sin(y * 0.5 + at * 30) * R * 0.08 * v
            guard x <= front, x >= back + ragged else { return nil }
            let f = (x - back) / max(1, front - back) * 10 + sin(v * 4 + at * 12) * 0.8
            let lock = Int(f.rounded(.down))
            if v > 0.55 + 0.45 * rnd(lock + 20, 31) { return nil }
            if f - f.rounded(.down) < 0.2 { return C(0x48627C, 0.55) }        // the dark between two locks
            switch (lock % 3 + 3) % 3 {
            case 0: return C(0xB8D2E6, 0.6)
            case 1: return C(0x7894B0, 0.55)
            default: return C(0x92AEC6, 0.55)
            }
        }
        let x0 = max(0, Int(cx - R * 2.4)), x1 = min(w - 1, Int(cx + R * 2))
        guard x0 <= x1 else { return }
        let band = max(3, h / 10)
        for y in 0..<h {
            let slip = rnd(y / band, frame + 77) > 0.75 ? Int((rnd(y / band, frame + 78) - 0.5) * R * 0.6) : 0
            for x in x0...x1 {
                let gx = Double(x - slip) + 0.5, gy = Double(y) + 0.5
                if inside(gx, gy) {
                    let rim = !inside(gx - 1.5, gy) || !inside(gx + 1.5, gy) || !inside(gx, gy - 1.5) || !inside(gx, gy + 1.5)
                    c.px(x, y, rim ? C(0xFFFFFF, 0.85) : C(0xD6ECFF, 0.62))
                } else if let lock = hair(gx, gy) {
                    c.px(x, y, lock)
                } else if inside(gx - 3, gy) || inside(gx + 3, gy) || inside(gx, gy - 3) || inside(gx, gy + 3)
                            || hair(gx + 2, gy) != nil {
                    c.px(x, y, C(0x7AC4FF, 0.3))
                }
            }
        }
        // Her face, still and blank: dark, half-shut sockets with a pale glint in each, a small parted mouth, and
        // her hair hanging over her brow and down the far side of her face in locks, hiding half of that eye.
        let hx = Int(head.x), hy = Int(head.y), u = max(1, Int(R * 0.09))
        let rx = R * 0.46, ry = R * 0.6
        func onHead(_ x: Int, _ y: Int) -> Bool {
            let a = (Double(x) + 0.5 - head.x) / rx, b = (Double(y) + 0.5 - head.y) / ry
            return a * a + b * b <= 1
        }
        let socket = C(0x14223A, 0.85)
        for ex in [hx - Int(R * 0.14), hx + Int(R * 0.2)] {
            c.ellipse(ex, hy - u / 2, u + 1, max(1, u / 2 + 1), socket)
            c.rect(ex - u, hy - u / 2 - max(1, u / 2) - 1, 2 * u + 1, 1, C(0x1A2A40, 0.3))    // the shadow of her brow
            c.px(ex + 1, hy - u / 2, C(0xF0FAFF))
        }
        c.ellipse(hx + Int(R * 0.06), hy + Int(R * 0.32), max(1, u - 1), max(1, u / 2), C(0x1A2A40, 0.6))
        let crown = hy - Int(ry)
        for x in (hx - Int(rx))...(hx + Int(R * 0.3)) {
            let lock = (x - hx + 1000) / max(2, u)
            let far = x < hx - Int(R * 0.2)
            let reach = Int(R * (far ? 0.8 + 0.4 * rnd(lock, 41) : 0.24 + 0.1 * rnd(lock, 42)))
            let col = lock % 2 == 0 ? C(0x7894B0, 0.7) : C(0x9AB6CC, 0.7)
            for y in crown...(crown + reach) where onHead(x, y) { c.px(x, y, col) }
        }
    }

    private static func mixHex(_ a: UInt32, _ b: UInt32, _ k: Double) -> UInt32 {
        let p = mix(a, b, k)
        return UInt32(p.r) << 16 | UInt32(p.g) << 8 | UInt32(p.b)
    }
}

/// Noise from a pair of numbers, 0…1.
private func rnd(_ a: Int, _ b: Int) -> Double { noise((a &* 7919 &+ b &* 104729) & 0xFFFFF) }

/// The last few tinted pictures: the old place stays frozen through the trip, so it's the same tint frame after frame.
private var tints: [(img: CGImage, key: [Double], out: CGImage)] = []

/// `img` with each of `fills` (a blend mode, a colour and how strongly) laid over it in turn, as filling the whole
/// frame over it would come out, but worked out on the picture at its own size, not on every pixel of a Retina frame.
/// A place's picture is pixel art with fewer than three pixels across for each of the trip's own art pixels (`art`),
/// so tinting it at no more than that loses nothing, however big the frame.
private func tinted(_ img: CGImage, _ art: HuntArt, like ctx: CGContext, _ fills: [(CGBlendMode, UInt32, Double)]) -> CGImage {
    let key = fills.flatMap { [Double($0.0.rawValue), Double($0.1), $0.2] }
    if let hit = tints.first(where: { $0.img === img && $0.key == key }) { return hit.out }
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
    tints = [(img, key, out)] + tints.prefix(3)
    return out
}

/// What `fills` come to over nothing at all: the colour of a gap where the picture has slipped away.
private func bare(like ctx: CGContext, _ fills: [(CGBlendMode, UInt32, Double)]) -> CGColor? {
    guard let s = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0,
                            space: ctx.colorSpace ?? CGColorSpaceCreateDeviceRGB(), bitmapInfo: layerBitmapInfo) else { return nil }
    for (mode, hex, a) in fills where a > 0 { s.setBlendMode(mode); s.setFillColor(huntTripRGB(hex, CGFloat(a))); s.fill(CGRect(x: 0, y: 0, width: 1, height: 1)) }
    guard let space = s.colorSpace, let d = s.data else { return nil }
    let b = d.assumingMemoryBound(to: UInt8.self)                   // one pixel, BGRA, premultiplied
    let a = CGFloat(b[3]) / 255
    guard a > 0 else { return nil }
    return CGColor(colorSpace: space, components: [CGFloat(b[2]) / 255 / a, CGFloat(b[1]) / 255 / a, CGFloat(b[0]) / 255 / a, a])
}

/// The parts of `band` that `shot` leaves bare.
private func uncovered(_ band: CGRect, by shot: CGRect) -> [CGRect] {
    let on = band.intersection(shot)
    guard !on.isNull, !on.isEmpty else { return [band] }
    return [CGRect(x: band.minX, y: band.minY, width: on.minX - band.minX, height: band.height),
            CGRect(x: on.maxX, y: band.minY, width: band.maxX - on.maxX, height: band.height),
            CGRect(x: on.minX, y: band.minY, width: on.width, height: on.minY - band.minY),
            CGRect(x: on.minX, y: on.maxY, width: on.width, height: band.maxY - on.maxY)].filter { $0.width > 0 && $0.height > 0 }
}
