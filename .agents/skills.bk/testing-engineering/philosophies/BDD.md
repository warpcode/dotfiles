# Behavior-Driven Development (BDD)

## Overview

Comprehensive guide to Behavior-Driven Development methodology. BDD extends TDD by focusing on system behavior from the perspective of stakeholders, using natural language (Gherkin) to define specifications that serve as documentation and tests.

## Core Principles

### BDD Philosophy

> **Specification → Implementation**

- Write specifications in plain language (Given-When-Then)
- Specifications are executable tests
- Collaboration between developers, QA, and business stakeholders
- Living documentation of system behavior

### Gherkin Syntax

```gherkin
Feature: User Registration
  As a user
  I want to register an account
  So that I can access the system

  Scenario: Successful registration
    Given I am on the registration page
    When I enter valid registration details
    And I submit the registration form
    Then I should see a success message
    And I should be redirected to the dashboard
    And I should receive a confirmation email
```

---

## Gherkin Syntax Reference

### Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| `Feature` | High-level feature description | `Feature: User Login` |
| `Scenario` | Specific test case | `Scenario: Login with valid credentials` |
| `Given` | Initial context | `Given I am logged in as admin` |
| `When` | Action taken | `When I click "Delete"` |
| `Then` | Expected outcome | `Then I should see "Deleted successfully"` |
| `And` | Additional steps | `And I should see a confirmation modal` |
| `But` | Negative step | `But I should not see "Error"` |
| `Background` | Common steps for all scenarios | `Background: User is authenticated` |
| `Scenario Outline` | Data-driven tests | `Scenario Outline: Different login cases` |
| `Examples` | Test data table | `Examples: \| username \| password \|` |

---

## Feature File Examples

### Basic Feature

```gherkin
Feature: User Authentication

  Background:
    Given the user database is empty

  Scenario: User logs in with valid credentials
    Given I am on the login page
    When I enter username "john@example.com"
    And I enter password "SecurePass123!"
    And I click "Login"
    Then I should be redirected to "/dashboard"
    And I should see "Welcome, John"

  Scenario: User logs in with invalid credentials
    Given I am on the login page
    When I enter username "john@example.com"
    And I enter password "WrongPassword"
    And I click "Login"
    Then I should see "Invalid username or password"
    And I should remain on the login page

  Scenario: User logs in with empty fields
    Given I am on the login page
    When I leave username empty
    And I leave password empty
    And I click "Login"
    Then I should see "Username and password are required"
```

### Scenario Outline (Data-Driven)

```gherkin
Feature: Password Validation

  Scenario Outline: Password strength validation
    Given I am on the registration page
    When I enter password "<password>"
    And I click "Register"
    Then I should see "<error_message>"

    Examples:
      | password      | error_message                           |
      | short         | Password must be at least 8 characters |
      | nouppercase   | Password must contain uppercase letter    |
      | NOLOWERCASE   | Password must contain lowercase letter    |
      | NoNumber123   | Password must contain a number           |
      | NoSpecialChar | Password must contain special character   |
```

### Complex Feature with Background

```gherkin
Feature: E-commerce Checkout

  Background:
    Given I am a registered user
    And I have products in my cart:
      | product  | quantity | price |
      | Laptop   | 1         | 999    |
      | Mouse    | 2         | 25     |
    And I am on the checkout page

  Scenario: Successful checkout with credit card
    When I select "Credit Card" as payment method
    And I enter card number "4111111111111111"
    And I enter expiry "12/25"
    And I enter CVV "123"
    And I enter billing address
    And I click "Place Order"
    Then I should see "Order placed successfully"
    And I should receive order confirmation email
    And my cart should be empty
    And I should see order "<order_number>"

  Scenario: Checkout fails with invalid card
    When I select "Credit Card" as payment method
    And I enter card number "4111111111111112"
    And I enter expiry "12/25"
    And I enter CVV "123"
    And I click "Place Order"
    Then I should see "Payment declined"
    And I should remain on checkout page
    And my cart should retain items

  Scenario: Checkout with PayPal
    When I select "PayPal" as payment method
    And I click "Place Order"
    Then I should be redirected to PayPal
    When I complete PayPal payment
    Then I should see "Order placed successfully"
    And my cart should be empty
```

---

## BDD Frameworks

### Cucumber (JavaScript/TypeScript)

**Installation:**
```bash
npm install --save-dev @cucumber/cucumber
```

**Feature File:** `features/user-login.feature`
```gherkin
Feature: User Login

  Scenario: User logs in successfully
    Given I am on the login page
    When I enter username "john@example.com"
    And I enter password "SecurePass123!"
    And I click "Login"
    Then I should be redirected to dashboard
```

**Step Definitions:** `features/step-definitions/login.steps.js`
```javascript
const { Given, When, Then } = require('@cucumber/cucumber');
const { expect } = require('@playwright/test');

Given('I am on the login page', async function () {
    await this.page.goto('http://localhost:3000/login');
});

When('I enter username {string}', async function (username) {
    await this.page.fill('input[name="username"]', username);
});

When('I enter password {string}', async function (password) {
    await this.page.fill('input[name="password"]', password);
});

When('I click {string}', async function (button) {
    await this.page.click(`button:has-text("${button}")`);
});

Then('I should be redirected to dashboard', async function () {
    await this.page.waitForURL('**/dashboard');
    expect(this.page.url()).toContain('/dashboard');
});
```

**World Setup:** `features/support/world.js`
```javascript
const { chromium } = require('@playwright/test');

module.exports = function () {
    this.browser = null;
    this.page = null;

    this.BeforeAll(async () => {
        this.browser = await chromium.launch();
    });

    this.AfterAll(async () => {
        if (this.browser) {
            await this.browser.close();
        }
    });

    this.Before(async () => {
        this.page = await this.browser.newPage();
    });

    this.After(async () => {
        if (this.page) {
            await this.page.close();
        }
    });
};
```

**Run Tests:**
```bash
npx cucumber-js
```

---

### Behave (Python)

**Installation:**
```bash
pip install behave
```

**Feature File:** `features/user-login.feature`
```gherkin
Feature: User Login

  Scenario: User logs in successfully
    Given I am on the login page
    When I enter username "john@example.com"
    When I enter password "SecurePass123!"
    When I click "Login"
    Then I should be redirected to dashboard
```

**Step Definitions:** `features/steps/login_steps.py`
```python
from behave import given, when, then
from playwright.sync_api import sync_playwright

@given('I am on the login page')
def step_impl(context):
    context.page.goto('http://localhost:3000/login')

@when('I enter username "{username}"')
def step_impl(context, username):
    context.page.fill('input[name="username"]', username)

@when('I enter password "{password}"')
def step_impl(context, password):
    context.page.fill('input[name="password"]', password)

@when('I click "{button}"')
def step_impl(context, button):
    context.page.click(f'button:has-text("{button}")')

@then('I should be redirected to dashboard')
def step_impl(context):
    context.page.wait_for_url('**/dashboard')
    assert '/dashboard' in context.page.url
```

**Environment Setup:** `features/environment.py`
```python
from behave import fixture
from playwright.sync_api import sync_playwright

@fixture
def browser(context):
    with sync_playwright() as p:
        browser = p.chromium.launch()
        context.browser = browser
        yield browser
        browser.close()

@fixture
def page(context, browser):
    page = browser.new_page()
    context.page = page
    yield page
    page.close()

@before_scenario
def before_scenario(context, scenario):
    context.page = context.browser.new_page()

@after_scenario
def after_scenario(context, scenario):
    context.page.close()
```

**Run Tests:**
```bash
behave
```

---

### Behat (PHP)

**Installation:**
```bash
composer require --dev behat/behat
composer require --dev friends-of-behat/mink-extension
composer require --dev friends-of-behat/mink-browserkit-driver
```

**Feature File:** `features/user-login.feature`
```gherkin
Feature: User Login

  Scenario: User logs in successfully
    Given I am on the login page
    When I enter username "john@example.com"
    When I enter password "SecurePass123!"
    When I click "Login"
    Then I should be redirected to dashboard
```

**Context File:** `features/bootstrap/FeatureContext.php`
```php
<?php

use Behat\Behat\Context\Context;
use Behat\MinkExtension\Context\MinkContext;

class FeatureContext extends MinkContext implements Context
{
    /**
     * @Given I am on the login page
     */
    public function iAmOnTheLoginPage()
    {
        $this->visitPath('/login');
    }

    /**
     * @When I enter username :username
     */
    public function iEnterUsername($username)
    {
        $this->fillField('username', $username);
    }

    /**
     * @When I enter password :password
     */
    public function iEnterPassword($password)
    {
        $this->fillField('password', $password);
    }

    /**
     * @When I click :button
     */
    public function iClick($button)
    {
        $this->pressButton($button);
    }

    /**
     * @Then I should be redirected to dashboard
     */
    public function iShouldBeRedirectedToDashboard()
    {
        $this->assertPageAddress('/dashboard');
    }
}
```

**Configuration:** `behat.yml`
```yaml
default:
    extensions:
        Behat\MinkExtension:
            base_url: 'http://localhost:8000'
            sessions:
                default:
                    goutte: ~
```

**Run Tests:**
```bash
./vendor/bin/behat
```

---

### RSpec + Cucumber (Ruby)

**Installation:**
```bash
gem install cucumber-rails
```

**Feature File:** `features/user-login.feature`
```gherkin
Feature: User Login

  Scenario: User logs in successfully
    Given I am on the login page
    When I enter username "john@example.com"
    When I enter password "SecurePass123!"
    When I click "Login"
    Then I should be redirected to dashboard
```

**Step Definitions:** `features/step_definitions/login_steps.rb`
```ruby
Given('I am on the login page') do
  visit login_path
end

When('I enter username {string}') do |username|
  fill_in 'username', with: username
end

When('I enter password {string}') do |password|
  fill_in 'password', with: password
end

When('I click {string}') do |button|
  click_button button
end

Then('I should be redirected to dashboard') do
  expect(current_path).to eq dashboard_path
end
```

**Run Tests:**
```bash
cucumber
```

---

## BDD Best Practices

### 1. Write Features First

Before writing any code, write the feature file. This forces you to think about behavior.

### 2. Use Business Language

Write features in language understood by stakeholders, not developers.

```gherkin
// ✅ Good - Business language
When I place an order
Then I should receive a confirmation email

// ❌ Bad - Technical language
When I call OrderService.createOrder()
Then EmailService.sendConfirmation() should be called
```

### 3. Keep Scenarios Independent

Each scenario should be independent and can run in any order.

### 4. Use Descriptive Feature Names

```gherkin
// ✅ Good - Clear feature name
Feature: User Registration and Email Verification

// ❌ Bad - Unclear feature name
Feature: User Stuff
```

### 5. Use Tables for Data

```gherkin
// ✅ Good - Table for data
Given I have the following products in my cart:
  | product  | quantity | price |
  | Laptop   | 1         | 999    |
  | Mouse    | 2         | 25     |

// ❌ Bad - Multiple Given steps
Given I have 1 Laptop for £999 in my cart
And I have 2 Mouse for £25 in my cart
```

### 6. Avoid "And" Overuse

Too many "And" steps indicate a scenario is doing too much.

```gherkin
// ❌ Bad - Too many Ands
Given I am logged in
And I have products in cart
And I go to checkout
And I enter shipping details
And I enter billing details
And I select payment method
And I confirm order
Then I should see success
And I should receive email

// ✅ Good - Break into smaller scenarios
Scenario: Checkout with saved address
  Given I am logged in
  And I have products in cart
  When I go to checkout
  And I use saved address
  And I select payment method
  And I confirm order
  Then I should see success
  And I should receive email
```

### 7. Use Tags for Organization

```gherkin
@smoke
@authentication
Feature: User Login

  @happy-path
  Scenario: User logs in successfully
    ...

  @negative
  Scenario: User fails with wrong password
    ...
```

Run specific tags:
```bash
# Run only smoke tests
behave --tags=@smoke

# Run all but slow tests
behave --tags=~@slow

# Run multiple tags
behave --tags=@smoke --tags=@authentication
```

---

## BDD Anti-Patterns

### ❌ "The UI-Only" - Tests only UI, not behavior

```gherkin
// Bad - Tests UI, not business logic
When I click the submit button
And the page loads in 2 seconds
And the button changes color
Then I see the form on the screen
```

**Fix:** Focus on behavior, not UI details.

```gherkin
// Good - Tests behavior
When I submit the registration form
Then my account should be created
And I should be logged in
```

### ❌ "The Scenario Giant" - Single scenario with too many steps

```gherkin
// Bad - Too many steps
Scenario: Complete user journey
  Given I register as a new user
  And I verify my email
  And I complete my profile
  And I add payment method
  And I browse products
  And I add products to cart
  And I checkout
  And I track my order
  And I write a review
  Then I should be happy
```

**Fix:** Break into smaller, focused scenarios.

### ❌ "The Given/When/Then Mismatch" - Misuse of keywords

```gherkin
// Bad - When/Then mixed up
Given I click the login button
When I should see the dashboard
Then I entered my password
```

**Fix:** Use keywords correctly.

```gherkin
// Good - Proper keyword usage
Given I am on the login page
When I enter my password and click login
Then I should see the dashboard
```

---

## BDD Workflow

### 1. Three Amigos Meeting

Bring together developer, QA, and business stakeholder to write feature file together.

### 2. Write Feature File

Write the feature in Gherkin syntax with all scenarios.

### 3. Implement Step Definitions

Write code to execute the Gherkin steps.

### 4. Run Tests (Failing)

Run the tests - they should fail (red).

### 5. Implement Code

Write production code to make tests pass (green).

### 6. Refactor

Improve code while keeping tests passing.

### 7. Repeat

Add more scenarios and iterate.

---

## Summary

BDD focuses on behavior specification:
- Use Gherkin syntax (Given-When-Then)
- Write features in business language
- Features serve as living documentation
- Collaboration between developers, QA, stakeholders

**Best Practices:**
- Write features first
- Use business language
- Keep scenarios independent
- Use tables for data
- Use tags for organization

**Frameworks:**
- JavaScript: Cucumber.js
- Python: Behave
- PHP: Behat
- Ruby: Cucumber-Ruby

Use BDD to bridge the gap between business requirements and technical implementation.
