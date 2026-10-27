import AppKit

/// One universe, as the app sees it: everything the engine asks a universe for. Each universe's folder has exactly one
/// type conforming to this, in its `<Prefix>Universe.swift`. Members without a default must be written; the rest have
/// sensible defaults. (Its plain numbers, which the hook needs too, are its `UniverseFacts`.)
protocol UniverseModule {
    /// The cast, the places in order, who lives where, arch-enemies, rides, the menu icon and the legend.
    var theme: Theme { get }
    /// Every place's drawing, by key. Keys are unique across universes.
    var places: [Location: Place] { get }
    /// Its trips between places; nil: plain edge and clock wipes (`Wipe`), as Star Clawds keeps.
    var transitions: TransitionSet? { get }
    /// What Tools/Preview needs: the batch names for its art files, and its characters by enum case name.
    var preview: PreviewInfo { get }
    /// HEM's costume here: his face, buns and fist-shaking are the engine's (`HemCostume`).
    var hem: HemCostume { get }

    // Have defaults
    /// Five sample prompts for the Playground's cards.
    var playgroundPrompts: [String] { get }
    /// Who floats cross-legged in meditation, and what floats round them.
    var meditation: Meditation { get }
    /// How guns are drawn: `.classic` is Clawd Wars' way (Star Clawds only).
    var poseStyle: PoseStyle { get }
    /// Who has the moonwalk among their habits.
    var moonwalkers: Set<Cast> { get }
    /// The web line's colour for characters who swing; nil: the usual near-white.
    var swingLine: Px? { get }
    /// A caption that types the place in when the scene changes, in place of the usual place name (The Clawd Files').
    var placeCaption: PlaceCaption? { get }
    /// What a compacted session's leader looks like while it's away and back (`UniverseCompaction.away`), `k` (0…1)
    /// through it; nil: nothing to see.
    func compactionLook(k: Double, cast: Cast) -> CompactionLook?
    /// Little things certain characters do on stage: the Weeping Angle, Captain Clawd's flinch, T. Wrecks's glass…
    var quirks: StageQuirks { get }
    /// Pairs who face off and now and then end with one bolt getting through (Han shoots first).
    var shootOuts: [ShootOut] { get }
    /// Its rides, every one (for Preview's sheet; who takes which is `theme.ride`).
    var rides: [Ride] { get }
    /// Characters' own drills, practised now and then among the general ones.
    var drills: [Cast: BespokeDrill] { get }
    /// What a regeneration looks like (`UniverseCompaction.regenerate`): drawn over the character, already in its next
    /// face, `k` (0…1) through `length` seconds.
    var regeneration: (length: Double, draw: (_ c: PixelCanvas, _ k: Double, _ t: Double) -> Void)? { get }
    /// What a change into a leader's other guise looks like (`UniverseCompaction.transform`), and what they say.
    var transformation: Transformation? { get }
    /// The lessons a leader in `morals` (the facts) gives when their session finishes, one picked each time.
    var morals: [String] { get }
    /// What Tools/RenderDocs draws for the README besides the roster and places: the desktop line-up and the social
    /// preview. Empty: neither is drawn.
    var docs: DocsInfo { get }
    /// Places where, now and then, the whole scene turns over (`SceneFlip`), in the window and the screen saver; nil:
    /// never.
    var sceneFlip: SceneFlip? { get }
    /// Only the template says true (`Sources/App/Universes/_Template/`), and it's never shown in the app: the registry
    /// refuses it in any build but a `TEMPLATE=1` one.
    var isTemplate: Bool { get }
}

extension UniverseModule {
    var transitions: TransitionSet? { nil }
    var playgroundPrompts: [String] {
        ["add a snowtaunt", "make the window resize to fit the Claudes", "why does the duel not start?",
         "write a nice README with screenshots", "fix the portrait crop for wide characters"]
    }
    var meditation: Meditation { Meditation() }
    var poseStyle: PoseStyle { .modern }
    var moonwalkers: Set<Cast> { [] }
    var swingLine: Px? { nil }
    var placeCaption: PlaceCaption? { nil }
    func compactionLook(k: Double, cast: Cast) -> CompactionLook? { nil }
    var quirks: StageQuirks { StageQuirks() }
    var shootOuts: [ShootOut] { [] }
    var rides: [Ride] { [] }
    var drills: [Cast: BespokeDrill] { [:] }
    var regeneration: (length: Double, draw: (_ c: PixelCanvas, _ k: Double, _ t: Double) -> Void)? { nil }
    var transformation: Transformation? { nil }
    var morals: [String] { [] }
    var docs: DocsInfo { DocsInfo() }
    var sceneFlip: SceneFlip? { nil }
    var isTemplate: Bool { false }
}

/// A universe's README pictures beyond its roster and places (Tools/RenderDocs).
struct DocsInfo {
    /// The desktop line-up: groups of one or two, left to right, a pair fighting each other.
    var lineup: [[LineupSlot]] = []
    /// The social preview: its title, the line under it, and who stands on the horizon (heroes first, then villains).
    var social: (title: String, subtitle: String, cast: [Cast])? = nil
}

/// Someone in a desktop line-up: a session (`leader`, its name tag) or an agent (its task as `label`), at `x` in the
/// line-up's points, facing right (1) or left (-1), `up` art pixels off the ground.
struct LineupSlot {
    let who: Cast
    let leader: Bool
    let label: String
    let x: Double
    let facing: Double
    let role: FightRole
    var up = 0.0

    /// Two who fight, `a` facing right and `b` left, their roles from their own weapons as the app pairs them.
    static func pair(_ a: Cast, _ aLead: Bool, _ aLabel: String, _ ax: Double,
                     _ b: Cast, _ bLead: Bool, _ bLabel: String, _ bx: Double) -> [LineupSlot] {
        let (ra, rb) = fightRoles(a.weapon, b.weapon)
        return [LineupSlot(who: a, leader: aLead, label: aLabel, x: ax, facing: 1, role: ra),
                LineupSlot(who: b, leader: bLead, label: bLabel, x: bx, facing: -1, role: rb)]
    }
}

/// Han shoots first, as an engine feature (`ShootsFirst` draws it): whenever `shooter` and `target` fight, now and
/// then the shooter's bolt gets through and knocks the target onto its back.
struct ShootOut {
    let shooter: Cast
    let target: Cast
    /// What the shooter says over the fallen target.
    let says: String
    /// What the target says getting back up, one at random.
    let comebacks: [String]
    /// The shooter fights with something else and draws a gun for this (Indy puts his whip away).
    var drawsGun = false

    /// The shoot-out between `a` and `b`, if their universes have one, with which of them shoots.
    static func between(_ a: Cast, _ b: Cast) -> (ShootOut, aShoots: Bool)? {
        for s in a.universe.module.shootOuts + (a.universe == b.universe ? [] : b.universe.module.shootOuts) {
            if s.shooter == a && s.target == b { return (s, true) }
            if s.shooter == b && s.target == a { return (s, false) }
        }
        return nil
    }
}

/// Someone on the stage, as a universe's quirks see them.
struct OnStage {
    let cast: Cast
    let x: CGFloat
    /// -1 facing left, 1 facing right.
    let facing: CGFloat
    let walking: Bool
    let leaving: Bool
    /// Its own offset (0…1), so two of them don't do the same thing at the same moment.
    let phase: Double
    /// Screen points to one of its art pixels (a leader's are bigger than an agent's), to turn a distance on stage
    /// into sprite pixels for `jitter`.
    var scale: CGFloat = 1
}

/// A universe's stage quirks: things certain characters do, whoever else is about.
struct StageQuirks {
    /// Only move while nobody's looking at them, and then quickly (the Weeping Angle).
    var unseenMovers: Set<Cast> = []
    /// A jump and a shiver, in sprite pixels, and maybe a muttered line: `who` among `others`, at `place`. Its name tag
    /// and speech bubble go with it, so it can also step (or vanish and turn up) somewhere else for a moment.
    var jitter: ((_ who: OnStage, _ others: [OnStage], _ place: Location?, _ t: Double) -> (dx: Int, up: Int, line: String?))? = nil
    /// Something drawn beside `who`, standing on `ground`, `scale` points to an art pixel.
    var prop: ((_ who: OnStage, _ ground: CGFloat, _ scale: CGFloat, _ t: Double) -> StageLayer?)? = nil
    /// A word to someone nearby: which way `who` turns to say it, and the line. `zoom`: the stage's zoom.
    var remark: ((_ who: OnStage, _ others: [OnStage], _ zoom: CGFloat, _ t: Double) -> (facing: CGFloat, line: String)?)? = nil
    /// While one of these is on stage, nobody has a voice: every line comes up an empty bubble (`StageQuirks.hushed`).
    var hushers: Set<Cast> = []
    /// These play their signature once a fight they were in, or watched, is over (Mayor Wilclawds' wet wipe; `AfterDuel`).
    var afterDuel: Set<Cast> = []
    /// For any of those whose signature ends with what they do after a fight: how far into it (0…1) to start, so only
    /// that end plays (Eleven's nosebleed, after her Eggo). Not listed: the whole signature.
    var afterDuelFrom: [Cast: Double] = [:]

    /// A line with the words taken out of it: the same bubble, the same width (the font is monospaced), nothing in it.
    /// No-break spaces, so the text keeps its width when it's measured.
    static func hushed(_ line: String) -> String { String(repeating: "\u{00A0}", count: max(3, line.count)) }
}

/// A leader turning into its other guise when its session is compacted (`UniverseCompaction.transform`): Clawds of
/// the Universe's "By the power of Greyskull!".
struct Transformation {
    /// How long it plays, in seconds.
    let length: Double
    /// Drawn over the character, already in its new guise (`into`; still the old one if the other was on stage, so it
    /// couldn't change), `k` (0…1) through it.
    let draw: (_ c: PixelCanvas, _ k: Double, _ t: Double, _ into: Cast) -> Void
    /// What it says over its head while it plays, if anything ("I have the power!").
    var says: (_ into: Cast) -> String? = { _ in nil }
}

/// How long a leader's lesson stays up when its session finishes (the module's `morals`), in seconds.
let moralLength = 5.0

/// How long a compaction plays on stage (`SessionRecord.abducted` to set down), in seconds: the missing-time clock
/// every `compactionLook` runs on.
let missingTimeLength = 6.0

/// A moment of a compaction on stage: The Clawd Files' abduction beam, Stevie Clawdberg's 88 mph, Clawd Slayer's
/// forgetting spell. The overlay asks for it every frame while it plays.
protocol CompactionLook {
    /// A line over the character's head ("WHERE DID THE TIME GO?").
    var caption: String? { get }
    /// How much of the character shows (fading into a beam or a flash).
    var alpha: Double { get }
    /// How far it's lifted, in art pixels.
    var lift: Double { get }
    /// Art pixels kept clear over its head for a mark (the forgetting spell's "?"), so its name tag sits above.
    var markRoom: Double { get }
    /// What's drawn round it, placed for a character at `x` (screen points, its middle) standing on `y`, already lifted
    /// `lift` points, drawn `scale` points to an art pixel and facing `facing` (-1 left, 1 right).
    func layers(cast: Cast, x: CGFloat, y: CGFloat, lift: CGFloat, scale: CGFloat, facing: CGFloat, t: Double) -> [StageLayer]
    /// Anything done to the character's own picture (a shimmer).
    func touch(_ sprite: PixelCanvas, t: Double)
}

extension CompactionLook {
    var caption: String? { nil }
    var alpha: Double { 1 }
    var lift: Double { 0 }
    var markRoom: Double { 0 }
    func touch(_ sprite: PixelCanvas, t: Double) {}
}

/// A picture drawn on the stage, in screen points.
struct StageLayer {
    let image: CGImage
    let rect: CGRect
    var mirrored = false
}

/// The place's name, typed in a letter at a time when the scene changes, shown by the window and the screen saver in
/// place of the usual place name.
struct PlaceCaption {
    /// What's been typed `t` seconds after it started, line by line (the place, then where it is).
    let typed: (_ place: Location, _ t: Double) -> [String]
    /// Whether it's done typing (and blinking) `t` seconds after it started.
    let done: (_ place: Location, _ t: Double) -> Bool
    /// The typeface, at a size.
    let font: (CGFloat) -> NSFont
}

/// Who meditates in a universe (floating cross-legged, among their drills), if their persona can sit at all.
struct Meditation {
    enum Who {
        case never                      // a sonic screwdriver, a flashlight or a bullwhip is no reason to float
        case casters                    // magic users
        case castersAndSabers           // magic users and everyone with a saber: Jedi and Sith alike
        case heroes(Set<Int>)           // just these heroes, by local index (Clawd Slayer's witches)
    }
    var who: Who = .casters
    /// Bits of rock float round them (Star Clawds); otherwise motes of their own magic.
    var stones = false
}

/// How a universe draws guns.
enum PoseStyle {
    case modern
    /// As Clawd Wars did: never raised while waiting or cheering, the flash at the resting muzzle, and heroes don't
    /// raise theirs to check them either.
    case classic
}

extension Universe {
    /// The universe's module (`registeredModules`, generated from the folders by Tools/universes.sh).
    var module: UniverseModule { checkedModules[self]! }

    /// `--template-preview`, which `TEMPLATE=1 ./build.sh` launches with: the template on show for a look, real
    /// sessions adopted into its cast. It counts as a test run (any `--` flag does), so the hook is never told about it,
    /// and nothing that names it is saved (the universe, the place, the menu icon's, the screen-saver feed).
    static let templatePreview = CommandLine.arguments.contains("--template-preview")
    /// The template, in a `--template-preview` run of a TEMPLATE=1 build; nil otherwise.
    static let previewed: Universe? = templatePreview ? allCases.first { $0.module.isTemplate } : nil
}

/// `registeredModules`, checked the first time any is asked for: the template (`isTemplate`) only ever comes in a
/// TEMPLATE=1 build, which passes `-D CLAWD_TEMPLATE`, and never in a release build (`-D CLAWD_RELEASE`), flag or not.
/// Anything else stops the app before it can show it.
private let checkedModules: [Universe: UniverseModule] = {
    let templates = registeredModules.filter { $0.value.isTemplate }.map { "\($0.key.title) (\($0.key.rawValue))" }
    #if CLAWD_RELEASE
    if !templates.isEmpty { fatalError("the template is never released: \(templates.joined(separator: ", ")) is in a release build") }
    #elseif CLAWD_TEMPLATE
    _ = templates
    #else
    if !templates.isEmpty { fatalError("the template is only for TEMPLATE=1 builds: \(templates.joined(separator: ", ")) is in this one") }
    #endif
    return registeredModules
}()

/// A universe's characters as Tools/Preview finds them: by batch (one art file's worth, "slayerHeroes1") and by enum
/// case name (`buffy`).
struct PreviewInfo {
    var batches: [(name: String, cast: [Cast])] = []
    var caseName: (String) -> Cast? = { _ in nil }

    /// The usual shape: hero files `<heroes>1…`, villain files `<villains>1…` (each a `[Enum: Persona]`, as the art
    /// files define them), plus any `extra` batches, and the case names of both enums.
    static func of<H, V>(_ u: Universe, heroes: String, _ heroFiles: [[H: Persona]], villains: String, _ villainFiles: [[V: Persona]],
                         extra: [(name: String, cast: [Cast])] = []) -> PreviewInfo
    where H: CaseIterable & RawRepresentable & Hashable, V: CaseIterable & RawRepresentable & Hashable, H.RawValue == Int, V.RawValue == Int {
        func hero(_ h: H) -> Cast { Cast(universe: u, isDark: false, index: h.rawValue) }
        func villain(_ v: V) -> Cast { Cast(universe: u, isDark: true, index: v.rawValue) }
        var out = PreviewInfo()
        for (i, b) in heroFiles.enumerated() { out.batches.append(("\(heroes)\(i + 1)", b.keys.sorted { $0.rawValue < $1.rawValue }.map(hero))) }
        for (i, b) in villainFiles.enumerated() { out.batches.append(("\(villains)\(i + 1)", b.keys.sorted { $0.rawValue < $1.rawValue }.map(villain))) }
        out.batches += extra
        out.caseName = { n in H.allCases.first { "\($0)" == n }.map(hero) ?? V.allCases.first { "\($0)" == n }.map(villain) }
        return out
    }
}

/// One trip between two places: Marvel's comic panels, the TARDIS's vortex, The Clawd Files' black oil…
protocol Trip {
    var duration: Double { get }
    /// A frame `k` (0…1) of the way from `old` to `new`, over the whole of `r`.
    func draw(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect)
    /// How much of the crew shows at `k` (0…1): 1 while the trip stays on the ground, less while it leaves it (the
    /// Great Eagle's open sky), so nobody is left standing on thin air.
    func crewShown(_ k: Double) -> Double
}

extension Trip {
    func crewShown(_ k: Double) -> Double { 1 }
}

/// A universe's trips.
struct TransitionSet {
    /// The trip to `to`, coming `from` (if known). `last` is the previous trip if it was this universe's, so it can pick
    /// a different kind.
    let pick: (_ last: Trip?, _ cast: [Cast], _ from: Location?, _ to: Location) -> Trip
    /// One of every kind, from `from` to `to`, for Tools/Transitions' sheets and clips.
    let every: (_ from: Location, _ to: Location) -> [ShownTrip]
}

/// A trip as Tools/Transitions shows it: its file key ("3-burst"), its title, the trip.
struct ShownTrip {
    let key: String
    let title: String
    let trip: Trip

    /// Every kind of a universe's trips, numbered from 1 in the kinds' order.
    static func all<W: CaseIterable & RawRepresentable>(_ kinds: W.AllCases, _ make: (W) -> Trip) -> [ShownTrip] where W.RawValue == Int {
        kinds.map { ShownTrip(key: "\($0.rawValue + 1)-\($0)", title: "\($0)", trip: make($0)) }
    }
}
