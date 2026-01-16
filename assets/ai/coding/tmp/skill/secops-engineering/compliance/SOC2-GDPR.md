# SOC2 & GDPR COMPLIANCE

## OVERVIEW
SOC2 (System and Organization Controls) and GDPR (General Data Protection Regulation) are critical compliance frameworks for data security and privacy.

## SOC2 COMPLIANCE

### 1. SOC2 Common Criteria

**Trust Services Criteria (TSC)**:
- **CC1.1**: Properly authorized and communicated
- **CC2.1**: Qualified personnel
- **CC3.1**: Adequate resources
- **CC4.1**: Monitoring and detection
- **CC5.1**: Respond to incidents
- **CC6.1**: Prevent or minimize impact
- **CC7.1**: System improvements

---

### 2. Access Control (CC6.1)

**Requirements**:
- [ ] Unique user identification
- [ ] Access restrictions based on need-to-know
- [ ] Regular access reviews
- [ ] Automated provisioning/deprovisioning
- [ ] Multi-factor authentication (MFA)

**Implementation**:

**User Access Management**:
```python
class AccessControl:
    def grant_user_access(self, user_id: int, resource: str, level: str):
        # Log all access grants
        audit_log.info(f"Access granted: user={user_id} resource={resource} level={level}")

        # Enforce least privilege
        if not self.user_needs_resource(user_id, resource, level):
            raise AccessDeniedException("User does not need this access level")

        # Grant access
        self.database.grant_access(user_id, resource, level)

        # Schedule access review (90 days)
        schedule_access_review(user_id, resource, days=90)
```

**Audit Logging**:
```python
import logging
from datetime import datetime

# Structured audit logging
audit_logger = logging.getLogger('audit')
audit_handler = logging.FileHandler('/var/log/audit.log')
audit_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s %(message)s'
))
audit_logger.addHandler(audit_handler)

def log_access_event(event_type: str, user_id: int, resource: str, success: bool):
    audit_logger.info(json.dumps({
        'event_type': event_type,
        'user_id': user_id,
        'resource': resource,
        'success': success,
        'timestamp': datetime.utcnow().isoformat(),
        'ip_address': get_client_ip()
    }))
```

---

### 3. Change Management (CC6.6)

**Requirements**:
- [ ] All changes authorized
- [ ] Changes tested before production
- [ ] Rollback plans documented
- [ ] Emergency access procedures

**Implementation**:

**Change Request Process**:
```python
class ChangeRequest:
    def __init__(self, title, description, requester, change_type):
        self.title = title
        self.description = description
        self.requester = requester
        self.change_type = change_type  # normal, emergency, critical
        self.status = 'pending_approval'
        self.approvals = []
        self.rollback_plan = None

    def submit(self):
        # Store in change management database
        db.change_requests.insert(self.to_dict())

        # Notify approvers
        notify_approvers(self)

    def add_approval(self, approver, comments):
        self.approvals.append({
            'approver': approver,
            'comments': comments,
            'timestamp': datetime.utcnow()
        })

    def add_rollback_plan(self, rollback_steps):
        self.rollback_plan = rollback_steps
```

---

### 4. Monitoring and Logging (CC6.1, CC6.2)

**Requirements**:
- [ ] All access logged
- [ ] Failed login attempts logged
- [ ] System events logged
- [ ] Logs protected from tampering
- [ ] Logs retained for minimum 90 days

**Implementation**:

**Centralized Logging**:
```python
import json
from logging.handlers import RotatingFileHandler

# Secure logging setup
logger = logging.getLogger('application')

# Rotate logs (prevent disk exhaustion)
handler = RotatingFileHandler(
    '/var/log/application.log',
    maxBytes=100*1024*1024,  # 100MB
    backupCount=10
)
handler.setFormatter(logging.Formatter(json.dumps({
    'timestamp': '%(asctime)s',
    'level': '%(levelname)s',
    'message': '%(message)s',
    'user_id': '%(user_id)s'
})))

logger.addHandler(handler)
```

---

### 5. Data Encryption (CC6.1)

**Requirements**:
- [ ] Data at rest encrypted
- [ ] Data in transit encrypted
- [ ] Key management procedures
- [ ] Encryption key rotation

**Implementation**:

**Encryption at Rest**:
```python
from cryptography.fernet import Fernet

# Load encryption key from secure location
def load_encryption_key():
    with open('/run/secrets/encryption_key', 'rb') as f:
        return f.read()

# Encrypt data
def encrypt_data(data: str, key: bytes) -> bytes:
    cipher_suite = Fernet(key)
    return cipher_suite.encrypt(data.encode())

# Decrypt data
def decrypt_data(encrypted_data: bytes, key: bytes) -> str:
    cipher_suite = Fernet(key)
    return cipher_suite.decrypt(encrypted_data).decode()

# Database encryption
def encrypt_sensitive_data(user_data: dict) -> dict:
    key = load_encryption_key()

    encrypted_data = {
        'id': user_data['id'],
        'email': user_data['email'],
        'name': encrypt_data(user_data['name'], key),
        'ssn': encrypt_data(user_data['ssn'], key)  # Encrypt SSN
    }

    return encrypted_data
```

**Encryption in Transit**:
```python
# HTTPS only (TLS 1.2+)
app.config.update({
    'SSL_CONTEXT': ssl.create_default_context(),
    'REQUIRE_SSL': True
})

# HSTS header
@app.route('/')
def index():
    response = make_response('Hello')
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    return response
```

---

## GDPR COMPLIANCE

### 1. Data Subject Rights (GDPR Articles 15-22)

**Rights**:
1. **Right to be informed** (Art. 13-14)
2. **Right of access** (Art. 15)
3. **Right to rectification** (Art. 16)
4. **Right to erasure** (Art. 17)
5. **Right to restrict processing** (Art. 18)
6. **Right to data portability** (Art. 20)
7. **Right to object** (Art. 21)

**Implementation**:

**Data Access Request**:
```python
class GDPRManager:
    def handle_data_access_request(self, user_id: int) -> dict:
        # Retrieve all user data
        user_data = self.database.get_all_user_data(user_id)

        # Format for export
        export = {
            'personal_data': user_data['personal'],
            'usage_data': user_data['usage'],
            'consent_records': user_data['consents'],
            'export_date': datetime.utcnow().isoformat()
        }

        # Generate export file
        self.create_export_file(user_id, export)

        # Log access request
        audit_logger.info(f"Data access request: user={user_id}")

        return export
```

**Data Deletion Request**:
```python
    def handle_data_deletion_request(self, user_id: int) -> bool:
        # Verify identity
        if not self.verify_user_identity(user_id):
            raise VerificationFailedException("Identity verification failed")

        # Identify all data to delete
        user_data_locations = self.database.find_user_data(user_id)

        # Log deletion request
        audit_logger.info(f"Data deletion request: user={user_id}")

        # Delete from all systems
        for location in user_data_locations:
            self.delete_data(location)

        # Confirm deletion
        self.send_deletion_confirmation(user_id)

        return True
```

---

### 2. Consent Management (GDPR Article 7)

**Requirements**:
- [ ] Explicit, informed consent
- [ ] Granular consent (separate for each purpose)
- [ ] Freely given consent
- [ ] Withdrawable consent
- [ ] Consent records retained

**Implementation**:

**Consent Management**:
```python
class ConsentManager:
    def request_consent(self, user_id: int, purpose: str, details: str):
        # Generate consent request
        consent_request = {
            'user_id': user_id,
            'purpose': purpose,
            'details': details,
            'requested_at': datetime.utcnow(),
            'status': 'pending'
        }

        self.database.insert_consent_request(consent_request)

        # Send consent request
        self.send_consent_email(user_id, consent_request)

    def record_consent(self, user_id: int, purpose: str, consented: bool):
        consent_record = {
            'user_id': user_id,
            'purpose': purpose,
            'consented': consented,
            'timestamp': datetime.utcnow(),
            'ip_address': get_client_ip()
        }

        self.database.insert_consent_record(consent_record)

        audit_logger.info(f"Consent recorded: user={user_id} purpose={purpose} consented={consented}")

    def withdraw_consent(self, user_id: int, purpose: str):
        self.database.update_consent_status(user_id, purpose, 'withdrawn')

        # Delete data associated with consent (Art. 17)
        self.delete_purpose_data(user_id, purpose)

        audit_logger.info(f"Consent withdrawn: user={user_id} purpose={purpose}")
```

---

### 3. Data Breach Notification (GDPR Article 33)

**Requirements**:
- [ ] Notify within 72 hours
- [ ] Describe nature of breach
- [ ] Contact information
- [ ] Likely consequences
- [ ] Measures taken

**Implementation**:

**Breach Response**:
```python
class DataBreachHandler:
    def handle_breach(self, breach_data: dict):
        # Assess severity
        severity = self.assess_breach_severity(breach_data)

        # Notify supervisory authority (if high risk)
        if severity in ['high', 'critical']:
            self.notify_authority(breach_data)

        # Notify affected individuals
        affected_users = self.get_affected_users(breach_data)

        for user_id in affected_users:
            self.notify_user_breach(user_id, breach_data)

        # Document breach response
        self.document_breach_response(breach_data)

    def notify_user_breach(self, user_id: int, breach_data: dict):
        user = self.database.get_user(user_id)

        notification = {
            'breach_date': breach_data['detected_at'],
            'type_of_breach': breach_data['type'],
            'affected_data': breach_data['affected_data'],
            'measures_taken': breach_data['response_measures'],
            'contact_details': 'privacy@example.com'
        }

        # Send email
        self.send_breach_email(user['email'], notification)

        # Log notification
        audit_logger.critical(f"Breach notification sent: user={user_id}")
```

---

## COMPLIANCE CHECKLIST

### SOC2 Checklist
- [ ] Access controls documented and enforced
- [ ] Change management process in place
- [ ] Security monitoring implemented
- [ ] Incident response procedures documented
- [ ] Vulnerability management program
- [ ] Data encryption implemented (at rest and in transit)
- [ ] Network security controls in place
- [ ] Physical access controls (if applicable)
- [ ] Security awareness training conducted
- [ ] Third-party risk assessments conducted
- [ ] Regular security reviews and audits

### GDPR Checklist
- [ ] Lawful basis for processing documented
- [ ] Privacy policy accessible and clear
- [ ] Data minimization implemented
- [ ] Consent management system in place
- [ ] Data subject rights implemented (access, rectification, erasure)
- [ ] Data portability implemented
- [ ] Data breach notification procedures
- [ ] Data Protection Officer (DPO) appointed
- [ ] Data processing agreement (DPA) with processors
- [ ] Cross-border data transfer safeguards
- [ ] Cookie consent implemented
- [ ] Privacy by design principles followed
- [ ] Regular privacy impact assessments (PIAs)

---

## DOCUMENTATION REQUIREMENTS

### SOC2 Documentation
- [ ] Security policy
- [ ] Access control policy
- [ ] Incident response policy
- [ ] Change management policy
- [ ] Data classification policy
- [ ] Encryption standards
- [ ] Network security policy
- [ ] Physical security policy
- [ ] Third-party vendor management policy

### GDPR Documentation
- [ ] Privacy policy
- [ ] Cookie policy
- [ ] Data processing agreement (DPA)
- [ ] Records of processing activities (ROPA)
- [ ] Data protection impact assessments (PIA)
- [ ] Consent records
- [ ] Data breach response plan
- [ ] Data subject rights procedures

---

## CROSS-REFERENCES
- For security patterns: @security/AUTHENTICATION.md, @security/INPUT-VALIDATION.md
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For secrets management: @secrets/SECRETS-MANAGEMENT.md
