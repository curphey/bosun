---
name: bosun-java
description: Java language best practices and idioms. Use when writing, reviewing, or debugging Java code. Provides modern Java patterns, Spring Boot, testing, and architecture guidance.
tags: [java, spring, jvm, testing, enterprise]
---

# Bosun Java Skill

Java language knowledge base for enterprise Java development.

## When to Use

- Writing new Java code
- Reviewing Java code for best practices
- Working with Spring Boot applications
- Implementing design patterns
- Setting up Maven/Gradle projects

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Modern Java Practices (17+)

### Records (Immutable Data)

```java
// GOOD: Use records for data classes
public record User(String name, String email, int age) {}

// Use with builder pattern
public record Config(String host, int port, boolean ssl) {
    public static Builder builder() {
        return new Builder();
    }
}
```

### Pattern Matching

```java
// Switch expressions
String result = switch (status) {
    case ACTIVE -> "Active";
    case PENDING -> "Pending";
    case INACTIVE -> "Inactive";
};

// Pattern matching for instanceof
if (obj instanceof String s) {
    System.out.println(s.length());
}

// Sealed classes
public sealed interface Shape permits Circle, Rectangle, Triangle {}
```

### Optional Handling

```java
// GOOD: Chain operations
Optional<User> user = findUser(id);
String email = user
    .map(User::email)
    .orElse("unknown@example.com");

// GOOD: Throw on missing
User user = findUser(id)
    .orElseThrow(() -> new UserNotFoundException(id));

// BAD: isPresent/get pattern
if (optional.isPresent()) {
    return optional.get(); // Don't do this
}
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService` |
| Interfaces | PascalCase | `UserRepository` |
| Methods | camelCase | `getUserById` |
| Constants | SCREAMING_SNAKE | `MAX_CONNECTIONS` |
| Packages | lowercase | `com.example.service` |

## Project Structure (Maven)

```
myproject/
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/
│   │   │       ├── Application.java
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       ├── model/
│   │   │       └── config/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── logback.xml
│   └── test/
│       └── java/
│           └── com/example/
└── target/
```

## Spring Boot Patterns

### Controller Layer

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<User> getUser(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public User createUser(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }
}
```

### Service Layer

```java
@Service
@Transactional
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final EventPublisher eventPublisher;

    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    public User create(CreateUserRequest request) {
        User user = User.builder()
            .name(request.name())
            .email(request.email())
            .build();

        User saved = userRepository.save(user);
        eventPublisher.publish(new UserCreatedEvent(saved));
        return saved;
    }
}
```

### Exception Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(ResourceNotFoundException ex) {
        return new ErrorResponse(ex.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErrorResponse handleValidation(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .toList();
        return new ErrorResponse("Validation failed", errors);
    }
}
```

## Testing

### Unit Tests (JUnit 5)

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    @Test
    void findById_existingUser_returnsUser() {
        // Given
        User user = new User(1L, "John", "john@example.com");
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        // When
        Optional<User> result = userService.findById(1L);

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().name()).isEqualTo("John");
    }

    @Test
    void findById_nonExistingUser_returnsEmpty() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        Optional<User> result = userService.findById(99L);

        assertThat(result).isEmpty();
    }
}
```

### Integration Tests

```java
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class UserControllerIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @Autowired
    private MockMvc mockMvc;

    @Test
    void createUser_validRequest_returnsCreated() throws Exception {
        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "John", "email": "john@example.com"}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("John"));
    }
}
```

## Dependency Injection

```java
// GOOD: Constructor injection (preferred)
@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
}

// BAD: Field injection
@Service
public class OrderService {
    @Autowired // Don't do this
    private OrderRepository orderRepository;
}
```

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| Maven | Build | `mvn clean install` |
| Gradle | Build | `./gradlew build` |
| SpotBugs | Static analysis | `mvn spotbugs:check` |
| Checkstyle | Style check | `mvn checkstyle:check` |
| JaCoCo | Coverage | `mvn jacoco:report` |

## References

See `references/` directory for detailed documentation.
