#!/usr/bin/env bash
# require-spec-on-commit.sh
# OpenSpec PreToolUse hook — fires when Claude runs any Bash command.
# Intercepts git commit calls and blocks them if source files are staged
# without a corresponding spec change.
#
# Exit 0 = allow the tool use to proceed
# Exit 2 = block the tool use and show the message to the user

COMMAND="$1"

# Only act on git commit commands
if [[ "$COMMAND" != *"git commit"* ]]; then
  exit 0
fi

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)

# Check for staged source files
SOURCE=$(echo "$STAGED" | grep -E '\.(py|ts|js|tsx|jsx|go|java|rb|rs|cpp|c|cs|swift|kt|php)$' || true)

# Check for staged spec files
SPECS=$(echo "$STAGED" | grep -E '\.openspec/specs/.*\.spec\.yaml$' || true)

if [ -n "$SOURCE" ] && [ -z "$SPECS" ]; then
  echo ""
  echo "OpenSpec: commit blocked."
  echo ""
  echo "Source files staged without a spec change:"
  echo "$SOURCE" | sed 's/^/  /'
  echo ""
  echo "Fix:"
  echo "  /openspec-scaffold <feature-name>   (in Claude Code)"
  echo "  gh openspec scaffold '<feature-name>'  (in terminal)"
  echo ""
  exit 2
fi

exit 0
