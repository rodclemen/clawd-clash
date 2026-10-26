import Foundation

// Heroes: the Royal Palace's household and Greyskull's guardian. Prince Addam is He-Clawd before the sword comes out,
// so he keeps the same blond pageboy on paler skin, in the palace's pink and lavender. Battle Kat and Cringer are one
// green tiger in two moods, drawn by the same function: Clawd's block in striped fur with a cat's face on its front,
// a haunch behind and a tail, on Clawd's own four legs. Teelah, Man-At-Clawds and the Sorceress are Clawd in costume.

let eterniaHeroes2: [EterniaHero: Persona] = [
    .princeAddam: Persona(name: "Prince Addam", headTop: 21, signature: 3.6, callout: "By the power of Greyskull!",
                          draw: drawAddam),
    .battleKat: Persona(name: "Battle Kat", weapon: .saber, bulk: 3, headTop: 19, signature: 3.2, callout: "Rrrowr!",
                        draw: { c, p in drawKat(c, p, battle: true) }),
    .cringer: Persona(name: "Cringer", headTop: 26, signature: 3.4, callout: "Do I have to?",
                      draw: { c, p in drawKat(c, p, battle: false) }),
    .teelah: Persona(name: "Teelah", weapon: .saber, headTop: 15, signature: 3.0, callout: "Where's Addam?",
                     draw: drawTeelah),
    .manAtClawds: Persona(name: "Man-At-Clawds", weapon: .saber, headTop: 19, signature: 3.4, callout: "Leave it to me.",
                          draw: drawManAtClawds),
    .sorceress: Persona(name: "The Sorceress of Greyskull", weapon: .lightning,
                        magic: Magic(core: C(0xFFFFFF), glow: C(0x6AC0FF), jagged: false),
                        headTop: 14, signature: 4.2, callout: "Hurry, He-Clawd!", draw: drawSorceress),
]

/// 0…1 easing in over `a…b` and back out over `c…d` of a signature's run (0 before and after).
private func eterniaRamp(_ s: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
    if s < a || s > d { return 0 }
    if s < b { return (s - a) / (b - a) }
    if s > c { return (d - s) / (d - c) }
    return 1
}

// MARK: - Prince Addam

/// Prince Addam: He-Clawd's other self, the idle prince of Eternia. The same blond pageboy as He-Clawd, but on paler
/// skin, with no harness, no fur and no bracers: a pink vest open over a lavender shirt with full sleeves, a brown belt
/// with a little gold buckle, lavender tights and soft tan boots. He carries nothing. Signature: he yawns and
/// stretches, both arms up and his eyes screwed shut, and while he does, the hilt of the Power Sword rises into view
/// over his back, until he catches it and it drops out of sight again.
private func drawAddam(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEAA286), skinD = C(0xC8826A), skinL = C(0xF6BCA2)
    let hair = C(0xE8C25A), hairD = C(0xB88E32), hairL = C(0xFFE48E)
    let vest = C(0xE070A0), vestD = C(0xB04E7A), vestL = C(0xF496BE)
    let lav = C(0xB49ADC), lavD = C(0x8E76BA), lavL = C(0xD0BCF0)
    let boot = C(0x9A6A40), bootD = C(0x6E4828), bootL = C(0xBA8A5A), belt = C(0x5A3A22), gold = C(0xE0B040)
    let s = p.signature ?? -1
    let stretch = eterniaRamp(s, 0.05, 0.2, 0.75, 0.88)
    let up = Int((stretch * 8).rounded())
    let yawn = s > 0.22 && s < 0.74
    // The sword peeks up from 0.3, and drops back fast when he notices, at 0.78.
    let peek = s > 0.3 && s < 0.78 ? min(1, (s - 0.3) / 0.25) : s >= 0.78 && s < 0.82 ? (0.82 - s) / 0.04 : 0

    drawLegs(c, Look(leg: lav), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 3, boot)
            c.rect(lx, bottom - 2, 2, 1, bootL); c.px(lx + 1, bottom, bootD)
        }
        for lx in [19, 23, 31, 35] { c.px(lx + 1, 38, lavD) }   // the tights shaded on the far side
    }
    c.oy += p.breathe

    // The Power Sword, hidden behind him: only its hilt ever shows, rising over the back of his head.
    if peek > 0 {
        let top = 24 - Int((peek * 8).rounded())
        c.rect(14, top, 2, 2, gold); c.px(14, top, C(0xFFE08A))
        c.rect(14, top + 2, 2, 5, C(0x5A4A6A)); c.px(14, top + 2, C(0x7A6A8A))
        c.rect(12, top + 7, 6, 1, C(0xE2E4EC)); c.rect(16, top + 7, 2, 1, C(0x7E8290))
    }

    drawBody(c, Look(body: skin, shade: skinD, arm: lav, eye: nil))
    c.px(18, 27, skinL); c.px(19, 26, skinL)
    // Eyes: open, or screwed shut in a yawn.
    if yawn {
        c.rect(22, 30, 2, 1, ink); c.rect(32, 30, 2, 1, ink); c.px(21, 29, ink); c.px(34, 29, ink)
        // The yawn: a wide-open mouth, a pink tongue in it.
        c.pattern(25, 31, [".KKKKK.", "KKkkkKK", ".KKKKK."], ["K": C(0x3A1418), "k": C(0xD86A80)])
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }

    // The lavender shirt, its full sleeves gathered at the cuff.
    c.rect(18, 33, 20, 4, lav)
    c.rect(15, 33, 3, 3, lav); c.rect(15, 35, 3, 1, lavD); c.px(15, 33, lavL)
    c.rect(38, 33, 3, 3, lav); c.rect(38, 35, 3, 1, lavD); c.px(38, 33, lavL)
    // The pink vest, open down the front, lit on its left edge and shaded on the far side, the shirt in the gap.
    c.rect(18, 33, 20, 4, vest)
    c.rect(18, 33, 1, 4, vestL); c.rect(19, 33, 6, 1, vestL)
    c.rect(36, 33, 2, 4, vestD)
    // The V of the shirt down the front, narrowing to the belt, the vest's edges shaded along it.
    c.pattern(25, 33, ["DllllD", ".DllD.", "..DD.."], ["l": lav, "D": vestD])
    c.px(27, 33, lavL)
    // The belt, the little gold buckle.
    c.rect(18, 36, 20, 1, belt); c.rect(27, 36, 2, 1, gold)

    // The pageboy, the same cut as He-Clawd's, a shade neater at the fringe.
    c.pattern(16, 21, [
        ".....HHHHHlHHHHHH......",
        "...HHHlHHHHHlHHHHHH....",
        "..HHhHHHHhHHHHHhHHHHH..",
        ".HHHhHHlHhHHHHHhHHHhHH.",
        "HHHHhHHHHhHHHhHHhHHhHHH",
        "HHHHHhHHHHhHHhHHHhHHhHH",
        "HHh.hHHhHHhHHhHHhHHH.HH",
        "HHh..................HH",
        "HHh..................hH",
        ".Hh..................h.",
        ".h....................h",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // The stretch: both arms straight up past his hair, the sleeves running down to the shoulders, the hands open.
    if up > 0 {
        for x in [15, 38] {
            c.rect(x, 33 - up, 3, up + 1, lav); c.rect(x, 33 - up, 1, up + 1, lavL); c.rect(x + 2, 33 - up, 1, up + 1, lavD)
            c.rect(x, 31 - up, 3, 2, skin); c.px(x + 1, 30 - up, skin); c.px(x, 31 - up, skinL)
        }
    }
}

// MARK: - Battle Kat and Cringer

/// Battle Kat and Cringer, one tiger in two moods. Green fur with orange stripes on the back, the haunch and the tail,
/// a pale muzzle with a pink nose and whiskers on the front of the face. Cringer wears nothing, his ears lie flat, his
/// brows are knotted with worry and his tail hangs to the ground. Battle Kat is a head taller and broader, his ears
/// up, a red helmet over his brow with a nose guard down between his eyes, a red saddle with gold trim on his back
/// and his tail up; he fights with his claws, a swipe of his paw. Signatures: Battle Kat rears up on his back legs,
/// paw high and claws out, and roars; Cringer covers his eyes with both paws and trembles, a bead of sweat on his
/// brow.
private func drawKat(_ c: PixelCanvas, _ p: Pose, battle: Bool) {
    let rear = battle ? eterniaRamp(p.signature ?? -1, 0.05, 0.25, 0.8, 0.95) : 0
    katArt(c, p, battle: battle, rise: Int((rear * 4).rounded()))
}

/// The tiger itself. `rise`: how far he's reared up (0 standing): his body lifts, level, on his stretched back legs,
/// the front legs fold up off the ground and the front paw goes up high, claws out. The body stays square, so its
/// edges stay clean instead of stepping.
private func katArt(_ c: PixelCanvas, _ p: Pose, battle: Bool, rise: Int) {
    let fur = C(0x5E9E3A), furD = C(0x3E7426), furL = C(0x86C25A)
    let stripe = C(0xE8862A), stripeD = C(0xB45E1A)
    let muz = C(0xDCE4A4), muzD = C(0xB0BA78), nose = C(0xE86A8A)
    let red = C(0xC8302A), redD = C(0x8A1E1A), redL = C(0xE8584A), gold = C(0xE0B040)
    let s = p.signature ?? -1
    let rearing = rise > 0
    let roar = battle && s > 0.3 && s < 0.78
    let cower = battle ? 0 : eterniaRamp(s, 0.05, 0.15, 0.85, 0.95)
    let hide = cower > 0.5
    let shake = hide && Int(p.lt * 24) % 2 == 0 ? 1 : 0
    c.ox += shake
    let top = battle ? 24 : 26

    // The legs: Clawd's four, in striped green fur, pale paws. Rearing, the back legs stretch up to his lifted body
    // and the front pair fold up under it, off the ground.
    if seatedPose {
        drawLegs(c, Look(leg: fur), step: p.step)
        for lx in [19, 23, 31, 35] { c.rect(lx + 1, 38, 2, 2, muz) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let lifted = p.step >= 0 && i % 2 == p.step && !rearing
            let front = i >= 2
            let y0 = 36 - rise
            let bottom = front && rearing ? 40 - rise : (lifted ? 42 : 43)
            c.rect(lx, y0, 2, bottom - y0 + 1, fur)
            c.px(lx + 1, y0, furD)
            if front && rearing {
                // Folded up under him, the paw tucked forward, its pale toes showing.
                c.rect(lx + 1, bottom - 1, 2, 2, muz); c.px(lx + 2, bottom, muzD)
            } else {
                c.rect(lx, bottom - 1, 2, 2, muz); c.px(lx + 1, bottom, muzD)
            }
            if !front { c.px(lx, 39, stripe); if rise > 2 { c.px(lx, 37 - rise, stripe) } }   // stripes round the back legs
        }
    }
    c.oy += p.breathe - rise

    // The tail: Battle Kat's curling up behind him, Cringer's hanging limp to the ground; ringed in orange.
    if battle {
        c.pattern(5, 18, [
            ".TT....",
            "TOTT...",
            "TT.....",
            "OT.....",
            "TT.....",
            ".TO....",
            ".TTT...",
            "..OTT..",
            "...TTT.",
            "....TOT",
            ".....TT",
        ], ["T": fur, "O": stripe])
    } else {
        c.pattern(7, 30, [
            ".....TT",
            "....TTO",
            "...TT..",
            "..OT...",
            "..TT...",
            ".TT....",
            ".OT....",
            ".TT....",
            "TT.....",
            "OT.....",
            "TTT....",
        ].prefix(max(0, 43 - c.oy - 30 + 1)).map { $0 }, ["T": fur, "O": stripe])
    }

    // The haunch behind the block: a round rump, its back edge curving in smoothly at the top and the bottom, lit
    // along the top and shaded underneath, stripes down it.
    for y in (top + 2)...37 {
        let fromTop = y - top - 2, fromBottom = 37 - y
        let x0 = fromTop == 0 ? 13 : fromTop == 1 ? 11 : fromBottom == 0 ? 12 : fromBottom == 1 ? 11 : 10
        c.rect(x0, y, 18 - x0, 1, fur)
        c.px(x0, y, fromTop <= 1 ? furL : y > 33 ? furD : fur)
    }
    c.rect(13, top + 2, 5, 1, furL); c.rect(12, 37, 6, 1, furD)
    for x in [12, 15] { c.rect(x, top + 3, 1, 3, stripe); c.px(x, top + 6, stripeD) }
    for x in [11, 16] where battle { c.rect(x, 32, 1, 2, stripe) }   // below the saddle cloth

    // The block: green fur, lit on top and the left, shaded under and on the right, its pale belly.
    c.rect(18, top, 20, 38 - top, fur)
    c.rect(18, top, 20, 1, furL); c.rect(18, top, 1, 38 - top, furL)
    c.rect(37, top, 1, 38 - top, furD); c.rect(18, 37, 20, 1, furD)
    c.rect(20, 36, 16, 1, muzD)
    // Stripes down his sides, and three short ones across the brow.
    for x in [20, 35] { c.rect(x, 33, 1, 3, stripe); c.px(x, 32, stripeD) }
    for x in [24, 27, 30] where !battle { c.rect(x, top + 1, 2, 1, stripe); c.px(x, top + 2, stripeD) }

    // The ears: up, through the helmet, or flat out to the sides.
    do {
        if battle {
            c.pattern(18, top - 4, ["GG..............GG", "GpG............GpG", "GGGG..........GGGG", "GGGG..........GGGG"],
                      ["G": fur, "p": nose])
        } else {
            c.pattern(14, top + 1, ["GGGG", ".GGG", "...G"], ["G": furD])
            c.pattern(38, top + 1, ["GGGG", "GGG.", "G..."], ["G": furD])
            c.px(15, top + 1, furL); c.px(40, top + 1, furL)
        }
    }

    // The face: Clawd's eyes, the brows over them (fierce or worried), the pale muzzle, the pink nose, the whiskers.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(22, 29, C(0xF4F4E8)); c.px(32, 29, C(0xF4F4E8))
    if battle {
        c.pattern(21, 27, ["KK.", ".KK"], ["K": furD]); c.pattern(32, 27, [".KK", "KK."], ["K": furD])
    } else {
        c.pattern(21, 27, [".KK", "KK."], ["K": furD]); c.pattern(32, 27, ["KK.", ".KK"], ["K": furD])
    }
    if roar {
        c.pattern(24, 31, [
            ".MMMMMMM.",
            "MMMNNMMMM",
            "MWkkkkkWM",
            "MkkrrrkkM",
            "MWkkkkkWM",
            ".MMMMMMM.",
        ], ["M": muz, "N": nose, "k": C(0x3A1012), "r": C(0xA83040), "W": C(0xF8F6EC)])
        // The roar's sound lines, shaking out ahead of him.
        for i in 0..<3 where Int(p.lt * 12 + Double(i)) % 3 != 0 {
            let r = 6.0 + Double(i) * 4
            for k in -2...2 {
                let a = Double(k) * 0.28
                let x = 36 + cos(a) * r, y = 33 + sin(a) * r
                c.px(Int(x), Int(y), C(0xFFFFFF, 0.85 - Double(i) * 0.2))
            }
        }
    } else {
        c.pattern(24, 31, [
            ".MMMMMMM.",
            "MMMNNMMMM",
            "MMMMkMMMM",
            ".MkkMkkM.",
        ], ["M": muz, "N": nose, "k": muzD])
        c.rect(27, 32, 2, 1, nose)
    }
    for y in [32, 34] {
        c.rect(19, y, 4, 1, C(0xF4F4E8, 0.85)); c.rect(34, y, 4, 1, C(0xF4F4E8, 0.85))
    }

    if battle {
        // The red helmet: a cap over his brow, a ridge lit down its middle, guards down his cheeks and a nose guard
        // between his eyes, gold studs along its rim.
        c.rect(18, top, 20, 3, red)
        c.rect(18, top, 20, 1, redL); c.rect(37, top, 1, 3, redD)
        c.rect(18, top + 3, 2, 4, red); c.rect(36, top + 3, 2, 4, redD)
        c.rect(27, top + 3, 2, 4, red); c.px(27, top + 3, redL); c.px(28, top + 6, redD)
        c.rect(27, top - 1, 2, 1, redL)
        for x in [20, 24, 31, 35] { c.px(x, top + 2, gold) }
        // The saddle on his back, big enough to ride: a high cantle behind and a pommel in front, both capped in
        // gold, the seat dipping between them, a red saddle cloth hanging down his side bordered in gold, and the
        // stirrup on its strap below it.
        c.pattern(9, top - 3, [
            "LR........",
            "RRr.....LR",
            "RRRrrrrrRr",
            ".RRRRRRRRr",
            ".RRRRRRRRr",
            ".RrRRRRrRr",
            ".RrRRRRrRr",
            "..RrRRrRr.",
            "..gGGGGGg.",
            "...gGGGg..",
        ], ["R": red, "r": redD, "L": redL, "g": C(0xFFE08A), "G": gold])
        c.rect(11, top, 7, 1, redL)
        c.px(13, top + 3, gold); c.px(17, top + 3, gold)   // studs on the cloth
        c.rect(14, top + 7, 2, 34 - top - 7, C(0x5A3A1A))
        c.pattern(12, 34, ["GGGGGG", "G....G", "GGGGGG"], ["G": gold])
    }

    // The front paw: at rest, a pale-toed paw; swiping, his paw on its foreleg, claws out; rearing, up high.
    let paw: (x: Double, y: Double)
    if let a = p.melee {
        for (i, t) in p.trail.enumerated() {
            let e = eterniaReach((38.5, 33.5), t, 7)
            for k in [-1.5, 0.0, 1.5] {
                let r = t * .pi / 180
                let nx = -sin(r) * k, ny = cos(r) * k
                c.glowLine(e.x + nx - cos(r) * 2, e.y + ny - sin(r) * 2, e.x + nx + cos(r) * 2, e.y + ny + sin(r) * 2,
                           core: C(0xFFFFFF, 0.5 / Double(i + 1)), glow: C(0xF8C070, 0.3 / Double(i + 1)), coreR: 0.3, glowR: 1)
            }
        }
        eterniaBar(c, (38.5, 33.5), a, from: 0, to: 5, fur, r: 1.3)
        paw = eterniaReach((38.5, 33.5), a, 6)
    } else if rearing {
        c.rect(38, 28, 3, 7, fur); c.rect(38, 28, 1, 7, furL)
        paw = (40, 27)
    } else {
        paw = (39.5, 34.5)
    }
    if hide {
        // Cringer's paws over his eyes, the toes parted, a bead of sweat on his brow.
        // His forelegs, up from his sides to his face, a dark edge under each.
        c.glowLine(16.5, 35.5, 21.5, 32.5, core: furD, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
        c.glowLine(39.5, 35.5, 34.5, 32.5, core: furD, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
        c.glowLine(16.5, 34.5, 21.5, 31.5, core: furL, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
        c.glowLine(39.5, 34.5, 34.5, 31.5, core: furL, glow: C(0, 0), coreR: 1.1, glowR: 1.2)
        // Shivers either side of him.
        for (x, y) in [(10, 26), (9, 29), (44, 26), (45, 29)] where shake == 1 { c.rect(x, y, 2, 1, C(0xFFFFFF, 0.7)) }
        // The paws themselves, backs to us: green fur at the wrist, then the pale paw, its four toes bumping up
        // along the top with short creases between them, so it reads as a paw and not a pad.
        for x in [18, 30] {
            c.pattern(x, 26, [
                "TT.TT.TT",
                "TTtTTtTT",
                "TTtTTtTT",
                "TTTTTTTt",
                "dTTTTTtd",
                ".FFFFFF.",
                ".FfFFfF.",
            ], ["T": muz, "t": muzD, "d": furD, "F": fur, "f": furD])
        }
        c.px(37, 26, C(0x9AD8FF)); c.px(37, 27, C(0x9AD8FF)); c.px(36, 27, C(0xD8F0FF))
    } else {
        let px0 = Int(paw.x.rounded()) - 1, py0 = Int(paw.y.rounded()) - 1
        c.rect(px0, py0, 3, 3, fur); c.rect(px0, py0 + 2, 3, 1, muz)
        if p.melee != nil || rearing { for y in [py0, py0 + 2] { c.px(px0 + 3, y, C(0xFAFAF0)) } }
    }
    if !battle && cower > 0 && !hide {
        c.px(37, 26, C(0x9AD8FF))
    }
}

// MARK: - Teelah

/// Teelah: Captain of the Guard. Auburn hair swept back off her brow into a long ponytail that swings behind her, the
/// gold snake-crest headpiece across her brow with a hooded cobra rising from its middle, a red eye in it; a white
/// leotard with a gold collar plate and a gold belt, gold bracers, bare legs and white boots with gold cuffs. She
/// fights with a long dark staff capped in gold at both ends, held upright beside her at rest. Signature: she twirls
/// the staff round in her fist, faster and faster, then plants it on the ground with a thump and a puff of dust.
private func drawTeelah(_ c: PixelCanvas, _ p: Pose) {
    let hair = C(0xB04A28), hairD = C(0x7E2E18), hairL = C(0xD8683A)
    let white = C(0xF4F4F8), whiteD = C(0xC4C8D8), gold = C(0xE0B040), goldD = C(0x9A7420), goldL = C(0xFFE08A)
    let wood = C(0x5A3A2A), woodL = C(0x7A5640)
    let s = p.signature ?? -1
    let twirl = s > 0.05 && s < 0.68 ? (s - 0.05) / 0.63 : -1
    let planted = s >= 0.68 ? s : -1

    drawLegs(c, Look(), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 4, white); c.rect(lx, bottom - 3, 2, 1, gold); c.px(lx + 1, bottom, whiteD)
        }
    }
    c.oy += p.breathe

    // The ponytail: from the back of her crown out behind her and down in strands, swinging.
    let sway = Int((sin(p.t * 2.2) * 1.2).rounded())
    c.pattern(9 + sway, 22, [
        "....hHHHHH",
        "..HHHHlHHH",
        ".HHhHHHh..",
        "HHhHHh....",
        "HhHHh.....",
        "HhHh......",
        ".hHh......",
        ".Hh.......",
        "..h.......",
    ], ["H": hair, "h": hairD, "l": hairL])

    drawBody(c, Look(eye: ink), armRight: twirl >= 0 ? 0 : p.armRaise)
    c.px(18, 26, C(0xE8906E)); c.px(19, 26, C(0xE8906E))

    // The leotard: white, shaded on the far side, a gold collar plate, a gold belt.
    c.rect(18, 33, 20, 5, white); c.rect(36, 33, 2, 5, whiteD); c.rect(18, 37, 20, 1, whiteD)
    c.rect(19, 33, 18, 1, gold); c.rect(19, 33, 6, 1, goldL); c.rect(33, 33, 3, 1, goldD)
    c.pattern(26, 34, ["gGGg", ".gg."], ["G": gold, "g": goldD])   // a little pendant at the collar's middle
    c.rect(18, 36, 20, 1, gold); c.rect(26, 36, 4, 1, goldD); c.px(27, 36, goldL)
    c.rect(15, 35, 3, 1, gold)   // the bracer on her back arm

    // Her hair: swept back over the crown in strands, a lit run along the top, down behind her ears.
    c.pattern(17, 20, [
        "......HHHHHHHHHH.....",
        "...HHHHlHHHHlHHHHH...",
        ".HHHhHHHHhHHHHhHHHHH.",
        "HHHHHhHHHHhHHHHhHHHHH",
        "HHh.................H",
        "Hh..................h",
        "H...................h",
    ], ["H": hair, "h": hairD, "l": hairL])
    // The snake-crest headpiece: a gold band across her brow, and the hooded cobra rising from its middle.
    c.rect(18, 24, 20, 2, gold); c.rect(18, 24, 20, 1, goldL); c.rect(36, 24, 2, 2, goldD)
    c.pattern(24, 15, [
        "..GGGG..",
        ".GlGGGG.",
        ".GrGGrG.",
        "..GggG..",
        ".GGggGG.",
        "GlgGGgGG",
        "GGgGGgGg",
        ".GGggGg.",
        "..GGGG..",
    ], ["G": gold, "g": goldD, "l": goldL, "r": C(0xD02A2A)])
    c.rect(22, 27, 2, 1, hairD); c.rect(32, 27, 2, 1, hairD)   // her brows

    // The staff.
    let hand = (x: 41.5, y: 34.5 - Double(twirl >= 0 ? 0 : p.armRaise))
    func staff(_ a: Double, from: Double, to: Double) {
        eterniaBar(c, hand, a, from: from, to: to, wood, r: 0.9)
        eterniaBar(c, hand, a, from: from + 1, to: to - 1, woodL, r: 0.3)
        for d in [from, to] {
            let q = eterniaReach(hand, a, d)
            c.rect(Int(q.x.rounded()) - 1, Int(q.y.rounded()) - 1, 2, 2, gold)
        }
    }
    if twirl >= 0 {
        // Twirling round her fist, two turns and a half and gathering speed, a smear behind it.
        let a = -90 + twirl * twirl * 900
        for k in 1...2 {
            let t = max(0, twirl - Double(k) * 0.02)
            let b = -90 + t * t * 900
            for sgn in [1.0, -1.0] {
                let e0 = eterniaReach(hand, b, 3 * sgn), e1 = eterniaReach(hand, b, 9 * sgn)
                c.glowLine(e0.x, e0.y, e1.x, e1.y, core: C(0xF0E8D0), glow: C(0xF0E8D0), coreR: 0.5, glowR: 1.4,
                           strength: 0.35 / Double(k))
            }
        }
        staff(a, from: -9, to: 9)
    } else if let a = p.melee {
        for (i, t) in p.trail.enumerated() {
            let e0 = eterniaReach(hand, t, 3), e1 = eterniaReach(hand, t, 15)
            c.glowLine(e0.x, e0.y, e1.x, e1.y, core: C(0xF0E8D0), glow: C(0xF0E8D0), coreR: 0.5, glowR: 1.6,
                       strength: 0.3 / Double(i + 1))
        }
        staff(a, from: -7, to: 15)
    } else {
        // Upright beside her, its foot on the ground.
        let foot = seatedPose ? 39.0 : 42.5
        let upAt = hand.y - 16
        staff(-90, from: -(foot - hand.y), to: hand.y - upAt)
        if planted >= 0 && planted < 0.8 && !seatedPose {
            // The thump: a puff of dust round the staff's foot.
            let k = (planted - 0.68) / 0.12
            for (dx, dy) in [(-3.0, 0.0), (3.0, 0.0), (-2.0, -1.0), (2.0, -1.0)] {
                let x = 41.5 + dx * (1 + k), y = 43 + dy * (1 + k) - Double(p.breathe)
                c.glowLine(x, y, x, y, core: C(0xE8DCC0, 0.7 * (1 - k)), glow: C(0xE8DCC0, 0), coreR: 0.7, glowR: 0.8)
            }
        }
    }
    let f = (x: Int(hand.x.rounded()) - 1, y: Int(hand.y.rounded()) - 1)
    c.rect(f.x, f.y, 3, 3, clawdOrange); c.rect(f.x - 1, f.y + 1, 1, 2, gold)   // her fist, its gold bracer
}

// MARK: - Man-At-Clawds

/// Man-At-Clawds: the royal armourer, master of arms. A bushy brown moustache drooping at its ends, an amber-orange
/// helmet with a ridge over the crown, a dark rim and guards down over his ears; a green suit under orange armour: a
/// riveted chest plate, gauntlets on both wrists, orange boots. He fights with a steel mace, flanged, on a dark haft.
/// Signature: he pulls a spanner from his belt and tinkers with the gauntlet on his raised arm, sparks jumping off it.
private func drawManAtClawds(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x4E8A3A), greenD = C(0x346628), greenL = C(0x6AAA4E)
    let arm = C(0xE08A2A), armD = C(0xA85E18), armL = C(0xF4AE50)
    let helm = C(0xE8A030), helmD = C(0xB0701C), helmL = C(0xFFCA6A), rim = C(0x6A3E18)
    let tache = C(0x6A3A1A), tacheL = C(0x8E5630), steel = C(0xB4B8C4), steelD = C(0x7E8290), steelL = C(0xE2E4EC)
    let s = p.signature ?? -1
    let tinker = eterniaRamp(s, 0.05, 0.18, 0.85, 0.95)
    let raise = Int((tinker * 6).rounded())
    let working = s > 0.2 && s < 0.84

    drawLegs(c, Look(leg: green), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 3, arm); c.rect(lx, bottom - 2, 2, 1, armL); c.px(lx + 1, bottom, armD)
            c.px(lx + 1, bottom - 4, greenD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: green), armRight: raise)

    // The suit below his face, and the chest plate on it: lit along the top, a seam down the middle, four rivets.
    c.rect(18, 33, 20, 5, green); c.rect(18, 33, 1, 5, greenL); c.rect(36, 33, 2, 5, greenD)
    c.rect(19, 34, 17, 3, arm); c.rect(19, 34, 17, 1, armL); c.rect(34, 35, 2, 2, armD)
    c.px(27, 35, armD); c.px(27, 36, armD)
    for x in [21, 25, 30, 33] { c.px(x, 35, armD) }
    c.rect(18, 37, 20, 1, C(0x4A2E18)); c.rect(26, 37, 3, 1, steel)   // the belt and its buckle
    // The gauntlets.
    c.rect(15, 34, 3, 2, arm); c.px(15, 34, armL)
    c.rect(38, 34 - raise, 3, 2, arm); c.px(38, 34 - raise, armL); c.px(40, 35 - raise, armD)

    // The moustache: bushy across under his eyes, drooping down at both ends.
    c.pattern(23, 32, ["..TTTTTT..", ".TTlTTlTT.", "TT......TT", "T........T"], ["T": tache, "l": tacheL])

    // The helmet: an amber dome with a ridge, a dark rim over the brow, and guards down over his ears.
    c.pattern(16, 19, [
        "........RRRR........",
        ".....HHHLLHHHHH.....",
        "...HHHLHHLHHHHHHH...",
        "..HHLHHHHLHHHHHHHd..",
        ".HHLHHHHHLHHHHHHHdd.",
        ".HLHHHHHHLHHHHHHHHd.",
        "rrrrrrrrrrrrrrrrrrrr",
        "HHHr............rHHd",
        "HHHr............rHdd",
        "HLHr............rHHd",
        "HHH..............Hdd",
        ".HH..............Hd.",
        ".hH..............hd.",
    ], ["H": helm, "L": helmL, "d": helmD, "h": helmD, "r": rim, "R": helmL])
    c.px(17, 26, helmL)
    for x in [19, 27, 35] { c.px(x, 25, helmL) }   // studs on the rim
    c.rect(22, 28, 2, 1, tache); c.rect(32, 28, 2, 1, tache)   // brows

    if working {
        // The spanner, worked against the raised gauntlet. A big steel nut on the gauntlet's front, out in the clear
        // past his wrist; the spanner's open jaw round it, mid-grey steel lit along the top so it doesn't fade into
        // the white outline; its handle running down to his other hand at his chest, edged in dark where it crosses
        // his arm; and sparks jumping up off the nut as he turns it.
        let gy = 34 - raise
        c.rect(41, gy, 2, 2, steelD); c.px(41, gy, steelL)   // the nut
        c.glowLine(44, Double(gy) + 4, 33, 37.2, core: C(0x2E2A30), glow: C(0, 0), coreR: 1.25, glowR: 1.3)
        c.glowLine(44, Double(gy) + 3.5, 33, 36.7, core: steel, glow: C(0, 0), coreR: 0.75, glowR: 0.8)
        c.glowLine(44, Double(gy) + 3, 34, 36, core: steelL, glow: C(0, 0), coreR: 0.25, glowR: 0.3)
        c.pattern(41, gy - 2, [
            ".LLSS.",
            "SSSSSd",
            "...SSd",
            "...SSd",
            "SSSSSd",
            ".dddd.",
        ], ["S": steel, "d": steelD, "L": steelL])
        c.rect(31, 35, 3, 3, clawdOrange); c.px(33, 37, clawdShade)   // his other hand on the spanner
        if Int(p.t * 9) % 3 != 0 {
            // The sparks fly up and out past the jaw, clear of his helmet.
            let seed = Int(p.t * 9)
            let nut = (x: 45.5, y: Double(gy) - 2.5)
            for k in 0..<3 {
                let a = -95 + noise(seed * 7 + k) * 75
                let d = 2 + noise(seed * 3 + k) * 3
                let e = eterniaReach(nut, a, d)
                c.glowLine(nut.x, nut.y, e.x, e.y, core: C(0xFFF6C0), glow: C(0xFFB030, 0.6), coreR: 0.35, glowR: 1)
            }
        }
        return
    }

    // The mace: a dark haft, a steel head with its flanges, a spike on top. At rest it hangs forward from his fist.
    let a = p.melee ?? (seatedPose ? 20 : 55)
    let h = eterniaHand
    for (i, t) in (p.melee == nil ? [] : p.trail).enumerated() {
        let e0 = eterniaReach(h, t, 6), e1 = eterniaReach(h, t, 12)
        c.glowLine(e0.x, e0.y, e1.x, e1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.8, glowR: 2.2, strength: 0.3 / Double(i + 1))
    }
    eterniaBar(c, h, a, from: -2, to: 7, C(0x4A2E1A), r: 0.7)
    let head = eterniaReach(h, a, 9)
    let n = (x: -sin(a * .pi / 180), y: cos(a * .pi / 180))
    c.glowLine(head.x + n.x * 2.2, head.y + n.y * 2.2, head.x - n.x * 2.2, head.y - n.y * 2.2, core: steelD, glow: C(0, 0),
               coreR: 0.9, glowR: 1)
    eterniaBar(c, h, a, from: 7, to: 11, steel, r: 1.5)
    eterniaBar(c, h, a, from: 7.5, to: 10.5, steelL, r: 0.4)
    eterniaBar(c, h, a, from: 11, to: 12.5, steelD, r: 0.5)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, arm); c.px(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, armL)
}

// MARK: - The Sorceress of Greyskull

/// The feathered fan of a wing from `root`: `n` feathers between `a0` and `a1` degrees, white with sky-blue tips, the
/// longest in the middle.
private func eterniaWing(_ c: PixelCanvas, root: (x: Double, y: Double), a0: Double, a1: Double, length: Double,
                         white: Px, shade: Px, tip: Px) {
    let n = 6
    for i in 0..<n {
        let f = Double(i) / Double(n - 1)
        let a = a0 + (a1 - a0) * f
        let len = length * (0.75 + 0.25 * sin(f * .pi))
        eterniaBar(c, root, a, from: 0, to: len, i % 2 == 0 ? white : shade, r: 1.2)
        eterniaBar(c, root, a, from: len - 3, to: len, tip, r: 0.9)
    }
}

/// The Sorceress's great wing folded down her back: its bend standing up behind her shoulder, a row of short covert
/// feathers, then the long flight feathers hanging in strokes to her heels, tipped in sky blue. Its back edge is sky
/// blue all the way down and the seams between the feathers a cool grey-blue, so the white wing keeps its shape inside
/// the white outline.
private func sorceressFoldedWing(_ c: PixelCanvas, white: Px, light: Px, tip: Px) {
    c.pattern(8, 21, [
        "....LWW...",
        "..BLWWWWW.",
        ".BWWWWWWWW",
        ".BWWsWWsWW",
        "BWWsWWsWWs",
        "BWWWWWWWWW",
        "BWsWsWsWsW",
        "BWsWsWsWsW",
        "BWsWsWsWsW",
        "BWsWsWsWsW",
        "BWsWsWsWsW",
        ".BsWsWsWsW",
        ".BsWsWsWsW",
        ".BsWsWsWsW",
        ".BsBsWsWsW",
        "..BBsBsWsW",
        "...BBsBsBs",
        "....BBBBB.",
    ], ["W": white, "L": light, "s": C(0x98AACA), "B": tip])
}

/// The Sorceress of Greyskull: the guardian of the castle's secrets, in Zoar's feathers. A white falcon headdress with
/// a gold hooked beak over her brow, the falcon's dark eyes above it and little feathered wings sweeping up either
/// side; a white feathered bodice with a sky-blue gem at its middle, a skirt of white feathers tipped in blue, pale
/// blue legs, and her great white wings folded down her back. Her magic is a calm, steady white and sky-blue ray.
/// Signature: she spreads her wings wide, and in a flash of light she's Zoar the falcon, hovering on beating wings,
/// then another flash and she's herself again, folding her wings.
private func drawSorceress(_ c: PixelCanvas, _ p: Pose) {
    let wht = C(0xF6F6FA), whtD = C(0xC8D2E4), whtL = C(0xFFFFFF)
    let sky = C(0x6AB8F0), leg = C(0x9ACCF0), legD = C(0x6EA4D0)
    let gold = C(0xE8B040), goldD = C(0xA87A20)
    let s = p.signature ?? -1
    let spread = eterniaRamp(s, 0.04, 0.2, 0.84, 0.96)
    let bird = s > 0.3 && s < 0.68
    let flash = s >= 0 ? max(eterniaRamp(s, 0.24, 0.3, 0.3, 0.36), eterniaRamp(s, 0.62, 0.68, 0.68, 0.74)) : 0

    if bird {
        drawZoar(c, p)
    } else {
        drawLegs(c, Look(leg: leg), step: p.step)
        if !seatedPose {
            for (i, lx) in [19, 23, 31, 35].enumerated() {
                let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
                c.rect(lx, bottom - 1, 2, 2, gold); c.px(lx + 1, bottom, goldD); c.px(lx + 1, bottom - 3, legD)
            }
        }
        c.oy += p.breathe
        // The back wing: folded down her back at rest, its bend standing up behind her shoulder and its long
        // feathers hanging to her heels; swept up and out when she spreads it.
        if spread < 0.15 {
            sorceressFoldedWing(c, white: wht, light: whtL, tip: sky)
        } else {
            let a0 = 100 + (-175 - 100) * spread, a1 = 130 + (-105 - 130) * spread
            eterniaWing(c, root: (18, 28), a0: a0, a1: a1, length: 11 + 5 * spread, white: wht, shade: whtD, tip: sky)
        }
        drawBody(c, Look(arm: wht), armRight: p.armRaise)
        // The bodice: white feathers in rows, the sky-blue gem at the middle, lit on the left.
        c.rect(18, 33, 20, 5, wht); c.rect(36, 33, 2, 5, whtD); c.rect(18, 33, 1, 5, whtL)
        for x in stride(from: 20, to: 36, by: 3) { c.px(x, 34, whtD); c.px(x + 1, 36, whtD) }
        c.pattern(26, 33, [".BB.", "BbBB", ".BB."], ["B": sky, "b": C(0xD8F0FF)])
        // The feather skirt, tipped in blue, over the tops of her legs.
        for (i, x) in stride(from: 18, to: 38, by: 2).enumerated() where 38 + c.oy <= 43 {
            c.rect(x, 38, 2, 1, wht); c.px(x + (i % 2), 39 + 0, i % 2 == 0 ? sky : whtD)
        }
        c.rect(15, 34, 3, 1, sky); c.rect(38, 34 - p.armRaise, 3, 1, sky)   // blue cuffs
        // The front wing, out only while spread.
        if spread > 0.05 {
            eterniaWing(c, root: (38, 28), a0: -75 - 10 * spread, a1: -75 + 70 * spread, length: 6 + 10 * spread,
                        white: wht, shade: whtD, tip: sky)
        }

        // The falcon headdress: a white feathered cap, the falcon's eyes, its gold hooked beak down over her brow, and
        // little wings sweeping up and out either side.
        c.pattern(13, 14, [
            "WW......................WW",
            "BWW....................WWB",
            ".BWW..................WWB.",
            "..BWW....WWWWWWWW....WWB..",
            "...BWWWWWWWLWWWWWWWWWWB...",
            "....WWWWLWWWWWWWWWWWWW....",
            ".....WWLWWKWWWWKWWWWWd....",
            ".....WWWWWWWWWWWWWWWWd....",
            ".....WWWWWWWGGWWWWWWWd....",
            ".....WWWWwWGGGGWwWWWdd....",
            ".....WWdwWWGGGGWWwWddd....",
            ".....BWd...gGGg...dWdB....",
            ".....BW.....gg.....WdB....",
        ], ["W": wht, "L": whtL, "d": whtD, "w": whtD, "B": sky, "K": ink, "G": gold, "g": goldD])
    }

    if flash > 0 {
        // The change: a burst of white and sky-blue light, feathers flying out of it.
        c.glowLine(28, 30, 28, 30, core: C(0xFFFFFF, 0.9 * flash), glow: C(0x8ACCFF, 0.8 * flash), coreR: 3 + 4 * flash,
                   glowR: 7 + 9 * flash)
        for k in 0..<6 {
            let a = Double(k) * 60 + s * 400
            let e = eterniaReach((28, 30), a, 6 + 10 * flash)
            c.rect(Int(e.x), Int(e.y), 2, 1, C(0xFFFFFF, flash))
        }
    }
}

/// Zoar the falcon, the Sorceress' other shape, for the beat she's one: Clawd's block in white plumage,
/// a sky-blue back, a gold hooked beak, a fanned tail, four yellow taloned legs dangling, hovering a little off the
/// ground on great beating wings.
private func drawZoar(_ c: PixelCanvas, _ p: Pose) {
    let wht = C(0xF6F6FA), whtD = C(0xC8D2E4), sky = C(0x6AB8F0), skyD = C(0x3A7AC0)
    let gold = C(0xE8B040), goldD = C(0xA87A20), talon = C(0xF0D040)
    let beat = sin(p.t * 12)
    let hover = 3 + Int((beat * 1).rounded())
    c.oy -= hover
    // The four legs, thin and yellow, the talons curled.
    for lx in [19, 23, 31, 35] {
        c.rect(lx, 38, 1, 4, talon); c.rect(lx, 41, 2, 1, goldD); c.px(lx + 1, 38, wht)
    }
    // The tail, fanned out behind.
    c.pattern(9, 30, ["SSSS.....", "SWWSSS...", "WWWWWSSS.", ".SWWWWWS.", "...SSWWW."], ["S": sky, "W": wht])
    // The back wing.
    eterniaWing(c, root: (20, 29), a0: -170 + beat * 25, a1: -110 + beat * 15, length: 15, white: wht, shade: whtD, tip: skyD)
    // The body: white breast, a sky-blue back and crown, lit on the left.
    c.rect(18, 26, 20, 12, wht)
    c.rect(18, 26, 20, 3, sky); c.rect(18, 26, 20, 1, C(0x9AD8FF)); c.rect(37, 26, 1, 12, whtD); c.rect(18, 37, 20, 1, whtD)
    for x in stride(from: 21, to: 36, by: 3) { c.px(x, 33, whtD); c.px(x + 1, 35, whtD) }
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.px(22, 29, gold); c.px(32, 29, gold)
    // The beak: gold, hooked, out from the front of the face.
    c.pattern(37, 29, ["GGG.", "GGGG", ".gGg", "...g"], ["G": gold, "g": goldD])
    // The front wing, beating.
    eterniaWing(c, root: (36, 29), a0: -100 + beat * 25, a1: -30 + beat * 15, length: 15, white: wht, shade: whtD, tip: skyD)
}
