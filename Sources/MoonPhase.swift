import SwiftUI

/// The lit part of a waning moon. phase 0 = full, 0.5 = half (lit on the left), 1 = new.
/// Left limb is the circle; the terminator is a half-ellipse whose x semi-axis runs r → 0 → -r.
struct MoonPhase: Shape {
    var phase: Double
    var animatableData: Double { get { phase } set { phase = newValue } }

    func path(in rect: CGRect) -> Path {
        if phase >= 1 { return Path() }   // new moon: nothing lit, no stray hairline
        let r = min(rect.width, rect.height) / 2, c = CGPoint(x: rect.midX, y: rect.midY)
        let a = r * (1 - 2 * max(phase, 0))
        let n = 48
        var p = Path()
        for i in 0...n {   // left limb, top → bottom
            let t = (CGFloat(i) / CGFloat(n) - 0.5) * CGFloat.pi
            let pt = CGPoint(x: c.x - r * cos(t), y: c.y + r * sin(t))
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        for i in 0...n {   // terminator, bottom → top
            let t = (0.5 - CGFloat(i) / CGFloat(n)) * CGFloat.pi
            p.addLine(to: CGPoint(x: c.x + a * cos(t), y: c.y + r * sin(t)))
        }
        p.closeSubpath()
        return p
    }
}

/// Dark disc outline + glowing lit region.
struct MoonView: View {
    var phase: Double
    var body: some View {
        ZStack {
            Circle().stroke(Theme.rule, lineWidth: 1)
            MoonPhase(phase: phase).fill(Theme.moon.opacity(0.14))
            MoonTexture().mask(MoonPhase(phase: phase))
            MoonPhase(phase: phase)
                .stroke(Theme.moon, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .shadow(color: Theme.moon.opacity(0.55), radius: 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Watercolour washes: each mare is several jittered, blurred blobs at uneven density,
/// with a faint darker rim like pigment pooling at a wet edge. No hard shapes.
struct MoonTexture: View {
    // ponytail: hand-placed washes (fractions of the radius). dark = mare, light = highland bloom.
    static let washes: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rot: CGFloat, dark: Bool)] = [
        (-0.32, -0.36, 0.56, 0.48, -20, true),    // Imbrium
        ( 0.08, -0.30, 0.40, 0.34,  10, true),    // Serenitatis
        ( 0.34, -0.06, 0.44, 0.38,  25, true),    // Tranquillitatis
        ( 0.56,  0.20, 0.30, 0.38,  40, true),    // Fecunditatis
        (-0.22,  0.30, 0.36, 0.28,   0, true),    // Nubium
        (-0.60, -0.02, 0.40, 0.72, -10, true),    // Procellarum
        ( 0.10,  0.55, 0.70, 0.40,  15, false),   // southern highlands
        ( 0.45, -0.55, 0.40, 0.30, -30, false),
        (-0.05,  0.05, 0.30, 0.22,  50, false),
    ]
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var seed: UInt32 = 7
            func rnd() -> CGFloat { seed = seed &* 1664525 &+ 1013904223; return CGFloat(seed >> 8) / CGFloat(1 << 24) }
            var soft = ctx;  soft.addFilter(.blur(radius: r * 0.085))
            var rim = ctx;   rim.addFilter(.blur(radius: r * 0.025))
            for w in Self.washes {
                for _ in 0..<4 {
                    let sw = w.w * (0.55 + rnd() * 0.7), sh = w.h * (0.55 + rnd() * 0.7)
                    let dx = (rnd() - 0.5) * w.w * 0.5, dy = (rnd() - 0.5) * w.h * 0.5
                    let rect = CGRect(x: -sw * r / 2, y: -sh * r / 2, width: sw * r, height: sh * r)
                    let t = CGAffineTransform(translationX: c.x + (w.x + dx) * r, y: c.y + (w.y + dy) * r)
                        .rotated(by: (w.rot + (rnd() - 0.5) * 40) * .pi / 180)
                    let blob = Path(ellipseIn: rect).applying(t)
                    if w.dark {
                        soft.fill(blob, with: .color(.black.opacity(0.16 + rnd() * 0.22)))
                        rim.stroke(blob, with: .color(.black.opacity(0.10 + rnd() * 0.08)), lineWidth: r * 0.02)
                    } else {
                        soft.fill(blob, with: .color(Theme.moon.opacity(0.05 + rnd() * 0.07)))
                    }
                }
            }
        }
    }
}
