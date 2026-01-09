import Foundation

/// Represents a single status check on a PR
struct StatusCheck: Equatable {
    let name: String
    let conclusion: CheckConclusion

    enum CheckConclusion: String, Equatable {
        case success = "SUCCESS"
        case failure = "FAILURE"
        case pending = "PENDING"
        case skipped = "SKIPPED"
        case cancelled = "CANCELLED"
        case neutral = "NEUTRAL"
        case actionRequired = "ACTION_REQUIRED"
        case timedOut = "TIMED_OUT"
        case unknown

        init(from string: String?) {
            guard let string = string else {
                self = .pending
                return
            }
            self = CheckConclusion(rawValue: string) ?? .unknown
        }
    }
}

/// Represents PR information for a worktree branch
struct PRInfo: Equatable {
    let number: Int
    let url: URL
    let state: PRState
    let mergeable: MergeableStatus
    let statusChecks: [StatusCheck]

    enum PRState: String, Equatable {
        case open = "OPEN"
        case closed = "CLOSED"
        case merged = "MERGED"

        init(from string: String) {
            self = PRState(rawValue: string) ?? .open
        }
    }

    enum MergeableStatus: String, Equatable {
        case mergeable = "MERGEABLE"
        case conflicting = "CONFLICTING"
        case unknown = "UNKNOWN"

        init(from string: String) {
            self = MergeableStatus(rawValue: string) ?? .unknown
        }
    }

    // MARK: - Computed Properties

    var passedChecks: Int {
        statusChecks.filter { $0.conclusion == .success }.count
    }

    var totalChecks: Int {
        statusChecks.count
    }

    var checksAllPassed: Bool {
        totalChecks > 0 && passedChecks == totalChecks
    }

    var hasFailedChecks: Bool {
        statusChecks.contains { $0.conclusion == .failure }
    }

    var hasPendingChecks: Bool {
        statusChecks.contains { $0.conclusion == .pending }
    }

    /// Returns true if all checks are either success or skipped (effectively passing)
    var isEffectivelyPassing: Bool {
        totalChecks > 0 && statusChecks.allSatisfy {
            $0.conclusion == .success || $0.conclusion == .skipped
        }
    }

    var isOpen: Bool {
        state == .open
    }

    var isMerged: Bool {
        state == .merged
    }
}
