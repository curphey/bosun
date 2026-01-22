---
name: bosun-devops
description: DevOps, CI/CD, and Infrastructure as Code best practices. Use when reviewing Dockerfiles, Kubernetes manifests, Terraform configurations, CI/CD pipelines, or monitoring setups. Provides IaC security patterns, deployment strategies, and observability guidance.
tags: [devops, docker, kubernetes, terraform, iac, cicd, monitoring, observability]
---

# Bosun DevOps Skill

Comprehensive DevOps knowledge base covering infrastructure as code, CI/CD pipelines, containerization, orchestration, and observability.

## When to Use

- Reviewing Dockerfiles and container configurations
- Analyzing Kubernetes manifests and Helm charts
- Evaluating Terraform, CloudFormation, or Pulumi configurations
- Reviewing CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins)
- Setting up monitoring, logging, and alerting
- Designing deployment strategies
- Implementing infrastructure security

## When NOT to Use

- Application-level security (use bosun-security)
- General architecture decisions (use bosun-architect)
- Language-specific code review (use language skills)
- Performance optimization (use bosun-performance)

## CI/CD Pipeline Patterns

### Pipeline Stages
```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  Build  │ → │  Test   │ → │  Scan   │ → │ Deploy  │ → │ Verify  │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### GitHub Actions Best Practices

```yaml
# Good: Pin actions to SHA
uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608  # v4.1.0

# Bad: Floating tag allows supply chain attacks
uses: actions/checkout@v4

# Good: Minimal permissions
permissions:
  contents: read
  pull-requests: write

# Bad: Default permissions (often too broad)
# permissions: write-all
```

| Pattern | Issue | Fix |
|---------|-------|-----|
| `uses: action@master` | Supply chain risk | Pin to SHA |
| `pull_request_target` | Code injection risk | Use `pull_request` |
| Secrets in logs | Credential exposure | Use `add-mask` |
| No timeout | Stuck jobs waste resources | Set `timeout-minutes` |
| No concurrency control | Parallel deploys conflict | Use `concurrency` group |

### GitLab CI Patterns

```yaml
# Good: Use rules instead of only/except
rules:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Good: Cache dependencies
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/

# Good: Use artifacts for stage outputs
artifacts:
  paths:
    - dist/
  expire_in: 1 week
```

## Container Best Practices

### Dockerfile Patterns

```dockerfile
# GOOD: Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
# Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

| Pattern | Issue | Fix |
|---------|-------|-----|
| `FROM image:latest` | Non-reproducible builds | Pin specific version |
| `USER root` | Security risk | Use non-root user |
| `ADD` for local files | Unexpected behavior | Use `COPY` |
| Secrets in `ENV` | Persisted in layers | Use `--mount=type=secret` |
| Single stage build | Large image size | Use multi-stage builds |
| No `.dockerignore` | Slow builds, secrets leak | Add `.dockerignore` |
| `apt-get upgrade` | Non-reproducible | Pin package versions |

### Container Security Scanning

```bash
# Trivy - vulnerability scanner
trivy image myapp:latest

# Grype - SBOM-based scanning
grype myapp:latest

# Docker Scout
docker scout cves myapp:latest

# Hadolint - Dockerfile linter
hadolint Dockerfile
```

## Kubernetes Best Practices

### Pod Security

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:v1.2.3
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "500m"
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

| Pattern | Issue | Fix |
|---------|-------|-----|
| `privileged: true` | Container escape risk | Remove or use capabilities |
| Missing resource limits | Resource exhaustion | Set CPU/memory limits |
| `runAsRoot` | Privilege escalation | `runAsNonRoot: true` |
| No network policies | Lateral movement | Define ingress/egress rules |
| No pod security standards | Weak defaults | Use `restricted` policy |
| Missing probes | Unhealthy pods serve traffic | Add liveness/readiness |
| `imagePullPolicy: Always` | Slow deployments | Use specific tags |

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
```

## Infrastructure as Code

### Terraform Best Practices

```hcl
# Good: Pin provider versions
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-prod"
    key    = "app/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    dynamodb_table = "terraform-locks"
  }
}

# Good: Use variables with validation
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Good: Use locals for computed values
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
  }
}

# Good: Output important values
output "api_endpoint" {
  value       = aws_api_gateway_stage.main.invoke_url
  description = "API Gateway endpoint URL"
}
```

| Pattern | Issue | Fix |
|---------|-------|-----|
| Unpinned versions | Drift risk | Pin provider/module versions |
| Local state | Collaboration issues | Use remote backend |
| Hardcoded values | Inflexible | Use variables |
| Missing tags | Cost tracking issues | Add required tags |
| No state locking | Race conditions | Enable DynamoDB locking |
| Secrets in state | Exposure risk | Use secrets manager |

### Terraform Security Scanning

```bash
# tfsec - security scanner
tfsec .

# checkov - policy-as-code
checkov -d .

# terrascan - compliance
terrascan scan -t aws

# Infracost - cost estimation
infracost breakdown --path .
```

## Deployment Strategies

### Blue-Green Deployment
```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼────────┐    │    ┌─────────▼────────┐
     │   Blue (v1.0)   │    │    │  Green (v1.1)    │
     │   [Active]      │    │    │  [Standby]       │
     └─────────────────┘    │    └──────────────────┘
                            │
              Switch traffic instantly
```

### Canary Deployment
```yaml
# Kubernetes: Gradual traffic shift
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
  - route:
    - destination:
        host: myapp
        subset: stable
      weight: 90
    - destination:
        host: myapp
        subset: canary
      weight: 10
```

### Rolling Update
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%        # Max pods over desired
      maxUnavailable: 25%  # Max pods unavailable
```

## Monitoring & Observability

### Three Pillars

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   Metrics   │   │    Logs     │   │   Traces    │
│ (Prometheus)│   │   (Loki)    │   │  (Jaeger)   │
└─────────────┘   └─────────────┘   └─────────────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                  ┌──────▼──────┐
                  │   Grafana   │
                  └─────────────┘
```

### Prometheus Metrics

```yaml
# ServiceMonitor for Prometheus Operator
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics
```

### Key Metrics (RED Method)

| Metric | Description | Example |
|--------|-------------|---------|
| **R**ate | Requests per second | `rate(http_requests_total[5m])` |
| **E**rrors | Error rate | `rate(http_requests_total{status=~"5.."}[5m])` |
| **D**uration | Request latency | `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))` |

### Alerting Rules

```yaml
groups:
- name: app-alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total[5m])) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: HighLatency
    expr: |
      histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High latency detected"
      description: "P99 latency is {{ $value | humanizeDuration }}"
```

### Structured Logging

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "error",
  "message": "Failed to process order",
  "service": "order-service",
  "trace_id": "abc123",
  "span_id": "def456",
  "order_id": "ord-789",
  "error": "payment declined",
  "duration_ms": 1234
}
```

## Secrets Management

### Kubernetes Secrets

```yaml
# External Secrets Operator (preferred)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: app-secrets
  data:
  - secretKey: database-url
    remoteRef:
      key: prod/app/database
      property: url
```

| Method | Security | Complexity | Use Case |
|--------|----------|------------|----------|
| ConfigMaps | None | Low | Non-sensitive config |
| K8s Secrets | Base64 only | Low | Dev/test only |
| Sealed Secrets | Encrypted at rest | Medium | GitOps workflows |
| External Secrets | External vault | Medium | Production |
| HashiCorp Vault | Full encryption | High | Enterprise |

## References

See `references/` directory for detailed documentation:
- `quick-reference.md` - Security scanning tools, common ports, CLI commands
- `gitops.md` - GitOps patterns, ArgoCD, Flux configurations
- `docker/` - Dockerfile patterns and security
- `iac-best-practices/` - Terraform, K8s, Helm, CloudFormation guides
- `iac-policies/` - Security policies for IaC tools
