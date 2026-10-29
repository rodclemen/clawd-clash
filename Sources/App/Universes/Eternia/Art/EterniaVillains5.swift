import Foundation

// Villains: more of Hordakk's Evil Horde, drawn the same way as EterniaVillains1.swift and matching the Horde in
// EterniaVillains3.swift. Each is told apart by a colour pair and a head: Leach's bald green dome and sucker mouth,
// Grizzlor's near-black shag, bear's ears and red eyes over Horde purple, Modulok's red skin and his second head on its
// neck, Multi-Bot's two boxy steel heads, and Entrapta's two great golden braids.

let eterniaVillains5: [EterniaVillain: Persona] = [
    .leach: Persona(name: "Leach", weapon: .lightning,
                    magic: Magic(core: C(0xF0FF8A), glow: C(0x3EBE3A), jagged: false, touch: true),
                    headTop: 20, signature: 4.0, draw: drawLeach),
    .grizzlor: Persona(name: "Grizzlor", weapon: .saber, headTop: 17, signature: 3.2, draw: drawGrizzlor),
    .modulok: Persona(name: "Modulok", weapon: .saber, headTop: 13, signature: 4.0, draw: drawModulok),
    .multiBot: Persona(name: "Multi-Bot", weapon: .saber, armoured: true, headTop: 13, signature: 3.0,
                       draw: drawMultiBot),
    .entrapta: Persona(name: "Entrapta", weapon: .saber, headTop: 18, signature: 3.4, draw: drawEntrapta),
]

// MARK: - Shared bits

private let h5None = C(0, 0)

/// 0 before `a`, 1 after `b`, a straight run between.
private func h5Ramp(_ s: Double, _ a: Double, _ b: Double) -> Double { min(1, max(0, (s - a) / (b - a))) }

/// Calls `f` with each leg's x and the row its foot is on (a lifted leg's foot is a row higher). Not when sitting.
private func h5Feet(_ p: Pose, _ f: (Int, Int) -> Void) {
    guard !seatedPose else { return }
    for (i, lx) in [19, 23, 31, 35].enumerated() { f(lx, p.step >= 0 && i % 2 == p.step ? 42 : 43) }
}

/// A solid line from `a` to `b`, `r` from its centre line, with no glow.
private func h5Line(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ col: Px, r: Double = 0.6) {
    c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: h5None, coreR: r, glowR: r + 0.1)
}

/// The pale smear a fast punch or swipe leaves: a short arc of streaks round the fist, fading.
private func h5Smear(_ c: PixelCanvas, _ trail: [Double], from a: Double, to b: Double) {
    for (i, t) in trail.enumerated() {
        let p0 = eterniaReach(eterniaHand, t, a), p1 = eterniaReach(eterniaHand, t, b)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.5, glowR: 1.6,
                   strength: 0.3 / Double(i + 1))
    }
}

// MARK: - Leach

/// Leach: the Horde's slimy green bloodsucker. A bald green dome glistening with slime, dark spots on it, beady yellow
/// eyes under a heavy brow, and a round sucker of a mouth, pale lips round a pink, toothed hole; a dark Horde-purple
/// belt plate, purple boots, and round suction cups for hands. His magic is a touch: the suckers glow yellow-green and
/// whoever he points them at has the life drained out of them. Signature: a slab of Fright Zone wall rises beside him; he
/// leaps up it and sticks there by one sucker, legs kicking, and slowly slides back down, a trail of slime glistening above his hand, until
/// the sucker pops off.
private func drawLeach(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x5EA03C), skinD = C(0x3C7026), skinL = C(0x8CCC5E), spot = C(0x447E2C), shine = C(0xD8F6B0)
    let rim = C(0xB8DC7E), rimD = C(0x7AA84A), mouth = C(0xC4505E), throat = C(0x4A1420), tooth = C(0xF4F0E4)
    let belt = C(0x4A2A6E), beltD = C(0x2E1A46), beltL = C(0x6E4A98), eyeY = C(0xF4E04A)
    let s = p.signature ?? -1
    let casting = p.zap != nil
    let cup = casting ? C(0xF0FF9A) : C(0xA8CC6A), cupD = casting ? C(0xB8F04A) : rimD
    // 0.04…0.16 the leap; stuck until 0.84, sliding from 9 pixels up to 5; then he drops.
    let stuck = s > 0.16 && s < 0.84
    let liftD: Double = s < 0 ? 0 : s < 0.16 ? h5Ramp(s, 0.04, 0.16) * 9
        : s < 0.8 ? 9 - (s - 0.16) / 0.64 * 4 : 5 * (1 - h5Ramp(s, 0.84, 0.92))
    let lift = Int(liftD.rounded())

    // The wall he sticks to: a slab of grey Fright Zone stone, its face lit, coursed in blocks, there only while he
    // climbs it.
    if s > 0.04 && s < 0.98 {
        let wa = h5Ramp(s, 0.04, 0.12) * (1 - h5Ramp(s, 0.9, 0.98))
        c.rect(43, 8, 5, 36, C(0x5A5E6C, wa)); c.rect(43, 8, 1, 36, C(0xB8BCC8, wa)); c.rect(43, 8, 5, 1, C(0x9A9EAC, wa))
        for y in stride(from: 13, through: 41, by: 5) {
            c.rect(44, y, 4, 1, C(0x3E414C, wa)); c.px(y % 2 == 0 ? 46 : 45, y + 2, C(0x3E414C, wa))
        }
    }
    c.oy -= lift
    // Green legs, kicking while he hangs; purple boots lit along the top.
    let step = lift > 2 ? Int(p.t * 5) % 2 : p.step
    drawLegs(c, Look(leg: skin), step: step)
    drawBoots(c, beltD, step: step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = step >= 0 && i % 2 == step ? 42 : 43
            c.rect(lx, bottom - 1, 2, 1, belt); c.px(lx, bottom - 1, beltL)
            c.px(lx + 1, bottom - 4, spot)
        }
    }
    c.oy += p.breathe

    let up = stuck ? 10 : p.armRaise
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil), armRight: up)
    c.rect(18, 26, 1, 9, skinL)
    if up > 3 { c.rect(38, 36 - up, 3, up, skin); c.rect(40, 36 - up, 1, up, skinD) }   // his stretchy arm, reaching up

    // The bald dome, lit and glistening at the top left, spotted, a slimy shine along it.
    c.pattern(18, 20, [
        "......SSSSSSSS......",
        "....SSLLSSSSSSSS....",
        "..SSLLSSSSSSSSSSSS..",
        ".SSLSSSSSSSSSSSSSSd.",
        "SSLSSSSSSSSSSSSSSSSd",
        "SSSSSSSSSSSSSSSSSSSd",
    ], ["S": skin, "L": skinL, "d": skinD])
    c.px(25, 20, shine); c.px(23, 21, shine); c.px(21, 22, shine)
    for (x, y) in [(29, 22), (33, 23), (26, 24), (35, 25), (19, 31), (36, 29), (20, 28)] { c.px(x, y, spot) }

    // A heavy brow, beady yellow eyes looking ahead.
    c.rect(20, 27, 5, 1, skinD); c.rect(31, 27, 5, 1, skinD)
    c.rect(21, 28, 3, 2, eyeY); c.rect(23, 28, 1, 2, ink)
    c.rect(31, 28, 3, 2, eyeY); c.rect(33, 28, 1, 2, ink)

    // The sucker mouth: pale lips in a ring round a pink hole, a ring of little teeth inside, dark at the throat.
    c.pattern(24, 30, [
        ".RRRRRR.",
        "RmTmmTmR",
        "RmmKKmmR",
        "RmTmmTmR",
        ".rrrrrr.",
    ], ["R": rim, "r": rimD, "m": mouth, "K": throat, "T": tooth])

    // The Horde's belt plate: dark purple, lit along the top.
    c.rect(19, 35, 18, 3, belt); c.rect(19, 35, 18, 1, beltL); c.rect(19, 37, 18, 1, beltD)
    c.rect(27, 36, 2, 1, beltL)

    // The suckers for hands: a round cup on the far arm; on the near one a round cup, or, stuck, a cup flattened on
    // the wall in front of him.
    c.pattern(11, 32, [".RRR.", "RcccR", "RcKcR", "RcccR", ".rrr."], ["R": rim, "r": rimD, "c": cup, "K": cupD])
    let hy = 32 - up
    if stuck {
        c.rect(41, hy - 1, 1, 7, rim); c.rect(42, hy - 1, 1, 7, cup); c.px(41, hy - 1, rimD); c.px(41, hy + 5, rimD)
        // The slime trail he leaves on the wall as he slides down it.
        if lift < 9 {
            c.rect(42, 13 + lift - 2, 1, 11 - lift, C(0xC8F08A, 0.75))
            c.px(42, 13 + lift - 1, C(0xFFFFFF, 0.8))
        }
        // The thwop as it lands.
        if s < 0.28 {
            let a = 1 - h5Ramp(s, 0.16, 0.28)
            for (x, y) in [(44, hy - 2), (45, hy + 2), (44, hy + 6), (40, hy - 3)] { c.px(x, y, C(0xF4FFE0, a)) }
        }
    } else {
        c.pattern(40, hy, [".RRR.", "RcccR", "RcKcR", "RcccR", ".rrr."], ["R": rim, "r": rimD, "c": cup, "K": cupD])
    }
    if s > 0.84 && s < 0.92 {   // the pop as it lets go
        let a = 1 - h5Ramp(s, 0.84, 0.92)
        for k in 0..<6 {
            let ang = Double(k) * .pi / 3
            c.px(42 + Int((cos(ang) * 4).rounded()), 30 + Int((sin(ang) * 4).rounded()), C(0xF4FFE0, a))
        }
    }

    // The glow on his suckers while he drains someone.
    if casting {
        c.glowLine(42.5, Double(hy) + 2.5, 42.5, Double(hy) + 2.5, core: C(0xF0FF9A, 0), glow: C(0x8AE83A, 0.5),
                   coreR: 0.2, glowR: 3)
        c.glowLine(13.5, 34.5, 13.5, 34.5, core: C(0xF0FF9A, 0), glow: C(0x8AE83A, 0.35), coreR: 0.2, glowR: 2.4)
    }
}

// MARK: - Grizzlor

/// Grizzlor: the Horde's furry brute. Shaggy near-black brown fur all over in strands, a low shaggy crown of it with two
/// round bear's ears, a grey-brown face with heavy brows, glowing red eyes, a pale snout and fangs; a Horde-purple
/// chest plate with silver studs, the fur poking over its top, and purple bands at his wrists. The darker fur, the
/// purple armour and the red eyes keep him apart from Chewbacca and Beast Clawd. He fights with his claws, three white
/// ones on each paw, raking three streaks through the air. Signature: he beats his chest, one paw then the other, and
/// roars, the roar rolling away in front of him.
private func drawGrizzlor(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0x4E3422), furD = C(0x2C1C12), furL = C(0x7E5A3C)
    let face = C(0x6E5E54), faceD = C(0x4A3E38), snout = C(0x9A8A7C), nose = C(0x1A1416)
    let plate = C(0x6A3496), plateD = C(0x46206A), plateL = C(0x9058C0), stud = C(0xD0D4E0)
    let eye = C(0xFF3A24), eyeL = C(0xFFB0A0), claw = C(0xF4EEDE), maw = C(0x3A0E14)
    let s = p.signature ?? -1
    let beating = s > 0.08 && s < 0.86
    let beats = beating ? (s - 0.08) / 0.78 * 8 : 0
    let beat = beating ? Int(beats) % 2 : -1            // 0: the near paw on his chest, 1: the far one
    let thump = beating ? frac(beats) : 1

    // Shaggy legs, strands of dark and light, dark clawed feet.
    drawLegs(c, Look(leg: fur), step: p.step)
    h5Feet(p) { lx, bottom in
        c.px(lx, bottom - 6, furL); c.rect(lx + 1, bottom - 5, 1, 2, furD)
        c.rect(lx, bottom, 2, 1, furD); c.px(lx + 2, bottom, claw)
    }
    c.oy += p.breathe

    // The body, furred in strands.
    c.rect(18, 26, 20, 12, fur); c.rect(18, 37, 20, 1, furD); c.rect(37, 26, 1, 12, furD)
    c.rect(18, 26, 1, 8, furL)

    // A low shaggy crown in tufts, lit at their tips, and a ragged ruff down either cheek.
    for x in 17...38 {
        let d = abs(Double(x) - 27.5)
        let top = 23 + Int(d * d / 45) - (x % 2 == 0 ? 1 : 0)
        c.rect(x, top, 1, 27 - top, fur)
        if x % 3 == 1 { c.px(x, top, furL) } else if x % 3 == 0 { c.px(x, top + 1, furD) }
    }
    for y in 26...33 {
        c.px(y % 2 == 0 ? 17 : 16, y, fur); c.px(y % 2 == 0 ? 38 : 39, y, furD)
    }
    for (x, y) in [(19, 30), (36, 31), (20, 33), (35, 27)] { c.px(x, y, furD) }
    // Round bear's ears on top, the inner ear dark.
    c.pattern(17, 19, [".EEE.", "EeeeE", "EeeEE", ".EEE."], ["E": fur, "e": furD])
    c.pattern(34, 19, [".EEE.", "EeeeE", "EEeeE", ".EEE."], ["E": fur, "e": furD])
    c.px(18, 19, furL); c.px(35, 19, furL)

    // The face: heavy brows slanting down to the middle, red eyes glowing under them, the pale snout and black nose,
    // fangs over his lip, or the mouth wide open, roaring.
    c.rect(21, 28, 14, 5, face); c.rect(22, 33, 12, 1, face); c.rect(21, 28, 1, 5, snout); c.rect(34, 28, 1, 5, faceD)
    for x in stride(from: 22, through: 34, by: 3) { c.px(x, 28, fur) }
    c.rect(21, 28, 3, 1, furD); c.px(24, 29, furD); c.rect(32, 28, 3, 1, furD); c.px(31, 29, furD)
    c.rect(22, 29, 2, 2, eye); c.px(22, 29, eyeL); c.rect(32, 29, 2, 2, eye); c.px(32, 29, eyeL)
    c.glowLine(23, 30, 33, 30, core: C(0xFF3A24, 0), glow: C(0xFF2A10, 0.16), coreR: 0.1, glowR: 1.6)
    c.rect(25, 30, 6, 2, snout); c.rect(27, 30, 2, 1, nose)
    if beating {
        c.rect(24, 32, 8, 2, maw); c.px(24, 32, claw); c.px(31, 32, claw); c.px(25, 33, claw); c.px(30, 33, claw)
    } else {
        c.rect(25, 32, 6, 1, nose); c.px(26, 33, claw); c.px(29, 33, claw)
    }

    // The Horde's purple chest plate: lit along the top, silver studs, the fur poking over its top edge.
    c.rect(18, 34, 20, 4, plate); c.rect(18, 34, 20, 1, plateL); c.rect(18, 37, 20, 1, plateD); c.rect(37, 34, 1, 4, plateD)
    for x in [20, 35] { c.px(x, 36, stud) }
    c.px(23, 35, stud); c.px(32, 35, stud)
    for x in stride(from: 19, through: 36, by: 2) where x < 23 || x > 32 { c.px(x, 34, x % 4 == 1 ? furL : fur) }

    // The far paw: at his side, or up on his chest, thumping it.
    if beat == 1 && thump < 0.55 {
        grizzlorPaw(c, x: 19, y: 32, chest: true, right: true)
    } else {
        grizzlorPaw(c, x: 9, y: 32 - (beat == 0 ? 2 : 0), chest: false, right: false)
    }

    if let a = p.melee {
        // The near paw raking at `a`: three streaks through the air behind it, then the paw and its three claws.
        for (i, t) in p.trail.enumerated() {
            for off in [-2.0, 0, 2] {
                let q = eterniaReach(eterniaHand, t + 90, off)
                let p0 = eterniaReach(q, t, 3), p1 = eterniaReach(q, t, 8)
                c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xFFF0E0), glow: C(0xFFF0E0), coreR: 0.35, glowR: 1.1,
                           strength: 0.4 / Double(i + 1))
            }
        }
        prop(c, at: eterniaHand, angle: a) { q in
            q.rect(15, 19, 2, 3, plate)
            q.rect(17, 17, 5, 7, fur); q.rect(17, 17, 5, 1, furL); q.rect(17, 23, 5, 1, furD)
            q.rect(18, 19, 4, 1, furD); q.rect(18, 21, 4, 1, furD)
            q.rect(22, 18, 3, 1, claw); q.rect(22, 20, 4, 1, claw); q.rect(22, 22, 3, 1, claw)
            q.px(25, 19, claw); q.px(26, 21, claw); q.px(25, 23, claw)
        }
    } else if beat == 0 && thump < 0.55 {
        grizzlorPaw(c, x: 27, y: 32, chest: true, right: false)
    } else {
        grizzlorPaw(c, x: 38, y: 32 - (beat == 1 ? 2 : 0), chest: false, right: true)
    }

    // The thump: dust shaken out of his fur either side of the paw.
    if beating && thump < 0.3 {
        let a = 0.7 * (1 - thump / 0.3), cx = beat == 0 ? 33 : 22, r = Int(thump * 8)
        for (dx, dy) in [(-3 - r, -1), (4 + r, -1), (-2 - r, 2), (3 + r, 2)] { c.px(cx + dx, 34 + dy, C(0xE8D8C0, a)) }
    }
    // The roar, rolling away from him in pale arcs.
    if beating {
        for k in 0..<3 {
            let f = frac(p.t * 2.2 + Double(k) / 3)
            let x = 44 + Int(f * 14)
            let col = C(0xF4F0E8, 0.55 * (1 - f))
            for dy in -2...2 { c.px(x + (abs(dy) == 2 ? 0 : 1), 31 + dy, col) }
        }
    }
}

/// One of Grizzlor's great paws: three thick shaggy fingers, a lighter brown than his fur so they stand off it, lit
/// along the top with dark seams between them, a big white claw hooked off each, and his purple wrist band. Flat on
/// his chest (`chest`), the fingers point across it; at his side they point forward or back. `right`: the claws point
/// right.
private func grizzlorPaw(_ c: PixelCanvas, x: Int, y: Int, chest: Bool, right: Bool) {
    let rows = chest ? [
        "P.LFLFL...",
        "PFFFFFFWWW",
        "PFFFdddd.W",
        "PFFFFFFWWW",
        "PFFFdddd.W",
        "PFFFFFFWWW",
    ] : [
        "PLFLFL..",
        "PFFFFFWWW",
        "PFdddd.W",
        "PFFFFFWWW",
        "PFdddd.W",
        "PFFFFFWW.",
    ]
    let w = rows.map(\.count).max() ?? 0
    c.pattern(x, y, right ? rows : rows.map { String($0.padding(toLength: w, withPad: ".", startingAt: 0).reversed()) },
              ["F": C(0x7E5A3C), "L": C(0xAC845C), "d": C(0x2C1C12), "P": C(0x46206A), "W": C(0xF4EEDE)])
}

// MARK: - Modulok

/// Modulok: the Horde's mad scientist, a creature who builds himself out of spare parts. Red skin, a crest of purple
/// spines over his brow, yellow eyes and a fanged grin; a second head of his own on a long neck off his back
/// shoulder, rounder, with its own yellow eyes and teeth; an extra pair of arms ending in purple pincers above his
/// fists; blue armour on his chest, his fists and his boots. He fights with the fists. Signature: his back pincer pops
/// the second head off its neck, turns it over and puts it back on upside down, where it sits grinning the wrong way
/// up while his main face stares at it, until he pops it off and puts it right.
private func drawModulok(_ c: PixelCanvas, _ p: Pose) {
    let red = C(0xCC3A2C), redD = C(0x8E2018), redL = C(0xF06A4E)
    let blue = C(0x2E4E86), blueD = C(0x1E3460), blueL = C(0x4E74B4)
    let spine = C(0x8A4AC0), spineL = C(0xB07ADE), yellow = C(0xFFDC3A), tooth = C(0xF4F0E4), maw = C(0x3A0E14)
    let s = p.signature ?? -1
    let lift = s < 0 ? 0.0 : h5Ramp(s, 0.06, 0.18) * (1 - h5Ramp(s, 0.3, 0.4)) + h5Ramp(s, 0.78, 0.84) * (1 - h5Ramp(s, 0.9, 0.97))
    let up = Int((lift * 6).rounded())
    let turning = (s > 0.21 && s < 0.27) || (s > 0.85 && s < 0.88)
    let flipped = s >= 0.27 && s <= 0.85
    let staring = s > 0.4 && s < 0.8

    // Red legs, blue boots lit along the top.
    drawLegs(c, Look(leg: red), step: p.step)
    drawBoots(c, blue, step: p.step, rows: 3)
    h5Feet(p) { lx, bottom in c.rect(lx, bottom - 2, 2, 1, blueL); c.px(lx + 1, bottom - 5, redD) }
    c.oy += p.breathe

    // The second head's neck, off his back shoulder; drawn first so the body covers its root.
    h5Line(c, (20, 27), (15.5, 21.5), red, r: 1.3)
    h5Line(c, (19, 27.5), (14.5, 22), redD, r: 0.5)
    if up > 0 { c.rect(14, 21, 3, 1, maw) }   // the empty socket, the head off it

    drawBody(c, Look(body: red, shade: redD, arm: red, eye: nil))
    c.rect(18, 26, 1, 8, redL)

    // The crest of purple spines over his brow, the middle ones tallest.
    for (i, x) in stride(from: 21, through: 34, by: 3).enumerated() {
        let h = i == 2 || i == 3 ? 4 : 3
        c.rect(x, 26 - h + 1, 2, h - 1, spine); c.px(x, 26 - h, spineL); c.px(x, 26 - h + 1, spineL)
    }
    // His face: yellow eyes under a heavy brow, looking ahead (or up at the other head), and the fanged grin.
    c.rect(20, 27, 5, 1, redD); c.rect(31, 27, 5, 1, redD)
    c.rect(21, 28, 3, 2, yellow); c.rect(31, 28, 3, 2, yellow)
    if staring { c.px(21, 28, ink); c.px(31, 28, ink) } else { c.rect(23, 28, 1, 2, ink); c.rect(33, 28, 1, 2, ink) }
    c.rect(23, 31, 10, 2, maw)
    for x in stride(from: 24, through: 31, by: 2) { c.px(x, 31, tooth) }
    c.px(23, 32, tooth); c.px(32, 32, tooth)

    // Blue armour on his chest, lit along the top, a rivet each side.
    c.rect(19, 34, 18, 4, blue); c.rect(19, 34, 18, 1, blueL); c.rect(19, 37, 18, 1, blueD); c.rect(36, 34, 1, 4, blueD)
    c.px(21, 36, blueL); c.px(34, 36, blueL)

    // The extra arms, above the fists: red, ending in purple pincers. The back one reaches up for the head.
    c.rect(38, 28, 3, 2, red); c.px(38, 28, redL)
    c.pattern(41, 26, ["PPP", "P..", "P..", "PPP"], ["P": spine])
    if up > 0 || turning {
        let hy = 22.0 - Double(up)
        h5Line(c, (16, 29), (10, hy + 2), red, r: 0.9)
        c.pattern(8, Int(hy) - 1, ["PP", "P.", "P.", "PP"], ["P": spine])
    } else {
        c.rect(15, 28, 3, 2, red)
        c.pattern(12, 26, ["PPP", "..P", "..P", "PPP"], ["P": spine])
    }

    // The second head: the right way up, mid-turn, or upside down.
    let headRows = [
        "..P.P.P..",
        "..RRRRR..",
        ".RLRRRRRd",
        "RRYYRRYYd",
        "RRYKRRYKd",
        "RRRRRRRRd",
        "RMTMTMTRd",
        ".dRRRRRd.",
    ]
    let hy = 13 - up
    let pal: [Character: Px] = ["P": spine, "R": red, "L": redL, "d": redD, "Y": yellow, "K": ink, "M": maw, "T": tooth]
    if turning {
        c.pattern(10, hy + 2, ["..RRRRR..", ".RRYRRYRd", "RRMTMTMRd", ".dRRRRRd."], pal)
    } else {
        c.pattern(10, hy, flipped ? Array(headRows.reversed()) : headRows, pal)
    }

    // The near fist, in a blue gauntlet: at his side, or punching at `a`.
    if let a = p.melee {
        h5Smear(c, p.trail, from: 1, to: 5)
        prop(c, at: eterniaHand, angle: a) { q in
            q.rect(14, 19, 6, 3, red); q.rect(14, 19, 6, 1, redL)
            q.rect(20, 18, 4, 5, blue); q.rect(20, 18, 4, 1, blueL); q.rect(23, 18, 1, 5, blueD)
        }
    } else {
        c.rect(38, 33, 4, 3, blue); c.rect(38, 33, 4, 1, blueL); c.rect(41, 34, 1, 2, blueD)
    }
    c.rect(14, 33, 3, 3, blue); c.px(14, 33, blueL)
}

// MARK: - Multi-Bot

/// Multi-Bot: the Horde's robot that comes apart and fights as many. Gunmetal steel, two boxy heads side by side on
/// short necks, each with a black visor and two amber eyes and an antenna, four arms (blocky fists below, little
/// clamps above), purple joints, vents down his chest round a purple power core with a red light at its heart, and jointed legs on wide feet. Two
/// heads and four arms keep him apart from the one-headed Horde Troopers and from Roboto. He fights with his fists.
/// Signature: both heads spin round on their necks, in opposite directions, face, side, back, side, then stop facing
/// front.
private func drawMultiBot(_ c: PixelCanvas, _ p: Pose) {
    let steel = C(0x8C94AA), steelD = C(0x5C6278), steelL = C(0xC0C8D8), dark = C(0x24262E), darkL = C(0x3E4250)
    let joint = C(0x6A3A9A), jointL = C(0x8E5CC0), lamp = C(0xFFC23A), red = C(0xD8202A)
    let s = p.signature ?? -1
    let spin = s > 0.08 && s < 0.88
    let k = spin ? Int(p.t * 12) % 4 : 0
    let frames = [k, (4 - k) % 4]

    // Steel legs, a purple joint at the knee, wide dark feet.
    drawLegs(c, Look(leg: steel), step: p.step)
    h5Feet(p) { lx, bottom in
        c.px(lx, 37, steelL); c.rect(lx, bottom - 4, 2, 1, joint); c.px(lx, bottom - 4, jointL)
        c.rect(lx, bottom - 1, 2, 2, dark); c.px(lx + 2, bottom, dark); c.px(lx, bottom - 1, darkL)
    }
    c.oy += p.breathe

    drawBody(c, Look(body: steel, shade: steelD, arm: steel, eye: nil))
    c.rect(18, 26, 1, 11, steelL); c.rect(19, 26, 18, 1, steelL)
    // Rivets at the corners, vents down either side of his chest, and a round purple power core low in the middle,
    // a Horde-red light at its heart.
    for (x, y) in [(19, 27), (36, 27), (19, 36), (36, 36)] { c.px(x, y, steelD) }
    c.rect(18, 30, 20, 1, steelD)
    for x in [21, 23, 32, 34] { c.rect(x, 32, 1, 4, steelD); c.rect(x + 1, 32, 1, 4, steelL) }
    c.pattern(25, 31, [".JJJJ.", "JjJJJJ", "JJrRJJ", "JJRRJJ", ".JJJJ."],
              ["J": joint, "j": jointL, "R": red, "r": C(0xFF8A7A)])
    c.rect(26, 36, 4, 1, steelD)

    // The necks, and the two heads on them, each turned to its own frame.
    c.rect(21, 24, 2, 2, dark); c.rect(33, 24, 2, 2, dark)
    // Face on: the visor and both eyes. Side on: the head narrower, the visor jutting out past it with one eye, and a
    // round purple ear bolt where the side of the head shows. From behind: no eyes at all, a purple hatch slatted
    // across with vents where the face was. Each turn changes the head's outline, not just its antenna.
    let looks: [[String]] = [
        [".SSSSSS.", "SLSSSSSd", "SKKKKKKd", "SKYKKYKd", "SKKKKKKd", "SSSSSSSd", "SSgSgSSd", ".dddddd."],
        ["..SSSSS..", ".SLSSSSd.", ".SSSSKKKK", ".SjJSKKYK", ".SJJSKKKK", ".SSSSSSd.", ".SSSSSgd.", "..dddd..."],
        [".SSSSSS.", "SLSSSSSd", "SjJJJJJd", "SJggggJd", "SJJJJJJd", "SJggggJd", "SbSSSSbd", ".dddddd."],
        ["..SSSSS..", ".SLSSSSd.", "KKKKSSSd.", "KYKKSjJd.", "KKKKSJJd.", "..SSSSSd.", "..gSSSSd.", "...dddd.."],
    ]
    for (n, x0) in [18, 30].enumerated() {
        let f = frames[n]
        let ox = f == 3 ? x0 - 1 : x0   // side on, the visor juts a pixel out past the head's usual box
        c.pattern(ox, 16, looks[f], ["S": steel, "L": steelL, "d": steelD, "K": dark, "Y": lamp, "g": darkL,
                                     "b": steelD, "J": joint, "j": jointL])
        let ax = x0 + [3, 5, 4, 2][f]
        c.rect(ax, 14, 1, 2, darkL); c.px(ax, 13, lamp)
        if spin {   // a whirr of motion either side of the spinning head: bright arcs sweeping round it
            let a = 0.8
            let up = (k + n) % 2
            c.rect(x0 - 2, 17 + up, 1, 3, C(0xE8ECF4, a)); c.px(x0 - 1, 16 + up, C(0xE8ECF4, a * 0.6))
            c.rect(x0 + 9, 19 - up, 1, 3, C(0xE8ECF4, a)); c.px(x0 + 8, 22 - up, C(0xE8ECF4, a * 0.6))
        }
    }

    // The upper arms: steel, a purple joint, little clamps.
    c.rect(38, 28, 3, 2, steel); c.px(38, 28, joint)
    c.pattern(41, 26, ["CC.", "C..", "C..", "CC."], ["C": steelD])
    c.rect(15, 28, 3, 2, steel); c.px(17, 28, joint)
    c.pattern(13, 26, [".CC", "..C", "..C", ".CC"], ["C": steelD])

    // The fists: big steel blocks with a purple wrist joint, at his sides, or punching at `a`.
    if let a = p.melee {
        h5Smear(c, p.trail, from: 1, to: 6)
        prop(c, at: eterniaHand, angle: a) { q in
            q.rect(13, 19, 7, 3, steel); q.rect(13, 19, 7, 1, steelL); q.rect(17, 19, 1, 3, joint)
            q.rect(20, 17, 5, 6, steel); q.rect(20, 17, 5, 1, steelL); q.rect(24, 18, 1, 4, steelD)
            q.rect(20, 22, 5, 1, steelD)
        }
    } else {
        c.rect(38, 32, 4, 4, steel); c.rect(38, 32, 4, 1, steelL); c.rect(41, 33, 1, 3, steelD); c.px(38, 35, joint)
    }
    c.rect(13, 32, 4, 4, steel); c.rect(13, 32, 4, 1, steelL); c.rect(13, 33, 1, 3, steelD); c.px(16, 35, joint)
}

// MARK: - Entrapta

/// Entrapta: the Horde's inventor, whose hair does her fighting. A big unruly golden mop parted in the middle, wisps
/// sticking up off it, a ragged fringe, and two great golden braids, plaited, tied in purple, hanging to the floor; a
/// purple bodysuit lit along the shoulders, a gold belt and gold cuffs, purple boots with gold tops. The two braids
/// keep her apart from She-Clawd's long loose hair and winged tiara. She fights with her near braid, gripping it and
/// lashing it out like a rope. Signature: both braids lash out at once, one forward and one back, rippling like whips,
/// crack at their tips, and coil back.
private func drawEntrapta(_ c: PixelCanvas, _ p: Pose) {
    let suit = C(0x7E3EAE), suitD = C(0x58267E), suitL = C(0xA466D2), tights = C(0x4A2470)
    let hair = C(0xF0C440), hairD = C(0xB8862A), hairL = C(0xFFE68A)
    let gold = C(0xE8B830), goldD = C(0xA87E1E)
    let s = p.signature ?? -1
    let ext = s < 0 ? 0 : h5Ramp(s, 0.08, 0.26) * (1 - h5Ramp(s, 0.76, 0.92))
    let lashing = ext > 0.02
    let crack = s > 0.44 && s < 0.54

    /// A braid hanging straight down at `x`, rows `y0` to `y1`, plaited, then its purple tie and a gold tuft.
    func hanging(_ x: Int, _ y0: Int, _ y1: Int) {
        for y in y0...y1 {
            if y % 2 == 0 { c.px(x, y, hairL); c.px(x + 1, y, hair); c.px(x + 2, y, hairD) }
            else { c.px(x, y, hair); c.px(x + 1, y, hairD); c.px(x + 2, y, hair) }
        }
        c.rect(x, y0 + 3, 3, 1, suit)   // the tie where the lock off her head becomes the braid
        c.rect(x, y1 + 1, 3, 1, suit)
        c.pattern(x - 1, y1 + 2, ["HhHhH", "H.h.H"], ["H": hair, "h": hairD])
    }
    /// A braid flung out from `root` to `tip`, rippling, plaited along it; its tie and tuft at the end, and a crack
    /// of sparks there when `snap`.
    func lash(_ root: (x: Double, y: Double), _ tip: (x: Double, y: Double), sag: Double, wave: Double, snap: Bool) {
        let dx = tip.x - root.x, dy = tip.y - root.y, len = max(1, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len, ny = dx / len
        var pts: [(x: Double, y: Double)] = []
        for i in 0...20 {
            let u = Double(i) / 20
            let off = sag * 4 * u * (1 - u) + wave * sin(u * .pi * 3 - p.t * 14) * u
            pts.append((root.x + dx * u + nx * off, root.y + dy * u + ny * off))
        }
        for i in 1..<pts.count { h5Line(c, pts[i - 1], pts[i], hair, r: i > 16 ? 0.8 : 1.1) }
        for i in stride(from: 2, to: pts.count - 1, by: 2) {
            c.px(Int(pts[i].x.rounded()), Int(pts[i].y.rounded()), hairD)
        }
        for i in stride(from: 1, to: pts.count - 2, by: 4) {
            c.px(Int(pts[i].x.rounded()), Int(pts[i].y.rounded()) - 1, hairL)
        }
        let e = pts[pts.count - 1]
        let ex = Int(e.x.rounded()), ey = Int(e.y.rounded())
        c.rect(ex - 1, ey - 1, 2, 2, suit)
        let ax = dx >= 0 ? 1 : -2
        c.px(ex + ax, ey - 1, hair); c.px(ex + ax + (dx >= 0 ? 1 : -1), ey, hairD); c.px(ex + ax, ey + 1, hair)
        if snap {
            c.glowLine(e.x, e.y, e.x, e.y, core: C(0xFFFFFF, 0), glow: C(0xFFE08A, 0.5), coreR: 0.2, glowR: 2.6)
            for k in 0..<4 {
                let a = Double(k) * .pi / 2 + .pi / 4
                c.px(ex + Int((cos(a) * 3).rounded()), ey + Int((sin(a) * 3).rounded()), C(0xFFF4C0))
            }
        }
    }

    // Purple tights, purple boots with gold tops.
    drawLegs(c, Look(leg: tights), step: p.step)
    drawBoots(c, suit, step: p.step, rows: 3)
    h5Feet(p) { lx, bottom in c.rect(lx, bottom - 2, 2, 1, gold); c.px(lx + 1, bottom, suitD) }
    c.oy += p.breathe

    // The far braid, behind her: hanging to the floor, or flung out back.
    if lashing {
        lash((17, 26), (17 - 11 * ext, 26 - 6 * ext), sag: -3 * ext, wave: 2 * ext, snap: crack)
    } else {
        hanging(14, 27, 39)
    }

    let armUp = lashing ? 2 : 0
    drawBody(c, Look(), armLeft: armUp, armRight: armUp)
    // The bodysuit: purple from the shoulders down, lit along the top and the left, the gold belt and its buckle.
    c.rect(18, 33, 20, 5, suit); c.rect(18, 32, 7, 1, suit); c.rect(31, 32, 7, 1, suit)
    c.rect(18, 32, 7, 1, suitL); c.rect(31, 32, 7, 1, suitL); c.rect(18, 32, 1, 5, suitL); c.rect(37, 33, 1, 5, suitD)
    c.rect(18, 36, 20, 1, gold); c.rect(27, 36, 2, 1, goldD)
    // Gold cuffs at her wrists.
    c.rect(15, 35 - armUp, 3, 1, gold); c.rect(38, 35 - armUp, 3, 1, gold)

    // Her hair: a big unruly golden mop parted in the middle, combed out in strands that sweep down and away from the
    // parting, stray wisps sticking up off the top, a long ragged fringe, and locks falling down past her cheeks into
    // the braids. The uneven outline and the strands running all the way down keep it from reading as a helmet.
    c.pattern(16, 15, [
        "........l....m..H.......",
        ".....H..lH..Hm.Hm..H....",
        "....HlHHlHHHpHHmHHmH....",
        "...HlHHlHHHHpHHHmHHmH...",
        "..HlHHlHHHHmpHHHHmHHmH..",
        ".HHlHHlHHHmHpHmHHHmHHmH.",
        ".HlHHlHHHmHHpHHmHHHmHHm.",
        "HHlHHlHHmHHHpHHHmHHHmHHH",
        "HlHHlHHmHHHmHmHHHmHHHmHH",
        "HlHHlHmHHHmHHHmHHHmHHmHm",
        "HlHHlmHHmHHmHHHmHHmHHmHm",
        "HlHHmH.HmH.Hm.mH.HmH.HmH",
        "HlHHm..m...m....m...m.mH",
        "HlHH................HHmH",
        ".lHm................HmH.",
        "..H..................m..",
    ], ["H": hair, "l": hairL, "m": hairD, "p": hairD])

    // The near braid: hanging down in front of her shoulder, flung out forward, or gripped and lashed at `a`.
    if let a = p.melee {
        let h = eterniaHand
        for (i, t) in p.trail.enumerated() {
            let p0 = eterniaReach(h, t, 3), p1 = eterniaReach(h, t, 17)
            c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xFFF0C0), glow: C(0xFFF0C0), coreR: 0.4, glowR: 1.4,
                       strength: 0.25 / Double(i + 1))
        }
        lash((38, 27), (h.x - 1, h.y - 1), sag: 2, wave: 0, snap: false)
        lash((h.x, h.y), eterniaReach(h, a, 17), sag: p.trail.isEmpty ? 1.5 : -2.5, wave: 0.8, snap: false)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) + 1, 3, 1, gold)
    } else if lashing {
        lash((38, 26), (38 + 24 * ext, 26 - 4 * ext), sag: -3 * ext, wave: 2 * ext, snap: crack)
    } else {
        hanging(36, 27, 39)
    }
}
