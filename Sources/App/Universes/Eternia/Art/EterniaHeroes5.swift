import Foundation

// Heroes: the rest of the Masters of the Universe, from Roboto to Granamyr, and Gwildor from the 1987 film. Drawn the
// same way as EterniaHeroes1.swift: Clawd in costume, the armour, moss, scales and robes over the blocky body. Granamyr
// is the one creature of the lot: an old dragon on Clawd's four legs, his long neck and head reaching up in front.

let eterniaHeroes5: [EterniaHero: Persona] = [
    .roboto: Persona(name: "Roboto", weapon: .blaster, shot: .energy(core: C(0xE6FFFF), glow: C(0x18C8E8)),
                     armoured: true, muzzle: (49, 33), handGun: false, headTop: 17, signature: 3.0, draw: drawRoboto),
    .mossClawd: Persona(name: "Moss Clawd", weapon: .saber, headTop: 17, signature: 3.6, draw: drawMossClawd),
    .syClawdne: Persona(name: "Sy-Clawdne", weapon: .lightning,
                        magic: Magic(core: C(0xF8FCFF), glow: C(0x8EC8F0), jagged: false, waves: true),
                        headTop: 10, signature: 3.2, draw: drawSyClawdne),
    .snoutSpout: Persona(name: "Snout Spout", weapon: .blaster, shot: .beam(core: C(0xF4FAFF), glow: C(0x2A7AE8)),
                         muzzle: m5SnoutTip, handGun: false, headTop: 19, signature: 3.6, draw: drawSnoutSpout),
    .zodac: Persona(name: "Zodac", weapon: .blaster, shot: .energy(core: C(0xF6E8FF), glow: C(0x9A3AF0)),
                    muzzle: (49, 33), headTop: 17, signature: 4.2, draw: drawZodac),
    .granamyr: Persona(name: "Granamyr", weapon: .blaster, motion: .fly, shot: .fire, muzzle: m5GranamyrJaws,
                       handGun: false, bulk: 10, headTop: 4, signature: 3.8, draw: drawGranamyr),
    .gwildor: Persona(name: "Gwildor", headTop: 20, signature: 3.6, callout: "Have key, will travel!", draw: drawGwildor),
]

// MARK: - Shared bits

private let m5None = C(0, 0)

/// A solid line from one point to another, `r` from its centre (a trunk, a vine, a neck).
private func m5Line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px,
                    _ r: Double = 0.8) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: m5None, coreR: r, glowR: r + 0.1)
}

/// How far round something has turned by `u` (0…1) of a move that speeds up from a standstill and slows back down
/// to one: `turns` turns in all, the fastest in the middle.
private func m5Spin(_ u: Double, turns: Double) -> Double {
    let v = min(1, max(0, u))
    return turns * (v - sin(2 * .pi * v) / (2 * .pi))
}

/// A cog with its centre at (`cx`, `cy`) turned `angle` radians: a disc shaded on its lower right, teeth round its
/// rim and a dark spoke across it, so the turning shows even at 1×.
private func m5Gear(_ c: PixelCanvas, cx: Double, cy: Double, r: Double, teeth: Int, angle: Double,
                    body: Px, dark: Px, light: Px, spoke: Px) {
    let n = Int(r.rounded(.up)) + 1
    for y in -n...n {
        for x in -n...n {
            let dx = Double(x) + 0.5, dy = Double(y) + 0.5
            let d = sqrt(dx * dx + dy * dy)
            guard d <= r - 0.5 else { continue }
            c.px(Int(cx) + x, Int(cy) + y, d > r - 1.5 && dx + dy > 0 ? dark : body)
        }
    }
    for k in 0..<teeth {
        let a = angle + Double(k) / Double(teeth) * 2 * .pi
        c.px(Int((cx + 0.5 + cos(a) * r).rounded(.down)), Int((cy + 0.5 + sin(a) * r).rounded(.down)), light)
    }
    let sx = cos(angle) * (r - 1), sy = sin(angle) * (r - 1)
    m5Line(c, cx + 0.5 - sx, cy + 0.5 - sy, cx + 0.5 + sx, cy + 0.5 + sy, spoke, 0.45)
}

// MARK: - Roboto

/// Roboto: the Masters' heroic robot, built by Man-At-Clawds. A chrome head with a red crest along its dome, a black
/// visor with two red eye lights, and a big snapping jaw of square white teeth; a see-through chest of tinted glass in
/// a chrome frame with a gold cog and a red cog turning inside it, navy-blue arms and legs with chrome joints. His
/// front arm ends in a chrome laser cannon with a cyan lens that fires cyan bolts. Signature: the cogs in his chest
/// spin faster and faster, his jaw chomping in time with them, a puff of steam out of his crest, then wind down.
private func drawRoboto(_ c: PixelCanvas, _ p: Pose) {
    let navy = C(0x2A4A9A), navyD = C(0x1C3270), navyL = C(0x4A6EC0)
    let chrome = C(0xC4C8D2), chromeD = C(0x80848F), chromeL = C(0xF0F2F6)
    let red = C(0xD0342C), redD = C(0x8A1E1A), redL = C(0xF06A56)
    let glass = C(0x1E3446), glassL = C(0x4A7690)
    let s = p.signature ?? -1
    // The cogs turn slowly all the time; through the signature they wind up to a whirl and back.
    let base = p.lt * 1.4
    let rush = s < 0 ? 0 : m5Spin((s - 0.05) / 0.9, turns: 5) * 2 * .pi
    let angle = base + rush
    let fast = s > 0.2 && s < 0.85
    let open = fast ? Int((abs(sin(angle * 0.5)) * 2.4).rounded(.down)) : 0

    drawLegs(c, Look(leg: navy), step: p.step)
    drawBoots(c, navyD, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 4, chromeL); c.px(lx + 1, bottom - 4, chromeD)   // a chrome knee joint
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: navy, shade: navyD, arm: navy, eye: nil))

    // The head: a chrome dome lit on the left, the red crest along its top, a black visor band with two red eye
    // lights in it.
    c.pattern(18, 17, [
        ".......rrRRRRRR.......",
        ".....rRRRRRRRRRRd.....",
        "...HHHHHHHHHHHHHHHH...",
        "..HLLHHHHHHHHHHHHHHD..",
        ".HLHHHHHHHHHHHHHHHHHD.",
        ".HLHHHHHHHHHHHHHHHHHD.",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "HHHHHHHHHHHHHHHHHHHHDD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "DDDDDDDDDDDDDDDDDDDDDD",
    ], ["H": chrome, "L": chromeL, "D": chromeD, "R": red, "r": redL, "d": redD])
    c.rect(18, 26, 22, 2, C(0x14141A))
    c.rect(21, 26, 3, 2, red); c.px(21, 26, redL)
    c.rect(32, 26, 3, 2, red); c.px(32, 26, redL)
    c.glowLine(22.5, 27, 22.5, 27, core: C(0xFF8A7A, 0), glow: C(0xFF3A2A, 0.3), coreR: 0.1, glowR: 2.2)
    c.glowLine(33.5, 27, 33.5, 27, core: C(0xFF8A7A, 0), glow: C(0xFF3A2A, 0.3), coreR: 0.1, glowR: 2.2)

    // The chest: a chrome frame round tinted glass, two cogs turning behind it, a glint in the glass's corner.
    c.rect(18, 31, 20, 7, chromeD); c.rect(18, 31, 20, 1, chrome); c.rect(18, 31, 1, 7, chrome)
    c.rect(19, 32, 18, 5, glass)
    m5Gear(c, cx: 23, cy: 34, r: 3.1, teeth: 7, angle: angle, body: C(0xF0B83A), dark: C(0xB0801E),
           light: C(0xFFEC9A), spoke: C(0x6A4810))
    m5Gear(c, cx: 31, cy: 34, r: 2.7, teeth: 6, angle: -angle * 1.3, body: C(0xE8503E), dark: C(0x9A2A1C),
           light: C(0xFFA088), spoke: C(0x5A1410))
    c.rect(19, 32, 18, 5, C(0x7AB0D0, 0.08))
    c.px(35, 32, glassL); c.px(34, 32, glassL); c.px(35, 33, glassL)

    // The jaw: a row of square teeth fixed under the visor, the lower jaw dropping open on a dark maw as he chomps.
    if open > 0 { c.rect(21, 29, 14, open + 1, C(0x3A1418)) }
    c.pattern(20, 28, [
        "WsWsWsWsWsWsWsWs",
    ], ["W": C(0xF4F4F0), "s": C(0x9A9CA4)])
    c.pattern(20, 29 + open, [
        "WsWsWsWsWsWsWsWs",
        "SSLSSSSSSSSSSSSD",
    ], ["S": chrome, "L": chromeL, "D": chromeD, "W": C(0xF4F4F0), "s": C(0x9A9CA4)])

    // The steam out of his crest while the cogs whirl: pale puffs drifting up and back.
    if fast {
        for k in 0..<3 {
            let f = frac(p.t * 1.6 + Double(k) / 3)
            let x = 26 - f * 6 + Double(k), y = 16 - f * 9
            c.glowLine(x, y, x, y, core: C(0xF4F6FA, 0.55 * (1 - f)), glow: C(0xD8DEE8, 0.35 * (1 - f)),
                       coreR: 0.8 + f, glowR: 1.8 + f)
        }
    }

    // His back arm: a chrome cuff and a three-fingered grip.
    c.rect(15, 33, 3, 1, chrome); c.px(15, 33, chromeL); c.px(15, 34, navyL)
    c.pattern(14, 35, ["S.S", "SSS"], ["S": chromeD])

    // The laser cannon on his front arm: a chrome housing, a barrel, the cyan lens glowing at its end.
    c.oy += p.gunY
    c.rect(38, 32, 5, 4, chrome); c.rect(38, 32, 5, 1, chromeL); c.rect(38, 35, 5, 1, chromeD)
    c.rect(40, 32, 1, 4, navy)
    c.rect(43, 32, 5, 3, chromeD); c.rect(43, 32, 5, 1, chrome); c.px(45, 33, C(0x5A5E6A))
    c.rect(48, 32, 1, 3, C(0x18C8E8)); c.px(48, 33, C(0xC8FFFF))
    c.glowLine(48.5, 33.5, 48.5, 33.5, core: C(0xC8FFFF, 0), glow: C(0x18C8E8, 0.4), coreR: 0.1, glowR: 2.4)
    c.oy -= p.gunY
}

// MARK: - Moss Clawd

/// Moss Clawd: the Masters' spy, who blends into any forest. Shaggy green moss from head to foot in hanging strokes,
/// lit along the top, a mossy mound over his crown and a brown face peering out of it, bare brown feet. He fights
/// with a long green vine, a leaf every few pixels along it, which he lashes like a whip; put away, it's coiled at his
/// hip. Signature: a stem pushes up out of the moss on his head, a bud swells on it, and it opens into a big pink
/// flower with a yellow heart, nods a moment, then closes and sinks back in.
private func drawMossClawd(_ c: PixelCanvas, _ p: Pose) {
    let moss = C(0x4E8E2E), mossD = C(0x2F621A), mossL = C(0x7EBE4A)
    let face = C(0x8A5A34), faceD = C(0x5E3A1E), faceL = C(0xAA7448)
    let vine = C(0x3A7A22), leaf = C(0x8ED05A)
    let s = p.signature ?? -1

    // Legs in moss down to brown bare feet, strokes hanging down them.
    drawLegs(c, Look(leg: moss), step: p.step)
    drawBoots(c, faceD, step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 5, mossL); c.rect(lx + 1, bottom - 4, 1, 2, mossD); c.px(lx, bottom - 2, mossD)
            c.px(lx + 1, bottom, face)
        }
    }
    c.oy += p.breathe
    // The vine coiled at his back hip while it's put away.
    if p.melee == nil {
        c.pattern(12, 33, [
            ".VVVV.",
            "VVllVV",
            "V....V",
            "VV..lV",
            ".VVVV.",
            "..V...",
        ], ["V": vine, "l": leaf])
    }
    drawBody(c, Look(body: moss, shade: mossD, arm: moss, eye: nil), armRight: p.melee == nil ? p.armRaise : 0)
    // The moss on his body: strokes hanging down it, lit along the shoulders, ragged at the bottom over his legs.
    eterniaFur(c, 18, 33, 20, 4, base: moss, dark: mossD, light: mossL)
    eterniaFur(c, 18, 37, 20, 1, base: moss, dark: mossD, light: moss)
    for (x, y) in [(20, 34), (25, 35), (30, 34), (34, 35)] { c.px(x, y, mossL) }
    c.rect(15, 33, 3, 1, mossL); c.px(16, 35, mossD)
    if p.melee == nil { c.rect(38, 33 - p.armRaise, 3, 1, mossL); c.px(39, 35 - p.armRaise, mossD) }

    // The face: brown, peering out of the moss, heavy brows, a broad nose.
    c.rect(20, 27, 16, 6, face)
    c.rect(20, 27, 16, 1, faceD); c.rect(20, 32, 16, 1, faceD); c.rect(35, 28, 1, 4, faceD); c.rect(20, 28, 1, 4, faceL)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(22, 29, C(0xE8E0B0)); c.px(32, 29, C(0xE8E0B0))
    c.rect(21, 28, 4, 1, faceD); c.rect(31, 28, 4, 1, faceD)
    c.rect(27, 30, 2, 2, faceL); c.px(28, 31, faceD)

    // The moss round his face and over his crown: a shaggy mound of strands, lit on top, hanging over his brow.
    c.pattern(16, 18, [
        "........lMMMlMM.........",
        ".....dMMMdMMMdMMMd......",
        "...MMdMMMdMMMdMMMdMM....",
        "..lMMMlMMMlMMMlMMMlMMM..",
        ".MMdMMMdMMMdMMMdMMMdMMM.",
        "MMMdMMMdMMMdMMMdMMMdMMMd",
        "lMMMlMMMlMMMlMMMlMMMlMMM",
        "MdMMMdMMMdMMMdMMMdMMMdMM",
        "MdMMMdMMMdMMMdMMMdMMMdMM",
        "MdMM.d.M.d.MM.d.M.dMMMlM",
        "MMMd................MMMd",
        "MMMd................MMMd",
        "lMMM................lMMM",
        "MdMM................MdMM",
        ".dMM................MdM.",
        ".MlM................MMl.",
    ], ["M": moss, "d": mossD, "l": mossL])

    // The flower: a stem up out of the moss on his crown, a bud, then the open bloom, and back.
    if s > 0.04 && s < 0.96 {
        let grow = min(1, (s - 0.04) / 0.2) * min(1, (0.96 - s) / 0.16)
        let stem = Int((grow * 6).rounded())
        let nod = s > 0.4 && s < 0.75 ? Int((sin((s - 0.4) * 30) * 0.8).rounded()) : 0
        if stem > 0 {
            c.rect(27, 18 - stem, 1, stem, C(0x3A8A22)); c.px(28, 18 - stem / 2, leaf)
            if stem >= 3 { c.px(26, 17 - stem / 3, leaf) }
            let fx = 27 + nod, fy = 17 - stem
            if grow > 0.85 {
                c.pattern(fx - 3, fy - 3, [
                    "..PPP..",
                    ".PpPpP.",
                    "PPpYpPP",
                    "PpYYYpP",
                    "PPpYpPP",
                    ".PpPpP.",
                    "..PPP..",
                ], ["P": C(0xF060A8), "p": C(0xFFA0D0), "Y": C(0xFFE040)])
                c.px(fx, fy, C(0xFFF4A0))
            } else if grow > 0.4 {
                c.pattern(fx - 1, fy - 2, [".P.", "PpP", "PPP"], ["P": C(0xF060A8), "p": C(0xFFA0D0)])
                c.px(fx, fy + 1, C(0x3A8A22))
            } else {
                c.px(fx, fy, C(0xF060A8))
            }
        }
    }

    if let a = p.melee { m5Vine(c, p, angle: a, vine: vine, leaf: leaf) }
}

/// Moss Clawd's vine from his fist at `angle`: a green lash that curls down at its far end, leaves on alternate sides,
/// a bud at the tip, and a smear behind a fast swing.
private func m5Vine(_ c: PixelCanvas, _ p: Pose, angle a: Double, vine: Px, leaf: Px) {
    let h = eterniaHand
    for (i, t) in p.trail.enumerated() {
        let p0 = eterniaReach(h, t, 5), p1 = eterniaReach(h, t, 15)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xE8FFE0), glow: C(0xC8F0B8), coreR: 0.6, glowR: 1.8,
                   strength: 0.3 / Double(i + 1))
    }
    var x = h.x, y = h.y, dir = a
    for i in 0..<15 {
        // It curls a little more with every pixel, towards the ground on a forward swing.
        dir += (a > -90 && a < 90 ? 2.4 : -2.4) * Double(i) / 6
        let r = dir * .pi / 180
        let nx = x + cos(r), ny = y + sin(r)
        m5Line(c, x, y, nx, ny, vine, 0.6)
        if i > 2 && i % 3 == 0 {
            let side = (i / 3) % 2 == 0 ? 90.0 : -90.0
            let q = eterniaReach((nx, ny), dir + side * 0.7, 1.4)
            c.px(Int(q.x.rounded(.down)), Int(q.y.rounded(.down)), leaf)
        }
        x = nx; y = ny
    }
    c.rect(Int(x.rounded(.down)) - 1, Int(y.rounded(.down)) - 1, 2, 2, C(0xF060A8))
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, C(0x4E8E2E))   // the mossy fist round it
    c.px(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, C(0x7EBE4A))
}

// MARK: - Sy-Clawdne

/// Sy-Clawdne: the Masters' whirlwind warrior. A blue suit, a red chest plate with a gold radar dish on it, red
/// bracers and boots; a blue helmet with a red band, a black face mask with two pale-blue lenses, and a tall gold
/// radar fin standing up off its crown, ribbed like a dish. His power is the wind: white arcs with a pale-blue glow
/// pulsing out of his hand. Signature: his body spins like a top on his planted legs, faster and faster, front, side,
/// back, side, with the wind whirling round him, then slows to a stop facing front.
private func drawSyClawdne(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let u = (s - 0.06) / 0.86
    let spinning = s >= 0.06 && s < 0.92
    let turns = spinning ? m5Spin(u, turns: 6) : 0
    let face = spinning ? Int((turns * 4).rounded(.down)) % 4 : 0
    let blue = C(0x2E64C8), red = C(0xC8302A), redD = C(0x8A1E1A), redL = C(0xE85A4A)

    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 2, redL); c.px(lx + 1, bottom, redD)
            c.px(lx, bottom - 5, C(0x5A8AE8))
        }
    }
    c.oy += p.breathe
    // The wind behind him while he spins: the far half of each whirl, faint.
    if spinning { m5Whirl(c, turns: turns, near: false) }
    switch face {
    case 1, 3: m5SyEdge(c, p)
    case 2: m5SyFront(c, p, back: true)
    default: m5SyFront(c, p, back: false)
    }
    if spinning { m5Whirl(c, turns: turns, near: true) }
}

private let m5SyPal: [Character: Px] = [
    "B": C(0x2E64C8), "b": C(0x1E4490), "l": C(0x5A8AE8),
    "R": C(0xC8302A), "r": C(0x8A1E1A), "L": C(0xE85A4A),
    "Y": C(0xF0C830), "y": C(0xB88E1A), "h": C(0xFFE878),
    "K": C(0x16161E), "E": C(0xC8ECFF), "e": C(0x7AB8E8),
]

/// Sy-Clawdne facing the front (or, `back`, turned right round: no mask, a vent on his back plate).
private func m5SyFront(_ c: PixelCanvas, _ p: Pose, back: Bool) {
    let blue = C(0x2E64C8), blueD = C(0x1E4490), blueL = C(0x5A8AE8)
    let red = C(0xC8302A), redD = C(0x8A1E1A), redL = C(0xE85A4A)
    let raise = back ? 0 : p.armRaise
    drawBody(c, Look(body: blue, shade: blueD, arm: blue, eye: nil), armRight: raise)
    c.rect(18, 26, 19, 1, blueL)
    // The chest plate: red, lit along its top, the gold radar dish on it (on his front only).
    c.rect(18, 33, 20, 4, red); c.rect(18, 33, 20, 1, redL); c.rect(37, 33, 1, 4, redD); c.rect(18, 36, 20, 1, redD)
    if back {
        for y in [34, 35] { c.rect(24, y, 8, 1, redD) }
    } else {
        c.pattern(24, 33, [
            ".hYYYY..",
            "YYyyyYY.",
            ".YYyYY..",
            "...YY...",
        ], m5SyPal)
    }
    c.rect(18, 37, 20, 1, blueD); c.rect(27, 37, 2, 1, C(0xC8CCD8))
    c.rect(15, 34, 3, 1, red); c.rect(38, 34 - raise, 3, 1, red)
    // The helmet: a blue dome down to his brow, a red band round it, and the mask below (or the back of the helmet).
    c.pattern(17, 20, [
        "......BBBBBBBBBB......",
        "....BBllBBBBBBBBBB....",
        "...BlBBBBBBBBBBBBBb...",
        "..BlBBBBBBBBBBBBBBBb..",
        ".BBBBBBBBBBBBBBBBBBBb.",
        ".BBBBBBBBBBBBBBBBBBBb.",
        "RLRRRRRRRRRRRRRRRRRRRr",
        "RRRRRRRRRRRRRRRRRRRRRr",
    ], m5SyPal)
    if back {
        c.rect(18, 28, 20, 4, blue); c.rect(18, 28, 1, 4, blueL); c.rect(37, 28, 1, 4, blueD)
        c.rect(27, 28, 2, 4, blueD)
    } else {
        c.pattern(18, 28, [
            "KKKKKKKKKKKKKKKKKKKK",
            "KKKEEeKKKKKKKKKEEeKK",
            "KKKeeeKKKKKKKKKeeeKK",
            ".KKKKKKKKKKKKKKKKKK.",
        ], m5SyPal)
        c.glowLine(22.5, 29.5, 22.5, 29.5, core: C(0xC8ECFF, 0), glow: C(0x8EC8F0, 0.3), coreR: 0.1, glowR: 2.2)
        c.glowLine(34.5, 29.5, 34.5, 29.5, core: C(0xC8ECFF, 0), glow: C(0x8EC8F0, 0.3), coreR: 0.1, glowR: 2.2)
    }
    // The radar fin: a tall gold blade standing up off his crown, seen edge on from the front, a groove down its
    // middle and a red light at its tip.
    c.pattern(25, 10, [
        "..LL..",
        ".hYYy.",
        ".hyYy.",
        ".hyYy.",
        ".hyYy.",
        ".hyYy.",
        "hYyYYy",
        "hYyYYy",
        "hYyYYy",
        "yyyyyy",
    ], m5SyPal)
}

/// Sy-Clawdne side on, half way round: his body narrow, the fin seen end on, one arm out in front.
private func m5SyEdge(_ c: PixelCanvas, _ p: Pose) {
    c.pattern(22, 12, [
        "...hYYY...",
        "..hYyYYY..",
        ".hYYyYyYy.",
        ".YyyyyyyYy",
        "hYYYyYyYYy",
        "hYYYYyYYYy",
        "yyyyyyyyyy",
        "...hYYy...",
        "..BBBBBB..",
        ".BlBBBBBb.",
        "BlBBBBBBBb",
        "BBBBBBBBBb",
        "BBBBBBBBBb",
        "BBBBBBBBBb",
        "RLRRRRRRRr",
        "RRRRRRRRRr",
        "KKKKKKKKKK",
        "KKKEeKKKKK",
        "KKKeeKKKKK",
        "BKKKKKKKKb",
        "BBBBBBBBBb",
        "RLRRRRRRRr",
        "RRRRRRRRRr",
        "RRRRRRRRRr",
        "RRRRRRRRRr",
        "bbbbbbbbbb",
    ], m5SyPal)
    c.rect(24, 34, 4, 3, C(0x2E64C8)); c.rect(24, 35, 4, 1, C(0xC8302A))   // the arm, swinging round in front
}

/// The whirlwind round Sy-Clawdne as he spins: four rings of white wind with a pale-blue glow at different heights,
/// turning; `near` draws the halves in front of him, otherwise the faint halves behind.
private func m5Whirl(_ c: PixelCanvas, turns: Double, near: Bool) {
    let strength = min(1, turns / 0.8)
    for (k, y) in [21.0, 27, 33, 40].enumerated() {
        let rx = 13.0 + Double(k % 2) * 2, ry = 2.0
        let phase = turns * 2 * .pi * 1.4 + Double(k) * 1.3
        // Two arcs per ring, each a third of the way round.
        for j in 0..<2 {
            let a0 = phase + Double(j) * .pi
            var prev: (Double, Double)? = nil
            for n in 0...8 {
                let a = a0 + Double(n) / 8 * 2.1
                let front = sin(a) > 0
                guard front == near else { prev = nil; continue }
                let x = 28 + cos(a) * rx, yy = y + sin(a) * ry
                if let q = prev {
                    let al = (near ? 0.85 : 0.35) * strength
                    c.glowLine(q.0, q.1, x, yy, core: C(0xF8FCFF, al), glow: C(0x8EC8F0, al * 0.6), coreR: 0.4, glowR: 1.4)
                }
                prev = (x, yy)
            }
        }
    }
}

// MARK: - Snout Spout

/// Where Snout Spout's water leaves from: the brass nozzle at the end of his trunk.
private let m5SnoutTip: (x: Double, y: Double) = (49, 30)

/// Snout Spout: the Masters' firefighter, given a robot elephant's head. A grey metal head with a domed top, a big
/// flat ear on the back with a riveted panel, small dark eyes and short ivory tusks, and a long ribbed trunk curling
/// up at its end to a brass nozzle; red fire-fighter armour with yellow reflective stripes over a blue suit, red
/// bracers and boots, and a chrome water tank on his back with a red valve wheel. He fights with a jet of water out
/// of his trunk, a white beam with a blue glow. Signature: he lifts his trunk high and trumpets, a fountain of water
/// shooting up out of it and falling back in drops.
private func drawSnoutSpout(_ c: PixelCanvas, _ p: Pose) {
    let metal = C(0x9AA0AC), metalD = C(0x6A707C), metalL = C(0xCDD2DC)
    let blue = C(0x2E58B8), blueD = C(0x1E3C84)
    let red = C(0xC8302A), redD = C(0x8A1E1A), redL = C(0xE85A4A)
    let stripe = C(0xF0D040)
    let brass = C(0xE0B040), brassD = C(0x9A7420)
    let s = p.signature ?? -1
    let lift = s < 0 ? 0 : habitArc(s, hold: 0.55)
    let gushing = s > 0.3 && s < 0.82

    drawLegs(c, Look(leg: blue), step: p.step)
    drawBoots(c, red, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 2, redL)
        }
    }
    c.oy += p.breathe
    // The water tank on his back: a chrome cylinder lit on the left, banded in red, a red valve wheel on top.
    c.rect(12, 30, 6, 8, metal); c.rect(12, 30, 1, 8, metalL); c.rect(17, 30, 1, 8, metalD)
    c.rect(12, 37, 6, 1, metalD); c.rect(12, 34, 6, 1, red)
    m5Line(c, 13.5, 37.5, 16, 40.5, C(0x2A2A30), 0.5)   // its hose, down to his belt

    drawBody(c, Look(body: blue, shade: blueD, arm: blue, eye: nil))
    // The armour: red over his chest, lit along the top, two yellow reflective stripes across it, a black belt.
    c.rect(18, 33, 20, 4, red); c.rect(18, 33, 20, 1, redL); c.rect(37, 33, 1, 4, redD)
    c.rect(18, 35, 20, 1, stripe); c.px(37, 35, C(0xB89A20)); c.rect(18, 36, 20, 1, redD)
    c.rect(18, 37, 20, 1, C(0x22202A)); c.rect(26, 37, 3, 1, metalL)
    c.rect(15, 33, 3, 2, red); c.rect(15, 33, 3, 1, redL)
    c.rect(38, 33, 3, 2, red); c.rect(38, 33, 3, 1, redL)

    // The head: grey metal, domed on top, a seam round the dome and rivets.
    c.pattern(17, 20, [
        ".....HHHHHHHHHHH......",
        "...HHLLHHHHHHHHHHH....",
        "..HLHHHHHHHHHHHHHHD...",
        ".HLHHHHHHHHHHHHHHHHD..",
        ".HLHHHHHHHHHHHHHHHHHD.",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "DDDDDDDDDDDDDDDDDDDDDD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        "HHHHHHHHHHHHHHHHHHHHHD",
        ".DDDDDDDDDDDDDDDDDDDD.",
    ], ["H": metal, "L": metalL, "D": metalD])
    c.px(20, 25, metalL); c.px(35, 25, metalD)
    // The eyes, small and dark under a heavy metal brow.
    c.rect(22, 28, 3, 1, metalD); c.rect(31, 28, 3, 1, metalD)
    c.rect(23, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.px(23, 29, C(0xE8ECF4)); c.px(32, 29, C(0xE8ECF4))
    // The big ear, flat against the back of his head: a riveted panel, its inside darker.
    c.pattern(9, 21, [
        "...EEEEEE",
        ".EEeeeeEE",
        "EEeeeeeeE",
        "EeeeoeeeE",
        "EeeeeeeeE",
        "EeeeeeeeE",
        "EeoeeeeeE",
        "EEeeeeeEE",
        ".EEeeeEE.",
        "..EEEEE..",
    ], ["E": metalD, "e": C(0x868C98), "o": metalL])
    // The tusks, short and ivory, forward under his eyes.
    c.pattern(34, 32, ["WWW.", ".wWW"], ["W": C(0xF0E8D4), "w": C(0xB8AC90)])

    // The trunk: ribbed, from the middle of his face, hanging and curling up to the nozzle; lifted high in the
    // signature. Each joint is a darker ring.
    let rest: [(Double, Double)] = [(31, 31), (37, 33.5), (42, 34.5), (46, 33.5), (48, 31)]
    let up: [(Double, Double)] = [(31, 31), (36, 28), (40, 23), (42, 18), (42, 14)]
    var pts: [(Double, Double)] = []
    for (a, b) in zip(rest, up) { pts.append((a.0 + (b.0 - a.0) * lift, a.1 + (b.1 - a.1) * lift)) }
    for i in 0..<(pts.count - 1) {
        let a = pts[i], b = pts[i + 1]
        m5Line(c, a.0, a.1, b.0, b.1, metal, 1.4 - Double(i) * 0.12)
    }
    for i in 0..<(pts.count - 1) {
        let a = pts[i], b = pts[i + 1]
        m5Line(c, a.0, a.1 - 0.9, b.0, b.1 - 0.9, metalL, 0.3)
        for k in 1...2 {
            let f = Double(k) / 3
            let x = a.0 + (b.0 - a.0) * f, y = a.1 + (b.1 - a.1) * f
            c.px(Int(x.rounded(.down)), Int(y.rounded(.down)), metalD)
        }
    }
    // The nozzle: brass, at the trunk's end, pointing the way the last joint goes.
    let tip = pts[pts.count - 1], prev = pts[pts.count - 2]
    let dir = atan2(tip.1 - prev.1, tip.0 - prev.0) * 180 / .pi
    eterniaBar(c, (tip.0, tip.1), dir, from: -0.5, to: 1.6, brass, r: 1.1)
    let mouth = eterniaReach((tip.0, tip.1), dir, 1.8)
    c.px(Int(mouth.x.rounded(.down)), Int(mouth.y.rounded(.down)), brassD)

    if gushing {
        // The fountain: a white jet up out of the nozzle, spreading as it climbs, and drops falling back either
        // side of it. See-through, a blue glow round it, so it shows on a dark desktop.
        let k = min(1, (s - 0.3) / 0.08) * min(1, (0.82 - s) / 0.08)
        let tx = tip.0 + 0.5, ty = tip.1 - 1.5
        c.glowLine(tx, ty, tx, 4, core: C(0xF4FAFF, 0.85 * k), glow: C(0x4A9AF0, 0.55 * k), coreR: 0.6, glowR: 1.8)
        for side in [-1.0, 1.0] {
            for n in 0..<4 {
                let f = frac(p.t * 1.3 + Double(n) / 4 + (side > 0 ? 0.12 : 0))
                let x = tx + side * (2 + f * 7), y = 4 + f * f * 22
                c.glowLine(x, y, x, y + 1, core: C(0xF0FAFF, 0.95 * k * (1 - f * 0.4)), glow: C(0x8ACCFF, 0.35 * k),
                           coreR: 0.7, glowR: 1.3)
            }
        }
        // The trumpet: two little sound arcs off the top.
        for r in [3.0, 5.0] where Int(p.t * 6) % 2 == 0 {
            c.glowLine(tx - r, 6 + r * 0.4, tx - r * 0.4, 6, core: C(0xFFFFFF, 0.5 * k), glow: C(0x8EC8F0, 0.3 * k), coreR: 0.3, glowR: 1)
        }
    }
}

// MARK: - Zodac

/// Zodac: the Cosmic Enforcer, who watches over the balance of the universe. A black helmet with a silver crest down
/// its middle and a silver rim, coming down over his ears; a short black beard all round his jaw; dark-red armour
/// on his chest, ribbed and lit along the top, with a silver star on its plate, a black belt, red bracers and red
/// boots over Clawd's orange. He fights with a silver laser pistol that fires violet bolts. Signature: a floating
/// cosmic chair glimmers into being behind him, he rises and sits down on it in mid-air, a violet glow under it,
/// sits a moment at his ease, then stands, and the chair fades away.
private func drawZodac(_ c: PixelCanvas, _ p: Pose) {
    let helm = C(0x1E1E26), helmL = C(0x4A4C5E)
    let silver = C(0xC4C8D2), silverD = C(0x80848F), silverL = C(0xF0F2F6)
    let red = C(0xA82A24), redD = C(0x701812), redL = C(0xD04A3A)
    let beard = C(0x2A2420), beardL = C(0x4A3E36)
    let s = p.signature ?? -1
    // The chair: it glimmers in (…0.15), he rises onto it (…0.28), sits (…0.78), gets down (…0.88), it fades.
    let chair = s < 0 ? 0 : min(1, max(0, s / 0.15)) * min(1, max(0, (1 - s) / 0.12))
    let up = s < 0 ? 0.0 : s < 0.15 ? 0 : s < 0.28 ? (s - 0.15) / 0.13 : s < 0.78 ? 1 : s < 0.88 ? 1 - (s - 0.78) / 0.1 : 0
    let lift = Int(((0.5 - 0.5 * cos(up * .pi)) * 6).rounded())
    let sitting = up > 0.6
    let bob = sitting ? Int((sin(p.t * 2.4) * 0.6).rounded()) : 0

    if chair > 0 { m5CosmicChair(c, lift: lift + bob, alpha: chair, t: p.t) }
    c.oy -= lift + bob
    if sitting {
        // His legs folded forward along the seat, red boots at their ends.
        for lx in [19, 23, 31, 35] {
            c.rect(lx - 1, 38, 4, 2, clawdOrange); c.rect(lx + 2, 38, 1, 2, red); c.px(lx - 1, 39, clawdShade)
        }
    } else {
        drawLegs(c, Look(), step: p.step)
        drawBoots(c, red, step: p.step, rows: 3)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
                c.rect(lx, bottom - 2, 2, 1, redL); c.px(lx + 1, bottom, redD)
            }
        }
    }
    c.oy += p.breathe
    let raise = sitting ? 0 : p.armRaise
    drawBody(c, Look(eye: ink), armRight: raise)
    c.rect(15, 34, 3, 2, red); c.rect(15, 34, 3, 1, redL)
    // The armour: dark red, ribbed, lit along the top, a silver star on its plate, a black belt with a silver buckle.
    c.rect(18, 33, 20, 4, red); c.rect(18, 33, 20, 1, redL); c.rect(37, 33, 1, 4, redD)
    for x in [20, 23, 33, 36] { c.rect(x, 34, 1, 3, redD) }
    c.pattern(26, 33, [
        "..S..",
        "SSlSS",
        ".SSS.",
        ".S.S.",
    ], ["S": silver, "l": silverL])
    c.rect(18, 37, 20, 1, helm); c.rect(27, 37, 2, 1, silver)

    // The helmet: black, lit on the left, down over his ears either side, a silver rim across his brow, and the
    // silver crest along its top.
    c.pattern(17, 18, [
        ".........SSSS.........",
        "......KKKSllSKKK......",
        "....KKLLKSllSKKKKK....",
        "...KLLKKKSllSKKKKKK...",
        "..KLKKKKKSssSKKKKKKK..",
        "..KLKKKKKSssSKKKKKKK..",
        ".KKKKKKKKKSSKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        ".KKKKKKKKKKKKKKKKKKKK.",
        "dSSSSSSSSSSSSSSSSSSSSd",
        "KK..................KK",
        "KK..................KK",
        "KK..................KK",
        "KK..................KK",
    ], ["K": helm, "L": helmL, "S": silver, "l": silverL, "s": silverD, "d": silverD])
    // The beard: black, round his jaw from ear to ear, short strokes hanging from it over the top of his armour.
    c.pattern(18, 31, [
        "BBBBBBBBBBBBBBBBBBBB",
        ".BBbBBBBBBBBBBBBbBB.",
        "..BBBbBBBbBBBbBBB...",
        "....B..B...B..B.....",
    ], ["B": beard, "b": beardL])
    c.rect(22, 28, 2, 1, beard); c.rect(32, 28, 2, 1, beard)   // his brows

    // The laser pistol: silver, a dark grip in his fist, a violet glow at its muzzle.
    if !sitting {
        c.oy += p.gunY
        c.pattern(38, 31, [
            "..SSSSSSSSs",
            "..SllllllSv",
            "..SSSSsSSS.",
            "..kk.......",
        ], ["S": silver, "l": silverL, "s": silverD, "k": C(0x2A2A30), "v": C(0xC07AFF)])
        c.rect(38, 33, 3, 3, clawdOrange); c.px(38, 35, clawdShade)
        c.glowLine(48.5, 32.5, 48.5, 32.5, core: C(0xF0D8FF, 0), glow: C(0x9A3AF0, 0.35), coreR: 0.1, glowR: 2)
        c.oy -= p.gunY
    } else {
        // His hands at ease on the chair's arms.
        c.rect(38, 34, 3, 2, clawdOrange)
    }
}

/// Zodac's cosmic chair, floating `lift` pixels up: a curved silver seat with a tall back behind him and a violet
/// glow under it, faded in and out with `alpha` (twinkles while it's still faint).
private func m5CosmicChair(_ c: PixelCanvas, lift: Int, alpha: Double, t: Double) {
    let y0 = 40 - lift
    let solid = alpha >= 0.95
    let a = solid ? 1 : 0.3 * alpha
    let seat = C(0xA8ACB8, a), seatL = C(0xE4E6EE, a), seatD = C(0x5E6270, a), trim = C(0x9A3AF0, a)
    // The back, rising behind him, then the seat under him and its curved arm in front.
    c.pattern(11, y0 - 15, [
        ".SS..",
        "SLSS.",
        "SLSS.",
        "SLSS.",
        "SLSS.",
        "SLSS.",
        "SLSS.",
        "SLSSv",
        "SLSSv",
        "SLSSv",
        "SLSSv",
        "SLSS.",
        "SLSS.",
        "SLSS.",
        "SDSS.",
    ], ["S": seat, "L": seatL, "D": seatD, "v": trim])
    c.rect(13, y0, 29, 1, seatL); c.rect(13, y0 + 1, 29, 1, seat); c.rect(15, y0 + 2, 25, 1, seatD)
    c.rect(18, y0 + 1, 18, 1, trim)
    c.rect(40, y0 - 3, 2, 3, seat); c.rect(40, y0 - 3, 3, 1, seatL)
    // The glow underneath: soft violet, no outline.
    let g = alpha * (0.75 + 0.25 * sin(t * 5))
    c.glowLine(17, Double(y0) + 3.5, 38, Double(y0) + 3.5, core: C(0xE8C8FF, 0.5 * g), glow: C(0x9A3AF0, 0.5 * g),
               coreR: 0.5, glowR: 2.2)
    if !solid {
        for k in 0..<5 {
            let x = 14 + Int(noise(k * 7 + Int(t * 10)) * 26), y = y0 - 14 + Int(noise(k * 3 + Int(t * 10)) * 16)
            c.px(x, y, C(0xF4E4FF, 0.9 * alpha + 0.1))
        }
    }
}

// MARK: - Granamyr

/// Where Granamyr's fire leaves from: between his jaws.
private let m5GranamyrJaws: (x: Double, y: Double) = (59, 17)

/// Granamyr: the ancient dragon of Darksmoke, wisest of his kind and tired of everyone. Grey-green scales lit along
/// the top and banded with darker strokes, a pale belly, leathery wings folded flat over his back (beating wide open
/// as he flies), a long tail curling round behind him to an arrow tip, and Clawd's four legs as stout dragon legs
/// with ivory talons. A long neck up to an old, heavy head: two ivory horns sweeping back, half-shut, unimpressed
/// eyes under a bony brow, and a long white beard hanging from his chin in strands. Not Marvel's Fin Fang Fume, who
/// stands upright in purple shorts: Granamyr is grey, bearded and on all fours. He breathes fire, his jaws dropping
/// open on each shot. Signature: he draws a slow breath and puffs out a smoke ring, which drifts up and away while he
/// watches it, eyes half shut.
private func drawGranamyr(_ c: PixelCanvas, _ p: Pose) {
    let scale = C(0x7A8A6E), scaleD = C(0x56644C), scaleL = C(0x9EB08E)
    let belly = C(0xB4B49A), bellyD = C(0x8E8E74)
    let wing = C(0x4E5C46), wingD = C(0x38422F), bone = C(0x2E3628)
    let horn = C(0xE4D8B8), hornD = C(0xA89878)
    let s = p.signature ?? -1
    let breath = s > 0.08 && s < 0.4 ? habitArc((s - 0.08) / 0.32, hold: 0.5) : 0
    let puff = s > 0.36 && s < 0.48
    let firing = p.fire.map { frac($0.t / p.firePeriod) < 0.2 } ?? false
    let open = firing ? 2 : puff ? 1 : 0
    let flap = p.flying ? (Int(p.t * 7) % 2 == 0) : nil

    // The tail, behind him: from his rump round to an arrow tip on the ground.
    m5Line(c, 18, 33, 12, 36, scale, 1.8)
    m5Line(c, 12, 36, 8, 40, scale, 1.5)
    m5Line(c, 8, 40, 9, 42.5, scale, 1.2)
    m5Line(c, 18, 32, 12, 34.5, scaleL, 0.4)
    c.pattern(9, 41, ["DDD.", "DDDD", "DD.."], ["D": scaleD])
    for (x, y) in [(15, 35), (11, 38)] { c.px(x, y, scaleD) }

    // The legs: Clawd's four as stout scaly legs, a darker band at the knee, ivory talons at the toes.
    drawLegs(c, Look(leg: scale), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 5, scaleL); c.rect(lx + 1, bottom - 4, 1, 2, scaleD)
            c.rect(lx, bottom, 2, 1, scaleD); c.px(lx + 2, bottom, horn)
        }
    } else {
        for lx in [19, 23, 31, 35] { c.px(lx + 3, 39, horn) }
    }
    c.oy += p.breathe

    // The far wing when he flies, raised behind the near one.
    if let f = flap { m5DragonWing(c, up: f, far: true, wing: wingD, bone: bone) }

    // The body: Clawd's block as a scaly barrel, swelling a pixel as he draws breath, a pale belly underneath.
    let swell = Int((breath * 1.4).rounded())
    c.rect(18, 26 - swell, 20, 12 + swell, scale)
    c.rect(18, 26 - swell, 20, 1, scaleL); c.rect(37, 26 - swell, 1, 12 + swell, scaleD)
    for y in stride(from: 28, through: 32, by: 2) {
        for x in stride(from: 19 + (y / 2) % 2 * 2, through: 35, by: 4) { c.rect(x, y, 2, 1, scaleD) }
    }
    c.rect(19, 34, 18, 4, belly); c.rect(19, 37, 18, 1, bellyD)
    for x in stride(from: 21, through: 35, by: 4) { c.rect(x, 35, 2, 1, bellyD) }
    // The spines down his back, short and dark.
    for x in stride(from: 19, through: 33, by: 3) { c.px(x, 25 - swell, scaleD) }

    // The folded near wing over his back (or the beating one as he flies).
    if let f = flap {
        m5DragonWing(c, up: f, far: false, wing: wing, bone: bone)
    } else {
        c.pattern(14, 21 - swell, [
            "..........bb.....",
            "......bbbbWWb....",
            "...bbbWWWWWWWb...",
            ".bbWWWWbWWWWWWb..",
            "bWWWWWbWWWWbWWWb.",
            "bWWWWbWWWWbWWWWWb",
            ".bWWbWWWWbWWWWWb.",
            "..bWWWWWbWWWWb...",
            "....bbWWWWbb.....",
        ], ["W": wing, "b": bone])
    }

    // The neck: thick, up and forward from the front of his body to the head, lit along its top, pale underneath.
    m5Line(c, 34, 30, 41, 22, scale, 3.2)
    m5Line(c, 41, 22, 45, 17, scale, 2.6)
    m5Line(c, 33, 27, 40, 19, scaleL, 0.5)
    m5Line(c, 38, 31, 44, 23, bellyD, 0.7)
    for (x, y) in [(36, 26), (39, 23), (42, 20)] { c.rect(x, y, 2, 1, scaleD) }

    // The head: long and heavy, the brow bony, the snout forward, the jaw dropping open when he breathes out.
    c.pattern(42, 10, [
        "...DDDDDD........",
        "..SLLLLLSD.......",
        ".SSSSSSSSSSLLL...",
        "SSSSSSSSSSSSSSSS.",
        "SSSSSSSSSSSSSSSSS",
        "SSSSSSSSSSSSSSSSD",
        "SSSSSSSDDDDDDDDD.",
        ".SSSSS...........",
    ], ["S": scale, "L": scaleL, "D": scaleD])
    c.px(57, 13, ink); c.px(56, 13, scaleD)   // the nostril
    c.px(56, 17, horn)                          // a fang over his lip
    // The lower jaw, under the snout, dropping open on a dark mouth with a glow when the fire comes.
    if open > 0 {
        c.rect(47, 18, 11, open, C(0x3A1210))
        if firing { c.rect(52, 18, 5, open, C(0xFF8A2A)) }
    }
    c.pattern(46, 18 + open, [
        "SSSSSSSSSSD",
        ".DDDDDDDDD.",
    ], ["S": scale, "D": scaleD])
    // The eye: half shut under a heavy lid, unimpressed.
    c.rect(47, 12, 5, 1, scaleD); c.rect(48, 13, 3, 1, C(0xF0C040)); c.px(49, 13, ink)
    c.rect(47, 14, 4, 1, scaleD)   // a bag under it
    // The horns: two ivory sweeps back off the top of his head.
    // The far horn, darker, then the near one: each sweeps back off his skull and hooks up at its tip.
    c.pattern(39, 3, [
        "h.......",
        "h.......",
        "hh......",
        ".hhh....",
        "..hhhh..",
        "....hhhh",
        "......hh",
    ], ["h": hornD])
    c.pattern(35, 5, [
        "H..........",
        "HH.........",
        "hHH........",
        ".hHHH......",
        "..hHHHH....",
        "....hhHHHH.",
        "......hhHHH",
    ], ["H": horn, "h": hornD])
    // The beard: long and white, from his chin down over his chest, in strands, its edges a shade greyer so the
    // white outline doesn't swallow it.
    c.pattern(44, 19 + open, [
        "..wWWWWWWWWw",
        ".wWWgWWWgWWw",
        ".wWgWWWgWWw.",
        "..wWWgWWWw..",
        "..wWgWWgWw..",
        "...wWWgWw...",
        "...wWgWWw...",
        "....wWgw....",
        "....wWWw....",
        ".....wW.....",
    ], ["W": C(0xF0F0EC), "g": C(0xB8BCBC), "w": C(0xA4A8AA)])

    // The smoke ring: puffed out of his mouth, drifting up and forward, growing and fading.
    if s > 0.38 && s < 0.98 {
        let f = (s - 0.38) / 0.6
        let cx = 60 + f * 5, cy = 16 - f * 11, r = 1.4 + f * 3
        let a = f < 0.1 ? f / 0.1 : 1 - (f - 0.1) / 0.9
        var prev: (Double, Double)? = nil
        for n in 0...12 {
            let ang = Double(n) / 12 * 2 * .pi
            let q = (cx + cos(ang) * r * 0.6, cy + sin(ang) * r)
            if let pq = prev {
                c.glowLine(pq.0, pq.1, q.0, q.1, core: C(0xE8EAEE, 0.85 * a), glow: C(0xB0B4BC, 0.45 * a), coreR: 0.5, glowR: 1.3)
            }
            prev = q
        }
    }
    // A thread of smoke from his nostril now and then, idle.
    if s < 0 && frac(p.lt / 5) < 0.3 {
        let f = frac(p.lt / 5) / 0.3
        c.glowLine(58, 13, 59 + f * 2, 13 - f * 5, core: C(0xD8DCE2, 0.5 * (1 - f)), glow: C(0xA0A4AC, 0.25 * (1 - f)),
                   coreR: 0.4, glowR: 1.2)
    }
}

/// One of Granamyr's wings spread in flight, `up` over his back or `down` beside him; the far one is a shade darker
/// and set back.
private func m5DragonWing(_ c: PixelCanvas, up: Bool, far: Bool, wing: Px, bone: Px) {
    let dx = far ? 5 : 0
    if up {
        c.pattern(13 + dx, 4, [
            "b.............",
            "bb...b........",
            ".bWb.bb...b...",
            ".bWWbWWb.bb...",
            "..bWWWbWWbWb..",
            "..bWWWWbWWWbb.",
            "...bWWWWbWWWb.",
            "...bWWWWWbWWWb",
            "....bWWWWWbWWb",
            ".....bWWWWWbWb",
            "......bWWWWWbb",
            ".......bWWWWWb",
            "........bWWWWb",
            ".........bbbbb",
        ], ["W": wing, "b": bone])
    } else {
        c.pattern(8 + dx, 25, [
            "..........bbbb",
            "......bbbbWWWb",
            "...bbbWWWWWWWb",
            ".bbWWWbWWWWWb.",
            "bWWWWbWWWWbb..",
            "bWWWbWWWbb....",
            ".bWbWWbb......",
            "..bbbb........",
        ], ["W": wing, "b": bone])
    }
}

// MARK: - Gwildor

/// Gwildor: the Thenorian locksmith from the film, who made the Cosmic Key. Small and stooped, his head sunk low
/// between his shoulders: a wrinkled grey-brown face with a broad nose and bushy brows, wild red-brown hair sticking
/// up and out in strands and a big bushy beard of it down his chest; long brown robes to the ground, a dark tool belt
/// with pouches and a little spanner. He doesn't fight. He carries the Cosmic Key in his hand: a dark casing rimmed
/// in gold, short silver prongs on top and a row of big bright lights along it. Signature: he holds the Key up high
/// and plays it, its lights blinking one after another along the row, a little run of music notes floating up from it.
private func drawGwildor(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8E7C64), skinD = C(0x6A5A46), skinL = C(0xAC9A80)
    let hair = C(0xA8502C), hairD = C(0x70301A), hairL = C(0xD07444)
    let robe = C(0x6E4A2C), robeD = C(0x4C301A), robeL = C(0x8E6640)
    let s = p.signature ?? -1
    let hold = s < 0 ? 0 : habitArc(s, hold: 0.7)
    let raise = Int((hold * 10).rounded())
    let playing = s > 0.18 && s < 0.84

    // The legs under the robe: brown, only the feet showing under the hem.
    drawLegs(c, Look(leg: robeD), step: p.step)
    drawBoots(c, C(0x3A2818), step: p.step, rows: 2)
    // Stooped: everything above the legs sits three rows lower than plain Clawd.
    c.oy += p.breathe + 3
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil))
    // The robe: from his shoulders to just above the ground, flaring, a shadow between the legs, lit on the left.
    c.rect(18, 31, 20, 7, robe); c.rect(18, 31, 1, 7, robeL); c.rect(37, 31, 1, 7, robeD)
    for y in 38...(seatedPose ? 38 : 39) {
        let flare = y - 37
        c.rect(18 - flare, y, 20 + 2 * flare, 1, robe)
        c.px(18 - flare, y, robeL); c.px(37 + flare, y, robeD)
        for x in [22, 26, 30, 34] { c.px(x, y, robeD) }
    }
    c.rect(15, 33, 3, 3, robe); c.rect(15, 33, 3, 1, robeL); c.px(15, 35, robeD)
    // The tool belt: dark leather, two pouches and a little spanner hanging off it.
    c.rect(17, 35, 22, 1, C(0x2E2016)); c.rect(26, 35, 2, 1, C(0xC8A040))
    c.rect(20, 36, 3, 2, C(0x4A3220)); c.px(20, 36, C(0x6A4A30))
    c.rect(32, 36, 3, 2, C(0x4A3220)); c.px(32, 36, C(0x6A4A30))
    c.rect(24, 36, 1, 3, C(0xB8BCC8)); c.rect(23, 38, 3, 1, C(0xB8BCC8))

    // The face: wrinkled, a creased brow, bushy brows, small eyes and a broad nose.
    c.rect(19, 26, 18, 5, skin)
    c.rect(20, 26, 15, 1, skinD); c.rect(23, 27, 2, 1, skinD); c.rect(30, 27, 3, 1, skinD)
    c.rect(21, 28, 4, 1, hairD); c.rect(31, 28, 4, 1, hairD)
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.px(22, 29, C(0xF0E8C8)); c.px(32, 29, C(0xF0E8C8))
    c.rect(26, 29, 4, 2, skinL); c.px(29, 30, skinD)
    c.px(20, 30, skinD); c.px(35, 30, skinD)
    // The beard: bushy and red-brown, from his jaw down over his chest in strands.
    c.pattern(20, 31, [
        "HHHHHHlHHHHHHHHH",
        "HhHHhHHhHHhHHhHH",
        ".hHHhHHhHHhHHhH.",
        "..HHhHHhHHhHHh..",
        "....h..h..h.....",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The hair: a cap over his crown and wild strands sticking up and out of it all round.
    c.pattern(17, 22, [
        "....HHHlHHHHlHHHH....",
        "..HHHlHHHHlHHHHHHHH..",
        ".HHhHHHhHHHHhHHHhHHH.",
        "HHHHhHHHHhHHHHhHHHhHH",
        "HHh..............hHHH",
        "Hh.................hH",
    ], ["H": hair, "h": hairD, "l": hairL])
    let strands: [(Double, Double, Double, Double, Px)] = [
        (18.5, 24.5, 14.5, 21.5, hair), (21, 22.5, 18.5, 18.5, hairD), (25, 22, 24, 17.5, hair),
        (30, 22, 31.5, 17.5, hairD), (34, 22.5, 36.5, 18.5, hair), (37, 24.5, 41, 21.5, hairD),
    ]
    for (x0, y0, x1, y1, col) in strands { m5Line(c, x0, y0, x1, y1, col, 0.8) }

    // His near arm, in its sleeve, and the Cosmic Key in his hand: at his side, or held up high and played.
    let hx = 40, hy = 33 - raise
    c.rect(38, hy, 3, 3, robe); c.rect(38, hy, 3, 1, robeL)
    if raise > 3 { c.rect(38, hy + 3, 3, min(raise, 8), robe); c.rect(40, hy + 3, 1, min(raise, 8), robeD) }
    c.rect(hx + 1, hy + 1, 2, 2, skin)
    m5CosmicKey(c, x: hx, y: hy - 6, t: p.t, playing: playing)
    if playing {
        // The music notes: a little run floating up from the Key and fading, each a different bright colour.
        let cols: [UInt32] = [0xFFE860, 0x7AF0FF, 0xFF8AD8, 0xA0FF8A]
        for k in 0..<3 {
            let f = frac(p.t * 0.9 + Double(k) / 3)
            let x = hx + 2 + k * 4 + Int(f * 4) + Int((sin(f * 9 + Double(k)) * 1.5).rounded())
            let y = hy - 8 - Int(f * 13)
            let col = C(cols[(k + Int(p.t * 0.9)) % 4], f < 0.6 ? 1 : max(0, 1 - (f - 0.6) / 0.4))
            c.pattern(x, y, [
                "..NN",
                "..N.",
                "..N.",
                "NNN.",
                "NN..",
            ], ["N": col])
        }
    }
}

/// The Cosmic Key, its top left at (`x`, `y`): three short silver prongs on a dark casing rimmed in gold, a row of four big
/// bright lights along it. Played, the lights blink one after another along the row, the lit one flaring with a glow;
/// otherwise they glow steadily, dimmer.
private func m5CosmicKey(_ c: PixelCanvas, x: Int, y: Int, t: Double, playing: Bool) {
    let gold = C(0xF0C040), goldD = C(0xA87820), silver = C(0xA8B0C0), casing = C(0x2E2A3A)
    // The prongs, short, and the casing: dark, so the lights stand out, rimmed in gold, a grip down into his fist.
    c.rect(x + 1, y + 1, 1, 2, silver); c.rect(x + 5, y, 1, 3, silver); c.rect(x + 9, y + 1, 1, 2, silver)
    c.rect(x - 1, y + 3, 13, 4, gold); c.rect(x - 1, y + 3, 13, 1, C(0xFFE07A)); c.rect(x - 1, y + 6, 13, 1, goldD)
    c.rect(x, y + 4, 11, 2, casing)
    c.rect(x + 2, y + 7, 2, 2, goldD)
    let lights: [(Px, Px)] = [(C(0xFF4A4A), C(0xFFD8D0)), (C(0xFFE040), C(0xFFFCE0)),
                               (C(0x40F060), C(0xE0FFE4)), (C(0x30D8FF), C(0xE0FAFF))]
    let lit = playing ? Int(t * 8) % 4 : -1
    for (i, l) in lights.enumerated() {
        let lx = x + i * 3
        let on = i == lit
        c.rect(lx, y + 4, 2, 2, l.0)
        if on || !playing { c.px(lx, y + 4, l.1) }
        let k = on ? 0.8 : playing ? 0.12 : 0.3
        c.glowLine(Double(lx) + 1, Double(y) + 5, Double(lx) + 1, Double(y) + 5, core: C(0xFFFFFF, 0),
                   glow: l.0.alpha(k), coreR: 0.1, glowR: on ? 3 : 2)
    }
}
