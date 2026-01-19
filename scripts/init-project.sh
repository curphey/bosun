#!/bin/bash
# Usage: ./scripts/init-project.sh <project-path>
# Bootstrap a new project with Bosun defaults

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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/templates"

log_info "Initializing project at $PROJECT_PATH"

# Create project directory if it doesn't exist
mkdir -p "$PROJECT_PATH"

# Copy CLAUDE.md template
if [[ ! -f "$PROJECT_PATH/CLAUDE.md" ]]; then
    cp "$TEMPLATE_DIR/PROJECT-CLAUDE.md" "$PROJECT_PATH/CLAUDE.md"
    log_success "Created CLAUDE.md"
else
    log_warning "CLAUDE.md already exists, skipping"
fi

log_success "Project initialized"
