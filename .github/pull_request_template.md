<!--
Thank you for opening a pull request!

This project enforces spec-driven development. Before submitting, please make
sure:

  1. A matching spec file exists under `.openspec/specs/` with status `review`
     or `approved`.
  2. Every acceptance_criterion in that spec is addressed by this PR.
  3. Every test_plan item has a real test in this PR (not a follow-up).
  4. README / CHANGELOG are updated if behaviour or usage changed.

CI will reject the PR if the spec is missing, tests are missing, or any
required check fails.
-->

## Spec

<!-- Required — link the spec this PR implements. -->
- Spec file: `.openspec/specs/<slug>.spec.yaml`
- Spec status: `draft` | `review` | `approved`
- Related issue: Closes #

## What this PR does

<!-- 1–3 sentences describing the change in plain language. -->

## Acceptance criteria satisfied

<!-- Copy the acceptance_criteria from the spec and check each one off. -->

- [ ] AC1 — …
- [ ] AC2 — …
- [ ] AC3 — …

## Test plan executed

<!-- Copy the test_plan from the spec and check each one off. -->

- [ ] Unit — …
- [ ] Integration — …
- [ ] Manual — …

## Out-of-scope changes

<!-- If this PR touches anything not covered by the spec, justify it here.
     Prefer to split unrelated changes into a separate PR with its own spec. -->

- None

## Docs

- [ ] README.md updated (or not required)
- [ ] CHANGELOG.md updated under `[Unreleased]`
- [ ] SECURITY.md / CONTRIBUTING.md updated (if governance changed)

## Checklist

- [ ] Spec file is included in this PR with status `review` or `approved`.
- [ ] Tests pass locally (`testing.test_command` from `.openspec/config.yaml`).
- [ ] No secrets, credentials, or `.env` files committed.
- [ ] Any new dependencies are necessary and have been license-checked.
- [ ] Any new GitHub Actions are pinned to a commit SHA.
- [ ] I have read and agree to the [Code of Conduct](../CODE_OF_CONDUCT.md).
