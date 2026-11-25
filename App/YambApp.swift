import SwiftUI

@main
struct YambApp: App {
    @State private var model = GameModel()

    var body: some Scene {
        WindowGroup {
            GameView(model: model)
                #if os(macOS)
                .frame(minWidth: 820, minHeight: 640)
                #endif
        }
    }
}
