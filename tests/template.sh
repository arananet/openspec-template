#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/openspec-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_failure() {
  if "$@" > "$SANDBOX/output" 2>&1; then
    fail "unexpected success: $*"
  fi
}

for adapter in CLAUDE.md .github/copilot-instructions.md .github/AGENTS.md .claude/commands/openspec-check.md; do
  grep -q 'AGENTS.md' "$ROOT/$adapter" || fail "$adapter does not route to shared rules"
  [[ $(wc -l < "$ROOT/$adapter") -le 30 ]] || fail "$adapter is no longer a thin adapter"
done
[[ $(wc -l < "$ROOT/AGENTS.md") -le 90 ]] || fail "shared rules exceed the context budget"
grep -q 'review.*approved' "$ROOT/AGENTS.md"
grep -q 'same PR' "$ROOT/AGENTS.md"
grep -q 'template maintenance' "$ROOT/AGENTS.md"
grep -q 'onboarding.yaml' "$ROOT/docs/ONBOARDING.md"
grep -q 'defaults.yaml' "$ROOT/docs/ONBOARDING.md"
grep -q 'Apply these to the project?' "$ROOT/docs/ONBOARDING.md"
[[ $(grep -c '^| `.*` | `!\[' "$ROOT/docs/ONBOARDING.md") -eq 41 ]] || fail "badge catalog changed"
grep -q 'AGENTS.md#small-verifiable-steps' "$ROOT/.github/agents/issue-autofix.md"
if grep -q 'Coding Guidelines (Karpathy)' "$ROOT/.github/agents/issue-autofix.md"; then
  fail "auto-fix references a removed instruction section"
fi
for guide in docs/ONBOARDING.md docs/ADOPTION.md; do
  [[ -f "$ROOT/$guide" ]] || fail "missing adoption guide: $guide"
  grep -q "$guide" "$ROOT/README.md" || fail "README does not link to $guide"
done
awk '/^## Start With This Template$/ { found=1 } /^## Quick start$/ { exit !found } END { if (!found) exit 1 }' "$ROOT/README.md" || fail "minimal adoption path must precede project quickstart"
grep -q '{{PROJECT_NAME}}' "$ROOT/README.md"
grep -q '{{TEST_COMMAND}}' "$ROOT/README.md"
printf 'PASS: shared agent contract and on-demand onboarding\n'

CHECK_SCRIPT="$(awk '/^```bash$/ { in_block=1; next } /^```$/ { in_block=0 } in_block' "$ROOT/.claude/commands/openspec-check.md")"
[[ -n "$CHECK_SCRIPT" ]] || fail "check command has no executable example"

mkdir -p "$SANDBOX/scripts" "$SANDBOX/.openspec/specs"
cp "$ROOT/scripts/openspec" "$SANDBOX/scripts/openspec"
cp "$ROOT/scripts/openspec_core.rb" "$ROOT/scripts/openspec_runtime.rb" "$SANDBOX/scripts/"
cp -R "$ROOT/.openspec/templates" "$SANDBOX/.openspec/templates"
cp "$ROOT/.openspec/config.yaml" "$SANDBOX/.openspec/config.yaml"
cp "$ROOT/.openspec/template" "$SANDBOX/.openspec/template"
cp "$ROOT/setup.sh" "$SANDBOX/setup.sh"
cp -R "$ROOT/hooks" "$SANDBOX/hooks"
cd "$SANDBOX"
git init -q
git config user.name "Template Test"
git config user.email "template-test@example.invalid"
bash setup.sh > /dev/null
bash setup.sh > /dev/null
[[ -x .git/hooks/pre-commit && -x .git/hooks/commit-msg ]]

bash scripts/openspec scaffold "Sample Feature" > /dev/null
grep -q '^slug: sample-feature' .openspec/specs/sample-feature.spec.yaml
expect_failure bash scripts/openspec scaffold "Sample Feature"
bash scripts/openspec scaffold "Sample Bug" --type bugfix > /dev/null
grep -q '^type: bugfix' .openspec/specs/sample-bug.spec.yaml
expect_failure bash scripts/openspec scaffold "Invalid" --type invalid
grep -q '^status: draft' .openspec/specs/sample-feature.spec.yaml
printf 'PASS: feature/bugfix scaffold and duplicate protection\n'

rm .openspec/specs/sample-feature.spec.yaml .openspec/specs/sample-bug.spec.yaml
cat > .openspec/specs/valid.spec.yaml <<'EOF'
title: "Valid fixture"
status: review
description: "Exercise the existing OpenSpec contract."
acceptance_criteria:
  - "Source changes have a spec."
test_plan:
  - "Exercise hook rejection and acceptance."
EOF
sed 's/status: review/status: draft/' .openspec/specs/valid.spec.yaml > .openspec/specs/draft.spec.yaml
bash scripts/openspec check --template > /dev/null 2>&1
expect_failure bash scripts/openspec check --strict --template
grep -q "status is 'draft'" "$SANDBOX/output"
rm .openspec/specs/draft.spec.yaml
bash scripts/openspec check --strict --template > /dev/null 2>&1
sed 's/status: review/status: approved/' .openspec/specs/valid.spec.yaml > .openspec/specs/approved.spec.yaml
bash scripts/openspec check --strict --template > /dev/null 2>&1
sed '/test_plan:/,$d' .openspec/specs/valid.spec.yaml > .openspec/specs/invalid.spec.yaml
expect_failure bash scripts/openspec check --template
grep -q 'missing required field: test_plan' "$SANDBOX/output"
rm .openspec/specs/invalid.spec.yaml
printf 'PASS: review/approved specs and missing test plan rejection\n'

printf 'console.log("fixture");\n' > fixture.ts
git add fixture.ts
expect_failure bash .git/hooks/pre-commit
grep -q 'no spec changes' "$SANDBOX/output"
expect_failure bash -c "$CHECK_SCRIPT"
grep -q 'no spec changes' "$SANDBOX/output"
git add .openspec/specs/valid.spec.yaml
bash .git/hooks/pre-commit
bash -c "$CHECK_SCRIPT" > /dev/null
printf 'PASS: source-only rejected; source with spec accepted\n'

cp "$ROOT/.openspec/specs/lean-agent-workflow.spec.yaml" .openspec/specs/
cp "$ROOT/.openspec/specs/reliable-verification-and-resumable-execution.spec.yaml" .openspec/specs/
bash "$ROOT/scripts/cleanup-template-specs" > /dev/null
[[ ! -f .openspec/specs/lean-agent-workflow.spec.yaml ]]
[[ ! -f .openspec/specs/reliable-verification-and-resumable-execution.spec.yaml ]]
[[ ! -f .openspec/template ]]
[[ -f .openspec/specs/valid.spec.yaml ]]
bash "$ROOT/scripts/cleanup-template-specs" > /dev/null
printf 'PASS: cleanup removes template spec and preserves project specs\n'
