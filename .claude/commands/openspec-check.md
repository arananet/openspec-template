---
allowed-tools: Read, Bash, Glob, Grep
---

Validate OpenSpec coverage for the current working changes.

1. **Get changed files** — run `git diff --name-only HEAD` and `git diff --cached --name-only` to get all modified and staged files.

2. **Identify source files** — filter for files matching: `*.py`, `*.ts`, `*.js`, `*.tsx`, `*.jsx`, `*.go`, `*.java`, `*.rb`, `*.rs`, `*.cpp`, `*.c`, `*.cs`, `*.swift`, `*.kt`, `*.php`.

3. **Check for spec changes** — check if any `.openspec/specs/*.spec.yaml` files are also changed.

4. **If source files changed but no spec** — report FAIL:
   > "No spec found for these source changes. Run `/openspec-scaffold <feature>` to create one."

5. **If spec files changed** — for each spec:
   a. Read the spec file
   b. Validate required fields: `title`, `description`, `acceptance_criteria`, `test_plan`, `status`
   c. Check `status` is not `draft` (warn if it is)
   d. Check `acceptance_criteria` has at least one item
   e. Check `test_plan` has at least one item
   f. Report PASS / WARN / FAIL per spec with specific findings

6. **Summary** — end with a table:

```
| File | Status | Issues |
|------|--------|--------|
| example.spec.yaml | PASS | — |
| other.spec.yaml   | WARN | status: draft |
```

7. **If everything passes** — tell the user they're clear to commit and open a PR.
