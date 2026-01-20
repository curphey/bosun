---
name: bosun-javascript
description: JavaScript best practices and patterns. Use when writing, reviewing, or debugging JavaScript code. Provides ES6+ patterns, module systems, testing guidance, and Node.js/browser considerations.
tags: [javascript, es6, nodejs, eslint, testing, react, vue]
---

# Bosun JavaScript Skill

JavaScript knowledge base for modern JS development.

## When to Use

- Writing new JavaScript code
- Reviewing JavaScript for quality and patterns
- Working with ES6+ features
- Configuring ESLint and Prettier
- Setting up testing with Jest/Vitest/Mocha
- Working with Node.js or browser code

## When NOT to Use

- TypeScript projects (use bosun-typescript)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Module Systems

### ES Modules (Preferred)

```javascript
// Named exports
export const API_URL = 'https://api.example.com';
export function fetchUser(id) { ... }

// Default export
export default class UserService { ... }

// Imports
import UserService, { API_URL, fetchUser } from './user-service.js';
```

### CommonJS (Node.js Legacy)

```javascript
// Exports
module.exports = { fetchUser, API_URL };
// or
exports.fetchUser = fetchUser;

// Imports
const { fetchUser, API_URL } = require('./user-service');
```

### Package.json Configuration

```json
{
  "type": "module",  // Enable ES modules
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs"
    }
  }
}
```

## ES6+ Patterns

### Destructuring

```javascript
// Objects
const { name, email, role = 'user' } = user;

// Arrays
const [first, second, ...rest] = items;

// Function parameters
function createUser({ name, email, role = 'user' }) {
  return { id: generateId(), name, email, role };
}
```

### Spread and Rest

```javascript
// Shallow clone
const copy = { ...original };
const merged = { ...defaults, ...options };

// Array operations
const combined = [...arr1, ...arr2];
const [head, ...tail] = items;
```

### Optional Chaining and Nullish Coalescing

```javascript
// Optional chaining
const city = user?.address?.city;
const result = obj.method?.();

// Nullish coalescing (null/undefined only)
const name = user.name ?? 'Anonymous';

// Avoid || for defaults (falsy trap)
const count = data.count ?? 0;  // GOOD: 0 is preserved
const count = data.count || 0;  // BAD: 0 becomes 0 (works but misleading)
```

### Async/Await

```javascript
// Prefer async/await over .then() chains
async function fetchUsers() {
  try {
    const response = await fetch('/api/users');
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch users:', error);
    throw error;
  }
}

// Parallel execution
const [users, posts] = await Promise.all([
  fetchUsers(),
  fetchPosts()
]);
```

### Classes

```javascript
class UserService {
  #apiUrl;  // Private field

  constructor(apiUrl) {
    this.#apiUrl = apiUrl;
  }

  async getUser(id) {
    const response = await fetch(`${this.#apiUrl}/users/${id}`);
    return response.json();
  }

  static create(config) {
    return new UserService(config.apiUrl);
  }
}
```

## ESLint Configuration

```javascript
// eslint.config.js (Flat config - ESLint 9+)
import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    rules: {
      'no-unused-vars': 'error',
      'no-console': 'warn',
      'eqeqeq': ['error', 'always'],
      'curly': 'error',
      'prefer-const': 'error',
      'no-var': 'error',
    },
  },
];
```

```javascript
// .eslintrc.js (Legacy config)
module.exports = {
  env: {
    browser: true,
    node: true,
    es2022: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'no-unused-vars': 'error',
    'eqeqeq': ['error', 'always'],
    'prefer-const': 'error',
    'no-var': 'error',
  },
};
```

## Testing Patterns

```javascript
// Jest/Vitest
describe('UserService', () => {
  let service;

  beforeEach(() => {
    service = new UserService('https://api.example.com');
  });

  it('should fetch a user by id', async () => {
    const user = await service.getUser('123');

    expect(user).toEqual({
      id: '123',
      name: expect.any(String),
    });
  });

  it('should throw on network error', async () => {
    await expect(service.getUser('invalid'))
      .rejects.toThrow();
  });
});
```

## Error Handling

```javascript
// Custom errors
class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
  }
}

// Error handling pattern
async function processRequest(data) {
  try {
    validate(data);
    return await saveToDatabase(data);
  } catch (error) {
    if (error instanceof ValidationError) {
      return { error: error.message, field: error.field };
    }
    // Re-throw unexpected errors
    throw error;
  }
}
```

## Project Structure

```
src/
├── components/        # UI components (React/Vue)
├── lib/              # Shared utilities
├── services/         # API and business logic
├── hooks/            # Framework hooks
├── constants/        # Configuration constants
└── index.js          # Entry point
```

## Browser vs Node.js

| Feature | Browser | Node.js |
|---------|---------|---------|
| Modules | `<script type="module">` | `"type": "module"` in package.json |
| Globals | `window`, `document` | `process`, `global`, `__dirname` |
| APIs | DOM, Fetch, localStorage | fs, path, http, crypto |
| Environment | `import.meta.url` | `process.env`, `import.meta.url` |

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| ESLint | Linting | `eslint .` |
| Prettier | Formatting | `prettier --write .` |
| Jest/Vitest | Testing | `npm test` |
| npm audit | Security | `npm audit` |
| Node.js | Runtime | `node --experimental-vm-modules` |

## Common Pitfalls

### Avoid These

```javascript
// BAD: == allows type coercion
if (value == null) { }
// GOOD: === is strict
if (value === null || value === undefined) { }
// BETTER: nullish check
if (value == null) { }  // Only case where == is OK

// BAD: for...in on arrays
for (const i in array) { }
// GOOD: for...of for arrays
for (const item of array) { }

// BAD: modifying function arguments
function process(options) {
  options.processed = true;  // Mutates caller's object!
}
// GOOD: clone first
function process(options) {
  const opts = { ...options, processed: true };
}
```

## References

See `references/` directory for detailed documentation:
- `javascript-research.md` - Comprehensive JavaScript patterns
- `node-security.md` - Node.js security best practices
