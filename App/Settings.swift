import Foundation
import Observation
import SwiftUI

/// Pastel colour themes.
enum ThemeColor: String, CaseIterable, Identifiable {
    case lavender, pink, blue, mint, peach, lilac

    var id: String { rawValue }

    var name: String {
        switch self {
        case .lavender: return "Lavender"
        case .pink: return "Pink"
        case .blue: return "Blue"
        case .mint: return "Mint"
        case .peach: return "Peach"
        case .lilac: return "Lilac"
        }
    }

    var accent: Color {
        switch self {
        case .lavender: return Color(red: 0.55, green: 0.42, blue: 0.85)
        case .pink: return Color(red: 0.91, green: 0.45, blue: 0.62)
        case .blue: return Color(red: 0.33, green: 0.58, blue: 0.86)
        case .mint: return Color(red: 0.24, green: 0.68, blue: 0.55)
        case .peach: return Color(red: 0.95, green: 0.55, blue: 0.38)
        case .lilac: return Color(red: 0.74, green: 0.45, blue: 0.82)
        }
    }
}

/// Light / dark mode choice.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// App-wide settings, saved between launches. Views reading these update automatically.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    var themeColor: ThemeColor { didSet { save(themeColor.rawValue, "themeColor") } }
    var appearance: Appearance { didSet { save(appearance.rawValue, "appearance") } }
    var soundsOn: Bool { didSet { save(soundsOn, "soundsOn") } }
    var hapticsOn: Bool { didSet { save(hapticsOn, "hapticsOn") } }
    var showPreviews: Bool { didSet { save(showPreviews, "showScorePreviews") } }

    private init() {
        let d = UserDefaults.standard
        themeColor = ThemeColor(rawValue: d.string(forKey: "themeColor") ?? "") ?? .lavender
        appearance = Appearance(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        soundsOn = d.object(forKey: "soundsOn") as? Bool ?? true
        hapticsOn = d.object(forKey: "hapticsOn") as? Bool ?? true
        showPreviews = d.object(forKey: "showScorePreviews") as? Bool ?? true
    }

    private func save(_ value: Any, _ key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
