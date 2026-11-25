import SwiftUI

/// One die with pips. Held dice are outlined and lifted.
struct DieView: View {
    let value: Int
    let held: Bool
    let active: Bool
    let spins: Int

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                    .fill(Theme.dieFace)
                    .shadow(color: .black.opacity(held ? 0.25 : 0.12), radius: held ? 6 : 2, y: held ? 4 : 1)
                RoundedRectangle(cornerRadius: size * 0.2, style: .continuous)
                    .strokeBorder(held ? Theme.accent : Theme.dieEdge, lineWidth: held ? size * 0.07 : 1)
                ForEach(Array((Self.pips[value] ?? []).enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(Theme.pip)
                        .frame(width: size * 0.19, height: size * 0.19)
                        .position(x: size * p.x, y: size * p.y)
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .opacity(active ? 1 : 0.35)
        .offset(y: held ? -6 : 0)
        .rotationEffect(.degrees(Double(spins) * 360))
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: spins)
        .animation(.spring(response: 0.25), value: held)
        .accessibilityLabel("Die showing \(value)\(held ? ", kept" : "")")
    }

    private static let l = 0.27, m = 0.5, r = 0.73
    static let pips: [Int: [CGPoint]] = [
        1: [CGPoint(x: m, y: m)],
        2: [CGPoint(x: l, y: l), CGPoint(x: r, y: r)],
        3: [CGPoint(x: l, y: l), CGPoint(x: m, y: m), CGPoint(x: r, y: r)],
        4: [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: l, y: r), CGPoint(x: r, y: r)],
        5: [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: m, y: m), CGPoint(x: l, y: r), CGPoint(x: r, y: r)],
        6: [CGPoint(x: l, y: l), CGPoint(x: r, y: l), CGPoint(x: l, y: m), CGPoint(x: r, y: m),
            CGPoint(x: l, y: r), CGPoint(x: r, y: r)],
    ]
}
