import Foundation

// Dungeon Crawler Clawd: a parody of Dungeon Crawler Carl, all eight books. The Earth's buildings sink into the
// dungeon, and the crawlers fight their way down floor by floor on a galactic game show: Carl, Princess Donut and
// their Royal Court against the bosses, the player killers, the showrunners and the gods. The plan, with the cast,
// places, mechanics and transitions, is in-progress/dungeon-crawler-clawd.md in the clawd-plans repo.
//
// The folder follows the template's layout (clawdify_guide.md, "Your folder"): CrawlFacts (enums and facts),
// CrawlRoster (personas, homes, nemeses, the theme, the place keys), CrawlHem, CrawlIcon, CrawlWipes, CrawlKit
// (drawing helpers several files share), Art/, Places/ and Promo/.

/// The universe as the app sees it: everything the engine asks of it. Exactly one type in the folder conforms to
/// `UniverseModule`, and universe.conf's `entry` names it. The first five members must be written; the rest have
/// defaults (Sources/App/Universes/UniverseModule.swift), written out here so you can see each one and its rule.
struct CrawlUniverse: UniverseModule {
    // MARK: Must be written

    /// The cast, the places in order, who lives where, arch-enemies, rides, the menu icon, the Status Symbols
    /// character: CrawlRoster.swift.
    var theme: Theme { crawlTheme }
    /// Every place's drawing, by key: the Places files, merged in CrawlRoster.swift. Every key in `theme.places`
    /// has one.
    var places: [Location: Place] { crawlPlaces }
    /// HEM's costume here: CrawlHem.swift.
    var hem: HemCostume { crawlHem }
    /// What Tools/Preview needs: the batch names for the art files (`crawlHeroes1`, `crawlVillains1`, one per
    /// file, in order; add each new file to its list) and the characters by enum case name.
    var preview: PreviewInfo {
        .of(.crawl, heroes: "crawlHeroes", [crawlHeroes1, crawlHeroes2, crawlHeroes3, crawlHeroes4, crawlHeroes5, crawlHeroes6],
            villains: "crawlVillains", [crawlVillains1, crawlVillains2, crawlVillains3, crawlVillains4, crawlVillains5,
                                        crawlVillains6, crawlVillains7])
    }
    /// The trips between places (CrawlWipes.swift): `pick` chooses the next, `every` lists one of each kind for
    /// Tools/Transitions. nil would leave plain edge and clock wipes, as only Star Clawds keeps.
    var transitions: TransitionSet? {
        TransitionSet(pick: { last, cast, _, to in CrawlTrip.pick(after: (last as? CrawlTrip)?.kind, cast: cast, to: to) },
                      every: { _, _ in ShownTrip.all(CrawlWipe.allCases) { CrawlTrip(kind: $0) } })
    }

    // MARK: Have defaults

    /// Five sample prompts for the Playground's cards, in the universe's voice.
    var playgroundPrompts: [String] {
        ["Open the loot box the CI left us.", "Find the stairwell before the build collapses.",
         "Ping the map for failing tests.", "Get Mordecai to brew something for this stack trace.",
         "Ask the System AI why it gave this PR a bronze box."]
    }
    /// Who floats cross-legged in meditation among their drills: `.casters` (magic users, the default), `.never`,
    /// `.castersAndSabers`, or `.heroes([...])` by hero index. `stones: true` floats bits of rock round them.
    var meditation: Meditation { Meditation(who: .never) }
    /// How guns are drawn: `.modern`. (`.classic` is Clawd Wars' way, Star Clawds only.)
    var poseStyle: PoseStyle { .modern }
    /// Who has the moonwalk among their idle habits.
    var moonwalkers: Set<Cast> { [] }
    /// The web line's colour for characters with `motion: .swing`; nil: the usual near-white.
    var swingLine: Px? { nil }
    /// A caption that types the place's name in when the scene changes (The Clawd Files'); nil: the usual name.
    var placeCaption: PlaceCaption? { nil }
    /// What a compacted session's leader looks like while it's away (with `compaction: .away` in the facts), `k` (0…1)
    /// through it: The Clawd Files' abduction beam, Stevie Clawdberg's 88 mph. nil: nothing to see.
    func compactionLook(k: Double, cast: Cast) -> CompactionLook? { nil }
    /// What a regeneration looks like (with `compaction: .regenerate` in the facts), drawn over the character already
    /// in its next face: Doctor Clawd's.
    var regeneration: (length: Double, draw: (_ c: PixelCanvas, _ k: Double, _ t: Double) -> Void)? { nil }
    /// What a change into a leader's other guise looks like (with `compaction: .transform` in the facts), drawn over the
    /// character in its new guise, and what it says: Clawds of the Universe's "By the power of Greyskull!".
    var transformation: Transformation? { nil }
    /// The lessons the leaders in the facts' `morals` give, now and then, when their session finishes.
    var morals: [String] { [] }
    /// Little things certain characters do on stage, whoever else is about: move only while nobody looks
    /// (`unseenMovers`), a jump and a shiver (`jitter`), something drawn beside them (`prop`), a word to someone nearby
    /// (`remark`), nobody has a voice while they're there (`hushers`), their signature once a fight is over
    /// (`afterDuel`). See `StageQuirks`.
    var quirks: StageQuirks { StageQuirks() }
    /// Pairs who face off and now and then end with one bolt getting through (Han shoots first): a `ShootOut` with
    /// the shooter, the target and their lines.
    var shootOuts: [ShootOut] { [] }
    /// Every ride, for Preview's sheet (who takes which is `theme.ride`).
    var rides: [Ride] { [] }
    /// Characters' own practice sets, done now and then among the general drills (`BespokeDrill`).
    var drills: [Cast: BespokeDrill] { [:] }
    /// Places where, now and then, the whole scene turns over in the window and the screen saver (`SceneFlip`); nil:
    /// never.
    var sceneFlip: SceneFlip? { nil }
    /// The README's pictures besides the roster and places (Tools/RenderDocs): the desktop line-up, left to right,
    /// pairs fighting each other and the odd one cheering, and the social preview's title, line and cast.
    var docs: DocsInfo {
        DocsInfo(lineup: [
            LineupSlot.pair(.villain(CrawlVillain.maestro), true, "", 60, .hero(CrawlHero.carl), true, "", 150),
            [LineupSlot(who: .hero(CrawlHero.donut), leader: true, label: "", x: 230, facing: 1, role: .cheer)],
            [LineupSlot(who: .hero(CrawlHero.mongo), leader: false, label: "Open the loot box", x: 300, facing: -1, role: .cheer)],
        ], social: (title: Universe.crawl.title.uppercased(), subtitle: "Your AI sessions as a pixel-art dungeon crawl on your desktop",
                    cast: [.hero(CrawlHero.carl), .hero(CrawlHero.donut), .hero(CrawlHero.mongo), .villain(CrawlVillain.maestro)]))
    }
}
