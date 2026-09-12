# Copilot Instructions

Read and follow [AGENTS.md](../AGENTS.md), the shared OpenSpec contract.
It owns task routing, spec readiness, same-PR tests, and verification rules.

For completions without a matching review-ready spec, suggest scaffolding
with `bash scripts/openspec scaffold "<feature-name>"` before production code.
For agent work, follow the full shared workflow; hooks and CI remain the
deterministic checks, not a substitute for reading the spec.

For downstream setup, load [onboarding](../docs/ONBOARDING.md). Copilot can
guide it directly with its question tool or chat; Claude Code is not required.
Preserve placeholders when the user is maintaining the template itself.
