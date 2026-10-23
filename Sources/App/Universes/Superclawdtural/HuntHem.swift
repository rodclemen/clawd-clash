import Foundation

// HEM in this universe. He's the same rare face in every universe (the last hero, `Universe.hem`): his face, buns,
// body and fist-shaking signature are the engine's (Sources/App/Universes/Hem.swift). The costume is yours, drawn at
// fixed moments of him in this order: `legs`, then after the breath his body in `top`'s colours and `chest` over it,
// `hat` over his hair, his face, and `prop` in his hand.
//
// Here he's a hunter: a red flannel shirt, Dean's amulet on its cord, a trucker cap, jeans and boots, and a sawn-off
// shotgun loaded with rock salt.

private let flannel = C(0xA03028), flannelD = C(0x6E1E1A), flannelL = C(0xC4503E)
private let mesh = C(0x3A4A3A), meshD = C(0x2A362A), foam = C(0xE8E2D0), bill = C(0x2E3A2E)

let huntHem = HemCostume(
    // His persona: the shotgun fires rock salt, drawn as the engine's bullet.
    persona: { Persona(name: "HEM", weapon: .blaster, shot: .bullet, muzzle: (52, 32), headTop: 16, signature: 2.6, draw: $0) },
    legs: { c, p in   // jeans and brown boots, before the breath so they stay on the ground
        drawLegs(c, Look(leg: C(0x3E5A86)), step: p.step)
        drawBoots(c, C(0x4A3020), step: p.step, rows: 2)
    },
    top: (flannel, flannelD, flannel, flannel),
    chest: { c, _ in   // the flannel's checks over his shirt, open at the neck, and the amulet hanging on its cord
        huntPlaid(c, 18, 34, 20, 4, base: flannel, dark: flannelD, light: flannelL)
        c.rect(26, 34, 4, 1, C(0x2E2E34))
        c.px(26, 35, C(0x2A1A10)); c.px(29, 35, C(0x2A1A10))
        c.rect(27, 36, 2, 2, C(0xE0B040)); c.px(28, 37, C(0x9A7420))
    },
    prop: { c, p, _, _ in   // the sawn-off: two short barrels over a stubby walnut stock, kicking with each shot
        c.pattern(39, 31 + p.gunY, [
            "..BBBBBBBBBBBB",
            "..bbbbbbbbbbbb",
            "WWWWkk........",
            "WWW...........",
        ], ["B": C(0x5A5E66), "b": C(0x34363C), "W": C(0x7A4A2A), "k": C(0x2A2A30)])
    },
    hat: { c, _ in   // the trucker cap: a white foam front, green mesh behind it, the bill out towards where he faces
        c.pattern(18, 15, [
            "......MMMMMFFFFF......",
            "....MMmMmMMFFFFFF.....",
            "...MMMMMMMMFFFFFFF....",
            "...MmMmMmMMFFFFFFF....",
            "...MMMMMMMMMMMMMMMMBBBB",
        ], ["M": mesh, "m": meshD, "F": foam, "B": bill])
    })
