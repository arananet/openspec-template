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

for adapter in CLAUDE.md .github/copilot-instructions.md .github/AGENTS.md; do
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
printf 'PASS: shared agent contract and on-demand onboarding\n'

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
git add .openspec/specs/valid.spec.yaml
bash .git/hooks/pre-commit
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
