# Review Mode: Security Operations

**Purpose**: Exhaustive review checklists for security operations, vulnerability assessment, and compliance

## EXHAUSTIVE LOADING STRATEGY

### Comprehensive Review Checklists
Load all security patterns for exhaustive security review:
- **OWASP Top 10**: `@owasp/OWASP-TOP10.md`
- **Authentication**: `@security/AUTHENTICATION.md`
- **Input Validation**: `@security/INPUT-VALIDATION.md`
- **File Upload**: `@security/FILE-UPLOAD.md`
- **Security Headers**: `@security/SECURITY-HEADERS.md`
- **File Upload Additional**: `@security/FILE-UPLOAD-ADDITIONAL.md`
- **Security Headers Advanced**: `@security/SECURITY-HEADERS-ADVANCED.md`
- **Parameter Validation**: `@validation/PARAMETER-VALIDATION.md`
- **Vulnerability Scanning**: `@vulnerability/VULNERABILITY-SCANNING.md`
- **Compliance**: `@compliance/SOC2-GDPR.md`
- **Secrets Management**: `@secrets/SECRETS-MANAGEMENT.md`

## OWASP TOP 10 REVIEW

### A01:2021 Broken Access Control
- [ ] **IDOR (Insecure Direct Object Reference)**: User can access other users' data (CRITICAL)
- [ ] **Missing Authentication**: Endpoints accessible without authentication (CRITICAL)
- [ ] **Missing Authorization**: No authorization checks on protected resources (CRITICAL)
- [ ] **Privilege Escalation**: User can escalate privileges (CRITICAL)
- [ ] **Bypassing Authorization**: Authorization can be bypassed (CRITICAL)
- [ ] **CORS Misconfiguration**: CORS allows unauthorized access (HIGH)
- [ ] **Metadata Manipulation**: User can manipulate metadata to gain access (HIGH)

### A02:2021 Cryptographic Failures
- [ ] **Weak Hashing**: Using MD5, SHA1, or weak algorithms (CRITICAL)
- [ ] **Hardcoded Keys**: Encryption keys hardcoded in source (CRITICAL)
- [ ] **No Encryption**: Sensitive data not encrypted at rest/transit (CRITICAL)
- [ ] **Weak Randomness**: Using predictable random values (CRITICAL)
- [ ] **Insecure Algorithms**: Using deprecated/weak cryptographic algorithms (HIGH)
- [ ] **Key Management Issues**: Poor key rotation, storage, or generation (CRITICAL)
- [ ] **No Integrity Checks**: Not verifying data integrity (MEDIUM)
- [ ] **Default Keys**: Using default encryption keys (CRITICAL)

### A03:2021 Injection
- [ ] **SQL Injection**: SQL injection vulnerabilities (CRITICAL)
- [ ] **NoSQL Injection**: NoSQL injection vulnerabilities (CRITICAL)
- [ ] **Command Injection**: Command injection in system calls (CRITICAL)
- [ ] **Code Injection**: Code injection via eval(), include(), etc. (CRITICAL)
- [ ] **LDAP Injection**: LDAP injection in directory queries (HIGH)
- [ ] **XPath Injection**: XPath injection in XML queries (HIGH)
- [ ] **HTML Injection**: HTML injection (XSS) vulnerabilities (HIGH)
- [ ] **OS Command Injection**: OS command injection in shell commands (CRITICAL)

### A04:2021 Insecure Design
- [ ] **Missing Threat Modeling**: No threat modeling performed (MEDIUM)
- [ ] **Insecure Defaults**: Insecure default configurations (HIGH)
- [ ] **Missing Security Requirements**: No security requirements in design (MEDIUM)
- [ ] **Business Logic Flaws**: Business logic can be abused (HIGH)
- [ ] **Security by Obscurity**: Relying on secrecy instead of proper security (MEDIUM)
- [ ] **No Defense in Depth**: Single layer of security (HIGH)

### A05:2021 Security Misconfiguration
- [ ] **Default Accounts**: Default credentials enabled (CRITICAL)
- [ ] **Debug Enabled**: Debug mode enabled in production (HIGH)
- [ ] **Error Messages**: Stack traces or detailed error messages exposed (MEDIUM)
- [ ] **Unnecessary Services**: Unnecessary services/ports exposed (MEDIUM)
- [ ] **Outdated Software**: Using outdated/vulnerable software versions (HIGH)
- [ ] **Missing Security Headers**: Critical security headers missing (MEDIUM)
- [ ] **Open Cloud Storage**: S3 buckets, cloud storage publicly accessible (CRITICAL)
- [ ] **Directory Listing**: Directory listing enabled (MEDIUM)
- [ ] **Verbose Error Messages**: Error messages leak sensitive info (MEDIUM)

### A06:2021 Vulnerable and Outdated Components
- [ ] **Outdated Dependencies**: Using dependencies with known vulnerabilities (CRITICAL)
- [ ] **No Dependency Scanning**: Not scanning dependencies for vulnerabilities (HIGH)
- [ ] **Unpinned Versions**: Using `*` or unpinned versions (HIGH)
- [ ] **Abandoned Libraries**: Using abandoned/maintained libraries (MEDIUM)
- [ ] **No Updates**: Not regularly updating dependencies (HIGH)
- [ ] **Vulnerable Components**: Components with CVEs (CRITICAL)

### A07:2021 Identification and Authentication Failures
- [ ] **Weak Password Policy**: No or weak password policy (HIGH)
- [ ] **No Rate Limiting**: No rate limiting on authentication (MEDIUM)
- [ ] **Session Fixation**: Session fixation vulnerabilities (HIGH)
- [ ] **Session Hijacking**: Session tokens not properly protected (HIGH)
- [ ] **Credential Stuffing**: No protection against credential stuffing (MEDIUM)
- [ ] **No Multi-Factor Auth**: Missing MFA on sensitive operations (HIGH)
- [ ] **Credential Disclosure**: Credentials in error messages/logs (CRITICAL)
- [ ] **Password Reset Flaws**: Weak password reset mechanisms (HIGH)
- [ ] **Session Management**: Improper session expiration/timeout (MEDIUM)

### A08:2021 Software and Data Integrity Failures
- [ ] **Insecure Updates**: Updates not verified or signed (HIGH)
- [ ] **CI/CD Pipeline Security**: Insecure CI/CD pipeline (HIGH)
- [ ] **Supply Chain Attacks**: No supply chain integrity checks (CRITICAL)
- [ ] **Deserialization of Untrusted Data**: Unsafe deserialization (CRITICAL)
- [ ] **No Code Signing**: Code not signed (MEDIUM)
- [ ] **Dependency Confusion**: Vulnerable to dependency confusion attacks (HIGH)

### A09:2021 Security Logging and Monitoring Failures
- [ ] **No Logging**: Security events not logged (HIGH)
- [ ] **Log Tampering**: Logs can be tampered with (MEDIUM)
- [ ] **No Monitoring**: No security monitoring/alerting (HIGH)
- [ ] **Missing Audit Trails**: No audit trail for critical operations (HIGH)
- [ ] **Insufficient Logs**: Logs insufficient for forensic analysis (MEDIUM)
- [ ] **No Intrusion Detection**: No IDS/IPS (MEDIUM)
- [ ] **Log Injection**: Logs vulnerable to log injection (MEDIUM)

### A10:2021 Server-Side Request Forgery (SSRF)
- [ ] **SSRF Vulnerabilities**: Server-side request forgery vulnerabilities (CRITICAL)
- [ ] **Unrestricted URLs**: User can request arbitrary URLs (HIGH)
- [ ] **Internal Network Access**: Access to internal network via SSRF (CRITICAL)
- [ ] **Cloud Metadata Access**: Access to cloud metadata via SSRF (CRITICAL)
- [ ] **URL Validation**: Missing or insufficient URL validation (HIGH)
- [ ] **Network Access**: SSRF allows access to internal services (CRITICAL)

## AUTHENTICATION REVIEW

### Password Authentication
- [ ] **Weak Hashing**: Using MD5, SHA1, or weak password hashing (CRITICAL)
- [ ] **No Salt**: Not using salt in password hashing (HIGH)
- [ ] **Password in Transit**: Passwords sent in plaintext (CRITICAL)
- [ ] **Password in Logs**: Passwords logged (CRITICAL)
- [ ] **Weak Password Policy**: No or weak password requirements (HIGH)
- [ ] **Password Reuse**: No check for common/compromised passwords (MEDIUM)
- [ ] **Password Expiration**: No or inappropriate password expiration (MEDIUM)
- [ ] **Password Reset Flaws**: Weak password reset implementation (HIGH)

### Session Management
- [ ] **Session Fixation**: Session fixation vulnerabilities (HIGH)
- [ ] **Session Hijacking**: Session tokens predictable or exposed (HIGH)
- [ ] **No Session Timeout**: No session expiration (MEDIUM)
- [ ] **Session in URL**: Session IDs in URL (CRITICAL)
- [ ] **HttpOnly Cookie Missing**: Session cookies not HttpOnly (HIGH)
- [ ] **Secure Cookie Missing**: Session cookies not Secure (no HTTPS) (HIGH)
- [ ] **SameSite Missing**: Session cookies not SameSite (MEDIUM)
- [ ] **Session Regeneration**: No session regeneration on login (HIGH)
- [ ] **Concurrent Sessions**: No limit on concurrent sessions (MEDIUM)

### Multi-Factor Authentication
- [ ] **Missing MFA**: No MFA on sensitive operations (HIGH)
- [ ] **Weak MFA**: Using weak second factor (SMS) (MEDIUM)
- [ ] **MFA Bypass**: MFA can be bypassed (HIGH)
- [ ] **No Recovery**: No MFA recovery mechanism (MEDIUM)
- [ ] **MFA Brute Force**: No rate limiting on MFA (MEDIUM)

### OAuth2/OIDC
- [ ] **Implicit Flow**: Using deprecated implicit flow (MEDIUM)
- [ ] **PKCE Missing**: Not using PKCE for public clients (HIGH)
- [ ] **State Parameter**: Not using state parameter (CSRF) (HIGH)
- [ ] **Redirect URI**: Weak or missing redirect URI validation (HIGH)
- [ ] **Token Leaks**: Tokens exposed in URL/Referer (HIGH)
- [ ] **Weak Scopes**: Overly permissive scopes (MEDIUM)
- [ ] **Token Storage**: Insecure token storage (HIGH)
- [ ] **No Token Expiration**: No token expiration (MEDIUM)

### JWT
- [ ] **None Algorithm**: Using "none" algorithm (CRITICAL)
- [ ] **Weak Secret**: Weak JWT signing secret (CRITICAL)
- [ ] **No Expiration**: No token expiration (HIGH)
- [ ] **Algorithm Confusion**: Algorithm confusion vulnerabilities (HIGH)
- [ ] **Token Leaks**: Tokens exposed in URL/Storage (HIGH)
- [ ] **No Refresh Token Rotation**: No refresh token rotation (MEDIUM)
- [ ] **JWT in URL**: JWT in URL parameters (MEDIUM)

### SAML
- [ ] **Signature Validation**: Missing signature validation (CRITICAL)
- [ ] **Certificate Issues**: Expired or weak certificates (HIGH)
- [ ] **Replay Attacks**: No replay protection (HIGH)
- [ ] **XML External Entity**: XXE vulnerabilities (CRITICAL)
- [ ] **SAML Assertion Tampering**: Assertions can be tampered (CRITICAL)

## INPUT VALIDATION REVIEW

### SQL Injection Prevention
- [ ] **Raw SQL Queries**: Using raw SQL without parameterization (CRITICAL)
- [ ] **String Concatenation**: Concatenating user input into SQL (CRITICAL)
- [ ] **No Prepared Statements**: Not using prepared statements/parameterized queries (CRITICAL)
- [ ] **ORM Raw Queries**: Using ORM raw queries unsafely (HIGH)
- [ ] **No Whitelist**: Using blacklist instead of allowlist (HIGH)
- [ ] **Stored Procedures**: Using stored procedures unsafely (MEDIUM)

### XSS Prevention
- [ ] **Output Not Escaped**: User output not HTML-escaped (HIGH)
- [ ] **Unsafe DOM Methods**: Using unsafe DOM methods (innerHTML) (HIGH)
- [ ] **Template Engines**: User input in templates not auto-escaped (HIGH)
- [ ] **No Content Security Policy**: Missing CSP (MEDIUM)
- [ ] **Client-Side Validation Only**: Relying only on client-side validation (HIGH)
- [ ] **Stored XSS**: Stored XSS vulnerabilities (HIGH)
- [ ] **Reflected XSS**: Reflected XSS vulnerabilities (MEDIUM)
- [ ] **DOM-Based XSS**: DOM-based XSS vulnerabilities (HIGH)

### CSRF Prevention
- [ ] **No CSRF Token**: Missing CSRF tokens (CRITICAL)
- [ ] **Weak CSRF Token**: Predictable or weak CSRF tokens (HIGH)
- [ ] **Token Not Validated**: CSRF token not validated (CRITICAL)
- [ ] **GET State-Changing**: State-changing requests using GET (MEDIUM)
- [ ] **SameSite Cookie**: Missing SameSite attribute (MEDIUM)

### Command Injection Prevention
- [ ] **Shell Execution**: User input in shell commands (CRITICAL)
- [ ] **System Calls**: User input in system() or exec() (CRITICAL)
- [ ] **No Sanitization**: User input not sanitized before command execution (CRITICAL)
- [ ] **Argument Injection**: Command argument injection vulnerabilities (HIGH)

### File Path Traversal
- [ ] **Path Traversal**: Path traversal vulnerabilities (HIGH)
- [ ] **No Path Validation**: User input not validated for file paths (HIGH)
- [ ] **Absolute Paths**: Not preventing absolute paths (MEDIUM)
- [ ] **Directory Traversal**: Not preventing directory traversal sequences (HIGH)

### Type Validation
- [ ] **No Type Validation**: User input not type-validated (MEDIUM)
- [ ] **Integer Overflow**: Integer overflow vulnerabilities (MEDIUM)
- [ ] **Numeric Validation**: Numeric input not validated (MEDIUM)
- [ ] **Boolean Validation**: Boolean input not validated (MEDIUM)

### Length Validation
- [ ] **No Length Limits**: No length limits on input (MEDIUM)
- [ ] **Buffer Overflow**: Potential buffer overflows (HIGH)
- [ ] **String Overflow**: String overflow vulnerabilities (MEDIUM)

## FILE UPLOAD REVIEW

### File Type Validation
- [ ] **No File Type Check**: Not validating file types (HIGH)
- [ ] **Extension Check Only**: Only checking file extension (MEDIUM)
- [ ] **MIME Type Check Only**: Only checking MIME type (MEDIUM)
- [ ] **Magic Number Missing**: Not checking magic numbers (HIGH)
- [ ] **Double Extension**: Double extension vulnerability (MEDIUM)

### File Size Validation
- [ ] **No Size Limit**: No file size limit (HIGH)
- [ ] **Large File Upload**: Can upload very large files (MEDIUM)
- [ ] **Disk Space**: Can exhaust disk space (MEDIUM)

### File Content Validation
- [ ] **No Content Check**: Not checking file content (MEDIUM)
- [ ] **Malicious Content**: Can upload malicious files (HIGH)
- [ ] **Embedded Scripts**: Embedded scripts in uploaded files (MEDIUM)

### File Storage Security
- [ ] **Executable Uploads**: Can upload executable files (HIGH)
- [ ] **Web Accessible**: Uploads in web-accessible directory (HIGH)
- [ ] **No Random Filename**: Predictable file naming (MEDIUM)
- [ ] **No Permission Control**: Incorrect file permissions (MEDIUM)

### Virus Scanning
- [ ] **No Virus Scanning**: No virus scanning (MEDIUM)
- [ ] **Scanning Issues**: Virus scanning not effective (LOW)

### File Execution
- [ ] **Execution Possible**: Can execute uploaded files (CRITICAL)
- [ ] **Include Vulnerability**: Local file include via uploaded file (CRITICAL)
- [ ] **No Extension Handling**: Dangerous extensions allowed (HIGH)

## SECURITY HEADERS REVIEW

### HTTP Security Headers
- [ ] **Missing CSP**: Content-Security-Policy header missing (MEDIUM)
- [ ] **Weak CSP**: CSP policy too permissive (MEDIUM)
- [ ] **Missing HSTS**: Strict-Transport-Security header missing (HIGH)
- [ ] **Missing X-Frame-Options**: X-Frame-Options header missing (MEDIUM)
- [ ] **Missing X-Content-Type-Options**: X-Content-Type-Options header missing (MEDIUM)
- [ ] **Missing X-XSS-Protection**: X-XSS-Protection header missing (LOW)
- [ ] **Missing Referrer-Policy**: Referrer-Policy header missing (LOW)
- [ ] **Missing Permissions-Policy**: Permissions-Policy header missing (MEDIUM)

### CSP (Content-Security-Policy)
- [ ] **Missing CSP**: No CSP header (MEDIUM)
- [ ] **Unsafe Inline**: Using 'unsafe-inline' in CSP (MEDIUM)
- [ ] **Unsafe Eval**: Using 'unsafe-eval' in CSP (HIGH)
- [ ] **Wildcard Origin**: Using wildcard '*' in CSP (MEDIUM)
- [ ] **No Report-Only**: Not using report-only mode initially (LOW)

### HSTS (HTTP Strict Transport Security)
- [ ] **Missing HSTS**: No HSTS header (HIGH)
- [ ] **Short Max-Age**: HSTS max-age too short (MEDIUM)
- [ ] **No Preload**: Not using HSTS preload (LOW)
- [ ] **Include Subdomains**: Not including subdomains in HSTS (MEDIUM)

### X-Frame-Options
- [ ] **Missing**: No X-Frame-Options header (MEDIUM)
- [ ] **Allow From Origin**: Using deprecated ALLOW-FROM (LOW)
- [ ] **Incorrect Value**: Incorrect header value (MEDIUM)

## SECRETS MANAGEMENT REVIEW

### Secrets in Code
- [ ] **Hardcoded Secrets**: Secrets hardcoded in source (CRITICAL)
- [ ] **Secrets in Config**: Secrets in config files committed (CRITICAL)
- [ ] **Secrets in Environment**: Sensitive environment variables exposed (HIGH)
- [ ] **Secrets in Logs**: Secrets logged (CRITICAL)
- [ ] **Secrets in URLs**: Secrets in URL parameters (HIGH)
- [ ] **Secrets in Error Messages**: Secrets in error messages (CRITICAL)

### Secrets Storage
- [ ] **Plaintext Storage**: Secrets stored in plaintext (CRITICAL)
- [ ] **Weak Encryption**: Weak encryption for secrets (HIGH)
- [ ] **No Rotation**: No secret rotation (HIGH)
- [ ] **No Access Control**: No access control on secrets (HIGH)
- [ ] **Secrets in Database**: Secrets in database without encryption (HIGH)

### Secrets Access
- [ ] **Excessive Access**: Too many users have access to secrets (HIGH)
- [ ] **No Auditing**: No audit trail for secret access (MEDIUM)
- [ ] **No Principle of Least Privilege**: Not following principle of least privilege (HIGH)
- [ ] **Shared Credentials**: Shared credentials instead of individual (HIGH)

### Secrets in CI/CD
- [ ] **Secrets in Pipeline**: Secrets in CI/CD configuration (CRITICAL)
- [ ] **No Secret Rotation**: CI/CD secrets not rotated (HIGH)
- [ ] **Secrets in Logs**: CI/CD logs contain secrets (CRITICAL)
- [ ] **No Secret Scanning**: Not scanning for secrets in code (HIGH)

## COMPLIANCE REVIEW

### SOC2
- [ ] **Access Control**: Missing access controls (HIGH)
- [ ] **Change Management**: No change management process (MEDIUM)
- [ ] **Incident Response**: No incident response plan (MEDIUM)
- [ ] **Logging**: Insufficient logging for SOC2 (HIGH)
- [ ] **Monitoring**: Insufficient monitoring for SOC2 (HIGH)
- [ ] **Risk Assessment**: No risk assessment process (MEDIUM)

### GDPR
- [ ] **Data Minimization**: Not following data minimization (HIGH)
- [ ] **Consent**: No proper consent mechanisms (HIGH)
- [ ] **Right to Erasure**: No right to be forgotten (HIGH)
- [ ] **Data Portability**: No data portability (HIGH)
- [ ] **Breach Notification**: No breach notification process (CRITICAL)
- [ ] **Data Processing**: No documented data processing (MEDIUM)
- [ ] **DPO**: No Data Protection Officer (if required) (MEDIUM)

### PCI-DSS
- [ ] **Cardholder Data**: Cardholder data not properly protected (CRITICAL)
- [ ] **Encryption**: Not encrypting cardholder data (CRITICAL)
- [ ] **Transmission**: Not encrypting data in transit (CRITICAL)
- [ ] **Access Control**: Insufficient access control (HIGH)
- [ ] **Network Security**: Insufficient network security (HIGH)
- [ ] **Logging**: Insufficient logging (MEDIUM)
- [ ] **Vulnerability Management**: No vulnerability scanning (HIGH)

### HIPAA
- [ ] **PHI Protection**: PHI not properly protected (CRITICAL)
- [ ] **Encryption**: Not encrypting PHI (CRITICAL)
- [ ] **Access Control**: Insufficient access control for PHI (HIGH)
- [ ] **Audit Trails**: No audit trail for PHI access (HIGH)
- [ ] **Business Associates**: No BAAs (MEDIUM)
- [ ] **Breach Notification**: No breach notification (CRITICAL)

## OUTPUT FORMAT

### Security Review Report Output
```markdown
## Security Assessment Report

### Critical Vulnerabilities (CRITICAL - Fix Immediately)

1. **[Vulnerability Name]**: [File:line]
   - Severity: CRITICAL
   - OWASP Category: [A01-A10]
   - CVSS Score: [if available]
   - Description: [Detailed vulnerability description]
   - Impact: [Potential consequence]
   - Attack Vector: [How to exploit]
   - Fix: [Recommended remediation steps]
   - Code Example: [Vulnerable and Fixed code]
   - Reference: @owasp/OWASP-TOP10.md or @security/[SPECIFIC-SECURITY].md

### High Priority Vulnerabilities (HIGH - Fix Soon)

[Same format as Critical]

### Medium Priority Vulnerabilities (MEDIUM - Consider Fixing)

[Same format as Critical]

### Low Priority Vulnerabilities (LOW - Nice to Have)

[Same format as Critical]

### OWASP Top 10 Assessment
- **A01: Broken Access Control**: [Issues found]
- **A02: Cryptographic Failures**: [Issues found]
- **A03: Injection**: [Issues found]
- **A04: Insecure Design**: [Issues found]
- **A05: Security Misconfiguration**: [Issues found]
- **A06: Vulnerable Components**: [Issues found]
- **A07: Auth Failures**: [Issues found]
- **A08: Integrity Failures**: [Issues found]
- **A09: Logging Failures**: [Issues found]
- **A10: SSRF**: [Issues found]

### Authentication Issues
- **Password Issues**: [List of password-related issues]
- **Session Issues**: [List of session-related issues]
- **MFA Issues**: [List of MFA-related issues]
- **OAuth/JWT/SAML Issues**: [List of protocol-specific issues]

### Input Validation Issues
- **SQLi**: [Locations and types]
- **XSS**: [Locations and types]
- **CSRF**: [Forms missing CSRF protection]
- **Command Injection**: [Command injection locations]
- **Path Traversal**: [Path traversal locations]
- **Other Input Issues**: [Other validation issues]

### File Upload Issues
- **Type Validation**: [File type validation issues]
- **Size Validation**: [File size validation issues]
- **Storage Security**: [Storage security issues]
- **Execution Risks**: [File execution risks]

### Security Headers Issues
- **Missing Headers**: [List of missing headers]
- **Weak Headers**: [List of weak headers]
- **CSP Issues**: [CSP-specific issues]
- **HSTS Issues**: [HSTS-specific issues]

### Secrets Management Issues
- **Hardcoded Secrets**: [Locations of hardcoded secrets]
- **Storage Issues**: [Secrets storage issues]
- **Access Issues**: [Secrets access issues]
- **CI/CD Issues**: [Secrets in CI/CD]

### Compliance Assessment
- **SOC2**: [Status: Compliant/Non-compliant]
- **GDPR**: [Status: Compliant/Non-compliant]
- **PCI-DSS**: [Status: Compliant/Non-compliant]
- **HIPAA**: [Status: Compliant/Non-compliant]
- **Gap Analysis**: [List of compliance gaps]

### Vulnerability Scanning Results
- **SAST Findings**: [Summary of SAST findings]
- **DAST Findings**: [Summary of DAST findings]
- **Dependency Scanning**: [Summary of dependency vulnerabilities]
- **Container Scanning**: [Summary of container vulnerabilities]

### Remediation Priority
1. [Critical issues requiring immediate fix]
2. [High priority issues]
3. [Medium priority improvements]
4. [Low priority enhancements]

### Recommendations
1. [Security improvement]
2. [Compliance improvement]
3. [Architecture improvement]
4. [Process improvement]

### Related Skills
- @database-engineering/SKILL.md (for SQLi, query optimization)
- @software-engineering/SKILL.md (for code quality issues)
- @performance-engineering/SKILL.md (for performance issues)
```
