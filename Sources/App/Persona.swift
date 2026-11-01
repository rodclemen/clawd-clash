import Foundation

// How every character in every universe is described: what it fights with, how it moves, what its shots and magic
// look like, and its drawing function. A universe registers one `Persona` per character in its art files.

/// How a character fights. The cases keep Clawd Wars' names; across the universes they mean:
/// - `saber`: up close, shields, hammers, claws, fists, swords, staffs. Deflects shots, blocks magic.
/// - `blaster`: at range, repulsors, webs, arrows, bullets, optic blasts, fire, ice… (`Persona.shot` says which).
/// - `lightning`: magic and energy streams, sorcery, telekinesis, Thanos' gauntlet (`Persona.magic` says how it looks).
/// - `none`: stays out of it.
enum Weapon { case saber, blaster, lightning, none }

/// How a character gets about when it moves along the line.
enum Motion {
    case walk
    case fly       // takes off to travel and lands where it's going (Iron Man, Thor, Captain Marvel…)
    case hover     // never quite touches the ground (Doctor Strange, Magneto, MODOK…)
    case swing     // swings on a web line (Spider-Man)
}

/// What a ranged character's shots look like.
enum ShotStyle {
    case energy(core: Px, glow: Px)   // a glowing streak: repulsors, photon blasts, Hydra rifles
    case beam(core: Px, glow: Px)     // a continuous ray from the muzzle: Cyclops, Sentinels
    case bullet                       // a small hot tracer
    case arrow                        // a feathered arrow
    case web                          // a web line with a blob on the end
    case fire                         // a fireball
    case ice                          // a frosty stream
    case card                         // a glowing playing card (Gambit)
    case thrown(Px)                   // something spinning: knives, pumpkin bombs, shuriken
}

/// A signature move that climbs a thread (`Persona.climb`): where the thread leaves the body (canvas pixels, facing
/// right), and at each point `p` (0…1) of the move how far the body has risen (canvas pixels), how visible it is
/// (0…1), and how much of the thread is out (0…1 of the way from the body to the top of the screen).
struct Climb {
    var from: (x: Double, y: Double)
    var rise: (Double) -> Double
    var alpha: (Double) -> Double
    var thread: (Double) -> Double
}

/// What a magic or energy stream looks like.
struct Magic {
    var core: Px
    var glow: Px
    var jagged = true                 // forked like lightning; false: a steady, wavering ray
    var rings = false                 // mind powers: rings rippling out along a faint ray (with jagged false)
    var waves = false                 // sound and force: arcs pulsing out towards the target (with jagged false)
    var spell = false                 // sorcery: a twinkling ribbon of sparkles (with jagged false)
    var rcCar = false                 // a little remote-controlled car racing at the target on two trails of fire
    var notes = false                 // music: big arcs in a heartbeat rhythm, a note riding behind each
    var touch = false                 // no stream at all: a glowing fingertip, and a glow round whoever it's pointed at
    var grip = false                  // telekinesis that holds: no stream; whoever it's aimed at is hauled off the ground,
                                      // kicking, a haze squeezing round them, then dropped (Supernatural's Abaddon)
    /// Small differences in its drawing (forks, kinks, thickness, speed…) so no two characters' magic looks the same.
    /// Filled in by `Theme.persona`, from `magicVariants`.
    var variant = 0
    /// Lightning: how many bolts, where a character's look needs a set number; nil leaves it to the variant.
    var bolts: Int?
    /// A steady ray drawn at its thickest, whatever the variant (a ray that burns, rather than a beam).
    var thick = false
    /// Not a stream it can fire into the sky or open as a portal: a gadget, a touch or a grip.
    var gadget: Bool { touch || rcCar || grip }
    /// How far short of the frame's edge a stream practised at nobody must stop, so what lands isn't cut in half.
    var landing: Double { notes ? 11 : rings || waves ? 7 : 0 }
    /// Which family of looks it belongs to; variants are numbered within each.
    var family: Int { grip ? 8 : touch ? 6 : rcCar ? 5 : notes ? 7 : rings ? 1 : waves ? 2 : spell ? 3 : jagged ? 0 : 4 }
    static let lightning = Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF))
}

/// One character: who it is and how it's drawn. Registered in an Art/*.swift file next to its drawing function.
struct Persona {
    let name: String
    var weapon: Weapon = .none
    var motion: Motion = .walk
    /// Ranged characters: what the shots look like.
    var shot: ShotStyle = .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A))
    /// Magic characters: what the stream looks like.
    var magic: Magic = .lightning
    /// Shots ricochet off it (armour, metal, rock).
    var armoured = false
    /// Sits down when its session has been idle a while.
    var canSit = true
    /// Where shots leave from, canvas pixels, facing right.
    var muzzle: (x: Double, y: Double) = (52, 32)
    /// More than one way to shoot (the Reminiscence Hydra's heads): each shot takes the next of these in turn, its look
    /// and where it leaves from, in place of `shot` and `muzzle`. The art can ask which one is firing (`shotTurn`).
    var shotTurns: [(shot: ShotStyle, muzzle: (x: Double, y: Double))] = []
    /// Where its melee weapon swings from, or where magic leaves its hand.
    var pivot: (x: Double, y: Double) = Sprite.hand
    /// Its ranged weapon is held in the hand (so it raises it to check it, idle). False when it's built in:
    /// repulsors, optic blasts, a Sentinel's palms.
    var handGun = true
    /// How many pixels further forward than plain Clawd its body reaches (the Hulk, the Juggernaut…): duels stand
    /// that much further apart so the other's weapon doesn't go through its face.
    var bulk = 0.0
    /// Top row of the head/helmet/hair on the canvas, for placing its label (the drawn sprite is measured too).
    var headTop = 21
    /// Length in seconds of its idle signature move, if it has one (`Pose.signature` runs 0…1 through it).
    var signature: Double? = nil
    /// What it says now and then while leading a session.
    var callout: String? = nil
    /// Does idle habits (glancing, shuffling, handling its weapon). False: it just stands guard.
    var fidgets = true
    /// Its own target-practice rhythm when working alone (seconds between shots, and where in that it starts), on the
    /// shared clock; nil: every `blasterPeriod` on its own clock. Clawd Wars' heroes each had one.
    var soloFire: (period: Double, phase: Double)? = nil
    /// A signature that climbs a thread up out of sight and back down (Shellob): drawn by whoever places the sprite,
    /// since the thread runs up to the top of the screen, past the canvas.
    var climb: Climb? = nil
    /// Its shots never land (the Stormtroupers, to keep the joke going): a bolt that would hit goes wide instead.
    var missesEverything = false
    /// Draws it facing right on the 72×52 canvas.
    let draw: (PixelCanvas, Pose) -> Void

    /// A placeholder for a character whose persona isn't registered (shouldn't happen).
    static func missing(_ name: String) -> Persona {
        Persona(name: name, draw: { c, p in drawStandIn(c, p, body: C(0x8A8A96), trim: C(0x5A5A66)) })
    }
}


/// Which of `count` shot turns (`Persona.shotTurns`) the shot fired on clock `t` is: the next in turn every period.
func shotTurn(t: Double, period: Double, count: Int) -> Int {
    guard count > 1 else { return 0 }
    let n = Int(floor(t / period)) % count
    return n < 0 ? n + count : n
}
