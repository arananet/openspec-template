# AI Agent Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.
**No production code without a spec.** This rule applies to every AI
agent operating in this repo (Codex CLI, Claude Code, Copilot, etc.).

The full workflow is in [`docs/OPENSPEC.md`](../docs/OPENSPEC.md). The
absolute minimum you need to know is below.

---

## Hard rules — refuse the request if any of these is violated

1. **No source-file edits without a corresponding spec change.**
   If `.openspec/specs/` does not have a matching `<slug>.spec.yaml`,
   stop and ask the user to scaffold one first:

   ```bash
   scripts/openspec scaffold "<feature name>"          # feature
   scripts/openspec scaffold "<bug summary>" --type bugfix
   ```

2. **Spec must be in `review` or `approved` status before code.**
   `draft` specs are not implementation-ready. Refuse to write code
   and ask the user to fill in `description`, `acceptance_criteria`,
   and `test_plan` first.

3. **Every spec needs ≥1 `acceptance_criteria` item and ≥1 `test_plan`
   item.** Both before code, both updated together with code.

4. **Tests land in the same PR as the source change.** Not as a
   follow-up issue, not in a separate commit, not "later".

5. **Only touch what the spec requires.** Each changed line should
   trace to an `acceptance_criteria` item. When in doubt, ask the user.

6. **Update user-facing docs.** If your change affects behaviour, touch
   `README.md`, `CHANGELOG.md`, or a file under `docs/` in the same PR.
   The `doc-drift.yml` CI check enforces this.

The structural enforcement (`hooks/pre-commit`, `spec-check.yml`,
`spec-ai-review.yml`, `doc-drift.yml`) catches violations after the
fact. Catch them before pushing — read the spec first.

---

## Coding guidelines (Karpathy)

These four principles complement OpenSpec — `acceptance_criteria` and
`test_plan` already enforce **Goal-Driven Execution**.

**Think Before Coding**
- State assumptions explicitly before writing code. If uncertain, ask.
- If multiple interpretations of a spec exist, present them. Don't
  pick silently.
- If something is unclear, stop and name what's confusing.

**Simplicity First**
- Write the minimum code that satisfies each `acceptance_criteria`
  item. Nothing more.
- No unrequested abstractions, configurability, or error handling for
  impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**Surgical Changes**
- Touch only what the spec requires. Don't improve adjacent code that
  isn't broken.
- Match existing style. Remove only orphans your own changes created.

---

## Quick command reference

```bash
ls .openspec/specs/                                       # what specs exist
scripts/openspec scaffold "<feature-name>"                # new feature spec
scripts/openspec scaffold "<bug-description>" --type bugfix
scripts/openspec check                                    # validate every spec
scripts/openspec check --strict                           # treat draft as failure
scripts/openspec check --pr <number>                      # PR coverage check
```

Specs live at `.openspec/specs/<slug>.spec.yaml`. Templates are in
`.openspec/templates/`. The CLI is `scripts/openspec` — pure bash, no
external dependencies.

---

## When `.openspec/config.yaml` has `{{PLACEHOLDER}}` tokens

The repo is freshly forked from the template and onboarding has not
run yet. Direct the user to open the project in Claude Code (which
reads [`CLAUDE.md`](../CLAUDE.md) and walks them through the interview),
or to edit `.openspec/config.yaml` manually. Do not write production
code until placeholders are resolved.

---

## CI layers your output is graded against

| Workflow | Type | What it checks |
|---|---|---|
| `spec-check.yml` | Deterministic | Spec exists for source changes; required fields present |
| `spec-ai-review.yml` | Agentic (AI) | Does the code actually satisfy the acceptance criteria? |
| `doc-drift.yml` | Deterministic | Source changes touched README / CHANGELOG / docs |
| `lint.yml` | Deterministic | actionlint, yamllint, shellcheck, markdownlint |
| `dco.yml` | Deterministic | Every commit has `Signed-off-by:` (use `git commit -s`) |
| `codeql.yml` / `secret-scan.yml` / `dependency-review.yml` | Security | SAST, secrets, vuln deps |

Aim to pass all of them on the first push. The deterministic checks
are the gate; the agentic review is advisory but graded.

---

## Config

`.openspec/config.yaml` controls enforcement levels, required spec
fields, CI behaviour, git-hook settings, and agentic review options
(including the `cost_guard` daily-run caps on AI workflows). Read it
before suggesting any cross-cutting change.
