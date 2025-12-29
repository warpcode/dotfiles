# CONTAINERIZATION

## OVERVIEW
Containerization packages applications with their dependencies into portable, isolated units for consistent deployment across environments.

## DOCKER FUNDAMENTALS

### 1. Multi-Stage Builds

**Purpose**: Minimize image size by excluding build dependencies.

**Before (Single Stage)**:
```dockerfile
# BAD: Includes build tools in final image
FROM php:8.2-cli

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install application dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist

# COPY application
COPY . /app
WORKDIR /app

# RUN composer dump-autoload --optimize
# Build tools remain in final image!
```

**After (Multi-Stage)**:
```dockerfile
# GOOD: Multi-stage build excludes build tools
FROM php:8.2-cli AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist

# Final stage - minimal image
FROM php:8.2-fpm-alpine

WORKDIR /var/www

# Copy only compiled artifacts from builder stage
COPY --from=builder /app /var/www
COPY --from=builder /app/vendor /var/www/vendor

RUN chown -R www-data:www-data /var/www
```

**Result**: Image size reduced from 800MB to 100MB.

---

### 2. Base Image Selection

**Principles**:
- Use official images
- Prefer specific tags (e.g., `8.2-fpm-alpine` not `latest`)
- Alpine Linux for minimal size (smaller security surface)
- Avoid `latest` tag (unpredictable)

**Examples**:
```dockerfile
# BAD: Latest tag (unpredictable)
FROM php:latest

# BAD: Too big (includes unnecessary tools)
FROM ubuntu:latest

# GOOD: Specific version, Alpine (minimal)
FROM php:8.2-fpm-alpine

# GOOD: Debian-based (compatible, larger)
FROM php:8.2-fpm

# GOOD: distroless (minimal, secure)
FROM gcr.io/distroless/php82
```

---

### 3. Layer Caching

**Principle**: Order Dockerfile instructions from least to most frequently changing to maximize caching.

**Before (Poor Caching)**:
```dockerfile
# BAD: Copy application first (changes invalidate all subsequent layers)
COPY . /app
WORKDIR /app

RUN composer install  # Re-runs on every code change!
RUN npm install  # Re-runs on every code change!
```

**After (Optimal Caching)**:
```dockerfile
# GOOD: Copy dependencies first (cached if unchanged)
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install  # Cached if composer.* unchanged

COPY package.json package-lock.json ./
RUN npm install  # Cached if package.* unchanged

# COPY application last
COPY . /app  # This layer invalidated on code change, but above layers cached
```

---

### 4. User Best Practices

**Principle**: Never run containers as root.

**Before (Root User)**:
```dockerfile
# BAD: Running as root
FROM node:18-alpine
WORKDIR /app
COPY . /app
RUN npm install
USER root  # Explicitly root
CMD ["node", "server.js"]
```

**After (Non-Root User)**:
```dockerfile
# GOOD: Running as non-root user
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:18-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

USER nodejs
CMD ["node", "server.js"]
```

---

## DOCKER COMPOSE PATTERNS

### 1. Multi-Environment Configuration

**docker-compose.yml (Base)**:
```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - APP_ENV=${APP_ENV:-development}
      - DB_HOST=db
      - DB_PORT=5432
    depends_on:
      - db
      - redis
    volumes:
      - .:/var/www

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME:-app}
      - POSTGRES_USER=${DB_USER:-app}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-secret}
    volumes:
      - db-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  db-data:
```

**docker-compose.prod.yml (Production overrides)**:
```yaml
version: '3.8'

services:
  app:
    environment:
      - APP_ENV=production
      - LOG_LEVEL=info
    restart: unless-stopped

  db:
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    volumes:
      - ./docker/production/postgresql.conf:/etc/postgresql/postgresql.conf
    secrets:
      - db_password
```

**Usage**:
```bash
# Development
docker-compose up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

### 2. Health Checks

```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

---

### 3. Resource Limits

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## KUBERNETES PATTERNS

### 1. Deployment Manifest

**deployment.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:${IMAGE_TAG}
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "250m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

### 2. Service and Ingress

**service.yaml**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
```

**ingress.yaml**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - app.example.com
    secretName: myapp-tls
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80
```

---

### 3. ConfigMaps and Secrets

**configmap.yaml**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  APP_ENV: production
  LOG_LEVEL: info
  DB_HOST: postgres-service
```

**secret.yaml**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
stringData:
  DB_PASSWORD: supersecret
  API_KEY: secretkey123
```

**Usage in Pod**:
```yaml
env:
- name: APP_ENV
  valueFrom:
    configMapKeyRef:
      name: myapp-config
      key: APP_ENV
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: myapp-secret
      key: DB_PASSWORD
```

---

## SECURITY BEST PRACTICES

### 1. Scan Images
```bash
# Trivy vulnerability scanner
trivy image myapp:latest

# Docker Bench Security
docker run --rm --net host --pid host \
  --cap-add audit_control \
  -v /var/lib:/var/lib \
  -v /var/run/docker.sock:/var/run/docker.sock \
  docker-bench-security

# Clair
clair-scanner myapp:latest
```

### 2. Minimal Base Images
```dockerfile
# Prefer Alpine
FROM php:8.2-fpm-alpine  # ~50MB

# Or distroless (even smaller)
FROM gcr.io/distroless/php82  # ~30MB

# Avoid fat images
FROM ubuntu:latest  # ~100MB+ (includes many unused tools)
```

### 3. Security Scanning in CI
```yaml
jobs:
  security-scan:
    steps:
    - name: Scan for vulnerabilities
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: myapp:${{ github.sha }}
        format: 'sarif'
        severity: 'CRITICAL,HIGH'
```

---

## CROSS-REFERENCES
- For container security: @security/CONTAINER-SECURITY.md
- For CI/CD patterns: @infrastructure/CI-CD.md
- For IaC patterns: @infrastructure/IAC.md
- For release strategies: @release/RELEASE-STRATEGIES.md
