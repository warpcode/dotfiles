# Algorithmic Complexity & Compute Optimization

Reference guide for evaluating compute hot-paths, memory usage, and execution efficiency.

---

## 1. Loop-in-Loop Lookups (`O(n^2)`)

### Inefficient Example
Searching an array repeatedly inside a loop over another collection:
```javascript
// O(n * m) complexity
const userOrders = users.map(user => {
    return {
        ...user,
        orders: orders.filter(order => order.userId === user.id)
    };
});
```

### Remediation: Hash Map Pre-Indexing (`O(n + m)`)
```javascript
// Build a lookup map in O(m) time
const ordersByUserId = orders.reduce((acc, order) => {
    (acc[order.userId] = acc[order.userId] || []).push(order);
    return acc;
}, {});

// Lookup in O(1) per user -> O(n) total
const userOrders = users.map(user => ({
    ...user,
    orders: ordersByUserId[user.id] || []
}));
```

---

## 2. Catastrophic Regular Expression Backtracking (ReDoS)

### Dangerous Patterns
Nested quantifiers like `(a+)+$` or `([a-zA-Z]+)*` against crafted inputs can cause exponential backtracking and lock the CPU thread.

### Remediation
- Use atomic groups or possessive quantifiers where supported.
- Validate string lengths prior to evaluating complex regular expressions.
- Keep regular expressions linear and anchored.

---

## 3. Resource & Memory Leaks in Long-Running Processes

### High-Risk Indicators
- Appending objects to global arrays or static class properties in daemon/worker scripts without eviction.
- Unclosed database cursors, open file streams, or unremoved event listeners in Node.js / worker processes.
- Retaining large closures that reference out-of-scope data structures.

