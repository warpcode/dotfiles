# Caching Strategies & Mitigation Patterns

Diagnostic guide and implementation patterns for HTTP caching, application cache topology, key management, and stampede prevention.

---

## 1. HTTP Caching Directives & Conditional Requests

### Cache-Control Directives

| Directive | Scope | Behavior |
| :--- | :--- | :--- |
| `max-age=<seconds>` | Browser & Shared | Maximum time in seconds a response is considered fresh. |
| `s-maxage=<seconds>` | Shared (CDN / Proxy) | Overrides `max-age` for shared caches (CDNs, reverse proxies). |
| `public` | Shared & Browser | Response may be cached by any cache (even with HTTP auth). |
| `private` | Browser only | Response is intended for a single user; shared caches must not store it. |
| `no-cache` | All caches | Forces validation with origin server (`ETag`/`If-None-Match`) before serving. |
| `no-store` | All caches | Caches must not store any part of the request or response (use for sensitive data). |
| `must-revalidate` | All caches | Stale responses must not be served without server revalidation. |
| `stale-while-revalidate=<seconds>` | All caches | Serves stale content immediately while asynchronously fetching an update. |
| `immutable` | All caches | Indicates the response body will never change (ideal for hashed assets). |

### Recommended Header Configurations

```http
# Static hashed assets (immutable forever)
Cache-Control: public, max-age=31536000, immutable

# Dynamic API responses with background revalidation
Cache-Control: public, max-age=60, s-maxage=300, stale-while-revalidate=60

# Authenticated user endpoints (private, revalidate)
Cache-Control: private, no-cache, must-revalidate

# Sensitive financial or personal data
Cache-Control: no-store, no-cache, must-revalidate, max-age=0
Pragma: no-cache
```

### ETags & Conditional Requests (304 Not Modified)

ETags enable conditional HTTP validation (`If-None-Match`), avoiding payload re-transmission when data has not changed:

```http
# Initial Request:
GET /api/v1/projects/42 HTTP/1.1
Host: api.example.com

# Server Response:
HTTP/1.1 200 OK
ETag: W/"d41d8cd98f00b204e9800998ecf8427e"
Cache-Control: public, no-cache

# Subsequent Conditional Request:
GET /api/v1/projects/42 HTTP/1.1
Host: api.example.com
If-None-Match: W/"d41d8cd98f00b204e9800998ecf8427e"

# Server Response (Unmodified):
HTTP/1.1 304 Not Modified
ETag: W/"d41d8cd98f00b204e9800998ecf8427e"
```

---

## 2. Application Caching Topologies & Patterns

### 1. Cache-Aside (Lazy Loading)
The application reads from the cache first; on a cache miss, it loads data from the database, writes it to the cache, and returns it.

```
App ---> [Cache] (Hit: Return data)
  |
  +---> (Miss) ---> [Database] ---> Write [Cache] ---> Return data
```
- **Pros**: Resilient to cache failure; stores only actively requested data.
- **Cons**: Cache miss penalty on cold starts; potential data staleness if writes bypass cache.

### 2. Write-Through
The application writes data to the cache and the backing database simultaneously and synchronously.

```
App ---> [Cache] + [Database] (Synchronous update)
```
- **Pros**: Data in cache is never stale; reads are consistently fast.
- **Cons**: Higher write latency; caches unused data unless paired with eviction/TTL policies.

### 3. Write-Behind (Write-Back)
The application writes data directly to the cache, which acknowledges immediately and asynchronously flushes batches to the database.

```
App ---> [Cache] (Immediate Ack)
             |
      (Async Batch) ---> [Database]
```
- **Pros**: Ultra-low write latency; absorbs high-throughput write bursts.
- **Cons**: Risk of data loss if cache nodes crash before draining dirty data to disk/database.

### 4. Refresh-Ahead (Proactive Refresh)
The caching tier or background worker predicts or tracks expiring keys and asynchronously reloads them before TTL expiration.

- **Pros**: Eliminates cache miss latency spikes on hot keys.
- **Cons**: Inaccurate predictions waste compute/memory on rarely accessed keys.

---

## 3. Cache Hygiene & Management

### Key Namespacing & Versioning
Structure keys hierarchically with explicit version prefixes to simplify schema migrations and mass invalidations:

```text
Format:  <env>:<service>:<version>:<entity>:<id>:<variant>
Example: prod:catalog:v2:product:9841:pricing
```

- When changing the cached payload schema, bump the version segment (`v1` -> `v2`) instead of running expensive wildcard deletes (`KEYS *`).

### Serialization Hygiene
- **Never serialize raw ORM entity models** with active connection proxies, circular references, or heavy lazy-loading state.
- **Use compact, fast serialization formats**: Prefer JSON, MessagePack, or Protocol Buffers over language-native serialization (e.g. PHP `serialize()`, Python `pickle`) to avoid security risks and payload bloat.
- **Strip unused fields**: Cache only the projected fields required by the consumer.

### TTL Jittering
When caching large sets of records (e.g. during a batch job or bulk warm-up), assigning identical TTLs causes synchronized expiration waves that hammer the database.

Apply random jitter to distribute expirations across a time window:

```python
import random

def get_jittered_ttl(base_ttl_seconds: int, jitter_ratio: float = 0.15) -> int:
    """Add +/- jitter_ratio variance to base TTL."""
    delta = int(base_ttl_seconds * jitter_ratio)
    return base_ttl_seconds + random.randint(-delta, delta)

# Base TTL 3600s with 15% jitter yields 3060s - 4140s
ttl = get_jittered_ttl(3600, jitter_ratio=0.15)
```

---

## 4. Cache Stampede & Thundering Herd Mitigation

A cache stampede occurs when a high-traffic key expires, causing hundreds of concurrent requests to experience a cache miss simultaneously and hammer the database.

### Mitigation 1: Distributed Mutex Locking (Single-Flight)
Use a distributed lock (e.g. Redis `SET key val NX EX`) so only one process recomputes the cache while other requests wait or receive stale data.

```python
import time

def get_with_lock(redis_client, key, fetch_fn, ttl=300, lock_timeout=5):
    val = redis_client.get(key)
    if val is not None:
        return val

    lock_key = f"lock:{key}"
    # Acquire lock with non-blocking NX
    if redis_client.set(lock_key, "1", nx=True, ex=lock_timeout):
        try:
            val = fetch_fn()
            redis_client.set(key, val, ex=ttl)
            return val
        finally:
            redis_client.delete(lock_key)
    else:
        # Sleep briefly and retry reading from cache
        time.sleep(0.05)
        return redis_client.get(key) or fetch_fn()
```

### Mitigation 2: Probabilistic Early Expiration (XFetch Algorithm)
Recompute the cache entry before it expires with increasing probability as expiration nears.

Formula:
`currentTime - (beta * delta * ln(random())) > expiry`
- `delta`: Compute time to generate the value.
- `beta`: Aggressiveness factor (> 0, typically 1.0).

```python
import math
import random
import time

def should_recompute_early(expiry_timestamp: float, compute_delta_sec: float, beta: float = 1.0) -> bool:
    """XFetch probabilistic early expiration check."""
    now = time.time()
    random_val = random.random()
    if random_val == 0:
        return True
    return (now - (beta * compute_delta_sec * math.log(random_val))) > expiry_timestamp
```
