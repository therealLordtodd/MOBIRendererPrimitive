# [PROJECT_NAME]

> Claude Code loads this file automatically at the start of every session.

## Quick Start

All project rules, coding standards, and architectural policies are in **`AGENTS.md`** — read it before any implementation work.

Before any **UI work**, read:
1. `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/style-guide-system.md`
2. `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/apple-platform-ui-style-guide.md`
3. `Style Guide/App Style Guide.md` — if this project has local tokens, components, or layout patterns.
4. `Style Guide/LOCAL STYLE GUIDE ADDENDUM.md` — if this project has explicit local deviations.

A local `Style Guide/` directory is optional. If it doesn't exist, use the wiki pages only.
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
| `Style Guide/` | Optional local app style docs layered on top of the wiki source of truth. |
| `Code Review/` | Optional local code review addenda layered on top of the wiki source of truth. |
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

The Foundation Libraries wiki is the source of truth for code review.

- **Pass A** (14 vectors): feature correctness
- **Pass B** (6 vectors): code quality
- **System overview:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-system.md`
- **Process:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-process.md`
- **Vector index:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/indexes/code-review-vectors.md`
- **Local addenda:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-local-addenda.md`
- **Slash command:** `/review`

If `Code Review/LOCAL CODE REVIEW ADDENDUM.md` exists in this project, read it after the wiki docs and apply it as a project-specific modification. Ignore legacy local review copies unless the addendum explicitly revives them.

If asked for a review, findings come first. Prioritize bugs, regressions, risks, and missing tests over summaries.

---
## AI CLI Tools

| Tool | Path |
|------|------|
| Claude Code CLI | `/Users/todd/.local/bin/claude` |
| Codex CLI | `/Users/todd/.local/bin/codex` |
---

## Project Operations

Shared task, support, and onboarding operations now live in the Foundation Libraries wiki.

Read:
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/project-ops-system.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/portfolio-doctrine.md`

Use the wiki page plus any truly local project note instead of duplicated service boilerplate.

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
