import CoreGraphics
import Foundation

// Headlights (`HuntWipe.headlights`): night falls on the old place, Baby drives across it nose to the right, and the
// wedge of light her headlight throws ahead of her sweeps the new place into view; behind her the new place waits in
// the dark, and when she's gone the night lifts off it.

extension HuntTrip {
    /// A frame `k` (0…1) of Headlights, over the whole of `r`. The old place darkens to a deep blue night (0–0.22);
    /// the Impala comes in from the left, wheels turning, her headlight lit, and drives across and out (0.1–0.8). Ahead
    /// of her the headlights flick on and off and on, and the beam opens into a wedge of warm light, bright near the
    /// lamp and falling off smoothly (dithered) as it reaches, its edges picked out, and inside it is the new place lit
    /// up out of a deep night; behind her, and round the beam as far as its light reaches, it's the new place too,
    /// still in the dark, so the old place goes at a curved front just ahead of the beam. Dust drifts in the beam, a
    /// puff of exhaust hangs behind her and her tail lights glow red. Then the night lifts off the new place (0.8–1).
    /// She's drawn as Baby is in HuntRides.swift, at twice the ride's size.
    func drawHeadlights(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let night = 0.875 * Self.ease(Self.span(k, 0, 0.22)) * (1 - Self.ease(Self.span(k, 0.8, 1)))
        let drive = Self.span(k, 0.1, 0.8)

        // Where she is: her nose from just off the left edge to well past the right, so the beam has crossed it all.
        let s = 2
        let carW = Ride.width * s, carH = Ride.height * s
        let reach = Double(w) * (art.wide ? 0.4 : 0.42)                      // how far the beam's edges throw
        let nose = Int(-4 + drive * (Double(w + carW) + 8))
        let carX = nose - carW, carY = h - max(4, h / 14) - carH
        let lamp = (x: carX + 62 * s, y: carY + 17 * s + s / 2)
        let up = Double(lamp.y) * 1.15, down = Double(h - lamp.y) + 6       // the wedge's spread at its far end
        func far(_ x: Int, _ y: Int) -> Double {                            // how far from the lamp, 1 at the light's reach:
            let dx = Double(x - lamp.x) / reach, dy = Double(y - lamp.y) / up // a pool bulging out ahead of her
            return (dx * dx + dy * dy).squareRoot() / 2.0.squareRoot()
        }
        func beam(_ x: Int, _ y: Int) -> Double? {                          // how far along the beam, or nil outside it
            let dx = Double(x - lamp.x), dy = Double(y - lamp.y), d = far(x, y)
            guard dx >= 0, d <= 1, dy >= -1 - dx * up / reach, dy <= 1 + dx * down / reach else { return nil }
            return d
        }
        let driving = k >= 0.1 && k < 0.8
        // Her headlights flick on as she comes in (off, on, off, then on for good), and burn brightest just after.
        let flick = k < 0.115 || (k >= 0.125 && k < 0.14) ? 0.0 : 1 + 0.35 * (1 - Self.span(k, 0.14, 0.3))

        // The old place, going dark.
        ctx.drawShot(old, in: r)
        Self.wash(ctx, 0x07101E, night, in: r)
        if k >= 0.8 {
            ctx.drawShot(new, in: r)
            Self.wash(ctx, 0x07101E, night, in: r)
        } else if driving {
            // Behind her and as far as the light reaches, the new place: its edge a curve round the lamp. It's dark
            // but for the beam, where the light falls off smoothly from the lamp, dithered in pixel-art steps (no
            // rings), warm and bright close to her and fading into the night at its reach.
            let behind = art.runs { x, y in x < lamp.x || far(x, y) <= 1 }
            if !behind.isEmpty {
                ctx.saveGState(); ctx.clip(to: behind); ctx.drawShot(new, in: r); ctx.restoreGState()
            }
            let dark = (night * 8).rounded() / 8
            for y in 0..<h {
                for x in 0..<w where x < lamp.x || far(x, y) <= 1 {
                    guard let t = beam(x, y), flick > 0 else { c.px(x, y, C(0x07101E, dark)); continue }
                    let fall = (1 - t * t * t) * flick                     // the light here: full most of the way, then fading
                    let steps = 6.0, level = min(steps, floor(fall * steps + headlightsBayer(x, y))) / steps
                    if level < 1 { c.px(x, y, C(0x07101E, ((night * (1 - level) * 8).rounded() / 8))) }
                    if level > 0 { c.px(x, y, C(0xFFE2A0, 0.3 * level)) }
                }
            }
        }

        if driving && flick > 0 {
            // The beam's edges, picked out so the wedge reads on any place, and dust drifting in it.
            for x in stride(from: max(0, lamp.x), to: min(w, lamp.x + Int(reach)), by: 1) {
                let t = Double(x - lamp.x) / reach
                let yt = Int((Double(lamp.y) - 1 - t * up).rounded()), yb = Int((Double(lamp.y) + 1 + t * down).rounded())
                if far(x, yt) <= 1 { c.px(x, yt, C(0xFFF0C4, 0.55 * (1 - far(x, yt)))) }
                if far(x, yb) <= 1 { c.px(x, yb, C(0xFFF0C4, 0.4 * (1 - far(x, yb)))) }
            }
            for i in 0..<26 {
                let x = lamp.x + Int(noise(i * 31 + 7) * reach), drift = Int(k * 40 + noise(i) * 9) % 9
                let y = Int(noise(i * 17 + 3) * Double(h)) - drift
                if let t = beam(x, y) { c.px(x, y, C(0xFFF6DC, 0.7 * (1 - t))) }
            }
        }
        if driving {
            // Exhaust puffs hanging behind her, thinning as they go.
            for i in 0..<4 {
                let age = (k * 9 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
                let px = carX - 2 - Int(age * 26), py = carY + 22 * s - Int(age * 6)
                c.circle(px, py, 2 + Int(age * 4), C(0x9AA2B4, 0.4 * (1 - age)))
            }
            // Her tail lights' glow, and the car.
            c.rect(carX - 3 * s, carY + 16 * s, 3 * s, 4 * s, C(0xFF3A2A, 0.22))
            let car = PixelCanvas(Ride.width, Ride.height)
            huntDrawImpala(car, ramp: 0, moving: true, t: k * duration)
            blit(car, into: c, x: carX, y: carY, scale: s)
            // The lamp itself, flaring: a long glint across and a short one up, as a lens catches a headlight.
            if flick > 0 {
                let glint = Int(6 + 4 * flick)
                c.rect(lamp.x - glint, lamp.y, 2 * glint + 1, 1, C(0xFFFBE8, 0.5))
                c.rect(lamp.x - glint / 2, lamp.y, glint + 1, 1, C(0xFFFBE8, 0.8))
                c.rect(lamp.x, lamp.y - 3, 1, 7, C(0xFFFBE8, 0.7))
                c.circle(lamp.x, lamp.y, 4, C(0xFFF4C8, 0.35))
                c.rect(lamp.x - 1, lamp.y - 1, 3, 3, C(0xFFFFFF))
            } else {
                c.rect(lamp.x - 1, lamp.y - 1, 3, 3, C(0x8A8470))
            }
        }
        art.show(ctx)
    }
}

/// A 4×4 ordered dither, 0…1 at each pixel: steps a smooth fall-off into pixel-art checks instead of hard rings.
private func headlightsBayer(_ x: Int, _ y: Int) -> Double {
    let m = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    return (Double(m[(y & 3) * 4 + (x & 3)]) + 0.5) / 16
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
