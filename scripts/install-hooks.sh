#!/usr/bin/env bash
#
# Install Bosun git hooks
#
# Usage:
#   ./scripts/install-hooks.sh          # Install all hooks
#   ./scripts/install-hooks.sh remove   # Remove installed hooks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$REPO_ROOT/hooks"
GIT_HOOKS_DIR=".git/hooks"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$1" = "remove" ]; then
    echo "Removing Bosun hooks..."

    for hook in pre-commit pre-push; do
        if [ -f "$GIT_HOOKS_DIR/$hook" ]; then
            rm "$GIT_HOOKS_DIR/$hook"
            echo -e "${GREEN}Removed $hook${NC}"
        fi
    done

    echo "Done."
    exit 0
fi

# Check if we're in a git repo
if [ ! -d ".git" ]; then
    echo "Error: Not in a git repository root"
    echo "Run this script from your project root"
    exit 1
fi

# Create hooks directory if needed
mkdir -p "$GIT_HOOKS_DIR"

echo "Installing Bosun hooks..."

# Install pre-commit hook
if [ -f "$HOOKS_DIR/pre-commit" ]; then
    cp "$HOOKS_DIR/pre-commit" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo -e "${GREEN}Installed pre-commit hook${NC}"
else
    echo -e "${YELLOW}Warning: pre-commit hook not found in $HOOKS_DIR${NC}"
fi

# Install pre-push hook if exists
if [ -f "$HOOKS_DIR/pre-push" ]; then
    cp "$HOOKS_DIR/pre-push" "$GIT_HOOKS_DIR/pre-push"
    chmod +x "$GIT_HOOKS_DIR/pre-push"
    echo -e "${GREEN}Installed pre-push hook${NC}"
fi

echo ""
echo "Hooks installed successfully!"
echo ""
echo "To bypass hooks (not recommended):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo ""
echo "To remove hooks:"
echo "  ./scripts/install-hooks.sh remove"
