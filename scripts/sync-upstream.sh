#!/bin/bash
# Usage: ./scripts/sync-upstream.sh [--diff <source>] [--mark <source>] [--check]
# Check upstream sources for updates and manage sync state
#
# Commands:
#   (no args)       List all upstream sources and their sync status
#   --check         Check all sources for new commits since last sync
#   --diff <name>   Show commits and changed files since last sync
#   --mark <name>   Mark source as synced at current HEAD

set -euo pipefail

# Color helpers
log_info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
log_warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$SCRIPT_DIR/../references/upstream-sources.json"
GITHUB_API="https://api.github.com"

if [[ ! -f "$SOURCES_FILE" ]]; then
    log_error "Upstream sources file not found: $SOURCES_FILE"
    exit 1
fi

# Check for required tools
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_error "curl is required but not installed"
    exit 1
fi

# Get source by name from JSON
get_source() {
    local name="$1"
    jq -r ".[] | select(.name == \"$name\")" "$SOURCES_FILE"
}

# Get latest commit SHA for a repo/branch
get_latest_commit() {
    local repo="$1"
    local branch="$2"

    local response
    response=$(curl -s -f "$GITHUB_API/repos/$repo/commits/$branch" 2>/dev/null) || {
        echo ""
        return 1
    }
    echo "$response" | jq -r '.sha // empty'
}

# Get commits between two SHAs
get_commits_since() {
    local repo="$1"
    local since_sha="$2"
    local branch="$3"

    if [[ -z "$since_sha" || "$since_sha" == "null" ]]; then
        # No previous sync, get recent commits
        curl -s -f "$GITHUB_API/repos/$repo/commits?sha=$branch&per_page=10" 2>/dev/null | \
            jq -r '.[] | "  \(.sha[0:7]) \(.commit.message | split("\n")[0])"' 2>/dev/null || echo "  (unable to fetch)"
    else
        # Get commits since last sync
        curl -s -f "$GITHUB_API/repos/$repo/compare/$since_sha...$branch" 2>/dev/null | \
            jq -r '.commits[] | "  \(.sha[0:7]) \(.commit.message | split("\n")[0])"' 2>/dev/null || echo "  (unable to fetch)"
    fi
}

# Get changed files between two SHAs
get_changed_files() {
    local repo="$1"
    local since_sha="$2"
    local branch="$3"
    local paths="$4"

    if [[ -z "$since_sha" || "$since_sha" == "null" ]]; then
        log_warning "No previous sync - showing recent tree structure"
        # Show directory listing for tracked paths
        for path in $(echo "$paths" | jq -r '.[]'); do
            echo "  Path: $path"
            curl -s -f "$GITHUB_API/repos/$repo/contents/${path}?ref=$branch" 2>/dev/null | \
                jq -r '.[] | "    \(.type): \(.name)"' 2>/dev/null || echo "    (unable to fetch)"
        done
    else
        curl -s -f "$GITHUB_API/repos/$repo/compare/$since_sha...$branch" 2>/dev/null | \
            jq -r '.files[] | "  \(.status): \(.filename)"' 2>/dev/null || echo "  (unable to fetch)"
    fi
}

# List all sources with status
list_sources() {
    log_info "Upstream sources:"
    echo ""

    local sources
    sources=$(jq -c '.[]' "$SOURCES_FILE")

    while IFS= read -r source; do
        local name repo branch last_synced maps_to
        name=$(echo "$source" | jq -r '.name')
        repo=$(echo "$source" | jq -r '.repo')
        branch=$(echo "$source" | jq -r '.branch')
        last_synced=$(echo "$source" | jq -r '.last_synced_commit // "never"')
        maps_to=$(echo "$source" | jq -r '.maps_to | join(", ")')

        echo "  $name"
        echo "    Repo: $repo ($branch)"
        echo "    Last synced: ${last_synced:0:7}"
        echo "    Maps to: $maps_to"
        echo ""
    done <<< "$sources"
}

# Check all sources for updates
check_sources() {
    log_info "Checking upstream sources for updates..."
    echo ""

    local sources has_updates=false
    sources=$(jq -c '.[]' "$SOURCES_FILE")

    while IFS= read -r source; do
        local name repo branch last_synced
        name=$(echo "$source" | jq -r '.name')
        repo=$(echo "$source" | jq -r '.repo')
        branch=$(echo "$source" | jq -r '.branch')
        last_synced=$(echo "$source" | jq -r '.last_synced_commit')

        local latest
        latest=$(get_latest_commit "$repo" "$branch")

        if [[ -z "$latest" ]]; then
            log_warning "$name: Unable to fetch (rate limited or network error)"
            continue
        fi

        if [[ -z "$last_synced" || "$last_synced" == "null" ]]; then
            log_warning "$name: Never synced (latest: ${latest:0:7})"
            has_updates=true
        elif [[ "$latest" != "$last_synced" ]]; then
            log_warning "$name: Updates available (${last_synced:0:7} -> ${latest:0:7})"
            has_updates=true
        else
            log_success "$name: Up to date (${latest:0:7})"
        fi
    done <<< "$sources"

    echo ""
    if [[ "$has_updates" == "true" ]]; then
        log_info "Run with --diff <source> to see changes"
    fi
}

# Show diff for a specific source
show_diff() {
    local name="$1"

    local source
    source=$(get_source "$name")

    if [[ -z "$source" ]]; then
        log_error "Unknown source: $name"
        log_info "Available sources:"
        jq -r '.[].name' "$SOURCES_FILE" | sed 's/^/  /'
        exit 1
    fi

    local repo branch last_synced paths
    repo=$(echo "$source" | jq -r '.repo')
    branch=$(echo "$source" | jq -r '.branch')
    last_synced=$(echo "$source" | jq -r '.last_synced_commit')
    paths=$(echo "$source" | jq -c '.paths')

    local latest
    latest=$(get_latest_commit "$repo" "$branch")

    if [[ -z "$latest" ]]; then
        log_error "Unable to fetch latest commit (rate limited or network error)"
        exit 1
    fi

    log_info "Diff for $name ($repo)"
    echo "  Branch: $branch"
    echo "  Last synced: ${last_synced:-never}"
    echo "  Latest: ${latest:0:7}"
    echo "  Tracked paths: $(echo "$paths" | jq -r 'join(", ")')"
    echo ""

    log_info "Commits:"
    get_commits_since "$repo" "$last_synced" "$branch"
    echo ""

    log_info "Changed files:"
    get_changed_files "$repo" "$last_synced" "$branch" "$paths"
    echo ""

    log_info "To mark as synced: ./scripts/sync-upstream.sh --mark $name"
}

# Mark a source as synced
mark_synced() {
    local name="$1"

    local source
    source=$(get_source "$name")

    if [[ -z "$source" ]]; then
        log_error "Unknown source: $name"
        log_info "Available sources:"
        jq -r '.[].name' "$SOURCES_FILE" | sed 's/^/  /'
        exit 1
    fi

    local repo branch
    repo=$(echo "$source" | jq -r '.repo')
    branch=$(echo "$source" | jq -r '.branch')

    local latest
    latest=$(get_latest_commit "$repo" "$branch")

    if [[ -z "$latest" ]]; then
        log_error "Unable to fetch latest commit (rate limited or network error)"
        exit 1
    fi

    # Update the JSON file
    local temp_file
    temp_file=$(mktemp)

    jq --arg name "$name" --arg sha "$latest" \
        '(.[] | select(.name == $name) | .last_synced_commit) = $sha' \
        "$SOURCES_FILE" > "$temp_file"

    mv "$temp_file" "$SOURCES_FILE"

    log_success "Marked $name as synced at ${latest:0:7}"
    log_info "Don't forget to commit the updated upstream-sources.json"
}

# Main
case "${1:-}" in
    --check)
        check_sources
        ;;
    --diff)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 --diff <source>"
            exit 1
        fi
        show_diff "$2"
        ;;
    --mark)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 --mark <source>"
            exit 1
        fi
        mark_synced "$2"
        ;;
    --help|-h)
        echo "Usage: $0 [--check] [--diff <source>] [--mark <source>]"
        echo ""
        echo "Commands:"
        echo "  (no args)       List all upstream sources and their sync status"
        echo "  --check         Check all sources for new commits since last sync"
        echo "  --diff <name>   Show commits and changed files since last sync"
        echo "  --mark <name>   Mark source as synced at current HEAD"
        echo ""
        echo "Workflow:"
        echo "  1. Run --check to see which sources have updates"
        echo "  2. Run --diff <source> to review changes"
        echo "  3. Manually update relevant bosun skills with improvements"
        echo "  4. Run --mark <source> to record the sync"
        echo "  5. Commit the updated upstream-sources.json"
        ;;
    "")
        list_sources
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Run '$0 --help' for usage"
        exit 1
        ;;
esac
