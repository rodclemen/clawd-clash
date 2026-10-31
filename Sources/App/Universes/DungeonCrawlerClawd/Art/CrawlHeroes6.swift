import Foundation

// Heroes, 8 to 10 a file, drawn the same way as the heroes (CrawlHeroes1.swift).
//
// The rest of the NPC allies and the show's side: Pater Coal, Edgar, Ferdinand, Quasar, Rosetta Thagra, Tipid,
// Princess Formidable, Orthrus, and Garret (agent only).

let crawlHeroes6: [CrawlHero: Persona] = [
    .paterCoal: Persona(name: "Pater Coal", weapon: .blaster, shot: .fire, muzzle: (43, 33), handGun: false,
                        headTop: 22, signature: 3.2, draw: drawPaterCoal),
    .edgar: Persona(name: "Edgar", weapon: .none, headTop: 14, signature: 3.0, draw: drawEdgar),
    .ferdinand: Persona(name: "Ferdinand", weapon: .lightning, magic: Magic(core: C(0xFFFBD8), glow: C(0xF4D21E)),
                        pivot: (35, 21), headTop: 13, signature: 2.8, draw: drawFerdinand),
    .quasar: Persona(name: "Quasar", weapon: .none, headTop: 11, signature: 3.0, draw: drawQuasar),
    .rosetta: Persona(name: "Rosetta Thagra", weapon: .blaster, shot: .thrown(C(0x30303A)), muzzle: (43, 30),
                      handGun: false, headTop: 20, signature: 3.4, draw: drawRosetta),
    .tipid: Persona(name: "Tipid", weapon: .blaster, shot: .thrown(C(0xA8E040)), muzzle: (43, 31), handGun: false,
                    headTop: 17, signature: 3.0, draw: drawTipid),
    .formidable: Persona(name: "Princess Formidable", weapon: .blaster,
                         shot: .energy(core: C(0xE4F6FF), glow: C(0x2AA0FF)), muzzle: (51, 33), handGun: false,
                         headTop: 18, signature: 3.0, draw: drawFormidable),
    .orthrus: Persona(name: "Orthrus", weapon: .saber, bulk: 4, headTop: 11, signature: 3.2, draw: drawOrthrus),
    .garret: Persona(name: "Garret", weapon: .saber, headTop: 20, signature: 3.0, draw: drawGarret),
]

// MARK: - Shared bits

/// The bottom row of leg `i` this frame: a row higher while it's lifted in the walk.
private func crawlH6Foot(_ i: Int, _ step: Int) -> Int { step >= 0 && i % 2 == step ? 42 : 43 }

/// 0 outside `a`…`b`, rising to 1 over `edge` at the start and falling back over `edge` at the end.
private func crawlH6Arc(_ s: Double, _ a: Double, _ b: Double, edge: Double = 0.1) -> Double {
    guard s > a, s < b else { return 0 }
    return min(1, (s - a) / edge, (b - s) / edge)
}

/// A long robe from row `from` down to just above the toes, flared a pixel at the hem, lit on the left, a soft fold
/// beside each leg; shorter when seated. Returns the hem's bottom row.
@discardableResult
private func crawlH6Robe(_ c: PixelCanvas, _ robe: Px, _ robeD: Px, _ robeL: Px, from: Int) -> Int {
    let hem = seatedPose ? 39 : 42
    c.rect(18, from, 20, hem - from, robe)
    c.rect(17, from + 4, 22, hem - from - 4, robe)
    c.rect(16, hem - 2, 24, 2, robe)
    c.rect(18, from, 1, hem - from - 2, robeL); c.rect(17, from + 4, 1, hem - from - 4, robeL)
    c.rect(16, hem - 1, 24, 1, robeD); c.rect(38, from + 4, 1, hem - from - 4, robeD)
    if !seatedPose {
        for x in [22, 27, 30, 34] { c.rect(x, from + 5, 1, hem - from - 6, robeD) }
    }
    return hem
}

/// A bald head's dome over the top of the body, a shine on its upper left (Ifechi's, CrawlHeroes3.swift).
private func crawlH6Dome(_ c: PixelCanvas, _ skin: Px, _ shine: Px) {
    c.rect(20, 25, 16, 1, skin); c.rect(23, 24, 10, 1, skin)
    c.rect(24, 24, 3, 1, shine); c.rect(21, 25, 3, 1, shine); c.px(20, 26, shine)
}

// MARK: - Pater Coal

/// Pater Coal: Emberus's tiny old cleric, Clawd bald on top, his long white hair hanging in strands down both sides
/// and his back, bushy white brows; a long red robe to the ground with a gold collar and a gold band at the hem, and
/// the god's gold flame on his chest. He fights with Emberus's fire, thrown from his open palm. Signature: he holds up
/// his hand, palm to the sky, and a little flame rises from it, flickers and dies down.
private func drawPaterCoal(_ c: PixelCanvas, _ p: Pose) {
    let robe = C(0xB0282A), robeD = C(0x7E1A1E), robeL = C(0xD04A40)
    let gold = C(0xE8C040), goldD = C(0xB08A20), goldL = C(0xFFE890)
    let hair = C(0xF2F0EA), hairD = C(0xC4C0B8), hairL = C(0xFFFFFF)
    let s = p.signature ?? -1
    let lift = crawlH6Arc(s, 0.06, 0.94, edge: 0.1)
    let flame = crawlH6Arc(s, 0.18, 0.88, edge: 0.2)
    let raise = lift > 0.5 ? 6 : 0

    // 1. The legs under the robe, the toes peeping out under the hem.
    drawLegs(c, Look(leg: robeD), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, crawlH6Foot(i, p.step), 2, 1, clawdShade) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Clawd, the far arm in the robe's sleeve; the near one comes up for the flame.
    drawBody(c, Look(arm: robe), armRight: raise)
    c.rect(15, 35, 3, 1, robeD)

    // 4. The robe from the shoulders to the ground, a gold collar along its top, the gold band round the hem, and
    //    Emberus's flame on his chest in gold.
    let hem = crawlH6Robe(c, robe, robeD, robeL, from: 31)
    c.rect(18, 31, 20, 1, gold); c.rect(18, 31, 3, 1, goldL); c.rect(36, 31, 2, 1, goldD)
    c.rect(16, hem - 2, 24, 1, gold); c.rect(16, hem - 2, 2, 1, goldL); c.rect(38, hem - 2, 2, 1, goldD)
    c.pattern(26, 33, ["..G..", ".GYG.", "GGYGG", ".GGG."], ["G": gold, "Y": goldL])

    // 5. The bald crown and its shine, a crease across the brow, bushy white brows drooping at the ends.
    crawlH6Dome(c, clawdOrange, C(0xF0A486))
    c.rect(24, 26, 8, 1, clawdShade)
    c.rect(20, 27, 5, 1, hair); c.px(20, 28, hairD); c.rect(21, 27, 2, 1, hairL)
    c.rect(31, 27, 5, 1, hair); c.px(35, 28, hairD)
    c.rect(26, 32, 4, 1, clawdShade)   // a small, kindly mouth just above the collar

    // 6. The long white hair: strands from the sides of the crown, hanging down past his shoulders at the back and to
    //    his jaw at the front, lit along the top, ragged at the ends.
    for x in 14...19 {
        let top = x < 17 ? 25 : 24, bottom = 33 - (x * 2) % 3 + (x < 16 ? 2 : 0)
        c.rect(x, top, 1, bottom - top + 1, x % 2 == 0 ? hair : hairD)
        c.px(x, top, hairL)
    }
    for x in 35...38 {
        let bottom = 30 - (x * 2) % 3
        c.rect(x, 24, 1, bottom - 23, x % 2 == 1 ? hair : hairD)
        c.px(x, 24, hairL)
    }
    c.rect(19, 23, 4, 1, hair); c.rect(33, 23, 3, 1, hair); c.px(19, 23, hairL)

    // 7. The near hand: open at his side, palm forward (warm as he throws fire); or held up, palm to the sky, with the
    //    little flame rising off it, flickering, solid, its yellow heart low and its orange tongue on top.
    if raise > 0 {
        c.rect(38, 26, 4, 1, clawdOrange); c.px(38, 25, clawdOrange); c.px(41, 25, clawdOrange)
        c.rect(38, 27, 3, 1, robeL)
        if flame > 0 {
            let h = 2 + Int((flame * 6).rounded())
            for k in 0..<h {
                let f = Double(k) / Double(h)
                let half = Int(((1 - f) * 2.2).rounded())
                let wob = f > 0.4 ? Int((sin(p.lt * 13 + Double(k)) * 0.9).rounded()) : 0
                for dx in -half...half {
                    let edge = abs(dx) == half && half > 0
                    let col = edge || k == h - 1 ? C(0xF0602A) : (f < 0.45 ? C(0xFFF2B0) : C(0xFFB02A))
                    c.px(40 + dx + wob, 24 - k, col)
                }
            }
        }
    } else {
        c.rect(41, 33, 2, 3, clawdOrange); c.px(42, 33, C(0xEE9A7A))
        if p.fire != nil { c.px(43, 34, C(0xFFD060)); c.px(43, 33, C(0xFFB02A, 0.6)) }
    }
}

// MARK: - Edgar

/// Edgar: a giant talking tortoise, Clawd under a great domed shell, brown and olive, its plates picked out by dark
/// seams, lit along its top, a ring of ochre plates round the rim; a cream belly plate below it. His wrinkly grey-olive
/// head pokes out on its neck at the front, sleepy-lidded, a horny beak; thick elephant-like legs with pale toenails.
/// He doesn't fight. Signature: he pulls out a tattoo gun, which buzzes away in his front foot, a drop of ink at its
/// needle, and his eyes open wide.
private func drawEdgar(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x8E9070), skinD = C(0x6A6C52), skinL = C(0xAEB08E)
    let shell = C(0x6E4E2A), shellD = C(0x3E2A16), shellL = C(0x987040), rim = C(0xA8823E), rimD = C(0x7C5C28)
    let belly = C(0xD8C890), bellyD = C(0xB0A068)
    let nail = C(0xE0D8BC), beak = C(0x5A5644)
    let s = p.signature ?? -1
    let gun = s > 0.1 && s < 0.9
    let buzz = gun && s > 0.22 && s < 0.82

    // 1. Thick wrinkly legs, lit on the left, a scale stroke or two, pale toenails on the ground.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, skin); c.rect(lx - 1, 38, 4, 1, skinL); c.px(lx + 2, 39, nail) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = crawlH6Foot(i, p.step)
            c.rect(lx - 1, 36, 3, b - 35, skin)
            c.rect(lx - 1, 36, 1, b - 36, skinL); c.rect(lx + 1, 37, 1, b - 37, skinD)
            c.px(lx, 39 + i % 2, skinD)
            c.px(lx - 1, b, nail); c.px(lx + 1, b, nail)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Clawd, under it all in grey-olive skin, and the cream belly plate along the bottom, its seams marked.
    drawBody(c, Look(body: skin, shade: skinD, arm: skin, eye: nil))
    c.rect(17, 33, 22, 4, belly); c.rect(17, 36, 22, 1, bellyD)
    for x in [22, 28, 34] { c.rect(x, 33, 1, 3, bellyD) }

    // 4. The domed shell over his back: a central row of plates with dark seams, a ring of side plates round them
    //    split by seams running out from the middle, and the rim of ochre plates along the bottom edge. Lit along its
    //    top and on the left, in shade on the lower right.
    let cx = 26.5, cy = 33.0, rx = 13.5, ry = 19.0
    for x in 13...39 {
        let u = (Double(x) + 0.5 - cx) / rx
        let top = Int((cy - sqrt(max(0, 1 - u * u)) * ry).rounded())
        guard top <= 33 else { continue }
        for y in top...33 {
            let v = (cy - Double(y)) / ry
            let r = sqrt(u * u + v * v)
            let theta = atan2(v, u)
            var col = shell, plain = false
            if y >= 31 {
                col = x % 4 == 1 ? rimD : (y == 31 ? rim : rimD)
            } else if abs(r - 0.6) < 0.05 {
                col = shellD
            } else if r < 0.6 {
                if x == 21 || x == 32 || (y == 22 && x > 21 && x < 32) { col = shellD } else { plain = true }
            } else {
                let step = Double.pi / 5
                let off = abs(theta - (theta / step).rounded() * step) * r * ry
                if off < 0.6 { col = shellD } else { plain = true }
            }
            if plain {
                if y == top || (u < -0.3 && v > 0.3 && (x + y) % 3 == 0) { col = shellL }
                else if u + (1 - v) > 1.4 { col = C(0x5A3E20) }
            }
            c.px(x, y, col)
        }
    }

    // 5. The neck, reaching out of the front of the shell from the shadow under it, and the head on it: wrinkly,
    //    lit on top, a horny beak, a sleepy eye under its heavy lid (wide open while he tattoos).
    c.rect(36, 27, 5, 6, skin); c.rect(36, 32, 5, 1, skinD); c.rect(36, 27, 1, 6, C(0x2E2418))
    c.px(38, 29, skinD); c.px(39, 31, skinD); c.px(38, 31, skinD)
    c.pattern(38, 21, [
        "...SSSSS...",
        ".SSLLLLSS..",
        "SSLSSSSSSS.",
        "SSSSSSSSSSS",
        "SSSSSSSSSBB",
        "SSdSSSSmmmB",
        ".SSSSSSSSB.",
        "..dSSSSSd..",
    ], ["S": skin, "L": skinL, "d": skinD, "B": beak, "m": C(0x2A2620)])
    if gun {
        c.rect(44, 23, 2, 2, ink); c.px(44, 23, white); c.rect(43, 22, 4, 1, skinD)
    } else {
        c.rect(44, 24, 2, 1, ink); c.rect(43, 23, 4, 1, skinD); c.rect(44, 23, 2, 1, skinD)
    }

    // 6. The near front foot, and in the signature the tattoo gun in it: a steel frame, two copper coils, a black
    //    grip, the needle with a drop of ink, buzzing (it shakes, and lines fizz off it).
    if gun {
        let j = buzz ? Int(p.lt * 30) % 2 : 0
        c.rect(39, 32, 3, 3, skin); c.rect(39, 34, 3, 1, skinD)
        c.pattern(41 + j, 27, [
            ".cc.cc..",
            ".CC.CC..",
            "FFFFFFFF",
            "...gF...",
            "...gF...",
            "....n...",
        ], ["c": C(0xE89A5A), "C": C(0xB86A2A), "F": C(0x9AA2AE), "g": C(0x22222A), "n": C(0xD8DCE4)])
        c.px(45 + j, 33, C(0x3A5AD0))
        if buzz, Int(p.lt * 12) % 2 == 0 {
            for (dx, dy) in [(0, 0), (1, -1), (2, 0), (3, -1)] {
                c.px(50 + dx, 26 + dy, C(0xFFF6C8, 0.85)); c.px(50 + dx, 30 + dy, C(0xFFF6C8, 0.85))
            }
        }
    } else {
        c.rect(39, 34, 3, 3, skin); c.px(39, 34, skinL); c.px(41, 36, nail)
    }
}

// MARK: - Ferdinand

/// Ferdinand: a yellow-orange tomcat, Clawd in ginger fur with dark tabby stripes along his flanks, a cream muzzle and
/// belly, a pink nose and white whiskers, green eyes with black slits, and a curled striped tail; his ears poke out
/// either side of a great gold turban, wound in folds, a red jewel at its front with a white plume. His forked yellow
/// lightning crackles from the turban's jewel. Signature: he phase-jumps, blinking out in a burst of sparkles and back.
private func drawFerdinand(_ c: PixelCanvas, _ p: Pose) {
    let s = p.signature ?? -1
    let gone = crawlH6Arc(s, 0.3, 0.7, edge: 0.05)
    guard gone > 0 || (s > 0.22 && s < 0.78) else { drawFerdinandBody(c, p); return }

    // The jump: solid, then gone (never left half see-through for long), with a burst of sparkles flying out as he
    // goes and falling back in as he returns.
    if gone < 1 {
        let fig = PixelCanvas(Sprite.width, Sprite.height)
        drawFerdinandBody(fig, p)
        c.paste(fig, alpha: gone > 0.85 ? 0 : 1 - gone)
    }
    let k = crawlH6Arc(s, 0.22, 0.78, edge: 0.12)
    for i in 0..<10 {
        let a = Double(i) * .pi / 5 + s * 4
        let r = 3 + k * 10
        let x = Int((28 + cos(a) * r * 1.2).rounded()), y = Int((30 + sin(a) * r * 0.8).rounded())
        let col = i % 2 == 0 ? C(0xFFF4A0, k) : C(0xFFFFFF, k)
        c.px(x, y, col)
        if (i + Int(p.lt * 10)) % 3 == 0 {
            c.px(x - 1, y, col.alpha(0.5)); c.px(x + 1, y, col.alpha(0.5))
            c.px(x, y - 1, col.alpha(0.5)); c.px(x, y + 1, col.alpha(0.5))
        }
    }
}

private func drawFerdinandBody(_ c: PixelCanvas, _ p: Pose) {
    let fur = C(0xF0A83A), furD = C(0xC07E22), furL = C(0xFFCC66), stripe = C(0xB0661A)
    let cream = C(0xFCE8C0), pink = C(0xF08A9A), eye = C(0x6AD04A)
    let cloth = C(0xE8BE3A), clothD = C(0xB08A20), clothL = C(0xFFE27A)
    let casting = p.zap != nil

    // 1. Ginger legs, a stripe across each, cream paws.
    drawLegs(c, Look(leg: fur), step: p.step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = crawlH6Foot(i, p.step)
            c.rect(lx, 39, 2, 1, stripe); c.rect(lx, b, 2, 1, cream); c.px(lx + 1, 36, furD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail, curling up behind him, striped, its tip hooked over.
    let sway = sin(p.lt * 1.6) * 0.8
    let pts: [(Double, Double)] = [(18, 34), (15.5, 33.5), (13.5, 31.5), (12.5 + sway * 0.3, 28.5),
                                   (12.5 + sway * 0.6, 25.5), (13.5 + sway, 23), (15.5 + sway, 22)]
    for j in 1..<pts.count {
        c.glowLine(pts[j - 1].0, pts[j - 1].1, pts[j].0, pts[j].1, core: fur, glow: C(0, 0), coreR: 1.05, glowR: 1.1)
    }
    for j in [1, 3, 5] { c.rect(Int(pts[j].0) - 1, Int(pts[j].1), 3, 1, stripe) }

    // 4. The body in ginger fur, lit on top and the left; tabby stripes along his flanks, a cream belly.
    drawBody(c, Look(body: fur, shade: furD, arm: fur, eye: nil))
    c.rect(18, 26, 1, 11, furL)
    for y in [32, 35] { c.rect(18, y, 3, 1, stripe); c.rect(35, y, 3, 1, stripe) }
    c.rect(19, 33, 2, 1, stripe); c.rect(35, 33, 2, 1, stripe)
    c.rect(23, 35, 10, 2, cream); c.rect(24, 34, 8, 1, cream)
    c.px(15, 35, furD)

    // 5. The face: green eyes with black slits under a dark lid, three tabby strokes on the brow, the cream muzzle,
    //    a pink nose, the little mouth, and white whiskers out to the sides.
    for x in [21, 32] {
        c.rect(x, 29, 3, 2, casting ? C(0xC8F07A) : eye); c.rect(x + 1, 29, 1, 2, ink)
        c.rect(x, 28, 3, 1, furD)
    }
    c.rect(25, 26, 1, 2, stripe); c.rect(28, 26, 1, 2, stripe); c.rect(31, 26, 1, 2, stripe)
    c.rect(25, 31, 7, 2, cream); c.rect(26, 33, 5, 1, cream)
    c.rect(27, 31, 3, 1, pink); c.px(28, 32, furD); c.px(27, 33, furD); c.px(29, 33, furD)
    let whisker = C(0xFFF8E8)
    c.rect(20, 31, 4, 1, whisker); c.rect(19, 33, 4, 1, whisker)
    c.rect(33, 31, 4, 1, whisker); c.rect(33, 33, 4, 1, whisker)

    // 6. His ears, poking out either side of the turban, pink inside.
    c.pattern(14, 20, ["F...", "FF..", "FpF.", "FFFF"], ["F": fur, "p": pink])
    c.pattern(38, 20, ["...F", "..FF", ".FpF", "FFFF"], ["F": fur, "p": pink])

    // 7. The gold turban, wound in folds slanting across it, lit on top, its bottom band in shade.
    c.pattern(17, 16, [
        ".......TTTTTTTT.......",
        "....TTLLLLTTTTTTTT....",
        "..TTLLTTTTdTTTTdTTTT..",
        ".TTLTTTTdTTTTdTTTTdTT.",
        ".TLTTTdTTTTdTTTTdTTTD.",
        "TTTTdTTTTdTTTTdTTTTTDT",
        "TTTdTTTTdTTTTdTTTTTDDT",
        "TdTTTTdTTTTdTTTTdTTDDT",
        "TTTTTdTTTTdTTTTdTTTTDT",
        ".DDDDDDDDDDDDDDDDDDDD.",
    ], ["T": cloth, "L": clothL, "d": clothD, "D": clothD])

    // 8. The plume, a white feather curling back off the jewel, and the jewel itself, red in a gold setting: it
    //    blazes yellow while he casts.
    c.pattern(28, 12, [
        "WW.....",
        ".WWW...",
        "..wWWW.",
        "....wWW",
        "......W",
    ], ["W": C(0xF8F4EC), "w": C(0xC8C4BC)])
    c.rect(33, 20, 3, 3, clothD); c.rect(34, 20, 2, 2, C(0xD0283A)); c.px(34, 20, C(0xFFB0B8))
    if casting {
        c.rect(34, 20, 2, 2, C(0xFFF4A0))
        c.ellipse(35, 21, 3, 3, C(0xFFE84A, 0.18))
    }
}

// MARK: - Quasar

/// Quasar: a grey alien lawyer, his huge bald bulbous head a dome far wider than his shoulders, lit on the upper left,
/// with two great black almond eyes, a glint in each, and a tiny mouth. A navy suit with a white shirt, and a silly
/// tie: an upside-down pineapple, its fruit up by the knot and its green crown hanging down between his legs. In his
/// near hand, his briefcase. He doesn't fight. Signature: the pineapple tie blinks, its little lights flashing.
private func drawQuasar(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x9A9EA6), skinD = C(0x74787F), skinL = C(0xC2C6CC)
    let suit = C(0x2A3450), suitD = C(0x1C2438), suitL = C(0x445274), shirt = C(0xF0F0F0)
    let yellow = C(0xF0C838), yellowD = C(0xB88A1E), leaf = C(0x4AA83A), leafD = C(0x2E7A28)
    let leather = C(0x7A4A28), leatherD = C(0x52301A), leatherL = C(0x9A6438)
    let s = p.signature ?? -1
    let blink = s > 0.08 && s < 0.92

    // 1. Navy trouser legs and black shoes.
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x16161C), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, 37, suitD); c.px(lx + 2, crawlH6Foot(i, p.step), C(0x16161C)) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body, grey; the navy suit jacket over it, lit on the left, the far side in shade, its lapels round a
    //    white shirt front, a fold or two.
    drawBody(c, Look(body: skin, shade: skinD, arm: suit, eye: nil))
    c.rect(18, 31, 20, 7, suit)
    c.rect(18, 31, 1, 7, suitL); c.rect(36, 31, 2, 7, suitD); c.rect(18, 37, 20, 1, suitD)
    c.pattern(23, 31, ["LWWWWWWWL", ".LWWWWWL.", "..LWWWL..", "...LWL..."], ["W": shirt, "L": suitL])
    c.rect(21, 34, 1, 3, suitD); c.rect(34, 34, 1, 3, suitD)
    c.px(31, 36, C(0xC8CCD4))   // a button

    // 4. The upside-down pineapple tie: a yellow knot, the fruit widening under it in a criss-cross of darker
    //    scales, and its spiky green crown hanging down past the jacket. In the signature its scales blink.
    let lights = [C(0xFF4A4A), C(0x5AF07A), C(0x5AA8FF), C(0xFFFFFF)]
    let tick = Int(p.lt * 6)
    c.rect(27, 31, 3, 1, yellowD)
    c.pattern(26, 32, [".YyY.", ".yYy.", "YyYyY", "yYyYy", ".YyY."], ["Y": yellow, "y": yellowD])
    c.pattern(26, 37, [".gGg.", "g.G.g"], ["g": leaf, "G": leafD])
    if blink {
        let dots = [(27, 32), (28, 33), (26, 34), (28, 34), (30, 34), (27, 35), (29, 35), (28, 36)]
        for (j, d) in dots.enumerated() {
            c.px(d.0, d.1, lights[(j + tick) % lights.count])
        }
        c.ellipse(28, 34, 4, 3, C(0xFFF0A0, 0.12))
    }

    // 5. The great bulbous head: a wide dome over the top of the body, lit on the upper left, in shade on the lower
    //    right, narrowing to a small chin.
    let hx = 28.0, hy = 20.0, hrx = 12.6, hry = 10.2
    for y in 10...30 {
        for x in 15...40 {
            let nx = (Double(x) + 0.5 - hx) / hrx, ny = (Double(y) + 0.5 - hy) / hry
            guard nx * nx + ny * ny <= 1 else { continue }
            var col = skin
            let rim = nx * nx + ny * ny
            if rim > 0.8 && nx > 0.35 && ny > -0.6 { col = skinD } else if rim > 0.6 && nx + ny < -0.8 { col = skinL }
            c.px(x, y, col)
        }
    }
    c.rect(22, 29, 12, 2, skin); c.rect(32, 29, 2, 2, skinD)
    c.rect(20, 11, 4, 1, C(0xE4E8EC))   // the shine on the crown

    // 6. The huge black almond eyes, slanting up and out, a white glint in each; the tiny mouth.
    let black = C(0x101014)
    c.pattern(18, 19, [
        "kkkk....",
        "kkkkkk..",
        ".kWkkkk.",
        "..kkkkk.",
        "....kk..",
    ], ["k": black, "W": white])
    c.pattern(30, 19, [
        "....kkkk",
        "..kkkkkk",
        ".kkkkWk.",
        ".kkkkk..",
        "..kk....",
    ], ["k": black, "W": white])
    c.rect(27, 27, 3, 1, skinD)

    // 7. The near hand, a navy sleeve and a grey hand, and the briefcase hanging from it: brown leather, lit along its
    //    top, a darker bottom edge, a gold clasp.
    c.rect(38, 33, 3, 3, suit); c.px(38, 33, suitL)
    c.rect(40, 35, 2, 2, skin)
    c.rect(41, 36, 4, 1, leatherD)
    c.rect(39, 37, 9, 5, leather); c.rect(39, 37, 9, 1, leatherL); c.rect(39, 41, 9, 1, leatherD)
    c.rect(47, 38, 1, 3, leatherD)
    c.rect(42, 38, 2, 1, C(0xE8C040))
}

// MARK: - Rosetta Thagra

/// Rosetta Thagra: a Crest, Clawd in pinkish-tan leathery skin, bald, a few creases on her brow, gold earrings, stern
/// thin brows and a dark red mouth; a teal pantsuit, its lapels round a white blouse, gold buttons. On her bald head
/// sits her movable blob of hair, a purple tuft of strands. She throws black bombs, one always in her hand, its fuse
/// fizzing. Signature: the hair blob slides across her head and back, changing colour as it goes.
private func drawRosetta(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0xC89A86), skinD = C(0xA07462), skinL = C(0xE4BCA8)
    let suit = C(0x2E7A80), suitD = C(0x1E5A60), suitL = C(0x4E9CA2), blouse = C(0xF2F0EC)
    let gold = C(0xE8C040), bomb = C(0x2A2A32), bombL = C(0x5A5A6A)
    let s = p.signature ?? -1
    let move = crawlH6Arc(s, 0.05, 0.95, edge: 0.45)
    let hue = s > 0.05 && s < 0.95 ? (s - 0.05) / 0.9 : 0

    // 1. Teal trouser legs, black shoes with a little heel.
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, C(0x18181E), step: p.step, rows: 1)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.px(lx + 1, 37, suitD); c.px(lx, crawlH6Foot(i, p.step) - 1, C(0x18181E)) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in leathery skin, lit on the left, a couple of creases on the brow; the bald dome.
    drawBody(c, Look(body: skin, shade: skinD, arm: suit))
    crawlH6Dome(c, skin, skinL)
    c.rect(18, 26, 1, 5, skinL)
    c.rect(24, 26, 3, 1, skinD); c.rect(29, 26, 4, 1, skinD)
    c.rect(21, 28, 3, 1, skinD); c.rect(32, 28, 3, 1, skinD)   // stern brows
    c.rect(26, 31, 4, 1, C(0x8A2A3A))                         // the mouth
    c.px(17, 30, gold); c.px(17, 31, gold); c.px(38, 30, gold); c.px(38, 31, gold)

    // 4. The teal pantsuit jacket: lapels round a white blouse, lit on the left, the far side in shade, gold buttons.
    c.rect(18, 32, 20, 6, suit)
    c.rect(18, 32, 1, 6, suitL); c.rect(36, 32, 2, 6, suitD); c.rect(18, 37, 20, 1, suitD)
    c.pattern(24, 32, ["LBBBBBBL", ".LBBBBL.", "..LBBL.."], ["B": blouse, "L": suitL])
    c.px(28, 35, gold); c.px(28, 37, gold)
    c.rect(20, 35, 3, 1, suitD); c.rect(33, 35, 3, 1, suitD)

    // 5. The hair blob: a tuft of strands sitting on her crown, sliding across to the right and back in the signature,
    //    its colour turning from purple through green and orange back to purple.
    let tones: [(Px, Px, Px)] = [(C(0x8A4AD0), C(0x6230A0), C(0xB080F0)), (C(0x4AC86A), C(0x2E9448), C(0x90F0A0)),
                                 (C(0xF08A2A), C(0xC0601A), C(0xFFC070)), (C(0x8A4AD0), C(0x6230A0), C(0xB080F0))]
    let seg = min(2.999, hue * 3), j = Int(seg), f = seg - Double(j)
    let hair = lerp(tones[j].0, tones[j + 1].0, f), hairD = lerp(tones[j].1, tones[j + 1].1, f)
    let hairL = lerp(tones[j].2, tones[j + 1].2, f)
    let bx = 19 + Int((move * 10).rounded())
    let by = bx > 22 && bx < 31 ? 20 : 21
    c.pattern(bx, by, [
        "..lLl..",
        ".HhHhH.",
        "HhHhHhH",
        "HhHhHhH",
    ], ["H": hair, "h": hairD, "l": hairL, "L": hairL])

    // 6. The near hand and its bomb: a round black bomb lit on its upper left, its fuse fizzing with sparks (gone a
    //    moment as she throws it).
    c.rect(38, 33, 3, 3, suit); c.px(38, 33, suitL); c.rect(40, 33, 2, 2, skin)
    if p.recoil == 0 {
        c.pattern(39, 28, [".BBB.", "BLBBB", "BBBBB", ".BBB."], ["B": bomb, "L": bombL])
        c.px(42, 27, C(0x8A6A3A)); c.px(43, 26, C(0x8A6A3A))
        let n = Int(p.lt * 14)
        c.px(44, 25, n % 2 == 0 ? C(0xFFF2A0) : C(0xFF9A2A)); if n % 3 == 0 { c.px(45, 24, C(0xFFD040)) }
    }
}

// MARK: - Tipid

/// Tipid: a tall Crest, Clawd in dark leathery brown, his bald head rising tall above his brow, creased across, a pale
/// scar slashed over it with its stitches; one brow cocked, the other eye in a squint, and a sideways grin up on one
/// side. A long brown leather coat with its collar up, a bandolier of green poison vials across it, dark trousers and
/// boots. He throws the vials. Signature: the sideways grin goes wide, a glint on his teeth, and a thumbs up.
private func drawTipid(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x9C7C60), skinD = C(0x765A42), skinL = C(0xBC9C7E)
    let coat = C(0x5A3E28), coatD = C(0x3E2A1A), coatL = C(0x7A5838), strap = C(0xA88452)
    let vial = C(0xA8E040), vialD = C(0x6A9A20), vialL = C(0xE8FFB0), cork = C(0x9A6A3A)
    let scar = C(0xE8B4A8), tooth = C(0xF4F0E4)
    let s = p.signature ?? -1
    let thumb = crawlH6Arc(s, 0.12, 0.88, edge: 0.12) > 0.5
    let grin = s > 0.08 && s < 0.92

    // 1. Dark trousers and brown boots.
    drawLegs(c, Look(leg: C(0x3A3430)), step: p.step)
    drawBoots(c, coatD, step: p.step, rows: 2)

    // 2. The breath.
    c.oy += p.breathe

    // 3. The body in leathery brown; his tall bald head rising above it, lit along its top and on the left, creases
    //    across it.
    drawBody(c, Look(body: skin, shade: skinD, arm: coat, eye: nil), armRight: thumb ? 5 : 0)
    c.pattern(18, 17, [
        ".....LLLLLLLL.......",
        "...LLSSSSSSSSSS.....",
        "..LSSSSSSSSSSSSSS...",
        ".LSSSSSSSSSSSSSSSd..",
        ".LSSSSSSSSSSSSSSSSd.",
        "LSSSSSSSSSSSSSSSSSSd",
        "LSSSSSSSSSSSSSSSSSSd",
        "LSSSSSSSSSSSSSSSSSSd",
        "LSSSSSSSSSSSSSSSSSSd",
    ], ["S": skin, "L": skinL, "d": skinD])
    c.rect(18, 26, 1, 6, skinL)
    c.rect(22, 21, 4, 1, skinD); c.rect(29, 22, 5, 1, skinD); c.rect(23, 24, 6, 1, skinD)

    // 4. The scar slashed across his head, pale, its stitches crossing it.
    for k in 0...9 {
        let x = 22 + k, y = 18 + Int((Double(k) * 0.55).rounded())
        c.px(x, y, scar)
        if k % 3 == 1 { c.px(x, y - 1, skinD); c.px(x, y + 1, skinD) }
    }

    // 5. The face: the left brow cocked up, the right eye in a squint; the sideways grin, flat on the left and
    //    turned up on the right, his teeth in it (wider, with a glint, in the signature).
    c.pattern(21, 26, ["..d", "dd."], ["d": C(0x4A3426)])
    c.rect(22, 29, 2, 3, ink)
    c.rect(31, 29, 4, 1, C(0x4A3426)); c.rect(32, 30, 2, 1, ink)
    let mouth = C(0x3A1E1A)
    c.rect(25, 32, 9, 1, mouth); c.px(34, 31, mouth); c.px(35, 30, mouth)
    c.rect(29, 32, grin ? 5 : 3, 1, tooth)
    if grin { c.px(34, 31, tooth); c.px(25, 32, mouth) }
    if grin && Int(p.lt * 6) % 3 == 0 {
        c.px(36, 28, white); c.px(35, 28, C(0xFFFFFF, 0.5)); c.px(37, 28, C(0xFFFFFF, 0.5))
        c.px(36, 27, C(0xFFFFFF, 0.5)); c.px(36, 29, C(0xFFFFFF, 0.5))
    }

    // 6. The long leather coat from the collar down, the collar turned up and lit, the far side in shade; the tan
    //    bandolier across it with four green vials in their loops, corked.
    c.rect(18, 33, 20, 5, coat)
    c.rect(18, 33, 20, 1, coatL); c.rect(18, 33, 1, 5, coatL); c.rect(36, 34, 2, 4, coatD)
    c.rect(27, 34, 1, 4, coatD)
    c.rect(18, 37, 20, 1, strap)
    for x in [20, 24, 30, 34] {
        c.px(x, 34, cork); c.rect(x, 35, 2, 2, vial); c.px(x, 35, vialL); c.px(x + 1, 36, vialD)
    }

    // 7. The near hand: a vial ready to throw (gone a moment as he throws it), or raised in a thumbs up.
    if thumb {
        c.rect(38, 28, 3, 3, coat); c.px(38, 28, coatL)
        c.rect(40, 25, 4, 4, skin); c.rect(40, 25, 1, 4, skinL); c.rect(43, 26, 1, 3, skinD)
        c.rect(41, 26, 2, 1, skinD); c.rect(41, 27, 2, 1, skinD)
        c.rect(40, 21, 2, 4, skinL); c.px(41, 21, skin)
    } else {
        c.rect(40, 34, 2, 2, skin)
        if p.recoil == 0 {
            c.px(42, 30, cork); c.rect(41, 31, 2, 3, vial); c.px(41, 31, vialL); c.px(42, 33, vialD)
        }
    }
}

// MARK: - Princess Formidable

/// Princess Formidable: an orc princess, Clawd in grey-green orc skin, a heavy brow over small amber eyes, two white
/// tusks jutting up from her jaw, little pointed ears; long black hair in strands down her back under a gold tiara with
/// a blue gem. A black spacesuit picked out in orange: an orange collar ring, orange side panels and belt, orange
/// boots. On her near arm, the black and orange arm cannon, its muzzle glowing blue. Signature: the cannon powers up,
/// lights running blue along it and a blue glow swelling at the muzzle, then a flash.
private func drawFormidable(_ c: PixelCanvas, _ p: Pose) {
    let skin = C(0x7C9A8A), skinD = C(0x5C7A6A), skinL = C(0x9CBAA8)
    let suit = C(0x1E1E26), suitD = C(0x121218), suitL = C(0x3A3A48)
    let orange = C(0xF07A1A), orangeD = C(0xB8560E), orangeL = C(0xFFA858)
    let hair = C(0x1A1418), hairL = C(0x3E3238), gold = C(0xE8C040), goldL = C(0xFFE890)
    let blue = C(0x5AC8FF), blueL = C(0xE4F6FF)
    let s = p.signature ?? -1
    let charge = s > 0.08 && s < 0.8 ? (s - 0.08) / 0.72 : 0
    let flash = crawlH6Arc(s, 0.78, 0.92, edge: 0.04)

    // 1. Black suit legs, orange boots lit on the toe.
    drawLegs(c, Look(leg: suit), step: p.step)
    drawBoots(c, orange, step: p.step, rows: 2)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = crawlH6Foot(i, p.step)
            c.px(lx, b - 1, orangeL); c.px(lx + 1, b, orangeD); c.px(lx + 1, 37, suitL)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. Her long black hair down her back, in strands, behind her.
    for x in 13...18 {
        let bottom = 34 - (x * 2) % 3 - (x < 15 ? 2 : 0)
        c.rect(x, 24, 1, bottom - 23, x % 2 == 0 ? hair : hairL)
    }

    // 4. The body: orc skin above, the black spacesuit below, lit on the left, an orange collar ring, orange
    //    panels down her sides, an orange belt with its buckle, a seam or two.
    drawBody(c, Look(body: skin, shade: skinD, arm: suit, eye: nil))
    c.rect(18, 26, 1, 6, skinL)
    c.rect(18, 32, 20, 6, suit)
    c.rect(18, 33, 1, 5, suitL); c.rect(36, 33, 2, 5, suitD)
    c.rect(18, 32, 20, 1, orange); c.rect(18, 32, 4, 1, orangeL); c.rect(35, 32, 3, 1, orangeD)
    c.rect(18, 33, 2, 4, orange); c.rect(18, 33, 1, 4, orangeL); c.rect(34, 33, 2, 4, orangeD)
    c.rect(18, 37, 20, 1, orangeD); c.rect(26, 36, 4, 2, orange); c.rect(27, 36, 2, 1, orangeL)
    c.rect(24, 34, 1, 2, suitL); c.rect(31, 34, 1, 2, suitL)

    // 5. The face: a heavy brow, small amber eyes, the tusks jutting up either side of her mouth, little ears.
    c.rect(20, 27, 5, 1, skinD); c.rect(31, 27, 5, 1, skinD)
    for x in [22, 32] { c.rect(x, 28, 2, 2, C(0xF0B030)); c.px(x + 1, 29, ink) }
    c.rect(25, 31, 7, 1, C(0x2A1A1E))
    c.rect(24, 29, 1, 2, white); c.rect(32, 29, 1, 2, white); c.px(24, 31, C(0xD8D4C8)); c.px(32, 31, C(0xD8D4C8))
    c.pattern(15, 27, ["L..", "SS.", ".SS"], ["S": skin, "L": skinL])

    // 6. The hair over the top of her head, strands swept back, and the gold tiara on it, its blue gem.
    c.pattern(17, 22, [
        "....HhHhHhHhHhHh....",
        "..HhHhHhHhHhHhHhHh..",
        ".hHhHhHhHhHhHhHhHhH.",
        "HhHhH..........HhHhH",
    ], ["H": hair, "h": hairL])
    c.pattern(21, 19, [
        "...g...g...g...",
        "..ggg.gBg.ggg..",
        "GGGGGGGGGGGGGGG",
    ], ["g": gold, "G": gold, "B": C(0x3A7AF0)])
    c.rect(21, 21, 3, 1, goldL)

    // 7. The arm cannon on her near arm: a black barrel lit along its top, two orange bands, the muzzle ring; its
    //    blue lights run along it as it powers up, and the glow at the muzzle swells and flashes.
    c.oy += p.gunY
    c.rect(38, 31, 11, 5, suit)
    c.rect(38, 31, 11, 1, suitL); c.rect(38, 35, 11, 1, suitD)
    c.rect(41, 31, 2, 5, orange); c.rect(41, 31, 2, 1, orangeL); c.rect(46, 31, 1, 5, orange)
    c.rect(49, 30, 2, 7, suitL); c.rect(50, 32, 1, 3, blue)
    if charge > 0 {
        let lit = Int((charge * 6).rounded(.up))
        for k in 0..<min(lit, 6) where k != 2 && k != 4 { c.px(39 + k * 2 - (k > 2 ? 1 : 0), 33, blue) }
        let r = Int((charge * 4).rounded())
        c.ellipse(52, 33, r + 2, r + 2, C(0x2AA0FF, 0.12 + 0.1 * charge))
        c.rect(51, 32, 1, 3, blueL); c.px(50, 33, blueL)
        if charge > 0.5 { c.px(52, 33, blueL) }
    }
    if flash > 0 {
        c.ellipse(53, 33, 5, 5, C(0x9ADCFF, 0.22 * flash))
        c.rect(51, 33, 4, 1, blueL); c.rect(52, 32, 2, 3, blueL)
    }
}

// MARK: - Orthrus

/// Orthrus's two heads share one look: fawn fur, a cream muzzle, a black nose, a long chocolate ear flopping down.
private struct OrthrusFur { var fur: Px, furD: Px, furL: Px }

/// One of Orthrus's puppy heads with its top-left at (`x`, `y`), facing right: a round fawn head lit on top, a long
/// floppy ear hanging down the back of it, a cream muzzle with a black nose, a black eye with a glint. `jaw` drops the
/// lower jaw open that many pixels (pink inside, little white teeth); `tongue` hangs the tongue out that far;
/// `sniff` lifts the nose a pixel.
private func crawlH6PuppyHead(_ c: PixelCanvas, _ x: Int, _ y: Int, _ f: OrthrusFur, jaw: Int = 0, tongue: Int = 0,
                              sniff: Bool = false) {
    let muzzle = C(0xF4E2C0), muzzleD = C(0xD4BE96), nose = C(0x1E1A1A), mouth = C(0x6A2A2E)
    let ear = C(0x6E4228), earD = C(0x4E2E1A), earL = C(0x8A5636)
    c.pattern(x, y, [
        "...FFFFFF....",
        ".FFLLLLLFF...",
        "FFLFFFFFFFF..",
        "FFFFFFFFFFFF.",
        "FFFFFFFFFMMMM",
        "FFFFFFFFMMMMM",
        ".FFFFFFFMMMM.",
    ], ["F": f.fur, "L": f.furL, "M": muzzle])
    if jaw > 0 {
        c.rect(x + 8, y + 7, 5, jaw, mouth)
        c.px(x + 9, y + 7, white); c.px(x + 11, y + 7, white)
    }
    c.pattern(x, y + 7 + jaw, ["..FFFFFFmmm..", "...dFFFFm...."], ["F": f.fur, "d": f.furD, "m": muzzleD])
    if tongue > 0 { c.rect(x + 9, y + 7 + jaw, 2, tongue, C(0xF07A90)); c.px(x + 10, y + 6 + jaw + tongue, C(0xC85068)) }
    c.rect(x + 11, y + (sniff ? 3 : 4), 2, 2, nose); c.px(x + 11, y + (sniff ? 3 : 4), C(0x5A5050))
    c.rect(x + 7, y + 3, 2, 2, ink); c.px(x + 7, y + 3, white); c.rect(x + 7, y + 2, 3, 1, f.furD)
    c.pattern(x - 1, y, [
        ".ll.",
        "EEEE",
        "EEEE",
        "EEEe",
        "EEEe",
        "EEEe",
        ".EEe",
        ".EE.",
        "..E.",
    ], ["E": ear, "e": earD, "l": earL])
}

/// Orthrus: a huge two-headed puppy, Clawd grown chubby in fawn fur, lit on top, a cream belly, big soft paws, a
/// short tail wagging; two floppy-eared puppy heads up on thick necks, the far one behind and a shade darker, each in
/// a red collar with a gold tag. He bites. Signature: the far head sniffs the air, its nose twitching, while the near
/// one licks, its pink tongue flicking out.
private func drawOrthrus(_ c: PixelCanvas, _ p: Pose) {
    let near = OrthrusFur(fur: C(0xD8B07A), furD: C(0xB08A56), furL: C(0xF0CE98))
    let far = OrthrusFur(fur: C(0xC09A66), furD: C(0x9A7646), furL: C(0xD8B482))
    let cream = C(0xF4E2C0), creamD = C(0xD4BE96)
    let collar = C(0xC8302E), collarL = C(0xE85A50), tag = C(0xF0C840)
    let s = p.signature ?? -1
    let sig = s > 0.08 && s < 0.92
    var lunge = 0, jaw = 0
    if let a = p.melee { lunge = a > -40 ? 3 : 1; jaw = a > -40 ? 3 : 1 }
    let sniff = sig && Int(p.lt * 8) % 2 == 0
    let lick = sig ? 1 + Int((abs(sin(p.lt * 9)) * 2.5).rounded()) : 0

    // 1. Thick fawn legs, big soft paws with cream toes split by little lines.
    if seatedPose {
        for lx in [19, 23, 31, 35] { c.rect(lx - 1, 38, 4, 2, near.fur); c.rect(lx - 1, 39, 4, 1, cream) }
    } else {
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let b = crawlH6Foot(i, p.step)
            c.rect(lx - 1, 36, 3, b - 35, i % 2 == 0 ? near.furD : near.fur)
            c.rect(lx - 1, b - 1, 3, 2, cream); c.px(lx, b, creamD)
        }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The tail, short and up, wagging.
    let wag = Int((sin(p.lt * 10) * 1.5).rounded())
    c.glowLine(15, 30, 10 + Double(wag), 24, core: near.fur, glow: C(0, 0), coreR: 1.0, glowR: 1.1)
    c.px(10 + wag, 23, near.furL)

    // 4. The chubby body, rounded at the back, lit on top, a cream belly.
    drawBody(c, Look(body: near.fur, shade: near.furD, arm: near.fur, eye: nil))
    c.rect(14, 28, 4, 9, near.fur); c.rect(15, 27, 3, 1, near.fur); c.rect(14, 28, 1, 8, near.furL)
    c.rect(15, 27, 23, 1, near.furL); c.rect(14, 36, 4, 1, near.furD)
    c.rect(21, 34, 15, 3, cream); c.rect(21, 36, 15, 1, creamD)
    for (x, y) in [(20, 30), (26, 29), (32, 31)] { c.rect(x, y, 2, 1, near.furD) }

    // 5. The far head, up behind on its neck in its red collar, sniffing in the signature.
    c.rect(22, 18, 9, 10, far.fur); c.rect(30, 18, 1, 10, far.furD)
    c.rect(22, 24, 9, 2, collar); c.rect(22, 24, 9, 1, collarL); c.px(28, 26, tag)
    crawlH6PuppyHead(c, 21, 10, far, sniff: sniff)
    if sniff {
        c.px(36, 12, C(0xFFFFFF, 0.7)); c.px(37, 11, C(0xFFFFFF, 0.5))
    }

    // 6. The near head, out in front on its thick neck in a red collar; it lunges and snaps when he bites, and licks
    //    in the signature.
    c.rect(31 + lunge / 2, 22, 9, 6, near.fur); c.rect(31 + lunge / 2, 22, 1, 6, near.furL)
    c.rect(31 + lunge / 2, 25, 9, 2, collar); c.rect(31 + lunge / 2, 25, 9, 1, collarL); c.px(37 + lunge / 2, 27, tag)
    crawlH6PuppyHead(c, 33 + lunge, 15, near, jaw: jaw, tongue: jaw > 0 ? 0 : lick)
    if lunge >= 3, Int(p.lt * 12) % 2 == 0 {
        c.px(48 + lunge, 18, C(0xFFFFFF, 0.8)); c.px(49 + lunge, 21, C(0xFFFFFF, 0.8)); c.px(48 + lunge, 24, C(0xFFFFFF, 0.8))
    }

    // 7. The near forepaw at his chest.
    c.rect(38, 33, 3, 3, near.fur); c.rect(38, 35, 3, 1, cream)
}

// MARK: - Garret

/// Garret: a Tummy Acher, Clawd as a round meatball on four little legs: lumpy brown meat, lit on the upper left, in
/// shade underneath, a glossy dollop of red sauce on top with a drip; Clawd's eyes, and a wide grin with his one big
/// white tooth hanging in it. He bites. Signature: he rolls back and forth on the spot, giggling, his lumps turning
/// round as he goes, his eyes screwed shut, a giggle floating up.
private func drawGarret(_ c: PixelCanvas, _ p: Pose) {
    let meat = C(0x8E4C2C), meatD = C(0x663420), meatL = C(0xB46C40), meatDD = C(0x4E2618)
    let sauce = C(0xC8382A), sauceD = C(0x962418), sauceL = C(0xF07060)
    let mouth = C(0x4A1418), tooth = C(0xF8F4E8)
    let s = p.signature ?? -1
    let rolling = s > 0.05 && s < 0.95
    let k = rolling ? (s - 0.05) / 0.9 : 0
    let roll = rolling ? sin(k * .pi * 2) * 4 : 0
    var lunge = 0, gape = 0
    if let a = p.melee { lunge = a > -40 ? 2 : 0; gape = a > -40 ? 3 : 1 }
    if rolling { gape = 2 }
    c.ox += Int(roll.rounded()) + lunge

    // 1. Four little legs in dark meat, darker toes; they patter while he rolls.
    let step = rolling ? Int(p.lt * 10) % 2 : p.step
    drawLegs(c, Look(leg: meatD), step: step)
    if !seatedPose {
        for (i, lx) in [19, 23, 31, 35].enumerated() { c.rect(lx, crawlH6Foot(i, step), 2, 1, meatDD) }
    }

    // 2. The breath.
    c.oy += p.breathe

    // 3. The meatball: round, lit on the upper left, in shade along the lower right.
    let cx = 28.5, cy = 31.5, r = 9.6
    for y in 21...41 {
        for x in 18...38 {
            let dx = Double(x) + 0.5 - cx, dy = Double(y) + 0.5 - cy
            let d = sqrt(dx * dx + dy * dy)
            guard d <= r else { continue }
            var col = meat
            if d > r - 1.6 && dx + dy > 3 { col = meatD } else if d > r - 2.2 && dx + dy < -5 { col = meatL }
            c.px(x, y, col)
        }
    }

    // 4. The lumps: little bumps round the edge, lit on top and dark under, turning as he rolls; none over his face.
    let turn = roll / r
    for i in 0..<9 {
        let a = Double(i) * 0.7 + turn - 2.6
        let rr = 6.8 + Double(i % 3) * 0.6
        let x = Int((cx + cos(a) * rr - 1).rounded()), y = Int((cy + sin(a) * rr).rounded())
        if x > 20 && x < 35 && y > 26 && y < 37 { continue }
        c.rect(x, y, 2, 1, meatL); c.rect(x, y + 1, 2, 1, meatDD)
    }

    // 5. The sauce on top, glossy, a drip running down the front.
    c.pattern(23, 20, [
        "...SSSSS...",
        ".SSLLSSSSS.",
        "SSSSSSSSSSS",
        ".DSS.SSSDS.",
        "..D...S..D.",
        "......D....",
    ], ["S": sauce, "L": sauceL, "D": sauceD])

    // 6. The face: Clawd's eyes (screwed shut in happy arcs while he giggles), and the grin with his one big tooth;
    //    it gapes wide when he bites.
    if rolling {
        for x in [21, 31] { c.pattern(x, 29, [".kk.", "k..k"], ["k": ink]) }
    } else {
        c.rect(22, 29, 2, 3, ink); c.rect(32, 29, 2, 3, ink)
    }
    c.rect(24, 33, 9, gape > 0 ? gape + 1 : 1, mouth)
    c.px(23, 32, mouth); c.px(33, 32, mouth)
    c.rect(27, 33, 2, 2, tooth); c.px(27, 33, white)

    // 7. The giggle, little letters bobbing up beside him.
    if rolling && Int(p.lt * 4) % 3 != 2 {
        let bob = Int((sin(p.lt * 9) * 1).rounded())
        crawlText(c, 38, 14 + bob, "HEHE", C(0xFFF0A0))
    }
}
