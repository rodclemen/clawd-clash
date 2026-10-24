import Foundation

// Villains: the last of the demons, and the archangels with Zachariah. Drawn the same way as the heroes
// (HuntHeroes1.swift): Clawd in costume, hair and clothes over the blocky body, Clawd's own orange face showing. What
// marks a demon is its eyes: Dagon's yellow, the Crossroads Demon's and Lucifer's red, Demon Dean's black all through.
// The angels show their wings only as a shadow on the wall behind them (HuntKit.swift's `huntWingShadows`): Lucifer's
// lit red, Michael's thrown by a burst of white light.
//
// Magic (`weapon: .lightning`): `magic:` says how the stream looks, and the engine draws it from `pivot` (the casting
// hand, raised `p.armRaise` pixels: draw the arm raised as much). Don't set `magic.variant` yourself.

let huntVillains3: [HuntVillain: Persona] = [
    .dagon: Persona(name: "Dagon", weapon: .blaster, shot: .fire, muzzle: (44, 32), handGun: false, headTop: 20,
                    signature: 3.2, draw: drawDagon),
    .ramiel: Persona(name: "Ramiel", weapon: .saber, bulk: 3, headTop: 20, signature: 3.8, draw: drawRamiel),
    .demonDean: Persona(name: "Demon Dean", weapon: .saber, headTop: 22, signature: 3.6, draw: drawDemonDean),
    .crossroadsDemon: Persona(name: "The Crossroads Demon", headTop: 20, signature: 3.6, callout: "Do we have a deal?",
                              draw: drawCrossroadsDemon),
    .lucifer: Persona(name: "Lucifer", weapon: .lightning, magic: Magic(core: C(0xFFFFFF), glow: C(0xE4202C)),
                      headTop: 22, signature: 3.6, callout: "Hello, Sam.", draw: drawLucifer),
    .michael: Persona(name: "Michael", weapon: .lightning,
                      magic: Magic(core: C(0xFFFFF6), glow: C(0xF0C24A), jagged: false, thick: true),
                      headTop: 21, signature: 3.6, draw: drawMichael),
    .zachariah: Persona(name: "Zachariah", weapon: .lightning,
                        magic: Magic(core: C(0xF4FAFF), glow: C(0x7AB6FF), jagged: false, touch: true),
                        headTop: 23, signature: 3.0, draw: drawZachariah),
]

// MARK: - Shared bits

/// How far `s` is from `a` to `b`, 0 before and 1 after.
private func hv3Ramp(_ s: Double, _ a: Double, _ b: Double) -> Double { min(1, max(0, (s - a) / (b - a))) }

/// Demon eyes over Clawd's: the whole eye one colour, lit at the top on the side the light comes from, darker below.
/// `pupil`: a dark point looking forward (a yellow-eyed demon's slit).
private func hv3Eyes(_ c: PixelCanvas, _ col: Px, light: Px, dark: Px, pupil: Px? = nil) {
    for x in [22, 32] {
        c.rect(x, 29, 2, 3, col)
        c.px(x, 29, light)
        c.rect(x, 31, 2, 1, dark)
        if let pupil { c.px(x + 1, 30, pupil) }
    }
}

/// A soft glow round a point, faint enough to leave the outline whole.
private func hv3Glow(_ c: PixelCanvas, _ x: Double, _ y: Double, _ col: Px, radius: Double, strength: Double) {
    c.glowLine(x, y, x, y, core: col.alpha(0), glow: col, coreR: 0.1, glowR: radius, strength: strength)
}

// MARK: - Dagon

/// Dagon, Prince of Hell and Lucifer's last guard: long straight black hair, parted in the middle and falling over her
/// shoulders, a black dress to the knee with long sleeves and a V neck, dark lips, black heels, and yellow eyes. She
/// throws fire from her bare palm. Signature: she lifts her hand and a flame blooms in her palm, grows, flickers, and
/// she closes her fingers on it.
private func drawDagon(_ c: PixelCanvas, _ p: Pose) {
    let dress = C(0x1E1C26), dressD = C(0x0C0B10), dressL = C(0x403C4E)
    let hair = C(0x1C1A2A), hairD = C(0x08070E), hairL = C(0x5A5A82)
    let s = p.signature ?? -1
    let bloom = s > 0.04 && s < 0.96 ? (s - 0.04) / 0.92 : -1
    let up = bloom < 0 ? 0 : min(1, bloom / 0.14, (1 - bloom) / 0.12)
    let raise = Int((up * 5).rounded())

    // Bare legs and black heels, the heel a darker point at the back.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, C(0x1A1820), step: p.step, rows: 1)

    c.oy += p.breathe
    // The dress's skirt to the knee, over the legs: lit down the left, a soft fold over each leg, the hem in shade.
    if seatedPose {
        c.rect(18, 38, 20, 1, dress)
    } else {
        c.rect(18, 38, 20, 2, dress); c.rect(18, 39, 20, 1, dressD)
        c.rect(18, 38, 1, 1, dressL)
        for x in [21, 25, 33] { c.px(x, 38, dressL) }
        c.rect(37, 38, 1, 2, C(0x050407))
    }
    drawBody(c, Look(arm: dress, eye: nil), armRight: raise)

    // The bodice: a V neck showing her throat, lit on the left shoulder, a seam under the bust, folds to the waist.
    c.rect(18, 33, 20, 5, dress)
    c.rect(25, 33, 6, 1, clawdOrange); c.rect(26, 34, 4, 1, clawdOrange); c.rect(27, 35, 2, 1, clawdOrange)
    c.px(24, 33, dressL); c.px(25, 34, dressL); c.px(26, 35, dressL)
    c.px(31, 33, dressD); c.px(30, 34, dressD); c.px(29, 35, dressD)
    c.rect(19, 33, 3, 1, dressL); c.rect(18, 34, 1, 3, dressL)
    c.rect(18, 36, 20, 1, dressD); c.rect(22, 34, 1, 2, dressD); c.rect(34, 34, 1, 2, dressD)
    c.rect(37, 33, 1, 5, C(0x050407)); c.rect(18, 37, 20, 1, dressD)
    c.rect(15, 35, 3, 1, dressD)

    // Long straight black hair with a cold blue sheen, parted in the middle and falling past her shoulders behind
    // her, so her cheeks show and the hair hangs clear of her face, a lit streak running down each side.
    c.pattern(16, 20, [
        "......HHHHHHHHHHHH......",
        "....HHHHHHHlHHHHHHHH....",
        "..HHHlHHHHHHhHHHHlHHHH..",
        ".HHHlHHHHHHhhHHHHHlHHHH.",
        ".HHlHHHHHHhHHhHHHHHlHHH.",
        ".HHlHHHHHhHHHHhHHHHlHHH.",
        ".HHlH..............HlHH.",
        "HHHlh..............hlHHH",
        "HHlh................hlHH",
        "HHl..................lHH",
        "Hlh..................hlH",
        "Hl....................lH",
        "Hl....................lH",
        "lh....................hl",
        ".h....................h.",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    // Yellow eyes with a dark slit, and dark lips.
    hv3Eyes(c, C(0xFFD43A), light: C(0xFFF2A0), dark: C(0xD89A10), pupil: C(0x4A3000))
    c.rect(27, 32, 2, 1, C(0x5A1E2E))

    if bloom >= 0 {
        // Her bare hand up, palm open, and the flame blooming in it: it grows, flickers and shrinks as her fingers close.
        let hy = 33 - raise
        c.rect(38, hy, 3, 2, clawdOrange); c.px(40, hy + 1, clawdShade)
        let grow = min(1, max(0, (bloom - 0.1) / 0.25), max(0, (0.9 - bloom) / 0.15))
        let size = Int((grow * 5).rounded())
        guard size > 0 else { return }
        let flick = Int(p.t * 10) % 2 == 0
        let tipA = flick ? "....o.." : "..o....", tipB = flick ? "..o.o.." : ".o..o.."
        let frames: [[String]] = [
            ["...o...", "..oYo.."],
            ["...o...", "..oYo..", "..YWY.."],
            [tipA, "...o...", "..oYo..", ".oYWYo.", "..YWY.."],
            [tipA, "...o...", "..ooo..", ".oYYYo.", ".oYWYo.", "oYWWWYo", ".YWWWY."],
            [tipA, tipB, "...o...", "..oYo..", ".ooYoo.", ".oYYYo.", "oYYWYYo", "oYWWWYo", "oYWWWYo", ".YWWWY."],
        ]
        let rows = frames[size - 1]
        let mid = Double(hy) - Double(rows.count) / 2
        hv3Glow(c, 39.5, mid, C(0xFF9A30), radius: 5 + Double(size) * 1.4, strength: 0.32)
        c.pattern(36, hy - rows.count + 1, rows, ["o": C(0xE8501A), "Y": C(0xFFB030), "W": C(0xFFF2B0)])
        c.rect(38, hy + 1, 3, 1, clawdOrange); c.px(40, hy + 1, clawdShade)   // her fingers round the base of it
        return
    }

    // The hand at her side, palm up; when she throws, a flame flares in it. It lifts `p.gunY` with each throw.
    c.oy += p.gunY
    c.rect(41, 34, 2, 2, clawdOrange); c.px(42, 35, clawdShade)
    if let f = p.fire, frac(f.t / p.firePeriod) < 0.4 {
        hv3Glow(c, 42.5, 32, C(0xFF7A20), radius: 3, strength: 0.25)
        c.pattern(41, 31, [".o.", "oYo", "YW."], ["o": C(0xE8501A), "Y": C(0xFFB030), "W": C(0xFFF2B0)])
    }
}

// MARK: - Ramiel

/// Ramiel, Prince of Hell gone fishing: long, scraggly dirty-blond hair, a scruffy beard, an olive henley under a
/// khaki fisherman's vest with all its pockets, cargo trousers and work boots. A big one (`bulk`). Fights with the
/// Lance of Michael, a long silver lance with a leaf-shaped point and a gold collar. Signature: he leans the lance
/// away, takes out a rod, swings it back over his shoulder and casts; the float lands with a ripple, sits a while, and
/// he reels it in.
private func drawRamiel(_ c: PixelCanvas, _ p: Pose) {
    let vest = C(0x8E8658), vestD = C(0x645E3A), vestL = C(0xB0A878)
    let shirt = C(0x3E4836), shirtD = C(0x283022)
    let hair = C(0xA88C50), hairD = C(0x6E5830), hairL = C(0xD6BE84), beard = C(0x9A7E48), beardD = C(0x76603A)
    let s = p.signature ?? -1
    let k = s > 0.03 && s < 0.97 ? (s - 0.03) / 0.94 : -1

    // Cargo trousers with a pocket on the thigh, and scuffed brown work boots.
    drawLegs(c, Look(leg: C(0x5E5240)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 37 : 38
            c.px(lx + 1, top, C(0x4A3F30))
        }
    }
    drawBoots(c, C(0x4A3220), step: p.step, rows: 2)
    drawBoots(c, C(0x2E1E12), step: p.step, rows: 1)

    c.oy += p.breathe
    let raise = k >= 0 ? 2 : 0
    drawBody(c, Look(arm: shirt), armRight: raise)

    // The henley, its button placket open at the neck, under the vest; the vest's pockets in two rows with their
    // flaps, a D-ring on the chest, the far side in shade.
    c.rect(18, 33, 20, 5, vest)
    c.rect(25, 33, 6, 5, shirt); c.rect(27, 33, 2, 2, shirtD); c.px(27, 35, C(0xC8C0A8))
    c.rect(24, 33, 1, 5, vestL); c.rect(31, 33, 1, 5, vestD)
    c.rect(19, 33, 4, 1, vestL); c.rect(32, 33, 4, 1, vestL)
    c.rect(19, 34, 4, 1, vestD); c.rect(19, 36, 4, 1, vestD); c.px(22, 35, vestD)
    c.rect(32, 34, 4, 1, vestD); c.rect(32, 36, 4, 1, vestD); c.px(35, 35, vestD)
    c.px(20, 35, vestL); c.px(33, 35, vestL); c.px(21, 37, vestL)
    c.px(23, 34, C(0xC0C4CA))   // a D-ring for his clippers
    c.rect(37, 33, 1, 5, vestD); c.rect(18, 37, 20, 1, vestD)
    c.rect(15, 35, 3, 1, shirtD)

    // Long scraggly hair, parted down the middle, falling in strands past his ears: a ragged top, dark strokes running
    // down and out through it, lit on the crown, so it reads as hair and not a cap. A scruffy beard on his jaw and
    // chin, a moustache over a dark mouth, kept clear of his eyes.
    c.pattern(16, 20, [
        "......H.HHH.HHHH.HH.H...",
        "....HHHHHlllHHlllHHHH...",
        "...HHlHHhHHHHHHHhHHlHH..",
        "..HHlHHhHHHhHHhHHhHHlHH.",
        ".HHlHHhHHHhHHHHhHHhHHlH.",
        ".HHlHhHHHhHHHHHHhHHhHlH.",
        ".HhlHH...........HHlhHH.",
        ".HhlH.............HlhHH.",
        "HHhl...............lhHH.",
        ".Hhl...............lhHd.",
        "HHd................d.HH.",
        ".Hd.................dH..",
        "Hd...................dH.",
        "d.....................d.",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    c.pattern(20, 32, ["bb..mmmmmm..bb", ".bbbb.oo.bbbb.", "..bbbbbbbbbb..", "....bBBBBb...."],
              ["b": beard, "m": beardD, "o": C(0x5A2A1E), "B": beardD])

    if k >= 0 {
        drawRamielCast(c, p, k)
        return
    }

    // The Lance of Michael: swung by the shaft, or held upright at his side.
    let steel = C(0xC8CED8), edge = C(0xF4F7FC), shaft = C(0x9AA0AA), gold = C(0xD8A838)
    if let a = p.melee {
        let h = huntHand
        huntSmear(c, h, p.trail, from: 2, to: 15, C(0xF0F4FF))
        huntBar(c, h, a, from: -6, to: 10, shaft, r: 0.7)
        huntBar(c, h, a, from: 10, to: 11, gold, r: 1.1)
        huntBar(c, h, a, from: 11, to: 15, steel, r: 1.1)
        huntBar(c, h, a, from: 11.5, to: 15.5, edge, r: 0.5)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
    } else {
        c.rect(41, 21, 1, 22, shaft); c.rect(42, 21, 1, 22, C(0x6E747E))
        c.rect(40, 20, 3, 1, gold); c.px(42, 20, C(0x9A7420))
        c.pattern(40, 13, [".E.", ".Es", "SEs", "SEs", "SEs", ".S."],
                  ["S": steel, "s": C(0x8A909A), "E": edge])
        c.rect(40, 33, 3, 3, clawdOrange); c.px(42, 35, clawdShade)
    }
}

/// Ramiel's cast, `k` 0…1 through it: the rod out, back over his shoulder, a flick forward, the float flying out to
/// land with a ripple, a wait while it bobs, and the reel bringing it home.
private func drawRamielCast(_ c: PixelCanvas, _ p: Pose, _ k: Double) {
    let hand = (x: 40.0, y: 31.5)
    // The rod's angle: up at rest, swung back, flicked forward, then lifting as he reels in.
    let back = hv3Ramp(k, 0.1, 0.26), fwd = hv3Ramp(k, 0.28, 0.36), lift = hv3Ramp(k, 0.8, 0.92)
    let angle = -40 - back * 75 + fwd * 100 - lift * 25
    let tip = huntReach(hand, angle, 13)
    // The float: dangling under the tip, then flying out to land, bobbing, and reeled back in.
    let land = (x: 63.0, y: 41.0)
    var float = (x: tip.x, y: tip.y + 3)
    let fly = hv3Ramp(k, 0.34, 0.5), reel = hv3Ramp(k, 0.74, 0.92)
    if fly > 0 && reel < 1 {
        let out = fly * (1 - reel)
        float = (x: tip.x + (land.x - tip.x) * out, y: tip.y + 3 + (land.y - tip.y - 3) * out - sin(out * .pi) * 8 * (1 - reel))
        if fly >= 1 && reel == 0 { float.y += Double(Int(p.t * 3) % 2) }
    }
    // The line, sagging between the tip and the float.
    for i in 0...24 {
        let u = Double(i) / 24
        let x = tip.x + (float.x - tip.x) * u, y = tip.y + (float.y - tip.y) * u + sin(u * .pi) * 2
        c.px(Int(x.rounded()), Int(y.rounded()), C(0xE6E2D2))
    }
    // The ripple where it lands, spreading out and fading.
    let ripple = hv3Ramp(k, 0.5, 0.72)
    if ripple > 0 && ripple < 1 {
        let r = 2 + Int(ripple * 4), col = C(0xBCD8F0, 0.5 * (1 - ripple))
        c.rect(Int(land.x) - r, 43, r * 2 + 2, 1, col)
    }
    // The rod: a cork grip in his fist, the dark blank thinning to a pale tip, the reel under his hand.
    huntBar(c, hand, angle, from: -3, to: 0, C(0xC8A070), r: 0.8)
    huntBar(c, hand, angle, from: 0, to: 8, C(0x3A2A1C), r: 0.6)
    huntBar(c, hand, angle, from: 8, to: 13, C(0x8A7A5A), r: 0.4)
    c.rect(38, 33, 3, 3, clawdOrange)
    c.rect(39, 30, 3, 3, clawdOrange); c.px(41, 32, clawdShade)
    c.rect(38, 33, 2, 2, C(0x6A6E76)); c.px(38, 33, C(0xA8ACB4))
    // The float, red over white.
    let fx = Int(float.x.rounded()), fy = Int(float.y.rounded())
    c.rect(fx, fy, 2, 1, C(0xD82A2A)); c.rect(fx, fy + 1, 2, 1, C(0xF2F0EA))
}

// MARK: - Demon Dean

/// Demon Dean: Dean Winclawdster turned, in his own clothes (the same leather jacket open over the flannel), but the
/// amulet's long gone, his right sleeve is pushed up on the Mark of Cain glowing red on his forearm, and his eyes are
/// black all through. Fights with the First Blade, a jawbone with its teeth still in. Signature: karaoke. A mic in his
/// fist, eyes shut, swaying, singing his heart out, notes floating up.
private func drawDemonDean(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x5E3C22), jacketD = C(0x3E2614), jacketL = C(0x7E5636)
    let flannel = C(0x7A2A26), flannelD = C(0x4A1A18), flannelL = C(0xA4483C), tee = C(0x2E2E34)
    let hair = C(0x7A5632), hairD = C(0x56391E), hairL = C(0x9A7444)
    let s = p.signature ?? -1
    let sing = s > 0.05 && s < 0.95 ? (s - 0.05) / 0.9 : -1
    let raise = sing < 0 ? 0 : Int((min(1, sing / 0.12, (1 - sing) / 0.12) * 5).rounded())

    // Jeans, faded down the front of each leg, and brown boots, as Dean's.
    drawLegs(c, Look(leg: C(0x3E5A86)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx, top, 1, 3, C(0x5A76A0))
        }
    }
    drawBoots(c, C(0x4A3020), step: p.step, rows: 2)

    c.oy += p.breathe
    // Swaying to the music while he sings.
    let belting = sing > 0.12 && sing < 0.88
    if belting && Int(p.t * 2.5) % 2 == 1 { c.ox += 1 }
    drawBody(c, Look(arm: jacket, eye: nil), armRight: raise)

    // The jacket open over the flannel and a dark tee, no amulet now.
    c.rect(18, 33, 20, 5, jacket)
    huntPlaid(c, 24, 33, 2, 5, base: flannel, dark: flannelD, light: flannelL)
    huntPlaid(c, 30, 33, 2, 5, base: flannel, dark: flannelD, light: flannelL)
    c.rect(26, 33, 4, 5, tee); c.rect(26, 33, 4, 1, C(0x1E1E24))
    c.rect(20, 33, 4, 1, jacketL); c.rect(32, 33, 3, 1, jacketL); c.px(18, 33, jacketL)
    c.rect(23, 33, 1, 5, jacketD); c.rect(32, 34, 1, 4, jacketD)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD)
    c.rect(19, 34, 1, 3, jacketL); c.rect(34, 35, 3, 1, jacketD); c.px(20, 36, jacketD)
    c.rect(15, 35, 3, 1, jacketD)

    // Dean's short hair, spiked up at the front.
    c.pattern(17, 21, [
        "................H.H...",
        "....H.HH.HH.HHH.HHH...",
        "..HHHlHHHlHHHHlHHHHH..",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HhHHHhHHHHhHHHHhHHhH.",
        ".HH................HH.",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    // Brows drawn down hard over black eyes: the whole eye black, wider than Clawd's and glossy like wet ink, a white
    // glint at the top left and a cold blue sheen at the bottom right, so they read as black eyes and not just his
    // own. Shut tight while he sings.
    c.rect(21, 28, 3, 1, hairD); c.rect(32, 28, 3, 1, hairD)
    if belting {
        c.rect(21, 30, 3, 1, C(0x0A0A0C)); c.rect(32, 30, 3, 1, C(0x0A0A0C))
        c.rect(26, 31, 3, 2, C(0x5A1A18)); c.px(27, 31, C(0x2A0A0A))   // mouth open, mid-song
    } else {
        for x in [21, 32] {
            c.rect(x, 29, 3, 3, C(0x020203)); c.px(x, 29, C(0xF6F8FF)); c.px(x + 1, 29, C(0x5A6480))
            c.px(x, 30, C(0x6E7896)); c.px(x + 2, 31, C(0x3C4866))
        }
    }

    // The sleeve pushed up his right forearm, bare and reaching a pixel further out, the Mark of Cain on it glowing a
    // deep pulsing red: a hooked brand with a bar across it, a hot core at the hook, in a red haze.
    let hy = 33 - raise
    c.rect(38, hy, 4, 3, clawdOrange); c.px(41, hy + 2, clawdShade)
    c.rect(37, hy, 1, 3, jacketD)
    let pulse = 0.7 + 0.3 * sin(p.t * 3)
    let mark = C(0xE81E1E).mix(C(0xFF6A4A), (pulse - 0.7) * 2), core = C(0xFFB49A).mix(C(0xFFE6D8), pulse - 0.7)
    hv3Glow(c, 39.5, Double(hy) + 1.5, C(0xFF2020), radius: 4.2, strength: 0.3 * pulse)
    c.pattern(38, hy, ["..MM", "MMC.", ".M.."], ["M": mark, "C": core])

    if sing >= 0 {
        // The mic in his raised fist, up at his mouth: a silver mesh head, the black handle, its cable looping to the
        // floor. Notes float up and drift away.
        if raise >= 3 {
            c.pattern(33, hy - 4, [".mm..", "mMMm.", "mMMm.", ".mmhh", "...hh"],
                      ["m": C(0x8A8E98), "M": C(0xD4D8E0), "h": C(0x1A1A20)])
            let cx = 39.0, cy = Double(hy) + 3
            for i in 0...14 {
                let u = Double(i) / 14
                let x = cx + u * 6 + sin(u * .pi) * 2, y = cy + (43 - cy) * u
                c.px(Int(x.rounded()), Int(y.rounded()), C(0x1A1A20))
            }
            for n in 0..<2 {
                let f = frac(p.t * 0.7 + Double(n) * 0.5)
                let nx = 42 + n * 4 + Int(f * 6), ny = 24 - Int(f * 14)
                let col = C(n == 0 ? 0xFFE08A : 0xFFB0A0, f < 0.8 ? 0.9 : 0.9 * (1 - f) / 0.2)
                c.pattern(nx, ny, [".NN", ".N.", "NN.", "NN."], ["N": col])
            }
        }
        return   // the First Blade stays in his belt while he sings
    }

    // The First Blade: a jawbone, its old teeth along the edge, swung from the hinge end; or held point down.
    let bone = C(0xE6DAB8), boneD = C(0xAE9E78), tooth = C(0xF8F2DE)
    if let a = p.melee {
        let h = huntHand
        huntSmear(c, h, p.trail, from: 2, to: 9, C(0xFFD6C8))
        huntBar(c, h, a, from: -2.5, to: 1.5, boneD, r: 1)
        huntBar(c, h, a, from: 2, to: 8.5, bone, r: 1)
        let bend = huntReach(huntHand, a - 9, 9.5)
        c.px(Int(bend.x.rounded()), Int(bend.y.rounded()), bone)
        for d in [3.5, 5.5, 7.5] {
            let q = huntReach(huntReach(h, a, d), a + 90, 1.6)
            c.px(Int(q.x.rounded()), Int(q.y.rounded()), tooth)
        }
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
    } else {
        c.pattern(39, 36, ["Bb.", "Bbt", "Bb.", "Bbt", "Bb.", "Bbt", ".B."], ["B": bone, "b": boneD, "t": tooth])
        c.rect(38, 33, 4, 3, clawdOrange); c.px(41, 35, clawdShade)
        c.pattern(38, 33, ["..MM", "MMC.", ".M.."], ["M": mark, "C": core])
    }
}

// MARK: - The Crossroads Demon

/// The Crossroads Demon: long dark-brown hair in loose waves over one shoulder, a fitted red dress to the knee, red
/// lips, black heels, and eyes that flash red when the deal's done. She never fights. Signature: she takes out a little
/// tin box and buries it at the crossroads, pushing the earth back over it and patting it down.
private func drawCrossroadsDemon(_ c: PixelCanvas, _ p: Pose) {
    let dress = C(0xB21C2C), dressD = C(0x7A0E1A), dressL = C(0xDC4656)
    let hair = C(0x3E2218), hairD = C(0x22120C), hairL = C(0x6A3C28)
    let tin = C(0xB8BCC4), tinD = C(0x7A7E86), earth = C(0x6A4A30), earthD = C(0x3A2818)
    let s = p.signature ?? -1
    let k = s > 0.04 && s < 0.96 ? (s - 0.04) / 0.92 : -1

    // The hole and its heap of earth in front of her: dug, the box in, filled, patted down, and gone.
    let hole = k >= 0 && k > 0.14 && k < 0.98
    let fill = hv3Ramp(k, 0.42, 0.68)
    if hole {
        let fade = hv3Ramp(k, 0.86, 0.98)
        let earthL = C(0x9A7452)
        if fill < 1 {
            // The hole, dark inside with a lit lip, and the heap of dug earth beside it, a few clods on top.
            c.rect(43, 42, 9, 2, earthD); c.rect(44, 42, 7, 1, C(0x1E140C)); c.px(43, 42, earth); c.px(51, 42, earth)
            let heap = Int(((1 - fill) * 5).rounded())
            if heap > 0 {
                let widths = [7, 6, 5, 3, 2]
                for row in 0..<heap {
                    c.rect(53 + (7 - widths[row]) / 2, 43 - row, widths[row], 1, row == heap - 1 ? earthL : earth)
                }
                c.px(55, 43, earthD); if heap >= 2 { c.px(57, 42, earthD) }
            }
        }
        // The tin box, set down in the hole: its lit lid, the lid's edge and a latch.
        if k > 0.34 && fill < 0.6 {
            c.rect(44, 39, 7, 4, tin); c.rect(44, 39, 7, 1, C(0xE4E8EE)); c.rect(44, 40, 7, 1, tinD)
            c.rect(50, 40, 1, 3, tinD); c.px(47, 41, C(0x5A5E66))
        }
        if fill > 0 {
            // Filled in, a mound patted down over it, sinking flat at the end.
            let w = 9 - Int((fade * 9).rounded())
            if w > 0 {
                let h = fill < 0.5 ? 1 : fill < 0.85 ? 2 : 3
                c.rect(43 + (9 - w) / 2, 44 - h, w, h, earth)
                if w > 2 { c.rect(44 + (9 - w) / 2, 44 - h, w - 2, 1, earthL) }
                if h > 1 && w > 4 { c.rect(43 + (9 - w) / 2, 44 - h, 1, h, earthD) }
            }
        }
    }

    // Bare legs and black heels.
    drawLegs(c, Look(), step: p.step)
    drawBoots(c, C(0x16121A), step: p.step, rows: 1)

    c.oy += p.breathe
    // The skirt, fitted to the knee: lit down the left, a fold over each leg, the hem in shade.
    if seatedPose {
        c.rect(18, 38, 20, 1, dress)
    } else {
        c.rect(18, 38, 20, 2, dress); c.rect(18, 39, 20, 1, dressD)
        c.px(18, 38, dressL); c.px(22, 38, dressD); c.px(26, 38, dressL); c.px(34, 38, dressD)
        c.rect(37, 38, 1, 2, dressD)
    }
    drawBody(c, Look(eye: nil))

    // The dress: a low square neckline on thin straps, lit on the left, a fold to the waist, the far side in shade.
    c.rect(18, 34, 20, 4, dress)
    c.rect(18, 34, 20, 1, dressL); c.rect(18, 34, 1, 3, dressL)
    c.px(21, 33, dress); c.px(34, 33, dress)
    c.rect(18, 36, 20, 1, dressD); c.px(23, 35, dressD); c.px(31, 35, dressD); c.px(27, 37, dressD)
    c.rect(37, 34, 1, 4, dressD); c.rect(18, 37, 20, 1, dressD)

    // Long dark waves, parted on the left and falling over her right shoulder.
    c.pattern(16, 20, [
        "......HHHHHHHHHHH.......",
        "....HHHHlHHHHHlHHHH.....",
        "...HHHlHHHHHHHHHlHHHH...",
        "..HHHHHHHhHHHHHHHHlHHH..",
        ".HHHHlHHHHHHhHHHhHHlHHH.",
        ".HHHHHHhHHHHHHhHHHHlHHH.",
        ".HHh..............hHHHH.",
        ".HH................hHHH.",
        ".Hh................HlHHH",
        "..h................hHHHH",
        "....................HlHH",
        "....................hHHh",
        ".....................HHh",
        ".....................hH.",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    // Red eyes and red lips.
    hv3Eyes(c, C(0xE8222C), light: C(0xFF8070), dark: C(0x8A0C14))
    c.rect(27, 32, 2, 1, C(0xC0182A))

    // Her right arm: at her side, or holding up the box, reaching down to set it in the hole, and patting the earth.
    var hand = (x: 39.0, y: 34.0)
    if k >= 0 {
        let show = hv3Ramp(k, 0, 0.1) * (1 - hv3Ramp(k, 0.12, 0.2))
        let reach = hv3Ramp(k, 0.14, 0.3) * (1 - hv3Ramp(k, 0.84, 0.96))
        hand = (x: 39 + reach * 6, y: 34 - show * 3 + reach * 6)
        if k > 0.42 && k < 0.84 {
            // Sweeping the earth in, then patting it flat.
            hand.x += k < 0.68 ? sin(k * 60) * 2 : 0
            hand.y += k >= 0.68 && Int(p.t * 8) % 2 == 0 ? -1 : 0
        }
    }
    let hx = Int(hand.x.rounded()), hy = Int(hand.y.rounded())
    if hx != 39 || hy != 34 {
        huntLine(c, 38.5, 34, Double(hx), Double(hy), clawdOrange, 1)
    }
    c.rect(hx - 1, hy - 1, 3, 3, clawdOrange); c.px(hx + 1, hy + 1, clawdShade)
    if k >= 0 && k < 0.34 {
        // The little tin box in her hand, its lit lid, the lid's edge and a latch.
        c.rect(hx - 1, hy - 5, 6, 4, tin); c.rect(hx - 1, hy - 5, 6, 1, C(0xE4E8EE)); c.rect(hx - 1, hy - 4, 6, 1, tinD)
        c.rect(hx + 4, hy - 4, 1, 3, tinD); c.px(hx + 1, hy - 3, C(0x5A5E66))
    }
}

// MARK: - Lucifer

/// Lucifer, in Nick's body: short sandy hair receding at the temples, a weathered grey canvas jacket open over a dark
/// henley, jeans and boots, a smirk, and red eyes. His power is an archangel's: a jagged white stream with a red glow.
/// Signature: a red light falls on the wall behind him and his wings' shadow spreads across it, his eyes burning
/// brighter, then folds away.
private func drawLucifer(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x76726A), jacketD = C(0x54504A), jacketL = C(0x98948C)
    let henley = C(0x34343A), henleyD = C(0x222226)
    let hair = C(0x9C8058), hairD = C(0x74603C), hairL = C(0xBCA070)
    let wings = p.signature.map { $0 > 0.06 && $0 < 0.94 ? sin(($0 - 0.06) / 0.88 * .pi) : 0 } ?? 0

    // Behind everything: the wings' shadow, lit red.
    huntWingShadows(c, min(1, wings * 1.3), tint: C(0x8C0A10), strength: 0.5)

    drawLegs(c, Look(leg: C(0x34405A)), step: p.step)
    drawBoots(c, C(0x3A2A1E), step: p.step, rows: 2)
    drawBoots(c, C(0x22180F), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket, eye: nil), armRight: p.armRaise)

    // The jacket open over the henley: a big collar lit on top, chest pockets with flaps, its buttons, a seam down
    // the far side; the henley's placket with two buttons.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(24, 33, 7, 5, henley); c.rect(27, 33, 1, 3, henleyD); c.px(27, 34, C(0x8A8A90)); c.px(27, 35, C(0x8A8A90))
    c.rect(19, 33, 5, 1, jacketL); c.rect(31, 33, 4, 1, jacketL)
    c.rect(23, 33, 1, 5, jacketL); c.rect(31, 34, 1, 4, jacketD)
    c.rect(19, 34, 3, 1, jacketD); c.rect(33, 34, 3, 1, jacketD); c.px(20, 35, jacketD); c.px(34, 35, jacketD)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD); c.rect(18, 34, 1, 3, jacketL)
    c.rect(15, 35, 3, 1, jacketD)
    c.rect(38, 35 - p.armRaise, 3, 1, jacketD)

    // Short sandy hair, cropped close, the hairline receding at the front.
    c.pattern(17, 22, [
        ".....HHHHHHHHHH.......",
        "...HHHHlHHHlHHHHH.....",
        "..HHHHHHHHHHHHHHHHh...",
        ".HHhHHHHHhHHHHHhHHh...",
        ".HHH..............h...",
        ".Hh...................",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    // Red eyes, a red glow round them while the wings are out, and the smirk.
    if wings > 0.3 {
        hv3Glow(c, 23, 30, C(0xFF2020), radius: 2.5, strength: 0.35 * wings)
        hv3Glow(c, 33, 30, C(0xFF2020), radius: 2.5, strength: 0.35 * wings)
    }
    hv3Eyes(c, wings > 0.5 ? C(0xFF3A3A) : C(0xD81C24), light: C(0xFFA090), dark: C(0x8A0A10))
    c.rect(26, 32, 3, 1, C(0x7A2E22)); c.px(29, 31, C(0x7A2E22))
}

// MARK: - Michael

/// Michael, the eldest archangel: short brown hair neatly parted, a dark navy suit, a white shirt open at the collar
/// and a white pocket square, black shoes, and a faint white light about him all the time. His power is a steady
/// white-gold ray. Signature: a burst of white light breaks out behind him, his eyes go white, and his wings throw
/// their shadow across it, spread and fold.
private func drawMichael(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x23283E), suitD = C(0x131626), suitL = C(0x40476A)
    let shirt = C(0xF4F2EC), shirtD = C(0xC8CCD4)
    let hair = C(0x5A3E28), hairD = C(0x3A2818), hairL = C(0x7E5A3C)
    let s = p.signature ?? -1
    let burst = s < 0 ? 0 : sin(hv3Ramp(s, 0.04, 0.5) * .pi)
    let wings = s < 0 ? 0 : sin(hv3Ramp(s, 0.14, 0.94) * .pi)
    let glow = C(0xFFF4D6)

    // The light about him, always there: a warm gold haze round him, too faint to touch his outline, and a few motes of
    // light rising slowly through it either side of him, clear of his silhouette.
    let shimmer = 0.85 + 0.15 * sin(p.t * 2)
    c.glowLine(27.5, 24, 27.5, 38, core: glow.alpha(0), glow: C(0xFFDE8C), coreR: 0.1, glowR: 13, strength: 0.16 * shimmer)
    for i in 0..<4 {
        let f = frac(p.t * 0.22 + Double(i) * 0.25)
        let x = [12, 45, 9, 48][i] + Int((sin(p.t * 1.3 + Double(i) * 2) * 1.2).rounded()), y = 40 - Int(f * 24)
        let a = 0.9 * min(1, f / 0.2, (1 - f) / 0.3)
        c.px(x, y, C(0xFFF6D8).alpha(a))
        c.px(x - 1, y, C(0xFFD870).alpha(a * 0.45)); c.px(x + 1, y, C(0xFFD870).alpha(a * 0.45))
        c.px(x, y - 1, C(0xFFD870).alpha(a * 0.45)); c.px(x, y + 1, C(0xFFD870).alpha(a * 0.45))
    }
    // The burst: rays of white-gold light from behind him, brightest away from his body.
    if burst > 0.02 {
        for i in 0..<14 {
            let a = Double(i) / 14 * 2 * .pi + 0.2
            let len = 8 + 6 * noise(i * 7 + 3)
            let x0 = 27.5 + cos(a) * 15, y0 = 30 + sin(a) * 13
            let x1 = 27.5 + cos(a) * (15 + len * burst), y1 = 30 + sin(a) * (13 + len * burst)
            c.glowLine(x0, y0, x1, y1, core: C(0xFFFFF4), glow: C(0xFFE08A), coreR: 0.5, glowR: 1.8,
                       strength: 0.55 * burst)
        }
        c.glowLine(27.5, 30, 27.5, 30, core: glow.alpha(0), glow: C(0xFFF8E0), coreR: 0.1, glowR: 22,
                   strength: 0.3 * burst)
    }
    huntWingShadows(c, min(1, wings * 1.3))

    drawLegs(c, Look(leg: C(0x1E2236)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx, top, 1, 4, C(0x2E3450))   // the crease down each trouser leg
        }
    }
    drawBoots(c, C(0x0C0C10), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: suit, eye: nil), armRight: p.armRaise)

    // The suit jacket: notched lapels lit along their edge, the shirt open at the neck, a pocket square, one button,
    // the far side in shade, white cuffs.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 3, shirt); c.rect(26, 33, 1, 1, shirtD); c.rect(29, 33, 1, 1, shirtD); c.rect(27, 34, 2, 2, clawdOrange)
    c.px(27, 35, shirt); c.px(28, 35, shirt); c.rect(26, 36, 4, 1, shirtD)
    c.rect(24, 33, 1, 4, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 4, suitD); c.px(32, 34, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL)
    c.rect(20, 35, 2, 1, shirt); c.px(21, 35, shirtD)
    c.px(28, 37, C(0x5A6080))
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.rect(18, 34, 1, 3, suitL)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 35, shirt)
    c.px(38, 35 - p.armRaise, shirt)

    // Short brown hair, neatly parted on the left and combed across, a gleam along the top.
    c.pattern(17, 21, [
        ".......HHHHHHHHH......",
        "....HHHHlllHHHHHHH....",
        "..HHHhHHHHHlllHHHHH...",
        ".HHHhHHHHHHHHHHHHHHH..",
        ".HHhHHHHHHHHHHHHHHHH..",
        ".HH...............HH..",
        ".Hh................h..",
    ], ["H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)
    // His eyes: lit pale from within, and white while the light bursts.
    if burst > 0.35 {
        hv3Eyes(c, C(0xF6FAFF), light: C(0xFFFFFF), dark: C(0xC8DCF4))
        hv3Glow(c, 23, 30, C(0xE8F2FF), radius: 2.4, strength: 0.4 * burst)
        hv3Glow(c, 33, 30, C(0xE8F2FF), radius: 2.4, strength: 0.4 * burst)
    } else {
        hv3Eyes(c, ink, light: C(0xA8C4E8), dark: ink)
    }
}

// MARK: - Zachariah

/// Zachariah, Heaven's middle manager: balding, with a grey fringe round the back and sides and a few strands combed
/// over the shine on top, a grey office suit, white shirt, a maroon tie, a pen in his breast pocket, black shoes. He
/// smites with a touch, a blue-white glow on his fingertip. Signature: he shoots his cuff and checks his watch,
/// glancing down at it with a little shake of the wrist.
private func drawZachariah(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x7C7E86), suitD = C(0x5A5C64), suitL = C(0xA0A2AA)
    let shirt = C(0xEEF0F2), tie = C(0x7A2232), tieD = C(0x521626)
    let hair = C(0xB8B4AC), hairD = C(0x8C887E), hairL = C(0xD8D4CC)
    let s = p.signature ?? -1
    let look = s > 0.06 && s < 0.94 ? min(1, (s - 0.06) / 0.14, (0.94 - s) / 0.14) : 0
    let watching = look >= 1

    drawLegs(c, Look(leg: C(0x6A6C74)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let top = p.step >= 0 && i % 2 == p.step ? 36 : 37
            c.rect(lx + 1, top, 1, 4, C(0x585A62))   // the trousers in shade on the far side of each leg
        }
    }
    drawBoots(c, C(0x141418), step: p.step, rows: 1)

    c.oy += p.breathe
    let raise = look > 0 ? Int((look * 3).rounded()) : p.armRaise
    drawBody(c, Look(arm: suit, eye: nil), armRight: raise)

    // The suit: lapels, the white shirt and maroon tie with its knot, a pen clipped in his breast pocket, two buttons,
    // the far side in shade.
    c.rect(18, 33, 20, 5, suit)
    c.rect(25, 33, 6, 4, shirt)
    c.rect(27, 33, 2, 1, tieD); c.rect(27, 34, 2, 3, tie); c.px(28, 35, tieD); c.px(27, 36, tieD)
    c.rect(24, 33, 1, 4, suitL); c.px(23, 34, suitL); c.rect(31, 33, 1, 4, suitD); c.px(32, 34, suitD)
    c.rect(19, 33, 4, 1, suitL); c.rect(33, 33, 3, 1, suitL)
    c.rect(20, 35, 3, 1, suitD); c.px(21, 34, C(0x2A4A9A)); c.px(21, 35, C(0x2A4A9A))
    c.px(28, 37, C(0x3A3C44)); c.px(27, 37, suitD)
    c.rect(37, 33, 1, 5, suitD); c.rect(18, 37, 20, 1, suitD); c.rect(18, 34, 1, 3, suitL)
    c.rect(15, 35, 3, 1, suitD); c.px(17, 35, shirt)

    // The bald crown rising above his brow, a shine on it and a few grey strands combed across; the grey fringe
    // thick round the back of his head and cut short over his ear.
    c.pattern(16, 23, [
        "........SSSSSSSS........",
        ".....HhSSLLSsSSsSSSSh...",
        "..HHHhSLLSsSSsSSSSSSSHh.",
        "..HlHh..............hHH.",
        "..HlHh..............hHH.",
        "..HHh...............hH..",
        "...h....................",
    ], ["S": clawdOrange, "L": C(0xF0A080), "s": hairD, "H": hair, "h": hairD, "l": hairL])
    c.rect(22, 28, 2, 1, hairD); c.rect(32, 28, 2, 1, hairD)

    // His eyes, glancing across at the watch while he checks it, and a thin, impatient mouth.
    let gx = watching ? 1 : 0, gy = watching ? 1 : 0
    c.rect(22 + gx, 29 + gy, 2, 3 - gy, ink); c.rect(32 + gx, 29 + gy, 2, 3 - gy, ink)
    c.rect(26, 32, 4, 1, C(0x8A3A2E))

    if look > 0 {
        // The forearm brought up and out in front of him, the cuff shot back, the gold watch on top of his wrist with
        // its white face and ticking hand; a little shake of the wrist to make sure it's going.
        let hy = 33 - raise
        let out = Int((look * 3).rounded())
        let shake = watching && Int(p.t * 6) % 3 == 0 ? -1 : 0
        c.rect(38, hy, 2 + out, 3, suit); c.rect(38, hy + 2, 2 + out, 1, suitD); c.rect(38, hy, 2 + out, 1, suitL)
        c.rect(40 + out, hy, 1, 3, shirt)
        c.rect(41 + out, hy + shake, 3, 3, clawdOrange); c.px(43 + out, hy + 2 + shake, clawdShade)
        if look > 0.6 {
            // The watch on top of his wrist, standing up off it: a gold case lit on top, its white face two by two
            // with a dark hand that ticks across it.
            let wx = 37 + out
            c.rect(wx, hy - 2, 4, 3, C(0xD8A838)); c.rect(wx, hy - 2, 4, 1, C(0xF4D47A)); c.px(wx + 3, hy, C(0x9A7420))
            c.rect(wx + 1, hy - 1, 2, 2, C(0xF8F8F2))
            c.px(wx + 1 + (Int(p.t * 2) % 2), hy - 1, C(0x2A2A30))
        }
    }
}

extension Px {
    /// Part of the way from this colour to `other`, `k` 0…1.
    fileprivate func mix(_ other: Px, _ k: Double) -> Px {
        let u = min(1, max(0, k))
        let r = Double(self.r) + (Double(other.r) - Double(self.r)) * u
        let g = Double(self.g) + (Double(other.g) - Double(self.g)) * u
        let b = Double(self.b) + (Double(other.b) - Double(self.b)) * u
        return Px(r: UInt8(r), g: UInt8(g), b: UInt8(b), a: a)
    }
}
