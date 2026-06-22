# Anti-Patterns

## Overview

Comprehensive guide to software anti-patterns. Anti-patterns are common solutions to recurring problems that are ineffective, counterproductive, or create more problems than they solve.

---

## Anti-Pattern Categories

```
┌─────────────────────────────────────┐
│        ANTI-PATTERNS              │
├─────────────────────────────────────┤
│  1. Creational                   │
│  2. Structural                    │
│  3. Behavioral                    │
│  4. Architectural                │
│  5. Concurrency                   │
│  6. Database                     │
│  7. API/Service                  │
└─────────────────────────────────────┘
```

---

## Creational Anti-Patterns

### 1. Singleton

**Problem:** Global state, hard to test, hidden dependencies.

```javascript
// ❌ ANTI-PATTERN - Singleton
class Database {
    static instance = null;

    static getInstance() {
        if (!Database.instance) {
            Database.instance = new Database();
        }
        return Database.instance;
    }
}

const db = Database.getInstance();
const db2 = Database.getInstance();  // Same instance everywhere!

// ✅ REFACTORED - Dependency Injection
class Database {
    connect(connectionString) {
        // Create instance per connection string
    }
}

const db = new Database(connectionString);
const db2 = new Database(connectionString2);  // Different instances
```

### 2. God Object

**Problem:** Class that knows too much or does too much.

```javascript
// ❌ ANTI-PATTERN - God Object
class Application {
    // Database operations
    async getUser(id) { /* ... */ }
    async createUser(user) { /* ... */ }
    async updateUser(id, user) { /* ... */ }
    async deleteUser(id) { /* ... */ }

    // Email operations
    async sendEmail(to, subject, body) { /* ... */ }

    // Payment operations
    async chargeCard(card, amount) { /* ... */ }
    async processRefund(transactionId, amount) { /* ... */ }

    // Shipping operations
    async calculateShipping(address) { /* ... */ }

    // Inventory operations
    async checkStock(productId) { /* ... */ }
    async reduceStock(productId, quantity) { /* ... */ }

    // Reporting operations
    async generateReport(reportType) { /* ... */ }

    // ... 50+ methods
}

// ✅ REFACTORED - Split into focused classes
class UserRepository {
    async getUser(id) { /* ... */ }
    async createUser(user) { /* ... */ }
}

class EmailService {
    async sendEmail(to, subject, body) { /* ... */ }
}

class PaymentService {
    async chargeCard(card, amount) { /* ... */ }
}

class ShippingService {
    async calculateShipping(address) { /* ... */ }
}

class InventoryService {
    async checkStock(productId) { /* ... */ }
}
```

### 3. Builder

**Problem:** Excessive builder with many optional parameters.

```javascript
// ❌ ANTI-PATTERN - Excessive builder
class UserBuilder {
    withId(id) { this.id = id; return this; }
    withName(name) { this.name = name; return this; }
    withEmail(email) { this.email = email; return this; }
    withPassword(password) { this.password = password; return this; }
    withRole(role) { this.role = role; return this; }
    withActive(active) { this.active = active; return this; }
    withCreatedAt(createdAt) { this.createdAt = createdAt; return this; }
    withUpdatedAt(updatedAt) { this.updatedAt = updatedAt; return this; }
    // ... 20 more methods

    build() {
        return {
            id: this.id,
            name: this.name,
            email: this.email,
            password: this.password,
            role: this.role,
            active: this.active,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt
            // ... 20 more fields
        };
    }
}

// ✅ REFACTORED - Simplify or use default values
class User {
    constructor({
        id,
        name = 'John Doe',
        email = 'john@example.com',
        role = 'user',
        active = true,
        createdAt = new Date(),
        updatedAt = new Date()
    } = {}) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.role = role;
        this.active = active;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
```

---

## Structural Anti-Patterns

### 4. Spaghetti Code

**Problem:** Tangled control flow, hard to follow.

```javascript
// ❌ ANTI-PATTERN - Spaghetti code
function processOrder(order) {
    let status = 'pending';

    if (order.items) {
        if (order.items.length > 0) {
            if (order.items[0]) {
                const item = order.items[0];
                if (item.productId) {
                    if (item.quantity) {
                        if (item.quantity > 0) {
                            status = 'validating_stock';
                            if (item.productId > 1000) {
                                const product = getProduct(item.productId);
                                if (product) {
                                    if (product.stock >= item.quantity) {
                                        status = 'ready_to_process';
                                    } else {
                                        status = 'out_of_stock';
                                    }
                                }
                            } else {
                                status = 'invalid_quantity';
                            }
                        } else {
                            status = 'invalid_item';
                        }
                    } else {
                        status = 'missing_product_id';
                    }
                } else {
                    status = 'missing_item';
                }
            } else {
                status = 'no_items';
            }
        } else {
            status = 'empty_order';
        }
    } else {
        status = 'invalid_order';
    }

    if (status === 'validating_stock') {
        // Deeply nested logic continues...
    }

    // ... 100+ more lines of nested ifs
}

// ✅ REFACTORED - Early returns, extract methods
function processOrder(order) {
    if (!order.items || order.items.length === 0) {
        return { status: 'empty_order' };
    }

    if (!validateItems(order.items)) {
        return { status: 'invalid_items' };
    }

    const stockValidation = validateStock(order.items);
    if (!stockValidation.valid) {
        return { status: stockValidation.status };
    }

    return { status: 'ready_to_process' };
}

function validateItems(items) {
    return items.every(item => item.productId && item.quantity > 0);
}

function validateStock(items) {
    const stockIssues = items
        .map(item => checkStock(item))
        .filter(issue => !issue.valid);

    if (stockIssues.length > 0) {
        return {
            valid: false,
            status: 'out_of_stock',
            issues: stockIssues
        };
    }

    return { valid: true };
}

function checkStock(item) {
    const product = getProduct(item.productId);
    if (!product) {
        return { valid: false, error: 'Product not found' };
    }

    if (product.stock < item.quantity) {
        return { valid: false, error: 'Out of stock' };
    }

    return { valid: true };
}
```

### 5. Golden Hammer

**Problem:** Applying the same solution to everything.

```javascript
// ❌ ANTI-PATTERN - Golden hammer (always use database)
class OrderService {
    // Everything stored in database, even simple lookups
    async getConfig() {
        return await db.query('SELECT * FROM config');
    }

    async getUserPreferences(userId) {
        return await db.query(`SELECT * FROM preferences WHERE user_id = ${userId}`);
    }

    async getFeatureFlag(flag) {
        return await db.query(`SELECT value FROM flags WHERE flag = '${flag}'`);
    }

    // Even static data!
    async getCountries() {
        return await db.query('SELECT * FROM countries');
    }
}

// ✅ REFACTORED - Use appropriate storage
class OrderService {
    async getConfig() {
        return config;  // Static file or environment variable
    }

    async getUserPreferences(userId) {
        return cache.get(`user:${userId}:preferences`) ||
            await db.query(`SELECT * FROM preferences WHERE user_id = ${userId}`);
    }

    async getFeatureFlag(flag) {
        return featureFlags[flag];  // In-memory object
    }

    async getCountries() {
        return countries;  // Constant
    }
}
```

---

## Behavioral Anti-Patterns

### 6. Temporal Coupling

**Problem:** Code must be called in specific order.

```javascript
// ❌ ANTI-PATTERN - Temporal coupling
class OrderProcessor {
    constructor() {
        this.orders = [];
        this.currentUser = null;
    }

    // MUST be called first
    setCurrentUser(user) {
        this.currentUser = user;
    }

    // MUST be called second
    loadOrders() {
        if (!this.currentUser) {
            throw new Error('User must be set first!');
        }
        this.orders = this.currentUser.orders;
    }

    // MUST be called third
    processOrders() {
        if (this.orders.length === 0) {
            throw new Error('Orders must be loaded first!');
        }
        // Process orders
    }
}

// ✅ REFACTORED - Pass required data
class OrderProcessor {
    processOrdersForUser(orders) {
        if (!orders || orders.length === 0) {
            throw new Error('No orders to process');
        }

        return orders.map(order => this.processOrder(order));
    }

    processOrder(order) {
        // Process single order
        return {
            orderId: order.id,
            status: 'processed',
            items: order.items
        };
    }
}
```

### 7. Train Wreck

**Problem:** Modifying data that shouldn't be modified.

```javascript
// ❌ ANTI-PATTERN - Train wreck (modifying data)
function processOrders(orders) {
    for (const order of orders) {
        if (!order.items || order.items.length === 0) {
            order.items = [];  // Mutating!
        }

        for (const item of order.items) {
            item.total = item.price * item.quantity;  // Mutating!
        }

        order.total = order.items.reduce((sum, item) => sum + item.total, 0);
    }
}

// ✅ REFACTORED - Immutability
function processOrders(orders) {
    return orders.map(order => processOrder(order));
}

function processOrder(order) {
    if (!order.items || order.items.length === 0) {
        return {
            ...order,
            items: [],
            total: 0
        };
    }

    const itemsWithTotal = order.items.map(item => ({
        ...item,
        total: item.price * item.quantity
    }));

    const total = itemsWithTotal.reduce((sum, item) => sum + item.total, 0);

    return {
        ...order,
        items: itemsWithTotal,
        total
    };
}
```

---

## Architectural Anti-Patterns

### 8. Monolith

**Problem:** Single, massive application doing everything.

```javascript
// ❌ ANTI-PATTERN - Monolith
class Application {
    // 1000+ lines of code
    // User management
    // Order processing
    // Payment handling
    // Email sending
    // Reporting
    // Admin panel
    // API endpoints
    // Frontend routes
    // Database queries
    // Authentication
    // Authorization
    // ... everything in one place
}
```

**✅ REFACTORED - Microservices or modular architecture**
```
/
├── user-service/        # User management
├── order-service/       # Order processing
├── payment-service/      # Payment handling
├── email-service/        # Email sending
├── reporting-service/     # Reporting
├── admin-panel/          # Admin panel
├── api/                 # API endpoints
└── frontend/             # Frontend routes
```

### 9. Circular Dependencies

**Problem:** Module A depends on B, B depends on A.

```javascript
// ❌ ANTI-PATTERN - Circular dependency
// moduleA.js
import { functionB } from './moduleB';

export function functionA() {
    return functionB();
}

// moduleB.js
import { functionA } from './moduleA';

export function functionB() {
    return functionA();
}

// moduleC.js depends on both A and B
import { functionA } from './moduleA';
import { functionB } from './moduleB';

export function functionC() {
    return functionA() + functionB();
}
```

**✅ REFACTORED - Dependency injection or shared module**
```javascript
// sharedModule.js
export const sharedFunctions = {
    functionA: () => { /* ... */ },
    functionB: () => { /* ... */ }
};

// moduleA.js
import { sharedFunctions } from './sharedModule';

export function callSharedA() {
    return sharedFunctions.functionA();
}

// moduleB.js
import { sharedFunctions } from './sharedModule';

export function callSharedB() {
    return sharedFunctions.functionB();
}

// moduleC.js
import { sharedFunctions } from './sharedModule';

export function callSharedC() {
    return sharedFunctions.functionA() + sharedFunctions.functionB();
}
```

---

## Concurrency Anti-Patterns

### 10. Race Condition

**Problem:** Multiple threads access shared state unsafely.

```javascript
// ❌ ANTI-PATTERN - Race condition
class Counter {
    constructor() {
        this.count = 0;
    }

    increment() {
        const temp = this.count;
        setTimeout(() => {
            this.count = temp + 1;  // Race condition!
        }, 10);
    }
}

const counter = new Counter();

// Thread 1
counter.increment();  // Reads count = 0

// Thread 2
counter.increment();  // Also reads count = 0

// Both threads write count = 1!
// Result: count should be 2, but might be 1
```

**✅ REFACTORED - Atomic operations or locks
```javascript
class Counter {
    constructor() {
        this.count = 0;
        this.lock = false;
    }

    async increment() {
        while (this.lock) {
            await new Promise(resolve => setTimeout(resolve, 10));
        }

        this.lock = true;
        const temp = this.count;
        this.count = temp + 1;
        this.lock = false;
    }
}
```

### 11. Busy Waiting

**Problem:** Thread waits in a loop checking a condition.

```javascript
// ❌ ANTI-PATTERN - Busy waiting
class Processor {
    async waitForCondition() {
        while (!this.conditionMet) {
            // CPU wasteful loop!
            await new Promise(resolve => setTimeout(resolve, 100));
        }
    }

    process() {
        setTimeout(() => {
            this.conditionMet = true;
        }, 5000);
    }
}

// ✅ REFACTORED - Event-driven or promises
class Processor {
    async waitForCondition() {
        return new Promise(resolve => {
            this.onConditionMet = resolve;
        });
    }

    process() {
        setTimeout(() => {
            this.conditionMet = true;
            if (this.onConditionMet) {
                this.onConditionMet();
            }
        }, 5000);
    }
}
```

---

## Database Anti-Patterns

### 12. N+1 Query Problem

**Problem:** Query in loop fetching data one row at a time.

```javascript
// ❌ ANTI-PATTERN - N+1 queries
async function getUsersWithOrders(userId) {
    const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

    const orders = [];

    // N+1 problem: Query in loop!
    for (const order of user.orders) {
        const orderDetails = await db.query(
            'SELECT * FROM orders WHERE id = ?',
            [order.id]
        );
        orders.push(orderDetails);
    }

    return { user, orders };
}
```

**✅ REFACTORED - Eager loading or single query
```javascript
async function getUsersWithOrders(userId) {
    // Single query with JOIN
    const result = await db.query(`
        SELECT
            u.*,
            o.*
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.id = ?
    `, [userId]);

    return result;
}
```

### 13. Select * All Columns

**Problem:** Selecting all columns even when not needed.

```javascript
// ❌ ANTI-PATTERN - SELECT *
async function getUser(userId) {
    // Selects ALL columns
    const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

    return user;  // Returns password, internal fields, etc.
}
```

**✅ REFACTORED - Select only needed columns
```javascript
async function getUser(userId) {
    // Select only needed columns
    const user = await db.query(`
        SELECT
            id,
            name,
            email
        FROM users
        WHERE id = ?
    `, [userId]);

    return user;  // Returns only public-safe data
}
```

---

## API/Service Anti-Patterns

### 14. Chatty API

**Problem:** Many small API calls instead of one batch call.

```javascript
// ❌ ANTI-PATTERN - Chatty API
async function loadUserData(userId) {
    // Call 1
    const user = await api.get(`/users/${userId}`);

    // Call 2
    const orders = await api.get(`/users/${userId}/orders`);

    // Call 3
    const preferences = await api.get(`/users/${userId}/preferences`);

    // Call 4
    const notifications = await api.get(`/users/${userId}/notifications`);

    // ... many more calls
}

// ✅ REFACTORED - Batched API
async function loadUserData(userId) {
    // Single batch call
    const data = await api.get(`/users/${userId}/full`);

    return data;  // Returns user, orders, preferences, notifications, etc.
}
```

### 15. Returning HTTP Status Codes without Messages

**Problem:** Generic error messages.

```javascript
// ❌ ANTI-PATTERN - Generic error messages
app.get('/users/:id', async (req, res) => {
    try {
        const user = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
        res.json(user);
    } catch (error) {
        // Generic error message
        res.status(500).json({ error: 'An error occurred' });
    }
});
```

**✅ REFACTORED - Specific error messages
```javascript
app.get('/users/:id', async (req, res) => {
    try {
        const user = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);
        res.json(user);
    } catch (error) {
        if (error.code === 'NOT_FOUND') {
            res.status(404).json({ error: 'User not found', userId: req.params.id });
        } else if (error.code === 'DB_ERROR') {
            res.status(500).json({ error: 'Database error', details: error.message });
        } else {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
});
```

---

## Summary

Anti-patterns are common bad solutions:

**Creational:**
- Singleton → Use dependency injection
- God Object → Split into focused classes
- Builder → Simplify or use defaults

**Structural:**
- Spaghetti Code → Early returns, extract methods
- Golden Hammer → Use appropriate tools
- Monolith → Modular architecture, microservices
- Circular Dependencies → Shared module, dependency injection

**Behavioral:**
- Temporal Coupling → Pass required data
- Train Wreck → Immutability

**Architectural:**
- Monolith → Microservices or modules

**Concurrency:**
- Race Condition → Atomic operations, locks
- Busy Waiting → Event-driven, promises

**Database:**
- N+1 Query → Eager loading, JOIN queries
- SELECT * → Select specific columns

**API/Service:**
- Chatty API → Batched API calls
- Generic Errors → Specific error messages

**Goal:**
- Improve maintainability
- Reduce complexity
- Enhance performance
- Increase reliability

Use anti-pattern detection to write better code.
