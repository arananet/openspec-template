# Security Policy

## Supported Versions

Security fixes are applied to the latest release line of `{{PROJECT_NAME}}`.
Older releases receive fixes only when explicitly flagged in the
[CHANGELOG](CHANGELOG.md).

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| older   | on a case-by-case basis |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately through one of these channels, in order of
preference:

1. **GitHub Private Vulnerability Reporting** — open the repository's
   **Security** tab and click **Report a vulnerability**.
2. **Email** — send details to `{{SECURITY_CONTACT}}`. Encrypt with the
   project's PGP key if the report contains exploit details.

### What to include

- Affected version, commit, or branch
- Reproduction steps (minimal proof-of-concept preferred)
- Impact assessment (what an attacker can achieve)
- Any suggested remediation

### Our commitments

- **Acknowledge** the report within **2 business days**.
- **Triage** and provide a severity assessment within **5 business days**.
- **Fix** critical and high-severity issues within **30 days** of triage.
- **Disclose** via a GitHub Security Advisory and credit the reporter (unless
  they request anonymity).

## Scope

In scope:

- Code in this repository
- Public-facing workflows in `.github/workflows/`
- Configuration under `.openspec/` and `.claude/` that affects repo integrity

Out of scope:

- Vulnerabilities in dependencies — report those upstream. Dependabot and the
  `dependency-review` workflow are configured to catch vulnerable direct
  dependencies automatically.
- Findings that require physical access, social engineering, or non-default
  build configurations.
- Denial-of-service via resource exhaustion against a user's own machine.

## Security Practices in This Repository

This repository ships with several defensive defaults:

- **OpenSpec gate** — no code merges without an approved spec and tests.
- **CodeQL** — static analysis on every PR and weekly.
- **Gitleaks** — secret scanning on every PR.
- **Dependency Review** — blocks PRs that introduce known-vulnerable
  dependencies.
- **Dependabot** — weekly updates for GitHub Actions and (when enabled) the
  project's package ecosystems.
- **SBOM** — CycloneDX SBOMs generated on release.
- **Pinned Actions** — all third-party actions pinned to commit SHAs.
- **Least-privilege permissions** — every workflow starts from
  `permissions: read-all` and escalates only where required.

If you believe any of these controls is misconfigured, please report it as
described above.
