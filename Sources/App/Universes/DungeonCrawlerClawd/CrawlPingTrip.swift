import CoreGraphics
import Foundation

// Ping (`CrawlWipe.ping`), Carl's spell, likelier with Carl or Elle the scout: a radar pulse rings out over a dungeon
// map grid, dots light up, and the map fades into the new place.

extension CrawlTrip {
    /// Ping, `k` (0…1) through its own part, over the whole of `r`. The System's map comes down over the old place,
    /// a bright scan line sweeping from the top to the bottom and leaving the map behind it (0–0.22): navy, a blue
    /// grid, the dungeon's rooms and corridors in lighter blue with bright walls. In the middle, where the crew are,
    /// the spell goes off, PING! in gold over a white spark (0.2–0.34), and two rings of electric blue run out from
    /// there across the map, each with a fading wake (0.22–0.62 and 0.36–0.76). As the first passes them, dots light
    /// up with a white flash: the party, green, round the middle; monsters, red, in the rooms, blinking; a gold boss
    /// in the room farthest off. Then the map fades away onto the new place, in eighths, the bright walls and the dots
    /// last (0.6–0.94).
    func drawPing(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        guard k > 0 else { ctx.drawShot(old, in: r); return }
        guard k < 0.94 else { ctx.drawShot(new, in: r); return }
        let art = CrawlArt(r)
        let c = art.c, w = art.w, h = art.h
        let scan = Self.span(k, 0, 0.22)
        let fade = Self.span(k, 0.6, 0.94)
        let map = crawlPingMap(w, h)
        let T = map.tile
        let cx = Double(w) / 2, cy = Double(h) / 2
        let far = (cx * cx + cy * cy).squareRoot() + 4
        let rings = [Self.ease(Self.span(k, 0.22, 0.62)) * far, Self.ease(Self.span(k, 0.36, 0.76)) * far]
        let scanY = Int(scan * Double(h + 2))

        // The map, a tile at a time: the floor in lighter blue, the walls bright where floor meets rock, the grid.
        // It fades in two steps: the floor and the grid first, then the walls.
        let body = (1 - Self.span(fade, 0, 0.7)) , walls = 1 - Self.span(fade, 0.3, 1)
        let step = { (a: Double) in (a * 8).rounded() / 8 }
        for y in 0..<min(h, scanY) {
            for x in 0..<w {
                let tx = x / T, ty = y / T
                let floor = map.floor(tx, ty)
                var hex: UInt32 = floor ? 0x163C8C : 0x08143A
                var a = step(body)
                if floor {
                    let lx = x % T, ly = y % T
                    let edge = (lx == 0 && !map.floor(tx - 1, ty)) || (lx == T - 1 && !map.floor(tx + 1, ty))
                        || (ly == 0 && !map.floor(tx, ty - 1)) || (ly == T - 1 && !map.floor(tx, ty + 1))
                    if edge { hex = 0x6AB4FF; a = step(walls) }
                } else if x % T == 0 || y % T == 0 {
                    hex = 0x14306E
                }
                // The rings and their wakes.
                let dd = (pow(Double(x) + 0.5 - cx, 2) + pow(Double(y) + 0.5 - cy, 2)).squareRoot()
                for (i, ring) in rings.enumerated() where ring > 0 && ring < far {
                    let behind = ring - dd
                    if behind >= 0 && behind < 2 { hex = i == 0 ? 0xDCF0FF : 0x9CD8FF; a = max(a, step(walls)) }
                    else if behind >= 2 && behind < 18 {
                        let glow = (1 - (behind - 2) / 16) * (i == 0 ? 0.55 : 0.4)
                        hex = Self.mixHexPing(hex, 0x3A8CFF, (glow * 4).rounded() / 4)
                    }
                }
                guard a > 0 else { continue }
                c.px(x, y, C(hex, a))
            }
        }
        // The scan line, bright, with a soft row either side.
        if scan > 0 && scan < 1 {
            c.rect(0, scanY - 2, w, 1, C(0x3A8CFF, 0.5)); c.rect(0, scanY - 1, w, 1, C(0xDCF0FF))
            c.rect(0, scanY, w, 1, C(0x3A8CFF, 0.5))
        }

        // The dots, lighting up as the first ring reaches them.
        let blink = Int(k * 24) % 2 == 0
        for dot in map.dots {
            let dd = (pow(Double(dot.x) - cx, 2) + pow(Double(dot.y) - cy, 2)).squareRoot()
            guard rings[0] >= dd, dot.y < scanY else { continue }
            let since = (rings[0] - dd) / far
            let a = step(walls)
            guard a > 0 else { continue }
            let hex: UInt32 = since < 0.06 ? 0xFFFFFF : dot.kind.colour
            let size = dot.kind == .boss ? 3 : 2
            if since < 0.06 { c.rect(dot.x - 1, dot.y - 1, size + 2, size + 2, C(hex, a * 0.5)) }
            if dot.kind == .monster && !blink && since > 0.1 { c.rect(dot.x, dot.y, size, size, C(0x8A1A20, a)); continue }
            c.rect(dot.x, dot.y, size, size, C(hex, a))
            if dot.kind == .boss { c.rect(dot.x - 1, dot.y + 1, size + 2, 1, C(hex, a)) }
        }

        // The spell going off in the middle: a white spark and PING! over it.
        let cast = Self.span(k, 0.2, 0.34)
        if cast > 0 && cast < 1 {
            let mx = Int(cx), my = Int(cy)
            let arm = Int((2 + 4 * sin(cast * .pi)).rounded())
            for i in -arm...arm {
                let col = abs(i) < arm / 2 ? C(0xFFFFFF) : C(0x9CD8FF)
                c.px(mx + i, my, col); c.px(mx, my + i, col)
            }
            let s = art.wide ? 2 : 3, word = "PING!"
            let ww = crawlTextWidth(word, scale: s)
            let wy = my - 9 - 5 * s - Int(cast * 4)
            crawlText(c, mx - ww / 2 + 1, wy + 1, word, C(0x3A2A04), scale: s)
            crawlText(c, mx - ww / 2, wy, word, C(0xF8D058), scale: s)
        }

        // Under the map: the old place until the map has covered it, then the new one, which the map fades onto.
        ctx.drawShot(scan < 1 ? old : new, in: r)
        art.show(ctx)
    }

    /// A colour `k` of the way from `a` to `b`, as 0xRRGGBB.
    private static func mixHexPing(_ a: UInt32, _ b: UInt32, _ k: Double) -> UInt32 {
        func ch(_ s: UInt32) -> UInt32 {
            let x = Double(a >> s & 0xFF), y = Double(b >> s & 0xFF)
            return UInt32(max(0, min(255, (x + (y - x) * k).rounded())))
        }
        return ch(16) << 16 | ch(8) << 8 | ch(0)
    }
}

/// What a dot on the map is.
private enum CrawlPingDot {
    case party, monster, boss
    var colour: UInt32 {
        switch self {
        case .party: return 0x5CF07A
        case .monster: return 0xFF3A3A
        case .boss: return 0xF8D058
        }
    }
}

/// The dungeon map for a `w`×`h` frame: tiles of `tile` pixels, a room in the middle where the crew stand and rooms
/// scattered round it, each joined to the middle one by an L of corridor; and the dots, in tile pixels.
private struct CrawlPingMap {
    let tile: Int, tw: Int, th: Int
    var cells: [Bool]
    var dots: [(x: Int, y: Int, kind: CrawlPingDot)] = []
    func floor(_ x: Int, _ y: Int) -> Bool { x >= 0 && y >= 0 && x < tw && y < th && cells[y * tw + x] }
}

private func crawlPingMap(_ w: Int, _ h: Int) -> CrawlPingMap {
    let T = h > 130 ? 5 : 4
    let tw = w / T + 1, th = h / T + 1
    var m = CrawlPingMap(tile: T, tw: tw, th: th, cells: [Bool](repeating: false, count: tw * th))
    func carve(_ x: Int, _ y: Int, _ cw: Int, _ ch: Int) {
        for yy in max(0, y)..<min(th, y + ch) { for xx in max(0, x)..<min(tw, x + cw) { m.cells[yy * tw + xx] = true } }
    }
    let mx = tw / 2, my = th / 2
    carve(mx - 3, my - 2, 7, 5)
    // Rooms round the middle, one to each slot of a loose grid, a few slots left as solid rock.
    var rooms: [(x: Int, y: Int, w: Int, h: Int)] = []
    let gx = max(3, tw / 12), gy = 3
    for j in 0..<gy {
        for i in 0..<gx {
            let n = j * 31 + i * 7
            let sw = tw / gx, sh = th / gy
            guard noise(n + 500) > 0.18 else { continue }
            let rw = 3 + Int(noise(n + 501) * Double(max(1, sw - 6))), rh = 2 + Int(noise(n + 502) * Double(max(1, sh - 4)))
            let rx = i * sw + 1 + Int(noise(n + 503) * Double(max(1, sw - rw - 2)))
            let ry = j * sh + 1 + Int(noise(n + 504) * Double(max(1, sh - rh - 2)))
            if abs(rx + rw / 2 - mx) < 6 && abs(ry + rh / 2 - my) < 4 { continue }
            rooms.append((rx, ry, rw, rh)); carve(rx, ry, rw, rh)
            // An L of corridor from the room to the middle: across, then up or down.
            let ax = rx + rw / 2, ay = ry + rh / 2
            carve(min(ax, mx), ay, abs(ax - mx) + 1, 1)
            carve(mx, min(ay, my), 1, abs(ay - my) + 1)
        }
    }
    // The party round the middle; a monster or two in each room; the boss in the room farthest off.
    for (dx, dy) in [(-3, -1), (2, -2), (-1, 2), (3, 1)] { m.dots.append((mx * T + dx * 2, my * T + dy * 2, .party)) }
    var farthest = -1, best = -1
    for (i, rm) in rooms.enumerated() {
        let d = abs(rm.x + rm.w / 2 - mx) + abs(rm.y + rm.h / 2 - my) * 2
        if d > best { best = d; farthest = i }
        let count = 1 + Int(noise(i * 9 + 600) * 2)
        for n in 0..<count {
            let x = (rm.x * T) + 1 + Int(noise(i * 9 + n * 3 + 601) * Double(max(1, rm.w * T - 4)))
            let y = (rm.y * T) + 1 + Int(noise(i * 9 + n * 3 + 602) * Double(max(1, rm.h * T - 4)))
            m.dots.append((x, y, .monster))
        }
    }
    if farthest >= 0 {
        let rm = rooms[farthest]
        m.dots.append(((rm.x + rm.w / 2) * T - 1, (rm.y + rm.h / 2) * T - 1, .boss))
    }
    return m
}
