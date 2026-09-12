# Project Onboarding

Load this guide only to configure a downstream project created from the
template. For template maintenance, preserve placeholders and internal specs.
The shared operating rules live in [AGENTS.md](../AGENTS.md).

Any capable coding agent can guide this process. Use its question tool, or
ask in chat if unavailable. Ask one question or a tight related group at a
time and confirm answers before editing. Do not invent values or approvals.

## 1. Check Setup

From the repository root:

```bash
test -f .openspec/config.yaml
bash scripts/openspec init
```

If config is missing, stop and explain what is missing. If it contains `{{`
tokens, continue below. Otherwise skip onboarding and work from the spec.
`init` reports status; it does not perform the interview or fill the config.

Make the local CLI executable and check it:

```bash
chmod +x scripts/openspec
scripts/openspec --help
```

It requires Bash, Git, standard shell utilities, and Ruby >= 2.6 (no gems),
not an extension install or AI runtime.

## 2. Collect and Confirm Values

Read [.openspec/defaults.yaml](../.openspec/defaults.yaml) and
[.openspec/onboarding.yaml](../.openspec/onboarding.yaml).
Use non-empty, non-placeholder defaults without re-asking; show them so the
user can override. Ask unanswered required questions one at a time.
Present optional defaults as one group; ask individually only for overrides.
Role fields do not require four different people.

Also confirm the GitHub owner (`{{GITHUB_OWNER}}`) if not provided by defaults.
The question schema currently omits it; do not derive it from the local login.
Confirm any unresolved substitution token not covered by the schema.
Only offer enforcement options that are implemented; consult
[known limits](ADOPTION.md#enforcement-limits) before promising a switch works.

Show all values in a table and ask: "Apply these to the project?"
Write files only after yes.

## 3. Configure the Project

Replace confirmed placeholders in `.openspec/config.yaml`, preserving other
values. If the user explicitly changed an optional setting, update only that
setting too. Write booleans as unquoted `true` or `false`.
Do not enable AI review or auto-fix unless explicitly requested after explaining
their runtime requirements, permissions, and cost guards.

## 4. Customize the README

Keep [README.md](../README.md) focused on the user's project:

- Replace `{{PROJECT_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{GITHUB_OWNER}}`,
  `{{TEST_COMMAND}}`, and `{{BADGES}}`.
- Match Quick start to the actual language, dependencies, and run command.
- Show one minimal working usage example. If none exists yet, keep the TODO
  and say it needs completing after the first feature.
- Keep links to OpenSpec documentation; do not embed the framework guide.

## 5. Scaffold the First Spec

If the user named a first feature:

```bash
scripts/openspec scaffold "<feature-name>"
```

Clarify description, at least one meaningful acceptance criterion, and a
corresponding test plan. Use configured role defaults; ask rather than invent
any required assignments. A solo maintainer can hold multiple responsibilities
where project policy permits. Set `status: review` only when scope is agreed
and the spec is ready. The CLI accepts quoted status values and inline comments.
Install Ruby >= 2.6 alongside Bash and Git for the CLI and hooks. Remove the
template marker through `scripts/cleanup-template-specs` during adoption, not
template maintenance. See [execution](EXECUTION.md) before enabling automation.

## 6. Complete Governance Files

Replace each confirmed token only where present:

| Token | Value | Files |
| --- | --- | --- |
| `{{PROJECT_NAME}}` | Project name | README, SECURITY, CONTRIBUTING, SUPPORT, CHANGELOG, devcontainer |
| `{{GITHUB_OWNER}}` | GitHub user/org | README, CONTRIBUTING, CHANGELOG, CODEOWNERS, issue templates |
| `{{TEAM_NAME}}` | Team slug | CODEOWNERS |
| `{{SECURITY_CONTACT}}` | Private reporting email | SECURITY, CODE_OF_CONDUCT, SUPPORT |
| `{{PROJECT_DESCRIPTION}}` | One-line description | README |
| `{{TECH_STACK}}` | Comma-separated technologies | config.yaml |
| `{{BADGES}}` | Badge line below | README |

For an individual-owned project, use `@owner` in CODEOWNERS rather than
inventing a nonexistent GitHub team. Review finer-grained ownership when needed.
Configure required checks using [branch protection](BRANCH_PROTECTION.md);
do not blindly require optional, scheduled-only, or unavailable jobs.
`make apply-branch-protection` changes remote settings and requires explicit
authorization, the `gh` CLI, and repository admin permissions.

After confirming this is a downstream fork, remove template-internal design
specs with `bash scripts/cleanup-template-specs`. Never run it on the template.

### Badge Catalog

Match `project.tech_stack` values case-insensitively. Join badges with spaces.
For an unknown value, use `![<Value>](https://img.shields.io/badge/<Value>-gray)`
with the URL value encoded. An empty stack gets no technology badges.
Always append OpenSpec and License badges:

```markdown
![OpenSpec](https://img.shields.io/badge/OpenSpec-enforced-blueviolet)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
```

| Value | Badge markdown |
| --- | --- |
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

## 7. Verify Completion

```bash
test -f .openspec/config.yaml && ! grep -q '{{' .openspec/config.yaml
bash scripts/openspec check
```

Resolve remaining placeholders before downstream production code. Explain:
"OpenSpec is configured. README now describes your project. Run `bash setup.sh`
to install git hooks if you have not already. The full workflow is in
`docs/OPENSPEC.md`." Report any checks not run or remaining setup tasks.
