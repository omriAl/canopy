import Foundation
import Observation

/// Manages running processes per worktree
@Observable
final class ProcessManager {
    /// Represents a tracked running process
    private struct TrackedProcess {
        let process: Process
        let pid: Int32
        let startTime: Date
    }

    /// Running processes keyed by worktree path
    private var processes: [String: TrackedProcess] = [:]

    /// Cached URLs from CANOPY_URL.txt files, keyed by worktree path
    private(set) var cachedURLs: [String: URL] = [:]

    /// Activity token to prevent App Nap while processes are running
    private var activityToken: NSObjectProtocol?

    /// Check if a process is running for a worktree
    func isRunning(worktreePath: String) -> Bool {
        guard let tracked = processes[worktreePath] else { return false }
        return tracked.process.isRunning
    }

    /// Start a command in a worktree directory
    func start(command: String, in worktreePath: String) throws {
        // Stop existing process if any
        stop(worktreePath: worktreePath)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.currentDirectoryURL = URL(fileURLWithPath: worktreePath)

        // Build PATH: custom path (if set) + common locations
        var paths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        if let customPath = UserDefaults.standard.string(forKey: "canopy.customCLIPath"), !customPath.isEmpty {
            paths.insert(customPath, at: 0)
        }
        process.environment = ProcessInfo.processInfo.environment.merging([
            "PATH": paths.joined(separator: ":")
        ]) { _, new in new }

        // Set up termination handler to clean up state
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.processes.removeValue(forKey: worktreePath)
                self?.endActivityIfNeeded()
            }
        }

        try process.run()

        let tracked = TrackedProcess(
            process: process,
            pid: process.processIdentifier,
            startTime: Date()
        )
        processes[worktreePath] = tracked

        // Prevent App Nap while processes are running
        beginActivityIfNeeded()
    }

    /// Stop a running process for a worktree
    func stop(worktreePath: String) {
        guard let tracked = processes[worktreePath] else { return }

        if tracked.process.isRunning {
            tracked.process.terminate()
        }
        processes.removeValue(forKey: worktreePath)

        // End activity if no more processes are running
        endActivityIfNeeded()
    }

    /// Restart the process for a worktree
    func restart(command: String, in worktreePath: String) throws {
        stop(worktreePath: worktreePath)
        try start(command: command, in: worktreePath)
    }

    /// Get the cached URL for a worktree
    func getCanopyURL(for worktreePath: String) -> URL? {
        cachedURLs[worktreePath]
    }

    /// Refresh cached URLs for the given worktree paths
    func refreshURLs(for worktreePaths: [String]) {
        var newCache: [String: URL] = [:]
        for path in worktreePaths {
            if let url = readCanopyURLFile(at: path) {
                newCache[path] = url
            }
        }
        cachedURLs = newCache
    }

    /// Read the URL from CANOPY_URL.txt in the worktree directory
    private func readCanopyURLFile(at worktreePath: String) -> URL? {
        let urlFile = URL(fileURLWithPath: worktreePath)
            .appendingPathComponent("CANOPY_URL.txt")

        guard let content = try? String(contentsOf: urlFile, encoding: .utf8) else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: trimmed)
    }

    // MARK: - App Nap Prevention

    /// Begin activity to prevent App Nap when processes start running
    private func beginActivityIfNeeded() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Running development processes"
        )
    }

    /// End activity when no more processes are running
    private func endActivityIfNeeded() {
        guard processes.isEmpty, let token = activityToken else { return }
        ProcessInfo.processInfo.endActivity(token)
        activityToken = nil
    }
}
