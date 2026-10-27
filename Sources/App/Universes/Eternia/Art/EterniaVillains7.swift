import Foundation

// Villains: the other foes of Eternia (King Hiss, Count Marzo, Shokoti) and Jitsu, Skeleclawd's martial artist,
// drawn the same way as EterniaVillains1.swift. Each is told apart by a colour pair and a head: King Hiss's gold cobra
// crown over a pale human mask, Count Marzo's bald dome and big red beard, Shokoti's blue skin and horned bronze headdress, and
// Jitsu's black topknot and orange headband, with the huge gold hand held up beside him.

let eterniaVillains7: [EterniaVillain: Persona] = [
    .kingHiss: Persona(name: "King Hiss", weapon: .saber, headTop: 15, signature: 3.6, draw: drawKingHiss),
    .countMarzo: Persona(name: "Count Marzo", weapon: .lightning,
                         magic: Magic(core: C(0xFFA83A), glow: C(0xB0101A)),
                         pivot: (43, 35), headTop: 20, signature: 3.2, draw: drawCountMarzo),
    .shokoti: Persona(name: "Shokoti", weapon: .lightning,
                      magic: Magic(core: C(0xFFCC2A), glow: C(0xC0701A), jagged: false),
                      headTop: 16, signature: 3.6, draw: drawShokoti),
    .jitsu: Persona(name: "Jitsu", weapon: .saber, headTop: 17, signature: 3.4, draw: drawJitsu),
]

private let v7None = C(0, 0)

/// 0…1 eased in and out.
private func v7Ease(_ u: Double) -> Double { 0.5 - 0.5 * cos(min(1, max(0, u)) * .pi) }

/// A solid line from `a` to `b`, `r` from its centre (a snake's neck, a sleeve, a plank), with no glow.
private func v7Line(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), _ col: Px, r: Double = 0.8) {
    c.glowLine(a.x, a.y, b.x, b.y, core: col, glow: v7None, coreR: r, glowR: r + 0.1)
}

// MARK: - King Hiss

/// King Hiss: the ancient king of the Snake Men, hiding in a man's shape. A pale lilac human face with yellow slit
/// eyes under slicked-back dark hair and a gold crown, a gold cobra rearing up from its front with ruby eyes; purple
/// armour trimmed in gold, a gold belt, and a fringe of five green snake heads hanging from it all round his waist,
/// red-eyed, their tongues flicking. His legs are plain dark purple greaves into purple boots. He fights with snake bites: a green
/// snake coils round his forearm and strikes from his fist, jaws wide. Signature: his human face splits down the middle
/// and its two halves peel back and curl up against the sides of his head (inside its outline, rolled pale lips, not
/// flaps), and three green snakes rise hissing out of the dark where it was, then the mask closes over them again.
private func drawKingHiss(_ c: PixelCanvas, _ p: Pose) {
    let purple = C(0x7A2E9E), purpleD = C(0x561E74), purpleL = C(0xA04EC4)
    let gold = C(0xE8B830), goldD = C(0xA87A18), goldL = C(0xFFE27A)
    let skin = C(0xD8C4DA), skinD = C(0xA88EB0), skinL = C(0xF2E4F2)
    let snake = C(0x3E9A44), snakeD = C(0x266A2E), snakeL = C(0x74CC64)
    let red = C(0xE8342A), maw = C(0x2A0E24), tongue = C(0xF0507A)
    let hair = C(0x2A1E36), hairL = C(0x4E3E62)
    let s = p.signature ?? -1
    let peel = s > 0.05 && s < 0.95 ? habitArc((s - 0.05) / 0.9, hold: 0.45) : 0
    let open = Int((peel * 7).rounded())
    let flick = Int(p.t * 6) % 3 == 0

    // Plain dark purple greaves into purple boots lit at the toe: kept quiet, so the green snakes hanging over them
    // stand out.
    drawLegs(c, Look(leg: purpleD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 1, 2, 2, purple); c.px(lx, bottom, purpleL)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: purple, eye: nil))

    // The purple armour, gold along its top and in a V down the front, scales pressed into it; gold bracers.
    c.rect(18, 33, 20, 3, purple); c.rect(18, 33, 20, 1, gold); c.rect(18, 33, 5, 1, goldL)
    c.rect(18, 34, 1, 2, purpleL); c.rect(37, 33, 1, 3, purpleD)
    c.px(25, 34, gold); c.px(30, 34, gold); c.rect(26, 35, 4, 1, gold)
    for x in stride(from: 20, through: 35, by: 3) where x < 25 || x > 30 { c.px(x, 35, purpleD) }
    c.rect(15, 35, 3, 1, gold); c.px(15, 35, goldL)
    // The gold belt, and the five snake heads hanging from it round his waist, red-eyed, tongues flicking in turn.
    c.rect(18, 36, 20, 1, goldD)
    for x in stride(from: 18, through: 37, by: 2) { c.px(x, 36, gold) }
    for (i, x) in [18, 22, 26, 30, 34].enumerated() {
        c.rect(x, 37, 3, 2, snake); c.px(x, 37, snakeL); c.px(x + 1, 39, snakeD)
        c.px(x, 38, red); c.px(x + 2, 38, red)
        if flick && i % 2 == Int(p.t * 2) % 2 { c.px(x + 1, 40, tongue) }
    }

    // Slicked-back dark hair in strands, and the gold crown: a band across his brow, a spike at either temple and the
    // cobra rearing up from its front, its hood spread, ruby eyes.
    c.rect(23, 21, 10, 1, hair); c.rect(21, 22, 14, 1, hair); c.rect(19, 23, 18, 1, hair)
    for x in stride(from: 21, through: 34, by: 3) { c.px(x, 22, hairL); c.px(x + 1, 23, hairL) }
    c.rect(18, 24, 20, 2, gold); c.rect(18, 24, 8, 1, goldL); c.rect(18, 25, 20, 1, goldD); c.rect(18, 24, 1, 2, goldL)
    c.px(21, 24, snakeL); c.px(34, 24, snakeL)
    c.pattern(18, 21, ["S................S", "SS..............SS", ".S..............S."], ["S": gold])
    c.pattern(24, 15, [
        "...GG...",
        "..GLGG..",
        ".GGGGGG.",
        "GGRGGRGG",
        "GGGddGGG",
        ".GGddGG.",
        "..GGGG..",
        "...GG...",
        "..GGGG..",
    ], ["G": gold, "L": goldL, "R": red, "d": goldD])

    if open == 0 {
        // The human face: yellow slit eyes under brows slanting down to the middle, a thin hard mouth.
        for ex in [22, 32] { c.rect(ex, 29, 2, 3, C(0xF0D040)); c.rect(ex + 1, 29, 1, 3, ink) }
        c.rect(21, 28, 3, 1, skinD); c.px(24, 28, skinD); c.rect(32, 28, 3, 1, skinD); c.px(31, 28, skinD)
        c.rect(26, 32, 4, 1, skinD)
        c.px(19, 27, skinL)
    } else {
        // The face peeled open on the dark inside him, three snakes rising hissing out of it, the mask's two halves
        // peeled back and curled up against the sides of his head, never past its edge.
        c.rect(18, 26, 20, 7, maw)
        let w = max(2, 10 - open - 1)
        // Each half: the pale skin narrowing as it rolls back, its inner edge a lit rolled lip, a torn notch in it.
        c.rect(18, 26, w, 7, skin); c.rect(18, 26, 1, 7, skinD)
        c.rect(18 + w - 1, 26, 1, 7, skinL); c.px(18 + w - 1, 29, skinD); c.px(18 + w - 1, 32, skinD)
        c.rect(38 - w, 26, w, 7, skin); c.rect(37, 26, 1, 7, skinD)
        c.rect(38 - w, 26, 1, 7, skinL); c.px(38 - w, 28, skinD); c.px(38 - w, 31, skinD)
        if w >= 6 {
            c.rect(22, 29, 2, 3, C(0xF0D040)); c.rect(23, 29, 1, 3, ink)
            c.rect(32, 29, 2, 3, C(0xF0D040)); c.rect(33, 29, 1, 3, ink)
        }
        let rise = Int((peel * 2).rounded())
        for (k, hx) in [21, 26, 31].enumerated() {
            let top = (k == 1 ? 28 : 29) - rise
            c.rect(hx + 1, top + 3, 2, 33 - top - 3, snakeD)
            c.rect(hx, top, 4, 3, snake); c.rect(hx, top, 2, 1, snakeL); c.px(hx + 3, top + 2, snakeD)
            c.px(hx, top + 1, red); c.px(hx + 3, top + 1, red)
            if flick || k == 1 && Int(p.t * 5) % 2 == 0 { c.px(hx + 1, top - 1, tongue); c.px(hx + 2, top - 1, tongue) }
        }
    }

    // The snake on his front arm: coiled round the forearm, and rearing up from his fist (lowered out of the way
    // while his face is open), or striking when he fights.
    let angle = hissKeepUp(p.melee ?? (open > 0 ? 25 : -72))
    hissSnake(c, at: eterniaHand, angle: angle, trail: p.melee == nil ? [] : p.trail.map(hissKeepUp), bite: p.melee != nil,
              t: p.t, snake: snake, dark: snakeD, lit: snakeL, eye: red, tongue: tongue)
    c.rect(38, 33, 3, 1, snake); c.rect(38, 35, 3, 1, snake); c.px(40, 34, snakeD); c.px(38, 33, snakeL)
}

/// A strike's angle kept above the ground: the snake is long, so a swing down past about 28 degrees either side of
/// straight down would bury its head in the floor.
private func hissKeepUp(_ a: Double) -> Double {
    var a = a.truncatingRemainder(dividingBy: 360)
    if a > 180 { a -= 360 } else if a <= -180 { a += 360 }
    if a > 28 && a <= 90 { return 28 }
    if a > 90 && a < 152 { return 152 }
    return a
}

/// King Hiss's snake, from his fist `h` at `angle` degrees: a green neck in a gentle S, a fat head with a lit crown, a
/// red eye and jaws that open wide to bite (`bite`), fangs out; resting, it flicks its tongue. A fast strike leaves a
/// smear (`trail`).
private func hissSnake(_ c: PixelCanvas, at h: (x: Double, y: Double), angle a: Double, trail: [Double], bite: Bool,
                       t: Double, snake: Px, dark: Px, lit: Px, eye: Px, tongue: Px) {
    for (i, ta) in trail.enumerated() {
        let p0 = eterniaReach(h, ta, 3), p1 = eterniaReach(h, ta, 13)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xE8FFE0), glow: C(0xE8FFE0), coreR: 0.6, glowR: 1.8,
                   strength: 0.28 / Double(i + 1))
    }
    let mid = eterniaReach(eterniaReach(h, a, 5), a - 90, 1.2)
    let neck = eterniaReach(h, a, 9)
    v7Line(c, eterniaReach(h, a, 1), mid, snake, r: 1.0)
    v7Line(c, mid, neck, snake, r: 1.0)
    v7Line(c, eterniaReach(eterniaReach(h, a, 2), a + 90, 0.8), eterniaReach(eterniaReach(h, a, 4.5), a + 90, 0.2), dark, r: 0.4)
    eterniaBar(c, h, a, from: 9, to: 12.5, snake, r: 1.7)
    eterniaBar(c, eterniaReach(h, a - 90, 1.1), a, from: 9.5, to: 12, lit, r: 0.45)
    let e = eterniaReach(eterniaReach(h, a, 10.8), a - 90, 0.8)
    c.px(Int(e.x.rounded(.down)), Int(e.y.rounded(.down)), eye)
    let jaw = eterniaReach(h, a, 12)
    let gape = bite ? 28.0 : 10
    eterniaBar(c, jaw, a - gape, from: 0, to: 3.2, snake, r: 0.8)
    eterniaBar(c, jaw, a + gape, from: 0, to: 2.6, dark, r: 0.7)
    if bite {
        let f = eterniaReach(jaw, a - gape + 12, 3.2)
        c.px(Int(f.x.rounded(.down)), Int(f.y.rounded(.down)) + 1, white)
    } else if Int(t * 4) % 3 == 0 {
        let q0 = eterniaReach(jaw, a, 1.5), q1 = eterniaReach(jaw, a, 3.5)
        v7Line(c, q0, q1, tongue, r: 0.4)
    }
}

// MARK: - Count Marzo

/// Count Marzo: the wicked old sorcerer of the pilot, made young by evil and turned back into a little old man by the
/// end of it. A bald, wrinkled dome with a fringe of red hair round its sides, bushy red brows over beady eyes, a big
/// nose and a great red beard and moustache spreading over his chest; a long wine-red robe to the ground (a red-purple
/// well away from Evil-Lynn's violet) with black-edged gold cuffs and a black band above its gold hem, and his amulet, a blood-orange stone in a gold setting, on its chain below his beard. When he casts
/// he holds the amulet out in front of him, and short crackling forks of orange and blood red jump out of it.
/// Signature: he brings both hands in over the amulet and rubs them greedily, and it glows hot, sparks rising off it.
private func drawCountMarzo(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0x7E1838), robeD = C(0x520C22), robeL = C(0xA8304E)
    let gold = C(0xD8A830), goldL = C(0xFFDC7A), goldD = C(0x9A7418)
    let skin = C(0xE8C0A0), skinD = C(0xC0906E), skinL = C(0xFFDCC0)
    let beard = C(0xC8401E), beardD = C(0x8A2A12), beardL = C(0xEA6E3A)
    let gem = C(0xFF7A1E), gemL = C(0xFFE0A0), gemD = C(0xB8301A)
    let trim = C(0x1A0A10)
    let s = p.signature ?? -1
    let rub: Double = s > 0.06 && s < 0.94 ? habitArc((s - 0.06) / 0.88, hold: 0.6) : 0
    let raise = p.armRaise
    let held = raise > 0 && rub == 0

    drawLegs(c, Look(leg: robeD), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: robe, eye: nil), armRight: raise)

    // The robe: wine-red from the shoulders down, lit on the left; the long skirt flaring to a gold hem a row off the
    // ground, a shadow either side of each leg under it.
    c.rect(18, 33, 20, 5, robe); c.rect(18, 33, 1, 5, robeL); c.rect(37, 33, 1, 5, robeD)
    for y in 38...43 where y + c.oy <= 42 {
        let flare = (y - 38) / 2
        c.rect(18 - flare, y, 20 + 2 * flare, 1, robe)
        c.px(18 - flare, y, robeL); c.px(37 + flare, y, robeD)
        if y >= 39 { for x in [22, 25, 30, 33] { c.px(x, y, robeD) } }
        if y + c.oy == 41 { c.rect(19 - flare, y, 18 + 2 * flare, 1, trim) }
        if y + c.oy == 42 { c.rect(19 - flare, y, 18 + 2 * flare, 1, gold); c.rect(19 - flare, y, 3, 1, goldL) }
    }
    // the gold cuffs, edged in black
    c.rect(15, 35, 3, 1, gold); c.rect(15, 36, 3, 1, trim); c.rect(38, 35 - raise, 3, 1, gold); c.rect(38, 36 - raise, 3, 1, trim)

    // The bald dome, wrinkled across the brow and shining on top, the fringe of red hair round its sides in strands.
    c.rect(23, 20, 10, 1, skin); c.rect(21, 21, 14, 1, skin); c.rect(19, 22, 18, 4, skin)
    c.rect(24, 20, 3, 1, skinL); c.rect(22, 21, 3, 1, skinL); c.px(20, 22, skinL)
    c.rect(36, 22, 1, 4, skinD)
    c.rect(23, 24, 4, 1, skinD); c.rect(29, 24, 4, 1, skinD); c.rect(25, 25, 6, 1, skinD)
    c.pattern(16, 25, [
        "lHhH................HhHH",
        "lHhH................HhHH",
        ".lHh................hHH.",
        ".lHh................hHH.",
        "..H..................H..",
    ], ["H": beard, "h": beardD, "l": beardL])
    c.rect(18, 24, 1, 1, beard); c.rect(37, 24, 1, 1, beard)
    // Bushy red brows slanting up at the outer ends, beady eyes, the big nose.
    c.pattern(20, 27, [
        "BBB.........BBB.",
        ".bBB.......BBb..",
    ], ["B": beard, "b": beardD])
    c.rect(22, 29, 2, 2, ink); c.rect(32, 29, 2, 2, ink); c.px(22, 29, white); c.px(32, 29, white)
    c.rect(27, 28, 2, 3, skinD); c.rect(26, 30, 4, 1, skinD); c.px(27, 28, skinL)

    // The beard: a great red spread from his sideburns and the moustache under his nose down over his chest to a
    // point, in strands, lit on the left.
    c.pattern(18, 31, [
        "B.......llll.......B",
        "BB...BBBBBBBBBB...BB",
        "BBBBBBBdBBBBdBBBBBBB",
        ".BlBBdBBBlBBBdBBBBB.",
        "..BlBBBdBBBBdBBBBB..",
        "....BBBBBdBBBBBB....",
        ".......BBBBBB.......",
    ], ["B": beard, "l": beardL, "d": beardD])
    c.px(20, 34, beardL)

    // The amulet: on its chain below his beard, or held out in front of him in his raised fist while he casts.
    func amulet(_ x: Int, _ y: Int, hot: Bool) {
        c.pattern(x, y, [
            ".GG.",
            "GOOG",
            "GoOG",
            ".GG.",
        ], ["G": gold, "O": hot ? gemL : gem, "o": hot ? gem : gemD])
        c.px(x + 1, y, goldL)
    }
    if held {
        c.rect(39, 32 - raise, 2, 2, skin); c.px(40, 32 - raise, skinL)
        c.px(41, 33 - raise, goldD); c.px(42, 33 - raise, gold)
        amulet(41, 34 - raise, hot: true)
        // the chain from his neck, slack now, gone into the beard
        c.px(36, 35, goldD)
    } else {
        if rub > 0 {
            // Glowing hot while he rubs it: a see-through warmth round it and sparks drifting up.
            let pulse = 0.6 + 0.4 * sin(p.t * 9)
            c.glowLine(28.5, 39, 28.5, 39, core: C(0xFFE0A0, 0), glow: C(0xFF6A1E), coreR: 0.2, glowR: 5,
                       strength: 0.75 * rub * pulse)
            for k in 0..<4 {
                let f = frac(p.t * 1.4 + Double(k) / 4)
                let x = 28 + Int((sin(p.t * 3 + Double(k) * 1.7) * 3).rounded()), y = 37 - Int(f * 12)
                c.px(x, y, (k % 2 == 0 ? C(0xFFC860) : C(0xFF4A1E)).alpha(rub * (1 - f)))
            }
        }
        c.px(25, 37, goldD); c.px(32, 37, goldD)
        amulet(27, 37, hot: rub > 0.3 && Int(p.t * 8) % 2 == 0)
    }

    if rub > 0 {
        // Both hands brought in to the amulet under his beard, rubbing up and down against each other, his sleeves
        // drawn in from his shoulders below the beard.
        let r = Int((rub * 2).rounded())
        let w = Int((sin(p.t * 14) * 1.2).rounded())
        let lx = 20 + r, rx = 33 - r
        v7Line(c, (16.5, 35.5), (Double(lx), 38.5 + Double(w)), robeL, r: 1.2)
        v7Line(c, (39.0, 35.5), (Double(rx) + 2, 38.5 - Double(w)), robeL, r: 1.2)
        c.rect(lx + 1, 38 + w, 3, 2, skin); c.px(lx + 1, 38 + w, skinL)
        c.rect(rx, 38 - w, 3, 2, skin); c.px(rx + 2, 39 - w, skinD)
    }
}

// MARK: - Shokoti

/// Shokoti: the witch of the House of Darkness, as in the cartoon. Pale blue skin, blank white eyes under dark lids
/// and two little fangs; long thick black hair falling past her shoulders; a bronze headdress, a band across her brow
/// with a crescent standing on it and two horns curving up and out from its ends; a black leotard trimmed in purple
/// with a bone skull for a buckle, purple gloves and boots, and a red cape hanging behind her. Her magic is a
/// wavering gold ray in a deep amber glow (a black glow read as gaps on a dark desktop). Signature: she raises both
/// arms high, her cape spreads out behind her like wings, and her blank eyes blaze white.
private func drawShokoti(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x9CC0E8), skinD = C(0x6A8EBE)
    let hair = C(0x16141C), hairL = C(0x3A3648)
    let bronze = C(0xC08A44), bronzeL = C(0xEAC07A), bronzeD = C(0x7A5424)
    let suit = C(0x1C1622), trim = C(0x7A44AA), glove = C(0x5A2A8A), boot = C(0x3A1E58)
    let cape = C(0xC0202A), capeL = C(0xE84A4E), capeD = C(0x7A1218)
    let bone = C(0xEEE6D8)
    let s = p.signature ?? -1
    let up: Double = s > 0.04 && s < 0.96 ? habitArc((s - 0.04) / 0.92, hold: 0.55) : 0
    let blaze = up > 0.6 ? (up - 0.6) / 0.4 * (0.8 + 0.2 * sin(p.t * 12)) : 0
    let raise = p.armRaise

    // The red cape behind her, out past her sides and down to her heels, its edges swaying; spread wide like wings
    // while she raises her arms.
    let last = min(41, 43 - c.oy)
    if last >= 27 {
        for y in 27...last {
            let k = Double(y - 27) / 14
            let sway = sin(p.t * p.capeSpeed + k * 2.2) * k * 1.2
            let spread = up * (7 - 5 * k) * min(1, k * 4)
            let l = Int((16 - k * 3 - spread + sway).rounded()), r = Int((39 + k * 3 + spread + sway).rounded())
            c.rect(l, y, r - l + 1, 1, cape)
            c.px(l, y, capeL); c.px(r, y, capeD)
            if y > 30 { c.px(l + 2, y, capeD); c.px(r - 2, y, capeD) }
        }
    }
    drawLegs(c, Look(leg: boot), step: p.step)
    c.oy += p.breathe
    drawBody(c, Look(body: skin, shade: skinD, arm: glove, eye: nil), armRight: up > 0 ? 0 : raise)

    // Long thick black hair: low over the crown and down past her shoulders either side.
    c.pattern(16, 23, [
        "....HHHHHHHHHHHHHHHH....",
        "..HHHHlHHHHHHHHHHlHHHH..",
        ".HHlHHHHHHHHHHHHHHHHlHH.",
        "HHHH................HHHH",
        "HlH..................HlH",
        "HHl..................lHH",
        "HlH..................HlH",
        "HlH..................HlH",
        "HHl..................lHH",
        "HlH..................HlH",
        "HHl..................lHH",
        "HlH..................HlH",
        ".HH..................HH.",
        ".H....................H.",
    ], ["H": hair, "l": hairL])
    // The bronze headdress: the band across her brow, the crescent standing on it, the horns curving up and out.
    c.rect(18, 26, 20, 1, bronze); c.rect(18, 26, 7, 1, bronzeL); c.px(37, 26, bronzeD)
    let moon = blaze > 0.3 ? C(0xFFF4C0) : bronzeL
    c.pattern(25, 21, ["B....B", "BB..BB", ".BBBB."], ["B": moon])
    c.rect(27, 24, 2, 2, bronze); c.px(28, 25, bronzeD)
    for (side, x0) in [(-1.0, 18.5), (1.0, 37.5)] {
        for i in 0...10 {
            let t = Double(i) / 10
            let x = x0 + side * (2.5 * t + 1.5 * t * t), y = 26.5 - 10.5 * t + 2 * t * t
            let col = t > 0.75 ? bronzeL : side < 0 ? bronze : bronzeD
            v7Line(c, (x, y), (x, y), col, r: 1.1 - 0.6 * t)
        }
    }

    // Blank white eyes under dark lids slanting down to the middle, and two little fangs in a dark mouth.
    for (ex, inner) in [(22, 24), (32, 32)] {
        c.rect(ex, 29, 2, 2, C(0xF4F8FF)); c.rect(ex - 1, 28, 4, 1, ink); c.px(inner, 29, ink)
    }
    if blaze > 0 {
        for ex in [23.0, 33.0] {
            c.glowLine(ex, 29.5, ex, 29.5, core: C(0xFFFFFF, 0), glow: C(0xE8F0FF), coreR: 0.2, glowR: 3, strength: 0.7 * blaze)
        }
    }
    c.rect(25, 32, 6, 1, C(0x2A1630)); c.px(26, 33, bone); c.px(29, 33, bone)

    // The black leotard, purple trim round the neck and a purple belt with a bone skull for a buckle.
    c.rect(18, 34, 20, 4, suit); c.rect(18, 34, 20, 1, trim); c.rect(18, 35, 1, 3, C(0x3A3048))
    c.rect(18, 36, 20, 1, trim)
    c.pattern(26, 35, [".BB.", "BKKB", ".BB."], ["B": bone, "K": ink])

    if up > 0 {
        // Both arms raised high, purple-gloved hands open.
        let lh = (x: 16 - 4 * up, y: 34 - 15 * up), rh = (x: 39.5 + 4 * up, y: 34 - 15 * up)
        v7Line(c, (16.5, 34), (lh.x, lh.y + 1), skin, r: 1.3)
        v7Line(c, (39.0, 34), (rh.x, rh.y + 1), skin, r: 1.3)
        v7Line(c, (lh.x, lh.y + 3), (lh.x, lh.y), glove, r: 1.3)
        v7Line(c, (rh.x, rh.y + 3), (rh.x, rh.y), glove, r: 1.3)
    }
}

// MARK: - Jitsu

/// Jitsu: Skeleclawd's martial-arts master. Black hair drawn up into a topknot, an orange headband tied round his brow
/// with its tails flying behind, straight stern brows; orange lacquered armour laced in black over a black
/// gi, a black belt knotted at the front, orange shin guards. His right hand is a huge golden hand, flat and fingers
/// together for chopping, as tall as his head: he holds it up beside him on guard, and swings its edge like a blade.
/// Signature: he sets a plank across two stones, raises the gold hand high and chops it clean in two, splinters flying.
private func drawJitsu(_ c: PixelCanvas, _ p: Pose) {
    let orange = C(0xF08A1E), orangeD = C(0xB45E10), orangeL = C(0xFFB04A)
    let black = C(0x1E1C22), blackL = C(0x3E3A46)
    let hair = C(0x141218), hairL = C(0x3A3644)
    let s = p.signature ?? -1
    let sig = s > 0.04 && s < 0.96

    // The plank on its two stones, in front of him: whole until the chop, then in two halves dropping inwards.
    if sig {
        let chop = jitsuChop(s)
        let fy = Double(43 - c.oy)
        for sx in [47, 57] {
            c.rect(sx, Int(fy) - 3, 4, 4, C(0x8A8478)); c.rect(sx, Int(fy) - 3, 4, 1, C(0xB4AEA2))
            c.rect(sx + 3, Int(fy) - 2, 1, 3, C(0x5E5A52))
        }
        let wood = C(0xC89A5A), woodD = C(0x8A6232), woodL = C(0xE8C080)
        let py = fy - 4.5
        if chop.broken <= 0 {
            c.rect(45, Int(py), 17, 2, wood); c.rect(45, Int(py), 17, 1, woodL); c.rect(61, Int(py), 1, 2, woodD)
            for x in [48, 53, 58] { c.px(x, Int(py) + 1, woodD) }
        } else {
            let drop = 34 * v7Ease(min(1, chop.broken / 0.35))
            for (pivot, dir) in [((45.5, py + 0.5), 0.0), ((61.5, py + 0.5), 180.0)] {
                let a = dir == 0 ? drop : 180 - drop
                v7Line(c, pivot, eterniaReach(pivot, a, 7.5), wood, r: 0.9)
                v7Line(c, eterniaReach(pivot, a, 2), eterniaReach(pivot, a, 6), woodD, r: 0.3)
            }
            if chop.broken < 0.6 {
                // Splinters thrown up off the break, falling back.
                let u = chop.broken / 0.6
                for k in 0..<5 {
                    let vx = (Double(k) - 2) * 2.4, vy = 7 + Double(k % 3) * 2
                    let x = 53.5 + vx * u * 2, y = py - vy * u + 14 * u * u
                    guard y < fy else { continue }
                    c.px(Int(x.rounded()), Int(y.rounded()), k % 2 == 0 ? woodL : wood)
                }
                // The flash of the blow, see-through.
                if chop.broken < 0.12 {
                    c.glowLine(53.5, py, 53.5, py, core: C(0xFFFFFF, 0.9), glow: C(0xFFE28A), coreR: 0.8, glowR: 4,
                               strength: 1 - chop.broken / 0.12)
                }
            }
        }
    }

    // Black gi trousers, orange shin guards lit along the top, black feet.
    drawLegs(c, Look(leg: black), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 4, 2, 3, orange); c.rect(lx, bottom - 4, 2, 1, orangeL); c.px(lx + 1, bottom - 2, orangeD)
        }
    }
    c.oy += p.breathe
    drawBody(c, Look(arm: black))

    // The armour: orange lacquered plates over the chest laced in black, an orange guard on his back shoulder, the
    // black belt knotted at the front, an orange skirt plate under it split in panels.
    c.rect(18, 33, 20, 3, orange); c.rect(18, 33, 20, 1, orangeL); c.rect(37, 33, 1, 3, orangeD)
    c.rect(18, 35, 20, 1, black)
    for x in stride(from: 20, through: 35, by: 3) { c.px(x, 35, orangeD) }
    c.rect(15, 33, 3, 2, orange); c.rect(15, 33, 3, 1, orangeL); c.px(17, 34, orangeD)
    c.rect(18, 36, 20, 1, black); c.rect(26, 36, 4, 1, blackL); c.px(26, 37, black); c.px(29, 37, black)
    c.rect(18, 37, 20, 1, orange)
    for x in stride(from: 21, through: 35, by: 4) { c.px(x, 37, orangeD) }
    c.px(26, 37, black); c.px(29, 37, black)

    // The hair: black, combed up tight from his temples in strands to the topknot on his crown, tied with orange.
    c.pattern(18, 17, [
        "........KKKK........",
        ".......KKlKKK.......",
        "........KKKK........",
        "........oOOo........",
        ".....KKKKKKKKKK.....",
        "...KKKlKKKKKKlKKK...",
        "..KKlKKKKlKKKKKlKK..",
        ".KKlKKKKlKKKKlKKKKK.",
    ], ["K": hair, "l": hairL, "O": orange, "o": orangeD])
    // The orange headband round his brow, its two tails flying out behind him.
    c.rect(18, 25, 20, 2, orange); c.rect(18, 25, 20, 1, orangeL); c.rect(37, 25, 1, 2, orangeD)
    let flap = Int(p.t * 5) % 2
    c.pattern(12, 25, flap == 0 ? ["..oOOO", ".ooOO.", "...o.."] : ["...OOO", ".oOOOO", "..o..."],
              ["O": orange, "o": orangeD])
    // His brows, straight and stern.
    c.rect(21, 28, 3, 1, hair); c.rect(32, 28, 3, 1, hair)

    // The gold hand: held up on guard beside him, or swung, its edge leading.
    let chop = sig ? jitsuChop(s) : (angle: Double?.none, trail: [Double](), broken: 0.0)
    if let a = chop.angle ?? p.melee {
        jitsuHand(c, angle: a, trail: chop.angle != nil ? chop.trail : p.trail)
    } else {
        jitsuGuard(c)
    }
}

/// The swing in Jitsu's signature, 0…1: the hand raised high (…0.36) and held, the chop (…0.44) down onto the plank,
/// held there, then back up to the guard. Nil once it's back on guard. `broken`: how long since the plank broke, in
/// the signature's own units (0 before).
private func jitsuChop(_ s: Double) -> (angle: Double?, trail: [Double], broken: Double) {
    func at(_ u: Double) -> Double? {
        if u < 0.06 || u > 0.92 { return nil }
        if u < 0.36 { return -78 - 40 * v7Ease((u - 0.06) / 0.24) }
        if u < 0.44 { let f = (u - 0.36) / 0.08; return -118 + 132 * (1 - pow(1 - f, 3)) }
        if u < 0.78 { return 14 }
        return 14 - 92 * v7Ease((u - 0.78) / 0.14)
    }
    let ds = 0.035 / 3.4
    let now = at(s)
    var trail: [Double] = []
    if let n = now, let prev = at(s - ds), abs(n - prev) > 6 { trail = [prev, at(s - 2 * ds) ?? prev] }
    return (now, trail, s > 0.43 ? s - 0.43 : 0)
}

/// The shoulder Jitsu's arm swings from: Clawd's near arm nub.
private let v7Shoulder = (x: 42.0, y: 34.5)

/// An angle of Jitsu's arm kept off his head: raised up and back past straight up, the great hand would lean over
/// his face, so the first 40 degrees back are squeezed into 8 (a chop raised high, an urgent wave), and the rest of a
/// full swing round behind him stretches to meet it.
private func jitsuClear(_ a: Double) -> Double {
    var a = a.truncatingRemainder(dividingBy: 360)
    if a > 180 { a -= 360 } else if a <= -180 { a += 360 }
    if a < -90 && a >= -130 { return -90 + (a + 90) * 0.2 }
    if a < -130 { return -98 + (a + 130) * 82 / 50 }
    return a
}

/// Jitsu's gold hand swung at `angle` degrees: a black sleeve and an orange bracer, then the great flat hand, fingers
/// together, its leading edge lit, the seams between the fingers along it and the thumb tucked in at its root. Raised,
/// his elbow comes out to the side (as on guard), so the hand stands clear of his head. A fast swing leaves a smear.
private func jitsuHand(_ c: PixelCanvas, angle raw: Double, trail: [Double]) {
    let gold = C(0xF0C030), goldD = C(0xA87A10), goldL = C(0xFFF2A8)
    let a = jitsuClear(raw)
    func root(_ a: Double) -> (x: Double, y: Double) {
        let up = max(0, -sin(a * .pi / 180))
        return (v7Shoulder.x + 3.5 * up, v7Shoulder.y - 1.5 * up)
    }
    let h = root(a)
    for (i, t) in trail.map(jitsuClear).enumerated() {
        let p0 = eterniaReach(root(t), t, 6), p1 = eterniaReach(root(t), t, 16)
        c.glowLine(p0.x, p0.y, p1.x, p1.y, core: C(0xFFF4D0), glow: C(0xFFE08A), coreR: 1.4, glowR: 2.8,
                   strength: 0.32 / Double(i + 1))
    }
    v7Line(c, (39.5, 34.5), h, C(0x1E1C22), r: 1.3)
    eterniaBar(c, h, a, from: -1, to: 4.5, C(0x1E1C22), r: 1.3)
    eterniaBar(c, h, a, from: 3.5, to: 5.5, C(0xF08A1E), r: 1.5)
    eterniaBar(c, h, a, from: 6, to: 15, gold, r: 2.3)
    // The chopping edge, the side leading the swing down (the hand's little-finger side), lit.
    eterniaBar(c, eterniaReach(h, a + 90, 1.6), a, from: 6.5, to: 14.5, goldL, r: 0.45)
    // The seams between the fingers, from the knuckles to the tips, and the thumb along the top side.
    eterniaBar(c, eterniaReach(h, a - 90, 0.3), a, from: 10, to: 14.5, goldD, r: 0.35)
    eterniaBar(c, eterniaReach(h, a - 90, 2.4), a, from: 6, to: 9.5, goldD, r: 0.8)
}

/// Jitsu's gold hand held up on guard beside his shoulder: a black sleeve up from his arm into an orange bracer, and
/// the great flat hand standing straight up out of it, as tall as his head, its four fingers together with the seams
/// between them, the thumb along its near side, lit down its left edge.
private func jitsuGuard(_ c: PixelCanvas) {
    let gold = C(0xF0C030), goldD = C(0xA87A10), goldL = C(0xFFF2A8)
    c.rect(38, 32, 4, 3, C(0x1E1C22)); c.rect(41, 31, 3, 2, C(0x1E1C22)); c.px(38, 32, C(0x3E3A46))
    c.rect(41, 28, 5, 3, C(0xF08A1E)); c.rect(41, 28, 5, 1, C(0xFFB04A)); c.rect(45, 29, 1, 2, C(0xB45E10))
    c.pattern(41, 16, [
        ".LGGG.",
        "LGdGdG",
        "LGdGdG",
        "LGdGdG",
        "LGdGdG",
        "LGdGdD",
        "LGGGGD",
        "TTGGGD",
        "TTGGGD",
        "TTGGGD",
        ".TGGD.",
        "..GG..",
    ], ["G": gold, "d": goldD, "D": goldD, "L": goldL, "T": C(0xD8A824)])
}
