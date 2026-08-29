# Dockerfile Best Practices & Hardening

Reference guide for authoring high-performance, secure, and lean Docker container images.

---

## 1. Multi-Stage Build Pattern

Always separate heavy build toolchains (compilers, npm build dependencies, dev headers) from the final production runtime image.

### Production Example (Go / Node / PHP)
```dockerfile
# Stage 1: Build & Compile
FROM node:20-alpine AS frontend-builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Lean Runtime
FROM php:8.3-fpm-alpine
WORKDIR /var/www/html

# Install only production runtime extensions
RUN docker-php-ext-install pdo pdo_mysql opcache

# Copy built assets from builder stage
COPY --from=frontend-builder /app/public/build ./public/build
COPY . .

# Run as non-root user
USER www-data

EXPOSE 9000
CMD ["php-fpm"]
```

---

## 2. Layer Caching Hygiene

Docker evaluates cache layer-by-layer. Order instructions from least frequently changing to most frequently changing:

1. **Base Image & System OS Packages** (`RUN apk add ...` / `RUN apt-get ...`)
2. **Dependency Manifests** (`COPY composer.json composer.lock ./`)
3. **Dependency Installation** (`RUN composer install --no-dev --optimize-autoloader`)
4. **Application Source Code** (`COPY . .`)

---

## 3. `.dockerignore` Essentials

Ensure `.dockerignore` excludes unnecessary files to keep the build context small and protect secrets:
```text
.git
.github
.env*
!*.example
node_modules
vendor
tests
coverage
*.md
```

---

## 4. Security Hardening Checklist

- **Never Run as Root**: Add `USER appuser` or use built-in unprivileged users (`node`, `www-data`).
- **Pin Base Image Versions**: Use explicit tags (e.g. `python:3.12-slim-bookworm` or SHA256 digests) rather than `:latest`.
- **Clean Package Manager Caches**: Remove apt lists or apk caches in the same `RUN` step (`rm -rf /var/lib/apt/lists/*` or `apk add --no-cache`).
- **Healthchecks**: Include a `HEALTHCHECK` directive so container orchestrators can monitor availability.

