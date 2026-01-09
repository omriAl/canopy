# gtr CLI Reference

> Git Worktree Runner - A cross-platform CLI for git worktree management
> Repository: https://github.com/coderabbitai/git-worktree-runner

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `git gtr list` | List all worktrees |
| `git gtr new <branch>` | Create new worktree |
| `git gtr rm <branch>` | Remove worktree |
| `git gtr ai <branch>` | Launch AI tool (Claude) in worktree |
| `git gtr go <branch>` | Get worktree path |

---

## Commands

### `git gtr list`

Display all worktrees with branch and status information.

```bash
# Human-readable output
git gtr list

# Machine-readable output (for parsing in Swift)
git gtr list --porcelain
```

**Options:**
- `--porcelain` - Output in machine-readable format

---

### `git gtr new <branch>`

Create a new worktree. The branch name becomes the folder identifier.

```bash
# Basic usage
git gtr new feature-auth

# Create from current branch
git gtr new feature-auth --from-current

# Create from specific ref
git gtr new feature-auth --from main

# Open in editor after creation
git gtr new feature-auth --editor
git gtr new feature-auth -e

# Launch AI tool after creation
git gtr new feature-auth --ai
git gtr new feature-auth -a

# Skip file copying
git gtr new feature-auth --no-copy

# Non-interactive mode
git gtr new feature-auth --yes
```

**Options:**
| Flag | Description |
|------|-------------|
| `--from <ref>` | Initialize from specific reference |
| `--from-current` | Create from current branch |
| `--track <mode>` | Tracking behavior: auto, remote, local, none |
| `--no-copy` | Skip automatic file copying |
| `--no-fetch` | Skip git fetch operation |
| `--force` | Allow same branch in multiple worktrees (requires `--name`) |
| `--name <suffix>` | Custom folder naming |
| `--editor`, `-e` | Open in configured editor after creation |
| `--ai`, `-a` | Launch AI tool after creation |
| `--yes` | Non-interactive mode |

**Worktree Location:**
Worktrees are created in `<repo>-worktrees/<branch-name>/` in the parent directory.

---

### `git gtr rm <branch>`

Remove one or multiple worktrees.

```bash
# Basic removal
git gtr rm feature-auth

# Remove multiple
git gtr rm feature-auth bugfix-123

# Force removal (ignore uncommitted changes)
git gtr rm feature-auth --force

# Skip confirmation prompts
git gtr rm feature-auth --yes

# Also delete the git branch
git gtr rm feature-auth --delete-branch
```

**Options:**
| Flag | Description |
|------|-------------|
| `--delete-branch` | Remove associated git branch |
| `--force` | Force removal even with uncommitted changes |
| `--yes` | Non-interactive mode, skip confirmations |

---

### `git gtr ai <branch>`

Launch AI coding tool in the specified worktree.

```bash
# Use default AI tool (configured via gtr.ai.default)
git gtr ai feature-auth

# Specify AI tool explicitly
git gtr ai feature-auth --ai claude
git gtr ai feature-auth --ai aider

# Pass arguments to the AI tool
git gtr ai feature-auth -- --model opus
```

**Supported AI Tools:**
- `claude` - Claude Code CLI
- `aider` - Aider
- `codex` - OpenAI Codex
- `continue` - Continue
- `copilot` - GitHub Copilot
- `cursor` - Cursor
- `gemini` - Google Gemini
- `opencode` - OpenCode

---

### `git gtr go <branch>`

Output worktree path for shell navigation.

```bash
# Get path
git gtr go feature-auth

# Use with cd (shell substitution)
cd $(git gtr go feature-auth)
```

---

### `git gtr run <branch> <command>`

Execute commands within the worktree directory.

```bash
# Run npm install in worktree
git gtr run feature-auth npm install

# Run tests
git gtr run feature-auth npm test
```

---

### `git gtr editor <branch>`

Open worktree in configured editor.

```bash
# Use default editor
git gtr editor feature-auth

# Specify editor
git gtr editor feature-auth --editor vscode
git gtr editor feature-auth --editor cursor
```

**Supported Editors:**
- `cursor` - Cursor
- `vscode` - VS Code
- `zed` - Zed

---

### `git gtr copy <target>`

Synchronize files from main repository to worktrees.

```bash
# Copy to specific worktree
git gtr copy feature-auth

# Copy to all worktrees
git gtr copy --all

# Dry run (preview only)
git gtr copy feature-auth --dry-run

# Copy specific patterns
git gtr copy feature-auth -- "**/.env.local"
```

---

### `git gtr config`

Manage configuration via git config backend.

```bash
# Get a config value
git gtr config get gtr.editor.default

# Set a config value
git gtr config set gtr.editor.default cursor

# Add to multi-value config
git gtr config add gtr.copy.include "**/.env.example"

# Remove config value
git gtr config unset gtr.hook.postCreate

# List all gtr config
git gtr config list

# Set globally (not per-repo)
git gtr config set gtr.editor.default cursor --global
```

---

### Utility Commands

```bash
# Health check (verify git, editors, AI tools)
git gtr doctor

# List available adapters
git gtr adapter

# Remove stale worktrees
git gtr clean

# Show version
git gtr version
```

---

## Configuration

### Configuration Keys

| Key | Description | Example |
|-----|-------------|---------|
| `gtr.editor.default` | Default editor | `cursor`, `vscode`, `zed` |
| `gtr.ai.default` | Default AI tool | `claude`, `aider` |
| `gtr.copy.include` | File patterns to copy | `**/.env.example` |
| `gtr.copy.exclude` | Patterns to exclude | `**/.env` |
| `gtr.copy.includeDirs` | Directories to include | `node_modules` |
| `gtr.copy.excludeDirs` | Directories to exclude | `node_modules/.cache` |
| `gtr.hook.postCreate` | Post-create hook command | `npm install` |

### Configuration Precedence

1. **Local repo config** (`.git/config`) - highest priority
2. **Repository `.gtrconfig` file**
3. **Global user config** (`~/.gitconfig`) - lowest priority

### `.gtrconfig` File Format

Team configuration file (INI-style) committed to repository:

```ini
[copy]
include = **/.env.example
exclude = **/.env
includeDirs = node_modules
excludeDirs = node_modules/.cache

[hooks]
postCreate = npm install

[defaults]
editor = cursor
ai = claude
```

---

## Hook System

### postCreate Hook

Runs automatically after worktree creation.

**Configure via git config:**
```bash
git gtr config set gtr.hook.postCreate "npm install"
```

**Configure via .gtrconfig:**
```ini
[hooks]
postCreate = npm install
```

**Multiple commands:**
```bash
git gtr config set gtr.hook.postCreate "npm install && npm run build"
```

---

## Output Formats for Swift Parsing

### `git gtr list --porcelain`

Machine-readable format suitable for parsing. Each worktree on a separate line with consistent field ordering.

### Dirty Detection (Standard Git)

Use standard git command for checking uncommitted changes:

```bash
git -C /path/to/worktree status --porcelain
```

- **Empty output** = clean worktree
- **Non-empty output** = uncommitted changes (dirty)

---

## Requirements

- Git 2.5+
- Bash 3.2+

---

## Installation

```bash
git clone https://github.com/coderabbitai/git-worktree-runner.git
cd git-worktree-runner
./install.sh
```

---

## Notes for Canopy Integration

1. **Listing worktrees:** Use `git gtr list --porcelain` for machine-readable output
2. **Creating worktrees:** Use `git gtr new <branch> --yes` for non-interactive creation
3. **Removing worktrees:** Use `git gtr rm <branch> --yes` to skip confirmation; add `--force` if needed
4. **Launching Claude:** Use `git gtr ai <branch>` directly, or get path with `git gtr go <branch>` and open manually
5. **Hook configuration:** Read from git config using `git gtr config get gtr.hook.postCreate`
6. **Special identifier:** `1` references the main repository (not a worktree)
