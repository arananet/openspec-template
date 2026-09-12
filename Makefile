# OpenSpec project — convenience targets.
# Wraps the most common workflow commands so contributors don't have to
# remember script paths. All targets are thin shims over scripts/openspec
# and project tooling — no logic lives here.

SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

OPENSPEC := scripts/openspec

TEMPLATE_FLAG := $(if $(wildcard .openspec/template),--template,)

.PHONY: help setup check check-strict scaffold scaffold-bug test test-template setup-lint lint-markdown verify-template status clean cleanup-template-specs apply-branch-protection

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup:  ## Install git hooks and make scripts/openspec executable
	bash setup.sh

check:  ## Validate every spec in .openspec/specs/
	$(OPENSPEC) check $(TEMPLATE_FLAG)

check-strict:  ## Validate specs and treat 'draft' status as failure
	$(OPENSPEC) check --strict $(TEMPLATE_FLAG)

scaffold:  ## Create a new feature spec.  Usage: make scaffold name="my feature"
	@if [ -z "$(name)" ]; then echo 'usage: make scaffold name="my feature"'; exit 2; fi
	$(OPENSPEC) scaffold "$(name)"

scaffold-bug:  ## Create a new bugfix spec.  Usage: make scaffold-bug name="login crash"
	@if [ -z "$(name)" ]; then echo 'usage: make scaffold-bug name="login crash"'; exit 2; fi
	$(OPENSPEC) scaffold "$(name)" --type bugfix

test:  ## Verify a spec with configured tests. Usage: make test name=my-feature
	@if [ -z "$(name)" ]; then echo 'usage: make test name=<spec-slug>'; exit 2; fi
	$(OPENSPEC) verify "$(name)"

test-template:  ## Test template contracts locally (bash, git, Ruby; no network)
	bash tests/template.sh
	ruby tests/workflows.rb
	ruby tests/openspec_core_test.rb

setup-lint:  ## Install locked Markdown lint dependencies (Node >= 22, npm; network)
	npm ci --ignore-scripts --prefix tools/lint

lint-markdown:  ## Run the same Markdown lint command as CI (after setup-lint)
	bash scripts/lint-markdown

verify-template: check-strict test-template lint-markdown  ## Verify template contracts and Markdown, not all CI/security jobs

status:  ## Show the active spec's execution state
	$(OPENSPEC) status

clean:  ## Remove generated artifacts (sandbox/test specs only — never touches .openspec/specs/)
	@find . -name '*.bak' -not -path './.git/*' -delete
	@echo "✓ removed .bak files"

cleanup-template-specs:  ## Remove the template's internal design specs (run once on a fresh fork)
	bash scripts/cleanup-template-specs

apply-branch-protection:  ## Push the default-branch ruleset to GitHub (requires gh CLI + admin)
	bash scripts/apply-branch-protection
