# Error Handling & Troubleshooting

This guide covers error scenarios, recovery procedures, and troubleshooting for Bosun commands.

## Table of Contents

- [Agent Failures](#agent-failures)
- [Finding Conflicts](#finding-conflicts)
- [Interrupted Operations](#interrupted-operations)
- [Permission Issues](#permission-issues)
- [File System Errors](#file-system-errors)
- [Recovery Procedures](#recovery-procedures)
- [Troubleshooting Guide](#troubleshooting-guide)

---

## Agent Failures

### Agent Timeout

**Scenario**: An agent takes too long to complete and times out.

**Symptoms**:
- Partial findings in `.bosun/findings.json`
- Missing category in findings (e.g., no security findings when security-agent timed out)
- Error message indicating timeout

**Recovery**:
1. Check which agent(s) failed by reviewing the audit output
2. Re-run with a narrower scope: `/audit security` instead of `/audit`
3. If timeout persists, the codebase may be too large for a single pass
4. Consider auditing specific paths: `/audit security src/api/`

**Prevention**:
- Audit specific directories rather than entire large codebases
- Use scoped audits for faster results

### Agent Crash

**Scenario**: An agent encounters an unrecoverable error and crashes.

**Symptoms**:
- Incomplete findings
- Error stack trace in output
- `.bosun/findings.json` may be missing or corrupted

**Recovery**:
1. Check if `.bosun/findings.json` exists and is valid JSON
2. If corrupted, delete it: `rm .bosun/findings.json`
3. Re-run the audit: `/audit`
4. If the crash is reproducible, try a different scope

**Reporting**:
If an agent consistently crashes, report the issue with:
- The command that triggered the crash
- Relevant code patterns that may have caused it
- Error messages or stack traces

### Partial Agent Completion

**Scenario**: Some agents complete while others fail.

**Symptoms**:
- Findings from some categories but not others
- Warning about incomplete audit

**Behavior**:
- Bosun saves findings from successful agents
- Failed agents are noted in metadata
- `/status` shows which agents completed

**Recovery**:
1. Review completed findings: `/status`
2. Re-run failed agents individually: `/audit <scope>`
3. Findings will be merged with existing results

---

## Finding Conflicts

### Duplicate Findings

**Scenario**: Multiple agents report the same issue.

**Behavior**:
- Bosun deduplicates findings by ID and location
- First finding is kept, duplicates are merged
- Severity is taken from the more severe finding

**Example**:
```
security-agent: SEC-001 at src/config.js:15 (critical)
quality-agent: SEC-001 at src/config.js:15 (high)
Result: SEC-001 kept with severity "critical"
```

### Conflicting Recommendations

**Scenario**: Agents provide contradictory fix suggestions.

**Example**:
- security-agent suggests removing a feature entirely
- quality-agent suggests refactoring the same feature

**Resolution**:
1. Review both recommendations in `/status`
2. Use `/fix --interactive` to choose which fix to apply
3. Security findings typically take precedence
4. When in doubt, apply security fix first, then quality improvements

### Severity Disagreements

**Scenario**: Same issue classified differently by different agents.

**Behavior**:
- Higher severity is preserved
- Original agent's assessment noted in finding metadata

**Manual Override**:
Edit `.bosun/findings.json` directly to adjust severity if needed:
```json
{
  "id": "SEC-001",
  "severity": "medium",  // Changed from "critical"
  "status": "open"
}
```

---

## Interrupted Operations

### Interrupted Audit

**Scenario**: `/audit` is interrupted (Ctrl+C, system crash, etc.)

**Symptoms**:
- No `.bosun/findings.json` created
- Or partial/corrupted findings file

**Recovery**:
1. Check if findings file exists: `ls -la .bosun/`
2. If missing or corrupted, simply re-run: `/audit`
3. Audits are idempotent - safe to re-run

### Interrupted Fix

**Scenario**: `/fix` is interrupted mid-operation.

**Symptoms**:
- Some fixes applied, others not
- Finding statuses partially updated
- Possible uncommitted changes

**Recovery**:
1. Check git status: `git status`
2. Review changes: `git diff`
3. If changes look good, commit them
4. If changes are problematic, revert: `git checkout .`
5. Re-run `/fix` - already-fixed findings will be skipped

**Safety**:
- `/fix` marks findings as "fixed" after successful application
- Already-fixed findings are not re-processed
- Git provides rollback capability

### Interrupted Improve

**Scenario**: `/improve --execute` is interrupted.

**Recovery**:
1. Check which improvements were applied via git history
2. Re-run `/improve --plan` to see remaining items
3. Continue with `/improve --execute`

---

## Permission Issues

### Permission Denied (Auto Tier)

**Scenario**: Auto-tier fix is blocked by system permissions.

**Symptoms**:
- "Permission denied" error
- File not modified

**Causes**:
- File is read-only
- File owned by different user
- Directory permissions restrictive

**Recovery**:
1. Check file permissions: `ls -la <file>`
2. Fix permissions if appropriate: `chmod u+w <file>`
3. Re-run the fix

### Permission Denied (Confirm/Approve Tier)

**Scenario**: User denies permission for a fix.

**Behavior**:
- Fix is skipped
- Finding remains "open"
- No error - this is expected behavior

**To Apply Later**:
1. Run `/fix --interactive`
2. Approve the specific finding when prompted

### Batch Permission Denial

**Scenario**: User denies a semantic batch (e.g., "extract secrets to env vars").

**Behavior**:
- All findings in that batch are skipped
- Findings remain "open"
- Other batches proceed normally

**To Apply Selectively**:
1. Run `/fix --interactive`
2. Approve individual findings instead of batches

---

## File System Errors

### Missing .bosun Directory

**Scenario**: `.bosun/` directory doesn't exist.

**Behavior**:
- Created automatically on first `/audit`
- `/status` and `/fix` will report "no findings"

**Manual Creation**:
```bash
mkdir -p .bosun
```

### Corrupted findings.json

**Scenario**: `findings.json` is not valid JSON.

**Symptoms**:
- Parse errors when running commands
- "Unexpected token" errors

**Recovery**:
1. Validate the JSON: `jq . .bosun/findings.json`
2. If invalid, check git for previous version: `git show HEAD:.bosun/findings.json`
3. Or delete and re-audit: `rm .bosun/findings.json && /audit`

### Disk Full

**Scenario**: Disk is full, can't write findings.

**Symptoms**:
- "No space left on device" error
- Partial or missing findings file

**Recovery**:
1. Free disk space
2. Delete corrupted findings: `rm .bosun/findings.json`
3. Re-run audit

---

## Recovery Procedures

### Full Reset

When all else fails, reset Bosun state:

```bash
# Remove all Bosun data
rm -rf .bosun/

# Re-run fresh audit
/audit
```

### Selective Reset

Reset specific state while preserving others:

```bash
# Reset findings only (preserves permissions)
rm .bosun/findings.json

# Reset permissions only (preserves findings)
rm .bosun/permissions.json
```

### Git-Based Recovery

Use git to recover from bad fixes:

```bash
# See what changed
git diff

# Revert all uncommitted changes
git checkout .

# Revert last commit (if fix was committed)
git revert HEAD
```

### Backup Before Major Operations

```bash
# Backup findings before bulk fix
cp .bosun/findings.json .bosun/findings.json.backup

# Restore if needed
cp .bosun/findings.json.backup .bosun/findings.json
```

---

## Troubleshooting Guide

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "No findings to display" | No audit run yet | Run `/audit` first |
| "findings.json not found" | No audit run or file deleted | Run `/audit` |
| "Invalid JSON" | Corrupted findings file | Delete and re-audit |
| Agent timeout | Large codebase | Use scoped audit |
| Fix not applied | Permission denied | Check file permissions |
| Duplicate findings | Multiple agents found same issue | Normal - deduped automatically |

### Diagnostic Commands

```bash
# Check Bosun state
ls -la .bosun/

# Validate findings JSON
jq . .bosun/findings.json

# Count findings by severity
jq '.summary.bySeverity' .bosun/findings.json

# List open findings
jq '[.findings[] | select(.status == "open")]' .bosun/findings.json

# Check file permissions
ls -la <problematic-file>

# Check git status
git status
```

### Debug Mode

For detailed output, check the agent's execution:
- Agent errors are logged to the conversation
- Review the full output for stack traces
- Check for patterns in failing files

### Getting Help

If issues persist:
1. Check existing issues: https://github.com/curphey/bosun/issues
2. Create a new issue with:
   - Command that failed
   - Error message or unexpected behavior
   - Relevant code patterns
   - Steps to reproduce

---

## Error Codes Reference

| Code | Meaning | Action |
|------|---------|--------|
| `AGENT_TIMEOUT` | Agent exceeded time limit | Use narrower scope |
| `AGENT_CRASH` | Agent encountered fatal error | Report issue |
| `PARSE_ERROR` | Invalid JSON in findings | Delete and re-audit |
| `PERMISSION_DENIED` | Can't write to file | Check permissions |
| `FILE_NOT_FOUND` | Target file doesn't exist | File may have been moved/deleted |
| `SCHEMA_INVALID` | Finding doesn't match schema | Internal error - report issue |

---

## Best Practices

### Before Running Audits

1. Commit or stash uncommitted changes
2. Ensure adequate disk space
3. For large codebases, plan scoped audits

### Before Running Fixes

1. Review findings with `/status`
2. Commit current state: `git add -A && git commit -m "pre-fix checkpoint"`
3. Start with `--auto` for safe fixes
4. Use `--interactive` for control

### Regular Maintenance

1. Run `/audit` periodically (weekly/before releases)
2. Address critical/high findings promptly
3. Keep findings.json in `.gitignore` (project-specific) or commit it (for tracking)
