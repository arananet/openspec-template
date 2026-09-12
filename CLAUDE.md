# Claude Code Instructions

Read and follow [AGENTS.md](AGENTS.md), the shared OpenSpec contract.
It defines task routing, spec gates, incremental implementation, and verification.

Load [docs/ONBOARDING.md](docs/ONBOARDING.md) only when configuring a
downstream project. Do not onboard this template during template maintenance.

Claude Code entry points:

- `/openspec-scaffold <name>`: clarify and scaffold a spec.
- `/openspec-implement <slug>`: implement and test a review-ready spec.
- `/openspec-check`: validate spec coverage.

These commands complement the shared rules and `bash scripts/openspec check`.
Use the available question tool for onboarding; ask in chat when unavailable.
