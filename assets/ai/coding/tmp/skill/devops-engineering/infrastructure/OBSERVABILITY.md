# OBSERVABILITY

## OVERVIEW
Observability is the ability to understand system behavior through metrics, logs, and traces. It enables debugging, performance optimization, and proactive issue detection.

## OBSERVABILITY PILLARS

### 1. Metrics
**Definition**: Numeric measurements over time.

**Types**:
- **Counter**: Monotonically increasing value (requests, errors)
- **Gauge**: Current value (memory usage, queue length)
- **Histogram**: Distribution of values (request duration)
- **Summary**: Count, sum, quantiles (response time percentiles)

**Example (Prometheus)**:
```go
// Counter: Total HTTP requests
var httpRequestsTotal = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "http_requests_total",
        Help: "Total number of HTTP requests",
    },
    []string{"method", "endpoint", "status"},
)

// Gauge: Current connections
var activeConnections = prometheus.NewGauge(
    prometheus.GaugeOpts{
        Name: "active_connections",
        Help: "Current number of active connections",
    },
)

// Histogram: Request duration
var httpRequestDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name: "http_request_duration_seconds",
        Help: "HTTP request duration in seconds",
        Buckets: prometheus.DefBuckets,
    },
    []string{"method", "endpoint"},
)

// Recording metrics
httpRequestsTotal.WithLabelValues("GET", "/api/users", "200").Inc()
activeConnections.Set(42)
httpRequestDuration.WithLabelValues("GET", "/api/users").Observe(0.123)
```

---

### 2. Logs

**Definition**: Discrete events with structured data.

**Structured Logging (JSON)**:
```javascript
// BAD: Unstructured logs
console.log('User logged in');
console.log(`User ${userId} failed to login from ${ip}`);

// GOOD: Structured logs
const logger = require('pino')();

logger.info({
    event: 'user_login',
    userId: 123,
    ip: '192.168.1.1',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
});

logger.error({
    event: 'login_failed',
    userId: 123,
    ip: '192.168.1.1',
    reason: 'invalid_password',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
});
```

**Log Levels**:
```javascript
logger.trace('Very detailed logging');
logger.debug('Debugging information');
logger.info('Informational messages');
logger.warn('Warning messages');
logger.error('Error messages');
logger.fatal('Fatal errors');
```

**Log Rotation (Winston)**:
```javascript
const winston = require('winston');

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    transports: [
        // Console logging
        new winston.transports.Console(),

        // File logging with rotation
        new winston.transports.File({
            filename: 'logs/error.log',
            level: 'error',
            maxsize: 5242880,  // 5MB
            maxFiles: 5,
        }),

        new winston.transports.File({
            filename: 'logs/combined.log',
            maxsize: 5242880,
            maxFiles: 5,
        }),
    ],
});
```

---

### 3. Tracing

**Definition**: Distributed tracking of a request across services.

**OpenTelemetry Tracing**:
```javascript
const { trace } = require('@opentelemetry/api');
const { BasicTracerProvider, SimpleSpanProcessor } = require('@opentelemetry/sdk-trace-base');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

const provider = new BasicTracerProvider();
provider.addSpanProcessor(new SimpleSpanProcessor(new JaegerExporter()));
trace.setGlobalTracerProvider(provider);

const tracer = trace.getTracer('my-service');

async function handleRequest(req, res) {
    const span = tracer.startSpan('handleRequest');

    try {
        span.setAttribute('http.method', req.method);
        span.setAttribute('http.url', req.url);

        // Database call
        const dbSpan = tracer.startSpan('database_query', { parent: span });
        const user = await db.getUser(req.params.id);
        dbSpan.end();

        // External API call
        const apiSpan = tracer.startSpan('external_api', { parent: span });
        const result = await externalAPI.call(user.id);
        apiSpan.end();

        res.json(result);
    } catch (error) {
        span.recordException(error);
        span.setStatus({ code: 2, message: error.message });
        throw error;
    } finally {
        span.end();
    }
}
```

**Trace Visualization**:
```
[HTTP Request]
  ├─ [Database Query] 50ms
  └─ [External API] 200ms
     └─ [Cache Hit] 10ms

Total: 260ms
```

---

## METRICS COLLECTION

### Prometheus

**Installation**:
```yaml
# docker-compose.yml
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
```

**Configuration (prometheus.yml)**:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'myapp'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: /metrics

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

**Prometheus Metrics Endpoint (Node.js)**:
```javascript
const client = require('prom-client');

const register = new client.Registry();

// Metrics
const httpRequestDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration',
    labelNames: ['method', 'route', 'status'],
    registers: [register]
});

// Express middleware
app.use((req, res, next) => {
    const start = Date.now();

    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        httpRequestDuration
            .labels(req.method, req.route, res.statusCode)
            .observe(duration);
    });

    next();
});

// Expose metrics
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});
```

---

## ALERTING

### AlertManager (Prometheus)

**Configuration (alertmanager.yml)**:
```yaml
global:
  resolve_timeout: 5m

route:
  receiver: 'default'

  # Route based on severity
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 30s
    group_interval: 5m

  - match:
      severity: warning
    receiver: 'warning-alerts'
    group_wait: 5m
    group_interval: 10m

receivers:
- name: 'critical-alerts'
  pagerduty_configs:
  - service_key: 'YOUR_SERVICE_KEY'

- name: 'warning-alerts'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK'
    channel: '#alerts'

- name: 'default'
  email_configs:
  - to: 'team@example.com'
```

**Alert Rules (Prometheus)**:
```yaml
# alerts.yml
groups:
  - name: application_alerts
    rules:
    # High error rate
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} errors/sec"

    # High latency
    - alert: HighLatency
      expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High latency detected"
        description: "95th percentile latency is {{ $value }}s"

    # Low available replicas
    - alert: LowReplicas
      expr: kube_deployment_status_replicas_available / kube_deployment_spec_replicas < 0.8
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "Low available replicas"
        description: "Only {{ $value * 100 }}% replicas available"
```

---

## DASHBOARDING

### Grafana

**Dashboard Example**:
```json
{
  "dashboard": {
    "title": "Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[1m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])",
            "legendFormat": "{{status}}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "95th Percentile Latency",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds)",
            "legendFormat": "P95 Latency"
          }
        ],
        "type": "singlestat"
      },
      {
        "title": "Active Connections",
        "targets": [
          {
            "expr": "active_connections",
            "legendFormat": "Connections"
          }
        ],
        "type": "singlestat"
      }
    ]
  }
}
```

---

## BEST PRACTICES

### 1. Golden Signals (Google SRE)
1. **Latency**: Time to service requests
2. **Traffic**: Request volume
3. **Errors**: Request failures
4. **Saturation**: System utilization (CPU, memory, disk)

### 2. RED Method (Weaveworks)
1. **Rate**: Requests per second
2. **Errors**: Failed requests
3. **Duration**: Request latency

### 3. USE Method (Brendan Gregg)
1. **Utilization**: How busy is the resource?
2. **Saturation**: How full is the resource?
3. **Errors**: Resource errors?

### 4. Metric Naming
```go
// GOOD: Clear, descriptive names
http_requests_total  // Counter
http_request_duration_seconds  // Histogram in seconds
memory_usage_bytes  // Gauge with units
disk_io_operations_total  // Counter

// AVOID: Ambiguous names
requests  // What type of request?
time  // Time of what? duration? timestamp?
size  // Size in bytes? count?
```

### 5. Cardinality Management
```go
// BAD: High cardinality (user_id can be millions)
http_requests_total.WithLabelValues(user_id).Inc()

// GOOD: Low cardinality (limited values)
http_requests_total.WithLabelValues(method, endpoint, status).Inc()
```

---

## CROSS-REFERENCES
- For CI/CD patterns: @infrastructure/CI-CD.md
- For container patterns: @infrastructure/CONTAINERIZATION.md
- For IaC patterns: @infrastructure/IAC.md
