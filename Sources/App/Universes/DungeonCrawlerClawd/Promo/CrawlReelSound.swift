import AppKit

// The opening's and the set piece's sound: a game-show sting and the crawl tune, a bouncy chiptune in the spirit of a
// televised dungeon, our own notes, never anyone's theme. The tune runs without a break from the title to the hook, and
// every effect plays over it, never instead of it.

extension Mix {
    /// A game-show brass stab: two saws a hair apart and a square an octave down.
    func crawlBrass(_ t: Double, _ dur: Double, _ notes: [Int], vol: Double) {
        for n in notes {
            tone(t, dur, midi(n) * 0.997, wave: .saw, vol: vol * 0.5, attack: 0.012, release: 0.14)
            tone(t, dur, midi(n) * 1.003, wave: .saw, vol: vol * 0.5, attack: 0.012, release: 0.14)
            tone(t, dur, midi(n - 12), wave: .square(0.3), vol: vol * 0.22, attack: 0.012, release: 0.14)
        }
    }
    /// Rain: a soft hiss, with a darker bed under it.
    func crawlRain(_ t: Double, _ dur: Double, vol: Double) {
        noise(t, dur, vol: vol, cutoff: 0.7, attack: 0.3, release: 0.8, highpass: true, seed: 41)
        noise(t, dur, vol: vol * 0.7, cutoff: 0.08, attack: 0.3, release: 0.8, seed: 43)
    }
    /// A studio audience, polite.
    func crawlApplause(_ t: Double, _ dur: Double, vol: Double) {
        noise(t, dur, vol: vol, cutoff: 0.5, attack: 0.25, release: 0.7, highpass: true, seed: 77)
        for i in 0..<Int(dur * 16) { noise(t + Double(i) / 16 + hashNoise(i) * 0.05, 0.02, vol: vol * 1.4, cutoff: 0.7, decay: 0.008, seed: i) }
    }
    /// Mongo: a rising screech with a rasp on it.
    func crawlScreech(_ t: Double, vol: Double = 0.08) {
        tone(t, 0.42, 1100, to: 2400, wave: .saw, vol: vol, attack: 0.01, release: 0.1, vibrato: 0.03)
        noise(t, 0.42, vol: vol * 0.5, cutoff: 0.8, release: 0.1, highpass: true, seed: 91)
    }
    /// A loot box rattling, then its lid going.
    func crawlRattle(_ t: Double, vol: Double = 0.1) {
        for i in 0..<9 { noise(t + Double(i) * 0.055, 0.03, vol: vol, cutoff: 0.5, decay: 0.012, seed: 60 + i) }
        ping(t + 0.55, vol: 0.1)
    }
}

// MARK: The crawl tune

/// The tune's chords, a bar each: Dm, B♭, C, A, our own four.
private let crawlChords: [[Int]] = [[62, 65, 69], [58, 62, 65], [60, 64, 67], [61, 64, 69]]
/// Its melody, a bar to each chord: (beat in the bar, beats long, note).
private let crawlTune: [[(Double, Double, Int)]] = [
    [(0, 0.5, 74), (0.5, 0.5, 77), (1, 0.5, 81), (1.5, 0.5, 77), (2, 1, 79), (3, 0.5, 77), (3.5, 0.5, 76)],
    [(0, 1, 74), (1, 0.5, 77), (1.5, 0.5, 74), (2, 1.5, 70), (3.5, 0.5, 72)],
    [(0, 0.5, 76), (0.5, 0.5, 79), (1, 0.5, 84), (1.5, 0.5, 79), (2, 1, 81), (3, 0.5, 79), (3.5, 0.5, 76)],
    [(0, 1, 73), (1, 0.5, 76), (1.5, 0.5, 79), (2, 2, 81)],
]
private let crawlBeat = 0.45, crawlBar = 1.8
/// Where its first bar starts (the title), and so where every bar starts: the boss room's comes in on the Dm, the
/// tune's top, and the last bar's A leads into the groove's Am at the hook.
let crawlTuneAt = 3.3

/// How a bar of the tune is played: how loud, how busy the drums, and whether the lead or the brass carries it.
private enum CrawlBar { case title, fall, show, sofa, boss, fanfare }

/// One bar of the tune from `t0`: the bass bouncing in octaves, the drums for its kind, the arpeggio in the boss bars,
/// and the melody on a square lead (or on brass for the fanfare).
private func crawlTuneBar(_ m: Mix, _ t0: Double, chord c: Int, _ kind: CrawlBar) {
    let chord = crawlChords[c], root = chord[0] - 24, beat = crawlBeat
    let loud: Double = [.title: 0.7, .fall: 0.85, .sofa: 0.8][kind] ?? 1
    for e in 0..<8 {
        m.tone(t0 + Double(e) * beat / 2, beat / 2 * 0.85, midi(root + (e % 2) * 12), wave: .square(0.25), vol: 0.07 * loud, release: 0.02)
    }
    switch kind {
    case .title:
        m.crawlBrass(t0, crawlBar * 0.95, chord, vol: 0.045)
    case .fall:
        for e in 0..<8 { m.hat(t0 + Double(e) * beat / 2, vol: 0.025) }
        m.kick(t0, vol: 0.18)
        for k in 0..<8 { m.snare(t0 + 2 * beat + Double(k) * beat / 4, vol: 0.03 + Double(k) * 0.008) }
    case .sofa, .show:
        for b in 0..<4 { m.hat(t0 + Double(b) * beat + beat / 2, vol: 0.035) }
        m.kick(t0, vol: 0.18); m.kick(t0 + 2 * beat, vol: 0.15)
        m.snare(t0 + beat, vol: 0.06); m.snare(t0 + 3 * beat, vol: 0.06)
        // The game-show offbeat: a little chord stab after every beat.
        for b in 0..<4 { for n in chord { m.tone(t0 + Double(b) * beat + beat / 2, beat * 0.3, midi(n), wave: .triangle, vol: 0.022 * loud, release: 0.03) } }
    case .boss, .fanfare:
        m.kick(t0, vol: 0.22); m.kick(t0 + 2 * beat, vol: 0.2); m.kick(t0 + 2.5 * beat, vol: 0.16)
        m.snare(t0 + beat, vol: 0.1); m.snare(t0 + 3 * beat, vol: 0.1)
        for k in 0..<16 { m.hat(t0 + Double(k) * beat / 4, vol: k % 2 == 0 ? 0.03 : 0.018) }
        // The fanfare's last beat: a snare fill into the big finish.
        if kind == .fanfare { for k in 0..<4 { m.snare(t0 + 3 * beat + Double(k) * beat / 4, vol: 0.07 + Double(k) * 0.015) } }
        for k in 0..<16 { m.tone(t0 + Double(k) * beat / 4, beat / 4 * 0.8, midi(chord[k % 3] + (k / 3 % 2) * 12), wave: .triangle, vol: 0.026, release: 0.02) }
    }
    guard kind != .title else { return }
    for (at, len, n) in crawlTune[c] {
        let t = t0 + at * beat, d = len * beat * 0.92
        if kind == .fanfare {
            m.crawlBrass(t, d, [n - 12, n - 5, n], vol: 0.03)
        } else {
            m.tone(t, d, midi(n), wave: .square(0.5), vol: 0.05 * loud, release: 0.04, vibrato: len >= 1 ? 0.006 : 0.002)
            if kind == .boss { m.tone(t, d, midi(n - 12), wave: .saw, vol: 0.025, release: 0.04) }
        }
    }
}

/// The tune, from the title to the boss's fall: eight bars, each played for what's on screen under it, then the big
/// finish on the next downbeat, a bright D major hit that has died away before the hook, so the groove starts after
/// a breath of quiet instead of cutting in.
private func crawlTuneScore(_ m: Mix) {
    let bars: [CrawlBar] = [.title, .fall, .show, .sofa, .sofa, .boss, .boss, .fanfare]
    for (b, kind) in bars.enumerated() {
        crawlTuneBar(m, crawlTuneAt + Double(b) * crawlBar, chord: (b + 3) % 4, kind)
    }
    let end = crawlTuneAt + Double(bars.count) * crawlBar
    m.crawlBrass(end, 0.22, [62, 66, 69, 74], vol: 0.05)
    m.tone(end, 0.3, midi(38), wave: .square(0.25), vol: 0.09, release: 0.15)
    m.kick(end, vol: 0.24)
    m.noise(end, 0.5, vol: 0.1, cutoff: 0.9, decay: 0.18, highpass: true, seed: 57)
    for (i, n) in [74, 78, 81, 86, 90, 93, 98].enumerated() { m.tone(end + Double(i) * 0.03, 0.18, midi(n), wave: .sine, vol: 0.04, release: 0.15) }
}

/// The opening (0 to 9 s) and the boss fight (9 to 18.5 s): the tune under all of it, and the effects over it. The
/// Collapse's own moments, in the trailer's seconds: the box lands at 2.2, the title at 3.3, the floor goes at 4.8,
/// they land at 6.1.
func crawlOpeningSound(_ m: Mix) {
    crawlTuneScore(m)
    // The street: rain and a rumble growing as the ground cracks.
    m.crawlRain(0, 5.2, vol: 0.05)
    m.noise(0.6, 1.7, vol: 0.12, cutoff: 0.03, attack: 0.9, release: 0.3, seed: 12)
    // WELCOME, CRAWLER!: the slam and the sting, F, G, then the title's A.
    m.boom(2.2, vol: 0.4)
    m.crawlBrass(2.2, 0.28, [53, 60, 65, 69], vol: 0.05)
    m.crawlBrass(2.55, 0.2, [55, 62, 67, 71], vol: 0.05)
    m.crawlBrass(2.8, 0.42, [55, 62, 67, 71], vol: 0.055)
    // The title: a glittering run up over the tune's first chord.
    for (i, n) in [69, 73, 76, 81, 85, 88, 93].enumerated() { m.tone(3.3 + Double(i) * 0.05, 0.26, midi(n), wave: .sine, vol: 0.05, release: 0.2) }
    // The fall: a rush of air and a whistle sliding down, then the landing, and the System naming the place.
    m.whoosh(5.4, 1.5, vol: 0.2)
    m.tone(4.8, 1.3, 1500, to: 240, wave: .sine, vol: 0.04, release: 0.1)
    m.boom(6.1, vol: 0.34)
    m.ping(6.5)

    // The sofa: an audience, then the trapdoor's clunk and the drop.
    let b = 9.0
    m.crawlApplause(b + 0.1, 2.4, vol: 0.05)
    m.boom(b + 2.6, vol: 0.2)
    m.step(b + 2.6, vol: 0.2)
    m.tone(b + 2.65, 0.8, 1300, to: 200, wave: .sine, vol: 0.05, release: 0.08)
    // The boss room: Magic Missiles and Mongo's screech over the tune.
    let go = b + 3.4, stop = b + 7.2
    for s in stride(from: go + 0.5, to: stop - 0.3, by: 0.62) { m.pew(s, vol: 0.06) }
    m.crawlScreech(go + 1.4)
    // BOSS DEFEATED: he goes down, the tune's fanfare bar carries on, and the rattle, its ping before the big finish.
    m.boom(stop + 0.1, vol: 0.4)
    m.crawlRattle(stop + 0.7)
}
