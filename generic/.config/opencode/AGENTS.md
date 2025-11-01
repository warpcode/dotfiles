# Expert Code Review Training Guide for AI Agents

## Purpose
This document trains AI agents to perform code reviews at an exceptionally high standard, matching expert human reviewers in thoroughness, accuracy, and insight.

---

## Core Principles

### 1. **Review Philosophy**
- Focus on substance over style (though style matters)
- Prioritize user safety, data integrity, and system reliability
- Be constructive, not destructive - every comment should add value
- Consider the context: production code requires higher standards than prototypes
- Balance perfectionism with pragmatism

### 2. **Review Mindset**
- Assume positive intent from the developer
- Ask questions rather than make accusations
- Provide specific, actionable feedback
- Explain the "why" behind every comment
- Acknowledge good code when you see it

---

## Review Categories & Severity Levels

### Severity Classification

**CRITICAL** - Must fix before merge
- Security vulnerabilities
- Data loss risks
- Crashes or system failures
- Breaking changes without migration

**HIGH** - Should fix before merge
- Performance degradation
- Logic bugs
- Poor architecture that will cause future problems
- Missing error handling for critical paths

**MEDIUM** - Fix in near term
- Code quality issues
- Maintainability concerns
- Missing tests for important functionality
- Incomplete documentation

**LOW** - Nice to have
- Style inconsistencies
- Minor optimizations
- Naming improvements
- Cosmetic issues

**INFO** - Educational/Suggestions
- Best practice recommendations
- Alternative approaches
- Learning opportunities

---

## Comprehensive Review Checklist

### 1. SECURITY REVIEW (Critical Priority)

#### Authentication & Authorization
- [ ] Are authentication checks present on all protected endpoints?
- [ ] Is authorization verified (user has permission for the action)?
- [ ] Are session tokens validated and expired properly?
- [ ] Is password handling secure (hashed, salted, never logged)?
- [ ] Are API keys/secrets stored securely (not hardcoded)?

**Red Flags:**
```python
# CRITICAL: Hardcoded credentials
password = "admin123"
api_key = "sk-1234567890"

# CRITICAL: SQL injection vulnerability
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# CRITICAL: Command injection
os.system(f"ping {user_input}")

# CRITICAL: Missing authentication check
@app.route('/admin/delete_user/<user_id>')
def delete_user(user_id):
    User.delete(user_id)  # No auth check!
```

**Good Patterns:**
```python
# Use parameterized queries
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# Use environment variables for secrets
api_key = os.getenv('API_KEY')

# Verify authorization
@require_admin
def delete_user(user_id):
    if not current_user.can_delete(user_id):
        abort(403)
    User.delete(user_id)
```

#### Input Validation
- [ ] Is all user input validated and sanitized?
- [ ] Are file uploads restricted by type and size?
- [ ] Are numeric inputs checked for range/overflow?
- [ ] Is there protection against XSS attacks?
- [ ] Are redirects validated against open redirect vulnerabilities?

#### Data Protection
- [ ] Is sensitive data encrypted at rest and in transit?
- [ ] Are PII fields properly masked in logs?
- [ ] Is there protection against mass assignment vulnerabilities?
- [ ] Are rate limits implemented to prevent abuse?

---

### 2. CORRECTNESS REVIEW

#### Logic & Algorithms
- [ ] Does the code actually solve the stated problem?
- [ ] Are edge cases handled (empty input, null, zero, negative)?
- [ ] Are boundary conditions correct (off-by-one errors)?
- [ ] Is the algorithm correct and efficient?
- [ ] Are there race conditions or concurrency issues?

**Common Issues:**
```python
# WRONG: Off-by-one error
for i in range(len(items) - 1):  # Skips last item!
    process(items[i])

# WRONG: Floating point comparison
if price == 19.99:  # May fail due to precision

# WRONG: Mutable default argument
def add_item(item, items=[]):  # Shared between calls!
    items.append(item)
    return items

# WRONG: Race condition
if not file_exists(path):  # Another thread may create it here
    create_file(path)
```

#### Error Handling
- [ ] Are errors caught and handled appropriately?
- [ ] Are error messages informative but not leaking sensitive info?
- [ ] Is there a clear error handling strategy (fail-fast vs. graceful degradation)?
- [ ] Are resources cleaned up in error cases (files, connections, locks)?
- [ ] Are exceptions logged with sufficient context?

**Anti-patterns:**
```python
# BAD: Silent failures
try:
    critical_operation()
except:
    pass  # Error is swallowed!

# BAD: Catching too broadly
try:
    process_data()
except Exception:  # Catches everything, even KeyboardInterrupt
    log("error")

# BAD: Leaking sensitive info
except Exception as e:
    return f"Error: {e}"  # May expose stack traces to users
```

**Good patterns:**
```python
# GOOD: Specific exception handling with cleanup
try:
    with open(file_path) as f:
        data = process(f)
except FileNotFoundError:
    logger.error(f"File not found: {file_path}")
    return default_value
except ValueError as e:
    logger.error(f"Invalid data format: {e}")
    raise
```

---

### 3. PERFORMANCE REVIEW

#### Algorithmic Efficiency
- [ ] Is the time complexity appropriate for the use case?
- [ ] Are there unnecessary nested loops (N² or worse)?
- [ ] Can operations be batched instead of repeated?
- [ ] Are there obvious optimization opportunities?

**Performance Issues:**
```python
# BAD: N+1 query problem
for user in users:
    user.posts = Post.query.filter_by(user_id=user.id).all()

# BAD: Inefficient search
if item in long_list:  # O(n) lookup, repeated in loop
    process(item)

# BAD: Repeated computation
for i in range(n):
    result = expensive_calculation()  # Move outside loop!
    use(result)

# BAD: Reading file multiple times
for user in users:
    config = json.load(open('config.json'))  # Load once!
```

#### Resource Management
- [ ] Are database queries optimized (indexes, joins vs. N+1)?
- [ ] Are connections pooled and reused?
- [ ] Is memory usage reasonable (no memory leaks)?
- [ ] Are large files streamed rather than loaded into memory?
- [ ] Are caches used appropriately?

#### Concurrency & Scaling
- [ ] Will this code scale with increased load?
- [ ] Are there blocking operations that should be async?
- [ ] Is there proper locking for shared resources?
- [ ] Are there opportunities for parallelization?

---

### 4. MAINTAINABILITY REVIEW

#### Code Structure
- [ ] Is the code organized logically?
- [ ] Are functions/methods single-purpose and focused?
- [ ] Is there appropriate separation of concerns?
- [ ] Are there any god classes or god functions?
- [ ] Is the code DRY (Don't Repeat Yourself)?

**Code Smells:**
```python
# BAD: Function doing too much
def process_user(user_data):
    # Validates data
    # Saves to database
    # Sends email
    # Updates cache
    # Logs analytics
    # 200 lines of code...

# BAD: Repeated code
def calculate_discount_vip(price):
    tax = price * 0.1
    discount = price * 0.2
    return price - discount + tax

def calculate_discount_regular(price):
    tax = price * 0.1
    discount = price * 0.1
    return price - discount + tax

# GOOD: Extract common logic
def calculate_final_price(price, discount_rate):
    tax = price * 0.1
    discount = price * discount_rate
    return price - discount + tax
```

#### Naming & Readability
- [ ] Are names descriptive and meaningful?
- [ ] Do names follow project/language conventions?
- [ ] Are abbreviations avoided (except well-known ones)?
- [ ] Is the code self-documenting?

**Naming Issues:**
```python
# BAD: Non-descriptive names
def f(x, y):
    return x * y + 10

data = process(stuff)

# BAD: Misleading names
def get_user(user_id):
    user = User.find(user_id)
    user.last_login = now()
    user.save()  # This modifies! Name suggests read-only
    return user

# GOOD: Clear, descriptive names
def calculate_total_price(base_price, quantity):
    return base_price * quantity + SHIPPING_FEE

def update_user_login_timestamp(user_id):
    user = User.find(user_id)
    user.last_login = now()
    user.save()
    return user
```

#### Complexity
- [ ] Is cyclomatic complexity reasonable (<10 per function)?
- [ ] Can nested conditionals be flattened?
- [ ] Can complex expressions be broken down?
- [ ] Would extracting helper functions improve clarity?
- [ ] Are early return patterns used to reduce nesting?

**Early Return Pattern (Preferred Style):**
```python
# BAD: Deep nesting (Arrow Anti-Pattern)
def validate_user(user):
    if user is not None:
        if user.is_active:
            if user.email_verified:
                if user.has_permission('read'):
                    return True
                else:
                    return False
            else:
                return False
        else:
            return False
    else:
        return False

# GOOD: Early returns - Preferred style
def validate_user(user):
    if user is None:
        return False
    
    if not user.is_active:
        return False
    
    if not user.email_verified:
        return False
    
    if not user.has_permission('read'):
        return False
    
    return True

# EVEN BETTER: Combined conditions when logical
def validate_user(user):
    if user is None:
        return False
    
    return (user.is_active and 
            user.email_verified and 
            user.has_permission('read'))
```

**Benefits of Early Returns:**
- Reduces cognitive load by eliminating nested blocks
- Makes error/edge cases explicit and handled first
- Happy path is clearly visible at the end
- Easier to test individual conditions
- Prevents the "arrow" anti-pattern (deeply nested code)
- More maintainable and easier to modify

**When to Use Early Returns:**
- Input validation - check and return immediately if invalid
- Guard clauses - check prerequisites at function start
- Error conditions - fail fast and return error early
- Edge cases - handle special cases before main logic
- Permission checks - verify access before proceeding

Always prefer flattening nested conditions with early returns unless there's
a compelling reason for nesting (like needing to run cleanup code in all paths).

---

### 5. TESTING REVIEW

#### Test Coverage
- [ ] Are there unit tests for new functionality?
- [ ] Are edge cases tested?
- [ ] Are error paths tested?
- [ ] Are integration points tested?
- [ ] Is the happy path tested?

#### Test Quality
- [ ] Are tests independent (no shared state)?
- [ ] Are tests deterministic (no flaky tests)?
- [ ] Are test names descriptive?
- [ ] Do tests follow AAA pattern (Arrange, Act, Assert)?
- [ ] Are mocks/stubs used appropriately?

**Test Anti-patterns:**
```python
# BAD: Testing implementation details
def test_internal_cache():
    obj._cache['key'] = 'value'  # Testing private details
    assert obj._cache['key'] == 'value'

# BAD: Multiple assertions without clear purpose
def test_everything():
    assert user.name == "John"
    assert user.age == 30
    assert user.email == "john@example.com"
    assert order.total == 100
    # What is this test actually testing?

# GOOD: Clear, focused test
def test_discount_applied_to_order_total():
    order = Order(items=[Item(price=100)])
    discount = Discount(percentage=0.1)
    
    final_total = apply_discount(order, discount)
    
    assert final_total == 90
```

---

### 6. ARCHITECTURE REVIEW

#### Design Patterns
- [ ] Are appropriate design patterns used?
- [ ] Is there over-engineering or premature optimization?
- [ ] Are dependencies managed properly?
- [ ] Is there tight coupling that should be loosened?
- [ ] Are interfaces/abstractions used appropriately?

#### System Design
- [ ] Does this fit well with existing architecture?
- [ ] Are there scalability concerns?
- [ ] Is there proper separation between layers?
- [ ] Are there circular dependencies?
- [ ] Is the data model sound?

---

### 7. DOCUMENTATION REVIEW

#### Code Comments (Inline Documentation)
- [ ] Are comments explaining "why" (not "what" or "how")?
- [ ] Are comments ONLY present for complex code that needs explanation?
- [ ] Is the code self-documenting enough to avoid needing comments?
- [ ] Are TODOs tracked and reasonable?
- [ ] Are comments accurate and up-to-date?
- [ ] Is there over-commenting of obvious code? (This is a red flag)

**CRITICAL RULE: Comments should ONLY explain WHY, never WHAT or HOW**

The code itself should be clear enough to explain WHAT it does and HOW it does it. Comments should only exist when:
1. The WHY is not obvious from the code
2. The code is inherently complex and the reasoning needs explanation
3. There are non-obvious side effects or behaviors
4. There are important business rules or constraints

**Comment Anti-Patterns (NEVER do this):**
```python
# BAD: Describing WHAT the code does (redundant)
# Increment i by 1
i += 1

# BAD: Describing WHAT the code does (obvious)
# Create a new user
user = User()

# BAD: Describing WHAT the code does (redundant)
# Loop through all users
for user in users:
    process(user)

# BAD: Describing HOW (code already shows this)
# Use list comprehension to filter active users
active_users = [u for u in users if u.is_active]

# BAD: Outdated comment (worse than no comment)
# Returns user email
def get_user_profile(user_id):
    return User.find(user_id)  # Returns full user object now!

# BAD: Comment because code is unclear (FIX THE CODE instead)
# Get all users where status is 1 (active)
users = User.query.filter_by(status=1).all()
# Should be: users = User.query.filter_by(status=UserStatus.ACTIVE).all()
```

**GOOD: Comments explaining WHY (only when necessary):**
```python
# GOOD: Explains business reasoning
# We must check inventory before payment to prevent overselling
# due to race conditions in high-traffic sales
if not check_inventory(order):
    return error("Out of stock")
payment.process(order)

# GOOD: Explains non-obvious optimization
# Use exponential backoff to avoid overwhelming the API
# after rate limit errors. Linear backoff was insufficient
# during peak traffic based on incident INC-2847
time.sleep(2 ** retry_count)

# GOOD: Explains surprising behavior
# Returns None instead of raising exception to allow graceful
# degradation in batch operations. If we raised here, one
# missing user would fail the entire batch of 10,000 users
def find_user_safe(user_id):
    try:
        return User.find(user_id)
    except NotFoundError:
        return None

# GOOD: Explains magic number with business context
# 90 days is mandated by GDPR for user data retention
# after account deletion request
RETENTION_DAYS = 90

# GOOD: Explains workaround
# Using sorted() instead of .sort() because MySQL ORDER BY
# doesn't handle NULL values the way our business logic requires.
# See ticket DATA-445 for detailed explanation
results = sorted(query_results, key=lambda x: x.date or datetime.min)

# GOOD: Explains complex algorithm reasoning
# We use binary search here despite unsorted data because
# sorting once (O(n log n)) + binary search (O(log n)) 
# is faster than linear search (O(n)) when this function
# is called 1000+ times per request
sorted_items = sorted(items, key=lambda x: x.id)
result = binary_search(sorted_items, target_id)
```

**When code needs comments, consider refactoring instead:**
```python
# BAD: Complex code requiring explanation
# Check if user is eligible (active, verified, and either premium or has >100 points)
if user.status == 1 and user.verified and (user.tier == 3 or user.points > 100):
    grant_access()

# GOOD: Self-documenting code (no comment needed)
def is_eligible_for_access(user):
    is_active = user.status == UserStatus.ACTIVE
    is_verified = user.verified
    is_premium = user.tier == UserTier.PREMIUM
    has_sufficient_points = user.points > MINIMUM_POINTS
    
    return is_active and is_verified and (is_premium or has_sufficient_points)

if is_eligible_for_access(user):
    grant_access()
```

**KEY PRINCIPLE: If you feel the need to write a comment explaining WHAT the code does, the code is not clear enough. Refactor the code to be self-documenting instead of adding a comment.**

**EXCEPTION: High Complexity**
Only write inline comments when the code has inherently high complexity that cannot be simplified:
- Complex algorithms (binary search, graph traversal, etc.)
- Performance optimizations with non-obvious trade-offs
- Workarounds for bugs in libraries or external systems
- Business logic with non-obvious rules or constraints
- Non-obvious side effects or behaviors

Even in these cases, the comment should explain WHY, not describe the steps.

#### API Documentation
- [ ] Are public functions/classes documented?
- [ ] Are parameters and return values described?
- [ ] Are exceptions documented?
- [ ] Are usage examples provided for complex APIs?

---

## Review Process Guidelines

### 1. **Initial Pass - High-Level Review**
- Understand the purpose of the change
- Review the PR description and related issues
- Check if the approach makes sense architecturally
- Identify any major red flags

### 2. **Detailed Review - Line by Line**
- Review each file systematically
- Check against all categories in the checklist
- Note both issues and good practices
- Consider how changes interact with existing code

### 3. **Final Pass - Integration Review**
- How does this fit into the larger system?
- Are there breaking changes?
- Is documentation updated?
- Are there database migrations if needed?

---

## How to Write Review Comments

### Structure of a Good Comment

```
[SEVERITY] Category: Brief Title

Description: Explain what the issue is and why it matters.

Suggestion: Provide specific, actionable advice on how to fix it.

Example: (optional) Show code demonstrating the fix.
```

### Examples of Excellent Comments

**Example 1 - Security Issue:**
```
[CRITICAL] Security: SQL Injection Vulnerability

The current implementation uses string formatting to build SQL queries,
which allows attackers to inject malicious SQL code through the username field.

Suggestion: Use parameterized queries to safely handle user input:

cursor.execute("SELECT * FROM users WHERE username = ?", (username,))

This separates the SQL logic from the data, preventing injection attacks.
```

**Example 2 - Performance Issue:**
```
[HIGH] Performance: N+1 Query Problem

This code makes a separate database query for each user's posts (line 45-47),
resulting in 1000+ queries if there are 1000 users. This will cause
significant performance degradation.

Suggestion: Use eager loading to fetch all data in one query:

users = User.query.options(joinedload(User.posts)).all()

This reduces 1000+ queries to just 1-2 queries.
```

**Example 3 - Maintainability Issue:**
```
[MEDIUM] Maintainability: Complex Nested Logic

This function has 4 levels of nested if-statements (lines 120-145), making it
difficult to understand and test. The cyclomatic complexity is 15.

Suggestion: Use early return patterns to flatten the logic and reduce nesting:

# BEFORE (nested):
def process_order(order):
    if order.is_valid():
        if has_inventory(order):
            if payment_authorized(order):
                return complete_order(order)
            else:
                return error("Payment failed")
        else:
            return error("Out of stock")
    else:
        return error("Invalid order")

# AFTER (early returns - PREFERRED):
def process_order(order):
    if not order.is_valid():
        return error("Invalid order")
    
    if not has_inventory(order):
        return error("Out of stock")
    
    if not payment_authorized(order):
        return error("Payment failed")
    
    return complete_order(order)

Early returns reduce nesting, improve readability, and make the happy path
stand out clearly at the end of the function.
```

**Example 4 - Positive Feedback:**
```
[INFO] Best Practice: Excellent Error Handling

Great job on the comprehensive error handling in this function! I particularly
like how you:
- Catch specific exceptions rather than broad Exception
- Log errors with context for debugging
- Provide graceful fallbacks for non-critical failures
- Clean up resources in all code paths

This is a model for how error handling should be done.
```

---

## Complete Anti-Pattern Reference

This section lists all common anti-patterns that MUST be flagged during code review. When you encounter these patterns, always recommend refactoring.

### CODE STRUCTURE ANTI-PATTERNS

#### 1. God Object / God Class
**What:** A class that knows too much or does too much.
```python
# BAD: God class doing everything
class UserManager:
    def authenticate(self): ...
    def send_email(self): ...
    def process_payment(self): ...
    def generate_report(self): ...
    def log_analytics(self): ...
    def resize_image(self): ...
    # 50+ methods handling unrelated concerns
```
**Fix:** Split into focused, single-responsibility classes.

#### 2. Arrow Anti-Pattern (Deep Nesting)
**What:** Excessive nested if-statements creating arrow-like code structure.
```python
# BAD: Arrow pattern
def process(data):
    if data:
        if data.valid:
            if data.user:
                if data.user.active:
                    if data.user.verified:
                        # Finally do work 5 levels deep!
                        return result
```
**Fix:** Use early returns to flatten logic (see Early Return Pattern section).

#### 3. Spaghetti Code
**What:** Code with complex and tangled control flow, lacking clear structure.
```python
# BAD: Tangled logic with goto-like flow
def process():
    stage = 1
    while True:
        if stage == 1:
            # do something
            stage = 3  # Skip stage 2
        elif stage == 2:
            stage = 1  # Go back
        elif stage == 3:
            if condition:
                stage = 2  # Loop back
            else:
                break
```
**Fix:** Use clear function calls, proper control structures, and state machines if needed.

#### 4. Lava Flow
**What:** Dead code that remains because no one dares to remove it.
```python
# BAD: Commented out code left "just in case"
def calculate_price(price):
    # Old calculation - don't delete, might need later
    # return price * 1.1 + 5
    # Another old version
    # return price * 1.15
    return price * 1.2  # Current version
```
**Fix:** Delete dead code. Use version control to recover if needed.

#### 5. Copy-Paste Programming
**What:** Duplicating code instead of abstracting common functionality.
```python
# BAD: Duplicated logic
def calculate_vip_discount(price):
    tax = price * 0.1
    discount = price * 0.2
    shipping = 5.99
    return price - discount + tax + shipping

def calculate_regular_discount(price):
    tax = price * 0.1
    discount = price * 0.1
    shipping = 5.99
    return price - discount + tax + shipping

def calculate_member_discount(price):
    tax = price * 0.1
    discount = price * 0.15
    shipping = 5.99
    return price - discount + tax + shipping
```
**Fix:** Extract common logic with parameters for variations.

#### 6. Magic Numbers
**What:** Unexplained numeric literals scattered throughout code.
```python
# BAD: Magic numbers
if user.age > 18 and user.score > 750 and user.balance > 10000:
    approve_loan()

time.sleep(86400)  # What does this number mean?
```
**Fix:** Use named constants with descriptive names.
```python
LEGAL_AGE = 18
MIN_CREDIT_SCORE = 750
MIN_BALANCE = 10000
SECONDS_IN_DAY = 86400
```

#### 7. Excessive Nesting (Arrow Anti-Pattern)
**What:** Code with more than 4 levels of nesting, creating hard-to-read arrow-like structure.

**CRITICAL RULE: Maximum 4 levels of nesting (including the function itself)**

```python
# BAD: 5+ levels of nesting - NEVER ACCEPTABLE
def process_order(order):
    if order:  # Level 1
        if order.valid:  # Level 2
            if order.user:  # Level 3
                if order.user.active:  # Level 4
                    if order.user.verified:  # Level 5 - TOO DEEP!
                        return complete_order(order)

# GOOD: Early returns - ALWAYS PREFERRED
def process_order(order):
    if not order:
        return None
    
    if not order.valid:
        return None
    
    if not order.user:
        return None
    
    if not order.user.active:
        return None
    
    if not order.user.verified:
        return None
    
    return complete_order(order)
```

**Shell Script Example:**
```bash
# BAD: 5+ levels of nesting
function validate_and_process() {
    if [[ -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            if [[ -r "$1" ]]; then
                if [[ -s "$1" ]]; then
                    if [[ $? -eq 0 ]]; then  # Level 5 - TOO DEEP!
                        process_file "$1"
                    fi
                fi
            fi
        fi
    fi
}

# GOOD: Early returns (maximum 4 levels including function)
function validate_and_process() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        echo "❌ Missing file parameter" >&2
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        echo "❌ File not found: $file" >&2
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        echo "❌ File not readable: $file" >&2
        return 1
    fi
    
    if [[ ! -s "$file" ]]; then
        echo "❌ File is empty: $file" >&2
        return 1
    fi
    
    # Main logic at top level
    process_file "$file"
}
```

**Fix Strategy:**
1. **Use early returns/guard clauses** - Handle error conditions first
2. **Extract functions** - Break complex logic into smaller functions
3. **Invert conditions** - Check for failure cases and return early
4. **Combine related conditions** - Use logical operators when appropriate

**This is a CRITICAL requirement - any code exceeding 4 levels of nesting MUST be refactored.**
**What:** A single change requires modifications in many different places.
```python
# BAD: Adding a field requires changes in 20+ files
# user.py - add field
# user_dto.py - add field
# user_validator.py - add validation
# user_serializer.py - add serialization
# user_mapper.py - add mapping
# ... 15 more files
```
**Fix:** Better encapsulation and abstraction to localize changes.

---

### FUNCTION ANTI-PATTERNS

#### 9. Long Method
**What:** Functions/methods that are too long (generally >50 lines).
```python
# BAD: 200-line function doing everything
def process_order():
    # Validate input (30 lines)
    # Calculate prices (40 lines)
    # Check inventory (25 lines)
    # Process payment (35 lines)
    # Send notifications (20 lines)
    # Update analytics (25 lines)
    # Generate invoice (25 lines)
```
**Fix:** Extract smaller, focused functions.

#### 10. Long Parameter List
**What:** Functions with too many parameters (generally >3-4).
```python
# BAD: Too many parameters
def create_user(first_name, last_name, email, phone, address, 
                city, state, zip, country, timezone, language,
                newsletter_opt_in, terms_accepted):
    pass
```
**Fix:** Use parameter objects or builder pattern.
```python
# GOOD: Use a data class or dict
@dataclass
class UserData:
    first_name: str
    last_name: str
    email: str
    # ... rest of fields

def create_user(user_data: UserData):
    pass
```

#### 11. Flag Arguments
**What:** Boolean parameters that control function behavior.
```python
# BAD: Boolean flag changes behavior
def save_user(user, is_new):
    if is_new:
        # Create logic
    else:
        # Update logic

def format_date(date, is_short):
    if is_short:
        return date.strftime("%m/%d")
    else:
        return date.strftime("%B %d, %Y")
```
**Fix:** Split into separate functions with clear names.
```python
# GOOD: Separate functions
def create_user(user): ...
def update_user(user): ...

def format_date_short(date): ...
def format_date_long(date): ...
```

#### 12. Side Effects in Getters
**What:** Functions named "get" or "is" that modify state.
```python
# BAD: Getter has side effects
def get_user(user_id):
    user = User.find(user_id)
    user.last_accessed = now()  # SIDE EFFECT!
    user.save()  # MUTATION!
    log_access(user_id)  # SIDE EFFECT!
    return user
```
**Fix:** Separate query and command operations.

#### 13. Mutable Default Arguments
**What:** Using mutable objects as default function arguments.
```python
# BAD: Mutable default - shared between calls!
def add_item(item, items=[]):
    items.append(item)
    return items

list1 = add_item(1)  # [1]
list2 = add_item(2)  # [1, 2] - UNEXPECTED!
```
**Fix:** Use None as default and create new instance inside function.
```python
# GOOD: Immutable default
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

---

### ERROR HANDLING ANTI-PATTERNS

#### 14. Swallowing Exceptions
**What:** Catching exceptions without handling or logging them.
```python
# BAD: Silent failure
try:
    critical_operation()
except Exception:
    pass  # Error is completely hidden!

# BAD: Generic error response
try:
    process_payment()
except:
    return "Error occurred"  # No context, no logging
```
**Fix:** Log errors with context, handle specifically, or let them propagate.

#### 15. Pokemon Exception Handling
**What:** Gotta catch 'em all - catching all exceptions indiscriminately.
```python
# BAD: Catching everything including system exits
try:
    process_data()
except Exception:  # Catches too much!
    log("error")

# WORSE: Bare except catches KeyboardInterrupt, SystemExit
try:
    process_data()
except:
    log("error")
```
**Fix:** Catch specific exceptions you can actually handle.

#### 16. Exception for Flow Control
**What:** Using exceptions for normal program flow instead of conditionals.
```python
# BAD: Using exceptions for control flow
try:
    user = users[user_id]
except KeyError:
    user = create_default_user()

# BAD: Expected condition as exception
try:
    value = int(input_string)
except ValueError:
    value = 0
```
**Fix:** Use conditionals for expected conditions, exceptions for exceptional situations.
```python
# GOOD: Check first
if user_id in users:
    user = users[user_id]
else:
    user = create_default_user()
```

#### 17. Leaking Implementation Details in Exceptions
**What:** Exposing internal details or sensitive information in error messages.
```python
# BAD: Leaking sensitive info
except Exception as e:
    return f"Database error: {e}"  # Might expose schema, credentials

# BAD: Stack trace to user
except Exception:
    import traceback
    return traceback.format_exc()  # Exposes internal paths
```
**Fix:** Return generic user messages, log details server-side.

---

### SECURITY ANTI-PATTERNS

#### 18. Hard-Coded Credentials
**What:** Secrets, passwords, or API keys in source code.
```python
# BAD: Hard-coded secrets
API_KEY = "sk-1234567890abcdef"
PASSWORD = "admin123"
DB_CONNECTION = "postgresql://user:password@localhost/db"
```
**Fix:** Use environment variables or secret management systems.

#### 19. String Concatenation in SQL
**What:** Building SQL queries with string formatting or concatenation.
```python
# BAD: SQL injection vulnerability
query = f"SELECT * FROM users WHERE username = '{username}'"
query = "SELECT * FROM users WHERE id = " + user_id
cursor.execute(query)
```
**Fix:** Always use parameterized queries.

#### 20. Eval / Exec on User Input
**What:** Using eval() or exec() on untrusted input.
```python
# BAD: Arbitrary code execution vulnerability
user_code = request.get('code')
result = eval(user_code)  # NEVER DO THIS!

formula = request.get('formula')
exec(formula)  # NEVER DO THIS!
```
**Fix:** Parse and validate input, use safe alternatives like ast.literal_eval for data.

#### 21. Trusting Client-Side Validation
**What:** Only validating input on client-side without server validation.
```python
# BAD: No server-side validation
@app.route('/update_price')
def update_price():
    # Assumes frontend validated this
    new_price = request.form['price']
    product.price = new_price  # No validation!
    product.save()
```
**Fix:** Always validate on server-side, client validation is just UX.

#### 22. Insufficient Authorization Checks
**What:** Not verifying user has permission to perform action.
```python
# BAD: No authorization check
@app.route('/delete_user/<user_id>')
def delete_user(user_id):
    User.delete(user_id)  # Any authenticated user can delete anyone!

# BAD: Authentication without authorization
@login_required
def view_salary(employee_id):
    return Employee.find(employee_id).salary  # Can view anyone's salary!
```
**Fix:** Verify user has permission for the specific resource/action.

---

#### 23. Command Injection (Shell Scripts)
**What:** Using untrusted input in commands without validation (critical for shell scripts).
```bash
# BAD: Command injection vulnerability
repo="$1"
git clone "https://github.com/$repo"  # Can inject commands!
# Input: "user/repo; rm -rf /" would execute both commands

url="$1"
curl "$url" | sh  # Extremely dangerous!

# BAD: Unvalidated URL construction
version="$1"
curl "https://example.com/${version}/file.sh" | sh
# Input: "../../../etc/passwd" could access wrong files

# BAD: Unquoted variables in commands
file="$1"
cat $file  # Word splitting and glob expansion

# GOOD: Input validation with regex
repo="$1"
if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    echo "❌ Invalid repo name: $repo" >&2
    return 1
fi
git clone "https://github.com/$repo"

# GOOD: Properly quoted and validated
version="$1"
if [[ ! $version =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version: $version" >&2
    return 1
fi
local url="https://example.com/${version#v}/file.sh"
curl "$url" | sh

# GOOD: Quote all variables
file="$1"
cat "$file"
```
**Fix:** Always validate input format, quote all variables, use allowlists not blocklists.

#### 24. Path Traversal Vulnerabilities
**What:** Not validating file paths, allowing access to unintended files.
```bash
# BAD: Path traversal vulnerability
file="$1"
cat "$HOME/config/$file"
# Input: "../../../etc/passwd" could access system files

# BAD: No validation of file path
dir="$1"
cd "$dir" && rm -rf *  # Extremely dangerous!

# GOOD: Validate path doesn't escape intended directory
file="$1"
if [[ "$file" == *..* ]] || [[ "$file" == /* ]]; then
    echo "❌ Invalid file path: $file" >&2
    return 1
fi
cat "$HOME/config/$file"

# GOOD: Use realpath to resolve and validate
file="$1"
config_dir="$HOME/config"
full_path=$(realpath -m "$config_dir/$file")
if [[ "$full_path" != "$config_dir"* ]]; then
    echo "❌ Path outside config directory" >&2
    return 1
fi
cat "$full_path"
```
**Fix:** Validate paths, check for ".." and absolute paths, use realpath to canonicalize.

---

### PERFORMANCE ANTI-PATTERNS

#### 25. N+1 Query Problem
**What:** Making a database query for each item in a collection.
```python
# BAD: N+1 queries (1 + N where N = number of users)
users = User.query.all()  # 1 query
for user in users:
    posts = Post.query.filter_by(user_id=user.id).all()  # N queries!
    user.posts = posts
```
**Fix:** Use joins, eager loading, or batch queries.

#### 26. Premature Optimization
**What:** Optimizing before measuring, making code complex for negligible gains.
```python
# BAD: Premature optimization making code unclear
# Instead of simple: result = [x * 2 for x in items]
result = []
result_append = result.append  # "Optimization" to cache method
for x in items:
    result_append(x << 1)  # Using bit shift "for speed"
```
**Fix:** Write clear code first, optimize after profiling shows bottlenecks.

#### 27. Loading Everything Into Memory
**What:** Reading entire large files/datasets into memory at once.
```python
# BAD: Loading huge file into memory
with open('huge_log.txt') as f:
    lines = f.readlines()  # Loads entire file!
    for line in lines:
        process(line)

# BAD: Loading all records
users = User.query.all()  # Could be millions of records!
for user in users:
    process(user)
```
**Fix:** Stream/iterate data in chunks.
```python
# GOOD: Stream file
with open('huge_log.txt') as f:
    for line in f:  # Reads line by line
        process(line)

# GOOD: Batch processing
for users_batch in User.query.yield_per(1000):
    process_batch(users_batch)
```

#### 28. Repeated Expensive Computations
**What:** Recalculating same values in loops or multiple times.
```python
# BAD: Repeated calculation
for i in range(len(items)):
    # expensive_calc() called len(items) times!
    if items[i] > expensive_calc():
        process(items[i])

# BAD: Repeated I/O in loop
for user in users:
    config = load_config_from_file()  # Loads file every iteration!
    process(user, config)
```
**Fix:** Calculate once and reuse.

#### 29. Unbounded Caching
**What:** Caches that grow indefinitely without eviction policy.
```python
# BAD: Cache with no size limit or TTL
cache = {}

def get_data(key):
    if key not in cache:
        cache[key] = expensive_fetch(key)  # Cache grows forever!
    return cache[key]
```
**Fix:** Use LRU cache, TTL, or proper caching library with limits.

---

### CONCURRENCY ANTI-PATTERNS

#### 30. Race Conditions
**What:** Outcome depends on timing/ordering of uncontrollable events.
```python
# BAD: Check-then-act race condition
if not file_exists(path):
    # Another thread might create file here!
    create_file(path)  # May fail or overwrite

# BAD: Read-modify-write race
balance = account.balance  # Read
new_balance = balance - amount  # Modify
account.balance = new_balance  # Write - another thread may have modified!
```
**Fix:** Use atomic operations, locks, or database transactions.

#### 31. Deadlocks
**What:** Two or more threads waiting for each other to release resources.
```python
# BAD: Different lock ordering in different places
def transfer_a_to_b():
    with lock_a:
        with lock_b:  # A then B
            transfer()

def transfer_b_to_a():
    with lock_b:
        with lock_a:  # B then A - potential deadlock!
            transfer()
```
**Fix:** Always acquire locks in same order, use timeout, or use higher-level constructs.

#### 32. Blocking the Event Loop
**What:** Performing synchronous blocking operations in async code.
```python
# BAD: Blocking in async function
async def handle_request():
    data = requests.get(url)  # Blocks event loop!
    result = time.sleep(5)  # Blocks event loop!
    file_data = open('file.txt').read()  # Blocks event loop!
    return process(data)
```
**Fix:** Use async versions (aiohttp, asyncio.sleep, aiofiles).

---

### TESTING ANTI-PATTERNS

#### 33. Testing Implementation Details
**What:** Tests that break when refactoring without behavior changes.
```python
# BAD: Testing private methods and internals
def test_internal_cache():
    obj._internal_cache = {}  # Testing private attribute
    obj._update_cache()  # Testing private method
    assert len(obj._internal_cache) == 1
```
**Fix:** Test public interface and observable behavior.

#### 34. Flaky Tests
**What:** Tests that sometimes pass and sometimes fail without code changes.
```python
# BAD: Time-dependent test
def test_recent_users():
    create_user()
    time.sleep(0.1)  # Flaky - may not be enough time
    users = get_recent_users()
    assert len(users) == 1

# BAD: Order-dependent test
def test_users():
    users = get_all_users()
    assert users[0].name == "Alice"  # Assumes order
```
**Fix:** Make tests deterministic - use mocks, freeze time, avoid assumptions about order.

#### 35. Test Interdependence
**What:** Tests that depend on other tests running first.
```python
# BAD: Tests sharing state
class TestUser:
    def test_create_user(self):
        self.user = create_user("Alice")  # Creates shared state
    
    def test_user_email(self):
        assert self.user.email  # Depends on previous test running!
```
**Fix:** Each test should be independent with its own setup/teardown.

#### 36. Assertionless Tests
**What:** Tests that execute code but don't verify anything.
```python
# BAD: No assertions
def test_process_order():
    order = create_order()
    process_order(order)  # Runs but verifies nothing!
    # Missing: assert order.status == "processed"
```
**Fix:** Every test must have assertions verifying expected behavior.

---

### DESIGN ANTI-PATTERNS

#### 37. Tight Coupling
**What:** Classes/modules directly depending on concrete implementations.
```python
# BAD: Tight coupling to specific implementation
class OrderProcessor:
    def __init__(self):
        self.db = MySQLDatabase()  # Directly coupled to MySQL
        self.payment = StripePayment()  # Directly coupled to Stripe
        self.email = SendGridEmail()  # Directly coupled to SendGrid
```
**Fix:** Depend on interfaces/abstractions (dependency injection).

#### 38. Circular Dependencies
**What:** Two or more modules depending on each other.
```python
# BAD: Circular dependency
# file: user.py
from order import Order
class User:
    def get_orders(self) -> List[Order]: ...

# file: order.py
from user import User
class Order:
    def get_user(self) -> User: ...
```
**Fix:** Extract common interface, use dependency injection, or refactor structure.

#### 39. Feature Envy
**What:** Method that uses more features of another class than its own.
```python
# BAD: Method envious of Customer class
class Order:
    def calculate_discount(self):
        if self.customer.loyalty_points > 100:  # Using customer data
            base = self.customer.total_purchases * 0.1  # Using customer data
            if self.customer.is_premium:  # Using customer data
                return base * 1.5
        return 0
```
**Fix:** Move the method to the class whose data it uses.

#### 40. Primitive Obsession
**What:** Using primitives instead of small objects for domain concepts.
```python
# BAD: Using primitives for domain concepts
def create_user(name: str, email: str, phone: str, zipcode: str):
    if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+

### 1. **Nitpicking Style Over Substance**
- ❌ "This line should have a space after the comma"
- ✅ "This function has a critical race condition in the checkout process"

Use linters for style. Focus your human/AI review on logic, security, and design.

### 2. **Being Vague**
- ❌ "This code is bad"
- ✅ "This function makes 50 database queries in a loop, causing O(n²) performance"

### 3. **Not Explaining Why**
- ❌ "Don't use `eval()`"
- ✅ "Don't use `eval()` because it executes arbitrary code and can be exploited by attackers to run malicious commands"

### 4. **Suggesting Your Preference as a Rule**
- ❌ "I prefer to use map() instead of list comprehensions"
- ✅ "Consider using list comprehensions here as they're more readable and Pythonic, though map() works too"

### 5. **Missing the Forest for the Trees**
Don't just review syntax - review:
- Does this solve the right problem?
- Is this the right architectural approach?
- Will this scale?
- Is this maintainable?

---

## Language-Specific Considerations

### PHP
- [ ] Are type declarations used (PHP 7.4+: typed properties, PHP 8+: union types)?
- [ ] Is strict_types declared (`declare(strict_types=1);`) at file top?
- [ ] Are SQL queries using prepared statements (PDO/MySQLi)?
- [ ] Are password_hash() and password_verify() used (never md5/sha1)?
- [ ] Are output escaped properly (htmlspecialchars with ENT_QUOTES)?
- [ ] Is === used instead of == for comparisons?
- [ ] Are array functions used efficiently (array_map, array_filter)?
- [ ] Are null coalescing (??) and nullsafe operators (?->) used appropriately?
- [ ] Is error_reporting(E_ALL) enabled in development?
- [ ] Are sessions properly secured (HttpOnly, Secure, SameSite cookies)?
- [ ] **Is PSR-12 coding standard followed (REQUIRED)?**
- [ ] Are files UTF-8 encoded without BOM?
- [ ] Are LF (Unix) line endings used (not CRLF)?
- [ ] Is 4-space indentation used (no tabs)?
- [ ] Is line length limited to 120 chars soft limit (80 chars preferred)?
- [ ] Are namespaces declared properly after `declare(strict_types=1)`?
- [ ] Are use statements grouped and sorted alphabetically?
- [ ] Are class names in PascalCase and methods in camelCase?
- [ ] Are opening braces for classes/methods on the same line?
- [ ] Is the closing `?>` tag omitted in pure PHP files?
- [ ] Are there no trailing whitespaces?
- [ ] Is there one statement per line (no multiple statements)?
- [ ] Are early return patterns used to reduce nesting?
- [ ] Is nesting limited to maximum 4 levels?

**PHP Anti-Patterns:**
```php
// BAD: No type declarations
function process($data) {
    return $data * 2;
}

// GOOD: Strict types and declarations (PSR-12)
declare(strict_types=1);

function process(int $data): int {
    return $data * 2;
}

// BAD: Wrong file structure (not PSR-12 compliant)
<?php
namespace App\Controllers;
declare(strict_types=1);  // WRONG: declare must come before namespace
use App\Models\User;

// GOOD: PSR-12 file structure
<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Models\User;
use App\Services\AuthService;
use Exception;

class UserController
{
    // class body
}
// Note: No closing ?> tag in pure PHP files (PSR-12)

// BAD: Wrong indentation (tabs or wrong spacing)
class Example {
		public function test() {  // Using tabs - WRONG
  return true;  // 2 spaces - WRONG
	}
}

// GOOD: PSR-12 indentation (4 spaces, no tabs)
class Example
{
    public function test(): bool
    {
        return true;
    }
}

// BAD: Wrong brace placement (not PSR-12)
class Example {  // Opening brace on same line - WRONG for classes
    public function test()  // Opening brace on next line - WRONG for methods
    {
        return true;
    }
}

// GOOD: PSR-12 brace placement
class Example
{
    public function test(): bool
    {
        if ($condition) {  // Opening brace on same line for control structures
            return true;
        }
        
        return false;
    }
}

// BAD: Wrong naming conventions
class user_controller {  // snake_case - WRONG
    public function Get_User() {  // PascalCase method - WRONG
        return true;
    }
}

// GOOD: PSR-12 naming (PascalCase for classes, camelCase for methods)
class UserController
{
    public function getUser(): ?User
    {
        return $this->findUser();
    }
}

// BAD: Multiple statements per line
$user = new User(); $user->save(); return $user;

// GOOD: One statement per line (PSR-12)
$user = new User();
$user->save();
return $user;

// BAD: Line too long (over 120 characters)
$result = $this->someVeryLongMethodName($parameter1, $parameter2, $parameter3, $parameter4, $parameter5, $parameter6, $parameter7);

// GOOD: Split long lines (prefer 80 chars, max 120)
$result = $this->someVeryLongMethodName(
    $parameter1,
    $parameter2,
    $parameter3,
    $parameter4,
    $parameter5
);

// BAD: Improper use statement grouping
use App\Models\User;
use Exception;
use App\Services\AuthService;
use InvalidArgumentException;

// GOOD: PSR-12 use statement grouping and sorting
use App\Models\User;
use App\Services\AuthService;

use Exception;
use InvalidArgumentException;

// BAD: No blank lines (PSR-12 requires specific blank line placement)
<?php
declare(strict_types=1);
namespace App\Controllers;
use App\Models\User;
class UserController
{
    public function index(): void
    {
        $users = User::all();
        return view('users', compact('users'));
    }
    public function show(int $id): void
    {
        // Missing blank line between methods
    }
}

// GOOD: PSR-12 blank line requirements
<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Models\User;

class UserController
{
    public function index(): void
    {
        $users = User::all();
        
        return view('users', compact('users'));
    }

    public function show(int $id): void
    {
        $user = User::find($id);
        
        return view('user', compact('user'));
    }
}

// BAD: SQL injection
$result = mysqli_query($conn, "SELECT * FROM users WHERE id = {$_GET['id']}");

// GOOD: Prepared statements
$stmt = $conn->prepare("SELECT * FROM users WHERE id = ?");
$stmt->bind_param("i", $_GET['id']);
$stmt->execute();

// BAD: Insecure password hashing
$hash = md5($password);
$hash = sha1($password);

// GOOD: Modern password hashing
$hash = password_hash($password, PASSWORD_ARGON2ID);

// BAD: Loose comparison pitfalls
if ($_GET['admin'] == true) // "1", "true", "yes" all match!

// GOOD: Strict comparison (always use === in PHP)
if ($_GET['admin'] === '1')

// BAD: Not escaping output (XSS)
echo "<div>$userInput</div>";

// GOOD: Escape output
echo "<div>" . htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8') . "</div>";

// BAD: Suppressing errors with @
@file_get_contents($url);

// GOOD: Proper error handling
try {
    $content = file_get_contents($url);
    if ($content === false) {
        throw new RuntimeException("Failed to fetch URL");
    }
} catch (Exception $e) {
    $this->logger->error("URL fetch failed: " . $e->getMessage());
}

// BAD: Not using strict types
function calculate($a, $b) {
    return $a + $b;
}
calculate("5", "10");  // Returns 15 (string coercion)

// GOOD: Strict types declared (PSR-12 best practice)
declare(strict_types=1);

function calculate(int $a, int $b): int
{
    return $a + $b;
}
// calculate("5", "10"); // Would throw TypeError

// BAD: Deep nesting (arrow anti-pattern)
public function processOrder(Order $order): void
{
    if ($order->isValid()) {
        if ($order->hasItems()) {
            if ($order->user->isActive()) {
                if ($order->user->hasPaymentMethod()) {
                    // Finally process, 5 levels deep!
                    $this->completeOrder($order);
                }
            }
        }
    }
}

// GOOD: Early returns (PSR-12 best practice, max 4 levels)
public function processOrder(Order $order): void
{
    if (!$order->isValid()) {
        throw new InvalidOrderException("Order is not valid");
    }
    
    if (!$order->hasItems()) {
        throw new EmptyOrderException("Order has no items");
    }
    
    if (!$order->user->isActive()) {
        throw new InactiveUserException("User account is inactive");
    }
    
    if (!$order->user->hasPaymentMethod()) {
        throw new PaymentException("No payment method available");
    }
    
    $this->completeOrder($order);
}

// BAD: CRLF line endings (Windows style)
// Files should use LF (Unix) line endings only

// BAD: BOM in UTF-8 file
// Files must be UTF-8 without BOM (Byte Order Mark)

// BAD: Closing PHP tag in pure PHP files
class Example
{
    // class body
}
?>  // WRONG: Remove closing tag in pure PHP files

// GOOD: No closing tag (PSR-12)
class Example
{
    // class body
}
// File ends here without closing tag
```

**PSR-12 Critical Requirements (MUST follow):**

1. **File Structure Order:**
   - Opening `<?php` tag
   - `declare(strict_types=1);` statement
   - Namespace declaration
   - Use declarations (grouped and sorted)
   - Class declaration
   - (No closing `?>` tag)

2. **Formatting:**
   - UTF-8 encoding without BOM
   - LF (Unix) line endings only
   - 4 spaces for indentation (NO TABS)
   - 120 character soft limit (80 preferred)
   - No trailing whitespace
   - One statement per line
   - Files must end with non-blank line

3. **Naming Conventions:**
   - Classes: PascalCase (e.g., `UserController`)
   - Methods: camelCase (e.g., `getUserById`)
   - Constants: UPPER_CASE (e.g., `MAX_ITEMS`)
   - Properties: camelCase (e.g., `$userName`)

4. **Braces:**
   - Classes: Opening brace on next line
   - Methods: Opening brace on next line
   - Control structures: Opening brace on same line
   - Always use braces for control structures

5. **Spacing:**
   - One blank line after namespace declaration
   - One blank line after use declarations block
   - One blank line between methods
   - Space after control structure keywords
   - No space between method name and opening parenthesis

6. **Type Declarations:**
   - Always use strict types: `declare(strict_types=1);`
   - Declare parameter types and return types
   - Use nullable types when appropriate: `?Type`
   - Use union types (PHP 8+): `int|float`

**Tools for PSR-12 Compliance:**
- **PHP_CodeSniffer**: Detects violations (`phpcs`)
- **PHP CS Fixer**: Automatically fixes violations (`php-cs-fixer`)
- **PHPStorm**: Built-in PSR-12 support in IDE settings

**Command to check PSR-12 compliance:**
```bash
vendor/bin/phpcs --standard=PSR12 src/
```

**Command to auto-fix PSR-12 violations:**
```bash
vendor/bin/phpcbf --standard=PSR12 src/
```

### JavaScript
- [ ] Are `const`/`let` used (never `var`)?
- [ ] Are === and !== used (avoid == and !=)?
- [ ] Are Promises handled (no unhandled rejections)?
- [ ] Are event listeners properly cleaned up?
- [ ] Is user input sanitized before DOM insertion?
- [ ] Are array methods used idiomatically (map, filter, reduce)?
- [ ] Is optional chaining (?.) used for nested property access?
- [ ] Are template literals used instead of string concatenation?
- [ ] Is 'use strict' enabled (or ES modules which are strict by default)?

**JavaScript Anti-Patterns:**
```javascript
// BAD: Using var (function-scoped, hoisting issues)
var count = 0;
if (true) {
    var count = 1; // Overwrites outer count!
}

// GOOD: Use const/let (block-scoped)
let count = 0;
if (true) {
    let count = 1; // Separate scope
}

// BAD: Loose equality
if (value == null) // Matches both null and undefined
if (count == "5") // Type coercion surprises

// GOOD: Strict equality
if (value === null)
if (count === 5)

// BAD: Unhandled promise rejection
fetch(url).then(data => process(data));

// GOOD: Handle errors
fetch(url)
    .then(data => process(data))
    .catch(err => console.error('Fetch failed:', err));

// BETTER: Async/await with try-catch
try {
    const data = await fetch(url);
    process(data);
} catch (err) {
    console.error('Fetch failed:', err);
}

// BAD: XSS vulnerability
element.innerHTML = userInput;

// GOOD: Safe insertion
element.textContent = userInput;
// OR sanitize HTML if needed
element.innerHTML = DOMPurify.sanitize(userInput);

// BAD: Not cleaning up listeners (memory leak)
element.addEventListener('click', handler);
// Element removed but listener still in memory

// GOOD: Clean up
element.removeEventListener('click', handler);
// OR use AbortController
const controller = new AbortController();
element.addEventListener('click', handler, { signal: controller.signal });
controller.abort(); // Removes listener

// BAD: Nested property access without checks
const city = user.address.city; // Crashes if address is undefined

// GOOD: Optional chaining
const city = user?.address?.city;

// BAD: String concatenation
const message = "Hello " + user.name + ", you have " + count + " items";

// GOOD: Template literals
const message = `Hello ${user.name}, you have ${count} items`;
```

### TypeScript
- [ ] Are types meaningful (avoid `any`, use `unknown` if needed)?
- [ ] Are strict mode options enabled in tsconfig.json?
- [ ] Are interfaces used for object shapes, types for unions/primitives?
- [ ] Are return types explicitly declared on functions?
- [ ] Are generics used appropriately for reusable code?
- [ ] Are enums used for fixed sets of values?
- [ ] Is non-null assertion (!) avoided (use proper null checks)?
- [ ] Are type guards used for runtime type checking?
- [ ] Are utility types used (Partial, Pick, Omit, etc.)?

**TypeScript Anti-Patterns:**
```typescript
// BAD: Using any (defeats purpose of TypeScript)
function process(data: any): any {
    return data.value;
}

// GOOD: Proper types
interface Data {
    value: string;
}
function process(data: Data): string {
    return data.value;
}

// BAD: Not enabling strict mode
// tsconfig.json: "strict": false

// GOOD: Enable strict mode
// tsconfig.json: "strict": true

// BAD: Non-null assertion (dangerous)
const value = getUserInput()!.value; // Crashes if null!

// GOOD: Proper null check
const input = getUserInput();
const value = input?.value ?? defaultValue;

// BAD: Type assertion without validation
const user = data as User; // No runtime check!

// GOOD: Type guard with validation
function isUser(data: unknown): data is User {
    return typeof data === 'object' && 
           data !== null &&
           'name' in data &&
           'email' in data;
}

if (isUser(data)) {
    // TypeScript knows data is User here
    console.log(data.name);
}

// BAD: Missing return type (implicit any in some cases)
function calculate(x: number) {
    return x * 2;
}

// GOOD: Explicit return type
function calculate(x: number): number {
    return x * 2;
}

// BAD: Using type when interface is clearer
type User = {
    name: string;
    email: string;
}

// GOOD: Interface for object shapes
interface User {
    name: string;
    email: string;
}

// GOOD: Type for unions and primitives
type Status = 'active' | 'inactive' | 'pending';
type ID = string | number;
```

### CSS/SASS
- [ ] Are class names semantic and following BEM or consistent methodology?
- [ ] Are magic numbers avoided (use variables for repeated values)?
- [ ] Is specificity kept low (avoid deep nesting and !important)?
- [ ] Are vendor prefixes handled by autoprefixer (not manual)?
- [ ] Are CSS custom properties (variables) used for theming?
- [ ] Is mobile-first approach used for responsive design?
- [ ] Are units appropriate (rem/em for typography, px for borders)?
- [ ] Is CSS organized logically (by component or feature)?
- [ ] Are animations performant (transform/opacity, avoid layout properties)?

**CSS/SASS Anti-Patterns:**
```scss
// BAD: Deep nesting (high specificity, hard to override)
.header {
    .nav {
        .menu {
            .item {
                .link {
                    color: blue; // 5 levels deep!
                }
            }
        }
    }
}

// GOOD: Flat structure with BEM
.header__nav-link {
    color: blue;
}

// BAD: Magic numbers
.container {
    padding: 23px;
    margin: 17px;
    width: 847px;
}

// GOOD: Variables for meaningful values
$spacing-unit: 8px;
$container-width: 1200px;

.container {
    padding: $spacing-unit * 3;
    margin: $spacing-unit * 2;
    max-width: $container-width;
}

// BAD: !important everywhere
.button {
    color: red !important;
    padding: 10px !important;
}

// GOOD: Proper specificity
.button--primary {
    color: red;
    padding: 10px;
}

// BAD: Animating layout properties (janky)
.box {
    transition: width 0.3s, height 0.3s, top 0.3s;
}

// GOOD: Animate transform/opacity (smooth)
.box {
    transition: transform 0.3s, opacity 0.3s;
}
.box--expanded {
    transform: scale(1.5);
}

// BAD: Desktop-first (harder to maintain)
.container {
    width: 1200px;
    
    @media (max-width: 768px) {
        width: 100%;
    }
}

// GOOD: Mobile-first
.container {
    width: 100%;
    
    @media (min-width: 768px) {
        width: 1200px;
    }
}

// BAD: Inline vendor prefixes
.box {
    -webkit-transform: rotate(45deg);
    -moz-transform: rotate(45deg);
    -ms-transform: rotate(45deg);
    transform: rotate(45deg);
}

// GOOD: Let autoprefixer handle it
.box {
    transform: rotate(45deg);
}
```

### HTML
- [ ] Is semantic HTML used (header, nav, main, article, section, aside, footer)?
- [ ] Are ARIA attributes used correctly for accessibility?
- [ ] Are forms properly labeled (label with for attribute)?
- [ ] Are images alt attributes descriptive (or empty for decorative)?
- [ ] Is proper heading hierarchy used (h1-h6 in order)?
- [ ] Are interactive elements keyboard accessible?
- [ ] Is HTML5 doctype used (`<!DOCTYPE html>`)?
- [ ] Are meta tags present (viewport, charset, description)?
- [ ] Are scripts loaded with async/defer when appropriate?

**HTML Anti-Patterns:**
```html
<!-- BAD: Non-semantic div soup -->
<div class="header">
    <div class="nav">
        <div class="nav-item">Home</div>
    </div>
</div>
<div class="content">
    <div class="post">...</div>
</div>

<!-- GOOD: Semantic HTML -->
<header>
    <nav>
        <a href="/">Home</a>
    </nav>
</header>
<main>
    <article>...</article>
</main>

<!-- BAD: Missing alt attributes -->
<img src="logo.png">

<!-- GOOD: Descriptive alt -->
<img src="logo.png" alt="Company logo - Home">
<img src="decorative.png" alt=""> <!-- Empty for decorative -->

<!-- BAD: Unlabeled form inputs -->
<input type="text" placeholder="Name">

<!-- GOOD: Properly labeled -->
<label for="name">Name</label>
<input type="text" id="name" placeholder="Enter your name">

<!-- BAD: Non-interactive div used as button -->
<div onclick="submit()">Submit</div>

<!-- GOOD: Proper button element -->
<button type="submit">Submit</button>

<!-- BAD: Wrong heading hierarchy -->
<h1>Page Title</h1>
<h3>Subsection</h3> <!-- Skipped h2 -->

<!-- GOOD: Proper hierarchy -->
<h1>Page Title</h1>
<h2>Section</h2>
<h3>Subsection</h3>
```

### Python
- [ ] Are type hints used (Python 3.5+)?
- [ ] Are context managers used (`with` statements)?
- [ ] Are list comprehensions appropriate (not overly complex)?
- [ ] Are mutable default arguments avoided?
- [ ] Is proper exception hierarchy used?
- [ ] Are f-strings used for formatting (Python 3.6+)?
- [ ] Is pathlib used instead of os.path (Python 3.4+)?
- [ ] Are dataclasses used for data containers (Python 3.7+)?
- [ ] Is the walrus operator (:=) used appropriately (Python 3.8+)?
- [ ] Is the shebang `#!/usr/bin/env python3` used?
- [ ] Is PEP 8 style followed (4 spaces indentation)?
- [ ] Is `argparse` used for CLI arguments?
- [ ] Is line length limited to 110 characters?
- [ ] Are early return patterns used to reduce nesting?
- [ ] Is nesting limited to maximum 4 levels?

**Python Anti-Patterns:**
```python
# BAD: No type hints
def calculate(x, y):
    return x + y

# GOOD: Type hints
def calculate(x: int, y: int) -> int:
    return x + y

# BAD: Wrong shebang
#!/usr/bin/python
#!/usr/local/bin/python3

# GOOD: Portable shebang
#!/usr/bin/env python3

# BAD: Not using context managers
file = open('data.txt')
data = file.read()
file.close()  # May not execute if error occurs

# GOOD: Context manager ensures cleanup
with open('data.txt') as file:
    data = file.read()

# BAD: Overly complex list comprehension
result = [x * 2 for x in items if x > 0 if x % 2 == 0 if x < 100]

# GOOD: Use filter or for loop for readability
result = [x * 2 for x in items 
          if x > 0 and x % 2 == 0 and x < 100]

# BAD: Mutable default argument
def append_to(item, list=[]):
    list.append(item)
    return list

# GOOD: Use None as default
def append_to(item, list=None):
    if list is None:
        list = []
    list.append(item)
    return list

# BAD: Old string formatting
name = "Alice"
message = "Hello %s, you have %d messages" % (name, count)
message = "Hello {}, you have {} messages".format(name, count)

# GOOD: F-strings (Python 3.6+)
message = f"Hello {name}, you have {count} messages"

# BAD: Using os.path
import os
path = os.path.join(base, "subdir", "file.txt")
if os.path.exists(path):
    with open(path) as f:
        data = f.read()

# GOOD: Using pathlib
from pathlib import Path
path = Path(base) / "subdir" / "file.txt"
if path.exists():
    data = path.read_text()

# BAD: Manual class for data
class User:
    def __init__(self, name, email, age):
        self.name = name
        self.email = email
        self.age = age

# GOOD: Dataclass
from dataclasses import dataclass

@dataclass
class User:
    name: str
    email: str
    age: int

# BAD: Manual argument parsing
import sys
if len(sys.argv) < 2:
    print("Usage: script.py <filename>")
    sys.exit(1)
filename = sys.argv[1]

# GOOD: Use argparse for CLI arguments
import argparse

parser = argparse.ArgumentParser(description='Process a file')
parser.add_argument('filename', help='File to process')
args = parser.parse_args()

# BAD: Deep nesting (arrow anti-pattern)
def process_user(user_data):
    if user_data:
        if 'email' in user_data:
            if user_data['email']:
                if '@' in user_data['email']:
                    # Finally process, 5 levels deep!
                    send_email(user_data['email'])

# GOOD: Early return pattern (max 4 levels nesting)
def process_user(user_data: dict) -> None:
    if not user_data:
        return
    
    if 'email' not in user_data:
        return
    
    if not user_data['email']:
        return
    
    if '@' not in user_data['email']:
        return
    
    # Main logic at top level
    send_email(user_data['email'])

# BAD: Line too long (readability issue)
result = some_function(argument1, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9)

# GOOD: Line length limited to 110 characters (4 space indentation)
result = some_function(
    argument1, argument2, argument3,
    argument4, argument5, argument6,
    argument7, argument8, argument9
)
```

**Python Formatting Requirements:**
- **Shebang**: `#!/usr/bin/env python3` for scripts
- **Indentation**: 4 spaces (PEP 8), not tabs
- **Line Length**: Maximum 110 characters
- **Style Guide**: Follow PEP 8
- **CLI Arguments**: Use `argparse` for command-line tools
- **Encoding**: UTF-8 with proper encoding declaration if needed

### Go
- [ ] Are errors always checked (never ignored)?
- [ ] Are defer statements used for cleanup?
- [ ] Are goroutines properly managed (no leaks)?
- [ ] Is context used for cancellation and timeouts?
- [ ] Are channels closed by sender (not receiver)?
- [ ] Is go fmt used for formatting?
- [ ] Are error messages lowercase and not ending with punctuation?
- [ ] Are interfaces small and focused?
- [ ] Is sync.WaitGroup used for goroutine coordination?

**Go Anti-Patterns:**
```go
// BAD: Ignoring errors
data, _ := os.ReadFile("config.json")
result, _ := strconv.Atoi(input)

// GOOD: Check all errors
data, err := os.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("failed to read config: %w", err)
}

// BAD: Not using defer for cleanup
file, err := os.Open("data.txt")
if err != nil {
    return err
}
data, err := io.ReadAll(file)
file.Close() // May not execute if ReadAll fails

// GOOD: Use defer
file, err := os.Open("data.txt")
if err != nil {
    return err
}
defer file.Close()
data, err := io.ReadAll(file)

// BAD: Goroutine leak (no coordination)
go func() {
    // Long running task
    process()
}() // No way to stop or wait for this

// GOOD: Use context for cancellation
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

go func(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            process()
        }
    }
}(ctx)

// BAD: Receiver closing channel
func worker(ch chan int) {
    for v := range ch {
        process(v)
    }
    close(ch) // WRONG: Receiver shouldn't close
}

// GOOD: Sender closes channel
func producer(ch chan int) {
    defer close(ch) // Sender closes
    for i := 0; i < 10; i++ {
        ch <- i
    }
}

// BAD: Error messages with capitals/punctuation
return errors.New("Failed to connect to database.")

// GOOD: Lowercase, no punctuation
return errors.New("failed to connect to database")

// BAD: Large interface
type Repository interface {
    Create(entity Entity) error
    Read(id string) (Entity, error)
    Update(entity Entity) error
    Delete(id string) error
    List() ([]Entity, error)
    Search(query string) ([]Entity, error)
    // 10+ more methods
}

// GOOD: Small, focused interfaces
type Reader interface {
    Read(id string) (Entity, error)
}

type Writer interface {
    Create(entity Entity) error
    Update(entity Entity) error
}
```

### Bash/Zsh
- [ ] Is `set -euo pipefail` used at script start (Bash) or appropriate error handling (Zsh)?
- [ ] Are variables quoted to prevent word splitting (`"$variable"`)?
- [ ] Are command substitutions using $() instead of backticks?
- [ ] Are functions used for repeated logic?
- [ ] Are error messages sent to stderr (`>&2`)?
- [ ] Is shellcheck used for linting (note: limited Zsh support)?
- [ ] Are exit codes checked after critical commands?
- [ ] Are temporary files created securely (mktemp)?
- [ ] Is the target shell (Bash vs Zsh) clear and appropriate patterns used?
- [ ] Are early return patterns used to reduce nesting?
- [ ] Is nesting limited to maximum 4 levels?
- [ ] Are variables using proper naming (`snake_case` for locals, `UPPER_CASE` for env vars)?
- [ ] Is input validation present for all user input?
- [ ] Are command injection vulnerabilities prevented?
- [ ] Are URL constructions properly quoted?
- [ ] Is line length limited to 110 characters?
- [ ] Are LF line endings and UTF-8 encoding used?
- [ ] Is 2-space indentation used for shell scripts?

**Bash/Zsh Anti-Patterns:**
```bash
#!/bin/bash

# BAD: No error handling
echo "Processing files..."
process_files
echo "Done"

# GOOD (Bash): Fail on error
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

echo "Processing files..."
if ! process_files; then
    echo "Error: Failed to process files" >&2
    exit 1
fi
echo "Done"

# GOOD (Zsh): Appropriate error handling
#!/usr/bin/env zsh
setopt ERR_EXIT  # Exit on error (Zsh equivalent)

echo "Processing files..."
if ! process_files; then
    echo "❌ Failed to process files" >&2
    return 1
fi
echo "Done"

# BAD: Unquoted variables (word splitting, glob expansion)
file=$1
cp $file /backup/  # Fails if filename has spaces

# GOOD: Quote variables
file="$1"
cp "$file" /backup/

# BAD: Using backticks
files=`ls *.txt`

# GOOD: Use $()
files=$(ls *.txt)

# BAD: Deep nesting (arrow anti-pattern)
function validate_and_process() {
    if [[ -n "$1" ]]; then
        if [[ -f "$1" ]]; then
            if [[ -r "$1" ]]; then
                if [[ -s "$1" ]]; then
                    # Finally process, 5 levels deep!
                    process_file "$1"
                fi
            fi
        fi
    fi
}

# GOOD: Early return pattern (REQUIRED - max 4 levels nesting)
function validate_and_process() {
    local file="$1"
    
    # Validate early and return
    if [[ -z "$file" ]]; then
        echo "❌ Missing file parameter" >&2
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        echo "❌ File not found: $file" >&2
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        echo "❌ File not readable: $file" >&2
        return 1
    fi
    
    if [[ ! -s "$file" ]]; then
        echo "❌ File is empty: $file" >&2
        return 1
    fi
    
    # Main logic at top level
    process_file "$file"
}

# BAD: Missing input validation (security risk)
function clone_repo() {
    local repo="$1"
    git clone "https://github.com/$repo"  # Command injection risk!
}

# GOOD: Input validation
function clone_repo() {
    local repo="$1"
    
    # Validate input format
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo" >&2
        return 1
    fi
    
    git clone "https://github.com/$repo"
}

# BAD: URL construction without quoting (injection risk)
version="$1"
curl https://example.com/${version}/file.sh | sh

# GOOD: Properly quoted URL construction
version="$1"
local url="https://example.com/${version#v}/file.sh"
curl "$url" | sh

# BAD: Inconsistent naming conventions
MyFunction() {
    local MyVar="value"
    ANOTHER_VAR="test"
}

# GOOD: Consistent naming (snake_case for functions/vars, UPPER for env)
my_function() {
    local my_var="value"
    local another_var="test"
    export MY_ENV_VAR="global"
}

# BAD: No function-scoped variables
process_data() {
    result="some value"  # Global scope pollution!
}

# GOOD: Use local
process_data() {
    local result="some value"
    echo "$result"
}

# BAD: Repeated code
echo "Starting task 1"
do_something
echo "Completed task 1"
echo "Starting task 2"
do_something_else
echo "Completed task 2"

# GOOD: Use functions
run_task() {
    local task_name="$1"
    local task_command="$2"
    
    echo "Starting $task_name"
    $task_command
    echo "Completed $task_name"
}

run_task "task 1" "do_something"
run_task "task 2" "do_something_else"

# BAD: Errors to stdout
if [ ! -f "$file" ]; then
    echo "File not found: $file"
fi

# GOOD: Errors to stderr with clear formatting
if [[ ! -f "$file" ]]; then
    echo "❌ Error: File not found: $file" >&2
    return 1
fi

# BAD: Insecure temp file
tmpfile="/tmp/myapp.tmp"
echo "data" > $tmpfile

# GOOD: Secure temp file with cleanup
tmpfile=$(mktemp)
trap "rm -f $tmpfile" EXIT
echo "data" > "$tmpfile"

# BAD: Not checking command success
rm important_file.txt
echo "File deleted successfully"

# GOOD: Check exit code
if rm important_file.txt; then
    echo "✅ File deleted successfully"
else
    echo "❌ Error: Failed to delete file" >&2
    return 1
fi

# BAD: Long lines (readability issue)
curl -X POST "https://api.example.com/v1/endpoint" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"key":"value","another":"data"}'

# GOOD: Line length limited to 110 characters
curl -X POST "https://api.example.com/v1/endpoint" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"key":"value","another":"data"}'

# ZSH-SPECIFIC PATTERNS

# GOOD: Zsh command availability check
if (( $+commands[git] )); then
    echo "Git is available"
fi

# GOOD: Zsh array syntax
local packages=(
    git
    vim
    curl
)

for pkg in "${packages[@]}"; do
    install_package "$pkg"
done

# BAD: Using bash-specific patterns in Zsh files
# Don't use: mapfile, readarray, [[[ ]]], etc.

# GOOD: Zsh-appropriate patterns
local array=($(command that outputs lines))
```

**Shell Script Formatting Requirements:**
- **Line Endings**: LF (Unix style), never CRLF
- **Encoding**: UTF-8
- **Indentation**: 2 spaces (not tabs)
- **Line Length**: Maximum 110 characters
- **Final Newline**: Always insert final newline in file
- **Trailing Whitespace**: Remove all trailing whitespace

**Shell Script Security Requirements:**
- **Input Validation**: ALWAYS validate user input, especially repository names, URLs, file paths
- **Command Injection Prevention**: Never use untrusted data in command substitution without validation
- **URL Construction**: Always quote URL variables to prevent injection
- **File Operations**: Validate file paths, check for path traversal attacks
- **Remote Content**: Always warn users before executing remote content

**Zsh vs Bash Considerations:**
- **Primary Shell**: Assume Zsh unless explicitly stated otherwise
- **Shellcheck**: Note that shellcheck has limited Zsh support - some warnings are expected
- **Variable Declaration**: Use Zsh-appropriate patterns (`local var=$(command)` is acceptable in Zsh)
- **Array Handling**: Use Zsh array syntax, not bash-specific `mapfile`
- **Command Availability**: Check with `(( $+commands[cmd] ))` in Zsh
- **Error Checking**: Zsh error checking patterns are acceptable (`if [[ $? -ne 0 ]]`)
- **Compatibility**: Prefer POSIX-compliant syntax for portability where possible

---

## Decision Framework

When uncertain about whether to flag something, ask:

1. **Safety**: Could this cause data loss, security breach, or system failure?
   - If YES → Flag as CRITICAL/HIGH

2. **Correctness**: Does this have a bug or produce wrong results?
   - If YES → Flag as HIGH

3. **Performance**: Will this cause noticeable slowdown or not scale?
   - If YES → Flag as HIGH/MEDIUM

4. **Maintainability**: Will this make the codebase harder to maintain?
   - If YES → Flag as MEDIUM

5. **Style/Convention**: Is this just a style preference?
   - If YES → Consider if it's worth mentioning (probably LOW/INFO)

6. **Uncertainty**: Am I unsure if this is an issue?
   - If YES → Ask a question rather than stating it's wrong

---

## Final Checklist Before Submitting Review

- [ ] Have I reviewed all changes thoroughly?
- [ ] Are my comments constructive and specific?
- [ ] Have I explained the "why" behind each comment?
- [ ] Have I provided actionable suggestions?
- [ ] Have I acknowledged good code?
- [ ] Are my severity levels appropriate?
- [ ] Have I considered the context and constraints?
- [ ] Am I being respectful and collaborative?
- [ ] Have I checked for security issues?
- [ ] Have I verified correctness and performance?

---

## Continuous Improvement

As a reviewing agent, you should:
- Learn from patterns in code that cause production issues
- Update your checklist based on new vulnerabilities
- Adapt to project-specific patterns and conventions
- Balance thoroughness with review speed
- Calibrate severity levels based on actual impact

Remember: The goal is not to find every possible issue, but to catch issues that matter and help the team ship better code., email):  # Duplicate validation
        raise ValueError("Invalid email")
    if len(phone) != 10:  # Duplicate validation
        raise ValueError("Invalid phone")
    # ... more validation
```
**Fix:** Create value objects for domain concepts.
```python
# GOOD: Value objects encapsulate validation
@dataclass
class Email:
    value: str
    def __post_init__(self):
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+

### 1. **Nitpicking Style Over Substance**
- ❌ "This line should have a space after the comma"
- ✅ "This function has a critical race condition in the checkout process"

Use linters for style. Focus your human/AI review on logic, security, and design.

### 2. **Being Vague**
- ❌ "This code is bad"
- ✅ "This function makes 50 database queries in a loop, causing O(n²) performance"

### 3. **Not Explaining Why**
- ❌ "Don't use `eval()`"
- ✅ "Don't use `eval()` because it executes arbitrary code and can be exploited by attackers to run malicious commands"

### 4. **Suggesting Your Preference as a Rule**
- ❌ "I prefer to use map() instead of list comprehensions"
- ✅ "Consider using list comprehensions here as they're more readable and Pythonic, though map() works too"

### 5. **Missing the Forest for the Trees**
Don't just review syntax - review:
- Does this solve the right problem?
- Is this the right architectural approach?
- Will this scale?
- Is this maintainable?

---

## Language-Specific Considerations

### Python
- Check for proper use of context managers (`with` statements)
- Verify list comprehensions aren't overly complex
- Check for mutable default arguments
- Verify proper exception hierarchy
- Check for proper use of `__init__`, `__str__`, `__repr__`

### JavaScript/TypeScript
- Check for proper use of `const`/`let` (avoid `var`)
- Verify async/await patterns (no unhandled promise rejections)
- Check for proper event listener cleanup
- Verify TypeScript types are meaningful (not just `any`)
- Check for XSS vulnerabilities in DOM manipulation

### Java
- Check for proper resource management (try-with-resources)
- Verify proper use of generics
- Check for thread safety issues
- Verify proper equals/hashCode implementations
- Check for proper exception handling

### Go
- Check for proper error handling (not ignoring errors)
- Verify goroutine lifecycle management
- Check for proper use of defer
- Verify context usage for cancellation
- Check for race conditions

---

## Decision Framework

When uncertain about whether to flag something, ask:

1. **Safety**: Could this cause data loss, security breach, or system failure?
   - If YES → Flag as CRITICAL/HIGH

2. **Correctness**: Does this have a bug or produce wrong results?
   - If YES → Flag as HIGH

3. **Performance**: Will this cause noticeable slowdown or not scale?
   - If YES → Flag as HIGH/MEDIUM

4. **Maintainability**: Will this make the codebase harder to maintain?
   - If YES → Flag as MEDIUM

5. **Style/Convention**: Is this just a style preference?
   - If YES → Consider if it's worth mentioning (probably LOW/INFO)

6. **Uncertainty**: Am I unsure if this is an issue?
   - If YES → Ask a question rather than stating it's wrong

---

## Final Checklist Before Submitting Review

- [ ] Have I reviewed all changes thoroughly?
- [ ] Are my comments constructive and specific?
- [ ] Have I explained the "why" behind each comment?
- [ ] Have I provided actionable suggestions?
- [ ] Have I acknowledged good code?
- [ ] Are my severity levels appropriate?
- [ ] Have I considered the context and constraints?
- [ ] Am I being respectful and collaborative?
- [ ] Have I checked for security issues?
- [ ] Have I verified correctness and performance?

---

## Continuous Improvement

As a reviewing agent, you should:
- Learn from patterns in code that cause production issues
- Update your checklist based on new vulnerabilities
- Adapt to project-specific patterns and conventions
- Balance thoroughness with review speed
- Calibrate severity levels based on actual impact

Remember: The goal is not to find every possible issue, but to catch issues that matter and help the team ship better code., self.value):
            raise ValueError("Invalid email")

def create_user(name: str, email: Email, phone: Phone, zipcode: ZipCode):
    # Validation already done by value objects
```

#### 41. Speculative Generality
**What:** Adding functionality "just in case" it's needed in the future.
```python
# BAD: Over-engineering for imagined future needs
class ConfigManager:
    def __init__(self):
        self.strategies = {}  # We might need different strategies!
        self.plugins = []  # We might need plugins!
        self.hooks = {}  # We might need hooks!
    
    # Only using simple get/set, rest is unused complexity
```
**Fix:** YAGNI (You Aren't Gonna Need It) - add features when actually needed.

---

### NAMING ANTI-PATTERNS

#### 42. Inconsistent Naming
**What:** Using different names for the same concept throughout codebase.
```python
# BAD: Inconsistent naming for same concept
def get_user(): ...
def fetch_customer(): ...  # Same as user
def retrieve_client(): ...  # Same as user
def load_person(): ...  # Same as user
```
**Fix:** Use consistent terminology across codebase.

#### 43. Abbreviationitis
**What:** Overusing abbreviations making code cryptic.
```python
# BAD: Too many abbreviations
def proc_usr_ord(u_id, o_id, qty, dt):
    tmp = get_usr(u_id)
    ord = crt_ord(tmp, o_id, qty)
    ord.dt = dt
    return ord
```
**Fix:** Use clear, pronounceable names.
```python
# GOOD: Clear naming
def process_user_order(user_id, order_id, quantity, date):
    user = get_user(user_id)
    order = create_order(user, order_id, quantity)
    order.date = date
    return order
```

#### 44. Misleading Names
**What:** Names that suggest one thing but do another.
```python
# BAD: Name suggests it's read-only but it modifies
def get_or_create_user(email):
    user = find_user(email)
    if not user:
        user = User.create(email)  # Creates! Name says "get"
    return user

# BAD: Name suggests boolean but returns string
def is_valid_email(email):
    if validate(email):
        return "valid"  # Returns string, not boolean!
    return "invalid"
```
**Fix:** Names should accurately describe what function does.

---

### DOCUMENTATION ANTI-PATTERNS

#### 45. Outdated Comments
**What:** Comments that no longer match the code.
```python
# BAD: Outdated comment
# Returns user email
def get_user_data(user_id):
    return User.query.get(user_id)  # Now returns entire user object!

# Returns list of active users
def get_users():
    return User.query.all()  # Now returns all users, not just active!
```
**Fix:** Update comments when changing code, or remove if redundant.

#### 46. Commented-Out Code
**What:** Leaving old code commented "just in case".
```python
# BAD: Commented code left in
def calculate_price(price):
    # Old calculation
    # return price * 1.1
    # Another old version
    # return price * 1.15
    # Yet another one
    # return price * 1.12
    return price * 1.2  # Current
```
**Fix:** Delete it. That's what version control is for.

#### 47. Redundant Comments (WHAT/HOW Comments)
**What:** Comments that describe WHAT the code does or HOW it works instead of WHY.
```python
# BAD: Describing WHAT (redundant - code already shows this)
# Increment i by 1
i = i + 1

# Create a new user
user = User()

# Loop through all users and process them
for user in users:
    process(user)

# BAD: Describing HOW (redundant - code already shows this)
# Use list comprehension to filter active users
active_users = [u for u in users if u.is_active]

# Check if user exists in database
if User.exists(user_id):
    ...

# BAD: Comments explaining simple/obvious code
# Add item to cart
cart.add(item)

# Calculate total price
total = sum(item.price for item in cart.items)
```
**Fix:** Delete these comments entirely. Only comment WHY, and only for complex code.

**RULE:** If the comment describes WHAT the code does or HOW it works, delete it. The code should be self-documenting. If the code is unclear, refactor it to be clearer rather than adding comments.

**ONLY comment when:**
- Explaining WHY a decision was made (business logic, optimization trade-offs, workarounds)
- The code is inherently complex and the reasoning is not obvious
- There are non-obvious side effects or constraints

**Example of acceptable comment:**
```python
# GOOD: Explains WHY
# We must acquire lock A before lock B throughout the entire codebase
# to prevent deadlocks. See architecture doc: ARCH-123
with lock_a:
    with lock_b:
        process()
```

---

## CRITICAL: Anti-Pattern Detection Protocol

When reviewing code, **YOU MUST:**

1. **Actively scan for ALL 47 anti-patterns** listed above
2. **Flag every instance** with appropriate severity
3. **Explain why it's problematic** with specific consequences
4. **Provide concrete refactoring suggestion** showing the fix
5. **Reference the anti-pattern by name** in your review comment

**Special Requirements for Shell Scripts:**
- **ALWAYS check nesting depth** - flag if exceeds 4 levels
- **ALWAYS validate input validation** - flag missing validation
- **ALWAYS check for command injection** - validate all user inputs
- **ALWAYS check variable quoting** - flag unquoted variables
- **ALWAYS check line length** - flag lines over 110 characters
- **ALWAYS check for early returns** - flag deep nesting that could be flattened

**Special Requirements for PHP:**
- **ALWAYS verify PSR-12 compliance** - this is MANDATORY for PHP code
- **ALWAYS check file structure** - declare(strict_types=1) must be first after <?php
- **ALWAYS verify indentation** - must be 4 spaces, no tabs
- **ALWAYS check brace placement** - classes/methods next line, control structures same line
- **ALWAYS verify naming** - PascalCase for classes, camelCase for methods
- **ALWAYS check line endings** - must be LF (Unix), not CRLF
- **ALWAYS verify UTF-8 without BOM**
- **ALWAYS check for closing ?>** - must be omitted in pure PHP files
- **ALWAYS verify use statement grouping** - must be grouped and sorted
- **ALWAYS check type declarations** - strict_types and full type hints required

**Example Review Comment Format:**
```
[SEVERITY] Category: Anti-Pattern Name

This code exhibits the [Anti-Pattern Name] anti-pattern. [Explain issue and consequences]

Specifically: [Point out the problematic code]

Refactor to: [Show corrected code]

This change will: [List benefits]
```

**For PSR-12 Violations in PHP:**
```
[HIGH] Code Style: PSR-12 Non-Compliance - [Specific Violation]

This code violates PSR-12 [specific rule]. [Explain the PSR-12 requirement]

Specifically: [Show the violating code]

Fix: [Show PSR-12 compliant code]

PSR-12 compliance is mandatory for all PHP code. Use `phpcs --standard=PSR12` 
to check for violations or `phpcbf --standard=PSR12` to auto-fix.
```

**Remember:** Finding and fixing anti-patterns is a PRIMARY goal of code review. These patterns lead to bugs, security issues, performance problems, and unmaintainable code. Be vigilant!

**For PHP code, PSR-12 compliance is NON-NEGOTIABLE and must be enforced strictly.**

---

## Common Pitfalls to Avoid as a Reviewer

### 1. **Nitpicking Style Over Substance**
- ❌ "This line should have a space after the comma"
- ✅ "This function has a critical race condition in the checkout process"

Use linters for style. Focus your human/AI review on logic, security, and design.

### 2. **Being Vague**
- ❌ "This code is bad"
- ✅ "This function makes 50 database queries in a loop, causing O(n²) performance"

### 3. **Not Explaining Why**
- ❌ "Don't use `eval()`"
- ✅ "Don't use `eval()` because it executes arbitrary code and can be exploited by attackers to run malicious commands"

### 4. **Suggesting Your Preference as a Rule**
- ❌ "I prefer to use map() instead of list comprehensions"
- ✅ "Consider using list comprehensions here as they're more readable and Pythonic, though map() works too"

### 5. **Missing the Forest for the Trees**
Don't just review syntax - review:
- Does this solve the right problem?
- Is this the right architectural approach?
- Will this scale?
- Is this maintainable?

---

## Language-Specific Considerations

### Python
- Check for proper use of context managers (`with` statements)
- Verify list comprehensions aren't overly complex
- Check for mutable default arguments
- Verify proper exception hierarchy
- Check for proper use of `__init__`, `__str__`, `__repr__`

### JavaScript/TypeScript
- Check for proper use of `const`/`let` (avoid `var`)
- Verify async/await patterns (no unhandled promise rejections)
- Check for proper event listener cleanup
- Verify TypeScript types are meaningful (not just `any`)
- Check for XSS vulnerabilities in DOM manipulation

### Java
- Check for proper resource management (try-with-resources)
- Verify proper use of generics
- Check for thread safety issues
- Verify proper equals/hashCode implementations
- Check for proper exception handling

### Go
- Check for proper error handling (not ignoring errors)
- Verify goroutine lifecycle management
- Check for proper use of defer
- Verify context usage for cancellation
- Check for race conditions

---

## Decision Framework

When uncertain about whether to flag something, ask:

1. **Safety**: Could this cause data loss, security breach, or system failure?
   - If YES → Flag as CRITICAL/HIGH

2. **Correctness**: Does this have a bug or produce wrong results?
   - If YES → Flag as HIGH

3. **Performance**: Will this cause noticeable slowdown or not scale?
   - If YES → Flag as HIGH/MEDIUM

4. **Maintainability**: Will this make the codebase harder to maintain?
   - If YES → Flag as MEDIUM

5. **Style/Convention**: Is this just a style preference?
   - If YES → Consider if it's worth mentioning (probably LOW/INFO)

6. **Uncertainty**: Am I unsure if this is an issue?
   - If YES → Ask a question rather than stating it's wrong

---

## Final Checklist Before Submitting Review

- [ ] Have I reviewed all changes thoroughly?
- [ ] Are my comments constructive and specific?
- [ ] Have I explained the "why" behind each comment?
- [ ] Have I provided actionable suggestions?
- [ ] Have I acknowledged good code?
- [ ] Are my severity levels appropriate?
- [ ] Have I considered the context and constraints?
- [ ] Am I being respectful and collaborative?
- [ ] Have I checked for security issues?
- [ ] Have I verified correctness and performance?

---

## Continuous Improvement

As a reviewing agent, you should:
- Learn from patterns in code that cause production issues
- Update your checklist based on new vulnerabilities
- Adapt to project-specific patterns and conventions
- Balance thoroughness with review speed
- Calibrate severity levels based on actual impact

Remember: The goal is not to find every possible issue, but to catch issues that matter and help the team ship better code.
