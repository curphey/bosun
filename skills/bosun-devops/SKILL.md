---
name: bosun-devops
description: DevOps and Infrastructure as Code best practices. Use when reviewing Dockerfiles, Kubernetes manifests, Terraform configurations, Helm charts, CloudFormation templates, or GitHub Actions workflows. Provides IaC security patterns and operational guidance.
tags: [devops, docker, kubernetes, terraform, iac, cicd]
---

# Bosun DevOps Skill

Infrastructure as Code and DevOps knowledge base for reviewing and improving deployment configurations.

## When to Use

- Reviewing Dockerfiles and container configurations
- Analyzing Kubernetes manifests and Helm charts
- Evaluating Terraform or CloudFormation configurations
- Reviewing CI/CD pipelines (GitHub Actions, etc.)
- Checking IaC security and best practices

## When NOT to Use

- Application-level security (use bosun-security)
- General architecture decisions (use bosun-architect)
- Language-specific code review (use language skills)

## Quick Reference

### Dockerfile Best Practices

| Pattern | Issue | Fix |
|---------|-------|-----|
| `FROM image:latest` | Non-reproducible builds | Pin specific version |
| `USER root` | Security risk | Use non-root user |
| `ADD` for local files | Unexpected behavior | Use `COPY` instead |
| Secrets in `ENV` | Persisted in layers | Use `--mount=type=secret` |

### Kubernetes Security

| Pattern | Issue | Fix |
|---------|-------|-----|
| `privileged: true` | Container escape risk | Remove or use capabilities |
| Missing resource limits | Resource exhaustion | Set CPU/memory limits |
| `runAsRoot: true` | Privilege escalation | `runAsNonRoot: true` |
| No network policies | Lateral movement | Define ingress/egress rules |

### Terraform Best Practices

| Pattern | Issue | Fix |
|---------|-------|-----|
| Unpinned module versions | Drift risk | Pin to specific versions |
| Missing tags | Cost tracking issues | Add required tags |
| Hardcoded credentials | Security exposure | Use variables/secrets manager |
| Local state | Collaboration issues | Use remote backend |

### GitHub Actions Security

| Pattern | Issue | Fix |
|---------|-------|-----|
| `uses: action@master` | Supply chain risk | Pin to SHA or version |
| Secrets in logs | Exposure | Use `add-mask` |
| `pull_request_target` | Injection risk | Use `pull_request` |

## References

See `references/` directory for detailed documentation:
- `docker/` - Dockerfile patterns and security
- `iac-best-practices/` - Terraform, K8s, Helm, CloudFormation guides
- `iac-policies/` - Security policies for IaC tools
