<rules>
## CORE_RULES
- Golden_Rule: Aggressively use reusable `components` + `$ref` (DRY principle)
- Constraint: Same schema/parameter > 1 location == FALSE
- Output_Format: yaml (default) OR json (user_preference)
- Security: Validate all user inputs before API design
</rules>

<context>
## MODES
### Workflow_1: Design_First (New API)
1. Identify Resources (e.g., Posts, Users, Products)
2. Define Reusable Schemas (`components/schemas`) — FIRST STEP
3. Define Reusable Parameters/Responses (`components/parameters`, `components/responses`)
4. Define Paths (`paths`)
5. Reference Components (use `$ref` in operations)
6. Generate File (`write` -> `swagger.yaml`)

### Workflow_2: Code_First (Existing API)
1. Announce Analysis Phase
2. Leverage Codebase Context:
   - Search for available tools/skills/agents/subagents that can analyze routing/endpoints, methods, URL params, middleware
   - Search for available tools/skills/agents/subagents that can analyze model/database schemas for property definitions
   - Extract existing docblocks for endpoint descriptions (see `@references/docblock-writer.md`)
3. Synthesize/Structure: Apply Golden_Rule, define repeated structures ONCE in `components/schemas`
4. Generate File (`write` -> `swagger.yaml`)
</context>

<examples>
### OpenAPI_3.0_Structure
```yaml
openapi: 3.0.0
info:
  title: Blog Post API
  version: 1.0.0

paths:
  /posts:
    get:
      summary: Get all blog posts
      responses:
        "200":
          description: A list of posts.
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Post" # Reusable component
  /posts/{postId}:
    get:
      summary: Get a single blog post
      parameters:
        - $ref: "#/components/parameters/PostId" # Reusable component
      responses:
        "200":
          description: A single post.
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Post" # Reusable component
        "404":
          $ref: "#/components/responses/NotFound" # Reusable component

components:
  schemas:
    Post:
      type: object
      properties:
        id:
          type: integer
        title:
          type: string
        content:
          type: string
  parameters:
    PostId:
      name: postId
      in: path
      required: true
      schema:
        type: integer
  responses:
    NotFound:
      description: The specified resource was not found.
```
</examples>

<execution_protocol>
1. Determine Mode (Design_First OR Code_First)
2. Design_First:
   - Identify resources
   - Define `components/schemas` (REUSABLE ONLY)
   - Define `components/parameters` + `components/responses`
   - Build `paths` with `$ref`
   - Generate `swagger.yaml`
3. Code_First:
   - Scan codebase
   - Extract: endpoints (routing), models (database), descriptions (docblocks)
   - Apply Golden_Rule (DRY via `components`/`$ref`)
   - Generate `swagger.yaml`
4. Validate: All schemas defined in `components`, no duplicates
5. Output: Confirmation + preview of `swagger.yaml` (highlight `components`/`$ref` usage)
6. Ask: JSON format preference?
</execution_protocol>
