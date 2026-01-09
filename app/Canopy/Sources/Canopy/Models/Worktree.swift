import Foundation

struct Worktree: Identifiable, Equatable {
    let id: String
    let path: String
    let branchName: String
    var isDirty: Bool
    var prInfo: PRInfo?

    init(path: String, branchName: String, isDirty: Bool = false, prInfo: PRInfo? = nil) {
        self.id = path
        self.path = path
        self.branchName = branchName
        self.isDirty = isDirty
        self.prInfo = prInfo
    }
}
