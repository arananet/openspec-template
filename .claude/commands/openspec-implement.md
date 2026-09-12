---
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Implement the feature or bugfix described in the OpenSpec spec: $ARGUMENTS

Read `AGENTS.md` first. It is the shared policy for all agents.
Follow these steps exactly — do not skip any gate.

1. **Find the spec** — look for `.openspec/specs/$ARGUMENTS.spec.yaml`. If not found, search `.openspec/specs/` for a close match. If none exists, stop and tell the user to run `/openspec-scaffold $ARGUMENTS` first.

2. **Status gate** — read the `status` field.
   - If `draft`: stop. Tell the user the spec must be moved to `review` before implementation can begin.
   - If `review` or `approved`: proceed.

3. **Read the full spec** — load all fields: `description`, `acceptance_criteria`, `test_plan`, `out_of_scope`, `implementation_skill`, `technical_notes`.
   Confirm a meaningful description and at least one real acceptance criterion
   and test-plan item before implementation. Placeholder examples do not count.

4. **Domain skill gate** — check `implementation_skill` in the spec. If null, check `agents.implementation_skills.default` in `.openspec/config.yaml`.
   - If a skill is set: locate and read its actual instructions, then follow
     the relevant workflow. Mentioning a name is not invocation. If unavailable,
     report it and agree on a fallback; do not silently install a skill.
   - If null: proceed with standard implementation.

5. **Implement against acceptance criteria** — work in small testable slices.
   Add the relevant test and run the cheapest behavior-scoped check after each
   slice. Pause and diagnose failures before continuing. For a small task,
   the spec is the plan; no extra planning document or specialist is required.

6. **Write tests per test_plan** — for every item in `test_plan`, write a corresponding test. Tests go in the same PR — no follow-up test tasks.

7. **Out-of-scope guard** — if any part of the implementation starts to touch something listed in `out_of_scope`, stop and flag it to the user before proceeding.

8. **Self-check** — run `bash scripts/openspec check`, the configured test
   command, and applicable checks. Map results to the acceptance criteria.
   Report commands, results, and anything not verified; do not claim success
   from inspection alone.

9. **Remind** — tell the user to commit the spec file alongside the production code:
   > "Include `.openspec/specs/$ARGUMENTS.spec.yaml` in the same commit as your code changes."
