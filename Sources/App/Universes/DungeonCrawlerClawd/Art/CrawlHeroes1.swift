import Foundation

// Heroes, 8 to 10 a file: each one a `Persona` in the dictionary below and a `private func draw…` further down. Read
// the clawdify guide's "Look and style" before drawing, and the header of Sources/App/Pose.swift for what a `Pose`
// gives you. Check every character with `build/preview cast out.png <name>`, and its edges with
// `build/preview edges out.txt "Dungeon Crawler Clawd"` (both from Tools/Preview/build.sh).
//
// The Royal Court of Princess Donut, first three: Carl, Donut and Mongo.

let crawlHeroes1: [CrawlHero: Persona] = [
    .carl: Persona(name: "Carl", weapon: .saber, headTop: 20, signature: 3.2, callout: "Donut!", draw: drawCarl),
    .donut: Persona(name: "Princess Donut", weapon: .blaster,
                    shot: .energy(core: C(0xFFE2F4), glow: C(0xFF3AB0)), muzzle: (44, 31), handGun: false,
                    headTop: 18, signature: 3.0, callout: "Carl!", draw: drawDonut),
    .mongo: Persona(name: "Mongo", weapon: .saber, bulk: 4, headTop: 16, signature: 2.6, draw: drawMongo),
]

// MARK: - Carl

/// Carl: Clawd with short brown hair, a battered brown leather jacket with its near sleeve burnt off at the shoulder
/// (the bare arm under it singed at the edge), blue boxer shorts with a darker stripe and a white waistband, and bare
/// feet with a gold toe ring on two of them. His near fist is in the War Gauntlet: steel plates, a spike on each
/// knuckle. He fights with his fists. Signature: he lights a stick of goblin dynamite, its fuse fizzing, and lobs it
/// up and away off the right of the frame; a moment later the boom flashes in from that side and he winces.
private func drawCarl(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x7A4A2E), leatherD = C(0x58321E), leatherL = C(0x9A6444), char = C(0x2A1A12)
    let boxer = C(0x4A72B8), boxerD = C(0x34548E), boxerL = C(0x6A92D0), band = C(0xEEEAE0)
    let hair = C(0x5A3A22), hairD = C(0x3C2414), hairL = C(0x7A5434)
    let gold = C(0xE8C040)
    let s = p.signature ?? -1
    // The signature's beats: up to 0.4 the lit stick held high, fuse fizzing; 0.4 to 0.6 it sails off; 0.62 to 0.86
    // the boom.
    let holding = s > 0.05 && s < 0.42
    let flying = s >= 0.42 && s < 0.62
    let boom = s >= 0.6 && s < 0.88 ? sin((s - 0.6) / 0.28 * .pi) : 0

    // 1. Bare legs, the boxers' legs over the top of each, and the toe rings on the ground row.
    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, 36, 2, 2, boxer); c.px(lx + 1, 37, boxerD)
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.px(lx + 1, bottom, clawdShade)
            if i == 1 || i == 3 { c.px(lx + 1, bottom - 1, gold) }
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Clawd's body. The near arm is bare, the far one in leather; it rises when he holds the dynamite up.
    let raise = holding ? 6 : 0
    drawBody(c, Look(arm: clawdOrange), armRight: raise)
    c.rect(15, 33, 3, 3, leather); c.px(15, 33, leatherL); c.rect(15, 35, 3, 1, leatherD)

    // 4. The boxers: a white waistband, blue below it with a darker stripe, shaded on the far side.
    c.rect(18, 35, 20, 3, boxer)
    c.rect(18, 35, 20, 1, band); c.rect(18, 35, 1, 1, C(0xFFFFFF))
    c.rect(18, 36, 1, 2, boxerL); c.rect(37, 36, 1, 2, boxerD)
    for x in [22, 27, 32] { c.rect(x, 36, 1, 2, boxerD) }
    c.rect(27, 37, 2, 1, boxerD)   // the fly

    // 5. The leather jacket, hanging open over his bare chest: lit on the left, the far side in shade, a turned
    //    collar, creases, and on the near side the shoulder burnt raw where the sleeve was, its charred edge ragged.
    c.rect(18, 32, 20, 3, leather)
    c.rect(26, 32, 4, 3, clawdOrange); c.rect(26, 34, 4, 1, clawdShade)   // the open front, his chest
    c.rect(24, 32, 2, 3, leatherL); c.rect(30, 32, 2, 3, leatherD)          // the lapels
    c.rect(18, 32, 1, 3, leatherL); c.rect(19, 32, 4, 1, leatherL)
    c.rect(36, 32, 2, 3, leatherD)
    c.px(21, 33, leatherD); c.px(34, 33, leatherD)
    c.rect(18, 34, 6, 1, leatherD); c.rect(32, 34, 4, 1, leatherD)
    c.pattern(34, 31, ["c.c.", ".cc.", "c..c"], ["c": char])   // the burnt edge at the shoulder
    c.px(38, 33 - raise, C(0xA85A3A))                         // a singe on the bare arm

    // 6. The face is Clawd's own: brows, which knit when the boom comes.
    if boom > 0.2 {
        c.pattern(21, 26, ["hh.", ".hh"], ["h": hairD]); c.pattern(31, 26, [".hh", "hh."], ["h": hairD])
    } else {
        c.rect(21, 27, 3, 1, hairD); c.rect(32, 27, 3, 1, hairD)
    }

    // 7. Short brown hair, a lit run along the top, a little longer at the back.
    c.pattern(17, 22, [
        "..HHHlHHHlHHHHlHHHHH..",
        ".HHlHHHHHhHHHHHHhHHHH.",
        "HHHHhHHhHHHHhHHHHHhHHH",
        "HHhHHHhHHHHhHHHHHhHHHH",
        "HHh..................H",
        "Hh....................",
    ], ["H": hair, "h": hairD, "l": hairL])

    // 8. The near fist in the War Gauntlet: steel, its plates picked out, a spike on each knuckle.
    func gauntlet(_ x: Int, _ y: Int, _ a: Double) {
        let steel = C(0x9AA2AE, a), steelD = C(0x5E6672, a), steelL = C(0xD0D6DE, a)
        c.rect(x - 1, y - 1, 3, 3, steel); c.px(x - 1, y - 1, steelL); c.rect(x - 1, y + 1, 3, 1, steelD)
        c.px(x + 2, y - 1, steelL); c.px(x + 2, y + 1, steelL)   // the knuckle spikes
    }
    if let a = p.melee {
        crawlPunch(c, angle: a, trail: p.trail, arm: clawdOrange, fist: gauntlet)
    } else if holding || flying {
        gauntlet(39, 33 - raise, 1)
    } else {
        gauntlet(39, 34, 1); c.rect(37, 34, 1, 2, C(0x5E6672))   // the cuff at his wrist
    }

    // 9. The dynamite: a red stick held high, its fuse fizzing with sparks; then thrown, tumbling up and away out of
    //    the frame; then the boom's light flaring in from the right edge.
    let red = C(0xC8302A), redD = C(0x8A1E1A)
    if holding {
        c.rect(40, 23, 2, 5, red); c.rect(41, 23, 1, 5, redD); c.rect(40, 25, 2, 1, C(0xE8D8A0))
        c.px(41, 22, C(0x3A2A1A)); c.px(42, 21, C(0x3A2A1A))
        if s > 0.12 {
            let n = Int(p.lt * 20)
            for k in 0..<3 where (n + k) % 2 == 0 {
                c.px(42 + [1, 0, 2][k], 20 - [0, 1, 1][k], k == 0 ? C(0xFFF2A0) : C(0xFF9A2A, 0.8))
            }
        }
    } else if flying {
        let k = (s - 0.42) / 0.2
        let x = 41 + k * 36, y = 24 - sin(k * .pi) * 14 - k * 6
        let spin = Int(k * 6) % 2 == 0
        let ix = Int(x.rounded()), iy = Int(y.rounded())
        if spin { c.rect(ix, iy, 2, 4, red); c.rect(ix + 1, iy, 1, 4, redD) } else { c.rect(ix - 1, iy + 1, 4, 2, red); c.rect(ix - 1, iy + 2, 4, 1, redD) }
        c.px(ix + 1, iy - 1, C(0xFFF2A0))
    }
    if boom > 0 {
        for y in 4...36 {
            let d = abs(Double(y) - 18) / 18
            for x in 60...71 {
                let k = boom * (1 - d * 0.7) * Double(x - 59) / 12
                if k > 0.15 { c.px(x, y, C(0xFFE8A0, min(0.85, k))) }
            }
        }
    }
}

// MARK: - Princess Donut

/// Princess Donut: a Persian, Clawd in her long fawn fur: a ginger saddle over her back, fluffy tufts along it, a full
/// cream ruff at her chest and a great plume of a tail held up behind her, fawn like the rest of her. Small round ears set wide, big copper
/// eyes, a squashed flat face with a tiny pink nose, and a little gold crown with a pink gem. Her Magic Missiles fly
/// from her in hot pink. Signature: she poses for the cameras: a flash goes off, she shuts her eyes in bliss, and a
/// little green viewer counter floats up over her: +10K.
private func drawDonut(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xA88058), furD = C(0x82603C), furL = C(0xC09A70)
    let saddle = C(0x9A4E22), saddleL = C(0xB86634)
    let cream = C(0xEAD2A0), creamD = C(0xC8AE7C), nose = C(0xE88AA0)
    let gold = C(0xF0C840), goldD = C(0xB88A20), gem = C(0xFF5AB8)
    let s = p.signature ?? -1
    let flash = s > 0.08 && s < 0.2
    let posing = s > 0.12 && s < 0.88

    // 1. Her legs in fawn, cream toes.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, fur); c.rect(lx, 39, 2, 1, cream) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 36, 2, bottom - 36 + 1, fur)
            c.rect(lx, bottom, 2, 1, cream); c.px(lx + 1, bottom, creamD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail: a fawn plume held up behind her, swaying a little, lit along its near edge.
    let sway = Int((sin(p.lt * 1.3) * 1.2).rounded())
    for y in 17...33 {
        let k = Double(33 - y) / 16
        let cx = 13 - Int((sin(k * 2.2) * 4).rounded()) + (y < 24 ? sway : 0)
        let half = y < 20 ? 2 : 3
        c.rect(cx - half, y, 2 * half + 1, 1, fur)
        c.px(cx - half, y, furL); c.px(cx + half, y, furD)
    }

    // 4. Her body: the fawn fur, lit on top and the left, shaded under and on the far side, then the ginger saddle
    //    over her back, lit along its top.
    c.rect(18, 26, 20, 12, fur)
    c.rect(18, 26, 20, 1, furL); c.rect(18, 26, 1, 12, furL)
    c.rect(37, 26, 1, 12, furD); c.rect(18, 37, 20, 1, furD)
    c.rect(19, 26, 14, 4, saddle); c.rect(19, 26, 14, 1, saddleL)
    // The long fur: a few soft tufts along her back and the bottom of her sides.
    for x in [20, 25, 30, 35] { c.px(x, 25, x < 33 ? saddleL : furL) }
    for (x, y) in [(17, 30), (17, 34), (38, 30)] { c.px(x, y, fur) }

    // 5. The ruff at her chest: cream, full, in a few tufts.
    c.pattern(24, 33, [
        ".CCCCCCCCCC.",
        "CCCcCCCCcCCC",
        "CC.CCC.CCC.C",
    ], ["C": cream, "c": creamD])

    // 6. The near paw: cream.
    c.rect(38, 33, 3, 3, cream); c.rect(38, 35, 3, 1, creamD)

    // 7. The face: the ears small and set wide, the face's own colour (and the blaze, if she has one), big copper
    //    eyes with a black pupil and a glint (shut in bliss while she poses), heavy lids for her unimpressed look, the
    //    small cream muzzle with its pink nose, and a few whiskers.
    c.pattern(17, 23, ["FF..", "FFF.", "FpFF"], ["F": saddle, "p": C(0x8A5A5A)])
    c.pattern(35, 23, ["..FF", ".FFF", "FFpF"], ["F": fur, "p": C(0x8A5A5A)])
    if posing {
        c.rect(21, 30, 3, 1, ink); c.px(21, 29, ink)
        c.rect(32, 30, 3, 1, ink); c.px(34, 29, ink)
    } else {
        for x in [21, 32] {
            c.rect(x, 28, 3, 3, C(0xE0902A)); c.rect(x + 1, 28, 1, 3, ink); c.px(x, 28, C(0xFFF6E0))
            c.rect(x, 27, 3, 1, furD)
        }
    }
    c.pattern(25, 30, [
        ".CCCCC.",
        "CCcNcCC",
        ".CcccC.",
    ], ["C": cream, "c": creamD, "N": nose])
    for y in [31, 33] { c.rect(19, y, 3, 1, C(0xF8F4EC, 0.8)); c.rect(34, y, 3, 1, C(0xF8F4EC, 0.8)) }

    // 8. The crown, small, gold with a pink gem in its front point.
    c.pattern(23, 20, [
        ".g..g..g.",
        ".G..G..G.",
        "GGGGGGGGG",
        "GGGEGGGGG",
        "ggggggggg",
    ], ["G": gold, "g": goldD, "E": gem])
    c.rect(23, 25, 9, 1, fur)   // no see-through row between the crown and her head

    // 9. The signature: a camera flash from the audience (a white star low on the left), then the viewer counter in a
    //    green box floating up over her head and fading.
    if flash {
        let k = sin((s - 0.08) / 0.12 * .pi)
        c.rect(4, 24, 5, 1, C(0xFFFFFF, k)); c.rect(6, 22, 1, 5, C(0xFFFFFF, k)); c.px(6, 24, C(0xFFFFFF))
    }
    if s > 0.22 && s < 0.9 {
        let k = (s - 0.22) / 0.68
        let a = min(1, (1 - k) * 3), y = 12 - Int(k * 6)
        let text = "+10K", w = crawlTextWidth(text)
        let x = 28 - w / 2
        c.rect(x - 2, y - 2, w + 4, 9, C(0x103A1E, a * 0.85))
        crawlText(c, x, y, text, C(0x7AF08A, a))
    }
}

// MARK: - Mongo

/// Mongo's colours: his scaly hide (base, shade, light, belly) under the pink plumage, and the plumage's own tones.
private struct MongoHide {
    var hide: Px, hideD: Px, hideL: Px, belly: Px, bellyD: Px
    var feather: Px, featherD: Px, featherL: Px
    var stripe: Px
}

/// Blue-grey scales with a little green left in them, pink plumage, a red stripe.
private let mongoHide = MongoHide(
    hide: C(0x5E7488), hideD: C(0x42546A), hideL: C(0x7C92A4), belly: C(0xC0C8CC), bellyD: C(0x9CA4AA),
    feather: C(0xF07AB0), featherD: C(0xC0507E), featherL: C(0xFFB0D2), stripe: C(0xC8283A))

/// Mongo: Clawd in a raptor suit, a scaly hide under pink plumage: a crest of plumes on his head, a feathered mane
/// down the back of his neck, a ruff of feathers along his back with a red stripe through it, feathered arms and
/// thighs, and a fan of feathers at the end of his stiff tail. A toothy snout, a fierce orange eye, a black collar
/// with a silver ring, dark claws. He fights with his claws. Signature: he throws his head up and screeches, bobbing
/// it.
private func drawMongo(_ c: PixelCanvas, _ p: Pose) {
    let m = mongoHide
    let claw = C(0x2A2024), tooth = C(0xF4F0E4), mouth = C(0x6A1E2E)
    let collar = C(0x1E1A1E), ring = C(0xC8CCD4)
    let s = p.signature ?? -1
    let screech = s > 0.1 && s < 0.9
    let bob = screech ? Int((abs(sin(s * .pi * 6)) * 2).rounded()) : 0
    var gape = 0
    if let a = p.melee, a > -40 { gape = 2 }
    if screech { gape = 3 }

    // 1. The legs: scaly, feathered at the thigh, dark claws on each foot.
    drawLegs(c, Look(leg: m.hide), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let y = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, 36, 2, 3, m.feather); c.px(lx + 1, 38, m.featherD)
            c.px(lx, 40, m.hideD)
            c.px(lx + 2, y, claw); c.px(lx - 1, y - 2, claw)
        }
    }
    c.oy += p.breathe

    // 2. The tail, held out stiffly behind: scaly underneath, feathered along its top, a fan of plumes at the tip.
    for x in 6...18 {
        let f = Double(18 - x) / 12
        let sway = sin(p.lt * 1.4 + f * 2) * f
        let mid = 31 - f * 4 + sway
        let half = 3.0 - f * 2.2
        let top = Int((mid - half).rounded()), bottom = Int((mid + half).rounded())
        c.rect(x, top, 1, bottom - top + 1, m.hide)
        c.px(x, bottom, m.hideD)
        c.px(x, top, m.feather); if x % 2 == 0 { c.px(x, top - 1, m.featherL) }
    }
    c.pattern(1, 22, [
        "LL.....",
        ".LFF...",
        "..FFFF.",
        "LLFFFFF",
        "..FFDD.",
        ".FDD...",
        "DD.....",
    ], ["L": m.featherL, "F": m.feather, "D": m.featherD])

    // 3. The body: scaly hide, lit on top, scales picked out, the pale belly; over it the ruff of feathers along his
    //    back, scalloped, the red stripe through it.
    drawBody(c, Look(body: m.hide, shade: m.hideD, arm: m.feather, eye: nil))
    c.rect(18, 26, 1, 11, m.hideL)
    for (x, y) in [(21, 31), (25, 32), (29, 31), (33, 32), (23, 29), (31, 29)] { c.px(x, y, m.hideD); c.px(x + 1, y, m.hideL) }
    c.rect(20, 34, 17, 3, m.belly); c.rect(20, 36, 17, 1, m.bellyD)
    c.rect(18, 24, 13, 3, m.feather)
    c.rect(18, 24, 13, 1, m.featherL)
    for x in stride(from: 18, to: 31, by: 3) { c.px(x, 27, m.feather); c.px(x + 1, 27, m.featherD) }
    c.rect(19, 25, 11, 1, m.stripe)

    // 4. The head, held up on its neck over the front of the body and bobbing while he screeches: the scaly neck with
    //    its mane of feathers down the back, the long snout, its teeth, the jaw, the crest, the orange eye.
    let sy = 18 - bob - (screech ? 2 : 0)
    c.rect(30, sy + 4, 8, 27 - sy - 4, m.hide)
    c.rect(29, sy + 3, 3, 27 - sy - 3, m.feather); c.rect(29, sy + 3, 1, 27 - sy - 3, m.featherL)
    for y in stride(from: sy + 4, to: 27, by: 2) { c.px(32, y, m.featherD) }
    c.pattern(30, sy, [
        "...sSSSs..........",
        ".sSSSSSSSSs.......",
        "SSSSSSSSSSSSSSSs..",
        "SSSSSSSSSSSSSSSSSn",
        "SSSSSSSSSSSSSSSSSS",
        "SSSSSSTtTtTtTtTtT.",
    ], ["S": m.hide, "s": m.hideD, "n": ink, "T": tooth, "t": m.hide])
    c.rect(33, sy, 12, 1, m.hideL)
    if gape > 0 { c.rect(36, sy + 6, 11, gape, mouth) }
    c.pattern(30, sy + 6 + gape, ["SSSSSStTtTtTtTt...", "SSSSSSSSSSSSSSs...", "SSSSSBBBBBB......."],
              ["S": m.hide, "s": m.hideD, "t": tooth, "T": m.hide, "B": m.belly])
    // The collar round the base of the neck, its silver ring at the front.
    c.rect(30, 27, 8, 2, collar); c.rect(30, 27, 8, 1, C(0x3A343A)); c.px(37, 28, ring); c.px(36, 29, ring)
    // The crest: plumes swept back from the brow, red at their roots.
    c.pattern(25, sy - 4, [
        "LL..........",
        ".LLL.L......",
        "..LFFFLL....",
        "...RFFFFFF..",
        "....RRRRRR..",
    ], ["L": m.featherL, "F": m.feather, "R": m.stripe])
    // The eye: orange, a black slit, under a heavy brow.
    c.rect(36, sy + 2, 3, 2, C(0xF0901E)); c.px(37, sy + 2, ink); c.px(37, sy + 3, ink)
    c.rect(35, sy + 1, 5, 1, m.hideD)
    // The screech: sound lines from the open jaws.
    if screech, Int(p.lt * 10) % 3 != 0 {
        for i in 0..<3 {
            let x = 50 + i * 2
            c.px(x, sy + 4 - i, C(0xFFFFFF, 0.8)); c.px(x + 1, sy + 5 - i, C(0xFFFFFF, 0.8))
            c.px(x, sy + 7 + i, C(0xFFFFFF, 0.8)); c.px(x + 1, sy + 6 + i, C(0xFFFFFF, 0.8))
        }
    }

    // 5. The little arm, feathered pink, claws out when he slashes.
    if let a = p.melee {
        for (i, ta) in p.trail.enumerated() {
            crawlTalons(c, crawlReach((38, 34), ta, 4), angle: ta, len: 4, C(0xF8E0EC), alpha: 0.35 / Double(i + 1))
        }
        crawlBar(c, (38, 34), a, from: 0, to: 4, m.feather, r: 1.1)
        crawlTalons(c, crawlReach((38, 34), a, 4), angle: a, len: 3.5, claw)
    } else {
        c.rect(38, 33, 3, 2, m.feather); c.px(38, 33, m.featherL); c.px(38, 35, m.featherD)
        crawlTalons(c, (40.5, 34.5), angle: 80, len: 2.5, claw)
    }
}
