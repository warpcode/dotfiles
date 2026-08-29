# Route Discovery & Controller Mapping

Reference guide for locating, cataloging, and auditing application HTTP routes, handlers, and middleware pipelines.

---

## 1. Route Manifest Locations by Ecosystem

| Framework | Default Route Files | CLI Route Lister |
|---|---|---|
| **Laravel (PHP)** | `routes/web.php`, `routes/api.php`, `routes/console.php` | `php artisan route:list` |
| **Express / Fastify (Node)** | `src/routes/`, `src/app.ts`, `server.ts` | Source inspection / AST |
| **Next.js / Nuxt** | `app/api/**/route.ts`, `pages/api/**`, `server/api/**` | File-system routing tree |
| **Django / FastAPI (Python)** | `urls.py`, `app/routers/` | `python manage.py show_urls` |
| **Gin / Echo (Go)** | `cmd/server/main.go`, `internal/router/` | Source inspection |

---

## 2. Route & Middleware Audit Checklist

1. **Authentication Gates**:
   - Verify every non-public route is protected by authentication middleware (e.g. `auth:sanctum`, `passport`, `jwt`, `session`).
2. **Rate Limiting (Throttling)**:
   - Ensure public APIs and authentication endpoints (`/login`, `/register`, `/password/reset`) enforce rate limiters (e.g. `throttle:60,1`).
3. **Parameter Validation**:
   - Ensure route parameters (e.g., `{id}`, `{uuid}`) are validated with regex constraints where supported (e.g., `whereUuid('id')`).
4. **Thin Controllers**:
   - Controllers should only orchestrate: validate input → call application/domain service → return formatted response.
   - Avoid placing multi-step business logic, third-party API calls, or heavy queries directly inside controller methods.

