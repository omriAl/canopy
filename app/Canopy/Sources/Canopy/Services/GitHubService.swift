import Foundation

/// Error types for GitHub CLI operations
enum GitHubError: Error, Equatable {
    case ghNotInstalled
    case notAuthenticated
    case noPRForBranch
    case rateLimited
    case parseError(String)
    case apiError(String)

    var userMessage: String {
        switch self {
        case .ghNotInstalled:
            return "GitHub CLI not installed. Install via: brew install gh"
        case .notAuthenticated:
            return "GitHub CLI not authenticated. Run: gh auth login"
        case .noPRForBranch:
            return ""
        case .rateLimited:
            return "GitHub API rate limit exceeded. PR info may be stale."
        case .parseError:
            return "Failed to parse GitHub response."
        case .apiError(let message):
            return "GitHub API error: \(message)"
        }
    }

    var shouldShowBanner: Bool {
        switch self {
        case .noPRForBranch:
            return false
        default:
            return true
        }
    }
}

/// Service for fetching PR information via the GitHub CLI
final class GitHubService {
    private let processRunner = ProcessRunner()

    /// Check if gh CLI is available and authenticated
    func checkGHStatus() async -> GitHubError? {
        // Check if gh is installed
        do {
            _ = try await processRunner.run(
                "/usr/bin/env",
                arguments: ["which", "gh"],
                workingDirectory: nil
            )
        } catch {
            return .ghNotInstalled
        }

        // Check if gh is authenticated
        do {
            _ = try await processRunner.run(
                "/usr/bin/env",
                arguments: ["gh", "auth", "status"],
                workingDirectory: nil
            )
        } catch {
            return .notAuthenticated
        }

        return nil
    }

    /// Fetch PR info for a specific branch in a repository
    func fetchPRInfo(branch: String, in repoPath: String) async throws -> PRInfo {
        let output: String
        do {
            output = try await processRunner.run(
                "/usr/bin/env",
                arguments: [
                    "gh", "pr", "view", branch,
                    "--json", "number,state,mergeable,statusCheckRollup,url"
                ],
                workingDirectory: repoPath
            )
        } catch let ProcessRunner.ProcessError.executionFailed(code, message) {
            // gh returns exit code 1 for "no PR found"
            if code == 1 && (message.contains("no pull requests found") ||
                             message.contains("Could not resolve")) {
                throw GitHubError.noPRForBranch
            }
            if message.contains("rate limit") {
                throw GitHubError.rateLimited
            }
            if message.contains("authentication") || message.contains("auth") {
                throw GitHubError.notAuthenticated
            }
            throw GitHubError.apiError(message)
        }

        return try parsePRInfo(from: output)
    }

    /// Fetch PR info for multiple branches in parallel
    /// Returns a dictionary mapping worktree paths to PR info
    func fetchPRInfoBatch(
        branches: [(branch: String, worktreePath: String)],
        in repoPath: String
    ) async -> (results: [String: PRInfo], error: GitHubError?) {
        var firstError: GitHubError?

        let results = await withTaskGroup(of: (String, PRInfo?, GitHubError?).self) { group in
            for (branch, worktreePath) in branches {
                group.addTask {
                    do {
                        let prInfo = try await self.fetchPRInfo(branch: branch, in: repoPath)
                        // Include open and merged PRs (merged PRs shown with special styling)
                        if prInfo.isOpen || prInfo.state == .merged {
                            return (worktreePath, prInfo, nil)
                        }
                        return (worktreePath, nil, nil)
                    } catch let error as GitHubError {
                        return (worktreePath, nil, error)
                    } catch {
                        return (worktreePath, nil, .apiError(error.localizedDescription))
                    }
                }
            }

            var resultMap: [String: PRInfo] = [:]
            for await (path, prInfo, error) in group {
                if let prInfo = prInfo {
                    resultMap[path] = prInfo
                }
                // Capture first displayable error
                if firstError == nil, let error = error, error.shouldShowBanner {
                    firstError = error
                }
            }
            return resultMap
        }

        return (results, firstError)
    }

    private func parsePRInfo(from json: String) throws -> PRInfo {
        guard let data = json.data(using: .utf8) else {
            throw GitHubError.parseError("Invalid JSON encoding")
        }

        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GitHubError.parseError("Expected JSON object")
        }

        guard let number = dict["number"] as? Int,
              let urlString = dict["url"] as? String,
              let url = URL(string: urlString),
              let state = dict["state"] as? String else {
            throw GitHubError.parseError("Missing required fields")
        }

        let mergeable = dict["mergeable"] as? String ?? "UNKNOWN"

        // Parse status checks
        var statusChecks: [StatusCheck] = []
        if let rollup = dict["statusCheckRollup"] as? [[String: Any]] {
            for check in rollup {
                let name = check["name"] as? String ?? check["context"] as? String ?? "Unknown"
                let conclusion = check["conclusion"] as? String ?? check["state"] as? String
                statusChecks.append(StatusCheck(
                    name: name,
                    conclusion: StatusCheck.CheckConclusion(from: conclusion)
                ))
            }
        }

        return PRInfo(
            number: number,
            url: url,
            state: PRInfo.PRState(from: state),
            mergeable: PRInfo.MergeableStatus(from: mergeable),
            statusChecks: statusChecks
        )
    }
}
