# Docker Compose & Service Topology

Reference guide for designing robust multi-container Docker Compose environments.

---

## 1. Network Isolation & Service Segmentation

Isolate database and cache services from public facing ingress:

```yaml
version: '3.8'

services:
  webserver:
    image: nginx:alpine
    ports:
      - "80:80"
    networks:
      - frontend
    depends_on:
      app:
        condition: service_healthy

  app:
    build: .
    networks:
      - frontend
      - backend
    environment:
      DB_HOST: db
      REDIS_HOST: redis
    healthcheck:
      test: ["CMD", "php-fpm-healthcheck"]
      interval: 10s
      timeout: 5s
      retries: 3

  db:
    image: postgres:16-alpine
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password

networks:
  frontend:
  backend:

volumes:
  db-data:
```

---

## 2. Healthchecks & Startup Dependencies

Avoid race conditions where the web app boots before the database is ready:
- Use `healthcheck` on database / backend services.
- Configure `depends_on` with `condition: service_healthy` instead of simple service names.

---

## 3. Volume Persistence Strategies

- **Named Volumes (`db-data:/path`)**: Used for persistent database engines (Postgres, MySQL, Redis, Elasticsearch). Fast, managed by Docker daemon, and platform-independent.
- **Bind Mounts (`./src:/var/www/html`)**: Used in local development environments for hot-reloading code. Never used for database data directories due to filesystem permission and performance bottlenecks on macOS/Windows.

