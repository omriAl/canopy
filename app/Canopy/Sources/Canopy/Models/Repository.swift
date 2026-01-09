import Foundation

struct Repository: Identifiable, Codable, Equatable {
    let id: UUID
    let path: String
    let name: String
    var postCreateHookPath: String?
    var baseBranch: String?
    var runCommand: String?

    var effectiveBaseBranch: String {
        baseBranch ?? "origin/main"
    }

    init(path: String, name: String, postCreateHookPath: String? = nil, baseBranch: String? = nil, runCommand: String? = nil) {
        self.id = UUID()
        self.path = path
        self.name = name
        self.postCreateHookPath = postCreateHookPath
        self.baseBranch = baseBranch
        self.runCommand = runCommand
    }
}
