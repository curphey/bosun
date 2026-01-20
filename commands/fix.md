---
name: fix
description: Remediate findings from the last audit. Applies fixes based on interaction tiers with optional validation.
---

# /fix Command

Remediates findings from the last `/audit` run. Reads `.bosun/findings.json` and applies fixes based on interaction tiers, with automatic validation of applied fixes.

## Usage

```
/fix [scope] [flags]
```

**Flags:**
- `--auto` - Apply only auto-tier fixes silently
- `--interactive` - Prompt for every fix individually
- `--validate` - Run validation after each fix (default: true)
- `--no-validate` - Skip validation (faster but less safe)
- `--dry-run` - Show what would be fixed without making changes

**Scope options:**
- (none) - Fix all open findings
- `security` - Fix security findings only
- `quality` - Fix quality findings only
- `docs` - Fix documentation findings only
- `architecture` - Fix architecture findings only
- `devops` - Fix DevOps findings only
- `SEC-001` - Fix specific finding by ID

## Interaction Tiers

The fix command applies different approval flows based on each finding's interaction tier:

| Tier | Approval | Examples |
|------|----------|----------|
| **auto** | None (silent) | Formatting, linting, typos, security headers (additive) |
| **confirm** | Batch | Env var extraction, import sorting, doc additions |
| **approve** | Individual | API changes, refactoring, dependency updates |

### Default Behavior (no flags)

1. **Auto-tier fixes** are applied silently
2. **Confirm-tier fixes** are batched by semantic category and prompted once
3. **Approve-tier fixes** are prompted individually
4. **Validation runs** after each fix to ensure correctness

### Permission Model

When prompted for a fix, you can respond:

| Key | Action |
|-----|--------|
| `y` | Apply this fix |
| `n` | Skip this fix |
| `a` | Allow all fixes of this type (session) |
| `!` | Allow always (persistent, stored in `.bosun/permissions.json`) |

### Semantic Category Batching

Instead of approving individual fixes, you can approve by semantic category:

```
3 findings match "extract secrets to env vars":
- SEC-001: Hardcoded API key (src/config.js:15)
- SEC-002: Hardcoded DB password (src/db.js:8)
- SEC-003: Hardcoded JWT secret (src/auth.js:22)

Apply all 3 fixes? [y/n/a/!]
```

## Validation

By default, `/fix` validates each fix after applying it:

### Validation Steps

1. **Syntax check** - Ensure modified file is syntactically valid
2. **Lint check** - Run appropriate linter (eslint, ruff, golangci-lint)
3. **Type check** - Run type checker if available (tsc, mypy, go vet)
4. **Test check** - Run related tests if identifiable
5. **Build check** - Verify project still builds

### Validation Results

```
Applying fix SEC-001: Hardcoded API key → env var...
✓ File modified: src/config.js
✓ Syntax valid
✓ ESLint passed
✓ TypeScript compiled
✓ Related tests passed (src/config.test.js)
Fix validated successfully.
```

### Validation Failure Handling

If validation fails:

```
Applying fix QUA-001: Extract helper function...
✓ File modified: src/utils.js
✓ Syntax valid
✗ ESLint failed: 'newHelper' is defined but never used
✗ Tests failed: 1 assertion error

Fix validation failed. Options:
[r] Rollback this fix
[c] Continue anyway (mark as needs-review)
[e] Edit the fix manually
[s] Skip this finding
```

## Output

### Progress Display

```
/fix

Reading .bosun/findings.json...
Found 12 open findings (4 auto, 5 confirm, 3 approve)

## Auto-tier fixes (4)
Applying SEC-005: Add CSP header... ✓
Applying QUA-003: Fix formatting... ✓
Applying QUA-004: Fix formatting... ✓
Applying DOC-002: Fix typo... ✓

## Confirm-tier fixes (5)

Category: "extract secrets to env vars" (2 findings)
- SEC-001: Hardcoded API key (src/config.js:15)
- SEC-002: Hardcoded DB password (src/db.js:8)
Apply? [y/n/a/!] y

Applying SEC-001... ✓ (validated)
Applying SEC-002... ✓ (validated)

Category: "add error handling" (3 findings)
- QUA-001: Missing try-catch (src/api/client.js:28)
- QUA-002: Missing error boundary (src/App.jsx:15)
- QUA-005: Unhandled promise (src/services/auth.js:42)
Apply? [y/n/a/!] y

Applying QUA-001... ✓ (validated)
Applying QUA-002... ✓ (validated)
Applying QUA-005... ✓ (validated)

## Approve-tier fixes (3)

ARC-001: Refactor authentication flow
  Location: src/auth/
  Effort: major
  Description: Extract auth logic into dedicated service
Apply this fix? [y/n/!] n
Skipped.

...

## Summary
- Applied: 9 fixes
- Skipped: 2 fixes
- Failed: 1 fix (needs review)

Updated .bosun/findings.json
```

### Findings Update

After fixing, `.bosun/findings.json` is updated:

```json
{
  "findings": [
    {
      "id": "SEC-001",
      "status": "fixed",
      "fixedAt": "2024-01-15T11:45:00Z",
      "fixedBy": "fix-command"
    },
    {
      "id": "ARC-001",
      "status": "open"
    },
    {
      "id": "QUA-006",
      "status": "open",
      "tags": ["needs-review"]
    }
  ]
}
```

## Examples

### Apply all fixes with default behavior
```
/fix
```

### Apply only auto-tier fixes silently
```
/fix --auto
```

### Fix only security issues interactively
```
/fix security --interactive
```

### Fix specific finding
```
/fix SEC-001
```

### Dry run to preview changes
```
/fix --dry-run
```

### Fix without validation (faster)
```
/fix --no-validate
```

## Permissions Persistence

Session and persistent permissions are stored in `.bosun/permissions.json`:

```json
{
  "session": {
    "extract secrets to env vars": true,
    "add error handling": true
  },
  "persistent": {
    "fix documentation typos": true,
    "format code": true
  }
}
```

Session permissions clear when the Claude Code session ends. Persistent permissions remain until manually removed.

## Implementation Notes

When implementing this command:

1. **Read findings**
   ```bash
   cat .bosun/findings.json
   ```

2. **Group by interaction tier**
   - Separate auto, confirm, approve findings
   - Within confirm tier, group by `suggestedFix.semanticCategory`

3. **Apply fixes by tier**
   - Auto: Apply silently using Edit tool
   - Confirm: Batch prompt by category, then apply
   - Approve: Individual prompt for each

4. **Validate each fix** (unless --no-validate)
   - Check syntax
   - Run linter
   - Run type checker
   - Run related tests
   - Verify build

5. **Handle validation failures**
   - Offer rollback, continue, edit, or skip
   - Track failures for summary

6. **Update findings.json**
   - Set `status: "fixed"` for applied fixes
   - Add `fixedAt` timestamp
   - Add `fixedBy: "fix-command"`
   - Add tags for failures

7. **Update permissions.json**
   - Store session permissions
   - Store persistent permissions (if `!` chosen)

## Error Handling

### No Findings

| Scenario | Cause | Solution |
|----------|-------|----------|
| "No findings.json found" | Audit not run | Run `/audit` first |
| "No open findings" | All findings already fixed | Run `/audit` for fresh scan |
| "No findings match scope" | Scope filter too narrow | Use broader scope or no scope |

### Fix Failures

**File Permission Errors**:
```
Error: Cannot write to src/config.js - Permission denied
```
- Check file permissions: `ls -la src/config.js`
- Fix permissions: `chmod u+w src/config.js`
- Re-run `/fix`

**File Modified Externally**:
```
Warning: src/config.js has been modified since audit
```
- File changed after audit but before fix
- Options: Continue (may conflict), Skip, Re-audit

**Validation Failure**:
See "Validation Failure Handling" section above for recovery options.

### Interrupted Fixes

If `/fix` is interrupted mid-operation:

1. **Check git status**: `git status` to see partial changes
2. **Review changes**: `git diff` to inspect modifications
3. **Options**:
   - Commit good changes: `git add -A && git commit -m "partial fixes"`
   - Revert all: `git checkout .`
   - Continue: Re-run `/fix` (already-fixed findings are skipped)

**Recovery**: The findings.json tracks which fixes were applied. Re-running `/fix` will skip already-fixed findings and continue with remaining ones.

### Rollback

To undo fixes:

```bash
# Undo all uncommitted changes
git checkout .

# Undo last committed fix
git revert HEAD

# Reset findings status (mark as open again)
# Edit .bosun/findings.json and change "status": "fixed" to "status": "open"
```

### Permission Denied Scenarios

| Prompt Response | What Happens |
|-----------------|--------------|
| `n` (no) | Fix skipped, finding stays "open" |
| `y` (yes) | Fix applied to this finding only |
| `a` (all session) | Fix applied, similar fixes auto-approved this session |
| `!` (persistent) | Fix applied, similar fixes always auto-approved |

To revoke persistent permissions:
```bash
# Edit or delete permissions file
rm .bosun/permissions.json
```

See [Error Handling Guide](../docs/error-handling.md) for comprehensive troubleshooting.

## Chaining

```
/audit          → writes .bosun/findings.json
/fix            → reads findings, applies fixes, updates status
/fix --validate → validates each fix after applying
/improve        → reads findings, prioritizes remaining work
/status         → shows current findings summary
```
