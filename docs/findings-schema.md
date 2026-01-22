# Findings Schema Specification

This document defines the complete schema for `.bosun/findings.json`, the standardized output format for Bosun audits.

## Overview

The findings file contains:
- **Metadata**: Information about the audit
- **Summary**: Aggregated statistics
- **Findings**: Individual issues discovered

## File Location

```
.bosun/
└── findings.json
```

## Complete Schema

```json
{
  "version": "1.0.0",
  "metadata": {
    "project": "string",
    "auditedAt": "ISO-8601 timestamp",
    "scope": "full | security | quality | docs | architecture | devops | ux-ui | testing | performance",
    "gitRef": "string (optional)",
    "branch": "string (optional)",
    "agents": ["string"]
  },
  "summary": {
    "total": "number",
    "bySeverity": {
      "critical": "number",
      "high": "number",
      "medium": "number",
      "low": "number",
      "info": "number"
    },
    "byStatus": {
      "open": "number",
      "fixed": "number",
      "wontfix": "number",
      "deferred": "number"
    },
    "byCategory": {
      "security": "number",
      "quality": "number",
      "docs": "number",
      "architecture": "number",
      "devops": "number",
      "ux-ui": "number",
      "testing": "number",
      "performance": "number"
    }
  },
  "findings": [
    {
      "id": "string",
      "category": "string",
      "severity": "string",
      "title": "string",
      "description": "string",
      "location": {
        "file": "string",
        "line": "number (optional)",
        "endLine": "number (optional)",
        "column": "number (optional)"
      },
      "suggestedFix": {
        "description": "string",
        "automated": "boolean",
        "effort": "string",
        "semanticCategory": "string"
      },
      "interactionTier": "string",
      "status": "string",
      "dependsOn": ["string (optional)"],
      "references": ["string (optional)"],
      "cwe": "string (optional)",
      "fixedAt": "ISO-8601 timestamp (optional)",
      "fixedBy": "string (optional)"
    }
  ]
}
```

## Field Reference

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version (currently "1.0.0") |
| `metadata` | object | Yes | Audit context information |
| `summary` | object | Yes | Aggregated statistics |
| `findings` | array | Yes | List of individual findings |

### Metadata Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `project` | string | Yes | Project name (from package.json, go.mod, etc.) |
| `auditedAt` | string | Yes | ISO-8601 timestamp of audit completion |
| `scope` | string | Yes | Audit scope that was run |
| `gitRef` | string | No | Git commit SHA at time of audit |
| `branch` | string | No | Git branch name |
| `agents` | array | Yes | List of agents that ran |

**Scope Values:**
- `full` - All agents
- `security` - Security agent only
- `quality` - Quality agent only
- `docs` - Documentation agent only
- `architecture` - Architecture agent only
- `devops` - DevOps agent only
- `ux-ui` - UX/UI agent only
- `testing` - Testing agent only
- `performance` - Performance agent only

### Summary Object

| Field | Type | Description |
|-------|------|-------------|
| `total` | number | Total number of findings |
| `bySeverity` | object | Count of findings per severity level |
| `byStatus` | object | Count of findings per status |
| `byCategory` | object | Count of findings per category |

### Finding Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Unique identifier (e.g., "SEC-001") |
| `category` | string | Yes | Finding category |
| `severity` | string | Yes | Severity level |
| `title` | string | Yes | Short description (< 80 chars) |
| `description` | string | Yes | Detailed explanation |
| `location` | object | Yes | Where the issue was found |
| `suggestedFix` | object | No | How to fix the issue |
| `interactionTier` | string | Yes | Fix approval level |
| `status` | string | Yes | Current status |
| `dependsOn` | array | No | IDs of findings this depends on |
| `references` | array | No | Links to documentation |
| `cwe` | string | No | CWE identifier (security findings) |
| `fixedAt` | string | No | When the finding was fixed |
| `fixedBy` | string | No | Who/what fixed it |

### Location Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | string | Yes | Relative file path |
| `line` | number | No | Starting line number (1-indexed) |
| `endLine` | number | No | Ending line number |
| `column` | number | No | Column number |

For findings without a specific location (e.g., "no tests"), use:
```json
"location": { "file": null }
```

### SuggestedFix Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | string | Yes | Human-readable fix description |
| `automated` | boolean | Yes | Can Bosun fix this automatically? |
| `effort` | string | Yes | Estimated effort level |
| `semanticCategory` | string | Yes | Type of fix for batching |

## Enumerations

### Severity Levels

| Value | Score | Description | Examples |
|-------|-------|-------------|----------|
| `critical` | 100 | Immediate action required | Hardcoded secrets, SQL injection |
| `high` | 75 | Should fix soon | Missing auth, XSS vulnerabilities |
| `medium` | 50 | Should fix | Missing error handling, code duplication |
| `low` | 25 | Nice to fix | Style issues, minor optimizations |
| `info` | 10 | Informational | Suggestions, best practices |

### Status Values

| Value | Description |
|-------|-------------|
| `open` | Not yet addressed |
| `fixed` | Remediated and validated |
| `wontfix` | Intentionally not fixing |
| `deferred` | Postponed to future sprint |

### Categories

| Value | Prefix | Agent | Description |
|-------|--------|-------|-------------|
| `security` | SEC | security-agent | Vulnerabilities, secrets, auth |
| `quality` | QUA | quality-agent | Code quality, patterns |
| `docs` | DOC | docs-agent | Documentation gaps |
| `architecture` | ARC | architecture-agent | Design issues |
| `devops` | DEV | devops-agent | CI/CD, infrastructure |
| `ux-ui` | UXU | ux-ui-agent | Accessibility, usability |
| `testing` | TST | testing-agent | Test coverage, quality |
| `performance` | PRF | performance-agent | Performance issues |

### Interaction Tiers

| Value | Approval | Use When |
|-------|----------|----------|
| `auto` | None (silent) | Safe, reversible changes |
| `confirm` | Batch approval | Low-risk but visible changes |
| `approve` | Individual approval | High-impact or risky changes |

**Tier Guidelines:**

| Tier | Examples |
|------|----------|
| `auto` | Formatting, linting fixes, adding security headers |
| `confirm` | Extract to env var, add error handling, update imports |
| `approve` | API changes, refactoring, dependency updates, schema changes |

### Effort Levels

| Value | Time Estimate | Examples |
|-------|---------------|----------|
| `trivial` | < 5 minutes | Typo fix, config change |
| `minor` | 5-30 minutes | Add validation, update docs |
| `moderate` | 30 min - 2 hours | Refactor function, add tests |
| `major` | 2-8 hours | Refactor module, add feature |
| `significant` | > 1 day | Architecture change, major rewrite |

### Semantic Categories

Semantic categories group similar fixes for batching:

| Category | Description | Examples |
|----------|-------------|----------|
| `extract secrets to env vars` | Move hardcoded secrets | API keys, passwords |
| `add error handling` | Add try/catch or error checks | Missing error handling |
| `add input validation` | Validate user input | Form validation, API params |
| `fix injection vulnerability` | Prevent injection attacks | SQL, XSS, command injection |
| `add security headers` | HTTP security headers | CSP, HSTS, X-Frame-Options |
| `update dependencies` | Upgrade packages | Security patches, updates |
| `add documentation` | Write missing docs | README, API docs, comments |
| `refactor for clarity` | Improve code structure | Extract function, rename |
| `optimize performance` | Improve speed/memory | Algorithm, caching |
| `add tests` | Write missing tests | Unit, integration tests |

## ID Format

Finding IDs follow the pattern: `{PREFIX}-{NUMBER}`

- Prefix: 3-letter category code (see Categories table)
- Number: 3-digit sequential number, zero-padded

Examples:
- `SEC-001` - First security finding
- `QUA-015` - 15th quality finding
- `DOC-003` - Third documentation finding

IDs are assigned by the orchestrator during aggregation, not by individual agents.

## Examples

### Minimal Finding

```json
{
  "id": "QUA-001",
  "category": "quality",
  "severity": "medium",
  "title": "Missing error handling",
  "description": "Function getData() does not handle errors from API call",
  "location": { "file": "src/api.ts", "line": 42 },
  "interactionTier": "confirm",
  "status": "open"
}
```

### Complete Finding

```json
{
  "id": "SEC-001",
  "category": "security",
  "severity": "critical",
  "title": "Hardcoded API key in source code",
  "description": "AWS access key found hardcoded at line 15. This key has been exposed in version control and should be rotated immediately.",
  "location": {
    "file": "src/config.js",
    "line": 15,
    "endLine": 15,
    "column": 20
  },
  "suggestedFix": {
    "description": "Move API key to environment variable AWS_ACCESS_KEY_ID and load via process.env",
    "automated": true,
    "effort": "trivial",
    "semanticCategory": "extract secrets to env vars"
  },
  "interactionTier": "confirm",
  "status": "open",
  "references": [
    "https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html"
  ],
  "cwe": "CWE-798"
}
```

### Finding Without Location

```json
{
  "id": "TST-001",
  "category": "testing",
  "severity": "high",
  "title": "No test files present",
  "description": "Project has no test files. Critical business logic is untested.",
  "location": { "file": null },
  "suggestedFix": {
    "description": "Add test suite with coverage for critical paths",
    "automated": false,
    "effort": "major",
    "semanticCategory": "add tests"
  },
  "interactionTier": "approve",
  "status": "open"
}
```

### Fixed Finding

```json
{
  "id": "SEC-002",
  "category": "security",
  "severity": "high",
  "title": "SQL injection vulnerability",
  "description": "User input concatenated directly into SQL query",
  "location": { "file": "src/db.py", "line": 28 },
  "suggestedFix": {
    "description": "Use parameterized query",
    "automated": true,
    "effort": "trivial",
    "semanticCategory": "fix injection vulnerability"
  },
  "interactionTier": "confirm",
  "status": "fixed",
  "fixedAt": "2024-01-15T14:30:00Z",
  "fixedBy": "bosun/security-agent",
  "cwe": "CWE-89"
}
```

### Finding with Dependencies

```json
{
  "id": "ARC-002",
  "category": "architecture",
  "severity": "medium",
  "title": "Auth logic should use new config system",
  "description": "Authentication module still uses hardcoded config instead of new environment-based system",
  "location": { "file": "src/auth/index.ts", "line": 1 },
  "suggestedFix": {
    "description": "Refactor to use config service",
    "automated": false,
    "effort": "moderate",
    "semanticCategory": "refactor for clarity"
  },
  "interactionTier": "approve",
  "status": "open",
  "dependsOn": ["SEC-001"]
}
```

## Complete File Example

```json
{
  "version": "1.0.0",
  "metadata": {
    "project": "my-api",
    "auditedAt": "2024-01-15T10:30:00Z",
    "scope": "full",
    "gitRef": "a1b2c3d",
    "branch": "main",
    "agents": ["security-agent", "quality-agent", "docs-agent"]
  },
  "summary": {
    "total": 4,
    "bySeverity": {
      "critical": 1,
      "high": 1,
      "medium": 1,
      "low": 1,
      "info": 0
    },
    "byStatus": {
      "open": 3,
      "fixed": 1,
      "wontfix": 0,
      "deferred": 0
    },
    "byCategory": {
      "security": 2,
      "quality": 1,
      "docs": 1
    }
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
      "status": "open",
      "cwe": "CWE-798"
    },
    {
      "id": "SEC-002",
      "category": "security",
      "severity": "high",
      "title": "Missing rate limiting",
      "description": "API endpoints lack rate limiting",
      "location": { "file": "src/server.ts", "line": 1 },
      "suggestedFix": {
        "description": "Add rate limiting middleware",
        "automated": true,
        "effort": "minor",
        "semanticCategory": "add security headers"
      },
      "interactionTier": "confirm",
      "status": "fixed",
      "fixedAt": "2024-01-15T11:00:00Z",
      "fixedBy": "bosun/security-agent"
    },
    {
      "id": "QUA-001",
      "category": "quality",
      "severity": "medium",
      "title": "Function too long",
      "description": "processOrder() is 150 lines and should be split",
      "location": { "file": "src/orders.ts", "line": 42, "endLine": 192 },
      "suggestedFix": {
        "description": "Extract into smaller functions",
        "automated": false,
        "effort": "moderate",
        "semanticCategory": "refactor for clarity"
      },
      "interactionTier": "approve",
      "status": "open"
    },
    {
      "id": "DOC-001",
      "category": "docs",
      "severity": "low",
      "title": "Missing API documentation",
      "description": "REST endpoints lack OpenAPI/Swagger docs",
      "location": { "file": "src/routes/", "line": null },
      "suggestedFix": {
        "description": "Add OpenAPI annotations",
        "automated": false,
        "effort": "moderate",
        "semanticCategory": "add documentation"
      },
      "interactionTier": "approve",
      "status": "open"
    }
  ]
}
```

## Validation

### Required Fields Checklist

For each finding, ensure:
- [ ] `id` is unique and follows `{PREFIX}-{NNN}` format
- [ ] `category` matches one of the defined categories
- [ ] `severity` is one of: critical, high, medium, low, info
- [ ] `title` is present and under 80 characters
- [ ] `description` provides actionable detail
- [ ] `location.file` is present (can be null)
- [ ] `interactionTier` is one of: auto, confirm, approve
- [ ] `status` is one of: open, fixed, wontfix, deferred

### Summary Validation

The summary should match the findings array:
- `summary.total` === `findings.length`
- `summary.bySeverity.*` counts match actual finding severities
- `summary.byStatus.*` counts match actual finding statuses
- `summary.byCategory.*` counts match actual finding categories

## Integrations

### Reading Findings (bash)

```bash
# Get total findings
jq '.summary.total' .bosun/findings.json

# List open critical/high findings
jq '[.findings[] | select(.status == "open" and (.severity == "critical" or .severity == "high"))]' .bosun/findings.json

# Get security findings
jq '[.findings[] | select(.category == "security")]' .bosun/findings.json
```

### Reading Findings (JavaScript)

```javascript
const findings = JSON.parse(fs.readFileSync('.bosun/findings.json', 'utf8'));

// Filter open findings
const openFindings = findings.findings.filter(f => f.status === 'open');

// Group by category
const byCategory = findings.findings.reduce((acc, f) => {
  acc[f.category] = acc[f.category] || [];
  acc[f.category].push(f);
  return acc;
}, {});
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Run Bosun Audit
  run: bosun /audit

- name: Check for Critical Findings
  run: |
    critical=$(jq '[.findings[] | select(.severity == "critical" and .status == "open")] | length' .bosun/findings.json)
    if [ "$critical" -gt 0 ]; then
      echo "::error::$critical critical findings detected"
      exit 1
    fi
```
