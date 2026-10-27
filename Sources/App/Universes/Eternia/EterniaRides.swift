import Foundation

// Clawds of the Universe's rides (phase 4): who gets picked up when their agent is done, and by what. Still to come:
// the Wind Raider for Eternia's heroes, Swift Wind for She-Clawd and the rebels, the Roton for Skeleclawd's side and a
// bat-winged skiff for the Horde (Hordakk arriving as a rocket). Until then everyone walks off on foot.

/// Every ride, for Preview's sheet.
let eterniaRides: [Ride] = []

/// The ride that picks `c` up when its agent is done; nil: it walks off on foot.
func eterniaRide(_ c: Cast) -> Ride? {
    guard c.universe == .eternia else { return nil }
    return nil
}
