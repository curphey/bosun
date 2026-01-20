# Bosun Roadmap

This document outlines planned features and priorities for Bosun development.

## Current Release: v1.0.0

Core functionality complete:
- 9 specialized agents (security, quality, docs, architecture, devops, testing, performance, ux-ui, orchestrator)
- 14 skills (6 language-specific, 8 cross-cutting)
- 4 commands (audit, fix, improve, status)
- Findings schema and persistence
- Test framework and CI/CD pipeline

---

## Phase 2: Automation & Expansion

### Hooks & CI Integration (#34)
- Pre-commit hook templates for local checks
- GitHub Actions workflow for automated audits
- GitLab CI and other CI platform support
- Pre-commit framework configuration

### Additional Language Skills
- **JavaScript** (#35) - ES6+, Node.js, browser patterns
- **Kotlin** - Android and server-side patterns
- **Swift** - iOS/macOS development patterns
- **Dart** - Flutter and web patterns

### Test Coverage (#36)
- Agent coordination and parallel execution tests
- Finding aggregation and deduplication tests
- Permission tier enforcement tests
- Schema validation tests

### Documentation (#37)
- Error handling and edge case documentation
- Troubleshooting guide
- Recovery procedures for interrupted operations

---

## Phase 3: Advanced Capabilities

### MCP Server for Dynamic RAG (#25)
- Real-time CVE database queries
- Live threat intelligence feeds
- External tool integration (Snyk, Dependabot APIs)
- Graceful fallback when unavailable

### Supply Chain Security
- Dedicated SBOM analysis skill
- Dependency vulnerability tracking
- License compliance checking
- Sigstore verification patterns

### Cloud-Specific Skills
- **bosun-aws** - AWS security and architecture patterns
- **bosun-gcp** - Google Cloud best practices
- **bosun-azure** - Azure-specific guidance

---

## Phase 4: Ecosystem Growth

### Framework-Specific Agents
- Next.js / React patterns
- Django / FastAPI patterns
- Rails patterns
- Spring Boot patterns

### Enterprise Features
- Team collaboration workflows
- Centralized policy management
- Reporting and metrics dashboards
- Custom skill development guide

### Integrations
- GitHub/GitLab API integration for PR comments
- Slack/Teams notifications
- JIRA/Linear issue creation from findings

---

## Contributing

See [CLAUDE.md](./CLAUDE.md) for development guidelines. Issues are tracked on [GitHub](https://github.com/curphey/bosun/issues).

Priority is given to:
1. Bug fixes and security issues
2. Phase 2 items (automation, coverage)
3. Community-requested features
