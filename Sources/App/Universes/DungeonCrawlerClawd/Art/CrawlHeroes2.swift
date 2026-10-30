import Foundation

// Heroes, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The rest of the Royal Court, Meadow Lark, and Bautista.

let crawlHeroes2: [CrawlHero: Persona] = [
    .katia: Persona(name: "Katia Grim", weapon: .saber, bulk: 4, headTop: 21, signature: 3.2, draw: drawKatia),
    .mordecai: Persona(name: "Mordecai", weapon: .blaster, shot: .thrown(C(0x5ED65A)), muzzle: (43, 33), handGun: false,
                       headTop: 22, signature: 3.4, draw: drawMordecai),
    .samantha: Persona(name: "Samantha", weapon: .saber, headTop: 14, signature: 2.8, callout: "I'll kill your mother!",
                       draw: drawSamantha),
    .prepotente: Persona(name: "Prepotente", weapon: .saber, headTop: 14, signature: 2.6,
                         callout: "AAAAAH!", draw: drawPrepotente),
    .louis: Persona(name: "Louis", weapon: .lightning,
                    magic: Magic(core: C(0xDCE6C8), glow: C(0x7E9A5E), jagged: false, waves: true),
                    headTop: 20, signature: 3.0, draw: drawLouis),
    .elle: Persona(name: "Elle McGibbons", weapon: .blaster, motion: .hover, shot: .ice, muzzle: (43, 34.5), handGun: false,
                   headTop: 15, signature: 3.2, draw: drawElle),
    .imani: Persona(name: "Imani", weapon: .saber, headTop: 12, signature: 3.0, draw: drawImani),
    .brandon: Persona(name: "Brandon Andrews", weapon: .saber, headTop: 22, signature: 3.2, draw: drawBrandon),
    .chris: Persona(name: "Chris Andrews", weapon: .saber, armoured: true, bulk: 4, headTop: 13, signature: 3.0,
                    draw: drawChris),
    .bautista: Persona(name: "Bautista", weapon: .saber, headTop: 22, signature: 3.6, draw: drawBautista),
]

// MARK: - Shared bits

/// The bottom row of leg `i` this frame: a row higher while it's lifted in the walk.
private func footRow(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

/// A straight run of pixels from `a` to `b`, one pixel wide: a crack, a vein.
private func pixelLine(_ c: PixelCanvas, _ a: (Int, Int), _ b: (Int, Int), _ col: Px) {
    let n = max(abs(b.0 - a.0), abs(b.1 - a.1))
    for i in 0...max(n, 0) {
        let t = n == 0 ? 0 : Double(i) / Double(n)
        let x = Double(a.0) + Double(b.0 - a.0) * t, y = Double(a.1) + Double(b.1 - a.1) * t
        c.px(Int(x.rounded()), Int(y.rounded()), col)
    }
}

/// Fills the triangle `a`, `b`, `d`, colouring each pixel from its weights towards each corner (1 at that corner, 0
/// on the side across from it), so a wing's border, veins and leading edge come from where in it a pixel falls.
/// `paint` returns nil to leave a pixel empty.
private func fillTriangle(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double),
                          _ d: (x: Double, y: Double), _ paint: (_ wa: Double, _ wb: Double, _ wd: Double) -> Px?) {
    let x0 = Int(floor(min(a.x, b.x, d.x))), x1 = Int(ceil(max(a.x, b.x, d.x)))
    let y0 = Int(floor(min(a.y, b.y, d.y))), y1 = Int(ceil(max(a.y, b.y, d.y)))
    let den = (b.y - d.y) * (a.x - d.x) + (d.x - b.x) * (a.y - d.y)
    guard abs(den) > 0.001 else { return }
    for y in y0...y1 {
        for x in x0...x1 {
            let fx = Double(x) + 0.5, fy = Double(y) + 0.5
            let wa = ((b.y - d.y) * (fx - d.x) + (d.x - b.x) * (fy - d.y)) / den
            let wb = ((d.y - a.y) * (fx - d.x) + (a.x - d.x) * (fy - d.y)) / den
            let wd = 1 - wa - wb
            guard wa >= 0, wb >= 0, wd >= 0 else { continue }
            if let col = paint(wa, wb, wd) { c.px(x, y, col) }
        }
    }
}

/// A solid box laid along `angle` from `from`: `a` to `b` pixels out, `v0` to `v1` across (positive: clockwise of the
/// angle). Lit along its top-left edge, shaded along its bottom-right: a hammer's head, an axe's blade.
private func angledBlock(_ c: PixelCanvas, _ from: (x: Double, y: Double), _ angle: Double, along a: Double, _ b: Double,
                         across v0: Double, _ v1: Double, _ col: Px, _ dark: Px, _ light: Px) {
    let r = angle * .pi / 180
    let ux = cos(r), uy = sin(r)
    let um = (a + b) / 2, vm = (v0 + v1) / 2
    let mx = from.x + ux * um - uy * vm, my = from.y + uy * um + ux * vm
    let reach = hypot(b - a, v1 - v0) / 2 + 1
    for y in Int(floor(my - reach))...Int(ceil(my + reach)) {
        for x in Int(floor(mx - reach))...Int(ceil(mx + reach)) {
            let dx = Double(x) + 0.5 - from.x, dy = Double(y) + 0.5 - from.y
            let u = dx * ux + dy * uy, v = -dx * uy + dy * ux
            guard u >= a, u <= b, v >= v0, v <= v1 else { continue }
            let edge = min(u - a, b - u) < 1 || min(v - v0, v1 - v) < 1
            if edge {
                let side = (Double(x) + 0.5 - mx) + (Double(y) + 0.5 - my)
                c.px(x, y, side < 0 ? light : dark)
            } else {
                c.px(x, y, col)
            }
        }
    }
}

/// Draws `art` on a scratch canvas (no offsets), turns it `degrees` about `pivot` (positive: clockwise) and lays it
/// on `c` with its offsets: a head thrown back.
private func turned(_ c: PixelCanvas, _ degrees: Double, about pivot: (x: Double, y: Double), _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    if abs(degrees) < 0.5 { c.paste(s); return }
    c.paste(s.rotated(degrees, about: pivot, into: c.w, c.h, at: pivot))
}

// MARK: - Katia Grim

/// Katia Grim: pale Clawd with a purple mohawk, its spikes swept back, the sides of her head shaved; a black crop top,
/// charcoal trousers and black boots. She fights with her fists in her combat form, and her signature is the same
/// change: she swells into her hulking pink eight-foot form, body, arms and legs all thickening, her brow knitting
/// and her teeth clenched, and back down again.
private func drawKatia(_ c: PixelCanvas, _ p: Pose) {
    let pale = C(0xEEDDD4), paleD = C(0xC9B3A8), paleL = C(0xFFF4EE)
    let pink = C(0xE8789E), pinkD = C(0xB84E76), pinkL = C(0xFFA6C4)
    let hair = C(0x8E3CCC), hairD = C(0x5E2294), hairL = C(0xBC7CF6)
    let top = C(0x26242C), topL = C(0x46424E), topD = C(0x18171C)
    let cloth = C(0x3E424E), clothD = C(0x2A2C36), boot = C(0x16151A)
    let s = p.signature ?? -1
    // How far into the combat form she is: all the way while she fights, swelling and shrinking in her signature.
    let fighting = p.melee != nil && p.mode == .working && !p.walking && !p.cheering
    var g = 0.0
    if fighting {
        g = 1
    } else if s >= 0 {
        if s < 0.3 { g = max(0, (s - 0.08) / 0.22) } else if s < 0.72 { g = 1 } else { g = max(0, (0.92 - s) / 0.2) }
    }
    let e = Int((g * 4).rounded())   // 0 her own size … 4 the full form
    let k = Double(e) / 4
    let skin = lerp(pale, pink, k), skinD = lerp(paleD, pinkD, k), skinL = lerp(paleL, pinkL, k)
    let left = 18 - e / 2, right = 37 + e, head = 26 - 2 * e
    let w = right - left + 1
    let lw = e >= 2 ? 3 : 2

    // 1. Charcoal trousers and black boots, the legs thickening with the rest of her.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, lw + 2, 2, cloth); c.rect(lx - 1, 39, lw + 2, 1, clothD) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, 36, lw, b - 35, cloth)
            c.rect(lx + lw - 1, 36, 1, b - 37, clothD)
            c.rect(lx, b - 1, lw, 2, boot); c.px(lx, b - 1, C(0x3A3842))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, then her body: pale, pink in the combat form, lit on top and the left, the far side in shade.
    let a = 3 + e / 2
    c.rect(left - a, 36 - a, a, a, skin); c.rect(left - a, 35, a, 1, skinD)
    c.rect(left, head, w, 38 - head, skin)
    c.rect(left, head, w, 1, skinL); c.rect(left, head, 1, 38 - head, skinL)
    c.rect(right, head, 1, 38 - head, skinD)

    // 4. The black crop top, the belt and the top of the trousers.
    let tr = 33 - e
    c.rect(left, tr, w, 36 - tr, top)
    c.rect(left, tr, w, 1, topL); c.rect(right, tr, 1, 36 - tr, topD)
    c.rect(left, 36, w, 2, cloth); c.rect(left, 37, w, 1, clothD)
    c.rect(left, 36, w, 1, C(0x1C1A20)); c.px(left + w / 2 + 2, 36, C(0xB8BCC6))

    // 5. The face: Clawd's eyes; in the combat form a knitted brow and clenched teeth.
    let ey = head + 3, ex1 = 22 + e / 2, ex2 = 32 + e
    c.rect(ex1, ey, 2, 3, ink); c.rect(ex2, ey, 2, 3, ink)
    if e >= 2 {
        c.pattern(ex1 - 1, ey - 2, ["dd..", ".ddd"], ["d": skinD])
        c.pattern(ex2 - 1, ey - 2, ["..dd", "ddd."], ["d": skinD])
    }
    if e >= 3 {
        c.rect(ex2 - 5, ey + 5, 6, 1, C(0xF6F2EE)); c.rect(ex2 - 5, ey + 6, 6, 1, skinD)
        c.px(ex2 - 3, ey + 5, skinD)
    }

    // 6. The mohawk: a ridge of purple spikes along the top of her head, each swept back, lit at its tip.
    let mx0 = left + 3 + e / 2, mw = 13 + e
    for i in 0..<mw {
        let ph = i % 4
        let hgt = [5, 4, 3, 2][ph] + (i >= mw - 2 ? -1 : 0)
        for r in 0..<max(1, hgt) {
            let col = r == hgt - 1 ? hairL : (ph == 3 || r == 0 && ph == 0 ? hairD : hair)
            c.px(mx0 + i, head - 1 - r, col)
        }
    }

    // 7. The near fist: out at whatever angle it's swinging, or the arm at her side.
    let fs = e >= 3 ? 4 : 3
    func fist(_ x: Int, _ y: Int, _ al: Double) {
        c.rect(x - 1, y - 1, fs, fs, skin.alpha(al))
        c.rect(x - 1, y - 1, fs, 1, skinL.alpha(al)); c.rect(x - 1, y + fs - 2, fs, 1, skinD.alpha(al))
    }
    if let ang = p.melee {
        crawlPunch(c, angle: ang, trail: p.trail, arm: skin, reach: 6 + Double(e) / 2, fist: fist)
    } else {
        c.rect(right + 1, 36 - a, a, a, skin); c.rect(right + 1, 36 - a, a, 1, skinL); c.rect(right + 1, 35, a, 1, skinD)
    }
}

// MARK: - Mordecai

/// Mordecai: a Skyfowl, Clawd as a golden-brown eagle: a crest of feathers swept back off his head, a stern brow over
/// amber eyes, a hooked yellow beak, a cream chest under an open black vest, blue trousers, and scaly yellow feet in
/// brown sandals. He throws green potions. Signature: he holds up a big round flask and stirs it, bubbles rising off it,
/// and it puffs a little green cloud.
private func drawMordecai(_ c: PixelCanvas, _ p: Pose) {
    let feather = C(0xA8742E), featherD = C(0x7C5220), featherL = C(0xCC9A4E)
    let cream = C(0xE6CC98), creamD = C(0xC4A874)
    let beak = C(0xF2C232), beakD = C(0xB8881A), amber = C(0xFFC828)
    let vest = C(0x1C1A20), vestL = C(0x3A3640)
    let blue = C(0x3A5CAA), blueD = C(0x284482), sole = C(0x6E4628), strap = C(0x8E5E34)
    let glass = C(0x5ED65A), glassD = C(0x2E9A3A), glassL = C(0xC8FFB8), cork = C(0x9A6A3A)
    let s = p.signature ?? -1
    let brewing = s > 0.04 && s < 0.96

    // 1. Blue trousers, the scaly yellow feet in brown sandals, a talon over the front of each sole.
    drawLegs(c, Look(leg: blue), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx + 1, 36, 1, b - 38, blueD)
            c.px(lx, b - 1, beak); c.px(lx + 1, b - 1, strap)
            c.rect(lx, b, 2, 1, sole); c.px(lx + 2, b, beakD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in golden-brown feathers, lit on top; the near arm comes up with the flask.
    drawBody(c, Look(body: feather, shade: featherD, arm: feather, eye: nil), armRight: brewing ? 3 : 0)
    c.rect(18, 26, 20, 1, featherL); c.rect(18, 26, 1, 6, featherL)
    c.px(15, 33, featherL)

    // 4. The crest: feathers swept back off the top of his head.
    c.pattern(13, 22, [
        "..LL.........",
        ".LFFL........",
        "LFFFFFL..L...",
        ".dFFFFFFFFFFF",
    ], ["F": feather, "L": featherL, "d": featherD])

    // 5. The open black vest over his cream chest, blue trousers at the waist.
    c.rect(18, 32, 20, 4, vest)
    c.rect(18, 32, 1, 4, vestL); c.rect(19, 32, 3, 1, vestL)
    c.rect(24, 31, 8, 1, cream)
    c.pattern(23, 32, ["CCCCCCCCC", ".CCcCCcC.", "..CCcCC..", "...CCC..."], ["C": cream, "c": creamD])
    c.px(22, 32, vestL); c.px(32, 32, vestL)
    c.rect(18, 36, 20, 2, blue); c.rect(18, 37, 20, 1, blueD)

    // 6. The face: a stern brow, amber eyes, the hooked beak.
    c.rect(20, 28, 5, 1, featherD); c.rect(30, 28, 5, 1, featherD)
    for x in [22, 32] { c.rect(x, 29, 2, 3, amber); c.rect(x + 1, 29, 1, 2, ink) }
    c.pattern(35, 29, [
        "BBB...",
        "BBBBB.",
        "bbbBBB",
        "....bB",
    ], ["B": beak, "b": beakD])

    // 7. The flask: at rest a small green one in his hand (gone a moment as he throws it); in the signature a big
    //    round one held up and stirred, bubbles rising off it, then a puff of green cloud.
    if brewing {
        let wob = Int((sin(p.lt * 9) * 1.2).rounded())
        c.rect(43 + wob, 23, 1, 7, C(0xD8DCE0))   // the stirring rod
        c.pattern(41, 28, [
            "..n..",
            ".GGG.",
            "GLGGG",
            "GGGGG",
            "GGGGg",
            ".ggg.",
        ], ["n": glassL, "G": glass, "L": glassL, "g": glassD])
        let n = Int(p.lt * 10)
        c.px(42 + n % 3, 31 + n % 2, glassL)   // the brew bubbling inside
        for k in 0..<3 {
            let rise = (s * 5 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
            c.px(43 + (k + n / 3) % 3 - 1, 26 - Int(rise * 6), C(0xB8F0A8, 1 - rise * 0.6))
        }
        if s > 0.6 && s < 0.86 {
            let r = sin((s - 0.6) / 0.26 * .pi) * 4
            let cx = 45.0, cy = 19.0 - (s - 0.6) * 12
            for y in Int(cy - r)...Int(cy + r) {
                for x in Int(cx - r - 1)...Int(cx + r + 1) {
                    let dx = (Double(x) + 0.5 - cx) / (r + 1), dy = (Double(y) + 0.5 - cy) / max(r, 0.5)
                    guard dx * dx + dy * dy <= 1 else { continue }
                    c.px(x, y, dy < -0.3 ? C(0xEEFFE8) : C(0xBEEAB2))
                }
            }
        }
    } else if p.recoil == 0 {
        c.px(42, 31, cork); c.px(42, 32, glassL)
        c.rect(41, 33, 3, 3, glass); c.px(41, 33, glassL); c.rect(41, 35, 3, 1, glassD)
    }
}

// MARK: - Samantha

/// Samantha: a big porcelain doll's head on four little legs in black shoes: wild bone-white hair over the top and down
/// the back, wide unblinking blue eyes with heavy lashes, rosy cheeks, and a smeared red lipstick mouth with two little
/// fangs. She bites. Signature: she rages, her brows slamming down and her mouth snarling open, and for a moment her
/// hair catches fire.
private func drawSamantha(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xF4DACB), skinD = C(0xD6B4A4), skinL = C(0xFFF0E6), blush = C(0xF0A4A4)
    let hair = C(0xEDE6D2), hairD = C(0xC4BA9E), hairL = C(0xFFFCF4)
    let lip = C(0xD4243A), smear = C(0xE85868), mouth = C(0x5A1420), fang = C(0xFFFFFF)
    let iris = C(0x4A8AD8), irisL = C(0x9AC8FF), lash = C(0x2A1A20), brow = C(0x8A6A5A)
    let s = p.signature ?? -1
    let rage = s > 0.06 && s < 0.94
    let fire = s > 0.28 && s < 0.8 ? sin((s - 0.28) / 0.52 * .pi) : 0
    let biting = p.melee.map { $0 > -45 } ?? false

    // 1. Little porcelain legs in black shoes.
    drawLegs(c, Look(leg: skin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx + 1, 38, 1, b - 39, skinD)
            c.rect(lx, b - 1, 2, 2, C(0x1A1820)); c.px(lx, b - 1, C(0x4A4652))
        }
    }

    // 2. The breath; she lunges when she bites, and shakes with rage.
    c.oy += p.breathe
    if biting { c.ox += 2 }
    if rage && noise(Int(p.lt * 24)) > 0.5 { c.ox += 1 }

    // 3. The head: a big porcelain ball, shaded round its right and bottom.
    let cx = 28.0, cy = 27.0
    for y in 15...38 {
        for x in 15...41 {
            let dx = (Double(x) + 0.5 - cx) / 11.5, dy = (Double(y) + 0.5 - cy) / 11.0
            let d = dx * dx + dy * dy
            guard d <= 1 else { continue }
            let rim = dx * 0.6 + dy * 0.8
            c.px(x, y, rim > 0.72 ? skinD : (rim < -0.6 ? skinL : skin))
        }
    }

    // 4. The hair: bone-white, wild, over the top of her head with a fringe in front and long down the back; strokes
    //    down it and a lit run along the top.
    for y in 13...36 {
        for x in 13...41 {
            let dx = (Double(x) + 0.5 - cx) / 13.0, dy = (Double(y) + 0.5 - cy) / 12.5
            let d = dx * dx + dy * dy
            guard d <= 1 else { continue }
            let line: Int
            if x < 20 { line = 36 - (x % 2) * 2 } else if x < 23 { line = 27 } else { line = 21 + (x % 3 == 0 ? 1 : 0) }
            guard y < line else { continue }
            if d > 0.9 && (x + y) % 3 == 0 { continue }   // wild ends
            var col = hair
            if d > 0.78 && dy < -0.45 { col = hairL } else if x % 3 == 1 && (y > 21 || dy < -0.2) { col = hairD }
            c.px(x, y, col)
        }
    }

    // 5. The eyes: wide, unblinking, lashes heavy along the top and flicking out at the corner; brows slam down when
    //    she rages.
    for x in [22, 31] {
        c.pattern(x, 24, [
            "KKKKK",
            "WGIIW",
            "WIIPW",
            ".WWW.",
        ], ["K": lash, "W": C(0xFFFFFF), "G": irisL, "I": iris, "P": ink])
        c.px(x + 5, 23, lash)
    }
    if rage {
        c.pattern(21, 21, ["bb....", ".bbbb."], ["b": brow]); c.pattern(30, 21, ["..bbbb", "bbbb.."], ["b": brow])
    }
    c.rect(20, 29, 3, 1, blush); c.rect(34, 29, 3, 1, blush)
    c.px(29, 29, skinD)   // the little nose

    // 6. The mouth: red lipstick smeared up past its corner, two fangs; wide open in a snarl or a bite.
    if biting || rage {
        c.pattern(25, 31, [
            "........ss",
            ".RRRRRRRs.",
            "RkWkkkWkR.",
            "RkkkkkkkR.",
            ".RRRRRRR..",
        ], ["R": lip, "s": smear, "k": mouth, "W": fang])
    } else {
        c.pattern(25, 31, [
            "........s.",
            ".RRRRRRs..",
            "RkWkkWkR..",
            ".RRRRRR...",
        ], ["R": lip, "s": smear, "k": mouth, "W": fang])
    }
    if biting {
        for (i, y) in [29, 33, 37].enumerated() { c.rect(42 + (i == 1 ? 1 : 0), y, 2, 1, C(0xFFFFFF, 0.8)) }
    }

    // 7. The fire: flames licking up off the top of her hair for a moment.
    if fire > 0.05 {
        for x in 17...39 {
            let dx = (Double(x) + 0.5 - cx) / 13.0
            guard abs(dx) < 1 else { continue }
            let topY = Int((cy - 12.5 * sqrt(1 - dx * dx)).rounded()) + 1
            let h = Int((fire * (3 + 2.5 * (1 + sin(Double(x) * 1.7 + p.lt * 16)))).rounded())
            for r in 0..<h {
                let col = r < h / 3 ? C(0xFF6A1A) : (r < h * 2 / 3 ? C(0xFFA42A) : C(0xFFE27A))
                c.px(x, topY - r, col)
            }
        }
    }
}

// MARK: - Prepotente

/// Prepotente: a goat standing on his own four legs, in a dark plum robe down to his hocks, a cream goat's head with
/// ram's horns curling back, a beard and yellow eyes, curled black nails on the hand that holds his axe. Signature: he
/// throws his head back and screams.
private func drawPrepotente(_ c: PixelCanvas, _ p: Pose) {
    let wool = C(0xE6E0D2), woolD = C(0xB8AE9C), woolL = C(0xFFFCF2), ram = C(0x9A8462), ramD = C(0x6A5640)
    let robe = C(0x5A2036), robeD = C(0x3C1424), robeL = C(0x7C3652), nail = C(0x0E0C10), hoof = C(0x2A2630)
    let steel = C(0xB8BEC8), steelD = C(0x7A808C), steelL = C(0xEEF2F8), haft = C(0x6A4A2A)
    let s = p.signature ?? -1
    let scream = s > 0.1 && s < 0.9
    let back = scream ? min(1, (s - 0.1) / 0.12, (0.9 - s) / 0.12) : 0

    // 1. His legs: cream wool under the robe's hem, black hooves.
    drawLegs(c, Look(leg: woolD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, footRow(i, p.step), 2, 1, hoof) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The robe: dark plum over the body, lit on the left, shaded under and on the far side, a fold or two, a
    //    darker hem.
    c.rect(18, 26, 20, 12, robe)
    c.rect(18, 26, 1, 12, robeL); c.rect(18, 26, 20, 1, robeL)
    c.rect(37, 26, 1, 12, robeD); c.rect(18, 37, 20, 1, robeD)
    c.rect(23, 30, 1, 7, robeD); c.rect(29, 31, 1, 6, robeD)

    // 4. His head: cream, ram's horns curling back, an ear, a yellow eye with its flat pupil, a long muzzle with a black
    //    nose, a beard down over the robe's collar. Thrown back when he screams, the mouth open.
    let wide = scream && back > 0.5
    turned(c, -38 * back, about: (28, 26)) { h in
        h.pattern(20, 14, [
            "..rrrr............",
            ".rRRRRr...........",
            "rR...rRr..........",
            "rR....wwwww.......",
            ".rr.LwwwwwwLw.....",
            "eee.wwwwwYkYw.....",
            ".eewwwwwwwwwwwww..",
            "...wwwwwwwwwwwwwwN",
            "...dwwwwwwwwwwwwww",
            "....dwwwwwwwwwwww.",
            ".....dwwwwwwwwwd..",
            "......dddwwwbbb...",
            "..........bbb.....",
            "...........b......",
        ], ["r": ramD, "R": ram, "w": wool, "L": woolL, "d": woolD, "e": woolD, "Y": C(0xF0D040), "k": ink,
            "N": ink, "b": woolD])
        if wide { h.pattern(31, 22, ["mmmmmm", ".mmmm."], ["m": C(0x4A1A22)]) } else { h.rect(32, 23, 5, 1, woolD) }
    }
    if scream && Int(p.lt * 10) % 3 != 0 {
        for i in 0..<3 {
            let x = 41 + i * 2
            c.px(x, 14 - i, C(0xFFFFFF, 0.8)); c.px(x + 1, 15 - i, C(0xFFFFFF, 0.8))
            c.px(x + 1, 19 + i, C(0xFFFFFF, 0.8)); c.px(x + 2, 18 + i, C(0xFFFFFF, 0.8))
        }
    }

    // 5. The near arm in its sleeve, the hand with its curled black nails, and the axe: at rest held up, or swung.
    c.rect(37, 32, 3, 3, robe); c.rect(37, 32, 3, 1, robeL)
    let ang = p.melee ?? -70
    let piv = Sprite.hand
    for (i, t) in p.trail.enumerated() {
        angledBlock(c, piv, t, along: 7, 10.5, across: 0.5, 4, steel.alpha(0.3 / Double(i + 1)),
                    steel.alpha(0.3 / Double(i + 1)), steel.alpha(0.3 / Double(i + 1)))
    }
    crawlBar(c, piv, ang, from: -1, to: 11, haft, r: 0.7)
    angledBlock(c, piv, ang, along: 6.5, 10.5, across: 0.5, 4.2, steel, steelD, steelL)
    c.rect(40, 33, 3, 3, wool); c.px(40, 33, woolL)
    c.px(43, 33, nail); c.px(43, 35, nail); c.px(42, 36, nail)
}

// MARK: - Louis

/// Louis: Clawd with messy dirty-blond hair, a black leather jacket hanging open over a white Donut Holes fan T-shirt
/// (a big pink donut on it), dark jeans and white trainers. His Cloud of Exhaust rolls out at his foes in grey-green.
/// Signature: he takes a swig from a bottle, then hiccups, twice.
private func drawLouis(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x2A282E), leatherD = C(0x18171B), leatherL = C(0x4A4852)
    let shirt = C(0xF2F0EA), shirtD = C(0xCFCCC4)
    let donut = C(0xF06AA8), donutD = C(0xBC4482), dough = C(0xD8A060)
    let hair = C(0xC8A050), hairD = C(0x9A7838), hairL = C(0xECCC7C)
    let denim = C(0x2E3A58), denimD = C(0x222B44)
    let bottle = C(0x2E7A34), bottleL = C(0x8ADC8A)
    let s = p.signature ?? -1
    let swig = s > 0.08 && s < 0.5
    let hic = (s > 0.6 && s < 0.66) || (s > 0.8 && s < 0.86)

    // 1. Dark jeans, white trainers with a grey sole.
    drawLegs(c, Look(leg: denim), step: p.step)
    drawBoots(c, shirt, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx + 1, 36, 1, b - 38, denimD)
            c.rect(lx, b, 2, 1, C(0x8A8A92))
        }
    }

    // 2. The breath; a hiccup jolts him up.
    c.oy += p.breathe
    if hic { c.oy -= 1 }

    // 3. The body; the near arm in its leather sleeve comes up with the bottle, or to cast.
    let raise = swig ? 5 : p.armRaise
    drawBody(c, Look(arm: leather, eye: nil), armRight: raise)
    c.px(38, 33 - raise, leatherL)
    c.rect(15, 33, 3, 3, leather); c.px(15, 33, leatherL)

    // 4. The jacket, hanging open: lit on the left, the far side in shade, its collar turned up; the white T-shirt in
    //    the opening with its pink donut.
    c.rect(18, 33, 20, 5, leather)
    c.rect(18, 33, 1, 5, leatherL); c.rect(19, 33, 4, 1, leatherL); c.rect(36, 33, 2, 5, leatherD)
    c.rect(24, 33, 8, 5, shirt); c.rect(31, 33, 1, 5, shirtD)
    c.rect(23, 33, 1, 5, leatherL); c.rect(32, 33, 1, 5, leatherD)   // the lapels
    c.pattern(25, 33, [
        ".PPP.",
        "PPPPP",
        "PP.PP",
        "PPPPp",
        ".ppp.",
    ], ["P": donut, "p": donutD])
    c.px(26, 33, C(0xFFE27A)); c.px(29, 35, C(0x7AD8F0))   // sprinkles
    c.px(25, 36, dough); c.px(29, 36, dough)

    // 5. The face: Clawd's eyes, screwed shut on a hiccup.
    if hic {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }

    // 6. The hair: dirty blond, messy, pushed up in front.
    c.pattern(17, 21, [
        "....L..L...L..L.....",
        "...HL.HL..HHL.HHL...",
        "..HHHHHHHHHHHHHHHH..",
        ".HHhHHHhHHHHhHHHHHH.",
        "HHHHHHHHHHHHHHHHHHHH",
        "H.hH.hH..H.hH..hH..H",
    ], ["H": hair, "h": hairD, "L": hairL])

    // 7. The bottle up at his mouth, tipped back; then the hiccup's bubble floating up.
    if swig {
        let tip = sin(min(1, (s - 0.08) / 0.1) * .pi / 2)
        let ang = -120 - 20 * tip
        crawlBar(c, (41, 29), ang, from: -1, to: 4, bottle, r: 1.4)
        crawlBar(c, (41, 29), ang, from: 0, to: 3, bottleL, r: 0.4)
        crawlBar(c, (41, 29), ang, from: 4, to: 7, bottle, r: 0.6)
        c.rect(39, 28, 2, 2, clawdOrange)
    }
    for start in [0.6, 0.8] where s > start && s < start + 0.16 {
        let k = (s - start) / 0.16
        let y = 28 - Int(k * 10), x = 39 + Int(sin(k * 6) * 1.5)
        c.pattern(x, y, [".b.", "b.b", ".b."], ["b": C(0xE8F4FF, 1 - k * 0.7)])
    }
}

// MARK: - Elle McGibbons

/// Elle McGibbons: a tiny Frost Maiden, Clawd in pale icy blue, a wild cloud of white hair standing up off her head
/// and down her back, a deep blue nightgown, and yellow anti-slip socks with white grip dots. She hovers just off the
/// ground, and throws icicles from her palms. Signature: a little snow flurry swirls round her.
private func drawElle(_ c: PixelCanvas, _ p: Pose) {
    let ice = C(0xA8D8EE), iceD = C(0x7AB0D0), iceL = C(0xD8F2FF)
    let gown = C(0x4E7EB4), gownD = C(0x385E8C), gownL = C(0x6E9ACC)
    let hair = C(0xF4F8FC), hairD = C(0xC4CEDC), hairL = C(0xFFFFFF)
    let sock = C(0xE8C040), sockD = C(0xB8902A), grip = C(0xFFF6D8)
    let s = p.signature ?? -1
    var frost = 0.0
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        frost = ph < 0.3 ? 1 - ph / 0.3 : 0
    }

    // 1. Pale blue legs in yellow anti-slip socks, white grip dots on the soles.
    drawLegs(c, Look(leg: ice), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, b - 3, 2, 4, sock); c.rect(lx + 1, b - 3, 1, 4, sockD)
            c.rect(lx, b - 3, 2, 1, grip)
            c.px(lx, b, grip)
        }
    } else {
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, sock); c.px(lx + 2, 39, grip) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Her hair down her back, behind her.
    c.pattern(13, 26, [
        "HHHHH",
        "HhhHH",
        ".HHHH",
        "HHHHH",
        ".HhH.",
        "..H..",
    ], ["H": hair, "h": hairD])

    // 4. The body in pale ice blue, lit on top and the left, the near palm thrust out frosted when she throws.
    let thrust = frost > 0.5 ? 1 : 0
    drawBody(c, Look(body: ice, shade: iceD, arm: ice))
    c.rect(18, 26, 20, 1, iceL); c.rect(18, 26, 1, 7, iceL)
    if thrust > 0 { c.rect(41, 33, 1, 3, ice) }
    c.px(40 + thrust, 34, iceL)

    // 5. The nightgown, deep blue, a frill along its neckline.
    c.rect(18, 33, 20, 5, gown)
    c.rect(18, 33, 20, 1, gownL); c.rect(18, 33, 1, 5, gownL); c.rect(37, 33, 1, 5, gownD); c.rect(18, 37, 20, 1, gownD)
    for x in stride(from: 19, to: 37, by: 3) { c.px(x, 34, gownD) }
    c.rect(15, 33, 3, 1, gown)   // the far sleeve

    // 6. The face: a glint of frost in each eye, a small stern mouth.
    c.px(22, 29, iceL); c.px(32, 29, iceL)
    c.rect(27, 32, 3, 1, iceD)

    // 7. The hair: a wild white cloud, frizzing up off her head and out at the back.
    c.pattern(14, 15, [
        "......L...L..L........",
        "...L.LL.LLL.LLL.L.....",
        "..HLLLLLLLLLLLLLHH.L..",
        ".LHHHHHHHHHHHHHHHHHH..",
        "HHHHhhHHHHHHhhHHHHHHH.",
        ".HHHHHhhHHHHHHhhHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHhhHHHHHhhHHHHHHhhHH.",
        ".HHHhhHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHH",
        "HHHH...H.HH.H..H.HHH.H",
        "HHhH..................",
        "HhHH..................",
    ], ["H": hair, "h": hairD, "L": hairL])

    // 8. Frost round her palm as she throws.
    if frost > 0 {
        for (dx, dy) in [(3, -2), (4, 1), (2, 3), (5, -1)] {
            c.px(41 + dx, 34 + dy, C(0xE8F8FF, frost * 0.8))
        }
    }

    // 9. The flurry: snowflakes wheeling round her, coming and going.
    if s > 0.05 && s < 0.95 {
        let fade = min(1, (s - 0.05) / 0.15, (0.95 - s) / 0.15)
        for i in 0..<12 {
            let a = Double(i) / 12 * 2 * .pi + s * 9
            let x = 28 + cos(a) * 17, y = 28 + sin(a) * 9 - Double(i % 3) * 2
            let ix = Int(x.rounded()), iy = Int(y.rounded())
            let front = sin(a) > 0
            let col = C(0xFFFFFF, fade * (front ? 0.95 : 0.55))
            if i % 3 == 0 {
                c.px(ix, iy, col); c.px(ix - 1, iy, col.alpha(0.6)); c.px(ix + 1, iy, col.alpha(0.6))
                c.px(ix, iy - 1, col.alpha(0.6)); c.px(ix, iy + 1, col.alpha(0.6))
            } else {
                c.px(ix, iy, col)
            }
        }
    }
}

// MARK: - Imani

/// Imani: Clawd with her face painted as a skull (white, black sockets round her eyes, a black nose and a row of
/// stitched teeth), black locs down her back, a black tunic, and the great orange wings of a monarch butterfly, veined
/// and bordered in black and dotted with white. She fights with a longsword. Signature: her wings beat and glow gold as
/// she buffs the party.
private func drawImani(_ c: PixelCanvas, _ p: Pose) {
    let wingO = C(0xF08A20), wingOD = C(0xC8601A), wingB = C(0x16121A), dot = C(0xFFFFFF)
    let paint = C(0xF2F0EC), paintD = C(0xC8C4C0), sock = C(0x16141A)
    let tunic = C(0x2A2630), tunicL = C(0x48424E), tunicD = C(0x1A181E)
    let locs = C(0x1E1A1C), locsL = C(0x3E3638)
    let steel = C(0xD8DCE4), steelD = C(0x9AA0AC), gold = C(0xD8B040), grip = C(0x4A2E1E)
    let s = p.signature ?? -1
    let buff = s > 0.06 && s < 0.94
    let glow = buff ? min(1, (s - 0.06) / 0.15, (0.94 - s) / 0.15) : 0
    let beat = buff ? sin(s * .pi * 10) : 0

    // 1. Legs in black leggings, darker boots.
    drawLegs(c, Look(leg: tunic), step: p.step)
    drawBoots(c, tunicD, step: p.step, rows: 2)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The wings: the upper and lower wing of a monarch, behind her, orange with black veins, a black border dotted
    //    with white; they beat in the signature, glowing gold.
    let up = beat * 4, sideways = beat * 2
    let o = glow * 0.55
    let fillO = lerp(wingO, C(0xFFD860), o), fillOD = lerp(wingOD, C(0xF0B030), o)
    func monarch(_ wa: Double, _ wb: Double, _ wd: Double) -> Px? {
        if wa < 0.17 {
            let r = wb / max(0.001, wb + wd)
            if wa > 0.05 && wa < 0.11 && Int(r * 16) % 2 == 0 { return dot }
            return wingB
        }
        if wb < 0.05 || wd < 0.05 { return wingB }
        let r = wb / (wb + wd)
        if abs(r - 0.34) < 0.035 || abs(r - 0.67) < 0.035 { return wingB }
        return wa > 0.7 ? fillOD : fillO
    }
    fillTriangle(c, (21, 29), (10 + sideways, 8 - up), (2, 23 + up / 2), monarch)
    fillTriangle(c, (20, 31), (3, 26 + up / 2), (9 - sideways, 38 - up / 2), monarch)

    // 4. The body, her black tunic over it, its neckline lit.
    drawBody(c, Look(arm: clawdOrange, eye: nil))
    c.rect(18, 34, 20, 4, tunic)
    c.rect(18, 34, 20, 1, tunicL); c.rect(37, 34, 1, 4, tunicD); c.rect(18, 37, 20, 1, tunicD)
    c.rect(15, 33, 3, 3, tunic); c.px(15, 33, tunicL)

    // 5. The skull paint: white over her face, black sockets with her eyes in them, a black nose, stitched teeth.
    c.pattern(20, 27, [
        "..WWWWWWWWWWWW..",
        ".WWWWWWWWWWWWWW.",
        ".WKKKKWWWWKKKKW.",
        ".WKgKKWWWWKgKKW.",
        ".WKKKKWWWWKKKKW.",
        "..WWWWWKKWWWWWd.",
        "...WKWKWKWKWd...",
    ], ["W": paint, "d": paintD, "K": sock, "g": C(0xF0E8A0)])

    // 6. Her locs: black, close over the top of her head and hanging down her back.
    c.pattern(16, 22, [
        "....LLL.L.LL.L.LL..",
        "..LllllllllllllllL.",
        ".llllLllllLllllllll",
        "llLll..............",
        "lll................",
        "lLl................",
        "lll................",
        "llL................",
        "l.l................",
        "l.l................",
    ], ["l": locs, "L": locsL])
    c.rect(18, 25, 19, 1, locs)   // no see-through row between her hair and her head

    // 7. The glow of the buff: gold motes rising round her.
    if glow > 0 {
        for i in 0..<6 {
            let k = (s * 3 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
            let x = 10 + (i * 7) % 30, y = 34 - Int(k * 18)
            c.px(x, y, C(0xFFE27A, glow * (1 - k)))
        }
    }

    // 8. The longsword: steel blade, a gold crossguard, a dark grip; held up at rest, or swung.
    let ang = p.melee ?? -72
    let hand = Sprite.hand
    for (i, t) in p.trail.enumerated() { crawlBar(c, hand, t, from: 3, to: 15, steel.alpha(0.3 / Double(i + 1)), r: 0.8) }
    crawlBar(c, hand, ang, from: -1.5, to: 2, grip, r: 0.6)
    crawlBar(c, hand, ang, from: 3, to: 15, steel, r: 0.8)
    crawlBar(c, hand, ang, from: 3, to: 14, steelD, r: 0.3)
    let gp = crawlReach(hand, ang, 2.5)
    crawlBar(c, gp, ang + 90, from: -2.2, to: 2.2, gold, r: 0.6)
    c.rect(39, 33, 3, 3, clawdOrange); c.px(39, 33, C(0xEE9474))
}

// MARK: - Brandon Andrews

/// Brandon Andrews: Clawd in a heavy quilted green winter jacket, its hood thrown back with a thick fur trim, short dark
/// hair, brown work trousers and heavy boots, and a huge hammer whose steel head glitters. Signature: he heaves the
/// hammer up off the ground and onto his shoulder, lightning crackling off its head.
private func drawBrandon(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0x2E7A68), coatD = C(0x1E5446), coatL = C(0x4AA08A)
    let fur = C(0xDCD4C2), furD = C(0xAEA492)
    let hair = C(0x3A2A1E), hairL = C(0x5A4430)
    let trousers = C(0x5E4C3A), trousersD = C(0x443626), boot = C(0x2A2420)
    let head = C(0xB4B8CC), headD = C(0x7A7E98), headL = C(0xEAEEFA), wood = C(0x6A4A2A)
    let s = p.signature ?? -1
    let heave = s > 0.06 && s < 0.94
    let crackle = s > 0.3 && s < 0.75

    // 1. Brown trousers, heavy boots.
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx + 1, 36, 1, footRow(i, p.step) - 37, trousersD) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The hood thrown back behind his head, its fur trim.
    c.pattern(13, 23, [
        "..FFFF.",
        ".FfFFFF",
        "FFCCCCF",
        "FCCCCCF",
        "FCCCCcF",
        "FFCCcCF",
        ".FFFFFF",
        "..FfFF.",
    ], ["F": fur, "f": furD, "C": coat, "c": coatD])

    // 4. The body, the puffy quilted jacket over it, a little wider than he is: lit on top and the left, a quilting seam
    //    every two rows, the zip up the front, a high collar.
    drawBody(c, Look(arm: coat, eye: nil))
    c.rect(17, 31, 22, 7, coat)
    c.rect(17, 31, 22, 1, coatL); c.rect(17, 31, 1, 7, coatL); c.rect(38, 31, 1, 7, coatD)
    for y in [33, 35] { c.rect(18, y, 20, 1, coatD) }
    c.rect(28, 31, 1, 7, C(0x9AA4A0))
    c.rect(14, 32, 4, 4, coat); c.px(14, 32, coatL); c.rect(14, 35, 4, 1, coatD)

    // 5. The face: Clawd's eyes, a heavy brow; short dark hair.
    c.rect(22, 28, 2, 3, ink); c.rect(32, 28, 2, 3, ink)
    c.rect(21, 27, 3, 1, hair); c.rect(31, 27, 4, 1, hair)
    c.pattern(17, 23, [
        "..hhHhhhHhhhhHhhhh..",
        ".hhhhhhhhhhhhhhhhhhh",
        "hhh.................",
    ], ["h": hair, "H": hairL])
    c.rect(18, 25, 19, 1, hair)

    // 6. The hammer: a huge glittering steel head on a wooden haft. At rest its head is on the ground in front of him;
    //    swung, or heaved up onto his shoulder in the signature.
    func glitter(_ x: Int, _ y: Int, _ i: Int) {
        if (Int(p.lt * 6) + i) % 4 == 0 { c.px(x, y, i % 2 == 0 ? C(0xFFFFFF) : C(0xF8C8F0)) }
    }
    var ang: Double? = p.melee
    if heave {
        let k = min(1, (s - 0.06) / 0.24), back = min(1, (0.94 - s) / 0.15)
        ang = 70 - 180 * sin(min(k, back) * .pi / 2)
    }
    if let a = ang {
        let hand = Sprite.hand
        for (i, t) in p.trail.enumerated() {
            let col = head.alpha(0.3 / Double(i + 1))
            angledBlock(c, hand, t, along: 8, 13.5, across: -4.5, 4.5, col, col, col)
        }
        crawlBar(c, hand, a, from: -2, to: 9, wood, r: 0.7)
        angledBlock(c, hand, a, along: 8, 13.5, across: -4.5, 4.5, head, headD, headL)
        let hc = crawlReach(hand, a, 10.8)
        for i in 0..<5 {
            let q = crawlReach(hc, a + 90, Double(i) * 2 - 4)
            glitter(Int(q.x.rounded()), Int(q.y.rounded()), i)
        }
        c.rect(39, 33, 3, 3, coat); c.px(39, 33, coatL)
        if crackle {
            let seed = Int(p.lt * 14)
            for b in 0..<3 {
                var x = hc.x, y = hc.y
                let dir = Double(b) * 120 + noise(seed + b) * 60
                for j in 0..<5 {
                    let d = crawlReach((x, y), dir + (noise(seed * 7 + b * 5 + j) - 0.5) * 80, 1.6)
                    c.px(Int(d.x.rounded()), Int(d.y.rounded()), j < 3 ? C(0xFFF6B0) : C(0x9AD0FF, 0.8))
                    x = d.x; y = d.y
                }
            }
        }
    } else {
        c.rect(43, 31, 2, 6, wood); c.px(43, 31, C(0x8A6A40))
        c.rect(39, 37, 10, 7, head)
        c.rect(39, 37, 10, 1, headL); c.rect(39, 37, 1, 7, headL); c.rect(48, 37, 1, 7, headD); c.rect(39, 43, 10, 1, headD)
        for (i, (x, y)) in [(41, 39), (46, 39), (44, 41), (41, 42), (47, 41)].enumerated() { glitter(x, y, i) }
        c.rect(39, 33, 4, 3, coat); c.px(39, 33, coatL)
    }
}

// MARK: - Chris Andrews

/// Chris Andrews: a giant of black volcanic rock, Clawd grown big and broad, thick-legged, a few red cracks of lava
/// glowing through him, a red crack of a mouth, glowing orange eyes, and a dented steel skullcap riveted on top. He
/// fights with his fists. Signature: the lava in his cracks flares bright yellow and fades again.
private func drawChris(_ c: PixelCanvas, _ p: Pose) {
    let rock = C(0x2A262E), rockD = C(0x18161C), rockL = C(0x46404C)
    let steel = C(0x8A929E), steelD = C(0x5A626E), steelL = C(0xC4CAD4)
    let s = p.signature ?? -1
    let flare = s > 0.05 && s < 0.95 ? sin((s - 0.05) / 0.9 * .pi) : 0
    let lava = lerp(C(0xC8281E), C(0xFFD860), flare), lavaL = lerp(C(0xFF6A2A), C(0xFFFCE0), flare)
    let eye = lerp(C(0xFF9A2A), C(0xFFF4B0), flare)

    // 1. Thick rock legs, a crack glowing in each.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 5, 2, rock); c.px(lx + 1, 38, lava) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, 36, 3, b - 35, rock)
            c.rect(lx + 2, 36, 1, b - 35, rockD); c.rect(lx, b, 3, 1, rockD)
            c.px(lx + 1, 39 + i % 2, lava)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, then the body: big, broad and craggy, lit on top and the left, a few chips in its edges.
    c.rect(11, 30, 4, 5, rock); c.rect(11, 30, 4, 1, rockL); c.rect(11, 34, 4, 1, rockD)
    c.rect(15, 18, 27, 20, rock)
    c.rect(15, 18, 27, 1, rockL); c.rect(15, 18, 1, 20, rockL)
    c.rect(41, 18, 1, 20, rockD); c.rect(15, 37, 27, 1, rockD)
    c.px(15, 18, C(0, 0)); c.px(41, 18, C(0, 0))
    for (x, y) in [(20, 25), (33, 33), (24, 35)] { c.rect(x, y, 2, 1, rockL) }

    // 4. The lava cracks, a few, glowing; and the mouth, a red crack.
    let cracks: [[(Int, Int)]] = [
        [(17, 21), (20, 25), (18, 29), (21, 33)],
        [(28, 31), (31, 34), (29, 37)],
        [(38, 30), (40, 33), (38, 36)],
    ]
    for crack in cracks {
        for j in 1..<crack.count { pixelLine(c, crack[j - 1], crack[j], lava) }
        c.px(crack[1].0, crack[1].1, lavaL)
    }
    c.pattern(31, 27, ["LLLLLLL.", ".llllllL"], ["L": lava, "l": lavaL])

    // 5. The eyes: glowing orange under a heavy brow of rock.
    c.rect(23, 21, 4, 1, rockL); c.rect(34, 21, 4, 1, rockL)
    c.rect(24, 22, 3, 2, eye); c.rect(35, 22, 3, 2, eye)

    // 6. The steel skullcap: a dented dome riveted on top, lit along its crown.
    c.pattern(17, 13, [
        "......SSSSSSSSSS......",
        "...SSLLLLLLSSSSSSSS...",
        "..SSSSSSSSSSSSSSSdSS..",
        ".SSSSSSSSSSSSSSSSSSSd.",
        "dDDrDDDDDrDDDDDrDDDDdD",
    ], ["S": steel, "L": steelL, "d": steelD, "D": steelD, "r": steelL])

    // 7. The near fist: a big lump of rock with a glowing seam, swung out, or at his side.
    func fist(_ x: Int, _ y: Int, _ al: Double) {
        c.rect(x - 1, y - 1, 4, 4, rock.alpha(al)); c.rect(x - 1, y - 1, 4, 1, rockL.alpha(al))
        c.rect(x - 1, y + 2, 4, 1, rockD.alpha(al)); c.px(x + 1, y, lava.alpha(al))
    }
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: rock, reach: 7, fist: fist)
    } else {
        c.rect(42, 30, 4, 6, rock); c.rect(42, 30, 4, 1, rockL); c.rect(45, 30, 1, 6, rockD); c.px(43, 33, lava)
    }
}

// MARK: - Bautista

/// Bautista: a tiger-man, Clawd in orange fur with black stripes, shirtless, a white muzzle with a pink nose, round ears,
/// a shaggy ringed tail hanging behind him, baggy khaki trousers and bare clawed feet. He fights with a curved sword
/// whose blade glows orange. Signature: he conjures a little blue plushie bear, which waddles about in front of him and
/// vanishes in a puff.
private func drawBautista(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xE8892A), furD = C(0xB8641A), furL = C(0xF8AC50), stripe = C(0x1E1614)
    let white = C(0xF4EEE2), whiteD = C(0xD0C8B8), nose = C(0xE07A8A)
    let khaki = C(0x8A7A56), khakiD = C(0x64583C), claw = C(0xF8F4E8)
    let hot = C(0xFF8A24), hotL = C(0xFFE8A8), glow = C(0xFF6A1A, 0.3)
    let plush = C(0x8AB4E8), plushD = C(0x5A84C0), plushL = C(0xB8D4F8)
    let s = p.signature ?? -1
    let summon = s > 0.06 && s < 0.24
    let sheathed = s > 0.06 && s < 0.94

    // 1. Baggy khaki trousers to the shin, bare orange feet with white claws over the front.
    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, 36, 2, b - 38, khaki); c.rect(lx + 1, 36, 1, b - 38, khakiD)
            c.px(lx - 1, b - 3, khaki)   // the baggy cuff
            c.px(lx, b - 1, stripe)
            c.px(lx + 2, b, claw)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail: shaggy, ringed in black, hanging behind him and curling up at its tip.
    let flick = sin(p.lt * 1.6) > 0.3 ? -1 : 0
    c.pattern(8 + flick, 26, [
        ".k.",
        "kkk",
        ".kk",
    ], ["k": stripe])
    c.pattern(8, 29, [
        ".OO.......",
        ".OO.......",
        ".kk.......",
        ".OO.......",
        ".OOO....OO",
        "..OOk..OOO",
        "...OOOOkO.",
        "....OOOO..",
    ], ["O": fur, "k": stripe])

    // 4. The body in orange fur, a few black stripes down his sides, his white chest; the trousers' waist.
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil), armRight: summon ? 4 : 0)
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 8, furL)
    for (x, y) in [(19, 28), (21, 31), (35, 28), (34, 31)] {
        c.pattern(x, y, ["s.", "ss", ".s"], ["s": stripe])
    }
    c.pattern(15, 33, ["s..", ".s."], ["s": stripe])   // the far arm
    c.rect(24, 33, 9, 3, white); c.rect(24, 35, 9, 1, whiteD); c.rect(25, 32, 7, 1, white)
    c.rect(18, 36, 20, 2, khaki); c.rect(18, 37, 20, 1, khakiD); c.rect(18, 36, 20, 1, C(0x4A3E28))

    // 5. The head: round ears, black stripes on his brow, eyes, the white muzzle with its pink nose.
    c.pattern(19, 23, ["ff.", "fwf", "fff"], ["f": fur, "w": white])
    c.pattern(32, 23, [".ff", "fwf", "fff"], ["f": fur, "w": white])
    c.px(19, 23, stripe); c.px(34, 23, stripe)
    for x in [26, 28, 30] { c.rect(x, 26, 1, x == 28 ? 3 : 2, stripe) }
    c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink)
    c.px(22, 28, C(0xF0D040)); c.px(32, 28, C(0xF0D040))
    c.pattern(24, 30, [
        "WWWNNWWW",
        "WWkWWkWW",
        ".WWWWWW.",
    ], ["W": white, "N": nose, "k": stripe])
    c.px(23, 31, stripe); c.px(32, 31, stripe)   // whisker spots

    // 6. The sword: a curved blade glowing orange-hot, a dark hilt; held up at rest, or swung. Put away while his
    //    plushie is out, the near hand up with a twinkle as he conjures it.
    if !sheathed {
        let ang = p.melee ?? -60
        let hand = Sprite.hand
        func blade(_ a: Double, _ col: Px, _ g: Px, _ r: Double) {
            var prev = crawlReach(hand, a, 2.5)
            for i in 1...6 {
                let l = 2.5 + Double(i) * 1.9
                let bend = -15 * pow(Double(i) / 6, 2)
                let q = crawlReach(hand, a + bend, l)
                c.glowLine(prev.x, prev.y, q.x, q.y, core: col, glow: g, coreR: r, glowR: r + 1.4)
                prev = q
            }
        }
        for (i, t) in p.trail.enumerated() { blade(t, hot.alpha(0.3 / Double(i + 1)), C(0, 0), 0.7) }
        blade(ang, hot, glow, 0.95)
        blade(ang, hotL, C(0, 0), 0.45)
        crawlBar(c, hand, ang, from: -1.5, to: 2.2, C(0x2A1E16), r: 0.6)
        let gp = crawlReach(hand, ang, 2.4)
        crawlBar(c, gp, ang + 90, from: -1.6, to: 1.6, C(0xC8A040), r: 0.5)
        c.rect(39, 33, 3, 3, fur); c.px(39, 33, furL)
    } else if summon {
        let k = (s - 0.06) / 0.18
        for i in 0..<4 {
            let a = Double(i) * 90 + k * 200
            let q = crawlReach((44, 26), a, 2 + k * 2)
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), C(0xBFE0FF, 0.9))
        }
    }

    // 7. The plushie: a little blue bear that pops in with a puff, waddles about in front of him, and pops away.
    if s > 0.18 && s < 0.9 {
        let k = (s - 0.18) / 0.72
        let x = 45 + Int((sin(k * .pi * 2) * 5).rounded())
        let waddle = Int(p.lt * 6) % 2
        let y = 36 - (waddle == 0 ? 0 : 0)
        if k > 0.06 && k < 0.92 {
            c.pattern(x, y + waddle, ["b....b", "BBBBBB"], ["b": plushD, "B": plush])
            c.pattern(x, y + 2, [
                "BkBBkB",
                "BBnLBB",
                ".BBBB.",
                "BBLLBB",
                "BBBBBB",
            ], ["B": plush, "k": ink, "n": C(0x2A3A5A), "L": plushL])
            c.pattern(x, y + 7, waddle == 0 ? [".b..b."] : ["b...b."], ["b": plushD])
        }
        for edge in [0.0, 0.92] where k > edge && k < edge + 0.08 {
            let r = (k - edge) / 0.08
            for i in 0..<6 {
                let q = crawlReach((Double(x) + 3, Double(y) + 4), Double(i) * 60, 2 + r * 3)
                c.px(Int(q.x.rounded()), Int(q.y.rounded()), C(0xFFFFFF, 0.8 * (1 - r * 0.5)))
            }
        }
    }
}
