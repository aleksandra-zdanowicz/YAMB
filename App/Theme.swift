import SwiftUI

/// Colours in one place. Accent-based colours follow the chosen pastel theme
/// (reading them inside a view's body makes the view update when the theme changes).
enum Theme {
    static var accent: Color { AppSettings.shared.themeColor.accent }
    static var available: Color { accent.opacity(0.16) }
    static var sumRow: Color { accent.opacity(0.11) }
    static var tint: Color { accent.opacity(0.06) }

    static let dieFace = Color(white: 0.99)
    static let dieEdge = Color.black.opacity(0.15)
    static let pip = Color(red: 0.16, green: 0.16, blue: 0.2)
    static let grid = Color.primary.opacity(0.18)
    static let announceHint = Color.orange.opacity(0.18)

    #if os(macOS)
    static let systemBackground = Color(nsColor: .windowBackgroundColor)
    #else
    static let systemBackground = Color(uiColor: .systemBackground)
    #endif

    /// Page background: the system background with a light wash of the theme colour.
    static var background: some View {
        systemBackground.overlay(tint)
    }
}
