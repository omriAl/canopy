import AppKit

/// Singleton service for displaying native macOS alerts.
/// MenuBarExtra doesn't have a window for SwiftUI .alert() modifiers,
/// so we use NSAlert directly.
final class AlertService {
    static let shared = AlertService()

    private init() {}

    /// Show an error alert with OK button
    @MainActor
    func showError(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")

        // Bring app to front so alert is visible
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Show a warning alert with OK button
    @MainActor
    func showWarning(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Show a confirmation alert with Cancel and destructive action buttons
    /// Returns true if user clicked the destructive action, false if cancelled
    @MainActor
    func showDestructiveConfirmation(
        title: String,
        message: String,
        destructiveButtonTitle: String
    ) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: destructiveButtonTitle)
        alert.addButton(withTitle: "Cancel")

        // Make the destructive button red
        if let destructiveButton = alert.buttons.first {
            destructiveButton.hasDestructiveAction = true
        }

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
}
