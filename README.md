# Bosun

⚓ Ship's officer for your codebase — keeping everything shipshape.

Bosun is a Claude Code plugin that orchestrates specialized agents for code quality, security, and architecture review. It provides parallel review capabilities through isolated agents that access curated skill knowledge.

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

### Components

| Component | Role | Location |
|-----------|------|----------|
| **Agents** | Specialized workers (isolated contexts) | `agents/*.md` |
| **Skills** | Reusable knowledge packages | `skills/*/SKILL.md` |
| **Commands** | Explicit user-triggered workflows | `commands/*.md` |
| **References** | RAG knowledge for skills | `skills/*/references/` |

## Agents

Agents are specialized workers that run in isolated contexts for independent analysis:

| Agent | Purpose | Model | Skills Used |
|-------|---------|-------|-------------|
| `security-agent` | Vulnerability scanning, threat modeling | Opus | bosun-security, bosun-threat-model |
| `quality-agent` | Code standards, performance, architecture | Sonnet | bosun-architect, language skills |
| `docs-agent` | Documentation completeness and quality | Sonnet | bosun-docs-writer |

Agents are **read-only** by default (`disallowedTools: Edit, Write`) for safety.

## Skills

Skills are knowledge packages that agents reference for domain expertise:

| Skill | Purpose |
|-------|---------|
| `bosun-architect` | Software architecture patterns, SOLID, DDD, Clean Architecture |
| `bosun-security` | Secret management, injection prevention, auth patterns, SAST tools |
| `bosun-threat-model` | STRIDE methodology, attack trees, DFDs, CVSS/DREAD |
| `bosun-golang` | Go idioms, error handling, concurrency, testing |
| `bosun-typescript` | TypeScript strict mode, ESLint, type patterns |
| `bosun-python` | PEP 8, type hints, pytest, async patterns |
| `bosun-docs-writer` | README templates, API docs, changelogs, technical writing |
| `bosun-ux-ui` | WCAG accessibility, design systems, usability heuristics |
| `bosun-project-auditor` | Project structure, configuration, dependency hygiene |
| `bosun-seo-llm` | SEO optimization, structured data, LLM-friendly content |

Each skill contains:
- `SKILL.md` — Skill definition with patterns and examples
- `references/` — RAG knowledge (detailed research docs)

## Commands

| Command | Description |
|---------|-------------|
| `/audit` | Run comprehensive project audit (security + quality + docs) |
| `/audit security` | Security review only |
| `/audit quality` | Code quality review only |
| `/audit docs` | Documentation review only |

## Installation

Install the plugin with one of the following scopes:

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

## Usage

### Automatic (Skills)

Skills are invoked automatically when Claude detects relevant context:

```
User: "Review this authentication code"
      → bosun-security skill activates
      → security-agent spawned for detailed analysis
```

### Explicit (Commands)

Use commands for explicit workflows:

```
/audit              # Full audit
/audit security     # Security only
```

### Example Output

```markdown
# Audit Report: my-project

## Security Findings
- Critical: 1 (hardcoded API key in config.js)
- High: 0
- Medium: 2

## Quality Findings
- Performance: 1 (O(n²) in user search)
- Style: 3 linting violations

## Documentation Findings
- Missing: API documentation
- Quality: README needs examples

## Recommendation
Block merge until critical security issue resolved.
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

Bosun implements a **pull-based sync model** for curating knowledge:

```
┌─────────────────────────────────────────────────────────────┐
│                    UPSTREAM SOURCES                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ superpowers │  │  VoltAgent  │  │ claude-design-eng   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          ▼                ▼                    ▼
    ┌─────────────────────────────────────────────────┐
    │              sync-upstream.sh                    │
    │  • Detects changes in tracked repos             │
    │  • Shows diffs for review                       │
    │  • Human decides what to pull                   │
    └─────────────────────┬───────────────────────────┘
                          │
                          ▼ (manual curation)
    ┌─────────────────────────────────────────────────┐
    │                    BOSUN                         │
    │  Skills are OWNED, not referenced               │
    └─────────────────────────────────────────────────┘
```

**Key principle**: Upstream repos are *sources of ideas*, not dependencies.

## Directory Structure

```
bosun/
├── .claude-plugin/
│   └── plugin.json              # Official plugin manifest
├── agents/                       # Specialized workers
│   ├── security-agent.md        # Security auditor (Opus)
│   ├── quality-agent.md         # Code quality reviewer (Sonnet)
│   └── docs-agent.md            # Documentation specialist (Sonnet)
├── skills/                       # Knowledge packages
│   ├── bosun-security/
│   │   ├── SKILL.md             # Skill definition
│   │   └── references/          # RAG knowledge
│   ├── bosun-architect/
│   ├── bosun-golang/
│   ├── bosun-typescript/
│   ├── bosun-python/
│   ├── bosun-threat-model/
│   ├── bosun-docs-writer/
│   ├── bosun-ux-ui/
│   ├── bosun-project-auditor/
│   └── bosun-seo-llm/
├── commands/                     # User-triggered workflows
│   └── audit.md                 # /audit command
├── scripts/                      # Shell utilities
│   ├── init-project.sh          # Bootstrap new projects
│   ├── audit-project.sh         # Audit project configuration
│   └── sync-upstream.sh         # Check upstream for updates
├── references/                   # Source research docs
│   └── upstream-sources.json    # Tracks source repos
└── assets/templates/
    └── PROJECT-CLAUDE.md        # Template for new projects
```

## Upstream Sources

This plugin curates from:
- `obra/superpowers` → bosun-architect, workflow patterns
- `VoltAgent/awesome-claude-code-subagents` → language specialists, security agents
- `Dammyjay93/claude-design-engineer` → bosun-ux-ui

## What are Claude Code Plugins?

[Claude Code](https://claude.ai/code) is Anthropic's CLI tool for AI-assisted development. Plugins extend Claude Code with:

- **Skills** — Knowledge packages that give Claude specialized expertise
- **Agents** — Specialized workers for isolated, parallel tasks
- **Commands** — Slash commands that trigger specific workflows
- **Hooks** — Automatic triggers based on context

To learn more, run `/help` or visit the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code).

## License

MIT License — see [LICENSE](LICENSE) for details.
