# Clean Architecture & SOLID Principles

Reference guide for evaluating architectural boundaries and object-oriented design hygiene.

---

## 1. SOLID Principles in Practice

- **Single Responsibility Principle (SRP)**:
  - A class should have one, and only one, reason to change.
  - *Anti-Pattern*: "God classes" (e.g. `UserManager` that handles validation, password hashing, SQL persistence, email notifications, and PDF generation).
  - *Remediation*: Split into dedicated services (`UserRegistrar`, `UserNotifier`, `InvoicePdfGenerator`).

- **Open/Closed Principle (OCP)**:
  - Software entities should be open for extension, but closed for modification.
  - *Pattern*: Strategy pattern, drivers, plugin interfaces instead of giant `switch ($type)` statements.

- **Liskov Substitution Principle (LSP)**:
  - Subtypes must be substitutable for their base types without altering program correctness.

- **Interface Segregation Principle (ISP)**:
  - Clients should not be forced to depend upon interfaces that they do not use.
  - Prefer small, focused interfaces (`CanPay`, `CanRefund`) over monolithic contracts (`PaymentGatewayInterface` with 30 methods).

- **Dependency Inversion Principle (DIP)**:
  - High-level modules should not depend on low-level modules; both should depend on abstractions.
  - Depend on interfaces/contracts, resolved via Dependency Injection.

---

## 2. Common Architectural Anti-Patterns

1. **Fat Controller / Anemic Domain**:
   - Controllers accumulating 500+ lines of raw database and business logic while domain entities are mere passive property bags.
2. **Leaky Infrastructure**:
   - HTTP Request/Response objects passed directly into domain models or database repositories.
3. **Hidden Dependencies**:
   - Direct calls to global singletons or static state (`App::make()`, `new ConcreteService()`) inside business logic instead of constructor injection.

