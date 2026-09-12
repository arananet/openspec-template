# {{PROJECT_NAME}}

{{BADGES}}

> {{PROJECT_DESCRIPTION}}

---

## Quick start

```bash
# 1. Clone and install
git clone https://github.com/{{GITHUB_OWNER}}/{{PROJECT_NAME}}.git
cd {{PROJECT_NAME}}
bash setup.sh

# 2. Run
{{TEST_COMMAND}}
```

<!--
Replace this section with how to actually install and run YOUR project:
language version, dependencies, env vars, run command, etc.
-->

---

## Usage

<!-- TODO: Show the smallest useful example of your project in action. -->

---

## Contributing

This project uses **OpenSpec** for spec-driven development — every feature
or bugfix starts with a spec file under `.openspec/specs/`. Each spec
includes a `roles` block to assign responsibility (`implementer`,
`reviewer`, `qa`, `product_owner`). See
[`docs/OPENSPEC.md`](docs/OPENSPEC.md) for the full workflow, or
[`CONTRIBUTING.md`](CONTRIBUTING.md) for the contributor checklist.

For small projects, use one concise spec and focused tests; no extra plan
document or specialist is required. Roles are responsibilities, not a minimum
team size. See [incremental adoption](docs/ADOPTION.md) for optional enterprise
capabilities and known enforcement limits. AI spec review is opt-in.

The OpenSpec CLI and hooks require Bash, Git and Ruby >= 2.6 (no gems).
Run `bash scripts/openspec verify <slug>` to record test evidence and
`bash scripts/openspec status` to inspect freshness. Manual work needs no AI
runtime; bounded agent execution is separately opt-in. See [execution](docs/EXECUTION.md).

---

## Documentation

| Topic | Where |
|---|---|
| Spec-driven workflow | [`docs/OPENSPEC.md`](docs/OPENSPEC.md) |
| Small-project adoption and assessment | [`docs/ADOPTION.md`](docs/ADOPTION.md) |
| Guided project setup | [`docs/ONBOARDING.md`](docs/ONBOARDING.md) |
| Branch protection setup | [`docs/BRANCH_PROTECTION.md`](docs/BRANCH_PROTECTION.md) |
| Architecture decisions | [`docs/adr/`](docs/adr/) |
| Security policy | [`SECURITY.md`](SECURITY.md) |
| Support channels | [`SUPPORT.md`](SUPPORT.md) |
| Release history | [`CHANGELOG.md`](CHANGELOG.md) |

---

## License

[MIT](LICENSE)

---

## Developer

Eduardo Arana

## Support this with a ko-fi

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H2H51MPWG)
