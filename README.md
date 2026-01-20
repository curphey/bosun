# Bosun

Ship's officer for your codebase — keeping everything shipshape.

Bosun is a Claude Code plugin that orchestrates specialized agents for code quality, security, and architecture review. It provides parallel review capabilities through isolated agents that access curated skill knowledge.

## Quick Start

```bash
# Install globally
/plugin install --global bosun@curphey/bosun

# Run a full audit
/audit

# Fix issues (auto-fixes applied, others prompted)
/fix

# View current findings
/status
```

## Architecture

```
┌─────────────────────────────────────────────┐
│          BOSUN (Orchestrator)               │
│  Coordinates parallel reviews, aggregates   │
└──────────┬──────────────┬───────────────────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ security-   │ │ quality-   │  ← Agents (parallel, isolated)
    │ agent       │ │ agent      │
    └──────┬──────┘ └─────┬──────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ bosun-      │ │ bosun-     │  ← Skills (knowledge packages)
    │ security    │ │ architect  │
    │ SKILL       │ │ SKILL      │
    └──────┬──────┘ └─────┬──────┘
           │              │
    ┌──────▼──────┐ ┌─────▼──────┐
    │ references/ │ │ references/│  ← RAG (curated knowledge)
    └─────────────┘ └────────────┘
```

## Commands

| Command | Description |
|---------|-------------|
| `/audit [scope] [path]` | Analyze project and produce findings |
| `/fix [scope] [--auto\|--interactive]` | Remediate findings from audit |
| `/improve [--plan\|--execute]` | Prioritize and implement improvements |
| `/status` | Show findings summary |

### Scopes

- `full` — All agents (default)
- `security` — Security vulnerabilities, secrets, auth
- `quality` — Code quality, patterns, linting
- `docs` — Documentation completeness
- `architecture` — System design, dependencies
- `devops` — CI/CD, IaC, containers
- `ux-ui` — Accessibility, usability (frontend)
- `testing` — Test coverage, quality
- `performance` — Algorithms, optimization

### Command Workflow

```
/audit → writes .bosun/findings.json
/fix   → reads findings, applies fixes, updates status
/improve → reads findings, prioritizes, plans/executes sprints
/status → shows current summary
```

## Agents

Agents are specialized workers that run in isolated contexts for independent analysis:

| Agent | Purpose | Model |
|-------|---------|-------|
| `orchestrator-agent` | Coordinates agents, aggregates findings | Sonnet |
| `security-agent` | Vulnerabilities, secrets, auth | Opus |
| `quality-agent` | Code quality, patterns, linting | Sonnet |
| `docs-agent` | Documentation, comments, READMEs | Sonnet |
| `architecture-agent` | System design, dependencies | Sonnet |
| `devops-agent` | CI/CD, IaC, containers | Sonnet |
| `ux-ui-agent` | Accessibility, usability | Sonnet |
| `testing-agent` | Test coverage, quality | Sonnet |
| `performance-agent` | Algorithms, optimization | Sonnet |

All agents have **full capabilities** — they can analyze, fix, refactor, and create code and documentation.

## Skills

Skills are knowledge packages that agents reference for domain expertise:

| Skill | Purpose |
|-------|---------|
| `bosun-architect` | Software architecture patterns, SOLID, DDD, Clean Architecture |
| `bosun-security` | Secret management, injection prevention, auth patterns, SAST |
| `bosun-threat-model` | STRIDE methodology, attack trees, DFDs, CVSS/DREAD |
| `bosun-devops` | CI/CD patterns, IaC, container best practices |
| `bosun-testing` | Testing strategies, coverage, mocking patterns |
| `bosun-performance` | Algorithm optimization, profiling, caching |
| `bosun-docs-writer` | README templates, API docs, changelogs |
| `bosun-ux-ui` | WCAG accessibility, design systems, usability |
| `bosun-project-auditor` | Project structure, configuration, hygiene |
| `bosun-seo-llm` | SEO optimization, structured data, LLM content |

### Language Skills

| Skill | Languages/Frameworks |
|-------|---------------------|
| `bosun-golang` | Go idioms, error handling, concurrency |
| `bosun-typescript` | TypeScript strict mode, ESLint, patterns |
| `bosun-python` | PEP 8, type hints, pytest, async |
| `bosun-rust` | Ownership, lifetimes, error handling |
| `bosun-java` | Modern Java, Spring Boot, testing |
| `bosun-csharp` | .NET Core, ASP.NET, LINQ, async |

## Findings Schema

Audits produce findings in `.bosun/findings.json`:

```json
{
  "version": "1.0.0",
  "metadata": {
    "project": "my-project",
    "auditedAt": "2025-01-20T10:00:00Z",
    "scope": "full"
  },
  "summary": {
    "total": 8,
    "bySeverity": { "critical": 1, "high": 2, "medium": 3, "low": 2 }
  },
  "findings": [
    {
      "id": "SEC-001",
      "category": "security",
      "severity": "critical",
      "title": "Hardcoded API key",
      "location": { "file": "src/config.js", "line": 15 },
      "interactionTier": "confirm"
    }
  ]
}
```

### Finding ID Prefixes

| Category | Prefix |
|----------|--------|
| Security | SEC |
| Quality | QUA |
| Documentation | DOC |
| Architecture | ARC |
| DevOps | DEV |
| UX/UI | UXU |
| Testing | TST |
| Performance | PRF |

## Interaction Tiers

When running `/fix`, findings are organized by interaction tier:

| Tier | Approval | Examples |
|------|----------|----------|
| **auto** | None (silent) | Formatting, linting, typos |
| **confirm** | Batch | Env var extraction, import sorting |
| **approve** | Individual | API changes, refactoring |

Use `--auto` to only apply auto-tier fixes, or `--interactive` to approve each fix individually.

## Installation

**Global** (available in all projects):
```
/plugin install --global bosun@curphey/bosun
```

**Project** (available to anyone working on this repo):
```
/plugin install --project bosun@curphey/bosun
```

**User** (just for yourself in this project):
```
/plugin install bosun@curphey/bosun
```

**Local** (development/testing):
```
/plugin install --local .
```

## Usage Examples

### Full Audit

```bash
/audit
# Spawns security, quality, and docs agents in parallel
# Outputs findings to .bosun/findings.json
# Displays summary report
```

### Security-Only Audit

```bash
/audit security
# Only security-agent runs
# Faster for targeted reviews
```

### Auto-Fix Issues

```bash
/fix --auto
# Applies all auto-tier fixes silently
# (formatting, linting, typos)
```

### Interactive Fix

```bash
/fix --interactive
# Prompts for each fix individually
# Maximum control over changes
```

### Improvement Planning

```bash
/improve --plan
# Generates prioritized sprint plan
# Shows effort vs. impact analysis
```

### Example Output

```markdown
# Audit Report: my-project

**Date**: 2025-01-20
**Scope**: full
**Agents**: security-agent, quality-agent, docs-agent

## Summary

| Severity | Count |
|----------|-------|
| Critical | 1     |
| High     | 2     |
| Medium   | 3     |
| Low      | 2     |

## Critical/High Findings

1. [SEC-001] Hardcoded API key - src/config.js:15
2. [SEC-002] SQL injection risk - src/db/query.js:42
3. [QUA-001] O(n²) complexity - src/search.js:88

## Recommendations

1. Extract all secrets to environment variables
2. Use parameterized queries for database access
3. Optimize search algorithm to O(n log n)

## Next Steps

- Run `/fix` to remediate findings
- Run `/fix --auto` for auto-tier fixes only
- Run `/status` for current summary
```

## Directory Structure

```
bosun/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── agents/                       # Specialized workers
│   ├── orchestrator-agent.md    # Master coordinator
│   ├── security-agent.md        # Security auditor
│   ├── quality-agent.md         # Code quality
│   ├── docs-agent.md            # Documentation
│   ├── architecture-agent.md    # System design
│   ├── devops-agent.md          # CI/CD, IaC
│   ├── ux-ui-agent.md           # Accessibility
│   ├── testing-agent.md         # Test coverage
│   └── performance-agent.md     # Optimization
├── skills/                       # Knowledge packages
│   ├── bosun-security/
│   ├── bosun-architect/
│   ├── bosun-devops/
│   ├── bosun-testing/
│   ├── bosun-performance/
│   ├── bosun-golang/
│   ├── bosun-typescript/
│   ├── bosun-python/
│   ├── bosun-rust/
│   ├── bosun-java/
│   ├── bosun-csharp/
│   └── ...
├── commands/                     # Slash commands
│   ├── audit.md                 # /audit
│   ├── fix.md                   # /fix
│   ├── improve.md               # /improve
│   └── status.md                # /status
├── schemas/                      # Validation
│   └── findings.schema.json     # Findings JSON schema
├── scripts/                      # Utilities
│   ├── init-project.sh          # Bootstrap projects
│   ├── audit-project.sh         # Audit configuration
│   └── sync-upstream.sh         # Upstream sync
└── references/
    └── upstream-sources.json    # Source tracking
```

## Shell Scripts

| Script | Purpose |
|--------|---------|
| `init-project.sh` | Bootstrap a new project with Bosun defaults |
| `audit-project.sh` | Audit project configuration and health |
| `sync-upstream.sh` | Check upstream sources for updates |

```bash
# Bootstrap a new project
./scripts/init-project.sh ./my-project

# Audit project configuration
./scripts/audit-project.sh ./my-project

# Check upstream for updates
./scripts/sync-upstream.sh check
```

## Design Philosophy

### Control Plane Architecture

Bosun is designed as a **control plane** — it sits at the top of the stack and owns its data:

1. **No Runtime Dependencies**: Users install Bosun alone. All knowledge is self-contained.

2. **Curated, Not Inherited**: Knowledge is curated from best-in-class sources into owned skills:
   - Full control over content quality and consistency
   - Freedom to modify, extend, or reject upstream changes
   - Unified voice and standards across all agents

3. **Parallel Review**: Agents run in isolated contexts for independent, parallel analysis.

4. **Single Source of Truth**: For projects using Bosun, the plugin IS the standard.

### Upstream Sync Model

Bosun implements a **pull-based sync model** for curating knowledge from:
- `obra/superpowers` — architecture patterns, workflow design
- `VoltAgent/awesome-claude-code-subagents` — language specialists
- `Dammyjay93/claude-design-engineer` — UX/UI patterns

**Key principle**: Upstream repos are *sources of ideas*, not dependencies.

## What are Claude Code Plugins?

[Claude Code](https://claude.ai/code) is Anthropic's CLI tool for AI-assisted development. Plugins extend Claude Code with:

- **Skills** — Knowledge packages that give Claude specialized expertise
- **Agents** — Specialized workers for isolated, parallel tasks
- **Commands** — Slash commands that trigger specific workflows
- **Hooks** — Automatic triggers based on context

To learn more, run `/help` or visit the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.
