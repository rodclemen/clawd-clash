import Foundation

// The universe's roster: who the characters are (their personas, from the Art files), where each one lives, who fights
// whom first, who gets picked up by what, and the `Theme` that puts it all together. Then the place keys, and every
// place's drawing merged from the Places files.
//
// Names: every top-level name in the folder starts with the prefix (lower-cased for helpers) or is `private`. Preview
// compiles every universe together, so two universes' `drawHat`s would clash, and a plain name could shadow one the
// app relies on (scripts/pr-guard.py refuses it). Helpers one file uses stay `private` to it; helpers several files
// share go in a `<Prefix>Kit.swift` with prefixed names.

extension CrawlHero {
    var persona: Persona { crawlHeroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

extension CrawlVillain {
    var persona: Persona { crawlVillainPersonas[self] ?? Persona.missing(String(describing: self)) }
}

/// Every hero's persona, from the Art/CrawlHeroes*.swift files (8 to 10 a file), and HEM's, who the engine draws
/// in this universe's costume (CrawlHem.swift). Add each new art file to the list.
let crawlHeroPersonas: [CrawlHero: Persona] = [crawlHeroes1]
    .reduce([.hem: hemPersona(.crawl)]) { $0.merging($1) { a, _ in a } }
/// Every villain's persona, from the Art/CrawlVillains*.swift files.
let crawlVillainPersonas: [CrawlVillain: Persona] = [crawlVillains1]
    .reduce([:]) { $0.merging($1) { a, _ in a } }

// MARK: - Homes

extension Location {
    /// Where each villain belongs: the crew gathers there when one leads the first session (window mode, Automatic).
    /// Every character's home is one of this universe's places, and a `switch` with no `default` makes the compiler
    /// ask for each new case.
    static func crawlHome(of villain: CrawlVillain) -> Location {
        switch villain {
        case .maestro: return .crawlSafeRoom
        }
    }

    static func crawlHome(of hero: CrawlHero) -> Location {
        switch hero {
        case .carl, .donut, .mongo, .hem: return .crawlSafeRoom
        }
    }
}

// MARK: - The theme

/// A character as a `Cast`. Everywhere else, name the enum too (`.hero(CrawlHero.carl)`): every universe has
/// a `.hero(_:)` and a `.hem`, so a bare `.hero(.hem)` is ambiguous once they're all compiled together.
extension Cast {
    static func hero(_ h: CrawlHero) -> Cast { Cast(universe: .crawl, isDark: false, index: h.rawValue) }
    static func villain(_ v: CrawlVillain) -> Cast { Cast(universe: .crawl, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line. Each
/// pair is a hero and a villain from this universe; a character can be in more than one pair.
private let crawlNemeses: [(CrawlHero, CrawlVillain)] = [
    (.carl, .maestro),   // Death Watch, and the grenade he bought to kill Carl
]

let crawlTheme = Theme(
    universe: .crawl,
    villains: CrawlVillain.allCases.map(\.persona),
    heroes: CrawlHero.allCases.map(\.persona),
    // Every place, in menu order. The first is the default: where the crew stands when nobody's home is known. A full
    // universe has about 20.
    places: [.crawlSafeRoom],
    home: { c in
        c.isDark ? .crawlHome(of: CrawlVillain(rawValue: c.index) ?? .maestro)
                 : .crawlHome(of: CrawlHero(rawValue: c.index) ?? .carl)
    },
    nemeses: crawlNemeses.map { (.hero($0.0), .villain($0.1)) },
    // Who gets picked up when their agent is done, and by what: nil walks off on foot, as everyone does here. A ride is
    // a `Ride` of this universe's own (`static let` in an extension of `Ride`, listed in the module's `rides`), drawn
    // nose to the right; see Slayer/SlayerUniverse.swift and SlayerRides.swift for a bus and two cars that drive in.
    ride: { c in
        guard c.universe == .crawl else { return nil }
        return nil
    },
    menuIcon: crawlMenuIcon,
    // Who stands in for a session in Status Symbols: usually the universe's lead hero.
    legend: .hero(CrawlHero.carl))

// MARK: - Places

// The place keys. They're saved in settings and the screen-saver feed, and unique across every universe, so each starts
// with the prefix (Tools/new-universe.sh renames the `sample…` ones here).
extension Location {
    static let crawlSafeRoom = Location("crawlSafeRoom")
}

/// Every place's drawing, from the Places/CrawlScenes*.swift files (a few places a file). Add each new file to the
/// list.
let crawlPlaces: [Location: Place] = [crawlScenes1]
    .reduce([:]) { $0.merging($1) { a, _ in a } }
