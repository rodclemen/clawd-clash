import Foundation

// "By the power of Greyskull!": Clawds of the Universe's compaction (`compaction: .transform` in EterniaFacts.swift).
// When a session led by one of the four secret identities compacts, its leader changes into the other self, and back
// at the next. The engine swaps the leader (never while the other self is on stage) and draws this over the character,
// already in its new self:
//  - Prince Addam into He-Clawd: lightning cracks down out of the sky onto him, a white-out, and he stands there in
//    the last of it, crackling. "I have the power!"
//  - Cringer into Battle Kat: a stray bolt from the side, the same white-out. "Rrraaawr!"
//  - Adorra into She-Clawd: a spiral of gold and rainbow light winds up round her, then the white-out. "For the
//    honour of Greyskull!"
//  - Spirit into Swift Wind: a rainbow sweeps over him and sparkles settle.
//  - Back again, any of them: a soft white glow that fades, no lightning.
// And the moral of the story: now and then, when a hero's session finishes its work, they step forward with a lesson,
// as every episode ended (`morals` in the facts says who and how often; the lines are here).

/// The transformation, as the module's `transformation`.
let eterniaTransformation = Transformation(length: 2.6, draw: { c, k, t, into in eterniaDrawPower(c, k: k, t: t, into: into) },
                                           says: { into in eterniaPowerLine(into) })

/// What they say as they change, over their head; nothing on the way back.
private func eterniaPowerLine(_ into: Cast) -> String? {
    guard into.universe == .eternia, !into.isDark else { return nil }
    switch EterniaHero(rawValue: into.index) {
    case .heClawd?: return "I have the power!"
    case .sheClawd?: return "For the honour of Greyskull!"
    case .battleKat?: return "Rrraaawr!"
    default: return nil
    }
}

/// How the change looks, by who they become.
private enum EterniaPowerKind { case lightning, stray, spiral, rainbow, back }

private func eterniaPowerKind(_ into: Cast) -> EterniaPowerKind {
    guard into.universe == .eternia, !into.isDark else { return .back }
    switch EterniaHero(rawValue: into.index) {
    case .heClawd?: return .lightning
    case .battleKat?: return .stray
    case .sheClawd?: return .spiral
    case .swiftWind?: return .rainbow
    default: return .back
    }
}

/// Every pixel of the character drawn so far, turned towards `col` by `a` (0…1): the white-out.
private func eterniaWhiteOut(_ c: PixelCanvas, _ col: Px, _ a: Double) {
    guard a > 0 else { return }
    for y in 0..<c.h {
        for x in 0..<c.w where c.buf[(y * c.w + x) * 4 + 3] > 0 { c.px(x, y, col.alpha(min(1, a))) }
    }
}

/// A bolt of lightning from `a` to `b`, jagged, a white core in a pale blue edge; `seed` changes its zigzag.
private func eterniaBolt(_ c: PixelCanvas, _ a: (x: Double, y: Double), _ b: (x: Double, y: Double), seed: Int) {
    let steps = 7
    var p = a
    for i in 1...steps {
        let k = Double(i) / Double(steps)
        let jag = i == steps ? 0 : (noise(seed * 31 + i) - 0.5) * 6
        let q = (x: a.x + (b.x - a.x) * k + jag, y: a.y + (b.y - a.y) * k)
        c.glowLine(p.x, p.y, q.x, q.y, core: C(0xFFFFFF), glow: C(0x9AD8FF), coreR: 0.5, glowR: 1.4)
        p = q
    }
}

/// The change, drawn over the character (the canvas: 72×52, its body about x 18…37, its head's top about row 20),
/// `k` (0…1) through it.
func eterniaDrawPower(_ c: PixelCanvas, k: Double, t: Double, into: Cast) {
    let kind = eterniaPowerKind(into)
    let flicker = 0.75 + 0.25 * sin(t * 40)
    switch kind {
    case .lightning, .stray:
        // The bolt strikes for the first third, flickering; the white-out peaks as it lands and fades.
        if k < 0.34 {
            let seed = Int(t * 14)
            if kind == .lightning {
                eterniaBolt(c, (28, 0), (28, 18), seed: seed)
                if k > 0.1 { eterniaBolt(c, (28, 18), (14, 30), seed: seed + 5); eterniaBolt(c, (28, 18), (42, 30), seed: seed + 9) }
            } else {
                eterniaBolt(c, (70, 6), (36, 26), seed: seed)
            }
        }
        let white = k < 0.3 ? k / 0.3 : max(0, 1 - (k - 0.3) / 0.5)
        eterniaWhiteOut(c, C(0xFFFFFF), white * flicker)
        // Crackles round them as it fades.
        if k > 0.3 && k < 0.9 {
            for i in 0..<5 {
                let a = Double(i) * 1.26 + t * 3, r = 13 + 3 * sin(t * 9 + Double(i))
                let x = 28 + cos(a) * r, y = 31 + sin(a) * r * 0.8
                c.glowLine(x, y, x + cos(a + 1.2) * 2.5, y + sin(a + 1.2) * 2.5, core: C(0xFFFFFF), glow: C(0x9AD8FF),
                           coreR: 0.35, glowR: 0.9, strength: 1 - k)
            }
        }
    case .spiral:
        // Gold and rainbow light winding up round her, then the white-out.
        let rainbow = [C(0xFF5A5A), C(0xFFB040), C(0xFFE860), C(0x6AE07A), C(0x5AB8FF), C(0xB070FF)]
        if k < 0.7 {
            // Two strands, gold and rainbow, a dot of light every few pixels, rising as it goes on.
            let rise = min(1, k / 0.45)
            for strand in 0..<2 {
                for i in 0..<30 {
                    let u = Double(i) / 30
                    let a = u * 4 * .pi + t * 7 + Double(strand) * .pi, r = 19 - 7 * u
                    let x = Int((28 + cos(a) * r).rounded()), y = Int((46 - u * 38 * rise).rounded())
                    guard y > 1, x > 1, x < c.w - 3 else { continue }
                    c.rect(x, y, 2, 2, strand == 0 ? C(0xFFE070) : rainbow[i % rainbow.count])
                }
            }
        }
        let white = k < 0.45 ? 0 : k < 0.6 ? (k - 0.45) / 0.15 : max(0, 1 - (k - 0.6) / 0.35)
        eterniaWhiteOut(c, C(0xFFF4D0), white * flicker)
    case .rainbow:
        // A rainbow sweeps over him from back to front, sparkles settling after it.
        let rainbow = [C(0xFF5A5A), C(0xFFB040), C(0xFFE860), C(0x6AE07A), C(0x5AB8FF), C(0xB070FF)]
        let sweep = 6 + k * 70
        for (i, col) in rainbow.enumerated() {
            for x in 2..<(c.w - 3) where Double(x) < sweep && Double(x) > sweep - 26 {
                let y = 30 - Int(14 * sin(Double(x) / 72 * .pi)) + i
                c.px(x, y, col.alpha(0.85 * (1 - k)))
            }
        }
        for i in 0..<8 where k > 0.3 {
            let x = 16 + Int(noise(i * 7 + 1) * 28), y = 16 + Int(noise(i * 7 + 2) * 26) + Int(k * 6)
            c.px(x, y, C(0xFFFFFF, 1 - k))
        }
    case .back:
        // A soft white glow that fades, no lightning.
        eterniaWhiteOut(c, C(0xF4F0FF), 0.55 * (1 - k))
        for i in 0..<6 {
            let x = 16 + Int(noise(i * 5 + 3) * 26), y = 40 - Int(k * 24) + Int(noise(i * 5 + 4) * 10)
            c.px(x, y, C(0xFFFFFF, 0.9 * (1 - k)))
        }
    }
}

/// The lessons, one picked each time: the Filmation voice with a coding twist.
let eterniaMorals = [
    "Remember, kids: always write your tests!",
    "Remember, kids: read the error message before you ask for help.",
    "Sharing your code is good, but never share your passwords!",
    "Commit before you refactor. Even He-Clawd saves his work.",
    "Never run a script from a stranger without reading it first.",
    "Nobody's code is perfect. Even Man-At-Clawds asks for a review.",
    "Bullies force-push. Friends open a pull request.",
    "Stuck on a bug? Take a break. It'll still be there, and so will you.",
    "Orkko learned today that magic numbers cause trouble. Give them names!",
    "Back up your files. Castle Greyskull didn't last this long by luck.",
]
