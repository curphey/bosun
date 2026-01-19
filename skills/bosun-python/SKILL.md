---
name: bosun-python
description: Python best practices and patterns. Use when writing, reviewing, or debugging Python code. Provides PEP 8 guidance, type hints, testing with pytest, and async patterns.
tags: [python, pep8, pytest, typing, async]
---

# Bosun Python Skill

Python knowledge base for idiomatic Python development.

## When to Use

- Writing new Python code
- Reviewing Python for best practices
- Configuring linting (ruff, flake8, pylint)
- Setting up testing with pytest
- Working with async/await

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## PEP 8 Essentials

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Module | lowercase_underscore | `user_service.py` |
| Class | PascalCase | `UserService` |
| Function | lowercase_underscore | `get_user_by_id` |
| Constant | UPPERCASE | `MAX_RETRIES` |
| Private | _prefix | `_internal_method` |

### Type Hints

```python
# GOOD: Full type hints
def get_user(user_id: str) -> User | None:
    ...

def process_items(items: list[Item]) -> dict[str, int]:
    ...

# Generic types
from typing import TypeVar, Generic

T = TypeVar('T')

class Repository(Generic[T]):
    def get(self, id: str) -> T | None:
        ...
```

## Modern Python Patterns

### Dataclasses

```python
from dataclasses import dataclass

@dataclass
class User:
    id: str
    name: str
    email: str
    active: bool = True
```

### Context Managers

```python
# Using contextlib
from contextlib import contextmanager

@contextmanager
def managed_resource():
    resource = acquire_resource()
    try:
        yield resource
    finally:
        release_resource(resource)
```

### Async/Await

```python
import asyncio

async def fetch_users() -> list[User]:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

# Run multiple tasks
results = await asyncio.gather(
    fetch_users(),
    fetch_orders(),
)
```

## Testing with Pytest

```python
import pytest

# Fixtures
@pytest.fixture
def user():
    return User(id="1", name="Test", email="test@example.com")

# Parameterized tests
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
])
def test_double(input: int, expected: int):
    assert double(input) == expected

# Async tests
@pytest.mark.asyncio
async def test_fetch_user():
    user = await fetch_user("1")
    assert user.id == "1"
```

## Project Structure

```
myproject/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── models.py
│       └── services.py
├── tests/
│   ├── conftest.py
│   └── test_services.py
├── pyproject.toml
└── README.md
```

## pyproject.toml

```toml
[project]
name = "myproject"
version = "0.1.0"
requires-python = ">=3.11"

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| ruff | Linting + formatting | `ruff check . --fix` |
| mypy | Type checking | `mypy src/` |
| pytest | Testing | `pytest -v` |
| pip-audit | Security | `pip-audit` |
| bandit | Security linting | `bandit -r src/` |

## References

See `references/` directory for detailed documentation:
- `python-research.md` - Comprehensive Python patterns
