import SwiftUI

/// Look & feel settings: colour theme, light/dark mode, sounds, haptics, score previews.
struct SettingsView: View {
    @Bindable var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colour") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 12)], spacing: 12) {
                        ForEach(ThemeColor.allCases) { color in
                            swatch(color)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Appearance") {
                    Picker("Mode", selection: $settings.appearance) {
                        ForEach(Appearance.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Feedback") {
                    Toggle("Sounds", isOn: $settings.soundsOn)
                    #if os(iOS)
                    Toggle("Haptics", isOn: $settings.hapticsOn)
                    #endif
                }

                Section {
                    Toggle("Show score previews", isOn: $settings.showPreviews)
                } footer: {
                    Text("When on, allowed cells show what they would score.")
                }
            }
            .formStyle(.grouped)
            .tint(Theme.accent)
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(settings.appearance.colorScheme)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }

    private func swatch(_ color: ThemeColor) -> some View {
        let selected = settings.themeColor == color
        return Button {
            settings.themeColor = color
            Feedback.shared.play(.hold)
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.accent)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().strokeBorder(.primary.opacity(selected ? 0.7 : 0), lineWidth: 3).padding(-5))
                    .overlay(selected ? Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(.white) : nil)
                Text(color.name).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.name) theme\(selected ? ", selected" : "")")
    }
}
