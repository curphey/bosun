# Contributing to Bosun

Thank you for your interest in contributing to Bosun! This guide will help you get started.

## Design Philosophy

Before contributing, understand Bosun's core principles:

- **No Runtime Dependencies** — Users install Bosun alone. All knowledge is self-contained.
- **Curated, Not Inherited** — Knowledge is curated from best-in-class sources, not wrapped or inherited.
- **Single Source of Truth** — For projects using Bosun, the plugin IS the standard.

## Getting Started

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/curphey/bosun.git
   cd bosun
   ```

2. Install locally for testing:
   ```bash
   cp -r . ~/.claude/plugins/bosun
   ```

3. Test your changes in Claude Code.

## Contributing Skills

### Creating a New Skill

1. Create directory: `skills/bosun-{name}/`
2. Create `SKILL.md` with required frontmatter:
   ```yaml
   ---
   name: bosun-{name}
   description: Brief description including trigger phrases
   ---
   ```
3. Add skill content (keep under 500 lines)
4. Add to `marketplace.json` skills array
5. Update README skills table

### Skill Guidelines

- Include trigger phrases in the description
- Use code blocks for examples
- Split long content to `references/` if needed
- Focus on actionable, specific guidance
- Avoid duplicating linter rules — let tools do deterministic work

## Contributing Scripts

Scripts live in `scripts/` and follow these conventions:

- Use `set -euo pipefail` at the top
- Include usage comment explaining the script
- Use color helpers for output:
  ```bash
  log_info()    { echo -e "\033[0;34m[INFO]\033[0m $1"; }
  log_success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
  log_warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
  log_error()   { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
  ```
- Make executable: `chmod +x scripts/your-script.sh`
- Name format: `{verb}-{noun}.sh`

## Upstream Sync Workflow

Bosun curates knowledge from upstream sources. To sync:

1. Check for updates:
   ```bash
   ./scripts/sync-upstream.sh --check
   ```

2. Review changes:
   ```bash
   ./scripts/sync-upstream.sh --diff {source}
   ```

3. Manually update relevant skills with improvements

4. Mark as synced:
   ```bash
   ./scripts/sync-upstream.sh --mark {source}
   ```

5. Commit the updated `upstream-sources.json`

## Git Workflow

### Branches

- `main` — stable, tagged releases
- `feature/*` — new skills or capabilities
- `fix/*` — bug fixes
- `chore/*` — maintenance

### Commit Messages

Use conventional commits:

```
feat(skill): add bosun-rust specialist
fix(audit): handle missing .github directory
chore(deps): update upstream source tracking
docs: improve README installation section
```

### Pull Requests

1. Create a feature branch from `main`
2. Make your changes
3. Test locally with Claude Code
4. Submit PR using the template
5. Address review feedback

## Testing

```bash
# Test scripts
./scripts/audit-project.sh /path/to/test-repo
./scripts/init-project.sh /tmp/test-project
./scripts/sync-upstream.sh --check

# Test skills by invoking them in Claude Code
```

## Code of Conduct

Be respectful and constructive. Focus on improving Bosun for everyone.

## Questions?

- Open a [Discussion](https://github.com/curphey/bosun/discussions) for questions
- Use [Issues](https://github.com/curphey/bosun/issues) for bugs and feature requests
