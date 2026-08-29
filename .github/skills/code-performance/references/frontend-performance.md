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

## 3. Asset & Image Optimization

- **Modern Formats**: Serve images in WebP or AVIF formats rather than uncompressed PNG/JPEG.
- **Responsive Images**: Use `srcset` and `sizes` to deliver appropriately sized images per viewport.
- **Font Display**: Apply `font-display: swap` to prevent Flash of Invisible Text (FOIT).

