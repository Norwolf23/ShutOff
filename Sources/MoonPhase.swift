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
            MoonPhase(phase: phase).fill(Theme.moon.opacity(0.10))
            MoonPhase(phase: phase)
                .stroke(Theme.moon, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .shadow(color: Theme.moon.opacity(0.55), radius: 8)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
