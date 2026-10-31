import Foundation

// Heroes, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The rest of the crawlers: Tran, Li Jun, Li Na, Zhang, Sister Ines, Tserendolgor, Langley, Gwendolyn Duet,
// Jurgen, Osvaldo.

let crawlHeroes4: [CrawlHero: Persona] = [
    .tran: Persona(name: "Tran", weapon: .saber, headTop: 22, signature: 3.2, callout: "Do you own a red shirt?",
                   draw: drawTran),
    .liJun: Persona(name: "Li Jun", weapon: .saber, headTop: 23, signature: 2.6, draw: drawLiJun),
    .liNa: Persona(name: "Li Na", weapon: .saber, headTop: 17, signature: 3.0, draw: drawLiNa),
    .zhang: Persona(name: "Zhang", weapon: .blaster, shot: .thrown(C(0x8A6238)), muzzle: (42, 33), handGun: false,
                    headTop: 20, signature: 3.0, draw: drawZhang),
    .sisterInes: Persona(name: "Sister Ines", weapon: .blaster, shot: .energy(core: C(0xFFFFFF), glow: C(0xD4DCF4)),
                         muzzle: (45, 30), handGun: false, headTop: 19, signature: 3.4, draw: drawSisterInes),
    .tserendolgor: Persona(name: "Tserendolgor", weapon: .blaster, shot: .fire, muzzle: (44, 32), handGun: false,
                           headTop: 14, signature: 3.8, draw: drawTserendolgor),
    .langley: Persona(name: "Langley", weapon: .blaster, shot: .arrow, muzzle: (51, 34), handGun: false, headTop: 22,
                      signature: 3.2, draw: drawLangley),
    .gwendolyn: Persona(name: "Gwendolyn Duet", weapon: .saber, headTop: 21, signature: 2.8, draw: drawGwendolyn),
    .jurgen: Persona(name: "Jurgen", weapon: .saber, bulk: 2, headTop: 17, signature: 3.4, draw: drawJurgen),
    .osvaldo: Persona(name: "Osvaldo", weapon: .blaster, shot: .arrow, muzzle: (49, 35), handGun: false, headTop: 22,
                      signature: 3.6, draw: drawOsvaldo),
]

// MARK: - Shared bits

/// The bottom row of leg `i` this frame: a row higher while it's lifted in the walk.
private func footRow(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

/// A fist, 3×3, centred on (`x`, `y`), lit on the top left and shaded underneath: wraps, gloves, bare knuckles.
private func crawlH4Fist(_ c: PixelCanvas, _ x: Int, _ y: Int, _ a: Double, _ col: Px, _ dark: Px, _ light: Px) {
    c.rect(x - 1, y - 1, 3, 3, col.alpha(a))
    c.rect(x - 1, y - 1, 3, 1, light.alpha(a))
    c.rect(x - 1, y + 1, 3, 1, dark.alpha(a))
}

/// A recurve or long bow held out at arm's length, its grip at (`x`, 34) plus `lift`: limbs bowing back towards the
/// tips over `half` pixels each way, the string drawn back `pull` pixels, and, `nocked`, an arrow on the string, its
/// point at `tip`. The near hand on the grip.
private func crawlH4Bow(_ c: PixelCanvas, x: Int, half: Int, pull: Int, nocked: Bool, tip: Int,
                        limb: Px, limbD: Px, grip: Px, hand: Px) {
    let string = C(0xF0F0F4)
    for y in (34 - half)...(34 + half) where y + c.oy <= 43 {
        let d = abs(y - 34)
        let off = d <= 2 ? 0 : d <= half / 2 ? -1 : d <= half - 2 ? -2 : -3
        c.px(x + off, y, d <= 1 ? grip : d % 3 == 0 ? limbD : limb)
    }
    for y in (35 - half)...(33 + half) where y + c.oy <= 43 {
        let d = Double(abs(y - 34)) / Double(half - 1)
        let bend = Double(pull) * (1 - d)
        c.px(x - 5 - Int(bend.rounded()), y, string)
    }
    if nocked {
        let tail = x - 5 - pull
        c.rect(tail, 34, tip - tail, 1, C(0x6A4A2A))
        c.px(tip - 1, 34, C(0xC8CCD4)); c.px(tip, 34, C(0xE8ECF4))
        c.px(tail, 33, C(0xF0ECE0)); c.px(tail, 35, C(0xF0ECE0))
        c.rect(tail - 1, 34, 2, 2, hand)
    }
    c.rect(x, 33, 2, 3, hand)
}

/// A cape hanging down his back from the shoulders, swaying a little, its hem at `hem`.
private func crawlH4BackCape(_ c: PixelCanvas, t: Double, speed: Double, _ col: Px, _ edge: Px, _ fold: Px, hem: Int) {
    let last = min(hem, 43 - c.oy)
    guard last >= 26 else { return }
    for y in 26...last {
        let k = Double(y - 26) / Double(max(1, hem - 26))
        let sway = sin(t * speed + k * 2.2) * k * 1.6
        let l = Int((16.5 - k * 6 + sway).rounded())
        c.rect(l, y, 22 - l, 1, col)
        c.px(l, y, edge)
        if y > 29 { c.px(l + 3, y, fold) }
    }
}

/// A little flame, its foot at (`x`, `y`), flickering on the clock `t`, `h` pixels tall: a red rim, an orange body and
/// a yellow heart, all solid, so it keeps its outline.
private func crawlH4Flame(_ c: PixelCanvas, _ x: Int, _ y: Int, h: Int, t: Double) {
    let f = Int(t * 10)
    let lick = noise(f) > 0.5 ? 1 : 0
    let red = C(0xE8401E), orange = C(0xFF8A1E), yellow = C(0xFFE45A), core = C(0xFFF8D0)
    for r in 0..<h {
        let k = Double(r) / Double(h)
        let w = max(1, Int((Double(h) * 0.55 * (1 - k * k)).rounded()))
        let sway = r > h / 2 ? (lick == 0 ? 0 : 1) : 0
        let yy = y - r
        c.rect(x - w / 2 + sway, yy, w, 1, r == h - 1 ? red : orange)
        if w > 2 { c.px(x - w / 2 + sway, yy, red); c.px(x - w / 2 + sway + w - 1, yy, red) }
        if w >= 3 && r < h - 2 { c.rect(x - w / 2 + sway + 1, yy, w - 2, 1, yellow) }
        if w >= 4 && r < h / 2 { c.rect(x - w / 2 + sway + 1 + (w - 2) / 2 - 1, yy, 1, 1, core) }
    }
}

/// Garret, Tserendolgor's Tummy Acher, drawn small at her feet: a meatball 8 pixels round, browned on top, the
/// mince picked out in short darker strokes, two beady eyes and his one big tooth. `face` 0 shows his face, 1 has it
/// turned up over the top (rolling), 2 round the back. `squash` flattens him a pixel as he giggles. His bottom row is
/// `y`.
private func crawlH4Garret(_ c: PixelCanvas, _ x: Int, _ y: Int, face: Int, squash: Bool) {
    let meat = C(0x9A5430), meatD = C(0x6A3418), meatL = C(0xC07A48), tooth = C(0xFFFCF0)
    let rows = squash ? [
        "..LLLL..",
        ".LMMMLMM",
        "MMMdMMMM",
        "MdMMMMdM",
        "MMMMdMMD",
        ".DDDDDD.",
    ] : [
        "..LLLL..",
        ".LMMLMM.",
        "LMMdMMMM",
        "MMMMMdMM",
        "MdMMMMMD",
        "MMMMdMDD",
        ".DDDDDD.",
    ]
    let top = y - rows.count + 1
    c.pattern(x, top, rows, ["M": meat, "D": meatD, "L": meatL, "d": meatD])
    switch face {
    case 0:
        c.px(x + 4, top + 2, ink); c.px(x + 6, top + 2, ink)
        c.rect(x + 4, top + 4, 3, 1, C(0x3A160A))
        c.rect(x + 5, top + 4, 1, 2, tooth)
    case 1:
        c.px(x + 3, top, ink); c.px(x + 5, top, ink)
        c.px(x + 6, top + 1, tooth)
    default:
        break
    }
}

// MARK: - Tran

/// Tran: a tired-looking Clawd, his messy black hair sticking up in tufts, heavy lids half over his eyes and the bags
/// under them. A faded grey-blue T-shirt (not red), its hem untucked, dark jeans and scuffed brown shoes. He fights
/// with a curved steel sabre, a brass knuckle-bow round its grip; at rest its tip droops to the ground. Signature: he
/// tugs his shirt out at the hem and peers down at it, as if checking whether it's red, and a question mark pops up.
private func drawTran(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0x6A7C90), shirtD = C(0x4E5C6E), shirtL = C(0x8A9CB0)
    let jeans = C(0x343E54), jeansD = C(0x262E40), shoe = C(0x6A4428)
    let hair = C(0x1E1A1C), hairL = C(0x3E3638), bags = C(0xA85A44)
    let steel = C(0xD0D6E0), steelD = C(0x8A929E), brass = C(0xC89A3A), gripC = C(0x2A1E16)
    let s = p.signature ?? -1
    let tug = s > 0.12 && s < 0.86
    let pull = tug ? min(1, (s - 0.12) / 0.12, (0.86 - s) / 0.12) : 0
    let flap = Int((pull * 2).rounded())

    // 1. Dark jeans, a lit crease down each leg, scuffed brown shoes.
    drawLegs(c, Look(leg: jeans), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx + 1, 38, 1, footRow(i, p.step) - 38, jeansD) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, his far arm in the shirt's sleeve; the T-shirt from the shoulders down, a round neck, the far side
    //    in shade, a fold or two, the hem hanging loose over his jeans (pulled out in the signature).
    drawBody(c, Look(arm: shirt, eye: nil))
    c.rect(18, 33, 20, 5, shirt)
    c.rect(18, 33, 20, 1, shirtL); c.rect(37, 33, 1, 5, shirtD)
    c.rect(25, 33, 6, 1, clawdOrange); c.rect(26, 34, 4, 1, clawdOrange); c.rect(25, 34, 1, 1, shirtD); c.rect(30, 34, 1, 1, shirtD)
    c.rect(21, 35, 1, 2, shirtD); c.rect(33, 35, 1, 2, shirtD)
    c.rect(18, 37, 20, 1, shirtD)
    c.rect(15, 33, 3, 1, shirtL)
    if flap > 0 {
        c.rect(33, 36, 5 + flap, 2 + flap / 2, shirtL); c.rect(33, 37 + flap / 2, 5 + flap, 1, shirtD)
        c.rect(33, 36, 1, 2, shirtD)
    }

    // 4. The face: heavy lids over the top of his eyes, the bags under them; looking down at the shirt in the
    //    signature.
    let down = pull > 0.5 ? 1 : 0
    for x in [22, 32] {
        c.rect(x, 29, 2, 1, clawdShade)
        c.rect(x, 30 + down, 2, 2 - down, ink)
        c.rect(x, 32, 2, 1, bags)
    }
    c.rect(21, 28, 4, 1, hair); c.rect(31, 28, 4, 1, hair)

    // 5. His hair: black, a mess of tufts sticking up every way, lit in a stroke or two.
    c.pattern(17, 21, [
        "...h...h....h..h....",
        "..hh.hhh..hhh.hh.h..",
        ".hhhhhhLhhhhhLhhhhh.",
        "hhhLLhhhhhhhhhhhhhhh",
        "hhhhhhhhhhLhhhhhhhhh",
        ".h..................h",
    ], ["h": hair, "L": hairL])
    c.rect(18, 25, 20, 1, hair)

    // 6. The sabre: a curved steel blade, a brass knuckle-bow round the dark grip; drooping to the ground at rest,
    //    or swung. In the signature the same hand is down at his hem, the sabre hanging from it.
    let hand = (x: Sprite.hand.x, y: Sprite.hand.y + (flap > 0 ? 2 : 0))
    let ang = p.melee ?? 55
    func blade(_ a: Double, _ col: Px, _ r: Double) {
        var prev = crawlReach(hand, a, 2.5)
        for i in 1...5 {
            let l = 2.5 + Double(i) * 1.9
            let q = crawlReach(hand, a - 14 * pow(Double(i) / 5, 2), l)
            c.glowLine(prev.x, prev.y, q.x, q.y, core: col, glow: C(0, 0), coreR: r, glowR: r + 0.1)
            prev = q
        }
    }
    for (i, t) in p.trail.enumerated() { blade(t, steel.alpha(0.3 / Double(i + 1)), 0.7) }
    blade(ang, steelD, 0.8)
    blade(ang, steel, 0.4)
    crawlBar(c, hand, ang, from: -1.5, to: 2, gripC, r: 0.6)
    let gp = crawlReach(hand, ang, 2.4)
    crawlBar(c, gp, ang + 90, from: -1.5, to: 1.5, brass, r: 0.5)
    let kb = crawlReach(hand, ang + 70, 2)
    c.px(Int(kb.x.rounded()), Int(kb.y.rounded()), brass)
    let hx = Int(hand.x.rounded()) - 3, hy = Int(hand.y.rounded()) - 1
    c.rect(hx, hy, 3, 3, clawdOrange); c.px(hx, hy, C(0xEE9474))

    // 7. The question mark, popping up over his head while he checks.
    if s > 0.4 && s < 0.84 {
        let bob = Int(((s - 0.4) * 10).rounded()) % 2
        c.pattern(39, 12 - bob, [".WWW.", "WW.WW", "...WW", "..WW.", "..W..", ".....", "..W.."], ["W": C(0xFFF6D8)])
    }
}

// MARK: - Li Jun

/// Li Jun: a street monk, Clawd with his head shaved, a shine on top, a calm brow. A maroon robe over his far
/// shoulder with a saffron sash at the waist, loose maroon trousers and black cloth shoes, his hands bound in white
/// wraps. He fights with his fists. Signature: a flying spin
/// kick, leaping up, his front legs snapping out together in a kick as a white swoosh whips round him.
private func drawLiJun(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x8C2A30), robeD = C(0x641C22), robeL = C(0xB04450)
    let sash = C(0xF0A830), sashD = C(0xC07E1E)
    let wrap = C(0xF0ECE2), wrapD = C(0xC4C0B4), wrapL = C(0xFFFFFF)
    let shoe = C(0x1E1C20), shine = C(0xF0A486)
    let s = p.signature ?? -1
    let leap = s > 0.12 && s < 0.82
    let k = leap ? (s - 0.12) / 0.7 : 0
    let lift = leap ? Int((sin(k * .pi) * 7).rounded()) : 0
    let kicking = leap && k > 0.3 && k < 0.72

    c.oy -= lift

    // 1. Loose maroon trousers, black shoes. In the kick the front pair snap out forward together, the back pair
    //    tuck up under him.
    if kicking {
        for (i, lx) in [19, 23].enumerated() {
            c.rect(lx, 36, 2, 5, robe); c.rect(lx, 40, 2, 1, shoe)
            if i == 0 { c.rect(lx + 1, 36, 1, 4, robeD) }
        }
        for (i, y) in [36, 38].enumerated() {
            c.rect(36, y, 8 - i, 2, robe); c.rect(36, y + 1, 8 - i, 1, robeD)
            c.rect(44 - i, y, 2, 2, shoe)
        }
    } else {
        drawLegs(c, Look(leg: robe), step: p.step)
        drawBoots(c, shoe, step: p.step, rows: 1)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx + 1, 36, 1, footRow(i, p.step) - 37, robeD) }
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The swoosh, a white arc whipping round him behind the body as he spins.
    if leap && k > 0.18 && k < 0.84 {
        let a0 = (k - 0.18) / 0.66 * 360 - 200
        for j in 0..<14 {
            let a = (a0 - Double(j) * 9) * .pi / 180
            let x = 28 + cos(a) * 17, y = 31 + sin(a) * 11
            c.px(Int(x.rounded()), Int(y.rounded()), C(0xFFFFFF, 0.85 * (1 - Double(j) / 14)))
        }
    }

    // 4. The body, his round shaved head with a shine on it, a calm brow, a small smile; the far arm wrapped.
    drawBody(c, Look(arm: wrap))
    c.rect(20, 25, 16, 1, clawdOrange); c.rect(23, 24, 10, 1, clawdOrange)
    c.rect(24, 24, 3, 1, shine); c.rect(21, 25, 3, 1, shine); c.px(20, 26, shine)
    c.rect(21, 27, 3, 1, clawdShade); c.rect(32, 27, 3, 1, clawdShade)
    c.rect(15, 35, 3, 1, wrapD)

    // 5. The robe: up over his far shoulder and wrapped round him from the chest down, lit along its edges; the
    //    saffron sash at the waist with its knot.
    c.pattern(18, 26, [
        "RL..................",
        "RL..................",
        "RRL.................",
        "RRL.................",
        "RdL.................",
        "RRL.................",
        "RRRRRRRRRRRRRRRRRRRR",
        "RRdRRRRRRRRRRRRRRRRR",
        "RRRRRRdRRRRRRRRdRRRR",
        "RRRRRRRRRRRRRRRRRRRR",
        "SSSSSSSSSSSSSSSSSSSS",
        "RRRRRRRRRRRRRRRRRRRR",
    ], ["R": robe, "L": robeL, "d": robeD, "S": sash])
    c.rect(21, 32, 17, 1, robeL)
    c.rect(37, 36, 1, 2, robeD); c.rect(18, 37, 20, 1, robeD)
    c.rect(33, 36, 2, 2, sashD); c.px(34, 38, sash)


    // 7. The near fist, wrapped, up in his guard; punching.
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: clawdOrange, reach: 6) { x, y, al in
            crawlH4Fist(c, x, y, al, wrap, wrapD, wrapL)
        }
    } else if kicking {
        crawlH4Fist(c, 40, 29, 1, wrap, wrapD, wrapL)
    } else {
        c.rect(38, 32, 3, 3, clawdOrange)
        crawlH4Fist(c, 41, 31, 1, wrap, wrapD, wrapL)
    }
}

// MARK: - Li Na

/// Li Na: a Changbi demon, Clawd tall and pale, her head a few pixels higher than his, two small black horns, long
/// black hair falling straight down her back in strands, dark eyes with a red glint and a wide mouth full of little
/// fangs. A jade-green dress with a gold-trimmed collar, dark green trousers. She fights with a heavy iron chain, a hook
/// on its end; at rest it hangs from her hand in a coil. Signature: she raises her arm and whirls the chain overhead.
private func drawLiNa(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xE4E0EA), skinD = C(0xB4AEC2), skinL = C(0xF8F6FC)
    let hair = C(0x16141C), hairL = C(0x3A3644), horn = C(0x1E1A22), hornL = C(0x4A4452)
    let dress = C(0x2E8A6A), dressD = C(0x1E604A), dressL = C(0x4CAA88), gold = C(0xE0B848)
    let trousers = C(0x1E4A3A), shoe = C(0x16141A)
    let iron = C(0x9A9CA8), ironD = C(0x5A5C68), ironL = C(0xD0D2DC)
    let s = p.signature ?? -1
    let whirl = s > 0.1 && s < 0.9

    // 1. Dark green trousers, black shoes.
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. Her hair down her back, long black strands to her waist.
    c.pattern(13, 22, [
        "...hhhh",
        "..hhhhh",
        ".hhLhhh",
        ".hhhhLh",
        "hhLhhhh",
        "hhhhLh.",
        "hLhhhh.",
        "hhhLhh.",
        "h.hhLh.",
        "h.hhh..",
        "..h.h..",
        "..h....",
    ], ["h": hair, "L": hairL])

    // 4. The tall pale body, her head four rows above Clawd's, lit on top and the left, the far side in shade.
    c.rect(18, 22, 20, 16, skin)
    c.rect(18, 22, 20, 1, skinL); c.rect(18, 22, 1, 12, skinL); c.rect(37, 22, 1, 16, skinD)
    c.rect(15, 33, 3, 3, dress); c.px(15, 33, dressL)

    // 5. The horns, small and black, curving up and out; her fringe, straight across.
    c.pattern(21, 18, ["h..", "hH.", ".hh"], ["h": horn, "H": hornL])
    c.pattern(32, 18, ["..h", ".Hh", "hh."], ["h": horn, "H": hornL])
    c.rect(18, 21, 20, 2, hair); c.rect(18, 23, 3, 1, hair); c.rect(35, 23, 3, 1, hair)
    c.rect(22, 21, 4, 1, hairL); c.rect(30, 21, 3, 1, hairL)

    // 6. The face: dark eyes with a red glint, a thin brow, and the wide mouth stretched nearly ear to ear, a row of
    //    little white fangs in it.
    for x in [22, 32] {
        c.rect(x, 25, 2, 3, ink); c.px(x + 1, 25, C(0xE83A3A))
        c.rect(x - 1, 24, 3, 1, skinD)
    }
    c.pattern(21, 29, [
        "k............k",
        "kkkkkkkkkkkkkk",
        ".kFkFkFkFkFkk.",
        "..kkkkkkkkkk..",
    ], ["k": C(0x2A0E14), "F": C(0xFFFFFF)])
    c.rect(23, 31, 10, 1, C(0x8A1E2A))

    // 7. The jade dress from her chest down: a gold-trimmed mandarin collar, lit on the left, the far side in shade,
    //    a gold frog-button on the front, a fold.
    c.rect(18, 33, 20, 5, dress)
    c.rect(18, 33, 20, 1, gold); c.rect(18, 34, 1, 4, dressL); c.rect(37, 34, 1, 4, dressD)
    c.rect(27, 33, 2, 1, dress)
    c.rect(28, 35, 3, 1, gold); c.px(29, 36, gold)
    c.rect(22, 35, 1, 2, dressD)
    c.rect(18, 37, 20, 1, dressD)

    // 8. The chain: iron links, light and dark by turns, a hook on the end. At rest it hangs in a coil from her
    //    hand; swung straight out; whirled overhead in the signature, her arm raised.
    func link(_ x: Double, _ y: Double, _ i: Int) {
        c.px(Int(x.rounded()), Int(y.rounded()), i % 2 == 0 ? iron : ironD)
    }
    func hook(_ x: Int, _ y: Int, _ al: Double = 1) {
        c.pattern(x - 1, y - 1, ["LL.", "I.I", "..I", "I.I", ".I."], ["L": ironL.alpha(al), "I": iron.alpha(al)])
    }
    if whirl {
        c.rect(38, 24, 3, 9, skin); c.rect(38, 24, 1, 9, skinL)
        c.rect(38, 22, 3, 3, skin)
        let spin = (s - 0.1) / 0.8 * 4 * 2 * .pi
        // a faint ring where it's been
        for j in 0..<24 {
            let a = Double(j) / 24 * 2 * .pi
            c.px(Int((40 + cos(a) * 11).rounded()), Int((14 + sin(a) * 3).rounded()), C(0xD0D2DC, 0.2))
        }
        let hx = 40 + cos(spin) * 11, hy = 14 + sin(spin) * 3
        for i in 0...10 {
            let f = Double(i) / 10
            link(39.5 + (hx - 39.5) * f, 21 + (hy - 21) * f, i)
        }
        hook(Int(hx.rounded()), Int(hy.rounded()))
    } else if let a = p.melee {
        for (i, t) in p.trail.enumerated() {
            let e = crawlReach(Sprite.hand, t, 15)
            crawlBar(c, Sprite.hand, t, from: 2, to: 14, iron.alpha(0.25 / Double(i + 1)), r: 0.5)
            hook(Int(e.x.rounded()), Int(e.y.rounded()), 0.3 / Double(i + 1))
        }
        for i in 1...14 {
            let q = crawlReach(Sprite.hand, a, Double(i))
            link(q.x, q.y, i)
        }
        let e = crawlReach(Sprite.hand, a, 15)
        hook(Int(e.x.rounded()), Int(e.y.rounded()))
        c.rect(39, 33, 3, 3, skin); c.px(39, 33, skinL)
    } else {
        let sway = sin(p.lt * 1.3) * 0.8
        for i in 0..<9 {
            let f = Double(i) / 8
            link(42 + f * 2 + sway * f, 35 + f * 7, i)
        }
        c.pattern(43, 39, ["I.I.", ".I.I"], ["I": ironD])
        hook(45 + Int(sway.rounded()), 42)
        c.rect(39, 33, 3, 3, skin); c.px(39, 33, skinL)
    }
}

// MARK: - Zhang

/// Zhang: a warehouse worker, Clawd in a scuffed white hard hat, a lime hi-vis vest with silver reflective stripes
/// over a grey T-shirt, work trousers and steel-toed boots, and on his back the Cape of Odds, deep purple trimmed in
/// gold, a white die on it. He throws Earth Mover rocks, a brown one in his hand. Signature: he lifts a foot and stamps,
/// and the ground in front of him heaves up in a wave of rock and dust.
private func drawZhang(_ c: PixelCanvas, _ p: Pose) {
    let vest = C(0xC8E030), vestD = C(0x98AE20), stripe = C(0xD8DCE4)
    let tee = C(0x9A9EA8), teeD = C(0x74787F)
    let hat = C(0xF0EEE6), hatD = C(0xBEBCB2), hatL = C(0xFFFFFF)
    let cape = C(0x5A2E8C), capeD = C(0x3E1E66), gold = C(0xE0B040)
    let trousers = C(0x4A4A40), trousersD = C(0x36362E), boot = C(0x5A3A20)
    let rock = C(0x8A6238), rockD = C(0x5E4024), rockL = C(0xB08A5A)
    let s = p.signature ?? -1
    let raise = s > 0.1 && s < 0.32
    let slam = s >= 0.32 && s < 0.4
    let heave = s >= 0.32 && s < 0.92

    // 1. The cape behind him, deep purple with a gold edge and a white die on it.
    crawlH4BackCape(c, t: p.t, speed: p.capeSpeed, cape, gold, capeD, hem: 41)
    c.pattern(11, 31, ["WWWWW", "Wk.kW", "W.k.W", "Wk.kW", "WWWWW"], ["W": C(0xF4F2EC), "k": ink, ".": C(0xF4F2EC)])

    // 2. Work trousers, boots with a lit steel toe. Raising a front foot for the stamp, then bringing it down.
    if raise && !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = i % 2 == 1 ? 40 : 43
            c.rect(lx, 36, 2, b - 35, trousers); c.rect(lx + 1, 36, 1, b - 37, trousersD)
            c.rect(lx, b - 1, 2, 2, boot); c.px(lx + 1, b, C(0x9A9CA4))
        }
    } else {
        drawLegs(c, Look(leg: trousers), step: p.step)
        drawBoots(c, boot, step: p.step, rows: 2)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let b = footRow(i, p.step)
                c.rect(lx + 1, 36, 1, b - 38, trousersD)
                c.px(lx + 1, b, C(0x9A9CA4))
            }
        }
    }

    // 3. The breath; a jolt down as the foot lands.
    c.oy += p.breathe + (slam ? 1 : 0)

    // 4. The body, his far arm in the grey sleeve; the grey T-shirt; over it the hi-vis vest, open down the
    //    front, two silver stripes round it.
    drawBody(c, Look(arm: tee))
    c.rect(18, 32, 20, 6, tee); c.rect(26, 32, 4, 1, teeD)
    c.rect(18, 32, 8, 6, vest); c.rect(30, 32, 8, 6, vest)
    c.rect(18, 32, 8, 1, C(0xE4F660)); c.rect(30, 32, 8, 1, C(0xE4F660)); c.rect(37, 33, 1, 5, vestD)
    c.rect(18, 34, 8, 1, stripe); c.rect(30, 34, 8, 1, stripe)
    c.rect(18, 36, 8, 1, stripe); c.rect(30, 36, 8, 1, stripe)
    c.rect(18, 37, 20, 1, vestD)
    c.rect(15, 35, 3, 1, teeD)

    // 5. The hard hat: a white dome with a ridge down the middle and a brim all round, a scuff on its side.
    c.pattern(16, 20, [
        "......HHHHHHHH......",
        "....HHlHHHHHHHHH....",
        "...HlHHHHrHHHHHHd...",
        "...HlHHHHrHHHHHHd...",
        "..HHHHHHHrHHHsHHHd..",
        "dddddddddddddddddddd",
    ], ["H": hat, "l": hatL, "d": hatD, "r": hatD, "s": C(0xA8A69C)])
    c.rect(18, 26, 20, 1, clawdShade)

    // 6. The near hand and a rock in it (gone a moment as he throws it); the arm drawn back with it in the stamp.
    if p.recoil == 0 && !heave {
        c.rect(38, 32, 3, 3, clawdOrange)
        c.pattern(40, 29, [".RRl", "RRRR", "RdRR", ".dd."], ["R": rock, "d": rockD, "l": rockL])
    }

    // 7. The heave: a wave of rock slabs bursting up out of the ground in front of him, one after another, then
    //    sinking back, a puff of dust off each.
    if heave {
        let k = (s - 0.32) / 0.6
        for i in 0..<6 {
            let start = Double(i) * 0.1
            let u = (k - start) / 0.45
            guard u > 0 && u < 1 else { continue }
            let h = Int((sin(u * .pi) * Double(5 - i / 2)).rounded())
            guard h > 0 else { continue }
            let x = 43 + i * 4
            c.rect(x, 44 - h, 3, h, rock)
            c.rect(x, 44 - h, 3, 1, rockL); c.px(x + 2, 44 - h + 1, rockD)
            c.px(x - 1, 43, rockD); c.px(x + 3, 43, rockD)
            if u < 0.5 {
                let a = 0.7 * (1 - u * 2)
                c.px(x - 1, 42 - h, C(0xE0D0B0, a)); c.px(x + 3, 41 - h, C(0xE0D0B0, a)); c.px(x + 1, 40 - h, C(0xE0D0B0, a))
            }
        }
    }
}

// MARK: - Sister Ines

/// Sister Ines: a Havana Brown cat-girl nun, Clawd in dark chocolate fur with bright green eyes, a pink nose and pale
/// whiskers, her pointed ears poking up through a black veil with a white band; a white bib with a little gold cross,
/// a deep blue cloak over a black habit, silver bracers. In her far hand, planted upright behind her, a trident whose
/// prongs glow. She throws white bolts like a baseball, winding up over her shoulder. Signature: she recites a poem,
/// and sparkles curl up out of the words.
private func drawSisterInes(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x5E3A28), furD = C(0x42281A), furL = C(0x7E543C)
    let veil = C(0x18181E), veilL = C(0x34343E), band = C(0xF2F0EA), bandD = C(0xC8C6BE)
    let cloak = C(0x2A3E78), cloakD = C(0x1C2A54), cloakL = C(0x42589A)
    let habit = C(0x1E1E26), silver = C(0xC8CED8), silverL = C(0xF0F4F8)
    let eye = C(0x7ADC5A), pink = C(0xE89AA8), gold = C(0xE8C050)
    let shaft = C(0x8A8E9A), prong = C(0xC8F4FF), prongGlow = C(0x7ADCFF)
    let s = p.signature ?? -1
    let reciting = s > 0.08 && s < 0.92
    var phase = -1.0
    if let f = p.fire { phase = frac(f.t / p.firePeriod) }
    let windUp = phase > 0.7
    let release = phase >= 0 && phase < 0.15

    // 1. The trident, planted upright behind her far side: a grey shaft, three prongs glowing pale blue at the top,
    //    a faint glow round them.
    c.rect(13, 18, 1, 26 - max(0, c.oy), shaft); c.rect(10, 17, 7, 1, shaft); c.rect(10, 16, 1, 1, shaft); c.rect(16, 16, 1, 1, shaft)
    for x in [10, 16] { c.rect(x, 12, 1, 4, prong); c.px(x, 11, prongGlow) }
    c.rect(13, 11, 1, 6, prong); c.px(13, 10, prongGlow)
    let pulse = 0.12 + 0.06 * sin(p.lt * 3)
    for (x, y) in [(9, 12), (11, 13), (12, 12), (14, 12), (15, 13), (17, 12), (13, 9)] { c.px(x, y, prongGlow.alpha(pulse)) }

    // 2. Black habit to the ground over her legs, her paws peeping under.
    drawLegs(c, Look(leg: habit), step: p.step)
    drawBoots(c, furD, step: p.step, rows: 1)

    // 3. The breath.
    c.oy += p.breathe

    // 4. The veil hanging down her back.
    c.pattern(14, 25, [
        "..VVVV",
        ".VVVVV",
        "VVlVVV",
        "VVVVlV",
        "VlVVVV",
        "VVVVV.",
        "VVlVV.",
        ".VVV..",
    ], ["V": veil, "l": veilL])

    // 5. The body in chocolate fur, lit along the top; the far paw in a silver bracer on the trident.
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil))
    c.rect(18, 26, 1, 6, furL)
    c.rect(13, 30, 3, 3, fur); c.rect(13, 32, 3, 1, silver); c.px(13, 32, silverL)

    // 6. The ears through the veil, pink inside; the veil over the top of her head, the white band across her brow.
    c.pattern(19, 19, ["F...", "FF..", "FpF.", "FFFF"], ["F": fur, "p": pink])
    c.pattern(33, 19, ["...F", "..FF", ".FpF", "FFFF"], ["F": fur, "p": pink])
    c.pattern(17, 23, [
        ".VVVVVVVVVVVVVVVVVV.",
        "VVlllVVVVVVVVVVVVVVV",
        "BBBBBBBBBBBBBBBBBBBB",
        "V..................V",
    ], ["V": veil, "l": veilL, "B": band])
    c.rect(17, 25, 20, 1, bandD); c.rect(17, 25, 20, 1, band); c.rect(17, 26, 1, 4, veil); c.rect(38, 26, 1, 4, veil)
    c.rect(19, 23, 1, 1, fur); c.rect(35, 23, 1, 1, fur)

    // 7. The face: green eyes with a slit, a pink nose, pale whiskers; her mouth opening on the words in the
    //    signature.
    for x in [22, 32] {
        c.rect(x, 28, 2, 3, eye); c.rect(x + 1, 28, 1, 3, ink)
    }
    c.rect(27, 30, 2, 1, pink)
    let talking = reciting && Int(p.lt * 7) % 2 == 0
    c.rect(27, 31, 2, 1, talking ? C(0x2A1018) : furD)
    for (x, y) in [(19, 30), (20, 31), (35, 30), (34, 31)] { c.px(x, y, C(0xD8C8B8)) }

    // 8. The white bib with its gold cross, the deep blue cloak over her shoulders, open over the black habit.
    c.rect(18, 33, 20, 5, habit)
    c.rect(23, 32, 10, 2, band); c.rect(24, 34, 8, 1, band); c.rect(23, 33, 1, 1, bandD)
    c.rect(27, 35, 1, 3, gold); c.rect(26, 36, 3, 1, gold)
    c.rect(18, 32, 5, 6, cloak); c.rect(33, 32, 5, 6, cloak)
    c.rect(18, 32, 5, 1, cloakL); c.rect(33, 32, 5, 1, cloakL); c.rect(37, 33, 1, 5, cloakD)
    c.rect(20, 34, 1, 3, cloakD); c.rect(18, 37, 20, 1, cloakD)

    // 9. The near arm in its bracer, and the white bolt glowing in her paw: wound back over her shoulder before a
    //    throw, flung forward as it goes, held down by her side the rest of the time.
    if windUp || release {
        let hx = windUp ? 36 : 44, hy = windUp ? 24 : 31
        crawlBar(c, (38, 32), windUp ? -100 : -20, from: 0, to: windUp ? 7 : 5, cloak, r: 1.2)
        c.rect(hx - 1, hy, 3, 3, fur); c.rect(hx - 1, hy + 2, 3, 1, silver)
        if windUp { c.glowLine(Double(hx) + 0.5, Double(hy) - 0.5, Double(hx) + 0.5, Double(hy) - 0.5,
                               core: C(0xFFFFFF), glow: C(0xD4DCF4), coreR: 1.1, glowR: 2.6) }
    } else {
        c.rect(38, 33, 3, 3, fur); c.rect(38, 35, 3, 1, silver); c.px(38, 35, silverL)
        if p.ready || p.fire != nil {
            c.glowLine(42.5, 35.5, 42.5, 35.5, core: C(0xFFFFFF), glow: C(0xD4DCF4), coreR: 0.9, glowR: 2.2)
        }
    }

    // 10. The poem: sparkles curling up out of her mouth in a spiral, white and gold, fading as they rise.
    if reciting {
        for i in 0..<6 {
            let f = frac((s - 0.08) * 2.4 + Double(i) / 6)
            guard f < 0.9 else { continue }
            let a = f * 3 * .pi
            let x = 39 + f * 14 + cos(a) * 3 * f, y = 31 - f * 18 + sin(a) * 3 * f
            let col = (i % 2 == 0 ? C(0xFFFFFF) : C(0xFFE07A)).alpha(1 - f * 0.7)
            let xi = Int(x.rounded()), yi = Int(y.rounded())
            c.px(xi, yi, col)
            if f < 0.6 { c.px(xi - 1, yi, col.alpha(0.6)); c.px(xi + 1, yi, col.alpha(0.6)); c.px(xi, yi - 1, col.alpha(0.6)); c.px(xi, yi + 1, col.alpha(0.6)) }
        }
    }
}

// MARK: - Tserendolgor

/// Tserendolgor: a German Shepherd soldier, Clawd in tan fur with a black saddle over her back and a black mask round
/// her muzzle, which pushes out in front with its black nose. An olive Vietnam-era helmet, her tall ears up through two
/// holes cut in it, a band round it; olive fatigues with breast pockets, and over them, on a chain, the gold locket
/// with a paw print. A Crisper's fire flickers in her near paw, ready to throw. Signature: Garret, her meatball Tummy
/// Acher, rolls up to her giggling, and she bends to pat him.
private func drawTserendolgor(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xC89A5A), furD = C(0x9A7240), furL = C(0xE4BC7C), black = C(0x221E1C), blackL = C(0x3E3832)
    let helmet = C(0x52643A), helmetD = C(0x3A4828), helmetL = C(0x728A50), bandC = C(0x2A2A22)
    let olive = C(0x6A6A44), oliveD = C(0x4E4E30), oliveL = C(0x86865A)
    let boot = C(0x1E1C1A), gold = C(0xE8C050), goldD = C(0xA8842A)
    let s = p.signature ?? -1
    let garret = s > 0.04 && s < 0.96
    // Garret rolls in from the right by 0.3, is patted until 0.72, and rolls off again by 0.96.
    var gx = 0.0
    if garret {
        if s < 0.3 { gx = 60 - (s - 0.04) / 0.26 * 15 }
        else if s < 0.72 { gx = 45 }
        else { gx = 45 + (s - 0.72) / 0.24 * 16 }
    }
    let patting = s > 0.32 && s < 0.7
    let pat = patting && Int((s - 0.32) * 24) % 2 == 0 ? 1 : 0

    // 1. Tan legs, black combat boots.
    drawLegs(c, Look(leg: olive), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx + 1, 36, 1, footRow(i, p.step) - 38, oliveD) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Her tail, bushy, hanging low behind her, black along the top.
    c.pattern(10, 31, [
        ".....BBBB",
        "...BBFFFF",
        "..BFFFFF.",
        ".BFFFF...",
        "BFFF.....",
        "FF.......",
    ], ["B": black, "F": fur])

    // 4. The body in tan fur, the black saddle over the top of her back; the far arm in its olive sleeve.
    drawBody(c, Look(body: fur, shade: furD, arm: olive, eye: nil))
    c.rect(18, 26, 2, 7, black); c.rect(18, 26, 1, 7, blackL)

    // 5. The ears, tall and pointed, black at the tips, up through the holes in the helmet.
    c.pattern(20, 14, ["..k", ".kF", ".FF", "FFF", "FpF", "FpF"], ["k": black, "F": fur, "p": C(0xD88A8A)])
    c.pattern(31, 14, ["k..", "Fk.", "FF.", "FFF", "FpF", "FpF"], ["k": black, "F": fur, "p": C(0xD88A8A)])

    // 6. The helmet: an olive dome lit on the left, the ears through it, a dark band round it, the rim low over her
    //    brow.
    c.pattern(16, 19, [
        "....HHHH...HHHHH....",
        "..HHlHH.....HHHHH...",
        ".HlHHH.......HHHHd..",
        ".HlHHHHHHHHHHHHHHd..",
        "bbbbbbbbbbbbbbbbbbb.",
        "HHHHHHHHHHHHHHHHHHHd",
        "dddddddddddddddddddd",
    ], ["H": helmet, "l": helmetL, "d": helmetD, "b": bandC])
    c.rect(20, 20, 3, 2, fur); c.rect(31, 20, 3, 2, fur); c.rect(23, 20, 8, 1, helmet); c.rect(22, 21, 9, 1, helmet)
    c.rect(19, 23, 2, 1, C(0xE8E4D8))   // a card tucked in the band

    // 7. The face: dark eyes under the rim, the black mask round her muzzle, which pushes out in front, the black
    //    nose on its end, her mouth a dark line.
    c.rect(22, 28, 2, 2, ink); c.px(22, 28, C(0xC8962A)); c.rect(31, 28, 2, 2, ink); c.px(31, 28, C(0xC8962A))
    c.pattern(34, 28, [
        ".KKK...",
        "FFFFFKN",
        "FFFFFFN",
        "Fddddd.",
        "FFFF...",
    ], ["K": blackL, "F": furL, "N": C(0x0E0C0C), "d": furD])

    // 8. The fatigues from her chest down: two breast pockets with flaps, lit along the top, the far side in shade;
    //    the locket's chain in a V and the gold locket, a paw print on it.
    c.rect(18, 33, 20, 5, olive)
    c.rect(18, 33, 20, 1, oliveL); c.rect(37, 34, 1, 4, oliveD); c.rect(18, 37, 20, 1, oliveD)
    c.rect(19, 34, 5, 1, oliveD); c.rect(32, 34, 5, 1, oliveD); c.rect(19, 35, 5, 2, olive); c.px(21, 35, gold)
    c.px(34, 35, gold)
    c.px(25, 33, goldD); c.px(26, 34, goldD); c.px(31, 33, goldD); c.px(30, 34, goldD)
    c.pattern(26, 34, [".GGG.", "GgGgG", "GGgGG", ".GGG."], ["G": gold, "g": C(0x7A5A1A)])

    // 9. The near paw: a flame flickering in it, ready (gone a moment as she throws it); bent down patting Garret in
    //    the signature.
    if patting {
        crawlBar(c, (39, 33), 45, from: 0, to: 4, olive, r: 1.2)
        c.rect(42, 35 + pat, 3, 2, fur); c.rect(42, 35 + pat, 3, 1, furL)
    } else {
        c.rect(38, 33, 3, 3, olive); c.px(38, 33, oliveL)
        c.rect(41, 33, 4, 2, fur); c.rect(41, 33, 4, 1, furL)
        if p.recoil == 0 && !garret { crawlH4Flame(c, 43, 32, h: 6, t: p.lt) }
    }

    // 10. Garret: rolling in, his face tumbling over; sat still and squashing as he giggles under her paw, little
    //     giggles popping off him; rolling away.
    if garret {
        c.oy -= p.breathe
        let x = Int(gx.rounded())
        let rolling = !(s > 0.3 && s < 0.72)
        let face = rolling ? [0, 1, 2, 1][Int(gx) % 4] : 0
        crawlH4Garret(c, x, 43, face: face, squash: patting && pat == 1)
        if s > 0.06 && s < 0.9 {
            for i in 0..<2 {
                let f = frac(s * 5 + Double(i) / 2)
                let col = C(0xFFF0F4, 1 - f * 0.8)
                let gy = 35 - Int(f * 6), gxp = x + 7 + i * 2 + Int(f * 2)
                c.pattern(gxp, gy, [".h.", "hhh", ".h."], ["h": col])
            }
        }
        c.oy += p.breathe
    }
}

// MARK: - Langley

/// Langley: a stocky hunter, Clawd a pixel broader each side, short greying blond hair in a flat crew cut and a heavy
/// greying brow over ice-blue eyes. A tan canvas hunting jacket with a dark corduroy collar, flapped pockets and a
/// brown quiver strap across it, the quiver's fletchings over his shoulder; dark trousers, brown boots. His bow is a
/// tall dark-wood longbow. Signature: he nocks an arrow, raises the bow to his eye and sights along it, one eye shut, a
/// glint on the arrowhead, then lets it down.
private func drawLangley(_ c: PixelCanvas, _ p: Pose) {
    let coat = C(0xA88454), coatD = C(0x7C6038), coatL = C(0xC8A472), collar = C(0x4A3420)
    let hair = C(0xD2C490), hairG = C(0xA8A8A0), hairD = C(0x8C8460)
    let ice = C(0x9AE4FF), strap = C(0x5A3A20), fletch = C(0xE8E4D8)
    let trousers = C(0x3E3A32), boot = C(0x6A4428)
    let limb = C(0x5A3A1E), limbD = C(0x3A2412), grip = C(0x2A1E14)
    let s = p.signature ?? -1
    let sighting = s > 0.1 && s < 0.9
    let up = sighting ? min(1, (s - 0.1) / 0.15, (0.9 - s) / 0.12) : 0

    // 1. The quiver on his back, the fletchings over his shoulder.
    c.pattern(12, 20, [
        "W.W.W..",
        ".WWW...",
        "..QQ...",
        "..QqQ..",
        "...QQq.",
        "...QqQ.",
        "....QQq",
        "....QqQ",
    ], ["W": fletch, "Q": strap, "q": collar])

    // 2. Dark trousers, brown boots.
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)

    // 3. The breath.
    c.oy += p.breathe

    // 4. The stocky body, broader a pixel each side, the far arm in the jacket.
    drawBody(c, Look(arm: coat, eye: nil))
    c.rect(17, 27, 1, 11, clawdOrange); c.rect(38, 27, 1, 11, clawdShade)
    c.rect(14, 33, 3, 3, coat); c.px(14, 33, coatL)

    // 5. The jacket from his chest down: the dark collar, lit along the top, the far side in shade, two flapped
    //    pockets, the quiver strap running across, a button or two.
    c.rect(17, 32, 22, 6, coat)
    c.rect(17, 32, 22, 1, collar); c.rect(23, 33, 2, 1, collar); c.rect(31, 33, 2, 1, collar)
    c.rect(17, 33, 1, 5, coatL); c.rect(38, 33, 1, 5, coatD); c.rect(17, 37, 22, 1, coatD)
    c.rect(19, 35, 4, 1, coatD); c.rect(33, 35, 4, 1, coatD)
    c.rect(28, 33, 1, 5, coatD)
    for i in 0..<6 { c.px(18 + i * 2, 32 + i, strap); c.px(19 + i * 2, 32 + i, strap) }

    // 6. The face: the heavy greying brow, ice-blue eyes with a dark pupil; one shut as he sights.
    c.rect(21, 28, 4, 1, hairD); c.rect(31, 28, 4, 1, hairD)
    let shut = up > 0.8
    c.rect(22, 29, 2, 3, ice); c.rect(23, 30, 1, 2, ink)
    if shut { c.rect(32, 29, 2, 3, clawdOrange); c.rect(32, 30, 2, 1, clawdShade) }
    else { c.rect(32, 29, 2, 3, ice); c.rect(33, 30, 1, 2, ink) }

    // 7. The crew cut: short and flat across the top, blond going grey, grey at the temples.
    c.pattern(17, 23, [
        ".hhhhhhhhhhhhhhhhhh.",
        "hhhllllhhhhhllllhhhh",
        "GGGhhhhhhhhhhhhhhGGG",
        "GG................GG",
    ], ["h": hair, "G": hairG, "l": C(0xE8DCB0)])

    // 8. The longbow, held out at arm's length; raised to his eye in the signature, an arrow drawn and sighted,
    //    a glint on its point.
    var pull = 0, nocked = p.ready && !sighting
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        nocked = ph >= 0.45
        if ph > 0.6 { pull = Int(((ph - 0.6) / 0.4 * 3).rounded()) }
    }
    if sighting {
        nocked = up > 0.3
        pull = up > 0.6 ? 3 : 0
    }
    let lift = -Int((up * 4).rounded()) + (seatedPose ? -3 : 0)
    c.oy += p.gunY + lift
    c.rect(38, 33, 6, 2, coat); c.px(38, 33, coatL)
    crawlH4Bow(c, x: 46, half: 10, pull: pull, nocked: nocked, tip: 51, limb: limb, limbD: limbD, grip: grip,
               hand: clawdOrange)
    if sighting && up > 0.9 && s > 0.45 && s < 0.75 {
        let tw = Int(s * 20) % 2
        c.px(52, 34, C(0xFFFFFF)); c.px(52, 33 - tw, C(0xFFFFFF, 0.7)); c.px(52, 35 + tw, C(0xFFFFFF, 0.7))
        c.px(53 + tw, 34, C(0xFFFFFF, 0.7))
    }
}

// MARK: - Gwendolyn Duet

/// Gwendolyn Duet: Clawd in a chainmail hauberk, steel rings picked out row by row, a mail coif over her head round
/// her face, a blond braid falling out of it down her back; a royal-blue tabard belted in brown leather over the mail,
/// dark trousers and steel-capped boots. She fights with a long ash spear, a steel leaf-shaped head; at rest she holds it
/// upright, its butt on the ground. Signature: she lifts the spear and plants it hard, dust jumping off the ground.
private func drawGwendolyn(_ c: PixelCanvas, _ p: Pose) {
    let mail = C(0x9AA2AE), mailD = C(0x6A727E), mailL = C(0xC8CED8)
    let tabard = C(0x2A4AA8), tabardD = C(0x1C3478), tabardL = C(0x4A6AC8)
    let braid = C(0xE8C860), braidD = C(0xB89A38)
    let belt = C(0x6A4428), buckle = C(0xD8B040)
    let wood = C(0xA8844E), woodD = C(0x7A5E34), steel = C(0xD8DEE8), steelD = C(0x8A929E)
    let trousers = C(0x3A3A44), boot = C(0x4A4E58)
    let s = p.signature ?? -1
    let planting = s > 0.1 && s < 0.9
    var rise = 0
    if planting {
        if s < 0.34 { rise = Int(((s - 0.1) / 0.24 * 5).rounded()) }
        else if s < 0.4 { rise = 5 - Int(((s - 0.34) / 0.06 * 5).rounded()) }
    }
    let thud = s >= 0.4 && s < 0.62

    // 1. Her braid down her back.
    c.pattern(14, 27, [
        "..BB",
        ".BbB",
        ".bBB",
        "BBb.",
        "BbB.",
        "bBB.",
        "BB..",
        "Bd..",
        "d...",
    ], ["B": braid, "b": braidD, "d": C(0x6A4428)])

    // 2. Dark trousers, steel-capped boots.
    drawLegs(c, Look(leg: trousers), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, footRow(i, p.step) - 1, C(0x9AA0AC)) }
    }

    // 3. The breath.
    c.oy += p.breathe + (thud && s < 0.46 ? 1 : 0)

    // 4. The body in mail, the far arm in a mail sleeve; the rings picked out in alternate rows of light and dark.
    drawBody(c, Look(body: mail, shade: mailD, arm: mail, eye: nil))
    for y in stride(from: 26, through: 36, by: 2) {
        for x in stride(from: 18 + (y / 2) % 2, through: 36, by: 2) { c.px(x, y, mailD) }
    }
    c.rect(18, 26, 20, 1, mailL)

    // 5. The coif round her face: the mail hood over the top of her head and down her cheeks, the face showing
    //    through its oval opening, Clawd-orange, her eyes.
    c.pattern(17, 21, [
        "....MMMMMMMMMMMM....",
        "..MMLMLMLMMMMMMMMM..",
        ".MLMMMMMMMMMMMMMMMd.",
        "MMMMdMMMMdMMMMdMMMMd",
        "MMdMMMMMMMMMMMMMMdMd",
    ], ["M": mail, "L": mailL, "d": mailD])
    c.rect(20, 27, 16, 6, clawdOrange); c.rect(19, 28, 1, 4, clawdOrange); c.rect(36, 28, 1, 4, clawdShade)
    c.rect(20, 26, 16, 1, mailD)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(21, 28, 3, 1, braidD); c.rect(32, 28, 3, 1, braidD)
    c.rect(20, 32, 16, 1, mailD)

    // 6. The tabard over the mail: royal blue, lit on the left, a fold either side; the brown belt
    //    with its buckle.
    c.rect(20, 33, 16, 5, tabard)
    c.rect(20, 33, 16, 1, tabardL); c.rect(35, 34, 1, 4, tabardD)
    c.rect(24, 34, 1, 2, tabardD); c.rect(31, 34, 1, 2, tabardD)
    c.rect(18, 36, 20, 1, belt); c.rect(27, 36, 2, 1, buckle)
    c.rect(20, 37, 16, 1, tabardD)

    // 7. The spear: an ash shaft, a steel leaf head. Upright at rest, its butt on the ground; lifted and planted in
    //    the signature; levelled and thrust in a fight.
    if let a = p.melee {
        let hand = Sprite.hand
        for (i, t) in p.trail.enumerated() where cos(t * .pi / 180) > 0 {
            crawlBar(c, hand, t, from: 12, to: 19, steel.alpha(0.3 / Double(i + 1)), r: 0.8)
        }
        crawlBar(c, hand, a, from: -7, to: 14, wood, r: 0.6)
        crawlBar(c, hand, a, from: 14, to: 18, steel, r: 1.1)
        crawlBar(c, hand, a, from: 18, to: 19.5, steel, r: 0.5)
        crawlBar(c, hand, a, from: 14, to: 18.5, steelD, r: 0.3)
        c.rect(39, 33, 3, 3, mail); c.px(39, 33, mailL)
    } else {
        let y0 = 11 - rise, bottom = 43 - rise
        c.rect(43, y0 + 5, 1, bottom - y0 - 5 + 1 - max(0, c.oy + y0 + 5 > 43 ? 0 : 0), wood)
        c.rect(44, y0 + 5, 1, bottom - y0 - 5 + 1, woodD)
        c.pattern(42, y0, ["..S.", ".SSs", ".SSs", ".SSs", "..s."], ["S": steel, "s": steelD])
        c.pattern(42, y0 + 5, ["bbbb"], ["b": steelD])
        c.rect(38, 32 - rise / 2, 3, 3, mail)
        c.rect(41, 32 - rise / 2, 4, 3, mail); c.rect(41, 32 - rise / 2, 4, 1, mailL)
        if thud {
            let k = (s - 0.4) / 0.22
            let a = 0.8 * (1 - k)
            for (dx, dy) in [(-3, 0), (4, 0), (-2, -2), (3, -2), (-5, -1), (6, -1)] {
                c.px(43 + dx + (dx < 0 ? -Int(k * 2) : Int(k * 2)), 43 + dy - Int(k * 2), C(0xE8DCC0, a))
            }
            c.px(41, 43, C(0x5A4A3A)); c.px(46, 43, C(0x5A4A3A))
        }
    }
}

// MARK: - Jurgen

/// Jurgen: a huge blond barbarian, Clawd grown taller and broader, his head four rows higher, long golden hair down
/// his back and a great blond beard, braided to a point, on a bare chest. A shaggy brown fur pelt over each shoulder,
/// a leather belt with a brass buckle, a fur kilt and fur boots, his fists bound in leather. He fights with his fists.
/// Signature: he looks up and talks to his absent wife, his beard moving, and a little pink heart floats up.
private func drawJurgen(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xF0D060), hairD = C(0xC8A838), hairL = C(0xFFF0A8)
    let beard = C(0xD8A030), beardD = C(0xA87420), beardL = C(0xF0C858)
    let furC = C(0x7A5634), furD = C(0x5A3E24), furL = C(0x9A7448)
    let strap = C(0x4A2E18), buckle = C(0xC8A040), wrap = C(0x8A5E36), wrapD = C(0x5E3E22), wrapL = C(0xAA7C4E)
    let heart = C(0xFF6A9A), heartL = C(0xFFB8CE)
    let s = p.signature ?? -1
    let talking = s > 0.08 && s < 0.92
    let look = talking ? 1 : 0

    // 1. Fur boots over his legs, the fur in short strokes.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, furC, step: p.step, rows: 4)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = footRow(i, p.step)
            c.px(lx, b - 3, furL); c.px(lx + 1, b - 1, furD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. His long hair down his back, golden strands.
    c.pattern(11, 22, [
        "....hhh",
        "...hhLh",
        "..hhhhh",
        "..hLhdh",
        ".hhhhhh",
        ".hdhLh.",
        "hhhhhh.",
        "hLhdh..",
        "h.hh...",
        "h.h....",
    ], ["h": hair, "L": hairL, "d": hairD])

    // 4. The big body, a pixel broader each side and four rows taller than Clawd, lit along the left, the far side
    //    in shade; the far arm and its bound fist.
    c.rect(17, 22, 22, 16, clawdOrange)
    c.rect(17, 22, 1, 16, C(0xE89070)); c.rect(17, 37, 22, 1, clawdShade); c.rect(38, 22, 1, 16, clawdShade)
    c.rect(13, 32, 4, 3, clawdOrange)
    crawlH4Fist(c, 14, 35, 1, wrap, wrapD, wrapL)

    // 5. His hair over the top of his head, parted in the middle and falling to his shoulders either side.
    c.pattern(16, 17, [
        ".....hhhhhhhhhhhh.....",
        "...hhhLLhhhdhhLLhhh...",
        "..hhLhhhhhhdhhhhhLhh..",
        ".hhhhhhhhhhdhhhhhhhhh.",
        "hhhhhdhhhh..hhhhdhhhhh",
        "hhh..............hhhh.",
        "hh................hh..",
        "hh....................",
        "h.....................",
    ], ["h": hair, "L": hairL, "d": hairD])

    // 6. The face: a heavy brow, his eyes (looking up and away as he talks to her).
    c.rect(21, 23, 4, 1, hairD); c.rect(31, 23, 4, 1, hairD)
    c.rect(22, 24 - look, 2, 3, ink); c.rect(32, 24 - look, 2, 3, ink)

    // 7. The fur pelts over his shoulders, shaggy at the edges.
    c.pattern(15, 28, [
        ".FLF.",
        "FFFFL",
        "FdFFF",
        "FFFdF",
        "F.F.F",
    ], ["F": furC, "L": furL, "d": furD])
    c.pattern(35, 28, [
        ".FLF.",
        "LFFFF",
        "FFdFF",
        "FdFFF",
        "F.F.F",
    ], ["F": furC, "L": furL, "d": furD])

    // 8. The beard: blond and full from cheek to cheek, braided to a point; his mouth showing in it, moving as he
    //    talks.
    c.pattern(19, 27, [
        "h..................h",
        "hhhhhhhhhhhhhhhhhhhh",
        ".hhhLhhhhmmhhhhLhhh.",
        ".hhhhhLhhhhhhLhhhhh.",
        "..hhhhhhhhhhhhhhhh..",
        "....hhhhdhhhdhhh....",
        "......hhhdhhhh......",
        ".......dhhhhd.......",
        "........hddh........",
        ".........hh.........",
    ], ["h": beard, "L": beardL, "d": beardD, "m": beardD])
    if talking && Int(p.lt * 6) % 2 == 0 { c.rect(28, 29, 2, 1, C(0x5A2A1A)) }

    // 9. The leather belt, a brass buckle, and the fur kilt below it, shaggy along its hem.
    c.rect(17, 35, 22, 1, strap); c.rect(26, 35, 3, 1, buckle)
    c.pattern(17, 36, [
        "FFLFFFFFFLFFFFFFFLFFFF",
        "FdF.FdFFF.FdFFF.dFF.FF",
    ], ["F": furC, "L": furL, "d": furD])

    // 10. The near fist, bound in leather: down at his side, or punching.
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: clawdOrange, reach: 6) { x, y, al in
            crawlH4Fist(c, x, y, al, wrap, wrapD, wrapL)
        }
    } else {
        c.rect(39, 30, 3, 4, clawdOrange); c.rect(41, 30, 1, 4, clawdShade)
        crawlH4Fist(c, 41, 35, 1, wrap, wrapD, wrapL)
    }

    // 11. The heart, floating up and off to the side while he talks to her, rocking a little as it rises.
    if talking && s > 0.3 {
        let k = (s - 0.3) / 0.62
        let x = 41 + Int((k * 6).rounded()) + (Int(k * 10) % 2), y = 21 - Int((k * 13).rounded())
        let a = k < 0.8 ? 1 : (1 - k) / 0.2
        c.pattern(x, y, ["HH.HH", "HLHHH", "HHHHH", ".HHH.", "..H.."], ["H": heart.alpha(a), "L": heartL.alpha(a)])
    }
}

// MARK: - Osvaldo

/// Osvaldo: barely five feet, Clawd drawn short, his head four rows lower than the rest, under a spiky shock of
/// dyed-red hair. A denim jacket buttoned up, brass buttons, dark jeans, white trainers; a small tan recurve bow. On his
/// far shoulder perches Gimli, his hawk of grey stone, a hooked beak and a stern eye. Signature: Gimli swoops off his
/// shoulder down onto a bug in the grass in front of him, and it turns to stone; then he flies back up to his perch.
private func drawOsvaldo(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xE8302A), redD = C(0xA81E1A), redL = C(0xFF7058)
    let denim = C(0x3E64A0), denimD = C(0x2A4878), denimL = C(0x6088C4), tee = C(0xE0B848)
    let jeans = C(0x2E3448), shoe = C(0xF0F0EC)
    let stone = C(0x8E8E8A), stoneD = C(0x5E5E5A), stoneL = C(0xBCBCB4)
    let bug = C(0x3A8A3A), bugD = C(0x1E5A24)
    let limb = C(0xC89A48), limbD = C(0x8A6A2A), grip = C(0x4A3420)
    let s = p.signature ?? -1
    let hunt = s > 0.06 && s < 0.96
    // Gimli leaves his shoulder at 0.12, lands on the bug at 0.4, stays a moment, back on his perch by 0.82.
    let perch = (x: 18.0, y: 23.0), prey = (x: 55.0, y: 37.0)
    var gimli = perch, flying = false
    if hunt && s > 0.12 && s < 0.82 {
        if s < 0.4 {
            let k = (s - 0.12) / 0.28
            gimli = (perch.x + (prey.x - perch.x) * k, perch.y + (prey.y - perch.y) * k - sin(k * .pi) * 8)
            flying = true
        } else if s < 0.54 {
            gimli = prey
        } else {
            let k = (s - 0.54) / 0.28
            gimli = (prey.x + (perch.x - prey.x) * k, prey.y + (perch.y - prey.y) * k - sin(k * .pi) * 10)
            flying = true
        }
    }
    let stoned = s >= 0.4

    // 1. Dark jeans, white trainers.
    drawLegs(c, Look(leg: jeans), step: p.step)
    drawBoots(c, shoe, step: p.step, rows: 1)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The short body: four rows lower than Clawd's, lit along the top; the far arm in the denim sleeve.
    c.rect(18, 30, 20, 8, clawdOrange)
    c.rect(18, 37, 20, 1, clawdShade); c.rect(37, 30, 1, 8, clawdShade)
    c.rect(15, 34, 3, 3, denim); c.px(15, 34, denimL)

    // 4. The face: his eyes.
    c.rect(22, 31, 2, 2, ink); c.rect(32, 31, 2, 2, ink)

    // 5. The hair: a spiky shock of dyed red, the spikes swept up and back, a lit stroke along them.
    c.pattern(17, 26, [
        "..r...r...r...r..r..",
        ".rLr.rLr.rLr.rLrrLr.",
        "rrrrrrrrrrrrrrrrrrrr",
        "rRrrrRrrrRrrrRrrrrRr",
        "r..................r",
    ], ["r": red, "L": redL, "R": redD])

    // 6. The denim jacket over a yellow T-shirt: open down the front, the collar turned out, lit on the left, the far
    //    side in shade, a seam.
    c.rect(18, 34, 20, 4, denim)
    c.rect(18, 34, 20, 1, denimL); c.rect(18, 35, 1, 2, denimL)
    c.rect(28, 35, 1, 3, denimD); c.px(26, 36, tee); c.px(30, 36, tee); c.rect(37, 35, 1, 3, denimD)
    c.rect(20, 36, 3, 1, denimD); c.rect(33, 36, 3, 1, denimD); c.rect(18, 37, 20, 1, denimD)

    // 7. The bug in the grass in front of him (signature): a little green beetle, scuttling, then stone grey and still.
    if hunt {
        let scuttle = stoned ? 0 : Int(p.lt * 6) % 2
        let bx = Int(prey.x) - 1 + scuttle
        let shell = stoned ? stone : bug, shellD = stoned ? stoneD : bugD
        c.pattern(bx, 41, [".SS.", "SSSS", "d.d."], ["S": shell, "d": shellD])
        c.px(bx + 1, 41, stoned ? stoneL : C(0x7ACA5A))
        if stoned && s < 0.6 {
            let k = (s - 0.4) / 0.2
            for i in 0..<4 {
                let q = crawlReach((Double(bx) + 2, 41.5), Double(i) * 90 + 45, 2 + k * 3)
                c.px(Int(q.x.rounded()), Int(q.y.rounded()), C(0xE8E8E0, 0.9 * (1 - k)))
            }
        }
    }

    // 8. Gimli: a stone hawk on his far shoulder, wings folded, the hooked beak forward, a stern eye; flying, his
    //    wings spread and beating.
    let gx = Int(gimli.x.rounded()), gy = Int(gimli.y.rounded()) - (flying ? 0 : p.breathe)
    if flying {
        let beat = Int(p.lt * 10) % 2
        c.pattern(gx - 4, gy - 2, beat == 0 ? [
            "SS.....SS..",
            ".SSs.sSS...",
            "..SSSSSSBb.",
            "...dSSd.b..",
            "....d.d....",
        ] : [
            "...........",
            "...s.s.....",
            "SSSSSSSSBb.",
            ".SSdSSdSb..",
            "SS..d.d.SS.",
        ], ["S": stone, "s": stoneL, "d": stoneD, "B": stone, "b": C(0xD8C890)])
        c.px(gx + 3, gy, ink)
    } else {
        c.pattern(gx, gy, [
            "..SSS.",
            ".SSkSb",
            "SSSSSb",
            "LSSSd.",
            "LSSSd.",
            ".LSSd.",
            "..dd..",
            ".D.D..",
        ], ["S": stone, "L": stoneL, "d": stoneD, "k": ink, "b": C(0xD8C890), "D": C(0x4A4A46)])
    }

    // 9. The bow, held out at arm's length, an arrow nocked and drawn before he looses it.
    var pull = 0, nocked = p.ready
    if let f = p.fire {
        let ph = frac(f.t / p.firePeriod)
        nocked = ph >= 0.45
        if ph > 0.6 { pull = Int(((ph - 0.6) / 0.4 * 3).rounded()) }
    }
    c.oy += p.gunY + (seatedPose ? -3 : 0)
    c.oy += 1
    c.rect(38, 33, 6, 2, denim); c.px(38, 33, denimL)
    crawlH4Bow(c, x: 44, half: 7, pull: pull, nocked: nocked, tip: 49, limb: limb, limbD: limbD, grip: grip,
               hand: clawdOrange)
}
