# AI Agent Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.
Every feature must have a spec file before code is written.

## Core Rules

1. No production code without a spec. Check `.openspec/specs/` before implementing anything.
2. Every spec must have a `test_plan` section before status moves to `review`.
3. Write tests alongside the implementation — not as a follow-up.
4. Do not merge a spec in `draft` status with production code.

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
