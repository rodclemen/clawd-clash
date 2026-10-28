import AppKit

// The trailer's score and effects. Music in the spirit of the 80s cartoon, a brassy, heroic synth march with a
// snare-drum tread, but our own notes, never the theme's: a thunderclap on the lightning, a sword shing as the title
// lands, Skeleclawd's cackle as pitched-down blips, and a bright fanfare sting on the end card.

// MARK: Instruments

extension Mix {
    /// A synth-brass note: two saws a hair apart and a square an octave down, a quick bite and a short tail.
    func eterniaBrass(_ t: Double, _ dur: Double, _ n: Int, vol: Double, attack: Double = 0.02, release: Double = 0.12) {
        tone(t, dur, midi(n) * 0.997, wave: .saw, vol: vol * 0.5, attack: attack, release: release, vibrato: 0.004)
        tone(t, dur, midi(n) * 1.003, wave: .saw, vol: vol * 0.5, attack: attack, release: release, vibrato: 0.004)
        tone(t, dur, midi(n - 12), wave: .square(0.3), vol: vol * 0.25, attack: attack, release: release)
    }
    /// A brass chord: every note of it.
    func eterniaChord(_ t: Double, _ dur: Double, _ notes: [Int], vol: Double, attack: Double = 0.02, release: Double = 0.15) {
        for n in notes { eterniaBrass(t, dur, n, vol: vol, attack: attack, release: release) }
    }
    /// The march's lead: a bright square over a saw, a little vibrato on the held notes.
    func eterniaLead(_ t: Double, _ dur: Double, _ n: Int, vol: Double) {
        let held = dur > 0.5
        tone(t, dur, midi(n), wave: .square(0.25), vol: vol * 0.6, attack: 0.015, release: 0.08, vibrato: held ? 0.01 : 0.003)
        tone(t, dur, midi(n) * 1.002, wave: .saw, vol: vol * 0.4, attack: 0.015, release: 0.08, vibrato: held ? 0.01 : 0.003)
    }
    /// A sword drawn or glinting: a bright metallic ring sliding up, over a hiss.
    func eterniaShing(_ t: Double, vol: Double = 0.08) {
        noise(t, 0.35, vol: vol * 0.8, cutoff: 0.9, decay: 0.12, highpass: true, seed: Int(t * 131))
        tone(t, 0.7, 2600, to: 3300, wave: .sine, vol: vol, attack: 0.005, release: 0.4, vibrato: 0.006)
        tone(t, 0.6, 3950, to: 4400, wave: .sine, vol: vol * 0.5, attack: 0.005, release: 0.35)
    }
    /// A thunderclap: the crack, then the boom and a long rumble.
    func eterniaThunder(_ t: Double, vol: Double = 0.3) {
        noise(t, 0.3, vol: vol * 0.9, cutoff: 0.95, decay: 0.07, highpass: true, seed: Int(t * 97))
        boom(t + 0.04, vol: vol * 1.4)
        noise(t + 0.1, 2.4, vol: vol * 0.45, cutoff: 0.03, cutoffTo: 0.008, attack: 0.05, release: 1.6, seed: Int(t * 53))
    }
    /// Skeleclawd's cackle, pitched down: four nasal blips falling, and a last one sliding away.
    func eterniaCackle(_ t: Double, vol: Double = 0.07) {
        for (i, f) in [262.0, 233.0, 220.0, 196.0].enumerated() {
            tone(t + Double(i) * 0.13, 0.09, f, to: f * 0.94, wave: .square(0.2), vol: vol, attack: 0.005, release: 0.03, vibrato: 0.05)
        }
        tone(t + 0.55, 0.35, 185, to: 120, wave: .square(0.2), vol: vol, attack: 0.005, release: 0.12, vibrato: 0.06)
    }
    /// A purple puff: a soft burst of breath.
    func eterniaPoof(_ t: Double, vol: Double = 0.12) {
        noise(t, 0.5, vol: vol, cutoff: 0.25, cutoffTo: 0.05, attack: 0.01, release: 0.3, seed: Int(t * 71))
        tone(t, 0.3, 500, to: 180, wave: .sine, vol: vol * 0.4, release: 0.15)
    }
}

// MARK: The march

/// The march's chords, a bar each: root position triads, our own progression.
private let marchChords: [[Int]] = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [53, 57, 60], [58, 62, 65], [55, 59, 62], [60, 64, 67]]
/// The march's tune, our own notes: (beat in the bar, beats long, note), a bar to a row.
private let marchTune: [[(Double, Double, Int)]] = [
    [(0, 1.5, 72), (1.5, 0.5, 67), (2, 1, 72), (3, 1, 76)],
    [(0, 1.5, 74), (1.5, 0.5, 72), (2, 2, 69)],
    [(0, 1.5, 77), (1.5, 0.5, 76), (2, 1, 74), (3, 1, 72)],
    [(0, 3, 79), (3, 0.5, 74), (3.5, 0.5, 76)],
    [(0, 1.5, 81), (1.5, 0.5, 79), (2, 1, 77), (3, 1, 76)],
    [(0, 1.5, 74), (1.5, 0.5, 76), (2, 2, 77)],
    [(0, 1, 76), (1, 1, 72), (2, 1, 74), (3, 1, 71)],
    [(0, 4, 72)],
]
private let beat = 0.45, bar = 1.8

/// The march's drums, from `t0` for `bars` bars: the kick on one and three, the snare's tread with a roll into every
/// other bar.
private func marchDrums(_ m: Mix, from t0: Double, bars: Int, vol: Double = 1) {
    for b in 0..<bars {
        let s = t0 + Double(b) * bar
        m.kick(s, vol: 0.22 * vol); m.kick(s + 2 * beat, vol: 0.18 * vol)
        for k in 0..<4 { m.snare(s + Double(k) * beat + beat / 2, vol: 0.05 * vol) }
        m.snare(s + beat, vol: 0.08 * vol); m.snare(s + 3 * beat, vol: 0.08 * vol)
        if b % 2 == 1 { for k in 0..<4 { m.snare(s + 3 * beat + Double(k) * beat / 4, vol: (0.04 + 0.015 * Double(k)) * vol) } }
        for k in 0..<8 { m.hat(s + Double(k) * beat / 2, vol: 0.02 * vol) }
    }
}

/// The march itself from `t0`: tune bars `from..<to`, with the brass stabbing the chords and the bass walking.
private func march(_ m: Mix, at t0: Double, bars range: Range<Int>, vol: Double = 1, tune: Bool = true) {
    for (i, b) in range.enumerated() {
        let s = t0 + Double(i) * bar
        let chord = marchChords[b % marchChords.count]
        for (at, len) in [(0.0, 0.9), (1.5, 0.4), (2.0, 0.9), (3.5, 0.4)] {
            m.eterniaChord(s + at * beat, len * beat, chord, vol: 0.022 * vol)
        }
        let root = chord[0] - 24
        for k in 0..<4 {
            let n = k % 2 == 0 ? root : root + 7
            m.tone(s + Double(k) * beat, beat * 0.8, midi(n), wave: .triangle, vol: 0.13 * vol, release: 0.05, decay: 0.2)
        }
        guard tune else { continue }
        for (at, len, n) in marchTune[b % marchTune.count] { m.eterniaLead(s + at * beat, len * beat * 0.95, n, vol: 0.075 * vol) }
    }
}

/// The villains' version under the raid: the bass in C minor, a low brass growl, no tune.
private func raid(_ m: Mix, at t0: Double, bars: Int) {
    let roots = [36, 36, 39, 34]
    for b in 0..<bars {
        let s = t0 + Double(b) * bar, r = roots[b % roots.count]
        for k in 0..<8 {
            let n = k % 4 == 3 ? r + 6 : r
            m.tone(s + Double(k) * beat / 2, beat * 0.4, midi(n), wave: .saw, vol: 0.1, release: 0.04, decay: 0.12)
        }
        m.eterniaChord(s, bar * 0.9, [r + 12, r + 15, r + 19], vol: 0.026, attack: 0.3, release: 0.4)
    }
}

// MARK: The score

/// The score and effects.
func eterniaSound(_ m: Mix) {
    // The title sequence: wind in the chasm, Cringer's paws, the sword drawn, a swell into the lightning.
    let i0 = start("intro")
    m.noise(i0, eterniaThunderAt + 0.2, vol: 0.05, cutoff: 0.02, cutoffTo: 0.05, attack: 1.2, release: 0.5, seed: 3)
    m.eterniaChord(i0 + 0.3, eterniaSwordUpAt, [48, 55], vol: 0.03, attack: 1.8, release: 0.6)
    for k in 0..<12 { m.step(i0 + 0.15 + Double(k) * 0.2, vol: 0.06) }
    m.tone(i0 + 2.45, 0.25, 900, to: 700, wave: .triangle, vol: 0.04, attack: 0.02, release: 0.1, vibrato: 0.08)   // Cringer's whimper
    m.tone(i0 + 2.75, 0.3, 820, to: 600, wave: .triangle, vol: 0.035, attack: 0.02, release: 0.1, vibrato: 0.08)
    m.eterniaShing(i0 + eterniaSwordUpAt, vol: 0.09)
    let swell = i0 + eterniaSwordUpAt + 0.1
    m.eterniaChord(swell, eterniaThunderAt - eterniaSwordUpAt + 0.2, [55, 60, 64], vol: 0.035, attack: 1.2, release: 0.2)
    for k in 0..<Int((eterniaThunderAt - eterniaSwordUpAt) / 0.075) {
        m.snare(swell + Double(k) * 0.075, vol: 0.02 + 0.05 * Double(k) / 26)
    }
    m.whoosh(i0 + 4.3, 0.6, vol: 0.08)
    m.eterniaThunder(i0 + eterniaThunderAt, vol: 0.32)
    m.crackle(i0 + eterniaThunderAt + 0.1, eterniaHeStandsAt - eterniaThunderAt - 0.2, vol: 0.05)
    m.eterniaChord(i0 + eterniaThunderAt, eterniaHeStandsAt - eterniaThunderAt, [48, 55, 60, 64], vol: 0.03, attack: 0.05, release: 0.3)
    m.noise(i0 + eterniaHeStandsAt - 0.9, 0.9, vol: 0.08, cutoff: 0.1, cutoffTo: 0.9, attack: 0.8, release: 0.05, seed: 7)
    // He-Clawd stands: the big hit, Battle Kat's roar, a fanfare up into the title and its shing, then the plunge.
    let he = i0 + eterniaHeStandsAt
    m.boom(he, vol: 0.4)
    m.eterniaChord(he, 1.1, [48, 55, 60, 64, 67], vol: 0.04, attack: 0.01, release: 0.4)
    m.roar(he + 0.1, 0.9, vol: 0.16)
    for (i, n) in [67, 72, 76].enumerated() { m.eterniaLead(he + 0.5 + Double(i) * 0.15, 0.14, n, vol: 0.08) }
    m.eterniaLead(he + 0.95, 1.0, 79, vol: 0.08)
    m.eterniaChord(he + 0.95, 1.2, [55, 60, 64, 67], vol: 0.035, release: 0.4)
    marchDrums(m, from: he, bars: 1, vol: 0.8)
    m.eterniaShing(i0 + eterniaTitleShingAt, vol: 0.1)
    m.whoosh(i0 + eterniaPlungeAt + 0.4, 1.0, vol: 0.16)
    m.tone(i0 + eterniaPlungeAt, 0.8, 200, to: 2400, wave: .saw, vol: 0.04, attack: 0.3, release: 0.1)

    // The set piece: the raid in C minor, the Roton's rumble and Skeleclawd's cackle.
    let s0 = start("siege")
    raid(m, at: s0, bars: 3)
    m.noise(s0, eterniaSiegePullUp, vol: 0.06, cutoff: 0.02, attack: 0.2, release: 0.2, seed: 21)
    m.tone(s0, eterniaSiegePullUp, 48, to: 52, wave: .saw, vol: 0.05, attack: 0.2, release: 0.2, vibrato: 0.04)
    m.eterniaCackle(s0 + 0.6, vol: 0.08)
    m.whoosh(s0 + eterniaSiegeCut, 0.4, vol: 0.06)
    m.noise(s0 + eterniaSiegePullUp - 0.3, 0.4, vol: 0.06, cutoff: 0.6, cutoffTo: 0.1, release: 0.1, highpass: true, seed: 31)
    m.clunk(s0 + eterniaSiegePullUp, vol: 0.12)
    m.eterniaChord(s0 + eterniaSiegeStaff, 0.8, [48, 51, 54], vol: 0.04, release: 0.3)
    m.crackle(s0 + eterniaSiegeStaff, 0.8, vol: 0.04)
    m.shimmer(s0 + eterniaSiegeOrkko, 0.5, vol: 0.05)
    m.slideWhistle(s0 + eterniaSiegeOops, up: false, vol: 0.06)
    m.rain(s0 + eterniaSiegeRain.0, eterniaSiegeRain.1 - eterniaSiegeRain.0, vol: 0.06)
    // The rescue: the march comes back in, a whoosh for the leap, a heave and the big hit as the Roton goes up.
    m.whoosh(s0 + eterniaSiegeLeap + 0.3, 0.7, vol: 0.14)
    march(m, at: s0 + eterniaSiegeLeap, bars: 2..<5, vol: 0.9)
    marchDrums(m, from: s0 + eterniaSiegeLeap, bars: 3)
    m.tone(s0 + eterniaSiegeLift, 0.45, 70, to: 140, wave: .saw, vol: 0.06, attack: 0.05, release: 0.1)
    m.boom(s0 + eterniaSiegeLift + 0.45, vol: 0.35)
    for k in 0..<10 { m.step(s0 + eterniaSiegeScatter + Double(k) * 0.1, vol: 0.06) }
    m.eterniaPoof(s0 + eterniaSiegePuff)
    m.eterniaCackle(s0 + eterniaSiegePuff + 0.1, vol: 0.04)
    for (i, n) in [84, 88, 91].enumerated() {                   // a little chime for the moral
        m.tone(s0 + eterniaSiegeMoral + 0.2 + Double(i) * 0.12, 0.6, midi(n), wave: .sine, vol: 0.05, release: 0.4)
    }

    // The app shots: the shared groove, and each shot's effects.
    groove(m, from: start("hook"), to: start("endcard"), fadeIn: 1.2)
    let hook = start("hook")
    for i in 0..<26 { m.click(hook + 0.2 + Double(i) * 0.13 + noise(i) * 0.06) }
    let desk = start("desktop"), deskEnd = end("desktop") + 1.3
    for (i, d) in [0.0, 0.12, 0.24, 0.32].enumerated() { m.step(desk + d + 0.3, vol: 0.1 + Double(i % 2) * 0.03) }
    for t in clashTimes(desk + 0.45, deskEnd) { m.clash(t, vol: 0.08) }
    m.crackle(desk + 0.5, deskEnd - desk - 0.5, vol: 0.02)
    let st = start("status")
    for i in 0..<4 { m.pop(st + 0.1 + Double(i) * 0.22, step: i) }
    for k in 0..<5 { m.tone(st + 1.2 + Double(k) * 0.62, 0.08, 1568, wave: .square(0.5), vol: 0.035, release: 0.03) }
    let ag = start("agents")
    for k in 0..<14 { m.step(ag + Double(k) * 0.125, vol: 0.06) }
    let wi = start("window")
    m.ping(wi + 2.5)
    let ais = start("ais")
    for i in 0..<6 { m.pop(ais + 0.15 + Double(i) * 0.1, step: i % 4) }
    m.crackle(ais + 0.4, end("ais") - ais, vol: 0.02)
    for s in shots { transitionSound(m, s) }

    // The end card: a bright brass fanfare sting as the title lands, the last chord ringing out over thunder.
    let ec = start("endcard")
    for (i, n) in [67, 72, 76].enumerated() { m.eterniaLead(ec + 0.1 + Double(i) * 0.12, 0.11, n, vol: 0.08) }
    m.eterniaLead(ec + 0.46, 0.3, 79, vol: 0.08)
    m.eterniaChord(ec + 0.46, 0.3, [55, 60, 64], vol: 0.04)
    m.eterniaLead(ec + 0.8, 2.6, 84, vol: 0.085)
    m.eterniaChord(ec + 0.8, 2.6, [48, 55, 60, 64, 67, 72], vol: 0.04, release: 1.4)
    m.boom(ec + 0.8, vol: 0.45)
    m.eterniaShing(ec + 1.1, vol: 0.08)
    m.noise(ec + 1.2, 2.6, vol: 0.06, cutoff: 0.03, cutoffTo: 0.01, attack: 0.2, release: 1.6, seed: 77)
}
