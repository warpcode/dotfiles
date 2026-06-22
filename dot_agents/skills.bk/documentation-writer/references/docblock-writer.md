## CORE_RULES
- Expertise: Code Librarian + Technical Writer
- Scope: Find/document undocumented public classes + methods
- Languages: PHP (PHPDoc), JavaScript/TypeScript (JSDoc), Python (docstrings), Java (Javadoc)
- Target: Public ONLY (skip private/protected)
- Security: Validate file paths, sanitize inputs before edit

## CONTEXT: PROCESS
1. Acknowledge Goal: Scan for undocumented classes/methods in supported languages
2. Locate Target Files:
    - `glob`: Find files with extensions `.php`, `.js`, `.ts`, `.py`, `.java`
    - Directories: `app/`, `src/`, `lib/`, etc.
3. Process Each File:
    - `read` file contents
    - Identify language + documentation format (by extension)
    - Find public declarations:
      - PHP: `class ...`, `public function ...`
      - Python: `def ...`
      - JS/TS: `class ...`, `function ...`, `=>` methods
      - Java: `public class ...`, `public ...`
    - Check preceding lines: Documentation ABSENT?
4. Generate Documentation:
    - Description: Human-readable from name (e.g., `storeNewProduct` -> "Store a new product.")
    - Parameters: Document each with type + name
    - Return: Document type + description
    - Format by language:
      - PHPDoc: `/** @param ... @return ... */`
      - JSDoc: `/** @param ... @returns ... */`
      - Python: `"""Description.\n\nArgs:\n    param: description\n\nReturns:\n    description"""`
      - Javadoc: `/** @param ... @return ... */`
5. Apply Changes:
    - Insert documentation on line above declaration
    - Use `edit` tool to update file
6. Generate Report: List all updated files with counts

## EXAMPLES
### PHP (PHPDoc)
```php
// Before:
public function store(StoreFavoriteRequest $request): JsonResponse
{
    // ... function body
}

// After:
/**
 * Store a new favorite for the authenticated user.
 *
 * @param \App\Http\Requests\StoreFavoriteRequest $request
 * @return \Illuminate\Http\JsonResponse
 */
public function store(StoreFavoriteRequest $request): JsonResponse
{
    // ... function body
}
```

### JavaScript (JSDoc)
```javascript
// Before:
function calculateTotal(items) {
    // ... function body
}

// After:
/**
 * Calculate the total price of items.
 *
 * @param {Array} items - The list of items to calculate.
 * @returns {number} The total price.
 */
function calculateTotal(items) {
    // ... function body
}
```

### Python (Docstring)
```python
# Before:
def get_user_by_id(user_id):
    # ... function body

# After:
def get_user_by_id(user_id):
    """
    Retrieve a user by their ID.

    Args:
        user_id (int): The unique identifier of user.

    Returns:
        User: The user object if found, None otherwise.
    """
    # ... function body
```

## EXECUTION PROTOCOL
1. Announce: "Beginning scan for undocumented public classes/methods"
2. Execute: `glob` for target extensions in common directories
3. For each file:
   - Read contents
   - Identify public declarations without documentation
   - Generate appropriate documentation format
   - Apply via `edit` tool
4. After all files: Generate structured Markdown report
5. Report format:
   - List updated files with language
   - Total count
   - Example before/after for each language
6. Security: Validate paths, sanitize inputs, confirm destructive edits
</execution_protocol>
