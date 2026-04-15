#!/usr/bin/env bash
# OpenSpec setup — installs git hooks into .git/hooks/
set -euo pipefail

HOOKS_DIR=".git/hooks"
SOURCE_DIR="hooks"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "Error: Not a git repository (no .git/hooks directory found)"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: hooks/ directory not found. Run from the repo root."
  exit 1
fi

echo "Installing OpenSpec git hooks..."
echo ""

for hook in pre-commit commit-msg; do
  SRC="$SOURCE_DIR/$hook"
  DEST="$HOOKS_DIR/$hook"

  if [ ! -f "$SRC" ]; then
    echo "  Warning: $SRC not found, skipping"
    continue
  fi

  if [ -f "$DEST" ]; then
    echo "  Backing up existing $hook → $hook.openspec.bak"
    cp "$DEST" "${DEST}.openspec.bak"
  fi

  cp "$SRC" "$DEST"
  chmod +x "$DEST"
  echo "  ✓ Installed $hook"
done

echo ""
echo "Git hooks installed. OpenSpec enforcement is now active."
echo ""
echo "Next steps:"
echo "  1. If config.yaml still has placeholders, open in Claude Code"
echo "     (it will guide you through the setup questions)"
echo "  2. Or edit .openspec/config.yaml manually"
echo "  3. Run: gh openspec check"
