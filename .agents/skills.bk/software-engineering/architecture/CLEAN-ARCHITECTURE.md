# CLEAN ARCHITECTURE

## OVERVIEW
Clean Architecture is a set of principles for organizing code into layers with dependencies pointing inward toward the business logic.

## CORE PRINCIPLES

### Dependency Rule

**Rule**: Source code dependencies can only point inward. Nothing in an inner circle can know anything about an outer circle.

**Layers (Outside → Inside)**:
```
┌─────────────────────────────────────────────┐
│           Frameworks & Drivers             │  ← UI, Web, Database, Frameworks
├─────────────────────────────────────────────┤
│              Interface Adapters             │  ← Controllers, Presenters, Gateways
├─────────────────────────────────────────────┤
│                 Use Cases                │  ← Application business rules
├─────────────────────────────────────────────┤
│              Entities                    │  ← Enterprise business rules
└─────────────────────────────────────────────┘
```

**Key Points**:
- Entities: Core business rules (no frameworks)
- Use Cases: Application-specific business rules
- Interface Adapters: Convert data between layers
- Frameworks/Drivers: External systems (database, UI, frameworks)

---

## ENTITY LAYER (Core Business Rules)

**Definition**: Enterprise-wide business rules. These rules would exist even without the application.

**Characteristics**:
- Framework-agnostic
- No dependencies on UI, database, or frameworks
- Pure business logic
- Testable without infrastructure

**Example**:
```php
// Entity: Core business rules
class Order {
    private array $items = [];
    private float $total = 0;

    public function addItem(string $name, float $price, int $quantity): void {
        $item = new OrderItem($name, $price, $quantity);
        $this->items[] = $item;
        $this->total += $price * $quantity;
    }

    public function canBeCompleted(): bool {
        return count($this->items) > 0 && $this->total > 0;
    }

    public function getTotal(): float {
        return $this->total;
    }
}

class OrderItem {
    public function __construct(
        public string $name,
        public float $price,
        public int $quantity
    ) {
        if ($quantity < 1) {
            throw new InvalidArgumentException('Quantity must be at least 1');
        }
        if ($price < 0) {
            throw new InvalidArgumentException('Price cannot be negative');
        }
    }
}
```

---

## USE CASE LAYER (Application Business Rules)

**Definition**: Application-specific business rules. Orchestrate entities to achieve goals.

**Characteristics**:
- Define application behavior
- Orchestrate entities
- No framework dependencies
- Depend on entities, not on infrastructure

**Example**:
```php
// Use Case: Application business rules
class CreateOrderUseCase {
    public function __construct(
        private OrderRepository $repository,
        private InventoryService $inventory
    ) { }

    public function execute(array $orderData): Order {
        $order = new Order();

        foreach ($orderData['items'] as $item) {
            // Check inventory
            if (!$this->inventory->isAvailable($item['name'], $item['quantity'])) {
                throw new OutOfStockException($item['name']);
            }

            $order->addItem(
                $item['name'],
                $item['price'],
                $item['quantity']
            );
        }

        if (!$order->canBeCompleted()) {
            throw new InvalidOrderException('Order is empty or invalid');
        }

        $this->repository->save($order);

        return $order;
    }
}
```

---

## INTERFACE ADAPTER LAYER

**Definition**: Convert data between use cases and external systems.

**Controllers**: Handle input from UI/Web
**Presenters**: Format output for UI/Web
**Gateways**: Communicate with external systems (database, APIs)

### Controller Example
```php
// Controller: Web/REST input
class CreateOrderController {
    public function __construct(
        private CreateOrderUseCase $useCase
    ) { }

    public function create(Request $request): JsonResponse {
        try {
            $orderData = $request->json()->all();

            // Convert to use case input format
            $useCaseInput = $this->transformInput($orderData);

            $order = $this->useCase->execute($useCaseInput);

            return new JsonResponse([
                'status' => 'success',
                'order_id' => $order->getId(),
                'total' => $order->getTotal()
            ], 201);

        } catch (OutOfStockException $e) {
            return new JsonResponse([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 400);
        }
    }

    private function transformInput(array $data): array {
        return [
            'items' => array_map(fn($item) => [
                'name' => $item['product_name'],
                'price' => (float) $item['price'],
                'quantity' => (int) $item['qty']
            ], $data['line_items'])
        ];
    }
}
```

### Gateway Example
```php
// Gateway: Database access
class DatabaseOrderRepository implements OrderRepository {
    public function __construct(private PDO $db) { }

    public function save(Order $order): void {
        $stmt = $this->db->prepare("
            INSERT INTO orders (total, created_at)
            VALUES (?, NOW())
        ");
        $stmt->execute([$order->getTotal()]);

        $orderId = $this->db->lastInsertId();

        foreach ($order->getItems() as $item) {
            $stmt = $this->db->prepare("
                INSERT INTO order_items (order_id, name, price, quantity)
                VALUES (?, ?, ?, ?)
            ");
            $stmt->execute([
                $orderId,
                $item->name,
                $item->price,
                $item->quantity
            ]);
        }
    }

    public function findById(int $id): ?Order {
        // Fetch and reconstruct Order entity
    }
}
```

---

## FRAMEWORKS & DRIVERS LAYER

**Definition**: External systems, frameworks, UI. The outermost layer.

**Characteristics**:
- Contains least amount of code
- Frameworks are tools, not architecture
- Can be replaced without affecting business rules

### Database Schema (PostgreSQL)
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL
);
```

---

## BENEFITS OF CLEAN ARCHITECTURE

### 1. Testability
- Business rules can be tested without UI, database, or frameworks
- Use cases testable with mock repositories
- No need to spin up external systems

### 2. Independence of Frameworks
- Can switch frameworks without changing business rules
- Laravel → Symfony → Custom framework: No change to entities/use cases
- Database changes affect only gateway layer

### 3. Independence of Database
- Business rules don't care about database
- Can switch MySQL → PostgreSQL → MongoDB without touching entities
- Use cases remain unchanged

### 4. Independence of UI
- Business logic doesn't know about web, mobile, CLI
- Can add new interfaces without changing core
- Web, mobile, CLI all share same use cases

### 5. Independent of External Agencies
- Business rules don't know about payment gateways, email services
- External services abstracted behind interfaces
- Can switch Stripe → PayPal without business logic changes

---

## DEPENDENCY INVERSION IN PRACTICE

**Before (Dependencies point outward)**:
```php
// BAD: Use case depends on concrete implementations
class CreateOrderUseCase {
    public function __construct() {
        $this->db = new MySQLDatabase();
        $this->email = new SendGridEmail();
    }
}
```

**After (Dependencies point inward)**:
```php
// GOOD: Use case depends on abstractions
class CreateOrderUseCase {
    public function __construct(
        private OrderRepository $repository,  // Abstraction
        private EmailService $emailService  // Abstraction
    ) { }
}

// Dependency injection provides concrete implementations
class MySQLOrderRepository implements OrderRepository { }
class SendGridEmailService implements EmailService { }
```

---

## SEPARATION OF CONCERNS

### What goes where?

| Concern | Layer | Example |
|---------|--------|---------|
| Business rules (enterprise) | Entities | Order entity with validation |
| Business rules (application) | Use Cases | CreateOrderUseCase orchestration |
| Data access | Gateways | DatabaseOrderRepository |
| Input handling | Controllers | CreateOrderController |
| Output formatting | Presenters | OrderJsonPresenter |
| External APIs | Gateways | StripePaymentGateway |
| UI/Web | Frameworks | Laravel routes, controllers |

---

## COMMON MISTAKES

### 1. Putting Business Logic in Controllers
**BAD**:
```php
class OrderController {
    public function create(Request $request) {
        // Business logic in controller!
        $total = 0;
        foreach ($request->items as $item) {
            $total += $item['price'] * $item['qty'];
        }
        if ($total > 1000) {
            // Apply discount
        }
        $this->db->insert('orders', [...]);
    }
}
```

**GOOD**:
```php
class CreateOrderController {
    public function create(Request $request) {
        $order = $this->createOrderUseCase->execute(
            $request->json()->all()
        );
        return response()->json($order);
    }
}
```

### 2. Entities Knowing About Infrastructure
**BAD**:
```php
class Order {
    public function save() {
        // Entity knows about database!
        DB::table('orders')->insert([...]);
    }
}
```

**GOOD**:
```php
class Order {
    // Pure business logic only
}

class OrderRepository {
    public function save(Order $order) {
        DB::table('orders')->insert([...]);
    }
}
```

### 3. Use Cases Containing Framework Logic
**BAD**:
```php
class CreateOrderUseCase {
    public function execute($data) {
        // Use case contains framework logic!
        return response()->json([...]);
    }
}
```

**GOOD**:
```php
class CreateOrderUseCase {
    public function execute($data): Order {
        // Pure business logic
        return $order;
    }
}
```

---

## CROSS-REFERENCES
- For SOLID principles: @principles/SOLID.md
- For design patterns: @patterns/DESIGN-PATTERNS.md
- For SOLID violations: @design/DESIGN-VIOLATIONS.md
