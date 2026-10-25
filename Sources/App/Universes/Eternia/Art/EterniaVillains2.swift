import Foundation

// Villains: the rest of Skeleclawd's Evil Warriors, drawn the same way as EterniaVillains1.swift. Each is told apart
// by a colour pair and a head: Evil-Lynn's finned black skullcap, Beast Clawd's blue face in an orange-red mane, Trap
// Clawd's black helmet and steel jaw, Tri-Clawdps's drum of three eyes, Mer-Clawd's fish face and fins, Kobra Khan's
// yellow hood and Clawdful's red shell.

let eterniaVillains2: [EterniaVillain: Persona] = [
    .evilLynn: Persona(name: "Evil-Lynn", weapon: .lightning,
                       magic: Magic(core: C(0x8AF4E4), glow: C(0x3A62E8), jagged: false, spell: true),
                       pivot: (42.5, 14.5), headTop: 17, signature: 3.2, draw: drawEvilLynn),
    .beastClawd: Persona(name: "Beast Clawd", weapon: .saber, headTop: 20, signature: 3.0, draw: drawBeastClawd),
    .trapClawd: Persona(name: "Trap Clawd", weapon: .blaster, shot: .energy(core: C(0xFFF2A0), glow: C(0xFF8A1A)),
                        muzzle: (48, 33), handGun: false, headTop: 20, signature: 2.8, draw: drawTrapClawd),
    .triClawdps: Persona(name: "Tri-Clawdps", weapon: .saber, headTop: 19, signature: 3.4, draw: drawTriClawdps),
    .merClawd: Persona(name: "Mer-Clawd", weapon: .saber, headTop: 17, signature: 3.0, draw: drawMerClawd),
    .kobraKhan: Persona(name: "Kobra Khan", weapon: .lightning,
                        magic: Magic(core: C(0xE4FFE0), glow: C(0x4ACB7A), jagged: false, waves: true),
                        pivot: (41, 28), headTop: 17, signature: 3.0, draw: drawKobraKhan),
    .clawdful: Persona(name: "Clawdful", weapon: .saber, armoured: true, bulk: 4, headTop: 17, signature: 3.0,
                       draw: drawClawdful),
]

private let v2None = C(0, 0)

/// 0…1 eased in and out.
private func v2Ease(_ u: Double) -> Double { 0.5 - 0.5 * cos(min(1, max(0, u)) * .pi) }

/// A solid line one pixel or so wide from `a` to `b` (a whip's lash, a scabbard), with no glow.
private func v2Line(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ col: Px, r: Double = 0.55) {
    c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: v2None, coreR: r, glowR: r + 0.1)
}

/// A sword put away in its scabbard, hanging from the back of the belt behind the hip: black leather with a silver
/// tip, the hilt showing above it. Drawn before the body, so the body hides its top.
private func v2Scabbard(_ c: PixelCanvas, leather: Px, tip: Px, hilt: Px) {
    v2Line(c, (17.5, 36.5), (12.5, 41.5), leather, r: 0.9)
    c.rect(12, 41, 2, 1, tip)
    v2Line(c, (18.5, 35.0), (16.0, 37.5), hilt, r: 0.8)
}

// MARK: - Evil-Lynn

/// Evil-Lynn: Skeleclawd's sorceress, and the one of his crew with any brains. Pale skin under a black skullcap
/// that comes to a widow's peak on her brow, a little crest down its crown and two dark fins sweeping up off its
/// sides; a tall purple collar standing up behind her head, a blue bodice with a gold amulet, and a long purple robe
/// to the ground, the four legs hinted under it. Her staff is topped with a crystal orb in a gold cradle, and her magic
/// is a twinkling ribbon of teal and deep blue out of it. Signature: she gazes up into the orb, her eyes lit by it,
/// and the mist inside it swirls faster and glows, sparkles circling it.
private func drawEvilLynn(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xEADCC2), skinD = C(0xC6B494)
    let robe = C(0x6A3AA8), robeD = C(0x4A2478), robeL = C(0x8A5ACC)
    let blue = C(0x2E5AB8), blueD = C(0x1E3E88), blueL = C(0x4E7ADC)
    let cap = C(0x18161E), capL = C(0x3E3C4C), fin = C(0x2C2438), finL = C(0x6A5A8E)
    let gold = C(0xE0B040), goldL = C(0xFFE08A)
    let teal = C(0x7AF0E0), deep = C(0x2A4AC8)
    let s = p.signature ?? -1
    let gaze: Double = s > 0.08 && s < 0.92 ? min(1, (s - 0.08) / 0.15) * min(1, (0.92 - s) / 0.15) : 0

    drawLegs(c, Look(leg: blueD), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil), armRight: p.armRaise)

    // The bodice: blue between the purple robe's edges, lit on the left, the gold amulet on its chain.
    c.rect(18, 33, 20, 5, robe); c.rect(18, 33, 1, 5, robeL); c.rect(37, 33, 1, 5, robeD)
    c.rect(21, 33, 14, 5, blue); c.rect(21, 33, 1, 5, blueL); c.rect(34, 33, 1, 5, blueD)
    c.rect(21, 37, 14, 1, blueD)
    c.px(26, 33, gold); c.px(29, 33, gold)
    c.rect(27, 34, 2, 2, gold); c.px(27, 34, goldL)
    // The long robe: from the waist to the hem, flaring, a fold either side of each leg, lit on the left. It stops a
    // row short of the ground, so the toes peep out.
    for y in 38...43 where y + c.oy <= 42 {
        let flare = (y - 38) / 2
        c.rect(18 - flare, y, 20 + 2 * flare, 1, robe)
        c.px(18 - flare, y, robeL); c.px(37 + flare, y, robeD)
        if y >= 39 { for x in [22, 25, 30, 33] { c.px(x, y, robeD) } }
    }
    // The tall collar, standing up behind her head either side.
    c.pattern(16, 29, [
        "P......................P",
        "PP....................PP",
        "lPP..................PPd",
        "lPPPPPPPPPPPPPPPPPPPPPPd",
    ], ["P": robe, "l": robeL, "d": robeD])

    // The skullcap: a black dome over her crown, down to a widow's peak and over her temples, lit on the left, a
    // little crest down its middle and a fin sweeping up off each side.
    let finRows = [
        "F.....",
        "FF....",
        "lFF...",
        ".lFF..",
        ".lFFF.",
        "..lFFF",
        "..lFFF",
        "...lFF",
        "....lF",
    ]
    c.pattern(13, 17, finRows, ["F": fin, "l": finL])
    c.pattern(37, 17, finRows.map { String($0.reversed()) }, ["F": fin, "l": finL])
    c.rect(21, 21, 14, 1, cap); c.rect(19, 22, 18, 1, cap); c.rect(18, 23, 20, 5, cap)
    c.rect(27, 28, 2, 1, cap); c.rect(18, 28, 2, 2, cap); c.rect(36, 28, 2, 2, cap)
    c.rect(22, 21, 4, 1, capL); c.rect(20, 22, 3, 1, capL); c.rect(19, 23, 1, 2, capL)
    c.rect(27, 18, 2, 3, fin); c.px(27, 18, finL); c.px(27, 19, finL)
    // A thin gold rim round the cap's edge, so it reads as a cap and not hair.
    c.rect(20, 27, 7, 1, gold); c.rect(29, 27, 7, 1, gold); c.px(26, 28, gold); c.px(29, 28, gold)
    c.px(19, 28, gold); c.px(36, 28, gold); c.px(20, 27, goldL)

    // Her eyes, lit teal looking up into the orb while she gazes, and dark brows slanting down to the middle.
    if gaze > 0.3 {
        c.rect(23, 29, 2, 2, teal); c.rect(33, 29, 2, 2, teal)
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.px(21, 28, skinD); c.px(34, 28, skinD)

    // The staff: a dark shaft from the ground up past her hand to the gold cradle, the crystal orb held in it.
    let raise = p.armRaise
    let top = 12 - raise
    let shaft = C(0x3A2A5A), shaftL = C(0x5E4A8E)
    c.rect(41, top + 5, 2, 37 - top - (seatedPose ? 4 : 0), shaft); c.rect(41, top + 5, 1, 24, shaftL)
    let ox = 42.5, oy = Double(top) + 2.5
    if gaze > 0 {
        // The glow round the orb while she gazes into it, see-through, and sparkles circling it.
        c.glowLine(ox, oy, ox, oy, core: C(0xC8FFF4, 0), glow: C(0x4AB0FF), coreR: 0.2, glowR: 5, strength: 0.7 * gaze)
        for k in 0..<3 {
            let a = p.t * 3.2 + Double(k) * 2.094
            c.px(Int((ox + cos(a) * 5).rounded(.down)), Int((oy + sin(a) * 4.5).rounded(.down)), C(0xD8FFF8, 0.7 * gaze))
        }
    }
    c.pattern(39, top, [
        "..OOO..",
        ".OOOOO.",
        "GOOOOOG",
        "GOOOOOG",
        ".GOOOG.",
        "..GGG..",
    ], ["O": C(0x2A8A9E), "G": gold])
    c.px(41, top + 1, C(0xE8FFFC))
    // The mist inside it, turning slowly, faster as she gazes.
    let spin = p.t * (gaze > 0 ? 9 : 2.5)
    for k in 0..<2 {
        let a = spin + Double(k) * .pi
        let mx = 42 + Int((cos(a) * 1.4).rounded()), my = top + 2 + Int((sin(a) * 1.4).rounded())
        c.px(mx, my, k == 0 ? teal : deep)
    }
    c.px(42, top + 2, gaze > 0.3 ? C(0xE8FFFC) : C(0x4AB4C8))
    c.rect(40, 33 - raise, 3, 3, skin); c.px(42, 35 - raise, skinD)   // her hand round the shaft
}

// MARK: - Beast Clawd

/// Beast Clawd: Skeleclawd's brute, who talks to animals. Shaggy orange-red fur all over, a mane of it in strands
/// round a blue face with heavy brows and a pale blue snout; blue armour on his chest and wrists and blue boots, a
/// strap of a belt and a ragged dark fur loincloth. He fights with a whip, which hangs from his fist to the floor when
/// he isn't swinging it. Signature: he draws the whip back over his head, cracks it out in front of him with a spark
/// at the tip, and roars, his mouth wide and his fangs out, the roar rolling away in front of him.
private func drawBeastClawd(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xC8442A), furD = C(0x8A2A18), furL = C(0xEA7044)
    let face = C(0x5A78C8), faceD = C(0x3A54A0), faceL = C(0x88A2E4)
    let armour = C(0x2E3C96), armourD = C(0x1E2868), armourL = C(0x5262C8)
    let strap = C(0x3A2214)
    let s = p.signature ?? -1
    let roar = s > 0.42 && s < 0.88
    let sig: (angle: Double, trail: [Double])? = s >= 0.06 && s < 0.92 ? beastSignatureWhip(s) : nil
    let armUp = s > 0.1 && s < 0.4 ? 4 : 0

    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx + 1, bottom - 6, 1, 2, furD); c.px(lx, bottom - 7, furL)
            c.rect(lx, bottom - 2, 2, 3, armourD); c.rect(lx, bottom - 2, 2, 1, armour)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil), armRight: armUp)

    // The mane: strands of fur from a shaggy crown, down either side of his face, lit along the top, a ragged fringe
    // over his brow.
    for x in 16...39 {
        let d = abs(Double(x) - 27.5)
        let top = 20 + Int(d * d / 36) + x % 2
        let bottom = x < 18 || x > 37 ? 29 : x < 20 || x > 35 ? 31 : 26
        guard top <= bottom else { continue }
        c.rect(x, top, 1, bottom - top + 1, fur)
        if x % 3 == 0 { c.rect(x, top + 2, 1, bottom - top - 1, furD) }
        if x % 3 == 1 { c.px(x, top, furL) }
        if (x < 20 || x > 35) && x % 2 == 0 { c.px(x, bottom + 1, furD) }
    }
    // The blue face: heavy brows slanting down to the middle, the eyes under them, a paler snout and a dark nose; and
    // the mouth wide open while he roars.
    c.rect(20, 27, 16, 6, face); c.rect(20, 27, 1, 6, faceL); c.rect(35, 27, 1, 6, faceD)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 27, fur) }
    c.rect(21, 28, 3, 1, faceD); c.px(24, 29, faceD); c.rect(32, 28, 3, 1, faceD); c.px(31, 29, faceD)
    c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    c.rect(26, 31, 4, 1, faceL); c.rect(27, 31, 2, 1, faceD)
    if !roar { c.px(25, 32, white); c.px(30, 32, white) }   // his fangs, over his lip
    if roar {
        c.rect(24, 31, 8, 3, C(0x3A0E14))
        c.px(25, 31, white); c.px(30, 31, white); c.px(26, 33, white); c.px(29, 33, white)
    }

    // Blue armour across his chest, lit along the top, three studs; blue bracers; a strap of a belt over a ragged
    // dark fur loincloth.
    c.rect(18, 33, 20, 2, armour); c.rect(18, 33, 20, 1, armourL); c.rect(36, 33, 2, 2, armourD)
    if roar { c.rect(24, 33, 8, 1, C(0x3A0E14)); c.px(26, 33, white); c.px(29, 33, white) }
    for x in [21, 34] { c.px(x, 34, armourL) }
    eterniaFur(c, 18, 35, 20, 1, base: fur, dark: furD, light: furL, ragged: false)
    c.rect(18, 36, 20, 1, strap); c.px(27, 36, C(0x9A8A6A))
    eterniaFur(c, 18, 37, 20, 1, base: furD, dark: strap, light: fur)
    c.rect(15, 34, 3, 1, armour); c.rect(38, 34 - armUp, 3, 1, armour)

    // The roar, rolling away from him in pale arcs.
    if roar {
        for k in 0..<3 {
            let f = frac(p.t * 2.2 + Double(k) / 3)
            let x = 43 + Int(f * 14)
            let col = C(0xF4F0E8, 0.55 * (1 - f))
            for dy in -2...2 { c.px(x + (abs(dy) == 2 ? 0 : 1), 30 + dy, col) }
        }
    }

    // The whip, from his fist.
    let h = (x: eterniaHand.x, y: eterniaHand.y - Double(armUp))
    beastWhip(c, at: h, angle: sig?.angle ?? p.melee, trail: sig?.trail ?? p.trail,
              crack: s > 0.4 && s < 0.5, t: p.t)
    c.rect(Int(h.x) - 1, Int(h.y) - 1, 3, 3, fur); c.px(Int(h.x) - 1, Int(h.y) - 1, furL)
}

/// The whip in Beast Clawd's signature: drawn back up over his head (…0.36), cracked out in front (…0.44) and held
/// there, then let droop. Its angle and the swing's trail, as `Pose.trail` has them.
private func beastSignatureWhip(_ s: Double) -> (angle: Double, trail: [Double]) {
    func at(_ u: Double) -> Double {
        if u < 0.36 { return 60 - 220 * v2Ease((u - 0.06) / 0.3) }
        if u < 0.44 { let f = (u - 0.36) / 0.08; return -160 + 170 * (1 - pow(1 - f, 3)) }
        return 10 + 30 * v2Ease((u - 0.74) / 0.16)
    }
    let ds = 0.035 / 3.0
    let now = at(s), prev = at(s - ds)
    return (now, abs(now - prev) > 6 ? [prev, at(s - 2 * ds)] : [])
}

/// A leather whip from the fist `h`. Swung (`angle`), the lash leaves the fist that way and curls the way gravity
/// pulls it, or, in a fast swing, back the way it came, so the tip comes last, smeared behind; `crack` throws sparks
/// off the tip. Put away (nil), it hangs from the fist to the floor and trails along it.
private func beastWhip(_ c: PixelCanvas, at h: (x: Double, y: Double), angle: Double?, trail: [Double], crack: Bool,
                       t: Double) {
    let leather = C(0x6A3E1E), grip = C(0x2A1A10)
    let floor = Double(43 - c.oy)
    guard let a = angle else {
        let pts: [(x: Double, y: Double)] = [(42, 36), (43, 38.5), (43.5, 41), (45, 42.5), (47.5, 43), (50, 43), (52, 42.5)]
        for i in 1..<pts.count {
            v2Line(c, (pts[i - 1].x, min(pts[i - 1].y, floor)), (pts[i].x, min(pts[i].y, floor)), leather)
        }
        return
    }
    let fast = trail.count >= 2
    func lash(_ a: Double, lag: Double) -> [(x: Double, y: Double)] {
        var pts: [(x: Double, y: Double)] = [eterniaReach(h, a, 2)]
        var dir = a
        for _ in 0..<9 {
            let gravity: Double = 9 * cos(dir * .pi / 180)
            dir += fast ? max(-24, min(24, lag * 0.35)) : gravity
            var n = eterniaReach(pts[pts.count - 1], dir, 1.8)
            n.y = min(n.y, floor)
            pts.append(n)
        }
        return pts
    }
    let lag = fast ? trail[0] - a : 0
    if fast {
        for (i, ta) in trail.enumerated() {
            let ghost = lash(ta, lag: lag)
            for k in 1..<ghost.count {
                c.glowLine(ghost[k - 1].x, ghost[k - 1].y, ghost[k].x, ghost[k].y, core: C(0xF0E4D0), glow: C(0xF0E4D0),
                           coreR: 0.3, glowR: 1.2, strength: 0.22 / Double(i + 1))
            }
        }
    }
    eterniaBar(c, h, a, from: -2, to: 2, grip, r: 0.9)
    let pts = lash(a, lag: lag)
    for i in 1..<pts.count { v2Line(c, pts[i - 1], pts[i], leather, r: i > 6 ? 0.45 : 0.55) }
    if crack, let tip = pts.last {
        for k in 0..<6 {
            let r = Double(k) * 60 + 25 * noise(k + Int(t * 20))
            let u = eterniaReach(tip, r, 1.5), v = eterniaReach(tip, r, 3.5)
            c.glowLine(u.x, u.y, v.x, v.y, core: C(0xFFF4C0), glow: C(0xFFB030), coreR: 0.3, glowR: 1, strength: 0.8)
        }
    }
}

// MARK: - Trap Clawd

/// Trap Clawd: Skeleclawd's weapons man. Blue skin, a black helmet with a steel rim down over his ears, and a great
/// steel jaw bolted on in place of his own, its teeth meeting in a row; purple straps across his chest, a black belt
/// with a steel buckle, purple briefs and boots. His back arm ends in a steel hook, and his front one in a laser
/// cannon that fires orange-yellow bolts. Signature: he chomps his metal jaw open and shut, a dark maw behind it.
private func drawTrapClawd(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x4A90D8), skinD = C(0x3470B0), skinL = C(0x72B0F0)
    let helm = C(0x1E1E26), helmL = C(0x4A4C5E)
    let purple = C(0x7A3AA8), purpleD = C(0x56247E), purpleL = C(0x9A5ACC)
    let steel = C(0xB8BCC8), steelD = C(0x7C808E), steelL = C(0xE8EAF0)
    let maw = C(0x5A1418), strap = C(0x22202A)
    let s = p.signature ?? -1
    var open = 0
    if s > 0.08 && s < 0.92 {
        let ph = (s - 0.08) / 0.84 * 4
        open = Int(((0.5 - 0.5 * cos(ph * 2 * .pi)) * 3).rounded())
    }

    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, purpleD, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, 2, 1, purple) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(18, 32, 1, 3, skinL)

    // Purple straps across his chest, the black belt and its buckle, purple briefs.
    c.rect(18, 34, 20, 2, purple); c.rect(18, 34, 20, 1, purpleL); c.rect(36, 34, 2, 2, purpleD)
    c.rect(18, 36, 20, 1, strap); c.rect(27, 36, 2, 1, steel)
    c.rect(18, 37, 20, 1, purpleD)

    // The helmet: a black dome lit on the left, down over his ears either side, its steel rim across his brow.
    c.rect(22, 20, 12, 1, helm); c.rect(20, 21, 16, 1, helm); c.rect(19, 22, 18, 6, helm)
    c.rect(18, 28, 2, 4, helm); c.rect(36, 28, 2, 4, helm)
    c.rect(23, 20, 4, 1, helmL); c.rect(21, 21, 3, 1, helmL); c.rect(20, 22, 1, 3, helmL)
    c.rect(18, 27, 20, 1, steelD); c.rect(18, 27, 6, 1, steel)
    c.px(18, 29, steelD); c.px(37, 29, steelD)
    // His eyes, glaring under the rim.
    c.rect(22, 28, 2, 2, ink); c.rect(32, 28, 2, 2, ink)
    c.px(21, 28, skinD); c.px(34, 28, skinD)

    // The steel jaw: the upper row of teeth fixed under his eyes, the lower jaw on its bolts dropping open (`open`)
    // on a dark maw.
    c.rect(20, 30, 16, 1, steel); c.rect(20, 30, 16, 1, steelD)
    for x in stride(from: 21, through: 34, by: 2) { c.px(x, 31, steelL); c.px(x + 1, 31, steelD) }
    if open > 0 { c.rect(21, 32, 14, open, maw) }
    c.pattern(20, 32 + open, [
        "STsTsTsTsTsTsTsS",
        "SLSSSSSSSSSSSSSd",
        ".SSSSSSSSSSSSSd.",
    ], ["S": steel, "T": steelL, "s": steelD, "L": steelL, "d": steelD])
    c.px(20, 31, steelD); c.px(35, 31, steelD); c.px(20, 32 + open, C(0x5A5E6A)); c.px(35, 32 + open, C(0x5A5E6A))

    // The hook on his back arm: a steel cuff and a hook curling under it.
    c.rect(15, 33, 3, 2, steel); c.rect(15, 33, 3, 1, steelL)
    c.pattern(11, 35, [
        ".....SS",
        "......S",
        "T.....S",
        "S....Ss",
        ".SSSSs.",
    ], ["S": steel, "s": steelD, "T": steelL])

    // The laser cannon built onto his front arm: a steel cuff, a barrel and its glowing orange lens.
    c.oy += p.gunY
    c.rect(38, 32, 4, 4, steel); c.rect(38, 32, 4, 1, steelL); c.rect(38, 35, 4, 1, steelD); c.rect(40, 32, 1, 4, purple)
    c.rect(42, 32, 5, 3, steelD); c.rect(42, 32, 5, 1, steel)
    c.rect(47, 32, 1, 3, C(0xFF9A2A)); c.px(47, 33, C(0xFFE27A))
    c.oy -= p.gunY
}

// MARK: - Tri-Clawdps

/// Tri-Clawdps: Skeleclawd's lookout, who sees everything. Green armour from head to foot, black boots, a black belt
/// with a silver buckle; his green helmet carries a gunmetal drum round his head at eye level with three round lenses
/// set in it, gold, cyan and lime, two of them looking out of the front at a time. No red visor anywhere. He fights
/// with a sword, sheathed at his back hip when it's put away. Signature: the drum turns right round, its seams
/// sliding past, and each eye glows its own colour as it comes round to the front.
private func drawTriClawdps(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x3E8A3A), greenD = C(0x2A6428), greenL = C(0x62B456), plate = C(0x4E9E46)
    let drum = C(0x545866), drumD = C(0x30333C), drumL = C(0x8A8E9C)
    let black = C(0x1E1E24), silver = C(0xB4B8C4)
    let s = p.signature ?? -1
    let turning = s > 0.08 && s < 0.92
    let rot = 60 + (turning ? v2Ease((s - 0.08) / 0.84) * 360 : 0)

    if p.melee == nil { v2Scabbard(c, leather: black, tip: silver, hilt: silver) }
    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, black, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, C(0x44444E)) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenD, arm: green, eye: nil))

    // The chest plate, lit along the top with a seam down its middle and a rivet each side; the belt and buckle.
    c.rect(19, 33, 17, 3, plate); c.rect(19, 33, 17, 1, greenL); c.rect(27, 34, 1, 2, greenD)
    c.px(21, 34, greenL); c.px(33, 34, greenL)
    c.rect(18, 36, 20, 1, black); c.rect(27, 36, 2, 1, silver)
    c.rect(18, 37, 20, 1, greenD)

    // The helmet: a green dome lit on the left with a ridge down its crown.
    c.rect(23, 19, 10, 1, green); c.rect(21, 20, 14, 1, green); c.rect(20, 21, 16, 1, green); c.rect(19, 22, 18, 5, green)
    c.rect(24, 19, 3, 1, greenL); c.rect(22, 20, 2, 1, greenL); c.rect(20, 22, 1, 3, greenL); c.rect(36, 22, 1, 5, greenD)
    c.rect(27, 19, 2, 8, greenD); c.px(27, 19, plate)
    c.rect(19, 26, 18, 1, greenD)

    // The drum round his head at eye level: gunmetal, a lit rim along the top and a dark one under it, its seams
    // turning with it.
    c.rect(17, 27, 22, 5, drum); c.rect(17, 27, 22, 1, drumL); c.rect(17, 31, 22, 1, drumD)
    c.rect(17, 28, 1, 3, drumL); c.rect(38, 28, 1, 3, drumD)
    for k in 0..<6 {
        let a = (rot + 30 + Double(k) * 60) * .pi / 180
        guard cos(a) > 0.15 else { continue }
        c.rect(Int((27.5 + 10 * sin(a)).rounded(.down)), 28, 1, 3, drumD)
    }
    // The three eyes, round lenses set a third of the way round from each other: narrower as they turn away, gone
    // round the back, and glowing as they come round to the front while it turns.
    let lens: [(Px, Px)] = [(C(0xF0C030), C(0xFFF2A8)), (C(0x3AC8E8), C(0xD0F6FF)), (C(0x8AE03A), C(0xE6FFC4))]
    for i in 0..<3 {
        let a = (rot + Double(i) * 120) * .pi / 180
        let cs = cos(a)
        guard cs > -0.15 else { continue }
        let w = cs > 0.3 ? 3 : cs > 0.05 ? 2 : 1
        let cx = 27.5 + 5.5 * sin(a)
        let x0 = Int((cx - Double(w) / 2).rounded())
        c.rect(x0 - 1, 28, w + 2, 3, drumD)
        c.rect(x0, 28, w, 3, lens[i].0)
        if w == 3 { c.px(x0 + 1, 29, lens[i].1); c.px(x0, 28, lens[i].1) }
        if turning && cs > 0.8 {
            let g = (cs - 0.8) / 0.2
            c.glowLine(cx, 29.5, cx, 29.5, core: lens[i].1.alpha(0.9 * g), glow: lens[i].0, coreR: 1.1, glowR: 4,
                       strength: 0.8 * g)
        }
    }

    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: black, guardCol: silver, steel: C(0xC8CCD8), edge: white, length: 13,
                     pommel: greenD)
        let h = eterniaHand
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, green)   // his gauntlet round the grip
    }
}

// MARK: - Mer-Clawd

/// Mer-Clawd: the warlord of the ocean, a fish-man rather than a man. Teal-green scaly skin, a fishy face with big
/// round yellow eyes, gills on his cheeks and a wide down-turned mouth with two fangs; a blue-green crest of fin along
/// his crown and fanned fins either side of his head, lit along their spines. Blue armour on his chest and
/// shoulders, a dark belt with a gold buckle, blue boots. He fights with a sword, sheathed at his back hip when it's
/// put away. Signature: an orange fish leaps past behind him, up from the right in a spray of drops, over his head
/// and down on the left.
private func drawMerClawd(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x3AA88A), skinD = C(0x267A62), skinL = C(0x62CCA8)
    let finC = C(0x2A9AB4), finD = C(0x1C6A80), finL = C(0x7AD8E8)
    let blue = C(0x3A5AC8), blueD = C(0x2A3E98), blueL = C(0x6A8AE8)
    let gold = C(0xE0B040)
    let s = p.signature ?? -1

    if s > 0.1 && s < 0.9 { merLeap(c, (s - 0.1) / 0.8) }
    if p.melee == nil { v2Scabbard(c, leather: blueD, tip: gold, hilt: gold) }
    drawLegs(c, Look(leg: skin), step: p.step)
    drawBoots(c, blue, step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 40 : 41, blueL) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))

    // The fins either side of his head, fanned out from behind his cheeks, a lit spine and a dark one in turn.
    let fanL = [
        "F....",
        "FL...",
        "FdF..",
        "FFdLF",
        "dFFdF",
        ".FdFF",
        "..FFF",
    ]
    c.pattern(13, 23, fanL, ["F": finC, "L": finL, "d": finD])
    c.pattern(38, 23, fanL.map { String($0.reversed()) }, ["F": finC, "L": finL, "d": finD])
    // The crest along his crown, three lit spines and the fin between them, and the scaly dome of his head.
    c.pattern(22, 17, [
        ".L....L....L.",
        ".FL..FFL..FFL",
        "FFFLFFFFLFFFF",
        "dFFFFdFFFFdFF",
        ".dFFdFFFdFFd.",
    ], ["F": finC, "L": finL, "d": finD])
    c.rect(22, 22, 12, 1, skin); c.rect(20, 23, 16, 1, skin); c.rect(19, 24, 18, 2, skin)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 23, skinL); c.px(x + 1, 25, skinD) }
    c.rect(20, 24, 1, 2, skinL)

    // The fish face: big round yellow eyes in dark sockets, gills on his cheeks, the wide mouth turned down at the
    // corners with a fang either side.
    for ex in [20, 31] {
        c.rect(ex, 27, 5, 5, skinD)
        c.rect(ex + 1, 28, 3, 3, C(0xF4D84A)); c.px(ex + 1, 28, C(0xFFF2A0)); c.px(ex + 2, 29, ink)
    }
    for gy in [29, 31] { c.rect(18, gy, 1, 1, skinD); c.rect(36, gy, 1, 1, skinD) }
    c.rect(23, 32, 10, 1, C(0x123A30)); c.px(22, 33, C(0x123A30)); c.px(33, 33, C(0x123A30))
    c.px(25, 33, white); c.px(30, 33, white)

    // The blue armour: a breastplate lit along the top with a scale of arcs on it, pads on his shoulders; the belt.
    c.rect(19, 34, 18, 2, blue); c.rect(19, 34, 18, 1, blueL); c.rect(36, 34, 1, 2, blueD)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 35, blueD) }
    c.rect(15, 33, 3, 1, blue); c.rect(38, 33, 3, 1, blue)
    c.rect(18, 36, 20, 1, C(0x1E2A40)); c.rect(27, 36, 2, 1, gold)
    c.rect(18, 37, 20, 1, blueD)

    if let a = p.melee {
        eterniaSword(c, p, angle: a, grip: blueD, guardCol: gold, steel: C(0xB8D4D8), edge: white, length: 13,
                     pommel: gold)
        let h = eterniaHand
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, skin)   // his scaly fist round the grip
    }
}

/// The fish in Mer-Clawd's signature, `u` 0…1 of the way through its leap: up out of a splash on his right, over
/// his head and down into another on his left, nose up as it rises and down as it falls, a few drops trailing it.
/// Drawn before him, so it passes behind.
private func merLeap(_ c: PixelCanvas, _ u: Double) {
    let fx = 62 - u * 54, fy = 30 - sin(u * .pi) * 22
    // The splashes it leaves and lands in: pale drops thrown up, see-through.
    for (sx, su) in [(64.0, u), (10.0, 1 - u)] where su < 0.18 {
        let f = su / 0.18
        for k in 0..<4 {
            let dx = (Double(k) - 1.5) * (1 + 2 * f), dy = -2 - 4 * f * (k % 2 == 0 ? 1 : 0.6)
            c.px(Int(sx + dx), Int(34 + dy), C(0xBFE8FF, 0.7 * (1 - f)))
        }
    }
    for k in 1...3 {
        let uu = u - Double(k) * 0.035
        guard uu > 0 else { continue }
        c.px(Int(62 - uu * 54 + 6), Int(30 - sin(uu * .pi) * 22 + 1), C(0xBFE8FF, 0.75 - Double(k) * 0.18))
    }
    let tilt = u < 0.38 ? -1 : u > 0.62 ? 1 : 0
    let fish = [
        "..FLLF..t",
        ".KFFFFFtt",
        "FFFFFFFtt",
        ".ffff...t",
    ]
    let pal: [Character: Px] = ["F": C(0xF08A2A), "L": C(0xFFC060), "f": C(0xC05A1A), "t": C(0xE0702A), "K": ink]
    let x0 = Int(fx.rounded()), y0 = Int(fy.rounded())
    for (r, row) in fish.enumerated() {
        for (col, ch) in row.enumerated() {
            guard let px = pal[ch] else { continue }
            let shear = Int(((Double(col) - 4) / 3 * Double(-tilt)).rounded())
            c.px(x0 + col, y0 + r + shear, px)
        }
    }
}

// MARK: - Kobra Khan

/// Kobra Khan: the snake man who puts his foes to sleep. Bright green scaly skin, red slit eyes, and a great yellow
/// cobra hood standing up behind his head, ribbed in amber; a pale scaled belly, dark red bracers and belt with a
/// gold buckle, green boots. His magic is a pale green sleep mist pulsing out of his hood. Signature: his hood flares
/// open wide and he hisses, his forked tongue flicking.
private func drawKobraKhan(_ c: PixelCanvas, _ p: Pose) {
    let green = C(0x5AC83A), greenD = C(0x3A9A2A), greenL = C(0x8EE860)
    let hood = C(0xF0C830), hoodD = C(0xC8901E), hoodL = C(0xFFEA80), hoodR = C(0xD86A1E)
    let belly = C(0xE0EC8A), bellyD = C(0xB4C45A)
    let red = C(0x9A2A1E), redL = C(0xC84A3A)
    let s = p.signature ?? -1
    let flare: Double = s > 0.06 && s < 0.94 ? min(1, (s - 0.06) / 0.14) * min(1, (0.94 - s) / 0.18) : 0
    let hiss = s > 0.25 && s < 0.8

    // The hood, behind his head: rounded at the top, widest about his brow, narrowing to his neck, wider and taller
    // as it flares. Lit on the left, its rim dark, ribs fanning out across it.
    let top = 17 - Int((3 * flare).rounded())
    let hw = 13.0 + 5 * flare, cx = 27.5
    func half(_ y: Int) -> Double {
        let t = Double(y - top) / Double(34 - top)
        let prof: Double = t < 0.55 ? 0.45 + 0.55 * sqrt(t / 0.55) : 1 - (t - 0.55) / 0.45 * 0.3
        return max(2, hw * prof)
    }
    c.oy += p.breathe
    for y in top...34 {
        let hh = half(y)
        let x0 = Int((cx - hh).rounded()), x1 = Int((cx + hh).rounded()) - 1
        c.rect(x0, y, x1 - x0 + 1, 1, hood)
        c.px(x0, y, hoodL); c.px(x1, y, hoodD)
        if y > top + 1 { c.px(x0 + 1, y, hoodR); c.px(x1 - 1, y, hoodR) }
    }
    for a in [-160.0, -132, -106, -74, -48, -20] {
        let r = a * .pi / 180
        var d = 8.0
        while d < 20 {
            let x = cx + cos(r) * d, y = 29 + sin(r) * d * 0.9
            let yi = Int(y.rounded(.down))
            if yi >= top + 1 && abs(x - cx) < half(yi) - 1.5 { c.px(Int(x.rounded(.down)), yi, hoodD) }
            d += 1
        }
    }
    c.oy -= p.breathe

    drawLegs(c, Look(leg: green), step: p.step)
    drawBoots(c, greenD, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx, p.step >= 0 && i % 2 == p.step ? 38 : 39, greenL) }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: green, shade: greenD, arm: green, eye: nil), armRight: p.armRaise)

    // His snake's head, rounded up in front of the hood, and scales on his crown: short strokes, lit and dark in turn.
    c.rect(23, 22, 10, 1, green); c.rect(21, 23, 14, 1, green); c.rect(19, 24, 18, 2, green)
    c.rect(24, 22, 3, 1, greenL); c.rect(20, 24, 1, 2, greenL); c.rect(36, 24, 1, 2, greenD)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 24, greenL); c.px(x + 1, 25, greenD) }
    for x in stride(from: 20, through: 35, by: 3) { c.px(x, 26, greenL); c.px(x + 1, 27, greenD) }
    c.rect(18, 26, 1, 6, greenL)
    // Red slit eyes, and two nostrils.
    for ex in [21, 32] { c.rect(ex, 29, 3, 3, C(0xE0402A)); c.rect(ex + 1, 29, 1, 3, ink); c.px(ex, 29, C(0xFF8A6A)) }
    c.px(26, 32, greenD); c.px(29, 32, greenD)

    // The scaled belly, in bands; red bracers and belt with a gold buckle.
    for y in 33...37 { c.rect(22, y, 12, 1, y % 2 == 0 ? belly : bellyD) }
    if hiss && Int(p.t * 8) % 2 == 0 {   // the forked tongue, flicking out over his belly
        let tongue = C(0xE83A5A)
        c.rect(27, 33, 2, 2, tongue); c.px(26, 35, tongue); c.px(29, 35, tongue)
    }
    c.rect(21, 33, 1, 5, greenD)
    c.rect(18, 36, 20, 1, red); c.rect(18, 36, 4, 1, redL); c.rect(27, 36, 2, 1, C(0xE0B040))
    c.rect(15, 34, 3, 1, red); c.rect(38, 34 - p.armRaise, 3, 1, red)
}

// MARK: - Clawdful

/// Clawdful: a great red crab of a warrior in yellow boots. A broad red shell over his whole body, lit along its
/// spiny top and shaded underneath, a pale belly plate in segments below it, two black eyes on stalks over it; a huge
/// pincer on each arm, the front one his weapon, the back one held up. Signature: he lifts both pincers and snaps them
/// open and shut, a spark at the front one as it clacks.
private func drawClawdful(_ c: PixelCanvas, _ p: Pose) {
    let shell = C(0xD8362A), shellD = C(0x9E2018), shellL = C(0xF2664A)
    let belly = C(0xF0A060), bellyD = C(0xC87840)
    let boot = C(0xF0C830), bootD = C(0xC09A1E), bootL = C(0xFFE878)
    let s = p.signature ?? -1
    let snapping = s > 0.08 && s < 0.92
    let up: Double = snapping ? min(1, (s - 0.08) / 0.12) * min(1, (0.92 - s) / 0.12) : 0
    let snap: Double = snapping ? 0.5 + 0.5 * cos((s - 0.08) / 0.84 * 5 * 2 * .pi) : 0.3
    let open: Double = snapping ? 26 - 22 * up + 40 * snap * up : 26

    drawLegs(c, Look(leg: shellD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 3, 2, 4, boot); c.rect(lx, bottom - 3, 2, 1, bootL); c.rect(lx + 1, bottom - 1, 1, 2, bootD)
        }
    }
    c.oy += p.breathe

    // The back pincer, held up behind him.
    let back = (x: 16.0, y: 32.0 - up * 3)
    clawdfulPincer(c, at: back, angle: -132 - up * 12, open: open, trail: [], shell: shell, dark: shellD, lit: shellL)

    // The shell: broad and rounded, spines along its top, lit along the top and the near side and shaded on the far
    // side and underneath, a few dark ridges across it.
    let widths = [9, 11, 12, 13, 13, 13, 13, 13, 13, 13, 12, 11]
    for (i, hw) in widths.enumerated() {
        let y = 23 + i
        c.rect(28 - hw, y, 2 * hw, 1, shell)
        c.px(28 - hw, y, shellL); c.px(27 + hw, y, shellD)
    }
    c.rect(20, 23, 14, 1, shellL); c.rect(17, 24, 4, 1, shellL)
    for x in [19, 24, 31, 36] { c.px(x, 22, shell) }
    c.px(19, 22, shellL); c.px(24, 22, shellL)
    c.rect(16, 33, 24, 1, shellD); c.rect(17, 34, 22, 1, shellD)
    c.pattern(19, 27, [
        "dd..............dd",
        "..d............d..",
    ], ["d": shellD])
    c.rect(25, 29, 6, 1, shellD); c.px(24, 30, shellD); c.px(31, 30, shellD)
    // The belly plate under it, in segments.
    c.rect(20, 35, 16, 3, belly); c.rect(20, 36, 16, 1, bellyD); c.rect(35, 35, 1, 3, bellyD)
    // The eyes on their stalks, black with a glint, wobbling while he snaps.
    let wob = snapping && Int(p.t * 10) % 2 == 0 ? 1 : 0
    c.rect(22, 19, 1, 4, shellD); c.rect(33, 19, 1, 4, shellD)
    c.rect(21 - wob, 17, 3, 3, ink); c.px(21 - wob, 17, white)
    c.rect(32 + wob, 17, 3, 3, ink); c.px(32 + wob, 17, white)

    // The front pincer: his weapon, raised for the signature.
    let h = (x: eterniaHand.x, y: eterniaHand.y - up * 4)
    let a = snapping ? -40 - 20 * up : p.melee ?? -25
    clawdfulPincer(c, at: h, angle: a, open: open, trail: snapping ? [] : p.trail, shell: shell, dark: shellD, lit: shellL)
    if snapping && snap < 0.12 && up > 0.5 {
        let tip = eterniaReach(h, a, 11)
        for k in 0..<4 {
            let u = eterniaReach(tip, Double(k) * 90 + 45, 1.5), v = eterniaReach(tip, Double(k) * 90 + 45, 3)
            c.glowLine(u.x, u.y, v.x, v.y, core: C(0xFFF8E0), glow: C(0xFFD060), coreR: 0.3, glowR: 1, strength: 0.8)
        }
    }
}

/// A crab's pincer on an arm from `h` at `angle` degrees: a short forearm, a fat palm, a fixed lower finger and a
/// moving upper one `open` degrees apart, lit along the palm. A fast swing leaves a smear (`trail`).
private func clawdfulPincer(_ c: PixelCanvas, at h: (x: Double, y: Double), angle a: Double, open: Double,
                            trail: [Double], shell: Px, dark: Px, lit: Px) {
    for (i, t) in trail.enumerated() {
        let p0 = eterniaReach(h, t, 4), p1 = eterniaReach(h, t, 12)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xFFE8E0), glow: C(0xFFE8E0), coreR: 0.6, glowR: 2,
                   strength: 0.28 / Double(i + 1))
    }
    eterniaBar(c, h, a, from: -2, to: 3, dark, r: 1.3)
    eterniaBar(c, h, a, from: 3, to: 6.5, shell, r: 2.5)
    let j = eterniaReach(h, a, 6)
    eterniaBar(c, j, a + open * 0.5, from: 0, to: 7, dark, r: 1.4)
    eterniaBar(c, j, a - open * 0.5, from: 0, to: 8, shell, r: 1.4)
    eterniaBar(c, j, a - open * 0.5, from: 5.5, to: 8.5, lit, r: 0.6)
    let l0 = eterniaReach(eterniaReach(h, a - 90, 1.6), a, 3.5), l1 = eterniaReach(eterniaReach(h, a - 90, 1.6), a, 7)
    v2Line(c, l0, l1, lit, r: 0.5)
}
