import AppKit

// The Clawds of the Universe trailer: `REEL=eternia build/renderpromo video promo` → promo/clawds-of-the-universe-promo.mp4.
// Drawn with RenderPromo's kit (Tools/RenderPromo/Kit: `Shot`, `brawl`, `windowShot`, `statusOf`, `agentsOf`,
// `everyAI`, `Mix`…) and compiled only into that tool, never into the app: Tools/universes.sh keeps the folder's
// Promo/ out of it.
//
// It opens on By the Power of Greyskull, the title sequence (EterniaReelIntro.swift): dusk at Castle Greyskull, Prince
// Addam walks up with Cringer trembling behind him, raises the sword, the lightning comes down (the app's own Greyskull trip, in
// close-up), and He-Clawd stands there with Battle Kat; CLAWDS OF THE UNIVERSE rises in carved stone and the camera
// plunges through the jawbridge. Then the set piece (EterniaReelSiege.swift): Skeleclawd's crew roll out of Snake
// Mountain on the Roton to the jawbridge, Orkko's spell rains on Skeleclawd, He-Clawd lifts the Roton over his head,
// Skeleclawd vanishes in a purple puff, and Orkko gives the moral. Then the shared shots.
//   source Tools/universes.sh && swiftc … (Tools/RenderPromo/main.swift's header has the whole command)
//   REEL=eternia build/renderpromo storyboard promo   the storyboard sheet, from `beats`
//   REEL=eternia build/renderpromo check               every frame once

/// The trailer, as the tool asks for it (`PromoReel`, Tools/RenderPromo/Kit/Reel.swift).
struct EterniaReel: PromoReel {
    /// Its REEL name (the manifest's `reel`), its video's file name and the GitHub-sized copy's.
    let name = "eternia", base = "clawds-of-the-universe-promo", small = "Clawds-of-the-Universe"
    var title: String { universe.title.uppercased() }
    /// What Gemini's terminal is busy with on the desktop, in the universe's voice.
    let geminiTask = "gemini ▸ polish the Power Sword"
    var shots: [Shot] { eterniaShots }
    var beats: [(key: Double, beat: Beat)] { eterniaBeats }
    var universe: Universe { .eternia }
    /// Who's in its desktop brawl, and the caption under the universe's pill (the promo plays this shot too).
    var brawl: BrawlCast {
        BrawlCast(claude: .hero(EterniaHero.heClawd), other: .villain(EterniaVillain.skeleclawd),
                  agent: .hero(EterniaHero.teelah), otherAgent: .villain(EterniaVillain.beastClawd),
                  line: universe.isReleased ? "Or ride out to \(universe.title)." : "Coming soon: \(universe.title).",
                  sub: "Power Swords, a Havoc Staff and a tiger who'd rather not.")
    }
    /// Who's in its window, and what you asked them (the promo plays this shot too).
    var window: WindowCast {
        WindowCast(place: .eterniaGreyskull, claude: .hero(EterniaHero.heClawd), other: .villain(EterniaVillain.skeleclawd),
                   agentA: .hero(EterniaHero.teelah), agentB: .hero(EterniaHero.orkko), extra: .villain(EterniaVillain.trapClawd),
                   prompt: "You: “by the power of Greyskull, fix the flaky test”", otherPrompt: "You: “steal the castle keys”")
    }
    func sound(_ m: Mix) { eterniaSound(m) }
}

/// The end card's line under "Have fun. Keep track.": never a count of universes.
let eterniaTagline = "One of many universes in Clawd Clash · free for macOS"

/// A Clawds of the Universe character's name, as the app has it.
func eterniaName(_ h: EterniaHero) -> String { Cast.hero(h).name }
func eterniaName(_ v: EterniaVillain) -> String { Cast.villain(v).name }

// MARK: The shots

/// The title sequence's and the set piece's lengths.
let eterniaIntroLength = 9.5, eterniaSiegeLength = 9.5
/// Where the shared shots start: straight after the set piece.
private let app = eterniaIntroLength + eterniaSiegeLength

/// Every shot, in order, each with its start and end in seconds and how it comes in (the soft wipe unless it says).
let eterniaShots: [Shot] = [
    // By the Power of Greyskull: the title sequence.
    Shot(name: "intro", start: 0, end: eterniaIntroLength, into: .cut) { ctx, local, t in eterniaIntro(ctx, local: local, t: t) },
    // Snake Mountain to the jawbridge: Skeleclawd's raid, Orkko's rain, He-Clawd and the Roton, the moral.
    Shot(name: "siege", start: eterniaIntroLength, end: eterniaIntroLength + eterniaSiegeLength, into: .cut) { ctx, local, t in
        eterniaSiege(ctx, local: local, t: t)
    },
    Shot(name: "hook", start: app, end: app + 4.0, into: .cut) { ctx, local, _ in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused prince.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: app + 4.0, end: app + 8.6) { ctx, local, t in
        brawl(ctx, .eternia, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("The battle for Greyskull, right on your desktop.", ctx, local: local, start: 0.35, y: 900)
        caption("A pixel-art \(Universe.eternia.title) brawl along the bottom of your screen. They fight while they work.", ctx,
                local: local, start: 0.6, y: 830, size: 36, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: app + 8.6, end: app + 12.8) { ctx, local, t in
        let cast: [Cast] = [.hero(EterniaHero.heClawd), .hero(EterniaHero.teelah), .hero(EterniaHero.orkko), .hero(EterniaHero.cringer)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: Universe.eternia.title.uppercased(),
                 aside: "(\(cast[2].name) needs you: “Oops!” \(cast[3].name) is hiding under the throne.)")
        // Teelah, thinking, asks the question she always asks.
        let ask = clamp((local - 1.4) / 0.15)
        if ask > 0 {
            let her = Actor(cast: cast[1], x: 48 + 75, mode: .thinking)
            let head = headPoint(her)
            balloon("Where's Adam?", ctx, center: CGPoint(x: head.x - 40, y: head.y + 250), tail: CGPoint(x: head.x - 20, y: head.y + 30),
                    size: 38, width: 500, alpha: ask)
        }
    },
    Shot(name: "agents", start: app + 12.8, end: app + 16.8) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .hero(EterniaHero.manAtClawds),
                 crew: [.hero(EterniaHero.teelah), .hero(EterniaHero.stratos), .hero(EterniaHero.ramClawd), .hero(EterniaHero.mekaneck)],
                 line: "Every subagent gets to be a Master of the Universe.", badgeText: Universe.eternia.title.uppercased())
    },
    // The window comes in on the universe's own Wind Raider trip, from Snake Mountain to Castle Greyskull.
    Shot(name: "window", start: app + 16.8, end: app + 21.6,
         into: .trip(ComicTransition(EterniaTrip(kind: .windRaider, from: .eterniaSnakeMountain, to: .eterniaGreyskull)))) { ctx, local, t in
        windowShot(ctx, .eternia, local: local, t: t, rise: true, needsAt: 2.5, at: .eterniaGreyskull)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Prefer a window? It has the power.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890,
                size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: app + 21.6, end: app + 26.0) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.hero(EterniaHero.heClawd), .hero(EterniaHero.sheClawd), .villain(EterniaVillain.skeleclawd),
                                                .villain(EterniaVillain.hordakk), .villain(EterniaVillain.evilLynn),
                                                .villain(EterniaVillain.beastClawd), .villain(EterniaVillain.trapClawd)])
    },
    // The end card: Castle Greyskull, the crew lines up, the title lands in stone, then the app's icon and where to get it.
    Shot(name: "endcard", start: app + 26.0, end: app + 30.2) { ctx, local, t in eterniaEndcard(ctx, local: local, t: t) },
]

/// The end card, its line under "Have fun. Keep track." never a count of universes.
func eterniaEndcard(_ ctx: CGContext, local: Double, t: Double) {
    blit(place(.eterniaGreyskull, floorRows: 34, t: t), ctx)
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.3)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let crew: [(Cast, FightRole, AI)] = [(.hero(EterniaHero.teelah), .cheer, .desktop), (.hero(EterniaHero.heClawd), .zap, .claude),
                                         (.villain(EterniaVillain.skeleclawd), .hit, .codex), (.villain(EterniaVillain.beastClawd), .none, .copilot),
                                         (.villain(EterniaVillain.evilLynn), .cheer, .qwen), (.villain(EterniaVillain.trapClawd), .none, .gemini)]
    let xs: [Double] = [28, 84, 156, 206, 252, 296]
    var placed: [Actor] = []
    for (i, (who, role, ai)) in crew.enumerated() {
        var a = Actor(cast: who, x: xs[i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
        a.lift = 8
        a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
        draw(a, ctx, t: t)
        placed.append(a)
    }
    if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
    // The title in carved stone, dropping into place with a thud and a glint running across it.
    if local > 0.35 {
        let land = backOut((local - 0.35) / 0.4)
        let y = 760 + 120 * (1 - land)
        eterniaDrawTitle(ctx, center: CGPoint(x: Double(W) / 2, y: y), scale: 5.0 / 6 + 0.1 * (1 - land), alpha: clamp((local - 0.35) / 0.15),
                         glint: (local - 0.75) / 0.5)
    }
    caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
    caption(eterniaTagline, ctx, local: local, start: 0.8, y: 462, size: 34, color: NSColor(white: 0.85, alpha: 1), weight: .bold)
    let ff = easeOut((local - 0.9) / 0.3)
    if ff > 0, let icon = appIcon {
        ctx.setFillColor(CGColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 0.8 * ff)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: 170))
        ctx.saveGState(); ctx.setAlpha(CGFloat(ff)); ctx.interpolationQuality = .high
        ctx.draw(icon, in: CGRect(x: 580, y: 20, width: 130, height: 130))
        ctx.restoreGState()
        text("github.com/rodclemen/clawd-clash", ctx, x: 740, y: 60, size: 44, weight: .bold, alpha: ff)
    }
}

// MARK: The storyboard

/// The storyboard's beats: a time in the reel, and its title, what happens, what's on screen and what's heard.
let eterniaBeats: [(key: Double, beat: Beat)] = [
    (1.4, ("DUSK AT GREYSKULL", "Tight on the near ledge, Castle Greyskull at dusk across the chasm behind, mist drifting in it. \(eterniaName(EterniaHero.princeAddam)) walks up to the edge, a trembling \(eterniaName(EterniaHero.cringer)) at his heels, cowering behind him.",
           "no text", "wind in the chasm, a low brass swell; the march's drum creeping in, our own notes")),
    (3.4, ("THE SWORD", "He draws the sword and raises it to the sky.", "“By the power of Greyskull!”", "a rising brass chord")),
    (5.2, ("THE LIGHTNING", "Close up: the fist and the Power Sword against the sunset, the castle black behind; lightning forks down into the tip, the blade blazes, bolts crackle out to every edge, and white swallows the screen.",
           "no text", "a thunderclap, crackling, the chord held")),
    (7.2, ("I HAVE THE POWER", "Out of the white: \(eterniaName(EterniaHero.heClawd)) stands where \(eterniaName(EterniaHero.princeAddam)) was, sword high, still crackling; \(eterniaName(EterniaHero.cringer)) is \(eterniaName(EterniaHero.battleKat)) now, and roars.",
            "“I HAVE THE POWER!”", "the roar; the march breaks out, brassy and heroic, our own notes")),
    (8.5, ("THE TITLE", "CLAWDS OF THE UNIVERSE rises over the castle in carved stone letters, a glint running across them; the camera plunges through the jawbridge into white.",
           "CLAWDS OF THE UNIVERSE", "a sword shing as it lands, a rising whoosh into the white")),
    (10.6, ("SNAKE MOUNTAIN", "Out of the white, Snake Mountain under a red sky: \(eterniaName(EterniaVillain.skeleclawd)), \(eterniaName(EterniaVillain.beastClawd)) and \(eterniaName(EterniaVillain.trapClawd)) roll out on the Roton.",
            "no text", "the march in a minor key, the Roton's rumble, Skeleclawd's cackle as pitched-down blips")),
    (13.2, ("AT THE JAWBRIDGE", "The Roton pulls up at Greyskull's jawbridge, the crew hops off, and \(eterniaName(EterniaVillain.skeleclawd)) raises the Havoc Staff.",
            "“Greyskull is mine!”", "brakes, a menacing brass stab")),
    (14.5, ("ORKKO HELPS", "\(eterniaName(EterniaHero.orkko)) pops up to help; his spell misfires and a rain cloud opens over \(eterniaName(EterniaVillain.skeleclawd)).",
            "“Oops!”", "a sparkle, a sad slide down, rain")),
    (16.3, ("THE RESCUE", "\(eterniaName(EterniaHero.heClawd)) and \(eterniaName(EterniaHero.battleKat)) leap in; \(eterniaName(EterniaHero.heClawd)) squats under the Roton, pushes it up overhead with both arms, shaking with the strain, dust flying, holds it high while the crew scatters, then tosses it away.",
            "no text", "a whoosh, a straining heave, the march's big hit, a whoosh as it flies")),
    (16.8, ("THE RETREAT", "\(eterniaName(EterniaVillain.skeleclawd)) vanishes in a purple puff.", "“I'll get you for this, He-Clawd!”", "a poof, the cackle fading")),
    (18.2, ("THE MORAL", "\(eterniaName(EterniaHero.orkko)) floats to the front and turns to us.", "“Remember, kids: always write your tests!”", "a little chime, the march's last bar")),
    (app + 1.5, ("THE HOOK", "Three busy terminals, slow push-in.", "“Three AIs. Nine agents. One very confused prince.”  →  “Sound familiar?”",
            "keyboard clicks, the groove fading in")),
    (app + 6.3, ("DESKTOP MODE", "\(eterniaName(EterniaHero.heClawd)) against \(eterniaName(EterniaVillain.skeleclawd)); \(eterniaName(EterniaHero.teelah)) against \(eterniaName(EterniaVillain.beastClawd)).",
            "DESKTOP MODE  ·  “The battle for Greyskull, right on your desktop.”", "footsteps, sword clashes, a crackle of magic")),
    (app + 10.9, ("AT A GLANCE", "\(eterniaName(EterniaHero.heClawd)) working, \(eterniaName(EterniaHero.teelah)) thinking (“Where's Adam?”), \(eterniaName(EterniaHero.orkko)) jumping NEEDS YOU, \(eterniaName(EterniaHero.cringer)) sat down, hiding.",
            "“(Orkko needs you: “Oops!” Cringer is hiding under the throne.)”", "pops, alert beeps")),
    (app + 15.0, ("SUBAGENTS", "\(eterniaName(EterniaHero.manAtClawds)) keeps watch; \(eterniaName(EterniaHero.teelah)), \(eterniaName(EterniaHero.stratos)), \(eterniaName(EterniaHero.ramClawd)) and \(eterniaName(EterniaHero.mekaneck)) arrive with their jobs on their labels.",
            "“Every subagent gets to be a Master of the Universe.”", "running feet")),
    (app + 19.6, ("WINDOW MODE", "In on the app's Wind Raider trip to \(Location.eterniaGreyskull.name), its name rising in stone; the window, live cards tick, then a card flips to NEEDS YOU.",
            "WINDOW MODE  ·  “Prefer a window? It has the power.”", "the Wind Raider's whoosh, a ping")),
    (app + 24.0, ("EVERY AI", "Seven sessions, one per AI outline: \(eterniaName(EterniaHero.heClawd)) (Claude Code, a head taller) and \(eterniaName(EterniaHero.sheClawd)) against \(eterniaName(EterniaVillain.skeleclawd)), \(eterniaName(EterniaVillain.hordakk)), \(eterniaName(EterniaVillain.evilLynn)), \(eterniaName(EterniaVillain.beastClawd)) and \(eterniaName(EterniaVillain.trapClawd)).",
            "BRING YOUR OWN AI*  ·  “One AI plays everyone. Run two and they pick sides.”  ·  *README for the full list", "zaps, pops")),
    (app + 28.9, ("END CARD", "\(Location.eterniaGreyskull.name): the crew lines up, CLAWDS OF THE UNIVERSE lands in stone, then the icon and the URL.",
            "CLAWDS OF THE UNIVERSE  ·  “Have fun. Keep track.”  ·  “\(eterniaTagline)”  ·  github.com/rodclemen/clawd-clash",
            "a bright brass fanfare sting, a last thunder roll")),
]
