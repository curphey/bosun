---
name: bosun-typescript
description: TypeScript best practices and patterns. Use when writing, reviewing, or debugging TypeScript code. Provides strict typing, ESLint configuration, testing patterns, and framework guidance.
tags: [typescript, javascript, eslint, testing, react, nodejs]
---

# Bosun TypeScript Skill

TypeScript knowledge base for type-safe JavaScript development.

## When to Use

- Writing new TypeScript code
- Reviewing TypeScript for type safety
- Configuring ESLint and Prettier
- Setting up testing with Jest/Vitest
- Working with React or Node.js

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Strict Mode Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

## Type Patterns

### Prefer Interfaces for Objects

```typescript
// GOOD: Interface for object shapes
interface User {
  id: string;
  name: string;
  email: string;
}

// Use type for unions, intersections
type Status = 'pending' | 'active' | 'archived';
type AdminUser = User & { permissions: string[] };
```

### Avoid `any`

```typescript
// BAD
function process(data: any) { ... }

// GOOD: Use unknown + type guards
function process(data: unknown) {
  if (isUser(data)) {
    // data is now typed as User
  }
}

function isUser(data: unknown): data is User {
  return typeof data === 'object' && data !== null && 'id' in data;
}
```

### Utility Types

```typescript
// Partial - all properties optional
type UpdateUser = Partial<User>;

// Pick - select properties
type UserPreview = Pick<User, 'id' | 'name'>;

// Omit - exclude properties
type CreateUser = Omit<User, 'id'>;

// Record - typed object
type UserMap = Record<string, User>;
```

## ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
  ],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
    '@typescript-eslint/no-unused-vars': 'error',
  },
};
```

## Testing Patterns

```typescript
// Jest/Vitest test
describe('UserService', () => {
  it('should create a user', async () => {
    const user = await userService.create({
      name: 'Test',
      email: 'test@example.com',
    });

    expect(user).toMatchObject({
      name: 'Test',
      email: 'test@example.com',
    });
    expect(user.id).toBeDefined();
  });
});
```

## Project Structure

```
src/
├── components/        # React components
├── hooks/            # Custom hooks
├── services/         # Business logic
├── types/            # Shared type definitions
├── utils/            # Helper functions
└── index.ts          # Entry point
```

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| tsc | Type checking | `tsc --noEmit` |
| ESLint | Linting | `eslint . --ext .ts,.tsx` |
| Prettier | Formatting | `prettier --write .` |
| Jest/Vitest | Testing | `npm test` |
| npm audit | Security | `npm audit` |

## References

See `references/` directory for detailed documentation:
- `typescript-research.md` - Comprehensive TypeScript patterns
