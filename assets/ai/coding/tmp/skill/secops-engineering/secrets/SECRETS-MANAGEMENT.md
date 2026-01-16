# SECRETS MANAGEMENT

## OVERVIEW
Proper secrets management prevents credential exposure, protects sensitive data, and enables secure rotation.

## ATTACK VECTORS

### 1. Hardcoded Secrets

**Vulnerability**: Secrets hardcoded in source code.

**Example**:
```php
// VULNERABLE: Hardcoded password in code
$connection = new PDO(
    'mysql:host=localhost;dbname=app',
    'user',
    'SuperSecretPassword123'  // Secret in code!
);
```

**Impact**:
- Secrets exposed in version control
- All developers have access to production secrets
- Secrets cannot be rotated easily

---

### 2. Secrets in Environment Files

**Vulnerability**: Secrets stored in `.env` files committed to version control.

**Example**:
```bash
# .env (should not be committed!)
DB_PASSWORD=SuperSecretPassword123
API_KEY=sk-1234567890abcdef
```

**Impact**:
- If `.env` committed to Git, secrets are exposed
- Accidental commits reveal secrets

**Prevention**:
```bash
# Add .env to .gitignore
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore

# Use environment-specific files
.env.local       # Local development (never commit)
.env.development
.env.staging
.env.production
```

---

### 3. Secrets in Logs

**Vulnerability**: Secrets logged to files/console.

**Example**:
```javascript
// VULNERABLE: Logging secrets
console.log(`Connecting to database with user: ${user} password: ${password}`);
logger.info(`API Key: ${apiKey}`);
```

**Prevention**:
```javascript
// SECURE: Redact secrets from logs
const redacted = '***REDACTED***';
logger.info(`Connecting to database with user: ${user}`);
// Or use structured logging with field redaction
```

---

## SECRETS MANAGEMENT STRATEGIES

### 1. Environment Variables

**Implementation**:
```bash
# Production environment
export DB_HOST=production-db.example.com
export DB_PASSWORD=$(cat /run/secrets/db_password)  # Read from secure storage
export API_KEY=$(cat /run/secrets/api_key)

# Application reads from environment
$password = getenv('DB_PASSWORD');
```

**PHP**:
```php
// Read from environment
$dbPassword = getenv('DB_PASSWORD');
$apiKey = getenv('API_KEY');
```

**JavaScript (Node.js)**:
```javascript
// Read from process.env
const dbPassword = process.env.DB_PASSWORD;
const apiKey = process.env.API_KEY;
```

---

### 2. Secrets Manager Services

### AWS Secrets Manager

**Store Secret**:
```bash
aws secretsmanager create-secret \
  --name prod/db/password \
  --secret-string "SuperSecretPassword123"
```

**Retrieve Secret**:
```python
import boto3

client = boto3.client('secretsmanager')

# Retrieve secret
response = client.get_secret_value(SecretId='prod/db/password')
password = response['SecretString']
```

**Automatic Rotation**:
```bash
# Create secret with rotation
aws secretsmanager create-secret \
  --name prod/db/password \
  --secret-string "InitialPassword123" \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:1234567890:function:RotateSecret \
  --rotation-rules AutomaticallyAfterDays=30
```

### HashiCorp Vault

**Store Secret**:
```bash
vault kv put secret/db-password \
  password="SuperSecretPassword123" \
  ttl="720h"
```

**Retrieve Secret**:
```python
import hvac

# Connect to Vault
client = hvac.Client(url='https://vault.example.com')
client.auth.approle.login('app-role', 'role-id')

# Retrieve secret
secret = client.kv.v2.read_secret_version(path='db-password', raise_on_deleted_version=False)
password = secret['data']['data']['password']
```

### Azure Key Vault

**Store Secret**:
```bash
az keyvault secret set \
  --vault-name my-vault \
  --name db-password \
  --value SuperSecretPassword123
```

**Retrieve Secret**:
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://my-vault.vault.azure.net", credential=credential)

# Retrieve secret
password = client.get_secret("db-password").value
```

---

### 3. Kubernetes Secrets

**Create Secret**:
```bash
kubectl create secret generic db-credentials \
  --from-literal=password=SuperSecretPassword123 \
  --from-literal=username=appuser
```

**Secret Manifest**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  password: SuperSecretPassword123
  username: appuser
```

**Use Secret in Pod**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
```

**Encrypted Secrets (K8s 1.13+)**:
```bash
# Encrypt secret with K8s encryption provider
kubectl create secret generic api-key \
  --from-literal=key=sk-1234567890abcdef \
  --encryption-provider aws-kms \
  --encryption-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-9012-3456789012
```

---

## SECRET ROTATION

### 1. Manual Rotation

**Process**:
```
1. Generate new secret
2. Update application configuration
3. Deploy with new secret
4. Verify application works
5. Retire old secret
6. Update all integrations
```

**Implementation**:
```python
class SecretRotator:
    def rotate_database_password(self, db_instance: str):
        # 1. Generate new password
        new_password = generate_strong_password()

        # 2. Update database
        self.update_database_password(db_instance, new_password)

        # 3. Update secrets manager
        self.secrets_manager.update(
            secret_name=f"{db_instance}/password",
            new_value=new_password
        )

        # 4. Deploy application (uses new secret automatically)

        # 5. Verify
        if self.test_database_connection(db_instance):
            # 6. Retire old password (after 24 hours)
            self.schedule_old_secret_deletion(db_instance, hours=24)
```

---

### 2. Automatic Rotation

**AWS Secrets Manager with Lambda**:
```python
# Lambda function to rotate secret
import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    arn = event['SecretId']
    token = event['ClientRequestToken']

    # Create Secrets Manager client
    client = boto3.client('secretsmanager')

    # Get current secret value
    current_secret = json.loads(
        client.get_secret_value(SecretId=arn, VersionStage="AWSCURRENT')['SecretString']
    )

    # Generate new password
    new_password = generate_strong_password()

    # Set new password in database
    if update_database_password(current_secret['db_instance'], new_password):
        # Update secret
        client.put_secret_value(
            SecretId=arn,
            SecretString=json.dumps({
                'db_instance': current_secret['db_instance'],
                'password': new_password,
                'version': current_secret['version'] + 1
            }),
            ClientRequestToken=token
        )

        return {
            'statusCode': 200,
            'body': json.dumps('Password rotated successfully')
        }
    else:
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to rotate password')
        }
```

**Configure Rotation**:
```bash
aws secretsmanager rotate-secret \
  --secret-id arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/db-password \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:RotateSecret
```

---

## SECRETS IN CI/CD

### 1. GitHub Secrets

**Set Secret**:
```
Repository → Settings → Secrets → Actions → New repository secret
Name: DB_PASSWORD
Value: SuperSecretPassword123
```

**Use Secret in Workflow**:
```yaml
name: Deploy

on: push
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Deploy to production
      run: |
        # Secret automatically injected as environment variable
        echo "Deploying with database password..."
        php artisan deploy --password=${{ secrets.DB_PASSWORD }}
```

**Best Practices**:
- Secrets are encrypted at rest
- Secrets are not logged by default
- Secrets are masked in output (e.g., `***`)
- Organization-level secrets can be shared across repositories

### 2. GitLab CI/CD Variables

**Set Secret**:
```
Project → Settings → CI/CD → Variables
Key: DB_PASSWORD
Value: SuperSecretPassword123
Protected: ✅ (hidden in logs)
Masked: ✅ (masked in job output)
```

**Use in Pipeline**:
```yaml
deploy-production:
  script:
    - php artisan deploy --password=$DB_PASSWORD
```

### 3. Environment-Specific Secrets

**Development**:
```bash
# .env.development (never commit)
DB_HOST=localhost
DB_PASSWORD=dev-password
```

**Staging**:
```bash
# .env.staging (never commit)
DB_HOST=staging-db.example.com
DB_PASSWORD=staging-password
```

**Production**:
```bash
# .env.production (never commit)
DB_HOST=production-db.example.com
DB_PASSWORD=$({vault kv get -field=password secret/db/password})
```

**CI/CD Workflow**:
```yaml
deploy-development:
  environment: development
  script:
    - cp .env.development .env
    - php artisan deploy

deploy-staging:
  environment: staging
  script:
    - echo $STAGING_DB_PASSWORD > .env
    - php artisan deploy

deploy-production:
  environment: production
  script:
    - echo $PRODUCTION_DB_PASSWORD > .env
    - php artisan deploy
```

---

## ACCESS CONTROL

### 1. Principle of Least Privilege

**Rule**: Grant minimum permissions necessary for task.

**IAM Policy Example (AWS)**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "aws:userid": ["user-id-123456"]
        }
      }
    }
  ]
}
```

**Kubernetes RBAC**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
roleRef:
  kind: Role
  name: secret-reader
```

---

### 2. Secret Rotation Policies

**Policy**:
```
- Database passwords: Rotate every 90 days
- API keys: Rotate every 180 days
- Encryption keys: Rotate every 365 days
- Compromised secrets: Rotate immediately
- Employee termination: Revoke all access within 1 hour
```

---

## SECRETS CHECKLIST

### Before Deployment
- [ ] No hardcoded secrets in source code
- [ ] No secrets in version control
- [ ] `.env` files in `.gitignore`
- [ ] Secrets stored in secure location (Vault, Secrets Manager)
- [ ] Secrets encrypted at rest
- [ ] Secrets encrypted in transit (HTTPS)
- [ ] Secret access logged and monitored
- [ ] Secret rotation policy documented
- [ ] Least privilege access controls in place
- [ ] Secrets redacted from logs and monitoring
- [ ] CI/CD uses secret manager (not plaintext)
- [ ] Environment-specific secrets configured
- [ ] Secrets not exposed in error messages

### Ongoing
- [ ] Regular secret audits (monthly)
- [ ] Automatic secret rotation configured
- [ ] Secret access reviews quarterly
- [ ] Secret scanning in CI/CD (detect accidental commits)
- [ ] Secrets lifecycle management
- [ ] Revocation process for compromised secrets

---

## CROSS-REFERENCES
- For authentication: @security/AUTHENTICATION.md
- For security patterns: @security/INPUT-VALIDATION.md
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For container security: @devops-engineering/security/CONTAINER-SECURITY.md
