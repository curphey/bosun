---
name: audit
description: Run a comprehensive project audit using parallel agents. Outputs findings to .bosun/findings.json for use by /fix and /improve commands.
---

# /audit Command

Triggers a comprehensive project audit using Bosun's specialized agents. Findings are persisted to `.bosun/findings.json` for subsequent remediation.

## Usage

```
/audit [scope] [path]
```

**Scope options:**
- `full` (default) - All agents: security + quality + docs + architecture + devops + ux-ui + testing + performance
- `security` - Security agent only
- `quality` - Quality agent only
- `docs` - Documentation agent only
- `architecture` - Architecture agent only
- `devops` - DevOps agent only
- `ux-ui` - UX/UI and accessibility agent only
- `testing` - Testing coverage and quality agent only
- `performance` - Performance optimization agent only

**Path filtering:**
```
/audit security ./src          # Security audit of src/ only
/audit quality ./lib/api       # Quality audit of lib/api/ only
/audit full .                  # Full audit of entire project
```

## What Happens

When you run `/audit`, Bosun:

1. **Creates `.bosun/` directory** if it doesn't exist
2. **Spawns specialized agents** based on scope (in parallel for `full`)
3. **Aggregates findings** into standardized schema
4. **Persists results** to `.bosun/findings.json`
5. **Displays summary** to user

### Agent Mapping by Scope

| Scope | Agents Spawned |
|-------|----------------|
| `full` | All agents below |
| `security` | security-agent |
| `quality` | quality-agent |
| `docs` | docs-agent |
| `architecture` | architecture-agent |
| `devops` | devops-agent |
| `ux-ui` | ux-ui-agent |
| `testing` | testing-agent |
| `performance` | performance-agent |

### 1. Security Review (security-agent)
- Scans for hardcoded secrets
- Checks dependency vulnerabilities
- Reviews authentication/authorization
- Identifies injection risks
- Verifies security headers

### 2. Quality Review (quality-agent)
- Validates code style and linting
- Checks architecture patterns
- Identifies performance issues
- Reviews error handling
- Assesses test coverage

### 3. Documentation Review (docs-agent)
- Checks README completeness
- Validates API documentation
- Reviews code comments
- Verifies CHANGELOG format

### 4. Architecture Review (architecture-agent)
- Evaluates system design patterns
- Identifies architectural anti-patterns
- Reviews module boundaries
- Assesses scalability concerns

### 5. DevOps Review (devops-agent)
- Reviews CI/CD configuration
- Checks infrastructure as code
- Validates deployment configs
- Reviews monitoring/observability

### 6. UX/UI Review (ux-ui-agent)
- Checks WCAG accessibility compliance
- Verifies color contrast ratios
- Reviews keyboard navigation
- Assesses usability heuristics

### 7. Testing Review (testing-agent)
- Measures code coverage
- Identifies untested critical paths
- Detects flaky tests
- Reviews test quality

### 8. Performance Review (performance-agent)
- Analyzes algorithm complexity
- Identifies N+1 queries
- Reviews memory usage
- Checks bundle sizes (frontend)

## Findings Output

Findings are persisted to `.bosun/findings.json`:

```json
{
  "version": "1.0.0",
  "metadata": {
    "project": "my-project",
    "auditedAt": "2024-01-15T10:30:00Z",
    "scope": "full",
    "gitRef": "abc1234"
  },
  "summary": {
    "total": 8,
    "bySeverity": { "critical": 1, "high": 2, "medium": 3, "low": 2, "info": 0 },
    "byStatus": { "open": 8, "fixed": 0, "wontfix": 0, "deferred": 0 },
    "byCategory": { "security": 3, "quality": 3, "docs": 2, "architecture": 0, "devops": 0 }
  },
  "findings": [
    {
      "id": "SEC-001",
      "category": "security",
      "severity": "critical",
      "title": "Hardcoded API key",
      "description": "API key found hardcoded in source file",
      "location": { "file": "src/config.js", "line": 15 },
      "suggestedFix": {
        "description": "Move to environment variable",
        "automated": true,
        "effort": "trivial",
        "semanticCategory": "extract secrets to env vars"
      },
      "interactionTier": "confirm",
      "status": "open"
    }
  ]
}
```

## Interaction Tiers

Each finding is assigned an interaction tier that determines how `/fix` handles it:

| Tier | Approval | Examples |
|------|----------|----------|
| **auto** | None (silent) | Formatting, linting, typos, security headers (additive) |
| **confirm** | Batch | Env var extraction, import sorting, doc additions |
| **approve** | Individual | API changes, refactoring, dependency updates |

## Terminal Output

After all agents complete, you'll see:

```
# Audit Report: my-project

## Summary
- Total findings: 8
- Critical: 1 | High: 2 | Medium: 3 | Low: 2

## By Category
- Security: 3 findings
- Quality: 3 findings
- Documentation: 2 findings

## Critical/High Findings
1. [SEC-001] Hardcoded API key - src/config.js:15
2. [QUA-001] O(n²) algorithm in user search - src/search.js:42
3. [SEC-002] Missing CSRF protection - src/auth/login.js:8

## Next Steps
- Run `/fix` to remediate findings
- Run `/fix --auto` to apply auto-tier fixes silently
- Run `/status` to view current findings summary

Findings saved to: .bosun/findings.json
```

## Examples

```
> /audit

Running full project audit...
Spawning security-agent (background)...
Spawning quality-agent (background)...
Spawning docs-agent (background)...
Spawning architecture-agent (background)...
Spawning devops-agent (background)...

[Agents complete]

# Audit Report: my-project
...
```

```
> /audit security ./src

Running security audit on ./src...
Spawning security-agent...

[Agent completes]

# Security Audit Report: my-project (./src)
...
```

## Chaining

The audit command is designed to chain with other Bosun commands:

```
/audit          → writes .bosun/findings.json
/fix            → reads findings, applies fixes, updates status
/improve        → reads findings, prioritizes, plans/executes
/status         → shows findings summary
```

## Implementation Notes

When implementing this command:

1. **Create .bosun directory**
   ```bash
   mkdir -p .bosun
   ```

2. **Spawn agents based on scope** - Use Task tool with appropriate agent types

3. **Collect agent outputs** - Each agent returns findings in the standard format

4. **Aggregate findings**
   - Assign unique IDs by category:
     - SEC-001 (security), QUA-001 (quality), DOC-001 (docs)
     - ARC-001 (architecture), DEV-001 (devops)
     - UXU-001 (ux-ui), TST-001 (testing), PRF-001 (performance)
   - Calculate summary statistics
   - Merge into single findings.json

5. **Persist results**
   - Write to `.bosun/findings.json`
   - Include git ref if available

6. **Display summary** - Show critical/high findings prominently
