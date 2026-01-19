---
name: bosun-docs-writer
description: Documentation best practices and templates. Use when writing READMEs, API documentation, changelogs, or code comments. Provides templates, style guides, and documentation-as-code patterns.
tags: [documentation, readme, api-docs, changelog, technical-writing]
---

# Bosun Docs Writer Skill

Documentation knowledge base for technical writing excellence.

## When to Use

- Writing or reviewing README files
- Creating API documentation
- Maintaining changelogs
- Writing code comments
- Setting up documentation sites

## When NOT to Use

- Code implementation (use language skills)
- Security review (use bosun-security)
- Architecture decisions (use bosun-architect)

## README Template

```markdown
# Project Name

Brief description of what this project does.

## Installation

\`\`\`bash
npm install my-project
\`\`\`

## Usage

\`\`\`javascript
import { feature } from 'my-project';
feature.doSomething();
\`\`\`

## API Reference

Brief API documentation or link to full docs.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
```

## Changelog Format (Keep a Changelog)

```markdown
# Changelog

## [Unreleased]

## [1.2.0] - 2024-03-15

### Added
- New feature description

### Changed
- Modified behavior

### Fixed
- Bug fix description (#123)

### Security
- Security patch (CVE-2024-1234)
```

## API Documentation (OpenAPI)

```yaml
openapi: 3.1.0
paths:
  /users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
```

## Code Comments

### When TO Comment

```python
# Explains WHY, not what
# Using binary search because list is always sorted
# and we need O(log n) for real-time responsiveness
index = binary_search(sorted_users, target_id)

# Non-obvious business rule
# Discount capped at 30% per legal agreement (JIRA-1234)
max_discount = min(calculated_discount, 0.30)
```

### When NOT to Comment

```python
# BAD: States the obvious
i = 0  # Initialize i to zero

# BAD: Should be better variable names
n = u.fn + " " + u.ln  # Get user's full name
# BETTER:
full_name = user.first_name + " " + user.last_name
```

## Docstring Styles

### Python (Google Style)

```python
def calculate_discount(price: float, percentage: float) -> float:
    """Calculate discounted price.

    Args:
        price: Original price in dollars.
        percentage: Discount percentage (0-100).

    Returns:
        The final price after discount.

    Raises:
        ValueError: If price is negative.
    """
```

### TypeScript (TSDoc)

```typescript
/**
 * Fetches user data from the API.
 *
 * @param userId - The unique identifier
 * @returns Promise resolving to user data
 * @throws NotFoundError when user doesn't exist
 */
```

## Documentation Generators

| Tool | Language | Format |
|------|----------|--------|
| MkDocs | Python | Markdown |
| Sphinx | Python | reStructuredText |
| TypeDoc | TypeScript | TSDoc |
| Storybook | React | MDX |

## References

See `references/` directory for detailed documentation:
- `docs-writer-research.md` - Comprehensive documentation patterns
