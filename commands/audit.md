---
name: audit
description: Run a comprehensive project audit using parallel agents for security, quality, and documentation review.
---

# /audit Command

Triggers a comprehensive project audit using Bosun's specialized agents.

## Usage

```
/audit [scope]
```

**Scope options:**
- `full` (default) - Security + Quality + Documentation
- `security` - Security agent only
- `quality` - Quality agent only
- `docs` - Documentation agent only

## What Happens

When you run `/audit`, Bosun orchestrates the following:

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

## Output

After all agents complete, you'll receive an aggregated report:

```markdown
# Audit Report: [Project Name]

## Security Findings
- Critical: [count]
- High: [count]
- Medium: [count]

## Quality Findings
- Performance issues: [count]
- Style violations: [count]
- Architecture concerns: [count]

## Documentation Findings
- Missing docs: [count]
- Quality issues: [count]

## Recommendation
[Block/Approve with conditions]
```

## Example

```
> /audit

Running full project audit...

Spawning security-agent (background)...
Spawning quality-agent (background)...
Spawning docs-agent (background)...

[Agents complete]

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
