import AppKit
import ServiceManagement
import UserNotifications

/// Borderless, transparent, never-key panel that floats above every app (and full-screen spaces).
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

/// One character on screen. Positions are screen coordinates of the body centre.
private struct Actor {
    enum Kind { case leader(Cast), agent(Cast) }   // a whole session (drawn large) or an agent (small)
    let key: String
    var kind: Kind
    var x: CGFloat
    var targetX: CGFloat
    var facing: CGFloat          // +1 right, -1 left while standing
    var walkDir: CGFloat = 0     // non-zero while walking
    let born: Double
    var leaving: Double?
    let phase: Double
    var mood: Mood = .idle
    var mode: VaderMode = .idle
    var label = ""
    var pid: Int32?              // the Claude process (an agent carries its parent's)
    var assistant = "claude"     // which AI (its list group, e.g. "claude-desktop"): sets the outline colour; agents carry their session's
    var bubble: BubbleKind?
    var urgent = false           // "needs you" ignored for over a minute
    var accent: NSColor?         // project colour, shared with its agents
    var focused = false          // its terminal is the one in front
    var sitting = false          // idle 2+ minutes: sat down on the floor
    var detail: [String] = []    // hover card lines
    var exit: (landX: CGFloat, dir: CGFloat, startX: CGFloat)?   // picked up by its ship (`Cast.ride`)
    var air: CGFloat = 0         // a flyer: 0 on the ground … 1 cruising in the air
    var watched: CGFloat = 0     // a Weeping Angle: seconds it's been held still by someone looking at it
    var regenerated: Double?     // a Doctor's session: when it last regenerated (the golden flare plays for a moment)
    var abducted: Double?        // an FBI agent's session: when it last lost time (the abduction plays for a moment)
    var transformed: Double?     // a session whose leader last turned into its other guise (the flash plays for a moment)
    var moral: Double?           // a session whose leader last gave a lesson on finishing (it's up for a moment)

    var isLeader: Bool { if case .leader = kind { return true } else { return false } }
    var cast: Cast { switch kind { case .leader(let c), .agent(let c): return c } }
}

private struct Fight { let a: String, b: String }

private let fadeIn = 0.5
private let fadeOut = 0.6
private let falconExit = 6.0      // a character with a ride (agent or session) leaving: ship lands, it boards, off

final class OverlayController: NSObject, NSMenuDelegate, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let panel: OverlayPanel
    private let view: OverlayView
    private var sessions: [SessionSnapshot] = []
    private var actors: [Actor] = []
    /// Everyone on screen, for the comic transitions' sound effects.
    var onStage: [Cast] { actors.map(\.cast) }
    private var fights: [Fight] = []
    private var cheering: Set<String> = []
    private var fightUntil: [String: Double] = [:]
    private var home = NSPoint.zero    // the crew's spot on the desktop, where you dragged it (saved as anchorX/anchorY)
    private var demo = CommandLine.arguments.contains("--demo")
    private var demoStart = 0.0
    // Playground: villains picked from the menu, in the order added (which decides who fights whom).
    private var playground: [Int]? = CommandLine.arguments.first { $0.hasPrefix("--playground=") }
        .map { $0.dropFirst(13).split(separator: ",").compactMap { Int($0) } }
    private var playgroundAgents: [Int] = CommandLine.arguments.first { $0.hasPrefix("--agents=") }
        .map { $0.dropFirst(9).split(separator: ",").compactMap { Int($0) } } ?? []
    /// `--ais=claude,codex`: which AI each playground session belongs to (cycled), to check outlines and grouping.
    private let playgroundAIs: [String] = CommandLine.arguments.first { $0.hasPrefix("--ais=") }
        .map { $0.dropFirst(6).split(separator: ",").map(String.init) } ?? []
    /// `--projects=clawd-wars,clawd-wars,tasuke`: each playground session's project (cycled), to check project trees.
    private let playgroundProjects: [String] = CommandLine.arguments.first { $0.hasPrefix("--projects=") }
        .map { $0.dropFirst(11).split(separator: ",").map(String.init) } ?? []
    private var playgroundMood: Mood = CommandLine.arguments.first { $0.hasPrefix("--mood=") }
        .flatMap { Mood(rawValue: String($0.dropFirst(7))) } ?? .working
    private var dragging = false
    private var dragOffset = NSPoint.zero
    private var lastTick = Date().timeIntervalSince1970
    private let start = Date().timeIntervalSince1970
    private var frameCount = 0
    private static let forcedHover = ProcessInfo.processInfo.environment["CLAWD_HOVER"]   // read once: it showed up in profiles
    private var refitting = false
    private let debug = ProcessInfo.processInfo.environment["VADER_DEBUG"] != nil   // Clawd Wars' old name, kept
    private var lastDebug = 0
    private var processes: [ClaudeProcesses.Info] = []
    private var lastScan = 0.0
    private var cpuSamples: [Int32: (at: Double, cpu: Double)] = [:]
    private var busyUntil: [Int32: Double] = [:]
    var items: [DrawItem] = []
    // Status debounce (from agent-view): a new mood must hold for 2 refreshes, except "needs you", which is instant.
    private var debounce: [String: (confirmed: Mood, pending: Mood?, ticks: Int)] = [:]
    private var moodSince: [String: Double] = [:]
    private var focusedPid: Int32?
    private var focusCandidate: Int32??         // a different answer seen once; adopted if it repeats
    private var lastFocusCheck = 0.0
    private var lastShot = 0.0
    // Chaos test (--chaos[=seconds]): random sessions/agents/moods, with layout invariants checked continuously.
    private let chaosSeconds: Double? = CommandLine.arguments.first { $0.hasPrefix("--chaos") }
        .map { arg in arg.split(separator: "=").count == 2 ? Double(arg.split(separator: "=")[1]) ?? 120 : 120 }
    private var chaos: [SessionSnapshot] = []
    private var chaosAgentSerial = 0
    private var violations: [String: (count: Int, examples: [String])] = [:]
    private var walkingSince: [String: Double] = [:]
    private var missingSince: [String: Double] = [:]
    private var lastCheck = 0.0
    private var hasLaidOut = false          // after the first layout, newcomers walk in instead of appearing
    private var hoveredKey: String?
    /// The character whose card row (a session, or one of its agents) the mouse is over in the window's list: it's
    /// picked out in the scene, a glow at its feet and the caret over its head. Set by `CardsView`.
    var listHoverKey: String?
    private var drawnListHover: String?
    /// A soft violet glow, the shape of a shadow, for under the feet of the character picked out from the list.
    private static let hoverGlow: CGImage? = {
        let w = 60, h = 16
        guard let g = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let colors = [CGColor(srgbRed: 0.72, green: 0.61, blue: 1, alpha: 0.75), CGColor(srgbRed: 0.72, green: 0.61, blue: 1, alpha: 0)] as CFArray
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return nil }
        g.scaleBy(x: 1, y: CGFloat(h) / CGFloat(w))
        g.drawRadialGradient(grad, startCenter: CGPoint(x: w / 2, y: w / 2), startRadius: 0, endCenter: CGPoint(x: w / 2, y: w / 2),
                             endRadius: CGFloat(w) / 2, options: [])
        return g.makeImage()
    }()
    private var busySince: [Int32: Double] = [:]
    private var offlineReason: String?
    private var lastHookCheck = 0.0
    private var hooksInstalled = true
    /// Something the user has to do so an AI that's on this Mac reports to us. Only AIs actually installed count.
    struct HookIssue { let text: String; let install: String?; let pid: Int32? }   // install = AI to hook up; pid = session to jump to
    private var hookIssues: [HookIssue] = []
    private var hooksSince: [String: Double] = [:]  // assistant → when its hook file last changed (only if our hooks are in it)
    private var missingHooks: [String] = []          // AIs on this Mac without our hooks
    /// AIs you've said you don't use with Clawd Clash: installed, not connected, and no reminders about it. Connecting
    /// one (Settings or the menu) takes it off the list; removing its hooks from Settings puts it on.
    static var ignoredHooks: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "ignoredHooks") ?? []) }
        set { UserDefaults.standard.set(newValue.sorted(), forKey: "ignoredHooks") }
    }
    private var notifiedSilent: Set<Int32> = []
    private var seenBusy: Set<Int32> = []            // pids seen working (a turn ran, so a working hook would have fired)
    private var reported: Set<Int32> = []            // pids whose hooks have fired: their hooks work, even once SessionEnd drops the record
    private var lastLive: [Int32: Double] = [:]      // when each pid last had a live record
    private let shotPath = ProcessInfo.processInfo.environment["CLAWD_SHOT"]     // "%d" in the path → numbered frames
    private let shotEvery = Double(ProcessInfo.processInfo.environment["CLAWD_SHOT_EVERY"] ?? "") ?? 5
    private var shotCount = 0
    private let dismissAfter = Double(ProcessInfo.processInfo.environment["CLAWD_DISMISS_AFTER"] ?? "")   // debug: Playground agents finish
    private var clawdWindow: ClawdWindow?
    private var windowMode: Bool {
        get { UserDefaults.standard.object(forKey: "windowMode") as? Bool ?? true }   // the window, until you choose
        set { UserDefaults.standard.set(newValue, forKey: "windowMode") }
    }

    /// The chosen size, shrunk in window mode when the crew is too wide for the window.
    private var zoom: CGFloat {
        get { windowMode ? Self.windowZoom * windowFit : baseZoom }
        set { UserDefaults.standard.set(newValue, forKey: "zoom") }
    }
    /// Window mode always uses the Small size (the scene backdrop's pixels match it: 2 pt).
    private static let windowZoom: CGFloat = 0.67
    /// Desktop size: Small until one is chosen.
    private var baseZoom: CGFloat { let z = UserDefaults.standard.double(forKey: "zoom"); return z > 0 ? z : 0.67 }
    private var windowFit: CGFloat = 1

    /// Project names over the Claudes, remembered per mode: on by default on the desktop, off in the window
    /// (its cards already name every project). Agents' task labels always show.
    private var showLabels: Bool {
        get { UserDefaults.standard.object(forKey: windowMode ? "labelsWindow" : "labels") as? Bool ?? !windowMode }
        set { UserDefaults.standard.set(newValue, forKey: windowMode ? "labelsWindow" : "labels") }
    }
    /// Agents' tasks over the agents: always on the desktop; in the window, off unless turned on in Settings
    /// (Settings → Window), since each agent's card row already names its task.
    private var showAgentLabels: Bool { !windowMode || UserDefaults.standard.bool(forKey: "agentLabelsWindow") }

    // Layout constants in points at zoom 1.
    private static let leaderScale: CGFloat = 3
    private static let companionScale: CGFloat = 2
    private static let leaderReach: (fwd: CGFloat, back: CGFloat) = (105, 50)
    private static let agentReach: (fwd: CGFloat, back: CGFloat) = (72, 28)
    private static let gap: CGFloat = 8
    /// How long a Claude keeps fighting after it stops working or thinking.
    private static let fightLinger: Double = 5
    private static let walkSpeed: CGFloat = 150
    /// Example agent tasks for the Playground and Demo Mode.
    private static let sampleTasks = ["Find hook events", "Review Overlay.swift", "Run the test suite", "Plan the refactor",
                                      "Search for usages", "Fix failing build", "Write changelog", "Audit permissions",
                                      "Explore codebase", "Check git history", "Draft README", "Profile CPU usage",
                                      "Verify the fix"]
    /// Canvas rows under the feet that may hang off the bottom of the screen: 8 empty rows minus the one
    /// holding the feet's white outline, which should sit on the screen edge, not just below it.
    private static let footroom: CGFloat = 7 * leaderScale

    override init() {
        // The hook only knows the cast sizes, counted from the enums in each universe's facts file; a persona without its
        // enum case (or a case without its persona) would never be picked, and saved ids would point at the wrong one. A
        // `precondition`, not an `assert`: every build here is optimised (-O), which compiles asserts out, so this is what
        // stops a mismatched build at its first launch.
        for u in Universe.allCases {
            let villains = Theme.of(u).villains.count, heroes = Theme.of(u).heroes.count
            precondition(villains == u.villainCount && heroes == u.heroCount,
                         "\(u.title): the roster has \(villains) villains and \(heroes) heroes, but its facts file has "
                         + "\(u.villainCount) and \(u.heroCount). Every case of the villain and hero enums in the universe's "
                         + "<Prefix>Facts.swift needs its persona in the roster, and every persona its case.")
        }
        panel = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 10, height: 10),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        view = OverlayView()
        super.init()
        view.controller = self
        // Menus in the top bar need a Dock icon. Without "Show Dock Icon", the window still gets them while it's in front.
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateFrontPolicy(active: true)
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateFrontPolicy(active: false)
        }
        // A monitor unplugged, the lid closed, a resolution or arrangement change: put the crew back on a screen.
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.screensChanged()
        }
        // Nothing to draw for while the displays sleep or the screen is locked (the desktop panel still counts as visible).
        let ws = NSWorkspace.shared.notificationCenter
        for (name, asleep) in [(NSWorkspace.screensDidSleepNotification, true), (NSWorkspace.screensDidWakeNotification, false),
                               (NSWorkspace.sessionDidResignActiveNotification, true), (NSWorkspace.sessionDidBecomeActiveNotification, false)] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.screensAsleep = asleep }
        }
        // Set early, so clicking a notification left over from an earlier run still reaches us. Needs an app bundle.
        if Bundle.main.bundleIdentifier != nil { UNUserNotificationCenter.current().delegate = self }

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = Self.charactersOnTop ? .statusBar : Self.desktopLevel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentView = view

        Universe.removed = Self.universesRemoved
        Universe.shown = Self.universe
        Universe.mixed = Self.clawdRoyale
        publishUniverse()   // the hook casts from it
        home = clampHome(savedHome())     // re-applies the edge snap, so positions saved under older rules are corrected
        if windowMode { openWindow() }
        refreshStatus()
        snapActors()
        tick()
        if !windowMode { panel.orderFrontRegardless() }
        installStatusItem()
        applyDockPolicy()
        offerHooksOnFirstLaunch()

        let refresh = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refreshStatus() }
        refresh.tolerance = 0.1   // macOS may line it up with other wake-ups; nobody sees a status a tenth late
        // The frame timer has none: animation is paced by it.
        let frame = Timer(timeInterval: 1.0 / 15, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(frame, forMode: .common)
    }

    // MARK: Placement

    private func savedHome() -> NSPoint {
        let d = UserDefaults.standard
        if d.object(forKey: "anchorX") != nil {
            let p = NSPoint(x: d.double(forKey: "anchorX"), y: d.double(forKey: "anchorY"))
            let feet = NSPoint(x: p.x, y: p.y + Self.footroom * zoom)
            if NSScreen.screens.contains(where: { $0.frame.insetBy(dx: -20, dy: -20).contains(feet) }) { return p }
        }
        let mouse = NSEvent.mouseLocation
        // No screen at all (a headless Mac, or the lid closed at login): any spot will do until one appears.
        guard let vf = (NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        else { return NSPoint(x: 200, y: 0) }
        return NSPoint(x: vf.maxX - 140 * zoom, y: vf.minY - Self.footroom * zoom)
    }

    private func screensChanged() {
        guard !windowMode else { return }   // the window keeps itself on screen
        home = clampHome(savedHome())
        relayout()
        snapActors()
    }

    private func saveHome() {
        UserDefaults.standard.set(home.x, forKey: "anchorX")
        UserDefaults.standard.set(home.y, forKey: "anchorY")
    }

    /// The screen the crew is standing on. `p` is the home point (bottom of the canvas); the feet are
    /// `footroom` above it, and that's what counts, the empty rows under the feet may hang off the edge.
    private func screen(at p: NSPoint) -> NSScreen? {
        let feet = NSPoint(x: p.x, y: p.y + Self.footroom * zoom + 1)
        return NSScreen.screens.first { $0.frame.contains(feet) } ?? NSScreen.main
    }

    /// Keep the lead villain fully on its screen, with the feet allowed right down to the bottom edge.
    /// While dragging, the screen under the cursor wins, so on stacked monitors the crew can stand on the
    /// bottom edge of the upper one instead of tipping over onto the lower one. Feet dropped within
    /// 12 pt of a bottom edge snap onto it.
    private func clampHome(_ p: NSPoint, cursor: NSPoint? = nil) -> NSPoint {
        let byCursor = cursor.flatMap { c in NSScreen.screens.first { $0.frame.contains(c) } }
        guard let f = (byCursor ?? screen(at: p) ?? NSScreen.main)?.frame else { return p }
        let s = Self.leaderScale * zoom
        let floor = f.minY - Self.footroom * zoom
        var y = min(max(p.y, floor), f.maxY - CGFloat(Sprite.height) * s)
        if y - floor < 12 { y = floor }
        return NSPoint(x: min(max(p.x, f.minX + 18 * s), f.maxX - 18 * s), y: y)
    }

    /// Where the crew stands. On the desktop: the screen under the saved spot. In window mode: the
    /// window's scene strip, so the same layout and drawing code works in both.
    private var stage: NSRect {
        if windowMode, let w = clawdWindow { return w.sceneScreenRect }
        return screen(at: home)?.frame ?? NSRect(x: -1e5, y: 0, width: 2e5, height: 1e5)
    }

    /// The first villain's spot (bottom of its canvas).
    private var anchor: NSPoint {
        guard windowMode else { return home }
        let st = stage
        return NSPoint(x: st.minX + 60 * zoom, y: st.minY + windowFloor - Self.footroom * zoom)
    }

    /// Where the window's scene is set: chosen in the Location menu, Random (somewhere new every ten minutes), or
    /// (Automatic) the home of the first-spawned Claude, Vader on the Death Star, Boba at the sarlacc pit, Jabba in
    /// his palace… Clawd Royale: always Random, from every universe's places (the menu's choice is kept for after).
    var location: Location {
        if Universe.mixed { return randomPlace(from: Location.everywhere) }
        let raw = Self.pickedLocation
        if raw == Self.randomLocation { return randomPlace(from: Location.all(in: .shown)) }
        if let raw, let l = Location(rawValue: raw), l.universe == .shown { return l }
        return sessions.first.map { Cast(id: $0.leader).home } ?? Location.all(in: .shown)[0]
    }

    static let randomLocation = "random"
    private var random: (place: Location, slot: Int)?

    /// The Random location: a new place from `list` (never the one before) at each ten minutes of the clock.
    private func randomPlace(from list: [Location]) -> Location {
        let slot = Int(Date().timeIntervalSince1970 / 600)
        if let r = random, r.slot == slot, list.contains(r.place) { return r.place }
        let place = list.filter { $0 != random?.place }.randomElement() ?? list[0]
        random = (place, slot)
        return place
    }

    /// Clawd Royale: the universe on show is the place's, so the menu bar icon, Status Symbols and the hook follow it.
    private func followPlace() {
        guard Universe.mixed, let place = shownLocation, place.universe != Universe.shown else { return }
        Universe.shown = place.universe
        statusItem?.button?.image = statusIcon(mono: monoMenuBarIcon)
        publishUniverse()
        if debug { FileHandle.standardError.write("clawd royale: \(place.name), \(place.universe.title)\n".data(using: .utf8)!) }
    }

    /// Height of the floor in the window's scene strip (in points), as the place is drawn (`SceneView`).
    static let cantinaFloor: CGFloat = 20
    /// Where feet stand in the scene strip, a little way into that floor.
    var windowFloor: CGFloat { 16 }

    // MARK: Status

    private func refreshStatus() {
        let now = Date().timeIntervalSince1970
        if chaosSeconds != nil {
            offlineReason = nil
            sessions = chaosStep(now)
        } else if let playground {
            offlineReason = nil
            if let d = dismissAfter, now - start > d { playgroundAgents = [] }
            sessions = playgroundSessions(playground)
        } else if demo {
            offlineReason = nil
            sessions = demoSessions(now - demoStart)
        } else {
            if lastScan == 0 {
                // The first scan is done here and now, so the crew is there from the first frame.
                lastScan = now
                if let found = ClaudeProcesses.runningOrNil() { processes = found; sampleCPU(now, cpu: Self.cpuTimes(found)) }
            } else if now - lastScan > 3 && !scanning {
                // Later ones run in the background: a process scan is a handful of system calls per process, and the
                // main thread draws the animation. Only this queue ever calls `runningOrNil` after the first scan.
                lastScan = now
                scanning = true
                Self.scanQueue.async { [weak self] in
                    let found = ClaudeProcesses.runningOrNil()
                    let cpu = found.map(Self.cpuTimes) ?? [:]
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.scanning = false
                        // A failed scan keeps the last list rather than dropping every session.
                        guard let found else { return }
                        self.processes = found
                        self.sampleCPU(Date().timeIntervalSince1970, cpu: cpu)
                    }
                }
            }
            let file = StatusStore.load()   // read once: it also tells us whether the file is readable
            // The hook (3.0.0 and older) rewrites the file without `mixed`, so cast from the app's own state, and put the
            // file right again for the hook.
            var shownFile = file ?? StatusFile()
            shownFile.universe = Universe.shown.rawValue
            shownFile.mixed = Universe.mixed ? true : nil
            shownFile.removed = Universe.removed.isEmpty ? nil : Universe.removed.map(\.rawValue).sorted()
            if let file, (file.mixed == true) != Universe.mixed || file.universe != Universe.shown.rawValue
                || file.removed != shownFile.removed { publishUniverse() }
            sessions = StatusStore.snapshot(shownFile, now: now, processes: processes)
            // A session that quits drops its record at SessionEnd, but the process lingers a moment while it shuts down.
            // Don't let it come back as a new character (a fresh villain walking in only to fade out): it has left.
            for s in sessions where s.live { if let pid = s.pid { lastLive[pid] = now } }
            sessions.removeAll { s in !s.live && s.pid.flatMap { lastLive[$0] }.map { now - $0 < 30 } ?? false }
            lastLive = lastLive.filter { now - $0.value < 30 }
            // Sessions without hooks can't report status, but a busy Claude burns CPU (idle ≈ 0.3%,
            // working ≈ 5–10%), so treat sustained CPU as "working" for them.
            for i in sessions.indices where !sessions[i].live {
                if let pid = sessions[i].pid, (busyUntil[pid] ?? 0) > now { sessions[i].mood = .working }
            }
            // Not reporting: the hooks say idle, but the process has been busy for over a minute and no
            // agent has reported in that time, the hooks have stopped firing for it.
            for i in sessions.indices where sessions[i].live {
                guard let pid = sessions[i].pid, let rec = sessions[i].record, rec.state == "idle",
                      let busy = busySince[pid], now - busy > 60, now - rec.updated > 60,
                      !sessions[i].agents.contains(where: { now - $0.lastSeen < 60 }) else { continue }
                sessions[i].stalled = true
            }
            // No hook fires when a permission request is approved, so "waiting" would last the whole tool run.
            // CPU busy for two samples in a row (about 6 s) since the request went up means it's running again.
            for i in sessions.indices where sessions[i].mood == .waiting {
                guard let pid = sessions[i].pid, let asked = sessions[i].record?.since, let busy = busySince[pid],
                      busy > asked, now - busy >= 6, (busyUntil[pid] ?? 0) > now else { continue }
                sessions[i].mood = .working
            }
            if now - lastHookCheck > 10 {
                lastHookCheck = now
                hooksInstalled = HookInstaller.isInstalled
                func changed(_ url: URL) -> Double? {
                    (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date)?.timeIntervalSince1970
                }
                hooksSince = [:]
                missingHooks = []
                if hooksInstalled { hooksSince["claude"] = changed(HookInstaller.settingsURL) }
                else if HookInstaller.claudeAvailable { missingHooks.append("claude") }
                for ai in HookInstaller.others where HookInstaller.available(ai) {
                    if HookInstaller.installed(ai) { hooksSince[ai.name] = changed(ai.file) } else { missingHooks.append(ai.name) }
                }
            }
            // A session that started after our hooks were in place and has run a turn, but never reported, has its
            // hook switched off, for Codex that means it hasn't been approved in /hooks yet.
            // A session that quits drops its record at SessionEnd but lingers (busy) for a moment while it shuts down:
            // having reported once, it isn't silent.
            let startedAt = Dictionary(processes.map { ($0.pid, $0.started) }, uniquingKeysWith: { a, _ in a })
            reported.formUnion(sessions.filter(\.live).compactMap(\.pid))
            for i in sessions.indices where !sessions[i].live {
                guard let pid = sessions[i].pid, !reported.contains(pid) else { continue }
                if sessions[i].mood == .working { seenBusy.insert(pid) }
                if let since = hooksSince[sessions[i].assistant], let st = startedAt[pid], st > since + 2, seenBusy.contains(pid) {
                    sessions[i].hookSilent = true
                }
            }
            hookIssues = missingHooks.filter { !Self.ignoredHooks.contains($0) }.map {
                HookIssue(text: HookInstaller.reportsToReplacedApp($0)
                            ? "\(HookInstaller.displayName($0)) still reports to the app Clawd Clash replaces. Connect it to Clawd Clash from the menu."
                            : "\(HookInstaller.displayName($0)) isn't connected: live status is off. Connect it from the menu.",
                          install: $0, pid: nil)
            } + sessions.filter(\.hookSilent).map {
                HookIssue(text: "\(HookInstaller.displayName($0.assistant))\($0.project.isEmpty ? "" : " (\($0.project))") isn't reporting: "
                              + HookInstaller.silentFix($0.assistant), install: nil, pid: $0.pid)
            }
            for s in sessions where s.hookSilent { if let pid = s.pid { notifySilent(pid: pid, assistant: s.assistant, project: s.project) } }
            offlineReason = nil
            if file == nil && FileManager.default.fileExists(atPath: StatusPaths.state.path) {
                offlineReason = "OFFLINE: can't read the status file"
            }
            if now - lastFocusCheck >= 1 {
                lastFocusCheck = now
                // Sticky: only switch when the same answer comes back twice, so a momentary miss doesn't flicker.
                let seen = Jump.focusedSession(among: sessions.compactMap { s in
                    s.pid.map { ($0, s.cwd.map { ($0 as NSString).lastPathComponent } ?? s.project) }
                })
                if seen == focusedPid { focusCandidate = nil }
                else if seen == focusCandidate { focusedPid = seen; focusCandidate = nil }
                else { focusCandidate = seen }
            }
        }
        // The homebound (`Universe.homebound`) only appear at home: in the window's scene when it's theirs, never on the
        // desktop. The Playground shows whoever was picked.
        if playground == nil { sessions = StatusStore.at(sessions, place: windowMode ? location.rawValue : nil, roster: .shown) }
        debounceMoods(now)
        Accents.update(visible: sessions.map(\.project))
        relayout()
        // Automatic follows the first session and Random moves on every ten minutes: when the place changes, the
        // scene, the cards' tint, the header's name and tint must follow.
        if location != shownLocation { followPlaceChange() }
        updateIdleWindow(now)
        randomUniverseTick(now)
        if windowMode && onScreen { updateCards(now) }
        publishSaverFeed(now)
    }

    private var shownLocation: Location?

    private func followPlaceChange() {
        shownLocation = location
        followPlace()
        clawdWindow?.sceneView.showFrame()
        clawdWindow?.cardsView.needsDisplay = true
        clawdWindow?.header.needsDisplay = true
        clawdWindow?.redrawScroller()
    }

    // MARK: Screen saver feed

    private var lastFeed = 0.0, lastSaverCheck = -100.0, saverInstalled = false
    private var feedEvents: [SaverFeed.Event] = []
    /// What each session and agent looked like at the last publish, to tell what happened since.
    private var feedSeen: [String: (mood: String, asleep: Bool, name: String, project: String, prompt: String?)] = [:]
    private var feedAgents: [String: (name: String, task: String, leader: String)] = [:]

    /// The latest feed, for the window's screen-saver view.
    private(set) var saverFeed: SaverFeed?

    /// About once a second, while the screen saver is installed or the window shows its view: what it should show
    /// (see `SaverFeed`). Only real sessions are written to the file; the Playground, demo and test runs leave it alone.
    private func publishSaverFeed(_ now: Double) {
        // A template preview's sessions are adopted into the template's cast: never written where the saver reads them.
        let real = playground == nil && !demo && chaosSeconds == nil && shotPath == nil && Universe.previewed == nil
        if real && now - lastSaverCheck > 10 { lastSaverCheck = now; saverInstalled = SaverFeed.installedSaver != nil }
        let board = windowMode && ClawdWindow.view == .board || fullScreen != nil
        guard (real && saverInstalled) || board, now - lastFeed >= 1 else { return }
        lastFeed = now
        var out: [SaverFeed.Session] = []
        var seenNow: [String: (mood: String, asleep: Bool, name: String, project: String, prompt: String?)] = [:]
        var agentsNow: [String: (name: String, task: String, leader: String)] = [:]
        for s in sessions where s.id != "home" {
            let actor = actors.first { $0.key == "L:" + s.id }
            let cast = Cast(id: s.leader)
            let asleep = actor?.bubble == .sleeping
            let hex = Accents.color(for: s.project).flatMap { $0.usingColorSpace(.sRGB) }.map {
                UInt32($0.redComponent * 255) << 16 | UInt32($0.greenComponent * 255) << 8 | UInt32($0.blueComponent * 255)
            }
            let agents = s.agents.map { a in
                SaverFeed.Agent(id: a.id, cast: Cast.of(a).id, task: a.label.isEmpty ? "Agent" : a.label)
            }
            out.append(SaverFeed.Session(
                id: s.id, cast: cast.id, assistant: s.group, project: s.project, 
                accent: hex, mood: s.mood.rawValue, urgent: actor?.urgent ?? false, asleep: asleep, sitting: actor?.sitting ?? false,
                unknown: !s.live || s.hookSilent, focused: s.pid != nil && s.pid == focusedPid, since: since(s, now: now),
                activity: s.mood == .background ? "Waiting on: " + backgroundJobs(s) : s.mood == .idle ? nil : s.record?.activity,
                prompt: s.record?.prompt, agents: agents))
            seenNow[s.id] = (s.mood.rawValue, asleep, cast.name, s.project, s.record?.prompt)
            for (a, fa) in zip(s.agents, agents) { agentsNow[a.id] = (Cast.of(a).name, fa.task, cast.name) }
        }
        // What happened since last time, for the saver's ticker.
        func event(_ text: String) { feedEvents.append(SaverFeed.Event(at: now, text: text)) }
        func short(_ s: String) -> String { s.count > 48 ? String(s.prefix(47)) + "…" : s }
        let first = feedSeen.isEmpty && feedAgents.isEmpty
        for (id, n) in seenNow where !first {
            let place = n.project.isEmpty ? "" : " in \(n.project)"
            guard let was = feedSeen[id] else { event("\(n.name) arrived\(place)"); continue }
            if n.mood == "waiting" && was.mood != "waiting" { event("\(n.name) is waiting on you\(place)") }
            else if n.mood == "background" && was.mood != "background" { event("\(n.name) is waiting on a job\(place)") }
            else if n.mood == "idle" && (was.mood == "working" || was.mood == "thinking") {
                event("\(n.name) finished\(n.prompt.map { " “" + short($0) + "”" } ?? "")\(place)")
            } else if n.asleep && !was.asleep { event("\(n.name) fell asleep\(place)") }
        }
        for (id, was) in feedSeen where seenNow[id] == nil && !first {
            event("\(was.name) left\(was.project.isEmpty ? "" : " " + was.project)")
        }
        // An agent leaves the scene when it's done, so the line says whose agent it was and that it's gone.
        for (id, a) in agentsNow where feedAgents[id] == nil && !first {
            event("\(a.name) joined \(a.leader) as an agent: \(short(a.task))")
        }
        for (id, a) in feedAgents where agentsNow[id] == nil && !first {
            event("\(a.name), \(a.leader)'s agent, finished and left: \(short(a.task))")
        }
        feedSeen = seenNow
        feedAgents = agentsNow
        feedEvents = Array(feedEvents.suffix(12))
        let feed = SaverFeed(at: now, location: location.rawValue, sessions: out, events: feedEvents,
                             universe: Universe.shown.rawValue, mixed: Universe.mixed ? true : nil,
                             removed: Universe.removed.isEmpty ? nil : Universe.removed.map(\.rawValue).sorted(),
                             privacy: Self.saverPrivacy)
        saverFeed = feed
        if real && saverInstalled { feed.save() }
    }

    private func debounceMoods(_ now: Double) {
        var next: [String: (confirmed: Mood, pending: Mood?, ticks: Int)] = [:]
        for i in sessions.indices {
            let id = sessions[i].id, raw = sessions[i].mood
            var e = debounce[id] ?? (raw, nil, 0)
            if debounce[id] == nil { moodSince[id] = now }
            if raw == e.confirmed {
                e.pending = nil; e.ticks = 0
            } else if raw == .waiting {
                e = (raw, nil, 0); moodSince[id] = now          // the raised hand is the whole point: no delay
            } else if e.pending == raw {
                e.ticks += 1
                if e.ticks >= 2 { e = (raw, nil, 0); moodSince[id] = now }
            } else {
                e.pending = raw; e.ticks = 1
            }
            sessions[i].mood = e.confirmed
            next[id] = e
        }
        debounce = next
        moodSince = moodSince.filter { next[$0.key] != nil }
    }

    /// How long a session has been in its current mood (hooks know exactly; otherwise we count from when we saw it).
    /// What a session waiting on a background job left running: "Render the promo", or "Build the app, and 2 more".
    private func backgroundJobs(_ s: SessionSnapshot) -> String {
        let jobs = s.record?.background ?? []
        guard let first = jobs.first else { return "a job" }
        return jobs.count == 1 ? first : first + ", and \(jobs.count - 1) more"
    }

    private func since(_ s: SessionSnapshot, now: Double) -> Double {
        if let rec = s.record, let t = rec.since, rec.state == s.mood.rawValue { return t }
        return moodSince[s.id] ?? now
    }

    private static let scanQueue = DispatchQueue(label: "clawdclash.process-scan", qos: .utility)
    private var scanning = false

    /// Each process's CPU time so far, in seconds.
    private static func cpuTimes(_ processes: [ClaudeProcesses.Info]) -> [Int32: Double] {
        var out: [Int32: Double] = [:]
        for p in processes { out[p.pid] = ClaudeProcesses.cpuSeconds(p.pid) }
        return out
    }

    private func sampleCPU(_ now: Double, cpu times: [Int32: Double]) {
        var next: [Int32: (at: Double, cpu: Double)] = [:]
        for p in processes {
            guard let cpu = times[p.pid] else { continue }
            if let prev = cpuSamples[p.pid], now > prev.at {
                let usage = (cpu - prev.cpu) / (now - prev.at)
                if usage > 0.03 {
                    busyUntil[p.pid] = now + 6
                    if busySince[p.pid] == nil { busySince[p.pid] = now }
                }
            }
            next[p.pid] = (now, cpu)
        }
        cpuSamples = next
        busyUntil = busyUntil.filter { $0.value > now }
        busySince = busySince.filter { busyUntil[$0.key] != nil }
    }

    /// Build the formation and give every actor a target position.
    ///
    /// Leaders pair up (1st & 2nd Claude, 3rd & 4th…) facing each other so they can fight; each leader's
    /// agents stand on its outer side. The whole line extends toward the side of the screen with more room,
    /// and if it still doesn't fit, everyone walks along until it does.
    private func relayout() {
        let now = Date().timeIntervalSince1970
        let z = zoom

        struct Unit { let key: String; let kind: Actor.Kind; var facing: CGFloat; let fwd, back: CGFloat
            var fixedDistance: CGFloat?; var session: SessionSnapshot?; var agent: AgentRecord? }
        var units: [Unit] = []
        var newFights: [Fight] = []

        func agentUnit(_ a: AgentRecord, _ facing: CGFloat) -> Unit {
            Unit(key: "A:" + a.id, kind: .agent(Cast.of(a)),
                 facing: facing, fwd: Self.agentReach.fwd * z, back: Self.agentReach.back * z, agent: a)
        }
        func leaderUnit(_ s: SessionSnapshot, _ facing: CGFloat) -> Unit {
            Unit(key: "L:" + s.id, kind: .leader(Cast(id: s.leader)), facing: facing,
                 fwd: Self.leaderReach.fwd * z, back: Self.leaderReach.back * z, session: s)
        }

        // Everyone on screen, in their natural order (each villain followed by its agents).
        struct Member { var unit: Unit; let weapon: Weapon; let isLeader: Bool; let order: Int }
        var members: [Member] = []
        for s in sessions {
            members.append(Member(unit: leaderUnit(s, 1), weapon: Cast(id: s.leader).weapon, isLeader: true,
                                  order: members.count))
            for ag in s.agents {
                members.append(Member(unit: agentUnit(ag, 1), weapon: Cast.of(ag).weapon, isLeader: false, order: members.count))
            }
        }

        // Who fights whom. Only Claudes that are working or thinking fight (with a short linger, so one that pauses
        // between tools doesn't walk in and out); idle ones and ones waiting for you step aside, to sit and sleep.
        //  1. Claudes fight Claudes (saber duels first).
        //  2. Agents fight agents, their own or other Claudes' (saber duels first).
        //  3. A leftover Claude and a leftover agent fight each other.
        //  4. Anyone still left over cheers the fighters on. The unarmed (Mantis, Professor X…) are bystanders.
        // A lone Claude with nobody to fight just practises its kata when working.
        var pairs: [(Member, Member)] = []
        func pairUp(_ pool: inout [Member]) {
            for saberFirst in [true, false] {
                var k = 0
                while k < pool.count {
                    let eligible = { (a: Member, b: Member) in !saberFirst || (a.weapon == .saber && b.weapon == .saber) }
                    guard let m = pool.indices.dropFirst(k + 1).first(where: { eligible(pool[k], pool[$0]) }) else { k += 1; continue }
                    pairs.append((pool[k], pool[m]))
                    pool.remove(at: m); pool.remove(at: k)
                }
            }
        }
        for s in sessions where s.mood == .working || s.mood == .thinking { fightUntil["L:" + s.id] = now + Self.fightLinger }
        let active = { (m: Member) in !m.isLeader || (self.fightUntil[m.unit.key] ?? 0) > now }
        var villains = members.filter { $0.isLeader && $0.weapon != .none && active($0) }
        let unarmedVillains = members.filter { $0.isLeader && $0.weapon == .none && active($0) }
        var agents = members.filter { !$0.isLeader && $0.weapon != .none }
        // 0. Arch-enemies face off first when both are fighting, Claude or agent, wherever they are in the line
        //    (`Cast.nemeses`): everyone between them walks over to make room.
        func cast(_ m: Member) -> Cast { switch m.unit.kind { case .leader(let c), .agent(let c): return c } }
        var fighters = villains + agents
        while let i = fighters.indices.first(where: { i in fighters.indices.contains { cast(fighters[i]).isNemesis(of: cast(fighters[$0])) } }),
              let j = fighters.indices.first(where: { cast(fighters[i]).isNemesis(of: cast(fighters[$0])) }) {
            let a = fighters[i], b = fighters[j]
            pairs.append((a, b))
            fighters.removeAll { $0.unit.key == a.unit.key || $0.unit.key == b.unit.key }
            villains.removeAll { $0.unit.key == a.unit.key || $0.unit.key == b.unit.key }
            agents.removeAll { $0.unit.key == a.unit.key || $0.unit.key == b.unit.key }
        }
        pairUp(&villains)
        pairUp(&agents)
        if let v = villains.first, let a = agents.first {
            pairs.append((v, a))
            villains.removeFirst(); agents.removeFirst()
        }
        var pool = agents
        if !pairs.isEmpty { pool += villains + unarmedVillains }   // a lone Claude with no opponents practises instead
        cheering = Set(pool.map(\.unit.key))
        let paired = Set(pairs.flatMap { [$0.0.unit.key, $0.1.unit.key] })

        // Lay out pairs and everyone else, keeping roughly the natural order so the line is stable.
        var groups: [[Member]] = pairs.map { [$0.0, $0.1] }
        groups += members.filter { !paired.contains($0.unit.key) }.map { [$0] }
        groups.sort { $0.map(\.order).min()! < $1.map(\.order).min()! }

        for g in groups {
            if g.count == 1 {
                units.append(g[0].unit)
                continue
            }
            var a = g[0].unit, b = g[1].unit
            a.facing = 1; b.facing = -1
            newFights.append(Fight(a: a.key, b: b.key))
            if fightIsCloseQuarters(g[0].weapon, g[1].weapon) {
                // Close enough that the two blades cross, whatever the sprite sizes.
                let sa = g[0].isLeader ? Self.leaderScale : Self.companionScale
                let sb = g[1].isLeader ? Self.leaderScale : Self.companionScale
                b.fixedDistance = (13.5 * (sa + sb) + 29.7 * min(sa, sb)
                                   + CGFloat(cast(g[0]).persona.bulk) * sa + CGFloat(cast(g[1]).persona.bulk) * sb) * z
            }
            units.append(a)
            units.append(b)
        }
        fights = newFights
        fightUntil = fightUntil.filter { $0.value > now - 60 }

        // Positions along the formation axis (f), Vader at 0.
        func left(_ u: Unit) -> CGFloat { u.facing > 0 ? u.back : u.fwd }
        func right(_ u: Unit) -> CGFloat { u.facing > 0 ? u.fwd : u.back }
        var f: [CGFloat] = []
        for (k, u) in units.enumerated() {
            if k == 0 { f.append(0); continue }
            f.append(f[k - 1] + (u.fixedDistance ?? (right(units[k - 1]) + Self.gap * z + left(u))))
        }
        // The first-spawned villain stands on the saved spot; everyone else lines up from there.
        let vaderIndex = units.firstIndex { u in u.session?.id == sessions.first?.id } ?? 0
        let origin = f.isEmpty ? 0 : f[vaderIndex]
        f = f.map { $0 - origin }

        // Direction: toward the side of the screen with more room.
        let sf = stage, origin0 = anchor
        let dir: CGFloat = windowMode ? 1 : ((sf.maxX - origin0.x) >= (origin0.x - sf.minX) ? 1 : -1)
        var lo = CGFloat.greatestFiniteMagnitude, hi = -CGFloat.greatestFiniteMagnitude
        for (k, u) in units.enumerated() {
            let x = origin0.x + dir * f[k]
            let ext = (dir * u.facing > 0) ? (u.back, u.fwd) : (u.fwd, u.back)
            lo = min(lo, x - ext.0); hi = max(hi, x + ext.1)
        }
        // Window mode: shrink the whole crew to fit the window (grow back when there's room again).
        // (Nobody left: nothing to measure, and leaving the fit alone lets the last ones fade out at their size.)
        if windowMode && !refitting && !units.isEmpty && hi > lo {
            let needed = hi - lo, avail = sf.width - 8
            var fit = windowFit
            if needed > avail { fit = max(0.35, windowFit * avail / needed) }
            else if windowFit < 1 && needed < avail * 0.8 { fit = min(1, windowFit * avail * 0.9 / needed) }
            if abs(fit - windowFit) > 0.01 {
                windowFit = fit
                refitting = true
                relayout()
                refitting = false
                snapActors()
                return
            }
        }
        var shift: CGFloat = 0
        if windowMode && hi - lo <= sf.width - 8 {
            shift = sf.midX - (lo + hi) / 2          // centred in the window when it fits
        } else {
            if hi > sf.maxX - 4 { shift = sf.maxX - 4 - hi }
            if lo + shift < sf.minX + 4 { shift = sf.minX + 4 - lo }
        }
        let projectOf = Dictionary(sessions.map { ($0.id, $0.project) }, uniquingKeysWith: { a, _ in a })
        let pidOf = Dictionary(sessions.map { ($0.id, $0.pid) }, uniquingKeysWith: { a, _ in a })
        let aiOf = Dictionary(sessions.map { ($0.id, $0.group) }, uniquingKeysWith: { a, _ in a })

        // Reconcile actors.
        var seen = Set<String>()
        for (k, u) in units.enumerated() {
            seen.insert(u.key)
            let target = origin0.x + dir * f[k] + shift
            let facing = dir * u.facing
            var mood = Mood.idle, mode = VaderMode.idle, label = ""
            var pid = u.session?.pid
            var assistant = u.session?.group ?? "claude"
            var bubble: BubbleKind?, urgent = false, accent: NSColor?
            if let s = u.session {
                mood = s.mood
                mode = (s.mood == .idle && !s.agents.isEmpty) || s.mood == .background ? .standGuard : VaderMode(s.mood)
                label = s.project.isEmpty ? (s.id == "home" ? "" : Cast(id: s.leader).name) : s.project
                let held = now - since(s, now: now)
                switch s.mood {
                case .thinking: bubble = .thinking
                case .waiting: bubble = .waiting; urgent = held > 60
                case .idle:
                    if (!s.live && s.pid != nil) || s.stalled { bubble = .unknown }  // no live status: say so, don't fake idle
                    else if !s.agents.isEmpty { bubble = .agentsOut(s.agents.count) } // its agents are still out
                    else if s.record != nil && held > 300 { bubble = .sleeping }    // idle 5+ min
                case .background: bubble = .background
                case .working: break
                }
                accent = Accents.color(for: s.project)
            }
            if let a = u.agent {
                label = a.label
                accent = Accents.color(for: projectOf[a.session] ?? "")
                pid = pidOf[a.session] ?? nil
                assistant = aiOf[a.session] ?? "claude"
            }
            let focused = pid != nil && pid == focusedPid && u.session != nil
            // Idle a while: sit down after 2 minutes (the zZz comes at 5).
            var sitting = false
            if let s = u.session, s.mood == .idle, s.record != nil, !s.stalled { sitting = now - since(s, now: now) > 120 }
            let detail = hoverDetail(u.session, u.agent, now: now)
            if let idx = actors.firstIndex(where: { $0.key == u.key && $0.leaving == nil }) {
                actors[idx].targetX = target
                actors[idx].facing = facing
                actors[idx].kind = u.kind
                actors[idx].mood = mood; actors[idx].mode = mode; actors[idx].label = label
                actors[idx].pid = pid; actors[idx].assistant = assistant
                actors[idx].bubble = bubble; actors[idx].urgent = urgent
                actors[idx].accent = accent; actors[idx].focused = focused
                actors[idx].sitting = sitting; actors[idx].detail = detail
                actors[idx].regenerated = u.session?.record?.regenerated
                actors[idx].abducted = u.session?.record?.abducted
                actors[idx].transformed = u.session?.record?.transformed
                actors[idx].moral = u.session?.record?.moral
            } else {
                // Newcomers walk in from the side, one at a time (from agent-view's walk-in through the door).
                var startX = target, born = now
                if hasLaidOut && !dragging {
                    let fromRight = target >= sf.midX
                    startX = target + (fromRight ? 1 : -1) * 240 * z
                    let queued = actors.filter { $0.born > now - 0.6 }.count
                    born = now + Double(queued) * 0.6
                }
                var a = Actor(key: u.key, kind: u.kind, x: startX, targetX: target, facing: facing,
                              born: born, phase: Double(abs(u.key.hashValue) % 1000) / 97)
                a.mood = mood; a.mode = mode; a.label = label; a.pid = pid; a.assistant = assistant
                a.bubble = bubble; a.urgent = urgent; a.accent = accent; a.focused = focused
                a.sitting = sitting; a.detail = detail
                a.regenerated = u.session?.record?.regenerated
                a.abducted = u.session?.record?.abducted
                a.transformed = u.session?.record?.transformed
                a.moral = u.session?.record?.moral
                actors.append(a)
            }
        }
        for idx in actors.indices where actors[idx].leaving == nil && !seen.contains(actors[idx].key) {
            actors[idx].leaving = now
            // Some don't just fade out: their ship comes to pick them up (`Cast.ride`), as an agent or a whole session.
            if actors[idx].cast.ride != nil {
                let st = stage, hx = actors[idx].x
                let dir: CGFloat = hx < st.midX ? 1 : -1
                actors[idx].exit = (hx + dir * 70 * zoom, dir, hx)
            }
        }
        if !sessions.isEmpty { hasLaidOut = true }
    }

    private func snapActors() {
        for i in actors.indices {
            actors[i].x = actors[i].targetX
            actors[i].walkDir = 0
        }
    }

    /// Playground agent tags from here up are villains that are only ever agents (the cast id added on).
    private static let playgroundVillainAgent = 1000

    private func playgroundSessions(_ villains: [Int]) -> [SessionSnapshot] {
        let activities = ["Read Overlay.swift", "Grep fightRoles", "Bash: swift build", "Edit Leaders.swift",
                          "Fetch github.com", "Glob **/*.swift", "Bash: run the tests", "Read README.md"]
        // Heroes by their index in the universe on show; the agent-only villains as `playgroundVillainAgent` + their
        // cast id. Adopted from the universe on show (its base added), so HEM, the last hero, stays HEM.
        let crew = playgroundAgents.enumerated().map { i, c in
            AgentRecord(id: "pg-a\(c)", session: "pg", type: "playground", character: c >= Self.playgroundVillainAgent ? 0 : c,
                        cast: Universe.shown.adopt(Universe.shown.base + (c >= Self.playgroundVillainAgent ? c - Self.playgroundVillainAgent
                                                                                                           : StatusStore.heroBase + c)),
                        started: start - Double(30 + i * 47),
                        lastSeen: 0, task: Self.sampleTasks[c % Self.sampleTasks.count],
                        activity: activities[(c + i) % activities.count], tools: 3 + (c * 7) % 23)
        }
        guard !villains.isEmpty else {
            return [SessionSnapshot(id: "home", leader: Universe.shown.base, project: "", mood: .idle, agents: crew)]
        }
        // Sample details so the Playground's cards look like live ones.
        let prompts = Universe.shown.module.playgroundPrompts
        let nowActs = ["Edit WindowMode.swift", "Bash: swift build", "Read Locations.swift", "Grep opaqueBounds", "Agent: Review the diff"]
        // Agents join the first villain. Empty project → the label shows the villain's name.
        return villains.enumerated().map { i, l in
            let leader = Universe.shown.adopt(l)
            var rec = SessionRecord(state: playgroundMood.rawValue, updated: start, leader: leader, project: "")
            rec.created = start - Double(600 + i * 1700)
            // `--missing-time`: the sessions' contexts are compacted two seconds in (The Clawd Files' FBI agents lose time,
            // Stevie Clawdberg's time travellers hit 88 mph, Clawd Slayer's Tabula Rasa eight forget who they are).
            if CommandLine.arguments.contains("--missing-time") { rec.abducted = start + 2 }
            // `--transform`: they change into their other guise two seconds in (Clawds of the Universe), as a compaction
            // would; `--moral`: each gives a lesson two seconds in, as on finishing.
            if CommandLine.arguments.contains("--transform"), Universe.of(leader).transforms,
               let other = Universe.of(leader).guises.first(where: { $0.contains(leader) })?.subtracting([leader]).first {
                rec.leader = other; rec.transformed = start + 2
            }
            if CommandLine.arguments.contains("--moral") { rec.moral = start + 2 }
            // On "Idle", spread them over the idle stages: standing, sitting (2 min+), asleep (5 min+).
            rec.since = playgroundMood == .idle ? start - Double(60 + i * 160) : start - Double(20 + i * 35)
            rec.model = "claude-opus-5-5"
            rec.prompt = prompts[i % prompts.count]
            rec.activity = nowActs[i % nowActs.count]
            rec.reply = "Done. The crew now fits the window and everyone still gets a fight."
            rec.prompts = 4 + i * 3
            rec.tools = 38 + i * 21
            let project = playgroundProjects.isEmpty ? "" : playgroundProjects[i % playgroundProjects.count]
            var snap = SessionSnapshot(id: "pg-\(l)", leader: leader, project: project, mood: playgroundMood, agents: i == 0 ? crew : [],
                                       record: rec)
            if !playgroundAIs.isEmpty {
                snap.assistant = playgroundAIs[i % playgroundAIs.count]
                // a sample model name that matches the AI, for screenshots
                let models = ["codex": "gpt-5-codex", "qwen": "qwen3-coder", "gemini": "gemini-3-pro", "copilot": "copilot-cli",
                              "pi": "devstral-medium"]
                if let m = models[snap.assistant] { snap.record?.model = m }
            }
            return snap
        }
    }

    private func demoSessions(_ t: Double) -> [SessionSnapshot] {
        func agents(_ chars: [Int], session: String) -> [AgentRecord] {
            chars.map { AgentRecord(id: "demo-\($0)", session: session, type: "demo", character: $0,
                                    cast: Universe.shown.adopt(StatusStore.heroBase + $0),
                                    started: demoStart, lastSeen: 0, task: Self.sampleTasks[$0 % Self.sampleTasks.count]) }
        }
        func s(_ leader: Int, _ mood: Mood, _ crew: [Int] = []) -> SessionSnapshot {
            SessionSnapshot(id: "demo-\(leader)", leader: Universe.shown.adopt(leader), project: "project-\(leader + 1)",
                            mood: mood, agents: agents(crew, session: "demo-\(leader)"))
        }
        switch Int(t / 6) % 10 {
        case 0: return [s(0, .idle)]
        case 1: return [s(0, .thinking)]
        case 2: return [s(0, .working)]
        case 3: return [s(0, .waiting)]
        case 4: return [s(0, .working, [0, 1, 2])]
        case 5: return [s(0, .working, [0]), s(1, .working)]                                   // Vader vs Kylo: duel
        case 6: return [s(0, .working), s(3, .working, [1])]                                   // Boba shoots, Vader deflects
        case 7: return [s(0, .thinking, [4]), s(1, .working), s(2, .working), s(5, .working)]  // Maul vs Emperor
        case 8: return [s(0, .working, [3]), s(4, .working, [5])]                             // Stormtrooper vs Vader
        default: return [s(0, .idle, [0, 3, 4])]
        }
    }

    // MARK: Frame loop

    private func tick() {
        let now = Date().timeIntervalSince1970
        let dt = CGFloat(min(0.1, now - lastTick))
        lastTick = now
        actors.removeAll { a in a.leaving.map { now - $0 > (a.exit == nil ? fadeOut : falconExit) } ?? false }

        for i in actors.indices {
            if now < actors[i].born { continue }        // waiting for its turn to walk in
            let d = actors[i].targetX - actors[i].x
            // A Weeping Angle only moves while nobody's looking at it, and then quickly. Held still too long, it gets
            // its chance anyway: somebody blinked.
            var pace: CGFloat = 1
            if actors[i].cast.universe.module.quirks.unseenMovers.contains(actors[i].cast), !dragging, abs(d) >= 0.5 {
                let me = actors[i]
                let seen = actors.contains { o in
                    o.key != me.key && o.leaving == nil && now >= o.born && (o.walkDir != 0 ? o.walkDir : o.facing) * (me.x - o.x) > 0
                }
                if seen && actors[i].watched < 8 {
                    actors[i].watched += dt
                    actors[i].walkDir = 0
                    continue
                }
                actors[i].watched = 0
                pace = 2.5
            }
            if dragging || abs(d) < 0.5 {
                actors[i].x = actors[i].targetX
                actors[i].walkDir = 0
            } else {
                let stepLen = min(abs(d), Self.walkSpeed * pace * zoom * dt)
                actors[i].x += d > 0 ? stepLen : -stepLen
                actors[i].walkDir = d > 0 ? 1 : -1
            }
            // Flyers take off when they set out and come down to land as they arrive (about half a second each way).
            if actors[i].cast.motion == .fly {
                let up: CGFloat = actors[i].walkDir != 0 && abs(d) > 24 * zoom ? 1 : 0
                actors[i].air += max(-dt * 2.2, min(dt * 2.2, up - actors[i].air))
            }
        }

        // Which character is the mouse over? (desktop and window alike: both work in screen coordinates)
        var mouseNow = NSEvent.mouseLocation
        if windowMode, let w = clawdWindow { mouseNow = w.toStage(mouseNow) }   // the window may be drawn smaller
        // In the window the list below shows the sessions, so their hover cards only appear when it's hidden. Agents
        // always get one: a card folds away all but its first few.
        let listShowsSessions = windowMode && (clawdWindow?.window.isVisible != true || ClawdWindow.listShown)
        var hovered = hitRects().first { $0.1.contains(mouseNow) && !(listShowsSessions && !$0.0.hasPrefix("A:")) }?.0
        if windowMode && ClawdWindow.view == .board { hovered = nil }   // the scene is hidden behind the board
        if let forced = Self.forcedHover {   // debug: pretend to hover a character
            hovered = actors.first { $0.key.contains(forced) }?.key
        }
        let hoverChanged = hovered != hoveredKey || listHoverKey != drawnListHover
        drawnListHover = listHoverKey
        hoveredKey = hovered

        // Idle scenes only breathe, so 7.5 fps is plenty; 15 fps when anything is moving (chunky pixel art needs no more).
        frameCount += 1
        let busy = dragging || !fights.isEmpty || actors.contains {
            $0.walkDir != 0 || $0.leaving != nil || now - $0.born < fadeIn || !$0.isLeader
                || $0.mode == .working || $0.mode == .waiting
        }
        guard busy || hoverChanged || frameCount % 2 == 0 else { return }
        guard onScreen || shotPath != nil else { return }   // hidden or fully covered: nothing would show
        // The window's screen-saver view covers the scene strip entirely: no point drawing the crew behind it.
        guard !(windowMode && ClawdWindow.view == .board) || shotPath != nil else { return }

        items = buildItems(now: now)
        if let shotPath, now - lastShot > shotEvery {
            lastShot = now
            shotCount += 1
            writeShot(to: shotPath.replacingOccurrences(of: "%d", with: String(format: "%02d", shotCount)))
        }
        if chaosSeconds != nil, now - lastCheck > 0.25 { lastCheck = now; checkInvariants(now) }

        if windowMode {
            clawdWindow?.sceneView.showFrame()
            return
        }

        // Fit the window around everything that's drawn.
        var bounds = NSRect.null
        for item in items { bounds = bounds.union(item.rect) }
        if bounds.isNull { bounds = NSRect(x: home.x, y: home.y, width: 1, height: 1) }
        bounds = bounds.insetBy(dx: -4, dy: -4).integral
        if bounds != panel.frame { panel.setFrame(bounds, display: false) }

        let mouse = NSEvent.mouseLocation
        let passThrough = !(dragging || hitRects().contains { $0.1.contains(mouse) })
        if panel.ignoresMouseEvents != passThrough { panel.ignoresMouseEvents = passThrough }

        view.showFrame()
    }

    /// Where each character can be hovered or clicked: sessions' leaders first, so they win overlaps over agents.
    /// The one place this is worked out, so hovering and clicking always agree (a flying character included).
    private func hitRects() -> [(String, NSRect)] {
        let s = Self.leaderScale * zoom, c = Self.companionScale * zoom
        return actors.filter { $0.leaving == nil }.sorted { $0.isLeader && !$1.isLeader }.map {
            let up = lastLift[$0.key] ?? 0   // in the air: the hit box goes up with it
            return $0.isLeader ? ($0.key, NSRect(x: $0.x - 16 * s, y: anchor.y + 5 * s + up, width: 32 * s, height: 35 * s))
                               : ($0.key, NSRect(x: $0.x - 16 * c, y: anchor.y + (s - c) * 8 + 5 * c + up, width: 32 * c, height: 35 * c))
        }
    }

    /// Lines for the hover card.
    private func hoverDetail(_ s: SessionSnapshot?, _ a: AgentRecord?, now: Double) -> [String] {
        if let a {
            let who = Cast.of(a)
            var lines = ["\(who.name) · \(a.label.isEmpty ? "Agent" : a.label)"]
            var info = [a.activity ?? "Starting…", Self.duration(now - a.started)]
            if let n = a.tools { info.append("\(n) tool call\(n == 1 ? "" : "s")") }
            lines.append(info.joined(separator: "  ·  "))
            if let owner = sessions.first(where: { $0.id == a.session }) {
                let p = owner.project.isEmpty ? "" : " (\(owner.project))"
                lines.append("Agent of \(Cast(id: owner.leader).name)\(p) · \(owner.aiLabel)")
            }
            return lines
        }
        guard let s else { return [] }
        var lines = [Cast(id: s.leader).name + (s.project.isEmpty ? "" : " · " + s.project) + (s.id == "home" ? "" : " · " + s.aiLabel)]
        let held = Self.duration(now - since(s, now: now))
        switch s.mood {
        case _ where s.stalled: lines.append("Not reporting: restart this Claude session")
        case _ where s.hookSilent: lines.append("Not reporting: " + HookInstaller.silentFix(s.assistant))
        case _ where !s.live: lines.append(s.mood == .working ? "Busy (no live status, no hooks)" : "No live status (no hooks)")
        case .working: lines.append("Working · \(held)")
        case .thinking: lines.append("Thinking · \(held)")
        case .waiting: lines.append("Needs you · \(held)")
        case .background: lines.append("Waiting on: " + backgroundJobs(s) + " · " + held)
        case .idle where !s.agents.isEmpty:
            lines.append("Waiting on \(s.agents.count) agent\(s.agents.count == 1 ? "" : "s") · " + held)
        case .idle: lines.append((now - since(s, now: now) > 300 ? "Asleep · " : "Idle · ") + held)
        }
        if let r = s.record {
            if let act = r.activity, s.mood != .idle { lines.append("Now: " + act) }
            if let p = r.prompt { lines.append("You: “" + (p.count > 60 ? String(p.prefix(59)) + "…" : p) + "”") }
        }
        if !s.agents.isEmpty { lines.append("\(s.agents.count) agent\(s.agents.count == 1 ? "" : "s") at work") }
        lines.append("Click to jump to this session")
        return lines
    }

    /// How often a character says its line (`Cast.callout`), and for how long it stays up, in seconds.
    static let calloutEvery = 45.0, calloutFor = 4.0

    struct DrawItem {
        var image: CGImage?
        var text: NSAttributedString?
        var rect: NSRect
        var mirrored = false
        var alpha: CGFloat = 1
        var boxed = false      // text drawn on a dark rounded box so it reads on any wallpaper
        var agentBox = false   // agents' task boxes get a blue tint to tell them from project names
        var accent: NSColor?   // project colour for the box border
        var speech = false     // a character's line: dark text on a soft cream backing, nothing like the status bubbles
        var upsideDown = false // drawn upside down (the scene turned over, `SceneTurn`)
        var upright = false    // a picture that reads like text (a status bubble): kept upright when the scene turns over
    }

    private func buildItems(now: Double) -> [DrawItem] {
        let t = now - start
        let z = zoom
        let ls = Self.leaderScale * z, cs = Self.companionScale * z
        var out: [DrawItem] = []
        var overlay: [DrawItem] = []

        // Fight roles for pairs that have arrived (not walking); the odd one out cheers.
        func weapon(_ a: Actor) -> Weapon {
            a.cast.weapon
        }
        /// Missing time: an FBI agent's session being taken stops fighting, and the other side holds fire until they're set down.
        func taken(_ a: Actor) -> Bool { a.isLeader && a.abducted.map { now - $0 < missingTimeLength } == true }
        var roles: [String: FightRole] = [:]
        var fx: [(Actor, Actor)] = []
        /// Each fighting pair keeps its own beat: its clock runs this far ahead of the plain one, so with several
        /// pairs on screen they don't all strike at once. The two in a pair share it, so they still trade blows.
        var fightPhase: [String: Double] = [:]
        /// The clock a character's fight moves (and its effects) run on.
        func ft(_ key: String) -> Double { t + (fightPhase[key] ?? 0) }
        var incoming: [String: Double] = [:]   // blaster-vs-blaster: each defender → its shooter's clock offset
        var held: Set<String> = []             // caught in a telekinetic grip (`Magic.grip`): lifted off the ground
        for fight in fights {
            guard let a = actors.first(where: { $0.key == fight.a && $0.leaving == nil }),
                  let b = actors.first(where: { $0.key == fight.b && $0.leaving == nil }),
                  a.walkDir == 0, b.walkDir == 0, !taken(a), !taken(b) else { continue }
            let (l, r) = a.x <= b.x ? (a, b) : (b, a)
            let (lRole, rRole) = fightRoles(weapon(l), weapon(r))
            roles[l.key] = lRole; roles[r.key] = rRole
            fx.append((l, r))
            // Han and Greedo stay on the plain clock: Han shooting first is timed to one of his own shots.
            let shootsFirst = ShootOut.between(l.cast, r.cast) != nil
            let phase = shootsFirst ? 0 : fightPhaseOffset(l.key, r.key)
            fightPhase[l.key] = phase; fightPhase[r.key] = phase
            if case .shoot(let lo) = lRole, case .shoot(let ro) = rRole { incoming[l.key] = ro; incoming[r.key] = lo }
            if case .zap = lRole, l.cast.persona.magic.grip { held.insert(r.key) }
            if case .zap = rRole, r.cast.persona.magic.grip { held.insert(l.key) }
        }
        for a in actors where cheering.contains(a.key) && a.walkDir == 0 && a.leaving == nil { roles[a.key] = .cheer }

        // Han shoots first: while the two stand facing off, now and then his bolt gets through. It starts on one of
        // Han's own shots, so the bolt leaves his blaster; anyone walking off or leaving calls it off.
        var shot: (han: String, greedo: String, e: Double, line: String, says: String)?
        if let pair = fx.first(where: { ShootOut.between($0.0.cast, $0.1.cast) != nil }),
           let (out, leftShoots) = ShootOut.between(pair.0.cast, pair.1.cast) {
            let han = leftShoots ? pair.0 : pair.1, greedo = leftShoots ? pair.1 : pair.0
            if let s = greedoShot, s.han != han.key || s.greedo != greedo.key { greedoShot = nil }
            if let s = greedoShot, now - s.start > ShootsFirst.done {
                greedoShot = nil
                nextShootsFirst = now + ShootsFirst.delay(first: false)
            }
            // Indy fights with his whip: as his moment comes he puts it away and draws his revolver instead.
            if out.drawsGun, greedoShot != nil || nextShootsFirst.map({ now >= $0 - 1.2 }) == true {
                roles[han.key] = .shoot(offset: 0)
            }
            if greedoShot == nil {
                if let next = nextShootsFirst, now >= next, case .shoot(let offset)? = roles[han.key] {
                    let fire = (floor((t + offset) / blasterPeriod) + 1) * blasterPeriod - offset
                    greedoShot = (han.key, greedo.key, start + fire, out.comebacks.randomElement() ?? "That hurt!")
                    nextShootsFirst = nil
                } else if nextShootsFirst == nil {
                    nextShootsFirst = now + ShootsFirst.delay(first: true)
                }
            }
            if let s = greedoShot, now >= s.start {
                let e = now - s.start
                shot = (s.han, s.greedo, e, s.line, out.says)
                incoming[s.han] = nil; incoming[s.greedo] = nil   // nobody ducks: Greedo doesn't see it coming
                if e > ShootsFirst.hit + 0.3 { roles[s.han] = .rest }   // blaster down, job done
            }
        } else {
            greedoShot = nil
            nextShootsFirst = nil
        }

        if debug, Int(now * 2) != lastDebug {
            lastDebug = Int(now * 2)
            let line = actors.map { a in
                "\(a.key) x=\(Int(a.x)) tgt=\(Int(a.targetX)) walk=\(Int(a.walkDir)) face=\(Int(a.facing)) mood=\(a.mood) role=\(roles[a.key].map { "\($0)" } ?? "-")"
            }.joined(separator: " | ")
            FileHandle.standardError.write("fights=\(fights.count) \(line)\n".data(using: .utf8)!)
        }

        let screenFrame = stage, ground = anchor.y
        var labels: [(item: DrawItem, leader: Bool, focused: Bool, key: String)] = []
        var listHoverHead: (key: String, x: CGFloat, top: CGFloat)?   // the character picked out from the list
        // Speech bubbles are placed after the names (see below), so they're kept here till then.
        var speeches: [(key: String, item: DrawItem)] = []   // lines said over a head, placed above its name tag
        var asides: [DrawItem] = []                           // lines said beside a head, placed last (see below)
        var bubbles: [(key: String, x: CGFloat, y: CGFloat, kind: BubbleKind, urgent: Bool, preferRight: Bool, alpha: CGFloat)] = []
        // While a universe's husher is on stage (Clawd Slayer's Gentlemen) nobody has a voice: every line comes up an empty bubble.
        let hushed = actors.contains { $0.leaving == nil && now >= $0.born && $0.cast.universe.module.quirks.hushers.contains($0.cast) }
        // Companions first so leaders (and their sabers) draw on top.
        var falconItems: [DrawItem] = []
        for var actor in actors.sorted(by: { !$0.isLeader && $1.isLeader }) {
            var walking = actor.walkDir != 0
            var facing = walking ? actor.walkDir : actor.facing
            let quirks = actor.cast.universe.module.quirks, me = stageView(actor)
            let others = quirks.remark == nil && quirks.jitter == nil ? [] : actors.filter { $0.key != actor.key }.map(stageView)
            let bunTalk = walking || roles[actor.key] != nil ? nil : quirks.remark?(me, others, z, t)
            if let b = bunTalk { facing = b.facing }
            var aboard = false
            if let exit = actor.exit, let left = actor.leaving {
                // Picked up by its ship, by phase: fly in (0–0.3), ramp down, it walks up (0.36–0.62),
                // ramp up, lift off and away (0.72–1).
                let p = min(1, (now - left) / falconExit)
                let cs0 = Self.companionScale * z
                // Where they board, left of the ride's centre (`Ride.boardingOffset`).
                let rampFoot = exit.landX - exit.dir * (actor.cast.ride?.boardingOffset ?? 14) * cs0
                if p >= 0.36 && p < 0.62 {
                    let k = (p - 0.36) / 0.26
                    actor.x = exit.startX + (rampFoot - exit.startX) * CGFloat(k)
                    walking = true; facing = exit.dir
                } else if p >= 0.62 {
                    aboard = true
                } else {
                    actor.x = exit.startX
                    facing = exit.dir
                }
                if let ride = actor.cast.ride {
                    falconItems.append(falconItem(exit, ride: ride, p: p, ground: ground + (ls - cs0) * 8 + 8 * cs0, scale: cs0))
                }
            }
            if aboard { continue }
            if now < actor.born { continue }             // not on stage yet: don't draw what won't be shown
            var canvas = PixelCanvas(Sprite.width, Sprite.height)
            let scale: CGFloat
            let y: CGFloat
            // Flyers ride up to `flightHeight` while they travel, and now and then take to the air where they stand
            // (fighting from up there, if they shoot or cast); Spider-Man swings along in arcs on a web line, the Bat-family
            // on grapnel lines.
            let air = self.air(actor, role: roles[actor.key], walking: walking, t: ft(actor.key))
            // Mayor Wilclawds wipes his hands after every duel (Clawd Slayer): his signature, once he's standing still.
            let wipe = afterDuel.wipe(actor.key, actor.cast, inFight: roles[actor.key] != nil,
                                      free: !walking && !actor.sitting && actor.leaving == nil, now: now)
            if let w = wipe {
                forcedHabit = w
                actor.cast.draw(canvas, t: t + actor.phase, mode: .idle, walking: false, role: .none, asSession: true)
                forcedHabit = nil
            }
            switch actor.kind {
            case .leader(let who):
                let role = roles[actor.key]
                if wipe == nil {
                    who.draw(canvas, t: ft(actor.key), mode: role != nil ? .working : actor.mode, walking: walking, role: role ?? .none,
                             urgent: actor.urgent && role == nil, sitting: actor.sitting, asSession: true,
                             airborne: walking && air > 0.3, aloft: !walking && air > 0.3)
                }
                if let r = actor.regenerated, let reg = actor.cast.universe.module.regeneration, now - r < reg.length {
                    reg.draw(canvas, (now - r) / reg.length, t)
                }
                if let r = actor.transformed, let tr = actor.cast.universe.module.transformation, now - r >= 0, now - r < tr.length {
                    tr.draw(canvas, (now - r) / tr.length, t, actor.cast)
                }
                scale = ls; y = ground
            case .agent(let who):
                let role = roles[actor.key]
                if wipe == nil {
                    who.draw(canvas, t: role != nil ? ft(actor.key) : t + actor.phase, mode: .working, walking: walking,
                             role: role ?? .none, asSession: false, airborne: walking && air > 0.3, aloft: !walking && air > 0.3)
                }
                scale = cs; y = ground + (ls - cs) * 8
            }
            var pivotX = Sprite.bodyCenterX, knockedTop: Int?
            var lift = air * Self.flightHeight * scale
            // Held in a telekinetic grip: hauled off the ground and kicking, on the fight's clock.
            if held.contains(actor.key) {
                let k = gripHold(ft(actor.key))
                lift += CGFloat(k * gripHeight) * scale
                if k > 0.6 { actor.x += (noise(Int(t * 24)) > 0.5 ? 1 : -1) * scale }
            }
            // Greedo, shot: knocked head over heels, flat on his back, back on his feet (his own, bigger canvas).
            if let s = shot, actor.key == s.greedo, s.e >= ShootsFirst.hit {
                let pose = ShootsFirst.pose(s.e), who = actor.cast
                let knocked = ShootsFirst.sprite(e: s.e, t: t) { c in
                    who.draw(c, t: t, mode: .idle, walking: pose.walking, role: .none, asSession: true)
                }
                canvas = knocked.canvas; knockedTop = knocked.top; pivotX = ShootsFirst.pivotX
                actor.x -= facing * CGFloat(pose.back) * scale
                lift = CGFloat(pose.lift) * scale
                walking = pose.walking
            }
            if actor.cast.motion == .swing, walking {
                let swing = actor.x / (70 * z)
                lift = abs(sin(swing * .pi)) * 16 * scale
                if let web = webLine(from: NSPoint(x: actor.x + facing * 13 * scale, y: y + lift + 30 * scale),   // the raised hand, (41, 22)
                                     anchor: NSPoint(x: (floor(swing) + 0.5) * 70 * z + facing * 20 * z, y: y + 90 * scale),
                                     scale: scale, universe: actor.cast.universe) {
                    out.append(web)
                }
            }
            // A signature that climbs a thread (`Persona.climb`, Shellob): risen and faded by the move, its thread from the
            // body up towards the top of the stage (the screen, or the window's scene).
            let climb = drawnSignature.flatMap { p in actor.cast.persona.climb.map { (move: $0, p: p) } }
            if let cl = climb {
                lift += CGFloat(cl.move.rise(cl.p)) * scale
                let from = NSPoint(x: actor.x + facing * CGFloat(cl.move.from.x - pivotX) * scale,
                                   y: y + lift + CGFloat(Double(Sprite.height) - cl.move.from.y) * scale)
                let reach = from.y + (stage.maxY - from.y) * CGFloat(cl.move.thread(cl.p))
                if reach > from.y + scale, var web = webLine(from: from, anchor: NSPoint(x: from.x, y: reach), scale: scale,
                                                             universe: actor.cast.universe) {
                    web.alpha = CGFloat(cl.move.alpha(cl.p))          // the thread fades with her
                    out.append(web)
                }
            }
            // Missing time: lifted away in a beam of light and set back down (The Clawd Files' FBI agents); 88 mph,
            // gone in a flash and back with three booms (Stevie Clawdberg's time travellers); Willow's forgetting spell,
            // cast and broken (Clawd Slayer's Tabula Rasa eight).
            let tripK = actor.isLeader ? actor.abducted.flatMap { now - $0 < missingTimeLength ? (now - $0) / missingTimeLength : nil } : nil
            let away = tripK.flatMap { actor.cast.universe.module.compactionLook(k: $0, cast: actor.cast) }
            if let away {
                lift += CGFloat(away.lift) * scale
                for l in away.layers(cast: actor.cast, x: actor.x, y: y, lift: lift, scale: scale, facing: facing, t: t) {
                    out.append(DrawItem(image: l.image, rect: l.rect, mirrored: l.mirrored, alpha: 1))
                }
                away.touch(canvas, t: t)
            }
            lastLift[actor.key] = lift
            canvas.addOutline(AIStyle.outline(actor.assistant))
            guard let img = canvas.makeImage() else { continue }
            var alpha = min(1, (now - actor.born) / 0.25)
            if let away { alpha = min(alpha, away.alpha) }
            if let cl = climb { alpha = min(alpha, cl.move.alpha(cl.p)) }
            var drop = 0.0
            if let left = actor.leaving, actor.exit == nil {
                let f = min(1, (now - left) / fadeOut)
                alpha = min(alpha, 1 - f)
                drop = actor.cast.motion == .fly ? f * 60 : -f * 30   // flyers take off; the rest sink away
            }
            let mirrored = facing < 0
            let bodyX = (mirrored ? CGFloat(canvas.w) - CGFloat(pivotX) : CGFloat(pivotX)) * scale
            // Ducking a bolt in a shoot-out: squat (squashed from the feet up).
            let duck = incoming[actor.key].map { CGFloat(duckAmount(t: ft(actor.key), shooterOffset: $0, armoured: actor.cast.armoured)) } ?? 0
            // Captain Clawd flinches at every tick of the Croc Clock (Stevie Clawdberg), in Pirate Town or with it about.
            let flinch: (dx: Int, up: Int, line: String?) = quirks.jitter?(me, others, location, t) ?? (0, 0, nil)
            actor.x += CGFloat(flinch.dx) * scale   // its name tag and speech bubble go with it
            let rect = NSRect(x: (actor.x - bodyX).rounded(), y: y + CGFloat(drop) * z + lift + CGFloat(flinch.up) * scale,
                              width: CGFloat(canvas.w) * scale, height: (CGFloat(canvas.h) * scale * (1 - 0.22 * duck)).rounded())
            if windowMode, actor.key == listHoverKey, let glow = Self.hoverGlow {
                let gw = 30 * scale, gh = 8 * scale
                out.append(DrawItem(image: glow, rect: NSRect(x: (actor.x - gw / 2).rounded(), y: y + lift - gh / 2, width: gw, height: gh),
                                    alpha: CGFloat(alpha)))
                var top = CGFloat(Sprite.height - actor.cast.drawnTop()) * scale
                if case .leader = actor.kind { top += 8 * z } else { top += 5 * z }
                listHoverHead = (actor.key, actor.x, y + lift + top)
            }
            out.append(DrawItem(image: img, rect: rect, mirrored: mirrored, alpha: CGFloat(alpha)))
            // A prop beside them (T. Wrecks's glass of water).
            if let p = quirks.prop?(OnStage(cast: me.cast, x: me.x, facing: facing, walking: walking, leaving: me.leaving, phase: me.phase,
                                            scale: scale), y, scale, t) {
                out.append(DrawItem(image: p.image, rect: p.rect, mirrored: p.mirrored, alpha: 1))
            }

            // Speech bubble on whichever side of the head fits on screen (Claudes only).
            var bubbleSpan: (minX: CGFloat, maxX: CGFloat, maxY: CGFloat)?
            if actor.isLeader, let kind = actor.bubble {
                let w = CGFloat(Bubble.width) * ls
                let rightX = actor.x + 13 * ls, leftX = actor.x - 13 * ls - w
                // On the side away from the nearest neighbour (so it's clearly this Claude's),
                // unless that side is off screen.
                let nearest = actors.filter { $0.key != actor.key && $0.leaving == nil }
                    .min { abs($0.x - actor.x) < abs($1.x - actor.x) }
                let preferRight = nearest.map { $0.x < actor.x } ?? true
                let onRight = preferRight ? rightX + w <= screenFrame.maxX : leftX < screenFrame.minX
                let h = CGFloat(Bubble.height) * ls
                let by = y + lift + CGFloat(Sprite.height - 1 - Bubble.height + actor.cast.bubbleLift) * ls
                let bx = onRight ? rightX : leftX
                bubbleSpan = (bx, bx + w, by + h)
                bubbles.append((actor.key, actor.x, by, kind, actor.urgent, onRight, CGFloat(alpha)))
            }

            // Some sessions have a line they say now and then (`Cast.callout`): about once every `calloutEvery`
            // seconds, each on its own beat, up long enough to read. Han and Greedo have words after a shot, over their
            // heads, clear of the fight.
            var line: String?, overHead = false
            if case .leader(let who) = actor.kind, let said = who.callout, actor.walkDir == 0,
               (t / Self.calloutEvery + actor.phase).truncatingRemainder(dividingBy: 1) < Self.calloutFor / Self.calloutEvery {
                line = said
            }
            if let s = shot {
                if actor.key == s.han, s.e >= ShootsFirst.hanLine.from, s.e < ShootsFirst.hanLine.to { line = s.says; overHead = true }
                if actor.key == s.greedo, s.e >= ShootsFirst.standing { line = s.line; overHead = true }
            }
            if let b = bunTalk { line = b.line; overHead = true }
            if let said = flinch.line { line = said; overHead = true }
            // A lesson on finishing (Clawds of the Universe's moral of the story), the same one all the while it's up.
            if actor.isLeader, let m = actor.moral, now - m >= 0, now - m < moralLength, actor.walkDir == 0 {
                let lessons = actor.cast.universe.module.morals
                if !lessons.isEmpty { line = lessons[abs(Int(m)) % lessons.count] }
            }
            // "I have the power!": what a leader says as it turns into its other guise.
            if actor.isLeader, let r = actor.transformed, let tr = actor.cast.universe.module.transformation,
               now - r >= 0, now - r < tr.length, let said = tr.says(actor.cast) {
                line = said; overHead = true
            }
            if hushed, let said = line { line = StageQuirks.hushed(said) }
            if let caption = away?.caption { line = caption; overHead = true }
            if let line {
                let sc = actor.isLeader ? ls : cs
                // Dark ink on a cream backing (`OverlayView.render`), so it reads on any place: bare text with an
                // outline got lost in busy, bright scenes.
                let callout = NSAttributedString(string: line, attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: max(9, 10 * z), weight: .heavy),
                    .foregroundColor: NSColor(calibratedRed: 0.16, green: 0.11, blue: 0.08, alpha: 1),
                ])
                let ts = callout.size()
                let size = NSSize(width: (ts.width + 10 * z).rounded(.up), height: (ts.height + 4 * z).rounded(.up))
                // On the side away from the speech bubble, level with the head; but never over a neighbour (in a fight
                // they stand close, and the line read as theirs): the other side if that one's clear, else over the head.
                let onLeft = bubbleSpan.map { $0.minX > actor.x } ?? (facing > 0)
                let leftX = actor.x - 16 * sc - size.width, rightX = actor.x + 16 * sc
                let bodies = actors.filter { $0.key != actor.key && $0.leaving == nil }
                    .map { ($0.x, 15 * ($0.isLeader ? ls : cs)) }
                func clear(_ x0: CGFloat) -> Bool {
                    x0 >= screenFrame.minX && x0 + size.width <= screenFrame.maxX
                        && !bodies.contains { $0.0 + $0.1 > x0 && $0.0 - $0.1 < x0 + size.width }
                }
                var cx = onLeft ? leftX : rightX
                if !clear(cx) {
                    if clear(onLeft ? rightX : leftX) { cx = onLeft ? rightX : leftX } else { overHead = true }
                }
                var cy = y + 33 * sc + lift
                if overHead {
                    // Over the head; once the name tags are placed, it moves up above this one's (see below).
                    cx = actor.x - size.width / 2
                    cy = y + CGFloat(Sprite.height - actor.cast.drawnTop()) * sc + 8 * z
                    if let away { cy += CGFloat(away.markRoom) * sc }   // above a mark (the forgetting spell's "?")
                }
                cx = min(max(cx, screenFrame.minX + 2), screenFrame.maxX - size.width - 2)
                let item = DrawItem(text: callout, rect: NSRect(x: cx.rounded(), y: cy, width: size.width, height: size.height),
                                    alpha: CGFloat(alpha), speech: true)
                if overHead { speeches.append((actor.key, item)) } else { asides.append(item) }
            }

            // Project name (Claudes) or task (agents) just above the head, centred on it. Speech bubbles make way for it.
            if (actor.isLeader ? showLabels : showAgentLabels) && !actor.label.isEmpty {
                // The project you're in (its terminal in front) gets its name 15% larger.
                let big: CGFloat = actor.isLeader && actor.focused ? 1.15 : 1
                let font = actor.isLeader ? NSFont.monospacedSystemFont(ofSize: max(9, 10 * z) * big, weight: .bold)
                                          : NSFont.monospacedSystemFont(ofSize: max(8, 8.5 * z), weight: .semibold)
                let centered = NSMutableParagraphStyle()
                centered.alignment = .center
                let lines = wrapLabel(actor.label, font: font, maxWidth: (actor.isLeader ? 110 * big : 88) * z)
                let text = NSAttributedString(string: lines.joined(separator: "\n"), attributes: [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .paragraphStyle: centered,
                ])
                let textSize = text.size()
                let size = NSSize(width: textSize.width + 10 * z, height: textSize.height + 4 * z)
                var lx = actor.x - size.width / 2
                // Never past the screen edge.
                lx = min(max(lx, screenFrame.minX + 2), screenFrame.maxX - size.width - 2)
                var headTop: CGFloat
                switch actor.kind {
                case .leader(let who):
                    // Its drawn top (the tauntaun's horns), lower when it's sitting down.
                    let seated = actor.sitting && roles[actor.key] == nil && !walking && (actor.mode == .idle || actor.mode == .standGuard)
                    headTop = CGFloat(Sprite.height - who.drawnTop(sitting: seated)) * ls + 8 * z
                case .agent(let who): headTop = CGFloat(Sprite.height - who.drawnTop()) * cs + 5 * z
                }
                headTop += lift
                if let away { headTop += CGFloat(away.markRoom) * scale }   // a mark (the forgetting spell's "?") goes under it
                if let top = knockedTop { headTop = CGFloat(canvas.h - top) * scale + (actor.isLeader ? 8 : 5) * z + lift }
                do {
                    let ly = y + CGFloat(drop) * z + headTop
                    labels.append((DrawItem(text: text, rect: NSRect(x: lx.rounded(), y: ly,
                                                                     width: size.width, height: size.height),
                                            alpha: CGFloat(alpha), boxed: true, agentBox: !actor.isLeader, accent: actor.accent),
                                   actor.isLeader, actor.focused, actor.key))
                }
            }
        }

        overlay += falconItems

        // Bolts, deflections, lightning and sparks between fighters.
        for (l, r) in fx {
            let margin = 24.0
            let dist = Double((r.x - l.x) / ls)
            let width = Int(dist + margin * 2)
            guard width > 0, width < 4000 else { continue }
            let left = l.x - CGFloat(margin) * ls
            // The effects canvas reaches `headroom` rows above a standing leader's, for whoever is fighting from the air.
            let headroom = Int(Self.flightHeight) + 8
            func fighter(_ a: Actor, side: Double) -> Fighter {
                let sc = a.isLeader ? ls : cs
                let lift = (a.isLeader ? 0 : (ls - cs) * 8) + self.air(a, role: roles[a.key], walking: false, t: ft(a.key)) * Self.flightHeight * sc
                    + (held.contains(a.key) ? CGFloat(gripHold(ft(a.key)) * gripHeight) * sc : 0)
                return Fighter(weapon: weapon(a), x: Double((a.x - left) / ls), k: Double(sc / ls),
                               top: Double((CGFloat(Sprite.height) * (ls - sc) - lift) / ls) + Double(headroom), side: side,
                               muzzle: a.cast.muzzle, armoured: a.cast.armoured, pivot: a.cast.weaponPivot).dressed(as: a.cast)
            }
            let fl = fighter(l, side: 1), fr = fighter(r, side: -1)
            let shotHere = shot.flatMap { s in Set([l.key, r.key]) == [s.han, s.greedo] ? s : nil }
            guard shotHere != nil || fightFXVisible(t: ft(l.key), fl.weapon, fr.weapon) else { continue }   // e.g. a duel between clashes
            let c = PixelCanvas(width, Sprite.height + headroom)
            if let s = shotHere {
                ShootsFirst.drawFX(c, e: s.e, t: t, han: l.key == s.han ? fl : fr, greedo: l.key == s.han ? fr : fl)
            } else {
                drawFightFX(c, t: ft(l.key), left: fl, right: fr)
            }
            if let img = c.makeImage() {
                overlay.append(DrawItem(image: img, rect: NSRect(x: left.rounded(), y: ground,
                                                                 width: CGFloat(width) * ls,
                                                                 height: CGFloat(Sprite.height + headroom) * ls)))
            }
        }

        // Names never overlap (from agent-view): Claudes' get first pick, then agents'; one that would collide with
        // another moves up a row. Speech bubbles don't move names: they're placed after, round them.
        var placed: [NSRect] = []
        var named: [(item: DrawItem, focused: Bool, key: String)] = []
        for l in labels.sorted(by: { $0.leader && !$1.leader }) {
            var r = l.item.rect
            var tries = 0
            while tries < 6, placed.contains(where: { $0.insetBy(dx: -2 * z, dy: -1 * z).intersects(r) }) {
                r.origin.y += r.height + 2 * z
                tries += 1
            }
            placed.append(r)
            let item = l.item
            named.append((DrawItem(text: item.text, rect: r, alpha: item.alpha, boxed: true, agentBox: item.agentBox, accent: item.accent),
                          l.focused, l.key))
        }
        // Each speech bubble beside its Claude's head, on the side away from its nearest neighbour; else the other
        // side; else just above its own name. Whichever first stays on screen and clear of every name and bubble.
        var taken = placed
        for b in bubbles {
            let w = CGFloat(Bubble.width) * ls, h = CGFloat(Bubble.height) * ls
            let right = NSRect(x: b.x + 13 * ls, y: b.y, width: w, height: h)
            let left = NSRect(x: b.x - 13 * ls - w, y: b.y, width: w, height: h)
            let own = named.first { $0.key == b.key }?.item.rect
            let above = NSRect(x: b.x - w / 2, y: max(b.y, (own?.maxY ?? b.y) + 2 * z), width: w, height: h)
            let free = { (r: NSRect) in
                r.minX >= screenFrame.minX && r.maxX <= screenFrame.maxX
                    && !taken.contains { $0.insetBy(dx: -2 * z, dy: -1 * z).intersects(r) }
            }
            let sides = b.preferRight ? [right, left] : [left, right]
            let r = sides.first(where: free) ?? above
            taken.append(r)
            let bc = PixelCanvas(Bubble.width, Bubble.height)
            drawBubble(bc, kind: b.kind, t: t, urgent: b.urgent, tailRight: r.midX < b.x)
            if let bimg = bc.makeImage() {
                overlay.append(DrawItem(image: bimg, rect: NSRect(x: r.minX.rounded(), y: r.minY, width: w, height: h), alpha: b.alpha,
                                        upright: true))
            }
        }
        for n in named {
            overlay.append(n.item)
            if n.focused {
                // Bobbing marker over the Claude whose terminal you're in.
                let r = n.item.rect
                let caret = PixelCanvas(3, 3)
                drawFocusCaret(caret)
                if let img = caret.makeImage() {
                    let cw = 3 * 2.5 * z, bob = (sin(t * 3.3) * 1.5 * z).rounded()
                    overlay.append(DrawItem(image: img, rect: NSRect(x: (r.midX - cw / 2).rounded(), y: r.maxY + 3 * z + bob,
                                                                     width: cw, height: cw)))
                }
            }
        }
        // The character whose card row the mouse is over: a violet arrow bobbing over its head (over its name tag
        // when it has one), pointing down at it.
        if let h = listHoverHead {
            let above = named.first { $0.key == h.key }.map { $0.item.rect.maxY + ($0.focused ? 14 * z : 3 * z) } ?? h.top
            let arrow = PixelCanvas(5, 4)
            arrow.pattern(0, 0, ["VVVVV", ".VVV.", "..V..", "....."], ["V": C(0xB89CFF)])
            if let img = arrow.makeImage() {
                let aw = 5 * 2.5 * z, ah = 4 * 2.5 * z, bob = (sin(t * 4) * 1.5 * z).rounded()
                overlay.append(DrawItem(image: img, rect: NSRect(x: (h.x - aw / 2).rounded(), y: above + 2 * z + bob, width: aw, height: ah)))
            }
        }
        // Lines never cover each other: one that would overlap a line already showing moves up a row at a time, only
        // as far as it has to (a line that overlaps nothing stays where it is). Lines over a head (Han and Greedo, a
        // flinch, a caption) are placed first; the now-and-then ones beside a head after them. One that still can't
        // find room in a few rows, or would go off the top, waits for its next turn.
        var said: [NSRect] = []
        func say(_ item: DrawItem) {
            var r = item.rect
            let gap = 2 * z
            for _ in 0..<4 {
                guard let hit = said.first(where: { $0.insetBy(dx: -4 * z, dy: -gap).intersects(r) }) else {
                    guard r.maxY <= screenFrame.maxY else { return }
                    said.append(r)
                    overlay.append(DrawItem(text: item.text, rect: r, alpha: item.alpha, speech: true))
                    return
                }
                r.origin.y = hit.maxY + gap
            }
        }
        for sp in speeches {
            var r = sp.item.rect
            if let tag = named.first(where: { $0.key == sp.key })?.item.rect { r.origin.y = max(r.minY, tag.maxY + 2 * z) }
            say(DrawItem(text: sp.item.text, rect: r, alpha: sp.item.alpha, speech: true))
        }
        for item in asides { say(item) }
        // Hover card (from agent-view's hover-for-details): next to the character, kept on screen.
        if let key = hoveredKey, let actor = actors.first(where: { $0.key == key && $0.leaving == nil }), !actor.detail.isEmpty {
            let text = NSMutableAttributedString()
            for (i, line) in actor.detail.enumerated() {
                let last = i == actor.detail.count - 1 && actor.isLeader
                text.append(NSAttributedString(string: (i == 0 ? "" : "\n") + line, attributes: [
                    .font: i == 0 ? NSFont.systemFont(ofSize: 12, weight: .bold) : NSFont.systemFont(ofSize: 11, weight: last ? .regular : .medium),
                    .foregroundColor: i == 0 ? NSColor.white : (last ? NSColor(white: 0.6, alpha: 1) : NSColor(white: 0.85, alpha: 1)),
                ]))
            }
            let ts = text.size()
            let size = NSSize(width: ts.width + 16, height: ts.height + 10)
            let s = actor.isLeader ? ls : cs
            var x = actor.x + 18 * s, y = ground + (actor.isLeader ? 10 : 18) * ls
            if x + size.width > screenFrame.maxX - 4 { x = actor.x - 18 * s - size.width }
            x = min(max(x, screenFrame.minX + 4), screenFrame.maxX - size.width - 4)
            y = min(y, screenFrame.maxY - size.height - 4)
            overlay.append(DrawItem(text: text, rect: NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height),
                                    alpha: 1, boxed: true, accent: actor.accent ?? NSColor(white: 0.6, alpha: 1)))
        }

        // OFFLINE banner on the desktop (the window shows it above the cards): never show stale data silently.
        if let reason = offlineReason ?? hookBanner, !windowMode, let first = actors.first(where: { $0.isLeader && $0.leaving == nil }) {
            let text = NSAttributedString(string: reason, attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: NSColor(srgbRed: 1, green: 0.72, blue: 0.72, alpha: 1)])
            let ts = text.size()
            let size = NSSize(width: ts.width + 16, height: ts.height + 8)
            let x = min(max(first.x - size.width / 2, screenFrame.minX + 4), screenFrame.maxX - size.width - 4)
            let y = ground + CGFloat(Sprite.height) * ls + 26 * z
            overlay.append(DrawItem(text: text, rect: NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height),
                                    alpha: 0.75 + 0.25 * CGFloat(sin(t * 4)), boxed: true, accent: NSColor(srgbRed: 0.9, green: 0.2, blue: 0.2, alpha: 1)))
        }
        return out + overlay
    }

    /// How high a flyer cruises, in canvas pixels.
    static let flightHeight: CGFloat = 16
    /// How far each character was lifted in the last frame (flying, swinging), for hit testing.
    private var lastLift: [String: CGFloat] = [:]
    /// Han shoots first (`ShootsFirst`, Star Wars): who's who, when Han fired (it plays out from there) and Greedo's
    /// line after.
    private var greedoShot: (han: String, greedo: String, start: Double, line: String)?
    private var nextShootsFirst: Double?
    /// Who was in a fight (or cheering one) and when it ended, for Mayor Wilclawds' wet wipe (`AfterDuel`).
    private var afterDuel = AfterDuel()

    /// How far up (0…1 of `flightHeight`) `a` is right now: taking off or landing on a trip along the line, or out on a
    /// sortie (`sortieAir`), never while sitting, waiting for you, cheering or on its way out.
    private func air(_ a: Actor, role: FightRole?, walking: Bool, t: Double) -> CGFloat {
        var fighting = false, cheering = false
        if let role { if case .cheer = role { cheering = true } else { fighting = true } }
        let grounded = walking || a.sitting || a.mode == .waiting || a.leaving != nil || cheering
        // Not in the middle of push-ups, squats or meditating on its own (`Drills.swift`).
        let drilling = role == nil && a.isLeader && a.mode == .working && a.cast.drill(at: t)?.kind.grounded == true
        let sortie = grounded || drilling ? 0 : sortieAir(a.cast, seed: frac(a.phase / 7), fighting: fighting, t: t)
        return max(a.air, CGFloat(sortie))
    }

    /// A web line from a swinging hand up to where it's stuck, as a thin white line `scale` points per pixel; in DC, a
    /// grapnel line, a thin steel-grey cable.
    private func webLine(from a: NSPoint, anchor b: NSPoint, scale: CGFloat, universe: Universe) -> DrawItem? {
        let minX = min(a.x, b.x), minY = min(a.y, b.y)
        let w = Int(abs(b.x - a.x) / scale) + 3, h = Int(abs(b.y - a.y) / scale) + 3
        guard w > 0, h > 0, w < 2000, h < 2000 else { return nil }
        let c = PixelCanvas(w, h)
        // Canvas rows run top down, screen y bottom up.
        let ax = Double((a.x - minX) / scale) + 1, ay = Double(h) - 1 - Double((a.y - minY) / scale)
        let bx = Double((b.x - minX) / scale) + 1, by = Double(h) - 1 - Double((b.y - minY) / scale)
        let line = universe.module.swingLine ?? C(0xF4F4F8, 0.9)
        c.glowLine(ax, ay, bx, by, core: line, glow: C(0xFFFFFF, 0), coreR: 0.35, glowR: 0.4)
        return DrawItem(image: c.makeImage(), rect: NSRect(x: (minX - scale).rounded(), y: (minY - scale).rounded(),
                                                           width: CGFloat(w) * scale, height: CGFloat(h) * scale))
    }

    /// The ship (`ride`) at phase `p` of picking someone up. `feet` is the ground line in screen coordinates.
    private func falconItem(_ exit: (landX: CGFloat, dir: CGFloat, startX: CGFloat), ride: Ride, p: Double, ground feet: CGFloat,
                            scale s: CGFloat) -> DrawItem {
        let z = zoom
        var x = exit.landX, lift: CGFloat = 0
        var ramp = 0.0, engines = false, gear = true
        var alpha: CGFloat = 1
        if ride.materialises {
            // The TARDIS fades in where it stands, wheezing in and out of view with its lamp flashing; the door opens,
            // they step in, and it fades away the same way.
            let pulse = { (k: Double) -> CGFloat in CGFloat(min(1, max(0, k * (0.75 + 0.25 * sin(k * 7 * .pi))))) }
            if p < 0.3 { alpha = pulse(p / 0.3); engines = Int(p * 40) % 2 == 0 }
            else if p < 0.72 { ramp = p < 0.36 ? (p - 0.3) / 0.06 : (p < 0.64 ? 1 : max(0, 1 - (p - 0.64) / 0.06)) }
            else { alpha = pulse(1 - (p - 0.72) / 0.28); engines = Int(p * 40) % 2 == 0 }
            // A spare row under it for the outline round its base, and placed a row lower to match.
            let c = PixelCanvas(Ride.width, ride.canvasHeight + 1)
            drawRide(c, ride, ramp: ramp, engines: engines, gear: true)
            c.addOutline(C(0xFFFFFF, 0.92))
            let w = CGFloat(Ride.width) * s, h = CGFloat(ride.canvasHeight + 1) * s
            return DrawItem(image: c.makeImage(), rect: NSRect(x: (x - w / 2).rounded(), y: (feet - 2 * s).rounded(), width: w, height: h),
                            mirrored: exit.dir < 0, alpha: alpha)
        }
        let flight: CGFloat = ride.drives ? 0 : 1      // a car comes along the ground
        if p < 0.3 {                                   // swoops in overhead and settles
            let e = CGFloat(1 - pow(1 - p / 0.3, 2))
            x = exit.landX - exit.dir * 260 * z * (1 - e)
            lift = 150 * z * (1 - e) * (1 - e) * flight
            engines = true; gear = p > 0.22
        } else if p < 0.72 {                           // landed: ramp down, they board, ramp up
            ramp = p < 0.36 ? (p - 0.3) / 0.06 : (p < 0.64 ? 1 : max(0, 1 - (p - 0.64) / 0.06))
            engines = p > 0.66
        } else {                                       // lift off and away
            let e = CGFloat(pow((p - 0.72) / 0.28, 2))
            x = exit.landX + exit.dir * 320 * z * e
            lift = 170 * z * e * flight
            engines = true; gear = p < 0.78
        }
        // A spare row under it, so the outline goes all the way round the wheels or hull, and placed a row lower to
        // match: what's drawn sits exactly where it did. Its own height, so a ride drawn taller than a ship (Stranger
        // Clawds' bikes) keeps its bottom rows.
        let c = PixelCanvas(Ride.width, ride.canvasHeight + 1)
        drawRide(c, ride, ramp: ramp, engines: engines, gear: gear)
        c.addOutline(C(0xFFFFFF, 0.92))
        let w = CGFloat(Ride.width) * s, h = CGFloat(ride.canvasHeight + 1) * s
        return DrawItem(image: c.makeImage(), rect: NSRect(x: (x - w / 2).rounded(), y: (feet - 2 * s + lift).rounded(), width: w, height: h),
                        mirrored: exit.dir < 0, alpha: 1)
    }

    /// Word-wrap a project name onto at most two lines of `maxWidth`; whatever still doesn't fit gets "…".
    /// Wrapped labels by text, font and width: measuring them was done for every label on every frame.
    private var wrapCache: [String: [String]] = [:]

    private func wrapLabel(_ label: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        let key = "\(label)\u{1}\(font.fontName)\u{1}\(font.pointSize)\u{1}\(maxWidth)"
        if let hit = wrapCache[key] { return hit }
        if wrapCache.count > 200 { wrapCache.removeAll() }
        let lines = wrapLabelUncached(label, font: font, maxWidth: maxWidth)
        wrapCache[key] = lines
        return lines
    }

    private func wrapLabelUncached(_ label: String, font: NSFont, maxWidth: CGFloat) -> [String] {
        func width(_ s: String) -> CGFloat { (s as NSString).size(withAttributes: [.font: font]).width }
        guard width(label) > maxWidth else { return [label] }
        // Break on spaces, dashes and underscores (keeping the dash/underscore at the end of the line).
        var words: [String] = []
        var current = ""
        for ch in label {
            current.append(ch)
            if ch == " " || ch == "-" || ch == "_" { words.append(current); current = "" }
        }
        if !current.isEmpty { words.append(current) }

        var lines: [String] = [""]
        for w in words {
            let candidate = lines[lines.count - 1] + w
            if width(candidate.trimmingCharacters(in: .whitespaces)) <= maxWidth || lines[lines.count - 1].isEmpty {
                lines[lines.count - 1] = candidate
            } else {
                lines.append(w)
            }
        }
        lines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
        // Hard-split a single long word, and squeeze anything past two lines into the second with an ellipsis.
        if width(lines[0]) > maxWidth {
            // One word too long for a line: fill the first line with as much as fits.
            let all = lines.joined(separator: " ")
            var n = all.count
            while n > 1 && width(String(all.prefix(n))) > maxWidth { n -= 1 }
            lines = [String(all.prefix(n)), String(all.dropFirst(n))]
        }
        var second = ""
        for line in lines.dropFirst() {
            let joiner = second.isEmpty || second.hasSuffix("-") || second.hasSuffix("_") ? "" : " "
            second += joiner + line
        }
        if width(second) > maxWidth {
            while !second.isEmpty && width(second + "…") > maxWidth { second.removeLast() }
            second = second.trimmingCharacters(in: .whitespaces) + "…"
        }
        return [lines[0], second]
    }

    // MARK: Dragging

    private var dragStart = NSPoint.zero

    func beginDrag() {
        dragging = true
        let m = NSEvent.mouseLocation
        dragStart = m
        dragOffset = NSPoint(x: m.x - home.x, y: m.y - home.y)
    }

    func continueDrag() {
        let m = NSEvent.mouseLocation
        home = clampHome(NSPoint(x: (m.x - dragOffset.x).rounded(), y: (m.y - dragOffset.y).rounded()), cursor: m)
        relayout()
        snapActors()
    }

    func endDrag() {
        dragging = false
        let m = NSEvent.mouseLocation
        if hypot(m.x - dragStart.x, m.y - dragStart.y) < 4 {
            jump(at: m)    // a click, not a drag
        } else {
            saveHome()
        }
    }

    /// Clicking a character brings its session's terminal or editor window to the front (an agent's, its session's).
    private func jump(at point: NSPoint) {
        guard let key = hitRects().first(where: { $0.1.contains(point) })?.0,
              let actor = actors.first(where: { $0.key == key }) else { return }
        guard let pid = actor.pid else { NSSound.beep(); return }
        Jump.toSession(pid: pid)
    }

    /// On launch, offer once per AI to connect every AI on this Mac that isn't hooked up or waved off yet (also
    /// catches one installed after the others were connected).
    private func offerHooksOnFirstLaunch() {
        guard playground == nil, !demo, shotPath == nil, chaosSeconds == nil else { return }
        SaverInstaller.refreshIfOutdated()
        // The app was moved since the hooks went in: point them here (already agreed to, so no need to ask).
        for ai in HookInstaller.repairMoved() { NSLog("Clawd Clash: re-pointed \(HookInstaller.displayName(ai)) hooks at \(HookInstaller.hookBinary)") }
        let d = UserDefaults.standard
        let ignored = Self.ignoredHooks
        let claude = HookInstaller.claudeAvailable && !HookInstaller.isInstalled && !d.bool(forKey: "offeredHooks")
            && !ignored.contains("claude")
        let others = HookInstaller.others.filter {
            HookInstaller.available($0) && !HookInstaller.installed($0) && !d.bool(forKey: "offeredHooks.\($0.name)")
                && !ignored.contains($0.name)
        }
        guard claude || !others.isEmpty else { return }
        if claude { d.set(true, forKey: "offeredHooks") }
        for ai in others { d.set(true, forKey: "offeredHooks.\(ai.name)") }
        let names = (claude ? ["Claude Code"] : []) + others.map { HookInstaller.displayName($0.name) }
        let list = names.count > 1 ? names.dropLast().joined(separator: ", ") + " and " + names.last! : names[0]
        let codex = others.contains { $0.name == "codex" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.activate(ignoringOtherApps: true)
            let a = NSAlert()
            a.messageText = "Connect Clawd Clash to \(list)?"
            a.informativeText = """
                Clawd Clash learns what your sessions are doing from hooks. This adds a small hook to each one's \
                settings (a backup is kept). Sessions already running pick it up after a restart.\(codex ? """


                Codex asks you to approve new hooks once: type /hooks in Codex and approve Clawd Clash. \
                You'll get a reminder if a Codex session isn't reporting yet.
                """ : "")

                You can do this later from Settings in the menu bar shield.
                """
            a.addButton(withTitle: "Connect")
            a.addButton(withTitle: "Not Now")
            if a.runModal() == .alertFirstButtonReturn {
                // Each on its own: one that fails doesn't stop the others, and every failure is listed.
                let errors = HookInstaller.installAll((claude ? ["claude"] : []) + others.map(\.name)).errors
                if !errors.isEmpty { self.alert("Couldn't install some hooks", errors.joined(separator: "\n")) }
                self.lastHookCheck = 0
            }
        }
    }

    /// An actor as a universe's stage quirks see it (`OnStage`).
    private func stageView(_ a: Actor) -> OnStage {
        OnStage(cast: a.cast, x: a.x, facing: a.walkDir != 0 ? a.walkDir : a.facing, walking: a.walkDir != 0,
                leaving: a.leaving != nil, phase: a.phase, scale: (a.isLeader ? Self.leaderScale : Self.companionScale) * zoom)
    }

    // MARK: Chaos test

    /// One random step: Claudes and agents come and go and change mood, much faster than real use.
    private func chaosStep(_ now: Double) -> [SessionSnapshot] {
        if let limit = chaosSeconds, now - start > limit { finishChaos() }
        func roll(_ p: Double) -> Bool { Double.random(in: 0..<1) < p }
        let r = Roster.shown
        let moods: [Mood] = [.working, .working, .thinking, .waiting, .idle]
        if chaos.isEmpty || (chaos.count < 7 && roll(0.15)) {
            let used = Set(chaos.map(\.leader))
            if let l = (r.darkCast + r.lightCast).filter({ !used.contains($0) && !r.agentOnly.contains($0) }).randomElement() {
                chaos.append(SessionSnapshot(id: "chaos-\(l)-\(Int(now * 1000))", leader: l, project: "project-\(l)",
                                             mood: moods.randomElement()!, agents: []))
            }
        }
        if chaos.count > 1 && roll(0.08) { chaos.remove(at: Int.random(in: 0..<chaos.count)) }
        if roll(0.4), !chaos.isEmpty { chaos[Int.random(in: 0..<chaos.count)].mood = moods.randomElement()! }
        let agentCount = chaos.reduce(0) { $0 + $1.agents.count }
        if agentCount < 12 && roll(0.25), !chaos.isEmpty {
            chaosAgentSerial += 1
            let i = Int.random(in: 0..<chaos.count)
            chaos[i].agents.append(AgentRecord(id: "chaos-a\(chaosAgentSerial)", session: chaos[i].id, type: "chaos",
                                               character: 0,
                                               cast: (r.darkCast + r.lightCast).randomElement(),
                                               started: now, lastSeen: now,
                                               task: Self.sampleTasks.randomElement()))
        }
        if roll(0.2), let i = chaos.indices.filter({ !chaos[$0].agents.isEmpty }).randomElement() {
            chaos[i].agents.remove(at: Int.random(in: 0..<chaos[i].agents.count))
        }
        return chaos
    }

    private func violation(_ kind: String, _ example: String) {
        var v = violations[kind] ?? (0, [])
        v.count += 1
        if v.examples.count < 3 { v.examples.append(example) }
        violations[kind] = v
    }

    /// The rules the layout must keep, whatever happens.
    private func checkInvariants(_ now: Double) {
        let st = stage
        let onStage = actors.filter { $0.leaving == nil && now >= $0.born }
        for a in onStage {
            // Off screen: once it has had time to walk in, every character's body stays on the stage.
            if now - a.born > 4, a.walkDir == 0, a.x < st.minX - 1 || a.x > st.maxX + 1 {
                violation("character off screen", "\(a.key) at x=\(Int(a.x)) (stage \(Int(st.minX))…\(Int(st.maxX)))")
            }
            // Stuck walking: nobody walks for more than 8 s without arriving.
            if a.walkDir != 0 {
                let since = walkingSince[a.key] ?? now
                walkingSince[a.key] = since
                if now - since > 8 { violation("stuck walking", "\(a.key) walking \(Int(now - since))s toward \(Int(a.targetX)) from \(Int(a.x))") }
            } else {
                walkingSince[a.key] = nil
            }
        }
        // Missing: every session and agent shows up within 3 s.
        var wanted: [String] = []
        for s in sessions { wanted.append("L:" + s.id); wanted += s.agents.map { "A:" + $0.id } }
        let present = Set(actors.filter { $0.leaving == nil }.map(\.key))
        for key in wanted where !present.contains(key) {
            let since = missingSince[key] ?? now
            missingSince[key] = since
            if now - since > 3 { violation("missing character", key) }
        }
        missingSince = missingSince.filter { !present.contains($0.key) && wanted.contains($0.key) }
        if present.count > wanted.count { violation("extra characters", "\(present.count) on stage for \(wanted.count) wanted") }
        // Labels: on screen, and never on top of each other.
        let boxes = items.filter { $0.boxed && $0.alpha > 0.5 }.map(\.rect)
        for r in boxes where r.minX < st.minX - 1 || r.maxX > st.maxX + 1 {
            violation("label off screen", "x \(Int(r.minX))…\(Int(r.maxX))")
        }
        for (i, a) in boxes.enumerated() {
            for b in boxes.dropFirst(i + 1) where a.insetBy(dx: 1, dy: 1).intersects(b.insetBy(dx: 1, dy: 1)) {
                violation("labels overlap", "\(Int(a.minX)),\(Int(a.minY)) and \(Int(b.minX)),\(Int(b.minY))")
            }
        }
    }

    private func finishChaos() {
        var report = "Chaos test: \(Int(chaosSeconds ?? 0)) s, \(chaosAgentSerial) agents spawned, \(windowMode ? "window" : "desktop") mode\n"
        if violations.isEmpty { report += "✓ no violations\n" }
        for (kind, v) in violations.sorted(by: { $0.value.count > $1.value.count }) {
            report += "✗ \(kind): \(v.count)×  e.g. \(v.examples.joined(separator: " | "))\n"
        }
        FileHandle.standardOutput.write(report.data(using: .utf8)!)
        exit(violations.isEmpty ? 0 : 1)
    }

    // MARK: Notifications

    /// The first hook issue, for the banner (with a count when there are more).
    private var hookBanner: String? {
        guard let first = hookIssues.first else { return nil }
        return hookIssues.count > 1 ? first.text + "  (+\(hookIssues.count - 1) more in the menu)" : first.text
    }

    /// Once per session: a macOS notification saying what to do; clicking it jumps to that session.
    private func notifySilent(pid: Int32, assistant: String, project: String) {
        guard !notifiedSilent.contains(pid), playground == nil, !demo, chaosSeconds == nil, shotPath == nil else { return }
        notifiedSilent.insert(pid)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            let name = HookInstaller.displayName(assistant)
            content.title = assistant == "codex" ? "Approve Clawd Clash in Codex" : "\(name) isn't reporting to Clawd Clash"
            let fix = HookInstaller.silentFix(assistant)
            content.body = fix.prefix(1).uppercased() + fix.dropFirst()
                + "\(project.isEmpty ? "" : " (\(project))") to see its live status. Click to jump there."
            content.userInfo = ["pid": Int(pid)]
            center.add(UNNotificationRequest(identifier: "silent-\(pid)", content: content, trigger: nil))
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        if let pid = response.notification.request.content.userInfo["pid"] as? Int {
            DispatchQueue.main.async { Jump.toSession(pid: Int32(pid)) }
        }
        done()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) {
        done([.banner, .sound])
    }

    // MARK: Menu bar

    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    /// Hidden from the menu bar shield (double-click): neither the crew nor the window shows. Not remembered across launches.
    private(set) var hidden = false
    /// The displays are asleep or the screen is locked.
    private var screensAsleep = false

    /// Whether anything we draw can be seen: not hidden, and the window not fully covered or minimised.
    /// The desktop panel only counts as visible once it shows something, so asking it would never draw a first frame.
    private var onScreen: Bool {
        guard !hidden, !screensAsleep else { return false }
        guard windowMode else { return panel.isVisible }
        return clawdWindow?.window.occlusionState.contains(.visible) ?? false
    }

    /// The universe's menu bar icon, opening the same menu as right-clicking a character. The menu opens at once;
    /// clicking the icon again while it's open closes it and hides or shows Clawd Clash.
    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = statusIcon(mono: monoMenuBarIcon)
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.toolTip = "Clawd Clash (double-click to hide or show)"
        statusMenu.delegate = self
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        if debug {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let w = item.button?.window
                FileHandle.standardError.write("status item: visible=\(item.isVisible) window=\(w?.frame ?? .zero) onscreen=\(w?.isVisible ?? false)\n".data(using: .utf8)!)
            }
        }
    }

    /// Settings → Monochrome Menu Bar Icon: the shield as a template image, tinted by macOS like the system icons.
    private var monoMenuBarIcon: Bool {
        get { UserDefaults.standard.bool(forKey: "menuBarMono") }
        set { UserDefaults.standard.set(newValue, forKey: "menuBarMono") }
    }

    @objc private func toggleMonoMenuBarIcon() {
        monoMenuBarIcon.toggle()
        statusItem?.button?.image = statusIcon(mono: monoMenuBarIcon)
    }

    /// The universe's menu bar icon (`Theme.menuIcon`: Vader's helmet, Captain America's shield). In colour it gets
    /// a white outline so it reads on a dark menu bar; monochrome is a template image macOS tints to match the bar.
    /// While Universe is Random it keeps the icon of the universe last picked by hand (remembered across launches),
    /// so it doesn't change every few minutes; it changes again when a single universe is picked.
    private func statusIcon(mono: Bool) -> NSImage? {
        let u: Universe
        if Self.universeEvery != nil, let kept = UserDefaults.standard.string(forKey: "menuIconUniverse").flatMap(Universe.offered(key:)) {
            u = kept
        } else {
            u = .shown
            if Universe.previewed == nil { UserDefaults.standard.set(u.key, forKey: "menuIconUniverse") }
        }
        let c = PixelCanvas(28, 26)
        Theme.of(u).menuIcon(c, mono)
        if !mono { c.addOutline(C(0xFFFFFF, 0.92)) }
        guard let cg = c.makeImage() else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: 19, height: 18))
        img.isTemplate = mono
        return img
    }

    /// A click on the helmet this soon after the menu opened counts as a double-click. Our own, not the system's
    /// double-click time (that can be set to seconds), and the status item reports every click with a clickCount
    /// of 1 anyway. The menu takes ~0.35 s to open and close again on a quick double-click.
    private static let statusDoubleClick: TimeInterval = 0.6
    private var ignoreStatusClickUntil: TimeInterval = 0

    @objc private func statusItemClicked() {
        // The mouse-up of a double-click that already closed the menu and hid us: don't reopen the menu.
        if ProcessInfo.processInfo.systemUptime < ignoreStatusClickUntil { return }
        showStatusMenu()
    }

    /// The menu opens at once. Clicking the helmet again right away closes it and hides (or shows) Clawd Clash.
    private func showStatusMenu() {
        guard let item = statusItem, let button = item.button else { return }
        let opened = ProcessInfo.processInfo.systemUptime
        item.menu = statusMenu   // attached only while it opens, so clicks keep coming to `statusItemClicked`
        button.performClick(nil)   // returns once the menu closes
        item.menu = nil
        let now = ProcessInfo.processInfo.systemUptime
        // Closed by a left click on the helmet itself (not on a menu item, not by Escape)?
        let closer = NSApp.currentEvent
        let onIcon = button.window.map { $0.convertToScreen(button.convert(button.bounds, to: nil)) }?
            .contains(NSEvent.mouseLocation) ?? false
        if now - opened < Self.statusDoubleClick, onIcon,
           closer?.type == .leftMouseDown || closer?.type == .leftMouseUp {
            ignoreStatusClickUntil = now + 0.5
            toggleHidden()
        }
    }

    @objc func toggleHidden() {
        hidden.toggle()
        if hidden {
            panel.orderOut(nil)
            clawdWindow?.window.orderOut(nil)
        } else if windowMode, clawdWindow != nil {
            holdWindow()   // back on screen without taking focus from the app you're in
        } else if windowMode {
            openWindow()
        } else {
            panel.orderFrontRegardless()
        }
    }

    /// Rebuild the menu bar and Crew menus from the live state each time they open.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let fresh = self.menu()
        let items = fresh.items
        fresh.removeAllItems()
        items.forEach { menu.addItem($0) }
    }

    /// The menu bar's Full Screen (`FullScreenSaver`): the screen saver over the whole screen until Escape or a click.
    private var fullScreen: FullScreenSaver?

    @objc func openFullScreen() {
        if fullScreen?.isShown == true { return }
        fullScreen?.close()
        let f = FullScreenSaver { [weak self] in self?.saverFeed }
        // The desktop crew and the window (pinned, it's on every Space, this one too) step aside on that display
        // while it's up, and come back after. On another display they stay.
        let aside = [panel, clawdWindow?.window].compactMap { $0 }
            .filter { $0.isVisible && $0.frame.intersects(f.screenFrame) }
        aside.forEach { $0.orderOut(nil) }
        f.onClose = { [weak self, weak f] in
            guard let self, self.fullScreen === f else { return }
            self.fullScreen = nil
            if !self.hidden { aside.forEach { $0.orderFrontRegardless() } }
            self.updateFrontPolicy(active: NSApp.isActive)
        }
        fullScreen = f
        // A Dock icon while it's open, as any full screen app has: without one, swiping between Spaces skipped its
        // Space (only Mission Control reached it). `updateFrontPolicy` puts your choice back when it closes.
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
            NSApp.mainMenu = makeMainMenu()
        }
        lastFeed = 0   // the feed at once, not up to a second from now
        publishSaverFeed(Date().timeIntervalSince1970)
        f.show()
    }

    // MARK: Window mode

    @objc func toggleWindowMode() {
        hidden = false   // switching where it shows means you want to see it
        windowMode.toggle()
        idleHidden = false
        idleHold = windowMode
        if windowMode {
            openWindow()
            panel.orderOut(nil)
        } else {
            clawdWindow?.window.orderOut(nil)
            clawdWindow = nil
            applyDockPolicy()
            panel.orderFrontRegardless()
        }
        NSApp.mainMenu = makeMainMenu()
        refreshStatus()
        snapActors()
    }

    private func openWindow() {
        if clawdWindow == nil {
            let w = ClawdWindow(controller: self, sceneHeight: sceneHeight)
            w.onClose = { [weak self] in self?.toggleWindowMode() }
            // × quits (window mode is remembered for next launch), or with Settings → "Closing the window hides
            // Clawd Clash" just hides it, back from the menu bar shield or the Dock icon.
            w.header.onClose = { [weak self] in
                if ClawdWindow.closeHides { self?.toggleHidden() } else { NSApp.terminate(nil) }
            }
            w.header.onToggleList = { [weak self] in self?.cycleWindowView() }
            w.header.onToggleLarge = { [weak self] in self?.toggleLargeWindow() }
            w.board.feedSource = { [weak self] in self?.saverFeed }
            w.board.contextMenu = { [weak self] in self?.menu() }
            w.onGeometryChange = { [weak self] in
                guard let self else { return }
                self.relayout()
                self.snapActors()
            }
            clawdWindow = w
            if ClawdWindow.view == .board { w.applyBoard() } else if !ClawdWindow.listShown { w.applyListShown() }
        }
        applyDockPolicy()
        clawdWindow?.window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: Nothing running

    /// Window mode with no AI running: rather than an empty scene, the window fades away a moment after the last one
    /// leaves, and fades back when one starts. Asking for it (the Dock icon, the menu bar shield, Window Mode) brings it
    /// back, and it stays until something has run and finished again.
    private var idleHidden = false
    private var idleHold = false
    private var idleSince: Double?
    private static let idleGrace = 3.0

    private func updateIdleWindow(_ now: Double) {
        let real = playground == nil && !demo && chaosSeconds == nil && shotPath == nil
        // A warning to fix (an AI not connected, the status file unreadable) keeps the window up so it can be read.
        let empty = real && sessions.isEmpty && actors.isEmpty && hookIssues.isEmpty && offlineReason == nil
        if empty { idleSince = idleSince ?? now } else { idleSince = nil; idleHold = false }
        guard windowMode, !hidden, let w = clawdWindow else { return }
        if empty, !idleHold, !idleHidden, let since = idleSince, now - since >= Self.idleGrace {
            idleHidden = true
            w.fade(in: false)
        } else if !empty, idleHidden {
            idleHidden = false
            updateCards(now)          // so it fades in showing who just arrived
            w.sceneView.showFrame()
            w.fade(in: true)
        }
    }

    /// You asked to see the window: it fades back if it had gone, and stays even with nothing running.
    private func holdWindow() {
        idleHold = true
        idleHidden = false
        clawdWindow?.fade(in: true)
    }

    private var showInDock: Bool {
        get { UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showInDock") }
    }

    /// Dock icon (and an app menu bar with the Crew menu) in both modes, or neither, then the
    /// menu bar helmet is the way in.
    private func applyDockPolicy() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        NSApp.mainMenu = makeMainMenu()
    }

    /// With the Dock icon off: a Dock icon (and so the top-bar menus) only while the window is the app in front.
    /// Not while Full Screen is open (it has a Dock icon then): dropping the icon takes a window out of full screen, and
    /// macOS then left it as a plain window on Space 1. It's settled when Full Screen closes.
    private func updateFrontPolicy(active: Bool) {
        guard !showInDock, fullScreen == nil else { return }
        let want: NSApplication.ActivationPolicy = active && windowMode && clawdWindow?.window.isVisible == true ? .regular : .accessory
        guard NSApp.activationPolicy() != want else { return }
        NSApp.setActivationPolicy(want)
        if want == .regular {
            NSApp.mainMenu = makeMainMenu()
        } else {
            // Dropping the Dock icon can take our windows down with it; keep them up, without stealing focus.
            if hidden || idleHidden { return }
            if windowMode { clawdWindow?.window.orderFrontRegardless() } else { panel.orderFrontRegardless() }
        }
    }

    @objc private func toggleDock() {
        showInDock.toggle()
        applyDockPolicy()
        // Changing the activation policy can hide our windows; bring them back.
        DispatchQueue.main.async {
            guard !self.hidden, !self.idleHidden else { return }
            if self.windowMode {
                self.clawdWindow?.window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                self.panel.orderFrontRegardless()
            }
        }
    }

    /// Clicking the Dock icon brings the window forward in window mode.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if hidden { toggleHidden() }
        else if windowMode { holdWindow(); clawdWindow?.window.makeKeyAndOrderFront(nil) }
        return true
    }

    private var sceneHeight: CGFloat { max(170, (CGFloat(Sprite.height) * Self.leaderScale + 70) * Self.windowZoom + windowFloor) }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let app = NSMenu()
        app.addItem(withTitle: "About Clawd Clash", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        app.addItem(settings)
        app.addItem(.separator())
        app.addItem(action: windowMode ? "Desktop Mode" : "Window Mode", #selector(toggleWindowMode), target: self)
        app.addItem(.separator())
        app.addItem(withTitle: "Quit Clawd Clash", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = app
        main.addItem(appItem)
        // The same options as right-clicking a villain, as a "Crew" menu.
        let crewItem = NSMenuItem()
        let crew = NSMenu(title: "Crew")
        crew.delegate = self
        crewItem.submenu = crew
        main.addItem(crewItem)
        let winItem = NSMenuItem()
        let win = NSMenu(title: "Window")
        win.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winItem.submenu = win
        main.addItem(winItem)
        return main
    }

    /// Click in the window's scene strip.
    func click(at point: NSPoint) { jump(at: point) }

    /// Shift-double-click on the window's scene, off the crew: somewhere else now, with its trip, instead of waiting
    /// for Random's ten minutes. Random and Clawd Royale pick a new place and stay Random; a picked place or
    /// Automatic steps to the next place of the universe, so clicking on goes round all of them.
    func shiftDoubleClick(at point: NSPoint) {
        guard !hitRects().contains(where: { $0.1.contains(point) }) else { return }
        let here = location
        if Universe.mixed || Self.pickedLocation == Self.randomLocation {
            let list = Universe.mixed ? Location.everywhere : Location.all(in: .shown)
            random = (list.filter { $0 != here }.randomElement() ?? here, Int(Date().timeIntervalSince1970 / 600))
            followPlaceChange()
        } else {
            let list = Location.all(in: .shown)
            let next = list[((list.firstIndex(of: here) ?? -1) + 1) % list.count]
            pickLocation(next.rawValue)
        }
    }

    private var portraitCache: [String: CGImage] = [:]
    private func portrait(_ key: String, assistant: String, _ draw: (PixelCanvas) -> Void) -> CGImage? {
        let key = key + ":" + assistant
        if let img = portraitCache[key] { return img }
        let c = PixelCanvas(Sprite.width, Sprite.height)
        draw(c)
        c.addOutline(AIStyle.outline(assistant))
        // Crop to the character's actual outline (walkers and Jabba are much wider than a Clawd).
        let img = c.opaqueBounds().flatMap { c.makeImage()?.cropping(to: $0) }
        portraitCache[key] = img
        return img
    }

    /// Seconds only for the first minute, then whole minutes: a card with a ticking second counter redraws every second.
    private static func duration(_ seconds: Double) -> String {
        let s = Int(max(0, seconds))
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }

    /// Build the window's cards from everything the hooks recorded (model, title, prompt, reply, current tool…).
    private func updateCards(_ now: Double) {
        guard let w = clawdWindow else { return }
        let dim = NSColor(white: 0.62, alpha: 1), soft = NSColor(white: 0.85, alpha: 1)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let compact = ClawdWindow.scale < 1          // Compact Window: no project path, one line of conversation
        var cards: [CardModel] = []
        // Grouped by AI (stable within a group); with more than one AI each group gets a small header.
        var listed = sessions.enumerated()
            .filter { $0.element.id != "home" || !$0.element.agents.isEmpty }
            .sorted { (AIStyle.rank($0.element.group), $0.offset) < (AIStyle.rank($1.element.group), $1.offset) }
            .map(\.element)
        // Several sessions of one AI in the same project sit together, under the first one's spot, as a tree.
        func projectKey(_ s: SessionSnapshot) -> String? {
            s.project.isEmpty ? nil : s.group + "\u{1}" + s.project + "\u{1}" + (s.remote ?? "")
        }
        var firstSeen: [String: Int] = [:]
        for (i, s) in listed.enumerated() { if let k = projectKey(s), firstSeen[k] == nil { firstSeen[k] = i } }
        listed = listed.enumerated()
            .sorted { (projectKey($0.element).flatMap { firstSeen[$0] } ?? $0.offset, $0.offset)
                    < (projectKey($1.element).flatMap { firstSeen[$0] } ?? $1.offset, $1.offset) }
            .map(\.element)
        let perProject = Dictionary(grouping: listed.compactMap(projectKey), by: { $0 }).mapValues(\.count)
        let severalAIs = Set(listed.map(\.group)).count > 1
        var lastAI: String?
        for (index, s) in listed.enumerated() {
            let leader = Cast(id: s.leader)
            let actor = actors.first { $0.key == "L:" + s.id }
            let held = Self.duration(now - since(s, now: now))
            var status: String, color: NSColor
            switch (s.mood, actor?.bubble) {
            case (_, _) where s.hookSilent: status = s.assistant == "codex" ? "APPROVE IN /hooks" : "NOT REPORTING"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (_, _) where s.stalled: status = "NOT REPORTING"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.working, _) where !s.live: status = "BUSY (CPU)"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.working, _): status = "WORKING · \(held)"; color = NSColor(srgbRed: 0.42, green: 0.9, blue: 0.46, alpha: 1)
            case (.thinking, _): status = "THINKING · \(held)"; color = NSColor(srgbRed: 0.42, green: 0.71, blue: 1, alpha: 1)
            case (.waiting, _): status = (actor?.urgent == true ? "NEEDS YOU! · " : "NEEDS YOU · ") + held
                color = NSColor(srgbRed: 1, green: 0.35, blue: 0.35, alpha: 1)
            case (.idle, .some(.unknown)): status = "NO LIVE STATUS"; color = NSColor(srgbRed: 1, green: 0.69, blue: 0.24, alpha: 1)
            case (.idle, .some(.sleeping)): status = "ASLEEP · \(held)"; color = NSColor(srgbRed: 0.63, green: 0.55, blue: 1, alpha: 1)
            case (.background, _): status = "WAITING ON A JOB · \(held)"; color = NSColor(srgbRed: 0.3, green: 0.8, blue: 0.72, alpha: 1)
            case (.idle, .some(.agentsOut(let n))): status = "WAITING ON \(n) AGENT\(n == 1 ? "" : "S") · \(held)"
                color = NSColor(srgbRed: 0.45, green: 0.65, blue: 1, alpha: 1)
            case (.idle, _): status = "IDLE · \(held)"; color = dim
            }

            var lines: [(String, NSColor)] = []
            if let r = s.record {
                let meta = [r.model, r.title].compactMap { $0 }.joined(separator: "  ·  ")
                if !meta.isEmpty { lines.append((meta, dim)) }
                if let a = r.activity, s.mood != .idle { lines.append(("Now: " + a, .white)) }
                if s.mood == .background { lines.append(("Waiting on: " + backgroundJobs(s), .white)) }
                let reply = s.mood == .idle || s.mood == .background ? r.reply.map { s.aiLabel.components(separatedBy: " · ")[0] + ": “" + $0 + "”" } : nil
                if compact {
                    // Compact Window: one line of the conversation, the reply once it's done, otherwise your prompt.
                    if let line = reply ?? r.prompt.map({ "You: “" + $0 + "”" }) { lines.append((line, soft)) }
                } else {
                    if let p = r.prompt { lines.append(("You: “" + p + "”", soft)) }
                    if let reply { lines.append((reply, soft)) }
                }
                var stats: [String] = []
                if let n = r.prompts { stats.append("\(n) prompt\(n == 1 ? "" : "s")") }
                if let n = r.tools { stats.append("\(n) tool call\(n == 1 ? "" : "s")") }
                if let c = r.created { stats.append("up " + Self.duration(now - c)) }
                if let cwd = s.cwd, !compact { stats.append(cwd.hasPrefix(home) ? "~" + cwd.dropFirst(home.count) : cwd) }
                if !stats.isEmpty { lines.append((stats.joined(separator: "  ·  "), dim)) }
            } else if s.hookSilent {
                lines.append(("The Clawd Clash hook isn't running in this session, so it can't report what it's doing.", soft))
                let fix = HookInstaller.silentFix(s.assistant)
                lines.append((fix.prefix(1).uppercased() + fix.dropFirst() + ": click this card to jump there.", dim))
            } else if !s.live {
                lines.append(("Started before the hooks were installed, so it can't report what it's doing.", soft))
                lines.append((s.assistant == "claude" ? "Restart it for live status: /exit, then claude --continue"
                                                      : "Restart this \(s.assistant.capitalized) session for live status.", dim))
                if let cwd = s.cwd, !compact { lines.append((cwd.hasPrefix(home) ? "~" + cwd.dropFirst(home.count) : cwd, dim)) }
            }

            let agents: [CardModel.Agent] = s.agents.map { a in
                let who = Cast.of(a)
                var detail = [a.activity ?? "Starting…", Self.duration(now - a.started)]
                if let n = a.tools { detail.append("\(n) tool call\(n == 1 ? "" : "s")") }
                if a.type != "general-purpose" && a.type != "playground" && a.type != "demo" { detail.append(a.type) }
                return CardModel.Agent(id: a.id, name: who.name, task: a.label.isEmpty ? "Agent" : a.label,
                                       detail: detail.joined(separator: "  ·  "),
                                       portrait: portrait("a\(who.id)", assistant: s.group) { who.draw($0, t: 0.3, mode: .idle, walking: false, role: .rest, asSession: true, habits: false) })
            }
            cards.append(CardModel(
                // which AI it is shows in the section header above, so the card only names the character
                villain: leader.name, project: s.project, accent: Accents.color(for: s.project) ?? NSColor(white: 0.5, alpha: 1),
                status: status, statusColor: color, focused: s.pid != nil && s.pid == focusedPid,
                lines: lines, agents: agents,
                portrait: portrait("l\(leader.id)", assistant: s.group) { leader.draw($0, t: 0.1, mode: .idle, walking: false, role: .none, asSession: true, habits: false) },
                pid: s.pid))
            cards[cards.count - 1].id = s.id
            if s.pid != nil { cards[cards.count - 1].remote = s.remote ?? "Local" }
            if s.live { cards[cards.count - 1].context = ContextUsage.fraction(session: s.id, assistant: s.assistant, record: s.record) }
            if severalAIs && s.group != lastAI {
                cards[cards.count - 1].group = (HookInstaller.displayName(s.group), AIStyle.color(s.group))
            }
            if let k = projectKey(s), let n = perProject[k], n > 1 {
                let first = index == 0 || projectKey(listed[index - 1]) != k
                let last = index == listed.count - 1 || projectKey(listed[index + 1]) != k
                cards[cards.count - 1].tree = CardModel.Tree(sessions: first ? n : nil, last: last)
            }
            lastAI = s.group
        }
        let banner: String? = offlineReason.map { $0 + ". Live status is off. Fix it from Settings in the menu." } ?? hookBanner
        // An AI that isn't connected can be waved off with the banner's ×; other problems can't.
        let dismissible = offlineReason == nil ? hookIssues.first?.install : nil
        w.cardsView.update(cards: cards, banner: banner, dismiss: dismissible.map { ai in { [weak self] in self?.ignoreHooks(for: ai) } })
        w.fitToContent()
    }

    /// CLAWD_SHOT=/path.png: write the rendered scene (or the whole window) every 5 s, for checking
    /// visuals without screen-recording permission (from agent-view's AGENTVIEW_SHOT).
    private func writeShot(to path: String) {
        var rep: NSBitmapImageRep?
        if windowMode, let content = clawdWindow?.window.contentView {
            rep = content.bitmapImageRepForCachingDisplay(in: content.bounds)
            if let rep { content.cacheDisplay(in: content.bounds, to: rep) }
        } else {
            var bounds = NSRect.null
            for item in items { bounds = bounds.union(item.rect) }
            guard !bounds.isNull else { return }
            bounds = bounds.insetBy(dx: -10, dy: -10).integral
            guard let r = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(bounds.width) * 2, pixelsHigh: Int(bounds.height) * 2,
                                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                  let gc = NSGraphicsContext(bitmapImageRep: r) else { return }
            r.size = bounds.size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = gc
            let ctx = gc.cgContext
            ctx.scaleBy(x: 2, y: 2)
            ctx.setFillColor(CGColor(red: 0.17, green: 0.18, blue: 0.23, alpha: 1))   // a dark "desktop"
            ctx.fill(CGRect(origin: .zero, size: bounds.size))
            OverlayView.render(items, origin: bounds.origin, in: ctx)
            NSGraphicsContext.restoreGraphicsState()
            rep = r
        }
        if let data = rep?.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    // MARK: Menu

    func menu() -> NSMenu {
        let m = NSMenu()
        for issue in hookIssues {
            let title: String
            if let ai = issue.install { title = "⚠︎ Connect \(HookInstaller.displayName(ai))…" }
            else { title = "⚠︎ " + issue.text }
            let item = NSMenuItem(title: title, action: #selector(fixHookIssue(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = issue.install ?? issue.pid.map { "jump:\($0)" }
            m.addItem(item)
            if let ai = issue.install {
                let ignore = NSMenuItem(title: "Don't Remind Me About \(HookInstaller.displayName(ai))", action: #selector(ignoreHookIssue(_:)),
                                        keyEquivalent: "")
                ignore.target = self
                ignore.representedObject = ai
                ignore.indentationLevel = 1
                m.addItem(ignore)
            }
        }
        if !hookIssues.isEmpty { m.addItem(.separator()) }
        // No session list here: the window's list and the desktop's hover cards already show every session.
        if demo { m.addItem(disabled: "(demo mode)") }
        if playground != nil { m.addItem(disabled: "(playground)") }
        if demo || playground != nil { m.addItem(.separator()) }

        m.addItem(action: hidden ? "Show Clawd Clash" : "Hide Clawd Clash", #selector(toggleHidden), target: self)
        m.addItem(action: windowMode ? "Desktop Mode" : "Window Mode", #selector(toggleWindowMode), target: self)
        m.addItem(action: "Full Screen", #selector(openFullScreen), target: self)
        m.addItem(.separator())
        if windowMode { m.addItem(locationMenu()) }
        m.addItem(statusSymbolsMenu())
        // Developer toys: only with ⌘ held while opening the menu (or while one is running, so you can leave it).
        if NSEvent.modifierFlags.contains(.command) || playground != nil || demo {
            m.addItem(.separator())
            m.addItem(playgroundMenu())
            m.addItem(action: "Demo Mode", #selector(toggleDemo), target: self, on: demo)
        }
        m.addItem(.separator())
        m.addItem(action: "Settings…", #selector(openSettings), target: self)
        m.addItem(action: "Quit", #selector(quit), target: self)
        return m
    }

    // MARK: Settings

    private var settingsWindow: SettingsWindow?

    @objc func openSettings() {
        if settingsWindow == nil {
            // One level above the window when it's kept on top, and above the characters when they are, so clicking
            // them never hides Settings behind them; a normal window otherwise.
            settingsWindow = SettingsWindow(level: { [weak self] in
                guard let self else { return .normal }
                let pinned = self.windowMode ? UserDefaults.standard.bool(forKey: "windowPinned") : Self.charactersOnTop
                guard pinned else { return .normal }
                return NSWindow.Level(rawValue: (self.windowMode ? NSWindow.Level.floating : .statusBar).rawValue + 1)
            }, sections: { [weak self] in self?.settingsSections() ?? [] })
        }
        settingsWindow?.show()
    }

    /// Desktop sizes, by name.
    private static let sizes: [(String, CGFloat)] = [("Small", 0.67), ("Medium", 1.0), ("Large", 1.33), ("Huge", 1.75)]

    /// Everything the Settings window shows, read afresh each time it's built.
    private func settingsSections() -> [SettingsSection] {
        let d = UserDefaults.standard
        let universes = Universe.offered
        let clawdRoyaleRow = universes.count, randomRow = universes.count + 1
        let locationChoices = self.locationChoices()
        var general: [SettingsRow] = [
            .choice("Universe", options: universes.map(\.title) + ["Clawd Royale", "Random"],
                    get: {
                        Universe.mixed ? clawdRoyaleRow
                            : Self.universeEvery != nil ? randomRow : universes.firstIndex(of: .shown) ?? 0
                    },
                    set: { [weak self] i in
                        guard let self else { return }
                        switch i {
                        case clawdRoyaleRow:
                            Self.universeEvery = nil
                            if !Universe.mixed { self.switchScene(to: Self.universe, mixed: true) }
                        case randomRow:
                            // Out of Clawd Royale first, back to the last single universe.
                            if Universe.mixed { self.switchScene(to: Self.universe, mixed: false) }
                            if Self.universeEvery == nil {
                                Self.universeEvery = 10
                                self.universeSince = Date().timeIntervalSince1970
                            }
                        default:
                            Self.universeEvery = nil
                            if universes[i] != .shown || Universe.mixed { self.switchScene(to: universes[i], mixed: false) }
                            // Off Random: the menu bar icon is this universe's again, even if Random had already landed here.
                            self.statusItem?.button?.image = self.statusIcon(mono: self.monoMenuBarIcon)
                        }
                    }),
            // Only with Universe set to Random; otherwise a blank row, so the window keeps its size.
            .choice("Switch every", options: Self.universeIntervals.map { $0 == 1 ? "Minute" : "\($0) minutes" },
                    shown: { Self.universeEvery != nil },
                    get: { Self.universeIntervals.firstIndex(of: Self.universeEvery ?? 10) ?? 2 },
                    set: { [weak self] i in
                        Self.universeEvery = Self.universeIntervals[i]
                        self?.universeSince = Date().timeIntervalSince1970
                    }),
            // The same choice as the window's Location menu (`pickedLocation`), one setting for both. Clawd Royale picks
            // the place itself, so the row stays out of the way then, as the menu greys out.
            .choice("Location", options: locationChoices.map(\.title), shown: { !Universe.mixed },
                    get: { locationChoices.firstIndex { $0.key == Self.pickedLocation } ?? 0 },
                    set: { [weak self] i in self?.pickLocation(locationChoices[i].key) }),
            .separator,
            .toggle("Show Dock icon", get: { [weak self] in self?.showInDock ?? true },
                    set: { [weak self] _ in self?.toggleDock() }),
            .toggle("Monochrome menu bar icon", get: { [weak self] in self?.monoMenuBarIcon ?? false },
                    set: { [weak self] _ in self?.toggleMonoMenuBarIcon() }),
            .toggle("Launch at login", get: { SMAppService.mainApp.status == .enabled },
                    set: { [weak self] _ in self?.toggleLogin() }),
        ]
        general.append(.separator)
        general.append(.button("Forget Idle Sessions", note: "Clears sessions that ended without saying so.",
                               action: { [weak self] in self?.forgetIdle() }))

        let window: [SettingsRow] = [
            .toggle("Closing the window hides Clawd Clash", note: "Otherwise the × quits the app.",
                    get: { ClawdWindow.closeHides }, set: { ClawdWindow.closeHides = $0 }),
            .toggle("Keep window on top", note: "Stays above your other windows.", get: { d.bool(forKey: "windowPinned") },
                    set: { [weak self] on in d.set(on, forKey: "windowPinned"); self?.clawdWindow?.applyPin() }),
            .separator,
            .toggle("Smaller window", note: "Everything in the window drawn smaller.", get: { ClawdWindow.small && !ClawdWindow.large },
                    set: { [weak self] _ in self?.toggleSmallWindow() }),
            .toggle("Larger window", note: "Everything in the window drawn bigger.",
                    get: { ClawdWindow.large }, set: { [weak self] _ in self?.toggleLargeWindow() }),
            .toggle("Show the session list", note: "A card per session under the scene.", get: { ClawdWindow.listShown && ClawdWindow.view != .board },
                    set: { [weak self] _ in self?.toggleWindowList() }),
            .toggle("Show the screen saver view instead", note: "The window shows what the screen saver shows.", get: { ClawdWindow.view == .board },
                    set: { [weak self] _ in self?.toggleBoard() }),
            .toggle("Fit the window's height to the sessions", note: "Grows and shrinks as sessions come and go.", get: { d.object(forKey: "autoHeight") as? Bool ?? true },
                    set: { [weak self] _ in self?.toggleAutoHeight() }),
            .separator,
            .toggle("Show project names over the characters", note: "Each session's project above its character.",
                    get: { d.object(forKey: "labelsWindow") as? Bool ?? false },
                    set: { on in d.set(on, forKey: "labelsWindow") }),
            .toggle("Show agents' tasks over the agents", note: "What each agent is working on, above it.", get: { d.bool(forKey: "agentLabelsWindow") },
                    set: { on in d.set(on, forKey: "agentLabelsWindow") }),
            .separator,
            // Each card redraws at once, the pills left closing up to the right.
            .checks("Card pills", note: "Small tags on each session's card.", items: [("Status", CardsView.Pill.status), ("Where the repo lives", .remote), ("Context", .context)].map { item in
                (item.0, get: { CardsView.shows(item.1) },
                 set: { [weak self] on in d.set(on, forKey: item.1.rawValue); self?.clawdWindow?.cardsView.needsDisplay = true })
            }),
        ]

        let desktop: [SettingsRow] = [
            .choice("Size", options: Self.sizes.map(\.0),
                    get: { [weak self] in Self.sizes.firstIndex { abs($0.1 - (self?.baseZoom ?? 0.67)) < 0.01 } ?? 0 },
                    set: { [weak self] i in self?.setDesktopZoom(Self.sizes[i].1) }),
            .toggle("Keep characters on top", note: "Off, they live on the desktop, behind your windows.",
                    get: { Self.charactersOnTop },
                    set: { [weak self] on in
                        Self.charactersOnTop = on
                        self?.panel.level = on ? .statusBar : Self.desktopLevel
                    }),
            .toggle("Show project names over the characters", get: { d.object(forKey: "labels") as? Bool ?? true },
                    set: { on in d.set(on, forKey: "labels") }),
            .separator,
            .button("Reset Position", note: "Puts the crew back in the bottom-right corner.",
                    action: { [weak self] in self?.resetPosition() }),
        ]

        // Every AI we support, so it's clear what could connect: one that isn't installed is greyed out, without a button.
        let claudeHere = { HookInstaller.claudeAvailable || HookInstaller.isInstalled }
        var ais: [SettingsRow] = [
            .status("Claude Code", detail: { claudeHere() ? (HookInstaller.isInstalled ? "Connected" : "Not connected") : "Not installed" },
                    button: { claudeHere() ? (HookInstaller.isInstalled ? "Remove" : "Connect") : nil },
                    dimmed: { !claudeHere() },
                    action: { [weak self] in
                        if HookInstaller.isInstalled { self?.removeHooks() } else { self?.installHooks() }
                    }),
        ]
        for ai in HookInstaller.others {
            let here = { HookInstaller.available(ai) }
            ais.append(.status(HookInstaller.displayName(ai.name),
                               detail: { here() ? (HookInstaller.installed(ai) ? "Connected" : "Not connected") : "Not installed" },
                               button: { here() ? (HookInstaller.installed(ai) ? "Remove" : "Connect") : nil },
                               dimmed: { !here() },
                               action: { [weak self] in
                                   guard let self else { return }
                                   if HookInstaller.installed(ai) {
                                       Self.ignoredHooks.insert(ai.name)   // removed on purpose: no reminders
                                       do { try HookInstaller.uninstall(ai) } catch {
                                           self.alert("Couldn't remove \(HookInstaller.displayName(ai.name)) hooks", error.localizedDescription)
                                       }
                                   } else {
                                       self.installOther(ai.name)
                                   }
                               }))
        }

        let released = Universe.allCases.filter(\.isReleased)
        let universeRows: [SettingsRow] = [
            .checkGrid("Universes", columns: 2, items: released.map { u in
                (title: u.title, get: { !Universe.removed.contains(u) },
                 set: { [weak self] kept in self?.keepUniverse(u, kept) })
            }),
        ]
        var sections = [
            SettingsSection(title: "General", symbol: "gearshape", rows: general),
            SettingsSection(title: "Universes", symbol: "square.stack.3d.up",
                            note: "Unchecked universes leave the Universe menu, Random, Clawd Royale and the screen saver. "
                                + "Check one again and it's back just as it was. At least one universe stays in.",
                            rows: universeRows),
            SettingsSection(title: "Window", symbol: "macwindow", rows: window),
            SettingsSection(title: "Desktop", symbol: "menubar.dock.rectangle", rows: desktop),
            SettingsSection(title: "AIs", symbol: "sparkles", note: "Connected AIs report what they're doing through Clawd Clash's hook.",
                            rows: ais),
        ]
        if SaverInstaller.bundled != nil {
            sections.append(SettingsSection(title: "Screen Saver", symbol: "display", rows: [
                .status("Clawd Clash", detail: { SaverInstaller.isInstalled ? "Installed" : "Not installed" },
                        button: { SaverInstaller.isInstalled ? "Remove" : "Install…" },
                        action: { [weak self] in
                            if SaverInstaller.isInstalled { self?.removeSaver() } else { self?.installSaver() }
                        }),
                .separator,
                .toggle("Show the banner", note: "The strip along the bottom: who joined, who left and what they're working on.",
                        get: { Self.saverPrivacy.banner },
                        set: { on in var p = Self.saverPrivacy; p.banner = on; Self.saverPrivacy = p }),
                .toggle("Show the session cards", note: "Off, someone walking past sees no projects, prompts or tasks: "
                            + "only the characters, their names, how they're doing and what they say.",
                        get: { Self.saverPrivacy.cards },
                        set: { on in var p = Self.saverPrivacy; p.cards = on; Self.saverPrivacy = p }),
            ]))
        }
        sections.append(SettingsSection(title: "About", symbol: "info.circle",
                                        rows: [.custom { [weak self] in self?.aboutView() ?? NSView() }]))
        return sections
    }

    // MARK: About and updates

    private static let repo = "rodclemen/clawd-clash"
    private var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?" }
    /// What the last "Check for Updates" found, shown under the button: a line, and where to get a newer version.
    private var updateCheck: (text: String, download: URL?)?

    /// The About tab, laid out as macOS apps' own: the icon on the left; beside it the name, the version, buttons to
    /// check for a newer release, read what's new and visit the repo, what the check found, and the licence.
    private func aboutView() -> NSView {
        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 128).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 128).isActive = true
        let name = NSTextField(labelWithString: "Clawd Clash")
        name.font = .systemFont(ofSize: 26)
        let ver = NSTextField(labelWithString: version)
        ver.font = .systemFont(ofSize: 15)
        ver.textColor = .secondaryLabelColor

        let check = NSButton(title: "Check for Updates…", target: self, action: #selector(checkForUpdates))
        let buttons = NSStackView(views: [check, button("What's New", "https://github.com/\(Self.repo)/blob/main/CHANGELOG.md"),
                                          button("Website", "https://github.com/\(Self.repo)")])
        buttons.spacing = 8
        var views: [NSView] = [name, ver, buttons]
        if let found = updateCheck {
            let line = Self.small(found.text, color: found.download == nil ? .secondaryLabelColor : .labelColor)
            line.font = .systemFont(ofSize: NSFont.systemFontSize)
            views.append(line)
            if found.download != nil {
                let get = NSButton(title: "Download", target: self, action: #selector(openDownload))
                get.bezelStyle = .rounded
                get.keyEquivalent = "\r"
                views.append(get)
            }
        }
        let thanks = NSTextField(labelWithString: "Thanks to")
        thanks.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        views.append(thanks)
        for c in Self.collaborators {
            // The universes they made, by their current names; a bug fix or a feature is thanked by name alone.
            var parts: [NSView] = [linkButton(c.name, "https://github.com/\(c.github)")]
            if !c.universes.isEmpty {
                parts.append(Self.small(c.universes.map(\.title).joined(separator: ", "), color: .secondaryLabelColor))
            }
            let line = NSStackView(views: parts)
            line.spacing = 6
            views.append(line)
        }
        let copyright = Self.small("© 2026 Rod Clemen", color: .secondaryLabelColor)
        views += [copyright,
                  Self.small("Licensed under the MIT License. A fan parody project for AI coding sessions: "
                             + "free to use, change and share.", color: .secondaryLabelColor),
                  Self.small("No warranty. See LICENSE for details.", color: .secondaryLabelColor)]
        let column = NSStackView(views: views)
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = 8
        column.setCustomSpacing(2, after: name)
        column.setCustomSpacing(14, after: ver)
        column.setCustomSpacing(4, after: thanks)
        if let i = views.firstIndex(of: thanks), i > 0 { column.setCustomSpacing(18, after: views[i - 1]) }
        if let i = views.firstIndex(of: copyright), i > 0 { column.setCustomSpacing(18, after: views[i - 1]) }

        let row = NSStackView(views: [icon, column])
        row.alignment = .top
        row.spacing = 28
        return row
    }

    /// Everyone outside the project whose pull requests were merged, for About's "Thanks to" (add them when merging),
    /// with the universes they made, if any.
    static let collaborators: [(name: String, github: String, universes: [Universe])] = [
        ("Henrik Andersen", "HEM42", [.middleEarth]),
    ]

    /// A borderless link-coloured button that opens `url`.
    private func linkButton(_ title: String, _ url: String) -> NSButton {
        let b = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        b.isBordered = false
        b.contentTintColor = .linkColor
        b.toolTip = url
        return b
    }

    /// Small wrapped text for the About tab's column.
    private static func small(_ s: String, color: NSColor) -> NSTextField {
        let t = NSTextField(wrappingLabelWithString: s)
        t.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        t.textColor = color
        t.preferredMaxLayoutWidth = 360
        t.widthAnchor.constraint(lessThanOrEqualToConstant: 360).isActive = true
        return t
    }

    /// A push button that opens `url`.
    private func button(_ title: String, _ url: String) -> NSButton {
        let b = NSButton(title: title, target: self, action: #selector(openLink(_:)))
        b.bezelStyle = .rounded
        b.toolTip = url
        return b
    }

    @objc private func openLink(_ sender: NSButton) {
        if let s = sender.toolTip, let url = URL(string: s) { NSWorkspace.shared.open(url) }
    }

    @objc private func openDownload() {
        if let url = updateCheck?.download { NSWorkspace.shared.open(url) }
    }

    /// Asks GitHub for the latest release (only when the button is clicked: Clawd Clash never checks on its own) and
    /// compares it with this version.
    @objc private func checkForUpdates() {
        updateCheck = ("Checking…", nil)
        settingsWindow?.reload()
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
            let tag = (json?["tag_name"] as? String).map { $0.hasPrefix("v") ? String($0.dropFirst()) : $0 }
            let page = (json?["html_url"] as? String).flatMap(URL.init(string:))
            DispatchQueue.main.async {
                guard let self else { return }
                if let tag, let page {
                    if Self.isNewer(tag, than: self.version) {
                        let brew = FileManager.default.fileExists(atPath: "/opt/homebrew/Caskroom/clawd-clash")
                            ? "\nInstalled with Homebrew: brew upgrade --cask clawd-clash" : ""
                        self.updateCheck = ("Version \(tag) is available (you have \(self.version)).\(brew)", page)
                    } else {
                        self.updateCheck = ("You're up to date.", nil)
                    }
                } else {
                    self.updateCheck = ("Couldn't reach GitHub\(error.map { ": \($0.localizedDescription)" } ?? ""). Try again later.", nil)
                }
                self.settingsWindow?.reload()
            }
        }.resume()
    }

    /// Whether version `a` ("3.6.0") comes after `b`, number by number.
    static func isNewer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }

    /// Settings → Size: the crew's size on the desktop (the window always fits its crew to the window).
    private func setDesktopZoom(_ z: CGFloat) {
        UserDefaults.standard.set(z, forKey: "zoom")
        guard !windowMode else { return }
        home = clampHome(home)
        relayout()
        snapActors()
    }

    /// Status Symbols: a key to the bubbles, poses and colours (`Legend`). Nothing to pick, so its rows are
    /// enabled only to keep their text at full strength.
    private func statusSymbolsMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Status Symbols", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        sub.autoenablesItems = false
        for (i, section) in Legend.sections.enumerated() {
            if i > 0 { sub.addItem(.separator()) }
            section.forEach { sub.addItem(Legend.menuItem($0)) }
        }
        root.submenu = sub
        return root
    }

    /// Settings → Keep Characters on Top (desktop mode): on, the crew stands above every window; off, it lives on the
    /// desktop itself, just above the icons, behind your windows. On by default.
    static var charactersOnTop: Bool {
        get { UserDefaults.standard.object(forKey: "charactersOnTop") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "charactersOnTop") }
    }
    private static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

    /// Settings → Screen Saver: whether it shows the banner and the session cards (both on by default), and when that
    /// was last changed here, so the saver's own Options can be the later word (`SaverFeed.Privacy`).
    static var saverPrivacy: SaverFeed.Privacy {
        get {
            let d = UserDefaults.standard
            return SaverFeed.Privacy(banner: d.object(forKey: "saverBanner") as? Bool ?? true,
                                     cards: d.object(forKey: "saverCards") as? Bool ?? true,
                                     at: d.double(forKey: "saverPrivacyAt"))
        }
        set {
            let d = UserDefaults.standard
            d.set(newValue.banner, forKey: "saverBanner")
            d.set(newValue.cards, forKey: "saverCards")
            d.set(Date().timeIntervalSince1970, forKey: "saverPrivacyAt")
        }
    }

    @objc private func toggleSmallWindow() {
        // Ticked in the Larger window: back down to the Compact Window, not just a flag the Larger one hides.
        if ClawdWindow.large { ClawdWindow.large = false; ClawdWindow.small = true } else { ClawdWindow.small.toggle() }
        clawdWindow?.applySmall()
    }

    /// The header's size button, or Settings → Larger window (125%): everything in the window 25% bigger, or back.
    @objc private func toggleLargeWindow() {
        let old = ClawdWindow.scale
        ClawdWindow.large.toggle()
        clawdWindow?.applyLarge(from: old)
        settingsWindow?.reload()
    }

    /// The header's view button: the scene with the list ↔ just the scene; from the screen-saver view (Settings
    /// only), back to the scene with the list.
    private func cycleWindowView() { toggleWindowList() }

    private func setBoard(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: "windowBoard")
        lastFeed = 0                     // a feed straight away, not up to a second later
        if on { publishSaverFeed(Date().timeIntervalSince1970) }
        clawdWindow?.applyBoard()
    }

    @objc private func toggleBoard() { setBoard(ClawdWindow.view != .board) }

    /// Settings → Show the session list (and the view button's last step): from the screen-saver view, back to
    /// the scene with the list.
    @objc private func toggleWindowList() {
        if ClawdWindow.view == .board {
            setBoard(false)
            if !ClawdWindow.listShown { UserDefaults.standard.set(true, forKey: "windowList"); clawdWindow?.applyListShown() }
            return
        }
        let show = !ClawdWindow.listShown
        if !show, let w = clawdWindow?.window { UserDefaults.standard.set(Double(w.frame.height), forKey: "windowListHeight") }
        UserDefaults.standard.set(show, forKey: "windowList")
        clawdWindow?.applyListShown()
    }

    @objc private func toggleAutoHeight() {
        let on = !(UserDefaults.standard.object(forKey: "autoHeight") as? Bool ?? true)
        UserDefaults.standard.set(on, forKey: "autoHeight")
        if on { clawdWindow?.fitToContent() }
    }

    // MARK: Universe

    /// The universe picked (in Clawd Royale, the last one picked, for when it ends). A fresh
    /// install takes after whichever app it replaces (Clawd Wars: Star Wars; Avengers: Clawd Wars: Marvel; Justice
    /// League: Clawd Wars: DC); the Homebrew casks preset it.
    static var universe: Universe {
        get {
            if let t = Universe.previewed { return previewPicks["universe"] as? Universe ?? t }
            let d = UserDefaults.standard
            if let key = d.string(forKey: "universe"), let u = Universe.offered(key: key) { return u }
            let used = { (id: String) in UserDefaults(suiteName: id)?.object(forKey: "windowMode") != nil }
            var first = Universe.starWars
            if !used("com.rodclemen.vaderclaude") {
                if used("com.rodclemen.justiceleagueclawdwars") { first = .dc }
                else if used("com.rodclemen.avengersclawdwars") { first = .marvel }
            }
            // Unchecked in Settings → Universes (the saved one too): the first universe still in.
            return Universe.offered.contains(first) ? first : Universe.offered[0]
        }
        set {
            if Universe.previewed != nil { previewPicks["universe"] = newValue; return }
            UserDefaults.standard.set(newValue.key, forKey: "universe")
        }
    }
    /// What a `--template-preview` run picks (the universe, Clawd Royale, the place, what's unchecked), kept for the run
    /// only: nothing that names the template is ever saved (`Universe.previewed`).
    private static var previewPicks: [String: Any] = [:]
    /// The place picked in the Location menu (a key, or `randomLocation`); nil: Automatic.
    static var pickedLocation: String? {
        get { Universe.previewed != nil ? previewPicks["location"] as? String : UserDefaults.standard.string(forKey: "location") }
        set {
            if Universe.previewed != nil { previewPicks["location"] = newValue; return }
            if let newValue { UserDefaults.standard.set(newValue, forKey: "location") } else { UserDefaults.standard.removeObject(forKey: "location") }
        }
    }
    /// `--clawd-royale`: Clawd Royale for this run only (test and screenshot runs); the flag itself isn't saved.
    private static let clawdRoyaleArg = CommandLine.arguments.contains("--clawd-royale")
    /// Clawd Royale (Settings → Universe): every universe's cast at once, in random places from all of them.
    /// `universe` keeps the last single universe meanwhile.
    static var clawdRoyale: Bool {
        get {
            clawdRoyaleArg || (Universe.previewed != nil ? previewPicks["clawdRoyale"] as? Bool ?? false
                                                          : UserDefaults.standard.bool(forKey: "clawdRoyale"))
        }
        set {
            if Universe.previewed != nil { previewPicks["clawdRoyale"] = newValue; return }
            UserDefaults.standard.set(newValue, forKey: "clawdRoyale")
        }
    }
    /// A test or screenshot run (as `main.swift` judges it): it never tells the hook what to cast, which would change
    /// what the real app's sessions get.
    private static let testRun = CommandLine.arguments.dropFirst().contains { $0.hasPrefix("--") }
        || ProcessInfo.processInfo.environment["CLAWD_SHOT"] != nil

    /// Tell the hook (and the screen saver, with the app closed) what's on show, and which universes are unchecked.
    private func publishUniverse() {
        guard !Self.testRun else { return }
        StatusStore.setUniverse(Universe.shown, mixed: Universe.mixed)
        StatusStore.setRemoved(Universe.removed)
    }

    /// Universes unchecked in Settings → Universes. Saved by key as what's removed, not what's kept, so a universe that
    /// comes with an update shows up checked.
    static var universesRemoved: Set<Universe> {
        get {
            if Universe.previewed != nil { return previewPicks["universesRemoved"] as? Set<Universe> ?? [] }
            return Set((UserDefaults.standard.stringArray(forKey: "universesRemoved") ?? []).compactMap(Universe.init(key:)))
        }
        set {
            if Universe.previewed != nil { previewPicks["universesRemoved"] = newValue; return }
            UserDefaults.standard.set(newValue.map(\.key).sorted(), forKey: "universesRemoved")
        }
    }

    /// Settings → Universes: check `u` back in, or uncheck it. It leaves (or rejoins) the Universe menu, Random,
    /// Clawd Royale's cast and places, and the screen saver's choices; the hook stops (or starts) casting from it.
    /// The last one checked stays in. If the universe on show goes, the app moves to the first one still in, as if
    /// picked from the menu; in Clawd Royale, a place from it gives way to another (sessions already cast keep their
    /// characters till they end).
    private func keepUniverse(_ u: Universe, _ kept: Bool) {
        var removed = Self.universesRemoved
        if kept { removed.remove(u) } else { removed.insert(u) }
        guard Universe.allCases.contains(where: { $0.isReleased && !removed.contains($0) }) else { return }
        Self.universesRemoved = removed
        Universe.removed = removed
        if removed.contains(Self.universe) { Self.universe = Universe.offered[0] }
        if !Universe.mixed, removed.contains(.shown) {
            switchScene(to: Universe.offered[0], mixed: false)
        } else if Universe.mixed, removed.contains(location.universe) {
            switchScene(to: Self.universe, mixed: true)
        } else {
            publishUniverse()
            if Universe.mixed { followPlace() }
        }
    }

    /// Random: a different universe every this many minutes (Settings → Universe → Random); nil: it stays on the one picked.
    static var universeEvery: Int? {
        get { let m = UserDefaults.standard.integer(forKey: "universeEvery"); return m > 0 ? m : nil }
        set { UserDefaults.standard.set(newValue ?? 0, forKey: "universeEvery") }
    }
    static let universeIntervals = [1, 5, 10, 15, 30, 60]
    /// When the universe last changed, for Random.
    private var universeSince = Date().timeIntervalSince1970
    /// The last change's comic-book transition, so the next one is another.
    private var lastSwitchComic: ComicTransition?
    private var lastSwitchWipe: Wipe.Kind?

    /// Random's turn: another universe, every `universeEvery` minutes. Not in the Playground, the demo or test runs.
    private func randomUniverseTick(_ now: Double) {
        guard let every = Self.universeEvery, now - universeSince >= Double(every * 60),
              playground == nil, !demo, chaosSeconds == nil, shotPath == nil,
              let next = Universe.offered.filter({ $0 != Universe.shown }).randomElement() else { return }
        switchScene(to: next, mixed: false)
    }

    /// Everyone is recast in the new universe (same places in its cast, so they keep their sides), or, into Battle
    /// Royale, shown as themselves; the scene moves to one of the new places, the menu bar icon changes, and the hook
    /// casts new arrivals from it. In the window, the whole window changes over with the new place's transition.
    private func switchScene(to u: Universe, mixed: Bool) {
        universeSince = Date().timeIntervalSince1970
        let window = windowMode && onScreen && ClawdWindow.view != .board ? clawdWindow : nil
        let before = window?.snapshot()
        Self.universe = u
        Self.clawdRoyale = mixed
        Universe.mixed = mixed
        random = nil
        if !mixed, let raw = Self.pickedLocation, raw != Self.randomLocation,
           Location(rawValue: raw)?.universe != u {
            Self.pickedLocation = nil     // a place from the other universe: back to automatic
        }
        Universe.shown = mixed ? location.universe : u
        publishUniverse()
        statusItem?.button?.image = statusIcon(mono: monoMenuBarIcon)
        actors.removeAll()                                           // walk back in, recast
        clawdWindow?.sceneView.skipWipe = before != nil              // the whole window has its own transition
        refreshStatus()
        clawdWindow?.sceneView.showFrame()
        clawdWindow?.sceneView.skipWipe = false
        clawdWindow?.cardsView.needsDisplay = true
        clawdWindow?.header.needsDisplay = true
        clawdWindow?.redrawScroller()
        if let window, let before {
            let comic = ComicTransition.pick(after: lastSwitchComic, cast: onStage, to: location)
            lastSwitchComic = comic
            lastSwitchWipe = Wipe.Kind.next(after: lastSwitchWipe)
            window.playSwitch(from: before, comic: comic, kind: lastSwitchWipe!)
        }
    }

    /// The Location menu's choices, in its order, for the menu and Settings → General alike: Automatic (nil), Random,
    /// then every place in the universe on show, each with who calls it home. Clawd Royale keeps the last single
    /// universe's, so the kept choice still shows.
    private func locationChoices() -> [(title: String, key: String?)] {
        let kept = Universe.mixed ? Self.universe : Universe.shown
        let owners: [Location: [String]] = Dictionary(grouping: Theme.of(kept).cast.filter { !kept.isHem($0.id) }
            .map { ($0.home, $0.name) }, by: \.0)
            .mapValues { $0.map(\.1) }
        return [("Automatic (where the first Claude belongs)", nil), ("Random (somewhere new every 10 minutes)", Self.randomLocation)]
            + Location.all(in: kept).map { l in
                let who = owners[l]?.joined(separator: ", ") ?? ""
                return (who.isEmpty ? l.name : "\(l.name)  ·  \(who)", l.rawValue)
            }
    }

    private func locationMenu() -> NSMenuItem {
        let root = NSMenuItem(title: Universe.mixed ? "Location: \(location.name) (Clawd Royale)" : "Location: \(location.name)",
                              action: nil, keyEquivalent: "")
        let lm = NSMenu()
        let picked = Self.pickedLocation
        for (i, choice) in locationChoices().enumerated() {
            let item = NSMenuItem(title: choice.title, action: #selector(setLocation(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = choice.key
            item.state = picked == choice.key ? .on : .off
            lm.addItem(item)
            if i == 1 { lm.addItem(.separator()) }
        }
        if Universe.mixed {   // Clawd Royale picks the place; the choice here comes back after
            lm.autoenablesItems = false
            lm.items.forEach { $0.isEnabled = false }
        }
        root.submenu = lm
        return root
    }

    @objc private func setLocation(_ sender: NSMenuItem) { pickLocation(sender.representedObject as? String) }

    /// Sets the place (a key, `randomLocation`, or nil for Automatic), from the Location menu or Settings.
    private func pickLocation(_ key: String?) {
        Self.pickedLocation = key
        settingsWindow?.reload()
        clawdWindow?.sceneView.showFrame()
        clawdWindow?.cardsView.needsDisplay = true
        clawdWindow?.header.needsDisplay = true
        clawdWindow?.redrawScroller()
    }

    private func playgroundMenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Playground", action: nil, keyEquivalent: "")
        let pm = NSMenu()
        let picked = playground ?? []
        pm.addItem(disabled: "Villains (they pair up in the order you add them)")
        let theme = Theme.of(.shown)
        func weaponLabel(_ p: Persona) -> String {
            var label: String
            switch p.weapon {
            case .saber: label = "melee"
            case .blaster: label = "ranged"
            case .lightning: label = "magic"
            case .none: label = p.callout.map { "unarmed, “\($0)”" } ?? "unarmed"
            }
            switch p.motion {
            case .fly: label += ", flies"
            case .hover: label += ", hovers"
            case .swing: label += ", swings"
            case .walk: break
            }
            return label
        }
        // Tags are local ids (villain index, hero index); `Cast(id:)` puts them in the universe on show.
        for (i, p) in theme.villains.enumerated() where !theme.universe.agentOnly.contains(theme.universe.base + i) {
            let order = picked.firstIndex(of: i).map { "   #\($0 + 1)" } ?? ""
            let item = NSMenuItem(title: "\(p.name) (\(weaponLabel(p)))\(order)",
                                  action: #selector(togglePlaygroundVillain(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = picked.contains(i) ? .on : .off
            pm.addItem(item)
        }
        pm.addItem(.separator())
        pm.addItem(disabled: "Agents (they join the first villain)")
        for (i, p) in theme.heroes.enumerated() {
            let item = NSMenuItem(title: p.name, action: #selector(togglePlaygroundAgent(_:)), keyEquivalent: "")
            item.target = self
            item.tag = i
            item.state = playground != nil && playgroundAgents.contains(i) ? .on : .off
            pm.addItem(item)
        }
        for id in theme.universe.agentOnly.sorted() where Universe.isDark(id) {   // agent-only heroes are listed above
            let tag = Self.playgroundVillainAgent + id % 1000
            let item = NSMenuItem(title: Cast(id: id).name, action: #selector(togglePlaygroundAgent(_:)), keyEquivalent: "")
            item.target = self
            item.tag = tag
            item.state = playground != nil && playgroundAgents.contains(tag) ? .on : .off
            pm.addItem(item)
        }
        pm.addItem(.separator())
        let moodItem = NSMenuItem(title: "Villains Are…", action: nil, keyEquivalent: "")
        let mm = NSMenu()
        for (title, mood) in [("Working (fighting)", Mood.working), ("Thinking", .thinking),
                              ("Waiting for you", .waiting), ("Idle", .idle)] {
            let item = NSMenuItem(title: title, action: #selector(setPlaygroundMood(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mood.rawValue
            item.state = playgroundMood == mood ? .on : .off
            mm.addItem(item)
        }
        moodItem.submenu = mm
        pm.addItem(moodItem)
        pm.addItem(.separator())
        pm.addItem(action: "Add All Villains", #selector(addAllVillains), target: self)
        // Hidden, for checking a place whose scene turns over (`SceneFlip`): with ⌥ held, the item above becomes this
        // one, which starts the turn at once. Only offered there, and never documented.
        if clawdWindow?.sceneView.flipClock.canTurn == true || clawdWindow?.board.canTurnOver == true {
            let item = NSMenuItem(title: "Surprise Me", action: #selector(startSceneFlip), keyEquivalent: "")
            item.target = self
            item.isAlternate = true
            item.keyEquivalentModifierMask = .option
            pm.addItem(item)
        }
        if playground != nil {
            pm.addItem(action: "Exit Playground", #selector(exitPlayground), target: self)
        }
        root.submenu = pm
        return root
    }

    private func enterPlayground() {
        if playground == nil {
            playground = []
            playgroundAgents = []
            demo = false
        }
    }

    @objc private func togglePlaygroundVillain(_ sender: NSMenuItem) {
        enterPlayground()
        if let i = playground!.firstIndex(of: sender.tag) { playground!.remove(at: i) } else { playground!.append(sender.tag) }
        refreshStatus()
    }

    @objc private func togglePlaygroundAgent(_ sender: NSMenuItem) {
        enterPlayground()
        if let i = playgroundAgents.firstIndex(of: sender.tag) { playgroundAgents.remove(at: i) } else { playgroundAgents.append(sender.tag) }
        refreshStatus()
    }

    @objc private func setPlaygroundMood(_ sender: NSMenuItem) {
        enterPlayground()
        playgroundMood = Mood(rawValue: sender.representedObject as? String ?? "") ?? .working
        refreshStatus()
    }

    @objc private func startSceneFlip() {
        let now = Date().timeIntervalSince1970
        clawdWindow?.sceneView.flipClock.start(now: now)
        clawdWindow?.board.turnOver(now: now)
    }

    @objc private func addAllVillains() {
        enterPlayground()
        let u = Universe.shown
        for i in 0..<u.villainCount where !playground!.contains(i) && !u.agentOnly.contains(u.base + i) { playground!.append(i) }
        refreshStatus()
    }

    @objc private func exitPlayground() {
        playground = nil
        refreshStatus()
    }

    @objc private func toggleDemo() {
        playground = nil
        demo.toggle()
        demoStart = Date().timeIntervalSince1970
        refreshStatus()
    }

    @objc private func forgetIdle() {
        StatusStore.forgetIdleSessions()
        refreshStatus()
    }

    @objc private func resetPosition() {
        UserDefaults.standard.removeObject(forKey: "anchorX")
        UserDefaults.standard.removeObject(forKey: "anchorY")
        home = clampHome(savedHome())     // re-applies the edge snap, so positions saved under older rules are corrected
        relayout()
        snapActors()
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            alert("Couldn't change Launch at Login", error.localizedDescription)
        }
    }

    /// Menu fix for a hook issue: connect the AI, or jump to the silent session.
    @objc private func fixHookIssue(_ sender: NSMenuItem) {
        guard let what = sender.representedObject as? String else { return }
        if what.hasPrefix("jump:"), let pid = Int32(what.dropFirst(5)) { Jump.toSession(pid: pid); return }
        if what == "claude" { installHooks() } else { installOther(what) }
        lastHookCheck = 0
    }

    @objc private func installSaver() {
        do { try SaverInstaller.install() } catch {
            alert("Couldn't install the screen saver", error.localizedDescription)
            return
        }
        lastSaverCheck = -100   // start publishing as soon as it's in place
        SaverInstaller.openSettings()
        alert("Clawd Clash screen saver installed",
              "In the Wallpaper settings that just opened, go to Screen Saver and pick Clawd Clash (with the other screen savers, near the end of the list). Clawd Clash needs to be running for the crew to show.")
    }

    @objc private func removeSaver() {
        if !SaverInstaller.remove() {
            alert("Couldn't remove the screen saver", "Delete /Library/Screen Savers/Clawd Clash.saver in Finder (it asks for an admin password).")
        }
        lastSaverCheck = -100
    }

    @objc private func ignoreHookIssue(_ sender: NSMenuItem) {
        if let ai = sender.representedObject as? String { ignoreHooks(for: ai) }
    }

    /// Stop nagging about an AI that's installed but deliberately not connected (the banner's ×, or the menu).
    func ignoreHooks(for ai: String) {
        Self.ignoredHooks.insert(ai)
        hookIssues.removeAll { $0.install == ai }
        if windowMode { updateCards(Date().timeIntervalSince1970) }
    }

    @objc private func installHooks() {
        Self.ignoredHooks.remove("claude")
        do { try HookInstaller.install() } catch { alert("Couldn't install hooks", error.localizedDescription) }
    }

    private func installOther(_ name: String) {
        guard let ai = HookInstaller.other(name) else { return }
        let display = HookInstaller.displayName(name)
        Self.ignoredHooks.remove(name)
        do {
            try HookInstaller.install(ai)
            alert("\(display) hooks installed", name == "codex"
                  ? "Codex only runs new hooks after you trust them: run /hooks in Codex and approve them. Codex sessions that are already open pick them up after a restart."
                  : name == "pi" ? "pi sessions that are already open pick it up after /reload (or a restart)."
                  : "\(display) sessions that are already open pick them up after a restart.")
        } catch { alert("Couldn't install \(display) hooks", error.localizedDescription) }
    }

    @objc private func removeHooks() {
        Self.ignoredHooks.insert("claude")
        do { try HookInstaller.uninstall() } catch { alert("Couldn't remove hooks", error.localizedDescription) }
    }

    @objc private func quit() { NSApp.terminate(nil) }

    private func alert(_ title: String, _ text: String) {
        NSApp.activate(ignoringOtherApps: true)
        let a = NSAlert()
        a.messageText = title
        a.informativeText = text
        a.runModal()
    }

    fileprivate var panelOrigin: NSPoint { panel.frame.origin }
}

private extension VaderMode {
    init(_ mood: Mood) {
        switch mood {
        case .idle: self = .idle
        case .thinking: self = .thinking
        case .working: self = .working
        case .waiting: self = .waiting
        case .background: self = .standGuard
        }
    }
}

private extension NSMenu {
    func addItem(disabled title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        addItem(item)
    }

    func addItem(action title: String, _ selector: Selector, target: AnyObject, on: Bool = false) {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = target
        item.state = on ? .on : .off
        addItem(item)
    }
}

final class OverlayView: NSView {
    weak var controller: OverlayController?

    private let sprites = SpriteLayers()

    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {}

    /// A new frame: the crew as Core Animation layers, scaled and composited on the GPU.
    func showFrame() {
        guard let controller else { return }
        wantsLayer = true
        guard let host = layer else { return }
        sprites.update(controller.items, origin: controller.panelOrigin, in: host,
                       pixelsPerPoint: window?.backingScaleFactor ?? 2)
    }

    /// Draw the scene's items (in screen coordinates) into the current context, offset by `origin`.
    /// Shared by the desktop overlay, the window's scene strip and the CLAWD_SHOT frame dump.
    static func render(_ items: [OverlayController.DrawItem], origin o: NSPoint, in ctx: CGContext) {
        ctx.interpolationQuality = .none
        for item in items {
            let r = item.rect.offsetBy(dx: -o.x, dy: -o.y)
            if let text = item.text {
                // Text is built opaque and faded here as a whole (as a layer's opacity does), so a fading label's
                // look doesn't change from frame to frame and `SpriteLayers` can cache it.
                ctx.saveGState()
                ctx.setAlpha(item.alpha)
                defer { ctx.restoreGState() }
                if item.speech {
                    // A character's line: a soft cream backing with fully rounded ends, no border or tail.
                    let box = NSBezierPath(roundedRect: r, xRadius: r.height / 2, yRadius: r.height / 2)
                    NSColor(calibratedRed: 0.98, green: 0.94, blue: 0.84, alpha: 0.95).setFill()
                    box.fill()
                    let ts = text.size(), tw = ts.width.rounded(.up) + 1, th = ts.height.rounded(.up) + 1
                    text.draw(in: NSRect(x: r.midX - tw / 2, y: r.midY - th / 2, width: tw, height: th))
                    continue
                }
                if item.boxed {
                    let box = NSBezierPath(roundedRect: r, xRadius: 4, yRadius: 4)
                    (item.agentBox ? NSColor(calibratedRed: 0.05, green: 0.10, blue: 0.24, alpha: 0.82)
                                   : NSColor(white: 0.08, alpha: 0.82)).setFill()
                    box.fill()
                    if let accent = item.accent {
                        accent.withAlphaComponent(0.9).setStroke()
                        box.lineWidth = 1.5
                    } else {
                        (item.agentBox ? NSColor(calibratedRed: 0.45, green: 0.65, blue: 1, alpha: 0.5)
                                       : NSColor(white: 1, alpha: 0.35)).setStroke()
                        box.lineWidth = 1
                    }
                    box.stroke()
                    // Rounded up, plus a point: drawn into exactly its measured (fractional) width, a line could
                    // wrap onto one that doesn't fit and be cut off.
                    let ts = text.size(), tw = ts.width.rounded(.up) + 1, th = ts.height.rounded(.up) + 1
                    text.draw(in: NSRect(x: r.midX - tw / 2, y: r.midY - th / 2, width: tw, height: th))
                    continue
                }
                text.draw(at: r.origin)
                continue
            }
            guard let image = item.image else { continue }
            ctx.saveGState()
            ctx.setAlpha(item.alpha)
            if item.mirrored || item.upsideDown {
                ctx.translateBy(x: item.mirrored ? r.maxX : r.minX, y: item.upsideDown ? r.maxY : r.minY)
                ctx.scaleBy(x: item.mirrored ? -1 : 1, y: item.upsideDown ? -1 : 1)
                ctx.draw(image, in: NSRect(origin: .zero, size: r.size))
            } else {
                ctx.draw(image, in: r)
            }
            ctx.restoreGState()
        }
    }

    override func mouseDown(with event: NSEvent) { controller?.beginDrag() }
    override func mouseDragged(with event: NSEvent) { controller?.continueDrag() }
    override func mouseUp(with event: NSEvent) { controller?.endDrag() }

    override func rightMouseDown(with event: NSEvent) {
        guard let controller else { return }
        NSMenu.popUpContextMenu(controller.menu(), with: event, for: self)
    }
}
