---
name: bosun-golang
description: Go language best practices and idioms. Use when writing, reviewing, or debugging Go code. Provides effective Go patterns, error handling, concurrency, and testing guidance.
tags: [go, golang, concurrency, testing, error-handling]
---

# Bosun Go Skill

Go language knowledge base for idiomatic Go development.

## When to Use

- Writing new Go code
- Reviewing Go code for best practices
- Debugging Go applications
- Setting up Go project structure
- Implementing concurrency patterns

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Effective Go Principles

### Error Handling

```go
// GOOD: Check errors immediately
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doSomething failed: %w", err)
}

// BAD: Ignoring errors
result, _ := doSomething()
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Package | lowercase, short | `http`, `json` |
| Exported | PascalCase | `UserService` |
| Unexported | camelCase | `getUserByID` |
| Interfaces | -er suffix | `Reader`, `Writer` |
| Acronyms | ALL CAPS | `HTTPServer`, `userID` |

### Interface Design

```go
// GOOD: Small, focused interfaces
type Reader interface {
    Read(p []byte) (n int, err error)
}

// BAD: Large interfaces
type FileSystem interface {
    Read() // ...20 more methods
}
```

### Concurrency Patterns

```go
// Worker pool pattern
func worker(jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        results <- process(job)
    }
}

// Context for cancellation
func doWork(ctx context.Context) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    case result := <-work():
        return nil
    }
}
```

## Project Structure

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── service/
│   └── repository/
├── pkg/           # Public libraries
├── go.mod
└── go.sum
```

## Testing

```go
// Table-driven tests
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| go fmt | Format code | `go fmt ./...` |
| go vet | Static analysis | `go vet ./...` |
| golangci-lint | Linting | `golangci-lint run` |
| go test | Testing | `go test -race ./...` |
| govulncheck | Security | `govulncheck ./...` |

## References

See `references/` directory for detailed documentation:
- `golang-research.md` - Comprehensive Go patterns
