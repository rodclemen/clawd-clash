import Foundation

// Superclawdtural: the Supernatural parody, all fifteen seasons. The Winclawdster brothers, their angel and the hunters
// against demons, angels gone bad, the Big Bads and the monsters of the week, in the Bunker, Singer Salvage, the
// Roadhouse, Hell, Heaven and on the open road in the Impala. The plan is clawd-plans' in-progress/superclawdtural.md;
// the folder follows clawdify_guide.md (one universe, one folder, nothing outside it).
//
// How it fits together:
//   universe.conf           the manifest: number 10, key hunters, prefix Hunt. The number and key are forever.
//   HuntFacts.swift         the cast's enums and plain facts. The hook compiles it too, so no drawing in it.
//   HuntUniverse.swift      this file: the one type the engine asks everything (`UniverseModule`).
//   HuntRoster.swift        personas, homes, nemeses, rides, the `Theme`, the place keys.
//   HuntHem.swift           HEM as a hunter.         HuntIcon.swift   the menu bar icon, a devil's trap.
//   HuntKit.swift           art helpers the Art files share: blades, flannel, wing shadows.
//   HuntTrips.swift         the trips between places, each drawn in its own Hunt…Trip.swift.
//   HuntRides.swift         Baby, the Impala.        HuntBackFromHell.swift   the compaction: dragged down, and back.
//   HuntHabits.swift        Jerk and Bitch, Clawdstiel's personal space.    HuntDrills.swift   the bespoke drills.
//   Art/                    the characters, 8 to 10 a file.    Places/   the places, a few a file.
//   Promo/HuntReel.swift    the trailer, compiled only into Tools/RenderPromo, never into the app.

/// The universe as the app sees it: everything the engine asks of it. Exactly one type in the folder conforms to
/// `UniverseModule`, and universe.conf's `entry` names it. The first five members must be written; the rest have
/// defaults (Sources/App/Universes/UniverseModule.swift), written out here so you can see each one and its rule.
struct HuntUniverse: UniverseModule {
    // MARK: Must be written

    /// The cast, the places in order, who lives where, arch-enemies, rides, the menu icon, the Status Symbols
    /// character: HuntRoster.swift.
    var theme: Theme { huntTheme }
    /// Every place's drawing, by key: the Places files, merged in HuntRoster.swift. Every key in `theme.places`
    /// has one.
    var places: [Location: Place] { huntPlaces }
    /// HEM's costume here: HuntHem.swift.
    var hem: HemCostume { huntHem }
    /// What Tools/Preview needs: the batch names for the art files (`huntHeroes1`, `huntVillains1`, one per
    /// file, in order; add each new file to its list) and the characters by enum case name.
    var preview: PreviewInfo {
        .of(.hunters, heroes: "huntHeroes", [huntHeroes1, huntHeroes2, huntHeroes3, huntHeroes4, huntHeroes5, huntHeroes6],
            villains: "huntVillains", [huntVillains1, huntVillains2, huntVillains3, huntVillains4, huntVillains5,
                                              huntVillains6, huntVillains7])
    }
    /// The trips between places (HuntTrips.swift): `pick` chooses the next, `every` lists one of each kind for
    /// Tools/Transitions. nil would leave plain edge and clock wipes, as only Star Clawds keeps.
    var transitions: TransitionSet? {
        TransitionSet(pick: { last, cast, _, to in HuntTrip.pick(after: (last as? HuntTrip)?.kind, cast: cast, to: to) },
                      every: { _, _ in ShownTrip.all(HuntWipe.allCases) { HuntTrip(kind: $0) } })
    }

    // MARK: Have defaults

    /// Five sample prompts for the Playground's cards, in the universe's voice.
    var playgroundPrompts: [String] {
        ["salt the doorways before the build runs", "find out what's haunting the test suite and burn its bones",
         "check the Bunker's library for this stack trace", "gas up the Impala and drive the deploy to Kansas",
         "paint a devil's trap round the flaky test"]
    }
    /// Who floats cross-legged in meditation among their drills: `.casters` (magic users, the default), `.never`,
    /// `.castersAndSabers`, or `.heroes([...])` by hero index. `stones: true` floats bits of rock round them.
    /// Nobody: hunters, angels and demons don't float cross-legged, and Rowena is the only witch.
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
    func compactionLook(k: Double, cast: Cast) -> CompactionLook? { HuntBackFromHell(k: k) }
    /// What a regeneration looks like (with `compaction: .regenerate` in the facts), drawn over the character already
    /// in its next face: Doctor Clawd's.
    var regeneration: (length: Double, draw: (_ c: PixelCanvas, _ k: Double, _ t: Double) -> Void)? { nil }
    /// Little things certain characters do on stage, whoever else is about: move only while nobody looks
    /// (`unseenMovers`), a jump and a shiver (`jitter`), something drawn beside them (`prop`), a word to someone nearby
    /// (`remark`), nobody has a voice while they're there (`hushers`), their signature once a fight is over
    /// (`afterDuel`). See `StageQuirks`.
    var quirks: StageQuirks { huntQuirks }
    /// Pairs who face off and now and then end with one bolt getting through (Han shoots first): a `ShootOut` with
    /// the shooter, the target and their lines.
    var shootOuts: [ShootOut] { [] }
    /// Every ride, for Preview's sheet (who takes which is `theme.ride`).
    var rides: [Ride] { [.huntImpala] }
    /// Characters' own practice sets, done now and then among the general drills (`BespokeDrill`).
    var drills: [Cast: BespokeDrill] { huntBespokeDrills }
    /// Places where, now and then, the whole scene turns over in the window and the screen saver (`SceneFlip`); nil:
    /// never.
    var sceneFlip: SceneFlip? { nil }
    /// The README's pictures besides the roster and places (Tools/RenderDocs): the desktop line-up, left to right,
    /// pairs fighting each other and the odd one cheering, and the social preview's title, line and cast.
    var docs: DocsInfo {
        DocsInfo(lineup: [
            LineupSlot.pair(.villain(HuntVillain.clawdley), true, "", 30, .hero(HuntHero.deanWinclawdster), true, "", 98),
            LineupSlot.pair(.hero(HuntHero.samWinclawdster), false, "Check git history", 132,
                            .villain(HuntVillain.ruby), false, "Write changelog", 182),
            LineupSlot.pair(.hero(HuntHero.clawdstiel), false, "Plan the refactor", 214,
                            .villain(HuntVillain.zachariah), false, "Review Overlay.swift", 252),
            LineupSlot.pair(.hero(HuntHero.bobbyClawdsinger), true, "", 282, .villain(HuntVillain.abaddon), true, "", 352),
            [LineupSlot(who: .hero(HuntHero.jackKlyne), leader: false, label: "Run the test suite", x: 388, facing: 1,
                        role: .cheer)],
        ], social: (title: Universe.hunters.title.uppercased(), subtitle: "Saving people. Hunting bugs. The family business.",
                    cast: [.hero(HuntHero.deanWinclawdster), .hero(HuntHero.samWinclawdster), .hero(HuntHero.clawdstiel),
                           .hero(HuntHero.bobbyClawdsinger), .villain(HuntVillain.clawdley), .villain(HuntVillain.lucifer),
                           .villain(HuntVillain.abaddon), .villain(HuntVillain.azazel)]))
    }
}
