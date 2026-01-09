import SwiftUI

struct WorktreeRowView: View {
    let worktree: Worktree
    @Environment(AppState.self) private var appState
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        HStack(spacing: 8) {
            // Clean/dirty indicator
            Image(systemName: worktree.isDirty ? "circle" : "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(worktree.isDirty ? .orange : .green)

            Text(worktree.branchName)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Launch action button
            Button {
                appState.launchWorktree(worktree)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
            }
            .buttonStyle(.hover)
            .help("Open in terminal")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
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
        .contextMenu {
            Button(role: .destructive) {
                if worktree.isDirty {
                    showingDeleteConfirmation = true
                } else {
                    removeWorktree()
                }
            } label: {
                Label("Remove Worktree", systemImage: "trash")
            }
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

    private func removeWorktree() {
        isDeleting = true
        Task {
            do {
                try await appState.removeWorktree(worktree)
            } catch {
                isDeleting = false
                await AlertService.shared.showError(
                    title: "Failed to Remove Worktree",
                    message: "Could not remove '\(worktree.branchName)'.\n\nError: \(error.localizedDescription)"
                )
            }
        }
    }
}
