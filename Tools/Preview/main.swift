import AppKit

// Sprite and location contact sheets, for checking art while drawing it.
//
//   Tools/Preview/build.sh                         compiles it into build/preview
//   build/preview cast  out.png ironMan thor ...   every pose of each character (or a batch: heroes1 … villains9,
//                                                  ringsHeroes1 …, a universe's key or title, all). A name two
//                                                  universes share (sandman) is an error: dc:sandman says which
//   build/preview fight out.png ironMan ultron     two characters fighting, a few moments of it, with the effects
//   build/preview drills out.png luke ironMan ...  each solo practice set it does, at a few moments (blank: not one of its);
//                                                  DRILL=bespoke shows just that one, at more moments
//   build/preview place out.png avengersTower ...  locations at window size and at screen-saver size
//   build/preview place out.png <universe> --flipped  each place of its that can turn over (`SceneFlip`) the right
//                                                  way up, mid-turn and upside down, a crew on it with their names
//   build/preview magic out.png [names…]           every magic user's stream side by side, at a few moments
//   build/preview rides out.png [rides…]           the ships, landed and flying (all, or only those named, e.g. gtx)
//   build/preview edges out.txt ironMan ...        every moment solid art touches the frame's top or side edges, where
//                                                  its outline is cut off (shots and exits leaving on purpose show too);
//                                                  --flipped checks the bottom edge too, the top when a scene turns over
//   build/preview ids out.txt                      every saved id and what it means, as text: each universe's facts
//                                                  (what the hook reads), every character, place, magic variant and
//                                                  adoption. The universe-modules refactor must leave it identical.
//
// SCALE=4 makes cells bigger (default 3). Clawd Slayer: MOON=full (or MOON=new) forces the full moon on or off for
// Ozz and Veruka; GUISE=0…3 shows the First Evil as one of its guises (the Old Master, the Mayor, Glory, Adam), GUISE_K
// how far through it (0…1, default 0.5).

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else {
    print("usage: preview cast|fight|drills|magic|place|rides|edges <out.png> [names…]")
    print("  a name two universes share is an error; put the universe's key in front: dc:sandman, marvel:sandman")
    exit(2)
}
let mode = args[0], out = args[1]
/// `--flipped`: the scene turned over (`SceneFlip`), for `place` and `edges`.
let flipped = args.contains("--flipped")
let names = Array(args.dropFirst(2)).filter { $0 != "--flipped" }
let scale = CGFloat(Double(ProcessInfo.processInfo.environment["SCALE"] ?? "") ?? 3)
if let moon = ProcessInfo.processInfo.environment["MOON"] { slayerMoonOverride = moon == "full" }
if let g = ProcessInfo.processInfo.environment["GUISE"].flatMap(Int.init) {
    slayerForcedGuise = (g, Double(ProcessInfo.processInfo.environment["GUISE_K"] ?? "") ?? 0.5)
}
// The baseline (Tools/Baseline) needs the same pictures every run: the cantina's band is otherwise picked at random.
if ProcessInfo.processInfo.environment["BASELINE"] != nil { starClawdsBandForced = false }
let bg = CGColor(red: 0.13, green: 0.14, blue: 0.19, alpha: 1)

func sheet(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    ctx.setFillColor(bg); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
    print("wrote \(out)")
}

func label(_ s: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat = 12, color: NSColor = .white) {
    NSAttributedString(string: s, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold),
                                               .foregroundColor: color]).draw(at: NSPoint(x: x, y: y))
}

/// A canvas drawn at `scale`, its bottom-left at (x, y), with a faint ground line under the feet (row 44).
func put(_ c: PixelCanvas, _ ctx: CGContext, x: CGFloat, y: CGFloat, outline: Bool = true) {
    if outline { c.addOutline(C(0xFFFFFF, 0.92)) }
    guard let img = c.makeImage() else { return }
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    ctx.fill(CGRect(x: x, y: y + CGFloat(c.h - 44) * scale, width: CGFloat(c.w) * scale, height: 1))
    ctx.draw(img, in: CGRect(x: x, y: y, width: CGFloat(c.w) * scale, height: CGFloat(c.h) * scale))
}

/// Names as typed, without case, spaces or punctuation: "Darth Vapor" and darthvapor are the same.
func squashed(_ s: String) -> String { s.lowercased().filter { $0.isLetter || $0.isNumber } }

/// Characters by batch name (each universe's art files: heroes1…, slayerVillains3…, ringsHem; see `PreviewInfo`), by
/// universe (its key, `slayer`, or its name), `all` (the first universe), by enum case name (ironMan, vader, superman…)
/// or by the name shown on screen ("Darth Vapor"). A name two universes share (sandman, enchantress) is an error that
/// lists them: say which with the universe's key in front, `dc:sandman` or `marvel:sandman`.
/// Universes can't be mixed in one call.
func cast(named n: String) -> [Cast] {
    var batches: [String: [Cast]] = ["all": Theme.of(Universe.allCases[0]).cast]
    for u in Universe.allCases {
        batches[u.key] = Theme.of(u).cast
        batches[squashed(u.title)] = Theme.of(u).cast
        for b in u.module.preview.batches { batches[b.name] = b.cast }
    }
    if let b = batches[n] ?? batches[squashed(n)] { return b }
    // `key:name` looks in that universe alone (keys from its universe.conf).
    var universes = Universe.allCases, name = n
    if let colon = n.firstIndex(of: ":") {
        let key = String(n[..<colon])
        name = String(n[n.index(after: colon)...])
        guard let u = Universe.allCases.first(where: { $0.key.lowercased() == key.lowercased() }) else {
            print("unknown universe: \(key) (one of \(Universe.allCases.map(\.key).joined(separator: ", ")))")
            exit(2)
        }
        universes = [u]
    }
    // An enum case name first, else the name shown on screen.
    var found = universes.compactMap { u in u.module.preview.caseName(name).map { (u, $0) } }
    if found.isEmpty {
        found = universes.compactMap { u in Theme.of(u).cast.first(where: { squashed($0.name) == squashed(name) }).map { (u, $0) } }
    }
    if found.count > 1 {
        print("\(n) is in \(found.count) universes: say which, \(found.map { "\($0.0.key):\(name)" }.joined(separator: " or "))")
        exit(2)
    }
    if let (_, c) = found.first { return [c] }
    print("unknown character: \(n)")
    exit(2)
}

/// How many pixels a fighter is lifted at `t` by its foe's telekinetic grip (`Magic.grip`), if the foe has one.
func gripLift(by foe: Cast, _ foeRole: FightRole, _ t: Double) -> Int {
    guard case .zap = foeRole, foe.persona.magic.grip else { return 0 }
    return Int((gripHold(t) * gripHeight).rounded())
}

switch mode {
case "ids":
    var lines: [String] = []
    func ids(_ s: Set<Int>) -> String { s.sorted().map(String.init).joined(separator: ",") }
    for u in Universe.allCases {
        lines.append("universe \(u.rawValue) key=\(u.key) title=\(u.title) base=\(u.base) villains=\(u.villainCount) heroes=\(u.heroCount) hem=\(u.hem)")
        lines.append("  agentOnly=\(ids(u.agentOnly)) claudeSide=\(u.claudeSide.map(String.init) ?? "nil") rivals=\(ids(u.rivals))")
        lines.append("  guises=\(u.guises.map(ids).joined(separator: " | ")) homebound=\(u.homebound.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" })")
        lines.append("  abductees=\(ids(u.abductees)) regenerations=\(u.regenerations) transforms=\(u.transforms) morals=\(u.morals.count) released=\(u.isReleased)")
        for c in Theme.of(u).cast {
            let p = c.persona
            lines.append("  cast \(c.id) \(c.name) weapon=\(p.weapon) variant=\(p.magic.variant) drills=\(c.drills.map { "\($0)" }.sorted())")
        }
        for l in Location.all(in: u) { lines.append("  place \(l.rawValue) \(l.name)") }
    }
    // How every id is shown in each universe (`adopt`): what a session saved in one universe looks like in another.
    let every = Universe.allCases.flatMap { u in (0..<u.villainCount).map { u.base + $0 } + (0..<u.heroCount).map { u.base + StatusStore.heroBase + $0 } }
    for u in Universe.allCases { lines.append("adopt \(u.key) " + every.map { "\($0)>\(u.adopt($0))" }.joined(separator: " ")) }
    lines.append("magicVariants " + magicVariants.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: ","))
    try! (lines.joined(separator: "\n") + "\n").write(toFile: out, atomically: true, encoding: .utf8)
    print("wrote \(out)")
case "edges":
    // Every moment a character's solid art touches the top, left or right edge of its 72×52 frame, where the white
    // outline gets cut off: 80 moments each of standing, walking, waiting, cheering, flinching and sitting, and 40 of
    // every idle habit and its signature move. `out` is a text report (one line per state that touches, with how many
    // moments); a picture of each state's first such moment goes next to it, as <out>-<name>-<state>.png.
    let who = names.flatMap(cast(named:))
    var lines: [String] = []
    for c in who {
        var hits: [String: Int] = [:]
        func probe(_ state: String, _ draw: (PixelCanvas) -> Void) {
            let n = PixelCanvas(Sprite.width, Sprite.height)
            draw(n)
            var edges = Set<String>()
            for x in 0..<n.w where n.buf[x * 4 + 3] >= 250 { edges.insert("top") }
            // Turned over, the frame's bottom row is its top: whatever's solid there is cut off against the ceiling.
            if flipped { for x in 0..<n.w where n.buf[((n.h - 1) * n.w + x) * 4 + 3] >= 250 { edges.insert("bottom (the top, upside down)") } }
            for y in 0..<n.h {
                if n.buf[(y * n.w) * 4 + 3] >= 250 { edges.insert("left") }
                if n.buf[(y * n.w + n.w - 1) * 4 + 3] >= 250 { edges.insert("right") }
            }
            guard !edges.isEmpty else { return }
            let key = "\(state), \(edges.sorted().joined(separator: " and "))"
            if hits[key] == nil {
                n.addOutline(C(0xFFFFFF, 0.92))
                let base = (out as NSString).deletingPathExtension
                if let img = n.makeImage() {
                    try? NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])?
                        .write(to: URL(fileURLWithPath: "\(base)-\(squashed(c.name))-\(squashed(state)).png"))
                }
            }
            hits[key, default: 0] += 1
        }
        for i in 0..<80 {
            let t = Double(i) * 0.037
            probe("standing") { c.draw($0, t: t, mode: .idle, walking: false, role: .none, asSession: true) }
            probe("walking") { c.draw($0, t: t, mode: .working, walking: true, role: .none, asSession: false, airborne: c.motion == .fly) }
            probe("waiting") { c.draw($0, t: t, mode: .waiting, walking: false, role: .none, urgent: true, asSession: true) }
            probe("cheering") { c.draw($0, t: t, mode: .working, walking: false, role: .cheer, asSession: false) }
            probe("hit") { c.draw($0, t: t, mode: .working, walking: false, role: .hit, asSession: false) }
            probe("sitting") { c.draw($0, t: t, mode: .idle, walking: false, role: .none, sitting: true, asSession: true) }
        }
        var kinds: [IdleHabit] = [.glance, .shuffle, .bounce]
        switch c.weapon {
        case .saber: kinds.append(.flourish)
        case .blaster: if c.persona.handGun { kinds.append(.checkWeapon) }
        case .lightning: kinds.append(.crackle)
        case .none: break
        }
        if c.signatureLength != nil { kinds.append(.signature) }
        for kind in kinds {
            let len = kind == .signature ? c.signatureLength ?? kind.length : kind.length
            for i in 0..<40 {
                forcedHabit = HabitPlay(kind: kind, e: len * Double(i) / 40, length: len)
                probe(kind == .signature ? "signature" : "\(kind) habit") {
                    c.draw($0, t: 0.3 + Double(i) * 0.05, mode: .idle, walking: false, role: .none, asSession: true)
                }
                forcedHabit = nil
            }
        }
        for (k, v) in hits.sorted(by: { $0.key < $1.key }) { lines.append("\(c.name): \(k) (\(v) moments)") }
    }
    let report = lines.isEmpty ? "Nothing touches the frame's edge." : lines.joined(separator: "\n")
    try! (report + "\n").write(toFile: out, atomically: true, encoding: .utf8)
    print(report)
    print("wrote \(out)")

case "cast":
    let who = names.flatMap(cast(named:))
    // Each pose: a title and how to draw it.
    typealias Shot = (title: String, draw: (Cast, PixelCanvas) -> Void)
    func habit(_ kind: IdleHabit, _ k: Double) -> (Cast, PixelCanvas) -> Void {
        { who, c in
            let len = kind == .signature ? who.signatureLength ?? kind.length : kind.length
            forcedHabit = HabitPlay(kind: kind, e: len * k, length: len)
            who.draw(c, t: 0.3, mode: .idle, walking: false, role: .none, asSession: true)
            forcedHabit = nil
        }
    }
    let shots: [Shot] = [
        ("idle", { $0.draw($1, t: 0.3, mode: .idle, walking: false, role: .none, asSession: true) }),
        ("walk 1", { $0.draw($1, t: 0.05, mode: .working, walking: true, role: .none, asSession: false, airborne: $0.motion == .fly) }),
        ("walk 2", { $0.draw($1, t: 0.18, mode: .working, walking: true, role: .none, asSession: false, airborne: $0.motion == .fly) }),
        ("working alone", { $0.draw($1, t: 0.3, mode: .working, walking: false, role: .none, asSession: false) }),
        ("working alone 2", { $0.draw($1, t: 0.62, mode: .working, walking: false, role: .none, asSession: false) }),
        ("fight (stream not shown)", { who, c in
            let role: FightRole
            switch who.weapon {
            case .saber: role = .duel
            case .blaster: role = .shoot(offset: 0)
            case .lightning: role = .zap
            case .none: role = .cheer
            }
            who.draw(c, t: 0.45, mode: .working, walking: false, role: role, asSession: false)
        }),
        ("hit", { $0.draw($1, t: 0.3, mode: .working, walking: false, role: .hit, asSession: false) }),
        ("waiting", { $0.draw($1, t: 0.3, mode: .waiting, walking: false, role: .none, urgent: true, asSession: true) }),
        ("sitting", { $0.draw($1, t: 0.3, mode: .idle, walking: false, role: .none, sitting: true, asSession: true) }),
        ("weapon habit", { who, c in
            switch who.weapon {
            case .saber: habit(.flourish, 0.45)(who, c)
            case .blaster: who.persona.handGun ? habit(.checkWeapon, 0.7)(who, c) : habit(.bounce, 0.2)(who, c)
            case .lightning: habit(.crackle, 0.5)(who, c)
            case .none: habit(.bounce, 0.2)(who, c)
            }
        }),
        ("moonwalk", { who, c in who.universe.module.moonwalkers.contains(who) ? habit(.moonwalk, 0.3)(who, c) : () }),
        ("signature ¼", habit(.signature, 0.25)),
        ("signature ½", habit(.signature, 0.5)),
        ("signature ¾", habit(.signature, 0.75)),
    ]
    let cellW = CGFloat(Sprite.width) * scale + 8, cellH = CGFloat(Sprite.height) * scale + 22, nameW: CGFloat = 130
    let w = Int(nameW + cellW * CGFloat(shots.count)), h = Int(cellH * CGFloat(who.count) + 24)
    save(sheet(w, h) { ctx in
        for (j, s) in shots.enumerated() { label(s.title, nameW + CGFloat(j) * cellW + 4, CGFloat(h) - 18) }
        for (i, c) in who.enumerated() {
            let y = CGFloat(h) - 24 - cellH * CGFloat(i + 1)
            let p = c.persona
            label(c.name, 6, y + cellH / 2 + 4, size: 13)
            var kind = "\(p.weapon)".replacingOccurrences(of: "saber", with: "melee").replacingOccurrences(of: "blaster", with: "ranged")
                .replacingOccurrences(of: "lightning", with: "magic")
            if p.motion != .walk { kind += " · \(p.motion)" }
            label(kind, 6, y + cellH / 2 - 12, size: 10, color: NSColor(white: 0.7, alpha: 1))
            for (j, s) in shots.enumerated() {
                if s.title.hasPrefix("signature"), c.signatureLength == nil { continue }
                let canvas = PixelCanvas(Sprite.width, Sprite.height)
                s.draw(c, canvas)
                put(canvas, ctx, x: nameW + CGFloat(j) * cellW, y: y + 4)
            }
        }
    })

case "drills":
    let who = names.flatMap(cast(named:))
    // DRILL=bespoke (any one drill): just that one, at more moments.
    let only = ProcessInfo.processInfo.environment["DRILL"].flatMap { n in Drill.allCases.first { "\($0)" == n } }
    let moments = only == nil ? [1.3, 2.05, 2.6, 4.45] : stride(from: 0.4, to: 7.6, by: 0.6).map { $0 }
    let cols = (only.map { [$0] } ?? Drill.allCases).flatMap { d in moments.map { (d, $0) } }
    let cellW = CGFloat(Sprite.width) * scale + 4, cellH = CGFloat(Sprite.height) * scale + 22, nameW: CGFloat = 130
    let w = Int(nameW + cellW * CGFloat(cols.count)), h = Int(cellH * CGFloat(who.count) + 24)
    save(sheet(w, h) { ctx in
        for (j, col) in cols.enumerated() where col.1 == moments[0] { label("\(col.0)", nameW + CGFloat(j) * cellW + 4, CGFloat(h) - 18) }
        for (i, c) in who.enumerated() {
            let y = CGFloat(h) - 24 - cellH * CGFloat(i + 1)
            label(c.name, 6, y + cellH / 2, size: 13)
            for (j, col) in cols.enumerated() where c.drills.contains(col.0) {
                let canvas = PixelCanvas(Sprite.width, Sprite.height)
                forcedDrill = DrillPlay(kind: col.0, e: col.1, length: 8, seed: 3)
                c.draw(canvas, t: 10 + col.1, mode: .working, walking: false, role: .none, asSession: true)
                forcedDrill = nil
                put(canvas, ctx, x: nameW + CGFloat(j) * cellW, y: y)
            }
        }
    })
case "fight":
    guard names.count == 2 else { print("fight needs two characters"); exit(2) }
    let a = cast(named: names[0])[0], b = cast(named: names[1])[0]
    let (ra, rb) = fightRoles(a.weapon, b.weapon)
    let close = fightIsCloseQuarters(a.weapon, b.weapon)
    let gap = close ? 30.0 + a.persona.bulk + b.persona.bulk : 64.0, margin = 24.0
    let width = Int(gap + margin * 2 + 36)
    let moments = [0.05, 0.2, 0.33, 0.45, 0.6, 0.75, 0.9, 1.3, 2.1]
    let headroom = 24   // flyers fight from the air now and then (`sortieAir`)
    let cellW = CGFloat(width) * scale + 8, cellH = CGFloat(Sprite.height + headroom) * scale + 8
    let w = Int(cellW * 3), h = Int(cellH * CGFloat((moments.count + 2) / 3) + 26)
    save(sheet(w, h) { ctx in
        label("\(a.name) (\(ra)) vs \(b.name) (\(rb))", 6, CGFloat(h) - 20)
        for (i, t) in moments.enumerated() {
            let c = PixelCanvas(width, Sprite.height + headroom)
            let lx = margin + 10, rx = lx + gap
            let sa = Int((sortieAir(a, seed: 0, fighting: true, t: t) * 16).rounded())
            let sb = Int((sortieAir(b, seed: 0.5, fighting: true, t: t) * 16).rounded())
            let ua = sa + gripLift(by: b, rb, t), ub = sb + gripLift(by: a, ra, t)
            let ca = PixelCanvas(Sprite.width, Sprite.height), cb = PixelCanvas(Sprite.width, Sprite.height)
            a.draw(ca, t: t, mode: .working, walking: false, role: ra, asSession: false, aloft: sa > 4)
            b.draw(cb, t: t, mode: .working, walking: false, role: rb, asSession: false, aloft: sb > 4)
            cb.flipHorizontally()
            c.paste(ca, x: Int(lx - Sprite.bodyCenterX), y: headroom - ua)
            c.paste(cb, x: Int(rx - (Double(Sprite.width) - Sprite.bodyCenterX)), y: headroom - ub)
            func fighter(_ who: Cast, x: Double, side: Double, up: Int) -> Fighter {
                Fighter(weapon: who.weapon, x: x, k: 1, top: Double(headroom - up), side: side, muzzle: who.muzzle,
                        armoured: who.armoured, pivot: who.weaponPivot).dressed(as: who)
            }
            drawFightFX(c, t: t, left: fighter(a, x: lx, side: 1, up: ua), right: fighter(b, x: rx, side: -1, up: ub))
            put(c, ctx, x: CGFloat(i % 3) * cellW, y: CGFloat(h) - 26 - cellH * CGFloat(i / 3 + 1), outline: false)
            label("t=\(t)", CGFloat(i % 3) * cellW + 4, CGFloat(h) - 26 - cellH * CGFloat(i / 3) - 16, size: 10)
        }
    })

case "magic":
    // Every magic user's stream side by side (or just the names given), at a few moments: no two should look alike.
    let everyone = Universe.allCases.flatMap { Theme.of($0).cast }.filter { $0.weapon == .lightning }
    let who = names.isEmpty ? everyone : names.flatMap(cast(named:))
    let moments = [0.1, 0.37, 0.71]
    let len = 46.0, cellW = CGFloat(len + 10) * scale, cellH: CGFloat = 16 * scale, nameW: CGFloat = 170
    let cols = 3, rows = (who.count + cols - 1) / cols
    let w = Int((nameW + cellW * CGFloat(moments.count)) * CGFloat(cols)), h = Int(cellH * CGFloat(rows) + 10)
    save(sheet(w, h) { ctx in
        for (i, c) in who.enumerated() {
            let x0 = CGFloat(i / rows) * (nameW + cellW * CGFloat(moments.count)), y = CGFloat(h) - 5 - cellH * CGFloat(i % rows + 1)
            let m = c.persona.magic
            label("\(c.name) [\(m.family).\(m.variant)]", x0 + 4, y + cellH / 2 - 6, size: 11)
            for (j, t) in moments.enumerated() {
                let canvas = PixelCanvas(Int(len) + 10, 16)
                drawMagic(canvas, m, from: (3, 8), to: (3 + len, 8), t: t)
                put(canvas, ctx, x: x0 + nameW + CGFloat(j) * cellW, y: y, outline: false)
            }
        }
    })

case "fightclip":
    // An animated fight: two characters for SECONDS (default 4) at 30 fps, as an mp4 (needs ffmpeg). LABEL captions it.
    guard names.count == 2 else { print("fightclip needs two characters"); exit(2) }
    let a = cast(named: names[0])[0], b = cast(named: names[1])[0]
    let (ra, rb) = fightRoles(a.weapon, b.weapon)
    let close = fightIsCloseQuarters(a.weapon, b.weapon)
    let gap = close ? 30.0 + a.persona.bulk + b.persona.bulk : 64.0, margin = 24.0
    let width = Int(gap + margin * 2 + 36), headroom = 12
    let seconds = Double(ProcessInfo.processInfo.environment["SECONDS"] ?? "") ?? 4
    let caption = ProcessInfo.processInfo.environment["LABEL"] ?? "\(a.name) vs \(b.name)"
    let frames = URL(fileURLWithPath: out + ".frames")
    try? FileManager.default.removeItem(at: frames)
    try! FileManager.default.createDirectory(at: frames, withIntermediateDirectories: true)
    let w = Int(CGFloat(width) * scale) / 2 * 2, h = (Int(CGFloat(Sprite.height + headroom) * scale) + 30) / 2 * 2
    for i in 0..<Int(seconds * 30) {
        let t = Double(i) / 30
        let rep = sheet(w, h) { ctx in
            let c = PixelCanvas(width, Sprite.height + headroom)
            let lx = margin + 10, rx = lx + gap
            let ca = PixelCanvas(Sprite.width, Sprite.height), cb = PixelCanvas(Sprite.width, Sprite.height)
            a.draw(ca, t: t, mode: .working, walking: false, role: ra, asSession: false)
            b.draw(cb, t: t, mode: .working, walking: false, role: rb, asSession: false)
            cb.flipHorizontally()
            let ua = gripLift(by: b, rb, t), ub = gripLift(by: a, ra, t)
            c.paste(ca, x: Int(lx - Sprite.bodyCenterX), y: headroom - ua)
            c.paste(cb, x: Int(rx - (Double(Sprite.width) - Sprite.bodyCenterX)), y: headroom - ub)
            func fighter(_ who: Cast, x: Double, side: Double, up: Int) -> Fighter {
                Fighter(weapon: who.weapon, x: x, k: 1, top: Double(headroom - up), side: side, muzzle: who.muzzle,
                        armoured: who.armoured, pivot: who.weaponPivot).dressed(as: who)
            }
            drawFightFX(c, t: t, left: fighter(a, x: lx, side: 1, up: ua), right: fighter(b, x: rx, side: -1, up: ub))
            put(c, ctx, x: 0, y: 0, outline: false)
            label(caption, 8, CGFloat(h) - 22, size: 14)
        }
        try! rep.representation(using: .png, properties: [:])!.write(to: frames.appendingPathComponent(String(format: "f%04d.png", i)))
    }
    let ff = Process()
    ff.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg")
    ff.arguments = ["-y", "-loglevel", "error", "-framerate", "30", "-i", frames.path + "/f%04d.png",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", out]
    try! ff.run(); ff.waitUntilExit()
    try? FileManager.default.removeItem(at: frames)
    print("wrote \(out)")

case "place":
    let everywhere = Universe.allCases.flatMap { Location.all(in: $0) }
    let universe = names.count == 1
        ? Universe(key: names[0]) ?? Universe.allCases.first { squashed($0.title) == squashed(names[0]) } : nil
    // A place by case name (cantina) or by the name shown on screen ("Mos Icely Cantina").
    func place(_ n: String) -> Location? {
        Location(rawValue: n) ?? everywhere.first { squashed($0.name) == squashed(n) }
    }
    var places = names.isEmpty || names == ["all"] ? everywhere
        : universe.map { Location.all(in: $0) }
        ?? names.map { n in place(n) ?? { print("unknown place: \(n)"); exit(2) }() }
    if flipped {
        // The places that can turn over (a universe named: just its own), each the right way up, mid-turn and upside
        // down, with a crew standing on its floor and their names, as the window and the screen saver turn them
        // (`SceneTurn`).
        if universe != nil || names.isEmpty { places = places.filter { $0.universe.module.sceneFlip?.places.contains($0) == true } }
        guard !places.isEmpty else { print("no place there turns over"); exit(2) }
        let strip = (w: 480, h: 75), tall = (w: 480, h: 300)
        let s: CGFloat = 2, gap: CGFloat = 12
        let turns: [(String, Double)] = [("the right way up", 0), ("turning", 0.4), ("upside down", 1)]
        let rowH = CGFloat(strip.h + tall.h) * s + 64
        let w = Int(CGFloat(strip.w) * s * 3 + gap * 4), h = Int(rowH * CGFloat(places.count))
        save(sheet(w, h) { ctx in
            for (i, l) in places.enumerated() {
                let top = CGFloat(h) - rowH * CGFloat(i)
                label(l.name, 6, top - 18, size: 13)
                // Who stands there: whoever lives there first, then the universe's first heroes, four in all.
                let cast = Theme.of(l.universe).cast.filter { !$0.universe.isHem($0.id) }
                let crew = Array((cast.filter { $0.home == l } + cast.filter { !$0.isDark && $0.home != l }).prefix(4))
                for (j, size) in [strip, tall].enumerated() {
                    let room = PixelCanvas(size.w, size.h); l.drawStatic(room, floorRows: 10)
                    let live = PixelCanvas(size.w, size.h); l.drawAnimated(live, floorRows: 10, t: 1.3)
                    let y = j == 0 ? top - 40 - CGFloat(strip.h) * s : top - 56 - CGFloat(strip.h + tall.h) * s
                    for (k, turn) in turns.enumerated() {
                        let x = gap + CGFloat(k) * (CGFloat(size.w) * s + gap)
                        let frame = CGRect(x: x, y: y, width: CGFloat(size.w) * s, height: CGFloat(size.h) * s)
                        if j == 0 { label(turn.0, x, top - 36, size: 11, color: NSColor(white: 0.75, alpha: 1)) }
                        let t = SceneTurn(amount: turn.1, axis: frame.midY)
                        ctx.saveGState()
                        ctx.clip(to: frame)
                        ctx.setFillColor(CGColor(red: 0.03, green: 0.035, blue: 0.05, alpha: 1)); ctx.fill(frame)
                        ctx.translateBy(x: 0, y: t.axis); ctx.scaleBy(x: 1, y: t.scale); ctx.translateBy(x: 0, y: -t.axis)
                        for img in [room.makeImage(), live.makeImage()].compactMap({ $0 }) { ctx.draw(img, in: frame) }
                        // The crew, a sprite's pixel to a place's, feet a little way into the floor.
                        var tags: [(String, CGFloat, CGFloat)] = []
                        for (n, who) in crew.enumerated() {
                            let c = PixelCanvas(Sprite.width, Sprite.height)
                            who.draw(c, t: 0.4 + Double(n), mode: .idle, walking: false, role: .none, asSession: true)
                            c.addOutline(C(0xFFFFFF, 0.92))
                            let cx = frame.minX + (60 + CGFloat(n) * 100) * s
                            if let img = c.makeImage() {
                                ctx.draw(img, in: CGRect(x: cx - CGFloat(Sprite.bodyCenterX) * s, y: frame.minY,
                                                         width: CGFloat(Sprite.width) * s, height: CGFloat(Sprite.height) * s))
                            }
                            tags.append((who.name, cx, frame.minY + CGFloat(Sprite.height - who.drawnTop() + 4) * s))
                        }
                        ctx.restoreGState()
                        // Their names, upright, where the spot over their heads went.
                        ctx.saveGState(); ctx.clip(to: frame)
                        for tag in tags {
                            let text = NSAttributedString(string: tag.0, attributes: [.font: NSFont.systemFont(ofSize: 11, weight: .bold),
                                .foregroundColor: NSColor.white.withAlphaComponent(t.labelAlpha)])
                            let ts = text.size()
                            let my = t.y(tag.2 + ts.height / 2)
                            let box = CGRect(x: tag.1 - ts.width / 2 - 4, y: my - ts.height / 2 - 1, width: ts.width + 8, height: ts.height + 2)
                            ctx.setFillColor(CGColor(gray: 0.08, alpha: 0.82 * t.labelAlpha))
                            ctx.addPath(CGPath(roundedRect: box, cornerWidth: 4, cornerHeight: 4, transform: nil)); ctx.fillPath()
                            text.draw(at: NSPoint(x: box.minX + 4, y: box.minY + 1))
                        }
                        ctx.restoreGState()
                    }
                }
            }
        })
        exit(0)
    }
    // The window's strip (about 480×75 pixels) and a screen-saver frame (16:10, tall enough for the extras).
    let strip = (w: 480, h: 75), tall = (w: 480, h: 300)
    let s: CGFloat = 2
    let rowH = CGFloat(strip.h + tall.h) * s + 40
    let w = Int(CGFloat(tall.w) * s + 12), h = Int(rowH * CGFloat(places.count))
    save(sheet(w, h) { ctx in
        for (i, l) in places.enumerated() {
            let top = CGFloat(h) - rowH * CGFloat(i)
            label(l.name, 6, top - 18, size: 13)
            for (j, size) in [strip, tall].enumerated() {
                let c = PixelCanvas(size.w, size.h); l.drawStatic(c, floorRows: 10)
                let m = PixelCanvas(size.w, size.h); l.drawAnimated(m, floorRows: 10, t: 1.3)
                let y = j == 0 ? top - 22 - CGFloat(strip.h) * s : top - 30 - CGFloat(strip.h + tall.h) * s
                for img in [c.makeImage(), m.makeImage()].compactMap({ $0 }) {
                    ctx.draw(img, in: CGRect(x: 6, y: y, width: CGFloat(size.w) * s, height: CGFloat(size.h) * s))
                }
            }
        }
    })

case "rides":
    let every = Universe.allCases.flatMap { $0.module.rides }
    let cellW = CGFloat(Ride.width) * scale + 12, cellH = CGFloat(every.map(\.canvasHeight).max() ?? Ride.height) * scale + 30
    let states: [(String, Double, Bool, Bool)] = [("landed", 0, false, true), ("ramp down / door open", 1, false, true), ("flying", 0, true, false)]
    let rides = names.isEmpty ? every : every.filter { names.contains($0.key) }
    save(sheet(Int(cellW * 3), Int(cellH * CGFloat(rides.count))) { ctx in
        for (i, ride) in rides.enumerated() {
            for (j, st) in states.enumerated() {
                let c = PixelCanvas(Ride.width, ride.canvasHeight + 1)   // a spare row for the outline, as the app has
                drawRide(c, ride, ramp: st.1, engines: st.2, gear: st.3, t: 1.3)   // a fixed clock: the same sheet every time
                c.addOutline(C(0xFFFFFF, 0.92))
                let x = CGFloat(j) * cellW, y = cellH * CGFloat(rides.count - 1 - i)
                ctx.draw(c.makeImage()!, in: CGRect(x: x + 6, y: y + 6 - scale, width: CGFloat(Ride.width) * scale,
                                                    height: CGFloat(ride.canvasHeight + 1) * scale))
                label("\(ride.key) · \(st.0)", x + 6, y + cellH - 20)
            }
        }
    })

default:
    print("unknown mode \(mode)")
    exit(2)
}
