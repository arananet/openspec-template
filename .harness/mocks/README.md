# mocks/

Mock tools, APIs, and data sources used during harness scenario runs.

Mocks provide **controlled, reproducible inputs** so that scenario results are
deterministic and comparable across runs — even when the real tools are
non-deterministic, rate-limited, or expensive.

## What goes here

| File type | Purpose |
|---|---|
| `*.json` | Stubbed API responses (tool call returns) |
| `*.txt` / `*.md` | Sample documents, corpora, or knowledge-base content |
| `*.yaml` | Mock tool definitions (name, description, parameters, canned return) |

## Example: mocked tool response

```yaml
# mocks/search-tool.yaml
tool: web_search
query_pattern: ".*"       # match any query
response:
  results:
    - title: "Example result"
      url: "https://example.com"
      snippet: "This is a canned search result used in harness runs."
```

## Guidelines

- Keep mocks small and focused — they document assumptions, not production data.
- Never commit real credentials, PII, or production snapshots here.
- Name mocks after the tool or data source they replace (`stripe-payment.json`, `openai-chat.yaml`).
- If a mock evolves significantly, add a short comment explaining what changed and why.
