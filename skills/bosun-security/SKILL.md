---
name: bosun-security
description: Security best practices and vulnerability patterns. Use when reviewing code for security issues, implementing authentication, handling secrets, or scanning dependencies. Provides OWASP patterns, injection prevention, and security tool guidance.
tags: [security, vulnerabilities, owasp, authentication, secrets]
---

# Bosun Security Skill

Security knowledge base for vulnerability identification and secure coding practices.

## When to Use

- Reviewing code for security vulnerabilities
- Implementing authentication/authorization
- Handling secrets and credentials
- Scanning dependencies for vulnerabilities
- Setting up security headers
- Configuring SAST tools

## When NOT to Use

- General code quality (use bosun-architect)
- Threat modeling methodology (use bosun-threat-model)
- Language-specific patterns (use language skills)

## Core Security Principles

### 1. Secret Management
- **Never** hardcode secrets in code or configs
- Use environment variables or secret managers
- Configure `.gitignore` for sensitive files
- Run pre-commit secret scanning (Gitleaks, TruffleHog)

### 2. Injection Prevention
- **Always** use parameterized queries for SQL
- **Never** concatenate user input into queries/commands
- Apply context-appropriate output encoding for XSS
- Use `execFile` over `exec` for command execution

### 3. Authentication
- Short-lived access tokens (15-60 min)
- Store tokens in HttpOnly cookies, not localStorage
- Implement proper session management
- Use OAuth 2.0 / OpenID Connect for third-party auth

### 4. Security Headers
- `Strict-Transport-Security` (HSTS)
- `Content-Security-Policy` (CSP)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`

### 5. Dependency Security
- Run `npm audit` / `pip-audit` / `govulncheck` regularly
- Enable Dependabot or Renovate
- Review and update vulnerable dependencies promptly

## Quick Reference

### Secret Patterns to Detect
```
API_KEY=
SECRET=
PASSWORD=
PRIVATE_KEY=
aws_access_key_id
-----BEGIN.*PRIVATE KEY-----
```

### Secure vs Insecure Patterns

```python
# INSECURE: SQL injection
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# SECURE: Parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

```javascript
// INSECURE: XSS
element.innerHTML = userInput;

// SECURE: Safe assignment
element.textContent = userInput;
```

## Security Tools

| Tool | Language | Purpose |
|------|----------|---------|
| Semgrep | Multi | SAST, pattern matching |
| Bandit | Python | Security linter |
| Gosec | Go | Security linter |
| npm audit | Node.js | Dependency scanning |
| pip-audit | Python | Dependency scanning |
| govulncheck | Go | Dependency scanning |

## References

See `references/` directory for detailed documentation:
- `security-research.md` - Comprehensive security patterns and tools
