# SECURITY FRAMEWORK

## PURPOSE
Universal security protocols for all components.

## CORE PRINCIPLES
- **Zero Trust**: Assume all input is malicious until validated
- **Least Privilege**: Execute with minimal required permissions
- **Fail Safe**: Default to safe state on error
- **Defense in Depth**: Multiple validation layers

## THREAT MODEL
### Common Threats
| Threat | Pattern | Mitigation |
|--------|---------|------------|
| Command Injection | `; rm -rf` | Sanitize input, use subprocess with list args |
| Path Traversal | `../../etc/passwd` | Validate absolute paths, whitelist directories |
| Secret Exposure | Log tokens/passwords | Redact secrets, sanitize errors |
| Data Loss | `rm`, `push -f` | Require user confirmation |

## VALIDATION LAYERS (Apply in Order)
1. **Input Validation**: Type check, schema validate, sanitize
2. **Context Validation**: Verify permissions, check dependencies
3. **Execution Validation**: Confirm intent, check for destructive operations
4. **Output Validation**: Verify format, redact secrets

## OPERATIONAL STANDARDS

### Destructive Operation Protection
IF destructive operation (rm, sudo, push -f, chmod 777) requested THEN
  Require User_Confirm
  Display operation details
  Display impact assessment
  Wait(User_Confirm)
END

### Input Sanitization
IF input contains shell metacharacters THEN
  Sanitize input
  Validate schema
  Reject if validation fails
END

### Path Traversal Prevention
IF path traversal detected THEN
  Reject absolute paths
  Validate against whitelist
  Error if path invalid
END

### Secret Protection
IF secrets might be exposed THEN
  Redact secrets from output
  Sanitize error messages
  Never log sensitive data
END

### Error Handling
IF error occurs THEN
  Provide safe error message
  Never expose stack traces
  Never expose secrets
  Log sanitized error
END
