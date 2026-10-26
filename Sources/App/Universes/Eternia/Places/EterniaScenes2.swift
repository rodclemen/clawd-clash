import Foundation

// More places on Eternia: the Royal Palace's throne room, Man-At-Clawds's workshop, Snake Mountain and the Vine
// Jungle, drawn the way Castle Greyskull is. The big thing in each (the hall, the mountain, the great tree) is drawn
// once at one pixel to a unit on a canvas of its own and blown up `q` times: once in the window, three times or more
// on the screen saver, where it fills the picture. The crew stands on the ground row `g`, in front of the plainer,
// darker band just above it.

let eterniaScenes2: [Location: Place] = [
    .eterniaPalace: Place(name: "The Royal Palace of Eternos", panel: 0x141C2A, still: Scenes.eterniaPalace,
                          moving: Scenes.eterniaPalaceLife),
    .eterniaWorkshop: Place(name: "Man-At-Clawds's Workshop", panel: 0x1E1610, still: Scenes.eterniaWorkshop,
                            moving: Scenes.eterniaWorkshopLife),
    .eterniaSnakeMountain: Place(name: "Snake Mountain", panel: 0x1E0C10, still: Scenes.eterniaSnakeMountain,
                                 moving: Scenes.eterniaSnakeMountainLife),
    .eterniaVineJungle: Place(name: "The Vine Jungle", panel: 0x0E1A12, still: Scenes.eterniaVineJungle,
                              moving: Scenes.eterniaVineJungleLife),
]

// MARK: - Shared

/// Paints `src` onto `c` blown up `q` times, its top left at (x, y), only where `keep` says (all of it by default).
private func eterniaBlowUp(_ c: PixelCanvas, _ src: PixelCanvas, _ x: Int, _ y: Int, _ q: Int,
                    keep: ((Int, Int) -> Bool)? = nil) {
    for yy in 0..<src.h where y + (yy + 1) * q > 0 && y + yy * q < c.h {
        for xx in 0..<src.w where src.buf[(yy * src.w + xx) * 4 + 3] > 0 {
            if let keep, !keep(xx, yy) { continue }
            c.rect(x + xx * q, y + yy * q, q, q, unpremultiplied(src, (yy * src.w + xx) * 4))
        }
    }
}

/// A tone out of `tones` (darkest first) for a brightness `v` of 0...1, dithered by position so the tones blend.
private func eterniaDither(_ tones: [Px], _ v: Double, _ x: Int, _ y: Int, grain: Double = 0.26) -> Px {
    let n = (noise(x * 7 + y * 131) - 0.5) * grain
    let i = Int((v + n) * Double(tones.count))
    return tones[max(0, min(tones.count - 1, i))]
}

/// How many times the big things are blown up: once in the window, growing with the screen saver (as Greyskull).
private func eterniaBigScale(_ c: PixelCanvas, _ g: Int) -> Int { max(1, min(g * 62 / (100 * 56), c.w * 8 / (10 * 120))) }

/// The frame of a place drawn whole at a unit a pixel on a canvas `w` by `h` units, blown up `q` times so that its
/// bottom row sits on the ground row and its middle column on the picture's: `h` rows reach the top of the picture,
/// the place's 56 at the bottom and its ceiling (or the air) over them.
private func eterniaHall(_ c: PixelCanvas, _ g: Int) -> (q: Int, x: Int, y: Int, w: Int, h: Int) {
    let q = eterniaBigScale(c, g)
    let w = (c.w + q - 1) / q + 2, h = (g + q - 1) / q
    return (q, c.w / 2 - w / 2 * q, g - h * q, w, h)
}

/// Bays either side of the middle of a canvas `w` wide, at `first`, `first + step` ... out from the middle, each
/// with how many steps out it is.
private func eterniaBays(_ w: Int, first: Int, step: Int) -> [(x: Int, k: Int)] {
    let cx = w / 2
    var out: [(x: Int, k: Int)] = []
    var k = 0
    while first + k * step < cx + step {
        let d = first + k * step
        out.append((cx - d, k)); out.append((cx + d, k))
        k += 1
    }
    return out
}

/// String art drawn `b` pixels to a character, for the little things that fly about (bats, the Wind Raider).
private func eterniaBigPattern(_ c: PixelCanvas, _ x: Int, _ y: Int, _ b: Int, _ rows: [String], _ pal: [Character: Px]) {
    for (r, row) in rows.enumerated() {
        for (k, ch) in row.enumerated() { if let col = pal[ch] { c.rect(x + k * b, y + r * b, b, b, col) } }
    }
}

// MARK: - The Royal Palace of Eternos

/// A tall arched window of the throne room: its middle, half-width, the row its arch springs from, and its sill.
private struct PalaceWindow { let x: Int, r: Int, arch: Int, sill: Int }

/// The throne room's windows on a hall canvas `w` by `h`: the great one behind the thrones, then one in every bay.
private func palaceWindows(_ w: Int, _ h: Int) -> [PalaceWindow] {
    let top = h - 56, cx = w / 2
    var out = [PalaceWindow(x: cx, r: 15, arch: top + 21, sill: top + 36)]
    for b in eterniaBays(w, first: 45, step: 36) { out.append(PalaceWindow(x: b.x, r: 7, arch: top + 16, sill: top + 34)) }
    return out
}

/// Whether (x, y) is inside a window, or inside its surround when `grow` is more than nothing.
private func inWindow(_ win: PalaceWindow, _ x: Int, _ y: Int, grow: Int = 0) -> Bool {
    let r = win.r + grow, dx = x - win.x
    if y >= win.arch { return abs(dx) <= r && y < win.sill + grow }
    let dy = y - win.arch
    return dx * dx + dy * dy <= r * r + r
}

/// Whether (x, y) is clear glass in one of the windows: not its mullion or, in the great window, its transom.
private func palaceGlass(_ wins: [PalaceWindow], _ x: Int, _ y: Int) -> Bool {
    for win in wins where inWindow(win, x, y) {
        return x != win.x && !(win.r > 10 && y == win.arch)
    }
    return false
}

extension Scenes {
    /// The throne room of the Royal Palace of Eternos, King Randor's: a hall of blue stone under a gold frieze, tall
    /// arched windows down its length, sunny Eternos outside them (white towers with teal domes, green hills). In
    /// the middle the great window, and in front of it two gold thrones with red backs on a stepped dais, a red carpet
    /// running down it and out across the floor. Red banners with the gold sword-and-ring hang from the pilasters
    /// either side, torches burn between them, and two guards stand at the dais with their spears, dark shapes
    /// against the light. The whole hall is drawn at a unit a pixel and blown up; on the screen saver it stands
    /// three times the size or more, under a ribbed vault and a gold chandelier.
    static func eterniaPalace(_ c: PixelCanvas, _ g: Int) {
        let f = eterniaHall(c, g)
        let u = PixelCanvas(f.w, f.h)
        eterniaPalaceHall(u)
        eterniaBlowUp(c, u, f.x, f.y, f.q)
        // The floor: polished blue-grey flags, and the carpet running on from the dais towards us, gold along its edges.
        c.ground(g, C(0x2C3446), edge: C(0x46506A), speck: C(0x252C3C), seed: 7)
        let cw = 9 * f.q, x0 = c.w / 2 - 4 * f.q, edge = max(1, f.q / 2)
        c.rect(x0, g, cw, c.h - g, C(0x8A1C26)); c.rect(x0, g, cw, 1, C(0xA8303A))
        c.rect(x0, g, edge, c.h - g, C(0xC89A3A)); c.rect(x0 + cw - edge, g, edge, c.h - g, C(0xC89A3A))
    }

    /// The hall itself, one pixel to a unit, its floor along the bottom row and its middle column in the middle.
    static func eterniaPalaceHall(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let stone = [C(0x34465E), C(0x3C506A), C(0x465C78), C(0x506884)], mortar = C(0x2A3A50)
        let gold = C(0xD8AC40), goldD = C(0x9A7426), goldL = C(0xF4D878)
        let sand = [C(0x7E7666), C(0x9C927C), C(0xBCB298)]
        let red = C(0xA82430), redD = C(0x701822), redL = C(0xC83C44)

        // On the screen saver the hall rises higher: a clerestory over the frieze, round windows in it and a rose
        // window over the thrones, then the vault: an arch from pilaster to pilaster, gold-ribbed, each one a
        // lunette painted night blue with gold stars, ribs fanning up from a gold half-sun on the cornice, a boss
        // with a gem at its crown and a gold drop hanging between the arches. Over the thrones the widest arch,
        // its sun the royal sword through a ring.
        let wallTop = top >= 30 ? top - 18 : top
        if wallTop > 0 {
            u.gradient(0, wallTop, C(0x0E1422), C(0x1C2638), bands: 5)
        }
        // (Only with room for the arches: in a short window they would squash into a gold smear.)
        if wallTop >= 10 {
            let piers = eterniaBays(u.w, first: 27, step: 36).map(\.x).sorted()
            for (a, b) in zip(piers, piers.dropFirst()) {
                let m = (a + b) / 2, rx = Double(b - a) / 2 - 1, ry = min(rx, Double(wallTop - 3))
                let royal = a < cx && b > cx
                /// How far out (x, y) is in the arch: 1 on its curve, under 1 inside.
                func out(_ x: Int, _ y: Int) -> Double {
                    let ex = Double(x - m) / rx, ey = Double(wallTop - y) / ry
                    return (ex * ex + ey * ey).squareRoot()
                }
                for y in max(0, wallTop - Int(ry) - 3)..<wallTop {
                    for x in (a + 1)...(b - 1) {
                        let d = out(x, y), band = 1.6 / ry
                        if d > 1 + band { continue }
                        if d > 1 { u.px(x, y, d > 1 + band / 2 ? goldD : goldL); continue }
                        if d > 1 - band * 0.6 { u.px(x, y, gold); continue }
                        if abs(d - 0.8) < band * 0.4 { u.px(x, y, C(0x3A4C6E)); continue }
                        // The painted heavens: deep blue, lighter low down, gold stars scattered over it.
                        let k = Double(wallTop - y) / ry
                        var col = lerp(C(0x22345A), C(0x152240), k)
                        if (x * 7 + y * 13) % 29 == 0 || (x * 11 + y * 5) % 37 == 0 { col = d < 0.8 ? goldL : goldD }
                        u.px(x, y, col)
                    }
                }
                // The ribs fanning up from the half-sun to the inner moulding.
                for i in 1...5 {
                    let ang = Double(i) * .pi / 6
                    for st in 0...40 {
                        let f = 0.3 + 0.48 * Double(st) / 40
                        let x = m + Int((cos(ang) * rx * f).rounded()), y = wallTop - Int((sin(ang) * ry * f).rounded())
                        u.px(x, y, goldD)
                    }
                }
                // The half-sun on the cornice, and the boss at the crown.
                let sr = max(3, Int(ry * 0.3))
                for dy in 0...sr {
                    for dx in -sr...sr where dx * dx + dy * dy <= sr * sr {
                        u.px(m + dx, wallTop - dy, dx * dx + dy * dy > (sr - 1) * (sr - 1) ? goldD : dy > sr / 2 ? goldL : gold)
                    }
                }
                if royal {
                    // The sword through the ring, red on the gold.
                    u.rect(m, wallTop - sr + 1, 1, sr - 1, redD); u.rect(m - 1, wallTop - sr / 2 - 1, 3, 1, redD)
                    u.px(m - 2, wallTop - 2, red); u.px(m + 2, wallTop - 2, red); u.px(m - 1, wallTop - 3, red); u.px(m + 1, wallTop - 3, red)
                }
                let by = wallTop - Int(ry)
                u.circle(m, by, 2, goldD); u.circle(m, by, 1, gold); u.px(m, by, royal ? C(0xE03A3A) : C(0x4AA8E8))
            }
            // A gold drop hanging where each two arches meet.
            for x in piers {
                u.rect(x - 1, wallTop - 4, 3, 3, goldD); u.rect(x - 1, wallTop - 4, 3, 1, goldL)
                u.px(x, wallTop - 1, gold)
            }
        }

        // The wall: blue stone in courses four rows high, each block its own shade.
        for y in max(0, wallTop)..<B {
            for x in 0..<u.w {
                let course = y / 4, off = course % 2 * 4
                if y % 4 == 3 || (x + off) % 8 == 7 { u.px(x, y, mortar); continue }
                let v = 0.15 + noise((x + off) / 8 * 17 + course * 59) * 0.6
                u.px(x, y, eterniaDither(stone, v, x, y, grain: 0.15))
            }
        }
        if wallTop < top {
            // The clerestory: a gold cornice along its top, round windows of sky, the rose window in the middle.
            u.rect(0, wallTop, u.w, 1, goldL); u.rect(0, wallTop + 1, u.w, 1, goldD)
            for b in [(x: cx, k: -1)] + eterniaBays(u.w, first: 45, step: 36) {
                let r = b.k < 0 ? 8 : 5, oy = top - 9
                u.circle(b.x, oy, r + 1, sand[1]); u.circle(b.x, oy, r, gold)
                for dy in -r...r {
                    for dx in -r...r where dx * dx + dy * dy < r * r {
                        let k = Double(dy + r) / Double(2 * r)
                        u.px(b.x + dx, oy + dy, lerp(C(0x5A92CC), C(0xC8E0F0), k))
                    }
                }
                if b.k < 0 {
                    // The rose: petals of red and gold glass round a gold heart.
                    for i in 0..<8 {
                        let a = Double(i) * .pi / 4
                        let px = b.x + Int((cos(a) * 5).rounded()), py = oy + Int((sin(a) * 5).rounded())
                        u.circle(px, py, 1, i % 2 == 0 ? red : C(0x3A7AC0))
                    }
                    u.rect(b.x - r, oy, 2 * r + 1, 1, goldD); u.rect(b.x, oy - r, 1, 2 * r + 1, goldD)
                    u.circle(b.x, oy, 2, gold); u.px(b.x, oy, goldL)
                } else {
                    u.rect(b.x - r, oy, 2 * r + 1, 1, goldD); u.rect(b.x, oy - r, 1, 2 * r + 1, goldD)
                }
            }
            // A chandelier at each of the first pilasters, hung from the vault on a long chain.
            for x in [cx - 27, cx + 27] {
                let ry = top - 5
                u.rect(x, 0, 1, ry - 1, C(0x5A4A2A))
                u.circle(x, ry - 2, 8, C(0xFFC060, 0.08)); u.circle(x, ry - 2, 4, C(0xFFD070, 0.10))
                u.ellipse(x, ry, 7, 2, goldD); u.ellipse(x, ry - 1, 6, 1, gold); u.rect(x - 6, ry - 1, 13, 1, goldL)
                for k in 0..<5 {
                    let cxk = x - 6 + k * 3
                    u.rect(cxk, ry - 4, 1, 3, C(0xF0E8D0)); u.px(cxk, ry - 5, C(0xFFD050)); u.px(cxk, ry - 6, C(0xF08A28))
                }
                u.rect(x - 1, ry + 2, 3, 2, goldD); u.px(x, ry + 4, goldL)
            }
        }
        // The frieze along the top: a gold band with dentils under it.
        u.rect(0, top, u.w, 1, goldL); u.rect(0, top + 1, u.w, 1, gold); u.rect(0, top + 2, u.w, 1, goldD)
        for x in stride(from: 0, to: u.w, by: 3) { u.rect(x, top + 3, 2, 1, goldD) }
        // The panelling along the bottom, dark so the crew stands out in front of it, under a gold rail.
        u.rect(0, B - 10, u.w, 10, C(0x222E42)); u.rect(0, B - 10, u.w, 1, gold)
        for x in stride(from: cx % 12, to: u.w, by: 12) {
            u.rect(x + 1, B - 8, 10, 1, C(0x34445E)); u.rect(x + 1, B - 7, 1, 5, C(0x34445E))
            u.rect(x + 1, B - 2, 10, 1, C(0x18202E)); u.rect(x + 10, B - 7, 1, 5, C(0x18202E))
        }

        // The windows, sandstone round them, sunny Eternos through them.
        let wins = palaceWindows(u.w, u.h)
        let view = PixelCanvas(u.w, u.h)
        eterniaPalaceView(view, top: top, floor: B)
        for win in wins {
            for y in max(0, win.arch - win.r - 3)..<(win.sill + 2) {
                for x in (win.x - win.r - 2)...(win.x + win.r + 2) where inWindow(win, x, y, grow: 2) {
                    if inWindow(win, x, y) {
                        let i = (y * u.w + x) * 4
                        if x >= 0, x < u.w { u.px(x, y, unpremultiplied(view, i)) }
                    } else {
                        u.px(x, y, eterniaDither(sand, 0.62 - Double(x - win.x) / Double(win.r * 3), x, y, grain: 0.2))
                    }
                }
            }
            // The mullion (and in the great window a transom), and a sill standing out under it.
            u.rect(win.x, win.arch - win.r, 1, win.sill - win.arch + win.r, goldD)
            if win.r > 10 { u.rect(win.x - win.r, win.arch, win.r * 2 + 1, 1, goldD) }
            u.rect(win.x - win.r - 3, win.sill + 1, win.r * 2 + 7, 1, sand[2]); u.rect(win.x - win.r - 3, win.sill + 2, win.r * 2 + 7, 1, sand[0])
        }

        // The pilasters, every other one hung with a banner, the rest with a torch.
        let piers = eterniaBays(u.w, first: 27, step: 36)
        for p in piers {
            let x = p.x
            u.rect(x - 3, top + 4, 6, B - 14 - top, C(0x58708E))
            u.rect(x - 3, top + 4, 1, B - 14 - top, C(0x7088A6)); u.rect(x + 2, top + 4, 1, B - 14 - top, C(0x3A4C64))
            u.rect(x - 1, top + 6, 1, B - 18 - top, C(0x46607C)); u.rect(x + 1, top + 6, 1, B - 18 - top, C(0x46607C))
            u.rect(x - 4, top + 3, 8, 2, gold); u.rect(x - 4, top + 3, 8, 1, goldL)
            u.rect(x - 4, B - 12, 8, 2, goldD)
            if p.k % 2 == 0 { palaceBanner(u, x, top, red: red, redD: redD, redL: redL, gold: gold, goldL: goldL) }
            else { palaceSconce(u, x, top + 24) }
        }
        palaceSconce(u, cx - 21, top + 24); palaceSconce(u, cx + 21, top + 24)

        // The dais: two broad steps of grey marble, gold along their noses, the carpet running down the middle.
        for (y, hw) in [(B - 8, 21), (B - 4, 26)] {
            u.rect(cx - hw, y, hw * 2 + 1, 4, C(0x525C70)); u.rect(cx - hw, y, hw * 2 + 1, 1, C(0x6E788C))
            u.rect(cx - hw, y + 3, hw * 2 + 1, 1, C(0x3A4256)); u.rect(cx - hw, y + 1, hw * 2 + 1, 1, goldD)
        }
        u.rect(cx - 4, B - 8, 9, 8, C(0x8A1C26)); u.rect(cx - 4, B - 8, 1, 8, gold); u.rect(cx + 4, B - 8, 1, 8, gold)
        u.rect(cx - 3, B - 5, 7, 1, C(0x6A1420)); u.rect(cx - 3, B - 1, 7, 1, C(0x6A1420))

        // The thrones: the King's on the left with the taller crest, the Queen's on the right with a blue gem.
        for (x0, crest, gem) in [(cx - 13, 5, C(0xE03A3A)), (cx + 3, 4, C(0x4AA8E8))] {
            let seat = B - 14
            u.rect(x0 + 1, B - 30, 9, seat - (B - 30), gold)
            u.rect(x0 + 1, B - 30, 1, seat - (B - 30), goldL); u.rect(x0 + 9, B - 30, 1, seat - (B - 30), goldD)
            u.rect(x0 + 3, B - 28, 5, seat - (B - 28) - 1, red); u.rect(x0 + 3, B - 28, 1, seat - (B - 28) - 1, redL)
            u.rect(x0 + 7, B - 28, 1, seat - (B - 28) - 1, redD)
            for j in 1...crest {
                let w = max(1, 9 - j * 2 + (j == crest ? 0 : 0))
                u.rect(x0 + 5 - w / 2, B - 30 - j, w, 1, j % 2 == 0 ? goldL : gold)
            }
            u.px(x0 + 5, B - 30 - crest - 1, goldL); u.rect(x0 + 4, B - 32, 3, 2, gem)
            u.rect(x0, seat - 4, 2, 4, gold); u.rect(x0 + 9, seat - 4, 2, 4, goldD)
            u.rect(x0, seat - 4, 2, 1, goldL); u.rect(x0 + 9, seat - 4, 2, 1, gold)
            u.rect(x0 + 1, seat, 9, 2, C(0xB02C34)); u.rect(x0 + 1, seat, 9, 1, redL)
            u.rect(x0 + 1, seat + 2, 9, 4, goldD); u.rect(x0 + 3, seat + 3, 5, 3, C(0x6A4E1A))
            u.rect(x0 + 1, seat + 2, 9, 1, gold)
        }

        // The guards, dark against the light, the sunlit side of them towards the thrones, spears up.
        let guardRows = [
            "..T.........",
            ".TTT........",
            ".TTT........",
            "..T.........",
            "..|..PPP....",
            "..|.HHHHr...",
            "..|HHHHHHr..",
            "..|HHHHHHr..",
            "..|HKKKKHr..",
            "..|.KKKKr...",
            "..|BBBBBBr..",
            ".hhBBBBBBBr.",
            ".hhBBBBBOOO.",
            "..|BBBBOOOOo",
            "..|BBBBOOOOo",
            "..|BBBBOOOOo",
            "..|BBBBBOOo.",
            "..|BBBBBB...",
            "..|GGGGGG...",
            "..|BBBBBBr..",
            "..|BBBBBBr..",
            "..|.LL.LLr..",
            "..|.LL.LLr..",
            "..|.LL.LLr..",
            "..|.LL.LLr..",
            "..|LLL.LLLr.",
        ]
        let sil = C(0x1A2232)
        let guardPal: [Character: Px] = ["T": C(0xB8C2D0), "|": C(0x2A3448), "P": C(0x4A1C26), "H": sil, "K": C(0x10161F),
                                         "B": sil, "L": sil, "h": sil, "r": C(0x3E5272), "O": C(0x202A3C),
                                         "o": C(0x4A5E7E), "G": C(0x6A5626)]
        u.pattern(cx - 39, B - 26, guardRows, guardPal)
        u.pattern(cx + 28, B - 26, guardRows.map { String($0.reversed()) }, guardPal)
    }

    /// A red banner on a pilaster at `x`: a gold rod, gold edges, the sword through a ring, a swallowtail end.
    private static func palaceBanner(_ u: PixelCanvas, _ x: Int, _ top: Int, red: Px, redD: Px, redL: Px, gold: Px, goldL: Px) {
        u.rect(x - 6, top + 6, 13, 1, gold); u.px(x - 7, top + 6, goldL); u.px(x + 7, top + 6, goldL)
        for y in (top + 7)..<(top + 30) {
            for dx in -4...4 {
                let tail = y - (top + 25)
                if tail > 0 && abs(dx) < tail { continue }
                let col = abs(dx) == 4 ? gold : dx <= -2 ? redL : dx >= 2 ? redD : red
                u.px(x + dx, y, col)
            }
        }
        u.rect(x - 3, top + 8, 7, 1, gold)
        u.circle(x, top + 15, 3, gold); u.circle(x, top + 15, 2, red)
        u.rect(x, top + 10, 1, 11, goldL); u.rect(x - 2, top + 18, 5, 1, gold)
    }

    /// An iron sconce on the wall at (x, y) with a gold cup, its torch's light warm on the stone round it.
    private static func palaceSconce(_ u: PixelCanvas, _ x: Int, _ y: Int) {
        u.circle(x, y - 3, 7, C(0xFFB060, 0.08)); u.circle(x, y - 3, 4, C(0xFFB060, 0.10))
        u.rect(x - 1, y - 1, 3, 2, C(0x9A7426)); u.rect(x - 1, y - 1, 3, 1, C(0xD8AC40))
        u.rect(x, y + 1, 1, 2, C(0x1A1A20)); u.rect(x - 2, y + 2, 5, 1, C(0x1A1A20))
    }

    /// Eternos on a sunny day, the way the windows show it: a blue sky paling to gold low down, a few clouds, the
    /// palace's other towers (white, teal domes, gold spikes) and the green hills beyond. Painted whole; the hall
    /// keeps only what falls in its glass.
    static func eterniaPalaceView(_ v: PixelCanvas, top: Int, floor B: Int) {
        let cx = v.w / 2
        v.gradient(max(0, top), B, C(0x4A86C4), C(0xF2DCA6), bands: 6)
        for (k, dx) in [-130, -70, -30, 30, 80, 140, -190, 190].enumerated() {
            cloud(v, cx + dx, top + 8 + k % 3 * 3, 2, seed: k)
        }
        v.dunes(base: B - 24, amp: 2, freq: 0.12, phase: 1.2, bottom: B, C(0x86AC6E), shade: C(0xA0C484))
        v.dunes(base: B - 21, amp: 2, freq: 0.2, phase: 3.1, bottom: B, C(0x6A9458), shade: C(0x7EA86A))
        /// A round tower `w` wide from row `top` down, lit from the left, slit windows, a dome with a spike or
        /// a ring of merlons.
        func tower(_ x: Int, _ w: Int, _ top: Int, dome: Bool, _ wall: [Px], _ roof: [Px], slit: Px) {
            let x0 = x - w / 2
            for y in top..<(B - 20) {
                for xx in x0..<(x0 + w) { v.px(xx, y, wall[xx - x0 < w / 3 ? 2 : xx - x0 < w * 3 / 4 ? 1 : 0]) }
            }
            for y in stride(from: top + 3, to: B - 22, by: 5) { v.rect(x, y, 1, 2, slit) }
            if dome {
                let r = w / 2 + 1
                for dy in 0...r {
                    let hw = Int((Double(r * r - dy * dy)).squareRoot().rounded())
                    for xx in (x - hw)...(x + hw) { v.px(xx, top - dy, roof[xx < x - hw / 3 ? 2 : xx > x + hw / 2 ? 0 : 1]) }
                }
                v.rect(x, top - r - 3, 1, 3, C(0xE8C050))
            } else {
                for xx in stride(from: x0 - 1, to: x0 + w + 1, by: 2) { v.rect(xx, top - 2, 1, 2, wall[1]) }
                v.rect(x0 - 1, top, w + 2, 1, wall[2])
            }
        }
        // The far towers, pale in the haze, then the palace's long wall, then the near towers, white and teal.
        let haze = [C(0xA8B4C8), C(0xBCC6D6), C(0xD0D8E4)], hazeRoof = [C(0x6A98A8), C(0x7EAABA), C(0x9AC0CC)]
        for i in stride(from: -v.w / 2, to: v.w / 2, by: 9) {
            let n = noise(i + 800)
            tower(cx + i + Int(noise(i + 801) * 4), 3 + Int(n * 2), top + 16 + Int(noise(i + 802) * 10), dome: n > 0.4,
                  haze, hazeRoof, slit: C(0x8A98B0))
        }
        let cream = [C(0xB0A690), C(0xD8CEBA), C(0xF0E8D8)], teal = [C(0x1E6462), C(0x2E8C88), C(0x5AB8B0)]
        v.rect(0, top + 31, v.w, B - top - 31, cream[1]); v.rect(0, top + 31, v.w, 1, cream[2])
        for x in stride(from: 0, to: v.w, by: 3) { v.rect(x, top + 29, 2, 2, cream[1]) }
        for x in stride(from: 1, to: v.w, by: 6) { v.rect(x, top + 33, 1, 1, C(0x8A8070)) }
        for i in stride(from: -v.w / 2, to: v.w / 2, by: 17) where abs(i) > 10 {
            let n = noise(i + 500)
            tower(cx + i + Int(noise(i + 600) * 6), 4 + Int(n * 4), top + 9 + Int(noise(i + 700) * 12), dome: n > 0.3,
                  cream, teal, slit: C(0x5A6A80))
        }
        // The great tower behind the thrones, its dome gold.
        tower(cx - 9, 6, top + 8, dome: true, cream, [C(0xA07A28), C(0xD0A840), C(0xF0D070)], slit: C(0x5A6A80))
    }

    /// The throne room's life: the torches flickering, a slow ripple travelling across each banner and, on the
    /// screen saver, now and then the green-and-orange Wind Raider gliding past outside the windows.
    static func eterniaPalaceLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaHall(c, g), B = f.h, cx = f.w / 2, top = B - 56
        let u = PixelCanvas(f.w, f.h)
        let piers = eterniaBays(f.w, first: 27, step: 36)
        let torches = piers.filter { $0.k % 2 == 1 }.map(\.x) + [cx - 21, cx + 21]
        for (i, x) in torches.enumerated() {
            let ph = Int(t * 9 + Double(i) * 1.7) % 4
            let tall = [4, 5, 3, 5][ph], lean = [0, 1, 0, -1][ph], y = top + 22
            u.circle(x, y - 2, 3, C(0xFFA040, 0.10 + 0.05 * Double(ph % 2)))
            u.rect(x - 1, y, 3, 1, C(0xF07820)); u.rect(x - 1, y - 1, 3, 1, C(0xF07820)); u.px(x, y - 1, C(0xFFE070))
            u.px(x + lean / 2, y - 2, C(0xFFD040))
            if tall > 3 { u.px(x + lean, y - 3, C(0xF08A28)) }
            if tall > 4 { u.px(x + lean, y - 4, C(0xE05020, 0.8)) }
        }
        for (i, p) in piers.filter({ $0.k % 2 == 0 }).enumerated() {
            let k = sin(t * 1.4 + Double(i) * 0.9)
            let x = p.x - 2 + Int(((k + 1) * 2).rounded())
            for y in (top + 9)..<(top + 25) where (y + Int(t * 3)) % 6 != 0 {
                u.px(x, y, C(0x4A0810, 0.35)); u.px(x - 1, y, C(0xF06068, 0.22))
            }
        }
        eterniaBlowUp(c, u, f.x, f.y, f.q)

        guard isTall(c) else { return }
        // The Wind Raider: one pass across every sixteen seconds, high up, bobbing a little, seen only through glass.
        let phase = (t / 16).truncatingRemainder(dividingBy: 1)
        guard phase < 0.55 else { return }
        let sky = PixelCanvas(f.w, f.h)
        let rx = -20 + Int(phase / 0.55 * Double(f.w + 40)), ry = top + 9 + Int((sin(t * 1.3) * 1.2).rounded())
        sky.pattern(rx, ry, [
            "..F.............",
            "..FF............",
            "..FFF.GGGGgg....",
            ".GGGGGGGGGGGGWW.",
            "OOOOOOOOOOOOOOO.",
            "..ooooooooooo...",
        ], ["F": C(0xE07A20), "G": C(0x3E9A3A), "g": C(0x6CC050), "W": C(0xBFE8F0), "O": C(0xF08A28),
            "o": C(0xA85A18)])
        let wins = palaceWindows(f.w, f.h)
        eterniaBlowUp(c, sky, f.x, f.y, f.q) { x, y in palaceGlass(wins, x, y) }
    }
}

// MARK: - Man-At-Clawds's Workshop

extension Scenes {
    /// Where the workshop's turning cogs sit on its wall: middle, radius and tooth count, on a hall canvas `w` by `h`.
    static func eterniaWorkshopCogs(_ w: Int, _ h: Int) -> [(x: Int, y: Int, r: Int, teeth: Int)] {
        let cx = w / 2, top = h - 56
        return [(cx - 2, top + 15, 12, 12), (cx + 19, top + 10, 8, 8), (cx + 31, top + 18, 5, 6)]
    }

    /// Man-At-Clawds's workshop under the palace: warm brick walls, timber posts, copper pipes along the top, and
    /// in the middle the Battle Ram up on wooden blocks with its wheels off, a gunmetal hull with a bronze stripe,
    /// its silver ram's head with the curled gold horn at the front, a hatch open and wires hanging out, a fresh
    /// weld glowing on its side. Great brass cogs turn on the wall above it. Either side, workbenches with
    /// pegboards of tools over them and half-built gadgets on top (a robot head, a crackling coil, a gizmo in
    /// pieces), and tall racks of jars, boxes and spare parts between. On the screen saver the room rises to a
    /// high rack of hanging tools and a timber roof with a skylight, its light slanting down across the Ram.
    static func eterniaWorkshop(_ c: PixelCanvas, _ g: Int) {
        let f = eterniaHall(c, g)
        let u = PixelCanvas(f.w, f.h)
        eterniaWorkshopHall(u)
        eterniaBlowUp(c, u, f.x, f.y, f.q)
        // The floor: dark stone, oil-stained, a lighter worn lip.
        c.ground(g, C(0x2E2824), edge: C(0x4A3E34), speck: C(0x24201C), seed: 9)
        for k in 0..<(c.w / 60 + 1) {
            let x = k * 60 + Int(noise(k + 70) * 30)
            c.ellipse(x, g + (c.h - g) / 2, 4 * f.q, max(1, f.q), C(0x1A1614, 0.7))
        }
    }

    /// The workshop itself, one pixel to a unit, its floor along the bottom row.
    static func eterniaWorkshopHall(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let wallTop = top >= 38 ? top - 16 : 0
        let brick = [C(0x4A2C22), C(0x56362A), C(0x623F31), C(0x6E4A3A)], mortar = C(0x34201A)
        let wood = C(0x5A3E24), woodL = C(0x7A5632), woodD = C(0x3A2816)

        // The roof, on the screen saver: timber trusses in the dark and a skylight letting the day in.
        if wallTop > 0 {
            u.gradient(0, wallTop, C(0x140E0A), C(0x2A1E16), bands: 4)
            let sx0 = cx - 24, sy0 = 3, sy1 = wallTop - 3
            u.rect(sx0 - 2, sy0 - 2, 53, sy1 - sy0 + 4, woodD)
            u.gradient(sy0, sy1, C(0x6AB0E0), C(0xB8E0F0), bands: 4)
            u.rect(0, 0, sx0 - 2, sy1 + 2, C(0x1E1610)); u.rect(sx0 + 51, 0, u.w, sy1 + 2, C(0x1E1610))
            u.gradient(0, sy0 - 2, C(0x140E0A), C(0x1E1610), bands: 2)
            cloud(u, cx - 8, sy0 + 5, 2, seed: 3)
            for x in stride(from: sx0, through: sx0 + 48, by: 8) { u.rect(x, sy0, 1, sy1 - sy0, woodD) }
            for y in stride(from: sy0 + 6, to: sy1, by: 6) { u.rect(sx0, y, 49, 1, woodD) }
            for x in stride(from: cx % 18, to: u.w, by: 18) {
                u.rect(x, 0, 2, wallTop, wood); u.rect(x, 0, 1, wallTop, woodL)
            }
            u.rect(0, wallTop - 3, u.w, 3, wood); u.rect(0, wallTop - 3, u.w, 1, woodL); u.rect(0, wallTop - 1, u.w, 1, woodD)
        }
        // The brick wall, warm in the lamplight.
        for y in wallTop..<(B - 10) {
            for x in 0..<u.w {
                let course = y / 3, off = course % 2 * 3
                if y % 3 == 2 || (x + off) % 6 == 5 { u.px(x, y, mortar); continue }
                let v = 0.2 + noise((x + off) / 6 * 23 + course * 41) * 0.65
                u.px(x, y, eterniaDither(brick, v, x, y, grain: 0.12))
            }
        }
        // Planking along the bottom, dark behind the crew.
        for x in 0..<u.w { u.rect(x, B - 10, 1, 10, x % 6 == 0 ? C(0x2A1E14) : x / 6 % 2 == 0 ? C(0x3A2A1E) : C(0x40301F)) }
        u.rect(0, B - 10, u.w, 1, C(0x5A4430))
        // The high rack of hanging tools, on the screen saver.
        if wallTop > 0 {
            let ry = top - 12
            u.rect(0, ry, u.w, 2, wood); u.rect(0, ry, u.w, 1, woodL)
            for x in stride(from: cx % 10, to: u.w, by: 10) {
                let kind = Int(noise(x + 900) * 5)
                u.px(x, ry + 2, C(0x9A9AA0))
                switch kind {
                case 0:   // a saw
                    u.rect(x - 1, ry + 3, 3, 2, C(0x8A5A30)); u.rect(x - 2, ry + 5, 4, 7, C(0xB8BCC4)); u.rect(x + 1, ry + 5, 1, 7, C(0x8A8E98))
                case 1:   // a coil of rope
                    u.circle(x, ry + 6, 3, C(0xB89A5A)); u.circle(x, ry + 6, 1, C(0x6A5430))
                case 2:   // a chain with a hook
                    for k in 0..<5 { u.px(x, ry + 3 + k * 2, C(0x6A6E78)); u.px(x, ry + 4 + k * 2, C(0x9A9EA8)) }
                    u.rect(x, ry + 13, 2, 1, C(0x9A9EA8)); u.px(x + 1, ry + 12, C(0x9A9EA8))
                case 3:   // a spare wheel
                    u.circle(x, ry + 7, 4, C(0x26262A)); u.circle(x, ry + 7, 2, C(0x8A8E98)); u.px(x, ry + 7, C(0xC0C4CC))
                default:  // a hammer and tongs
                    u.rect(x - 1, ry + 3, 1, 8, C(0x8A5A30)); u.rect(x - 2, ry + 3, 3, 2, C(0x8A8E98))
                    u.rect(x + 2, ry + 3, 1, 7, C(0x6A6E78)); u.rect(x + 3, ry + 3, 1, 7, C(0x6A6E78))
                }
            }
        }
        // Copper pipes along the top of the wall, valves and a gauge on them.
        u.rect(0, top + 1, u.w, 2, C(0xB06A34)); u.rect(0, top + 1, u.w, 1, C(0xD88A4C))
        u.rect(0, top + 4, u.w, 1, C(0x8A5028))
        for x in stride(from: cx % 24, to: u.w, by: 24) {
            u.rect(x, top, 2, 4, C(0x8A5028)); u.rect(x - 1, top - 1, 4, 1, C(0xC03A2A))
        }
        u.rect(cx - 40, top + 3, 2, 4, C(0x8A5028))
        u.circle(cx - 39, top + 9, 4, C(0xB08838)); u.circle(cx - 39, top + 9, 3, C(0xE8E0C8))
        u.px(cx - 39, top + 9, C(0x1A1A1E)); u.px(cx - 38, top + 8, C(0x1A1A1E)); u.px(cx - 37, top + 7, C(0xC02020))
        u.px(cx - 41, top + 10, C(0x8A8A90)); u.px(cx - 39, top + 7, C(0x8A8A90)); u.px(cx - 37, top + 10, C(0xC02020))

        // The posts and the bays between them, no two neighbours alike: a bench, a rack of parts, the forge, a
        // drafting board, a hoist over crates and barrels, in a different order either side and each bench with a
        // gadget of its own.
        for p in eterniaBays(u.w, first: 52, step: 36) {
            u.rect(p.x - 2, wallTop, 4, B - wallTop, wood)
            u.rect(p.x - 2, wallTop, 1, B - wallTop, woodL); u.rect(p.x + 1, wallTop, 1, B - wallTop, woodD)
            for y in [top + 8, B - 14] { u.rect(p.x - 2, y, 4, 2, C(0x4A4A52)); u.px(p.x, y, C(0x9A9AA4)) }
        }
        for (i, b) in eterniaBays(u.w, first: 70, step: 36).enumerated() {
            let side = i % 2
            switch (b.k + side * 2) % 5 {
            case 0: workBench(u, b.x, B, variant: (b.k / 5 + side) % 3)
            case 1: workRack(u, b.x, B, seed: i)
            case 2: workForge(u, b.x, B, top: wallTop)
            case 3: workBoard(u, b.x, B, seed: i)
            default: workHoist(u, b.x, B, top: top)
            }
        }

        // The cogs' housings: dark round recesses in the wall, the cogs themselves turn in the moving layer.
        for cg in eterniaWorkshopCogs(u.w, u.h) {
            u.circle(cg.x, cg.y, cg.r + 1, C(0x22140E)); u.circle(cg.x, cg.y, cg.r - 3, C(0x1A0E0A))
        }

        // The Battle Ram, up on blocks.
        let crate = C(0x9A6A38), crateD = C(0x6A4824), crateL = C(0xBA8A50)
        for bx in [cx - 27, cx - 4, cx + 15] {
            for k in 0..<2 {
                let y = B - 5 - k * 5
                u.rect(bx, y, 9, 5, crate); u.rect(bx, y, 9, 1, crateL); u.rect(bx, y + 4, 9, 1, crateD)
                u.rect(bx, y, 1, 5, crateD); u.rect(bx + 8, y, 1, 5, crateD)
                for d in 1..<4 { u.px(bx + d * 2, y + d, crateD) }
            }
        }
        // The hull: a long gunmetal wedge, a flat deck, the nose sloping down to the ram, a bronze stripe down its
        // length, and the empty wheel arches showing where its wheels came off.
        let hull = [C(0x2A323E), C(0x3A4454), C(0x4C5A6E), C(0x627288), C(0x7A8AA0)]
        let arches = [cx - 22, cx + 9]
        for x in (cx - 34)...(cx + 27) {
            let topY: Int
            if x < cx - 30 { topY = B - 20 + (cx - 30 - x) }
            else if x <= cx + 12 { topY = B - 24 }
            else { topY = B - 24 + (x - (cx + 12)) * 9 / 15 }
            for y in topY..<(B - 10) {
                if arches.contains(where: { a in let dx = x - a, dy = y - (B - 10); return dx * dx + dy * dy < 36 }) { continue }
                let v = 0.8 - Double(y - topY) / 14 * 0.6
                u.px(x, y, eterniaDither(hull, v, x, y, grain: 0.12))
            }
            u.px(x, topY, hull[4])
        }
        for a in arches {
            for dx in -6...6 {
                let dy = Int((Double(36 - dx * dx)).squareRoot().rounded())
                u.px(a + dx, B - 10 - dy, hull[0])
            }
            u.rect(a - 1, B - 13, 3, 3, C(0x8A8E98)); u.px(a, B - 12, C(0x3A3A44))
        }
        u.rect(cx - 34, B - 19, 61, 1, C(0xD09848)); u.rect(cx - 34, B - 18, 61, 1, C(0x8A5E28))
        for x in stride(from: cx - 31, to: cx + 24, by: 5) { u.px(x, B - 21, hull[0]); u.px(x, B - 16, hull[4]) }
        // The open hatch in the deck, wires spilling out and down the side.
        u.rect(cx - 8, B - 24, 12, 4, C(0x12161C)); u.rect(cx - 8, B - 25, 12, 1, hull[1])
        u.rect(cx - 10, B - 29, 2, 5, hull[3]); u.rect(cx - 10, B - 29, 14, 1, hull[3])
        for (dx, col, len) in [(-7, C(0xD03030), 9), (-5, C(0xE8C040), 12), (-2, C(0x3A7AD0), 8), (1, C(0x40A040), 10)] {
            for k in 0..<len { u.px(cx + dx + (k > 5 ? 1 : 0), B - 21 + k, col) }
        }
        // The driver's seat at the back, high and red, a windscreen and the steering bar in front of it.
        u.rect(cx - 31, B - 36, 10, 12, C(0x50606E)); u.rect(cx - 30, B - 35, 8, 10, C(0xA83028))
        u.rect(cx - 30, B - 35, 2, 10, C(0xC84838)); u.rect(cx - 30, B - 35, 8, 1, C(0xD05A48))
        for k in 0..<6 { u.rect(cx - 19 + k / 2, B - 30 + k, 2, 1, C(0x8ACCE0)) }
        u.rect(cx - 15, B - 28, 1, 4, C(0x2A2A30)); u.rect(cx - 17, B - 29, 5, 1, C(0x2A2A30))
        // The fresh weld on its side, glowing orange, a scorch round it.
        u.ellipse(cx + 6, B - 14, 4, 2, C(0x1A1A1E, 0.6)); u.rect(cx + 3, B - 14, 6, 1, C(0xF08A30)); u.px(cx + 5, B - 14, C(0xFFD070))
        // The ram's head on the nose: a silver skull in profile, a long snout, a red eye, teeth along the jaw, and
        // a heavy gold horn curling back and round from its brow.
        u.pattern(cx + 25, B - 24, [
            "...SSSSSS........",
            ".SSLLLLLLSS......",
            "SSLLLLLLLLLSS....",
            "SLLLLLLLLLLLLSS..",
            "SLLLLLLLLLKKLLLLS",
            "SSLLLLLLLKKRKLLLS",
            "SSSLLLLLLLKKLLLLS",
            ".SSSLLLLLLLLLLLLN",
            "..sSSSLLLLLLLLLSN",
            "...ssSSSSSSSSSSs.",
            "....ssTsTsTsTss..",
            ".....ssssssss....",
        ], ["S": C(0xA4A8B4), "L": C(0xD4D8E0), "s": C(0x6E727E), "K": C(0x1A1A22), "R": C(0xF03030), "N": C(0x2A2A32),
            "T": C(0xE8E4D4)])
        // The horn: a ridged coil, dark-edged so its turns stand apart.
        for pass in 0..<2 {
            for st in 0...48 {
                let k = Double(st) / 48, a = -Double.pi / 2 - k * 2.3 * Double.pi
                let r = 5.6 - 3.8 * k, th = k < 0.6 ? 1 : 0
                let hx = Int((Double(cx + 28) + cos(a) * r).rounded()), hy = Int((Double(B - 19) + sin(a) * r).rounded())
                if pass == 0 { u.circle(hx, hy, th + 1, C(0x5A4018)); continue }
                u.circle(hx, hy, th, st % 6 < 2 ? C(0xF0D080) : st % 6 < 4 ? C(0xD0A850) : C(0xA88030))
            }
        }
        // A wheel off it, leaning on the blocks, another lying flat; a red toolbox by the nose.
        u.circle(cx - 39, B - 9, 8, C(0x26262A)); u.circle(cx - 39, B - 9, 5, C(0x8A8E98)); u.circle(cx - 39, B - 9, 2, C(0xC0C4CC))
        for k in 0..<10 {
            let a = Double(k) * .pi / 5
            u.px(cx - 39 + Int((cos(a) * 7.4).rounded()), B - 9 + Int((sin(a) * 7.4).rounded()), C(0x3E3E44))
        }
        u.rect(cx + 40, B - 6, 8, 5, C(0xA82A22)); u.rect(cx + 40, B - 6, 8, 1, C(0xD04A3A)); u.rect(cx + 43, B - 7, 2, 1, C(0x3A3A44))

        // The skylight's light, slanting down across the room.
        if wallTop > 0 {
            for y in (wallTop - 3)..<B {
                let dy = y - (wallTop - 3)
                u.rect(cx - 22 + dy / 3, y, 44, 1, C(0xFFE8A0, 0.05))
            }
        }
    }

    /// A workbench in the bay at `bx`: a pegboard of tools over it, a vice, a half-built gadget on top (a robot head,
    /// a crackling coil, a gizmo in pieces), and boxes on the shelf under it.
    private static func workBench(_ u: PixelCanvas, _ bx: Int, _ B: Int, variant: Int) {
        u.rect(bx - 12, B - 37, 25, 21, C(0x5A4028)); u.rect(bx - 11, B - 36, 23, 19, C(0x7A5A38))
        for y in stride(from: B - 35, to: B - 17, by: 2) { for x in stride(from: bx - 10, to: bx + 12, by: 2) { u.px(x, y, C(0x5A4028)) } }
        let steel = C(0xA8ACB4), steelD = C(0x6A6E78), handle = C(0x8A3A22)
        // A wrench, a hammer, a saw, a screwdriver and pliers, hung in a row.
        u.rect(bx - 9, B - 33, 1, 10, steel); u.rect(bx - 10, B - 34, 3, 2, steel); u.px(bx - 9, B - 34, C(0x7A5A38))
        u.rect(bx - 5, B - 31, 1, 10, handle); u.rect(bx - 7, B - 33, 5, 2, steelD)
        u.rect(bx - 1, B - 34, 2, 3, handle); u.rect(bx - 2, B - 31, 4, 9, steel); u.rect(bx + 1, B - 31, 1, 9, steelD)
        u.rect(bx + 5, B - 34, 1, 4, C(0xE8C040)); u.rect(bx + 5, B - 30, 1, 6, steel)
        u.rect(bx + 8, B - 34, 1, 7, handle); u.rect(bx + 10, B - 34, 1, 7, handle); u.rect(bx + 8, B - 27, 3, 3, steelD)
        // The bench.
        u.rect(bx - 14, B - 13, 29, 2, C(0x8A5A30)); u.rect(bx - 14, B - 13, 29, 1, C(0xA8723E))
        u.rect(bx - 14, B - 11, 29, 1, C(0x5A3A1E))
        u.rect(bx - 13, B - 10, 2, 10, C(0x4A3018)); u.rect(bx + 11, B - 10, 2, 10, C(0x4A3018))
        u.rect(bx - 13, B - 4, 26, 1, C(0x4A3018))
        u.rect(bx - 10, B - 8, 6, 4, C(0x6A4A2A)); u.rect(bx - 10, B - 8, 6, 1, C(0x7A5A36))
        u.rect(bx + 2, B - 7, 3, 3, C(0x7A2A20)); u.rect(bx + 6, B - 6, 3, 2, C(0x4A5A2A))
        u.rect(bx + 10, B - 16, 4, 3, steelD); u.rect(bx + 10, B - 16, 4, 1, steel); u.rect(bx + 13, B - 15, 2, 1, steel)
        switch variant {
        case 0:   // a robot's head, its dome off to one side, one red eye, wires out of the neck
            u.ellipse(bx - 3, B - 17, 5, 3, C(0x7A828E)); u.ellipse(bx - 4, B - 18, 3, 2, C(0xA8B0BC))
            u.rect(bx - 8, B - 17, 11, 3, C(0x7A828E)); u.rect(bx - 6, B - 17, 7, 2, C(0x2A2E36)); u.rect(bx - 5, B - 17, 2, 1, C(0xE03030))
            u.rect(bx - 3, B - 23, 1, 3, C(0x5A6270)); u.px(bx - 3, B - 24, C(0xE8C040))
            u.ellipse(bx + 5, B - 15, 3, 1, C(0x8A929E)); u.px(bx + 2, B - 14, C(0xD03030)); u.px(bx + 3, B - 14, C(0x3A7AD0))
        case 1:   // a coil on a stand, copper turns and a glass ball on top
            u.rect(bx - 5, B - 15, 8, 2, C(0x3A3A40)); u.rect(bx - 2, B - 23, 2, 8, C(0x6A4A2A))
            for y in stride(from: B - 23, to: B - 15, by: 2) { u.rect(bx - 3, y, 4, 1, C(0xD08A40)) }
            u.circle(bx - 1, B - 26, 2, C(0x9AC8F0)); u.px(bx - 2, B - 27, C(0xE8F4FF))
            u.rect(bx + 4, B - 16, 5, 3, C(0x4A4A52)); u.px(bx + 5, B - 15, C(0x40E060)); u.px(bx + 7, B - 15, C(0xE0C040))
        default:  // a gizmo in pieces: an open box of gears, a lens, a spring
            u.rect(bx - 8, B - 18, 9, 5, C(0x5A6270)); u.rect(bx - 7, B - 17, 7, 3, C(0x2A2E36))
            u.circle(bx - 5, B - 16, 1, C(0xC8A050)); u.circle(bx - 2, B - 16, 1, C(0xA8ACB4))
            u.circle(bx + 4, B - 15, 2, C(0x5AA0C8)); u.px(bx + 3, B - 16, C(0xD0F0FF))
            for k in 0..<4 { u.px(bx + 8 + k % 2, B - 14 - k, C(0xA8ACB4)) }
        }
    }

    /// A tall rack in the bay at `bx`: shelves of jars, boxes, coils and spare gears.
    private static func workRack(_ u: PixelCanvas, _ bx: Int, _ B: Int, seed: Int) {
        let wood = C(0x5A3E24), woodL = C(0x8A6438)
        u.rect(bx - 12, B - 47, 2, 47, wood); u.rect(bx + 11, B - 47, 2, 47, wood)
        let glass = [C(0x4AA05A), C(0xD8A040), C(0x4A7AC0), C(0xB04A8A)]
        for (si, y) in [B - 47, B - 36, B - 25, B - 14].enumerated() {
            u.rect(bx - 12, y, 25, 2, woodL); u.rect(bx - 12, y + 1, 25, 1, wood)
            guard si > 0 else { continue }
            var x = bx - 9
            var k = 0
            while x < bx + 9 {
                let kind = Int(noise(seed * 40 + si * 9 + k + 300) * 4)
                switch kind {
                case 0:   // a jar of something
                    let col = glass[(seed + si + k) % glass.count]
                    u.rect(x, y - 6, 3, 6, col); u.px(x, y - 5, C(0xE8F0E8, 0.7)); u.rect(x, y - 7, 3, 1, C(0x8A8E98)); x += 4
                case 1:   // a box
                    u.rect(x, y - 5, 5, 5, C(0x8A6A44)); u.rect(x, y - 5, 5, 1, C(0xA88458)); u.px(x + 2, y - 3, C(0x5A4028)); x += 6
                case 2:   // a coil of wire
                    u.circle(x + 2, y - 3, 2, C(0xC07838)); u.px(x + 2, y - 3, C(0x5A3A1E)); x += 5
                default:  // a spare gear on its edge
                    u.circle(x + 2, y - 3, 3, C(0x8A8E98)); u.circle(x + 2, y - 3, 1, C(0x3A3A44)); x += 6
                }
                k += 1
            }
        }
        u.rect(bx - 9, B - 6, 7, 6, C(0x3A2A1C)); u.rect(bx + 1, B - 5, 8, 5, C(0x4A3622))
        u.rect(bx - 9, B - 6, 7, 1, C(0x4A3826)); u.rect(bx + 1, B - 5, 8, 1, C(0x5A4430))
    }

    /// The forge in the bay at `bx`: a stone hearth with the fire glowing orange in its arched mouth, a copper hood
    /// over it and its flue climbing to the roof (from row `top`), leather bellows on the left, tongs and a
    /// hammer hung on the hood, and an anvil standing out in front on the right.
    private static func workForge(_ u: PixelCanvas, _ bx: Int, _ B: Int, top: Int) {
        let copper = C(0xA0602E), copperL = C(0xD08A4C), copperD = C(0x6A3A1A)
        u.circle(bx, B - 10, 15, C(0xFF8030, 0.07)); u.circle(bx, B - 10, 9, C(0xFF9040, 0.08))
        // The flue and the hood, widening down to the hearth.
        u.rect(bx - 3, top, 6, B - 30 - top, copperD); u.rect(bx - 2, top, 4, B - 30 - top, copper)
        u.rect(bx - 2, top, 1, B - 30 - top, copperL)
        for y in stride(from: top + 3, to: B - 31, by: 7) { u.rect(bx - 3, y, 6, 1, copperD) }
        for y in (B - 30)..<(B - 17) {
            let hw = 3 + (y - (B - 30)) * 9 / 13
            u.rect(bx - hw, y, hw * 2 + 1, 1, copper); u.px(bx - hw, y, copperL); u.px(bx - hw + 1, y, copperL)
            u.px(bx + hw, y, copperD)
        }
        u.rect(bx - 13, B - 17, 27, 1, copperD)
        for x in [bx - 6, bx, bx + 6] { u.px(x, B - 19, copperL); u.px(x, B - 18, copperD) }
        // The hearth of stone blocks, the fire in its mouth, coals glowing.
        let stone = [C(0x3E3632), C(0x4E4440), C(0x5E5450)]
        for y in (B - 16)..<B {
            for x in (bx - 12)...(bx + 12) {
                let course = (y - B + 16) / 3, off = course % 2 * 2
                let seam = (y - B + 16) % 3 == 2 || (x + off) % 5 == 4
                u.px(x, y, seam ? C(0x2A2420) : stone[Int(noise(x / 5 * 7 + course * 31 + 5) * 3)])
            }
        }
        u.rect(bx - 13, B - 16, 27, 2, C(0x6E645A)); u.rect(bx - 13, B - 16, 27, 1, C(0x8A8076))
        for y in (B - 13)..<(B - 3) {
            for x in (bx - 6)...(bx + 6) {
                let dx = Double(x - bx) / 6.5, dy = Double(y - (B - 9)) / 4.5
                guard dx * dx + dy * dy <= 1 || (y >= B - 9 && abs(x - bx) <= 6) else { continue }
                let heat = Double(y - (B - 13)) / 10
                u.px(x, y, lerp(C(0x2A0C06), C(0xE0581A), heat * (1 - abs(dx) * 0.5)))
            }
        }
        for (x, y) in [(bx - 3, B - 5), (bx, B - 6), (bx + 3, B - 5), (bx - 1, B - 4), (bx + 2, B - 4)] {
            u.px(x, y, C(0xFFD050))
        }
        u.rect(bx - 6, B - 3, 13, 1, C(0x1A0C08))
        // The bellows, leather between two boards, the nozzle into the hearth.
        u.rect(bx - 17, B - 9, 5, 1, C(0x5A3A1E))
        for k in 0..<5 { u.rect(bx - 17 + k / 2, B - 8 + k, 6 - k, 1, k % 2 == 0 ? C(0x7A4A28) : C(0x5A3418)) }
        u.rect(bx - 17, B - 3, 6, 1, C(0x5A3A1E)); u.rect(bx - 12, B - 6, 2, 1, C(0x6A6E78))
        // Tongs and a hammer hung on the hood's side.
        u.rect(bx + 9, B - 28, 1, 8, C(0x3A3A40)); u.rect(bx + 11, B - 28, 1, 8, C(0x3A3A40)); u.px(bx + 10, B - 29, C(0x5A5A62))
        u.rect(bx - 10, B - 27, 1, 7, C(0x8A5A30)); u.rect(bx - 12, B - 28, 5, 2, C(0x6A6E78))
        // The anvil: a black iron block on a stump, its horn to the right.
        u.rect(bx + 9, B - 4, 5, 4, C(0x5A3E24)); u.rect(bx + 9, B - 4, 5, 1, C(0x7A5A36))
        u.rect(bx + 10, B - 6, 3, 2, C(0x2A2A30))
        u.rect(bx + 7, B - 8, 8, 2, C(0x3A3A42)); u.rect(bx + 7, B - 8, 8, 1, C(0x7A7E88))
        u.rect(bx + 15, B - 8, 2, 1, C(0x3A3A42)); u.px(bx + 17, B - 8, C(0x5A5E68))
    }

    /// A drafting board in the bay at `bx`, tilted on its easel: a blueprint pinned to it (the Wind Raider in
    /// white lines on blue), a lamp on a jointed arm shining down on it, a stool, and a bin of rolled-up plans.
    private static func workBoard(_ u: PixelCanvas, _ bx: Int, _ B: Int, seed: Int) {
        let wood = C(0x6A4A2A), woodL = C(0x8A6438), woodD = C(0x4A3018)
        let blue = C(0x24508A), blueL = C(0x3462A0), ink = C(0xD8E8F8)
        // The easel legs, then the board on them.
        for k in 0..<18 { u.px(bx - 7 + k / 6, B - 17 + k, woodD); u.px(bx + 7 - k / 6, B - 17 + k, woodD) }
        u.rect(bx - 8, B - 9, 17, 1, woodD)
        u.rect(bx - 12, B - 36, 25, 20, wood); u.rect(bx - 12, B - 36, 25, 1, woodL); u.rect(bx - 12, B - 17, 25, 1, woodD)
        u.rect(bx - 11, B - 35, 23, 17, blue)
        for y in stride(from: B - 34, to: B - 18, by: 3) { u.rect(bx - 11, y, 23, 1, blueL) }
        for x in stride(from: bx - 9, to: bx + 12, by: 3) { u.rect(x, B - 35, 1, 17, blueL) }
        // The Wind Raider in side view: a long hull, the tail fin up, a wing, the canopy, and a dimension line.
        u.rect(bx - 8, B - 25, 17, 1, ink); u.rect(bx - 6, B - 24, 13, 1, ink)
        for k in 0..<4 { u.px(bx - 8 + k, B - 26 - k, ink) }
        u.rect(bx - 2, B - 28, 6, 1, ink); u.px(bx - 3, B - 27, ink); u.px(bx + 4, B - 27, ink); u.px(bx + 5, B - 26, ink)
        u.rect(bx + 9, B - 26, 1, 2, ink); u.rect(bx - 4, B - 23, 6, 1, C(0xA8C8E8))
        u.rect(bx - 8, B - 21, 18, 1, C(0x9AB8D8)); u.px(bx - 8, B - 22, C(0x9AB8D8)); u.px(bx + 9, B - 22, C(0x9AB8D8))
        u.rect(bx - 10, B - 33, 4, 2, C(0xE8E0C8)); u.rect(bx + 7, B - 33, 4, 2, C(0xE8E0C8))
        for (x, y) in [(bx - 11, B - 35), (bx + 11, B - 35)] { u.px(x, y, C(0xD03030)) }
        // The lamp, on an arm out of the board's top, its light falling across the plan.
        u.rect(bx + 11, B - 40, 1, 5, C(0x3A3A40)); u.rect(bx + 4, B - 41, 8, 1, C(0x3A3A40))
        u.rect(bx + 1, B - 42, 5, 2, C(0x2E7A4A)); u.rect(bx + 2, B - 40, 3, 1, C(0xFFE890))
        for k in 0..<6 { u.rect(bx + 1 - k / 2, B - 39 + k, 5 + k, 1, C(0xFFE890, 0.10)) }
        // The stool, and a bin of rolled-up plans.
        u.rect(bx + 4, B - 8, 8, 2, woodL); u.rect(bx + 5, B - 6, 1, 6, woodD); u.rect(bx + 10, B - 6, 1, 6, woodD)
        u.rect(bx - 15, B - 7, 6, 7, C(0x5A5048)); u.rect(bx - 15, B - 7, 6, 1, C(0x7A6E62))
        for (k, dx) in [-14, -12, -10].enumerated() {
            let h = 4 + (seed + k) % 3 * 2
            u.rect(bx + dx, B - 7 - h, 2, h, k % 2 == 0 ? C(0xE8E0C8) : C(0x9AB8D8)); u.px(bx + dx, B - 7 - h, C(0xB8AC90))
        }
    }

    /// A hoist in the bay at `bx`: a chain from a block high on the wall (below row `top`'s pipes) holding a spare
    /// engine in the air, crates stacked under it on the left, banded barrels on the right.
    private static func workHoist(_ u: PixelCanvas, _ bx: Int, _ B: Int, top: Int) {
        // The beam out from the wall, the pulley block, the chain.
        u.rect(bx - 6, top + 7, 13, 2, C(0x5A3E24)); u.rect(bx - 6, top + 7, 13, 1, C(0x7A5632))
        u.rect(bx - 1, top + 9, 3, 3, C(0x4A4A52)); u.px(bx, top + 10, C(0x9A9AA4))
        for y in (top + 12)..<(B - 33) { u.px(bx, y, y % 2 == 0 ? C(0x9A9EA8) : C(0x5A5E68)) }
        u.rect(bx - 1, B - 33, 3, 1, C(0x9A9EA8)); u.px(bx - 1, B - 32, C(0x9A9EA8)); u.px(bx + 1, B - 32, C(0x9A9EA8))
        // The engine: a gunmetal block with cooling fins, a red cap and pipes curling off it.
        let eng = [C(0x2A323E), C(0x3E4858), C(0x58667A), C(0x7A8AA0)]
        u.rect(bx - 6, B - 31, 13, 10, eng[1]); u.rect(bx - 6, B - 31, 13, 1, eng[3]); u.rect(bx - 6, B - 22, 13, 1, eng[0])
        u.rect(bx - 6, B - 31, 1, 10, eng[2]); u.rect(bx + 6, B - 31, 1, 10, eng[0])
        for y in stride(from: B - 29, to: B - 22, by: 2) { u.rect(bx - 4, y, 9, 1, eng[0]) }
        u.rect(bx - 2, B - 33, 5, 2, C(0xB02C24)); u.rect(bx - 2, B - 33, 5, 1, C(0xD84A3A))
        for k in 0..<5 { u.px(bx + 7 + k / 2, B - 28 + k, C(0xB06A34)) }
        u.rect(bx - 9, B - 26, 3, 1, C(0xB06A34)); u.rect(bx - 9, B - 26, 1, 4, C(0xB06A34))
        // Crates, two stacked and one beside, stencilled.
        let crate = C(0x8A6438), crateD = C(0x5A3E20), crateL = C(0xA8804C)
        for (x, y, w, h) in [(bx - 15, B - 8, 9, 8), (bx - 14, B - 16, 8, 8), (bx - 5, B - 6, 6, 6)] {
            u.rect(x, y, w, h, crate); u.rect(x, y, w, 1, crateL); u.rect(x, y + h - 1, w, 1, crateD)
            u.rect(x, y, 1, h, crateD); u.rect(x + w - 1, y, 1, h, crateD)
            u.rect(x + w / 2 - 1, y + h / 2 - 1, 2, 2, C(0x3A2814))
        }
        // Barrels, banded in iron.
        for (x, h) in [(bx + 3, 9), (bx + 9, 11)] {
            u.rect(x, B - h, 6, h, C(0x6A4424)); u.rect(x + 1, B - h, 4, h, C(0x845630)); u.rect(x + 1, B - h, 1, h, C(0x9A6A3C))
            u.ellipse(x + 2, B - h, 2, 1, C(0x4A3018))
            for y in [B - h + 2, B - 3] { u.rect(x, y, 6, 1, C(0x3A3A42)) }
        }
    }

    /// A cog at (cx, cy), radius `r`, turned to `angle`: teeth round the rim, four spokes, lit from the top left.
    private static func workCog(_ u: PixelCanvas, _ cx: Int, _ cy: Int, _ r: Int, teeth: Int, angle: Double, _ tones: [Px]) {
        let rd = Double(r)
        for dy in -r...r {
            for dx in -r...r {
                let d = (Double(dx * dx + dy * dy)).squareRoot()
                if d > rd + 0.3 { continue }
                let a = atan2(Double(dy), Double(dx)) - angle
                if d > rd - 2 && cos(a * Double(teeth)) < -0.1 { continue }
                let lit = 0.62 - (Double(dx) + Double(dy)) / (4 * rd)
                var col = tones[max(1, min(3, Int(lit * 4)))]
                if d < 1.6 { col = C(0x140C08) }
                else if d < 3 { col = tones[3] }
                else if d > rd - 3.4 && d < rd - 2.4 { col = tones[0] }
                else if r >= 7 && d > rd * 0.42 && d < rd * 0.42 + 1 { col = tones[1] }
                if r >= 7 {
                    // Four bolt heads round the hub, turning with it.
                    let br = rd * 0.62, step = Double.pi / 2, ba = (a / step).rounded() * step
                    if d * d + br * br - 2 * d * br * cos(a - ba) < 1.3 { col = tones[3] }
                }
                u.px(cx + dx, cy + dy, col)
            }
        }
    }

    /// The workshop's life: the cogs on the wall turning, the big one driving the others, and bursts of welding at
    /// the Ram's seam, a blue-white spark spitting showers of orange that fall to the floor.
    static func eterniaWorkshopLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaHall(c, g), B = f.h, cx = f.w / 2
        let u = PixelCanvas(f.w, f.h)
        let brass = [C(0x5A3E18), C(0x8A6428), C(0xB08838), C(0xD8B050)], steel = [C(0x3A3E48), C(0x5E6470), C(0x868C98), C(0xB0B6C0)]
        let cogs = eterniaWorkshopCogs(f.w, f.h)
        let a0 = t * 0.35, a1 = -a0 * 12 / 8, a2 = -a1 * 8 / 6
        workCog(u, cogs[0].x, cogs[0].y, cogs[0].r, teeth: cogs[0].teeth, angle: a0, brass)
        workCog(u, cogs[1].x, cogs[1].y, cogs[1].r, teeth: cogs[1].teeth, angle: a1, steel)
        workCog(u, cogs[2].x, cogs[2].y, cogs[2].r, teeth: cogs[2].teeth, angle: a2, brass)
        // Welding: on for two seconds in every three and a half.
        let w = t.truncatingRemainder(dividingBy: 3.5)
        if w < 2.0 {
            let wx = cx + 6, wy = B - 16
            u.circle(wx, wy, 2, C(0x9AD0FF, 0.35))
            u.px(wx, wy, Int(t * 20) % 2 == 0 ? C(0xFFFFFF) : C(0xC8E8FF))
            for k in 0..<10 {
                let life = 0.7, tau = (t + Double(k) * 0.07).truncatingRemainder(dividingBy: life)
                let vx = (noise(k * 5 + Int(t / life) * 3) - 0.5) * 14, vy = -noise(k * 5 + 1) * 8
                let x = Double(wx) + vx * tau, y = Double(wy) + vy * tau + 22 * tau * tau
                guard y < Double(B) else { continue }
                u.px(Int(x.rounded()), Int(y.rounded()), tau < 0.3 ? C(0xFFE070) : C(0xF08A30, 1 - tau / life))
            }
        }
        eterniaBlowUp(c, u, f.x, f.y, f.q)
    }
}

// MARK: - Snake Mountain

extension Scenes {
    /// Where things stand at Snake Mountain, shared by the still picture and the moving layer: the mountain is drawn
    /// at one pixel to a unit on a canvas of its own (`eterniaSnakeMountainPeak`, 120×56) and blown up `q` times,
    /// left of the middle where Greyskull stands right of it. `foot` is the row it stands on, `x`/`y` its canvas's
    /// top left.
    static func eterniaSnakeFrame(_ c: PixelCanvas, _ g: Int) -> (q: Int, foot: Int, x: Int, y: Int) {
        let q = eterniaBigScale(c, g)
        let foot = g - (isTall(c) ? 10 : 6) * q
        return (q, foot, c.w * 44 / 100 - 60 * q, foot - 55 * q)
    }

    /// Snake Mountain, Skeleclawd's lair and the evil mirror of Greyskull: a blood-red sky going black overhead, a
    /// swollen red moon low on the right (where Greyskull's sun sets on the left), soot clouds lit red from under,
    /// black crags. The mountain is a crooked peak of dark basalt lit red down its right side, a giant stone snake
    /// in poison green coiled three times round it, yellow belly under each coil. Its head is down at the foot,
    /// facing us: a ridged crest of spines, bone horns swept back from a heavy brow knotted over slit eyes, and
    /// jaws gaping on two long fangs. The maw is the door, a violet glow deep inside,
    /// a causeway of black flagstones running out over the lower jaw, slits of yellow light dotted up the rock.
    /// On the screen saver the mountain stands three times the size and the sky goes up into the dark.
    static func eterniaSnakeMountain(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaSnakeFrame(c, g), q = f.q, tall = isTall(c)
        let base = f.foot + q
        c.gradient(0, base, C(0x12040A), C(0xC8361C), bands: tall ? 12 : 8)
        if tall { c.stars(0, base / 4, density: 110, seed: 23) }
        // The blood moon, in rings of red glow.
        let moon = (x: c.w * (tall ? 84 : 76) / 100, y: tall ? base * 42 / 100 : base - 26 * s, r: (tall ? 17 : 9) * s)
        for (k, a) in [(2.6, 0.08), (1.9, 0.12), (1.4, 0.18)] { c.circle(moon.x, moon.y, Int(Double(moon.r) * k), C(0xFF6040, a)) }
        c.circle(moon.x, moon.y, moon.r, C(0xE8805A)); c.circle(moon.x + moon.r / 4, moon.y - moon.r / 5, moon.r * 3 / 4, C(0xF29A70))
        c.circle(moon.x - moon.r / 3, moon.y + moon.r / 3, moon.r / 4, C(0xC86448)); c.circle(moon.x + moon.r / 3, moon.y, moon.r / 5, C(0xD06E50))
        // Soot clouds in long streaks, lit red underneath.
        let banks: [(x: Int, y: Int, len: Int)] = tall
            ? [(6, 26, 34), (60, 18, 30), (24, 44, 40), (78, 52, 28), (4, 64, 30), (52, 70, 34)]
            : [(4, 24, 18), (64, 12, 16), (88, 40, 12), (30, 8, 12)]
        for (k, b) in banks.enumerated() {
            let x = c.w * b.x / 100, y = base * b.y / 100, len = b.len * s * (tall ? 2 : 1), th = s * (tall ? 2 : 1)
            for p in 0..<4 {
                let px = x + len * p / 4 + Int(noise(k * 7 + p) * Double(len / 6)), pw = len / 3 + Int(noise(k * 7 + p + 40) * Double(len / 5))
                c.rect(px, y - th * (1 + p % 2), pw, th * (1 + p % 2), C(0x3A0E18))
            }
            c.rect(x, y, len, th, C(0x5A1620)); c.rect(x + len / 8, y + th, len * 3 / 4, th, C(0xE0503A))
            c.rect(x + len / 3, y + 2 * th, len / 4, th, C(0xF07048, 0.6))
        }
        // The far crags: jagged black ranges, the nearer darker.
        if tall { snakeCrags(c, base: base - 46 * s, amp: 22 * s, period: 26 * s, seed: 3, bottom: base, C(0x4A1420), edge: C(0x7A2A2A)) }
        snakeCrags(c, base: base - (tall ? 20 : 8) * s, amp: (tall ? 14 : 7) * s, period: (tall ? 18 : 12) * s, seed: 9,
                   bottom: base, C(0x2E0C14), edge: C(0x6A2024))
        // The plain at the mountain's foot: dark ash, cracks glowing a little.
        c.rect(0, base, c.w, g - base, C(0x22141A)); c.rect(0, base, c.w, max(1, s), C(0x3A2026))
        for k in 0..<(c.w / (40 * s) + 1) {
            let x = k * 40 * s + Int(noise(k + 90) * Double(20 * s)), y = base + Int(noise(k + 91) * Double(max(1, (g - base) / 2)))
            c.rect(x, y, (4 + Int(noise(k + 92) * 6)) * s, max(1, s / 2 + (q > 2 ? 1 : 0)), C(0xE04A20, 0.55))
        }

        // The mountain, blown up to size.
        let m = PixelCanvas(120, 56)
        eterniaSnakeMountainPeak(m)
        eterniaBlowUp(c, m, f.x, f.y, q)

        // The causeway out of the door: black flagstones widening as they come, fang-stones either side.
        let dx0 = f.x + 52 * q, dw = 17 * q, top = base, bottom = g - s
        for y in top..<max(top + 1, bottom) {
            let k = Double(y - top) / Double(max(1, bottom - top))
            let w = Int(Double(dw) * (1 + 0.8 * k)), x = dx0 + dw / 2 - w / 2
            c.rect(x, y, w, 1, (y - top) / max(1, q * 2) % 2 == 0 ? C(0x2E2228) : C(0x241A20))
            c.px(x, y, C(0x4A3236)); c.px(x + w - 1, y, C(0x4A3236))
        }
        // The near ledge: dark red-brown rock, plain where the crew stands.
        c.ground(g, C(0x3A2A2C), edge: C(0x5A403E), speck: C(0x2C2022), seed: 29)
    }

    /// Jagged ranges along the horizon: peaks at every `period` pixels at heights of their own, filled to `bottom`.
    private static func snakeCrags(_ c: PixelCanvas, base: Int, amp: Int, period: Int, seed: Int, bottom: Int, _ col: Px, edge: Px) {
        let p = max(1, period)
        for x in 0..<c.w {
            let k = x / p, f = Double(x % p) / Double(p)
            let h0 = noise(k * 31 + seed), h1 = noise((k + 1) * 31 + seed)
            let v = h0 * (1 - f) + h1 * f - 0.45 * sin(f * .pi)
            let top = base - Int(v * Double(amp))
            if top < bottom { c.rect(x, top, 1, bottom - top, col); c.px(x, top, edge) }
        }
    }

    /// The snake's head, reared up at the mountain's foot facing us, its open maw the door: a heavy brow knotted
    /// down to the middle over two slit eyes, nostrils, the upper jaw's red gum with two long fangs hanging from
    /// it, the black maw with a violet glow deep inside, and the lower jaw laid open along the ground, teeth up,
    /// for the causeway to run out over. Drawn as its left half and mirrored. `E` marks the eyes and `P` their
    /// pupils, which burn in the moving layer.
    static let eterniaSnakeHead: [String] = [
        "........DDSSSSS",
        "......DSSSSLSSS",
        "....DSSSSSSLSSS",
        "..DDSSSSSSSSLSS",
        ".DSHHHSSSSSSLSS",
        "DSBBBBHHHSSSSSS",
        "DSSBBBBBBBHHSSS",
        "DSSSEEBBBBBBBHS",
        "DSSSSEEEPEBBBBB",
        ".DSSSSSSEEEBBSS",
        ".DSSSSSSSSSSSSS",
        "..DSSSSSSSSSSSS",
        "..DSSSSSSSSNNSS",
        "..DjGGGGGGGGGGG",
        "..DjFFFMMMMMMMM",
        "..DjFFFMMMMMMMM",
        "..DjjFFMMMMMMMM",
        "..DjjFFMMMMMMMV",
        ".DSjjFfMMMMMMVV",
        ".DSjjMFMMMMMVVV",
        ".DSjjMFMMMMVVVV",
        "DSSjjMfMMMVVVVV",
        "DSSjjMMMMVVVVVV",
        "DSjGtGGtGGtGGtG",
        "DjJJJJJJJJJJJJJ",
        "DjjjjjjjjjjjjjJ",
    ].map { $0 + String($0.dropLast().reversed()) }
    /// Where the head sits on the mountain's canvas: its jaw on the foot row, its middle on the peak's.
    static let eterniaSnakeHeadAt = (x: 46, y: 30)

    /// Snake Mountain itself, one pixel to a unit on a 120×56 canvas, its foot on row 55: a tall crooked peak of
    /// basalt with a spire either side (the tall one on the right, where Greyskull's tall tower is on the left),
    /// the snake's body coiled three times down round the rock, and at the foot its head, crested and horned, its
    /// open maw the door.
    static func eterniaSnakeMountainPeak(_ c: PixelCanvas) {
        let rock = [C(0x120A0E), C(0x1E1218), C(0x2A1A22), C(0x3A262E), C(0x4C323A), C(0x62424A)]
        let rim = C(0xF05A3A), rimD = C(0xA03A30)
        let scale = [C(0x16260F), C(0x203A16), C(0x2C521E), C(0x3C6C28), C(0x508834), C(0x6AA444)]
        let belly = C(0xC8B45A), bellyD = C(0x8E7E3A), deep = C(0x080306)
        func bump(_ y: Int, _ at: Int, _ r: Int) -> Double { max(0, 1 - Double(abs(y - at)) / Double(r)) }
        /// How far the rock reaches out from the middle on `side` (-1 left, 1 right) at row `y`.
        func edge(_ y: Int, _ side: Int) -> Double {
            if y < 10 { return -1 }
            let foot = y > 42 ? pow(Double(y - 42), 2) / 9 : 0
            let hw = 2 + Double(y - 10) * 0.6 + foot
            let crag = (noise(y / 2 * 13 + side * 77 + 5) - 0.5) * 3
            let jut = side < 0 ? 4 * bump(y, 30, 4) : 4 * bump(y, 38, 4)
            return hw + crag + jut
        }
        /// A crooked spire of rock standing from the foot to `top`, `w` wide at its base, leaning `lean` at its tip.
        func spire(_ x0: Int, _ w: Int, _ top: Int, lean: Int) {
            for y in top..<56 {
                let k = Double(y - top) / Double(56 - top)
                let hw = Double(w) / 2 * pow(k, 0.6) + 0.6
                let mid = Double(x0) + Double(lean) * pow(1 - k, 2) + (noise(y / 2 + x0) - 0.5) * 1.5
                let l = Int((mid - hw).rounded()), r = Int((mid + hw).rounded())
                for x in l...r { c.px(x, y, eterniaDither(rock, 0.3 + 0.4 * (Double(x) - mid) / max(1, hw), x, y, grain: 0.3)) }
                c.px(r, y, rim); c.px(l, y, rock[0])
            }
        }
        spire(24, 12, 26, lean: -3)
        spire(97, 14, 9, lean: 4)
        spire(86, 8, 22, lean: 2)
        // The rock, lit red from the right where the moon is, gullies running down it.
        for y in 10..<56 {
            let l = 60 - edge(y, -1), r = 60 + edge(y, 1), hw = max(4, (r - l) / 2)
            for x in Int(l.rounded())...Int(r.rounded()) {
                let k = (Double(x) - 60) / hw
                c.px(x, y, eterniaDither(rock, 0.32 + 0.34 * k, x, y, grain: 0.3))
            }
            c.px(Int(r.rounded()), y, rim); c.px(Int(r.rounded()) - 1, y, rimD)
            c.px(Int(l.rounded()), y, rock[0])
        }
        for x0 in [40, 48, 54, 67, 74, 82] {
            for y in 14..<56 {
                let x = x0 + (y - 30) * (x0 - 60) / 50 + Int(noise(y / 2 + x0) * 2)
                guard Double(abs(x - 60)) < edge(y, x < 60 ? -1 : 1) - 1 else { continue }
                c.px(x, y, rock[0]); c.px(x + 1, y, rock[4])
            }
        }
        // Slits of yellow light, high windows in the rock and the spires.
        for (x, y) in [(41, 49), (80, 50), (40, 45), (81, 45), (86, 45), (34, 52), (97, 30), (24, 44), (99, 40)] {
            c.rect(x - 1, y - 1, 3, 4, rock[0]); c.rect(x, y, 1, 2, C(0xF0B040))
        }

        // The coils, lowest first: each the front of one turn round the peak, rising to the right like a barber's
        // pole, dipping in the middle, lit along its back and dark along its underside, turning away round the rock
        // at its ends, its yellow belly showing along the bottom.
        func coil(_ yc: Int, _ e: Double, _ th: Int) {
            let r = Int(edge(yc, 1)) + 3
            for dx in -r...r {
                let k = Double(dx) / Double(r)
                let yb = Int((Double(yc) + e * (1 - k * k) - 0.2 * Double(dx)).rounded())
                let turn = pow(abs(k), 3) * 0.6
                // The ends round off as the body turns away behind the rock.
                let tk = max(2, Int((Double(th) * (1 - pow(abs(k), 6) * 0.55)).rounded()))
                c.rect(60 + dx, yb + tk - tk / 2, 1, 1, rock[0])
                for j in 0..<tk {
                    let y = yb - tk / 2 + j, x = 60 + dx
                    let across = Double(j) / Double(max(1, tk - 1))
                    let round = 1 - pow(across * 2 - 0.7, 2)
                    let mark = abs((dx - j + 300) % 7 - 3) + abs(j - tk / 2) <= 1 && j < tk - 1
                    let col: Px
                    if j == tk - 1 { col = turn > 0.25 ? bellyD : belly }
                    else if j == tk - 2 { col = turn > 0.25 ? scale[0] : scale[1] }
                    else if mark { col = scale[1] }
                    else { col = eterniaDither(scale, 0.25 + 0.6 * round - turn + k * 0.08, x, y, grain: 0.16) }
                    c.px(x, y, col)
                }
                if dx > -r / 2 && dx < r - 2 { c.px(60 + dx, yb - tk / 2, C(0x8AB050)) }
            }
        }
        coil(41, 2, 7)
        coil(25, 1.5, 6)
        coil(15, 1, 5)

        // A ridged crest of spines along the crown of the head, tallest in the middle, and two horns of bone
        // swept back from the ends of the brow.
        for (o, h) in [(-9, 3), (-6, 5), (-3, 6), (0, 7), (3, 6), (6, 5), (9, 3)] {
            let x = 60 + o, base = abs(o) > 7 ? 31 : 30
            for j in 0..<h {
                let w = j < h / 2 ? 3 : 1, y = base - 1 - j
                c.rect(x - w / 2, y, w, 1, j < h / 2 ? C(0x0C1408) : scale[0])
            }
            c.px(x, base - 1 - h, C(0x8A2A24))
        }
        let bone = C(0xC8BCA0), boneD = C(0x7E7262)
        for (k, (x, y)) in [(46, 35), (45, 34), (44, 33), (43, 32), (42, 31), (41, 30), (40, 28), (39, 27)].enumerated() {
            let w = k < 6 ? 2 : 1
            for hx in [x, 120 - x - w] {
                c.rect(hx, y - 1, w, 1, C(0x0A1206)); c.rect(hx, y, w, 1, bone); c.rect(hx, y + 1, w, 1, k < 5 ? boneD : C(0x0A1206))
            }
        }

        // The head, then its shading: the face lighter on top and to the right where the moon catches it and
        // mottled, the glow deep in the maw brightest low in the middle, the belly scales of the lower jaw.
        let at = eterniaSnakeHeadAt, head = eterniaSnakeHead
        c.pattern(at.x, at.y, head,
                  ["S": scale[3], "L": scale[5], "H": scale[4], "B": C(0x0C1408), "D": C(0x0A1206), "E": C(0xC08A20),
                   "P": C(0x2A1A08), "N": deep, "j": scale[1], "G": C(0x6A0E18), "F": C(0xEEE6CC), "f": C(0x9E9480),
                   "t": C(0xEEE6CC), "J": bellyD, "M": deep, "V": deep])
        for (r, row) in head.enumerated() {
            for (k, ch) in row.enumerated() {
                let x = at.x + k, y = at.y + r
                switch ch {
                case "S":
                    c.px(x, y, eterniaDither(scale, 0.66 - Double(r) * 0.018 + Double(k - 14) / 28 * 0.25, x, y, grain: 0.3))
                case "V":
                    let d = (pow(Double(k - 14) / 9, 2) + pow(Double(r - 25) / 8, 2)).squareRoot()
                    c.px(x, y, lerp(C(0x7A3AA8), deep, min(1, d)))
                case "J":
                    c.px(x, y, k % 3 == 0 ? bellyD : belly)
                default: break
                }
            }
            // The moonlit side: a red rim down the head's right edge.
            if let k = row.lastIndex(where: { $0 != "." }).map({ row.distance(from: row.startIndex, to: $0) }) {
                c.px(at.x + k, at.y + r, rimD)
            }
        }
    }

    /// Snake Mountain's life: the snake's slit eyes burning yellow for a few seconds, going dull, burning again,
    /// and bats flitting round the summit.
    static func eterniaSnakeMountainLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaSnakeFrame(c, g), q = f.q
        if t.truncatingRemainder(dividingBy: 4.2) < 3.0 {
            let at = eterniaSnakeHeadAt, head = eterniaSnakeHead, mid = head[0].count / 2
            // A glow round each eye, then the slits burning yellow, the pupils upright in them.
            for side in [-1, 1] {
                var sx = 0.0, sy = 0.0, n = 0.0
                for (r, row) in head.enumerated() {
                    for (k, ch) in row.enumerated() where ch == "E" && (k - mid) * side > 0 {
                        sx += Double(k) + 0.5; sy += Double(r) + 0.5; n += 1
                    }
                }
                guard n > 0 else { continue }
                let px = f.x + Int((Double(at.x) + sx / n) * Double(q)), py = f.y + Int((Double(at.y) + sy / n) * Double(q))
                c.circle(px, py, 5 * q, C(0xF0A020, 0.10)); c.circle(px, py, 3 * q, C(0xF8F060, 0.20))
            }
            for (r, row) in head.enumerated() {
                for (k, ch) in row.enumerated() where ch == "E" || ch == "P" {
                    c.rect(f.x + (at.x + k) * q, f.y + (at.y + r) * q, q, q, ch == "E" ? C(0xF8F060) : C(0x2A1A08))
                }
            }
        }
        let b = max(1, (q + 1) / 2), bat = C(0x1A0A0E)
        let up = ["B.....B", "BB.B.BB", ".BBBBB.", "...B..."], down = ["...B...", ".BBBBB.", "BB.B.BB", "B.....B"]
        for k in 0..<6 {
            let a = t * (0.5 + Double(k % 3) * 0.12) + Double(k) * 1.05
            let rx = Double((34 + k * 5) * q), ry = Double((8 + k % 3 * 4) * q)
            let x = f.x + 60 * q + Int(cos(a) * rx), y = f.y + 8 * q + Int(sin(a * 1.3) * ry)
            eterniaBigPattern(c, x - 3 * b, y - 2 * b, b, Int(t * 6 + Double(k)) % 2 == 0 ? up : down, ["B": bat])
        }
    }
}

// MARK: - The Vine Jungle

extension Scenes {
    /// Where the vines hang from in the Vine Jungle, on its canvas `w` by `h` (the great tree's limbs, and the
    /// canopy out of sight above at the sides): the top of each vine, its length, and its phase.
    static func eterniaJungleVines(_ w: Int, _ h: Int) -> [(x: Int, y: Int, len: Int, ph: Double)] {
        let cx = w / 2, top = h - 56
        var out: [(x: Int, y: Int, len: Int, ph: Double)] = [
            (cx - 45, top + 19, 18, 0.0), (cx - 34, top + 20, 14, 1.3), (cx - 21, top + 22, 16, 2.1),
            (cx + 19, top + 22, 15, 0.7), (cx + 32, top + 20, 18, 1.9), (cx + 46, top + 19, 15, 2.8),
        ]
        for b in eterniaBays(w, first: 62, step: 23) {
            out.append((b.x, 0, top + 18 + Int(noise(b.x + 40) * 16), noise(b.x + 41) * 6))
        }
        return out
    }

    /// The Vine Jungle: deep green air, misty low down, sun slanting through in shafts; rows of trunks fading into
    /// the mist behind, and in front one great old tree, its trunk furrowed and mossy, a liana wound round it, its
    /// buttress roots spread wide with dark hollows between, two huge limbs reaching out under heavy clumps of
    /// leaves. Giant ferns either side, pink flowers, mossy rocks, vines hanging everywhere. On the screen saver the
    /// tree stands three times the size and the canopy closes over far above, a few chinks of sky in it.
    static func eterniaVineJungle(_ c: PixelCanvas, _ g: Int) {
        let s = unit(g), f = eterniaHall(c, g), tall = isTall(c)
        let treeTop = f.y + (f.h - 56) * f.q
        c.gradient(0, g, C(0x0C221C), C(0x3A6A4A), bands: tall ? 10 : 6)
        // The canopy overhead (on the screen saver), or just its lowest leaves along the top (in the window).
        let cb = tall ? treeTop * 70 / 100 : 5 * s
        if tall {
            c.rect(0, 0, c.w, cb, C(0x0E2A1A))
            for k in 0..<(c.w / (30 * s) + 2) {
                let x = k * 30 * s + Int(noise(k + 300) * Double(20 * s)), y = Int(noise(k + 301) * Double(cb * 2 / 3))
                c.ellipse(x, y, (4 + Int(noise(k + 302) * 5)) * s, (2 + Int(noise(k + 303) * 3)) * s, C(0xB8DCA8))
            }
        }
        let clumps = c.w * max(cb, 4 * s) / (60 * s * s) + 8
        for k in 0..<clumps {
            let x = Int(noise(k * 3 + 400) * Double(c.w)), y = Int(noise(k * 3 + 401) * Double(cb + 2 * s))
            let r = (6 + Int(noise(k * 3 + 402) * 10)) * s * (tall ? 1 : 1) / (tall ? 1 : 2) + s
            let col = [C(0x143820), C(0x1E4A26), C(0x2A5E2C)][k % 3]
            c.ellipse(x, y, r, r * 2 / 3, col)
            c.ellipse(x - r / 3, y - r / 4, r / 2, r / 3, C(0x3E7A34))
        }
        // Sun shafts slanting down through the gaps.
        for k in 0..<6 {
            let x0 = c.w * (4 + k * 17) / 100, wd = (6 + k % 3 * 4) * s
            for y in cb..<g { c.rect(x0 + (y - cb) / 2, y, wd, 1, C(0xE8F4A8, 0.05)) }
        }
        // The trunks behind, two rows of them: pale and thin far back in the mist, darker and stouter nearer.
        for layer in 0..<2 {
            let step = (layer == 0 ? 26 : 44) * s, tw = (layer == 0 ? 3 : 7) * s
            let col = layer == 0 ? C(0x2E5446) : C(0x1E3C30), lit = layer == 0 ? C(0x3E6656) : C(0x2A4C3C)
            for k in 0..<(c.w / step + 2) {
                let x = k * step + Int(noise(k * 5 + layer * 77) * Double(step / 2)) - step / 2
                let w = tw + Int(noise(k * 5 + layer * 77 + 1) * Double(tw))
                c.rect(x, cb / 2, w, g - cb / 2, col); c.rect(x, cb / 2, max(1, s), g - cb / 2, lit)
                c.rect(x - w / 2, g - 2 * s, w * 2, 2 * s, col)
            }
        }
        // Low mist over the jungle floor.
        c.rect(0, g - 14 * s, c.w, 6 * s, C(0x6AA078, 0.10)); c.rect(0, g - 8 * s, c.w, 8 * s, C(0x6AA078, 0.14))
        if tall {
            // Lianas dropping from the canopy far above, still in the windless heights.
            for k in 0..<(c.w / (34 * s) + 1) {
                let x = k * 34 * s + Int(noise(k + 500) * Double(20 * s)), len = cb / 3 + Int(noise(k + 501) * Double(treeTop / 2))
                c.rect(x, cb - 4 * s, max(1, s), len, C(0x2A4A22))
                for y in stride(from: cb, to: cb - 4 * s + len, by: 5 * s) { c.rect(x + (y / (5 * s) % 2 == 0 ? s : -s), y, s, s, C(0x3E6A2C)) }
            }
        }
        // The great tree and the jungle round it, blown up to size.
        let u = PixelCanvas(f.w, f.h)
        eterniaJungleTree(u)
        eterniaBlowUp(c, u, f.x, f.y, f.q)
        // The jungle floor: dark moss and leaf litter.
        c.ground(g, C(0x22301C), edge: C(0x3A5228), speck: C(0x1A2616), seed: 33)
    }

    /// The great tree, the ferns, the rocks and the flowers round it, one pixel to a unit with the ground along the
    /// bottom row and the tree's 56 rows at the bottom of the canvas.
    static func eterniaJungleTree(_ u: PixelCanvas) {
        let B = u.h, cx = u.w / 2, top = B - 56
        let bark = [C(0x1C140E), C(0x2A1E14), C(0x3A2A1C), C(0x4C3824), C(0x604830), C(0x78603E)]
        let moss = [C(0x2A4A1E), C(0x3E6A28), C(0x5A8E36)]
        let flower = C(0xD04A9A), flowerL = C(0xF07AC0)

        // Giant ferns either side of the tree, fanning up out of the ground.
        for b in eterniaBays(u.w, first: 48, step: 29) {
            let size = 16 + noise(b.x + 7) * 10
            jungleFern(u, b.x, B, size, seed: b.x)
        }
        // Mossy rocks between them.
        for b in eterniaBays(u.w, first: 62, step: 29) {
            let r = 3 + Int(noise(b.x + 9) * 3)
            u.ellipse(b.x, B - 2, r + 2, r, C(0x34383A)); u.ellipse(b.x - 1, B - 3, r, r - 1, C(0x4A5048))
            u.ellipse(b.x - 1, B - r - 1, r, 1, moss[1])
        }

        // The trunk: furrowed bark lit from the upper left, flaring into six buttress roots with dark hollows between.
        func hw(_ y: Int) -> Double { 8 + pow(max(0, Double(y - top - 34)), 2) / 13 }
        for y in (top + 14)..<B {
            let h = hw(y), depth = Double(y - top - 42) / 13
            for x in Int((Double(cx) - h).rounded())...Int((Double(cx) + h).rounded()) {
                let k = Double(x - cx) / h
                let root = (k + 1) * 3, frac = root - root.rounded(.down)
                if depth > 0 && abs(frac - 0.5) < 0.42 * depth && abs(k) > 0.1 { u.px(x, y, C(0x0A140C)); continue }
                let ridge = depth > 0 ? (0.5 - abs(frac - 0.5)) * 0.5 : 0
                let fine = (k + 1) * 9, ff = fine - fine.rounded(.down)
                var col = eterniaDither(bark, 0.6 - 0.42 * k - ridge, x, y, grain: 0.14)
                if ff < 0.12 { col = bark[1] }
                if noise(x / 2 * 13 + y / 2 * 7 + 3) > 0.78 && k < 0.1 && (y - top) % 11 < 5 { col = moss[(x + y) % 2 + (k < -0.4 ? 1 : 0)] }
                u.px(x, y, col)
            }
            u.px(Int((Double(cx) - h).rounded()), y, bark[5])
        }
        // The hollow at its foot, dark, its rim mossy.
        for y in (B - 12)..<B {
            for x in (cx - 5)...(cx + 5) {
                let dx = Double(x - cx) / 5.5, dy = Double(y - (B - 6)) / 6
                if dx * dx + dy * dy <= 1 || (y >= B - 6 && abs(x - cx) <= 5) { u.px(x, y, C(0x060C08)) }
            }
        }
        u.rect(cx - 4, B - 12, 9, 1, moss[1]); u.rect(cx - 6, B - 10, 1, 3, moss[0])
        // The strangler liana winding round the trunk.
        for y in (top + 16)..<(B - 12) {
            let a = Double(y) * 0.2, h = hw(y)
            guard cos(a) > 0 else { continue }
            let x = cx + Int((sin(a) * h).rounded())
            u.rect(x, y, 2, 1, moss[1]); u.px(x, y, moss[2])
        }
        // The two great limbs, thick at the trunk, arching up and out under the leaves, a lesser bough off each.
        func limb(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, arch: Double, r0: Double, r1: Double) {
            for st in 0...70 {
                let k = Double(st) / 70
                let x = x0 + (x1 - x0) * k, y = y0 + (y1 - y0) * k - arch * sin(k * .pi)
                let r = Int((r0 + (r1 - r0) * k).rounded())
                u.circle(Int(x), Int(y), r, bark[2]); u.circle(Int(x), Int(y) - max(1, r / 2), max(1, r - 1), bark[4])
                if r > 1 { u.rect(Int(x) - 1, Int(y) - r + 1, 2, 1, bark[5]) }
                u.px(Int(x), Int(y) - r, bark[5])
                if st % 14 == 7 { u.px(Int(x) + 1, Int(y) - r, moss[2]) }
            }
        }
        for side in [-1.0, 1.0] {
            let c0 = Double(cx)
            let y0 = Double(top + (side < 0 ? 29 : 26))
            limb(c0 + side * 4, y0, c0 + side * 47, Double(top + 17), arch: 5, r0: 3, r1: 2)
            limb(c0 + side * 26, y0 - 6, c0 + side * 32, Double(top + 12), arch: 1, r0: 2, r1: 1)
        }
        // Lianas looping between the limbs and the trunk, flowers on them.
        for (x0, y0, x1, y1, sag) in [(cx - 40, top + 19, cx - 10, top + 25, 8), (cx + 10, top + 25, cx + 40, top + 19, 7)] {
            for st in 0...40 {
                let k = Double(st) / 40
                let x = Double(x0) + Double(x1 - x0) * k, y = Double(y0) + Double(y1 - y0) * k + Double(sag) * sin(k * .pi)
                u.px(Int(x), Int(y), C(0x3A4A22))
                if st == 20 { u.rect(Int(x) - 1, Int(y) + 1, 3, 2, flower); u.px(Int(x), Int(y) + 1, flowerL) }
            }
        }
        // Heavy clumps of leaves on the limbs and over the crown, each a heap of rounded masses, lit from the top
        // left with a shadowed underside.
        // The tones sit just over the canopy's own, so the crown is one with the jungle rather than a lit lawn on it.
        let leaf = [C(0x081A0E), C(0x0E2814), C(0x153620), C(0x1E4626), C(0x2A582C), C(0x3A6C32)]
        let clumps: [(dx: Int, dy: Int, r: Int)] = [(-49, 15, 6), (-38, 11, 7), (-27, 9, 6), (-15, 6, 8), (0, 5, 9),
                                                   (15, 6, 8), (27, 9, 6), (38, 11, 7), (49, 15, 6)]
        for (i, cl) in clumps.enumerated() {
            for j in 0..<3 {
                let jx = cx + cl.dx + (j - 1) * cl.r * 2 / 3, jy = top + cl.dy + (j == 1 ? -cl.r / 3 : 1)
                let rr = Double(cl.r - (j == 1 ? 0 : 2))
                let ir = Int(rr) + 1
                for y in max(0, jy - ir)...(jy + ir) {
                    for x in (jx - ir - 1)...(jx + ir + 1) {
                        let ex = Double(x - jx) / (rr * 1.2), ey = Double(y - jy) / rr
                        let d = ex * ex + ey * ey + (noise(x / 2 * 17 + y / 2 * 5 + i) - 0.5) * 0.45
                        guard d <= 1 else { continue }
                        let v = 0.5 - ex * 0.2 - ey * 0.4 - (d > 0.7 && ey > 0 ? 0.25 : 0)
                        u.px(x, y, eterniaDither(leaf, v, x, y, grain: 0.22))
                    }
                }
            }
        }
        for (x, y) in [(cx - 42, top + 17), (cx + 6, top + 13), (cx + 40, top + 17), (cx - 22, top + 15), (cx + 24, top + 15)] {
            u.rect(x - 1, y, 3, 2, flower); u.px(x, y, flowerL); u.px(x, y + 1, C(0xF0D040))
        }
    }

    /// A giant fern standing at `bx`: seven fronds fanning up and out from the ground and drooping at their tips,
    /// leaflets along each, lit on top and darker low down.
    private static func jungleFern(_ u: PixelCanvas, _ bx: Int, _ B: Int, _ size: Double, seed: Int) {
        let leaf = [C(0x183A1A), C(0x245A24), C(0x34762E), C(0x4E9638)]
        for i in 0..<7 {
            let a = -1.2 + Double(i) * 0.4 + (noise(seed + i) - 0.5) * 0.15
            let len = size * (0.7 + 0.3 * cos(a))
            let n = Int(len * 1.6)
            for st in 0...n {
                let k = Double(st) / Double(n)
                let x = Double(bx) + sin(a) * len * k * 1.15
                let y = Double(B - 1) - cos(a) * len * k + len * 0.6 * k * k * (abs(sin(a)) + 0.35)
                let dxd = sin(a) * 1.15, dyd = -cos(a) + 1.2 * k * (abs(sin(a)) + 0.35)
                let m = max(0.01, (dxd * dxd + dyd * dyd).squareRoot())
                let px = -dyd / m, py = dxd / m
                let height = Double(B - 1) - y
                let v = 0.25 + height / (size * 1.2) * 0.6
                u.px(Int(x), Int(y), leaf[0])
                guard st % 2 == 0 else { continue }
                let ll = Int((1 - k) * 4) + 1
                for l in 1...ll {
                    for sgn in [-1.0, 1.0] {
                        let lx = x + px * Double(l) * sgn + dxd / m * Double(l) * 0.5
                        let ly = y + py * Double(l) * sgn + dyd / m * Double(l) * 0.5
                        u.px(Int(lx), Int(ly), eterniaDither(leaf, v + (sgn < 0 ? 0.1 : -0.05), Int(lx), Int(ly), grain: 0.2))
                    }
                }
            }
        }
    }

    /// The Vine Jungle's life: the hanging vines swaying, each its own way, and fireflies drifting and blinking.
    static func eterniaVineJungleLife(_ c: PixelCanvas, _ g: Int, _ t: Double) {
        let f = eterniaHall(c, g), s = unit(g)
        let u = PixelCanvas(f.w, f.h)
        for v in eterniaJungleVines(f.w, f.h) {
            let sway = sin(t * 0.7 + v.ph) * 2.2
            for i in 0..<v.len {
                let k = Double(i) / Double(max(1, v.len))
                let x = v.x + Int((sway * k * k).rounded()), y = v.y + i
                u.px(x, y, C(0x34521E))
                if i % 3 == 1 { u.px(x + (i / 3 % 2 == 0 ? 1 : -1), y, C(0x5A8A30)) }
            }
            let ex = v.x + Int(sway.rounded()), ey = v.y + v.len
            if Int(v.ph * 10) % 3 == 0 { u.rect(ex - 1, ey, 3, 2, C(0xD04A9A)); u.px(ex, ey, C(0xF07AC0)) }
            else { u.rect(ex - 1, ey - 1, 2, 2, C(0x4E8A2E)) }
        }
        eterniaBlowUp(c, u, f.x, f.y, f.q)
        // Fireflies: soft yellow-green lights drifting over the ferns, blinking slowly.
        let n = max(10, c.w / 36)
        for k in 0..<n {
            let bx = noise(k * 7 + 600) * Double(c.w), by = Double(g) - (12 + noise(k * 7 + 601) * Double(min(70, g / 2))) * Double(s)
            let x = Int(bx + sin(t * 0.3 + Double(k)) * Double(18 * s)), y = Int(by + sin(t * 0.45 + Double(k) * 2) * Double(6 * s))
            let glow = 0.5 + 0.5 * sin(t * 1.8 + Double(k) * 1.3)
            guard glow > 0.2 else { continue }
            c.circle(x, y, 3 * s, C(0xD8F060, 0.16 * glow)); c.circle(x, y, s + 1, C(0xE8FF70, 0.35 * glow))
            c.rect(x, y, s + 1, s + 1, C(0xF8FFA0, glow))
        }
    }
}
