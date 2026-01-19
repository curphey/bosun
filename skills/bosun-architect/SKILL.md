---
name: bosun-architect
description: Software architecture patterns and design principles. Use when designing systems, making architectural decisions, reviewing code structure, or creating design documents. Provides SOLID, DDD, Clean Architecture, and API design guidance.
tags: [architecture, design-patterns, solid, ddd, api-design]
---

# Bosun Architect Skill

Architecture knowledge base for system design and code structure decisions.

## When to Use

- Designing new systems or major features
- Making architectural decisions
- Reviewing code structure and organization
- Creating Architecture Decision Records (ADRs)
- Evaluating trade-offs between patterns
- Designing APIs

## When NOT to Use

- Language-specific implementation (use language skills)
- Security concerns (use bosun-security)
- Documentation format (use bosun-docs-writer)

## SOLID Principles

| Principle | Description | Violation Sign |
|-----------|-------------|----------------|
| **S**ingle Responsibility | One reason to change | Class does too much |
| **O**pen/Closed | Open for extension, closed for modification | Changing existing code for new features |
| **L**iskov Substitution | Subtypes substitutable for base types | Overrides that break contracts |
| **I**nterface Segregation | Specific interfaces over general | Clients implement unused methods |
| **D**ependency Inversion | Depend on abstractions | High-level modules import low-level |

## Architecture Patterns

### When to Use Each

| Pattern | Best For | Avoid When |
|---------|----------|------------|
| **Monolith** | Small teams, simple domains | Scaling concerns |
| **Microservices** | Large teams, complex domains | Simple applications |
| **Hexagonal** | Testability, port/adapter isolation | Quick prototypes |
| **Event-Driven** | Loose coupling, async workflows | Simple CRUD |
| **CQRS** | Read/write optimization | Simple domains |

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│           Frameworks & UI           │  ← External (Web, DB, etc.)
├─────────────────────────────────────┤
│        Interface Adapters           │  ← Controllers, Gateways
├─────────────────────────────────────┤
│          Application Logic          │  ← Use Cases
├─────────────────────────────────────┤
│           Domain Entities           │  ← Business Rules (innermost)
└─────────────────────────────────────┘

Dependencies point INWARD only
```

## API Design Principles

1. **Use nouns for resources**: `/users`, `/orders`
2. **HTTP verbs for actions**: GET, POST, PUT, DELETE
3. **Consistent naming**: plural nouns, kebab-case
4. **Version your API**: `/api/v1/users`
5. **Return appropriate status codes**
6. **Paginate collections**
7. **Use HATEOAS for discoverability**

## ADR Template

```markdown
# ADR-001: [Decision Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[What is the issue? Why does this decision need to be made?]

## Decision
[What is the change being proposed?]

## Consequences
[What are the positive and negative results?]
```

## Code Organization

### Feature-Based (Recommended)
```
src/
├── users/
│   ├── user.controller.ts
│   ├── user.service.ts
│   ├── user.repository.ts
│   └── user.entity.ts
├── orders/
│   └── ...
```

### Layer-Based
```
src/
├── controllers/
├── services/
├── repositories/
├── entities/
```

## References

See `references/` directory for detailed documentation:
- `architect-research.md` - Comprehensive architecture patterns
