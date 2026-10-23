import Foundation

/// The menu bar icon: a devil's trap, the hunters' painted circle with the star inside it, on a 28×26 canvas. Bold
/// enough to read 19×18 points in the menu bar: a thick ring, the five-pointed star's lines two pixels wide where they
/// can be, and nothing finer. `mono`: one colour, for a template image macOS tints to match the bar. In colour it's the
/// red of spray paint on a concrete floor, and the app adds a white outline round it.
func huntMenuIcon(_ c: PixelCanvas, mono: Bool = false) {
    let paint = mono ? C(0x000000) : C(0xC42A26), paintD = mono ? C(0x000000) : C(0x8A1A18)
    let cx = 13.5, cy = 13.0
    // The ring: everything between two radii.
    for y in 0..<26 {
        for x in 0..<28 {
            let d = ((Double(x) - cx) * (Double(x) - cx) + (Double(y) - cy) * (Double(y) - cy)).squareRoot()
            if d >= 10.6 && d <= 12.9 { c.px(x, y, d > 12 ? paintD : paint) }
        }
    }
    // The star: five points on a circle inside the ring, each joined to the next-but-one.
    let pts = (0..<5).map { k -> (Double, Double) in
        let a = (-90 + Double(k) * 72) * .pi / 180
        return (cx + cos(a) * 10, cy + sin(a) * 10)
    }
    for k in 0..<5 {
        let a = pts[k], b = pts[(k + 2) % 5]
        let n = 40
        for i in 0...n {
            let t = Double(i) / Double(n)
            let x = a.0 + (b.0 - a.0) * t, y = a.1 + (b.1 - a.1) * t
            c.px(Int(x.rounded()), Int(y.rounded()), paint)
            c.px(Int(x.rounded()), Int((y + 0.5).rounded()), paint)
        }
    }
}
