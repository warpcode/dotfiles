# E2E Testing

## Overview

Comprehensive guide to end-to-end (E2E) testing. E2E tests verify complete user flows through the application UI, simulating real user interactions.

---

## E2E Testing Fundamentals

### What is an E2E Test?

A test that simulates real user interaction with the application through the UI, testing the complete flow from start to finish.

### Characteristics

- **Full System**: Tests entire application (UI, DB, APIs, external services)
- **User-Centric**: Simulates real user actions (click, type, navigate)
- **Slow**: Runs in minutes to hours
- **No Isolation**: All components work together
- **Flaky**: Most prone to failures (network, timing, UI changes)

### Unit vs Integration vs E2E

| Aspect | Unit Tests | Integration Tests | E2E Tests |
|--------|-----------|------------------|------------|
| **Scope** | Single function/class | Multiple components | Full user flows |
| **Dependencies** | Mocked/Faked | Real or test doubles | Real system |
| **Speed** | <100ms | <5s | >10s |
| **Isolation** | Yes | Partial | No |
| **Flakiness** | Rare | Occasional | Frequent |
| **Value** | High | Medium | Low |
| **Cost** | Low | Medium | High |

---

## When to Write E2E Tests

### Good Candidates

✅ **Critical user flows** (registration, checkout, login)
```javascript
// Full user journey
1. User visits registration page
2. User fills form
3. User submits form
4. User verifies email
5. User logs in
6. User views dashboard
```

✅ **Complex multi-step workflows** (wizard, onboarding)
```javascript
// Multi-step form
1. User enters personal details
2. User navigates to next step
3. User enters address
4. User enters payment details
5. User completes form
```

✅ **Authentication flows** (login, logout, password reset)
```javascript
// Authentication flow
1. User enters email and password
2. User clicks login button
3. User is redirected to dashboard
4. User logs out
```

### Poor Candidates

❌ **Individual UI components** (should be unit/integration tests)
```javascript
// Don't E2E test this
<Button component />
<Input component />
<Dropdown component />
```

❌ **API endpoints** (should be integration tests)
```javascript
// Don't E2E test this
GET /api/users
POST /api/users
```

❌ **Validation rules** (should be unit tests)
```javascript
// Don't E2E test this
function isValidEmail(email) { ... }
function calculateDiscount(price, isPremium) { ... }
```

---

## E2E Testing Tools

### Cypress

**Setup:**
```bash
npm install --save-dev cypress
npx cypress open
```

**Configuration (cypress.config.js):**
```javascript
const { defineConfig } = require('cypress');

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://localhost:3000',
        supportFile: 'cypress/support/e2e.js',
        specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
        viewportWidth: 1280,
        viewportHeight: 720,
    },
});
```

**Basic Test:**
```javascript
// cypress/e2e/user-registration.cy.js
describe('User Registration', () => {
    beforeEach(() => {
        cy.visit('/register');
    });

    it('should register new user', () => {
        // Fill registration form
        cy.get('input[name="name"]').type('John Doe');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('input[name="password_confirmation"]').type('SecurePass123!');

        // Submit form
        cy.get('button[type="submit"]').click();

        // Verify success
        cy.url().should('include', '/verify-email');
        cy.contains('Check your email').should('be.visible');
    });

    it('should show validation errors for invalid data', () => {
        // Submit empty form
        cy.get('button[type="submit"]').click();

        // Verify validation errors
        cy.contains('Name is required').should('be.visible');
        cy.contains('Email is required').should('be.visible');
        cy.contains('Password is required').should('be.visible');
    });

    it('should show error for invalid email format', () => {
        cy.get('input[name="email"]').type('invalid-email');
        cy.get('button[type="submit"]').click();

        cy.contains('Invalid email format').should('be.visible');
    });
});
```

**Page Object Model:**
```javascript
// cypress/support/pages/RegistrationPage.js
class RegistrationPage {
    visit() {
        cy.visit('/register');
    }

    fillName(name) {
        cy.get('input[name="name"]').clear().type(name);
    }

    fillEmail(email) {
        cy.get('input[name="email"]').clear().type(email);
    }

    fillPassword(password) {
        cy.get('input[name="password"]').clear().type(password);
    }

    fillPasswordConfirmation(password) {
        cy.get('input[name="password_confirmation"]').clear().type(password);
    }

    submit() {
        cy.get('button[type="submit"]').click();
    }

    assertEmailSent() {
        cy.url().should('include', '/verify-email');
        cy.contains('Check your email').should('be.visible');
    }
}

export default RegistrationPage;

// Test using page object
import RegistrationPage from '../support/pages/RegistrationPage';

describe('User Registration (Page Object)', () => {
    it('should register new user', () => {
        const page = new RegistrationPage();

        page.visit();
        page.fillName('John Doe');
        page.fillEmail('john@example.com');
        page.fillPassword('SecurePass123!');
        page.fillPasswordConfirmation('SecurePass123!');
        page.submit();

        page.assertEmailSent();
    });
});
```

---

### Playwright

**Setup:**
```bash
npm install --save-dev @playwright/test
npx playwright install
```

**Configuration (playwright.config.ts):**
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './e2e',
    fullyParallel: true,
    retries: 0,
    workers: process.env.CI ? 1 : undefined,
    reporter: 'html',
    use: {
        baseURL: 'http://localhost:3000',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    ],
});
```

**Basic Test:**
```typescript
import { test, expect } from '@playwright/test';

test.describe('User Registration', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/register');
    });

    test('should register new user', async ({ page }) => {
        // Fill registration form
        await page.fill('input[name="name"]', 'John Doe');
        await page.fill('input[name="email"]', 'john@example.com');
        await page.fill('input[name="password"]', 'SecurePass123!');
        await page.fill('input[name="password_confirmation"]', 'SecurePass123!');

        // Submit form
        await page.click('button[type="submit"]');

        // Verify success
        await expect(page).toHaveURL(/\/verify-email/);
        await expect(page.locator('text=Check your email')).toBeVisible();
    });

    test('should show validation errors', async ({ page }) => {
        // Submit empty form
        await page.click('button[type="submit"]');

        // Verify validation errors
        await expect(page.locator('text=Name is required')).toBeVisible();
        await expect(page.locator('text=Email is required')).toBeVisible();
        await expect(page.locator('text=Password is required')).toBeVisible();
    });
});
```

**Page Object Model:**
```typescript
// e2e/pages/RegistrationPage.ts
import { Page, Locator } from '@playwright/test';

export class RegistrationPage {
    readonly nameInput: Locator;
    readonly emailInput: Locator;
    readonly passwordInput: Locator;
    readonly passwordConfirmationInput: Locator;
    readonly submitButton: Locator;

    constructor(page: Page) {
        this.nameInput = page.locator('input[name="name"]');
        this.emailInput = page.locator('input[name="email"]');
        this.passwordInput = page.locator('input[name="password"]');
        this.passwordConfirmationInput = page.locator('input[name="password_confirmation"]');
        this.submitButton = page.locator('button[type="submit"]');
    }

    async fillName(name: string) {
        await this.nameInput.clear();
        await this.nameInput.fill(name);
    }

    async fillEmail(email: string) {
        await this.emailInput.clear();
        await this.emailInput.fill(email);
    }

    async fillPassword(password: string) {
        await this.passwordInput.clear();
        await this.passwordInput.fill(password);
    }

    async submit() {
        await this.submitButton.click();
    }

    async assertEmailSent() {
        await expect(this.page).toHaveURL(/\/verify-email/);
        await expect(this.page.locator('text=Check your email')).toBeVisible();
    }
}

// Test using page object
import { test } from '@playwright/test';
import { RegistrationPage } from '../pages/RegistrationPage';

test('should register new user', async ({ page }) => {
    const registrationPage = new RegistrationPage(page);

    await registrationPage.goto();
    await registrationPage.fillName('John Doe');
    await registrationPage.fillEmail('john@example.com');
    await registrationPage.fillPassword('SecurePass123!');
    await registrationPage.submit();

    await registrationPage.assertEmailSent();
});
```

---

## Common E2E Test Scenarios

### User Registration Flow

```javascript
// Cypress
describe('User Registration Flow', () => {
    it('should complete full registration journey', () => {
        // Step 1: Registration form
        cy.visit('/register');
        cy.get('input[name="name"]').type('John Doe');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('input[name="password_confirmation"]').type('SecurePass123!');
        cy.get('button[type="submit"]').click();

        // Step 2: Email verification (simulate)
        const verificationToken = 'mock-verification-token';
        cy.visit(`/verify/${verificationToken}`);

        // Step 3: Login
        cy.visit('/login');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('button[type="submit"]').click();

        // Step 4: Verify logged in
        cy.url().should('include', '/dashboard');
        cy.contains('Welcome, John Doe').should('be.visible');
    });
});
```

### E-commerce Checkout Flow

```javascript
// Playwright
import { test, expect } from '@playwright/test';

test.describe('E-commerce Checkout Flow', () => {
    test('should complete purchase flow', async ({ page }) => {
        // Step 1: Browse products
        await page.goto('/products');
        await page.click('.product-card:first-child');

        // Step 2: Add to cart
        await page.click('button:has-text("Add to Cart")');
        await expect(page.locator('.cart-badge')).toContainText('1');

        // Step 3: View cart
        await page.goto('/cart');
        await expect(page.locator('.cart-items')).toHaveCount(1);

        // Step 4: Checkout
        await page.click('button:has-text("Proceed to Checkout")');
        await page.fill('input[name="shipping_address"]', '123 Main St');
        await page.fill('input[name="shipping_city"]', 'London');
        await page.fill('input[name="shipping_postcode"]', 'SW1A 1AA');
        await page.click('button:has-text("Continue")');

        // Step 5: Payment
        await page.fill('input[name="card_number"]', '4111111111111111');
        await page.fill('input[name="expiry"]', '12/25');
        await page.fill('input[name="cvv"]', '123');
        await page.click('button:has-text("Place Order")');

        // Step 6: Verify order success
        await expect(page).toHaveURL(/\/order-success/);
        await expect(page.locator('.order-confirmation')).toBeVisible();

        // Step 7: Verify cart empty
        await page.goto('/cart');
        await expect(page.locator('.empty-cart')).toBeVisible();
    });
});
```

### Authentication Flow

```javascript
// Cypress
describe('Authentication Flow', () => {
    it('should login and logout', () => {
        // Login
        cy.visit('/login');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('button[type="submit"]').click();

        // Verify logged in
        cy.url().should('include', '/dashboard');
        cy.contains('Welcome, John Doe').should('be.visible');

        // Logout
        cy.get('button:has-text("Logout")').click();

        // Verify logged out
        cy.url().should('include', '/login');
        cy.contains('Welcome').should('not.exist');
    });

    it('should show error for invalid credentials', () => {
        cy.visit('/login');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('WrongPassword');
        cy.get('button[type="submit"]').click();

        cy.contains('Invalid email or password').should('be.visible');
        cy.url().should('include', '/login');  // Not redirected
    });
});
```

---

## E2E Testing Best Practices

### 1. Test Only Critical User Flows

**Good:** Focus on critical paths
```javascript
// Critical flows:
- User registration
- User login
- Checkout/purchase
- Password reset
```

### 2. Use Page Object Model

**Good:** Reusable page objects
```javascript
// pages/LoginPage.js
class LoginPage {
    getEmailInput() {
        return cy.get('input[name="email"]');
    }

    getPasswordInput() {
        return cy.get('input[name="password"]');
    }

    getSubmitButton() {
        return cy.get('button[type="submit"]');
    }

    login(email, password) {
        this.getEmailInput().type(email);
        this.getPasswordInput().type(password);
        this.getSubmitButton().click();
    }
}

export default LoginPage;
```

### 3. Wait for Elements Explicitly

**Good:** Wait for elements
```javascript
// Cypress
cy.get('.button').should('be.visible');  // Wait for visible
cy.get('.button').should('be.enabled');   // Wait for enabled

// Playwright
await page.waitForSelector('.button');
await page.waitForLoadState('networkidle');
```

### 4. Use Data-Driven Tests

**Good:** Test with multiple data sets
```javascript
const testData = [
    { email: 'valid@example.com', password: 'ValidPass123!', shouldSucceed: true },
    { email: 'invalid', password: 'ValidPass123!', shouldSucceed: false },
    { email: 'valid@example.com', password: 'short', shouldSucceed: false },
];

testData.forEach((data, index) => {
    it(`should handle test case ${index + 1}`, () => {
        cy.get('input[name="email"]').type(data.email);
        cy.get('input[name="password"]').type(data.password);
        cy.get('button[type="submit"]').click();

        if (data.shouldSucceed) {
            cy.url().should('include', '/dashboard');
        } else {
            cy.contains('Invalid credentials').should('be.visible');
        }
    });
});
```

### 5. Run E2E Tests in CI/CD

**GitHub Actions:**
```yaml
name: E2E Tests

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Start application
        run: npm start &
        run: sleep 10  # Wait for app to start

      - name: Run E2E tests
        run: npx cypress run
```

---

## E2E Testing Anti-Patterns

### ❌ "The UI-Only Test" - Testing UI Details

```javascript
// Bad - Testing UI implementation details
it('should have correct font size', () => {
    cy.get('h1').should('have.css', 'font-size', '32px');
});

it('should have correct button color', () => {
    cy.get('button').should('have.css', 'background-color', 'rgb(0, 0, 255)');
});
```

**Fix:** Test behavior, not UI details.

```javascript
// Good - Testing user behavior
it('should display welcome message', () => {
    cy.contains('Welcome').should('be.visible');
});

it('should be clickable when enabled', () => {
    cy.get('button').should('be.enabled');
});
```

### ❌ "The Implementation Leak" - Testing Internals

```javascript
// Bad - Testing API calls directly
it('should call API endpoint', () => {
    cy.intercept('GET', '/api/users').as('getUsers');
    cy.visit('/users');
    cy.wait('@getUsers');
    cy.get('@getUsers').should('have.been.called');
});
```

**Fix:** Test user-visible behavior.

```javascript
// Good - Testing what user sees
it('should display user list', () => {
    cy.visit('/users');
    cy.get('.user-card').should('have.length', 10);
});
```

### ❌ "The Brittle Test" - Tight Coupling to DOM

```javascript
// Bad - Tight coupling to DOM structure
it('should display user info', () => {
    cy.get('div > div > div > span.user-name').should('have.text', 'John Doe');
    // Will break if DOM changes!
});
```

**Fix:** Use data attributes or meaningful selectors.

```javascript
// Good - Loose coupling
it('should display user info', () => {
    cy.get('[data-testid="user-name"]').should('have.text', 'John Doe');
});
```

### ❌ "The Slow Test" - Unnecessary Waits

```javascript
// Bad - Hard-coded waits
it('should load data', () => {
    cy.visit('/dashboard');
    cy.wait(5000);  // Always wait 5 seconds!
    cy.contains('Welcome').should('be.visible');
});
```

**Fix:** Wait for specific conditions.

```javascript
// Good - Wait for specific element
it('should load data', () => {
    cy.visit('/dashboard');
    cy.contains('Welcome', { timeout: 10000 }).should('be.visible');
});
```

---

## E2E Testing Checklist

### Test Case Checklist

For each E2E test:

- [ ] **Critical Path**: Tests important user flow
- [ ] **Realistic Data**: Uses realistic test data
- [ ] **Explicit Waits**: Waits for elements, not hard-coded timeouts
- [ ] **Clean State**: Tests start with clean state
- [ ] **Error Handling**: Tests error scenarios
- [ ] **Page Objects**: Uses page object model
- [ ] **Data Attributes**: Uses data-testid selectors

### Critical Flows to Test

- [ ] User registration
- [ ] User login/logout
- [ ] Password reset
- [ ] Checkout/purchase
- [ ] Profile update
- [ ] Account deletion

---

## Summary

E2E testing verifies complete user flows:

**Characteristics:**
- Full system (UI, DB, APIs)
- User-centric (simulates real actions)
- Slow (>10s)
- Flaky (network, timing, UI changes)

**Good Candidates:**
- Critical user flows (registration, checkout, login)
- Complex multi-step workflows
- Authentication flows

**Poor Candidates:**
- Individual UI components (unit/integration tests)
- API endpoints (integration tests)
- Validation rules (unit tests)

**Best Practices:**
- Test only critical user flows
- Use page object model
- Wait for elements explicitly
- Use data-driven tests
- Run in CI/CD

**Anti-Patterns:**
- UI-only tests (testing font sizes, colors)
- Implementation leak (testing API calls)
- Brittle tests (tight DOM coupling)
- Slow tests (hard-coded waits)

Use E2E tests sparingly for critical user journeys.
