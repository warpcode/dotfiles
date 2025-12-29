# Connection Pooling

## Overview

Comprehensive guide to implementing database and external service connection pooling across frameworks. Connection pooling reduces connection overhead, improves performance, and enables better resource utilization.

## Quick Reference

| Pool Type | Max Connections | Min Connections | Idle Timeout | Use Case |
|-----------|-----------------|------------------|---------------|----------|
| Database | 10-100 | 2-5 | 10-30 min | PostgreSQL, MySQL, MongoDB |
| Redis | 10-50 | 2-5 | 5 min | Redis connection pool |
| HTTP | 10-100 | 2-5 | 1 min | External API calls |
| gRPC | 10-50 | 2-5 | 1 min | Microservice communication |

---

## Phase 1: Database Connection Pooling

### PostgreSQL Connection Pooling

#### Node.js (pg)

```javascript
const { Pool } = require('pg');

// Create connection pool
const pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,

    // Pool configuration
    max: 20,              // Maximum pool size
    min: 2,               // Minimum pool size
    idleTimeoutMillis: 30000,  // 30 seconds idle timeout
    connectionTimeoutMillis: 2000,  // 2 seconds connect timeout

    // Connection lifetime (to prevent long-lived connections)
    maxUses: 7500,         // Max uses per connection
});

// Query using pool
async function getUser(userId) {
    const client = await pool.connect();

    try {
        const result = await client.query(
            'SELECT * FROM users WHERE id = $1',
            [userId]
        );
        return result.rows[0];
    } finally {
        client.release();  // Release back to pool
    }
}

// Or use pool.query (automatically gets/releases connection)
async function getUserSimple(userId) {
    const result = await pool.query(
        'SELECT * FROM users WHERE id = $1',
        [userId]
    );
    return result.rows[0];
}

// Transaction
async function createUserWithOrder(userData, orderData) {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const userResult = await client.query(
            'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id',
            [userData.name, userData.email]
        );

        const userId = userResult.rows[0].id;

        await client.query(
            'INSERT INTO orders (user_id, total) VALUES ($1, $2)',
            [userId, orderData.total]
        );

        await client.query('COMMIT');
        return userId;
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
}

// Monitor pool stats
setInterval(() => {
    console.log('Pool stats:', {
        totalCount: pool.totalCount,
        idleCount: pool.idleCount,
        waitingCount: pool.waitingCount
    });
}, 60000);

// Graceful shutdown
process.on('SIGINT', async () => {
    await pool.end();
    process.exit(0);
});
```

#### Python (psycopg2)

```python
import psycopg2
from psycopg2 import pool
from contextlib import contextmanager

# Create connection pool
connection_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=2,
    maxconn=20,
    host=os.getenv('DB_HOST'),
    port=os.getenv('DB_PORT', 5432),
    database=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    connect_timeout=2,
)

# Context manager for connection
@contextmanager
def get_connection():
    conn = connection_pool.getconn()
    try:
        yield conn
    finally:
        connection_pool.putconn(conn)

# Query with context manager
def get_user(user_id):
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                'SELECT * FROM users WHERE id = %s',
                (user_id,)
            )
            return cursor.fetchone()

# Transaction with context manager
def create_user_with_order(user_data, order_data):
    with get_connection() as conn:
        with conn.cursor() as cursor:
            try:
                conn.autocommit = False

                cursor.execute(
                    'INSERT INTO users (name, email) VALUES (%s, %s) RETURNING id',
                    (user_data['name'], user_data['email'])
                )
                user_id = cursor.fetchone()[0]

                cursor.execute(
                    'INSERT INTO orders (user_id, total) VALUES (%s, %s)',
                    (user_id, order_data['total'])
                )

                conn.commit()
                return user_id
            except Exception as e:
                conn.rollback()
                raise e

# Monitor pool stats
def print_pool_stats():
    print('Pool stats:', {
        'closed': connection_pool.closed,
        'minconn': connection_pool.minconn,
        'maxconn': connection_pool.maxconn,
    })

# Graceful shutdown
import atexit
atexit.register(lambda: connection_pool.closeall())
```

#### PHP (Laravel)

```php
// config/database.php

return [
    'default' => env('DB_CONNECTION', 'pgsql'),

    'connections' => [
        'pgsql' => [
            'driver' => 'pgsql',
            'url' => env('DATABASE_URL'),
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '5432'),
            'database' => env('DB_DATABASE', 'forge'),
            'username' => env('DB_USERNAME', 'forge'),
            'password' => env('DB_PASSWORD', ''),

            // Pool configuration
            'pool_max' => env('DB_POOL_MAX', 20),
            'pool_min' => env('DB_POOL_MIN', 2),
            'pool_idle_timeout' => env('DB_POOL_IDLE_TIMEOUT', 30),
            'pool_max_wait_time' => env('DB_POOL_MAX_WAIT_TIME', 2),
        ],
    ],
];

// Usage with Eloquent (automatic pooling)
$user = User::find($userId);

// Transaction with automatic connection management
DB::transaction(function () use ($userData, $orderData) {
    $user = User::create($userData);
    $user->orders()->create($orderData);
});
```

---

### MySQL Connection Pooling

#### Node.js (mysql2/promise)

```javascript
const mysql = require('mysql2/promise');

// Create connection pool
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,

    // Pool configuration
    connectionLimit: 20,
    waitForConnections: true,
    queueLimit: 0,  // Unlimited queue

    // Connection timeouts
    connectTimeout: 2000,  // 2 seconds
    acquireTimeout: 10000,  // 10 seconds to acquire from pool

    // Connection lifetime
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
});

// Query using pool
async function getUser(userId) {
    const [rows] = await pool.execute(
        'SELECT * FROM users WHERE id = ?',
        [userId]
    );
    return rows[0];
}

// Transaction
async function createUserWithOrder(userData, orderData) {
    const connection = await pool.getConnection();

    try {
        await connection.beginTransaction();

        const [userResult] = await connection.execute(
            'INSERT INTO users (name, email) VALUES (?, ?)',
            [userData.name, userData.email]
        );
        const userId = userResult.insertId;

        await connection.execute(
            'INSERT INTO orders (user_id, total) VALUES (?, ?)',
            [userId, orderData.total]
        );

        await connection.commit();
        return userId;
    } catch (error) {
        await connection.rollback();
        throw error;
    } finally {
        connection.release();
    }
}
```

#### Python (SQLAlchemy)

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from contextlib import contextmanager

# Create engine with pooling
engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}",
    pool_size=5,            # Number of connections to keep in pool
    max_overflow=10,       # Additional connections when pool is full
    pool_timeout=30,       # Seconds to wait for connection
    pool_recycle=3600,     # Recycle connections after 1 hour
    pool_pre_ping=True,    # Test connection before using
)

# Create session factory
Session = sessionmaker(bind=engine)

# Context manager for sessions
@contextmanager
def get_session():
    session = Session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

# Query
def get_user(user_id):
    with get_session() as session:
        return session.query(User).filter(User.id == user_id).first()

# Transaction
def create_user_with_order(user_data, order_data):
    with get_session() as session:
        user = User(**user_data)
        session.add(user)
        session.flush()  # Flush to get ID

        order = Order(user_id=user.id, **order_data)
        session.add(order)

        session.commit()
        return user.id
```

---

### MongoDB Connection Pooling

#### Node.js (Mongoose)

```javascript
const mongoose = require('mongoose');

// Connection options with pooling
const options = {
    // Connection pooling
    maxPoolSize: 20,       // Maximum connections
    minPoolSize: 2,        // Minimum connections
    maxIdleTimeMS: 30000,  // 30 seconds idle timeout

    // Connection timeouts
    socketTimeoutMS: 45000,  // Socket timeout
    serverSelectionTimeoutMS: 5000,  // Server selection timeout

    // Connection lifecycle
    connectTimeoutMS: 10000,  // 10 seconds connect timeout

    // Auto-reconnection
    retryWrites: true,
    retryReads: true,

    // Monitor connection events
    monitorCommands: true,
};

// Connect with pooling
mongoose.connect(process.env.MONGODB_URI, options);

// Monitor connection events
mongoose.connection.on('connected', () => {
    console.log('Connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
    console.error('MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
    console.log('Disconnected from MongoDB');
});

// Monitor pool stats
setInterval(() => {
    const pool = mongoose.connection.client;
    console.log('MongoDB pool stats:', {
        poolSize: pool.options.maxPoolSize,
        currentConnections: pool.topology.s.pool.totalConnectionCount,
        availableConnections: pool.topology.s.pool.availableConnectionCount,
    });
}, 60000);

// Graceful shutdown
process.on('SIGINT', async () => {
    await mongoose.connection.close();
    process.exit(0);
});
```

---

## Phase 2: Redis Connection Pooling

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

// Create connection pool
const redis = new Redis({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,

    // Pool configuration
    maxRetriesPerRequest: 3,
    enableReadyCheck: true,
    enableOfflineQueue: true,

    // Connection timeout
    connectTimeout: 10000,  // 10 seconds

    // Keep-alive
    keepAlive: 30000,  // 30 seconds

    // Connection pool size (per instance)
    family: 4,  // IPv4
});

// Cluster with pooling
const RedisCluster = require('ioredis');

const redisCluster = new Redis.Cluster([
    { host: 'redis-1', port: 6379 },
    { host: 'redis-2', port: 6379 },
    { host: 'redis-3', port: 6379 },
], {
    redisOptions: {
        maxRetriesPerRequest: 3,
        enableReadyCheck: true,
        connectTimeout: 10000,
        keepAlive: 30000,
    },
    // Cluster configuration
    scaleReads: 'slave',  // Read from slaves
    redisOptions: {
        // Connection pool per node
        maxRetriesPerRequest: 3,
        enableOfflineQueue: true,
    },
});
```

### Python (redis-py)

```python
import redis
from redis.connection import ConnectionPool

# Create connection pool
pool = ConnectionPool(
    host=os.getenv('REDIS_HOST'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD'),
    db=0,

    # Pool configuration
    max_connections=20,
    socket_timeout=2,
    socket_connect_timeout=2,
    socket_keepalive=True,
    socket_keepalive_options={},
)

# Create Redis client with pool
redis_client = redis.Redis(connection_pool=pool)

# Usage
def get_user_cache(user_id):
    return redis_client.get(f'user:{user_id}')

def set_user_cache(user_id, data, ttl=3600):
    redis_client.setex(f'user:{user_id}', ttl, data)

# Cluster with pooling
from redis.cluster import RedisCluster

redis_cluster = RedisCluster(
    host='redis-1',
    port=6379,

    # Connection pool per node
    max_connections=20,
    socket_timeout=2,
    socket_connect_timeout=2,
    skip_full_coverage_check=True,
)
```

---

## Phase 3: HTTP Connection Pooling

### Node.js (axios/http)

```javascript
const axios = require('axios');
const http = require('http');
const https = require('https');

// Create HTTP agent with pooling
const httpAgent = new http.Agent({
    keepAlive: true,
    maxSockets: 100,
    maxFreeSockets: 10,
    timeout: 30000,  // 30 seconds
    keepAliveTimeout: 30000,
});

const httpsAgent = new https.Agent({
    keepAlive: true,
    maxSockets: 100,
    maxFreeSockets: 10,
    timeout: 30000,
    keepAliveTimeout: 30000,
});

// Create axios instance with pooling
const apiClient = axios.create({
    baseURL: process.env.API_BASE_URL,
    httpAgent,
    httpsAgent,
    timeout: 30000,  // Request timeout
});

// Make request
async function getUser(userId) {
    const response = await apiClient.get(`/users/${userId}`);
    return response.data;
}

// Monitor pool stats
setInterval(() => {
    console.log('HTTP pool stats:', {
        httpRequests: httpAgent.requests,
        httpSockets: httpAgent.sockets,
        httpFreeSockets: httpAgent.freeSockets,
        httpsRequests: httpsAgent.requests,
        httpsSockets: httpsAgent.sockets,
        httpsFreeSockets: httpsAgent.freeSockets,
    });
}, 60000);

// Graceful shutdown
process.on('SIGINT', () => {
    httpAgent.destroy();
    httpsAgent.destroy();
    process.exit(0);
});
```

### Python (requests/urllib3)

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# Create session with connection pooling
session = requests.Session()

# Configure retry strategy
retry_strategy = Retry(
    total=3,
    backoff_factor=1,
    status_forcelist=[429, 500, 502, 503, 504],
)

# Configure connection pool
adapter = HTTPAdapter(
    max_retries=retry_strategy,
    pool_connections=10,
    pool_maxsize=100,
    pool_block=False,
)

# Mount adapter for HTTP and HTTPS
session.mount('http://', adapter)
session.mount('https://', adapter)

# Make request
def get_user(user_id):
    response = session.get(
        f'{API_BASE_URL}/users/{user_id}',
        timeout=30
    )
    return response.json()

# Close session (graceful shutdown)
def close_session():
    session.close()

import atexit
atexit.register(close_session)
```

---

## Phase 4: gRPC Connection Pooling

### Node.js

```javascript
const grpc = require('@grpc/grpc-js');

// Create channel with connection pooling
const client = new UserServiceClient(
    process.env.GRPC_SERVER_URL,
    grpc.credentials.createInsecure(),
    {
        // Channel arguments (pooling)
        'grpc.max_receive_message_length': -1,  // Unlimited
        'grpc.max_send_message_length': -1,  // Unlimited
        'grpc.keepalive_permit_without_calls': 1,
        'grpc.keepalive_time_ms': 30000,  // 30 seconds
        'grpc.keepalive_timeout_ms': 5000,  // 5 seconds
        'grpc.http2.min_time_between_pings_ms': 10000,
        'grpc.http2.max_pings_without_data': 0,
    }
);

// Make request
async function getUser(userId) {
    return new Promise((resolve, reject) => {
        client.GetUser({ id: userId }, (err, response) => {
            if (err) {
                reject(err);
            } else {
                resolve(response);
            }
        });
    });
}

// Close channel (graceful shutdown)
process.on('SIGINT', () => {
    client.close();
    process.exit(0);
});
```

### Python

```python
import grpc
from concurrent.futures import ThreadPoolExecutor

# Create channel with connection pooling
channel = grpc.insecure_channel(
    f'{GRPC_SERVER_HOST}:{GRPC_SERVER_PORT}',
    options=[
        ('grpc.max_receive_message_length', -1),
        ('grpc.max_send_message_length', -1),
        ('grpc.keepalive_permit_without_calls', 1),
        ('grpc.keepalive_time_ms', 30000),
        ('grpc.keepalive_timeout_ms', 5000),
    ]
)

# Create stub
stub = user_pb2_grpc.UserServiceStub(channel)

# Create thread pool for concurrent calls
executor = ThreadPoolExecutor(max_workers=10)

def get_user(user_id):
    request = user_pb2.GetUserRequest(id=user_id)
    return stub.GetUser(request)

# Close channel
import atexit
atexit.register(channel.close)
```

---

## Phase 5: Pool Configuration Strategies

### Pool Sizing Formula

```
Max Connections = (CPU Cores * 2) + Effective Disk Count
Min Connections = Max Connections / 4

For database-heavy workloads:
Max Connections = CPU Cores * (1 + (Waiting Time / Service Time))

Example (4 CPU cores, 50% waiting, 50% service):
Max = 4 * (1 + (0.5 / 0.5)) = 8 connections
Min = 8 / 4 = 2 connections
```

### Environment-Based Configuration

```javascript
// Dynamic pool sizing based on environment
const isProduction = process.env.NODE_ENV === 'production';
const isDevelopment = process.env.NODE_ENV === 'development';
const isTest = process.env.NODE_ENV === 'test';

const poolConfig = {
    production: { max: 20, min: 5, idleTimeout: 30000 },
    development: { max: 10, min: 2, idleTimeout: 60000 },
    test: { max: 5, min: 1, idleTimeout: 5000 },
};

const config = poolConfig[process.env.NODE_ENV] || poolConfig.development;

const pool = new Pool({
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    max: config.max,
    min: config.min,
    idleTimeoutMillis: config.idleTimeout,
});
```

---

## Phase 6: Pool Monitoring

### Connection Pool Metrics

```javascript
// PostgreSQL pool monitoring
function getPoolMetrics(pool) {
    return {
        totalCount: pool.totalCount,           // Total connections
        idleCount: pool.idleCount,              // Idle connections
        waitingCount: pool.waitingCount,        // Requests waiting
        utilization: ((pool.totalCount - pool.idleCount) / pool.totalCount * 100).toFixed(2) + '%',
    };
}

// Log metrics periodically
setInterval(() => {
    const metrics = getPoolMetrics(pool);
    console.log('Pool metrics:', metrics);

    // Alert if utilization is high
    if (metrics.utilization > 80) {
        console.warn('High pool utilization:', metrics);
    }
}, 60000);

// Track slow queries
async function queryWithTiming(sql, params) {
    const start = Date.now();
    const result = await pool.query(sql, params);
    const duration = Date.now() - start;

    if (duration > 1000) {
        console.warn('Slow query:', { sql, duration: `${duration}ms` });
    }

    return result;
}
```

### Health Check

```javascript
// Pool health check
async function checkPoolHealth(pool) {
    try {
        const client = await pool.connect();

        const result = await client.query('SELECT 1');
        client.release();

        return { healthy: true, message: 'Pool is healthy' };
    } catch (error) {
        return { healthy: false, error: error.message };
    }
}

// Health endpoint
app.get('/health', async (req, res) => {
    const health = await checkPoolHealth(pool);

    if (health.healthy) {
        res.status(200).json(health);
    } else {
        res.status(503).json(health);
    }
});
```

---

## Phase 7: Connection Pool Anti-Patterns

### ❌ Don't Create New Connections per Request

```javascript
// Bad - New connection per request
app.get('/users/:id', async (req, res) => {
    const client = new Client({ /* config */ });
    await client.connect();

    const user = await client.query('SELECT * FROM users WHERE id = $1', [req.params.id]);

    await client.end();  // Expensive!
    res.json(user);
});

// Good - Use connection pool
app.get('/users/:id', async (req, res) => {
    const user = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    res.json(user.rows[0]);
});
```

### ❌ Don't Forget to Release Connections

```javascript
// Bad - Connection leak
app.get('/users/:id', async (req, res) => {
    const client = await pool.connect();

    const user = await client.query('SELECT * FROM users WHERE id = $1', [req.params.id]);

    // Forgot to release!
    res.json(user.rows[0]);
});

// Good - Always release connection
app.get('/users/:id', async (req, res) => {
    const client = await pool.connect();

    try {
        const user = await client.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
        res.json(user.rows[0]);
    } finally {
        client.release();
    }
});
```

### ❌ Don't Set Pool Size Too High

```javascript
// Bad - Excessive pool size (resource exhaustion)
const pool = new Pool({
    max: 1000,  // Too many!
    min: 500,
});

// Good - Reasonable pool size
const pool = new Pool({
    max: 20,
    min: 5,
});
```

### ❌ Don't Ignore Connection Timeouts

```javascript
// Bad - No timeout (hanging connections)
const pool = new Pool({
    max: 20,
    // No connectionTimeout
});

// Good - Set connection timeout
const pool = new Pool({
    max: 20,
    connectionTimeoutMillis: 2000,  // 2 seconds
});
```

---

## Summary

Connection pooling involves:
1. **Database pooling** (PostgreSQL, MySQL, MongoDB)
2. **Redis pooling** (connection pools, clusters)
3. **HTTP pooling** (keep-alive connections)
4. **gRPC pooling** (channel management)
5. **Pool configuration** (sizing, environment-based)
6. **Monitoring** (metrics, health checks)
7. **Anti-patterns** (per-request connections, leaks, excessive sizing)

Use this guide to implement efficient connection pooling across frameworks.
