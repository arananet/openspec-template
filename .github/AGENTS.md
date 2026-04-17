# AI Agent Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.
Every feature must have a spec file before code is written.

## Core Rules

1. No production code without a spec. Check `.openspec/specs/` before implementing anything.
2. Every spec must have a `test_plan` section before status moves to `review`.
3. Write tests alongside the implementation — not as a follow-up.
4. Do not merge a spec in `draft` status with production code.

## Coding Guidelines (Karpathy)

These apply on every implementation task, alongside the OpenSpec process.

**Think Before Coding**
- State assumptions explicitly before writing code. If uncertain, ask — don't guess.
- If multiple interpretations of a spec exist, present them. Don't pick silently.
- If something is unclear, stop and name what's confusing.

**Simplicity First**
- Write the minimum code that satisfies each `acceptance_criteria` item. Nothing more.
- No unrequested abstractions, configurability, or error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**Surgical Changes**
- Touch only what the spec requires. Don't improve adjacent code that isn't broken.
- Match existing style. Remove only orphans your own changes created.
- Every changed line must trace to an acceptance criterion in the spec.

**Goal-Driven Execution** *(OpenSpec handles this)*
- `acceptance_criteria` = success criteria. `test_plan` = verification steps.
- Both must be present and met before a PR is opened.

---

## Quick Commands

```bash
# Check if a spec exists
ls .openspec/specs/

# Create a spec for a new feature
gh openspec scaffold "<feature-name>"

# Create a bugfix spec
gh openspec scaffold "<bug-description>" --type bugfix

# Validate all specs
gh openspec check

# Check spec coverage for a PR
gh openspec check --pr <number>
```

## Spec File Location

`.openspec/specs/<slug>.spec.yaml`

## Onboarding

If `.openspec/config.yaml` contains `{{` placeholder tokens, the project has
not been configured yet. Read `CLAUDE.md` for the guided setup flow.

## CI Layers

Two complementary CI workflows run on every PR:

| Workflow | Type | What it checks |
|---|---|---|
| `spec-check.yml` | Deterministic | Field presence, valid status, spec exists for source changes |
| `spec-ai-review.yml` | Agentic (AI) | Semantic alignment — does the code satisfy the acceptance criteria and test_plan? |

The AI review posts a comment on the PR. It is advisory — the deterministic check is the gate.

## Config

`.openspec/config.yaml` — controls enforcement levels, required spec fields,
CI behavior, git hook settings, and agentic review options.
