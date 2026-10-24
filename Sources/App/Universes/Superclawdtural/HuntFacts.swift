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

enum HuntHero: Int, CaseIterable {
    // Team Free Will
    case deanWinclawdster, samWinclawdster, clawdstiel, jackKlyne
    // The Winclawdster family
    case maryWinclawdster, johnWinclawdster, henryWinclawdster
    // Hunters
    case bobbyClawdsinger, ellenHarvell, joHarvell, charlieClawdbury
    // Friends and allies
    case ash, kevinTran, gabriel, rowenaMacClawd
    // More hunters
    case rufusTurner, garthFitzclawd, jodyMills, donnaHanscum, claireNovak, alexJones, eileenLeahy
    case edZedmore, harrySpangler, frankDevereaux
    // More friends and allies
    case bennyLafitte, missouriMosley, pamelaBarnes, beckyRosen, victorHenriksen, mickDavies, tessa, balthaclawds
    // Agent-only
    case miracle
    case hem   // always last (`Universe.hem`)
}

enum HuntVillain: Int, CaseIterable {
    // Demons
    case clawdley, azazel, megMasters, ruby, lilith, alastair, abaddon, cain, asmodeus, dagon, ramiel, demonDean
    case crossroadsDemon
    // Angels
    case lucifer, michael, zachariah, metatron
    // Big Bads
    case dickRoman, chuck, war, famine, pestilence, death
    // More angels
    case uriel, raphael, naomi, gadreel
    // More Big Bads
    case eve, amara, billie
    // Human villains
    case toniBevell, arthurKetch, gordonWalker, belaTalbot
    // Monsters of the week
    case alphaVampire, bloodyMary, womanInWhite, hookman, shapeshifter, djinn, clown, scarecrow
    // Agent-only small fry
    case hellhound, leviathanBlob, demonSmoke
}

extension Universe {
    /// The universe's constant: `Cast(universe: .hunters, …)` inside this folder. Code outside the folder never names
    /// it. The number is the one NUMBERS gives you, for good.
    static let hunters = Universe(number: 10)
}

enum HuntFacts {
    static let entry = UniverseEntry(universe: .hunters, key: "hunters", title: "Superclawdtural", facts: facts)
    static let facts = UniverseFacts(
        // The counts come from the enums, never typed by hand.
        villainCount: HuntVillain.allCases.count, heroCount: HuntHero.allCases.count,
        // Miracle the dog, a hellhound, a Leviathan blob and a wisp of demon smoke only ever turn up as agents.
        agentOnly: [HuntVillain.hellhound.rawValue, HuntVillain.leviathanBlob.rawValue, HuntVillain.demonSmoke.rawValue,
                    UniverseFacts.heroBase + HuntHero.miracle.rawValue],
        // Death and Billie never lead two sessions back to back: two Deaths in a row.
        rivals: [HuntVillain.death.rawValue, HuntVillain.billie.rawValue],
        // The Winclawdsters and the ones who keep coming back (Dean, Sam, Clawdstiel, Bobby and Jack): a compaction
        // drags them down to Hell for a moment, and they punch their way back out of the ground (`HuntBackFromHell`).
        compaction: .away(who: Set([HuntHero.deanWinclawdster, .samWinclawdster, .clawdstiel, .bobbyClawdsinger, .jackKlyne]
                                    .map { UniverseFacts.heroBase + $0.rawValue }))
        // Everything below is optional: uncomment what your universe needs. Ids here are local: a villain's is its
        // rawValue, a hero's `UniverseFacts.heroBase + rawValue`.
        //
        // Small fry that only ever turn up as agents, never leading a session (a pet, a minion):
        //   , agentOnly: [HuntVillain.minion.rawValue, UniverseFacts.heroBase + HuntHero.pet.rawValue]
        // With another AI running, which side Claude Code plays: false (the default) the heroes, true the villains,
        // nil whoever came first keeps the side it mostly has (Star Clawds):
        //   , claudeSide: false
        // Two who never lead sessions back to back (Vader and Kylo; Angstel and Spyke):
        //   , rivals: [UniverseFacts.heroBase + HuntHero.a.rawValue, UniverseFacts.heroBase + HuntHero.b.rawValue]
        // One character in two guises, never on screen together (Clawd of the Rings' Strider and Aragorn):
        //   , guises: [[UniverseFacts.heroBase + HuntHero.a.rawValue, UniverseFacts.heroBase + HuntHero.b.rawValue]]
        // Someone who only ever appears at home, as id and place key (Smaug the Stashed, at the Lonely Mountain):
        //   , homebound: [HuntVillain.dragon.rawValue: "huntLair"]
        // What a compaction does to a session's leader, one of two kinds (the module draws it: `compactionLook` or
        // `regeneration` in HuntUniverse.swift):
        //   , compaction: .regenerate(order: [...])   // Doctor Clawd: the next face in the list, same session
        //   , compaction: .away(who: [...])           // The Clawd Files: gone for a moment, back the same
    )
}
