# GitHub Automation Instructions

Follow the root [AGENTS.md](../AGENTS.md). This file is scoped to `.github/`;
the repository-wide contract lives at the root for agent discovery.

Changes to workflows, CODEOWNERS, permissions, and agent goal files affect
the trust boundary. Preserve least privilege, existing security gates, and
human approval requirements. Do not enable autonomous or paid automation
without maintainer authorization. Validate changed workflows before handoff.
