import AppKit

// Superclawdtural: Baby picking someone up, Back from Hell, Clawdstiel's personal space, "Bitch." "Jerk.", the
// devil's trap and the angel blade, Abaddon's grip, a few of the trips, and the icon.
// The showcase README's own pictures, drawn by Tools/RenderShowcase (`build/rendershowcase docs hunters`) with its kit
// (`canvas`, `strip`, `sprite`, `at`, `tag`…). Compiled only into that tool.

struct HuntShowcase: Showcase {
    let name = "hunters"
    func render() { huntShowcase() }
}

// MARK: Superclawdtural

/// Baby standing on the floor of a panel, centred on `x`.
private func impala(_ ctx: CGContext, _ o: CGPoint, x: Double, ramp: Double, moving: Bool, t: Double = 0.4) {
    let ride = Ride.huntImpala
    let c = PixelCanvas(Ride.width, ride.canvasHeight)
    drawRide(c, ride, ramp: ramp, engines: moving, gear: true, t: t)
    c.addOutline(C(0xFFFFFF, 0.92))
    put(c, ctx, x: x - Double(Ride.width) / 2, y: Double(ph - 8 - ride.canvasHeight + 1), unit: unit, frameH: ph, origin: o)
}

/// Back from Hell round someone standing at `bodyX`, `k` (0…1) through it: the claw marks, the pit, the cross and the
/// dust behind them, then their own picture sunk, punching up or climbing out, as the overlay draws it.
private func backFromHell(_ who: Cast, k: Double, _ ctx: CGContext, _ o: CGPoint, bodyX: Double, t: Double = 1.1) {
    let s = HuntBackFromHell(k: k)
    let fx = PixelCanvas(Sprite.width, Sprite.height)
    huntDrawBackFromHell(fx, s, t: t)
    put(fx, ctx, x: bodyX - Sprite.bodyCenterX, y: spriteTop, unit: unit, frameH: ph, origin: o)
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: 0.3, mode: .idle, walking: false, role: .rest, asSession: true)
    huntBackFromHellTouch(c, s, t: t)
    c.addOutline(C(0xFFFFFF, 0.92))
    at(c, ctx, o, bodyX: bodyX)
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

/// Someone at their own practice set (`huntBespokeDrills`), `e` seconds into a set `length` long, outlined.
private func drilling(_ who: Cast, e: Double, length: Double, left: Bool = false) -> PixelCanvas {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.drawDrill(c, DrillPlay(kind: .bespoke, e: e, length: length, seed: 7), t: e)
    if left { c.flipHorizontally() }
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// Clawdstiel's feathers drifting down where he stood, `k` (0…1) through their fall, round `bodyX`.
private func feathers(_ ctx: CGContext, _ o: CGPoint, bodyX: Double, k: Double) {
    let c = PixelCanvas(30, Sprite.height)
    huntDrawFeathers(c, k: k, t: 0.8)
    put(c, ctx, x: bodyX - 15, y: spriteTop, unit: unit, frameH: ph, origin: o)
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
private func trip(_ kind: HuntWipe, from: Location, to: Location, k: Double, _ ctx: CGContext, _ o: CGPoint) {
    let r = CGRect(x: o.x, y: o.y, width: CGFloat(pw) * unit, height: CGFloat(ph) * unit)
    HuntTrip(kind: kind).draw(ctx, old: shot(from), new: shot(to, t: 2.1), k: k, in: r)
}

func huntShowcase() {
    Universe.shown = .hunters
    let dean = Cast.hero(HuntHero.deanWinclawdster), sam = Cast.hero(HuntHero.samWinclawdster)
    let cas = Cast.hero(HuntHero.clawdstiel), bobby = Cast.hero(HuntHero.bobbyClawdsinger)
    let clawdley = Cast.villain(HuntVillain.clawdley), abaddon = Cast.villain(HuntVillain.abaddon)
    let meg = Cast.villain(HuntVillain.megMasters)

    // Baby: Sam's agent is done, the Impala rolls up outside the motel, the back door swings open and the trunk lid
    // comes up on the arsenal, Sam gets in, and she drives off, leaving Meg on the forecourt.
    let samX = 26.0, babyX = 102.0
    strip(.huntMotel, [
        Panel(caption: "1 · Baby rolls up") { ctx, o, sy in
            impala(ctx, o, x: babyX, ramp: 0, moving: true)
            at(sprite(sam), ctx, o, bodyX: samX)
            tag("Verify the fix", ctx, centerX: o.x + CGFloat(samX) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "2 · the door and the trunk open") { ctx, o, sy in
            impala(ctx, o, x: babyX, ramp: 1, moving: false, t: 1.0)
            at(sprite(sam), ctx, o, bodyX: samX)
            tag("Verify the fix", ctx, centerX: o.x + CGFloat(samX) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "3 · Sam gets in the back") { ctx, o, _ in
            impala(ctx, o, x: babyX, ramp: 1, moving: false, t: 1.2)
            at(sprite(sam, t: 0.06, walking: true), ctx, o, bodyX: babyX - 14, alpha: 0.8)
        },
        Panel(caption: "4 · and she drives off") { ctx, o, _ in
            impala(ctx, o, x: 150, ramp: 0, moving: true, t: 0.9)
            at(sprite(meg), ctx, o, bodyX: 30)
        },
    ], file: "impala.png")

    // Back from Hell: /compact, and Dean is raked by hellhounds nobody can see and dragged down into a red pit; a
    // cross goes up over the grave, his fist punches up through it, and he climbs out and dusts himself off.
    let name = "Dean Winclawdster", dx = 72.0
    strip(.huntCrossroads, [
        Panel(caption: "you type /compact") { ctx, o, sy in
            backFromHell(dean, k: 0.1, ctx, o, bodyX: dx)
            tag(name, ctx, centerX: o.x + CGFloat(dx) * unit, bottom: sy(spriteTop + 16), leader: true)
        },
        Panel(caption: "the hellhounds drag him down…") { ctx, o, _ in
            backFromHell(dean, k: 0.3, ctx, o, bodyX: dx)
        },
        Panel(caption: "…a fist through the grave…") { ctx, o, _ in
            backFromHell(dean, k: 0.62, ctx, o, bodyX: dx)
        },
        Panel(caption: "same session, same face") { ctx, o, sy in
            let s = HuntBackFromHell(k: 0.93)
            backFromHell(dean, k: 0.93, ctx, o, bodyX: dx)
            said(s.caption ?? "", ctx, centerX: o.x + CGFloat(dx) * unit, bottom: sy(spriteTop + 16))
        },
    ], file: "back-from-hell.png")

    // Personal space: Clawdstiel vanishes in a flutter of wings, a few feathers left drifting where he stood, and
    // turns up right behind Dean, a step too close. Dean turns round and tells him.
    let deanX = 46.0, casX = 120.0
    strip(.huntSalvage, [
        Panel(caption: "Dean, minding his own business") { ctx, o, _ in
            at(sprite(dean), ctx, o, bodyX: deanX)
            at(sprite(cas, left: true), ctx, o, bodyX: casX, left: true)
        },
        Panel(caption: "a flutter of wings…") { ctx, o, _ in
            at(sprite(dean), ctx, o, bodyX: deanX)
            feathers(ctx, o, bodyX: casX, k: 0.3)
        },
        Panel(caption: "…and he's right behind him") { ctx, o, sy in
            huntFlutterForced = 0.6
            defer { huntFlutterForced = nil }
            at(sprite(cas), ctx, o, bodyX: deanX - 21)
            at(sprite(dean), ctx, o, bodyX: deanX)
            feathers(ctx, o, bodyX: casX, k: 0.75)
            said("Hello, Dean.", ctx, centerX: o.x + CGFloat(deanX - 21) * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "he turns round") { ctx, o, sy in
            at(sprite(dean, left: true), ctx, o, bodyX: deanX + 6, left: true)
            at(sprite(cas), ctx, o, bodyX: deanX - 21)
            said("Cas. Personal space.", ctx, centerX: o.x + CGFloat(deanX + 10) * unit, bottom: sy(spriteTop + 18))
        },
    ], file: "personal-space.png")

    // "Bitch." "Jerk.": the brothers standing about, Dean says it, and Sam answers a beat later.
    strip(.huntRoadhouse, [
        Panel(caption: "Dean turns to his brother") { ctx, o, sy in
            at(sprite(dean), ctx, o, bodyX: 50)
            at(sprite(sam, left: true), ctx, o, bodyX: 104, left: true)
            said("Bitch.", ctx, centerX: o.x + 50 * unit, bottom: sy(spriteTop + 18))
        },
        Panel(caption: "and Sam, a beat later") { ctx, o, sy in
            at(sprite(dean), ctx, o, bodyX: 50)
            at(sprite(sam, left: true), ctx, o, bodyX: 104, left: true)
            said("Jerk.", ctx, centerX: o.x + 104 * unit, bottom: sy(spriteTop + 18))
        },
    ], file: "bitch-jerk.png")

    // The devil's trap: Bobby shakes the can, paints the trap on the floor stroke by stroke, steps back and nods as it
    // glints red, and scuffs it out with his boot for the next go.
    let trapL = 9.0, bx = 52.0
    strip(.huntBunker, [
        Panel(caption: "Bobby shakes the can…") { ctx, o, _ in
            at(drilling(bobby, e: 0.9, length: trapL), ctx, o, bodyX: bx)
        },
        Panel(caption: "…paints a devil's trap…") { ctx, o, _ in
            at(drilling(bobby, e: 4.2, length: trapL), ctx, o, bodyX: bx)
        },
        Panel(caption: "…steps back: it holds") { ctx, o, _ in
            at(drilling(bobby, e: 7.6, length: trapL), ctx, o, bodyX: bx)
        },
        Panel(caption: "and scuffs it out again") { ctx, o, _ in
            at(drilling(bobby, e: 8.3, length: trapL), ctx, o, bodyX: bx)
        },
    ], file: "devils-trap.png")

    // The angel blade: Clawdstiel's set by the book, a thrust, a rising slash, and on the last thrust a flash lights
    // the dark and his wings' shadow flares out wide.
    let bladeL = 8.0, cx = 66.0, sc = min(1.25, max(1, bladeL / 7))
    strip(.huntEmpty, [
        Panel(caption: "Clawdstiel thrusts…") { ctx, o, _ in
            at(drilling(cas, e: 1.02 * sc, length: bladeL), ctx, o, bodyX: cx)
        },
        Panel(caption: "…slashes up…") { ctx, o, _ in
            at(drilling(cas, e: 1.96 * sc, length: bladeL), ctx, o, bodyX: cx)
        },
        Panel(caption: "…the last thrust: a flash…") { ctx, o, _ in
            at(drilling(cas, e: 3.85 * sc, length: bladeL), ctx, o, bodyX: cx)
        },
        Panel(caption: "…and the wings") { ctx, o, _ in
            at(drilling(cas, e: 4.6 * sc, length: bladeL), ctx, o, bodyX: cx)
        },
    ], file: "angel-blade.png")

    // Abaddon's grip: her fist out and glowing, she hauls Dean off the ground in a crimson coil, holds him there
    // kicking, and drops him.
    let ax = 40.0, vx = 108.0
    func grip(_ t: Double) -> (CGContext, CGPoint, (Double) -> CGFloat) -> Void {
        { ctx, o, _ in
            let (ra, rv) = fightRoles(abaddon.weapon, dean.weapon)
            let lift = gripHold(t) * gripHeight
            let left = Fighter(weapon: abaddon.weapon, x: ax, k: 1, top: spriteTop, side: 1, muzzle: abaddon.muzzle,
                               armoured: abaddon.armoured, pivot: abaddon.weaponPivot).dressed(as: abaddon)
            let right = Fighter(weapon: dean.weapon, x: vx, k: 1, top: spriteTop - lift, side: -1, muzzle: dean.muzzle,
                                armoured: dean.armoured, pivot: dean.weaponPivot).dressed(as: dean)
            at(sprite(abaddon, t: t, mode: .working, role: ra), ctx, o, bodyX: ax)
            let kick = gripHold(t) > 0.6 ? (noise(Int(t * 24)) > 0.5 ? 1.0 : -1.0) : 0
            at(sprite(dean, t: t, mode: .working, role: rv, left: true), ctx, o, bodyX: vx + kick, left: true, lift: lift)
            let fx = PixelCanvas(pw, ph)
            drawFightFX(fx, t: t, left: left, right: right)
            put(fx, ctx, x: 0, y: 0, unit: unit, frameH: ph, origin: o)
        }
    }
    strip(.huntHell, [
        Panel(caption: "Abaddon raises her fist…", draw: grip(2.4)),
        Panel(caption: "…and Dean leaves the ground", draw: grip(0.2)),
        Panel(caption: "held there, kicking", draw: grip(1.2)),
        Panel(caption: "and dropped", draw: grip(2.2)),
    ], file: "grip.png")

    // A few of the trips between places.
    strip(.huntRoadhouse, [
        Panel(caption: "Headlights") { ctx, o, _ in trip(.headlights, from: .huntMotel, to: .huntCrossroads, k: 0.5, ctx, o) },
        Panel(caption: "Devil's Trap") { ctx, o, _ in trip(.devilsTrap, from: .huntSalvage, to: .huntBunker, k: 0.5, ctx, o) },
        Panel(caption: "Smoke Out") { ctx, o, _ in trip(.smokeOut, from: .huntRoadhouse, to: .huntHell, k: 0.72, ctx, o) },
        Panel(caption: "Angel Light") { ctx, o, _ in trip(.angelLight, from: .huntBunker, to: .huntHeaven, k: 0.72, ctx, o) },
    ], file: "trips.png")
    strip(.huntRoadhouse, [
        Panel(caption: "The Road So Far") { ctx, o, _ in trip(.roadSoFar, from: .huntBunker, to: .huntCrossroads, k: 0.25, ctx, o) },
        Panel(caption: "Salt and Burn") { ctx, o, _ in trip(.saltAndBurn, from: .huntLawrence, to: .huntStull, k: 0.5, ctx, o) },
        Panel(caption: "Hellhound") { ctx, o, _ in trip(.hellhound, from: .huntDiner, to: .huntLawrence, k: 0.55, ctx, o) },
        Panel(caption: "Leviathan Maw") { ctx, o, _ in trip(.leviathanMaw, from: .huntBunker, to: .huntRoman, k: 0.4, ctx, o) },
    ], file: "trips-more.png")

    // The icon: Dean's Colt against Clawdley's red lightning at the crossroads at dusk, a devil's trap painted on the
    // dirt between them, a signpost and dead trees on the skyline.
    let icon = canvas(1024, 1024, bg: nil) { ctx in
        let box = CGRect(x: 100, y: 100, width: 824, height: 824)
        let path = CGPath(roundedRect: box, cornerWidth: 185, cornerHeight: 185, transform: nil)
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        // The sky, chunky: night at the top, a rusty amber dusk low down behind the skyline.
        let px = 12, n = 824 / px + 1
        for j in 0..<n {
            let v = Double(j) / Double(n)
            let col: UInt32 = v > 0.86 ? 0x07080E : v > 0.76 ? 0x0E1020 : v > 0.67 ? 0x22182A : v > 0.58 ? 0x4A2420
                : v > 0.5 ? 0x7A3A1C : v > 0.42 ? 0xA85A24 : 0xC8782C
            ctx.setFillColor(hexRGB(col))
            ctx.fill(CGRect(x: box.minX, y: box.minY + CGFloat(j * px), width: box.width, height: CGFloat(px)))
        }
        for i in 0..<30 {
            ctx.setFillColor(hexRGB(0xE6ECFF, CGFloat(0.35 + 0.5 * noise(i * 3 + 2))))
            ctx.fill(CGRect(x: box.minX + CGFloat(noise(i * 3)) * box.width, y: box.minY + 560 + CGFloat(noise(i * 3 + 1)) * 260,
                            width: 8, height: 8))
        }
        // The skyline in silhouette: flat fields, dead trees, telegraph poles, and the crossroads signpost.
        let dark = hexRGB(0x0C0A0C)
        ctx.setFillColor(dark)
        ctx.fill(CGRect(x: box.minX, y: box.minY + 228, width: box.width, height: 36))
        for (x, h) in [(60.0, 210.0), (740.0, 240.0)] {   // dead trees, bare branches
            ctx.fill(CGRect(x: box.minX + CGFloat(x), y: box.minY + 228, width: 22, height: CGFloat(h)))
            ctx.fill(CGRect(x: box.minX + CGFloat(x) - 50, y: box.minY + 228 + CGFloat(h) - 80, width: 50, height: 12))
            ctx.fill(CGRect(x: box.minX + CGFloat(x) - 50, y: box.minY + 228 + CGFloat(h) - 80, width: 12, height: 50))
            ctx.fill(CGRect(x: box.minX + CGFloat(x) + 22, y: box.minY + 228 + CGFloat(h) - 120, width: 48, height: 12))
            ctx.fill(CGRect(x: box.minX + CGFloat(x) + 58, y: box.minY + 228 + CGFloat(h) - 120, width: 12, height: 44))
        }
        for x in [240.0, 560.0] {   // telegraph poles
            ctx.fill(CGRect(x: box.minX + CGFloat(x), y: box.minY + 228, width: 14, height: 250))
            ctx.fill(CGRect(x: box.minX + CGFloat(x) - 30, y: box.minY + 456, width: 74, height: 10))
        }
        ctx.fill(CGRect(x: box.minX + 400, y: box.minY + 228, width: 16, height: 190))   // the signpost
        ctx.fill(CGRect(x: box.minX + 330, y: box.minY + 384, width: 150, height: 24))
        ctx.fill(CGRect(x: box.minX + 380, y: box.minY + 344, width: 120, height: 22))
        // The dirt road, and the floor line.
        ctx.setFillColor(hexRGB(0x1A130E)); ctx.fill(CGRect(x: box.minX, y: box.minY, width: box.width, height: 228))
        ctx.setFillColor(hexRGB(0x8A5A34)); ctx.fill(CGRect(x: box.minX, y: box.minY + 222, width: box.width, height: 6))
        // The devil's trap on the dirt, seen from the side: a red ring flattened into an ellipse, a star across it.
        let tc = CGPoint(x: box.minX + 412, y: box.minY + 130), trx: CGFloat = 300, tr_y: CGFloat = 70
        ctx.setStrokeColor(hexRGB(0xC8281C)); ctx.setLineWidth(12)
        ctx.strokeEllipse(in: CGRect(x: tc.x - trx, y: tc.y - tr_y, width: trx * 2, height: tr_y * 2))
        ctx.setLineWidth(8)
        let pts = (0..<5).map { i -> CGPoint in
            let a = Double(i) * 2 * .pi / 5 + .pi / 2
            return CGPoint(x: tc.x + CGFloat(cos(a)) * (trx - 22), y: tc.y + CGFloat(sin(a)) * (tr_y - 8))
        }
        for i in 0..<5 {
            ctx.move(to: pts[i]); ctx.addLine(to: pts[(i + 2) % 5])
        }
        ctx.strokePath()
        ctx.restoreGState()
        // The fighters and the fight between them.
        let s: CGFloat = 10.5, floorY: CGFloat = box.minY + 222, headroom = 20.0
        let lx = 22.0, rx = 58.0
        ctx.saveGState(); ctx.addPath(path); ctx.clip()
        let left = Fighter(weapon: dean.weapon, x: lx, k: 1, top: headroom, side: 1, muzzle: dean.muzzle,
                           armoured: dean.armoured, pivot: dean.weaponPivot).dressed(as: dean)
        let right = Fighter(weapon: clawdley.weapon, x: rx, k: 1, top: headroom, side: -1, muzzle: clawdley.muzzle,
                            armoured: clawdley.armoured, pivot: clawdley.weaponPivot).dressed(as: clawdley)
        let fxW = 80, fxH = Sprite.height + Int(headroom)
        let fx = PixelCanvas(fxW, fxH)
        let tIcon = Double(ProcessInfo.processInfo.environment["ICON_T"] ?? "") ?? 0.55
        drawFightFX(fx, t: tIcon, left: left, right: right)
        let (rl, rr) = fightRoles(dean.weapon, clawdley.weapon)
        func body(_ c: PixelCanvas, _ bodyX: Double, flipped: Bool) {
            let x = flipped ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
            ctx.draw(c.makeImage()!, in: CGRect(x: box.minX + 10 + CGFloat(x) * s, y: floorY - 8 * s,
                                               width: CGFloat(Sprite.width) * s, height: CGFloat(Sprite.height) * s))
        }
        body(sprite(dean, t: tIcon, mode: .working, role: rl), lx, flipped: false)
        body(sprite(clawdley, t: tIcon, mode: .working, role: rr, left: true), rx, flipped: true)
        ctx.draw(fx.makeImage()!, in: CGRect(x: box.minX + 10, y: floorY - 8 * s, width: CGFloat(fxW) * s, height: CGFloat(fxH) * s))
        ctx.restoreGState()
        ctx.addPath(path); ctx.setStrokeColor(hexRGB(0xFFFFFF, 0.12)); ctx.setLineWidth(3); ctx.strokePath()
    }
    save(icon, "icon.png")
}
