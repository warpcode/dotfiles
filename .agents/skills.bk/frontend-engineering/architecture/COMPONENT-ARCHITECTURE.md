# Component Architecture

**Purpose**: Guide for designing scalable and maintainable frontend component architectures

## COMPOSITION PATTERNS

### Presentational vs Container Pattern

#### Presentational Components
- **Purpose**: UI only, no business logic, receive props, render UI
- **Characteristics**: 
  - No state (or only UI state)
  - Receive data via props
  - Emit data via callbacks
  - Framework-agnostic (can use in multiple frameworks)
- **Example**:
```jsx
// Presentational component (React)
function UserCard({ user, onEdit, onDelete }) {
  return (
    <div className="user-card">
      <h2>{user.name}</h2>
      <p>{user.email}</p>
      <button onClick={() => onEdit(user.id)}>Edit</button>
      <button onClick={() => onDelete(user.id)}>Delete</button>
    </div>
  );
}
```

#### Container Components
- **Purpose**: Business logic, state management, fetch data
- **Characteristics**:
  - Manage state (Redux, Pinia, Context)
  - Fetch data from APIs
  - Pass data to presentational components
  - Framework-specific (tied to state library)
- **Example**:
```jsx
// Container component (React with Redux)
import { connect } from 'react-redux';
import { fetchUser, deleteUser } from '../actions/users';
import UserCard from './UserCard';

function UserContainer({ user, loading, error, fetchUser, deleteUser }) {
  useEffect(() => {
    fetchUser(userId);
  }, [fetchUser, userId]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return <UserCard user={user} onEdit={onEditUser} onDelete={handleDelete} />;
}

function mapStateToProps(state, ownProps) {
  return {
    user: state.users.byId[ownProps.userId],
    loading: state.users.loading,
    error: state.users.error
  };
}

export default connect(mapStateToProps, { fetchUser, deleteUser })(UserContainer);
```

### Higher-Order Components (HOCs)

#### HOC Pattern
- **Purpose**: Reuse component logic
- **Characteristics**:
  - Takes component as argument
  - Returns enhanced component
  - Cross-cutting concerns (auth, theming, logging)
- **Example**:
```jsx
// HOC for authentication
function withAuthentication(Component) {
  return function AuthenticatedWrapper(props) {
    const { isAuthenticated, user } = useAuth();
    
    if (!isAuthenticated) {
      return <Redirect to="/login" />;
    }
    
    return <Component {...props} user={user} />;
  };
}

// Usage
const ProtectedDashboard = withAuthentication(Dashboard);
```

### Render Props

#### Render Props Pattern
- **Purpose**: Share code between components using function prop
- **Characteristics**:
  - Component passes function as prop
  - Child calls function to render
  - More flexible than HOCs
- **Example**:
```jsx
// Render props component
function MouseTracker({ render }) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const handleMouseMove = (e) => {
    setPosition({ x: e.clientX, y: e.clientY });
  };

  return (
    <div onMouseMove={handleMouseMove}>
      {render(position)}
    </div>
  );
}

// Usage
function App() {
  return (
    <MouseTracker
      render={({ x, y }) => (
        <p>Mouse position: {x}, {y}</p>
      )}
    />
  );
}
```

### Custom Hooks (React)

#### Custom Hooks Pattern
- **Purpose**: Reuse stateful logic
- **Characteristics**:
  - Use `use` prefix
  - Return state and functions
  - Can be composed together
- **Example**:
```jsx
// Custom hook for data fetching
function useFetch(url) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch(url)
      .then(response => {
        if (!response.ok) throw new Error('Network error');
        return response.json();
      })
      .then(data => setData(data))
      .catch(error => setError(error))
      .finally(() => setLoading(false));
  }, [url]);

  return { data, loading, error };
}

// Usage
function UserList() {
  const { data: users, loading, error } = useFetch('/api/users');

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

## COMPOSITION TECHNIQUES

### Component Composition
```jsx
// Compose multiple components
function Dashboard() {
  return (
    <Layout>
      <Header />
      <Sidebar />
      <MainContent>
        <UserProfile />
        <UserActivity />
      </MainContent>
      <Footer />
    </Layout>
  );
}
```

### Slot Pattern (Vue)
```vue
<!-- Parent component -->
<template>
  <div class="card">
    <slot name="header"></slot>
    <slot></slot>
    <slot name="footer"></slot>
  </div>
</template>

<!-- Usage -->
<Card>
  <template #header>
    <h2>Card Title</h2>
  </template>
  <p>Card content</p>
  <template #footer>
    <button>Action</button>
  </template>
</Card>
```

### Transclusion (Angular)
```typescript
// Parent component
@Component({
  selector: 'app-card',
  template: `
    <div class="card">
      <ng-content select="[header]"></ng-content>
      <ng-content></ng-content>
      <ng-content select="[footer]"></ng-content>
    </div>
  `
})
export class CardComponent {}

// Usage
<app-card>
  <div header><h2>Card Title</h2></div>
  <p>Card content</p>
  <div footer><button>Action</button></div>
</app-card>
```

## STATE MANAGEMENT PATTERNS

### Lifting State Up
- **Purpose**: Share state between sibling components
- **Pattern**: Move state to closest common parent
- **Example**:
```jsx
// Parent with shared state
function Parent() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <Counter count={count} onSetCount={setCount} />
      <CounterDisplay count={count} />
    </div>
  );
}

function Counter({ count, onSetCount }) {
  return <button onClick={() => onSetCount(count + 1)}>Increment</button>;
}

function CounterDisplay({ count }) {
  return <p>Count: {count}</p>;
}
```

### Compound Components
- **Purpose**: Group related components sharing state
- **Pattern**: Context API + compound pattern
- **Example**:
```jsx
// Tab compound components
const TabsContext = createContext();

function Tabs({ children, defaultTab }) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  );
}

function TabList({ children }) {
  const { activeTab, setActiveTab } = useContext(TabsContext);
  
  return (
    <div className="tab-list">
      {React.Children.map(children, child => {
        return React.cloneElement(child, {
          active: child.props.value === activeTab,
          onClick: () => setActiveTab(child.props.value)
        });
      })}
    </div>
  );
}

function Tab({ value, active, children, onClick }) {
  return (
    <button 
      className={`tab ${active ? 'active' : ''}`}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

function TabPanel({ value, children }) {
  const { activeTab } = useContext(TabsContext);

  if (value !== activeTab) return null;

  return <div className="tab-panel">{children}</div>;
}

// Usage
function App() {
  return (
    <Tabs defaultTab="tab1">
      <TabList>
        <Tab value="tab1">Tab 1</Tab>
        <Tab value="tab2">Tab 2</Tab>
      </TabList>
      <TabPanel value="tab1">
        Content 1
      </TabPanel>
      <TabPanel value="tab2">
        Content 2
      </TabPanel>
    </Tabs>
  );
}
```

## COMPONENT PATTERNS

### Container/Presentational (Redux)
```jsx
// Redux container component
import { connect } from 'react-redux';

function TodoListContainer({ todos, loading, error, fetchTodos }) {
  useEffect(() => {
    fetchTodos();
  }, [fetchTodos]);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error.message}</p>;

  return <TodoList todos={todos} />;
}

const mapStateToProps = state => ({
  todos: state.todos.items,
  loading: state.todos.loading,
  error: state.todos.error
});

const mapDispatchToProps = {
  fetchTodos: () => ({ type: 'FETCH_TODOS_REQUEST' })
};

export default connect(mapStateToProps, mapDispatchToProps)(TodoListContainer);

// Presentational component
function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

### Controlled Components
```jsx
// Controlled component pattern
function ControlledInput({ value, onChange }) {
  return (
    <input
      type="text"
      value={value}
      onChange={e => onChange(e.target.value)}
    />
  );
}

function Form() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <form>
      <ControlledInput
        value={email}
        onChange={setEmail}
      />
      <ControlledInput
        type="password"
        value={password}
        onChange={setPassword}
      />
    </form>
  );
}
```

### Uncontrolled Components
```jsx
// Uncontrolled component pattern
function UncontrolledInput() {
  const inputRef = useRef();

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log(inputRef.current.value);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input ref={inputRef} type="text" />
      <button type="submit">Submit</button>
    </form>
  );
}
```

## ANTI-PATTERNS

### God Components
```jsx
// BAD: God component doing too much
function Dashboard({ user, posts, settings, notifications }) {
  // Does everything: renders, fetches, validates, transforms
  return (
    <div>
      {/* Hundreds of lines of code */}
    </div>
  );
}

// GOOD: Split into smaller components
function Dashboard({ user }) {
  return (
    <Layout>
      <UserProfile user={user} />
      <UserPosts userId={user.id} />
      <UserSettings userId={user.id} />
      <UserNotifications userId={user.id} />
    </Layout>
  );
}
```

### Prop Drilling
```jsx
// BAD: Prop drilling through many levels
function App() {
  const [theme, setTheme] = useState('light');
  return <Layout theme={theme} setTheme={setTheme} />;
}

function Layout({ theme, setTheme, children }) {
  return <Sidebar theme={theme} setTheme={setTheme} children={children} />;
}

function Sidebar({ theme, setTheme, children }) {
  return (
    <div className="sidebar">
      <Header theme={theme} setTheme={setTheme} />
      {children}
    </div>
  );
}

function Header({ theme, setTheme }) {
  return <button onClick={() => setTheme('dark')}>Toggle theme</button>;
}

// GOOD: Use Context API
const ThemeContext = createContext();

function ThemeProvider({ children }) {
  const [theme, setTheme] = useState('light');

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

function ThemeToggle() {
  const { setTheme } = useContext(ThemeContext);
  return <button onClick={() => setTheme('dark')}>Toggle theme</button>;
}
```

## BEST PRACTICES

### Single Responsibility
- Each component should do one thing well
- Split large components into smaller ones
- Use composition to build complex UIs

### Reusability
- Make components framework-agnostic when possible
- Use props for customization
- Avoid hard-coded values

### Composition Over Inheritance
- Prefer composition over component inheritance
- Use render props or HOCs for code reuse
- Use custom hooks for stateful logic

### Performance
- Use React.memo() for expensive components
- Use useMemo() for expensive calculations
- Use useCallback() to memoize callbacks
- Use lazy loading with React.lazy()
- Use code splitting
