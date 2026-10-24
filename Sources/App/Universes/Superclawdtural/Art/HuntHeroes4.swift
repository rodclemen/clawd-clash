import Foundation

// Heroes: the hunters of Sioux Falls and beyond. Drawn the way HuntHeroes1.swift draws Team Free Will (its header has the Persona fields; HuntKit.swift the
// shared helpers): each one a `Persona` in the dictionary below and a `private func draw…` further down.
//
// Clawd in costume, Clawd's own orange face showing. Six of them carry pistols, so each gun is told apart by its
// owner first and its shape second: Rufus in a flat cap and green cardigan with a stubby nickel revolver; Garth with
// his big ears and sweater vest, a pistol with a tan frame; Jody in her tan sheriff's shirt, a light under her barrel;
// Donna in a navy parka with a fur ruff, red mittens and a box of donuts; Alex in pale blue scrubs and a stethoscope
// with a little stainless compact; Eileen in an olive field jacket with a suppressor on hers. Claire fights with a machete.
//
// Guns (`weapon: .blaster`, `shot: .bullet`), held `p.gunY` up or down with each shot; the machete (`.saber`) from
// `p.melee`, and point down at her side when that's nil.

let huntHeroes4: [HuntHero: Persona] = [
    .rufusTurner: Persona(name: "Rufus Turner", weapon: .blaster, shot: .bullet, muzzle: (47, 31), headTop: 21,
                          signature: 3.6, draw: drawRufusTurner),
    .garthFitzclawd: Persona(name: "Garth Fitzclawd IV", weapon: .blaster, shot: .bullet, muzzle: (49, 31),
                             headTop: 23, signature: 3.2, callout: "Mr. Fizzles says hi!", draw: drawGarthFitzclawd),
    .jodyMills: Persona(name: "Jody Mills", weapon: .blaster, shot: .bullet, muzzle: (49, 31), headTop: 22,
                        signature: 3.0, draw: drawJodyMills),
    .donnaHanscum: Persona(name: "Donna Hanscum", weapon: .blaster, shot: .bullet, muzzle: (48, 31), headTop: 22,
                           signature: 3.4, callout: "Oh, ya!", draw: drawDonnaHanscum),
    .claireNovak: Persona(name: "Claire Novak", weapon: .saber, headTop: 21, signature: 2.6, draw: drawClaireNovak),
    .alexJones: Persona(name: "Alex Jones", weapon: .blaster, shot: .bullet, muzzle: (46, 30), headTop: 21,
                        draw: drawAlexJones),
    .eileenLeahy: Persona(name: "Eileen Leahy", weapon: .blaster, shot: .bullet, muzzle: (53, 31), headTop: 20,
                          signature: 2.8, draw: drawEileenLeahy),
]

// MARK: - Shared bits

/// How far through the part of the signature between `from` and `to` (0…1), or -1 outside it.
private func h4Span(_ p: Pose, _ from: Double, _ to: Double) -> Double {
    guard let s = p.signature, s > from, s < to else { return -1 }
    return (s - from) / (to - from)
}

/// Smoothstep: 0→1 eased at both ends.
private func h4Smooth(_ x: Double) -> Double {
    let u = min(1, max(0, x))
    return u * u * (3 - 2 * u)
}

/// Up over the first `edge` of `k`, held, and down again over the last `edge`; 0 when `k` is outside 0…1.
private func h4Ease(_ k: Double, edge: Double) -> Double {
    guard k >= 0, k <= 1 else { return 0 }
    return h4Smooth(min(1, k / edge, (1 - k) / edge))
}

/// Clawd's brows, a stroke over each eye.
private func h4Brows(_ c: PixelCanvas, _ col: Px) {
    c.rect(22, 28, 2, 1, col); c.rect(32, 28, 2, 1, col)
}

// MARK: - Rufus Turner

/// Rufus Turner: the old hunter Bobby trusts least and likes most. A grey tweed flat cap with its short peak pulled
/// down at the front, close-cut grey stubble along his jaw, a bottle-green shawl-collar cardigan with leather buttons
/// and a ribbed hem over a pale blue shirt, charcoal slacks and brown shoes. Fights with a stubby nickel revolver, its
/// black rubber grip in his fist. Signature: out comes a bottle of the good stuff with its blue label and a tumbler,
/// and he pours himself a glass, the whisky rising in it.
private func drawRufusTurner(_ c: PixelCanvas, _ p: Pose) {
    let knit = C(0x3C5A46), knitD = C(0x283E30), knitL = C(0x587A62), button = C(0x7A5434)
    let shirt = C(0xB8C8DA), shirtD = C(0x8EA2BA)
    let tweed = C(0x6E6656), tweedD = C(0x4A4438), tweedL = C(0x8E8674)
    let stubble = C(0x9A968E), stubbleD = C(0x76726C)
    let k = h4Span(p, 0.05, 0.95)
    let up = h4Ease(k, edge: 0.14)
    let raise = Int((up * 4).rounded())

    // Charcoal slacks with a crease lit down the front, and brown shoes.
    drawLegs(c, Look(leg: C(0x3A3A42)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 37 : 38, 1, 3, C(0x52525C))
        }
    }
    drawBoots(c, C(0x4A3020), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: knit), armRight: raise)

    // Close grey stubble along his jaw and over his chin, in short strokes.
    c.pattern(18, 30, [
        "s..................s",
        "Ss................sS",
        "SsS..sSsSSsSs...sSsS",
    ], ["S": stubble, "s": stubbleD])

    // The cardigan, kept plain so it reads as one soft knit: a thick rolled shawl collar meeting low on his chest, lit
    // on the near side and shaded on the far, with only a narrow sliver of pale blue shirt between at the top; two
    // leather buttons below, a patch pocket, the far side in shade and a ribbed hem.
    c.pattern(18, 33, [
        "KLLKKCCCCSsEEEEKKKKD",
        "KLKKKKCCCCEEEEKKKKKD",
        "KLPPPKKCCCEEEKKKKKKD",
        "KLKKKKKKCbEKKKKKKKKD",
        "RRRRRRRRRbRRRRRRRRRR",
    ], ["K": knit, "L": knitL, "D": knitD, "P": knitD, "C": C(0x5A7E64), "E": C(0x2E4636), "S": shirt,
        "s": shirtD, "b": button, "R": C(0x30483A)])
    c.rect(15, 35, 3, 1, knitD)
    if raise == 0 { c.rect(38, 35, 3, 1, knitD) }   // the ribbed cuff

    // The flat cap: the tweed crown sloping forward over his brow, flecked, lit on top, and the short peak out front.
    // Grey hair at his temples underneath.
    c.pattern(17, 21, [
        "...TTTTTTTTTTTT.......",
        "..TTtTTlTTTtTTTTT.....",
        ".TTTlTTTtTTTTlTTtTT...",
        ".TtTTTTTTTtTTTTTTTTTT.",
        ".DDDDDDDDDDDDDDDDDDDPPP",
        ".gg..............g..pp",
        ".g................g...",
    ], ["T": tweed, "t": tweedD, "l": tweedL, "D": tweedD, "P": C(0x5A5446), "p": C(0x3A3628),
        "g": C(0xB4B0A8)])
    h4Brows(c, C(0x8A867E))

    if k >= 0 {
        // The pour. The tumbler in his other hand, held out low in front; the bottle in his raised fist, tipped
        // over the glass while the whisky runs, then upright again.
        let tip = k < 0.22 ? 0 : k < 0.32 ? (k - 0.22) / 0.1 : k < 0.7 ? 1 : k < 0.8 ? (0.8 - k) / 0.1 : 0
        let fill = max(0, min(1, (k - 0.32) / 0.38))
        let hy = 33 - raise
        let pivot = (x: 44.5, y: Double(hy) - 2)
        let a = -90 + tip * 110
        let amber = C(0x7A4218), amberD = C(0x4E2A10), amberL = C(0xB8783A)
        let label = C(0x2850A8), labelL = C(0x5A80D0), gold = C(0xD8B048)
        // The tumbler out in front: clear glass edges, its heavy base, the whisky rising in it.
        if up > 0.5 {
            let glass = C(0xD8E4EC), glassD = C(0x9AAAB6)
            c.rect(48, 33, 1, 5, glass); c.rect(51, 33, 1, 5, glassD); c.rect(48, 37, 4, 1, glassD)
            c.rect(49, 33, 2, 4, C(0xC8D8E4, 0.2))
            let lv = Int((fill * 3).rounded())
            if lv > 0 { c.rect(49, 37 - lv, 2, lv, C(0xC88A30)); c.px(49, 37 - lv, C(0xE8B050)) }
            c.rect(46, 35, 2, 3, clawdOrange); c.px(46, 37, clawdShade)   // his other hand round it
        }
        // The bottle: amber glass lit along its top side, the blue label with a gold rim, the dark neck and cap.
        let n = (x: cos((a - 90) * .pi / 180), y: sin((a - 90) * .pi / 180))
        let b0 = huntReach(pivot, a, -4), b1 = huntReach(pivot, a, 3), neck = huntReach(pivot, a, 6)
        huntLine(c, b0.x, b0.y, b1.x, b1.y, amber, 1.8)
        let l0 = huntReach(pivot, a, -1.5), l1 = huntReach(pivot, a, 1)
        huntLine(c, l0.x, l0.y, l1.x, l1.y, label, 1.9)
        for d in [-2.0, 1.6] {
            let g = huntReach(pivot, a, d)
            c.px(Int(g.x.rounded()), Int(g.y.rounded()), gold)
        }
        c.px(Int((l0.x + n.x).rounded()), Int((l0.y + n.y).rounded()), labelL)
        let h0 = huntReach(pivot, a, -3.5)
        c.px(Int((h0.x + n.x).rounded()), Int((h0.y + n.y).rounded()), amberL)
        huntLine(c, b1.x, b1.y, neck.x, neck.y, amberD, 0.7)
        c.px(Int(neck.x.rounded()), Int(neck.y.rounded()), C(0x1E1E22))
        if tip > 0.95 && fill > 0 && fill < 1 {
            // The whisky running from the neck into the glass.
            let nx = Int(neck.x.rounded()), ny = Int(neck.y.rounded())
            for y in (ny + 1)..<(37 - Int((fill * 3).rounded())) { c.px(nx, y, C(0xD89A3A)) }
        }
        c.rect(39, hy, 3, 3, clawdOrange); c.px(41, hy + 1, clawdShade)   // his fist round the bottle
        return   // the revolver back in his pocket while he pours
    }

    // The snub-nosed revolver: a short nickel barrel lit along the top, the fat cylinder, the hammer, the black
    // rubber grip in his fist.
    c.oy += p.gunY
    c.pattern(38, 29, [
        "...h.....",
        "..hSSSSSl",
        "..CcCSSs.",
        "OOOGCk...",
        "OOOGk....",
        ".OGG.....",
    ], ["S": C(0xD6D8DC), "s": C(0x9A9EA6), "l": C(0xF4F6F8), "h": C(0x6E727A), "C": C(0xB4B8C0),
        "c": C(0x7E838C), "k": C(0x3A3C42), "G": C(0x1E1E22), "O": clawdOrange])
}

// MARK: - Garth Fitzclawd IV

/// Garth Fitzclawd IV: the gangly, cheerful hunter, all elbows, with short light-brown hair buzzed close, ears that
/// stick out on both sides, a pale blue shirt buttoned to the neck under an oatmeal sweater vest with a brown argyle,
/// a skinny maroon tie, brown cords and shoes. Fights with a pistol with a tan frame. Signature: Mr. Fizzles, his
/// sock puppet, pops up on his hand, googly eyes rolling, and chats away, his felt mouth flapping.
private func drawGarthFitzclawd(_ c: PixelCanvas, _ p: Pose) {
    let vest = C(0xC8B48E), vestD = C(0xA08C68), vestL = C(0xDCCCA8), argyle = C(0x8E7454)
    let shirt = C(0xA8C4E0), shirtD = C(0x7E9CC0), tie = C(0x8A2A30), tieD = C(0x5E1A20)
    let hair = C(0x9A7048), hairD = C(0x7A5636), hairL = C(0xB89068)
    let k = h4Span(p, 0.04, 0.96)
    let up = h4Ease(k, edge: 0.16)
    let raise = Int((up * 4).rounded())

    // Brown corduroys, a crease down the front, and brown shoes.
    drawLegs(c, Look(leg: C(0x6A5640)), step: p.step)
    if !seatedPose {
        for (i, lx) in [20, 24, 32, 36].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 37 : 38, 1, 3, C(0x52422E))
        }
    }
    drawBoots(c, C(0x2E2016), step: p.step, rows: 1)

    c.oy += p.breathe
    drawBody(c, Look(arm: shirt), armRight: raise)

    // His ears, sticking out either side of his head, a shade inside.
    c.rect(15, 28, 3, 4, clawdOrange); c.px(15, 28, C(0xE88E6E)); c.rect(16, 29, 1, 2, clawdShade)
    c.px(15, 31, clawdShade)
    c.rect(38, 28, 2, 4, clawdOrange); c.px(38, 28, C(0xE88E6E)); c.rect(38, 29, 1, 2, clawdShade); c.px(39, 31, clawdShade)

    // The sweater vest, cut narrow over a shirt that hangs loose on him, so he reads as all shirt and no body: the
    // shirt showing at both sides, a deep V neck with the collar and the long skinny tie down to his belt, one column of
    // argyle diamonds each side, the near edge lit, the far side in shade; his cords belted high, a brass buckle;
    // shirt cuffs at the wrists.
    c.pattern(18, 33, [
        "SSLLLLLsSTTSsVVVVvSs",
        "SSLVaVVLsTtsvVaVvvSs",
        "SsLaVaVVLTtvVaVavvSs",
        "SsVVaVVVVTtVVVaVvvSs",
        "BBBBBBBBBbbBBBBBBBBB",
    ], ["S": shirt, "s": shirtD, "V": vest, "v": vestD, "L": vestL, "a": argyle, "T": tie, "t": tieD,
        "B": C(0x4A3524), "b": C(0xD0A848)])
    c.rect(15, 35, 3, 1, shirtD)
    if raise == 0 { c.rect(38, 35, 3, 1, shirtD) }

    // Short hair buzzed right down to the scalp, so it's a soft brown wash over his head rather than a cap: a
    // hairline that dips to a little peak at the front and is thin at the temples, a few lit strokes on top, and one
    // stubborn tuft sticking up.
    c.pattern(18, 23, [
        "...........Hl.......",
        ".....hHHHHHHHHHh....",
        "..hHHlHHHlHHHlHHHHh.",
        ".hHHHHhHHHHHHHhHHHHh",
        ".HH.......hHh.....HH",
    ], ["H": hair, "h": hairD, "l": hairL])
    h4Brows(c, hairD)

    if k >= 0 {
        // Mr. Fizzles, worn on his hand: a grey wool sock pulled over his fist and up his wrist, its ribbed cuff where
        // the hand would be, so the puppet grows straight out of his arm. A tuft of red yarn on top, two big googly
        // eyes whose pupils roll about, and a red felt mouth across the toe that drops open and shut as he talks. He
        // rises up off the arm at the start and sinks back down at the end.
        let rise = Int(((1 - up) * 6).rounded())
        let talk = k > 0.18 && k < 0.84 && Int(p.t * 8) % 2 == 0
        let roll = Int(p.t * 3) % 3
        let sock = C(0xC4C2C8), sockD = C(0x8E8C96), sockL = C(0xE6E4EA), cuff = C(0xA4A2AC), cuffD = C(0x7C7A84)
        let y0 = 18 + rise
        c.pattern(37, y0, [
            "....yYyy...",
            "...SSSSSS..",
            "..SLLSSLLS.",
            "..SWWSSWWSS",
            ".SSWWSSWWSS",
            ".SLSSSSSSSd",
            talk ? ".SLSSSSmmmm" : ".SLSSSSMMMM",
            talk ? ".SSSSSmmmm." : ".SSSSSSSSd.",
            talk ? ".SSSSSMMM.." : ".SSSSSSSd..",
            "..SSSSSSd..",
            "..CcCcCc...",
            "..cCcCcC...",
        ], ["S": sock, "L": sockL, "d": sockD, "W": C(0xF8F8F4), "M": C(0xC8303A), "m": C(0x5A1218),
            "y": C(0xC8442A), "Y": C(0xF06A3A), "C": cuff, "c": cuffD])
        // The pupils, rolling round inside the googly eyes.
        let dx = roll == 0 ? 0 : 1, dy = roll == 2 ? 1 : 0
        c.px(40 + dx, y0 + 3 + dy, C(0x141418)); c.px(44 + dx, y0 + 3 + dy, C(0x141418))
        // The sock runs on down his wrist to meet the sleeve.
        if y0 + 12 < 36 - raise { c.rect(39, y0 + 12, 3, 36 - raise - y0 - 12, cuff) }
        return   // the pistol tucked in his belt while Mr. Fizzles talks
    }

    // The pistol: a black slide lit along the top, a tan polymer frame and grip in his fist.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGGGl",
        "..TTTTTTTt.",
        "OOOTk.k....",
        "OOOT.......",
        ".OTT.......",
    ], ["G": C(0x2A2C32), "l": C(0x7A808C), "T": C(0xB49A6A), "t": C(0x8A744A), "k": C(0x6A5634), "O": clawdOrange])
}

// MARK: - Sheriff Jody Mills

/// Sheriff Jody Mills: warm brown hair to her shoulders with a side parting, a tan sheriff's shirt with dark brown
/// epaulettes and flapped pockets, the gold star on her chest and a name bar opposite, a black duty belt with its
/// silver buckle and holster, dark brown trousers and black boots. Fights with her black service pistol, a light under
/// its barrel. Signature: she holds up her badge wallet, flips it open on the gold star, and puts it away.
private func drawJodyMills(_ c: PixelCanvas, _ p: Pose) {
    let shirt = C(0xC8AE7E), shirtD = C(0x9E8458), shirtL = C(0xE0CA9E), brown = C(0x5E4428)
    let gold = C(0xE8C04A), goldD = C(0xA8842A), belt = C(0x1E1E22), silver = C(0xC8CCD4)
    let hair = C(0x6A4A30), hairD = C(0x4A3220), hairL = C(0x8E6844)
    let k = h4Span(p, 0.06, 0.94)
    let up = h4Ease(k, edge: 0.18)
    let raise = Int((up * 6).rounded())

    // Dark brown uniform trousers, a tan stripe down the outside of the near legs, and black boots.
    drawLegs(c, Look(leg: C(0x4A3826)), step: p.step)
    if !seatedPose {
        for (leg, lx) in [(0, 20), (3, 36)] {
            c.rect(lx, p.step >= 0 && leg % 2 == p.step ? 36 : 37, 1, 4, C(0x9E8458))
        }
    }
    drawBoots(c, C(0x18181C), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: shirt), armRight: raise)

    // The uniform shirt: its collar open at the neck, the epaulettes on the shoulders, a flapped pocket each side,
    // the star over the near pocket, the name bar over the far one, a button placket, the far side in shade.
    c.rect(18, 33, 20, 5, shirt)
    c.rect(26, 33, 4, 1, clawdOrange); c.px(27, 34, clawdShade); c.px(28, 34, clawdShade)   // open at the neck
    c.rect(24, 33, 2, 1, shirtL); c.px(26, 34, shirtL); c.rect(30, 33, 2, 1, shirtD); c.px(29, 34, shirtD)
    c.rect(18, 33, 4, 1, brown); c.rect(34, 33, 4, 1, brown)
    c.rect(20, 35, 4, 1, shirtD); c.rect(31, 35, 4, 1, shirtD); c.px(21, 36, shirtD); c.px(33, 36, shirtD)
    c.pattern(20, 33, [".g.", "ggg", "g.g"], ["g": gold]); c.px(21, 34, C(0xFFE48A)); c.px(22, 35, goldD)
    c.rect(32, 34, 3, 1, silver)
    c.rect(28, 35, 1, 2, shirtD)
    c.rect(18, 34, 1, 3, shirtL); c.rect(37, 33, 1, 4, shirtD)
    // The duty belt: black, a silver buckle, a pouch on the near side.
    c.rect(18, 37, 20, 1, belt); c.rect(27, 37, 2, 1, silver); c.rect(20, 37, 2, 1, C(0x34343A))
    c.rect(15, 35, 3, 1, shirtD)
    if raise == 0 { c.rect(38, 35, 3, 1, shirtD) }

    // Warm brown hair to her shoulders, close to her head on top: a parting on the far side, the hair combed away from
    // it in lit strokes on both sides, a sweep across her brow that falls lower towards the near side, and the ends
    // flicking out unevenly at her shoulders.
    c.pattern(17, 22, [
        "......HHHHHHHHH.......",
        "...HHlHhHHlllHHHH.....",
        "..HlHHHhHHHHlllHHHH...",
        ".HlHHHhHHHHHHHHlHHHHd.",
        "HHHHHhHHHHHHHHHHHHHHHd",
        "HHHH..dhHHHHHHHHHHHHHd",
        "HHH.........ddHHHHHHd.",
        "HlH...............HHd.",
        "HlH...............HHd.",
        "HHd...............dHd.",
        "HHdH..............dHHd",
        "dH.d.............d.Hd.",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    h4Brows(c, hairD)

    if k >= 0 {
        // The badge wallet up at eye level: black leather, closed at first, then flipped open on the gold star and
        // her ID card, the star glinting, then shut again.
        let hy = 33 - raise
        let open = k > 0.28 && k < 0.82
        let leather = C(0x22201E), leatherL = C(0x46423C)
        if open {
            c.rect(40, hy - 7, 5, 7, leather); c.rect(45, hy - 7, 5, 7, leather)
            c.rect(40, hy - 7, 5, 1, leatherL); c.rect(45, hy - 7, 5, 1, leatherL)
            c.pattern(40, hy - 6, ["..g..", ".ggg.", "ggggg", ".ggg.", ".g.g."], ["g": gold])
            c.px(41, hy - 4, C(0xFFE48A)); c.px(42, hy - 2, goldD)
            c.rect(46, hy - 6, 3, 5, C(0xEEEAE0)); c.rect(46, hy - 6, 3, 2, C(0x8EA2BA)); c.rect(46, hy - 3, 3, 1, C(0x5A5A60))
            if Int(p.t * 6) % 3 == 0 { c.px(42, hy - 7, C(0xFFFFFF, 0.9)) }
        } else {
            c.rect(40, hy - 7, 5, 7, leather); c.rect(40, hy - 7, 1, 7, leatherL); c.px(43, hy - 4, goldD)
        }
        c.rect(38, hy, 3, 3, clawdOrange); c.px(40, hy + 1, clawdShade)
        return   // the pistol in its holster while she shows the badge
    }

    // The service pistol: a black slide lit along the top, the frame, and the light mounted under the barrel with
    // its pale lens.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGGGl",
        "..KKKKKKKKK",
        "OOOKk.TTTTW",
        "OOOK.......",
        ".OKK.......",
    ], ["G": C(0x3A3C44), "l": C(0x8A909A), "K": C(0x1E1E22), "k": C(0x141416), "T": C(0x2E3036),
        "W": C(0xF4F0D0), "O": clawdOrange])
}

// MARK: - Sheriff Donna Hanscum

/// Sheriff Donna Hanscum, of Stillwater, Minnesota: pale blonde hair, long and straight, with a fringe cut across;
/// a puffy navy sheriff's parka, quilted, with a cream fur ruff round the hood and a gold star patch, open at the
/// hem over brown trousers and snow boots; red mittens; and a pink box of donuts tucked under her arm. Fights with a
/// black service pistol, held in her mitten. Signature: she takes a pink-frosted donut out of the box and eats it in
/// three happy bites.
private func drawDonnaHanscum(_ c: PixelCanvas, _ p: Pose) {
    let parka = C(0x2E3E5E), parkaD = C(0x1E2A42), parkaL = C(0x4A5E86)
    let fur = C(0xE6DCC8), furD = C(0xBCAE96), furL = C(0xF8F2E6)
    let mitten = C(0xC0303A), mittenD = C(0x8A1E26), mittenL = C(0xE05058)
    let hair = C(0xE8D8A8), hairD = C(0xC0AE7C), hairL = C(0xF8EED0)
    let box = C(0xF0A0B8), boxD = C(0xC87890), boxL = C(0xFFD0DC)
    let k = h4Span(p, 0.05, 0.95)
    let up = h4Ease(k, edge: 0.14)
    let raise = Int((up * 5).rounded())

    // Brown trousers and chunky snow boots, a cuff of grey fleece at the top of each.
    drawLegs(c, Look(leg: C(0x5A4632)), step: p.step)
    drawBoots(c, C(0x3A2A1E), step: p.step, rows: 3)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 39 : 40, 2, 1, C(0x9A968E))
        }
    }

    // The donut box under her far arm, sticking out behind her: pink card, the lid lifted a little on two donuts.
    let bob = p.breathe
    c.rect(8, 34 + bob, 9, 4, box); c.rect(8, 37 + bob, 9, 1, boxD); c.rect(8, 34 + bob, 1, 3, boxL)
    c.rect(9, 32 + bob, 8, 1, boxL); c.rect(8, 33 + bob, 1, 1, boxL)
    c.rect(10, 33 + bob, 3, 1, C(0xC08A4A)); c.rect(13, 33 + bob, 3, 1, C(0x6A3A20))   // the donuts peeking out
    c.px(11, 33 + bob, C(0xFF7AA8)); c.px(14, 33 + bob, C(0xFFE0A0))
    c.rect(10, 35 + bob, 4, 1, C(0xD86A8A))   // the bakery's stripe

    c.oy += p.breathe
    // The parka's skirt over her hips, split down the front, so the four legs show below.
    if seatedPose {
        c.rect(17, 38, 22, 1, parka)
    } else {
        c.rect(17, 38, 22, 1, parka); c.rect(17, 39, 22, 1, parkaD)
        c.px(17, 38, parkaL); c.rect(28, 38, 1, 2, C(0x141C2E))
    }
    drawBody(c, Look(arm: parka), armRight: raise)

    // The parka, puffy enough to stand out past her sides: the fur ruff of the hood round her neck in strokes, a
    // quilted seam across, each puff lit on the near side, the zip, the star patch, the far side in shade.
    c.rect(17, 33, 22, 5, parka)
    c.rect(17, 35, 22, 1, parkaD); c.rect(18, 36, 7, 1, parkaL); c.rect(18, 34, 3, 1, parkaL)
    c.rect(17, 37, 22, 1, parkaD); c.rect(38, 33, 1, 5, parkaD); c.rect(17, 33, 1, 4, parkaL)
    c.rect(28, 34, 1, 4, C(0x141C2E)); c.px(28, 36, C(0xA0A4AC))
    c.pattern(20, 33, [
        "FfFLFFfdFFLFfFFdFF",
        ".dFfd.........dFd.",
    ], ["F": fur, "f": furL, "L": furL, "d": furD])
    c.pattern(31, 35, [".g.", "ggg", "g.g"], ["g": C(0xE8C04A)])
    // Her mittens: red, a lit knuckle; the far one holding the box.
    c.rect(15, 34, 2, 2, mitten); c.px(15, 34, mittenL); c.px(16, 35, mittenD)

    // Pale blonde hair, long and straight, lying flat on her head instead of standing up round it: lit in long
    // strokes on top, a fringe cut across her brow that splits into strands at its ends, and the lengths falling
    // straight down past her shoulders onto the ruff, a strand line down each, the ends tapering.
    c.pattern(16, 22, [
        "........HHHHHHHH........",
        "......HHHlllHHHHHH......",
        "....HHHlHHHHHHHlllHH....",
        "..HHHlHHHHHHHHHHHHHHHd..",
        "..HHHHHlHHHHHlHHHHHlHd..",
        "..HHHdHHHdHHHdHHHdHHHd..",
        "..HHd.H.d.H.Hd.H.d.HHd..",
        "..HlH...............HHd.",
        "..HlH...............dHd.",
        "..HlHd..............dHd.",
        "..HHdH..............HdH.",
        "..HdHd..............HdH.",
        "..HdH................Hd.",
        "..dH.................dd.",
        "...d....................",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    h4Brows(c, hairD)

    if k >= 0 {
        // The donut up to her mouth in her mitten: pink frosting with sprinkles on golden dough round the hole. Each
        // bite takes a piece off the side nearest her; crumbs fall after each.
        let bites = k < 0.3 ? 0 : k < 0.5 ? 1 : k < 0.7 ? 2 : 3
        let hy = 33 - raise
        if bites < 3 {
            let rows = [".PPPPP.", "PsPPPsP", "PPp.pPs", "DDd.dDD", "DDDdDDD", ".DDDDD."]
            let pal: [Character: Px] = ["P": C(0xF27AA6), "p": C(0xD85C8A), "s": C(0xFFF0A0), "D": C(0xD09A54),
                                        "d": C(0xA87232)]
            for (dy, row) in rows.enumerated() {
                for (dx, ch) in row.enumerated() where dx >= bites * 2 {
                    guard let col = pal[ch] else { continue }
                    c.px(37 + dx, hy - 6 + dy, col)
                }
            }
        }
        for b in 1...3 {
            let at = [0.3, 0.5, 0.7][b - 1], f = (k - at) / 0.12
            guard f > 0 && f < 1 else { continue }
            c.px(38, hy + Int(f * 6), C(0xD09A54)); c.px(40, hy + 1 + Int(f * 5), C(0xF27AA6))
        }
        c.rect(38, hy, 3, 3, mitten); c.px(38, hy, mittenL); c.px(40, hy + 2, mittenD)
        return
    }

    // The service pistol in her red mitten: a black slide lit along the top, the frame and trigger guard.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGGl",
        "..KKKKKKK.",
        "MMLKk.k...",
        "MMMK......",
        "mMKK......",
    ], ["G": C(0x34363E), "l": C(0x80868F), "K": C(0x1C1C20), "k": C(0x141416), "M": mitten, "L": mittenL,
        "m": mittenD])
}

// MARK: - Claire Novak

/// Claire Novak: honey-blonde hair, long and a bit wild, darker at the roots; a black leather jacket with its collar
/// up, a sheen on the leather, open over a charcoal hoodie, its drawstrings hanging down the front; ripped
/// jeans with pale frays at the knee; black boots. Fights with a machete, a broad steel blade with a black grip.
/// Signature: she spins the machete round her hand, two turns, and catches it point down.
private func drawClaireNovak(_ c: PixelCanvas, _ p: Pose) {
    let leather = C(0x26262C), leatherD = C(0x141418), leatherL = C(0x4A4A54), sheen = C(0x62626E)
    let hood = C(0x5A5A62), hoodD = C(0x3E3E46), hoodL = C(0x76767E)
    let hair = C(0xC8A060), hairD = C(0x9A7640), hairL = C(0xE2C084), roots = C(0x7A5A34)
    let grip = C(0x1E1E22), steel = C(0xA8AEB8), steelD = C(0x7A808A), edge = C(0xE8ECF2)
    let k = h4Span(p, 0.05, 0.95)

    // Ripped jeans, the frays pale across the near knees, and black boots.
    drawLegs(c, Look(leg: C(0x3A4C70)), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() where i % 2 == 1 {
            let y = p.step >= 0 && i % 2 == p.step ? 38 : 39
            c.rect(lx, y, 2, 1, C(0xC8D0DE)); c.px(lx, y + 1, C(0x8A9AB8))
        }
    }
    drawBoots(c, C(0x18181C), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: leather))

    // The jacket: the collar up and lit, open on the hoodie, sheen strokes on the leather, silver zip teeth down one
    // front edge, the far side and the hem in shade, a cuff. The hoodie shows down the front only: the rolled rim of
    // its hood round her neck, its two pale drawstrings and a pouch pocket seam, so it reads as a hoodie and not as a
    // grey block.
    c.rect(18, 33, 20, 5, leather)
    c.rect(26, 33, 4, 5, hood); c.rect(26, 33, 4, 1, hoodL); c.rect(26, 34, 4, 1, hoodD); c.rect(26, 37, 4, 1, hoodD)
    c.rect(27, 35, 1, 2, C(0xE4E2DA)); c.rect(28, 35, 1, 1, C(0xE4E2DA)); c.px(28, 36, hoodD)
    c.rect(19, 32, 5, 1, leatherL); c.rect(32, 32, 4, 1, leather); c.px(35, 32, leatherD)
    c.rect(25, 33, 1, 5, leatherL); c.rect(30, 33, 1, 5, leatherD)
    c.px(25, 34, C(0xB0B4BC)); c.px(25, 36, C(0xB0B4BC))
    c.rect(20, 34, 1, 2, sheen); c.px(21, 34, sheen); c.rect(33, 35, 2, 1, leatherL)
    c.rect(37, 33, 1, 5, leatherD); c.rect(18, 37, 20, 1, leatherD)
    c.rect(15, 35, 3, 1, leatherD)
    c.rect(38, 35, 3, 1, leatherD)

    // Long honey-blonde hair, a bit wild: darker at the roots on top, its outline rough with strands kinking out, a
    // ragged fringe pushed aside, and the lengths falling past her shoulders in rough strokes to uneven ends.
    c.pattern(16, 21, [
        ".....R.RRRRRRR.R........",
        "....RRRRRHRRRRRRRR......",
        "..HRRHHHlHHHRRHHHHH.....",
        "..HHHlHHHHHlHHHHHlHHHH..",
        ".HHHlHHHdHHHHlHHHHdHHHH.",
        "HHHHHHHdHHHHHHHdHHHHHHd.",
        ".HHHHd.dH......dHdHHHHd.",
        "HHHH.d..........d.HHHd.H",
        "HHlH..............HHHd..",
        ".HlHH..............HHHd.",
        "HHHH...............dHHd.",
        "HlHd................HHd.",
        "HHHd...............dHHHd",
        ".HdH................dHd.",
        "Hd.d...............d.Hd.",
    ], ["H": hair, "l": hairL, "d": hairD, "R": roots])
    h4Brows(c, roots)

    // The machete: swung when she fights; spun two turns round her hand for the signature; otherwise held point
    // down at her side.
    var angle = p.melee
    var q = p
    if k >= 0 {
        let turn = h4Smooth(k) * 720
        angle = 90 + turn
        q.trail = [angle! - 28, angle! - 56]
    }
    if let a = angle {
        huntBlade(c, q, angle: a, grip: grip, steel: steel, edge: edge, length: 10)
        // The broad back of the blade, a shade darker, and its squared-off tip.
        let h = huntHand
        let n = (x: cos((a - 90) * .pi / 180), y: sin((a - 90) * .pi / 180))
        let b0 = huntReach(h, a, 3), b1 = huntReach(h, a, 10)
        huntLine(c, b0.x + n.x * 1.2, b0.y + n.y * 1.2, b1.x + n.x * 1.2, b1.y + n.y * 1.2, steelD, 0.6)
        c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
    } else {
        c.rect(39, 34, 2, 3, grip); c.px(39, 35, C(0x46464E))
        c.rect(39, 37, 3, 6, steel); c.rect(41, 37, 1, 6, steelD); c.rect(39, 37, 1, 5, edge); c.px(41, 42, steel)
        c.rect(38, 34, 3, 2, clawdOrange)
    }
}

// MARK: - Alex Jones

/// Alex Jones: Jody's eldest, a nurse, with dark hair pulled back in a ponytail and a side fringe; pale blue scrubs,
/// the V-neck top with a chest pocket and pens, a stethoscope round her neck, an ID badge clipped on; scrub trousers
/// to match and white sneakers. Fights with a small two-tone compact pistol, a stainless slide on a black frame. No
/// signature.
private func drawAlexJones(_ c: PixelCanvas, _ p: Pose) {
    let scrubs = C(0x86AED4), scrubsD = C(0x6088B0), scrubsL = C(0xACCCEA)
    let tube = C(0x2A2A30), chrome = C(0xC8CCD4)
    let hair = C(0x2E1E16), hairD = C(0x1A100A), hairL = C(0x4E3626)

    // Scrub trousers, a fold down the front of each leg, and white sneakers with grey soles.
    drawLegs(c, Look(leg: scrubs), step: p.step)
    if !seatedPose {
        for (i, lx) in [20, 24, 32, 36].enumerated() {
            c.rect(lx, p.step >= 0 && i % 2 == p.step ? 36 : 37, 1, 4, scrubsD)
        }
    }
    drawBoots(c, C(0xEEEEF0), step: p.step, rows: 2)
    drawBoots(c, C(0x9A9CA4), step: p.step, rows: 1)

    // The ponytail, hanging down behind her head.
    c.pattern(13, 23, [
        "..HHH",
        ".HHlH",
        ".HlHH",
        "HHHH.",
        "HlHd.",
        "HHd..",
        ".Hd..",
        ".d...",
    ], ["H": hair, "l": hairL, "d": hairD])

    c.oy += p.breathe
    drawBody(c, Look(arm: scrubs))

    // The scrub top: a V neck, the chest pocket on the far side with two pens, the ID badge on the near side, the
    // far side and the hem in shade, short sleeves.
    c.rect(18, 33, 20, 5, scrubs)
    c.rect(26, 33, 4, 1, clawdOrange); c.rect(27, 34, 2, 1, clawdOrange)
    c.px(25, 33, scrubsL); c.px(26, 34, scrubsL); c.px(27, 35, scrubsL); c.px(30, 33, scrubsD); c.px(29, 34, scrubsD)
    c.rect(31, 35, 4, 1, scrubsD); c.px(32, 34, C(0x2A3A8A)); c.px(33, 34, C(0xC03030))
    c.rect(19, 34, 1, 3, scrubsL); c.rect(37, 33, 1, 5, scrubsD); c.rect(18, 37, 20, 1, scrubsD)
    c.rect(21, 35, 2, 2, C(0xF2F2F0)); c.px(21, 35, C(0x5A84B8))   // the ID badge
    // The stethoscope: dark tubing round the back of her neck and down either side of the V, its chrome chest piece.
    c.rect(23, 33, 1, 3, tube); c.rect(32, 33, 1, 3, tube); c.px(24, 36, tube); c.px(31, 36, tube)
    c.rect(24, 37, 2, 1, chrome); c.px(24, 37, C(0xF0F2F6))
    c.rect(15, 35, 3, 1, scrubsD)
    c.rect(38, 35, 3, 1, scrubsD)

    // Dark hair pulled back tight, a side fringe swept across her brow, the band of the ponytail at the back.
    c.pattern(17, 21, [
        "......HHHHHHHHH.......",
        "....HHHHlHHHlHHHH.....",
        "..HHHlHHHHHlHHHHHHH...",
        ".HHHHHHHHHHHHHHHHHHHH.",
        ".HHHHHHhhHHHHHHHHHHHd.",
        ".HHH......hhHHHHHHHd..",
        ".HH................d..",
        ".Hd...................",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    c.px(17, 24, C(0x8A3A5A)); c.px(17, 25, C(0x8A3A5A))   // the hair tie
    h4Brows(c, hairD)

    // The compact pistol, told apart from every other hunter's black one: short and chunky, a bright stainless slide
    // with grip serrations at the back and a lit top, on a black frame with a fat little trigger guard.
    c.oy += p.gunY
    c.pattern(38, 29, [
        "..llllll",
        "..SsSSSS",
        "..KKKKKd",
        "OOOKk.K.",
        "OOOKkk..",
        ".OKK....",
    ], ["S": C(0xD4D8DE), "s": C(0x8A9098), "l": C(0xF4F6F8), "K": C(0x1A1A1E), "k": C(0x101012),
        "d": C(0x3A3C42), "O": clawdOrange])
}

// MARK: - Eileen Leahy

/// Eileen Leahy: the hunter from Ireland, deaf and a lip-reader, with long dark hair in loose waves from a side
/// parting; an olive field jacket with its collar out, two flapped chest pockets with buttons and a zip, over a cream
/// knit top; dark jeans and brown boots. Fights with a pistol with a long suppressor on the barrel. Signature: she
/// signs "hi", her hand up high in a big wave.
private func drawEileenLeahy(_ c: PixelCanvas, _ p: Pose) {
    let jacket = C(0x55663C), jacketD = C(0x3A4828), jacketL = C(0x768A54), button = C(0x2A2A22)
    let knit = C(0xDCD0B4), knitD = C(0xB8AC90)
    let hair = C(0x2A1A14), hairD = C(0x180E0A), hairL = C(0x4A3226)
    let k = h4Span(p, 0.06, 0.94)
    let up = h4Ease(k, edge: 0.18)
    let raise = Int((up * 9).rounded())

    drawLegs(c, Look(leg: C(0x34405A)), step: p.step)
    if !seatedPose { for lx in [19, 23, 31, 35] { c.px(lx, 39, C(0x4A587A)) } }
    drawBoots(c, C(0x5E3E26), step: p.step, rows: 2)

    c.oy += p.breathe
    drawBody(c, Look(arm: jacket), armRight: raise)

    // The field jacket: a collar out and lit, open on the knit top, two chest pockets with flaps and buttons, the zip
    // on the near front edge, the far side and the hem in shade, cuffs.
    c.rect(18, 33, 20, 5, jacket)
    c.rect(25, 33, 6, 5, knit); c.rect(25, 33, 6, 1, knitD); c.px(26, 35, knitD); c.px(29, 36, knitD)
    c.rect(20, 33, 4, 1, jacketL); c.rect(32, 33, 3, 1, jacketL); c.px(24, 33, jacketL)
    c.rect(24, 34, 1, 4, jacketD); c.px(24, 35, C(0x9A9C8E)); c.rect(31, 33, 1, 5, jacketD)
    c.rect(19, 34, 4, 1, jacketD); c.px(21, 35, button)
    c.rect(33, 34, 3, 1, jacketD); c.px(34, 35, button)
    c.rect(37, 33, 1, 5, jacketD); c.rect(18, 37, 20, 1, jacketD); c.rect(18, 34, 1, 3, jacketL)
    c.rect(15, 35, 3, 1, jacketD)
    if raise == 0 { c.rect(38, 35, 3, 1, jacketD) }

    // Long dark hair in loose waves from a side parting, lit in strokes on top, past her shoulders.
    c.pattern(16, 20, [
        ".......HHHHHHHHHH.......",
        ".....HHHlHHHlHHlHHH.....",
        "...HHHlHHHlHHHHHlHHHH...",
        "..HHlHHHHHHHHHHHHHlHHH..",
        ".HHHHHHHHhHHHHHHHHHHHHd.",
        ".HHHHhHHHHHhhHHHHHHHHHd.",
        ".HHHHHHH........HHHHHHd.",
        "HHHH..............HHHHd.",
        "HHlH..............HHHd..",
        ".HlHH..............HHd..",
        ".HHlH..............HHHd.",
        "HHlH...............dHHd.",
        "HlHH...............HHd..",
        ".HHd...............HHd..",
        ".Hd................dd...",
        "........................",
    ], ["H": hair, "h": hairD, "l": hairL, "d": hairD])
    h4Brows(c, hairD)

    if k >= 0 {
        // "Hi": her open hand up high, fingers spread, waving side to side, a sleeve under it.
        if raise > 3 {
            let wave = k > 0.2 && k < 0.82 ? Int((sin((k - 0.2) / 0.62 * 6 * .pi) * 1.6).rounded()) : 0
            let hy = 33 - raise
            c.pattern(38 + wave, hy - 6, [
                "o.o.o.",
                "o.o.o.",
                "ooooo.",
                "ooooo.",
                "oooood",
                ".ooo..",
            ], ["o": clawdOrange, "d": clawdShade])
            c.rect(38, hy - 1, 3, 2, clawdOrange)
        }
        return   // the pistol tucked away while she signs
    }

    // The pistol: a black slide lit along the top, and the long suppressor screwed onto the barrel, a darker band at
    // each end.
    c.oy += p.gunY
    c.pattern(38, 30, [
        "..GGGGGGtSSSSSl",
        "..KKKKKKtssssst",
        "OOOKk.k........",
        "OOOK...........",
        ".OKK...........",
    ], ["G": C(0x2E3036), "K": C(0x1A1A1E), "k": C(0x101012), "S": C(0x6A6E76), "s": C(0x4A4E56), "l": C(0x9EA2AA),
        "t": C(0x26282E), "O": clawdOrange])
}
