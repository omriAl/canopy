# Canopy - Task Index

## Active Tasks

| ID | Task | Status | Updated | Notes |
|----|------|--------|---------|-------|
| SPEC-canopy-app | Application Specification | In Progress | 2026-01-08 | Phase 1 & 2 complete, Phase 3 partial |
| TASK-001 | gtr CLI Research | Completed | 2026-01-08 | ✅ Documented in docs/gtr-cli-reference.md |

---

## Task Dependencies

```
TASK-001 (gtr Research) ✅ COMPLETE
    │
    └──▶ SPEC-canopy-app Phase 1 & 2 ✅ COMPLETE
              │
              └──▶ Phase 3 (Enhancements) ⏳ PARTIAL
                      │ ✅ Warp integration (opens at path)
                      │ ⏳ Dirty indicators, hooks, launch at login
                      │
                      └──▶ Phase 4 (Polish)
```

---

## Quick Links

- [Full Specification](./SPEC-canopy-app.md)
- [gtr Research Task](./TASK-001-gtr-research.md)
- [gtr CLI Reference](./docs/gtr-cli-reference.md)
- [App Source Code](../app/Canopy/)

## Build & Run

```bash
cd app/Canopy
/Users/omri.alon/.mint/bin/swift-bundler bundle
open .build/bundler/Canopy.app
```
