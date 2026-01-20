---
name: status
description: Show summary of current findings from the last audit. Read-only view of .bosun/findings.json.
---

# /status Command

Displays a summary of current findings from the last `/audit` run. Read-only command that reads `.bosun/findings.json`.

## Usage

```
/status [scope] [flags]
```

**Scope options:**
- (none) - Show all findings
- `security` - Security findings only
- `quality` - Quality findings only
- `docs` - Documentation findings only
- `architecture` - Architecture findings only
- `devops` - DevOps findings only

**Flags:**
- `--open` - Show only open findings (default)
- `--all` - Show all findings including fixed
- `--verbose` - Show full finding details
- `--json` - Output raw JSON

## Output

### Default View

```
/status

# Bosun Status: my-project

Last audit: 2024-01-15T10:30:00Z (2 hours ago)
Scope: full
Git ref: abc1234

## Summary

| Status   | Count |
|----------|-------|
| Open     | 8     |
| Fixed    | 4     |
| Won't Fix| 1     |
| Deferred | 2     |
| **Total**| **15**|

## Open Findings by Severity

| Severity | Count | Categories              |
|----------|-------|-------------------------|
| Critical | 1     | security (1)            |
| High     | 2     | security (1), quality (1)|
| Medium   | 3     | quality (2), docs (1)   |
| Low      | 2     | docs (2)                |

## Open Findings by Category

| Category     | Critical | High | Medium | Low | Total |
|--------------|----------|------|--------|-----|-------|
| Security     | 1        | 1    | 0      | 0   | 2     |
| Quality      | 0        | 1    | 2      | 0   | 3     |
| Docs         | 0        | 0    | 1      | 2   | 3     |
| Architecture | 0        | 0    | 0      | 0   | 0     |
| DevOps       | 0        | 0    | 0      | 0   | 0     |

## Critical/High Findings (3)

1. **[SEC-001] Hardcoded API key** (critical)
   src/config.js:15 | Effort: trivial | Tier: confirm

2. **[SEC-002] SQL injection vulnerability** (high)
   src/db/users.js:42 | Effort: minor | Tier: confirm

3. **[QUA-001] O(n²) algorithm in user search** (high)
   src/services/userSearch.js:42 | Effort: moderate | Tier: approve

## Quick Actions

- `/fix --auto` - Apply 3 auto-tier fixes silently
- `/fix SEC-001` - Fix critical finding
- `/improve` - Generate improvement plan
```

### Scoped View

```
/status security

# Security Status: my-project

## Open Security Findings (2)

| ID      | Severity | Title                    | Location           | Effort   |
|---------|----------|--------------------------|--------------------| ---------|
| SEC-001 | critical | Hardcoded API key        | src/config.js:15   | trivial  |
| SEC-002 | high     | SQL injection            | src/db/users.js:42 | minor    |

## Fixed Security Findings (2)

| ID      | Severity | Title                    | Fixed At              |
|---------|----------|--------------------------|---------------------- |
| SEC-003 | medium   | Missing CSRF protection  | 2024-01-15T11:00:00Z |
| SEC-004 | low      | Missing security headers | 2024-01-15T11:05:00Z |

## Quick Actions
- `/fix security` - Fix all security findings
- `/fix SEC-001` - Fix critical finding first
```

### Verbose View

```
/status --verbose

# Bosun Status: my-project (Verbose)

## SEC-001: Hardcoded API key

| Field           | Value                                |
|-----------------|--------------------------------------|
| Severity        | critical                             |
| Category        | security                             |
| Status          | open                                 |
| Location        | src/config.js:15                     |
| Interaction Tier| confirm                              |
| Effort          | trivial                              |

**Description:**
AWS API key found hardcoded in configuration file. This exposes credentials in version control and could lead to unauthorized access.

**Suggested Fix:**
Move API key to environment variable AWS_API_KEY

**References:**
- CWE-798
- https://owasp.org/Top10/A07_2021-Identification_and_Authentication_Failures/

**Tags:** secrets, hardcoded, aws

---

## SEC-002: SQL injection vulnerability
...
```

### JSON Output

```
/status --json

{
  "version": "1.0.0",
  "metadata": {
    "project": "my-project",
    "auditedAt": "2024-01-15T10:30:00Z",
    "scope": "full"
  },
  "summary": {
    "total": 15,
    "bySeverity": { "critical": 1, "high": 2, "medium": 3, "low": 2, "info": 0 },
    "byStatus": { "open": 8, "fixed": 4, "wontfix": 1, "deferred": 2 },
    "byCategory": { "security": 2, "quality": 3, "docs": 3, "architecture": 0, "devops": 0 }
  },
  "findings": [...]
}
```

## No Findings State

```
/status

# Bosun Status: my-project

No findings file found.

Run `/audit` to analyze your project.
```

## All Fixed State

```
/status

# Bosun Status: my-project

🎉 All findings resolved!

Last audit: 2024-01-15T10:30:00Z
Total findings: 15
Fixed: 15

Run `/audit` to check for new issues.
```

## Implementation Notes

When implementing this command:

1. **Check for findings file**
   ```bash
   if [ -f .bosun/findings.json ]; then
     cat .bosun/findings.json
   else
     echo "No findings file found."
   fi
   ```

2. **Parse and aggregate**
   - Count by severity
   - Count by status
   - Count by category
   - Filter by scope if provided

3. **Format output**
   - Tables for summary views
   - Detailed cards for verbose view
   - Raw JSON for --json flag

4. **Highlight actionable items**
   - Show critical/high findings prominently
   - Suggest quick actions

## Error Handling

### No Findings File

```
/status

No findings file found.
Run `/audit` to analyze your project.
```

**Cause**: No audit has been run, or `.bosun/findings.json` was deleted.

**Solution**: Run `/audit` to generate findings.

### Corrupted Findings

```
/status

Error: Invalid JSON in .bosun/findings.json
```

**Cause**: The findings file is corrupted or malformed.

**Solutions**:
1. Validate JSON: `jq . .bosun/findings.json`
2. Check git for previous version: `git show HEAD:.bosun/findings.json`
3. Delete and re-audit: `rm .bosun/findings.json && /audit`

### Stale Findings

```
/status

Warning: Findings are from 7 days ago (2024-01-08T10:30:00Z)
Code may have changed since last audit.
```

**Recommendation**: Run `/audit` for fresh results if significant changes have been made.

### Scope Filtering Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "No findings match scope" | No findings in category | Use different scope or no scope |
| "Invalid scope" | Typo in scope name | Use: security, quality, docs, architecture, devops |

### Read-Only Command

The `/status` command is read-only and cannot fail in ways that affect your project. It only reads `.bosun/findings.json` and displays information.

If status shows unexpected data:
1. Check the findings file directly: `cat .bosun/findings.json | jq .summary`
2. Re-run audit if data seems wrong: `/audit`

See [Error Handling Guide](../docs/error-handling.md) for comprehensive troubleshooting.

## Chaining

```
/audit          → writes .bosun/findings.json
/status         → shows current findings summary
/fix            → applies fixes, updates status
/status         → shows updated summary
/improve        → plans remaining work
```
