import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showingNewWorktree = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Repository header
            HStack {
                Text("Repository:")
                    .foregroundStyle(.secondary)
                Text(appState.selectedRepository?.name ?? "None selected")
                    .fontWeight(.medium)
                Spacer()
                SettingsLink {
                    Image(systemName: "gear")
                }
                .buttonStyle(.hover)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Worktrees section
            if appState.selectedRepository != nil {
                Text("Worktrees:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                if appState.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                        Spacer()
                    }
                    .padding()
                } else if appState.worktrees.isEmpty {
                    Text("No worktrees found")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                } else {
                    ForEach(appState.worktrees) { worktree in
                        WorktreeRowView(worktree: worktree)
                    }
                }
            } else {
                Text("Select a repository in Settings")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            Divider()

            // New worktree button
            Button {
                showingNewWorktree = true
            } label: {
                Label("New Worktree", systemImage: "plus")
            }
            .buttonStyle(.hoverMenu)
            .disabled(appState.selectedRepository == nil)

            Divider()

            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Canopy")
            }
            .buttonStyle(.hoverMenu)
        }
        .frame(width: 280)
        .sheet(isPresented: $showingNewWorktree) {
            NewWorktreeView()
                .environment(appState)
        }
        .task {
            await appState.refreshWorktrees()
        }
    }
}
