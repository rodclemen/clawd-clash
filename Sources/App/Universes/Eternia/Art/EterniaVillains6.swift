import Foundation

// Villains: the rest of the Horde (Octavia, Vultak and Horde Prime himself) and the two snake men who fight beside
// them (Rattlor and Tung Lashor), drawn the same way as EterniaVillains1.swift and the Horde in EterniaVillains3.swift.

let eterniaVillains6: [EterniaVillain: Persona] = [
    .octavia: Persona(name: "Octavia", weapon: .saber, headTop: 13, signature: 3.2, draw: drawOctavia),
    .rattlor: Persona(name: "Rattlor", weapon: .saber, headTop: 20, signature: 3.0, draw: drawRattlor),
    .tungLashor: Persona(name: "Tung Lashor", weapon: .saber, pivot: (38, 32.5), headTop: 18, signature: 3.2,
                         draw: drawTungLashor),
    .vultak: Persona(name: "Vultak", weapon: .saber, motion: .fly, headTop: 21, signature: 3.4, draw: drawVultak),
    .hordePrime: Persona(name: "Horde Prime", weapon: .lightning, motion: .hover,
                         magic: Magic(core: C(0xB4FF2A), glow: C(0x14200A)),
                         canSit: false, pivot: (57, 28.5), headTop: 13, signature: 3.6, draw: drawHordePrime),
]

// MARK: - Shared bits

/// 0 before `a`, 1 after `b`, a straight run between.
private func h6Ramp(_ s: Double, _ a: Double, _ b: Double) -> Double { min(1, max(0, (s - a) / (b - a))) }

/// The Horde's red bat, ears up and wings raised, 9 wide and 4 high, its top-left corner at (`x`, `y`). Worn on the
/// brow, as in EterniaVillains3.swift: never on the chest, where it reads as a grin.
private func h6Bat(_ c: PixelCanvas, _ x: Int, _ y: Int, red: Px, redD: Px) {
    c.pattern(x, y, [
        "R..R.R..R",
        "RR.RRR.RR",
        ".RRRdRRR.",
        "...R.R...",
    ], ["R": red, "d": redD])
}

/// A plain chest plate from row 33 to 37, its top edge dark so it parts cleanly from the face, lit under that.
private func h6Plate(_ c: PixelCanvas, plate: Px, plateD: Px, plateL: Px) {
    c.rect(20, 33, 16, 5, plate); c.rect(20, 33, 16, 1, plateD); c.rect(20, 34, 16, 1, plateL)
    c.rect(35, 34, 1, 4, plateD); c.rect(20, 37, 16, 1, plateD)
}

/// A tapering rope through `pts` (a tail, a neck), `r0` thick at the first point and `r1` at the last, in `col` with
/// a darker `rim` round it so it parts from whatever is behind.
private func h6Rope(_ c: PixelCanvas, _ pts: [(x: Double, y: Double)], r0: Double, r1: Double, col: Px, rim: Px) {
    let none = C(0, 0)
    for pass in 0..<2 {
        for k in 1..<pts.count {
            let f = Double(k) / Double(pts.count - 1)
            let r = r0 + (r1 - r0) * f
            let a = pts[k - 1], b = pts[k]
            if pass == 0 {
                c.glowLine(a.x, a.y, b.x, b.y, core: rim, glow: none, coreR: r + 0.6, glowR: r + 0.65)
            } else {
                c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: none, coreR: r, glowR: r + 0.05)
            }
        }
    }
}

// MARK: - Octavia

/// One of Octavia's tentacles, from `b` at `angle` degrees, turning `curl` degrees more at every one of its `n`
/// joints: thick at the root and thin at the tip, a dark rim round it so the four part from each other, a lit run
/// along its outer side and pale suckers dotted along the side it curls towards.
private func octaviaTentacle(_ c: PixelCanvas, from b: (x: Double, y: Double), angle: Double, curl: Double, n: Int = 7,
                             seg: Double = 1.9, skin: Px, rim: Px, lit: Px, sucker: Px) {
    var pts: [(x: Double, y: Double)] = [b]
    var a = angle
    for _ in 0..<n {
        pts.append(eterniaReach(pts[pts.count - 1], a, seg))
        a += curl
    }
    h6Rope(c, pts, r0: 1.6, r1: 0.5, col: skin, rim: rim)
    let side: Double = curl >= 0 ? 90 : -90
    a = angle
    for k in 0..<(n - 1) {
        let mid = ((pts[k].x + pts[k + 1].x) / 2, (pts[k].y + pts[k + 1].y) / 2)
        let r = 1.6 - 1.1 * Double(k) / Double(n)
        let inner = eterniaReach(mid, a + side, r * 0.75), outer = eterniaReach(mid, a - side, r * 0.75)
        if k % 2 == 1 { c.px(Int(inner.x.rounded(.down)), Int(inner.y.rounded(.down)), sucker) }
        if k < n - 2 { c.px(Int(outer.x.rounded(.down)), Int(outer.y.rounded(.down)), lit) }
        a += curl
    }
}

/// Octavia: the Horde's octopus woman. Blue skin, a great domed octopus mantle for a head, leaning back and dappled
/// with darker spots, a steel Horde circlet across her brow with the red bat on it, big yellow octopus eyes with a
/// bar of a pupil, a steel chest plate, and four blue tentacles, suckers and all: two behind her, curling up, one
/// hanging at her front and the one she fights with, lashing from her near shoulder. Signature: she lifts all four
/// tentacles and waves them about.
private func drawOctavia(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x3C7ED8), skinD = C(0x2A58A8), skinL = C(0x78B2F6), rim = C(0x1A3474), spot = C(0x2A5EB4)
    let sucker = C(0xF6C8DC), eyeY = C(0xFFD84A), eyeL = C(0xFFF2A8), boot = C(0x2A2240), bootL = C(0x4A4068)
    let steel = C(0x8A8E9C), steelD = C(0x5A5E6C), steelL = C(0xB8BCC8), red = C(0xD0202A), redD = C(0x8A1018)
    let s = p.signature ?? -1
    let wave = s < 0 ? 0 : h6Ramp(s, 0.06, 0.2) * (1 - h6Ramp(s, 0.82, 0.96))
    let w = sin(p.t * 7), w2 = sin(p.t * 7 + 2)
    let drift = sin(p.lt * 1.6)

    // Blue legs, dark purple boots lit at the cuff.
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, boot, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 1, 2, 1, bootL); c.px(lx, bottom - 4, skinL)
        }
    }
    c.oy += p.breathe

    // The two tentacles behind her, curling up off her back; waving, they rise and thrash.
    let lit = skinL
    octaviaTentacle(c, from: (17, 30), angle: 190 + 65 * wave + 18 * w * wave + 4 * drift,
                    curl: 15 - 28 * wave + 8 * w * wave,
                    skin: skinD, rim: rim, lit: skin, sucker: sucker)
    octaviaTentacle(c, from: (17, 35), angle: 165 + 60 * wave - 18 * w2 * wave - 3 * drift, curl: 17 - 30 * wave,
                    skin: skin, rim: rim, lit: lit, sucker: sucker)

    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 26, 1, 7, skinL)

    // The mantle: a great bulb of a dome rising off her head, wider than her face and pinched in above the brow,
    // leaning back, lit at the top left, dappled with spots.
    for y in 13...25 {
        let t = max(0, (19.5 - Double(y)) / 7)
        let hw = y >= 20 ? 11.5 - Double(y - 20) * 0.3 : 11.5 * (1 - t * t).squareRoot()
        let lean = y >= 20 ? 0 : -(20 - Double(y)) / 2.6
        let x0 = Int((28 + lean - hw).rounded()), x1 = Int((28 + lean + hw).rounded())
        c.rect(x0, y, x1 - x0, 1, skin)
        c.px(x0, y, skinL); c.px(x1 - 1, y, skinD)
    }
    c.rect(22, 14, 4, 1, skinL); c.rect(20, 15, 3, 1, skinL); c.px(19, 16, skinL); c.px(18, 17, skinL)
    for (x, y) in [(24, 16), (30, 15), (34, 18), (21, 19), (28, 18), (32, 21), (25, 20)] {
        c.rect(x, y, 2, 1, spot); c.px(x, y + 1, spot)
    }

    // The thin steel circlet across her brow, the red bat standing up off it.
    c.rect(18, 25, 20, 1, steel); c.px(18, 25, steelL); c.px(37, 25, steelD)
    h6Bat(c, 23, 21, red: red, redD: redD)
    c.px(27, 25, red)

    // Big yellow octopus eyes, each with a black bar of a pupil, under a heavy lid with lashes flicked out.
    for ex in [21, 31] {
        c.rect(ex, 28, 3, 3, eyeY); c.px(ex, 28, eyeL); c.rect(ex, 29, 3, 1, ink)
        c.rect(ex - 1, 27, 5, 1, ink)
    }
    c.px(19, 26, ink); c.px(35, 26, ink)

    // A steel Horde chest plate on a dark belt.
    h6Plate(c, plate: steel, plateD: steelD, plateL: steelL)
    c.rect(18, 36, 20, 1, C(0x1E1A2A)); c.rect(27, 36, 2, 1, red)

    // The tentacle hanging at her front, curling forward and up at the tip.
    octaviaTentacle(c, from: (36, 36), angle: 55 - 60 * wave + 22 * w2 * wave + 5 * drift, curl: -17,
                    skin: skin, rim: rim, lit: lit, sucker: sucker)
    // The one she fights with, from her near shoulder: lashing at the weapon's angle, hanging and curling under
    // at rest, raised and waving in the signature.
    let a: Double, curl: Double
    if let m = p.melee { a = m; curl = -5 }
    else if wave > 0 { a = 10 - 75 * wave + 25 * w * wave; curl = 14 - 22 * wave + 8 * w * wave }
    else { a = 8 + 6 * drift; curl = 14 }
    octaviaTentacle(c, from: (39, 34), angle: a, curl: curl, n: 8, seg: 2, skin: skin, rim: rim, lit: lit,
                    sucker: sucker)
    c.rect(38, 33, 3, 3, skin); c.px(38, 33, skinL)
}

// MARK: - Rattlor

/// Rattlor: the rattlesnake man. Red-orange scales with rattlesnake diamonds down his crown, yellow slit eyes under
/// a heavy brow, a flat snake's snout and a yellow banded belly; a black harness strap and belt with a silver snake
/// buckle, black bracers and boots. His tail curls up behind him to a rattle of pale horny beads. He bites: his neck
/// shoots out, carrying his head up and forward with its jaws open and fangs bared. Signature: the tail lifts and the
/// rattle shakes, a blur with little sound ticks off it.
private func drawRattlor(_ c: PixelCanvas, _ p: Pose) {
    let scale = C(0xE0582A), scaleD = C(0xA83A1A), scaleL = C(0xFF8C56), diamond = C(0x7A2612)
    let belly = C(0xF4D040), bellyD = C(0xC8A020)
    let strap = C(0x1E1A22), strapL = C(0x46404C), silver = C(0xD0D4DE)
    let rattle = C(0xEAD8A6), rattleD = C(0xA8946A), rattleL = C(0xFFF4D4)
    let eyeY = C(0xFFE04A), fang = C(0xF4F0E4), maw = C(0x6A1020)
    let s = p.signature ?? -1
    let shaking = s > 0.1 && s < 0.9
    let lift = s < 0 ? 0 : h6Ramp(s, 0.02, 0.14) * (1 - h6Ramp(s, 0.86, 0.98))
    let k: Double = p.melee.map { max(0, cos(($0 + 25) * .pi / 180)) } ?? 0
    let hx = Int((k * 7).rounded()), hy = -Int((k * 5).rounded())
    let bite = k > 0.5

    // Red-orange scaled legs, black boots.
    drawLegs(c, Look(leg: scale), step: p.step)
    drawBoots(c, strap, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 5, scaleL); c.px(lx + 1, bottom - 4, scaleD); c.px(lx, bottom - 1, strapL)
        }
    }
    c.oy += p.breathe

    // The tail, behind him: out from the small of his back, along the ground and curling up, diamonds down it, to
    // the rattle standing up at its tip. Shaking, it lifts and blurs.
    let jig: Double = shaking ? (Int(p.t * 28) % 2 == 0 ? -1 : 1) : 0
    let tip = (x: 8.5 + jig, y: 27.5 - 3 * lift)
    let pts: [(x: Double, y: Double)] = [(18, 35), (14, 37), (10.5, 36.5), (8.5, 34), (7.8 + jig * 0.3, 31 - lift),
                                         tip]
    h6Rope(c, pts, r0: 1.7, r1: 1.0, col: scale, rim: scaleD)
    for q in pts.dropFirst().dropLast() { c.px(Int(q.x.rounded(.down)), Int(q.y.rounded(.down)), diamond) }
    func beads(_ x: Int, _ alpha: Double) {
        let y0 = Int(tip.y.rounded(.down))
        for i in 0..<4 {
            let y = y0 - 2 - i * 2
            c.rect(x - 1, y, 3, 2, rattle.alpha(alpha)); c.px(x - 1, y, rattleL.alpha(alpha))
            c.rect(x - 1, y + 1, 3, 1, rattleD.alpha(alpha)); c.px(x - 1, y + 1, rattle.alpha(alpha))
        }
        c.px(x, y0 - 10, rattle.alpha(alpha))
    }
    let bx = Int(tip.x.rounded(.down))
    if shaking { beads(bx - 2 * Int(jig), 0.35) }
    beads(bx, 1)
    if shaking {   // the sound coming off it: little ticks either side, flickering
        let on = Int(p.t * 12) % 2 == 0
        let tick = C(0xFFF0C8, on ? 0.85 : 0.4)
        let ty = Int(tip.y.rounded(.down)) - 8
        c.px(bx - 4, ty, tick); c.px(bx - 5, ty - 1, tick); c.px(bx + 4, ty - 1, tick); c.px(bx + 5, ty - 2, tick)
        c.px(bx - 4, ty + 4, tick); c.px(bx + 4, ty + 3, tick)
    }

    // His body, the yellow banded belly, the strap over his shoulder and the belt with its silver snake buckle.
    drawBody(c, Look(body: scale, shade: scaleD, arm: scale, eye: nil))
    c.rect(18, 26, 1, 11, scaleL)
    for y in 33...37 { c.rect(22, y, 12, 1, y % 2 == 0 ? belly : bellyD) }
    c.rect(21, 33, 1, 4, scaleD)
    c.pattern(18, 32, ["SS..", ".SS.", "..SS", "...S"], ["S": strap])
    c.rect(18, 36, 20, 1, strap); c.px(18, 36, strapL)
    c.pattern(26, 35, [".SS.", "S..S", ".SS."], ["S": silver])
    c.rect(15, 34, 3, 1, strap); c.rect(38, 34, 3, 1, strap)

    // The neck, when it shoots out: striped, the yellow belly running up its front, leaning towards the head.
    let ny = 32 + hy
    if hy < 0 {
        for y in ny...32 {
            let f = Double(32 - y) / Double(-hy)
            let sx = Int((Double(hx) * f).rounded())
            c.rect(21 + sx, y, 13, 1, scale); c.px(21 + sx, y, scaleL); c.px(33 + sx, y, scaleD)
            c.rect(27 + sx, y, 6, 1, y % 2 == 0 ? belly : bellyD)
            if y % 3 == 0 { c.px(23 + sx, y, diamond) }
        }
    }

    // The head, carried on the neck: a rounded crown with dark diamonds, the flat snout jutting forward, yellow slit
    // eyes under a heavy brow, a nostril, and the jaw, shut with a fang showing or open wide to bite.
    c.ox += hx; c.oy += hy
    c.rect(23, 21, 10, 1, scale); c.rect(20, 22, 16, 1, scale); c.rect(19, 23, 18, 3, scale)
    c.rect(18, 26, 20, 6, scale); c.rect(38, 28, 4, 4, scale); c.rect(38, 28, 3, 1, scaleL)
    c.rect(24, 21, 4, 1, scaleL); c.rect(20, 23, 1, 3, scaleL); c.rect(18, 26, 1, 6, scaleL); c.px(21, 22, scaleL)
    c.rect(36, 23, 1, 3, scaleD); c.rect(37, 26, 1, 2, scaleD)
    for (x, y) in [(22, 23), (28, 22), (33, 24)] {
        c.pattern(x - 1, y, [".D.", "DDD", ".D."], ["D": diamond])
    }
    c.rect(20, 27, 5, 1, scaleD); c.rect(30, 27, 5, 1, scaleD)
    for ex in [21, 31] { c.rect(ex, 28, 3, 3, eyeY); c.rect(ex + 1, 28, 1, 3, ink) }
    c.px(40, 29, ink)
    if bite {
        c.rect(26, 32, 16, 3, maw); c.rect(26, 31, 16, 1, ink)
        c.rect(26, 34, 16, 1, scale); c.rect(26, 35, 15, 1, scaleD)
        c.px(39, 32, fang); c.px(39, 33, fang); c.px(36, 32, fang); c.px(37, 33, fang)
    } else {
        c.rect(26, 31, 16, 1, scaleD); c.rect(25, 32, 17, 1, scale); c.rect(38, 32, 4, 1, scaleD)
        c.px(39, 33, fang)
    }
    c.ox -= hx; c.oy -= hy
}

// MARK: - Tung Lashor

/// Tung Lashor's tongue: out of his mouth at `m` along `angle` degrees for `length` pixels, wriggling, pink with a
/// lit top and a dark rim, and forked at the tip.
private func tungTongue(_ c: PixelCanvas, from m: (x: Double, y: Double), angle a: Double, length: Double, t: Double) {
    let pink = C(0xF2609E), pinkD = C(0xA02A62), pinkL = C(0xFFB0D2)
    let n = max(2, Int(length / 1.6))
    var pts: [(x: Double, y: Double)] = []
    for k in 0...n {
        let f = Double(k) / Double(n)
        let wob = sin(f * 9 + t * 22) * 0.9 * f
        pts.append(eterniaReach(eterniaReach(m, a, length * f), a + 90, wob))
    }
    h6Rope(c, pts, r0: 1.1, r1: 0.7, col: pink, rim: pinkD)
    for k in stride(from: 1, to: n, by: 2) {
        let q = eterniaReach(pts[k], a - 90, 0.5)
        c.px(Int(q.x.rounded(.down)), Int(q.y.rounded(.down)), pinkL)
    }
    let tip = pts[pts.count - 1]
    for d in [-30.0, 30] {
        let e = eterniaReach(tip, a + d, 3)
        c.glowLine(tip.x, tip.y, e.x, e.y, core: pink, glow: pinkD, coreR: 0.5, glowR: 0.9)
    }
}

/// Tung Lashor: the snake man with the tongue. Purple scales, a crest of dark spines down his crown, big round
/// bulging orange eyes, a wide mouth from ear to snout with a fang at each corner, a cream banded belly, a teal
/// shoulder guard and teal belt and bracers. He fights with his long pink forked tongue, lashing it out of his mouth.
/// Signature: he flicks his tongue right out, twice, far in front of him.
private func drawTungLashor(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8A48C8), skinD = C(0x5E2C96), skinL = C(0xB27CEA), spine = C(0x3E1A6A), spineL = C(0x6A3AA0)
    let belly = C(0xF0E2A8), bellyD = C(0xC4B47A)
    let teal = C(0x1E8A8A), tealD = C(0x125858), tealL = C(0x4CC0B8), gold = C(0xE0B040)
    let eye = C(0xFFA028), eyeL = C(0xFFD890), fang = C(0xF4F0E4)
    let s = p.signature ?? -1
    let flick: Double = s > 0.1 && s < 0.9 ? abs(sin((s - 0.1) / 0.8 * 2 * .pi)) : 0
    let taste = s < 0 && p.melee == nil && Int(p.lt * 2.5) % 7 == 0
    let mouth = (x: 38.0, y: 32.5)
    let tongueOut = p.melee != nil || flick > 0.05 || taste

    // Purple legs, teal boots.
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, tealD, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 1, teal); c.px(lx, bottom - 5, skinL); c.px(lx + 1, bottom - 3, skinD)
        }
    }
    c.oy += p.breathe

    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 26, 1, 7, skinL)
    // The crown, rounded up over his head, scaled in strokes, and the crest of spines down it, leaning back.
    c.rect(23, 22, 10, 1, skin); c.rect(20, 23, 16, 1, skin); c.rect(19, 24, 18, 2, skin)
    c.rect(24, 22, 3, 1, skinL); c.rect(20, 24, 1, 2, skinL); c.rect(36, 24, 1, 2, skinD)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 25, skinL); c.px(x + 1, 26, skinD) }
    c.pattern(19, 18, [
        "D....D.....D.....",
        "DD...DD....DD....",
        ".DD...DD....DD...",
        "..lD...lD....lD..",
    ], ["D": spine, "l": spineL])
    c.rect(22, 22, 12, 1, spine)

    // The bulging eyes, round and orange with a black pupil looking ahead, a dark ring under each, a heavy brow.
    for ex in [20, 31] {
        c.pattern(ex, 26, [".OOO.", "OLOOO", "OOOKK", "OOOKK", ".ooo."], ["O": eye, "L": eyeL, "K": ink, "o": skinD])
        c.rect(ex, 25, 5, 1, skinD)
    }
    // The wide mouth, open when the tongue is out, and a fang at each end.
    if tongueOut {
        c.rect(25, 31, 13, 2, ink); c.rect(27, 32, 10, 1, C(0x8A1E4A))
    } else {
        c.rect(25, 32, 13, 1, ink); c.px(24, 31, ink)
    }
    c.px(26, 33, fang); c.px(36, 33, fang)

    // The cream belly in bands, the teal belt with a gold buckle, the shoulder guard and the bracers.
    for y in 34...37 { c.rect(23, y, 11, 1, y % 2 == 0 ? belly : bellyD) }
    c.rect(18, 36, 20, 1, teal); c.rect(18, 36, 3, 1, tealL); c.rect(27, 36, 2, 1, gold)
    c.pattern(15, 31, [".TTTT", "TLTTT", "TTTTd", "Tdd.."], ["T": teal, "L": tealL, "d": tealD])
    c.rect(15, 35, 3, 1, tealD); c.rect(38, 34, 3, 1, teal); c.px(38, 34, tealL)

    // The tongue: lashing at the weapon's angle, flicked right out in the signature, or tasting the air at rest.
    if let a = p.melee {
        tungTongue(c, from: mouth, angle: a, length: 15, t: p.t)
    } else if flick > 0.05 {
        tungTongue(c, from: mouth, angle: 4, length: 3 + 21 * flick, t: p.t)
    } else if taste {
        tungTongue(c, from: mouth, angle: 10, length: 3, t: p.t)
    }
}

// MARK: - Vultak

/// One of Vultak's wings spread from shoulder `sh`: a fan of black feathers out to the leading edge from `a` to `b`,
/// lit grey strokes between the long flight feathers and a pale edge along the top, so it reads against the night.
private func vultakWing(_ c: PixelCanvas, _ sh: (Double, Double), _ a: (Double, Double), _ b: (Double, Double),
                        bow: Double, dim: Bool) {
    let feather = dim ? C(0x1C1A24) : C(0x2A2834), stroke = dim ? C(0x3E3C50) : C(0x5C5A74)
    let edge = dim ? C(0x6A6880) : C(0x9A98B4)
    for k in 0...16 {
        let t = Double(k) / 16
        let tip = (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t - bow * sin(t * .pi))
        c.glowLine(sh.0, sh.1, tip.0, tip.1, core: k % 4 == 2 ? stroke : feather, glow: C(0, 0), coreR: 0.7, glowR: 0.8)
    }
    c.glowLine(sh.0, sh.1 - 0.5, b.0, b.1, core: edge, glow: C(0, 0), coreR: 0.5, glowR: 0.6)
}

/// Vultak: the Horde's vulture. A bald pink head, wrinkled across the crown, angry yellow eyes under a heavy pink
/// brow and a big hooked yellow beak; a ruff of grey-white feathers round his neck, black plumage scalloped in grey
/// below it, great black wings folded down his back (spread and beating in flight), and grey vulture's legs with black
/// talons. He fights with the talons of his near foot-like hand. Signature: he hunches, wings mantled up round his
/// shoulders, and croaks, his beak gaping and the croaks rolling out.
private func drawVultak(_ c: PixelCanvas, _ p: Pose) {
    let feather = C(0x2A2834), featherD = C(0x16141C), featherL = C(0x5C5A74), edge = C(0x9A98B4)
    let head = C(0xE88A9A), headD = C(0xB45A6E), headL = C(0xFFB8C4)
    let ruff = C(0xE2DED6), ruffD = C(0xA8A49C)
    let beak = C(0xECD47A), beakD = C(0xAC944A), beakL = C(0xFFF2B8), mawC = C(0x7A1A2A)
    let leg = C(0x9A8E96), legD = C(0x6A5E66), legL = C(0xBEB2BA), talon = C(0x141018)
    let eyeC = C(0xFFCC30)
    let s = p.signature ?? -1
    let hunch = s < 0 ? 0 : h6Ramp(s, 0.05, 0.2) * (1 - h6Ramp(s, 0.84, 0.97))
    let croaking = (s > 0.3 && s < 0.46) || (s > 0.58 && s < 0.74)
    let down = Int((hunch * 2).rounded())
    let up: Bool? = p.flying ? Int(p.t * 7) % 2 == 0 : nil

    // Grey scaled legs and black talons, splayed.
    drawLegs(c, Look(leg: leg), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx, bottom - 5, legL); c.px(lx + 1, bottom - 3, legD)
            c.px(lx - 1, bottom, talon); c.px(lx + 2, bottom, talon); c.px(lx + 1, bottom, legD)
        }
    }
    c.oy += p.breathe + down

    // The wings: beating in flight, mantled up round his shoulders as he hunches, otherwise the far one folded behind.
    if let u = up {
        for (n, sh) in [(23.0, 29.0), (27.0, 30.0)].enumerated() {
            let dx = Double(n) * 5
            if u { vultakWing(c, sh, (6 + dx, 21), (15 + dx, 7), bow: 3, dim: n == 0) }
            else { vultakWing(c, sh, (5 + dx, 34), (10 + dx, 43), bow: -1, dim: n == 0) }
        }
    } else if hunch > 0 {
        let h = Int((hunch * 5).rounded())
        for (n, x) in [11, 15].enumerated() {
            let col = n == 0 ? featherD : feather
            c.pattern(x, 22 - h + 5, [
                "...EEEE.",
                "..EFFFFE",
                ".EFFFFFF",
                "EFFFFFFF",
                "FFFFFFFF",
                "FFsFFsFF",
                "FFFFFFFF",
                "FsFFsFFF",
                "FFFFFFFF",
                "F.F.F.FF",
            ], ["E": n == 0 ? featherL : edge, "F": col, "s": featherL])
        }
    }

    drawBody(c, Look(body: feather, shade: featherD, arm: feather, eye: nil))
    // Black plumage scalloped in grey, lit down the left.
    for y in stride(from: 34, through: 36, by: 2) {
        for x in stride(from: 20 + (y / 2) % 2 * 2, to: 37, by: 4) { c.rect(x, y, 2, 1, featherL) }
    }
    c.rect(18, 33, 1, 4, featherL)

    // The bald pink head: the top of his face and a smooth dome over it, lit on the left, a couple of wrinkles at the
    // back of his neck, and the angry brows sloping down to the beak.
    c.rect(18, 26, 20, 6, head)
    c.rect(22, 23, 12, 1, head); c.rect(20, 24, 16, 2, head)
    c.rect(23, 23, 4, 1, headL); c.rect(20, 24, 2, 2, headL); c.rect(18, 26, 1, 5, headL); c.rect(37, 26, 1, 5, headD)
    c.rect(34, 24, 2, 1, headD); c.px(19, 28, headD); c.px(19, 30, headD)
    c.pattern(20, 27, ["DD...........DD", "..DD.......DD.."], ["D": ink])
    for ex in [21, 31] { c.rect(ex, 29, 3, 2, eyeC); c.rect(ex + 1, 29, 2, 2, ink) }

    // The ruff round his neck: grey-white feathers in tufts, ragged along the bottom.
    c.rect(17, 31, 22, 2, ruff)
    for x in stride(from: 17, to: 39, by: 2) { c.px(x, 33, x % 4 == 1 ? ruff : ruffD) }
    for x in stride(from: 19, to: 38, by: 3) { c.px(x, 32, ruffD) }
    c.px(17, 31, white); c.rect(38, 31, 1, 2, ruffD)

    // The far wing folded behind him, its long flight feathers trailing back, a pale edge along the top.
    if up == nil && hunch == 0 {
        c.pattern(9, 29, [
            "........EEEEEE",
            ".....EEEFFFFFF",
            "...EEFFFFsFFFF",
            ".EEFFFsFFFFFFF",
            "EFFFsFFFFFFFFF",
            "FFsFFFFFsFFFFF",
            ".FFFFsFFFFFFF.",
            "..F.F.FF.FF...",
        ], ["E": edge, "F": feather, "s": featherL])
    }

    // The beak: hooked and shut, or gaping as he croaks.
    if croaking && Int(p.t * 6) % 3 != 2 {
        c.pattern(35, 24, [
            "..LLBB......",
            ".LBBBBBB....",
            "LBBBBBBBBB..",
            "BBBBBBBBBBB.",
            "MMMMMM..bBBb",
            "MMMMM....bB.",
            "MMMM........",
            "bbbbbbb.....",
            ".bbbbbb.....",
        ], ["B": beak, "b": beakD, "L": beakL, "M": mawC])
        // The croaks rolling out of it: pale rings swelling and fading.
        for k in 0..<2 {
            let f = (s * 7 + Double(k) / 2).truncatingRemainder(dividingBy: 1)
            let r = 3 + f * 9, al = (1 - f) * 0.8
            for d in stride(from: -35.0, through: 35.0, by: 10) {
                let ang = d * .pi / 180
                c.px(Int((47 + cos(ang) * r).rounded()), Int((29 + sin(ang) * r).rounded()), C(0xF2EEFF, al))
            }
        }
    } else {
        c.pattern(35, 25, [
            "..LLBB......",
            ".LBBBBBB....",
            "LBBBBBBBBB..",
            "BBBBBBBBBBB.",
            "bbbbbbbbBBBb",
            "........bBB.",
            ".........bB.",
            "..........b.",
        ], ["B": beak, "b": beakD, "L": beakL])
        c.px(39, 27, beakD)   // the nostril
    }

    // The near hand: a feathered fist at rest, or the talons swiped at the weapon's angle.
    if let a = p.melee {
        prop(c, at: eterniaHand, angle: a) { q in
            q.pattern(17, 16, [
                ".......GG..K.",
                "......GGGGKK.",
                "GGGGGGGGG..K.",
                "LLLLLLLLGGGKK",
                "GGGGGGGGG..K.",
                "......GGGGKK.",
                ".......GG..K.",
            ], ["G": leg, "L": legL, "K": talon])
        }
        c.rect(38, 33, 3, 3, feather); c.px(38, 33, featherL)
    } else {
        c.rect(38, 33, 3, 3, feather); c.px(38, 33, featherL); c.px(41, 35, talon); c.px(41, 33, talon)
    }
}

// MARK: - Horde Prime

/// A puff of smoke: a disc of `base`, its upper-left rim lit and its lower-right rim in shade, so overlapping puffs
/// read as a billowing cloud.
private func primePuff(_ c: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, base: Px, lit: Px, dark: Px) {
    let x0 = Int(floor(cx - r)), x1 = Int(ceil(cx + r)), y0 = Int(floor(cy - r)), y1 = Int(ceil(cy + r))
    for y in y0...y1 {
        for x in x0...x1 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let d = (dx * dx + dy * dy).squareRoot()
            guard d <= r else { continue }
            let rim = d > r - 1.3
            let col = rim && dx + dy < -r * 0.45 ? lit : rim && dx + dy > r * 0.55 ? dark : base
            c.px(x, y, col)
        }
    }
}

/// Horde Prime: the Horde's dread master, who is never seen. A hooded cloak of billowing grey-violet smoke, its puffs
/// rolling, the Horde's red bat on its brow, inside it a black void with two slanted acid-green eyes, and four smoke
/// legs trailing away to wisps. Out of the smoke comes his one huge green hand, dark-nailed, its fingers flexing; he
/// points it to cast, and acid-green bolts crack out of the smoke round it. Signature: the hand reaches out of the
/// smoke and points, his eyes flaring.
private func drawHordePrime(_ c: PixelCanvas, _ p: Pose) {
    let smoke = C(0x6A6482), smokeD = C(0x48425C), smokeL = C(0x9C96B4), back = C(0x524C66), backL = C(0x7A7494)
    let hand = C(0x6CCC34), handD = C(0x3E8A1C), handL = C(0xA8EE6A), nail = C(0x1A2A10)
    let acid = C(0xB4FF2A), void = C(0x0C0A12), red = C(0xD0202A), redD = C(0x8A1018)
    let s = p.signature ?? -1
    let reach = s < 0 ? 0 : h6Ramp(s, 0.08, 0.3) * (1 - h6Ramp(s, 0.8, 0.95))
    let pointing = p.zap != nil || (s > 0.22 && s < 0.86)
    let flare = s > 0.3 && s < 0.8
    let hx = Int((reach * 5).rounded()), hy = -p.armRaise

    // The four smoke legs, thinning to wisps at the ground, a lit stroke down each.
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step
            let bottom = lifted ? 41 : 42
            c.rect(lx, 36, 2, bottom - 36, smokeD); c.rect(lx, 36, 1, bottom - 36, smoke)
            c.px(lx + (i % 2 == 0 ? 0 : 1), bottom, smokeD.alpha(0.6))
            c.px(lx + (i % 2 == 0 ? -1 : 2), bottom + 1, smokeD.alpha(0.35))
        }
    }
    c.oy += p.breathe

    // The smoke, back to front: wisps drifting off behind, the body of the cloak, then the hood.
    func roll(_ i: Int) -> Double { sin(p.lt * 1.8 + Double(i) * 1.3) * 0.6 }
    primePuff(c, 11.5 + roll(0), 29 + roll(1), 3, base: back, lit: backL, dark: smokeD)
    primePuff(c, 8.5 + roll(2), 24.5 + roll(3), 2, base: back, lit: backL, dark: smokeD)
    primePuff(c, 21, 35.5 + roll(4) * 0.5, 3.5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 28, 36, 4, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 35, 35.5 + roll(5) * 0.5, 3.5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 19.5 + roll(6), 31.5, 5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 36 + roll(7), 31.5, 5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 28, 32, 6, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 21 + roll(8) * 0.5, 24.5, 5.5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 35 + roll(9) * 0.5, 24.5, 5.5, base: smoke, lit: smokeL, dark: smokeD)
    primePuff(c, 28, 20.5 + roll(10) * 0.4, 7.5, base: smoke, lit: smokeL, dark: smokeD)

    // The void inside the hood, and the two slanted eyes glowing in it.
    for y in 25...32 {
        let t = (Double(y) - 28.5) / 4
        let hw = 8.5 * max(0, 1 - t * t).squareRoot()
        let x0 = Int((28 - hw).rounded()), x1 = Int((28 + hw).rounded())
        if x1 > x0 { c.rect(x0, y, x1 - x0, 1, void) }
    }
    let eyeCol = flare ? C(0xEAFFB0) : acid
    c.pattern(21, 28, ["AA..", ".AAA"], ["A": eyeCol]); c.pattern(31, 28, ["..AA", "AAA."], ["A": eyeCol])
    let eg = flare ? 0.6 : 0.35
    c.glowLine(22, 29, 24, 29.5, core: C(0, 0), glow: C(0x9AF02A, eg), coreR: 0.1, glowR: 1.8)
    c.glowLine(32, 29.5, 34, 29, core: C(0, 0), glow: C(0x9AF02A, eg), coreR: 0.1, glowR: 1.8)
    // The Horde's bat on the hood's brow.
    h6Bat(c, 24, 17, red: red, redD: redD)

    // The sleeve of smoke out to his wrist, then the hand.
    c.ox += hx; c.oy += hy
    primePuff(c, 38.5 - Double(hx) * 0.5, 33 + roll(11) * 0.4 - Double(hy) * 0.4, 2.8,
              base: smoke, lit: smokeL, dark: smokeD)
    if pointing {
        // The smoke wreathing his wrist, behind the fist.
        primePuff(c, 39.5, 35 + roll(12) * 0.3, 2.4, base: smoke, lit: smokeL, dark: smokeD)
        // The pointing hand: a fist, the thumb over it, and the long forefinger out ahead, its nail dark.
        c.pattern(39, 25, [
            "...LLLL..........",
            "..LGGGGL.........",
            ".LGGGGGGLLLLLLLL.",
            "LGGGGGGGGGGGGGGGN",
            "GGGGGGGGGGGGGGGNN",
            "GGGGGGGGddddddd..",
            "GGGGGGGGd........",
            "GdGGGdGGGd.......",
            "GGGGGGGGGd.......",
            "GdGGGdGGGd.......",
            "GGGGGGGGd........",
            ".dddddddd........",
        ], ["G": hand, "L": handL, "d": handD, "N": nail])
        if p.zap == false || flare {   // a crackle of acid green round the fingertip
            let k = Int(p.t * 20)
            for j in 0..<3 {
                let ang = noise(k * 3 + j) * 2 * .pi
                let x = 56.5 + cos(ang) * 2.2, y = 28.5 + sin(ang) * 2.2
                c.glowLine(56.5, 28.5, x, y, core: C(0xEAFFB0, 0.9), glow: C(0x6ACC1A, 0.5), coreR: 0.35, glowR: 1.2)
            }
        }
    } else {
        // The open hand, palm out and fingers up, each finger flexing in turn, dark claws of nails at the tips.
        c.rect(39, 25, 11, 6, hand); c.rect(39, 25, 1, 6, handL); c.rect(49, 25, 1, 6, handD)
        c.rect(40, 30, 9, 1, handD); c.rect(41, 26, 1, 3, handD); c.rect(46, 27, 2, 1, handD)
        for (i, fx) in [39, 42, 45, 48].enumerated() {
            let base = i == 1 || i == 2 ? 6 : 5
            let len = base - (sin(p.lt * 2.2 + Double(i) * 1.1) > 0.5 ? 1 : 0)
            c.rect(fx, 25 - len, 2, len, hand); c.px(fx, 25 - len, nail); c.px(fx + 1, 25 - len, nail)
            c.rect(fx, 26 - len, 1, len - 1, handL); c.px(fx + 1, 23, handD)
        }
        c.pattern(50, 26, ["GG.", "GGG", ".GN"], ["G": hand, "N": nail]); c.px(50, 26, handL)
        c.rect(41, 31, 7, 2, hand); c.rect(41, 32, 7, 1, handD)    }
    if !pointing {   // the smoke curling round his wrist
        primePuff(c, 41.5, 33.5 + roll(12) * 0.3, 2.2, base: smoke, lit: smokeL, dark: smokeD)
        primePuff(c, 45, 34 + roll(13) * 0.3, 1.8, base: smoke, lit: smokeL, dark: smokeD)
    }
    c.ox -= hx; c.oy -= hy
}
