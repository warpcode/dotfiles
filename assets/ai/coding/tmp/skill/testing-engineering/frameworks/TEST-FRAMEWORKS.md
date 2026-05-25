# Test Frameworks

## Overview

Comprehensive guide to test frameworks across languages. Framework detection, setup, configuration, and common patterns.

---

## JavaScript / TypeScript

### Jest

**Detection:**
- `jest.config.js` or `jest.config.ts`
- `package.json` has `jest` in `devDependencies`
- Files: `*.test.js`, `*.spec.js`, `__tests__/` directory
- Code: `describe()`, `it()`, `test()`, `expect()`

**Installation:**
```bash
npm install --save-dev jest
# TypeScript
npm install --save-dev jest ts-jest @types/jest
```

**Configuration (jest.config.js):**
```javascript
module.exports = {
    // Test environment
    testEnvironment: 'node',  // or 'jsdom' for browser

    // Test files
    testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],

    // Coverage
    collectCoverageFrom: [
        'src/**/*.js',
        '!src/**/*.test.js',
        '!src/config/**',
    ],

    // Setup files
    setupFilesAfterEnv: ['./jest.setup.js'],

    // Transform
    transform: {
        '^.+\\.(js|jsx)$': 'babel-jest',
    },
};
```

**Basic Test:**
```javascript
describe('Calculator', () => {
    it('should add two numbers', () => {
        expect(add(2, 3)).toBe(5);
    });

    it('should subtract two numbers', () => {
        expect(subtract(5, 3)).toBe(2);
    });

    it('should handle async operations', async () => {
        const result = await fetchData();
        expect(result).toEqual({ data: 'test' });
    });
});
```

**Mocking:**
```javascript
// Mock function
const mockFn = jest.fn();
mockFn.mockReturnValue(42);
mockFn.mockResolvedValue('async');

// Mock module
jest.mock('./api');
const { fetchData } = require('./api');
fetchData.mockResolvedValue({ data: 'test' });

// Mock implementation
jest.mock('./module', () => ({
    func: jest.fn(() => 'mocked value')
}));
```

**Run Tests:**
```bash
npm test                    # Run all tests
npm test -- --watch         # Watch mode
npm test -- --coverage      # With coverage
npm test -- --testNamePattern="specific"  # Run specific test
```

---

### Vitest

**Detection:**
- `vitest.config.ts` or `vite.config.ts`
- `package.json` has `vitest` in `devDependencies`
- Code: `import { test, expect, describe } from 'vitest'`

**Installation:**
```bash
npm install --save-dev vitest
```

**Configuration (vitest.config.ts):**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        globals: true,
        environment: 'jsdom',
        coverage: {
            provider: 'v8',
            reporter: ['text', 'json', 'html'],
        },
    },
});
```

**Basic Test:**
```typescript
import { describe, it, expect } from 'vitest';

describe('Calculator', () => {
    it('should add two numbers', () => {
        expect(add(2, 3)).toBe(5);
    });

    it('should subtract two numbers', () => {
        expect(subtract(5, 3)).toBe(2);
    });
});
```

**Run Tests:**
```bash
npm run test                # Run all tests
npm run test:watch          # Watch mode
npm run test:coverage       # With coverage
```

---

### Mocha

**Detection:**
- `mocha.opts` or `.mocharc.js`
- `package.json` has `mocha` in `devDependencies`
- Code: `describe()`, `it()`, `before()`, `after()`

**Installation:**
```bash
npm install --save-dev mocha chai
```

**Basic Test:**
```javascript
const { expect } = require('chai');

describe('Calculator', () => {
    it('should add two numbers', () => {
        expect(add(2, 3)).to.equal(5);
    });

    it('should subtract two numbers', () => {
        expect(subtract(5, 3)).to.equal(2);
    });

    it('should handle async operations', async () => {
        const result = await fetchData();
        expect(result).to.deep.equal({ data: 'test' });
    });
});
```

**Run Tests:**
```bash
npx mocha                    # Run all tests
npx mocha --watch            # Watch mode
npx mocha --reporter nyc     # With coverage
```

---

### Cypress

**Detection:**
- `cypress/` directory
- `cypress.config.js` or `cypress.config.ts`
- Code: `cy.visit()`, `cy.get()`, `cy.contains()`, `cy.click()`

**Installation:**
```bash
npm install --save-dev cypress
```

**Configuration (cypress.config.js):**
```javascript
const { defineConfig } = require('cypress');

module.exports = defineConfig({
    e2e: {
        baseUrl: 'http://localhost:3000',
        supportFile: 'cypress/support/e2e.js',
    },
});
```

**Basic Test:**
```javascript
describe('User Registration', () => {
    it('should register a new user', () => {
        cy.visit('/register');

        cy.get('input[name="name"]').type('John Doe');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');

        cy.get('button[type="submit"]').click();

        cy.url().should('include', '/dashboard');
        cy.contains('Welcome, John Doe').should('be.visible');
    });
});
```

**Run Tests:**
```bash
npx cypress open             # Open interactive mode
npx cypress run             # Headless mode
```

---

### Playwright

**Detection:**
- `playwright.config.ts`
- `package.json` has `@playwright/test` in `devDependencies`
- Code: `test()`, `expect()`, `page.goto()`, `page.click()`

**Installation:**
```bash
npm install --save-dev @playwright/test
npx playwright install      # Install browsers
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
    test('should register a new user', async ({ page }) => {
        await page.goto('/register');

        await page.fill('input[name="name"]', 'John Doe');
        await page.fill('input[name="email"]', 'john@example.com');
        await page.fill('input[name="password"]', 'SecurePass123!');

        await page.click('button[type="submit"]');

        await expect(page).toHaveURL(/\/dashboard/);
        await expect(page.locator('text=Welcome, John Doe')).toBeVisible();
    });
});
```

**Run Tests:**
```bash
npx playwright test           # Run all tests
npx playwright test --ui     # UI mode
npx playwright test --headed  # Headed mode
```

---

## Python

### PyTest

**Detection:**
- `conftest.py` file
- `pytest.ini` or `pyproject.toml`
- Code: `def test_` functions, `@pytest.fixture`

**Installation:**
```bash
pip install pytest pytest-cov pytest-asyncio
```

**Configuration (pytest.ini):**
```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --cov=src
    --cov-report=html
    --cov-report=term
```

**Basic Test:**
```python
def test_add():
    assert add(2, 3) == 5

def test_subtract():
    assert subtract(5, 3) == 2

# Async test
@pytest.mark.asyncio
async def test_async_function():
    result = await fetch_data()
    assert result == {'data': 'test'}

# Parametrized test
@pytest.mark.parametrize('a,b,expected', [
    (2, 3, 5),
    (5, 10, 15),
    (0, 0, 0),
])
def test_add(a, b, expected):
    assert add(a, b) == expected
```

**Fixtures:**
```python
# conftest.py
import pytest
from app import create_app, db

@pytest.fixture
def app():
    app = create_app('testing')
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def runner(app):
    return app.test_cli_runner()
```

**Run Tests:**
```bash
pytest                    # Run all tests
pytest -v                 # Verbose
pytest --cov=src         # With coverage
pytest -k test_add        # Run specific test
pytest -x                # Stop on first failure
```

---

### unittest

**Detection:**
- Code: `import unittest`, `class Test*(unittest.TestCase)`

**Basic Test:**
```python
import unittest

class TestCalculator(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)

    def test_subtract(self):
        self.assertEqual(subtract(5, 3), 2)

    def test_async_function(self):
        import asyncio
        result = asyncio.run(fetch_data())
        self.assertEqual(result, {'data': 'test'})
```

**Run Tests:**
```bash
python -m unittest
python -m unittest discover
```

---

## PHP

### PHPUnit

**Detection:**
- `phpunit.xml` or `phpunit.xml.dist`
- `vendor/bin/phpunit`
- Code: `use PHPUnit\Framework\TestCase;`

**Installation:**
```bash
composer require --dev phpunit/phpunit
```

**Configuration (phpunit.xml):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
    bootstrap="vendor/autoload.php"
    colors="true"
>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Feature">
            <directory>tests/Feature</directory>
        </testsuite>
    </testsuites>

    <coverage>
        <include>
            <directory suffix=".php">src</directory>
        </include>
    </coverage>
</phpunit>
```

**Basic Test:**
```php
<?php

use PHPUnit\Framework\TestCase;

class CalculatorTest extends TestCase
{
    public function testAdd()
    {
        $this->assertEquals(5, add(2, 3));
    }

    public function testSubtract()
    {
        $this->assertEquals(2, subtract(5, 3));
    }

    public function testAsyncFunction()
    {
        $result = $this->await(fetchData());
        $this->assertEquals(['data' => 'test'], $result);
    }
}
```

**Run Tests:**
```bash
./vendor/bin/phpunit                     # Run all tests
./vendor/bin/phpunit --filter testAdd    # Run specific test
./vendor/bin/phpunit --coverage-html    # With coverage
```

---

### Pest

**Detection:**
- `Pest.php` or `phpunit.xml` (Pest compatible)
- `vendor/bin/pest`
- Code: `it('should ...', function () { })`

**Installation:**
```bash
composer require --dev pestphp/pest --with-all-dependencies
```

**Configuration (Pest.php):**
```php
<?php

use Pest\Plugins\Actions\Coverage;
use PHPUnit\TextUI\DefaultResultPrinter;

$plugin = Coverage::resolve();
$plugin->init();

tests()->in('tests');
```

**Basic Test:**
```php
<?php

use PHPUnit\Framework\TestCase;

it('adds two numbers', function () {
    expect(add(2, 3))->toBe(5);
});

it('subtracts two numbers', function () {
    expect(subtract(5, 3))->toBe(2);
});

it('handles async function', function () {
    $result = $this->await(fetchData());
    expect($result)->toBe(['data' => 'test']);
});

// Test suite
describe('Calculator', function () {
    it('adds numbers', function () {
        expect(add(2, 3))->toBe(5);
    });

    it('subtracts numbers', function () {
        expect(subtract(5, 3))->toBe(2);
    });
});
```

**Run Tests:**
```bash
./vendor/bin/pest                        # Run all tests
./vendor/bin/pest --filter 'adds numbers' # Run specific test
./vendor/bin/pest --coverage            # With coverage
```

---

### Codeception

**Detection:**
- `codeception.yml`
- `tests/` directory with `unit/`, `functional/`, `acceptance/` subdirectories
- Code: `class *Test extends \Codeception\Test\Unit`

**Installation:**
```bash
composer require --dev codeception/codeception
```

**Basic Test:**
```php
<?php

class CalculatorTest extends \Codeception\Test\Unit
{
    public function testAdd()
    {
        $this->assertEquals(5, add(2, 3));
    }

    public function testSubtract()
    {
        $this->assertEquals(2, subtract(5, 3));
    }
}
```

**Run Tests:**
```bash
vendor/bin/codecept run                  # Run all tests
vendor/bin/codecept run unit            # Run unit tests
vendor/bin/codecept run functional      # Run functional tests
vendor/bin/codecept run acceptance      # Run acceptance tests
```

---

## Ruby

### RSpec

**Detection:**
- `spec/` directory
- `spec_helper.rb` or `rails_helper.rb`
- Code: `describe()`, `it()`, `expect().to`

**Installation:**
```bash
bundle add rspec --group "development, test"
bundle exec rspec --init
```

**Basic Test:**
```ruby
require 'spec_helper'

describe Calculator do
  it 'adds two numbers' do
    expect(add(2, 3)).to eq(5)
  end

  it 'subtracts two numbers' do
    expect(subtract(5, 3)).to eq(2)
  end

  it 'handles async function' do
    result = await(fetch_data)
    expect(result).to eq({ 'data' => 'test' })
  end

  describe '.add' do
    it 'returns sum of two numbers' do
      expect(Calculator.add(2, 3)).to eq(5)
    end
  end
end
```

**Run Tests:**
```bash
bundle exec rspec                  # Run all tests
bundle exec rspec --tag unit       # Run unit tests
bundle exec rspec --tag integration # Run integration tests
bundle exec rspec spec/calculator_spec.rb # Run specific file
```

---

### Minitest

**Detection:**
- `test/` directory
- Code: `class Test* < Minitest::Test`

**Basic Test:**
```ruby
require 'minitest/autorun'

class TestCalculator < Minitest::Test
  def test_add
    assert_equal 5, add(2, 3)
  end

  def test_subtract
    assert_equal 2, subtract(5, 3)
  end

  def test_async_function
    result = await(fetch_data)
    assert_equal({ 'data' => 'test' }, result)
  end
end
```

**Run Tests:**
```bash
ruby -Itest test/calculator_test.rb
rails test
```

---

## Go

### Testing Package

**Detection:**
- Files: `*_test.go`
- Code: `func Test*`, `testing.T`, `assert.Equal()`

**Basic Test:**
```go
package calculator

import (
    "testing"
)

func TestAdd(t *testing.T) {
    result := Add(2, 3)
    if result != 5 {
        t.Errorf("Add(2, 3) = %d; want 5", result)
    }
}

func TestSubtract(t *testing.T) {
    result := Subtract(5, 3)
    if result != 2 {
        t.Errorf("Subtract(5, 3) = %d; want 2", result)
    }
}

// Table-driven test
func TestAddTableDriven(t *testing.T) {
    tests := []struct {
        a, b, expected int
    }{
        {2, 3, 5},
        {5, 10, 15},
        {0, 0, 0},
    }

    for _, tt := range tests {
        result := Add(tt.a, tt.b)
        if result != tt.expected {
            t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, result, tt.expected)
        }
    }
}

// Benchmark test
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(2, 3)
    }
}
```

**Run Tests:**
```bash
go test                    # Run all tests
go test -v                 # Verbose
go test -cover             # With coverage
go test -bench=.           # Run benchmarks
go test -run TestAdd       # Run specific test
```

---

## Java

### JUnit 5 (Jupiter)

**Detection:**
- `@Test` annotation
- `org.junit.jupiter.api.Test`
- Code: `@Test`, `@BeforeEach`, `@AfterEach`

**Installation (Maven):**
```xml
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.9.2</version>
    <scope>test</scope>
</dependency>
```

**Basic Test:**
```java
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    @Test
    void shouldAddTwoNumbers() {
        assertEquals(5, Calculator.add(2, 3));
    }

    @Test
    void shouldSubtractTwoNumbers() {
        assertEquals(2, Calculator.subtract(5, 3));
    }

    @Test
    void shouldThrowExceptionForInvalidInput() {
        assertThrows(IllegalArgumentException.class,
            () -> Calculator.add(null, 3)
        );
    }
}
```

**Run Tests:**
```bash
mvn test                   # Run all tests
mvn test -Dtest=CalculatorTest  # Run specific test
mvn test -Dcoverage         # With coverage (Jacoco)
```

---

### TestNG

**Detection:**
- `@Test` annotation
- `org.testng.annotations.Test`

**Basic Test:**
```java
import org.testng.annotations.Test;
import static org.testng.Assert.*;

public class CalculatorTest {

    @Test
    public void shouldAddTwoNumbers() {
        assertEquals(Calculator.add(2, 3), 5);
    }

    @Test
    public void shouldSubtractTwoNumbers() {
        assertEquals(Calculator.subtract(5, 3), 2);
    }
}
```

**Run Tests:**
```bash
mvn test
mvn test -Dtest=CalculatorTest
```

---

## C#

### xUnit

**Detection:**
- `[Fact]` or `[Theory]` attributes
- `Xunit` namespace
- Code: `[Fact]`, `Assert.Equal()`

**Installation (NuGet):**
```bash
dotnet add package xunit
dotnet add package xunit.runner.visualstudio
```

**Basic Test:**
```csharp
using Xunit;

public class CalculatorTests
{
    [Fact]
    public void ShouldAddTwoNumbers()
    {
        Assert.Equal(5, Calculator.Add(2, 3));
    }

    [Fact]
    public void ShouldSubtractTwoNumbers()
    {
        Assert.Equal(2, Calculator.Subtract(5, 3));
    }

    [Theory]
    [InlineData(2, 3, 5)]
    [InlineData(5, 10, 15)]
    [InlineData(0, 0, 0)]
    public void ShouldAddVariousNumbers(int a, int b, int expected)
    {
        Assert.Equal(expected, Calculator.Add(a, b));
    }
}
```

**Run Tests:**
```bash
dotnet test
dotnet test --filter "FullyQualifiedName~CalculatorTests"
```

---

### NUnit

**Detection:**
- `[Test]` attribute
- `NUnit.Framework` namespace
- Code: `[Test]`, `Assert.AreEqual()`

**Basic Test:**
```csharp
using NUnit.Framework;

[TestFixture]
public class CalculatorTests
{
    [Test]
    public void ShouldAddTwoNumbers()
    {
        Assert.AreEqual(5, Calculator.Add(2, 3));
    }

    [Test]
    public void ShouldSubtractTwoNumbers()
    {
        Assert.AreEqual(2, Calculator.Subtract(5, 3));
    }

    [TestCase(2, 3, 5)]
    [TestCase(5, 10, 15)]
    public void ShouldAddVariousNumbers(int a, int b, int expected)
    {
        Assert.AreEqual(expected, Calculator.Add(a, b));
    }
}
```

**Run Tests:**
```bash
dotnet test
```

---

## Summary

Choose the right framework for your language:

| Language | Unit Testing | E2E Testing | Popular Choice |
|----------|--------------|--------------|----------------|
| JavaScript | Jest, Vitest | Cypress, Playwright | Jest |
| TypeScript | Jest, Vitest | Cypress, Playwright | Vitest |
| Python | PyTest | Playwright | PyTest |
| PHP | PHPUnit, Pest | Codeception | Pest |
| Ruby | RSpec | Capybara | RSpec |
| Go | testing (built-in) | - | testing |
| Java | JUnit | Selenium | JUnit |
| C# | xUnit, NUnit | Selenium | xUnit |

Use framework detection to identify the testing setup in your codebase.
