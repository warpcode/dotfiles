# Mode: Rules

## Purpose
Guidelines for creating context-aware coding conventions and project-specific instructions in Cursor IDE using .cursorrules files that guide AI behavior based on file patterns, descriptions, or always-apply settings.

## Blueprint Structure

### Core Principles

**Rule = Trigger + Instructions + Examples + Rationale**

Rules are project-specific guidelines that Cursor AI applies automatically based on glob patterns, AI discovery via description, or always-apply settings to ensure consistent code generation aligned with project conventions.

**Rule Types**:

| Type | Trigger Mechanism | Visibility | Use Case |
|------|------------------|------------|----------|
| **Always Apply** | `alwaysApply: true` | Slash menu | Global conventions (code style, naming) |
| **Apply Intelligently** | `description:` field (and `alwaysApply: false`) | Slash menu | Context-dependent (API patterns, DB) |
| **Apply to Specific Files** | `globs: pattern` | Slash menu | File-specific patterns (React, tests) |
| **Manual Only** | No globs/alwaysApply | Slash menu | On-demand reference (@rule-name) |

### File Structure

**Location**: `.cursor/rules/` in project root

**Format**: `.mdc` (Markdown with frontmatter) - recommended  
**Also Supported**: `.md` (Markdown)

```
.cursor/
└── rules/
    ├── 01-global-conventions.mdc      # Always apply
    ├── 02-typescript-patterns.mdc     # Glob: **/*.ts
    ├── 03-react-components.mdc        # Glob: **/*.tsx
    ├── 04-testing-standards.mdc       # Glob: **/*.test.*
    ├── tasks/
    │   ├── api-integration.mdc        # AI discovery
    │   └── database-queries.mdc       # AI discovery
    └── deprecated/
        └── old-patterns.mdc           # Manual reference only
```

**Numbering**: Use prefixes (01-, 02-) for sort order visibility[3][132][144].

### File Format: MDC (Markdown + Frontmatter)

```markdown
---
description: [topic: details] format for AI discovery
globs: **/*.ts, **/*.tsx
alwaysApply: false
---

# Rule Title

[Main rule content with instructions, examples, rationale]
```

**CRITICAL**: Frontmatter is **NOT strict YAML**. Special parsing rules apply[142][147][150]:

- **description**: Can use `topic: details` format (colon in value)
- **globs**: Comma-separated, NO brackets, NO quotes
- **alwaysApply**: `true` | `false` (lowercase)

**Valid Frontmatter**:
```markdown
---
description: TypeScript: Strict typing conventions and patterns
globs: **/*.ts, **/*.tsx, **/*.test.ts
alwaysApply: false
---
```

**Invalid Frontmatter** (will not parse):
```markdown
---
description: "TypeScript conventions"  # ❌ Quotes break parsing
globs: ["**/*.ts", "**/*.tsx"]          # ❌ Array syntax not supported
alwaysApply: True                       # ❌ Must be lowercase: true
---
```

### Frontmatter Field Specifications

**description** (optional, critical for AI discovery)
- Format: `topic: specific details` works best
- Purpose: AI uses this to determine rule relevance
- Discovery: Empty globs + good description = AI decides when to apply
- Example: `React Components: Functional components with hooks and TypeScript`
- Length: 1-2 sentences, specific and keyword-rich

**globs** (optional, file pattern matching)
- Format: Comma-separated glob patterns (NO brackets, NO quotes)
- Syntax: Standard glob patterns
  - `**/*.ts` - All TypeScript files recursively
  - `src/**/*.tsx` - All TSX files in src/ recursively
  - `**/*{.test,.spec}.ts` - All test files
  - `**/*` - All files (prefer alwaysApply instead)
- Multiple patterns: `**/*.ts, **/*.tsx, **/*.d.ts`
- When matched: Rule automatically applies to matching files

**alwaysApply** (optional, boolean)
- Values: `true` | `false` (lowercase only)
- `true`: Rule always included in AI context (global conventions)
- `false` or omitted: Rule applies based on globs or AI discovery
- Use sparingly: Only for truly global conventions (naming, formatting)

**Priority**: `alwaysApply: true` > `Apply to Specific Files` > `Apply Intelligently`

### Content Structure

```markdown
# High-Level Overview (2-3 sentences)

[What this rule covers, why it exists, when it applies]

## Core Principles

- **Principle 1**: [Statement with reasoning]
- **Principle 2**: [Statement with reasoning]
- **Principle 3**: [Statement with reasoning]

## Pattern: [Pattern Name]

### ✅ Recommended Approach

```[language]
// Complete, real-world implementation showing GOOD pattern
// Include meaningful variable names, realistic context
// Show full component/function, not just snippets
```

**Why This Works**:
- [Reason 1: Technical benefit]
- [Reason 2: Maintainability benefit]
- [Reason 3: Performance/scalability consideration]

### ❌ Deprecated Pattern (Avoid)

```[language]
// Complete example showing OUTDATED or PROBLEMATIC pattern
// Same context as recommended approach for direct comparison
```

**Why Deprecated**:
- [Problem 1: Technical issue]
- [Problem 2: Maintenance burden]
- [Problem 3: Performance/security concern]

**Migration Path**:
- [Step 1: How to refactor from deprecated to recommended]
- [Step 2: What to watch out for]

## Pattern: [Another Pattern Name]

[Repeat structure: Recommended → Deprecated → Why → Migration]

## Edge Cases

### Edge Case 1: [Scenario]
**Solution**: [How to handle this specific case]
**Example**:
```[language]
[Code showing edge case handling]
```

### Edge Case 2: [Scenario]
...

## Integration Points

### With [System/Library Name]
- [How this pattern integrates]
- [Special considerations]
- [Common pitfalls]

## Testing Requirements

- [What must be tested when following this pattern]
- [Test structure and organization]
- [Coverage expectations]

## References

- [Internal doc link: project-conventions.md]
- [External resource: Official documentation URL]
- [Related rules: @another-rule-name]
```

### Content Best Practices

#### High-Level First, Details Later
Start with 2-3 sentence overview before diving into specifics[3][132]:

**Good**:
```markdown
# React Component Patterns

Use functional components with TypeScript, hooks for state management, and prop validation. 
Avoid class components and inline styles. 
Follow Material-UI theming conventions for styling.
```

**Bad** (too detailed upfront):
```markdown
# React Component Patterns

Components must use React.FC type annotation with explicit props interface...
[Immediately jumps into technical details without context]
```

#### Complete Real-World Examples, Not Snippets
Show full implementations, not fragments[3][132]:

**Good**:
```typescript
// ✅ Recommended: Functional component with hooks
interface UserCardProps {
  userId: string;
  onUpdate: (user: User) => void;
}

export const UserCard: React.FC<UserCardProps> = ({ userId, onUpdate }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUser(userId).then(data => {
      setUser(data);
      setLoading(false);
    });
  }, [userId]);

  if (loading) return <Spinner />;
  if (!user) return <Error message="User not found" />;

  return (
    <Card>
      <Avatar src={user.avatar} />
      <Typography>{user.name}</Typography>
      <Button onClick={() => onUpdate(user)}>Edit</Button>
    </Card>
  );
};
```

**Bad** (incomplete snippet):
```typescript
// ✅ Use functional components
export const UserCard = ({ userId }) => {
  // ... implementation
};
```

#### Explicit Deprecated Patterns with Alternatives
Always show what NOT to do and why[3][132]:

**Good**:
```typescript
// ❌ Deprecated: Class components
class UserCard extends React.Component<UserCardProps, UserCardState> {
  componentDidMount() {
    this.fetchUser();
  }
  // ... rest of class implementation
}

// Why Deprecated:
// - More verbose than functional components
// - Hooks provide cleaner state/effect management
// - Harder to test and reason about lifecycle
// - React team recommends functional components

// Migration Path:
// 1. Convert class to function
// 2. Replace componentDidMount with useEffect
// 3. Replace this.state with useState
// 4. Replace this.props access with destructured props
```

#### Explain "Why" Behind Patterns
Don't just state rules, explain reasoning[3][132]:

**Good**:
```markdown
## Use const for immutable bindings

**Rationale**:
- Prevents accidental reassignment bugs
- Signals intent to readers (this value won't change)
- Enables compiler optimizations
- Aligns with functional programming principles
```

**Bad**:
```markdown
## Use const for immutable bindings

Always use const instead of let.
```

#### Organize by Category/Feature
Group related patterns logically[3][132][144]:

```markdown
# React Component Patterns

## State Management
[Patterns for useState, useReducer, context]

## Side Effects
[Patterns for useEffect, useLayoutEffect, cleanup]

## Performance
[Patterns for useMemo, useCallback, React.memo]

## Styling
[Patterns for styled-components, CSS modules, theming]
```

### Optional Sections

#### Framework-Specific Patterns
```markdown
## Next.js Specific

### Server Components (App Router)
[When to use Server Components vs Client Components]

### Data Fetching
[fetch in Server Components, SWR in Client Components]

### Routing
[File-based routing conventions, dynamic routes, route groups]
```

#### Performance Guidelines
```markdown
## Performance Considerations

### Bundle Size
- Lazy load heavy components: `const Heavy = lazy(() => import('./Heavy'))`
- Use dynamic imports for conditional features
- Avoid importing entire libraries: `import { debounce } from 'lodash'` → `import debounce from 'lodash/debounce'`

### Rendering Optimization
- Memoize expensive calculations with useMemo
- Prevent unnecessary re-renders with React.memo
- Use useCallback for functions passed as props
```

#### Security Requirements
```markdown
## Security Patterns

### Input Validation
- Always validate user input on server side
- Use Zod or Yup for schema validation
- Sanitize HTML content: `DOMPurify.sanitize(userContent)`

### Authentication
- Store tokens in httpOnly cookies (not localStorage)
- Implement CSRF protection for state-changing operations
- Use refresh tokens for long-lived sessions
```

## Rule Type Decision Matrix

### When to Use alwaysApply: true
**Criteria**:
- Rule applies to ALL code in project (naming conventions, formatting)
- Rarely needs exceptions
- Fundamental to project identity

**Examples**:
- Global naming conventions (PascalCase components, camelCase functions)
- Code formatting (tabs vs spaces, line length)
- Import ordering and organization
- File structure conventions

**Template**:
```markdown
---
description: Global: Project-wide naming and formatting conventions
alwaysApply: true
---

# Global Code Conventions

## Naming
- Components: PascalCase (Button, UserProfile)
- Functions/variables: camelCase (fetchUser, isLoading)
- Constants: UPPER_SNAKE_CASE (API_BASE_URL)
- Files: kebab-case (user-profile.tsx, api-client.ts)

## Formatting
- Indentation: 2 spaces
- Line length: 100 characters
- Semicolons: Required
- Quotes: Single quotes for strings
```

### When to Use Apply to Specific Files (globs Patterns)
**Criteria**:
- Rule applies to specific file types or locations
- File extension or path determines applicability

**Examples**:
- TypeScript conventions: `globs: **/*.ts, **/*.tsx`
- React components: `globs: src/components/**/*.tsx`
- Test files: `globs: **/*.test.ts, **/*.spec.ts`
- API routes: `globs: src/pages/api/**/*.ts`

**Template**:
```markdown
---
description: TypeScript: Strict typing and linting conventions
globs: **/*.ts, **/*.tsx, **/*.test.ts
alwaysApply: false
---

# TypeScript Conventions

## Strict Typing
- Enable strict mode in tsconfig.json
- No explicit any (use unknown or proper type)
- No type assertions unless necessary (use type guards)

[Full patterns...]
```

### When to Use Apply Intelligently (description only)
**Criteria**:
- Rule relevance depends on context, not file type
- AI should decide when applicable based on task

**Examples**:
- API integration patterns (relevant when working with external APIs)
- Database query patterns (relevant when writing SQL/ORM code)
- State management (relevant when managing complex state)

**Template**:
```markdown
---
description: API Integration: Patterns for REST API clients, error handling, retry logic
globs:
alwaysApply: false
---

# API Integration Patterns

[Instructions that apply when user is working with APIs, regardless of file type]
```

### When to Use Manual Only (no globs, no alwaysApply)
**Criteria**:
- Reference material, not automatic enforcement
- Invoked explicitly via @mention
- Complex workflows needing manual triggering

**Examples**:
- Migration guides (old pattern → new pattern)
- Troubleshooting procedures
- Architecture decision records

**Template**:
```markdown
---
description: Reference: Migration guide from Redux to Zustand
---

# Redux to Zustand Migration Guide

[Detailed migration steps, available when explicitly referenced: @redux-migration]
```

## Validation Checklist

- [ ] **Frontmatter Valid**: No quotes on globs, lowercase true/false, correct format?
- [ ] **Description Specific**: If using AI discovery, description has keywords?
- [ ] **Globs Correct**: Patterns match intended files? Test with glob tester?
- [ ] **Complete Examples**: Full implementations, not snippets?
- [ ] **Deprecated Marked**: Old patterns explicitly shown with alternatives?
- [ ] **Rationale Included**: "Why" explained for each pattern?
- [ ] **Edge Cases**: Unusual scenarios documented?
- [ ] **Organization**: Grouped by feature/category logically?
- [ ] **High-Level First**: Overview before details?
- [ ] **Testing Covered**: How to test code following these patterns?

## Common Pitfalls to Avoid

❌ **Strict YAML in Frontmatter**: `globs: ["**/*.ts"]` (won't parse)  
✅ **Special Format**: `globs: **/*.ts, **/*.tsx` (no quotes, no brackets)

❌ **Vague Description**: "React patterns"  
✅ **Specific Keywords**: "React Components: Functional components with hooks and TypeScript"

❌ **Snippets Instead of Complete Code**: `export const Component = () => { ... }`  
✅ **Full Implementation**: Complete component with imports, types, logic, return

❌ **No Deprecated Patterns**: Only shows recommended approach  
✅ **Explicit Anti-Patterns**: Shows what to avoid, why, and migration path

❌ **Missing Rationale**: "Use const instead of let"  
✅ **Explained Why**: "Use const to prevent reassignment, signal immutability, enable optimizations"

❌ **Flat Organization**: All patterns in one long list  
✅ **Categorized**: Grouped by feature (State, Effects, Performance, Styling)

❌ **Too Many alwaysApply**: Every rule has alwaysApply: true  
✅ **Selective**: Only truly global conventions (naming, formatting)

❌ **No Edge Cases**: Only happy path examples  
✅ **Edge Cases**: Null handling, empty arrays, error states, loading states

## Glob Pattern Reference

```bash
*                    # Any file in current directory
**/*                 # All files recursively
*.ts                 # All .ts files in current directory
**/*.ts              # All .ts files recursively
src/**/*.ts          # All .ts in src/ recursively
**/*.{ts,tsx}        # All .ts and .tsx files recursively
**/*{.test,.spec}.ts # All .test.ts and .spec.ts files
src/components/**    # All files in src/components/
!**/*.test.ts        # Exclude test files (negative pattern)
```

**Testing Globs**: Use [globtester.com](https://globtester.com) or similar to verify patterns.

## Platform-Specific Notes

### Cursor IDE Rules
- **Location**: `.cursor/rules/` (project root)
- **Format**: `.mdc` preferred (frontmatter + markdown), `.md` supported
- **Frontmatter**: Special parsing (not strict YAML)[142][147][150]
- **Discovery**: Visible in slash menu when matching globs or description
- **Manual Invocation**: Use @rule-name to explicitly reference

### MDC vs MD Files
- **MDC**: Markdown with frontmatter support
- **MD**: Regular markdown (may have limited frontmatter support)
- **Recommendation**: Use .mdc for consistency[142][147]

### Rule Priority and Conflicts
When multiple rules apply:
- All matching rules are combined
- Later rules don't override earlier ones
- AI synthesizes guidance from all applicable rules
- Contradictions: AI's choice non-deterministic (avoid conflicts)

## Example: Complete Rule File

```markdown
---
description: React Components: Functional components with TypeScript, hooks, and Material-UI styling
globs: src/components/**/*.tsx, src/pages/**/*.tsx
alwaysApply: false
---

# React Component Patterns

Functional components using TypeScript, React hooks for state management, and Material-UI for styling. 
Avoid class components, inline styles, and prop drilling beyond 2 levels.
Follow project conventions for component structure and organization.

## Core Principles

- **Functional Over Class**: Use functional components with hooks (useState, useEffect, useContext)
- **TypeScript Typing**: Full type safety with Props interfaces, no any types
- **Composition**: Build complex UIs from simple, reusable components
- **Material-UI Theming**: Use theme-aware styling, avoid hardcoded colors

## Pattern: Functional Component with Hooks

### ✅ Recommended Approach

```typescript
import { useState, useEffect } from 'react';
import { Card, Typography, Button, CircularProgress } from '@mui/material';
import { styled } from '@mui/material/styles';

// Theme-aware styling
const StyledCard = styled(Card)(({ theme }) => ({
  padding: theme.spacing(3),
  margin: theme.spacing(2, 0),
  backgroundColor: theme.palette.background.paper,
}));

// Full TypeScript interface
interface UserCardProps {
  userId: string;
  onUpdate: (user: User) => void;
  showActions?: boolean;
}

// Named export, React.FC type
export const UserCard: React.FC<UserCardProps> = ({ 
  userId, 
  onUpdate, 
  showActions = true 
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    fetchUser(userId)
      .then(data => {
        if (isMounted) {
          setUser(data);
          setLoading(false);
        }
      })
      .catch(err => {
        if (isMounted) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => {
      isMounted = false; // Cleanup to prevent state updates on unmounted component
    };
  }, [userId]);

  if (loading) return <CircularProgress />;
  if (error) return <Typography color="error">{error}</Typography>;
  if (!user) return <Typography>User not found</Typography>;

  return (
    <StyledCard>
      <Typography variant="h6">{user.name}</Typography>
      <Typography variant="body2" color="text.secondary">
        {user.email}
      </Typography>
      {showActions && (
        <Button 
          variant="contained" 
          onClick={() => onUpdate(user)}
          sx={{ mt: 2 }}
        >
          Edit User
        </Button>
      )}
    </StyledCard>
  );
};
```

**Why This Works**:
- **Clean Lifecycle**: useEffect handles mounting, updates, and cleanup properly
- **Type Safety**: Props interface prevents type errors, enables IntelliSense
- **Composition**: Single responsibility (display user), actions via callbacks
- **Theming**: styled() uses theme values, respects dark/light mode automatically
- **Error Handling**: Graceful degradation for loading, error, and empty states
- **Memory Safe**: Cleanup function prevents state updates after unmount

### ❌ Deprecated Pattern (Avoid)

```typescript
import React from 'react';

// Class component (deprecated)
class UserCard extends React.Component<UserCardProps, UserCardState> {
  state = {
    user: null,
    loading: true,
    error: null,
  };

  componentDidMount() {
    this.fetchUser();
  }

  componentDidUpdate(prevProps: UserCardProps) {
    if (prevProps.userId !== this.props.userId) {
      this.fetchUser();
    }
  }

  fetchUser = async () => {
    try {
      const data = await fetchUser(this.props.userId);
      this.setState({ user: data, loading: false });
    } catch (err) {
      this.setState({ error: err.message, loading: false });
    }
  };

  render() {
    const { loading, error, user } = this.state;
    
    if (loading) return <div>Loading...</div>;
    if (error) return <div style={{ color: 'red' }}>{error}</div>;
    
    return (
      <div style={{ padding: '16px', border: '1px solid #ccc' }}>
        <h3>{user.name}</h3>
        <p>{user.email}</p>
        <button onClick={() => this.props.onUpdate(user)}>Edit</button>
      </div>
    );
  }
}
```

**Why Deprecated**:
- **Verbose Lifecycle**: componentDidMount, componentDidUpdate harder to reason about than useEffect
- **this Binding**: Need to bind methods or use arrow functions, confusing for new developers
- **Testing Complexity**: Harder to test lifecycle methods compared to hooks
- **Inline Styles**: Hardcoded colors don't respect theme, no dark mode support
- **HTML Elements**: Using div/button instead of Material-UI components
- **React Team Recommendation**: Functional components are the future, better ecosystem support

**Migration Path**:
1. Convert class to function: `class UserCard extends Component` → `export const UserCard: React.FC<Props> =`
2. Replace state with useState: `this.state = { ... }` → `const [user, setUser] = useState(...)`
3. Replace componentDidMount/Update with useEffect: Single useEffect with userId dependency
4. Remove this.props: Destructure props directly from function parameter
5. Replace inline styles: Use Material-UI components and styled()
6. Add cleanup: Return cleanup function from useEffect to prevent memory leaks

## Pattern: Custom Hooks for Logic Reuse

### ✅ Extract Complex Logic into Custom Hooks

```typescript
// hooks/useUser.ts
import { useState, useEffect } from 'react';

export function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    setLoading(true);
    setError(null);

    fetchUser(userId)
      .then(data => {
        if (isMounted) {
          setUser(data);
          setLoading(false);
        }
      })
      .catch(err => {
        if (isMounted) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [userId]);

  return { user, loading, error };
}

// Component using custom hook
export const UserCard: React.FC<UserCardProps> = ({ userId, onUpdate }) => {
  const { user, loading, error } = useUser(userId);

  if (loading) return <CircularProgress />;
  if (error) return <Typography color="error">{error}</Typography>;
  if (!user) return <Typography>User not found</Typography>;

  return (
    <StyledCard>
      <Typography variant="h6">{user.name}</Typography>
      <Button onClick={() => onUpdate(user)}>Edit</Button>
    </StyledCard>
  );
};
```

**Why This Works**:
- **Reusability**: useUser hook can be used in any component needing user data
- **Testability**: Hook can be tested independently with @testing-library/react-hooks
- **Separation of Concerns**: Component focuses on rendering, hook focuses on data fetching
- **Maintainability**: Business logic changes happen in one place (the hook)

## Edge Cases

### Edge Case 1: User Data with Optional Fields
**Scenario**: API returns user with optional profile fields (avatar, bio, etc.)

**Solution**:
```typescript
interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  bio?: string | null;
}

export const UserCard: React.FC<UserCardProps> = ({ userId }) => {
  const { user, loading, error } = useUser(userId);

  if (loading) return <CircularProgress />;
  if (error) return <Typography color="error">{error}</Typography>;
  if (!user) return <Typography>User not found</Typography>;

  return (
    <StyledCard>
      {user.avatar && <Avatar src={user.avatar} alt={user.name} />}
      <Typography variant="h6">{user.name}</Typography>
      <Typography variant="body2">{user.email}</Typography>
      {user.bio && (
        <Typography variant="body2" color="text.secondary">
          {user.bio}
        </Typography>
      )}
    </StyledCard>
  );
};
```

### Edge Case 2: Component Unmounts During Fetch
**Scenario**: User navigates away before data loads, causing "can't perform state update on unmounted component" warning

**Solution**: Cleanup function in useEffect (already shown in recommended pattern)
```typescript
useEffect(() => {
  let isMounted = true; // Track mount status

  fetchUser(userId).then(data => {
    if (isMounted) { // Only update state if still mounted
      setUser(data);
    }
  });

  return () => {
    isMounted = false; // Set flag on cleanup
  };
}, [userId]);
```

### Edge Case 3: Rapid Prop Changes (Race Conditions)
**Scenario**: userId prop changes rapidly, earlier fetch completes after later fetch

**Solution**: Use AbortController to cancel previous requests
```typescript
useEffect(() => {
  const abortController = new AbortController();

  fetchUser(userId, { signal: abortController.signal })
    .then(data => setUser(data))
    .catch(err => {
      if (err.name !== 'AbortError') {
        setError(err.message);
      }
    });

  return () => {
    abortController.abort(); // Cancel fetch on cleanup
  };
}, [userId]);
```

## Integration Points

### With React Router
- Use useParams() hook for route parameters: `const { userId } = useParams<{ userId: string }>();`
- Navigate programmatically: `const navigate = useNavigate(); navigate('/users/' + userId);`

### With Material-UI Theme
- Access theme in styled components: `styled(Card)(({ theme }) => ({ padding: theme.spacing(2) }))`
- Use theme in components: `const theme = useTheme(); <Box sx={{ mt: theme.spacing(2) }} />`

### With React Query (if using)
- Replace useState + useEffect with useQuery: `const { data: user, isLoading, error } = useQuery(['user', userId], () => fetchUser(userId));`
- Automatic caching, refetching, and error handling

## Testing Requirements

### Unit Tests (Component Logic)
```typescript
import { render, screen } from '@testing-library/react';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  it('shows loading state initially', () => {
    render(<UserCard userId="123" onUpdate={jest.fn()} />);
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('displays user data when loaded', async () => {
    render(<UserCard userId="123" onUpdate={jest.fn()} />);
    expect(await screen.findByText('John Doe')).toBeInTheDocument();
  });

  it('calls onUpdate when edit button clicked', async () => {
    const handleUpdate = jest.fn();
    render(<UserCard userId="123" onUpdate={handleUpdate} />);
    
    const editButton = await screen.findByRole('button', { name: /edit/i });
    editButton.click();
    
    expect(handleUpdate).toHaveBeenCalledWith(expect.objectContaining({ name: 'John Doe' }));
  });
});
```

### Integration Tests (Full Flow)
- Test with real API calls (mocked with MSW)
- Test theme switching (light/dark mode)
- Test responsive behavior (different screen sizes)

### Coverage Expectations
- Unit tests: 80%+ line coverage
- All props combinations tested
- Error states and edge cases covered
- Accessibility checks (a11y)

## References

- [React Documentation: Hooks](https://react.dev/reference/react)
- [Material-UI: Theming](https://mui.com/material-ui/customization/theming/)
- [Project Conventions: @global-conventions]
- [TypeScript Patterns: @typescript-conventions]
```

## Token Optimization

### ✅ Safe to Optimize
- Reduce example count if pattern clear from 1-2 examples
- Consolidate similar edge cases
- Shorten category descriptions
- Remove redundant explanations

### ❌ Never Optimize Away
- Complete code examples (snippets insufficient)
- Deprecated pattern markings (critical for learning)
- Rationale sections (AI needs "why" not just "what")
- Edge case documentation (prevents bugs)
- Integration points (shows system interactions)

## References

This mode incorporates best practices from:
- Cursor rules documentation[3][132][144]
- MDC format specifications[142][147][150]
- Rule organization patterns[3][132]
- AI discovery optimization[3][144]
- Complete example methodology[3][132]
