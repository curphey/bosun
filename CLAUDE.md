# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bosun is a Claude Code plugin that orchestrates specialized agents for code quality, security, and architecture review. It provides parallel review capabilities through isolated agents that access curated skill knowledge.

## Architecture

```
┌─────────────────────────────────────────────┐
│          BOSUN (Orchestrator)               │
│  Coordinates parallel reviews, aggregates   │
└──────────┬──────────────┬───────────────────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ quality-    │ │ security-  │  ← Agents (parallel, isolated)
    │ agent       │ │ agent      │
    └──────┬──────┘ └─────┬──────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ bosun-      │ │ bosun-     │  ← Skills (knowledge packages)
    │ architect   │ │ security   │
    │ SKILL       │ │ SKILL      │
    └─────────────┘ └────────────┘
```

### Component Roles

| Component | Role | Location |
|-----------|------|----------|
| **Agents** | Specialized workers (isolated contexts) | `agents/*.md` |
| **Skills** | Reusable knowledge packages | `skills/*/SKILL.md` |
| **Commands** | Explicit user-triggered workflows | `commands/*.md` |
| **References** | RAG knowledge for skills | `skills/*/references/` |

## Design Philosophy

Bosun is a **control plane** — it sits at the top of the stack and owns its data:

- **No Runtime Dependencies**: Users install Bosun alone. All knowledge is self-contained.
- **Curated, Not Inherited**: Knowledge is curated from best-in-class sources into owned skills, not inherited or wrapped.
- **Single Source of Truth**: For projects using Bosun, the plugin IS the standard.
- **Parallel Review**: Agents run in isolated contexts for independent analysis.

Upstream repos (superpowers, VoltAgent, claude-design-engineer) are *sources of ideas*, not dependencies.

## Tech Stack

- **Type:** Claude Code Plugin (agents + skills + commands)
- **Languages:** Markdown (skills, agents, commands), Bash (scripts)
- **Distribution:** GitHub via `.claude-plugin/plugin.json`

## Directory Structure

```
bosun/
├── .claude-plugin/
│   └── plugin.json           # Official plugin manifest
├── agents/                   # Specialized workers
│   ├── security-agent.md     # Security auditor
│   ├── quality-agent.md      # Code quality reviewer
│   └── docs-agent.md         # Documentation specialist
├── skills/                   # Knowledge packages
│   ├── bosun-security/
│   │   ├── SKILL.md          # Skill definition
│   │   └── references/       # RAG knowledge
│   ├── bosun-architect/
│   ├── bosun-golang/
│   └── ...
├── commands/                 # User-triggered workflows
│   └── audit.md              # /audit command
├── scripts/                  # Shell utilities
├── references/               # Source research docs
└── assets/templates/         # Project templates
```

## Code Conventions

### Agents (agents/*.md)
- YAML frontmatter with `name`, `description`, `tools`, `model`, `skills`
- Use `disallowedTools: Edit, Write` for read-only agents
- Specify `model: opus` for critical work, `sonnet` for standard
- Reference skills with `skills: [bosun-security]`

### Skills (skills/*/SKILL.md)
- YAML frontmatter with `name`, `description`, `tags`
- `description` should include trigger phrases for auto-discovery
- Keep under 500 lines; put detailed docs in `references/`
- Use code blocks for patterns and examples

### Commands (commands/*.md)
- YAML frontmatter with `name`, `description`
- Document usage, what happens, and example output
- Commands trigger explicit workflows (e.g., `/audit`)

### Naming
- Agents: `{purpose}-agent` (e.g., `security-agent`)
- Skills: `bosun-{purpose}` (e.g., `bosun-golang`)
- Commands: `{verb}` (e.g., `audit`)
- Scripts: `{verb}-{noun}.sh` (e.g., `audit-project.sh`)

## Git Workflow

### Branches
- `main` - stable, tagged releases
- `feature/*` - new skills or capabilities
- `fix/*` - bug fixes
- `chore/*` - maintenance

### Commits
Use conventional commits:
```
feat(agent): add security-agent for parallel review
feat(skill): add bosun-rust specialist
fix(audit): handle missing .github directory
chore(deps): update upstream source tracking
docs: improve README installation section
```

## Common Tasks

### Adding a New Agent
1. Create `agents/{purpose}-agent.md`
2. Define frontmatter: name, description, tools, model, skills
3. Write instructions for the agent's specialized role
4. Reference relevant skills for knowledge

### Adding a New Skill
1. Create directory: `skills/bosun-{name}/`
2. Create `SKILL.md` with frontmatter and instructions
3. Add `references/` subdirectory for RAG knowledge
4. Update README skills table

### Running an Audit
```
/audit          # Full audit (security + quality + docs)
/audit security # Security only
/audit quality  # Quality only
```

### Testing
```bash
# Install plugin locally
/plugin install --local .

# Test with a sample project
cd /path/to/test-project
/audit
```

### Updating Upstream Sources
1. Run `./scripts/sync-upstream.sh` to check for changes
2. Review diffs: `./scripts/sync-upstream.sh --diff {source}`
3. Manually update relevant skills with improvements
4. Mark synced: `./scripts/sync-upstream.sh --mark {source}`

## Troubleshooting

### Quick Diagnostics

```bash
# Check Bosun state
ls -la .bosun/

# Validate findings JSON
jq . .bosun/findings.json

# Check findings summary
jq '.summary' .bosun/findings.json

# List open findings
jq '[.findings[] | select(.status == "open")] | length' .bosun/findings.json
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "No findings to display" | No audit run | Run `/audit` first |
| "findings.json not found" | File deleted or never created | Run `/audit` |
| "Invalid JSON" | Corrupted findings file | Delete and re-audit |
| Agent timeout | Large codebase | Use scoped audit: `/audit security ./src` |
| Fix permission denied | File permissions | Check `ls -la <file>` |

### Recovery Commands

```bash
# Reset Bosun state completely
rm -rf .bosun/

# Reset findings only
rm .bosun/findings.json

# Revert uncommitted fixes
git checkout .

# Revert last committed fix
git revert HEAD
```

### Error Handling Documentation

For comprehensive error handling and recovery procedures, see:
- `docs/error-handling.md` - Full troubleshooting guide
- Each command doc (`commands/*.md`) has an "Error Handling" section

### Reporting Issues

If issues persist:
1. Check existing issues: https://github.com/curphey/bosun/issues
2. Create a new issue with:
   - Command that failed
   - Error message or unexpected behavior
   - Steps to reproduce
