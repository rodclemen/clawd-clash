import Foundation

// The universe's facts: its cast's enums and what the hook, the app and the screen saver need to know about it. Plain
// data, no drawing: the hook compiles this file too (and nothing else in the folder), so keep it to enums and numbers.
//
// Ids: a character's id is the universe's number × 1000 plus its local id: villains 0…99 by `<Prefix>Villain`'s order,
// heroes 100… by `<Prefix>Hero`'s. Ids are saved in running sessions, the hook's state file and the screen-saver feed,
// so the enums are append-only:
//   - only ever add cases at the end;
//   - never reorder, rename into another character or remove a case once it's on `main`;
//   - HEM is always the last hero (`Universe.hem` counts on it), so new heroes go just before him.
// Group the cases with a comment line per group, as the other universes do. A full universe has 80 to 110 characters.

enum EterniaHero: Int, CaseIterable {
    // The Masters of the Universe
    case heClawd, orkko, princeAddam, battleKat, cringer, teelah, manAtClawds, sorceress, kingRandor, queenMarlena
    case stratos, ramClawd, manEClawds, mekaneck, buzzOff, clawdfist
    // She-Clawd and the Great Rebellion
    case sheClawd, adorra, spirit, swiftWind, bow, glimmer, madameRazz, kowl
    // The rest of the Masters
    case roboto, mossClawd, syClawdne, snoutSpout, zodac, granamyr
    // The rest of the Great Rebellion
    case queenAngella, clawdstaspella, frosta, seaHawk, mermista, perfuma, peekablue, netossa, flutterina, lightHope
    case stonedar
    // Small fry, agents only: the Kon-Seal who hides
    case looKee
    // From the 1987 film: the Thenorian locksmith with the Cosmic Key
    case gwildor
    case hem   // always last (`Universe.hem`)
}

enum EterniaVillain: Int, CaseIterable {
    // Skeleclawd and the Evil Warriors
    case skeleclawd, evilLynn, beastClawd, trapClawd, triClawdps, merClawd, kobraKhan, clawdful
    // Hordakk and the Evil Horde
    case hordakk, shadowWeaver, katra, scorpia, mantenna
    // Small fry, agents only: Hordakk's spy, his foot soldiers, Skeleclawd's bird
    case imp, hordeTrooper, screeech
    // The rest of the Evil Warriors
    case webstor, whiplash, spikor, twoBad, faker, panthor, stinkor
    // Other foes of Eternia
    case kingHiss, countMarzo, shokoti
    // The rest of the Evil Horde
    case leach, grizzlor, modulok, multiBot, entrapta, octavia, rattlor, tungLashor, vultak, hordePrime
    // From the bench: Skeleclawd's martial artist
    case jitsu
    // From the 1987 film: Skeleclawd's mercenaries, and his foot soldiers (agents only)
    case blade, saurod, karg, darkTrooper
}

extension Universe {
    /// The universe's constant: `Cast(universe: .eternia, …)` inside this folder. Code outside the folder never names
    /// it. The number is the one NUMBERS gives you, for good.
    static let eternia = Universe(number: 11)
}

enum EterniaFacts {
    static let entry = UniverseEntry(universe: .eternia, key: "eternia", title: "Clawds of the Universe", facts: facts)
    static let facts = UniverseFacts(
        // The counts come from the enums, never typed by hand.
        villainCount: EterniaVillain.allCases.count, heroCount: EterniaHero.allCases.count,
        agentOnly: Set([EterniaVillain.imp, .hordeTrooper, .screeech, .darkTrooper].map(\.rawValue)
                       + [UniverseFacts.heroBase + EterniaHero.looKee.rawValue]),
        // The two big bads, old pupil and old teacher: two cackling skull faces in a row would wear thin.
        rivals: [EterniaVillain.skeleclawd.rawValue, EterniaVillain.hordakk.rawValue],
        // The secret identities: one hero in two guises, never on stage together (compaction swaps them, phase 4).
        guises: [(EterniaHero.princeAddam, EterniaHero.heClawd), (.cringer, .battleKat), (.adorra, .sheClawd),
                 (.spirit, .swiftWind)].map { [UniverseFacts.heroBase + $0.0.rawValue, UniverseFacts.heroBase + $0.1.rawValue] as Set },
        // "By the power of Greyskull!": when a session led by one of a pair compacts, they change into the other, and
        // back at the next (EterniaPower.swift draws it).
        compaction: .transform,
        // The moral of the story: now and then, when a hero's session finishes, they step forward with a lesson, about
        // one finish in eight; Orkko, the Sorceress and Man-At-Clawds, who gave the most in the show, one in four.
        // Villains don't give lessons (EterniaPower.swift has the lines).
        morals: Dictionary(uniqueKeysWithValues: EterniaHero.allCases.filter { $0 != .hem && $0 != .looKee }.map { h in
            (UniverseFacts.heroBase + h.rawValue, [EterniaHero.orkko, .sorceress, .manAtClawds].contains(h) ? 0.25 : 0.125)
        })
        // Everything below is optional: uncomment what your universe needs. Ids here are local: a villain's is its
        // rawValue, a hero's `UniverseFacts.heroBase + rawValue`.
        //
        // Small fry that only ever turn up as agents, never leading a session (a pet, a minion):
        //   , agentOnly: [EterniaVillain.minion.rawValue, UniverseFacts.heroBase + EterniaHero.pet.rawValue]
        // With another AI running, which side Claude Code plays: false (the default) the heroes, true the villains,
        // nil whoever came first keeps the side it mostly has (Star Clawds):
        //   , claudeSide: false
        // Two who never lead sessions back to back (Vader and Kylo; Angstel and Spyke):
        //   , rivals: [UniverseFacts.heroBase + EterniaHero.a.rawValue, UniverseFacts.heroBase + EterniaHero.b.rawValue]
        // One character in two guises, never on screen together (Clawd of the Rings' Strider and Aragorn):
        //   , guises: [[UniverseFacts.heroBase + EterniaHero.a.rawValue, UniverseFacts.heroBase + EterniaHero.b.rawValue]]
        // Someone who only ever appears at home, as id and place key (Smaug the Stashed, at the Lonely Mountain):
        //   , homebound: [EterniaVillain.dragon.rawValue: "eterniaLair"]
    )
}
