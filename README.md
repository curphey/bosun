# Bosun

⚓ Ship's officer for your codebase — keeping everything shipshape.

Bosun is a Claude Code plugin that enforces development standards through curated specialist agents. It provides planning discipline, git hygiene, CI/CD setup, code quality enforcement, and project auditing.

> **Note:** This project is in early development. Features described below represent the planned roadmap.

## Design Philosophy

### Control Plane Architecture

Bosun is designed as a **control plane** — it sits at the top of the stack and owns its data:

1. **No Runtime Dependencies**: Bosun does not depend on other plugins being installed. Users install Bosun alone, not a collection of plugins. All knowledge is self-contained.

2. **Curated, Not Inherited**: Instead of extending or wrapping other plugins, Bosun **curates** knowledge from best-in-class sources into its own skills. This means:
   - Full control over content quality and consistency
   - Freedom to modify, extend, or reject upstream changes
   - No breaking changes from upstream updates
   - Unified voice and standards across all agents

3. **Single Source of Truth**: For any project using Bosun, the plugin IS the standard. There's no ambiguity about which plugin's advice takes precedence.

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

**Key principle**: Upstream repos are *sources of ideas*, not dependencies. Changes are reviewed, cherry-picked, and adapted — never automatically merged.

## Planned Skills

| Skill | Purpose |
|-------|---------|
| `bosun-architect` | Planning discipline and design |
| `bosun-golang` | Go specialist |
| `bosun-typescript` | TypeScript specialist |
| `bosun-python` | Python specialist |
| `bosun-security` | Security reviewer |
| `bosun-docs-writer` | Documentation |
| `bosun-seo-llm` | SEO + LLM discoverability |
| `bosun-project-auditor` | Git, CI/CD, project setup |
| `bosun-threat-model` | Threat modeling |

## What are Claude Code Plugins?

[Claude Code](https://claude.ai/code) is Anthropic's CLI tool for AI-assisted development. Plugins extend Claude Code with additional skills and commands.

Plugins can provide:
- **Skills** — Markdown files that give Claude specialized knowledge and workflows for specific tasks
- **Commands** — Slash commands (like `/brainstorm` or `/review`) that trigger specific behaviors
- **Hooks** — Automatic triggers that activate skills based on context

Plugins are distributed through marketplaces (GitHub repositories) and can be installed at different scopes depending on whether you want them available globally, per-project, or just for yourself.

To learn more about Claude Code, run `/help` or visit the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code).

## Installation

First, add the Bosun marketplace:

```
/plugin marketplace add curphey/bosun
```

Then install the plugin with one of the following scopes:

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

## Directory Structure

```
bosun/
├── marketplace.json              # Plugin metadata for distribution
├── skills/                       # Specialist agents
│   ├── bosun-architect/          # Planning discipline
│   ├── bosun-golang/             # Go specialist
│   ├── bosun-typescript/         # TypeScript specialist
│   ├── bosun-python/             # Python specialist
│   ├── bosun-security/           # Security reviewer
│   ├── bosun-docs-writer/        # Documentation
│   ├── bosun-seo-llm/            # SEO + LLM discoverability
│   ├── bosun-project-auditor/    # Git, CI/CD, project setup
│   └── bosun-threat-model/       # Threat modeling
├── scripts/                      # Shell utilities
│   ├── init-project.sh           # Bootstrap new projects
│   ├── audit-project.sh          # Audit project configuration
│   └── sync-upstream.sh          # Check upstream sources for updates
├── references/
│   └── upstream-sources.json     # Tracks source repos we curate from
└── assets/templates/
    └── PROJECT-CLAUDE.md         # Template for new projects
```

## Upstream Sources

This plugin curates from:
- `obra/superpowers` → bosun-architect
- `VoltAgent/awesome-claude-code-subagents` → language specialists, security
- `Dammyjay93/claude-design-engineer` → bosun-architect

## License

MIT License — see [LICENSE](LICENSE) for details.
