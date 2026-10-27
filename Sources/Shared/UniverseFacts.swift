import Foundation

/// What every part of Clawd Clash needs to know about a universe: plain numbers, no drawing. Each universe's
/// `<Prefix>Facts.swift` holds its cast's enums and one of these; the hook compiles those files too, so it can cast
/// characters and handle compaction without a single sprite.
///
/// Ids here are local: villains `0..<100`, heroes `StatusStore.heroBase…` (HEM last). `Universe` adds its `base`.
struct UniverseFacts {
    /// Where heroes' local ids start: villains `0..<heroBase`, heroes `heroBase…`.
    static let heroBase = StatusStore.heroBase

    /// From the enums (`allCases.count`), never typed by hand: agent-only characters included.
    let villainCount: Int
    /// From the enums: HEM included, always last.
    let heroCount: Int
    /// Small fry that only ever turn up as agents, never leading a session.
    var agentOnly: Set<Int> = []
    /// With another AI running, Claude Code's side: false = heroes, true = villains, nil = whoever came first keeps
    /// the side it mostly has (Star Clawds, as Clawd Wars always did).
    var claudeSide: Bool? = false
    /// Characters that never lead two sessions back to back (Vader and Kylo; Angstel and Spyke).
    var rivals: Set<Int> = []
    /// One character in two guises: never on screen together.
    var guises: [Set<Int>] = []
    /// Characters who only ever appear at home, as id → place key.
    var homebound: [Int: String] = [:]
    /// What happens to a session's leader when its context is compacted.
    var compaction: UniverseCompaction? = nil
    /// Who now and then steps forward with a short lesson when their session finishes (Stop), as id → the chance on
    /// each finish; never twice within half an hour for the same session (`StatusStore`'s Stop, the module's `morals`).
    var morals: [Int: Double] = [:]
}

/// What a compaction does to a session's leader (`StatusStore`'s PreCompact).
enum UniverseCompaction {
    /// Doctor Clawd: the next face in `order`, same session.
    case regenerate(order: [Int])
    /// The Clawd Files, Stevie Clawdberg, Clawd Slayer: `who` are gone for a moment and come back the same.
    case away(who: Set<Int>)
    /// Clawds of the Universe: a leader who is one of a pair of `guises` turns into the other (and back again at the
    /// next compaction), unless the other is already on stage; then only the flash plays.
    case transform
}

/// A universe as the registry lists it: its constant, key and title, and its facts. Each universe's facts file has one
/// (`<Prefix>Facts.entry`); `registeredUniverses` lists them all, generated from the folders by Tools/universes.sh.
struct UniverseEntry {
    let universe: Universe
    /// Stored in settings and the screen-saver feed: never changes.
    let key: String
    let title: String
    let facts: UniverseFacts
}
