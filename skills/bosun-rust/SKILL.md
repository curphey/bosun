---
name: bosun-rust
description: Rust language best practices and idioms. Use when writing, reviewing, or debugging Rust code. Provides ownership, lifetimes, error handling, and safety patterns.
tags: [rust, ownership, lifetimes, safety, concurrency]
---

# Bosun Rust Skill

Rust language knowledge base for safe, performant Rust development.

## When to Use

- Writing new Rust code
- Reviewing Rust code for best practices
- Understanding ownership and borrowing
- Implementing error handling patterns
- Working with async Rust

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Ownership and Borrowing

### The Three Rules

1. Each value has exactly one owner
2. When the owner goes out of scope, the value is dropped
3. You can have either one mutable reference OR many immutable references

```rust
// GOOD: Clear ownership
fn process(data: String) {
    println!("{}", data);
} // data dropped here

// GOOD: Borrowing for read access
fn analyze(data: &str) -> usize {
    data.len()
}

// GOOD: Mutable borrowing
fn modify(data: &mut Vec<i32>) {
    data.push(42);
}
```

### Common Patterns

```rust
// Clone when you need independent copies
let original = String::from("hello");
let copy = original.clone();

// Use references for temporary access
fn print_length(s: &str) {
    println!("Length: {}", s.len());
}

// Return owned values from functions
fn create_greeting(name: &str) -> String {
    format!("Hello, {}!", name)
}
```

## Error Handling

### Result and Option

```rust
// GOOD: Propagate errors with ?
fn read_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = toml::from_str(&content)?;
    Ok(config)
}

// GOOD: Handle Option explicitly
fn get_user(id: u64) -> Option<User> {
    users.get(&id).cloned()
}

// BAD: Unwrap in production code
let value = something.unwrap(); // Will panic!
```

### Custom Error Types

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Parse error: {0}")]
    Parse(#[from] serde_json::Error),

    #[error("Not found: {0}")]
    NotFound(String),
}
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Crates | snake_case | `my_crate` |
| Modules | snake_case | `file_utils` |
| Types | PascalCase | `UserService` |
| Functions | snake_case | `get_user_by_id` |
| Constants | SCREAMING_SNAKE | `MAX_CONNECTIONS` |
| Lifetimes | short lowercase | `'a`, `'de` |

## Project Structure

```
myproject/
├── Cargo.toml
├── Cargo.lock
├── src/
│   ├── lib.rs          # Library root
│   ├── main.rs         # Binary entry
│   ├── config.rs
│   └── utils/
│       ├── mod.rs
│       └── helpers.rs
├── tests/              # Integration tests
│   └── integration_test.rs
├── benches/            # Benchmarks
│   └── benchmark.rs
└── examples/
    └── basic.rs
```

## Testing

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_addition() {
        assert_eq!(add(2, 2), 4);
    }

    #[test]
    fn test_with_result() -> Result<(), Box<dyn std::error::Error>> {
        let result = parse_config("valid.toml")?;
        assert_eq!(result.name, "test");
        Ok(())
    }

    #[test]
    #[should_panic(expected = "division by zero")]
    fn test_panic() {
        divide(1, 0);
    }
}
```

## Async Rust

```rust
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let result = fetch_data("https://api.example.com").await?;
    Ok(())
}

async fn fetch_data(url: &str) -> Result<String, reqwest::Error> {
    let response = reqwest::get(url).await?;
    response.text().await
}
```

## Common Traits

| Trait | Purpose | When to Implement |
|-------|---------|-------------------|
| `Clone` | Deep copy | Types that need copying |
| `Debug` | Debug formatting | Almost always |
| `Default` | Default value | Types with sensible defaults |
| `PartialEq` | Equality comparison | Comparable types |
| `Serialize` | JSON/data serialization | Data structures |

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| cargo fmt | Format code | `cargo fmt` |
| cargo clippy | Linting | `cargo clippy -- -D warnings` |
| cargo test | Testing | `cargo test` |
| cargo audit | Security | `cargo audit` |
| cargo doc | Documentation | `cargo doc --open` |

## References

See `references/` directory for detailed documentation.
