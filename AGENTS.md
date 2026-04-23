# [PROJECT_NAME] — AI Agent Instructions

Be direct, concise, and blunt. Go beyond surface meaning. Anticipate intent. Fix documentation and clarity issues proactively. Act as an intellectual collaborator, not a tool.

---

## Project Overview

[PROJECT_DESCRIPTION]

**Tech stack:** [TECH_STACK]

## Repositories & Local Paths

| App | Repository | Local Path |
|-----|-----------|------------|
| **[APP_NAME]** | [REPO_URL] | `[LOCAL_PATH]` |

## GitHub Repository Visibility

- New GitHub repositories always start out as **private**.
- Do not create, publish, or leave a repository public unless Todd explicitly asks for that repository to be public.

## Project Directory Structure

```
[PROJECT_NAME]/         ← Project root
├── AGENTS.md           ← This file — AI agent instructions
├── CLAUDE.md           ← Claude Code auto-loaded config
├── Code Review/        ← Optional project-specific review addenda
├── Style Guide/        ← Optional local app style profile and addenda
└── docs/plans/         ← Design docs and implementation plans
```

---

## Project Operations

The Foundation Libraries wiki is the source of truth for shared project-operations guidance.

Read:
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/project-ops-system.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/portfolio-doctrine.md`

Project-local docs should not duplicate the shared support / task / onboarding doctrine. Keep only project-specific operational exceptions or identifiers locally.

---

## Build Policy

Before handing off any implementation work, build the project and report the result.

**Build command:** `[BUILD_COMMAND]`
**Style check command:** `bash scripts/style_check.sh`

All Apple app targets should include a `Style Check` Run Script build phase that executes:
`STYLE_CHECK_STRICT="${STYLE_CHECK_STRICT:-0}" "$SRCROOT/scripts/style_check.sh" "$SRCROOT"`

---

## Logging Requirement

All logging must use the project's centralized logging facade (`[LOG_FACADE]`). Never use `print()` or raw logging APIs.

> **Diagnostics and logging baseline:** Apple host apps should follow `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/apple-platform-observability-baseline.md` together with this project's logging facade requirements. Build the observability surface before writing feature code when the app owns meaningful runtime state.

**Categories:**

| Logger | Use for |
|--------|---------|
| `[LOG_FACADE].db` | Database queries, fetches, writes, connection lifecycle |
| `[LOG_FACADE].auth` | Login, logout, credential storage |
| `[LOG_FACADE].ui` | User-facing actions: navigation, clipboard, window events |
| `[LOG_FACADE].network` | HTTP/REST calls, external API interactions |
| `[LOG_FACADE].app` | App lifecycle, startup, shutdown, migrations |
| `[LOG_FACADE].ai` | AI chat, tool calls, provider API interactions |

**Levels:**
- `.info` — Normal operations
- `.warning` — Recoverable issues
- `.error` — Failures
- `.debug` — Verbose debug detail (do not commit to main)

**Pattern — log at entry AND outcome for any fallible operation:**
```
[LOG_FACADE].db.info("Fetching records.")
do {
    let result = try await fetch()
    [LOG_FACADE].db.info("Fetched records.", metadata: ["count": result.count])
} catch {
    [LOG_FACADE].db.error("Failed to fetch.", metadata: ["error": error.localizedDescription])
}
```

**Never log:** passwords, tokens, API keys, or PII beyond what's needed for debugging.

**Required Logs settings controls (macOS template baseline):**
- `Clear Current Log` — truncates only the active rolling log file.
- `Reset Log History` — deletes all log files and recreates the active log file.
- `Clear Status Panel` — clears in-app `ErrorLog` entries only (no file deletion).
- Use `.alert` confirmations for destructive actions and log each action through `[LOG_FACADE].ui`.

---

## Data Integrity Policy

### Hard Deletes Allowed (Default)

Hard deletes are allowed by default for this app. Use soft-delete patterns only when a specific feature requires retention, undo, or audit-preservation semantics.

When a feature requires soft delete, document that behavior explicitly in the feature spec and data model notes.

### Mutation Logging

All database writes must go through the project's mutation logging system. No direct writes that bypass audit capture.

---

## Testing System

The Foundation Libraries wiki is the source of truth for shared testing doctrine.

Read:
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/testing-system.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/post-coding-testing.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/post-coding-ui-testing.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/visual-sweep-doctrine.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/testing-audit-prompt.md`
- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/testing-historical-perspectives.md`

Keep only truly local testing harness notes in project docs.

---

## Code Review Process

The Foundation Libraries wiki is the source of truth for code review.

- **System overview:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-system.md`
- **Process:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-process.md`
- **Vector index:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/indexes/code-review-vectors.md`
- **Local addenda:** `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/code-review-local-addenda.md`
- **Slash command:** `/review`

Run the standard two-pass, 20-vector review system from the wiki:
- **Pass A** (14 vectors): feature correctness
- **Pass B** (6 vectors): code quality

If this project has `Code Review/LOCAL CODE REVIEW ADDENDUM.md`, read it after the wiki docs and treat it as a project-specific modification to the standard review. Do not use legacy local vector copies as authority unless the local addendum explicitly says to.

If asked for a review, findings come first. Prioritize bugs, regressions, risks, and missing tests over summaries.

**Model attribution:** Every review finding recorded in the current issue/task system must include the reviewing model in the description, e.g. `Reviewed by: Anthropic / claude-sonnet-4-6`

---
## Style Guide System

The Foundation Libraries wiki is the source of truth for style guidance.

Before UI work, read:

1. `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/style-guide-system.md`
2. `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/apple-platform-ui-style-guide.md`
3. `Style Guide/App Style Guide.md` — if the project has local tokens, components, or layout patterns.
4. `Style Guide/LOCAL STYLE GUIDE ADDENDUM.md` — if the project has explicit local deviations.

A local `Style Guide/` directory is optional. Do not treat legacy local `Unified Standards.md` or `platform-notes/*` copies as authority.

### UI Tokenization Rule (from Day 1)

All visual styling must be tokenized from the beginning of the project.

- No raw visual values in production UI code: colors, fonts, spacing, radii, borders, shadows, opacity, animation durations/curves, and layout constants.
- Define and consume centralized design tokens (for example: color, typography, spacing, corner radius, motion, component sizing).
- Keep local token and component documentation in `Style Guide/App Style Guide.md` when the project owns a real app-specific design system.
- When introducing or changing styles, update tokens first and update the local style guide in the same change when the project has one.


## UI Element Naming Convention

This is a first-class rule. Follow it in every View and ViewModel.

### The Pattern

Every interactive element the user touches is a **named computed property** on the View (not anonymous inline):

```swift
// WRONG — anonymous, ungrepable
TextField("Search clients...", text: $searchQuery)

// RIGHT — named, grep-able, referable in natural language
private var clientNameSearchField: some View {
    TextField("Search clients...", text: $searchQuery)
        .textFieldStyle(.roundedBorder)
}
```

### Canonical Element Type Suffixes

| Suffix | Control | Natural Language Example |
|--------|---------|--------------------------|
| `TextField` | Single-line text input | "the project name text field" |
| `TextEditor` | Multi-line text input | "the notes text editor" |
| `SearchField` | Text input used as search/filter | "the client name search field" |
| `Dropdown` | Picker with discrete options | "the status dropdown" |
| `Toggle` | Boolean toggle | "the auto-run toggle" |
| `DatePicker` | Date/time picker | "the due date picker" |
| `Stepper` | Numeric stepper | "the count stepper" |
| `Slider` | Numeric slider | "the volume slider" |
| `Button` | Named button (when stored as var) | "the save button" |
| `Table` | Data table | "the results table" |
| `List` | Scrollable list | "the items list" |
| `Tab` | Tab/segment control | "the active tab" |
| `Segment` | Segmented control (alias) | — |

### Naming Rules

1. **No abbreviations.** `projectNameTextField` not `projNameTF`.
2. **camelCase.** Data object first, then property, then element type.
3. **Context prefix** when the same type appears in multiple sections: `headerClientSearchField` vs `sidebarClientSearchField`.
4. **Elements group under `// MARK: -` sections** naming their screen section — this is how the AI locates elements by natural language.
5. **Every ViewModel** exposes a `uiElementContext: String` computed property listing interactive elements and their current values.

### `uiElementContext` Pattern

```swift
var uiElementContext: String {
    """
    screen: [ScreenName]
    section: [SectionName]
      [elementName]: "[currentValue]"
    section: [OtherSection]
      [elementName]: \(someValue)
    """
}
```

This is injected into the AI panel alongside schema and logs so the AI always knows the full UI state when you ask a question.

---

## Project Constitution

Before making architectural or tooling decisions, read `docs/project-constitution.md`. It records the *why* behind foundational choices made for this project. If you are making a decision that will be hard to reverse, record your reasoning there.

**When to update the constitution:**
- A new tool, framework, or dependency is chosen over an obvious alternative
- An architectural pattern is established that future code must follow
- A significant trade-off is accepted (e.g. simplicity over flexibility)
- An open question listed in the constitution is resolved
- The direction of the project meaningfully changes

Add an entry to the **Decision Log** table at the bottom of the constitution for any decision not already covered by an existing section. For major decisions, add a full named section.

---

## Documentation & Clarity

When you find documentation or clarity issues, fix them proactively without waiting for approval.

---

## Workflow Style

Direct collaboration between Todd and Claude on the active branch. Work directly in the repository unless otherwise specified.


---

## Continuity Engine — Persistent AI Memory

This project uses a shared memory system that persists across sessions and across AI models.
**You should use it.** It knows what was decided before, what failed, and what the user prefers.

### Connection

```
Base URL: http://127.0.0.1:19191
Auth:     X-Engine-Key header (key from ~/.continuity/api-key)
```

Call `GET /health` first to verify the engine is running.
Call `GET /describe` to see all available API methods and their parameters.

### Session Lifecycle

**1. Start session (get context)**
```
POST /session/wrap/start
{"model": "<your-model-id>", "application": "<app-name>", "project": "<project-name>"}
```
Returns `session_id` + `context` (markdown brief of memories, past sessions, preferences, and unresolved conflicts). **Read the context before working** — it prevents re-doing work or contradicting decisions.

**2. Record as you go — don't batch**
After solving a non-trivial problem, making a decision, hitting a dead end, or discovering something non-obvious, store it immediately:
```
POST /memory/remember
{"category": "architecture", "topic": "...", "summary": "...", "model": "<your-model-id>"}
```

Search past decisions:
```
POST /memory/recall
{"query": "cache strategy", "match": "any"}
```

**3. End session**
```
POST /session/wrap/end
{"id": "<session_id>", "summary": "...", "decisions": [...], "discoveries": [...], "deadEnds": [...], "energy": "high|medium|low"}
```

**4. Before compact, handoff, or close-out**
- Do a final memory pass **before** any context compaction, thread wrap-up, or end-of-session handoff.
- If anything non-trivial from the current session has not been recorded yet, commit it with `POST /memory/remember` first.
- Then call `POST /session/wrap/end`.
- Treat this as part of the shutdown checklist, not optional cleanup. Do not wait until after compaction to save important reasoning.

### What to Remember
- **Decisions** — why X was chosen over Y
- **Dead ends** — what was tried and didn't work
- **Discoveries** — non-obvious things about the codebase
- **Preferences** — user style/workflow conventions (use `"space": "preference"`)

Don't record trivial details, things obvious from reading the code, or temporary debugging state.

### Conflicts
Your context may include an "Unresolved Conflicts" section showing disagreements between models. If you have relevant context to weigh in, call:
```
POST /memory/resolveConflict
{"id": "<conflict-id>", "resolution": "a_wins|b_wins|merged|coexist", "reason": "...", "resolvedBy": "<your-model-id>"}
```

---

## Primitives-First Development

**Before building any new feature or component**, check `/Users/todd/Programming/Packages/` for existing primitives and kits that already solve part of the problem. Browse the directory listing — the names are descriptive.

**During every design and implementation task**, actively ask: *"Are parts of what I'm building legitimate candidates for new primitives or kits in the shared library?"* If yes, extract them. We are aggressively growing this shared library through real app development. Every app is both a consumer of primitives and a proving ground that justifies their existence with real usage and bug testing.
