import SwiftUI

/// Colours in one place, so pastel themes can be added later (phase 4).
enum Theme {
    static let accent = Color(red: 0.55, green: 0.42, blue: 0.85)          // soft purple
    static let dieFace = Color(white: 0.99)
    static let dieEdge = Color.black.opacity(0.15)
    static let pip = Color(red: 0.16, green: 0.16, blue: 0.2)
    static let grid = Color.primary.opacity(0.18)
    static let sumRow = Color.primary.opacity(0.08)
    static let available = accent.opacity(0.14)
    static let announceHint = Color.orange.opacity(0.16)
    #if os(macOS)
    static let background = Color(nsColor: .windowBackgroundColor)
    #else
    static let background = Color(uiColor: .systemBackground)
    #endif
}
