import Foundation

// Back from Hell: Superclawdtural's compaction. The Winclawdsters never stay dead. When the session of Dean, Sam,
// Clawdstiel, Bobby or Jack has its context compacted, they're dragged down by hellhound claws and sink in a red glow;
// a moment later a fist punches up through the ground, they climb out and dust themselves off, and the caption reads
// BACK FROM HELL. Same session, same face. It runs on the engine's missing-time clock (`SessionRecord.abducted`,
// `missingTimeLength`), as The Clawd Files' missing time and Stranger Clawds' Upside Down do.
//
// To draw here: everything above.

/// Where it is, `k` 0…1 through it.
struct HuntBackFromHell: CompactionLook {
    let k: Double

    func layers(cast: Cast, x: CGFloat, y: CGFloat, lift: CGFloat, scale: CGFloat, facing: CGFloat, t: Double) -> [StageLayer] { [] }
}
