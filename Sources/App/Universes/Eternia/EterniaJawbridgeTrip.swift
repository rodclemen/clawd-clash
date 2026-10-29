import CoreGraphics
import Foundation

// The Jawbridge (`EterniaWipe.jawbridge`): the scene turns to stone and becomes Castle Greyskull's skull face, close
// up at dusk, its jaw shut; the jawbridge drops like a mouth falling open, and the new place is through the doorway,
// rushing up until it fills the screen. The castle is the place's own drawing (`Scenes.eterniaGreyskullCastle`), so
// it's the same Greyskull, blown up.

extension EterniaTrip {
    /// The Jawbridge, `k` (0…1) through its own part, over the whole of `r`. The old place turns to stone a dither at
    /// a time from the middle out, and is the skull face, close up, its jaw shut (0–0.22); the castle rumbles, shaking
    /// (0.2–0.3); the jaw falls open, its stone face folding down and its plank deck coming down across the chasm on
    /// its chains, the doorway a dark mouth with the new place in it (0.28–0.5); the doorway rushes up, the teeth and the
    /// deck sweeping off the edges, until the new place fills the screen (0.5–0.75) and the dark inside lifts off it
    /// (to 0.8). Every picture of the castle is pixel art blown up whole pixels at a time, never smoothed.
    func drawJawbridge(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k < 0.985 else { ctx.drawShot(new, in: r); return }
        let art = EterniaArt(r)
        let c = art.c, w = art.w, h = art.h
        let turn = Self.span(k, 0, 0.22)
        let shake = k > 0.2 && k < 0.3 ? (Int(k * 1.9 / 0.04) % 2 == 0 ? 1.0 : -1.0) : 0
        let drop = pow(Self.span(k, 0.28, 0.5), 2)
        let rush = Self.span(k, 0.5, 1)

        let world = eterniaJawWorld(drop: drop)
        // The camera: on the face at first, whole pixels three or four to one; then in to the doorway, until it's all
        // doorway by the rush's middle (the mouth is only five rows tall under its teeth, so it takes a close look),
        // the teeth above and the deck below sweeping off the frame's edges; the new place has the rest to itself.
        let z0 = Double(art.wide ? 3 : 4), zf = 48.0
        let zoom = z0 * pow(zf / z0, Self.ease(Self.span(rush, 0, 0.6)))
        let move = Self.ease(Self.span(rush, 0, 0.45))
        let cx = eterniaJawFace.x + shake / zoom, cy = eterniaJawFace.y + (eterniaJawDoor.y - eterniaJawFace.y) * move
        let halfW = Double(w) / 2, halfH = Double(h) / 2
        let far = (halfW * halfW + halfH * halfH).squareRoot()

        var hole = [Bool](repeating: false, count: w * h)
        for y in 0..<h {
            let wy = cy + (Double(y) + 0.5 - halfH) / zoom
            let iy = max(0, min(world.c.h - 1, Int(floor(wy))))
            for x in 0..<w {
                if turn < 1 {
                    // Turning to stone: a pixel at a time, by a dither, from the middle out.
                    let dx = Double(x) - halfW, dy = Double(y) - halfH
                    let v = eterniaJawBayer[(y % 4) * 4 + x % 4] * 0.5 + 0.5 * (dx * dx + dy * dy).squareRoot() / far
                    if v >= turn { continue }
                }
                let wx = cx + (Double(x) + 0.5 - halfW) / zoom
                let ix = max(0, min(world.c.w - 1, Int(floor(wx))))
                if world.hole[iy * world.c.w + ix] { hole[y * w + x] = true; continue }
                c.px(x, y, unpremultiplied(world.c, (iy * world.c.w + ix) * 4))
            }
        }

        // Underneath: the old place while it turns to stone, then the new one through the doorway, dark in there at
        // first and lighting up as it comes.
        ctx.drawShot(k < 0.28 ? old : new, in: r)
        let dark = 0.75 * (1 - Self.span(k, 0.42, 0.8))
        if dark > 0 {
            let runs = art.runs { hole[$1 * w + $0] }
            if !runs.isEmpty {
                ctx.saveGState(); ctx.clip(to: runs)
                Self.wash(ctx, 0x0E1012, dark, in: r)
                ctx.restoreGState()
            }
        }
        art.show(ctx)
    }
}

/// Where the camera looks at first (the skull's face) and where it ends (the open doorway, the middle of the dark
/// between the teeth on row 52 and the deck on row 58), in the world's pixels.
private let eterniaJawFace = (x: 150.0, y: 44.0), eterniaJawDoor = (x: 150.0, y: 55.5)

/// A 4×4 ordered dither, thresholds in 0…1.
private let eterniaJawBayer: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

/// The world the camera looks at, one pixel to a unit, 300×90: the dusk sky banded violet to orange with the sun low
/// on the left, long clouds and the far peaks; Castle Greyskull on its cliff, its foot on row 58; the chasm below; and
/// the jaw, `drop` (0…1) of the way down. Shut, it's a slab of the skull's stone filling the mouth with a row of teeth
/// along its top; falling, its stone face folds down out of sight and its plank deck comes down over the chasm,
/// widening towards us, teeth along its near end and a chain from either side of the mouth to its corners. `hole`
/// says which pixels are the open doorway (where the mouth's dark is still showing once the jaw has begun to drop).
private func eterniaJawWorld(drop: Double) -> (c: PixelCanvas, hole: [Bool]) {
    let W = 300, H = 90, ox = 90, oy = 4, hinge = 58, chasm = 64
    let c = PixelCanvas(W, H)
    c.gradient(0, hinge, C(0x2A1C4C), C(0xF0904A), bands: 8)
    for (m, a) in [(2.2, 0.12), (1.6, 0.2)] { c.circle(52, 46, Int(9 * m), C(0xFFB060, a)) }
    c.circle(52, 46, 9, C(0xFFD890)); c.circle(50, 44, 6, C(0xFFEAB4))
    for (i, b) in [(8, 18, 40), (218, 12, 36), (246, 32, 30), (24, 34, 26), (92, 8, 24)].enumerated() {
        Scenes.eterniaCloudBank(c, b.0, b.1, b.2, 1, seed: i)
    }
    c.dunes(base: 50, amp: 4, freq: 0.06, phase: 0.7, bottom: hinge, C(0x8A5486), shade: C(0xA46A96))
    c.dunes(base: 54, amp: 3, freq: 0.09, phase: 2.3, bottom: hinge, C(0x56385E), shade: C(0x6A4670))
    // The cliff the castle stands on: a ragged lip lit by the sunset, strata down its face.
    let rock = C(0x4A4652), rockD = C(0x322E3A), rockL = C(0x6E6874)
    for x in 0..<W {
        let lip = hinge - Int(noise(x + 400) * 2)
        c.rect(x, lip, 1, chasm - lip, rock); c.px(x, lip, rockL)
        if x % 7 == 3 { c.rect(x, hinge + 1, 1, chasm - hinge - 2, rockD) }
    }
    c.rect(0, chasm - 1, W, 1, rockD)
    c.gradient(chasm, H, C(0x1A2620), C(0x080C0A), bands: 4)

    // The castle.
    let castle = PixelCanvas(120, 56)
    Scenes.eterniaGreyskullCastle(castle)
    for y in 0..<56 {
        for x in 0..<120 where castle.buf[(y * 120 + x) * 4 + 3] > 0 {
            c.px(ox + x, oy + y, unpremultiplied(castle, (y * 120 + x) * 4))
        }
    }

    // The jaw. Its edge (the top while it's shut, the near end once it's down) runs from row 53 down to 88.
    let mx = ox + 47, mw = 27, mid = Double(mx) + Double(mw) / 2
    let edge = 53 + Int((35 * drop).rounded())
    let tooth = C(0xC8D0B4), toothD = C(0x94A086), jaw = C(0x7E9074), jawD = C(0x56664E), jawL = C(0x92A482)
    let wood = C(0x8A6438), woodD = C(0x5E4224)
    var corners = (Double(mx), Double(mx + mw))
    if edge < hinge {
        // Its stone face, folding down: teeth along the top, lit on the left.
        for y in edge..<hinge {
            c.rect(mx, y, mw, 1, jaw); c.px(mx, y, jawL); c.px(mx + mw - 1, y, jawD)
        }
        c.rect(mx, edge, mw, 1, C(0x1A2018))
        for i in 0..<6 where edge >= 53 {
            let tx = mx + 2 + i * 4
            c.rect(tx, edge - 2, 3, 2, tooth); c.px(tx + 2, edge - 2, toothD); c.px(tx + 2, edge - 1, toothD)
        }
    } else {
        // Its deck, down over the chasm and widening towards us: planks between stone rails, teeth at the near end.
        for y in hinge..<max(hinge + 1, edge) {
            let f = Double(y - hinge) / 30
            let bw = Int(Double(mw) * (1 + 0.8 * f)), bx = Int(mid) - bw / 2, rail = 1 + Int(f * 2)
            c.rect(bx, y, bw, 1, (y - hinge) / 2 % 2 == 0 ? wood : woodD)
            c.rect(bx, y, rail, 1, jaw); c.rect(bx + bw - rail, y, rail, 1, jawD)
            corners = (Double(bx), Double(bx + bw))
        }
        let ew = Int(corners.1 - corners.0), tw = max(2, ew / 10)
        for i in 0..<5 where drop > 0.6 {
            let tx = Int(corners.0) + ew * (2 * i + 1) / 10 - tw / 2
            c.rect(tx, edge - 3, tw, 3, tooth); c.rect(tx + tw - 1, edge - 3, 1, 3, toothD)
        }
    }
    // The chains, from either side of the mouth's top down to the jaw's corners.
    if drop > 0 {
        for (side, x0) in [(0, Double(mx)), (1, Double(mx + mw - 1))] {
            let x1 = side == 0 ? corners.0 : corners.1 - 1, y0 = Double(oy + 47), y1 = Double(edge - 1)
            let n = max(4, Int(abs(y1 - y0) + abs(x1 - x0)))
            for i in 0...n {
                let t = Double(i) / Double(n)
                c.px(Int(x0 + (x1 - x0) * t), Int(y0 + (y1 - y0) * t), i % 2 == 0 ? C(0x3A3A42) : C(0x6A6A74))
            }
        }
    }

    // The doorway: the mouth's dark, wherever it still shows, once the jaw has begun to drop.
    var hole = [Bool](repeating: false, count: W * H)
    if drop > 0 {
        for y in (oy + 45)...hinge {
            for x in (mx - 1)...(mx + mw) {
                let i = (y * W + x) * 4
                if c.buf[i] == 0x0E && c.buf[i + 1] == 0x10 && c.buf[i + 2] == 0x12 { hole[y * W + x] = true }
            }
        }
    }
    return (c, hole)
}
