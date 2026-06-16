# CI/CD PIPELINES

## OVERVIEW
Continuous Integration and Continuous Deployment (CI/CD) automate the build, test, and deployment process, enabling frequent, reliable releases.

## CI/CD PRINCIPLES

### 1. Continuous Integration (CI)
- Commit frequently (multiple times per day)
- Automated builds on every commit
- Automated tests on every build
- Fast feedback (builds complete in < 10 minutes)
- Fix failing builds immediately

### 2. Continuous Deployment (CD)
- Automated deployment to production
- Manual approval gates for critical changes
- Rollback capability
- Zero-downtime deployments
- Gradual rollout strategies

---

## PIPELINE STAGES

### 1. Build Stage

**Purpose**: Compile code, install dependencies, prepare artifacts.

**Example (GitHub Actions)**:
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.2'

    - name: Install dependencies
      run: composer install --no-dev --prefer-dist

    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: vendor
        key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
```

---

### 2. Test Stage

**Purpose**: Run automated tests, check code quality.

**Example (PHPUnit)**:
```yaml
  test:
    needs: build
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.2'

    - name: Install dependencies
      run: composer install

    - name: Run tests
      run: vendor/bin/phpunit --coverage-clover=coverage.xml

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

    - name: Run code quality
      run: vendor/bin/phpstan analyse --error-format=github

    - name: Run security check
      run: vendor/bin/audit --no-dev
```

---

### 3. Build Artifacts

**Purpose**: Create deployable artifacts (Docker images, compiled code, packages).

**Example (Docker Build)**:
```yaml
  build-image:
    needs: test
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build Docker image
      run: |
        docker build -t myapp:${{ github.sha }} .
        docker tag myapp:${{ github.sha }} myapp:latest

    - name: Login to registry
      run: echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin

    - name: Push image
      run: docker push myapp:${{ github.sha }}
```

---

### 4. Deploy Stage

**Purpose**: Deploy to environments (staging, production).

**Example (Kubernetes Deployment)**:
```yaml
  deploy-staging:
    needs: build-image
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'

    steps:
    - name: Configure kubectl
      run: |
        echo ${{ secrets.KUBE_CONFIG }} | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy to staging
      run: |
        kubectl set image deployment/myapp-staging \
          myapp=myapp:${{ github.sha }} \
          --namespace=staging
        kubectl rollout status deployment/myapp-staging \
          --namespace=staging
```

---

## PIPELINE PATTERNS

### 1. Sequential vs Parallel Execution

**Sequential (safe)**:
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps: [...]

  test:
    needs: lint
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps: [...]
```

**Parallel (fast)**:
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps: [...]

  test:
    runs-on: ubuntu-latest  # Runs in parallel with lint
    steps: [...]

  security:
    runs-on: ubuntu-latest  # Runs in parallel
    steps: [...]

  deploy:
    needs: [lint, test, security]  # Waits for all
    runs-on: ubuntu-latest
    steps: [...]
```

---

### 2. Environment-Specific Pipelines

**Staging Pipeline**:
```yaml
# Triggers: develop branch
on:
  push:
    branches: [ develop ]

jobs:
  deploy-staging:
    steps:
    - name: Deploy to staging
      run: ./deploy.sh staging
```

**Production Pipeline**:
```yaml
# Triggers: main branch + manual approval
on:
  push:
    branches: [ main ]

jobs:
  deploy-production:
    environment:
      name: production
      url: https://app.example.com

    steps:
    - name: Deploy to production
      run: ./deploy.sh production
```

---

### 3. Rollback Strategy

**Automatic Rollback on Failure**:
```yaml
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Deploy new version
      id: deploy
      run: kubectl set image deployment/myapp myapp=myapp:${{ github.sha }}

    - name: Wait for rollout
      run: kubectl rollout status deployment/myapp --timeout=300s

    - name: Health check
      run: ./health-check.sh

    - name: Rollback on failure
      if: failure()
      run: kubectl rollout undo deployment/myapp
```

---

## SECURITY INTEGRATION

### 1. Dependency Scanning
```yaml
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Run security audit
      run: |
        composer audit
        npm audit
        pip-audit

    - name: Generate SARIF report
      run: ./generate-sarif.sh
```

### 2. Container Image Scanning
```yaml
  image-scan:
    needs: build-image
    runs-on: ubuntu-latest
    steps:
    - name: Scan image for vulnerabilities
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: myapp:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

---

## MONITORING & NOTIFICATIONS

### 1. Pipeline Metrics
```yaml
jobs:
  monitor:
    needs: [test, deploy]
    runs-on: ubuntu-latest
    steps:
    - name: Record metrics
      run: |
        # Send build time to monitoring system
        curl -X POST https://metrics.example.com/api/builds \
          -H "Authorization: Bearer ${{ secrets.METRICS_TOKEN }}" \
          -d '{
            "status": "success",
            "duration": "${{ job.duration }}",
            "commit": "${{ github.sha }}",
            "branch": "${{ github.ref_name }}"
          }'

    - name: Send Slack notification
      if: success()
      uses: slackapi/slack-github-action@v1
      with:
        payload: |
          {
            "text": "✅ Deploy successful to production",
            "blocks": [
              {
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "Commit: ${{ github.sha }}\nBranch: ${{ github.ref_name }}"
                }
              }
            ]
          }
```

---

## BEST PRACTICES

### 1. Fast Feedback
- Parallelize independent jobs
- Cache dependencies
- Only test changed code (if possible)
- Target: < 10 minutes for full pipeline

### 2. Idempotent Deployments
- Same deployment repeated multiple times produces same result
- Handle "already exists" errors gracefully
- Use upsert operations instead of create

### 3. Immutable Infrastructure
- Never modify running containers
- Replace containers instead of updating
- Build new images, don't patch

### 4. Security First
- Scan dependencies
- Scan container images
- Enforce policies (e.g., no high-severity vulnerabilities)
- Sign artifacts

### 5. Visibility
- Log all pipeline steps
- Store artifacts
- Track build metrics
- Send notifications on failures

---

## COMMON MISTAKES

### 1. Skipping Tests
```yaml
# BAD: Skipping tests for speed
deploy:
  steps:
  - run: ./deploy.sh  # No tests!
```

### 2. Hard-coded Credentials
```yaml
# BAD: Secrets in pipeline
deploy:
  steps:
  - run: echo "password=secret123" > .env

# GOOD: Use secrets
deploy:
  steps:
  - run: echo "password=${{ secrets.DATABASE_PASSWORD }}" > .env
```

### 3. No Rollback Capability
```yaml
# BAD: No rollback on failure
deploy:
  steps:
  - run: ./deploy.sh  # If this fails, system is broken
```

### 4. Manual Deployments
```yaml
# BAD: Manual approval for every deployment
deploy:
  needs: test
  environment: production  # Requires approval every time
  steps:
  - run: ./deploy.sh

# GOOD: Automated deployments with manual gates only for critical changes
deploy:
  needs: test
  if: github.ref == 'refs/heads/main'
  steps:
  - run: ./deploy.sh
```

---

## CROSS-REFERENCES
- For container patterns: @infrastructure/CONTAINERIZATION.md
- For IaC patterns: @infrastructure/IAC.md
- For release strategies: @release/RELEASE-STRATEGIES.md
- For container security: @security/CONTAINER-SECURITY.md
