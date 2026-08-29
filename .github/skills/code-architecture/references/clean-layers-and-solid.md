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

---

## 3. Frontend API Client Abstractions

Audit centralized HTTP clients, API client wrappers, and network middleware to ensure proper architectural abstraction between UI components and backend communication:

1. **Centralized HTTP Client Instances**:
   - Ensure all frontend API requests route through a single, configured HTTP client instance (e.g., custom Axios instance `api.ts`, Fetch wrapper, or Ky instance) rather than scattered `fetch()` or `axios` calls across UI components.
   - Verify Base URL resolution and environment-specific variable configuration (e.g., `VITE_API_URL`, `process.env.NEXT_PUBLIC_API_URL`).
2. **CSRF & Security Token Interceptors**:
   - Audit automatic CSRF token extraction and header injection for session-authenticated single-page apps (e.g., `X-XSRF-TOKEN` cookie extraction to `X-CSRF-TOKEN` header).
   - Verify proper credentials handling (`withCredentials: true` or `credentials: 'include'`) across CORS and same-origin requests.
3. **Authentication Token Injection**:
   - Inspect request interceptors for dynamic Bearer token attachment (`Authorization: Bearer <token>`).
   - Audit token refresh lifecycles (intercepting `401 Unauthorized` responses to refresh tokens and retry failed requests).
4. **Error Handling & Response Normalization**:
   - Audit response interceptors for standardized error transformation (normalizing backend validation errors, e.g. RFC 7807 Problem Details or Laravel 422 JSON, into predictable client structures).
   - Check global exception hooks (displaying toast notifications on 500 errors, redirecting to login on 401).
5. **API Service Layer Encapsulation**:
   - Ensure UI components consume typed domain API services (e.g. `UserService.list()`, TanStack Query hooks, Pinia/Vuex actions) rather than calling HTTP clients directly.
