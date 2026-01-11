# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Canopy** is a macOS menu bar application (Swift/SwiftUI) for managing Git worktrees. It enables developers to quickly switch between worktrees and launch Claude Code sessions in each.

## Build Commands

```bash
cd app/Canopy

# Compile Swift code
swift build

# Bundle as macOS app (requires swift-bundler via mint)
~/.mint/bin/swift-bundler bundle

# Run the bundled app
open .build/bundler/Canopy.app
```

### Prerequisites
```bash
brew install mint
mint install stackotter/swift-bundler
```

## Architecture

### App Structure
```
app/Canopy/
├── Package.swift          # Swift Package (macOS 14+, swift-tools-version 5.9)
├── Bundler.toml           # swift-bundler config (LSUIElement=1 for menu bar only)
└── Sources/Canopy/
    ├── CanopyApp.swift    # @main entry - MenuBarExtra + Settings/NewWorktree windows
    ├── Models/
    │   ├── AppState.swift # @Observable state container (repos, worktrees, settings)
    │   ├── Repository.swift
    │   └── Worktree.swift
    ├── Views/
    │   ├── MenuBarMenuView.swift    # Dropdown menu content
    │   ├── MenuBarContentView.swift
    │   ├── WorktreeRowView.swift    # Individual worktree row
    │   ├── SettingsView.swift       # Repository management, hooks, launch at login
    │   └── NewWorktreeView.swift    # Branch name input dialog
    └── Services/
        ├── WorktreeService.swift # Git worktree operations (list, add, remove)
        ├── ProcessRunner.swift   # Async Process execution
        └── SettingsService.swift # UserDefaults persistence
```

### Data Flow
- **AppState** holds all app state and is passed via SwiftUI `@Environment`
- **WorktreeService** executes `git worktree` commands via ProcessRunner
- **SettingsService** persists repositories and preferences to UserDefaults
- Worktree list auto-refreshes when menu opens; dirty status checked in parallel

### Key Patterns
- Menu bar app uses `MenuBarExtra` (no dock icon via `LSUIElement=1`)
- State management via `@Observable` macro (requires macOS 14+)
- Launch at login via `SMAppService`
- Warp integration opens new window at worktree path via URL scheme: `warp://action/new_window?path=<path>`

## Git Worktree Commands

The app uses pure `git worktree` commands:

| Command | Purpose |
|---------|---------|
| `git worktree list --porcelain` | List worktrees (machine-readable) |
| `git worktree add <path> -b <branch> [<ref>]` | Create worktree |
| `git worktree remove <path> [--force]` | Remove worktree |
| `git config canopy.hook.postCreate <path>` | Set post-create hook |

Worktrees are created at `<repo>-worktrees/<branch>/` (sibling to the main repo).

Hook config key: `canopy.hook.postCreate`

## Releasing a Version

### Prerequisites
```bash
brew install create-dmg
```

### Build Release DMG
```bash
./scripts/build-release.sh
```

This script:
1. Generates the app icon (`AppIcon.icns`) and DMG background
2. Builds the app bundle with `swift-bundler`
3. Creates a DMG installer at `dist/Canopy-Installer.dmg`

### Individual Scripts
| Script | Purpose |
|--------|---------|
| `scripts/build-release.sh` | Full release build (icon + app + DMG) |
| `scripts/generate-icon.sh` | Generate app icon and DMG background |
| `scripts/create-dmg.sh` | Create DMG from existing app bundle |

### Icon Generator
The app icon is generated programmatically via `app/Canopy/Tools/IconGenerator/`. To regenerate just the icon:
```bash
./scripts/generate-icon.sh
```

### Unsigned App Note
The app is not code-signed. Users must right-click and select "Open" on first launch to bypass Gatekeeper.
