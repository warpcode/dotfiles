# INPUT VALIDATION

## OVERVIEW
Input validation prevents malicious or malformed data from entering your system, mitigating injection attacks and data corruption.

## VALIDATION PRINCIPLES

### 1. Allowlist over Blacklist

**BAD: Blacklist (easily bypassed)**
```php
$blacklist = ['admin', 'root', 'test'];

if (in_array($username, $blacklist)) {
    die('Username not allowed');
}

// Attacker uses: 'adminn', 'rooot', 'tEst' - all bypass!
```

**GOOD: Allowlist (strict)**
```php
$allowedChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';

if (!preg_match('/^[' . $allowedChars . ']{3,20}$/', $username)) {
    die('Invalid username. Use only letters, numbers, -_ and be 3-20 characters.');
}
```

---

### 2. Type Validation

**PHP Examples**:
```php
// Validate integer
$id = (int) $_GET['id'];  // Cast to int
if ($id < 1) {
    die('Invalid ID');
}

// Validate email
$email = filter_var($_POST['email'], FILTER_VALIDATE_EMAIL);
if ($email === false) {
    die('Invalid email address');
}

// Validate URL
$url = filter_var($_POST['website'], FILTER_VALIDATE_URL);
if ($url === false) {
    die('Invalid URL');
}

// Validate with whitelist (allowed domains)
$email = filter_var($_POST['email'], FILTER_VALIDATE_EMAIL);
$allowedDomains = ['example.com', 'myapp.com'];
$emailDomain = substr(strrchr($email, '@'), 1);

if (!in_array($emailDomain, $allowedDomains)) {
    die('Email domain not allowed');
}
```

**JavaScript Examples**:
```javascript
// Validate email with regex
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if (!emailRegex.test(email)) {
    return { valid: false, error: 'Invalid email' };
}

// Validate URL
try {
    new URL(input);
} catch (e) {
    return { valid: false, error: 'Invalid URL' };
}

// Validate number
if (typeof value !== 'number' || isNaN(value)) {
    return { valid: false, error: 'Must be a number' };
}
```

---

## SQL INJECTION PREVENTION

### 1. Parameterized Queries (Preferred)

**PHP (PDO)**:
```php
// VULNERABLE: Direct interpolation
$email = $_GET['email'];
$query = "SELECT * FROM users WHERE email = '$email'";
// Attacker: email=' OR '1'='1

// SECURE: Parameterized query
$email = $_GET['email'];
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([$email]);
$user = $stmt->fetch();
```

**PHP (MySQLi)**:
```php
// SECURE: Prepared statement
$stmt = $mysqli->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param('s', $email);
$stmt->execute();
$result = $stmt->get_result();
```

**Python (SQLAlchemy)**:
```python
# VULNERABLE: String formatting
query = f"SELECT * FROM users WHERE email = '{email}'"

# SECURE: Parameterized query
query = text("SELECT * FROM users WHERE email = :email")
result = db.execute(query, {"email": email})
```

### 2. ORM Usage (Automatic Parameterization)

**Laravel (Eloquent)**:
```php
// SECURE: ORM automatically parameterizes
$user = User::where('email', $email)->first();
$users = User::where('status', 'active')->where('created_at', '>', $date)->get();
```

**Django**:
```python
# SECURE: ORM automatically parameterizes
user = User.objects.filter(email=email).first()
users = User.objects.filter(status='active').filter(created_at__gt=date)
```

---

## XSS (CROSS-SITE SCRIPTING) PREVENTION

### 1. Output Encoding

**PHP (htmlspecialchars)**:
```php
// VULNERABLE: No encoding
echo "<div>" . $userInput . "</div>";
// If $userInput = <script>alert(1)</script>, XSS executes

// SECURE: HTML encode output
echo "<div>" . htmlspecialchars($userInput, ENT_QUOTES, 'UTF-8') . "</div>";
// Outputs: &lt;script&gt;alert(1)&lt;/script&gt;
```

**PHP (filter_input)**:
```php
// SECURE: Sanitize input and encode output
$email = filter_input(INPUT_GET, 'email', FILTER_SANITIZE_EMAIL);
$comment = filter_input(INPUT_POST, 'comment', FILTER_SANITIZE_SPECIAL_CHARS);

echo "<div>" . htmlspecialchars($comment, ENT_QUOTES, 'UTF-8') . "</div>";
```

**JavaScript (DOMPurify)**:
```javascript
// Import DOMPurify library
import DOMPurify from 'dompurify';

// SECURE: Sanitize HTML before rendering
const clean = DOMPurify.sanitize(userInput);
element.innerHTML = clean;
```

**React (Automatic XSS protection)**:
```jsx
// SECURE: React automatically escapes
function Comment({ content }) {
    return <div>{content}</div>;  // Safe by default
}

// For HTML content (dangerous!)
function Comment({ content }) {
    return <div dangerouslySetInnerHTML={{ __html: content }}></div>;
    // Only use with trusted/sanitized content
}
```

---

## CSRF (CROSS-SITE REQUEST FORGERY) PREVENTION

### 1. CSRF Token Implementation

**PHP Session-Based**:
```php
// Generate CSRF token on page load
session_start();
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
?>

<!-- Form with CSRF token -->
<form method="POST" action="/submit">
    <input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token'], ENT_QUOTES, 'UTF-8') ?>">
    <input type="text" name="data">
    <button type="submit">Submit</button>
</form>
```

**PHP CSRF Verification**:
```php
session_start();

function verifyCsrfToken(): bool
{
    if (!isset($_POST['csrf_token']) || !isset($_SESSION['csrf_token'])) {
        return false;
    }

    // Use hash_equals() to prevent timing attacks
    return hash_equals($_SESSION['csrf_token'], $_POST['csrf_token']);
}

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verifyCsrfToken()) {
        die('CSRF token validation failed');
    }

    // Regenerate token (one-time use)
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

    // Process form...
}
```

**Laravel CSRF Middleware**:
```php
// Automatically added to forms via @csrf directive
<form method="POST" action="/submit">
    @csrf
    <input type="text" name="data">
    <button type="submit">Submit</button>
</form>
```

**Django CSRF Middleware**:
```python
# Automatically added to forms via {% csrf_token %}

<form method="POST" action="/submit">
    {% csrf_token %}
    <input type="text" name="data">
    <button type="submit">Submit</button>
</form>
```

### 2. SameSite Cookie Attribute

**PHP**:
```php
// Secure cookie configuration
session_set_cookie_params([
    'lifetime' => 86400,
    'path' => '/',
    'domain' => 'example.com',
    'secure' => true,  // HTTPS only
    'httponly' => true,  // Prevent JavaScript access
    'samesite' => 'Strict'  // CSRF protection
]);

session_start();
```

**Express**:
```javascript
app.use(session({
    name: 'sessionId',
    secret: process.env.SESSION_SECRET,
    cookie: {
        secure: true,  // HTTPS only
        httpOnly: true,  // Prevent JavaScript access
        sameSite: 'strict',  // CSRF protection
        maxAge: 24 * 60 * 60 * 1000
    }
}));
```

---

## COMMAND INJECTION PREVENTION

### 1. Avoid Shell Commands

**BAD: Using shell_exec(), exec(), system()**:
```php
// VULNERABLE: Command injection
$filename = $_GET['file'];
system("cat /var/www/uploads/$filename");

// Attacker: file=/etc/passwd; rm -rf /
// Executes: cat /var/www/uploads//etc/passwd; rm -rf /
```

**GOOD: Use PHP built-in functions**:
```php
// SECURE: Use PHP functions instead of shell
$filename = basename($_GET['file']);  // Remove path traversal
$allowedFiles = ['file1.txt', 'file2.txt'];

if (!in_array($filename, $allowedFiles)) {
    die('File not allowed');
}

$content = file_get_contents("/var/www/uploads/$filename");
```

### 2. escapeshellarg() (If Shell Required)

```php
// SECURE: Use escapeshellarg()
$filename = escapeshellarg($_GET['file']);
system("cat /var/www/uploads/$filename");

// escapeshellcmd() for entire command
$command = escapeshellcmd("cat $filename");
system($command);
```

### 3. Allowlist Validation

```php
// SECURE: Allowlist for filenames
$allowedFiles = [
    'document.pdf',
    'image.png',
    'data.csv'
];

$filename = $_GET['file'];

if (!in_array($filename, $allowedFiles)) {
    die('File not allowed');
}

$path = "/var/www/uploads/" . basename($filename);
readfile($path);
```

---

## PATH TRAVERSAL PREVENTION

### 1. Prevent Directory Traversal

**Vulnerability**:
```php
// VULNERABLE: Path traversal
$filename = $_GET['file'];
include("/var/www/uploads/$filename");

// Attacker: file=../../etc/passwd
// Includes: /etc/passwd
```

**Prevention**:
```php
// SECURE: basename() and realpath()
$filename = basename($_GET['file']);  // Removes ../
$fullPath = realpath("/var/www/uploads/$filename");

// Verify path is within allowed directory
$allowedDir = realpath('/var/www/uploads');

if (strpos($fullPath, $allowedDir) !== 0) {
    die('Access denied');
}

include($fullPath);
```

---

## FILE UPLOAD VALIDATION

### 1. File Type Validation

```php
// SECURE: Validate MIME type (not just extension)
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $_FILES['file']['tmp_name']);
$allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];

if (!in_array($mimeType, $allowedTypes)) {
    die('Invalid file type');
}

// Verify file signature (magic bytes)
$handle = fopen($_FILES['file']['tmp_name'], 'rb');
$bytes = fread($handle, 8);
fclose($handle);

if ($bytes !== "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A") {  // PNG magic bytes
    die('Invalid file');
}
```

### 2. File Size Validation

```php
// SECURE: Validate file size
$maxSize = 5 * 1024 * 1024;  // 5MB

if ($_FILES['file']['size'] > $maxSize) {
    die('File too large. Maximum 5MB allowed.');
}
```

### 3. File Renaming

```php
// SECURE: Generate safe filename
$extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
$safeFilename = uniqid() . '.' . $extension;

$destination = '/var/www/uploads/' . $safeFilename;
move_uploaded_file($_FILES['file']['tmp_name'], $destination);
```

---

## VALIDATION FRAMEWORKS

### PHP
```php
// Respect Validation
$validator = Validator::make($data, [
    'email' => 'required|email|max:255',
    'password' => 'required|min:12|regex:/^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{12,}$/',
    'age' => 'required|integer|min:18|max:120'
]);

if ($validator->fails()) {
    return response()->json(['errors' => $validator->errors()], 422);
}
```

**Laravel Validation**:
```php
$validator = Validator::make($request->all(), [
    'email' => 'required|email|unique:users',
    'password' => 'required|min:12|confirmed',
    'age' => 'required|integer|min:18'
]);

if ($validator->fails()) {
    return redirect()->back()->withErrors($validator);
}
```

**Django Forms**:
```python
from django import forms

class UserForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['email', 'password', 'age']

    email = forms.EmailField(required=True)
    password = forms.CharField(min_length=12, required=True)
    age = forms.IntegerField(min_value=18, required=True)
```

**JavaScript (Joi)**:
```javascript
const Joi = require('joi');

const schema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(12).pattern(/^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)/).required(),
    age: Joi.number().integer().min(18).max(120).required()
});

const { error, value } = schema.validate(data);
if (error) {
    return { valid: false, errors: error.details };
}
```

---

## VALIDATION CHECKLIST

### Before Deployment
- [ ] All user inputs validated (type, format, length)
- [ ] SQL queries use parameterized statements or ORM
- [ ] Output encoded (htmlspecialchars, DOMPurify)
- [ ] CSRF tokens implemented
- [ ] SameSite cookies enabled
- [ ] File uploads validated (type, size, content)
- [ ] Path traversal prevention (basename, realpath)
- [ ] Command injection prevention (escapeshellarg, allowlists)
- [ ] Allowlist over blacklist for validation
- [ ] Server-side validation (never trust client-side)

---

## CROSS-REFERENCES
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For code injection: @software-engineering/security/CODE-INJECTION.md
- For authentication: @security/AUTHENTICATION.md
