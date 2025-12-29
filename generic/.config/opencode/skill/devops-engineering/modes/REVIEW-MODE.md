# Review Mode: DevOps Engineering

**Purpose**: Exhaustive review checklists for infrastructure, CI/CD, containers, and DevOps operations

## EXHAUSTIVE LOADING STRATEGY

### Comprehensive Review Checklists
Load all infrastructure and DevOps patterns for exhaustive review:
- **CI/CD**: `@infrastructure/CI-CD.md`
- **Containerization**: `@infrastructure/CONTAINERIZATION.md`
- **Infrastructure as Code**: `@infrastructure/IAC.md`
- **Observability**: `@infrastructure/OBSERVABILITY.md`
- **Container Security**: `@security/CONTAINER-SECURITY.md`
- **Release Strategies**: `@release/RELEASE-STRATEGIES.md`

## CI/CD REVIEW

### Pipeline Issues
- [ ] **Hardcoded Credentials**: Secrets in CI/CD configuration (CRITICAL)
- [ ] **No Caching**: Not caching dependencies/build artifacts (performance)
- [ ] **Sequential Jobs**: Jobs running sequentially when parallel possible (performance)
- [ ] **No Testing**: Pipeline not running tests (quality)
- [ ] **Fragile Pipeline**: Pipeline flaky/unreliable (reliability)
- [ ] **Timeout Issues**: Jobs timing out frequently (performance)
- [ ] **No Version Pinning**: Using latest versions instead of specific versions (stability)
- [ ] **Missing Dependencies**: Jobs failing due to missing dependencies

### Build Issues
- [ ] **No Clean Build**: Not starting from clean state (reproducibility)
- [ ] **Leaky Build**: Previous state affecting build (quality)
- [ ] **No Build Artifacts**: Not storing build artifacts (reproducibility)
- [ ] **Large Build Times**: Builds taking too long (performance)
- [ ] **No Parallel Builds**: Not running builds in parallel (performance)
- [ ] **Missing Unit Tests**: Not running unit tests in pipeline (quality)
- [ ] **Missing Integration Tests**: Not running integration tests (quality)
- [ ] **No Code Coverage**: Not measuring code coverage (quality)

### Deployment Issues
- [ ] **No Staging**: Deploying directly to production (risk)
- [ ] **No Rollback**: No rollback mechanism (risk)
- [ ] **No Health Checks**: Not verifying deployment health (reliability)
- [ ] **Zero-Downtime Missing**: Downtime during deployment (availability)
- [ ] **Database Migrations**: Migrations not handled properly (risk)
- [ ] **Configuration Mismatch**: Wrong config in production (risk)
- [ ] **No Smoke Tests**: Not running smoke tests after deployment (quality)

### CI/CD Security
- [ ] **Secrets in Repo**: Secrets committed to repository (CRITICAL)
- [ ] **Unprivileged Access**: Pipeline running with excessive permissions (CRITICAL)
- [ ] **No Dependency Scanning**: Not scanning for vulnerabilities (security)
- [ ] **No Container Scanning**: Not scanning Docker images (security)
- [ ] **Static Analysis Missing**: Not running SAST (security)
- [ ] **Dynamic Analysis Missing**: Not running DAST (security)
- [ ] **Supply Chain Attacks**: Not verifying supply chain integrity (security)
- [ ] **Dependency Pinning**: Not pinning dependency versions (security)

### Platform-Specific Issues
#### GitHub Actions
- [ ] **No Caching**: Not using `actions/cache` (performance)
- [ ] **Excessive Workflow Runs**: Too many triggered runs (cost)
- [ ] **No Reusable Workflows**: Not using reusable workflows (maintainability)
- [ ] **Self-Hosted Runners**: Security issues with self-hosted runners
- [ ] **Actions Using `latest`**: Not pinning action versions (stability)

#### GitLab CI
- [ ] **No Artifacts Expired**: Artifacts not expiring (storage)
- [ ] **Docker Service Issues**: Docker service configuration issues
- [ ] **Cache Issues**: Not using cache properly (performance)
- [ ] **Runners Not Configured**: Insufficient runner capacity (performance)

#### Jenkins
- [ ] **No Pipeline as Code**: Using UI instead of Jenkinsfile (maintainability)
- [ ] **No Backup**: No Jenkins backup (risk)
- [ ] **Plugin Issues**: Outdated or vulnerable plugins (security/stability)
- [ ] **Node Issues**: Agents not properly configured (reliability)

## CONTAINERIZATION REVIEW

### Dockerfile Issues
- [ ] **Running as Root**: Running containers as root (CRITICAL - security)
- [ ] **No .dockerignore**: Not excluding files from build (performance/security)
- [ ] **Large Image Size**: Unnecessarily large images (performance/cost)
- [ ] **No Multistage Build**: Not using multistage builds (security/performance)
- [ ] **Hardcoded Secrets**: Secrets in Dockerfile (CRITICAL - security)
- [ ] **Using Latest**: Using `latest` tag (stability)
- [ ] **No Health Check**: No health check defined (reliability)
- [ ] **No Resource Limits**: No CPU/memory limits (reliability)
- [ ] **Layers Not Minimized**: Too many layers (performance)
- [ ] **Cache Not Utilized**: Not leveraging Docker cache (performance)
- [ ] **Vulnerable Base Image**: Using outdated base image (security)
- [ ] **Unnecessary Packages**: Installing packages not needed (security/attack surface)

### Docker Compose Issues
- [ ] **No Networks**: Using default network (security/observability)
- [ ] **No Volumes**: Data not persisted (reliability)
- [ ] **No Environment Files**: Secrets in docker-compose.yml (security)
- [ ] **No Resource Limits**: No CPU/memory limits (reliability)
- [ ] **No Health Checks**: No health checks defined (reliability)
- [ ] **Running as Root**: Services running as root (security)
- [ ] **Exposed Ports**: Unnecessary ports exposed (security)
- [ ] **No Restart Policy**: No restart policy defined (reliability)

### Kubernetes Issues
- [ ] **No Resource Limits**: No requests/limits defined (reliability/cost)
- [ ] **No Liveness Probe**: No liveness probe defined (reliability)
- [ ] **No Readiness Probe**: No readiness probe defined (reliability)
- [ ] **No Security Context**: Not defining security context (security)
- [ ] **Privileged Containers**: Running as privileged (CRITICAL - security)
- [ ] **No Network Policies**: No network policies defined (security)
- [ ] **Using `latest`**: Not pinning image versions (stability)
- [ ] **No Replicas**: Single replica (availability)
- [ ] **No Pod Disruption Budget**: No PDB defined (availability)
- [ ] **No Namespace Isolation**: Resources not namespaced (security/organization)
- [ ] **Secrets in Config**: Secrets in ConfigMaps instead of Secrets (security)
- [ ] **No Ingress/Service**: No proper ingress configuration (networking)

### Container Security
- [ ] **Container Escapes**: Potential for container escapes (CRITICAL)
- [ ] **Privilege Escalation**: Running with excessive privileges (CRITICAL)
- [ ] **No Least Privilege**: Not using least privilege (security)
- [ ] **Vulnerable Images**: Using images with known vulnerabilities (security)
- [ ] **No Image Scanning**: Not scanning images for vulnerabilities (security)
- [ ] **Secrets in Images**: Secrets embedded in images (security)
- [ ] **No Rootless**: Not running rootless containers (security)
- [ ] **Cap Dropping**: Not dropping unnecessary Linux capabilities (security)
- [ ] **No Seccomp Profile**: Not using seccomp profiles (security)
- [ ] **No AppArmor Profile**: Not using AppArmor profiles (security)
- [ ] **No Read-Only Filesystem**: Writable filesystem where not needed (security)

## INFRASTRUCTURE AS CODE REVIEW

### Terraform Issues
- [ ] **Hardcoded Values**: Hardcoded values instead of variables (maintainability)
- [ ] **No State Locking**: Not using state locking (race conditions)
- [ ] **State Stored Locally**: State file in repository (security)
- [ ] **No Remote State**: State not stored securely (security/backup)
- [ ] **No Version Pinning**: Provider versions not pinned (stability)
- [ ] **No Backend Config**: Not configuring backend for state (security/backup)
- [ ] **Secrets in State**: Secrets in state file (CRITICAL - security)
- [ ] **No Outputs**: No outputs defined (usability)
- [ ] **No Documentation**: Code not documented (maintainability)
- [ ] **No Tests**: No infrastructure tests (quality)
- [ ] **Large State Files**: State files too large (performance)
- [ ] **Drift Detection**: Not detecting drift between code and actual state

### Ansible Issues
- [ ] **No Idempotency**: Playbooks not idempotent (safety)
- [ ] **No Error Handling**: No error handling (reliability)
- [ ] **No Tags**: Not using tags for selective execution (maintainability)
- [ ] **No Variables File**: Variables in playbooks instead of files (maintainability)
- [ ] **No Vault Usage**: Not using Ansible Vault for secrets (security)
- [ ] **No Check Mode**: Not using check mode (safety)
- [ ] **No Dry Run**: Not testing playbooks before running (safety)
- [ ] **No Version Control**: Not under version control (maintainability)

### CloudFormation Issues
- [ ] **No Parameters**: Hardcoded values instead of parameters (maintainability)
- [ ] **No Outputs**: No outputs defined (usability)
- [ ] **No Mappings**: Not using mappings for cross-region (maintainability)
- [ ] **No Change Sets**: Not using change sets for preview (safety)
- [ ] **No Stack Policies**: Not using stack policies (safety)
- [ ] **Secrets in Templates**: Secrets in CloudFormation templates (security)
- [ ] **Stack Limits**: Exceeding CloudFormation limits

### Infrastructure Security
- [ ] **No Encryption**: Data not encrypted at rest/transit (security)
- [ ] **No Least Privilege**: Excessive IAM roles/permissions (security)
- [ ] **Public Resources**: Unnecessary public access (security)
- [ ] **No Network Segmentation**: No VPC/subnet isolation (security)
- [ ] **No Logging**: No logging enabled (observability/security)
- [ ] **No Backup**: No backup configured (disaster recovery)
- [ ] **No Disaster Recovery**: No disaster recovery plan (availability)
- [ ] **No Compliance**: Not following compliance requirements (compliance)

## OBSERVABILITY REVIEW

### Monitoring Issues
- [ ] **No Metrics**: No metrics collection (observability)
- [ ] **No Alerts**: No alerting configured (reliability)
- [ ] **Alert Fatigue**: Too many alerts (usability)
- [ ] **No SLO/SLI**: No service level objectives defined (reliability)
- [ ] **Missing Critical Metrics**: Critical metrics not monitored (reliability)
- [ ] **No Dashboard**: No monitoring dashboard (usability)
- [ ] **No Error Budget**: No error budget defined (reliability)

### Logging Issues
- [ ] **No Structured Logs**: Logs not structured (observability)
- [ ] **No Log Levels**: Not using appropriate log levels (observability)
- [ ] **Secrets in Logs**: Secrets logged (CRITICAL - security)
- [ ] **No Log Aggregation**: Logs not centralized (observability)
- [ ] **No Log Retention**: No log retention policy (compliance/storage)
- [ ] **No Search**: Logs not searchable (troubleshooting)
- [ ] **No Log Sampling**: No sampling for high-volume logs (cost)

### Tracing Issues
- [ ] **No Distributed Tracing**: No tracing for microservices (troubleshooting)
- [ ] **No Trace Context**: Trace context not propagated (troubleshooting)
- [ ] **No Span Naming**: Inconsistent span naming (usability)
- [ ] **No Trace Sampling**: No sampling for high-volume traces (cost)
- [ ] **Trace Storage Costs**: Excessive trace storage costs (cost)

### Alerting Issues
- [ ] **False Positives**: Too many false alerts (usability)
- [ ] **No Escalation**: No alert escalation (reliability)
- [ ] **No On-Call**: No on-call rotation (reliability)
- [ ] **No Runbooks**: No runbooks for alerts (maintainability)
- [ ] **Alert Latency**: Alerts delayed (reliability)
- [ ] **No Severity Levels**: All alerts same priority (usability)

## RELEASE STRATEGIES REVIEW

### Deployment Issues
- [ ] **No Blue-Green**: Not using blue-green deployments (risk)
- [ ] **No Canary**: Not using canary deployments (risk)
- [ ] **No Rolling Updates**: Not using rolling updates (availability)
- [ ] **No A/B Testing**: No A/B testing capability (business)
- [ ] **No Feature Flags**: Not using feature flags (flexibility)
- [ ] **Database Migrations**: Not handling migrations properly (risk)
- [ ] **No Zero-Downtime**: Downtime during deployments (availability)
- [ ] **No Rollback**: No rollback mechanism (risk)
- [ ] **No Traffic Shifting**: Not controlling traffic during rollout (risk)

### Release Issues
- [ ] **No Semver**: Not using semantic versioning (maintainability)
- [ ] **No Changelog**: No changelog (maintainability)
- [ ] **No Release Notes**: No release notes (usability)
- [ ] **No Tagging**: Not tagging releases (maintainability)
- [ ] **No Branching Strategy**: No branching strategy (maintainability)

### Database Migration Issues
- [ ] **No Idempotency**: Migrations not idempotent (safety)
- [ ] **No Rollback**: No rollback mechanism (risk)
- [ ] **No Backward Compatibility**: Breaking changes (risk)
- [ ] **No Data Validation**: Not validating data (quality)
- [ ] **No Performance Testing**: Not testing migration performance (performance)
- [ ] **Large Migrations**: Single migration too large (risk/performance)

## PLATFORM-SPECIFIC ISSUES

### AWS
- [ ] **No Cost Monitoring**: No cost monitoring/anomaly detection (cost)
- [ ] **Unused Resources**: Unused EC2, RDS, etc. (cost)
- [ ] **No Reserved Instances**: Not using reserved instances where applicable (cost)
- [ ] **No Security Groups**: Security groups too permissive (security)
- [ ] **No S3 Versioning**: Not using versioning on critical buckets (data loss)
- [ ] **No IAM Policies**: Excessive permissions (security)
- [ ] **No CloudTrail**: No CloudTrail enabled (security/audit)
- [ ] **No GuardDuty**: Not using GuardDuty (security)

### GCP
- [ ] **No Billing Alerts**: No billing alerts configured (cost)
- [ ] **No Organization Policies**: No organization policies (security/compliance)
- [ ] **No IAM Roles**: Excessive permissions (security)
- [ ] **No Cloud Audit Logs**: No audit logging (security/audit)
- [ ] **Unused Resources**: Unused resources (cost)

### Azure
- [ ] **No Cost Alerts**: No cost alerts configured (cost)
- [ ] **No Azure Policy**: No Azure policies (security/compliance)
- [ ] **No RBAC**: Excessive permissions (security)
- [ ] **No Azure Monitor**: No monitoring configured (reliability)
- [ ] **Unused Resources**: Unused resources (cost)

## OUTPUT FORMAT

### Review Report Output
```markdown
## DevOps Infrastructure Review Report

### Critical Issues (CRITICAL - Fix Immediately)

1. **[Issue Name]**: [Component/File]
   - Severity: CRITICAL
   - Category: [CI-CD/Containerization/IaC/Observability/Security]
   - Description: [Detailed issue description]
   - Impact: [What could happen if not fixed]
   - Fix: [Specific remediation steps]
   - Example: [Before/After configuration examples]
   - Reference: @infrastructure/[SPECIFIC-PATTERN].md or @security/CONTAINER-SECURITY.md

### High Priority Issues (HIGH - Fix Soon)

[Same format as Critical]

### Medium Priority Issues (MEDIUM - Consider Fixing)

[Same format as Critical]

### Low Priority Issues (LOW - Nice to Have)

[Same format as Critical]

### CI/CD Issues
- **Pipeline Issues**: [List of issues]
- **Security Issues**: [SAST/DAST/container scanning issues]
- **Platform Specific**: [GitHub/GitLab/Jenkins specific issues]

### Container Issues
- **Dockerfile Issues**: [List of issues with line numbers]
- **Docker Compose Issues**: [List of issues]
- **Kubernetes Issues**: [List of issues]
- **Security**: [Container security issues]

### Infrastructure as Code Issues
- **Terraform Issues**: [List of issues]
- **Ansible Issues**: [List of issues]
- **Security**: [IaC security issues]

### Observability Issues
- **Monitoring**: [Missing metrics, alerts]
- **Logging**: [Logging issues]
- **Tracing**: [Tracing issues]
- **Alerting**: [Alerting issues]

### Release Issues
- **Deployment Strategy**: [Current strategy and issues]
- **Migration Issues**: [Database migration issues]
- **Rollback Issues**: [Rollback capability issues]

### Platform-Specific Issues
- **AWS**: [AWS-specific issues]
- **GCP**: [GCP-specific issues]
- **Azure**: [Azure-specific issues]

### Recommendations
1. [Infrastructure improvement]
2. [Security improvement]
3. [Performance improvement]
4. [Cost optimization]

### Related Skills
- @database-engineering/SKILL.md (for database migrations, query optimization)
- @secops-engineering/SKILL.md (for security best practices)
- @software-engineering/SKILL.md (for build system issues)
```
