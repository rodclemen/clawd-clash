import Foundation

/// How near a session is to its next automatic compaction, for the pill on its card: 0…1 (1 = compacting), nil
/// when it can't be told. Where an AI says when it compacts, it's the share of the way there; where it doesn't
/// (Claude Code, Codex), the share of the context window. Logs are only re-read when they change.
/// - Claude Code: its transcript (`~/.claude/projects/<folder>/<session>.jsonl`) records each reply's token usage;
///   what the next request carries is the input plus the cache read and written. The window is 1M tokens for a
///   `[1m]` model (as the hooks record it, or as `~/.claude/settings.json` picks it when the hooks didn't say),
///   else 200k, and 1M anyway once a session has gone past 200k.
/// - Codex: its rollout (`~/.codex/sessions/YYYY/MM/DD/rollout-…-<session>.jsonl`) logs a `token_count` after each
///   turn with the last turn's tokens and the model's context window.
/// - Gemini CLI: its chat log (the hook's `transcript_path`, kept as `SessionRecord.transcript`) records each reply's
///   `tokens.input`; the window is 1,048,576 tokens (256k for Gemma), and it compacts at half of that.
/// - Qwen Code and pi: their hooks say it outright (`StatusStore.contextNearness`, kept as `SessionRecord.context`).
/// Copilot CLI only tells its status line, so its cards show no pill.
enum ContextUsage {
    private static var files: [String: URL] = [:]
    private static var cache: [String: (modified: Date, value: Double?)] = [:]

    /// Whether this Claude Code process is sure never to have been given a prompt: Claude Code writes down which session
    /// each process runs (`~/.claude/sessions/<pid>.json`), and a session's transcript only appears with its first prompt.
    /// That file isn't documented, so anything unexpected answers false and the caller goes by what else it knows.
    static func neverPrompted(claude pid: Int32) -> Bool {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/sessions/\(pid).json")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["sessionId"] as? String, !id.isEmpty else { return false }
        return file(for: id, assistant: "claude") == nil
    }

    static func fraction(session id: String, assistant: String, record: SessionRecord?) -> Double? {
        if assistant == "qwen" || assistant == "pi" { return record?.context }
        let model = record?.model
        let fm = FileManager.default
        guard let url = assistant == "gemini" ? record?.transcript.map({ URL(fileURLWithPath: $0) }) : file(for: id, assistant: assistant),
              let modified = (try? fm.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else { return nil }
        if let hit = cache[id], hit.modified == modified { return hit.value }
        let value: Double?
        switch assistant {
        case "claude": value = claude(url, model: model)
        case "codex": value = codex(url)
        case "gemini": value = gemini(url, model: model)
        default: value = nil
        }
        cache[id] = (modified, value)
        return value
    }

    /// The session's log, found once and remembered.
    private static func file(for id: String, assistant: String) -> URL? {
        if let f = files[id] { return f }
        let fm = FileManager.default, home = fm.homeDirectoryForCurrentUser
        var found: URL?
        switch assistant {
        case "claude":
            let root = home.appendingPathComponent(".claude/projects")
            for dir in (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
                let f = dir.appendingPathComponent(id + ".jsonl")
                if fm.fileExists(atPath: f.path) { found = f; break }
            }
        case "codex":
            // Newest days first: a running session's rollout is in today's folder, or a recent one.
            let root = home.appendingPathComponent(".codex/sessions")
            let suffix = "-" + id + ".jsonl"
            func sorted(_ u: URL) -> [URL] {
                ((try? fm.contentsOfDirectory(at: u, includingPropertiesForKeys: nil)) ?? []).sorted { $0.lastPathComponent > $1.lastPathComponent }
            }
            search: for year in sorted(root) { for month in sorted(year) { for day in sorted(month).prefix(40) {
                if let f = sorted(day).first(where: { $0.lastPathComponent.hasSuffix(suffix) }) { found = f; break search }
            } } }
        default: break
        }
        if let found { files[id] = found }
        return found
    }

    /// The JSON objects on the last lines of `url`, newest first: the last 256 KB, then up to 2 MB when a long tool
    /// result has pushed the last usage further back.
    private static func lastObjects(_ url: URL, where match: String) -> [[String: Any]] {
        guard let h = try? FileHandle(forReadingFrom: url) else { return [] }
        defer { try? h.close() }
        let size = (try? h.seekToEnd()) ?? 0
        for span in [UInt64(262_144), 2_097_152] {
            try? h.seek(toOffset: size > span ? size - span : 0)
            let data = h.readDataToEndOfFile()
            var out: [[String: Any]] = []
            for line in data.split(separator: UInt8(ascii: "\n")).reversed() where line.count < 4_000_000 {
                guard let text = String(data: line, encoding: .utf8), text.contains(match),
                      let obj = (try? JSONSerialization.jsonObject(with: Data(line))) as? [String: Any] else { continue }
                out.append(obj)
                if out.count >= 5 { return out }
            }
            if !out.isEmpty || size <= span { return out }
        }
        return []
    }

    /// Whether Claude Code's settings pick a 1M-token model by default (`"model": "opus[1m]"`), read once a minute.
    private static var settingsRead: (at: Date, big: Bool)?
    private static var defaultIs1M: Bool {
        if let s = settingsRead, Date().timeIntervalSince(s.at) < 60 { return s.big }
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/settings.json")
        let json = (try? Data(contentsOf: url)).flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
        let big = (json?["model"] as? String)?.contains("[1m]") ?? false
        settingsRead = (Date(), big)
        return big
    }

    private static func number(_ any: Any?) -> Double { (any as? NSNumber)?.doubleValue ?? 0 }

    private static func claude(_ url: URL, model: String?) -> Double? {
        // The newest reply in the main conversation (not an agent's side chain) that carries its usage.
        for obj in lastObjects(url, where: "\"usage\"") where (obj["isSidechain"] as? Bool) != true {
            guard let message = obj["message"] as? [String: Any], let usage = message["usage"] as? [String: Any] else { continue }
            let used = number(usage["input_tokens"]) + number(usage["cache_read_input_tokens"])
                + number(usage["cache_creation_input_tokens"]) + number(usage["output_tokens"])
            guard used > 0 else { continue }
            let big = (model ?? "").contains("[1m]") || defaultIs1M || used > 200_000
            return min(1, used / (big ? 1_000_000 : 200_000))
        }
        return nil
    }

    private static func gemini(_ url: URL, model: String?) -> Double? {
        // The newest reply with its tokens (a reply is written again once its tokens are in: the last copy wins).
        for obj in lastObjects(url, where: "\"tokens\"") where (obj["type"] as? String) == "gemini" {
            guard let tokens = obj["tokens"] as? [String: Any] else { continue }
            let used = number(tokens["input"])
            guard used > 0 else { continue }
            let name = (obj["model"] as? String ?? model ?? "").lowercased()
            let window: Double = name.contains("gemma") ? 256_000 : 1_048_576
            return min(1, used / (window * 0.5))
        }
        return nil
    }

    private static func codex(_ url: URL) -> Double? {
        for obj in lastObjects(url, where: "\"token_count\"") {
            let payload = obj["payload"] as? [String: Any] ?? obj
            guard let info = payload["info"] as? [String: Any],
                  let last = info["last_token_usage"] as? [String: Any] else { continue }
            let window = number(info["model_context_window"]), used = number(last["total_tokens"])
            guard window > 0, used > 0 else { continue }
            return min(1, used / window)
        }
        return nil
    }
}
