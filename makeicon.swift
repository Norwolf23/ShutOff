// Renders the app icon: deep-night gradient, one thin-line crescent moon, three faint stars.
// Writes icon_mac_1024.png (rounded rect with macOS margins) and icon_ios_1024.png (full square).
import AppKit

let S: CGFloat = 1024
let top = NSColor(calibratedRed: 0.055, green: 0.070, blue: 0.135, alpha: 1)
let bottom = NSColor(calibratedRed: 0.016, green: 0.020, blue: 0.047, alpha: 1)
let moon = NSColor(calibratedRed: 0.788, green: 0.831, blue: 0.918, alpha: 1)

/// Outline of a crescent = outer arc of circle 1 (away from circle 2) + inner arc of circle 2 (inside circle 1).
func crescent(c1: NSPoint, r1: CGFloat, c2: NSPoint, r2: CGFloat) -> NSBezierPath {
    let dx = c2.x - c1.x, dy = c2.y - c1.y, d = hypot(dx, dy)
    let a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    let h = sqrt(r1 * r1 - a * a)
    let phi = atan2(dy, dx), delta = atan2(h, a)
    let deg = { (r: CGFloat) in r * 180 / .pi }
    let p = NSBezierPath()
    // outer arc on c1, counterclockwise from phi+delta through phi+180 to phi-delta
    p.appendArc(withCenter: c1, radius: r1, startAngle: deg(phi + delta), endAngle: deg(phi - delta) + 360, clockwise: false)
    // inner arc on c2 back to the start, passing the side that faces c1
    let end = NSPoint(x: c1.x + r1 * cos(phi - delta), y: c1.y + r1 * sin(phi - delta))
    let start = NSPoint(x: c1.x + r1 * cos(phi + delta), y: c1.y + r1 * sin(phi + delta))
    let a2 = atan2(end.y - c2.y, end.x - c2.x), a1 = atan2(start.y - c2.y, start.x - c2.x)
    p.appendArc(withCenter: c2, radius: r2, startAngle: deg(a2), endAngle: deg(a1), clockwise: true)
    p.close()
    return p
}

func render(mac: Bool) -> NSImage {
    let img = NSImage(size: NSSize(width: S, height: S))
    img.lockFocus()
    let bg = mac ? NSRect(x: 100, y: 100, width: S - 200, height: S - 200) : NSRect(x: 0, y: 0, width: S, height: S)
    if mac { NSBezierPath(roundedRect: bg, xRadius: 185, yRadius: 185).setClip() }
    NSGradient(colors: [top, bottom])!.draw(in: bg, angle: -90)

    NSColor(calibratedWhite: 1, alpha: 0.45).setFill()
    for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(300, 760, 5), (720, 800, 3.5), (770, 330, 4)] {
        NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)).fill()
    }

    let scale: CGFloat = mac ? 1 : 1.15
    let path = crescent(c1: NSPoint(x: 512, y: 512), r1: 230 * scale,
                        c2: NSPoint(x: 512 + 115 * scale, y: 512 + 60 * scale), r2: 215 * scale)
    path.lineWidth = 34; path.lineJoinStyle = .round
    moon.withAlphaComponent(0.18).setStroke(); path.stroke()   // glow
    path.lineWidth = 14
    moon.setStroke(); path.stroke()
    img.unlockFocus()
    return img
}

for (name, mac) in [("icon_mac_1024.png", true), ("icon_ios_1024.png", false)] {
    let rep = NSBitmapImageRep(data: render(mac: mac).tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: name))
    print("wrote \(name)")
}
