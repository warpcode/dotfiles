# Code Smells

## Overview

Comprehensive guide to identifying code smells. Code smells are symptoms in code that indicate deeper problems (design issues, maintainability problems, or missed opportunities for refactoring).

---

## Code Smell Categories

```
┌─────────────────────────────────────┐
│          CODE SMELLS               │
├─────────────────────────────────────┤
│  1. Bloaters                     │
│  2. Object-Orientation Abusers     │
│  3. Change Preventers            │
│  4. Dispensables                 │
│  5. Couplers                      │
├─────────────────────────────────────┤
│  6. Secondary Smell Categories    │
│    - Large Class                  │
│    - Long Method                  │
│    - Long Parameter List          │
│    - Divergent Change            │
│    - Shotgun Surgery              │
│    - Feature Envy               │
│    - Data Clumps                 │
│    - Primitive Obsession         │
│    - Alternative Classes          │
│    - Lazy Class                  │
└─────────────────────────────────────┘
```

---

## Bloaters

### 1. Long Method

**Problem:** Method is too long, doing too much.

```javascript
// ❌ SMELL - Long method (50+ lines)
function processOrder(order, user, paymentService, emailService, shippingService, inventoryService) {
    // Validation
    if (!order || !order.items) {
        throw new Error('Invalid order');
    }

    if (!user || !user.id) {
        throw new Error('Invalid user');
    }

    // Calculate total
    let total = 0;
    for (const item of order.items) {
        total += item.price * item.quantity;
    }

    // Apply discounts
    if (user.isPremium) {
        total *= 0.9;
    }

    // Check inventory
    for (const item of order.items) {
        const product = await inventoryService.check(item.productId);
        if (product.stock < item.quantity) {
            throw new Error('Out of stock');
        }
    }

    // Calculate shipping
    const shipping = await shippingService.calculate(order.address);

    // Process payment
    const payment = await paymentService.charge({
        amount: total + shipping.cost,
        method: paymentMethod
    });

    // Update inventory
    for (const item of order.items) {
        await inventoryService.reduce(item.productId, item.quantity);
    }

    // Create order record
    const orderRecord = await orderRepository.create({
        userId: user.id,
        items: order.items,
        total,
        shipping,
        payment
    });

    // Send email
    await emailService.sendConfirmation({
        to: user.email,
        order: orderRecord
    });

    // Return result
    return {
        success: true,
        orderId: orderRecord.id
    };
}

// ✅ REFACTORED - Extracted methods
function processOrder(order, user, paymentService, emailService, shippingService, inventoryService) {
    validateOrder(order);
    validateUser(user);

    const total = await calculateTotal(order, user);
    const shipping = await calculateShipping(order);
    const payment = await processPayment(total, shipping, paymentService);

    await updateInventory(order.items, inventoryService);
    const orderRecord = await createOrder(order, user, total, shipping, payment);
    await sendConfirmationEmail(user.email, orderRecord, emailService);

    return { success: true, orderId: orderRecord.id };
}

function validateOrder(order) {
    if (!order || !order.items) {
        throw new Error('Invalid order');
    }
}

function validateUser(user) {
    if (!user || !user.id) {
        throw new Error('Invalid user');
    }
}

function calculateTotal(order, user) {
    let total = order.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    return user.isPremium ? total * 0.9 : total;
}

function calculateShipping(order) {
    return shippingService.calculate(order.address);
}

function processPayment(total, shipping, paymentService) {
    return paymentService.charge({
        amount: total + shipping.cost,
        method: paymentService.method
    });
}
```

### 2. Large Class

**Problem:** Class has too many responsibilities.

```javascript
// ❌ SMELL - Large class (20+ methods, 500+ lines)
class UserService {
    // User CRUD
    async createUser(userData) { /* ... */ }
    async getUserById(id) { /* ... */ }
    async updateUser(id, userData) { /* ... */ }
    async deleteUser(id) { /* ... */ }
    async findUserByEmail(email) { /* ... */ }

    // Authentication
    async login(email, password) { /* ... */ }
    async logout(userId) { /* ... */ }
    async resetPassword(email) { /* ... */ }
    async changePassword(userId, oldPassword, newPassword) { /* ... */ }
    async verifyToken(token) { /* ... */ }
    async generateToken(userId) { /* ... */ }

    // Email operations
    async sendWelcomeEmail(email, name) { /* ... */ }
    async sendPasswordResetEmail(email) { /* ... */ }
    async sendConfirmationEmail(email, orderId) { /* ... */ }
    async sendNotificationEmail(email, message) { /* ... */ }

    // Profile operations
    async updateProfile(userId, profileData) { /* ... */ }
    async getProfile(userId) { /* ... */ }
    async uploadAvatar(userId, file) { /* ... */ }
    async deleteAvatar(userId) { /* ... */ }

    // Subscription
    async createSubscription(userId, plan) { /* ... */ }
    async cancelSubscription(userId) { /* ... */ }
    async getSubscription(userId) { /* ... */ }
    async updateSubscription(userId, plan) { /* ... */ }

    // Reporting
    async getUserActivity(userId) { /* ... */ }
    async generateReport(userId) { /* ... */ }
    async exportUserData(userId) { /* ... */ }

    // ... more methods (500+ lines)
}

// ✅ REFACTORED - Split into smaller classes
class UserService {
    async createUser(userData) { /* ... */ }
    async getUserById(id) { /* ... */ }
    async updateUser(id, userData) { /* ... */ }
    async deleteUser(id) { /* ... */ }
    async findUserByEmail(email) { /* ... */ }
}

class AuthenticationService {
    async login(email, password) { /* ... */ }
    async logout(userId) { /* ... */ }
    async resetPassword(email) { /* ... */ }
    async changePassword(userId, oldPassword, newPassword) { /* ... */ }
    async verifyToken(token) { /* ... */ }
}

class EmailService {
    async sendWelcomeEmail(email, name) { /* ... */ }
    async sendPasswordResetEmail(email) { /* ... */ }
    async sendConfirmationEmail(email, orderId) { /* ... */ }
    async sendNotificationEmail(email, message) { /* ... */ }
}

class ProfileService {
    async updateProfile(userId, profileData) { /* ... */ }
    async getProfile(userId) { /* ... */ }
    async uploadAvatar(userId, file) { /* ... */ }
    async deleteAvatar(userId) { /* ... */ }
}

class SubscriptionService {
    async createSubscription(userId, plan) { /* ... */ }
    async cancelSubscription(userId) { /* ... */ }
    async getSubscription(userId) { /* ... */ }
    async updateSubscription(userId, plan) { /* ... */ }
}

class ReportService {
    async getUserActivity(userId) { /* ... */ }
    async generateReport(userId) { /* ... */ }
    async exportUserData(userId) { /* ... */ }
}
```

### 3. Long Parameter List

**Problem:** Method has too many parameters (>4).

```javascript
// ❌ SMELL - 8 parameters
function createOrder(userId, shippingAddress, billingAddress, items, discountCode, paymentMethod, cardNumber, cvv, expiry) {
    // Method body
}

// ✅ REFACTORED - Use parameter object
function createOrder(orderData) {
    const {
        userId,
        shippingAddress,
        billingAddress,
        items,
        discountCode,
        paymentMethod,
        payment: { cardNumber, cvv, expiry }
    } = orderData;

    // Method body
}
```

---

## Object-Orientation Abusers

### 4. Switch Statement

**Problem:** Using switch statements instead of polymorphism.

```javascript
// ❌ SMELL - Switch statement
function calculateDiscount(user, order) {
    let discount = 0;

    switch (user.type) {
        case 'regular':
            discount = 0;
            break;
        case 'premium':
            discount = order.total * 0.1;
            break;
        case 'vip':
            discount = order.total * 0.2;
            break;
        case 'enterprise':
            discount = order.total * 0.3;
            break;
        default:
            discount = 0;
    }

    return discount;
}

// ✅ REFACTORED - Polymorphism
class DiscountCalculator {
    calculate(order) {
        return this.discount;
    }
}

class RegularDiscount extends DiscountCalculator {
    get discount() { return 0; }
}

class PremiumDiscount extends DiscountCalculator {
    constructor(order) {
        super();
        this.discount = order.total * 0.1;
    }
}

class VipDiscount extends DiscountCalculator {
    constructor(order) {
        super();
        this.discount = order.total * 0.2;
    }
}

class EnterpriseDiscount extends DiscountCalculator {
    constructor(order) {
        super();
        this.discount = order.total * 0.3;
    }
}

function createDiscountCalculator(user, order) {
    switch (user.type) {
        case 'regular': return new RegularDiscount();
        case 'premium': return new PremiumDiscount(order);
        case 'vip': return new VipDiscount(order);
        case 'enterprise': return new EnterpriseDiscount(order);
    }
}

function calculateDiscount(user, order) {
    const calculator = createDiscountCalculator(user, order);
    return calculator.calculate(order);
}
```

### 5. Temp Field

**Problem:** Variable exists only to pass data between code blocks.

```javascript
// ❌ SMELL - Temp field
class OrderService {
    tempOrder = null;  // Temp field

    async processOrder(orderId) {
        this.tempOrder = await this.orderRepository.findById(orderId);
        this.tempOrder.status = 'processing';
        await this.orderRepository.update(this.tempOrder);

        const shipping = await this.shippingService.calculate(this.tempOrder);
        this.tempOrder.shippingCost = shipping.cost;

        const payment = await this.paymentService.charge(this.tempOrder);
        this.tempOrder.payment = payment;

        await this.orderRepository.update(this.tempOrder);
    }
}

// ✅ REFACTORED - Remove temp field
class OrderService {
    async processOrder(orderId) {
        const order = await this.orderRepository.findById(orderId);

        const updatedOrder = await this.updateStatus(order, 'processing');
        const orderWithShipping = await this.calculateShipping(updatedOrder);
        const orderWithPayment = await this.processPayment(orderWithShipping);

        await this.orderRepository.update(orderWithPayment);
    }

    async updateStatus(order, status) {
        const updated = { ...order, status };
        return await this.orderRepository.update(updated);
    }

    async calculateShipping(order) {
        const shipping = await this.shippingService.calculate(order);
        return { ...order, shippingCost: shipping.cost };
    }

    async processPayment(order) {
        const payment = await this.paymentService.charge(order);
        return { ...order, payment };
    }
}
```

---

## Change Preventers

### 6. Divergent Change

**Problem:** Similar changes affect multiple classes.

```javascript
// ❌ SMELL - Divergent change
// When adding new user type, must change multiple classes
class RegularUser {
    calculateDiscount() { return 0; }
}

class PremiumUser {
    calculateDiscount() { return 0.1; }
}

class VipUser {
    calculateDiscount() { return 0.2; }
}

class EnterpriseUser {
    calculateDiscount() { return 0.3; }
}

// If you add a new type, you must create a new class

// ✅ REFACTORED - Move to single class with type field
class User {
    constructor(type) {
        this.type = type;
    }

    calculateDiscount(total) {
        const discounts = {
            regular: 0,
            premium: 0.1,
            vip: 0.2,
            enterprise: 0.3
        };
        return total * (discounts[this.type] || 0);
    }
}
```

### 7. Shotgun Surgery

**Problem:** One change requires modifications to many methods.

```javascript
// ❌ SMELL - Shotgun surgery
class Order {
    // If you change how orderId is stored, must update ALL methods
    constructor(orderId, items, total, status, userId) {
        this.orderId = orderId;
        this.items = items;
        this.total = total;
        this.status = status;
        this.userId = userId;
    }

    addItem(item) {
        // Updates orderId logic
        this.orderId = generateId();
    }

    updateStatus(status) {
        // Updates orderId logic
        this.orderId = updateId(this.orderId);
    }

    deleteItem(itemId) {
        // Updates orderId logic
        this.orderId = removeItemId(this.orderId, itemId);
    }

    // ... many more methods all touching orderId
}

// ✅ REFACTORED - Encapsulate orderId in its own class
class OrderId {
    constructor(prefix) {
        this.id = generateId(prefix);
    }

    toString() {
        return this.id;
    }
}

class Order {
    constructor(orderId, items, total, status, userId) {
        this.orderId = new OrderId('order');
        this.items = items;
        this.total = total;
        this.status = status;
        this.userId = userId;
    }

    addItem(item) {
        this.orderId = this.orderId.addItem(item);
    }
}
```

---

## Dispensables

### 8. Comments

**Problem:** Code explained in comments instead of being self-documenting.

```javascript
// ❌ SMELL - Useless comments
// Calculate total
let total = 0;

// Loop through items
for (const item of items) {
    // Add price times quantity
    total += item.price * item.quantity;
}

// Return total
return total;

// ✅ REFACTORED - Self-documenting code
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}
```

### 9. Dead Code

**Problem:** Code that's never executed.

```javascript
// ❌ SMELL - Dead code
function calculateTotal(items) {
    let total = 0;

    for (const item of items) {
        total += item.price * item.quantity;
    }

    return total;
}

function oldCalculateTotal(items) {
    // Dead code - never called
    return items.reduce((sum, item) => sum + item.price, 0);
}

// ✅ REFACTORED - Remove dead code
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}
```

---

## Couplers

### 10. Feature Envy

**Problem:** Method uses data from another class more than its own.

```javascript
// ❌ SMELL - Feature Envy
class Order {
    constructor(userService, shippingService, paymentService) {
        this.userService = userService;
        this.shippingService = shippingService;
        this.paymentService = paymentService;
    }

    // Too much interest in UserService data
    processOrder() {
        const user = this.userService.findUser(this.userId);
        const premiumDiscount = user.isPremium ? 0.1 : 0;
        const shippingDiscount = user.hasFreeShipping ? 0 : this.shippingCost;
        const paymentDiscount = user.hasPaymentFeeWaiver ? 0 : this.paymentFee;

        // Feature envy - using too much user data
    }
}

// ✅ REFACTORED - Move logic to UserService
class Order {
    processOrder() {
        const user = this.userService.findUser(this.userId);
        const discount = this.userService.calculateDiscount(this, user);
        this.applyDiscount(discount);
    }
}

class UserService {
    calculateDiscount(order, user) {
        const premiumDiscount = user.isPremium ? 0.1 : 0;
        const shippingDiscount = user.hasFreeShipping ? 0 : order.shippingCost;
        const paymentDiscount = user.hasPaymentFeeWaiver ? 0 : order.paymentFee;

        return premiumDiscount + shippingDiscount + paymentDiscount;
    }
}
```

### 11. Data Clumps

**Problem:** Group of data without behavior used in multiple places.

```javascript
// ❌ SMELL - Data clumps
const ADDRESS = {
    street: '',
    city: '',
    state: '',
    zip: '',
    country: ''
};

class OrderService {
    createOrder(shipping, billing, items) {
        // Using ADDRESS data clump
        const shippingAddress = { ...ADDRESS, ...shipping };
        const billingAddress = { ...ADDRESS, ...billing };

        // More code
    }
}

class ShippingService {
    calculateShipping(address) {
        // Using ADDRESS data clump
        const fullAddress = { ...ADDRESS, ...address };

        // More code
    }
}

// ✅ REFACTORED - Create Address class with behavior
class Address {
    constructor(street, city, state, zip, country) {
        this.street = street;
        this.city = city;
        this.state = state;
        this.zip = zip;
        this.country = country;
    }

    getFullAddress() {
        return `${this.street}, ${this.city}, ${this.state} ${this.zip}`;
    }

    formatForShipping() {
        return {
            street1: this.street,
            city: this.city,
            state: this.state,
            zip: this.zip,
            country: this.country
        };
    }
}
```

---

## Secondary Code Smells

### 12. Duplicate Code

**Problem:** Identical or similar code in multiple places.

```javascript
// ❌ SMELL - Duplicate code
function validateUser(user) {
    if (!user || !user.name) {
        throw new Error('Name is required');
    }
    if (!user.email || !isValidEmail(user.email)) {
        throw new Error('Invalid email');
    }
    if (!user.age || user.age < 18) {
        throw new Error('Must be 18 or older');
    }
}

function validateAdmin(admin) {
    if (!admin || !admin.name) {
        throw new Error('Name is required');
    }
    if (!admin.email || !isValidEmail(admin.email)) {
        throw new Error('Invalid email');
    }
    if (!admin.age || admin.age < 21) {
        throw new Error('Must be 21 or older');
    }
}

// ✅ REFACTORED - Extract to validator
class PersonValidator {
    validate(person, config) {
        if (!person || !person.name) {
            throw new Error('Name is required');
        }
        if (!person.email || !isValidEmail(person.email)) {
            throw new Error('Invalid email');
        }
        if (!person.age || person.age < config.minAge) {
            throw new Error(`Must be ${config.minAge} or older`);
        }
    }
}

function validateUser(user) {
    const validator = new PersonValidator();
    validator.validate(user, { minAge: 18 });
}

function validateAdmin(admin) {
    const validator = new PersonValidator();
    validator.validate(admin, { minAge: 21 });
}
```

### 13. Magic Numbers

**Problem:** Hard-coded numbers without explanation.

```javascript
// ❌ SMELL - Magic numbers
function calculateInterest(principal, rate, years) {
    return principal * Math.pow(1 + rate / 12, years * 12);
}

function validatePassword(password) {
    if (password.length < 8) {
        return false;
    }
    if (password.length > 128) {
        return false;
    }
    return true;
}

// ✅ REFACTORED - Named constants
const MONTHS_PER_YEAR = 12;
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

function calculateInterest(principal, rate, years) {
    return principal * Math.pow(1 + rate / MONTHS_PER_YEAR, years * MONTHS_PER_YEAR);
}

function validatePassword(password) {
    if (password.length < MIN_PASSWORD_LENGTH) {
        return false;
    }
    if (password.length > MAX_PASSWORD_LENGTH) {
        return false;
    }
    return true;
}
```

---

## Summary

Code smells indicate deeper problems:

**Bloaters:**
- Long Method → Extract methods
- Large Class → Split into smaller classes
- Long Parameter List → Use parameter object

**Object-Orientation Abusers:**
- Switch Statement → Use polymorphism
- Temp Field → Pass data as parameters

**Change Preventers:**
- Divergent Change → Encapsulate change in single class
- Shotgun Surgery → Isolate changes

**Dispensables:**
- Comments → Self-documenting code
- Dead Code → Remove unused code

**Couplers:**
- Feature Envy → Move logic to appropriate class
- Data Clumps → Create class with behavior

**Secondary Smells:**
- Duplicate Code → Extract to functions/classes
- Magic Numbers → Use named constants

**Refactoring Goal:**
- Improve maintainability
- Reduce complexity
- Enhance readability
- Follow SOLID principles

Use code smell detection to improve quality.
