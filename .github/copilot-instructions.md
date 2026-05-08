# Copilot Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development. Full
workflow: [`docs/OPENSPEC.md`](../docs/OPENSPEC.md).

## Before suggesting code for any new feature

1. **Check the spec.** Look for `.openspec/specs/<feature>.spec.yaml`.
2. **If no spec exists, surface that first** — do not autocomplete
   production code. Suggest:
   > "I don't see a spec for this. Scaffold one before we add code:
   > `scripts/openspec scaffold '<feature-name>'`"
3. **If the spec is in `draft` status, surface that too** — code should
   not land while the spec is still being shaped.
4. **Use `acceptance_criteria` as the definition of done.** Each line
   you suggest should map to a criterion in the spec.
5. **Always pair the source change with a test.** The spec's
   `test_plan` lists what to cover; tests must land in the same PR.
6. **If the change is user-facing, suggest a README/CHANGELOG/docs
   touch alongside it.** The `doc-drift.yml` CI check fails the PR
   otherwise.
7. **Use `git commit -s`** so commits carry a `Signed-off-by:` trailer
   (DCO check, see `.github/workflows/dco.yml`).

Copilot autocompletes — it doesn't refuse — so the structural gates
(pre-commit hook, `spec-check.yml`, `doc-drift.yml`, `dco.yml`) are
what enforce these rules at commit / PR time.

## Spec files

- Location: `.openspec/specs/*.spec.yaml`
- Templates: `.openspec/templates/{feature,bugfix}.spec.yaml`
- CLI: `scripts/openspec` (bash + coreutils, no external deps)
- Config: `.openspec/config.yaml`

## Unconfigured project

If `.openspec/config.yaml` contains `{{PLACEHOLDER}}` tokens, the repo
was just forked from the template and onboarding has not run. Direct
the user to open the project in Claude Code or edit `.openspec/config.yaml`
manually before any non-trivial code suggestion.
