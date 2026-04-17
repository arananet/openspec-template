---
allowed-tools: Read, Write, Bash, Glob
---

Guide the user through creating a new OpenSpec spec for: $ARGUMENTS

Follow these steps exactly:

1. **Read project context** — read `.openspec/config.yaml` and `.openspec/defaults.yaml` to understand the project settings.

2. **Check for duplicates** — list `.openspec/specs/` and check if a spec for "$ARGUMENTS" already exists. If it does, show it to the user and ask if they want to edit it instead.

3. **Determine spec type** — ask the user: is this a `feature` or a `bugfix`? Default to `feature`.

4. **Read the right template** — read `.openspec/templates/feature.spec.yaml` or `.openspec/templates/bugfix.spec.yaml` based on their answer.

5. **Gather required fields** — ask the user for:
   - `description`: one paragraph, what it does and why
   - `acceptance_criteria`: at least one "Given/When/Then" item
   - `test_plan`: at least one test item mapping to an AC
   - `implementation_skill`: suggest options from `agents.implementation_skills` in config.yaml — let them pick or skip

6. **Write the spec file** — create `.openspec/specs/<slug>.spec.yaml` using the template, filled with the user's answers. Set `status: draft`.

7. **Validate** — confirm the file has no empty required fields. Show the created file to the user.

8. **Next step prompt** — tell the user:
   > "Spec created at `.openspec/specs/<slug>.spec.yaml` with status `draft`.
   > When you're ready to implement, set status to `review` and run `/openspec-implement <slug>`."
