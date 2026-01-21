# Mode: Instructions (VS Code Copilot / GitHub Copilot)

## Purpose
Guidelines for creating repository-wide and path-specific instructions that customize GitHub Copilot's code generation behavior in VS Code through `.github/copilot-instructions.md` and conditional `.instructions.md` files.

## Blueprint Structure

### Core Principles

**Instruction = Scope + Context + Conventions + Resources**

Instructions are markdown files that provide Copilot with project-specific context, coding standards, and available resources to generate code aligned with your team's practices.

**Instruction Types**:

| Type | File Location | Scope | Use Case |
|------|--------------|-------|----------|
| **Repository-Wide** | `.github/copilot-instructions.md` | All files | Project overview, global conventions |
| **Path-Specific** | `.github/instructions/*.instructions.md` | Matching globs | Language/framework-specific patterns |
| **Experimental** | `AGENTS.md` | Agent workflows | Multi-step agentic workflows |

### File Structure

```
.github/
├── copilot-instructions.md        # Repository-wide instructions
└── instructions/
    ├── typescript.instructions.md  # Path-specific for TS files
    ├── react.instructions.md       # Path-specific for React
    ├── tests.instructions.md       # Path-specific for test files
    └── api.instructions.md         # Path-specific for API routes
```

**Experimental**: `AGENTS.md` in repository root (agentic workflows)[145]

### Repository-Wide Instructions

**File**: `.github/copilot-instructions.md`

**Purpose**: Provide project overview, structure, global conventions, and available resources to all Copilot interactions.

```markdown
# Project: [Project Name]

## Overview
[1-2 paragraphs describing what the project does, its purpose, and key technologies]

## Project Structure
```
src/
├── components/     # React components (functional, TypeScript)
├── services/       # Business logic and API clients
├── utils/          # Helper functions and utilities
├── types/          # TypeScript type definitions
└── pages/          # Next.js pages or React Router routes
tests/
├── unit/           # Unit tests (Jest)
├── integration/    # Integration tests
└── e2e/            # End-to-end tests (Playwright)
```

## Technology Stack
- **Frontend**: React 18, TypeScript 5, Material-UI 5
- **Backend**: Node.js 20, Express, PostgreSQL 15
- **Testing**: Jest, React Testing Library, Playwright
- **Build**: Vite, ESBuild

## Coding Standards

### TypeScript
- Strict mode enabled (`strict: true` in tsconfig.json)
- No explicit `any` types (use `unknown` or proper types)
- Prefer interfaces over type aliases for object shapes
- Use `const` for immutable bindings, `let` for mutable

### React
- Functional components only (no class components)
- Hooks for state management (`useState`, `useEffect`, `useContext`)
- PropTypes validation using TypeScript interfaces
- Named exports preferred over default exports

### Formatting
- 2 spaces indentation
- Single quotes for strings
- Semicolons required
- 100 character line length
- Run `npm run format` before committing

### Testing
- Test files: `*.test.ts` or `*.spec.ts` co-located with source
- Use React Testing Library for component tests
- Aim for 80%+ code coverage
- Test behavior, not implementation details

## Available Resources

### Scripts (Available for Reference)
- `scripts/start-app.sh`: Installs dependencies and starts development server
- `scripts/test-project.sh`: Runs full test suite (unit + integration + e2e)
- `scripts/build-production.sh`: Production build with optimization
- `scripts/db-migrate.sh`: Run database migrations

### MCP Servers (Model Context Protocol)
- **Playwright Server**: For generating and running e2e tests
- **GitHub Server**: For repository interactions (issues, PRs, commits)
- **Database Server**: For querying schema and running SQL

### Documentation
- `docs/architecture.md`: System architecture and design decisions
- `docs/api-spec.md`: REST API documentation (OpenAPI 3.0)
- `docs/contributing.md`: Contribution guidelines and workflows

## Common Patterns

### API Client
```typescript
// Use axios with interceptors for auth
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.VITE_API_BASE_URL,
  timeout: 10000,
});

apiClient.interceptors.request.use(config => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### Error Handling
```typescript
// Use custom error classes
class APIError extends Error {
  constructor(public statusCode: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}

// Handle errors with try-catch
try {
  const data = await fetchUser(userId);
} catch (error) {
  if (error instanceof APIError) {
    console.error(`API Error ${error.statusCode}: ${error.message}`);
  } else {
    console.error('Unexpected error:', error);
  }
}
```

## Preferences
- Prioritize type safety over brevity
- Include error handling in all network operations
- Add JSDoc comments for complex functions
- Write tests alongside implementation (TDD when appropriate)
```

### Path-Specific Instructions

**File Pattern**: `.github/instructions/*.instructions.md`

**Frontmatter** (required):
```markdown
---
applyTo: "**/*.test.ts, **/*.spec.ts"
---

# [Instructions Title]

[Path-specific guidance]
```

**Field Specifications**:

**applyTo** (required)
- Comma-separated glob patterns
- Determines when these instructions apply
- Standard glob syntax (same as .gitignore)
- Examples:
  - `**/*.ts, **/*.tsx` - All TypeScript files
  - `src/components/**/*.tsx` - React components in src/components/
  - `**/*.{test,spec}.ts` - All test files

### TypeScript Instructions Example

**File**: `.github/instructions/typescript.instructions.md`

```markdown
---
applyTo: "**/*.ts, **/*.tsx"
---

# TypeScript Guidelines

## Type Definitions
- Define all function parameters and return types explicitly
- Use `interface` for object shapes, `type` for unions/intersections
- Export types alongside functions when used as public API

## Strict Typing
- No `any` types - use `unknown` for truly unknown types
- No type assertions (`as Type`) unless absolutely necessary
- Use type guards for narrowing instead of assertions

## Async/Await
- Prefer `async/await` over `.then()` chains
- Always handle errors with try-catch
- Include proper return types: `Promise<Type>`

## Example
```typescript
// ✅ Good
interface User {
  id: string;
  name: string;
  email: string;
}

async function fetchUser(id: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    throw error;
  }
}

// ❌ Avoid
async function fetchUser(id: any): Promise<any> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
```
```

### React Instructions Example

**File**: `.github/instructions/react.instructions.md`

```markdown
---
applyTo: "src/components/**/*.tsx, src/pages/**/*.tsx"
---

# React Component Guidelines

## Component Structure
- Functional components with TypeScript
- Props interface defined above component
- Named exports (not default)
- Co-locate styles with component

## Hooks Usage
- `useState` for local state
- `useEffect` for side effects (cleanup functions required)
- `useContext` for shared state (avoid prop drilling)
- `useMemo`/`useCallback` only when performance profiling shows benefit

## Event Handlers
- Name handlers with `handle` prefix: `handleClick`, `handleSubmit`
- Define handlers inside component (access to props/state)
- Use proper TypeScript event types: `React.MouseEvent<HTMLButtonElement>`

## Example
```typescript
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  onClick: () => void;
  children: React.ReactNode;
  disabled?: boolean;
}

export const Button: React.FC<ButtonProps> = ({ 
  variant = 'primary',
  onClick,
  children,
  disabled = false
}) => {
  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
    onClick();
  };

  return (
    <button
      className={`button button--${variant}`}
      onClick={handleClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
};
```

## Testing
- Include `.test.tsx` file alongside component
- Test rendering, user interactions, edge cases
- Use React Testing Library queries: `getByRole`, `findByText`
```

### Test Instructions Example

**File**: `.github/instructions/tests.instructions.md`

```markdown
---
applyTo: "**/*.test.ts, **/*.spec.ts, tests/**/*"
---

# Testing Guidelines

## Test Structure
- Use `describe` blocks to group related tests
- Use `it` or `test` for individual test cases
- Follow Arrange-Act-Assert pattern

## React Component Tests
- Import from React Testing Library: `render`, `screen`, `fireEvent`, `waitFor`
- Use `getByRole` for accessibility-friendly queries
- Avoid `getByTestId` unless necessary (test behavior, not implementation)

## Async Tests
- Use `async/await` for async operations
- Use `findBy` queries (automatically wait) instead of `waitFor(() => getBy...)`
- Clean up timers, subscriptions in `afterEach`

## Mocking
- Mock external dependencies (API calls, localStorage, etc.)
- Use Jest mocks: `jest.fn()`, `jest.mock()`
- Restore mocks in `afterEach`: `jest.restoreAllMocks()`

## Example
```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

describe('Button', () => {
  it('renders children text', () => {
    render(<Button onClick={jest.fn()}>Click Me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click Me</Button>);
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('disables button when disabled prop is true', () => {
    render(<Button onClick={jest.fn()} disabled>Click Me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## Coverage
- Aim for 80%+ line coverage
- Focus on critical paths and edge cases
- Use `npm run test:coverage` to check coverage
```

### API Routes Instructions Example

**File**: `.github/instructions/api.instructions.md`

```markdown
---
applyTo: "src/pages/api/**/*.ts, src/api/**/*.ts"
---

# API Route Guidelines

## Route Structure (Next.js App Router)
- Export HTTP method handlers: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
- Return `Response` objects with proper status codes
- Include error handling for all routes

## Input Validation
- Validate request body using Zod schemas
- Return 400 Bad Request for validation errors
- Sanitize inputs to prevent injection attacks

## Authentication
- Check auth token in `Authorization` header
- Return 401 Unauthorized if missing/invalid token
- Extract user info from verified token

## Response Format
- JSON responses with consistent structure
- Include `data` and optional `error` fields
- Set appropriate Content-Type headers

## Example
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

// Input validation schema
const CreateUserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

export async function POST(request: NextRequest) {
  try {
    // Authentication
    const token = request.headers.get('Authorization')?.replace('Bearer ', '');
    if (!token) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Verify token and extract user
    const currentUser = await verifyToken(token);
    if (!currentUser) {
      return NextResponse.json(
        { error: 'Invalid token' },
        { status: 401 }
      );
    }

    // Parse and validate input
    const body = await request.json();
    const validatedData = CreateUserSchema.parse(body);

    // Business logic
    const newUser = await createUser(validatedData);

    // Success response
    return NextResponse.json(
      { data: newUser },
      { status: 201 }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('API Error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
```

## Rate Limiting
- Implement rate limiting for public endpoints
- Use Redis or in-memory cache for tracking
- Return 429 Too Many Requests when limit exceeded
```

## Content Best Practices

### Repository-Wide Instructions[22][145][148]

**1. Keep Short and Clear**
- Focus on high-level overview and global conventions
- 200-500 lines maximum
- Avoid detailed implementation examples (use path-specific for those)

**2. Project Context First**
- What the project does (business domain)
- Why certain technologies chosen
- Key architectural decisions

**3. Separate by Module/Folder**
- Use path-specific instructions for detailed patterns
- Repository-wide for global conventions only

**4. Reference External Resources**
- List available scripts and their purposes
- Document MCP servers and their capabilities
- Link to architecture docs and API specs

**5. Enable Instruction Files**
Set in VS Code settings:
```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true
}
```

### Path-Specific Instructions[17][22][25]

**1. Focused Scope**
- Single language, framework, or file type per instruction file
- Specific patterns and conventions for that context
- Concrete examples showing recommended approach

**2. Multiple Instructions Combine**
- When file matches multiple `applyTo` patterns, all instructions apply
- Avoid contradictions (Copilot's choice non-deterministic)
- Design instructions to be complementary, not conflicting

**3. Glob Pattern Precision**
```
# Too Broad (avoid)
applyTo: "**/*"

# Good (specific)
applyTo: "src/components/**/*.tsx"

# Better (very specific)
applyTo: "src/components/**/*.tsx, src/pages/**/*.tsx"
```

**4. Include Complete Examples**
- Show full function/component, not snippets
- Include imports, types, error handling
- Demonstrate best practices in realistic context

**5. Explain "Why"**
- Not just "do this", but "do this because..."
- Rationale helps Copilot understand intent
- Context improves suggestion quality

## Experimental: AGENTS.md[145]

**Status**: Experimental support in VS Code/GitHub Copilot

**File Location**: `AGENTS.md` in repository root (not `.github/`)

**Purpose**: Define multi-step agentic workflows with tool usage

**Format**:
```markdown
# Agent Workflows

## Workflow: [Workflow Name]

### Steps
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]

### Tools
- [Tool 1: purpose]
- [Tool 2: purpose]

### Example
[Full workflow example]
```

**Note**: Check latest GitHub Copilot documentation for AGENTS.md support status and syntax.

## Validation Checklist

- [ ] **Repository-Wide**: `.github/copilot-instructions.md` exists with project overview?
- [ ] **Short and Focused**: Repository-wide under 500 lines?
- [ ] **Path-Specific**: Separate `.instructions.md` files for different contexts?
- [ ] **Glob Patterns**: `applyTo` patterns specific and accurate?
- [ ] **No Conflicts**: Instructions complementary, not contradictory?
- [ ] **Complete Examples**: Full implementations, not snippets?
- [ ] **Rationale Included**: "Why" explained for patterns?
- [ ] **Resources Listed**: Scripts, MCP servers, docs referenced?
- [ ] **Settings Enabled**: `useInstructionFiles` set to true in VS Code?
- [ ] **Testing**: Instructions tested by generating code and verifying alignment?

## Common Pitfalls to Avoid

❌ **Too Long Repository-Wide**: 1000+ line file with all details  
✅ **Concise Overview**: 200-500 lines, details in path-specific

❌ **No Path-Specific**: All instructions in repository-wide  
✅ **Separated by Context**: TypeScript, React, tests each have own file

❌ **Vague Glob Patterns**: `applyTo: "**/*"`  
✅ **Specific Patterns**: `applyTo: "src/components/**/*.tsx"`

❌ **Conflicting Instructions**: Repository-wide says X, path-specific says NOT X  
✅ **Complementary**: Repository-wide has high-level, path-specific has details

❌ **No Examples**: Only text descriptions  
✅ **Complete Code**: Full functions/components with context

❌ **No Rationale**: "Use this pattern"  
✅ **Explained Why**: "Use this pattern because it prevents X and improves Y"

❌ **Outdated**: Instructions reference old frameworks/patterns  
✅ **Maintained**: Regular updates when project conventions change

## Platform-Specific Notes

### GitHub Copilot for VS Code
- **Settings**: `github.copilot.chat.codeGeneration.useInstructionFiles: true`[17]
- **Repository-Wide**: `.github/copilot-instructions.md`[22][25]
- **Path-Specific**: `.github/instructions/*.instructions.md` with `applyTo` frontmatter[25]
- **Priority**: Both repository-wide and matching path-specific instructions combine
- **Visibility**: Copilot uses instructions in chat, inline suggestions, and editing

### GitHub Copilot CLI
- Instructions apply to CLI commands
- Same file structure and format
- Useful for code generation scripts

### Best Practices from GitHub[22]
1. **Be specific and clear**: Precise instructions yield better suggestions
2. **Separate concerns**: Different instruction files for different contexts
3. **Reuse and reference**: Reference other instructions to avoid duplication
4. **Include examples**: Show don't tell - concrete code examples
5. **Reference external resources**: Scripts, MCP servers, documentation

## Example: Complete Instruction Set

### `.github/copilot-instructions.md`
```markdown
# Project: E-Commerce Platform

## Overview
Full-stack e-commerce platform built with Next.js 14 (App Router), TypeScript, and PostgreSQL.
Handles product catalog, shopping cart, checkout, and order management for medium-sized retailers.

## Project Structure
```
src/
├── app/              # Next.js App Router pages and API routes
│   ├── (shop)/       # Public-facing shop pages
│   ├── (admin)/      # Admin dashboard
│   └── api/          # API routes
├── components/       # Shared React components
├── lib/              # Business logic and utilities
│   ├── services/     # API clients and business services
│   ├── db/           # Database client and queries
│   └── utils/        # Helper functions
└── types/            # TypeScript type definitions
```

## Technology Stack
- **Frontend**: Next.js 14, React 18, TypeScript 5, Tailwind CSS, Radix UI
- **Backend**: Next.js API Routes, Prisma ORM, PostgreSQL 15
- **Auth**: NextAuth.js with JWT
- **Payments**: Stripe
- **Testing**: Jest, React Testing Library, Playwright

## Coding Standards

### TypeScript
- Strict mode enabled
- No `any` types
- Prefer interfaces for objects
- Export types alongside implementations

### React/Next.js
- Server Components by default (use 'use client' only when needed)
- Functional components with hooks
- Named exports
- Co-locate tests with components

### Styling
- Tailwind CSS for utility classes
- Radix UI for accessible components
- CSS modules for custom styles
- Dark mode support required

### Database
- Prisma for ORM
- Migrations in `prisma/migrations/`
- Seed data in `prisma/seed.ts`

## Available Resources

### Scripts
- `scripts/dev.sh`: Start development server with database
- `scripts/test.sh`: Run all tests (unit + integration + e2e)
- `scripts/migrate.sh`: Run database migrations
- `scripts/seed.sh`: Seed database with test data

### MCP Servers
- **Stripe MCP**: For payment integration and testing
- **Playwright MCP**: For generating e2e tests

### Documentation
- `docs/architecture.md`: System design and data flow
- `docs/api.md`: REST API documentation
- `docs/database.md`: Database schema and relationships

## Common Patterns

### Database Access
```typescript
import { prisma } from '@/lib/db/client';

// Always use try-catch for database operations
async function getProduct(id: string) {
  try {
    const product = await prisma.product.findUnique({
      where: { id },
      include: { category: true, images: true },
    });
    return product;
  } catch (error) {
    console.error('Database error:', error);
    throw new Error('Failed to fetch product');
  }
}
```

### API Response Format
```typescript
// Success
{ data: { ... }, error: null }

// Error
{ data: null, error: { message: "...", code: "ERROR_CODE" } }
```

## Preferences
- Prioritize server-side rendering (use Server Components)
- Include loading and error states for all async operations
- Add proper error boundaries
- Write tests for business logic and critical paths
```

### `.github/instructions/react-components.instructions.md`
```markdown
---
applyTo: "src/components/**/*.tsx, src/app/**/*.tsx"
---

# React Component Guidelines

## Server vs Client Components
- Default to Server Components (no 'use client')
- Add 'use client' only when needed: hooks, event handlers, browser APIs
- Fetch data in Server Components, pass to Client Components as props

## Component Structure
```typescript
// Server Component (default)
interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  return (
    <div className="card">
      <h3>{product.name}</h3>
      <p>{product.price}</p>
    </div>
  );
}

// Client Component (when interactivity needed)
'use client';

interface AddToCartButtonProps {
  productId: string;
}

export function AddToCartButton({ productId }: AddToCartButtonProps) {
  const [loading, setLoading] = useState(false);

  async function handleClick() {
    setLoading(true);
    try {
      await addToCart(productId);
    } catch (error) {
      console.error('Failed to add to cart:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <button onClick={handleClick} disabled={loading}>
      {loading ? 'Adding...' : 'Add to Cart'}
    </button>
  );
}
```

## Styling with Tailwind
- Use utility classes for layout and spacing
- Use Radix UI for interactive components
- Add dark mode variants: `dark:bg-gray-800`

## Accessibility
- Use semantic HTML: `<button>` not `<div onClick>`
- Include ARIA labels for icon buttons
- Ensure keyboard navigation works
- Test with screen readers
```

### `.github/instructions/api-routes.instructions.md`
```markdown
---
applyTo: "src/app/api/**/*.ts"
---

# API Routes Guidelines

## Next.js 14 App Router Format
```typescript
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import { auth } from '@/lib/auth';
import { prisma } from '@/lib/db/client';

// Input validation
const CreateProductSchema = z.object({
  name: z.string().min(1).max(200),
  price: z.number().positive(),
  categoryId: z.string().uuid(),
});

// Route handler
export async function POST(request: NextRequest) {
  try {
    // Auth check
    const session = await auth();
    if (!session?.user) {
      return NextResponse.json(
        { data: null, error: { message: 'Unauthorized', code: 'AUTH_REQUIRED' } },
        { status: 401 }
      );
    }

    // Validate input
    const body = await request.json();
    const validatedData = CreateProductSchema.parse(body);

    // Business logic
    const product = await prisma.product.create({
      data: {
        ...validatedData,
        userId: session.user.id,
      },
    });

    // Success response
    return NextResponse.json(
      { data: product, error: null },
      { status: 201 }
    );
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        {
          data: null,
          error: {
            message: 'Validation failed',
            code: 'VALIDATION_ERROR',
            details: error.errors,
          },
        },
        { status: 400 }
      );
    }

    console.error('API Error:', error);
    return NextResponse.json(
      { data: null, error: { message: 'Internal server error', code: 'INTERNAL_ERROR' } },
      { status: 500 }
    );
  }
}
```

## Required Patterns
- Validate all inputs with Zod schemas
- Check authentication for protected routes
- Use try-catch for error handling
- Return consistent response format
- Log errors for debugging
```

## Token Optimization

### ✅ Safe to Optimize
- Remove duplicate examples across instruction files
- Shorten overly verbose descriptions
- Consolidate similar patterns
- Reference external docs instead of embedding

### ❌ Never Optimize Away
- Project structure overview
- Technology stack list
- Complete code examples
- Rationale explanations
- Available resources (scripts, MCP servers)
- Path-specific glob patterns

## References

This mode incorporates best practices from:
- GitHub Copilot documentation[17][22][25]
- VS Code custom instructions[17][26]
- GitHub best practices guide[22]
- Community patterns[20][145][148]
