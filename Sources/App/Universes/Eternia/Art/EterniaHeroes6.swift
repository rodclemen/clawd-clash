import Foundation

// Heroes: more of She-Clawd's Great Rebellion, the queens and princesses of Etheria and the one pirate among them,
// drawn the same way as EterniaHeroes1.swift and EterniaHeroes4.swift. Gowns and robes stop short of the ground so
// Clawd's four legs always show under them; Mermista's tail is her legs while she's on land.

let eterniaHeroes6: [EterniaHero: Persona] = [
    .queenAngella: Persona(name: "Queen Angella", weapon: .lightning, motion: .fly,
                           magic: Magic(core: C(0xFFFFFF), glow: C(0xF0C040), jagged: false, rings: true),
                           pivot: h6WingTip, headTop: 12, signature: 3.4, draw: drawQueenAngella),
    .clawdstaspella: Persona(name: "Clawdstaspella", weapon: .lightning,
                             magic: Magic(core: C(0xECDCFF), glow: C(0x8C48E0), jagged: false, rings: true),
                             headTop: 15, signature: 3.6, draw: drawClawdstaspella),
    .frosta: Persona(name: "Frosta", weapon: .blaster, shot: .ice, muzzle: (44, 33.5), handGun: false, headTop: 12,
                     signature: 4.0, draw: drawFrosta),
    .seaHawk: Persona(name: "Sea Hawk", weapon: .saber, headTop: 20, signature: 3.8, draw: drawSeaHawk),
    .mermista: Persona(name: "Mermista", weapon: .lightning,
                       magic: Magic(core: C(0xC8FFF6), glow: C(0x2A8AE8), jagged: false, waves: true),
                       headTop: 14, signature: 3.4, draw: drawMermista),
    .perfuma: Persona(name: "Perfuma", weapon: .blaster, shot: .thrown(C(0xFF6AB4)), muzzle: (43, 31), handGun: false,
                      headTop: 18, signature: 3.6, draw: drawPerfuma),
]

// MARK: - Shared bits

private let h6None = C(0, 0)
/// Where Queen Angella's near wing-tip points while she casts: her rings leave from it.
private let h6WingTip = (x: 48.0, y: 21.0)

/// Draws `art` (in sprite coordinates, no offsets) on a scratch canvas, turns it `degrees` about `pivot` (positive:
/// clockwise) and lays it on `c` with its offsets.
private func h6Turned(_ c: PixelCanvas, _ degrees: Double, about pivot: (x: Double, y: Double), _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    if abs(degrees) < 0.5 { c.paste(s); return }
    c.paste(s.rotated(degrees, about: pivot, into: c.w, c.h, at: pivot))
}

/// Draws `art` on a scratch canvas and lays it on `c` squeezed sideways to `k` of its width about column `ax`
/// (negative: mirrored, so she faces the other way), `shift` pixels along: a body seen turning on the spot.
private func h6Spun(_ c: PixelCanvas, _ k: Double, about ax: Double = 28, shift: Int = 0, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    if abs(k - 1) < 0.01 { c.paste(s, x: shift); return }
    let kk = abs(k) < 0.15 ? (k < 0 ? -0.15 : 0.15) : k
    let out = PixelCanvas(c.w, c.h)
    for y in 0..<s.h {
        for x in 0..<s.w {
            let src = ax + (Double(x) + 0.5 - ax) / kk
            let sx = Int(floor(src))
            guard sx >= 0, sx < s.w, s.isDrawn(sx, y) else { continue }
            out.px(x, y, unpremultiplied(s, (y * s.w + sx) * 4))
        }
    }
    c.paste(out, x: shift)
}

/// A feathered wing from `root`: six feathers hanging at `feathers` degrees from points along a leading edge at
/// `edge` degrees, `length` long; a shaded line under each feather so they read apart, and their ends in `tip`.
private func h6Wing(_ c: PixelCanvas, root: (x: Double, y: Double), edge a: Double, feathers f: Double, length: Double,
                    main: Px, shade: Px, tip: Px) {
    for i in (1...6).reversed() {
        let k = Double(i) / 6
        let p0 = eterniaReach(root, a, length * k)
        let l = 3 + 5 * k
        let p1 = eterniaReach(p0, f, l)
        let p2 = eterniaReach(p0, f, l - 2)
        c.glowLine(p0.x, p0.y + 1, p1.x, p1.y + 1, core: shade, glow: h6None, coreR: 0.6, glowR: 0.65)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: main, glow: h6None, coreR: 0.8, glowR: 0.85)
        c.glowLine(p2.x, p2.y, p1.x, p1.y, core: tip, glow: h6None, coreR: 0.7, glowR: 0.75)
    }
    // The leading edge, thick and lit, a shaded line along its underside so it stands off the feathers.
    let e = eterniaReach(root, a, length)
    c.glowLine(root.x, root.y + 1, e.x, e.y + 1, core: shade, glow: h6None, coreR: 0.8, glowR: 0.85)
    c.glowLine(root.x, root.y, e.x, e.y, core: main, glow: h6None, coreR: 1.1, glowR: 1.15)
}

/// A great folded wing, drawn feather by feather: its lit leading edge arching up from the shoulder at the right, the
/// long feathers sweeping down and back to tips in `tip` at the lower left, a shaded line between each.
private func h6AngelWing(_ c: PixelCanvas, x: Int, y: Int, main: Px, shade: Px, edge: Px, tip: Px) {
    c.pattern(x, y, [
        "..........EE....",
        "........EEWWE...",
        "......EEWWWWE...",
        ".....EWWWWWWWE..",
        "....EWWsWWWWWE..",
        "...EWWsWWsWWWWE.",
        "..EWWsWWsWWsWWE.",
        "..WWsWWsWWsWWWWE",
        ".WWsWWsWWsWWsWWE",
        ".WsWWsWWsWWsWWWW",
        "TWWWsWWsWWsWWWWW",
        ".TWsWWsWWsWWsWWW",
        "TTWWWsWWsWWsWWWW",
        "..TWsWWsWWsWWWWW",
        ".TTTWWsWWsWWWWWW",
        "...TTWsWWsWWWWW.",
        "..TTTWWWsWWWWW..",
        "....TTWWWWWW....",
        "...TTTTWWWW.....",
        "......TTWW......",
    ], ["W": main, "s": shade, "E": edge, "T": tip])
}

/// The bottom of leg `i` this frame (the lifted pair a row higher while walking).
private func h6Foot(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

/// A four-petal blossom centred on (`x`, `y`): `petal` round a `heart`, a lit petal on top.
private func h6Blossom(_ c: PixelCanvas, _ x: Int, _ y: Int, petal: Px, lit: Px, heart: Px) {
    c.pattern(x - 2, y - 2, [".LP.", "PHHP", "PHHP", ".PP."], ["P": petal, "L": lit, "H": heart])
}

// MARK: - Queen Angella

/// Queen Angella: Bright Moon's queen and Glimmer's mother. Long blue-black hair falling straight past her shoulders,
/// a tall gold crown of three spires set with pink gems, a lilac gown with a purple hem and a gold belt, gold cuffs,
/// and two great white wings, gold at the feather-tips, folded up behind her back. She flies. Her magic is golden
/// rings from the tip of her near wing, which sweeps forward while she casts. Signature: she opens her wings wide, a
/// twinkle at each tip, and folds them again.
private func drawQueenAngella(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0xB89AE0), gownD = C(0x8A6AB8), gownL = C(0xD8C6F6), hem = C(0x6A4AA0)
    let hair = C(0x2E2A4C), hairD = C(0x1A1832), hairL = C(0x4E4878)
    let gold = C(0xF0C040), goldD = C(0xB08420), goldL = C(0xFFE88A), gem = C(0xF070B8)
    let wht = C(0xFAFAFF), whtD = C(0xA8A4C4), tip = C(0xF0D070)
    let s = p.signature ?? -1
    var spread = s < 0 ? 0 : habitArc(s, hold: 0.45)
    if p.flying { spread = 0.5 + 0.5 * sin(p.t * 9) }
    let casting = p.zap != nil

    // The two wings behind her, one swept higher than the other so both show: folded up her back at rest, opened
    // wide and back.
    let w = spread
    h6Turned(c, 12 * w, about: (23, 26)) {
        h6AngelWing($0, x: 9, y: 8, main: C(0xDCDCEA), shade: C(0x8E8AAA), edge: C(0x9C98B8), tip: C(0xD0B060))
    }
    h6Turned(c, -12 - 34 * w, about: (19, 27)) {
        h6AngelWing($0, x: 5, y: 10, main: wht, shade: whtD, edge: C(0xB4B0CC), tip: tip)
    }
    // Her hair down her back, in strands.
    for (i, x) in [15, 16, 17].enumerated() { c.rect(x, 27, 1, 11 - i % 2, i % 2 == 0 ? hair : hairD) }

    // Bare legs under the gown, lilac slippers.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, gownD, step: p.step, rows: 2)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, h6Foot(i, p.step) - 1, gownL) } }

    c.oy += p.breathe
    drawBody(c, Look(arm: gown))
    // The gown: a lit neckline, the far side shaded, folds; the gold belt and its gem; the skirt flaring to a
    // purple hem just above her slippers.
    c.rect(18, 32, 20, 4, gown); c.rect(18, 32, 20, 1, gownL); c.rect(37, 32, 1, 4, gownD)
    c.rect(21, 33, 1, 3, gownD); c.rect(34, 33, 1, 3, gownD)
    c.rect(18, 36, 20, 1, gold); c.rect(18, 36, 6, 1, goldL); c.rect(27, 36, 2, 1, gem)
    for y in 37...40 where y + c.oy <= 42 {
        let f = (y - 37) / 2
        c.rect(18 - f, y, 20 + 2 * f, 1, y == 40 ? hem : gown)
        if y < 40 { for x in [21, 25, 30, 34] { c.px(x, y, gownD) } }
        c.px(18 - f, y, y == 40 ? hem : gownL); c.px(37 + f, y, y == 40 ? hem : gownD)
    }
    c.rect(15, 35, 3, 1, gold); c.rect(38, 35, 3, 1, gold); c.px(38, 35, goldL)   // the cuffs

    // The hair: a centre parting, straight down either side of her face to her shoulders.
    c.pattern(15, 20, [
        "....HHHHHHHHHHHHHHHH....",
        "..HHHHHlHHHHHHlHHHHHHH..",
        ".HHHlHHHHHhHHHHHHHhHHHH.",
        ".HHhHHHHHhHHHHHHHHHhHHH.",
        "HHhHHHHhhHHHHHHHHhhHHhHH",
        "HHhHHhHhhhHhhhHhhHhHHhHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hhH",
        "HhH..................hH.",
        "Hh....................h.",
        ".h......................",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The crown: a gold band across her brow set with gems, three tall spires, the middle one tallest.
    c.pattern(20, 11, [
        ".......LL.......",
        ".......GL.......",
        ".......GG.......",
        "..L....GG....L..",
        "..GL..gGGg..LG..",
        "..GG..GJJG..GG..",
        "..GGg.GJJG.gGG..",
        "..GGGgGGGGgGGG..",
        "..GGGGGGGGGGGG..",
        ".gGLLLLLLLLLLGg.",
        ".gGGjGGGGGGjGGg.",
    ], ["G": gold, "g": goldD, "L": goldL, "J": gem, "j": C(0xB84A8A)])

    // The near wing: swept forward while she casts, its tip where the rings leave from.
    if casting {
        let tipAt = (x: h6WingTip.x, y: h6WingTip.y - Double(p.armRaise))
        let root = (x: 35.0, y: 28.0)
        let a = atan2(tipAt.y - root.y, tipAt.x - root.x) * 180 / .pi
        let len = hypot(tipAt.x - root.x, tipAt.y - root.y)
        h6Wing(c, root: root, edge: a, feathers: a + 115, length: len, main: wht, shade: whtD, tip: tip)
    }
    if s > 0.3 && s < 0.7 {
        // A twinkle at each wing-tip while they're open.
        let tw = 0.5 + 0.5 * sin(p.t * 14)
        for (x, y) in [(5.0, 18.0), (23.0, 8.0)] {
            c.glowLine(x, y, x, y, core: C(0xFFFFFF, 0.95 * tw), glow: C(0xFFD040, 0.8 * tw), coreR: 0.6, glowR: 2.2)
        }
    }
}

// MARK: - Clawdstaspella

/// Clawdstaspella: the sorceress-queen of Mystacor. Long copper-brown hair, a thin gold circlet with a violet gem, and
/// her great stiff collar, lilac and ridged, standing up behind her head in a fan of points. A long violet robe with a
/// magenta sash and hem, wide lilac cuffs. Her magic is hypnotic lilac rings with a violet glow. Signature: the
/// hypno-spin: she twirls on the spot twice, rings of lilac light rising round her as she turns.
private func drawClawdstaspella(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let spinning = s > 0.06 && s < 0.9
    let u = spinning ? (s - 0.06) / 0.84 : 0
    let e = u * u * (3 - 2 * u)
    let k = spinning ? cos(e * 4 * .pi) : 1
    h6Spun(c, k) { c in clawdstaspellaBody(c, p, back: k < 0) }
    guard spinning else { return }
    // The hypnotic rings, rising round her as she spins and fading as they go.
    for j in 0..<3 {
        let f = frac(u * 3 + Double(j) / 3)
        let rx = 9 + f * 12, ry = 2 + f * 2.5, cy = 41 - f * 18
        let a = (1 - f) * 0.9 * min(1, u * 8) * min(1, (1 - u) * 8)
        for n in 0..<56 {
            let t = Double(n) / 56 * 2 * .pi
            let x = Int((28 + cos(t) * rx).rounded()), y = Int((cy + sin(t) * ry).rounded())
            c.px(x, y, (n % 2 == 0 ? C(0xF0E4FF) : C(0xA868F0)).alpha(a))
        }
    }
}

private func clawdstaspellaBody(_ c: PixelCanvas, _ p: Pose, back: Bool) {
    let robe = C(0x5E2E9E), robeD = C(0x40206E), robeL = C(0x7E4ABE)
    let collar = C(0xD4BCF6), collarD = C(0xA486DE), rim = C(0x6A38B8)
    let sash = C(0xE04AA8), sashL = C(0xFF80C8)
    let hair = C(0x9A5228), hairD = C(0x683418), hairL = C(0xC07440)
    let gold = C(0xF0C040), goldL = C(0xFFE88A)
    let raise = p.armRaise

    // The stiff collar, a fan of ridged points standing up behind her head from shoulder to shoulder.
    let n = 13
    for i in 0..<n {
        let a = -168 + 156 * Double(i) / Double(n - 1)
        let r = i % 2 == 0 ? 15.5 : 13.0
        eterniaBar(c, (28, 31), a, from: 4, to: r, i % 2 == 0 ? collar : collarD, r: 1.5)
    }
    for i in stride(from: 0, to: n, by: 2) {
        let a = -168 + 156 * Double(i) / Double(n - 1)
        eterniaBar(c, (28, 31), a, from: 14, to: 15.6, rim, r: 0.8)
    }
    // Her hair down her back, in strands.
    for (i, x) in [15, 16, 17].enumerated() { c.rect(x, 27, 1, 12 - i % 2, i % 2 == 0 ? hair : hairD) }

    drawLegs(c, Look(), step: p.step)
    drawBoots(c, robeD, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe, eye: back ? nil : ink), armRight: raise)
    // The robe: violet, lit along the shoulders, the far side shaded, a gold brooch; the magenta sash; the
    // long skirt to just above her slippers, in folds, a magenta hem.
    c.rect(18, 32, 20, 4, robe); c.rect(18, 32, 20, 1, robeL); c.rect(37, 32, 1, 4, robeD)
    c.rect(26, 34, 3, 2, C(0xF0C040)); c.px(27, 34, C(0x9A50F0))   // a gold brooch with a violet stone
    c.rect(18, 36, 20, 1, sash); c.rect(18, 36, 5, 1, sashL)
    for y in 37...40 where y + c.oy <= 42 {
        let f = (y - 37) / 2
        c.rect(18 - f, y, 20 + 2 * f, 1, y == 40 ? sash : robe)
        if y < 40 { for x in [21, 26, 31, 35] { c.px(x, y, robeD) } }
        c.px(18 - f, y, y == 40 ? sash : robeL)
    }
    // Wide lilac cuffs.
    c.rect(14, 35, 4, 1, collar); c.rect(38, 35 - raise, 4, 1, collar); c.px(41, 35 - raise, collarD)

    // The hair: long and full, a soft wave at either side, down past her shoulders.
    c.pattern(15, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHlHHHHHHlHHHHH....",
        "..HHHlHHHhHHHHHHhHHHHH..",
        ".HHhHHHHhHHHHHHHHhHHHHH.",
        ".HHhHHHhhHHHHHHHhhHHhHH.",
        "HHhHHhHhhHhhhHhhHHhHhhHH",
        "HHh..................hHH",
        "HHHh................hHHH",
        "HHh..................hHH",
        ".HHh................hHH.",
        "HHh..................hHH",
        "HhH..................Hh.",
        ".hH...................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    if back {
        // Turned away: the back of her head is all hair.
        c.rect(18, 25, 20, 8, hair)
        for x in stride(from: 19, to: 37, by: 3) { c.rect(x, 26, 1, 6, hairD) }
    }
    // The circlet: a thin gold band across her brow, a point at its middle with a violet gem.
    c.rect(18, 24, 20, 1, gold); c.rect(18, 24, 6, 1, goldL)
    c.pattern(26, 21, [".GG.", "GVVG", "GVVG"], ["G": gold, "V": C(0x9A50F0)])
    c.px(27, 22, C(0xE0C4FF))
}

// MARK: - Frosta

/// Frosta: the ice princess of Snows. Long white hair, shaded blue-grey in strands, a crown of ice-blue icicles
/// standing up from her brow, a white bodice with an ice-blue snowflake brooch, an ice-blue skirt with a hem of white
/// icicles, white boots and pale blue stockings. She blasts ice from her hands. Signature: she freezes the floor round
/// her and skates a little circle on it, out, round and back, her blades scratching white lines.
private func drawFrosta(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let freeze = s < 0 ? 0 : min(1, s / 0.15) * (s > 0.9 ? max(0, (1 - s) / 0.1) : 1)
    let skating = s > 0.18 && s < 0.88
    let u = skating ? (s - 0.18) / 0.7 : 0
    let glide = skating ? sin(u * 2 * .pi) * 7 : 0
    var k = skating ? cos(u * 2 * .pi) : 1
    if abs(k) < 0.3 { k = k < 0 ? -0.3 : 0.3 }
    if freeze > 0 {
        // The frozen floor: a sheet of ice spreading from her feet, lit along the top, glints in it.
        let half = Int(4 + 18 * freeze)
        c.rect(28 - half, 44, 2 * half, 1, C(0xC8F0FF, 0.95))
        c.rect(29 - half, 45, 2 * half - 2, 1, C(0x5AB0E8, 0.85))
        for x in stride(from: 30 - half, to: 26 + half, by: 7) { c.rect(x, 44, 2, 1, C(0xFFFFFF)) }
        if skating {
            // The lines her blades scratch.
            let reach = Int(abs(glide).rounded())
            c.rect(min(20, 20 + Int(glide)), 45, reach + 16, 1, C(0xE8FAFF, 0.9))
        }
    }
    h6Spun(c, k, shift: Int(glide.rounded())) { c in frostaBody(c, p, skating: skating) }
}

private func frostaBody(_ c: PixelCanvas, _ p: Pose, skating: Bool) {
    let wht = C(0xF4F8FC), whtD = C(0xBCC8DA), whtL = C(0xFFFFFF)
    let ice = C(0x7CC8F4), iceD = C(0x3E8ACC), iceL = C(0xCCF0FF)
    let hair = C(0xEEF2FA), hairD = C(0xA4B2CC), hairL = C(0xFFFFFF)
    let step = skating ? -1 : p.step
    // Firing: the near hand thrust out, frost round it.
    var thrust = 0
    var frost = 0.0
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        thrust = ph < 0.3 ? 1 : 0
        frost = ph < 0.3 ? 1 - ph / 0.3 : ph > 0.85 ? (ph - 0.85) / 0.15 : 0
    }
    if p.ready { frost = max(frost, 0.45 + 0.15 * sin(p.t * 6)) }

    // Her hair down her back.
    for (i, x) in [15, 16, 17].enumerated() { c.rect(x, 27, 1, 11 - i % 2, i % 2 == 0 ? hair : hairD) }
    drawLegs(c, Look(leg: C(0xA8D8F4)), step: step)
    drawBoots(c, wht, step: step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = h6Foot(i, step)
            c.rect(lx, b - 2, 2, 1, ice); c.px(lx + 1, b, whtD)
            if skating { c.rect(lx - 1, 44, 4, 1, C(0xD8DCE6)) }   // the skate blades
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: wht))
    // The white bodice, a fold, the far side shaded; the snowflake brooch; the ice-blue skirt with its icicle hem.
    c.rect(18, 32, 20, 4, wht); c.rect(18, 32, 20, 1, whtL); c.rect(37, 32, 1, 4, whtD)
    c.rect(21, 33, 1, 3, whtD); c.rect(34, 33, 1, 3, whtD)
    c.pattern(26, 33, ["S.S", ".I.", "S.S"], ["S": iceD, "I": iceL]); c.px(27, 33, iceD); c.px(27, 35, iceD)
    c.rect(18, 36, 20, 1, iceD)
    for y in 37...39 where y + c.oy <= 42 {
        let f = (y - 37) / 2
        c.rect(18 - f, y, 20 + 2 * f, 1, ice)
        c.px(18 - f, y, iceL); c.px(37 + f, y, iceD)
        if y == 38 { for x in [22, 27, 32] { c.px(x, y, iceD) } }
    }
    if 40 + c.oy <= 42 {
        // The icicles hanging off the hem, white, long and short.
        for x in stride(from: 17, through: 37, by: 2) {
            c.px(x, 40, (x / 2) % 2 == 0 ? whtL : iceL)
            if (x / 2) % 2 == 0 && 41 + c.oy <= 42 { c.px(x, 41, whtD) }
        }
    }
    c.rect(15, 35, 3, 1, ice); c.rect(38, 35, 3, 1, ice)   // the cuffs

    // The hair: white, straight and long, a short fringe, shaded in blue-grey strands.
    c.pattern(15, 20, [
        ".....HHHHHHHHHHHHH......",
        "...HHHHlHHHHHHlHHHHH....",
        "..HHHhHHHHhHHHHHhHHHHH..",
        ".HHhHHHHhHHHHhHHHHhHHHH.",
        ".HHhHHHhHHHhHHHhHHHhHHH.",
        "HHhHhhHhhhHhhhHhhHhhhHHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HhH..................hHH",
        "Hh...................hH.",
        ".h....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The icicle crown: a band of ice across her brow, icicles standing up from it, the middle one tallest, each lit
    // down one side.
    c.pattern(17, 11, [
        "...........L..........",
        "...........I..........",
        "..........LIi.........",
        "......L...LIi...L.....",
        "......I...IIi...I.....",
        "..L..LIi.LIIIi.LIi..L.",
        "..I..LIi.LIIIi.LIi..I.",
        ".LIi.IIIiIIIIIiIIIi.Ii",
        ".LIIiIIIIIIIIIIIIIiLIi",
        "..DDDDDDDDDDDDDDDDDDD.",
    ], ["I": ice, "i": iceD, "L": iceL, "D": iceD])

    // The near hand, thrust out to fire, and the frost gathering round it.
    if thrust > 0 { c.rect(41, 33, 2, 3, wht); c.rect(41, 35, 2, 1, ice) }
    if frost > 0.02 {
        let hx = 42.0 + Double(thrust), hy = 34.0
        c.glowLine(hx, hy, hx, hy, core: C(0xFFFFFF, 0.9 * frost), glow: C(0x7CD0FF, 0.75 * frost), coreR: 0.8, glowR: 2.6)
        for i in 0..<3 {
            let a = p.t * 4 + Double(i) * 2.1
            c.px(Int((hx + cos(a) * 3.5).rounded()), Int((hy + sin(a) * 3).rounded()), C(0xE8FAFF, frost))
        }
    }
}

// MARK: - Sea Hawk

/// Sea Hawk: the Rebellion's pirate captain. A red bandana tied tight over his dark-brown hair, its knot and tails
/// fluttering behind, an open brown leather waistcoat over his bare chest, white shirt-sleeves, a black belt with a gold
/// buckle, buff breeches and tall black boots with turned-down cuffs. His cutlass is curved, with a brass basket hilt.
/// Signature: he swings in on a rope, back and forth, lets go and lands.
private func drawSeaHawk(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let swinging = s >= 0 && s < 0.86
    var theta = 0.0, lift = 0
    if swinging {
        if s < 0.1 {
            let f = s / 0.1
            theta = 16 * f * f * (3 - 2 * f); lift = Int((6 * f).rounded())
        } else {
            let v = (s - 0.1) / 0.76
            theta = 16 * cos(.pi * 2.5 * v) * (1 - 0.6 * v); lift = 6
        }
    } else if s >= 0.86 && s < 0.94 {
        lift = Int((6 * (1 - (s - 0.86) / 0.08)).rounded())
    }
    if s >= 0.86 {
        // The rope he let go of, swinging back up out of reach and fading.
        let f = (s - 0.86) / 0.14
        let end = eterniaReach((39.5, 3), 90 + 30 * f, 14 - 4 * f)
        c.glowLine(39.5, 3, end.x, end.y, core: C(0xC8A060, 1 - f), glow: h6None, coreR: 0.6, glowR: 0.65)
    }
    if !swinging && lift == 0 {
        seaHawkBody(c, p, lift: 0, rope: false)
        return
    }
    let l = lift
    h6Turned(c, theta, about: (39.5, 3)) { k in seaHawkBody(k, p, lift: l, rope: swinging) }
}

private func seaHawkBody(_ c: PixelCanvas, _ p: Pose, lift: Int, rope: Bool) {
    let red = C(0xD83030), redD = C(0x9A1E1E), redL = C(0xF05E4E)
    let hair = C(0x4A2C1A), hairD = C(0x2E1A10)
    let shirt = C(0xF2EEE6), shirtD = C(0xC4BEB4)
    let vest = C(0x7A4A28), vestD = C(0x52301A), vestL = C(0x9A6438)
    let boot = C(0x26222C), cuff = C(0x6A5038), breeches = C(0xC8A878), breechesD = C(0x9A8058)
    let gold = C(0xE8B840)
    let airborne = lift > 0
    let step = airborne ? -1 : p.step
    let raise = rope ? 10 : 0
    c.oy -= lift

    // The bandana's knot and its two tails, fluttering out behind his head.
    let flap = Int((sin(p.t * 7) * 1).rounded())
    c.pattern(10, 23, [
        "......RR",
        "..RRRRRr",
        "RRrrRR.r",
        ".....RRr",
        "...RRRr.",
        "RRRrr...",
    ], ["R": red, "r": redD])
    c.px(10, 25 + flap, redL)
    // Buff breeches tucked into tall black boots, a brown cuff turned down at the top.
    drawLegs(c, Look(leg: breeches), step: step)
    drawBoots(c, boot, step: step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = airborne ? 43 : h6Foot(i, step)
            c.rect(lx, b - 4, 2, 1, cuff); c.px(lx, 37, breechesD)
            c.px(lx + 1, b - 1, C(0x44404C))
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: shirt), armRight: raise)
    // The open waistcoat over his bare chest, white shirt-sleeves; the belt and its buckle.
    c.rect(18, 32, 5, 5, vest); c.rect(33, 32, 5, 5, vest)
    c.rect(22, 32, 1, 5, vestL); c.rect(33, 32, 1, 5, vestL); c.rect(37, 32, 1, 5, vestD)
    c.px(20, 34, vestD); c.px(35, 34, vestD)
    c.rect(18, 37, 20, 1, C(0x1E1A22)); c.rect(26, 37, 3, 1, gold)
    c.rect(15, 35, 3, 1, shirtD)                                  // the back cuff
    // The bandana: tight over the top of his head, a lit fold across his brow, his dark hair below it at the sides.
    c.pattern(17, 21, [
        ".....RRRRRRRRRR.......",
        "...RRRRLRRRRRRRRRR....",
        "..RRRLRRRRRRRRRRRRRR..",
        ".RRRRRRRRRRRRRRRRRRRr.",
        "RRrRRRRrRRRRRRrRRRRRr.",
        "LLLLLLLLLLLLLLLLLLLLrr",
    ], ["R": red, "r": redD, "L": redL])
    c.pattern(17, 27, ["HH...................H", "Hh..................HH", "H...................Hh"],
              ["H": hair, "h": hairD])

    if rope {
        // His hand up on the rope, the rope running up to where it's tied.
        c.glowLine(39.5, 3 + Double(lift - p.breathe), 39.5, Double(33 - raise), core: C(0xC8A060), glow: h6None,
                   coreR: 0.6, glowR: 0.65)
        c.rect(38, 33 - raise, 3, 3, clawdOrange)
        return
    }
    let a: Double = p.melee ?? (seatedPose ? 20 : 72)
    h6Cutlass(c, p, angle: a, length: p.melee == nil ? 9 : 12, smear: true)
}

/// A cutlass in the fist at `angle`: a curved blade, its back lit, sweeping up towards the tip; a brass basket hilt
/// round the knuckles; the smear a fast swing leaves.
private func h6Cutlass(_ c: PixelCanvas, _ p: Pose, angle a: Double, at h: (x: Double, y: Double) = eterniaHand,
                       length: Double, smear: Bool) {
    if smear {
        for (i, t) in p.trail.enumerated() {
            let p0 = eterniaReach(h, t, 3), p1 = eterniaReach(h, t, length + 2)
            c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.5, glowR: 1.6,
                       strength: 0.3 / Double(i + 1))
        }
    }
    let brass = C(0xE0B040), brassD = C(0x9A7420)
    eterniaBar(c, h, a, from: -3, to: 1.5, C(0x4A3020), r: 0.9)
    // The blade, curving back: each step bends a little further off the line of the grip.
    let steps = 8
    var prev = eterniaReach(h, a, 2.5)
    for i in 1...steps {
        let f = Double(i) / Double(steps)
        let d = 2.5 + (length - 2.5) * f
        let q = eterniaReach(eterniaReach(h, a, d), a - 90, 2.2 * f * f)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xC8CCD8), glow: h6None, coreR: 1.05 - 0.35 * f, glowR: 1.1 - 0.35 * f)
        prev = q
    }
    prev = eterniaReach(eterniaReach(h, a, 3), a - 90, 0.5)
    for i in 1...steps {
        let f = Double(i) / Double(steps)
        let d = 3 + (length - 3.5) * f
        let q = eterniaReach(eterniaReach(h, a, d), a - 90, 2.2 * f * f + 0.5)
        c.glowLine(prev.x, prev.y, q.x, q.y, core: C(0xF4F8FF), glow: h6None, coreR: 0.4, glowR: 0.45)
        prev = q
    }
    // The basket: a guard across the blade's root, a bow of brass round the knuckles to the pommel.
    let g = eterniaReach(h, a, 2)
    let g0 = eterniaReach(g, a - 90, 1.5), g1 = eterniaReach(g, a + 90, 2.6)
    c.glowLine(g0.x, g0.y, g1.x, g1.y, core: brass, glow: h6None, coreR: 0.8, glowR: 0.85)
    let k0 = eterniaReach(eterniaReach(h, a, 1), a + 90, 2.6), k1 = eterniaReach(eterniaReach(h, a, -2.5), a + 90, 2)
    c.glowLine(k0.x, k0.y, k1.x, k1.y, core: brassD, glow: h6None, coreR: 0.6, glowR: 0.65)
    let pm = eterniaReach(h, a, -3)
    c.glowLine(k1.x, k1.y, pm.x, pm.y, core: brassD, glow: h6None, coreR: 0.6, glowR: 0.65)
    c.rect(Int(pm.x.rounded()) - 1, Int(pm.y.rounded()) - 1, 2, 2, brass)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)   // the fist round the grip
}

// MARK: - Mermista

/// Mermista: the mermaid princess of Salineas. Long white-blonde hair falling in waves, a coral-pink scallop shell for
/// a crown, an aqua bodice of scales, a belt strung with pearls and a blue-green fin skirt; on land her tail is two
/// pairs of blue-green scaled legs with little fins at the feet. Her magic is water: aqua arcs with a blue glow.
/// Signature: she lifts a hand and a little wave rises beside her, curls over and breaks into spray.
private func drawMermista(_ c: PixelCanvas, _ p: Pose) {
    let tail = C(0x26A89C), tailD = C(0x167670), tailL = C(0x5AD4C2), fin = C(0x8AF0E0)
    let aqua = C(0x3AA8E8), aquaD = C(0x2070B8), aquaL = C(0x8AD8FF)
    let hair = C(0xF6F0D2), hairD = C(0xC8BC8A), hairL = C(0xFFFFF4)
    let shell = C(0xF8A0B4), shellD = C(0xC8607E), shellL = C(0xFFE0E8)
    let s = p.signature ?? -1
    let call = s < 0 ? 0 : habitArc(s, hold: 0.7)
    let raise = max(p.armRaise, Int((call * 3).rounded()))

    // Her hair down her back in long waves.
    for (i, x) in [14, 15, 16, 17].enumerated() {
        let len = 12 - i % 2 - (i == 0 ? 3 : 0)
        for y in 27..<(27 + len) { c.px(x + ((y / 3) % 2 == 0 && i == 0 ? 1 : 0), y, i % 2 == 0 ? hair : hairD) }
    }
    // The tail as legs: blue-green, scaled, a fin flaring at each foot.
    drawLegs(c, Look(leg: tail), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = h6Foot(i, p.step)
            for y in stride(from: b - 6, to: b - 1, by: 2) { c.px(lx + (y / 2) % 2, y, tailD) }
            c.px(lx, b - 5, tailL)
            c.rect(lx - 1, b, 4, 1, fin); c.px(lx - 1, b - 1, fin)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange), armRight: raise)
    // The scaled bodice, the pearl; the fin skirt, its points over her legs.
    c.rect(18, 33, 20, 3, aqua); c.rect(18, 33, 20, 1, aquaL); c.rect(37, 33, 1, 3, aquaD)
    for x in stride(from: 19, to: 37, by: 2) { c.px(x, 34 + (x / 2) % 2, aquaD) }
    c.rect(18, 36, 20, 1, tailD)
    for x in stride(from: 20, to: 37, by: 4) { c.px(x, 36, C(0xF4F8FF)) }   // a string of pearls on her belt
    for y in 37...39 where y + c.oy <= 42 {
        for x in 18...37 {
            let ph = (x - 18) % 5
            if y == 39 && ph > 1 { continue }
            if y == 38 && ph > 3 { continue }
            c.px(x, y, y == 37 ? tail : ph == 0 ? tailL : tailD)
        }
    }
    c.rect(15, 35, 3, 1, aqua); c.rect(38, 35 - raise, 3, 1, aqua)   // shell bracelets

    // The hair: white-blonde, parted at the side, falling in waves either side of her face.
    c.pattern(14, 20, [
        "......HHHHHHHHHHHH.......",
        "....HHHHlHHHHHHlHHHHH....",
        "...HHhHHHHHhHHHHHHhHHHH..",
        "..HHhHHHHHhHHHHHHHHhHHHH.",
        "..HHhHHhhHHHHHHHHhhHHhHH.",
        ".HHhHHhHhhHhhhHhhHHhHhHHH",
        ".HHh..................hHH",
        "HHh...................hhH",
        ".HHh..................hHH",
        "HHh...................hH.",
        ".HHh..................hHH",
        "HHh...................hH.",
        ".hH....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The scallop-shell crown, ridged, its hinge on her hair, a pearl either side.
    c.pattern(21, 14, [
        ".S.S.S.S.S.S.",
        "SLSrSLSrSLSrS",
        "SLSrSLSrSLSrS",
        ".SLrSLSrSLSr.",
        "..LrSLSrSLS..",
        "...rSLSrSL...",
        "....sPPPs....",
    ], ["S": shell, "r": shellD, "L": shellL, "s": shellD, "P": C(0xE8C860)])
    c.rect(20, 20, 2, 2, C(0xFFFFFF)); c.rect(34, 20, 2, 2, C(0xFFFFFF))
    c.px(21, 21, C(0xC8D8E8)); c.px(35, 21, C(0xC8D8E8))

    if s > 0.08 && s < 0.95 {
        // The wave: it rises, curls over, and breaks into spray.
        let w = (s - 0.08) / 0.87
        let pal: [Character: Px] = ["W": C(0x40C8EC), "w": C(0x2290D0), "d": C(0x1A68B0), "F": C(0xF2FFFF),
                                    "f": C(0xA8F0FF)]
        if w < 0.3 {
            let rows = [
                "..............",
                "......FFF.....",
                "....FfWWWF....",
                "..FfWWwwwWFf..",
                "FfWWwwwwwwwWWF",
            ]
            let h = Int((w / 0.3 * 4).rounded())
            c.pattern(42, 39 + (4 - h), Array(rows.suffix(h + 1)), pal)
        } else if w < 0.7 {
            c.pattern(42, 30, [
                ".......FFFF....",
                ".....FFWWWWFF..",
                "....FWWwwwwWWF.",
                "...fWwwwddwwWWF",
                "...WwwwddddwWfF",
                "..WwwwdddW...fF",
                "..WwwddW......f",
                ".WwwwddW.......",
                ".WwwwwddW......",
                "WwwwwwwddW.....",
                "WwwwwwwwddWFF..",
                "WwwwwwwwwwwwWFF",
                "FfWWWWWWWWWWWfF",
            ], pal)
        } else {
            let f = (w - 0.7) / 0.3
            c.pattern(42, 36, [
                "....FFFFF......",
                "..FFWWWWWFF....",
                ".FWWwwwwwWWF...",
                "FWwwwwwwwwwWFf.",
                "WwwwwwwwwwwwWFF",
                "FfWWWWWWWWWWWfF",
            ], pal)
            // The spray, flying up and out, bright on a dark desktop.
            for i in 0..<7 {
                let a = -150.0 + Double(i) * 20
                let q = eterniaReach((50, 36), a, 3 + f * 9)
                c.px(Int(q.x.rounded()), Int((q.y + f * f * 6).rounded()), C(i % 2 == 0 ? 0xF2FFFF : 0x8AE0FF, 1 - f * 0.7))
            }
        }
    }
}

// MARK: - Perfuma

/// Perfuma: the flower princess of Plumeria. Long golden hair with pink blossoms tucked in it, a bodice of green
/// leaves with a leaf collar, a skirt of pink petals ending in points, green slippers. She throws pink flowers. A
/// flower is always in her hand. Signature: she lifts it to her face and sniffs it, eyes closed in bliss, and petals
/// drift up off it.
private func drawPerfuma(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF4D470), hairD = C(0xC8A040), hairL = C(0xFFF0A8)
    let leaf = C(0x4AB04A), leafD = C(0x2E7A32), leafL = C(0x84D46C)
    let petal = C(0xF07AB4), petalD = C(0xC04A88), petalL = C(0xFFB0D4), heart = C(0xFFE860)
    let s = p.signature ?? -1
    let sniff = s < 0 ? 0 : habitArc(s, hold: 0.6)
    let smelling = sniff > 0.9
    // Throwing: her arm goes up to wind back, then down as she lets the flower go; it's gone from her hand a beat.
    var raise = Int((sniff * 4).rounded())
    var thrown = false
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        if ph > 0.75 { raise = max(raise, Int(((ph - 0.75) / 0.25 * 4).rounded())) }
        thrown = ph < 0.35
    }

    // Her hair down her back.
    for (i, x) in [15, 16, 17].enumerated() { c.rect(x, 27, 1, 11 - i % 2, i % 2 == 0 ? hair : hairD) }
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, leaf, step: p.step, rows: 2)
    if !seatedPose { for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, h6Foot(i, p.step), leafD) } }
    c.oy += p.breathe
    drawBody(c, Look(arm: clawdOrange, eye: smelling ? nil : ink), armRight: raise)
    if smelling {
        // Her eyes closed in bliss.
        for ex in [22, 32] { c.px(ex - 1, 30, ink); c.rect(ex, 31, 2, 1, ink); c.px(ex + 2, 30, ink) }
    }
    // The leaf bodice: a collar of pointed leaves, then leaves overlapping, each with its vein.
    c.pattern(18, 32, [
        "L.LL.LL.LL.LL.LL.LL.",
        "GLGGlGGlGGlGGlGGlGGd",
        "GgGGgGGgGGgGGgGGgGGd",
        "GGgGGGgGGGgGGGgGGGgd",
    ], ["G": leaf, "g": leafD, "l": leafL, "L": leafL, "d": leafD])
    // The petal skirt: rows of pink petals, lit at the top, ending in points over her legs.
    for y in 36...40 where y + c.oy <= 42 {
        let f = (y - 36) / 2
        for x in (18 - f)...(37 + f) {
            let ph = (x - 18 + f + (y % 2) * 2) % 4
            if y == 40 && ph != 1 { continue }
            if y == 39 && ph == 3 { continue }
            c.px(x, y, ph == 0 ? petalD : y == 36 ? petalL : petal)
        }
    }
    c.rect(15, 35, 3, 1, leaf); c.rect(38, 35 - raise, 3, 1, leaf)   // leafy cuffs

    // The hair: long and golden, a soft fringe, falling past her shoulders, blossoms tucked in it.
    c.pattern(15, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHlHHHHHHlHHHHH....",
        "..HHHhHHHHhHHHHHhHHHHH..",
        ".HHhHHHHhHHHHHhHHHHhHHH.",
        ".HHhHHHhHHHHhHHHHHHhHHH.",
        "HHhHHhhHhhhHHhhhHhhHhHHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HHh..................hHH",
        "HhH..................hHH",
        "Hh...................hH.",
        ".h....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    h6Blossom(c, 19, 21, petal: petal, lit: petalL, heart: heart)
    h6Blossom(c, 28, 19, petal: C(0xFF5A9A), lit: petalL, heart: heart)
    h6Blossom(c, 36, 22, petal: petal, lit: petalL, heart: heart)
    h6Blossom(c, 16, 27, petal: C(0xFF5A9A), lit: petalL, heart: heart)

    // The flower in her hand: a pink bloom on a green stem; held up to her face while she smells it.
    if !thrown {
        let hy = 34 - raise
        let fx = 43, fy = smelling ? hy - 1 : hy - 4
        c.glowLine(41, Double(hy), Double(fx), Double(fy + 1), core: leafD, glow: h6None, coreR: 0.5, glowR: 0.55)
        c.px(fx - 1, fy + 2, leaf)
        c.pattern(fx - 2, fy - 2, [".PP.", "PHHP", "PHHP", ".PP."], ["P": C(0xFF5A9A), "H": heart])
        c.px(fx - 1, fy - 2, petalL)
        c.rect(40, hy, 3, 2, clawdOrange)   // her fingers round the stem
    }
    if s > 0.2 && s < 0.95 {
        // The petals she's breathed off it, drifting up and swaying, fading only near the top.
        for i in 0..<4 {
            let f = frac(p.t * 0.6 + Double(i) / 4)
            let x = 41 + Int((sin(f * 7 + Double(i)) * 2.5).rounded()) + i, y = 26 - Int(f * 16)
            guard f < 0.9 else { continue }
            c.rect(x, y, 2, 1, (i % 2 == 0 ? petalL : C(0xFF5A9A)).alpha(1 - f * 0.6))
        }
    }
}
