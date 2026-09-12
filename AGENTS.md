# Agent Instructions

This repository uses OpenSpec. These are the shared rules for all agents;
host-specific instructions link here instead of maintaining separate policies.

## Route the Task

- For questions and read-only reviews, inspect relevant files and report
  evidence. Do not start onboarding or create a spec just to answer a question.
- For explicitly requested template maintenance, preserve placeholders and
  template-internal specs. Do not run onboarding or cleanup on the template.
- Before taking an issue, check its auto-fix label, open PRs, and workflow runs.
  Reuse an existing agent draft PR; do not race an active run or bypass an
  agent's documented refusal. See [auto-fix](docs/OPENSPEC.md#issue-auto-fix-agent-opt-in).
- For downstream implementation, check `.openspec/config.yaml`. If it contains
  `{{` tokens, follow [onboarding](docs/ONBOARDING.md) and confirm values before
  writing them. Missing config is an error, not proof that setup is complete.
  Any capable agent can guide onboarding.

## OpenSpec Contract

1. Find the matching `.openspec/specs/<slug>.spec.yaml` before source edits.
   If none exists, scaffold one with `bash scripts/openspec scaffold "<name>"`
   (add `--type bugfix` for a bugfix). Clarify scope with the user.
2. Implement only when status is `review` or `approved`, with a meaningful
   description, at least one acceptance criterion, and at least one test-plan
   item. Never promote a draft merely to bypass this gate.
3. Keep changes within the spec. Include the corresponding spec change and
   tests with implementation; tests belong in the same PR, not a follow-up.
   Existing specs can be updated instead of creating duplicate specs.
4. Update README, CHANGELOG, or relevant docs when behavior or usage changes.
   For internal-only changes, explain any `skip-doc-drift` request to a maintainer.
  Use Mermaid for diagrams unless the user explicitly requests another format.
5. Preserve security checks, human approvals, and branch protection. An AI
   review is advisory, never proof of correctness or permission to merge.

## Small, Verifiable Steps

- Start from relevant code or a failing test. State assumptions that affect
  behavior and resolve ambiguity before implementing it.
- For a small change, the spec's acceptance criteria and test plan are enough.
  Do not require an extra plan document, ADR, specialist, or agent handoff.
- For larger changes, implement one testable slice at a time. Run the cheapest
  relevant check immediately, then expand validation to the affected contract.
- Prefer existing utilities and simple code. Add abstractions only when they
  remove demonstrated complexity. Do not clean up unrelated code.
- Role names describe responsibilities, not a minimum team size. A solo
  maintainer may hold multiple roles where project policy permits. Never
  fabricate role assignments or approval; honor configured review requirements.
- Load only the applicable spec, nearby code/tests, and relevant references.
  If `implementation_skill` (or the configured default) names a skill, load
  its actual instructions. Mentioning its name is not invoking it. If unavailable,
  report that and agree on a fallback rather than pretending it ran.
- Delegate only when authorized and useful for independent work. Preserve the
  user's changes. Do not install skills, commit, push, or enable paid services
  without authorization. Use `git commit -s` when asked to commit.

## Verification and Handoff

- Run `bash scripts/openspec check`; use `--strict` when all specs must be
  implementation-ready. Run the configured `testing.test_command` with its
  required environment, plus focused checks for the changed behavior.
- For template maintenance, use `check --template` and `make test-template`.
- For downstream work, run `verify <slug>` and inspect `status <slug>` before
  reporting completion. See [execution](docs/EXECUTION.md); automation is opt-in,
  and passing command evidence does not prove every acceptance criterion.
- Report acceptance criteria met, commands run and results, and anything not
  verified. Do not claim tests, security reviews, or deployments happened
  without evidence. Pause on failures; do not weaken checks to make them pass.

See [OpenSpec](docs/OPENSPEC.md) for the schema and lifecycle,
[adoption](docs/ADOPTION.md) for optional capabilities and known gate limits,
and [branch protection](docs/BRANCH_PROTECTION.md) before changing required checks.
