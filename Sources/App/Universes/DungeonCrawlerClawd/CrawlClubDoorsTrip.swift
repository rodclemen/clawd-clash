import CoreGraphics
import Foundation

// The Club Doors (`CrawlWipe.clubDoors`), likelier with the Sledge, Bomo, Doctor Bones or Splash Zone and going to
// the casino or the Parade: the Desperado Club's velvet doors swing shut over the scene, then swing open, neon light
// spilling out of the club, and the new place is inside.

extension CrawlTrip {
    /// The Club Doors, `k` (0…1) through its own part, over the whole of `r`. A pair of tall doors, hinged at the
    /// frame's sides, swing in over the old place, faster and faster (0–0.24): deep purple velvet tufted in diamonds,
    /// a gold stud at every tuft, gold frames, brass handles at the middle; they slam shut and shudder (0.24–0.3), their
    /// neon trim buzzes on in fits (0.28–0.36), and purple light glows in the crack between them and under them,
    /// brighter and brighter (0.3–0.46). Then they swing open away from us, foreshortened and darkening as they turn
    /// (0.46–0.78): the light spills out of the gap, a pink-white blaze at first, then rays fanning out over the doors
    /// and a glow thrown across the floor, the new place inside washed in the club's neon purple; the purple fades off
    /// it in eighths (0.6–0.92). The doors are pixel art on the art's grid, each column of a turning door taken whole
    /// from its flat drawing.
    func drawClubDoors(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.92 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let t = k * CrawlWipe.clubDoors.effect
        let opening = k >= 0.46
        // How far each door is turned, 1 edge-on (open) to 0 (shut): slamming in, swinging out.
        let close = Self.span(k, 0, 0.24), swing = Self.ease(Self.span(k, 0.46, 0.78))
        let turn = opening ? swing : 1 - close * close
        let neon = k < 0.28 ? 0 : (k < 0.36 ? (Int(t * 22) % 3 == 0 ? 0 : 1) : 1.0)
        let glow = Self.span(k, 0.3, 0.46)

        // The place: the old one until they're shut, the new one, in the club's purple light, once they open.
        if opening {
            ctx.drawShot(new, in: r)
            Self.wash(ctx, 0x9A2CE0, 0.5 * (1 - Self.span(k, 0.6, 0.92)), in: r)
        } else {
            ctx.drawShot(old, in: r)
        }

        let half = (w + 1) / 2
        let shut = turn <= 0.001
        let shake = k > 0.24 && k < 0.3 ? (Int(t * 40) % 2 == 0 ? 1 : -1) : 0
        let gapL = Int((Double(half) * cos(turn * .pi / 2)).rounded()), gapR = w - gapL

        // The doors.
        if turn < 1 {
            let door = clubDoor(half, h, neon: neon, t: t)
            let sink = sin(turn * .pi / 2)
            let shade = (sink * 4).rounded() / 4 * 0.55
            for side in 0..<2 {
                let vw = gapL
                guard vw > 0 else { continue }
                for sx in 0..<vw {
                    let u = (Double(sx) + 0.5) / Double(vw)
                    let dx = min(half - 1, Int(u * Double(half)))
                    let colH = Double(h) * (1 - 0.16 * sink * u)
                    let top = (Double(h) - colH) / 2
                    let x = side == 0 ? sx + shake : w - 1 - sx + shake
                    let y0 = Int(top.rounded()), y1 = Int((top + colH).rounded())
                    for y in y0..<y1 {
                        let dy = min(h - 1, Int((Double(y) - top) / colH * Double(h)))
                        let i = (dy * half + (side == 0 ? dx : half - 1 - dx)) * 4
                        guard door.buf[i + 3] > 0 else { continue }
                        let p = unpremultiplied(door, i)
                        c.px(x, y, shade > 0 ? lerp(p, C(0x14061E), shade) : p)
                    }
                }
            }
            // Shut: the crack between them and the gap under them glowing with the club's light.
            if shut && glow > 0 {
                let mid = w / 2
                c.rect(mid - 1 + shake, 0, 2, h, lerp(C(0x9A2CE0), C(0xFFD8FF), glow))
                c.rect(mid - 3 + shake, 0, 6, h, C(0xE070FF, 0.35 * glow))
                c.rect(0, h - 2, w, 2, C(0xE070FF, 0.6 * glow))
            }
            // Opening: the doors' free edges lit by the neon behind them.
            if opening && gapL > 0 {
                let edge = 1 - Self.span(k, 0.66, 0.78)
                c.rect(gapL - 1, 0, 1, h, C(0xFFB8FF, edge))
                c.rect(gapR, 0, 1, h, C(0xFFB8FF, edge))
            }
        }
        // The light spilling out of the gap as they open: a blaze filling it at first, rays fanning over the doors,
        // and a glow thrown across the floor.
        if opening && turn < 1 {
            let mid = Double(w) / 2, top = -Double(h) * 0.15
            let rays = 1 - Self.span(k, 0.62, 0.84)
            if rays > 0 {
                for i in 0..<9 {
                    let spread = Double(w) * (0.15 + 0.85 * swing)
                    let ex = mid + (Double(i) / 8 - 0.5) * spread * 1.6
                    let col = i % 3 == 1 ? C(0xFFD84A) : C(0xE070FF)
                    c.glowLine(mid + (Double(i) / 8 - 0.5) * Double(gapR - gapL) * 0.6, top, ex, Double(h) + 4,
                               core: col.alpha(0.35), glow: col.alpha(0.18), coreR: 1.5, glowR: 4, strength: rays)
                }
            }
            let floor = Self.span(k, 0.5, 0.6) * (1 - Self.span(k, 0.7, 0.88))
            if floor > 0 {
                let rows = max(6, h / 7)
                for y in (h - rows)..<h {
                    let f = Double(y - (h - rows)) / Double(rows)
                    let wide = Double(gapR - gapL) / 2 + f * Double(w) * 0.35
                    c.rect(Int(mid - wide), y, Int(wide * 2), 1, C(0xE070FF, floor * (0.25 + 0.15 * f)))
                }
            }
            let blaze = 1 - Self.span(k, 0.48, 0.64)
            if blaze > 0 {
                c.rect(gapL, 0, gapR - gapL, h, C(0xFFE8FF, (blaze * 4).rounded(.up) / 4 * 0.9))
                c.rect(gapL - 1, 0, gapR - gapL + 2, h, C(0xF070FF, 0.6 * blaze))
            }
        }

        art.show(ctx)
    }
}

/// The left door, flat, `dw`×`dh` art pixels, its hinge on the left and its free edge (by the other door) on the
/// right: deep purple velvet tufted in diamonds, a crease from tuft to tuft, each pillow lit at its top and shaded
/// under, a gold stud at every tuft; a gold frame round it, lit on the top and the hinge side; a brass handle by the
/// free edge, a little above the middle; a neon tube inside the frame, pink with a purple glow, as bright as `neon`.
/// The right door is this one mirrored.
private func clubDoor(_ dw: Int, _ dh: Int, neon: Double, t: Double) -> PixelCanvas {
    let c = PixelCanvas(dw, dh)
    let velvet = C(0x5E1C92), lit = C(0x8A3CC4), deep = C(0x3E0E64), crease = C(0x2A0846)
    let cell = max(10, dh / 7)
    let gold = C(0xE4AC2C), goldL = C(0xFFE47E), goldD = C(0x9A6814)
    for y in 0..<dh {
        for x in 0..<dw {
            let a = ((x + y) % cell + cell) % cell, b = ((x - y) % cell + cell) % cell
            let col: Px
            if a == 0 || b == 0 { col = crease }
            else if a < cell / 4 && b > cell * 3 / 4 { col = lit }   // the top corner of each pillow
            else if a > cell * 3 / 4 && b < cell / 4 { col = deep }  // the bottom corner
            else if a < cell / 3 { col = lerp(velvet, lit, 0.4) }
            else if a > cell * 2 / 3 { col = lerp(velvet, deep, 0.5) }
            else { col = velvet }
            c.px(x, y, col)
        }
    }
    // The studs, at every tuft (where the creases cross).
    let sd = max(2, dh / 60)
    for y in stride(from: 0, through: dh, by: 1) {
        for x in 0..<dw where (x + y) % cell == 0 && ((x - y) % cell + cell) % cell == 0 {
            c.rect(x - sd / 2, y - sd / 2, sd, sd, gold)
            c.px(x - sd / 2, y - sd / 2, goldL)
        }
    }
    // The gold frame.
    let f = max(3, dh / 36)
    c.rect(0, 0, dw, f, gold); c.rect(0, dh - f, dw, f, gold)
    c.rect(0, 0, f, dh, gold); c.rect(dw - f, 0, f, dh, gold)
    c.rect(0, 0, dw, 1, goldL); c.rect(0, 0, 1, dh, goldL)
    c.rect(f - 1, f - 1, dw - 2 * f + 2, 1, goldD); c.rect(f - 1, f - 1, 1, dh - 2 * f + 2, goldD)
    c.rect(0, dh - 1, dw, 1, goldD); c.rect(dw - 1, 0, 1, dh, goldD)
    // The neon tube, just inside the frame.
    if neon > 0 {
        let n = f + 2, flick = 0.85 + 0.15 * sin(t * 40)
        let core = C(0xFFA8FF, neon * flick), halo = C(0xC040FF, 0.55 * neon * flick)
        c.rect(n - 1, n - 1, dw - 2 * n + 2, 3, halo); c.rect(n - 1, dh - n - 2, dw - 2 * n + 2, 3, halo)
        c.rect(n - 1, n - 1, 3, dh - 2 * n + 2, halo); c.rect(dw - n - 2, n - 1, 3, dh - 2 * n + 2, halo)
        c.rect(n, n, dw - 2 * n, 1, core); c.rect(n, dh - n - 1, dw - 2 * n, 1, core)
        c.rect(n, n, 1, dh - 2 * n, core); c.rect(dw - n - 1, n, 1, dh - 2 * n, core)
    }
    // The brass handle by the free edge: a plate, and a bar standing off it.
    let hw = max(5, dw / 24), hh = max(18, dh * 22 / 100)
    let hx = dw - f - 4 - hw - 2, hy = dh * 40 / 100 - hh / 2
    let brass = C(0xC8963A), brassL = C(0xF6D27A), brassD = C(0x7A5418)
    c.rect(hx - 1, hy - 1, hw + 2, hh + 2, C(0x1A0A10))
    c.rect(hx, hy, hw, hh, brassD)
    c.rect(hx + 1, hy + 1, hw - 2, hh - 2, brass)
    c.rect(hx + 1, hy + 1, hw - 2, 1, brassL); c.rect(hx + 1, hy + 1, 1, hh - 2, brassL)
    let bx = hx + hw / 2 - 1
    c.rect(bx - 1, hy + 3, 4, hh - 6, C(0x1A0A10))
    c.rect(bx, hy + 4, 2, hh - 8, brassL)
    c.rect(bx + 1, hy + 4, 1, hh - 8, brass)
    return c
}
