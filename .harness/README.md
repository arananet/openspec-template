# .harness/

This directory contains the **test harness** for this project — executable scenarios, evaluators, mocks, and traces that prove specs are satisfied under controlled conditions.

## Structure

```
.harness/
├── scenarios/       # Declarative eval scenarios (agent tasks, prompt runs, API calls)
├── evaluators/      # Custom evaluator logic (scripts, rubrics, graders)
├── mocks/           # Mock tools, APIs, and data sources used during eval runs
└── traces/          # Captured execution traces (gitignored by default)
```

## Relationship to OpenSpec

OpenSpec defines **what should be true** — via `acceptance_criteria` and `test_plan`.

The harness proves **whether it is true** — via reproducible, measurable, executable runs.

| OpenSpec artifact | Harness artifact |
|---|---|
| `acceptance_criteria` | Scenario `expected` assertions |
| `test_plan` | Scenario `metrics` + evaluator rubrics |
| `eval_plan.scenarios` | Scenario files in `scenarios/` |
| `eval_plan.metrics` | Evaluator scripts in `evaluators/` |

## Running scenarios

```bash
# Run all scenarios (adapt to your harness runner)
gh openspec harness run

# Run a single scenario
gh openspec harness run scenarios/example-agent-task.scenario.yaml

# Compare against a baseline trace
gh openspec harness diff traces/baseline.json traces/latest.json
```

## Adding a scenario

1. Create a file in `scenarios/` following the `example.scenario.yaml` format.
2. Reference it in the relevant spec under `eval_plan.scenarios`.
3. Run the scenario locally before opening a PR.
4. Captured traces go in `traces/` — they are gitignored by default to keep the repo small.

## When to use this

- Any feature spec that involves an AI model, agent, or LLM-backed component.
- Integration boundaries where behavior is probabilistic rather than deterministic.
- Regression baselines for safety-critical or quality-sensitive flows.
- Latency and cost budgets that need continuous monitoring.

For purely deterministic code, standard unit/integration tests (defined in `test_plan`) are sufficient.
