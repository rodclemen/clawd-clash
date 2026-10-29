import Foundation

// HEM in this universe. He's the same rare face in every universe (the last hero, `Universe.hem`): his face, buns,
// body and fist-shaking signature are the engine's (Sources/App/Universes/Hem.swift). The costume is his own.
//
// Here: a fan's He-Clawd. A blond pageboy wig, a cardboard harness painted silver with a red cross felt-tipped on it,
// brown fake-fur shorts and boots, and a foam Power Sword.

private let wig = C(0xF0CC5E), wigDark = C(0xC09A3A), wigLight = C(0xFFE896)
private let card = C(0xA8ACB6), cardDark = C(0x7A7E88), cross = C(0xD03A30)
private let fur = C(0x8A5A30), furDark = C(0x5E3A1C), furLight = C(0xAA7646)
private let foam = C(0xD8DCE4), foamDark = C(0xA4A8B2), hilt = C(0x8A6ABA)

let eterniaHem = HemCostume(
    persona: { Persona(name: "HEM", weapon: .saber, headTop: 16, signature: 2.6, draw: $0) },
    legs: { c, p in   // bare legs and fake-fur boots, lit along the top
        drawLegs(c, Look(), step: p.step)
        guard !seatedPose else { return }
        for (i, lx) in [19, 23, 31, 35].enumerated() {
            let bottom = p.step >= 0 && i % 2 == p.step ? 42 : 43
            c.rect(lx, bottom - 2, 2, 3, fur); c.rect(lx, bottom - 2, 2, 1, furLight)
        }
    },
    top: (clawdOrange, clawdShade, clawdOrange, clawdOrange),
    chest: { c, _ in   // the cardboard harness, its red cross a little wonky, and the fake-fur shorts
        c.rect(19, 33, 18, 2, card); c.rect(36, 33, 1, 2, cardDark); c.rect(19, 33, 18, 1, C(0xC4C8D0))
        c.rect(26, 33, 4, 1, cross); c.rect(27, 34, 2, 1, cross); c.px(25, 33, cross)
        eterniaFur(c, 18, 36, 20, 2, base: fur, dark: furDark, light: furLight)
    },
    prop: { c, p, _, _ in eterniaHemSword(c, angle: p.melee) },
    hat: { c, _ in   // the wig: a round blond cap, a straight fringe, the strands in strokes
        c.pattern(18, 16, [
            "....WWWlWWWWlWWW....",
            "..WWlWWWWWWWWWWlWW..",
            ".WWWWWwWWWWwWWWWWWW.",
            "WWwWWWWWwWWWWwWWWwWW",
            "WWWWWWWWWWWWWWWWWWWW",
            "WwwwwwwwwwwwwwwwwwwW",
        ], ["W": wig, "w": wigDark, "l": wigLight])
    })

/// His foam Power Sword: swung at `angle` degrees from his hand, or, put away, held point down at his side.
private func eterniaHemSword(_ c: PixelCanvas, angle: Double?) {
    guard let a = angle else {
        c.rect(40, 31, 2, 3, hilt); c.rect(38, 34, 6, 1, foamDark)
        c.rect(40, 35, 2, seatedPose ? 5 : 8, foam); c.rect(41, 35, 1, seatedPose ? 5 : 8, foamDark)
        return
    }
    let h = eterniaHand
    eterniaBar(c, h, a, from: -2.5, to: 1.5, hilt, r: 0.9)
    let g = eterniaReach(h, a, 2), g0 = eterniaReach(g, a + 90, 2.4), g1 = eterniaReach(g, a - 90, 2.4)
    c.glowLine(g0.x, g0.y, g1.x, g1.y, core: foamDark, glow: C(0, 0), coreR: 0.8, glowR: 0.9)
    eterniaBar(c, h, a, from: 3, to: 15, foam, r: 1.2)
    c.rect(Int(h.x.rounded()) - 1, Int(h.y.rounded()) - 1, 3, 3, clawdOrange)
}
