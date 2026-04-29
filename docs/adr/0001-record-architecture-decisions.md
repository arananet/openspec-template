# ADR 0001: Record Architecture Decisions

**Date:** 2026-01-01
**Status:** Accepted

---

## Context

AI agents can implement features quickly, but they have no persistent memory of
*why* a particular approach was chosen over alternatives. Human developers share
the same problem — but with more confidence and less RAM.

Without a lightweight record of decisions, future contributors (human or AI) must
reverse-engineer intent from code, leading to repeated debates, inconsistent
extensions, and regressions that undo intentional trade-offs.

## Decision

We will use Architecture Decision Records (ADRs), stored in `docs/adr/`, to
capture decisions that are significant enough to be worth explaining to a future
reader.

Each ADR is a short Markdown file with the following structure:

```
# ADR NNNN: <title>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR NNNN

---

## Context
<Why this decision was needed. What forces are at play.>

## Decision
<What was decided and why. Be specific.>

## Consequences
<What becomes easier. What becomes harder. Any trade-offs accepted.>
```

ADRs are numbered sequentially and never deleted. A superseded ADR is marked
`Superseded by ADR NNNN` and a new ADR explains the replacement.

## Consequences

- New decisions take 5–15 minutes to document.
- Future contributors (including AI agents) have a searchable record of intent.
- Decisions are easy to find: one directory, sequential filenames.
- The record is append-only — no history is lost when decisions change.

---

## When to write an ADR

Write one when you:

- Choose a framework, library, or tool over a concrete alternative.
- Reject an approach that looks obvious (explain why).
- Accept a trade-off that will surprise a future reader.
- Make a cross-cutting architectural change that affects more than one component.

Skip it for implementation details, style choices, or decisions that are obvious
from the code.
