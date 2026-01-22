---
name: bosun-gcp
description: Google Cloud Platform security and best practices. Use when reviewing GCP infrastructure, IAM policies, Cloud Storage, Cloud Functions, or Terraform for GCP. Provides patterns for secure GCP deployments.
tags: [gcp, google-cloud, security, iam, cloud-storage, cloud-functions, infrastructure]
---

# Bosun GCP Skill

GCP security patterns and infrastructure best practices for secure cloud deployments.

## When to Use

- Reviewing GCP IAM policies and service accounts
- Auditing Cloud Storage bucket configurations
- Securing Cloud Functions and Cloud Run
- Reviewing Terraform configurations for GCP
- Setting up VPC and firewall rules
- Configuring Cloud SQL security

## When NOT to Use

- General infrastructure patterns (use bosun-devops)
- AWS-specific (use bosun-aws)
- Azure-specific (use bosun-azure)
- Kubernetes (use bosun-devops)

## IAM Security

### Service Account Best Practices

```yaml
# Terraform - Secure service account
resource "google_service_account" "app_sa" {
  account_id   = "my-app-sa"
  display_name = "My App Service Account"
  description  = "Service account for my-app with minimal permissions"
}

# Specific role binding (not primitive roles!)
resource "google_project_iam_member" "storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"  # ✅ Predefined role
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### IAM Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `roles/owner` | Full project control | Use specific predefined roles |
| `roles/editor` | Too broad | Scope to specific services |
| `allUsers` | Public access | Use specific members |
| `allAuthenticatedUsers` | Any Google account | Use specific identities |
| User accounts for services | No audit trail | Use service accounts |
| Default service account | Over-privileged | Create dedicated accounts |

### Secure IAM Binding

```yaml
# ❌ BAD: Primitive role
resource "google_project_iam_member" "bad_binding" {
  role   = "roles/editor"  # Too broad!
  member = "serviceAccount:${google_service_account.app.email}"
}

# ✅ GOOD: Specific predefined role
resource "google_project_iam_member" "good_binding" {
  role   = "roles/cloudsql.client"  # Only Cloud SQL access
  member = "serviceAccount:${google_service_account.app.email}"
}
```

### Workload Identity (GKE)

```yaml
# Best practice for GKE: Workload Identity
resource "google_service_account" "gke_workload" {
  account_id = "gke-workload-sa"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.gke_workload.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.ksa_name}]"
}
```

## Cloud Storage Security

### Secure Bucket Configuration

```yaml
resource "google_storage_bucket" "secure_bucket" {
  name     = "my-secure-bucket"
  location = "US"

  # Uniform bucket-level access (recommended)
  uniform_bucket_level_access = true

  # Encryption with CMEK
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  # Versioning for data protection
  versioning {
    enabled = true
  }

  # Lifecycle rules for cost management
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Logging
  logging {
    log_bucket = google_storage_bucket.logs.name
  }
}

# Block public access
resource "google_storage_bucket_iam_member" "no_public" {
  bucket = google_storage_bucket.secure_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.app.email}"
  # No allUsers or allAuthenticatedUsers!
}
```

### Storage Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `allUsers` binding | Public bucket | Remove or use signed URLs |
| Fine-grained ACLs | Complex to audit | Use uniform bucket access |
| No versioning | Data loss | Enable versioning |
| Default encryption | Google-managed keys | Use CMEK for sensitive data |
| No logging | No audit trail | Enable access logging |

## Cloud Functions Security

### Secure Function Configuration

```yaml
resource "google_cloudfunctions2_function" "secure_function" {
  name     = "secure-function"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "handler"
    source {
      storage_source {
        bucket = google_storage_bucket.source.name
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    max_instance_count = 100  # Limit concurrency
    min_instance_count = 0
    timeout_seconds    = 60
    available_memory   = "256M"

    # Use dedicated service account
    service_account_email = google_service_account.function_sa.email

    # VPC connector for private access
    vpc_connector = google_vpc_access_connector.connector.id
    vpc_connector_egress_settings = "ALL_TRAFFIC"

    # Secrets from Secret Manager
    secret_environment_variables {
      key        = "API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.api_key.secret_id
      version    = "latest"
    }
  }
}

# Restrict invocation
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions2_function.secure_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.caller.email}"
  # No allUsers for internal functions!
}
```

### Functions Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `allUsers` invoker | Public endpoint | Restrict to specific identities |
| Default service account | Over-privileged | Dedicated service account |
| Hardcoded secrets | Credential exposure | Use Secret Manager |
| No VPC connector | Public network | Use VPC connector |
| No concurrency limit | DoS/cost risk | Set max instances |

## VPC & Firewall Security

### Firewall Rules

```yaml
# ❌ BAD: Open to internet
resource "google_compute_firewall" "bad_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # From anywhere!
}

# ✅ GOOD: Restricted access
resource "google_compute_firewall" "good_ssh" {
  name    = "allow-ssh-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Only from IAP (Identity-Aware Proxy)
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap-ssh"]
}
```

### VPC Best Practices

| Practice | Implementation |
|----------|----------------|
| Private Google Access | Enable on subnets for GCP API access |
| VPC Flow Logs | Enable for network monitoring |
| Private Service Connect | Access GCP services privately |
| No external IPs | Use Cloud NAT for outbound |
| IAP for SSH/RDP | No bastion hosts needed |
| Firewall rules with tags | Target specific instances |

## Cloud SQL Security

### Secure Cloud SQL Configuration

```yaml
resource "google_sql_database_instance" "secure_instance" {
  name             = "secure-db"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = "db-custom-2-4096"

    ip_configuration {
      ipv4_enabled    = false  # No public IP!
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }
  }

  deletion_protection = true
}
```

### Cloud SQL Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| Public IP enabled | Direct internet access | Use private IP only |
| SSL not required | Unencrypted traffic | Set `require_ssl = true` |
| No backups | Data loss | Enable automated backups |
| Default password | Weak credentials | Use Secret Manager |
| Public authorized networks | Open access | Use private IP + IAM |

## Secrets Management

### Using Secret Manager

```yaml
# Create secret
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password  # From CI/CD, not hardcoded!
}

# Grant access
resource "google_secret_manager_secret_iam_member" "accessor" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}
```

### Accessing Secrets in Code

```javascript
// ❌ BAD: Hardcoded
const API_KEY = 'AIzaSy...';

// ✅ GOOD: From Secret Manager
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();

async function getSecret(name) {
  const [version] = await client.accessSecretVersion({
    name: `projects/${projectId}/secrets/${name}/versions/latest`,
  });
  return version.payload.data.toString();
}
```

## Quick Reference

### Security Checklist

**IAM:**
- [ ] No primitive roles (owner/editor/viewer)
- [ ] Dedicated service accounts per workload
- [ ] No `allUsers` or `allAuthenticatedUsers`
- [ ] Workload Identity for GKE

**Storage:**
- [ ] Uniform bucket-level access
- [ ] No public buckets (unless intended)
- [ ] CMEK encryption for sensitive data
- [ ] Versioning enabled

**Functions/Run:**
- [ ] Dedicated service account
- [ ] No public invocation (unless intended)
- [ ] Secrets from Secret Manager
- [ ] VPC connector for private access

**Network:**
- [ ] No 0.0.0.0/0 firewall rules
- [ ] VPC Flow Logs enabled
- [ ] IAP for administrative access
- [ ] No external IPs on VMs

**Data:**
- [ ] Cloud SQL private IP only
- [ ] SSL required
- [ ] Automated backups enabled
- [ ] Secrets in Secret Manager

### GCP Security Tools

| Tool | Purpose | Usage |
|------|---------|-------|
| Security Command Center | Vulnerability detection | Console |
| IAM Recommender | Unused permissions | Console/API |
| Policy Analyzer | IAM troubleshooting | Console/API |
| VPC Service Controls | Data exfiltration prevention | Console/API |
| gcloud | CLI management | `gcloud` commands |
| Forseti | Security scanning | Self-hosted |
| Checkov | IaC security | `checkov -f main.tf` |

## References

See `references/` for detailed documentation:
- `iam-patterns.md` - Advanced IAM patterns
- `network-security.md` - VPC and firewall patterns
- `organization-policies.md` - Org-level constraints
