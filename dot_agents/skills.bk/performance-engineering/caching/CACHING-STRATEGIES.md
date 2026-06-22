# Caching Strategies

## Overview

Comprehensive guide to implementing caching strategies across application layers (browser, CDN, edge, application, database). Proper caching reduces latency, decreases load, improves scalability, and enhances user experience.

## Quick Reference

| Cache Type | TTL | Use Case | Invalidation |
|------------|-----|----------|--------------|
| Browser Cache | 1 hour - 1 year | Static assets | Versioned URLs |
| CDN Cache | 5 min - 1 day | Public content | Purge/Cache-busting |
| Edge Cache | 1 min - 1 hour | Dynamic content | Time-based |
| Application Cache | 1 min - 1 day | Computed results | Event-driven |
| Database Cache | 1 hour - 1 week | Query results | Data changes |
| Session Cache | Session lifetime | User data | Session expiry |

---

## Phase 1: HTTP Caching

### Cache-Control Headers

```http
# Public assets (CSS, JS, images)
Cache-Control: public, max-age=31536000, immutable

# HTML pages
Cache-Control: public, max-age=0, must-revalidate

# API responses (GET)
Cache-Control: public, max-age=300, s-maxage=600
Cache-Control: private, max-age=60, no-store  # User-specific data

# No caching
Cache-Control: no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
```

**Cache-Control Directives:**

| Directive | Meaning |
|-----------|---------|
| `public` | Cachable by any cache (browser, CDN) |
| `private` | Cachable only by browser |
| `max-age=X` | Cache for X seconds |
| `s-maxage=X` | Cache for X seconds (shared caches like CDN) |
| `must-revalidate` | Must check freshness before use |
| `no-cache` | Must verify before use |
| `no-store` | Never cache |
| `immutable` | Resource never changes |

### ETag and Last-Modified

```javascript
// Express - ETag generation
const crypto = require('crypto');

app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);

    // Generate ETag from user data
    const etag = crypto.createHash('md5')
        .update(JSON.stringify(user))
        .digest('hex');

    // Check If-None-Match header
    if (req.headers['if-none-match'] === etag) {
        return res.status(304).end();  // Not Modified
    }

    res.set('ETag', etag);
    res.set('Last-Modified', user.updated_at.toUTCString());
    res.json(user);
});

// FastAPI - ETag
from fastapi import FastAPI, Response
import hashlib
import json

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: int, response: Response):
    user = await User.get(user_id)

    # Generate ETag
    etag = hashlib.md5(json.dumps(user).encode()).hexdigest()

    response.headers["ETag"] = etag
    response.headers["Last-Modified"] = user.updated_at.strftime("%a, %d %b %Y %H:%M:%S GMT")

    return user
```

---

## Phase 2: Application-Level Caching

### In-Memory Caching (Redis/Memcached)

#### Redis Caching

```javascript
// Node.js with ioredis
const Redis = require('ioredis');
const redis = new Redis();

// Cache middleware
const cacheMiddleware = (ttl = 60) => {
    return async (req, res, next) => {
        const key = `cache:${req.method}:${req.originalUrl}`;

        // Check cache
        const cached = await redis.get(key);
        if (cached) {
            return res.json(JSON.parse(cached));
        }

        // Store original send method
        const originalSend = res.json.bind(res);
        res.json = (data) => {
            // Cache response
            redis.setex(key, ttl, JSON.stringify(data));
            return originalSend(data);
        };

        next();
    };
};

// Usage
app.get('/api/users', cacheMiddleware(300), async (req, res) => {
    const users = await User.findAll();
    res.json(users);
});

// Manual caching
app.get('/api/users/:id', async (req, res) => {
    const key = `user:${req.params.id}`;

    // Check cache
    const cached = await redis.get(key);
    if (cached) {
        return res.json(JSON.parse(cached));
    }

    // Fetch from DB
    const user = await User.findById(req.params.id);

    // Cache for 1 hour
    await redis.setex(key, 3600, JSON.stringify(user));

    res.json(user);
});
```

```python
# FastAPI with Redis
from fastapi import FastAPI
import redis
import json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)
app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    key = f"user:{user_id}"

    # Check cache
    cached = r.get(key)
    if cached:
        return json.loads(cached)

    # Fetch from DB
    user = await User.get(user_id)

    # Cache for 1 hour
    r.setex(key, 3600, json.dumps(user))

    return user
```

### Memcached Caching

```php
// Laravel with Memcached
use Illuminate\Support\Facades\Cache;

// Cache with expiration
$users = Cache::remember('users', 3600, function () {
    return User::all();
});

// Cache forever (manual invalidation)
$users = Cache::rememberForever('users', function () {
    return User::all();
});

// Cache with tags (for grouped invalidation)
$users = Cache::tags(['users'])->remember('users:all', 3600, function () {
    return User::all();
});

// Invalidate by tag
Cache::tags(['users'])->flush();
```

### In-Process Caching

```javascript
// Node.js with node-cache
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 300, checkperiod: 120 });

// Set cache
cache.set('users', users, 600);  // 10 minutes

// Get cache
const cached = cache.get('users');
if (cached) {
    return res.json(cached);
}

// Delete cache
cache.del('users');

// Flush all
cache.flushAll();
```

---

## Phase 3: Database Query Caching

### Laravel Query Cache

```php
// Cache query results
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

$users = Cache::remember('users:active', 3600, function () {
    return DB::table('users')->where('active', true)->get();
});

// Cache complex queries
$stats = Cache::remember('stats:daily', 3600, function () {
    return DB::select("
        SELECT
            DATE(created_at) as date,
            COUNT(*) as count
        FROM users
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(created_at)
        ORDER BY date DESC
    ");
});

// Cache with model events (auto-invalidation)
class User extends Model
{
    protected static function booted()
    {
        static::saved(function ($user) {
            Cache::forget('users:active');
            Cache::forget('stats:daily');
        });
    }
}
```

### Django Query Cache

```python
# Using Django cache framework
from django.core.cache import cache
from django.db.models import Count

def get_active_users():
    cache_key = 'users:active'

    # Check cache
    users = cache.get(cache_key)
    if users:
        return list(users)

    # Fetch from DB
    users = User.objects.filter(active=True)

    # Cache for 1 hour
    cache.set(cache_key, users, 3600)

    return list(users)

def get_daily_stats():
    cache_key = 'stats:daily'

    stats = cache.get(cache_key)
    if stats:
        return stats

    # Complex query
    from django.db.models import Count
    from django.db.models.functions import TruncDate

    stats = User.objects.filter(
        created_at__gte=timezone.now() - timedelta(days=30)
    ).annotate(
        date=TruncDate('created_at')
    ).values('date').annotate(
        count=Count('id')
    ).order_by('-date')

    cache.set(cache_key, stats, 3600)
    return stats
```

---

## Phase 4: Cache Invalidation Strategies

### Time-Based Expiration

```javascript
// Simple TTL-based caching
await redis.setex('key', 3600, 'value');  // Expires in 1 hour

// Sliding expiration (reset TTL on access)
async function getWithSlidingExpiration(key, ttl, factory) {
    let value = await redis.get(key);
    if (value) {
        // Reset TTL
        await redis.expire(key, ttl);
        return JSON.parse(value);
    }

    value = await factory();
    await redis.setex(key, ttl, JSON.stringify(value));
    return value;
}
```

### Event-Based Invalidation

```php
// Laravel - Invalidate cache on model changes
class User extends Model
{
    protected static function booted()
    {
        static::saved(function ($user) {
            Cache::forget("user:{$user->id}");
            Cache::tags(['users'])->flush();
        });

        static::deleted(function ($user) {
            Cache::forget("user:{$user->id}");
            Cache::tags(['users'])->flush();
        });
    }
}
```

```javascript
// Express - Event-driven invalidation
const EventEmitter = require('events');
const cacheEvents = new EventEmitter();

// Invalidate cache on user update
cacheEvents.on('user:updated', (userId) => {
    redis.del(`user:${userId}`);
});

// Trigger event when updating user
app.put('/api/users/:id', async (req, res) => {
    const user = await User.update(req.params.id, req.body);
    cacheEvents.emit('user:updated', req.params.id);
    res.json(user);
});
```

### Version-Based Caching

```javascript
// Add version to cache key
async function getCachedUsers() {
    const version = await redis.get('users:version') || 0;
    const key = `users:v${version}`;

    let users = await redis.get(key);
    if (users) {
        return JSON.parse(users);
    }

    users = await User.findAll();
    await redis.set(key, JSON.stringify(users), 'EX', 3600);
    return users;
}

// Invalidate by incrementing version
async function invalidateUsersCache() {
    await redis.incr('users:version');
}
```

### Cache Busting

```html
<!-- Versioned URLs for static assets -->
<link rel="stylesheet" href="/css/style.css?v=1.2.3">
<script src="/js/app.js?v=1.2.3"></script>

<!-- Or use hash-based versioning -->
<link rel="stylesheet" href="/css/style.a1b2c3d4.css">
<script src="/js/app.e5f6g7h8.js"></script>
```

```javascript
// Express - Static file cache busting
const express = require('express');
const app = express();

app.use('/static', express.static('public', {
    maxAge: '1y',
    etag: true,
    lastModified: true,
    setHeaders: (res, path) => {
        // Add version hash to filename
        const hash = getHashOfFile(path);
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    }
}));
```

---

## Phase 5: Caching Patterns

### Cache-Aside Pattern (Lazy Loading)

```javascript
async function getFromCacheOrDB(key, factory, ttl = 3600) {
    // Check cache
    const cached = await redis.get(key);
    if (cached) {
        return JSON.parse(cached);
    }

    // Cache miss - load from DB
    const data = await factory();

    // Populate cache
    await redis.setex(key, ttl, JSON.stringify(data));

    return data;
}

// Usage
const user = await getFromCacheOrDB(
    `user:${userId}`,
    () => User.findById(userId),
    3600
);
```

### Write-Through Pattern

```javascript
async function setUserWithCache(userId, userData) {
    // Write to DB
    const user = await User.update(userId, userData);

    // Write to cache
    await redis.setex(`user:${userId}`, 3600, JSON.stringify(user));

    return user;
}
```

### Write-Behind Pattern (Write-Back)

```javascript
const writeQueue = [];

async function setUserWriteBehind(userId, userData) {
    // Update cache immediately
    await redis.setex(`user:${userId}`, 3600, JSON.stringify(userData));

    // Queue for DB write
    writeQueue.push({ userId, userData });

    // Process queue asynchronously
    processWriteQueue();
}

async function processWriteQueue() {
    while (writeQueue.length > 0) {
        const { userId, userData } = writeQueue.shift();
        await User.update(userId, userData);
    }
}
```

### Read-Through Pattern

```javascript
class CacheWithReadThrough {
    constructor(redis) {
        this.redis = redis;
    }

    async get(key, factory, ttl = 3600) {
        let value = await this.redis.get(key);

        if (!value) {
            // Cache miss - use factory to load
            value = await factory(key);

            // Populate cache
            await this.redis.setex(key, ttl, JSON.stringify(value));
        } else {
            value = JSON.parse(value);
        }

        return value;
    }

    async set(key, value, ttl = 3600) {
        await this.redis.setex(key, ttl, JSON.stringify(value));
    }

    async del(key) {
        await this.redis.del(key);
    }
}

// Usage
const cache = new CacheWithReadThrough(redis);
const user = await cache.get(
    `user:${userId}`,
    () => User.findById(userId),
    3600
);
```

---

## Phase 6: Cache Keys Design

### Key Naming Conventions

```javascript
// Good cache key design

// 1. Namespaced keys
'user:123'
'users:active'
'products:featured'

// 2. Hierarchical keys
'category:electronics:products'
'user:123:orders'
'stats:daily:2025-01-15'

// 3. Versioned keys
'users:v2:active'
'api:v3:users:123'

// 4. Hash tags for Redis clustering (same hash slot)
'{user:123}:profile'
'{user:123}:preferences'
'{user:123}:settings'
```

### Key Length Considerations

```javascript
// Bad - Too long
'users_with_status_active_and_role_admin_sorted_by_name_desc_with_pagination_page_2_limit_20'

// Good - Concise but clear
'users:active:admin:page:2'
```

---

## Phase 7: Cache Warming

### Proactive Cache Population

```javascript
// Warm cache on startup
async function warmCache() {
    console.log('Warming cache...');

    // Pre-load frequently accessed data
    const activeUsers = await User.findAllActive();
    await redis.setex('users:active', 3600, JSON.stringify(activeUsers));

    const featuredProducts = await Product.findFeatured();
    await redis.setex('products:featured', 3600, JSON.stringify(featuredProducts));

    console.log('Cache warmed!');
}

// Call on startup
warmCache();
```

### Scheduled Cache Warming

```javascript
// Warm cache periodically
const cron = require('node-cron');

cron.schedule('0 */30 * * * *', async () => {
    console.log('Scheduled cache warming...');
    await warmCache();
});
```

---

## Phase 8: Cache Monitoring

### Cache Hit/Miss Tracking

```javascript
let cacheHits = 0;
let cacheMisses = 0;

async function getCached(key, factory, ttl = 3600) {
    const cached = await redis.get(key);

    if (cached) {
        cacheHits++;
        return JSON.parse(cached);
    }

    cacheMisses++;
    const data = await factory();
    await redis.setex(key, ttl, JSON.stringify(data));
    return data;
}

// Get cache statistics
function getCacheStats() {
    const total = cacheHits + cacheMisses;
    const hitRate = total > 0 ? (cacheHits / total * 100).toFixed(2) : 0;

    return {
        hits: cacheHits,
        misses: cacheMisses,
        total,
        hitRate: `${hitRate}%`
    };
}

// Log stats periodically
setInterval(() => {
    const stats = getCacheStats();
    console.log('Cache Stats:', stats);
}, 60000);  // Every minute
```

### Cache Size Monitoring

```javascript
// Redis memory usage
async function getCacheMemoryUsage() {
    const info = await redis.info('memory');

    return {
        used_memory: info.used_memory_human,
        used_memory_peak: info.used_memory_peak_human,
        used_memory_rss: info.used_memory_rss_human
    };
}
```

---

## Phase 9: Cache Security

### Cache Poisoning Prevention

```javascript
// Validate data before caching
async function setCached(key, data, ttl = 3600) {
    // Validate data
    if (!isValidData(data)) {
        throw new Error('Invalid data for caching');
    }

    // Serialize safely
    const serialized = JSON.stringify(data);

    // Encrypt sensitive data
    const encrypted = encrypt(serialized);

    await redis.setex(key, ttl, encrypted);
}

function isValidData(data) {
    // Check for unexpected keys
    const expectedKeys = ['id', 'name', 'email'];
    const actualKeys = Object.keys(data);

    return expectedKeys.every(key => actualKeys.includes(key));
}
```

### Sensitive Data Protection

```javascript
// Don't cache sensitive data
const BLACKLISTED_KEYS = ['password', 'token', 'secret', 'api_key'];

function sanitizeForCache(data) {
    const sanitized = { ...data };

    BLACKLISTED_KEYS.forEach(key => {
        delete sanitized[key];
    });

    return sanitized;
}

// Usage
const userData = await User.findById(userId);
const safeData = sanitizeForCache(userData);
await redis.setex(`user:${userId}`, 3600, JSON.stringify(safeData));
```

---

## Phase 10: Caching Anti-Patterns

### ❌ Don't Cache Everything

```javascript
// Bad - Caching everything
app.get('*', cacheMiddleware(), async (req, res) => {
    // Even POST requests get cached!
});

// Good - Cache only GET requests
app.get('/api/users', cacheMiddleware(), async (req, res) => {
    // Cache GET requests
});

app.post('/api/users', async (req, res) => {
    // Don't cache POST requests
});
```

### ❌ Don't Cache Large Objects

```javascript
// Bad - Caching large response
const largeData = await fetchDataWith10000Records();
await redis.set('large-data', JSON.stringify(largeData));

// Good - Cache only needed fields
const summary = await fetchDataSummary();
await redis.set('data-summary', JSON.stringify(summary));
```

### ❌ Don't Ignore Cache Invalidation

```javascript
// Bad - Cache never invalidated
const user = await getCached(`user:${userId}`, () => User.findById(userId));

// Good - Invalidate on updates
app.put('/api/users/:id', async (req, res) => {
    const user = await User.update(userId, req.body);
    await redis.del(`user:${userId}`);  // Invalidate
    res.json(user);
});
```

### ❌ Don't Have Long TTLs for Dynamic Data

```javascript
// Bad - Long TTL for user profile (changes frequently)
await redis.setex(`user:${userId}`, 86400, userData);  // 24 hours

// Good - Short TTL for dynamic data
await redis.setex(`user:${userId}`, 300, userData);  // 5 minutes
```

---

## Summary

Caching strategies involve:
1. **HTTP caching** (Cache-Control, ETag, Last-Modified)
2. **Application caching** (Redis, Memcached, in-memory)
3. **Database caching** (query result caching)
4. **Invalidation strategies** (time-based, event-based, version-based)
5. **Caching patterns** (cache-aside, write-through, write-behind, read-through)
6. **Key design** (naming, length, versioning)
7. **Cache warming** (proactive, scheduled)
8. **Monitoring** (hit/miss rates, memory usage)
9. **Security** (poisoning prevention, sensitive data)
10. **Anti-patterns** (over-caching, long TTLs, missing invalidation)

Use this guide to implement comprehensive caching across application layers.
