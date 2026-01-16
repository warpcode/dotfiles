# Write Mode: PHP Code Generation

**Purpose**: Progressive loading for PHP code generation based on framework and requirements

## PROGRESSIVE LOADING STRATEGY

### Step 1: Framework Detection
Load framework-specific patterns based on detected framework:
- **Laravel detected**: `@frameworks/LARAVEL.md`
- **Symfony detected**: `@frameworks/SYMFONY.md`
- **Bespoke detected**: `@frameworks/BESPOKE.md`

### Step 2: Context Analysis
Analyze request to determine what patterns to load:
- **Database operations**: Load ORM patterns (Eloquent, Doctrine, PDO)
- **Authentication**: Load auth patterns (Laravel Auth, Symfony Security, custom auth)
- **API development**: Load routing/controller patterns
- **Frontend integration**: Load view/template patterns (Blade, Twig, plain PHP)
- **Testing**: Load testing patterns (PHPUnit, Pest)

### Step 3: PHP Version Detection
Determine PHP version to apply appropriate features:
- **PHP 8.0+**: Use named arguments, attributes, constructor property promotion
- **PHP 8.1+**: Use readonly properties, first-class callables, enums
- **PHP 8.2+**: Use readonly classes, DNF types
- **PHP 8.3+**: Use typed class constants, randomizer
- **Legacy (< 8.0)**: Use compatible syntax, avoid type hints where problematic

### Step 4: Modern PHP Features
Apply modern PHP features based on version:
- **Type Hints**: Add parameter types, return types, property types
- **Null Safety**: Use null coalescing (`??`), null coalescing assignment (`??=`)
- **Array Syntax**: Use `[]` instead of `array()`
- **Short Ternary**: Use `?:` instead of full ternary
- **Spaceship Operator**: Use `<=>` for comparisons
- **Attributes**: Use `#[Attribute]` instead of annotations (PHP 8+)
- **Constructor Property Promotion**: Combine properties and constructor (PHP 8+)
- **Named Arguments**: Use named parameters for clarity (PHP 8+)
- **Match Expression**: Use `match` instead of `switch` (PHP 8+)

## FRAMEWORK-SPECIFIC GENERATION

### Laravel Code Generation

#### Controller Generation
```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    public function index(): JsonResponse
    {
        $users = User::paginate(20);
        return response()->json($users);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
        ]);

        $user = User::create($validated);

        return response()->json($user, 201);
    }

    public function show(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        return response()->json($user);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $id,
        ]);

        $user->update($validated);

        return response()->json($user);
    }

    public function destroy(string $id): JsonResponse
    {
        $user = User::findOrFail($id);
        $user->delete();

        return response()->json(null, 204);
    }
}
```

#### Model Generation
```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class User extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    public function posts(): HasMany
    {
        return $this->hasMany(Post::class);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('active', true);
    }
}
```

#### Migration Generation
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
```

#### Request Validation
```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
        ];
    }
}
```

#### Job Generation
```php
<?php

namespace App\Jobs;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

class SendWelcomeEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public User $user
    ) {
    }

    public function handle(): void
    {
        Mail::to($this->user->email)->send(new WelcomeEmail($this->user));
    }
}
```

### Symfony Code Generation

#### Controller Generation
```php
<?php

namespace App\Controller;

use App\Entity\User;
use App\Repository\UserRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

class UserController extends AbstractController
{
    private UserRepository $userRepository;

    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }

    #[Route('/users', name: 'user_index', methods: ['GET'])]
    public function index(): JsonResponse
    {
        $users = $this->userRepository->findAll();

        return $this->json($users);
    }

    #[Route('/users', name: 'user_store', methods: ['POST'])]
    public function store(Request $request, EntityManagerInterface $entityManager): JsonResponse
    {
        $data = json_decode($request->getContent(), true);

        $user = new User();
        $user->setName($data['name']);
        $user->setEmail($data['email']);

        $entityManager->persist($user);
        $entityManager->flush();

        return $this->json($user, 201);
    }

    #[Route('/users/{id}', name: 'user_show', methods: ['GET'])]
    public function show(string $id): JsonResponse
    {
        $user = $this->userRepository->find($id);

        if (!$user) {
            return $this->json(['error' => 'User not found'], 404);
        }

        return $this->json($user);
    }
}
```

#### Entity Generation
```php
<?php

namespace App\Entity;

use App\Repository\UserRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: UserRepository::class)]
#[ORM\Table(name: 'users')]
class User
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: 'integer')]
    private ?int $id = null;

    #[ORM\Column(type: 'string', length: 255)]
    private string $name;

    #[ORM\Column(type: 'string', length: 255, unique: true)]
    private string $email;

    #[ORM\Column(type: 'datetime', nullable: true)]
    private ?\DateTimeInterface $emailVerifiedAt = null;

    #[ORM\OneToMany(targetEntity: Post::class, mappedBy: 'user')]
    private Collection $posts;

    public function __construct()
    {
        $this->posts = new ArrayCollection();
    }

    // Getters and Setters
    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function setName(string $name): self
    {
        $this->name = $name;
        return $this;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setEmail(string $email): self
    {
        $this->email = $email;
        return $this;
    }

    public function getPosts(): Collection
    {
        return $this->posts;
    }
}
```

#### Console Command Generation
```php
<?php

namespace App\Command;

use App\Service\UserService;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(name: 'app:create-user')]
class CreateUserCommand extends Command
{
    public function __construct(
        private UserService $userService
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->setDescription('Creates a new user.')
            ->addArgument('name', InputArgument::REQUIRED, 'The name of the user')
            ->addArgument('email', InputArgument::REQUIRED, 'The email of the user');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $name = $input->getArgument('name');
        $email = $input->getArgument('email');

        $user = $this->userService->create($name, $email);

        $output->writeln(sprintf('User created successfully! ID: %d', $user->getId()));

        return Command::SUCCESS;
    }
}
```

### Bespoke PHP Code Generation

#### Controller Generation
```php
<?php

namespace App\Controller;

use App\Model\UserRepository;
use App\View\UserView;

class UserController
{
    private UserRepository $userRepository;

    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }

    public function index(): void
    {
        $users = $this->userRepository->findAll();
        require __DIR__ . '/../View/user_list.php';
    }

    public function show(string $id): void
    {
        $user = $this->userRepository->findById($id);

        if (!$user) {
            http_response_code(404);
            echo 'User not found';
            return;
        }

        require __DIR__ . '/../View/user_detail.php';
    }

    public function create(): void
    {
        $name = $_POST['name'] ?? '';
        $email = $_POST['email'] ?? '';

        if (empty($name) || empty($email)) {
            http_response_code(400);
            echo 'Name and email are required';
            return;
        }

        $id = $this->userRepository->create($name, $email);

        header('Location: /users/' . $id);
        http_response_code(303);
    }
}
```

#### Model Generation
```php
<?php

namespace App\Model;

class User
{
    private string $id;
    private string $name;
    private string $email;

    public function __construct(string $id, string $name, string $email)
    {
        $this->id = $id;
        $this->name = $name;
        $this->email = $email;
    }

    public function getId(): string
    {
        return $this->id;
    }

    public function getName(): string
    {
        return $this->name;
    }

    public function getEmail(): string
    {
        return $this->email;
    }

    public function setName(string $name): void
    {
        $this->name = $name;
    }

    public function setEmail(string $email): void
    {
        $this->email = $email;
    }
}
```

#### Repository Generation
```php
<?php

namespace App\Repository;

use App\Model\User;
use PDO;

class UserRepository
{
    private PDO $pdo;

    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    public function findAll(): array
    {
        $stmt = $this->pdo->query('SELECT * FROM users');
        $users = [];

        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $users[] = new User($row['id'], $row['name'], $row['email']);
        }

        return $users;
    }

    public function findById(string $id): ?User
    {
        $stmt = $this->pdo->prepare('SELECT * FROM users WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $data = $stmt->fetch(PDO::FETCH_ASSOC);

        return $data ? new User($data['id'], $data['name'], $data['email']) : null;
    }

    public function create(string $name, string $email): string
    {
        $stmt = $this->pdo->prepare('INSERT INTO users (name, email) VALUES (:name, :email)');
        $stmt->execute(['name' => $name, 'email' => $email]);

        return $this->pdo->lastInsertId();
    }
}
```

## MODERN PHP PATTERNS

### Type Hints (PHP 7.0+)
```php
// Bad: No type hints
function createUser($name, $email) {
    // ...
}

// Good: Type hints
function createUser(string $name, string $email): void {
    // ...
}
```

### Return Types (PHP 7.0+)
```php
// Bad: No return type
function getUser($id) {
    return $user;
}

// Good: Return type
function getUser(string $id): ?User {
    return $user;
}
```

### Nullable Types (PHP 7.1+)
```php
// Good: Nullable return type
function getUser(string $id): ?User {
    return $user ?? null;
}

// Good: Nullable parameter
function setUserEmail(?string $email): void {
    if ($email !== null) {
        // ...
    }
}
```

### Strict Types (PHP 7.0+)
```php
<?php
declare(strict_types=1);

function add(int $a, int $b): int {
    return $a + $b;
}
```

### Null Coalescing Operator (PHP 7.0+)
```php
// Bad: isset check
$name = isset($_GET['name']) ? $_GET['name'] : 'Anonymous';

// Good: Null coalescing
$name = $_GET['name'] ?? 'Anonymous';

// Good: Null coalescing assignment
$name ??= 'Anonymous';
```

### Spaceship Operator (PHP 7.0+)
```php
// Bad: Multiple comparisons
if ($a < $b) {
    return -1;
} elseif ($a > $b) {
    return 1;
} else {
    return 0;
}

// Good: Spaceship operator
return $a <=> $b;
```

### Array Syntax (PHP 5.4+)
```php
// Bad: Old array syntax
$users = array('John', 'Jane', 'Bob');

// Good: Short array syntax
$users = ['John', 'Jane', 'Bob'];
```

### Anonymous Classes (PHP 7.0+)
```php
// Good: Anonymous class
$logger = new class {
    public function log(string $message): void {
        error_log($message);
    }
};

$logger->log('Hello world');
```

### Use Statement Grouping (PHP 7.0+)
```php
// Bad: Multiple use statements
use App\Controller\UserController;
use App\Controller\PostController;
use App\Controller\CommentController;

// Good: Grouped use
use App\Controller\{
    UserController,
    PostController,
    CommentController
};
```

### Traits (PHP 5.4+)
```php
trait Loggable
{
    public function log(string $message): void
    {
        error_log($message);
    }
}

class User
{
    use Loggable;

    public function save(): void
    {
        $this->log('Saving user...');
    }
}
```

### Generator Functions (PHP 5.5+)
```php
function getUsers(): iterable
{
    $stmt = $pdo->query('SELECT * FROM users');

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        yield $row;
    }
}

foreach (getUsers() as $user) {
    // Process user
}
```

### Late Static Binding (PHP 5.3+)
```php
class ParentClass
{
    public static function getInstance(): self
    {
        return new static();
    }
}

class ChildClass extends ParentClass
{
}

$instance = ChildClass::getInstance(); // Returns ChildClass instance
```

## DEPRECATED API REPLACEMENTS

### mysql_* functions → PDO/mysqli
```php
// Bad: Deprecated mysql_* functions
$link = mysql_connect('localhost', 'user', 'pass');
$result = mysql_query('SELECT * FROM users');

// Good: PDO
$pdo = new PDO('mysql:host=localhost;dbname=test', 'user', 'pass');
$stmt = $pdo->query('SELECT * FROM users');

// Good: mysqli
$mysqli = new mysqli('localhost', 'user', 'pass', 'test');
$result = $mysqli->query('SELECT * FROM users');
```

### ereg_* functions → preg_* functions
```php
// Bad: Deprecated ereg_* functions
if (ereg('^[a-zA-Z]+$', $name)) {
    // ...
}

// Good: preg_* functions
if (preg_match('/^[a-zA-Z]+$/', $name)) {
    // ...
}
```

### split() → explode() or preg_split()
```php
// Bad: Deprecated split()
$parts = split(',', $string);

// Good: explode()
$parts = explode(',', $string);

// Good: preg_split()
$parts = preg_split('/\s+/', $string);
```

### each() → foreach
```php
// Bad: Deprecated each()
while (list($key, $value) = each($array)) {
    // ...
}

// Good: foreach
foreach ($array as $key => $value) {
    // ...
}
```

### mysql_real_escape_string() → Prepared Statements
```php
// Bad: Escaping strings
$name = mysql_real_escape_string($_POST['name']);
$query = "SELECT * FROM users WHERE name = '$name'";

// Good: Prepared statements
$stmt = $pdo->prepare('SELECT * FROM users WHERE name = :name');
$stmt->execute(['name' => $_POST['name']]);
```

## OUTPUT FORMAT

### Code Generation Output
```markdown
## Generated PHP Code: [Component]

### Framework: [Laravel/Symfony/Bespoke]
### PHP Version: [8.1+]

### Implementation
```php
[Generated PHP code]
```

### Modern PHP Features Applied
- [Type hints on parameters and return types]
- [Constructor property promotion]
- [Named arguments]
- [Match expression]
- [Short array syntax]

### Notes
- [Additional notes or considerations]
- [Dependencies to install via Composer]
- [Configuration required]

### Related Patterns
@frameworks/[FRAMEWORK].md
```
