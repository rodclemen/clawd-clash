import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// Player killers and the Syndicate: Burcu, Agatha, Tsarina Signet, Vrah, Stalwart, Loita, Harbinger, Astrid.

let crawlVillains6: [CrawlVillain: Persona] = [
    .burcu: Persona(name: "Burcu", weapon: .saber, headTop: 15, signature: 3.0, draw: drawBurcu),
    .agatha: Persona(name: "Agatha", weapon: .lightning,
                     magic: Magic(core: C(0xF4F6FA), glow: C(0x9AA4B4), jagged: false, waves: true), pivot: (45, 28),
                     headTop: 19, signature: 3.6, draw: drawAgatha),
    .tsarina: Persona(name: "Tsarina Signet", weapon: .lightning,
                      magic: Magic(core: C(0xFF6A6A), glow: C(0x8A0E1E), jagged: false, spell: true), pivot: (43, 32),
                      headTop: 19, signature: 3.2, draw: drawTsarina),
    .vrah: Persona(name: "Vrah", weapon: .blaster, motion: .fly, shot: .arrow, muzzle: (50, 34), handGun: false,
                   headTop: 13, signature: 2.6, draw: drawVrah),
    .stalwart: Persona(name: "Stalwart", weapon: .saber, bulk: 2, headTop: 15, signature: 2.8, draw: drawStalwart),
    .loita: Persona(name: "Loita", headTop: 15, signature: 3.2, draw: drawLoita),
    .harbinger: Persona(name: "Harbinger", weapon: .lightning,
                        magic: Magic(core: C(0xFFE0E0), glow: C(0xC8102A), jagged: false, touch: true), pivot: (45, 32),
                        headTop: 14, signature: 3.0, draw: drawHarbinger),
    .astrid: Persona(name: "Astrid", weapon: .blaster, motion: .fly, shot: .energy(core: C(0xFFE4EA), glow: C(0xFF3050)),
                     muzzle: (45, 33), handGun: false, headTop: 17, signature: 3.2, draw: drawAstrid),
]

// MARK: - Helpers

/// 0 outside `a…b`, 1 inside it, easing in and out over `edge` at each end.
private func v6Arc(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    let k = min(1, (s - a) / edge, (b - s) / edge)
    return k * k * (3 - 2 * k)
}

/// The fractional part, always 0…1.
private func v6Frac(_ v: Double) -> Double { v - floor(v) }

/// String art turned to `angle` degrees (0 forward, -90 straight up, as `Pose.melee`): `rows` is drawn upright, its
/// top pointing along `angle`, the point `pivot` (in pattern pixels, from its top-left) on the canvas at `at`.
private func v6Stamp(_ c: PixelCanvas, _ rows: [String], _ palette: [Character: Px], pivot: (x: Double, y: Double),
                     at: (x: Double, y: Double), angle: Double, alpha: Double = 1) {
    let grid = rows.map { Array($0) }
    let w = Double(grid.map(\.count).max() ?? 0), h = Double(grid.count)
    let reach = max(hypot(pivot.x, pivot.y), hypot(w - pivot.x, pivot.y), hypot(pivot.x, h - pivot.y),
                    hypot(w - pivot.x, h - pivot.y)) + 1
    let r = (angle + 90) * .pi / 180
    let cs = cos(r), sn = sin(r)
    let x0 = Int(floor(at.x - reach)), x1 = Int(ceil(at.x + reach))
    let y0 = Int(floor(at.y - reach)), y1 = Int(ceil(at.y + reach))
    for y in y0...y1 {
        for x in x0...x1 {
            let dx = Double(x) + 0.5 - at.x, dy = Double(y) + 0.5 - at.y
            let u = dx * cs + dy * sn, v = -dx * sn + dy * cs
            let col = Int(floor(u + pivot.x)), row = Int(floor(v + pivot.y))
            guard row >= 0, row < grid.count, col >= 0, col < grid[row].count else { continue }
            if let p = palette[grid[row][col]] { c.px(x, y, alpha < 1 ? p.alpha(alpha) : p) }
        }
    }
}

/// A rope through `pts`, `r0` thick at its root thinning to `r1` at its tip (a horn, a plume, a limb).
private func v6Rope(_ c: PixelCanvas, _ pts: [(Double, Double)], r0: Double, r1: Double, _ col: Px) {
    guard pts.count > 1 else { return }
    for i in 0..<(pts.count - 1) {
        let k = Double(i) / Double(pts.count - 1)
        let r = r0 + (r1 - r0) * k
        c.glowLine(pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
    }
}

/// A 1-pixel curve from `a` through towards `ctrl` to `b` (an antenna, a strap).
private func v6Curve(_ c: PixelCanvas, _ a: (Double, Double), _ ctrl: (Double, Double), _ b: (Double, Double),
                     _ col: Px) {
    for i in 0...24 {
        let t = Double(i) / 24, u = 1 - t
        let x = u * u * a.0 + 2 * u * t * ctrl.0 + t * t * b.0
        let y = u * u * a.1 + 2 * u * t * ctrl.1 + t * t * b.1
        c.px(Int(x.rounded(.down)), Int(y.rounded(.down)), col)
    }
}

/// A filled polygon (a wing): every pixel whose centre is inside `poly`.
private func v6Fill(_ c: PixelCanvas, _ poly: [(Double, Double)], _ col: Px) {
    guard let minX = poly.map(\.0).min(), let maxX = poly.map(\.0).max(),
          let minY = poly.map(\.1).min(), let maxY = poly.map(\.1).max() else { return }
    for y in Int(floor(minY))...Int(ceil(maxY)) {
        for x in Int(floor(minX))...Int(ceil(maxX)) {
            let px = Double(x) + 0.5, py = Double(y) + 0.5
            var hit = false
            for i in 0..<poly.count {
                let a = poly[i], b = poly[(i + 1) % poly.count]
                if (a.1 > py) != (b.1 > py), px < a.0 + (py - a.1) / (b.1 - a.1) * (b.0 - a.0) { hit.toggle() }
            }
            if hit { c.px(x, y, col) }
        }
    }
}

/// `poly` turned `deg` degrees round `root` (a wing lifting on its hinge).
private func v6Turn(_ poly: [(Double, Double)], about root: (Double, Double), _ deg: Double) -> [(Double, Double)] {
    let r = deg * .pi / 180, cs = cos(r), sn = sin(r)
    return poly.map { pt in
        let dx = pt.0 - root.0, dy = pt.1 - root.1
        return (root.0 + dx * cs - dy * sn, root.1 + dx * sn + dy * cs)
    }
}

/// Which row a leg's foot is on: lifted a row while it steps.
private func v6Foot(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

// MARK: - Burcu

/// Burcu: a badger-headed swashbuckler, Clawd with grey fur and a badger's face: white, a black stripe running up
/// through each amber eye, a short white snout pushed forward with a black nose. A black cavalier hat with a gold band,
/// its brim pinned up at the back, a great white plume sweeping back off it. A crimson coat with gold buttons, a white
/// lace jabot and cuffs, a black sash with a gold buckle, grey breeches and tall black boots with turned-down tops. He
/// fights with a curved sabre, a gold basket guard round the grip. Signature: a fencer's salute, the blade brought up
/// before his face, then swept down and out to the side, held, and back on guard.
private func drawBurcu(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x8E8C94), furD = C(0x68666E), furL = C(0xB4B2BA)
    let black = C(0x1C1A1E), wht = C(0xF4F2EC), whtD = C(0xC8C4BC)
    let coat = C(0x9A2232), coatD = C(0x6E1622), coatL = C(0xC44454)
    let gold = C(0xE8C040), goldD = C(0xB08A22)
    let felt = C(0x26242C), feltL = C(0x46444E)
    let s = p.signature ?? -1

    // The salute: up before the face by 0.42, swept down and out by 0.52, held to 0.84, back on guard by 0.94.
    let rest = (angle: -58.0, x: Sprite.hand.x, y: Sprite.hand.y)
    let up = (angle: -90.0, x: 38.5, y: 29.5)
    let down = (angle: 38.0, x: 44.0, y: 35.5)
    var pose = (angle: p.melee ?? rest.angle, x: rest.x, y: rest.y)
    var trail: [Double] = p.trail
    func mix(_ a: (angle: Double, x: Double, y: Double), _ b: (angle: Double, x: Double, y: Double), _ k: Double)
        -> (angle: Double, x: Double, y: Double) {
        let e = k * k * (3 - 2 * k)
        return (a.angle + (b.angle - a.angle) * e, a.x + (b.x - a.x) * e, a.y + (b.y - a.y) * e)
    }
    if s > 0.06 && s < 0.94 {
        if s < 0.3 { pose = mix(rest, up, (s - 0.06) / 0.24) }
        else if s < 0.44 { pose = up }
        else if s < 0.52 {
            let k = (s - 0.44) / 0.08
            pose = mix(up, down, k)
            trail = [up.angle + (down.angle - up.angle) * max(0, k - 0.3), up.angle + (down.angle - up.angle) * max(0, k - 0.6)]
        }
        else if s < 0.84 { pose = down }
        else { pose = mix(down, rest, (s - 0.84) / 0.1) }
    }

    // 1. Grey breeches, tall black boots with their tops turned down.
    drawLegs(c, Look(leg: C(0x4A4652)), step: p.step)
    drawBoots(c, black, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = v6Foot(i, p.step)
            c.rect(lx, b - 3, 2, 1, C(0x5A4030)); c.px(lx, b - 2, C(0x3A3640))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in grey fur, lit along the top in short strokes; the sleeves crimson.
    drawBody(c, Look(body: fur, shade: furD, arm: coat, eye: nil))
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 7, furL)
    c.px(15, 33, coatL); c.rect(15, 35, 3, 1, coatD)

    // 4. The badger's face: white, a black stripe up through each eye, grey at the cheeks; amber eyes in the stripes.
    c.rect(20, 26, 16, 7, wht)
    c.rect(20, 32, 16, 1, whtD)
    c.rect(21, 26, 4, 7, black); c.rect(31, 26, 4, 7, black)
    c.rect(18, 28, 2, 5, fur); c.rect(36, 28, 1, 5, furD)
    for x in [22, 32] { c.rect(x, 29, 2, 2, C(0xE0A040)); c.px(x + 1, 29, ink); c.px(x, 29, C(0xFFE0A0)) }
    // The snout: short and white, pushed forward, the black nose at its tip, the mouth under it.
    c.pattern(36, 28, [
        "WWWW..",
        "WWWWWN",
        "WWWWWN",
        "wwww..",
    ], ["W": wht, "w": whtD, "N": black])
    c.rect(37, 32, 3, 1, furD)

    // 5. The coat: crimson, lit on the left, the far side and hem in shade, a gold-edged hem; two rows of gold buttons,
    //    the white lace jabot at the throat, the black sash with its gold buckle, and the coat's skirts over his thighs.
    c.rect(18, 33, 20, 5, coat)
    c.rect(18, 33, 1, 5, coatL); c.rect(36, 33, 2, 5, coatD)
    c.rect(17, 38, 22, 1, coat); c.px(17, 38, coatL); c.rect(37, 38, 2, 1, coatD); c.rect(17, 39, 22, 1, goldD)
    c.rect(22, 38, 1, 2, coatD); c.rect(33, 38, 1, 2, coatD)
    for y in [34, 37] { c.px(23, y, gold); c.px(32, y, gold) }
    c.pattern(26, 33, ["WwWw", ".WW.", ".wW."], ["W": wht, "w": whtD])
    c.rect(18, 36, 18, 1, black); c.rect(36, 36, 2, 1, C(0x0E0D10)); c.rect(27, 36, 2, 1, gold)
    c.rect(38, 33, 1, 3, wht)   // the near lace cuff

    // 6. The hat: black felt, a lit run on the crown, a gold band, the brim wide, pinned up at the back; the white plume
    //    sweeping back off it, its barbs picked out.
    c.pattern(14, 19, [
        ".......FFFFFFFF.........",
        "......FFlFFFFFFFF.......",
        ".....FlFFFFFFFFFFF......",
        "FF...FFFFFFFFFFFFFF.....",
        "FFF..GGGGGGGGGGGGGG.....",
        ".FFFFFFFFFFFFFFFFFFFFFFF",
        "..ffffffffffffffffffffff",
    ], ["F": felt, "l": feltL, "f": C(0x141218), "G": gold])
    c.rect(19, 23, 1, 1, goldD); c.px(32, 23, goldD)
    let plume: [(Double, Double)] = [(31, 20), (27, 16.5), (22, 15.5), (17, 16.5), (13, 19), (11.5, 22)]
    v6Rope(c, plume, r0: 1.6, r1: 0.7, wht)
    for (x, y) in [(26, 16), (21, 15), (16, 17), (13, 20)] { c.px(x, y + 1, whtD) }
    c.px(23, 14, wht); c.px(18, 15, wht); c.px(12, 18, wht)

    // 7. The sabre: a curved steel blade, its edge bright, a gold basket guard round a dark grip; on guard, swung, or
    //    brought up for the salute.
    let sabre = [
        "...LL",
        "..LSS",
        ".LSSS",
        ".LSS.",
        "LSSS.",
        "LSS..",
        "LSS..",
        "LSS..",
        "LSS..",
        "LSD..",
        "gGGGg",
        ".GhG.",
        "..h..",
        "..p..",
    ]
    let pal: [Character: Px] = ["S": C(0xC4CAD4), "L": C(0xF0F4FA), "D": C(0x8890A0), "G": gold, "g": goldD,
                                "h": C(0x3A2418), "p": gold]
    for (i, a) in trail.enumerated() {
        v6Stamp(c, sabre, pal, pivot: (2.5, 12.5), at: (pose.x, pose.y), angle: a, alpha: 0.3 / Double(i + 1))
    }
    crawlBar(c, (38.5, 34), atan2(pose.y - 34, pose.x - 38.5) * 180 / .pi, from: 0,
             to: hypot(pose.x - 38.5, pose.y - 34), coat, r: 1.2)
    v6Stamp(c, sabre, pal, pivot: (2.5, 12.5), at: (pose.x, pose.y), angle: pose.angle)
    c.rect(Int(pose.x.rounded()) - 1, Int(pose.y.rounded()) - 1, 2, 2, fur)
}

// MARK: - Agatha

/// Agatha: a wrinkled old woman, Clawd with crow's feet and bags under small eyes, wisps of grey hair escaping a
/// red-checked trapper hat with cream fur at the brim and its flaps hanging down, three scarves wound round her neck
/// (purple, mustard, teal), a drab brown coat and old shoes. Behind her, her shopping cart, full of bags and junk, a
/// pink plastic flamingo standing up out of it. She sprays silver paint from a can. Signature: she sprays a big silver
/// smiley face in the air, then cackles, HA HA.
private func drawAgatha(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x6E5E44), coatD = C(0x4E4230), coatL = C(0x8E7C5A)
    let red = C(0xC8302A), redD = C(0x8E1E1A), check = C(0x2A1A1C), fur = C(0xE6D8BA), furD = C(0xB4A486)
    let grey = C(0xD0CEC8), greyD = C(0x9A9894)
    let purple = C(0x7A3A8A), purpleL = C(0x9A5AAA), mustard = C(0xD8A830), teal = C(0x2E8A80)
    let wire = C(0xB4BAC4), wireD = C(0x7A808A), wireL = C(0xE4E8EE)
    let pink = C(0xF07AA8), pinkD = C(0xC04E80), pinkL = C(0xFFA8C8)
    let tin = C(0xC0C6D0), tinL = C(0xF0F4F8), tinD = C(0x7E8490)
    let paint = C(0xDDE2EA)
    let s = p.signature ?? -1
    let spraying = s > 0.08 && s < 0.6
    let cackle = s >= 0.6 && s < 0.92
    let shake = cackle && Int(p.lt * 12) % 2 == 0 ? -1 : 0

    // 1. Thick brown stockings, old brown shoes.
    drawLegs(c, Look(leg: C(0x5A4A3E)), step: p.step)
    drawBoots(c, C(0x2E2420), step: p.step, rows: 1)

    // 2. The cart behind her: a wire basket on a frame, two small wheels; full of bags, a tin and the flamingo, the
    //    red handle by her far hand.
    c.rect(3, 42, 2, 2, ink); c.rect(12, 42, 2, 2, ink); c.px(3, 42, C(0x5A5A64)); c.px(12, 42, C(0x5A5A64))
    c.rect(4, 37, 1, 5, wireD); c.rect(13, 37, 1, 5, wireD); c.rect(3, 40, 12, 1, wireD)
    // The flamingo, standing up out of the cart: a pink body, its long neck curving up, its head, the beak hooked
    // down with a black tip.
    c.ellipse(9, 26, 3, 2, pink); c.rect(7, 25, 3, 1, pinkL); c.rect(10, 27, 2, 1, pinkD)
    v6Rope(c, [(11, 25), (12.5, 22), (12, 19.5), (10.5, 17.5)], r0: 0.9, r1: 0.8, pink)
    c.rect(9, 16, 3, 2, pink); c.px(9, 16, pinkL); c.px(10, 16, ink)
    c.rect(12, 16, 1, 2, C(0xF4E8D8)); c.px(12, 18, ink)
    // A paper bag and a tin.
    c.rect(3, 23, 4, 4, C(0xC8A878)); c.rect(3, 23, 4, 1, C(0xA88A5C)); c.px(3, 24, C(0xE0C898))
    c.rect(12, 25, 2, 2, C(0xC83A30)); c.px(12, 25, C(0xE8E0D8))
    for y in 27...37 {
        let x0 = 2 + (y - 27) / 5
        c.rect(x0, y, 16 - x0, 1, C(0x3E424A))
        for x in x0..<16 where (x - x0) % 3 == 0 { c.px(x, y, wire) }
        if (y - 27) % 3 == 0 { c.rect(x0, y, 16 - x0, 1, wire) }
        c.px(x0, y, wireL); c.px(15, y, wireD)
    }
    c.rect(2, 27, 14, 1, wireL)
    c.rect(15, 31, 3, 2, C(0xC82A2A)); c.px(15, 31, C(0xE85A50))   // the handle's red grip

    // 3. The breath.
    c.oy += p.breathe
    c.oy += shake

    // 4. The body; the near arm up as she sprays, the sleeves in the coat.
    let raise = spraying ? 4 : p.armRaise
    drawBody(c, Look(arm: coat, eye: nil), armRight: raise)
    c.px(15, 33, coatL); c.rect(15, 35, 3, 1, coatD)

    // 5. The coat: drab brown, lit on the left, the far side in shade, two big buttons, its hem over her knees.
    c.rect(18, 33, 20, 5, coat)
    c.rect(18, 33, 1, 5, coatL); c.rect(36, 33, 2, 5, coatD)
    c.rect(17, 38, 22, 2, coat); c.px(17, 38, coatL); c.rect(17, 39, 22, 1, coatD); c.rect(37, 38, 2, 1, coatD)
    c.rect(27, 33, 1, 7, coatD)
    c.px(29, 35, C(0x2E2420)); c.px(29, 38, C(0x2E2420))

    // 6. The scarves: purple wound round twice, mustard over it, a teal end and a mustard end hanging down her front.
    c.rect(18, 33, 20, 2, purple); c.rect(18, 33, 20, 1, purpleL)
    for x in stride(from: 20, to: 37, by: 3) { c.px(x, 34, C(0x5A2A6A)) }
    c.rect(19, 35, 13, 1, mustard); c.px(19, 35, C(0xF0C850))
    c.rect(21, 35, 2, 4, teal); c.px(21, 35, C(0x4AAAA0)); c.rect(21, 39, 2, 1, C(0x1E6A62))
    c.rect(24, 36, 2, 3, mustard); c.rect(24, 38, 2, 1, C(0xA8801E))

    // 7. The face: wrinkled, small eyes with bags under them and crow's feet; a thin mouth, or the cackle, wide open
    //    with one tooth, eyes squeezed shut.
    if cackle {
        c.pattern(21, 29, ["X..X", ".XX."], ["X": ink]); c.pattern(31, 29, ["X..X", ".XX."], ["X": ink])
        c.pattern(25, 31, ["MMMMM", "MtMMM"], ["M": C(0x4A1A1E), "t": C(0xF0E8D0)])
    } else {
        c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
        c.rect(26, 32, 4, 1, clawdShade)
    }
    c.rect(21, 31, 3, 1, clawdShade); c.rect(32, 31, 3, 1, clawdShade)   // bags under the eyes
    c.px(20, 28, clawdShade); c.px(20, 30, clawdShade); c.px(35, 28, clawdShade); c.px(35, 30, clawdShade)
    c.rect(21, 27, 3, 1, greyD); c.rect(32, 27, 3, 1, greyD)
    c.px(28, 30, clawdShade); c.px(28, 31, clawdShade)   // the nose

    // 8. The grey hair escaping at the sides in wisps.
    c.pattern(15, 26, ["..GG", ".G.G", "G.GG", ".GGg", "..Gg"], ["G": grey, "g": greyD])
    c.pattern(37, 26, ["gG..", "G.G.", "gG.G", "Gg..", "g..."], ["G": grey, "g": greyD])

    // 9. The trapper hat: buffalo-checked red and black, its flaps hanging down either side, cream fur along the brim
    //    and the flaps' edges; the flaps bounce while she cackles.
    let crown: [(y: Int, x0: Int, x1: Int)] = [(19, 22, 33), (20, 20, 35), (21, 19, 36), (22, 18, 37), (23, 18, 37),
                                                (24, 18, 37)]
    func checked(_ x: Int, _ y: Int) -> Px {
        let a = (x / 2) % 2 == 0, b = (y / 2) % 2 == 0
        return a && b ? check : (a || b ? redD : red)
    }
    for r in crown { for x in r.x0...r.x1 { c.px(x, r.y, checked(x, r.y)) } }
    c.rect(21, 19, 3, 1, C(0xE05048))
    let flap = cackle && Int(p.lt * 12) % 2 == 0 ? -1 : 0
    for (x0, x1) in [(15, 18), (37, 40)] {
        for y in (25 + flap)...(30 + flap) { for x in x0...x1 { c.px(x, y, checked(x, y)) } }
        c.rect(x0, 31 + flap, x1 - x0 + 1, 1, fur)
    }
    c.rect(17, 25, 22, 1, fur); c.rect(16, 26, 24, 1, fur)
    for x in stride(from: 18, to: 39, by: 3) { c.px(x, 26, furD) }

    // 10. The spray can: silver, its red cap and nozzle at the top, upright in her near hand.
    let hy = 34 - raise
    c.pattern(41, hy - 6, [
        ".rr",
        "rrn",
        "LCC",
        "LCD",
        "LCD",
        "LCD",
    ], ["r": C(0xD0302A), "n": ink, "L": tinL, "C": tin, "D": tinD])
    c.rect(40, hy, 2, 2, clawdOrange); c.px(41, hy + 1, clawdShade)

    // 11. The smiley: sprayed in silver paint, round it goes, then the eyes, then the grin; the mist from the nozzle.
    if spraying {
        let k = min(1, max(0, (s - 0.14) / 0.3))
        let cx = 56.0, cy = 21.0
        var tip = (cx, cy - 6)
        let n = Int(k * 40)
        if n > 0 {
            for i in 0...n {
                let a = -Double.pi / 2 + Double(i) / 40 * 2 * .pi
                let pt = (cx + cos(a) * 6.5, cy + sin(a) * 6.5)
                c.px(Int(pt.0.rounded()), Int(pt.1.rounded()), paint)
                tip = pt
            }
        }
        if k >= 1 && s > 0.46 { c.rect(53, 18, 1, 2, paint); c.rect(58, 18, 1, 2, paint) }
        if k >= 1 && s > 0.52 {
            for i in 0...8 {
                let a = Double.pi * (0.15 + 0.7 * Double(i) / 8)
                c.px(Int((cx + cos(a) * 3.6).rounded()), Int((cy + 0.5 + sin(a) * 3.2).rounded()), paint)
            }
        }
        if s < 0.56 {
            for i in 0..<5 {
                let f = v6Frac(p.lt * 3 + Double(i) / 5)
                let x = 44 + (tip.0 - 44) * f, y = Double(hy - 3) + (tip.1 - Double(hy - 3)) * f
                c.px(Int(x.rounded()), Int((y + noise(i + Int(p.lt * 9)) * 2 - 1).rounded()), paint.alpha(0.24))
            }
        }
    } else if cackle {
        // The smiley still hangs there while she laughs.
        for i in 0..<40 {
            let a = -Double.pi / 2 + Double(i) / 40 * 2 * .pi
            c.px(Int((56 + cos(a) * 6.5).rounded()), Int((21 + sin(a) * 6.5).rounded()), paint)
        }
        c.rect(53, 18, 1, 2, paint); c.rect(58, 18, 1, 2, paint)
        for i in 0...8 {
            let a = Double.pi * (0.15 + 0.7 * Double(i) / 8)
            c.px(Int((56 + cos(a) * 3.6).rounded()), Int((21.5 + sin(a) * 3.2).rounded()), paint)
        }
        if Int(p.lt * 4) % 2 == 0 {
            crawlText(c, 38, 12, "HA", C(0xF4F0E8))
        } else {
            crawlText(c, 44, 7, "HA", C(0xF4F0E8))
        }
    }
}

// MARK: - Tsarina Signet

/// Tsarina Signet: Clawd in luminous pale sea-green scales, covered in black and red tattoos that never sit still,
/// curling slowly over her skin. Long plum-red hair falling straight past her shoulders, a gold circlet with a red
/// signet stone at her brow, dark eyes, dark red lips, a black bodice laced in red and a skirt of red and black
/// ribbons. Her hands glow yellow; her magic is blood and ink, red and black. Signature: the tattoos swirl into a
/// spiral round her and spin, her hands blazing brighter.
private func drawTsarina(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xCFEDE6), skinD = C(0x9CC6BE), skinL = C(0xF2FFFB), scale = C(0xB6DCD4)
    let tatInk = C(0x1E1420), tatRed = C(0xC41E2C)
    let hair = C(0x5E1424), hairD = C(0x3E0C18), hairL = C(0x8E2A40)
    let gold = C(0xE8C040), goldD = C(0xA88420), gem = C(0xD0202E)
    let bodice = C(0x1E1620), bodiceL = C(0x3A2A36)
    let glowY = C(0xFFE458), glowW = C(0xFFFBD0)
    let s = p.signature ?? -1
    let swirl = v6Arc(s, 0.06, 0.94, edge: 0.15)
    let t = p.lt

    // The tattoos at a pixel of skin: wavy black lines one way and thinner red ones the other, drifting; or, in the
    // signature, a spinning spiral round her middle.
    func tattoo(_ x: Int, _ y: Int) -> Px? {
        let fx = Double(x), fy = Double(y)
        if swirl > 0.5 {
            let dx = fx - 28, dy = fy - 32
            let v = atan2(dy, dx) * 2 + hypot(dx, dy) * 0.5 - t * 7
            if abs(sin(v)) < 0.3 { return Int(hypot(dx, dy) / 3) % 2 == 0 ? tatInk : tatRed }
            return nil
        }
        let a = fx * 0.55 + fy * 0.35 + sin(fy * 0.5 + t) * 1.4 - t * 0.8
        if abs(sin(a)) < 0.24 { return tatInk }
        let b = fx * 0.3 - fy * 0.6 + cos(fx * 0.4 + t * 0.7) * 1.2 + t * 0.6
        if abs(sin(b * 0.8)) < 0.16 { return tatRed }
        return nil
    }

    // 1. The legs in scaled skin, tattooed, dark red slippers.
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = v6Foot(i, p.step)
            c.rect(lx + 1, 36, 1, b - 36, skinD)
            for y in 38...(b - 1) { for x in lx...(lx + 1) { if let col = tattoo(x, y) { c.px(x, y, col) } } }
            c.rect(lx, b, 2, 1, C(0x6A1420))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The hair at the back, falling long behind her shoulders.
    c.pattern(14, 26, [
        "HHHH",
        "HhHH",
        "HHhH",
        "HhHH",
        "HHhH",
        "HhHH",
        "HHhH",
        "HhH.",
        "HH..",
        "H...",
        "H...",
        "H...",
    ], ["H": hair, "h": hairD])

    // 4. The body in luminous scales, a brick pattern of little scale strokes, lit on the left; the tattoos over it,
    //    clear of her eyes and mouth.
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil), armRight: p.armRaise)
    c.rect(18, 26, 20, 1, skinL); c.rect(18, 26, 1, 8, skinL)
    for y in stride(from: 27, to: 34, by: 2) {
        for x in stride(from: 19 + (y / 2) % 2 * 2, to: 36, by: 4) { c.rect(x, y, 2, 1, scale) }
    }
    for y in 26...33 {
        for x in 18...37 {
            let nearEye = (x >= 21 && x <= 24 || x >= 31 && x <= 34) && y >= 28 && y <= 31
            if nearEye || (x >= 25 && x <= 30 && y >= 31) { continue }
            if let col = tattoo(x, y) { c.px(x, y, col) }
        }
    }
    for y in 33...35 { for x in 15...16 { if let col = tattoo(x, y) { c.px(x, y, col) } } }

    // 5. The bodice: black, laced up the front in red, red trim along its top; the ribbon skirt over her thighs.
    c.rect(18, 34, 20, 4, bodice)
    c.rect(18, 34, 20, 1, C(0xA8182A)); c.rect(18, 35, 1, 3, bodiceL)
    c.pattern(26, 35, ["r..r", ".rr.", "r..r"], ["r": C(0xC8202E)])
    for (i, x) in stride(from: 17, through: 37, by: 2).enumerated() {
        c.rect(x, 38, 2, 1, i % 2 == 0 ? C(0xA8182A) : bodice)
        c.px(x, 39, i % 2 == 0 ? C(0x7A101E) : bodiceL)
    }

    // 6. The face: dark almond eyes with a gold glint, fine dark brows, dark red lips.
    for x in [22, 32] { c.rect(x, 29, 2, 3, ink); c.px(x, 29, C(0xE8C860)) }
    c.px(21, 29, ink); c.px(34, 29, ink)
    c.rect(21, 27, 3, 1, hairD); c.rect(32, 27, 3, 1, hairD)
    c.rect(26, 32, 4, 1, C(0x8A1428)); c.px(27, 32, C(0xB8283C))

    // 7. The hair over her crown and down either side of her face in long straight strands; the circlet with its
    //    signet stone.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH....",
        "....HHHlHHHHHlHHHHHH..",
        "...HHlHHHHHHHHHHlHHHH.",
        "..HHHHHhHHHHHhHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHH",
        "..HHHH............HHHH",
        "..HHH..............HHH",
        "..HhH..............HhH",
        "..HHH..............HHH",
        "..HhH..............HhH",
        "..HHH..............HH.",
        "..HhH..............Hh.",
        "..HHH..............H..",
        "..HhH.................",
        "..HH..................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(18, 24, 20, 1, gold); c.rect(18, 24, 4, 1, C(0xFFE07A)); c.rect(34, 24, 4, 1, goldD)
    c.pattern(26, 23, [".GG.", "GrrG", ".GG."], ["G": gold, "r": gem])

    // 8. The hands, glowing yellow, a faint warm halo round each; brighter as the tattoos swirl.
    let halo = 0.12 + swirl * 0.1
    let ny = 33 - p.armRaise
    c.circle(16, 34, 3, glowY.alpha(halo * 0.8)); c.circle(40, ny + 1, 3, glowY.alpha(halo))
    c.rect(15, 33, 2, 3, glowY); c.px(15, 33, glowW)
    c.rect(39, ny, 2, 3, glowY); c.px(40, ny, glowW)
    if swirl > 0.3 { c.px(41, ny + 1, glowW); c.px(14, 34, glowW) }
}

// MARK: - Vrah

/// Vrah: a mantis hunter, Clawd in bright jade chitin: two great red compound eyes bulging at the top corners, long
/// antennae, a pair of mandibles jutting forward at the front of her face, a pale belly plate in segments, and her long
/// abdomen out behind under folded wings. No trophies. She hunts with a crossbow in her spiked raptor arm: a dark
/// stock, pale bowed limbs, a red-fletched bolt. She flies, her wings blurring. Signature: her mandibles click, open
/// and shut, her antennae twitching.
private func drawVrah(_ c: PixelCanvas, _ p: Pose) {
    let chit = C(0x6CAE3C), chitD = C(0x4A7E28), chitL = C(0x9CD460), belly = C(0xC8DC96)
    let eye = C(0xD8482A), eyeD = C(0x8E2A1A), eyeL = C(0xFFA070)
    let wing = C(0xC4D49A), wingD = C(0x92A468), wingL = C(0xE4EEC4)
    let jaw = C(0xC09A48), jawD = C(0x6A4A1C)
    let stock = C(0x3A3024), stockL = C(0x5E5038), limb = C(0xD8CCAA), limbD = C(0xA89A78), string = C(0xE8E8E0)
    let s = p.signature ?? -1
    let clicking = s > 0.1 && s < 0.9
    let open = clicking && Int(s * 16) % 2 == 0
    var cocked = true
    if let f = p.fire { cocked = v6Frac(f.t / p.firePeriod) > 0.25 }
    let twitch = clicking ? (Int(s * 10) % 2 == 0 ? 1.0 : -1.0) : sin(p.lt * 1.3) * 0.6

    // 1. The legs in jade chitin, a lit knee on each, dark claws at the foot.
    drawLegs(c, Look(leg: chit), step: p.step)
    drawBoots(c, chitD, step: p.step, rows: 1)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, v6Foot(i, p.step) - 4, chitL) } }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The abdomen, long behind her, in segments, its underside pale.
    c.ellipse(12, 33, 7, 4, chit)
    c.rect(6, 35, 13, 2, belly); c.ellipse(12, 36, 5, 1, belly)
    for x in [9, 12, 15] { c.rect(x, 30, 1, 5, chitD) }
    c.rect(7, 30, 6, 1, chitL)

    // 4. The wings: folded flat along her back over the abdomen; lifted and blurring while she flies, the hind pair
    //    a faint flicker behind.
    let folded: [(Double, Double)] = [(22, 26), (14, 26.5), (6, 29), (3, 32), (7, 33.5), (20, 30)]
    let root = (21.0, 27.0)
    if p.flying {
        let up = Int(p.t * 24) % 2 == 0
        let lift = up ? 62.0 : 30.0
        v6Fill(c, v6Turn(folded, about: root, lift + 18), wingL.alpha(0.2))
        let w = v6Turn(folded, about: root, lift)
        v6Fill(c, w, wing)
        let tip = w[3], mid = w[2]
        c.glowLine(root.0, root.1, tip.0, tip.1, core: wingD, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.glowLine(root.0, root.1, mid.0, mid.1, core: wingD, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
    } else {
        v6Fill(c, folded, wing)
        c.glowLine(21, 27.5, 4.5, 32, core: wingD, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
        c.rect(12, 27, 8, 1, wingL)
        for x in [9, 14, 18] { c.px(x, 30, wingD); c.px(x, 31, wingD) }
    }

    // 5. The body in chitin, lit along the top, the pale belly plate in segments.
    drawBody(c, Look(body: chit, shade: chitD, arm: chit, eye: nil))
    c.rect(18, 26, 20, 1, chitL); c.rect(18, 26, 1, 7, chitL)
    c.rect(20, 33, 16, 5, belly)
    for y in [34, 36] { c.rect(20, y, 16, 1, C(0xA8BC78)) }
    c.rect(20, 33, 16, 1, chitD)
    c.px(15, 33, chitL)

    // 6. The eyes: two great compound eyes bulging at the top corners, red, a lit facet up on the left of each, a
    //    darker false pupil looking forward.
    for cx in [19, 36] {
        c.ellipse(cx, 25, 3, 3, eye)
        c.rect(cx - 2, 27, 5, 1, eyeD)
        c.px(cx - 2, 23, eyeL); c.px(cx - 1, 23, eyeL); c.px(cx - 2, 24, eyeL)
        c.rect(cx + 1, 25, 1, 2, eyeD)
    }

    // 7. The antennae: long and fine, up off her brow, twitching.
    v6Curve(c, (25, 25), (22, 16), (17 + twitch, 12), chitD)
    v6Curve(c, (31, 25), (34, 15), (40 - twitch, 12), chitD)

    // 8. The face: a lit run down the middle of her brow, and the mandibles jutting forward, shut or clicking open.
    c.rect(27, 27, 2, 4, chitL); c.px(27, 31, chitD); c.px(28, 31, chitD)
    if open {
        c.pattern(37, 27, [
            "....jJ",
            "jjjjJ.",
            "PP....",
            "PP....",
            "jjjjJ.",
            "....jJ",
        ], ["j": jaw, "J": jawD, "P": chitD])
        c.px(45, 26, C(0xFFFFFF, 0.8)); c.px(46, 30, C(0xFFFFFF, 0.8)); c.px(45, 33, C(0xFFFFFF, 0.8))
    } else {
        c.pattern(37, 28, [
            "jjjj..",
            "jjjjjJ",
            "jjjjjJ",
            "jjjj..",
        ], ["j": jaw, "J": jawD])
        c.rect(38, 29, 3, 1, C(0xB0904A))
    }

    // 9. The crossbow: the dark stock under her raptor arm, pale bowed limbs at the front, the string drawn back to
    //    the nut and a bolt on it, red-fletched, or the string slack just after a shot.
    c.rect(35, 34, 13, 2, stock); c.rect(35, 34, 13, 1, stockL)
    c.rect(38, 36, 1, 2, stock)
    v6Rope(c, [(46.5, 34.5), (46, 31), (44.5, 28.5)], r0: 0.8, r1: 0.6, limb)
    v6Rope(c, [(46.5, 34.5), (46, 38), (44.5, 40.5)], r0: 0.8, r1: 0.6, limbD)
    let back = cocked ? 40.5 : 44.0
    c.glowLine(44.5, 28.5, back, 34, core: string, glow: C(0, 0), coreR: 0.35, glowR: 0.4)
    c.glowLine(44.5, 40.5, back, 34, core: string, glow: C(0, 0), coreR: 0.35, glowR: 0.4)
    if cocked {
        c.rect(41, 33, 7, 1, C(0x8A6A3A)); c.px(48, 33, C(0xC8CCD4)); c.px(49, 33, C(0xE8ECF4))
        c.px(41, 32, C(0xD8302A)); c.px(42, 32, C(0xD8302A))
    }
    // The raptor arm over the stock, spikes along its underside.
    c.rect(38, 33, 4, 2, chit); c.px(38, 33, chitL)
    c.px(39, 35, chitL); c.px(41, 35, chitL)
}

// MARK: - Stalwart

/// Stalwart: a tall orc prince, Clawd half a head taller in dark green skin, a heavy brow over small red-glinting
/// eyes, pointed ears, two ivory tusks jutting up from his underbite, and a gold crown with five points set with red
/// and blue stones. A royal purple tunic trimmed in gold, a black belt with a gold buckle, a purple cape behind, black
/// trousers and boots. Big fists, gold rings on his knuckles. Signature: he punches his open palm, three times, hard.
private func drawStalwart(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x557A3E), skinD = C(0x3A5A2A), skinL = C(0x76A05A)
    let tunic = C(0x5E2A80), tunicD = C(0x3E1A58), tunicL = C(0x8248A6)
    let gold = C(0xF0C840), goldD = C(0xB88A20), goldL = C(0xFFE88A), gem = C(0xD02A3A), gemB = C(0x3A6AE0)
    let tusk = C(0xF0E8D0)
    let s = p.signature ?? -1
    let palm = s > 0.1 && s < 0.9
    var hit = false, wind = false
    if palm && s > 0.2 && s < 0.82 {
        let f = v6Frac((s - 0.2) / 0.62 * 3)
        wind = f < 0.45
        hit = f >= 0.55 && f < 0.85
    }

    // 1. Black trousers, heavy boots with a gold toecap.
    drawLegs(c, Look(leg: C(0x24222A)), step: p.step)
    drawBoots(c, C(0x3A2A20), step: p.step, rows: 2)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, v6Foot(i, p.step), goldD) } }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The cape behind him, purple, in folds.
    c.rect(14, 25, 4, 16, tunicD); c.rect(13, 30, 1, 11, tunicD)
    c.rect(14, 25, 4, 1, tunic); c.px(15, 28, tunic); c.px(15, 33, tunic); c.px(14, 38, tunic)
    c.rect(13, 40, 5, 1, goldD)

    // 4. The body, half a head taller, in dark green skin, lit on the left and top; the pointed ears.
    drawBody(c, Look(body: skin, shade: skinD, arm: tunic, eye: nil))
    c.rect(18, 22, 20, 4, skin); c.rect(37, 22, 1, 4, skinD)
    c.rect(18, 22, 20, 1, skinL); c.rect(18, 22, 1, 10, skinL)
    c.pattern(13, 24, ["L....", ".SSS.", "..SSS"], ["S": skin, "L": skinL])
    c.pattern(38, 24, ["....S", ".SSS.", "SSS.."], ["S": skinD])

    // 5. The face: the heavy brow, small eyes with a red glint, the underbite with the tusks jutting up.
    c.rect(20, 26, 16, 1, skinD); c.rect(21, 25, 4, 1, skinD); c.rect(31, 25, 4, 1, skinD)
    c.rect(22, 27, 2, 2, ink); c.rect(32, 27, 2, 2, ink); c.px(22, 27, C(0xE04030)); c.px(32, 27, C(0xE04030))
    c.rect(24, 30, 9, 1, C(0x2A1E1A)); c.rect(23, 31, 11, 1, skinD)
    c.pattern(24, 28, ["T.......T", "T.......T"], ["T": tusk])
    c.px(24, 28, C(0xFFFFFF))

    // 6. The tunic: royal purple, lit on the left, a gold-trimmed V at the neck, the far side in shade, a black belt
    //    with its gold buckle, the gold hem.
    c.rect(18, 32, 20, 6, tunic)
    c.rect(18, 32, 1, 6, tunicL); c.rect(36, 32, 2, 6, tunicD)
    c.pattern(23, 32, ["GG.......GG", ".GSSSSSSSG.", "..GSSSSSG..", "...GSSSG...", "....GGG...."],
              ["G": gold, "S": skin])
    c.rect(18, 36, 20, 1, C(0x1A1418)); c.rect(27, 36, 3, 1, gold); c.px(28, 36, goldD)
    c.rect(18, 37, 20, 1, goldD)

    // 7. The crown: gold, five points, a lit run on its left, red and blue stones in the band.
    c.pattern(19, 16, [
        "G....G....G....G...G",
        "G...GGG..GGG..GGG..G",
        "GG.GGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGGG",
        "LLLLLLLLLLLLLLLLLLLd",
        "GGrGGGGbGGGGrGGGGbGd",
        "ddddddddddddddddddd.",
    ], ["G": gold, "L": goldL, "d": goldD, "r": gem, "b": gemB])

    // A fist: big, dark green knuckles, two gold rings with a red stone on one.
    func fist(_ x: Int, _ y: Int, _ a: Double) {
        c.rect(x - 2, y - 2, 4, 4, skin.alpha(a)); c.px(x - 2, y - 2, skinL.alpha(a)); c.rect(x - 2, y + 1, 4, 1, skinD.alpha(a))
        c.px(x - 1, y - 1, gold.alpha(a)); c.px(x, y - 1, gold.alpha(a)); c.px(x, y - 2, gem.alpha(a))
    }
    // 8. The far fist at his side, or held up open in front of him for the signature.
    if palm {
        c.rect(38, 31, 2, 3, tunic)
        c.rect(42, 28, 2, 6, skin); c.px(42, 28, skinL); c.rect(43, 28, 1, 6, skinD); c.px(41, 30, skin)
    } else {
        fist(16, 35, 1)
    }

    // 9. The near fist: punching, at rest, or slamming into his palm, a burst where it lands.
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: tunic, fist: fist)
    } else if palm {
        if wind {
            fist(38, 35, 1)
        } else {
            crawlBar(c, (37, 34.5), -20, from: 0, to: 3, tunic, r: 1.2)
            fist(41, 32, 1)
            if hit {
                for (x, y) in [(46, 28), (47, 32), (46, 35), (44, 26)] { c.px(x, y, C(0xFFF2A0)) }
                c.px(45, 30, C(0xFFFFFF)); c.px(45, 33, C(0xFFFFFF))
            }
        }
    } else {
        fist(41, 35, 1)
    }
}

// MARK: - Loita

/// Loita: a fish alien, Clawd in slate-blue scales with a silver belly, a great violet sail of a crest fin along her
/// head, pink at its scalloped edge, a frilled fin at her cheek, a fan of a tail behind, big round gold fish eyes and
/// pouting pink lips. A smart coral blazer over a white shirt, and her steel rebreather (teal filters, as Cascadia's)
/// hanging round her neck on its strap. On her lapel, the Bloom badge: a pink bloom in gold. She doesn't fight.
/// Signature: she breathes on the badge, polishes it with a cloth, and it gleams.
private func drawLoita(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x4E74B4), skinD = C(0x36548C), skinL = C(0x7898D4)
    let fin = C(0x7A5ACA), finD = C(0x5A3EA0), finL = C(0xA88AEA), finTip = C(0xF08AB8)
    let blazer = C(0xE0705A), blazerD = C(0xB04E3E), blazerL = C(0xF49A82), shirt = C(0xF4F2EE)
    let steel = C(0x8A9298), steelD = C(0x5A6268), steelL = C(0xC8D0D4)
    let gold = C(0xF0C840), goldD = C(0xB08A20), bloom = C(0xF06AA8), bloomL = C(0xFFB0D4)
    let s = p.signature ?? -1
    let huff = s > 0.1 && s < 0.3
    let polish = s >= 0.3 && s < 0.78
    let gleam = s >= 0.78 && s < 0.94

    // 1. Blue legs, coral shoes.
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, blazerD, step: p.step, rows: 1)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, v6Foot(i, p.step) - 3, skinL) } }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail behind her: a fan, its rays picked out, pink at the edge.
    c.pattern(9, 27, [
        "T......",
        "TFf....",
        "TFFff..",
        "TFFFfff",
        "TfFFFff",
        "TFFFfff",
        "TFFff..",
        "TFf....",
        "T......",
    ], ["T": finTip, "F": fin, "f": finD])

    // 4. The body: slate-blue, lit on the top and left, scale strokes on the lit side, the silver belly under her chin.
    drawBody(c, Look(body: skin, shade: skinD, arm: blazer, eye: nil))
    c.rect(18, 26, 20, 1, skinL); c.rect(18, 26, 1, 7, skinL)
    for (x, y) in [(20, 27), (24, 27), (30, 27), (34, 27)] { c.rect(x, y, 2, 1, skinL) }
    c.rect(20, 31, 16, 2, C(0xC8D4E4))

    // 5. The crest: a tall violet sail along the top of her head, its rays dark, its scalloped edge pink.
    for x in 19...35 {
        let k = Double(x - 19) / 16
        let h = Int((3 + 7 * sin(k * .pi)).rounded()) + (x % 3 == 0 ? 1 : 0)
        let top = 26 - h
        for y in top..<26 {
            var col = (x - 19) % 3 == 0 ? finD : fin
            if y == top { col = finTip } else if x == 19 || y == top + 1 { col = finL }
            c.px(x, y, col)
        }
    }

    // 6. The cheek fin, frilled, out to the side; the gill slits.
    c.pattern(13, 28, ["T...", "TFf.", "TFFf", "TFf.", "T..."], ["T": finTip, "F": fin, "f": finD])
    for y in [29, 31] { c.px(19, y, skinD); c.px(20, y + 1, skinD) }

    // 7. The eyes: big and round, gold, a black pupil and a glint; looking down at the badge while she polishes it.
    let down = polish || huff ? 1 : 0
    for x in [21, 31] {
        c.pattern(x, 27, [".GG.", "GGGG", "GGGG", ".GG."], ["G": C(0xE8B830)])
        c.rect(x + 1, 28 + down, 2, 2, ink); c.px(x + 1, 28, C(0xFFFFFF))
    }

    // 8. The lips: pink, pouting forward at the front of her face, pursed to huff on the badge.
    c.rect(37, 30, 2, 2, C(0xD86A8A)); c.px(39, huff ? 30 : 31, C(0xB04A6A))

    // 9. The blazer: coral, lit on the left, the far side in shade, the white shirt collar at the neck, a button.
    c.rect(18, 33, 20, 5, blazer)
    c.rect(18, 33, 1, 5, blazerL); c.rect(36, 33, 2, 5, blazerD); c.rect(18, 37, 20, 1, blazerD)
    c.rect(24, 33, 8, 1, shirt)
    c.px(28, 36, C(0x8A3A2E))
    c.px(15, 33, blazerL); c.rect(15, 35, 3, 1, blazerD)

    // 10. The rebreather, hanging round her neck on its strap: the steel mask, a teal filter either side, the port.
    c.px(20, 32, steelD); c.px(21, 33, steelD); c.px(35, 32, steelD); c.px(34, 33, steelD)
    c.rect(23, 34, 8, 2, steel); c.rect(23, 34, 8, 1, steelL)
    c.rect(22, 34, 1, 2, C(0x3A8A9A)); c.rect(31, 34, 1, 2, C(0x2A6A78))
    c.px(26, 35, ink); c.px(27, 35, ink)

    // 11. The Bloom badge on her lapel: a pink bloom in a gold ring, a gleam across it after she's polished it.
    c.pattern(32, 33, [
        ".GGG.",
        "GbBbG",
        "GByBG",
        "GbBbG",
        ".ggg.",
    ], ["G": gold, "g": goldD, "b": bloom, "B": bloomL, "y": gold])

    // 12. The near fin: at her side; or breathing on the badge, a little mist; or rubbing it with a white cloth.
    if huff {
        let k = (s - 0.1) / 0.2
        for i in 0..<3 {
            let y = 33 - Int(k * 3) - i
            c.px(36 - i, y, C(0xFFFFFF, 0.22)); c.px(37 - i, y + 1, C(0xFFFFFF, 0.16))
        }
    }
    if polish {
        let wob = sin(p.lt * 16) * 1.4
        let hx = 34.5 + wob, hy = 35.0
        crawlBar(c, (38.5, 34), atan2(hy - 34, hx - 38.5) * 180 / .pi, from: 0, to: hypot(hx - 38.5, hy - 34), blazer, r: 1.1)
        c.rect(Int(hx.rounded()) - 1, Int(hy.rounded()) - 1, 3, 2, shirt); c.px(Int(hx.rounded()) + 1, Int(hy.rounded()), C(0xC8C6C2))
    } else {
        c.rect(41, 34, 2, 2, skin); c.px(41, 34, skinL)
    }
    if gleam && Int(p.lt * 10) % 3 != 0 {
        c.px(34, 35, C(0xFFFFFF)); c.px(34, 31, C(0xFFFFFF, 0.8)); c.px(34, 32, C(0xFFFFFF))
        c.px(37, 35, C(0xFFFFFF, 0.8)); c.px(38, 35, C(0xFFFFFF, 0.6))
    }
}

// MARK: - Harbinger

/// Harbinger: a tall goat creature, Clawd half a head taller in sooty grey fur, two great ram's horns curling down
/// either side of his head, floppy ears, a long goat's muzzle with a pale beard under it, and across his face a single
/// line of six small red bug eyes. A long silky black coat to the ground, its sheen running down it, a standing
/// collar, black hooves peeping out under the hem. His weapon is dread: a touch of red. Signature: he leans in towards
/// you and stares, his six eyes burning brighter.
private func drawHarbinger(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x1E1C26), coatD = C(0x111017), coatL = C(0x3C3A4C), sheen = C(0x5A5870)
    let fur = C(0x4A4440), furD = C(0x322E2C), furL = C(0x6A625C), beard = C(0x9A948C)
    let horn = C(0xD4C8AA), hornD = C(0x9A8C70), hornL = C(0xF0E8D0)
    let red = C(0xE02A2A), redL = C(0xFF8A80)
    let s = p.signature ?? -1
    let lean = v6Arc(s, 0.08, 0.92, edge: 0.22)
    let stare = lean > 0.6

    // 1. The legs under the coat, black hooves, split at the front.
    drawLegs(c, Look(leg: furD), step: p.step)
    drawBoots(c, C(0x0E0C10), step: p.step, rows: 2)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, v6Foot(i, p.step), C(0x3A3640)) } }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The coat's long skirt, to just above the hooves, flared at the hem, its sheen in a run down the lit side and
    //    folds beside each leg; it shifts a little as he leans.
    let skirt = Int((lean * 1.4).rounded())
    c.ox += skirt
    let hem = seatedPose ? 39 : 41
    c.rect(18, 36, 20, hem - 36 + 1, coat)
    c.rect(17, 39, 22, hem - 39 + 1, coat)
    c.rect(18, 36, 1, 3, sheen); c.px(17, 39, sheen); c.rect(37, 36, 1, hem - 36 + 1, coatD); c.px(38, 39, coatD)
    c.rect(17, hem, 22, 1, coatD)
    if !seatedPose { for x in [22, 26, 30, 34] { c.rect(x, 38, 1, hem - 38, coatD) } }
    c.ox -= skirt

    // The rest of him leans in: across, and down a pixel.
    let lx = Int((lean * 3).rounded())
    c.ox += lx; c.oy += Int(lean.rounded())

    // 4. The body, half a head taller, sooty fur lit along the top in strokes.
    drawBody(c, Look(body: fur, shade: furD, arm: coat, eye: nil), armRight: p.armRaise)
    c.rect(18, 23, 20, 3, fur); c.rect(37, 23, 1, 3, furD)
    c.rect(18, 23, 20, 1, furL); c.rect(18, 23, 1, 8, furL)
    for x in [21, 26, 31] { c.rect(x, 24, 2, 1, furL) }

    // 5. The ears, floppy, out to the sides.
    c.pattern(13, 25, ["FFFFF", ".FFFF", "..ff."], ["F": fur, "f": furD])
    c.pattern(38, 25, ["FFFFF", "FFFF.", ".ff.."], ["F": furD, "f": coatD])

    // 6. The horns: ram's horns, thick at the root, curling up, out and down round each side of his head, ridged.
    let left: [(Double, Double)] = [(21, 23), (19, 18.5), (15.5, 15.5), (12, 16.5), (10.5, 20), (12, 23.5), (14.5, 24)]
    let right: [(Double, Double)] = [(34, 23), (36, 18.5), (39.5, 15.5), (43, 16.5), (44.5, 20), (43, 23.5), (40.5, 24)]
    v6Rope(c, left, r0: 1.8, r1: 0.8, horn)
    v6Rope(c, right, r0: 1.8, r1: 0.8, hornD)
    for pt in left.dropFirst().dropLast() { c.px(Int(pt.0), Int(pt.1), hornD) }
    for pt in right.dropFirst().dropLast() { c.px(Int(pt.0), Int(pt.1), C(0x7A6E58)) }
    c.px(18, 18, hornL); c.px(15, 15, hornL)

    // 7. The line of six red bug eyes across his face, under a dark brow; burning brighter as he stares.
    c.rect(19, 27, 18, 1, furD)
    if stare { c.rect(18, 27, 20, 3, red.alpha(0.18)) }
    for x in [19, 22, 25, 28, 31, 34] {
        c.rect(x, 28, 2, 2, stare ? redL : red)
        c.px(x, 28, stare ? C(0xFFFFFF) : redL)
    }

    // 8. The muzzle: long and goatish, pushing forward, lit on top, a dark nose at the end, the mouth a thin line;
    //    the pale beard hanging under his chin in strands.
    c.pattern(34, 29, [
        "LLLLLLLL.",
        "FFFFFFFFN",
        "FFFFFFFFN",
        "ddddddd..",
    ], ["L": furL, "F": fur, "N": C(0x0E0C10), "d": furD])

    // 9. The coat's top: silky black, a standing collar up round his jaw, the sheen down the lit side, its buttons
    //    hidden; the sleeves.
    c.rect(18, 31, 18, 7, coat)
    c.rect(18, 31, 1, 7, sheen); c.rect(19, 32, 1, 5, coatL); c.rect(30, 32, 1, 5, coatL); c.rect(36, 31, 2, 7, coatD)
    c.pattern(17, 29, ["CC", "CC", ".C"], ["C": coatL])
    c.rect(26, 31, 1, 7, coatD)
    c.px(15, 33, coatL); c.rect(15, 35, 3, 1, coatD)
    c.pattern(36, 33, ["BBBb", "BbBb", ".BBb", ".Bb.", "..b."], ["B": beard, "b": C(0x6E6862)])

    // 10. The near hand: long grey fingers, one pointing out to send his dread.
    let ny = 33 - p.armRaise
    c.rect(41, ny + 1, 2, 2, fur)
    if p.zap != nil || stare { c.rect(43, ny + 1, 2, 1, furL) }
}

// MARK: - Astrid

/// Astrid: a fairy in a tuxedo, Clawd with sleek raven hair pulled back into a tight bun, fine lashes and red lips,
/// a pair of pale lilac fairy wings at her back, always on the flutter. A black tuxedo with satin lapels, a white shirt
/// front and a red bow tie, tails behind, black trousers with a satin stripe and shiny shoes. She flies, and boils the
/// blood with red sparkles from her fingertip. Signature: she loops the loop, leaving a trail of red sparkles behind
/// her.
private func drawAstrid(_ c: PixelCanvas, _ p: Pose) {
    let tux = C(0x1E1E28), tuxD = C(0x101016), tuxL = C(0x3C3C4E), satin = C(0x50506A)
    let shirt = C(0xF4F2EE), shirtD = C(0xC8C6C2), tie = C(0xD81E30), tieD = C(0x981424)
    let hair = C(0x181A28), hairL = C(0x3E4A6E)
    let wing = C(0xE6DAF8), wingD = C(0xB8A2DC), wingL = C(0xFFFFFF)
    let spark = C(0xFF3A50), sparkL = C(0xFFD0D8)
    let s = p.signature ?? -1

    // The loop: up a little, round a loop forward, over and back, and down; red sparkles left behind along it.
    func loop(_ u: Double) -> (x: Double, y: Double) {
        let rise = min(1, min(u, 1 - u) * 6) * 3
        let a = u > 0.15 && u < 0.85 ? (u - 0.15) / 0.7 * 2 * .pi : 0
        return (rise / 3 * 2 + sin(a) * 4, -(rise * 0.7 + (1 - cos(a)) * 3))
    }
    var off = (x: 0.0, y: 0.0)
    if s > 0.06 && s < 0.94 {
        let u = (s - 0.06) / 0.88
        off = loop(u)
        for k in 1...12 {
            let uk = u - Double(k) * 0.022
            guard uk > 0 else { break }
            let q = loop(uk)
            let x = Int((26 + q.x).rounded()), y = Int((40 + q.y).rounded())
            let a = 1 - Double(k) / 13
            let col = k % 3 == 0 ? sparkL : spark
            c.px(x, y, col.alpha(a)); c.px(x - 1, y, spark.alpha(a * 0.4)); c.px(x + 1, y, spark.alpha(a * 0.4))
            c.px(x, y - 1, spark.alpha(a * 0.4)); c.px(x, y + 1, spark.alpha(a * 0.4))
        }
    }
    let fluttering = p.flying || (s > 0.06 && s < 0.94)
    c.ox += Int(off.x.rounded()); c.oy += Int(off.y.rounded())

    // 1. Black trousers with a satin stripe, shiny black shoes.
    drawLegs(c, Look(leg: tux), step: p.step)
    drawBoots(c, C(0x0A0A0E), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = v6Foot(i, p.step)
            c.rect(lx, 38, 1, b - 38, satin); c.px(lx + 1, b, C(0x6A6A80))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The wings at her back, two pairs: pale lilac, a white sheen near the root, a darker rim and vein; fluttering
    //    quickly in flight, slowly at rest.
    let root = (19.0, 30.0)
    let upper: [(Double, Double)] = [(19, 29), (15, 22), (10, 17), (7, 18), (7, 23), (12, 28)]
    let lower: [(Double, Double)] = [(19, 31), (12, 31), (7, 35), (8, 39), (13, 38), (18, 33)]
    let beat = fluttering ? (Int(p.t * 22) % 2 == 0 ? 0.0 : 22.0) : (sin(p.lt * 2.4) + 1) * 4
    for (poly, dir) in [(upper, 1.0), (lower, -1.0)] {
        let w = v6Turn(poly, about: root, beat * dir)
        v6Fill(c, w, wing)
        for i in 0..<w.count {
            let a = w[i], b = w[(i + 1) % w.count]
            if i == 0 || i == w.count - 1 { continue }
            c.glowLine(a.0, a.1, b.0, b.1, core: wingD, glow: C(0, 0), coreR: 0.4, glowR: 0.5)
        }
        let mid = w[w.count / 2]
        c.glowLine(root.0, root.1, (root.0 + mid.0) / 2, (root.1 + mid.1) / 2, core: wingL, glow: C(0, 0), coreR: 0.5,
                   glowR: 0.6)
    }

    // 4. The tails of the tuxedo, behind.
    c.pattern(15, 36, ["TTT", "TTT", ".TT", ".TT", "..T"], ["T": tuxD])

    // 5. The body, the arms in black sleeves; the near hand out with a sparkle at its tip when she fires.
    drawBody(c, Look(arm: tux, eye: nil))
    c.px(15, 33, tuxL); c.px(38, 33, tuxL)
    var firing = false
    if let f = p.fire { firing = v6Frac(f.t / p.firePeriod) < 0.3 }
    if firing || p.ready {
        c.rect(41, 33, 2, 2, clawdOrange); c.px(43, 33, clawdOrange)
        if firing {
            c.px(44, 33, sparkL); c.px(45, 33, spark.alpha(0.6)); c.px(44, 32, spark.alpha(0.6)); c.px(44, 34, spark.alpha(0.6))
        }
    } else {
        c.rect(41, 34, 2, 2, clawdOrange); c.px(42, 35, clawdShade)
    }

    // 6. The tuxedo: black, satin lapels lit along their edges, the white shirt front with studs, the red bow tie,
    //    the far side in shade.
    c.rect(18, 33, 20, 5, tux)
    c.rect(18, 33, 1, 5, tuxL); c.rect(36, 33, 2, 5, tuxD); c.rect(18, 37, 20, 1, tuxD)
    c.pattern(23, 33, ["SSWWWWWWSS", ".SSWWWWSS.", "..SSWWSS..", "...SSSS...", "....SS...."],
              ["S": satin, "W": shirt])
    c.px(28, 35, shirtD); c.px(28, 36, ink)
    c.pattern(25, 33, ["TT.TT", "TtTtT"], ["T": tie, "t": tieD])
    c.px(27, 33, tieD)

    // 7. The face: dark eyes with fine lashes, a glint, small red lips.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(22, 29, C(0x5A5A6A)); c.px(32, 29, C(0x5A5A6A))
    c.px(21, 28, ink); c.px(34, 28, ink)
    c.rect(27, 32, 2, 1, C(0xC02A3A))

    // 8. The hair: raven black, sleek, combed straight back in strands that catch a blue sheen, into a tight bun at the
    //    back of her head, a red pin through it.
    c.pattern(17, 22, [
        "....HHHHHHHHHHHHH...",
        "..HHlHHHHlHHHHHHHH..",
        ".HHHHlHHHHlHHHHlHHH.",
        "HHHHHHlHHHHlHHHHlHHH",
        "HHH..............HHH",
        "HH................HH",
        "H..................H",
    ], ["H": hair, "l": hairL])
    c.circle(18, 21, 3, hair)
    c.pattern(16, 19, [".l..", "l..l", "l.l.", ".ll."], ["l": hairL])
    c.rect(13, 20, 4, 1, tie); c.px(13, 20, tieD)
}
