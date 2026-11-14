import Foundation

/// The menu bar icon: a stick of goblin dynamite, its fuse lit, on a 28×26 canvas. `mono`: one colour, for a template
/// image macOS tints to match the bar, with a gap between the stick and its spark so they still read as two. In colour
/// the app adds a white outline round it, so it reads on a dark menu bar.
func crawlMenuIcon(_ c: PixelCanvas, mono: Bool = false) {
    let rows: [String] = [
        "..................S.S.......",
        "...................S........",
        "..................S.S.......",
        "................F...........",
        "...............F............",
        "..............F.............",
        "...........RRRR.............",
        "..........RRRRRR............",
        ".........RRRRRRR............",
        "........RRRRRRR.............",
        ".......WRRRRRR..............",
        "......WWWRRRR...............",
        ".....RRWWWRR................",
        "....RRRRWWW.................",
        "...RRRRRRW..................",
        "..RRRRRRR...................",
        ".RRRRRRR....................",
        "RRRRRRR.....................",
        ".RRRRR......................",
        "..RRR.......................",
    ]
    let y0 = 3
    if mono {
        c.pattern(0, y0, rows, ["R": C(0x000000), "W": C(0x000000, 0), "F": C(0x000000), "S": C(0x000000)])
        return
    }
    c.pattern(0, y0, rows, ["R": C(0xC8302A), "W": C(0xEAD8A0), "F": C(0x3A2A1A), "S": C(0xFFD040)])
    // The stick's shade along its underside, its lit top edge, the spark's hot middle.
    for k in 0..<8 { c.px(3 + k * 2 - 1, y0 + 17 - k * 2 + 1, C(0x8A1E1A)) }
    for k in 0..<5 { c.px(10 + k, y0 + 7 - k / 2, C(0xE8584A)) }
    c.px(19, y0 + 1, C(0xFFFFFF))
}
