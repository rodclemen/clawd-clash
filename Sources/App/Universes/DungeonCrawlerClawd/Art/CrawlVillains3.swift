import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The player killers and rivals, the Syndicate, and a god: Lucia Mar, Frank Q, Maggie My, Hekla, Chaco, Cascadia,
// Emberus.

let crawlVillains3: [CrawlVillain: Persona] = [
    .lucia: Persona(name: "Lucia Mar", weapon: .saber, headTop: 21, signature: 3.0, draw: drawLucia),
    .frankQ: Persona(name: "Frank Q", weapon: .saber, headTop: 18, draw: drawFrankQ),
    .maggieMy: Persona(name: "Maggie My", weapon: .saber, headTop: 20, signature: 3.2, draw: drawMaggieMy),
    .hekla: Persona(name: "Hekla", weapon: .saber, bulk: 2, headTop: 20, signature: 2.6, draw: drawHekla),
    .chaco: Persona(name: "Chaco", weapon: .lightning,
                    magic: Magic(core: C(0xFFE8C8), glow: C(0xFF8A1E), jagged: false, notes: true), pivot: (47, 31),
                    headTop: 20, signature: 3.4, draw: drawChaco),
    .cascadia: Persona(name: "Cascadia", headTop: 20, signature: 2.8, callout: "Now get out there and kill, kill, kill!",
                       draw: drawCascadia),
    .emberus: Persona(name: "Emberus", weapon: .lightning,
                      magic: Magic(core: C(0xFFF0A0), glow: C(0xFF6A1A), jagged: false, thick: true), pivot: (44, 33), bulk: 3, headTop: 15, signature: 3.0, draw: drawEmberus),
]

// MARK: - Helpers

/// String art turned to `angle` degrees (0 forward, -90 straight up, as `Pose.melee`): `rows` is drawn upright, its
/// top pointing along `angle`, the point `pivot` (in pattern pixels, from its top-left) on the canvas at `at`. Every
/// canvas pixel samples the pattern, so a turned weapon has no holes in it.
private func stamp(_ c: PixelCanvas, _ rows: [String], _ palette: [Character: Px], pivot: (x: Double, y: Double),
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

/// A held weapon at `angle` from the near hand: faint copies where it was a moment ago (`trail`), then the weapon.
private func wield(_ c: PixelCanvas, _ rows: [String], _ palette: [Character: Px], pivot: (x: Double, y: Double),
                   angle: Double, trail: [Double] = []) {
    for (i, a) in trail.enumerated() {
        stamp(c, rows, palette, pivot: pivot, at: Sprite.hand, angle: a, alpha: 0.3 / Double(i + 1))
    }
    stamp(c, rows, palette, pivot: pivot, at: Sprite.hand, angle: angle)
}

/// 0 outside `a…b`, 1 inside it, easing in and out over `edge` at each end.
private func villainsArc(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    let k = min(1, (s - a) / edge, (b - s) / edge)
    return k * k * (3 - 2 * k)
}

/// A 1-pixel curve from `a` through towards `ctrl` to `b` (a whisker, a hose).
private func villainsCurve(_ c: PixelCanvas, _ a: (Double, Double), _ ctrl: (Double, Double), _ b: (Double, Double),
                           _ col: Px) {
    for i in 0...24 {
        let t = Double(i) / 24, u = 1 - t
        let x = u * u * a.0 + 2 * u * t * ctrl.0 + t * t * b.0
        let y = u * u * a.1 + 2 * u * t * ctrl.1 + t * t * b.1
        c.px(Int(x.rounded(.down)), Int(y.rounded(.down)), col)
    }
}

// MARK: - Lucia Mar

/// Lucia Mar, in her grown-up Lajabless form: Clawd with long black hair falling down her back, a lovely face (lashes,
/// fine brows, red lips), a yellow football jersey with a round collar over silver armour that shows at the arms and the
/// legs. She swings a spiked steel mace. Signature: her face flickers and flips to a bone-white skull, black
/// sockets with a red pinprick in each, holds it a moment, and flips back.
private func drawLucia(_ c: PixelCanvas, _ p: Pose) {
    let jersey = C(0xF4C820), jerseyD = C(0xC4960E), jerseyL = C(0xFFE878)
    let steel = C(0xA8AEB8), steelD = C(0x6A707C), steelL = C(0xDCE0E6)
    let hair = C(0x1E181C), hairL = C(0x40363C)
    let bone = C(0xEAE4D0), boneD = C(0xB8B09A), socket = C(0x16121A)
    let lips = C(0xB8283A)
    let s = p.signature ?? -1
    // The flip: a few frames flickering between the two faces, then the skull, then the flicker back.
    var skull = s > 0.22 && s < 0.78
    if (s > 0.12 && s <= 0.22) || (s >= 0.78 && s < 0.88) { skull = Int(p.lt * 14) % 2 == 0 }

    // 1. The legs in silver greaves, lit down their left edge, darker steel at the foot.
    drawLegs(c, Look(leg: steelD), step: p.step)
    drawBoots(c, C(0x4A505A), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 38, 1, bottom - 38, steel)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, its arms in silver; the jersey's short sleeves over the tops of them.
    drawBody(c, Look(arm: steel, eye: nil))
    c.px(15, 34, steelL); c.rect(15, 35, 3, 1, steelD); c.px(38, 34, steelL); c.rect(38, 35, 3, 1, steelD)

    // 4. The jersey: yellow, lit on the left, the far side and the hem in shade, a round collar.
    c.rect(18, 33, 20, 5, jersey)
    c.rect(18, 33, 1, 5, jerseyL); c.rect(37, 33, 1, 5, jerseyD); c.rect(18, 37, 20, 1, jerseyD)
    c.rect(15, 33, 3, 1, jerseyD); c.rect(38, 33, 3, 1, jersey)
    c.rect(23, 33, 10, 1, jerseyD); c.rect(24, 34, 8, 1, jerseyL)   // the round collar

    // 5. The face: her own, or the skull.
    if skull {
        c.rect(18, 26, 20, 7, bone)
        c.rect(37, 26, 1, 7, boneD)
        c.pattern(20, 28, [
            ".ssss.....ssss",
            "sssss.....ssss",   // (the far socket's left edge hides under her hair)
            ".sss.......sss",
        ], ["s": socket])
        c.px(22, 29, C(0xE04050)); c.px(32, 29, C(0xE04050))   // a red pinprick deep in each socket
        c.rect(20, 31, 3, 1, boneD); c.rect(32, 31, 3, 1, boneD)
        c.pattern(27, 30, [".s", "ss"], ["s": socket])          // the nose
        c.pattern(23, 32, ["sBsBsBsBsBs"], ["s": socket, "B": bone])   // the teeth
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.px(22, 29, C(0x5A4A50)); c.px(32, 29, C(0x5A4A50))
        c.px(21, 28, ink); c.px(34, 28, ink)                       // the lashes
        c.rect(21, 27, 3, 1, hair); c.rect(32, 27, 3, 1, hair)     // fine brows
        c.rect(26, 32, 4, 1, lips); c.px(27, 32, C(0xE05062))
    }

    // 6. The hair: long and black, a lit run along the crown, a fringe down the front, and the long fall down her
    //    back.
    c.pattern(14, 21, [
        "......HHHHHHHHHHHHHHHH....",
        "....HHHHlHHHHHlHHHHHHHH...",
        "...HHHlHHHHHHHHHHHHHHHHH..",
        "..HHHHHHHHHHHHHHHHHHHHHHH.",
        "..HHHHHHHHHHHHHHHHHHHHHHHH",
        "..HHHHH.............HHHHH.",
        ".HHHHH...............HHHH.",
        ".HHHH.................HHH.",
        ".HHHH..................H..",
        "HHHH......................",
        "HHHH......................",
        "HHH.......................",
        "HlH.......................",
        "HHH.......................",
        "HH........................",
        "HH........................",
        "H.........................",
    ], ["H": hair, "l": hairL])

    // 7. The mace: a spiked steel head on a dark haft, a leather grip; upright in her hand, or swung.
    let mace = [
        "...p...",
        "..SSS..",
        ".SLSSS.",
        "pSLSSDp",
        ".SSSDD.",
        "..DDD..",
        "...p...",
        "...h...",
        "...h...",
        "...h...",
        "...h...",
        "...h...",
        "...h...",
        "...h...",
        "...g...",
        "...g...",
        "...D...",
    ]
    let macePal: [Character: Px] = ["S": steel, "D": steelD, "L": steelL, "p": steelL, "h": C(0x3E3A40), "g": C(0x6A4628)]
    wield(c, mace, macePal, pivot: (3.5, 14.5), angle: p.melee ?? -75, trail: p.trail)
    c.rect(41, 34, 2, 2, steel); c.px(41, 34, steelL)   // the gauntlet round the grip
}

// MARK: - Frank Q

/// Frank Q: an elf, Clawd with purple skin and long pointed ears sticking out under a navy beanie (a lime stripe, a
/// navy cuff, a lime pompom), a mean slant to his brows, a black zip-up jacket with its collar up, dark jeans and black
/// boots. He has one hand: the far sleeve is empty, folded up and pinned. He chops with a steel battle axe.
private func drawFrankQ(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8A5CB8), skinD = C(0x6A4096), skinL = C(0xA67CD0)
    let navy = C(0x1E2A4E), navyD = C(0x141C36), navyL = C(0x34446E), lime = C(0x7ACC2A), limeL = C(0xA8EC5A)
    let jacket = C(0x24242C), jacketD = C(0x141418), jacketL = C(0x40404C)
    let steel = C(0xA8AEB8), steelD = C(0x6A707C), steelL = C(0xE4E8EE)

    // 1. Dark jeans, black boots.
    drawLegs(c, Look(leg: C(0x343C52)), step: p.step)
    drawBoots(c, C(0x141418), step: p.step, rows: 2)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in purple skin, lit on the left; no far arm, only the near one.
    c.rect(18, 26, 20, 12, skin)
    c.rect(18, 26, 1, 7, skinL); c.rect(37, 26, 1, 12, skinD)

    // 4. The ears: long and pointed, sticking out either side under the beanie.
    c.pattern(13, 23, ["P....", "PP...", ".PPP.", "..PPP"], ["P": skin])
    c.pattern(38, 23, ["....P", "...PP", ".PPP.", "PPP.."], ["P": skinD])
    c.px(14, 24, skinL)

    // 5. The jacket: black, the collar turned up and lit, a silver zip down the front, the far side in shade; the
    //    near sleeve, and the empty far one folded up and pinned.
    c.rect(18, 32, 20, 6, jacket)
    c.rect(18, 32, 1, 6, jacketL); c.rect(36, 32, 2, 6, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.pattern(22, 31, ["LLL......LLL", ".LLL....LLL.", "..d......d.."], ["L": jacketL, "d": jacketD])
    c.rect(28, 33, 1, 5, C(0x8A8E98))
    c.rect(15, 33, 3, 2, jacket); c.px(15, 33, jacketL); c.px(16, 34, C(0xC8CCD4))
    c.rect(38, 33, 3, 3, jacket); c.px(38, 33, jacketL); c.rect(38, 35, 3, 1, jacketD)

    // 6. The face: dark eyes under brows slanting down to the middle.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.pattern(20, 27, ["dd..........dd", "..dd......dd.."], ["d": skinD])
    c.rect(21, 27, 2, 1, C(0x3A1E5A)); c.rect(33, 27, 2, 1, C(0x3A1E5A))

    // 7. The beanie: navy, a lit run on top, a lime stripe round it, a ribbed navy cuff, the lime pompom.
    c.pattern(17, 17, [
        "..........ll..........",
        ".........lLLl.........",
        "......NNNNNNNNNN......",
        "....NNlNNNNNNNNNNN....",
        "...NlNNNNNNNNNNNNNNN..",
        "..NNNNNNNNNNNNNNNNNNN.",
        ".GGGGGGGGGGGGGGGGGGGGG",
        ".NNNNNNNNNNNNNNNNNNNNN",
        ".CcCcCcCcCcCcCcCcCcCc.",
        ".CcCcCcCcCcCcCcCcCcCc.",
    ], ["N": navy, "l": navyL, "G": lime, "C": navy, "c": navyD, "L": limeL])
    c.pattern(26, 17, ["..ll", ".LLl", ".lll"], ["l": lime, "L": limeL])

    // 8. The battle axe: a steel half-moon blade, its edge bright, a spike behind, on a wooden haft.
    let axe = [
        "..p.....",
        "..hSS...",
        ".dhSSSS.",
        "ddhSSSSL",
        ".dhSSSSL",
        "..hSSSSL",
        "..hSSS..",
        "..h.....",
        "..h.....",
        "..h.....",
        "..h.....",
        "..h.....",
        "..g.....",
        "..g.....",
        "..p.....",
    ]
    let axePal: [Character: Px] = ["S": steel, "d": steelD, "L": steelL, "p": steelD, "h": C(0x7A5230),
                                   "g": C(0x3A2A1E)]
    wield(c, axe, axePal, pivot: (2.5, 12.5), angle: p.melee ?? -78, trail: p.trail)
    c.rect(41, 34, 2, 2, skin); c.px(41, 34, skinL)   // his one hand
}

// MARK: - Maggie My

/// Maggie My: a rogue, Clawd in a slate-teal hooded cloak, her face showing in the hood's shadow, heavy-lidded eyes, a
/// leather belt with a silver buckle, dark leggings and soft boots. Her dagger is black with a purple halo round it.
/// Signature: her stealth field shimmers over her and she fades into it, all but gone, then shimmers back.
private func drawMaggieMy(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.06, s < 0.94 else { drawMaggieBody(c, p); return }
    var q = p
    q.signature = nil
    let fig = PixelCanvas(Sprite.width, Sprite.height)
    drawMaggieBody(fig, q)
    // She's half see-through only for a moment either way: the fade is quick, so she's solid or nearly gone.
    let gone = villainsArc(s, 0.16, 0.84, edge: 0.06)
    c.paste(fig, alpha: 1 - gone * 0.86)
    // The stealth field: a ripple of pale violet sweeping down over her as she goes, and up as she comes back, and
    // a faint glint now and then while she's hidden.
    let shimmer = villainsArc(s, 0.06, 0.94, edge: 0.12)
    let band = s < 0.5 ? 18 + (s - 0.06) / 0.16 * 26 : 44 - (0.94 - s) / 0.16 * 26
    for y in 18...44 {
        let d = abs(Double(y) - band)
        guard d < 2.5 else { continue }
        for x in 14...44 where fig.isDrawn(x, y) && (x + y) % 2 == 0 {
            c.px(x, y, C(0xD8C8FF, 0.22 * shimmer))
        }
    }
    if gone > 0.9 {
        let n = Int(p.lt * 6)
        for k in 0..<3 {
            let x = 18 + Int(noise(n * 3 + k) * 20), y = 22 + Int(noise(n * 7 + k) * 18)
            if fig.isDrawn(x, y) { c.px(x, y, C(0xE8DCFF, 0.22)) }
        }
    }
}

/// Maggie My herself (drawn into a canvas of her own and faded for her signature).
private func drawMaggieBody(_ c: PixelCanvas, _ p: Pose) {
    let cloak = C(0x3E5C62), cloakD = C(0x283E44), cloakL = C(0x5C7C80)
    let belt = C(0x4A3222), buckle = C(0xC8CCD4)
    let blade = C(0x121018), edge = C(0x4A4060), halo = C(0xA060FF)

    // 1. Dark leggings, soft black boots.
    drawLegs(c, Look(leg: C(0x2C2E38)), step: p.step)
    drawBoots(c, C(0x16161C), step: p.step, rows: 2)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, the arms in the cloak's sleeves.
    drawBody(c, Look(arm: cloak, eye: nil))
    c.px(15, 33, cloakL); c.rect(15, 35, 3, 1, cloakD); c.px(38, 33, cloakL); c.rect(38, 35, 3, 1, cloakD)

    // 4. The cloak over her body, lit on the left, folds down it, the far side in shade, and the belt with its buckle.
    c.rect(18, 32, 20, 6, cloak)
    c.rect(18, 32, 1, 6, cloakL); c.rect(36, 32, 2, 6, cloakD); c.rect(18, 37, 20, 1, cloakD)
    for x in [22, 31] { c.rect(x, 33, 1, 2, cloakD) }
    c.rect(18, 35, 18, 1, belt); c.rect(36, 35, 2, 1, C(0x32221A)); c.rect(27, 35, 2, 1, buckle)

    // 5. The face in the hood's shadow: the top of it shaded, heavy lids over dark eyes.
    c.rect(20, 27, 16, 1, clawdShade)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(22, 29, 2, 1, clawdShade); c.rect(32, 29, 2, 1, clawdShade)

    // 6. The hood: up over her head, lit along its crown, its sides falling to her shoulders, a dark rim round her face.
    c.pattern(16, 19, [
        "......CCCCCCCCCC......",
        "....CCCLLLCCCCCCCC....",
        "...CCLLCCCCCCCCCCCC...",
        "..CCLCCCCCCCCCCCCCCCC.",
        "..CLCCCCCCCCCCCCCCCCC.",
        ".CCCCCCCCCCCCCCCCCCCCC",
        ".CCCCCCCCCCCCCCCCCCCCC",
        ".CCddddddddddddddddCCC",
        ".CCd..............dCCC",
        ".CCd..............dCCd",
        ".CC...............dCCd",
        ".CC................CCd",
        ".CC................CCd",
        ".CC................CCd",
    ], ["C": cloak, "L": cloakL, "d": cloakD])

    // 7. The dagger: a short black blade, a purple halo round it.
    let dagger = [
        ".b.",
        ".Bb",
        "BBb",
        "BBb",
        "BBb",
        "BBb",
        "ggg",
        ".h.",
        ".h.",
    ]
    let pal: [Character: Px] = ["B": blade, "b": edge, "g": C(0x5A4A6A), "h": C(0x2A2230)]
    let angle = p.melee ?? -62
    for (i, a) in p.trail.enumerated() {
        let s0 = crawlReach(Sprite.hand, a, 2), s1 = crawlReach(Sprite.hand, a, 8)
        c.glowLine(s0.x, s0.y, s1.x, s1.y, core: halo.alpha(0.3 / Double(i + 1)), glow: C(0, 0), coreR: 1, glowR: 1.1)
    }
    let s0 = crawlReach(Sprite.hand, angle, 2.5), s1 = crawlReach(Sprite.hand, angle, 8)
    let pulse = 0.8 + 0.2 * sin(p.lt * 5)
    c.glowLine(s0.x, s0.y, s1.x, s1.y, core: halo.alpha(0.55 * pulse), glow: halo.alpha(0.5 * pulse), coreR: 1.4, glowR: 2.8)
    stamp(c, dagger, pal, pivot: (1.5, 7.5), at: Sprite.hand, angle: angle)
    c.rect(41, 34, 2, 2, clawdOrange); c.px(42, 35, clawdShade)
}

// MARK: - Hekla

/// Hekla: an Amazon shieldmaiden, Clawd built like a bodybuilder: big bare arms, a bronze muscle cuirass, a leather
/// skirt of strips, leather sandals. Blonde hair with a bronze band through it and a thick braid down her back, strong
/// brows over sapphire-blue eyes. A spear in her near hand, a round wooden shield with a steel rim and boss on her far
/// arm. Signature: she brings the shield up in front of her, a glint across its boss, and lowers it.
private func drawHekla(_ c: PixelCanvas, _ p: Pose) {
    let bronze = C(0xC88A3A), bronzeD = C(0x8E5A22), bronzeL = C(0xEEB868)
    let leather = C(0x6A4428), leatherD = C(0x482C18)
    let hair = C(0xE8C860), hairD = C(0xB8943A), hairL = C(0xFAE8A2)
    let wood = C(0x8A5A32), woodD = C(0x643E22), steel = C(0xA8AEB8), steelL = C(0xE4E8EE), steelD = C(0x6A707C)
    let sapphire = C(0x2A60E8), sapphireL = C(0x9CC0FF), sapphireD = C(0x143488)
    let s = p.signature ?? -1
    let raise = villainsArc(s, 0.08, 0.9, edge: 0.2)

    // 1. Bare legs, the sandals' soles and a strap.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, leather, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // The shield: round, wood planks, a steel rim and boss. Behind her on the far arm, or brought up in front.
    func shield(_ cx: Int, _ cy: Int, glint: Bool) {
        c.circle(cx, cy, 7, steel)
        c.circle(cx, cy, 6, wood)
        c.rect(cx - 5, cy - 2, 11, 1, woodD); c.rect(cx - 5, cy + 2, 11, 1, woodD)
        c.px(cx - 4, cy - 6, steelL); c.px(cx - 6, cy - 3, steelL); c.px(cx + 5, cy + 5, steelD); c.px(cx + 6, cy + 3, steelD)
        c.circle(cx, cy, 1, steel); c.px(cx - 1, cy - 1, steelL)
        if glint { c.px(cx, cy, C(0xFFFFFF)); c.px(cx + 1, cy - 1, C(0xFFFFFF, 0.7)); c.px(cx - 1, cy + 1, C(0xFFFFFF, 0.7)) }
    }
    let sx = Int((11 + raise * 27).rounded()), sy = Int((31 - raise * 2).rounded())
    if raise < 0.5 { shield(sx, sy, glint: false) }

    // 3. The braid down her back, in twists.
    for (i, y) in stride(from: 26, through: 36, by: 2).enumerated() {
        c.rect(15, y, 3, 2, hair); c.px(15, y, hairL); c.px(17, y + 1, hairD)
        if i == 5 { c.rect(15, y + 1, 3, 1, bronze) }
    }

    // 4. The body and the big arms: the near one a bulging upper arm with a bronze bracer at the wrist.
    drawBody(c, Look(eye: nil))
    c.rect(14, 32, 4, 4, clawdOrange); c.px(14, 32, C(0xE8957A)); c.rect(14, 35, 4, 1, clawdShade)
    c.rect(38, 31, 4, 5, clawdOrange); c.rect(38, 31, 3, 1, C(0xE8957A)); c.rect(38, 35, 4, 1, clawdShade)
    c.px(40, 33, clawdShade)

    // 5. The muscle cuirass: bronze, lit on top and the left, the pecs and the line of the abs moulded in.
    c.rect(18, 32, 20, 4, bronze)
    c.rect(18, 32, 20, 1, bronzeL); c.rect(18, 32, 1, 4, bronzeL); c.rect(36, 32, 2, 4, bronzeD)
    c.pattern(21, 33, ["dddd..dddd..", ".....dd.....", "...d....d..."], ["d": bronzeD])

    // 6. The skirt: leather strips over the tops of her legs, a bronze stud on each.
    for x in stride(from: 18, to: 38, by: 3) {
        c.rect(x, 36, 2, 3, leather); c.px(x + 1, 38, leatherD); c.px(x, 36, bronzeL)
    }
    c.rect(18, 36, 20, 1, leatherD)

    // 7. The face: strong brows, sapphire eyes with a glint.
    c.rect(21, 27, 4, 1, hairD); c.rect(31, 27, 4, 1, hairD)
    for x in [22, 32] {
        c.rect(x, 29, 2, 3, sapphire); c.px(x, 29, sapphireL); c.rect(x, 31, 2, 1, sapphireD); c.px(x + 1, 30, ink)
    }

    // 8. The hair: blonde, a lit run on top, the bronze band through it, a little fall at the back.
    c.pattern(16, 20, [
        ".....HHHHHHlHHHHHH.....",
        "...HHlHHHHHHHHHlHHHH...",
        "..HHHHHlHHHHHHHHHHHHH..",
        ".HBBBBBBBBBBBBBBBBBBBB.",
        ".HHHHHhHHHHhHHHHHhHHHH.",
        ".HHH..............HHH..",
    ], ["H": hair, "h": hairD, "l": hairL, "B": bronze])

    // 9. The spear: a steel leaf-shaped head on a long wooden haft, bound below the head.
    let spear = [
        ".L.",
        "LSS",
        "LSS",
        "LSD",
        ".S.",
        ".k.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".h.",
        ".D.",
    ]
    let spearPal: [Character: Px] = ["S": steel, "L": steelL, "D": steelD, "k": leatherD, "h": C(0x9A6A3A)]
    wield(c, spear, spearPal, pivot: (1.5, 18.5), angle: p.melee ?? -88, trail: p.trail)
    c.rect(41, 34, 2, 2, clawdOrange); c.px(41, 35, clawdShade); c.rect(40, 33, 1, 3, bronze)

    if raise >= 0.5 { shield(sx, sy, glint: s > 0.4 && s < 0.6 && Int(p.lt * 10) % 2 == 0) }
}

// MARK: - Chaco

/// Chaco: a wolf-headed showman with bat wings, Clawd with grey fur, tall pointed ears, a long snout with a black nose,
/// amber eyes, and a pair of leathery dark bat wings folded up behind him. He wears a brown leisure suit checked in
/// orange, wide brown lapels and a big cream shirt collar, and white loafers. A microphone in his hand: his Song Bard
/// sends music at his foes in orange. Signature: he steps out of shot, runs back in, grins with all his sharp teeth
/// and announces into the mic.
private func drawChaco(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x82808A), furD = C(0x5E5C66), furL = C(0xA8A6B0), muzzle = C(0xC8C4CC)
    let brown = C(0x6E4020), check = C(0xD8782A), lapel = C(0x4A2A14), cream = C(0xF0E4C8)
    let wing = C(0x4E3446), wingL = C(0x6A4A5E), bone = C(0x2A1A26)
    let s = p.signature ?? -1
    // The beats: out of shot to the left by 0.16, back in by 0.38, then the grin and the announcement.
    var shift = 0.0
    if s > 0 && s < 0.16 { shift = -pow(s / 0.16, 2) * 52 }
    if s >= 0.16 && s < 0.38 { shift = -(1 - (s - 0.16) / 0.22) * 52 }
    let running = s > 0 && s < 0.38
    let announcing = s >= 0.4 && s < 0.94
    let grin = announcing || p.melee != nil || p.zap == true
    c.ox += Int(shift.rounded())
    let step = running ? Int(s * 40) % 2 : p.step

    // 1. The suit's trousers, checked, and white loafers.
    drawLegs(c, Look(leg: brown), step: step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = step >= 0 && i % 2 == step ? 42 : 43
            c.rect(lx, 38, 2, 1, check); c.px(lx + 1, 40, check)
            c.rect(lx, bottom, 2, 1, cream); c.px(lx + 2, bottom, cream)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The wing, folded up behind him: a dark leathery membrane between its bones, its lower edge scalloped,
    //    stirring a little.
    let flap = Int((sin(p.lt * 2.1) * 1.2).rounded())
    let wrist = (13.0, 15.0 + Double(flap)), shoulder = (20.0, 27.0)
    let tips = [(3.0, 18.0 + Double(flap)), (3.0, 27.0), (8.0, 35.0), (18.0, 35.0)]
    let poly = [shoulder, wrist] + tips
    func inside(_ x: Double, _ y: Double) -> Bool {
        var hit = false
        for i in 0..<poly.count {
            let a = poly[i], b = poly[(i + 1) % poly.count]
            if (a.1 > y) != (b.1 > y), x < a.0 + (y - a.1) / (b.1 - a.1) * (b.0 - a.0) { hit.toggle() }
        }
        guard hit else { return false }
        // The scallops between the fingers' tips.
        for i in 0..<3 {
            let a = tips[i], b = tips[i + 1]
            let ex = b.0 - a.0, ey = b.1 - a.1, len2 = ex * ex + ey * ey
            let t = ((x - a.0) * ex + (y - a.1) * ey) / len2
            guard t > 0, t < 1 else { continue }
            let d = abs((x - a.0) * ey - (y - a.1) * ex) / len2.squareRoot()
            if d < 2.6 * sin(t * .pi) { return false }
        }
        return true
    }
    for y in 12...36 {
        for x in 1...20 where inside(Double(x) + 0.5, Double(y) + 0.5) {
            c.px(x, y, y < Int(wrist.1) + 4 && x > 6 ? wingL : wing)
        }
    }
    c.glowLine(shoulder.0, shoulder.1, wrist.0, wrist.1, core: bone, glow: C(0, 0), coreR: 0.9, glowR: 1)
    for t in tips.prefix(3) { c.glowLine(wrist.0, wrist.1, t.0, t.1, core: bone, glow: C(0, 0), coreR: 0.5, glowR: 0.6) }

    // 4. The body: grey fur, lit along the top in short strokes.
    drawBody(c, Look(body: fur, shade: furD, arm: brown, eye: nil))
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 6, furL)
    for x in [21, 26, 31] { c.px(x, 27, furL); c.px(x + 1, 27, furD) }

    // 5. The suit: brown checked in orange, the far side in shade, wide dark lapels and the big cream collar.
    c.rect(18, 33, 20, 5, brown)
    for y in 33...37 { for x in 18...37 where (x - 18) % 4 == 1 || (y - 33) % 3 == 1 { c.px(x, y, check) } }
    c.rect(36, 33, 2, 5, C(0x5A3418)); c.rect(18, 37, 20, 1, C(0x5A3418))
    c.pattern(22, 33, [
        "CCCLLL..LLLCCC",
        ".CCLLL..LLLCC.",
        "...LLLccLLL...",
        "....LLccLL....",
        ".....LLLL.....",
    ], ["C": cream, "L": lapel, "c": cream])
    c.rect(15, 33, 3, 3, brown); c.px(16, 34, check); c.rect(38, 33, 3, 3, brown); c.px(39, 34, check)

    // 6. The ears: tall and pointed, dark inside.
    c.pattern(18, 20, ["F....", "FF...", "FiF..", "FiFF.", "FFFFF", "FFFFF"], ["F": fur, "i": C(0x3A3040)])
    c.pattern(29, 20, ["....F", "...FF", "..FiF", ".FFiF", "FFFFF", "FFFFF"], ["F": furD, "i": C(0x3A3040)])
    c.px(18, 20, furL)

    // 7. The snout, long and reaching forward, the black nose at its tip; the mouth a dark line, or the grin, wide
    //    open with its sharp white teeth.
    c.pattern(32, 27, [
        "FFFFFF.......",
        "LLLLLLLLLLL..",
        "FFFFFFFFFFFNN",
        "FFFFFFFFFFFNN",
        "MMMMMMMMMMMM.",
    ], ["F": fur, "L": furL, "N": ink, "M": muzzle])
    if grin {
        c.pattern(29, 31, [
            "mTmTmTmTmTmTmT.",
            "mmmmmmmmmmmmmm.",
            ".mTmTmTmTmTmTm.",
            "..MMMMMMMMMMM..",
        ], ["m": C(0x4A1A24), "T": C(0xFFFFFF), "M": muzzle])
    } else {
        c.rect(32, 31, 12, 1, C(0x2A2430)); c.rect(32, 32, 11, 1, muzzle)
    }
    // The eyes: amber, a black pupil, a heavy brow.
    for x in [21, 30] {
        c.rect(x, 28, 2, 2, C(0xF0A020)); c.px(x + 1, 28, ink); c.px(x + 1, 29, ink)
        c.rect(x - 1, 27, 4, 1, furD)
    }

    // 8. The microphone: low in his hand, or up at his snout as he announces (and as he sings his Song Bard).
    let mic = C(0x222226), mesh = C(0xB8BCC4), meshD = C(0x7A7E88)
    if announcing || p.zap != nil {
        c.rect(41, 32, 2, 3, brown)
        c.glowLine(42, 33.5, 45.5, 31.5, core: mic, glow: C(0, 0), coreR: 0.7, glowR: 0.8)
        c.rect(45, 29, 3, 3, mesh); c.px(47, 31, meshD); c.px(45, 29, C(0xFFFFFF))
        c.rect(41, 33, 2, 2, fur)
    } else {
        c.rect(41, 34, 2, 2, fur)
        c.rect(43, 33, 3, 1, mic); c.rect(46, 32, 2, 3, mesh); c.px(47, 34, meshD)
    }
    if announcing, Int(p.lt * 8) % 3 != 0 {
        for i in 0..<3 {
            let x = 51 + i * 2
            c.px(x, 27 - i, C(0xFFD8A0, 0.9)); c.px(x, 33 + i, C(0xFFD8A0, 0.9)); c.px(x + 1, 30, C(0xFFD8A0, 0.9))
        }
    }
}

// MARK: - Cascadia

/// Cascadia: a little catfish alien, Clawd in olive-green skin with a cream belly, a dorsal fin along the top of her
/// head, a forked tail fin behind, small beady eyes and long dark whiskers trailing from the corners of her mouth.
/// Over her mouth a steel rebreather, a teal filter at either side. A bottle of tequila in her fin.
/// Signature: she tips the bottle to the rebreather's port and takes a long swig, eyes screwed shut.
private func drawCascadia(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x6E7A44), skinD = C(0x525C30), skinL = C(0x8C9A5C), belly = C(0xDCD2A8), bellyD = C(0xB8AE84)
    let steel = C(0x8A9298), steelD = C(0x5A6268), steelL = C(0xC8D0D4)
    let whisker = C(0x2E2A1C)
    let s = p.signature ?? -1
    let swig = villainsArc(s, 0.08, 0.86, edge: 0.18)
    let gulping = s > 0.28 && s < 0.7

    // 1. Olive legs, darker toes.
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, skinD, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail fin behind her, forked.
    c.pattern(8, 28, [
        "Ll......",
        ".Lll....",
        "..llll..",
        "...lllll",
        "...lllll",
        "..llll..",
        ".Lll....",
        "Ll......",
    ], ["l": skinD, "L": skinL])

    // 4. The body: olive, lit on the left and top in strokes, the cream belly.
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 26, 20, 1, skinL); c.rect(18, 26, 1, 8, skinL)
    for (x, y) in [(21, 27), (27, 27), (33, 27)] { c.rect(x, y, 2, 1, skinL) }
    c.rect(20, 35, 16, 3, belly); c.rect(20, 37, 16, 1, bellyD)
    c.px(15, 33, skinL); c.rect(15, 35, 3, 1, skinD)

    // 5. The dorsal fin along the top of her head, its rays picked out.
    c.pattern(21, 20, [
        "......L.....",
        "....LLl.....",
        "..LLlllL....",
        ".LlllllllL..",
        "LllllllllllL",
        "llllllllllll",
    ], ["l": skin, "L": skinL])
    for x in [24, 27, 30] { c.rect(x, 22, 1, 4, skinD) }

    // 6. The eyes: small and beady, shut tight while she swigs.
    if gulping {
        c.rect(21, 30, 3, 1, ink); c.rect(32, 30, 3, 1, ink)
    } else {
        c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.px(22, 29, C(0xE8E4B0)); c.px(32, 29, C(0xE8E4B0))
    }

    // 7. The whiskers: long and dark, from the corners of her mouth, drooping and swaying.
    let sway = sin(p.lt * 1.6) * 1.2
    villainsCurve(c, (17, 32), (12, 32), (10, 40 + sway), whisker)
    villainsCurve(c, (38, 32), (44, 31), (47, 40 - sway), whisker)

    // 8. The rebreather: a steel mask over her mouth with a teal filter at each side and a port in the middle.
    c.rect(20, 32, 16, 3, steel); c.rect(20, 32, 16, 1, steelL); c.rect(20, 34, 16, 1, steelD)
    c.rect(18, 32, 2, 3, C(0x3A8A9A)); c.rect(36, 32, 2, 3, C(0x2A6A78))
    c.rect(27, 33, 2, 2, ink)

    // 9. The tequila: a clear bottle, pale gold inside, a cream label with a red band, a red cap. Upright in her fin,
    //    or tipped to the port for a swig.
    let bottle = [
        ".rr.",
        ".gg.",
        ".gg.",
        "gGGg",
        "gTTg",
        "lllL",
        "lRRL",
        "gTTg",
        "gTTg",
        "gggg",
    ]
    let pal: [Character: Px] = ["r": C(0xC82A2A), "g": C(0xC8E4E8), "G": C(0xF2FAFA), "T": C(0xE8C050),
                                "l": C(0xF2EAD2), "L": C(0xC8BEA4), "R": C(0xC82A2A)]
    let bx = 42.0 - swig * 6, by = 33.0 - swig * 8
    stamp(c, bottle, pal, pivot: (2, 6), at: (bx, by), angle: -90 + swig * 215)
    c.rect(Int(bx.rounded()) - 1, Int(by.rounded()), 2, 2, skin)
    c.rect(38, 33, 3, 3, skin); c.px(38, 33, skinL)
}

// MARK: - Emberus

/// Emberus: a god of fire, a man-shaped mass of it on Clawd's frame: red at the edges, orange inside, a yellow-white
/// heart at his chest, tongues of flame licking up off his head and shoulders, fiery legs. A great charred horn curls
/// up off his brow, smoke rising off its tip, and where his eyes were there are only dark pits of smoke, wisps
/// curling up out of them. He hurls a ray of fire from his palm. Signature: he flares up, the flames roaring twice
/// as high and white-hot, the horn smoking hard.
private func drawEmberus(_ c: PixelCanvas, _ p: Pose) {
    let redD = C(0x8A1C12), red = C(0xD23A1C), orange = C(0xF4801E), yellow = C(0xFFC63A), white = C(0xFFF2B0)
    let char = C(0x2E2624), charL = C(0x5A4A42), smoke = C(0x4A4040)
    let s = p.signature ?? -1
    let flare = villainsArc(s, 0.06, 0.94, edge: 0.18)
    let t = p.lt

    // 1. The legs: flame, orange down their left edge, red at the foot.
    drawLegs(c, Look(leg: red), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 36, 1, bottom - 36, orange); c.px(lx + 1, bottom, redD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Sparks thrown off as he flares.
    if flare > 0 {
        for (x, y) in [(12, 20), (44, 18), (9, 30), (47, 27)] where Int(p.lt * 9 + Double(x)) % 3 != 0 {
            c.px(x, y - Int(flare * 3), C(0xFFD060, 0.9 * flare))   // sparks thrown off
        }
    }

    // 4. The tongues of flame off his head and shoulders: red outside, orange in, yellow at the roots, flickering,
    //    and twice as high as he flares.
    let tongues: [(x: Double, h: Double)] = [(17, 5), (21.5, 8), (26.5, 10), (31, 8), (35.5, 6), (39, 3)]
    for (i, tg) in tongues.enumerated() {
        let fi = Double(i)
        let h = tg.h * (1 + flare * 0.8) + sin(t * (7 + fi) + fi * 2.1) * 1.5
        let lean = sin(t * 3 + fi) * 0.8
        let top = 26 - h
        for y in Int(top.rounded())...26 {
            let k = (26 - Double(y)) / h                  // 0 at the roots, 1 at the tip
            let half = 2.6 * (1 - k) + 0.4
            let cx = tg.x + lean * k
            let x0 = Int((cx - half).rounded()), x1 = Int((cx + half).rounded())
            guard x1 >= x0 else { continue }
            c.rect(x0, y, x1 - x0 + 1, 1, red)
            if k < 0.75 && x1 - x0 >= 2 { c.rect(x0 + 1, y, x1 - x0 - 1, 1, orange) }
            if k < 0.35 && x1 - x0 >= 4 { c.rect(x0 + 2, y, x1 - x0 - 3, 1, flare > 0.5 ? white : yellow) }
        }
    }

    // 5. The body: red at the edges and deep red in shade, orange through it, the yellow-white heart at his chest
    //    (wider as he flares), a few licks of orange rising through the red.
    drawBody(c, Look(body: red, shade: redD, arm: red, eye: nil))
    c.rect(36, 26, 2, 12, redD)
    c.rect(20, 26, 15, 11, orange)
    let heart = Int((flare * 2).rounded())
    c.pattern(22, 32 - heart, [
        "....YY....",
        "..YYYYYY..",
        ".YYYWWYYY.",
        "YYYWWWWYYY",
        ".YYYWWYYY.",
    ], ["Y": yellow, "W": white])
    if heart > 0 { c.rect(22, 37 - heart, 10, heart, yellow) }
    for (i, x) in [21, 28, 33].enumerated() {
        let y = 33 + Int((sin(t * 6 + Double(i) * 2) * 1.5).rounded())
        c.rect(x, y, 1, 3, yellow)
    }
    c.rect(15, 33, 3, 3, red); c.px(15, 33, orange)
    c.rect(38, 33, 4, 3, orange); c.rect(39, 34, 3, 1, yellow); c.rect(38, 35, 4, 1, red)

    // 6. Where his eyes were: dark pits of smoke, wisps curling up out of them.
    c.pattern(21, 28, ["sSs", "SSS", "sSs"], ["s": charL, "S": smoke])
    c.pattern(31, 28, ["sSs", "SSS", "sSs"], ["s": charL, "S": smoke])
    for i in 0..<4 {
        let k = (t * 0.7 + Double(i) * 0.25).truncatingRemainder(dividingBy: 1)
        let y = 27 - Int(k * 8), dx = Int((sin(k * 6 + Double(i)) * 1.2).rounded())
        let a = 0.24 * (1 - k)
        c.px(22 + dx, y, C(0x6A6060, a)); c.px(32 + dx, y, C(0x6A6060, a))
    }

    // 7. The horn: charred black, curling up off his brow, ridged, its tip smoking.
    c.pattern(31, 15, [
        ".......c",
        "......cc",
        ".....cC.",
        "....ccC.",
        "...cCc..",
        "...cC...",
        "..cCc...",
        "..cC....",
        ".ccC....",
        ".cCC....",
        "cccC....",
    ], ["c": char, "C": charL])
    let puffs = 3 + Int(flare * 3)
    for i in 0..<puffs {
        let k = (t * (0.5 + flare * 0.5) + Double(i) / Double(puffs)).truncatingRemainder(dividingBy: 1)
        let x = 39 + Int((k * 5 + sin(k * 5 + Double(i)) * 1.5).rounded()), y = 13 - Int(k * 9)
        c.circle(x, y, 1 + Int(k * 2), C(0x8A8484, 0.22 * (1 - k)))
    }
}
