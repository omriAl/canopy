import SwiftUI
import Observation
import ServiceManagement

@Observable
final class AppState {
    private let settingsService = SettingsService()
    private let worktreeService = WorktreeService()
    private let githubService = GitHubService()
    let processManager = ProcessManager()

    var repositories: [Repository] = []
    var selectedRepository: Repository?
    var worktrees: [Worktree] = []
    var isLoading = false
    var launchAtLogin = false
    var selectedTerminal: Terminal = .warp
    var customCLIPath: String?
    private var isRefreshing = false

    // GitHub PR status
    var ghError: GitHubError?
    var showGHError = true

    init() {
        loadSettings()
        syncLaunchAtLoginState()
        // Trigger initial worktree refresh
        Task {
            await refreshWorktrees()
        }
    }

    func loadSettings() {
        repositories = settingsService.loadRepositories()
        selectedRepository = settingsService.loadSelectedRepository(from: repositories)
        launchAtLogin = settingsService.loadLaunchAtLogin()
        selectedTerminal = settingsService.loadTerminal()
        customCLIPath = settingsService.loadCustomCLIPath()
    }

    func selectRepository(_ repo: Repository) {
        selectedRepository = repo
        settingsService.saveSelectedRepository(repo)
        Task {
            await refreshWorktrees()
        }
    }

    func addRepository(at path: String) {
        let name = URL(fileURLWithPath: path).lastPathComponent
        let repo = Repository(path: path, name: name)
        repositories.append(repo)
        settingsService.saveRepositories(repositories)

        if selectedRepository == nil {
            selectRepository(repo)
        }
    }

    func removeRepositories(at indexSet: IndexSet) {
        let removingSelected = indexSet.contains { repositories[$0].id == selectedRepository?.id }
        repositories.remove(atOffsets: indexSet)
        settingsService.saveRepositories(repositories)

        if removingSelected {
            selectedRepository = repositories.first
            if let selected = selectedRepository {
                settingsService.saveSelectedRepository(selected)
            }
        }
    }

    func updateRepositoryHook(_ repository: Repository, hookPath: String?) {
        if let index = repositories.firstIndex(where: { $0.id == repository.id }) {
            repositories[index].postCreateHookPath = hookPath
            settingsService.saveRepositories(repositories)

            // Update selected repository if it's the one being modified
            if selectedRepository?.id == repository.id {
                selectedRepository = repositories[index]
            }

            // Configure the hook in git config
            Task {
                do {
                    if let path = hookPath {
                        try await worktreeService.setPostCreateHook(path, in: repository.path)
                    } else {
                        try await worktreeService.clearPostCreateHook(in: repository.path)
                    }
                } catch {
                    await AlertService.shared.showError(
                        title: "Failed to Configure Hook",
                        message: "Could not save the post-create hook.\n\nError: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    func updateRepositoryBaseBranch(_ repository: Repository, baseBranch: String?) {
        if let index = repositories.firstIndex(where: { $0.id == repository.id }) {
            repositories[index].baseBranch = baseBranch
            settingsService.saveRepositories(repositories)

            // Update selected repository if it's the one being modified
            if selectedRepository?.id == repository.id {
                selectedRepository = repositories[index]
            }
        }
    }

    func updateRepositoryRunCommand(_ repository: Repository, runCommand: String?) {
        if let index = repositories.firstIndex(where: { $0.id == repository.id }) {
            repositories[index].runCommand = runCommand
            settingsService.saveRepositories(repositories)

            // Update selected repository if it's the one being modified
            if selectedRepository?.id == repository.id {
                selectedRepository = repositories[index]
            }
        }
    }

    // MARK: - Process Management

    func startProcess(for worktree: Worktree) throws {
        guard let repo = selectedRepository,
              let command = repo.runCommand else { return }
        try processManager.start(command: command, in: worktree.path)
    }

    func stopProcess(for worktree: Worktree) {
        processManager.stop(worktreePath: worktree.path)
    }

    func restartProcess(for worktree: Worktree) throws {
        guard let repo = selectedRepository,
              let command = repo.runCommand else { return }
        try processManager.restart(command: command, in: worktree.path)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        settingsService.saveLaunchAtLogin(enabled)

        // Register or unregister with macOS login items
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert the setting on failure
            launchAtLogin = !enabled
            settingsService.saveLaunchAtLogin(!enabled)

            Task { @MainActor in
                AlertService.shared.showError(
                    title: "Failed to Update Login Item",
                    message: "Could not \(enabled ? "enable" : "disable") launch at login.\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }

    func setSelectedTerminal(_ terminal: Terminal) {
        selectedTerminal = terminal
        settingsService.saveTerminal(terminal)
    }

    func setCustomCLIPath(_ path: String?) {
        customCLIPath = path
        settingsService.saveCustomCLIPath(path)
    }

    /// Sync the launch at login state with the actual system state
    func syncLaunchAtLoginState() {
        let status = SMAppService.mainApp.status
        let isEnabled = (status == .enabled)
        if launchAtLogin != isEnabled {
            launchAtLogin = isEnabled
            settingsService.saveLaunchAtLogin(isEnabled)
        }
    }

    @MainActor
    func refreshWorktrees() async {
        // Skip if refresh already in progress
        guard !isRefreshing else { return }

        guard let repo = selectedRepository else {
            worktrees = []
            return
        }

        isRefreshing = true
        isLoading = true
        defer {
            isLoading = false
            isRefreshing = false
        }

        do {
            worktrees = try await worktreeService.listWorktrees(in: repo.path)
            // Refresh cached URLs from CANOPY_URL.txt files
            processManager.refreshURLs(for: worktrees.map { $0.path })
            // Fetch PR info for all worktrees
            await refreshPRInfo(for: repo.path)
        } catch {
            // Keep existing data on error instead of clearing
            AlertService.shared.showError(
                title: "Failed to Load Worktrees",
                message: "Could not list worktrees for \(repo.name).\n\nError: \(error.localizedDescription)"
            )
        }
    }

    @MainActor
    private func refreshPRInfo(for repoPath: String) async {
        // First check gh CLI status
        if let error = await githubService.checkGHStatus() {
            ghError = error
            return
        }

        let branches = worktrees.map { (branch: $0.branchName, worktreePath: $0.path) }
        let (prInfoMap, error) = await githubService.fetchPRInfoBatch(branches: branches, in: repoPath)

        // Update worktrees with PR info
        for index in worktrees.indices {
            worktrees[index].prInfo = prInfoMap[worktrees[index].path]
        }

        // Update error state
        if let error = error {
            ghError = error
        } else {
            ghError = nil
        }
    }

    func dismissGHError() {
        showGHError = false
    }

    func resetGHError() {
        showGHError = true
        ghError = nil
    }

    @MainActor
    func createWorktree(branch: String) async throws {
        guard let repo = selectedRepository else { return }

        let baseBranch = repo.effectiveBaseBranch
        try await worktreeService.fetchRemoteBranch(baseBranch, in: repo.path)
        try await worktreeService.createWorktree(branch: branch, from: baseBranch, in: repo.path)

        await refreshWorktrees()

        // Find the new worktree
        guard let newWorktree = worktrees.first(where: { $0.branchName == branch }) else { return }

        // Launch terminal in the new worktree FIRST
        launchWorktree(newWorktree)

        // Small delay to let terminal window appear before hook runs
        try? await Task.sleep(for: .milliseconds(500))

        // Run post-create hook if configured
        if let hookCommand = repo.postCreateHookPath {
            do {
                try await worktreeService.runPostCreateHook(hookCommand, in: newWorktree.path)
                NotificationService.shared.showSuccess(
                    title: "Worktree Ready",
                    message: "Setup complete for '\(branch)'"
                )
            } catch {
                NotificationService.shared.showError(
                    title: "Worktree Setup Failed",
                    message: "Setup failed for '\(branch)': \(error.localizedDescription)"
                )
            }
        }
    }

    @MainActor
    func removeWorktree(_ worktree: Worktree) async throws {
        guard let repo = selectedRepository else { return }
        try await worktreeService.removeWorktree(branch: worktree.branchName, force: worktree.isDirty, in: repo.path)
        await refreshWorktrees()
    }

    func launchWorktree(_ worktree: Worktree) {
        guard let repo = selectedRepository else { return }

        do {
            try worktreeService.launchAI(branch: worktree.branchName, in: repo.path, terminal: selectedTerminal)
        } catch {
            Task { @MainActor in
                AlertService.shared.showError(
                    title: "Failed to Launch Worktree",
                    message: "Could not open '\(worktree.branchName)' in \(selectedTerminal.displayName).\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }
}
