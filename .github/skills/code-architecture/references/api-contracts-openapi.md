# OpenAPI & API Contract Synchronization

Reference guide for locating, auditing, and synchronizing HTTP routes and controller implementations with OpenAPI / Swagger specifications to prevent contract drift and breaking changes.

---

## 1. OpenAPI Specification Discovery

Locate API contract manifests and generation tooling across the codebase:

| Contract Type / Tooling | File / Directory Locations | Generation Mechanism |
|---|---|---|
| **Static OpenAPI / Swagger Specs** | `openapi.yaml`, `openapi.json`, `docs/api/`, `swagger/` | Manually authored or exported YAML/JSON specifications |
| **Code-First / Annotation Specs** | `app/Http/Controllers/`, `src/routes/` | Annotations & decorators (`@OA\...`, `tsoa`, `swagger-jsdoc`, `utoipa`) |
| **Schema Reflection Tools** | `routes/api.php`, `fastapi`, `drf-spectacular` | Framework reflection (`php artisan l5-swagger:generate`, FastAPI `/openapi.json`) |

---

## 2. Contract Drift Detection Checklist

Audit routes, controllers, and validation rules against API specifications across these dimensions:

1. **Path & Route Parameter Parity**:
   - Verify URL path templates match OpenAPI paths (e.g., `/api/v1/users/{id}` vs `/api/v1/users/{userId}`).
   - Verify parameter types and formats (e.g., integer ID vs UUID string, path parameter regex constraints).
2. **Query Parameters**:
   - Compare supported query filters, sorting parameters, and pagination flags (`page`, `per_page`, `limit`, `sort`) between controller request validation and OpenAPI parameter definitions.
   - Verify required vs optional flags and default fallback values.
3. **Request Body Schemas**:
   - Compare validation schemas (Form Requests, Zod, Joi, Pydantic, class-validator) against OpenAPI request body definitions.
   - Audit required field constraints, nested object structures, array element types, and allowed enum values.
4. **Response Status Codes & Payload Schemas**:
   - Verify documented HTTP status codes (`200 OK`, `201 Created`, `204 No Content`, `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`).
   - Audit response JSON envelopes, resource transformers (API resources, DTOs, serializers), and error payload structures against OpenAPI response schemas.

---

## 3. Undocumented Route Detection

Identify API endpoints that exist in route manifests but lack corresponding documentation in OpenAPI specs:

1. **Route Manifest vs Spec Comparison**:
   - Extract registered API route paths and HTTP verbs from route manifests (`php artisan route:list --path=api`, Express router stack, FastAPI route table).
   - Diff active endpoints against all paths defined under `paths` in the OpenAPI spec.
2. **Internal vs Public API Boundaries**:
   - Classify undocumented routes: internal/private admin endpoints, legacy routes scheduled for deprecation, or newly added public endpoints missing documentation.
3. **Tagging & Grouping**:
   - Ensure documented endpoints are categorized under correct API tags/groups matching domain modules.

---

## 4. Breaking API Schema Change Detection

Flag regressions and breaking changes during API evolution:

1. **Removed or Renamed Endpoints**:
   - Deletion of existing paths or HTTP methods without deprecation notices (`deprecated: true`) or version bumps.
2. **Tightened Request Contracts**:
   - Adding new mandatory request body properties or required query parameters without backwards-compatible defaults.
   - Restricting accepted data types, formats, or regex constraints.
3. **Weakened Response Contracts**:
   - Removing response properties or renaming JSON keys.
   - Changing property nullability (making non-nullable fields nullable or vice versa).
   - Changing status codes (e.g., returning `200 OK` with an error payload instead of `4xx`/`5xx`).
