# Verification and Resumable Execution

OpenSpec requires Bash, Git and Ruby >= 2.6 with standard libraries. No gems,
AI runtime or model account is required for manual implementation and verification.
Install the application's own runtime and test dependencies separately, locally
and in the `Run Tests` job before its verification step.

## Manual Workflow

```bash
bash scripts/openspec check --strict
bash scripts/openspec verify my-feature
bash scripts/openspec status
bash scripts/openspec pause my-feature
bash scripts/openspec resume my-feature
```

`verify` validates the selected review/approved spec and runs
`testing.test_command` from the repository root with a timeout (default 300
seconds). `make test name=my-feature` is equivalent. Commands use Bash with
closed stdin; supply a noninteractive command and required environment.
`resume` clears the pause and verifies manually; it never invokes an agent.
`pause` can be issued from another terminal and terminates the active command's
process group. There is one verification/runner lock per repository.

Exit codes and recorded results:

| Code | Result | Meaning |
| --- | --- | --- |
| 0 | `passed` | The configured command exited zero and inputs stayed unchanged |
| 1 | `failed` | The configured command exited nonzero |
| 2 | `unverified` | Missing prerequisites, invalid spec/config, pause, timeout or changed inputs |

CLI argument/config-loading errors can exit 2 before a report can be written.
A passed command does **not** prove all acceptance criteria, the execution of
every test-plan item, security review or human approval. Reports explicitly set
`acceptance_criteria_proven: false`. Configure the test runner to fail when it
collects no tests and to enforce any coverage threshold. Test-file detection
only establishes that a matching file exists, not that assertions ran.

## Evidence and State

Ignored local files under `.openspec/runs/` contain the active spec, per-spec
state, append-only verification reports and command logs. State includes result,
next step, blocker, attempts, reserved cost and elapsed execution time. Reports
include the command, timestamps, exit status, commit and input fingerprint.

`status` recalculates freshness without rewriting historical evidence. Its
effective result is `unverified` when the fingerprint differs. The fingerprint
covers HEAD, the Git index, and tracked/nonignored untracked file contents and
modes, including specs, tests and config. Runtime records are excluded. Ignored
dependencies, environment variables, external services and symlink target
contents are not fingerprinted: rerun verification when these change. Ignore
generated build output deliberately, or generating it will invalidate a run.

Records are local evidence, not signed attestations. Do not trust them against
a malicious process with repository access. Logs may contain secrets: directory
permissions are restricted, but inspect before sharing. CI uploads only report
JSON for seven days, not raw logs; report commands can still contain sensitive
text, so never embed credentials in configured commands. Local retention is
manual; removing state resets budgets and must be an explicit human decision.

## Optional Agent Adapter

Automation is off by default. To opt in, configure a trusted, already installed
adapter after reviewing its permissions and cost controls:

```yaml
verification:
  timeout_seconds: 300
execution:
  enabled: true
  adapter: local-agent
  max_attempts: 2
  max_seconds: 600
  max_cost: 2.0
  adapters:
    local-agent:
      command: 'bash tools/implement-spec "$OPENSPEC_SPEC"'
      max_cost_per_attempt: 1.0
```

The example adapter is not bundled. Implement it for your chosen agent CLI;
it receives `OPENSPEC_ROOT` and the relative `OPENSPEC_SPEC` path. It must read
the spec and shared agent instructions, invoke required skills, make only scoped
changes and tests, exit noninteractively, and enforce its own provider budget.
No runtime is installed or provider called by enabling the configuration alone.

```bash
bash scripts/openspec run my-feature
bash scripts/openspec run my-feature --resume
```

Each attempt reserves `max_cost_per_attempt` before invocation. The sum cannot
exceed `max_cost`; use one consistent currency/unit. This is a conservative
admission budget, **not measured spending or a provider billing cap**. Only use
an adapter whose declared bound is credible and independently enforced.
Attempts and execution time persist across resumes. Waiting between commands
does not consume the time budget. The runner reserves remaining time before
launch, so a coordinator crash conservatively consumes it rather than granting
a fresh budget. Interrupted state can retain phase `running`; inspect the
processes and records before deliberately changing limits.

After a successful adapter invocation, verification runs. Failed tests can
trigger another attempt within all limits. Passing verification stops at human
review. Adapter failure, pause, timeout, missing evidence or modification/deletion
of spec/config stops for intervention. Changes are not reverted. A completed,
unchanged run is not repeated on resume; stale evidence requires verification.

This is **not a sandbox**. Commands have the current user's filesystem/network
access and could alter state or policies. Detached processes and remote work
may outlive local cancellation. Use trusted adapters and external isolation for
untrusted work. OpenSpec itself never commits, pushes, approves or merges.

## Shared Policy and CI

CLI, hooks and deterministic PR jobs use the same structured YAML validator.
Duplicate keys and malformed content fail. Quoted scalars, inline comments,
block descriptions and lists are supported. Ready specs require meaningful
description, acceptance criteria and test-plan text; draft scaffolds remain
valid for editing, unless strict/draft policy is enabled.

- `spec.required_fields`, `min_acceptance_criteria` and `statuses` affect validation.
- Source detection defaults to all non-document/test/spec/runtime paths,
  including shell, infrastructure and extensionless files. Override with
  `spec.source_patterns` (Ruby pathname globs, for example `["src/**/*"]`).
- Override test detection with `testing.test_patterns`; specs never count as tests.
- Source commits require a changed staged ready spec when `enforce_on_commit`
  and hook `block_if_no_spec` are true. Hooks honor `enabled` and `warn_only`.
  Commit-message enforcement honors its `pattern` with `<slug>` and requires
  the referenced spec to exist. Merge/revert/fixup/squash messages are exempt.
- Source PRs require a live changed ready spec when `enforce_on_pr` and
  `ci.fail_on_missing_spec` are true. Test changes are required when all of
  `testing.require_tests`, `testing.fail_on_missing_tests` and
  `ci.fail_on_missing_tests` are true. Any changed spec is only a coverage
  heuristic, not proof of a semantic source-to-criterion mapping.
- `spec.approved_required_for_merge` checks changed specs in CI; it does not
  authenticate an approval. `ci.fail_on_draft_spec` rejects every draft spec.
- `ci-tests --base <ref>` verifies changed ready specs for relevant changes,
  or existing ready specs when none changed. It runs the configured suite per
  selected spec; docs-only diffs do not run tests. Missing Git refs fail closed.
- `ci.run_tests: false` records `unverified` without running tests and exits zero.
  `ci.fail_on_test_failure: false` retains `failed` evidence but exits zero in CI.
  Neither flag affects manual `verify` or the local automatic runner.
- Non-null `testing.coverage_threshold` and enabled `ci.notify_slack` fail with
  guidance rather than silently promising unsupported integrations.

Missing config or unresolved config placeholders fail downstream checks.
Template maintenance uses `check --template` (or `make check`). CI allows that
exception only when `.openspec/template` exists both in the checkout and trusted
base revision. For the initial template-maintenance PR introducing this marker,
a maintainer may explicitly set repository variable `OPENSPEC_TEMPLATE=true`;
it authorizes the template exception while the checkout marker exists. No
repository variable is changed by the CLI. Do not set this in downstream projects.
`cleanup-template-specs` removes this marker during downstream adoption; commit
the cleanup before relying on downstream CI. Do not add the marker to projects.
Protect config, workflows and engine changes with human review and branch rules.
Job names `Validate Spec Coverage` and `Run Tests` are unchanged.
