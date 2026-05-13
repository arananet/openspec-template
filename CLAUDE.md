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

This project was created from the OpenSpec template. `.openspec/config.yaml`
still has `{{PLACEHOLDER}}` tokens, and `README.md` is a starter shell
that needs to become the **user's** project README. Your job is to drive
both, **interactively**, before anything else.

**Onboarding is a conversation — not a batch job.** Use the
`AskUserQuestion` tool one question (or one tight group) at a time.
Confirm answers before writing files. Do not invent values.

---

**Step 0 — Make sure the local OpenSpec CLI is executable:**

```bash
chmod +x scripts/openspec && scripts/openspec --help >/dev/null
```

The template ships a self-contained `scripts/openspec` (bash + coreutils
+ git only — no `gh` extension, no Python, no yq).

**Step 1 — Load defaults and the question schema:**

Read `.openspec/onboarding.yaml` and `.openspec/defaults.yaml`. Any field
already set in `defaults.yaml` (non-empty, non-placeholder) skips its
question — use that value directly. Show the user which defaults are
being applied so they can override.

**Step 2 — Interview the user, one question at a time:**

For each `required: true` question not pre-answered:
1. Ask via `AskUserQuestion` (with options when the schema gives them).
2. Wait for the answer before asking the next.
3. After the last required question, summarise every answer in a table
   and ask: *"Apply these to the project?"* Only proceed on yes.

For `required: false` questions, show the default and let the user
accept it or supply a different value.

**Step 3 — Write the config:**

Edit `.openspec/config.yaml`, replacing each `{{PLACEHOLDER}}` token
with the confirmed answer. For boolean fields, write `true` or `false`
(no quotes). Do not touch lines without a placeholder.

**Step 4 — Customise `README.md` (this is what the user will see first):**

The shipped `README.md` is a slim starter. Replace its placeholders with
the user's project details — do **not** restore the long OpenSpec
section that older versions had. Specifically:

- Replace `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{GITHUB_OWNER}}`,
  `{{TEST_COMMAND}}`, `{{BADGES}}` (generate from `tech_stack`, see badge
  catalog further down).
- Edit the `## Quick start` block so the install/run steps match the
  user's actual stack (Python? Node? Go? Docker?).
- Edit the `## Usage` section to show **one minimal example** of the
  user's project doing its job. If the user doesn't have one yet, leave
  the `<!-- TODO -->` line and tell them to fill it after the first
  feature ships.
- Leave the OpenSpec link block alone — it points to `docs/OPENSPEC.md`
  which carries all the framework-specific detail.

**Step 5 — Scaffold the first spec (if the user named one):**

```bash
scripts/openspec scaffold "<feature-name>"
```

Walk the user through `description`, `acceptance_criteria` (≥1),
`test_plan` (≥1), and `roles` (implementer / reviewer / qa /
product_owner) interactively — same one-question-at-a-time approach.
If `roles.default_*` is set in `.openspec/config.yaml`, the scaffold
script pre-fills those values; otherwise ask the user. Set
`status: review` only after all are non-trivial.

**Step 6 — Substitute placeholders across governance files and generate badges:**

`README.md` was customised in Step 4 — for the **other** files shipped
with the template, do a single find-and-replace per token:

   | Token | Replace with | Files |
   |---|---|---|
   | `{{PROJECT_NAME}}` | Project name | README, SECURITY, CONTRIBUTING, SUPPORT, CHANGELOG, devcontainer |
   | `{{GITHUB_OWNER}}` | GitHub org/user | CONTRIBUTING, CHANGELOG, CODEOWNERS, ISSUE_TEMPLATE/config.yml |
   | `{{TEAM_NAME}}` | GitHub team slug | CODEOWNERS |
   | `{{SECURITY_CONTACT}}` | Security contact email | SECURITY, CODE_OF_CONDUCT, SUPPORT |
   | `{{PROJECT_DESCRIPTION}}` | One-line description | README |
   | `{{BADGES}}` | shields.io badge line (auto-generated from `tech_stack`) | README |
   | `{{TECH_STACK}}` | Comma-separated tech list | config.yaml |

3. **Generate badges from `tech_stack`:**

   Read `project.tech_stack` from `config.yaml`. For each comma-separated
   value, look up the matching badge from the catalog below and concatenate
   them into a single line separated by spaces. Replace `{{BADGES}}` in
   `README.md` with the result. If `tech_stack` is empty, remove the
   `{{BADGES}}` line entirely.

   Always append the OpenSpec and License badges at the end:
   ```
   ![OpenSpec](https://img.shields.io/badge/OpenSpec-enforced-blueviolet)
   ![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
   ```

   **Badge catalog** (case-insensitive match on `tech_stack` values):

   | Value | Badge markdown |
   |---|---|
   | `python` | `![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)` |
   | `javascript` | `![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?logo=javascript&logoColor=black)` |
   | `typescript` | `![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?logo=typescript&logoColor=white)` |
   | `go` | `![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)` |
   | `rust` | `![Rust](https://img.shields.io/badge/Rust-000000?logo=rust&logoColor=white)` |
   | `java` | `![Java](https://img.shields.io/badge/Java-ED8B00?logo=openjdk&logoColor=white)` |
   | `csharp` | `![C#](https://img.shields.io/badge/C%23-239120?logo=csharp&logoColor=white)` |
   | `ruby` | `![Ruby](https://img.shields.io/badge/Ruby-CC342D?logo=ruby&logoColor=white)` |
   | `php` | `![PHP](https://img.shields.io/badge/PHP-777BB4?logo=php&logoColor=white)` |
   | `swift` | `![Swift](https://img.shields.io/badge/Swift-FA7343?logo=swift&logoColor=white)` |
   | `kotlin` | `![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?logo=kotlin&logoColor=white)` |
   | `react` | `![React](https://img.shields.io/badge/React-61DAFB?logo=react&logoColor=black)` |
   | `vue` | `![Vue.js](https://img.shields.io/badge/Vue.js-4FC08D?logo=vuedotjs&logoColor=white)` |
   | `angular` | `![Angular](https://img.shields.io/badge/Angular-DD0031?logo=angular&logoColor=white)` |
   | `nextjs` | `![Next.js](https://img.shields.io/badge/Next.js-000000?logo=nextdotjs&logoColor=white)` |
   | `express` | `![Express](https://img.shields.io/badge/Express-000000?logo=express&logoColor=white)` |
   | `django` | `![Django](https://img.shields.io/badge/Django-092E20?logo=django&logoColor=white)` |
   | `flask` | `![Flask](https://img.shields.io/badge/Flask-000000?logo=flask&logoColor=white)` |
   | `fastapi` | `![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)` |
   | `spring` | `![Spring](https://img.shields.io/badge/Spring-6DB33F?logo=spring&logoColor=white)` |
   | `dotnet` | `![.NET](https://img.shields.io/badge/.NET-512BD4?logo=dotnet&logoColor=white)` |
   | `rails` | `![Rails](https://img.shields.io/badge/Rails-CC0000?logo=rubyonrails&logoColor=white)` |
   | `laravel` | `![Laravel](https://img.shields.io/badge/Laravel-FF2D20?logo=laravel&logoColor=white)` |
   | `docker` | `![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)` |
   | `kubernetes` | `![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?logo=kubernetes&logoColor=white)` |
   | `terraform` | `![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)` |
   | `azure` | `![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoftazure&logoColor=white)` |
   | `aws` | `![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazonwebservices&logoColor=white)` |
   | `gcp` | `![GCP](https://img.shields.io/badge/GCP-4285F4?logo=googlecloud&logoColor=white)` |
   | `github-actions` | `![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?logo=githubactions&logoColor=white)` |
   | `postgres` | `![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)` |
   | `mongodb` | `![MongoDB](https://img.shields.io/badge/MongoDB-47A248?logo=mongodb&logoColor=white)` |
   | `redis` | `![Redis](https://img.shields.io/badge/Redis-DC382D?logo=redis&logoColor=white)` |
   | `nodejs` | `![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)` |
   | `svelte` | `![Svelte](https://img.shields.io/badge/Svelte-FF3E00?logo=svelte&logoColor=white)` |
   | `tailwind` | `![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-06B6D4?logo=tailwindcss&logoColor=white)` |
   | `graphql` | `![GraphQL](https://img.shields.io/badge/GraphQL-E10098?logo=graphql&logoColor=white)` |
   | `mysql` | `![MySQL](https://img.shields.io/badge/MySQL-4479A1?logo=mysql&logoColor=white)` |
   | `sqlite` | `![SQLite](https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white)` |
   | `firebase` | `![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)` |
   | `supabase` | `![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)` |

   If a `tech_stack` value has no catalog match, generate a generic gray badge:
   ```
   ![<Value>](https://img.shields.io/badge/<Value>-gray)
   ```

4. Review `.github/CODEOWNERS` — add finer-grained per-path owners as the
   codebase grows. Default ownership is the team from `{{TEAM_NAME}}`.

5. Point the user to `docs/BRANCH_PROTECTION.md` to configure required
   status checks (OpenSpec PR Check, Lint, CodeQL, gitleaks,
   dependency-review, OSSF Scorecard, DCO, Doc drift, ScanCode license
   analysis, Run tests) on the default branch. For one-command setup
   they can run `make apply-branch-protection` (requires `gh` CLI and
   admin rights on the repo).

6. **Clean up template-internal specs.** Run `bash scripts/cleanup-template-specs`
   (or `make cleanup-template-specs`) to remove the design specs that
   document how this template was built — they're not relevant to the
   user's project and clutter `.openspec/specs/`.

**Step 7 — Confirm setup is complete:**

```bash
grep -c '{{' .openspec/config.yaml
```

If output is `0`, configuration is complete. Run `scripts/openspec check`
to validate any specs that exist, then tell the user:

> "OpenSpec is configured. `README.md` now describes your project.
>  Run `bash setup.sh` if you haven't — it installs the git hooks that
>  gate commits without specs. The full OpenSpec workflow lives in
>  `docs/OPENSPEC.md`."

Do not write any production code until the config has no `{{` tokens.

---

## Working on Features

When the user asks you to implement something new:

1. **Check for an existing spec:**
   ```bash
   ls .openspec/specs/
   ```
   Look for a `<feature-slug>.spec.yaml` file matching the requested feature.
   Alternatively, run `/openspec-check` to validate current coverage.

2. **If no spec exists — create one first:**
   ```bash
   scripts/openspec scaffold "<feature-name>"
   # or in Claude Code:
   /openspec-scaffold <feature-name>
   ```
   Ask the user to confirm or fill in:
   - `description`: what this does and why
   - `acceptance_criteria`: definition of done (at least one item)
   - `test_plan`: at least one test per AC
   - `roles`: who implements, reviews, QAs, and approves this spec (use defaults from `config.yaml` if set, otherwise ask)
   - `implementation_skill`: optional — check `agents.implementation_skills` in `config.yaml` for available domain skills
   - `out_of_scope`: what this explicitly does NOT cover

3. **Do not write production code** until the spec has at least one
   `acceptance_criteria` item, at least one `test_plan` item, and `status`
   is `review` or `approved`.

4. **Check for a domain skill** — read `implementation_skill` in the spec.
   If set, invoke that skill before writing code. If null, check
   `agents.implementation_skills.default` in `config.yaml`.

5. **Use the spec as your definition of done.**
   Each acceptance criterion should be verifiable in the implementation.
   Use `/openspec-implement <slug>` to drive the full workflow.

6. **Write tests alongside the implementation.**
   Every spec requires a `test_plan`. Tests must be written as part of the
   same PR — not as a follow-up. CI will fail if tests are missing or failing.

7. **Commit the spec with the implementation:**
   Include the `.openspec/specs/<slug>.spec.yaml` file in the same commit
   (or PR) as the production code changes.

8. **Update README.md** to reflect any new features, changed behavior, or
   new usage instructions introduced by the implementation.

---

## Issues already in flight with the auto-fix agent

If the user asks you to work on an issue, first check whether the issue
has the `agent:autofix` label (or whatever `agents.issue_autofix.label`
is set to in `.openspec/config.yaml`). The repo's auto-fix workflow
(`.github/workflows/issue-autofix.yml`) may already be running or have
opened a draft PR for it.

```bash
gh issue view <n> --json labels,state
gh pr list --search "Fixes #<n>" --state open
```

- If a draft PR already exists on `agent/autofix/issue-<n>` — review and
  improve **that** branch instead of starting a parallel one. Do not
  open a competing PR.
- If the workflow is mid-run (an in-progress GitHub Actions run on the
  branch), wait or coordinate with the user before pushing — your push
  will collide with the agent's.
- If the agent aborted (you'll see a comment naming the reason), read
  the comment and treat its concern as a constraint on your own work
  (e.g. don't blindly do the sensitive-path edit it refused to do).

---

## Validating Spec Coverage

```bash
scripts/openspec check           # validate all specs in this repo
scripts/openspec check --strict  # treat warnings as errors
scripts/openspec check --pr 42   # check spec coverage for PR #42
```

---

## Scaffolding a New Spec Manually

```bash
scripts/openspec scaffold "user authentication"         # feature spec
scripts/openspec scaffold "fix login crash" --type bugfix  # bugfix spec
```

Spec files are created at `.openspec/specs/<slug>.spec.yaml`.

---

## Coding Guidelines (Karpathy)

> These guidelines reduce common LLM coding mistakes. They bias toward caution over speed — use judgment on trivial tasks.
> OpenSpec already handles **Goal-Driven Execution**: `acceptance_criteria` are your success criteria and `test_plan` items are your verification steps. The guidelines below cover what OpenSpec does not.

### 1. Think Before Coding

Before writing a single line of implementation:

- **State your assumptions explicitly.** If uncertain about what the spec means, ask — don't guess silently.
- **If multiple interpretations exist**, present them to the user. Don't pick one without saying so.
- **If a simpler approach exists**, say so. Push back on the spec if the design is overcomplicated.
- **If something is unclear**, stop. Name what's confusing. Ask. Do not hide confusion behind code.
- Surface assumptions during spec creation or spec review — not mid-implementation.

### 2. Simplicity First

Write the minimum code that satisfies each acceptance criterion. Nothing more.

- No features beyond what the AC requires.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that the spec didn't ask for.
- No error handling for scenarios that cannot happen given the spec's stated context.
- If you write 200 lines and it could be 50, rewrite it.
- Ask yourself: *"Would a senior engineer say this is overcomplicated?"* If yes, simplify.

### 3. Surgical Changes

Touch only what the spec requires. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting that is not part of the spec.
- Don't refactor things that aren't broken unless the spec explicitly asks for it.
- Match existing code style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- When your changes create orphans (unused imports, variables, functions), remove them.
- Don't remove pre-existing dead code unless asked.
- **The test:** every changed line should trace directly to an acceptance criterion in the spec.

### 4. Goal-Driven Execution (OpenSpec integration)

OpenSpec enforces this structurally. Map each implementation step to a spec artifact:

- Each AC → a verifiable code change
- Each `test_plan` item → a written test in the same PR
- Multi-step tasks → state a brief plan before starting:
  ```
  [Step] → verify: [AC reference]
  [Step] → verify: [test_plan item]
  ```
- Weak criteria ("make it work") → go back to the spec and sharpen the AC before coding.

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
