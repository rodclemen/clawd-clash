import AppKit

// The trailer's own two scenes, before the shared shots. The opening is the Collapse trip itself, stretched to the
// length of a title sequence. The set piece runs from Odette's sofa through a trapdoor into the Juicer's gym.

/// The title sequence's and the set piece's lengths.
let crawlIntroLength = 9.0, crawlBossLength = 9.5

/// The Collapse: Carl's street, then the whole of the trip, landing in a safe room.
func crawlIntro(_ ctx: CGContext, local: Double, t: Double) {
    guard let old = shotImage({ blit(place(.crawlSeattle, floorRows: 30, t: t), $0) }),
          let new = shotImage({ blit(place(.crawlSafeRoom, floorRows: 30, t: t), $0) }) else { return }
    ComicTransition(CrawlTrip(kind: .collapse, from: .crawlSeattle, to: .crawlSafeRoom))
        .draw(ctx, old: old, new: new, k: clamp(local / crawlIntroLength), in: fullRect)
    crawlTumble(ctx, local: local, t: t)
}

/// Carl and Donut tumbling down through the System blue, end over end, landing on the safe room's floor on the thump
/// at 6.1 s and staying there.
private func crawlTumble(_ ctx: CGContext, local: Double, t: Double) {
    let k = clamp((local - 5.1) / 1.0)
    guard k > 0 else { return }
    for (who, x, turns) in [(Cast.hero(CrawlHero.carl), 120.0, 2.0), (Cast.hero(CrawlHero.donut), 200.0, -3.0)] {
        let a = Actor(cast: who, x: x, facing: 1, mode: .idle)
        let cx = x * S, cy = Double(H) - (groundY - 22) * S
        ctx.saveGState()
        // The canvas is y-up: from over the top of the frame down to where they stand. Whole turns, so they land upright.
        ctx.translateBy(x: cx, y: lerp(Double(H) + 150, cy, k * k))
        ctx.rotate(by: CGFloat(k * turns * 2 * .pi))
        ctx.translateBy(x: -cx, y: -cy)
        draw(a, ctx, t: t)
        ctx.restoreGState()
    }
}

/// The System's blue box, big, in the middle of the frame, with one line in its block letters.
private func crawlBossBox(_ ctx: CGContext, _ line: String, alpha: Double) {
    let s = 2, w = crawlTextWidth(line, scale: s) + 16, h = 5 * s + 12
    let c = PixelCanvas(fxW, fxH), x = (fxW - w) / 2, y = 34
    c.rect(x - 2, y - 2, w + 4, h + 4, C(0x3A8CFF, 0.4 * alpha))
    c.rect(x, y, w, h, C(0x0E2A6A, 0.96 * alpha))
    c.rect(x, y, w, 1, C(0x6AB4FF, alpha)); c.rect(x, y, 1, h, C(0x6AB4FF, alpha))
    c.rect(x, y + h - 1, w, 1, C(0x2A64C8, alpha)); c.rect(x + w - 1, y, 1, h, C(0x2A64C8, alpha))
    crawlText(c, x + 8, y + 7, line, C(0xFFD84A, alpha), scale: s)
    blit(c, ctx)
}

/// From the sofa to the boss room: Carl and Donut on air until the floor opens at 2.6 s and they drop out of shot; the
/// Juicer's gym from 3.4 s with the lights gone red, Carl and Donut against him and Mongo leaping in; at 7.2 s he falls
/// and the System says so.
func crawlBoss(_ ctx: CGContext, local: Double, t: Double) {
    let carl = Cast.hero(CrawlHero.carl), donut = Cast.hero(CrawlHero.donut), mongo = Cast.hero(CrawlHero.mongo)
    if local < 3.4 {
        let studio = place(.crawlStudio, floorRows: 30, t: t), fall = max(0, local - 2.6)
        blit(studio, ctx)
        if fall > 0 {
            // The sofa's gone: the striped backdrop from higher up, over where it stood.
            ctx.saveGState()
            ctx.clip(to: CGRect(x: 380, y: 186, width: 400, height: 124))
            blit(studio, ctx, dy: 130)
            ctx.restoreGState()
            // The trapdoor: a pit in the floor, its two leaves swung down and hanging at the sides.
            let open = clamp(fall / 0.2), half = 200 * open, mid = 580.0
            ctx.setFillColor(CGColor(gray: 0.02, alpha: 1)); ctx.fill(CGRect(x: mid - half, y: 0, width: half * 2, height: 174))
            ctx.setFillColor(CGColor(red: 0.33, green: 0.25, blue: 0.2, alpha: 1))
            ctx.fill(CGRect(x: mid - half, y: 0, width: 18, height: 174)); ctx.fill(CGRect(x: mid + half - 18, y: 0, width: 18, height: 174))
            ctx.setFillColor(CGColor(red: 0.55, green: 0.45, blue: 0.34, alpha: 1)); ctx.fill(CGRect(x: mid - half, y: 168, width: half * 2, height: 6))
        }
        for (who, x) in [(carl, 80.0), (donut, 112.0)] {
            var a = Actor(cast: who, x: x, facing: 1, session: false, mode: .idle)
            a.sitting = true
            a.lift = 8 - fall * fall * 260
            draw(a, ctx, t: t)
        }
        return
    }
    let e = local - 3.4
    blit(place(.crawlGym, floorRows: 30, t: t), ctx)
    ctx.setFillColor(CGColor(red: 0.8, green: 0.05, blue: 0.05, alpha: 0.16 + 0.05 * sin(t * 6))); ctx.fill(fullRect)
    let dead = clamp((e - 3.8) / 0.5)
    var carlA = Actor(cast: carl, x: 90, facing: 1, role: .zap), donutA = Actor(cast: donut, x: 140, facing: 1, role: .zap)
    var boss = Actor(cast: .villain(CrawlVillain.juicer), x: 240, facing: -1, role: .zap)
    carlA.lift = max(0, (0.3 - e) * 200); donutA.lift = max(0, (0.4 - e) * 200)
    boss.alpha = 1 - dead
    var leaper = Actor(cast: mongo, x: 40 + clamp((e - 1.4) / 0.9) * 150, facing: 1, role: .none)
    leaper.lift = e > 1.4 && e < 2.3 ? sin((e - 1.4) / 0.9 * .pi) * 46 : 0
    leaper.alpha = clamp((e - 1.3) / 0.1)
    draw(boss, ctx, t: t); draw(carlA, ctx, t: t); draw(donutA, ctx, t: t); draw(leaper, ctx, t: t)
    if dead == 0 { drawFX([(carlA, boss), (donutA, boss)], ctx, t: t) }
    let box = clamp((e - 4.0) / 0.15)
    if box > 0 { crawlBossBox(ctx, "BOSS DEFEATED", alpha: box) }
    caption("Mongo is appalled.", ctx, local: e, start: 4.7, y: 590, size: 64, color: yellow)
}
