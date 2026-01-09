# TASK-001: Research gtr CLI Commands & Integration

**Status:** Completed
**Added:** 2026-01-08
**Updated:** 2026-01-08
**Blocks:** SPEC-canopy-app (Phase 2: Core Features) - UNBLOCKED

---

## Objective

Research the `gtr` (Git Worktree Runner) CLI tool to document:
1. Available commands for worktree lifecycle (list, add, remove)
2. Exact command syntax and options
3. Hook system (`gtr.hook.postCreate`) configuration
4. Output formats (for parsing in Swift)
5. Error codes and messages

---

## Deliverables

- [x] Document gtr CLI command reference → [docs/gtr-cli-reference.md](./docs/gtr-cli-reference.md)
- [x] Document hook configuration mechanism → included in reference
- [x] Identify any limitations or edge cases → Warp URL scheme cannot execute commands
- [x] Update SPEC-canopy-app.md with concrete command examples → done

---

## Research Sources

- gtr GitHub repository / README
- `gtr --help` output
- Any existing documentation or wiki

---

## Implementation Plan

1. Search for gtr repository online
2. Fetch and review documentation
3. Document findings in `/tasks/docs/gtr-cli-reference.md`
4. Update main spec with concrete implementation details

---

## Progress Tracking

**Overall Status:** Completed - 100%

### Subtasks

| ID | Description | Status | Updated | Notes |
|----|-------------|--------|---------|-------|
| 1.1 | Find gtr repository/docs | Complete | 2026-01-08 | Found at github.com/coderabbitai/git-worktree-runner |
| 1.2 | Document list command | Complete | 2026-01-08 | `git gtr list --porcelain` |
| 1.3 | Document add command | Complete | 2026-01-08 | `git gtr new <branch>` |
| 1.4 | Document remove command | Complete | 2026-01-08 | `git gtr rm <branch>` |
| 1.5 | Document hook system | Complete | 2026-01-08 | `gtr.hook.postCreate` in git config |
| 1.6 | Update main spec | Complete | 2026-01-08 | Added commands, resolved questions |

---

## Progress Log

#### 2026-01-08
- Task created
- Identified as blocker for Phase 2 implementation
- Found gtr repository: https://github.com/coderabbitai/git-worktree-runner
- Documented all CLI commands in docs/gtr-cli-reference.md
- Researched Warp URL scheme - found limitation (no command execution)
- Updated SPEC-canopy-app.md with concrete implementation details
- Resolved all open questions
- **Task completed** - Phase 2 is now unblocked
