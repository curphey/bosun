# Skill Development Guide

This guide explains how to create custom skills for Bosun. Skills are reusable knowledge packages that agents load to gain expertise in specific domains.

## What is a Skill?

A skill is a curated knowledge package containing:
- **Patterns**: Best practices and anti-patterns
- **Rules**: When to flag issues
- **Examples**: Correct and incorrect code samples
- **References**: Deep-dive documentation

Skills make agents smarter without requiring changes to agent logic.

## Skill Anatomy

```
skills/
└── bosun-{name}/
    ├── SKILL.md           # Main skill file (required)
    └── references/        # Detailed documentation (optional)
        ├── patterns.md
        ├── anti-patterns.md
        └── tools.md
```

### Required: SKILL.md

Every skill needs a `SKILL.md` file with:

1. **YAML Frontmatter**: Metadata for discovery
2. **Content**: Knowledge the agent uses

### Optional: references/

For skills over 300 lines, split detailed content into `references/` subdirectory. This keeps the main skill focused while allowing deep documentation.

## Creating a Skill

### Step 1: Plan Your Skill

Before writing, answer:
- What domain does this cover?
- Who will use it (which agent)?
- What problems does it help solve?
- What existing skills overlap?

### Step 2: Create Directory Structure

```bash
mkdir -p skills/bosun-{name}/references
```

### Step 3: Write the Frontmatter

```yaml
---
name: bosun-{name}
description: Brief description with trigger phrases. Use when [specific scenarios]. Provides [capabilities].
tags: [tag1, tag2, tag3]
---
```

#### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (must match directory name) |
| `description` | Yes | Discovery text with trigger phrases |
| `tags` | No | Keywords for categorization |

#### Writing Good Descriptions

The description is critical for auto-discovery. Include:
- What the skill covers
- When to use it ("Use when...")
- What it provides ("Provides...")

**Good:**
```yaml
description: Security best practices and vulnerability patterns. Use when reviewing code for security issues, implementing authentication, handling secrets, or scanning dependencies. Provides OWASP patterns, injection prevention, and security tool guidance.
```

**Bad:**
```yaml
description: Security stuff.
```

### Step 4: Structure the Content

Recommended sections:

```markdown
# Skill Name

Brief introduction.

## When to Use

- Scenario 1
- Scenario 2

## When NOT to Use

- Use other-skill instead for X
- Use another-skill for Y

## Core Concepts

### Concept 1

Explanation with examples.

### Concept 2

Explanation with examples.

## Quick Reference

Tables, checklists, common patterns.

## References

See `references/` for detailed documentation:
- `patterns.md` - Detailed patterns
- `anti-patterns.md` - What to avoid
```

### Step 5: Add Examples

Always include code examples showing correct and incorrect patterns:

````markdown
### Secure vs Insecure Patterns

```python
# INSECURE: SQL injection
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# SECURE: Parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```
````

### Step 6: Add References (if needed)

For detailed documentation, create files in `references/`:

```markdown
<!-- references/injection-prevention.md -->
# Injection Prevention Deep Dive

Detailed explanation of injection attacks and prevention...
```

Then link from main SKILL.md:

```markdown
## References

See `references/` for detailed documentation:
- `injection-prevention.md` - SQL, command, and XSS injection
```

## Best Practices

### Keep Skills Focused

Each skill should cover one domain. Don't create a "bosun-everything" skill.

| Good | Bad |
|------|-----|
| bosun-security | bosun-all-the-things |
| bosun-typescript | bosun-frontend |
| bosun-testing | bosun-quality-and-testing-and-docs |

### Keep SKILL.md Under 500 Lines

If your skill exceeds 500 lines:
1. Move detailed content to `references/`
2. Keep SKILL.md as an overview with links
3. Include quick-reference sections inline

### Use Tables for Quick Reference

```markdown
## Security Headers

| Header | Value | Purpose |
|--------|-------|---------|
| HSTS | max-age=31536000 | Force HTTPS |
| CSP | script-src 'self' | Prevent XSS |
| X-Frame-Options | DENY | Prevent clickjacking |
```

### Include Anti-Patterns

Show what NOT to do, not just what to do:

````markdown
### ❌ Anti-Patterns

```javascript
// DON'T: Eval user input
eval(userInput);

// DON'T: innerHTML with untrusted data
element.innerHTML = userData;
```

### ✅ Correct Patterns

```javascript
// DO: Use safe alternatives
JSON.parse(userInput);

// DO: Use textContent
element.textContent = userData;
```
````

### Add Tool Recommendations

Include relevant tools and how to use them:

```markdown
## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| ESLint | Linting | `npx eslint .` |
| Prettier | Formatting | `npx prettier --write .` |
| TypeScript | Type checking | `npx tsc --noEmit` |
```

## Skill Templates

### Language Skill Template

```markdown
---
name: bosun-{language}
description: {Language} best practices and idioms. Use when writing {language} code, reviewing {language} projects, or configuring {language} tooling.
tags: [{language}, programming]
---

# Bosun {Language} Skill

## When to Use

- Writing new {language} code
- Reviewing {language} pull requests
- Configuring linters and formatters

## Project Setup

### Recommended Configuration

\`\`\`json
{
  // Config example
}
\`\`\`

### Directory Structure

\`\`\`
project/
├── src/
├── tests/
└── config files
\`\`\`

## Coding Standards

### Naming Conventions

- Variables: convention
- Functions: convention
- Classes: convention

### Idioms

\`\`\`{language}
// Idiomatic example
\`\`\`

## Common Patterns

### Pattern 1

\`\`\`{language}
// Example
\`\`\`

## Anti-Patterns

### Anti-Pattern 1

\`\`\`{language}
// What not to do
\`\`\`

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| Tool1 | Purpose | `command` |

## References

See `references/` for detailed documentation.
```

### Domain Skill Template

```markdown
---
name: bosun-{domain}
description: {Domain} patterns and best practices. Use when [scenarios]. Provides [capabilities].
tags: [{domain}, related-tags]
---

# Bosun {Domain} Skill

## When to Use

- Scenario 1
- Scenario 2

## When NOT to Use

- Use other-skill for X

## Core Principles

### Principle 1

Explanation and rationale.

### Principle 2

Explanation and rationale.

## Patterns

### Pattern 1

\`\`\`
Example
\`\`\`

## Anti-Patterns

### What to Avoid

\`\`\`
Bad example
\`\`\`

## Quick Reference

| Item | Recommendation |
|------|----------------|
| X | Do Y |

## References

See `references/` for detailed documentation.
```

## Testing Your Skill

### 1. Validate Structure

Run the integration tests:

```bash
./tests/integration/run-tests.sh
```

The `test-skills-valid.sh` test checks:
- SKILL.md exists
- Frontmatter has required fields
- File isn't too long

### 2. Test with an Agent

Create a test project and invoke the agent that uses your skill:

```bash
# In a test project
/audit {scope}
```

Check if findings reference your skill's patterns.

### 3. Check Trigger Phrases

The skill should be auto-discovered when users mention trigger phrases from your description.

## Connecting Skills to Agents

Skills are connected to agents via the agent's frontmatter:

```yaml
---
name: security-agent
skills: [bosun-security, bosun-supply-chain]
---
```

To add your skill to an agent:

1. Open `agents/{agent-name}.md`
2. Add your skill to the `skills` array
3. The agent will now load your skill's knowledge

## Contributing Skills

To contribute a skill back to Bosun:

1. Create skill following this guide
2. Run integration tests: `./tests/integration/run-tests.sh`
3. Create a PR with:
   - `skills/bosun-{name}/SKILL.md`
   - `skills/bosun-{name}/references/` (if applicable)
   - Updated agent frontmatter (if applicable)

### Checklist

- [ ] SKILL.md has valid frontmatter
- [ ] Description includes trigger phrases
- [ ] Content is under 500 lines (or split into references)
- [ ] Includes "When to Use" section
- [ ] Includes code examples
- [ ] Includes anti-patterns
- [ ] Integration tests pass

## Examples

### Minimal Skill

```markdown
---
name: bosun-example
description: Example patterns. Use when learning Bosun skills.
tags: [example]
---

# Bosun Example Skill

## When to Use

- Learning how skills work

## Key Concept

Explanation here.

### Example

\`\`\`javascript
// Code example
\`\`\`
```

### Full Skill

See `skills/bosun-security/SKILL.md` for a complete example with:
- Comprehensive frontmatter
- Multiple sections
- Code examples
- Tool recommendations
- References directory

## Troubleshooting

### Skill Not Being Discovered

1. Check the `description` includes relevant trigger phrases
2. Verify the skill is listed in an agent's `skills` array
3. Check for syntax errors in YAML frontmatter

### Skill Too Long

1. Move detailed content to `references/`
2. Keep SKILL.md as overview with links
3. Use tables for quick-reference content

### Frontmatter Errors

YAML is whitespace-sensitive. Common issues:
- Missing `---` delimiters
- Incorrect indentation
- Special characters in description (wrap in quotes)

```yaml
# Correct
description: "Skills for C# and .NET development"

# Incorrect (# causes YAML comment)
description: Skills for C# development
```
