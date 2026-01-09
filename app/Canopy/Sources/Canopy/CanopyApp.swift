import SwiftUI

@main
struct CanopyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenuView()
                .environment(appState)
        } label: {
            Image(systemName: "tree.fill")
        }
        .menuBarExtraStyle(.window)

        Window("Canopy Settings", id: "settings") {
            SettingsView()
                .environment(appState)
        }
        .windowResizability(.contentSize)

        Window("New Worktree", id: "new-worktree") {
            NewWorktreeView()
                .environment(appState)
        }
        .windowResizability(.contentSize)
    }
}
