import AppKit

// The universe's trailer: `REEL=crawl build/renderpromo video promo` → promo/dungeon-crawler-clawd-promo.mp4. Drawn with
// RenderPromo's kit (Tools/RenderPromo/Kit: `Shot`, `brawl`, `windowShot`, `statusOf`, `agentsOf`, `everyAI`, `Mix`…)
// and compiled only into that tool, never into the app: Tools/universes.sh keeps the folder's Promo/ out of it.
//
// The Collapse opens it, Odette's sofa drops the crew into a boss fight (CrawlReelIntro.swift), then the shared shots.
//   source Tools/universes.sh && swiftc … (Tools/RenderPromo/main.swift's header has the whole command)
//   REEL=crawl build/renderpromo storyboard promo   the storyboard sheet, from `beats`
//   REEL=crawl build/renderpromo check               every frame once

/// The trailer, as the tool asks for it (`PromoReel`, Tools/RenderPromo/Kit/Reel.swift).
struct CrawlReel: PromoReel {
    /// Its REEL name (the manifest's `reel`), its video's file name and the GitHub-sized copy's.
    let name = "crawl", base = "dungeon-crawler-clawd-promo", small = "Dungeon-Crawler-Clawd"
    var title: String { universe.title.uppercased() }
    /// What Gemini's terminal is busy with on the desktop, in the universe's voice.
    let geminiTask = "gemini ▸ map the first floor"
    var shots: [Shot] { crawlShots }
    var beats: [(key: Double, beat: Beat)] { crawlBeats }
    var universe: Universe { .crawl }
    /// Who's in its desktop brawl, and the caption under the universe's pill (the promo plays this shot too).
    var brawl: BrawlCast {
        BrawlCast(claude: .hero(CrawlHero.carl), other: .villain(CrawlVillain.maestro), agent: .hero(CrawlHero.katia), otherAgent: .villain(CrawlVillain.juicer),
                  line: universe.isReleased ? "Or crawl into \(universe.title)." : "Coming soon: \(universe.title).",
                  sub: "Goblin dynamite, Magic Missiles and a cat with a crown.")
    }
    /// Who's in its window, and what you asked them (the promo plays this shot too).
    var window: WindowCast {
        WindowCast(place: .crawlSafeRoom, claude: .hero(CrawlHero.carl), other: .villain(CrawlVillain.maestro),
                   agentA: .hero(CrawlHero.donut), agentB: .hero(CrawlHero.katia), extra: .villain(CrawlVillain.juicer),
                   prompt: "You: “loot the flaky tests”", otherPrompt: "You: “raise the ratings”")
    }
    func sound(_ m: Mix) { crawlSound(m) }
}

// MARK: The shots

/// Where the shared shots start: straight after the opening and the set piece.
private let app = crawlIntroLength + crawlBossLength

/// Every shot, in order, each with its start and end in seconds and how it comes in (the soft wipe unless it says).
let crawlShots: [Shot] = [
    // The Collapse: the street sinks, WELCOME, CRAWLER!, the title, the drop into a safe room.
    Shot(name: "intro", start: 0, end: crawlIntroLength, into: .cut) { ctx, local, t in crawlIntro(ctx, local: local, t: t) },
    // From Odette's sofa to the Juicer's gym.
    Shot(name: "boss", start: crawlIntroLength, end: app, into: .cut) { ctx, local, t in crawlBoss(ctx, local: local, t: t) },
    Shot(name: "hook", start: app, end: app + 4.0, into: .cut) { ctx, local, _ in
        let zoom = 1 + 0.03 * local
        ctx.saveGState()
        ctx.translateBy(x: Double(W) / 2, y: Double(H) / 2); ctx.scaleBy(x: zoom, y: zoom); ctx.translateBy(x: -Double(W) / 2, y: -Double(H) / 2)
        desktop(ctx, dim: 0)
        ctx.restoreGState()
        caption("Three AIs. Nine agents. One very confused crawler.", ctx, local: local, start: 0.05, y: 860, size: 60)
        caption("Sound familiar?", ctx, local: local, start: 0.7, y: 120, size: 76, color: yellow)
    },
    Shot(name: "desktop", start: app + 4.0, end: app + 8.6) { ctx, local, t in
        brawl(ctx, .crawl, local: local, t: t, drop: true, chrome: false)
        badge("DESKTOP MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Welcome to the dungeon. Your desktop is the dungeon.", ctx, local: local, start: 0.35, y: 900, size: 56)
        caption("A pixel-art \(Universe.crawl.title) brawl along the bottom of your screen. They fight while they work.", ctx,
                local: local, start: 0.6, y: 830, size: 36, color: yellow, weight: .bold)
    },
    Shot(name: "status", start: app + 8.6, end: app + 12.8) { ctx, local, t in
        let cast: [Cast] = [.hero(CrawlHero.carl), .hero(CrawlHero.donut), .hero(CrawlHero.katia), .hero(CrawlHero.prepotente)]
        statusOf(ctx, local: local, t: t, cast: cast, badgeText: Universe.crawl.title.uppercased(),
                 aside: "(\(cast[2].name) needs you. Achievement: Professional Loiterer.)")
    },
    Shot(name: "agents", start: app + 12.8, end: app + 16.8) { ctx, local, t in
        agentsOf(ctx, local: local, t: t, guardCast: .hero(CrawlHero.mordecai),
                 crew: [.hero(CrawlHero.katia), .hero(CrawlHero.mongo), .hero(CrawlHero.bautista), .hero(CrawlHero.imani)],
                 line: "Every subagent gets a loot box.", badgeText: Universe.crawl.title.uppercased())
    },
    // The window comes in on the universe's own trip.
    Shot(name: "window", start: app + 16.8, end: app + 21.6,
         into: .trip(ComicTransition(CrawlTrip(kind: .lootBox, from: .crawlGym, to: .crawlSafeRoom)))) { ctx, local, t in
        windowShot(ctx, .crawl, local: local, t: t, rise: true, needsAt: 2.5, at: .crawlSafeRoom)
        badge("WINDOW MODE", ctx, alpha: clamp((local - 0.2) / 0.3))
        caption("Safe room. For now.", ctx, local: local, start: 0.1, y: 955, size: 56)
        caption("A live card per session: what it's doing, your last prompt, every agent.", ctx, local: local, start: 0.4, y: 890,
                size: 32, color: yellow, weight: .bold)
    },
    Shot(name: "ais", start: app + 21.6, end: app + 26.0) { ctx, local, t in
        everyAI(ctx, local: local, t: t, cast: [.hero(CrawlHero.carl), .hero(CrawlHero.donut), .hero(CrawlHero.katia), .villain(CrawlVillain.maestro),
                                                .hero(CrawlHero.mordecai), .villain(CrawlVillain.juicer), .hero(CrawlHero.prepotente)])
    },
    // The end card: the safe room, the crew lines up, the title lands, then the app's icon and where to get it.
    Shot(name: "endcard", start: app + 26.0, end: app + 30.2) { ctx, local, t in crawlEndcard(ctx, local: local, t: t) },
]

/// The end card, its line under "Have fun. Keep track." never a count of universes.
func crawlEndcard(_ ctx: CGContext, local: Double, t: Double) {
    blit(place(.crawlSafeRoom, floorRows: 34, t: t), ctx)
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.3)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let crew: [(Cast, FightRole, AI)] = [(.hero(CrawlHero.donut), .cheer, .desktop), (.hero(CrawlHero.carl), .zap, .claude),
                                         (.villain(CrawlVillain.maestro), .zap, .codex)]
    var placed: [Actor] = []
    for (i, (who, role, ai)) in crew.enumerated() {
        var a = Actor(cast: who, x: [60.0, 130, 200][i], facing: i < 2 ? 1 : -1, role: role, ai: ai)
        a.lift = 8
        a.alpha = clamp((local - 0.15 - Double(i) * 0.05) / 0.2)
        draw(a, ctx, t: t)
        placed.append(a)
    }
    if local > 0.5 { drawFX([(placed[1], placed[2])], ctx, t: t) }
    caption(Universe.crawl.title.uppercased(), ctx, local: local, start: 0.35, y: 760, size: 120)
    caption("Have fun. Keep track.", ctx, local: local, start: 0.6, y: 520, size: 56)
    caption("One of many universes in Clawd Clash · free for macOS", ctx, local: local, start: 0.8, y: 462, size: 34,
            color: NSColor(white: 0.85, alpha: 1), weight: .bold)
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
let crawlBeats: [(key: Double, beat: Beat)] = [
    (1.5, ("THE COLLAPSE", "Rain on Carl's street at night. The ground cracks and the buildings start to sink.", "", "rain, a low rumble")),
    (2.6, ("WELCOME, CRAWLER!", "The blue System box slams in over the sinking street.", "SYSTEM MESSAGE: WELCOME, CRAWLER!", "a game-show brass sting, our own notes")),
    (4.0, ("THE TITLE", "The glittering title sweeps up and knocks the box away.", "\(Universe.crawl.title.uppercased())", "the crawl tune starts on a held chord")),
    (5.4, ("THE FALL", "The floor goes and the crew fall through bands of System blue.", "", "a rushing wind, the tune's hook comes in")),
    (7.5, ("A SAFE ROOM", "They land in a safe room, and the System names it.", "ENTERING: A SAFE ROOM", "a thump, a ping")),
    (10.5, ("ON THE SOFA", "Carl and Donut on Odette's cream sofa, ON AIR glowing.", "", "polite studio applause over the tune's game-show beat")),
    (12.0, ("THE TRAPDOOR", "The floor opens under the sofa and they drop out of shot.", "", "a clunk, a falling whistle")),
    (14.5, ("BOSS ROOM", "The Juicer's gym, the lights gone red. Carl punches, Donut fires Magic Missiles, Mongo leaps in.", "", "the tune again, heavier drums, pew, a screech")),
    (17.4, ("BOSS DEFEATED", "The Juicer falls. The System box drops in.", "BOSS DEFEATED, “Mongo is appalled.”", "the tune's fanfare on brass, a loot-box rattle")),
    (app + 1.5, ("THE HOOK", "The desktop, busy with terminals, zooming in slowly.", "“Three AIs. Nine agents. One very confused crawler.” “Sound familiar?”", "keys clicking, the groove fading in")),
    (app + 6.0, ("THE DESKTOP", "\(Cast.hero(CrawlHero.carl).name) and \(Cast.villain(CrawlVillain.maestro).name) drop onto the desktop and fight along the bottom of the screen.",
           "DESKTOP MODE, “Welcome to the dungeon. Your desktop is the dungeon.”", "footsteps, dynamite and a crackle of magic")),
    (app + 10.5, ("THE STATUS", "The crew in a line-up, one state each.", "“Achievement: Professional Loiterer.”", "pops, a little tune")),
    (app + 14.5, ("THE AGENTS", "Mordecai keeps watch while the subagents run in.", "“Every subagent gets a loot box.”", "running feet")),
    (app + 19.0, ("THE WINDOW", "A loot box bursts open onto the window: a safe room, the cards under it.", "WINDOW MODE, “Safe room. For now.”", "a thump, then a ping")),
    (app + 23.5, ("EVERY AI", "Every AI's sessions, each in its own colour.", "the AIs' names", "pops")),
    (app + 28.0, ("THE END CARD", "The safe room, the crew lined up, the title.", "\(Universe.crawl.title.uppercased()), “Have fun. Keep track.”", "the last chord")),
]

// MARK: The sound

/// The score and effects: the opening's own tune (CrawlReelSound.swift), the shared groove under the app shots, each shot's effects, the trips' own sounds, and a
/// last chord on the end card. A finished trailer has music of its own in the franchise's spirit, never its notes.
func crawlSound(_ m: Mix) {
    crawlOpeningSound(m)
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    for t in shotTimes(desk + 0.45, deskEnd, offset: 0) { m.pew(t, vol: 0.07) }
    m.crackle(desk + 0.5, deskEnd - desk - 0.5, vol: 0.02)
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    let wi = start("window")
    m.whoosh(wi - 0.6, 1.2, vol: 0.1)
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    for s in shots { transitionSound(m, s) }
    let ec = start("endcard")
    for n in [55, 59, 62, 67] { m.tone(ec + 0.35, 2.8, midi(n), wave: .saw, vol: 0.035, attack: 0.05, release: 1.4) }
    m.boom(ec + 0.35, vol: 0.4)
}
