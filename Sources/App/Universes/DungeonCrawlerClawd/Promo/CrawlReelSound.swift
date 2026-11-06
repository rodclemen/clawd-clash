import AppKit

// The opening's and the set piece's sound: a game-show sting and a chiptune pulse in the spirit of a televised dungeon,
// our own notes, never anyone's theme.

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
    /// The chiptune pulse: an octave-bouncing square bass in sixteenths, walking through `roots`, a bar each.
    func crawlPulse(_ from: Double, _ to: Double, roots: [Int], beat: Double, vol: Double) {
        var i = 0, t = from
        while t < to {
            let root = roots[(i / 16) % roots.count]
            tone(t, beat / 4 * 0.8, midi(root + (i % 2 == 0 ? 0 : 12)), wave: .square(0.25), vol: vol, release: 0.02)
            t += beat / 4; i += 1
        }
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

/// The opening (0 to 9 s) and the boss fight (9 to 18.5 s). The Collapse's own moments, in the trailer's seconds: the
/// box lands at 2.2, the title at 3.3, the floor goes at 4.8, they land at 6.1.
func crawlOpeningSound(_ m: Mix) {
    // The street: rain and a rumble growing as the ground cracks.
    m.crawlRain(0, 5.2, vol: 0.05)
    m.noise(0.6, 1.7, vol: 0.12, cutoff: 0.03, attack: 0.9, release: 0.3, seed: 12)
    // WELCOME, CRAWLER!: the slam and the sting.
    m.boom(2.2, vol: 0.4)
    m.crawlBrass(2.2, 0.28, [58, 65, 70, 74], vol: 0.05)
    m.crawlBrass(2.55, 0.2, [60, 67, 72, 76], vol: 0.05)
    m.crawlBrass(2.8, 0.42, [63, 70, 75, 79], vol: 0.055)
    // The title: a glittering run up, a held chord, and the pulse starting under it.
    for (i, n) in [72, 76, 79, 84, 88, 91, 96].enumerated() { m.tone(3.3 + Double(i) * 0.05, 0.26, midi(n), wave: .sine, vol: 0.05, release: 0.2) }
    m.crawlBrass(3.3, 1.3, [58, 62, 65, 70], vol: 0.05)
    m.crawlPulse(3.3, 6.1, roots: [34, 37], beat: 0.42, vol: 0.05)
    // The fall: a rush of air and a whistle sliding down, then the landing, and the System naming the place.
    m.whoosh(5.4, 1.5, vol: 0.2)
    m.tone(4.8, 1.3, 1500, to: 240, wave: .sine, vol: 0.04, release: 0.1)
    m.boom(6.1, vol: 0.34)
    m.ping(6.5)
    m.crawlPulse(6.5, 9.0, roots: [34], beat: 0.5, vol: 0.022)

    // The sofa: an audience, a soft pad, then the trapdoor's clunk and the drop.
    let b = 9.0
    m.crawlApplause(b + 0.1, 2.4, vol: 0.05)
    m.boom(b + 2.6, vol: 0.2)
    m.step(b + 2.6, vol: 0.2)
    m.tone(b + 2.65, 0.8, 1300, to: 200, wave: .sine, vol: 0.05, release: 0.08)
    // The boss room: a minor riff with a kick, a snare and hats at a fast walk.
    let beat = 0.4, go = b + 3.4, stop = b + 7.2
    var t = go; var i = 0
    while t < stop {
        if i % 2 == 0 { m.kick(t, vol: 0.2) } else { m.snare(t, vol: 0.09) }
        m.hat(t + beat / 2, vol: 0.03)
        t += beat; i += 1
    }
    m.crawlPulse(go, stop, roots: [33, 33, 36, 31], beat: beat * 2, vol: 0.05)
    let riff = [69, 72, 76, 75, 72, 69, 67, 69]
    for k in 0..<Int((stop - go) / (beat / 2 * 2)) {
        m.tone(go + Double(k) * beat, beat * 0.85, midi(riff[k % riff.count]), wave: .square(0.25), vol: 0.035, release: 0.05)
    }
    for s in stride(from: go + 0.5, to: stop - 0.3, by: 0.62) { m.pew(s, vol: 0.06) }
    m.crawlScreech(go + 1.4)
    // BOSS DEFEATED: he goes down, the fanfare, the rattle, and a sad little note for Mongo.
    m.boom(stop + 0.1, vol: 0.4)
    m.crawlBrass(stop + 0.55, 0.16, [65, 69, 72], vol: 0.05)
    m.crawlBrass(stop + 0.73, 0.16, [65, 69, 72], vol: 0.05)
    m.crawlBrass(stop + 0.91, 0.7, [70, 74, 77], vol: 0.055)
    m.crawlRattle(stop + 1.25)
}
