import Foundation

// The universe's roster: who the characters are (their personas, from the Art files), where each one lives, who fights
// whom first, who gets picked up by what, and the `Theme` that puts it all together. Then the place keys, and every
// place's drawing merged from the Places files.
//
// Names: every top-level name in the folder starts with the prefix (lower-cased for helpers) or is `private`. Preview
// compiles every universe together, so two universes' `drawHat`s would clash, and a plain name could shadow one the
// app relies on (scripts/pr-guard.py refuses it). Helpers one file uses stay `private` to it; helpers several files
// share go in a `<Prefix>Kit.swift` with prefixed names.

extension HuntHero {
    var persona: Persona { huntHeroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

extension HuntVillain {
    var persona: Persona { huntVillainPersonas[self] ?? Persona.missing(String(describing: self)) }
}

/// Every hero's persona, from the Art/HuntHeroes*.swift files (8 to 10 a file), and HEM's, who the engine draws
/// in this universe's costume (HuntHem.swift). Add each new art file to the list.
let huntHeroPersonas: [HuntHero: Persona] = [huntHeroes1, huntHeroes2, huntHeroes3]
    .reduce([.hem: hemPersona(.hunters)]) { $0.merging($1) { a, _ in a } }
/// Every villain's persona, from the Art/HuntVillains*.swift files.
let huntVillainPersonas: [HuntVillain: Persona] = [huntVillains1, huntVillains2, huntVillains3, huntVillains4]
    .reduce([:]) { $0.merging($1) { a, _ in a } }

// MARK: - Homes

extension Location {
    /// Where each villain belongs: the crew gathers there when one leads the first session (window mode, Automatic).
    /// Every character's home is one of this universe's places, and a `switch` with no `default` makes the compiler
    /// ask for each new case.
    static func huntHome(of villain: HuntVillain) -> Location {
        switch villain {
        case .crossroadsDemon, .megMasters, .ramiel: return .huntCrossroads
        case .lucifer, .war, .pestilence: return .huntStull
        case .clawdley, .lilith, .alastair, .abaddon, .asmodeus, .dagon: return .huntHell
        case .zachariah: return .huntHeaven
        case .ruby: return .huntMotel
        case .demonDean: return .huntRoadhouse   // a bar and a karaoke mic
        // Until their own places come in phase 3: Lawrence (Azazel), the orchard (Cain), Apocalypse World (Michael),
        // Chuck's house (Chuck, Metatron), Roman Enterprises (Dick Roman) and the diner (Death, Famine).
        case .azazel: return .huntHell
        case .cain: return .huntCrossroads
        case .michael, .metatron, .chuck: return .huntHeaven
        case .dickRoman: return .huntMotel
        case .death, .famine: return .huntRoadhouse
        }
    }

    static func huntHome(of hero: HuntHero) -> Location {
        switch hero {
        case .deanWinclawdster, .samWinclawdster, .clawdstiel, .jackKlyne, .henryWinclawdster, .kevinTran, .hem:
            return .huntBunker
        case .bobbyClawdsinger: return .huntSalvage
        case .ellenHarvell, .joHarvell, .ash: return .huntRoadhouse
        case .rowenaMacClawd: return .huntHell   // Queen of Hell, in the end
        case .gabriel: return .huntHeaven
        // Until their own places come in phase 3: Lawrence (Mary, John) and Moondoor (Charlie).
        case .maryWinclawdster, .johnWinclawdster, .charlieClawdbury: return .huntBunker
        }
    }
}

// MARK: - The theme

/// A character as a `Cast`. Everywhere else, name the enum too (`.hero(HuntHero.deanWinclawdster)`): every universe has
/// a `.hero(_:)` and a `.hem`, so a bare `.hero(.hem)` is ambiguous once they're all compiled together.
extension Cast {
    static func hero(_ h: HuntHero) -> Cast { Cast(universe: .hunters, isDark: false, index: h.rawValue) }
    static func villain(_ v: HuntVillain) -> Cast { Cast(universe: .hunters, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line. Each
/// pair is a hero and a villain from this universe; a character can be in more than one pair.
private let huntNemeses: [(HuntHero, HuntVillain)] = [
    (.deanWinclawdster, .michael), (.samWinclawdster, .lucifer), (.clawdstiel, .metatron), (.jackKlyne, .chuck),
    (.johnWinclawdster, .azazel), (.bobbyClawdsinger, .clawdley), (.charlieClawdbury, .dickRoman),
    (.gabriel, .asmodeus), (.henryWinclawdster, .abaddon),
    // Still to come with their characters in phase 3: Mary and Lady Toni Bevell, Kevin and Gadreel, Benny and Eve,
    // Victor Henriksen and Lilith, Mick Davies and Arthur Ketch.
]

let huntTheme = Theme(
    universe: .hunters,
    villains: HuntVillain.allCases.map(\.persona),
    heroes: HuntHero.allCases.map(\.persona),
    // Every place, in menu order. The first is the default: where the crew stands when nobody's home is known. A full
    // universe has about 20.
    places: [.huntBunker, .huntSalvage, .huntRoadhouse, .huntMotel, .huntCrossroads, .huntStull, .huntHell, .huntHeaven],
    home: { c in
        c.isDark ? .huntHome(of: HuntVillain(rawValue: c.index) ?? .clawdley)
                 : .huntHome(of: HuntHero(rawValue: c.index) ?? .deanWinclawdster)
    },
    nemeses: huntNemeses.map { (.hero($0.0), .villain($0.1)) },
    // Who gets picked up when their agent is done, and by what: nil walks off on foot, as everyone does here. A ride is
    // a `Ride` of this universe's own (`static let` in an extension of `Ride`, listed in the module's `rides`), drawn
    // nose to the right; see Slayer/SlayerUniverse.swift and SlayerRides.swift for a bus and two cars that drive in.
    ride: { c in
        guard c.universe == .hunters else { return nil }
        return nil
    },
    menuIcon: huntMenuIcon,
    // Who stands in for a session in Status Symbols: usually the universe's lead hero.
    legend: .hero(HuntHero.deanWinclawdster))

// MARK: - Places

// The place keys. They're saved in settings and the screen-saver feed, and unique across every universe, so each starts
// with the prefix (Tools/new-universe.sh renames the `sample…` ones here).
extension Location {
    static let huntBunker = Location("huntBunker")
    static let huntSalvage = Location("huntSalvage")
    static let huntRoadhouse = Location("huntRoadhouse")
    static let huntMotel = Location("huntMotel")
    static let huntCrossroads = Location("huntCrossroads")
    static let huntStull = Location("huntStull")
    static let huntHell = Location("huntHell")
    static let huntHeaven = Location("huntHeaven")
}

/// Every place's drawing, from the Places/HuntScenes*.swift files (a few places a file). Add each new file to the
/// list.
let huntPlaces: [Location: Place] = [huntScenes1, huntScenes2, huntScenes3]
    .reduce([:]) { $0.merging($1) { a, _ in a } }
