# Copilot Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.

## Before Suggesting Code for Any New Feature

1. Check whether `.openspec/specs/<feature>.spec.yaml` exists.
2. If not, suggest creating one:
   > "I don't see a spec for this feature. Should I scaffold one with
   > `gh openspec scaffold '<feature-name>'`?"
3. Do not write production code if the spec is in `draft` status or has no `test_plan`.
4. Reference `acceptance_criteria` as the definition of done.
5. Reference `test_plan` to know what tests to write — write them in the same PR.

## Spec Files

- Location: `.openspec/specs/*.spec.yaml`
- Templates: `.openspec/templates/feature.spec.yaml` and `bugfix.spec.yaml`
- Config: `.openspec/config.yaml`

## Unconfigured Project

If `.openspec/config.yaml` contains `{{PLACEHOLDER}}` tokens, the project
has not been set up yet. Direct the user to open `CLAUDE.md` for guided setup.
