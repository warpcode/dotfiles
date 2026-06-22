# Complexity

## Overview

Comprehensive guide to analyzing and reducing code complexity. High complexity leads to bugs, difficulty in maintenance, and reduced developer productivity.

---

## Complexity Metrics

### 1. Cyclomatic Complexity

**Definition:** Number of linearly independent paths through a program's source code.

**Formula:**
```
CC = E - N + 1
Where:
E = Number of edges (branching statements)
N = Number of nodes (decision points)
```

**Scoring:**
| Complexity | Risk | Action |
|-----------|-------|--------|
| 1-10 | Low | No action needed |
| 11-20 | Moderate | Consider refactoring |
| 21-50 | High | Should refactor |
| 50+ | Very High | Must refactor |

**Example:**
```javascript
// CC = 1 (Low complexity)
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}

// CC = 12 (High complexity)
function processOrder(order) {
    let status = 'pending';
    let discount = 0;
    let shipping = 0;
    let tax = 0;
    let total = 0;
    let processed = false;
    let emailSent = false;
    let invoiceCreated = false;

    if (order.user.isPremium) {
        if (order.total > 50) {
            discount = 0.1;
        } else {
            discount = 0.05;
        }
    } else {
        if (order.total > 100) {
            discount = 0.05;
        } else {
            discount = 0;
        }
    }

    if (order.shipping.country === 'US') {
        if (order.shipping.state === 'CA') {
            shipping = 10;
        } else {
            shipping = 5;
        }
    } else if (order.shipping.country === 'UK') {
        shipping = 15;
    } else {
        shipping = 20;
    }
    }

    tax = order.total * 0.2;
    total = order.total - discount + shipping + tax;

    if (order.user.email) {
        emailService.send(order.user.email);
        emailSent = true;
    }

    if (order.items) {
        for (const item of order.items) {
            if (item.product) {
                invoiceService.addLineItem(item);
                invoiceCreated = true;
            }
        }
    }

    if (emailSent && invoiceCreated) {
        processed = true;
        status = 'completed';
    } else {
        status = 'error';
    }

    return { status, total, discount, shipping, tax, processed };
}
```

**✅ REFACTORED - Reduced complexity**
```javascript
function processOrder(order) {
    const discount = calculateDiscount(order);
    const shipping = calculateShipping(order.shipping);
    const tax = calculateTax(order.total);
    const total = calculateTotal(order, discount, shipping, tax);

    if (order.user.email) {
        await emailService.send(order.user.email);
    }

    await invoiceService.create(order);

    return { status: 'completed', total };
}

function calculateDiscount(order) {
    if (order.user.isPremium) {
        return order.total * (order.total > 50 ? 0.1 : 0.05);
    }
    return 0;
}

function calculateShipping(shipping) {
    const rates = { US: { CA: 10, other: 5 }, UK: 15 };
    return rates[shipping.country] || 20;
}
```

### 2. Cognitive Complexity

**Definition:** How difficult it is for a human reader to understand the code's flow.

**Formula:**
```
Nesting + Operators + Conditionals - Returns + Total
```

**Scoring:**
| Complexity | Cognitive | Risk | Action |
|-----------|-----------|-------|--------|
| 0-5 | Very Low | No action needed |
| 6-10 | Low | No action needed |
| 11-20 | Moderate | Consider simplifying |
| 21-40 | High | Should simplify |
| 40+ | Very High | Must simplify |

**Example:**
```javascript
// Cognitive Complexity = 35 (Very High)
function processPayment(order) {
    if (order.paymentMethod === 'credit_card') {
        if (order.card.type === 'visa') {
            if (order.card.number.length === 16) {
                if (order.card.expYear > 2025) {
                    if (order.card.expMonth > 12) {
                        if (order.card.cvv) {
                            if (order.billingAddress.country === 'US') {
                                if (order.billingAddress.state === 'CA') {
                                    if (order.billingAddress.zip) {
                                        return processVisa(order);
                                    } else {
                                        return processInvalidZip(order);
                                    }
                                } else if (order.billingAddress.country === 'UK') {
                                    if (order.billingAddress.zip) {
                                        return processUKZip(order);
                                    }
                                } else {
                                    return processInternationalZip(order);
                                }
                            }
                        }
                    }
                } else if (order.card.number.length === 15) {
                    // ... more nested logic
                }
            }
        }
    }
}
```

**✅ REFACTORED - Reduced cognitive complexity**
```javascript
async function processPayment(order) {
    if (!isValidPayment(order)) {
        throw new Error('Invalid payment');
    }

    const cardValidation = await validateCard(order.card);
    if (!cardValidation.valid) {
        throw new Error(cardValidation.error);
    }

    const addressValidation = await validateAddress(order.billingAddress);
    if (!addressValidation.valid) {
        throw new Error(addressValidation.error);
    }

    const paymentResult = await chargeCard(order);
    if (!paymentResult.success) {
        throw new Error(paymentResult.error);
    }

    return { success: true, transactionId: paymentResult.transactionId };
}

async function validateCard(card) {
    if (card.number.length < 13 || card.number.length > 16) {
        return { valid: false, error: 'Invalid card number length' };
    }

    if (card.expYear < new Date().getFullYear()) {
        return { valid: false, error: 'Card expired' };
    }

    return { valid: true };
}

function isValidPayment(order) {
    return order.paymentMethod && order.card && order.billingAddress;
}
```

### 3. Maintainability Index (MI)

**Definition:** Halstead metrics to measure maintainability.

**Formula:**
```
MI = 171 - 5.2 × ln(V) - 0.23 × C - 16.2 × ln(L)

Where:
V = Number of distinct operators
C = Cyclomatic Complexity
L = Number of lines of code
```

**Scoring:**
| MI Score | Maintainability | Risk | Action |
|----------|---------------|-------|--------|
| 85-100 | Very High | No action needed |
| 65-85 | High | Consider refactoring |
| 50-65 | Moderate | Should refactor |
| 0-50 | Low | Must refactor |

---

## Reducing Complexity

### Strategy 1: Extract Methods

**Problem:** Long method with many responsibilities.

```javascript
// ❌ High complexity
function processOrder(order) {
    // 50+ lines
    if (order.items) {
        for (const item of order.items) {
            if (item.product) {
                if (item.product.stock) {
                    if (item.quantity <= item.product.stock) {
                        order.items.push({
                            productId: item.product.id,
                            quantity: item.quantity,
                            price: item.product.price
                        });
                    }
                }
            }
        }
    }

    let total = 0;
    for (const item of order.items) {
        total += item.price * item.quantity;
    }
    // ... more code
}
```

**✅ REFACTORED - Extract methods**
```javascript
function processOrder(order) {
    const items = validateAndFilterItems(order.items);
    const total = calculateOrderTotal(items);

    return {
        items,
        total
    };
}

function validateAndFilterItems(items) {
    return items
        .filter(item => item.product && item.product.stock)
        .filter(item => item.quantity <= item.product.stock)
        .map(item => ({
            productId: item.product.id,
            quantity: item.quantity,
            price: item.product.price
        }));
}

function calculateOrderTotal(items) {
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}
```

### Strategy 2: Use Guard Clauses

**Problem:** Nested conditionals increase cyclomatic complexity.

```javascript
// ❌ High complexity (CC = 5)
function calculateDiscount(user, order) {
    let discount = 0;

    if (user.isPremium) {
        if (order.total > 50) {
            if (user.hasFreeShipping) {
                discount = 0.15;
            } else {
                discount = 0.10;
            }
        } else {
            discount = 0.05;
        }
    } else {
        if (order.total > 100) {
            discount = 0.05;
        } else {
            discount = 0;
        }
    }

    return order.total * (1 - discount);
}
```

**✅ REFACTORED - Guard clauses (CC = 2)**
```javascript
function calculateDiscount(user, order) {
    if (!user.isPremium || order.total <= 0) {
        return order.total;
    }

    if (order.total > 100) {
        return 0.95 * order.total;
    }

    const premiumDiscount = user.isPremium && order.total > 50 ? 0.10 : 0.05;
    const freeShippingDiscount = user.hasFreeShipping ? 0.05 : 0;

    const discount = premiumDiscount + freeShippingDiscount;

    return order.total * (1 - discount);
}
```

### Strategy 3: Use Strategy Pattern

**Problem:** Multiple switch/if statements.

```javascript
// ❌ High complexity
function calculateTax(country, state, productType) {
    let taxRate = 0;

    if (country === 'US') {
        if (state === 'CA') {
            taxRate = 0.0875;
        } else if (state === 'NY') {
            taxRate = 0.08875;
        } else if (state === 'TX') {
            taxRate = 0.0625;
        } else {
            taxRate = 0.07;
        }
    } else if (country === 'UK') {
        if (productType === 'electronics') {
            taxRate = 0.2;
        } else if (productType === 'clothing') {
            taxRate = 0.05;
        } else {
            taxRate = 0.1;
        }
    } else if (country === 'DE') {
        if (productType === 'electronics') {
            taxRate = 0.19;
        } else if (productType === 'clothing') {
            taxRate = 0.07;
        } else {
            taxRate = 0.16;
        }
    } else {
        taxRate = 0.1;
    }

    return price * taxRate;
}
```

**✅ REFACTORED - Strategy pattern**
```javascript
class TaxCalculatorStrategy {
    getTaxRate(country, state, productType) {
        throw new Error('Method must be implemented');
    }

    getTaxAmount(price, country, state, productType) {
        const rate = this.getTaxRate(country, state, productType);
        return price * rate;
    }
}

class USTaxCalculator extends TaxCalculatorStrategy {
    getTaxRate(state) {
        const stateRates = {
            'CA': 0.0875,
            'NY': 0.08875,
            'TX': 0.0625
        };
        return stateRates[state] || 0.07;
    }
}

class UKTaxCalculator extends TaxCalculatorStrategy {
    getTaxRate(productType) {
        const typeRates = {
            'electronics': 0.2,
            'clothing': 0.05,
            'other': 0.1
        };
        return typeRates[productType] || 0.15;
    }
}

class DETaxCalculator extends TaxCalculatorStrategy {
    getTaxRate(productType) {
        const typeRates = {
            'electronics': 0.19,
            'clothing': 0.07,
            'other': 0.16
        };
        return typeRates[productType] || 0.2;
    }
}

class DefaultTaxCalculator extends TaxCalculatorStrategy {
    getTaxRate() {
        return 0.1;
    }
}

// Factory
const taxCalculators = {
    'US': new USTaxCalculator(),
    'UK': new UKTaxCalculator(),
    'DE': new DETaxCalculator(),
};

function getTaxCalculator(country) {
    return taxCalculators[country] || new DefaultTaxCalculator();
}

function calculateTax(price, country, state, productType) {
    const calculator = getTaxCalculator(country);
    return calculator.getTaxAmount(price, country, state, productType);
}
```

### Strategy 4: Use Polymorphism

**Problem:** Type checking and switch statements.

```javascript
// ❌ High complexity
function calculateShipping(address) {
    let shippingCost = 0;

    if (address.type === 'residential') {
        if (address.weight < 1) {
            shippingCost = 5;
        } else if (address.weight < 5) {
            shippingCost = 10;
        } else if (address.weight < 10) {
            shippingCost = 15;
        } else {
            shippingCost = 20;
        }
    } else if (address.type === 'business') {
        if (address.weight < 1) {
            shippingCost = 8;
        } else if (address.weight < 5) {
            shippingCost = 15;
        } else if (address.weight < 10) {
            shippingCost = 20;
        } else {
            shippingCost = 30;
        }
    }

    return shippingCost;
}
```

**✅ REFACTORED - Polymorphism**
```javascript
class ShippingStrategy {
    calculateCost(weight) {
        throw new Error('Method must be implemented');
    }
}

class ResidentialShippingStrategy extends ShippingStrategy {
    getWeightBrackets() {
        return [1, 5, 10, 10];
    }

    getRates() {
        return [5, 10, 15, 20];
    }

    calculateCost(weight) {
        const brackets = this.getWeightBrackets();
        const rates = this.getRates();

        for (let i = 0; i < brackets.length; i++) {
            if (weight <= brackets[i]) {
                return rates[i];
            }
        }

        return rates[rates.length - 1];
    }
}

class BusinessShippingStrategy extends ShippingStrategy {
    getWeightBrackets() {
        return [1, 5, 10, 10];
    }

    getRates() {
        return [8, 15, 20, 30];
    }

    calculateCost(weight) {
        const brackets = this.getWeightBrackets();
        const rates = this.getRates();

        for (let i = 0; i < brackets.length; i++) {
            if (weight <= brackets[i]) {
                return rates[i];
            }
        }

        return rates[rates.length - 1];
    }
}

const shippingStrategies = {
    'residential': new ResidentialShippingStrategy(),
    'business': new BusinessShippingStrategy(),
};

function getShippingStrategy(type) {
    return shippingStrategies[type];
}

function calculateShipping(address) {
    const strategy = getShippingStrategy(address.type);
    return strategy.calculateCost(address.weight);
}
```

---

## Complexity Analysis Tools

### JavaScript/TypeScript

```bash
# Install complexity analyzer
npm install --save-dev eslint-plugin-complexity

# Run complexity check
eslint . --ext .js --format json --output-file complexity-report.json

# Alternative: Plato
npm install -g plato
plato -r -d report -x complexity -l json ./src/
```

### Python

```bash
# Install complexity analyzer
pip install radon

# Run complexity check
radon ./src -o complexity.json
radon ./src -cc -a -nb -nc -s --json
```

### PHP

```bash
# Install complexity analyzer
composer require --dev pdepend/pdepend
composer require --dev phpmd/phpmd

# Run complexity check
pdepend --jdepend-chart=overview --overview-xml=complexity.xml ./src
phpmd --reportfile=complexity.html complexity.xml
```

---

## Complexity Anti-Patterns

### ❌ Long Method

```javascript
// Anti-pattern: 100+ line method
function superComplexMethod(data) {
    // 100+ lines of nested logic
    // ...complex...
}

// Refactor: Split into smaller methods
function superComplexMethod(data) {
    const validated = validateData(data);
    const processed = processData(validated);
    const result = generateResult(processed);

    return result;
}
```

### ❌ Deep Nesting

```javascript
// Anti-pattern: 5+ levels of nesting
function processOrder(order) {
    if (order) {
        if (order.user) {
            if (order.user.id) {
                if (order.user.email) {
                    // 4 levels deep!
                    processUser(order.user);
                }
            }
        }
    }
}

// Refactor: Use guard clauses and early returns
function processOrder(order) {
    if (!order || !order.user) {
        return;
    }

    if (!order.user.email) {
        return;
    }

    processUser(order.user);
}
```

---

## Summary

Code complexity analysis:

**Metrics:**
- **Cyclomatic Complexity**: Number of decision paths (CC <10 good)
- **Cognitive Complexity**: How hard to understand (<15 good)
- **Maintainability Index**: MI score (>65 good)

**Reduction Strategies:**
- Extract methods from long functions
- Use guard clauses to reduce nesting
- Apply strategy pattern for business rules
- Use polymorphism instead of switch statements

**Tools:**
- JavaScript: eslint-plugin-complexity, Plato
- Python: radon
- PHP: pdepend, phpmd

**Anti-Patterns:**
- Long method (>50 lines)
- Deep nesting (>3 levels)
- Excessive parameters (>5 parameters)
- Multiple responsibilities

Use complexity analysis to reduce technical debt and improve maintainability.
