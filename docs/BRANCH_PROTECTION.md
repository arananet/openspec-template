# Branch Protection

This document describes the **recommended** branch protection and ruleset
configuration for a repository forked from this template. GitHub does not let
a template repo ship protection rules directly — the settings apply at the
repository level — so this file documents exactly what to configure.

Apply these settings at **Settings → Branches → Add rule** (classic branch
protection) or **Settings → Rules → Rulesets** (newer, recommended).

---

## Default branch: `main`

### Required status checks

All of the following must pass before a PR can merge:

- `OpenSpec PR Check / Validate Spec Coverage`
- `OpenSpec PR Check / Run Tests` *(when `ci.run_tests: true`)*
- `OpenSpec AI Review / AI Spec Alignment Review`
- `CodeQL / Analyze (<language>)` — one per language in the matrix
- `Secret Scan / Gitleaks`
- `Dependency Review / Review new dependencies`
- Any language-specific build / lint checks added by your team

Enable **Require branches to be up to date before merging** so checks always
run against the current base.

### Reviews

- **Require a pull request before merging:** yes
- **Required approving reviews:** 1 (2 for repos with >3 maintainers)
- **Dismiss stale pull request approvals when new commits are pushed:** yes
- **Require review from Code Owners:** yes *(honours [.github/CODEOWNERS](../.github/CODEOWNERS))*
- **Require approval of the most recent reviewable push:** yes
- **Require conversation resolution before merging:** yes

### History and merge hygiene

- **Require linear history:** yes *(forbids merge commits on `main`)*
- **Require signed commits:** yes *(protects against spoofed authorship; see
  [GitHub's guide to signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits))*
- **Require deployments to succeed:** only if you have environment gates
- **Lock branch:** no *(only on release branches if you use them)*

### Force pushes and deletions

- **Allow force pushes:** no
- **Allow deletions:** no

### Bypass permissions

- **Who can push directly / bypass:** nobody — not even admins.
  Emergency override should be logged via an Incident issue and reversed as
  soon as possible.

---

## Release branches: `release/*`

Same settings as `main`, plus:

- **Require linear history:** yes
- **Restrict who can push:** only the release manager role
- **Lock branch** once the release is cut

---

## Tags: `v*`

Configure at **Settings → Rules → Rulesets → New tag ruleset**:

- **Require signed tags:** yes
- **Restrict tag creation:** only maintainers
- **Prevent tag deletion:** yes *(protects the SBOM trail)*

---

## Ruleset vs classic branch protection

GitHub now supports two mechanisms:

| Feature | Classic branch protection | Rulesets |
|---|---|---|
| Layered overlap | one rule per pattern | multiple rulesets stack |
| Insights / dry-run | no | yes (`Enforcement: Evaluate`) |
| Tag protection | separate UI | unified |
| Org-level rollout | no | yes |
| Import / export | no | yes (JSON) |

**Recommendation:** use rulesets. Start in **Evaluate** mode, watch the
Insights tab for a week to catch false positives, then switch to **Active**.

---

## Exporting your ruleset

Once configured, export the JSON so future forks can import it:

```bash
gh api repos/{{GITHUB_OWNER}}/{{PROJECT_NAME}}/rulesets > ruleset.json
```

Check `ruleset.json` into a `docs/` or internal infra repo — don't commit it
here (it contains org-specific IDs).

---

## GitHub Advanced Security (optional)

If GHAS is available, additionally enable:

- **Secret scanning** (beyond gitleaks) — GitHub's native engine
- **Push protection** for secret scanning
- **Dependency review** with vulnerability alerts
- **Code scanning** alerts for the default branch

The CodeQL, gitleaks, and dependency-review workflows in this repository are
designed to stay useful whether or not GHAS is enabled.
