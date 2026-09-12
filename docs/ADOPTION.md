# Adopting OpenSpec Without Extra Ceremony

## Assessment

The template is enterprise-capable scaffolding, not a verified enterprise
control system. Its sustainable core is the local CLI, versioned specs,
acceptance criteria, same-PR tests, and deterministic checks. Keep that core.
More workflows do not automatically mean stronger guarantees.

The previous agent entry points duplicated policy and loaded an entire
onboarding interview and badge catalog for ordinary changes. Codex's rules
were under `.github/` rather than at the repository root. Responsibilities
looked like a four-person staffing requirement, and AI review ran without
honoring its enable flag. These increased friction without improving proof.

Now [AGENTS.md](../AGENTS.md) owns the shared contract, host adapters are short,
[onboarding](ONBOARDING.md) loads only for downstream setup, and AI review
requires an explicit opt-in. Existing CLI commands, spec fields, hooks,
security workflows, and remote branch protection are unchanged.

## Minimum Loop

After configuring the project and running `bash setup.sh`:

1. Find or scaffold the spec: `bash scripts/openspec scaffold "<change>"`.
2. Agree on scope, meaningful acceptance criteria, and corresponding tests.
   Set `status: review` once ready; do not claim human approval on their behalf.
3. Implement one testable change and run its focused check immediately.
4. Run `bash scripts/openspec check`, then `bash scripts/openspec verify <slug>`
  with the configured test environment and inspect `bash scripts/openspec status <slug>`.
5. Include the spec change, implementation, and tests in the same PR.
   Update user-facing docs when behavior changes and review the evidence.

A small bugfix can have one criterion and one regression test. The spec is
already the plan: do not require a second plan file, ADR, evaluator harness,
or specialist review unless risk or project policy warrants it. Optional spec
sections can remain empty or be omitted. Required fields stay required.
Role names represent responsibilities; a solo maintainer can hold several,
but separation of duties remains mandatory where the team requires it.
Questions and read-only assessments need neither onboarding nor a new spec.

## Compose by Need

These are adoption recommendations, not new config profiles. Except for AI
review and auto-fix, shipped workflows retain their existing triggers. Merely
following this guide does not disable them or change required checks.

| Capability | Use when | Activation or prerequisite |
| --- | --- | --- |
| Spec validation and tests | Every behavioral change | Configure test command and runtime; keep local and PR checks |
| Lint, secrets, dependency checks | Every project | Verify available tools, repository features, and job names |
| CODEOWNERS and review gates | Shared ownership or regulated work | Real users/teams; configured branch protection |
| DCO | Contributor attestation is required | Shipped workflow; `git commit -s` |
| CodeQL and container scanning | Supported source or container workload | Configure languages, build, permissions, and registry |
| AI spec review | Semantic feedback adds value | `agents.spec_review.enabled: true`; validate runtime and cost guards |
| Issue auto-fix | Trusted maintainer-driven automation | Explicit opt-in and review of its security model |
| ADRs | Long-lived architectural tradeoffs | Record the decision, alternatives, and consequences |
| Evaluation harness | Model/agent behavior needs evaluation | Add real scenarios and evaluators; directory presence is not a test |
| SBOM, provenance, license analysis | Release or compliance requirements | Validate artifacts, tooling, and organization policy |
| Scorecard and metrics | Periodic maintenance | Triage results; scheduled jobs are not reliable PR gates |

Before enabling AI review, validate `.github/workflows/spec-ai-review.yml`'s
external runtime (`github/agentic-workflow@v1`) and pin a reviewed supported
version. Editor diagnostics currently report that action as unresolvable;
do not enable it until repaired. This assessment did not execute that runtime. The model
is currently hardcoded in the workflow; changing the config model alone does
not select a different one. Enabling the flag on a PR cannot self-authorize
review: the guard reads the base branch config. Missing/false means off,
even if the cost guard is disabled. Daily run caps are not a currency budget.

Do not require AI review when disabled or unavailable. Required checks must
match actual PR job names, including matrix variants. Reconcile the supplied
ruleset with the jobs that run in your repository before applying it. No
remote settings or security checks were removed by this simplification.

## Agent Skills Principles

Inspired by [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills):

- Progressive disclosure: concise shared rules; load onboarding and domain
  references only for the current task.
- Spec before code: OpenSpec remains the source of acceptance criteria.
- Incremental implementation: one slice, focused validation, then continue.
- Evidence before completion: report actual commands, outcomes, and gaps.
- Composable workflows: use a skill or specialist for a concrete need, not
  as a mandatory ceremony for every change.
- Conservative boundaries: do not install skills, enable spending, change
  permissions, or claim approval implicitly.

No external skill pack is installed or vendored. `implementation_skill` is an
integration point, not a package manager. Agents must load the named skill's
actual instructions or disclose its absence. The example skill names in the
config are not bundled implementations. External workflows must not replace
OpenSpec specs with an unrelated PRD format or weaken repository gates.

## Enforcement Limits

The shared CLI now handles YAML validation, policy flags, verification and
bounded local execution. See [execution](EXECUTION.md) for commands and precise
guarantees. Remaining limits matter before treating this as a compliance boundary:

| Finding | Evidence | Consequence |
| --- | --- | --- |
| Coverage is a path heuristic | Shared configurable globs include scripts and infrastructure | A changed spec/test file is not a semantic mapping or proof of assertions |
| Test success is command-level evidence | `verify` records exit status and input fingerprint | Human review must still assess acceptance criteria and test quality |
| Local adapters are trusted commands | Cost bounds are declared, state is locally editable | Use provider caps and isolation; this is not a security sandbox |
| Test job needs project-specific setup | [spec-check.yml](../.github/workflows/spec-check.yml) runs a command without installing project dependencies | Configure the test environment; a command string is insufficient |
| Optional automation runtime is unresolved | Editor diagnostics cannot resolve `github/agentic-workflow@v1` in [AI review](../.github/workflows/spec-ai-review.yml) | Repair and pin the runtime before enabling; offline guard tests do not certify model invocation |

Audit workflow permissions, action pins and branch-protection contexts on a
disposable GitHub repository before making enterprise assurance claims.

## Template Verification

From the template repository root:

```bash
bash scripts/openspec check --template
make test-template
```

The template test suite uses Bash, Git, and Ruby
standard libraries (no gems) to exercise CLI/hook behavior and the actual
AI-review guard shell without network calls. Ruby >= 2.6 is also required by the
OpenSpec CLI and hooks, independently of the downstream application's language.

Markdown lint is a separate toolchain. With Node >= 22 and npm available:

```bash
make setup-lint
make lint-markdown
make verify-template
```

`setup-lint` installs locked dependencies under `tools/lint` using `npm ci
--ignore-scripts`; it needs registry access or a populated npm cache. CI runs
the same install and lint targets on Node 24. `lint-markdown` runs offline after
installation and fails with guidance when Node or dependencies are missing.
The CLI is pinned to 0.23.2 with a patched `smol-toml` 1.8.0 override for
GHSA-7w5x-hrqm-74c2; reassess the override when upgrading the CLI.
Existing rule configuration is unchanged; the newer CLI also checks table spacing.
All Markdown is checked except dependency directories and changelogs.

`verify-template` combines strict spec validation, the template suite, and
Markdown lint. It does **not** reproduce actionlint, ShellCheck, yamllint,
security scans, or remote branch protection; those CI checks remain enabled.
Node and npm are unnecessary for the core OpenSpec workflow or `test-template`.

Template PR checks use the explicit `.openspec/template` marker in the base revision.
Configured downstream projects use their own `testing.test_command`; these
template-default assertions are not a replacement for application tests.
Checks of instruction links and size are structural, not proof that every
agent host will follow them. Remote GitHub Actions and agent-host behavioral
evaluation still require a separate integration run.
