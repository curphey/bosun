---
name: bosun-csharp
description: C# language best practices and idioms. Use when writing, reviewing, or debugging C# code. Provides modern C# patterns, .NET Core, ASP.NET, testing, and LINQ guidance.
tags: [csharp, dotnet, aspnet, linq, testing]
---

# Bosun C# Skill

C# language knowledge base for modern .NET development.

## When to Use

- Writing new C# code
- Reviewing C# code for best practices
- Working with ASP.NET Core applications
- Implementing async patterns
- Setting up .NET projects

## When NOT to Use

- Other languages (use appropriate language skill)
- Security review (use bosun-security first)
- Architecture decisions (use bosun-architect)

## Modern C# Practices (10+)

### Records (Immutable Data)

```csharp
// GOOD: Use records for data transfer
public record User(string Name, string Email, int Age);

// Record with init-only properties
public record Config
{
    public required string Host { get; init; }
    public int Port { get; init; } = 8080;
    public bool UseSsl { get; init; }
}

// With expressions for immutable updates
var updated = user with { Email = "new@example.com" };
```

### Pattern Matching

```csharp
// Switch expressions
string GetStatusText(Status status) => status switch
{
    Status.Active => "Active",
    Status.Pending => "Pending",
    Status.Inactive => "Inactive",
    _ => throw new ArgumentException($"Unknown status: {status}")
};

// Property patterns
if (user is { Age: >= 18, IsVerified: true })
{
    // Adult verified user
}

// List patterns (C# 11)
int[] numbers = { 1, 2, 3 };
if (numbers is [1, 2, ..])
{
    // Starts with 1, 2
}
```

### Nullable Reference Types

```csharp
// Enable in project file: <Nullable>enable</Nullable>

// GOOD: Explicit nullability
public string? GetMiddleName(User user)
{
    return user.MiddleName; // Nullable return
}

// GOOD: Null-forgiving when you know better
string name = GetName()!; // ! tells compiler it's not null

// GOOD: Null-conditional operators
int? length = user?.Address?.Street?.Length;
string city = user?.Address?.City ?? "Unknown";
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserService` |
| Interfaces | IPascalCase | `IUserRepository` |
| Methods | PascalCase | `GetUserById` |
| Properties | PascalCase | `FirstName` |
| Private fields | _camelCase | `_userRepository` |
| Constants | PascalCase | `MaxConnections` |
| Namespaces | PascalCase | `MyApp.Services` |

## Project Structure

```
MyProject/
├── MyProject.sln
├── src/
│   ├── MyProject.Api/
│   │   ├── Controllers/
│   │   ├── Program.cs
│   │   └── MyProject.Api.csproj
│   ├── MyProject.Core/
│   │   ├── Entities/
│   │   ├── Interfaces/
│   │   └── Services/
│   └── MyProject.Infrastructure/
│       ├── Data/
│       └── Repositories/
├── tests/
│   ├── MyProject.UnitTests/
│   └── MyProject.IntegrationTests/
└── Directory.Build.props
```

## ASP.NET Core Patterns

### Controller Layer

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<User>> GetUser(int id)
    {
        var user = await _userService.GetByIdAsync(id);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<User>> CreateUser(CreateUserRequest request)
    {
        var user = await _userService.CreateAsync(request);
        return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
    }
}
```

### Minimal APIs

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

app.MapGet("/users/{id}", async (int id, IUserService service) =>
{
    var user = await service.GetByIdAsync(id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

app.MapPost("/users", async (CreateUserRequest request, IUserService service) =>
{
    var user = await service.CreateAsync(request);
    return Results.Created($"/users/{user.Id}", user);
});

app.Run();
```

### Dependency Injection

```csharp
// Program.cs / Startup.cs
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<ICacheService, RedisCacheService>();
builder.Services.AddTransient<IEmailSender, SmtpEmailSender>();

// GOOD: Constructor injection
public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<UserService> _logger;

    public UserService(IUserRepository userRepository, ILogger<UserService> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }
}
```

## Async/Await Patterns

```csharp
// GOOD: Async all the way
public async Task<User> GetUserAsync(int id)
{
    return await _repository.GetByIdAsync(id);
}

// GOOD: Parallel operations
public async Task<(User, List<Order>)> GetUserWithOrdersAsync(int userId)
{
    var userTask = _userRepository.GetByIdAsync(userId);
    var ordersTask = _orderRepository.GetByUserIdAsync(userId);

    await Task.WhenAll(userTask, ordersTask);

    return (userTask.Result, ordersTask.Result);
}

// BAD: .Result or .Wait() blocking
var user = GetUserAsync(id).Result; // Don't do this - causes deadlocks
```

## LINQ Best Practices

```csharp
// GOOD: Method syntax for complex queries
var result = users
    .Where(u => u.IsActive)
    .OrderBy(u => u.LastName)
    .ThenBy(u => u.FirstName)
    .Select(u => new UserDto(u.Id, u.FullName))
    .ToList();

// GOOD: Query syntax for joins
var query = from u in users
            join o in orders on u.Id equals o.UserId
            where o.Total > 100
            select new { u.Name, o.Total };

// GOOD: Use async versions for EF Core
var users = await _context.Users
    .Where(u => u.Age >= 18)
    .ToListAsync();

// BAD: Multiple enumerations
var filtered = users.Where(u => u.IsActive); // IEnumerable
var count = filtered.Count(); // First enumeration
var list = filtered.ToList(); // Second enumeration - BAD
```

## Testing

### Unit Tests (xUnit)

```csharp
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repositoryMock;
    private readonly UserService _sut;

    public UserServiceTests()
    {
        _repositoryMock = new Mock<IUserRepository>();
        _sut = new UserService(_repositoryMock.Object);
    }

    [Fact]
    public async Task GetByIdAsync_ExistingUser_ReturnsUser()
    {
        // Arrange
        var user = new User { Id = 1, Name = "John" };
        _repositoryMock.Setup(r => r.GetByIdAsync(1))
            .ReturnsAsync(user);

        // Act
        var result = await _sut.GetByIdAsync(1);

        // Assert
        Assert.NotNull(result);
        Assert.Equal("John", result.Name);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task GetByIdAsync_InvalidId_ThrowsArgumentException(int id)
    {
        await Assert.ThrowsAsync<ArgumentException>(
            () => _sut.GetByIdAsync(id));
    }
}
```

### Integration Tests

```csharp
public class UsersControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersControllerTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateUser_ValidRequest_ReturnsCreated()
    {
        var request = new { Name = "John", Email = "john@example.com" };
        var content = new StringContent(
            JsonSerializer.Serialize(request),
            Encoding.UTF8,
            "application/json");

        var response = await _client.PostAsync("/api/users", content);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
```

## Tools

| Tool | Purpose | Command |
|------|---------|---------|
| dotnet build | Build | `dotnet build` |
| dotnet test | Testing | `dotnet test` |
| dotnet format | Formatting | `dotnet format` |
| dotnet-outdated | Check updates | `dotnet outdated` |
| Roslyn Analyzers | Static analysis | Built-in |

## References

See `references/` directory for detailed documentation.
