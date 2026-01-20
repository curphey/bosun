#!/bin/bash
# Usage: ./scripts/audit-project.sh <project-path> [options]
# Audit a project for configuration and health issues

set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $1"; }

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

check_pass() {
    log_success "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_warn() {
    log_warning "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

check_fail() {
    log_error "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

show_help() {
    cat << EOF
Usage: $(basename "$0") <project-path> [options]

Audit a project for configuration and health issues.

Options:
    -h, --help      Show this help message
    -v, --verbose   Show detailed output
    -o, --output    Output format: text (default), json
    --strict        Treat warnings as failures

Categories checked:
    - Project structure (README, LICENSE, CLAUDE.md)
    - Git configuration (.gitignore, hooks)
    - CI/CD (GitHub Actions, GitLab CI)
    - Dependencies (package.json, requirements.txt, go.mod)
    - Security (.env files, secrets)
    - Documentation (docs/, CONTRIBUTING.md, CHANGELOG.md)

Examples:
    $(basename "$0") ./my-project
    $(basename "$0") ./my-project --verbose
    $(basename "$0") ./my-project --output json
EOF
}

# Parse arguments
PROJECT_PATH=""
VERBOSE=false
OUTPUT_FORMAT="text"
STRICT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$PROJECT_PATH" ]]; then
    log_error "Project path is required"
    show_help
    exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Directory not found: $PROJECT_PATH"
    exit 1
fi

# Convert to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

echo ""
log_info "Auditing project: $PROJECT_NAME"
log_info "Path: $PROJECT_PATH"
echo ""

# ====================
# Project Structure
# ====================
echo "## Project Structure"
echo ""

# Check for README
if [[ -f "$PROJECT_PATH/README.md" ]]; then
    # Check README has content
    if [[ $(wc -l < "$PROJECT_PATH/README.md") -gt 10 ]]; then
        check_pass "README.md exists with content"
    else
        check_warn "README.md exists but is minimal"
    fi
else
    check_fail "Missing README.md"
fi

# Check for LICENSE
if [[ -f "$PROJECT_PATH/LICENSE" ]] || [[ -f "$PROJECT_PATH/LICENSE.md" ]]; then
    check_pass "LICENSE exists"
else
    check_warn "Missing LICENSE file"
fi

# Check for CLAUDE.md
if [[ -f "$PROJECT_PATH/CLAUDE.md" ]]; then
    check_pass "CLAUDE.md exists"
else
    check_warn "Missing CLAUDE.md (run init-project.sh to create)"
fi

echo ""

# ====================
# Git Configuration
# ====================
echo "## Git Configuration"
echo ""

# Check if git repo
if [[ -d "$PROJECT_PATH/.git" ]]; then
    check_pass "Git repository initialized"
else
    check_warn "Not a git repository"
fi

# Check for .gitignore
if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
    # Check for common ignores
    MISSING_IGNORES=""
    if ! grep -q "node_modules" "$PROJECT_PATH/.gitignore" 2>/dev/null; then
        MISSING_IGNORES="$MISSING_IGNORES node_modules"
    fi
    if ! grep -q "\.env" "$PROJECT_PATH/.gitignore" 2>/dev/null; then
        MISSING_IGNORES="$MISSING_IGNORES .env"
    fi

    if [[ -z "$MISSING_IGNORES" ]]; then
        check_pass ".gitignore exists with common patterns"
    else
        check_warn ".gitignore may be missing:$MISSING_IGNORES"
    fi
else
    check_fail "Missing .gitignore"
fi

echo ""

# ====================
# CI/CD
# ====================
echo "## CI/CD Configuration"
echo ""

CI_FOUND=false

# GitHub Actions
if [[ -d "$PROJECT_PATH/.github/workflows" ]]; then
    WORKFLOW_COUNT=$(find "$PROJECT_PATH/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $WORKFLOW_COUNT -gt 0 ]]; then
        check_pass "GitHub Actions: $WORKFLOW_COUNT workflow(s) found"
        CI_FOUND=true
    fi
fi

# GitLab CI
if [[ -f "$PROJECT_PATH/.gitlab-ci.yml" ]]; then
    check_pass "GitLab CI configuration found"
    CI_FOUND=true
fi

# Jenkins
if [[ -f "$PROJECT_PATH/Jenkinsfile" ]]; then
    check_pass "Jenkinsfile found"
    CI_FOUND=true
fi

if [[ "$CI_FOUND" == false ]]; then
    check_warn "No CI/CD configuration found"
fi

echo ""

# ====================
# Dependencies
# ====================
echo "## Dependencies"
echo ""

DEP_FOUND=false

# Node.js
if [[ -f "$PROJECT_PATH/package.json" ]]; then
    check_pass "package.json found (Node.js)"
    DEP_FOUND=true

    # Check for lock file
    if [[ -f "$PROJECT_PATH/package-lock.json" ]] || [[ -f "$PROJECT_PATH/yarn.lock" ]] || [[ -f "$PROJECT_PATH/pnpm-lock.yaml" ]]; then
        check_pass "Lock file exists"
    else
        check_warn "No package lock file (npm, yarn, or pnpm)"
    fi
fi

# Python
if [[ -f "$PROJECT_PATH/requirements.txt" ]] || [[ -f "$PROJECT_PATH/pyproject.toml" ]] || [[ -f "$PROJECT_PATH/setup.py" ]]; then
    check_pass "Python project detected"
    DEP_FOUND=true
fi

# Go
if [[ -f "$PROJECT_PATH/go.mod" ]]; then
    check_pass "go.mod found (Go)"
    DEP_FOUND=true
fi

# Rust
if [[ -f "$PROJECT_PATH/Cargo.toml" ]]; then
    check_pass "Cargo.toml found (Rust)"
    DEP_FOUND=true
fi

if [[ "$DEP_FOUND" == false ]]; then
    log_info "No dependency files detected"
fi

echo ""

# ====================
# Security
# ====================
echo "## Security"
echo ""

# Check for .env files committed
if [[ -d "$PROJECT_PATH/.git" ]]; then
    ENV_IN_GIT=$(git -C "$PROJECT_PATH" ls-files | grep -E "^\.env$|\.env\." | head -5 || true)
    if [[ -n "$ENV_IN_GIT" ]]; then
        check_fail ".env file(s) committed to git: $ENV_IN_GIT"
    else
        check_pass "No .env files in git history"
    fi
fi

# Check for common secret patterns in tracked files
if [[ -d "$PROJECT_PATH/.git" ]]; then
    # Simple check for obvious API key patterns (not comprehensive)
    SUSPICIOUS=$(git -C "$PROJECT_PATH" grep -l -E "(api[_-]?key|secret[_-]?key|password)\s*[:=]\s*['\"][^'\"]{10,}" -- "*.js" "*.ts" "*.py" "*.go" "*.rb" 2>/dev/null | head -3 || true)
    if [[ -n "$SUSPICIOUS" ]]; then
        check_warn "Potential hardcoded secrets in: $(echo $SUSPICIOUS | tr '\n' ' ')"
    else
        check_pass "No obvious hardcoded secrets detected"
    fi
fi

echo ""

# ====================
# Documentation
# ====================
echo "## Documentation"
echo ""

# Check for docs directory
if [[ -d "$PROJECT_PATH/docs" ]]; then
    DOC_COUNT=$(find "$PROJECT_PATH/docs" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [[ $DOC_COUNT -gt 0 ]]; then
        check_pass "docs/ directory with $DOC_COUNT markdown file(s)"
    else
        check_warn "docs/ directory exists but no markdown files"
    fi
else
    log_info "No docs/ directory"
fi

# CONTRIBUTING.md
if [[ -f "$PROJECT_PATH/CONTRIBUTING.md" ]]; then
    check_pass "CONTRIBUTING.md exists"
else
    log_info "No CONTRIBUTING.md"
fi

# CHANGELOG.md
if [[ -f "$PROJECT_PATH/CHANGELOG.md" ]]; then
    check_pass "CHANGELOG.md exists"
else
    log_info "No CHANGELOG.md"
fi

echo ""

# ====================
# Summary
# ====================
echo "========================================"
echo "## Summary"
echo ""
echo -e "${GREEN}Passed:${NC}   $PASS_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo -e "${RED}Failed:${NC}   $FAIL_COUNT"
echo ""

TOTAL=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
if [[ $TOTAL -gt 0 ]]; then
    SCORE=$((PASS_COUNT * 100 / TOTAL))
    echo "Score: ${SCORE}%"
fi

echo ""

# Exit code
if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
elif [[ "$STRICT" == true ]] && [[ $WARN_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
