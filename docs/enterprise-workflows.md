# Enterprise Workflows

Guide to integrating Bosun into enterprise development workflows.

## Table of Contents

1. [Team Workflow Integration](#team-workflow-integration)
2. [CI/CD Pipeline Integration](#cicd-pipeline-integration)
3. [Pull Request Review Workflows](#pull-request-review-workflows)
4. [Custom Skills for Enterprise](#custom-skills-for-enterprise)
5. [Governance and Compliance](#governance-and-compliance)
6. [Multi-Repository Setup](#multi-repository-setup)

---

## Team Workflow Integration

### Daily Development Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Workflow                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Feature Branch      2. Development       3. Pre-Commit       │
│     git checkout -b       Write code          /audit             │
│     feature/xyz                               Fix findings       │
│                                                                  │
│  4. Pull Request        5. CI Audit          6. Merge            │
│     Push & create PR      Automated check     After approval     │
│                           Blocks on critical                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Recommended Audit Points

| Stage | Command | Severity Threshold | Purpose |
|-------|---------|-------------------|---------|
| Pre-commit | `/audit` | Any | Catch issues early |
| Pre-push | `/audit --severity high` | High+ | Block bad code from remote |
| PR | Automated CI | Medium+ | Enforce standards |
| Pre-release | Full audit | Any | Final quality gate |

### Team Configuration

Create a shared `.bosun/config.json` at the repository root:

```json
{
  "audit": {
    "agents": ["security", "quality", "docs"],
    "severityThreshold": "medium",
    "autoFix": false
  },
  "improve": {
    "batchSize": 5,
    "autoCommit": false
  },
  "skills": {
    "include": ["bosun-typescript", "bosun-security"],
    "exclude": []
  }
}
```

---

## CI/CD Pipeline Integration

### GitHub Actions

```yaml
# .github/workflows/bosun-audit.yml
name: Bosun Audit

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Claude Code
        run: |
          npm install -g @anthropic-ai/claude-code
          claude plugin install bosun@curphey/bosun

      - name: Run Bosun Audit
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Run /audit and output findings as JSON" > audit-results.json

      - name: Check for Critical Findings
        run: |
          CRITICAL=$(jq '[.findings[] | select(.severity == "critical")] | length' audit-results.json)
          HIGH=$(jq '[.findings[] | select(.severity == "high")] | length' audit-results.json)

          echo "Critical: $CRITICAL, High: $HIGH"

          if [ "$CRITICAL" -gt 0 ]; then
            echo "::error::Found $CRITICAL critical findings"
            exit 1
          fi

      - name: Upload Audit Results
        uses: actions/upload-artifact@v4
        with:
          name: bosun-audit
          path: audit-results.json

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('audit-results.json'));
            const summary = results.summary;

            const body = `## Bosun Audit Results

            | Severity | Count |
            |----------|-------|
            | Critical | ${summary.critical || 0} |
            | High | ${summary.high || 0} |
            | Medium | ${summary.medium || 0} |
            | Low | ${summary.low || 0} |

            **Total Findings:** ${summary.total}
            `;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - audit

bosun-audit:
  stage: audit
  image: node:20
  variables:
    ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY
  before_script:
    - npm install -g @anthropic-ai/claude-code
    - claude plugin install bosun@curphey/bosun
  script:
    - claude -p "Run /audit security ./src" > security-audit.json
    - |
      CRITICAL=$(jq '[.findings[] | select(.severity == "critical")] | length' security-audit.json)
      if [ "$CRITICAL" -gt 0 ]; then
        echo "Found $CRITICAL critical findings"
        exit 1
      fi
  artifacts:
    paths:
      - security-audit.json
    reports:
      codequality: security-audit.json
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run quick audit on staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx|py|go)$')

if [ -n "$STAGED_FILES" ]; then
  echo "Running Bosun pre-commit audit..."

  # Create temp file with staged content
  for file in $STAGED_FILES; do
    git show ":$file" > "/tmp/staged-$file"
  done

  # Run focused audit
  claude -p "Audit these files for critical issues: $STAGED_FILES" > /tmp/audit.json

  CRITICAL=$(jq '[.findings[] | select(.severity == "critical")] | length' /tmp/audit.json)

  if [ "$CRITICAL" -gt 0 ]; then
    echo "❌ Found $CRITICAL critical issues. Commit blocked."
    jq '.findings[] | select(.severity == "critical") | "\(.file):\(.line): \(.message)"' /tmp/audit.json
    exit 1
  fi

  echo "✅ Pre-commit audit passed"
fi
```

---

## Pull Request Review Workflows

### Automated PR Review

When a PR is opened, Bosun can provide an initial review:

```yaml
# Triggered by PR webhook
name: Bosun PR Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get Changed Files
        id: changed
        run: |
          FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | tr '\n' ' ')
          echo "files=$FILES" >> $GITHUB_OUTPUT

      - name: Run Targeted Audit
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review these changed files for issues: ${{ steps.changed.outputs.files }}" > review.json

      - name: Post Review Comments
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = JSON.parse(fs.readFileSync('review.json'));

            for (const finding of review.findings) {
              await github.rest.pulls.createReviewComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                pull_number: context.issue.number,
                body: `**${finding.severity.toUpperCase()}**: ${finding.message}\n\n${finding.suggestion || ''}`,
                path: finding.file,
                line: finding.line
              });
            }
```

### Review Checklist Integration

Add Bosun findings to PR templates:

```markdown
<!-- .github/pull_request_template.md -->
## Description
<!-- What does this PR do? -->

## Bosun Audit
- [ ] Ran `/audit` locally
- [ ] All critical/high findings addressed
- [ ] Security findings reviewed

## Audit Summary
<!-- Paste output from `/audit` here -->
```

---

## Custom Skills for Enterprise

### Creating Organization-Specific Skills

Create skills that encode your organization's standards:

```markdown
<!-- skills/acme-standards/SKILL.md -->
---
name: acme-standards
description: ACME Corp coding standards and patterns. Use when reviewing code for compliance with internal standards.
tags: [acme, standards, compliance]
---

# ACME Corp Standards

## Required Patterns

### Error Handling
All public functions must return Result types:

```typescript
// Required pattern
function fetchUser(id: string): Result<User, AcmeError> {
  // ...
}
```

### Logging
All services must use the corporate logger:

```typescript
import { logger } from '@acme/logging';

// Required: structured logging
logger.info('User created', { userId: user.id, action: 'create' });
```

### API Responses
All API responses must follow the standard envelope:

```typescript
interface ApiResponse<T> {
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
  };
}
```
```

### Skill Registration

Register custom skills in your config:

```json
{
  "skills": {
    "custom": [
      "./skills/acme-standards",
      "./skills/acme-security"
    ]
  }
}
```

---

## Governance and Compliance

### Audit Trail

Bosun creates an audit trail in `.bosun/findings.json`. For compliance:

1. **Version Control**: Commit findings to track history
2. **Export**: Generate compliance reports from findings
3. **Track Remediation**: Monitor fix status over time

### Compliance Report Generation

```bash
#!/bin/bash
# scripts/generate-compliance-report.sh

# Generate report from findings
jq -r '
  "# Compliance Report\n" +
  "Generated: " + (now | strftime("%Y-%m-%d")) + "\n\n" +
  "## Summary\n" +
  "- Total Findings: " + (.summary.total | tostring) + "\n" +
  "- Critical: " + (.summary.critical // 0 | tostring) + "\n" +
  "- Open: " + ([.findings[] | select(.status == "open")] | length | tostring) + "\n" +
  "- Fixed: " + ([.findings[] | select(.status == "fixed")] | length | tostring) + "\n\n" +
  "## Critical Findings\n" +
  ([.findings[] | select(.severity == "critical") |
    "- **" + .id + "**: " + .message + " (" + .status + ")"] | join("\n"))
' .bosun/findings.json > compliance-report.md
```

### Security Standards Mapping

Map Bosun findings to compliance frameworks:

| Bosun Category | OWASP | CWE | SOC 2 |
|---------------|-------|-----|-------|
| injection | A03:2021 | CWE-89 | CC6.1 |
| auth | A07:2021 | CWE-287 | CC6.1, CC6.2 |
| crypto | A02:2021 | CWE-327 | CC6.7 |
| secrets | A09:2021 | CWE-798 | CC6.1 |

---

## Multi-Repository Setup

### Monorepo Configuration

For monorepos, configure per-package auditing:

```json
{
  "packages": {
    "packages/api": {
      "skills": ["bosun-typescript", "bosun-security"],
      "agents": ["security", "quality"]
    },
    "packages/web": {
      "skills": ["bosun-typescript", "bosun-ux-ui"],
      "agents": ["quality"]
    },
    "packages/shared": {
      "skills": ["bosun-typescript", "bosun-architect"],
      "agents": ["quality"]
    }
  }
}
```

### Cross-Repository Standards

For organizations with multiple repositories:

1. **Central Skills Repository**
   ```
   acme-bosun-skills/
   ├── skills/
   │   ├── acme-api-standards/
   │   ├── acme-frontend-standards/
   │   └── acme-security/
   └── README.md
   ```

2. **Install in Each Repository**
   ```bash
   claude plugin install acme-bosun-skills@acme/acme-bosun-skills
   ```

3. **Inherit Base Configuration**
   ```json
   {
     "extends": "@acme/bosun-config",
     "overrides": {
       "severityThreshold": "high"
     }
   }
   ```

---

## Metrics and Reporting

### Tracking Improvement Over Time

```bash
#!/bin/bash
# Track findings over time
DATE=$(date +%Y-%m-%d)
FINDINGS=$(jq '.summary.total' .bosun/findings.json)
CRITICAL=$(jq '.summary.critical // 0' .bosun/findings.json)

echo "$DATE,$FINDINGS,$CRITICAL" >> metrics/findings-history.csv
```

### Dashboard Integration

Export findings to your metrics platform:

```javascript
// Export to monitoring system
const findings = require('./.bosun/findings.json');

metrics.gauge('bosun.findings.total', findings.summary.total);
metrics.gauge('bosun.findings.critical', findings.summary.critical || 0);
metrics.gauge('bosun.findings.high', findings.summary.high || 0);
metrics.gauge('bosun.findings.open',
  findings.findings.filter(f => f.status === 'open').length
);
```

---

## Best Practices

### Do

- Run `/audit` before creating PRs
- Address critical/high findings before merging
- Commit `.bosun/findings.json` for audit trail
- Create custom skills for organization standards
- Integrate into CI/CD for consistent enforcement

### Don't

- Ignore critical security findings
- Commit with unreviewed findings
- Disable audits to "ship faster"
- Use only automated checks (human review still needed)
- Over-customize severity thresholds (defeats the purpose)

### Escalation Policy

| Severity | Response Time | Requires |
|----------|--------------|----------|
| Critical | Immediate | Block merge, security review |
| High | Same day | Fix before merge |
| Medium | This sprint | Track in backlog |
| Low | Backlog | Fix when convenient |
| Info | Optional | Consider for improvement |
