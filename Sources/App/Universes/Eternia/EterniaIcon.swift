import Foundation

/// The menu bar icon: Castle Greyskull's skull face between its two towers, the jawbridge down onto the rock it
/// stands on, on a 28×26 canvas. `mono`: one colour for the template image; the sockets, the nose and the open mouth
/// stay holes, and a column of gap keeps each tower apart from the skull, so the face still reads when tinted.
func eterniaMenuIcon(_ c: PixelCanvas, mono: Bool = false) {
    let rows: [String] = [
        "..TT....................TT..",
        ".TTTT..................TTTT.",
        ".TTTT......SSSSSS......TTTT.",
        ".TTTT....SSSSSSSSSS....TTTT.",
        ".TTTT...SSSSSSSSSSSS...TTTT.",
        ".TTTT..SSSSSSSSSSSSSS..TTTT.",
        ".TTTT.SSSSSSSSSSSSSSSS.TTTT.",
        ".TTTT.SSKKKKSSSSKKKKSS.TTTT.",
        ".TTTT.SKKKKKKSSKKKKKKS.TTTT.",
        ".TTTT.SKKKKKKSSKKKKKKS.TTTT.",
        ".TTTT.SSKKKKSSSSKKKKSS.TTTT.",
        ".TTTT.SSSSSSSKKSSSSSSS.TTTT.",
        ".TTTT.SSSSSSKKKKSSSSSS.TTTT.",
        ".TTTT.SSSSSSSSSSSSSSSS.TTTT.",
        ".TTTT.SSSSKKKKKKKKSSSS.TTTT.",
        ".TTTT.SSSKKKKKKKKKKSSS.TTTT.",
        ".TTTT.SSSKKKKKKKKKKSSS.TTTT.",
        ".TTTTTSSSKKKKKKKKKKSSSTTTTT.",
        "TTTTTTTSSKKKKKKKKKKSSTTTTTTT",
        "RRRRRRRRR.JJJJJJJJ.RRRRRRRRR",
        "RRRRRRRR.JJJJJJJJJJ.RRRRRRRR",
        ".RRRRRR.JJJJJJJJJJJJ.RRRRRR.",
        "..RRRR................RRRR..",
        "...RR..................RR...",
    ]
    let y0 = 1
    if mono {
        let k = C(0x000000)
        c.pattern(0, y0, rows, ["T": k, "S": k, "R": k, "J": k])
        return
    }
    c.pattern(0, y0, rows, ["T": C(0x5E7A5A), "S": C(0x8EA282), "K": C(0x16141C), "R": C(0x6A5A4A), "J": C(0x9A7444)])
    // The light from the left: the towers' and the skull's left edges lit, the brow ridge over the sockets, the planks.
    for y in 1...18 { c.px(1, y0 + y, C(0x7E9A76)); c.px(23, y0 + y, C(0x7E9A76)) }
    c.rect(11, y0 + 2, 6, 1, C(0xB0C2A2)); c.rect(9, y0 + 3, 3, 1, C(0xB0C2A2)); c.px(7, y0 + 5, C(0xB0C2A2))
    for x in stride(from: 11, to: 18, by: 2) { c.px(x, y0 + 20, C(0x6E4E2A)) }
}
