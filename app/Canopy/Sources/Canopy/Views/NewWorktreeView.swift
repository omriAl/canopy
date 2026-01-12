import SwiftUI

struct NewWorktreeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var branchName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @FocusState private var isBranchNameFocused: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Worktree")
                    .font(.headline)

                TextField("Branch name", text: $branchName)
                    .textFieldStyle(.roundedBorder)
                    .focused($isBranchNameFocused)
                    .disabled(isCreating)
                    .onSubmit {
                        createWorktree()
                    }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.hoverPlain)
                    .keyboardShortcut(.cancelAction)
                    .disabled(isCreating)

                    Button("Create") {
                        createWorktree()
                    }
                    .buttonStyle(.hoverPlain)
                    .keyboardShortcut(.defaultAction)
                    .disabled(branchName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .opacity(isCreating ? 0.3 : 1.0)
            .allowsHitTesting(!isCreating)

            if isCreating {
                TreeLoadingView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isCreating)
        .padding()
        .frame(minWidth: 300, maxWidth: 400)
        .onAppear {
            branchName = ""
            errorMessage = nil
            isBranchNameFocused = true
        }
    }

    private func createWorktree() {
        let trimmedName = branchName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await appState.createWorktree(branch: trimmedName)
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                    NotificationService.shared.showError(
                        title: "Failed to Create Worktree",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}
