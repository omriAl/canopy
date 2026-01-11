import Foundation
import AppKit

final class WorktreeService {
    private let processRunner = ProcessRunner()

    enum WorktreeError: Error, LocalizedError {
        case commandFailed(String)
        case parseError(String)
        case worktreeNotFound(String)

        var errorDescription: String? {
            switch self {
            case .commandFailed(let message):
                return "Git command failed: \(message)"
            case .parseError(let message):
                return "Failed to parse git output: \(message)"
            case .worktreeNotFound(let branch):
                return "Worktree not found for branch: \(branch)"
            }
        }
    }

    /// List all worktrees for a repository
    func listWorktrees(in repoPath: String) async throws -> [Worktree] {
        let output = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "worktree", "list", "--porcelain"],
            workingDirectory: repoPath
        )

        var worktrees = parseWorktreeList(output, repoPath: repoPath)

        // Populate dirty status in parallel for all worktrees
        try await withThrowingTaskGroup(of: (Int, Bool).self) { group in
            for (index, worktree) in worktrees.enumerated() {
                group.addTask {
                    let isDirty = try await self.checkDirtyStatus(path: worktree.path)
                    return (index, isDirty)
                }
            }

            for try await (index, isDirty) in group {
                worktrees[index].isDirty = isDirty
            }
        }

        return worktrees
    }

    /// Fetch a remote branch to ensure we have the latest state
    func fetchRemoteBranch(_ remoteBranch: String, in repoPath: String) async throws {
        let components = remoteBranch.split(separator: "/", maxSplits: 1)
        guard components.count == 2 else {
            throw WorktreeError.parseError("Invalid remote branch format: \(remoteBranch). Expected format: remote/branch")
        }

        let remote = String(components[0])
        let branch = String(components[1])

        _ = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "fetch", remote, branch],
            workingDirectory: repoPath
        )
    }

    /// Create a new worktree from a specified base branch
    func createWorktree(branch: String, from baseBranch: String?, in repoPath: String) async throws {
        // Calculate worktree path following the convention: <repo>-worktrees/<branch>/
        let repoURL = URL(fileURLWithPath: repoPath)
        let repoName = repoURL.lastPathComponent
        let parentDir = repoURL.deletingLastPathComponent()
        let worktreesDir = parentDir.appendingPathComponent("\(repoName)-worktrees")
        let worktreePath = worktreesDir.appendingPathComponent(branch).path

        // Create worktrees directory if needed
        try FileManager.default.createDirectory(at: worktreesDir, withIntermediateDirectories: true)

        // Build git worktree add command
        var args = ["git", "worktree", "add", worktreePath, "-b", branch]
        if let baseBranch = baseBranch {
            args.append(baseBranch)
        }

        _ = try await processRunner.run(
            "/usr/bin/env",
            arguments: args,
            workingDirectory: repoPath
        )
    }

    /// Remove a worktree
    func removeWorktree(branch: String, force: Bool, in repoPath: String) async throws {
        // First resolve the branch name to its worktree path
        let worktreePath = try await getWorktreePath(branch: branch, in: repoPath)

        var args = ["git", "worktree", "remove", worktreePath]
        if force {
            args.append("--force")
        }

        do {
            _ = try await processRunner.run(
                "/usr/bin/env",
                arguments: args,
                workingDirectory: repoPath
            )
        } catch {
            // git worktree remove --force fails with "Directory not empty" when there are
            // untracked files. In this case, manually delete the directory and prune.
            let errorMessage = error.localizedDescription
            if errorMessage.contains("Directory not empty") {
                // Manually delete the worktree directory
                try FileManager.default.removeItem(atPath: worktreePath)

                // Prune stale worktree references
                _ = try await processRunner.run(
                    "/usr/bin/env",
                    arguments: ["git", "worktree", "prune"],
                    workingDirectory: repoPath
                )
            } else {
                throw error
            }
        }
    }

    /// Launch AI tool (Claude) in a worktree (synchronous, non-blocking)
    func launchAI(branch: String, in repoPath: String, terminal: Terminal) throws {
        let worktreePath = try getWorktreePathSync(branch: branch, in: repoPath)
        openTerminal(at: worktreePath, terminal: terminal)
    }

    /// Open terminal at the specified path
    func openTerminal(at path: String, terminal: Terminal) {
        switch terminal {
        case .warp:
            openWarp(at: path)
        case .iterm2:
            openITerm2(at: path)
        }
    }

    private func openWarp(at path: String) {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let warpURL = "warp://action/new_window?path=\(encodedPath)"
        if let url = URL(string: warpURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openITerm2(at path: String) {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let itermURL = "iterm2:///command?d=\(encodedPath)"
        if let url = URL(string: itermURL) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Get worktree path synchronously by parsing git worktree list output
    func getWorktreePathSync(branch: String, in repoPath: String) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "worktree", "list", "--porcelain"]
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        process.standardOutput = pipe

        try process.run()

        // Read pipe data BEFORE waiting for exit to avoid deadlock
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""

        // Parse the output to find the path for the given branch
        if let path = findWorktreePath(forBranch: branch, in: output) {
            return path
        }

        throw WorktreeError.worktreeNotFound(branch)
    }

    /// Get the path of a worktree
    func getWorktreePath(branch: String, in repoPath: String) async throws -> String {
        let output = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "worktree", "list", "--porcelain"],
            workingDirectory: repoPath
        )

        if let path = findWorktreePath(forBranch: branch, in: output) {
            return path
        }

        throw WorktreeError.worktreeNotFound(branch)
    }

    /// Check if a worktree has uncommitted changes
    func checkDirtyStatus(path: String) async throws -> Bool {
        let output = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "-C", path, "status", "--porcelain"],
            workingDirectory: nil
        )
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Set the postCreate hook for a repository
    func setPostCreateHook(_ hookPath: String, in repoPath: String) async throws {
        _ = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "config", "canopy.hook.postCreate", hookPath],
            workingDirectory: repoPath
        )
    }

    /// Clear the postCreate hook for a repository
    func clearPostCreateHook(in repoPath: String) async throws {
        _ = try await processRunner.run(
            "/usr/bin/env",
            arguments: ["git", "config", "--unset", "canopy.hook.postCreate"],
            workingDirectory: repoPath
        )
    }

    /// Run the post-create hook command in a worktree directory
    func runPostCreateHook(_ command: String, in worktreePath: String) async throws {
        _ = try await processRunner.run(
            "/bin/sh",
            arguments: ["-c", command],
            workingDirectory: worktreePath
        )
    }

    /// Find worktree path for a branch in git worktree list --porcelain output
    private func findWorktreePath(forBranch branch: String, in output: String) -> String? {
        // git worktree list --porcelain format:
        // worktree /path/to/worktree
        // HEAD abc123...
        // branch refs/heads/branch-name
        // <blank line>

        let blocks = output.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
            var path: String?
            var branchName: String?

            for line in lines {
                if line.hasPrefix("worktree ") {
                    path = String(line.dropFirst("worktree ".count))
                } else if line.hasPrefix("branch refs/heads/") {
                    branchName = String(line.dropFirst("branch refs/heads/".count))
                }
            }

            if branchName == branch, let path = path {
                return path
            }
        }

        return nil
    }

    /// Parse git worktree list --porcelain output
    private func parseWorktreeList(_ output: String, repoPath: String) -> [Worktree] {
        // git worktree list --porcelain format:
        // worktree /path/to/worktree
        // HEAD abc123...
        // branch refs/heads/branch-name
        // <blank line>
        // worktree /path/to/another
        // HEAD def456...
        // branch refs/heads/another-branch

        var worktrees: [Worktree] = []
        let blocks = output.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.components(separatedBy: .newlines)
            var path: String?
            var branchName: String?

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("worktree ") {
                    path = String(trimmed.dropFirst("worktree ".count))
                } else if trimmed.hasPrefix("branch refs/heads/") {
                    branchName = String(trimmed.dropFirst("branch refs/heads/".count))
                }
            }

            // Only add if we have both path and branch (skip detached HEAD)
            if let path = path, let branch = branchName {
                worktrees.append(Worktree(path: path, branchName: branch))
            }
        }

        return worktrees
    }
}
