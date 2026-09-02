// Renders the app icon: crescent moon + stars on a night gradient, macOS rounded-rect shape.
import AppKit

let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()

let bg = NSRect(x: 100, y: 100, width: S - 200, height: S - 200)
NSBezierPath(roundedRect: bg, xRadius: 185, yRadius: 185).setClip()
NSGradient(colors: [
    NSColor(calibratedRed: 0.18, green: 0.14, blue: 0.42, alpha: 1),
    NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.09, alpha: 1),
])!.draw(in: bg, angle: -90)

// stars
NSColor(calibratedWhite: 1, alpha: 0.85).setFill()
for (x, y, r): (CGFloat, CGFloat, CGFloat) in [(320, 740, 10), (680, 790, 7), (760, 640, 9), (270, 560, 6), (600, 300, 5)] {
    NSBezierPath(ovalIn: NSRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)).fill()
}

// crescent moon: big circle minus offset circle (even-odd fill, clipped to the big circle)
NSGraphicsContext.current?.saveGraphicsState()
let big = NSRect(x: 292, y: 262, width: 440, height: 440)
NSBezierPath(ovalIn: big).setClip()
let crescent = NSBezierPath()
crescent.windingRule = .evenOdd
crescent.append(NSBezierPath(ovalIn: big))
crescent.append(NSBezierPath(ovalIn: big.offsetBy(dx: 130, dy: 80)))
NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.72, alpha: 1).setFill()
crescent.fill()
NSGraphicsContext.current?.restoreGraphicsState()

img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "icon_1024.png"))
print("wrote icon_1024.png")
