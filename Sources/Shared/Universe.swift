import Foundation

/// A universe Clawd Clash can show. One at a time, except in Clawd Royale (`Roster`), where a scene mixes all of them.
/// A universe can be built before it's released (`isReleased`; every one is today): only the tools see an unreleased one.
///
/// Cast ids are stored in the status file and the screen-saver feed: `universe.base + local`, where local ids are
/// villains `0..<100` and heroes `100…`. Star Wars keeps Clawd Wars' ids (base 0), so its saved state carries over.
struct Universe: Hashable, Comparable, CaseIterable, Codable, RawRepresentable {
    /// Its permanent number: every id it ever gave out is `number × 1000 + local id`. Never reused.
    let rawValue: Int

    /// Only universes that are registered (`registeredUniverses`).
    init?(rawValue: Int) {
        guard Universe.entries[rawValue] != nil else { return nil }
        self.rawValue = rawValue
    }
    /// For a universe's own constant (`static let slayer = Universe(number: 7)`, in its facts file).
    init(number: Int) { rawValue = number }
    init?(key: String) { guard let e = registeredUniverses.first(where: { $0.key == key }) else { return nil }; self = e.universe }

    /// Every registered universe, in number order. Numbers from 900 up are the template's, only ever in a TEMPLATE=1
    /// build (`-D CLAWD_TEMPLATE`) and never in a release (`-D CLAWD_RELEASE`): the app, the hook and the screen saver
    /// all stop here rather than cast or show one.
    static let allCases: [Universe] = {
        let all = registeredUniverses.map(\.universe).sorted()
        #if CLAWD_RELEASE || !CLAWD_TEMPLATE
        if let u = all.first(where: { $0.rawValue >= 900 }) { fatalError("universe \(u.rawValue) is the template's number, never in this build") }
        #endif
        return all
    }()
    /// The lowest-numbered universe, for when none is known (Star Clawds).
    static var fallback: Universe { allCases[0] }
    private static let entries: [Int: UniverseEntry] = Dictionary(uniqueKeysWithValues: registeredUniverses.map { ($0.universe.rawValue, $0) })
    private var entry: UniverseEntry { Universe.entries[rawValue]! }

    static func < (a: Universe, b: Universe) -> Bool { a.rawValue < b.rawValue }

    /// Stored as its number alone, as it always was.
    init(from decoder: Decoder) throws {
        let n = try decoder.singleValueContainer().decode(Int.self)
        guard let u = Universe(rawValue: n) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "no universe \(n)"))
        }
        self = u
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    var key: String { entry.key }
    var title: String { entry.title }
    var base: Int { rawValue * 1000 }

    /// What the hook, the app and the screen saver know about it: its `<Prefix>Facts.swift`.
    var facts: UniverseFacts { entry.facts }

    var villainCount: Int { facts.villainCount }
    var heroCount: Int { facts.heroCount }

    /// HEM: the same rare face in every universe, last of the heroes. He's never in the regular pools (`lightCast`);
    /// a new session or agent turns out to be him now and then (`hemOdds`), and he stays himself across universes.
    var hem: Int { base + StatusStore.heroBase + heroCount - 1 }
    func isHem(_ id: Int) -> Bool { id % 1000 == StatusStore.heroBase + heroCount - 1 }
    /// The chance a new session's character, or a new agent's, is HEM.
    static let hemOdds = (session: 1.0 / 50, agent: 1.0 / 150)

    /// Small fry that only ever turn up as agents, never leading a session (global ids).
    var agentOnly: Set<Int> { Set(facts.agentOnly.map { base + $0 }) }

    /// With another AI running, Claude Code's side: false = heroes, true = villains, nil = whoever came first keeps
    /// the side it mostly has (Star Wars, as Clawd Wars always did).
    var claudeSide: Bool? { facts.claudeSide }

    /// Characters that never lead two sessions back to back (Vader and Kylo; Angstel and Spyke), as global ids.
    var rivals: Set<Int> { Set(facts.rivals.map { base + $0 }) }

    /// One character in two guises, as global ids: never on screen together (the casting and `StatusStore.snapshot`
    /// keep to it). Clawd of the Rings has them (`RingsFacts`).
    var guises: [Set<Int>] { facts.guises.map { Set($0.map { base + $0 }) } }

    /// Characters who only ever appear at home, as global id → place key: anywhere else, and on the desktop (no place),
    /// they're shown as someone else (`Roster.recast`). Clawd of the Rings' Smaug the Stashed (`RingsFacts`).
    var homebound: [Int: String] { Dictionary(uniqueKeysWithValues: facts.homebound.map { (base + $0.key, $0.value) }) }

    /// Who's gone for a moment when their session is compacted, the same face when they're back, as global ids
    /// (`StatusStore`'s PreCompact): The Clawd Files' FBI agents (`FilesMissingTime`), Stevie Clawdberg's time travellers
    /// (`ClawdbergOutaTime`), Clawd Slayer's eight from "Tabula Rasa" (`SlayerTabulaRasa`).
    var abductees: Set<Int> {
        if case .away(let who)? = facts.compaction { return Set(who.map { base + $0 }) }
        return []
    }

    /// Doctor Clawd: the Doctors in order, as global ids. When a session's context is compacted, its Doctor
    /// regenerates into the next one (`StatusStore`'s PreCompact); nobody else changes.
    var regenerations: [Int] {
        if case .regenerate(let order)? = facts.compaction { return order.map { base + $0 } }
        return []
    }

    /// Whether a leader with another guise turns into it when its session is compacted (`StatusStore`'s PreCompact),
    /// and back at the next: Clawds of the Universe's Prince Addam and He-Clawd.
    var transforms: Bool {
        if case .transform? = facts.compaction { return true }
        return false
    }

    /// Who now and then gives a lesson when their session finishes, as global id → the chance on each finish
    /// (`StatusStore`'s Stop).
    var morals: [Int: Double] { Dictionary(uniqueKeysWithValues: facts.morals.map { (base + $0.key, $0.value) }) }

    /// Whether people can pick it: Settings, Random, Clawd Royale and the screen saver only offer released universes.
    /// An unreleased one exists for the tools (the workbench, the docs and promo renderers) until it's ready.
    var isReleased: Bool { true }
    /// Universes unchecked in Settings → Universes: left out of everything people pick from and of the hook's casting.
    /// Each process learns it its own way: the app from its defaults, the hook from the status file (`removed`), the
    /// screen saver from its feed.
    static var removed: Set<Universe> = []
    /// The universes people can pick, in menu order.
    static var offered: [Universe] { offered(without: removed) }
    /// The released universes but `removed`; never none (the app keeps at least one checked, so this is only a guard).
    static func offered(without removed: Set<Universe>) -> [Universe] {
        let released = allCases.filter(\.isReleased), kept = released.filter { !removed.contains($0) }
        return kept.isEmpty ? released : kept
    }
    /// A stored key, but only for a universe people can pick: an unreleased or removed one reads as unset.
    static func offered(key: String) -> Universe? { Universe(key: key).flatMap { offered.contains($0) ? $0 : nil } }

    var darkCast: [Int] { (0..<villainCount).map { base + $0 } }
    var lightCast: [Int] { (0..<heroCount - 1).map { base + StatusStore.heroBase + $0 } }   // all but HEM

    /// Which universe a cast id belongs to.
    static func of(_ id: Int) -> Universe { Universe(rawValue: id / 1000) ?? .fallback }
    static func isDark(_ id: Int) -> Bool { id % 1000 < StatusStore.heroBase }

    /// `id` as a member of this universe: itself if it already is one, otherwise the character in the same place on
    /// the same side here (the screen saver showing another universe, or the universe switched with sessions open).
    func adopt(_ id: Int) -> Int {
        guard Universe.of(id) != self else { return id }
        if Universe.of(id).isHem(id) { return hem }
        let local = id % 1000
        return Universe.isDark(id) ? base + local % villainCount
                                   : base + StatusStore.heroBase + (local - StatusStore.heroBase) % (heroCount - 1)
    }
}

/// Who can be cast and shown: one universe, or every one of them at once (Clawd Royale), each character as itself.
struct Roster {
    let universes: [Universe]

    init(_ universe: Universe, mixed: Bool, removed: Set<Universe> = Universe.removed) {
        universes = mixed ? Universe.offered(without: removed) : [universe]
    }

    var mixed: Bool { universes.count > 1 }
    var darkCast: [Int] { universes.flatMap(\.darkCast) }
    var lightCast: [Int] { universes.flatMap(\.lightCast) }
    var agentOnly: Set<Int> { universes.reduce(into: Set<Int>()) { $0.formUnion($1.agentOnly) } }
    var rivals: Set<Int> { universes.reduce(into: Set<Int>()) { $0.formUnion($1.rivals) } }
    var guises: [Set<Int>] { universes.flatMap(\.guises) }
    /// Who can't join while `shown` (ids as of this roster) are on screen: the other guises of anyone there.
    func ruledOut(by shown: Set<Int>) -> Set<Int> {
        guises.reduce(into: Set<Int>()) { out, g in if !g.isDisjoint(with: shown) { out.formUnion(g.subtracting(shown)) } }
    }
    var homebound: [Int: String] { universes.reduce(into: [:]) { $0.merge($1.homebound) { a, _ in a } } }
    /// Whether `id` may appear at `place` (a place key; nil: no place, the desktop): anyone but the homebound, and
    /// those only at home.
    func allowed(_ id: Int, at place: String?) -> Bool { homebound[id].map { $0 == place } ?? true }
    /// `ids` (as of this roster) as they may appear at `place`: anyone homebound elsewhere is shown as someone else on
    /// the same side, not on screen already and not the other guise of anyone there, picked by `seeds` (one per id) so
    /// it's the same someone on every refresh.
    func recast(_ ids: [Int], seeds: [String], at place: String?) -> [Int] {
        guard !homebound.isEmpty else { return ids }
        var out = ids
        for (i, id) in ids.enumerated() where !allowed(id, at: place) {
            let taken = Set(out), ruled = ruledOut(by: taken)
            let pool = (StatusStore.isDark(id) ? darkCast : lightCast)
                .filter { !taken.contains($0) && !ruled.contains($0) && !agentOnly.contains($0) && allowed($0, at: place) }
            if !pool.isEmpty { out[i] = pool[Int(StatusStore.stableHash(seeds[i]) % UInt64(pool.count))] }
        }
        return out
    }
    /// With another AI running, Claude Code's side (`Universe.claudeSide`); in Clawd Royale, the heroes.
    var claudeSide: Bool? { mixed ? false : universes[0].claudeSide }
    /// HEM, once for each universe here.
    var hems: Set<Int> { Set(universes.map(\.hem)) }
    /// Whether `id` is HEM, in whichever universe it's from.
    static func isHem(_ id: Int) -> Bool { Universe.of(id).isHem(id) }
    /// `id` as one of this roster: itself in Clawd Royale, otherwise the universe's `adopt`.
    func adopt(_ id: Int) -> Int { mixed ? id : universes[0].adopt(id) }
}
