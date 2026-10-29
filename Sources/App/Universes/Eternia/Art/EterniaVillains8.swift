import Foundation

// Villains: the mercenaries Skeleclawd hires in the 1987 film, and his black-armoured foot soldiers, drawn in the
// same flat cel style as EterniaVillains1.swift so they sit with the cartoon cast. Each is told apart by a colour
// pair and a head: Blade's slicked-back black hair over black and silver armour, Saurod's silver helm on a grey-green
// lizard's snout, Karg's wild white mane over a black fur cloak, and the Dark Trooper's angular black helmet with
// its one narrow red slit.

let eterniaVillains8: [EterniaVillain: Persona] = [
    .blade: Persona(name: "Blade", weapon: .saber, headTop: 20, signature: 3.4, draw: drawBlade),
    .saurod: Persona(name: "Saurod", weapon: .blaster, shot: .energy(core: C(0xFFF2A0), glow: C(0xFF8A1A)),
                     armoured: true, muzzle: (46, 30.5), handGun: false, headTop: 18, signature: 3.0, draw: drawSaurod),
    .karg: Persona(name: "Karg", weapon: .saber, headTop: 12, signature: 3.0, draw: drawKarg),
    .darkTrooper: Persona(name: "Dark Trooper", weapon: .blaster, shot: .energy(core: C(0xFFD8D0), glow: C(0xE8281E)),
                          armoured: true, muzzle: (53, 33), headTop: 19, signature: 3.2, draw: drawDarkTrooper),
]

private let v8None = C(0, 0)

/// 0…1 eased in and out.
private func v8Ease(_ u: Double) -> Double { 0.5 - 0.5 * cos(min(1, max(0, u)) * .pi) }

/// 0…1, fast at first and settling (a snap of the wrist).
private func v8Snap(_ u: Double) -> Double { let f = min(1, max(0, u)); return 1 - pow(1 - f, 3) }

/// A solid line from `a` to `b` with no glow (a scabbard, a hook's curve).
private func v8Line(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ col: Px, r: Double = 0.6) {
    c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: v8None, coreR: r, glowR: r + 0.1)
}

/// The angle a move is at now and the two earlier angles a fast swing smears behind it, as `Pose.trail` has them,
/// for a move whose angle is `at(s)` over a signature `seconds` long.
private func v8Swing(_ s: Double, seconds: Double, _ at: (Double) -> Double) -> (angle: Double, trail: [Double]) {
    let ds = 0.035 / seconds
    let now = at(s), prev = at(s - ds)
    return (now, abs(now - prev) > 6 ? [prev, at(s - 2 * ds)] : [])
}

// MARK: - Blade

/// Blade: the mercenary swordsman. Black hair swept up off his brow in a slick quiff and combed straight back, the comb
/// lines lit in long strands running back and down, with a widow's peak dipping onto his forehead and the ends hanging
/// loose down his nape: hair, not a helmet, because his forehead shows under it and its edge is ragged with strands. A
/// red scar down his cheek beside his front eye, crossed by pale stitch marks. Black armour trimmed in silver: a silver
/// gorget over a black breastplate with a ridge down it and a few silver rivets, a belt of silver studs, black
/// gauntlets with silver cuffs, black legs and boots. His long sword hangs in a black scabbard at his hip, banded and
/// tipped in silver, its silver hilt forward. Signature: a fencing salute, the hilt brought up to his chin with the
/// blade straight up in front of his face, held; then the blade snaps down and he whirls it twice round in a quick
/// flourish before putting it up.
private func drawBlade(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x24242C), blackD = C(0x131318), blackL = C(0x42444F)
    let silver = C(0xB8BCC8), silverD = C(0x7C808E), silverL = C(0xEEF0F6)
    let hair = C(0x15151B), hairM = C(0x2E3140), hairL = C(0x6E7896)
    let leg = C(0x2E2E38), scar = C(0x9A2226), stitch = C(0xFBDCC8)
    let s = p.signature ?? -1
    let sig: (angle: Double, trail: [Double], raise: Int)? = s > 0.05 && s < 0.95 ? bladeSalute(s) : nil
    let raise = sig?.raise ?? 0
    let drawn = p.melee != nil || sig != nil

    // The scabbard, behind him: from his hip back and down past his back legs, banded and tipped in silver. Sitting,
    // it lies back along the ground behind him instead of poking down through it.
    if !drawn {
        let tip: (x: Double, y: Double) = seatedPose ? (6.5, 37.5) : (6.5, 42)
        let band = seatedPose ? (x: 12, y: 36) : (x: 12, y: 38)
        v8Line(c, (19, 36), tip, black, r: 0.95)
        v8Line(c, (18.5, 35.5), (tip.x + 0.5, tip.y - 1), blackL, r: 0.35)
        c.rect(Int(tip.x) - 0, Int(tip.y) - 1, 2, 2, silver); c.px(Int(tip.x), Int(tip.y) - 1, silverL)
        c.rect(band.x, band.y, 1, 2, silver); c.px(band.x, band.y, silverL)
    }

    // Black legs, and black boots with a silver band round the top.
    drawLegs(c, Look(leg: leg), step: p.step)
    drawBoots(c, blackD, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 1, silverD); c.px(lx, bottom - 3, silver)
            c.px(lx, bottom - 6, C(0x44444F))
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: black, eye: nil), armRight: raise)
    c.rect(15, 35, 3, 1, silver); c.px(15, 35, silverL)                      // the cuffs
    c.rect(38, 35 - raise, 3, 1, silver); c.px(38, 35 - raise, silverL)

    // The face: his eyes under straight black brows slanting down to the middle, and the scar: a red line down his
    // cheek beside the front eye, crossed twice by pale stitch marks.
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(22, 28, 2, 1, hair); c.rect(31, 28, 3, 1, hair); c.px(34, 27, hair)
    for (x, y) in [(36, 27), (35, 28), (35, 29), (35, 30), (35, 31), (34, 32)] { c.px(x, y, scar) }
    for (x, y) in [(34, 28), (36, 28), (34, 30), (36, 30)] { c.px(x, y, stitch) }

    // The hair: combed straight back off a high brow, its front edge sloping back as it rises, a slick quiff on top,
    // long lit strands running back and down it, and the ends hanging loose and parted down his nape behind his
    // face. His high forehead shows under the front of it (his head is a little taller there than a bare Clawd's),
    // so it reads as hair and not a cap or a helmet.
    for (y, x0) in [(22, 35), (23, 33), (24, 32), (25, 29)] {
        c.rect(x0, y, 37 - x0, 1, clawdOrange); c.px(37, y, clawdShade)
    }
    c.rect(36, 19, 2, 1, hair); c.px(38, 20, hair); c.px(37, 19, hairL)   // the quiff's tip, flicked forward
    c.pattern(12, 17, [
        "..............HHHHHH......",
        "...........HHHHlllHHHHHH..",
        ".........HHHlllHHHHHlHHH..",
        ".......HHHllHHHHlllHHHHHH.",
        "......HHllHHHHlllHHHHHHmHH",
        ".....HlHHHHlllHHHHHHmmHHH.",
        "....HlHHHlllHHHHHHmHHH....",
        "...HlHHHllHHHHHHmHHHH.....",
        "...HlHHlHHHHHmHHH.........",
        "..HlHHlHHHHHmH............",
        "..HlH.lHHH................",
        ".HlHH.HlH.................",
        ".HlH.HHl..................",
        "HlHH.HlH..................",
        "HlH..Hl...................",
        "H.H...H...................",
        "H.....H...................",
    ], ["H": hair, "m": hairM, "l": hairL])

    // The armour: a silver gorget under his chin, then a black breastplate with a lit ridge down its middle and a
    // silver rivet each side, a belt of silver studs and a black skirt plate edged in silver.
    c.rect(18, 33, 20, 1, silver); c.rect(18, 33, 4, 1, silverL); c.rect(34, 33, 4, 1, silverD)
    c.rect(18, 34, 20, 2, black); c.rect(18, 34, 1, 2, blackL); c.rect(37, 34, 1, 2, blackD)
    c.rect(27, 34, 1, 2, blackL); c.rect(28, 34, 1, 2, blackD)
    c.px(21, 35, silver); c.px(34, 35, silver)
    c.rect(18, 36, 20, 1, blackD)
    for x in stride(from: 19, through: 35, by: 3) { c.px(x, 36, silver) }
    c.rect(18, 37, 20, 1, black); for x in stride(from: 20, through: 36, by: 4) { c.px(x, 37, silverD) }

    if let sig {
        let h = (x: eterniaHand.x, y: eterniaHand.y - Double(raise))
        var q = p; q.trail = sig.trail
        eterniaSword(c, q, angle: sig.angle, at: h, grip: blackD, guardCol: silver, steel: C(0xC8CCD8),
                     edge: white, length: 16, pommel: silverL)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, black)   // his gauntlet round the grip
        c.px(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, blackL)
    } else if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: blackD, guardCol: silver, steel: C(0xC8CCD8), edge: white, length: 16,
                     pommel: silverL)
        let h = eterniaHand
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, black)
        c.px(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, blackL)
    } else {
        // The hilt at his hip, forward of the scabbard: a silver crossguard, a black grip and a silver pommel.
        c.rect(36, 34, 1, 4, silver); c.px(36, 34, silverL)
        c.rect(37, 35, 3, 1, blackD); c.rect(40, 34, 2, 2, silver); c.px(40, 34, silverL)
    }
}

/// Blade's salute, 0…1: the hilt comes up to his chin, the blade straight up (…0.2), held there (…0.42); it snaps
/// down and forward (…0.52), whirls round twice (…0.82) and settles low in front of him. The sword's angle, the
/// swing's trail, and how high his sword hand is lifted.
private func bladeSalute(_ s: Double) -> (angle: Double, trail: [Double], raise: Int) {
    func at(_ u: Double) -> Double {
        if u < 0.2 { return 30 - 120 * v8Ease((u - 0.05) / 0.15) }
        if u < 0.42 { return -90 }
        if u < 0.52 { return -90 + 125 * v8Snap((u - 0.42) / 0.1) }
        if u < 0.82 { return 35 - 720 * v8Ease((u - 0.52) / 0.3) }
        return 35 + 25 * v8Ease((u - 0.82) / 0.13)
    }
    let swing = v8Swing(s, seconds: 3.4, at)
    let lift = s < 0.2 ? v8Ease((s - 0.05) / 0.15) * 5 : s < 0.42 ? 5 : s < 0.82 ? 3 : 3 * (1 - v8Ease((s - 0.82) / 0.13))
    return (swing.angle, swing.trail, Int(lift.rounded()))
}

// MARK: - Saurod

/// Saurod: the armoured lizard man. Grey-green scales, each a little rounded one (a dark curve under a lit top), set in
/// staggered rows, a blunt snout jutting out in front at eye level with a nostril and a row of teeth along the jaw,
/// kept short and high so his fighting arm shows under it, and red eyes under a heavy brow; a silver helm over his
/// crown with a crest down the middle, and silver plate on his chest, wrists and shins, riveted and lit along the top,
/// over a dark belt. No fins, no hood: the helm and the plate are what keep him apart from the other scaly greens. He
/// spits his shots, orange-yellow sparks out of his jaws, and his jaw drops as each one goes. Signature: he opens his
/// jaws wide and a shower of sparks sprays out of them, arcing down in front of him.
private func drawSaurod(_ c: PixelCanvas, _ p: Pose) {
    let scale = C(0x7E9C7A), scaleD = C(0x58725A), scaleL = C(0xA8C4A2)
    let silver = C(0xC4C8D2), silverD = C(0x868A98), silverL = C(0xF0F2F8)
    let belt = C(0x2A2E2A), mouth = C(0x5A1414), red = C(0xE8281E), redL = C(0xFFA080)
    let s = p.signature ?? -1
    let spray = s > 0.1 && s < 0.86
    let open = spray ? (s < 0.16 ? 1 : s > 0.8 ? 1 : 3) : p.recoil > 0 ? 2 : 0

    drawLegs(c, Look(leg: scale), step: p.step)
    drawBoots(c, silverD, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 1, silver); c.px(lx, bottom - 2, silverL)   // the shin plates' lit tops
            c.px(lx + 1, bottom - 5, scaleD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: scale, shade: scaleD, arm: scale, eye: nil))

    // Scales: little rounded ones in staggered rows over his face and neck, each a dark curve under a lit top (a
    // curve, not a block, so they read as scales and not as brickwork), and a lit run down his left side.
    for (x, y) in [(20, 31), (26, 31), (32, 31), (23, 32), (29, 32), (27, 27)] {
        c.px(x, y, scaleD); c.px(x + 1, y + 1, scaleD); c.px(x + 2, y, scaleD); c.px(x + 1, y, scaleL)
    }
    c.rect(18, 26, 1, 7, scaleL)

    // The helm: a silver dome over his crown, lit on the left, a crest of plate down its middle and a dark rim along
    // his brow; two rivets.
    c.pattern(18, 18, [
        ".........SS.........",
        "......LLSccSSS......",
        "....LLSSScdSSSSS....",
        "...LSSSSScdSSSSSSd..",
        "..LSSSSSScdSSSSSSSd.",
        ".LSSSSSSScdSSSSSSSSd",
        "LSSSSSSSScdSSSSSSSSd",
        "SSSSSSSSScdSSSSSSSSd",
    ], ["S": silver, "L": silverL, "d": silverD, "c": silverL])
    c.rect(27, 19, 1, 7, silverL); c.rect(28, 19, 1, 7, silverD)
    c.rect(18, 26, 20, 1, silverD); c.px(21, 24, silverD); c.px(34, 24, silverD)

    // Red eyes under a heavy scaly brow.
    c.rect(21, 27, 4, 1, scaleD); c.rect(31, 27, 4, 1, scaleD)
    for ex in [22, 32] {
        c.rect(ex - 1, 28, 4, 3, scaleD)
        c.rect(ex, 28, 2, 2, red); c.px(ex, 28, redL)
    }

    // Silver plate on his chest, lit along the top, a seam down it and two rivets; a dark belt with a silver buckle;
    // silver bracers.
    c.rect(18, 34, 18, 2, silver); c.rect(18, 34, 18, 1, silverL); c.rect(35, 34, 1, 2, silverD)
    c.rect(26, 34, 1, 2, silverD); c.px(20, 35, silverD); c.px(33, 35, silverD)
    c.rect(18, 36, 20, 1, belt); c.rect(26, 36, 2, 1, silver)
    c.rect(18, 37, 20, 1, scaleD)
    c.rect(15, 34, 3, 1, silver); c.px(15, 34, silverL)
    c.rect(38, 34, 3, 1, silver); c.px(38, 34, silverL)

    // The snout, jutting out in front of his face at eye level, short and high so his fighting arm shows under it:
    // the upper jaw with its nostril and its row of teeth, and the slim lower jaw under it, hinged at the back, its
    // front dropping open (`open`) on a dark mouth.
    c.pattern(36, 27, [
        "SSSSSS....",
        "SSSSSSSSL.",
        "SSSdSSSSSn",
        "TdTdTdTdT.",
    ], ["S": scale, "L": scaleL, "d": scaleD, "n": ink, "T": white])
    c.rect(36, 27, 6, 1, scaleL)
    for i in 0..<8 {
        let x = 36 + i, drop = open * i / 7
        if drop > 0 { c.rect(x, 31, 1, drop, mouth) }
        c.px(x, 31 + drop, i == 7 ? scaleD : i % 2 == 0 ? white : scaleD)
        c.px(x, 32 + drop, i == 7 ? scaleD : scale)
    }

    if spray { saurodSparks(c, (s - 0.1) * 3.0, open: open) }
}

/// The shower of sparks out of Saurod's jaws, `tt` seconds into it: one spark every 0.05 s, each flung forward and up
/// a little, falling as it goes and fading, a short bright streak along its path. Each is drawn only while it's well
/// inside the frame.
private func saurodSparks(_ c: PixelCanvas, _ tt: Double, open: Int) {
    let mx = 44.0, my = 31.0 + Double(open) / 2
    c.glowLine(mx, my, mx, my, core: C(0xFFF6C0, 0.9), glow: C(0xFF9A2A), coreR: 0.8, glowR: 2.4, strength: 0.8)
    for i in 0..<44 {
        let age = tt - Double(i) * 0.05
        guard age > 0, age < 0.55 else { continue }
        let a = (-38 + 58 * noise(i * 7 + 3)) * .pi / 180
        let v = 26 + 20 * noise(i * 13 + 1)
        func at(_ t: Double) -> (x: Double, y: Double) {
            (mx + cos(a) * v * t, my + sin(a) * v * t + 34 * t * t)
        }
        let now = at(age), back = at(max(0, age - 0.04))
        guard now.x < 68, now.y < 49, now.y > 3 else { continue }
        // Full bright for most of its flight, so it reads on a dark desktop, then gone quickly.
        let fade = age < 0.38 ? 1 : 1 - (age - 0.38) / 0.17
        let hot = noise(i * 5) > 0.5
        c.glowLine(back.x, back.y, now.x, now.y, core: (hot ? C(0xFFFBE0) : C(0xFFE070)).alpha(fade),
                   glow: C(0xFFB040), coreR: 0.55, glowR: 1.2, strength: fade)
    }
}

// MARK: - Karg

/// Karg: the hook-handed mercenary, Skeleclawd's tracker. A wild white mane standing out all round his head in strands,
/// grey at the tips and shaded in strokes, round a pale face with heavy black brows and a grim mouth; a black fur cloak
/// hanging down his back with a ragged collar of it over his shoulders, and bronze armour on his chest with a dark
/// belt; black sleeves, a bronze bracer, dark legs and bronze-capped boots. A sword hangs at his back hip over the
/// cloak, its bronze hilt standing up by his back arm and its brown leather scabbard slanting down behind him, but he
/// never draws it: his sword hand is a steel hook, outlined dark so it still reads against his white mane when he
/// raises it, and it's what he fights with. Nothing about him is a skull: the mane and the hook carry him. Signature:
/// he draws the hook back over his head, slashes it down through the air in a pale streak, and bares his teeth.
private func drawKarg(_ c: PixelCanvas, _ p: Pose) {
    let mane = C(0xDCDCE4), maneD = C(0x9C9EAA), maneL = C(0xFAFAFC), maneT = C(0xB8BAC6)
    let face = C(0xE2CDBE), faceD = C(0xB8A090)
    let cloak = C(0x1E1A20), cloakD = C(0x0E0C10), cloakL = C(0x3E3842)
    let bronze = C(0xB8813A), bronzeD = C(0x84561E), bronzeL = C(0xE4B266)
    let sleeve = C(0x2A2428), leg = C(0x3A302C), brow = C(0x18141A)
    let s = p.signature ?? -1
    let sig: (angle: Double, trail: [Double])? = s > 0.06 && s < 0.9 ? kargSlash(s) : nil
    let raise = sig != nil ? (s < 0.32 ? Int((v8Ease((s - 0.06) / 0.2) * 4).rounded()) : s > 0.8 ? 1 : 2) : 0
    let snarl = s > 0.3 && s < 0.86

    // The cloak hanging down his back, ragged at the hem, strands of fur lit down it; drawn behind his legs.
    c.oy += p.breathe
    for y in 30...42 where y + c.oy <= 43 {
        let left = 15 - (y - 30) / 3
        c.rect(left, y, 21 - left, 1, cloak)
        c.px(left, y, cloakL)
    }
    for x in stride(from: 13, through: 19, by: 2) {
        c.rect(x, 37 + (x % 4 == 1 ? 0 : 1), 1, 4, cloakD)
    }
    if c.oy <= 0 { for x in stride(from: 12, through: 20, by: 3) { c.px(x, 43, cloakD) } }

    c.oy -= p.breathe

    drawLegs(c, Look(leg: leg), step: p.step)
    drawBoots(c, C(0x2A2220), step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 1, bronzeD); c.px(lx, bottom - 2, bronze)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: face, shade: faceD, arm: sleeve, eye: nil), armRight: raise)
    c.rect(38, 35 - raise, 3, 1, bronze); c.px(38, 35 - raise, bronzeL)   // the bracer above the hook
    c.rect(15, 35, 3, 1, bronzeD)

    // The wild mane: strands standing out all round his head, every one ending in a grey tip, shaded in strokes and
    // lit along the crown; down past his cheeks either side, ragged at the ends.
    let tops = [28, 22, 25, 19, 22, 17, 20, 16, 18, 15, 18, 16, 15, 18, 15, 17, 14, 17, 16, 15, 18, 16, 19, 17, 20, 18, 22,
                20, 25, 29]
    for (i, top) in tops.enumerated() {
        let x = 13 + i
        let side = x < 20 || x > 35
        let bottom = !side ? 26 : x < 15 || x > 40 ? 30 + x % 2 : 33 - x % 2
        c.rect(x, top, 1, bottom - top + 1, mane)
        c.px(x, top, maneT)
        let n = Int(noise(x * 5) * 4)   // the strokes run different lengths, so it reads as tangled, not combed
        if x % 3 == 0 { c.rect(x, top + 1 + n % 2, 1, max(1, bottom - top - 2 - n), maneD) }
        if x % 3 == 2 && n > 1 { c.rect(x, top + 2 + n, 1, 3, maneD) }
        if x % 3 == 1 && x < 31 && top + 1 < bottom { c.rect(x, top + 1, 1, 2, maneL) }
        if side { c.px(x, bottom, maneT) }
    }
    // Strands flying loose out of it, up and out at the crown and the sides.
    for (x0, y0, x1, y1) in [(15.5, 21.5, 11.5, 17.5), (13.5, 26.5, 10.5, 24.5), (20.5, 17.5, 18.5, 13.5),
                             (33.5, 16.5, 36.5, 12.5), (39.5, 20.5, 43.5, 17.5), (41.5, 26.5, 44.5, 25.5)] {
        v8Line(c, (x0, y0), (x1, y1), mane, r: 0.5)
        c.px(Int(x1), Int(y1), maneT)
    }

    // The pale face: heavy black brows slanting down to the middle, his eyes under them, and a grim mouth that opens
    // on bared teeth while he snarls.
    c.rect(20, 27, 16, 6, face); c.rect(35, 27, 1, 6, faceD)
    c.rect(21, 27, 4, 1, brow); c.px(24, 28, brow); c.rect(31, 27, 4, 1, brow); c.px(31, 28, brow)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    if snarl {
        c.pattern(24, 31, [
            "KTKTKTKTK",
            "KTTKTTKTK",
        ], ["K": C(0x3A1014), "T": white])
    } else {
        c.rect(25, 32, 6, 1, faceD); c.px(24, 32, C(0x6A4A44)); c.px(31, 32, C(0x6A4A44))
    }

    // The ragged black fur collar over his shoulders, then the bronze breastplate, lit along the top with a seam and
    // two rivets; the dark belt and its bronze buckle; a black fur kilt.
    eterniaFur(c, 15, 33, 26, 1, base: cloak, dark: cloakD, light: cloakL, ragged: false)
    c.rect(18, 34, 20, 2, bronze); c.rect(18, 34, 20, 1, bronzeL); c.rect(36, 34, 2, 2, bronzeD)
    c.rect(27, 34, 1, 2, bronzeD); c.px(21, 35, bronzeD); c.px(33, 35, bronzeD)
    c.rect(18, 36, 20, 1, C(0x2A1E18)); c.rect(27, 36, 2, 1, bronzeL)
    eterniaFur(c, 18, 37, 20, 1, base: cloak, dark: cloakD, light: cloakL)
    // The sword at his side, hanging from his belt at the back hip over the cloak: a bronze pommel and a dark
    // leather grip standing up beside his back arm, a bronze crossguard, and the brown leather scabbard slanting down
    // and back to a bronze chape. Sitting, it lies back along the ground.
    let leather = C(0x6A4024), leatherD = C(0x2E1A0E), leatherL = C(0x9C6A40)
    let tip: (x: Double, y: Double) = seatedPose ? (5.5, 37.5) : (9.5, 42.5)
    v8Line(c, (11.5, 35.5), tip, leatherD, r: 1.2)
    v8Line(c, (11.5, 35.5), tip, leather, r: 0.7)
    c.px(11, 35, leatherL)
    c.rect(Int(tip.x) - 1, Int(tip.y) - 1, 2, 2, bronze); c.px(Int(tip.x) - 1, Int(tip.y) - 1, bronzeL)
    c.rect(9, 34, 5, 1, bronze); c.px(9, 34, bronzeL); c.px(13, 34, bronzeD)          // the crossguard
    c.rect(11, 32, 1, 2, leatherL)                                                     // the grip
    c.rect(10, 30, 2, 2, bronze); c.px(10, 30, bronzeL); c.px(11, 31, bronzeD)        // the pommel

    // The hook: held out on the fighting arm, swung when he fights or slashes, hanging down in front of him when
    // he doesn't.
    let h = (x: eterniaHand.x, y: eterniaHand.y - Double(raise))
    let angle = sig?.angle ?? p.melee ?? 70
    let trail = sig?.trail ?? p.trail
    for (i, t) in trail.enumerated() {   // the pale streak a fast slash leaves
        let p0 = eterniaReach(h, t, 4), p1 = eterniaReach(h, t, 11)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xF0F4FF), glow: C(0xF0F4FF), coreR: 0.5, glowR: 1.8,
                   strength: 0.35 / Double(i + 1))
    }
    kargHook(c, at: h, angle: angle)
}

/// Karg's hook from the cuff at `h`, pointing along `angle`: a steel cuff, a straight shank, then a curve turning
/// back on itself to a sharp point, lit along its outer edge. The curve opens upward when he holds it out.
private func kargHook(_ c: PixelCanvas, at h: (x: Double, y: Double), angle a: Double) {
    let steel = C(0xA4ACC0), steelD = C(0x5A5E6C), steelL = C(0xF0F2F8), rim = C(0x22242E)
    let r = 2.6
    let base = eterniaReach(h, a, 6.5)
    let centre = eterniaReach(base, a - 90, r)
    var pts: [(x: Double, y: Double)] = []
    for k in 0...6 {
        let th = a + 90 - Double(k) * 30
        pts.append(eterniaReach(centre, th, r))
    }
    let tip = eterniaReach(pts[pts.count - 1], a + 180, 1.6)
    // A dark rim round all of it first, so the steel parts from his white mane when he raises it over his head.
    eterniaBar(c, h, a, from: 1.2, to: 6.5, rim, r: 1.35)
    for i in 1..<pts.count { v8Line(c, pts[i - 1], pts[i], rim, r: 1.3) }
    v8Line(c, pts[pts.count - 1], tip, rim, r: 1.15)
    eterniaBar(c, h, a, from: 1.2, to: 6.5, steel, r: 0.75)
    for i in 1..<pts.count { v8Line(c, pts[i - 1], pts[i], steel, r: 0.7) }
    v8Line(c, pts[pts.count - 1], tip, steel, r: 0.55)
    c.px(Int(tip.x.rounded(.down)), Int(tip.y.rounded(.down)), steelL)
    let mid = pts[3]
    c.px(Int(mid.x.rounded(.down)), Int(mid.y.rounded(.down)), steelL)
    // The cuff over his wrist, square to the shank.
    let q = eterniaReach(h, a, 0.8)
    let e0 = eterniaReach(q, a + 90, 1.8), e1 = eterniaReach(q, a - 90, 1.8)
    c.glowLine(e0.x, e0.y, e1.x, e1.y, core: steelD, glow: v8None, coreR: 1.1, glowR: 1.2)
    c.px(Int(e1.x.rounded(.down)), Int(e1.y.rounded(.down)), steelL)
}

/// Karg's slash, 0…1: the hook drawn back up over his head (…0.3), slashed down through the air (…0.38), held low
/// while he snarls, then a second, smaller slash back up and down (…0.72), and let fall.
private func kargSlash(_ s: Double) -> (angle: Double, trail: [Double]) {
    func at(_ u: Double) -> Double {
        if u < 0.3 { return 70 - 190 * v8Ease((u - 0.06) / 0.24) }
        if u < 0.38 { return -120 + 165 * v8Snap((u - 0.3) / 0.08) }
        if u < 0.56 { return 45 }
        if u < 0.64 { return 45 - 110 * v8Ease((u - 0.56) / 0.08) }
        if u < 0.7 { return -65 + 115 * v8Snap((u - 0.64) / 0.06) }
        return 50 + 20 * v8Ease((u - 0.74) / 0.12)
    }
    return v8Swing(s, seconds: 3.0, at)
}

// MARK: - Dark Trooper

/// A Dark Trooper: one of Skeleclawd's foot soldiers from the film. Black armour from head to foot with gunmetal lit
/// along its edges: an angular helmet with a flat crown and a flared neck guard, a brow ridge, and one narrow visor
/// slit glowing dim red right across it; banded black plates on his chest, no emblem of any kind, black legs with
/// gunmetal knees. His laser rifle is gunmetal with a black barrel shroud and a red power cell, and fires red bolts.
/// Black with the one red slit keeps him apart from the grey, bat-badged Horde Trooper. Signature: he brings the rifle
/// up to his shoulder and takes aim, a red glint sweeping back and forth along his visor and a thin red sighting beam
/// flickering out ahead of him, then lowers it.
private func drawDarkTrooper(_ c: PixelCanvas, _ p: Pose) {
    let black = C(0x1E1E24), blackD = C(0x101014), blackL = C(0x383A44), gun = C(0x5A5E6A), gunL = C(0x8A8E9C)
    let slit = C(0x7A1212), glint = C(0xFF5038), cell = C(0xE8281E)
    let s = p.signature ?? -1
    let aim = s > 0.08 && s < 0.9
    let up = aim ? Int((min(1, (s - 0.08) / 0.12, (0.9 - s) / 0.1) * 3).rounded()) : 0
    let step = eterniaMarchStep(p.who) ?? p.step   // marching on the spot with the others (EterniaHabits.swift)

    // Black legs with a gunmetal knee, black boots a shade darker, a lit toe.
    drawLegs(c, Look(leg: black), step: step)
    drawBoots(c, blackD, step: step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = step >= 0 && i % 2 == step ? 42 : 43
            c.px(lx, bottom - 4, gun); c.px(lx + 1, bottom - 4, blackL)
            c.px(lx + 1, bottom, blackL)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: black, shade: blackD, arm: black, eye: nil), armRight: up)
    c.rect(18, 26, 1, 11, blackL)

    // The helmet: a flat crown, sides sloping out to a flared neck guard behind, gunmetal along the top and the left
    // edges, a brow ridge over the visor.
    c.pattern(17, 19, [
        "....GGGGGGGGGGGGGG....",
        "...GLLLLLLLLLLLLLLd...",
        "..GLBBBBBBBBBBBBBBBd..",
        ".GLBBBBBBBBBBBBBBBBBd.",
        ".LBBBBBBBBBBBBBBBBBBd.",
        "GLBBBBBBBBBBBBBBBBBBBd",
        "LBBBBBBBBBBBBBBBBBBBBd",
        "GGGGGGGGGGGGGGGGGGGGGd",
        "BBBBBBBBBBBBBBBBBBBBBd",
        ".BBBBBBBBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBBBBBBBBB.",
    ], ["B": black, "L": blackL, "G": gun, "d": blackD])
    c.rect(15, 27, 3, 4, black); c.rect(15, 27, 1, 4, blackL); c.px(15, 30, gun)   // the flared neck guard behind
    c.rect(27, 20, 2, 6, blackL); c.px(27, 20, gunL)
    // The visor slit: one narrow line of dim red right across, its glint at rest or sweeping while he aims.
    c.rect(19, 29, 18, 1, slit)
    c.rect(19, 30, 18, 1, blackD)
    let gx: Int
    if aim { gx = 20 + Int(((sin(p.t * 3.2) + 1) / 2 * 14).rounded()) } else { gx = 32 }
    c.rect(gx, 29, 3, 1, glint); c.px(gx + 1, 29, C(0xFFC0A8))
    c.glowLine(Double(gx) + 1.5, 29.5, Double(gx) + 1.5, 29.5, core: C(0xFF5038, 0), glow: C(0xFF3020, 0.3),
               coreR: 0.1, glowR: 2)
    // A plain chin plate under it with a seam, then banded black plates on his chest, lit along each top edge.
    c.rect(20, 31, 16, 1, blackL); c.rect(20, 32, 16, 1, blackD)
    for y in [33, 35] { c.rect(19, y, 18, 1, blackL); c.px(19, y, gun) }
    c.rect(18, 37, 20, 1, blackD); c.rect(27, 36, 2, 1, gun)
    c.rect(15, 33, 3, 1, blackL)

    // The rifle: gunmetal with a lit top, a black barrel shroud, a red power cell, a stock under his arm and a grip
    // under the fist. Aiming, it comes up to his shoulder at eye level and a thin red sighting beam flickers ahead.
    let y0 = 32 - up + p.gunY
    c.rect(33, y0 + 1, 4, 2, blackL)                                   // the stock
    c.rect(37, y0, 11, 3, gun); c.rect(37, y0, 11, 1, gunL)
    c.rect(44, y0 + 1, 8, 1, blackD); c.rect(48, y0, 4, 1, black); c.px(52, y0 + 1, gunL)
    c.rect(40, y0 + 2, 3, 1, cell); c.px(40, y0 + 2, C(0xFF8A70))
    c.rect(41, y0 + 3, 2, 2, black)
    c.rect(38, y0 + 1, 3, 3, black); c.px(38, y0 + 1, blackL)          // the gauntlet round it
    if aim && up >= 3 && Int(p.t * 9) % 4 != 0 {
        c.glowLine(54, Double(y0) + 1.5, 68, Double(y0) + 1.5, core: C(0xFF4030, 0.55), glow: C(0xFF2010, 0.12),
                   coreR: 0.3, glowR: 1)
    }
    eterniaMarchKnees(c, p.who)   // knees up, marching with the others (EterniaHabits.swift)
}
