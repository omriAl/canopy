import Foundation

/// Service for displaying native macOS notifications via terminal-notifier.
final class NotificationService {
    static let shared = NotificationService()

    /// Path to the bundled terminal-notifier executable
    private var notifierPath: String {
        // Try bundled path first
        if let resourcePath = Bundle.main.resourcePath {
            let bundledPath = "\(resourcePath)/terminal-notifier.app/Contents/MacOS/terminal-notifier"
            if FileManager.default.fileExists(atPath: bundledPath) {
                return bundledPath
            }
        }
        // Fallback to homebrew path for development
        return "/opt/homebrew/bin/terminal-notifier"
    }

    private init() {}

    /// Show a success notification
    func showSuccess(title: String, message: String) {
        sendNotification(title: title, message: message)
    }

    /// Show an error notification
    func showError(title: String, message: String) {
        sendNotification(title: title, message: message)
    }

    private func sendNotification(title: String, message: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: notifierPath)
        process.arguments = [
            "-title", title,
            "-message", message,
            "-sound", "default",
            "-sender", "com.canopy.app"
        ]

        do {
            try process.run()
        } catch {
            print("[Canopy] Failed to send notification: \(error.localizedDescription)")
        }
    }
}
