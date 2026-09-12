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

/// Faint maria and crater rings, roughly where they are on the real near side.
/// Positions are fractions of the radius from the centre; drawn once per frame, masked by the phase.
struct MoonTexture: View {
    // ponytail: hand-placed features, not a height map. Tweak here.
    static let maria: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rot: CGFloat)] = [
        (-0.32, -0.36, 0.56, 0.48, -20),   // Imbrium
        ( 0.08, -0.30, 0.40, 0.34,  10),   // Serenitatis
        ( 0.34, -0.06, 0.44, 0.38,  25),   // Tranquillitatis
        ( 0.56,  0.20, 0.30, 0.38,  40),   // Fecunditatis
        (-0.22,  0.30, 0.36, 0.28,   0),   // Nubium
        (-0.60, -0.02, 0.40, 0.72, -10),   // Oceanus Procellarum
    ]
    static let craters: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (-0.10, 0.66, 0.065), (-0.24, -0.04, 0.055), (-0.50, 0.02, 0.038),
        ( 0.40, 0.42, 0.045), ( 0.18, 0.20, 0.030), (-0.42, 0.50, 0.032),
    ]
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var soft = ctx
            soft.addFilter(.blur(radius: r * 0.055))
            for m in Self.maria {
                let rect = CGRect(x: -m.w * r / 2, y: -m.h * r / 2, width: m.w * r, height: m.h * r)
                let t = CGAffineTransform(translationX: c.x + m.x * r, y: c.y + m.y * r).rotated(by: m.rot * .pi / 180)
                soft.fill(Path(ellipseIn: rect).applying(t), with: .color(.black.opacity(0.55)))
            }
            for k in Self.craters {
                let rect = CGRect(x: c.x + k.x * r - k.r * r, y: c.y + k.y * r - k.r * r, width: 2 * k.r * r, height: 2 * k.r * r)
                ctx.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.18)))
                ctx.stroke(Path(ellipseIn: rect), with: .color(Theme.moon.opacity(0.35)), lineWidth: 0.8)
            }
        }
    }
}
