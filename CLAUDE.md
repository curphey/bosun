# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bosun is a Claude Code plugin that enforces development standards through curated specialist agents. It provides planning discipline, git hygiene, CI/CD setup, code quality enforcement, and project auditing.

## Design Philosophy

Bosun is a **control plane** — it sits at the top of the stack and owns its data:

- **No Runtime Dependencies**: Users install Bosun alone. All knowledge is self-contained.
- **Curated, Not Inherited**: Knowledge is curated from best-in-class sources into owned skills, not inherited or wrapped.
- **Single Source of Truth**: For projects using Bosun, the plugin IS the standard.

Upstream repos (superpowers, VoltAgent, claude-design-engineer) are *sources of ideas*, not dependencies. Changes are reviewed, cherry-picked, and adapted — never automatically merged.

## Tech Stack

- **Type:** Claude Code Plugin (skills + scripts)
- **Languages:** Bash (scripts), Markdown (skills)
- **Distribution:** GitHub marketplace via `marketplace.json`

## Directory Structure

```
bosun/
├── marketplace.json              # Plugin metadata
├── skills/                       # Specialist agents (bosun-*)
├── scripts/                      # Shell utilities
├── references/                   # Upstream source tracking
└── assets/templates/             # Project templates
```

## Code Conventions

### Skills (SKILL.md files)
- YAML frontmatter with `name` and `description` (required)
- `description` should include trigger phrases
- Keep under 500 lines; split to references/ if longer
- Use code blocks for examples

### Naming
- Skills: `bosun-{purpose}` (e.g., `bosun-golang`)
- Scripts: `{verb}-{noun}.sh` (e.g., `audit-project.sh`)

### Scripts
- Bash with `set -euo pipefail`
- Use color helpers: `log_info`, `log_success`, `log_warning`, `log_error`
- Include usage comment at top
- Make executable: `chmod +x`

## Git Workflow

### Branches
- `main` - stable, tagged releases
- `feature/*` - new skills or capabilities
- `fix/*` - bug fixes
- `chore/*` - maintenance

### Commits
Use conventional commits:
```
feat(skill): add bosun-rust specialist
fix(audit): handle missing .github directory
chore(deps): update upstream source tracking
docs: improve README installation section
```

## Common Tasks

### Adding a New Skill
1. Create directory: `skills/bosun-{name}/`
2. Create `SKILL.md` with frontmatter and instructions
3. Add to `marketplace.json` skills array
4. Update README skills table

### Testing
```bash
# Install plugin locally
cp -r . ~/.claude/plugins/bosun

# Test scripts
./scripts/audit-project.sh /path/to/test-repo
./scripts/init-project.sh /tmp/test-project
./scripts/sync-upstream.sh
```

### Updating Upstream Sources
1. Run `./scripts/sync-upstream.sh` to check for changes
2. Review diffs: `./scripts/sync-upstream.sh --diff {source}`
3. Manually update relevant skills with improvements
4. Mark synced: `./scripts/sync-upstream.sh --mark {source}`
