import Foundation

// Heroes: the royal court of Eternia and the Masters who serve it, from King Randor and Queen Marlena to Clawdfist.
// Drawn the same way as EterniaHeroes1.swift: Clawd in costume, the armour, fur, feathers and helmets over the blocky
// body, Clawd's own orange showing wherever Filmation left an arm or a leg bare.

let eterniaHeroes3: [EterniaHero: Persona] = [
    .kingRandor: Persona(name: "King Randor", weapon: .saber, headTop: 18, signature: 3.4, draw: drawKingRandor),
    .queenMarlena: Persona(name: "Queen Marlena", headTop: 19, signature: 4.2, draw: drawQueenMarlena),
    .stratos: Persona(name: "Stratos", weapon: .saber, motion: .fly, headTop: 21, signature: 3.6, draw: drawStratos),
    .ramClawd: Persona(name: "Ram Clawd", weapon: .saber, pivot: h3RamHand, bulk: 3, headTop: 22, signature: 2.8,
                       draw: drawRamClawd),
    .manEClawds: Persona(name: "Man-E-Clawds", weapon: .saber, headTop: 19, signature: 4.0, draw: drawManEClawds),
    .mekaneck: Persona(name: "Mekaneck", weapon: .saber, headTop: 21, signature: 3.8, draw: drawMekaneck),
    .buzzOff: Persona(name: "Buzz-Off", weapon: .saber, motion: .fly, headTop: 18, signature: 2.6, draw: drawBuzzOff),
    .clawdfist: Persona(name: "Clawdfist", weapon: .saber, headTop: 21, signature: 3.0, draw: drawClawdfist),
]

// MARK: - Shared bits

private let h3None = C(0, 0)
/// The shoulder a punch is thrown from: Clawd's near arm nub.
private let h3Shoulder = (x: 39.0, y: 34.5)

/// A solid line from one point to another, `r` from its centre (an arm, a haft, a feather).
private func h3Line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px,
                    _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: h3None, coreR: r, glowR: r + 0.1)
}

/// A punch along `angle`: the arm out from the shoulder in its sleeve, a cuff near the end, and the fist, `size`
/// pixels square, with a faint smear behind it on a fast swing.
private func h3Fist(_ c: PixelCanvas, angle a: Double, trail: [Double], sleeve: Px, cuff: Px? = nil,
                    glove: Px = clawdOrange, gloveD: Px = clawdShade, size: Int = 3, reach: Double = 6) {
    let e = eterniaReach(h3Shoulder, a, reach)
    for (i, t) in trail.enumerated() {
        let q = eterniaReach(h3Shoulder, t, reach)
        c.glowLine(q.x, q.y, e.x, e.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.6, glowR: 1.8,
                   strength: 0.3 / Double(i + 1))
    }
    h3Line(c, h3Shoulder.x - 1, h3Shoulder.y, e.x, e.y, sleeve, 1.3)
    if let cuff {
        let k = eterniaReach(h3Shoulder, a, reach - 2)
        c.rect(Int(k.x.rounded()) - 1, Int(k.y.rounded()) - 1, 2, 2, cuff)
    }
    let x0 = Int(e.x.rounded()) - size / 2, y0 = Int(e.y.rounded()) - size / 2
    c.rect(x0, y0, size, size, glove)
    c.rect(x0, y0 + size - 1, size, 1, gloveD); c.rect(x0 + size - 1, y0, 1, size, gloveD)
}

/// A battle axe in the fist at `angle`: the haft, then a broad head on its leading side near the end, lit along its
/// cutting edge, a smear behind a fast swing.
private func h3Axe(_ c: PixelCanvas, _ p: Pose, angle a: Double, at h: (x: Double, y: Double) = eterniaHand,
                   haft: Px, haftL: Px, head: Px, headD: Px, edge: Px, length: Double = 11) {
    for (i, t) in p.trail.enumerated() {
        let p0 = eterniaReach(h, t, length - 4), p1 = eterniaReach(h, t, length + 3)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.6, glowR: 1.8,
                   strength: 0.3 / Double(i + 1))
    }
    eterniaBar(c, h, a, from: -3, to: length + 1, haft, r: 0.8)
    eterniaBar(c, h, a, from: -2, to: length, haftL, r: 0.3)
    // The head: three bars out from the haft on the side it's swung towards, the middle one longest, so it flares.
    for (d, out) in [(length - 3.5, 3.4), (length - 2, 4.4), (length - 0.5, 3.4)] {
        let root = eterniaReach(h, a, d)
        let tip = eterniaReach(root, a + 90, out)
        h3Line(c, root.x, root.y, tip.x, tip.y, head, 1.0)
    }
    let r0 = eterniaReach(eterniaReach(h, a, length - 4.2), a + 90, 1.2)
    let r1 = eterniaReach(eterniaReach(h, a, length + 0.2), a + 90, 1.2)
    h3Line(c, r0.x, r0.y, r1.x, r1.y, headD, 0.5)
    let e0 = eterniaReach(eterniaReach(h, a, length - 4), a + 90, 4.2)
    let e1 = eterniaReach(eterniaReach(h, a, length), a + 90, 4.2)
    h3Line(c, e0.x, e0.y, e1.x, e1.y, edge, 0.5)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)   // the fist round the haft
}

/// A long skirt (a robe, a gown) from row 38 to the hem at `hem`, flaring out by a pixel every `flareEvery` rows,
/// lit on the near-left edge, shaded on the far side, with a soft fold between the legs. Stops short of the ground
/// when sitting, the legs folded up under it.
private func h3Skirt(_ c: PixelCanvas, _ base: Px, _ dark: Px, _ light: Px, hem: Int, flareEvery: Int = 2) {
    for y in 38...(seatedPose ? 38 : hem) {
        let flare = (y - 38 + 1) / flareEvery
        c.rect(18 - flare, y, 20 + 2 * flare, 1, base)
        c.px(18 - flare, y, light); c.px(37 + flare, y, dark)
        if y >= 39 { for x in [22, 26, 30, 34] { c.px(x, y, dark) } }
    }
}

// MARK: - King Randor

/// King Randor: Eternia's king, and Prince Addam's father, none the wiser. A gold crown with five points and red and
/// blue stones set in its band, short brown hair, and a full brown beard combed down over his chest; a long royal blue
/// robe to the ground with a gold collar, a gold stripe down its front and a gold hem, the toes of his brown boots
/// peeping out under it. Fights with a broadsword, carried at his hip in its scabbard when it's put away. Signature:
/// holding court, he raises his gold sceptre high, its red stone glinting, and lowers it again.
private func drawKingRandor(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x2E5AB8), robeD = C(0x1E3E88), robeL = C(0x5A84D8)
    let gold = C(0xE0B040), goldD = C(0x9A7420), goldL = C(0xFFE07A), ruby = C(0xD0283A), sapphire = C(0x3A8AF0)
    let beard = C(0x7A4E2A), beardD = C(0x54341A), beardL = C(0x9E6E40), boot = C(0x5A3A22)
    let s = p.signature ?? -1
    let up = s < 0 ? 0 : habitArc(s, hold: 0.6)
    let raise = Int((up * 9).rounded())

    // The legs under the robe, and the toes of his boots peeping out under the hem.
    drawLegs(c, Look(leg: robeD), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    c.oy += p.breathe
    drawBody(c, Look(arm: robe), armRight: raise)
    // The robe: from the collar down to the ground, a fold down each side of his chest, lit down the near side.
    c.rect(18, 32, 20, 6, robe); c.rect(18, 32, 1, 6, robeL); c.rect(37, 32, 1, 6, robeD)
    h3Skirt(c, robe, robeD, robeL, hem: 41)
    // The gold collar across his shoulders, the stripe down the robe's front and its hem.
    c.rect(18, 32, 20, 1, gold); c.px(18, 32, goldL); c.px(37, 32, goldD)
    for y in 37...(seatedPose ? 38 : 41) { c.rect(27, y, 2, 1, gold); c.px(28, y, goldD) }
    if !seatedPose {
        c.rect(16, 41, 24, 1, gold); c.px(16, 41, goldL)
        for x in stride(from: 18, to: 40, by: 3) { c.px(x, 41, goldD) }
    }
    // The gold belt, its buckle set with a ruby.
    c.rect(18, 37, 20, 1, goldD); c.rect(26, 37, 4, 1, gold); c.px(27, 37, ruby); c.px(28, 37, ruby)
    // Gold cuffs on his sleeves.
    c.rect(15, 35, 3, 1, gold); c.rect(38, 35 - raise, 3, 1, gold)

    // The beard: full and brown, down from his sideburns, round under his eyes and combed in strands to a point on
    // his chest, a darker moustache over it.
    c.pattern(18, 28, [
        "Bh................hB",
        "Bh................hB",
        "BB................BB",
        "BBh..............hBB",
        "BBBB.MMMMMMMMMM.BBBB",
        ".BBBlBBMMMMMMBBlBBB.",
        "..BBBhBBlBBlBBhBBB..",
        "...BBBhBBBBBBhBBB...",
        "....BBBhBlBBhBBB....",
        "......BBhBBhBB......",
    ], ["B": beard, "h": beardD, "l": beardL, "M": beardD])
    // His hair, short and brown, under the crown, and his brows.
    c.rect(18, 25, 20, 2, beard); c.rect(18, 26, 1, 2, beardD); c.rect(37, 26, 1, 2, beardD)
    for x in stride(from: 20, to: 37, by: 3) { c.px(x, 26, beardD) }
    c.rect(22, 28, 2, 1, beardD); c.rect(32, 28, 2, 1, beardD)
    // The crown: five points, a band lit along the top and shaded underneath, a ruby in the middle and sapphires
    // either side.
    c.pattern(18, 18, [
        "L........LL........L",
        "GG...L...GG...L...GG",
        "GG..GGG.GGGG.GGG..GG",
        "GGGGGGGGGGGGGGGGGGGG",
        "LLLLLLLLLLLLLLLLLLLd",
        "GGGsGGGGGrrGGGGsGGGd",
        "GGGGGGGGGrrGGGGGGGGd",
        "dddddddddddddddddddd",
    ], ["G": gold, "L": goldL, "d": goldD, "r": ruby, "s": sapphire])

    if raise > 0 {
        // The sceptre, up from his raised fist: a gold rod, a collar, and a red stone in a gold cup at its top that
        // glints while it's held up.
        let hx = 40, hy = 34 - raise
        c.rect(hx - 1, hy - 12, 2, 13, gold); c.rect(hx - 1, hy - 12, 1, 13, goldL)
        c.rect(hx - 2, hy - 4, 4, 1, goldD)
        c.pattern(hx - 3, hy - 18, [
            "..rr..",
            ".rRrr.",
            "GrrrrG",
            "GGrrGG",
            ".GGGG.",
            "..GG..",
        ], ["r": ruby, "R": C(0xFF8A9A), "G": gold])
        if up > 0.95 {
            // The glint: a little star that twinkles at the stone.
            let k = sin(p.t * 9) * 0.5 + 0.5
            let gx = Double(hx), gy = Double(hy - 16)
            c.glowLine(gx - 3, gy, gx + 3, gy, core: C(0xFFFFFF, 0.9 * k), glow: C(0xFFD060, 0.6 * k), coreR: 0.3, glowR: 1.2)
            c.glowLine(gx, gy - 3, gx, gy + 3, core: C(0xFFFFFF, 0.9 * k), glow: C(0xFFD060, 0.6 * k), coreR: 0.3, glowR: 1.2)
        }
        c.rect(hx - 2, hy - 1, 3, 3, robe); c.rect(hx - 2, hy + 1, 3, 1, gold)   // his sleeve round it
        return
    }
    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: C(0x5A3A22), guardCol: gold, steel: C(0xC4C8D4), edge: C(0xFFFFFF),
                     length: 13, pommel: gold)
    } else {
        // The sword at his hip, in its scabbard: the hilt and guard by his hand, the sheath down the robe's side.
        c.rect(39, 37, 1, 5 - (seatedPose ? 3 : 0), C(0x3A2A1A)); c.px(39, 41 - (seatedPose ? 3 : 0), goldD)
        c.rect(38, 36, 3, 1, gold); c.px(39, 35, C(0x5A3A22)); c.px(39, 34, gold)
    }
}

// MARK: - Queen Marlena

/// Queen Marlena: Eternia's queen, once Captain Marlena Glenn of Earth, who crash-landed her spaceship there and
/// stayed. Honey-blonde hair cut in a soft bob, a slim gold circlet with three points and a blue stone, and a long
/// lavender gown to the ground, its neckline trimmed in gold, a gold sash at her waist and white cuffs. She doesn't
/// fight. Signature: she brings out her old astronaut's helmet from behind her, lifts it over her head and puts it on,
/// looks out through its visor for a moment, and takes it off again.
private func drawQueenMarlena(_ c: PixelCanvas, _ p: Pose) {
    let gown = C(0xB89CE0), gownD = C(0x8466C0), gownL = C(0xDCCCF6)
    let hair = C(0xD0A060), hairD = C(0x9A7038), hairL = C(0xF0C888)
    let gold = C(0xE0B040), goldD = C(0x9A7420), goldL = C(0xFFE07A), cuff = C(0xF4F2F8)
    let s = p.signature ?? -1
    // Where the helmet is (the row its top is on), whether it's behind her, and how far her arms are up holding it.
    var hy = 34, behind = true, on = false
    func ease(_ u: Double) -> Double { u * u * (3 - 2 * u) }
    if s >= 0.06 && s < 0.3 { hy = 34 - Int((ease((s - 0.06) / 0.24) * 28).rounded()) }
    else if s >= 0.3 && s < 0.42 { hy = 6 + Int((ease((s - 0.3) / 0.12) * 12).rounded()); behind = false }
    else if s >= 0.42 && s < 0.72 { hy = 18; behind = false; on = true }
    else if s >= 0.72 && s < 0.82 { hy = 18 - Int((ease((s - 0.72) / 0.1) * 12).rounded()); behind = false }
    else if s >= 0.82 && s < 0.96 { hy = 6 + Int((ease((s - 0.82) / 0.14) * 28).rounded()) }
    let showHelmet = s >= 0.06 && s < 0.96
    // Her hands hold its sides, except while it's on, when they come down to her sides for a moment.
    var raise = showHelmet ? max(0, min(16, 24 - hy)) : 0
    if on {
        let u = s < 0.48 ? 1 - (s - 0.42) / 0.06 : s > 0.66 ? (s - 0.66) / 0.06 : 0
        raise = Int((Double(raise) * max(0, min(1, u))).rounded())
    }

    drawLegs(c, Look(leg: gownD), step: p.step)
    drawBoots(c, gold, step: p.step, rows: 1)
    c.oy += p.breathe
    if showHelmet && behind { h3Helmet(c, hy: hy, eyes: false) }
    drawBody(c, Look(arm: gown), armLeft: raise, armRight: raise)
    if raise > 3 {   // her arms up, in their sleeves, to the hands at the helmet's sides
        c.rect(15, 33 - raise, 3, raise, gown); c.rect(15, 33 - raise, 1, raise, gownL)
        c.rect(38, 33 - raise, 3, raise, gown); c.rect(40, 33 - raise, 1, raise, gownD)
    }
    c.rect(15, 35 - raise, 3, 1, cuff); c.rect(38, 35 - raise, 3, 1, cuff)
    c.rect(15, 32 - raise, 3, 1, clawdOrange); c.rect(38, 32 - raise, 3, 1, clawdOrange)   // her hands

    // The gown: the bodice, then the skirt flaring all the way to the ground, folds between the legs.
    c.rect(18, 33, 20, 5, gown); c.rect(18, 33, 1, 5, gownL); c.rect(37, 33, 1, 5, gownD)
    h3Skirt(c, gown, gownD, gownL, hem: 42, flareEvery: 2)
    if !seatedPose { c.rect(17, 42, 22, 1, gownD); c.px(16, 42, gownL); c.px(39, 42, gownD) }
    // The gold-trimmed neckline, a scoop, and the gold sash at her waist with its ends hanging.
    c.pattern(18, 33, [
        "GGGGG........GGGGG",
        ".gGGGGGGGGGGGGGGg.",
    ], ["G": gold, "g": goldD])
    c.px(18, 33, goldL)
    c.rect(18, 36, 20, 1, gold); c.rect(18, 36, 1, 1, goldL); c.rect(37, 36, 1, 1, goldD)
    c.rect(24, 37, 2, 3 - (seatedPose ? 2 : 0), goldD); c.px(24, 37, gold)

    if on {
        h3Helmet(c, hy: hy, eyes: true)
        return
    }
    // The bob: a soft cap of honey-blonde hair parted on the left, combed down in strands to her jaw either side,
    // curling in at the ends.
    c.pattern(16, 21, [
        ".....HHHHlHHHHHHHH....",
        "...HHHlHHHHhHHHlHHHH..",
        "..HHHhHHHHHHhHHHHhHHH.",
        ".HHHHhHHlHHHHhHHHHhHHH",
        ".HHHhHHHhHHHHHhHHHHhHH",
        "HHHHhHHhHHH..hHHHHhHHH",
        "HHh.hH........hH...hHH",
        "HHh..................H",
        "HHh..................H",
        "HHh..................h",
        "HHh..................h",
        ".HH.................h.",
        "..h...................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)   // her brows
    // The circlet: a slim gold band with three points, the middle one tallest, a blue stone at its front.
    c.pattern(19, 18, [
        "........LL........",
        "...L....GG....L...",
        "...G...GGGG...G...",
        "LLLLLLLLbbLLLLLLLL",
        "ddddddddddddddddd.",
    ], ["G": gold, "L": goldL, "d": goldD, "b": C(0x3A8AF0)])
    if showHelmet && !behind { h3Helmet(c, hy: hy, eyes: false) }
}

/// Queen Marlena's astronaut helmet, its top on row `hy`: a big white dome lit on the left, a pale blue visor with a
/// glint across it, her eyes looking out through it when it's on (`eyes`), and a grey neck ring.
private func h3Helmet(_ c: PixelCanvas, hy: Int, eyes: Bool) {
    let w = C(0xF2F2F6), wD = C(0xB8BAC6), wL = C(0xFFFFFF), visor = C(0x8CC0EC), visorD = C(0x5A8CC8)
    c.pattern(17, hy, [
        "......WWWWWWWWWW......",
        "....WWWLLWWWWWWWWD....",
        "...WWLLWWWWWWWWWWWD...",
        "..WWLWWWWWWWWWWWWWWD..",
        ".WWLWWWWWWWWWWWWWWWWD.",
        ".WWWWWWWWWWWWWWWWWWWD.",
        "WWLWWWWWWWWWWWWWWWWWWD",
        "WWWWWWWWWWWWWWWWWWWWWD",
        "WWWWWWWWWWWWWWWWWWWWWD",
        "WWWWWWWWWWWWWWWWWWWWWD",
        "WWWVVVVVVVVVVVVVVVVWWD",
        "WWVVgVVVVVVVVVVVVVVvWD",
        "WWVVVgVVVVVVVVVVVVVvWD",
        "WWWvvvvvvvvvvvvvvvvWWD",
        ".RRRRRRRRRRRRRRRRRRRR.",
    ], ["W": w, "D": wD, "L": wL, "V": visor, "v": visorD, "g": C(0xFFFFFF), "R": C(0x8A8E9A)])
    c.rect(36, hy + 4, 2, 2, C(0xC8302A))   // a little red light on its side
    if eyes { c.rect(22, hy + 11, 2, 2, ink); c.rect(32, hy + 11, 2, 2, ink) }
}

// MARK: - Stratos

/// Stratos: the winged leader of the bird people of Avion. Grey fur all over, combed in strokes, a shock of white
/// hair swept back into spikes behind him and a short white beard, round flying goggles with amber lenses over his
/// eyes on a black strap, and big blue feathered wings down the backs of his arms, the long feathers lit at their
/// leading edge. A red flying pack on his back with grey nozzles, its red straps over his chest to a red belt. He
/// fights with his fists. Signature: he beats his wings, rises off the ground, hangs in the air a moment on slow
/// beats, and comes down again.
private func drawStratos(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x8A8C9A), furD = C(0x62646F), furL = C(0xAEB0BC)
    let hair = C(0xE8EAF2), hairD = C(0xA8AAB8), hairL = C(0xFFFFFF)
    let pack = C(0xC8302A), packD = C(0x8A1E1A), packL = C(0xE85A4A)
    let s = p.signature ?? -1
    let aloft = s < 0 ? 0 : habitArc(s, hold: 0.5)
    let lift = Int((aloft * 8).rounded())
    // The wings: folded down his arms at rest; in the air they flick between up over his back and down, hard in
    // flight and on take-off, slowly while he hangs there.
    var up: Bool? = nil
    if p.flying { up = Int(p.t * 9) % 2 == 0 }
    else if s >= 0.04 && s < 0.96 { up = Int(p.t * (aloft > 0.95 ? 3.5 : 9)) % 2 == 0 }

    c.oy -= lift
    drawLegs(c, Look(leg: fur), step: p.step)
    drawBoots(c, furD, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {   // fur strokes down his legs
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 4, furL); c.px(lx + 1, bottom - 3, furD)
        }
    }
    c.oy += p.breathe

    // The wings, behind him: both raised over his back, or the far one folded down behind his pack.
    if up == true {
        h3WingUp(c, x: 20, dim: true)
        h3WingUp(c, x: 26, dim: false)
    } else {
        h3WingFolded(c, x: 10, y: 31, dim: true)
    }
    // The flying pack on his back: a red case with a lit top and seams, two grey nozzles underneath.
    c.rect(12, 27, 6, 9, pack); c.rect(12, 27, 6, 1, packL); c.rect(12, 27, 1, 9, packL)
    c.rect(12, 35, 6, 1, packD); c.rect(14, 29, 1, 5, packD)
    c.rect(12, 36, 2, 2, C(0x8A8E9A)); c.rect(16, 36, 2, 2, C(0x8A8E9A)); c.px(12, 37, C(0x5A5E6A)); c.px(16, 37, C(0x5A5E6A))
    if up != nil {   // the nozzles burn while he's in the air
        c.glowLine(13, 38.5, 13, 40.5, core: C(0xFFE8A0, 0.9), glow: C(0xFF8A2A, 0.6), coreR: 0.5, glowR: 1.4)
        c.glowLine(17, 38.5, 17, 40.5, core: C(0xFFE8A0, 0.9), glow: C(0xFF8A2A, 0.6), coreR: 0.5, glowR: 1.4)
    }

    let raise = p.melee == nil && up == nil ? p.armRaise : 0
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: ink), armRight: raise)
    // Fur strokes on his chest and sides, a lit run along his shoulders.
    c.rect(18, 26, 19, 1, furL)
    for (x, y) in [(23, 35), (29, 36), (32, 35), (26, 35), (19, 30), (36, 30)] { c.rect(x, y, 1, 2, furD) }
    // The pack's straps over his shoulders to a red belt.
    c.rect(20, 32, 2, 5, pack); c.rect(34, 32, 2, 5, pack); c.px(20, 32, packL); c.px(34, 32, packL)
    c.rect(18, 37, 20, 1, packD); c.rect(26, 37, 4, 1, C(0xE0B040))
    // The short white beard round his chin.
    c.pattern(22, 32, [
        "WWWWWWWWWWWW",
        ".WWdWWWWdWW.",
        "...WWlWWW...",
    ], ["W": hair, "d": hairD, "l": hairL])
    // His hair: a white shock swept back off his brow into spikes behind him, in strands.
    c.pattern(13, 20, [
        "...........WWWWWW......",
        "WW......WWWWlWWWWWWW...",
        ".WWW..WWWWWlWWWWWWWWW..",
        "..WWWWWWdWWWWWWdWWWWWW.",
        "WWWWWWWdWWWWWdWWWWWWdWW",
        "..WWWdWWWWdWWWWWdWWWWWW",
        ".....WWdWWWWdWWWWWWdWWW",
    ], ["W": hair, "d": hairD, "l": hairL])
    // The goggles: a black strap round his head, a rim round each eye, the lens amber.
    c.rect(18, 28, 20, 1, C(0x2A2A33))
    for gx in [21, 31] {
        c.pattern(gx, 28, [
            "RRRR",
            "RaaR",
            "RaaR",
            "RaaR",
            ".RR.",
        ], ["R": C(0x3A3A44), "a": C(0xF0C86A)])
        c.rect(gx + 1, 29, 2, 3, ink)
        c.px(gx + 1, 29, C(0xFFF0C0))
    }

    // The near wing, folded down the back of his arm, the arm over it; then a punch.
    if up != true {
        h3WingFolded(c, x: 37, y: 31, dim: false)
        c.rect(38, 33 - raise, 3, 3, fur); c.px(38, 33 - raise, furL)
    }
    if let a = p.melee { h3Fist(c, angle: a, trail: p.trail, sleeve: fur) }
    if lift > 1 && !p.flying {
        // A puff of air under him as he goes up and comes down, pale so it shows on a dark desktop.
        let k = 1 - aloft
        let gy = 44 + Double(lift)
        for dx in [-8.0, 0, 8] {
            c.glowLine(28 + dx - 3, gy, 28 + dx + 3, gy, core: C(0xF4F8FF, 0.25 + 0.45 * k),
                       glow: C(0xD8E4F8, 0.15 + 0.3 * k), coreR: 0.4, glowR: 1.3)
        }
    }
}

private let h3WingBlue: [Character: Px] = ["B": C(0x2E6AD0), "d": C(0x1E4890), "L": C(0x7AAAF8)]
private let h3WingDim: [Character: Px] = ["B": C(0x2456A8), "d": C(0x183A74), "L": C(0x5A88D8)]

/// One of Stratos's wings raised high over his back, its long feathers fanned up and back, its left edge at `x`.
private func h3WingUp(_ c: PixelCanvas, x: Int, dim: Bool) {
    c.pattern(x, 9, [
        "L.............",
        "LL..L.........",
        ".LBBLL.L......",
        ".LBBBBLLL.....",
        "..BBdBBBBL....",
        "..BBBdBBdBL...",
        "...BBBdBBdB...",
        "...BBBBdBBdB..",
        "....BBBBdBBB..",
        ".....BBBBdBBB.",
        "......BBBBdBB.",
        ".......BBBBBBB",
        "........BBBBBB",
        ".........BBBBB",
        "..........BBBB",
    ], dim ? h3WingDim : h3WingBlue)
}

/// One of Stratos's wings folded down along his arm from the shoulder, the long feathers hanging in strokes, its top
/// left at (x, y).
private func h3WingFolded(_ c: PixelCanvas, x: Int, y: Int, dim: Bool) {
    c.pattern(x, y, [
        ".BBBB.",
        "LBBBBB",
        "LBdBdB",
        "LBdBdB",
        "LBdBdB",
        "LBdBdB",
        ".BdBdB",
        ".BdBd.",
        "..dBd.",
        "..d.d.",
    ], dim ? h3WingDim : h3WingBlue)
}

// MARK: - Ram Clawd

private let h3RamHand = (x: 42.5, y: 36.5)

/// Ram Clawd: the Masters' human battering ram, short and stocky. A huge red-brown helmet rounded like a ram's skull,
/// a ridge down its front and big tan horns curling round in a spiral at its sides, coming down to just over his
/// eyes; green armour plates on his broad chest, his shoulders and his shins, a brown belt, Clawd's orange showing at
/// his arms. He sits lower than the others, his shoulders hunched, and charges with his head; he swings a short battle
/// axe, which hangs on his back when it's put away. Signature: he crouches down low, then springs forward head first,
/// a whoosh behind him, and lands back on his feet.
private func drawRamClawd(_ c: PixelCanvas, _ p: Pose) {
    let helm = C(0xA0402A), helmD = C(0x6A2416), helmL = C(0xC86444)
    let horn = C(0xC8925A), hornD = C(0x8A5E32), hornL = C(0xE8B880)
    let green = C(0x3A8A3A), greenD = C(0x266A26), greenL = C(0x62B45A), belt = C(0x5A3A22)
    let s = p.signature ?? -1
    // The crouch, then the spring: forward and up in an arc and back down where he started.
    var crouch = 0.0, jump = -1.0
    if s >= 0.05 && s < 0.4 { crouch = habitArc((s - 0.05) / 0.35, hold: 0.4) }
    if s >= 0.4 && s < 0.78 { jump = (s - 0.4) / 0.38 }
    if s >= 0.78 && s < 0.92 { crouch = 0.5 * habitArc((s - 0.78) / 0.14, hold: 0) }
    let arc = jump >= 0 ? sin(jump * .pi) : 0
    let jx = Int((arc * 6).rounded()), jy = Int((arc * 7).rounded())
    let lean = jump >= 0 ? Int((min(1, arc * 3) * 2).rounded()) : 0
    let squat = 2 + Int((crouch * 2).rounded())

    c.ox += jx; c.oy -= jy
    if jump > 0.05 && jump < 0.85 {
        // The whoosh behind him: pale streaks, see-through, so they read on a dark desktop without an outline.
        for (k, y) in [27.0, 31, 35].enumerated() {
            let len = 6 + Double(k % 2) * 3
            c.glowLine(14 - len, y, 14, y, core: C(0xF4F8FF, 0.85), glow: C(0xD8E4F8, 0.4), coreR: 0.4, glowR: 1.2)
        }
    }
    drawLegs(c, Look(), step: p.step)
    // Green armour on his shins, lit along the top, and brown boots.
    drawBoots(c, belt, step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 3, green); c.px(lx, bottom - 3, greenL); c.px(lx + 1, bottom - 1, greenD)
        }
    }
    c.oy += p.breathe + squat
    c.ox += lean
    // The axe on his back while it's put away: the haft across behind him, the head over his far shoulder.
    if p.melee == nil {
        h3Line(c, 14, 38, 20, 24, belt, 0.8)
        c.pattern(13, 21, [
            "..HHH..",
            ".HHHHH.",
            "HHHHHH.",
            "eHHHH..",
            ".eH....",
        ], ["H": C(0x9AA0AC), "e": C(0xE4E8F0)])
    }
    drawBody(c, Look(eye: ink))
    // The broad chest plate past Clawd's own sides, lit along the top, a seam down the middle, two rivets; the
    // pauldrons over his shoulders.
    c.rect(16, 33, 24, 4, green); c.rect(16, 33, 24, 1, greenL); c.rect(16, 36, 24, 1, greenD)
    c.rect(27, 34, 1, 2, greenD); c.px(19, 34, greenL); c.px(36, 34, greenD)
    c.rect(14, 31, 5, 3, green); c.rect(14, 31, 5, 1, greenL); c.rect(14, 33, 5, 1, greenD)
    c.rect(37, 31, 5, 3, green); c.rect(37, 31, 5, 1, greenL); c.rect(37, 33, 5, 1, greenD)
    c.rect(16, 37, 24, 1, belt); c.rect(26, 37, 4, 1, C(0xC8A040))
    // The helmet: a big round dome down to his brow, a ridge down its front, horns curling round at its sides.
    c.pattern(14, 18, [
        "........DDDDDDDDDD........",
        "......DHHHHHrrHHHHHD......",
        ".....DHLLHHHrrHHHHHHD.....",
        "....DHLHHHHHrrHHHHHHHD....",
        "....DHLHHHHHrrHHHHHHHD....",
        "...DHHHHHHHHrrHHHHHHHHD...",
        "...DHHHHHHHHrrHHHHHHHHD...",
        "...DHHHHHHHHrrHHHHHHHHD...",
        "...dddddddddrrddddddddd...",
        "...ddd..............ddd...",
    ], ["H": helm, "L": helmL, "D": helmD, "d": helmD, "r": helmL])
    // The horns: a thick curl either side, round from the top of the helmet, down past his cheek and forward.
    let hornRows = [
        "...lHHHH",
        ".HHHhHHH",
        "HHh.....",
        "HH......",
        "Hh..HH..",
        "HH.hlH..",
        ".HhHHh..",
        "..hhh...",
    ]
    c.pattern(10, 21, hornRows, ["H": horn, "h": hornD, "l": hornL])
    c.pattern(38, 21, hornRows.map { String($0.reversed()) }, ["H": horn, "h": hornD, "l": hornL])
    c.rect(22, 28, 2, 1, helmD); c.rect(32, 28, 2, 1, helmD)   // the helmet's shadow on his brow

    if let a = p.melee {
        c.ox -= lean
        h3Axe(c, p, angle: a, at: h3RamHand, haft: belt, haftL: C(0x7A5232), head: C(0x9AA0AC), headD: C(0x6A707C),
              edge: C(0xF0F2F8), length: 10)
    }
}

// MARK: - Man-E-Clawds

/// Man-E-Clawds: the Man of a Thousand Faces. A tall red helmet, lit along its dome and ridged down the middle, with a
/// window in its front where a drum of three faces turns: his own Clawd face, a grey robot face with a red visor and a
/// grille, and a green monster face with yellow eyes and fangs. Green armour on his chest with a red trim, red bracers
/// and red boots. Fights with his fists. Signature: the drum turns, man to robot to monster and back to man.
private func drawManEClawds(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xC8302A), redD = C(0x8A1E1A), redL = C(0xE85A4A)
    let green = C(0x3A9A4A), greenD = C(0x26703A), greenL = C(0x62BE6A)
    let s = p.signature ?? -1
    // Which faces show: a turn from one to the next at each of three moments, holding in between.
    var from = 0, offset = 0
    if s >= 0 {
        let turns: [Double] = [0.12, 0.42, 0.72]
        for (i, t0) in turns.enumerated() {
            if s >= t0 + 0.12 { from = i + 1 }
            else if s >= t0 { from = i; offset = Int(((s - t0) / 0.12 * 15).rounded()) }
        }
        if from >= 3 { from = 0; offset = 0 }
    }

    drawLegs(c, Look(), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 2, redL)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(eye: nil), armRight: p.melee == nil ? p.armRaise : 0)
    c.rect(15, 34, 3, 1, red); if p.melee == nil { c.rect(38, 34 - p.armRaise, 3, 1, red) }   // the bracers

    // The chest armour: green, lit along the top, a red trim round its top edge and a red belt with a gold buckle.
    c.rect(18, 33, 20, 4, green); c.rect(18, 34, 20, 1, greenL); c.rect(37, 33, 1, 4, greenD)
    c.rect(18, 33, 20, 1, red); c.px(18, 33, redL)
    c.rect(22, 35, 1, 2, greenD); c.rect(33, 35, 1, 2, greenD)
    c.rect(18, 37, 20, 1, redD); c.rect(26, 37, 4, 1, C(0xE0B040))

    // The helmet: a tall red dome over his head, a ridge down the middle, coming down either side of the window to
    // his jaw.
    c.pattern(17, 19, [
        ".......DDDDDDDD.......",
        ".....DHHHHHrrHHHHD....",
        "....DHLLHHHrrHHHHHD...",
        "...DHLHHHHHrrHHHHHHD..",
        "...DHLHHHHHrrHHHHHHD..",
        "..DHHHHHHHHrrHHHHHHHD.",
        "..DHHHHHHHHrrHHHHHHHD.",
        ".DHHHHHHHHHHHHHHHHHHHD",
        ".HHHddddddddddddddHHHD",
        ".HHd..............dHHD",
        ".HHd..............dHHD",
        ".HHd..............dHHD",
        ".HHd..............dHHD",
        ".HHd..............dHHD",
        ".HHHddddddddddddddHHHD",
    ], ["H": red, "L": redL, "D": redD, "d": redD, "r": redL])
    // The drum in the window: one face, or two as it turns, with a dark seam between them, shaded towards its
    // ends so it reads as round.
    let faces: [[String]] = [h3ManFace, h3RobotFace, h3MonsterFace]
    let a = faces[from % 3], b = faces[(from + 1) % 3]
    var rows: [String] = []
    for r in 0..<5 {
        let joined = Array(a[r] + "s" + b[r])
        rows.append(String(joined[offset..<(offset + 14)]))
    }
    c.pattern(21, 28, rows, h3FacePalette)
    for y in 28...32 { c.px(21, y, C(0x000000, 0.3)); c.px(34, y, C(0x000000, 0.35)) }

    if let a = p.melee {
        h3Fist(c, angle: a, trail: p.trail, sleeve: clawdOrange, cuff: red)
    }
}

/// The three faces on Man-E-Clawds's drum, 14 by 5, each filling the helmet's window.
private let h3ManFace = [
    "oooooooooooooo",
    "obbooooooobboo",
    "oKKoooooooKKoo",
    "oKKoooooooKKoo",
    "oooooooooooooO",
]
private let h3RobotFace = [
    "gggggggggggggG",
    "gVVVVVVVVVVVVG",
    "gVRRVVVVVVRRVG",
    "gVVVVVVVVVVVVG",
    "gggkgkgkgkgggG",
]
private let h3MonsterFace = [
    "mmMmmmmmmmmMmm",
    "MMMMmmmmmmMMMM",
    "mYYKmmmmmmYYKm",
    "mYYYmmmmmmYYYm",
    "mWMWMWMMWMWMWm",
]
private let h3FacePalette: [Character: Px] = [
    "o": clawdOrange, "O": clawdShade, "K": ink, "b": C(0xA04A30),
    "g": C(0x9AA0AC), "G": C(0x6A707C), "V": C(0x2A2A33), "R": C(0xFF4A3A), "k": C(0x3A3E48),
    "m": C(0x6AB040), "M": C(0x3E7A24), "Y": C(0xFFE040), "W": C(0xFFFFFF),
    "s": C(0x1A1A20),
]

// MARK: - Mekaneck

/// Mekaneck: the Masters' human periscope, who can stretch his neck to see over anything. A blue helmet, a silver
/// scope over his near eye with a glowing red lens and a short barrel out the front, blue armour over Clawd's orange
/// (a chest plate studded in silver, bracers and boots), a ribbed metal neck that shows when it stretches. Fights with
/// a wooden club bound in silver bands, which hangs at his back when it's put away. Signature: his neck telescopes
/// up, his head turns to look behind him and back, and it comes down again.
private func drawMekaneck(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A5AC0), blueD = C(0x1C3C8A), blueL = C(0x5A88E8)
    let silver = C(0xB8BCC8), silverD = C(0x7E8290), silverL = C(0xE8EAF0)
    let s = p.signature ?? -1
    let neck = s < 0 ? 0 : Int((habitArc(s, hold: 0.6) * 10).rounded())
    // Looking round, at the top: behind him for a moment, then forward again.
    let back = s > 0.36 && s < 0.6
    let sway = s > 0.25 && s < 0.75 && !back ? Int((sin((s - 0.25) * 30) * 1).rounded()) : 0

    drawLegs(c, Look(), step: p.step)
    drawBoots(c, blue, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 2, blueL)
        }
    }
    c.oy += p.breathe
    // The club at his back while it's put away.
    if p.melee == nil {
        h3Line(c, 13, 41, 17, 29, C(0x7A5232), 1.3); h3Line(c, 12.5, 40, 15.5, 31, C(0x9A6E44), 0.4)
        c.px(14, 35, silver); c.px(15, 35, silver); c.px(16, 31, silver); c.px(17, 31, silver)
    }
    // His body without its head: arms and the lower half drawn here, the head above on its neck.
    let raise = p.melee == nil ? p.armRaise : 0
    c.rect(18, 32, 20, 6, clawdOrange); c.rect(18, 37, 20, 1, clawdShade); c.rect(37, 32, 1, 6, clawdShade)
    c.rect(15, 33, 3, 3, clawdOrange); c.rect(38, 33 - raise, 3, 3, clawdOrange)
    c.rect(15, 34, 3, 1, blue); c.rect(38, 34 - raise, 3, 1, blue)   // the bracers
    // The chest plate: blue, lit along the top, shaded on the far side, a row of silver studs.
    c.rect(18, 33, 20, 4, blue); c.rect(18, 33, 20, 1, blueL); c.rect(37, 33, 1, 4, blueD)
    for x in stride(from: 20, through: 35, by: 3) { c.px(x, 35, silver) }
    c.rect(18, 37, 20, 1, C(0x3A2A1A)); c.rect(26, 37, 4, 1, silver)
    if neck > 0 {
        // The neck, ribbed metal, from his shoulders up to his head.
        c.rect(25, 32 - neck, 6, neck, silverD); c.rect(25, 32 - neck, 1, neck, silver)
        for y in stride(from: 31, through: 32 - neck, by: -2) { c.rect(25, y, 6, 1, silverL) }
        c.rect(24, 31, 8, 1, silver)   // the collar it comes up out of
    }

    // The head: the top of Clawd's block, lifted on the neck, under the blue helmet.
    let hy = -neck
    c.ox += sway
    c.rect(18, 26 + hy, 20, 6, clawdOrange); c.rect(37, 26 + hy, 1, 6, clawdShade)
    if neck > 0 { c.rect(18, 31 + hy, 20, 1, clawdShade) }
    c.pattern(17, 20 + hy, [
        ".....DDDDDDDDDDDD.....",
        "...DHHHHHHHHHHHHHHD...",
        "..DHLLHHHHHHHHHHHHHD..",
        ".DHLHHHHHHHHHHHHHHHHD.",
        ".DHLHHHHHHHHHHHHHHHHD.",
        "DHHHHHHHHHHHHHHHHHHHHD",
        "DDDDDDDDDDDDDDDDDDDDDD",
        "DH..................HD",
        "DH..................HD",
    ], ["H": blue, "L": blueL, "D": blueD])
    // The eye and the scope, on whichever side he's looking.
    let eyeX = back ? 32 : 22, scopeX = back ? 19 : 31
    c.rect(eyeX, 29 + hy, 2, 3, ink)
    c.pattern(scopeX, 28 + hy, [
        "SSSSS",
        "SrrRS",
        "SrrrS",
        "SrrrS",
        "sSSSs",
    ], ["S": silver, "s": silverD, "r": C(0xE0302A), "R": C(0xFF9A8A)])
    if back { c.rect(16, 29 + hy, 3, 2, silver); c.px(16, 29 + hy, silverL) }
    else { c.rect(36, 29 + hy, 3, 2, silver); c.px(38, 29 + hy, silverL) }
    // The lens glows a little, so it reads as a light on a dark desktop.
    let lx = Double(scopeX) + 2.5, ly = Double(30 + hy) + 0.5
    c.glowLine(lx, ly, lx, ly, core: C(0xFFB0A0, 0), glow: C(0xFF4A3A, 0.35), coreR: 0.1, glowR: 2.2)
    c.ox -= sway

    if let a = p.melee {
        // The club: a thick wooden head bound in silver, a thinner grip.
        for (i, t) in p.trail.enumerated() {
            let p0 = eterniaReach(eterniaHand, t, 5), p1 = eterniaReach(eterniaHand, t, 13)
            c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.6, glowR: 1.8,
                       strength: 0.3 / Double(i + 1))
        }
        eterniaBar(c, eterniaHand, a, from: -2, to: 5, C(0x5A3A22), r: 0.8)
        eterniaBar(c, eterniaHand, a, from: 4, to: 12, C(0x7A5232), r: 1.6)
        eterniaBar(c, eterniaHand, a, from: 4.5, to: 11.5, C(0x9A6E44), r: 0.5)
        for d in [6.0, 10.0] {
            let q = eterniaReach(eterniaHand, a, d)
            let q0 = eterniaReach(q, a + 90, 2), q1 = eterniaReach(q, a - 90, 2)
            h3Line(c, q0.x, q0.y, q1.x, q1.y, silver, 0.6)
        }
        c.rect(Int(eterniaHand.x.rounded()) - 1, Int(eterniaHand.y.rounded()) - 1, 3, 3, clawdOrange)
    }
}

// MARK: - Buzz-Off

/// Buzz-Off: the heroic bee-man of Andreenos. Yellow from head to waist, three black stripes round his middle, black
/// arms and legs, a round yellow helmet-head with big black compound eyes glinting white, two black antennae curling
/// up, and two pairs of clear wings on his back, rimmed and veined in white, a blur while they beat. Swings a battle
/// axe, black-hafted with a silver head, carried on his back when it's put away. Signature: he takes off and buzzes
/// a little loop in the air, wings a blur, and lands.
private func drawBuzzOff(_ c: PixelCanvas, _ p: Pose) {
    let yellow = C(0xF0C020), yellowD = C(0xC09010), yellowL = C(0xFFE468)
    let black = C(0x2A2420), blackL = C(0x4A443E)
    let s = p.signature ?? -1
    var lx = 0, ly = 0
    if s >= 0.08 && s < 0.92 {
        // Up a little, round a loop (forward, over the top, back and down), and back down.
        let u = (s - 0.08) / 0.84
        let rise = min(1, min(u, 1 - u) * 6) * 3
        let loop = u > 0.15 && u < 0.85 ? (u - 0.15) / 0.7 * 2 * .pi : 0
        lx = Int((rise / 3 * 2 + sin(loop) * 4).rounded())
        ly = -Int((rise + (1 - cos(loop)) * 3.5).rounded())
    }
    let buzzing = p.flying || (s >= 0.04 && s < 0.96)
    c.ox += lx; c.oy += ly

    drawLegs(c, Look(leg: black), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 39, blackL) } }   // a lit knee on each leg
    c.oy += p.breathe
    // The wings, behind him: folded flat down his back at rest; while he flies, flicking between up and down, the
    // other pair showing faintly as a blur.
    let up = Int(p.t * 26) % 2 == 0
    if buzzing {
        h3BeeWings(c, up: up, alpha: 1)
    } else {
        h3BeeWings(c, up: nil, alpha: 1)
    }
    // The axe on his back while it's put away.
    if p.melee == nil {
        h3Line(c, 15, 40, 19, 28, black, 0.8)
        c.pattern(16, 25, ["SSS.", "SSSS", ".SSe", "..e."], ["S": C(0x9AA0AC), "e": C(0xE4E8F0)])
    }
    drawBody(c, Look(body: yellow, shade: yellowD, arm: black, eye: nil), armRight: p.melee == nil ? p.armRaise : 0)
    // The stripes round his middle, and a lit run along his shoulders.
    c.rect(18, 26, 19, 1, yellowL)
    for y in [33, 35, 37] { c.rect(18, y, 20, 1, black); c.px(18, y, blackL) }
    // The eyes: big and black, compound, glinting.
    for ex in [21, 31] {
        c.pattern(ex, 28, [
            ".KK.",
            "KWKK",
            "KKkK",
            "KkKK",
            ".KK.",
        ], ["K": ink, "k": C(0x3A3048), "W": C(0xFFFFFF)])
    }
    // The helmet-head: a round yellow dome over his brow with a black band, and the antennae curling up from it.
    c.pattern(18, 22, [
        "....YYYYYYYYYYYY....",
        "..YYLLYYYYYYYYYYYY..",
        ".YLLYYYYYYYYYYYYYYd.",
        "YYYYYYYYYYYYYYYYYYYd",
        "KKKKKKKKKKKKKKKKKKKK",
    ], ["Y": yellow, "L": yellowL, "d": yellowD, "K": black])
    let wave = Int((sin(p.lt * 3) * 0.6).rounded())
    c.pattern(20, 17 + wave, [
        "KK..........KK",
        ".K..........K.",
        ".K.........K..",
        "..K.......K...",
        "..K.......K...",
    ], ["K": black])
    c.px(20, 17 + wave, yellowL); c.px(33, 17 + wave, yellowL)

    if let a = p.melee {
        h3Axe(c, p, angle: a, haft: black, haftL: blackL, head: C(0x9AA0AC), headD: C(0x6A707C), edge: C(0xF0F2F8))
        c.rect(40, 33, 3, 3, black)   // his black glove on the haft
    }
}

/// Buzz-Off's wings on his back: two pairs, `up` (raised high over his back), down (spread out behind him), or nil
/// (folded flat down his back). The rim is solid white so it keeps its outline; the membrane is faint.
private func h3BeeWings(_ c: PixelCanvas, up: Bool?, alpha: Double) {
    let rim = C(0xE8F2FF, alpha), vein = C(0xC0D4EC, alpha), skin = C(0xDDEEFF, 0.5 * alpha)
    let pal: [Character: Px] = ["R": rim, "v": vein, "m": skin]
    switch up {
    case .some(true):
        c.pattern(7, 13, [
            "........RRRR....",
            "......RRmmmmR...",
            "....RRmmmvmmR...",
            "...RmmmmvmmmR...",
            "..RmmmmvmmmR....",
            ".RmmmmvmmmR.....",
            ".RmmmvmmRR......",
            "..RRvmRR........",
            "....RR.R........",
            "........RR......",
            ".........RRR....",
            "...........RR...",
        ], pal)
    case .some(false):
        c.pattern(4, 26, [
            "...RRRRRRRR.......",
            ".RRmmmmmmmmRRRR...",
            "RmmmmvvvvmmmmmRRRR",
            "RmmvvmmmmvvvvvvvRR",
            ".RRmmmmmmmmmmRRR..",
            "...RRRRRRRRRR.....",
            "......RmmmmmRRRR..",
            ".....RmmvvvvvvRR..",
            "......RRRRRRRR....",
        ], pal)
    case .none:
        c.pattern(9, 24, [
            ".......RRR",
            "....RRRmmR",
            "..RRmmmvmR",
            ".RmmmmvmmR",
            "RmmmmvmmR.",
            "RmmmvmmR..",
            "RmmvmmR...",
            ".RvmmR....",
            ".RmmR.....",
            "..RR......",
        ], pal)
    }
}

// MARK: - Clawdfist

/// Clawdfist: the Masters' heavy-handed brawler. A huge fist of polished silver on his right arm, as big as his head,
/// its knuckles lined and lit; short black hair, a big black beard down over his chest in strands, a blue chest plate
/// with a red trim and red shoulder guards, a red belt, blue boots. He fights with the fist. Signature: he brings his
/// open hand up in front of him and thumps the metal fist into it three times, a flash at each thump.
private func drawClawdfist(_ c: PixelCanvas, _ p: Pose) {
    let blue = C(0x2A4AA8), blueD = C(0x1C3478), blueL = C(0x4A6ED0)
    let red = C(0xC0302A), redD = C(0x84201A), redL = C(0xE05A48)
    let silver = C(0xC4C8D2), silverD = C(0x868A96), silverL = C(0xF2F4F8)
    let beard = C(0x1E1A1E), beardL = C(0x46404A)
    let s = p.signature ?? -1
    let palm = s >= 0 ? habitArc(s, hold: 0.8) : 0
    // The thumps: three, the fist coming down onto the palm and bouncing back up.
    var thump = 0.0
    if s > 0.15 && s < 0.85 {
        let u = (s - 0.15) / 0.7 * 3
        thump = 1 - abs(sin(u * .pi))
    }
    let hit = s > 0.15 && s < 0.85 && thump > 0.9

    drawLegs(c, Look(), step: p.step)
    drawBoots(c, blue, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 2, blueL)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(eye: ink))
    // The chest plate, red trim along its top, red shoulder guards, the red belt.
    c.rect(18, 33, 20, 4, blue); c.rect(18, 34, 20, 1, blueL); c.rect(37, 33, 1, 4, blueD)
    c.rect(18, 33, 20, 1, red); c.px(18, 33, redL)
    c.rect(18, 37, 20, 1, red); c.rect(26, 37, 4, 1, silver)
    c.rect(15, 31, 4, 2, red); c.rect(15, 31, 4, 1, redL); c.rect(37, 31, 4, 2, red); c.rect(37, 31, 4, 1, redL); c.px(40, 32, redD)
    c.rect(15, 34, 3, 1, blue)   // a bracer on his other arm

    // The beard: big and black, from thin sideburns down his cheeks, full under his eyes and down over his chest in
    // strands, so his face still shows between it and his hair.
    c.pattern(18, 27, [
        "B..................B",
        "B..................B",
        "B..................B",
        "BB................BB",
        "BBB..BBBBBBBBBB..BBB",
        "BBBBBBlBBBBBBlBBBBBB",
        ".BBBBBBBBlBBBBBBBBB.",
        "..BBlBBBBBBBBBBlBB..",
        "....BBBBlBBlBBBB....",
        "......BBBBBBBB......",
    ], ["B": beard, "l": beardL])
    // Short black hair, cropped close over the top of his head, lit along the top; and heavy brows.
    c.pattern(18, 22, [
        ".....BBBBBBBBBB.....",
        "...BBBlBBBBBBlBBBB..",
        "..BBBBBBBBlBBBBBBBB.",
        ".BBlBBBBBBBBBBBBlBBB",
        "BBBBBBBBBBBBBBBBBBBB",
    ], ["B": beard, "l": beardL])
    c.rect(21, 28, 3, 1, beard); c.rect(32, 28, 3, 1, beard)

    if palm > 0 {
        // His open hand across in front of him, palm up, the fist above it coming down onto it.
        let px = 31 + Int((palm * 4).rounded())
        h3Line(c, 17, 34.5, Double(px), 34.5, clawdOrange, 1.2)
        c.rect(px, 33, 5, 2, clawdOrange); c.rect(px, 35, 5, 1, clawdShade); c.px(px + 4, 32, clawdOrange)
        let fy = 26 + Int((thump * 3).rounded())
        h3SilverFist(c, x: px, y: fy, silver, silverD, silverL)
        if hit {
            for (dx, dy) in [(-3.0, -1.0), (8, -1), (-2, 2), (7, 2)] {
                let x0 = Double(px) + 2.5, y0 = 32.5
                c.glowLine(x0, y0, x0 + dx, y0 + dy, core: C(0xFFFFFF, 0.9), glow: C(0xC8DCFF, 0.5), coreR: 0.3, glowR: 1.1)
            }
        }
        return
    }
    if let a = p.melee {
        // The punch: the silver forearm out from the shoulder and the great fist at its end.
        let e = eterniaReach(h3Shoulder, a, 7)
        for (i, t) in p.trail.enumerated() {
            let q = eterniaReach(h3Shoulder, t, 7)
            c.glowLine(q.x, q.y, e.x, e.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 1.2, glowR: 2.6,
                       strength: 0.3 / Double(i + 1))
        }
        h3Line(c, h3Shoulder.x - 1, h3Shoulder.y - 0.5, e.x, e.y, silverD, 1.6)
        h3SilverFist(c, x: Int(e.x.rounded()) - 2, y: Int(e.y.rounded()) - 3, silver, silverD, silverL)
    } else {
        // At his side, resting: the forearm down from the shoulder and the fist by his hip.
        c.rect(38, 32, 3, 3, silverD); c.px(38, 32, silver)
        h3SilverFist(c, x: 38, y: 33, silver, silverD, silverL)
    }
}

/// Clawdfist's silver fist, 6 by 6 with its top-left at (x, y): lit along the top and left, three knuckle lines, the
/// thumb wrapped across the front.
private func h3SilverFist(_ c: PixelCanvas, x: Int, y: Int, _ base: Px, _ dark: Px, _ light: Px) {
    c.pattern(x, y, [
        ".LLLL.",
        "LBdBdB",
        "LBdBdD",
        "LBBBBD",
        "LTTTBD",
        ".DDDD.",
    ], ["B": base, "d": dark, "D": dark, "L": light, "T": C(0xA8ACB8)])
}
