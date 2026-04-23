# [PROJECT_NAME] — Project Constitution

**Created:** [YYYY-MM-DD]
**Authors:** [HUMAN_NAME] + [AI_MODEL]

This document records the *why* behind foundational decisions. It is written for future collaborators — human and AI — who weren't in the room when these choices were made. The development plan tells you what we're building. AGENTS.md tells you how to build it. This document tells you why we made the decisions we made, and where we believe this is going.

Fill in the project-specific sections as decisions are made. The **Founding Principles** apply to every project in the portfolio without exception — they are the intent behind the work. The **Portfolio-Wide Decisions** are pre-filled conventional choices that follow from those principles; they apply unless explicitly overridden here with a documented reason.

---

## What [PROJECT_NAME] Is Trying to Be

*Write 2–4 sentences. What problem does this solve? Who is it for — humans, AIs, or both? What is the central insight that makes it worth building?*

[FILL IN]

---

## Foundational Decisions

### Shared Portfolio Doctrine

The shared founding principles and portfolio-wide defaults now live in the Foundation Libraries wiki:

- `/Users/todd/Library/CloudStorage/GoogleDrive-todd@cowingfamily.com/My Drive/The Commons/Libraries/Foundation Libraries/operations/portfolio-doctrine.md`

Use this local constitution for project-specific decisions, not copied portfolio boilerplate.

---

### Project-Specific Decisions

*Add an entry here for every significant architectural, tooling, or directional decision made for this project. Write it at decision time, not retroactively. Future collaborators need to understand the reasoning, not just the outcome.*

*Template for each entry:*

#### [Decision Title]

**Decision:** [One sentence stating what was decided.]

**Why:** [The reasoning. What alternatives were considered? What made this the right call for this project at this time? What would cause us to revisit it?]

**Trade-offs accepted:** [What are we giving up? What assumptions does this depend on?]

---

*Add more entries as decisions are made.*

---

## Tech Stack and Platform Choices

**Platform:** [iOS / macOS / watchOS / web / cross-platform / etc.]
**Primary language:** [Swift / Python / TypeScript / etc.]
**UI framework:** [SwiftUI / UIKit / React / etc.]
**Data layer:** [SQLite / Postgres / CoreData / etc.]

**Why this stack:** [The reasoning. If it's obvious (SwiftUI for a new iOS app), one sentence is fine. If it's a meaningful choice, explain the trade-offs.]

---

## Who This Is Built For

*Who are the primary users or operators of this software? Humans, AI agents, or both? This shapes everything from UI density to conductorship defaults.*

[ ] Primarily humans
[ ] Primarily AI agents
[ ] Both, roughly equally
[ ] Both — humans build it, AIs operate it
[ ] Both — AIs build it, humans operate it

**Notes:** [Any nuance on the audience that affects design decisions.]

---

## Where This Is Going

*Write 2–3 sentences. What does a mature version of this project look like? What capabilities does it eventually have that it doesn't have today? What would make this project a success in 2 years?*

[FILL IN]

---

## Open Questions

*Record known unknowns here. These are not gaps in the plan — they are questions that will resolve through use, and future collaborators should know they were intentionally deferred.*

- [Question 1]
- [Question 2]

*Remove entries as questions resolve; add a brief note to the relevant Foundational Decision entry when they do.*

---

## Amendment Process

Use this process whenever a foundational decision changes or a new decision is added.

1. Update the relevant section in this constitution in the same change as the code/docs that motivated the update.
2. For each new or changed decision entry, include:
   - **Decision**
   - **Why**
   - **Trade-offs accepted**
   - **Revisit trigger** (what condition should cause reconsideration)
3. Add a matching row in the **Decision Log** with date and a concise summary.
4. If the amendment changes implementation rules, update `AGENTS.md` and any affected style guide files in the same change.
5. Record who approved the amendment (human + AI collaborator when applicable).

Minor wording clarifications that do not change meaning do not require a new decision entry, but should still be noted in the Decision Log.

---

## Decision Log

*Brief chronological record of significant decisions. Add an entry whenever a non-trivial decision is made that isn't already captured in the sections above.*

| Date | Decision | Decided by |
|------|----------|------------|
| [YYYY-MM-DD] | [Brief description] | [Human / AI / Both] |
