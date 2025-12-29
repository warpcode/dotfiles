# Bespoke PHP Patterns

**Framework**: Generic/Bespoke PHP (No Framework Detected)
**Purpose**: Standard PHP patterns, MVC conventions, PSR standards, autoloading, and modern PHP practices for custom applications

## CORE PATTERNS

### PSR Standards

#### PSR-1 (Basic Coding Standard)
- **Namespace**: All code must be in a namespace
- **Class Names**: One class per file, class name matches filename
- **Autoloading**: Enable autoloading via Composer

#### PSR-4 (Autoloading Standard)
- **Namespace Mapping**: Map namespaces to directory structure
- **Composer Autoload**: Configure in `composer.json` under `autoload.psr-4`
- **Example**:
  ```json
  {
    "autoload": {
      "psr-4": {
        "App\\": "src/",
        "Library\\": "lib/"
      }
    }
  }
  ```
- **Generate Autoloader**: Run `composer dump-autoload`

#### PSR-12 (Extended Coding Style)
- **Indentation**: 4 spaces (no tabs)
- **Line Length**: 120 characters or less (soft limit, hard limit optional)
- **Opening Braces**: Opening brace on same line or next line (consistent)
- **Namespace Declaration**: One blank line after `use` statements
- **Class/Method Formatting**: One blank line between methods
- **Control Structures**: Space between keywords and opening parenthesis

### MVC Architecture

#### Model
- **Purpose**: Represent data and business logic
- **Location**: `src/Model/` or `app/Models/`
- **Pattern**:
  - Class name: Singular (User, Product)
  - Properties: Protected or private
  - Methods: Public getters/setters or magic methods (`__get`, `__set`)
- **Example**:
  ```php
  namespace App\Model;

  class User {
      private string $id;
      private string $name;
      private string $email;

      public function __construct(string $id, string $name, string $email) {
          $this->id = $id;
          $this->name = $name;
          $this->email = $email;
      }

      public function getName(): string {
          return $this->name;
      }

      public function setEmail(string $email): void {
          $this->email = $email;
      }
  }
  ```

#### View
- **Purpose**: Display data to user
- **Location**: `src/View/` or `app/Views/`
- **Patterns**:
  - Plain PHP templates: `<?php foreach ($users as $user): ?>`
  - Simple template engine: Twig, Mustache (optional)
  - Data passed via `require` or include with `$data` array
- **Example**:
  ```php
  <?php foreach ($users as $user): ?>
      <div class="user">
          <h2><?= htmlspecialchars($user->getName(), ENT_QUOTES, 'UTF-8') ?></h2>
          <p><?= htmlspecialchars($user->getEmail(), ENT_QUOTES, 'UTF-8') ?></p>
      </div>
  <?php endforeach; ?>
  ```

#### Controller
- **Purpose**: Handle HTTP requests and coordinate Model/View
- **Location**: `src/Controller/` or `app/Controllers/`
- **Pattern**:
  - Namespace: `App\Controller`
  - Class name: ControllerName (UserController, ProductController)
  - Methods: Actions for routes (index, show, create, store, edit, update, delete)
  - Dependency Injection: Inject services via constructor
- **Example**:
  ```php
  namespace App\Controller;

  use App\Model\UserRepository;
  use App\View\UserView;

  class UserController {
      private UserRepository $userRepository;

      public function __construct(UserRepository $userRepository) {
          $this->userRepository = $userRepository;
      }

      public function index(): void {
          $users = $this->userRepository->getAll();
          require 'src/View/user_list.php';
      }

      public function show(string $id): void {
          $user = $this->userRepository->findById($id);
          if (!$user) {
              http_response_code(404);
              echo 'User not found';
              return;
          }
          require 'src/View/user_detail.php';
      }
  }
  ```

### Routing

#### Basic Router
- **Purpose**: Map URLs to controller actions
- **Pattern**:
  - Parse `$_SERVER['REQUEST_URI']`
  - Match against defined routes
  - Dispatch to controller method
- **Example**:
  ```php
  class Router {
      private array $routes = [];

      public function add(string $method, string $path, callable $handler): void {
          $this->routes[] = ['method' => $method, 'path' => $path, 'handler' => $handler];
      }

      public function dispatch(): void {
          $method = $_SERVER['REQUEST_METHOD'];
          $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

          foreach ($this->routes as $route) {
              if ($route['method'] === $method && $route['path'] === $path) {
                  call_user_func($route['handler']);
                  return;
              }
          }

          http_response_code(404);
          echo 'Route not found';
      }
  }

  $router = new Router();
  $router->add('GET', '/', [UserController::class, 'index']);
  $router->dispatch();
  ```

#### Dynamic Parameters
- **Pattern**: Use `{id}` placeholder, replace with actual value
- **Example**:
  ```php
  // Route definition: '/user/{id}'
  preg_match('#^/user/(\d+)$#', $path, $matches);
  $id = $matches[1];
  $controller->show($id);
  ```

### Autoloading

#### Composer Autoloader
- **Purpose**: Automatically load class files
- **Setup**:
  - Define PSR-4 mapping in `composer.json`
  - Run `composer dump-autoload`
  - Require `vendor/autoload.php` in entry point
- **Example**:
  ```php
  require 'vendor/autoload.php';

  use App\Controller\UserController;
  use App\Model\UserRepository;

  $controller = new UserController(new UserRepository());
  $controller->index();
  ```

### Dependency Injection

#### Constructor Injection
- **Purpose**: Inject dependencies via constructor
- **Pattern**:
  - Type-hint dependencies in `__construct()`
  - Store as private properties
  - Use in methods
- **Example**:
  ```php
  class UserController {
      private UserRepository $userRepository;
      private LoggerInterface $logger;

      public function __construct(UserRepository $userRepository, LoggerInterface $logger) {
          $this->userRepository = $userRepository;
          $this->logger = $logger;
      }

      public function show(string $id): void {
          $user = $this->userRepository->findById($id);
          $this->logger->info('User viewed', ['user_id' => $id]);
          // ...
      }
  }
  ```

### Configuration

#### Config File
- **Purpose**: Store configuration in one place
- **Pattern**:
  - Return associative array
  - Use constants for config keys
- **Example**:
  ```php
  // config/database.php
  return [
      'host' => getenv('DB_HOST') ?: 'localhost',
      'port' => getenv('DB_PORT') ?: '3306',
      'database' => getenv('DB_NAME') ?: 'myapp',
      'username' => getenv('DB_USER') ?: 'root',
      'password' => getenv('DB_PASS') ?: '',
  ];
  ```

#### Environment Variables
- **Purpose**: Store sensitive data outside code
- **Pattern**:
  - Use `.env` file
  - Load with `getenv()`
  - Never commit `.env` to version control
- **Example**:
  ```php
  $dbHost = getenv('DB_HOST');
  $apiKey = getenv('API_KEY');
  ```

### Database Access

#### PDO Basic Usage
- **Purpose**: Safe database access
- **Pattern**:
  - Connect to database
  - Use prepared statements
  - Bind parameters (prevent SQLi)
  - Fetch results
- **Example**:
  ```php
  try {
      $pdo = new PDO('mysql:host=localhost;dbname=myapp', 'username', 'password');
      $stmt = $pdo->prepare('SELECT * FROM users WHERE id = :id');
      $stmt->bindParam(':id', $id, PDO::PARAM_INT);
      $stmt->execute();
      $user = $stmt->fetch(PDO::FETCH_ASSOC);
  } catch (PDOException $e) {
      error_log('Database error: ' . $e->getMessage());
  }
  ```

#### Database Abstraction Layer
- **Purpose**: Encapsulate database logic
- **Pattern**:
  - Create repository classes
  - Methods for common operations (find, findAll, insert, update, delete)
  - Use PDO internally
- **Example**:
  ```php
  class UserRepository {
      private PDO $pdo;

      public function __construct(PDO $pdo) {
          $this->pdo = $pdo;
      }

      public function findById(string $id): ?User {
          $stmt = $this->pdo->prepare('SELECT * FROM users WHERE id = :id');
          $stmt->execute(['id' => $id]);
          $data = $stmt->fetch(PDO::FETCH_ASSOC);
          return $data ? new User($data['id'], $data['name'], $data['email']) : null;
      }

      public function findAll(): array {
          $stmt = $this->pdo->query('SELECT * FROM users');
          $users = [];
          while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
              $users[] = new User($row['id'], $row['name'], $row['email']);
          }
          return $users;
      }
  }
  ```

### Request Handling

#### Super Globals
- **`$_GET`**: Query parameters from URL
- **`$_POST`**: POST request body
- **`$_REQUEST`**: Combined GET, POST, COOKIE (avoid if possible)
- **`$_SERVER`**: Server and execution environment info
- **`$_FILES`**: Uploaded files

#### Input Validation
- **Purpose**: Sanitize and validate user input
- **Pattern**:
  - Never trust user input
  - Use filter_var() for basic validation
  - Use htmlspecialchars() for output (prevent XSS)
- **Example**:
  ```php
  $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
  if (!$email) {
      echo 'Invalid email';
      return;
  }

  $name = filter_input(INPUT_POST, 'name', FILTER_SANITIZE_STRING);
  // Output
  echo htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
  ```

#### CSRF Protection
- **Purpose**: Prevent Cross-Site Request Forgery
- **Pattern**:
  - Generate token on session start
  - Include token in forms
  - Validate token on POST
- **Example**:
  ```php
  session_start();

  // Generate token
  if (!isset($_SESSION['csrf_token'])) {
      $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
  }

  // Validate token
  if ($_SERVER['REQUEST_METHOD'] === 'POST') {
      $token = $_POST['csrf_token'] ?? '';
      if (!hash_equals($_SESSION['csrf_token'], $token)) {
          http_response_code(403);
          echo 'Invalid CSRF token';
          exit;
      }
  }

  // Form
  echo '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($_SESSION['csrf_token'], ENT_QUOTES, 'UTF-8') . '">';
  ```

### Error Handling

#### Error Reporting
- **Purpose**: Control error reporting during development vs production
- **Pattern**:
  - Development: Show all errors
  - Production: Log errors, show generic message
- **Example**:
  ```php
  if (getenv('ENVIRONMENT') === 'production') {
      error_reporting(0);
      ini_set('display_errors', '0');
      ini_set('log_errors', '1');
      ini_set('error_log', '/var/log/php_errors.log');
  } else {
      error_reporting(E_ALL);
      ini_set('display_errors', '1');
  }
  ```

#### Exception Handling
- **Purpose**: Gracefully handle errors
- **Pattern**:
  - Use try-catch blocks
  - Log exceptions
  - Show user-friendly messages
- **Example**:
  ```php
  try {
      $result = riskyOperation();
  } catch (DatabaseException $e) {
      error_log('Database error: ' . $e->getMessage());
      echo 'Database error occurred';
  } catch (Exception $e) {
      error_log('Unexpected error: ' . $e->getMessage());
      echo 'An error occurred';
  }
  ```

## COMMON MISTAKES

### Autoloading Mistakes
- **Not Using Namespaces**: All code must be in namespace
- **Wrong Namespace**: Namespace doesn't match directory structure
- **Not Running dump-autoload**: Changes not reflected
- **Hardcoded Require**: Using `require` instead of autoloading

### MVC Mistakes
- **Fat Controllers**: Too much business logic in controllers
- **Business Logic in Views**: Logic in templates instead of controllers
- **Direct Database Access**: Controllers accessing database directly (use repositories)
- **Missing Separation**: Models, views, controllers mixed together

### Routing Mistakes
- **Case Sensitivity**: URLs should be case-insensitive
- **Trailing Slashes**: Inconsistent trailing slashes
- **Missing 404**: Not handling unmatched routes
- **SQL Injection in Routes**: Not validating route parameters

### Database Mistakes
- **SQL Injection**: Not using prepared statements
- **Not Closing Connections**: Not closing database connections
- **Raw Queries Everywhere**: Not using abstraction layer
- **Missing Transactions**: Not using transactions for multi-step operations

### Security Mistakes
- **XSS Vulnerability**: Not escaping output with `htmlspecialchars()`
- **CSRF Vulnerability**: Missing CSRF token validation
- **SQL Injection**: Concatenating strings in SQL queries
- **Hardcoded Secrets**: Credentials in code instead of environment variables

### Error Handling Mistakes
- **Silencing Errors**: Using `@` operator
- **Not Logging Errors**: Not recording errors in production
- **Showing Errors in Production**: Exposing stack traces
- **Not Handling Exceptions**: Uncaught exceptions crash application

## BEST PRACTICES

### Code Organization
- **PSR Standards**: Follow PSR-1, PSR-4, PSR-12
- **Namespace Conventions**: `Vendor\Project\Component`
- **Directory Structure**: Separate `src/`, `public/`, `config/`, `vendor/`
- **Composer**: Use Composer for dependency management

### Performance
- **Use Autoloading**: Don't require files manually
- **Database Optimization**: Use indexes, limit results, select specific columns
- **Caching**: Cache expensive operations
- **Opcode Cache**: Use OPcache in production

### Security
- **Input Validation**: Validate all user input
- **Output Escaping**: Escape all output with `htmlspecialchars()`
- **CSRF Protection**: Use CSRF tokens on all forms
- **SQL Injection Prevention**: Always use prepared statements
- **Password Hashing**: Use `password_hash()` and `password_verify()`
- **Environment Variables**: Store sensitive data in environment

### Testing
- **Unit Tests**: Test individual functions/classes
- **Integration Tests**: Test components working together
- **Test Structure**: Follow Arrange-Act-Assert pattern
- **Test Coverage**: Aim for high coverage

### Deployment
- **Environment**: Use `.env` files for environment-specific config
- **Composer**: Run `composer install --no-dev` in production
- **Opcode Cache**: Enable OPcache for production
- **Error Logging**: Log errors, don't display to users
- **Version Control**: Use Git, commit frequently
