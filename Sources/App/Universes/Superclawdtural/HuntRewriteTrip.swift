import CoreGraphics
import Foundation

// Chuck's Rewrite (`HuntWipe.rewrite`, only with Chuck or Becky about): the old place turns into a page of the
// Supernatural novels, cream paper with the running head along the top, a chapter title and the scene typed out in
// lines, fed up over the picture a line at a time like paper into a typewriter. A cursor adds "ACTUALLY, NO." to the
// end of it; Chuck's hand comes in, in his maroon bathrobe sleeve, and scrunches the page up into a ball, creases and
// all, and tosses it away. A fresh page lies under it: the cursor types a new chapter onto it, and the page feeds on
// up and out of the top, the new place underneath.

extension HuntTrip {
    /// A frame `k` (0…1) of Chuck's Rewrite, over the whole of `r`. The page feeds up over the old place, a line at a
    /// time (0–0.16); the cursor types its last words (0.16–0.32); Chuck's hand reaches in (0.29–0.37) and crumples
    /// the page into a ball over the blank page beneath (0.36–0.56), then tosses it off to the right (0.56–0.68); the
    /// cursor types the new chapter (0.6–0.88) and the page feeds out of the top, the new place under it (0.88–1).
    func drawRewrite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let blink = Int(k * 40) % 2 == 0
        let step = max(6, h / 16)                                    // a line's feed, as the platen clicks round

        // The old page, and its last words being typed.
        let oldText = huntRewriteOld + (k < 0.16 ? "" : String(" ACTUALLY, NO.".prefix(Int(Self.span(k, 0.18, 0.32) * 14))))
        let typingOld = k >= 0.16 && k < 0.36

        if k < 0.36 {
            ctx.drawShot(old, in: r)
            // Fed up from the bottom in clicks, its top edge throwing a shadow on the place above it.
            let fed = Int(Self.ease(Self.span(k, 0, 0.16)) * Double(h + step - 1)) / step * step
            let top = max(0, h - fed)
            if top < h {
                c.oy = top
                huntRewritePage(c, chapter: "CHAPTER 4", text: oldText, cursor: typingOld && (blink || k < 0.32))
                c.oy = 0
                if top > 0 { c.rect(0, top - 2, w, 2, C(0x000000, 0.35)) }
            }
            art.show(ctx)
            huntRewriteHand(ctx, art, k: k, ball: nil)
            return
        }

        // From here the fresh page lies underneath: blank, then the new chapter typed onto it, then fed out of the top
        // in clicks, the new place under it.
        let out = Int(Self.ease(Self.span(k, 0.88, 1)) * Double(h + step - 1)) / step * step
        if out > 0 { ctx.drawShot(new, in: r) }
        let typed = Self.span(k, 0.6, 0.88)
        let newText = String(huntRewriteNew.prefix(Int(Double(huntRewriteNew.count) * Self.span(typed, 0.22, 0.95))))
        let title = String("CHAPTER 5".prefix(Int(9 * Self.span(typed, 0, 0.18))))
        c.oy = -out
        huntRewritePage(c, chapter: title, text: newText, cursor: k >= 0.58 && (blink || (typed > 0 && typed < 1)))
        c.oy = 0
        if out > 0 && out < h { c.rect(0, h - out, w, 2, C(0x000000, 0.35)) }
        art.show(ctx)

        // The old page, crumpling into a ball in Chuck's hand and thrown away.
        let crumple = Self.ease(Self.span(k, 0.36, 0.56))
        let toss = pow(Self.span(k, 0.56, 0.68), 1.6)
        if toss < 1 {
            let page = PixelCanvas(w, h)
            huntRewritePage(page, chapter: "CHAPTER 4", text: oldText, cursor: false)
            let ballR = Double(h) * (art.wide ? 0.32 : 0.22)
            let g = (x: Double(w) * 0.5 + toss * Double(w) * 0.62, y: Double(h) * 0.5 - sin(toss * .pi) * Double(h) * 0.25)
            let ballArt = HuntArt(r)
            huntRewriteCrumple(ballArt.c, page, crumple, centre: g, ballR: ballR)
            ballArt.show(ctx)
            huntRewriteHand(ctx, art, k: k, ball: (g.x, g.y, ballR))
        }
    }

    /// Chuck's hand: in from the right in his maroon bathrobe sleeve, a cuff at the wrist and Clawd's orange hand on the
    /// end, seen from the back: a palm, four fingers, each its own rounded stroke parted from the next by a dark line,
    /// bending at the knuckle, and a thumb over the top. The fingers reach out flat for the page, then curl down round
    /// the ball as it grips, and it carries the ball off. A dark edge round all of it, so it reads on paper and on a
    /// dark place alike.
    private func huntRewriteHand(_ ctx: CGContext, _ base: HuntArt, k: Double, ball: (x: Double, y: Double, r: Double)?) {
        let reachIn = Self.ease(Self.span(k, 0.29, 0.37))
        guard reachIn > 0 else { return }
        let art = HuntArt(base.r)
        let c = art.c, w = art.w, h = art.h
        let size = Double(h) * (art.wide ? 0.42 : 0.3)
        let u = size / 18                                            // the hand's own unit
        let rest = (x: Double(w) * 0.5 + size * 0.45, y: Double(h) * 0.5)
        var hx = Double(w) + size + (rest.x - Double(w) - size) * reachIn, hy = rest.y
        if let b = ball, k >= 0.36 { hx = b.x + b.r * 0.55 + size * 0.2; hy = b.y }
        let grip = Self.ease(Self.span(k, 0.36, 0.48))
        let outline = C(0x2A120E), skin = C(0xD97757), lit = C(0xE8957A), shade = C(0xB85F40)
        // The palm's left edge (the knuckles) at hx, its middle at hy.
        let px0 = hx, py0 = hy - 8 * u

        // The sleeve, out to the right edge, with folds and its lit top edge; the cuff turned back, lighter.
        let sx = Int(px0 + 9 * u), sy = Int(py0 - 1.5 * u), sh = Int(19 * u)
        if sx < w {
            c.rect(sx - 1, sy - 1, w - sx + 2, sh + 2, outline)
            c.rect(sx, sy, w - sx, sh, C(0x7C3A40))
            c.rect(sx, sy, w - sx, 2, C(0xA05A5E)); c.rect(sx, sy + sh - 3, w - sx, 2, C(0x52242A))
            for fx in stride(from: sx + Int(5 * u), to: w, by: max(6, Int(6 * u))) { c.rect(fx, sy + 3, 1, sh - 7, C(0x5E2A30)) }
            let cw = max(3, Int(2.5 * u))
            c.rect(sx - 1, sy - 2, cw + 2, sh + 4, outline); c.rect(sx, sy - 1, cw, sh + 2, C(0xA05A5E)); c.rect(sx, sy - 1, 1, sh + 2, C(0xC07A7C))
        }

        /// A rounded stroke from (x0, y0) to (x1, y1), `t` thick: its dark edge, the skin, and a lit line along its top.
        func stroke(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ t: Double, edge: Bool) {
            if edge { huntLine(c, x0, y0, x1, y1, outline, t / 2 + 1) } else {
                huntLine(c, x0, y0, x1, y1, skin, t / 2)
                huntLine(c, x0, y0 - t * 0.3, x1, y1 - t * 0.3, lit, 0.5)
            }
        }
        // The palm: a rounded block behind the knuckles.
        let palm = (x: px0 + 1.5 * u, y: py0 + 1 * u, w: 8.5 * u, h: 15 * u)
        c.rect(Int(palm.x) - 1, Int(palm.y) - 1, Int(palm.w) + 2, Int(palm.h) + 2, outline)
        c.rect(Int(palm.x), Int(palm.y), Int(palm.w), Int(palm.h), skin)
        c.rect(Int(palm.x), Int(palm.y), Int(palm.w), 1, lit)
        c.rect(Int(palm.x + palm.w) - 1, Int(palm.y), 1, Int(palm.h), shade)
        // The fingers, the little one at the bottom first, so each lies over the one below it with a dark line
        // between them. Each a first joint out from the knuckle and a second bending down as it grips.
        let fingers: [(y: Double, len1: Double, len2: Double, a: Double)] = [
            (14, 5.5, 3.5, 186), (10, 7, 4.5, 181), (6, 7.5, 5, 178), (2.2, 7, 4.5, 174),
        ]
        let ft = 3.6 * u
        for f in fingers {
            // Angles in degrees, 180 pointing straight out to the left, more bending it down.
            let kx = px0 + 2 * u, ky = py0 + (f.y + 0.6) * u
            let a1 = (f.a + 10 * grip) * .pi / 180, a2 = (f.a + 10 * grip + 75 * grip) * .pi / 180
            let jx = kx + cos(a1) * f.len1 * u, jy = ky - sin(a1) * f.len1 * u
            let tx = jx + cos(a2) * f.len2 * u, ty = jy - sin(a2) * f.len2 * u
            // Its dark edge over the finger below it, then the skin, a crease at the knuckle and the joint.
            stroke(kx, ky, jx, jy, ft, edge: true); stroke(jx, jy, tx, ty, ft * 0.92, edge: true)
            stroke(kx, ky, jx, jy, ft, edge: false); stroke(jx, jy, tx, ty, ft * 0.92, edge: false)
            c.px(Int(jx.rounded()), Int((jy + ft * 0.2).rounded()), shade)
            c.px(Int(kx.rounded()), Int((ky + ft * 0.2).rounded()), shade)
        }
        // The thumb, over the top of the hand, angled up and out, curling in as it grips.
        let ta = (215 - 30 * grip) * .pi / 180
        let tbx = px0 + 6 * u, tby = py0 + 1 * u
        let tex = tbx + cos(ta) * 7.5 * u, tey = tby + sin(ta) * 7.5 * u
        stroke(tbx, tby, tex, tey, 3.8 * u, edge: true)
        stroke(tbx, tby, tex, tey, 3.8 * u, edge: false)
        art.show(ctx)
    }
}

/// The old chapter, printed on the page Chuck throws away.
private let huntRewriteOld = "DEAN SLAMMED THE TRUNK OF THE IMPALA. SALT, IRON, THE SHOTGUN, THE GOOD FLASHLIGHT. SAM WAS ALREADY "
    + "READING, BECAUSE SAM WAS ALWAYS ALREADY READING. SOMETHING HERE HAD BEEN WAITING FOR THEM, AND IT WAS NOT HAPPY ABOUT "
    + "IT. THE LIGHTS FLICKERED. OF COURSE THEY DID. DEAN SAID IT WAS PROBABLY NOTHING. IT WAS NEVER NOTHING. A FLOORBOARD "
    + "CREAKED. SAM LOOKED AT DEAN. DEAN LOOKED AT SAM. SOMEWHERE A DOG BARKED, AND THEN, VERY SUDDENLY, IT DID NOT. THEY "
    + "SPLIT UP, WHICH EVERYONE KNOWS IS A TERRIBLE IDEA. DEAN CHECKED HIS WATCH, THEN THE EXITS, THEN THE PIE SITUATION. "
    + "THE AIR WENT COLD. SAM SAID THEY HAD TO GO. DEAN SAID FIVE MORE MINUTES. THE WALLS DISAGREED. THE BROTHERS RAN, "
    + "THEN STOPPED, THEN RAN AGAIN, AND THE NIGHT CLOSED IN BEHIND THEM LIKE A DOOR."

/// The new chapter, typed onto the fresh page: short, so it types at a pace you can read.
private let huntRewriteNew = "LET'S TRY THAT AGAIN. THEY ARRIVED. SAM NOTICED. DEAN DID NOT."

/// A page of the novels onto `c`, over the whole of it: cream paper with a yellowed edge, CARVER EDLUND and
/// SUPERNATURAL along the top over a rule, the page number, the chapter title and `text` wrapped into lines with room
/// between them, and a block cursor after its last letter.
private func huntRewritePage(_ c: PixelCanvas, chapter: String, text: String, cursor: Bool) {
    let w = c.w, h = c.h
    let ink = C(0x2A2420), head = C(0x8A7A5E)
    c.rect(0, 0, w, h, C(0xEEE6D0))
    for i in 0..<(w * h / 40) { c.px(Int(noise(i * 3 + 700) * Double(w)), Int(noise(i * 3 + 701) * Double(h)), C(0xE2D8BE)) }
    c.rect(0, 0, w, 2, C(0xD8CCA8)); c.rect(0, h - 2, w, 2, C(0xD8CCA8)); c.rect(0, 0, 2, h, C(0xD8CCA8)); c.rect(w - 2, 0, 2, h, C(0xD8CCA8))
    let mx = max(10, w * 10 / 100)
    huntTripText(c, mx, 4, "CARVER EDLUND", head, 1)
    huntTripCentred(c, w / 2, 4, "SUPERNATURAL", head, 1)
    huntTripText(c, w - mx - huntTripTextWidth("213", 1), 4, "213", head, 1)
    c.rect(mx, 11, w - 2 * mx, 1, C(0xC8BC9C))
    huntTripCentred(c, w / 2, 15, chapter, ink, 2)

    // The text, wrapped to the page's width, a line every ten rows, as many lines as fit.
    let perLine = max(10, (w - 2 * mx) / 4), lead = 10
    var lines: [String] = [], line = ""
    for word in text.split(separator: " ", omittingEmptySubsequences: false) {
        if line.count + word.count + 1 > perLine { lines.append(line); line = String(word) }
        else { line = line.isEmpty ? String(word) : line + " " + word }
    }
    lines.append(line)
    let first = 32, room = max(1, (h - first - 4) / lead)
    if lines.count > room { lines = Array(lines.suffix(room)) }
    for (i, l) in lines.enumerated() { huntTripText(c, mx, first + i * lead, l, ink, 1) }
    if cursor {
        let last = lines.last ?? ""
        let cx = mx + huntTripTextWidth(last, 1) + (last.isEmpty ? 0 : 2)
        c.rect(cx, first + (lines.count - 1) * lead - 1, 3, 7, C(0x2A2420))
    }
}

/// `page` scrunched `q` (0…1) of the way into a ball of radius `ballR` round `centre`, onto `c`: it shrinks from its
/// own rectangle into a lumpy round, its edge going jagged, broken into creased facets that catch the light or fall
/// into shade (more and more as it scrunches), a dark crease between them and a dark edge round it.
private func huntRewriteCrumple(_ c: PixelCanvas, _ page: PixelCanvas, _ q: Double, centre g: (x: Double, y: Double), ballR: Double) {
    let w = c.w, h = c.h
    let hw = Double(w) / 2, hh = Double(h) / 2
    // The facets: fixed points spread over the page, in page coordinates.
    let seeds = (0..<18).map { (noise($0 * 7 + 400) * Double(w), noise($0 * 7 + 401) * Double(h), 0.72 + 0.36 * noise($0 * 7 + 402)) }
    func rectEdge(_ a: Double) -> Double {
        let ca = abs(cos(a)), sa = abs(sin(a))
        return min(ca > 1e-6 ? hw / ca : 1e9, sa > 1e-6 ? hh / sa : 1e9)
    }
    let shrink = pow(q, 0.8)
    let bx0 = max(0, Int(g.x - max(hw, ballR * 1.4)) - 2), bx1 = min(w, Int(g.x + max(hw, ballR * 1.4)) + 2)
    let by0 = max(0, Int(g.y - max(hh, ballR * 1.4)) - 2), by1 = min(h, Int(g.y + max(hh, ballR * 1.4)) + 2)
    guard bx0 < bx1, by0 < by1 else { return }
    for y in by0..<by1 {
        for x in bx0..<bx1 {
            let dx = Double(x) - g.x, dy = Double(y) - g.y
            let rho = (dx * dx + dy * dy).squareRoot(), a = atan2(dy, dx)
            let lump = 1 + 0.18 * (noise(Int((a + .pi) * 5) + 450) - 0.5) + 0.1 * (noise(Int((a + .pi) * 13) + 470) - 0.5)
            let jag = q * (1 - q) * 6 * (noise(Int((a + .pi) * 40) + 490) - 0.5)
            let edge = rectEdge(a) * (1 - shrink) + ballR * lump * shrink + jag
            guard rho < edge else { continue }
            // Where on the flat page this point came from.
            let f = rho / edge * rectEdge(a)
            var sx = hw + cos(a) * f, sy = hh + sin(a) * f
            var best = 1e9, second = 1e9, shade = 1.0
            for s in seeds {
                let d = (sx - s.0) * (sx - s.0) + (sy - s.1) * (sy - s.1)
                if d < best { second = best; best = d; shade = s.2 } else if d < second { second = d }
            }
            // A little wobble in where it samples, so the lines of type kink at the creases.
            sx += (shade - 0.9) * 10 * q; sy += (shade - 0.9) * 6 * q
            let ix = max(0, min(w - 1, Int(sx))), iy = max(0, min(h - 1, Int(sy)))
            var col = unpremultiplied(page, (iy * w + ix) * 4)
            let k = 1 + (shade - 1) * min(1, q * 1.6)
            col = Px(r: UInt8(min(255, Double(col.r) * k)), g: UInt8(min(255, Double(col.g) * k)), b: UInt8(min(255, Double(col.b) * k)), a: 255)
            let crease = second.squareRoot() - best.squareRoot() < 1.6 * Double(w) / 256 && q > 0.08
            if crease { col = lerp(col, C(0x6A5A40), min(0.7, q)) }
            if rho > edge - 1.2 { col = C(0x5A4A34) }
            c.px(x, y, col)
        }
    }
}
