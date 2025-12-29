# GraphQL Patterns

**Purpose**: Guide for designing and implementing GraphQL APIs

## GRAPHQL VS REST

### GraphQL
- **Purpose**: Query language for APIs - clients specify exactly what data they need
- **Single Endpoint**: `/graphql` - all requests go to one endpoint
- **Flexible**: Clients define the response structure
- **Type Safe**: Strongly typed schema
- **Introspection**: Clients can query schema metadata

### REST
- **Purpose**: Resource-based API - predefined endpoints
- **Multiple Endpoints**: `/api/users`, `/api/posts` - one endpoint per resource
- **Over-Fetching/Under-Fetching**: Clients get fixed data structure
- **Multiple Requests**: Need multiple requests for related data
- **HATEOAS**: Hypermedia as the Engine of Application State

## GRAPHQL SCHEMA DESIGN

### Type System
```graphql
# Scalar types
scalar Date
scalar DateTime

# Object types
type User {
  id: ID!
  name: String!
  email: String!
  createdAt: DateTime!
  posts: [Post!]!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  tags: [String!]!
  published: Boolean!
}

# Input types
input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

input UpdateUserInput {
  name: String
  email: String
  password: String
}

# Enum types
enum UserRole {
  ADMIN
  USER
  GUEST
}

# Union types
union SearchResult = User | Post | Comment

# Interface types
interface Node {
  id: ID!
  createdAt: DateTime!
}

type User implements Node {
  id: ID!
  createdAt: DateTime!
  name: String!
}
```

### Queries and Mutations
```graphql
# Queries
type Query {
  user(id: ID!): User!
  users(limit: Int, offset: Int): [User!]!
  posts(limit: Int, offset: Int): [Post!]!
  search(query: String!): [SearchResult!]!
}

# Mutations
type Mutation {
  createUser(input: CreateUserInput!): User!
  updateUser(id: ID!, input: UpdateUserInput!): User!
  deleteUser(id: ID!): Boolean!
  createPost(title: String!, content: String!, authorId: ID!): Post!
}
```

## RESOLVER PATTERNS

### Basic Resolver
```typescript
// Simple field resolver
const userResolver: Resolver<ParentType, Args, Context, Info> = {
  async user(parent, args, context, info) {
    const user = await context.dataSources.userAPI.getUser(args.id);
    return user;
  },

  async posts(parent, args, context, info) {
    const posts = await context.dataSources.postAPI.getPostsByUser(parent.id, args);
    return posts;
  }
};
```

### DataLoader Pattern
```typescript
import DataLoader from 'dataloader';

// Create batch loader for user posts
const postBatchLoader = new DataLoader(async (userIds) => {
  const posts = await context.dataSources.postAPI.getPostsByUsers(userIds);
  return userIds.map(id => posts[id]);
});

// Resolver using DataLoader
const User: UserResolver = {
  async posts(parent, args, context, info) {
    return await postBatchLoader.load(parent.id);
  }
};
```

### N+1 Prevention
```typescript
// BAD: N+1 queries
const User: UserResolver = {
  async posts(parent) {
    // Causes N+1 - one query per User resolver
    return await context.dataSources.postAPI.getPostsByUser(parent.id);
  }
};

// GOOD: DataLoader batching
const postBatchLoader = new DataLoader(async (userIds) => {
  const posts = await context.dataSources.postAPI.getPostsByUsers(userIds);
  return userIds.map(id => posts[id]);
});

const User: UserResolver = {
  async posts(parent) {
    return await postBatchLoader.load(parent.id);
  }
};
```

### Error Handling
```typescript
// Error wrapper for resolvers
function wrapResolver(resolver) {
  return async (parent, args, context, info) => {
    try {
      return await resolver(parent, args, context, info);
    } catch (error) {
      // Log error
      console.error('Resolver error:', error);
      // Rethrow with GraphQLError
      throw new GraphQLError(error.message, {
        extensions: {
          code: 'INTERNAL_SERVER_ERROR'
        }
      });
    }
  };
}

// Usage
const userResolver: UserResolver = {
  user: wrapResolver(async (parent, args, context, info) => {
    return await context.dataSources.userAPI.getUser(args.id);
  })
};
```

### Authentication
```typescript
// Get authenticated user from context
const authenticatedUser = (context) => {
  if (!context.user) {
    throw new GraphQLError('Authentication required', {
      extensions: {
        code: 'UNAUTHENTICATED'
      }
    });
  }
  return context.user;
};

// Protected resolver
const updateUser: MutationResolver = {
  async updateUser(parent, args, context, info) {
    const user = authenticatedUser(context);

    // Authorization check
    if (user.id !== args.id && !user.roles.includes('ADMIN')) {
      throw new GraphQLError('Not authorized', {
        extensions: {
          code: 'FORBIDDEN'
        }
      });
    }

    return await context.dataSources.userAPI.updateUser(args.id, args.input);
  }
};
```

### Authorization
```typescript
// Role-based authorization
const hasRole = (user, role) => {
  return user.roles.includes(role);
};

// Permission-based authorization
const canUpdateUser = (currentUser, targetUserId) => {
  return currentUser.id === targetUserId || hasRole(currentUser, 'ADMIN');
};

// Usage
const updateUser: MutationResolver = {
  async updateUser(parent, args, context, info) {
    const user = authenticatedUser(context);
    
    if (!canUpdateUser(user, args.id)) {
      throw new GraphQLError('Not authorized to update this user', {
        extensions: {
          code: 'FORBIDDEN'
        }
      });
    }

    return await context.dataSources.userAPI.updateUser(args.id, args.input);
  }
};
```

## QUERY PATTERNS

### Basic Query
```graphql
query GetUser {
  user(id: "123") {
    id
    name
    email
    posts {
      id
      title
      published
    }
  }
}
```

### Query with Arguments
```graphql
query GetUsers($limit: Int, $offset: Int) {
  users(limit: $limit, offset: $offset) {
    id
    name
    email
  }
}

# Variables
{
  "limit": 20,
  "offset": 0
}
```

### Query with Fragments
```graphql
fragment UserFields on User {
  id
  name
  email
}

query GetUsers {
  users {
    ...UserFields
    posts {
      id
      title
    }
  }
}
```

### Query with Union Type
```graphql
query Search($query: String!) {
  search(query: $query) {
    ... on User { id name email }
    ... on Post { id title published }
  }
}
```

### Query with Inline Fragments
```graphql
query GetUserWithPosts($userId: ID!) {
  user(id: $userId) {
    id
    name
    posts(first: 10) {
      id
      title
    }
  }
}
```

### Nested Queries
```graphql
query GetDeepUser($userId: ID!) {
  user(id: $userId) {
    id
    name
    posts {
      id
      title
      author {
        id
        name
      }
      comments {
        id
        text
        author {
          id
          name
        }
      }
    }
  }
}
```

## MUTATION PATTERNS

### Create Mutation
```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    name
    email
  }
}

# Variables
{
  "input": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepassword"
  }
}
```

### Update Mutation
```graphql
mutation UpdateUser($id: ID!, $input: UpdateUserInput!) {
  updateUser(id: $id, input: $input) {
    id
    name
    email
  }
}

# Variables
{
  "id": "123",
  "input": {
    "name": "Jane Doe"
  }
}
```

### Delete Mutation
```graphql
mutation DeleteUser($id: ID!) {
  deleteUser(id: $id)
}
```

### Multiple Mutations
```graphql
mutation CreatePost($input: CreatePostInput!) {
  createPost(input: $input) {
    id
    title
    content
    author {
      id
      name
    }
  }
  createComment(input: $commentInput) {
    id
    text
  }
}
```

## ERROR HANDLING

### GraphQLError Extensions
```typescript
throw new GraphQLError('User not found', {
  extensions: {
    code: 'USER_NOT_FOUND',
    timestamp: new Date().toISOString()
  }
});
```

### Validation Errors
```typescript
const createUserMutation: MutationResolver = {
  async createUser(parent, args, context, info) {
    const { name, email } = args.input;

    // Validate input
    if (!name || name.length < 3) {
      throw new GraphQLError('Name must be at least 3 characters', {
        extensions: {
          code: 'VALIDATION_ERROR',
          fields: ['name']
        }
      });
    }

    if (!email || !email.includes('@')) {
      throw new GraphQLError('Invalid email format', {
        extensions: {
          code: 'VALIDATION_ERROR',
          fields: ['email']
        }
      });
    }

    return await context.dataSources.userAPI.createUser(args.input);
  }
};
```

### Database Errors
```typescript
const userResolver: UserResolver = {
  async user(parent, args, context, info) {
    try {
      return await context.dataSources.userAPI.getUser(args.id);
    } catch (error) {
      if (error.code === 'P0001') {
        throw new GraphQLError('User not found', {
          extensions: {
            code: 'USER_NOT_FOUND'
          }
        });
      }
      throw error;
    }
  }
};
```

## PERFORMANCE OPTIMIZATION

### Query Depth Limiting
```typescript
// Limit query depth
const MAX_QUERY_DEPTH = 5;

const depthLimit = (maxDepth) => (next) => (parent, args, context, info) => {
  const depth = context.operation?.path?.length || 0;
  if (depth > maxDepth) {
    throw new GraphQLError(`Query depth exceeds maximum of ${maxDepth}`, {
      extensions: {
        code: 'QUERY_DEPTH_EXCEEDED'
      }
    });
  }
  return next(parent, args, context, info);
};

// Usage
const resolvers = {
  Query: {
    user: depthLimit(MAX_QUERY_DEPTH)(userResolver),
    users: depthLimit(MAX_QUERY_DEPTH)(usersResolver)
  }
};
```

### Query Complexity Analysis
```typescript
// Define complexity rules
const complexityRule = {
  user: 1,
  posts: {
    perItem: 3,
      author: 1
  },
  comments: {
    perItem: 2
  }
};

const queryComplexity = (query) => {
  let complexity = 0;

  const traverse = (node) => {
    if (node.kind === 'Field') {
      const fieldName = node.name.value;
      const field = complexityRule[fieldName];
      if (typeof field === 'number') {
        complexity += field;
      } else if (typeof field === 'object') {
        const perItem = field.perItem || 0;
        complexity += perItem;
      }
    }
    if (node.kind === 'InlineFragment') {
      const selections = node.selectionSet?.selections || [];
      selections.forEach(selection => traverse(selection));
    }
    if (node.kind === 'SelectionSet') {
      const selections = node.selections || [];
      selections.forEach(selection => traverse(selection));
    }
  };

  traverse(query);
  return complexity;
};

// Usage
const complexityLimiter = (maxComplexity) => (next) => {
  const complexity = queryComplexity(info.operation);
  if (complexity > maxComplexity) {
    throw new GraphQLError(`Query complexity ${complexity} exceeds maximum of ${maxComplexity}`, {
      extensions: {
        code: 'QUERY_COMPLEXITY_EXCEEDED'
      }
    });
  }
  return next(parent, args, context, info);
};
```

### Field Level Rate Limiting
```typescript
// Track query frequency per field
const rateLimiters = {};

const fieldRateLimit = (field, maxCallsPerMinute) => (next) => {
  const now = Date.now();
  const key = `${field}:${Math.floor(now / 60000)}`; // 1-minute buckets

  if (!rateLimiters[key]) {
    rateLimiters[key] = [];
  }

  if (rateLimiters[key].length >= maxCallsPerMinute) {
    throw new GraphQLError(`Rate limit exceeded for field '${field}'`, {
      extensions: {
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: new Date(Math.ceil(now / 60000) * 60000 + 60000)
      }
    });
  }

  rateLimiters[key].push(now);
  return next(parent, args, context, info);
};

// Usage
const resolvers = {
  Query: {
    posts: fieldRateLimit('posts', 100)(postsResolver)
  }
};
```

## TESTING

### Query Tests
```typescript
describe('User queries', () => {
  test('should fetch user', async () => {
    const result = await executeQuery(`
      query GetUser($id: "123") {
        user(id: $id) {
          id
          name
        }
      }
    `, { id: '123' });

    expect(result.data.user).toEqual({
      id: '123',
      name: 'Test User'
    });
  });

  test('should return null for non-existent user', async () => {
    const result = await executeQuery(`
      query GetUser($id: "999") {
        user(id: $id) {
          id
          name
        }
      }
    `, { id: '999' });

    expect(result.data.user).toBeNull();
  });
});
```

### Mutation Tests
```typescript
describe('User mutations', () => {
  test('should create user', async () => {
    const result = await executeMutation(`
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          id
          name
          email
        }
      }
    `, {
      input: {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password'
      }
    });

    expect(result.data.createUser).toHaveProperty('id');
  });

  test('should throw validation error for invalid email', async () => {
    const result = await executeMutation(`
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          id
          name
          email
        }
      }
    `, {
      input: {
        name: 'Test User',
        email: 'invalid-email',
        password: 'password'
      }
    });

    expect(result.errors).toBeDefined();
    expect(result.errors?.[0]?.extensions?.code).toBe('VALIDATION_ERROR');
  });
});
```

## FRAMEWORK-SPECIFIC EXAMPLES

### Apollo Server (Node.js)
```typescript
import { ApolloServer, gql, IResolvers } from '@apollo/server';
import { Context } from './context';

const typeDefs = gql`
  type User {
    id: ID!
    name: String!
    email: String!
    posts: [Post!]!
  }

  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
  }

  type Query {
    user(id: ID!): User
    users: [User!]!
  }
`;

const resolvers: IResolvers = {
  Query: {
    user: async (_, { id }, { dataSources }) => {
      return dataSources.userAPI.getUser(id);
    },
    users: async (_, __, { dataSources }) => {
      return dataSources.userAPI.getAllUsers();
    }
  },
  User: {
    posts: async (user, _, { dataSources }) => {
      return dataSources.postAPI.getPostsByUser(user.id);
    }
  }
};

const server = new ApolloServer<Context>({
  typeDefs,
  resolvers,
  context: async () => ({
    dataSources: {
      userAPI: new UserAPI(),
      postAPI: new PostAPI()
    }
  })
});
```

### GraphQL Yoga (Node.js)
```javascript
const { createServer } = require('graphql-yoga');
const { createPost } = require('./resolvers/post');
const { getUser } = require('./resolvers/user');

const typeDefs = `
  type User {
    id: ID!
    name: String!
    email: String!
    posts: [Post!]!
  }

  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
  }

  type Query {
    user(id: ID!): User!
    users: [User!]!
  }

  type Mutation {
    createPost(title: String!, content: String!, authorId: ID!): Post!
  }
`;

const resolvers = {
  Query: {
    user: getUser,
    users: () => getAllUsers()
  },
  Mutation: {
    createPost: createPost
  },
  User: {
    posts: (user) => getPostsByUser(user.id)
  }
};

const server = createServer({
  schema: [typeDefs],
  resolvers
});
```

### DraphQL (Go)
```go
package graphql

import (
    "github.com/99designs/gqlgen/graphql/graphql/introspection"
    "github.com/99designs/gqlgen/graphql/language/parser"
)

type User struct {
    ID    string `json:"id"`
    Name  string `json:"name"`
    Email  string `json:"email"`
}

type Query struct {
    Users []User `json:"users"`
}

func (q Query) Users() ([]User, error) {
    // Query users from database
    users, err := database.GetUsers()
    return users, err
}
```

### Django Graphene (Python)
```python
import graphene
from graphene_django import DjangoObjectType

class UserType(DjangoObjectType):
    class Meta:
        model = User

    id = graphene.String()
    name = graphene.String()
    email = graphene.String()

    posts = graphene.List('PostType')

class PostType(DjangoObjectType):
    class Meta:
        model = Post

    id = graphene.String()
    title = graphene.String()
    content = graphene.String()

class Query(graphene.ObjectType):
    users = graphene.List(UserType)

    def resolve_users(self, info):
        return User.objects.all()

    def resolve_user(self, info, id):
        return User.objects.get(pk=id)

class Mutation(graphene.ObjectType):
    create_user = graphene.Field(UserType, graphene.String())
    email = graphene.Argument(UserType, graphene.String(required=True))
    name = graphene.Argument(UserType, graphene.String(required=True))

    def resolve_create_user(self, info, email, name):
        user = User.objects.create(email=email, name=name)
        return user

schema = graphene.Schema(query=Query, mutation=Mutation)
```

## BEST PRACTICES

### Schema Design
- **Descriptive Names**: Use clear, descriptive type and field names
- **Strong Typing**: Always specify types for all fields
- **Non-Null Fields**: Use `!` for required fields
- **Lists for Collections**: Use `[Type]` for lists
- **Interfaces for Common Fields**: Use interfaces for shared fields across types

### Error Handling
- **Use GraphQLError**: Throw GraphQLError with proper extensions
- **Meaningful Error Codes**: Use descriptive error codes
- **Include Debug Info**: Include timestamp, request ID, etc.
- **Don't Expose Internal Details**: Don't leak database errors or stack traces

### Performance
- **Limit Query Depth**: Prevent deeply nested queries
- **Analyze Query Complexity**: Use complexity analysis
- **Implement Rate Limiting**: Protect against abuse
- **Use DataLoaders**: Batch requests to prevent N+1 queries
- **Enable Query Caching**: Cache frequently accessed data
- **Avoid Over-Fetching**: Only request needed fields

### Security
- **Authentication & Authorization**: Protect mutations and sensitive queries
- **Input Validation**: Validate all input in resolvers
- **Sanitize Output**: Don't return internal fields to unauthorized users
- **Rate Limiting**: Protect against DDoS attacks
- **Query Cost Analysis**: Use complexity analysis to prevent resource exhaustion
- **Audit Logging**: Log all queries for security auditing

### Testing
- **Unit Tests**: Test resolvers in isolation
- **Integration Tests**: Test the full API
- **Load Testing**: Test performance under load
- **Fuzzing**: Test for vulnerabilities
```
