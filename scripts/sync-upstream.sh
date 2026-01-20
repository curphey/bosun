#!/bin/bash
# Usage: ./scripts/sync-upstream.sh [command] [options]
# Check upstream sources for updates and sync changes

set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/../references/upstream-sources.json"
CACHE_DIR="$SCRIPT_DIR/../.cache/upstream"

show_help() {
    cat << EOF
Usage: $(basename "$0") [command] [options]

Check upstream sources for updates and manage syncing.

Commands:
    list                List all configured upstream sources
    check               Check all sources for updates (default)
    check <source>      Check specific source for updates
    diff <source>       Show diff for a specific source
    mark <source>       Mark a source as synced at current commit
    fetch <source>      Fetch latest from upstream (creates cache)

Options:
    -h, --help          Show this help message
    -v, --verbose       Show detailed output

Upstream Sources File:
    $SOURCES_FILE

Examples:
    $(basename "$0")                    # Check all sources
    $(basename "$0") list               # List configured sources
    $(basename "$0") check superpowers  # Check specific source
    $(basename "$0") diff superpowers   # Show changes
    $(basename "$0") mark superpowers   # Mark as synced
EOF
}

# Check if gh CLI is available
check_gh() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is required but not installed"
        log_info "Install with: brew install gh"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_info "Run: gh auth login"
        exit 1
    fi
}

# Check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        log_info "Install with: brew install jq"
        exit 1
    fi
}

# List all upstream sources
list_sources() {
    check_jq

    if [[ ! -f "$SOURCES_FILE" ]]; then
        log_error "Upstream sources file not found: $SOURCES_FILE"
        exit 1
    fi

    echo ""
    echo -e "${CYAN}Configured Upstream Sources${NC}"
    echo "========================================"
    echo ""

    jq -r '.[] | "Name:        \(.name)\nRepository:  \(.repo)\nBranch:      \(.branch)\nPaths:       \(.paths | join(", "))\nMaps to:     \(.maps_to | join(", "))\nLast synced: \(.last_synced_commit // "never")\n"' "$SOURCES_FILE"
}

# Get latest commit for a repo
get_latest_commit() {
    local repo="$1"
    local branch="${2:-main}"

    gh api "repos/$repo/commits/$branch" --jq '.sha' 2>/dev/null || echo ""
}

# Get commit date
get_commit_date() {
    local repo="$1"
    local sha="$2"

    gh api "repos/$repo/commits/$sha" --jq '.commit.committer.date' 2>/dev/null || echo ""
}

# Check a single source for updates
check_source() {
    local name="$1"
    check_jq
    check_gh

    local source=$(jq -r ".[] | select(.name == \"$name\")" "$SOURCES_FILE")

    if [[ -z "$source" ]]; then
        log_error "Source not found: $name"
        exit 1
    fi

    local repo=$(echo "$source" | jq -r '.repo')
    local branch=$(echo "$source" | jq -r '.branch')
    local last_synced=$(echo "$source" | jq -r '.last_synced_commit // empty')
    local maps_to=$(echo "$source" | jq -r '.maps_to | join(", ")')

    echo ""
    echo -e "${CYAN}Checking: $name${NC}"
    echo "Repository: $repo"
    echo "Branch: $branch"
    echo "Maps to: $maps_to"

    local latest=$(get_latest_commit "$repo" "$branch")

    if [[ -z "$latest" ]]; then
        log_error "Could not fetch latest commit for $repo"
        return 1
    fi

    local latest_date=$(get_commit_date "$repo" "$latest")
    echo "Latest commit: ${latest:0:7} ($latest_date)"

    if [[ -z "$last_synced" ]]; then
        log_warning "Never synced - run 'mark $name' after reviewing"
        echo "New commits available"
    elif [[ "$last_synced" == "$latest" ]]; then
        log_success "Up to date"
    else
        local synced_date=$(get_commit_date "$repo" "$last_synced")
        echo "Last synced:   ${last_synced:0:7} ($synced_date)"
        log_warning "Updates available"

        # Count commits since last sync
        local commit_count=$(gh api "repos/$repo/compare/${last_synced}...${latest}" --jq '.commits | length' 2>/dev/null || echo "?")
        echo "Commits since sync: $commit_count"
    fi

    echo ""
}

# Check all sources
check_all() {
    check_jq

    if [[ ! -f "$SOURCES_FILE" ]]; then
        log_error "Upstream sources file not found: $SOURCES_FILE"
        exit 1
    fi

    local names=$(jq -r '.[].name' "$SOURCES_FILE")

    for name in $names; do
        check_source "$name"
    done
}

# Show diff for a source
show_diff() {
    local name="$1"
    check_jq
    check_gh

    local source=$(jq -r ".[] | select(.name == \"$name\")" "$SOURCES_FILE")

    if [[ -z "$source" ]]; then
        log_error "Source not found: $name"
        exit 1
    fi

    local repo=$(echo "$source" | jq -r '.repo')
    local branch=$(echo "$source" | jq -r '.branch')
    local last_synced=$(echo "$source" | jq -r '.last_synced_commit // empty')
    local paths=$(echo "$source" | jq -r '.paths | join(" ")')

    local latest=$(get_latest_commit "$repo" "$branch")

    if [[ -z "$last_synced" ]]; then
        log_warning "Never synced - showing recent commits"
        gh api "repos/$repo/commits?sha=$branch&per_page=10" --jq '.[].commit | "\(.committer.date | split("T")[0]) \(.message | split("\n")[0])"'
    else
        echo ""
        echo -e "${CYAN}Changes in $name since last sync${NC}"
        echo "From: ${last_synced:0:7}"
        echo "To:   ${latest:0:7}"
        echo ""

        # Show commit messages
        gh api "repos/$repo/compare/${last_synced}...${latest}" --jq '.commits[] | "\(.sha[0:7]) \(.commit.message | split("\n")[0])"' 2>/dev/null || log_error "Could not fetch comparison"

        echo ""
        log_info "To see full diff, visit:"
        echo "https://github.com/$repo/compare/${last_synced}...${latest}"
    fi
}

# Mark a source as synced
mark_synced() {
    local name="$1"
    check_jq
    check_gh

    local source=$(jq -r ".[] | select(.name == \"$name\")" "$SOURCES_FILE")

    if [[ -z "$source" ]]; then
        log_error "Source not found: $name"
        exit 1
    fi

    local repo=$(echo "$source" | jq -r '.repo')
    local branch=$(echo "$source" | jq -r '.branch')

    local latest=$(get_latest_commit "$repo" "$branch")

    if [[ -z "$latest" ]]; then
        log_error "Could not fetch latest commit for $repo"
        exit 1
    fi

    # Update the JSON file
    local tmp_file=$(mktemp)
    jq "map(if .name == \"$name\" then .last_synced_commit = \"$latest\" else . end)" "$SOURCES_FILE" > "$tmp_file"
    mv "$tmp_file" "$SOURCES_FILE"

    log_success "Marked $name as synced at ${latest:0:7}"
}

# Fetch source to cache
fetch_source() {
    local name="$1"
    check_jq
    check_gh

    local source=$(jq -r ".[] | select(.name == \"$name\")" "$SOURCES_FILE")

    if [[ -z "$source" ]]; then
        log_error "Source not found: $name"
        exit 1
    fi

    local repo=$(echo "$source" | jq -r '.repo')
    local branch=$(echo "$source" | jq -r '.branch')

    mkdir -p "$CACHE_DIR"

    local cache_path="$CACHE_DIR/$name"

    if [[ -d "$cache_path" ]]; then
        log_info "Updating cached repository..."
        git -C "$cache_path" fetch origin "$branch"
        git -C "$cache_path" reset --hard "origin/$branch"
    else
        log_info "Cloning repository to cache..."
        gh repo clone "$repo" "$cache_path" -- --branch "$branch" --depth 100
    fi

    log_success "Fetched $name to $cache_path"
}

# Main
COMMAND="${1:-check}"
shift || true

case "$COMMAND" in
    -h|--help)
        show_help
        exit 0
        ;;
    list)
        list_sources
        ;;
    check)
        if [[ $# -gt 0 ]]; then
            check_source "$1"
        else
            check_all
        fi
        ;;
    diff)
        if [[ $# -eq 0 ]]; then
            log_error "Source name required for diff"
            show_help
            exit 1
        fi
        show_diff "$1"
        ;;
    mark)
        if [[ $# -eq 0 ]]; then
            log_error "Source name required for mark"
            show_help
            exit 1
        fi
        mark_synced "$1"
        ;;
    fetch)
        if [[ $# -eq 0 ]]; then
            log_error "Source name required for fetch"
            show_help
            exit 1
        fi
        fetch_source "$1"
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
