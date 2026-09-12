---
allowed-tools: Read, Bash, Glob, Grep
---

Read [AGENTS.md](../../AGENTS.md). Delegate validation and source classification
to the shared CLI; do not maintain a separate extension list or status policy.

Run from the repository root, stopping if a command fails:

```bash
set -e
git status --short
args=(check)
if [[ -f .openspec/template ]]; then args+=(--template); fi
bash scripts/openspec "${args[@]}"
bash scripts/openspec "${args[@]}" --staged
```

Report the commands, exit results, and CLI diagnostics. The first check validates
working-tree specs; `--staged` checks coverage for the Git index. Unstaged and
untracked implementation changes are not covered, and an empty index proves no
change coverage. Do not stage files or change spec status to obtain a pass.

For committed PR changes, use `check --ci --base <base-ref>` with the actual base
ref and the same template flag where applicable. A missing ref is a blocker.
These checks do not execute tests or grant approval to merge; use `verify <slug>`
and human review as described in the shared contract.
