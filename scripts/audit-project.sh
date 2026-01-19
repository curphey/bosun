#!/bin/bash
# Usage: ./scripts/audit-project.sh <project-path>
# Audit a project for configuration and health issues

set -euo pipefail

# Color helpers
log_info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

if [[ $# -lt 1 ]]; then
    log_error "Usage: $0 <project-path>"
    exit 1
fi

PROJECT_PATH="$1"

if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Directory not found: $PROJECT_PATH"
    exit 1
fi

log_info "Auditing project at $PROJECT_PATH"

# Check for CLAUDE.md
if [[ -f "$PROJECT_PATH/CLAUDE.md" ]]; then
    log_success "CLAUDE.md exists"
else
    log_warning "Missing CLAUDE.md"
fi

# Check for README
if [[ -f "$PROJECT_PATH/README.md" ]]; then
    log_success "README.md exists"
else
    log_warning "Missing README.md"
fi

# Check for LICENSE
if [[ -f "$PROJECT_PATH/LICENSE" ]]; then
    log_success "LICENSE exists"
else
    log_warning "Missing LICENSE"
fi

# Check for .gitignore
if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
    log_success ".gitignore exists"
else
    log_warning "Missing .gitignore"
fi

# Check for CI/CD
if [[ -d "$PROJECT_PATH/.github/workflows" ]]; then
    log_success "GitHub Actions workflows exist"
else
    log_warning "Missing GitHub Actions workflows"
fi

log_info "Audit complete"
