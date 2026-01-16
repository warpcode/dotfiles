# CONTAINER SECURITY

## OVERVIEW
Container security protects containerized applications from attacks, vulnerabilities, and unauthorized access.

## CONTAINER ESCAPE VECTORS

### 1. Privileged Containers

**Vulnerability**: Running container with `--privileged` flag gives container full host access.

**Example**:
```bash
# BAD: Privileged container (full host access)
docker run --privileged -v /:/host-fs alpine sh

# Attacker inside container:
# Can now access entire host filesystem via /host-fs
# Can mount host devices
# Can modify host kernel
```

**Fix**: Never use `--privileged`
```bash
# GOOD: Non-privileged container
docker run --rm \
  -v /data:/app/data \
  -p 8080:8080 \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  myapp
```

---

### 2. Socket Mounting

**Vulnerability**: Mounting host Docker socket gives container ability to control Docker daemon.

**Example**:
```yaml
# BAD: Mounting Docker socket (CI/CD scenario)
services:
  docker-in-docker:
    image: docker:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock  # CRITICAL!
```

**Attack**:
```bash
# Inside container, attacker has Docker control
docker run -v /:/host-fs alpine sh  # Escape to host!
```

**Fix**: Use DinD (Docker-in-Docker) properly or use Kaniko
```yaml
# GOOD: Kaniko (no Docker socket needed)
services:
  build:
    image: gcr.io/kaniko-project/executor:latest
    args:
      - --dockerfile=Dockerfile
      - --context=dir://workspace
      - --destination=myregistry.com/myapp:tag
```

---

### 3. Root User

**Vulnerability**: Running as root gives attacker more privilege if container is compromised.

**Example**:
```dockerfile
# BAD: Running as root
FROM node:18-alpine
WORKDIR /app
COPY . .
USER root
CMD ["node", "server.js"]
```

**Attack**:
```bash
# If attacker escapes container, they're root on host
```

**Fix**: Use non-root user
```dockerfile
# GOOD: Non-root user
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Production stage
FROM node:18-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json
COPY --chown=nodejs:nodejs . .

USER nodejs
CMD ["node", "server.js"]
```

---

### 4. Host Path Mounts

**Vulnerability**: Mounting sensitive host paths (e.g., `/`, `/etc`, `/var/lib/docker`) exposes host to container.

**Example**:
```bash
# BAD: Mounting root filesystem
docker run -v /:/host-fs alpine

# Container can now access /etc/passwd, /root, etc.
```

**Fix**: Mount only necessary paths with read-only where possible
```bash
# GOOD: Specific path, read-only
docker run -v /data/app:/app/data:ro myapp
```

---

## SECURITY BEST PRACTICES

### 1. Base Image Selection

**Principles**:
- Use official images from trusted sources
- Use minimal images (Alpine, distroless)
- Scan images for vulnerabilities
- Pin to specific tags (not `latest`)

**Examples**:
```dockerfile
# BAD: Latest tag (unpredictable, possible vulnerabilities)
FROM python:latest

# BAD: Large, full OS
FROM ubuntu:latest

# GOOD: Specific version
FROM python:3.11-slim

# GOOD: Alpine (minimal)
FROM python:3.11-alpine

# BEST: Distroless (minimal, secure)
FROM gcr.io/distroless/python3
```

---

### 2. Resource Limits

**Purpose**: Prevent container from consuming all host resources (DoS).

**Example**:
```yaml
# docker-compose.yml
services:
  myapp:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

**Kubernetes**:
```yaml
# deployment.yaml
resources:
  limits:
    cpu: "1000m"
    memory: "512Mi"
  requests:
    cpu: "500m"
    memory: "256Mi"
```

---

### 3. Capabilities Management

**Principle**: Drop all Linux capabilities, only add what's needed.

**Example**:
```bash
# BAD: Default capabilities (many unnecessary)
docker run myapp

# GOOD: Drop all, add only needed
docker run --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add CHOWN \
  myapp
```

**Kubernetes**:
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - NET_BIND_SERVICE
```

---

### 4. Read-Only Filesystem

**Principle**: Make container filesystem read-only to prevent runtime modifications.

**Example**:
```dockerfile
# GOOD: Read-only root filesystem
FROM python:3.11-slim

# Application files are read-only
COPY --chown=appuser:appuser . /app
USER appuser
WORKDIR /app

# Only writable directory
VOLUME /app/tmp

# Read-only root filesystem
CMD ["--read-only", "python", "server.py"]
```

**Kubernetes**:
```yaml
securityContext:
  readOnlyRootFilesystem: true

volumeMounts:
- name: app
  mountPath: /app
  readOnly: true
- name: tmp
  mountPath: /app/tmp
  readOnly: false
```

---

### 5. Secrets Management

**BAD**: Secrets in images or environment variables
```dockerfile
# NEVER DO THIS!
ARG DATABASE_PASSWORD=supersecret123
ENV DATABASE_PASSWORD=$DATABASE_PASSWORD
```

```yaml
# NEVER DO THIS!
environment:
  - DATABASE_PASSWORD=supersecret123
```

**GOOD**: Use secrets management
```dockerfile
# Accept secret via argument (not in layer)
ARG DATABASE_PASSWORD  # Build-time only, not in final image
```

```yaml
# Kubernetes secrets
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  db-password: supersecret123
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:latest
    env:
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db-password
```

---

### 6. Network Isolation

**Example**:
```yaml
# Kubernetes network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-traffic
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80
```

---

## IMAGE SCANNING

### 1. Trivy Scanner

```bash
# Scan image for vulnerabilities
trivy image myapp:latest

# Scan with severity threshold
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan in CI (GitHub Actions)
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
```

### 2. Docker Bench Security

```bash
# Run security checks
docker run --rm --net host --pid host \
  --cap-add audit_control \
  -v /var/lib:/var/lib \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-bench-security

# Score: 0-100 (higher is better)
```

### 3. Clair

```bash
# Analyze image
clair-scanner myapp:latest

# Report includes:
# - CVE vulnerabilities
# - Severity levels
# - Affected packages
```

---

## RUNTIME SECURITY

### 1. Seccomp Profiles

**Restrict system calls container can make**
```bash
# Docker seccomp profile
docker run --security-opt seccomp:seccomp-profile.json myapp

# Kubernetes
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

**Example seccomp-profile.json**:
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "name": "read",
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "name": "write",
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "name": "execve",
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

---

### 2. AppArmor Profiles

**Restrict file access**
```bash
# Docker AppArmor profile
docker run --security-opt apparmor=docker-default myapp

# Custom AppArmor profile
apparmor_parser -r myapp-profile

docker run --security-opt apparmor=myapp-profile myapp
```

**Example AppArmor profile**:
```conf
#include <tunables/global>

profile myapp-profile flags=(attach_disconnected) {
  # Deny access to sensitive files
  deny /etc/shadow r,
  deny /root/** r,
  deny /var/lib/docker/** r,

  # Allow only necessary files
  /app/** r,
  /app/tmp/** rw,
}
```

---

### 3. SELinux

**Enforce mandatory access control**
```bash
# Docker with SELinux
docker run --security-opt label=type:svirt_sandbox_file_t myapp

# Check SELinux status
sestatus

# List SELinux contexts
seinfo -t | grep docker
```

---

## VULNERABILITY MANAGEMENT

### 1. Dependency Scanning

```bash
# npm audit (JavaScript)
npm audit

# composer audit (PHP)
composer audit

# pip-audit (Python)
pip-audit

# Safety (Python)
safety check
```

### 2. CI/CD Integration

```yaml
# GitHub Actions: Security scan
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Run Trivy scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: myapp:${{ github.sha }}
        format: 'sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

---

## CROSS-REFERENCES
- For container patterns: @infrastructure/CONTAINERIZATION.md
- For CI/CD patterns: @infrastructure/CI-CD.md
- For OWASP vulnerabilities: @secops-engineering/owasp/OWASP-TOP10.md
