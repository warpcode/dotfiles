# DESIGN PATTERNS

## OVERVIEW
Design patterns are reusable solutions to commonly occurring problems in software design. They represent best practices used by experienced developers.

## CREATIONAL PATTERNS

### Factory Pattern

**Purpose**: Create objects without specifying the exact class of object to be created.

**When to Use**:
- When you don't know which concrete classes to create
- When you want to centralize object creation logic
- When you want to decouple creation from usage

**PHP Example**:
```php
interface Notification {
    public function send(string $message);
}

class EmailNotification implements Notification {
    public function send(string $message) {
        echo "Sending email: $message\n";
    }
}

class SMSNotification implements Notification {
    public function send(string $message) {
        echo "Sending SMS: $message\n";
    }
}

class NotificationFactory {
    public static function create(string $type): Notification {
        return match($type) {
            'email' => new EmailNotification(),
            'sms' => new SMSNotification(),
            default => throw new InvalidArgumentException("Unknown type: $type")
        };
    }
}

$notification = NotificationFactory::create('email');
$notification->send('Hello World');
```

---

### Singleton Pattern

**Purpose**: Ensure a class has only one instance and provide global access to it.

**When to Use**:
- When exactly one instance of a class is needed
- When that instance needs to be accessible globally
- Database connections, loggers, configurations

**PHP Example**:
```php
class Database {
    private static ?Database $instance = null;
    private PDO $connection;

    private function __construct() {
        $this->connection = new PDO('sqlite::memory:');
    }

    public static function getInstance(): Database {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }

    public function getConnection(): PDO {
        return $this->connection;
    }

    private function __clone() { }
    public function __wakeup() { throw new Exception("Cannot unserialize singleton"); }
}

$db = Database::getInstance();
```

**⚠️ Warning**: Singleton can make code hard to test and create hidden dependencies. Prefer dependency injection.

---

### Builder Pattern

**Purpose**: Construct complex objects step by step.

**When to Use**:
- When objects have many optional parameters
- When construction requires multiple steps
- When you want to create different representations

**PHP Example**:
```php
class User {
    private function __construct(
        private string $name,
        private string $email,
        private ?int $age = null,
        private ?string $phone = null
    ) { }

    public static function builder(): UserBuilder {
        return new UserBuilder();
    }
}

class UserBuilder {
    private ?string $name = null;
    private ?string $email = null;
    private ?int $age = null;
    private ?string $phone = null;

    public function name(string $name): self {
        $this->name = $name;
        return $this;
    }

    public function email(string $email): self {
        $this->email = $email;
        return $this;
    }

    public function age(int $age): self {
        $this->age = $age;
        return $this;
    }

    public function phone(string $phone): self {
        $this->phone = $phone;
        return $this;
    }

    public function build(): User {
        return new User(
            $this->name,
            $this->email,
            $this->age,
            $this->phone
        );
    }
}

$user = User::builder()
    ->name('John Doe')
    ->email('john@example.com')
    ->age(30)
    ->build();
```

---

## STRUCTURAL PATTERNS

### Adapter Pattern

**Purpose**: Allow incompatible interfaces to work together.

**When to Use**:
- When you need to use a class with incompatible interface
- When you want to reuse existing classes
- When you need to integrate third-party code

**PHP Example**:
```php
interface MediaPlayer {
    public function play(string $filename);
}

class MP3Player {
    public function playMp3(string $filename) {
        echo "Playing MP3: $filename\n";
    }
}

class MP4Player {
    public function playMp4(string $filename) {
        echo "Playing MP4: $filename\n";
    }
}

class MediaAdapter implements MediaPlayer {
    private MP3Player $mp3;
    private MP4Player $mp4;

    public function __construct() {
        $this->mp3 = new MP3Player();
        $this->mp4 = new MP4Player();
    }

    public function play(string $filename) {
        if (str_ends_with($filename, '.mp3')) {
            $this->mp3->playMp3($filename);
        } elseif (str_ends_with($filename, '.mp4')) {
            $this->mp4->playMp4($filename);
        }
    }
}

$player = new MediaAdapter();
$player->play('song.mp3');
$player->play('video.mp4');
```

---

### Decorator Pattern

**Purpose**: Add behavior to objects dynamically without modifying their class.

**When to Use**:
- When you need to add responsibilities dynamically
- When subclassing would create too many classes
- When you want to compose behaviors

**PHP Example**:
```php
interface Coffee {
    public function cost(): float;
    public function description(): string;
}

class SimpleCoffee implements Coffee {
    public function cost(): float { return 2.0; }
    public function description(): string { return "Simple coffee"; }
}

class MilkDecorator implements Coffee {
    public function __construct(private Coffee $coffee) { }

    public function cost(): float { return $this->coffee->cost() + 0.5; }
    public function description(): string { return $this->coffee->description() . ", milk"; }
}

class SugarDecorator implements Coffee {
    public function __construct(private Coffee $coffee) { }

    public function cost(): float { return $this->coffee->cost() + 0.2; }
    public function description(): string { return $this->coffee->description() . ", sugar"; }
}

$coffee = new SimpleCoffee();
$coffee = new MilkDecorator($coffee);
$coffee = new SugarDecorator($coffee);
echo $coffee->description();  // "Simple coffee, milk, sugar"
echo $coffee->cost();  // 2.7
```

---

### Facade Pattern

**Purpose**: Provide simplified interface to complex subsystems.

**When to Use**:
- When you need to simplify complex systems
- When you want to decouple clients from subsystems
- When you want layering of subsystems

**PHP Example**:
```php
class CPU {
    public function freeze() { echo "CPU frozen\n"; }
    public function jump(string $position) { echo "CPU jumped to $position\n"; }
    public function execute() { echo "CPU executing\n"; }
}

class Memory {
    public function load(long $position, string $data) { echo "Memory loaded at $position\n"; }
}

class HardDrive {
    public function read(long $lba, int $size): string { return "Data from $lba"; }
}

class ComputerFacade {
    private CPU $cpu;
    private Memory $memory;
    private HardDrive $hd;

    public function __construct() {
        $this->cpu = new CPU();
        $this->memory = new Memory();
        $this->hd = new HardDrive();
    }

    public function start() {
        $this->cpu->freeze();
        $this->memory->load(0x00, $this->hd->read(0x0000, 1024));
        $this->cpu->jump('0x00');
        $this->cpu->execute();
    }
}

$computer = new ComputerFacade();
$computer->start();  // Simple interface to complex operations
```

---

## BEHAVIORAL PATTERNS

### Strategy Pattern

**Purpose**: Define a family of algorithms and make them interchangeable.

**When to Use**:
- When you have multiple ways to do something
- When you want to switch algorithms at runtime
- When you want to avoid conditional logic

**PHP Example**:
```php
interface PaymentStrategy {
    public function pay(float $amount): bool;
}

class CreditCardPayment implements PaymentStrategy {
    public function pay(float $amount): bool {
        echo "Paid $amount with credit card\n";
        return true;
    }
}

class PayPalPayment implements PaymentStrategy {
    public function pay(float $amount): bool {
        echo "Paid $amount with PayPal\n";
        return true;
    }
}

class ShoppingCart {
    private PaymentStrategy $strategy;

    public function setPaymentStrategy(PaymentStrategy $strategy): void {
        $this->strategy = $strategy;
    }

    public function checkout(float $amount): void {
        $this->strategy->pay($amount);
    }
}

$cart = new ShoppingCart();
$cart->setPaymentStrategy(new CreditCardPayment());
$cart->checkout(100.0);

$cart->setPaymentStrategy(new PayPalPayment());
$cart->checkout(50.0);
```

---

### Observer Pattern

**Purpose**: Define subscription mechanism to notify multiple objects about events.

**When to Use**:
- When one object needs to notify others
- When you don't know which objects need notification
- For event-driven systems

**PHP Example**:
```php
interface Observer {
    public function update(string $event, mixed $data): void;
}

interface Subject {
    public function attach(Observer $observer): void;
    public function detach(Observer $observer): void;
    public function notify(string $event, mixed $data): void;
}

class EventDispatcher implements Subject {
    private array $observers = [];

    public function attach(Observer $observer): void {
        $this->observers[] = $observer;
    }

    public function detach(Observer $observer): void {
        $this->observers = array_filter($this->observers, fn($o) => $o !== $observer);
    }

    public function notify(string $event, mixed $data): void {
        foreach ($this->observers as $observer) {
            $observer->update($event, $data);
        }
    }
}

class EmailLogger implements Observer {
    public function update(string $event, mixed $data): void {
        echo "Email: Event $event occurred\n";
    }
}

class DatabaseLogger implements Observer {
    public function update(string $event, mixed $data): void {
        echo "DB: Logged event $event\n";
    }
}

$dispatcher = new EventDispatcher();
$dispatcher->attach(new EmailLogger());
$dispatcher->attach(new DatabaseLogger());
$dispatcher->notify('user_registered', ['user' => 'John']);
```

---

### Command Pattern

**Purpose**: Encapsulate requests as objects.

**When to Use**:
- When you want to parameterize objects with operations
- When you want to queue/undo operations
- For logging, transactions, undo/redo

**PHP Example**:
```php
interface Command {
    public function execute(): void;
    public function undo(): void;
}

class Light {
    public function on() { echo "Light is ON\n"; }
    public function off() { echo "Light is OFF\n"; }
}

class LightOnCommand implements Command {
    public function __construct(private Light $light) { }

    public function execute(): void { $this->light->on(); }
    public function undo(): void { $this->light->off(); }
}

class LightOffCommand implements Command {
    public function __construct(private Light $light) { }

    public function execute(): void { $this->light->off(); }
    public function undo(): void { $this->light->on(); }
}

class RemoteControl {
    private array $history = [];

    public function executeCommand(Command $command): void {
        $command->execute();
        $this->history[] = $command;
    }

    public function undoLast(): void {
        $command = array_pop($this->history);
        if ($command) {
            $command->undo();
        }
    }
}

$remote = new RemoteControl();
$light = new Light();

$remote->executeCommand(new LightOnCommand($light));
$remote->executeCommand(new LightOffCommand($light));
$remote->undoLast();
```

---

## CROSS-REFERENCES
- For anti-patterns: @patterns/ANTI-PATTERNS.md
- For SOLID principles: @principles/SOLID.md
- For code smells: @patterns/CODE-SMELLS.md
- For clean architecture: @architecture/CLEAN-ARCHITECTURE.md
