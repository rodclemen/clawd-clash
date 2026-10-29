import AppKit

// Renders a universe's showcase README's own pictures with the app's sprite code: its icon and the strips showing its
// set pieces. Each universe that has a showcase keeps it in its folder, as `Promo/<Prefix>Showcase.swift` (a
// `Showcase`), drawn with the kit below. (The roster, locations, desktop and social preview come from
// Tools/RenderDocs, the transitions sheet from Tools/Transitions; the window, screen saver and hover shots are
// CLAWD_SHOT captures of a Playground run.)
//   source Tools/universes.sh && swiftc -swift-version 5 Sources/App/{Pixel,Characters,Fights,Persona,Theme,Pose,Locations,Cast,Habits,Drills,Icon,Rides}.swift \
//          $UNIVERSE_APP $UNIVERSE_SHOWCASE Sources/Shared/*.swift Tools/RenderShowcase/main.swift -o build/rendershowcase
//   build/rendershowcase docs <name>        doctor, files, clawdberg, rings, slayer, hawkins, hunters, eternia: each showcase's `name`

/// A universe's showcase pictures. The registered ones (`registeredShowcases`) are generated from the folders by
/// Tools/universes.sh.
protocol Showcase {
    /// What `build/rendershowcase docs <name>` calls it.
    var name: String { get }
    /// Draws and saves every picture into `out`.
    func render()
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
let which = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "doctor"

func hexRGB(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func canvas(_ w: Int, _ h: Int, bg: UInt32?, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    if let bg { ctx.setFillColor(hexRGB(bg)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h)) }
    ctx.interpolationQuality = .none
    draw(ctx)
    NSGraphicsContext.current = nil
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
    print("wrote \(out)/\(name)")
}

/// One character drawn on its own canvas, outlined, facing right (or left).
func sprite(_ who: Cast, t: Double = 0.3, mode: VaderMode = .idle, walking: Bool = false, role: FightRole = .rest,
            left: Bool = false, flare: Double? = nil) -> PixelCanvas {
    let c = PixelCanvas(Sprite.width, Sprite.height)
    who.draw(c, t: t, mode: mode, walking: walking, role: role, asSession: false)
    if let flare { doctorDrawRegeneration(c, k: flare, t: t) }
    if left { c.flipHorizontally() }
    c.addOutline(C(0xFFFFFF, 0.92))
    return c
}

/// A pixel canvas drawn into `ctx` with its top-left at pixel (`x`, `y`) of a frame `unit` screen pixels per pixel,
/// `frameH` pixels tall (CoreGraphics is y-up).
func put(_ c: PixelCanvas, _ ctx: CGContext, x: Double, y: Double, unit: CGFloat, frameH: Int, origin: CGPoint, alpha: CGFloat = 1) {
    guard let img = c.makeImage() else { return }
    ctx.saveGState(); ctx.setAlpha(alpha)
    ctx.draw(img, in: CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(Double(frameH) - y - Double(c.h)) * unit,
                             width: CGFloat(c.w) * unit, height: CGFloat(c.h) * unit))
    ctx.restoreGState()
}

/// A label box over a character, as the app draws an agent's.
func tag(_ s: String, _ ctx: CGContext, centerX: CGFloat, bottom: CGFloat, leader: Bool = false) {
    let font = leader ? NSFont.monospacedSystemFont(ofSize: 15, weight: .bold) : NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
    let text = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: NSColor.white])
    let ts = text.size()
    let box = CGRect(x: centerX - ts.width / 2 - 8, y: bottom, width: ts.width + 16, height: ts.height + 6)
    let path = CGPath(roundedRect: box, cornerWidth: 6, cornerHeight: 6, transform: nil)
    ctx.addPath(path)
    ctx.setFillColor(leader ? CGColor(gray: 0.08, alpha: 0.85) : CGColor(red: 0.05, green: 0.10, blue: 0.24, alpha: 0.85)); ctx.fillPath()
    ctx.addPath(path)
    ctx.setStrokeColor(leader ? CGColor(gray: 1, alpha: 0.35) : CGColor(red: 0.45, green: 0.65, blue: 1, alpha: 0.5))
    ctx.setLineWidth(1.5); ctx.strokePath()
    NSGraphicsContext.saveGraphicsState()
    text.draw(at: NSPoint(x: box.minX + 8, y: box.minY + 3))
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: Strips

/// A strip of panels in one place, each with its caption above it, the way the Star Clawds page shows the shoot-out.
let pw = 150, ph = 66, unit: CGFloat = 3.2, gap: CGFloat = 10, capH: CGFloat = 34
struct Panel { let caption: String; let draw: (CGContext, CGPoint, (Double) -> CGFloat) -> Void }

func strip(_ place: Location, _ panels: [Panel], file: String) {
    let W = CGFloat(pw) * unit, H = CGFloat(ph) * unit
    let total = CGFloat(panels.count) * W + CGFloat(panels.count + 1) * gap
    let rep = canvas(Int(total), Int(H + capH + gap), bg: 0x121219) { ctx in
        for (i, p) in panels.enumerated() {
            let o = CGPoint(x: gap + CGFloat(i) * (W + gap), y: gap / 2)
            let bg = PixelCanvas(pw, ph); place.drawStatic(bg, floorRows: 8)
            let mv = PixelCanvas(pw, ph); place.drawAnimated(mv, floorRows: 8, t: 1.3 + Double(i) * 0.7)
            for img in [bg.makeImage(), mv.makeImage()].compactMap({ $0 }) { ctx.draw(img, in: CGRect(x: o.x, y: o.y, width: W, height: H)) }
            ctx.saveGState(); ctx.clip(to: CGRect(x: o.x, y: o.y, width: W, height: H))
            p.draw(ctx, o) { y in o.y + CGFloat(Double(ph) - y) * unit }   // pixel row → screen y
            ctx.restoreGState()
            let text = NSAttributedString(string: p.caption, attributes: [
                .font: NSFont.systemFont(ofSize: 17, weight: .bold), .foregroundColor: NSColor(srgbRed: 1, green: 0.91, blue: 0.3, alpha: 1)])
            NSGraphicsContext.saveGraphicsState()
            text.draw(at: NSPoint(x: o.x + (W - text.size().width) / 2, y: o.y + H + 8))
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    save(rep, file)
}

/// Feet on the ground row: a sprite's canvas top for a panel whose floor is 8 rows tall.
let spriteTop = Double(ph - 8 - 44)
func at(_ c: PixelCanvas, _ ctx: CGContext, _ o: CGPoint, bodyX: Double, left: Bool = false, alpha: CGFloat = 1, lift: Double = 0) {
    let x = left ? bodyX - (Double(Sprite.width) - Sprite.bodyCenterX) : bodyX - Sprite.bodyCenterX
    put(c, ctx, x: x, y: spriteTop - lift, unit: unit, frameH: ph, origin: o, alpha: alpha)
}

guard let showcase = registeredShowcases.first(where: { $0.name == which }) else {
    print("no showcase called \(which): \(registeredShowcases.map(\.name).joined(separator: ", "))")
    exit(1)
}
showcase.render()
