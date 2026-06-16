# Laravel Framework Patterns

**Framework**: Laravel (PHP Framework)
**Purpose**: Laravel-specific patterns, Eloquent ORM, routing, middleware, services, and best practices

## CORE PATTERNS

### Eloquent ORM

#### Relationships
- **One-to-One**: `hasOne()` on parent model, `belongsTo()` on child model
- **One-to-Many**: `hasMany()` on parent model, `belongsTo()` on child model
- **Many-to-Many**: `belongsToMany()` on both models, pivot table required
- **Has Many Through**: Access distant relations via intermediate model
- **Polymorphic Relations**: `morphTo()`, `morphMany()`, `morphToMany()`
- **Eager Loading**: Use `with()` to prevent N+1 queries, `withCount()` for counts

#### Scopes
- **Global Scopes**: Apply query constraints automatically to all queries
- **Local Scopes**: Define reusable query constraints (prefix with `scope`)
- **Dynamic Scopes**: Pass parameters to scopes

#### Accessors & Mutators
- **Accessors**: Transform model attribute values when accessed (prefix with `get`)
- **Mutators**: Transform attribute values before saving (prefix with `set`)
- **Attribute Casting**: Define `$casts` property for automatic type conversion

#### Mass Assignment
- **Fillable**: Define `$fillable` property (allowlist of mass-assignable attributes)
- **Guarded**: Define `$guarded` property (blocklist of non-assignable attributes)
- **Force Fill**: Use `forceFill()` to bypass mass assignment protection

### Routing

#### Route Definitions
- **Web Routes**: `routes/web.php` (session, CSRF protection)
- **API Routes**: `routes/api.php` (no session, stateless)
- **Console Routes**: `routes/console.php` (artisan commands)
- **Route Groups**: Apply middleware, prefix, namespace to multiple routes
- **Resource Controllers**: `Route::resource()` for CRUD operations
- **Route Model Binding**: Automatic model injection by ID or custom key

#### Route Parameters
- **Required Parameters**: `{id}` in route definition
- **Optional Parameters**: `{id?}` with default value in controller
- **Route Constraints**: Regular expressions to validate parameters
- **Explicit Binding**: Define custom resolution logic in `RouteServiceProvider`

### Controllers

#### Resource Controllers
- **Standard Methods**: `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()`
- **Form Requests**: Use for validation, separate validation from controller
- **API Resources**: Transform model data for API responses
- **Single Action Controllers**: `__invoke()` method for single-action controllers

#### Dependency Injection
- **Constructor Injection**: Inject dependencies in `__construct()`
- **Method Injection**: Inject dependencies in controller methods
- **Service Container**: Automatic resolution of class dependencies

### Middleware

#### Middleware Types
- **Global Middleware**: Applied to all routes (Kernel.php)
- **Route Middleware**: Applied to specific routes or groups
- **Middleware Groups**: Apply multiple middleware with single alias
- **Terminable Middleware**: Run after response sent to client

#### Common Middleware
- **Authentication**: `auth` middleware for authenticated routes
- **Guest**: `guest` middleware for unauthenticated routes
- **Throttle**: Rate limiting per user/IP
- **CSRF**: `VerifyCsrfToken` middleware (automatic for web routes)
- **Subdomain**: Route group by subdomain

### Request Validation

#### Form Requests
- **Create Form Request Class**: `php artisan make:request StoreUserRequest`
- **Authorization**: Implement `authorize()` method
- **Validation Rules**: Implement `rules()` method
- **Error Messages**: Implement `messages()` method
- **Prepare for Validation**: Implement `prepareForValidation()` method

#### Validation Rules
- **Common Rules**: `required`, `email`, `unique`, `max`, `min`, `confirmed`, `regex`
- **Conditional Rules**: `sometimes()` for conditional validation
- **Custom Rules**: `Rule::object()` for complex validation
- **Database Validation**: `unique:table,column`, `exists:table,column`

### Views

#### Blade Templates
- **Blade Directives**: `@if`, `@foreach`, `@forelse`, `@while`, `@auth`, `@guest`
- **Components**: `@component`, `@slot`, `@props`, `@aware`
- **Layouts**: `@extends`, `@yield`, `@section`, `@parent`
- **Includes**: `@include`, `@includeIf`
- **Forms**: `@csrf`, `@method`, `@error`

#### View Composers
- **View Data Sharing**: Share data with all views
- **View Creators**: Run when view is instantiated

### Services & Containers

#### Service Providers
- **Register Method**: Register bindings in service container
- **Boot Method**: Boot services after all providers registered
- **Deferred Providers**: Load only when needed

#### Service Container
- **Binding**: Bind interfaces to implementations
- **Singleton**: Bind as singleton (single instance)
- **Automatic Resolution**: Dependencies automatically injected

### Events & Listeners

#### Event-Driven Architecture
- **Create Event**: `php artisan make:event OrderPlaced`
- **Create Listener**: `php artisan make:listener SendOrderNotification`
- **Register**: Map events to listeners in `EventServiceProvider`
- **Dispatch**: `event(new OrderPlaced($order))`

#### Event Listeners
- **Handle Method**: Process event in `handle()` method
- **Queueable Listeners**: Run asynchronously
- **Event Subscribers**: Subscribe to multiple events in one class

### Jobs & Queues

#### Job Dispatching
- **Create Job**: `php artisan make:job SendEmail`
- **Dispatch**: `dispatch(new SendEmail($user))`
- **Delayed Dispatch**: `dispatch(new SendEmail($user))->delay(now()->addMinutes(5))`
- **Chain**: Chain multiple jobs sequentially
- **Batch**: Dispatch multiple jobs as batch

#### Queue Workers
- **Run Worker**: `php artisan queue:work`
- **Supervisor**: Keep queue workers running
- **Failed Jobs**: Handle failed jobs, retry or delete

### Notifications

#### Notification Channels
- **Mail**: Send email notifications
- **Database**: Store notifications in database
- **Broadcast**: Real-time notifications via broadcasting
- **SMS**: Send SMS notifications
- **Slack**: Send Slack notifications

### Migrations

#### Migration Patterns
- **Create Table**: `Schema::create()`, define columns and indexes
- **Modify Table**: `Schema::table()`, add/drop columns
- **Drop Table**: `Schema::drop()` or `Schema::dropIfExists()`
- **Foreign Keys**: Define constraints with `onDelete()`, `onUpdate()`
- **Indexes**: Define indexes for query optimization
- **Soft Deletes**: Add `deleted_at` timestamp for soft deletes

#### Migration Best Practices
- **Idempotent**: Migrations should be safe to run multiple times
- **Rollback**: Always define `down()` method
- **Atomic**: Keep migrations small and focused
- **Data Migrations**: Separate from schema migrations

## COMMON MISTAKES

### Eloquent Mistakes
- **N+1 Queries**: Querying relationships inside loops (fix with `with()`)
- **Mass Assignment Vulnerability**: Missing `$fillable` or using `$guarded: []`
- **SQL Injection**: Using raw queries without parameterization (`DB::raw()` requires validation)
- **Unnecessary Queries**: Loading entire model when only one field needed (`pluck()`)
- **Eager Loading Overkill**: Loading too many relationships (performance)

### Routing Mistakes
- **Route Order**: Specific routes defined after generic routes (never match)
- **Missing CSRF Token**: Forms without `@csrf` directive (vulnerable)
- **API Routes in Web**: API routes should be stateless (no session)
- **Route Cache**: Not running `php artisan route:cache` in production

### Controller Mistakes
- **Fat Controllers**: Too much business logic in controllers (move to services)
- **Missing Validation**: Not validating request data (security issue)
- **Hardcoded Data**: Hardcoding data in controllers (use config)
- **Direct Database Calls**: Using `DB` facade instead of Eloquent in controllers

### Middleware Mistakes
- **Missing Auth**: Forgetting to add authentication middleware
- **CSRF Bypass**: Disabling CSRF protection globally
- **Middleware Order**: Middleware order affects execution
- **Missing Throttle**: No rate limiting on API endpoints

### Service Provider Mistakes
- **Not Registering Services**: Services not available in container
- **Wrong Method**: Using `boot()` for registration (use `register()`)
- **Circular Dependencies**: Services depending on each other

### Blade Mistakes
- **Escaping Issues**: Using `{{ }}` for untrusted data (auto-escaped, but verify)
- **Missing CSRF**: Forms without `@csrf` directive
- **Direct PHP**: Using `<?php ?>` in Blade (use directives instead)

### Queue Mistakes
- **Not Running Workers**: Jobs dispatched but not processed
- **Timeout Issues**: Jobs exceeding timeout (increase timeout)
- **Failed Jobs**: Not handling or monitoring failed jobs
- **Memory Leaks**: Workers consuming memory (restart workers)

## PLATFORM ERRORS

### 500 Internal Server Error
- **Causes**: Unhandled exceptions, composer issues, permission errors, missing .env
- **Debugging**: Check `storage/logs/laravel.log`, enable debug mode in `.env`
- **Common Fixes**: Run `composer install`, check file permissions, verify `.env` configuration

### Class Not Found
- **Causes**: Autoloader issues, namespace mismatch, missing composer update
- **Fixes**: Run `composer dump-autoload`, verify namespace matches directory, check `composer.json` autoload section

### Target Class Does Not Exist
- **Causes**: Service provider not registered, alias not defined
- **Fixes**: Register service in `config/app.php`, run `php artisan config:clear`

### 404 Not Found
- **Causes**: Route not defined, method mismatch, missing CSRF on POST
- **Fixes**: Check route definition, verify HTTP method, add CSRF token

### SQLSTATE Connection Errors
- **Causes**: Wrong database credentials, database not running, missing .env variables
- **Fixes**: Verify `.env` database configuration, check database is running, test connection with `php artisan tinker`

### Migration Rollback Errors
- **Causes**: Schema conflicts, foreign key constraints, data integrity
- **Fixes**: Check foreign key order, drop constraints before dropping tables, handle data manually

### Composer Dependency Issues
- **Causes**: Version conflicts, incompatible packages, missing PHP extensions
- **Fixes**: Run `composer update`, check composer.json constraints, install missing extensions

### Cache Issues
- **Causes**: Stale config cache, stale route cache, view cache corruption
- **Fixes**: Run `php artisan config:clear`, `php artisan route:clear`, `php artisan view:clear`

## BEST PRACTICES

### Code Organization
- **Fat Models, Skinny Controllers**: Move business logic to models or services
- **Service Classes**: Create service classes for complex business logic
- **Form Requests**: Validate data in dedicated request classes
- **API Resources**: Transform data for API responses
- **Jobs for Async**: Use jobs for time-consuming tasks

### Security
- **Mass Assignment Protection**: Always define `$fillable` or `$guarded`
- **CSRF Protection**: Use `@csrf` directive on all forms
- **Authentication**: Use `auth` middleware on protected routes
- **Authorization**: Use Policies and Gates for authorization
- **Validation**: Always validate request data
- **SQL Injection Prevention**: Use Eloquent or parameterized queries

### Performance
- **Eager Loading**: Use `with()` to prevent N+1 queries
- **Query Optimization**: Use indexes, limit results, select specific columns
- **Cache**: Use Laravel's cache for expensive operations
- **Queues**: Use queues for time-consuming tasks
- **Lazy Loading**: Load relationships only when needed

### Testing
- **Unit Tests**: Test isolated business logic
- **Feature Tests**: Test HTTP requests and responses
- **Browser Tests**: Test JavaScript interactions
- **Database Transactions**: Roll back after each test

### Deployment
- **Environment Variables**: Never commit `.env` file
- **Production Optimizations**: Run `php artisan config:cache`, `php artisan route:cache`, `php artisan view:cache`
- **Queue Workers**: Use supervisor to keep workers running
- **Database Migrations**: Run migrations on production with backup

## MODERN LARAVEL FEATURES

### Laravel 9+
- **Enum Casting**: Cast to PHP 8.1 enums
- **Rendered Blade Strings**: Render Blade to string without HTTP request
- **Full Text Indexes**: MySQL full text search
- **Scope Binding**: Access scope in closures
- **Sokolov Date Cast**: Date/Time improvements

### Laravel 10+
- **Process Interaction**: Improved process API
- **Native Types**: Return native types from Eloquent
- **Horizon Improvements**: New dashboard and metrics
- **Queue Performance**: Improved queue performance
- **Test Profiling**: New test profiling features

### Laravel 11+
- **Application Structure Changes**: Simplified directory structure
- **Once Feature**: Execute code only once per request
- **Improved Performance**: Framework performance improvements
- **Queue Testing**: Enhanced queue testing features
