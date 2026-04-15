# Claude Code Instructions — OpenSpec Project

## OpenSpec Status Check (run this first on every session start)

Before doing any other work, check whether this project has been configured:

```bash
grep -c '{{' .openspec/config.yaml 2>/dev/null && echo "STATUS: NOT_CONFIGURED" || echo "STATUS: CONFIGURED"
```

- **`NOT_CONFIGURED`** → Follow "First-Time Setup" below before anything else.
- **`CONFIGURED`** → Skip to "Working on Features".

---

## First-Time Setup (AI-Guided Onboarding)

This project was created with OpenSpec enforcement, but `.openspec/config.yaml`
still has placeholder values that need to be filled in.

**Step 1 — Read the question schema:**
Read `.openspec/onboarding.yaml`. It contains the list of questions to ask,
what each answer maps to in `config.yaml`, and instructions for what to do after.

**Step 2 — Interview the user:**
Ask each `required: true` question. For `required: false` questions, show the
default and let the user accept or change it.

**Step 3 — Write the config:**
Edit `.openspec/config.yaml`, replacing each `{{PLACEHOLDER}}` token with the
user's answer. For boolean fields, write `true` or `false` (no quotes).

**Step 4 — Scaffold the first spec (if the user named a feature):**
```bash
gh openspec scaffold "<feature-name>"
```
Show the user the created file and offer to help fill in `acceptance_criteria`.

**Step 5 — Confirm setup is complete:**
```bash
grep -c '{{' .openspec/config.yaml
```
If output is `0`, configuration is complete. Tell the user:
> "OpenSpec is configured. Run `bash setup.sh` to install git hooks.
>  After that, any commit touching source files will require a spec."

**Step 6 — Create or update README.md:**
After configuration is complete, create or update `README.md` with:
- Project name and description (from `config.yaml`)
- How to install/run the project
- How OpenSpec works in this repo (brief overview)
- Link to `.openspec/` for spec details

Do not write any production code until the config has no `{{` tokens.

---

## Working on Features

When the user asks you to implement something new:

1. **Check for an existing spec:**
   ```bash
   ls .openspec/specs/
   ```
   Look for a `<feature-slug>.spec.yaml` file matching the requested feature.

2. **If no spec exists — create one first:**
   ```bash
   gh openspec scaffold "<feature-name>"
   ```
   Ask the user to confirm or fill in:
   - `description`: what this does and why
   - `acceptance_criteria`: definition of done (at least one item)
   - `out_of_scope`: what this explicitly does NOT cover

3. **Do not write production code** until the spec has at least one
   `acceptance_criteria` item, at least one `test_plan` item, and `status`
   is `review` or `approved`.

4. **Use the spec as your definition of done.**
   Each acceptance criterion should be verifiable in the implementation.

5. **Write tests alongside the implementation.**
   Every spec requires a `test_plan`. Tests must be written as part of the
   same PR — not as a follow-up. CI will fail if tests are missing or failing.

6. **Commit the spec with the implementation:**
   Include the `.openspec/specs/<slug>.spec.yaml` file in the same commit
   (or PR) as the production code changes.

7. **Update README.md** to reflect any new features, changed behavior, or
   new usage instructions introduced by the implementation.

---

## Validating Spec Coverage

```bash
gh openspec check           # validate all specs in this repo
gh openspec check --strict  # treat warnings as errors
gh openspec check --pr 42   # check spec coverage for PR #42
```

---

## Scaffolding a New Spec Manually

```bash
gh openspec scaffold "user authentication"         # feature spec
gh openspec scaffold "fix login crash" --type bugfix  # bugfix spec
```

Spec files are created at `.openspec/specs/<slug>.spec.yaml`.

---

## Testing & QA Standards

Every feature or bugfix implemented through OpenSpec **must** include tests. This is enforced at the spec, commit, and CI levels.

### Spec requirements
- Every spec must have a `test_plan` section with at least one item before status moves to `review`.
- `test_plan` items should map 1-to-1 with `acceptance_criteria` where possible.
- Bugfix specs must also fill in `regression_test` with the specific file/function added.

### Implementation requirements
- Write unit tests for all new logic.
- Write integration tests for any new API endpoints, data flows, or cross-service interactions.
- Do not merge a spec without its tests — CI blocks on missing or failing tests.

### CI gates
The following CI checks are enforced (configured in `.openspec/config.yaml`):
- `ci.run_tests: true` — test suite runs on every PR.
- `ci.fail_on_test_failure: true` — failing tests block merge.
- `ci.fail_on_missing_tests: true` — PRs with no test changes alongside source changes are flagged.

### Running tests locally
```bash
# Use the test command configured during onboarding (testing.test_command in config.yaml)
# Examples:
npm test
pytest
go test ./...
```

---

## Documentation Standards

### README.md
- Always create `README.md` during first-time setup (Step 6 above).
- Always update `README.md` when implementing a feature or fixing a bug that changes behavior or usage.
- Keep it accurate and up to date — it is the entry point for any developer opening this repo.

### Diagrams
- **Always use [Mermaid](https://mermaid.js.org/) syntax** for any diagrams (flowcharts, sequence diagrams, ERDs, etc.).
- Mermaid renders natively on GitHub inside fenced code blocks:
  ````
  ```mermaid
  graph TD
      A[Start] --> B[End]
  ```
  ````
- Do **not** use image-based diagrams (PNG, SVG files, external tools) unless the user explicitly requests it.
- Place diagrams directly in `README.md` or in the relevant spec/doc file where they add the most clarity.

---

## Project Context

- **Config**: `.openspec/config.yaml` ← fill this in during onboarding
- **Spec templates**: `.openspec/templates/`
- **Active specs**: `.openspec/specs/`
- **Onboarding questions**: `.openspec/onboarding.yaml`
- **OpenSpec version**: 1
