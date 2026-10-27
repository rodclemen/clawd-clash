import Foundation

// Shared state between the hook binary, which every AI's events go through, and the app, which reads it (and writes
// the universe on show and tidies stale sessions); the screen saver reads it too when the app isn't running.
// Lives at ~/.claude/clawd-clash/state.json.

struct SessionRecord: Codable {
    var state: String      // idle | thinking | working | waiting | background
    var updated: Double
    var leader: Int?       // cast id of this session's character (`Universe.base` + local: villains <100, heroes 100+)
    var project: String?   // last path component of the session's cwd
    var lastTool: Double?  // last PreToolUse, so brief "thinking" gaps between tools still read as working
    var pid: Int32?        // the claude process, so the session disappears as soon as it exits
    var pidStart: Double?  // when that process started, so a recycled pid doesn't keep a dead session alive
    var created: Double?   // when the session first appeared, for spawn order
    var since: Double?     // when `state` last changed (status durations, long-idle sleep, ignored "!")
    var activity: String?  // what it's doing right now, e.g. "Edit Overlay.swift" or "Bash: swift build"
    var prompt: String?    // your last prompt (trimmed)
    var reply: String?     // Claude's last reply (trimmed), from Stop
    var title: String?     // Claude Code's session title
    var model: String?
    var tools: Int?        // tool calls this session
    var prompts: Int?      // prompts this session
    var assistant: String? // "claude", "codex", "qwen", "gemini", "copilot", "pi" (nil = claude, from before Codex support)
    var client: String?    // where Claude Code runs: CLAUDE_CODE_ENTRYPOINT ("cli", "claude-desktop", "claude-vscode"…)
    var regenerated: Double? // a Doctor's last regeneration (its context compacted), for the golden flare
    var abducted: Double?    // an FBI agent's last missing time (its context compacted), for the abduction
    var transformed: Double? // its leader's last change into its other guise, or try at one (its context compacted)
    var moral: Double?       // when its leader last stepped forward with a lesson, on finishing (Stop)
    var context: Double?     // how near its next compaction, 0…1, where the AI's hooks say (Qwen's Stop, our pi extension)
    var transcript: String?  // its session log, where the hooks name it and the app reads it (Gemini CLI's chat file)
    var background: [String]? // what it left running in the background (a render, a build), until it's woken up again
}

struct AgentRecord: Codable {
    var id: String
    var session: String
    var type: String
    var character: Int     // legacy hero index (Companion); `cast` supersedes it
    var cast: Int?         // cast id: `Universe.base` + local (villains <100, heroes 100+)
    var started: Double
    var lastSeen: Double
    var task: String?      // the Agent tool's short description, e.g. "Find hook events"
    var activity: String?  // the agent's current tool call
    var tools: Int?

    /// What it's doing: its task description, else a readable version of its type.
    var label: String {
        if let task, !task.isEmpty { return task }
        switch type {
        case "general-purpose", "agent", "claude": return "Agent"
        case "playground", "demo": return ""
        default: return type.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
}

/// An Agent tool call seen in PreToolUse, waiting for its SubagentStart (which only carries the type).
struct PendingAgent: Codable {
    var session: String
    var type: String
    var task: String
    var at: Double
}

struct StatusFile: Codable {
    var sessions: [String: SessionRecord] = [:]
    var agents: [AgentRecord] = []
    var pending: [PendingAgent]? = []
    /// The universe on show (`Universe.rawValue`), set by the app; the hook casts new characters from it.
    var universe: Int?
    /// Clawd Royale: the hook casts from every universe (`Roster`), and nobody is recast. Nil: one universe.
    var mixed: Bool?
    /// Universes unchecked in Settings → Universes (`Universe.rawValue`s), set by the app: Clawd Royale casts nobody
    /// new from them. Nil: none.
    var removed: [Int]?

    var shownUniverse: Universe { universe.flatMap(Universe.init(rawValue:)) ?? .fallback }
    var removedUniverses: Set<Universe> { Set((removed ?? []).compactMap(Universe.init(rawValue:))) }
    var roster: Roster { Roster(shownUniverse, mixed: mixed == true, removed: removedUniverses) }
}

/// Decodes to nil instead of failing, so one bad record doesn't cost every other one.
private struct Lenient<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}

extension StatusFile {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sessions = (try? c.decode([String: Lenient<SessionRecord>].self, forKey: .sessions))?.compactMapValues(\.value) ?? [:]
        agents = (try? c.decode([Lenient<AgentRecord>].self, forKey: .agents))?.compactMap(\.value) ?? []
        pending = (try? c.decode([Lenient<PendingAgent>].self, forKey: .pending))?.compactMap(\.value) ?? []
        universe = try? c.decode(Int.self, forKey: .universe)
        mixed = try? c.decode(Bool.self, forKey: .mixed)
        removed = try? c.decode([Int].self, forKey: .removed)
    }
}

enum Mood: String {
    case idle, thinking, working, waiting
    case background     // its turn is over, but it's waiting on something it left running and will carry on by itself
}

/// One Claude Code session as the overlay should draw it.
struct SessionSnapshot {
    let id: String
    var leader: Int
    let project: String
    var mood: Mood
    var agents: [AgentRecord]
    var live = true        // false = found in the process table but its hooks never fired
    var pid: Int32?        // the claude process, for jumping to its terminal
    var record: SessionRecord?   // everything the hooks know (nil for sessions without hooks)
    var assistant = "claude"     // which AI runs this session: "claude", "codex", "qwen", "gemini", "copilot" or "pi"
    var stalled = false          // hooks say idle, but the process has been busy for a minute: not reporting
    var hookSilent = false       // started after our hooks were installed and ran a turn, yet never reported (e.g. Codex: not approved)
    var cwd: String?
    var remote: String?          // where the repo's remote lives ("GitHub", "GitLab"…); nil = local only
    var client: String?          // Claude Code's entrypoint: "cli", "claude-desktop", "claude-vscode"…

    /// What the list groups by: Claude Desktop gets its own section; everything else groups by AI.
    var group: String { assistant == "claude" && client == "claude-desktop" ? "claude-desktop" : assistant }

    /// Short name for cards and the menu: "Claude", "Claude Desktop", "Claude · VS Code", "Codex"…
    var aiLabel: String {
        guard assistant == "claude" else { return assistant.capitalized }
        switch client {
        case "claude-desktop": return "Claude Desktop"
        case "claude-vscode": return "Claude · VS Code"
        default: return "Claude"
        }
    }
}

enum StatusPaths {
    /// The real home (`SaverFeed.home`): the screen saver reads this too, and in its sandbox the usual home is its container.
    static let dir = URL(fileURLWithPath: SaverFeed.home).appendingPathComponent(".claude/clawd-clash", isDirectory: true)
    static let state = dir.appendingPathComponent("state.json")
    static let lock = dir.appendingPathComponent("state.lock")
}

enum StatusStore {

    // Stale timeouts: Stop never fires when the user hits Esc, so states must decay on their own.
    static let thinkingTTL: Double = 10 * 60
    static let workingTTL: Double = 30 * 60
    static let waitingTTL: Double = 15 * 60
    /// A background job that never wakes its session (killed, or the AI quit) stops counting after this.
    static let backgroundTTL: Double = 60 * 60
    static let agentTTL: Double = 20 * 60
    static let sessionTTL: Double = 3 * 60 * 60
    /// A session with no known process can't be checked for being alive: past this it no longer counts when
    /// picking sides and characters.
    static let noPidTTL: Double = 30 * 60
    /// A "thinking" this soon after a tool call is just the gap between tools.
    static let toolGrace: Double = 3

    static func load() -> StatusFile? {
        guard let data = try? Data(contentsOf: StatusPaths.state) else { return nil }
        return try? JSONDecoder().decode(StatusFile.self, from: data)
    }

    /// Runs `body` on the state under the lock and writes the result. Without the lock nothing is written:
    /// skipping one event beats two writers clobbering each other.
    static func withLock(_ body: (inout StatusFile) -> Void) {
        try? FileManager.default.createDirectory(at: StatusPaths.dir, withIntermediateDirectories: true)
        // Owner-only, like Claude Code's ~/.claude/projects: the state holds your prompts, replies and commands.
        // A chmod rather than a create attribute, so folders made earlier with 0755 are tightened too.
        chmod(StatusPaths.dir.path, 0o700)
        let fd = open(StatusPaths.lock.path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { return }
        defer { close(fd) }
        var locked = flock(fd, LOCK_EX) == 0
        while !locked && errno == EINTR { locked = flock(fd, LOCK_EX) == 0 }
        guard locked else { return }
        defer { flock(fd, LOCK_UN) }
        var status: StatusFile
        if let data = try? Data(contentsOf: StatusPaths.state), !data.isEmpty {
            if let decoded = try? JSONDecoder().decode(StatusFile.self, from: data) {
                status = decoded
            } else {
                // Not even the outline decodes: keep a copy to look at before starting over.
                let corrupt = StatusPaths.state.appendingPathExtension("corrupt")
                try? FileManager.default.removeItem(at: corrupt)
                try? data.write(to: corrupt)
                chmod(corrupt.path, 0o600)
                status = StatusFile()
            }
        } else {
            status = StatusFile()
        }
        body(&status)
        if let data = try? JSONEncoder().encode(status) {
            try? data.write(to: StatusPaths.state, options: .atomic)
            chmod(StatusPaths.state.path, 0o600)
        }
    }

    /// How near a session is to its next automatic compaction (0…1, 1 = compacting), where its hooks say so:
    /// - Qwen Code's Stop carries `context_usage`, the prompt's tokens over the window; it compacts at 85% of that.
    /// - Our pi extension sends `ctx.getContextUsage()`, `{tokens, contextWindow}`; pi compacts when fewer than
    ///   16,384 tokens are left.
    static func contextNearness(_ json: [String: Any], assistant: String) -> Double? {
        switch assistant {
        case "qwen":
            guard let used = (json["context_usage"] as? NSNumber)?.doubleValue, used >= 0 else { return nil }
            return min(1, used / 0.85)
        case "pi":
            guard let u = json["context_usage"] as? [String: Any], let tokens = (u["tokens"] as? NSNumber)?.doubleValue,
                  let window = (u["contextWindow"] as? NSNumber)?.doubleValue, window > 16_384 else { return nil }
            return min(1, max(0, tokens / (window - 16_384)))
        default:
            return nil
        }
    }

    /// Brings other AIs' payloads to the Claude Code shape `apply` reads: Copilot's camelCase fields, Gemini CLI's
    /// event names (BeforeAgent → UserPromptSubmit, AfterTool → PostToolUse…), tool input sent as a JSON string.
    static func normalize(_ input: [String: Any], assistant: String, event: String?) -> [String: Any] {
        var j = input
        let renames = ["sessionId": "session_id", "hookEventName": "hook_event_name", "toolName": "tool_name",
                       "toolArgs": "tool_input", "transcriptPath": "transcript_path", "agentId": "agent_id",
                       "agentName": "agent_type", "agentDescription": "description"]
        for (from, to) in renames where j[to] == nil { if let v = j[from] { j[to] = v } }
        if let text = j["tool_input"] as? String, let data = text.data(using: .utf8),
           let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] { j["tool_input"] = obj }
        if let event { j["hook_event_name"] = event }
        if assistant == "gemini" {
            let names = ["BeforeAgent": "UserPromptSubmit", "AfterAgent": "Stop", "BeforeTool": "PreToolUse", "AfterTool": "PostToolUse"]
            if let e = j["hook_event_name"] as? String, let mapped = names[e] { j["hook_event_name"] = mapped }
            if j["last_assistant_message"] == nil, let reply = j["prompt_response"] { j["last_assistant_message"] = reply }
            if (j["notification_type"] as? String) == "ToolPermission" { j["notification_type"] = "permission_prompt" }
        }
        // pi's built-in tools, by the names and fields Claude Code uses for them.
        if assistant == "pi" {
            let names = ["bash": "Bash", "read": "Read", "write": "Write", "edit": "Edit", "grep": "Grep", "find": "Glob",
                         "ls": "list_directory"]
            if let t = j["tool_name"] as? String, let mapped = names[t] { j["tool_name"] = mapped }
            if var input = j["tool_input"] as? [String: Any], input["file_path"] == nil, let path = input["path"],
               ["Read", "Write", "Edit"].contains(j["tool_name"] as? String ?? "") {
                input["file_path"] = path
                j["tool_input"] = input
            }
        }
        return j
    }

    /// Apply one Claude Code hook event (the JSON Claude Code pipes to the hook on stdin), after `normalize`.
    static func apply(event json: [String: Any], assistant: String = "claude", now: Double = Date().timeIntervalSince1970) {
        let event = json["hook_event_name"] as? String ?? ""
        let session = json["session_id"] as? String ?? "default"
        let agentId = json["agent_id"] as? String
        let project = (json["cwd"] as? String).map { URL(fileURLWithPath: $0).lastPathComponent }
        let hookOwner = agentId == nil ? ClaudeProcesses.hookOwner() : nil
        // Codex hooks run under its shared app-server; `ClaudeProcesses.codexSession` finds the session's own process.
        let owner = assistant == "codex" ? hookOwner.map { ClaudeProcesses.codexSession(server: $0, cwd: json["cwd"] as? String) ?? $0 } : hookOwner
        let ownerStart = owner.flatMap(ClaudeProcesses.startTime)

        withLock { s in
            prune(&s, now: now)
            if event != "SessionEnd" {
                let agentCasts = s.agents.compactMap { $0.cast ?? (heroBase + $0.character) }
                if s.sessions[session] == nil {
                    var rec = SessionRecord(state: "idle", updated: now,
                                            leader: nextLeader(castable(s.sessions, now: now), agents: agentCasts, assistant: assistant,
                                                               roster: s.roster), project: project)
                    rec.assistant = assistant
                    rec.created = now
                    s.sessions[session] = rec
                }
                if s.sessions[session]?.leader == nil {
                    let leader = nextLeader(castable(s.sessions, now: now), agents: agentCasts, assistant: assistant, roster: s.roster)
                    s.sessions[session]?.leader = leader
                }
                if let project, agentId == nil { s.sessions[session]?.project = project }
                if let owner {
                    s.sessions[session]?.pid = owner
                    s.sessions[session]?.pidStart = ownerStart
                    // A process hosts one live session: any other one on it was replaced (e.g. /clear starts a new
                    // session id in the same process) and will never hear another event.
                    let replaced = s.sessions.filter { id, rec in
                        id != session && rec.pid == owner && samePID(rec.pidStart, ownerStart)
                    }.map(\.key)
                    for id in replaced { s.sessions[id] = nil }
                    s.agents.removeAll { replaced.contains($0.session) }
                    s.pending = s.pending?.filter { !replaced.contains($0.session) }
                }
                // How near the next compaction is, where the AI tells its hooks; and Gemini CLI's chat log, which
                // the app reads for the same (`ContextUsage`).
                if let used = contextNearness(json, assistant: assistant) { s.sessions[session]?.context = used }
                if assistant == "gemini", let path = json["transcript_path"] as? String, !path.isEmpty {
                    s.sessions[session]?.transcript = path
                }
                // Claude Code tells its hooks where it was started from (terminal, desktop app, VS Code…).
                if assistant == "claude", let entry = ProcessInfo.processInfo.environment["CLAUDE_CODE_ENTRYPOINT"], !entry.isEmpty {
                    s.sessions[session]?.client = entry
                }
            }
            func set(_ state: String) {
                if s.sessions[session]?.state != state || s.sessions[session]?.since == nil { s.sessions[session]?.since = now }
                s.sessions[session]?.state = state
                s.sessions[session]?.updated = now
            }
            // Agents at work keep their session fresh too (without changing its state), so a long subagent run
            // doesn't let the parent decay to idle or be pruned.
            func touchSession(_ id: String) {
                if s.sessions[id] != nil { s.sessions[id]?.updated = now }
            }
            func touchAgent(_ id: String) {
                if let i = s.agents.firstIndex(where: { $0.id == id }) {
                    s.agents[i].lastSeen = now
                    touchSession(s.agents[i].session)
                }
            }
            func clip(_ v: Any?, _ n: Int) -> String? {
                guard let t = (v as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
                let flat = t.replacingOccurrences(of: "\n", with: " ")
                return flat.count > n ? String(flat.prefix(n - 1)) + "…" : flat
            }
            if let title = clip(json["session_title"], 80) { s.sessions[session]?.title = title }
            // Its first event after a background wait: a job it left running has finished and woken it (or you
            // typed something), so it's at work again. Which job isn't said, so they all count as done; any it
            // starts again are counted afresh.
            if agentId == nil, s.sessions[session]?.state == "background", event != "Notification" && event != "PreCompact" {
                s.sessions[session]?.background = nil
            }

            switch event {
            case "SessionStart":
                set("idle")
                if let m = json["model"] as? String { s.sessions[session]?.model = m }
                else if let m = (json["model"] as? [String: Any])?["id"] as? String { s.sessions[session]?.model = m }
            case "UserPromptSubmit":
                set("thinking")
                if let m = json["model"] as? String { s.sessions[session]?.model = m }   // pi can switch model mid-session
                s.sessions[session]?.prompt = clip(json["prompt"], 240)
                let promptsCount = (s.sessions[session]?.prompts ?? 0) + 1
                    s.sessions[session]?.prompts = promptsCount
                s.sessions[session]?.activity = nil
            case "PreToolUse":
                let activity = describeTool(json["tool_name"] as? String ?? "", json["tool_input"] as? [String: Any] ?? [:])
                if let a = agentId {
                    touchAgent(a)
                    if let i = s.agents.firstIndex(where: { $0.id == a }) {
                        s.agents[i].activity = activity
                        s.agents[i].tools = (s.agents[i].tools ?? 0) + 1
                    }
                } else {
                    set("working")
                    s.sessions[session]?.lastTool = now
                    s.sessions[session]?.activity = activity
                    if let job = backgroundJob(assistant, json["tool_name"] as? String ?? "", json["tool_input"] as? [String: Any] ?? [:],
                                                cwd: json["cwd"] as? String) {
                        let jobs = (s.sessions[session]?.background ?? []) + [job]
                        s.sessions[session]?.background = jobs
                    }
                    let toolsCount = (s.sessions[session]?.tools ?? 0) + 1
                    s.sessions[session]?.tools = toolsCount
                    // Remember the task of each agent Claude launches; SubagentStart picks it up.
                    let tool = json["tool_name"] as? String ?? ""
                    if ["Agent", "Task", "task", "agent"].contains(tool), let input = json["tool_input"] as? [String: Any],
                       let task = (input["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !task.isEmpty {
                        s.pending = (s.pending ?? []) + [PendingAgent(session: session,
                            type: input["subagent_type"] as? String ?? "general-purpose", task: task, at: now)]
                    }
                }
            case "PostToolUse", "PostToolUseFailure":
                if let a = agentId { touchAgent(a) } else {
                    set("thinking")
                    s.sessions[session]?.lastTool = now
                }
            case "PermissionRequest":
                if agentId == nil {
                    set("waiting")
                    let tool = describeTool(json["tool_name"] as? String ?? "", json["tool_input"] as? [String: Any] ?? [:])
                    s.sessions[session]?.activity = "Asking to: " + tool
                }
            case "Notification":
                let type = json["notification_type"] as? String ?? ""
                let message = (json["message"] as? String ?? "").lowercased()
                if type == "permission_prompt" || message.contains("permission") { set("waiting") }
            case "PreCompact":
                // A Doctor whose context is compacted regenerates: same session, the next Doctor's face (one nobody
                // else is leading with), in a golden flare the overlay plays.
                guard agentId == nil, let leader = s.sessions[session]?.leader else { break }
                // An FBI agent in The Clawd Files loses some time instead: abducted, and set back down.
                if Universe.of(leader).abductees.contains(leader) { s.sessions[session]?.abducted = now; break }
                // In Clawds of the Universe, one of a pair of guises turns into the other (Prince Addam into He-Clawd,
                // and back the next time), unless the other already leads a session or works as an agent: nobody meets
                // their own secret identity. Then the flash plays and they stay as they are.
                if Universe.of(leader).transforms, let pair = Universe.of(leader).guises.first(where: { $0.contains(leader) }),
                   let other = pair.subtracting([leader]).first {
                    let roster = s.roster
                    let elsewhere = s.sessions.filter { $0.key != session }.values.compactMap(\.leader)
                        + s.agents.map { $0.cast ?? StatusStore.heroBase + $0.character }
                    if !elsewhere.contains(where: { roster.adopt($0) == other }) { s.sessions[session]?.leader = other }
                    s.sessions[session]?.transformed = now
                    break
                }
                let order = Universe.of(leader).regenerations
                guard let i = order.firstIndex(of: leader) else { break }
                let used = Set(s.sessions.filter { $0.key != session }.values.compactMap(\.leader))
                let next = (1..<order.count).map { order[(i + $0) % order.count] }.first { !used.contains($0) }
                if let next {
                    s.sessions[session]?.leader = next
                    s.sessions[session]?.regenerated = now
                }
            case "Stop", "StopFailure", "Interrupt":
                set(s.sessions[session]?.background?.isEmpty == false ? "background" : "idle")
                s.sessions[session]?.lastTool = nil
                s.sessions[session]?.activity = nil
                if let r = clip(json["last_assistant_message"], 240) { s.sessions[session]?.reply = r }
                // Now and then a leader who gives lessons steps forward with one as it finishes (Clawds of the
                // Universe's moral of the story), never twice within half an hour.
                if event == "Stop", agentId == nil, let leader = s.sessions[session]?.leader,
                   let chance = Universe.of(leader).morals[leader],
                   (s.sessions[session]?.moral).map({ now - $0 > 1800 }) ?? true, Double.random(in: 0..<1) < chance {
                    s.sessions[session]?.moral = now
                }
            case "SubagentStart":
                touchSession(session)
                let id = agentId ?? UUID().uuidString
                if !s.agents.contains(where: { $0.id == id }) {
                    let type = json["agent_type"] as? String ?? "agent"
                    // Oldest queued launch of this type in this session (any type as a fallback).
                    var pending = s.pending ?? []
                    let match = pending.firstIndex { $0.session == session && $0.type == type }
                        ?? pending.firstIndex { $0.session == session }
                    let task = match.map { pending.remove(at: $0).task } ?? clip(json["description"], 80)
                    s.pending = pending
                    s.agents.append(AgentRecord(
                        id: id, session: session, type: type,
                        character: 0, cast: nextAgentCast(s, session: session, now: now),
                        started: now, lastSeen: now, task: task))
                }
            case "SubagentStop":
                touchSession(session)
                if let a = agentId, s.agents.contains(where: { $0.id == a }) {
                    s.agents.removeAll { $0.id == a }
                } else if agentId == nil || assistant == "copilot" {
                    // No id, or (Copilot) an id its SubagentStart didn't give us: the oldest agent of that type
                    // (the oldest of any type when the type is missing or unknown).
                    let type = json["agent_type"] as? String
                    if let i = s.agents.firstIndex(where: { $0.session == session && $0.type == type })
                        ?? s.agents.firstIndex(where: { $0.session == session }) {
                        s.agents.remove(at: i)
                    }
                }
            case "SessionEnd":
                s.sessions[session] = nil
                s.agents.removeAll { $0.session == session }
            default:
                break
            }
        }
    }

    /// What a tool call leaves running in the background, by its description ("Render the promo"), or nil when it
    /// runs to the end before the AI goes on, or the AI won't be woken when it's done. Only the AIs that carry on by
    /// themselves when the job finishes count, so a session never waits on something that will never wake it:
    /// - Claude Code: Bash with `run_in_background`, and the Monitor tool.
    /// - Qwen Code: `run_shell_command` with `is_background`, and its monitor tool. Its woken turn skips
    ///   UserPromptSubmit, but its first tool call or Stop ends the wait all the same.
    /// - Copilot CLI: Bash with `mode: "async"` (detached too): it starts a turn of its own when the job ends.
    /// - Gemini CLI: `run_shell_command` with `is_background`, only when its settings feed the result back and let it
    ///   take a turn by itself (`geminiWakesOnJobs`); otherwise a finished job waits for you, so it's plain idle.
    /// - Codex and pi: never. Codex has to poll its running commands itself (`write_stdin`), pi has no background jobs.
    /// Background agents aren't here: they're on stage as agents, and the session already waits on them.
    static func backgroundJob(_ assistant: String, _ tool: String, _ input: [String: Any], cwd: String? = nil) -> String? {
        func str(_ k: String) -> String? {
            guard let v = (input[k] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return nil }
            return v
        }
        func job(_ fallback: String) -> String {
            let flat = (str("description") ?? str("command") ?? fallback).replacingOccurrences(of: "\n", with: " ")
            return flat.count > 60 ? String(flat.prefix(59)) + "…" : flat
        }
        switch (assistant, tool) {
        case ("claude", "Bash") where input["run_in_background"] as? Bool == true,
             ("qwen", "run_shell_command") where input["is_background"] as? Bool == true,
             ("copilot", "Bash"), ("copilot", "bash"):
            if assistant == "copilot" && str("mode") != "async" { return nil }
            return job("a command")
        case ("claude", "Monitor"), ("qwen", "monitor"), ("qwen", "Monitor"):   // wakes it on each line it watches for
            return job("a process")
        case ("gemini", "run_shell_command") where input["is_background"] as? Bool == true:
            return geminiWakesOnJobs(cwd: cwd) ? job("a command") : nil
        default:
            return nil
        }
    }

    /// Gemini CLI takes a turn by itself when a background command ends only with both settings on:
    /// `tools.shell.backgroundCompletionBehavior` "inject" or "notify" (the default "silent" feeds nothing back) and
    /// `experimental.modelSteering`. The project's .gemini/settings.json wins over ~/.gemini/settings.json.
    static func geminiWakesOnJobs(cwd: String?) -> Bool {
        var behavior = "silent", steering = false
        let files = [SaverFeed.home + "/.gemini/settings.json"] + (cwd.map { [$0 + "/.gemini/settings.json"] } ?? [])
        for f in files {
            guard let data = FileManager.default.contents(atPath: f),
                  let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { continue }
            if let b = ((root["tools"] as? [String: Any])?["shell"] as? [String: Any])?["backgroundCompletionBehavior"] as? String {
                behavior = b
            }
            if let on = (root["experimental"] as? [String: Any])?["modelSteering"] as? Bool { steering = on }
        }
        return steering && (behavior == "inject" || behavior == "notify")
    }

    /// A short, human description of a tool call: "Edit Overlay.swift", "Bash: swift build", "Grep fightRoles".
    static func describeTool(_ tool: String, _ input: [String: Any]) -> String {
        func str(_ k: String) -> String? { (input[k] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
        func file(_ k: String) -> String? { str(k).map { ($0 as NSString).lastPathComponent } }
        func short(_ v: String, _ n: Int = 48) -> String {
            let flat = v.replacingOccurrences(of: "\n", with: " ")
            return flat.count > n ? String(flat.prefix(n - 1)) + "…" : flat
        }
        switch tool {
        case "Bash", "shell", "exec_command", "local_shell", "run_shell_command":
            return "Bash: " + short(str("description") ?? str("command") ?? (input["command"] as? [String])?.joined(separator: " ") ?? "")
        case "apply_patch":   // Codex edits files with patches: name the first file it touches
            let patch = str("command") ?? str("input") ?? ""
            let file = patch.components(separatedBy: "\n").first { $0.hasPrefix("*** ") && $0.contains("File: ") }
                .map { ($0.components(separatedBy: "File: ").last ?? "") as NSString }
            return "Edit " + (file?.lastPathComponent ?? "files")
        case "Read", "Edit", "Write", "MultiEdit": return "\(tool) \(file("file_path") ?? "")"
        // Qwen Code's tools
        case "read_file", "read_many_files": return "Read " + (file("file_path") ?? file("absolute_path") ?? file("path") ?? "files")
        case "write_file": return "Write " + (file("file_path") ?? file("absolute_path") ?? "")
        case "edit", "replace": return "Edit " + (file("file_path") ?? file("absolute_path") ?? "")
        case "grep_search", "search_file_content": return "Grep " + short(str("pattern") ?? "", 32)
        case "glob": return "Glob " + short(str("pattern") ?? "", 32)
        case "web_fetch": return "Fetch " + (str("url").flatMap { URL(string: $0)?.host } ?? "the web")
        case "web_search", "google_web_search": return "Search: " + short(str("query") ?? "", 40)
        case "todo_write", "write_todos": return "Updating todos"
        case "list_directory": return "List " + (file("dir_path") ?? file("path") ?? "files")
        case "task", "agent": return "Agent: " + short(str("description") ?? "", 40)
        case "NotebookEdit": return "Edit \(file("notebook_path") ?? "")"
        case "Grep": return "Grep " + short(str("pattern") ?? "", 32)
        case "Glob": return "Glob " + short(str("pattern") ?? "", 32)
        case "WebFetch": return "Fetch " + (str("url").flatMap { URL(string: $0)?.host } ?? "")
        case "WebSearch": return "Search: " + short(str("query") ?? "", 40)
        case "Agent", "Task": return "Agent: " + short(str("description") ?? "", 40)
        case "Skill": return "Skill " + (str("skill") ?? "")
        case "TodoWrite": return "Updating todos"
        default:
            if tool.hasPrefix("mcp__") {   // mcp__server__tool → "server: tool"
                let parts = tool.dropFirst(5).components(separatedBy: "__")
                return parts.count >= 2 ? "\(parts[0]): \(parts.dropFirst().joined(separator: " "))" : tool
            }
            return tool
        }
    }

    // MARK: Cast and sides
    //
    // Cast ids: see `Universe` (villains local 0..<100, heroes 100…, plus the universe's base). One AI running: every
    // new character is random from the roster's whole cast (one universe, or every released one in Clawd Royale). Two AIs running:
    // the roster's `claudeSide` says which side Claude takes; otherwise the AI that was there first keeps the side it
    // mostly has and the other takes the opposite. Each one's agents join their session's side. If a side is all on
    // screen, the other lends someone.

    static let heroBase = 100
    static func isDark(_ cast: Int) -> Bool { Universe.isDark(cast) }

    static func assistantOf(_ r: SessionRecord) -> String { r.assistant ?? "claude" }

    /// The side `assistant` should use right now (true: villains), or nil when it's the only AI running (anything
    /// goes). Claude Code takes the roster's `claudeSide` (the heroes everywhere but Star Wars) and the others the
    /// opposite; otherwise, or with no Claude among them, whoever has been running longest keeps the side it mostly
    /// has and the rest take the other.
    static func side(for assistant: String, in sessions: [String: SessionRecord], roster: Roster) -> Bool? {
        let live = sessions.values.filter { $0.leader != nil }
        guard live.contains(where: { assistantOf($0) != assistant }) else { return nil }
        let isClaude = { (ai: String) in ai == "claude" || ai.hasPrefix("claude-") }
        if let claudeSide = roster.claudeSide {
            if isClaude(assistant) { return claudeSide }
            if live.contains(where: { isClaude(assistantOf($0)) }) { return !claudeSide }
        }
        // (A record without `created` predates that field, so it's older than any that has one.)
        guard let first = live.min(by: { ($0.created ?? 0) < ($1.created ?? 0) }) else { return nil }
        let firstAI = assistantOf(first)
        let theirs = live.filter { assistantOf($0) == firstAI }.sorted { ($0.created ?? 0) < ($1.created ?? 0) }
        let dark = theirs.filter { isDark($0.leader!) }.count, light = theirs.count - dark
        let firstSideDark = dark == light ? isDark(theirs[0].leader!) : dark > light
        return firstAI == assistant ? firstSideDark : !firstSideDark
    }

    /// Character for a new session: random from the whole cast, or from this AI's side when two AIs are running
    /// (borrowing from the other side only when its own is all on screen).
    static func nextLeader(_ sessions: [String: SessionRecord], agents: [Int] = [], assistant: String = "claude", roster: Roster) -> Int {
        let used = Set(sessions.values.compactMap(\.leader))
        let ruled = roster.ruledOut(by: Set((Array(used) + agents).map(roster.adopt)))
        let latest = sessions.values.filter { $0.leader != nil }.max { ($0.created ?? $0.updated) < ($1.created ?? $1.updated) }
        let pool: [Int]
        let dark = roster.darkCast, light = roster.lightCast
        switch side(for: assistant, in: sessions, roster: roster) {
        case .some(true): pool = dark.filter { !used.contains($0) }.isEmpty ? light : dark
        case .some(false): pool = light.filter { !used.contains($0) }.isEmpty ? dark : light
        case nil: pool = dark + light
        }
        // One HEM at most, whichever universe he's from.
        if !used.contains(where: Roster.isHem), pool.contains(where: { !isDark($0) }),
           Double.random(in: 0..<1) < Universe.hemOdds.session {
            return roster.hems.randomElement()!
        }
        return pickLeader(used: used, previous: latest?.leader, pool: pool, roster: roster, ruledOut: ruled)
    }

    /// Character for a new agent: its session's side when two AIs are running, otherwise anyone;
    /// someone not already on screen whenever possible.
    static func nextAgentCast(_ s: StatusFile, session: String, now: Double = Date().timeIntervalSince1970) -> Int {
        var s = s
        s.sessions = castable(s.sessions, now: now)
        let r = s.roster
        // As shown: a character cast in another universe (before a switch) stands as its counterpart here.
        let onScreen = Set((s.agents.compactMap { $0.cast ?? (heroBase + $0.character) } + s.sessions.values.compactMap(\.leader)).map(r.adopt))
        var pool = r.darkCast + r.lightCast
        if let rec = s.sessions[session], let leader = rec.leader, side(for: assistantOf(rec), in: s.sessions, roster: r) != nil {
            pool = isDark(leader) ? r.darkCast : r.lightCast
        }
        let ruled = r.ruledOut(by: Set(onScreen.map(r.adopt)))
        let allowed = pool.filter { !ruled.contains($0) }   // never the other guise of someone on screen
        if !allowed.isEmpty { pool = allowed }
        if !onScreen.contains(where: Roster.isHem), pool.contains(where: { !isDark($0) }),
           Double.random(in: 0..<1) < Universe.hemOdds.agent {
            return r.hems.randomElement()!
        }
        let free = pool.filter { !onScreen.contains($0) }
        return (free.isEmpty ? pool : free).randomElement()!
    }

    /// `seed` makes the choice deterministic (for sessions found by the process scan, re-evaluated every refresh).
    static func pickLeader(used: Set<Int>, previous: Int?, seed: UInt64? = nil, pool: [Int], roster: Roster,
                           ruledOut: Set<Int> = []) -> Int {
        var pool = pool.filter { !roster.agentOnly.contains($0) }
        let allowed = pool.filter { !ruledOut.contains($0) }   // never the other guise of someone on screen
        if !allowed.isEmpty { pool = allowed }
        var free = pool.filter { !used.contains($0) }
        if free.isEmpty { free = pool }                      // the whole pool is on screen: repeats are fine
        let rivals = roster.rivals                           // Vader and Kylo never lead two sessions back to back
        if let p = previous, rivals.contains(p) {
            let spaced = free.filter { !rivals.contains($0) || $0 == p }
            if !spaced.isEmpty { free = spaced }
        }
        if let seed { return free[Int(seed % UInt64(free.count))] }
        return free.randomElement()!
    }

    /// Sessions that count when picking sides and characters: one with no known process only while it's recent,
    /// since nothing tells us when it ends.
    static func castable(_ sessions: [String: SessionRecord], now: Double) -> [String: SessionRecord] {
        sessions.filter { $0.value.pid != nil || now - $0.value.updated < noPidTTL }
    }

    /// Times from the future (the clock was set back) would keep a record fresh for as long as the jump: treat them as now.
    static func clampFuture(_ s: inout StatusFile, now: Double) {
        func fix(_ t: inout Double) { if t > now + 60 { t = now } }
        func fix(_ t: inout Double?) { if let v = t, v > now + 60 { t = now } }
        for id in s.sessions.keys {
            fix(&s.sessions[id]!.updated); fix(&s.sessions[id]!.since)
            fix(&s.sessions[id]!.lastTool); fix(&s.sessions[id]!.created)
        }
        for i in s.agents.indices { fix(&s.agents[i].lastSeen); fix(&s.agents[i].started) }
        for i in (s.pending ?? []).indices { fix(&s.pending![i].at) }
    }

    static func prune(_ s: inout StatusFile, now: Double) {
        clampFuture(&s, now: now)
        s.agents.removeAll { now - $0.lastSeen > agentTTL }
        s.sessions = s.sessions.filter { now - $0.value.updated < sessionTTL && isAlive($0.value.pid, started: $0.value.pidStart) }
        let sessions = Set(s.sessions.keys)
        // An agent whose session is gone goes after a minute; an Agent call still waiting for its SubagentStart after
        // two minutes isn't coming.
        s.agents.removeAll { !sessions.contains($0.session) && now - $0.started > 60 }
        s.pending = (s.pending ?? []).filter { now - $0.at < 120 && sessions.contains($0.session) }
    }

    /// Is the session's process still running? With its start time known, a different process that has
    /// since been given the same pid doesn't count.
    static func isAlive(_ pid: Int32?, started: Double? = nil) -> Bool {
        guard let pid else { return true }
        guard kill(pid, 0) == 0 || errno != ESRCH else { return false }
        guard let started, let current = ClaudeProcesses.startTime(pid) else { return true }
        return abs(current - started) < 1
    }

    /// Two records on the same pid are the same process unless both start times are known and differ.
    static func samePID(_ a: Double?, _ b: Double?) -> Bool {
        guard let a, let b else { return true }
        return abs(a - b) < 1
    }

    /// FNV-1a over the UTF-8 bytes: the same on every launch, unlike `hashValue`.
    static func stableHash(_ text: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in text.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
    }

    /// Tell the hook (and the screen saver, when the app isn't running) what's on show: the universe, and whether it's
    /// Clawd Royale.
    static func setUniverse(_ universe: Universe, mixed: Bool = false) {
        withLock { s in s.universe = universe.rawValue; s.mixed = mixed ? true : nil }
    }

    /// Tell the hook which universes are unchecked in Settings, so Clawd Royale casts nobody new from them.
    static func setRemoved(_ removed: Set<Universe>) {
        withLock { s in s.removed = removed.isEmpty ? nil : removed.map(\.rawValue).sorted() }
    }

    /// Drop idle sessions with no agents (e.g. terminals closed without a clean exit). They return on their next event.
    static func forgetIdleSessions() {
        withLock { s in
            let busy = Set(s.agents.map(\.session))
            s.sessions = s.sessions.filter { $0.value.state != "idle" || busy.contains($0.key) }
        }
    }

    static func mood(_ rec: SessionRecord, id: String, now: Double) -> Mood {
        let age = now - rec.updated
        let m = Mood(rawValue: rec.state) ?? .idle
        if m == .waiting, (rec.assistant ?? "claude") == "claude" {
            // A question or permission prompt waits as long as it takes: the session's process is checked elsewhere,
            // so a dead one is already gone. Pressing Esc fires no hook, but Claude Code writes the interruption
            // to the transcript, which ends the wait at once. Can't read the transcript (the screen saver's
            // sandbox): the old timeout.
            switch interrupted(sessionID: id, since: rec.since ?? rec.updated) {
            case true?: return .idle
            case false?: return .waiting
            case nil: break
            }
        }
        switch m {
        case .thinking where age > thinkingTTL, .working where age > workingTTL, .waiting where age > waitingTTL,
             .background where age > backgroundTTL:
            return .idle
        case .thinking where now - (rec.lastTool ?? 0) < toolGrace:
            return .working
        default:
            return m
        }
    }

    private static var transcripts: [String: URL] = [:]
    private static var interruptCache: [String: (modified: Date, since: Double, result: Bool)] = [:]

    /// Whether the user interrupted Claude Code session `sessionID` (Esc, "[Request interrupted by user…]" in its
    /// transcript) after `since`; nil when the transcript can't be found or read. Re-read only when the file changes.
    static func interrupted(sessionID: String, since: Double) -> Bool? {
        let fm = FileManager.default
        if transcripts[sessionID] == nil {
            let root = fm.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")
            for dir in (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
                let f = dir.appendingPathComponent(sessionID + ".jsonl")
                if fm.fileExists(atPath: f.path) { transcripts[sessionID] = f; break }
            }
        }
        guard let url = transcripts[sessionID],
              let modified = (try? fm.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else { return nil }
        if let hit = interruptCache[sessionID], hit.modified == modified, hit.since == since { return hit.result }
        // Nothing written since the question: still waiting. Otherwise look at the newest interruption in the tail
        // (the real entry, unescaped: a command that merely mentions it is stored with escaped quotes).
        var result = false
        // (Half a second of slack between the question's time and the file's modification date.)
        if modified.timeIntervalSince1970 > since + 0.5, let h = try? FileHandle(forReadingFrom: url) {
            defer { try? h.close() }
            let size = (try? h.seekToEnd()) ?? 0
            try? h.seek(toOffset: size > 32_768 ? size - 32_768 : 0)   // only the last 32 KB: the newest entries
            let tail = String(decoding: h.readDataToEndOfFile(), as: UTF8.self)
            if let line = tail.split(separator: "\n").last(where: { $0.contains(#""text":"[Request interrupted by user"#) }),
               let r = line.range(of: #""timestamp":"([^"]+)""#, options: .regularExpression) {
                let stamp = line[r].dropFirst(13).dropLast()   // 13: the length of `"timestamp":"`
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let when = iso.date(from: String(stamp)) { result = when.timeIntervalSince1970 > since }
            }
        }
        interruptCache[sessionID] = (modified, since, result)
        return result
    }

    /// A session's name: the repo's, when it has a remote; otherwise its folder's.
    static func projectName(cwd: String?, git: GitRemote?) -> String? {
        git?.name ?? cwd.map { ($0 as NSString).lastPathComponent }
    }

    /// `snaps` as they may appear at `place` (a place key; nil: no place, the desktop): the homebound away from home
    /// are shown as someone else (`Roster.recast`), leaders first, then each session's agents.
    static func at(_ snaps: [SessionSnapshot], place: String?, roster: Roster) -> [SessionSnapshot] {
        guard !roster.homebound.isEmpty else { return snaps }
        var ids: [Int] = [], seeds: [String] = []
        for s in snaps { ids.append(roster.adopt(s.leader)); seeds.append(s.id) }
        for s in snaps { for a in s.agents { ids.append(roster.adopt(a.cast ?? heroBase + a.character)); seeds.append(a.id) } }
        let shown = roster.recast(ids, seeds: seeds, at: place)
        guard shown != ids else { return snaps }
        var out = snaps, k = snaps.count
        for i in out.indices {
            out[i].leader = shown[i]
            for j in out[i].agents.indices { out[i].agents[j].cast = shown[k]; k += 1 }
        }
        return out
    }

    /// Every live session in spawn order (empty when none are running, unless stray agents need a placeholder: the
    /// universe's first villain). `processes` (from `ClaudeProcesses.running()`) adds sessions whose hooks never fired
    /// and drops dead ones.
    static func snapshot(_ s: StatusFile, now: Double = Date().timeIntervalSince1970,
                         processes: [ClaudeProcesses.Info]? = nil) -> [SessionSnapshot] {
        var s = s
        clampFuture(&s, now: now)
        var live = s.sessions.filter { now - $0.value.updated < sessionTTL && isAlive($0.value.pid, started: $0.value.pidStart) }
        if let processes {
            let running = Set(processes.map(\.pid))
            live = live.filter { $0.value.pid.map { running.contains($0) } ?? true }
        }
        // One live session per process: the newest wins (the others were replaced, e.g. by /clear; the hook
        // drops them on its next event).
        var newest: [Int32: (id: String, updated: Double)] = [:]
        for (id, rec) in live {
            guard let pid = rec.pid else { continue }
            if let n = newest[pid], n.updated > rec.updated || (n.updated == rec.updated && n.id > id) { continue }
            newest[pid] = (id, rec.updated)
        }
        let replaced = Set(live.filter { id, rec in rec.pid.map { newest[$0]?.id != id } ?? false }.map(\.key))
        live = live.filter { !replaced.contains($0.key) }
        // Everyone is shown in the universe on show; characters cast in another one take the same place in this one.
        // In Clawd Royale nobody is recast.
        let universe = s.shownUniverse, roster = s.roster
        let cast = roster.darkCast + roster.lightCast
        var used = Set(live.values.compactMap(\.leader).map(roster.adopt))
        var result: [SessionSnapshot] = []
        var previous: Int?
        // Spawn order, so "who came after whom" is meaningful.
        for (id, rec) in live.sorted(by: { ($0.value.created ?? $0.value.updated) < ($1.value.created ?? $1.value.updated) }) {
            var leader = rec.leader.map(roster.adopt) ?? -1
            if leader < 0 {   // records written before leaders existed
                leader = pickLeader(used: used, previous: previous, seed: stableHash(id), pool: cast, roster: roster)
                used.insert(leader)
            }
            previous = leader
            // The live cwd beats the hooks' copy: after a folder rename the hooks can report a stale path.
            let cwd = rec.pid.flatMap { ClaudeProcesses.cwd($0) }
            let git = cwd.flatMap { GitRemote.of($0, now: now) }
            result.append(SessionSnapshot(id: id, leader: leader,
                                          project: projectName(cwd: cwd, git: git) ?? rec.project ?? "",
                                          mood: mood(rec, id: id, now: now), agents: [], pid: rec.pid, record: rec,
                                          assistant: assistantOf(rec), cwd: cwd, remote: git?.host,
                                          client: rec.client ?? processes?.first { $0.pid == rec.pid }?.client))
        }
        if let processes {
            // Records from before pids were tracked are matched to a process by project folder.
            var claimed = Set(live.values.compactMap(\.pid))
            for rec in live.values where rec.pid == nil {
                if let p = processes.first(where: { !claimed.contains($0.pid) && $0.project == rec.project }) {
                    claimed.insert(p.pid)
                    if let i = result.firstIndex(where: { $0.project == rec.project && $0.pid == nil }) {
                        result[i].pid = p.pid
                    }
                }
            }
            for p in processes where !claimed.contains(p.pid) {
                // Seeded by pid so the same process keeps the same character across refreshes; Knuth's multiplicative
                // hash spreads nearby pids across the pool.
                let leader = pickLeader(used: used, previous: previous, seed: UInt64(p.pid) &* 2654435761, pool: cast, roster: roster)
                used.insert(leader)
                previous = leader
                let cwd = ClaudeProcesses.cwd(p.pid)
                let git = cwd.flatMap { GitRemote.of($0, now: now) }
                result.append(SessionSnapshot(id: "pid-\(p.pid)", leader: leader,
                                              project: projectName(cwd: cwd, git: git) ?? p.project,
                                              mood: .idle, agents: [], live: false, pid: p.pid,
                                              assistant: p.assistant, cwd: cwd, remote: git?.host, client: p.client))
            }
        }
        let agents = s.agents.filter { now - $0.lastSeen <= agentTTL && !replaced.contains($0.session) }.sorted { $0.started < $1.started }
        // No AI running: the stage stays empty. Only stray agents still reporting in get a placeholder (the universe's first villain) to stand with.
        if result.isEmpty && !agents.isEmpty {
            result.append(SessionSnapshot(id: "home", leader: universe.base, project: "", mood: .idle, agents: []))
        }
        for a in agents {
            // Agents whose session we never heard from stand with the first session's character.
            let i = result.firstIndex { $0.id == a.session } ?? 0
            result[i].agents.append(a)
        }
        // One guise at a time (`Universe.guises`), even when the casting couldn't see it coming (the universe switched
        // with sessions open): whoever comes later is shown as someone else, the same someone on every refresh.
        if !roster.guises.isEmpty {
            // Every leader counts as taken, later ones too, so a stand-in never doubles someone further along.
            let leaders = Set(result.map(\.leader))
            var shown = Set<Int>()
            for i in result.indices {
                let leader = result[i].leader
                if roster.ruledOut(by: shown).contains(leader) {
                    // Someone on the same side, so with two AIs running it stays on its AI's side.
                    result[i].leader = pickLeader(used: shown.union(leaders), previous: nil, seed: stableHash(result[i].id),
                                                  pool: isDark(leader) ? roster.darkCast : roster.lightCast,
                                                  roster: roster, ruledOut: roster.ruledOut(by: shown))
                }
                shown.insert(result[i].leader)
                for j in result[i].agents.indices {
                    let a = result[i].agents[j], id = roster.adopt(a.cast ?? heroBase + a.character)
                    let ruled = roster.ruledOut(by: shown)
                    if ruled.contains(id) {
                        let pool = (isDark(id) ? roster.darkCast : roster.lightCast).filter {
                            !ruled.contains($0) && !shown.contains($0) && !leaders.contains($0)
                        }
                        if !pool.isEmpty { result[i].agents[j].cast = pool[Int(stableHash(a.id) % UInt64(pool.count))] }
                    }
                    shown.insert(roster.adopt(result[i].agents[j].cast ?? heroBase + a.character))
                }
            }
        }
        // Nobody twice: an agent cast before the universe switched can land on someone already shown. It's shown as
        // someone free on the same side instead, the same someone on every refresh (repeats only when nobody's free).
        var seen = Set(result.map(\.leader))
        for i in result.indices {
            for j in result[i].agents.indices {
                let a = result[i].agents[j], id = roster.adopt(a.cast ?? heroBase + a.character)
                if seen.contains(id) {
                    let ruled = roster.ruledOut(by: seen)
                    let pool = (isDark(id) ? roster.darkCast : roster.lightCast).filter { !seen.contains($0) && !ruled.contains($0) }
                    if !pool.isEmpty { result[i].agents[j].cast = pool[Int(stableHash(a.id) % UInt64(pool.count))] }
                }
                seen.insert(roster.adopt(result[i].agents[j].cast ?? heroBase + a.character))
            }
        }
        return result
    }
}
