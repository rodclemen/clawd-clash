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
let crawlHeroPersonas: [CrawlHero: Persona] = [crawlHeroes1, crawlHeroes2, crawlHeroes3, crawlHeroes4, crawlHeroes5,
                                                 crawlHeroes6]
    .reduce([.hem: hemPersona(.crawl)]) { $0.merging($1) { a, _ in a } }
/// Every villain's persona, from the Art/CrawlVillains*.swift files.
let crawlVillainPersonas: [CrawlVillain: Persona] = [crawlVillains1, crawlVillains2, crawlVillains3,
                                                     crawlVillains4, crawlVillains5, crawlVillains6, crawlVillains7]
    .reduce([:]) { $0.merging($1) { a, _ in a } }

// MARK: - Homes

extension Location {
    /// Where each villain belongs: the crew gathers there when one leads the first session (window mode, Automatic).
    /// Every character's home is one of this universe's places, and a `switch` with no `default` makes the compiler
    /// ask for each new case.
    static func crawlHome(of villain: CrawlVillain) -> Location {
        switch villain {
        case .hoarder, .scatterer: return .crawlHoard
        case .juicer: return .crawlGym
        case .ballOfSwine, .ralph, .goblin, .tuskling: return .crawlCorridor
        case .frankQ, .maggieMy: return .crawlSeattle
        case .astrid: return .crawlDesperado
        case .missQuill: return .crawlOverCity
        case .grimaldi, .heather, .tsarina: return .crawlCircus
        case .goreGore, .krakaren, .dismember, .stationMimic, .hekla, .eva, .quanCh, .grull, .pooka, .cloneling:
            return .crawlTangle
        case .mrsGhazi, .ruckus: return .crawlHumpTown
        case .imogen, .lucia, .vrah: return .crawlCastle
        case .bigTina, .denise: return .crawlHunting
        case .cascadia, .loita, .harbinger: return .crawlStudio
        case .maestro, .stalwart, .chaco: return .crawlDeathWatch
        case .amayon, .shiMaria, .hydra: return .crawlHavana
        case .eris, .burcu, .agatha: return .crawlLarracos
        case .emberus: return .crawlTemple
        }
    }

    static func crawlHome(of hero: CrawlHero) -> Location {
        switch hero {
        case .tran, .florin, .ifechi, .langley, .gwendolyn, .jurgen, .osvaldo, .hem: return .crawlSafeRoom
        case .ferdinand: return .crawlSeattle
        case .elle, .imani, .brandon, .chris, .rory, .lorelai: return .crawlCorridor
        case .mordecai: return .crawlGuild
        case .carl, .donut, .mongo, .katia, .samantha, .prepotente, .louis, .garret: return .crawlPersonal
        case .sledge, .bomo, .rosemarie: return .crawlDesperado
        case .doctorBones, .splashZone, .gluteusMaxx, .dongQuixote, .damascusSteel, .anaconda: return .crawlParade
        case .bautista: return .crawlOverCity
        case .liJun, .liNa, .zhang, .tserendolgor: return .crawlTangle
        case .juiceBox, .popovs: return .crawlHumpTown
        case .miriamDom: return .crawlHunting
        case .odette, .zev, .quasar, .rosetta: return .crawlStudio
        case .formidable: return .crawlDeathWatch
        case .sisterInes: return .crawlHavana
        case .tipid, .edgar: return .crawlLarracos
        case .paterCoal, .orthrus: return .crawlTemple
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
    (.carl, .maestro),          // Death Watch, and the grenade he bought to kill Carl
    (.donut, .lucia),           // the insult to her dogs and the fight that followed
    (.katia, .hekla),           // Brynhild's Daughters
    (.chris, .maggieMy),        // she rode him like a suit
    (.brandon, .ballOfSwine),   // Meadow Lark's First Floor fight
    (.mordecai, .chaco),        // Uzzi
    (.mongo, .bigTina),         // dinosaur against dinosaur
    (.florin, .imogen),         // she wore Ifechi's face
    (.prepotente, .harbinger),  // working to remove him from the crawl
    (.samantha, .shiMaria),     // "MaeMae"
    (.zev, .loita),             // the Bloom
    (.bautista, .grimaldi),     // the circus that killed his family
    (.sisterInes, .amayon),     // her charm on him
    (.langley, .vrah),          // the hunter who took him
    (.formidable, .stalwart),   // the succession
]

let crawlTheme = Theme(
    universe: .crawl,
    villains: CrawlVillain.allCases.map(\.persona),
    heroes: CrawlHero.allCases.map(\.persona),
    // Every place, in menu order. The first is the default: where the crew stands when nobody's home is known. A full
    // universe has about 20.
    places: [.crawlSafeRoom, .crawlSeattle, .crawlCorridor, .crawlGuild, .crawlHoard, .crawlGym, .crawlPersonal,
             .crawlDesperado, .crawlParade, .crawlOverCity, .crawlCircus, .crawlTangle, .crawlHumpTown, .crawlCastle,
             .crawlHunting, .crawlStudio, .crawlDeathWatch, .crawlHavana, .crawlLarracos, .crawlTemple],
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
    static let crawlCorridor = Location("crawlCorridor")
    static let crawlGuild = Location("crawlGuild")
    static let crawlHoard = Location("crawlHoard")
    static let crawlGym = Location("crawlGym")
    static let crawlPersonal = Location("crawlPersonal")
    static let crawlDesperado = Location("crawlDesperado")
    static let crawlStudio = Location("crawlStudio")
    static let crawlSeattle = Location("crawlSeattle")
    static let crawlParade = Location("crawlParade")
    static let crawlOverCity = Location("crawlOverCity")
    static let crawlCircus = Location("crawlCircus")
    static let crawlTangle = Location("crawlTangle")
    static let crawlHumpTown = Location("crawlHumpTown")
    static let crawlCastle = Location("crawlCastle")
    static let crawlHunting = Location("crawlHunting")
    static let crawlDeathWatch = Location("crawlDeathWatch")
    static let crawlHavana = Location("crawlHavana")
    static let crawlLarracos = Location("crawlLarracos")
    static let crawlTemple = Location("crawlTemple")
}

/// Every place's drawing, from the Places/CrawlScenes*.swift files (a few places a file). Add each new file to the
/// list.
let crawlPlaces: [Location: Place] = [crawlScenes1, crawlScenes2, crawlScenes3, crawlScenes4, crawlScenes5,
                                         crawlScenes6]
    .reduce([:]) { $0.merging($1) { a, _ in a } }
