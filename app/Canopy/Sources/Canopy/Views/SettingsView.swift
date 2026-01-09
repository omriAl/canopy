import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showingFilePicker = false
    @State private var hookEditingRepository: Repository?
    @State private var hookCommandText: String = ""
    @State private var baseBranchEditingRepository: Repository?
    @State private var baseBranchText: String = ""
    @State private var runCommandEditingRepository: Repository?
    @State private var runCommandText: String = ""

    var body: some View {
        TabView {
            repositoriesTab
                .tabItem {
                    Label("Repositories", systemImage: "folder")
                }

            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .padding()
        .frame(width: 450, height: 380)
    }

    private var repositoriesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Registered Repositories")
                .font(.headline)

            List {
                ForEach(appState.repositories) { repo in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(repo.name)
                                    .fontWeight(.medium)
                                Spacer()
                                if repo.id == appState.selectedRepository?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            Text(repo.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            // Post-create hook configuration
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Post-create command:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    if hookEditingRepository?.id == repo.id {
                                        TextField("e.g. npm install", text: $hookCommandText)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.caption.monospaced())
                                            .onSubmit {
                                                let command = hookCommandText.trimmingCharacters(in: .whitespaces)
                                                appState.updateRepositoryHook(repo, hookPath: command.isEmpty ? nil : command)
                                                hookEditingRepository = nil
                                                hookCommandText = ""
                                            }
                                        Button("Save") {
                                            let command = hookCommandText.trimmingCharacters(in: .whitespaces)
                                            appState.updateRepositoryHook(repo, hookPath: command.isEmpty ? nil : command)
                                            hookEditingRepository = nil
                                            hookCommandText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        Button("Cancel") {
                                            hookEditingRepository = nil
                                            hookCommandText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                    } else {
                                        Text(repo.postCreateHookPath ?? "Not configured")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(repo.postCreateHookPath != nil ? .primary : .tertiary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Button("Edit") {
                                            hookEditingRepository = repo
                                            hookCommandText = repo.postCreateHookPath ?? ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        if repo.postCreateHookPath != nil {
                                            Button {
                                                appState.updateRepositoryHook(repo, hookPath: nil)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.hoverPlain)
                                        }
                                    }
                                }
                            }

                            // Base branch configuration
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Base branch for new worktrees:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    if baseBranchEditingRepository?.id == repo.id {
                                        TextField("e.g. origin/main", text: $baseBranchText)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.caption.monospaced())
                                            .onSubmit {
                                                let branch = baseBranchText.trimmingCharacters(in: .whitespaces)
                                                appState.updateRepositoryBaseBranch(repo, baseBranch: branch.isEmpty ? nil : branch)
                                                baseBranchEditingRepository = nil
                                                baseBranchText = ""
                                            }
                                        Button("Save") {
                                            let branch = baseBranchText.trimmingCharacters(in: .whitespaces)
                                            appState.updateRepositoryBaseBranch(repo, baseBranch: branch.isEmpty ? nil : branch)
                                            baseBranchEditingRepository = nil
                                            baseBranchText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        Button("Cancel") {
                                            baseBranchEditingRepository = nil
                                            baseBranchText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                    } else {
                                        Text(repo.baseBranch ?? "origin/main (default)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(repo.baseBranch != nil ? .primary : .tertiary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Button("Edit") {
                                            baseBranchEditingRepository = repo
                                            baseBranchText = repo.baseBranch ?? ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        if repo.baseBranch != nil {
                                            Button {
                                                appState.updateRepositoryBaseBranch(repo, baseBranch: nil)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.hoverPlain)
                                        }
                                    }
                                }
                            }

                            // Run command configuration
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Run command:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    if runCommandEditingRepository?.id == repo.id {
                                        TextField("e.g. npm run dev", text: $runCommandText)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.caption.monospaced())
                                            .onSubmit {
                                                let command = runCommandText.trimmingCharacters(in: .whitespaces)
                                                appState.updateRepositoryRunCommand(repo, runCommand: command.isEmpty ? nil : command)
                                                runCommandEditingRepository = nil
                                                runCommandText = ""
                                            }
                                        Button("Save") {
                                            let command = runCommandText.trimmingCharacters(in: .whitespaces)
                                            appState.updateRepositoryRunCommand(repo, runCommand: command.isEmpty ? nil : command)
                                            runCommandEditingRepository = nil
                                            runCommandText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        Button("Cancel") {
                                            runCommandEditingRepository = nil
                                            runCommandText = ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                    } else {
                                        Text(repo.runCommand ?? "Not configured")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(repo.runCommand != nil ? .primary : .tertiary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                        Button("Edit") {
                                            runCommandEditingRepository = repo
                                            runCommandText = repo.runCommand ?? ""
                                        }
                                        .font(.caption)
                                        .buttonStyle(.hoverPlain)
                                        if repo.runCommand != nil {
                                            Button {
                                                appState.updateRepositoryRunCommand(repo, runCommand: nil)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                            }
                                            .buttonStyle(.hoverPlain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.selectRepository(repo)
                    }
                }
                .onDelete { indexSet in
                    appState.removeRepositories(at: indexSet)
                }
            }
            .listStyle(.bordered)

            HStack {
                Button("Add Repository...") {
                    showingFilePicker = true
                }
                .buttonStyle(.hoverPlain)
                Spacer()
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result,
               let url = urls.first {
                appState.addRepository(at: url.path)
            }
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terminal")
                .font(.headline)

            Picker("Default terminal app", selection: Binding(
                get: { appState.selectedTerminal },
                set: { appState.setSelectedTerminal($0) }
            )) {
                ForEach(Terminal.allCases, id: \.self) { terminal in
                    Text(terminal.displayName).tag(terminal)
                }
            }
            .pickerStyle(.segmented)

            Text("CLI Path")
                .font(.headline)
                .padding(.top, 8)

            HStack {
                TextField("Custom path (e.g., /usr/local/bin)", text: Binding(
                    get: { appState.customCLIPath ?? "" },
                    set: { appState.setCustomCLIPath($0.isEmpty ? nil : $0) }
                ))
                .textFieldStyle(.roundedBorder)
            }

            Text("Optional: Add path for CLI tools like gh if not in default locations.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Startup")
                .font(.headline)
                .padding(.top, 8)

            Toggle("Launch Canopy at login", isOn: Binding(
                get: { appState.launchAtLogin },
                set: { appState.setLaunchAtLogin($0) }
            ))

            Spacer()

            Divider()

            HStack {
                Text("Canopy v0.1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}
