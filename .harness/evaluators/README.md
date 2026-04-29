# evaluators/

Evaluators are rubrics or scripts that score scenario runs against the `expected` assertions and `metrics` defined in each scenario file.

## Types of evaluators

| Type | Format | When to use |
|---|---|---|
| **Rubric** | Markdown file | LLM-as-judge — describe scoring criteria in natural language |
| **Script** | Python / shell | Deterministic checks (regex, schema validation, threshold comparison) |
| **Composite** | YAML pointing to multiple | Mix of rubric + script for hybrid evaluation |

## Adding an evaluator

Create a file in this directory and reference it from the scenario via `evaluator:`.

### Rubric example (`citation-and-groundedness.md`)

```markdown
Score the response on the following axes (0.0 – 1.0 each):

**citation_accuracy**: Every source cited by the agent must appear
verbatim or near-verbatim in the input document. Deduct 0.1 per
hallucinated citation.

**groundedness**: Every factual claim in the summary must be traceable
to a sentence in the input document. Deduct 0.1 per unsupported claim.
```

### Script example (`check-tool-call-count.sh`)

```bash
#!/usr/bin/env bash
# Exits 1 if tool_calls in trace exceeds the scenario threshold.
CALLS=$(jq '.tool_calls | length' "$1")
MAX=$(jq '.thresholds.max_tool_calls' "$2")
[ "$CALLS" -le "$MAX" ] && exit 0 || exit 1
```
