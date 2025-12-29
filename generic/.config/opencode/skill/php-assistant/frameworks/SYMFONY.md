# Symfony Framework Patterns

**Framework**: Symfony (PHP Framework)
**Purpose**: Symfony-specific patterns, Doctrine ORM, routing, console commands, Twig, and best practices

## CORE PATTERNS

### Doctrine ORM

#### Entities
- **Mapping**: Use annotations, XML, YAML, or PHP 8 attributes
- **Repository Pattern**: Extend `Doctrine\ORM\EntityRepository` for custom queries
- **Entity Managers**: Use `EntityManagerInterface` for persistence operations
- **Flush Operations**: Persist multiple entities before flushing (batch operations)

#### Relationships
- **One-to-One**: `@OneToOne` on owning side, `@OneToOne(mappedBy="...")` on inverse
- **One-to-Many**: `@OneToMany` with `mappedBy`, `@ManyToOne` on owning side
- **Many-to-Many**: `@ManyToMany` with `inversedBy` and `mappedBy`
- **Eager Loading**: Use `LEFT JOIN` in DQL or `fetch="EAGER"` in mapping

#### Query Builder
- **DQL**: Doctrine Query Language for type-safe queries
- **Query Builder**: Fluent interface for building queries dynamically
- **Criteria API**: Type-safe query building
- **Pagination**: Use `Paginator` interface for pagination

#### Migrations
- **Doctrine Migrations**: Use `doctrine:migrations:diff` to generate migrations
- **Rollback**: Use `doctrine:migrations:migrate prev` to rollback
- **Version Control**: Always commit migration files

### Routing

#### Route Configuration
- **YAML Routes**: `config/routes.yaml` (traditional)
- **PHP Routes**: `config/routes.php` (modern)
- **Annotation Routes**: `#[Route]` attributes on controller methods (modern)
- **Route Groups**: Group routes with common prefix, requirements, defaults

#### Route Parameters
- **Required Parameters**: `{id}` in route
- **Optional Parameters**: `{id?}` with default value
- **Requirements**: Regular expression constraints on parameters
- **Route Defaults**: Default values for parameters

#### Controllers
- **Controller as Service**: Autowired services in `__construct()`
- **Base Controller**: Extend `AbstractController` for shortcuts
- **Request/Response**: Use `Request` and `Response` objects
- **Redirects**: `redirectToRoute()`, `redirect()` helper methods

### Controllers

#### Action Methods
- **Public Methods**: Controller actions must be public
- **Return Types**: Return `Response` objects
- **Request Injection**: Type-hint `Request` parameter for access to request data
- **Service Injection**: Autowire services in `__construct()` or action methods

#### Request Handling
- **GET/POST**: Check `$request->getMethod()` or use `#[Route(methods: ['GET'])`
- **Query Parameters**: `$request->query->get('param')`
- **Request Body**: `$request->request->get('param')`
- **Files**: `$request->files->get('file')`

### Console Commands

#### Command Creation
- **Command Class**: Extend `Command` class
- **Configure Method**: Define name, description, arguments, options
- **Execute Method**: Implement command logic
- **Register Command**: Add to `config/services.yaml` or use `autoconfigure`

#### Command Features
- **Arguments**: Required parameters (`$this->addArgument()`)
- **Options**: Optional flags (`$this->addOption()`)
- **Input/Output**: Use `InputInterface` and `OutputInterface`
- **Services**: Autowire services via constructor

### Twig Templates

#### Template Inheritance
- **Extends**: `{% extends 'base.html.twig' %}`
- **Blocks**: `{% block title %}...{% endblock %}`
- **Include**: `{% include 'partial.html.twig' %}`
- **Embed**: `{{ embed('template.html.twig') }}{{ block('content') }}{{ endembed }}`

#### Twig Filters & Functions
- **Filters**: `|upper`, `|lower`, `|date`, `|number_format`, `|trans`
- **Functions**: `path()`, `url()`, `asset()`, `dump()`
- **Custom Filters**: Register as Twig extension

#### Forms
- **Form Types**: Use `FormBuilderInterface` to build forms
- **Form Handling**: `$form->handleRequest($request)`, `$form->isValid()`, `$form->getData()`
- **CSRF Protection**: Automatic CSRF tokens in forms
- **Form Theming**: Customize form rendering with Twig

### Dependency Injection

#### Service Container
- **Autowiring**: Automatic dependency injection based on type hints
- **Service Configuration**: `config/services.yaml` for manual configuration
- **Factory Pattern**: Use services with factories for complex instantiation
- **Service Tags**: Tag services for extensibility

#### Controller Services
- **Constructor Injection**: Inject services in `__construct()`
- **Action Injection**: Inject services directly in action methods
- **Lazy Services**: Use `ProxyInterface` for lazy-loaded services

### Events & Event Listeners

#### Event Dispatching
- **Create Event**: Class implementing `EventDispatcherInterface`
- **Dispatch Event**: `$eventDispatcher->dispatch(new MyEvent($data))`
- **Event Subscribers**: Subscribe to multiple events in one class

#### Event Listeners
- **Create Listener**: Class with `__invoke()` method
- **Configure Listener**: Map to event in `config/services.yaml`
- **Priority**: Set listener priority for execution order

### Security

#### User Provider
- **User Provider**: Implement `UserProviderInterface`
- **Load User**: `loadUserByIdentifier()` for authentication
- **Refresh User**: `refreshUser()` for session renewal

#### Authentication
- **Security Configuration**: `config/packages/security.yaml`
- **Firewalls**: Define access rules and authentication methods
- **Access Control**: `#[IsGranted('ROLE_ADMIN')]` attribute
- **Password Encoder**: Encode/validate passwords with `UserPasswordEncoderInterface`

#### Authorization
- **Roles**: Define roles in security configuration
- **Voters**: Custom authorization logic with `VoterInterface`
- **Access Control**: Use `access_control` configuration or `#[IsGranted]`

### Validation

#### Validation Constraints
- **Built-in Constraints**: `@Assert\NotBlank`, `@Assert\Email`, `@Assert\Length`
- **Custom Constraints**: Extend `Constraint` and `ConstraintValidator`
- **Validation Groups**: Group constraints for different validation scenarios

#### Form Validation
- **Form Types**: Add validation constraints to form fields
- **Manual Validation**: Use `ValidatorInterface` for custom validation
- **Validation Errors**: Access via `$form->getErrors()`

## COMMON MISTAKES

### Doctrine Mistakes
- **N+1 Queries**: Not joining relationships (use LEFT JOIN)
- **Unnecessary Queries**: Loading entities when only specific data needed
- **Missing Indexes**: Querying without indexes (slow queries)
- **Not Flushing**: Persisting entities without flushing (data not saved)
- **Circular References**: Entities referencing each other (infinite loops)

### Routing Mistakes
- **Route Order**: Generic routes defined before specific routes (never match)
- **Missing Methods**: Not specifying HTTP methods (matches all methods)
- **Wrong Return Type**: Returning string instead of Response object
- **Route Conflicts**: Multiple routes with same path and requirements

### Controller Mistakes
- **Static Dependencies**: Using static methods instead of services
- **Fat Controllers**: Too much business logic in controllers (move to services)
- **Missing Validation**: Not validating request data (security issue)
- **Not Using Form Component**: Handling form data manually

### Twig Mistakes
- **Not Escaping**: Using `|raw` filter on untrusted data (XSS vulnerability)
- **Complex Logic**: Business logic in templates (move to PHP)
- **Missing CSRF**: Forms without CSRF tokens
- **Hardcoded Text**: Text in templates (use translations)

### Service Container Mistakes
- **Service Conflicts**: Multiple services with same ID
- **Circular Dependencies**: Services depending on each other
- **Not Using Autowiring**: Manual configuration when autowiring works
- **Missing Dependencies**: Services not defined in container

### Console Mistakes
- **Not Using Return Codes**: Not returning proper exit codes
- **Missing Error Handling**: Not catching exceptions in commands
- **Interactive by Default**: Not using `--no-interaction` option for automation
- **Not Using Dependencies**: Using global/static code instead of injected services

### Security Mistakes
- **Weak Passwords**: Not using password encoders properly
- **Missing CSRF**: Forms without CSRF protection
- **Open Redirects**: Redirecting to user-provided URLs
- **Hardcoded Roles**: Checking roles manually instead of using security system

## PLATFORM ERRORS

### Service Not Found
- **Causes**: Service not configured, namespace mismatch, cache issues
- **Fixes**: Check `config/services.yaml`, run `cache:clear`, verify service ID

### Route Not Found (404)
- **Causes**: Route not defined, wrong HTTP method, cache issue
- **Fixes**: Check route configuration, verify HTTP method, run `cache:clear`

### Template Not Found
- **Causes**: Wrong template path, missing template, cache issue
- **Fixes**: Verify template path, check template exists, run `cache:clear`

### Doctrine Mapping Errors
- **Causes**: Wrong namespace, missing annotation, cache issue
- **Fixes**: Verify namespace, check annotations, run `cache:clear`, `doctrine:cache:clear-metadata`

### Database Connection Errors
- **Causes**: Wrong credentials, database not running, missing .env
- **Fixes**: Verify `.env` database configuration, check database connection
- **Debugging**: Run `doctrine:database:create` to test connection

### Cache Issues
- **Causes**: Stale cache, corrupted cache, permission issues
- **Fixes**: Run `cache:clear`, check cache directory permissions, `rm -rf var/cache/*`

### Composer Dependency Issues
- **Causes**: Version conflicts, incompatible packages, missing extensions
- **Fixes**: Run `composer update`, check `composer.json`, install missing extensions

### Autoloader Issues
- **Causes**: Missing autoload files, namespace mismatch, cache
- **Fixes**: Run `composer dump-autoload`, verify namespace, run `cache:clear`

## BEST PRACTICES

### Code Organization
- **Thin Controllers**: Move business logic to services
- **Service Classes**: Create services for complex business logic
- **Repository Pattern**: Use repositories for data access
- **DTOs**: Use Data Transfer Objects for form data

### Performance
- **Eager Loading**: Join relationships to prevent N+1 queries
- **Query Optimization**: Use indexes, limit results, select specific columns
- **Cache**: Use Symfony cache for expensive operations
- **Lazy Services**: Load services only when needed
- **Profiler**: Use Symfony Profiler to identify performance issues

### Security
- **CSRF Protection**: Enable CSRF protection on all forms
- **Authentication**: Use Symfony Security component
- **Authorization**: Use roles and voters
- **Validation**: Validate all input data
- **XSS Prevention**: Always escape output in Twig

### Testing
- **Unit Tests**: Test isolated business logic
- **Functional Tests**: Test HTTP requests and responses
- **Browser Tests**: Test JavaScript interactions
- **Database Fixtures**: Use Doctrine fixtures for test data

### Deployment
- **Environment Variables**: Use `.env` files, never commit sensitive data
- **Cache**: Run `cache:clear --env=prod` in production
- **Assets**: Build assets with `asset:install` or Webpack Encore
- **Database Migrations**: Run migrations with backup
- **Composer**: Run `composer install --no-dev --optimize-autoloader` in production

## MODERN SYMFONY FEATURES

### Symfony 5+
- **PHP 8 Attributes**: Use `#[Route]`, `#[Entity]` instead of annotations
- **Component-based Architecture**: Reusable components across bundles
- **Notifiable**: De-notified event system
- **Improved Performance**: Framework performance improvements

### Symfony 6+
- **Native Types**: Strict types throughout framework
- **PHP 8.1+**: Use PHP 8.1+ features
- **Removed Features**: Deprecated features removed (check upgrade guide)
- **Improved DI**: Enhanced dependency injection

### Symfony 7+
- **PHP 8.2+**: Requires PHP 8.2+
- **Stringable**: Enhanced string handling
- **Improved UX**: Better error messages and DX
- **Performance Enhancements**: Further performance improvements
