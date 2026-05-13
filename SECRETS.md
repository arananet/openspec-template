# Secrets Management Policy

This document defines how secrets, credentials, and sensitive configuration
are handled in this repository. Required reading for all contributors.

## Scope

A "secret" is any value that grants access, identifies a privileged
principal, or whose disclosure would harm the project, its users, or the
organization. Examples:

- API keys, OAuth tokens, JWTs
- Database connection strings (with credentials)
- Cloud provider credentials (Azure, AWS, GCP service accounts)
- TLS private keys, SSH private keys, GPG signing keys
- Encryption keys, HMAC secrets
- PII or customer data used during testing

## Rules

1. **Never commit secrets.** Not in code, not in tests, not in CI logs,
   not in `.env` files, not in fixtures.
2. **Never echo secrets** in shell scripts or workflows. Use `::add-mask::`
   when a secret must enter a workflow's environment.
3. **No secrets in URLs**, error messages, telemetry, or logs.
4. **No long-lived cloud credentials.** Use OIDC federation (GitHub Actions
   → cloud) or short-lived workload identity. See `docs/OPENSPEC.md` for
   the Azure pattern.
5. **No shared secrets between environments.** Dev, staging, and prod must
   each have distinct credentials.
6. **Encryption at rest.** Secrets stored locally for development belong
   in your OS keychain, `direnv` + `.envrc` (gitignored), or a vault
   (1Password, Bitwarden, HashiCorp Vault, Azure Key Vault, etc.).

## Enforcement

| Layer | Mechanism |
|---|---|
| Pre-commit | `gitleaks` runs in `hooks/pre-commit` (when installed via `setup.sh`) |
| PR | `.github/workflows/secret-scan.yml` blocks PRs containing detected secrets |
| Repository | GitHub Push Protection enabled — see `docs/BRANCH_PROTECTION.md` |
| Audit | `.github/workflows/scorecard.yml` reports on secret-scanning posture |

## Rotation

| Class | Rotation cadence | Trigger |
|---|---|---|
| Cloud OIDC tokens | N/A (short-lived) | every workflow run |
| API keys (3rd party) | 90 days | calendar or on team change |
| Service account keys | 30 days | calendar; immediate on incident |
| TLS certificates | per CA policy (typically ≤ 90 days) | renewal automation |
| GPG / cosign signing keys | annual | scheduled review |
| Personal access tokens (PATs) | 30 days max | scheduled review |
| Secrets known to a departing contributor | immediate | offboarding checklist |

## Incident response

If a secret is suspected to have leaked:

1. **Revoke immediately.** Don't wait for confirmation.
2. **Rotate** the credential at the issuer.
3. **Audit** access logs for anomalous use during the exposure window.
4. **Purge** the secret from git history if it was committed
   (use `git filter-repo`, then force-push with team notification).
5. **Report** via the channels in [SECURITY.md](SECURITY.md).
6. **Post-mortem** in an ADR under `docs/adr/`.

## What to do if you accidentally commit a secret

1. **Do not** simply delete it in a follow-up commit — it's still in history.
2. Stop, do not push.
3. Rotate the secret with the issuer immediately, even if you haven't pushed.
4. Use `git reset` (if not pushed) or `git filter-repo` (if pushed) to
   remove it from history.
5. Notify [`{{SECURITY_CONTACT}}`](mailto:{{SECURITY_CONTACT}}).

## Tools

- **gitleaks** — local pre-commit and CI scanning
- **GitHub Push Protection** — server-side block on push
- **GitHub Secret Scanning** — partner pattern detection (alerts repo admins)
- **OSSF Scorecard** — aggregate posture metric
- **OIDC federation** — for Azure, AWS, GCP (no stored cloud creds)

## References

- [SECURITY.md](SECURITY.md) — vulnerability disclosure
- [OWASP ASVS V2: Authentication & Secrets](https://owasp.org/www-project-application-security-verification-standard/)
- [GitHub: Best practices for secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
