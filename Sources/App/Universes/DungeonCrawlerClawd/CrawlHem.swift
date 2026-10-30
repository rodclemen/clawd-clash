import Foundation

// HEM in this universe. He's the same rare face in every universe (the last hero, `Universe.hem`): his face, buns,
// body and fist-shaking signature are the engine's (Sources/App/Universes/Hem.swift). The costume is yours, drawn at
// fixed moments of him in this order: `legs`, then after the breath his body in `top`'s colours and `chest` over it,
// `hat` over his hair, his face, and `prop` in his hand.
//
// Here he's a crawler and a fan: a denim jacket covered in sewn-on patches, a pink "Princess Posse" sash across it,
// cargo shorts and trainers, and a slingshot he fights with, its stones drawn as the engine's thrown shot.

private let denim = C(0x4A6A9A), denimD = C(0x34507A), denimL = C(0x6A8ABA)
private let sash = C(0xF07AB8), sashD = C(0xC04E8E)

let crawlHem = HemCostume(
    persona: { Persona(name: "HEM", weapon: .blaster, shot: .thrown(C(0x9A9AA2)), muzzle: (48, 30), headTop: 17,
                       signature: 2.6, draw: $0) },
    legs: { c, p in   // khaki cargo shorts over bare legs, white trainers
        drawLegs(c, Look(), step: p.step)
        if !seatedPose { for lx in [19, 23, 31, 35] { c.rect(lx, 36, 2, 3, C(0x9A8A5E)); c.px(lx + 1, 38, C(0x7A6A44)) } }
        drawBoots(c, C(0xEEEEF0), step: p.step, rows: 2)
    },
    top: (denim, denimD, denim, denim),
    chest: { c, _ in   // the patches, the pink sash from his left shoulder to his right hip, its gold tassel
        c.rect(19, 34, 3, 2, C(0xC8302A)); c.px(20, 34, C(0xF0C840))   // a dynamite patch
        c.rect(33, 35, 3, 2, C(0x2A64C8)); c.px(34, 35, C(0xF0F6FF))   // a System-blue patch
        c.rect(30, 33, 2, 2, C(0xF0C840))                              // a crown patch
        for k in 0..<6 { c.rect(21 + k * 2, 33 + k * 4 / 5, 3, 1, sash); c.px(21 + k * 2, 34 + k * 4 / 5, sashD) }
        c.px(33, 38, C(0xF0C840))
        c.rect(18, 33, 1, 4, denimL); c.rect(24, 36, 1, 2, denimD)
    },
    prop: { c, p, _, _ in   // the slingshot: a wooden fork, its band drawn back while he aims
        let y = 29 + p.gunY
        c.pattern(40, y, [
            "W...W",
            "W...W",
            ".WWW.",
            "..W..",
            "..W..",
        ], ["W": C(0x8A5A32)])
        c.rect(41, y, 3, 1, C(0x5A3A22, 0.8))
    })
