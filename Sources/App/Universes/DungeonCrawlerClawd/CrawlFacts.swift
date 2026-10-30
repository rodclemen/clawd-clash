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

enum CrawlHero: Int, CaseIterable {
    // The Royal Court
    case carl, donut, mongo
    case katia, mordecai, samantha, prepotente, louis
    // Meadow Lark
    case elle, imani, brandon, chris
    // Crawlers
    case bautista, florin, ifechi
    // The Desperado Club and its dancers
    case sledge, bomo, doctorBones, splashZone
    // NPC allies
    case rory, lorelai
    // The show's side
    case odette, zev
    case hem   // always last (`Universe.hem`)
}

enum CrawlVillain: Int, CaseIterable {
    // Bosses
    case maestro, hoarder, juicer, krakaren, ballOfSwine, ralph
    // Player killers and rivals
    case lucia, frankQ, maggieMy, hekla
    // The Syndicate
    case chaco, cascadia
    // Gods
    case emberus
}

extension Universe {
    /// The universe's constant: `Cast(universe: .crawl, …)` inside this folder. Code outside the folder never names
    /// it. The number is the one NUMBERS gives you, for good.
    static let crawl = Universe(number: 12)
}

enum CrawlFacts {
    static let entry = UniverseEntry(universe: .crawl, key: "crawl", title: "Dungeon Crawler Clawd", facts: facts)
    static let facts = UniverseFacts(
        // The counts come from the enums, never typed by hand.
        villainCount: CrawlVillain.allCases.count, heroCount: CrawlHero.allCases.count,
        // Claude plays the crawlers.
        claudeSide: false,
        // The Hoarder never leaves her lair.
        homebound: [CrawlVillain.hoarder.rawValue: "crawlHoard"]
        // Everything below is optional: uncomment what your universe needs. Ids here are local: a villain's is its
        // rawValue, a hero's `UniverseFacts.heroBase + rawValue`.
        //
        // Small fry that only ever turn up as agents, never leading a session (a pet, a minion):
        //   , agentOnly: [CrawlVillain.minion.rawValue, UniverseFacts.heroBase + CrawlHero.pet.rawValue]
        // With another AI running, which side Claude Code plays: false (the default) the heroes, true the villains,
        // nil whoever came first keeps the side it mostly has (Star Clawds):
        //   , claudeSide: false
        // Two who never lead sessions back to back (Vader and Kylo; Angstel and Spyke):
        //   , rivals: [UniverseFacts.heroBase + CrawlHero.a.rawValue, UniverseFacts.heroBase + CrawlHero.b.rawValue]
        // One character in two guises, never on screen together (Clawd of the Rings' Strider and Aragorn):
        //   , guises: [[UniverseFacts.heroBase + CrawlHero.a.rawValue, UniverseFacts.heroBase + CrawlHero.b.rawValue]]
        // Someone who only ever appears at home, as id and place key (Smaug the Stashed, at the Lonely Mountain):
        //   , homebound: [CrawlVillain.dragon.rawValue: "crawlLair"]
        // What a compaction does to a session's leader, one of three kinds (the module draws it: `regeneration`,
        // `compactionLook` or `transformation` in CrawlUniverse.swift):
        //   , compaction: .regenerate(order: [...])   // Doctor Clawd: the next face in the list, same session
        //   , compaction: .away(who: [...])           // The Clawd Files: gone for a moment, back the same
        //   , compaction: .transform                  // Clawds of the Universe: into the other of its `guises`, and back
        // Who now and then gives a lesson when their session finishes, as id and the chance each time (the lines are
        // the module's `morals`):
        //   , morals: [UniverseFacts.heroBase + CrawlHero.a.rawValue: 0.125]
    )
}
