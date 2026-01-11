# Canopy

A lightweight macOS menu bar app for managing Git worktrees.

## Why Canopy?

If you've ever worked with AI coding assistants like Claude Code, you know the drill: you're deep into a feature branch when a critical bug comes in, or you want to explore an alternative approach without losing your current context. Git worktrees are the perfect solution—they let you have multiple working directories for the same repository, each on a different branch.

But managing worktrees from the command line gets tedious fast:

```bash
git worktree add ../my-repo-worktrees/feature-x -b feature-x origin/main
cd ../my-repo-worktrees/feature-x
claude  # or whatever you run to start coding
# ... later ...
git worktree remove ../my-repo-worktrees/feature-x
```

Multiply this by several parallel coding sessions, and you're spending more time managing worktrees than actually coding.

**Canopy** puts all of this in your menu bar. One click to create a worktree and launch your terminal. One click to open an existing worktree. Visual indicators show you which branches have uncommitted changes and which have open PRs. When you're done, remove the worktree with a single action.

## Features

### Worktree Management
- **List all worktrees** for your repositories at a glance
- **Create new worktrees** with a simple branch name input—Canopy handles the path conventions
- **Remove worktrees** with smart confirmation (only warns when there are uncommitted changes)
- **Dirty indicators** show which worktrees have uncommitted changes (parallel status checks for speed)

### Terminal Integration
- **One-click launch** opens your preferred terminal directly in the worktree directory
- Supports **Warp** and **iTerm2**
- Perfect for spinning up new Claude Code sessions in each worktree

### GitHub Integration
- **PR status badges** show open pull requests for each branch
- **CI status indicators** display check results (passing, failing, pending)
- **Merge conflict detection** warns when PRs have conflicts
- Requires [GitHub CLI](https://cli.github.com/) (`gh`) for PR features

### Post-Create Hooks
- Configure a **shell command to run** after creating a new worktree
- Great for running `npm install`, `bundle install`, or any setup script
- Configured per-repository in Settings

### Additional Features
- **Launch at login** support
- **Multiple repository** management—switch between repos in Settings
- **Native macOS app**—lightweight, fast, and fits right in your menu bar
- No dock icon (menu bar only)

## Getting Started

### Download

Download the latest release from the [Releases](https://github.com/omriAl/canopy/releases) page.

> **Note:** The app is not code-signed. On first launch, right-click the app and select "Open" to bypass Gatekeeper.

### First Run

1. Click the tree icon in your menu bar
2. Open **Settings** (gear icon or `Cmd+,`)
3. Add a repository by clicking **+** and selecting a Git repository folder
4. Back in the menu, you'll see all worktrees for that repository

### Creating a Worktree

1. Click **+ New Worktree** in the menu
2. Enter a branch name
3. Click **Create**

Canopy will:
- Create a new worktree at `<repo>-worktrees/<branch>/` (sibling to your main repo)
- Open your terminal in the new worktree
- Run your post-create hook if configured

### Opening a Worktree

Click the play button next to any worktree to open it in your configured terminal.

### Removing a Worktree

Right-click (or secondary click) on a worktree row and select **Remove**. If the worktree has uncommitted changes, you'll be asked to confirm.

## Configuration

### Settings

Access Settings via the gear icon in the menu or `Cmd+,`:

- **Repositories**: Add, remove, and switch between Git repositories
- **Terminal**: Choose between Warp and iTerm2
- **Post-Create Hook**: Set a command to run after creating worktrees (per-repo)
- **Base Branch**: Configure which remote branch new worktrees are based on (default: `origin/main`)
- **Launch at Login**: Start Canopy automatically when you log in

### GitHub CLI Setup

For PR status features, install and authenticate the GitHub CLI:

```bash
brew install gh
gh auth login
```

## Building from Source

### Prerequisites

```bash
brew install mint
mint install stackotter/swift-bundler
```

### Build

```bash
cd app/Canopy

# Compile
swift build

# Bundle as macOS app
~/.mint/bin/swift-bundler bundle

# Run
open .build/bundler/Canopy.app
```

### Create Release DMG

```bash
brew install create-dmg
./scripts/build-release.sh
# Output: dist/Canopy-Installer.dmg
```

## Requirements

- macOS 14 (Sonoma) or later
- Git (comes with macOS)
- [Warp](https://www.warp.dev/) or [iTerm2](https://iterm2.com/) (for terminal integration)
- [GitHub CLI](https://cli.github.com/) (optional, for PR status features)

## How It Works

Canopy uses native Git commands under the hood:

| Action | Command |
|--------|---------|
| List worktrees | `git worktree list --porcelain` |
| Create worktree | `git worktree add <path> -b <branch> <base>` |
| Remove worktree | `git worktree remove <path> [--force]` |
| Check dirty status | `git status --porcelain` |
| PR info | `gh pr view <branch> --json ...` |

Worktrees are created at `<repo>-worktrees/<branch>/`, keeping them organized as siblings to your main repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Bugs
Open an issue with:
- Your macOS version
- Steps to reproduce the problem
- Expected vs actual behavior
- Screenshots if applicable

### Suggesting Features
Open an issue to discuss your idea before implementing. This helps ensure the feature aligns with the project's goals.

### Submitting Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Ensure the app builds (`swift build` in `app/Canopy/`)
5. Test your changes manually
6. Submit a pull request

Please follow the existing code style and patterns in the codebase.
