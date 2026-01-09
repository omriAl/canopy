import Foundation

final class SettingsService {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let repositories = "canopy.repositories"
        static let selectedRepositoryId = "canopy.selectedRepositoryId"
        static let launchAtLogin = "canopy.launchAtLogin"
        static let terminal = "canopy.terminal"
        static let customCLIPath = "canopy.customCLIPath"
    }

    func loadRepositories() -> [Repository] {
        guard let data = defaults.data(forKey: Keys.repositories),
              let repos = try? JSONDecoder().decode([Repository].self, from: data) else {
            return []
        }
        return repos
    }

    func saveRepositories(_ repositories: [Repository]) {
        guard let data = try? JSONEncoder().encode(repositories) else { return }
        defaults.set(data, forKey: Keys.repositories)
    }

    func loadSelectedRepository(from repositories: [Repository]) -> Repository? {
        guard let idString = defaults.string(forKey: Keys.selectedRepositoryId),
              let id = UUID(uuidString: idString) else {
            return repositories.first
        }
        return repositories.first { $0.id == id } ?? repositories.first
    }

    func saveSelectedRepository(_ repository: Repository?) {
        defaults.set(repository?.id.uuidString, forKey: Keys.selectedRepositoryId)
    }

    func loadLaunchAtLogin() -> Bool {
        defaults.bool(forKey: Keys.launchAtLogin)
    }

    func saveLaunchAtLogin(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.launchAtLogin)
    }

    func loadTerminal() -> Terminal {
        guard let rawValue = defaults.string(forKey: Keys.terminal),
              let terminal = Terminal(rawValue: rawValue) else {
            return .warp
        }
        return terminal
    }

    func saveTerminal(_ terminal: Terminal) {
        defaults.set(terminal.rawValue, forKey: Keys.terminal)
    }

    func loadCustomCLIPath() -> String? {
        defaults.string(forKey: Keys.customCLIPath)
    }

    func saveCustomCLIPath(_ path: String?) {
        defaults.set(path, forKey: Keys.customCLIPath)
    }
}
