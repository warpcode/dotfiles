# Frontend & Asset Performance

Reference guide for auditing client-side assets, bundle splitting, and rendering efficiency.

---

## 1. Route & Component Code Splitting

### Inefficient Example
Importing all page components synchronously in router definitions causes the initial bundle to include the entire application code:
```javascript
import Dashboard from './views/Dashboard.vue';
import Settings from './views/Settings.vue';
import AdminPanel from './views/AdminPanel.vue'; // Heavy admin code loaded for all users
```

### Remediation: Dynamic Imports
Use dynamic imports to split routes into separate chunks loaded on-demand:
```javascript
const Dashboard = () => import('./views/Dashboard.vue');
const Settings = () => import('./views/Settings.vue');
const AdminPanel = () => import('./views/AdminPanel.vue');
```

---

## 2. Heavy Library Tree-Shaking

### Inefficient Example
Importing entire utility libraries when only single functions are used:
```javascript
import _ from 'lodash'; // Pulls whole ~70KB library
import * as LucideIcons from 'lucide-vue-next'; // Pulls all 1,000+ icons
```

### Remediation: Named / Deep Imports
```javascript
import debounce from 'lodash/debounce';
import { Check, AlertCircle } from 'lucide-vue-next';
```

---

## 3. Asset Pipeline & Font Optimization

- **Asset Bundling & Minification**: Ensure production build pipelines enable JS/CSS minification (e.g. `terser`, `esbuild`, `cssnano`), eliminate unused loaders, and strip development source maps from client distribution.
- **Modern Image Formats**: Serve images in WebP or AVIF formats rather than uncompressed PNG/JPEG, utilizing `srcset` and `sizes` for responsive delivery.
- **Font Loading Strategies**:
  - Apply `font-display: swap` in `@font-face` definitions to prevent Flash of Invisible Text (FOIT).
  - Preload critical above-the-fold webfonts in the document `<head>`:
    ```html
    <link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>
    ```
  - Self-host webfonts to eliminate third-party DNS lookup, TLS handshake, and render-blocking connection overhead.

---

## 4. Client-Side Rendering & List Virtualization

### DOM Virtualization for Large Data Tables & Lists
Rendering thousands of DOM nodes causes memory bloat, high layout thrashing, and frame drops during scrolling.
- Use windowing / DOM virtualization libraries (`vue-virtual-scroller` for Vue, `react-window` or `@tanstack/react-virtual` for React) to render only the visible viewport slice (+ small buffer).

```vue
<!-- Virtualized list: only visible items exist in DOM -->
<RecycleScroller
  class="scroller"
  :items="largeDataset"
  :item-size="48"
  key-field="id"
  v-slot="{ item }"
>
  <div class="user-row">{{ item.name }}</div>
</RecycleScroller>
```

### Key Stability in Loops
- **Anti-Pattern**: Using array index as loop key (`:key="index"` / `key={index}`). When array items are reordered, prepended, or filtered, the virtual DOM cannot correlate component instances with data records, causing UI state corruption and unnecessary DOM node recreations.
- **Remediation**: Always use stable, unique entity IDs (`:key="item.id"` / `key={item.id}`).

### Reactive Computed Memoization
- Avoid executing expensive filtering, sorting, or nested transformations directly inside template expressions or render cycles.
- Use memoized / reactive computed properties (e.g. `computed()` in Vue, `useMemo()` in React) with granular dependency tracking so calculations only rerun when underlying source collections mutate.


