# OpenSpec project — convenience targets.
# Wraps the most common workflow commands so contributors don't have to
# remember script paths. All targets are thin shims over scripts/openspec
# and project tooling — no logic lives here.

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

OPENSPEC := scripts/openspec

# Read testing.test_command from .openspec/config.yaml (best-effort).
TEST_CMD := $(shell grep -E '^[[:space:]]*test_command:' .openspec/config.yaml 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*test_command:[[:space:]]*//' | sed -E 's/^"(.*)"$$/\1/')

.PHONY: help setup check check-strict scaffold scaffold-bug test status clean cleanup-template-specs

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup:  ## Install git hooks and make scripts/openspec executable
	bash setup.sh

check:  ## Validate every spec in .openspec/specs/
	$(OPENSPEC) check

check-strict:  ## Validate specs and treat 'draft' status as failure
	$(OPENSPEC) check --strict

scaffold:  ## Create a new feature spec.  Usage: make scaffold name="my feature"
	@if [ -z "$(name)" ]; then echo 'usage: make scaffold name="my feature"'; exit 2; fi
	$(OPENSPEC) scaffold "$(name)"

scaffold-bug:  ## Create a new bugfix spec.  Usage: make scaffold-bug name="login crash"
	@if [ -z "$(name)" ]; then echo 'usage: make scaffold-bug name="login crash"'; exit 2; fi
	$(OPENSPEC) scaffold "$(name)" --type bugfix

test:  ## Run testing.test_command from .openspec/config.yaml
	@if [ -z "$(TEST_CMD)" ] || echo "$(TEST_CMD)" | grep -q '{{'; then \
		echo "error: testing.test_command not configured in .openspec/config.yaml"; exit 1; \
	fi
	@echo "→ $(TEST_CMD)"
	@bash -c '$(TEST_CMD)'

status:  ## Show OpenSpec configuration status
	@if grep -q '{{' .openspec/config.yaml 2>/dev/null; then \
		echo "STATUS: NOT_CONFIGURED — run onboarding (open in Claude Code or edit .openspec/config.yaml)"; \
	else \
		echo "STATUS: CONFIGURED"; \
	fi
	@$(OPENSPEC) check 2>&1 | tail -5 || true

clean:  ## Remove generated artifacts (sandbox/test specs only — never touches .openspec/specs/)
	@find . -name '*.bak' -not -path './.git/*' -delete
	@echo "✓ removed .bak files"

cleanup-template-specs:  ## Remove the template's internal design specs (run once on a fresh fork)
	bash scripts/cleanup-template-specs
