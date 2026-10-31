import Foundation

// Villains, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// Bosses: Grimaldi, Heather the Bear, Miss Quill, Big Tina, Gore-Gore, Dismember, Queen Imogen, Shi Maria.

let crawlVillains4: [CrawlVillain: Persona] = [
    .grimaldi: Persona(name: "Grimaldi", weapon: .saber, headTop: 13, signature: 3.2, draw: drawGrimaldi),
    .heather: Persona(name: "Heather the Bear", weapon: .saber, headTop: 11, signature: 3.0, draw: drawHeather),
    .missQuill: Persona(name: "Miss Quill", weapon: .lightning,
                        magic: Magic(core: C(0xF2FFC8), glow: C(0xA8C82A), jagged: false, spell: true), pivot: (44, 33),
                        headTop: 19, signature: 3.2, draw: drawMissQuill),
    .bigTina: Persona(name: "Big Tina", weapon: .lightning,
                      magic: Magic(core: C(0xFFE4E4), glow: C(0xFF2A3A), jagged: false), pivot: (54.5, 24.5),
                      bulk: 5, headTop: 5, signature: 3.4, draw: drawBigTina),
    .goreGore: Persona(name: "Gore-Gore", weapon: .saber, headTop: 11, signature: 3.0, draw: drawGoreGore),
    .dismember: Persona(name: "Dismember", weapon: .lightning,
                        magic: Magic(core: C(0xF4E4FF), glow: C(0x9A4AD8)), pivot: (44, 33),
                        headTop: 19, signature: 3.2, draw: drawDismember),
    .imogen: Persona(name: "Queen Imogen", weapon: .lightning,
                     magic: Magic(core: C(0xFFF6D0), glow: C(0xE8B830), jagged: false, rings: true), pivot: (45, 33),
                     headTop: 8, signature: 3.2, draw: drawImogen),
    .shiMaria: Persona(name: "Shi Maria", weapon: .lightning,
                       magic: Magic(core: C(0xFFFFFF), glow: C(0xC87AF0), jagged: false, touch: true), pivot: (56, 27),
                       bulk: 4, headTop: 18, signature: 3.0, draw: drawShiMaria),
]

// MARK: - Helpers

/// 0 outside `a…b`, 1 inside it, easing in and out over `edge` at each end.
private func v4Arc(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    let k = min(1, (s - a) / edge, (b - s) / edge)
    return k * k * (3 - 2 * k)
}

/// 0 before `a`, 1 after `b`, eased between.
private func v4Ease(_ s: Double, _ a: Double, _ b: Double) -> Double {
    let k = min(1, max(0, (s - a) / (b - a)))
    return k * k * (3 - 2 * k)
}

/// A solid bar `r` pixels thick from (`x0`, `y0`) to (`x1`, `y1`): a limb, a stick.
private func v4Line(_ c: PixelCanvas, _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ col: Px, _ r: Double = 0.6) {
    c.glowLine(x0, y0, x1, y1, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
}

/// The point `t` (0…1) of the way along a curve from `a` bending towards `k` to `b`.
private func v4Bez(_ a: (Double, Double), _ k: (Double, Double), _ b: (Double, Double), _ t: Double) -> (Double, Double) {
    let u = 1 - t
    let x = u * u * a.0 + 2 * u * t * k.0 + t * t * b.0
    let y = u * u * a.1 + 2 * u * t * k.1 + t * t * b.1
    return (x, y)
}

/// A vine from `a` curving towards `k` to `b`, a pixel thick (two near its root), with a lit pixel along it now and
/// then, a leaf at each of `leaves` (0…1 along it) and a curl at its tip.
private func v4Vine(_ c: PixelCanvas, _ a: (Double, Double), _ k: (Double, Double), _ b: (Double, Double),
                    _ col: Px, _ lit: Px, _ leaf: Px, leaves: [Double] = []) {
    for i in 0...32 {
        let pt = v4Bez(a, k, b, Double(i) / 32)
        let x = Int(pt.0.rounded(.down)), y = Int(pt.1.rounded(.down))
        c.px(x, y, i % 7 == 3 ? lit : col)
        if i < 10 { c.px(x + 1, y, col) }
    }
    for f in leaves {
        let pt = v4Bez(a, k, b, f), q = v4Bez(a, k, b, min(1, f + 0.06))
        let dx = q.0 - pt.0, dy = q.1 - pt.1, l = max(hypot(dx, dy), 0.01)
        let x = Int((pt.0 - dy / l * 1.6).rounded(.down)), y = Int((pt.1 + dx / l * 1.6).rounded(.down))
        c.pattern(x - 1, y - 1, [".L", "LL", "L."], ["L": leaf])
        c.px(x, y - 1, lit)
    }
    let end = v4Bez(a, k, b, 1), pre = v4Bez(a, k, b, 0.92)
    let ex = Int(end.0.rounded(.down)), ey = Int(end.1.rounded(.down))
    c.px(ex + (end.0 > pre.0 ? 1 : -1), ey + 1, col)       // the curl
}

/// A chain of `n` segments `step` pixels long from `from`, setting off at `angle` degrees and bending `bend` degrees
/// more at each one: a whip's lash, a lashing vine. Nothing goes below the ground row (it lies along it). Returns the
/// points, root first.
private func v4Chain(from: (Double, Double), angle: Double, bend: Double, n: Int, step: Double) -> [(Double, Double)] {
    var pts = [from]
    var pt = from, dir = angle
    for _ in 0..<n {
        let r = dir * .pi / 180
        pt = (pt.0 + cos(r) * step, min(43, pt.1 + sin(r) * step))
        pts.append(pt)
        dir += bend
    }
    return pts
}

/// A colour by hue (0…1, round the wheel), saturation and value.
private func v4Hue(_ h: Double, _ s: Double, _ v: Double) -> Px {
    let hh = (h - floor(h)) * 6
    let i = Int(hh) % 6, f = hh - floor(hh)
    let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
    var rgb = (v, t, p)
    switch i {
    case 1: rgb = (q, v, p)
    case 2: rgb = (p, v, t)
    case 3: rgb = (p, q, v)
    case 4: rgb = (t, p, v)
    case 5: rgb = (v, p, q)
    default: break
    }
    return Px(r: UInt8(rgb.0 * 255), g: UInt8(rgb.1 * 255), b: UInt8(rgb.2 * 255), a: 255)
}

/// Draws `body` into a canvas of its own and pastes it, turned to face the other way when `back` (a spin, in two
/// flips): `about` is the column it turns round.
private func v4Spin(_ c: PixelCanvas, back: Bool, about: Double, _ body: (PixelCanvas) -> Void) {
    let fig = PixelCanvas(Sprite.width, Sprite.height)
    body(fig)
    if back { fig.mirror(aboutX: about) }
    c.paste(fig)
}

// MARK: - Grimaldi

/// Grimaldi: a dwarf ringmaster, Clawd in a red tailcoat with gold frogging across it and gold-fringed epaulettes, its
/// tails hanging down behind, white breeches and black riding boots; a great bushy ginger beard down his chest, bushy
/// brows, a dwarf's round nose, and a tall black top hat with a red band. Pale-green vines sprout from him: out of the
/// hat, its brim and his far shoulder, curling and swaying, their leaves lit. He lashes with a long vine out of his
/// white-gloved hand, which hangs coiled to the ground at rest. Signature: he cracks a ringmaster's whip, the black
/// lash swung up behind him and snapped out in front with a bright crack at its tip.
private func drawGrimaldi(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xB8242C), coatD = C(0x861820), coatL = C(0xDC4646)
    let gold = C(0xE8B83A), goldD = C(0xA88220)
    let white = C(0xF0ECE0), whiteD = C(0xC8C2B4)
    let boot = C(0x4A2E20), bootL = C(0x6E4A34)
    let beard = C(0xA45A2A), beardD = C(0x6E3A1A), beardL = C(0xCC7C40)
    let hat = C(0x1C1A22), hatD = C(0x0E0C12), hatL = C(0x403E4A), band = C(0x9A1E26)
    let vine = C(0x9CCC86), vineL = C(0xD4F0C4), leaf = C(0xB8E4A0)
    let lash = C(0x2A2224), lashL = C(0x4A3E40), grip = C(0x7A4A28)
    let s = p.signature ?? -1
    let cracking = s > 0.06 && s < 0.92
    let sw = sin(p.lt * 1.3), sw2 = sin(p.lt * 1.1 + 2)

    // 1. White breeches, black riding boots to the knee, lit along their tops.
    drawLegs(c, Look(leg: white), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 1, bootL); c.px(lx + 1, 37, whiteD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The coat's tails, hanging down behind him.
    c.pattern(14, 33, ["CCCC", "CCCc", ".CCc", ".Ccc", ".Cc.", "..c.", "..c."], ["C": coat, "c": coatD])

    // 4. The body in the red tailcoat: lit on the left, its far side in shade, gold frogging across the chest each side
    //    of the beard, the epaulettes with their fringe.
    drawBody(c, Look(arm: coat, eye: nil))
    c.rect(18, 32, 20, 6, coat)
    c.rect(18, 32, 1, 6, coatL); c.rect(36, 32, 2, 6, coatD); c.rect(18, 37, 20, 1, coatD)
    for y in [33, 35] { c.rect(19, y, 3, 1, gold); c.rect(33, y, 3, 1, gold); c.px(21, y, goldD); c.px(35, y, goldD) }
    c.rect(15, 33, 3, 1, gold); c.rect(38, 33, 3, 1, gold)
    c.px(15, 34, goldD); c.px(17, 34, goldD); c.px(38, 34, goldD); c.px(40, 34, goldD)

    // 5. The vine out of his far shoulder, curling up behind him.
    v4Vine(c, (16, 32), (10 + sw, 28), (11 + sw, 21), vine, vineL, leaf, leaves: [0.45, 0.8])

    // 6. The face: bushy brows, small dark eyes, a dwarf's round nose.
    c.pattern(20, 27, ["BBBb", ".BBB"], ["B": beard, "b": beardL])
    c.pattern(31, 27, ["bBBB", "BBB."], ["B": beard, "b": beardL])
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.rect(26, 29, 3, 2, C(0xE48A6A)); c.px(26, 29, C(0xF4A888)); c.rect(26, 31, 3, 1, clawdShade)

    // 7. The beard: great and bushy, the moustache across first, strands combed down it, lit on top, to a point.
    c.pattern(19, 31, [
        "..bbbbbBBBbbbbbbbb..",
        ".bBBBBBBBBBBBBBBBBb.",
        "BBdBBBdBBBBdBBBdBBBB",
        "BBdBBBdBBBBdBBBBdBBB",
        ".BBdBBBdBBBdBBBdBBB.",
        "..BdBBBdBBBBdBBdBB..",
        "...BdBBdBBBdBBdBB...",
        ".....BdBBBBdBB......",
        ".......BdBdB........",
    ], ["B": beard, "b": beardL, "d": beardD])
    c.px(18, 27, beard); c.rect(18, 28, 1, 3, beardD); c.rect(37, 28, 1, 3, beardD)   // sideburns

    // 8. The top hat: a wide brim lit along the top, the tall crown lit down its left, its far side in shade, the red
    //    band.
    c.rect(16, 25, 24, 1, hat); c.rect(17, 24, 22, 1, hat); c.rect(17, 24, 8, 1, hatL)
    c.rect(20, 14, 16, 10, hat)
    c.rect(20, 14, 16, 1, hatL); c.rect(21, 15, 1, 7, hatL); c.rect(34, 15, 2, 9, hatD)
    c.rect(20, 21, 16, 2, band); c.rect(20, 21, 16, 1, C(0xC0303A))

    // 9. The vines out of the hat: one from the band curling up and forward, one out of the crown, swaying.
    v4Vine(c, (35, 21), (41 + sw * 0.6, 18), (40 + sw, 11), vine, vineL, leaf, leaves: [0.35, 0.7])
    v4Vine(c, (24, 14), (21 + sw2 * 0.6, 10), (25 + sw2, 6), vine, vineL, leaf, leaves: [0.5])
    v4Vine(c, (17, 24), (14, 23 + sw2 * 0.4), (13, 19), vine, vineL, leaf, leaves: [0.6])

    // 10. The near hand, white-gloved: the vine lash swung, or hanging coiled to the ground; the whip as he cracks it.
    if cracking {
        // The handle swings up behind him (…0.42), snaps forward (…0.52), holds while the crack rings out, and drops.
        var h = 40.0, start = 80.0, bend = 6.0
        if s < 0.42 {
            let e = v4Ease(s, 0.06, 0.42); h = 40 - 165 * e; start = h + 50 + 30 * e; bend = 6 + 2 * e
        } else if s < 0.52 {
            let e = v4Ease(s, 0.42, 0.52); h = -125 + 110 * e; start = h + 80 * (1 - e) - 4; bend = 8 * (1 - e)
        } else if s < 0.66 {
            h = -15; start = -18; bend = 0.4
        } else {
            let e = v4Ease(s, 0.66, 0.92); h = -15 + 55 * e; start = h + 30 * e; bend = 10 * e
        }
        let tip = crawlReach(Sprite.hand, h, 3)
        v4Line(c, Sprite.hand.x, Sprite.hand.y, tip.x, tip.y, grip, 0.8)
        let pts = v4Chain(from: tip, angle: start, bend: bend, n: 12, step: 1.5)
        for i in 0..<(pts.count - 1) {
            v4Line(c, pts[i].0, pts[i].1, pts[i + 1].0, pts[i + 1].1, i < 3 ? lashL : lash, i < 5 ? 0.6 : 0.45)
        }
        if s > 0.5 && s < 0.64, let end = pts.last {
            let x = Int(end.0.rounded()), y = Int(end.1.rounded())
            let f = Int(p.lt * 16) % 2 == 0
            c.pattern(x - 2, y - 2, f ? ["Y...Y", ".YWY.", ".WWW.", ".YWY.", "Y...Y"] : ["..Y..", ".YWY.", "YWWWY", ".YWY.", "..Y.."],
                      ["W": C(0xFFFFFF), "Y": C(0xFFE07A)])
        }
    } else if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            let pts = v4Chain(from: Sprite.hand, angle: ta, bend: 3, n: 12, step: 1.4)
            for k in 0..<(pts.count - 1) {
                v4Line(c, pts[k].0, pts[k].1, pts[k + 1].0, pts[k + 1].1, vine.alpha(0.3 / Double(i + 1)), 0.5)
            }
        }
        let pts = v4Chain(from: Sprite.hand, angle: a, bend: 3, n: 12, step: 1.4)
        for k in 0..<(pts.count - 1) {
            v4Line(c, pts[k].0, pts[k].1, pts[k + 1].0, pts[k + 1].1, k % 5 == 2 ? vineL : vine, k < 6 ? 1 : 0.75)
        }
        for k in [4, 8] {
            let x = Int(pts[k].0.rounded(.down)), y = Int(pts[k].1.rounded(.down))
            c.pattern(x - 1, y - 2, [".L", "LL"], ["L": leaf])
        }
        if let end = pts.last { c.px(Int(end.0.rounded()), Int(end.1.rounded()) + 1, vine) }
    } else {
        v4Vine(c, (42, 35), (46, 38), (44, 43), vine, vineL, leaf, leaves: [0.4, 0.75])
    }
    c.rect(41, 33, 2, 3, white); c.px(41, 33, C(0xFFFFFF)); c.px(42, 35, whiteD)
}

// MARK: - Heather the Bear

/// Heather the Bear: a mother bear in clown costume, sad and eerie rather than frightening: Clawd in brown fur, round
/// ears either side of a faded cream clown hat with red and blue polka dots and a limp red pompom, a pale muzzle with
/// a black nose and a downturned mouth, white clown paint round her drooping eyes and a blue painted tear; a white
/// frilled ruff, a faded pink tutu, and white roller skates with pink wheels. She swipes with her glowing worm-paws:
/// pale sea-green worms of light wriggling out of the pads. Signature: a wobbly roller-skate twirl, arms out, turning
/// round twice and wobbling to a stop.
private func drawHeather(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.06, s < 0.94 else { drawHeatherBody(c, p, twirl: false); return }
    var q = p
    q.signature = nil
    // Two full turns, speeding up and slowing down: she faces away every other half turn.
    let turn = 4 * v4Ease(s, 0.08, 0.84)
    let back = Int(turn) % 2 == 1
    let wobble = s > 0.8 ? Int((sin(s * 90) * 1.2).rounded()) : 0
    c.ox += wobble
    v4Spin(c, back: back, about: 28) { drawHeatherBody($0, q, twirl: true) }
    c.ox -= wobble
    // Swirls round her skates while she turns.
    if s < 0.84 {
        let k = Int(p.lt * 14)
        for i in 0..<3 {
            let x = 14 + Int(noise(k * 3 + i) * 28)
            c.rect(x, 44, 3, 1, C(0xF4E8F0, 0.5))
        }
    }
}

/// Heather herself (drawn into a canvas of her own and turned round for her twirl). `twirl`: her paws held out wide.
private func drawHeatherBody(_ c: PixelCanvas, _ p: Pose, twirl: Bool) {
    let fur = C(0x7A5236), furD = C(0x573A26), furL = C(0x9C6E4C)
    let muzzle = C(0xC8A47E), muzzleD = C(0xA08060)
    let paint = C(0xF2EEE8), tear = C(0x6A9AE0)
    let hat = C(0xE8DCBC), hatD = C(0xBEB290), dotR = C(0xC85060), dotB = C(0x5A7AC0), pom = C(0xC85A68)
    let ruff = C(0xF2EEE6), ruffD = C(0xC4BEB4)
    let tutu = C(0xE0A0BA), tutuD = C(0xB87894), tutuL = C(0xF2C6D8)
    let skate = C(0xE6E0D8), skateD = C(0xB4ACA2), wheel = C(0xE07AA0)
    let worm = C(0xC8FFE8), wormGlow = C(0x40D8A8)

    // 1. Brown furry legs, lit down the front, in white roller skates on pink wheels.
    if seatedPose {
        drawLegs(c, Look(leg: fur))
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 36, 2, bottom - 38, fur); c.rect(lx, 37, 1, bottom - 40, furL)
            c.rect(lx, bottom - 2, 3, 2, skate); c.px(lx, bottom - 2, C(0xFFFFFF)); c.px(lx + 2, bottom - 1, skateD)
            c.px(lx, bottom, wheel); c.px(lx + 2, bottom, wheel)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in brown fur, short strokes down it, lit on the left; the arms, held out wide while she twirls.
    let lift = twirl ? 3 : 0
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil), armLeft: lift, armRight: lift)
    c.rect(18, 26, 1, 11, furL)
    for (x, y) in [(20, 27), (25, 26), (30, 27), (35, 26), (19, 31), (36, 31)] { c.px(x, y, furD); c.px(x + 1, y + 1, furD) }
    if twirl { c.rect(13, 30, 2, 3, fur); c.rect(41, 30, 2, 3, fur) }

    // 4. The face: white clown paint round each drooping eye, the lids heavy, painted brows high and sad, the blue tear.
    c.pattern(21, 26, ["..P.", ".PP.", "....", "....", ".PP.", "..P."], ["P": paint])
    c.pattern(31, 26, [".P..", ".PP.", "....", "....", ".PP.", ".P.."], ["P": paint])
    c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink); c.px(22, 28, furD); c.px(33, 28, furD)
    c.pattern(19, 26, ["...kk", ".kk..", "k...."], ["k": ink])        // the far brow, rising to the middle
    c.pattern(33, 26, ["kk...", "..kk.", "....k"], ["k": ink])
    c.rect(34, 30, 1, 3, tear); c.px(34, 30, C(0xA8CCFF)); c.px(35, 32, tear)

    // 5. The muzzle: pale, the black nose with its shine, a small downturned mouth.
    c.rect(25, 29, 6, 5, paint); c.rect(24, 30, 8, 3, paint); c.rect(25, 33, 6, 1, muzzle)
    c.rect(26, 29, 4, 2, ink); c.px(26, 29, C(0x5A5058))
    c.rect(27, 31, 2, 1, muzzleD); c.rect(26, 32, 4, 1, muzzleD); c.px(25, 33, muzzleD); c.px(30, 33, muzzleD)

    // 6. The ruff: white frills round her neck and over her shoulders, scalloped.
    c.rect(17, 34, 22, 1, ruff)
    for x in stride(from: 16, through: 38, by: 2) { c.px(x, 35, ruff); c.px(x + 1, 35, ruffD) }
    c.rect(17, 34, 22, 1, ruff); c.px(38, 34, ruffD)

    // 7. The tutu: faded pink, layered, flaring out over her hips, its frills scalloped.
    c.rect(16, 36, 24, 1, tutuL)
    c.rect(14, 37, 28, 1, tutu); c.rect(38, 37, 4, 1, tutuD)
    for x in stride(from: 13, through: 41, by: 2) { c.px(x, 38, tutu); c.px(x + 1, 38, tutuD) }

    // 8. The clown hat: faded cream, tipped a little forward, dots of red and blue, a frill round its brim and a limp
    //    pompom hanging off its tip; the round ears either side of it.
    c.pattern(16, 22, ["FFFF", "FMMF", "FMMF", ".FF."], ["F": fur, "M": muzzleD])
    c.pattern(36, 22, ["FFFF", "FMMF", "FMMF", ".FF."], ["F": furD, "M": muzzleD])
    c.pattern(21, 12, [
        "...........PP..",
        "..........PPp..",
        ".........HH....",
        "........HHH....",
        "........HRH....",
        ".......HHHH....",
        "......HHHHHh...",
        "......HBHHHh...",
        ".....HHHHHRh...",
        ".....HHRHHHh...",
        "....HHHHHHHHh..",
        "....HHHHHBHHh..",
        "...hhhhhhhhhhh.",
        "..fFfFfFfFfFfFf",
    ], ["H": hat, "h": hatD, "R": dotR, "B": dotB, "P": pom, "p": C(0x9A3E4A), "f": ruffD, "F": ruff])

    // 9. The near paw: swiped, or held at her side (or out wide as she twirls), pale worms of light wriggling out of
    //    its pads.
    func worms(_ at: (x: Double, y: Double), _ angle: Double, _ len: Double, alpha: Double) {
        for (i, k) in [-30.0, 0, 30].enumerated() {
            let w = sin(p.lt * 9 + Double(i) * 2) * 12
            let e = crawlReach(at, angle + k + w, len)
            let m = crawlReach(at, angle + k - w, len * 0.5)
            c.glowLine(at.x, at.y, m.x, m.y, core: worm.alpha(alpha), glow: wormGlow.alpha(alpha * 0.5), coreR: 0.4, glowR: 1.2)
            c.glowLine(m.x, m.y, e.x, e.y, core: worm.alpha(alpha), glow: wormGlow.alpha(alpha * 0.5), coreR: 0.4, glowR: 1.2)
        }
    }
    if let a = p.melee, !twirl {
        for (i, ta) in p.trail.enumerated() { worms(crawlReach((39, 34), ta, 6), ta, 4, alpha: 0.3 / Double(i + 1)) }
        crawlBar(c, (39, 34), a, from: 0, to: 5, fur, r: 1.2)
        let e = crawlReach((39, 34), a, 5)
        c.rect(Int(e.x.rounded()) - 1, Int(e.y.rounded()) - 1, 3, 3, furD)
        worms(crawlReach((39, 34), a, 6), a, 5, alpha: 1)
    } else if twirl {
        worms((43, 31), -30, 2.5, alpha: 0.8); worms((12, 31), 210, 2.5, alpha: 0.8)
    } else {
        c.rect(39, 34, 3, 3, fur); c.rect(39, 36, 3, 1, furD)
        worms((41.5, 37), 70, 3.5, alpha: 0.8 + 0.2 * sin(p.lt * 3))
    }
}

// MARK: - Miss Quill

/// Miss Quill: an elderly Skyfowl, a grey bird-woman: Clawd under grey feathers, a wispy crest of long feathers swept
/// back off her crown, small beady eyes under heavy lids and brows knitted in a sour frown, a dull horn-yellow beak,
/// hooked and cracked across, turned down at the corner. She wears a long plum cleric's robe to the ground, a white
/// collar tab at her throat and a pale name badge, her grey toes peeping out under the hem. Her dark cleric magic is a
/// sickly green spell from her wing-hand. Signature: a form floats up in front of her; she lifts a rubber stamp and
/// slams it down, and lifts it off a red NO.
private func drawMissQuill(_ c: PixelCanvas, _ p: Pose) {
    let feather = C(0x9C9CA6), featherD = C(0x70707C), featherL = C(0xC8C8D0)
    let beak = C(0xD4B460), beakD = C(0x9C8034), beakL = C(0xEED890)
    let robe = C(0x5A3256), robeD = C(0x3C2038), robeL = C(0x7C4C76)
    let collar = C(0xEEEAE0), toe = C(0xA8A090)
    let paper = C(0xF4F0E4), paperD = C(0xC8C2B0), red = C(0xD02A2A)
    let wood = C(0x8A5A30), woodD = C(0x5E3C1E)
    let s = p.signature ?? -1
    let stamping = s > 0.08 && s < 0.92

    // 1. The legs, scaly grey, only her toes showing under the robe.
    drawLegs(c, Look(leg: featherD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom, 3, 1, toe); c.px(lx + 2, bottom, ink)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in grey feathers, lit on the left, short strokes of feather on her cheeks; the sleeves in plum.
    drawBody(c, Look(body: feather, shade: featherD, arm: robe, eye: nil))
    c.rect(18, 26, 1, 7, featherL)
    for (x, y) in [(19, 30), (20, 31), (35, 31), (34, 26), (24, 26)] { c.px(x, y, featherD) }
    c.px(15, 33, robeL)

    // 4. The robe: long to the ground, flaring, lit on the left, folds down it and a shadow either side of each leg; the
    //    white collar tab and her pale badge.
    c.rect(18, 32, 20, 4, robe)
    c.rect(17, 36, 22, 3, robe); c.rect(16, 39, 24, 3, robe)
    c.rect(18, 32, 1, 4, robeL); c.rect(17, 36, 1, 3, robeL); c.rect(16, 39, 1, 3, robeL)
    c.rect(36, 32, 2, 4, robeD); c.rect(37, 36, 2, 3, robeD); c.rect(38, 39, 2, 3, robeD)
    for x in [22, 29, 33] { c.rect(x, 37, 1, 5, robeD) }
    c.rect(26, 32, 3, 2, collar); c.px(28, 33, C(0xC8C4BA))
    c.rect(31, 34, 3, 2, C(0xE4E0D2)); c.px(33, 35, C(0x6A8AC0))

    // 5. The face: beady eyes under heavy lids, the brows knitted down to the middle.
    c.rect(22, 29, 2, 3, ink); c.rect(31, 29, 2, 3, ink)
    c.rect(22, 29, 2, 1, featherD); c.rect(31, 29, 2, 1, featherD)
    c.pattern(20, 27, ["kk..", "..kk"], ["k": C(0x3A3A44)])
    c.pattern(30, 27, ["..kk", "kk.."], ["k": C(0x3A3A44)])

    // 6. The beak: hooked, horn-yellow and dull, lit along the top, a crack across it, the corner turned down.
    c.pattern(34, 28, [
        ".BBBBl....",
        "BBBBBBBll.",
        "BBBkBBBBBB",
        "BBBBkBBBBB",
        "bbbbkbbbbB",
        "bbbbbb..bb",
        ".bbb......",
    ], ["B": beak, "b": beakD, "l": beakL, "k": ink])

    // 7. The crest: long wispy feathers swept back off her crown, lit along the top.
    c.rect(19, 25, 18, 1, featherL)
    let crest: [(Double, Double, Double, Px)] = [(22, 15, 19, featherL), (27, 21, 18, feather), (31, 27, 19, featherL),
                                                 (24, 17, 22, featherD)]
    for (x0, x1, y1, col) in crest {
        v4Line(c, x0, 25.5, (x0 + x1) / 2, y1 + 2, col, 0.55)
        v4Line(c, (x0 + x1) / 2, y1 + 2, x1, y1, col, 0.45)
    }

    // 8. The near wing-hand: down at her side, raised as she casts, or holding the stamp.
    if stamping {
        // The form floats up in front of her (…0.16); she lifts the stamp (…0.4) and slams it down (…0.5), holds,
        // and lifts it off the NO (0.62…).
        let up = v4Ease(s, 0.08, 0.16) * (1 - v4Ease(s, 0.84, 0.92))
        let py = 30 + Int(((1 - up) * 4).rounded())
        c.rect(43, py, 10, 11, paper); c.rect(52, py, 1, 11, paperD); c.rect(43, py + 10, 10, 1, paperD)
        for k in 0..<4 { c.rect(44, py + 2 + k * 2, 7 - (k % 2) * 2, 1, paperD) }
        if s > 0.5 { crawlText(c, 45, py + 3, "NO", red) }
        var hx = 46.0, hy = 34.0
        if s < 0.42 {
            let e = v4Ease(s, 0.12, 0.4); hx = 41 + 5 * e; hy = 34 - 13 * e
        } else if s < 0.5 {
            let e = v4Ease(s, 0.42, 0.5); hy = 21 + 11 * e * e
        } else if s < 0.62 {
            hy = 32
        } else {
            let e = v4Ease(s, 0.62, 0.8); hx = 46 - 5 * e; hy = 32 - 4 * e + 6 * v4Ease(s, 0.8, 0.9)
        }
        v4Line(c, 39, 33.5, hx, hy, robe, 1.2)
        let x = Int(hx.rounded()), y = Int(hy.rounded())
        c.rect(x, y - 3, 2, 2, wood); c.px(x, y - 3, C(0xB07A48))
        c.rect(x - 1, y - 1, 4, 2, feather); c.px(x - 1, y - 1, featherL)
        c.rect(x - 2, y + 1, 6, 1, wood); c.rect(x - 2, y + 2, 6, 1, woodD); c.rect(x - 2, y + 3, 6, 1, red)
        if s > 0.49 && s < 0.56 {
            for (dx, dy) in [(-4, 2), (6, 2), (-4, 4), (6, 4)] { c.px(x + dx, y + dy, C(0xFFFFFF, 0.8)) }
        }
    } else if p.zap != nil {
        let r = p.armRaise
        c.rect(38, 32 - r, 3, 3, robe); c.px(38, 32 - r, robeL)
        c.pattern(41, 31 - r, ["FF..", "FFFF", ".FF."], ["F": feather])
        c.px(44, 32 - r, featherL)
    } else {
        c.pattern(38, 34, ["FFF", "FFF", ".Fd"], ["F": feather, "d": featherD])
    }
}

// MARK: - Big Tina

/// Big Tina: an allosaurus, Clawd in a huge sandy dinosaur suit banded with brown stripes: a long head on a thick
/// neck, little red horns over a fierce eye, a row of teeth, a heavy tail held out behind; and on her a hot-pink tutu
/// round her hips, a fluffy pink feather boa round her neck, and a silver tiara with a pink jewel. In one tiny hand
/// she holds a star wand, and its gold star fires a steady red ray. Signature: a ballerina's pirouette, up on her
/// toes, wand held high, turning twice with the tutu flared out and pink sparkles off the star.
private func drawBigTina(_ c: PixelCanvas, _ p: Pose) {
    guard let s = p.signature, s > 0.06, s < 0.94 else { drawTinaBody(c, p, spin: 0); return }
    var q = p
    q.signature = nil
    let up = v4Arc(s, 0.06, 0.94, edge: 0.1)
    let turn = 4 * v4Ease(s, 0.12, 0.86)
    let back = Int(turn) % 2 == 1
    c.oy -= Int((up * 1).rounded())
    v4Spin(c, back: back, about: 36) { drawTinaBody($0, q, spin: up) }
    c.oy += Int((up * 1).rounded())
    // Pink sparkles flung off the star as she turns.
    for i in 0..<4 {
        let f = (p.lt * 2 + Double(i) / 4).truncatingRemainder(dividingBy: 1)
        let x = 36 + Int((cos(f * 9 + Double(i)) * (8 + f * 14)).rounded()), y = 12 + Int((f * 14).rounded())
        let col = C(i % 2 == 0 ? 0xFF8AC8 : 0xFFE07A).alpha(up * (1 - f))
        c.px(x, y, col); c.px(x - 1, y, col.alpha(0.5)); c.px(x + 1, y, col.alpha(0.5))
        c.px(x, y - 1, col.alpha(0.5)); c.px(x, y + 1, col.alpha(0.5))
    }
}

/// Big Tina herself (drawn into a canvas of her own and turned round for her pirouette). `spin` (0…1): up on her toes
/// and turning, the wand held high and the tutu flared.
private func drawTinaBody(_ c: PixelCanvas, _ p: Pose, spin: Double) {
    let hide = C(0xC89A4E), hideD = C(0x9A7236), hideL = C(0xE4BC72), belly = C(0xEAD8A8), bellyD = C(0xC8B480)
    let stripe = C(0x7A5428), horn = C(0xB8402A), claw = C(0x2A2018), tooth = C(0xF6F0E0), mouth = C(0x6A1E24)
    let tutu = C(0xFF6EB0), tutuD = C(0xD0468A), tutuL = C(0xFFAED4)
    let boa = C(0xF05CA8), boaL = C(0xFF9CCC), boaD = C(0xC03C84)
    let silver = C(0xDCE0E8), silverD = C(0x9CA2AE), jewel = C(0xFF3A90)
    let spinning = spin > 0.3
    var gape = 0
    if let a = p.melee, a > -40 { gape = 1 }
    if p.zap == true { gape = 2 }

    // 1. The legs: thick, sandy, lit down the front, dark claws on the toes.
    if seatedPose {
        drawLegs(c, Look(leg: hide))
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            let rise = spinning ? 1 : 0
            c.rect(lx - 1, 34, 3, bottom - 34 - rise, hide); c.rect(lx - 1, 36, 1, bottom - 37 - rise, hideL)
            c.px(lx + 1, bottom - 1 - rise, hideD)
            c.rect(lx - 1, bottom - rise, 3, 1 + rise, hideD); c.px(lx + 2, bottom, claw)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail, held out stiffly behind, swaying a little, tapering to its tip, banded along the top.
    for x in 2...16 {
        let f = Double(16 - x) / 14
        let sway = sin(p.lt * 1.2 + f * 2) * f * 1.2
        let mid = 27 - f * 3 + sway, half = 4.4 - f * 3.5
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, hide)
        c.px(x, bottom, hideD); c.px(x, top, hideL)
        if x % 4 == 1 { c.rect(x, top, 1, max(1, (bottom - top) / 2), stripe) }
    }

    // 4. The body: a great sandy barrel, lit along its back, the pale belly under it, brown bands across the back.
    c.ellipse(28, 28, 15, 8, hide)
    c.ellipse(31, 32, 12, 4, belly)
    c.rect(22, 35, 18, 1, bellyD)
    for x in stride(from: 16, through: 38, by: 4) {
        let dx = Double(x - 28) / 15
        let top = 28 - Int((8 * (1 - dx * dx).squareRoot()).rounded())
        c.rect(x, top + 1, 2, 4, stripe)
        c.px(x - 1, top, hideL); c.px(x + 2, top, hideL)
    }

    // 5. The tutu: hot pink, layered round her hips, its frills scalloped and flared out further as she spins.
    let flare = spinning ? 2 : 0
    c.rect(12, 32, 32, 1, tutuL)
    c.rect(11, 33, 34, 2, tutu); c.rect(41, 33, 4, 2, tutuD)
    c.rect(10 - flare, 35, 36 + flare * 2, 1, tutu)
    for x in stride(from: 9 - flare, through: 45 + flare, by: 2) { c.px(x, 36, tutu); c.px(x + 1, 36, tutuD) }
    for x in stride(from: 14, through: 42, by: 5) { c.px(x, 33, tutuL) }

    if spinning { tinaWand(c, p, spinning: true) }

    // 6. The neck, thick, rising forward to the head.
    v4Line(c, 37, 25, 46, 16, hide, 3.6)
    v4Line(c, 36, 22, 44, 13, hideL, 0.6)
    v4Line(c, 42, 25, 49, 19, belly, 1.2)

    // 7. The head: long and deep, lit along the skull, the nostril, the teeth along the jaw, the pale underjaw, the
    //    little red horns over the eye; the jaw drops as she roars and casts.
    let hx = 42, hy = 7
    c.pattern(hx, hy, [
        ".......LLLLLLL..........",
        ".....LLHHHHHHHLLL.......",
        "...LHHHHHHHHHHHHHHLL....",
        "..LHHHHHHHHHHHHHHHHHHL..",
        ".HHHHHHHHHHHHHHHHHHHHHL.",
        "HHHHHHHHHHHHHHHHHHHHHHHn",
        "HHHHHHHHHHHHHHHHHHHHHHHH",
        "HHHHHHHHHHHHHHHHHHHHHHHd",
        "HHHHHHHHdTdTdTdTdTdTdTd.",
    ], ["H": hide, "L": hideL, "d": hideD, "T": tooth, "n": ink])
    for k in [3, 8, 13] { c.rect(hx + k, hy + 2, 2, 2, stripe) }
    if gape > 0 { c.rect(hx + 8, hy + 9, 15, gape, mouth) }
    c.pattern(hx, hy + 9 + gape, [
        "HHHHHHHHTdTdTdTdTdT.....",
        "HHHHHHHHHHHHHHHHHHd.....",
        ".dBBBBBBBBBBBBBBBd......",
        "..dddddddddddddd........",
    ], ["H": hide, "d": hideD, "T": tooth, "B": belly])
    c.rect(hx + 12, hy + 3, 3, 2, C(0xF4A020)); c.px(hx + 13, hy + 3, ink); c.px(hx + 13, hy + 4, ink)
    c.rect(hx + 11, hy + 2, 5, 1, hideD)
    c.pattern(hx + 13, hy - 1, [".hh", "hhh"], ["h": horn]); c.px(hx + 14, hy - 1, C(0xE0683E))

    // 8. The tiara on her crown: silver, three points, the pink jewel at the middle.
    c.pattern(hx + 3, hy - 3, ["S..j..S", "SSjjjSS", "sssssss"], ["S": silver, "s": silverD, "j": jewel])
    c.px(hx + 6, hy - 3, C(0xFFB0D4))

    // 9. The feather boa round her neck, fluffy and pink, one end hanging down her chest.
    let boaPts: [(Int, Int)] = [(35, 20), (37, 22), (39, 23), (41, 24), (43, 24), (45, 23), (47, 21)]
    for (i, pt) in boaPts.enumerated() {
        c.rect(pt.0 - 1, pt.1 - 1, 3, 3, boa)
        c.px(pt.0 - 1, pt.1 - 1, boaL); c.px(pt.0 + 1, pt.1 + 1, boaD)
        c.px(pt.0 + (i % 2 == 0 ? 2 : -2), pt.1 + (i % 2 == 0 ? 0 : 1), boaL)
    }
    let sway = Int((sin(p.lt * 1.6) * 0.8).rounded())
    for (k, y) in [26, 28, 30, 32].enumerated() {
        let x = 44 + (k % 2) + sway
        c.rect(x - 1, y - 1, 3, 3, boa); c.px(x - 2, y, boaL); c.px(x + 1, y, boaD)
    }

    // 10. The tiny arm and the star wand (behind her head while she spins).
    if !spinning { tinaWand(c, p, spinning: false) }
}

/// Big Tina's tiny arm and the star wand in its claws: down at rest, raised as she casts, held high over her snout as
/// she spins.
private func tinaWand(_ c: PixelCanvas, _ p: Pose, spinning: Bool) {
    let hide = C(0xC89A4E), claw = C(0x2A2018), star = C(0xFFD23A), starD = C(0xD0A020), stick = C(0xF0ECF4)
    let raise = Double(p.armRaise)
    var tip = (x: 54.5, y: 24.5 - raise)
    if spinning { tip = (59.5, 6.5) }
    if p.zap == nil && !spinning { tip = (53.5, 28.5) }
    let hand = spinning ? (x: 46.0, y: 20.0) : (x: 46.0, y: 29.0 - raise * 0.5)
    v4Line(c, 41, 27, hand.x, hand.y, hide, 0.9)
    v4Line(c, hand.x, hand.y, tip.x, tip.y, stick, 0.45)
    c.px(Int(hand.x) + 1, Int(hand.y) + 1, claw); c.px(Int(hand.x), Int(hand.y) + 1, claw)
    let sx = Int(tip.x), sy = Int(tip.y)
    let lit = p.zap == true ? C(0xFFFFFF) : C(0xFFF4C0)
    c.pattern(sx - 2, sy - 2, ["..Y..", ".YYY.", "YYWYY", ".YYD.", "Y...D"], ["Y": star, "D": starD, "W": lit])
}

// MARK: - Gore-Gore

/// Gore-Gore: a train engineer with a second, smaller torso growing up out of the top of his head: two Clawds, one on
/// the other, each with a band of blue warpaint across the eyes. The lower one wears blue denim bib overalls with
/// brass buttons over a red shirt, and work boots; the upper one, a red shirt and a striped hickory engineer's cap with
/// its brim forward. All four fists are in brown leather work gloves, and he punches with both near ones. Signature:
/// both torsos flex, all four arms up, three pumps.
private func drawGoreGore(_ c: PixelCanvas, _ p: Pose) {
    let denim = C(0x3A5A8A), denimD = C(0x26406A), denimL = C(0x5A7AAA)
    let shirt = C(0xB8302C), shirtD = C(0x86201E), shirtL = C(0xD84A40)
    let paint = C(0x2E6ED8), paintL = C(0x5A96F0)
    let glove = C(0x7A4E2C), gloveD = C(0x52321A), gloveL = C(0x9E6A40)
    let brass = C(0xE0B040), cap = C(0x30487A), capL = C(0xDCE2EC)
    let s = p.signature ?? -1
    let flexing = s > 0.08 && s < 0.92
    let pump = flexing ? Int((abs(sin((s - 0.08) / 0.84 * 3 * .pi)) * 2).rounded()) : 0

    func fist(_ x: Int, _ y: Int, _ alpha: Double) {
        c.rect(x - 1, y - 1, 3, 3, glove.alpha(alpha))
        c.px(x - 1, y - 1, gloveL.alpha(alpha)); c.rect(x - 1, y + 1, 3, 1, gloveD.alpha(alpha))
    }

    // 1. Denim legs, dark work boots.
    drawLegs(c, Look(leg: denim), step: p.step)
    drawBoots(c, C(0x2A2420), step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 37, 1, bottom - 39, denimL)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The lower torso in its red shirt, the overalls' bib over it, the straps up over the shoulders, brass buttons.
    drawBody(c, Look(arm: shirt, eye: nil))
    c.rect(18, 32, 20, 6, shirt); c.rect(36, 32, 2, 6, shirtD); c.rect(18, 32, 1, 6, shirtL)
    c.rect(20, 33, 16, 5, denim); c.rect(20, 33, 16, 1, denimL); c.rect(34, 33, 2, 5, denimD)
    c.rect(26, 35, 4, 1, denimD)                                         // the bib pocket
    c.rect(21, 31, 2, 2, denim); c.rect(33, 31, 2, 2, denim)
    c.px(21, 33, brass); c.px(34, 33, brass)
    c.rect(20, 37, 16, 1, denimD)

    // 4. The lower face: the band of blue warpaint across the eyes.
    c.rect(19, 28, 18, 3, paint); c.rect(19, 28, 18, 1, paintL); c.rect(36, 28, 1, 3, C(0x2050A8))
    c.rect(22, 28, 2, 3, ink); c.rect(32, 28, 2, 3, ink)

    // 5. The upper torso, smaller, growing up out of his head: its red shirt, its own warpaint and eyes, its arms.
    let ux = 22, uy = 16
    c.rect(ux, uy, 12, 10, clawdOrange); c.rect(ux + 11, uy, 1, 10, clawdShade)
    c.rect(ux, uy + 6, 12, 4, shirt); c.rect(ux, uy + 6, 1, 4, shirtL); c.rect(ux + 10, uy + 6, 2, 4, shirtD)
    c.rect(ux + 4, uy + 6, 4, 1, clawdOrange)                             // its open collar
    c.rect(ux, uy + 2, 12, 2, paint); c.rect(ux, uy + 2, 12, 1, paintL)
    c.rect(ux + 2, uy + 2, 2, 2, ink); c.rect(ux + 8, uy + 2, 2, 2, ink)
    c.rect(18, 26, 20, 1, clawdShade)                                     // where the two meet

    // 6. The engineer's cap: hickory stripes, blue and white, the brim forward.
    c.pattern(ux - 1, uy - 5, [
        "..WBWBWBWB....",
        ".BWBWBWBWBW...",
        "WBWBWBWBWBWB..",
        "WBWBWBWBWBWBW.",
        "BBBBBBBBBBBBBBBB",
    ], ["W": capL, "B": cap])
    c.rect(ux + 9, uy, 6, 1, C(0x1E2E50))

    // 7. The fists: the far ones at the sides, the near ones punching, or all four up as he flexes.
    if flexing {
        let up = pump
        v4Line(c, 38, 33, 41, 29 - Double(up), shirt, 1.1); fist(41, 27 - up, 1); c.px(40, 30 - up, shirtL)
        v4Line(c, 17, 33, 14, 29 - Double(up), shirt, 1.1); fist(14, 27 - up, 1); c.px(15, 30 - up, shirtL)
        let u2 = 2 - up
        v4Line(c, 34, 22, 37, 18 - Double(u2), shirt, 0.9); fist(37, 16 - u2, 1)
        v4Line(c, 21, 22, 18, 18 - Double(u2), shirt, 0.9); fist(18, 16 - u2, 1)
        c.px(36, 20 - u2, shirtL); c.px(19, 20 - u2, shirtL)
    } else {
        fist(16, 34, 1)
        c.rect(19, 21, 3, 2, shirt); fist(20, 23, 1)
        if let a = p.melee {
            crawlPunch(c, angle: a, trail: p.trail, arm: shirt, fist: fist)
            let a2 = min(10, max(-60, (p.trail.first ?? a) - 30))
            let sh = (34.5, 21.5)
            v4Line(c, sh.0, sh.1, crawlReach(sh, a2, 4).x, crawlReach(sh, a2, 4).y, shirt, 0.9)
            let e = crawlReach(sh, a2, 5)
            fist(Int(e.x.rounded()), Int(e.y.rounded()), 1)
        } else {
            fist(39, 35, 1)
            c.rect(34, 21, 2, 2, shirt); fist(36, 23, 1)
        }
    }
}

// MARK: - Dismember

/// Dismember: an elf necromancer, Clawd with pale grey-lilac skin, long straight silver hair parted at the middle and
/// falling past his shoulders, long elf ears swept back out of it, a bone circlet with a little skull on his brow,
/// narrow eyes with violet light in them under a cruel slant of brows. A long black robe to the ground, edged in
/// violet, a bone clasp at his throat. He casts sickly violet necromantic lightning from his long pale fingers.
/// Signature: he raises a hand, palm up, and green wisps of the dead rise up out of the ground round him, his eyes
/// burning green with them.
private func drawDismember(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC4BCCC), skinD = C(0x9C94AA), skinL = C(0xDEDAE6)
    let hair = C(0xB4BAC8), hairD = C(0x868C9C), hairL = C(0xDCE0E8)
    let robe = C(0x26222E), robeD = C(0x16141C), robeL = C(0x423C50)
    let trim = C(0x8A4ACC), trimL = C(0xB27CF0)
    let bone = C(0xDCD4BC), boneD = C(0xA8A08A)
    let s = p.signature ?? -1
    let raising = v4Arc(s, 0.06, 0.94, edge: 0.12)
    let eye = raising > 0.5 ? C(0x8CF0A0) : C(0xB070F0)

    // 1. The legs under the robe, black boots; only the toes show.
    drawLegs(c, Look(leg: robeD), step: p.step)
    drawBoots(c, C(0x4A4458), step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body: pale skin, lit on the left; the sleeves black.
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil))
    c.rect(18, 26, 1, 7, skinL); c.px(15, 33, robeL)

    // 4. The robe: long to the ground, black, lit on the left, edged in violet down the front and round the hem,
    //    folds and a shadow either side of each leg; the bone clasp at his throat.
    c.rect(18, 32, 20, 4, robe)
    c.rect(17, 36, 22, 3, robe); c.rect(16, 39, 24, 4, robe)
    c.rect(18, 32, 1, 4, robeL); c.rect(17, 36, 1, 3, robeL); c.rect(16, 39, 1, 3, robeL)
    c.rect(36, 32, 2, 4, robeD); c.rect(37, 36, 2, 3, robeD); c.rect(38, 39, 2, 3, robeD)
    for x in [21, 25, 34] { c.rect(x, 37, 1, 5, robeD) }
    c.rect(29, 33, 1, 9, trim); c.px(29, 33, trimL)
    c.rect(16, 42, 24, 1, trim); c.rect(16, 42, 6, 1, trimL)
    c.rect(18, 32, 20, 1, trim)
    c.rect(28, 32, 3, 2, bone); c.px(30, 33, boneD)

    // 5. The face: narrow eyes with light in them, the brows slanting down to the middle.
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink)
    c.px(23, 29, eye); c.px(33, 29, eye)
    c.pattern(20, 27, ["dd..", "..dd"], ["d": skinD])
    c.pattern(31, 27, ["..dd", "dd.."], ["d": skinD])
    c.rect(26, 32, 4, 1, skinD)

    // 6. The ears: long and pointed, swept back and up out of the hair.
    c.pattern(12, 23, ["S....", ".SS..", "..SSS", "...SS"], ["S": skin])
    c.px(12, 23, skinL)
    c.pattern(39, 23, ["....S", "..SS.", "SSS..", "SS..."], ["S": skinD])

    // 7. The hair: long, straight and silver, parted at the middle, in strands down past his shoulders, lit along
    //    the crown.
    c.pattern(15, 20, [
        ".....LLLLLLL.LLLLLLL......",
        "...LLHHHHHHHdHHHHHHHLL....",
        "..LHHHHHHHHHdHHHHHHHHHL...",
        ".HHHhHHHhHHHdHHHhHHHhHHH..",
        ".HHHhHHHhHHd.dHHhHHHhHHH..",
        "HHHhHHHhHHd...dHHhHHHhHHH.",
        "HHhHH.............HHhHHH..",
        "HHhH...............HhHH...",
        "HhHH................HhH...",
        "HhH.................HhH...",
        "HhH..................hH...",
        "HhH..................H....",
        "HH........................",
        "Hh........................",
        "H.........................",
    ], ["H": hair, "h": hairD, "d": hairD, "L": hairL])

    // 8. The bone circlet across his brow, the little skull at its middle.
    c.rect(19, 25, 18, 1, bone); c.rect(33, 25, 4, 1, boneD)
    c.pattern(27, 23, ["BBB", "kBk", ".B."], ["B": bone, "k": ink])

    // 9. The near hand: long pale fingers, down at his side, raised as he casts, or held up high, palm up, as the
    //    wisps rise.
    if raising > 0 {
        let r = Int((raising * 8).rounded())
        v4Line(c, 39, 33.5, 41, 33.5 - Double(r), robe, 1.3)
        c.pattern(40, 30 - r, ["S.S.S", "SSSSS", ".SSS."], ["S": skin])
        // The wisps: pale green, wavering up out of the ground, fading as they climb.
        for i in 0..<6 {
            let k = (s * 2.2 + Double(i) / 6).truncatingRemainder(dividingBy: 1)
            let bx: Double = [11, 15, 44, 48, 52, 8][i]
            let y = 40 - k * 24
            let x = bx + sin(k * 9 + Double(i)) * 1.6
            let a = raising * min(1, (1 - k) * 1.6)
            c.glowLine(x, y, x + sin(k * 9 + Double(i) + 1) * 1.5, y + 4, core: C(0xD8FFE0, a), glow: C(0x48D070, a * 0.6),
                       coreR: 0.7, glowR: 2)
        }
    } else if p.zap != nil {
        let r = p.armRaise
        c.rect(38, 32 - r, 3, 3, robe); c.px(38, 32 - r, robeL)
        c.pattern(41, 31 - r, ["SSSS.", "SSSSS", ".SS.."], ["S": skin]); c.px(41, 31 - r, skinL)
    } else {
        c.pattern(38, 34, ["SSS", "S.S", "S.S"], ["S": skin])
    }
}

// MARK: - Queen Imogen

/// Queen Imogen: Clawd as a queen of the ballroom, her face painted in gold leaf round the eyes and across the brow,
/// gold lips, long lashes; her near-black hair piled up high in a tall beehive, strands swept up round it and gold
/// pins through it; a gown to the floor that shifts slowly through its colours, a gold collar at its neckline and a
/// gold sash at the waist, gold slippers peeping under the hem; long curved gold claws for nails. Her telekinesis
/// ripples out in gold rings. Signature: her gown shimmers through every colour, a light running down it as it turns.
private func drawImogen(_ c: PixelCanvas, _ p: Pose) {
    let gold = C(0xE8BE48), goldD = C(0xB08A28), goldL = C(0xFFE68A)
    let hair = C(0x7A2836), hairD = C(0x4E1622), hairL = C(0xA84A5A)
    let s = p.signature ?? -1
    let shimmer = v4Arc(s, 0.06, 0.94, edge: 0.1)
    let hue = 0.45 + 0.05 * sin(p.lt * 0.25) + (s > 0 ? v4Ease(s, 0.06, 0.94) : 0)
    let gown = v4Hue(hue, 0.62, 0.62), gownD = v4Hue(hue, 0.7, 0.42), gownL = v4Hue(hue, 0.42, 0.86)

    // 1. The legs under the gown, only the gold slippers' toes showing.
    drawLegs(c, Look(leg: goldD), step: p.step)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, the sleeves in the gown's colour.
    drawBody(c, Look(arm: gown, eye: nil))
    c.px(15, 33, gownL); c.rect(15, 35, 3, 1, gownD)

    // 4. The gown: long to the floor, flaring, lit on the left, its folds, a shadow either side of each leg; the gold
    //    collar and the sash.
    c.rect(18, 32, 20, 4, gown)
    c.rect(17, 36, 22, 3, gown); c.rect(15, 39, 26, 4, gown)
    c.rect(18, 32, 1, 4, gownL); c.rect(17, 36, 1, 3, gownL); c.rect(15, 39, 1, 4, gownL)
    c.rect(36, 32, 2, 4, gownD); c.rect(37, 36, 2, 3, gownD); c.rect(39, 39, 2, 4, gownD)
    for x in [21, 26, 33] { c.rect(x, 37, 1, 6, gownD); c.px(x - 1, 38, gownL) }
    c.rect(19, 33, 18, 1, gold); c.rect(19, 33, 4, 1, goldL); c.px(28, 34, gold); c.px(28, 34, goldL)
    c.rect(18, 36, 20, 1, gold); c.rect(35, 36, 3, 1, goldD)
    if shimmer > 0 {
        // The light running down her gown as it turns.
        let band = 32 + ((s - 0.06) / 0.88 * 22).truncatingRemainder(dividingBy: 11)
        for y in 32...42 where abs(Double(y) - band) < 1.5 {
            for x in 15...40 where c.isDrawn(x, y) && (x + y) % 2 == 0 { c.px(x, y, C(0xFFFFFF, 0.55 * shimmer)) }
        }
    }

    // 5. The face: gold leaf round the eyes and across the brow, long lashes, gold lips.
    c.rect(21, 28, 4, 1, gold); c.rect(31, 28, 4, 1, gold); c.px(21, 28, goldL); c.px(31, 28, goldL)
    c.rect(26, 27, 4, 1, gold); c.px(27, 26, goldL); c.px(28, 26, gold)
    for (x, y) in [(20, 31), (21, 32), (35, 31), (34, 32), (25, 30), (30, 30)] { c.px(x, y, gold) }
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 29, ink); c.px(34, 29, ink); c.px(20, 28, ink); c.px(35, 28, ink)
    c.rect(27, 32, 2, 1, goldD)

    // 6. The hair: piled up high in a tall beehive, strands swept up round it, lit on the left, gold pins through it,
    //    and falling either side of her face.
    c.pattern(17, 8, [
        "........HHHHHH......",
        "......HHlHHHHhHH....",
        ".....HlHHHHhHHHHH...",
        "....HHlHHHhHHHHHHH..",
        "....HlHHHhHHHHHhHH..",
        "...HHlHHhHHHHHhHHHH.",
        "...HlHHhHHHHHhHHHHH.",
        "...HlHHhHHHHhHHHHHH.",
        "...HlHHHhHHHhHHHHHh.",
        "...HHlHHhHHHHhHHHHh.",
        "....HlHHHhHHHhHHHh..",
        "....HHlHHhHHHHhHHh..",
        ".....HHHHHhHHHhHh...",
        "...HHHHHHHHhHHHHHHH.",
        "..HHlHHHHHHHHHhHHHHH",
        ".HHlHHHHHHHHHHHHhHHH",
        ".HlHHHHHHHHHHHHHHhHH",
        ".HHH.............HHH",
        ".HH...............HH",
        ".HH...............Hh",
        ".H................H.",
        ".H..................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(18, 25, 20, 1, hairD)
    for (x, y) in [(22, 11), (32, 13), (27, 9)] { c.px(x, y, goldL); c.px(x + 1, y + 1, gold) }
    c.rect(19, 21, 18, 1, gold); c.rect(19, 21, 5, 1, goldL)                 // the band round the base of it

    // 7. The near hand and its long gold claws: down at her side, or held out as she casts.
    if p.zap != nil {
        let r = p.armRaise
        c.rect(38, 32 - r, 3, 3, gown); c.px(38, 32 - r, gownL)
        c.rect(41, 32 - r, 2, 3, clawdOrange)
        c.pattern(43, 30 - r, ["..G.", ".G..", ".GG.", "..GG", ".G.."], ["G": gold])
        c.px(44, 31 - r, goldL)
    } else {
        c.rect(38, 33, 3, 3, gown); c.px(38, 33, gownL)
        c.rect(39, 36, 2, 1, clawdOrange)
        c.pattern(39, 37, ["G.G", "G.G", ".G."], ["G": gold])
    }
}

// MARK: - Shi Maria

/// Shi Maria: a huge spider with a haggard woman's head: the head is Clawd, orange, lined and tired, sunken bags under
/// the eyes and a thin grim mouth, long stringy grey hair hanging down from the crown; her near eye is a faceted cyan
/// jewel. Under her chin a dark, bristly spider's body, and behind it a great bulb of an abdomen marked with pale bone
/// chevrons; eight legs, Clawd's four in black chitin and four more arching high out of her sides, their knees lit.
/// Her illusions are a touch: she raises a foreleg and its tip glows, rainbow sparkles winding round it. Signature:
/// the jewel eye flashes, rays of every colour wheeling out of it.
private func drawShiMaria(_ c: PixelCanvas, _ p: Pose) {
    let chitin = C(0x2E2430), chitinD = C(0x1C161E), chitinL = C(0x4C3E4E), far = C(0x42364A), bristle = C(0x6A5A66)
    let mark = C(0xC8B898)
    let hair = C(0xA8A49C), hairD = C(0x7C786E), hairL = C(0xC8C4BA)
    let jewel = C(0x3AD8C8), jewelD = C(0x1A8080), jewelL = C(0xC8FFF8)
    let s = p.signature ?? -1
    let flash = v4Arc(s, 0.15, 0.8, edge: 0.15)
    let casting = p.zap != nil

    // The four extra legs: root, knee, tip. The near front one lifts to cast.
    typealias Leg = (a: (Double, Double), k: (Double, Double), t: (Double, Double))
    let farLegs: [Leg] = [((20, 32), (10, 19), (3, 43)), ((36, 32), (45, 20), (51, 43))]
    var nearLegs: [Leg] = [((21, 35), (13, 23), (9, 43)), ((37, 34), (49, 22), (58, 43))]
    if casting { nearLegs[1] = ((37, 34), (48, 21), (56, 27 - Double(p.armRaise))) }
    func leg(_ l: Leg, _ i: Int, _ col: Px, lit: Px) {
        let lifted = p.step >= 0 && i % 2 == p.step
        let knee = (l.k.0, l.k.1 - (lifted ? 1 : 0))
        let tip = (l.t.0 + (lifted ? 1 : 0), l.t.1 - (lifted && l.t.1 > 40 ? 2 : 0))
        v4Line(c, l.a.0, l.a.1, knee.0, knee.1, col, 1.2)
        v4Line(c, knee.0, knee.1, tip.0, tip.1, col, 0.8)
        c.px(Int(knee.0), Int(knee.1), lit); c.px(Int(knee.0) - 1, Int(knee.1), lit)
        let m = ((knee.0 + tip.0) / 2, (knee.1 + tip.1) / 2)
        c.px(Int(m.0) + 1, Int(m.1), bristle)
    }

    // 1. The far pair of extra legs, behind everything.
    for (i, l) in farLegs.enumerated() { leg(l, i + 1, far, lit: bristle) }

    // 2. Clawd's four legs in black chitin, a pale band at each joint, bristles.
    drawLegs(c, Look(leg: chitin), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 39, 2, 1, chitinL); c.px(lx + 2, 37, bristle); c.px(lx - 1, 41, bristle)
            c.px(lx + 1, bottom, chitinD)
        }
    }

    // 3. The breath.
    c.oy += p.breathe

    // 4. The abdomen: a great dark bulb behind her, shaded under, lit along the top, bone chevrons down its back,
    //    bristles in short strokes.
    c.ellipse(11, 28, 9, 9, chitinD)
    c.ellipse(11, 27, 9, 8, chitin)
    c.rect(7, 20, 7, 1, chitinL); c.rect(5, 21, 2, 1, chitinL)
    c.pattern(6, 22, ["M.....M", "MM...MM", ".MMMMM.", "...M..."], ["M": mark])
    c.pattern(7, 28, ["M...M", "MMMMM", "..M.."], ["M": mark])
    c.pattern(8, 33, ["M.M", ".M."], ["M": mark])
    for (x, y) in [(3, 25), (4, 32), (17, 22), (14, 35)] { c.px(x, y, bristle); c.px(x + (x < 10 ? -1 : 1), y - 1, bristle) }

    // 5. Under her chin, the spider's body: dark chitin, bristly, lit on top; the head above it.
    drawBody(c, Look(body: chitin, shade: chitinD, arm: chitin, eye: nil))
    c.rect(18, 26, 20, 7, clawdOrange); c.rect(37, 26, 1, 7, clawdShade)
    c.rect(18, 33, 20, 1, chitinL)
    for x in [21, 26, 31, 35] { c.px(x, 35, bristle); c.px(x + 1, 36, bristle) }

    // 6. The face: lined and tired, the far eye sunken over a bag, the jewel for the near eye, a thin grim mouth.
    c.rect(21, 27, 4, 1, clawdShade); c.rect(31, 27, 5, 1, clawdShade)
    c.rect(22, 29, 2, 2, ink); c.rect(21, 31, 3, 1, C(0x9A5A5A)); c.px(20, 30, clawdShade)
    c.rect(26, 32, 4, 1, C(0x6A2A2A)); c.px(25, 32, clawdShade); c.px(30, 32, clawdShade)
    c.px(27, 29, clawdShade); c.px(27, 30, clawdShade)
    let jc = flash > 0.5 ? C(0xFFFFFF) : jewel
    c.pattern(31, 28, [".jL.", "jjjL", "Djjj", ".DD."], ["j": jc, "L": jewelL, "D": jewelD])

    // 7. The hair: long, stringy and grey, hanging from her crown down over her back and either side of her face.
    c.pattern(15, 19, [
        ".....LLLLLLLLLLLL.....",
        "...LLHHHhHHHHhHHHLL...",
        "..HHhHHHhHHHhHHHhHHH..",
        ".HHhHHHhHHHHhHHHHhHHH.",
        ".HHhHHHhHHHhHHHHhHHHH.",
        "HHhHHHhHHHHHhHHHhHHHHH",
        "HHhHH.H..H...H..HhHHHH",
        "HhHH..............HhHH",
        "HhHH..............hH.H",
        "HhH...............HH.h",
        "HhH...............H...",
        "Hh.H..............h...",
        "H..h..................",
        "h.....................",
    ], ["H": hair, "h": hairD, "L": hairL])

    // 8. The near pair of extra legs, over her body.
    for (i, l) in nearLegs.enumerated() { leg(l, i, chitin, lit: chitinL) }

    // 9. The touch: rainbow sparkles winding round the raised leg's tip.
    if casting {
        let tip = (56.0, 27.0 - Double(p.armRaise))
        for i in 0..<4 {
            let a = p.lt * 5 + Double(i) * .pi / 2
            let col = v4Hue(p.lt * 0.7 + Double(i) / 4, 0.7, 1)
            c.px(Int((tip.0 + cos(a) * 3).rounded()), Int((tip.1 + sin(a) * 3).rounded()), col)
        }
    }

    // 10. The flash: rays of every colour wheeling out of the jewel.
    if flash > 0 {
        let cx = 33.0, cy = 29.5
        for i in 0..<8 {
            let a = Double(i) * .pi / 4 + s * 3
            let len = 2 + flash * 6
            let col = v4Hue(Double(i) / 8 + s * 2, 0.75, 1)
            c.glowLine(cx + cos(a) * 2, cy + sin(a) * 2, cx + cos(a) * len, cy + sin(a) * len,
                       core: col.alpha(0.9 * flash), glow: col.alpha(0.35 * flash), coreR: 0.4, glowR: 1.2)
        }
    }
}
