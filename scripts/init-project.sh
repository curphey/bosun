#!/bin/bash
# Usage: ./scripts/init-project.sh <project-path>
# Bootstrap a new project with Bosun defaults

set -euo pipefail

# Color helpers
log_info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

show_help() {
    cat << EOF
Usage: $(basename "$0") <project-path> [options]

Bootstrap a new project with Bosun defaults.

Options:
    -h, --help      Show this help message
    --no-gitignore  Skip .gitignore creation
    --no-ci         Skip CI/CD configuration
    --no-docs       Skip documentation structure

Examples:
    $(basename "$0") ./my-project
    $(basename "$0") ./my-project --no-ci
EOF
}

# Parse arguments
PROJECT_PATH=""
CREATE_GITIGNORE=true
CREATE_CI=true
CREATE_DOCS=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --no-gitignore)
            CREATE_GITIGNORE=false
            shift
            ;;
        --no-ci)
            CREATE_CI=false
            shift
            ;;
        --no-docs)
            CREATE_DOCS=false
            shift
            ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            else
                log_error "Unknown option: $1"
                show_help
                exit 1
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../assets/templates"

log_info "Initializing project at $PROJECT_PATH"

# Create project directory if it doesn't exist
mkdir -p "$PROJECT_PATH"

# Copy CLAUDE.md template
if [[ ! -f "$PROJECT_PATH/CLAUDE.md" ]]; then
    if [[ -f "$TEMPLATE_DIR/PROJECT-CLAUDE.md" ]]; then
        cp "$TEMPLATE_DIR/PROJECT-CLAUDE.md" "$PROJECT_PATH/CLAUDE.md"
        log_success "Created CLAUDE.md"
    else
        # Create a basic CLAUDE.md
        cat > "$PROJECT_PATH/CLAUDE.md" << 'CLAUDEMD'
# CLAUDE.md

This file provides guidance to Claude Code when working with this codebase.

## Project Overview

[Describe your project here]

## Tech Stack

[List your technologies]

## Code Conventions

[Describe your coding standards]

## Common Tasks

[List common development tasks]
CLAUDEMD
        log_success "Created CLAUDE.md (basic template)"
    fi
else
    log_warning "CLAUDE.md already exists, skipping"
fi

# Create .gitignore
if [[ "$CREATE_GITIGNORE" == true ]] && [[ ! -f "$PROJECT_PATH/.gitignore" ]]; then
    cat > "$PROJECT_PATH/.gitignore" << 'GITIGNORE'
# Dependencies
node_modules/
vendor/
venv/
.venv/
__pycache__/
*.pyc

# Build outputs
dist/
build/
*.egg-info/
target/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
.env.*.local
*.env

# Secrets (never commit these)
*.pem
*.key
credentials.json
secrets.json

# Logs
*.log
logs/

# Testing
coverage/
.coverage
htmlcov/
.pytest_cache/
.nyc_output/

# Bosun
.bosun/
GITIGNORE
    log_success "Created .gitignore"
elif [[ "$CREATE_GITIGNORE" == true ]]; then
    log_warning ".gitignore already exists, skipping"
fi

# Create GitHub Actions CI workflow
if [[ "$CREATE_CI" == true ]]; then
    mkdir -p "$PROJECT_PATH/.github/workflows"
    if [[ ! -f "$PROJECT_PATH/.github/workflows/ci.yml" ]]; then
        cat > "$PROJECT_PATH/.github/workflows/ci.yml" << 'CIWORKFLOW'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # Uncomment and adjust for your project:
      # - name: Install dependencies
      #   run: npm ci

      # - name: Run linter
      #   run: npm run lint

      # - name: Run tests
      #   run: npm test

      # - name: Build
      #   run: npm run build
CIWORKFLOW
        log_success "Created .github/workflows/ci.yml"
    else
        log_warning "CI workflow already exists, skipping"
    fi
fi

# Create documentation structure
if [[ "$CREATE_DOCS" == true ]]; then
    mkdir -p "$PROJECT_PATH/docs"

    # Create README if it doesn't exist
    if [[ ! -f "$PROJECT_PATH/README.md" ]]; then
        PROJECT_NAME=$(basename "$PROJECT_PATH")
        cat > "$PROJECT_PATH/README.md" << README
# ${PROJECT_NAME}

[Project description]

## Installation

\`\`\`bash
# Installation instructions
\`\`\`

## Usage

\`\`\`bash
# Usage examples
\`\`\`

## Development

\`\`\`bash
# Development setup
\`\`\`

## License

[License information]
README
        log_success "Created README.md"
    else
        log_warning "README.md already exists, skipping"
    fi

    # Create CONTRIBUTING.md
    if [[ ! -f "$PROJECT_PATH/CONTRIBUTING.md" ]]; then
        cat > "$PROJECT_PATH/CONTRIBUTING.md" << 'CONTRIBUTING'
# Contributing

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## Code Style

Please follow the existing code style and conventions.

## Pull Request Process

1. Update documentation as needed
2. Add tests for new functionality
3. Ensure all tests pass
4. Request review from maintainers
CONTRIBUTING
        log_success "Created CONTRIBUTING.md"
    fi
fi

# Create .bosun directory for findings
mkdir -p "$PROJECT_PATH/.bosun"
echo '{}' > "$PROJECT_PATH/.bosun/.gitkeep"
log_success "Created .bosun/ directory"

log_info ""
log_success "Project initialized successfully!"
log_info ""
log_info "Next steps:"
log_info "  1. cd $PROJECT_PATH"
log_info "  2. Edit CLAUDE.md with your project details"
log_info "  3. Run /audit to check your project"
