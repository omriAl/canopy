# Canopy - Git Worktree Manager for macOS

**Status:** In Progress
**Added:** 2026-01-08
**Updated:** 2026-01-08 (Phase 1, 2, 3 & 4 complete)

---

## Overview

**Canopy** is a lightweight macOS menu bar application that provides a graphical interface for managing Git worktrees via the `gtr` (Git Worktree Runner) CLI tool. The primary goal is to streamline worktree lifecycle management for developers using multiple Claude Code instances across different worktrees.

---

## Core Requirements

### 1. Menu Bar Application
- **Location:** macOS menu bar only (no dock icon)
- **Icon:** Tree icon representing "worktree"
- **Activation:** Click to reveal dropdown menu
- **Target:** macOS 14+ (Sonoma) - leverage latest SwiftUI features

### 2. Worktree Management
| Action | Description |
|--------|-------------|
| **List** | Display all worktrees for the selected repository |
| **Add** | Create new worktree (branch name input only, minimal UI) |
| **Remove** | Delete worktree with smart confirmation (warn only if uncommitted changes) |

### 3. Quick Actions
- **One-click Warp + Claude:** Single action to open Warp terminal at worktree path and automatically run `claude` command
- **Dirty indicator:** Visual icon showing if worktree has uncommitted changes

### 4. Hook System (postCreate)
- **Scope:** Per-repository configuration
- **Type:** Point to existing shell scripts on the filesystem
- **Trigger:** Runs automatically after worktree creation via `gtr.hook.postCreate`

### 5. Repository Management
- **Mode:** Single repository focus at a time
- **Switching:** Configure repos in Settings/Preferences panel
- **Storage:** App preferences via UserDefaults

---

## Technical Specifications

### Technology Stack
| Component | Choice |
|-----------|--------|
| Language | Swift |
| UI Framework | SwiftUI |
| Platform | macOS 14+ (Sonoma) |
| Architecture | Menu bar app (NSStatusItem) |
| CLI Backend | `gtr` (existing CLI tool) |

### Data Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Canopy    │────▶│     gtr     │────▶│  git CLI    │
│  (SwiftUI)  │◀────│   (CLI)     │◀────│             │
└─────────────┘     └─────────────┘     └─────────────┘
```

### Configuration Storage
- **Location:** macOS UserDefaults
- **Contents:**
  - List of registered repositories (paths)
  - Currently selected repository
  - Per-repo postCreate hook script paths
  - Launch at login preference

### gtr Commands Reference

> Full documentation: [docs/gtr-cli-reference.md](./docs/gtr-cli-reference.md)

| Action | Command | Notes |
|--------|---------|-------|
| List worktrees | `git gtr list --porcelain` | Machine-readable output |
| Create worktree | `git gtr new <branch> --yes` | Non-interactive |
| Remove worktree | `git gtr rm <branch> --yes` | Add `--force` if dirty |
| Launch Claude | `git gtr ai <branch>` | Uses configured AI tool |
| Get path | `git gtr go <branch>` | Returns worktree path |
| Check dirty | `git -C <path> status --porcelain` | Empty = clean |

### gtr Hook Configuration
```bash
# Set postCreate hook for current repo
git gtr config set gtr.hook.postCreate "npm install"

# Read hook value
git gtr config get gtr.hook.postCreate
```

---

## User Interface Design

### Menu Bar Dropdown
```
┌────────────────────────────────┐
│ 🌲 Canopy                      │
├────────────────────────────────┤
│ Repository: my-project  [⚙️]   │
├────────────────────────────────┤
│ Worktrees:                     │
│  ● main            [▶️]        │  ← ● = clean
│  ○ feature-auth    [▶️]        │  ← ○ = dirty (uncommitted)
│  ● bugfix-123      [▶️]        │
├────────────────────────────────┤
│ [+ New Worktree]               │
├────────────────────────────────┤
│ Settings...                    │
│ Quit                           │
└────────────────────────────────┘
```

### Actions per Worktree
- **Click [▶️]:** Open Warp terminal at worktree path + run `claude`
- **Right-click / Secondary action:** Context menu with "Remove worktree"

### New Worktree Flow
1. Click "+ New Worktree"
2. Single text field: "Branch name"
3. Click "Create"
4. `gtr` creates worktree → postCreate hook runs if configured

### Settings Panel
- List of registered repositories with add/remove
- Per-repo postCreate script path (file picker)
- "Launch at login" toggle
- About/version info

---

## Behaviors

### Worktree List Refresh
- **Trigger:** Auto-refresh each time menu is opened
- **Method:** Call `git gtr list --porcelain` for machine-readable output

### Dirty Detection
- Check `git status --porcelain` for each worktree
- Display indicator (filled vs hollow dot, or color)

### Error Handling
- **Display:** Native macOS alert dialogs
- **Scenarios:**
  - gtr command failures
  - Permission issues
  - Invalid repository paths

### Missing gtr CLI
- On launch, check if `gtr` is available in PATH
- If missing: Show alert with installation instructions
- Disable worktree operations until installed

### Delete Confirmation Logic
```
if worktree.hasUncommittedChanges {
    show confirmation dialog with warning
} else {
    delete immediately (no confirmation)
}
```

---

## Warp Terminal Integration

### Current Implementation
Opens Warp in a new window at the worktree path using URL scheme:

```swift
func launchClaudeInWarp(at path: String) throws {
    let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
    let warpURL = "warp://action/new_window?path=\(encodedPath)"
    if let url = URL(string: warpURL) {
        NSWorkspace.shared.open(url)
    }
}
```

### Limitations
- **Warp URL scheme does NOT support command execution**
- AppleScript keystrokes require accessibility permissions and don't work reliably from background processes
- `gtr ai` command has issues with claude CLI arguments

### Future Options
1. Wait for Warp to add command execution to URL scheme
2. Use a different terminal (iTerm2 has better AppleScript support)
3. Create a Warp workflow/script that users can trigger

---

## Out of Scope (v1)

- Multiple repositories in single view
- Keyboard shortcuts / global hotkeys
- Notification Center integration
- Auto-install of gtr
- Branch creation from UI (only existing branches)
- Worktree path customization

---

## Implementation Plan

### Phase 1: Foundation ✅ COMPLETE
- [x] Set up Swift Package project (Package.swift + swift-bundler)
- [x] Create basic MenuBarExtra with tree SF Symbol icon
- [x] Implement dropdown menu structure
- [x] Settings window with repository management

### Phase 2: Core Features ✅ COMPLETE
- [x] Integrate with `gtr` CLI (list, add, remove)
- [x] Worktree list display with refresh on open
- [x] New worktree creation flow
- [x] Delete with smart confirmation

### Phase 3: Enhancements ✅ COMPLETE
- [x] Dirty/clean status indicators (parallel git status checks)
- [x] Warp terminal integration (opens new window at worktree path)
- [x] postCreate hook configuration per repo (Settings UI)
- [x] Launch at login functionality (SMAppService integration)
- [~] Auto-run claude command in Warp (blocked by Warp URL scheme limitations)

### Phase 4: Polish ✅ COMPLETE
- [x] Error handling with native alerts (AlertService using NSAlert)
- [~] gtr availability check on launch (skipped - gtr being replaced)
- [x] App icon and branding (using SF Symbol tree.fill)
- [x] Testing and bug fixes

---

## Resolved Questions

> **Research completed in [TASK-001](./TASK-001-gtr-research.md)**
> Full reference: [docs/gtr-cli-reference.md](./docs/gtr-cli-reference.md)

1. **gtr CLI commands:** ✅ RESOLVED
   - List: `git gtr list --porcelain`
   - Add: `git gtr new <branch> [--from-current] [--yes]`
   - Remove: `git gtr rm <branch> [--force] [--yes]`
   - AI: `git gtr ai <branch>`

2. **Warp URL scheme:** ✅ RESOLVED
   - URL scheme: `warp://action/new_tab?path=<path>`
   - **No command execution support** - use gtr's `git gtr ai <branch>` instead

3. **Dirty check performance:** Recommend async/background
   - Use `git -C <path> status --porcelain` per worktree
   - Run checks in parallel on background thread

---

## Building & Running

### Prerequisites
```bash
# Install swift-bundler via mint
brew install mint
mint install stackotter/swift-bundler
```

### Build Commands
```bash
cd app/Canopy

# Compile only
swift build

# Bundle as macOS app
~/.mint/bin/swift-bundler bundle

# App bundle location
.build/bundler/Canopy.app
```

### Running the App
```bash
# Launch directly from build
open .build/bundler/Canopy.app

# Or copy to Applications and launch
cp -R .build/bundler/Canopy.app ~/Applications/
open ~/Applications/Canopy.app
```

### Accessing Canopy
- **Menu bar:** Look for the tree icon (🌲) in the macOS menu bar
- **Settings:** Click the gear icon in the dropdown, or use Cmd+,
- **First run:** Add a repository in Settings > Repositories

---

## Notes

- Keep the app lightweight - it's a quick-access tool, not a full Git client
- Prioritize speed of common actions (open claude in worktree)
- The target user is a developer managing multiple Claude Code sessions across worktrees
