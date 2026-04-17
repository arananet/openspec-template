---
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Implement the feature or bugfix described in the OpenSpec spec: $ARGUMENTS

Follow these steps exactly — do not skip any gate.

1. **Find the spec** — look for `.openspec/specs/$ARGUMENTS.spec.yaml`. If not found, search `.openspec/specs/` for a close match. If none exists, stop and tell the user to run `/openspec-scaffold $ARGUMENTS` first.

2. **Status gate** — read the `status` field.
   - If `draft`: stop. Tell the user the spec must be moved to `review` before implementation can begin.
   - If `review` or `approved`: proceed.

3. **Read the full spec** — load all fields: `description`, `acceptance_criteria`, `test_plan`, `out_of_scope`, `implementation_skill`, `technical_notes`.

4. **Domain skill gate** — check `implementation_skill` in the spec. If null, check `agents.implementation_skills.default` in `.openspec/config.yaml`.
   - If a skill is set (e.g. `frontend-pro`): invoke it now by mentioning it explicitly — "I will use the **frontend-pro** skill for this implementation."
   - If null: proceed with standard implementation.

5. **Implement against acceptance criteria** — write production code that satisfies each AC. Reference each criterion explicitly as you go.

6. **Write tests per test_plan** — for every item in `test_plan`, write a corresponding test. Tests go in the same PR — no follow-up test tasks.

7. **Out-of-scope guard** — if any part of the implementation starts to touch something listed in `out_of_scope`, stop and flag it to the user before proceeding.

8. **Self-check** — after implementation, go through each AC and confirm it is verifiably met by the code. List any that are not fully covered.

9. **Remind** — tell the user to commit the spec file alongside the production code:
   > "Include `.openspec/specs/$ARGUMENTS.spec.yaml` in the same commit as your code changes."
