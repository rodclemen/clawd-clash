import Foundation

// Superclawdtural's ride (`Ride`): Baby, the black 1967 Chevrolet Impala, drawn nose to the right on the rides'
// `Ride.width`×`Ride.height` canvas. Who rides is `huntTheme`'s `ride:` closure (HuntRoster.swift): everyone.
//
// To draw here: the Impala driving in along the ground, headlights on, stopping, the trunk lid swinging up on the
// arsenal for a moment while whoever's leaving gets in, and driving off.

extension Ride {
    /// Baby: she drives in, and whoever's leaving gets in at the back door.
    static let huntImpala = Ride(key: "huntImpala", arrival: .drives, boardingOffset: 14) { c, ramp, engines, _, t in
        huntDrawImpala(c, ramp: ramp, moving: engines, t: t)
    }
}

/// The Impala. `moving`: driving, the wheels turning and the headlights lit; `ramp` 0…1 is the stop and the boarding.
func huntDrawImpala(_ c: PixelCanvas, ramp: Double, moving: Bool, t: Double) {}
