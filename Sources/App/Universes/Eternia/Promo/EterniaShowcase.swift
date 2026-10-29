import AppKit

// Clawds of the Universe: By the power of Greyskull and back, For the honour of Greyskull, the rides, the moral of
// the story, Skeleclawd's retreat, a few of the trips, and the icon.
// The showcase README's own pictures, drawn by Tools/RenderShowcase (`build/rendershowcase docs eternia`) with its kit
// (`canvas`, `strip`, `sprite`, `at`, `tag`…). Compiled only into that tool.

struct EterniaShowcase: Showcase {
    let name = "eternia"
    func render() { eterniaShowcase() }
}

// MARK: Clawds of the Universe

/// A ride standing on the floor of a panel, centred on `x`.
private func ride(_ ride: Ride, _ ctx: CGContext, _ o: CGPoint, x: Double, ramp: Double, moving: Bool, t: Double = 0.4) {
    let c = PixelCanvas(Ride.width, ride.canvasHeight)
    drawRide(c, ride, ramp: ramp, engines: moving, gear: true, t: t)
    c.addOutline(C(0xFFFFFF, 0.92))
    put(c, ctx, x: x - Double(Ride.width) / 2, y: Double(ph - 8 - ride.canvasHeight + 1), unit: unit, frameH: ph, origin: o)
}

/// Someone in the middle of their change, `k` (0…1) through it, drawn as the overlay draws it: already their new
/// self, the power over them.
private func changing(_ into: Cast, k: Double, t: Double = 0.9) -> PixelCanvas {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    into.draw(c, t: t, mode: .idle, walking: false, role: .none, asSession: true)
    eterniaTransformation.draw(c, k, t, into)
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// Skeleclawd `s` (0…1) through his signature, which ends in the retreat once a fight is over.
private func signature(_ who: Cast, s: Double, t: Double = 0.6) -> PixelCanvas {
    let len = who.signatureLength ?? 4
    forcedHabit = HabitPlay(kind: .signature, e: len * s, length: len)
    defer { forcedHabit = nil }
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: .idle, walking: false, role: .none, asSession: true)
    c.flipHorizontally()
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// What someone says, in a cream box with dark ink over their head, as the overlay shows a line.
private func said(_ s: String, _ ctx: CGContext, centerX: CGFloat, bottom: CGFloat) {
    let text = NSAttributedString(string: s, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 15, weight: .heavy),
                                                          .foregroundColor: NSColor(srgbRed: 0.16, green: 0.11, blue: 0.08, alpha: 1)])
    let ts = text.size()
    let box = CGRect(x: centerX - ts.width / 2 - 8, y: bottom, width: ts.width + 16, height: ts.height + 6)
    let path = CGPath(roundedRect: box, cornerWidth: 6, cornerHeight: 6, transform: nil)
    ctx.addPath(path); ctx.setFillColor(hexRGB(0xFAF0D6)); ctx.fillPath()
    ctx.addPath(path); ctx.setStrokeColor(hexRGB(0x2A1C14)); ctx.setLineWidth(1.5); ctx.strokePath()
    NSGraphicsContext.saveGraphicsState()
    text.draw(at: NSPoint(x: box.minX + 8, y: box.minY + 3))
    NSGraphicsContext.restoreGraphicsState()
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
private func trip(_ kind: EterniaWipe, from: Location, to: Location, k: Double, _ ctx: CGContext, _ o: CGPoint) {
    let r = CGRect(x: o.x, y: o.y, width: CGFloat(pw) * unit, height: CGFloat(ph) * unit)
    EterniaTrip(kind: kind, from: from, to: to).draw(ctx, old: shot(from), new: shot(to, t: 2.1), k: k, in: r)
}

/// Two fighters squaring off, `t` into the fight, the effects between them.
private func duel(_ a: Cast, _ b: Cast, ax: Double, bx: Double, t: Double, _ ctx: CGContext, _ o: CGPoint) {
    let (ra, rb) = fightRoles(a.weapon, b.weapon)
    let left = Fighter(weapon: a.weapon, x: ax, k: 1, top: spriteTop, side: 1, muzzle: a.muzzle,
                       armoured: a.armoured, pivot: a.weaponPivot).dressed(as: a)
    let right = Fighter(weapon: b.weapon, x: bx, k: 1, top: spriteTop, side: -1, muzzle: b.muzzle,
                        armoured: b.armoured, pivot: b.weaponPivot).dressed(as: b)
    at(sprite(a, t: t, mode: .working, role: ra), ctx, o, bodyX: ax)
    at(sprite(b, t: t, mode: .working, role: rb, left: true), ctx, o, bodyX: bx, left: true)
    let fx = PixelCanvas(pw, ph)
    drawFightFX(fx, t: t, left: left, right: right)
    put(fx, ctx, x: 0, y: 0, unit: unit, frameH: ph, origin: o)
}

func eterniaShowcase() {
    Universe.shown = .eternia
    let heClawd = Cast.hero(EterniaHero.heClawd), addam = Cast.hero(EterniaHero.princeAddam)
    let sheClawd = Cast.hero(EterniaHero.sheClawd), adorra = Cast.hero(EterniaHero.adorra)
    let teelah = Cast.hero(EterniaHero.teelah), manAt = Cast.hero(EterniaHero.manAtClawds)
    let orkko = Cast.hero(EterniaHero.orkko)
    let skeleclawd = Cast.villain(EterniaVillain.skeleclawd), beast = Cast.villain(EterniaVillain.beastClawd)
    let hordakk = Cast.villain(EterniaVillain.hordakk)

    // By the power of Greyskull: /compact in Prince Addam's session, lightning out of the sky, a white-out, and
    // He-Clawd standing in the last of it.
    let px = 72.0
    strip(.eterniaGreyskull, [
        Panel(caption: "you type /compact") { ctx, o, sy in
            at(sprite(addam), ctx, o, bodyX: px)
            tag(addam.name, ctx, centerX: o.x + CGFloat(px) * unit, bottom: sy(spriteTop + 16), leader: true)
        },
        Panel(caption: "lightning out of the sky…") { ctx, o, _ in
            at(changing(heClawd, k: 0.12), ctx, o, bodyX: px)
        },
        Panel(caption: "…a white-out…") { ctx, o, _ in
            at(changing(heClawd, k: 0.3), ctx, o, bodyX: px)
        },
        Panel(caption: "…and He-Clawd") { ctx, o, sy in
            at(changing(heClawd, k: 0.75), ctx, o, bodyX: px)
            said("I have the power!", ctx, centerX: o.x + CGFloat(px) * unit, bottom: sy(spriteTop + 16))
        },
    ], file: "by-the-power.png")

    // For the honour of Greyskull: Adorra's spiral of gold and rainbow light, She-Clawd, and at the next compaction
    // the spiral unwinding back up off her.
    strip(.eterniaWhisperingWoods, [
        Panel(caption: "Adorra's session compacts") { ctx, o, sy in
            at(sprite(adorra), ctx, o, bodyX: px)
            tag(adorra.name, ctx, centerX: o.x + CGFloat(px) * unit, bottom: sy(spriteTop + 16), leader: true)
        },
        Panel(caption: "a spiral of light…") { ctx, o, _ in
            at(changing(sheClawd, k: 0.1), ctx, o, bodyX: px)
        },
        Panel(caption: "…and She-Clawd") { ctx, o, sy in
            at(changing(sheClawd, k: 0.75), ctx, o, bodyX: px)
            said("For the honour of Greyskull!", ctx, centerX: o.x + CGFloat(px) * unit, bottom: sy(spriteTop + 16))
        },
        Panel(caption: "the next one changes her back") { ctx, o, _ in
            at(changing(adorra, k: 0.5), ctx, o, bodyX: px)
        },
    ], file: "for-the-honour.png")

    // The rides: Teelah's agent is done and the Wind Raider sets down for her; Skeleclawd's side gets the Roton and
    // the Horde Hordakk's rocket.
    let tx = 26.0, rx = 100.0
    strip(.eterniaPalace, [
        Panel(caption: "the Wind Raider sets down") { ctx, o, sy in
            ride(.eterniaWindRaider, ctx, o, x: rx, ramp: 1, moving: false, t: 1.0)
            at(sprite(teelah), ctx, o, bodyX: tx)
            tag("Ship the release", ctx, centerX: o.x + CGFloat(tx) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "Teelah climbs aboard") { ctx, o, _ in
            ride(.eterniaWindRaider, ctx, o, x: rx, ramp: 1, moving: false, t: 1.2)
            at(sprite(teelah, t: 0.06, walking: true), ctx, o, bodyX: rx - 14, alpha: 0.8)
        },
    ], file: "wind-raider.png")
    strip(.eterniaSnakeMountain, [
        Panel(caption: "the Roton rolls in for Beast Clawd") { ctx, o, sy in
            ride(.eterniaRoton, ctx, o, x: rx, ramp: 0, moving: true, t: 0.6)
            at(sprite(beast), ctx, o, bodyX: tx)
            tag("Fix the flaky test", ctx, centerX: o.x + CGFloat(tx) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "Hordakk's rocket for the Horde") { ctx, o, sy in
            ride(.eterniaHordeRocket, ctx, o, x: rx, ramp: 1, moving: false, t: 1.0)
            at(sprite(hordakk), ctx, o, bodyX: tx)
            tag("Merge the branch", ctx, centerX: o.x + CGFloat(tx) * unit, bottom: sy(spriteTop + 18))
        },
    ], file: "roton-and-rocket.png")

    // The moral of the story: Man-At-Clawds' session finishes, and he steps forward with the lesson.
    let mx = 60.0
    strip(.eterniaWorkshop, [
        Panel(caption: "the work's done") { ctx, o, sy in
            at(sprite(manAt), ctx, o, bodyX: mx)
            at(sprite(orkko, left: true), ctx, o, bodyX: 118, left: true)
            tag(manAt.name, ctx, centerX: o.x + CGFloat(mx) * unit, bottom: sy(spriteTop + 16), leader: true)
        },
        Panel(caption: "and the moral of the story") { ctx, o, sy in
            at(sprite(manAt), ctx, o, bodyX: mx)
            at(sprite(orkko, left: true), ctx, o, bodyX: 118, left: true)
            said("Remember, kids: always write your tests!", ctx, centerX: o.x + 75 * unit, bottom: sy(spriteTop + 16))
        },
    ], file: "moral.png")

    // Skeleclawd's retreat: the fight with He-Clawd is over, he shakes his fist, vanishes in a purple puff and
    // leaves his line behind.
    let hx = 40.0, sx = 108.0
    func retreat(_ r: Double) -> Double { eterniaRetreatStart + r * (1 - eterniaRetreatStart) }
    strip(.eterniaSnakeMountain, [
        Panel(caption: "He-Clawd against Skeleclawd") { ctx, o, _ in
            duel(heClawd, skeleclawd, ax: hx, bx: sx, t: 0.5, ctx, o)
        },
        Panel(caption: "the fight's over…") { ctx, o, _ in
            at(sprite(heClawd), ctx, o, bodyX: hx)
            at(signature(skeleclawd, s: 0.5), ctx, o, bodyX: sx, left: true)
        },
        Panel(caption: "…a purple puff…") { ctx, o, _ in
            at(sprite(heClawd), ctx, o, bodyX: hx)
            at(signature(skeleclawd, s: retreat(0.1)), ctx, o, bodyX: sx, left: true)
        },
        Panel(caption: "…and he's gone") { ctx, o, sy in
            at(sprite(heClawd), ctx, o, bodyX: hx)
            at(signature(skeleclawd, s: retreat(0.4)), ctx, o, bodyX: sx, left: true)
            said("I'll get you for this, He-Clawd!", ctx, centerX: o.x + 95 * unit, bottom: sy(spriteTop + 16))
        },
    ], file: "retreat.png")

    // A few of the trips between places.
    strip(.eterniaGreyskull, [
        Panel(caption: "By the Power of Greyskull") { ctx, o, _ in
            trip(.greyskull, from: .eterniaPalace, to: .eterniaGreyskull, k: 0.4, ctx, o)
        },
        Panel(caption: "The Jawbridge") { ctx, o, _ in
            trip(.jawbridge, from: .eterniaGreyskull, to: .eterniaChamber, k: 0.35, ctx, o)
        },
        Panel(caption: "Orkko's Trick") { ctx, o, _ in
            trip(.orkko, from: .eterniaWorkshop, to: .eterniaAvion, k: 0.4, ctx, o)
        },
        Panel(caption: "The Havoc Staff") { ctx, o, _ in
            trip(.havoc, from: .eterniaPalace, to: .eterniaSnakeMountain, k: 0.35, ctx, o)
        },
    ], file: "trips.png")
    strip(.eterniaGreyskull, [
        Panel(caption: "The Wind Raider") { ctx, o, _ in
            trip(.windRaider, from: .eterniaPalace, to: .eterniaMysticMountains, k: 0.14, ctx, o)
        },
        Panel(caption: "The Horde Bat") { ctx, o, _ in
            trip(.hordeBat, from: .eterniaWhisperingWoods, to: .eterniaFrightZone, k: 0.3, ctx, o)
        },
        Panel(caption: "The Portal") { ctx, o, _ in
            trip(.portal, from: .eterniaGreyskull, to: .eterniaBrightMoon, k: 0.35, ctx, o)
        },
        Panel(caption: "Light Hope's Rainbow") { ctx, o, _ in
            trip(.lightHope, from: .eterniaBrightMoon, to: .eterniaCrystalCastle, k: 0.35, ctx, o)
        },
    ], file: "trips-more.png")

    // The icon: He-Clawd's Power Sword against Skeleclawd's Havoc Staff in front of Castle Greyskull.
    let icon = canvas(1024, 1024, bg: nil) { ctx in
        let box = CGRect(x: 100, y: 100, width: 824, height: 824)
        let path = CGPath(roundedRect: box, cornerWidth: 185, cornerHeight: 185, transform: nil)
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        // Castle Greyskull, chunky: the place scaled up so its height fills the icon, the castle in the middle.
        let s = box.height / CGFloat(ph)
        let w = CGFloat(pw) * s
        ctx.draw(shot(.eterniaGreyskull), in: CGRect(x: box.midX - w / 2, y: box.minY, width: w, height: box.height))
        ctx.restoreGState()
        // The fighters and the fight between them.
        let fs: CGFloat = 10.5, floorY: CGFloat = box.minY + 8 * s, headroom = 20.0
        let lx = 22.0, rx = 58.0
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        let left = Fighter(weapon: heClawd.weapon, x: lx, k: 1, top: headroom, side: 1, muzzle: heClawd.muzzle,
                           armoured: heClawd.armoured, pivot: heClawd.weaponPivot).dressed(as: heClawd)
        let right = Fighter(weapon: skeleclawd.weapon, x: rx, k: 1, top: headroom, side: -1, muzzle: skeleclawd.muzzle,
                            armoured: skeleclawd.armoured, pivot: skeleclawd.weaponPivot).dressed(as: skeleclawd)
        let fxW = 80, fxH = Sprite.height + Int(headroom)
        let fx = PixelCanvas(fxW, fxH)
        let tIcon = Double(ProcessInfo.processInfo.environment["ICON_T"] ?? "") ?? 0.55
        drawFightFX(fx, t: tIcon, left: left, right: right)
        let (rl, rr) = fightRoles(heClawd.weapon, skeleclawd.weapon)
        func body(_ c: PixelCanvas, _ bodyX: Double, flipped: Bool) {
            let x = flipped ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
            ctx.draw(c.makeImage()!, in: CGRect(x: box.minX + 10 + CGFloat(x) * fs, y: floorY - 8 * fs,
                                               width: CGFloat(Sprite.width) * fs, height: CGFloat(Sprite.height) * fs))
        }
        body(sprite(heClawd, t: tIcon, mode: .working, role: rl), lx, flipped: false)
        body(sprite(skeleclawd, t: tIcon, mode: .working, role: rr, left: true), rx, flipped: true)
        ctx.draw(fx.makeImage()!, in: CGRect(x: box.minX + 10, y: floorY - 8 * fs, width: CGFloat(fxW) * fs, height: CGFloat(fxH) * fs))
        ctx.restoreGState()
        ctx.addPath(path); ctx.setStrokeColor(hexRGB(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
    }
    save(icon, "icon.png")
}
