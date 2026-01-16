# FILE UPLOAD SECURITY

## OVERVIEW
File uploads are a common attack vector. Proper validation, storage, and access controls are critical.

## ATTACK VECTORS

### 1. Malicious File Upload (Web Shell)

**Vulnerability**: Attacker uploads executable file (e.g., `shell.php`) which executes on server.

```php
// VULNERABLE: No validation
$filename = $_FILES['file']['name'];
move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/$filename");

// Attacker uploads: shell.php
// Then executes: http://example.com/uploads/shell.php?cmd=ls%20-la
```

**Prevention**:
```php
// SECURE: Generate safe filename
$extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
$safeFilename = uniqid() . '.' . $extension;
$destination = "/uploads/" . $safeFilename;

// Validate file type (not just extension)
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $_FILES['file']['tmp_name']);
$allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];

if (!in_array($mimeType, $allowedTypes)) {
    die('Invalid file type');
}

move_uploaded_file($_FILES['file']['tmp_name'], $destination);
```

---

### 2. File Overwrite Attack

**Vulnerability**: Attacker overwrites critical files (e.g., `.htaccess`, `web.config`).

```php
// VULNERABLE: Uses attacker-provided filename
$filename = $_FILES['file']['name'];  // Attacker: .htaccess
move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/$filename");

// Overwrites: /uploads/.htaccess
```

**Prevention**:
```php
// SECURE: Generate random filename
$extension = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
$safeFilename = bin2hex(random_bytes(16)) . '.' . $extension;
$destination = "/uploads/" . $safeFilename;

move_uploaded_file($_FILES['file']['tmp_name'], $destination);

// Store original filename in database
DB::insert('files', [
    'filename' => $safeFilename,
    'original_name' => $_FILES['file']['name'],
    'user_id' => $userId
]);
```

---

### 3. Path Traversal Attack

**Vulnerability**: Attacker accesses files outside upload directory using `../`.

```php
// VULNERABLE: No path validation
$filename = $_FILES['file']['name'];
$destination = "/uploads/" . $filename;
move_uploaded_file($_FILES['file']['tmp_name'], $destination);

// Attacker: filename="../../etc/passwd"
// Moves to: /etc/passwd
```

**Prevention**:
```php
// SECURE: basename() and realpath()
$filename = basename($_FILES['file']['name']);
$uploadDir = realpath('/uploads');
$destination = $uploadDir . '/' . $filename;
$realDestination = realpath($destination);

// Verify destination is within upload directory
if (strpos($realDestination, $uploadDir) !== 0) {
    die('Invalid filename');
}

move_uploaded_file($_FILES['file']['tmp_name'], $realDestination);
```

---

### 4. Double Extension Attack

**Vulnerability**: Attacker uses multiple extensions to bypass extension validation.

```php
// VULNERABLE: Only validates last extension
$filename = $_FILES['file']['name'];
$extension = pathinfo($filename, PATHINFO_EXTENSION);

if (!in_array($extension, ['jpg', 'png', 'pdf'])) {
    die('Invalid extension');
}

move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/$filename");

// Attacker uploads: image.php.jpg
// Validation passes (.jpg)
// But PHP executes: .php part!
```

**Prevention**:
```php
// SECURE: Use MIME type, not extension
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $_FILES['file']['tmp_name']);

$allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];

if (!in_array($mimeType, $allowedTypes)) {
    die('Invalid file type');
}

// Verify file signature (magic bytes)
$handle = fopen($_FILES['file']['tmp_name'], 'rb');
$signature = fread($handle, 8);
fclose($handle);

// JPEG: FF D8 FF E0 00 10 4A 46 49
// PNG: 89 50 4E 47 0D 0A 1A 0A 00
$allowedSignatures = [
    "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46",  // JPEG
    "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00"    // PNG
];

if (!in_array($signature, $allowedSignatures)) {
    die('Invalid file');
}
```

---

### 5. Null Byte Injection

**Vulnerability**: Attacker uses null byte to bypass extension validation.

```php
// VULNERABLE: PHP < 5.3.4 vulnerable
$filename = $_FILES['file']['name'];
$parts = explode('.', $filename);
$extension = end($parts);

if (!in_array($extension, ['jpg', 'png'])) {
    die('Invalid extension');
}

move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/$filename");

// Attacker: shell.php%00.jpg
// Validation: extension = jpg (passes)
// PHP executes: shell.php (null byte truncates .jpg)
```

**Prevention**:
```php
// SECURE: Use latest PHP, MIME type validation
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $_FILES['file']['tmp_name']);

if ($mimeType !== 'image/jpeg' && $mimeType !== 'image/png') {
    die('Invalid file type');
}

// Never trust extension alone
```

---

### 6. File Size Exhausion

**Vulnerability**: Attacker uploads huge files, filling disk space and causing DoS.

```php
// VULNERABLE: No size limit
move_uploaded_file($_FILES['file']['tmp_name'], "/uploads/{$_FILES['file']['name']}");

// Attacker uploads: 10GB file
// Disk fills up, system crashes
```

**Prevention**:
```php
// SECURE: Validate file size
$maxSize = 10 * 1024 * 1024;  // 10MB

if ($_FILES['file']['size'] > $maxSize) {
    die('File too large. Maximum 10MB allowed.');
}

// Or configure in php.ini
// upload_max_filesize = 10M
// post_max_size = 10M
```

---

## SECURE FILE UPLOAD IMPLEMENTATION

### Complete Secure Upload (PHP)

```php
class FileUploader {
    private string $uploadDir;
    private int $maxSize = 10 * 1024 * 1024;  // 10MB
    private array $allowedTypes = ['image/jpeg', 'image/png', 'application/pdf'];

    public function __construct(string $uploadDir)
    {
        $this->uploadDir = $uploadDir;
    }

    public function upload(array $file): array
    {
        // 1. Validate upload error
        if ($file['error'] !== UPLOAD_ERR_OK) {
            throw new RuntimeException('Upload error');
        }

        // 2. Validate file size
        if ($file['size'] > $this->maxSize) {
            throw new RuntimeException('File too large. Maximum 10MB allowed.');
        }

        // 3. Validate MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        if (!in_array($mimeType, $this->allowedTypes)) {
            throw new RuntimeException('Invalid file type');
        }

        // 4. Validate file signature (magic bytes)
        if (!$this->validateSignature($file['tmp_name'])) {
            throw new RuntimeException('Invalid file signature');
        }

        // 5. Generate safe filename
        $extension = $this->getExtension($mimeType);
        $safeFilename = bin2hex(random_bytes(16)) . '.' . $extension;

        // 6. Path traversal prevention
        $uploadDir = realpath($this->uploadDir);
        $destination = $uploadDir . '/' . $safeFilename;
        $realDestination = realpath($destination);

        if (strpos($realDestination, $uploadDir) !== 0) {
            throw new RuntimeException('Invalid filename');
        }

        // 7. Move uploaded file
        if (!move_uploaded_file($file['tmp_name'], $realDestination)) {
            throw new RuntimeException('Failed to move file');
        }

        return [
            'filename' => $safeFilename,
            'original_name' => $file['name'],
            'size' => $file['size'],
            'mime_type' => $mimeType
        ];
    }

    private function validateSignature(string $filepath): bool
    {
        $handle = fopen($filepath, 'rb');
        $signature = fread($handle, 8);
        fclose($handle);

        // JPEG signature
        if ($signature === "\xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46") {
            return true;
        }

        // PNG signature
        if ($signature === "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00") {
            return true;
        }

        // PDF signature
        if (substr($signature, 0, 4) === '%PDF') {
            return true;
        }

        return false;
    }

    private function getExtension(string $mimeType): string
    {
        $extensions = [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'application/pdf' => 'pdf'
        ];

        return $extensions[$mimeType] ?? 'bin';
    }
}

// Usage
$uploader = new FileUploader('/var/www/uploads');

try {
    $result = $uploader->upload($_FILES['file']);
    echo "File uploaded: " . $result['filename'];
} catch (Exception $e) {
    echo "Upload failed: " . $e->getMessage();
}
```

---

## SERVER CONFIGURATION

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name example.com;

    root /var/www/uploads;
    index index.html;

    # Prevent execution of uploaded scripts
    location ~* \.(php|pl|py|jsp|sh|exe)$ {
        deny all;
    }

    # Limit upload size
    client_max_body_size 10M;

    # Prevent directory listing
    autoindex off;
}
```

### Apache Configuration

```apache
<Directory /var/www/uploads>
    # Prevent execution of uploaded files
    <FilesMatch "\.(php|pl|py|jsp|sh|exe)$">
        Require all denied
    </FilesMatch>

    # Prevent directory listing
    Options -Indexes

    # Limit upload size
    LimitRequestBody 10485760  # 10MB
</Directory>
```

---

## ADDITIONAL SECURITY MEASURES

### 1. Separate Upload Domain

```
example.com           # Main application
uploads.example.com  # File uploads (different origin)
```

**Benefits**:
- Prevents XSS from uploaded files
- Files cannot execute under main domain
- Easy to isolate and secure uploads

---

### 2. Store Files Outside Web Root

```
/var/www/app/       # Application code (no uploads)
/var/www/uploads/    # Uploads (no scripts)
```

**Nginx Configuration**:
```nginx
location /uploads/ {
    alias /var/www/uploads/;
    # No PHP execution in uploads directory
    location ~* \.php$ {
        deny all;
    }
}
```

---

### 3. Virus Scanning

```php
// Use ClamAV to scan uploaded files
exec('clamscan --no-summary ' . escapeshellarg($file['tmp_name']), $output, $returnCode);

if ($returnCode !== 0) {
    throw new RuntimeException('File contains virus');
}
```

---

### 4. Content Delivery Network (CDN)

```php
// Upload to S3/CloudFront, not local filesystem
$s3Client = new S3Client([
    'region' => 'us-east-1',
    'credentials' => [...]
]);

$s3Client->putObject([
    'Bucket' => 'my-uploads',
    'Key' => $safeFilename,
    'SourceFile' => $file['tmp_name'],
    'ContentType' => $mimeType
]);

// Serve via CloudFront (no execution possible)
$url = $cloudFrontClient->getSignedUrl([
    'Bucket' => 'my-uploads',
    'Key' => $safeFilename
], '+15 minutes');
```

---

## FILE UPLOAD CHECKLIST

### Before Deployment
- [ ] File type validated by MIME type (not just extension)
- [ ] File signature (magic bytes) verified
- [ ] File size limited (e.g., 10MB)
- [ ] Random filename generated
- [ ] Original filename stored in database
- [ ] Path traversal prevention (basename, realpath)
- [ ] Double extension prevention
- [ ] Files stored outside web root or on separate domain
- [ ] Virus scanning implemented
- [ ] Upload directory has no execute permissions
- [ ] Web server configured to deny script execution in uploads
- [ ] Directory listing disabled
- [ ] Access controls (authentication, authorization) implemented
- [ ] Logs record upload events

---

## CROSS-REFERENCES
- For input validation: @security/INPUT-VALIDATION.md
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For command injection: @software-engineering/security/CODE-INJECTION.md
