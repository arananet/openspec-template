# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

---

## What is OpenSpec?

OpenSpec is a spec-driven development framework built into this repo. Every feature or bugfix starts with a spec file — no spec, no code. Specs define acceptance criteria, test plans, and the domain skill to use during implementation.

**Two layers of enforcement:**

| Layer | When | What |
|---|---|---|
| Git hook (local) | `git commit` | Blocks commits with source changes but no spec |
| CI — deterministic | Every PR | Validates spec fields, status, and test_plan presence |
| CI — agentic | Every PR | AI checks if the implementation actually satisfies the spec |

---

## How it works

```mermaid
flowchart TD
    A([New feature or bugfix]) --> B{Spec exists?}
    B -- No --> C["/openspec-scaffold\nor: gh openspec scaffold"]
    C --> D[Fill in acceptance_criteria\nand test_plan]
    D --> E{status = review?}
    B -- Yes --> E
    E -- draft --> D
    E -- review/approved --> F["/openspec-implement\ninvokes domain skill if set"]
    F --> G[Write tests per test_plan]
    G --> H([Open PR])
    H --> I[spec-check.yml\ndeterministic gate]
    H --> J[spec-ai-review.yml\nagentic alignment check]
    I --> K{All checks pass?}
    J --> K
    K -- No --> F
    K -- Yes --> L([Merge])
```

---

## Quick start

### 1. Configure this repo

Open it in [Claude Code](https://claude.ai/code) — it detects the unconfigured state and interviews you automatically.

Or configure manually:

```bash
# Edit the five required fields
vi .openspec/config.yaml

# Install git hooks
bash setup.sh
```

### 2. Set your personal defaults (optional)

Fill in `.openspec/defaults.yaml` once — onboarding will skip questions you've already answered:

```yaml
owner: "your-github-org"
team: "your-team"
test_command: "npm test"
default_implementation_skill: "frontend-pro"  # or backend-pro, devops-pro, etc.
```

### 3. Create your first spec

```bash
gh openspec scaffold "my first feature"
# or in Claude Code:
/openspec-scaffold my first feature
```

### 4. Implement with the right domain skill

```bash
# In Claude Code — reads the spec, invokes implementation_skill if set
/openspec-implement my-first-feature
```

### 5. Validate before pushing

```bash
gh openspec check           # validate all specs
gh openspec check --strict  # treat warnings as errors
gh openspec check --pr 42   # check a specific PR
```

---

## Claude Code skills

Three project skills are available in any Claude Code session:

| Skill | What it does |
|---|---|
| `/openspec-scaffold [feature]` | Guided spec creation — reads defaults, scaffolds file, validates required fields |
| `/openspec-implement [slug]` | Reads spec, checks status, invokes domain skill, implements + writes tests |
| `/openspec-check` | Validates spec coverage for current staged changes |

---

## Project structure

```
.openspec/
├── config.yaml          # Project configuration and enforcement settings
├── defaults.yaml        # Personal/team defaults (fill in once)
├── onboarding.yaml      # Questions Claude Code asks during first-time setup
├── specs/               # Active spec files (one per feature/bugfix)
│   └── example-feature.spec.yaml
└── templates/
    ├── feature.spec.yaml
    └── bugfix.spec.yaml

.github/
├── workflows/
│   ├── spec-check.yml       # Deterministic CI gate
│   └── spec-ai-review.yml   # Agentic semantic review
├── agents/
│   └── spec-review.md       # AI agent goal file
├── AGENTS.md                # Instructions for AI agents
└── copilot-instructions.md  # GitHub Copilot instructions

.claude/
├── commands/
│   ├── openspec-scaffold.md
│   ├── openspec-implement.md
│   └── openspec-check.md
├── hooks/
│   └── require-spec-on-commit.sh
└── settings.json
```

---

## Spec file format

See `.openspec/specs/example-feature.spec.yaml` for a fully filled-in reference.

Required fields: `title`, `description`, `acceptance_criteria`, `test_plan`, `status`

Status lifecycle: `draft` → `review` → `approved`

> Code can only be written when status is `review` or `approved`.

---

**Developer:** Eduardo Arana

**License:** [MIT](LICENSE)
