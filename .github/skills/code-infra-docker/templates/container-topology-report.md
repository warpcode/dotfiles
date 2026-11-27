### Container Infrastructure Overview
- **Base Images**: [e.g., `php:8.3-fpm-alpine`, `node:20-alpine`]
- **Multi-Stage Build**: [Yes / No]
- **Total Services**: [Count] (e.g., `app`, `webserver`, `db`, `redis`)

### Service Topology

```mermaid
graph LR
    User[Client] -->|Port 80/443| Nginx[webserver]
    Nginx -->|FastCGI 9000| App[app / php-fpm]
    App -->|Internal 5432| DB[(postgres)]
    App -->|Internal 6379| Redis[(redis)]
```

### Optimization & Hardening Findings
- **Image Size Improvements**: [e.g. Multi-stage build can reduce final image by ~350MB]
- **Security Recommendations**: [e.g. Add non-root user `appuser`]
