# Copilot Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.

## Before Suggesting Code for Any New Feature

1. Check whether `.openspec/specs/<feature>.spec.yaml` exists.
2. If not, suggest creating one:
   > "I don't see a spec for this feature. Should I scaffold one with
   > `gh openspec scaffold '<feature-name>'`?"
3. Reference `acceptance_criteria` in the spec as the definition of done.

## Spec Files

- Location: `.openspec/specs/*.spec.yaml`
- Templates: `.openspec/templates/feature.spec.yaml` and `bugfix.spec.yaml`
- Config: `.openspec/config.yaml`

## Unconfigured Project

If `.openspec/config.yaml` contains `{{PLACEHOLDER}}` tokens, the project
has not been set up yet. Direct the user to open `CLAUDE.md` for guided setup.
