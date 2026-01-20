---
name: bosun-performance
description: Performance optimization patterns and profiling guidance. Use when analyzing bottlenecks, optimizing algorithms, improving database queries, reducing bundle sizes, or diagnosing memory issues. Provides patterns for backend, frontend, and database performance.
tags: [performance, optimization, profiling, algorithms, database, caching, memory]
---

# Bosun Performance Skill

Performance knowledge base for optimization, profiling, and efficiency analysis.

## When to Use

- Analyzing performance bottlenecks
- Optimizing algorithm complexity
- Improving database query performance
- Reducing frontend bundle sizes
- Diagnosing memory leaks
- Implementing caching strategies
- Profiling CPU/memory usage

## When NOT to Use

- Security vulnerabilities (use bosun-security)
- Test coverage issues (use bosun-testing)
- General architecture review (use bosun-architect)

## Performance Hierarchy

Focus optimization efforts in this order (highest impact first):

```
1. Architecture    - Wrong design = can't optimize later
2. Algorithms      - O(n²) to O(n) = 1000x improvement
3. Database        - Missing index = table scans
4. I/O             - Network, disk, blocking calls
5. Memory          - Leaks, excessive allocation
6. Micro           - Loop unrolling, etc. (rarely needed)
```

## Algorithm Complexity

### Big O Quick Reference
| Complexity | Name | Example | 10 items | 1M items |
|------------|------|---------|----------|----------|
| O(1) | Constant | HashMap lookup | instant | instant |
| O(log n) | Logarithmic | Binary search | instant | instant |
| O(n) | Linear | Array scan | instant | 1 second |
| O(n log n) | Linearithmic | Good sorts | instant | 20 seconds |
| O(n²) | Quadratic | Nested loops | instant | 12 days |
| O(2ⁿ) | Exponential | Naive recursion | instant | heat death |

### Common Optimizations
```javascript
// BAD: O(n²) - nested array search
for (const user of users) {
  for (const order of orders) {
    if (order.userId === user.id) { /* ... */ }
  }
}

// GOOD: O(n) - build lookup map first
const ordersByUser = new Map();
for (const order of orders) {
  if (!ordersByUser.has(order.userId)) {
    ordersByUser.set(order.userId, []);
  }
  ordersByUser.get(order.userId).push(order);
}
for (const user of users) {
  const userOrders = ordersByUser.get(user.id) || [];
}
```

## Database Performance

### Query Optimization Checklist
1. **Index frequently queried columns** (WHERE, JOIN, ORDER BY)
2. **Avoid SELECT *** - fetch only needed columns
3. **Use EXPLAIN/ANALYZE** to understand query plans
4. **Batch operations** instead of row-by-row
5. **Paginate large results** with LIMIT/OFFSET or cursors

### N+1 Query Problem
```python
# BAD: N+1 queries (1 + N database calls)
users = User.query.all()  # 1 query
for user in users:
    orders = Order.query.filter_by(user_id=user.id).all()  # N queries

# GOOD: Eager loading (1-2 queries)
users = User.query.options(joinedload(User.orders)).all()

# Or batch loading
user_ids = [u.id for u in users]
orders = Order.query.filter(Order.user_id.in_(user_ids)).all()
```

### Index Strategy
```sql
-- Single column for equality lookups
CREATE INDEX idx_users_email ON users(email);

-- Composite for multi-column queries
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- Partial index for filtered queries
CREATE INDEX idx_active_users ON users(email) WHERE status = 'active';

-- Covering index (includes all needed columns)
CREATE INDEX idx_orders_cover ON orders(user_id, status) INCLUDE (total);
```

## Caching Strategy

### Cache Decision Matrix
| Access Pattern | Data Size | Change Frequency | Cache? |
|----------------|-----------|------------------|--------|
| Frequent | Small | Rarely | Yes, long TTL |
| Frequent | Large | Rarely | Yes, consider CDN |
| Frequent | Any | Often | Yes, short TTL + invalidation |
| Rare | Any | Any | Usually no |

### Caching Layers
```
Browser Cache   → HTTP caching headers
CDN             → Static assets, API responses
Application     → In-memory, Redis
Database        → Query cache, materialized views
```

### Cache Patterns
```javascript
// Read-through cache
async function getUser(id) {
  const cached = await cache.get(`user:${id}`);
  if (cached) return cached;

  const user = await db.users.findById(id);
  await cache.set(`user:${id}`, user, { ttl: 3600 });
  return user;
}

// Write-through cache
async function updateUser(id, data) {
  const user = await db.users.update(id, data);
  await cache.set(`user:${id}`, user, { ttl: 3600 });
  return user;
}

// Cache invalidation
async function deleteUser(id) {
  await db.users.delete(id);
  await cache.del(`user:${id}`);
  await cache.del(`user:${id}:*`);  // Related keys
}
```

## Frontend Performance

### Core Web Vitals Targets
| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| LCP (Largest Contentful Paint) | ≤2.5s | ≤4s | >4s |
| FID (First Input Delay) | ≤100ms | ≤300ms | >300ms |
| CLS (Cumulative Layout Shift) | ≤0.1 | ≤0.25 | >0.25 |

### Bundle Size Optimization
```javascript
// 1. Analyze bundle
npx webpack-bundle-analyzer

// 2. Code splitting
const Dashboard = lazy(() => import('./Dashboard'));

// 3. Tree shaking - use named imports
import { debounce } from 'lodash-es';  // Only debounce
// NOT: import _ from 'lodash';        // Everything

// 4. Replace heavy dependencies
// moment.js (300KB) → date-fns (30KB) or dayjs (2KB)
// lodash (70KB) → native methods or lodash-es with tree shaking
```

### Image Optimization
```html
<!-- Lazy loading -->
<img src="photo.jpg" loading="lazy" alt="...">

<!-- Responsive images -->
<img srcset="photo-320.jpg 320w,
             photo-640.jpg 640w,
             photo-1280.jpg 1280w"
     sizes="(max-width: 600px) 320px, 640px"
     src="photo-640.jpg" alt="...">

<!-- Modern formats with fallback -->
<picture>
  <source srcset="photo.avif" type="image/avif">
  <source srcset="photo.webp" type="image/webp">
  <img src="photo.jpg" alt="...">
</picture>
```

### React Performance
```javascript
// Memoize expensive computations
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);

// Memoize callbacks to prevent child re-renders
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

// Memoize components
const ExpensiveComponent = memo(({ data }) => {
  // Only re-renders if data changes
  return <div>{/* ... */}</div>;
});

// Virtualize long lists
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={400}
  itemCount={10000}
  itemSize={35}
>
  {({ index, style }) => <Row style={style} item={items[index]} />}
</FixedSizeList>
```

## Memory Management

### Memory Leak Patterns

```javascript
// LEAK: Event listener not removed
useEffect(() => {
  window.addEventListener('resize', handleResize);
  // Missing cleanup!
}, []);

// FIXED: Return cleanup function
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => window.removeEventListener('resize', handleResize);
}, []);
```

```javascript
// LEAK: Closure holding reference
function setupHandler() {
  const hugeData = loadHugeData();  // 100MB
  element.onclick = () => {
    console.log(hugeData.length);   // Keeps hugeData alive
  };
}

// FIXED: Only capture what's needed
function setupHandler() {
  const hugeData = loadHugeData();
  const length = hugeData.length;    // Extract needed value
  element.onclick = () => {
    console.log(length);             // hugeData can be GC'd
  };
}
```

```javascript
// LEAK: Growing cache without bounds
const cache = {};
function getData(key) {
  if (!cache[key]) {
    cache[key] = expensiveComputation(key);  // Grows forever
  }
  return cache[key];
}

// FIXED: Use LRU cache with max size
import LRU from 'lru-cache';
const cache = new LRU({ max: 500 });
```

## Profiling Tools

### Backend Profiling
```bash
# Node.js
node --inspect app.js          # Chrome DevTools
npx clinic doctor -- node app.js
npx 0x app.js                  # Flamegraph

# Python
python -m cProfile -o output.prof app.py
python -m memory_profiler app.py
py-spy record -o profile.svg -- python app.py

# Go
go test -cpuprofile cpu.prof -memprofile mem.prof -bench .
go tool pprof cpu.prof
```

### Database Profiling
```sql
-- PostgreSQL
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- MySQL
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
SET profiling = 1;
SHOW PROFILES;
```

### Frontend Profiling
```bash
# Lighthouse
npx lighthouse https://example.com --only-categories=performance

# Bundle analysis
npx webpack-bundle-analyzer dist/stats.json
npx source-map-explorer dist/main.js

# Performance API
performance.mark('start');
// ... operation
performance.mark('end');
performance.measure('operation', 'start', 'end');
```

## Quick Reference

### HTTP Caching Headers
```
Cache-Control: public, max-age=31536000  # Static assets (1 year)
Cache-Control: private, max-age=0        # User-specific, validate
Cache-Control: no-store                  # Never cache (sensitive)
ETag: "abc123"                           # Conditional requests
```

### Connection Pooling
```javascript
// Database connection pool
const pool = new Pool({
  max: 20,              // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});

// HTTP keep-alive
const agent = new http.Agent({
  keepAlive: true,
  maxSockets: 50
});
```

### Async Best Practices
```javascript
// BAD: Sequential when could be parallel
const user = await getUser(id);
const orders = await getOrders(id);
const reviews = await getReviews(id);

// GOOD: Parallel execution
const [user, orders, reviews] = await Promise.all([
  getUser(id),
  getOrders(id),
  getReviews(id)
]);
```

## Anti-Patterns to Flag

| Anti-Pattern | Impact | Fix |
|--------------|--------|-----|
| N+1 queries | O(n) DB calls | Eager loading, batching |
| SELECT * | Unnecessary data transfer | Select specific columns |
| Missing indexes | Full table scans | Add appropriate indexes |
| Synchronous I/O | Blocks event loop | Use async methods |
| No pagination | Memory exhaustion | Implement pagination |
| Unbounded cache | Memory leak | Use LRU or TTL |
| Re-renders | UI jank | memo, useMemo, useCallback |

## References

See `references/` directory for detailed documentation:
- `optimization-patterns.md` - Detailed optimization techniques
- `profiling-guides.md` - Tool-specific profiling guides
