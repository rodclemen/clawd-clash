import Foundation

// The universe's roster: who the characters are (their personas, from the Art files), where each one lives, who fights
// whom first, who gets picked up by what, and the `Theme` that puts it all together. Then the place keys, and every
// place's drawing merged from the Places files.
//
// Names: every top-level name in the folder starts with the prefix (lower-cased for helpers) or is `private`. Preview
// compiles every universe together, so two universes' `drawHat`s would clash, and a plain name could shadow one the
// app relies on (scripts/pr-guard.py refuses it). Helpers one file uses stay `private` to it; helpers several files
// share go in a `<Prefix>Kit.swift` with prefixed names.

extension EterniaHero {
    var persona: Persona { eterniaHeroPersonas[self] ?? Persona.missing(String(describing: self)) }
}

extension EterniaVillain {
    var persona: Persona { eterniaVillainPersonas[self] ?? Persona.missing(String(describing: self)) }
}

/// Every hero's persona, from the Art/EterniaHeroes*.swift files (8 to 10 a file), and HEM's, who the engine draws
/// in this universe's costume (EterniaHem.swift). Add each new art file to the list.
let eterniaHeroPersonas: [EterniaHero: Persona] = [eterniaHeroes1, eterniaHeroes2, eterniaHeroes3, eterniaHeroes4]
    .reduce([.hem: hemPersona(.eternia)]) { $0.merging($1) { a, _ in a } }
/// Every villain's persona, from the Art/EterniaVillains*.swift files.
let eterniaVillainPersonas: [EterniaVillain: Persona] = [eterniaVillains1, eterniaVillains2, eterniaVillains3]
    .reduce([:]) { $0.merging($1) { a, _ in a } }

// MARK: - Homes

extension Location {
    /// Where each villain belongs: the crew gathers there when one leads the first session (window mode, Automatic).
    /// Every character's home is one of this universe's places, and a `switch` with no `default` makes the compiler
    /// ask for each new case.
    static func eterniaHome(of villain: EterniaVillain) -> Location {
        switch villain {
        case .skeleclawd, .evilLynn, .beastClawd, .trapClawd, .triClawdps, .merClawd, .clawdful, .screeech:
            return .eterniaSnakeMountain   // Mer-Clawd and Beast Clawd until their own realms are built
        case .kobraKhan: return .eterniaVineJungle
        case .hordakk, .shadowWeaver, .katra, .scorpia, .mantenna, .imp, .hordeTrooper: return .eterniaFrightZone
        }
    }

    static func eterniaHome(of hero: EterniaHero) -> Location {
        switch hero {
        case .heClawd, .sorceress, .battleKat, .hem: return .eterniaGreyskull
        case .kingRandor, .queenMarlena, .princeAddam, .cringer, .teelah, .orkko, .ramClawd, .manEClawds, .mekaneck:
            return .eterniaPalace
        case .stratos, .buzzOff: return .eterniaPalace   // until Avion and Andreenos are built
        case .manAtClawds: return .eterniaWorkshop
        case .clawdfist: return .eterniaVineJungle
        case .adorra, .spirit, .bow, .madameRazz, .kowl: return .eterniaWhisperingWoods
        case .glimmer: return .eterniaWhisperingWoods   // until Bright Moon is built
        case .sheClawd, .swiftWind: return .eterniaCrystalCastle
        }
    }
}

// MARK: - The theme

/// A character as a `Cast`. Everywhere else, name the enum too (`.hero(EterniaHero.heClawd)`): every universe has
/// a `.hero(_:)` and a `.hem`, so a bare `.hero(.hem)` is ambiguous once they're all compiled together.
extension Cast {
    static func hero(_ h: EterniaHero) -> Cast { Cast(universe: .eternia, isDark: false, index: h.rawValue) }
    static func villain(_ v: EterniaVillain) -> Cast { Cast(universe: .eternia, isDark: true, index: v.rawValue) }
}

/// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line. Each
/// pair is a hero and a villain from this universe; a character can be in more than one pair.
private let eterniaNemeses: [(EterniaHero, EterniaVillain)] = [
    (.heClawd, .skeleclawd),
    (.sheClawd, .hordakk),
    (.princeAddam, .beastClawd),
    (.adorra, .katra),
    (.teelah, .evilLynn),
    (.manAtClawds, .trapClawd),
    (.mekaneck, .triClawdps),
    (.ramClawd, .clawdful),
    (.bow, .mantenna),
]

let eterniaTheme = Theme(
    universe: .eternia,
    villains: EterniaVillain.allCases.map(\.persona),
    heroes: EterniaHero.allCases.map(\.persona),
    // Every place, in menu order. The first is the default: where the crew stands when nobody's home is known. A full
    // universe has about 20.
    places: [.eterniaGreyskull, .eterniaPalace, .eterniaWorkshop, .eterniaSnakeMountain, .eterniaVineJungle,
             .eterniaFrightZone, .eterniaWhisperingWoods, .eterniaCrystalCastle],
    home: { c in
        c.isDark ? .eterniaHome(of: EterniaVillain(rawValue: c.index) ?? .skeleclawd)
                 : .eterniaHome(of: EterniaHero(rawValue: c.index) ?? .heClawd)
    },
    nemeses: eterniaNemeses.map { (.hero($0.0), .villain($0.1)) },
    // Who gets picked up when their agent is done, and by what: nil walks off on foot, as everyone does here. A ride is
    // a `Ride` of this universe's own (`static let` in an extension of `Ride`, listed in the module's `rides`), drawn
    // nose to the right; see Slayer/SlayerUniverse.swift and SlayerRides.swift for a bus and two cars that drive in.
    ride: { c in
        guard c.universe == .eternia else { return nil }
        return nil
    },
    menuIcon: eterniaMenuIcon,
    // Who stands in for a session in Status Symbols: usually the universe's lead hero.
    legend: .hero(EterniaHero.heClawd))

// MARK: - Places

// The place keys. They're saved in settings and the screen-saver feed, and unique across every universe, so each starts
// with the prefix (Tools/new-universe.sh renames the `sample…` ones here).
extension Location {
    static let eterniaGreyskull = Location("eterniaGreyskull")   // Castle Greyskull, the default
    static let eterniaPalace = Location("eterniaPalace")         // the Royal Palace of Eternos
    static let eterniaWorkshop = Location("eterniaWorkshop")     // Man-At-Clawds's workshop
    static let eterniaSnakeMountain = Location("eterniaSnakeMountain")
    static let eterniaVineJungle = Location("eterniaVineJungle")
    static let eterniaFrightZone = Location("eterniaFrightZone")
    static let eterniaWhisperingWoods = Location("eterniaWhisperingWoods")
    static let eterniaCrystalCastle = Location("eterniaCrystalCastle")
}

/// Every place's drawing, from the Places/EterniaScenes*.swift files (a few places a file). Add each new file to the
/// list.
let eterniaPlaces: [Location: Place] = [eterniaScenes1, eterniaScenes2, eterniaScenes3]
    .reduce([:]) { $0.merging($1) { a, _ in a } }
