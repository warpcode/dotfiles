# Design Patterns & Selection Criteria

Practical reference for selecting, implementing, and auditing modern Gang of Four (GoF) design patterns across creational, structural, and behavioral domains.

---

## 1. Pattern Decision Matrix

| Pattern | Category | Primary Intent | When to Use | Typical Pitfalls |
|---|---|---|---|---|
| **Factory** | Creational | Centralize instantiation without exposing concrete classes | Creation logic depends on configuration, runtime parameters, or polymorphic types | Over-engineering when simple `new` suffices; switch smell inside factory |
| **Builder** | Creational | Construct complex objects step-by-step with fluent interface | Objects with many optional parameters, invariants, or multi-step validation | Verbosity for simple DTOs; mutable state leaks during build |
| **Adapter** | Structural | Convert incompatible interface into expected target interface | Integrating legacy code, third-party libraries, or external SDKs | Performance overhead from redundant translation layers |
| **Decorator** | Structural | Dynamically attach additional responsibilities to objects | Extending behavior without class inheritance explosions (e.g. caching, logging) | Deeply nested decorator stacks making debugging and stack traces obscure |
| **Facade** | Structural | Provide unified, simplified high-level interface to complex subsystem | Masking complicated multi-service orchestration behind clean API | "God Facade" accumulating domain logic instead of purely delegating |
| **Strategy** | Behavioral | Define family of interchangeable algorithms selected at runtime | Replacing branching conditionals (`switch`/`match`) with polymorphic strategies | Client must be aware of differences between strategies |
| **Observer** | Behavioral | One-to-many subscription notification upon state change | Decoupling event producers from event consumers (Domain Events, Webhooks) | Memory leaks from un-detached listeners; unpredictable event ordering |
| **Command** | Behavioral | Encapsulate request as standalone object with execution and undo logic | Queued jobs, transactional rollbacks, CLI commands, macro recording | High class count for simple one-off operations |

---

## 2. Creational Patterns

### Factory Pattern
Decouples client code from concrete implementations by delegating instantiation to dedicated factory methods or classes.

```php
interface PaymentGateway {
    public function charge(int $amountInCents, string $currency): PaymentResult;
}

final class StripeGateway implements PaymentGateway {
    public function charge(int $amountInCents, string $currency): PaymentResult {
        // Stripe API integration
        return new PaymentResult(success: true, transactionId: 'ch_stripe_' . bin2hex(random_bytes(4)));
    }
}

final class PayPalGateway implements PaymentGateway {
    public function charge(int $amountInCents, string $currency): PaymentResult {
        // PayPal API integration
        return new PaymentResult(success: true, transactionId: 'PAYPAL-' . bin2hex(random_bytes(4)));
    }
}

final class PaymentGatewayFactory {
    /** @param array<string, class-string<PaymentGateway>> $gatewayMap */
    public function __construct(private array $gatewayMap = []) {}

    public function make(string $provider): PaymentGateway {
        $gatewayClass = $this->gatewayMap[$provider] ?? match ($provider) {
            'stripe' => StripeGateway::class,
            'paypal' => PayPalGateway::class,
            default  => throw new InvalidArgumentException("Unsupported payment gateway: {$provider}"),
        };

        return new $gatewayClass();
    }
}
```

### Builder Pattern
Separates object construction from representation, allowing step-by-step configuration of complex immutable objects.

```typescript
export interface QueryConfig {
  readonly table: string;
  readonly fields: readonly string[];
  readonly filters: ReadonlyArray<{ field: string; op: string; value: unknown }>;
  readonly limit?: number;
  readonly offset?: number;
}

export class QueryBuilder {
  private fields: string[] = ['*'];
  private filters: Array<{ field: string; op: string; value: unknown }> = [];
  private limitCount?: number;
  private offsetCount?: number;

  constructor(private readonly table: string) {
    if (!table) throw new Error('Table name is required');
  }

  select(...fields: string[]): this {
    this.fields = fields.length > 0 ? fields : ['*'];
    return this;
  }

  where(field: string, op: string, value: unknown): this {
    this.filters.push({ field, op, value });
    return this;
  }

  paginate(limit: number, offset: number = 0): this {
    if (limit <= 0) throw new RangeError('Limit must be greater than zero');
    this.limitCount = limit;
    this.offsetCount = offset;
    return this;
  }

  build(): QueryConfig {
    return Object.freeze({
      table: this.table,
      fields: Object.freeze([...this.fields]),
      filters: Object.freeze([...this.filters]),
      limit: this.limitCount,
      offset: this.offsetCount,
    });
  }
}
```

---

## 3. Structural Patterns

### Adapter Pattern
Wraps an incompatible service or third-party interface so clients can interact with it through a standard contract.

```php
// Target Domain Interface
interface SmsNotifier {
    public function sendSms(string $recipientPhone, string $message): bool;
}

// Incompatible Third-Party SDK
final class TwilioSdkClient {
    public function dispatchMessage(array $payload): array {
        // e.g. ['to' => '+1234567890', 'body' => '...', 'from' => '...']
        return ['status' => 'delivered', 'sid' => 'SM123'];
    }
}

// Adapter
final class TwilioSmsAdapter implements SmsNotifier {
    public function __construct(
        private TwilioSdkClient $client,
        private string $fromNumber
    ) {}

    public function sendSms(string $recipientPhone, string $message): bool {
        $response = $this->client->dispatchMessage([
            'to'   => $recipientPhone,
            'body' => $message,
            'from' => $this->fromNumber,
        ]);

        return ($response['status'] ?? '') === 'delivered';
    }
}
```

### Decorator Pattern
Attaches additional responsibilities dynamically using object composition rather than inheritance.

```typescript
export interface DataRepository<T> {
  findById(id: string): Promise<T | null>;
}

export class SqlDataRepository<T> implements DataRepository<T> {
  async findById(id: string): Promise<T | null> {
    // Database query execution
    return null;
  }
}

export class CachedDataRepository<T> implements DataRepository<T> {
  constructor(
    private readonly inner: DataRepository<T>,
    private readonly cache: Map<string, T>,
    private readonly ttlMs: number = 60000
  ) {}

  async findById(id: string): Promise<T | null> {
    if (this.cache.has(id)) {
      return this.cache.get(id) ?? null;
    }
    const item = await this.inner.findById(id);
    if (item !== null) {
      this.cache.set(id, item);
    }
    return item;
  }
}
```

### Facade Pattern
Provides a simplified, high-level interface over a complex subsystem of microservices or domain classes.

```php
final class OrderCheckoutFacade {
    public function __construct(
        private InventoryService $inventory,
        private PaymentGatewayFactory $paymentFactory,
        private InvoiceGenerator $invoices,
        private EventDispatcher $events
    ) {}

    public function placeOrder(Customer $customer, Cart $cart, string $paymentMethod): OrderResult {
        $this->inventory->reserveStock($cart->items());

        $gateway = $this->paymentFactory->make($paymentMethod);
        $payment = $gateway->charge($cart->totalInCents(), 'USD');

        if (!$payment->isSuccessful()) {
            $this->inventory->releaseStock($cart->items());
            throw new PaymentFailedException($payment->errorMessage());
        }

        $invoice = $this->invoices->generate($customer, $cart, $payment->transactionId());
        $this->events->notify('order.placed', new OrderPlacedEvent($customer, $cart, $invoice));

        return new OrderResult(success: true, invoiceId: $invoice->id());
    }
}
```

---

## 4. Behavioral Patterns

### Strategy Pattern
Encapsulates a family of algorithms, making them interchangeable at runtime based on business rules or tenant configuration.

```python
from abc import ABC, abstractmethod
from decimal import Decimal

class TaxCalculationStrategy(ABC):
    @abstractmethod
    def calculate_tax(self, subtotal: Decimal) -> Decimal:
        pass

class USTaxStrategy(TaxCalculationStrategy):
    def __init__(self, state_rate: Decimal):
        self.state_rate = state_rate

    def calculate_tax(self, subtotal: Decimal) -> Decimal:
        return subtotal * self.state_rate

class EUTaxStrategy(TaxCalculationStrategy):
    def __init__(self, vat_rate: Decimal = Decimal('0.20')):
        self.vat_rate = vat_rate

    def calculate_tax(self, subtotal: Decimal) -> Decimal:
        return subtotal * self.vat_rate

class TaxCalculator:
    def __init__(self, strategy: TaxCalculationStrategy):
        self._strategy = strategy

    def set_strategy(self, strategy: TaxCalculationStrategy) -> None:
        self._strategy = strategy

    def compute(self, subtotal: Decimal) -> Decimal:
        return self._strategy.calculate_tax(subtotal)
```

### Observer Pattern
Defines a publish-subscribe dependency so that when one object changes state, all registered observers are notified automatically.

```php
interface DomainEventObserver {
    public function handle(string $eventName, object $eventData): void;
}

final class EventDispatcher {
    /** @var array<string, list<DomainEventObserver>> */
    private array $listeners = [];

    public function subscribe(string $eventName, DomainEventObserver $observer): void {
        $this->listeners[$eventName][] = $observer;
    }

    public function unsubscribe(string $eventName, DomainEventObserver $observer): void {
        if (!isset($this->listeners[$eventName])) {
            return;
        }
        $this->listeners[$eventName] = array_values(
            array_filter($this->listeners[$eventName], fn($o) => $o !== $observer)
        );
    }

    public function notify(string $eventName, object $eventData): void {
        foreach ($this->listeners[$eventName] ?? [] as $observer) {
            $observer->handle($eventName, $eventData);
        }
    }
}
```

### Command Pattern
Encapsulates all information needed to perform an action or trigger an event at a later time, supporting undo/redo and transactional rollback.

```typescript
export interface Command {
  execute(): Promise<void>;
  undo(): Promise<void>;
}

export class CreateUserCommand implements Command {
  private createdUserId?: string;

  constructor(
    private readonly userRepository: UserRepository,
    private readonly userData: UserDto
  ) {}

  async execute(): Promise<void> {
    const user = await this.userRepository.create(this.userData);
    this.createdUserId = user.id;
  }

  async undo(): Promise<void> {
    if (this.createdUserId) {
      await this.userRepository.deleteById(this.createdUserId);
      this.createdUserId = undefined;
    }
  }
}

export class CommandInvoker {
  private readonly history: Command[] = [];

  async run(command: Command): Promise<void> {
    await command.execute();
    this.history.push(command);
  }

  async rollback(): Promise<void> {
    const lastCommand = this.history.pop();
    if (lastCommand) {
      await lastCommand.undo();
    }
  }
}
```

---

## 5. Selection Heuristics & Trade-offs

1. **Avoid Premature Pattern Injection**:
   - Do not introduce Factories or Strategy hierarchies before at least 2 distinct concrete implementations exist.
   - Prefer simple dependency-injected services over deep Decorator or Adapter chains when requirements are static.
2. **Favor Composition Over Inheritance**:
   - Replace rigid subclass hierarchies with Strategy and Decorator composition.
3. **Keep Facades Stateless**:
   - Facades must only orchestrate interactions between domain services without maintaining their own mutable session state.
