# Lazy Loading Strategies

**Purpose**: Guide for implementing lazy loading in frontend applications

## CODE SPLITTING

### React

#### React.lazy()
```jsx
// Basic lazy loading
const Dashboard = React.lazy(() => import('./Dashboard'));
const AdminPanel = React.lazy(() => import('./AdminPanel'));

function App() {
  return (
    <Routes>
      <Route path="/dashboard" element={
        <Suspense fallback={<Spinner />}>
          <Dashboard />
        </Suspense>
      } />
      <Route path="/admin" element={
        <Suspense fallback={<Spinner />}>
          <AdminPanel />
        </Suspense>
      } />
    </Routes>
  );
}
```

#### Named Exports
```jsx
// Component with named exports
// Dashboard.js
export default Dashboard;
export const DashboardHeader = () => <h1>Dashboard</h1>;

// Lazy loading named exports
const Dashboard = React.lazy(() => import('./Dashboard'));
const { DashboardHeader } = await import('./Dashboard');
```

#### Dynamic Import
```jsx
// Dynamic import with error boundary
function App() {
  const [component, setComponent] = useState(null);

  const loadComponent = async (componentName) => {
    try {
      const { default: Component } = await import(`./components/${componentName}`);
      setComponent(() => <Component />);
    } catch (error) {
      setComponent(() => <ErrorPage error={error} />);
    }
  };

  return (
    <div>
      <button onClick={() => loadComponent('Dashboard')}>Load Dashboard</button>
      {component}
    </div>
  );
}
```

### Vue.js

#### Async Components
```vue
<!-- AsyncComponent.vue -->
<template>
  <component :is="component" :v-if="component" />
  <span v-else>Loading...</span>
</template>

<script>
export default {
  data() {
    return {
      component: null
    };
  },
  methods: {
    async loadComponent(name) {
      try {
        const component = await import(`./components/${name}.vue`);
        this.component = component.default;
      } catch (error) {
        this.component = ErrorComponent;
      }
    }
  }
}
</script>
```

#### DefineAsyncComponent
```vue
<script>
import { defineAsyncComponent } from 'vue';

const AsyncDashboard = defineAsyncComponent({
  loader: () => import('./Dashboard.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent: ErrorPage,
  delay: 200,  // Show loading for at least 200ms
  timeout: 3000  // Timeout after 3 seconds
});

export default {
  components: {
    AsyncDashboard
  }
};
</script>

<template>
  <AsyncDashboard />
</template>
```

### Angular

#### Load Children
```typescript
// app-routing.module.ts
import { NgModule } from '@angular/core';
import { RouterModule, Routes, Router } from '@angular/router';

const routes: Routes = [
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule)
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)]
})
export class AppRoutingModule { }
```

#### Preloading Strategy
```typescript
// Preloading specific routes
const routes: Routes = [
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule),
    data: { preload: true }  // Custom property for preloading
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m => m.AdminModule)
  }
];

// Custom preloading strategy
export class CustomPreloadingStrategy implements PreloadingStrategy {
  preload(route: Route, load: () => Observable<any[]> | Observable<any>) {
    return route.data?.preload ? this.preload(route, load) : load();
  }

  preload(route: Route, load: () => Observable<any[]> | Observable<any>) {
    return load().pipe(
      delay(2000)  // Add delay for smooth UX
      catchError(() => of({ default: ErrorComponent }))
    );
  }
}
```

## IMAGE LAZY LOADING

### Native Lazy Loading
```html
<!-- Native lazy loading with placeholder -->
<img src="placeholder.jpg" 
     data-src="actual-image.jpg" 
     loading="lazy" 
     alt="Description">

<!-- Decode attribute to prevent layout shift -->
<img src="placeholder.jpg" 
     data-src="actual-image.jpg" 
     loading="lazy" 
     decoding="async"
     alt="Description">
```

### React Lazy Loading

#### react-lazy-load
```bash
npm install react-lazy-load
```

```jsx
import { LazyLoadImage } from 'react-lazy-load-images';

function ImageGallery() {
  const images = [
    'https://example.com/image1.jpg',
    'https://example.com/image2.jpg',
    'https://example.com/image3.jpg',
  ];

  return (
    <div>
      {images.map((src, index) => (
        <LazyLoadImage
          key={index}
          src={src}
          alt={`Image ${index + 1}`}
          placeholder={<ImagePlaceholder />}
          threshold={0.1}  // Load when 10% visible
          effect="blur"  // Blur effect during load
        />
      ))}
    </div>
  );
}
```

#### Intersection Observer
```jsx
function LazyImage({ src, alt, placeholder }) {
  const [imageSrc, setImageSrc] = useState(placeholder);
  const imgRef = useRef();

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setImageSrc(src);
          observer.unobserve(imgRef.current);
        }
      },
      { threshold: 0.1 }
    );

    observer.observe(imgRef.current);

    return () => {
      if (imgRef.current) {
        observer.unobserve(imgRef.current);
      }
    };
  }, [src, placeholder]);

  return <img ref={imgRef} src={imageSrc} alt={alt} />;
}
```

### Vue.js Lazy Loading

#### vue-lazyload
```bash
npm install vue-lazyload
```

```vue
<template>
  <div>
    <lazy v-for="(image, index) in images"
           :key="index"
           :src="image.src"
           :alt="image.alt">
      <div slot="placeholder">
        <div class="spinner"></div>
      </div>
    </lazy>
  </div>
</template>

<script>
import VueLazyload from 'vue-lazyload';

export default {
  data() {
    return {
      images: [
        { src: 'image1.jpg', alt: 'Image 1' },
        { src: 'image2.jpg', alt: 'Image 2' },
      ]
    };
  },
  components: {
    Lazy: VueLazyload
  }
};
</script>
```

### Angular Lazy Loading

#### ng-lazyload-images
```bash
npm install ng-lazyload-images
```

```typescript
import { LazyLoadImageModule } from 'ng-lazyload-images';

@NgModule({
  imports: [
    LazyLoadImageModule.forRoot({
      defaultImage: 'assets/placeholder.jpg',
      useCache: true,
      debounceTime: 200
    })
  ]
})
export class AppModule {}

@Component({
  selector: 'app-image-gallery',
  template: `
    <div>
      <img *ngFor="let image of images"
           [defaultImage]="placeholder.jpg"
           [lazyLoad]="load(image.src)"
           [alt]="image.alt" />
    </div>
  `
})
export class ImageGalleryComponent {
  images = [
    { src: 'https://example.com/image1.jpg', alt: 'Image 1' },
    { src: 'https://example.com/image2.jpg', alt: 'Image 2' },
  ];

  load(src: string) {
    // Custom loader function
    return src;
  }
}
```

## ROUTE-BASED LAZY LOADING

### React Router
```jsx
import { Routes, Route } from 'react-router-dom';
import { lazy, Suspense } from 'react';

const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Routes>
      <Route path="/" element={<Dashboard />} />
      <Route path="/settings" element={<Settings />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function MainApp() {
  return (
    <Suspense fallback={<Spinner />}>
      <App />
    </Suspense>
  );
}
```

### React Router Data Loading
```jsx
import { Routes, Route, RouterProvider, createBrowserRouter, defer } from 'react-router-dom';

const router = createBrowserRouter([
  {
    path: "/dashboard",
    element: <Dashboard />,
    loader: defer(() => import('./Dashboard')),
  },
  {
    path: "/settings",
    element: <Settings />,
    loader: defer(() => import('./Settings')),
  },
]);

function Dashboard() {
  // Access data via useLoaderData
  return <div>Dashboard content</div>;
}

function App() {
  return <RouterProvider router={router} />;
}
```

### Vue Router
```vue
<script>
import { defineAsyncComponent } from 'vue';
import { useRouter } from 'vue-router';

const Dashboard = defineAsyncComponent(() => import('./views/Dashboard.vue'));
const Settings = defineAsyncComponent(() => import('./views/Settings.vue'));

export default {
  components: {
    Dashboard,
    Settings
  },
  setup() {
    const router = useRouter();
    return { router };
  }
};
</script>

<template>
  <router-view v-slot="{ Component }">
    <Suspense>
      <component :is="Component" />
    </Suspense>
    <div v-if="false">Loading...</div>
  </router-view>
</template>
```

### Angular Router
```typescript
const routes: Routes = [
  {
    path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule)
  },
  {
    path: 'settings',
    loadChildren: () => import('./settings/settings.module').then(m => m.SettingsModule)
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
```

## COMPONENT LAZY LOADING

### Higher-Order Component for Lazy Loading
```jsx
import React, { useState, useEffect } from 'react';

function withLazyLoading(WrappedComponent, loader) {
  return function LazyLoader(props) {
    const [component, setComponent] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
      loader()
        .then(module => setComponent(() => module.default || module))
        .catch(error => {
          console.error('Failed to load component:', error);
          setComponent(() => <ErrorPage />);
        })
        .finally(() => setLoading(false));
    }, [loader]);

    if (loading) {
      return <Spinner />;
    }

    if (!component) {
      return <ErrorPage />;
    }

    return <component {...props} />;
  };
}

// Usage
const Dashboard = withLazyLoading(
  Dashboard,
  () => import('./Dashboard')
);

function App() {
  return <Dashboard />;
}
```

### Suspense Wrapper
```jsx
import React, { Suspense, lazy } from 'react';

function LazyWrapper({ children, fallback }) {
  return (
    <Suspense fallback={fallback || <Spinner />}>
      {children}
    </Suspense>
  );
}

// Usage
const Dashboard = lazy(() => import('./Dashboard'));

function App() {
  return (
    <LazyWrapper fallback={<div>Loading...</div>}>
      <Dashboard />
    </LazyWrapper>
  );
}
```

## DATA FETCHING LAZY LOADING

### React Query
```jsx
import { useQuery } from '@tanstack/react-query';

function UserList() {
  const { data, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
    staleTime: 5000, // Data is fresh for 5 seconds
    cacheTime: 300000, // Keep in cache for 5 minutes
  });
  
  if (isLoading) return <Spinner />;
  
  return (
    <ul>
      {data.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### SWR (Stale-While-Revalidate)
```javascript
import useSWR from 'swr';

function UserList() {
  const { data, isLoading, error } = useSWR('/api/users', fetcher, {
    revalidateOnFocus: true,  // Revalidate when window gets focus
    revalidateOnReconnect: true,  // Revalidate when network reconnects
    refreshInterval: 30000,  // Revalidate every 30 seconds
    dedupingInterval: 60000, // Dedupe requests within 60 seconds
  });

  if (isLoading) return <Spinner />;
  if (error) return <Error />;

  return (
    <ul>
      {data.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### Vuex Action Lazy Loading
```javascript
// actions.js
export const loadUser = async ({ commit }) => {
  commit('SET_LOADING', true);
  try {
    const module = await import('@/store/modules/user');
    commit('REGISTER_USER_MODULE', module);
    const { fetchUser } = module.actions;
    await fetchUser({ commit });
  } catch (error) {
    commit('SET_ERROR', error);
  } finally {
    commit('SET_LOADING', false);
  }
};

// component
import { mapActions } from 'vuex';

export default {
  computed: {
    ...mapActions(['loadUser'])
  },
  mounted() {
    this.loadUser();
  }
};
```

## BEST PRACTICES

### Bundle Splitting
- **Route-based**: Split by routes/pages
- **Component-based**: Split large components
- **Vendor-based**: Third-party libraries separate
- **Common chunks**: Extract common code
- **Dynamic Imports**: Use `import()` for non-critical code

### Placeholder Design
- **Consistent Size**: Use same aspect ratio for all images
- **Loading Indicators**: Show loading spinners/skeletons
- **Error Fallback**: Show error state on load failure
- **Blur Effect**: Add blur effect during image load

### Performance Optimization
- **Threshold Tuning**: Set appropriate intersection thresholds
- **Preloading**: Preload critical routes/resources
- **Cache Strategies**: Cache lazy-loaded components
- **Retry Logic**: Implement retry for failed loads

### Error Handling
- **Error Boundaries**: Wrap lazy components in error boundaries
- **Fallback Components**: Provide generic fallbacks
- **Error Logging**: Log lazy load failures
- **User Feedback**: Show friendly error messages

### SEO Considerations
- **Server-Side Rendering**: Ensure critical content loads initially
- **Meta Tags**: Ensure meta tags are present
- **Crawlers**: Ensure crawlers can access content
- **Progressive Enhancement**: Start with functional, then lazy load
