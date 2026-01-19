---
name: bosun-threat-model
description: Threat modeling methodology and risk assessment. Use when performing STRIDE analysis, creating attack trees, building data flow diagrams, or assessing risk with CVSS/DREAD. Provides structured threat identification frameworks.
tags: [threat-modeling, stride, risk-assessment, attack-trees, dfd]
---

# Bosun Threat Model Skill

Threat modeling knowledge base for systematic threat identification and risk assessment.

## When to Use

- Performing STRIDE threat analysis
- Creating attack trees
- Building data flow diagrams (DFDs)
- Assessing risk (CVSS, DREAD)
- Writing security user stories / abuse cases
- Identifying trust boundaries

## When NOT to Use

- Code-level vulnerability scanning (use bosun-security)
- Implementation of security controls (use bosun-security)
- General architecture review (use bosun-architect)

## STRIDE Framework

| Threat | Property Violated | Example |
|--------|-------------------|---------|
| **S**poofing | Authentication | Impersonating a user |
| **T**ampering | Integrity | Modifying data in transit |
| **R**epudiation | Non-repudiation | Denying actions |
| **I**nformation Disclosure | Confidentiality | Data leaks |
| **D**enial of Service | Availability | Resource exhaustion |
| **E**levation of Privilege | Authorization | Gaining admin access |

## STRIDE Analysis Template

```markdown
## STRIDE Analysis: [Component]

### Spoofing
- [ ] Can an attacker impersonate a user?
- [ ] Are authentication mechanisms secure?

### Tampering
- [ ] Can data be modified in transit?
- [ ] Are integrity checks in place?

### Repudiation
- [ ] Are actions logged?
- [ ] Can users deny actions?

### Information Disclosure
- [ ] Is sensitive data encrypted?
- [ ] Are error messages safe?

### Denial of Service
- [ ] Is there rate limiting?
- [ ] Are resources bounded?

### Elevation of Privilege
- [ ] Is least privilege applied?
- [ ] Is input validated?
```

## DREAD Risk Scoring

| Factor | 1 (Low) | 2 (Medium) | 3 (High) |
|--------|---------|------------|----------|
| **D**amage | Minor | Significant | Critical |
| **R**eproducibility | Hard | Sometimes | Always |
| **E**xploitability | Difficult | Moderate | Easy |
| **A**ffected Users | Few | Some | All |
| **D**iscoverability | Hidden | Findable | Obvious |

**Score** = (D + R + E + A + D) / 5

- **High Risk**: 2.5 - 3.0
- **Medium Risk**: 1.5 - 2.4
- **Low Risk**: 1.0 - 1.4

## Data Flow Diagram Components

| Symbol | Component | Description |
|--------|-----------|-------------|
| ○ | Process | Application logic |
| ═ | Data Store | Database, file |
| □ | External Entity | User, external system |
| → | Data Flow | Data movement |
| ┊ | Trust Boundary | Security perimeter |

## Abuser Story Template

```markdown
**As a** [malicious actor],
**I want to** [malicious action],
**So that** [attacker's goal].
```

Example:
> **As a** hacker, **I want to** send SQL injection in login forms, **So that** I can access unauthorized data.

## References

See `references/` directory for detailed documentation:
- `threat-model-research.md` - Comprehensive threat modeling patterns
