# RELEASE STRATEGIES

## OVERVIEW
Release strategies define how new code deployments are rolled out to production, balancing speed of delivery with risk mitigation.

## RELEASE STRATEGY COMPARISON

| Strategy | Rollback Speed | Risk Level | Complexity | Zero Downtime |
|-----------|---------------|-------------|-------------|-----------------|
| Recreate | Fast | High | Low | No |
| Rolling | Medium | Medium | Medium | Yes |
| Blue-Green | Very Fast | Low | High | Yes |
| Canary | Fast | Very Low | High | Yes |
| A/B Testing | Fast | Low | High | Yes |

---

## 1. RECREATE STRATEGY

**Definition**: Stop all old instances, start all new instances.

**Pros**:
- Simple
- Fast rollback (just switch back)

**Cons**:
- Downtime during deployment
- High risk (if new version fails, all instances down)

**Example (Kubernetes)**:
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

**Deployment Flow**:
```
1. Stop all v1 pods (3 down)
2. Start v2 pods (0 up → 1 up → 2 up → 3 up)

Result: ~30s downtime
```

---

## 2. ROLLING UPDATE STRATEGY

**Definition**: Gradually replace old instances with new ones.

**Pros**:
- No downtime (some instances always up)
- Faster than blue-green
- Less infrastructure needed

**Cons**:
- Risk of running both versions simultaneously
- Rollback requires gradual reversal
- Harder to test new version

**Example (Kubernetes)**:
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Add 1 extra pod during update
      maxUnavailable: 1    # Allow 1 pod unavailable during update
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v2.0
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

**Deployment Flow**:
```
Initial: v1.0 (3 pods)

Step 1: Start v2.0 (1 pod)
        v1.0 (3 pods) + v2.0 (1 pod) = 4 total

Step 2: Stop v1.0 (1 pod)
        v1.0 (2 pods) + v2.0 (1 pod) = 3 total

Step 3: Start v2.0 (1 pod)
        v1.0 (2 pods) + v2.0 (2 pods) = 4 total

Step 4: Stop v1.0 (1 pod)
        v1.0 (1 pod) + v2.0 (2 pods) = 3 total

Step 5: Start v2.0 (1 pod)
        v1.0 (1 pod) + v2.0 (3 pods) = 4 total

Step 6: Stop v1.0 (1 pod)
        v2.0 (3 pods) = 3 total

Result: Zero downtime
```

**Rollback**:
```bash
# Just change image back to v1.0
kubectl set image deployment/myapp myapp=myapp:v1.0
```

---

## 3. BLUE-GREEN DEPLOYMENT

**Definition**: Maintain two identical environments (blue and green), switch traffic between them.

**Pros**:
- Instant rollback (just switch traffic)
- Can test green before switch
- Zero downtime
- Easy to compare versions

**Cons**:
- Requires 2x infrastructure
- Complex database migration handling
- Higher cost

**Example (Kubernetes)**:

**Blue Deployment** (v1.0):
```yaml
# blue-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      color: blue
  template:
    metadata:
      labels:
        app: myapp
        color: blue
    spec:
      containers:
      - name: myapp
        image: myapp:v1.0
```

**Green Deployment** (v2.0):
```yaml
# green-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      color: green
  template:
    metadata:
      labels:
        app: myapp
        color: green
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

**Service** (switches traffic):
```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    color: blue  # Select blue deployment
  ports:
  - port: 80
    targetPort: 8080
```

**Deployment Flow**:
```
Initial:
  - Blue (v1.0): 100% traffic
  - Green (v2.0): 0% traffic (just created)

Deploy Green:
  1. Deploy v2.0 to green (0% traffic)
  2. Test green (health checks, smoke tests)
  3. Switch service selector to green
  4. Green (v2.0): 100% traffic
  5. Blue (v1.0): 0% traffic (kept for rollback)

Rollback (if needed):
  1. Switch service selector back to blue
  2. Blue (v1.0): 100% traffic
  3. Green (v2.0): 0% traffic
```

**Traffic Switch (Argo Rollouts)**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    blueGreen:
      activeService: myapp-active
      previewService: myapp-preview
      autoPromotionEnabled: false  # Manual promotion
      previewReplicaCount: 1
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

---

## 4. CANARY DEPLOYMENT

**Definition**: Gradually roll out new version to small percentage of traffic.

**Pros**:
- Low risk (only small subset affected)
- Fast detection of issues
- Can test with real users
- Easy to rollback

**Cons**:
- Complex monitoring needed
- Database migrations challenging
- Both versions run simultaneously

**Example (Kubernetes with Argo Rollouts)**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 10    # 10% traffic to v2.0
      - pause: {}        # Wait for manual approval
      - setWeight: 25    # 25% traffic
      - pause: {duration: 10m}  # Wait 10 minutes
      - setWeight: 50    # 50% traffic
      - pause: {duration: 10m}
      - setWeight: 100   # 100% traffic
      canaryService: myapp-canary
      stableService: myapp-stable
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v2.0
```

**Deployment Flow**:
```
Initial:
  - Stable (v1.0): 100% traffic
  - Canary (v2.0): 0% traffic

Step 1: 10% canary
  - Stable (v1.0): 90% traffic
  - Canary (v2.0): 10% traffic
  - Monitor: Check error rate, latency, crashes

Step 2: Approval after monitoring
  - If issues: Rollback (setWeight: 0)
  - If OK: Continue

Step 3: 25% canary
  - Stable (v1.0): 75% traffic
  - Canary (v2.0): 25% traffic
  - Monitor: 10 minutes

Step 4: 50% canary
  - Stable (v1.0): 50% traffic
  - Canary (v2.0): 50% traffic
  - Monitor: 10 minutes

Step 5: 100% stable (full rollout)
  - Stable (v2.0): 100% traffic
  - Canary: 0 traffic (delete canary)
```

**Automated Canary (Flagger)**:
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  service:
    port: 80
    targetPort: 8080
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
```

---

## 5. A/B TESTING

**Definition**: Deploy different versions to different user segments for feature testing.

**Pros**:
- Test user behavior
- Measure conversion rates
- Low risk

**Cons**:
- Complex routing logic
- Requires user segmentation
- Not for critical bug fixes

**Example (Istio)**:
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.example.com
  http:
  - match:
    - headers:
        x-user-segment:
          exact: beta
    route:
    - destination:
        host: myapp
        subset: v2  # Beta users get v2.0
      weight: 100
  - route:
    - destination:
        host: myapp
        subset: v1  # Other users get v1.0
      weight: 100
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  subsets:
  - name: v1
    labels:
      version: v1.0
  - name: v2
    labels:
      version: v2.0
```

---

## FEATURE FLAGS

**Purpose**: Deploy code to all users but enable/disable features dynamically.

**Benefits**:
- Instant rollback (just disable flag)
- Test features with subsets of users
- No new deployment needed

**Example**:
```javascript
// Frontend
if (featureFlags.isEnabled('new-checkout-flow')) {
  renderNewCheckoutFlow();
} else {
  renderOldCheckoutFlow();
}

// Backend
if (featureFlags.isEnabled('caching-strategy', user.id)) {
  return cache.get(key);
} else {
  return database.query(key);
}
```

---

## ROLLBACK STRATEGIES

### 1. Database Migrations with Rollback

```bash
# Migration file
BEGIN;
-- Change v1.0 → v2.0
ALTER TABLE users ADD COLUMN new_column VARCHAR(255);
COMMIT;

-- Rollback file
BEGIN;
-- Change v2.0 → v1.0
ALTER TABLE users DROP COLUMN new_column;
COMMIT;
```

**Deployment with Migrations**:
```
1. Deploy v2.0 code (works with v1.0 database)
2. Run v1.0 → v2.0 migration
3. Verify system works
4. If issues: Rollback code, keep v2.0 database (compatible with v1.0 code)
```

---

### 2. Feature Flag Rollback

```javascript
// Instant rollback without deployment
featureFlags.disable('new-feature');
```

---

## MONITORING & VALIDATION

### Canary Monitoring

```yaml
# Alert if canary error rate higher than stable
alert: CanaryErrorRateHigh
expr: |
  rate(http_requests_total{version="v2.0",status=~"5.."}[5m]) /
  rate(http_requests_total[5m]) > 0.05
for: 5m
annotations:
  summary: "Canary error rate 5% higher than stable"
```

---

## BEST PRACTICES

### 1. Automated Testing Before Switch
- Run smoke tests on new version
- Run integration tests
- Monitor for 5-10 minutes

### 2. Gradual Rollout
- Start with 10-20% of users
- Monitor metrics carefully
- Increase gradually

### 3. Always Have Rollback Plan
- Know rollback commands
- Have rollback tested
- Document rollback procedure

### 4. Database Compatibility
- Deploy code first (backward compatible)
- Run migrations
- Verify
- Rollback code if issues (migrations stay)

### 5. Feature Flags for Risky Changes
- Use feature flags for new features
- Enable to small subset
- Rollback by disabling flag

---

## CROSS-REFERENCES
- For CI/CD patterns: @infrastructure/CI-CD.md
- For container patterns: @infrastructure/CONTAINERIZATION.md
- For monitoring: @infrastructure/OBSERVABILITY.md
