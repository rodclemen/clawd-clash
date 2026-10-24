import CoreGraphics
import Foundation

// Chuck's Rewrite (`HuntWipe.rewrite`, only with Chuck or Becky about): the old place turns into a page of the
// Supernatural novels, cream paper with the running head along the top, a chapter title and the scene typed out in
// lines. A cursor adds "ACTUALLY, NO." to the end of it; Chuck's hand comes in, in his maroon bathrobe sleeve, and
// scrunches the page up into a ball, creases and all, and tosses it away. A fresh page lies under it: the cursor types
// a new chapter onto it, and the page fades into the new place.

extension HuntTrip {
    /// A frame `k` (0…1) of Chuck's Rewrite, over the whole of `r`. The old place washes into a printed page (0–0.16);
    /// the cursor types its last words (0.16–0.32); Chuck's hand reaches in (0.29–0.37) and crumples the page into a
    /// ball over the blank page beneath (0.36–0.56), then tosses it off to the right (0.56–0.68); the cursor types the
    /// new chapter (0.62–0.86) and the page fades into the new place (0.86–1).
    func drawRewrite(_ ctx: CGContext, old: CGImage, new: CGImage, k: Double, in r: CGRect) {
        let art = HuntArt(r)
        let c = art.c, w = art.w, h = art.h
        let blink = Int(k * 40) % 2 == 0

        // The old page, and its last words being typed.
        let oldText = huntRewriteOld + (k < 0.16 ? "" : String(" ACTUALLY, NO.".prefix(Int(Self.span(k, 0.18, 0.32) * 14))))
        let typingOld = k >= 0.16 && k < 0.36
        let wash = (Self.span(k, 0, 0.16) * 8).rounded() / 8

        if k < 0.36 {
            ctx.drawShot(old, in: r)
            huntRewritePage(c, chapter: "CHAPTER 4", text: oldText, cursor: typingOld && (blink || k < 0.32))
            art.show(ctx, alpha: wash)
            huntRewriteHand(ctx, art, k: k, ball: nil)
            return
        }

        // From here the fresh page lies underneath: blank, then the new chapter typed onto it.
        let fade = (Self.span(k, 0.86, 1) * 8).rounded() / 8
        if fade > 0 { ctx.drawShot(new, in: r) }
        let typed = Self.span(k, 0.62, 0.86)
        let newText = String(huntRewriteNew.prefix(Int(Double(huntRewriteNew.count) * Self.span(typed, 0.2, 1))))
        let title = String("CHAPTER 5".prefix(Int(9 * Self.span(typed, 0, 0.18))))
        huntRewritePage(c, chapter: title, text: newText, cursor: k >= 0.6 && k < 0.9 && (blink || (typed > 0 && typed < 1)))
        art.show(ctx, alpha: 1 - fade)

        // The old page, crumpling into a ball in Chuck's hand and thrown away.
        let crumple = Self.ease(Self.span(k, 0.36, 0.56))
        let toss = pow(Self.span(k, 0.56, 0.68), 1.6)
        if toss < 1 {
            let page = PixelCanvas(w, h)
            huntRewritePage(page, chapter: "CHAPTER 4", text: oldText, cursor: false)
            let ballR = Double(h) * 0.2
            let g = (x: Double(w) * 0.5 + toss * Double(w) * 0.62, y: Double(h) * 0.5 - sin(toss * .pi) * Double(h) * 0.25)
            let ballArt = HuntArt(r)
            huntRewriteCrumple(ballArt.c, page, crumple, centre: g, ballR: ballR)
            ballArt.show(ctx)
            huntRewriteHand(ctx, art, k: k, ball: (g.x, g.y, ballR))
        }
    }

    /// Chuck's hand: in from the right in his maroon bathrobe sleeve, a cuff at the wrist and Clawd's orange hand on the
    /// end, closing round the ball and carrying it off. A dark edge round all of it, so it reads on paper and on a dark
    /// place alike.
    private func huntRewriteHand(_ ctx: CGContext, _ base: HuntArt, k: Double, ball: (x: Double, y: Double, r: Double)?) {
        let reachIn = Self.ease(Self.span(k, 0.29, 0.37))
        guard reachIn > 0 else { return }
        let art = HuntArt(base.r)
        let c = art.c, w = art.w, h = art.h
        let size = Int(Double(h) * 0.26)
        let rest = (x: Double(w) * 0.5 + Double(h) * 0.12, y: Double(h) * 0.5)
        var hx = Double(w + size) + (rest.x - Double(w + size)) * reachIn, hy = rest.y
        if let b = ball, k >= 0.36 { hx = b.x + b.r * 0.6; hy = b.y }
        let grip = Self.span(k, 0.36, 0.46)
        let x = Int(hx.rounded()), y = Int(hy.rounded()) - size / 2
        let outline = C(0x2A120E)

        // The sleeve, out to the right edge, sloping up a little, with folds and its lit top edge.
        let sx = x + size - 2, sh = size + 4
        c.rect(sx - 1, y - 3, w - sx + 2, sh + 2, outline)
        c.rect(sx, y - 2, w - sx, sh, C(0x7C3A40))
        c.rect(sx, y - 2, w - sx, 2, C(0xA05A5E)); c.rect(sx, y + sh - 4, w - sx, 2, C(0x52242A))
        for fx in stride(from: sx + 7, to: w, by: 9) { c.rect(fx, y + 1, 1, sh - 6, C(0x5E2A30)) }
        // The cuff: a band of the robe turned back, lighter.
        c.rect(sx - 1, y - 3, 5, sh + 2, outline); c.rect(sx, y - 2, 3, sh, C(0xA05A5E)); c.rect(sx, y - 2, 1, sh, C(0xC07A7C))

        // The hand: Clawd's orange, a block with the fingers curled round the front of the ball and the thumb over
        // the top; it closes a little as it grips.
        let fingers = Int(Double(size) * (0.45 + 0.15 * grip))
        let palmX = x + size - fingers - 2
        c.rect(palmX - 1, y - 1, fingers + 4, size + 2, outline)
        c.rect(palmX, y, fingers + 2, size, C(0xD97757))
        c.rect(palmX, y, fingers + 2, 1, C(0xE8957A)); c.rect(palmX + fingers + 1, y, 1, size, C(0xB85F40))
        // Four curled fingers reaching left over the ball, each a stub with a knuckle line.
        let fw = max(3, size / 4), reach = Int(Double(size) * (0.35 - 0.12 * grip))
        for i in 0..<4 {
            let fy = y + i * fw
            let len = reach - (i == 0 || i == 3 ? 2 : 0)
            c.rect(palmX - len - 1, fy, len + 1, fw, outline)
            c.rect(palmX - len, fy + 1, len, fw - 2, C(0xD97757))
            c.rect(palmX - len, fy + 1, len, 1, C(0xE8957A))
            c.px(palmX - 1, fy + fw / 2, C(0xB85F40))
        }
        // The thumb, along the top.
        c.rect(palmX - reach / 2 - 1, y - fw / 2 - 1, reach / 2 + 4, fw, outline)
        c.rect(palmX - reach / 2, y - fw / 2, reach / 2 + 3, fw - 2, C(0xD97757))
        c.rect(palmX - reach / 2, y - fw / 2, reach / 2 + 3, 1, C(0xE8957A))
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

/// The new chapter, typed onto the fresh page.
private let huntRewriteNew = "LET'S TRY THAT AGAIN. THEY ARRIVED, AND EVERYTHING WAS EXACTLY WHERE IT WAS SUPPOSED TO BE. "
    + "SAM NOTICED. DEAN DID NOT. THE WRITER WAS PLEASED."

/// A page of the novels onto `c`, over the whole of it: cream paper with a yellowed edge, CARVER EDLUND and
/// SUPERNATURAL along the top over a rule, the page number, the chapter title and `text` wrapped into lines, and a
/// block cursor after its last letter.
private func huntRewritePage(_ c: PixelCanvas, chapter: String, text: String, cursor: Bool) {
    let w = c.w, h = c.h
    let ink = C(0x2A2420), head = C(0x8A7A5E)
    c.rect(0, 0, w, h, C(0xEEE6D0))
    for i in 0..<(w * h / 40) { c.px(Int(noise(i * 3 + 700) * Double(w)), Int(noise(i * 3 + 701) * Double(h)), C(0xE2D8BE)) }
    c.rect(0, 0, w, 2, C(0xD8CCA8)); c.rect(0, h - 2, w, 2, C(0xD8CCA8)); c.rect(0, 0, 2, h, C(0xD8CCA8)); c.rect(w - 2, 0, 2, h, C(0xD8CCA8))
    let mx = max(8, w * 8 / 100)
    huntTripText(c, mx, 4, "CARVER EDLUND", head, 1)
    huntTripCentred(c, w / 2, 4, "SUPERNATURAL", head, 1)
    huntTripText(c, w - mx - huntTripTextWidth("213", 1), 4, "213", head, 1)
    c.rect(mx, 11, w - 2 * mx, 1, C(0xC8BC9C))
    huntTripCentred(c, w / 2, 15, chapter, ink, 2)

    // The text, wrapped to the page's width, as many lines as fit.
    let perLine = max(10, (w - 2 * mx) / 4)
    var lines: [String] = [], line = ""
    for word in text.split(separator: " ", omittingEmptySubsequences: false) {
        if line.count + word.count + 1 > perLine { lines.append(line); line = String(word) }
        else { line = line.isEmpty ? String(word) : line + " " + word }
    }
    lines.append(line)
    let first = 31, room = max(1, (h - first - 4) / 8)
    if lines.count > room { lines = Array(lines.suffix(room)) }
    for (i, l) in lines.enumerated() { huntTripText(c, mx, first + i * 8, l, ink, 1) }
    if cursor {
        let last = lines.last ?? ""
        let cx = mx + huntTripTextWidth(last, 1) + (last.isEmpty ? 0 : 2)
        c.rect(cx, first + (lines.count - 1) * 8 - 1, 3, 7, C(0x2A2420))
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
