import Foundation

// Heroes, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The Popov brothers, Miriam Dom and Juice Box, and the rest of the Desperado Club's dancers: Gluteus Maxx,
// Dong Quixote, Damascus Steel, Anaconda, Rosemarie.

let crawlHeroes5: [CrawlHero: Persona] = [
    .popovs: Persona(name: "The Popov brothers", weapon: .saber, pivot: (45.5, 34.5), bulk: 4, headTop: 5,
                     signature: 3.4, draw: drawPopovs),
    .miriamDom: Persona(name: "Miriam Dom", weapon: .saber, headTop: 11, signature: 4.0, draw: drawMiriamDom),
    .juiceBox: Persona(name: "Juice Box", weapon: .none, headTop: 19, signature: 4.2, draw: drawJuiceBox),
    .gluteusMaxx: Persona(name: "Gluteus Maxx", weapon: .saber, headTop: 22, signature: 2.8, draw: drawGluteusMaxx),
    .dongQuixote: Persona(name: "Dong Quixote", weapon: .saber, headTop: 21, signature: 3.4, draw: drawDongQuixote),
    .damascusSteel: Persona(name: "Damascus Steel", weapon: .saber, armoured: true, headTop: 22, signature: 3.6,
                            draw: drawDamascusSteel),
    .anaconda: Persona(name: "Anaconda", weapon: .saber, headTop: 25, signature: 2.6, draw: drawAnaconda),
    .rosemarie: Persona(name: "Rosemarie", weapon: .blaster, shot: .thrown(C(0xF2C232)), muzzle: (43, 33),
                        handGun: false, headTop: 21, signature: 3.0, draw: drawRosemarie),
]

// MARK: - Shared bits

/// The bottom row of leg `i` this frame: a row higher while it's lifted in the walk.
private func footRow(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

/// Draws `art` on a scratch canvas (no offsets), turns it `degrees` about `pivot` (positive: clockwise) and lays it
/// on `c` with its offsets: a body bowing from the hips.
private func turned(_ c: PixelCanvas, _ degrees: Double, about pivot: (x: Double, y: Double), _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    if abs(degrees) < 0.5 { c.paste(s); return }
    c.paste(s.rotated(degrees, about: pivot, into: c.w, c.h, at: pivot))
}

/// Draws `art` on a scratch canvas (no offsets) and lays it on `c` squeezed sideways to `scale` (0…1) about Clawd's
/// middle, column 27.5, and mirrored when `back`: a body turning on the spot, seen from the side.
private func spun(_ c: PixelCanvas, scale: Double, back: Bool, _ art: (PixelCanvas) -> Void) {
    let s = PixelCanvas(c.w, c.h)
    art(s)
    let k = max(0.25, scale)
    for x in 0..<s.w {
        var src = 27.5 + (Double(x) + 0.5 - 27.5) / k
        if back { src = 55 - src }
        let sx = Int(floor(src))
        guard sx >= 0, sx < s.w else { continue }
        for y in 0..<s.h {
            let i = (y * s.w + sx) * 4
            guard s.buf[i + 3] > 0 else { continue }
            c.px(x, y, unpremultiplied(s, i))
        }
    }
}

/// Clawd's body block without the arm nubs, for when the arms are drawn somewhere else (raised, out wide).
private func torso(_ c: PixelCanvas, _ body: Px, _ shade: Px) {
    c.rect(18, 26, 20, 12, body)
    c.rect(18, 37, 20, 1, shade)
    c.rect(37, 26, 1, 12, shade)
}

/// A long robe or skirt from row `from` to the ground: a little wider below the hips, flaring at the hem, lit on the
/// left, a soft fold either side of each leg under it.
private func robe(_ c: PixelCanvas, _ col: Px, _ dark: Px, _ light: Px, from: Int, hem: Int) {
    c.rect(18, from, 20, hem - from, col)
    c.rect(17, from + 3, 22, hem - from - 3, col)
    c.rect(16, hem - 2, 24, 2, col)
    c.rect(18, from, 1, hem - from - 2, light); c.rect(17, from + 3, 1, hem - from - 3, light)
    c.rect(16, hem - 1, 24, 1, dark); c.rect(38, from + 3, 1, hem - from - 3, dark)
    if !seatedPose {
        for x in [22, 27, 30, 34] { c.rect(x, from + 4, 1, hem - from - 5, dark) }
    }
}

// MARK: - The Popov brothers

/// The Popov brothers: two men in one seven-foot body, Clawd grown huge and broad in grey skin, two heads side by side
/// on two thick necks. The far brother is bald, a heavy black brow and a stubbled jaw; the near one wears a knitted
/// mustard beanie, its ribs and turned-up cuff picked out. A brown leather jerkin laced up the front over the shared
/// chest, a belt, grey-blue trousers and boots. They fight with a meteor hammer: an iron weight on a red rope, swung
/// out from the near fist (a second, smaller weight on the rope's other end). Signature: the two heads argue, turning
/// on each other, shouting in turn, an angry vein on whoever's being shouted at.
private func drawPopovs(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8C8E96), skinD = C(0x686A72), skinL = C(0xB0B2BA), stub = C(0x74767E)
    let vest = C(0x6E4C30), vestD = C(0x4C3420), vestL = C(0x926A46), lace = C(0xD8C8A0)
    let cloth = C(0x3A4252), clothD = C(0x2A303C), boot = C(0x221E1C)
    let beanie = C(0xD69A30), beanieD = C(0xA87420), beanieL = C(0xF2C060)
    let brow = C(0x24201E), mouth = C(0x3A1E22), tooth = C(0xF0ECE0), vein = C(0xE8384A)
    let rope = C(0xB8342C), iron = C(0x3E4048), ironL = C(0x8A8E9A), ironD = C(0x26272D)
    let s = p.signature ?? -1
    let arguing = s > 0.06 && s < 0.94
    // Who's shouting: the far head (0) or the near one (1), turn about.
    let shouter = arguing ? Int((s - 0.06) * 9) % 2 : -1

    // 1. Thick legs in grey-blue trousers, a seam down the shaded side, heavy boots.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 5, 2, cloth); c.rect(lx - 1, 39, 5, 1, clothD) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, 36, 3, b - 35, cloth)
            c.rect(lx + 2, 36, 1, b - 37, clothD)
            c.rect(lx, b - 1, 3, 2, boot); c.px(lx, b - 1, C(0x403A36))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The far arm, thick and grey, a fist at its end.
    c.rect(9, 23, 5, 11, skin); c.rect(9, 23, 1, 11, skinL); c.rect(13, 24, 1, 10, skinD)
    c.rect(9, 34, 5, 3, skin); c.rect(9, 34, 5, 1, skinL); c.rect(9, 36, 5, 1, skinD)

    // 4. The great shared chest, lit on top and the left, the far side in shade.
    c.rect(14, 21, 29, 17, skin)
    c.rect(14, 21, 29, 1, skinL); c.rect(14, 21, 1, 17, skinL); c.rect(42, 21, 1, 17, skinD)

    // 5. The leather jerkin, laced up the front over a strip of grey chest, lit along its top; a belt and buckle.
    c.rect(14, 25, 29, 13, vest)
    c.rect(14, 25, 29, 1, vestL); c.rect(14, 25, 1, 13, vestL); c.rect(41, 26, 2, 12, vestD)
    c.rect(27, 25, 3, 9, skin); c.rect(27, 25, 3, 1, skinL)
    for y in [27, 30, 33] { c.px(26, y, lace); c.px(30, y, lace); c.px(27, y + 1, lace); c.px(29, y + 1, lace) }
    c.rect(18, 29, 1, 5, vestD); c.rect(37, 29, 1, 5, vestD)   // creases
    c.rect(14, 35, 29, 2, C(0x2A1E16)); c.rect(26, 35, 4, 2, C(0xC8A44A)); c.rect(27, 35, 2, 1, C(0x2A1E16))
    c.rect(14, 37, 29, 1, clothD)

    // 6. Two thick necks.
    c.rect(17, 18, 7, 4, skin); c.rect(17, 18, 1, 4, skinL); c.rect(23, 18, 1, 4, skinD)
    c.rect(33, 18, 7, 4, skin); c.rect(33, 18, 1, 4, skinL); c.rect(39, 18, 1, 4, skinD)

    // 7. The far brother's head: bald and round, a shine on top, a heavy black brow, small eyes, a stubbled jaw. He
    //    turns to his brother when they argue, and leans in when it's his turn to shout.
    let ax = shouter == 0 ? 1 : 0, look = arguing ? 1 : 0
    c.ox += ax
    c.pattern(14, 8, [
        "...hhhhhhh...",
        "..hLLLhhhhh..",
        ".hLhhhhhhhhd.",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hssssssssssd.",
        ".sssssssssd..",
        "..ssssssss...",
    ], ["h": skin, "L": skinL, "d": skinD, "s": stub])
    c.rect(16 + look, 12, 4, 1, brow); c.rect(22 + look, 12, 4, 1, brow)
    c.rect(17 + look, 13, 2, 2, ink); c.rect(23 + look, 13, 2, 2, ink)
    if shouter == 0 {
        c.rect(20 + look, 16, 4, 2, mouth); c.rect(20 + look, 16, 4, 1, tooth)
    } else {
        c.rect(20 + look, 16, 4, 1, mouth)
    }
    if shouter == 1 { c.pattern(15, 10, ["v.v", ".v.", "v.v"], ["v": vein]) }
    c.ox -= ax

    // 8. The near brother's head, in the knitted beanie: its ribs, the turned-up cuff, lit on the left.
    let bx = shouter == 1 ? -1 : 0
    c.ox += bx
    c.pattern(30, 5, [
        "....BBBBB....",
        "..BBbBbBbBB..",
        ".BlBbBbBbBbB.",
        ".BlBbBbBbBbBd",
        "BlBBbBbBbBbBd",
        "LLLLLLLLLLLLd",
        "CCCCCCCCCCCCd",
    ], ["B": beanie, "b": beanieD, "l": beanieL, "L": beanieL, "C": beanie, "d": beanieD])
    c.pattern(30, 12, [
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhhd",
        "hhhhhhhhhhhd.",
        ".hhhhhhhhhd..",
    ], ["h": skin, "d": skinD])
    c.rect(30, 12, 1, 5, skinL)
    c.rect(32 - look, 12, 3, 1, C(0x5A4A3A)); c.rect(38 - look, 12, 3, 1, C(0x5A4A3A))
    c.rect(33 - look, 13, 2, 2, ink); c.rect(38 - look, 13, 2, 2, ink)
    c.rect(36 - look, 15, 2, 1, skinD)   // the nose
    if shouter == 1 {
        c.rect(34 - look, 16, 4, 2, mouth); c.rect(34 - look, 16, 4, 1, tooth)
    } else {
        c.rect(34 - look, 17, 4, 1, mouth)
    }
    if shouter == 0 { c.pattern(40, 13, ["v.v", ".v.", "v.v"], ["v": vein]) }
    c.ox -= bx

    // 9. The shout: three short lines out of the shouting mouth towards the other head.
    if shouter == 0 {
        for (x, y) in [(27, 14), (28, 16), (27, 18)] { c.rect(x, y, 2, 1, C(0xFFFFFF)) }
    } else if shouter == 1 {
        for (x, y) in [(28, 14), (27, 16), (28, 18)] { c.rect(x, y, 2, 1, C(0xFFFFFF)) }
    }

    // 10. The near arm and fist, and the meteor hammer: a red rope, an iron weight at its end, swung out at whatever
    //     angle it's going; at rest the weight hangs from the fist near the ground, the rope's second, smaller weight
    //     dangling short.
    c.rect(43, 23, 4, 10, skin); c.rect(43, 23, 1, 10, skinL); c.rect(46, 24, 1, 9, skinD)
    let hand = (x: 45.5, y: 34.5)
    func weight(_ x: Int, _ y: Int, _ al: Double) {
        c.pattern(x - 2, y - 2, [
            ".III.",
            "ILLII",
            "ILIII",
            "IIIIi",
            ".iii.",
        ], ["I": iron.alpha(al), "L": ironL.alpha(al), "i": ironD.alpha(al)])
    }
    if let a = p.melee {
        for (i, t) in p.trail.enumerated() {
            let e = crawlReach(hand, t, 12)
            weight(Int(e.x.rounded()), Int(e.y.rounded()), 0.3 / Double(i + 1))
        }
        crawlBar(c, hand, a, from: 1, to: 11, rope, r: 0.5)
        let e = crawlReach(hand, a, 12)
        weight(Int(e.x.rounded()), Int(e.y.rounded()), 1)
        c.rect(46, 37, 1, 2, rope); c.rect(46, 39, 2, 2, iron); c.px(46, 39, ironL)
    } else {
        let sway = Int((sin(p.lt * 1.8) * 1.2).rounded())
        c.rect(47, 37, 1, 2, rope); c.px(47 + sway, 39, rope)
        weight(48 + sway, 41, 1)
        c.rect(44, 37, 1, 3, rope); c.rect(44, 40, 2, 2, iron); c.px(44, 40, ironL)
    }
    c.rect(43, 33, 5, 4, skin); c.rect(43, 33, 5, 1, skinL); c.rect(43, 36, 5, 1, skinD); c.px(47, 34, skinD)
}

// MARK: - Miriam Dom

/// Miriam Dom: an old shepherdess, Clawd in a long undyed wool robe of oatmeal brown to the ground, a dark green
/// shawl round her shoulders with a fringe, and a cream headscarf over her head and down her back, grey hair showing
/// at her temples, kind grey brows. Her hooked shepherd's staff is pale ash wood, its crook curled over at the top;
/// she fights with it. Signature: one of her little goats trots past in front of her, white with curved horns and a
/// beard, and she follows it with her eyes.
private func drawMiriamDom(_ c: PixelCanvas, _ p: Pose) {
    let wool = C(0x8E7252), woolD = C(0x6A5238), woolL = C(0xAC8E6C)
    let shawl = C(0x3E5E3A), shawlD = C(0x2A4228), shawlL = C(0x5A7E52)
    let scarf = C(0xE6DAC0), scarfD = C(0xBCAE90), scarfL = C(0xFFF8E6), grey = C(0xB4B0A8)
    let wood = C(0xB48C58), woodD = C(0x7E5C34), woodL = C(0xD6B07C)
    let s = p.signature ?? -1
    let goatK = s > 0.06 && s < 0.94 ? (s - 0.06) / 0.88 : -1.0

    // 1. The legs under the robe, the toes peeping out under the hem.
    drawLegs(c, Look(leg: woolD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, footRow(i, p.step), 2, 1, clawdShade) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, the far arm in the robe's sleeve.
    drawBody(c, Look(arm: wool, eye: nil))
    c.px(15, 33, woolL); c.rect(15, 35, 3, 1, woolD)

    // 4. The long robe from the shoulders to the ground.
    robe(c, wool, woolD, woolL, from: 32, hem: seatedPose ? 39 : 42)

    // 5. The green shawl round her shoulders, lit on top, a fringe along its lower edge.
    c.rect(17, 32, 22, 3, shawl)
    c.rect(17, 32, 22, 1, shawlL); c.rect(38, 32, 1, 3, shawlD)
    for x in stride(from: 18, through: 37, by: 2) { c.px(x, 35, shawlD) }
    c.rect(26, 33, 3, 2, shawlD); c.px(27, 33, shawlL)   // the knot at her throat

    // 6. The face: Clawd's eyes, glancing down at the goat as it passes; kind grey brows, a small smile.
    let glance = goatK > 0 ? (goatK < 0.5 ? 0 : 1) : 0
    c.rect(22 + glance, 29, 2, 3, ink); c.rect(32 + glance, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, grey); c.rect(32, 28, 3, 1, grey)
    c.rect(26, 31, 3, 1, clawdShade); c.px(25, 30, clawdShade); c.px(29, 30, clawdShade)

    // 7. The headscarf: over the top of her head, lit along its crown, framing her face, and falling down her back;
    //    grey hair in strands at her temples.
    c.pattern(16, 21, [
        "......SSSSSSSSSSS.....",
        "....SSLLLLLLLLLLSSS...",
        "...SSLSSSSSSSSSSSSSS..",
        "..SSSSSSSSSSSSSSSSSSS.",
        "..SSSSdddddddddddSSSSd",
        "..SSSh...........hSSd.",
        "..SSSh...........hSd..",
        "..SSh.............h...",
        "..SSh.................",
        "..SSd.................",
        "..Ssd.................",
        "..sd..................",
    ], ["S": scarf, "L": scarfL, "d": scarfD, "s": scarfD, "h": grey])

    // 8. The staff: pale ash, a lit edge up its near side, the crook curled over at the top; upright beside her, its
    //    foot on the ground, or swung, crook first.
    c.oy += p.gunY
    if let a = p.melee {
        let hand = Sprite.hand
        for (i, t) in p.trail.enumerated() { crawlBar(c, hand, t, from: 4, to: 13, wood.alpha(0.3 / Double(i + 1)), r: 0.7) }
        crawlBar(c, hand, a, from: -4, to: 13, wood, r: 0.8)
        let e = crawlReach(hand, a, 13)
        let q1 = crawlReach(e, a + 55, 2.6), q2 = crawlReach(q1, a + 125, 2.6), q3 = crawlReach(q2, a + 190, 2)
        for (u, v) in [(e, q1), (q1, q2), (q2, q3)] {
            c.glowLine(u.x, u.y, v.x, v.y, core: wood, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
        }
        c.rect(39, 33, 3, 3, wool); c.px(39, 33, woolL)
    } else {
        c.rect(42, 17, 2, 27, wood); c.rect(42, 17, 1, 27, woodL); c.rect(43, 38, 1, 6, woodD)
        c.pattern(42, 11, [
            ".WWWW..",
            "lW..WW.",
            "lW...WW",
            "lW...dW",
            "lW....d",
            "lW.....",
        ], ["W": wood, "l": woodL, "d": woodD])
        c.rect(39, 33, 4, 3, wool); c.px(39, 33, woolL); c.rect(41, 33, 3, 2, clawdOrange)
    }
    c.oy -= p.gunY

    // 9. The goat, trotting past in front of her from the left to the right: white, curved grey horns, a little
    //    beard and an upturned tail, its legs taking turns.
    c.oy -= p.breathe
    if goatK > 0 {
        let gx = 3 + Int((goatK * 54).rounded())
        let trot = Int(p.lt * 9) % 2
        let goatW = C(0xF2EEE6), goatD = C(0xC8C2B6), horn = C(0x8A7C64), hoof = C(0x4A4038)
        c.pattern(gx, 35 - trot, [
            "........hh..",
            ".t.......hW.",
            "tt.....WWkWW",
            "WWWWWWWWWWWn",
            "WWWWWWWWWb..",
            "dWWWWWWWdb..",
        ], ["W": goatW, "d": goatD, "h": horn, "t": goatW, "k": ink, "n": C(0xE0A0A0), "b": goatD])
        let legs = trot == 0 ? ["l..l...l.l..", "o..o...o.o.."] : [".l..l..l..l.", ".o..o..o..o."]
        c.pattern(gx, 41 - trot, [legs[0], legs[0], legs[1]], ["l": goatD, "o": hoof])
    }
}

// MARK: - Juice Box

/// Juice Box: a changeling. Most of the time a gum-chewing blonde: long straight platinum hair falling past her
/// shoulders, a light denim jacket open over a pink top, black leggings and white sneakers, her jaw working on a piece
/// of pink gum. Now and then her ratkin form: grey-brown fur, big round pink ears, a pointed snout with a pink nose and
/// whiskers, a long pink tail, in a purple jumpsuit zipped up the front. She doesn't fight. Signature: she blows a big
/// pink bubble, it pops in a puff of smoke, and she's the ratkin; another puff and she's back.
private func drawJuiceBox(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let rat = s > 0.37 && s < 0.77
    let gum = C(0xF890C8), gumL = C(0xFFD0EA), gumD = C(0xD0609C)
    if rat {
        drawJuiceBoxRat(c, p)
    } else {
        drawJuiceBoxGirl(c, p, blowing: s > 0.06 && s < 0.37)
    }

    // The bubble, blown out of her mouth until it bursts, and the puff of smoke round her at each change.
    if s > 0.08 && s < 0.35 {
        let r = Int(((s - 0.08) / 0.27 * 4.5).rounded())
        if r >= 1 {
            c.circle(28, 33 - r / 2, r, gum)
            c.circle(28, 33 - r / 2, max(0, r - 1), gum)
            c.rect(28 - r / 2, 33 - r / 2 - r + 1, max(1, r / 2), 1, gumL)
            c.px(28 + r - 1, 33 - r / 2 + 1, gumD)
        } else {
            c.px(28, 33, gum)
        }
    }
    for start in [0.34, 0.74] where s > start && s < start + 0.09 {
        let k = (s - start) / 0.09
        if k < 0.35 && start < 0.5 {
            for i in 0..<8 {
                let q = crawlReach((28, 31), Double(i) * 45, 3 + k * 10)
                c.px(Int(q.x.rounded()), Int(q.y.rounded()), gum)
            }
        }
        let a = 0.6 * sin(k * .pi)
        for i in 0..<7 {
            let q = crawlReach((28, 32), Double(i) * 51 + k * 40, 8 + k * 5)
            c.circle(Int(q.x.rounded()), Int(q.y.rounded()), 2 + Int(k * 2), C(0xF0EEF4, a))
        }
    }
}

/// Juice Box as the blonde, chewing.
private func drawJuiceBoxGirl(_ c: PixelCanvas, _ p: Pose, blowing: Bool) {
    let hair = C(0xF2DC84), hairD = C(0xC8AE52), hairL = C(0xFFF4C4)
    let denim = C(0x6A8EC4), denimD = C(0x4A6A9C), denimL = C(0x92B2DE)
    let top = C(0xF06AA8), topD = C(0xC84A86), legging = C(0x24222A), shoe = C(0xF4F4F4), sole = C(0xB8B8C0)
    let lip = C(0xC84A6A)

    // 1. Black leggings and white sneakers, a grey sole.
    drawLegs(c, Look(leg: legging), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, footRow(i, p.step), 2, 1, sole) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, the far arm in the denim sleeve.
    drawBody(c, Look(arm: denim, eye: nil))
    c.px(15, 33, denimL); c.rect(15, 35, 3, 1, denimD)

    // 4. The pink top, the leggings' waistband; the denim jacket hanging open either side, lit on the left, a collar,
    //    a pocket and a seam.
    c.rect(18, 33, 20, 3, top); c.rect(18, 35, 20, 1, topD)
    c.rect(18, 36, 20, 2, legging)
    c.pattern(18, 32, [
        "LLLLL..........LLLLL",
        "LDDDDD........DDDDDD",
        "LDDDDD........DDDDDd",
        "LDDDDD........DDDDDd",
        "LDDDDD........DDDDDd",
        "LDDDDD........DDDDDd",
    ], ["D": denim, "L": denimL, "d": denimD])
    c.rect(19, 34, 3, 1, denimD); c.rect(34, 34, 3, 1, denimD)

    // 5. The face: Clawd's eyes with a lash at each outer corner, and the jaw working on the gum (or pursed to blow).
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(21, 28, ink); c.px(34, 28, ink)
    if blowing {
        c.rect(27, 32, 2, 2, lip)
    } else if Int(p.lt * 3.4) % 2 == 0 {
        c.rect(27, 33, 3, 1, lip)
    } else {
        c.rect(27, 32, 3, 2, lip); c.px(28, 33, C(0xF890C8))
    }

    // 6. Long straight platinum hair: lit along the top, parted, a fringe swept aside, falling in strands down both
    //    sides of her face and past her shoulders at the back.
    c.pattern(16, 22, [
        ".....HHlHHHlHHlHHHH...",
        "...HHHHHHHHhHHHHHHHHH.",
        "..HHHHhHHHHhHHHHHhHHHH",
        "..HHHHHHHHHh.HHHHHHHHH",
        ".HHHHH.HHH.........HHH",
        ".HHhH...............HH",
        ".HhHH...............hH",
        ".HHhH...............HH",
        ".hHHH...............Hh",
        ".HHhH...............hH",
        ".HhH................H.",
        ".HHh..................",
        ".hH...................",
    ], ["H": hair, "h": hairD, "l": hairL])
}

/// Juice Box as the ratkin, in the purple jumpsuit.
private func drawJuiceBoxRat(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x8E847C), furD = C(0x6A625C), furL = C(0xB2A8A0)
    let pink = C(0xF0A0B4), pinkD = C(0xC87890)
    let suit = C(0x6E3AA8), suitD = C(0x4C2680), suitL = C(0x9262CE)

    // 1. The jumpsuit's legs, pink feet.
    drawLegs(c, Look(leg: suit), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx + 1, 36, 1, b - 37, suitD)
            c.rect(lx, b, 2, 1, pink); c.px(lx + 2, b, pinkD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The long pink tail, out behind and curling up at its tip.
    let flick = sin(p.lt * 2.2) > 0.4 ? -1 : 0
    c.pattern(5, 30 + flick, [
        "pp...........",
        "p............",
        "p............",
        "pp...........",
        ".pp........pp",
        "..pppp..pppp.",
        "....pppppp...",
    ], ["p": pink])

    // 4. The body in grey-brown fur, lit along the top, a few fur strokes; the far arm in the purple sleeve.
    drawBody(c, Look(body: fur, shade: furD, arm: suit, eye: nil))
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 6, furL)
    c.rect(20, 28, 2, 1, furD); c.rect(25, 27, 2, 1, furD)

    // 5. The big round ears on top, pink inside.
    for x in [17, 32] {
        c.pattern(x, 19, [
            ".FFFF.",
            "FFppFF",
            "FpppPF",
            "FpppPF",
            "FFppFF",
            ".FFFF.",
        ], ["F": fur, "p": pink, "P": pinkD])
    }

    // 6. The face: beady eyes with a glint, the pointed snout out in front with its pink nose, the whiskers.
    c.rect(22, 29, 2, 2, ink); c.px(22, 29, C(0xFFFFFF))
    c.rect(32, 29, 2, 2, ink); c.px(32, 29, C(0xFFFFFF))
    c.pattern(25, 30, [
        "FFFFFFFFFFFFFF.",
        "FFFFFFFFFFFFFFFp",
        ".FFFFFFFFFFFFdd.",
    ], ["F": furL, "d": furD, "p": pink])
    c.px(39, 30, furL); c.px(40, 31, pink); c.px(41, 31, pinkD)
    for y in [30, 32] { c.rect(42, y, 3, 1, C(0xF4F0E8)) }
    c.rect(36, 33, 2, 1, C(0xF4F0E8))

    // 7. The purple jumpsuit from the chest down: a collar, the zip up the front, lit on the left, a belt.
    c.rect(18, 34, 20, 4, suit)
    c.rect(18, 34, 20, 1, suitL); c.rect(18, 34, 1, 4, suitL); c.rect(37, 34, 1, 4, suitD)
    c.rect(27, 34, 1, 4, C(0xD8DCE4))
    c.rect(18, 36, 20, 1, suitD); c.px(27, 36, C(0xD8DCE4))

    // 8. The near paw.
    c.rect(38, 33, 3, 3, suit); c.px(38, 33, suitL); c.rect(40, 34, 2, 2, pink)
}

// MARK: - Gluteus Maxx

/// Gluteus Maxx: a short, hairy dancer, Clawd bare but for a shiny gold Speedo, dark hair in strokes on his chest, arms
/// and legs, and a red hockey helmet with black vents, ear guards and a chin strap. He fights with a butt crush: he
/// turns his back on whoever he's fighting and bumps them with it, hard. Signature: he flexes, both arms up in a
/// double biceps, a shine on each.
private func drawGluteusMaxx(_ c: PixelCanvas, _ p: Pose) {
    let hairC = C(0x5A3420)
    let helmet = C(0xC8302A), helmetD = C(0x8E1E1A), helmetL = C(0xEC6A5A), vent = C(0x1E1A1E)
    let gold = C(0xE8B830), goldD = C(0xB0841A), goldL = C(0xFFE684)
    let s = p.signature ?? -1
    let flexing = s > 0.08 && s < 0.92
    // The butt crush: his back turned while he fights up close, the hips shoving forward on each strike.
    let fighting = p.melee != nil && p.mode == .working && !p.walking && !p.cheering
    let strike = fighting && (p.melee ?? -90) > -50
    let shove = strike ? 2 : 0

    // 1. Bare hairy legs, a stroke of hair down each.
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx + 1, 38, 1, 2, hairC); c.px(lx, 40, hairC)
            c.px(lx + 1, footRow(i, p.step), clawdShade)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, the hips shoved forward on a strike; the arms up in the flex.
    c.ox += shove / 2
    if flexing && !fighting { torso(c, clawdOrange, clawdShade) } else { drawBody(c, Look(eye: nil)) }
    c.rect(18, 26, 20, 1, C(0xEE9474))
    if flexing && !fighting {
        let pump = Int(s * 10) % 2
        for (sx, fx, bx) in [(13, 12, 14), (38, 40, 39)] {
            c.rect(sx, 31, 5, 3, clawdOrange); c.rect(sx, 33, 5, 1, clawdShade)
            c.rect(fx, 25, 3, 7, clawdOrange)
            c.rect(fx - 1, 23, 5, 3, clawdOrange); c.rect(fx - 1, 23, 5, 1, C(0xEE9474))
            c.rect(bx, 29 - pump, 3, 2, clawdOrange); c.px(bx, 29 - pump, C(0xEE9474))
            c.rect(fx + 1, 27, 1, 2, hairC)
        }
        if Int(s * 12) % 3 == 0 {
            for (x, y) in [(10, 27), (45, 27)] {
                c.px(x, y, C(0xFFFFFF)); c.px(x - 1, y, C(0xFFF4C0, 0.7)); c.px(x + 1, y, C(0xFFF4C0, 0.7))
                c.px(x, y - 1, C(0xFFF4C0, 0.7)); c.px(x, y + 1, C(0xFFF4C0, 0.7))
            }
        }
    } else {
        c.rect(16, 33, 1, 2, hairC); c.rect(39, 33, 1, 2, hairC)
    }

    // 4. Chest hair in strokes down his sides (not on his back).
    if !fighting {
        c.pattern(19, 32, ["h..", ".h.", "h.h"], ["h": hairC])
        c.pattern(34, 32, ["..h", ".h.", "h.h"], ["h": hairC])
    }

    // 5. The gold Speedo: a lit band at the top, shining, cut in a V at the front; from behind, a plain band.
    if fighting {
        c.rect(18, 35, 20, 3, gold); c.rect(18, 35, 20, 1, goldL); c.rect(18, 37, 20, 1, goldD)
        c.rect(37, 35, 1, 3, goldD)
    } else {
        c.pattern(18, 35, [
            "LLLLLLLLLLLLLLLLLLLd",
            ".GGGGGGGGgGGGGGGGGd.",
            "....GGGGGGGGGGGd....",
        ], ["G": gold, "L": goldL, "g": goldD, "d": goldD])
        c.px(21, 36, C(0xFFFFFF))
    }

    // 6. The face: Clawd's eyes, a determined set of brows; turned away, nothing but the back of his helmet.
    if !fighting {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
        c.rect(21, 28, 3, 1, hairC); c.rect(32, 28, 3, 1, hairC)
    }

    // 7. The red hockey helmet: the shell lit along its top, black vent slots, ear guards down the sides, the chin
    //    strap under his jaw.
    c.pattern(17, 22, [
        "......HHHHHHHHHH......",
        "....HHLLLLLLLLHHHH....",
        "...HLLHHVHHHHVHHHHH...",
        "..HLHHHHVHHHHVHHHHHd..",
        ".HHHHHHHHHHHHHHHHHHHd.",
        ".HHHHHHHHHHHHHHHHHHHHd",
        ".ddddddddddddddddddddd",
        ".HHH..............HHHd",
        ".HHH..............HHd.",
        "..Hs..............sd..",
    ], ["H": helmet, "L": helmetL, "d": helmetD, "V": vent, "s": vent])
    if fighting {
        c.rect(19, 29, 18, 2, helmet); c.rect(19, 30, 18, 1, helmetD)   // the back of the shell
        c.rect(23, 29, 1, 1, vent); c.rect(32, 29, 1, 1, vent)
    } else {
        c.rect(20, 31, 1, 2, vent); c.rect(35, 31, 1, 2, vent)
    }
    c.ox -= shove / 2

    // 8. The bump: the hips punch forward a little further than the rest, a burst where they land, and speed lines
    //    behind.
    if strike {
        c.rect(36 + shove, 34, 2, 4, gold); c.rect(36 + shove, 35, 2, 1, goldL)
        for (x, y) in [(41, 33), (42, 36), (41, 39)] { c.rect(x + shove, y, 2, 1, C(0xFFF4C0)) }
        if !p.trail.isEmpty {
            for (x, y) in [(10, 30), (8, 33), (11, 36)] { c.rect(x, y, 4, 1, C(0xFFFFFF, 0.5)) }
        }
    }
}

// MARK: - Dong Quixote

/// Dong Quixote: an elderly dancer with the heart of a knight, Clawd under a brass barber's basin worn as a helmet
/// (its wide flat brim with the notch in front), wisps of grey hair under it, bushy grey brows, a long grey moustache
/// turned up at the ends and a pointed goatee. A black doublet with red slashed puff sleeves, a red sash across it,
/// black tights and black dancing shoes with silver buckles. He fights with a slim rapier, its brass cup guard
/// shining. Signature: a gallant bow, sweeping low from the hips, the rapier lowered before him, then up again.
private func drawDongQuixote(_ c: PixelCanvas, _ p: Pose) {
    let brass = C(0xD4A440), brassD = C(0x9A7424), brassL = C(0xF4D47A)
    let grey = C(0xF4F2EE), greyD = C(0xC4BEB4)
    let doublet = C(0x26242C), doubletD = C(0x16151A), doubletL = C(0x46444E), slash = C(0xC02C3E)
    let tights = C(0x2E2C34), shoe = C(0x141318), buckle = C(0xD8DCE4)
    let steel = C(0xE4E8EE), steelD = C(0x9AA0AC)
    let s = p.signature ?? -1
    var tilt = 0.0
    if s > 0.08 && s < 0.92 {
        let k = min(1, (s - 0.08) / 0.2, (0.92 - s) / 0.2)
        tilt = 28 * (0.5 - 0.5 * cos(k * .pi))
    }
    let bowing = tilt > 0.5

    // 1. Black tights, black dancing shoes with a silver buckle.
    drawLegs(c, Look(leg: tights), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.px(lx + 1, b, buckle); c.px(lx + 1, 37, doubletL)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Everything above the hips, bowing forward from them in the signature.
    turned(c, tilt, about: (28, 38)) { u in
        // The body, its far arm in a red-slashed black puff sleeve, swept out behind him in the bow.
        torso(u, clawdOrange, clawdShade)
        if bowing {
            u.rect(10, 30, 8, 3, doublet); u.rect(10, 30, 8, 1, doubletL); u.px(13, 31, slash)
            u.rect(8, 29, 3, 3, clawdOrange)
        } else {
            u.rect(15, 33, 3, 3, doublet); u.px(16, 34, slash); u.px(15, 33, doubletL)
        }

        // The black doublet from the chest down, lit on the left, silver buttons, the red sash across it.
        u.rect(18, 34, 20, 4, doublet)
        u.rect(18, 34, 1, 4, doubletL); u.rect(19, 34, 4, 1, doubletL); u.rect(37, 34, 1, 4, doubletD)
        for y in [35, 37] { u.px(31, y, buckle) }
        for x in 18...37 {
            let y = 37 - Int((Double(x - 18) / 19 * 3).rounded())
            u.px(x, y, slash); if y < 37 { u.px(x, y + 1, C(0x8E1E2C)) }
        }

        // The face: Clawd's eyes under bushy grey brows; the long moustache turned up at both ends, the pointed goatee
        // down over the doublet.
        u.rect(22, 29, 2, 3, ink); u.rect(32, 29, 2, 3, ink)
        u.rect(21, 28, 4, 1, grey); u.rect(31, 28, 4, 1, grey)
        u.pattern(21, 31, [
            "M............M",
            "MM..........MM",
            ".MMMMMmmMMMMM.",
            "......GG......",
            "......GG......",
            "......G.......",
        ], ["M": grey, "m": greyD, "G": grey])

        // Wisps of grey hair under the basin at the back.
        u.pattern(17, 27, ["gG", "g.", "G.", "g."], ["g": greyD, "G": grey])

        // The barber's basin: a shallow brass dome, lit on the left, and its wide flat brim, the notch cut in its
        // front edge.
        u.pattern(15, 21, [
            "........BBBBBBBBB.......",
            "......BBLLLLBBBBBBB.....",
            ".....BBLBBBBBBBBBBBd....",
            ".....BBBBBBBBBBBBBBd....",
            "LLLLLLLLLLLLLLLLLLLLL..L",
            "dDDDDDDDDDDDDDDDDDDDD..D",
        ], ["B": brass, "L": brassL, "d": brassD, "D": brassD])

        // The near hand and the rapier: a slim steel blade, the brass cup guard and its quillon; held up at rest,
        // swung, or lowered point-down before him in the bow.
        let ang = p.melee ?? (bowing ? -18 : -70)
        let hand = Sprite.hand
        for (i, t) in p.trail.enumerated() { crawlBar(u, hand, t, from: 3, to: 17, steel.alpha(0.3 / Double(i + 1)), r: 0.5) }
        crawlBar(u, hand, ang, from: -1.5, to: 1.5, doubletD, r: 0.6)
        crawlBar(u, hand, ang, from: 2, to: 17, steel, r: 0.5)
        crawlBar(u, hand, ang, from: 9, to: 16, steelD, r: 0.2)
        let gp = crawlReach(hand, ang, 1.8)
        crawlBar(u, gp, ang + 90, from: -2.6, to: 2.6, brassD, r: 0.6)
        let cup = crawlReach(hand, ang, 1.2)
        u.px(Int(cup.x.rounded()), Int(cup.y.rounded()) - 1, brassL)
        u.px(Int(cup.x.rounded()), Int(cup.y.rounded()), brass)
        u.rect(38, 33, 3, 3, doublet); u.px(38, 33, doubletL); u.px(39, 34, slash)
        u.rect(40, 34, 2, 2, clawdOrange)
    }
}

// MARK: - Damascus Steel

/// Damascus Steel: a smoky Ifrit with skin of metal, Clawd in dark blue-grey steel rippled with the lighter wavy bands
/// of Damascus steel, glowing white eyes, stubby ivory goat horns curving back off his head, and ember-orange tattoos
/// down his arms and across his chest. Deep purple harem trousers gathered at the ankle in gold, a gold sash, gold
/// armbands, bare steel feet. Smoke always wisps off him a little. He fights with his steel fists. Signature: smoke
/// curls up off him in thick grey curls, and his tattoos glow brighter.
private func drawDamascusSteel(_ c: PixelCanvas, _ p: Pose) {
    let steel = C(0x50545E), steelD = C(0x383A42), steelL = C(0x7C828E), wave = C(0x686E7A)
    let horn = C(0xDCCFAA), hornD = C(0xA8986E)
    let pants = C(0x5E2E80), pantsD = C(0x40205A), pantsL = C(0x8050A8), gold = C(0xE0B040), goldD = C(0xA8801E)
    let s = p.signature ?? -1
    let smoking = s > 0.04 && s < 0.96 ? sin((s - 0.04) / 0.92 * .pi) : 0
    let tattoo = lerp(C(0xE07A28), C(0xFFD27A), smoking)

    // 1. Baggy purple harem trousers, gathered at the ankle in a gold cuff, bare steel feet.
    drawLegs(c, Look(leg: pants), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx + 1, 36, 1, b - 38, pantsD)
            c.px(lx - 1, b - 3, pants); c.px(lx - 1, b - 4, pantsL)   // the billow
            c.rect(lx, b - 1, 2, 1, gold)
            c.rect(lx, b, 2, 1, steel); c.px(lx + 2, b, steelD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in steel, lit on top and the left; two wavy Damascus bands across it.
    drawBody(c, Look(body: steel, shade: steelD, arm: steel, eye: nil))
    c.rect(18, 26, 20, 1, steelL); c.rect(18, 26, 1, 8, steelL)
    for (base, from, to) in [(28, 19, 36), (33, 19, 36)] {
        for x in from...to {
            let y = base + Int((sin(Double(x) * 0.9) * 0.9).rounded())
            c.px(x, y, wave)
        }
    }

    // 4. The tattoos, ember-orange: a curl down each side of the chest and a band on the far arm.
    c.pattern(19, 33, ["t..", ".t.", ".t.", "t.."], ["t": tattoo])
    c.pattern(34, 33, ["..t", ".t.", ".t.", "..t"], ["t": tattoo])
    c.px(16, 34, tattoo); c.px(15, 33, gold); c.px(16, 33, gold)

    // 5. The purple trousers' waist and the gold sash, knotted at the side.
    c.rect(18, 36, 20, 2, pants); c.rect(18, 37, 20, 1, pantsD)
    c.rect(18, 36, 20, 1, gold); c.rect(33, 36, 2, 2, goldD)

    // 6. The glowing white eyes, a faint glow round them.
    for x in [22, 32] {
        c.rect(x - 1, 29, 4, 3, C(0xFFFFFF, 0.18))
        c.rect(x, 29, 2, 3, C(0xFFFFFF))
    }
    c.rect(21, 28, 3, 1, steelD); c.rect(32, 28, 3, 1, steelD)

    // 7. The stubby goat horns, curving back off the top of his head.
    for x in [19, 30] {
        c.pattern(x, 22, [
            "hh..",
            "hhh.",
            ".hHh",
            "..dh",
        ], ["h": horn, "H": horn, "d": hornD])
    }

    // 8. The near fist: steel, a gold armband, a tattoo stroke on the knuckles; punching, or at his side.
    func fist(_ x: Int, _ y: Int, _ al: Double) {
        c.rect(x - 1, y - 1, 3, 3, steel.alpha(al)); c.rect(x - 1, y - 1, 3, 1, steelL.alpha(al))
        c.rect(x - 1, y + 1, 3, 1, steelD.alpha(al)); c.px(x, y, tattoo.alpha(al))
    }
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: steel, fist: fist)
    } else {
        fist(39, 34, 1)
    }
    c.px(38, 33, gold); c.px(38, 34, gold)

    // 9. The smoke: a thin wisp off his head always, thick curls off his head and shoulders in the signature, rising
    //    and swaying, faint where it leaves him.
    let count = smoking > 0 ? 9 : 3
    for i in 0..<count {
        let rate = smoking > 0 ? 0.55 : 0.3
        let k = (p.lt * rate + Double(i) / Double(count)).truncatingRemainder(dividingBy: 1)
        let base = [27.0, 20, 35][i % 3]
        let x = base + sin(k * .pi * 2.4 + Double(i)) * (1 + k * 4)
        let y = 22 - k * 18
        let peak = smoking > 0 ? 0.6 * smoking + 0.2 : 0.3
        let a = peak * sin(k * .pi)
        let r = smoking > 0 ? 1 + Int(k * 3) : 1 + Int(k * 1.5)
        c.circle(Int(x.rounded()), Int(y.rounded()), r, C(0xECECF4, a))
    }
}

// MARK: - Anaconda

/// Anaconda: a snake-man, Clawd in purple scales with a viper's broad head, flaring out wide at the jaw, a paler
/// belly of scutes down his front, slit yellow eyes, a forked pink tongue that flicks out now and then, and a long
/// purple tail out behind him. Shirtless, in tight black dancer's trousers with a silver-studded belt. He fights with
/// his fists. Signature: a dancer's spin, turning on the spot twice, his arms out.
private func drawAnaconda(_ c: PixelCanvas, _ p: Pose) {
    let scale = C(0x7E3EA0), scaleD = C(0x5A2A76), scaleL = C(0xA466C4)
    let belly = C(0x9E64BC), bellyD = C(0x8A52A8)
    let eye = C(0xF2D23A), pants = C(0x1E1C22), pantsL = C(0x3A3842), stud = C(0xC8CCD4)
    let tongue = C(0xE8466A)
    let s = p.signature ?? -1
    var turn = -1.0
    if s > 0.12 && s < 0.88 {
        let k = (s - 0.12) / 0.76
        turn = (0.5 - 0.5 * cos(k * .pi)) * 4 * .pi
    }

    // 1. Black trousers, bare scaly feet.
    drawLegs(c, Look(leg: pants), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.px(lx, 37, pantsL)
            c.rect(lx, b, 2, 1, scaleD); c.px(lx + 2, b, scale)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // Everything above the legs: facing front, or seen from behind as he spins (no face, the tail on the other side).
    func upper(_ u: PixelCanvas, back: Bool, armsOut: Bool) {
        // The tail: thick at the body, tapering out behind, its tip curling up; lit along the top, a darker scale
        // every few pixels.
        let sway = sin(p.lt * 1.4)
        for x in 5...17 {
            let f = Double(17 - x) / 12
            let top = 33 + Int((f * 2 + sway * f * 0.8).rounded())
            let bottom = 37 - Int((f * 1.6).rounded())
            u.rect(x, top, 1, max(1, bottom - top + 1), scale)
            u.px(x, top, scaleL)
            if x % 3 == 0 { u.px(x, bottom, scaleD) }
        }
        u.pattern(3, 29 + Int((sway * 0.8).rounded()), [".l", "ss", "s.", "ss", ".s"], ["s": scale, "l": scaleL])

        // The body in purple scales, lit along the top and the left, chevrons of darker scale down the sides.
        torso(u, scale, scaleD)
        if !armsOut {
            u.rect(15, 33, 3, 3, scale); u.rect(38, 33, 3, 3, scale)
        } else {
            u.rect(11, 31, 7, 2, scale); u.rect(11, 31, 7, 1, scaleL)
            u.rect(38, 31, 7, 2, scale); u.rect(38, 31, 7, 1, scaleL)
        }
        u.rect(18, 31, 20, 1, scaleL); u.rect(18, 31, 1, 5, scaleL)
        for (x, y) in [(19, 33), (34, 33)] { u.pattern(x, y, ["d.d", ".d."], ["d": scaleD]) }

        // The viper's head: flaring out wide at the jaw on both sides, lit along its top.
        u.pattern(15, 25, [
            "....LLLLLLLLLLLLLLLL....",
            ".LLSSSSSSSSSSSSSSSSSSSL.",
            "LSSSSSSSSSSSSSSSSSSSSSSd",
            "SSSSSSSSSSSSSSSSSSSSSSSd",
            ".SSSSSSSSSSSSSSSSSSSSSd.",
            "..SSSSSSSSSSSSSSSSSSSd..",
            "...dddddddddddddddddd...",
        ], ["S": scale, "L": scaleL, "d": scaleD])

        if !back {
            // The paler belly, its scutes, low on his front.
            u.rect(25, 33, 6, 3, belly)
            u.rect(25, 35, 6, 1, bellyD)
            // Slit yellow eyes under a heavy brow, and now and then the forked tongue.
            u.rect(21, 28, 4, 1, scaleD); u.rect(31, 28, 4, 1, scaleD)
            u.rect(21, 29, 3, 3, eye); u.rect(22, 29, 1, 3, ink)
            u.rect(32, 29, 3, 3, eye); u.rect(33, 29, 1, 3, ink)
            if (p.lt * 0.9).truncatingRemainder(dividingBy: 3) < 0.35 && turn < 0 {
                u.pattern(27, 31, [".tt.", ".tt.", "t..t"], ["t": tongue])
            }
        }

        // The tight black trousers' waist and the silver-studded belt.
        u.rect(18, 36, 20, 2, pants); u.rect(18, 36, 20, 1, pantsL)
        for x in stride(from: 19, through: 37, by: 3) { u.px(x, 36, stud) }
    }

    // 3. The fists: punching, at his sides, or out in the spin.
    func fist(_ x: Int, _ y: Int, _ al: Double) {
        c.rect(x - 1, y - 1, 3, 3, scale.alpha(al)); c.rect(x - 1, y - 1, 3, 1, scaleL.alpha(al))
        c.rect(x - 1, y + 1, 3, 1, scaleD.alpha(al))
    }
    if turn >= 0 {
        let k = cos(turn)
        spun(c, scale: abs(k), back: k < 0) { u in upper(u, back: k < 0, armsOut: true) }
        // A swirl of motion round his middle.
        for i in 0..<5 {
            let a = turn * 57.3 + Double(i) * 72
            let x = 28 + cos(a * .pi / 180) * 14, y = 40 + sin(a * .pi / 180) * 2
            c.px(Int(x.rounded()), Int(y.rounded()), C(0xC8A0E8, 0.55))
        }
    } else {
        upper(c, back: false, armsOut: false)
        if let a = p.melee {
            crawlPunch(c, angle: a, trail: p.trail, arm: scale, fist: fist)
        }
    }
}

// MARK: - Rosemarie

/// Rosemarie: an elderly dwarf, short and stout, Clawd wider and lower in a burgundy cardigan buttoned in gold, a
/// white blouse collar peeping out, a long grey skirt and sturdy brown boots; her white hair swept back and in two
/// thick braids down her front, rosy cheeks, and a green card-dealer's eyeshade over her eyes. Bernie the mole rides
/// on her near shoulder: dark velvet fur, big pink digging paws and his pink star of a nose. She throws gold coins.
/// Signature: she flicks a coin off her thumb at someone's eye, spinning away off to the right, and Bernie's nose
/// twitches.
private func drawRosemarie(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xEEEAE4), hairD = C(0xBEB8AE), hairL = C(0xFFFFFF)
    let visor = C(0x3AA060), visorD = C(0x26743E), visorL = C(0x7AD496)
    let wool = C(0x8A2A3E), woolD = C(0x64192A), woolL = C(0xB04A5C), button = C(0xE8C040), blouse = C(0xF2EEE6)
    let skirt = C(0x4E4A56), skirtD = C(0x36333E), skirtL = C(0x68646E), boot = C(0x5A3A22), bootD = C(0x3E2614)
    let mole = C(0x4A3C38), moleD = C(0x30262A), moleL = C(0x6E5C56), molePink = C(0xF29AB0)
    let coin = C(0xF2C232), coinD = C(0xB8881A), coinL = C(0xFFF0A0)
    let s = p.signature ?? -1
    let poised = s > 0.08 && s < 0.36
    let flight = s >= 0.36 && s < 0.62 ? (s - 0.36) / 0.26 : -1.0
    let twitch = s > 0.5 && s < 0.9 && Int(p.lt * 10) % 2 == 0 ? 1 : 0
    let throwing = p.fire != nil && p.recoil > 0

    // 1. Stubby legs in sturdy brown boots, laced.
    drawLegs(c, Look(leg: skirtD), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.rect(lx, b, 2, 1, bootD); c.px(lx + 1, b - 1, C(0x8A6A48))
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, stout: Clawd a pixel wider each side and two rows lower, the far arm in the cardigan's sleeve.
    c.rect(17, 28, 22, 10, clawdOrange)
    c.rect(17, 37, 22, 1, clawdShade); c.rect(38, 28, 1, 10, clawdShade)
    c.rect(14, 33, 3, 3, wool); c.px(14, 33, woolL); c.rect(14, 35, 3, 1, woolD)

    // 4. The long grey skirt to her boot tops.
    robe(c, skirt, skirtD, skirtL, from: 36, hem: seatedPose ? 39 : 41)

    // 5. The cardigan, burgundy, buttoned up the front in gold, lit on the left, the blouse's collar points at the top.
    c.rect(17, 32, 22, 5, wool)
    c.rect(17, 32, 1, 5, woolL); c.rect(18, 32, 4, 1, woolL); c.rect(38, 32, 1, 5, woolD)
    c.rect(27, 33, 1, 3, woolD)
    for y in [33, 35] { c.px(26, y, button) }
    c.px(18, 32, blouse); c.px(37, 32, blouse)
    c.rect(17, 36, 22, 1, woolD)

    // 6. The face: small eyes in the eyeshade's green shadow, white brows, rosy cheeks, a sly little smile.
    c.rect(22, 30, 2, 2, ink); c.rect(32, 30, 2, 2, ink)
    c.rect(21, 29, 3, 1, hairD); c.rect(32, 29, 3, 1, hairD)
    c.rect(20, 31, 2, 1, C(0xE88A80)); c.rect(34, 31, 2, 1, C(0xE88A80))
    c.rect(26, 31, 3, 1, clawdShade); c.px(29, 30, clawdShade)

    // 7. Her white hair: pulled back over the top of her head, lit along the crown, and two thick braids, plaited,
    //    hanging down her front over the cardigan.
    c.pattern(17, 23, [
        "....llllllHHHHHHH.....",
        "..HHHHHHHHHhhhhHHHH...",
        ".hhhhHHHHHHHHHHHhhhhH.",
        ".HHHHH...........HHHH.",
    ], ["H": hair, "h": hairD, "l": hairL])
    for x in [17, 36] {
        c.pattern(x, 27, [
            "HH.",
            "Hh.",
            "hH.",
            "Hh.",
            "hH.",
            "Hh.",
            "hH.",
            "Hh.",
            ".v.",
            "HH.",
        ], ["H": hair, "h": hairD, "v": visorD])
    }

    // 8. The green card-dealer's eyeshade: a band round her head and the stiff see-through-looking brim jutting out
    //    over her eyes, lit along its front.
    c.pattern(16, 26, [
        "..vvvvvvvvvvvvvvvvvv...",
        "LLLLLLLLLLLLLLLLLLLLLLL",
        ".VVVVVVVVVVVVVVVVVVVVV.",
    ], ["v": visorD, "V": visor, "L": visorL])

    // 9. Bernie the mole on her near shoulder: a dark velvet lump, lit along his back, big pink paws gripping her,
    //    the pink star of his nose out in front, twitching.
    c.pattern(32, 20, [
        "...mmmm...",
        "..mLLLmm..",
        ".mLmmmmmm.",
        "mmmmmmmmmd",
        "mmmmmmmmd.",
        ".pp.dd.pp.",
    ], ["m": mole, "L": moleL, "d": moleD, "p": molePink])
    c.pattern(41 + twitch, 21, [".P.", "PPP", ".P."], ["P": molePink])
    c.px(39, 22, ink)

    // 10. The near hand: the next coin ready in it, or on her thumb, poised to flick; then the coin spinning off to
    //     the right at someone's eye.
    if poised {
        c.rect(39, 30, 3, 3, wool); c.px(39, 30, woolL)
        c.rect(41, 29, 2, 2, clawdOrange)
        let wob = Int(s * 30) % 2
        c.rect(42, 27 - wob, 2, 1, coin); c.px(42, 27 - wob, coinL)
    } else {
        c.rect(39, 33, 3, 3, wool); c.px(39, 33, woolL); c.rect(39, 35, 3, 1, woolD)
        c.rect(41, 34, 2, 2, clawdOrange)
        if !throwing && flight < 0 {
            c.rect(42, 33, 2, 2, coin); c.px(42, 33, coinL); c.px(43, 34, coinD)
        }
    }
    if flight >= 0 {
        let x = 43 + flight * 34, y = 26 - sin(flight * .pi) * 5
        let ix = Int(x.rounded()), iy = Int(y.rounded())
        switch Int(flight * 14) % 3 {
        case 0: c.rect(ix, iy, 3, 3, coin); c.px(ix, iy, coinL); c.px(ix + 2, iy + 2, coinD)
        case 1: c.rect(ix + 1, iy, 1, 3, coin)
        default: c.rect(ix, iy + 1, 3, 1, coinL)
        }
        if flight < 0.15 {
            c.px(43, 25, C(0xFFF4C0, 0.8)); c.px(45, 24, C(0xFFF4C0, 0.6))
        }
    }
}
