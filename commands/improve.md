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

## Algorithm Reference

### Constants

```javascript
// Severity weights (higher = more urgent)
const SEVERITY_WEIGHTS = {
  critical: 100,
  high: 75,
  medium: 50,
  low: 25,
  info: 10
};

// Effort multipliers (higher = easier to fix = prioritize)
const EFFORT_MULTIPLIERS = {
  trivial: 1.0,    // Minutes
  minor: 0.9,      // < 1 hour
  moderate: 0.7,   // 1-4 hours
  major: 0.5,      // 4-8 hours
  significant: 0.3 // > 1 day
};

// Category multipliers (adjust based on project priorities)
const CATEGORY_MULTIPLIERS = {
  security: 1.5,      // Security issues are urgent
  architecture: 1.2,  // Arch debt compounds
  devops: 1.1,        // Ops issues affect everyone
  quality: 1.0,       // Baseline
  performance: 1.0,   // Baseline
  testing: 0.9,       // Important but less urgent
  docs: 0.8,          // Lowest urgency
  'ux-ui': 0.9        // UX issues
};

// Sprint effort bands
const SPRINT_EFFORT_BANDS = [
  ['trivial', 'minor'],           // Sprint 1: Quick wins
  ['minor', 'moderate'],          // Sprint 2: Medium effort
  ['moderate', 'major'],          // Sprint 3: Significant work
  ['major', 'significant']        // Sprint 4+: Large refactors
];
```

### Priority Score Calculation

```javascript
function calculatePriorityScore(finding, focusCategory = null) {
  const severityWeight = SEVERITY_WEIGHTS[finding.severity] || 50;
  const effortMultiplier = EFFORT_MULTIPLIERS[finding.suggestedFix?.effort] || 0.7;

  let categoryMultiplier = CATEGORY_MULTIPLIERS[finding.category] || 1.0;

  // Boost focused category
  if (focusCategory && finding.category === focusCategory) {
    categoryMultiplier = 2.0;
  }

  return Math.round(severityWeight * effortMultiplier * categoryMultiplier);
}
```

### Dependency Resolution (Topological Sort)

```javascript
function orderByDependencies(findings) {
  // Build dependency graph
  const graph = new Map();
  const inDegree = new Map();

  findings.forEach(f => {
    graph.set(f.id, []);
    inDegree.set(f.id, 0);
  });

  // Add edges for dependencies
  findings.forEach(f => {
    if (f.dependsOn) {
      f.dependsOn.forEach(depId => {
        if (graph.has(depId)) {
          graph.get(depId).push(f.id);
          inDegree.set(f.id, inDegree.get(f.id) + 1);
        }
      });
    }
  });

  // Kahn's algorithm for topological sort
  const queue = [];
  const result = [];

  inDegree.forEach((degree, id) => {
    if (degree === 0) queue.push(id);
  });

  while (queue.length > 0) {
    const id = queue.shift();
    result.push(findings.find(f => f.id === id));

    graph.get(id).forEach(neighbor => {
      inDegree.set(neighbor, inDegree.get(neighbor) - 1);
      if (inDegree.get(neighbor) === 0) {
        queue.push(neighbor);
      }
    });
  }

  // Handle cycles (remaining items)
  findings.forEach(f => {
    if (!result.find(r => r.id === f.id)) {
      result.push(f);
    }
  });

  return result;
}
```

### Sprint Grouping

```javascript
function groupIntoSprints(scoredFindings) {
  const sprints = [];

  for (const [index, effortBand] of SPRINT_EFFORT_BANDS.entries()) {
    const sprintFindings = scoredFindings.filter(f => {
      const effort = f.suggestedFix?.effort || 'moderate';
      return effortBand.includes(effort);
    });

    if (sprintFindings.length > 0) {
      sprints.push({
        number: index + 1,
        name: getSprintName(index),
        effort: effortBand.join('-'),
        findings: sprintFindings.sort((a, b) => b.score - a.score),
        impact: calculateImpact(sprintFindings)
      });
    }
  }

  return sprints;
}

function getSprintName(index) {
  const names = [
    'Quick Wins',
    'Core Improvements',
    'Technical Debt',
    'Major Refactoring'
  ];
  return names[index] || `Sprint ${index + 1}`;
}

function calculateImpact(findings) {
  const counts = { critical: 0, high: 0, medium: 0, low: 0, info: 0 };
  findings.forEach(f => counts[f.severity]++);
  return counts;
}
```

### Full Algorithm Flow

```javascript
async function generateImprovementPlan(options = {}) {
  // 1. Load findings
  const findings = await loadFindings('.bosun/findings.json');

  // 2. Filter to open findings only
  let openFindings = findings.filter(f => f.status === 'open');

  // 3. Apply focus filter if specified
  if (options.focus) {
    openFindings = openFindings.filter(f => f.category === options.focus);
  }

  // 4. Calculate priority scores
  const scoredFindings = openFindings.map(f => ({
    ...f,
    score: calculatePriorityScore(f, options.focus)
  }));

  // 5. Order by dependencies
  const orderedFindings = orderByDependencies(scoredFindings);

  // 6. Group into sprints
  const sprints = groupIntoSprints(orderedFindings);

  // 7. Generate recommendations
  const recommendations = generateRecommendations(sprints);

  return {
    totalOpen: openFindings.length,
    sprints,
    recommendations
  };
}
```

### Agent Selection for Execution

```javascript
function selectAgentForFinding(finding) {
  const categoryToAgent = {
    security: 'security-agent',
    quality: 'quality-agent',
    docs: 'docs-agent',
    architecture: 'architecture-agent',
    devops: 'devops-agent',
    'ux-ui': 'ux-ui-agent',
    testing: 'testing-agent',
    performance: 'performance-agent'
  };

  return categoryToAgent[finding.category] || 'quality-agent';
}
```

## Error Handling

### No Findings

| Scenario | Cause | Solution |
|----------|-------|----------|
| "No findings.json found" | Audit not run | Run `/audit` first |
| "No open findings" | All findings fixed | Run `/audit` for fresh scan |
| "Cannot calculate priorities" | Invalid findings data | Check findings.json format |

### Sprint Execution Failures

**Agent Failure During Sprint**:
```
Sprint 1: SEC-001 fix failed
Error: Agent timeout while processing
```

Recovery:
1. Completed fixes within the sprint are preserved
2. Failed finding remains "open"
3. Continue with remaining findings: `/improve --execute`
4. Or retry failed finding: `/fix SEC-001`

**Validation Failure**:
```
Sprint 1: QUA-001 fix applied but validation failed
- Tests failing: 2 assertions
```

Options:
- `[r]` Rollback this fix and continue sprint
- `[c]` Continue anyway (mark as needs-review)
- `[s]` Skip remaining sprint, review manually

### Interrupted Execution

If `/improve --execute` is interrupted:

1. **Check progress**: Run `/status` to see what was fixed
2. **Review changes**: `git diff` to inspect modifications
3. **Continue**: Re-run `/improve --execute` - already-fixed findings are skipped
4. **Rollback if needed**: `git checkout .` to revert uncommitted changes

### Dependency Issues

**Circular Dependencies**:
```
Warning: Circular dependency detected between SEC-001 and ARC-002
```
- Findings will be scheduled in same sprint
- Manual review may be needed

**Unresolvable Dependencies**:
```
Warning: QUA-005 depends on SEC-001 which is "wontfix"
```
- Dependent finding scheduled anyway
- Consider reviewing the dependency

### Focus Mode Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "No findings in category" | Category has no open findings | Use different focus or no focus |
| "Invalid category" | Typo in category name | Use: security, quality, docs, architecture, devops |

See [Error Handling Guide](../docs/error-handling.md) for comprehensive troubleshooting.

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
