# AUTHENTICATION

## OVERVIEW
Authentication verifies the identity of users and systems. This guide covers secure authentication implementation patterns.

## PASSWORD AUTHENTICATION

### 1. Password Hashing

**Principle**: Never store plaintext passwords. Use strong, slow hashing algorithms.

**Vulnerability**:
```php
// BAD: Plaintext or weak hashing
$password = $_POST['password'];

// VULNERABLE: Plaintext storage
DB::insert('users', ['password' => $password]);

// VULNERABLE: MD5 (fast, weak)
$hashed = md5($password);

// VULNERABLE: SHA1 (broken)
$hashed = sha1($password);
```

**Secure Implementation**:
```php
// GOOD: Argon2 or bcrypt (recommended)
$hashed = password_hash($password, PASSWORD_ARGON2ID);
DB::insert('users', ['password' => $hashed]);

// Verify password
if (password_verify($input, $hashed)) {
    // Valid password
}

// Verify with Argon2 specifically
$hash_options = [
    'memory_cost' => PASSWORD_ARGON2_DEFAULT_MEMORY_COST,
    'time_cost' => PASSWORD_ARGON2_DEFAULT_TIME_COST,
    'threads' => PASSWORD_ARGON2_DEFAULT_THREADS,
];
$hashed = password_hash($password, PASSWORD_ARGON2, $hash_options);
```

**Best Practices**:
- Use Argon2 (PASSWORD_ARGON2ID) or bcrypt (PASSWORD_BCRYPT)
- Use PHP 8.0+ for Argon2 support
- Minimum hash cost: 10 for bcrypt, default for Argon2
- Never use MD5, SHA1, SHA256 (too fast for password hashing)

---

### 2. Password Policies

**Strong Password Requirements**:
- Minimum 12 characters
- Mix of uppercase and lowercase
- At least one number
- At least one special character
- No common passwords (123456, password, qwerty)

**Implementation**:
```php
// Secure password policy validation
public function validatePassword(string $password): array
{
    $errors = [];

    if (strlen($password) < 12) {
        $errors[] = 'Password must be at least 12 characters';
    }

    if (!preg_match('/[A-Z]/', $password)) {
        $errors[] = 'Password must contain uppercase letter';
    }

    if (!preg_match('/[a-z]/', $password)) {
        $errors[] = 'Password must contain lowercase letter';
    }

    if (!preg_match('/[0-9]/', $password)) {
        $errors[] = 'Password must contain number';
    }

    if (!preg_match('/[^A-Za-z0-9]/', $password)) {
        $errors[] = 'Password must contain special character';
    }

    return $errors;
}
```

**Example** (JavaScript):
```javascript
// Password strength meter (zxcvbn)
import zxcvbn from 'zxcvbn';

function validatePassword(password) {
    const result = zxcvbn(password);

    if (result.score < 3) {  // 0-4 scale, 3+ is strong
        return {
            valid: false,
            score: result.score,
            warning: result.feedback.warning
        };
    }

    return { valid: true, score: result.score };
}
```

---

### 3. Account Lockout

**Purpose**: Prevent brute force attacks by limiting failed login attempts.

**Implementation**:
```php
// Rate limiting with Redis
public function attemptLogin(string $email, string $ip): void
{
    $key = "login_attempts:$ip";

    $attempts = Redis::get($key) ?? 0;

    if ($attempts >= 5) {
        $ttl = Redis::ttl($key);
        throw new TooManyAttemptsException(
            "Too many attempts. Try again in $ttl seconds."
        );
    }

    // Increment attempt counter
    Redis::incr($key);

    // Lock for 15 minutes on 5th attempt
    if ($attempts >= 4) {
        Redis::expire($key, 900);  // 15 minutes
    }

    // Successful login - clear attempts
    if ($this->authenticate($email, $_POST['password'])) {
        Redis::del($key);
    }
}
```

**Best Practices**:
- Lock after 5 failed attempts
- Lock duration: 15 minutes
- Clear attempts on successful login
- Per-IP and per-account tracking

---

## JWT (JSON WEB TOKEN) AUTHENTICATION

### 1. JWT Structure

```javascript
// JWT = Header.Payload.Signature
const jwt = 'header.payload.signature';

// Example
const header = {
    "alg": "RS256",
    "typ": "JWT"
};

const payload = {
    "sub": "1234567890",
    "name": "John Doe",
    "iat": 1516239022,
    "exp": 1516242622
};
```

### 2. Access Token vs Refresh Token

**Access Token**: Short-lived (5-15 minutes), contains user info
**Refresh Token**: Long-lived (7-30 days), used to get new access token

**Implementation**:
```php
// Generate access token (15 minutes)
$accessPayload = [
    'sub' => $user->id,
    'email' => $user->email,
    'iat' => time(),
    'exp' => time() + 900  // 15 minutes
];
$accessToken = JWT::encode($accessPayload, $privateKey, 'RS256');

// Generate refresh token (30 days)
$refreshPayload = [
    'sub' => $user->id,
    'type' => 'refresh',
    'iat' => time(),
    'exp' => time() + (30 * 24 * 60 * 60)  // 30 days
];
$refreshToken = JWT::encode($refreshPayload, $privateKey, 'RS256');

// Store refresh token in database (hashed)
DB::insert('refresh_tokens', [
    'user_id' => $user->id,
    'token_hash' => hash('sha256', $refreshToken),
    'expires_at' => date('Y-m-d H:i:s', time() + (30 * 86400))
]);
```

**Refresh Flow**:
```php
public function refreshToken(string $refreshToken): string
{
    // Validate refresh token
    try {
        $payload = JWT::decode($refreshToken, $publicKey, ['RS256']);
    } catch (Exception $e) {
        throw new AuthenticationException('Invalid refresh token');
    }

    // Verify it's a refresh token
    if (!isset($payload['type']) || $payload['type'] !== 'refresh') {
        throw new AuthenticationException('Invalid token type');
    }

    // Verify token exists in database
    $tokenHash = hash('sha256', $refreshToken);
    $storedToken = DB::table('refresh_tokens')
        ->where('token_hash', $tokenHash)
        ->where('expires_at', '>', now())
        ->first();

    if (!$storedToken) {
        throw new AuthenticationException('Refresh token expired or invalid');
    }

    // Get user
    $user = User::find($payload['sub']);

    // Generate new access token
    $accessPayload = [
        'sub' => $user->id,
        'email' => $user->email,
        'iat' => time(),
        'exp' => time() + 900
    ];
    return JWT::encode($accessPayload, $privateKey, 'RS256');
}
```

### 3. JWT Best Practices

**DO**:
- Use RS256 (asymmetric) or ES256 (ECDSA) for production
- Use HS256 (symmetric) only for internal services
- Short access token lifetime (5-15 minutes)
- Store refresh tokens securely (hashed, httpOnly cookies)
- Verify algorithm claim (`alg`) in header
- Verify issuer claim (`iss`) and audience claim (`aud`)

**DON'T**:
- Never store secrets in JWT
- Never use JWT for sessions (use server-side sessions)
- Never store JWT in URL (use Authorization header)
- Never use "none" algorithm
- Never trust JWT without signature verification

---

## OAUTH2 AUTHENTICATION

### 1. OAuth2 Authorization Code Flow

**Flow Diagram**:
```
User → Client → Authorization Server → User (consent)
User → Authorization Server (auth code)
Authorization Server → Client (auth code)
Client → Authorization Server (access token)
Authorization Server → Client (JWT access token)
```

**Implementation**:
```php
// Step 1: Redirect to authorization server
public function redirectToProvider(string $provider): RedirectResponse
{
    $authUrl = "https://{$provider}.com/oauth/authorize";
    $params = http_build_query([
        'response_type' => 'code',
        'client_id' => config("oauth.{$provider}.client_id"),
        'redirect_uri' => route('oauth.callback', ['provider' => $provider]),
        'scope' => 'email profile',
        'state' => Str::random(40)  // CSRF protection
    ]);

    return redirect("$authUrl?$params");
}

// Step 2: Handle callback
public function handleCallback(Request $request, string $provider): JsonResponse
{
    // Verify state (CSRF protection)
    if ($request->state !== session()->get('oauth_state')) {
        throw new InvalidStateException('Invalid state parameter');
    }

    // Exchange authorization code for access token
    $response = Http::post("https://{$provider}.com/oauth/token", [
        'grant_type' => 'authorization_code',
        'code' => $request->code,
        'client_id' => config("oauth.{$provider}.client_id"),
        'client_secret' => config("oauth.{$provider}.client_secret"),
        'redirect_uri' => route('oauth.callback', ['provider' => $provider])
    ]);

    $data = json_decode($response->body(), true);

    // Get user info from provider
    $userResponse = Http::withToken($data['access_token'])
        ->get("https://{$provider}.com/api/user");

    $userData = json_decode($userResponse->body(), true);

    // Create or update user
    $user = User::updateOrCreate(
        ['provider_id' => $userData['id'], 'provider' => $provider],
        ['email' => $userData['email'], 'name' => $userData['name']]
    );

    // Generate JWT for your application
    $token = JWT::encode(['sub' => $user->id], $privateKey, 'RS256');

    return response()->json(['token' => $token]);
}
```

---

### 2. OAuth2 Client Credentials Flow (Service-to-Service)

**Purpose**: Authenticate between services (no user involved).

```php
// Service A authenticates to Service B
public function authenticateToServiceB(): string
{
    $response = Http::asForm()->post('https://service-b.com/oauth/token', [
        'grant_type' => 'client_credentials',
        'client_id' => config('services.service_b.client_id'),
        'client_secret' => config('services.service_b.client_secret'),
        'scope' => 'read write'
    ]);

    $data = json_decode($response->body(), true);

    return $data['access_token'];
}
```

---

## SESSION MANAGEMENT

### 1. Secure Session Configuration

**PHP Configuration**:
```php
// session.php
ini_set('session.cookie_httponly', '1');  // Prevent JavaScript access
ini_set('session.cookie_secure', '1');  // HTTPS only
ini_set('session.cookie_samesite', 'Strict');  // CSRF protection
ini_set('session.use_strict_mode', '1');  // Prevent session fixation
ini_set('session.gc_maxlifetime', '1440');  // 24 minutes

session_start();
```

**Express Configuration**:
```javascript
const session = require('express-session');

app.use(session({
    secret: process.env.SESSION_SECRET,  // Strong secret
    name: 'sessionId',
    cookie: {
        httpOnly: true,  // Prevent JavaScript access
        secure: true,  // HTTPS only
        sameSite: 'strict',  // CSRF protection
        maxAge: 24 * 60 * 60 * 1000  // 24 hours
    },
    resave: false,  // Don't save unmodified sessions
    saveUninitialized: false,  // Don't create sessions until needed
}));
```

### 2. Session Fixation Prevention

**Vulnerability**:
```php
// VULNERABLE: Session ID not regenerated on login
session_id($_GET['PHPSESSID']);  // Attacker provides session ID

if (authenticate($_POST['username'], $_POST['password'])) {
    $_SESSION['user'] = $user;
    // Still using attacker's session ID!
}
```

**Prevention**:
```php
// SECURE: Regenerate session ID on login
session_start();

if (authenticate($_POST['username'], $_POST['password'])) {
    // Regenerate session ID (prevents session fixation)
    session_regenerate_id(true);

    $_SESSION['user'] = $user;
    $_SESSION['ip'] = $_SERVER['REMOTE_ADDR'];
    $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
}
```

---

## MULTIFACTOR AUTHENTICATION (MFA)

### 1. TOTP (Time-based One-Time Password)

**Implementation** (using speakeasy PHP library):
```php
// Generate TOTP secret during registration
$secret = generateRandomSecret(32);
User::update($userId, ['totp_secret' => encrypt($secret)]);

// Generate QR code for user to scan
$qrCode = "otpauth://totp/AppName?secret=$secret&issuer=AppName";

// Verify TOTP during login
use Speakeasy\Speakeasy;

$otp = $_POST['otp'];
$secret = decrypt($user->totp_secret);

$speakeasy = new Speakeasy();
$result = $speakeasy->verifyOtp($secret, $otp);

if (!$result['verified']) {
    throw new AuthenticationException('Invalid OTP');
}

// MFA verified, create session
```

---

## AUTHENTICATION CHECKLIST

### Before Deployment
- [ ] Passwords hashed with Argon2 or bcrypt
- [ ] Strong password policy implemented (12+ chars)
- [ ] Account lockout after 5 failed attempts
- [ ] JWT uses RS256 or ES256
- [ ] JWT access token lifetime < 15 minutes
- [ ] Refresh tokens stored securely (hashed, httpOnly)
- [ ] Session cookies: httpOnly, Secure, SameSite
- [ ] Session ID regenerated on login
- [ ] MFA implemented for sensitive accounts
- [ ] Rate limiting on login endpoints
- [ ] No hardcoded secrets
- [ ] OAuth2 state parameter verified

---

## CROSS-REFERENCES
- For input validation: @security/INPUT-VALIDATION.md
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For secrets management: @secrets/SECRETS-MANAGEMENT.md
