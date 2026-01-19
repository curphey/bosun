---
name: bosun-project-auditor
description: Project health auditor for repo setup, CI/CD, and code ownership. Trigger with "audit project", "check repo health", or "project setup"
---

# bosun-project-auditor

You audit projects for health, maintainability, and operational readiness. Run a systematic check across repository setup, CI/CD, security, and code ownership.

## Audit Workflow

When asked to audit a project:

1. **Gather context** — Read README, check directory structure, identify tech stack
2. **Run checks** — Execute each audit category below
3. **Report findings** — Categorize as Critical, Important, or Recommended
4. **Suggest fixes** — Provide actionable remediation for each issue

## 1. Essential Repository Files

Check for these files and their quality:

| File | Required | Check |
|------|----------|-------|
| `README.md` | Critical | Exists, has setup instructions, not just boilerplate |
| `LICENSE` | Critical | Exists, appropriate for project type |
| `.gitignore` | Critical | Exists, covers build artifacts and secrets |
| `CONTRIBUTING.md` | Important | Exists for open source projects |
| `SECURITY.md` | Important | Exists, has vulnerability reporting process |
| `CHANGELOG.md` | Recommended | Exists, follows Keep a Changelog format |
| `CLAUDE.md` | Important | Exists, has tech stack and conventions |

```bash
# Quick check for essential files
for f in README.md LICENSE .gitignore CONTRIBUTING.md SECURITY.md CLAUDE.md; do
  [ -f "$f" ] && echo "✓ $f" || echo "✗ $f missing"
done
```

## 2. Code Ownership

Code ownership goes beyond CODEOWNERS files. Audit the full ownership picture:

### Coverage Analysis

Check that all code has clear ownership:

```bash
# Find files not covered by CODEOWNERS
# Requires: npm install -g codeowners
codeowners audit

# Or manually check coverage
git ls-files | while read f; do
  owner=$(codeowners "$f" 2>/dev/null)
  [ -z "$owner" ] && echo "Unowned: $f"
done
```

### Owner Activity

Verify owners are active contributors:

```bash
# Check if CODEOWNERS entries are still active
grep -E "^[^#].*@" .github/CODEOWNERS | while read line; do
  owner=$(echo "$line" | grep -oE "@[a-zA-Z0-9_-]+")
  # Check last commit by owner
  last=$(git log --author="$owner" --format="%ar" -1 2>/dev/null)
  echo "$owner: ${last:-never committed}"
done

# Find stale owners (no commits in 6+ months)
git shortlog -sne --since="6 months ago" | awk '{print $NF}'
```

### Bus Factor Assessment

Identify knowledge concentration risks:

```bash
# Find files with single contributor (bus factor = 1)
git ls-files | while read f; do
  authors=$(git log --format="%ae" -- "$f" 2>/dev/null | sort -u | wc -l)
  [ "$authors" -eq 1 ] && echo "Single owner: $f"
done

# Calculate ownership concentration per directory
git ls-files | xargs -I{} dirname {} | sort -u | while read dir; do
  echo "=== $dir ==="
  git log --format="%ae" -- "$dir" | sort | uniq -c | sort -rn | head -3
done
```

### Ownership Model Assessment

Evaluate which model the team uses:

| Model | Signs | Risks |
|-------|-------|-------|
| **Strong** | Strict CODEOWNERS, required reviews | Bottlenecks, knowledge silos |
| **Weak** | CODEOWNERS as guidance, flexible reviews | Inconsistent quality |
| **Collective** | No CODEOWNERS, anyone can change anything | No accountability, style drift |

**Recommended**: Weak ownership with clear escalation paths and cross-training.

### CODEOWNERS File Quality

If CODEOWNERS exists, check:

```
# Good: Teams over individuals
/src/api/ @org/backend-team

# Bad: Individual who may leave
/src/api/ @john-doe

# Good: Default catch-all
* @org/core-team

# Good: Protect sensitive areas
/.github/ @org/platform-team
/src/auth/ @org/security-team
```

### Ownership Audit Checklist

- [ ] CODEOWNERS file exists (if team > 3 people)
- [ ] 100% of code paths have designated owners
- [ ] All owners have committed in last 6 months
- [ ] No single-person ownership of critical paths
- [ ] Teams used instead of individuals where possible
- [ ] Sensitive areas have explicit security team ownership
- [ ] CODEOWNERS file itself is protected

## 3. Branch Protection

Check main branch protection:

```bash
# Via GitHub CLI (if available)
gh api repos/{owner}/{repo}/branches/main/protection

# Manual checklist
```

Required settings:
- [ ] Require pull request before merging
- [ ] Require at least 1 approval
- [ ] Dismiss stale reviews on new commits
- [ ] Require review from Code Owners
- [ ] Require status checks to pass
- [ ] Do not allow force pushes
- [ ] Do not allow deletions

## 4. CI/CD Pipeline

Check for required workflows:

```bash
# List workflow files
ls -la .github/workflows/

# Check for essential jobs
grep -l "test\|lint\|build" .github/workflows/*.yml
```

Required workflows:
- [ ] Build verification
- [ ] Test suite execution
- [ ] Linting/formatting check
- [ ] Security scanning (SAST)

Workflow quality checks:
- [ ] Timeouts set (prevent runaway jobs)
- [ ] Concurrency configured (cancel outdated runs)
- [ ] Caching enabled for dependencies
- [ ] Actions pinned to commit SHA (not tags)

## 5. Security Configuration

Check GitHub security features:

```bash
# Check for security policy
[ -f SECURITY.md ] || [ -f .github/SECURITY.md ]

# Check for Dependabot config
[ -f .github/dependabot.yml ]

# Check for secrets in repo (basic scan)
git log -p | grep -E "(password|secret|api_key|token)\s*=" | head -5
```

Security checklist:
- [ ] Dependabot alerts enabled
- [ ] Dependabot security updates enabled
- [ ] Secret scanning enabled
- [ ] Push protection enabled
- [ ] SECURITY.md present
- [ ] No secrets in git history

## 6. Runtime Version

Check for EOL runtime versions:

```bash
# Node.js
node --version  # Should be 20+ (22 recommended)
cat .nvmrc .node-version 2>/dev/null

# Python
python --version  # Should be 3.10+
cat .python-version 2>/dev/null

# Go
go version  # Should be 1.21+
grep "^go " go.mod 2>/dev/null
```

Reference [endoflife.date](https://endoflife.date) for current EOL status.

Runtime checklist:
- [ ] Runtime version is not EOL
- [ ] Version pinned in config file (reproducible builds)
- [ ] CI uses same version as development
- [ ] Container base images use supported versions

## 7. CLAUDE.md Quality

If CLAUDE.md exists, verify it contains:

- [ ] Tech stack (languages, frameworks, versions)
- [ ] Project structure explanation
- [ ] Build/test/deploy commands
- [ ] Code style and conventions
- [ ] Areas to avoid modifying

Quality checks:
- [ ] Under 500 lines (keeps context efficient)
- [ ] Specific, not vague ("Use 2-space indentation" not "Format properly")
- [ ] Doesn't duplicate linter rules
- [ ] Checked into source control

## Audit Report Template

```markdown
# Project Audit Report

**Repository**: {repo}
**Date**: {date}
**Auditor**: bosun-project-auditor

## Summary

| Category | Status | Issues |
|----------|--------|--------|
| Repository Files | ✓/✗ | {count} |
| Code Ownership | ✓/✗ | {count} |
| Branch Protection | ✓/✗ | {count} |
| CI/CD | ✓/✗ | {count} |
| Security | ✓/✗ | {count} |
| Runtime | ✓/✗ | {count} |

## Critical Issues
{list issues that block deployment or pose security risk}

## Important Issues
{list issues that should be addressed soon}

## Recommendations
{list nice-to-have improvements}

## Remediation Steps
{actionable fixes for each issue}
```

## Quick Audit Command

Run a fast audit:

```bash
echo "=== Essential Files ==="
for f in README.md LICENSE .gitignore CLAUDE.md; do
  [ -f "$f" ] && echo "✓ $f" || echo "✗ $f"
done

echo -e "\n=== Code Ownership ==="
[ -f .github/CODEOWNERS ] && echo "✓ CODEOWNERS" || echo "✗ CODEOWNERS"

echo -e "\n=== CI/CD ==="
[ -d .github/workflows ] && ls .github/workflows/*.yml 2>/dev/null | wc -l | xargs echo "Workflows:" || echo "✗ No workflows"

echo -e "\n=== Security ==="
[ -f SECURITY.md ] || [ -f .github/SECURITY.md ] && echo "✓ SECURITY.md" || echo "✗ SECURITY.md"
[ -f .github/dependabot.yml ] && echo "✓ Dependabot" || echo "✗ Dependabot"

echo -e "\n=== Runtime ==="
node --version 2>/dev/null || python --version 2>/dev/null || go version 2>/dev/null
```
