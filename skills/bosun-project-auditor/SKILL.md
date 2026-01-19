---
name: bosun-project-auditor
description: Project structure and health assessment. Use when auditing project setup, reviewing configurations, checking dependency hygiene, or evaluating technical debt. Provides project structure patterns and health metrics.
tags: [project-audit, configuration, dependencies, technical-debt, health]
---

# Bosun Project Auditor Skill

Project audit knowledge base for codebase health assessment.

## When to Use

- Auditing new or unfamiliar projects
- Reviewing project configuration
- Assessing technical debt
- Checking dependency hygiene
- Evaluating project structure

## When NOT to Use

- Code-level review (use language skills)
- Security audit (use bosun-security)
- Architecture design (use bosun-architect)

## Project Health Checklist

### Configuration Files

| File | Purpose | Required |
|------|---------|----------|
| README.md | Project documentation | Yes |
| LICENSE | Legal terms | Yes |
| .gitignore | Git exclusions | Yes |
| .editorconfig | Editor consistency | Recommended |
| package.json / pyproject.toml | Dependencies | Yes |
| tsconfig.json / setup.cfg | Language config | Yes |

### CI/CD Configuration

- [ ] CI pipeline exists (GitHub Actions, GitLab CI, etc.)
- [ ] Tests run on every PR
- [ ] Linting enforced in CI
- [ ] Security scanning enabled
- [ ] Build artifacts published

### Dependency Health

```bash
# Node.js
npm outdated
npm audit

# Python
pip list --outdated
pip-audit

# Go
go list -m -u all
govulncheck ./...
```

## Project Structure Patterns

### Monorepo vs Polyrepo

| Aspect | Monorepo | Polyrepo |
|--------|----------|----------|
| **Best for** | Related services, shared code | Independent teams |
| **Tooling** | Nx, Turborepo, Lerna | Standard git |
| **CI/CD** | Complex, selective builds | Simple, isolated |
| **Deps** | Shared, consistent | Independent versions |

### Standard Structures

**Node.js/TypeScript:**
```
├── src/
├── tests/
├── dist/
├── package.json
├── tsconfig.json
└── .eslintrc.js
```

**Python:**
```
├── src/myproject/
├── tests/
├── pyproject.toml
└── README.md
```

**Go:**
```
├── cmd/myapp/
├── internal/
├── pkg/
├── go.mod
└── go.sum
```

## Technical Debt Indicators

### High Priority
- [ ] No tests or <20% coverage
- [ ] Outdated dependencies with vulnerabilities
- [ ] No CI/CD pipeline
- [ ] Missing documentation
- [ ] Hardcoded secrets

### Medium Priority
- [ ] Inconsistent code style
- [ ] No linting configuration
- [ ] Complex circular dependencies
- [ ] Large functions (>100 lines)
- [ ] No error handling strategy

### Low Priority
- [ ] Missing .editorconfig
- [ ] No contribution guidelines
- [ ] Outdated non-vulnerable dependencies
- [ ] Missing IDE configurations

## Audit Report Template

```markdown
# Project Audit: [Project Name]

## Summary
- Overall Health: [Good/Fair/Poor]
- Priority Issues: [Count]

## Configuration
- [ ] README.md: [Present/Missing/Incomplete]
- [ ] LICENSE: [Present/Missing]
- [ ] CI/CD: [Present/Missing]

## Dependencies
- Total: [Count]
- Outdated: [Count]
- Vulnerable: [Count]

## Code Quality
- Test Coverage: [%]
- Linting: [Configured/Not configured]

## Recommendations
1. [Priority 1 recommendation]
2. [Priority 2 recommendation]
```

## References

See `references/` directory for detailed documentation:
- `project-auditor-research.md` - Comprehensive audit patterns
