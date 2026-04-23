# [PROJECT_NAME]

> Claude Code loads this file automatically at the start of every session.

## Quick Start

All project rules, coding standards, and architectural policies are in **`AGENTS.md`** — read it before any implementation work.

Before any **UI work**, also read:
1. `Style Guide/Unified Standards.md` — Cross-app rules. **Read first.**
2. `Style Guide/App Style Guide.md` — App-specific tokens and components.
3. `Style Guide/platform-notes/Apple Apps.md` — If building for Apple platforms.
   - **Canonical cross-project version:** `/Users/todd/Programming/Vantage/Style Guide/platform-notes/Apple Apps.md`

---

## Project Overview

[PROJECT_DESCRIPTION]

**Tech stack:** [TECH_STACK]

| App | Repository | Local Path |
|-----|-----------|------------|
| **[APP_NAME]** | [REPO_URL] | `[LOCAL_PATH]` |

## GitHub Repository Visibility

- New GitHub repositories always start out as **private**.
- Do not create, publish, or leave a repository public unless Todd explicitly asks for that repository to be public.

---

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `Style Guide/` | Mandatory design system docs. Read before any UI work. |
| `Code Review/` | Two-pass review system (15 vectors). Reviews run daily+. |
| `docs/plans/` | Design documents and implementation plans. |
| `docs/project-constitution.md` | Foundational decisions and their reasoning. Update when making hard-to-reverse choices. |

---

## Critical Rules (Always Follow)

### Code Quality
- Use **`[LOG_FACADE]`** for all logging — never `print()`
- **Hard deletes allowed by default** — use soft delete only when a feature explicitly requires retention/rollback semantics
- **All mutations** go through the mutation logging system
- **Build** the project before handing off work: `[BUILD_COMMAND]`
- If the app has an in-app status/error panel, implement and preserve all three log maintenance controls:
`Clear Current Log`, `Reset Log History`, and `Clear Status Panel` (with destructive actions confirmed via `.alert`)

### Design System
- **Never use raw color values** — always use `[DESIGN_TOKEN_PREFIX]Colors` tokens
- **Never use raw font modifiers** — always use `[DESIGN_TOKEN_PREFIX]Typography` tokens
- **Never use raw spacing values** — always use `[DESIGN_TOKEN_PREFIX]Spacing` tokens
- **Every button** has an explicit button style — no unstyled buttons

---

## Workflow Style

Direct collaboration between Todd and Claude on the active branch. No git worktrees unless explicitly requested.

### Session-End Commit Check

**Before ending any session**, run `git status` in the project repo. If there are uncommitted changes, commit them before wrapping up. Uncommitted work accumulating across sessions is a recurring problem — don't let it happen.

---

## Code Review Process

Two-pass, 15-vector review system:
- **Pass A** (8 vectors): Feature correctness
- **Pass B** (7 vectors): Code quality

Process: `Code Review/CODE REVIEW PROCESS.md`
Slash command: `/review`

---

## AI CLI Tools

| Tool | Path |
|------|------|
| Claude Code CLI | `/Users/todd/.local/bin/claude` |
| Codex CLI | `/Users/todd/.local/bin/codex` |
---

## Plane API

Full reference: **`~/.claude/plane-api.md`**

> **Pages require session auth, not API keys.** See `~/.claude/plane-api.md` for the session auth procedure.

---

## Zammad API

Full reference: **`~/.claude/zammad-api.md`**

Support VM SSH: `ssh todd@support.toddcowing.com`

---

## Continuity Engine — Persistent Memory

This project uses the Continuity Engine for persistent AI memory across sessions.

**Session lifecycle is automatic** — the `/session-start` and `/session-end` skills handle context loading and session recording.

### During Sessions

- Use `/remember` to store important decisions, discoveries, dead ends, and preferences immediately — don't wait until session end
- Use `/recall` to search past memories before making decisions that may have been made before
- Use `/session-end` when wrapping up (or when Todd signals he's done)
- Before any compact, thread handoff, or close-out, do a final memory pass first: commit any missing non-trivial memories with `/remember`, then run `/session-end`
- Treat that final memory pass as part of shutdown procedure, not optional cleanup after the fact

### Context-Loss Checkpoints

Context rollovers (compaction) can happen at any time without warning — there is no pre-compaction signal. To protect against memory loss:

- **After completing each major task or milestone**, immediately `/remember` the outcome, approach taken, and any non-obvious decisions — don't batch these for session end
- **Before dispatching subagents or starting context-heavy operations**, record what you've accomplished so far and what remains — these operations consume large amounts of context and increase rollover risk
- **After any commit**, record a brief memory if the committed work involved non-obvious decisions or patterns worth preserving
- **Think of `/remember` as a save point in a game** — save often, especially before boss fights (big operations). You can't predict when the power will go out.

### What to Record

After solving a non-trivial problem, making a decision, hitting a dead end, or discovering something non-obvious — record it immediately with `/remember`. The session-end audit is a safety net, not the primary recording mechanism.

- **Decisions** — why X was chosen over Y
- **Dead ends** — what was tried and didn't work
- **Discoveries** — non-obvious things about the codebase or tools
- **Preferences** — user workflow conventions (use `--space preference`)

Don't record trivial details, things obvious from reading the code, or temporary debugging state.

---

## Primitives-First Development

**Before building any new feature or component**, check `/Users/todd/Programming/Packages/` for existing primitives and kits that already solve part of the problem. Browse the directory listing — the names are descriptive.

**During every design and implementation task**, actively ask: *"Are parts of what I'm building legitimate candidates for new primitives or kits in the shared library?"* If yes, extract them. We are aggressively growing this shared library through real app development. Every app is both a consumer of primitives and a proving ground that justifies their existence with real usage and bug testing.
