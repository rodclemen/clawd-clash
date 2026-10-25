import Foundation

// START HERE.
//
// This folder is a whole universe, as small as one can be: one hero ("Sample Hero"), HEM, one villain ("Sample
// Villain"), one place ("Sample Meadow"), one kind of trip and a trailer with the shared shots. It's the template every
// new universe starts from: it shows how each part is done, with the rules written next to the code they apply to. It's
// for day one only. From there you grow it into a full universe, 80 to 110 characters, about 20 places, 8 to 15
// trips, a ride and the franchise's mechanics if it has any, following clawdify_guide.md the whole way.
//
// How it fits together:
//   universe.conf           the manifest: number, key, title, prefix, entry, reel. The number and key come from
//                           Sources/App/Universes/NUMBERS and are forever (they're in every saved id).
//   <Prefix>Facts.swift     the cast's enums and plain facts. The hook compiles it too, so no drawing in it.
//   <Prefix>Universe.swift  this file: the one type the engine asks everything (`UniverseModule`).
//   <Prefix>Roster.swift    personas, homes, nemeses, rides, the `Theme`, the place keys.
//   <Prefix>Hem.swift       HEM's costume here.        <Prefix>Icon.swift   the menu bar icon.
//   <Prefix>Wipes.swift     the trips between places.
//   Art/                    the characters, 8 to 10 a file.    Places/   the places, a few a file.
//   Promo/<Prefix>Reel.swift  the trailer, compiled only into Tools/RenderPromo, never into the app.
//
// To start a universe of your own:
//   1. Ask the owner for a number: a `reserved` line in Sources/App/Universes/NUMBERS, with your key and folder.
//   2. Tools/new-universe.sh <Folder> <Prefix> <key> "<Title>" <number>
//      It copies this folder, renames the files, the types, the place keys and the prefix, fills in the manifest and
//      takes out the first and last lines that keep the template out of normal builds. (Copying by hand works too:
//      Tools/universes.sh stops with a plain message at anything left over.)
//   3. Build and run the real app, with every universe and yours: ./build.sh --no-install. Look at your work with
//      Tools/Preview (sheets of characters and places) and Tools/Transitions, and in the window, the screen saver and
//      Clawd Royale.
//   4. Tools/CheckUniverse/check.sh <Folder> before you hand it off: it checks names, counts, homes, ids, that nothing
//      outside your folder names it, and renders its sheets.
//   5. Hand off only the folder. Nothing else in the repo needs to change.
// To try the template itself: TEMPLATE=1 ./build.sh (it runs from build/, leaves your hooks and settings alone and
// never saves anything about it), or Tools/CheckUniverse/check.sh --template for its sheets.
//
// Names. Every file starts with the prefix. Every top-level name is unique across the whole app (Preview compiles every
// universe together), so prefix the ones other files need and keep the rest `private`. Code in this folder never
// names another universe, and code outside it never names this one.
//
// What you may use: everything in the engine's toolkit, freely, from inside the folder. `Persona` and its weapons,
// shots, magic and motions (Persona.swift); `PixelCanvas`, `Pose`, `drawLegs`, `drawBody`, `drawBoots`, `drawHood`,
// `Look`, `C(0xRRGGBB)`, `lerp`, `noise`, `gradient`, `pattern` and outlines (Pixel.swift, Pose.swift,
// Characters.swift, Locations.swift); `Place` and `Scenes`' helpers; `Ride`; `Trip` and `TransitionSet`; and every
// member below. Anything beyond that is an engine request: say what you need, and the owner builds it into the core
// as a general hook any universe can use (as `quirks` and `shootOuts` below once were). Never slip an `if` for your
// universe into a shared file: that's what turns every hand-off into a merge fight.

/// The universe as the app sees it: everything the engine asks of it. Exactly one type in the folder conforms to
/// `UniverseModule`, and universe.conf's `entry` names it. The first five members must be written; the rest have
/// defaults (Sources/App/Universes/UniverseModule.swift), written out here so you can see each one and its rule.
struct EterniaUniverse: UniverseModule {
    // MARK: Must be written

    /// The cast, the places in order, who lives where, arch-enemies, rides, the menu icon, the Status Symbols
    /// character: EterniaRoster.swift.
    var theme: Theme { eterniaTheme }
    /// Every place's drawing, by key: the Places files, merged in EterniaRoster.swift. Every key in `theme.places`
    /// has one.
    var places: [Location: Place] { eterniaPlaces }
    /// HEM's costume here: EterniaHem.swift.
    var hem: HemCostume { eterniaHem }
    /// What Tools/Preview needs: the batch names for the art files (`eterniaHeroes1`, `eterniaVillains1`, one per
    /// file, in order; add each new file to its list) and the characters by enum case name.
    var preview: PreviewInfo {
        .of(.eternia, heroes: "eterniaHeroes", [eterniaHeroes1], villains: "eterniaVillains", [eterniaVillains1])
    }
    /// The trips between places (EterniaWipes.swift): `pick` chooses the next, `every` lists one of each kind for
    /// Tools/Transitions. nil would leave plain edge and clock wipes, as only Star Clawds keeps.
    var transitions: TransitionSet? {
        TransitionSet(pick: { last, cast, _, to in EterniaTrip.pick(after: (last as? EterniaTrip)?.kind, cast: cast, to: to) },
                      every: { _, _ in ShownTrip.all(EterniaWipe.allCases) { EterniaTrip(kind: $0) } })
    }

    // MARK: Have defaults

    /// Five sample prompts for the Playground's cards, in the universe's voice.
    var playgroundPrompts: [String] {
        ["Skeleclawd stole the castle keys: rotate the secrets", "Orkko broke the build again, find out what he did",
         "by the power of Greyskull, fix the flaky test", "Gwildor's Cosmic Key plays the wrong notes: fix the tune parser",
         "Hordakk needs a dashboard for the Fright Zone's smokestacks"]
    }
    /// Who floats cross-legged in meditation among their drills: `.casters` (magic users, the default), `.never`,
    /// `.castersAndSabers`, or `.heroes([...])` by hero index. `stones: true` floats bits of rock round them.
    var meditation: Meditation { Meditation(who: .never) }   // Orkko floats already; nobody here sits cross-legged in the air
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
            LineupSlot.pair(.villain(EterniaVillain.skeleclawd), true, "", 60, .hero(EterniaHero.heClawd), true, "", 150),
        ], social: (title: Universe.eternia.title.uppercased(), subtitle: "Your AI sessions as a pixel-art battle for Castle Greyskull on your desktop",
                    cast: [.hero(EterniaHero.heClawd), .villain(EterniaVillain.skeleclawd)]))
    }
}
