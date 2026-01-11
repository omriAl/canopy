import SwiftUI

struct MenuBarMenuView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            headerSection

            // GitHub error banner (if any)
            if let error = appState.ghError, appState.showGHError, error.shouldShowBanner {
                ghErrorBanner(error)
            }

            Divider()

            // Worktrees section
            worktreesSection

            Divider()

            // Footer actions
            footerSection
        }
        .frame(width: 320)
        .task {
            appState.resetGHError()
            await appState.refreshWorktrees()
        }
    }

    private func ghErrorBanner(_ error: GitHubError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))

            Text(error.userMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            Button {
                appState.dismissGHError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Repository")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.selectedRepository?.name ?? "None selected")
                    .fontWeight(.medium)
            }
            Spacer()
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.hover)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var worktreesSection: some View {
        if appState.selectedRepository != nil {
            if appState.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                    Spacer()
                }
                .padding()
            } else if appState.worktrees.isEmpty {
                Text("No worktrees")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(appState.worktrees) { worktree in
                            WorktreeRow(worktree: worktree)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        } else {
            Text("Select a repository in Settings")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 0) {
            // New Worktree button
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "new-worktree")
            } label: {
                Label("New Worktree...", systemImage: "plus")
            }
            .buttonStyle(.hoverMenu)
            .disabled(appState.selectedRepository == nil)

            // Refresh button
            Button {
                Task {
                    await appState.forceRefreshWorktrees()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.hoverMenu)

            Divider()

            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Canopy")
            }
            .buttonStyle(.hoverMenu)
        }
    }
}

// MARK: - Worktree Row

private struct WorktreeRow: View {
    let worktree: Worktree
    @Environment(AppState.self) private var appState
    @State private var isHovering = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isRestarting = false

    private var isRunning: Bool {
        appState.processManager.isRunning(worktreePath: worktree.path)
    }

    private var hasRunCommand: Bool {
        appState.selectedRepository?.runCommand != nil
    }

    private var canopyURL: URL? {
        appState.processManager.getCanopyURL(for: worktree.path)
    }

    private var isMerged: Bool {
        worktree.prInfo?.isMerged ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Primary row: status + branch name + actions
            HStack(spacing: 8) {
                // Status indicator
                statusIndicator

                // Branch name
                Text(isMerged ? "\(worktree.branchName) (merged)" : worktree.branchName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(isMerged ? .secondary : .primary)

                Spacer()

                // Action buttons (visible on hover or when running)
                actionButtons
                    .opacity(isHovering || isRunning ? 1 : 0)
            }

            // Secondary row: PR info (only for open PRs)
            if let prInfo = worktree.prInfo, prInfo.isOpen {
                prInfoRow(prInfo)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        .contentShape(Rectangle())
        .opacity(isDeleting ? 0.5 : 1.0)
        .overlay {
            if isDeleting {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                    Spacer()
                }
            }
        }
        .allowsHitTesting(!isDeleting)
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            contextMenuContent
        }
        .confirmationDialog(
            "Remove worktree '\(worktree.branchName)'?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                removeWorktree()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This worktree has uncommitted changes that will be lost.")
        }
    }

    private func prInfoRow(_ prInfo: PRInfo) -> some View {
        Button {
            NSWorkspace.shared.open(prInfo.url)
        } label: {
            HStack(spacing: 6) {
                // Indent to align with branch name (past the status dot)
                Color.clear.frame(width: 12)

                // GitHub icon + PR number
                GitHubIconView(size: 12, color: .secondary)

                Text("#\(prInfo.number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Status checks badge
                if prInfo.totalChecks > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: checkIconName(for: prInfo))
                            .font(.system(size: 9))
                            .foregroundStyle(checkColor(for: prInfo))

                        Text("\(prInfo.passedChecks)/\(prInfo.totalChecks)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Mergeable indicator
                if prInfo.mergeable == .mergeable {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                } else if prInfo.mergeable == .conflicting {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.red)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .help("Open PR #\(prInfo.number) in browser")
    }

    private func checkIconName(for prInfo: PRInfo) -> String {
        if prInfo.checksAllPassed || prInfo.isEffectivelyPassing {
            return "checkmark.circle.fill"
        } else if prInfo.hasFailedChecks {
            return "xmark.circle.fill"
        }
        // Pending or other incomplete state
        return "clock.circle"
    }

    private func checkColor(for prInfo: PRInfo) -> Color {
        if prInfo.checksAllPassed || prInfo.isEffectivelyPassing {
            return .green
        } else if prInfo.hasFailedChecks {
            return .red
        }
        return .orange
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if isRunning {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
        } else if isMerged {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: worktree.isDirty ? "circle" : "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(worktree.isDirty ? .orange : .green)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
            if isMerged {
                // Show delete button for merged PRs
                Button {
                    if worktree.isDirty {
                        showingDeleteConfirmation = true
                    } else {
                        removeWorktree()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                }
                .buttonStyle(.hover)
                .foregroundStyle(.red)
                .help("Delete worktree (PR merged)")
            } else {
                // Run/Stop control (only if runCommand configured)
                if hasRunCommand {
                    if isRunning {
                        Button {
                            appState.stopProcess(for: worktree)
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.hover)
                        .help("Stop running process")

                        Button {
                            restartProcess()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .rotationEffect(.degrees(isRestarting ? 360 : 0))
                                .animation(isRestarting ? .linear(duration: 0.5).repeatForever(autoreverses: false) : .default, value: isRestarting)
                        }
                        .buttonStyle(.hover)
                        .help("Restart process")
                        .disabled(isRestarting)
                    } else {
                        Button {
                            startProcess()
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.hover)
                        .help("Run configured command")
                    }
                }

                // Open Link button (only when running and URL available)
                if isRunning, let url = canopyURL {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.hover)
                    .help("Open in browser")
                }

                // Open in terminal
                Button {
                    appState.launchWorktree(worktree)
                } label: {
                    Image(systemName: "terminal")
                        .font(.system(size: 14))
                }
                .buttonStyle(.hover)
                .help("Open in terminal")
            }
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        if hasRunCommand {
            if isRunning {
                Button("Stop") {
                    appState.stopProcess(for: worktree)
                }
                Button("Restart") {
                    restartProcess()
                }
            } else {
                Button("Run") {
                    startProcess()
                }
            }

            if let url = canopyURL, isRunning {
                Button("Open Link") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()
        }

        Button("Open in Terminal") {
            appState.launchWorktree(worktree)
        }

        Divider()

        Button("Remove Worktree", role: .destructive) {
            if worktree.isDirty {
                showingDeleteConfirmation = true
            } else {
                removeWorktree()
            }
        }
    }

    // MARK: - Actions

    private func startProcess() {
        do {
            try appState.startProcess(for: worktree)
        } catch {
            Task { @MainActor in
                AlertService.shared.showError(
                    title: "Failed to Start Process",
                    message: "Could not start process for '\(worktree.branchName)'.\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }

    private func restartProcess() {
        isRestarting = true
        do {
            try appState.restartProcess(for: worktree)
            // Brief delay so user sees the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isRestarting = false
            }
        } catch {
            isRestarting = false
            Task { @MainActor in
                AlertService.shared.showError(
                    title: "Failed to Restart Process",
                    message: "Could not restart process for '\(worktree.branchName)'.\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }

    private func removeWorktree() {
        isDeleting = true
        Task {
            do {
                try await appState.removeWorktree(worktree)
            } catch {
                isDeleting = false
                AlertService.shared.showError(
                    title: "Failed to Remove Worktree",
                    message: "Could not remove '\(worktree.branchName)'.\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }
}
