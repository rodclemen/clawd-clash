import AppKit

// Dungeon Crawler Clawd: New Achievement!, Katia's monster truck, eight of the trips, and the icon.
// The showcase README's own pictures, drawn by Tools/RenderShowcase (`build/rendershowcase docs crawl`) with its kit
// (`canvas`, `strip`, `sprite`, `at`, `tag`…). Compiled only into that tool. The habits play on a live stage, so the
// window and screen-saver shots (CLAWD_SHOT captures of a Playground run) show those.

struct CrawlShowcase: Showcase {
    let name = "crawl"
    func render() { crawlShowcase() }
}

// MARK: Dungeon Crawler Clawd

/// Katia's monster truck standing on the floor of a panel, centred on `x`.
private func truck(_ ctx: CGContext, _ o: CGPoint, x: Double, ramp: Double, moving: Bool, t: Double = 0.4) {
    let ride = Ride.crawlMonsterTruck
    let c = PixelCanvas(Ride.width, ride.canvasHeight)
    drawRide(c, ride, ramp: ramp, engines: moving, gear: true, t: t)
    c.addOutline(C(0xFFFFFF, 0.92))
    put(c, ctx, x: x - Double(Ride.width) / 2, y: Double(ph - 8 - ride.canvasHeight + 1), unit: unit, frameH: ph, origin: o)
}

/// Someone `k` (0…1) through New Achievement!, the box a gold one: the loot box's light behind them, them with the box
/// at their feet, and the System box over their head, brought down to the top of the panel (the app gives it more
/// room overhead than a 66-row panel has).
private func achievement(_ who: Cast, k: Double, _ ctx: CGContext, _ o: CGPoint, bodyX: Double, t: Double = 0.5) {
    let a = CrawlAchievement(k: k, tier: .gold, cast: who)
    let light = PixelCanvas(pw, ph)
    crawlDrawLootLight(light, a, mouth: (bodyX + 48.5 - Sprite.bodyCenterX, spriteTop + 44 - 7), t: t)
    put(light, ctx, x: 0, y: 0, unit: unit, frameH: ph, origin: o)
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: .idle, walking: false, role: .none, asSession: true)
    a.touch(c, t: t)
    c.addOutline(C(0xFFFFFF, 0.92))
    at(c, ctx, o, bodyX: bodyX)
    guard a.panelDrop < 1000 else { return }
    let boxW = ["YOU", "FORGOT", "EVERYTHING!"].reduce(0) { $0 + crawlTextWidth($1) } + 6 + 4
    let box = PixelCanvas(pw, ph)
    crawlDrawSystemBox(box, a, x: Int(bodyX) - boxW / 2 + a.panelJolt, y: 3 - a.panelDrop, t: t)
    put(box, ctx, x: 0, y: 0, unit: unit, frameH: ph, origin: o)
}

/// A place as one picture, its still and moving parts together, for a trip to go from or to.
private func shot(_ place: Location, t: Double = 1.3) -> CGImage {
    let bg = PixelCanvas(pw, ph); place.drawStatic(bg, floorRows: 8)
    let mv = PixelCanvas(pw, ph); place.drawAnimated(mv, floorRows: 8, t: t)
    // Its own bitmap, not `canvas`: that would take over the strip's current drawing context, and its captions with it.
    let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .none
    for img in [bg.makeImage(), mv.makeImage()].compactMap({ $0 }) { ctx.draw(img, in: CGRect(x: 0, y: 0, width: pw, height: ph)) }
    return ctx.makeImage()!
}

/// A trip from one place to another, `k` (0…1) through it, over the whole panel.
private func trip(_ kind: CrawlWipe, from: Location, to: Location, k: Double, _ ctx: CGContext, _ o: CGPoint) {
    let r = CGRect(x: o.x, y: o.y, width: CGFloat(pw) * unit, height: CGFloat(ph) * unit)
    CrawlTrip(kind: kind, from: from, to: to).draw(ctx, old: shot(from), new: shot(to, t: 2.1), k: k, in: r)
}

func crawlShowcase() {
    Universe.shown = .crawl
    let carl = Cast.hero(CrawlHero.carl), donut = Cast.hero(CrawlHero.donut)
    let maestro = Cast.villain(CrawlVillain.maestro)

    // New Achievement!: /compact in Carl's session, the System box slams down, a loot box drops at his feet,
    // rattles and bursts open.
    let px = 75.0
    strip(.crawlCorridor, [
        Panel(caption: "you type /compact") { ctx, o, sy in
            at(sprite(carl), ctx, o, bodyX: px)
            tag(carl.name, ctx, centerX: o.x + CGFloat(px) * unit, bottom: sy(spriteTop + 16), leader: true)
        },
        Panel(caption: "NEW ACHIEVEMENT!") { ctx, o, _ in achievement(carl, k: 0.11, ctx, o, bodyX: px) },
        Panel(caption: "a loot box drops and rattles…") { ctx, o, _ in achievement(carl, k: 0.5, ctx, o, bodyX: px) },
        Panel(caption: "…and bursts open") { ctx, o, _ in achievement(carl, k: 0.64, ctx, o, bodyX: px) },
    ], file: "new-achievement.png")

    // Katia's monster truck: Donut's agent is done, the truck roars in, drops its tailgate, and she climbs in.
    let dx = 22.0, rx = 96.0
    strip(.crawlSeattle, [
        Panel(caption: "Katia's monster truck roars in") { ctx, o, sy in
            truck(ctx, o, x: rx, ramp: 0, moving: true, t: 0.6)
            at(sprite(donut), ctx, o, bodyX: dx)
            tag("Ship the release", ctx, centerX: o.x + CGFloat(dx) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "Donut climbs aboard") { ctx, o, _ in
            truck(ctx, o, x: rx, ramp: 1, moving: false, t: 1.2)
            at(sprite(donut, t: 0.06, walking: true), ctx, o, bodyX: rx - 31, alpha: 0.85)
        },
    ], file: "monster-truck.png")

    // Eight of the twelve trips between places, each at a moment that shows what it is.
    strip(.crawlSafeRoom, [
        Panel(caption: "The Loot Box") { ctx, o, _ in trip(.lootBox, from: .crawlGym, to: .crawlSafeRoom, k: 0.4, ctx, o) },
        Panel(caption: "Down the Stairwell") { ctx, o, _ in trip(.stairwell, from: .crawlCorridor, to: .crawlGuild, k: 0.4, ctx, o) },
        Panel(caption: "Goblin Dynamite") { ctx, o, _ in trip(.dynamite, from: .crawlHoard, to: .crawlDesperado, k: 0.35, ctx, o) },
        Panel(caption: "Ping") { ctx, o, _ in trip(.ping, from: .crawlCorridor, to: .crawlHoard, k: 0.3, ctx, o) },
    ], file: "trips.png")
    strip(.crawlSafeRoom, [
        Panel(caption: "The Recap Episode") { ctx, o, _ in trip(.recap, from: .crawlStudio, to: .crawlCircus, k: 0.2, ctx, o) },
        Panel(caption: "The Death Watch Wheel") { ctx, o, _ in trip(.wheel, from: .crawlDeathWatch, to: .crawlHavana, k: 0.5, ctx, o) },
        Panel(caption: "The Iron Tangle") { ctx, o, _ in trip(.ironTangle, from: .crawlTangle, to: .crawlHumpTown, k: 0.2, ctx, o) },
        Panel(caption: "The Club Doors") { ctx, o, _ in trip(.clubDoors, from: .crawlParade, to: .crawlDesperado, k: 0.3, ctx, o) },
    ], file: "trips-more.png")

    // The icon: Carl against Maestro in front of the Tutorial Guild's potion shelves (the safe room's TV and sign
    // crowded them); ICON_PLACE tries another place's key.
    let icon = canvas(1024, 1024, bg: nil) { ctx in
        let box = CGRect(x: 100, y: 100, width: 824, height: 824)
        let path = CGPath(roundedRect: box, cornerWidth: 185, cornerHeight: 185, transform: nil)
        let place = Location(ProcessInfo.processInfo.environment["ICON_PLACE"] ?? "crawlGuild")
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        let s = box.height / CGFloat(ph)
        let w = CGFloat(pw) * s
        ctx.draw(shot(place), in: CGRect(x: box.midX - w / 2, y: box.minY, width: w, height: box.height))
        ctx.restoreGState()
        let fs: CGFloat = 10.5, floorY: CGFloat = box.minY + 8 * s, headroom = 20.0
        let lx = 22.0, rx = 58.0
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        let left = Fighter(weapon: carl.weapon, x: lx, k: 1, top: headroom, side: 1, muzzle: carl.muzzle,
                           armoured: carl.armoured, pivot: carl.weaponPivot).dressed(as: carl)
        let right = Fighter(weapon: maestro.weapon, x: rx, k: 1, top: headroom, side: -1, muzzle: maestro.muzzle,
                            armoured: maestro.armoured, pivot: maestro.weaponPivot).dressed(as: maestro)
        let fxW = 80, fxH = Sprite.height + Int(headroom)
        let fx = PixelCanvas(fxW, fxH)
        let tIcon = Double(ProcessInfo.processInfo.environment["ICON_T"] ?? "") ?? 0.55
        drawFightFX(fx, t: tIcon, left: left, right: right)
        let (rl, rr) = fightRoles(carl.weapon, maestro.weapon)
        func body(_ c: PixelCanvas, _ bodyX: Double, flipped: Bool) {
            let x = flipped ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
            ctx.draw(c.makeImage()!, in: CGRect(x: box.minX + 10 + CGFloat(x) * fs, y: floorY - 8 * fs,
                                               width: CGFloat(Sprite.width) * fs, height: CGFloat(Sprite.height) * fs))
        }
        body(sprite(carl, t: tIcon, mode: .working, role: rl), lx, flipped: false)
        body(sprite(maestro, t: tIcon, mode: .working, role: rr, left: true), rx, flipped: true)
        ctx.draw(fx.makeImage()!, in: CGRect(x: box.minX + 10, y: floorY - 8 * fs, width: CGFloat(fxW) * fs, height: CGFloat(fxH) * fs))
        ctx.restoreGState()
        ctx.addPath(path); ctx.setStrokeColor(hexRGB(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
    }
    save(icon, "icon.png")
}
