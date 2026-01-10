import Foundation

final class ProcessRunner {
    enum ProcessError: Error, LocalizedError {
        case executionFailed(Int32, String)
        case invalidOutput

        var errorDescription: String? {
            switch self {
            case .executionFailed(let code, let output):
                return "Process failed with code \(code): \(output)"
            case .invalidOutput:
                return "Invalid output from process"
            }
        }
    }

    func run(
        _ executable: String,
        arguments: [String],
        workingDirectory: String? = nil
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = errorPipe

            if let workingDirectory {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
            }

            // Build PATH: custom path (if set) + common locations
            var paths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
            if let customPath = UserDefaults.standard.string(forKey: "canopy.customCLIPath"), !customPath.isEmpty {
                paths.insert(customPath, at: 0)
            }
            process.environment = ProcessInfo.processInfo.environment.merging([
                "PATH": paths.joined(separator: ":"),
                // Prevent git from updating stat cache, which triggers file watchers
                "GIT_OPTIONAL_LOCKS": "0"
            ]) { _, new in new }

            do {
                try process.run()

                // Read pipe data BEFORE waiting for exit to avoid deadlock.
                // If output exceeds the pipe buffer, the process blocks on write
                // and we'd be waiting forever for it to exit.
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                process.waitUntilExit()

                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? output
                    continuation.resume(throwing: ProcessError.executionFailed(
                        process.terminationStatus,
                        errorOutput
                    ))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func runDetached(
        _ executable: String,
        arguments: [String],
        workingDirectory: String? = nil
    ) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        if let workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        // Build PATH: custom path (if set) + common locations
        var paths = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        if let customPath = UserDefaults.standard.string(forKey: "canopy.customCLIPath"), !customPath.isEmpty {
            paths.insert(customPath, at: 0)
        }
        process.environment = ProcessInfo.processInfo.environment.merging([
            "PATH": paths.joined(separator: ":"),
            // Prevent git from updating stat cache, which triggers file watchers
            "GIT_OPTIONAL_LOCKS": "0"
        ]) { _, new in new }

        try process.run()
    }
}
