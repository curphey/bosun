---
name: improve
description: Prioritize remaining findings and plan or execute improvement sprints. Works with findings from /audit.
---

# /improve Command

Analyzes remaining open findings from `/audit`, prioritizes them, and either generates an improvement plan or executes improvements in prioritized sprints.

## Usage

```
/improve [flags]
```

**Flags:**
- `--plan` - Generate prioritized improvement plan only (default)
- `--execute` - Execute the improvement plan
- `--sprint <n>` - Limit execution to n sprints (default: 1)
- `--focus <category>` - Focus on specific category (security, quality, docs, etc.)

## What Happens

### Plan Mode (default)

`/improve --plan` analyzes open findings and generates a prioritized plan:

1. **Reads findings** from `.bosun/findings.json`
2. **Filters** to open findings only
3. **Scores** each finding based on:
   - Severity (critical=100, high=75, medium=50, low=25, info=10)
   - Effort (trivial=1.0x, minor=0.9x, moderate=0.7x, major=0.5x, significant=0.3x)
   - Dependencies (blocked items deprioritized)
   - Category multipliers (security gets 1.5x by default)
4. **Groups** into sprints based on effort and dependencies
5. **Outputs** prioritized plan

### Execute Mode

`/improve --execute` runs the plan:

1. **Generates plan** as above
2. **Confirms** sprint scope with user
3. **Executes** each sprint using appropriate agents
4. **Validates** changes after each sprint
5. **Updates** findings.json with results

## Priority Scoring

Each finding gets a priority score:

```
score = severity_weight × effort_multiplier × category_multiplier

Where:
- severity_weight: critical=100, high=75, medium=50, low=25, info=10
- effort_multiplier: trivial=1.0, minor=0.9, moderate=0.7, major=0.5, significant=0.3
- category_multiplier: security=1.5, quality=1.0, docs=0.8, architecture=1.2, devops=1.1
```

Higher scores = higher priority.

## Plan Output

```
/improve

Reading .bosun/findings.json...
Found 15 open findings

## Improvement Plan

### Sprint 1: Quick Wins (Est. effort: trivial-minor)
Priority | ID      | Title                          | Category | Effort
---------|---------|--------------------------------|----------|--------
150      | SEC-001 | Hardcoded API key              | security | trivial
112      | SEC-003 | Missing CSRF protection        | security | minor
75       | QUA-002 | Missing error handling         | quality  | minor
60       | DOC-001 | Missing README installation    | docs     | minor

Impact: Resolves 1 critical, 2 high, 1 medium finding
Dependencies: None

### Sprint 2: Security Hardening (Est. effort: minor-moderate)
Priority | ID      | Title                          | Category | Effort
---------|---------|--------------------------------|----------|--------
105      | SEC-002 | SQL injection vulnerability    | security | moderate
90       | SEC-004 | Missing rate limiting          | security | moderate
67       | QUA-005 | Unvalidated user input         | quality  | minor

Impact: Resolves 2 high, 1 medium finding
Dependencies: Sprint 1 (env vars must be configured)

### Sprint 3: Technical Debt (Est. effort: moderate-major)
Priority | ID      | Title                          | Category | Effort
---------|---------|--------------------------------|----------|--------
52       | ARC-001 | Refactor auth into service     | arch     | major
45       | QUA-003 | O(n²) algorithm optimization   | quality  | moderate
38       | ARC-002 | Extract shared utilities       | arch     | moderate

Impact: Resolves 1 high, 2 medium findings
Dependencies: Sprint 2 (auth refactor needs secure foundation)

### Remaining (Lower Priority)
- 5 low/info findings deferred to future sprints
- Run `/improve --focus quality` to prioritize these

## Recommendations
1. Start with Sprint 1 - highest ROI, minimal risk
2. Sprint 2 addresses security backlog
3. Sprint 3 can be deferred if timeline is tight

Execute Sprint 1? [y/n]
```

## Execute Output

```
/improve --execute

[Plan displayed as above]

Execute Sprint 1? [y/n] y

## Executing Sprint 1

### SEC-001: Hardcoded API key
Spawning security-agent to fix...
✓ Moved API key to environment variable
✓ Created .env.example
✓ Updated .gitignore
✓ Validation passed
Status: fixed

### SEC-003: Missing CSRF protection
Spawning security-agent to fix...
✓ Added CSRF middleware
✓ Updated form handlers
✓ Validation passed
Status: fixed

### QUA-002: Missing error handling
Spawning quality-agent to fix...
✓ Added try-catch blocks
✓ Added error logging
✓ Validation passed
Status: fixed

### DOC-001: Missing README installation
Spawning docs-agent to fix...
✓ Added installation section
✓ Added prerequisites
✓ Validation passed
Status: fixed

## Sprint 1 Complete

Summary:
- Fixed: 4 findings
- Failed: 0
- Remaining: 11 open findings

Updated .bosun/findings.json

Continue to Sprint 2? [y/n]
```

## Examples

### Generate improvement plan
```
/improve
/improve --plan
```

### Execute first sprint only
```
/improve --execute --sprint 1
```

### Execute all sprints
```
/improve --execute --sprint all
```

### Focus on security improvements
```
/improve --focus security
```

### Focus on documentation
```
/improve --focus docs --execute
```

## Sprint Configuration

Sprints are automatically configured based on:

### Effort Grouping
- **Sprint 1**: trivial + minor effort (quick wins)
- **Sprint 2**: minor + moderate effort
- **Sprint 3**: moderate + major effort
- **Sprint 4+**: major + significant effort

### Dependency Ordering
Findings with dependencies are scheduled after their dependencies:
- Environment variable extraction before code that uses them
- Auth refactoring after security foundations
- Tests after implementation

### Category Focus
When using `--focus`, the category multiplier is boosted to 2.0x for that category.

## Implementation Notes

When implementing this command:

1. **Read findings**
   ```bash
   cat .bosun/findings.json
   ```

2. **Calculate scores**
   ```
   For each finding:
     score = severity_weights[severity]
           × effort_multipliers[effort]
           × category_multipliers[category]
   ```

3. **Sort and group**
   - Sort by score descending
   - Group into sprints by effort bands
   - Respect dependencies (topological sort)

4. **Generate plan**
   - Format as table
   - Show impact summary
   - List dependencies

5. **Execute (if --execute)**
   - Spawn appropriate agent for each finding
   - Agent applies fix
   - Validate after each fix
   - Update findings.json

6. **Update findings.json**
   - Mark fixed items
   - Track sprint metadata

## Chaining

```
/audit          → writes .bosun/findings.json
/fix            → applies immediate fixes
/improve        → prioritizes and plans remaining work
/improve --exec → executes improvement sprints
/status         → shows current findings summary
```

## Typical Workflow

```
# 1. Run audit
/audit

# 2. Apply quick fixes
/fix --auto

# 3. Review and plan improvements
/improve

# 4. Execute improvements sprint by sprint
/improve --execute --sprint 1
/improve --execute --sprint 2

# 5. Check status
/status
```
